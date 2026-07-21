#!/usr/bin/env -S deno run --quiet --allow-run

// git worktree を fzf で対話選択し、選んだパスを stdout へ出力する。
// fzf は UI を /dev/tty に描くため、stdout はコマンド置換でそのまま受け取れる。
// リストには branch description の先頭 1 行 (subject) を表示し、
// preview で全文を mdcat により markdown レンダリングする。
// ロジックは lib/git-worktree-select.ts に分離し、副作用はここで注入する。

import { type FzfRequest, run } from "./lib/git-worktree-select.ts";

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

async function runFzf(req: FzfRequest) {
  const args = [
    "--ansi",
    "--delimiter=\t",
    "--with-nth=3..",
    "--nth=3..",
    "--layout=reverse",
    "--height=~50%",
    "--preview",
    req.previewCommand,
    "--preview-window=right,55%,wrap",
  ];
  if (req.initialIndex > 0) {
    // pos() は 1 始まり。--sync で読み込み完了後にカーソルを移す。
    args.push("--sync", "--bind", `start:pos(${req.initialIndex + 1})`);
  }
  let child: Deno.ChildProcess;
  try {
    child = new Deno.Command("fzf", {
      args,
      stdin: "piped",
      stdout: "piped",
      stderr: "inherit",
    }).spawn();
  } catch (e) {
    if (e instanceof Deno.errors.NotFound) {
      console.error("fzf not found. Install fzf to use git-worktree-select.");
      return { code: 127, line: "" };
    }
    throw e;
  }
  const writer = child.stdin.getWriter();
  await writer.write(new TextEncoder().encode(req.lines.join("\n") + "\n"));
  await writer.close();
  const output = await child.output();
  return {
    code: output.code,
    line: new TextDecoder().decode(output.stdout).trim(),
  };
}

const code = await run({
  args: Deno.args,
  cwd: () => Deno.cwd(),
  listWorktrees: () => gitStdout(["worktree", "list", "--porcelain"]),
  getDescription: (branch) =>
    gitStdout(["config", `branch.${branch}.description`], true).then((s) =>
      s.split("\n")[0]
    ),
  runFzf,
  writeSelected: (path) => {
    // 末尾の改行はコマンド置換では剥がれ、直接実行では表示を整える。
    Deno.stdout.writeSync(new TextEncoder().encode(path + "\n"));
  },
  errorLine: (msg) => console.error(msg),
});

Deno.exit(code);
