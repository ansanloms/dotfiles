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
# パッケージ定義（packages.nix）の変更を反映
deno task switch

# 依存（nixpkgs / nix-claude-code）を更新して反映
deno task upgrade
```

## Agent Skills

Claude Code 等の Agent Skills は [apm](https://github.com/microsoft/apm)（`packages.nix` で導入）で管理し、`.claude/skills/` に取り込んでリポジトリにコミットしている。

セットアップ時の追加作業は不要。skill 本体はコミット済みのため、`deno task install`（[Deploy dotfiles](#3-deploy-dotfiles)）で `~/.claude/skills` にシンボリックリンクされる。

skill を追加・更新する場合のみ apm を使用する。

```sh
# skill を新規追加
apm install <org>/<repo>/<skill> --target claude

# 既存 skill を最新へ更新
apm update --yes
```

`apm.yml` / `apm.lock.yaml` は commit hash でバージョンを固定している。追加・更新後は、これらと `.claude/skills/` の差分をコミットする。

## Uninstall

```sh
deno task uninstall
```
