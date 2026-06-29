#!/usr/bin/env -S deno run --quiet --allow-env --allow-run --allow-read --allow-write

// Windows ホストのクリップボード上の画像 (Win+Shift+S のキャプチャ等) を
// WSL 側の PNG ファイルに保存し、その絶対パスを stdout に出力する。
//
// 用途:
//   - nvim:        :r !clip-image  /  :put =system('clip-image')->trim()
//   - claude code: シェルから実行してパスを得る (Claude にこの画像を見せる等)
//
// 設計:
//   - stdout には保存先の WSL 絶対パスのみを出す。進捗・エラーは stderr。
//     これで `:r !` や `$(clip-image)` に混ぜても余計な文字列が紛れない。
//   - powershell は native NTFS の一時領域へ書き、コピーは WSL 側で行う。
//     9P 共有を「Windows -> WSL 直書き」ではなく「WSL -> NTFS 読み」の向きで
//     使うことで、.NET の Image.Save が \\wsl$ パスで稀に転ける問題を避ける。

// クリップボード画像を Windows の一時 PNG に保存し、その Windows パスを stdout に返す
// PowerShell スクリプト。画像が無ければ exit 3。STA でないと Clipboard API が使えないため
// powershell.exe を -STA で起動する。
const psScript = [
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

function die(message: string): never {
  console.error(`clip-image: ${message}`);
  Deno.exit(1);
}

// 2 桁・3 桁ゼロ詰め。
const pad = (n: number, width = 2) => String(n).padStart(width, "0");

// クリップボード画像を Windows の一時 PNG に書き出す。
const ps = await new Deno.Command("powershell.exe", {
  args: ["-NoProfile", "-STA", "-Command", psScript],
  stdout: "piped",
  stderr: "piped",
}).output();

if (ps.code === 3) {
  die("クリップボードに画像がない");
}
if (!ps.success) {
  const err = new TextDecoder().decode(ps.stderr).trim();
  die(`powershell 失敗: ${err || `exit ${ps.code}`}`);
}

const winPath = new TextDecoder().decode(ps.stdout).trim();
if (winPath === "") {
  die("一時ファイルのパスを取得できなかった");
}

// Windows パス (C:\...) を WSL パス (/mnt/c/...) へ変換する。
const wp = await new Deno.Command("wslpath", {
  args: ["-u", winPath],
  stdout: "piped",
  stderr: "piped",
}).output();

if (!wp.success) {
  const err = new TextDecoder().decode(wp.stderr).trim();
  die(`wslpath 失敗: ${err || `exit ${wp.code}`}`);
}

const tmpWslPath = new TextDecoder().decode(wp.stdout).trim();

// 保存先: $XDG_CACHE_HOME/clip-image または ~/.cache/clip-image。
const cacheHome = Deno.env.get("XDG_CACHE_HOME") ||
  `${Deno.env.get("HOME")}/.cache`;
const destDir = `${cacheHome}/clip-image`;
await Deno.mkdir(destDir, { recursive: true });

const now = new Date();
const stamp =
  `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}` +
  `-${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}` +
  `-${pad(now.getMilliseconds(), 3)}`;
const destPath = `${destDir}/clip-${stamp}.png`;

// native NTFS の一時 PNG を ext4 のキャッシュへコピーし、一時ファイルを削除する。
await Deno.copyFile(tmpWslPath, destPath);
try {
  await Deno.remove(tmpWslPath);
} catch {
  // 一時ファイルの削除失敗は致命的ではないため握りつぶす。
}

// 機械可読な出力は保存先パスのみ。
console.log(destPath);
