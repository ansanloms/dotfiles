#!/usr/bin/env deno

import * as path from "jsr:@std/path@1.1.3";
import * as fs from "jsr:@std/fs@1.0.20";

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

const getTokens = async (transcriptPath: string): Promise<number> => {
  if (!(await fs.exists(transcriptPath))) {
    return 0;
  }

  const transcripts = (await Deno.readTextFile(transcriptPath)).split("\n")
    .filter((line) => line.trim().length > 0)
    .map((line) => JSON.parse(line));

  return transcripts.map((transcript) => {
    const {
      input_tokens: inputTokens = 0,
      output_tokens: outputTokens = 0,
      cache_creation_input_tokens: cacheCreationInputTokens = 0,
      cache_read_input_tokens: cacheReadInputTokens = 0,
    } = transcript.message?.usage ?? {};

    return Number(inputTokens) + Number(outputTokens) +
      Number(cacheCreationInputTokens) + Number(cacheReadInputTokens);
  }).reduce((total, token) => total + token, 0);
};

const formatNumber = (num: number): string => {
  return new Intl.NumberFormat("en", {
    notation: "compact",
    compactDisplay: "short",
  }).format(num);
};

const data = await (async () => {
  const decoder = new TextDecoder();
  let input = "";
  for await (const chunk of Deno.stdin.readable) {
    input += decoder.decode(chunk);
  }
  return JSON.parse(input) as StatuslineCommand;
})();

(async () => {
  try {
    console.log(
      [
        [
          "󰚩",
          data.model.display_name,
        ],
        [
          "📁 ",
          (await gitManaged(data.workspace.current_dir))
            ? (path.relative(
              await gitRoot(data.workspace.current_dir),
              data.workspace.current_dir,
            ).trim() || `.${path.SEPARATOR}`)
            : path.resolve(data.workspace.current_dir),
        ],
        [
          "",
          `${formatNumber(await getTokens(data.transcript_path))} tokens`,
        ],
        [
          "💰",
          `$${data.cost.total_cost_usd.toLocaleString()}`,
        ],
      ].map(([icon, label]) => `${icon} ${label}`).join(" | "),
    );
  } catch (e) {
    console.log(e);
  }
})();
