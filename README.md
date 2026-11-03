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

ビルドした生成物は、#139（bun 書き換え + nix 配布）までの暫定として `~/.local/bin` へ symlink する（リポジトリ直下で、`deno task build` の後に実行する。生成物が無いと zsh では glob が空でエラーになる）。

```sh
mkdir -p ~/.local/bin && ln -sf "$PWD"/.local/bin/git-worktree-* ~/.local/bin/
```

[chezmoi](https://www.chezmoi.io/) で chezmoi 管理分の設定（nvim・shell 等）をコピーする。Linux / macOS は次のとおり。

```sh
# chezmoi の設定（マシンごとに 1 回）
mkdir -p ~/.config/chezmoi
printf 'sourceDir = "~/dev/github.com/ansanloms/dotfiles"\n' > ~/.config/chezmoi/chezmoi.toml

# 差分を確認して適用
nix run nixpkgs#chezmoi -- diff
nix run nixpkgs#chezmoi -- apply
```

手順 5 で nix profile に入った後は素の `chezmoi` でよい。pull と `chezmoi apply` は同じシェルで続けて実行し、その間に新しいシェルを開かない。shell 設定の symlink が pull でリンク切れになるため、新しいシェルでは PATH が通らず `chezmoi` が見つからない。その場合は `~/.nix-profile/bin/chezmoi` を絶対パスで実行する。git も同様で、apply までの間はグローバル設定（excludesfile・credential helper）が無い状態になるため、その間に git 操作をしない。

以前の symlink 管理（dot-mori）から移行する場合、以前 dot-mori が作った symlink が残っていると、ファイルの symlink は `chezmoi apply` がファイルの内容で置き換える。ディレクトリの symlink（`~/.config/{nvim,sheldon,zsh,zellij,wezterm,just,git,alacritty,devin,nix}`、`~/.claude/{rules,lsp,skills,agents}`、`~/.devin/rules` 等）は `chezmoi apply` の前に symlink だけを削除する（`rm <path>`。リンク先の中身は消えない）。旧 `.config/nvim/` に残る未追跡ファイル（`lazy-lock.json`、`lua/temp.lua`、`lua/work.lua` 等）は apply 後に `~/.config/nvim/` へ移す。旧 `.config/git/` に残る未追跡の秘匿ファイル（`credentials`、`config.personal`、`config.work`）は apply 後に `~/.config/git/` へ移す。

漏れの確認には `find ~ -maxdepth 3 -lname '*dotfiles*'` で dotfiles の clone を指す symlink を列挙する（Windows は PowerShell の `Get-ChildItem -Recurse -Depth 2 ~ | Where-Object LinkType` 等で相当の確認をする）。

旧 dot-mori の残骸として `~/.config/alacritty/os.toml` の dangling symlink が残っている場合は、`chezmoi apply` の前に `rm` で削除する。

vim の設定は削除したので、dot-mori が作った `~/.vimrc` と `~/.config/vim` の symlink は手で削除する（リポジトリ側 `.config/vim/` に残る undo・viminfo 等も不要なら削除）。

Windows（PowerShell）は次のとおり。

```powershell
winget install twpayne.chezmoi
New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\chezmoi" | Out-Null
Set-Content "$env:USERPROFILE\.config\chezmoi\chezmoi.toml" "sourceDir = 'C:\path\to\dotfiles'"
setx XDG_CONFIG_HOME "$env:USERPROFILE\.config"
# 以前 dot-mori が作ったディレクトリの symlink（~/.config/{nvim,git,zellij,wezterm,just,zsh,sheldon}、~/AppData/Roaming/{alacritty,devin}、~/AppData/Local/nvim、~/.claude/{rules,lsp,skills,agents}、~/.devin/rules 等）を削除してから、新しいシェルで
chezmoi diff
chezmoi apply
```

`sourceDir` は Windows 側 clone の絶対パスに置き換える。TOML のダブルクォート文字列ではバックスラッシュがエスケープになるため、パスはシングルクォートで書く。旧 `.config/nvim/` に残る未追跡ファイル（`lazy-lock.json`、`lua/temp.lua`、`lua/work.lua` 等）は apply 後に `~/.config/nvim/` へ移す。旧 `.config/git/` に残る未追跡の秘匿ファイル（`credentials`、`config.personal`、`config.work`）は apply 後に `~/.config/git/` へ移す。`setx` の反映には新しいシェルが要る。pull と `chezmoi apply` は同じシェルで続けて実行する。適用後、nvim で `:echo stdpath("config")` が `~/.config/nvim` を指すことを確認する。

`~/.wslconfig` `~/AppData/Roaming/devin/config.json` `~/AppData/Local/noctty/*.ghostty` 等、dot-mori が Windows 側 clone へ張ったファイルの symlink は、apply がコピーに置き換える。

以前 dot-mori が作った `~/.claude/rules` `~/.claude/lsp` `~/.claude/skills` `~/.claude/agents` `~/.devin/rules` のディレクトリ symlink が残っている場合は apply 前に `rm` する（`~/.claude/CLAUDE.md` `~/.claude/settings.json` のファイル symlink は apply が内容で置き換える）。`~/.claude/skills` が symlink ではなく実ディレクトリ（Claude Code の `synced/` 等）の場合、apply はその中の管理対象（`review-loop/`）だけを書き、他には触れない。

### 5. Apply packages

`dot_config/nix/` の flake で定義したパッケージを nix profile に導入する。flake は `chezmoi apply` が `~/.config/nix` へ配るので、先に手順 4 を済ませる。

```sh
# 初回: profile に導入
nix profile add ~/.config/nix#default --impure
```

以降のパッケージ更新:

```sh
# パッケージ定義の変更を反映
chezmoi apply
nix profile upgrade --all --impure

# 依存（flake input）を更新
nix flake update --flake path:dot_config/nix
chezmoi apply

# プロファイルから削除（登録名は `nix profile list` の Name 列で確認）
nix profile remove <name>
```

既存機で dot-mori 時代の登録（`git+file://<clone>?dir=.config/nix`、名前 `.config/nix`）が残っている場合は、次の順で付け替える。

```sh
# 旧 symlink が残っていれば消す
rm -f ~/.config/nix
# ~/.config/nix がコピーで出来る
chezmoi apply
# この時点で ~/.nix-profile/bin の chezmoi・git は消える（nix 本体は installer が入れた system profile にあり、続行できる）
nix profile remove .config/nix
nix profile add ~/.config/nix#default --impure
```

## Agent Skills

`~/.apm/apm.yml` は chezmoi が配るので、先に手順 4 の `chezmoi apply` を済ませてから実行する。

[apm](https://github.com/microsoft/apm) は nix profile に入った後、user scope で skill を導入する。`apm lifecycle trust` は `~/.apm` で実行する。

```sh
(cd ~/.apm && apm lifecycle trust)
apm install -g
```
