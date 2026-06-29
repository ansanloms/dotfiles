#!/usr/bin/env -S deno run --quiet --allow-env --allow-run --allow-read --allow-write

// devcontainer 内で動くクライアント。ホストの clip-image-watch が listen する
// unix socket に接続し、配信される PNG をコンテナのクリップボードへ image/png で
// 載せる。これで devcontainer 内の Claude Code / Chrome 等で Ctrl+V 貼り付けできる。
//
// 前提:
//   - ホストの socket (CLIP_IMAGE_SOCK, 既定 /tmp/clip-image.sock) を devcontainer に
//     bind-mount しておくこと。
//   - コンテナに wl-copy / xclip があり、DISPLAY / WAYLAND_DISPLAY でコンテナの
//     display server に繋がること (Claude Code / Chrome が読むクリップボードと同じ)。
//
// ロジックは lib/clip-image-clip.ts に分離し、副作用はここで組み立てて注入する。

import { run } from "./lib/clip-image-clip.ts";

const sockPath = Deno.env.get("CLIP_IMAGE_SOCK") ?? "/tmp/clip-image.sock";

// PNG をコンテナのクリップボードへ image/png で載せる。
// 動作系が不定なので Wayland (wl-copy) と X11 (xclip) の両方へ。
// どちらも stdin からバイト列を受け取る。
async function loadClipboard(png: Uint8Array): Promise<void> {
  for (
    const spec of [
      { cmd: "wl-copy", args: ["--type", "image/png"] },
      { cmd: "xclip", args: ["-selection", "clipboard", "-t", "image/png"] },
    ]
  ) {
    try {
      const p = new Deno.Command(spec.cmd, {
        args: spec.args,
        stdin: "piped",
        stdout: "null",
        stderr: "null",
      }).spawn();
      const w = p.stdin.getWriter();
      await w.write(png);
      await w.close();
    } catch {
      // そのツール / display が無い場合はスキップ (もう一方に賭ける)。
    }
  }
}

// 切断されたら待って再接続するループ。
while (true) {
  let conn: Deno.UnixConn | null = null;
  try {
    conn = await Deno.connect({ path: sockPath, transport: "unix" });
    console.log(`clip-image-clip: connected ${sockPath}`);
    const c = conn;
    await run({
      chunks: () => c.readable,
      loadClipboard,
      log: (msg) => console.log(msg),
      errorLine: (msg) => console.error(msg),
    });
  } catch (e) {
    console.error(`clip-image-clip: ${e}`);
  } finally {
    try {
      conn?.close();
    } catch {
      // 既に閉じている場合は無視。
    }
  }
  // 3 秒待って再接続。
  await new Promise((resolve) => setTimeout(resolve, 3000));
}
