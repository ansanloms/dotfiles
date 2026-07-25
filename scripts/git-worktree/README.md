# git-worktree

git worktree の選択・ローカル未追跡ファイルの持ち込み・マージ済み worktree の片付けを行う 3 つの CLI で構成するモジュール。マージ判定は forge（GitHub 等）の API に依存せず git のみで行う。

## コマンド

- `git-worktree-select` - `git worktree list --porcelain` の結果を fzf で対話選択し、選んだ worktree の絶対パスを stdout へ出力する（コマンド置換で受け取れる）。一覧には各 worktree のパス・SHA・ブランチ名・lock 状態に加え、branch description の先頭 1 行（subject）を表示する。preview ペインでは branch description の全文を `mdcat` で markdown レンダリングする（`mdcat` が無い環境では素のテキスト表示にフォールバック）。カーソルは cwd が属する worktree（最長一致で最も深いもの）に初期位置合わせする。`--exclude-main` でメイン worktree を候補から除く。
- `git-worktree-include` - `.worktreeinclude` に記載されたファイルをメインワークツリーから指定の worktree へコピーする。`git worktree add` と同じ引数を受け取り、そこからコピー先パスを取り出す。`.worktreeinclude` は gitignore 互換の構文（`ignore` ライブラリ準拠）で、マッチしたファイルがコピー対象になる。`.git` ディレクトリ・他 worktree の配下・`.worktreeinclude` 内の否定パターン（`!` 行）は走査から除外する。使い方: `git-worktree-include [<options>] <path> [<commit-ish>]`。メインワークツリーの解決に `git worktree list --porcelain` の実行結果（cwd 依存）を使うため、対象リポジトリ内（どの worktree でもよい）から実行する必要がある。
- `git-worktree-sweep` - メイン以外の全 linked worktree（配置場所は問わない）のうち、デフォルトブランチへマージ済みかつ working tree がクリーンなものを削除し、ローカルブランチも削除する。マージ判定は forge（GitHub 等）の API に依存せず git のみで行うが、実行時に `git fetch --prune origin` を行い `origin/HEAD` からデフォルトブランチを解決するため、`origin` リモートの設定とネットワーク到達性は前提とする: (1) 固有コミットが無ければデフォルトブランチ上の merge commit の第 2 親以降に tip が現れるかで判定、(2) 固有コミットがあればブランチを merge-base に対して仮 squash した commit を作り、その patch-id が `git cherry` でデフォルトブランチに含まれるかで squash merge を検知する。dirty・未マージ・detached HEAD・固有コミット無し（作成直後）の worktree は削除せず報告のみ行う。使い方: `git-worktree-sweep [--dry-run]`（`--dry-run` は削除せず判定結果のみ出力する）。

## 構成

各エントリは「薄いエントリポイント + 依存注入した `run()`」に分離している。副作用（git 実行 / fzf 起動 / fs 走査・読み書き / cwd・パス解決）はエントリ側で組み立てて注入し、`lib/*.ts` は副作用を持たない純粋ロジックとしてユニットテストする。

- `git-worktree-select.ts` - CLI 本体。`git worktree list --porcelain` の実行・`git config` によるブランチ description 取得・fzf の起動（引数組み立て・stdin 書き込み・結果取得）を組み立て、`lib/select.ts` の `run()` へ注入する。
- `git-worktree-include.ts` - CLI 本体。git 実行・ファイル存在確認・テキスト読み込み・パス解決・`expandGlob` によるディレクトリ走査・ディレクトリ作成・ファイルコピーを組み立て、`lib/include.ts` の `run()` へ注入する。
- `git-worktree-sweep.ts` - CLI 本体。git 実行（stdout/stderr 取得）とログ出力を組み立て、`lib/sweep.ts` の `run()` へ注入する。
- `lib/select.ts` - porcelain 出力のパース、cwd から初期選択位置を決める `pickDefaultIndex`、一覧表示ラベルの整形（列幅計算・色付け・branch description subject の markdown 簡易畳み込み）、fzf 向け行の組み立てなどの純粋ロジック。
- `lib/include.ts` - porcelain 出力のパース、`git worktree add` 引数からのコピー先解決、`.worktreeinclude` の除外パターン構築・ignore マッチャ構築などの純粋ロジック。
- `lib/sweep.ts` - porcelain 出力のパース、デフォルトブランチの解決、`isMergedAsParent` / `classifyBranch`（merge / squash merge / 固有コミット無しの判定）などの純粋ロジック。

モジュール固有の依存（`deno.json`）は次のとおり。

- `@std/fmt` - 一覧表示の色付け・ANSI 除去（`git-worktree-select`）。
- `@std/fs` - `.worktreeinclude` にマッチするファイルの走査（`expandGlob` / `ensureDir`、`git-worktree-include`）。
- `ignore` - `.worktreeinclude`（gitignore 互換構文）のマッチャ構築（`git-worktree-include`）。

## ビルドとテスト

リポジトリルートで `deno task build` を実行すると、各エントリ（`git-worktree-select.ts` / `git-worktree-include.ts` / `git-worktree-sweep.ts`）が `deno bundle` で単一ファイル化され、`.local/bin/<エントリファイル名（拡張子なし）>` として配置される（`lib/` はビルド対象から外れる）。

`deno task test` でリポジトリ全体のユニットテスト（`lib/*.test.ts`）を実行する。
