#!/usr/bin/env -S deno run --allow-read=scripts --allow-write=.local/bin --allow-run=deno

// scripts/ 配下の各エントリ (このファイル自身を除く *.ts) を deno bundle で
// 単一ファイル化し、.local/bin/ 配下に実行可能ファイルとして配置する。
//
// 各エントリの shebang（権限フラグを含む）は deno bundle が出力先の先頭へ
// そのまま引き継ぐため、ビルド側で権限を管理する必要はない。

const srcDir = "scripts";
const outDir = ".local/bin";

for await (const entry of Deno.readDir(srcDir)) {
  if (!entry.isFile || !entry.name.endsWith(".ts")) {
    continue;
  }
  if (entry.name === "build.ts") {
    continue;
  }

  const src = `${srcDir}/${entry.name}`;
  const out = `${outDir}/${entry.name.replace(/\.ts$/, "")}`;

  const command = new Deno.Command("deno", {
    args: ["bundle", "--quiet", "--platform", "deno", "-o", out, src],
    stderr: "piped",
  });
  const { success, stderr } = await command.output();

  if (!success) {
    console.error(new TextDecoder().decode(stderr));
    Deno.exit(1);
  }

  await Deno.chmod(out, 0o755);
  console.log(`Built: ${out}`);
}
