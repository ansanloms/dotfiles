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
nix profile install path:.config/nix#default --impure

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

skill の実体は `.agents/skills/` の 1 箇所に置く。`~/.agents/skills`（Devin CLI / Devin Desktop が参照する cross-agent ディレクトリ）と `~/.claude/skills`（Claude Code）は、どちらも `.agents/skills/` を指すシンボリックリンク（`config.yaml` で設定）。両エージェントが同一実体を参照し、claude 専用・cross-agent 専用の配置区別は持たない。

apm のデプロイ先は `apm.yml` の `targets: [agent-skills]` で `.agents/skills/` に固定している。target の解決順は `--target` > `apm.yml` の `targets:` > auto-detect で、この固定により install 時に `--target` を省略しても `.agents/skills/` へ配置される（省略時の auto-detect は `.claude/` の存在を見て `claude` を選ぶため、固定が無いと `.claude/` 側へ流れる）。

導入済み skill:

| skill                   | 取得元                    |
| ----------------------- | ------------------------- |
| find-docs               | `ansanloms/skills`（apm） |
| empirical-prompt-tuning | `mizchi/skills`（apm）    |
| nvim-remote             | `ansanloms/skills`（apm） |
| worktree                | `ansanloms/skills`（apm） |

skill を追加・更新する場合のみ apm を使用する。`apm.yml` の `targets` で配置先（`.agents/skills/`）を固定済みのため、install は `--target` 無しでよい。

```sh
# skill の追加・更新（apm.yml の targets: agent-skills により .agents/skills/ へ配置）
apm install <org>/<repo>/<skill>#<commit>
```

更新も同じ install で commit を上げる。`apm update` は使わない。`apm update` は最新の一致 ref へ更新してしまい、commit hash 固定と噛み合わないため。最新 commit は `git ls-remote <repo> HEAD` 等で確認する。

`apm.yml` / `apm.lock.yaml` は commit hash でバージョンを固定している。追加・更新後は、これらと `.agents/skills/` の差分をコミットする。

## Local scripts

`.local/bin/` 配下のコマンド（`git-worktree-select` / `git-worktree-include` 等）は、`scripts/` 以下の TypeScript を `deno bundle` で単一ファイルにビルドした生成物。依存は `deno.json` の `imports` で一元管理する。

- ソース: `scripts/*.ts`（shebang に実行時の権限フラグを記述。`deno bundle` が生成物の先頭へ引き継ぐ）
- ビルド: `deno task build` で `scripts/*.ts` を `.local/bin/<name>` に bundle し、実行ビットを付与する
- 生成物は `.gitignore` 済みでコミットしない。`deno task install` でシンボリックリンクするため、**install の前に build しておく**こと

ソースを編集したら `deno task build` で再生成する。

## 自前 nix パッケージの更新

`.config/nix/` には nixpkgs 未収録のパッケージを自前 derivation で管理している。

- `playwright-cli.nix`（`@playwright/cli`、npm パッケージ / buildNpmPackage、wrapper で nixpkgs `google-chrome` を駆動）

### バージョンを上げる

`deno task bump` / `deno task bump:playwright-cli [version]`（version 省略で最新）で、依存 version・lockfile・ハッシュを更新する。具体的な処理は各スクリプトを参照:

- `.config/nix/playwright-cli/upgrade.ts`

bump はファイルを書き換えるだけで反映はしない。完了後に `git diff` で確認してから `deno task switch` で反映する。`switch` = `nix profile upgrade --all --impure` はプロファイルが `path:.config/nix#default` で登録されている前提で、`.config/nix` の作業ツリーの現在の内容を反映する（git のステージ状態を見ないため、`git add` の有無に関わらず、未追跡の新規ファイルも含めて反映される）。`git add` は反映のためではなくコミット準備として行う。

### bump で拾えない変更

bump が更新するのは version 文字列と FOD ハッシュという、機械的に再計算できる値だけ。新版が次を変えた場合は bump 後の `switch` がビルドエラーになるので、エラーを読んで derivation を手当てする:

- **playwright-cli**: 新版で bin のパスや名前が変わると、`playwright-cli.nix` の wrapper（`--add-flags` のパス）が合わなくなる。`find` で実 bin を確認して修正する。

このため bump 後は必ず `deno task switch` までやってビルドが通ることを確認すること。

### nixpkgs 収録されたら

`@playwright/cli` が nixpkgs に収録されたら（`nix search nixpkgs playwright-cli` で確認）、自前 derivation 一式を削除して `packages.nix` の 1 行に乗り換える。
