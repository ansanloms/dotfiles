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
