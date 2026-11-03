#!/usr/bin/env -S deno run --allow-read=scripts,dot_local/bin --allow-write=dot_local/bin --allow-run=deno --allow-env=LD_LIBRARY_PATH

// scripts/ 配下の各 workspace member ディレクトリ (lib/ を除く) 直下の各エントリ
// (*.test.ts を除く *.ts) を deno bundle で単一ファイル化し、dot_local/bin/ 配下に
// executable_<name> として配置する (chezmoi が ~/.local/bin/<name> へ実行権限付きでコピーする)。
//
// 各エントリの shebang (権限フラグを含む) は deno bundle が出力先の先頭へ
// そのまま引き継ぐため、ビルド側で権限を管理する必要はない。
//
// ロジックは lib/build.ts に分離し、副作用はここで注入する。

import { run } from "./lib/build.ts";

// LD_LIBRARY_PATH が設定された状態で --allow-run=deno のような限定付き allow-run から
// subprocess を spawn すると Deno が NotCapable で拒否する (sandbox 環境で発生)。
// 子プロセスに引き継ぐ前に除去する。
Deno.env.delete("LD_LIBRARY_PATH");

const code = await run({
  readDir: (dir) => Deno.readDir(dir),
  remove: (path) => Deno.remove(path),
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
