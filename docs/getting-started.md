# 導入

この dotfiles を新しい環境へ導入する手順。Windows 端末そのものの整備 (アプリの導入・WSL の作成・Windows 側での chezmoi の設定) は [setup/windows.md](setup/windows.md)、WSL ディストリビューションの初期設定は [setup/wsl-archlinux.md](setup/wsl-archlinux.md) にある。

## 方針

- 開発作業は WSL (Arch Linux) 上で行う。Windows 側は dotfiles の適用など Windows 側で必要な用途に限る。
- リポジトリは Linux 側のファイルシステムに置き、`~/dev/<service>/<owner>/<repo>` の構成で clone する (例: `~/dev/github.com/ansanloms/dotfiles`)。
- 設定は [chezmoi](https://www.chezmoi.io/) (コピー方式) で配り、コマンド類は Nix flake (`nix profile`) で入れる。WSL 側のツールは原則すべて Nix で入れる。

## 導入手順

### 1. Nix を導入する

[公式 installer](https://nixos.org/download/) を multi-user/daemon モードで使う。Arch Linux の WSL イメージには curl が無いので先に入れる。

```sh
command -v curl || sudo pacman -S --needed curl
sh <(curl -L https://nixos.org/nix/install) --daemon
```

公式 installer は flakes を有効化しないため、システム側で有効にする (次手順の `nix run` に必要)。あわせて、`~/.config/nix/nix.conf` の `extra-substituters` が無視されないよう trusted-users を設定する。`<username>` は自分のユーザー名に置き換える。

```sh
sudo tee -a /etc/nix/nix.conf <<'EOF'
extra-experimental-features = nix-command flakes
extra-trusted-users = <username>
EOF
sudo systemctl restart nix-daemon
```

シェルを開き直し、flakes の有効化と daemon 経由の実行を確認する。

```sh
nix run nixpkgs#hello
```

インストーラ同梱の nix はブートストラップ用。普段使いの nix client は `packages.nix` で nixpkgs 版を導入しており、`~/.nix-profile/bin` が daemon profile (`/nix/var/nix/profiles/default/bin`) より PATH で優先されるため、profile 導入後はそちらが使われる。daemon 側の nix を更新したい場合は `sudo -i nix upgrade-nix` を使う (普段の更新は client 側で完結するため頻度は低い)。

インストーラ配布バイナリは同梱 libgit2 が古く (1.9.2 < 1.9.4)、`worktree.useRelativePaths = true` で worktree を作ると刻まれる `extensions.relativeWorktrees` のあるリポジトリを git fetcher が開けない。nixpkgs 版の nix は nixpkgs の libgit2 (1.9.4 以降) にリンクするため、この問題を回避できる。

### 2. clone する

git が無い環境では `nix run nixpkgs#git -- clone ...` で代用する。

```sh
mkdir -p ~/dev/github.com/ansanloms
git clone https://github.com/ansanloms/dotfiles.git ~/dev/github.com/ansanloms/dotfiles
```

### 3. chezmoi で設定を配る

chezmoi 自身の設定 `~/.config/chezmoi/chezmoi.toml` は、リポジトリ直下の `.chezmoi.toml.tmpl` から `chezmoi init` が生成する。マシンごとに 1 回。source に `.git` があるので clone はされず、config の生成だけ行われる。

```sh
nix run nixpkgs#chezmoi -- --source ~/dev/github.com/ansanloms/dotfiles init
```

生成後は `--source` 無しでよい。差分を確認して適用する。手順 4 で nix profile に入った後は素の `chezmoi` でよい。

```sh
nix run nixpkgs#chezmoi -- diff
nix run nixpkgs#chezmoi -- apply
```

### 4. パッケージを導入する

`dot_config/nix/` の flake で定義したパッケージを nix profile に導入する。flake は `chezmoi apply` が `~/.config/nix` へ配るので、先に手順 3 を済ませる。

```sh
nix profile add ~/.config/nix#default --impure
```

導入後はシェルを開き直す。`~/.nix-profile/bin` に chezmoi・git・zsh 等が入る。ログインシェルを zsh へ切り替える手順は [setup/wsl-archlinux.md](setup/wsl-archlinux.md#ログインシェルを-zsh-にする) にある。

### 5. Agent Skills を導入する

`~/.apm/apm.yml` は chezmoi が配るので、手順 3 の後に実行する。[apm](https://github.com/microsoft/apm) は手順 4 で nix profile に入る。`apm lifecycle trust` は `~/.apm` で実行する (マシンごとに 1 回。`apm.yml` の `lifecycle` ブロックを編集したときも再実行する)。

```sh
(cd ~/.apm && apm lifecycle trust)
apm install -g
```

lifecycle の失敗は `apm install -g` の出力にも終了コードにも現れないため、依存を持つ skill の `node_modules` が出来たことを確認する。

```sh
ls ~/.claude/skills/ja-tech-proofread/scripts/node_modules
```

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

skill の実体はリポジトリに無いため、pull だけでは更新されない。`flake.nix` の input を変えたときは、リポジトリ側で `nix flake lock --flake path:dot_config/nix` (または `nix flake update`) を実行して `flake.lock` を更新してから `chezmoi apply` する。先に `nix profile upgrade` すると nix が `~/.config/nix` 側に lock を書き、source と食い違う。
