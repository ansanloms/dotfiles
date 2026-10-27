alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias ll="ls -l"
alias vi="vim"
alias vim="nvim"

# WSL: ファイル・ディレクトリ・URL を Windows 側の既定ハンドラで開く。
# URL は wslpath が受け付けないため無変換で渡す。
# explorer.exe は成功時も終了コード 1 を返すため rundll32 の FileProtocolHandler を使う。
if type wslpath > /dev/null 2>&1; then
  open() {
    local target win
    [ $# -eq 0 ] && set -- .
    for target in "$@"; do
      case "$target" in
        *://*)
          win="$target"
          ;;
        *)
          if [ ! -e "$target" ]; then
            echo "open: $target: No such file or directory" >&2
            return 1
          fi
          win="$(wslpath -w -- "$target")" || return 1
          ;;
      esac
      rundll32.exe url.dll,FileProtocolHandler "$win" || return 1
    done
  }
fi

if type eza > /dev/null 2>&1; then
  alias ls="eza"
fi
