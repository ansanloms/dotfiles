if [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc"
fi

if [ -f "$HOME/.bash_aliases" ]; then
  source "$HOME/.bash_aliases"
fi

export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

if type "starship" > /dev/null 2>&1; then
  eval "$(starship init bash)"
fi

if type -P mise > /dev/null; then
  eval "$(mise activate bash)"
fi
