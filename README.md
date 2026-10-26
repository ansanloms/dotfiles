# dotfiles

## Setup

### 1. Clone

```sh
git clone https://github.com/ansanloms/dotfiles.git
cd dotfiles
```

### 2. Install Nix

[公式 installer](https://nixos.org/download/) を使用する（multi-user / daemon モード）。

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```

インストーラ同梱の nix はブートストラップ用。普段使いの nix client は `packages.nix` で nixpkgs 版を導入しており、`~/.nix-profile/bin` が daemon profile（`/nix/var/nix/profiles/default/bin`）より PATH で優先されるため、profile 導入後はそちらが使われる。daemon 側の nix を更新したい場合は `sudo -i nix upgrade-nix` を使う（普段の更新は client 側で完結するため頻度は低い）。

インストーラ配布バイナリは同梱 libgit2 が古く（1.9.2 < 1.9.4）、`worktree.useRelativePaths = true` で worktree を作ると刻まれる `extensions.relativeWorktrees` のあるリポジトリを git fetcher が開けない。nixpkgs 版の nix は nixpkgs の libgit2（1.9.4 以降）にリンクするため、この問題を回避できる。

### 3. Configure /etc/nix/nix.conf

公式 installer は flakes を有効化しないため、システム側で有効にする（次手順の `nix run` に必要）。あわせて、`~/.config/nix/nix.conf` の `extra-substituters` が無視されないよう trusted-users を設定する。

`/etc/nix/nix.conf` に以下を追記する。

```conf
extra-experimental-features = nix-command flakes
extra-trusted-users = <username>
```

その後、nix-daemon を再起動する。

```sh
sudo systemctl restart nix-daemon
```

### 4. Deploy dotfiles

`.local/bin/` 配下のスクリプトは `scripts/` のソースから生成するため、先にビルドする。

```sh
nix run nixpkgs#deno -- task build
```

[dot-mori](https://github.com/ansanloms/dot-mori) でシンボリックリンクを作成する。

```sh
nix run nixpkgs#deno -- task install
```

### 5. Apply packages

`.config/nix/` の flake で定義したパッケージを nix profile に導入する。

```sh
# 初回: profile に導入
nix profile add ~/.config/nix#default --impure
```

以降のパッケージ更新:

```sh
# パッケージ定義の変更を反映
nix profile upgrade --all --impure

# 依存（flake input）を更新
nix flake update --flake path:.config/nix

# プロファイルから削除
nix profile remove .config/nix
```

## Uninstall

```sh
deno task uninstall
```
