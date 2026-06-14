#!/usr/bin/env -S deno run --quiet --allow-run

import { Select } from "@cliffy/prompt";
import { cyan, green, stripAnsiCode, yellow } from "@std/fmt/colors";
import { relative } from "@std/path";
import { unicodeWidth } from "@std/cli/unicode-width";

const process = new Deno.Command("git", {
  args: ["worktree", "list"],
  stdout: "piped",
});

const { stdout } = await process.output();
const output = new TextDecoder().decode(stdout).trim();

if (!output) {
  console.error("No worktrees found.");
  Deno.exit(1);
}

const worktrees = output.split("\n").map((line) => {
  const match = line.match(/^(\S+)\s+(\S+)\s+\[(.+)\]$/);
  if (!match) {
    return null;
  }
  return { path: match[1], sha: match[2], branch: match[3] };
}).filter((v) => v !== null);

const getDescription = async (branch: string): Promise<string> => {
  const proc = new Deno.Command("git", {
    args: ["config", `branch.${branch}.description`],
    stdout: "piped",
    stderr: "null",
  });
  const { stdout, success } = await proc.output();
  if (!success) {
    return "";
  }
  return new TextDecoder().decode(stdout).trim().split("\n")[0];
};

const mainPath = worktrees[0].path;

const excludeMain = Deno.args.includes("--exclude-main");
const targets = excludeMain ? worktrees.slice(1) : worktrees;

if (targets.length === 0) {
  console.error("No worktrees to select.");
  Deno.exit(1);
}

const entries = await Promise.all(
  targets.map(async (worktree) => {
    const desc = await getDescription(worktree.branch);
    const relativePath = relative(mainPath, worktree.path) || ".";
    return { ...worktree, relativePath, desc };
  }),
);

const pad = (str: string, width: number): string => {
  const visible = unicodeWidth(stripAnsiCode(str));
  return str + " ".repeat(Math.max(0, width - visible));
};

const maxPathLen = Math.max(
  ...entries.map((entry) => unicodeWidth(entry.relativePath)),
);
const maxBranchLen = Math.max(
  ...entries.map((entry) => unicodeWidth(`[${entry.branch}]`)),
);

const selected = await Select.prompt({
  message: "Select worktree",
  options: entries.map((entry) => {
    const path = pad(cyan(entry.relativePath), maxPathLen);
    const branch = pad(green(`[${entry.branch}]`), maxBranchLen);
    const name = entry.desc
      ? `${path}  ${entry.sha} ${branch}  ${yellow("# " + entry.desc)}`
      : `${path}  ${entry.sha} ${branch}`;
    return { name, value: entry.path };
  }),
  default: targets.find((wt) => Deno.cwd().startsWith(wt.path))?.path,
  hideDefault: true,
});

await Deno.stderr.write(new TextEncoder().encode(selected));
