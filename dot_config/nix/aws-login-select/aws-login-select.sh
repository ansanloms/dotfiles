# AWS profile を fzf で対話選択し、選んだ profile で aws login を実行する。
# 使い方: aws-login-select [aws login の引数...] (--profile 以外はそのまま aws login へ渡す)
# shebang と errexit nounset pipefail は writeShellApplication が付ける。

for arg in "$@"; do
  case "$arg" in
    --profile | --profile=*)
      echo "usage: aws-login-select [aws login options except --profile]" >&2
      exit 2
      ;;
    *) ;;
  esac
done

profiles=$(aws configure list-profiles)

if [ -z "$profiles" ]; then
  echo "No AWS profiles found." >&2
  exit 1
fi

# preview は設定ファイルから該当セクション (default は [default]、それ以外は [profile <name>]) を抜き出す。
# {} は fzf がクォート済みで展開するので、profile 名に空白があっても壊れない。
# shellcheck disable=SC2016
selected=$(printf '%s\n' "$profiles" | fzf \
  --layout=reverse --height=50% --min-height=15 \
  --preview 'awk -v name={} "BEGIN { sec = (name == \"default\") ? \"[default]\" : \"[profile \" name \"]\" } \$0 == sec { p = 1; print; next } /^\\[/ { p = 0 } p" "${AWS_CONFIG_FILE:-$HOME/.aws/config}" 2>/dev/null || true' \
  --preview-window=right,55%,wrap) || exit 1

exec aws login --profile "$selected" "$@"
