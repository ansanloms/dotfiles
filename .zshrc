if [ -f "$HOME/.bash_aliases" ]; then
  source "$HOME/.bash_aliases"
fi

if [ -f "$HOME/.config/zsh/prompt.zsh" ]; then
  source "$HOME/.config/zsh/prompt.zsh"
fi

if type sheldon > /dev/null 2>&1; then
  eval "$(sheldon source)"
fi

if type wsl2-ssh-agent > /dev/null 2>&1; then
  eval $(wsl2-ssh-agent)
fi

# zellij のネスト起動を防ぐ (既に zellij 内なら新規セッション/アタッチを拒否)
zellij() {
  if [[ -n "$ZELLIJ" ]]; then
    case "${1:-}" in
      ""|attach|a|-s|--session|-n|--new-session-with-layout)
        echo "zellij: 既にセッション '${ZELLIJ_SESSION_NAME}' 内です。ネスト起動を中止しました (本当に入れ子にするなら command zellij)。" >&2
        return 1
        ;;
    esac
  fi
  command zellij "$@"
}

# git wt ls で worktree 選択して cd
git() {
  if [[ "$1" == "wt" && "$2" == "ls" ]]; then
    local dir
    dir=$(command git worktree-select 2>&1 >/dev/tty)
    [[ -n "$dir" ]] && cd "$dir"
  else
    command git "$@"
  fi
}
