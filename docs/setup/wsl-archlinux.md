# WSL (Arch Linux) のセットアップ

Arch Linux 公式 WSL イメージを導入し、Nix と dotfiles を入れる前の初期設定のうち、WSL 固有の手順。環境を問わない共通の初期設定 (ユーザー作成・ロケール・Docker Engine・ログインシェル) は [archlinux.md](archlinux.md) にあり、本書はそこへの参照と WSL 固有の差分だけを持つ。開発作業は WSL (Arch Linux) 上で行い、Windows 側は dotfiles の適用など Windows 側で必要な用途に限る。前提として WSL 本体と仮想マシン プラットフォームの有効化が済んでいること ([windows.md](windows.md))。Nix 以降の手順は [../getting-started.md](../getting-started.md) にある。

## 導入

```powershell
wsl --install archlinux
```

初回起動時に pacman の鍵の生成と keyring の投入は自動で完了し、root でログインした状態で起動する。ローリングリリースのため、初回起動直後に `pacman -Syu` を実行する。

## 初回設定

ユーザーの作成と sudo の設定は [archlinux.md](archlinux.md) の「初回設定」に従う。ログインし直す代わりに、既定ユーザーを設定する (Windows 側で実行)。

```powershell
wsl --manage archlinux --set-default-user <username>
wsl --terminate archlinux
wsl -d archlinux
```

`whoami` が自分のユーザー名を返すこと、PID 1 が systemd で `systemctl is-system-running` が running を返すこと、`sudo -v` が通ることを確認する。

既定のディストリビューションを archlinux にする (Windows 側で実行)。`wsl --status` の既定のディストリビューションが archlinux になることを確認する。

```powershell
wsl --set-default archlinux
```

## sudo をパスワードなしにする

WSL では `wsl -u root` でパスワードなしに root へ入れるため、NOPASSWD にして失うのはディストリビューション内のプロセスに対する昇格の壁だけと判断している。一時ファイルを `visudo -c` で検査してから配置する。

```bash
echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' > /tmp/wheel
sudo visudo -c -f /tmp/wheel \
  && sudo install -m 440 -o root -g root /tmp/wheel /etc/sudoers.d/wheel
rm /tmp/wheel
sudo -k && sudo true
```

## 共通の初期設定

ロケールと Docker Engine は [archlinux.md](archlinux.md) の該当節に従う。WSL 固有の差分は無い。

## ログインシェルを zsh にする

手順は [archlinux.md](archlinux.md) の「ログインシェルを zsh にする」に従う。zsh が壊れてログインできなくなった場合は、Windows 側から `wsl -d archlinux -u root -- chsh -s /bin/bash <username>` で bash に戻せる。

## ssh-agent (Windows 側の agent を使う)

SSH の秘密鍵は Windows 側の OpenSSH Authentication Agent に持たせる ([windows.md](windows.md))。WSL からは wsl2-ssh-agent で橋渡しする。wsl2-ssh-agent は dotfiles の nix profile で入り、`.zshrc`/`.bashrc` が WSL 上では `eval "$(wsl2-ssh-agent)"` を実行して `SSH_AUTH_SOCK` を `~/.ssh/wsl2-ssh-agent.sock` に向ける。初回は daemon を起動し、以降のシェルは起動済みの daemon を再利用する。daemon は PowerShell.exe を子プロセスとして起こし、Windows 側の名前付きパイプ `openssh-ssh-agent` へ中継する。

[../getting-started.md](../getting-started.md) の手順 4 (パッケージの導入) まで済ませ、Windows 側で鍵をサービスに登録した後、シェルを開き直して Windows 側の鍵が見えることを確認する。

```bash
echo "$SSH_AUTH_SOCK"
ssh-add -l
ssh -T git@github.com
```

`ssh-add -l` が Windows 側で登録した鍵を返せば橋渡しは動いている。`Could not open a connection to your authentication agent` が出る場合は、まず Windows 側で `Get-Service ssh-agent` が `Running` であること、PowerShell から `ssh-add -l` が鍵を返すことを確認する。WSL 側の daemon を作り直すときは `wsl2-ssh-agent -stop` で止めてシェルを開き直す。`wsl2-ssh-agent --verbose --foreground` で前景起動すると中継の過程がログに出る。

WSL 内に ssh-agent を立てる構成は採らない。WSL インスタンスは最後の端末を閉じると停止するため、WSL 側の agent に載せた鍵は端末を閉じるごとに消える。

## 次の手順

Nix の installer は curl で取得するが、Arch Linux の WSL イメージには curl が無いため先に入れる。この時点では Nix が無いので pacman で入れる。

```bash
sudo pacman -S --needed curl
```

Nix の導入から dotfiles の適用までは [../getting-started.md](../getting-started.md) に進む。ログインシェルの切り替えは上記のとおりその後に戻って行う。

## 補足: Windows 側のファイル共有を DrvFs でマウントする

UNC パスの共有は DrvFs でマウントでき、資格情報は Windows 側のものが使われる (WSL 側では指定できない)。先に Windows で `Test-Path \\<host>\<share>` が通ることを確認する。

```bash
sudo mkdir -p /mnt/<host>/<share>
sudo mount -t drvfs '\\<host>\<share>' /mnt/<host>/<share>
printf '%s\n' '\\<host>\<share> /mnt/<host>/<share> drvfs defaults 0 0' | sudo tee -a /etc/fstab
```

fstab への追記は `printf` で行う。zsh の組み込み `echo` はシングルクォート内でも `\\` を `\` に変換するため、先頭のバックスラッシュが 1 本になった行が書き込まれ、起動時に「スペシャルデバイス ... が存在しません」(`/bin/mount failed with status 0x2000`) で失敗する。
