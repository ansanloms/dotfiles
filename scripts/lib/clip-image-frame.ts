// clip-image-watch (サーバ) と clip-image-clip (クライアント) で共有する
// 長さ前置きのバイナリフレーミング。1 フレーム = 4 byte big-endian の長さ N +
// N byte のペイロード (PNG)。unix socket は境界の無いバイトストリームなので、
// PNG を 1 単位として区切るためにフレーム長を前置きする。

/** ペイロードを 4 byte 長 + 本体のフレームに包む。 */
export function frame(payload: Uint8Array): Uint8Array {
  const out = new Uint8Array(4 + payload.length);
  new DataView(out.buffer).setUint32(0, payload.length, false);
  out.set(payload, 4);
  return out;
}

function concat(a: Uint8Array, b: Uint8Array): Uint8Array {
  const c = new Uint8Array(a.length + b.length);
  c.set(a, 0);
  c.set(b, a.length);
  return c;
}

// バイトチャンク列をフレーム境界で区切り、ペイロードを順に取り出す。
// チャンクはフレームの途中で切れていてよい (バッファに溜めて再構成する)。
export async function* readFrames(
  chunks: AsyncIterable<Uint8Array>,
): AsyncIterable<Uint8Array> {
  let buf: Uint8Array = new Uint8Array(0);
  for await (const chunk of chunks) {
    buf = concat(buf, chunk);
    while (buf.length >= 4) {
      const len = new DataView(buf.buffer, buf.byteOffset, 4).getUint32(
        0,
        false,
      );
      if (buf.length < 4 + len) {
        break;
      }
      yield buf.slice(4, 4 + len);
      buf = buf.slice(4 + len);
    }
  }
}
