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
import { CODE_COPY_JS, MARKDOWN_THEME_CSS } from "./assets.ts";

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

/**
 * hast の要素 properties からクラス名の配列を読む。canonical な `className`
 * (配列) だけでなく、`@shikijs/rehype` の addLanguageClass が出力する生の
 * `class` (文字列または配列) にも対応する。
 */
function getClassNames(properties: HastNode | undefined): string[] {
  if (!properties) {
    return [];
  }
  const raw = properties.className ?? properties.class;
  if (Array.isArray(raw)) {
    return raw as string[];
  }
  if (typeof raw === "string") {
    return raw.split(/\s+/).filter((name) => name !== "");
  }
  return [];
}

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

/**
 * http(s): / data: 以外の img src を扱う rehype プラグイン。resolveImage が
 * 画像を返せば data URI へ差し替え、null を返せば (ローカルに実体が無ければ)
 * `<div class="img-ph">alt（画像プレースホルダ）</div>` へ置換する。
 */
function rehypeInlineImages(resolveImage: ConvertOptions["resolveImage"]) {
  return async (tree: HastNode) => {
    const targets: Array<
      { node: HastNode; parent: HastNode; index: number }
    > = [];
    visit(
      tree,
      "element",
      (
        node: HastNode,
        index: number | undefined,
        parent: HastNode | undefined,
      ) => {
        if (
          node.tagName === "img" &&
          typeof node.properties?.src === "string" &&
          parent && typeof index === "number"
        ) {
          targets.push({ node, parent, index });
        }
      },
    );

    for (const { node, parent, index } of targets) {
      const src = node.properties.src as string;
      if (/^(https?:|data:)/i.test(src)) {
        continue;
      }

      const resolved = await resolveImage(src);
      if (resolved) {
        node.properties.src = `data:${resolved.mime};base64,${
          encodeBase64(resolved.data)
        }`;
        continue;
      }

      const alt = typeof node.properties.alt === "string"
        ? node.properties.alt
        : "";
      const label = alt !== ""
        ? `${alt}（画像プレースホルダ）`
        : "画像（画像プレースホルダ）";
      parent.children[index] = {
        type: "element",
        tagName: "div",
        properties: { className: ["img-ph"] },
        children: [{ type: "text", value: label }],
      };
    }
  };
}

/** table を `<div class="table-wrap">` で包む rehype プラグイン。 */
function rehypeTableWrap() {
  return (tree: HastNode) => {
    visit(
      tree,
      "element",
      (
        node: HastNode,
        index: number | undefined,
        parent: HastNode | undefined,
      ) => {
        if (
          node.tagName !== "table" || !parent || typeof index !== "number"
        ) {
          return;
        }
        parent.children[index] = {
          type: "element",
          tagName: "div",
          properties: { className: ["table-wrap"] },
          children: [node],
        };
      },
    );
  };
}

/**
 * shiki 変換後の `pre` (mermaid は既に pre.mermaid へ退避済みのため対象外) を
 * `<div class="code-block">` で包み、言語ラベル (フェンスに言語指定があった
 * 場合のみ) と `<button class="code-copy">` を付ける rehype プラグイン。
 * @shikijs/rehype より後に適用する。コードブロックを 1 つでも変換したら
 * used.value を true にする。
 */
function rehypeCodeBlocks(used: { value: boolean }) {
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

        const classNames = getClassNames(codeChild.properties);
        const languageClass = classNames.find((name) =>
          name.startsWith("language-")
        );
        // defaultLanguage: "text" の fallback と区別できないため、
        // 解決後の言語が "text" のときはラベルを出さない。
        const language = languageClass
          ? languageClass.slice("language-".length)
          : "";

        const children: HastNode[] = [];
        if (language !== "" && language !== "text") {
          children.push({
            type: "element",
            tagName: "span",
            properties: { className: ["code-lang"] },
            children: [{ type: "text", value: language }],
          });
        }
        children.push(node);
        children.push({
          type: "element",
          tagName: "button",
          properties: { className: ["code-copy"], type: "button" },
          children: [{ type: "text", value: "コピー" }],
        });

        parent.children[index] = {
          type: "element",
          tagName: "div",
          properties: { className: ["code-block"] },
          children,
        };
        used.value = true;
      },
    );
  };
}

/** 見出し 1 件分の TOC エントリ (h2/h3 のみ)。 */
interface TocEntry {
  depth: 2 | 3;
  id: string;
  text: string;
}

/**
 * 見出しテキストから id 用の slug を生成する。前後 trim → 小文字化 →
 * 空白の連続を "-" 1 個に → 文字・数字・"-"・"_" 以外を除去 → 連続する
 * "-" を 1 個に潰し、先頭・末尾の "-" を除去する。日本語見出しはそのまま
 * (文字として) 残る。
 */
export function slugify(text: string): string {
  return text
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "-")
    .replace(/[^\p{L}\p{N}\-_]/gu, "")
    .replace(/-+/g, "-")
    .replace(/^-+|-+$/g, "");
}

/**
 * h1〜h6 要素へ id を付与する rehype プラグイン。@shikijs/rehype より後、
 * rehype-stringify より前に適用する。既に id を持つ見出し (raw HTML 由来) は
 * その id をそのまま使い、書き換えない (文書内リンクを壊すため)。id 未設定の
 * 見出しへ slug を生成する際は、既存 id との衝突も避ける必要があるため 2 パスで
 * 走査する。第 1 パスで全見出しの既存 id を予約し、第 2 パスで未設定の見出しへ
 * (予約済みも含めて) 重複しない slug を割り当てる。生成した slug が空なら
 * "section" へフォールバックし、重複する場合は "-1", "-2" ... を付けて一意化する。
 *
 * TOC (headings) には h2/h3 のみを、テキストは h1〜h4 へのアンカー追加より前に
 * 抽出した状態で収集する。h1〜h4 には見出し末尾へ `<a class="anchor">` を追加する。
 */
function rehypeHeadingIds(headings: TocEntry[]) {
  return (tree: HastNode) => {
    const usedIds = new Set<string>();

    // 第 1 パス: 既存 id を全て予約する。
    visit(tree, "element", (node: HastNode) => {
      const match = /^h([1-6])$/.exec(node.tagName ?? "");
      if (!match) {
        return;
      }
      const existingId = node.properties?.id;
      if (typeof existingId === "string" && existingId !== "") {
        usedIds.add(existingId);
      }
    });

    // 第 2 パス: id 未設定の見出しへ slug を生成し、TOC (h2/h3) を収集し、
    // h1〜h4 へアンカーを追加する。
    visit(tree, "element", (node: HastNode) => {
      const match = /^h([1-6])$/.exec(node.tagName ?? "");
      if (!match) {
        return;
      }

      const depth = Number(match[1]);
      const text = extractText(node);

      node.properties = node.properties ?? {};
      let id = typeof node.properties.id === "string" ? node.properties.id : "";

      if (id === "") {
        const base = slugify(text) || "section";
        id = base;
        let suffix = 1;
        while (usedIds.has(id)) {
          id = `${base}-${suffix}`;
          suffix += 1;
        }
        node.properties.id = id;
        usedIds.add(id);
      }

      if (depth === 2 || depth === 3) {
        headings.push({ depth, id, text });
      }

      if (depth >= 1 && depth <= 4) {
        node.children = node.children ?? [];
        node.children.push({
          type: "element",
          tagName: "a",
          properties: {
            className: ["anchor"],
            href: `#${id}`,
            ariaHidden: "true",
          },
          children: [{ type: "text", value: "#" }],
        });
      }
    });
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

/** markdown を自己完結 HTML へ変換する。 */
export async function convert(
  markdown: string,
  options: ConvertOptions,
): Promise<string> {
  const mermaidUsed = { value: false };
  const codeBlockUsed = { value: false };
  const headings: TocEntry[] = [];

  const file = await unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(remarkRehype, { allowDangerousHtml: true })
    .use(rehypeRaw)
    .use(rehypeMermaid, mermaidUsed)
    .use(rehypeShiki, {
      themes: { light: "github-light", dark: "github-dark" },
      defaultLanguage: "text",
      fallbackLanguage: "text",
      addLanguageClass: true,
    })
    .use(rehypeHeadingIds, headings)
    .use(rehypeCodeBlocks, codeBlockUsed)
    .use(rehypeTableWrap)
    .use(rehypeInlineImages, options.resolveImage)
    .use(rehypeStringify, { allowDangerousHtml: true })
    .process(markdown);

  const body = String(file);

  let mermaidScript = "";
  if (mermaidUsed.value) {
    const js = await options.getMermaidJs();
    mermaidScript = `<script type="module">${escapeScriptClose(js)}</script>`;
  }

  let layoutStyle = "";
  let tocAside = "";
  if (headings.length > 0) {
    const items = headings
      .map((heading) =>
        `<li><a class="lv-${heading.depth}" href="#${escapeHtml(heading.id)}">${
          escapeHtml(heading.text)
        }</a></li>`
      )
      .join("");
    tocAside =
      `<aside class="toc" aria-label="目次"><p class="toc-title">目次</p><ul>${items}</ul></aside>`;
  } else {
    layoutStyle = ' style="grid-template-columns: minmax(0, 1fr)"';
  }

  let codeCopyScript = "";
  if (codeBlockUsed.value) {
    codeCopyScript = `<script>${escapeScriptClose(CODE_COPY_JS)}</script>`;
  }

  return [
    "<!doctype html>",
    '<html lang="ja">',
    "<head>",
    '<meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1">',
    `<title>${escapeHtml(options.title)}</title>`,
    "<style>",
    MARKDOWN_THEME_CSS,
    options.css ?? "",
    "</style>",
    "</head>",
    "<body>",
    '<header class="site-header"><div class="inner"></div></header>',
    `<div class="layout"${layoutStyle}>`,
    `<article class="md">${body}</article>`,
    tocAside,
    "</div>",
    codeCopyScript,
    mermaidScript,
    "</body>",
    "</html>",
  ].filter((part) => part !== "").join("\n");
}
