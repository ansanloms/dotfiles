import {
  bgBrightBlack,
  bgGreen,
  bgRed,
  bgYellow,
  black,
  green,
  red,
  white,
  yellow,
} from "@std/fmt/colors";
import type { HookInput } from "../types.ts";

/**
 * ファイル末尾から指定行数を効率的に読み込む。
 * 大きなトランスクリプトファイルでも全体を読まず、末尾からチャンク単位で逆読みする。
 */
export const tailLines = async (
  filePath: string,
  n: number,
): Promise<string[]> => {
  const file = await Deno.open(filePath);
  const stat = await file.stat();
  const fileSize = stat.size;

  if (fileSize === 0) {
    file.close();
    return [];
  }

  const chunkSize = 4096;
  const lines: string[] = [];
  let buffer = new Uint8Array(0);
  let position = fileSize;

  try {
    while (position > 0 && lines.length < n) {
      const readSize = Math.min(chunkSize, position);
      position -= readSize;

      await file.seek(position, Deno.SeekMode.Start);
      const chunk = new Uint8Array(readSize);
      await file.read(chunk);

      // 新しいチャンクを前に結合
      const newBuffer = new Uint8Array(chunk.length + buffer.length);
      newBuffer.set(chunk);
      newBuffer.set(buffer, chunk.length);
      buffer = newBuffer;

      // 行を後ろから抽出
      const text = new TextDecoder().decode(buffer);
      const splitLines = text.split(/\r?\n/);

      if (position > 0) {
        // まだ読み続ける場合、最初の不完全な行はバッファに残す
        buffer = new TextEncoder().encode(splitLines[0]);
        lines.unshift(...splitLines.slice(1).filter((l) => l !== ""));
      } else {
        lines.unshift(...splitLines.filter((l) => l !== ""));
      }
    }

    return lines.slice(-n);
  } finally {
    file.close();
  }
};

/**
 * stdin から JSON を読み取り、指定した型として返す。
 * 型引数を省略した場合は HookInput として扱う。
 */
export const getInput = async <T = HookInput>(): Promise<T> => {
  const decoder = new TextDecoder();
  let input = "";
  for await (const chunk of Deno.stdin.readable) {
    input += decoder.decode(chunk);
  }

  return JSON.parse(input) as T;
};

/**
 * 数値を compact 表記（例: 1K, 2.3M）にフォーマットする。
 */
export const formatCompact = (num: number): string =>
  new Intl.NumberFormat("en", {
    notation: "compact",
    compactDisplay: "short",
  }).format(num);

/**
 * 指定パーセンテージのプログレスバー文字列を生成する。
 * `width` はバーの総文字数。
 */
export const buildProgressBar = (pct: number, width: number): string => {
  const filled = Math.floor(pct * width / 100);
  return "\u2593".repeat(filled) + "\u2591".repeat(width - filled);
};

/**
 * パーセンテージに応じた色付きプログレスバーを返す。
 * 90% 以上: 赤、70% 以上: 黄、それ以外: 緑。
 */
export const coloredProgressBar = (pct: number, width: number): string => {
  const bar = buildProgressBar(pct, width);
  return pct >= 90 ? red(bar) : pct >= 70 ? yellow(bar) : green(bar);
};

/**
 * ラベルをバー内に埋め込んだ背景色付きプログレスバーを返す。
 * filled 領域と unfilled 領域で背景色を分け、ラベルが境界をまたぐ場合は
 * それぞれの背景色を適用する。
 * 90% 以上: 赤背景、70% 以上: 黄背景、それ以外: 緑背景。
 * unfilled 領域は暗いグレー背景。
 */
export const buildInlineProgressBar = (
  pct: number,
  label: string,
  width: number,
): string => {
  const filled = Math.floor(pct * width / 100);
  const clipped = label.slice(0, width);
  const splitAt = Math.min(filled, clipped.length);

  const labelFilled = clipped.slice(0, splitAt);
  const labelUnfilled = clipped.slice(splitAt);
  const filledRemainder = " ".repeat(Math.max(0, filled - clipped.length));
  const unfilledRemainder = " ".repeat(
    Math.max(0, width - Math.max(filled, clipped.length)),
  );

  const filledStr = labelFilled + filledRemainder;
  const unfilledStr = labelUnfilled + unfilledRemainder;

  if (pct >= 90) {
    return bgRed(white(filledStr)) + bgBrightBlack(white(unfilledStr));
  } else if (pct >= 70) {
    return bgYellow(black(filledStr)) + bgBrightBlack(white(unfilledStr));
  } else {
    return bgGreen(black(filledStr)) + bgBrightBlack(white(unfilledStr));
  }
};
