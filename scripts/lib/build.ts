// build の純粋ロジックとオーケストレーション。
// 副作用 (ディレクトリ走査 / deno bundle / chmod / 出力) は BuildDeps として注入する。
//
// scripts/ 配下の各エントリ (build.ts 自身と *_test.ts を除く *.ts) を
// deno bundle で単一ファイル化し、.local/bin/ 配下に実行可能ファイルとして配置する。
// サブディレクトリ (lib/) は readDir のファイル判定で自然に除外される。

/** bundle 対象のソースか判定する。build.ts 自身とテストファイルは除く。 */
export function isBuildableSource(name: string): boolean {
  return name.endsWith(".ts") && name !== "build.ts" &&
    !name.endsWith("_test.ts");
}

/** ソースファイル名から出力コマンド名を導く (.ts を除去)。 */
export function outName(name: string): string {
  return name.replace(/\.ts$/, "");
}

export interface BuildEntry {
  name: string;
  isFile: boolean;
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

/** scripts/ の各エントリを bundle して .local/bin/ へ配置する。終了コードを返す。 */
export async function run(
  deps: BuildDeps,
  srcDir = "scripts",
  outDir = ".local/bin",
): Promise<number> {
  for await (const entry of deps.readDir(srcDir)) {
    if (!entry.isFile || !isBuildableSource(entry.name)) {
      continue;
    }

    const src = `${srcDir}/${entry.name}`;
    const out = `${outDir}/${outName(entry.name)}`;

    const result = await deps.bundle(src, out);
    if (!result.success) {
      deps.errorLog(result.stderr);
      return 1;
    }

    await deps.chmod(out, 0o755);
    deps.log(`Built: ${out}`);
  }

  return 0;
}
