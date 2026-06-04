# nvim 連携

zellij セッション内で起動している nvim は `/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock` で listen している (`.config/zellij/layouts/default.kdl` 参照)。この socket 経由で nvim を遠隔操作し、作業結果を隣ペインの nvim に流し込む。

このファイルは「いつ nvim で開くべきか」の判断を定める。具体的な操作手順は `nvim-remote` skill を参照する。

## 前提条件

- MUST: 以下を **すべて** 満たす場合のみ本ルールを適用する。満たさない場合は通常のコンソール出力にフォールバックし、エラーで作業を止めない。
  - 環境変数 `ZELLIJ_SESSION_NAME` が定義されている。
  - `/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock` が存在する (`[ -S ... ]` で確認)。

## いつ nvim で開くか

前提条件を満たす場合、以下の場面ではコンソールに出力せず nvim で開く。

- MUST: ユーザにファイルを参照させる場面。コンソールに内容を貼り付けない。
- MUST: 2 ファイル間の diff、または `git diff` 等の差分文字列を見せる場面。
- MUST: コマンド実行結果や調査結果等、長文の出力をユーザに見せる場面。
- MUST: plan mode で plan を書き終え `ExitPlanMode` を呼んだ直後。

## 実行手順

- MUST: 上記の場面で nvim を操作する具体手順 (socket パスの組み立て、`--remote-tab` / `--remote-send` の送り方、一時ファイルの扱い、注意事項) は `nvim-remote` skill に従う。
