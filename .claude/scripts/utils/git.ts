import * as path from "jsr:@std/path@1.1.3";

/**
 * 指定ファイル/ディレクトリのパスを基点に git コマンドを実行する。
 * ディレクトリでない場合は親ディレクトリを基点にする。
 */
const git = async (filepath: string, args: string[]) => {
  const command = new Deno.Command("git", {
    args: [
      "-C",
      (await Deno.stat(filepath)).isDirectory
        ? filepath
        : path.dirname(filepath),
      ...args,
    ],
  });
  return await command.output();
};

/**
 * 指定ファイル/ディレクトリが属する git リポジトリのルートパスを返す。
 * git 管理下でない場合はエラーを投げる。
 */
export const root = async (filepath: string): Promise<string> => {
  const { code, stdout, stderr } = await git(filepath, [
    "rev-parse",
    "--show-toplevel",
  ]);
  if (code !== 0) {
    throw new Error(new TextDecoder().decode(stderr));
  }
  return new TextDecoder().decode(stdout).trim();
};

/**
 * 指定ファイル/ディレクトリが git 管理下にあるかどうかを返す。
 */
export const managed = async (filepath: string): Promise<boolean> => {
  const { code } = await git(filepath, ["rev-parse"]);
  return code === 0;
};

/**
 * 指定ファイル/ディレクトリが属する git リポジトリの共通 git ディレクトリ
 * （common dir）の絶対パスを返す。linked worktree から呼んでもメイン worktree
 * の .git を指す。git 管理下でない場合はエラーを投げる。
 */
export const commonDir = async (filepath: string): Promise<string> => {
  const { code, stdout, stderr } = await git(filepath, [
    "rev-parse",
    "--git-common-dir",
  ]);
  if (code !== 0) {
    throw new Error(new TextDecoder().decode(stderr));
  }

  const raw = new TextDecoder().decode(stdout).trim();
  // 出力が相対パス（例: ".git"）で返るケースに備え、git 実行基点で絶対化する。
  const base = (await Deno.stat(filepath)).isDirectory
    ? filepath
    : path.dirname(filepath);
  return path.resolve(base, raw);
};

/**
 * 指定ファイル/ディレクトリが属する git リポジトリのメイン worktree の
 * ルートパスを返す。linked worktree から呼んでもメイン worktree を指す。
 */
export const mainRoot = async (filepath: string): Promise<string> => {
  return path.dirname(await commonDir(filepath));
};

/**
 * 指定ファイル/ディレクトリが linked worktree 内にあるなら、その worktree の
 * ルートパスを返す。メイン worktree 内・git 管理外・パスが存在しない場合は
 * null を返す。toplevel と common-dir を 1 回の rev-parse でまとめて取得する。
 */
export const linkedWorktreeRoot = async (
  filepath: string,
): Promise<string | null> => {
  let output: Deno.CommandOutput;
  try {
    output = await git(filepath, [
      "rev-parse",
      "--show-toplevel",
      "--git-common-dir",
    ]);
  } catch {
    // filepath が存在しない等で git の実行基点を解決できない場合。
    return null;
  }
  if (output.code !== 0) {
    return null;
  }

  // rev-parse はオプション順に値を出力する。1 行目が toplevel、2 行目が
  // common-dir。common-dir は相対（メイン worktree では ".git"）で返ることが
  // あるため、git の実行基点で絶対化する。
  const lines = new TextDecoder().decode(output.stdout).trim().split("\n");
  if (lines.length < 2) {
    return null;
  }
  const toplevel = lines[0].trim();

  const base = (await Deno.stat(filepath)).isDirectory
    ? filepath
    : path.dirname(filepath);
  const mainRootPath = path.dirname(path.resolve(base, lines[1].trim()));

  return toplevel !== mainRootPath ? toplevel : null;
};

/**
 * 指定ファイル/ディレクトリが属する worktree の現在のブランチ名を返す。
 * detached HEAD 等でブランチ名が無い場合は空文字を返す。
 */
export const branch = async (filepath: string): Promise<string> => {
  const { code, stdout } = await git(filepath, ["branch", "--show-current"]);
  if (code !== 0) {
    return "";
  }
  return new TextDecoder().decode(stdout).trim();
};
