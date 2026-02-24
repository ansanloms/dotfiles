is-wsl() {
  [[ "$(uname)" == "Linux" ]] && [[ "$(uname -r)" == *microsoft* ]]
}

if [ -d "$HOME/bin" ]; then
  export PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "/opt/nvim-linux-x86_64/bin" ]; then
  export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
fi

if [ -f "$HOME/.bash_aliases" ]; then
  source "$HOME/.bash_aliases"
fi

if type mise > /dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if type starship > /dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if type sheldon > /dev/null 2>&1; then
  eval "$(sheldon source)"
fi

if type wsl2-ssh-agent > /dev/null 2>&1; then
  eval $(wsl2-ssh-agent)
fi

# git wt を拡張: sel でworktree選択してcd
git() {
  if [[ "$1" == "wt" && "$2" == "sel" ]]; then
    local dir
    dir=$(command git worktree-select 2>&1 >/dev/tty)
    [[ -n "$dir" ]] && cd "$dir"
  else
    command git "$@"
  fi
}
