import type {
  HookInput,
  NotificationHookInput,
  PermissionRequestHookInput,
  StopHookInput,
} from "../types.ts";
import { tailLines } from "./common.ts";

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
      return `${input.file_path ?? ""}\n${
        String(input.old_string ?? "").slice(0, 80)
      }...`;
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
