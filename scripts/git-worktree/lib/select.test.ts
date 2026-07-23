import { assertEquals } from "@std/assert";
import {
  branchLabel,
  buildFzfLine,
  buildLabel,
  type Colors,
  computeColumnWidths,
  type Entry,
  filterTargets,
  formatSubject,
  type FzfRequest,
  lockLabel,
  padVisible,
  parseWorktreePorcelain,
  pickDefaultIndex,
  PREVIEW_COMMAND,
  run,
  type SelectDeps,
  selectedPath,
  type Worktree,
} from "./select.ts";

const PLAIN: Colors = {
  path: (s) => s,
  branch: (s) => s,
  lock: (s) => s,
  desc: (s) => s,
};

function wt(over: Partial<Worktree> & Pick<Worktree, "path">): Worktree {
  return { sha: "", branch: "", locked: false, lockReason: "", ...over };
}

function entry(over: Partial<Entry> & Pick<Entry, "path">): Entry {
  return { relativePath: ".", desc: "", ...wt(over), ...over };
}

Deno.test("parseWorktreePorcelain は locked / detached を含めてパースする", () => {
  const out = [
    "worktree /home/u/repo",
    "HEAD abc1234abc1234abc1234abc1234abc1234abc1",
    "branch refs/heads/main",
    "",
    "worktree /home/u/repo/.wt/feat",
    "HEAD def5678def5678def5678def5678def5678def5",
    "branch refs/heads/feature-x",
    "locked",
    "",
    "worktree /home/u/repo/.wt/pin",
    "HEAD 0123abc0123abc0123abc0123abc0123abc0123",
    "branch refs/heads/pinned",
    "locked working on hotfix",
    "",
    "worktree /home/u/repo/.wt/det",
    "HEAD fedcba9fedcba9fedcba9fedcba9fedcba9fedc",
    "detached",
  ].join("\n");
  assertEquals(parseWorktreePorcelain(out), [
    wt({
      path: "/home/u/repo",
      sha: "abc1234abc1234abc1234abc1234abc1234abc1",
      branch: "main",
    }),
    wt({
      path: "/home/u/repo/.wt/feat",
      sha: "def5678def5678def5678def5678def5678def5",
      branch: "feature-x",
      locked: true,
    }),
    wt({
      path: "/home/u/repo/.wt/pin",
      sha: "0123abc0123abc0123abc0123abc0123abc0123",
      branch: "pinned",
      locked: true,
      lockReason: "working on hotfix",
    }),
    wt({
      path: "/home/u/repo/.wt/det",
      sha: "fedcba9fedcba9fedcba9fedcba9fedcba9fedc",
    }),
  ]);
});

Deno.test("parseWorktreePorcelain は worktree 行の前のゴミを捨てる", () => {
  assertEquals(parseWorktreePorcelain("garbage\nmore garbage"), []);
});

Deno.test("filterTargets は --exclude-main で先頭を除く", () => {
  const wts = [
    wt({ path: "/a", sha: "1", branch: "main" }),
    wt({ path: "/b", sha: "2", branch: "x" }),
  ];
  assertEquals(filterTargets(wts, false), wts);
  assertEquals(filterTargets(wts, true), [
    wt({ path: "/b", sha: "2", branch: "x" }),
  ]);
});

Deno.test("pickDefaultIndex は最長一致の worktree を返す", () => {
  const wts = [
    wt({ path: "/a", sha: "1", branch: "main" }),
    wt({ path: "/a/b", sha: "2", branch: "x" }),
  ];
  // メイン (/a) が先に並んでいても、より深い /a/b を優先する。
  assertEquals(pickDefaultIndex(wts, "/a/b/sub"), 1);
  assertEquals(pickDefaultIndex(wts, "/a/b"), 1);
  assertEquals(pickDefaultIndex(wts, "/a/sub"), 0);
  assertEquals(pickDefaultIndex(wts, "/other"), -1);
  // パス境界を見るため /a は /aa に一致しない。
  assertEquals(pickDefaultIndex(wts, "/aa/sub"), -1);
});

Deno.test("branchLabel はブランチ無しを (detached) にする", () => {
  assertEquals(branchLabel(wt({ path: "/a", branch: "main" })), "[main]");
  assertEquals(branchLabel(wt({ path: "/a" })), "(detached)");
});

Deno.test("lockLabel は lock 状態と理由を表示する", () => {
  assertEquals(lockLabel(wt({ path: "/a" })), "");
  assertEquals(lockLabel(wt({ path: "/a", locked: true })), "locked");
  assertEquals(
    lockLabel(wt({ path: "/a", locked: true, lockReason: "hotfix 作業中" })),
    "locked: hotfix 作業中",
  );
});

Deno.test("padVisible は ANSI を幅に数えず右詰めする", () => {
  assertEquals(padVisible("ab", 5), "ab   ");
  assertEquals(padVisible("\x1b[36mab\x1b[39m", 5), "\x1b[36mab\x1b[39m   ");
  assertEquals(padVisible("toolong", 3), "toolong");
});

Deno.test("computeColumnWidths は最大表示幅を求める", () => {
  const entries: Entry[] = [
    entry({ path: "/a", sha: "1", branch: "main" }),
    entry({
      path: "/b",
      sha: "2",
      branch: "feature",
      relativePath: "wt/feat",
      locked: true,
      lockReason: "keep",
    }),
  ];
  assertEquals(computeColumnWidths(entries), {
    maxPathLen: "wt/feat".length,
    maxBranchLen: "[feature]".length,
    maxLockLen: "locked: keep".length,
  });
});

Deno.test("buildLabel は desc 有無で形を変える", () => {
  const widths = { maxPathLen: 4, maxBranchLen: 6, maxLockLen: 0 };
  const base = entry({
    path: "/a",
    sha: "abc1234abc1234abc1234abc1234abc1234abc1",
    branch: "main",
    relativePath: "wt",
  });
  assertEquals(buildLabel(base, widths, PLAIN), "wt    abc1234 [main]");
  assertEquals(
    buildLabel({ ...base, desc: "作業中" }, widths, PLAIN),
    "wt    abc1234 [main]  # 作業中",
  );
});

Deno.test("buildLabel は lock 列を揃えて表示する", () => {
  const widths = { maxPathLen: 4, maxBranchLen: 6, maxLockLen: 12 };
  const base = entry({
    path: "/a",
    sha: "abc1234abc1234abc1234abc1234abc1234abc1",
    branch: "main",
    relativePath: "wt",
  });
  assertEquals(
    buildLabel(
      { ...base, locked: true, lockReason: "keep" },
      widths,
      PLAIN,
    ),
    "wt    abc1234 [main]  locked: keep",
  );
  // 未 lock 行は lock 列を空白で埋めて desc の位置を揃える。
  assertEquals(
    buildLabel({ ...base, desc: "作業中" }, widths, PLAIN),
    "wt    abc1234 [main]                # 作業中",
  );
  // 未 lock かつ desc 無しは末尾の空白を落とす。
  assertEquals(buildLabel(base, widths, PLAIN), "wt    abc1234 [main]");
});

Deno.test("formatSubject は H1 マーカーと markdown リンクを畳む", () => {
  assertEquals(
    formatSubject(
      "# [#11](https://github.com/ansanloms/dotfiles/pull/11) tmux へ移行する",
    ),
    "#11 tmux へ移行する",
  );
  assertEquals(formatSubject("# チケット無しの作業"), "チケット無しの作業");
  assertEquals(
    formatSubject("旧形式の 1 行 description"),
    "旧形式の 1 行 description",
  );
});

Deno.test("buildLabel は subject の markdown を整形して表示する", () => {
  const widths = { maxPathLen: 4, maxBranchLen: 6, maxLockLen: 0 };
  const base = entry({
    path: "/a",
    sha: "abc1234abc1234abc1234abc1234abc1234abc1",
    branch: "main",
    relativePath: "wt",
  });
  assertEquals(
    buildLabel(
      { ...base, desc: "# [#11](https://example.com/11) 作業中" },
      widths,
      PLAIN,
    ),
    "wt    abc1234 [main]  # #11 作業中",
  );
});

Deno.test("buildFzfLine はパス・ブランチ・ラベルをタブで区切る", () => {
  const widths = { maxPathLen: 4, maxBranchLen: 6, maxLockLen: 0 };
  const e = entry({
    path: "/home/u/repo/.wt/feat",
    sha: "abc1234abc1234abc1234abc1234abc1234abc1",
    branch: "feature",
    relativePath: "wt",
  });
  assertEquals(
    buildFzfLine(e, widths, PLAIN),
    "/home/u/repo/.wt/feat\tfeature\t" + buildLabel(e, widths, PLAIN),
  );
});

Deno.test("buildFzfLine は detached でブランチ欄を空にする", () => {
  const widths = { maxPathLen: 4, maxBranchLen: 10, maxLockLen: 0 };
  const e = entry({
    path: "/home/u/repo/.wt/det",
    sha: "fedcba9fedcba9fedcba9fedcba9fedcba9fedc",
    relativePath: "det",
  });
  assertEquals(
    buildFzfLine(e, widths, PLAIN),
    "/home/u/repo/.wt/det\t\t" + buildLabel(e, widths, PLAIN),
  );
});

Deno.test("selectedPath は先頭フィールドを取り出す", () => {
  assertEquals(selectedPath("/a/b\tfeature\tlabel # desc"), "/a/b");
  assertEquals(selectedPath("/a/b"), "/a/b");
});

const PORCELAIN_TWO = [
  "worktree /home/u/repo",
  "HEAD abc1234abc1234abc1234abc1234abc1234abc1",
  "branch refs/heads/main",
  "",
  "worktree /home/u/repo/.wt/feat",
  "HEAD def5678def5678def5678def5678def5678def5",
  "branch refs/heads/feature",
  "locked",
].join("\n");

function fakeDeps(overrides: Partial<SelectDeps> = {}): {
  deps: SelectDeps;
  errors: string[];
  selected: string[];
  fzfCalls: FzfRequest[];
  descCalls: string[];
} {
  const errors: string[] = [];
  const selected: string[] = [];
  const fzfCalls: FzfRequest[] = [];
  const descCalls: string[] = [];

  const deps: SelectDeps = {
    args: [],
    cwd: () => "/home/u/repo",
    listWorktrees: () => Promise.resolve(PORCELAIN_TWO),
    getDescription: (branch) => {
      descCalls.push(branch);
      return Promise.resolve("");
    },
    runFzf: (req) => {
      fzfCalls.push(req);
      return Promise.resolve({ code: 0, line: req.lines[0] });
    },
    writeSelected: (p) => selected.push(p),
    errorLine: (m) => errors.push(m),
    ...overrides,
  };

  return { deps, errors, selected, fzfCalls, descCalls };
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
    listWorktrees: () =>
      Promise.resolve(
        [
          "worktree /home/u/repo",
          "HEAD abc1234abc1234abc1234abc1234abc1234abc1",
          "branch refs/heads/main",
        ].join("\n"),
      ),
  });
  assertEquals(await run(f.deps), 1);
  assertEquals(f.errors, ["No worktrees to select."]);
});

Deno.test("run: lock された worktree も行に出し選択パスを書く", async () => {
  const f = fakeDeps();
  assertEquals(await run(f.deps), 0);
  assertEquals(f.fzfCalls.length, 1);
  assertEquals(f.fzfCalls[0].lines.map(selectedPath), [
    "/home/u/repo",
    "/home/u/repo/.wt/feat",
  ]);
  assertEquals(f.fzfCalls[0].initialIndex, 0);
  assertEquals(f.fzfCalls[0].previewCommand, PREVIEW_COMMAND);
  assertEquals(f.selected, ["/home/u/repo"]);
});

Deno.test("run: cwd が 2 番目の worktree 配下なら initialIndex は 1", async () => {
  const f = fakeDeps({ cwd: () => "/home/u/repo/.wt/feat/sub" });
  assertEquals(await run(f.deps), 0);
  assertEquals(f.fzfCalls[0].initialIndex, 1);
});

Deno.test("run: fzf が中断 (非 0) なら exit 1 で何も書かない", async () => {
  const f = fakeDeps({
    runFzf: () => Promise.resolve({ code: 130, line: "" }),
  });
  assertEquals(await run(f.deps), 1);
  assertEquals(f.selected, []);
});

Deno.test("run: fzf が code 0 でも空行なら exit 1", async () => {
  const f = fakeDeps({
    runFzf: () => Promise.resolve({ code: 0, line: "" }),
  });
  assertEquals(await run(f.deps), 1);
  assertEquals(f.selected, []);
});

Deno.test("run: detached には getDescription を呼ばない", async () => {
  const f = fakeDeps({
    listWorktrees: () =>
      Promise.resolve(
        [
          "worktree /home/u/repo",
          "HEAD abc1234abc1234abc1234abc1234abc1234abc1",
          "branch refs/heads/main",
          "",
          "worktree /home/u/repo/.wt/det",
          "HEAD fedcba9fedcba9fedcba9fedcba9fedcba9fedc",
          "detached",
        ].join("\n"),
      ),
  });
  assertEquals(await run(f.deps), 0);
  assertEquals(f.descCalls, ["main"]);
});
