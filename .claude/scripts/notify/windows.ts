import type { NotifyRequest } from "https://raw.githubusercontent.com/ansanloms/wsl-notify/refs/tags/0.0.7/notifier.ts";
import { SOCK_PATH } from "https://raw.githubusercontent.com/ansanloms/wsl-notify/refs/tags/0.0.7/socket.ts";

import { getInput, getMessage } from "./utils.ts";

const BUFFER_SIZE = 16384; // 16KB
const __dirname = new URL(".", import.meta.url).pathname;

const conn = await Deno.connect({
  path: SOCK_PATH,
  transport: "unix",
});

const getAudioSrc = (eventName: string) => {
  if (eventName === "Stop") {
    return "ms-winsoundevent:Notification.Looping.Alarm8";
  }

  if (eventName === "Notification") {
    return "ms-winsoundevent:Notification.Looping.Call7";
  }

  return "ms-winsoundevent:Notification.Looping.Call6";
};

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
      src: getAudioSrc(input.hook_event_name),
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
