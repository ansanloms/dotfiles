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

[chezmoi](https://www.chezmoi.io/) で chezmoi 管理分の設定（nvim・shell 等。一覧は CLAUDE.md の移行状況）をコピーする。Linux / macOS は次のとおり。

```sh
# chezmoi の設定（マシンごとに 1 回）
mkdir -p ~/.config/chezmoi
printf 'sourceDir = "~/dev/github.com/ansanloms/dotfiles"\n' > ~/.config/chezmoi/chezmoi.toml

# 差分を確認して適用
nix run nixpkgs#chezmoi -- diff
nix run nixpkgs#chezmoi -- apply
```

手順 5 で nix profile に入った後は素の `chezmoi` でよい。pull と `chezmoi apply` は同じシェルで続けて実行し、その間に新しいシェルを開かない。shell 設定の symlink が pull でリンク切れになるため、新しいシェルでは PATH が通らず `chezmoi` が見つからない。その場合は `~/.nix-profile/bin/chezmoi` を絶対パスで実行する。

以前 dot-mori が作った symlink が残っている場合、ファイルの symlink は `chezmoi apply` がファイルの内容で置き換える。ディレクトリの symlink（`~/.config/nvim`、`~/.config/sheldon`、`~/.config/zellij`、`~/.config/wezterm` 等。CLAUDE.md の移行状況の表にあるディレクトリ）は `chezmoi apply` の前に symlink だけを削除する（`rm <path>`。リンク先の中身は消えない）。旧 `.config/nvim/` に残る未追跡ファイル（`lazy-lock.json`、`lua/temp.lua`、`lua/work.lua` 等）は apply 後に `~/.config/nvim/` へ移す。

Windows（PowerShell）は次のとおり。

```powershell
winget install twpayne.chezmoi
New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\chezmoi" | Out-Null
Set-Content "$env:USERPROFILE\.config\chezmoi\chezmoi.toml" "sourceDir = 'C:\path\to\dotfiles'"
setx XDG_CONFIG_HOME "$env:USERPROFILE\.config"
# 以前 dot-mori が作ったディレクトリの symlink（~/AppData/Local/nvim、zellij、wezterm、~/.claude 配下、~/.devin/rules 等）を削除してから、新しいシェルで
chezmoi diff
chezmoi apply
```

`sourceDir` は Windows 側 clone の絶対パスに置き換える。TOML のダブルクォート文字列ではバックスラッシュがエスケープになるため、パスはシングルクォートで書く。旧 `.config/nvim/` に残る未追跡ファイル（`lazy-lock.json`、`lua/temp.lua`、`lua/work.lua` 等）は apply 後に `~/.config/nvim/` へ移す。`setx` の反映には新しいシェルが要る。pull と `chezmoi apply` は同じシェルで続けて実行する。適用後、nvim で `:echo stdpath("config")` が `~/.config/nvim` を指すことを確認する。

以前 dot-mori が作った `~/.claude/rules` `~/.claude/lsp` `~/.claude/skills` `~/.claude/agents` `~/.devin/rules` のディレクトリ symlink が残っている場合は apply 前に `rm` する（`~/.claude/CLAUDE.md` `~/.claude/settings.json` のファイル symlink は apply が内容で置き換える）。`~/.claude/skills` が symlink ではなく実ディレクトリ（Claude Code の `synced/` 等）の場合、apply はその中の管理対象（`review-loop/`）だけを書き、他には触れない。

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

## Agent Skills

`~/.apm/apm.yml` は chezmoi が配るので、先に手順 4 の `chezmoi apply` を済ませてから実行する。

[apm](https://github.com/microsoft/apm) は nix profile に入った後、user scope で skill を導入する。`apm lifecycle trust` は `~/.apm` で実行する。

```sh
(cd ~/.apm && apm lifecycle trust)
apm install -g
```

## Uninstall

```sh
deno task uninstall
```
