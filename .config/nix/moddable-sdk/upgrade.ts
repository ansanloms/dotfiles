#!/usr/bin/env -S deno run -A
// moddable-sdk を public ブランチの指定コミット（省略時は HEAD）へ更新する。
//
// Moddable はタグ付きリリースが古く（2022 年止まり）、現行ツールは public ブランチで
// 配布される。そのため tag ではなく public の特定コミットに pin する。
//
// 処理内容:
//   1. 対象コミットを決定（引数 or `git ls-remote ... public` の HEAD）
//   2. `nix flake prefetch` で fetchFromGitHub 用 hash と取得済みツリーの storePath を得る
//   3. storePath の tools/VERSION を version 文字列に反映
//   4. moddable-sdk.nix の rev / hash / version を反映
//
// git add / deno task switch は行わない。完了後に git diff で確認し、手動で反映すること。
//
// 使い方:
//   deno task bump:moddable-sdk            # public HEAD へ
//   deno task bump:moddable-sdk <commit>   # 指定コミットへ

const REPO = "https://github.com/Moddable-OpenSource/moddable.git";
const scriptDir = import.meta.dirname!;
const nixPath = `${scriptDir}/../moddable-sdk.nix`;

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

// 1. 対象コミットを決定
let rev = Deno.args[0];
if (!rev) {
  const out = await run("git", ["ls-remote", REPO, "public"]);
  rev = out.split(/\s+/)[0];
}
if (!/^[0-9a-f]{40}$/.test(rev)) {
  throw new Error(`コミットハッシュが不正: ${rev}`);
}
console.log(`対象コミット: ${rev}`);

// 2. hash と storePath を取得（fetchFromGitHub は fetchTree 系のため flake prefetch の
//    narHash がそのまま hash として使える）
console.log("hash を取得中...");
const prefetch = JSON.parse(
  await run("nix", [
    "flake",
    "prefetch",
    `github:Moddable-OpenSource/moddable/${rev}`,
    "--json",
  ]),
);
const hash: string = prefetch.hash;
const storePath: string = prefetch.storePath;
console.log(`hash: ${hash}`);

// 3. version を tools/VERSION から取得
const version = (await Deno.readTextFile(`${storePath}/tools/VERSION`)).trim();
console.log(`version: ${version}`);

// 4. moddable-sdk.nix へ反映
let nix = await Deno.readTextFile(nixPath);
nix = replaceNixString(nix, "version", version);
nix = replaceNixString(nix, "rev", rev);
nix = replaceNixString(nix, "hash", hash);
await Deno.writeTextFile(nixPath, nix);

console.log("\n更新完了。git diff で確認し、問題なければ反映:");
console.log("  git add .config/nix/moddable-sdk.nix");
console.log("  deno task switch");
