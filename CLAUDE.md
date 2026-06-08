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
- `.local/bin/` - ユーザースクリプト（`scripts/` から `deno bundle` で生成）

## Agent Skills

Agent Skills は [apm](https://github.com/microsoft/apm)（`packages.nix` で導入）で管理し、skill 本体をリポジトリにコミットしている。`deno task install` で各エージェントへシンボリックリンクされる。

配置先は 2 系統あり、apm の `--target` で振り分ける。

- `.claude/skills/` → `~/.claude/skills`（Claude Code）。target は `claude`。
- `.agents/skills/` → `~/.agents/skills`（Devin CLI / Devin Desktop が参照する cross-agent ディレクトリ）。target は `agent-skills`。

skill ごとの方針:

| skill | 取得元 | 配置先 |
| --- | --- | --- |
| find-docs | `ansanloms/skills`（apm） | `.claude/skills/` + `.agents/skills/` |
| empirical-prompt-tuning | `mizchi/skills`（apm） | `.claude/skills/` のみ |
| nvim-remote | `ansanloms/skills`（apm） | `.claude/skills/` + `.agents/skills/` |

skill を追加・更新する場合のみ apm を使用する。target は **必ず明示** すること。省略すると apm が auto-detect で `claude` のみに絞り、`.agents/skills/`（cross-agent）への配置が lock から外れる。

```sh
# Claude Code のみに配置（例: empirical-prompt-tuning）
apm install <org>/<repo>/<skill>#<commit> --target claude

# Claude Code と cross-agent（.agents/skills/）の両方に配置（例: find-docs, nvim-remote）
apm install <org>/<repo>/<skill>#<commit> --target claude,agent-skills
```

更新も同じ install で commit を上げる。`apm update` は使わない。target を per-package で扱えず auto-detect で `.agents/skills/` を落とすうえ、`--target` を付けても全 skill 一律になり、claude のみ配置の skill まで `.agents/skills/` へ広げてしまうため。最新 commit は `git ls-remote <repo> HEAD` 等で確認する。

`apm.yml` / `apm.lock.yaml` は commit hash でバージョンを固定している。追加・更新後は、これらと `.claude/skills/` / `.agents/skills/` の差分をコミットする。

## Local scripts

`.local/bin/` 配下のコマンド（`git-worktree-select` / `git-worktree-include` 等）は、`scripts/` 以下の TypeScript を `deno bundle` で単一ファイルにビルドした生成物。依存は `deno.json` の `imports` で一元管理する。

- ソース: `scripts/*.ts`（shebang に実行時の権限フラグを記述。`deno bundle` が生成物の先頭へ引き継ぐ）
- ビルド: `deno task build` で `scripts/*.ts` を `.local/bin/<name>` に bundle し、実行ビットを付与する
- 生成物は `.gitignore` 済みでコミットしない。`deno task install` でシンボリックリンクするため、**install の前に build しておく**こと

ソースを編集したら `deno task build` で再生成する。

## 自前 nix パッケージの更新

`.config/nix/` には nixpkgs 未収録のパッケージを自前 derivation で管理している。

- `playwright-cli.nix`（`@playwright/cli`、npm パッケージ / buildNpmPackage、wrapper で nixpkgs `google-chrome` を駆動）
- `apm.nix`（`microsoft/apm`、プリビルドバイナリ / fetchurl + autoPatchelfHook）

### バージョンを上げる

`deno task bump`（両方）/ `deno task bump:playwright-cli [version]` / `deno task bump:apm [version]`（version 省略で最新）で、依存 version・lockfile・ハッシュを更新する。具体的な処理は各スクリプトを参照:

- `.config/nix/playwright-cli/upgrade.ts`
- `.config/nix/apm/upgrade.ts`

bump はファイルを書き換えるだけで反映はしない。完了後に `git diff` で確認し、`git add` してから `deno task switch` で反映する（`switch` = `nix profile upgrade --all --impure` は git flake を参照するため、ステージしていない変更、特に新規ファイルは反映されない）。

### bump で拾えない変更

bump が更新するのは version 文字列と FOD ハッシュという、機械的に再計算できる値だけ。新版が次を変えた場合は bump 後の `switch` がビルドエラーになるので、エラーを読んで derivation を手当てする:

- **apm**: 同梱 PyInstaller バンドルの Python 拡張モジュールが要求する native ライブラリが増えると、autoPatchelf が解決できず失敗する。不足分を `apm.nix` の `buildInputs` に追加する（例: 0.16.1 で sqlite / lzma / ffi / bz2 / uuid / readline / zlib が必要になった）。
- **playwright-cli**: 新版で bin のパスや名前が変わると、`playwright-cli.nix` の wrapper（`--add-flags` のパス）が合わなくなる。`find` で実 bin を確認して修正する。

このため bump 後は必ず `deno task switch` までやってビルドが通ることを確認すること。

### nixpkgs 収録されたら

`@playwright/cli` が nixpkgs に収録されたら（`nix search nixpkgs playwright-cli` で確認）、自前 derivation 一式を削除して `packages.nix` の 1 行に乗り換える。
