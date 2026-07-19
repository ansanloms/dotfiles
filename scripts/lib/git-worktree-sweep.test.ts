import { assertEquals } from "@std/assert";
import {
  type GitResult,
  isFullyContained,
  isMergedAsParent,
  isSweepTarget,
  parseWorktreeList,
  run,
  type SweepDeps,
} from "./git-worktree-sweep.ts";

Deno.test("parseWorktreeList は main と worktree 群を分離しブランチ名を取り出す", () => {
  const out = [
    "worktree /home/u/repo",
    "HEAD abc",
    "branch refs/heads/main",
    "",
    "worktree /home/u/repo/.claude/worktrees/feat-a",
    "HEAD def",
    "branch refs/heads/feat/a",
    "",
    "worktree /home/u/repo/.claude/worktrees/detached",
    "HEAD ghi",
    "detached",
  ].join("\n");
  assertEquals(parseWorktreeList(out), {
    mainWt: "/home/u/repo",
    entries: [
      { path: "/home/u/repo/.claude/worktrees/feat-a", branch: "feat/a" },
      { path: "/home/u/repo/.claude/worktrees/detached", branch: null },
    ],
  });
});

Deno.test("isSweepTarget は .claude/worktrees/ 配下のみ対象にする", () => {
  const main = "/home/u/repo";
  assertEquals(isSweepTarget(`${main}/.claude/worktrees/x`, main), true);
  assertEquals(isSweepTarget("/home/u/other-worktree", main), false);
  assertEquals(isSweepTarget(`${main}/sub/dir`, main), false);
});

Deno.test("isFullyContained は全行が - のときのみ true", () => {
  assertEquals(isFullyContained("- abc\n- def\n"), true);
  assertEquals(isFullyContained("- abc\n+ def\n"), false);
  assertEquals(isFullyContained("+ abc\n"), false);
  assertEquals(isFullyContained(""), true);
});

Deno.test("isMergedAsParent は第 2 親以降の出現のみ merge とみなす", () => {
  // 第 2 親として出現 → merge commit でマージ済み
  assertEquals(isMergedAsParent("aaa tip00\nbbb\n", "tip00"), true);
  // 第 1 親としての出現は直列の履歴でも起こるため merge の証拠にならない
  assertEquals(isMergedAsParent("tip00 other\nbbb\n", "tip00"), false);
  assertEquals(isMergedAsParent("tip00\nbbb\n", "tip00"), false);
  assertEquals(isMergedAsParent("", "tip00"), false);
});

/** テスト用の SweepDeps。git 呼び出しを応答表で模倣する。 */
function makeDeps(
  responses: Record<string, GitResult>,
  args: string[] = [],
): { deps: SweepDeps; calls: string[]; logs: string[]; errors: string[] } {
  const calls: string[] = [];
  const logs: string[] = [];
  const errors: string[] = [];
  const ok = (stdout = ""): GitResult => ({
    success: true,
    stdout,
    stderr: "",
  });
  const deps: SweepDeps = {
    args,
    runGit: (gitArgs) => {
      const key = gitArgs.join(" ");
      calls.push(key);
      return Promise.resolve(responses[key] ?? ok());
    },
    log: (msg) => logs.push(msg),
    errorLog: (msg) => errors.push(msg),
  };
  return { deps, calls, logs, errors };
}

const porcelain = [
  "worktree /repo",
  "branch refs/heads/main",
  "",
  "worktree /repo/.claude/worktrees/done",
  "branch refs/heads/feat/done",
].join("\n");

const ok = (stdout = ""): GitResult => ({ success: true, stdout, stderr: "" });

// squash merge 済みクリーン worktree を表す応答表。
const squashMergedResponses: Record<string, GitResult> = {
  "worktree list --porcelain": ok(porcelain),
  "symbolic-ref --short refs/remotes/origin/HEAD": ok("origin/main\n"),
  "-C /repo/.claude/worktrees/done status --porcelain": ok(""),
  "rev-list --count origin/main..feat/done": ok("1\n"),
  "merge-base origin/main feat/done": ok("base00\n"),
  "rev-parse feat/done^{tree}": ok("tree00\n"),
  "commit-tree tree00 -p base00 -m git-worktree-sweep: squash merge check": ok(
    "tmp000\n",
  ),
  "cherry origin/main tmp000": ok("- tmp000\n"),
};

Deno.test("run は squash merge 済みクリーン worktree を削除しブランチも消す", async () => {
  const { deps, calls, logs } = makeDeps({ ...squashMergedResponses });
  const code = await run(deps);
  assertEquals(code, 0);
  assertEquals(
    calls.includes("worktree remove --force /repo/.claude/worktrees/done"),
    true,
  );
  assertEquals(calls.includes("branch -D feat/done"), true);
  assertEquals(calls.includes("worktree prune"), true);
  assertEquals(
    logs.some((l) => l.startsWith("Removed: /repo/.claude/worktrees/done")),
    true,
  );
});

Deno.test("run は --dry-run では削除しない", async () => {
  const { deps, calls, logs } = makeDeps({ ...squashMergedResponses }, [
    "--dry-run",
  ]);
  const code = await run(deps);
  assertEquals(code, 0);
  assertEquals(
    calls.some((c) => c.startsWith("worktree remove")),
    false,
  );
  assertEquals(calls.includes("worktree prune"), false);
  assertEquals(
    logs.some((l) => l.startsWith("Would remove:")),
    true,
  );
});

Deno.test("run は merge commit でマージ済み (固有コミット無し) も削除する", async () => {
  const { deps, calls } = makeDeps({
    ...squashMergedResponses,
    "rev-list --count origin/main..feat/done": ok("0\n"),
    "rev-parse feat/done": ok("tip00\n"),
    "log --format=%P origin/main ^feat/done": ok("aaa tip00\nbbb\n"),
  });
  const code = await run(deps);
  assertEquals(code, 0);
  assertEquals(
    calls.includes("worktree remove --force /repo/.claude/worktrees/done"),
    true,
  );
});

Deno.test("run はコミット未着手の worktree を残す", async () => {
  const { deps, calls, logs } = makeDeps({
    ...squashMergedResponses,
    "rev-list --count origin/main..feat/done": ok("0\n"),
    "rev-parse feat/done": ok("tip00\n"),
    // tip は第 1 親としてしか現れない (= main の履歴上の通常 commit)
    "log --format=%P origin/main ^feat/done": ok("tip00\nbbb\n"),
  });
  const code = await run(deps);
  assertEquals(code, 0);
  assertEquals(
    calls.some((c) => c.startsWith("worktree remove")),
    false,
  );
  assertEquals(
    logs.some((l) => l.startsWith("Kept (no commits on branch yet):")),
    true,
  );
});

Deno.test("run は dirty な worktree を残す", async () => {
  const { deps, calls, logs } = makeDeps({
    ...squashMergedResponses,
    "-C /repo/.claude/worktrees/done status --porcelain": ok(" M file.ts\n"),
  });
  const code = await run(deps);
  assertEquals(code, 0);
  assertEquals(
    calls.some((c) => c.startsWith("worktree remove")),
    false,
  );
  assertEquals(
    logs.some((l) => l.startsWith("Kept (merged but dirty):")),
    true,
  );
});

Deno.test("run は未マージの worktree を残す", async () => {
  const { deps, calls, logs } = makeDeps({
    ...squashMergedResponses,
    "cherry origin/main tmp000": ok("+ tmp000\n"),
  });
  const code = await run(deps);
  assertEquals(code, 0);
  assertEquals(
    calls.some((c) => c.startsWith("worktree remove")),
    false,
  );
  assertEquals(
    logs.some((l) => l.startsWith("Kept (not merged")),
    true,
  );
});

Deno.test("run は対象が無ければ何もしない", async () => {
  const { deps, calls, logs } = makeDeps({
    "worktree list --porcelain": ok("worktree /repo\nbranch refs/heads/main\n"),
  });
  const code = await run(deps);
  assertEquals(code, 0);
  assertEquals(calls.length, 1);
  assertEquals(logs, ["No worktrees under .claude/worktrees/"]);
});
