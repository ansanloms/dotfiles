#!/usr/bin/env -S deno run --quiet --allow-run

// git worktree を対話選択し、選んだパスを stderr へ出力する。
// ロジックは lib/git-worktree-select.ts に分離し、副作用はここで注入する。

import { Select } from "@cliffy/prompt";
import { run, type SelectOptions } from "./lib/git-worktree-select.ts";

async function gitStdout(args: string[], allowFail = false): Promise<string> {
  const { stdout, success } = await new Deno.Command("git", {
    args,
    stdout: "piped",
    stderr: allowFail ? "null" : "inherit",
  }).output();
  if (!success && allowFail) {
    return "";
  }
  return new TextDecoder().decode(stdout).trim();
}

const code = await run({
  args: Deno.args,
  cwd: () => Deno.cwd(),
  listWorktrees: () => gitStdout(["worktree", "list"]),
  getDescription: (branch) =>
    gitStdout(["config", `branch.${branch}.description`], true).then((s) =>
      s.split("\n")[0]
    ),
  select: (opts: SelectOptions) =>
    Select.prompt({ ...opts, hideDefault: true }) as Promise<string>,
  writeSelected: (path) => {
    Deno.stderr.writeSync(new TextEncoder().encode(path));
  },
  errorLine: (msg) => console.error(msg),
});

Deno.exit(code);
