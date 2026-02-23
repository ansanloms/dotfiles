#!/usr/bin/env deno

import * as path from "jsr:@std/path@1.1.3";

interface StatuslineCommand {
  hook_event_name: string;
  session_id: string;
  transcript_path: string;
  cwd: string;
  model: {
    id: string;
    display_name: string;
  };
  workspace: {
    current_dir: string;
    project_dir: string;
  };
  version: string;
  output_style: {
    name: string;
  };
  cost: {
    total_cost_usd: number;
    total_duration_ms: number;
    total_api_duration_ms: number;
    total_lines_added: number;
    total_lines_removed: number;
  };
  context_window: {
    total_input_tokens: number;
    total_output_tokens: number;
    context_window_size: number;
    used_percentage?: number | null;
    remaining_percentage?: number | null;
    current_usage?: {
      input_tokens?: number;
      output_tokens?: number;
      cache_creation_input_tokens?: number;
      cache_read_input_tokens?: number;
    };
  };
}

const git = async (filepath: string, args: string[]) => {
  const command = new Deno.Command("git", {
    args: [
      "-C",
      (await Deno.stat(filepath)).isDirectory
        ? filepath
        : path.dirname(filepath),
      ...args,
    ],
  });
  return await command.output();
};

const gitRoot = async (filepath: string): Promise<string> => {
  const { code, stdout, stderr } = await git(filepath, [
    "rev-parse",
    "--show-toplevel",
  ]);
  if (code !== 0) {
    throw new Error(new TextDecoder().decode(stderr));
  }
  return new TextDecoder().decode(stdout).trim();
};

const gitManaged = async (filepath: string): Promise<boolean> => {
  const { code } = await git(filepath, ["rev-parse"]);
  return code === 0;
};

const formatCompact = (num: number): string =>
  new Intl.NumberFormat("en", {
    notation: "compact",
    compactDisplay: "short",
  }).format(num);

const buildProgressBar = (pct: number, width: number): string => {
  const filled = Math.floor(pct * width / 100);
  return "\u2593".repeat(filled) + "\u2591".repeat(width - filled);
};

const contextBarColor = (pct: number): string =>
  pct >= 90 ? "\x1b[31m" : pct >= 70 ? "\x1b[33m" : "\x1b[32m";

const RESET = "\x1b[0m";

const decoder = new TextDecoder();
let raw = "";
for await (const chunk of Deno.stdin.readable) {
  raw += decoder.decode(chunk);
}
const data = JSON.parse(raw) as StatuslineCommand;

try {
  const dir = (await gitManaged(data.workspace.current_dir))
    ? (path.relative(
      await gitRoot(data.workspace.current_dir),
      data.workspace.current_dir,
    ).trim() || `.${path.SEPARATOR}`)
    : path.resolve(data.workspace.current_dir);

  const tokens = (data.context_window.current_usage?.input_tokens ?? 0) +
    (data.context_window.current_usage?.cache_creation_input_tokens ?? 0) +
    (data.context_window.current_usage?.cache_read_input_tokens ?? 0);

  const pct = Math.floor(data.context_window.used_percentage ?? 0);

  console.log(data.session_id);
  console.log(
    [
      ["\uDB80\uDC29", data.model.display_name],
      ["\uD83D\uDCC1 ", dir],
      ["\uD83D\uDCB0", `$${data.cost.total_cost_usd.toLocaleString()}`],
    ].map(([icon, label]) => `${icon} ${label}`).join(" | "),
  );
  console.log(
    `${contextBarColor(pct)}${buildProgressBar(pct, 20)}${RESET} ${pct}% (${
      formatCompact(tokens)
    } tokens)`,
  );
} catch (error) {
  console.error(error);
}
