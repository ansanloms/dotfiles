#!/usr/bin/env -S deno run --quiet --allow-env --allow-run

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

const code = await run({
  lines: () => lines,
  runClip: async () => {
    await new Deno.Command(clipImage, {
      stdout: "null",
      stderr: "null",
    }).output();
  },
  errorLine: (msg) => console.error(msg),
});

Deno.exit(code);
