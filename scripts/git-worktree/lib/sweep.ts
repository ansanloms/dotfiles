// git-worktree-sweep の純粋ロジックとオーケストレーション。
// 副作用 (git 実行 / 出力) は SweepDeps として注入する。
//
// メイン以外の全 linked worktree (配置場所は問わない) のうち、ブランチが
// デフォルトブランチへマージ済みかつ working tree がクリーンなものを削除し、
// ローカルブランチも消す。
// マージ判定は forge (GitHub 等) の API に依存せず git のみで行う:
//   1. merge-base --is-ancestor (通常 merge / fast-forward)
//   2. ブランチを merge-base に対して仮 squash した commit の patch-id が
//      デフォルトブランチに含まれるか (git cherry) — squash merge 検知
// dirty・未マージ・detached はスキップして報告のみ行う。判定不能 (git コマンドの失敗) も
// worktree には触れないが、エラーとして報告し非 0 で終了する。git が prunable と
// 判定した worktree (管理情報の破損・実体ディレクトリの消失等) は分類せず
// Skipped として報告し、(非 dry-run では) 末尾の `git worktree prune` が整理する。

import { parseArgs } from "@std/cli/parse-args";

export interface WorktreeEntry {
  path: string;
  /** checkout 中のブランチ名。detached の場合は null。 */
  branch: string | null;
  /** git が prunable と判定し `git worktree prune` の対象になっているか。 */
  prunable: boolean;
}

export interface WorktreeList {
  mainWt: string;
  entries: WorktreeEntry[];
}

/** `git worktree list --porcelain` をパースする。先頭エントリがメイン worktree。 */
export function parseWorktreeList(output: string): WorktreeList {
  const blocks = output.trim().split("\n\n").filter((b) => b.length > 0);
  const entries: WorktreeEntry[] = [];
  for (const block of blocks) {
    let path = "";
    let branch: string | null = null;
    let prunable = false;
    for (const line of block.split("\n")) {
      if (line.startsWith("worktree ")) {
        path = line.slice("worktree ".length);
      } else if (line.startsWith("branch ")) {
        branch = line.slice("branch ".length).replace(/^refs\/heads\//, "");
      } else if (line.startsWith("prunable ")) {
        prunable = true;
      }
    }
    if (path !== "") {
      entries.push({ path, branch, prunable });
    }
  }
  const mainWt = entries.length > 0 ? entries[0].path : "";
  return { mainWt, entries: entries.slice(1) };
}

/** `git cherry <upstream> <head>` の出力から「全 commit が upstream に含まれる」か判定する。 */
export function isFullyContained(cherryOutput: string): boolean {
  const lines = cherryOutput.trim().split("\n").filter((l) => l.length > 0);
  if (lines.length === 0) {
    return true;
  }
  return lines.every((line) => line.startsWith("-"));
}

export interface GitResult {
  success: boolean;
  stdout: string;
  stderr: string;
}

export interface SweepDeps {
  args: string[];
  runGit(args: string[]): Promise<GitResult>;
  log(msg: string): void;
  errorLog(msg: string): void;
}

/** origin のデフォルトブランチ名を解決する。解決できなければ null。 */
export async function resolveDefaultBranch(
  deps: SweepDeps,
): Promise<string | null> {
  const symbolic = await deps.runGit([
    "symbolic-ref",
    "--short",
    "refs/remotes/origin/HEAD",
  ]);
  if (symbolic.success) {
    return symbolic.stdout.trim().replace(/^origin\//, "");
  }
  for (const candidate of ["main", "master"]) {
    const verify = await deps.runGit([
      "rev-parse",
      "--verify",
      `refs/remotes/origin/${candidate}`,
    ]);
    if (verify.success) {
      return candidate;
    }
  }
  return null;
}

/**
 * `git log --format=%P` の出力から、tip がいずれかの merge commit の
 * 第 2 親以降として現れるか判定する。第 1 親としての出現は直列の履歴でも
 * 起こるため merge の証拠にならない。
 */
export function isMergedAsParent(logOutput: string, tip: string): boolean {
  return logOutput
    .split("\n")
    .map((line) => line.trim().split(/\s+/).filter((p) => p.length > 0))
    .some((parents) => parents.length >= 2 && parents.slice(1).includes(tip));
}

export type BranchVerdict =
  | "merged"
  | "not-merged"
  | "no-own-commits"
  | { kind: "classification-failed"; detail: string };

/** 落ちた git サブコマンドと stderr の先頭行から classification-failed の detail を作る。 */
function classificationFailed(
  subcommand: string,
  result: GitResult,
): { kind: "classification-failed"; detail: string } {
  const firstLine = result.stderr.trim().split("\n")[0] ?? "";
  return {
    kind: "classification-failed",
    detail: `${subcommand}: ${firstLine}`,
  };
}

/**
 * ブランチのマージ状態を分類する。
 * - 固有コミットが無い場合: デフォルトブランチ上の merge commit の第 2 親以降に
 *   tip が現れれば merged (merge commit でマージ済み)、現れなければ
 *   no-own-commits (作成直後の worktree 等) として削除対象にしない。
 * - 固有コミットがある場合: ブランチを merge-base に対して仮 squash した commit の
 *   patch-id がデフォルトブランチに含まれれば merged (squash merge 検知)。
 *
 * ブランチ側の revision 引数は同名パス・同名タグとの曖昧解釈 (ambiguous argument)
 * を避けるため refs/heads/ で修飾する。defaultRef (origin/main 等) 側の曖昧解釈は
 * log の argv 末尾の `--` (path 解釈の遮断) が防いでおり、これを消すと
 * ambiguous argument が再発する。
 */
export async function classifyBranch(
  deps: SweepDeps,
  branch: string,
  defaultRef: string,
): Promise<BranchVerdict> {
  const unique = await deps.runGit([
    "rev-list",
    "--count",
    `${defaultRef}..refs/heads/${branch}`,
  ]);
  if (!unique.success) {
    return classificationFailed("rev-list", unique);
  }

  if (unique.stdout.trim() === "0") {
    const tip = await deps.runGit(["rev-parse", `refs/heads/${branch}`]);
    if (!tip.success) {
      return classificationFailed("rev-parse", tip);
    }
    const log = await deps.runGit([
      "log",
      "--format=%P",
      defaultRef,
      `^refs/heads/${branch}`,
      "--",
    ]);
    if (!log.success) {
      return classificationFailed("log", log);
    }
    return isMergedAsParent(log.stdout, tip.stdout.trim())
      ? "merged"
      : "no-own-commits";
  }

  const base = await deps.runGit([
    "merge-base",
    defaultRef,
    `refs/heads/${branch}`,
  ]);
  if (!base.success) {
    // merge-base は共通祖先が無い場合、stderr を出さずに exit 1 する
    // (エラーではなく「merge base 無し」という正常な結果)。stderr が
    // 空ならこのケースとみなし not-merged にする。stderr があれば
    // 従来どおり判定不能として扱う。
    if (base.stderr.trim() === "") {
      return "not-merged";
    }
    return classificationFailed("merge-base", base);
  }
  const tree = await deps.runGit([
    "rev-parse",
    `refs/heads/${branch}^{tree}`,
  ]);
  if (!tree.success) {
    return classificationFailed("rev-parse", tree);
  }
  const tmpCommit = await deps.runGit([
    "commit-tree",
    tree.stdout.trim(),
    "-p",
    base.stdout.trim(),
    "-m",
    "git-worktree-sweep: squash merge check",
  ]);
  if (!tmpCommit.success) {
    return classificationFailed("commit-tree", tmpCommit);
  }
  const cherry = await deps.runGit([
    "cherry",
    defaultRef,
    tmpCommit.stdout.trim(),
  ]);
  if (!cherry.success) {
    return classificationFailed("cherry", cherry);
  }
  return isFullyContained(cherry.stdout) ? "merged" : "not-merged";
}

/**
 * メイン以外の linked worktree のうちマージ済みクリーンなものを削除する。
 * 終了コードを返す。--dry-run 時は削除せず判定結果のみ出力する。
 */
export async function run(deps: SweepDeps): Promise<number> {
  const parsed = parseArgs(deps.args, {
    boolean: ["dry-run"],
  });
  const dryRun = parsed["dry-run"];

  const list = await deps.runGit(["worktree", "list", "--porcelain"]);
  if (!list.success) {
    deps.errorLog(list.stderr);
    return 1;
  }
  const { entries: targets } = parseWorktreeList(list.stdout);

  if (targets.length === 0) {
    deps.log("No linked worktrees.");
    return 0;
  }

  const fetch = await deps.runGit(["fetch", "--prune", "origin"]);
  if (!fetch.success) {
    deps.errorLog(
      `Warning: git fetch failed; merge detection may use stale refs.\n${fetch.stderr}`,
    );
  }

  const defaultBranch = await resolveDefaultBranch(deps);
  if (defaultBranch === null) {
    deps.errorLog("Could not resolve the default branch of origin.");
    return 1;
  }
  const defaultRef = `origin/${defaultBranch}`;

  let failed = false;
  for (const target of targets) {
    if (target.prunable) {
      deps.log(`Skipped (prunable): ${target.path}`);
      continue;
    }

    if (target.branch === null) {
      deps.log(`Kept (detached HEAD): ${target.path}`);
      continue;
    }

    const status = await deps.runGit([
      "-C",
      target.path,
      "status",
      "--porcelain",
    ]);
    if (!status.success) {
      const firstLine = status.stderr.trim().split("\n")[0] ?? "";
      deps.errorLog(`Kept (status failed: ${firstLine}): ${target.path}`);
      failed = true;
      continue;
    }
    const dirty = status.stdout.trim() !== "";

    const verdict = await classifyBranch(deps, target.branch, defaultRef);

    if (typeof verdict === "object") {
      deps.errorLog(
        `Kept (classification failed: ${verdict.detail}): ${target.path}`,
      );
      failed = true;
      continue;
    }
    switch (verdict) {
      case "no-own-commits":
        deps.log(`Kept (no commits on branch yet): ${target.path}`);
        continue;
      case "not-merged":
        deps.log(`Kept (not merged into ${defaultRef}): ${target.path}`);
        continue;
      case "merged":
        break;
      default: {
        const _exhaustive: never = verdict;
        throw new Error(`Unexpected verdict: ${_exhaustive}`);
      }
    }
    if (dirty) {
      deps.log(`Kept (merged but dirty): ${target.path}`);
      continue;
    }

    if (dryRun) {
      deps.log(`Would remove: ${target.path} (branch: ${target.branch})`);
      continue;
    }

    const remove = await deps.runGit([
      "worktree",
      "remove",
      "--force",
      target.path,
    ]);
    if (!remove.success) {
      deps.errorLog(`Failed to remove ${target.path}:\n${remove.stderr}`);
      failed = true;
      continue;
    }
    const branchDelete = await deps.runGit(["branch", "-D", target.branch]);
    if (!branchDelete.success) {
      deps.errorLog(
        `Failed to delete branch ${target.branch}:\n${branchDelete.stderr}`,
      );
      failed = true;
      continue;
    }
    deps.log(`Removed: ${target.path} (branch: ${target.branch})`);

    const remote = await deps.runGit([
      "ls-remote",
      "--heads",
      "origin",
      target.branch,
    ]);
    if (remote.success && remote.stdout.trim() !== "") {
      deps.log(
        `Note: remote branch origin/${target.branch} still exists. Delete with: git push origin --delete ${target.branch}`,
      );
    }
  }

  if (!dryRun) {
    await deps.runGit(["worktree", "prune"]);
  }

  return failed ? 1 : 0;
}
