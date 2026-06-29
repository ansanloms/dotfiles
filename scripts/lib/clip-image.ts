// clip-image の純粋ロジックとオーケストレーション。
// 副作用 (powershell / wslpath / fs / tty / 時刻 / 環境変数) はすべて
// ClipImageDeps として注入する。エントリポイント (scripts/clip-image.ts) が
// 実物の副作用を組み立てて run() を呼ぶ。

/**
 * クリップボード画像を Windows の一時 PNG に保存し、その Windows パスを stdout に返す
 * PowerShell スクリプト。画像が無ければ exit 3。STA でないと Clipboard API が使えない。
 */
export const PS_SCRIPT = [
  "try {",
  "  Add-Type -AssemblyName System.Windows.Forms,System.Drawing",
  "  $img = [System.Windows.Forms.Clipboard]::GetImage()",
  "  if ($null -eq $img) { exit 3 }",
  "  $p = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString() + '.png')",
  "  $img.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)",
  "  [Console]::Out.Write($p)",
  "} catch {",
  "  [Console]::Error.Write($_.Exception.Message)",
  "  exit 1",
  "}",
].join("\n");

/** 2 桁・3 桁ゼロ詰め。 */
const pad = (n: number, width = 2): string => String(n).padStart(width, "0");

/** Date をファイル名用のタイムスタンプ (YYYYMMDD-HHMMSS-mmm) に整形する。 */
export function formatStamp(date: Date): string {
  return `${date.getFullYear()}${pad(date.getMonth() + 1)}${
    pad(date.getDate())
  }` +
    `-${pad(date.getHours())}${pad(date.getMinutes())}${
      pad(date.getSeconds())
    }` +
    `-${pad(date.getMilliseconds(), 3)}`;
}

/** タイムスタンプから保存ファイル名を作る。 */
export function destFileName(stamp: string): string {
  return `clip-${stamp}.png`;
}

/**
 * テキストをクリップボードへ載せる OSC 52 エスケープシーケンスのバイト列を作る。
 * 形式: ESC ] 52 ; c ; <base64> BEL
 */
export function osc52(text: string): Uint8Array {
  const b64 = btoa(String.fromCharCode(...new TextEncoder().encode(text)));
  return new TextEncoder().encode(`\x1b]52;c;${b64}\x07`);
}

/** 保存先ディレクトリを解決する: $XDG_CACHE_HOME/clip-image または ~/.cache/clip-image。 */
export function resolveCacheDir(
  env: { get(key: string): string | undefined },
): string {
  const cacheHome = env.get("XDG_CACHE_HOME") || `${env.get("HOME")}/.cache`;
  return `${cacheHome}/clip-image`;
}

/** --copy-path / -c が指定されているか。 */
export function hasCopyPathFlag(args: string[]): boolean {
  return args.includes("--copy-path") || args.includes("-c");
}

export interface CommandResult {
  code: number;
  success: boolean;
  stdout: string;
  stderr: string;
}

export interface ClipImageDeps {
  args: string[];
  env: { get(key: string): string | undefined };
  now(): Date;
  runPowershell(script: string): Promise<CommandResult>;
  runWslpath(winPath: string): Promise<CommandResult>;
  mkdirp(dir: string): Promise<void>;
  copyFile(src: string, dest: string): Promise<void>;
  removeFile(path: string): Promise<void>;
  writeClipboard(bytes: Uint8Array): void;
  stdout(line: string): void;
  stderr(line: string): void;
}

/**
 * クリップボード画像を WSL の PNG へ保存し、保存先パスを stdout へ出す。
 * 終了コードを返す (0 = 成功, 1 = 失敗)。
 */
export async function run(deps: ClipImageDeps): Promise<number> {
  const copyPath = hasCopyPathFlag(deps.args);

  const ps = await deps.runPowershell(PS_SCRIPT);
  if (ps.code === 3) {
    deps.stderr("clip-image: クリップボードに画像がない");
    return 1;
  }
  if (!ps.success) {
    deps.stderr(
      `clip-image: powershell 失敗: ${ps.stderr.trim() || `exit ${ps.code}`}`,
    );
    return 1;
  }

  const winPath = ps.stdout.trim();
  if (winPath === "") {
    deps.stderr("clip-image: 一時ファイルのパスを取得できなかった");
    return 1;
  }

  const wp = await deps.runWslpath(winPath);
  if (!wp.success) {
    deps.stderr(
      `clip-image: wslpath 失敗: ${wp.stderr.trim() || `exit ${wp.code}`}`,
    );
    return 1;
  }
  const tmpWslPath = wp.stdout.trim();

  const destDir = resolveCacheDir(deps.env);
  await deps.mkdirp(destDir);

  const destPath = `${destDir}/${destFileName(formatStamp(deps.now()))}`;

  await deps.copyFile(tmpWslPath, destPath);
  try {
    await deps.removeFile(tmpWslPath);
  } catch {
    // 一時ファイルの削除失敗は致命的ではないため握りつぶす。
  }

  if (copyPath) {
    deps.writeClipboard(osc52(destPath));
    deps.stderr("clip-image: パスをクリップボードへコピーした");
  }

  deps.stdout(destPath);
  return 0;
}
