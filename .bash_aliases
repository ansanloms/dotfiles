alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias ll="ls -l"
alias vi="vim"
alias vim="nvim"

if command -v is-wsl >/dev/null 2>&1 && is-wsl; then
  alias open="wsl-open"
  alias ssh="/mnt/c/WINDOWS/System32/OpenSSH/ssh.exe"
else
  alias open="xdg-open"
fi
