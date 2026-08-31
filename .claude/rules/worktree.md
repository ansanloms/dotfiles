# Worktree

メインの worktree (clone 直下) のブランチを切り替えずに、タスクを別ブランチの worktree へ隔離するためのルール。ファイルを変更する作業だけでなく、別ブランチを対象にする読み取り専用の調査にも適用する。

この節は「いつ worktree へ隔離するか」の判断、worktree の配置先 (`<base>`) の供給、片付けツールの供給を定める。これらは呼び出し側 (このルール) の責務とする。worktree の作成・ローカル設定の持ち込み・branch description の設定と更新・マージ後の片付けといった具体手順は `worktree` skill に委譲する。

## 原則

- MUST: メインの worktree (clone 直下) が今いるブランチを切り替えない。別のブランチが要る作業 (ファイル変更のために専用ブランチを新規に切る場合、既に main から切られた別ブランチを読み取り専用で調べる場合) は、そのブランチを worktree でチェックアウトして行う。
- メインの worktree が現在いるブランチに対する読み取りのみの調査・質問への回答・情報収集には worktree は不要。
- 既に当該タスク専用の worktree 上にいる場合は新規に切らず、その worktree で続行する。

## ハーネスの bg 隔離との関係

Claude Code のバックグラウンドジョブは、既定 (`worktree.bgIsolation: "worktree"`) ではメイン checkout への Edit / Write が「Call EnterWorktree first」で拒否され、セッション自身が `EnterWorktree` で隔離してから編集する。隔離したセッション (`claude --worktree` や `isolation: worktree` の subagent も同じ) では、メイン checkout 宛ての Edit / Write、cwd がメイン checkout に解決する Bash、git をメイン checkout へ向けるリダイレクト (`git -C` / `GIT_DIR` / 事前の `cd`)、worktree 内に留まると静的検証できない形の Bash (パイプ・`;`・heredoc・`$(...)`・サブシェル・`eval`。git を含まないコマンドも対象) が `This session is isolated in the worktree <path>` で拒否される。この隔離後のガードは設定では切れない。

- MUST: `bgIsolation` はグローバル `.claude/settings.json` で `"none"` にし、バックグラウンドジョブでも `EnterWorktree` を使わず本ルールの手順で隔離する。理由: 隔離の責務は本ルールが持ち、配置先も同じ `<base>` のため、`EnterWorktree` を挟むと二重隔離になる。しかも隔離後は `worktree` skill の `git-worktree-include` (cwd = メイン worktree 必須) が cwd ガードに、description 設定 (`git config ... "$(cat ...)"`) が形状ガードに当たり、skill の手順自体が実行できない。`"none"` が外すのは「Call EnterWorktree first」の拒否だけだが、それで `EnterWorktree` を呼ぶ動機が消え、隔離後のガードに入らなくなる (2026-08-15〜29 の tool エラー 792 件中 490 件が隔離後ガードによるもので、全件が `.claude/worktrees/` 配下を cwd にした bg ジョブで発生)。
- 代償: バックグラウンドジョブが工程 1 (隔離) を飛ばすと、誰も見ていない状態でメイン checkout へ直接書く。設定はグローバルで全リポジトリに及ぶ。防波堤は「原則」の MUST だけになる。
- 隔離後のガードはセッションの属性であり、そのセッションが起動する subagent (implementer / code-review-runner 等) にも及ぶ。subagent に別 worktree の絶対パスを渡しても、入っている worktree 以外への git 操作は拒否される。そのため複数 worktree の並列作業が成立せず、`EnterWorktree` の `path` で切り替える直列作業になる (#72 の事例。片方の worktree で reviewer が動いている間、もう片方に触れなかった)。
- MUST: セッション開始時または作業中に、自分が `EnterWorktree` の隔離下にある (cwd が `.claude/worktrees/` 配下で、上記 `This session is isolated` の拒否が出る) と分かったら、作業を続ける前に `ExitWorktree` で抜けてメイン checkout に戻る。抜け方はその worktree の状態で分ける。
  - 未着手 (変更もコミットも無い): `action: "remove"` で抜け、本ルールの手順で worktree を切り直す。
  - 作業済み (変更またはコミットがある): `action: "keep"` で抜け、その worktree を本ルールの worktree として引き取る。配置先は `<base>` と同じ `.claude/worktrees/<name>` なので切り直さず、メイン checkout の cwd から skill の include・description 設定を施して続行する。
  - 抜けた後は、複数の worktree に `git -C <path>` と subagent の並列起動で同時に触れられる (#72 で実測)。
- `claude --worktree` で隔離したセッションも `ExitWorktree` (`action: "keep"`) で抜けられ、cwd がメイン checkout、HEAD が main に戻る (2026-08-31 に `claude --worktree exit-probe -p` で実測。`--worktree <name>` が作る worktree は `.claude/worktrees/<name>`、ブランチ名は `worktree-<name>`)。扱いは `EnterWorktree` と同じで、上の MUST に従う。

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
