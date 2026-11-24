# SonarQube CLI (sonar)。
# nixpkgs 未収録 (収録されているのは別物の sonar-scanner-cli)。
#
# 配布物は Bun の standalone 実行ファイル (Bun ランタイムとアプリを 1 つの ELF
# に埋め込んだ単一バイナリ)。Bun は起動時に /proc/self/exe で自分自身を読み、
# ファイル末尾の trailer から埋め込みペイロードの位置を得る。patchelf や strip で
# ELF を書き換えると trailer の位置がずれ、Bun がアプリを見つけられず素の Bun CLI
# にフォールバックする。そのため fixup を一切かけず raw バイナリのまま導入する。
#
# raw のため ELF インタプリタは配布時のままのパスを指す (x86_64 は
# /lib64/ld-linux-x86-64.so.2、aarch64 は /lib/ld-linux-aarch64.so.1)。
# システム側に glibc / ローダがある FHS 環境 (WSL の通常ディストリ等) で動く前提。
# ローダを持たない環境 (純 NixOS 等) では動かない。その場合は buildFHSEnv での
# ラップに切り替える必要がある。
#
# バージョンを上げる場合 (dot_config/nix/sonarqube-cli/upgrade.sh が下記を自動で行う):
#   1. https://binaries.sonarsource.com/Distribution/sonarqube-cli/<ver>/linux/sonarqube-cli-<ver>-<target>.bin
#      を target ごとに nix store prefetch-file で取得し、system 別に hashes を更新する。
#   2. version 文字列を更新する。
{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "1.13.1.18209";

  # nix の system -> 配布物の target。
  targets = {
    "x86_64-linux" = "linux-x86-64";
    "aarch64-linux" = "linux-arm64";
  };

  # system 別の hash (dot_config/nix/sonarqube-cli/upgrade.sh が書き換える)。
  hashes = {
    "x86_64-linux" = "sha256-suP6z2A4UUyEb3w8+it88KB2HIsFL8W3b+QkzfvJybc=";
    "aarch64-linux" = "sha256-zgGMjdps7xY0FqrXQtgZLFh8c6Ub1AvpRB9IeA8k80M=";
  };

  system = stdenv.hostPlatform.system;
  target = targets.${system} or (throw "sonarqube-cli: unsupported system ${system}");
in
stdenv.mkDerivation {
  pname = "sonarqube-cli";
  inherit version;

  src = fetchurl {
    url = "https://binaries.sonarsource.com/Distribution/sonarqube-cli/${version}/linux/sonarqube-cli-${version}-${target}.bin";
    hash = hashes.${system};
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
    platforms = lib.attrNames targets;
    mainProgram = "sonar";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
