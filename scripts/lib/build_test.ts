import { assertEquals } from "@std/assert";
import {
  type BuildDeps,
  type BuildEntry,
  isBuildableSource,
  outName,
  run,
} from "./build.ts";

Deno.test("isBuildableSource は build.ts とテストと非 ts を除く", () => {
  assertEquals(isBuildableSource("clip-image.ts"), true);
  assertEquals(isBuildableSource("build.ts"), false);
  assertEquals(isBuildableSource("clip-image_test.ts"), false);
  assertEquals(isBuildableSource("readme.md"), false);
});

Deno.test("outName は .ts を除去する", () => {
  assertEquals(outName("clip-image.ts"), "clip-image");
});

function fakeDeps(
  entries: BuildEntry[],
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

  async function* readDir(): AsyncIterable<BuildEntry> {
    for (const e of entries) {
      yield e;
    }
  }

  const deps: BuildDeps = {
    readDir: () => readDir(),
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

Deno.test("run: 対象だけ bundle し chmod・log する", async () => {
  const f = fakeDeps([
    { name: "clip-image.ts", isFile: true },
    { name: "build.ts", isFile: true },
    { name: "clip-image_test.ts", isFile: true },
    { name: "lib", isFile: false },
    { name: "readme.md", isFile: true },
  ]);
  assertEquals(await run(f.deps), 0);
  assertEquals(f.bundled, [["scripts/clip-image.ts", ".local/bin/clip-image"]]);
  assertEquals(f.chmodded, [".local/bin/clip-image"]);
  assertEquals(f.logs, ["Built: .local/bin/clip-image"]);
  assertEquals(f.errors, []);
});

Deno.test("run: bundle 失敗で exit 1 し以降を止める", async () => {
  const f = fakeDeps(
    [
      { name: "a.ts", isFile: true },
      { name: "b.ts", isFile: true },
    ],
    { "scripts/a.ts": { success: false, stderr: "boom" } },
  );
  assertEquals(await run(f.deps), 1);
  assertEquals(f.bundled, [["scripts/a.ts", ".local/bin/a"]]);
  assertEquals(f.errors, ["boom"]);
  assertEquals(f.logs, []);
});
