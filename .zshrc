is-wsl() {
  [[ "$(uname)" == "Linux" ]] && [[ "$(uname -r)" == *microsoft* ]]
}

if is-wsl; then
  if [ -d "/mnt/c/Users/$(whoami)" ]; then
    export USERPROFILE="/mnt/c/Users/$(whoami)"
  else
    WIN_USER=$(ls /mnt/c/Users | grep -v -E 'Public|Default|All Users|defaultuser0' | head -n1)
    export USERPROFILE="/mnt/c/Users/$WIN_USER"
  fi
fi

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
