[windows]
set shell := ["pwsh", "-NoLogo", "-NoProfileLoadTime", "-Command"]

# 一覧。
list:
    @just --list

# dotfiles を最新にして適用する。
[linux]
upgrade:
    git pull --ff-only
    chezmoi apply
    nix profile upgrade --all --impure
    apm install -g

# dotfiles を最新にして適用する。
[windows]
upgrade:
    git pull --ff-only
    chezmoi apply
