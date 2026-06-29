import type { NotifyRequest } from "./notify-wire.ts";
import { SOCK_PATH } from "./notify-wire.ts";

import type { HookInput } from "./types.ts";
import { getInput } from "./utils/common.ts";
import { buildNotification, type Notification } from "./utils/hook.ts";

const BUFFER_SIZE = 16384; // 16KB
const __dirname = new URL(".", import.meta.url).pathname;

/**
 * 非 ASCII を含む文字列を HTTP ヘッダ値へ載せられる形にする。
 * fetch のヘッダ値は Latin-1（0-255）しか許さないため、UTF-8 バイト列を
 * 1 バイト 1 文字へ写す。ntfy サーバは受け取った生バイトを UTF-8 として解釈する。
 */
const encodeHeader = (text: string): string => {
  const bytes = new TextEncoder().encode(text);
  let out = "";
  for (const byte of bytes) {
    out += String.fromCharCode(byte);
  }
  return out;
};

const notifyNtfy = async (notification: Notification) => {
  const url = Deno.env.get("NTFW_URL");
  const token = Deno.env.get("NTFW_TOKEN");

  if (!url || !token) {
    return;
  }

  try {
    await fetch(url, {
      method: "POST",
      body: notification.body,
      headers: {
        Authorization: `Bearer ${token}`,
        Markdown: "yes",
        Title: encodeHeader(notification.title),
        Tags: notification.tag,
      },
    });
  } catch (error) {
    console.error("ntfy error:", error);
  }
};

const notifyWindows = async (input: HookInput, notification: Notification) => {
  const conn = await Deno.connect({
    path: SOCK_PATH,
    transport: "unix",
  });

  try {
    const req: NotifyRequest = {
      title: `${notification.emoji} ${notification.title}`,
      message: notification.body,
      attribution: input.cwd,
      image: {
        placement: "appLogoOverride",
        hintCrop: "circle",
        src: `${__dirname}/clawd.jpg`,
      },
      audio: {
        src: notification.sound,
      },
      duration: "long",
    };

    await conn.write(new TextEncoder().encode(JSON.stringify(req)));
    await conn.read(new Uint8Array(BUFFER_SIZE));
  } catch (error) {
    console.error("notify error:", error);
    throw error;
  } finally {
    conn.close();
  }
};

const input = await getInput();
const notification = await buildNotification(input);

await Promise.all([
  notifyNtfy(notification),
  notifyWindows(input, notification),
]);
