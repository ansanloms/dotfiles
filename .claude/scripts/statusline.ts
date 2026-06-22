import * as path from "@std/path";
import { bgBlue, bgMagenta, white } from "@std/fmt/colors";
import {
  buildInlineProgressBar,
  formatCompact,
  getInput,
  type ProgressBarColorScheme,
} from "./utils/common.ts";
import * as git from "./utils/git.ts";
import { readWorktree } from "./utils/worktree.ts";
import type { StatusLineInput, StatusLineRateLimitWindow } from "./types.ts";

const getDir = async (input: StatusLineInput) => {
  return (await git.managed(input.workspace.current_dir))
    ? (path.relative(
      await git.root(input.workspace.current_dir),
      input.workspace.current_dir,
    ).trim() || `.${path.SEPARATOR}`)
    : path.resolve(input.workspace.current_dir);
};

const formatBarLabel = (name: string, pct: number, detail: string) => {
  return ` ${name.padEnd(8)} : ${String(pct).padStart(3)}% (${detail}) `;
};

const buildRateLimitBar = (
  window: StatusLineRateLimitWindow | undefined,
  label: string,
  scheme: Partial<ProgressBarColorScheme>,
) => {
  if (window === undefined) {
    return undefined;
  }

  const pct = Math.floor(window.used_percentage);
  const resetsAt = new Date(window.resets_at * 1000).toLocaleString("ja-JP", {
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });

  return buildInlineProgressBar(
    pct,
    formatBarLabel(`Limit ${label}`, pct, `~${resetsAt}`),
    60,
    scheme,
  );
};

const getTokens = (input: StatusLineInput) => {
  return (input.context_window.current_usage?.input_tokens ?? 0) +
    (input.context_window.current_usage?.cache_creation_input_tokens ?? 0) +
    (input.context_window.current_usage?.cache_read_input_tokens ?? 0);
};

const resolveWorktreeBranch = async (
  sessionId: string,
): Promise<string | null> => {
  const root = await readWorktree(sessionId);
  if (root === null) {
    return null;
  }
  const live = await git.linkedWorktreeRoot(root);
  if (live === null) {
    return null;
  }
  return (await git.branch(live)) || path.basename(live);
};

try {
  const input = await getInput<StatusLineInput>();

  const model = input.model.display_name;
  const dir = await getDir(input);
  const cost = input.cost.total_cost_usd;
  const tokens = getTokens(input);
  const pct = Math.floor(input.context_window.used_percentage ?? 0);
  const worktreeBranch = await resolveWorktreeBranch(input.session_id);

  const line1: [string, string][] = [
    ["󰚩", model],
    ["", dir],
    ["", `$${cost.toLocaleString()}`],
  ];
  if (worktreeBranch !== null) {
    line1.splice(1, 0, ["\uE0A0", worktreeBranch]);
  }
  console.log(
    line1.map(([icon, label]) => `${icon}  ${label}`).join(" | "),
  );
  console.log(
    buildInlineProgressBar(
      pct,
      formatBarLabel("Token", pct, `${formatCompact(tokens)} tokens`),
      60,
    ),
  );
  for (
    const bar of [
      buildRateLimitBar(input.rate_limits?.five_hour, "5h", {
        low: (s) => bgBlue(white(s)),
      }),
      buildRateLimitBar(input.rate_limits?.seven_day, "7d", {
        low: (s) => bgMagenta(white(s)),
      }),
    ]
  ) {
    if (bar !== undefined) {
      console.log(bar);
    }
  }

  console.log(input.session_id);
} catch (error) {
  console.error(error);
  throw error;
}
