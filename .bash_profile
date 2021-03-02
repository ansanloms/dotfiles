export PATH=$HOME/bin:$PATH

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

export NVM_DIR="$HOME/.nvm"

# Source global definitions
if [ -f /etc/bashrc ]; then
	/etc/bashrc
fi

test -r ~/.bashrc && . ~/.bashrc
