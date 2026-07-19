#!/usr/bin/env -S deno run --quiet --allow-run

// <main>/.claude/worktrees/ 配下の worktree のうち、ブランチがデフォルトブランチへ
// マージ済み (squash merge 含む) かつ working tree がクリーンなものを削除し、
// ローカルブランチも消す。dirty・未マージ・detached は報告のみ。
// マージ判定は git のみで行い、forge (GitHub 等) の API に依存しない。
// 使い方: git-worktree-sweep [--dry-run]
//
// ロジックは lib/git-worktree-sweep.ts に分離し、副作用はここで注入する。

import { run } from "./lib/git-worktree-sweep.ts";

const code = await run({
  args: Deno.args,
  runGit: async (args) => {
    const { success, stdout, stderr } = await new Deno.Command("git", {
      args,
      stdout: "piped",
      stderr: "piped",
    }).output();
    const decoder = new TextDecoder();
    return {
      success,
      stdout: decoder.decode(stdout),
      stderr: decoder.decode(stderr),
    };
  },
  log: (msg) => console.log(msg),
  errorLog: (msg) => console.error(msg),
});

Deno.exit(code);
