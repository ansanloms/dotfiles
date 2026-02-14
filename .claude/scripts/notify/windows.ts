import type { NotifyRequest } from "https://raw.githubusercontent.com/ansanloms/wsl-notify/refs/tags/0.0.6/notifier.ts";
import { SOCK_PATH } from "https://raw.githubusercontent.com/ansanloms/wsl-notify/refs/tags/0.0.6/socket.ts";

import { getInput, getMessage } from "./utils.ts";

const BUFFER_SIZE = 16384; // 16KB
const __dirname = new URL(".", import.meta.url).pathname;

const conn = await Deno.connect({
  path: SOCK_PATH,
  transport: "unix",
});

try {
  const input = await getInput();
  const message = (await getMessage(input)) ?? "";

  const req: NotifyRequest = {
    title: "Claude Code",
    message,
    attribution: `${input.session_id} (${input.hook_event_name})`,
    image: {
      placement: "appLogoOverride",
      hintCrop: "circle",
      src: `${__dirname}/../clawd.jpg`,
    },
    audio: {
      src: input.hook_event_name === "Stop"
        ? "ms-winsoundevent:Notification.Looping.Alarm8"
        : "ms-winsoundevent:Notification.Looping.Call7",
    },
    duration: "long",
  };

  await conn.write(new TextEncoder().encode(JSON.stringify(req)));
  await conn.read(new Uint8Array(BUFFER_SIZE));
} catch (error) {
  console.error("Client error:", error);
  throw error;
} finally {
  conn.close();
}
