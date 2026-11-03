#!/usr/bin/env bash
# sonarqube-cli を指定バージョン（省略時は GitHub の最新リリース）へ更新する。
#
# 処理内容:
#   1. 対象バージョンを決定（引数 or GitHub releases の latest tag）
#   2. 配布 ELF の hash を nix store prefetch-file で取得
#   3. sonarqube-cli.nix の version / hash を反映
#
# git add / nix profile upgrade は行わない。完了後に git diff で確認し、手動で反映すること。
#
# 使い方:
#   .config/nix/sonarqube-cli/upgrade.sh                # 最新へ
#   .config/nix/sonarqube-cli/upgrade.sh 1.1.0.3122     # 指定バージョンへ
set -euo pipefail

REPO="SonarSource/sonarqube-cli"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nix_path="$script_dir/../sonarqube-cli.nix"

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

# 1. 対象バージョンを決定
version="${1:-$(gh api "repos/${REPO}/releases/latest" --jq .tag_name)}"
echo "対象バージョン: ${version}"

# 2. 配布 ELF の hash を取得（SRI sha256- 形式でそのまま nix へ書ける）
echo "hash を取得中..."
hash="$(nix store prefetch-file --json \
  "https://binaries.sonarsource.com/Distribution/sonarqube-cli/${version}/linux/sonarqube-cli-${version}-linux-x86-64.bin" |
  jq -r .hash)"
echo "hash: ${hash}"

# 3. sonarqube-cli.nix へ反映
set_nix_string "$nix_path" version "$version"
set_nix_string "$nix_path" hash "$hash"

echo
echo "更新完了。git diff で確認し、問題なければ反映:"
echo "  git add .config/nix/sonarqube-cli.nix"
echo "  nix profile upgrade --all --impure"
