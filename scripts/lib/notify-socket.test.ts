import { assertEquals } from "@std/assert";
import { startSocketServer } from "./notify-socket.ts";
import type { NotifyRequest } from "./notify-notifier.ts";

/**
 * テスト用にサーバを起動し、1 リクエスト送って受信内容と応答を返す。
 * 送信は `write` を 1 回で行うパターンと、複数チャンクに分割するパターンを選べる。
 */
const roundTrip = async (
  req: NotifyRequest,
  opts: { splitInto?: number } = {},
): Promise<{ received: NotifyRequest | null; response: string }> => {
  const sockPath = await Deno.makeTempFile();
  await Deno.remove(sockPath); // listen 前にファイルを消す

  let received: NotifyRequest | null = null;
  const controller = new AbortController();

  // サーバ起動（await しない: listener ループでブロックするため）
  const serverPromise = startSocketServer({
    sockPath,
    signal: controller.signal,
    onMessage: (r) => {
      received = r;
      return Promise.resolve({ status: "ok" });
    },
  });
  // listen 完了をポーリングで待つ
  for (let i = 0; i < 50; i++) {
    try {
      await Deno.stat(sockPath);
      break;
    } catch {
      await new Promise((r) => setTimeout(r, 20));
    }
  }

  const conn = await Deno.connect({ path: sockPath, transport: "unix" });
  let response = "";
  try {
    const payload = new TextEncoder().encode(JSON.stringify(req));
    const splitInto = opts.splitInto ?? 1;

    if (splitInto <= 1) {
      await conn.write(payload);
    } else {
      const size = Math.ceil(payload.length / splitInto);
      for (let i = 0; i < payload.length; i += size) {
        await conn.write(payload.subarray(i, i + size));
        // 分割受信を確実に再現するため少し待つ
        await new Promise((r) => setTimeout(r, 10));
      }
    }

    const buf = new Uint8Array(4096);
    const n = await conn.read(buf);
    response = new TextDecoder().decode(buf.subarray(0, n ?? 0));
  } finally {
    conn.close();
  }

  // サーバ側 onMessage の完了を待つ
  await new Promise((r) => setTimeout(r, 50));
  // listener を閉じてサーバループを終了させ、Promise の解決を待つ
  controller.abort();
  await serverPromise;
  await Deno.remove(sockPath).catch(() => {});

  return { received, response };
};

Deno.test("startSocketServer - 小さなリクエストを受信できること。", async () => {
  const req: NotifyRequest = { title: "T", message: "small" };
  const { received, response } = await roundTrip(req);

  assertEquals(received?.message, "small");
  assertEquals(response.includes('"ok"'), true);
});

Deno.test("startSocketServer - 16KB を超えるリクエストを受信できること。", async () => {
  const req: NotifyRequest = { title: "T", message: "x".repeat(50000) };
  const { received, response } = await roundTrip(req);

  assertEquals(received?.message.length, 50000);
  assertEquals(response.includes('"ok"'), true);
});

Deno.test("startSocketServer - 複数チャンクに分割されたリクエストを受信できること。", async () => {
  const req: NotifyRequest = { title: "T", message: "y".repeat(40000) };
  const { received, response } = await roundTrip(req, { splitInto: 5 });

  assertEquals(received?.message.length, 40000);
  assertEquals(response.includes('"ok"'), true);
});
