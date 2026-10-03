import { assertEquals } from "@std/assert";
import type {
  NotificationHookInput,
  PermissionRequestHookInput,
  StopHookInput,
} from "@anthropic-ai/claude-agent-sdk";
import {
  buildNotification,
  buildTerminalSequence,
  formatToolInput,
  getEventDescriptor,
  getLastAssistantMessage,
  getMessage,
  getNotificationMessage,
  getPermissionRequestMessage,
  getStopFailureMessage,
  getStopMessage,
} from "./hook.ts";

const baseInput = {
  session_id: "test-session",
  transcript_path: "",
  cwd: "/tmp",
};

// --- getLastAssistantMessage ---

Deno.test("getLastAssistantMessage: テキストメッセージを抽出する", async () => {
  const tmp = await Deno.makeTempFile();
  try {
    const lines = [
      JSON.stringify({
        message: { content: [{ type: "tool_use", name: "Bash" }] },
      }),
      JSON.stringify({
        message: { content: [{ type: "text", text: "hello world" }] },
      }),
    ];
    await Deno.writeTextFile(tmp, lines.join("\n") + "\n");
    const result = await getLastAssistantMessage(tmp);
    assertEquals(result, "hello world");
  } finally {
    await Deno.remove(tmp);
  }
});

Deno.test("getLastAssistantMessage: 最新のテキストを返す", async () => {
  const tmp = await Deno.makeTempFile();
  try {
    const lines = [
      JSON.stringify({ message: { content: [{ type: "text", text: "old" }] } }),
      JSON.stringify({ message: { content: [{ type: "text", text: "new" }] } }),
    ];
    await Deno.writeTextFile(tmp, lines.join("\n") + "\n");
    const result = await getLastAssistantMessage(tmp);
    assertEquals(result, "new");
  } finally {
    await Deno.remove(tmp);
  }
});

Deno.test("getLastAssistantMessage: テキストがなければ undefined を返す", async () => {
  const tmp = await Deno.makeTempFile();
  try {
    const lines = [
      JSON.stringify({
        message: { content: [{ type: "tool_use", name: "Read" }] },
      }),
    ];
    await Deno.writeTextFile(tmp, lines.join("\n") + "\n");
    const result = await getLastAssistantMessage(tmp);
    assertEquals(result, undefined);
  } finally {
    await Deno.remove(tmp);
  }
});

// --- getStopMessage ---

Deno.test("getStopMessage: last_assistant_message があればそれを返す", async () => {
  const input: StopHookInput = {
    ...baseInput,
    hook_event_name: "Stop",
    stop_hook_active: false,
    last_assistant_message: "direct message",
  };
  const result = await getStopMessage(input);
  assertEquals(result, "direct message");
});

Deno.test("getStopMessage: last_assistant_message がなければトランスクリプトから取得する", async () => {
  const tmp = await Deno.makeTempFile();
  try {
    await Deno.writeTextFile(
      tmp,
      JSON.stringify({
        message: { content: [{ type: "text", text: "from transcript" }] },
      }) + "\n",
    );
    const input: StopHookInput = {
      ...baseInput,
      hook_event_name: "Stop",
      stop_hook_active: false,
      transcript_path: tmp,
    };
    const result = await getStopMessage(input);
    assertEquals(result, "from transcript");
  } finally {
    await Deno.remove(tmp);
  }
});

// --- getNotificationMessage ---

Deno.test("getNotificationMessage: title ありの場合", () => {
  const input: NotificationHookInput = {
    ...baseInput,
    hook_event_name: "Notification",
    message: "task done",
    title: "Background task",
    notification_type: "task_completed",
  };
  assertEquals(getNotificationMessage(input), "Background task\ntask done");
});

Deno.test("getNotificationMessage: title なしの場合", () => {
  const input: NotificationHookInput = {
    ...baseInput,
    hook_event_name: "Notification",
    message: "task done",
    notification_type: "task_completed",
  };
  assertEquals(getNotificationMessage(input), "task done");
});

// --- formatToolInput ---

Deno.test("formatToolInput: Bash はコマンドを返す", () => {
  assertEquals(
    formatToolInput("Bash", { command: "ls -la" }),
    "ls -la",
  );
});

Deno.test("formatToolInput: Edit はファイルパスと変更箇所を返す", () => {
  const result = formatToolInput("Edit", {
    file_path: "/tmp/foo.ts",
    old_string: "old code",
  });
  assertEquals(result, "/tmp/foo.ts\nold code...");
});

Deno.test("formatToolInput: Write はファイルパスを返す", () => {
  assertEquals(
    formatToolInput("Write", { file_path: "/tmp/bar.ts" }),
    "/tmp/bar.ts",
  );
});

Deno.test("formatToolInput: Read はファイルパスを返す", () => {
  assertEquals(
    formatToolInput("Read", { file_path: "/tmp/baz.ts" }),
    "/tmp/baz.ts",
  );
});

Deno.test("formatToolInput: Glob はパターンを返す", () => {
  assertEquals(
    formatToolInput("Glob", { pattern: "**/*.ts" }),
    "**/*.ts",
  );
});

Deno.test("formatToolInput: Grep はパターンを返す", () => {
  assertEquals(
    formatToolInput("Grep", { pattern: "TODO" }),
    "TODO",
  );
});

Deno.test("formatToolInput: AskUserQuestion は質問文と選択項目を返す", () => {
  const result = formatToolInput("AskUserQuestion", {
    questions: [
      {
        question: "どちらがいい？",
        options: [{ label: "A" }, { label: "B" }],
      },
    ],
  });
  assertEquals(result, "どちらがいい？\n- A\n- B");
});

Deno.test("formatToolInput: AskUserQuestion で options がなければ質問文のみ返す", () => {
  const result = formatToolInput("AskUserQuestion", {
    questions: [{ question: "自由入力してください" }],
  });
  assertEquals(result, "自由入力してください");
});

Deno.test("formatToolInput: AskUserQuestion で questions がなければ空文字を返す", () => {
  assertEquals(formatToolInput("AskUserQuestion", {}), "");
});

Deno.test("formatToolInput: 未知のツールは JSON を返す", () => {
  const result = formatToolInput("Unknown", { foo: "bar" });
  assertEquals(result, JSON.stringify({ foo: "bar" }, null, 2));
});

Deno.test("formatToolInput: 未知のツールで長い入力は 200 文字で切り詰める", () => {
  const longValue = "x".repeat(300);
  const result = formatToolInput("Unknown", { data: longValue });
  assertEquals(result.endsWith("..."), true);
  assertEquals(result.length, 203); // 200 + "..."
});

Deno.test("formatToolInput: null 入力は空文字を返す", () => {
  assertEquals(formatToolInput("Bash", null), "");
});

// --- getPermissionRequestMessage ---

Deno.test("getPermissionRequestMessage: ツール名と入力を含むメッセージを返す", () => {
  const input: PermissionRequestHookInput = {
    ...baseInput,
    hook_event_name: "PermissionRequest",
    tool_name: "Bash",
    tool_input: { command: "rm -rf /tmp/test" },
  };
  const result = getPermissionRequestMessage(input);
  assertEquals(result, "**Bash** の実行許可を求めています\nrm -rf /tmp/test");
});

// --- getMessage (統合テスト) ---

Deno.test("getMessage: Stop イベント", async () => {
  const input: StopHookInput = {
    ...baseInput,
    hook_event_name: "Stop",
    stop_hook_active: false,
    last_assistant_message: "done",
  };
  assertEquals(await getMessage(input), "done");
});

Deno.test("getMessage: Notification イベント", async () => {
  const input: NotificationHookInput = {
    ...baseInput,
    hook_event_name: "Notification",
    message: "hello",
    notification_type: "idle_prompt",
  };
  assertEquals(await getMessage(input), "hello");
});

Deno.test("getMessage: PermissionRequest イベント", async () => {
  const input: PermissionRequestHookInput = {
    ...baseInput,
    hook_event_name: "PermissionRequest",
    tool_name: "Write",
    tool_input: { file_path: "/tmp/out.ts" },
  };
  assertEquals(
    await getMessage(input),
    "**Write** の実行許可を求めています\n/tmp/out.ts",
  );
});

// --- getEventDescriptor ---

Deno.test("getEventDescriptor: 既知イベントは対応する属性を返す", () => {
  assertEquals(getEventDescriptor("Stop").label, "完了");
  assertEquals(getEventDescriptor("StopFailure").label, "失敗");
  assertEquals(getEventDescriptor("Notification").label, "確認待ち");
  assertEquals(getEventDescriptor("PermissionRequest").label, "許可待ち");
});

// --- getStopFailureMessage ---

Deno.test("getStopFailureMessage: error_type があれば種別を含める", () => {
  const input = {
    ...baseInput,
    hook_event_name: "StopFailure",
    error_type: "rate_limit",
  } as unknown as Parameters<typeof getStopFailureMessage>[0];
  assertEquals(
    getStopFailureMessage(input),
    "API エラーでターンが終了: rate_limit",
  );
});

Deno.test("getStopFailureMessage: error type が無ければ固定文言を返す", () => {
  const input = {
    ...baseInput,
    hook_event_name: "StopFailure",
  } as unknown as Parameters<typeof getStopFailureMessage>[0];
  assertEquals(getStopFailureMessage(input), "API エラーでターンが終了");
});

Deno.test("getEventDescriptor: 未知イベントは既定値を返す", () => {
  const descriptor = getEventDescriptor("Unknown");
  assertEquals(descriptor.label, "通知");
  assertEquals(descriptor.tag, "speech_balloon");
});

// --- buildNotification ---

Deno.test("buildNotification: タイトルはラベルとプロジェクト名を結合する", async () => {
  const input: StopHookInput = {
    ...baseInput,
    cwd: "/home/user/dev/dotfiles",
    hook_event_name: "Stop",
    stop_hook_active: false,
    last_assistant_message: "作業完了",
  };
  const notification = await buildNotification(input);
  assertEquals(notification.title, "完了 | dotfiles");
  assertEquals(notification.body, "作業完了");
  assertEquals(notification.tag, "white_check_mark");
  assertEquals(notification.emoji, "✅");
});

Deno.test("buildNotification: 本文はメッセージをそのまま渡す", async () => {
  const input: StopHookInput = {
    ...baseInput,
    hook_event_name: "Stop",
    stop_hook_active: false,
    last_assistant_message: "x".repeat(200),
  };
  const notification = await buildNotification(input);
  assertEquals(notification.body, "x".repeat(200));
});

// --- buildTerminalSequence ---

const sample = (title: string, body: string) => ({
  title,
  body,
  tag: "white_check_mark",
  emoji: "✅",
});

Deno.test("buildTerminalSequence: OSC 777 の形式になる", () => {
  assertEquals(
    buildTerminalSequence(sample("完了 | dotfiles", "作業完了")),
    "\x1b]777;notify;✅ 完了 | dotfiles;作業完了\x07",
  );
});

Deno.test("buildTerminalSequence: body の改行は空白に畳まれる", () => {
  assertEquals(
    buildTerminalSequence(sample("t", "a\nb\r\nc\rd\te")),
    "\x1b]777;notify;✅ t;a b c d e\x07",
  );
});

Deno.test("buildTerminalSequence: 制御文字は除去され ESC は先頭・BEL は末尾のみ", () => {
  const seq = buildTerminalSequence(
    sample("t\x1b\x07", "a\x1b[31mb\x07c\x9cd\x85e\x7ff"),
  );
  assertEquals(seq, "\x1b]777;notify;✅ t;a[31mbcdef\x07");
  assertEquals(seq.split("\x1b").length - 1, 1);
  assertEquals(seq.split("\x07").length - 1, 1);
});

Deno.test("buildTerminalSequence: title の ; は , になり body の ; は残る", () => {
  assertEquals(
    buildTerminalSequence(sample("a;b", "c;d")),
    "\x1b]777;notify;✅ a,b;c;d\x07",
  );
});

Deno.test("buildTerminalSequence: 長さ超過は … で切り詰められる", () => {
  const body = buildTerminalSequence(sample("t", "x".repeat(300))).split(";")[3]
    .replace("\x07", "");
  assertEquals(Array.from(body).length, 200);
  assertEquals(body.endsWith("…"), true);

  const title = buildTerminalSequence(sample("y".repeat(300), "b")).split(
    ";",
  )[2];
  assertEquals(Array.from(title).length, 100);
  assertEquals(title.endsWith("…"), true);
});

Deno.test("buildTerminalSequence: サロゲートペアを割らずに切り詰める", () => {
  const body = buildTerminalSequence(sample("t", "😀".repeat(300))).split(
    ";",
  )[3]
    .replace("\x07", "");
  assertEquals(body, "😀".repeat(199) + "…");
});

Deno.test("buildTerminalSequence: body が空でも形式は崩れない", () => {
  assertEquals(
    buildTerminalSequence(sample("t", "\x1b\n ")),
    "\x1b]777;notify;✅ t;\x07",
  );
});
