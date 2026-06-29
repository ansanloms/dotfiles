#!/usr/bin/env -S deno run --quiet --allow-env --allow-run --allow-read

// Windows のクリップボードに画像が入ったら自動で clip-image を実行する常駐
// プロセス。WSL の systemd ユーザサービス (clip-image-watch.service) から起動
// する想定。
//
// Windows のクリップボード変更イベントは Linux から購読できないため、検知は
// Windows 側の powershell リスナに任せ、このプロセスはそれを監督する。
// powershell を 1 個常駐させ、画像コピーのたびに届く 1 行を受けて clip-image を
// 起動する。
//
// ロジックは lib/clip-image-watch.ts に分離し、副作用はここで組み立てて注入する。

import { TextLineStream } from "@std/streams";
import { LISTENER_PS, run } from "./lib/clip-image-watch.ts";

// クリップボード変更を監視する powershell リスナを常駐起動する。
// STA でないと Clipboard API が使えないため -STA を付ける。
const listener = new Deno.Command("powershell.exe", {
  args: ["-NoProfile", "-STA", "-Command", LISTENER_PS],
  stdout: "piped",
  stderr: "null",
}).spawn();

// powershell の stdout を行単位のストリームに変換する。
const lines = listener.stdout
  .pipeThrough(new TextDecoderStream())
  .pipeThrough(new TextLineStream());

const clipImage = `${Deno.env.get("HOME")}/.local/bin/clip-image`;

// PNG を Linux (WSLg) のクリップボードへ image/png で載せる。
// Chrome の動作系 (Wayland / XWayland) が不定なので Wayland (wl-copy) と
// X11 (xclip) の両方へ載せる。どちらかが無くても致命的ではないため握りつぶす。
// 接続には WAYLAND_DISPLAY / DISPLAY が要る (service の Environment で設定)。
async function loadClipboard(pngPath: string): Promise<void> {
  const png = await Deno.readFile(pngPath);

  // Wayland: wl-copy は stdin から画像バイト列を受け取る。
  try {
    const wl = new Deno.Command("wl-copy", {
      args: ["--type", "image/png"],
      stdin: "piped",
      stdout: "null",
      stderr: "null",
    }).spawn();
    const w = wl.stdin.getWriter();
    await w.write(png);
    await w.close();
  } catch {
    // Wayland が無い等。X11 側に賭ける。
  }

  // X11 (XWayland): xclip はファイルを直接読める。
  try {
    await new Deno.Command("xclip", {
      args: ["-selection", "clipboard", "-t", "image/png", "-i", pngPath],
      stdout: "null",
      stderr: "null",
    }).output();
  } catch {
    // X11 が無い等。
  }
}

const code = await run({
  lines: () => lines,
  runClip: async () => {
    const o = await new Deno.Command(clipImage, {
      stdout: "piped",
      stderr: "null",
    }).output();
    return new TextDecoder().decode(o.stdout).trim();
  },
  loadClipboard,
  log: (msg) => console.log(msg),
  errorLine: (msg) => console.error(msg),
});

Deno.exit(code);
