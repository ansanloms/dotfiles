function isWsl() {
  if [ "$(uname)" == "Linux" ] && [[ "$(uname -r)" == *microsoft* ]]; then
    return 0
  else
    return 1
  fi
}

function isMsys() {
  if [[ "$(uname)" == *MSYS* ]]; then
    return 0
  else
    return 1
  fi
}

export LANG=ja_JP.UTF-8
export LC_ALL=

export LESSCHARSET=utf-8

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

export DENO_INSTALL="$HOME/.deno"
if [ -d "$DENO_INSTALL" ]; then
  export PATH="$DENO_INSTALL/bin:$PATH"
fi

export CARGO_HOME="$HOME/.cargo"
if [ -d "$CARGO_HOME" ]; then
  export PATH="$CARGO_HOME/bin:$PATH"
  . "$HOME/.cargo/env"
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
  /etc/bashrc
fi

# include .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi

export VOLTA_HOME="$HOME/.volta"
if [ -d "$VOLTA_HOME" ]; then
  export PATH="$VOLTA_HOME/bin:$PATH"
fi
