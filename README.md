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
deno task install
```

### 4. Apply Home Manager

[Home Manager](https://github.com/nix-community/home-manager) でパッケージをインストールする。

```sh
nix run home-manager/master -- switch --flake ~/.config/home-manager --impure
```

以降のパッケージ更新:

```sh
# パッケージ定義の適用
home-manager switch --flake ~/.config/home-manager --impure

# nixpkgs / home-manager の更新
nix flake update --flake ~/.config/home-manager
```

### 5. Setup Rust toolchain

```sh
rustup default stable
```

## Uninstall

```sh
deno task uninstall
```
