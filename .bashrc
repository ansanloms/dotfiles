is-wsl() {
  [[ "$(uname)" == "Linux" && "$(uname -r)" == *microsoft* ]]
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

if type mise > /dev/null 2>&1; then
  eval "$(mise activate bash)"
fi

if type starship > /dev/null 2>&1; then
  eval "$(starship init bash)"
fi

#if type sheldon > /dev/null 2>&1; then
#  eval "$(sheldon source)"
#fi

if type wsl2-ssh-agent > /dev/null 2>&1; then
  eval $(wsl2-ssh-agent)
fi
