#!/usr/bin/env deno

import type { NotifyRequest } from "https://raw.githubusercontent.com/ansanloms/wsl-notify/refs/tags/0.0.5/notifier.ts";
import { SOCK_PATH } from "https://raw.githubusercontent.com/ansanloms/wsl-notify/refs/tags/0.0.5/socket.ts";

const BUFFER_SIZE = 16384; // 16KB

interface HookCommand {
  session_id: string;
  transcript_path: string;
  cwd: string;
  hook_event_name: string;
  message: string;
  notification_type: string;
}

const tailLines = async (filePath: string, n: number): Promise<string[]> => {
  const file = await Deno.open(filePath);
  const stat = await file.stat();
  const fileSize = stat.size;

  if (fileSize === 0) {
    file.close();
    return [];
  }

  const chunkSize = 4096;
  const lines: string[] = [];
  let buffer = new Uint8Array(0);
  let position = fileSize;

  try {
    while (position > 0 && lines.length < n) {
      const readSize = Math.min(chunkSize, position);
      position -= readSize;

      await file.seek(position, Deno.SeekMode.Start);
      const chunk = new Uint8Array(readSize);
      await file.read(chunk);

      // 新しいチャンクを前に結合
      const newBuffer = new Uint8Array(chunk.length + buffer.length);
      newBuffer.set(chunk);
      newBuffer.set(buffer, chunk.length);
      buffer = newBuffer;

      // 行を後ろから抽出
      const text = new TextDecoder().decode(buffer);
      const splitLines = text.split(/\r?\n/);

      if (position > 0) {
        // まだ読み続ける場合、最初の不完全な行はバッファに残す
        buffer = new TextEncoder().encode(splitLines[0]);
        lines.unshift(...splitLines.slice(1).filter((l) => l !== ""));
      } else {
        lines.unshift(...splitLines.filter((l) => l !== ""));
      }
    }

    return lines.slice(-n);
  } finally {
    file.close();
  }
};

const data = await (async () => {
  const decoder = new TextDecoder();
  let input = "";
  for await (const chunk of Deno.stdin.readable) {
    input += decoder.decode(chunk);
  }
  return JSON.parse(input) as HookCommand;
})();

const conn = await Deno.connect({
  path: SOCK_PATH,
  transport: "unix",
});

try {
  const message = await (async () => {
    const lines = (await tailLines(data.transcript_path, 10)).reverse();
    for (const line of lines) {
      const session = JSON.parse(line);

      const text = (session?.message?.content ?? []).find(({ type }) =>
        type === "text"
      )?.text;
      if (text) {
        return String(text);
      }
    }

    return "";
  })();

  const req: NotifyRequest = {
    title: "Claude Code",
    message,
    attribution: `${data.session_id} (${data.hook_event_name})`,
    audio: {
      src: data.hook_event_name === "Stop"
        ? "ms-winsoundevent:Notification.Looping.Alarm8"
        : "ms-winsoundevent:Notification.Looping.Call7",
    },
    duration: "long",
  };

  await conn.write(new TextEncoder().encode(JSON.stringify(req)));
  await conn.read(new Uint8Array(BUFFER_SIZE));
} catch (error) {
  console.error("Client error:", error);
} finally {
  conn.close();
}
