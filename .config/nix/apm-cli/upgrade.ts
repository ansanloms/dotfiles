#!/usr/bin/env -S deno run -A
// apm-cli を指定バージョン（省略時は GitHub の最新リリース）へ更新する。
//
// 処理内容:
//   1. 対象バージョンを決定（引数 or GitHub releases の latest tag。先頭の v は除く）
//   2. ソースツリーの hash を nix flake prefetch で取得
//   3. apm-cli.nix の version / hash を反映
//
// git add / deno task switch は行わない。完了後に git diff で確認し、手動で反映すること。
//
// 使い方:
//   deno task bump:apm-cli          # 最新へ
//   deno task bump:apm-cli 0.25.0   # 指定バージョンへ

const REPO = "microsoft/apm";
const scriptDir = import.meta.dirname!;
const nixPath = `${scriptDir}/../apm-cli.nix`;

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

// 1. 対象バージョンを決定（tag は v プレフィックス付きで配布される）
const version = (Deno.args[0] ??
  await run("gh", [
    "api",
    `repos/${REPO}/releases/latest`,
    "--jq",
    ".tag_name",
  ])).replace(/^v/, "");
console.log(`対象バージョン: ${version}`);

// 2. hash を取得（fetchFromGitHub は fetchTree 系のため flake prefetch の
//    narHash がそのまま hash として使える）
console.log("hash を取得中...");
const prefetch = JSON.parse(
  await run("nix", [
    "flake",
    "prefetch",
    `github:${REPO}/v${version}`,
    "--json",
  ]),
);
const hash: string = prefetch.hash;
console.log(`hash: ${hash}`);

// 3. apm-cli.nix へ反映
let nix = await Deno.readTextFile(nixPath);
nix = replaceNixString(nix, "version", version);
nix = replaceNixString(nix, "hash", hash);
await Deno.writeTextFile(nixPath, nix);

console.log("\n更新完了。git diff で確認し、問題なければ反映:");
console.log("  git add .config/nix/apm-cli.nix");
console.log("  deno task switch");
