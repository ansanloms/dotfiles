# nvim 連携

zellij セッション内で起動している nvim は `/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock` で listen している (`.config/zellij/layouts/default.kdl` 参照)。この socket 経由で nvim を遠隔操作し、作業結果を隣ペインの nvim に流し込む。

## 前提条件

- MUST: 以下を **すべて** 満たす場合のみ本ルールを適用する。満たさない場合は通常のコンソール出力にフォールバックし、エラーで作業を止めない。
  - 環境変数 `ZELLIJ_SESSION_NAME` が定義されている。
  - `/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock` が存在する (`[ -S ... ]` で確認)。

## ファイルを nvim で開く

- MUST: ユーザにファイルを参照させる場面では、コンソールに内容を貼り付けるのではなく nvim で開く。

  ```sh
  nvim --server "/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock" --remote <filepath>
  ```

## diff を nvim で開く

- MUST: 2 ファイル間の diff を見せる場合は片方を `--remote` で開いた後、`diffsplit` を送る。`<Esc>` を前置して insert mode の影響を避ける。

  ```sh
  sock="/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock"
  nvim --server "$sock" --remote <file1>
  nvim --server "$sock" --remote-send '<Esc>:vert diffsplit <file2><CR>'
  ```

- MUST: `git diff` 等の差分文字列そのものを見せる場合は一時ファイルに書き出してから開く。拡張子 `.diff` で filetype が自動判定される。

  ```sh
  tmp=$(mktemp --suffix=.diff)
  git diff > "$tmp"
  nvim --server "/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock" --remote "$tmp"
  ```

## 出力結果を nvim で開く

- MUST: コマンド実行結果や調査結果等、長文の出力をユーザに見せる場合は一時ファイルに書き出して `--remote` で開く。
- MUST: 拡張子は内容に合わせる (`.md` / `.log` / `.json` / `.txt` 等)。filetype 判定が効く。
- MUST NOT: 一時ファイルを削除しない。nvim 側で開いている間に消えると参照できなくなる。

  ```sh
  tmp=$(mktemp --suffix=.md)
  <command> > "$tmp"
  nvim --server "/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock" --remote "$tmp"
  ```

## plan mode の plan を nvim で開く

- MUST: plan mode で plan ファイルを書き終え `ExitPlanMode` を呼んだ直後、plan ファイルのパスを `--remote` で開く。

  ```sh
  nvim --server "/tmp/nvim-${ZELLIJ_SESSION_NAME}.sock" --remote <plan-file-path>
  ```

- plan ファイルは plan mode により既に生成済みの為、新規作成は不要。パスをそのまま渡す。

## 注意事項

- `--remote-send` で送るキーシーケンスは nvim 記法 (`<Esc>` / `<CR>` 等) を使用する。
- nvim が insert mode 等にいる可能性を考慮し、Ex コマンド送信前には `<Esc>` を前置する。
- socket 接続失敗時はエラー扱いせず通常出力にフォールバックする。
