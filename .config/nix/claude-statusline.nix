# claude-statusline (Claude Code の statusLine / subagentStatusLine レンダラ)。
# nixpkgs 未収録の自前ツール (https://github.com/ansanloms/claude-statusline)。
#
# 配布物は GitHub Release に添付された deno bundle 済みの単一 JS ファイルで、
# 展開処理は不要 (dontUnpack)。先頭に以下の shebang を持つ:
#   #!/usr/bin/env -S deno run --allow-env --allow-read --allow-run=git
# `env -S` はシステムの deno を PATH から探す前提の shebang なので、そのまま
# 導入すると nix の外の deno に依存してしまう。stdenv の fixupPhase が
# patchShebangs を実行し、`env -S` 形式の shebang も含めて buildInputs の deno を
# 絶対パスへ書き換えるため、ここでは buildInputs に deno を渡すだけでよい。
# ビルド後は `head -1 $out/bin/claude-statusline` で
#   #!/nix/store/...-coreutils-*/bin/env -S /nix/store/...-deno-*/bin/deno run --allow-env --allow-read --allow-run=git
# 形式 (env -S は残り、env と deno の両方が store の絶対パスに書き換わる) に
# なっていることを確認すること。
#
# サブコマンド: `claude-statusline main` (メイン statusline) / `claude-statusline sub` (agent panel)。
#
# バージョンを上げる場合 (deno task bump:claude-statusline が下記を自動で行う):
#   1. https://github.com/ansanloms/claude-statusline/releases/download/v<ver>/claude-statusline
#      を nix store prefetch-file で取得し hash を更新する。
#   2. version 文字列を更新する。
{
  lib,
  stdenv,
  fetchurl,
  deno,
}:

let
  version = "0.0.1";
in
stdenv.mkDerivation {
  pname = "claude-statusline";
  inherit version;

  src = fetchurl {
    url = "https://github.com/ansanloms/claude-statusline/releases/download/v${version}/claude-statusline";
    hash = "sha256-3XCgM6fXdyFNexH73PrEiXgWqlTKDr97OWk5+hfOI5E=";
  };

  # src は deno bundle 済みの単一 JS ファイル。展開処理は不要。
  dontUnpack = true;

  # patchShebangs (fixupPhase) が shebang の deno を nix store の絶対パスへ
  # 書き換えるために必要。
  buildInputs = [ deno ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/claude-statusline
    runHook postInstall
  '';

  meta = {
    description = "Claude Code statusline renderer";
    homepage = "https://github.com/ansanloms/claude-statusline";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "claude-statusline";
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
  };
}
