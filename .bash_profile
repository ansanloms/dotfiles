if [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc"
fi

if [ -f "$HOME/.bash_aliases" ]; then
  source "$HOME/.bash_aliases"
fi

if type "starship" > /dev/null 2>&1; then
  eval "$(starship init bash)"
fi
