import type {
  HookInput,
  NotificationHookInput,
  PermissionRequestHookInput,
  StopHookInput,
} from "npm:@anthropic-ai/claude-agent-sdk@latest";

/**
 * ファイル末尾から指定行数を効率的に読み込む。
 * 大きなトランスクリプトファイルでも全体を読まず、末尾からチャンク単位で逆読みする。
 */
export const tailLines = async (
  filePath: string,
  n: number,
): Promise<string[]> => {
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

/**
 * stdin から Claude Code の hook 入力 JSON を読み取り、HookInput として返す。
 */
export const getInput = async () => {
  const decoder = new TextDecoder();
  let input = "";
  for await (const chunk of Deno.stdin.readable) {
    input += decoder.decode(chunk);
  }

  return JSON.parse(input) as HookInput;
};

/**
 * トランスクリプトファイルの末尾から最新のアシスタントテキストメッセージを抽出する。
 * トランスクリプトは JSONL 形式で、各行が `{ message: { content: [...] } }` 構造を持つ。
 */
export const getLastAssistantMessage = async (transcriptPath: string) => {
  const lines = (await tailLines(transcriptPath, 10)).reverse();
  for (const line of lines) {
    const session = JSON.parse(line);

    const text =
      (Array.isArray(session?.message?.content) ? session.message.content : [])
        .find(({ type }: { type: string }) => type === "text")?.text;
    if (text) {
      return String(text);
    }
  }

  return undefined;
};

/**
 * Stop hook 用メッセージを取得する。
 * `last_assistant_message` が提供されていればそれを使い、なければトランスクリプトから抽出する。
 */
export const getStopMessage = async (input: StopHookInput) => {
  if (input.last_assistant_message) {
    return input.last_assistant_message;
  }
  return await getLastAssistantMessage(input.transcript_path);
};

/**
 * Notification hook 用メッセージを取得する。
 * title があれば `title\nmessage` 形式、なければ message のみ返す。
 */
export const getNotificationMessage = (input: NotificationHookInput) => {
  if (input.title) {
    return `${input.title}\n${input.message}`;
  }
  return input.message;
};

/**
 * ツール入力を人間が読みやすい形式にフォーマットする。
 * ツールの種類に応じて最も重要な情報のみを抽出する。
 */
export const formatToolInput = (
  toolName: string,
  toolInput: unknown,
): string => {
  const input = toolInput as Record<string, unknown> | null;
  if (!input) return "";

  switch (toolName) {
    case "Bash":
      return String(input.command ?? "");
    case "Edit":
      return `${input.file_path ?? ""}\n${String(input.old_string ?? "").slice(0, 80)}...`;
    case "Write":
      return String(input.file_path ?? "");
    case "Read":
      return String(input.file_path ?? "");
    case "Glob":
      return String(input.pattern ?? "");
    case "Grep":
      return String(input.pattern ?? "");
    case "AskUserQuestion": {
      const questions = input.questions as
        | { question: string; options?: { label: string }[] }[]
        | undefined;
      if (!Array.isArray(questions)) return "";
      return questions.map((q) => {
        const opts = Array.isArray(q.options)
          ? q.options.map((o) => `- ${o.label}`).join("\n")
          : "";
        return opts ? `${q.question}\n${opts}` : q.question;
      }).join("\n");
    }
    default: {
      const json = JSON.stringify(input, null, 2);
      return json.length > 200 ? json.slice(0, 200) + "..." : json;
    }
  }
};

/**
 * PermissionRequest hook 用メッセージを取得する。
 * ツール名と入力内容を markdown 形式で返す。
 */
export const getPermissionRequestMessage = (
  input: PermissionRequestHookInput,
) => {
  const detail = formatToolInput(input.tool_name, input.tool_input);
  return `**${input.tool_name}** の実行許可を求めています\n${detail}`;
};

/**
 * hook イベントの種類に応じた通知メッセージを生成する。
 * - Stop: 最後のアシスタントメッセージ
 * - Notification: 通知メッセージ本文
 * - PermissionRequest: ツール名と入力の要約
 * - その他: トランスクリプトからの最新メッセージ（フォールバック）
 */
export const getMessage = async (input: HookInput) => {
  switch (input.hook_event_name) {
    case "Stop":
      return await getStopMessage(input);
    case "Notification":
      return getNotificationMessage(input);
    case "PermissionRequest":
      return getPermissionRequestMessage(input);
    default:
      return await getLastAssistantMessage(input.transcript_path);
  }
};
