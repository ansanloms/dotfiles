import * as path from "@std/path";

// セッションごとの「作業中 worktree」を記録する state ディレクトリ。
// このモジュール（scripts/utils/）からの相対で scripts/.state/worktree/ を指す。
const stateDir = path.fromFileUrl(
  new URL("../.state/worktree/", import.meta.url),
);

const stateFile = (sessionId: string): string =>
  path.join(stateDir, `${encodeURIComponent(sessionId)}.json`);

/**
 * セッションが作業中の worktree ルートを記録する。
 */
export const recordWorktree = async (
  sessionId: string,
  root: string,
): Promise<void> => {
  await Deno.mkdir(stateDir, { recursive: true });
  await Deno.writeTextFile(stateFile(sessionId), JSON.stringify({ root }));
};

/**
 * セッションに記録された worktree ルートを返す。未記録・破損時は null。
 */
export const readWorktree = async (
  sessionId: string,
): Promise<string | null> => {
  try {
    const data = JSON.parse(await Deno.readTextFile(stateFile(sessionId))) as {
      root?: unknown;
    };
    return typeof data.root === "string" ? data.root : null;
  } catch {
    return null;
  }
};

/**
 * セッションの記録を削除する。無ければ何もしない。
 */
export const clearWorktree = async (sessionId: string): Promise<void> => {
  try {
    await Deno.remove(stateFile(sessionId));
  } catch {
    // 既に無い場合は無視する。
  }
};
