import { assertEquals } from "@std/assert";
import {
  buildExcludePatterns,
  buildIgnore,
  type IncludeDeps,
  parsePorcelain,
  resolveDst,
  run,
  type WalkEntry,
} from "./git-worktree-include.ts";

Deno.test("parsePorcelain は main と他 worktree を分離する", () => {
  const out = [
    "worktree /home/u/repo",
    "HEAD abc",
    "branch refs/heads/main",
    "",
    "worktree /home/u/repo/.wt/feat",
    "HEAD def",
    "branch refs/heads/feat",
  ].join("\n");
  assertEquals(parsePorcelain(out), {
    mainWt: "/home/u/repo",
    others: ["/home/u/repo/.wt/feat"],
  });
});

Deno.test("buildExcludePatterns は .git・否定行・他 worktree を含む", () => {
  const content = ["*.log", "!keep/", "build/"].join("\n");
  const patterns = buildExcludePatterns(
    content,
    ["/home/u/repo/.wt/feat"],
    "/home/u/repo",
  );
  assertEquals(patterns, [".git", "keep/", ".wt/feat/**"]);
});

Deno.test("resolveDst は最初の位置引数を返す", () => {
  assertEquals(resolveDst(["-f", "/dst", "main"]), "/dst");
  assertEquals(resolveDst(["--force", "/dst"]), "/dst");
  assertEquals(resolveDst(["-b", "newbranch", "/dst"]), "/dst");
  assertEquals(resolveDst(["--quiet"]), null);
  assertEquals(resolveDst([]), null);
});

Deno.test("buildIgnore はマッチ行 (= コピー対象) を判定する", () => {
  const ig = buildIgnore([".env", "config/*.local"].join("\n"));
  assertEquals(ig.ignores(".env"), true);
  assertEquals(ig.ignores("config/db.local"), true);
  assertEquals(ig.ignores("src/main.ts"), false);
});

function fakeDeps(overrides: Partial<IncludeDeps> = {}): {
  deps: IncludeDeps;
  copied: Array<[string, string]>;
  logs: string[];
  ensured: string[];
} {
  const copied: Array<[string, string]> = [];
  const logs: string[] = [];
  const ensured: string[] = [];

  async function* walk(): AsyncIterable<WalkEntry> {
    yield { path: "/home/u/repo/.env", isFile: true };
    yield { path: "/home/u/repo/src", isFile: false };
    yield { path: "/home/u/repo/src/main.ts", isFile: true };
  }

  const deps: IncludeDeps = {
    args: ["/dst"],
    runGitPorcelain: () => Promise.resolve("worktree /home/u/repo\n"),
    exists: () => Promise.resolve(true),
    readText: () => Promise.resolve(".env\n"),
    resolve: (p) => p,
    walk: () => walk(),
    ensureDir: (dir) => {
      ensured.push(dir);
      return Promise.resolve();
    },
    copyFile: (src, dest) => {
      copied.push([src, dest]);
      return Promise.resolve();
    },
    log: (msg) => logs.push(msg),
    ...overrides,
  };

  return { deps, copied, logs, ensured };
}

Deno.test("run: .worktreeinclude が無ければ何もせず exit 0", async () => {
  const f = fakeDeps({ exists: () => Promise.resolve(false) });
  assertEquals(await run(f.deps), 0);
  assertEquals(f.copied, []);
});

Deno.test("run: コピー先パスが無ければ exit 0", async () => {
  const f = fakeDeps({ args: ["--quiet"] });
  assertEquals(await run(f.deps), 0);
  assertEquals(f.copied, []);
});

Deno.test("run: マッチしたファイルのみコピーする", async () => {
  const f = fakeDeps();
  assertEquals(await run(f.deps), 0);
  // .env はマッチ (コピー)、src (ディレクトリ) と src/main.ts は非マッチ。
  assertEquals(f.copied, [["/home/u/repo/.env", "/dst/.env"]]);
  assertEquals(f.ensured, ["/dst"]);
  assertEquals(f.logs, ["Copied: .env"]);
});
