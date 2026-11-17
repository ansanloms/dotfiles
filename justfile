[windows]
set shell := ["pwsh", "-NoLogo", "-NoProfileLoadTime", "-Command"]

# 一覧。
list:
    @just --list

# pull せずに dotfiles を適用する。引数は chezmoi apply へ渡す (例: --force で上書き確認を省く)。
[linux]
upgrade *flags:
    chezmoi apply {{ flags }}
    nix profile upgrade --all --impure
    apm install -g

# pull せずに dotfiles を適用する。引数は chezmoi apply へ渡す (例: --force で上書き確認を省く)。
[windows]
upgrade *flags:
    chezmoi apply {{ flags }}
