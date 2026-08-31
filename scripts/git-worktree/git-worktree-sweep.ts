#!/usr/bin/env -S deno run --quiet --allow-run

// メイン以外の全 linked worktree (配置場所は問わない) のうち、ブランチが
// デフォルトブランチへマージ済み (squash merge 含む) かつ working tree が
// クリーンなものを削除し、ローカルブランチも消す。
// dirty・未マージ・detached・固有コミット無しは報告のみ。判定不能 (git コマンドの失敗) も
// worktree には触れないが、エラーとして報告し非 0 で終了する。git が prunable と
// 判定した worktree (管理情報の破損・実体ディレクトリの消失等) は分類せず
// Skipped として報告し、(非 dry-run では) 末尾の `git worktree prune` が整理する。
// マージ判定は git のみで行い、forge (GitHub 等) の API に依存しない。
// 使い方: git-worktree-sweep [--dry-run]
//
// ロジックは lib/sweep.ts に分離し、副作用はここで注入する。

import { run } from "./lib/sweep.ts";

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
