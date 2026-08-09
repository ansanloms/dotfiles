#!/usr/bin/env -S deno run -A
// google-health-cli を main ブランチの指定コミット（省略時は HEAD）へ更新する。
//
// upstream にタグ・リリースが無いため、tag ではなく main の特定コミットに pin する。
//
// 処理内容:
//   1. 対象コミットを決定（引数 or `git ls-remote ... main` の HEAD）
//   2. `nix flake prefetch` で fetchFromGitHub 用 hash を得る
//   3. `gh api` でコミットの committer date を取得し、version を
//      `0-unstable-YYYY-MM-DD` 形式に組み立てる
//   4. google-health-cli.nix の version / rev / hash を反映
//
// vendorHash は go.mod / go.sum が変わったときのみずれる。反映対象外のため、
// ビルドエラーの got: に出る hash を google-health-cli.nix へ手動で更新すること。
//
// git add / deno task switch は行わない。完了後に git diff で確認し、手動で反映すること。
//
// 使い方:
//   deno task bump:google-health-cli            # main HEAD へ
//   deno task bump:google-health-cli <commit>   # 指定コミットへ

const REPO = "https://github.com/Google-Health-API/google-health-cli.git";
const scriptDir = import.meta.dirname!;
const nixPath = `${scriptDir}/../google-health-cli.nix`;

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
  const out = await run("git", ["ls-remote", REPO, "main"]);
  rev = out.split(/\s+/)[0];
}
if (!/^[0-9a-f]{40}$/.test(rev)) {
  throw new Error(`コミットハッシュが不正: ${rev}`);
}
console.log(`対象コミット: ${rev}`);

// 2. hash を取得（fetchFromGitHub は fetchTree 系のため flake prefetch の hash がそのまま使える）
console.log("hash を取得中...");
const prefetch = JSON.parse(
  await run("nix", [
    "flake",
    "prefetch",
    `github:Google-Health-API/google-health-cli/${rev}`,
    "--json",
  ]),
);
const hash: string = prefetch.hash;
console.log(`hash: ${hash}`);

// 3. version をコミット日時から組み立て
console.log("コミット日時を取得中...");
const committerDate = await run("gh", [
  "api",
  `repos/Google-Health-API/google-health-cli/commits/${rev}`,
  "--jq",
  ".commit.committer.date",
]);
const date = committerDate.slice(0, 10);
if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
  throw new Error(`コミット日時が不正: ${committerDate}`);
}
const version = `0-unstable-${date}`;
console.log(`version: ${version}`);

// 4. google-health-cli.nix へ反映
let nix = await Deno.readTextFile(nixPath);
nix = replaceNixString(nix, "version", version);
nix = replaceNixString(nix, "rev", rev);
nix = replaceNixString(nix, "hash", hash);
await Deno.writeTextFile(nixPath, nix);

console.log("\n更新完了。git diff で確認し、問題なければ反映:");
console.log("  git add .config/nix/google-health-cli.nix");
console.log("  deno task switch");
console.log(
  "\n注意: vendorHash は更新していない。go.mod / go.sum が変わっていた場合は",
);
console.log("ビルドエラーの got: に出る hash を手動で反映すること。");
