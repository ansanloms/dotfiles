# 導入

この dotfiles を新しい環境へ導入する手順。

Windows 端末そのものの整備 (アプリの導入・WSL の作成・Windows 側での chezmoi の設定) は [setup/windows.md](setup/windows.md)、WSL ディストリビューションの初期設定は [setup/wsl-archlinux.md](setup/wsl-archlinux.md)、WSL ではない Arch Linux の初期設定は [setup/archlinux.md](setup/archlinux.md) にある。

## 方針

- リポジトリは Linux 側のファイルシステムに置き、`~/dev/<service>/<owner>/<repo>` の構成で clone する (例: `~/dev/github.com/ansanloms/dotfiles`)。
- 設定は [chezmoi](https://www.chezmoi.io/) で配り、コマンド類は Nix flake (`nix profile`) で入れる。コマンド類は原則すべて Nix で入れる。

## 導入手順

### 1. Nix を導入する

[公式 installer](https://nixos.org/download/) を multi-user/daemon モードで使う。installer の取得に curl を使うため、無い環境では OS のパッケージマネージャで先に入れる。

```sh
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
```

公式 installer は flakes を有効化しないため、システム側で有効にする (次手順の `nix run` に必要)。

あわせて、`~/.config/nix/nix.conf` の `extra-substituters` が無視されないよう trusted-users を設定する。

```sh
sudo tee -a /etc/nix/nix.conf <<EOF
extra-experimental-features = nix-command flakes
extra-trusted-users = $USER
EOF
sudo systemctl restart nix-daemon
```

シェルを開き直し、flakes の有効化と daemon 経由の実行を確認する。

```sh
nix run nixpkgs#hello
```

インストーラ同梱の nix はブートストラップ用。普段使いの nix client は `packages.nix` で nixpkgs 版を導入しており、`~/.nix-profile/bin` が daemon profile (`/nix/var/nix/profiles/default/bin`) より PATH で優先されるため、profile 導入後はそちらが使われる。

daemon 側の nix を更新したい場合は `sudo -i nix upgrade-nix` を使う (普段の更新は client 側で完結するため頻度は低い)。

> [!WARNING]
>
> インストーラ配布バイナリは同梱 libgit2 が古く (1.9.2 < 1.9.4)、`worktree.useRelativePaths = true` で worktree を作ると刻まれる `extensions.relativeWorktrees` のあるリポジトリを git fetcher が開けない。nixpkgs 版の nix は nixpkgs の libgit2 (1.9.4 以降) にリンクするため、この問題を回避できる。

### 2. clone する

```sh
mkdir -p ~/dev/github.com/ansanloms
nix run nixpkgs#git -- clone https://github.com/ansanloms/dotfiles.git ~/dev/github.com/ansanloms/dotfiles
```

### 3. chezmoi で設定を配る

chezmoi 自身の設定 `~/.config/chezmoi/chezmoi.toml` は、リポジトリ直下の `.chezmoi.toml.tmpl` から `chezmoi init` が生成する。

source に `.git` があるので clone はされず、config の生成だけ行われる。

```sh
nix run nixpkgs#chezmoi -- --source ~/dev/github.com/ansanloms/dotfiles init
```

生成後は `--source` 無しでよい。差分を確認して適用する。

```sh
nix run nixpkgs#chezmoi -- diff
nix run nixpkgs#chezmoi -- apply
```

### 4. パッケージを導入する

`dot_config/nix/` の flake で定義したパッケージを nix profile に導入する。

```sh
nix profile add ~/.config/nix#default --impure
```

### 5. Agent Skills を導入する

```sh
(cd ~/.apm && apm lifecycle trust)
apm install -g
```

lifecycle の失敗は `apm install -g` の出力にも終了コードにも現れないため、依存を持つ skill の `node_modules` が出来たことを確認する。

```sh
ls ~/.claude/skills/ja-tech-proofread/scripts/node_modules
```

## フォント

フォントは次の 2 つを使う。

- Moralerspace: Monaspace と IBM Plex Sans JP などを合成したプログラミング向けフォントで、SIL Open Font License 1.1。出典: [yuru7/moralerspace](https://github.com/yuru7/moralerspace)
- Source Han Sans JP: 源ノ角ゴシックの日本語サブセット OTF で、SIL Open Font License 1.1。出典: [adobe-fonts/source-han-sans](https://github.com/adobe-fonts/source-han-sans)

導入は chezmoi に任せる。`chezmoi apply` が `.chezmoiexternal.toml` に従って各フォントの zip を取得し、OS ごとのユーザーフォントディレクトリへ展開する。管理者権限は要らない。

| OS      | 展開先                                   | 補足                                                                              |
| ------- | ---------------------------------------- | --------------------------------------------------------------------------------- |
| Linux   | `~/.local/share/fonts`                   | fontconfig の既定設定が見るディレクトリ。反映されなければ `fc-cache` を実行する。 |
| macOS   | `~/Library/Fonts`                        | この repo では未検証。                                                            |
| Windows | `%LOCALAPPDATA%\Microsoft\Windows\Fonts` | 続けて `run_onchange_after_register-fonts.ps1` が HKCU の Fonts キーへ登録する。  |

バージョンはフォントごとに `.chezmoiexternal.toml` の `url` と `checksum.sha256` の 2 箇所で固定している。GitHub Actions の `font-bump` workflow が毎週 latest release を見て 2 箇所を書き換え、展開を検証したうえで main にコミットする。各機では `chezmoi apply --refresh-externals` で取り直す。

手動で上げるときは新しい zip の SHA-256 を `Get-FileHash -Algorithm SHA256 <zip>` (PowerShell) または `sha256sum <zip>` で求め、同じ 2 箇所を書き換える。

## 更新

```sh
# chezmoi 管理分の差分確認と適用
chezmoi diff
chezmoi apply

# パッケージ定義 (packages.nix / *.nix / flake.lock) の変更を反映。先に chezmoi apply で届ける
chezmoi apply
nix profile upgrade --all --impure

# flake input (nixpkgs / llm-agents) を更新 (リポジトリ直下が cwd の前提)
nix flake update --flake path:dot_config/nix
chezmoi apply

# プロファイルから削除 (登録名は `nix profile list` の Name 列で確認)
nix profile remove <name>

# dot_apm/apm.lock.yaml が変わるコミットを pull したとき
chezmoi apply
apm install -g
```

skill の実体はリポジトリに無いため、pull だけでは更新されない。`flake.nix` の input を変えたときは、リポジトリ側で `nix flake lock --flake path:dot_config/nix` (または `nix flake update`) を実行して `flake.lock` を更新してから `chezmoi apply` する。

先に `nix profile upgrade` すると nix が `~/.config/nix` 側に lock を書き、source と食い違う。
