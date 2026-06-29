#!/usr/bin/env -S deno run --quiet --allow-net --allow-run --allow-read --allow-write --allow-env

// WSL から Windows のトースト通知を出す常駐サーバ。WSL の systemd ユーザ
// サービス (notify.service) から起動する想定。UNIX socket を listen し、
// 受信した NotifyRequest を Windows の Toast Notification API へ渡す。
//
// ロジックは lib/notify-socket.ts (UNIX socket サーバ) と
// lib/notify-notifier.ts (Windows トースト通知) に分離する。

import { startSocketServer } from "./lib/notify-socket.ts";
import { sendWindowsNotification } from "./lib/notify-notifier.ts";

// socket パスはエントリで解決する (lib は ambient な env 読みを持たない)。
// systemd サービス (notify.service) が NOTIFY_SOCK を渡す。
const sockPath = Deno.env.get("NOTIFY_SOCK") ?? "/tmp/notify.sock";

await startSocketServer({
  sockPath,
  onMessage: async (req) => {
    try {
      await sendWindowsNotification(req);
      return { status: "ok" };
    } catch (e) {
      console.error("Notification error:", e);
      return { status: "error", error: String(e) };
    }
  },
});
