import { assertEquals, assertMatch } from "@std/assert";
import { stripAnsiCode } from "@std/fmt/colors";
import {
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
  assertMatch(coloredProgressBar(69, 10), /^\x1b\[32m/);
});

Deno.test("coloredProgressBar: 70% は黄", () => {
  assertMatch(coloredProgressBar(70, 10), /^\x1b\[33m/);
});

Deno.test("coloredProgressBar: 90% は赤", () => {
  assertMatch(coloredProgressBar(90, 10), /^\x1b\[31m/);
});
