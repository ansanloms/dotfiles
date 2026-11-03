// build の純粋ロジックとオーケストレーション。
// 副作用 (ディレクトリ走査 / 削除 / deno bundle / chmod / 出力) は BuildDeps として注入する。
//
// scripts/ 配下の各 workspace member ディレクトリ (lib/ を除く) を走査し、
// その直下の各エントリ (*.test.ts を除く *.ts) を deno bundle で単一ファイル化し、
// dot_local/bin/ 配下に executable_<name> として配置する (chezmoi が ~/.local/bin/<name> へ実行権限付きでコピーする)。member 内の lib/ サブディレクトリ
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
  remove(path: string): Promise<void>;
  chmod(path: string, mode: number): Promise<void>;
  log(msg: string): void;
  errorLog(msg: string): void;
}

/** scripts/ 直下の各 member ディレクトリ (lib を除く) を bundle して dot_local/bin/ へ executable_<name> として配置する。終了コードを返す。 */
export async function run(
  deps: BuildDeps,
  srcDir = "scripts",
  outDir = "dot_local/bin",
): Promise<number> {
  const generated = new Set<string>();

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
      const out = `${outDir}/executable_${outName(entry.name)}`;

      const result = await deps.bundle(src, out);
      if (!result.success) {
        deps.errorLog(result.stderr);
        return 1;
      }

      await deps.chmod(out, 0o755);
      generated.add(`executable_${outName(entry.name)}`);
      deps.log(`Built: ${out}`);
    }
  }

  // 全て成功した後に、今回生成しなかった executable_ (改名・削除したエントリの古い生成物) だけ掃除する。
  // 出力先が無ければ何もしない。.gitkeep など executable_ 以外には触れない。
  const stale: string[] = [];
  try {
    for await (const entry of deps.readDir(outDir)) {
      if (
        entry.isFile && entry.name.startsWith("executable_") &&
        !generated.has(entry.name)
      ) {
        stale.push(entry.name);
      }
    }
  } catch (e) {
    if (!(e instanceof Deno.errors.NotFound)) {
      throw e;
    }
  }
  for (const name of stale) {
    try {
      await deps.remove(`${outDir}/${name}`);
    } catch (e) {
      if (!(e instanceof Deno.errors.NotFound)) {
        throw e;
      }
    }
  }

  return 0;
}
