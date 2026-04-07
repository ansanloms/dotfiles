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

### 5. Apply Home Manager

[Home Manager](https://github.com/nix-community/home-manager) でパッケージをインストールする。

```sh
nix run home-manager/master -- switch --flake ~/.config/home-manager --impure
```

以降のパッケージ更新:

```sh
# nixpkgs / home-manager の更新
nix flake update --flake ~/.config/home-manager

# パッケージ定義の適用
home-manager switch --flake ~/.config/home-manager --impure
```

## Uninstall

```sh
deno task uninstall
```
