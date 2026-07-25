# notify

WSL 内のアプリ（Claude Code のフック等）から Windows のトースト通知を出すための常駐サーバ。UNIX socket で JSON リクエストを受け取り、PowerShell 経由で Windows の Toast Notification API を呼び出す。WSL 専用。

## コマンド

- `notify` - サーバ本体。`NOTIFY_SOCK` 環境変数（既定 `/tmp/notify.sock`）で指定した UNIX socket を listen し、受信した `NotifyRequest`（JSON）ごとに Windows へトースト通知を送る。起動時に同名の socket ファイルが既に存在すれば削除してから listen する（前回異常終了時の残骸対策）。クライアントは接続してリクエストの JSON を書き込み、応答（`NotifyResponse`、`{ status: "ok" | "error", error?: string }`）を待つ。`NotifyRequest` はタイトル・メッセージ・属性表示・クリック時の遷移先 URL・ボタン・画像（`appLogoOverride` / `hero` 配置、`circle` トリミング）・オーディオ・表示時間（`long` / `short`）を持てる。

## 構成

エントリポイント（`notify.ts`）+ 副作用を持つ 2 つの lib モジュールに分離している。

- `notify.ts` - サーバ起動本体。`NOTIFY_SOCK` の解決（env 読み取りはここでのみ行い、lib には ambient な env 読みを持たせない）と、`lib/socket.ts` の `startSocketServer()` に `lib/notifier.ts` の `sendWindowsNotification()` を `onMessage` として渡す組み立てを行う。
- `lib/socket.ts` - UNIX socket サーバ。1 回の `read` がメッセージ全体を保証しないストリームである点に対応するため、受信バイトを貯めて `JSON.parse` が成功した時点で完了とみなす方式で 1 リクエストを受信する（各 `read` にタイムアウト、合計サイズに上限を設ける）。接続は並列処理し、1 接続のエラーがサーバ全体を止めないようにする。
- `lib/notifier.ts` - Windows トースト通知の組み立てと送信。`NotifyRequest` / `NotifyResponse` の型定義もここに置く。通知本文は XML の不正文字・ANSI エスケープを除去した上でエスケープし、各テキスト要素は Windows 側のペイロードサイズ上限に収まるよう文字数を切り詰める。XML は base64 化して PowerShell スクリプトの stdin へ渡す（コマンドライン引数の長さ上限を避け、展開可能 here-string への直接埋め込みによる特殊文字破壊も避けるため）。WSL パスの画像はハッシュベースのファイル名で Windows 側 TEMP フォルダへコピーしてから参照する。

`lib/socket.ts` / `lib/notifier.ts` は環境変数を直接読まず、`notify.ts` から必要な値（socket パス等）を受け取る設計を徹底している。`deno.json` にモジュール固有の依存は無い。

### クライアントとのワイヤ契約

クライアントは `.claude/scripts/notify.ts`（Claude Code のフック）。`.claude/scripts` は `~/.claude` へシンボリックリンクされた別 deno プロジェクトのため、サーバ側の `scripts/notify/lib` を相対 import できない。そのため socket パスと `NotifyRequest` 型は `.claude/scripts/notify-wire.ts` に複製して持ち、コードは共有せず UNIX socket 上の JSON というワイヤ契約だけを両端で一致させている。

## ビルドとテスト

リポジトリルートで `deno task build` を実行すると、エントリ（`notify.ts`）が `deno bundle` で単一ファイル化され、`.local/bin/notify` として配置される（`lib/` はビルド対象から外れる）。

`deno task test` でリポジトリ全体のユニットテスト（`lib/*.test.ts`）を実行する。

## systemd サービス

- `notify.service` - `notify` を `Restart=always` で常駐させる systemd ユーザサービス。`NOTIFY_SOCK=/tmp/notify.sock` を渡す。
- 有効化: `deno task build` 後に `systemctl --user enable --now notify`。
