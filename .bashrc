export LANG=ja_JP.UTF-8
export LC_ALL=

export LESSCHARSET=utf-8

function isWsl() {
  if [ "$(uname)" == "Linux" ] && [[ "$(uname -r)" == *microsoft* ]]; then
    return 0
  else
    return 1
  fi
}

if [ -f /etc/bashrc ]; then
  source /etc/bashrc
fi

#if [ isWsl ] && [ -z "$http_proxy" ]; then
#  export http_proxy=http://$(ip route list default | awk '{print $3}'):30080
#  export https_proxy=${http_proxy}
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
