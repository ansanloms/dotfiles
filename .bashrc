
if type "starship" > /dev/null 2>&1; then
	eval "$(starship init bash)"
#else
#	PS1='\n'
#	PS1+='\w $(git show --format="%D" --no-patch --no-color 2> /dev/null)\n'
#	PS1+='\u@\h ❯❯❯ '
fi

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ll='ls -l'
alias vi='vim'

if [ -d "${NVM_DIR}" ]; then
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi
