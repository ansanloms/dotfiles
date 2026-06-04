#!/usr/bin/env -S deno run -A
// playwright-cli を指定バージョン（省略時は npm レジストリの最新）へ更新する。
//
// 処理内容:
//   1. package.json の依存バージョンを反映
//   2. package-lock.json を再生成
//   3. npmDepsHash を取得
//   4. playwright-cli.nix の version / npmDepsHash を反映
//
// git add / deno task switch は行わない。完了後に git diff で確認し、手動で反映すること。
//
// 使い方:
//   deno task bump:playwright-cli            # 最新へ
//   deno task bump:playwright-cli 0.1.14     # 指定バージョンへ

const PKG = "@playwright/cli";
const scriptDir = import.meta.dirname!;
const pkgJsonPath = `${scriptDir}/package.json`;
const lockPath = `${scriptDir}/package-lock.json`;
const nixPath = `${scriptDir}/../playwright-cli.nix`;

/** 外部コマンドを実行し、標準出力（trim 済み）を返す。非ゼロ終了で例外。 */
async function run(
  cmd: string,
  args: string[],
  opts: { cwd?: string } = {},
): Promise<string> {
  const { code, stdout, stderr } = await new Deno.Command(cmd, {
    args,
    cwd: opts.cwd,
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

const version = Deno.args[0] ?? await run("npm", ["view", PKG, "version"]);
console.log(`対象バージョン: ${version}`);

// 1. package.json の依存バージョンを反映
const pkg = JSON.parse(await Deno.readTextFile(pkgJsonPath));
pkg.version = version;
pkg.dependencies[PKG] = version;
await Deno.writeTextFile(pkgJsonPath, JSON.stringify(pkg, null, 2) + "\n");

// 2. lockfile を再生成（nix の npm を使う）
console.log("lockfile を再生成中...");
await run("npm", [
  "install",
  "--prefix",
  scriptDir,
  "--package-lock-only",
  "--omit=dev",
]);

// 3. npmDepsHash を取得
console.log("npmDepsHash を取得中...");
const hash = await run("nix", [
  "run",
  "nixpkgs#prefetch-npm-deps",
  "--",
  lockPath,
]);
console.log(`npmDepsHash: ${hash}`);

// 4. playwright-cli.nix へ反映
let nix = await Deno.readTextFile(nixPath);
nix = replaceNixString(nix, "version", version);
nix = replaceNixString(nix, "npmDepsHash", hash);
await Deno.writeTextFile(nixPath, nix);

console.log("\n更新完了。git diff で確認し、問題なければ反映:");
console.log("  git add .config/nix/playwright-cli.nix .config/nix/playwright-cli/");
console.log("  deno task switch");
