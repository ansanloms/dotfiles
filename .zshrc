if type mise > /dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if type starship > /dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if type sheldon > /dev/null 2>&1; then
  eval "$(sheldon source)"
fi

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
