import { assertEquals } from "@std/assert";
import { parseWorktreeAddPath } from "./worktree-state.ts";
import {
  clearWorktree,
  readWorktree,
  recordWorktree,
} from "./utils/worktree.ts";

Deno.test("parseWorktreeAddPath: path then new branch flag", () => {
  assertEquals(
    parseWorktreeAddPath("git worktree add /base/foo -b feat/foo"),
    "/base/foo",
  );
});

Deno.test("parseWorktreeAddPath: new branch flag then path", () => {
  assertEquals(
    parseWorktreeAddPath("git worktree add -b feat/foo /base/foo"),
    "/base/foo",
  );
});

Deno.test("parseWorktreeAddPath: existing branch positional", () => {
  assertEquals(
    parseWorktreeAddPath("git worktree add /base/bar existing-branch"),
    "/base/bar",
  );
});

Deno.test("parseWorktreeAddPath: leading -C and value flag", () => {
  assertEquals(
    parseWorktreeAddPath("git -C /repo worktree add --quiet /base/baz"),
    "/base/baz",
  );
});

Deno.test("parseWorktreeAddPath: quoted path with space", () => {
  assertEquals(
    parseWorktreeAddPath('git worktree add "/base/with space" -b x'),
    "/base/with space",
  );
});

Deno.test("parseWorktreeAddPath: not an add command", () => {
  assertEquals(parseWorktreeAddPath("git worktree list"), null);
});

Deno.test("worktree state store round-trip", async () => {
  const sessionId = `test-${crypto.randomUUID()}`;
  try {
    assertEquals(await readWorktree(sessionId), null);
    await recordWorktree(sessionId, "/some/worktree/root");
    assertEquals(await readWorktree(sessionId), "/some/worktree/root");
  } finally {
    await clearWorktree(sessionId);
  }
  assertEquals(await readWorktree(sessionId), null);
});
