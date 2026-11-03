#!/usr/bin/env bash
# claude-statusline を指定バージョン（省略時は GitHub の最新リリース）へ更新する。
#
# 処理内容:
#   1. 対象バージョンを決定（引数 or GitHub releases の latest tag）
#   2. target ごとの配布バイナリの hash を nix store prefetch-file で取得
#   3. claude-statusline.nix の version / system 別 hash を反映
#
# git add / nix profile upgrade は行わない。完了後に git diff で確認し、手動で反映すること。
#
# 使い方:
#   .config/nix/claude-statusline/upgrade.sh          # 最新へ
#   .config/nix/claude-statusline/upgrade.sh 0.1.0    # 指定バージョンへ
set -euo pipefail

REPO="ansanloms/claude-statusline"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nix_path="$script_dir/../claude-statusline.nix"

# nix の system -> Release 資産の target（claude-statusline.nix の targets と同じ）。
declare -A TARGETS=(
  ["x86_64-linux"]="linux-x64"
  ["aarch64-linux"]="linux-arm64"
)

# nix ファイル内の最初の `<key> = "...";` の値を置換する。
# value は sed の置換文字列に埋め込むため、`/` `&` `\` をエスケープする
# （SRI hash の base64 は `/` を含みうる）。
set_nix_string() {
  local file="$1" key="$2" raw="$3" value
  value="$(printf '%s' "$raw" | sed -e 's/[\/&\\]/\\&/g')"
  if ! grep -qE "\b${key} = \"[^\"]*\";" "$file"; then
    echo "${file} に ${key} の定義が見つからない" >&2
    exit 1
  fi
  sed -i -E "0,/(\b${key} = \")[^\"]*(\";)/s//\1${value}\2/" "$file"
  if ! grep -qF "${key} = \"${raw}\";" "$file"; then
    echo "${file} の ${key} を更新できなかった" >&2
    exit 1
  fi
}

# nix ファイル内の `"<system>" = "sha256-...";` の hash を置換する。
# targets 側の `"<system>" = "..."` に当たらないよう sha256- を前提にする。
# value は set_nix_string と同じく `/` `&` `\` をエスケープして sed の置換側へ埋め込む。
set_nix_system_hash() {
  local file="$1" system="$2" raw="$3" value
  value="$(printf '%s' "$raw" | sed -e 's/[\/&\\]/\\&/g')"
  if ! grep -qE "\"${system}\" = \"sha256-[^\"]*\"" "$file"; then
    echo "${file} に ${system} の hash 定義が見つからない" >&2
    exit 1
  fi
  sed -i -E "0,/(\"${system}\" = \")sha256-[^\"]*(\")/s//\1${value}\2/" "$file"
  if ! grep -qF "\"${system}\" = \"${raw}\"" "$file"; then
    echo "${file} の ${system} の hash を更新できなかった" >&2
    exit 1
  fi
}

# 1. 対象バージョンを決定（タグ = version）
version="${1:-$(gh api "repos/${REPO}/releases/latest" --jq .tag_name)}"
echo "対象バージョン: ${version}"

# 2. target ごとの hash を取得（SRI sha256- 形式でそのまま nix へ書ける）
declare -A hashes=()
for system in "${!TARGETS[@]}"; do
  target="${TARGETS[$system]}"
  echo "${system}: hash を取得中..."
  hashes[$system]="$(nix store prefetch-file --json \
    "https://github.com/${REPO}/releases/download/${version}/claude-statusline-${target}" | jq -r .hash)"
  echo "${system}: ${hashes[$system]}"
done

# 3. claude-statusline.nix へ反映
set_nix_string "$nix_path" version "$version"
for system in "${!hashes[@]}"; do
  set_nix_system_hash "$nix_path" "$system" "${hashes[$system]}"
done

echo
echo "更新完了。git diff で確認し、問題なければ反映:"
echo "  git add .config/nix/claude-statusline.nix"
echo "  nix profile upgrade --all --impure"
