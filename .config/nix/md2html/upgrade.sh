#!/usr/bin/env bash
# md2html を指定バージョン（省略時は GitHub の最新リリース）へ更新する。
#
# 処理内容:
#   1. 対象バージョンを決定（引数 or GitHub releases の latest tag）
#   2. Release の SHA256SUMS を gh で取得し、target ごとの sha256 を SRI 形式へ変換
#   3. md2html.nix の version / system 別 hash を反映
#
# git add / nix profile upgrade は行わない。完了後に git diff で確認し、手動で反映すること。
#
# 使い方:
#   .config/nix/md2html/upgrade.sh          # 最新へ
#   .config/nix/md2html/upgrade.sh 0.2.1    # 指定バージョンへ（先頭の v は省略可）
set -euo pipefail

REPO="ansanloms/md2html"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nix_path="$script_dir/../md2html.nix"

# nix の system -> Release 資産の target（md2html.nix の targets と同じ）。
# SHA256SUMS には darwin も載るが、nix に無い system は更新しない。
declare -A TARGETS=(
  ["x86_64-linux"]="bun-linux-x64"
  ["aarch64-linux"]="bun-linux-arm64"
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

# 1. 対象バージョンを決定（引数は誤って "v" 付きで指定された場合への防御として先頭の "v" を
#    除去する。タグ自体は v プレフィックス無しのため、自動取得した tag_name はそのまま使う）
if [[ $# -ge 1 ]]; then
  version="${1#v}"
else
  version="$(gh api "repos/${REPO}/releases/latest" --jq .tag_name)"
fi
echo "対象バージョン: ${version}"

# 2. SHA256SUMS を取得（sha256sum 形式: `<hex>  <name>`、name の前に `*` が付く場合もある）
echo "SHA256SUMS を取得中..."
sums="$(gh release download "$version" --repo "$REPO" --pattern SHA256SUMS -O -)"

declare -A hashes=()
for system in "${!TARGETS[@]}"; do
  target="${TARGETS[$system]}"
  hex="$(awk -v name="md2html-${target}" '
    { n = $2; sub(/^\*/, "", n) }
    length($1) == 64 && $1 ~ /^[0-9a-f]+$/ && n == name { print $1; exit }
  ' <<<"$sums")"
  if [[ -z "$hex" ]]; then
    echo "SHA256SUMS に md2html-${target} が見つからない" >&2
    exit 1
  fi
  hashes[$system]="$(nix hash convert --hash-algo sha256 --to sri "$hex")"
  echo "${system}: ${hashes[$system]}"
done

# 3. md2html.nix へ反映
set_nix_string "$nix_path" version "$version"
for system in "${!hashes[@]}"; do
  set_nix_system_hash "$nix_path" "$system" "${hashes[$system]}"
done

echo
echo "更新完了。git diff で確認し、問題なければ反映:"
echo "  git add .config/nix/md2html.nix"
echo "  nix profile upgrade --all --impure"
