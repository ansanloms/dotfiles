#!/usr/bin/env -S deno run --quiet --allow-run=tmux --allow-read --allow-env=TMUX,TMUX_AI_AGENT

// 作業用の tmux セッションを用意して attach する。
// 左: AI Agent (幅 86、$TMUX_AI_AGENT または claude agents)、
// 右上: Neovim (--listen /tmp/nvim-<セッション名>.sock)、右下: Terminal (高さ 25%)。
// 同名セッションが既にあれば attach のみ行う。
// 使い方: tmux-workspace [<session-name>] (省略時はカレントディレクトリ名から導出)
//
// ロジックは lib/tmux-workspace.ts に分離し、副作用はここで注入する。

import { run } from "./lib/tmux-workspace.ts";

const code = await run({
  args: Deno.args,
  env: (name) => Deno.env.get(name),
  cwd: () => Deno.cwd(),
  consoleSize: () => {
    try {
      return Deno.consoleSize();
    } catch {
      return null;
    }
  },
  tmux: async (args) => {
    const { code, stdout, stderr } = await new Deno.Command("tmux", {
      args,
      stdout: "piped",
      stderr: "piped",
    }).output();
    return {
      code,
      stdout: new TextDecoder().decode(stdout),
      stderr: new TextDecoder().decode(stderr),
    };
  },
  attach: async (args) => {
    const status = await new Deno.Command("tmux", {
      args,
      stdin: "inherit",
      stdout: "inherit",
      stderr: "inherit",
    }).spawn().status;
    return status.code;
  },
  errorLog: (msg) => console.error(msg),
});

Deno.exit(code);
