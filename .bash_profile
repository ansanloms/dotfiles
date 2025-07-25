if [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc"
fi

if type "starship" > /dev/null 2>&1; then
  eval "$(starship init bash)"
fi

alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias ll="ls -l"
alias vi="vim"
alias vim="nvim"
