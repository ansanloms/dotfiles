# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

個人用 dotfiles。[dot-mori](https://github.com/ansanloms/dot-mori) (Deno) でシンボリックリンクを管理し、Nix flake (`nix profile`) でパッケージを管理する。dot-mori から chezmoi (コピー方式、`packages.nix` で導入) への段階移行中で、移行済みの設定は chezmoi が、未移行の設定は dot-mori が管理する。

## コマンド

```sh
# dotfiles インストール（シンボリックリンク作成）
deno task install

# dotfiles アンインストール（シンボリックリンク削除）
deno task uninstall

# chezmoi 管理分の差分確認と適用
chezmoi diff
chezmoi apply

# パッケージ初回導入（chezmoi apply で配った ~/.config/nix を指す）
nix profile add ~/.config/nix#default --impure

# パッケージ適用（packages.nix / *.nix / flake.lock の変更を反映。先に chezmoi apply で届ける）
chezmoi apply
nix profile upgrade --all --impure

# flake input（nixpkgs / llm-agents）を更新（リポジトリ直下が cwd の前提）
nix flake update --flake path:dot_config/nix
chezmoi apply
```

## 構成

- `config.yaml` - シンボリックリンク設定（OS別: windows/linux/darwin）
- `dot_config/nix/` - Nix 設定（nix.conf）と flake によるパッケージ管理（flake.nix + packages.nix）。chezmoi 管理で `~/.config/nix` へコピー
- `dot_config/nvim/` - Neovim 設定（Lua）。chezmoi 管理（下記「chezmoi」節）
- `dot_config/git/` - Git 設定。chezmoi 管理
- `dot_config/wezterm/` - WezTerm 設定。chezmoi 管理
- `AppData/Local/noctty/` - Ghostty 設定（Windows では Ghostty フォークの noctty が読む。`config.ghostty` が共通、`os.ghostty` が Windows 固有。chezmoi 管理）
- `dot_config/alacritty/` - Alacritty 設定。chezmoi 管理。Windows は `AppData/Roaming/alacritty/` の include stub から配る
- `dot_config/devin/` - Devin 設定。chezmoi 管理。Windows は `AppData/Roaming/devin/` の include stub から配る
- `dot_config/zellij/` - Zellij 設定。chezmoi 管理
- `dot_config/starship.toml` - Starship プロンプト設定。chezmoi 管理
- `dot_config/just/` - just のグローバル justfile。chezmoi 管理
- `dot_ripgreprc` - ripgrep の設定。chezmoi 管理
- `dot_config/zsh/` - zsh のプロンプト設定（prompt.zsh）。chezmoi 管理
- `dot_config/sheldon/` - Sheldon（zsh プラグインマネージャ）設定
- `dot_bashrc` / `dot_bash_profile` / `dot_bash_aliases` / `dot_zshenv` / `dot_zshrc` / `dot_zprofile` / `dot_inputrc` - shell の rc ファイル。chezmoi 管理
- `.claude/` - このリポジトリの project 設定 (worktrees・jobs・settings.local.json)。グローバル設定は `dot_claude/` に移した
- `dot_claude/` - Claude Code のグローバル設定 (`CLAUDE.md` `settings.json` `rules/` `agents/` `lsp/` `skills/review-loop/`)。chezmoi 管理で `~/.claude/` へコピーする。`rules/` は `dot_devin/rules/*.md.tmpl` から `include` して `~/.devin/rules` にも配る。rules を追加・削除したら `dot_devin/rules/` の stub も同じ名前で追加・削除する (自動では配られない)。
- `dot_apm/` - apm の manifest と lock (`~/.apm/` へコピー。下記「Agent Skills」節)
- `.local/bin/` - ユーザースクリプト（`scripts/` から `deno bundle` で生成）

## chezmoi

source はリポジトリ直下。chezmoi は `.` 始まりのエントリを既定で無視するため、dot-mori 管理の `.config/` 等とは衝突しない。それ以外のリポジトリ管理ファイル（README.md・config.yaml・scripts 等）は `.chezmoiignore` で除外しており、移行が進んで不要になった行は削除する。

- 管理対象は `dot_` 接頭辞で表す（`dot_config/nvim/` → `~/.config/nvim/`）。mode は既定の file（コピー）。symlink ではないため、`~/.config/nvim` を直接編集した場合は `chezmoi re-add` で source に取り込む。source 側を編集した場合は `chezmoi apply`。`chezmoi edit --apply <target>` で両方を一度にできる。管理対象ディレクトリの中のドットファイルも同様に `dot_` 接頭辞にする（`dot_config/nvim/dot_luarc.json` → `~/.config/nvim/.luarc.json`）。source 側で `.` 始まりのままだと chezmoi が無視して適用されない。
- `exact_` は付けない。nvim が target 側に書く `lazy-lock.json` や、ローカル専用の `lua/temp.lua` を消さないため。これらはリポジトリに置かない（`.chezmoiignore` で target パスを除外しており `chezmoi add` / `apply` の対象にならない。`.gitignore` の該当行は git 側の安全網）。同じ理由で `~/.claude/skills/`（apm が置く skill と Claude Code の `synced/` キャッシュ）にも付けない。
- マシンごとの設定は `~/.config/chezmoi/chezmoi.toml` に `sourceDir = "~/dev/github.com/ansanloms/dotfiles"` の 1 行を書く（Windows は `%USERPROFILE%\.config\chezmoi\chezmoi.toml`。`~` 展開は Windows で未確認のため絶対パスで書く。TOML のダブルクォート文字列ではバックスラッシュがエスケープになるため、Windows のパスはシングルクォートの literal string で書く。例: `sourceDir = 'C:\path\to\dotfiles'`）。`chezmoi init` は使わない（ローカルパスを source にする手順が公式文書に無い）。
- Windows は環境変数 `XDG_CONFIG_HOME` を `%USERPROFILE%\.config` にし、nvim に `~/.config/nvim` を読ませる。これにより nvim の source に OS 分岐は無い。`XDG_CONFIG_HOME` を読む他ツールの探索先も変わりうる点に注意。
- `~/.claude` 配下と `~/.apm` もコピー方式。`~/.claude` `~/.apm` に限らず、アプリが自分で書き換える設定（devin の `config.json`、Windows Terminal の `settings.json`、CorvusSKK の `config.xml` 等）は `chezmoi diff` → `chezmoi re-add` でリポジトリへ取り込む。Windows の `AppData/.../*.tmpl`（include stub）と `~/.devin/rules/*.md` はテンプレートなので re-add できず、source 側（`dot_config/<name>/`、rules は `~/.claude/rules`）を直す。
- Linux と Windows で配布先が異なる設定は、`dot_config/<name>/` を実体にし、`AppData/.../<name>/<file>.tmpl` の `include` stub で Windows 側に配る。`dot_config/<name>/` にファイルを足したら（include 元の断片のように target に置かないファイルは除く）、Windows 用の `AppData/.../<name>/<file>.tmpl` の stub も同じ名前で足す（自動では配られない）。OS ごとの要否は `.chezmoiignore` の `.chezmoi.os` 分岐で制御する（shell 設定は Windows に配らない等）。
- 空になりうるファイル (alacritty の `os.toml` の Linux 版等) は `empty_` 接頭辞を付け、空でも target に作る。
- OS で内容が変わる 1 ファイルは `<name>.tmpl` にして `{{ include "..." }}` で OS 別の断片を取り込む (`dot_config/git/config.os.tmpl` が `config.linux` / `config.windows` を `.chezmoi.os` で選ぶ)。断片そのものは `.chezmoiignore` で target から外す。`.tmpl` のファイルは `chezmoi re-add` の対象外なので、直すときは source 側を編集する。

移行状況:

| 設定                                                                       | 管理                                                                                                                                                       |
| -------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| nvim                                                                       | chezmoi (`dot_config/nvim/`)                                                                                                                               |
| shell (bash / zsh / sheldon)                                               | chezmoi (`dot_bashrc` 等、`dot_config/zsh/`、`dot_config/sheldon/`)                                                                                        |
| 共通設定 (starship / zellij / just / ripgrep / wezterm)                    | chezmoi (`dot_config/starship.toml`、`dot_config/zellij/`、`dot_config/just/`、`dot_config/wezterm/`、`dot_ripgreprc`)                                     |
| .claude / .devin (rules) / .apm                                            | chezmoi (`dot_claude/`、`dot_devin/rules/*.md.tmpl`、`dot_apm/`)                                                                                           |
| nix                                                                        | chezmoi (`dot_config/nix/`。`*/upgrade.sh` は配らない)                                                                                                     |
| git                                                                        | chezmoi (`dot_config/git/`、config.os は tmpl)                                                                                                             |
| Windows 専用 (AppData / Documents / .wslconfig / noctty)、devin、alacritty | chezmoi (`AppData/`、`Documents/`、`dot_wslconfig`、`dot_config/devin/`、`dot_config/alacritty/`。Windows 側は `AppData/Roaming/<name>/*.tmpl` の include) |
| 上記以外                                                                   | dot-mori (`config.yaml`)                                                                                                                                   |

## Agent Skills

Agent Skills は [apm](https://github.com/microsoft/apm)（`packages.nix` で導入）の user scope（`apm install -g`）で管理する。manifest と lock は `dot_apm/apm.yml` / `dot_apm/apm.lock.yaml` にあり、chezmoi が `~/.apm/` へコピーする。`apm install -g` は `~/.apm/apm.yml` を読み、`targets: [claude]` により skill を `~/.claude/skills/<name>/` に配置する。取得物は `~/.apm/apm_modules/`。

skill の実体はリポジトリに置かない。自前管理の `review-loop` だけ `dot_claude/skills/review-loop/` にコミットし、chezmoi が `~/.claude/skills/review-loop/` へコピーする。`~/.claude/skills/` には apm の skill と Claude Code の `synced/` キャッシュも入るため `exact_` は付けない。

導入済み skill:

| skill                   | 取得元                    |
| ----------------------- | ------------------------- |
| find-docs               | `ansanloms/skills`（apm） |
| empirical-prompt-tuning | `mizchi/skills`（apm）    |
| nvim-remote             | `ansanloms/skills`（apm） |
| worktree                | `ansanloms/skills`（apm） |
| ja-tech-proofread       | `ansanloms/skills`（apm） |
| infra-architecture      | `ansanloms/skills`（apm） |
| retrospective-codify    | `mizchi/skills`（apm）    |
| adr                     | `ansanloms/skills`（apm） |
| yomiyasu                | `nanaism/yomiyasu`（apm） |

skill を追加・更新する場合のみ apm を使用する。cwd は問わない。

```sh
# skill の追加・更新（~/.apm/apm.yml を更新し、targets: claude により ~/.claude/skills/ へ配置）
apm install -g <org>/<repo>/<skill>#<commit>
```

更新も同じ install で commit を上げる。`apm update` は使わない。`apm update` は最新の一致 ref へ更新してしまい、commit hash 固定と噛み合わないため。最新 commit は `git ls-remote <repo> HEAD` 等で確認する。

`apm.yml` / `apm.lock.yaml` は commit hash でバージョンを固定している。追加・更新後は `chezmoi re-add ~/.apm/apm.yml ~/.apm/apm.lock.yaml` でリポジトリへ取り込み、`dot_apm/` の 2 ファイルをコミットする。skill の中身の変化は diff に現れないため、lock の resolved_commit を上げる PR の本文には上流の compare URL（`https://github.com/<org>/<repo>/compare/<旧 commit>...<新 commit>`）を載せ、中身を読んでから取り込む。

yomiyasu は `<org>/<repo>/<skill>` 形式ではなく、`git: nanaism/yomiyasu` + `skills: [yomiyasu]` 形式で `apm.yml` に登録している（`../skills` の `apm.yml` と同じ形）。上記の `apm install -g <org>/<repo>/<skill>#<commit>` では更新しない。全依存をまとめて上げるときは、`~/.apm/apm.lock.yaml` と `~/.claude/skills/` の apm 管理分（`review-loop` と `synced/` 以外）を削除して引数無しの `apm install -g` を実行し、`chezmoi re-add` で lock を取り込む。

### 復元と lifecycle

依存を持つ skill（`scripts/package.json` の `dependencies` が空でないもの。現状は `ja-tech-proofread`）は `scripts/node_modules` を要する。`apm.yml` の `lifecycle.post-install` が、`apm install -g` のたびに該当 skill の `scripts/` で `npm ci --omit=dev` を実行する。global では cwd が `~/.apm` になるため、コマンドは `$HOME/.claude/skills/*/scripts` を見る。ブロックは ansanloms/skills の README「依存を持つ skill」節の雛形を、global 向けにパスを直したもの。

lifecycle は `apm lifecycle trust` で信頼したときだけ実行される。trust は `~/.apm` で実行し、マシンごとに `~/.apm/scripts-trust.json` へ「`apm.yml` の絶対パス → lifecycle ブロックのハッシュ」で記録され、リポジトリでは運べない。次の場合は trust し直す。

- 新しいマシン
- `lifecycle` ブロックを編集したとき（ハッシュが変わり信頼が外れる）

未信頼の `apm install -g` は `Skipped N untrusted project script(s)` と出して lifecycle を飛ばす。lifecycle の失敗は `apm install -g` の出力にも終了コードにも現れないため、install 後は `ls ~/.claude/skills/ja-tech-proofread/scripts/node_modules` で生成を確認する。

clone 直後の手順:

```sh
chezmoi apply
(cd ~/.apm && apm lifecycle trust)
apm install -g
deno task build
deno task install
```

`dot_apm/apm.lock.yaml` が変わるコミットを pull したときは `chezmoi apply` の後に `apm install -g` を実行する。skill の実体はリポジトリに無いため、pull だけでは更新されない。

## Local scripts

`.local/bin/` 配下のコマンド（`git-worktree-select` / `git-worktree-include` 等）は、`scripts/` 以下の TypeScript を `deno bundle` で単一ファイルにビルドした生成物。`scripts/` は Deno workspace で、モジュールごとのディレクトリ（member。現状は `git-worktree` のみ）に分かれている。共有依存はルートの `deno.json` の `imports` で、モジュール固有の依存（npm パッケージ等）は各 member（`scripts/<module>/deno.json`）の `imports` で管理する。

- ソース: `scripts/<module>/*.ts`（shebang に実行時の権限フラグを記述。`deno bundle` が生成物の先頭へ引き継ぐ）
- ビルド: `deno task build` で `scripts/<module>/*.ts` を `.local/bin/<name>` に bundle し、実行ビットを付与する
- 生成物は `.gitignore` 済みでコミットしない。`deno task install` でシンボリックリンクするため、**install の前に build しておく**こと

ソースを編集したら `deno task build` で再生成する。

導入済みコマンド:

- `git-worktree-select` / `git-worktree-include` - worktree の選択・ローカル設定持ち込み。選択 UI は fzf（`packages.nix` で導入）で、リストに branch description の先頭 1 行（subject）を表示し、プレビューで全文を mdcat により markdown レンダリングする（mdcat が無い環境では素のテキスト表示にフォールバック）。選択したパスは stdout へ出力する
- `git-worktree-sweep` - マージ済み worktree の掃除。メイン以外の全 linked worktree (配置場所は問わない) を対象に、マージ判定を git のみで行い (squash merge は merge-base への仮 squash commit + `git cherry` の patch-id 判定で検知)、forge の API に依存しない。マージ済みかつクリーンなものだけを worktree remove + ローカルブランチ削除し、dirty・未マージ・固有コミット無し (作成直後) は報告のみ。判定不能 (git コマンドの失敗) も worktree には触れずエラーとして報告し非 0 で終了する。git が prunable と判定した worktree (管理情報の破損・実体ディレクトリの消失等) は分類せず Skipped として報告し、(非 dry-run では) 末尾の `git worktree prune` が整理する。`--dry-run` で判定結果だけ確認できる

`scripts/` のソースは「薄いエントリポイント（`scripts/<module>/*.ts`）＋ 純粋ロジック / 依存注入した `run()`（`scripts/<module>/lib/*.ts`）」に分離している。副作用（subprocess / fs / tty / 対話プロンプト等）を注入することでテスト可能にし、`scripts/<module>/lib/*.test.ts` でユニットテストする（`deno task test` / `deno task coverage`）。`deno task build` は各 member 直下のみを bundle 対象とし、`lib/` サブディレクトリは対象から外れる。

## Claude Code の通知（組み込み通知）

- `dot_claude/settings.json` の `preferredNotifChannel` を `"ghostty"` にし、Claude Code 自身の通知（OSC 777）を端末へ出す。通知用の hook は使わない。
- 既定の `"auto"` は、端末を iTerm2・Ghostty・Kitty と検出したときだけデスクトップ通知を出す。zellij 越しの noctty で検出されるかに依存しないよう、チャネルを明示している。
- トーストを表示するのは端末側。noctty（Ghostty の Windows フォーク）は `desktop-notifications`（既定 true）で OSC 777 をトースト表示する。zellij は 0.45.0 以降、ペイン内の通知シーケンスをホスト端末へ転送する。alacritty は OSC 通知を実装していないため表示されない。
- 通知が出る場面は Claude Code が決める。Claude Code 2.1.286 の実装では、バックグラウンドジョブが入力待ち・完了になったとき（`claude agents` の画面側が出す）と、対話セッションで応答後のアイドルが続いたとき（`messageIdleNotifThresholdMs`、既定 60 秒）に出る。ターン完了の直後に出す経路は、同じ版の実装からは確認できていない。
- 元は hook（`.claude/scripts/notify.ts`）が ntfy への送信と、hook の JSON 出力の `terminalSequence` による OSC 777 の返却を行っていた。バックグラウンドジョブの Stop で通知が欠ける回があり、原因が Claude Code 内部の書き込み経路で hook 側から直せないため、組み込み通知へ寄せて `.claude/scripts` ごと削除した。さらに前は unix socket 経由で WSL 常駐サーバ（`scripts/notify` + `notify.service`）から Windows の Toast Notification API を叩いていた。

## 自前 nix パッケージの更新

`dot_config/nix/` には nixpkgs 未収録のパッケージを自前 derivation で管理している。

- `claude-statusline.nix`（[claude-statusline](https://github.com/ansanloms/claude-statusline)、Claude Code の statusLine レンダラ。nixpkgs 収録対象外の自前ツール。GitHub Release（タグは `0.1.0` 形式で v 無し、nix の version と同じ値）に添付した OS 別の Bun standalone バイナリ（`claude-statusline-<target>`）を system ごとに fetchurl で取得し、raw のまま導入する（md2html / sonarqube-cli と同じ。patchelf / strip で末尾 trailer が壊れるため fixup 無し）。実行に deno / bun は不要。`dot_claude/settings.json` の `statusLine` から `claude-statusline main` で呼ばれる）
- `md2html.nix`（[md2html](https://github.com/ansanloms/md2html)、markdown をシンタックスハイライト（shiki）・mermaid・目次内蔵の自己完結 HTML へ変換する CLI。nvim の quickrun からのプレビューが主用途。nixpkgs 収録対象外の自前ツール。元は `scripts/md2html` の workspace member だったが独立リポジトリへ移管した。GitHub Release（タグは `0.1.0` 形式で v プレフィックス無し）に添付した OS 別の Bun standalone バイナリ（`md2html-bun-<target>`）を fetchurl で取得し、raw のまま導入する（sonarqube-cli と同じ。patchelf / strip で末尾 trailer が壊れるため fixup 無し）。実行に deno は不要。mermaid は初回利用時に jsdelivr から取得して `$XDG_CACHE_HOME/md2html/` にキャッシュする）
- `sonarqube-cli.nix`（SonarQube CLI、コマンド名 `sonar`。SonarSource 配布のプリビルド ELF を fetchurl で取得し raw のまま導入する。配布物は Bun standalone 実行ファイルで、末尾 trailer に埋め込みアプリを持つ。patchelf / strip で ELF を書き換えると trailer が壊れ素の Bun CLI にフォールバックするため fixup を一切かけない。代わりにシステムの glibc / ローダに依存する＝FHS 環境専用。nixpkgs 収録の `sonar-scanner-cli` は別物の旧スキャナ）
- `moddable-sdk.nix`（Moddable SDK の CLI ツール `mcconfig` / `mcrun` / `mcpack` 等。Linux 専用。GTK ベースの GUI（xsbug / mcsim）はビルドしない。fetchFromGitHub で public ブランチの特定コミットを取得し、sub-makefile（xsc/xsid/xsl/serial2xsbug/tools）だけをビルドする。CLI ツールは単一マルチコールバイナリ `tools` への bash ラッパで、実行時に環境変数 `MODDABLE` が SDK ツリーを指す必要があるため、SDK ツリー一式を `$out/share/moddable` へ展開し各ツールを `MODDABLE` 付きで wrap する。SDK ツリーは read-only（store）のため、アプリビルド時は `mcconfig -o <書き込み可能なディレクトリ>` で出力先を明示する。nixpkgs 未収録。タグは 2022 年止まりなので tag ではなく public のコミットに pin する）
- `backlog-bee-cli.nix`（Backlog（Nulab）の CLI `bee`。npm でのみ配布（`@nulab/bee`）されるため buildNpmPackage で導入する。nixpkgs の `bee` は別物（ethersphere/bee = Ethereum Swarm ノード）なので attribute 名を分けている。コマンド名は `bee`）

`buildNpmPackage` で自前の `installPhase` を書く derivation（`backlog-bee-cli`）は、`node_modules` を `$out/lib/<pname>/node_modules` へ置く。`$out/lib/node_modules` へ平坦に展開すると、npm が `node_modules` 直下に書く `.package-lock.json` が derivation 間で同一の相対パスになり、`packages.nix` の `buildEnv` が file collision で落ちる（実際に発生した）。依存パッケージ名が被った場合も同じ理由で衝突する。nixpkgs 標準の `npmInstallHook` はパッケージ本体を `$out/lib/node_modules/<name>/` へ置き、依存をその配下へ入れ子にするため衝突しない（nixpkgs が `buildNpmPackage` で提供する npm パッケージはこちら）。この規約は hook を使わず `installPhase` を自前で書く場合にのみ当てはまる。

この衝突は個々の derivation を単体で `nix build` しても検出できない。`buildEnv` が複数パッケージを同一 prefix へ束ねたときにだけ現れる。そのため npm 系の derivation を追加・変更したら、`nix profile upgrade --all --impure`（または当該パッケージを含む `buildEnv`）まで通してから反映すること。

### バージョンを上げる

`dot_config/nix/<name>/upgrade.sh [version]`（version 省略で最新）で、version・ハッシュ（backlog-bee-cli は lockfile も）を更新する。全パッケージをまとめて上げる場合は `for s in dot_config/nix/*/upgrade.sh; do "$s"; done`。具体的な処理は各スクリプトを参照:

- `dot_config/nix/claude-statusline/upgrade.sh`（最新は GitHub releases の latest tag、hash は system（target）ごとに nix store prefetch-file。タグは v 無しで nix の version と同じ値。引数でバージョン指定も可）
- `dot_config/nix/md2html/upgrade.sh`（最新は GitHub releases の latest tag、hash は Release の SHA256SUMS から system 別に更新。タグは v プレフィックス無し。引数でバージョン指定も可）
- `dot_config/nix/sonarqube-cli/upgrade.sh`（最新は GitHub releases の latest tag、hash は nix store prefetch-file。配布リリース番号は `1.1.0.3122` 形式）
- `dot_config/nix/moddable-sdk/upgrade.sh`（最新は `git ls-remote ... public` の HEAD、hash と取得ツリーの storePath は `nix flake prefetch`、version は storePath の `tools/VERSION`。引数でコミット指定も可）
- `dot_config/nix/backlog-bee-cli/upgrade.sh`（最新は npm レジストリ、FOD は prefetch-npm-deps）

bump はファイルを書き換えるだけで反映はしない。完了後に `git diff` で確認してから `chezmoi apply` で `~/.config/nix` へ届け、`nix profile upgrade --all --impure` で反映する。これはプロファイルが `~/.config/nix#default` で登録されている前提。`~/.config/nix` は chezmoi のコピーで git 管理外の通常ディレクトリなので、nix から見ると path flake であり、tracked かどうかに関係なくディレクトリ全体が使われる。新規 `.nix` ファイル等を追加したときも `chezmoi apply` で届ければよい（`git add` は不要）。`flake.nix` の input を変えたときは、リポジトリ側で `nix flake lock --flake path:dot_config/nix`（または `nix flake update`）を実行して `flake.lock` を更新してから `chezmoi apply` する。先に `nix profile upgrade` すると nix が `~/.config/nix` 側に lock を書き、source と食い違う。

既存 profile の付け替え（dot-mori 時代の登録は `git+file://<clone>?dir=.config/nix`、名前 `.config/nix`）は、このブランチのマージ後に次の順で行う。

```sh
# 旧 symlink が残っていれば消す
rm -f ~/.config/nix
# ~/.config/nix がコピーで出来る
chezmoi apply
# この時点で ~/.nix-profile/bin の chezmoi・git は消える（nix 本体は installer が入れた system profile にあり、続行できる）
nix profile remove .config/nix
nix profile add ~/.config/nix#default --impure
```

### bump で拾えない変更

bump が更新するのは version 文字列と FOD ハッシュという、機械的に再計算できる値だけ。新版が次を変えた場合は bump 後の `nix profile upgrade` がビルドエラーになるので、エラーを読んで derivation を手当てする。以下の `nix profile upgrade` はいずれも先に `chezmoi apply` で届けてから実行する:

- **claude-statusline**: 資産名や shebang の権限フラグ構成が変わると `claude-statusline.nix` が合わなくなる。bump 後は `echo '{"hook_event_name":"Status","...":"..."}' | claude-statusline main` のようなスモークで動作確認する。
- **md2html**: 資産名（`md2html-bun-<target>`）や SHA256SUMS の形式が変わると `md2html.nix` が合わなくなる。bump 後は適当な markdown を変換して出力が `<!doctype html>` で始まることをスモーク確認する（例: `printf '# t\n' > /tmp/t.md && md2html /tmp/t.md | head -c 20`）。
- **sonarqube-cli**: bump 後は `sonar -h` で本物の SonarQube CLI help が出ることを必ず確認する。Bun の help（`bun <command>` の usage）や `--version` が Bun のバージョンを返す場合、配布物の埋め込み構造が変わって raw 導入では動かなくなったサイン。`dontFixup` のままラップ方式（buildFHSEnv 等）への切り替えを検討する。
- **moddable-sdk**: 新版で release ターゲットの sub-makefile 構成（`xsc.mk` / `tools.mk` 等のパスや並び）や CLI ツールの一覧が変わると、`buildPhase` の make 呼び出しや `cliTools` のラップ対象がずれる。bump 後は `nix build` が通ること、`mcconfig` が実行できることを確認する。アプリビルドの C コンパイル段（`x-cli-lin` は `gio-2.0` 依存）が動くかは wrapper の `runtimeInputs` / `PKG_CONFIG_PATH` に依存するため、依存が増えた場合はそこを手当てする。
- **backlog-bee-cli**: 新版で `bin` のパスや名前が変わると `installPhase` の `--add-flags` のパスが合わなくなる。bump 後は `bee --version` で動作確認する。

このため bump 後は必ず `nix profile upgrade --all --impure` までやってビルドが通ることを確認すること。

### nixpkgs 収録されたら

自前 derivation を削除したら、`~/.config/nix` に残る旧ファイルは chezmoi が消さない（`exact_` を付けていない）ので手で消す。

`sonarqube-cli`（コマンド `sonar`）が nixpkgs に収録されたら、`sonarqube-cli.nix` と flake.nix の overlay を削除して `packages.nix` の 1 行に乗り換える。

`moddable-sdk` も nixpkgs に収録されたら（`nix search nixpkgs moddable` で確認）、`moddable-sdk.nix` と flake.nix の overlay を削除して `packages.nix` の 1 行に乗り換える。

`@nulab/bee`（Backlog CLI）が nixpkgs に収録されたら、`backlog-bee-cli.nix` と flake.nix の overlay を削除して `packages.nix` の 1 行に乗り換える。ただし nixpkgs の `bee` は別物（ethersphere/bee）のため、収録される場合の attribute 名はこの自前 derivation と同じ `backlog-bee-cli` にはならず、別名になる前提で `nix search nixpkgs bee` 等で該当パッケージを探すこと。

### nixpkgs パッケージの一時的な上書き

nixpkgs 収録パッケージが壊れているときは、自前 derivation を書かず `flake.nix` の overlay で該当箇所だけ差し替える。恒久化しないよう、適用条件と削除条件を overlay のコメントとここに書く。
