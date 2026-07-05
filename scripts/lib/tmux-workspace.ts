// tmux-workspace の純粋ロジックとオーケストレーション。
// 副作用 (tmux 実行 / env / cwd / 端末サイズ取得) は WorkspaceDeps として注入する。
//
// zellij で使っていた default layout を tmux セッションとして再現する:
// 左に AI Agent ペイン (幅 86 固定)、右上に Neovim、右下に Terminal (高さ 25%)。
// 同名セッションが既にあれば attach する。

import { basename } from "@std/path";

/** AI Agent ペインの幅 (カラム数)。 */
export const AI_PANE_WIDTH = 86;

/** Terminal ペインの高さ (右カラムに対する割合)。 */
export const TERMINAL_HEIGHT = "25%";

/** AI Agent ペインを識別する user option @role の値。 */
export const AI_PANE_ROLE = "ai-agent";

// エージェントは固定ではなく $TMUX_AI_AGENT で差し替えられる。
// tmux は単一文字列のコマンドを既定シェルで実行するが、zsh は未クオートの
// 変数を単語分割しないため、必ず argv 形式の `sh -c` (POSIX の分割規則) で渡す。
export const AI_AGENT_COMMAND =
  'if [ -n "$TMUX_AI_AGENT" ]; then exec $TMUX_AI_AGENT; else exec claude agents --cwd "$PWD"; fi';

/** AI Agent ペインの起動コマンド (argv 形式、tmux >= 3.4)。 */
export const AI_AGENT_ARGV = ["sh", "-c", AI_AGENT_COMMAND];

/** セッション名に対応する nvim socket パス (.agents/AGENTS.md の nvim 連携規約)。 */
export function nvimSocketPath(session: string): string {
  return `/tmp/nvim-${session}.sock`;
}

/** Neovim ペインの起動コマンド (argv 形式、シェルを介さず直接 exec する)。 */
export function nvimArgv(session: string): string[] {
  return ["nvim", "--listen", nvimSocketPath(session)];
}

/**
 * パスからセッション名を導出する。tmux のセッション名に使えない "." / ":" と
 * 空白・パス区切りを "-" へ置換し、先頭・末尾の "-" を除く。
 * 空になる場合は "workspace"。
 */
export function sessionNameFromPath(path: string): string {
  const name = basename(path)
    .replaceAll(/[.:\s/\\]+/g, "-")
    .replace(/^-+/, "")
    .replace(/-+$/, "");
  return name === "" ? "workspace" : name;
}

export interface TmuxResult {
  code: number;
  stdout: string;
  stderr: string;
}

export interface WorkspaceDeps {
  args: string[];
  env(name: string): string | undefined;
  cwd(): string;
  consoleSize(): { columns: number; rows: number } | null;
  /** tmux をサブプロセスとして実行し結果を返す。 */
  tmux(args: string[]): Promise<TmuxResult>;
  /** tmux に端末を明け渡して実行する (attach 用)。終了コードを返す。 */
  attach(args: string[]): Promise<number>;
  errorLog(msg: string): void;
}

/** セッションを用意して attach する。終了コードを返す。 */
export async function run(deps: WorkspaceDeps): Promise<number> {
  if ((deps.env("TMUX") ?? "") !== "") {
    deps.errorLog("tmux-workspace: already inside a tmux session");
    return 1;
  }

  const cwd = deps.cwd();
  const session = deps.args[0] ?? sessionNameFromPath(cwd);

  const exists = await deps.tmux(["has-session", "-t", `=${session}`]);
  if (exists.code === 0) {
    return await deps.attach(["attach-session", "-t", `=${session}`]);
  }

  // detached でセッションを作り、attach 前に layout を組む。-x/-y へ現在の
  // 端末サイズを渡すことで attach 時のリサイズ (ペイン幅の再配分) を避け、
  // AI Agent ペインの幅を正確に保つ。
  const newSession = [
    "new-session",
    "-d",
    "-P",
    "-F",
    "#{pane_id}",
    "-s",
    session,
    "-c",
    cwd,
  ];
  const size = deps.consoleSize();
  if (size !== null) {
    newSession.push("-x", String(size.columns), "-y", String(size.rows));
  }
  const aiAgentEnv = deps.env("TMUX_AI_AGENT");
  if (aiAgentEnv !== undefined) {
    newSession.push("-e", `TMUX_AI_AGENT=${aiAgentEnv}`);
  }
  newSession.push(...AI_AGENT_ARGV);

  const created = await deps.tmux(newSession);
  if (created.code !== 0) {
    deps.errorLog(`tmux-workspace: new-session failed: ${created.stderr}`);
    return 1;
  }
  const aiPane = created.stdout.trim();

  // layout を組む。失敗したらエラーメッセージを返す。
  const build = async (): Promise<string | null> => {
    // ペインの識別は pane_title ではなく user option @role で行う。
    // pane_title は実行中のアプリが OSC で書き換えるため安定しない。
    let res = await deps.tmux([
      "set-option",
      "-p",
      "-t",
      aiPane,
      "@role",
      AI_PANE_ROLE,
    ]);
    if (res.code !== 0) {
      return res.stderr;
    }
    res = await deps.tmux(["select-pane", "-t", aiPane, "-T", "AI Agent"]);
    if (res.code !== 0) {
      return res.stderr;
    }

    const nvimSplit = await deps.tmux([
      "split-window",
      "-h",
      "-P",
      "-F",
      "#{pane_id}",
      "-t",
      aiPane,
      "-c",
      cwd,
      ...nvimArgv(session),
    ]);
    if (nvimSplit.code !== 0) {
      return nvimSplit.stderr;
    }
    const nvimPane = nvimSplit.stdout.trim();

    res = await deps.tmux(["select-pane", "-t", nvimPane, "-T", "Neovim"]);
    if (res.code !== 0) {
      return res.stderr;
    }
    res = await deps.tmux([
      "resize-pane",
      "-t",
      aiPane,
      "-x",
      String(AI_PANE_WIDTH),
    ]);
    if (res.code !== 0) {
      return res.stderr;
    }

    // 右カラムを縦に割る。コマンド未指定なのでログインシェル (zsh) が起動する。
    const termSplit = await deps.tmux([
      "split-window",
      "-v",
      "-P",
      "-F",
      "#{pane_id}",
      "-t",
      nvimPane,
      "-l",
      TERMINAL_HEIGHT,
      "-c",
      cwd,
    ]);
    if (termSplit.code !== 0) {
      return termSplit.stderr;
    }
    const termPane = termSplit.stdout.trim();

    res = await deps.tmux(["select-pane", "-t", termPane, "-T", "Terminal"]);
    if (res.code !== 0) {
      return res.stderr;
    }
    res = await deps.tmux(["select-pane", "-t", nvimPane]);
    if (res.code !== 0) {
      return res.stderr;
    }
    return null;
  };

  const err = await build();
  if (err !== null) {
    deps.errorLog(`tmux-workspace: layout failed: ${err}`);
    await deps.tmux(["kill-session", "-t", `=${session}`]);
    return 1;
  }

  return await deps.attach(["attach-session", "-t", `=${session}`]);
}
