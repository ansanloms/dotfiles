is-wsl() {
  [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]
}

if [ -d "$HOME/bin" ]; then
  export PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
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
