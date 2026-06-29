import { assertEquals, assertStringIncludes } from "@std/assert";
import { type ClipDeps, run } from "./clip-image-clip.ts";
import { frame } from "./clip-image-frame.ts";

function fakeDeps(chunkList: Uint8Array[], overrides: Partial<ClipDeps> = {}): {
  deps: ClipDeps;
  loaded: Uint8Array[];
  logs: string[];
  errors: string[];
} {
  const loaded: Uint8Array[] = [];
  const logs: string[] = [];
  const errors: string[] = [];

  async function* chunks(): AsyncIterable<Uint8Array> {
    for (const c of chunkList) {
      yield c;
    }
  }

  const deps: ClipDeps = {
    chunks,
    loadClipboard: (p) => {
      loaded.push(p);
      return Promise.resolve();
    },
    log: (m) => logs.push(m),
    errorLine: (m) => errors.push(m),
    ...overrides,
  };

  return { deps, loaded, logs, errors };
}

Deno.test("run: 受信フレームごとにクリップボードへ載せる", async () => {
  const data = new Uint8Array([
    ...frame(new Uint8Array([1, 2, 3])),
    ...frame(new Uint8Array([4, 5])),
  ]);
  const f = fakeDeps([data]);
  const code = await run(f.deps);
  assertEquals(code, 1); // 切断で再接続を促す
  assertEquals(f.loaded, [new Uint8Array([1, 2, 3]), new Uint8Array([4, 5])]);
  assertEquals(f.logs.length, 2);
  assertStringIncludes(f.errors[f.errors.length - 1], "stream ended");
});

Deno.test("run: クリップボード load の失敗で止めない", async () => {
  const data = new Uint8Array([
    ...frame(new Uint8Array([1])),
    ...frame(new Uint8Array([2])),
  ]);
  let n = 0;
  const f = fakeDeps([data], {
    loadClipboard: () => {
      n++;
      if (n === 1) {
        return Promise.reject(new Error("boom"));
      }
      return Promise.resolve();
    },
  });
  const code = await run(f.deps);
  assertEquals(code, 1);
  // 2 件目だけ成功ログ。
  assertEquals(f.logs.length, 1);
  assertStringIncludes(f.errors[0], "clipboard load failed");
  assertStringIncludes(f.errors[0], "boom");
});
