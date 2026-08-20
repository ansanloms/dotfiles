# md2html (markdown を自己完結 HTML へ変換する CLI)。
# nixpkgs 収録対象外の自前ツール (https://github.com/ansanloms/md2html)。
#
# 配布物は GitHub Release に添付された deno bundle 済みの単一 JS ファイルで、
# 展開処理は不要 (dontUnpack)。先頭に以下の shebang を持つ:
#   #!/usr/bin/env -S deno run --quiet --allow-read --allow-write --allow-run=deno --allow-env
# `env -S` はシステムの deno を PATH から探す前提の shebang なので、そのまま
# 導入すると nix の外の deno に依存してしまう。stdenv の fixupPhase が
# patchShebangs を実行し、`env -S` 形式の shebang も含めて buildInputs の deno を
# 絶対パスへ書き換えるため、ここでは buildInputs に deno を渡すだけでよい。
# 実行時に mermaid ブロックのバンドル生成で `deno` サブプロセスを PATH から
# 起動するため、wrapProgram で nix の deno を PATH へ前置し、あわせて
# LD_LIBRARY_PATH を外す (Deno の限定付き --allow-run が NotCapable になる
# 既知問題の回避)。
#
# リリースタグは v プレフィックス無し (例: 0.1.0)。
#
# バージョンを上げる場合 (deno task bump:md2html が下記を自動で行う):
#   1. https://github.com/ansanloms/md2html/releases/download/<ver>/md2html
#      を nix store prefetch-file で取得し hash を更新する。
#   2. version 文字列を更新する。
{
  lib,
  stdenv,
  fetchurl,
  deno,
  makeWrapper,
}:

let
  version = "0.1.0";
in
stdenv.mkDerivation {
  pname = "md2html";
  inherit version;

  src = fetchurl {
    url = "https://github.com/ansanloms/md2html/releases/download/${version}/md2html";
    hash = "sha256-m1cVqyAeebPZX5N8W1AvYJ+54L7NVGYZykS+HxefsQg=";
  };

  # src は deno bundle 済みの単一 JS ファイル。展開処理は不要。
  dontUnpack = true;

  # patchShebangs (fixupPhase) が shebang の deno を nix store の絶対パスへ
  # 書き換えるために必要。
  buildInputs = [ deno ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/md2html
    runHook postInstall
  '';

  # 実行時の mermaid バンドル生成が PATH の deno を spawn するため、nix の deno を
  # PATH へ前置する。また LD_LIBRARY_PATH が設定されていると Deno が限定付き
  # --allow-run からの spawn を NotCapable で拒否するため (scripts/build.ts と同じ
  # 既知問題)、wrapper で外す。wrapProgram は fixupPhase の patchShebangs より後に
  # 走るため、退避された実体の shebang は書き換え済みのまま維持される。
  postFixup = ''
    wrapProgram $out/bin/md2html \
      --prefix PATH : ${lib.makeBinPath [ deno ]} \
      --unset LD_LIBRARY_PATH
  '';

  meta = {
    description = "Convert markdown to self-contained HTML with shiki and mermaid";
    homepage = "https://github.com/ansanloms/md2html";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "md2html";
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
  };
}
