import type {
  PreToolUseHookInput,
  PreToolUseHookSpecificOutput,
} from "@anthropic-ai/claude-agent-sdk";

export const DEFAULT_SUBAGENT_MODEL = "opus";

export interface SubagentModelDecision {
  hookSpecificOutput: PreToolUseHookSpecificOutput;
}

/**
 * Agent ツール呼び出しに model を補うかを判定する。
 * 補う場合は hook の出力 JSON をそのまま返し、補わない場合は null を返す。
 * pinnedTypes: frontmatter に `model:` を持つ agent 名の集合 (この種別には補わない)。
 */
export const decide = (
  input: PreToolUseHookInput,
  pinnedTypes: ReadonlySet<string>,
  defaultModel: string = DEFAULT_SUBAGENT_MODEL,
): SubagentModelDecision | null => {
  if (input.tool_name !== "Agent") {
    return null;
  }

  const toolInput = input.tool_input;
  if (typeof toolInput !== "object" || toolInput === null) {
    return null;
  }

  const record = toolInput as Record<string, unknown>;

  if (typeof record.model === "string" && record.model !== "") {
    return null;
  }

  if (record.subagent_type === "fork") {
    return null;
  }

  if (
    typeof record.subagent_type === "string" &&
    pinnedTypes.has(record.subagent_type)
  ) {
    return null;
  }

  return {
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      updatedInput: { ...record, model: defaultModel },
    },
  };
};

/**
 * agent 定義 markdown の frontmatter に `model:` 行があるかを判定する。
 * frontmatter = 先頭行が `---` で始まり、次の `---` 行までの範囲。その範囲内の行頭 `model:` のみを見る。
 */
export const hasPinnedModel = (markdown: string): boolean => {
  const lines = markdown.split(/\r?\n/);

  if (lines[0] !== "---") {
    return false;
  }

  const endIndex = lines.indexOf("---", 1);
  if (endIndex === -1) {
    return false;
  }

  const frontmatter = lines.slice(1, endIndex);
  return frontmatter.some((line) => line.startsWith("model:"));
};
