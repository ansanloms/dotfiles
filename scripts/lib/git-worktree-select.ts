// git-worktree-select の純粋ロジックとオーケストレーション。
// 副作用 (git 実行 / 対話プロンプト / cwd / 出力) は SelectDeps として注入する。

import { cyan, green, stripAnsiCode, yellow } from "@std/fmt/colors";
import { relative } from "@std/path";
import { unicodeWidth } from "@std/cli/unicode-width";

export interface Worktree {
  path: string;
  sha: string;
  branch: string;
}

export interface Entry extends Worktree {
  relativePath: string;
  desc: string;
}

export interface ColumnWidths {
  maxPathLen: number;
  maxBranchLen: number;
}

export interface Colors {
  path: (s: string) => string;
  branch: (s: string) => string;
  desc: (s: string) => string;
}

/** `git worktree list` の出力をパースする。マッチしない行は捨てる。 */
export function parseWorktreeList(output: string): Worktree[] {
  return output.split("\n").map((line) => {
    const match = line.match(/^(\S+)\s+(\S+)\s+\[(.+)\]$/);
    if (!match) {
      return null;
    }
    return { path: match[1], sha: match[2], branch: match[3] };
  }).filter((v) => v !== null);
}

/** --exclude-main 指定時は先頭 (メインワークツリー) を除く。 */
export function filterTargets(
  worktrees: Worktree[],
  excludeMain: boolean,
): Worktree[] {
  return excludeMain ? worktrees.slice(1) : worktrees;
}

/** cwd を含む worktree のパスをデフォルト選択として返す。 */
export function pickDefault(
  targets: Worktree[],
  cwd: string,
): string | undefined {
  return targets.find((wt) => cwd.startsWith(wt.path))?.path;
}

/** 表示幅で右側を空白パディングする (ANSI エスケープは幅に数えない)。 */
export function padVisible(str: string, width: number): string {
  const visible = unicodeWidth(stripAnsiCode(str));
  return str + " ".repeat(Math.max(0, width - visible));
}

/** path 列・branch 列の最大表示幅を求める。 */
export function computeColumnWidths(entries: Entry[]): ColumnWidths {
  return {
    maxPathLen: Math.max(
      0,
      ...entries.map((e) => unicodeWidth(e.relativePath)),
    ),
    maxBranchLen: Math.max(
      0,
      ...entries.map((e) => unicodeWidth(`[${e.branch}]`)),
    ),
  };
}

/** 1 エントリの選択肢ラベルを組み立てる。 */
export function buildLabel(
  entry: Entry,
  widths: ColumnWidths,
  colors: Colors,
): string {
  const path = padVisible(colors.path(entry.relativePath), widths.maxPathLen);
  const branch = padVisible(
    colors.branch(`[${entry.branch}]`),
    widths.maxBranchLen,
  );
  return entry.desc
    ? `${path}  ${entry.sha} ${branch}  ${colors.desc("# " + entry.desc)}`
    : `${path}  ${entry.sha} ${branch}`;
}

const COLORS: Colors = { path: cyan, branch: green, desc: yellow };

export interface SelectOptions {
  message: string;
  options: Array<{ name: string; value: string }>;
  default?: string;
}

export interface SelectDeps {
  args: string[];
  cwd(): string;
  listWorktrees(): Promise<string>;
  getDescription(branch: string): Promise<string>;
  select(opts: SelectOptions): Promise<string>;
  writeSelected(path: string): void;
  errorLine(msg: string): void;
}

/** worktree を対話選択し、選んだパスを stderr へ書く。終了コードを返す。 */
export async function run(deps: SelectDeps): Promise<number> {
  const output = (await deps.listWorktrees()).trim();
  if (!output) {
    deps.errorLine("No worktrees found.");
    return 1;
  }

  const worktrees = parseWorktreeList(output);
  if (worktrees.length === 0) {
    deps.errorLine("No worktrees found.");
    return 1;
  }

  const mainPath = worktrees[0].path;
  const excludeMain = deps.args.includes("--exclude-main");
  const targets = filterTargets(worktrees, excludeMain);
  if (targets.length === 0) {
    deps.errorLine("No worktrees to select.");
    return 1;
  }

  const entries: Entry[] = await Promise.all(
    targets.map(async (wt) => ({
      ...wt,
      relativePath: relative(mainPath, wt.path) || ".",
      desc: await deps.getDescription(wt.branch),
    })),
  );

  const widths = computeColumnWidths(entries);

  const selected = await deps.select({
    message: "Select worktree",
    options: entries.map((e) => ({
      name: buildLabel(e, widths, COLORS),
      value: e.path,
    })),
    default: pickDefault(targets, deps.cwd()),
  });

  deps.writeSelected(selected);
  return 0;
}
