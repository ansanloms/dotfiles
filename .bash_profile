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

export PS1_COLOR_BLACK="$(tput setaf 0)"
export PS1_COLOR_RED="$(tput setaf 1)"
export PS1_COLOR_GREEN="$(tput setaf 2)"
export PS1_COLOR_YELLOW="$(tput setaf 3)"
export PS1_COLOR_BLUE="$(tput setaf 4)"
export PS1_COLOR_PURPLE="$(tput setaf 5)"
export PS1_COLOR_CYAN="$(tput setaf 6)"
export PS1_COLOR_GRAY="$(tput setaf 7)"
export PS1_COLOR_RESET="$(tput sgr0)"

export MYSQL_PS1="(\u@\h) [\d]> "

#if [ isWsl ] && [ -z "$http_proxy" ]; then
#  export http_proxy=http://$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):30080
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

export VOLTA_HOME="$HOME/.volta"
if [ -d "$VOLTA_HOME" ]; then
  export PATH="$VOLTA_HOME/bin:$PATH"
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
  /etc/bashrc
fi

# include .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi
