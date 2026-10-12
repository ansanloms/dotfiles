#!/usr/bin/env -S deno run -A
// claude-statusline を指定バージョン（省略時は GitHub の最新リリース）へ更新する。
//
// 処理内容:
//   1. 対象バージョンを決定（引数 or GitHub releases の latest tag）
//   2. target ごとの配布バイナリの hash を nix store prefetch-file で取得
//   3. claude-statusline.nix の version / system 別 hash を反映
//
// git add / nix profile upgrade は行わない。完了後に git diff で確認し、手動で反映すること。
//
// 使い方:
//   deno task bump:claude-statusline          # 最新へ
//   deno task bump:claude-statusline 0.1.0   # 指定バージョンへ

const REPO = "ansanloms/claude-statusline";
const scriptDir = import.meta.dirname!;
const nixPath = `${scriptDir}/../claude-statusline.nix`;

// nix の system -> Release 資産の target（claude-statusline.nix の targets と同じ）。
const TARGETS: Record<string, string> = {
  "x86_64-linux": "linux-x64",
  "aarch64-linux": "linux-arm64",
};

const url = (version: string, target: string) =>
  `https://github.com/${REPO}/releases/download/${version}/claude-statusline-${target}`;

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

// 1. 対象バージョンを決定（タグ = version）
const version = Deno.args[0] ??
  await run("gh", [
    "api",
    `repos/${REPO}/releases/latest`,
    "--jq",
    ".tag_name",
  ]);
console.log(`対象バージョン: ${version}`);

// 2. target ごとの hash を取得（SRI sha256- 形式でそのまま nix へ書ける）
const hashes: Record<string, string> = {};
for (const [system, target] of Object.entries(TARGETS)) {
  console.log(`${system}: hash を取得中...`);
  const prefetch = JSON.parse(
    await run("nix", [
      "store",
      "prefetch-file",
      "--json",
      url(version, target),
    ]),
  );
  hashes[system] = prefetch.hash;
  console.log(`${system}: ${hashes[system]}`);
}

// 3. claude-statusline.nix へ反映
let nix = await Deno.readTextFile(nixPath);
nix = replaceNixString(nix, "version", version);
for (const [system, hash] of Object.entries(hashes)) {
  // targets 側の `"<system>" = "linux-..."` に当たらないよう sha256- を前提にする。
  const re = new RegExp(`("${system}" = ")sha256-[^"]*(")`);
  if (!re.test(nix)) {
    throw new Error(`${nixPath} に ${system} の hash 定義が見つからない`);
  }
  nix = nix.replace(re, `$1${hash}$2`);
}
await Deno.writeTextFile(nixPath, nix);

console.log("\n更新完了。git diff で確認し、問題なければ反映:");
console.log("  git add .config/nix/claude-statusline.nix");
console.log("  nix profile upgrade --all --impure");
