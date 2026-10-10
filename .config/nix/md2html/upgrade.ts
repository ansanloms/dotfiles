#!/usr/bin/env -S deno run -A
// md2html を指定バージョン（省略時は GitHub の最新リリース）へ更新する。
//
// 処理内容:
//   1. 対象バージョンを決定（引数 or GitHub releases の latest tag）
//   2. Release の SHA256SUMS を gh で取得し、target ごとの sha256 を SRI 形式へ変換
//   3. md2html.nix の version / system 別 hash を反映
//
// git add / nix profile upgrade は行わない。完了後に git diff で確認し、手動で反映すること。
//
// 使い方:
//   deno task bump:md2html          # 最新へ
//   deno task bump:md2html 0.2.1    # 指定バージョンへ（先頭の v は省略可）

const REPO = "ansanloms/md2html";
const scriptDir = import.meta.dirname!;
const nixPath = `${scriptDir}/../md2html.nix`;

// nix の system -> Release 資産の target（md2html.nix の targets と同じ）。
// SHA256SUMS には darwin も載るが、nix に無い system は更新しない。
const TARGETS: Record<string, string> = {
  "x86_64-linux": "bun-linux-x64",
  "aarch64-linux": "bun-linux-arm64",
};

/** 外部コマンドを実行し、標準出力（trim 済み）を返す。非ゼロ終了で例外。 */
async function run(cmd: string, args: string[]): Promise<string> {
  const { code, stdout, stderr } = await new Deno.Command(cmd, {
    args,
    stdout: "piped",
    stderr: "piped",
  }).output();
  if (code !== 0) {
    console.error(new TextDecoder().decode(stderr));
    throw new Error(`コマンド失敗: ${cmd} ${args.join(" ")}`);
  }
  return new TextDecoder().decode(stdout).trim();
}

/** nix ファイル内の `<key> = "...";` の値を置換する（最初の 1 件）。 */
function replaceNixString(src: string, key: string, value: string): string {
  const re = new RegExp(`(\\b${key} = ")[^"]*(";)`);
  if (!re.test(src)) {
    throw new Error(`${nixPath} に ${key} の定義が見つからない`);
  }
  return src.replace(re, `$1${value}$2`);
}

// 1. 対象バージョンを決定（引数は誤って "v" 付きで指定された場合への防御として先頭の "v" を
//    除去する。タグ自体は v プレフィックス無しのため、自動取得した tag_name はそのまま使う）
const version = Deno.args[0]?.replace(/^v/, "") ??
  await run("gh", [
    "api",
    `repos/${REPO}/releases/latest`,
    "--jq",
    ".tag_name",
  ]);
console.log(`対象バージョン: ${version}`);

// 2. SHA256SUMS を取得（sha256sum 形式: `<hex>  <name>`）
console.log("SHA256SUMS を取得中...");
const sums = await run("gh", [
  "release",
  "download",
  version,
  "--repo",
  REPO,
  "--pattern",
  "SHA256SUMS",
  "-O",
  "-",
]);
const hexByName = new Map<string, string>();
for (const line of sums.split("\n")) {
  const m = line.trim().match(/^([0-9a-f]{64})\s+\*?(.+)$/);
  if (m) {
    hexByName.set(m[2], m[1]);
  }
}

/** hex 文字列を SRI（sha256-<base64>）へ変換する。 */
function toSri(hex: string): string {
  const bytes = Uint8Array.from(
    hex.match(/../g)!.map((b) => parseInt(b, 16)),
  );
  return `sha256-${btoa(String.fromCharCode(...bytes))}`;
}

const hashes: Record<string, string> = {};
for (const [system, target] of Object.entries(TARGETS)) {
  const hex = hexByName.get(`md2html-${target}`);
  if (!hex) {
    throw new Error(`SHA256SUMS に md2html-${target} が見つからない`);
  }
  hashes[system] = toSri(hex);
  console.log(`${system}: ${hashes[system]}`);
}

// 3. md2html.nix へ反映
let nix = await Deno.readTextFile(nixPath);
nix = replaceNixString(nix, "version", version);
for (const [system, hash] of Object.entries(hashes)) {
  // targets 側の `"<system>" = "bun-..."` に当たらないよう sha256- を前提にする。
  const re = new RegExp(`("${system}" = ")sha256-[^"]*(")`);
  if (!re.test(nix)) {
    throw new Error(`${nixPath} に ${system} の hash 定義が見つからない`);
  }
  nix = nix.replace(re, `$1${hash}$2`);
}
await Deno.writeTextFile(nixPath, nix);

console.log("\n更新完了。git diff で確認し、問題なければ反映:");
console.log("  git add .config/nix/md2html.nix");
console.log("  nix profile upgrade --all --impure");
