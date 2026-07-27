import { assertEquals } from "@std/assert";
import { tailLines } from "./common.ts";

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
