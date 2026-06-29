import { assertEquals } from "@std/assert";
import { frame, readFrames } from "./clip-image-frame.ts";

Deno.test("frame は 4 byte big-endian 長 + 本体を前置きする", () => {
  const f = frame(new Uint8Array([0xaa, 0xbb, 0xcc]));
  assertEquals(f, new Uint8Array([0, 0, 0, 3, 0xaa, 0xbb, 0xcc]));
});

// 与えたチャンク列から取り出せたフレーム (ペイロード) を集める。
async function collect(chunks: Uint8Array[]): Promise<Uint8Array[]> {
  async function* gen(): AsyncIterable<Uint8Array> {
    for (const c of chunks) {
      yield c;
    }
  }
  const out: Uint8Array[] = [];
  for await (const f of readFrames(gen())) {
    out.push(f);
  }
  return out;
}

Deno.test("readFrames は 1 チャンク内の複数フレームを分解する", async () => {
  const data = new Uint8Array([
    ...frame(new Uint8Array([1, 2])),
    ...frame(new Uint8Array([3, 4, 5])),
  ]);
  const got = await collect([data]);
  assertEquals(got, [new Uint8Array([1, 2]), new Uint8Array([3, 4, 5])]);
});

Deno.test("readFrames はフレーム途中で切れたチャンクを再構成する", async () => {
  const whole = frame(new Uint8Array([9, 8, 7, 6]));
  // 長さヘッダの途中、本体の途中で分割する。
  const got = await collect([
    whole.slice(0, 2),
    whole.slice(2, 5),
    whole.slice(5),
  ]);
  assertEquals(got, [new Uint8Array([9, 8, 7, 6])]);
});

Deno.test("readFrames は不完全な末尾フレームを出さない", async () => {
  const whole = frame(new Uint8Array([1, 2, 3, 4]));
  // 本体が 1 byte 足りない。
  const got = await collect([whole.slice(0, whole.length - 1)]);
  assertEquals(got, []);
});
