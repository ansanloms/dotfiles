import { assertEquals } from "@std/assert";
import {
  buildLabel,
  type Colors,
  computeColumnWidths,
  type Entry,
  filterTargets,
  padVisible,
  parseWorktreeList,
  pickDefault,
  run,
  type SelectDeps,
  type SelectOptions,
} from "./git-worktree-select.ts";

const PLAIN: Colors = { path: (s) => s, branch: (s) => s, desc: (s) => s };

Deno.test("parseWorktreeList は有効行をパースし無効行を捨てる", () => {
  const out = [
    "/home/u/repo            abc1234 [main]",
    "garbage line",
    "/home/u/repo/.wt/feat   def5678 [feature-x]",
  ].join("\n");
  assertEquals(parseWorktreeList(out), [
    { path: "/home/u/repo", sha: "abc1234", branch: "main" },
    { path: "/home/u/repo/.wt/feat", sha: "def5678", branch: "feature-x" },
  ]);
});

Deno.test("filterTargets は --exclude-main で先頭を除く", () => {
  const wts = [
    { path: "/a", sha: "1", branch: "main" },
    { path: "/b", sha: "2", branch: "x" },
  ];
  assertEquals(filterTargets(wts, false), wts);
  assertEquals(filterTargets(wts, true), [{
    path: "/b",
    sha: "2",
    branch: "x",
  }]);
});

Deno.test("pickDefault は cwd に前方一致した最初の worktree を選ぶ", () => {
  const wts = [
    { path: "/a/b", sha: "2", branch: "x" },
    { path: "/a", sha: "1", branch: "main" },
  ];
  // 先頭から最初に前方一致したものを返す (元コードの挙動)。
  assertEquals(pickDefault(wts, "/a/b/sub"), "/a/b");
  assertEquals(pickDefault(wts, "/a/sub"), "/a");
  assertEquals(pickDefault(wts, "/other"), undefined);
});

Deno.test("padVisible は ANSI を幅に数えず右詰めする", () => {
  assertEquals(padVisible("ab", 5), "ab   ");
  assertEquals(padVisible("\x1b[36mab\x1b[39m", 5), "\x1b[36mab\x1b[39m   ");
  assertEquals(padVisible("toolong", 3), "toolong");
});

Deno.test("computeColumnWidths は最大表示幅を求める", () => {
  const entries: Entry[] = [
    { path: "/a", sha: "1", branch: "main", relativePath: ".", desc: "" },
    {
      path: "/b",
      sha: "2",
      branch: "feature",
      relativePath: "wt/feat",
      desc: "",
    },
  ];
  assertEquals(computeColumnWidths(entries), {
    maxPathLen: "wt/feat".length,
    maxBranchLen: "[feature]".length,
  });
});

Deno.test("buildLabel は desc 有無で形を変える", () => {
  const widths = { maxPathLen: 4, maxBranchLen: 6 };
  const base: Entry = {
    path: "/a",
    sha: "abc1234",
    branch: "main",
    relativePath: "wt",
    desc: "",
  };
  assertEquals(buildLabel(base, widths, PLAIN), "wt    abc1234 [main]");
  assertEquals(
    buildLabel({ ...base, desc: "作業中" }, widths, PLAIN),
    "wt    abc1234 [main]  # 作業中",
  );
});

function fakeDeps(overrides: Partial<SelectDeps> = {}): {
  deps: SelectDeps;
  errors: string[];
  selected: string[];
  selectCalls: SelectOptions[];
} {
  const errors: string[] = [];
  const selected: string[] = [];
  const selectCalls: SelectOptions[] = [];

  const deps: SelectDeps = {
    args: [],
    cwd: () => "/home/u/repo",
    listWorktrees: () =>
      Promise.resolve(
        "/home/u/repo abc1234 [main]\n/home/u/repo/.wt/feat def5678 [feature]",
      ),
    getDescription: () => Promise.resolve(""),
    select: (opts) => {
      selectCalls.push(opts);
      return Promise.resolve(opts.options[0].value);
    },
    writeSelected: (p) => selected.push(p),
    errorLine: (m) => errors.push(m),
    ...overrides,
  };

  return { deps, errors, selected, selectCalls };
}

Deno.test("run: worktree が無ければ exit 1", async () => {
  const f = fakeDeps({ listWorktrees: () => Promise.resolve("   ") });
  assertEquals(await run(f.deps), 1);
  assertEquals(f.errors, ["No worktrees found."]);
});

Deno.test("run: マッチ行が無ければ exit 1", async () => {
  const f = fakeDeps({
    listWorktrees: () => Promise.resolve("garbage\nmore garbage"),
  });
  assertEquals(await run(f.deps), 1);
  assertEquals(f.errors, ["No worktrees found."]);
});

Deno.test("run: --exclude-main で対象が空なら exit 1", async () => {
  const f = fakeDeps({
    args: ["--exclude-main"],
    listWorktrees: () => Promise.resolve("/home/u/repo abc1234 [main]"),
  });
  assertEquals(await run(f.deps), 1);
  assertEquals(f.errors, ["No worktrees to select."]);
});

Deno.test("run: 選択結果を stderr へ書き exit 0", async () => {
  const f = fakeDeps();
  assertEquals(await run(f.deps), 0);
  assertEquals(f.selectCalls.length, 1);
  assertEquals(f.selectCalls[0].options.map((o) => o.value), [
    "/home/u/repo",
    "/home/u/repo/.wt/feat",
  ]);
  assertEquals(f.selectCalls[0].default, "/home/u/repo");
  assertEquals(f.selected, ["/home/u/repo"]);
});
