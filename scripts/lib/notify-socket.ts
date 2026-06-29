import type { NotifyRequest, NotifyResponse } from "./notify-notifier.ts";

/**
 * 1 回の読み込みで使うチャンクバッファのサイズ（バイト）。
 * リクエスト全体の上限ではなく、ループで読み進める単位。
 */
const CHUNK_SIZE = 16384; // 16KB

/**
 * 受信を許容するリクエストの最大サイズ（バイト）。
 * これを超えたら異常とみなして打ち切る（メモリ枯渇の防止）。
 */
const MAX_MESSAGE_SIZE = 1024 * 1024; // 1MB

export interface SocketServerOptions {
  /**
   * UNIX ソケットのパス。
   */
  sockPath: string;

  /**
   * メッセージ受信時のハンドラ。
   * @param req 受信した通知リクエスト
   * @returns 処理結果のレスポンス
   */
  onMessage: (req: NotifyRequest) => Promise<NotifyResponse>;

  /**
   * サーバーを停止するためのシグナル（任意）。
   * abort されるとリスナーを閉じ、`startSocketServer` の Promise が解決する。
   */
  signal?: AbortSignal;
}

/**
 * レスポンスを安全に書き込む。
 * クライアントが既に切断している場合でも、エラーをキャッチしてサーバーを継続動作させる。
 * @param conn ソケット接続
 * @param res レスポンスデータ
 */
const safeWriteResponse = async (
  conn: Deno.Conn,
  res: NotifyResponse,
): Promise<void> => {
  try {
    await conn.write(new TextEncoder().encode(JSON.stringify(res)));
  } catch (error) {
    console.error("Failed to send response:", error);
  }
};

/**
 * タイムアウト付きでソケットから読み込む。
 * @param conn ソケット接続
 * @param buf バッファ
 * @param timeoutMs タイムアウト時間（ミリ秒）
 * @returns 読み込んだバイト数
 */
const readWithTimeout = async (
  conn: Deno.Conn,
  buf: Uint8Array,
  timeoutMs: number,
): Promise<number | null> => {
  const timeoutPromise = new Promise<never>((_, reject) =>
    setTimeout(() => reject(new Error("Read timeout")), timeoutMs)
  );

  return await Promise.race([
    conn.read(buf),
    timeoutPromise,
  ]);
};

/**
 * 受信したチャンク列を 1 本の文字列へ連結する。
 * @param chunks 受信済みのチャンク列
 * @param total 合計バイト数
 */
const decodeChunks = (chunks: Uint8Array[], total: number): string => {
  const merged = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    merged.set(chunk, offset);
    offset += chunk.length;
  }
  return new TextDecoder().decode(merged);
};

/**
 * リクエストを完全に受信してパースする。
 *
 * UNIX ソケットの 1 回の `read` は「1 read = メッセージ全体」を保証しない
 * （ストリームのため分割・結合され得る）。固定バッファで 1 回だけ読む実装では、
 * 16KB を超えるメッセージは切り詰められ、分割受信時は途中で `JSON.parse` が
 * 失敗して通知が届かなくなる。
 *
 * 既存クライアントは書き込み後に応答を待つ（write 側を閉じない）ため、EOF を
 * 完了の合図にできない。そこで受信バイトを貯め、`JSON.parse` が成功した時点で
 * 完了とみなす。各 `read` にはタイムアウトを設け、合計サイズには上限を設ける。
 *
 * @param conn ソケット接続
 * @param timeoutMs 1 回の読み込みのタイムアウト（ミリ秒）
 * @returns パース済みのリクエスト
 */
const readRequest = async (
  conn: Deno.Conn,
  timeoutMs: number,
): Promise<NotifyRequest> => {
  const chunks: Uint8Array[] = [];
  let total = 0;
  const buf = new Uint8Array(CHUNK_SIZE);

  while (true) {
    const n = await readWithTimeout(conn, buf, timeoutMs);

    // null は EOF。これ以上は届かないので、貯めた分でパースを試みる。
    if (n === null) {
      return JSON.parse(decodeChunks(chunks, total));
    }

    chunks.push(buf.slice(0, n));
    total += n;

    if (total > MAX_MESSAGE_SIZE) {
      throw new Error(
        `Request exceeds max size of ${MAX_MESSAGE_SIZE} bytes`,
      );
    }

    // 受信済みデータが完全な JSON ならパースして完了。
    // 不完全な場合は SyntaxError を握りつぶして次のチャンクを待つ。
    try {
      return JSON.parse(decodeChunks(chunks, total));
    } catch (error) {
      if (error instanceof SyntaxError) {
        continue;
      }
      throw error;
    }
  }
};

/**
 * ソケット接続を処理する。
 * クライアントからのリクエストを受信し、onMessage ハンドラを実行して、レスポンスを返す。
 * @param conn ソケット接続
 * @param onMessage メッセージ受信時のハンドラ
 */
const handleConnection = async (
  conn: Deno.Conn,
  onMessage: (req: NotifyRequest) => Promise<NotifyResponse>,
): Promise<void> => {
  try {
    const req = await readRequest(conn, 30000); // 30秒タイムアウト

    const res = await onMessage(req);
    await safeWriteResponse(conn, res);
  } catch (error) {
    console.error("Connection error:", error);

    const res: NotifyResponse = {
      status: "error",
      error: String(error),
    };

    await safeWriteResponse(conn, res);
  } finally {
    conn.close();
  }
};

/**
 * UNIX ソケットサーバーを起動する。
 * 既存のソケットファイルが存在する場合は削除してから、新しいソケットでリスニングを開始する。
 * @param options サーバーオプション
 */
export const startSocketServer = async (
  { sockPath, onMessage, signal }: SocketServerOptions,
): Promise<void> => {
  // 既存のソケットファイルが存在する場合は削除
  try {
    await Deno.remove(sockPath);
  } catch (error) {
    if (!(error instanceof Deno.errors.NotFound)) {
      throw error;
    }
  }

  const listener = Deno.listen({
    path: sockPath,
    transport: "unix",
  });

  // abort されたらリスナーを閉じて accept ループを抜ける。
  signal?.addEventListener("abort", () => {
    try {
      listener.close();
    } catch {
      // 既に閉じている場合は無視する。
    }
  });

  console.log(`Listening on ${sockPath}`);

  try {
    for await (const conn of listener) {
      // 接続を並列処理する（awaitしない）
      // handleConnection内でエラーハンドリング済みだが、念のためcatchを追加
      handleConnection(conn, onMessage).catch((err) => {
        console.error("Unhandled connection error:", err);
      });
    }
  } catch (error) {
    // abort によるリスナー close では accept が BadResource で失敗する。
    // 意図した停止なら無視し、それ以外は再スローする。
    if (!signal?.aborted) {
      throw error;
    }
  }
};
