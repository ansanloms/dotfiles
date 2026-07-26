import { unicodeWidth } from "@std/cli";
import { red, yellow } from "@std/fmt/colors";
import { formatCompact, getInput } from "./utils/common.ts";
import type { SubagentStatusLineInput, SubagentTask } from "./types.ts";

/**
 * モデル ID を短縮表示名にする。
 * 先頭の "claude-" と末尾の日付サフィックス (例: "-20251001") を除去する。
 * 例: "claude-sonnet-5" -> "sonnet-5"、"claude-haiku-4-5-20251001" -> "haiku-4-5"
 */
export const shortenModelId = (id: string): string =>
  id.replace(/^claude-/, "").replace(/-\d{8}$/, "");

/**
 * トークン使用率 (0-100 目安、上限なし) を計算する。
 * contextWindowSize が 0 以下の場合は undefined を返す。
 */
const calcTokenPct = (tokenCount: number, contextWindowSize: number) =>
  contextWindowSize > 0
    ? Math.floor(tokenCount / contextWindowSize * 100)
    : undefined;

/**
 * パーセンテージに応じて文字列を着色する。
 * 90% 以上: 赤、70% 以上: 黄、それ以外は無着色。
 */
const colorizePct = (pct: number, s: string): string =>
  pct >= 90 ? red(s) : pct >= 70 ? yellow(s) : s;

/**
 * task の行本文 (プレーン、色なし) を組み立てる。
 * トークン使用率部分は別途返し、呼び出し側で着色して合成する。
 */
const buildPlainLine = (
  task: SubagentTask & { model: string },
): { prefix: string; tokenPart?: { pct: number; text: string } } => {
  const parts = [`${shortenModelId(task.model)}`];
  if (task.effort !== undefined) {
    parts[0] += ` (${task.effort})`;
  }

  let prefix = `󰚩  ${parts[0]} | ${task.name}`;
  if (task.description) {
    prefix += `: ${task.description}`;
  }

  if (
    task.tokenCount !== undefined &&
    task.contextWindowSize !== undefined
  ) {
    const pct = calcTokenPct(task.tokenCount, task.contextWindowSize);
    if (pct !== undefined) {
      const text = `${pct}% (${formatCompact(task.tokenCount)})`;
      return { prefix, tokenPart: { pct, text } };
    }
  }

  return { prefix };
};

/**
 * 表示幅 (unicodeWidth ベース) が columns を超える場合、末尾を "..." で切り詰める。
 * ANSI エスケープを含まないプレーン文字列に対して行うこと。
 */
export const truncateToWidth = (s: string, columns: number): string => {
  if (unicodeWidth(s) <= columns) {
    return s;
  }

  const ellipsis = "...";
  const ellipsisWidth = unicodeWidth(ellipsis);
  if (columns <= ellipsisWidth) {
    // 幅が "..." 自体にも満たない場合は素朴に 1 文字ずつ削って収める。
    let result = "";
    for (const ch of s) {
      if (unicodeWidth(result + ch) > columns) {
        break;
      }
      result += ch;
    }
    return result;
  }

  let result = "";
  for (const ch of s) {
    if (unicodeWidth(result + ch) > columns - ellipsisWidth) {
      break;
    }
    result += ch;
  }
  return result + ellipsis;
};

/**
 * task 1 件分の行本文 (色付き・切り詰め済み) を組み立てる。
 */
export const buildTaskLine = (
  task: SubagentTask & { model: string },
  columns: number,
): string => {
  const { prefix, tokenPart } = buildPlainLine(task);
  const plain = tokenPart ? `${prefix} | ${tokenPart.text}` : prefix;
  const truncated = truncateToWidth(plain, columns);

  if (!tokenPart) {
    return truncated;
  }

  // 色付けは切り詰め後、プレーン文字列同士の位置関係を使って行う。
  // tokenPart.text が切り詰めで欠けている場合は着色しない。
  if (truncated.endsWith(tokenPart.text)) {
    const head = truncated.slice(0, truncated.length - tokenPart.text.length);
    return head + colorizePct(tokenPart.pct, tokenPart.text);
  }

  return truncated;
};

/**
 * model が解決済みの task だけを抽出する。
 * model 未解決の task は既定表示 (name / description / token count) に任せる。
 */
export const selectResolvedTasks = (
  tasks: SubagentTask[],
): (SubagentTask & { model: string })[] =>
  tasks.filter((task): task is SubagentTask & { model: string } =>
    typeof task.id === "string" &&
    typeof task.name === "string" &&
    typeof task.model === "string"
  );

if (import.meta.main) {
  try {
    const input = await getInput<SubagentStatusLineInput>();

    if (typeof input.columns !== "number" || input.columns <= 0) {
      // columns が不正な場合は一切出力せず正常終了する。
      // 空 content の出力は行の非表示を意味してしまうため、
      // パネル幅の過渡状態で行が意図せず消えるのを避ける。
    } else {
      for (const task of selectResolvedTasks(input.tasks)) {
        const content = buildTaskLine(task, input.columns);
        console.log(JSON.stringify({ id: task.id, content }));
      }
    }
  } catch {
    // 入力パース失敗・想定外構造の場合は何も出力せず正常終了する。
    // id を出さなかった行は Claude Code 既定表示にフォールバックするため安全側。
  }
}
