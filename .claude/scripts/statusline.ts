import * as path from "@std/path";
import { bgBlue, bgMagenta, white } from "@std/fmt/colors";
import {
  buildInlineProgressBar,
  formatCompact,
  getInput,
  type ProgressBarColorScheme,
} from "./utils/common.ts";
import * as git from "./utils/git.ts";
import type { StatusLineInput, StatusLineRateLimitWindow } from "./types.ts";

/**
 * プログレスバーの横幅を端末幅に合わせて算出する。
 *
 * Claude Code はスクリプトの stdout を端末に直結せずキャプチャするため、
 * `tput cols` や `Deno.consoleSize()` では端末幅を取得できない。
 * 代わりに Claude Code が実行前に設定する `COLUMNS` 環境変数を読む
 * (Claude Code v2.1.153 以降)。末尾の折り返しを避けるため 4 桁マージンを取る。
 * `COLUMNS` が無効・未設定の環境では従来の固定幅 60 にフォールバックする。
 */
const getBarWidth = (): number => {
  const cols = Number(Deno.env.get("COLUMNS"));
  return Number.isFinite(cols) && cols > 0 ? cols - 4 : 60;
};

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
    getBarWidth(),
    scheme,
  );
};

const getTokens = (input: StatusLineInput) => {
  return (input.context_window.current_usage?.input_tokens ?? 0) +
    (input.context_window.current_usage?.cache_creation_input_tokens ?? 0) +
    (input.context_window.current_usage?.cache_read_input_tokens ?? 0);
};

try {
  const input = await getInput<StatusLineInput>();

  const model = input.model.display_name;
  const dir = await getDir(input);
  const cost = input.cost.total_cost_usd;
  const tokens = getTokens(input);
  const pct = Math.floor(input.context_window.used_percentage ?? 0);

  console.log(
    [
      ["󰚩", model],
      ["", dir],
      ["", `$${cost.toLocaleString()}`],
    ].map(([icon, label]) => `${icon}  ${label}`).join(" | "),
  );
  console.log(
    buildInlineProgressBar(
      pct,
      formatBarLabel("Token", pct, `${formatCompact(tokens)} tokens`),
      getBarWidth(),
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
