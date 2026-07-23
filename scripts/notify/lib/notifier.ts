import { extname } from "@std/path";

const PS_PATH = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";

/**
 * WSL パスかどうかを判定する。
 * `/` で始まるパスを WSL パスとみなす（Windows パスはドライブレターで始まる）。
 */
export const isWslPath = (path: string): boolean => {
  return path.startsWith("/");
};

/**
 * 通知本文向けに文字列をサニタイズする。
 * ANSI エスケープシーケンスと、XML 1.0 で不正な制御文字を除去する。
 * これらが残ると Windows 側の `XmlDocument.LoadXml` が
 * `WC_E_XMLCHARACTER` (HRESULT 0xC00CE508) で失敗し、通知が表示されない。
 * タブ・改行・復帰 (`\t` `\n` `\r`) は XML で有効なため保持する。
 */
export const sanitizeXmlText = (text: string): string => {
  // ANSI CSI エスケープシーケンス（色付け等）を除去する。
  // deno-lint-ignore no-control-regex
  const withoutAnsi = text.replace(/\x1b\[[0-9;]*[A-Za-z]/g, "");
  // XML 1.0 で不正な制御文字を除去する（\t \n \r は保持）。
  // deno-lint-ignore no-control-regex
  return withoutAnsi.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F]/g, "");
};

// 各テキスト要素の最大文字数。
// Windows トースト通知のペイロードには上限（約 5KB）があり、超えると
// `ToastNotification.Show` が「通知の内容のサイズが大きすぎます」で失敗して
// 何も表示されない。マルチバイト文字（UTF-8 で 1 文字最大 4 バイト）を考慮し、
// 合計が上限に収まる範囲で控えめに設定する。トーストは数行しか表示しないため、
// この長さでも視覚的な情報量は損なわれない。
const MAX_TITLE_LENGTH = 200;
const MAX_MESSAGE_LENGTH = 1000;
const MAX_ATTRIBUTION_LENGTH = 200;
const MAX_LABEL_LENGTH = 100;

/**
 * 文字列を指定した最大文字数に切り詰める。
 * 切り詰めた場合は末尾を省略記号（…）に置き換える。
 */
export const clampText = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) {
    return text;
  }
  return text.slice(0, maxLength - 1) + "…";
};

/**
 * Windows の TEMP フォルダーのパスを取得する。
 */
const getWindowsTempPath = async (): Promise<string> => {
  const cmd = new Deno.Command(PS_PATH, {
    args: ["-NoProfile", "-Command", "[System.IO.Path]::GetTempPath()"],
  });
  const result = await cmd.output();

  if (result.code !== 0) {
    throw new Error(
      `Failed to get TEMP path: ${new TextDecoder().decode(result.stderr)}`,
    );
  }

  return new TextDecoder().decode(result.stdout).trim();
};

/**
 * ファイルの SHA-256 ハッシュを16進文字列で返す。
 */
export const hashFile = async (path: string): Promise<string> => {
  const data = await Deno.readFile(path);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
};

/**
 * WSL パスの画像を Windows 側の TEMP フォルダーにコピーし、Windows パスを返す。
 * ハッシュベースのファイル名を使い、既にコピー済みならスキップする。
 * @param src WSL 上の画像パス
 * @returns Windows パス形式の一時ファイルパス
 */
const copyImageToWindowsTemp = async (
  src: string,
): Promise<string | undefined> => {
  let resolvedSrc: string;
  try {
    resolvedSrc = await Deno.realPath(src);
  } catch {
    return undefined;
  }

  const ext = extname(resolvedSrc);
  const hash = await hashFile(resolvedSrc);
  const tempDir = await getWindowsTempPath();
  const fileName = `notify-${hash}${ext}`;
  const winPath = `${tempDir}${fileName}`;

  const wslpathCmd = new Deno.Command("wslpath", {
    args: ["-u", winPath],
  });
  const wslpathResult = await wslpathCmd.output();
  const wslTmpPath = new TextDecoder().decode(wslpathResult.stdout).trim();

  try {
    await Deno.stat(wslTmpPath);
  } catch {
    await Deno.copyFile(resolvedSrc, wslTmpPath);
  }

  return winPath;
};

export interface NotifyRequest {
  /**
   * タイトル。
   */
  title: string;

  /**
   * メッセージ。
   */
  message: string;

  /**
   * 属性表示。
   */
  attribution?: string;

  /**
   * 通知クリック時に開く遷移先。
   */
  url?: string;

  /**
   * ボタン。
   */
  button?: {
    /**
     * ラベル。
     */
    label: string;

    /**
     * 遷移先。
     */
    src: string;
  }[];

  /**
   * 画像表示。
   */
  image?: {
    /**
     * 画像の配置。
     */
    placement?: "appLogoOverride" | "hero";

    /**
     * 画像のトリミング。
     */
    hintCrop?: "circle";

    /**
     * 画像のパス。
     */
    src: string;
  };

  /**
   * オーディオ出力。
   */
  audio?: {
    /**
     * @see https://learn.microsoft.com/ja-jp/uwp/schemas/tiles/toastschema/element-audio
     */
    src?: string;

    /**
     * ループ再生するかどうか。
     */
    loop?: boolean;

    /**
     * 無音にするかどうか。
     */
    silent?: boolean;
  };

  /**
   * 通知の表示時間。
   */
  duration?: "long" | "short";
}

export interface NotifyResponse {
  /**
   * 処理結果のステータス。
   */
  status: "ok" | "error";

  /**
   * エラー時のメッセージ。
   */
  error?: string;
}

/**
 * XML テキストノード向けにエスケープする（`&` `<` `>`）。
 * `"` `'` はテキストノードでは必須ではないため変換しない。
 * 制御文字は呼び出し前に sanitizeXmlText で除去している前提。
 */
const escapeXmlText = (text: string): string =>
  text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

/**
 * XML 属性値向けにエスケープする。属性は二重引用符で囲むため `"` も変換する。
 */
const escapeXmlAttr = (text: string): string =>
  escapeXmlText(text).replace(/"/g, "&quot;");

/**
 * 属性を 1 つ組み立てる。値が undefined の属性は出力しない。
 */
const attr = (name: string, value: string | undefined): string =>
  value === undefined ? "" : ` ${name}="${escapeXmlAttr(value)}"`;

/**
 * NotifyRequest から Windows トースト通知用の XML を構築する。
 *
 * 以前は xmlbuilder2 で組み立てていたが、同パッケージの依存 (@oozcitak/url) が
 * module 初期化時に `require("node:url")` を呼ぶため `deno bundle` した
 * 単一ファイル (.local/bin/notify) では `Dynamic require ... not supported` で
 * 起動に失敗する。toast XML は固定形・小規模なので、依存を持たずに文字列で
 * 組み立てる。エスケープは sanitizeXmlText で制御文字を除去した上で `&<>"` を
 * エンティティ化する。
 *
 * @param req 通知リクエスト
 * @returns Windows トースト通知用の XML 文字列
 */
export const buildToastXml = (req: NotifyRequest): string => {
  const launch = escapeXmlAttr(sanitizeXmlText(req.url ?? ""));
  const duration = escapeXmlAttr(req.duration ?? "short");

  const image = req.image
    ? `<image${attr("placement", req.image.placement)}${
      attr("hint-crop", req.image.hintCrop)
    }${attr("src", sanitizeXmlText(req.image.src))}/>`
    : "";

  const title = escapeXmlText(
    clampText(sanitizeXmlText(req.title), MAX_TITLE_LENGTH),
  );
  const message = escapeXmlText(
    clampText(sanitizeXmlText(req.message), MAX_MESSAGE_LENGTH),
  );

  const attribution = req.attribution
    ? `<text placement="attribution">${
      escapeXmlText(
        clampText(sanitizeXmlText(req.attribution), MAX_ATTRIBUTION_LENGTH),
      )
    }</text>`
    : "";

  let actionsInner = "";
  if (req.button) {
    for (const { label, src } of req.button) {
      const content = escapeXmlAttr(
        clampText(sanitizeXmlText(label), MAX_LABEL_LENGTH),
      );
      const args = escapeXmlAttr(sanitizeXmlText(src));
      actionsInner +=
        `<action content="${content}" activationType="protocol" arguments="${args}"/>`;
    }
  }
  const actions = actionsInner
    ? `<actions>${actionsInner}</actions>`
    : "<actions/>";

  const audio = req.audio
    ? `<audio src="${
      escapeXmlAttr(sanitizeXmlText(req.audio.src ?? ""))
    }" loop="${req.audio.loop ? "true" : "false"}" silent="${
      req.audio.silent ? "true" : "false"
    }"/>`
    : "";

  return `<toast launch="${launch}" duration="${duration}">` +
    `<visual><binding template="ToastGeneric">` +
    `${image}<text>${title}</text><text>${message}</text>${attribution}` +
    `</binding></visual>${actions}${audio}</toast>`;
};

/**
 * UTF-8 文字列を Base64 文字列へエンコードする。
 * `btoa` はバイナリ文字列（各文字が 1 バイト）しか扱えないため、
 * 先に UTF-8 バイト列へ変換してからエンコードする。
 */
const encodeUtf8Base64 = (text: string): string => {
  const bytes = new TextEncoder().encode(text);
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary);
};

/**
 * Windows トースト通知を送信するための PowerShell スクリプトを生成する。
 *
 * XML は Base64 へエンコードして渡し、PowerShell 側でデコードする。
 * 展開可能 here-string（`@"..."@`）に XML を直接埋め込む方式は、
 * 本文中のバッククォート（エスケープ文字）・`$`（変数展開）・`$(...)`（部分式実行）・
 * 行頭 `"@`（here-string の早期終了）を PowerShell が解釈してしまい、
 * 通知本文の破壊やスクリプトの構文エラーを引き起こす。
 * Base64 はこれらの特殊文字を含まないため、XML を純粋なデータとして渡せる。
 *
 * @param xmlContent トースト通知用の XML 文字列
 * @returns PowerShell スクリプト
 */
export const buildToastScript = (xmlContent: string): string => {
  const xmlBase64 = encodeUtf8Base64(xmlContent);

  return `
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

$app = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\\WindowsPowerShell\\v1.0\\powershell.exe'

$xml = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${xmlBase64}'))

$XmlDocument = [Windows.Data.Xml.Dom.XmlDocument]::new()
$XmlDocument.LoadXml($xml)

$toast = [Windows.UI.Notifications.ToastNotification]::new($XmlDocument)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($app).Show($toast)
`;
};

/**
 * Windows トースト通知を送信する。
 * PowerShell を介して Windows Toast Notification API を呼び出す。
 * @param req 通知リクエスト
 * @throws PowerShell の実行に失敗した場合にエラーをスロー
 */
export const sendWindowsNotification = async (
  req: NotifyRequest,
): Promise<void> => {
  if (req.image && isWslPath(req.image.src)) {
    const resolvedSrc = await copyImageToWindowsTemp(req.image.src);
    if (resolvedSrc) {
      req.image.src = resolvedSrc;
    } else {
      delete req.image;
    }
  }

  const script = buildToastScript(buildToastXml(req));

  // スクリプトはコマンドライン引数ではなく標準入力で渡す。
  // `-Command <script>` で引数として渡すと Windows のコマンドライン長上限
  // （約 32767 文字）に当たり、本文が大きいと powershell が
  // "Invalid argument" で失敗する。base64 化によりスクリプトは純 ASCII なので、
  // stdin の入力エンコーディングに依存せず安全に渡せる。
  const cmd = new Deno.Command(PS_PATH, {
    args: ["-NoProfile", "-Command", "-"],
    stdin: "piped",
    stdout: "piped",
    stderr: "piped",
  });
  const child = cmd.spawn();
  const writer = child.stdin.getWriter();
  await writer.write(new TextEncoder().encode(script));
  await writer.close();
  const { code, stdout, stderr } = await child.output();

  if (code !== 0) {
    const stdoutText = new TextDecoder().decode(stdout);
    const stderrText = new TextDecoder().decode(stderr);

    console.error("PowerShell execution failed:");
    console.error("Exit code:", code);
    if (stdoutText) {
      console.error("stdout:", stdoutText);
    }
    if (stderrText) {
      console.error("stderr:", stderrText);
    }

    throw new Error(`PowerShell exited with code ${code}`);
  }
};
