// git-worktree-include の純粋ロジックとオーケストレーション。
// 副作用 (git 実行 / fs 走査・読み書き / パス解決) は IncludeDeps として注入する。
//
// .worktreeinclude に記載されたファイルをメインワークツリーから指定の worktree に
// コピーする。.worktreeinclude は gitignore 互換の構文 (ignore ライブラリ準拠)。

import { dirname, join, relative } from "@std/path";
import { parseArgs } from "@std/cli/parse-args";
import ignore from "ignore";

export interface Porcelain {
  mainWt: string;
  others: string[];
}

/** `git worktree list --porcelain` をパースし、メインと他 worktree のパスを返す。 */
export function parsePorcelain(output: string): Porcelain {
  const lines = output.split("\n");
  const mainWt = lines[0].replace(/^worktree /, "");
  const others = lines
    .filter((line) => line.startsWith("worktree "))
    .map((line) => line.replace(/^worktree /, ""))
    .filter((path) => path !== mainWt);
  return { mainWt, others };
}

/**
 * expandGlob の exclude に渡す除外パターンを構築する。
 * .git + .worktreeinclude の ! 行 (否定パターン) + 他 worktree の相対パス。
 */
export function buildExcludePatterns(
  content: string,
  others: string[],
  mainWt: string,
): string[] {
  const patterns = [".git"];
  for (const line of content.split("\n")) {
    const trimmed = line.trimEnd();
    if (trimmed.startsWith("!")) {
      patterns.push(trimmed.slice(1));
    }
  }
  for (const wt of others) {
    patterns.push(`${relative(mainWt, wt)}/**`);
  }
  return patterns;
}

/** git worktree add と同じ引数からコピー先パスを取り出す。無ければ null。 */
export function resolveDst(args: string[]): string | null {
  const parsed = parseArgs(args, {
    boolean: [
      "force",
      "detach",
      "checkout",
      "no-checkout",
      "lock",
      "quiet",
      "track",
      "no-track",
      "guess-remote",
      "no-guess-remote",
    ],
    string: ["b", "B", "reason"],
    alias: { f: "force", q: "quiet" },
  });
  const dst = parsed._[0];
  return typeof dst === "string" ? dst : null;
}

export interface Matcher {
  ignores(path: string): boolean;
}

/** .worktreeinclude の内容から ignore マッチャを構築する (マッチ = コピー対象)。 */
export function buildIgnore(content: string): Matcher {
  return ignore().add(content);
}

export interface WalkEntry {
  path: string;
  isFile: boolean;
}

export interface IncludeDeps {
  args: string[];
  runGitPorcelain(): Promise<string>;
  exists(path: string): Promise<boolean>;
  readText(path: string): Promise<string>;
  resolve(path: string): string;
  walk(root: string, exclude: string[]): AsyncIterable<WalkEntry>;
  ensureDir(dir: string): Promise<void>;
  copyFile(src: string, dest: string): Promise<void>;
  log(msg: string): void;
}

/**
 * .worktreeinclude にマッチするファイルをコピー先 worktree へ複製する。
 * 終了コードを返す (常に 0; 対象が無い場合も成功扱い)。
 */
export async function run(deps: IncludeDeps): Promise<number> {
  const output = (await deps.runGitPorcelain()).trim();
  const { mainWt, others } = parsePorcelain(output);

  const includeFile = join(mainWt, ".worktreeinclude");
  if (!(await deps.exists(includeFile))) {
    return 0;
  }

  const dst = resolveDst(deps.args);
  if (dst === null) {
    return 0;
  }
  const dstPath = deps.resolve(dst);

  const content = await deps.readText(includeFile);
  const ig = buildIgnore(content);
  const exclude = buildExcludePatterns(content, others, mainWt);

  for await (const entry of deps.walk(mainWt, exclude)) {
    if (!entry.isFile) {
      continue;
    }
    const rel = relative(mainWt, entry.path);
    if (!ig.ignores(rel)) {
      continue;
    }
    const destPath = join(dstPath, rel);
    await deps.ensureDir(dirname(destPath));
    await deps.copyFile(entry.path, destPath);
    deps.log(`Copied: ${rel}`);
  }

  return 0;
}
