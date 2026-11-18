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
    # apm-cli 0.35.0 の不具合 (microsoft/apm#3372, #3391) で、1 回目に skill が消えることがあるため 2 回実行する。
    # 0.35.0 では消えても exit 0 で終わるので、2 回目で復元させる。nixpkgs の apm-cli が 0.36.0 以上になったら 1 回に戻す。
    apm install -g
    apm install -g

# pull せずに dotfiles を適用する。引数は chezmoi apply へ渡す (例: --force で上書き確認を省く)。
[windows]
upgrade *flags:
    chezmoi apply {{ flags }}
