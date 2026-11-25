#!/usr/bin/env bash
# quint-language-server を指定バージョン（省略時は npm レジストリの最新）へ更新する。
#
# 処理内容:
#   1. package.json の依存バージョンを反映
#   2. package-lock.json を再生成
#   3. npmDepsHash を取得
#   4. quint-language-server.nix の version / npmDepsHash を反映
#
# git add / nix profile upgrade は行わない。完了後に git diff で確認し、手動で反映すること。
#
# 使い方:
#   dot_config/nix/quint-language-server/upgrade.sh           # 最新へ
#   dot_config/nix/quint-language-server/upgrade.sh 0.21.0     # 指定バージョンへ
set -euo pipefail

PKG="@informalsystems/quint-language-server"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pkg_json_path="$script_dir/package.json"
lock_path="$script_dir/package-lock.json"
nix_path="$script_dir/../quint-language-server.nix"

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

version="${1:-$(npm view "$PKG" version)}"
# 範囲指定 (^0.21.0 等) や latest を渡すと nix の version にそのまま書き込まれ実際の版と食い違うため、
# 具体的なバージョン文字列であることを検証する。
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "バージョンの形式が不正: \"${version}\"（期待する形式: 0.20.0 や 1.0.0-rc.3 のような具体的なバージョン文字列）" >&2
  exit 1
fi
echo "対象バージョン: ${version}"

# 1. package.json の依存バージョンを反映
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
jq --indent 2 --arg v "$version" --arg p "$PKG" \
  '.version = $v | .dependencies[$p] = $v' "$pkg_json_path" >"$tmp"
cat "$tmp" >"$pkg_json_path"

# 2. lockfile を再生成（nix の npm を使う）
echo "lockfile を再生成中..."
npm install --prefix "$script_dir" --package-lock-only --omit=dev

# 3. npmDepsHash を取得
# ビルドで使う flake.lock の nixpkgs と同じ prefetch-npm-deps を使うため、--inputs-from で固定する。
echo "npmDepsHash を取得中..."
hash="$(nix run --inputs-from "$script_dir/.." nixpkgs#prefetch-npm-deps -- "$lock_path")"
echo "npmDepsHash: ${hash}"

# 4. quint-language-server.nix へ反映
set_nix_string "$nix_path" version "$version"
set_nix_string "$nix_path" npmDepsHash "$hash"

echo
echo "更新完了。git diff で確認し、問題なければ反映:"
echo "  git add dot_config/nix/quint-language-server.nix dot_config/nix/quint-language-server/"
echo "  chezmoi apply"
echo "  nix profile upgrade --all --impure"
