if type "starship" > /dev/null 2>&1; then
  eval "$(starship init bash)"
#else
#  PS1='\n'
#  PS1+='\w $(git show --format="%D" --no-patch --no-color 2> /dev/null)\n'
#  PS1+='\u@\h ❯❯❯ '
fi

alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias ll="ls -l"
alias vi="vim"

#if [ isWsl ]; then
#  alias git="git.exe"
#  alias vim="vim.exe"
#  alias vi="vim.exe"
#fi
