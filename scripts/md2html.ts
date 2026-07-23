#!/usr/bin/env -S deno run --quiet --allow-read --allow-write --allow-run=deno --allow-env

// markdown ファイルを自己完結 HTML (シンタックスハイライト + mermaid 内蔵) へ変換する CLI。
//
// 使い方: md2html <input.md> [--output <path>] [--css <path>] [--title <title>]
//   --output  出力先パス。省略時は stdout。
//   --css     追記するユーザ CSS ファイルのパス。
//   --title   HTML の <title>。省略時は入力ファイル名。
//
// mermaid は npm:mermaid を import する browser 向けエントリ TS を子プロセスの
// `deno bundle` でバンドルし、初回のみ ~/.cache/md2html/ (または
// $XDG_CACHE_HOME/md2html/) へキャッシュする。以降はキャッシュを読むだけなので
// このプロセス自身はネットワーク権限を必要としない (npm:mermaid の取得は
// 子プロセスの deno bundle が自身のモジュール解決として行う)。
//
// 変換ロジックは lib/md2html.ts の convert() に分離し、副作用 (ファイル読み書き・
// mermaid bundle 取得・キャッシュ) はここで組み立てて注入する。

import { parseArgs } from "@std/cli/parse-args";
import { basename } from "@std/path";
import { convert } from "./lib/md2html.ts";
import {
  getMermaidBundle,
  type MermaidBundleDeps,
} from "./lib/md2html-mermaid.ts";

const IMAGE_MIME_TYPES: Record<string, string> = {
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".gif": "image/gif",
  ".svg": "image/svg+xml",
  ".webp": "image/webp",
};

/** 拡張子から画像 mime を引く。対応外は null。 */
function imageMimeType(path: string): string | null {
  const dot = path.lastIndexOf(".");
  if (dot === -1) {
    return null;
  }
  return IMAGE_MIME_TYPES[path.slice(dot).toLowerCase()] ?? null;
}

/** cwd 相対でローカル画像を読み込む。対応外の拡張子・読み込み失敗は null。 */
async function resolveImage(
  src: string,
): Promise<{ mime: string; data: Uint8Array } | null> {
  const mime = imageMimeType(src);
  if (mime === null) {
    return null;
  }
  try {
    const data = await Deno.readFile(src);
    return { mime, data };
  } catch {
    return null;
  }
}

/**
 * entryPath を browser 向けに bundle し outPath へ書き出す。失敗時は throw する。
 *
 * `--no-config` / `--no-lock` で md2html 実行時の cwd 以下にある無関係な
 * deno.json / deno.lock の自動検出を止める。付けないと、cwd に deno プロジェクトが
 * あるディレクトリ (例: 別リポジトリの README.md を変換する) で mermaid ブロックを
 * 変換するたびに、そのプロジェクトの deno.lock へ mermaid の依存木が書き込まれてしまう。
 */
async function bundle(entryPath: string, outPath: string): Promise<void> {
  const { success, stderr } = await new Deno.Command("deno", {
    args: [
      "bundle",
      "--no-config",
      "--no-lock",
      "--platform",
      "browser",
      "--minify",
      "-o",
      outPath,
      entryPath,
    ],
    stdout: "piped",
    stderr: "piped",
  }).output();

  if (!success) {
    throw new Error(
      `deno bundle に失敗した: ${new TextDecoder().decode(stderr).trim()}`,
    );
  }
}

const mermaidBundleDeps: MermaidBundleDeps = {
  env: (key) => Deno.env.get(key),
  readTextFile: (path) => Deno.readTextFile(path),
  writeTextFile: (path, text) => Deno.writeTextFile(path, text),
  mkdir: (path) => Deno.mkdir(path, { recursive: true }),
  makeTempDir: () => Deno.makeTempDir(),
  bundle,
};

/** mermaid の browser 向け bundle を取得する。キャッシュがあればそれを読み、無ければ bundle して保存する。 */
function getMermaidJs(): Promise<string> {
  return getMermaidBundle(mermaidBundleDeps);
}

async function main(): Promise<number> {
  const parsed = parseArgs(Deno.args, {
    string: ["output", "css", "title"],
  });

  const inputPath = parsed._[0];
  if (typeof inputPath !== "string") {
    console.error("md2html: 入力ファイルを指定してください");
    console.error(
      "使い方: md2html <input.md> [--output <path>] [--css <path>] [--title <title>]",
    );
    return 1;
  }

  let markdown: string;
  try {
    markdown = await Deno.readTextFile(inputPath);
  } catch (error) {
    console.error(
      `md2html: 入力ファイルを読み込めない: ${
        error instanceof Error ? error.message : String(error)
      }`,
    );
    return 1;
  }

  let css: string | undefined;
  if (parsed.css) {
    try {
      css = await Deno.readTextFile(parsed.css);
    } catch (error) {
      console.error(
        `md2html: CSS ファイルを読み込めない: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
      return 1;
    }
  }

  const title = parsed.title ?? basename(inputPath);

  let html: string;
  try {
    html = await convert(markdown, {
      title,
      css,
      getMermaidJs,
      resolveImage,
    });
  } catch (error) {
    console.error(
      `md2html: 変換に失敗した: ${
        error instanceof Error ? error.message : String(error)
      }`,
    );
    return 1;
  }

  if (parsed.output) {
    await Deno.writeTextFile(parsed.output, html);
  } else {
    console.log(html);
  }

  return 0;
}

Deno.exit(await main());
