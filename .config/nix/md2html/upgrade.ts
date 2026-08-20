#!/usr/bin/env -S deno run -A
// md2html を指定バージョン（省略時は GitHub の最新リリース）へ更新する。
//
// 処理内容:
//   1. 対象バージョンを決定（引数 or GitHub releases の latest tag）
//   2. 配布 JS の hash を nix store prefetch-file で取得
//   3. md2html.nix の version / hash を反映
//
// git add / nix profile upgrade は行わない。完了後に git diff で確認し、手動で反映すること。
//
// 使い方:
//   deno task bump:md2html          # 最新へ
//   deno task bump:md2html 0.1.0    # 指定バージョンへ（先頭の v は省略可）

const REPO = "ansanloms/md2html";
const scriptDir = import.meta.dirname!;
const nixPath = `${scriptDir}/../md2html.nix`;

// リリースタグは v プレフィックス無し（例: 0.1.0）。
const url = (version: string) =>
  `https://github.com/${REPO}/releases/download/${version}/md2html`;

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

// 2. 配布 JS の hash を取得（SRI sha256- 形式でそのまま nix へ書ける）
console.log("hash を取得中...");
const prefetch = JSON.parse(
  await run("nix", ["store", "prefetch-file", "--json", url(version)]),
);
const hash: string = prefetch.hash;
console.log(`hash: ${hash}`);

// 3. md2html.nix へ反映
let nix = await Deno.readTextFile(nixPath);
nix = replaceNixString(nix, "version", version);
nix = replaceNixString(nix, "hash", hash);
await Deno.writeTextFile(nixPath, nix);

console.log("\n更新完了。git diff で確認し、問題なければ反映:");
console.log("  git add .config/nix/md2html.nix");
console.log("  nix profile upgrade --all --impure");
