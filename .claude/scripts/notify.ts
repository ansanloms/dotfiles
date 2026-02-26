import type { NotifyRequest } from "@ansanloms/wsl-notify/notifier.ts";
import { SOCK_PATH } from "@ansanloms/wsl-notify/socket.ts";

import type { HookInput } from "./types.ts";
import { getInput } from "./utils/common.ts";
import { getMessage } from "./utils/hook.ts";

const BUFFER_SIZE = 16384; // 16KB
const __dirname = new URL(".", import.meta.url).pathname;

const getAudioSrc = (eventName: string) => {
  if (eventName === "Stop") {
    return "ms-winsoundevent:Notification.Looping.Alarm8";
  }

  if (eventName === "Notification") {
    return "ms-winsoundevent:Notification.Looping.Call7";
  }

  return "ms-winsoundevent:Notification.Looping.Call6";
};

const notifyNtfy = async (input: HookInput, message: string) => {
  const url = Deno.env.get("NTFW_URL");
  const token = Deno.env.get("NTFW_TOKEN");

  if (!url || !token) return;

  try {
    await fetch(url, {
      method: "POST",
      body: message,
      headers: {
        Authorization: `Bearer ${token}`,
        Markdown: "yes",
        Title: `Claude Code (${input.cwd})`,
        Tags: input.hook_event_name,
      },
    });
  } catch (error) {
    console.error("ntfy error:", error);
  }
};

const notifyWindows = async (input: HookInput, message: string) => {
  const conn = await Deno.connect({
    path: SOCK_PATH,
    transport: "unix",
  });

  try {
    const req: NotifyRequest = {
      title: "Claude Code",
      message,
      attribution: `${input.session_id} (${input.hook_event_name})`,
      image: {
        placement: "appLogoOverride",
        hintCrop: "circle",
        src: `${__dirname}/clawd.jpg`,
      },
      audio: {
        src: getAudioSrc(input.hook_event_name),
      },
      duration: "long",
    };

    await conn.write(new TextEncoder().encode(JSON.stringify(req)));
    await conn.read(new Uint8Array(BUFFER_SIZE));
  } catch (error) {
    console.error("wsl-notify error:", error);
    throw error;
  } finally {
    conn.close();
  }
};

const input = await getInput();
const message = (await getMessage(input)) ?? "";

await Promise.all([notifyNtfy(input, message), notifyWindows(input, message)]);
