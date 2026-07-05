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
