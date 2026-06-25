# SonarQube CLI (sonar)。
# nixpkgs 未収録 (収録されているのは別物の sonar-scanner-cli)。
#
# 配布物は Bun の standalone 実行ファイル (Bun ランタイムとアプリを 1 つの ELF
# に埋め込んだ単一バイナリ)。Bun は起動時に /proc/self/exe で自分自身を読み、
# ファイル末尾の trailer から埋め込みペイロードの位置を得る。patchelf や strip で
# ELF を書き換えると trailer の位置がずれ、Bun がアプリを見つけられず素の Bun CLI
# にフォールバックする。そのため fixup を一切かけず raw バイナリのまま導入する。
#
# raw のため ELF インタプリタは配布時のままの /lib64/ld-linux-x86-64.so.2 を指す。
# システム側に glibc / ローダがある FHS 環境 (WSL の通常ディストリ等) で動く前提。
# ローダを持たない環境 (純 NixOS 等) では動かない。その場合は buildFHSEnv での
# ラップに切り替える必要がある。
#
# バージョンを上げる場合 (deno task bump:sonarqube-cli が下記を自動で行う):
#   1. https://binaries.sonarsource.com/Distribution/sonarqube-cli/<ver>/linux/sonarqube-cli-<ver>-linux-x86-64.bin
#      を nix store prefetch-file で取得し hash を更新する。
#   2. version 文字列を更新する。
{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "1.1.0.3122";
in
stdenv.mkDerivation {
  pname = "sonarqube-cli";
  inherit version;

  src = fetchurl {
    url = "https://binaries.sonarsource.com/Distribution/sonarqube-cli/${version}/linux/sonarqube-cli-${version}-linux-x86-64.bin";
    hash = "sha256-J3PHH83RVMC9ZQwM/F+LF6J1zWvXv3HONuS1l2EamGQ=";
  };

  # src は単一の ELF バイナリ。展開処理は不要。
  dontUnpack = true;

  # fixup を全て無効化する。autoPatchelfHook は使わず、既定の strip も止める。
  # どちらも ELF を書き換え、Bun standalone の末尾 trailer を破壊するため。
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/sonar
    runHook postInstall
  '';

  meta = {
    description = "SonarQube CLI for developers and AI agents";
    homepage = "https://github.com/SonarSource/sonarqube-cli";
    license = lib.licenses.lgpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "sonar";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
