# aws-login-select (AWS profile を fzf で選び、aws login --profile <選択> を実行する shell スクリプト)。
# 本体は同名ディレクトリの aws-login-select.sh。
# writeShellApplication が runtimeInputs で awscli2 / fzf / gawk を PATH に固定し、ビルド時に shellcheck を通す。
{ writeShellApplication, awscli2, fzf, gawk }:

writeShellApplication {
  name = "aws-login-select";
  runtimeInputs = [ awscli2 fzf gawk ];
  text = builtins.readFile ./aws-login-select/aws-login-select.sh;
}
