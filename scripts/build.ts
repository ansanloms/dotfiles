#!/usr/bin/env -S deno run --allow-read=scripts --allow-write=.local/bin --allow-run=deno

// scripts/ 配下の各エントリ (build.ts 自身と *_test.ts を除く *.ts) を deno bundle で
// 単一ファイル化し、.local/bin/ 配下に実行可能ファイルとして配置する。
//
// 各エントリの shebang (権限フラグを含む) は deno bundle が出力先の先頭へ
// そのまま引き継ぐため、ビルド側で権限を管理する必要はない。
//
// ロジックは lib/build.ts に分離し、副作用はここで注入する。

import { run } from "./lib/build.ts";

const code = await run({
  readDir: (dir) => Deno.readDir(dir),
  bundle: async (src, out) => {
    const { success, stderr } = await new Deno.Command("deno", {
      args: ["bundle", "--quiet", "--platform", "deno", "-o", out, src],
      stderr: "piped",
    }).output();
    return { success, stderr: new TextDecoder().decode(stderr) };
  },
  chmod: (path, mode) => Deno.chmod(path, mode),
  log: (msg) => console.log(msg),
  errorLog: (msg) => console.error(msg),
});

Deno.exit(code);
