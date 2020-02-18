PS1='\n'
PS1+='\w $(git show --format="%D" --no-patch --no-color 2> /dev/null)\n'
PS1+='\u@\h ❯ '

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ll='ls -l'
alias vi='vim'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
