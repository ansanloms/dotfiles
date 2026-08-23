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
 * agent 定義 markdown の frontmatter を読み、`model:` を持つ場合にその agent 名を返す。
 * 名前は frontmatter の `name:` の値 (前後の空白を除去) を使い、無ければ fallbackName を使う。
 * frontmatter が無い、または `model:` が無い場合は null。
 * frontmatter = 先頭行が `---` で始まり、次の `---` 行までの範囲。行頭の `name:` / `model:` のみを見る。
 */
export const pinnedAgentName = (
  markdown: string,
  fallbackName: string,
): string | null => {
  const lines = markdown.split(/\r?\n/);

  if (lines[0] !== "---") {
    return null;
  }

  const endIndex = lines.indexOf("---", 1);
  if (endIndex === -1) {
    return null;
  }

  const frontmatter = lines.slice(1, endIndex);

  if (!frontmatter.some((line) => line.startsWith("model:"))) {
    return null;
  }

  const nameLine = frontmatter.find((line) => line.startsWith("name:"));
  if (nameLine === undefined) {
    return fallbackName;
  }

  const name = nameLine.slice("name:".length).trim();
  return name === "" ? fallbackName : name;
};
