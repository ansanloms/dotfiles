# Worktree

メイン worktree (clone 直下) のブランチを切り替えずに、タスクを別ブランチの worktree へ隔離するためのルール。ファイルを変更する作業だけでなく、別ブランチを対象にする読み取り専用の調査にも適用する。

worktree 操作は git alias `git wt` (`.config/git/config` 定義、`git-worktree-select` / `git-worktree-include` に依存) を使う。

## 原則

- MUST: メイン worktree (clone 直下) が今いるブランチを切り替えない。別のブランチで作業する必要があるなら、そのブランチを worktree でチェックアウトして行う。これはファイル変更か読み取りかを問わない。
- worktree が必要なのは「メイン worktree の現在のブランチとは別のブランチを使う」とき。具体的には:
  - ファイルを変更する作業 (専用ブランチを新規に切る)。メイン worktree で直接編集・コミットしない。
  - 読み取りのみでも、別ブランチを対象にする調査。例: 調査用にブランチを新規に切る場合、または既に main から切られた既存ブランチの状態を調べる場合。メインのブランチを切り替えず、その別ブランチを worktree でチェックアウトして調べる。
- worktree が不要なのは、メイン worktree が現在いるブランチに対する読み取りのみの調査・質問への回答・情報収集 (ブランチを変えないため)。
- 既に当該タスク専用の worktree 上にいる場合は新規に切らない。その worktree で続行する。
- 本ルールが縛るのは worktree のセットアップ (用意 + description 設定) まで。その後のコミット・push・PR は本ルールの対象外で、通常の Git 運用 (AGENTS.md のコミット規約等) に従う。

## 作成手順

1. worktree を用意する。`<main>` はメイン worktree の絶対パス。
   - 新しいブランチを切る場合: `git wt add <main>/.claude/worktrees/<name> -b <branch>`。
   - 既存ブランチ (例: 既に main から切られたブランチ) を調べる/続ける場合: `git wt add <main>/.claude/worktrees/<name> <branch>` (`-b` を付けない。既存ブランチをそのままチェックアウトする)。
   - path 規約: リポジトリ内の `.claude/worktrees/<name>` に置く。例: メインが `~/dev/foo` なら worktree は `~/dev/foo/.claude/worktrees/<name>`。`.claude/worktrees/` はグローバル gitignore (`~/.config/git/ignore` の `**/.claude/worktrees/*`) で除外済みのため、リポジトリ内に置いてもメインの `git status` を汚さない。
   - `git wt add` の path 引数は絶対パスで渡す。どの cwd から実行しても所定のディレクトリへ確実に置くため。
   - `git wt add` は `git worktree add` の後に `.worktreeinclude` 記載のファイルをメインから複製する (ローカル設定の持ち込み)。`.worktreeinclude` が無ければ複製は何もしない (エラーではない)。
   - `<name>` / `<branch>` はタスク内容がわかる短い名前にする。
2. その branch に description を設定する (下記「branch description」)。

## branch description

- MUST: 作業対象の worktree は、常に 1 行の branch description を持つこと。これは作成時の一手順ではなく、worktree の steady state に対する不変条件として扱う。調査 (read) 用でも変更 (write) 用でも区別しない。
  - worktree を新規に用意したとき (新ブランチ・既存ブランチを問わず): 着手前に設定する。既存ブランチに既に description があればそのまま使ってよい。
  - 既存の worktree で作業を続けるとき: description が未設定なら、その場で設定してから着手する (誰が作ったかに関係なく適用する)。
- 設定方法: `git config branch.<branch>.description "<作業概要>"`。
- 内容は「その worktree で何をするか」が分かる作業概要を **1 行** で書く。文体はコミットメッセージの subject に準じる (日本語。AGENTS.md のコミット規約参照)。
- 理由: `git wt ls` (= `git-worktree-select`) は worktree 一覧に description を表示するが、`branch.<branch>.description` の **先頭 1 行のみ** を読む (`.split("\n")[0]`、2 行目以降は捨てる)。未設定だと一覧でタスクを識別できず、複数 worktree の区別がつかない。
- 注意: `git wt ls` は人間向けの対話セレクタ (`git-worktree-select`)。エージェントがプログラム的に実行すると入力待ちでハングするため使わない。description や worktree の確認は `git config --get branch.<branch>.description` と `git worktree list` を非対話で使う。
