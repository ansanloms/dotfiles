import { assertEquals } from "@std/assert";
import {
  type BuildDeps,
  type BuildEntry,
  isBuildableSource,
  outName,
  run,
} from "./build.ts";

Deno.test("isBuildableSource は build.ts とテストと非 ts を除く", () => {
  assertEquals(isBuildableSource("sample-tool.ts"), true);
  assertEquals(isBuildableSource("build.ts"), false);
  assertEquals(isBuildableSource("sample-tool.test.ts"), false);
  assertEquals(isBuildableSource("readme.md"), false);
});

Deno.test("outName は .ts を除去する", () => {
  assertEquals(outName("sample-tool.ts"), "sample-tool");
});

// dir ("scripts" または各 member ディレクトリ) ごとのエントリ一覧を与えて
// 二段走査 (member 列挙 → member 直下のファイル列挙) をフェイクする。
function fakeDeps(
  entriesByDir: Record<string, BuildEntry[]>,
  bundleResults: Record<string, { success: boolean; stderr: string }> = {},
): {
  deps: BuildDeps;
  bundled: Array<[string, string]>;
  chmodded: string[];
  removed: string[];
  logs: string[];
  errors: string[];
} {
  const bundled: Array<[string, string]> = [];
  const chmodded: string[] = [];
  const removed: string[] = [];
  const logs: string[] = [];
  const errors: string[] = [];

  async function* readDir(dir: string): AsyncIterable<BuildEntry> {
    for (const e of entriesByDir[dir] ?? []) {
      yield e;
    }
  }

  const deps: BuildDeps = {
    readDir,
    remove: (path) => {
      removed.push(path);
      return Promise.resolve();
    },
    bundle: (src, out) => {
      bundled.push([src, out]);
      return Promise.resolve(
        bundleResults[src] ?? { success: true, stderr: "" },
      );
    },
    chmod: (path) => {
      chmodded.push(path);
      return Promise.resolve();
    },
    log: (m) => logs.push(m),
    errorLog: (m) => errors.push(m),
  };

  return { deps, bundled, chmodded, removed, logs, errors };
}

Deno.test("run: member ディレクトリを列挙し lib は無視する", async () => {
  const f = fakeDeps({
    "scripts": [
      { name: "sample-tool", isFile: false, isDirectory: true },
      { name: "lib", isFile: false, isDirectory: true },
      { name: "readme.md", isFile: true, isDirectory: false },
    ],
    "scripts/sample-tool": [
      { name: "sample-tool.ts", isFile: true, isDirectory: false },
      { name: "sample-tool.test.ts", isFile: true, isDirectory: false },
      { name: "lib", isFile: false, isDirectory: true },
    ],
    // lib は走査されないはずなので、万一走査されたら検出できるよう
    // ダミーのエントリを仕込んでおく。
    "scripts/lib": [
      { name: "build.ts", isFile: true, isDirectory: false },
    ],
  });

  assertEquals(await run(f.deps), 0);
  assertEquals(f.bundled, [
    [
      "scripts/sample-tool/sample-tool.ts",
      "dot_local/bin/executable_sample-tool",
    ],
  ]);
  assertEquals(f.chmodded, ["dot_local/bin/executable_sample-tool"]);
  assertEquals(f.logs, ["Built: dot_local/bin/executable_sample-tool"]);
  assertEquals(f.errors, []);
});

Deno.test("run: 複数 member の直下エントリをすべて bundle する", async () => {
  const f = fakeDeps({
    "scripts": [
      { name: "sample-tool", isFile: false, isDirectory: true },
      { name: "other-tool", isFile: false, isDirectory: true },
    ],
    "scripts/sample-tool": [
      { name: "sample-tool.ts", isFile: true, isDirectory: false },
    ],
    "scripts/other-tool": [
      { name: "other-tool.ts", isFile: true, isDirectory: false },
    ],
  });

  assertEquals(await run(f.deps), 0);
  assertEquals(f.bundled, [
    [
      "scripts/sample-tool/sample-tool.ts",
      "dot_local/bin/executable_sample-tool",
    ],
    ["scripts/other-tool/other-tool.ts", "dot_local/bin/executable_other-tool"],
  ]);
  assertEquals(f.chmodded, [
    "dot_local/bin/executable_sample-tool",
    "dot_local/bin/executable_other-tool",
  ]);
});

Deno.test("run: bundle 失敗で exit 1 し以降を止める", async () => {
  const f = fakeDeps(
    {
      "scripts": [
        { name: "a", isFile: false, isDirectory: true },
      ],
      "scripts/a": [
        { name: "a.ts", isFile: true, isDirectory: false },
        { name: "b.ts", isFile: true, isDirectory: false },
      ],
    },
    { "scripts/a/a.ts": { success: false, stderr: "boom" } },
  );
  assertEquals(await run(f.deps), 1);
  assertEquals(f.bundled, [["scripts/a/a.ts", "dot_local/bin/executable_a"]]);
  assertEquals(f.errors, ["boom"]);
  assertEquals(f.logs, []);
});

Deno.test("run: 成功時に今回生成しなかった executable_ だけ削除する", async () => {
  const f = fakeDeps({
    "dot_local/bin": [
      { name: "executable_stale", isFile: true, isDirectory: false },
      { name: "executable_a", isFile: true, isDirectory: false },
      { name: ".gitkeep", isFile: true, isDirectory: false },
      { name: "other", isFile: true, isDirectory: false },
      { name: "executable_dir", isFile: false, isDirectory: true },
    ],
    "scripts": [
      { name: "a", isFile: false, isDirectory: true },
    ],
    "scripts/a": [
      { name: "a.ts", isFile: true, isDirectory: false },
    ],
  });
  assertEquals(await run(f.deps), 0);
  assertEquals(f.removed, ["dot_local/bin/executable_stale"]);
});

Deno.test("run: bundle 失敗時は既存の executable_ を削除しない", async () => {
  const f = fakeDeps(
    {
      "dot_local/bin": [
        { name: "executable_keep", isFile: true, isDirectory: false },
      ],
      "scripts": [
        { name: "a", isFile: false, isDirectory: true },
      ],
      "scripts/a": [
        { name: "a.ts", isFile: true, isDirectory: false },
      ],
    },
    { "scripts/a/a.ts": { success: false, stderr: "boom" } },
  );
  assertEquals(await run(f.deps), 1);
  assertEquals(f.removed, []);
});

Deno.test("run: 削除が NotFound でも残りの掃除を続ける", async () => {
  const f = fakeDeps({
    "dot_local/bin": [
      { name: "executable_x", isFile: true, isDirectory: false },
      { name: "executable_y", isFile: true, isDirectory: false },
    ],
  });
  f.deps.remove = (path) => {
    f.removed.push(path);
    return path.endsWith("executable_x")
      ? Promise.reject(new Deno.errors.NotFound("gone"))
      : Promise.resolve();
  };
  assertEquals(await run(f.deps), 0);
  assertEquals(f.removed, [
    "dot_local/bin/executable_x",
    "dot_local/bin/executable_y",
  ]);
});

Deno.test("run: 出力先が無くてもエラーにしない", async () => {
  const f = fakeDeps({});
  const readDir = f.deps.readDir;
  f.deps.readDir = (dir) => {
    if (dir === "dot_local/bin") {
      throw new Deno.errors.NotFound("no dir");
    }
    return readDir(dir);
  };
  assertEquals(await run(f.deps), 0);
  assertEquals(f.removed, []);
});
