export PATH=$HOME/bin:$PATH

export LANG=ja_JP.utf8

export PS1_COLOR_BLACK="$(tput setaf 0)"
export PS1_COLOR_RED="$(tput setaf 1)"
export PS1_COLOR_GREEN="$(tput setaf 2)"
export PS1_COLOR_YELLOW="$(tput setaf 3)"
export PS1_COLOR_BLUE="$(tput setaf 4)"
export PS1_COLOR_PURPLE="$(tput setaf 5)"
export PS1_COLOR_CYAN="$(tput setaf 6)"
export PS1_COLOR_GRAY="$(tput setaf 7)"
export PS1_COLOR_RESET="$(tput sgr0)"

PS1='\n'
PS1+='\w\n'
PS1+=' $(git show --format="%D" --no-patch --no-color 2> /dev/null)\n'
PS1+='> '

export MYSQL_PS1="(\u@\h) [\d]> "

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ll='ls -l'
alias vi='vim'

