// git-worktree-select の純粋ロジックとオーケストレーション。
// 副作用 (git 実行 / fzf 起動 / cwd / 出力) は SelectDeps として注入する。

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
  /** branch description の先頭 1 行 (subject)。 */
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

/**
 * cwd を含む worktree の位置 (0 始まり) を返す。無ければ -1。
 * worktree をメイン配下 (例: <main>/.claude/worktrees/) に置く構成では
 * メインのパスも常に前方一致するため、最長一致で最も深い worktree を選ぶ。
 * パス境界 ("/") を見ない単純な startsWith だと /a が /aa にも一致してしまう。
 */
export function pickDefaultIndex(targets: Worktree[], cwd: string): number {
  let best = -1;
  let bestLen = -1;
  targets.forEach((wt, i) => {
    const inside = cwd === wt.path || cwd.startsWith(wt.path + "/");
    if (inside && wt.path.length > bestLen) {
      best = i;
      bestLen = wt.path.length;
    }
  });
  return best;
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

/** 1 エントリの表示ラベルを組み立てる。lock された worktree が無ければ lock 列は出さない。 */
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
    label += `  ${
      padVisible(lock ? colors.lock(lock) : "", widths.maxLockLen)
    }`;
  }
  if (entry.desc) {
    label += `  ${colors.desc("# " + entry.desc)}`;
  }
  return label.trimEnd();
}

/**
 * fzf へ流し込む 1 行を組み立てる。
 * タブ区切りで「worktree の絶対パス・ブランチ名・表示ラベル」を持ち、
 * fzf 側は --with-nth=3.. でラベルのみ表示する。fzf の検索は --with-nth 変換後の
 * 表示行に対して行われるため、検索範囲もラベルのみになる (--nth は併用しない。
 * 変換後の行にはタブが無くフィールド 3 が存在しないため、付けると検索範囲が
 * 空になり全クエリが 0 件になる)。
 * パスは選択結果の逆引きに、ブランチ名は preview ({2}) に使う。
 */
export function buildFzfLine(
  entry: Entry,
  widths: ColumnWidths,
  colors: Colors,
): string {
  return [entry.path, entry.branch, buildLabel(entry, widths, colors)].join(
    "\t",
  );
}

/** fzf が返した行から worktree の絶対パス (先頭フィールド) を取り出す。 */
export function selectedPath(line: string): string {
  return line.split("\t", 1)[0];
}

/**
 * preview で branch description の全文を markdown レンダリングするコマンド。
 * {2} は fzf がブランチ名に置換する (single quote 付きで挿入されるため
 * 前後を引用符で囲まない)。mdcat が無い環境では素のテキスト表示に落とす。
 * detached (ブランチ名が空) は git config が失敗し preview は空になる。
 */
export const PREVIEW_COMMAND =
  "git config --get branch.{2}.description 2>/dev/null" +
  " | if command -v mdcat >/dev/null 2>&1; then mdcat --ansi -; else cat; fi";

const COLORS: Colors = { path: cyan, branch: green, lock: red, desc: yellow };

export interface FzfRequest {
  /** buildFzfLine で組み立てたタブ区切り行。 */
  lines: string[];
  /** 起動時にカーソルを置く行 (0 始まり)。-1 は先頭のまま。 */
  initialIndex: number;
  previewCommand: string;
}

export interface FzfResult {
  /** fzf の終了コード。0 以外は未選択 (中断・エラー) を意味する。 */
  code: number;
  /** 選択された行。未選択は空文字。 */
  line: string;
}

export interface SelectDeps {
  args: string[];
  cwd(): string;
  /** `git worktree list --porcelain` の出力を返す。 */
  listWorktrees(): Promise<string>;
  /** branch description の先頭 1 行 (subject) を返す。 */
  getDescription(branch: string): Promise<string>;
  runFzf(req: FzfRequest): Promise<FzfResult>;
  writeSelected(path: string): void;
  errorLine(msg: string): void;
}

/** worktree を fzf で対話選択し、選んだパスを書き出す。終了コードを返す。 */
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

  const result = await deps.runFzf({
    lines: entries.map((e) => buildFzfLine(e, widths, COLORS)),
    initialIndex: pickDefaultIndex(targets, deps.cwd()),
    previewCommand: PREVIEW_COMMAND,
  });
  if (result.code !== 0 || !result.line) {
    return 1;
  }

  deps.writeSelected(selectedPath(result.line));
  return 0;
}
