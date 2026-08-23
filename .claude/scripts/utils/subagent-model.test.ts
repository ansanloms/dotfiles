import { assertEquals } from "@std/assert";
import type { PreToolUseHookInput } from "@anthropic-ai/claude-agent-sdk";
import { decide, hasPinnedModel } from "./subagent-model.ts";

/**
 * テスト用の最小 PreToolUseHookInput を作る。
 */
const makeInput = (
  toolName: string,
  toolInput: unknown,
): PreToolUseHookInput => ({
  session_id: "test-session",
  transcript_path: "",
  cwd: "/tmp",
  hook_event_name: "PreToolUse",
  tool_name: toolName,
  tool_input: toolInput,
  tool_use_id: "tool-use-1",
});

// --- decide ---

Deno.test("decide: Agent ツール以外は null を返す", () => {
  const input = makeInput("Bash", { command: "ls" });
  assertEquals(decide(input, new Set()), null);
});

Deno.test("decide: tool_input がオブジェクトでなければ null を返す", () => {
  const input = makeInput("Agent", "not-an-object");
  assertEquals(decide(input, new Set()), null);
});

Deno.test("decide: model が空でない文字列で指定済みなら null を返す", () => {
  const input = makeInput("Agent", {
    subagent_type: "general-purpose",
    model: "sonnet",
    prompt: "x",
    description: "d",
  });
  assertEquals(decide(input, new Set()), null);
});

Deno.test("decide: subagent_type が fork なら null を返す", () => {
  const input = makeInput("Agent", {
    subagent_type: "fork",
    prompt: "x",
    description: "d",
  });
  assertEquals(decide(input, new Set()), null);
});

Deno.test("decide: subagent_type が pinnedTypes に含まれるなら null を返す", () => {
  const input = makeInput("Agent", {
    subagent_type: "implementer",
    prompt: "x",
    description: "d",
  });
  assertEquals(decide(input, new Set(["implementer"])), null);
});

Deno.test("decide: 対象外に該当しなければ model を補って返す", () => {
  const input = makeInput("Agent", {
    subagent_type: "general-purpose",
    prompt: "調査してほしい",
    description: "調査タスク",
    isolation: "worktree",
  });
  const result = decide(input, new Set(["implementer"]));
  assertEquals(result, {
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      updatedInput: {
        subagent_type: "general-purpose",
        prompt: "調査してほしい",
        description: "調査タスク",
        isolation: "worktree",
        model: "opus",
      },
    },
  });
});

Deno.test("decide: subagent_type 未指定でも model を補って返す", () => {
  const input = makeInput("Agent", {
    prompt: "x",
    description: "d",
  });
  const result = decide(input, new Set(["implementer"]));
  assertEquals(result?.hookSpecificOutput.updatedInput?.model, "opus");
});

// --- hasPinnedModel ---

Deno.test("hasPinnedModel: frontmatter に model: があれば true を返す", () => {
  const markdown = [
    "---",
    "name: implementer",
    "model: sonnet",
    "---",
    "",
    "本文",
  ].join("\n");
  assertEquals(hasPinnedModel(markdown), true);
});

Deno.test("hasPinnedModel: frontmatter が無ければ false を返す", () => {
  const markdown = "# タイトル\n\nmodel: sonnet\n";
  assertEquals(hasPinnedModel(markdown), false);
});

Deno.test("hasPinnedModel: frontmatter 外の model: は無視して false を返す", () => {
  const markdown = [
    "---",
    "name: research-worker",
    "---",
    "",
    "本文中に model: sonnet と書いてある",
  ].join("\n");
  assertEquals(hasPinnedModel(markdown), false);
});

Deno.test("hasPinnedModel: frontmatter に model: が無ければ false を返す", () => {
  const markdown = [
    "---",
    "name: research-worker",
    "description: 調査用",
    "---",
    "",
    "本文",
  ].join("\n");
  assertEquals(hasPinnedModel(markdown), false);
});
