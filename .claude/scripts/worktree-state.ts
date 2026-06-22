import * as path from "@std/path";
import { getInput } from "./utils/common.ts";
import * as git from "./utils/git.ts";
import { clearWorktree, recordWorktree } from "./utils/worktree.ts";
import type { WorktreeStateHookInput } from "./types.ts";

/**
 * `git worktree add <path> ...` から作成先 path を best-effort で抜く。
 * 最初の非フラグ位置引数を path とみなす。抽出できなければ null。
 */
export const parseWorktreeAddPath = (command: string): string | null => {
  const matched = command.match(/\bworktree\s+add\b([^\n]*)/);
  if (matched === null) {
    return null;
  }
  const tokens = matched[1].match(/"[^"]*"|'[^']*'|\S+/g) ?? [];
  // 値を取るフラグ。直後のトークンは path ではないのでスキップする。
  const flagsWithValue = new Set(["-b", "-B", "--reason", "--lock-reason"]);
  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i];
    if (token.startsWith("-")) {
      if (flagsWithValue.has(token)) {
        i++;
      }
      continue;
    }
    return token.replace(/^["']|["']$/g, "");
  }
  return null;
};

/**
 * 対象パスから linked worktree を解決し、見つかればセッションに記録する。
 */
const recordIfWorktree = async (
  sessionId: string,
  target: string,
): Promise<void> => {
  const root = await git.linkedWorktreeRoot(target);
  if (root !== null) {
    await recordWorktree(sessionId, root);
  }
};

const main = async (): Promise<void> => {
  const input = await getInput<WorktreeStateHookInput>();

  if (input.hook_event_name === "SessionEnd") {
    // セッション終了時に記録を掃除する。
    await clearWorktree(input.session_id);
    return;
  }

  if (input.hook_event_name === "PostToolUse") {
    const filePath = input.tool_input?.file_path ??
      input.tool_input?.notebook_path;
    if (typeof filePath === "string") {
      // Edit / Write 系: 編集対象ファイルが属する worktree を記録する。
      await recordIfWorktree(input.session_id, filePath);
      return;
    }

    if (input.tool_name === "Bash") {
      const command = input.tool_input?.command;
      // `git worktree add` の瞬間を捕捉する（初回編集前・read-only worktree 対策）。
      if (typeof command === "string" && command.includes("worktree add")) {
        const added = parseWorktreeAddPath(command);
        if (added !== null) {
          await recordIfWorktree(
            input.session_id,
            path.resolve(input.cwd, added),
          );
        }
      }
    }
  }
};

if (import.meta.main) {
  try {
    await main();
  } catch {
    // hook はツール実行を止めない。あらゆる失敗を握り潰す。
    Deno.exit(0);
  }
}
