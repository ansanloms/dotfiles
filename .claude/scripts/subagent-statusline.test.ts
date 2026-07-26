import { assert, assertEquals } from "@std/assert";
import { unicodeWidth } from "@std/cli";
import { stripAnsiCode } from "@std/fmt/colors";
import {
  buildTaskLine,
  selectResolvedTasks,
  shortenModelId,
  truncateToWidth,
} from "./subagent-statusline.ts";
import type { SubagentTask } from "./types.ts";

const baseTask: SubagentTask & { model: string } = {
  id: "t1",
  name: "implementer",
  type: "implementer",
  status: "running",
  description: "Deno workspace 分割の実装",
  model: "claude-sonnet-5",
};

// --- shortenModelId ---

Deno.test("shortenModelId: 先頭の claude- を除去する", () => {
  assertEquals(shortenModelId("claude-sonnet-5"), "sonnet-5");
});

Deno.test("shortenModelId: 末尾の日付サフィックスを除去する", () => {
  assertEquals(
    shortenModelId("claude-haiku-4-5-20251001"),
    "haiku-4-5",
  );
});

Deno.test("shortenModelId: claude- 接頭辞も日付サフィックスも無ければそのまま返す", () => {
  assertEquals(shortenModelId("sonnet-5"), "sonnet-5");
});

// --- buildTaskLine ---

Deno.test("buildTaskLine: model のみ (effort なし、token なし)", () => {
  const line = stripAnsiCode(buildTaskLine(baseTask, 200));
  assertEquals(
    line,
    "󰚩  sonnet-5 | implementer: Deno workspace 分割の実装",
  );
});

Deno.test("buildTaskLine: effort ありの場合は括弧付きで表示する", () => {
  const line = stripAnsiCode(
    buildTaskLine({ ...baseTask, effort: "high" }, 200),
  );
  assert(line.includes("sonnet-5 (high)"));
});

Deno.test("buildTaskLine: effort が数値の場合もそのまま括弧内に表示する", () => {
  const line = stripAnsiCode(
    buildTaskLine({ ...baseTask, effort: 12000 }, 200),
  );
  assert(line.includes("sonnet-5 (12000)"));
});

Deno.test("buildTaskLine: description が空なら : 区切りを付けない", () => {
  const line = stripAnsiCode(
    buildTaskLine({ ...baseTask, description: "" }, 200),
  );
  assertEquals(line, "󰚩  sonnet-5 | implementer");
});

Deno.test("buildTaskLine: tokenCount と contextWindowSize が両方あれば使用率を付ける", () => {
  const line = stripAnsiCode(
    buildTaskLine(
      { ...baseTask, tokenCount: 45000, contextWindowSize: 200000 },
      200,
    ),
  );
  assert(line.endsWith("| 22% (45K)"));
});

Deno.test("buildTaskLine: tokenCount のみで contextWindowSize が無ければ使用率を付けない", () => {
  const line = stripAnsiCode(
    buildTaskLine({ ...baseTask, tokenCount: 45000 }, 200),
  );
  assertEquals(
    line,
    "󰚩  sonnet-5 | implementer: Deno workspace 分割の実装",
  );
});

Deno.test("buildTaskLine: 90% 以上は赤で着色する", () => {
  const line = buildTaskLine(
    { ...baseTask, tokenCount: 190000, contextWindowSize: 200000 },
    200,
  );
  assert(line.includes("\x1b[31m"));
});

Deno.test("buildTaskLine: 70% 以上 90% 未満は黄で着色する", () => {
  const line = buildTaskLine(
    { ...baseTask, tokenCount: 150000, contextWindowSize: 200000 },
    200,
  );
  assert(line.includes("\x1b[33m"));
});

Deno.test("buildTaskLine: 70% 未満は着色しない", () => {
  const line = buildTaskLine(
    { ...baseTask, tokenCount: 45000, contextWindowSize: 200000 },
    200,
  );
  assert(!line.includes("\x1b[31m"));
  assert(!line.includes("\x1b[33m"));
});

// --- truncateToWidth ---

Deno.test("truncateToWidth: columns 以内ならそのまま返す", () => {
  assertEquals(truncateToWidth("hello", 10), "hello");
});

Deno.test("truncateToWidth: columns を超える場合は ... 付きで幅内に収まる", () => {
  const result = truncateToWidth("0123456789ABCDEF", 10);
  assertEquals(result, "0123456...");
});

Deno.test("truncateToWidth: 全角文字を含む場合も unicodeWidth ベースで幅内に収まる", () => {
  const s = "あいうえおかきくけこ"; // 全角10文字 = 幅20
  const result = truncateToWidth(s, 10);
  assert(result.endsWith("..."));
  assert(unicodeWidth(result) <= 10);
});

Deno.test("truncateToWidth: 幅が ... 自体に満たない場合は省略記号なしで切り詰める", () => {
  const result = truncateToWidth("0123456789", 2);
  assertEquals(result, "01");
});

// --- selectResolvedTasks ---

Deno.test("selectResolvedTasks: model 未解決の task は除外する", () => {
  const tasks: SubagentTask[] = [
    baseTask,
    {
      id: "t2",
      name: "x",
      type: "claude",
      status: "running",
      description: "model 未解決",
    },
  ];
  const result = selectResolvedTasks(tasks);
  assertEquals(result.map((t) => t.id), ["t1"]);
});

Deno.test("selectResolvedTasks: model 解決済みの task はすべて含む", () => {
  const tasks: SubagentTask[] = [
    baseTask,
    { ...baseTask, id: "t3", model: "claude-opus-4-1" },
  ];
  const result = selectResolvedTasks(tasks);
  assertEquals(result.map((t) => t.id), ["t1", "t3"]);
});

Deno.test("selectResolvedTasks: name が欠落した task は除外する", () => {
  const tasks = [
    baseTask,
    {
      id: "t2",
      type: "claude",
      status: "running",
      description: "name 欠落",
      model: "claude-sonnet-5",
    },
  ] as unknown as SubagentTask[];
  const result = selectResolvedTasks(tasks);
  assertEquals(result.map((t) => t.id), ["t1"]);
});

Deno.test("selectResolvedTasks: id が欠落した task は除外する", () => {
  const tasks = [
    baseTask,
    {
      name: "x",
      type: "claude",
      status: "running",
      description: "id 欠落",
      model: "claude-sonnet-5",
    },
  ] as unknown as SubagentTask[];
  const result = selectResolvedTasks(tasks);
  assertEquals(result.map((t) => t.id), ["t1"]);
});
