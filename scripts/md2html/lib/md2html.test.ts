import { assertEquals, assertStringIncludes } from "@std/assert";
import { convert, type ConvertOptions, slugify } from "./md2html.ts";

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

Deno.test("GFM テーブルは div.table-wrap で包まれる", async () => {
  const html = await convert(
    "| a | b |\n|---|---|\n| 1 | 2 |\n",
    baseOptions(),
  );
  assertStringIncludes(html, '<div class="table-wrap"><table>');
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

Deno.test("resolveImage が null を返すローカル画像は img-ph へ置換される (alt あり)", async () => {
  const html = await convert(
    "![サンプル画像](./not-found.png)\n",
    baseOptions(),
  );
  assertStringIncludes(
    html,
    '<div class="img-ph">サンプル画像（画像プレースホルダ）</div>',
  );
  assertEquals(html.includes("<img"), false);
});

Deno.test("resolveImage が null を返すローカル画像は img-ph へ置換される (alt 空)", async () => {
  const html = await convert(
    "![](./not-found.png)\n",
    baseOptions(),
  );
  assertStringIncludes(
    html,
    '<div class="img-ph">画像（画像プレースホルダ）</div>',
  );
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

Deno.test("header.site-header と article.md で本文が構成される", async () => {
  const html = await convert("# hello\n", baseOptions());
  assertStringIncludes(
    html,
    '<header class="site-header"><div class="inner"></div></header>',
  );
  assertStringIncludes(html, '<article class="md">');
});

Deno.test("見出しに id が付き h2/h3 のみ TOC (aside.toc) に収集される", async () => {
  const html = await convert(
    "# Hello World\n\n## Sub Heading\n\n### Sub Sub\n",
    baseOptions(),
  );
  assertStringIncludes(html, '<h1 id="hello-world">');
  assertStringIncludes(html, '<h2 id="sub-heading">');
  assertStringIncludes(html, '<h3 id="sub-sub">');
  assertStringIncludes(html, '<aside class="toc" aria-label="目次">');
  assertStringIncludes(
    html,
    '<li><a class="lv-2" href="#sub-heading">Sub Heading</a></li>',
  );
  assertStringIncludes(
    html,
    '<li><a class="lv-3" href="#sub-sub">Sub Sub</a></li>',
  );
  // h1 は TOC に含まれない (lv-1 は出力されない)。
  assertEquals(html.includes('class="lv-1"'), false);
});

Deno.test("h1 しか無い文書では TOC が出ず layout が 1 カラムになる", async () => {
  const html = await convert("# hello\n", baseOptions());
  assertEquals(html.includes('<aside class="toc"'), false);
  assertStringIncludes(
    html,
    '<div class="layout" style="grid-template-columns: minmax(0, 1fr)">',
  );
});

Deno.test("h1〜h4 の見出しには anchor が付き、h5/h6 には付かない", async () => {
  const html = await convert(
    "# H1\n\n## H2\n\n### H3\n\n#### H4\n\n##### H5\n\n###### H6\n",
    baseOptions(),
  );
  assertStringIncludes(
    html,
    '<h1 id="h1">H1<a class="anchor" href="#h1" aria-hidden="true">#</a></h1>',
  );
  assertStringIncludes(
    html,
    '<h4 id="h4">H4<a class="anchor" href="#h4" aria-hidden="true">#</a></h4>',
  );
  assertStringIncludes(html, '<h5 id="h5">H5</h5>');
  assertStringIncludes(html, '<h6 id="h6">H6</h6>');
});

Deno.test("TOC のテキストにアンカーの # が混入しない", async () => {
  const html = await convert("## Sub Heading\n", baseOptions());
  assertStringIncludes(
    html,
    '<li><a class="lv-2" href="#sub-heading">Sub Heading</a></li>',
  );
});

Deno.test("同名見出しの id は -1 連番で一意化される", async () => {
  const html = await convert("# 概要\n\n## 概要\n", baseOptions());
  assertStringIncludes(html, '<h1 id="概要">');
  assertStringIncludes(html, '<h2 id="概要-1">');
});

Deno.test("raw HTML 見出しの既存 id と自動生成 id が衝突しない (既存が後)", async () => {
  const html = await convert(
    '## Foo\n\n<h2 id="foo">Bar</h2>\n',
    baseOptions(),
  );
  assertStringIncludes(html, 'id="foo-1"');
  assertStringIncludes(html, 'id="foo">Bar');
});

Deno.test("raw HTML 見出しの既存 id と自動生成 id が衝突しない (既存が先)", async () => {
  const html = await convert(
    '<h2 id="foo">Bar</h2>\n\n## Foo\n',
    baseOptions(),
  );
  assertStringIncludes(html, 'id="foo">Bar');
  assertStringIncludes(html, 'id="foo-1"');
});

Deno.test("slugify: 日本語見出し・空白・記号を扱う", () => {
  assertEquals(slugify("  Hello World  "), "hello-world");
  assertEquals(slugify("日本語 見出し"), "日本語-見出し");
  assertEquals(slugify("a/b?c#d"), "abcd");
  assertEquals(slugify("   "), "");
});

Deno.test("slugify: 記号除去で生じる連続ハイフンを 1 個に潰し、先頭・末尾のハイフンを除去する", () => {
  assertEquals(slugify("code in heading & raw"), "code-in-heading-raw");
  assertEquals(slugify("- leading and trailing -"), "leading-and-trailing");
});

Deno.test("コードブロックの出力は shiki-dark を含む (デュアルテーマ)", async () => {
  const html = await convert(
    "```ts\nconst x: number = 1;\n```\n",
    baseOptions(),
  );
  assertStringIncludes(html, "--shiki-dark");
});

Deno.test("テーマ CSS (MARKDOWN_THEME_CSS) が注入されている", async () => {
  const html = await convert("# hello\n", baseOptions());
  assertStringIncludes(html, ".site-header");
  assertStringIncludes(html, "--accent:");
});

Deno.test("コードブロックは div.code-block で包まれ、言語指定時のみラベルが付く", async () => {
  const html = await convert(
    "```ts\nconst x: number = 1;\n```\n",
    baseOptions(),
  );
  assertStringIncludes(html, '<div class="code-block">');
  assertStringIncludes(html, '<span class="code-lang">ts</span>');
  assertStringIncludes(
    html,
    '<button class="code-copy" type="button">コピー</button>',
  );
});

Deno.test("言語未指定のコードブロックには code-lang ラベルが付かない", async () => {
  const html = await convert("```\nplain\n```\n", baseOptions());
  assertStringIncludes(html, '<div class="code-block">');
  assertEquals(html.includes('<span class="code-lang">'), false);
});

Deno.test("CODE_COPY_JS はコードブロックがあるときのみ注入される", async () => {
  const withCode = await convert(
    "```ts\nconst x = 1;\n```\n",
    baseOptions(),
  );
  assertStringIncludes(withCode, "navigator.clipboard");

  const withoutCode = await convert("# hello\n", baseOptions());
  assertEquals(withoutCode.includes("navigator.clipboard"), false);
});

Deno.test("見出しが無い入力では TOC 分の空行が残らない", async () => {
  const html = await convert("本文だけ。\n", baseOptions());
  assertStringIncludes(html, "</article>\n</div>\n</body>");
});

Deno.test("タスクリストは task-list-item / contains-task-list class を持つ", async () => {
  const html = await convert("- [x] done\n- [ ] todo\n", baseOptions());
  assertStringIncludes(html, '<ul class="contains-task-list">');
  assertStringIncludes(html, '<li class="task-list-item">');
});

Deno.test("convert: 複数言語のコードブロックがそれぞれ shiki 出力になる", async () => {
  const html = await convert(
    "```ts\nconst x: number = 1;\n```\n\n```python\nprint(1)\n```\n",
    baseOptions(),
  );
  assertStringIncludes(html, "const");
  assertStringIncludes(html, "print");
  const shikiCount = html.split('class="shiki').length - 1;
  assertEquals(shikiCount, 2);
  assertStringIncludes(html, "language-ts");
  assertStringIncludes(html, "language-python");
});

Deno.test("convert: mermaid と ts の混在では mermaid は pre.mermaid、ts は shiki 出力になる", async () => {
  const html = await convert(
    "```mermaid\ngraph TD\n  A --> B\n```\n\n```ts\nconst x = 1;\n```\n",
    baseOptions(),
  );
  assertStringIncludes(html, '<pre class="mermaid">');
  assertStringIncludes(html, 'class="shiki');
});

Deno.test("Object.prototype のプロパティ名と同名のフェンス言語でも throw しない", async () => {
  const html = await convert(
    "```constructor\nfoo\n```\n",
    baseOptions(),
  );
  assertStringIncludes(html, "foo");
  assertStringIncludes(html, "language-text");
});

Deno.test("markdown フェンス (コンテナ grammar) を含む文書も throw せず変換できる", async () => {
  const html = await convert(
    "````markdown\n# inner\n\n```python\nprint(1)\n```\n````\n",
    baseOptions(),
  );
  assertStringIncludes(html, "print");
  assertStringIncludes(html, 'class="shiki');
});

Deno.test("アラート記法は markdown-alert へ変換される", async () => {
  for (const marker of ["NOTE", "TIP", "IMPORTANT", "WARNING", "CAUTION"]) {
    const html = await convert(
      `> [!${marker}]\n> 本文テキスト\n`,
      baseOptions(),
    );
    const type = marker.toLowerCase();
    assertStringIncludes(
      html,
      `class="markdown-alert markdown-alert-${type}"`,
    );
    assertStringIncludes(html, 'class="markdown-alert-title"');
    assertStringIncludes(html, "本文テキスト");
  }
});

Deno.test("マーカーの無い blockquote はアラートにならない", async () => {
  const html = await convert("> ただの引用\n", baseOptions());
  assertEquals(html.includes('class="markdown-alert'), false);
  assertStringIncludes(html, "<blockquote>");
});

Deno.test("TOC に可視ラベルが出ない", async () => {
  const html = await convert("## 見出し\n", baseOptions());
  assertEquals(html.includes("toc-title"), false);
  assertStringIncludes(html, '<aside class="toc" aria-label="目次">');
});
