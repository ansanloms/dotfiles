setopt PROMPT_SUBST
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%F{cyan}%b%f'
zstyle ':vcs_info:git:*' actionformats '%F{cyan}%b|%a%f'

# OS アイコンは起動時に 1 回だけ確定する（毎プロンプトのコストを避ける）。
# グリフは starship.toml の [os.symbols] のコードポイントを移植したもの。
typeset -gA _os_icons=(
  ubuntu $' ' debian $' ' arch $' '
  fedora $' ' nixos $' ' alpine $' ' macos $' '
)
if [[ "$OSTYPE" == darwin* ]]; then
  _os_id=macos
else
  _os_id=$( . /etc/os-release 2>/dev/null && print -r -- "$ID" )
fi
_os_glyph=$' '   # 未知は Linux のグリフをフォールバックにする
[[ -n ${_os_icons[$_os_id]} ]] && _os_glyph=${_os_icons[$_os_id]}
_os_icon="%F{green}${_os_glyph}%f"

precmd() { vcs_info }

PROMPT='
%F{244}┌──────────────%f ${_os_icon}${vcs_info_msg_0_}
%F{244}│%f %F{white}%~%f
%(?.%F{244}>%f.%F{red}>%f) '
