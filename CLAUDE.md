# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

個人用 dotfiles。[dot-mori](https://github.com/ansanloms/dot-mori) (Deno) でシンボリックリンクを管理し、Nix flake (`nix profile`) でパッケージを管理する。

## コマンド

```sh
# dotfiles インストール（シンボリックリンク作成）
deno task install

# dotfiles アンインストール（シンボリックリンク削除）
deno task uninstall

# パッケージ初回導入
nix profile install path:.config/nix#default --impure

# パッケージ適用（packages.nix の変更を反映）
deno task switch

# パッケージ更新（nixpkgs / llm-agents を更新して反映）
deno task upgrade
```

## 構成

- `config.yaml` - シンボリックリンク設定（OS別: windows/linux/darwin）
- `.config/nix/` - Nix 設定（nix.conf）と flake によるパッケージ管理（flake.nix + packages.nix）
- `.config/nvim/` - Neovim 設定（Lua）
- `.config/vim/` - Vim 設定（minpac でプラグイン管理）
- `.config/git/` - Git 設定
- `.config/wezterm/` - WezTerm 設定
- `.config/zellij/` - Zellij 設定
- `.config/starship.toml` - Starship プロンプト設定
- `.config/sheldon/` - Sheldon（zsh プラグインマネージャ）設定
- `.claude/` - Claude Code のグローバル設定（`~/.claude/` にリンク）
- `.local/bin/` - ユーザースクリプト（`scripts/` から `deno bundle` で生成）

## Agent Skills

Agent Skills は [apm](https://github.com/microsoft/apm)（`packages.nix` で導入）で管理し、skill 本体をリポジトリにコミットしている。`deno task install` で各エージェントへシンボリックリンクされる。

skill の実体は `.agents/skills/` の 1 箇所に置く。`~/.agents/skills`（Devin CLI / Devin Desktop が参照する cross-agent ディレクトリ）と `~/.claude/skills`（Claude Code）は、どちらも `.agents/skills/` を指すシンボリックリンク（`config.yaml` で設定）。両エージェントが同一実体を参照し、claude 専用・cross-agent 専用の配置区別は持たない。

apm のデプロイ先は `apm.yml` の `targets: [agent-skills]` で `.agents/skills/` に固定している。target の解決順は `--target` > `apm.yml` の `targets:` > auto-detect で、この固定により install 時に `--target` を省略しても `.agents/skills/` へ配置される（省略時の auto-detect は `.claude/` の存在を見て `claude` を選ぶため、固定が無いと `.claude/` 側へ流れる）。

導入済み skill:

| skill                   | 取得元                    |
| ----------------------- | ------------------------- |
| find-docs               | `ansanloms/skills`（apm） |
| empirical-prompt-tuning | `mizchi/skills`（apm）    |
| nvim-remote             | `ansanloms/skills`（apm） |
| worktree                | `ansanloms/skills`（apm） |

skill を追加・更新する場合のみ apm を使用する。`apm.yml` の `targets` で配置先（`.agents/skills/`）を固定済みのため、install は `--target` 無しでよい。

```sh
# skill の追加・更新（apm.yml の targets: agent-skills により .agents/skills/ へ配置）
apm install <org>/<repo>/<skill>#<commit>
```

更新も同じ install で commit を上げる。`apm update` は使わない。`apm update` は最新の一致 ref へ更新してしまい、commit hash 固定と噛み合わないため。最新 commit は `git ls-remote <repo> HEAD` 等で確認する。

`apm.yml` / `apm.lock.yaml` は commit hash でバージョンを固定している。追加・更新後は、これらと `.agents/skills/` の差分をコミットする。

## Local scripts

`.local/bin/` 配下のコマンド（`git-worktree-select` / `git-worktree-include` 等）は、`scripts/` 以下の TypeScript を `deno bundle` で単一ファイルにビルドした生成物。依存は `deno.json` の `imports` で一元管理する。

- ソース: `scripts/*.ts`（shebang に実行時の権限フラグを記述。`deno bundle` が生成物の先頭へ引き継ぐ）
- ビルド: `deno task build` で `scripts/*.ts` を `.local/bin/<name>` に bundle し、実行ビットを付与する
- 生成物は `.gitignore` 済みでコミットしない。`deno task install` でシンボリックリンクするため、**install の前に build しておく**こと

ソースを編集したら `deno task build` で再生成する。

導入済みコマンド:

- `git-worktree-select` / `git-worktree-include` - worktree の選択・ローカル設定持ち込み
- `clip-image` - Windows ホストのクリップボード画像（Win+Shift+S 等）を WSL の PNG に保存し絶対パスを stdout へ出力する（WSL 専用）。`powershell.exe` で画像を取得し native NTFS の一時領域へ書き出してから `~/.cache/clip-image/` へコピーする。保存と同時に `~/.cache/clip-image/latest.png` を最新キャプチャへ張り替える（自動実行時の固定参照先）。nvim では `:r !clip-image`、claude code ではシェルから実行してパスを渡す。`--copy-path`（`-c`）で保存先パスを OSC 52 でクリップボードへ載せ、入力欄に Ctrl+V でパスを貼れるようにする（OSC 52 は `/dev/tty` へ直接書き stdout を汚さない）

`scripts/` のソースは「薄いエントリポイント（`scripts/*.ts`）＋ 純粋ロジック / 依存注入した `run()`（`scripts/lib/*.ts`）」に分離している。副作用（subprocess / fs / tty / 対話プロンプト等）を注入することでテスト可能にし、`scripts/lib/*.test.ts` でユニットテストする（`deno task test` / `deno task coverage`）。`scripts/lib/` はサブディレクトリのため `deno task build` の bundle 対象から自然に外れる。

## クリップボード画像の自動取り込み（Windows 常駐リスナ）

Windows のクリップボードに画像が入ったら自動で `clip-image` を実行する常駐リスナ（Windows 専用）。

- `AppData/Local/clip-image-watch.ps1` - `AddClipboardFormatListener`（`WM_CLIPBOARDUPDATE`）でクリップボード更新をイベント購読し、画像のときだけ `wsl.exe bash -lc '~/.local/bin/clip-image'` を起動する。ポーリングしない。`clip-image`（`--copy-path` なし）は Windows クリップボードを書き換えないためループしない。多重起動は名前付き Mutex で防ぐ。
- `AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/clip-image-watch.vbs` - ログオン時にコンソールを出さず（hidden）リスナを起動する Startup ランチャ。`%LOCALAPPDATA%\clip-image-watch.ps1` を `powershell -WindowStyle Hidden` で起動する。
- 取り込んだ画像は `~/.cache/clip-image/latest.png` で参照する（nvim / claude code から固定パスで読む）。
- 反映には Windows 側で `deno task install`（symlink 作成）後、再ログオンするか `.vbs` を一度手動実行する。

## 自前 nix パッケージの更新

`.config/nix/` には nixpkgs 未収録のパッケージを自前 derivation で管理している。

- `playwright-cli.nix`（`@playwright/cli`、npm パッケージ / buildNpmPackage、wrapper で nixpkgs `google-chrome` を駆動）
- `sonarqube-cli.nix`（SonarQube CLI、コマンド名 `sonar`。SonarSource 配布のプリビルド ELF を fetchurl で取得し raw のまま導入する。配布物は Bun standalone 実行ファイルで、末尾 trailer に埋め込みアプリを持つ。patchelf / strip で ELF を書き換えると trailer が壊れ素の Bun CLI にフォールバックするため fixup を一切かけない。代わりにシステムの glibc / ローダに依存する＝FHS 環境専用。nixpkgs 収録の `sonar-scanner-cli` は別物の旧スキャナ）
- `moddable-sdk.nix`（Moddable SDK の CLI ツール `mcconfig` / `mcrun` / `mcpack` 等。Linux 専用。GTK ベースの GUI（xsbug / mcsim）はビルドしない。fetchFromGitHub で public ブランチの特定コミットを取得し、sub-makefile（xsc/xsid/xsl/serial2xsbug/tools）だけをビルドする。CLI ツールは単一マルチコールバイナリ `tools` への bash ラッパで、実行時に環境変数 `MODDABLE` が SDK ツリーを指す必要があるため、SDK ツリー一式を `$out/share/moddable` へ展開し各ツールを `MODDABLE` 付きで wrap する。SDK ツリーは read-only（store）のため、アプリビルド時は `mcconfig -o <書き込み可能なディレクトリ>` で出力先を明示する。nixpkgs 未収録。タグは 2022 年止まりなので tag ではなく public のコミットに pin する）

### バージョンを上げる

`deno task bump`（全パッケージ）/ `deno task bump:<name> [version]`（version 省略で最新）で、version・ハッシュ（playwright-cli は lockfile も）を更新する。具体的な処理は各スクリプトを参照:

- `.config/nix/playwright-cli/upgrade.ts`（最新は npm レジストリ、FOD は prefetch-npm-deps）
- `.config/nix/sonarqube-cli/upgrade.ts`（最新は GitHub releases の latest tag、hash は nix store prefetch-file。配布リリース番号は `1.1.0.3122` 形式）
- `.config/nix/moddable-sdk/upgrade.ts`（最新は `git ls-remote ... public` の HEAD、hash と取得ツリーの storePath は `nix flake prefetch`、version は storePath の `tools/VERSION`。引数でコミット指定も可）

bump はファイルを書き換えるだけで反映はしない。完了後に `git diff` で確認してから `deno task switch` で反映する。`switch` = `nix profile upgrade --all --impure` はプロファイルが `path:.config/nix#default` で登録されている前提。この `path:` はリポジトリ内にあるため nix はリポジトリの git tree を flake ソースとして使う。git tree flake は **tracked ファイルしか** store にコピーしない（追跡済みファイルの変更は作業ツリーの内容がそのまま反映されるが、未追跡の新規ファイルは除外され `path ... does not exist` でビルドが落ちる）。

このため、bump で既存ファイルの version / hash を書き換えただけなら `git add` 不要で `switch` が反映する。一方、新規 `.nix` ファイル等を追加したときは `switch` の前に `git add` して tracked にしておく必要がある。

### bump で拾えない変更

bump が更新するのは version 文字列と FOD ハッシュという、機械的に再計算できる値だけ。新版が次を変えた場合は bump 後の `switch` がビルドエラーになるので、エラーを読んで derivation を手当てする:

- **playwright-cli**: 新版で bin のパスや名前が変わると、`playwright-cli.nix` の wrapper（`--add-flags` のパス）が合わなくなる。`find` で実 bin を確認して修正する。
- **sonarqube-cli**: bump 後は `sonar -h` で本物の SonarQube CLI help が出ることを必ず確認する。Bun の help（`bun <command>` の usage）や `--version` が Bun のバージョンを返す場合、配布物の埋め込み構造が変わって raw 導入では動かなくなったサイン。`dontFixup` のままラップ方式（buildFHSEnv 等）への切り替えを検討する。
- **moddable-sdk**: 新版で release ターゲットの sub-makefile 構成（`xsc.mk` / `tools.mk` 等のパスや並び）や CLI ツールの一覧が変わると、`buildPhase` の make 呼び出しや `cliTools` のラップ対象がずれる。bump 後は `nix build` が通ること、`mcconfig` が実行できることを確認する。アプリビルドの C コンパイル段（`x-cli-lin` は `gio-2.0` 依存）が動くかは wrapper の `runtimeInputs` / `PKG_CONFIG_PATH` に依存するため、依存が増えた場合はそこを手当てする。

このため bump 後は必ず `deno task switch` までやってビルドが通ることを確認すること。

### nixpkgs 収録されたら

`@playwright/cli` が nixpkgs に収録されたら（`nix search nixpkgs playwright-cli` で確認）、自前 derivation 一式を削除して `packages.nix` の 1 行に乗り換える。

`sonarqube-cli`（コマンド `sonar`）も nixpkgs に収録されたら、`sonarqube-cli.nix` と flake.nix の overlay を削除して `packages.nix` の 1 行に乗り換える。

`moddable-sdk` も nixpkgs に収録されたら（`nix search nixpkgs moddable` で確認）、`moddable-sdk.nix` と flake.nix の overlay を削除して `packages.nix` の 1 行に乗り換える。
