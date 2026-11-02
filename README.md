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

[chezmoi](https://www.chezmoi.io/) で nvim の設定をコピーする。Linux / macOS は次のとおり。

```sh
# chezmoi の設定（マシンごとに 1 回）
mkdir -p ~/.config/chezmoi
printf 'sourceDir = "~/dev/github.com/ansanloms/dotfiles"\n' > ~/.config/chezmoi/chezmoi.toml

# 差分を確認して適用
chezmoi diff
chezmoi apply
```

以前 dot-mori が作った `~/.config/nvim` の symlink が残っている場合は、`chezmoi apply` の前に symlink だけを削除する（`rm ~/.config/nvim`。リンク先の中身は消えない）。旧 `.config/nvim/` に残る未追跡ファイル（`lazy-lock.json`、`lua/temp.lua`、`lua/work.lua` 等）は apply 後に `~/.config/nvim/` へ移す。

Windows（PowerShell）は次のとおり。

```powershell
winget install twpayne.chezmoi
New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\chezmoi" | Out-Null
Set-Content "$env:USERPROFILE\.config\chezmoi\chezmoi.toml" "sourceDir = 'C:\path\to\dotfiles'"
setx XDG_CONFIG_HOME "$env:USERPROFILE\.config"
# 以前 dot-mori が作った ~/AppData/Local/nvim の symlink を削除してから、新しいシェルで
chezmoi diff
chezmoi apply
```

`sourceDir` は Windows 側 clone の絶対パスに置き換える。TOML のダブルクォート文字列ではバックスラッシュがエスケープになるため、パスはシングルクォートで書く。旧 `.config/nvim/` に残る未追跡ファイル（`lazy-lock.json`、`lua/temp.lua`、`lua/work.lua` 等）は apply 後に `~/.config/nvim/` へ移す。`setx` の反映には新しいシェルが要る。適用後、nvim で `:echo stdpath("config")` が `~/.config/nvim` を指すことを確認する。

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
