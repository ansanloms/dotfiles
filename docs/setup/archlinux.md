# Arch Linux のセットアップ

Arch Linux に Nix と dotfiles を入れる前の、環境を問わない共通の初期設定の手順。WSL 固有の手順 (ディストリビューションの導入・既定ユーザーの設定・Windows 側の ssh-agent との橋渡し等) は [wsl-archlinux.md](wsl-archlinux.md) が本書を参照する形で持つ。Nix 以降の手順は [../getting-started.md](../getting-started.md) にある。

## 初回設定

root で実行する。`<username>` は自分のユーザー名に置き換える。

```bash
pacman -Syu
pacman -S --needed sudo
useradd -m -G wheel <username>
passwd <username>
passwd
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel
```

作成したユーザーでログインし直し、`sudo -v` が通ることを確認する。

## systemd-resolved の resolv.conf

systemd-resolved を使うホストでは、`/etc/resolv.conf` が stub resolver を指しているかを確認する。指していないと、Nix 導入後の `nix run` が flake registry の取得で `Could not resolve host` となる。ホスト側の `ping` や `curl` が通っていても起きる ([NixOS/nix#6770](https://github.com/NixOS/nix/issues/6770))。

指していなければ stub resolver へ向ける ([ArchWiki: systemd-resolved](https://wiki.archlinux.org/title/Systemd-resolved))。

```sh
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

## ロケール

`ja_JP.UTF-8` が未生成だと setlocale の警告が出る。`LOCALE_ARCHIVE` の設定は不要。

```bash
sudo sed -i -e 's/^#\(ja_JP\.UTF-8 UTF-8\)/\1/' -e 's/^#\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
sudo locale-gen
locale -a
```

## Docker Engine

ツールは原則 Nix で入れるが、Docker Engine は例外として pacman で入れる。root で常駐するデーモンと systemd ユニットが本体で、NixOS 以外では Nix でシステムサービスを管理できないため。

```bash
sudo pacman -S docker docker-buildx docker-compose
sudo systemctl enable --now docker.service
sudo usermod -aG docker "$USER"   # 再ログイン後に有効
```

`docker` グループのメンバーは実質 root と同等になる。

## ログインシェルを zsh にする

zsh は dotfiles の nix profile で入るため、[../getting-started.md](../getting-started.md) の手順 4 (パッケージの導入) まで済ませてから行う。Nix の zsh を `/etc/shells` に登録して `chsh` する。

```bash
echo "$HOME/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
chsh -s "$HOME/.nix-profile/bin/zsh"
```

入り直して zsh で起動することを確認する。zsh が壊れてログインできなくなった場合は、root で `chsh -s /bin/bash <username>` を実行して bash に戻す。

## 次の手順

Nix の導入から dotfiles の適用までは [../getting-started.md](../getting-started.md) に進む。ログインシェルの切り替えは上記のとおりその後に戻って行う。
