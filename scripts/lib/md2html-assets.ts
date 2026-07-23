// md2html-assets/ 配下の CSS / JS を `with { type: "text" }` のテキスト
// インポートで取り込み、文字列定数として export するアグリゲータ。
// これらは純データのため、md2html.ts / md2html-mermaid.ts から直接 import してよい
// (副作用の DI 分離という既存方針は、副作用を持つ処理のみを対象とする)。

import markdownThemeCssRaw from "./md2html-assets/markdown-theme.css" with {
  type: "text",
};
import codeCopyJsRaw from "./md2html-assets/code-copy.js" with {
  type: "text",
};
import mermaidZoomJsRaw from "./md2html-assets/mermaid-zoom.js" with {
  type: "text",
};

/** デザイナ提供の自己完結テーマ CSS (light/dark は prefers-color-scheme を直接参照)。 */
export const MARKDOWN_THEME_CSS = markdownThemeCssRaw;

/** コードブロックのコピー・ボタンを扱う JS。 */
export const CODE_COPY_JS = codeCopyJsRaw;

/** mermaid の render + パン・ズーム DOM 構築を行うクライアント JS (mermaid bundle の entry から import される)。 */
export const MERMAID_ZOOM_JS = mermaidZoomJsRaw;
