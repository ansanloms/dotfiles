export LANG=ja_JP.UTF-8
export LC_ALL=

export LESSCHARSET=utf-8

function is-wsl() {
  if [ "$(uname)" == "Linux" ] && [[ "$(uname -r)" == *microsoft* ]]; then
    return 0
  else
    return 1
  fi
}

function get-local-appdata() {
  if [ is-wsl ]; then
    local localappdata_win=$(powershell.exe -c "echo \$env:LOCALAPPDATA" | tr -d '\r')
    wslpath "$localappdata_win"
  fi
}

if [ -f /etc/bashrc ]; then
  source /etc/bashrc
fi

if [ -d "$HOME/bin" ]; then
  export PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/.deno" ]; then
  export PATH="$HOME/.deno/bin:$PATH"
fi

if [ -d "$HOME/.cargo" ]; then
  export PATH="$HOME/.cargo/bin:$PATH"
  . "$HOME/.cargo/env"
fi

if [ -d "$HOME/go" ]; then
  export PATH="$HOME/go/bin:$PATH"
fi

if [ -d "/opt/nvim-linux-x86_64/bin" ]; then
  export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
fi
