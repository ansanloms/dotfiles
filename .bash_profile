export LANG=ja_JP.UTF-8
export LC_ALL=
export LESSCHARSET=utf-8
export TERM=xterm-256color

export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

if [ -f /etc/bashrc ]; then
  source /etc/bashrc
fi

if [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc"
fi
