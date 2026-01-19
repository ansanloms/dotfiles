alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias ll="ls -l"
alias vi="vim"
alias vim="nvim"

if type wsl-open > /dev/null 2>&1; then
  alias open="wsl-open"
fi

if type eza > /dev/null 2>&1; then
  alias ls="eza"
fi
