# clip-image

Windows ホストのクリップボード画像を WSL 側に取り込むためのモジュール。手動キャプチャ用の CLI と、自動取り込み用の常駐プロセス、devcontainer 側で受け取るクライアントで構成する。すべて WSL 専用。

## コマンド

- `clip-image` - Windows ホストのクリップボード画像（Win+Shift+S 等）を WSL の PNG に保存し、その絶対パスを stdout へ出力する。`powershell.exe` で画像を取得して native NTFS の一時領域へ書き出し、コピーは WSL 側から行う（`.NET` の `Image.Save` を `\\wsl$` パスへ直接書かせないため）。保存先ディレクトリは `$XDG_CACHE_HOME/clip-image` または `~/.cache/clip-image`。保存と同時にそのディレクトリ内の `latest.png` を最新キャプチャへ張り替える。
  - `--copy-path` / `-c` - 保存先パスを OSC 52 で制御端末（`/dev/tty`）へ直接書き、クリップボードへ載せる。stdout は汚さない。claude code 等の入力欄に Ctrl+V でパスを貼れるようにする。
- `clip-image-watch` - 上記を自動化する常駐プロセス。`powershell.exe` を 1 個常駐起動し、`AddClipboardFormatListener` でクリップボード更新をイベント購読する（ポーリングしない）。画像コピーのたびにリスナが 1 行 (`image`) を stdout へ吐き、それを受けて `clip-image` を起動する。リスナが死んだら非 0 で終了し、systemd の `Restart=always` に再起動させる。取り込んだ PNG は Linux クリップボード（`wl-copy` + `xclip`、両方試みる）へも `image/png` で載せ、さらに unix socket（既定 `/tmp/clip-image.sock`、`CLIP_IMAGE_SOCK` で変更可）へ接続中の全クライアントへ配信する。フレーム形式は 4 byte big-endian の長さ + PNG 本体。
- `clip-image-clip` - devcontainer 内で常駐するクライアント。ホストの `clip-image-watch` が listen する unix socket に接続し、配信される PNG フレームを受信してコンテナのクリップボードへ `image/png` で載せる（`wl-copy` + `xclip`）。切断したら 3 秒待って再接続する。

## 構成

各エントリは「薄いエントリポイント + 依存注入した `run()`」に分離している。副作用（`powershell.exe` / `wslpath` / fs / tty / socket 通信等）はエントリ側で組み立てて注入し、`lib/*.ts` は副作用を持たない純粋ロジックとしてユニットテストする。

- `clip-image.ts` - CLI 本体。`lib/clip-image.ts` の `run()` へ powershell 実行・wslpath 変換・ファイル操作・OSC 52 書き込みを注入する。
- `clip-image-watch.ts` - 常駐監督プロセス本体。powershell リスナの起動、行ストリームの変換、Linux クリップボードへの読み込み、unix socket サーバ（接続受け付け・配信）を組み立て、`lib/watch.ts` の `run()` へ注入する。
- `clip-image-clip.ts` - devcontainer クライアント本体。socket への接続・再接続ループを持ち、`lib/clip.ts` の `run()` へバイトストリームとクリップボード書き込みを注入する。
- `lib/clip-image.ts` - `clip-image` の保存先パス解決・ファイル名生成・OSC 52 エスケープ組み立てなどの純粋ロジックとオーケストレーション。
- `lib/watch.ts` - `clip-image-watch` の純粋ロジック。powershell リスナに埋め込む C# ソース（`lib/clipboard-watcher.cs`、`with { type: "text" }` で取り込み）を使ったリスナ用スクリプト文字列の組み立てを含む。
- `lib/clip.ts` - `clip-image-clip` の純粋ロジック（フレーム受信ループの制御）。
- `lib/frame.ts` - サーバ・クライアント間で共有する長さ前置きバイナリフレーミング（`frame()` で包み、`readFrames()` で分解する）。
- `lib/clipboard-watcher.cs` - `AddClipboardFormatListener` でクリップボード更新イベントを受け取る C# クラス。`watch.ts` からテキストとして取り込み、powershell の `Add-Type` へ渡す。

モジュール固有の依存は `deno.json` の `@std/streams`（powershell リスナの stdout を行単位ストリームへ変換する `TextLineStream` に使用）のみ。

## ビルドとテスト

リポジトリルートで `deno task build` を実行すると、各エントリ（`clip-image.ts` / `clip-image-watch.ts` / `clip-image-clip.ts`）が `deno bundle` で単一ファイル化され、`.local/bin/<エントリファイル名（拡張子なし）>` として配置される（`lib/` はビルド対象から外れる）。

`deno task test` でリポジトリ全体のユニットテスト（`lib/*.test.ts`）を実行する。

## systemd サービス

- `clip-image-watch.service` - `clip-image-watch` を `Restart=always` で常駐させる systemd ユーザサービス。systemd ユーザインスタンスの最小 PATH には WSL interop 用の Windows ディレクトリが含まれないため、`PATH` に `WindowsPowerShell` のディレクトリを補って起動する。`wl-copy` / `xclip` が WSLg のコンポジタへ接続できるよう `WAYLAND_DISPLAY` / `DISPLAY` を設定する。`CLIP_IMAGE_SOCK`（既定 `/tmp/clip-image.sock`）で devcontainer へ配信する unix socket のパスを指定する。
- 有効化: `deno task build` 後に `systemctl --user enable --now clip-image-watch`。
