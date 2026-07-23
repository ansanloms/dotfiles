// mermaid の browser 向け bundle 供給の純粋ロジック。
// 副作用 (ファイル読み書き・一時ディレクトリ作成・deno bundle の実行) は
// MermaidBundleDeps 経由で呼び出し側から注入する (clip-image.ts の
// resolveCacheDir(env) の前例に倣う)。

import { MERMAID_ZOOM_JS } from "./md2html-assets.ts";

/** mermaid のキャッシュ・bundle 対象に使う固定バージョン。 */
export const MERMAID_VERSION = "11.16.0";

/**
 * `deno bundle` に渡す browser 向けエントリ TS のソースを生成する。
 * npm:mermaid と ./mermaid-zoom.js を import し、mermaid インスタンスの
 * render・テーマ切替・パン・ズーム DOM 構築は initMermaidZoom へ委譲する。
 */
export function mermaidEntrySource(version: string): string {
  return `import mermaid from "npm:mermaid@${version}";
import { initMermaidZoom } from "./mermaid-zoom.js";

await initMermaidZoom(mermaid);
`;
}

/** FNV-1a (32bit) ハッシュ。依存を増やさずキャッシュキーを作るための自前実装。 */
function fnv1a32(input: string): number {
  let hash = 0x811c9dc5;
  for (let i = 0; i < input.length; i++) {
    hash ^= input.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193);
  }
  return hash >>> 0;
}

/**
 * mermaid entry (mermaidEntrySource) + mermaid-zoom.js の内容から
 * bundle のキャッシュキーに使う 8 桁 hex を作る。これらの内容が変わったら
 * (このライブラリの更新で) 古いキャッシュを再利用してしまわないようにする。
 */
export function bundleRevision(version: string): string {
  const content = mermaidEntrySource(version) + MERMAID_ZOOM_JS;
  return fnv1a32(content).toString(16).padStart(8, "0");
}

/** XDG_CACHE_HOME > HOME/.cache の順で解決し `<cache>/md2html` を返す。 */
export function resolveCacheDir(
  env: (key: string) => string | undefined,
): string {
  const cacheHome = env("XDG_CACHE_HOME") || `${env("HOME")}/.cache`;
  return `${cacheHome}/md2html`;
}

export interface MermaidBundleDeps {
  env: (key: string) => string | undefined;
  readTextFile: (path: string) => Promise<string>;
  writeTextFile: (path: string, text: string) => Promise<void>;
  mkdir: (path: string) => Promise<void>;
  makeTempDir: () => Promise<string>;
  /** entryPath を bundle し outPath へ書き出す。失敗時は throw する。 */
  bundle: (entryPath: string, outPath: string) => Promise<void>;
}

/**
 * mermaid の browser 向け bundle を取得する。キャッシュ
 * (`<cacheDir>/mermaid-<version>-<revision>.bundle.js`) が在ればそれを返し、
 * 無ければ一時ディレクトリにエントリ TS と mermaid-zoom.js を書いて
 * bundle し、キャッシュへ保存してから返す。revision はエントリ・mermaid-zoom.js
 * の内容から作るため、これらの内容が変わると別キャッシュになる。bundle の
 * 失敗はそのまま throw する (握りつぶさない)。
 */
export async function getMermaidBundle(
  deps: MermaidBundleDeps,
  version: string = MERMAID_VERSION,
): Promise<string> {
  const cacheDir = resolveCacheDir(deps.env);
  const revision = bundleRevision(version);
  const cachePath = `${cacheDir}/mermaid-${version}-${revision}.bundle.js`;

  try {
    return await deps.readTextFile(cachePath);
  } catch {
    // キャッシュが無ければ bundle する。
  }

  const tempDir = await deps.makeTempDir();
  const entryPath = `${tempDir}/mermaid-entry.ts`;
  await deps.writeTextFile(entryPath, mermaidEntrySource(version));
  await deps.writeTextFile(`${tempDir}/mermaid-zoom.js`, MERMAID_ZOOM_JS);

  await deps.mkdir(cacheDir);
  await deps.bundle(entryPath, cachePath);

  return await deps.readTextFile(cachePath);
}
