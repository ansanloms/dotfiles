# claude-statusline (Claude Code の statusLine レンダラ)。
# nixpkgs 収録対象外の自前ツール (https://github.com/ansanloms/claude-statusline)。
#
# 配布物は GitHub Release に添付された Bun の standalone 実行ファイル
# (claude-statusline-<target>)。Bun ランタイムとアプリを 1 つのバイナリに埋め込んでおり、
# 実行に deno / bun は不要。system と Release 資産 target の対応は下記 targets を参照
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
# サブコマンド: `claude-statusline main` (メイン statusline)。
#
# リリースタグは version そのもの (v 無し。例: 0.1.0)。
#
# バージョンを上げる場合 (deno task bump:claude-statusline が下記を自動で行う):
#   1. target ごとの資産 (claude-statusline-<target>) を nix store prefetch-file で
#      取得し、system 別に hashes を更新する。
#   2. version 文字列を更新する。
{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.1.0";

  # nix の system -> Release 資産の target。
  targets = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
  };

  # 初回 bump 前のプレースホルダ (bump:claude-statusline が実値へ書き換える)。
  hashes = {
    "x86_64-linux" = "sha256-8vZLfyhPU3ruQ8o7bACu1/BfZEHjmi/4BPmsF3DIRsk=";
    "aarch64-linux" = "sha256-UuwIB0WyZ2iTB0pczPooYDZSrKB5YYCzClsTT3SvXBQ=";
  };

  system = stdenv.hostPlatform.system;
  target = targets.${system} or (throw "claude-statusline: unsupported system ${system}");
in
stdenv.mkDerivation {
  pname = "claude-statusline";
  inherit version;

  src = fetchurl {
    url = "https://github.com/ansanloms/claude-statusline/releases/download/${version}/claude-statusline-${target}";
    hash = hashes.${system};
  };

  # src は単一の実行ファイル。展開処理は不要。
  dontUnpack = true;

  # fixup を全て無効化する。autoPatchelfHook は使わず、既定の strip も止める。
  # どちらもバイナリを書き換え、Bun standalone の末尾 trailer を破壊するため。
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/claude-statusline
    runHook postInstall
  '';

  meta = {
    description = "Claude Code statusline renderer";
    homepage = "https://github.com/ansanloms/claude-statusline";
    license = lib.licenses.mit;
    platforms = lib.attrNames targets;
    mainProgram = "claude-statusline";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
