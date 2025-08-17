alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias ll="ls -l"
alias vi="vim"
alias vim="nvim"

if [ isWsl ]; then
  alias open="wsl-open"
else
  alias open="xdg-open"
fi
