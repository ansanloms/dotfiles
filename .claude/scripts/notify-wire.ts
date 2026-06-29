// notify サーバ (scripts/lib/notify-socket.ts / notify-notifier.ts) との
// ワイヤ契約。サーバとは UNIX socket 上の JSON でやり取りするだけで、コードは
// 共有しない (.claude/scripts は ~/.claude へシンボリックリンクされ、別の deno
// プロジェクトとして動くため、サーバ側 scripts/lib を相対 import できない)。
// そのため socket パスと送信する JSON の型だけをここに複製する。
// サーバ側の定義 (NOTIFY_SOCK / NotifyRequest) と一致させること。

export const SOCK_PATH = Deno.env.get("NOTIFY_SOCK") ?? "/tmp/notify.sock";

export interface NotifyRequest {
  /** タイトル。 */
  title: string;

  /** メッセージ。 */
  message: string;

  /** 属性表示。 */
  attribution?: string;

  /** 通知クリック時に開く遷移先。 */
  url?: string;

  /** ボタン。 */
  button?: {
    /** ラベル。 */
    label: string;

    /** 遷移先。 */
    src: string;
  }[];

  /** 画像表示。 */
  image?: {
    /** 画像の配置。 */
    placement?: "appLogoOverride" | "hero";

    /** 画像のトリミング。 */
    hintCrop?: "circle";

    /** 画像のパス。 */
    src: string;
  };

  /** オーディオ出力。 */
  audio?: {
    /** @see https://learn.microsoft.com/ja-jp/uwp/schemas/tiles/toastschema/element-audio */
    src?: string;

    /** ループ再生するかどうか。 */
    loop?: boolean;

    /** 無音にするかどうか。 */
    silent?: boolean;
  };

  /** 通知の表示時間。 */
  duration?: "long" | "short";
}
