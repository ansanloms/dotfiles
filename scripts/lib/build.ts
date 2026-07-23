// build の純粋ロジックとオーケストレーション。
// 副作用 (ディレクトリ走査 / deno bundle / chmod / 出力) は BuildDeps として注入する。
//
// scripts/ 配下の各 workspace member ディレクトリ (lib/ を除く) を走査し、
// その直下の各エントリ (*.test.ts を除く *.ts) を deno bundle で単一ファイル化し、
// .local/bin/ 配下に実行可能ファイルとして配置する。member 内の lib/ サブディレクトリ
// は走査対象に含めない。

/**
 * bundle 対象のソースか判定する。テストファイルは除く。
 * build.ts の除外は防御的な残置 (scripts/ 直下の build.ts は member ディレクトリ外の
 * ため走査に乗らず、現行の呼び出し経路ではこの条件に到達しない)。
 */
export function isBuildableSource(name: string): boolean {
  return name.endsWith(".ts") && name !== "build.ts" &&
    !name.endsWith(".test.ts");
}

/** ソースファイル名から出力コマンド名を導く (.ts を除去)。 */
export function outName(name: string): string {
  return name.replace(/\.ts$/, "");
}

export interface BuildEntry {
  name: string;
  isFile: boolean;
  isDirectory: boolean;
}

export interface BundleResult {
  success: boolean;
  stderr: string;
}

export interface BuildDeps {
  readDir(dir: string): AsyncIterable<BuildEntry>;
  bundle(src: string, out: string): Promise<BundleResult>;
  chmod(path: string, mode: number): Promise<void>;
  log(msg: string): void;
  errorLog(msg: string): void;
}

/** scripts/ 直下の各 member ディレクトリ (lib を除く) を bundle して .local/bin/ へ配置する。終了コードを返す。 */
export async function run(
  deps: BuildDeps,
  srcDir = "scripts",
  outDir = ".local/bin",
): Promise<number> {
  for await (const memberEntry of deps.readDir(srcDir)) {
    if (!memberEntry.isDirectory || memberEntry.name === "lib") {
      continue;
    }

    const memberDir = `${srcDir}/${memberEntry.name}`;

    for await (const entry of deps.readDir(memberDir)) {
      if (!entry.isFile || !isBuildableSource(entry.name)) {
        continue;
      }

      const src = `${memberDir}/${entry.name}`;
      const out = `${outDir}/${outName(entry.name)}`;

      const result = await deps.bundle(src, out);
      if (!result.success) {
        deps.errorLog(result.stderr);
        return 1;
      }

      await deps.chmod(out, 0o755);
      deps.log(`Built: ${out}`);
    }
  }

  return 0;
}
