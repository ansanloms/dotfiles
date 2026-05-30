# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

個人用 dotfiles。[dot-mori](https://github.com/ansanloms/dot-mori) (Deno) でシンボリックリンクを管理し、Nix flake (`nix profile`) でパッケージを管理する。

## コマンド

```sh
# dotfiles インストール（シンボリックリンク作成）
deno task install

# dotfiles アンインストール（シンボリックリンク削除）
deno task uninstall

# パッケージ初回導入
nix profile install ~/.config/nix#default --impure

# パッケージ適用（packages.nix の変更を反映）
deno task switch

# パッケージ更新（nixpkgs / nix-claude-code を更新して反映）
deno task upgrade
```

## 構成

- `config.yaml` - シンボリックリンク設定（OS別: windows/linux/darwin）
- `.config/nix/` - Nix 設定（nix.conf）と flake によるパッケージ管理（flake.nix + packages.nix）
- `.config/nvim/` - Neovim 設定（Lua）
- `.config/vim/` - Vim 設定（minpac でプラグイン管理）
- `.config/git/` - Git 設定
- `.config/wezterm/` - WezTerm 設定
- `.config/zellij/` - Zellij 設定
- `.config/starship.toml` - Starship プロンプト設定
- `.config/sheldon/` - Sheldon（zsh プラグインマネージャ）設定
- `.claude/` - Claude Code のグローバル設定（`~/.claude/` にリンク）
- `.local/bin/` - ユーザースクリプト

## Neovim 設定構造

`.config/nvim/init.lua` がエントリーポイント。以下のモジュールを順番にロード：

1. `config/general.lua` - 基本設定
2. `config/im.lua` - IME 設定
3. `config/clipboard.lua` - クリップボード設定
4. `config/mapping.lua` - キーマッピング
5. `config/plugins.lua` - プラグイン設定
6. `config/lsp.lua` - LSP 設定
7. `config/langs/` - 言語別設定
8. `config/appearance/` - 外観設定（colorscheme, statusline）
