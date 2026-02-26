export LANG=ja_JP.UTF-8
export LC_ALL=
export LESSCHARSET=utf-8
export TERM=xterm-256color

export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

is-wsl() {
  [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]
}

if is-wsl; then
  if [ -d "/mnt/c/Users/$(whoami)" ]; then
    export USERPROFILE="/mnt/c/Users/$(whoami)"
  else
    export USERPROFILE="/mnt/c/Users/$(ls /mnt/c/Users | grep -v -E 'Public|Default|All Users|defaultuser0' | head -n1)"
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
