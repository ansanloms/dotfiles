import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import type {
  NotificationHookInput,
  PermissionRequestHookInput,
  StopHookInput,
} from "npm:@anthropic-ai/claude-agent-sdk@latest";
import {
  formatToolInput,
  getLastAssistantMessage,
  getMessage,
  getNotificationMessage,
  getPermissionRequestMessage,
  getStopMessage,
  tailLines,
} from "./utils.ts";

const baseInput = {
  session_id: "test-session",
  transcript_path: "",
  cwd: "/tmp",
};

// --- tailLines ---

Deno.test("tailLines: 空ファイルは空配列を返す", async () => {
  const tmp = await Deno.makeTempFile();
  try {
    const result = await tailLines(tmp, 5);
    assertEquals(result, []);
  } finally {
    await Deno.remove(tmp);
  }
});

Deno.test("tailLines: 指定行数分の末尾行を返す", async () => {
  const tmp = await Deno.makeTempFile();
  try {
    await Deno.writeTextFile(tmp, "line1\nline2\nline3\nline4\nline5\n");
    const result = await tailLines(tmp, 3);
    assertEquals(result, ["line3", "line4", "line5"]);
  } finally {
    await Deno.remove(tmp);
  }
});

Deno.test("tailLines: ファイルの行数が n 未満の場合は全行を返す", async () => {
  const tmp = await Deno.makeTempFile();
  try {
    await Deno.writeTextFile(tmp, "line1\nline2\n");
    const result = await tailLines(tmp, 10);
    assertEquals(result, ["line1", "line2"]);
  } finally {
    await Deno.remove(tmp);
  }
});

// --- getLastAssistantMessage ---

Deno.test("getLastAssistantMessage: テキストメッセージを抽出する", async () => {
  const tmp = await Deno.makeTempFile();
  try {
    const lines = [
      JSON.stringify({ message: { content: [{ type: "tool_use", name: "Bash" }] } }),
      JSON.stringify({ message: { content: [{ type: "text", text: "hello world" }] } }),
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
      JSON.stringify({ message: { content: [{ type: "tool_use", name: "Read" }] } }),
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
      JSON.stringify({ message: { content: [{ type: "text", text: "from transcript" }] } }) + "\n",
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
