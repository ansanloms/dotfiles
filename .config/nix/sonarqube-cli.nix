# SonarQube CLI (sonar)。
# nixpkgs 未収録 (収録されているのは別物の sonar-scanner-cli)。
# SonarSource がプリビルド ELF を配布しているため、fetchurl で取得し
# autoPatchelfHook で ELF インタプリタ・RPATH を nix の glibc へ張り替えて導入する。
#
# バージョンを上げる場合:
#   1. https://binaries.sonarsource.com/Distribution/sonarqube-cli/<ver>/linux/sonarqube-cli-<ver>-linux-x86-64.bin
#      を nix store prefetch-file で取得し hash を更新する。
#   2. version 文字列を更新する。
{
  lib,
  stdenv,
  autoPatchelfHook,
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

  nativeBuildInputs = [ autoPatchelfHook ];

  # 動的リンクされた依存 (libstdc++ / libgcc_s 等) を nix の物へ張り替える。
  buildInputs = [ stdenv.cc.cc.lib ];

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
