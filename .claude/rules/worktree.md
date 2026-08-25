# Worktree

メインの worktree (clone 直下) のブランチを切り替えずに、タスクを別ブランチの worktree へ隔離するためのルール。ファイルを変更する作業だけでなく、別ブランチを対象にする読み取り専用の調査にも適用する。

この節は「いつ worktree へ隔離するか」の判断、worktree の配置先 (`<base>`) の供給、片付けツールの供給を定める。これらは呼び出し側 (このルール) の責務とする。worktree の作成・ローカル設定の持ち込み・branch description の設定と更新・マージ後の片付けといった具体手順は `worktree` skill に委譲する。

## 原則

- MUST: メインの worktree (clone 直下) が今いるブランチを切り替えない。別のブランチが要る作業 (ファイル変更のために専用ブランチを新規に切る場合、既に main から切られた別ブランチを読み取り専用で調べる場合) は、そのブランチを worktree でチェックアウトして行う。
- メインの worktree が現在いるブランチに対する読み取りのみの調査・質問への回答・情報収集には worktree は不要。
- 既に当該タスク専用の worktree 上にいる場合は新規に切らず、その worktree で続行する。

## 片付け

- MUST: マージ済み worktree の削除は `git-worktree-sweep` (`.local/bin`、`--dry-run` あり。skill が言う「呼び出し側から供給される専用ツール」がこれ) に任せる。PR / ブランチのマージ報告を受けたとき、または残骸に気づいたときに、メイン worktree の cwd で実行する (`--dry-run` は任意)。skill の汎用手順 (個別の `git worktree remove` / `git branch -d`) を手組みしない。sweep は squash merge も検知し、dirty・未マージ・detached の worktree には触れず報告のみ行う。
- MUST: merge 操作のローカル後処理を merge コマンドに任せない (理由と失敗例は skill の「片付け」節)。GitHub なら `--delete-branch` を付けずに merge し、ブランチ削除は sweep に任せる。
- `EnterWorktree` で入った worktree を `ExitWorktree` で除去する場合 (それ以外の除去は sweep に任せる)、squash merge 済みならローカルコミットは常に「未マージ」に見えるため検知による拒否が必ず作動する。確認済みなら最初から `discard_changes: true` で呼んでよい。

## worktree 配置先 (base) の供給

`worktree` skill は worktree を置くベースディレクトリ (`<base>`) を呼び出し側から受け取る前提で動く。配置先の決定と、それが `git status` を汚さない保証は呼び出し側 (このルール) の責務とし、skill は関与しない。

- `<base>` はリポジトリ内の `.claude/worktrees/` とする。`<main>` をメインの worktree (clone 直下) の絶対パスとして `<base>` = `<main>/.claude/worktrees`。各 worktree は `<base>/<name>` に作られる (`<name>` は skill が決める)。
- `.claude/worktrees/` はグローバル gitignore (`~/.config/git/ignore` の `**/.claude/worktrees/*`) で除外済みのため、リポジトリ内に置いてもメインの `git status` を汚さない。

## 実行手順

- MUST: 上記「原則」で worktree への隔離が必要と判断した場合、worktree の用意 (作成 + ローカル設定の持ち込み + branch description 設定) は `worktree` skill に委譲する。「worktree 配置先 (base) の供給」で定めた `<base>` = `<main>/.claude/worktrees` を絶対パスで渡す (どの cwd から実行しても所定のディレクトリへ確実に置くため)。
- 渡した `<base>` を使った worktree 操作の具体手順 (`git worktree add` の送り方、`git-worktree-include` によるローカル設定持ち込みとその cwd 制約、branch description の書式・確認方法、対話セレクタを使わないこと) は `worktree` skill に従う。
- MUST: branch description は worktree の不変条件として常に持つ。書式・確認方法は skill に従う。設定タイミングは、worktree を新規に用意したときは着手前。既存ブランチに description が既にあればそれを使い、無ければその場で設定してから着手する。
- MUST: 作業の節目 (todo 項目の完了・方針転換・中断・再開・PR 作成) が来たら、その場で branch description の status / todo を更新する。手順は skill の「更新」節に従う。
