# dotfiles

## Setup

### 1. Clone

```sh
git clone https://github.com/ansanloms/dotfiles.git
cd dotfiles
```

### 2. Install Nix

[Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) を使用する。

```sh
# install:
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

# upgrade:
sudo determinate-nixd upgrade
```

### 3. Deploy dotfiles

`.local/bin/` 配下のスクリプトは `scripts/` のソースから生成するため、先にビルドする。

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

### 6. Enable systemd user services (WSL)

WSL の常駐サービスを有効化する。前提として WSL で systemd が有効（`/etc/wsl.conf` の `[boot]` に `systemd=true`）であること。`deno task install` でユニットが `~/.config/systemd/user/` に symlink 済みであること。

導入済みのユーザサービス:

- `notify` - WSL からの通知を Windows 側へ中継する
- `clip-image-watch` - Windows のクリップボードに入った画像を自動で `clip-image` に取り込む

```sh
# symlink したユニットを systemd に読み込ませる
systemctl --user daemon-reload

# 有効化 + 起動
systemctl --user enable --now notify
systemctl --user enable --now clip-image-watch
```

ターミナルを全て閉じてもサービスを常駐させるには、ユーザの linger を有効にする（systemd ユーザインスタンスがログインセッションに依存しなくなる）。

```sh
sudo loginctl enable-linger $USER
```

動作確認・トラブルシュート（`<service>` は `notify` / `clip-image-watch` 等）:

```sh
# 起動しているか（クラッシュループしていないか）
systemctl --user status <service>

# ログをライブで追う（例: clip-image-watch なら Win+Shift+S しながら見る）
journalctl --user -u <service> -f

# 直近のログをまとめて見る
journalctl --user -u <service> -n 50 --no-pager
```

## Uninstall

```sh
deno task uninstall
```
