# Worktree

メインの worktree (clone 直下) のブランチを切り替えずに、タスクを別ブランチの worktree へ隔離するためのルール。ファイルを変更する作業だけでなく、別ブランチを対象にする読み取り専用の調査にも適用する。

この節は「いつ worktree へ隔離するか」の判断と、worktree の配置先 (`<base>`) の供給を定める。これらは呼び出し側 (このルール) の責務とする。worktree の作成・ローカル設定の持ち込み・branch description 設定といった具体手順は `worktree` skill に委譲する。

## 原則

- MUST: メインの worktree (clone 直下) が今いるブランチを切り替えない。別のブランチで作業する必要があるなら、そのブランチを worktree でチェックアウトして行う。これはファイル変更か読み取りかを問わない。
- worktree が必要なのは「メインの worktree の現在のブランチとは別のブランチを使う」とき。具体的には:
  - ファイルを変更する作業 (専用ブランチを新規に切る)。メインの worktree で直接編集・コミットしない。
  - 読み取りのみでも、別ブランチを対象にする調査。例: 調査用にブランチを新規に切る場合、または既に main から切られた既存ブランチの状態を調べる場合。メインのブランチを切り替えず、その別ブランチを worktree でチェックアウトして調べる。
- worktree が不要なのは、メインの worktree が現在いるブランチに対する読み取りのみの調査・質問への回答・情報収集 (ブランチを変えないため)。
- 既に当該タスク専用の worktree 上にいる場合は新規に切らない。その worktree で続行する。
- 本ルールが縛るのは worktree のセットアップ (用意 + description 設定) まで。その後のコミット・push・PR は本ルールの対象外で、通常の Git 運用 (AGENTS.md のコミット規約等) に従う。

## worktree 配置先 (base) の供給

`worktree` skill は worktree を置くベースディレクトリ (`<base>`) を呼び出し側から受け取る前提で動く。配置先の決定と、それが `git status` を汚さない保証は呼び出し側 (このルール) の責務とする。skill 自身は配置先を決めたり検証したりしない。

- `<base>` はリポジトリ内の `.claude/worktrees/` とする。`<main>` をメインの worktree (clone 直下) の絶対パスとして `<base>` = `<main>/.claude/worktrees`。各 worktree は `<base>/<name>` に作られる。例: メインが `~/dev/foo` なら worktree は `~/dev/foo/.claude/worktrees/<name>`。
- `.claude/worktrees/` はグローバル gitignore (`~/.config/git/ignore` の `**/.claude/worktrees/*`) で除外済みのため、リポジトリ内に置いてもメインの `git status` を汚さない。
- MUST: `<base>` は絶対パスで skill に渡す。どの cwd から実行しても所定のディレクトリへ確実に置くため。

## 実行手順

- MUST: 上記「原則」で worktree への隔離が必要と判断した場合、worktree の用意 (作成 + ローカル設定の持ち込み + branch description 設定) は `worktree` skill に委譲する。「worktree 配置先 (base) の供給」で定めた `<base>` = `<main>/.claude/worktrees` を絶対パスで渡す。
- 渡した `<base>` を使った worktree 操作の具体手順 (`git worktree add` の送り方、`git-worktree-include` によるローカル設定持ち込みとその cwd 制約、branch description の書式・確認方法、対話セレクタを使わないこと) は `worktree` skill に従う。skill は配置先の決定・検証・`git status` 非汚染の保証には関与しない。
- MUST: branch description は worktree の不変条件として常に 1 行で持つ。新規に用意したときは着手前に設定し、既存の worktree で作業を続けるときは未設定ならその場で設定してから着手する。書式・理由・確認方法は skill に従う。
