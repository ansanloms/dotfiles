#!/usr/bin/env -S deno run -A
// apm-cli を指定バージョン（省略時は GitHub の最新リリース）へ更新する。
//
// 処理内容:
//   1. 対象バージョンを決定（引数 or GitHub releases の latest tag。先頭の v は除く）
//   2. ソースツリーの hash を nix flake prefetch で取得
//   3. apm-cli.nix の version / hash を反映
//
// git add / nix profile upgrade は行わない。完了後に git diff で確認し、手動で反映すること。
//
// apm-cli.nix の先頭付近に固定マーカー（行の先頭（インデント可）に置く
// `# bump: pinned <version>`）がある場合、バージョンを引数で明示しない実行
// （GitHub Actions の日次 bump を含む）は、マーカーのバージョンと apm-cli.nix の
// version が一致していれば何もせずに終了する。
// マーカー行はバージョンの後ろに注記を置いてよい（先頭トークンだけをバージョンとして読む）。
// 食い違っている（手動で version だけ上げてマーカーの消し忘れ等）場合や、
// マーカー行の書式が壊れてバージョンが取れない場合は、無音でスキップせず
// 非ゼロ終了する（GitHub Actions の日次 bump が失敗して気づける）。この失敗は
// `deno task bump` 全体を非ゼロにするため、日次 bump ではその日の他パッケージの
// 更新もコミットされない。マーカーを直すまで全パッケージの自動更新が止まる
// （意図した強制）。
// 固定を解除するには固定コメントブロック（マーカー行を含む）を消す。
// バージョン明示（`deno task bump:apm-cli <version>`）は固定中でも bump を実行するが、
// 固定の解除にはならない。マーカーは書き換えないので、実行後は固定ブロックを消すか、
// 固定を続けるならマーカーのバージョンと固定理由のコメントを更新すること。放置すると
// 次の引数無し実行（日次 bump）が不一致で非ゼロ終了する。
//
// 使い方:
//   deno task bump:apm-cli          # 最新へ（固定中かつ一致なら何もしない）
//   deno task bump:apm-cli 0.25.0   # 指定バージョンへ（固定中でも実行するが、固定は解除されない）

const REPO = "microsoft/apm";
const scriptDir = import.meta.dirname!;
const nixPath = `${scriptDir}/../apm-cli.nix`;

/** apm-cli.nix を固定するマーカー。行の先頭（インデント可）に置く `# bump: pinned <version>` の形式。 */
const PIN_MARKER_RE = /^\s*# bump: pinned\b(.*)$/m;

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

let nix = await Deno.readTextFile(nixPath);

const pinLine = nix.match(PIN_MARKER_RE);
if (pinLine) {
  // マーカー行の残りは先頭トークンだけをバージョンとして読み、
  // それ以降（注記等）は無視する。
  const pinnedVersion = pinLine[1].trim().split(/\s+/)[0] ?? "";
  const currentVersion = nix.match(/\bversion = "([^"]*)"/)?.[1];

  if (Deno.args[0] === undefined) {
    if (pinnedVersion !== "" && pinnedVersion === currentVersion) {
      console.log(
        `apm-cli.nix が \`# bump: pinned ${pinnedVersion}\` で固定されているため何もしない。` +
          "解除するには固定コメントブロック（マーカー行を含む）を消す。" +
          "バージョン明示で実行すると固定のまま bump できる。",
      );
      Deno.exit(0);
    }
    console.error(
      "apm-cli.nix の固定マーカー（`# bump: pinned " +
        (pinnedVersion || "(バージョン取得不可)") +
        "`）と実際の version（" + (currentVersion ?? "取得不可") +
        "）が食い違っている。固定を解除するなら固定コメントブロック（マーカー行を含む）を消す。" +
        "固定を続けるならマーカーのバージョンと固定理由のコメントを version に合わせて更新する。",
    );
    Deno.exit(1);
  }
  console.log("固定中だがバージョン明示のため続行する。");
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
nix = replaceNixString(nix, "version", version);
nix = replaceNixString(nix, "hash", hash);
await Deno.writeTextFile(nixPath, nix);

console.log("\n更新完了。git diff で確認し、問題なければ反映:");
console.log("  git add .config/nix/apm-cli.nix");
console.log("  nix profile upgrade --all --impure");
