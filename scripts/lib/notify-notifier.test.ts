import { assertEquals, assertStringIncludes } from "@std/assert";
import {
  buildToastScript,
  buildToastXml,
  clampText,
  hashFile,
  isWslPath,
  sanitizeXmlText,
} from "./notify-notifier.ts";
import type { NotifyRequest } from "./notify-notifier.ts";

// --- isWslPath ---

Deno.test("isWslPath - `/` で始まるパスは WSL パスと判定されること。", () => {
  assertEquals(isWslPath("/home/user/image.png"), true);
});

Deno.test("isWslPath - `/mnt/` で始まるパスも WSL パスと判定されること。", () => {
  assertEquals(isWslPath("/mnt/c/Users/user/image.png"), true);
});

Deno.test("isWslPath - Windows パスは WSL パスと判定されないこと。", () => {
  assertEquals(isWslPath("C:\\Users\\user\\image.png"), false);
});

Deno.test("isWslPath - 空文字列は WSL パスと判定されないこと。", () => {
  assertEquals(isWslPath(""), false);
});

// --- hashFile ---

Deno.test("hashFile - 同じ内容のファイルは同じハッシュを返すこと。", async () => {
  const tmp1 = await Deno.makeTempFile();
  const tmp2 = await Deno.makeTempFile();
  try {
    await Deno.writeTextFile(tmp1, "hello");
    await Deno.writeTextFile(tmp2, "hello");
    const hash1 = await hashFile(tmp1);
    const hash2 = await hashFile(tmp2);
    assertEquals(hash1, hash2);
  } finally {
    await Deno.remove(tmp1);
    await Deno.remove(tmp2);
  }
});

Deno.test("hashFile - 異なる内容のファイルは異なるハッシュを返すこと。", async () => {
  const tmp1 = await Deno.makeTempFile();
  const tmp2 = await Deno.makeTempFile();
  try {
    await Deno.writeTextFile(tmp1, "hello");
    await Deno.writeTextFile(tmp2, "world");
    const hash1 = await hashFile(tmp1);
    const hash2 = await hashFile(tmp2);
    assertEquals(hash1 !== hash2, true);
  } finally {
    await Deno.remove(tmp1);
    await Deno.remove(tmp2);
  }
});

Deno.test("hashFile - SHA-256 の16進文字列（64文字）を返すこと。", async () => {
  const tmp = await Deno.makeTempFile();
  try {
    await Deno.writeTextFile(tmp, "test");
    const hash = await hashFile(tmp);
    assertEquals(hash.length, 64);
    assertEquals(/^[0-9a-f]{64}$/.test(hash), true);
  } finally {
    await Deno.remove(tmp);
  }
});

// --- buildToastXml ---

Deno.test("buildToastXml - タイトルとメッセージのみの基本的な通知を生成できること。", () => {
  const req: NotifyRequest = {
    title: "Test Title",
    message: "Test Message",
  };

  const xml = buildToastXml(req);

  assertStringIncludes(xml, "<toast");
  assertStringIncludes(xml, "<text>Test Title</text>");
  assertStringIncludes(xml, "<text>Test Message</text>");
});

Deno.test("buildToastXml - URL付きの通知を生成できること。", () => {
  const req: NotifyRequest = {
    title: "Test Title",
    message: "Test Message",
    url: "https://example.com",
  };

  const xml = buildToastXml(req);

  assertStringIncludes(xml, 'launch="https://example.com"');
});

Deno.test("buildToastXml - 画像付きの通知を生成できること。", () => {
  const req: NotifyRequest = {
    title: "Test Title",
    message: "Test Message",
    image: {
      placement: "appLogoOverride",
      src: "C:\\path\\to\\icon.png",
    },
  };

  const xml = buildToastXml(req);

  assertStringIncludes(xml, "<image");
  assertStringIncludes(xml, 'placement="appLogoOverride"');
  assertStringIncludes(xml, 'src="C:\\path\\to\\icon.png"');
});

Deno.test("buildToastXml - hero 画像付きの通知を生成できること。", () => {
  const req: NotifyRequest = {
    title: "Test Title",
    message: "Test Message",
    image: {
      placement: "hero",
      src: "C:\\path\\to\\hero.png",
    },
  };

  const xml = buildToastXml(req);

  assertStringIncludes(xml, 'placement="hero"');
  assertStringIncludes(xml, 'src="C:\\path\\to\\hero.png"');
});

Deno.test("buildToastXml - hint-crop 付き画像の通知を生成できること。", () => {
  const req: NotifyRequest = {
    title: "Test Title",
    message: "Test Message",
    image: {
      placement: "appLogoOverride",
      hintCrop: "circle",
      src: "C:\\path\\to\\avatar.png",
    },
  };

  const xml = buildToastXml(req);

  assertStringIncludes(xml, 'hint-crop="circle"');
});

Deno.test("buildToastXml - ボタン付きの通知を生成できること。", () => {
  const req: NotifyRequest = {
    title: "Test Title",
    message: "Test Message",
    button: [
      { label: "Open", src: "https://example.com" },
      { label: "Dismiss", src: "https://example.com/dismiss" },
    ],
  };

  const xml = buildToastXml(req);

  assertStringIncludes(xml, "<actions>");
  assertStringIncludes(xml, 'content="Open"');
  assertStringIncludes(xml, 'arguments="https://example.com"');
  assertStringIncludes(xml, 'content="Dismiss"');
  assertStringIncludes(xml, 'arguments="https://example.com/dismiss"');
});

Deno.test("buildToastXml - タイトル内のXML特殊文字をエスケープすること。", () => {
  const req: NotifyRequest = {
    title: 'Test <Title> & "Quote"',
    message: "Test Message",
  };

  const xml = buildToastXml(req);

  // xmlbuilder2 escapes <, >, & in text nodes (", ' are not required to be escaped)
  assertStringIncludes(xml, "&lt;");
  assertStringIncludes(xml, "&gt;");
  assertStringIncludes(xml, "&amp;");
});

Deno.test("buildToastXml - メッセージ内のXML特殊文字をエスケープすること。", () => {
  const req: NotifyRequest = {
    title: "Test Title",
    message: "Message with <tags> & 'apostrophes'",
  };

  const xml = buildToastXml(req);

  // xmlbuilder2 escapes <, >, & in text nodes (', " are not required to be escaped)
  assertStringIncludes(xml, "&lt;tags&gt;");
  assertStringIncludes(xml, "&amp;");
});

Deno.test("buildToastXml - ボタンラベル内のXML特殊文字をエスケープすること。", () => {
  const req: NotifyRequest = {
    title: "Test Title",
    message: "Test Message",
    button: [
      { label: "Open <Now>", src: "https://example.com" },
    ],
  };

  const xml = buildToastXml(req);

  assertStringIncludes(xml, "Open &lt;Now&gt;");
});

Deno.test("buildToastXml - 全てのオプションを含む通知を生成できること。", () => {
  const req: NotifyRequest = {
    title: "Build Complete",
    message: "Your project has been built successfully",
    url: "https://example.com/build/123",
    image: {
      placement: "appLogoOverride",
      src: "C:\\icons\\build.png",
    },
    button: [
      { label: "View Details", src: "https://example.com/build/123" },
      { label: "Dismiss", src: "dismiss://action" },
    ],
  };

  const xml = buildToastXml(req);

  assertStringIncludes(xml, "<toast");
  assertStringIncludes(xml, 'launch="https://example.com/build/123"');
  assertStringIncludes(xml, "<text>Build Complete</text>");
  assertStringIncludes(
    xml,
    "<text>Your project has been built successfully</text>",
  );
  assertStringIncludes(xml, 'src="C:\\icons\\build.png"');
  assertStringIncludes(xml, 'content="View Details"');
  assertStringIncludes(xml, 'content="Dismiss"');
});

Deno.test("buildToastXml - URLが空の場合は空のlaunch属性になること。", () => {
  const req: NotifyRequest = {
    title: "Test Title",
    message: "Test Message",
  };

  const xml = buildToastXml(req);

  assertStringIncludes(xml, 'launch=""');
});

Deno.test("buildToastXml - attribution 付きの通知を生成できること。", () => {
  const req: NotifyRequest = {
    title: "Test Title",
    message: "Test Message",
    attribution: "via WSL",
  };

  const xml = buildToastXml(req);

  assertStringIncludes(xml, 'placement="attribution"');
  assertStringIncludes(xml, "via WSL");
});

Deno.test("buildToastXml - audio 付きの通知を生成できること。", () => {
  const req: NotifyRequest = {
    title: "Test Title",
    message: "Test Message",
    audio: {
      src: "ms-winsoundevent:Notification.Default",
      loop: true,
      silent: false,
    },
  };

  const xml = buildToastXml(req);

  assertStringIncludes(xml, "<audio");
  assertStringIncludes(
    xml,
    'src="ms-winsoundevent:Notification.Default"',
  );
  assertStringIncludes(xml, 'loop="true"');
  assertStringIncludes(xml, 'silent="false"');
});

Deno.test("buildToastXml - duration を long に設定できること。", () => {
  const req: NotifyRequest = {
    title: "Test Title",
    message: "Test Message",
    duration: "long",
  };

  const xml = buildToastXml(req);

  assertStringIncludes(xml, 'duration="long"');
});

// --- sanitizeXmlText ---

Deno.test("sanitizeXmlText - 通常のテキストはそのまま返すこと。", () => {
  assertEquals(sanitizeXmlText("Build complete"), "Build complete");
});

Deno.test("sanitizeXmlText - タブ・改行・復帰は保持すること。", () => {
  assertEquals(sanitizeXmlText("a\tb\nc\r\n"), "a\tb\nc\r\n");
});

Deno.test("sanitizeXmlText - NUL 文字を除去すること。", () => {
  assertEquals(sanitizeXmlText("before\x00after"), "beforeafter");
});

Deno.test("sanitizeXmlText - その他の XML 不正な制御文字を除去すること。", () => {
  assertEquals(sanitizeXmlText("a\x01b\x08c\x0Bd\x1Fe"), "abcde");
});

Deno.test("sanitizeXmlText - ANSI CSI エスケープシーケンスを除去すること。", () => {
  assertEquals(
    sanitizeXmlText("\x1b[31mred\x1b[0m text"),
    "red text",
  );
});

Deno.test("sanitizeXmlText - `$` とバッククォートは制御文字ではないため保持すること。", () => {
  // PowerShell では特殊だが XML テキストとしては有効。伝送方式(Base64)側で無害化する。
  assertEquals(
    sanitizeXmlText("cost $5 run `npm test` $(date)"),
    "cost $5 run `npm test` $(date)",
  );
});

// --- buildToastXml: 制御文字混入時の XML 妥当性 ---

Deno.test("buildToastXml - 本文の制御文字を除去し XML に残さないこと。", () => {
  const req: NotifyRequest = {
    title: "ok\x00",
    message: "ansi \x1b[31mred\x1b[0m and \x01ctrl",
  };

  const xml = buildToastXml(req);

  // LoadXml を失敗させる制御文字が残っていないこと。
  // deno-lint-ignore no-control-regex
  assertEquals(/[\x00-\x08\x0B\x0C\x0E-\x1F]/.test(xml), false);
  assertStringIncludes(xml, "<text>ok</text>");
  assertStringIncludes(xml, "ansi red and ctrl");
});

Deno.test("buildToastXml - `$` やバッククォートを含む本文を XML にリテラル保持すること。", () => {
  const req: NotifyRequest = {
    title: "t",
    message: "run `npm test`; cost $5; $(hostname)",
  };

  const xml = buildToastXml(req);

  // 伝送が Base64 化されたため、これらは XML にそのまま残してよい。
  assertStringIncludes(xml, "run `npm test`; cost $5; $(hostname)");
});

// --- buildToastScript: Base64 伝送 ---

Deno.test("buildToastScript - 展開可能 here-string を使わないこと。", () => {
  const xml = buildToastXml({ title: "t", message: "m" });
  const script = buildToastScript(xml);

  // `@"` (展開可能 here-string の開始) を含まないこと。
  assertEquals(script.includes('@"'), false);
  assertStringIncludes(script, "FromBase64String");
});

// --- clampText ---

Deno.test("clampText - 上限以下の文字列はそのまま返すこと。", () => {
  assertEquals(clampText("hello", 10), "hello");
});

Deno.test("clampText - 上限を超える文字列を切り詰めて省略記号を付けること。", () => {
  const result = clampText("a".repeat(100), 10);
  assertEquals(result.length, 10);
  assertEquals(result.endsWith("…"), true);
  assertEquals(result, "a".repeat(9) + "…");
});

Deno.test("buildToastXml - 長すぎるメッセージを切り詰めること。", () => {
  // トースト通知のペイロード上限(約5KB)を超えると Show が失敗するため切り詰める。
  const req: NotifyRequest = {
    title: "t",
    message: "a".repeat(5000),
  };

  const xml = buildToastXml(req);

  // 1000 文字を超える連続は残らないこと（省略記号で打ち切られる）。
  assertEquals(xml.includes("a".repeat(1000)), false);
  assertStringIncludes(xml, "…");
});

Deno.test("buildToastScript - 生成スクリプトが ASCII のみであること。", () => {
  // スクリプトは標準入力で渡すため、非 ASCII が混じると入力エンコーディング次第で
  // 壊れる。XML を Base64 化しているので、多バイト本文でもスクリプトは ASCII に保たれる。
  const xml = buildToastXml({ title: "完了 🎉", message: "日本語 `$(x)`" });
  const script = buildToastScript(xml);

  assertEquals([...script].every((c) => c.charCodeAt(0) < 128), true);
});

Deno.test("buildToastScript - XML を Base64 で round-trip できること。", () => {
  // PowerShell が解釈してしまう文字を含む本文でも壊れずに復元できること。
  const xml = buildToastXml({
    title: "完了 🎉",
    message: 'run `npm test`; $(hostname); cost $5; line\n"@',
  });
  const script = buildToastScript(xml);

  const match = script.match(/FromBase64String\('([^']+)'\)/);
  assertEquals(match !== null, true);

  const base64 = match![1];
  const decoded = new TextDecoder().decode(
    Uint8Array.from(atob(base64), (c) => c.charCodeAt(0)),
  );

  assertEquals(decoded, xml);
});
