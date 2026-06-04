#!/usr/bin/env -S deno run -A
// apm を指定バージョン（省略時は GitHub の最新リリース）へ更新する。
//
// 処理内容:
//   1. 各プラットフォームの tarball ハッシュを取得
//   2. apm.nix の version / 各 hash を反映
//
// git add / deno task switch は行わない。完了後に git diff で確認し、手動で反映すること。
//
// 使い方:
//   deno task bump:apm           # 最新へ
//   deno task bump:apm 0.16.1    # 指定バージョンへ

// apm.nix の sources に対応するリリースアセット名。
const ASSETS = [
  "apm-linux-x86_64",
  "apm-linux-arm64",
  "apm-darwin-x86_64",
  "apm-darwin-arm64",
];

const scriptDir = import.meta.dirname!;
const nixPath = `${scriptDir}/../apm.nix`;

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

/** 正規表現の特殊文字をエスケープする。 */
function escapeRe(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// バージョン決定（引数優先、なければ最新リリースの tag）。先頭の v は剥がす。
let version = Deno.args[0];
if (!version) {
  version = await run("gh", [
    "api",
    "repos/microsoft/apm/releases/latest",
    "--jq",
    ".tag_name",
  ]);
}
version = version.replace(/^v/, "");
console.log(`対象バージョン: ${version}`);

// 1. 各アセットのハッシュを取得（SRI 形式）
const hashes: Record<string, string> = {};
for (const asset of ASSETS) {
  const url =
    `https://github.com/microsoft/apm/releases/download/v${version}/${asset}.tar.gz`;
  console.log(`prefetch: ${asset} ...`);
  const out = await run("nix", ["store", "prefetch-file", "--json", url]);
  hashes[asset] = JSON.parse(out).hash;
  console.log(`  ${hashes[asset]}`);
}

// 2. apm.nix へ反映
let nix = await Deno.readTextFile(nixPath);

// version
const verRe = /(\bversion = ")[^"]*(";)/;
if (!verRe.test(nix)) throw new Error(`${nixPath} に version の定義が見つからない`);
nix = nix.replace(verRe, `$1${version}$2`);

// 各 asset に対応する hash（asset 行をアンカーに直後の hash 行を置換）
for (const asset of ASSETS) {
  const re = new RegExp(
    `(asset = "${escapeRe(asset)}";\\s*\\n\\s*hash = ")[^"]*(")`,
  );
  if (!re.test(nix)) {
    throw new Error(`${nixPath} に ${asset} の hash 定義が見つからない`);
  }
  nix = nix.replace(re, `$1${hashes[asset]}$2`);
}

await Deno.writeTextFile(nixPath, nix);

console.log("\n更新完了。git diff で確認し、問題なければ反映:");
console.log("  git add .config/nix/apm.nix");
console.log("  deno task switch");
