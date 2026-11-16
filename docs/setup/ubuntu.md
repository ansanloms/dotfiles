# Ubuntu のセットアップ

Ubuntu に Nix と dotfiles を入れる前の、環境を問わない共通の初期設定の手順。Raspberry Pi 5 の Ubuntu Server 24.04 LTS で確かめた。Nix 以降の手順は [../getting-started.md](../getting-started.md) にある。

## 初回設定

ユーザーは OS の導入時に作る。Raspberry Pi Imager の OS カスタマイズで作ったユーザーは、最初から `sudo` グループに入っていた。Ubuntu には `wheel` グループが無く、sudo は `/etc/sudoers` の `%sudo ALL=(ALL:ALL) ALL` の行で許可されている。[archlinux.md](archlinux.md) の初回設定 (`wheel` への追加と sudoers の作成) は要らない。

作成したユーザーでログインし、`sudo -v` が通ることを確認する。

Nix の installer の取得に使う curl は、Ubuntu Server に最初から入っている。

## systemd-resolved の resolv.conf

Ubuntu Server の `/etc/resolv.conf` は最初から systemd-resolved の stub resolver を指している。張り替えは要らない。

```sh
ls -l /etc/resolv.conf
```

`../run/systemd/resolve/stub-resolv.conf` へのリンクになっていなければ、[archlinux.md](archlinux.md) の同じ節の手順で張り替える。

## ロケール

`ja_JP.UTF-8` が未生成だと、`.bash_profile` が `LC_ALL=ja_JP.UTF-8` を設定するため、bash のログインで setlocale の警告が出る。Ubuntu では `locale-gen` にロケール名を渡して生成する。`/etc/locale.gen` を手で編集する必要は無かった。

```sh
sudo locale-gen ja_JP.UTF-8 en_US.UTF-8
locale -a
```

## Docker Engine

ツールは原則 Nix で入れるが、Docker Engine は例外として Docker 公式の apt リポジトリから入れる。root で常駐するデーモンと systemd ユニットが本体で、NixOS 以外では Nix でシステムサービスを管理できないため。手順は [Docker の公式手順](https://docs.docker.com/engine/install/ubuntu/) に従う。

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"   # 再ログイン後に有効
```

Ubuntu では Docker のサービスが起動時に立ち上がる設定で入るため、`systemctl enable` は要らない。`sudo docker run hello-world` で動作を確認する。

`docker` グループのメンバーは実質 root と同等になる。

## ログインシェルを zsh にする

zsh は dotfiles の nix profile で入るため、[../getting-started.md](../getting-started.md) の手順 4 (パッケージの導入) まで済ませてから行う。Nix の zsh を `/etc/shells` に登録して `chsh` する。

```bash
echo "$HOME/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
chsh -s "$HOME/.nix-profile/bin/zsh"
```

入り直して zsh で起動することを確認する。初回の起動では sheldon が zsh のプラグインを取得する。zsh が壊れてログインできなくなった場合は、`sudo chsh -s /bin/bash <username>` を実行して bash に戻す。

ログインシェルを zsh にすると、`ssh <host> '<command>'` の形で実行するコマンドは `.zshenv` しか読まない。`.zshenv` は PATH に `~/.nix-profile/bin` を足さないため、nix profile のコマンドが見つからない。このときはフルパスで呼ぶ。

## 次の手順

Nix の導入から dotfiles の適用までは [../getting-started.md](../getting-started.md) に進む。ログインシェルの切り替えは上記のとおりその後に戻って行う。
