# dotfiles

## Setup

### 1. Clone

```sh
git clone https://github.com/ansanloms/dotfiles.git
cd dotfiles
```

### 2. Install Nix

[Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) を使用する。

### 3. Deploy dotfiles

`.local/bin/` 配下のスクリプトは `scripts/` のソースから生成するため、先にビルドする（[Local scripts](#local-scripts) 参照）。

```sh
nix run nixpkgs#deno -- task build
```

[dot-mori](https://github.com/ansanloms/dot-mori) でシンボリックリンクを作成する。

```sh
nix run nixpkgs#deno -- task install
```

### 4. Configure trusted-users (for Cachix substituter)

`~/.config/nix/nix.conf` の `extra-substituters` が無視されないようにする。

Determinate Nix Installer 環境では `/etc/nix/nix.conf` は自動生成のため編集不可。代わりに `/etc/nix/nix.custom.conf` に以下を追記する。

```conf
extra-trusted-users = <username>
```

その後、nix-daemon を再起動する。

```sh
sudo systemctl restart nix-daemon
```

### 5. Apply packages

`.config/nix/` の flake で定義したパッケージを nix profile に導入する。

```sh
# 初回: profile に導入
nix profile install ~/.config/nix#default --impure
```

以降のパッケージ更新:

```sh
# パッケージ定義の変更を反映
deno task switch

# 依存を更新して反映
deno task upgrade
```

## Agent Skills

Agent Skills は [apm](https://github.com/microsoft/apm)（`packages.nix` で導入）で管理し、skill 本体をリポジトリにコミットしている。セットアップ時の追加作業は不要で、`deno task install`（[Deploy dotfiles](#3-deploy-dotfiles)）で各エージェントへシンボリックリンクされる。

配置先は 2 系統ある。apm の `--target` で振り分ける。

- `.claude/skills/` → `~/.claude/skills`（Claude Code）。target は `claude`。
- `.agents/skills/` → `~/.agents/skills`（Devin CLI / Devin Desktop が参照する cross-agent ディレクトリ）。target は `agent-skills`。

skill ごとの方針は以下のとおり。

| skill | 取得元 | 配置先 |
| --- | --- | --- |
| library-docs | `ansanloms/skills`（apm） | `.claude/skills/` + `.agents/skills/` |
| empirical-prompt-tuning | `mizchi/skills`（apm, devDependencies） | `.claude/skills/` のみ |
| nvim-remote | 自作（apm 非管理） | `.agents/skills/nvim-remote`（実体）+ `.claude/skills/nvim-remote`（シンボリックリンク） |

skill を追加・更新する場合のみ apm を使用する。

```sh
# Claude Code のみに導入
apm install <org>/<repo>/<skill> --target claude

# Claude Code と cross-agent（.agents/skills/）の両方に導入
apm install <org>/<repo>/<skill> --target claude,agent-skills

# 既存 skill を最新へ更新
apm update --yes
```

nvim-remote は自作 skill のため apm を介さない。`.agents/skills/nvim-remote/` をソースとして編集し、`.claude/skills/nvim-remote` はそこへのシンボリックリンクで Claude Code へ共有する。

`apm.yml` / `apm.lock.yaml` は commit hash でバージョンを固定している。追加・更新後は、これらと `.claude/skills/` / `.agents/skills/` の差分をコミットする。

## Local scripts

`.local/bin/` 配下のコマンド（`git-worktree-select` / `git-worktree-include` 等）は、`scripts/` 以下の TypeScript を `deno bundle` で単一ファイルにビルドした生成物。依存は `deno.json` の `imports` で一元管理する。

- ソース: `scripts/*.ts`（shebang に実行時の権限フラグを記述。`deno bundle` が生成物の先頭へ引き継ぐ）
- ビルド: `deno task build` で `scripts/*.ts` を `.local/bin/<name>` に bundle し、実行ビットを付与する
- 生成物は `.gitignore` 済みでコミットしない。`deno task install` でシンボリックリンクするため、**install の前に build しておく**こと

ソースを編集したら `deno task build` で再生成する。

```sh
deno task build
```

## Uninstall

```sh
deno task uninstall
```
