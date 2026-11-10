# Arch Linux (非 WSL) のセットアップ

WSL ではない Arch Linux (サーバや実機) に Nix と dotfiles を入れる前の初期設定の手順。WSL 上の Arch Linux は [wsl-archlinux.md](wsl-archlinux.md) を使う。Nix 以降の手順は [../getting-started.md](../getting-started.md) にある。

## systemd-resolved の resolv.conf

systemd-resolved を使うホストでは、`/etc/resolv.conf` が stub resolver を指しているかを確認する。指していないと、Nix 導入後の `nix run` が flake registry の取得で `Could not resolve host` となる。ホスト側の `ping` や `curl` が通っていても起きる ([NixOS/nix#6770](https://github.com/NixOS/nix/issues/6770))。

指していなければ stub resolver へ向ける ([ArchWiki: systemd-resolved](https://wiki.archlinux.org/title/Systemd-resolved))。

```sh
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

## 次の手順

Nix の導入から dotfiles の適用までは [../getting-started.md](../getting-started.md) に進む。
