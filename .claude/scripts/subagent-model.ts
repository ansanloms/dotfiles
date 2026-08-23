import type { PreToolUseHookInput } from "@anthropic-ai/claude-agent-sdk";
import { getInput } from "./utils/common.ts";
import { decide, pinnedAgentName } from "./utils/subagent-model.ts";

/**
 * 指定ディレクトリの直下にある agent 定義 (*.md) のうち、
 * frontmatter に `model:` を持つものの名前 (frontmatter の `name:`。無ければファイル名から拡張子を除いたもの) を集める。
 * ディレクトリが無ければ空集合を返す。
 */
const collectPinnedTypes = async (dir: string): Promise<Set<string>> => {
  const pinned = new Set<string>();

  let entries: Deno.DirEntry[];
  try {
    entries = await Array.fromAsync(Deno.readDir(dir));
  } catch {
    return pinned;
  }

  for (const entry of entries) {
    if (
      !(entry.isFile || entry.isSymlink) || !entry.name.endsWith(".md")
    ) {
      continue;
    }

    let content: string;
    try {
      content = await Deno.readTextFile(`${dir}/${entry.name}`);
    } catch (error) {
      console.error(`subagent-model: failed to read ${entry.name}:`, error);
      continue;
    }

    const name = pinnedAgentName(content, entry.name.replace(/\.md$/, ""));
    if (name !== null) {
      pinned.add(name);
    }
  }

  return pinned;
};

try {
  const input = await getInput<PreToolUseHookInput>();

  const home = Deno.env.get("HOME") ?? "";
  const [homePinned, cwdPinned] = await Promise.all([
    collectPinnedTypes(`${home}/.claude/agents`),
    collectPinnedTypes(`${input.cwd}/.claude/agents`),
  ]);
  const pinned = new Set([...homePinned, ...cwdPinned]);

  // `updatedInput` は `permissionDecision` を省略したときだけ適用される (Claude Code 2.1.240 の実装で確認)。
  // `permissionDecision: "allow"` を付けると書き換えが無効になるので付けない。
  const result = decide(input, pinned);
  if (result) {
    console.log(JSON.stringify(result));
  }
} catch (error) {
  console.error("subagent-model error:", error);
}
