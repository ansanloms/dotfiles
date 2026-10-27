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
  logs: string[];
  errors: string[];
} {
  const bundled: Array<[string, string]> = [];
  const chmodded: string[] = [];
  const logs: string[] = [];
  const errors: string[] = [];

  async function* readDir(dir: string): AsyncIterable<BuildEntry> {
    for (const e of entriesByDir[dir] ?? []) {
      yield e;
    }
  }

  const deps: BuildDeps = {
    readDir,
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

  return { deps, bundled, chmodded, logs, errors };
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
    ["scripts/sample-tool/sample-tool.ts", ".local/bin/sample-tool"],
  ]);
  assertEquals(f.chmodded, [".local/bin/sample-tool"]);
  assertEquals(f.logs, ["Built: .local/bin/sample-tool"]);
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
    ["scripts/sample-tool/sample-tool.ts", ".local/bin/sample-tool"],
    ["scripts/other-tool/other-tool.ts", ".local/bin/other-tool"],
  ]);
  assertEquals(f.chmodded, [".local/bin/sample-tool", ".local/bin/other-tool"]);
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
  assertEquals(f.bundled, [["scripts/a/a.ts", ".local/bin/a"]]);
  assertEquals(f.errors, ["boom"]);
  assertEquals(f.logs, []);
});
