# nvim 連携

zellij セッション内で起動している nvim は `/tmp/nvim-<セッション名>.sock` で listen している (`.config/zellij/layouts/default.kdl` 参照)。この socket 経由で nvim を遠隔操作し、作業結果を隣ペインの nvim に流し込む。適用主体はメインループのみ (ユーザへの提示はメインループの責務。dev-workflow ルール)。subagent には適用しない。

この節は「いつ nvim で開くべきか」の判断と、socket の解決 (導出 + 発見 + 絞り込み) と生存確認を定める。これらは呼び出し側 (このルール) の責務とする。

## 前提条件

- MUST: **生きている nvim socket が 1 つ以上見つかる** 場合に本ルールを適用する。見つからない場合のみ通常のコンソール出力にフォールバックし、エラーで作業を止めない。
- MUST: socket の有無は下記「socket の解決手順」を実行した結果で判定する。
- MUST: バックグラウンドジョブでは `ZELLIJ_SESSION_NAME` を信用しない。ジョブの shell は常駐の claude daemon 配下で動き、env は daemon が起動した時点のセッション名で固定される。

## socket の解決手順

候補は必ず `[ -S "$sock" ]` (socket として存在) と `nvim --server "$sock" --remote-expr 'has("nvim")'` (live な nvim が応答する) の **両方** で確認する。後者は exit 0 かつ標準出力が `1` のときのみ live とみなす。エラー・非 0・出力欠落はすべて live でない扱いにする。`[ -S ]` だけだと crash 後に残った stale な socket ファイルを掴む。解決手順中の `nvim --server` / `zellij action` 呼び出しにはすべて `timeout 5` を付け、判定コマンドはリトライしない (1 回の結果で確定する)。失敗の扱いはコマンド系統で逆になる: `nvim --server` 呼び出し (生存確認・cwd 取得) の失敗はその候補を落とし (応答しない nvim は送信先に使えない)、`zellij action` (attach 判定) の失敗は判定不能として候補に残す。

1. 環境判定: `CLAUDE_JOB_DIR` が設定されている (バックグラウンドジョブ) 場合は手順 2 をスキップして手順 3 へ進む。
2. 導出 (フォアグラウンドのみ): `sock="/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock"`。これが冒頭の 2 条件で live ならそれを使う。
3. 発見: `ls /tmp/nvim-*.sock` で実体を探し、冒頭の 2 条件 (`[ -S ]` + `has("nvim")`) をこの段で各実体に適用し、live なものを候補にする (手順 2 で live でなかった socket は再判定せず、live でないものとして扱う)。
4. 候補数で分岐する。
   - 0 個 (live なし): 前提条件を満たさない。コンソール出力へフォールバックする。
   - 1 個: それを使う。
   - 2 個以上: 次の順で絞り込む。
     1. attach 判定: socket 名からセッション名を取り (`/tmp/nvim-<セッション名>.sock`)、`env -u ZELLIJ ZELLIJ_SESSION_NAME=<セッション名> timeout 5 zellij action list-clients` を実行する。出力にヘッダ行しか無い (client が 1 つも attach されていない = ユーザから見えていない) セッションは候補から外す。コマンドが失敗した候補は判定不能として残す。この絞り込みで 0 個になったら、ユーザはどの nvim も見ていないためコンソール出力へフォールバックする。1 個になったらそれを使う。
     2. cwd 絞り込み: まだ複数なら、各 socket の cwd を `nvim --server "$sock" --remote-expr 'getcwd()'` で引き、照合基準に対応する socket だけを残す。照合基準は現在作業中のプロジェクトのメイン worktree (clone 直下) のルートのみとし、`git worktree list --porcelain` の先頭 `worktree` 行で取得する (隔離 worktree 内で作業中も同じ)。「対応する」とは、socket の cwd が照合基準と同一、または一方が他方の配下にあることを指す。配下の判定はパス区切り境界で行う (`<parent>/` で始まるかで比較する。例: `/home/u/proj-backup` は `/home/u/proj` の配下ではない)。1 個に絞れたらそれを使う。
     3. ユーザ確認: 対応が一意に定まらない (どの socket も一致しない、複数が一致する、のいずれも含む) 場合は、起動時刻や socket 名等の弱い基準でエージェントが勝手に選ばず、どのセッションを使うかユーザに確認する (同一プロジェクトを複数セッションで開いている状態は想定内で、確認になるのが期待挙動)。禁止対象はエージェント自身による自動選択であり、候補の識別のため socket 名・cwd・attach 判定で得た focused pane のコマンド (`RUNNING_COMMAND` 列。client 行が複数あるセッションは全行) を提示するのは構わない。提示には手順 4-1 で得た出力をそのまま再利用し、再実行しない。

## いつ nvim で開くか

前提条件を満たす場合、以下の場面ではコンソールに出力せず nvim で開く。

- MUST: ユーザにファイルを参照させる場面。コンソールに内容を貼り付けない。
- MUST: 2 ファイル間の diff、または `git diff` 等の差分文字列を見せる場面。
- MUST: コマンド実行結果や調査結果等、長文の出力をユーザに見せる場面。
- MUST: plan mode で plan を書き終え `ExitPlanMode` を呼んだ直後。

## 実行手順

- MUST: socket の解決 (環境判定 → 導出 → 発見 → 生存確認 → 複数時の絞り込み) は呼び出し側であるこのルールが行う。「socket の解決手順」で得た live な絶対パスを `nvim-remote` skill に渡して操作させる。
- MUST: 渡した socket パスでの nvim 操作の具体手順は `nvim-remote` skill に従う。skill は socket の解決・生存確認・フォールバック判断には関与しない。
