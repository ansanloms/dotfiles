// markdown -> 自己完結 HTML 変換の純粋ロジック。
// 副作用 (mermaid bundle の取得・キャッシュ、ローカル画像の読み込み) は
// ConvertOptions 経由で呼び出し側から注入する。

import { unified } from "unified";
import remarkParse from "remark-parse";
import remarkGfm from "remark-gfm";
import remarkRehype from "remark-rehype";
import rehypeRaw from "rehype-raw";
import rehypeStringify from "rehype-stringify";
import rehypeShiki from "@shikijs/rehype";
import { visit } from "unist-util-visit";
import { encodeBase64 } from "@std/encoding/base64";

export interface ResolvedImage {
  mime: string;
  data: Uint8Array;
}

export interface ConvertOptions {
  /** 出力 HTML の <title>。 */
  title: string;
  /** 追記するユーザ CSS (テキスト)。 */
  css?: string;
  /** mermaid ブロックがあるときだけ呼ばれる。mermaid の browser 向け bundle 本文を返す。 */
  getMermaidJs: () => Promise<string>;
  /** http(s): / data: 以外の img src を解決する。読めなければ null を返す。 */
  resolveImage: (src: string) => Promise<ResolvedImage | null>;
}

// remark/rehype 系のパッケージは deno.json に "hast" 型を直接持ち込んでいないため、
// hast ノードは最小限のダックタイピングで扱う (visit へは any として渡す)。
// deno-lint-ignore no-explicit-any
type HastNode = any;

/** テキストノードの value を再帰的に連結する。 */
function extractText(node: HastNode): string {
  if (node.type === "text") {
    return typeof node.value === "string" ? node.value : "";
  }
  if (!Array.isArray(node.children)) {
    return "";
  }
  return node.children.map(extractText).join("");
}

/**
 * `pre > code.language-mermaid` を `<pre class="mermaid">生コード</pre>` へ置換する
 * rehype プラグイン。@shikijs/rehype より前に適用し、shiki のハイライト対象から外す。
 * mermaid ブロックを 1 つでも変換したら used.value を true にする。
 */
function rehypeMermaid(used: { value: boolean }) {
  return (tree: HastNode) => {
    visit(
      tree,
      "element",
      (
        node: HastNode,
        index: number | undefined,
        parent: HastNode | undefined,
      ) => {
        if (node.tagName !== "pre" || !parent || typeof index !== "number") {
          return;
        }

        const codeChild = (node.children ?? []).find(
          (child: HastNode) =>
            child.type === "element" && child.tagName === "code",
        );
        if (!codeChild) {
          return;
        }

        const classNames: string[] = Array.isArray(
            codeChild.properties?.className,
          )
          ? codeChild.properties.className
          : [];
        if (!classNames.includes("language-mermaid")) {
          return;
        }

        parent.children[index] = {
          type: "element",
          tagName: "pre",
          properties: { className: ["mermaid"] },
          children: [{ type: "text", value: extractText(codeChild) }],
        };
        used.value = true;
      },
    );
  };
}

/** http(s): / data: 以外の img src を resolveImage で data URI へ差し替える rehype プラグイン。 */
function rehypeInlineImages(resolveImage: ConvertOptions["resolveImage"]) {
  return async (tree: HastNode) => {
    const targets: HastNode[] = [];
    visit(tree, "element", (node: HastNode) => {
      if (
        node.tagName === "img" && typeof node.properties?.src === "string"
      ) {
        targets.push(node);
      }
    });

    for (const node of targets) {
      const src = node.properties.src as string;
      if (/^(https?:|data:)/i.test(src)) {
        continue;
      }

      const resolved = await resolveImage(src);
      if (!resolved) {
        continue;
      }

      node.properties.src = `data:${resolved.mime};base64,${
        encodeBase64(resolved.data)
      }`;
    }
  };
}

/** HTML エスケープ (title 埋め込み用)。 */
function escapeHtml(text: string): string {
  return text
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

/** 埋め込み <script> 内の `</script` によるタグの早期終了を防ぐ。 */
function escapeScriptClose(js: string): string {
  return js.replace(/<\/script/gi, "<\\/script");
}

const DEFAULT_CSS = `
body {
  max-width: 860px;
  margin: 2rem auto;
  padding: 0 1rem;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Hiragino Kaku Gothic ProN", "Noto Sans JP", sans-serif;
  line-height: 1.7;
}
pre {
  overflow-x: auto;
  padding: 0.75rem;
}
table {
  border-collapse: collapse;
}
table th,
table td {
  border: 1px solid #d0d7de;
  padding: 0.35rem 0.6rem;
}
img {
  max-width: 100%;
}
`;

/** markdown を自己完結 HTML へ変換する。 */
export async function convert(
  markdown: string,
  options: ConvertOptions,
): Promise<string> {
  const mermaidUsed = { value: false };

  const file = await unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(remarkRehype, { allowDangerousHtml: true })
    .use(rehypeRaw)
    .use(rehypeMermaid, mermaidUsed)
    .use(rehypeShiki, {
      theme: "github-light",
      defaultLanguage: "text",
      fallbackLanguage: "text",
    })
    .use(rehypeInlineImages, options.resolveImage)
    .use(rehypeStringify, { allowDangerousHtml: true })
    .process(markdown);

  const body = String(file);

  let mermaidScript = "";
  if (mermaidUsed.value) {
    const js = await options.getMermaidJs();
    mermaidScript = `<script type="module">${escapeScriptClose(js)}</script>`;
  }

  return [
    "<!doctype html>",
    '<html lang="ja">',
    "<head>",
    '<meta charset="utf-8">',
    `<title>${escapeHtml(options.title)}</title>`,
    "<style>",
    DEFAULT_CSS,
    options.css ?? "",
    "</style>",
    "</head>",
    "<body>",
    body,
    mermaidScript,
    "</body>",
    "</html>",
  ].join("\n");
}
