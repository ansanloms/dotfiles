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

# windows 側にある proxy を使う。
if [ is-wsl ]; then
  export http_proxy=http://$(ip route list default | awk '{print $3}'):30080
  export https_proxy=${http_proxy}
  export HTTP_PROXY=${http_proxy}
  export HTTPS_PROXY=${http_proxy}
  export no_proxy=localhost,127.0.0.1
  export NO_PROXY=localhost,127.0.0.1
fi

# wsl から windows 側の ssh-agent を使う。
# socat が必要。
#if [ is-wsl ]; then
#  export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
#
#  if [[ ! -S "$SSH_AUTH_SOCK" ]]; then
#    rm -f "$SSH_AUTH_SOCK"
#
#    # winget install albertony.npiperelay
#    (setsid socat UNIX-LISTEN:"$SSH_AUTH_SOCK",fork EXEC:"$(get-local-appdata)/Microsoft/WinGet/Links/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) >/dev/null 2>&1 &
#  fi
#fi

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

if [ -d "$HOME/.volta" ]; then
  export PATH="$HOME/.volta/bin:$PATH"
fi

export GOPATH="$HOME/go"
if [ -d "$GOPATH" ]; then
  export PATH="$GOPATH/bin:$PATH"
fi

if [ -d "/opt/nvim-linux-x86_64/bin" ]; then
  export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
fi
