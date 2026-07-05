import { assert, assertEquals } from "@std/assert";
import {
  AI_AGENT_ARGV,
  AI_PANE_ROLE,
  nvimArgv,
  nvimSocketPath,
  run,
  sessionNameFromPath,
  type TmuxResult,
  type WorkspaceDeps,
} from "./tmux-workspace.ts";

Deno.test("sessionNameFromPath: ディレクトリ名をそのまま使う", () => {
  assertEquals(sessionNameFromPath("/home/user/dev/dotfiles"), "dotfiles");
});

Deno.test("sessionNameFromPath: '.' ':' 空白を '-' へ置換する", () => {
  assertEquals(
    sessionNameFromPath("/home/user/my.repo:v2 beta"),
    "my-repo-v2-beta",
  );
});

Deno.test("sessionNameFromPath: 先頭・末尾の '-' を除く", () => {
  assertEquals(sessionNameFromPath("/tmp/.hidden."), "hidden");
});

Deno.test("sessionNameFromPath: 空になる場合は workspace", () => {
  assertEquals(sessionNameFromPath("/"), "workspace");
});

Deno.test("nvimSocketPath / nvimArgv: socket 規約に従う", () => {
  assertEquals(nvimSocketPath("foo"), "/tmp/nvim-foo.sock");
  assertEquals(nvimArgv("foo"), ["nvim", "--listen", "/tmp/nvim-foo.sock"]);
});

interface FakeOpts {
  args?: string[];
  env?: Record<string, string>;
  cwd?: string;
  consoleSize?: { columns: number; rows: number } | null;
  hasSession?: boolean;
  failCommand?: string;
  attachCode?: number;
}

function fakeDeps(opts: FakeOpts = {}) {
  const calls: string[][] = [];
  const attached: string[][] = [];
  const errors: string[] = [];
  let paneSeq = 0;

  const deps: WorkspaceDeps = {
    args: opts.args ?? [],
    env: (name) => (opts.env ?? {})[name],
    cwd: () => opts.cwd ?? "/home/user/dev/dotfiles",
    consoleSize: () =>
      opts.consoleSize === undefined
        ? { columns: 220, rows: 60 }
        : opts.consoleSize,
    tmux: (args) => {
      calls.push(args);
      const command = args[0];
      const result: TmuxResult = { code: 0, stdout: "", stderr: "" };
      if (command === opts.failCommand) {
        return Promise.resolve({ code: 1, stdout: "", stderr: "boom" });
      }
      if (command === "has-session") {
        result.code = opts.hasSession ? 0 : 1;
      }
      if (command === "new-session" || command === "split-window") {
        result.stdout = `%${paneSeq++}\n`;
      }
      return Promise.resolve(result);
    },
    attach: (args) => {
      attached.push(args);
      return Promise.resolve(opts.attachCode ?? 0);
    },
    errorLog: (msg) => errors.push(msg),
  };

  return { deps, calls, attached, errors };
}

Deno.test("run: tmux セッション内では起動しない", async () => {
  const { deps, calls, attached } = fakeDeps({
    env: { TMUX: "/tmp/tmux-1000/default,1,0" },
  });
  assertEquals(await run(deps), 1);
  assertEquals(calls, []);
  assertEquals(attached, []);
});

Deno.test("run: 既存セッションには attach のみ行う", async () => {
  const { deps, calls, attached } = fakeDeps({ hasSession: true });
  assertEquals(await run(deps), 0);
  assertEquals(calls, [["has-session", "-t", "=dotfiles"]]);
  assertEquals(attached, [["attach-session", "-t", "=dotfiles"]]);
});

Deno.test("run: 新規セッションで layout を組んで attach する", async () => {
  const { deps, calls, attached } = fakeDeps();
  assertEquals(await run(deps), 0);

  const newSession = calls.find((c) => c[0] === "new-session")!;
  assert(newSession.includes("-d"));
  assertEquals(newSession[newSession.indexOf("-s") + 1], "dotfiles");
  assertEquals(
    newSession[newSession.indexOf("-c") + 1],
    "/home/user/dev/dotfiles",
  );
  assertEquals(newSession[newSession.indexOf("-x") + 1], "220");
  assertEquals(newSession[newSession.indexOf("-y") + 1], "60");
  assertEquals(newSession.slice(-3), AI_AGENT_ARGV);

  // AI Agent ペイン (%0) に @role を付ける。
  assert(
    calls.some((c) =>
      c[0] === "set-option" && c.includes("%0") && c.includes("@role") &&
      c.includes(AI_PANE_ROLE)
    ),
  );

  // 右カラム: nvim (%1) を AI Agent (%0) から水平分割で作る。
  const nvimSplit = calls.find((c) =>
    c[0] === "split-window" && c.includes("-h")
  )!;
  assertEquals(nvimSplit[nvimSplit.indexOf("-t") + 1], "%0");
  assertEquals(nvimSplit.slice(-3), nvimArgv("dotfiles"));

  // AI Agent ペインの幅を 86 に固定する。
  const resize = calls.find((c) => c[0] === "resize-pane")!;
  assertEquals(resize[resize.indexOf("-t") + 1], "%0");
  assertEquals(resize[resize.indexOf("-x") + 1], "86");

  // Terminal (%2) は nvim (%1) から縦分割、高さ 25%。
  const termSplit = calls.find((c) =>
    c[0] === "split-window" && c.includes("-v")
  )!;
  assertEquals(termSplit[termSplit.indexOf("-t") + 1], "%1");
  assertEquals(termSplit[termSplit.indexOf("-l") + 1], "25%");

  // 最終フォーカスは nvim。
  const lastSelect = calls.filter((c) => c[0] === "select-pane").at(-1)!;
  assertEquals(lastSelect, ["select-pane", "-t", "%1"]);

  assertEquals(attached, [["attach-session", "-t", "=dotfiles"]]);
});

Deno.test("run: 引数でセッション名を指定できる", async () => {
  const { deps, calls } = fakeDeps({ args: ["myname"] });
  assertEquals(await run(deps), 0);
  assertEquals(calls[0], ["has-session", "-t", "=myname"]);
  const nvimSplit = calls.find((c) =>
    c[0] === "split-window" && c.includes("-h")
  )!;
  assertEquals(nvimSplit.slice(-3), nvimArgv("myname"));
});

Deno.test("run: TMUX_AI_AGENT をセッション環境へ引き継ぐ", async () => {
  const { deps, calls } = fakeDeps({ env: { TMUX_AI_AGENT: "codex --foo" } });
  assertEquals(await run(deps), 0);
  const newSession = calls.find((c) => c[0] === "new-session")!;
  assertEquals(
    newSession[newSession.indexOf("-e") + 1],
    "TMUX_AI_AGENT=codex --foo",
  );
});

Deno.test("run: 端末サイズ不明なら -x/-y を付けない", async () => {
  const { deps, calls } = fakeDeps({ consoleSize: null });
  assertEquals(await run(deps), 0);
  const newSession = calls.find((c) => c[0] === "new-session")!;
  assert(!newSession.includes("-x"));
  assert(!newSession.includes("-y"));
});

Deno.test("run: layout 構築に失敗したらセッションを片付けて 1 を返す", async () => {
  const { deps, calls, attached } = fakeDeps({ failCommand: "split-window" });
  assertEquals(await run(deps), 1);
  assert(calls.some((c) => c[0] === "kill-session"));
  assertEquals(attached, []);
});
