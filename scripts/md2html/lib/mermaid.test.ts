import { assertEquals, assertRejects, assertStringIncludes } from "@std/assert";
import {
  bundleRevision,
  getMermaidBundle,
  type MermaidBundleDeps,
  mermaidEntrySource,
  resolveCacheDir,
} from "./mermaid.ts";

Deno.test("mermaidEntrySource は pin 済みの npm:mermaid 指定子を含む", () => {
  const source = mermaidEntrySource("11.16.0");
  assertStringIncludes(source, 'import mermaid from "npm:mermaid@11.16.0";');
});

Deno.test("mermaidEntrySource は ./mermaid-zoom.js の initMermaidZoom を呼ぶ", () => {
  const source = mermaidEntrySource("11.16.0");
  assertStringIncludes(
    source,
    'import { initMermaidZoom } from "./mermaid-zoom.js";',
  );
  assertStringIncludes(source, "await initMermaidZoom(mermaid);");
});

Deno.test("resolveCacheDir は XDG_CACHE_HOME を優先する", () => {
  const env = new Map([["XDG_CACHE_HOME", "/xdg"], ["HOME", "/home/u"]]);
  assertEquals(resolveCacheDir((k) => env.get(k)), "/xdg/md2html");
});

Deno.test("resolveCacheDir は XDG 未設定なら HOME/.cache", () => {
  const env = new Map([["HOME", "/home/u"]]);
  assertEquals(resolveCacheDir((k) => env.get(k)), "/home/u/.cache/md2html");
});

/** テスト用の最小 MermaidBundleDeps。キャッシュファイルの有無を files で表現する。 */
function makeDeps(
  overrides: Partial<MermaidBundleDeps> = {},
): { deps: MermaidBundleDeps; bundleCalls: Array<[string, string]> } {
  const files = new Map<string, string>();
  const bundleCalls: Array<[string, string]> = [];

  const deps: MermaidBundleDeps = {
    env: (key) => key === "HOME" ? "/home/u" : undefined,
    readTextFile: (path) => {
      const text = files.get(path);
      if (text === undefined) {
        return Promise.reject(new Deno.errors.NotFound(path));
      }
      return Promise.resolve(text);
    },
    writeTextFile: (path, text) => {
      files.set(path, text);
      return Promise.resolve();
    },
    mkdir: () => Promise.resolve(),
    makeTempDir: () => Promise.resolve("/tmp/md2html-test"),
    bundle: (entryPath, outPath) => {
      bundleCalls.push([entryPath, outPath]);
      files.set(outPath, "/* bundled mermaid */");
      return Promise.resolve();
    },
    ...overrides,
  };

  return { deps, bundleCalls };
}

Deno.test("getMermaidBundle: キャッシュがあれば bundle を呼ばずそれを返す", async () => {
  const { deps, bundleCalls } = makeDeps();
  const revision = bundleRevision("11.16.0");
  await deps.writeTextFile(
    `/home/u/.cache/md2html/mermaid-11.16.0-${revision}.bundle.js`,
    "/* cached */",
  );

  const result = await getMermaidBundle(deps, "11.16.0");

  assertEquals(result, "/* cached */");
  assertEquals(bundleCalls.length, 0);
});

Deno.test("getMermaidBundle: キャッシュが無ければ bundle して保存する", async () => {
  const { deps, bundleCalls } = makeDeps();
  const revision = bundleRevision("11.16.0");

  const result = await getMermaidBundle(deps, "11.16.0");

  assertEquals(result, "/* bundled mermaid */");
  assertEquals(bundleCalls.length, 1);
  const [entryPath, outPath] = bundleCalls[0];
  assertEquals(
    outPath,
    `/home/u/.cache/md2html/mermaid-11.16.0-${revision}.bundle.js`,
  );
  assertStringIncludes(entryPath, "/tmp/md2html-test");
});

Deno.test("getMermaidBundle: 一時ディレクトリへ mermaid-zoom.js を書き出す (panzoom.js は書かない)", async () => {
  const { deps } = makeDeps();
  const files: Record<string, string> = {};
  const writeTextFile = deps.writeTextFile;
  deps.writeTextFile = (path, text) => {
    files[path] = text;
    return writeTextFile(path, text);
  };

  await getMermaidBundle(deps, "11.16.0");

  assertStringIncludes(
    files["/tmp/md2html-test/mermaid-zoom.js"] ?? "",
    "initMermaidZoom",
  );
  assertEquals("/tmp/md2html-test/panzoom.js" in files, false);
});

Deno.test("getMermaidBundle: bundle の失敗は throw で伝播する", async () => {
  const { deps } = makeDeps({
    bundle: () => Promise.reject(new Error("deno bundle 失敗")),
  });

  await assertRejects(
    () => getMermaidBundle(deps, "11.16.0"),
    Error,
    "deno bundle 失敗",
  );
});
