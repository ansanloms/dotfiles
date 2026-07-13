// git-worktree-select の純粋ロジックとオーケストレーション。
// 副作用 (git 実行 / 対話プロンプト / cwd / 出力) は SelectDeps として注入する。

import { cyan, green, red, stripAnsiCode, yellow } from "@std/fmt/colors";
import { relative } from "@std/path";
import { unicodeWidth } from "@std/cli/unicode-width";

export interface Worktree {
  path: string;
  sha: string;
  /** refs/heads/ を剥いだブランチ名。detached / bare は空文字。 */
  branch: string;
  locked: boolean;
  /** lock 理由。理由なしの lock や未 lock は空文字。 */
  lockReason: string;
}

export interface Entry extends Worktree {
  relativePath: string;
  desc: string;
}

export interface ColumnWidths {
  maxPathLen: number;
  maxBranchLen: number;
  maxLockLen: number;
}

export interface Colors {
  path: (s: string) => string;
  branch: (s: string) => string;
  lock: (s: string) => string;
  desc: (s: string) => string;
}

/**
 * `git worktree list --porcelain` の出力をパースする。
 * 人間向け出力と違い locked / prunable 等の注記で行の形が揺れないため、
 * lock された worktree も漏れなく拾える。
 */
export function parseWorktreePorcelain(output: string): Worktree[] {
  const worktrees: Worktree[] = [];
  let current: Worktree | undefined;
  for (const line of output.split("\n")) {
    if (line.startsWith("worktree ")) {
      current = {
        path: line.slice("worktree ".length),
        sha: "",
        branch: "",
        locked: false,
        lockReason: "",
      };
      worktrees.push(current);
      continue;
    }
    if (!current) {
      continue;
    }
    if (line.startsWith("HEAD ")) {
      current.sha = line.slice("HEAD ".length);
    } else if (line.startsWith("branch ")) {
      current.branch = line.slice("branch ".length).replace(
        /^refs\/heads\//,
        "",
      );
    } else if (line === "locked") {
      current.locked = true;
    } else if (line.startsWith("locked ")) {
      current.locked = true;
      current.lockReason = line.slice("locked ".length);
    }
  }
  return worktrees;
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

/** branch 列の表示文字列。ブランチを持たない worktree は (detached) とする。 */
export function branchLabel(wt: Worktree): string {
  return wt.branch ? `[${wt.branch}]` : "(detached)";
}

/** lock 列の表示文字列。未 lock は空文字。 */
export function lockLabel(wt: Worktree): string {
  if (!wt.locked) {
    return "";
  }
  return wt.lockReason ? `locked: ${wt.lockReason}` : "locked";
}

/** 表示幅で右側を空白パディングする (ANSI エスケープは幅に数えない)。 */
export function padVisible(str: string, width: number): string {
  const visible = unicodeWidth(stripAnsiCode(str));
  return str + " ".repeat(Math.max(0, width - visible));
}

/** path 列・branch 列・lock 列の最大表示幅を求める。 */
export function computeColumnWidths(entries: Entry[]): ColumnWidths {
  return {
    maxPathLen: Math.max(
      0,
      ...entries.map((e) => unicodeWidth(e.relativePath)),
    ),
    maxBranchLen: Math.max(
      0,
      ...entries.map((e) => unicodeWidth(branchLabel(e))),
    ),
    maxLockLen: Math.max(0, ...entries.map((e) => unicodeWidth(lockLabel(e)))),
  };
}

/** 1 エントリの選択肢ラベルを組み立てる。lock された worktree が無ければ lock 列は出さない。 */
export function buildLabel(
  entry: Entry,
  widths: ColumnWidths,
  colors: Colors,
): string {
  const path = padVisible(colors.path(entry.relativePath), widths.maxPathLen);
  const branch = padVisible(
    colors.branch(branchLabel(entry)),
    widths.maxBranchLen,
  );
  let label = `${path}  ${entry.sha.slice(0, 7)} ${branch}`;
  if (widths.maxLockLen > 0) {
    const lock = lockLabel(entry);
    label += `  ${padVisible(lock ? colors.lock(lock) : "", widths.maxLockLen)}`;
  }
  if (entry.desc) {
    label += `  ${colors.desc("# " + entry.desc)}`;
  }
  return label.trimEnd();
}

const COLORS: Colors = { path: cyan, branch: green, lock: red, desc: yellow };

export interface SelectOptions {
  message: string;
  options: Array<{ name: string; value: string }>;
  default?: string;
}

export interface SelectDeps {
  args: string[];
  cwd(): string;
  /** `git worktree list --porcelain` の出力を返す。 */
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

  const worktrees = parseWorktreePorcelain(output);
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
      desc: wt.branch ? await deps.getDescription(wt.branch) : "",
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
