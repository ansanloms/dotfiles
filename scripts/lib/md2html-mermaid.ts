// mermaid の browser 向け bundle 供給の純粋ロジック。
// 副作用 (ファイル読み書き・一時ディレクトリ作成・deno bundle の実行) は
// MermaidBundleDeps 経由で呼び出し側から注入する (clip-image.ts の
// resolveCacheDir(env) の前例に倣う)。

/** mermaid のキャッシュ・bundle 対象に使う固定バージョン。 */
export const MERMAID_VERSION = "11.16.0";

/**
 * `deno bundle` に渡す browser 向けエントリ TS のソースを生成する。
 * npm:mermaid を import し、pre.mermaid を対象に初期化・実行する。
 */
export function mermaidEntrySource(version: string): string {
  return `import mermaid from "npm:mermaid@${version}";

mermaid.initialize({ startOnLoad: false });
await mermaid.run({ querySelector: "pre.mermaid", suppressErrors: true });
`;
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
 * (`<cacheDir>/mermaid-<version>.bundle.js`) が在ればそれを返し、無ければ
 * 一時ディレクトリにエントリ TS を書いて bundle し、キャッシュへ保存してから
 * 返す。bundle の失敗はそのまま throw する (握りつぶさない)。
 */
export async function getMermaidBundle(
  deps: MermaidBundleDeps,
  version: string = MERMAID_VERSION,
): Promise<string> {
  const cacheDir = resolveCacheDir(deps.env);
  const cachePath = `${cacheDir}/mermaid-${version}.bundle.js`;

  try {
    return await deps.readTextFile(cachePath);
  } catch {
    // キャッシュが無ければ bundle する。
  }

  const tempDir = await deps.makeTempDir();
  const entryPath = `${tempDir}/mermaid-entry.ts`;
  await deps.writeTextFile(entryPath, mermaidEntrySource(version));

  await deps.mkdir(cacheDir);
  await deps.bundle(entryPath, cachePath);

  return await deps.readTextFile(cachePath);
}
