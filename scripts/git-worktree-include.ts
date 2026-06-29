#!/usr/bin/env -S deno run --quiet --allow-run --allow-read --allow-write

// .worktreeinclude に記載されたファイルをメインワークツリーから指定の worktree に
// コピーする。git worktree add と同じ引数を受け取り、パスを特定してコピーする。
// .worktreeinclude は gitignore 互換の構文 (ignore ライブラリ準拠)。
// 使い方: git-worktree-include [<options>] <path> [<commit-ish>]
//
// ロジックは lib/git-worktree-include.ts に分離し、副作用はここで注入する。

import { expandGlob } from "@std/fs/expand-glob";
import { ensureDir } from "@std/fs/ensure-dir";
import { resolve } from "@std/path";
import { run, type WalkEntry } from "./lib/git-worktree-include.ts";

async function* walk(
  root: string,
  exclude: string[],
): AsyncIterable<WalkEntry> {
  for await (const entry of expandGlob("**/*", { root, exclude })) {
    yield { path: entry.path, isFile: entry.isFile };
  }
}

const code = await run({
  args: Deno.args,
  runGitPorcelain: async () => {
    const { stdout } = await new Deno.Command("git", {
      args: ["worktree", "list", "--porcelain"],
      stdout: "piped",
    }).output();
    return new TextDecoder().decode(stdout);
  },
  exists: async (path) => {
    try {
      await Deno.stat(path);
      return true;
    } catch {
      return false;
    }
  },
  readText: (path) => Deno.readTextFile(path),
  resolve: (path) => resolve(path),
  walk,
  ensureDir: (dir) => ensureDir(dir),
  copyFile: (src, dest) => Deno.copyFile(src, dest),
  log: (msg) => console.log(msg),
});

Deno.exit(code);
