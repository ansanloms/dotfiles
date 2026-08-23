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
    if (!entry.isFile || !entry.name.endsWith(".md")) {
      continue;
    }

    const content = await Deno.readTextFile(`${dir}/${entry.name}`);
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

  const result = decide(input, pinned);
  if (result) {
    console.log(JSON.stringify(result));
  }
} catch (error) {
  console.error("subagent-model error:", error);
}
