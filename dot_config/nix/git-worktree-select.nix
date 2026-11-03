# git-worktree-select (git worktree を fzf で選び、絶対パスを stdout へ出す shell スクリプト)。
# 本体は同名ディレクトリの git-worktree-select.sh。
# writeShellApplication が runtimeInputs で git / fzf / mdcat を PATH に固定し、ビルド時に shellcheck を通す。
{ writeShellApplication, git, fzf, mdcat }:

writeShellApplication {
  name = "git-worktree-select";
  runtimeInputs = [ git fzf mdcat ];
  text = builtins.readFile ./git-worktree-select/git-worktree-select.sh;
}
