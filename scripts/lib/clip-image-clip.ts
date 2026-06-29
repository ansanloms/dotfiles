// clip-image-clip (devcontainer 側クライアント) の純粋ロジック。
// 副作用 (socket のバイトストリーム / コンテナのクリップボードへの load / 出力) は
// ClipDeps として注入する。エントリポイント (scripts/clip-image-clip.ts) が
// 実物を組み立てて run() を呼ぶ。
//
// ホストの clip-image-watch が unix socket へ配信する PNG フレームを受け取り、
// コンテナのクリップボードへ image/png で載せる。これで devcontainer 内の
// Claude Code / Chrome 等で Ctrl+V 貼り付けできる。

import { readFrames } from "./clip-image-frame.ts";

export interface ClipDeps {
  // socket からのバイトチャンク列。
  chunks(): AsyncIterable<Uint8Array>;
  // 受信した PNG をコンテナのクリップボードへ image/png で載せる。
  loadClipboard(png: Uint8Array): Promise<void>;
  log(msg: string): void;
  errorLine(msg: string): void;
}

// socket のチャンク列をフレーム分解し、PNG のたびにクリップボードへ載せる。
// ストリームが尽きた (= 切断) ら非 0 を返し、エントリポイントの再接続に委ねる。
export async function run(deps: ClipDeps): Promise<number> {
  for await (const png of readFrames(deps.chunks())) {
    try {
      await deps.loadClipboard(png);
      deps.log(`clip-image-clip: loaded ${png.length} bytes`);
    } catch (e) {
      // 1 回の失敗で止めない。次のフレームを待つ。
      deps.errorLine(`clip-image-clip: clipboard load failed: ${e}`);
    }
  }

  deps.errorLine("clip-image-clip: stream ended");
  return 1;
}
