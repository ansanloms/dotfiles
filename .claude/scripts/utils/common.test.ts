import { assert, assertEquals } from "@std/assert";
import { bgBlue, stripAnsiCode, white } from "@std/fmt/colors";
import {
  buildInlineProgressBar,
  buildProgressBar,
  coloredProgressBar,
  formatCompact,
  tailLines,
} from "./common.ts";

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

// --- formatCompact ---

Deno.test("formatCompact: 1000 未満はそのまま返す", () => {
  assertEquals(formatCompact(999), "999");
});

Deno.test("formatCompact: 1000 以上は K 表記にする", () => {
  assertEquals(formatCompact(1000), "1K");
});

Deno.test("formatCompact: 1500 は 1.5K になる", () => {
  assertEquals(formatCompact(1500), "1.5K");
});

Deno.test("formatCompact: 1000000 は 1M になる", () => {
  assertEquals(formatCompact(1_000_000), "1M");
});

// --- buildProgressBar ---

Deno.test("buildProgressBar: 0% は全て未完了文字になる", () => {
  assertEquals(buildProgressBar(0, 10), "░".repeat(10));
});

Deno.test("buildProgressBar: 100% は全て完了文字になる", () => {
  assertEquals(buildProgressBar(100, 10), "▓".repeat(10));
});

Deno.test("buildProgressBar: 50% は半分が完了文字になる", () => {
  assertEquals(buildProgressBar(50, 10), "▓".repeat(5) + "░".repeat(5));
});

Deno.test("buildProgressBar: width ぶんの文字数になる", () => {
  assertEquals(buildProgressBar(30, 20).length, 20);
});

// --- coloredProgressBar ---

Deno.test("coloredProgressBar: ANSI コードを除いた文字列が buildProgressBar と一致する", () => {
  assertEquals(
    stripAnsiCode(coloredProgressBar(50, 20)),
    buildProgressBar(50, 20),
  );
});

Deno.test("coloredProgressBar: 69% は緑", () => {
  assert(coloredProgressBar(69, 10).startsWith("\x1b[32m"));
});

Deno.test("coloredProgressBar: 70% は黄", () => {
  assert(coloredProgressBar(70, 10).startsWith("\x1b[33m"));
});

Deno.test("coloredProgressBar: 90% は赤", () => {
  assert(coloredProgressBar(90, 10).startsWith("\x1b[31m"));
});

// --- buildInlineProgressBar ---

Deno.test("buildInlineProgressBar: ANSI コードを除くと width ぶんの文字数になる", () => {
  assertEquals(
    stripAnsiCode(buildInlineProgressBar(50, " label ", 20)).length,
    20,
  );
});

Deno.test("buildInlineProgressBar: ラベルが先頭に埋め込まれ残りは空白になる", () => {
  assertEquals(
    stripAnsiCode(buildInlineProgressBar(50, "abc", 10)),
    "abc" + " ".repeat(7),
  );
});

Deno.test("buildInlineProgressBar: ラベルが width を超える場合は末尾を ... で省略する", () => {
  assertEquals(
    stripAnsiCode(buildInlineProgressBar(0, "0123456789ABC", 10)),
    "0123456...",
  );
});

Deno.test("buildInlineProgressBar: width が ... に満たないときは省略記号なしで切り詰める", () => {
  assertEquals(
    stripAnsiCode(buildInlineProgressBar(0, "0123456789", 3)),
    "012",
  );
});

Deno.test("buildInlineProgressBar: ラベルが filled / unfilled の境界をまたいでも文字列が欠けない", () => {
  assertEquals(
    stripAnsiCode(buildInlineProgressBar(50, "abcdefgh", 10)),
    "abcdefgh" + " ".repeat(2),
  );
});

Deno.test("buildInlineProgressBar: 69% は緑背景", () => {
  const bar = buildInlineProgressBar(69, "x", 10);
  assert(bar.includes("\x1b[42m"));
  assert(!bar.includes("\x1b[43m"));
  assert(!bar.includes("\x1b[41m"));
});

Deno.test("buildInlineProgressBar: 70% は黄背景", () => {
  assert(buildInlineProgressBar(70, "x", 10).includes("\x1b[43m"));
});

Deno.test("buildInlineProgressBar: 90% は赤背景", () => {
  assert(buildInlineProgressBar(90, "x", 10).includes("\x1b[41m"));
});

Deno.test("buildInlineProgressBar: unfilled 領域は暗いグレー背景になる", () => {
  assert(buildInlineProgressBar(50, "x", 10).includes("\x1b[100m"));
});

Deno.test("buildInlineProgressBar: scheme.low で 70% 未満の色を差し替えられる", () => {
  const bar = buildInlineProgressBar(50, "x", 10, {
    low: (s) => bgBlue(white(s)),
  });
  assert(bar.includes("\x1b[44m"));
  assert(!bar.includes("\x1b[42m"));
});

Deno.test("buildInlineProgressBar: scheme.low だけ指定しても 70% 以上は既定の黄背景になる", () => {
  const bar = buildInlineProgressBar(70, "x", 10, {
    low: (s) => bgBlue(white(s)),
  });
  assert(bar.includes("\x1b[43m"));
  assert(!bar.includes("\x1b[44m"));
});

Deno.test("buildInlineProgressBar: scheme.low だけ指定しても 90% 以上は既定の赤背景になる", () => {
  const bar = buildInlineProgressBar(90, "x", 10, {
    low: (s) => bgBlue(white(s)),
  });
  assert(bar.includes("\x1b[41m"));
  assert(!bar.includes("\x1b[44m"));
});
