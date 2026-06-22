import { basename } from "@std/path";
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
  if (!input) {
    return "";
  }

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
      if (!Array.isArray(questions)) {
        return "";
      }
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

/**
 * hook イベント種別ごとの表示属性。
 * 「どのラベル・どの絵文字・どの音か」をこの 1 箇所で定義する。
 */
export interface EventDescriptor {
  /** 通知タイトルの先頭に出す、一目で種別が分かるラベル。 */
  label: string;

  /** ntfy の Tags に渡す絵文字キーワード（受信側でアイコンに変換される）。 */
  tag: string;

  /**
   * 絵文字リテラル。Windows トーストは Tags のようなキーワード変換を持たないため、
   * タイトル先頭へ直接前置するのに使う。`tag` と同じ意味の絵文字を指す。
   */
  emoji: string;

  /** Windows トーストの通知音（ms-winsoundevent URI）。 */
  sound: string;
}

/**
 * イベント種別 → 表示属性の対応表。
 * 新しいイベントを通知対象に加える場合や、ラベル・音を変える場合はここを編集する。
 */
const eventDescriptors: Record<string, EventDescriptor> = {
  Stop: {
    label: "完了",
    tag: "white_check_mark",
    emoji: "✅",
    sound: "ms-winsoundevent:Notification.Looping.Alarm8",
  },
  StopFailure: {
    label: "失敗",
    tag: "rotating_light",
    emoji: "🚨",
    sound: "ms-winsoundevent:Notification.Looping.Alarm2",
  },
  Notification: {
    label: "確認待ち",
    tag: "bell",
    emoji: "🔔",
    sound: "ms-winsoundevent:Notification.Looping.Call7",
  },
  PermissionRequest: {
    label: "許可待ち",
    tag: "warning",
    emoji: "⚠️",
    sound: "ms-winsoundevent:Notification.Looping.Call6",
  },
};

/** 対応表にないイベント用のフォールバック属性。 */
const defaultDescriptor: EventDescriptor = {
  label: "通知",
  tag: "speech_balloon",
  emoji: "💬",
  sound: "ms-winsoundevent:Notification.Looping.Call6",
};

/**
 * イベント名に対応する表示属性を返す。未知のイベントは既定値を返す。
 */
export const getEventDescriptor = (eventName: string): EventDescriptor =>
  eventDescriptors[eventName] ?? defaultDescriptor;

/**
 * StopFailure hook 用メッセージを取得する。
 * ターンが API エラーで終了したことと、判明すればその error type を返す。
 * error type のフィールド名は公式に確定していないため、候補を順に探し、
 * いずれも無ければ種別なしの固定文言にフォールバックする。
 */
export const getStopFailureMessage = (input: HookInput): string => {
  const record = input as Record<string, unknown>;
  const errorType = record.error_type ?? record.error ?? record.reason;
  return typeof errorType === "string" && errorType
    ? `API エラーでターンが終了: ${errorType}`
    : "API エラーでターンが終了";
};

/**
 * 送信経路に依存しない通知 1 件分の構成要素。
 * 各経路（ntfy / Windows トースト）はこれを自分の形式へ流し込む。
 */
export interface Notification {
  /** タイトル。「ラベル | プロジェクト名」形式（絵文字は含まない）。 */
  title: string;

  /** 本文。イベント別メッセージそのまま。 */
  body: string;

  /** ntfy の Tags に渡す絵文字キーワード。 */
  tag: string;

  /** タイトル先頭へ前置する絵文字リテラル（Windows トースト用）。 */
  emoji: string;

  /** Windows トーストの通知音。 */
  sound: string;
}

/**
 * hook 入力から、種別ラベル付きで読みやすい通知 1 件を組み立てる。
 * - タイトル: 「<ラベル> | <プロジェクト名>」（プロジェクト名は cwd の basename）
 * - 本文: イベント別メッセージそのまま
 */
export const buildNotification = async (
  input: HookInput,
): Promise<Notification> => {
  const descriptor = getEventDescriptor(input.hook_event_name);
  const project = basename(input.cwd);
  const message = (input.hook_event_name as string) === "StopFailure"
    ? getStopFailureMessage(input)
    : (await getMessage(input)) ?? "";

  return {
    title: `${descriptor.label} | ${project}`,
    body: message,
    tag: descriptor.tag,
    emoji: descriptor.emoji,
    sound: descriptor.sound,
  };
};
