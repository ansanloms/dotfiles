import { assertEquals, assertStringIncludes } from "@std/assert";
import { convert, type ConvertOptions } from "./md2html.ts";

/** テスト用の最小 ConvertOptions。個別のテストで必要な項目だけ上書きする。 */
function baseOptions(
  overrides: Partial<ConvertOptions> = {},
): ConvertOptions {
  return {
    title: "テスト",
    getMermaidJs: () => Promise.resolve("/* mermaid stub */"),
    resolveImage: () => Promise.resolve(null),
    ...overrides,
  };
}

Deno.test("コードブロックは shiki でインライン style 化される", async () => {
  const html = await convert(
    "```ts\nconst x: number = 1;\n```\n",
    baseOptions(),
  );
  assertStringIncludes(html, 'class="shiki');
  assertStringIncludes(html, "style=");
});

Deno.test("mermaid ブロックは pre.mermaid に変換され mermaid bundle が module script で埋め込まれる", async () => {
  const html = await convert(
    "```mermaid\ngraph TD\n  A --> B\n```\n",
    baseOptions({ getMermaidJs: () => Promise.resolve("/* mermaid stub */") }),
  );
  assertStringIncludes(html, '<pre class="mermaid">');
  assertStringIncludes(html, "graph TD");
  assertStringIncludes(
    html,
    '<script type="module">/* mermaid stub */</script>',
  );
});

Deno.test("mermaid ブロックが無ければ mermaid スクリプトは埋め込まれない", async () => {
  const html = await convert("# hello\n", baseOptions());
  assertEquals(html.includes('<script type="module">'), false);
  assertEquals(html.includes("mermaid stub"), false);
});

Deno.test("未知言語・言語未指定ブロックでも throw しない", async () => {
  const html1 = await convert(
    "```unknown-lang-xyz\nfoo\n```\n",
    baseOptions(),
  );
  assertStringIncludes(html1, "foo");

  const html2 = await convert("```\nbar\n```\n", baseOptions());
  assertStringIncludes(html2, "bar");
});

Deno.test("GFM テーブルは table 要素になる", async () => {
  const html = await convert(
    "| a | b |\n|---|---|\n| 1 | 2 |\n",
    baseOptions(),
  );
  assertStringIncludes(html, "<table>");
  assertStringIncludes(html, "<td>1</td>");
});

Deno.test("ローカル画像は data URI 化される", async () => {
  const data = new Uint8Array([1, 2, 3]);
  const html = await convert(
    "![alt](local.png)\n",
    baseOptions({
      resolveImage: (src) =>
        src === "local.png"
          ? Promise.resolve({ mime: "image/png", data })
          : Promise.resolve(null),
    }),
  );
  assertStringIncludes(html, "data:image/png;base64,");
});

Deno.test("http(s) 画像はそのまま残る", async () => {
  const html = await convert(
    "![alt](https://example.com/a.png)\n",
    baseOptions({
      resolveImage: () => {
        throw new Error("http(s) 画像で resolveImage を呼んではいけない");
      },
    }),
  );
  assertStringIncludes(html, 'src="https://example.com/a.png"');
});

Deno.test("title は HTML エスケープされる", async () => {
  const html = await convert(
    "# hello\n",
    baseOptions({ title: '<script>alert("x")</script>' }),
  );
  assertStringIncludes(
    html,
    "<title>&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;</title>",
  );
});
