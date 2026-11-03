#!/usr/bin/env bash
# moddable-sdk を public ブランチの指定コミット（省略時は HEAD）へ更新する。
#
# Moddable はタグ付きリリースが古く（2022 年止まり）、現行ツールは public ブランチで
# 配布される。そのため tag ではなく public の特定コミットに pin する。
#
# 処理内容:
#   1. 対象コミットを決定（引数 or `git ls-remote ... public` の HEAD）
#   2. `nix flake prefetch` で fetchFromGitHub 用 hash と取得済みツリーの storePath を得る
#   3. storePath の tools/VERSION を version 文字列に反映
#   4. moddable-sdk.nix の rev / hash / version を反映
#
# git add / nix profile upgrade は行わない。完了後に git diff で確認し、手動で反映すること。
#
# 使い方:
#   dot_config/nix/moddable-sdk/upgrade.sh            # public HEAD へ
#   dot_config/nix/moddable-sdk/upgrade.sh <commit>   # 指定コミットへ
set -euo pipefail

REPO="https://github.com/Moddable-OpenSource/moddable.git"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nix_path="$script_dir/../moddable-sdk.nix"

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

# 1. 対象コミットを決定
if [[ $# -ge 1 ]]; then
  rev="$1"
else
  rev="$(git ls-remote "$REPO" refs/heads/public | cut -f1)"
  if [[ -z "$rev" ]]; then
    echo "public ブランチが見つからない" >&2
    exit 1
  fi
fi
if [[ ! "$rev" =~ ^[0-9a-f]{40}$ ]]; then
  echo "コミットハッシュが不正: ${rev}" >&2
  exit 1
fi
echo "対象コミット: ${rev}"

# 2. hash と storePath を取得（fetchFromGitHub は fetchTree 系のため flake prefetch の
#    narHash がそのまま hash として使える）
echo "hash を取得中..."
prefetch="$(nix flake prefetch "github:Moddable-OpenSource/moddable/${rev}" --json)"
hash="$(jq -r .hash <<<"$prefetch")"
store_path="$(jq -r .storePath <<<"$prefetch")"
echo "hash: ${hash}"

# 3. version を tools/VERSION から取得
version="$(tr -d '[:space:]' <"$store_path/tools/VERSION")"
echo "version: ${version}"

# 4. moddable-sdk.nix へ反映
set_nix_string "$nix_path" version "$version"
set_nix_string "$nix_path" rev "$rev"
set_nix_string "$nix_path" hash "$hash"

echo
echo "更新完了。git diff で確認し、問題なければ反映:"
echo "  git add dot_config/nix/moddable-sdk.nix"
echo "  chezmoi apply"
echo "  nix profile upgrade --all --impure"
