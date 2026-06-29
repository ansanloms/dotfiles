import { assertEquals } from "@std/assert";
import {
  type ClipImageDeps,
  type CommandResult,
  destFileName,
  formatStamp,
  hasCopyPathFlag,
  osc52,
  resolveCacheDir,
  run,
} from "./clip-image.ts";

Deno.test("formatStamp はゼロ詰めの YYYYMMDD-HHMMSS-mmm を返す", () => {
  const d = new Date(2026, 5, 29, 9, 7, 5, 3); // 6 月 = month index 5
  assertEquals(formatStamp(d), "20260629-090705-003");
});

Deno.test("destFileName は clip-<stamp>.png", () => {
  assertEquals(
    destFileName("20260629-090705-003"),
    "clip-20260629-090705-003.png",
  );
});

Deno.test("osc52 は ESC]52;c;<base64>BEL を生成する", () => {
  // "abc" の base64 は "YWJj"。
  const bytes = osc52("abc");
  assertEquals(new TextDecoder().decode(bytes), "\x1b]52;c;YWJj\x07");
});

Deno.test("resolveCacheDir は XDG_CACHE_HOME を優先する", () => {
  const env = new Map([["XDG_CACHE_HOME", "/xdg"], ["HOME", "/home/u"]]);
  assertEquals(resolveCacheDir({ get: (k) => env.get(k) }), "/xdg/clip-image");
});

Deno.test("resolveCacheDir は XDG 未設定なら HOME/.cache", () => {
  const env = new Map([["HOME", "/home/u"]]);
  assertEquals(
    resolveCacheDir({ get: (k) => env.get(k) }),
    "/home/u/.cache/clip-image",
  );
});

Deno.test("hasCopyPathFlag は --copy-path / -c を検出する", () => {
  assertEquals(hasCopyPathFlag([]), false);
  assertEquals(hasCopyPathFlag(["--copy-path"]), true);
  assertEquals(hasCopyPathFlag(["-c"]), true);
  assertEquals(hasCopyPathFlag(["x", "-c", "y"]), true);
});

// run() 用のフェイク deps を組み立てるヘルパ。
function fakeDeps(overrides: Partial<ClipImageDeps> = {}): {
  deps: ClipImageDeps;
  out: string[];
  err: string[];
  clipboard: Uint8Array[];
  copied: Array<[string, string]>;
  removed: string[];
  mkdirs: string[];
} {
  const out: string[] = [];
  const err: string[] = [];
  const clipboard: Uint8Array[] = [];
  const copied: Array<[string, string]> = [];
  const removed: string[] = [];
  const mkdirs: string[] = [];

  const ok = (stdout: string): CommandResult => ({
    code: 0,
    success: true,
    stdout,
    stderr: "",
  });

  const deps: ClipImageDeps = {
    args: [],
    env: { get: (k) => (k === "HOME" ? "/home/u" : undefined) },
    now: () => new Date(2026, 5, 29, 9, 7, 5, 3),
    runPowershell: () => Promise.resolve(ok("C:\\Temp\\x.png")),
    runWslpath: () => Promise.resolve(ok("/mnt/c/Temp/x.png")),
    mkdirp: (dir) => {
      mkdirs.push(dir);
      return Promise.resolve();
    },
    copyFile: (src, dest) => {
      copied.push([src, dest]);
      return Promise.resolve();
    },
    removeFile: (path) => {
      removed.push(path);
      return Promise.resolve();
    },
    writeClipboard: (bytes) => clipboard.push(bytes),
    stdout: (line) => out.push(line),
    stderr: (line) => err.push(line),
    ...overrides,
  };

  return { deps, out, err, clipboard, copied, removed, mkdirs };
}

Deno.test("run: 画像が無ければ exit 1 とエラー出力", async () => {
  const f = fakeDeps({
    runPowershell: () =>
      Promise.resolve({ code: 3, success: false, stdout: "", stderr: "" }),
  });
  assertEquals(await run(f.deps), 1);
  assertEquals(f.out, []);
  assertEquals(f.err, ["clip-image: クリップボードに画像がない"]);
});

Deno.test("run: powershell が他の失敗をしたら exit 1", async () => {
  const f = fakeDeps({
    runPowershell: () =>
      Promise.resolve({ code: 1, success: false, stdout: "", stderr: "boom" }),
  });
  assertEquals(await run(f.deps), 1);
  assertEquals(f.err, ["clip-image: powershell 失敗: boom"]);
});

Deno.test("run: 一時パスが空なら exit 1", async () => {
  const f = fakeDeps({
    runPowershell: () =>
      Promise.resolve({ code: 0, success: true, stdout: "  ", stderr: "" }),
  });
  assertEquals(await run(f.deps), 1);
  assertEquals(f.err, ["clip-image: 一時ファイルのパスを取得できなかった"]);
});

Deno.test("run: wslpath が失敗したら exit 1", async () => {
  const f = fakeDeps({
    runWslpath: () =>
      Promise.resolve({
        code: 1,
        success: false,
        stdout: "",
        stderr: "bad path",
      }),
  });
  assertEquals(await run(f.deps), 1);
  assertEquals(f.err, ["clip-image: wslpath 失敗: bad path"]);
});

Deno.test("run: 成功時は保存・削除しパスを stdout へ (--copy-path なし)", async () => {
  const f = fakeDeps();
  assertEquals(await run(f.deps), 0);
  const expected = "/home/u/.cache/clip-image/clip-20260629-090705-003.png";
  assertEquals(f.mkdirs, ["/home/u/.cache/clip-image"]);
  assertEquals(f.copied, [["/mnt/c/Temp/x.png", expected]]);
  assertEquals(f.removed, ["/mnt/c/Temp/x.png"]);
  assertEquals(f.clipboard.length, 0);
  assertEquals(f.out, [expected]);
});

Deno.test("run: --copy-path で OSC 52 を発火する", async () => {
  const f = fakeDeps({ args: ["--copy-path"] });
  assertEquals(await run(f.deps), 0);
  const expected = "/home/u/.cache/clip-image/clip-20260629-090705-003.png";
  assertEquals(f.clipboard.length, 1);
  assertEquals(f.clipboard[0], osc52(expected));
  assertEquals(f.err, ["clip-image: パスをクリップボードへコピーした"]);
  assertEquals(f.out, [expected]);
});

Deno.test("run: 一時ファイル削除が失敗しても成功扱い", async () => {
  const f = fakeDeps({
    removeFile: () => Promise.reject(new Error("locked")),
  });
  assertEquals(await run(f.deps), 0);
  assertEquals(f.out.length, 1);
});
