# md2html (markdown を自己完結 HTML へ変換する CLI)。
# nixpkgs 収録対象外の自前ツール (https://github.com/ansanloms/md2html)。
#
# 配布物は GitHub Release に添付された Bun の standalone 実行ファイル
# (md2html-bun-<target>)。Bun ランタイムとアプリを 1 つのバイナリに埋め込んでおり、
# 実行に deno は不要。system と Release 資産 target の対応は下記 targets を参照
# (x86_64 / aarch64 の linux のみ)。darwin は未検証。dontFixup で ad-hoc 署名も
# 止まるため、署名の扱いを確認してから足す。
#
# Bun は起動時に /proc/self/exe で自分自身を読み、ファイル末尾の trailer から
# 埋め込みペイロードの位置を得る。patchelf や strip で書き換えると trailer の
# 位置がずれ、Bun がアプリを見つけられず素の Bun CLI にフォールバックする。
# そのため fixup を一切かけず raw バイナリのまま導入する (sonarqube-cli.nix と同じ)。
#
# raw のため ELF インタプリタは配布時のままのパスを指す。システム側に glibc /
# ローダがある FHS 環境 (WSL の通常ディストリ等) で動く前提で、ローダを持たない
# 環境 (純 NixOS 等) では動かない。
#
# mermaid ブロックは初回利用時に jsdelivr から mermaid.min.js を取得し、
# $XDG_CACHE_HOME/md2html/ にキャッシュする。初回のみネットワークを使う。
#
# リリースタグは v プレフィックス無し (例: 0.2.1)。
#
# バージョンを上げる場合 (deno task bump:md2html が下記を自動で行う):
#   1. Release の SHA256SUMS から target ごとの sha256 を取得し、system 別に
#      SRI 形式へ変換して hashes を更新する。
#   2. version 文字列を更新する。
{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.2.1";

  # nix の system -> Release 資産の target。
  targets = {
    "x86_64-linux" = "bun-linux-x64";
    "aarch64-linux" = "bun-linux-arm64";
  };

  hashes = {
    "x86_64-linux" = "sha256-01VUxtfV+PEJiGYIEhh0MSHnYoXUiGUzF0XXI+OQLc4=";
    "aarch64-linux" = "sha256-ndQ/2zavA4HfUCHYtSTB+Aqt9ZRJDNG42XKZbZTVICY=";
  };

  system = stdenv.hostPlatform.system;
  target = targets.${system} or (throw "md2html: unsupported system ${system}");
in
stdenv.mkDerivation {
  pname = "md2html";
  inherit version;

  src = fetchurl {
    url = "https://github.com/ansanloms/md2html/releases/download/${version}/md2html-${target}";
    hash = hashes.${system};
  };

  # src は単一の実行ファイル。展開処理は不要。
  dontUnpack = true;

  # fixup を全て無効化する。autoPatchelfHook は使わず、既定の strip も止める。
  # どちらもバイナリを書き換え、Bun standalone の末尾 trailer を破壊するため。
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/md2html
    runHook postInstall
  '';

  meta = {
    description = "Convert markdown to self-contained HTML with shiki and mermaid";
    homepage = "https://github.com/ansanloms/md2html";
    license = lib.licenses.mit;
    platforms = lib.attrNames targets;
    mainProgram = "md2html";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
