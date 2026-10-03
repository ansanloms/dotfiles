import { getInput } from "./utils/common.ts";
import {
  buildNotification,
  buildTerminalSequence,
  type Notification,
} from "./utils/hook.ts";

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

// hook の timeout (10 秒) より短くし、応答が無くても terminalSequence を出せるようにする。
const NTFY_TIMEOUT_MS = 5000;

const notifyNtfy = async (notification: Notification) => {
  const url = Deno.env.get("NTFW_URL");
  const token = Deno.env.get("NTFW_TOKEN");

  if (!url || !token) {
    return;
  }

  try {
    const response = await fetch(url, {
      method: "POST",
      signal: AbortSignal.timeout(NTFY_TIMEOUT_MS),
      body: notification.body,
      headers: {
        Authorization: `Bearer ${token}`,
        Markdown: "yes",
        Title: encodeHeader(notification.title),
        Tags: notification.tag,
      },
    });
    if (!response.ok) {
      console.error("ntfy error:", response.status, response.statusText);
    }
    await response.body?.cancel();
  } catch (error) {
    console.error("ntfy error:", error);
  }
};

const input = await getInput();
const notification = await buildNotification(input);

await notifyNtfy(notification);

// hook の stdout は JSON オブジェクト 1 つだけにする（ログは stderr へ）。
console.log(
  JSON.stringify({ terminalSequence: buildTerminalSequence(notification) }),
);
