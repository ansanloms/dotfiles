# WSL (Arch Linux) のセットアップ

Arch Linux 公式 WSL イメージを導入し、Nix と dotfiles を入れる前の初期設定の手順。前提として WSL 本体と仮想マシン プラットフォームの有効化が済んでいること ([windows.md](windows.md))。Nix 以降の手順は [../getting-started.md](../getting-started.md) にある。

## 導入

```powershell
wsl --install archlinux
```

初回起動時に pacman の鍵の生成と keyring の投入は自動で完了し、root でログインした状態で起動する。ローリングリリースのため、初回起動直後に `pacman -Syu` を実行する。

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

既定ユーザーを設定する (Windows 側で実行)。

```powershell
wsl --manage archlinux --set-default-user <username>
wsl --terminate archlinux
wsl -d archlinux
```

`whoami` が自分のユーザー名を返すこと、PID 1 が systemd で `systemctl is-system-running` が running を返すこと、`sudo -v` が通ることを確認する。

## sudo をパスワードなしにする

WSL では `wsl -u root` でパスワードなしに root へ入れるため、NOPASSWD にして失うのはディストリビューション内のプロセスに対する昇格の壁だけと判断している。一時ファイルを `visudo -c` で検査してから配置する。

```bash
echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' > /tmp/wheel
sudo visudo -c -f /tmp/wheel \
  && sudo install -m 440 -o root -g root /tmp/wheel /etc/sudoers.d/wheel
rm /tmp/wheel
sudo -k && sudo true
```

## ロケール

`ja_JP.UTF-8` が未生成だと setlocale の警告が出る。`LOCALE_ARCHIVE` の設定は不要。

```bash
sudo sed -i -e 's/^#\(ja_JP\.UTF-8 UTF-8\)/\1/' -e 's/^#\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
sudo locale-gen
locale -a
```

## Docker Engine

WSL 側のツールは原則 Nix で入れるが、Docker Engine は例外として pacman で入れる。root で常駐するデーモンと systemd ユニットが本体で、NixOS 以外では Nix でシステムサービスを管理できないため。

```bash
sudo pacman -S docker docker-buildx docker-compose
sudo systemctl enable --now docker.service
sudo usermod -aG docker <username>   # 再ログイン後に有効
```

`docker` グループのメンバーは実質 root と同等になる。

## 次の手順

Nix の導入から dotfiles の適用までは [../getting-started.md](../getting-started.md) に進む。

## 補足: Windows 側のファイル共有を DrvFs でマウントする

UNC パスの共有は DrvFs でマウントでき、資格情報は Windows 側のものが使われる (WSL 側では指定できない)。先に Windows で `Test-Path \\<host>\<share>` が通ることを確認する。

```bash
sudo mkdir -p /mnt/<host>/<share>
sudo mount -t drvfs '\\<host>\<share>' /mnt/<host>/<share>
printf '%s\n' '\\<host>\<share> /mnt/<host>/<share> drvfs defaults 0 0' | sudo tee -a /etc/fstab
```

fstab への追記は `printf` で行う。zsh の組み込み `echo` はシングルクォート内でも `\\` を `\` に変換するため、先頭のバックスラッシュが 1 本になった行が書き込まれ、起動時に「スペシャルデバイス ... が存在しません」(`/bin/mount failed with status 0x2000`) で失敗する。
