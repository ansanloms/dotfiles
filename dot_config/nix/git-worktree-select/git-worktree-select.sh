# git worktree を fzf で対話選択し、選んだ worktree の絶対パスを stdout へ出す。
# 使い方: git-worktree-select [--exclude-main]
# shebang と errexit nounset pipefail は writeShellApplication が付ける。

exclude_main=0
case "$#" in
  0) ;;
  1)
    if [ "$1" = "--exclude-main" ]; then
      exclude_main=1
    else
      echo "usage: git-worktree-select [--exclude-main]" >&2
      exit 2
    fi
    ;;
  *)
    echo "usage: git-worktree-select [--exclude-main]" >&2
    exit 2
    ;;
esac

porcelain=$(git worktree list --porcelain)

lines=""
first=1
path=""
branch=""
sha=""

# レコード (空行区切り) を 1 行 (path<TAB>branch<TAB>sha<TAB>subject) に変換して lines へ貯める。
emit() {
  [ -n "$path" ] || return 0
  if [ "$first" -eq 1 ]; then
    first=0
    if [ "$exclude_main" -eq 1 ]; then
      return 0
    fi
  fi
  local label subject=""
  if [ -n "$branch" ]; then
    label="$branch"
    subject=$(git config --get "branch.${branch}.description" 2>/dev/null | head -n 1 | sed -E 's/^#+[[:space:]]+//; s/\[([^]]*)\]\([^)]*\)/\1/g' || true)
  else
    label="(detached)"
  fi
  lines+=$(printf '%s\t%s\t%s\t%s' "$path" "$label" "${sha:0:7}" "$subject")$'\n'
}

while IFS= read -r line; do
  case "$line" in
    "worktree "*) path="${line#worktree }" ;;
    "HEAD "*) sha="${line#HEAD }" ;;
    "branch refs/heads/"*) branch="${line#branch refs/heads/}" ;;
    "")
      emit
      path=""
      branch=""
      sha=""
      ;;
    *) ;;
  esac
done <<<"$porcelain"
emit

if [ -z "$lines" ]; then
  echo "No worktrees to select." >&2
  exit 1
fi

selected=$(printf '%s' "$lines" | fzf --ansi --delimiter='\t' --with-nth=1,2,4 \
  --layout=reverse --height=50% --min-height=15 \
  --preview 'git config --get branch.{2}.description 2>/dev/null | mdcat --ansi - 2>/dev/null || true' \
  --preview-window=right,55%,wrap) || exit 1

printf '%s\n' "$selected" | cut -f1
