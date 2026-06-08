# deno 公式の最新リリースバイナリ (linux/x86_64) を取り込むパッケージ。
# nixpkgs の deno はソースビルド (Rust + V8) でバージョンが遅れがちなため、
# flake input (deno-bin = releases/latest/download) で取得したプリビルド ELF を
# unzip + autoPatchelfHook で導入する。`nix flake update` のたびに最新へ追従する。
{
  lib,
  stdenv,
  autoPatchelfHook,
  unzip,
  src,
}:

stdenv.mkDerivation {
  pname = "deno";

  # 実バージョンは flake.lock が固定する deno-bin の中身に従う (binary 自身が報告する)。
  # 派生としては version 文字列を持たないため "latest" を置く。
  version = "latest";

  inherit src;

  # src は単一の zip ファイル。stdenv の拡張子ベース自動展開に頼らず明示的に解凍する。
  nativeBuildInputs = [
    unzip
    autoPatchelfHook
  ];

  # deno バイナリは glibc 以外は概ね静的リンクだが libgcc_s を要する。
  # autoPatchelfHook が ELF インタプリタと RPATH を nix の glibc・libgcc へ張り替える。
  buildInputs = [ stdenv.cc.cc.lib ];

  unpackPhase = ''
    runHook preUnpack
    unzip $src
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 deno $out/bin/deno
    runHook postInstall
  '';

  meta = {
    description = "A modern runtime for JavaScript and TypeScript";
    homepage = "https://deno.land";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "deno";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
