#!/usr/bin/env -S deno run --quiet --allow-env --allow-run --allow-read --allow-write

// Windows ホストのクリップボード上の画像 (Win+Shift+S のキャプチャ等) を
// WSL 側の PNG ファイルに保存し、その絶対パスを stdout に出力する。
//
// 用途:
//   - nvim:        :r !clip-image  /  :put =system('clip-image')->trim()
//   - claude code: シェルから実行してパスを得る (Claude にこの画像を見せる等)
//
// オプション:
//   --copy-path, -c  保存先パス文字列を OSC 52 でシステムクリップボードへ載せる。
//                    キャプチャ後に `clip-image --copy-path` を実行すると、
//                    claude code 等の入力欄に Ctrl+V でパスを貼れるようになる。
//
// 設計:
//   - ロジックは lib/clip-image.ts に分離し、副作用はここで組み立てて注入する。
//   - stdout には保存先の WSL 絶対パスのみを出す。進捗・エラーは stderr。
//     これで `:r !` や `$(clip-image)` に混ぜても余計な文字列が紛れない。
//   - powershell は native NTFS の一時領域へ書き、コピーは WSL 側で行う。
//     9P 共有を「Windows -> WSL 直書き」ではなく「WSL -> NTFS 読み」の向きで
//     使うことで、.NET の Image.Save が \\wsl$ パスで稀に転ける問題を避ける。
//   - --copy-path の OSC 52 も stdout を汚さないよう制御端末 (/dev/tty) へ直接書く。

import { type CommandResult, run } from "./lib/clip-image.ts";

/** Deno.Command の結果を CommandResult へ正規化する。 */
async function output(cmd: string, args: string[]): Promise<CommandResult> {
  const o = await new Deno.Command(cmd, {
    args,
    stdout: "piped",
    stderr: "piped",
  }).output();
  const dec = new TextDecoder();
  return {
    code: o.code,
    success: o.success,
    stdout: dec.decode(o.stdout),
    stderr: dec.decode(o.stderr),
  };
}

/**
 * OSC 52 を制御端末 (/dev/tty) へ直接書く。tty が開けなければ stderr へ
 * フォールバックする (stderr が端末なら届く)。
 */
function writeClipboard(bytes: Uint8Array): void {
  try {
    const tty = Deno.openSync("/dev/tty", { write: true });
    try {
      tty.writeSync(bytes);
    } finally {
      tty.close();
    }
  } catch {
    Deno.stderr.writeSync(bytes);
  }
}

const code = await run({
  args: Deno.args,
  env: Deno.env,
  now: () => new Date(),
  runPowershell: (script) =>
    output("powershell.exe", ["-NoProfile", "-STA", "-Command", script]),
  runWslpath: (winPath) => output("wslpath", ["-u", winPath]),
  mkdirp: (dir) => Deno.mkdir(dir, { recursive: true }),
  copyFile: (src, dest) => Deno.copyFile(src, dest),
  removeFile: (path) => Deno.remove(path),
  linkLatest: async (linkPath, target) => {
    try {
      await Deno.remove(linkPath);
    } catch {
      // 既存リンクが無ければそのまま新規作成する。
    }
    await Deno.symlink(target, linkPath);
  },
  writeClipboard,
  stdout: (line) => console.log(line),
  stderr: (line) => console.error(line),
});

Deno.exit(code);
