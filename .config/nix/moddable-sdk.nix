# Moddable SDK CLI tools (mcconfig / mcrun / mcpack ...).
# nixpkgs 未収録。
#
# scope: Linux 専用かつ CLI ツールのみ。GTK ベースの GUI (xsbug デバッガ / mcsim
# シミュレータ) はビルドしない。アプリのターゲットは x-cli-lin を想定する。
#
# 設計上の要点:
#   1. Moddable のツール群 (mcconfig 等) は単一マルチコールバイナリ `tools` への
#      bash ラッパで、実行時に環境変数 MODDABLE が SDK のソースツリーを指している
#      必要がある。mcconfig は manifest から Makefile を生成して make を呼ぶため、
#      バイナリ単体では動かない。そのため SDK ツリー一式を $out/share/moddable へ
#      展開し、各 CLI ツールを MODDABLE 付きでラップする。
#   2. SDK ツリーは読み取り専用 (nix store) に置かれる。mcconfig はアプリビルド成果物
#      を既定で $MODDABLE/build 配下へ書こうとする (read-only で失敗する) ため、
#      アプリをビルドする際は `mcconfig -o <書き込み可能なディレクトリ>` で出力先を
#      明示する必要がある (-o は mcmanifest.js が解釈する公式フラグ)。
#   3. release ターゲットは末尾で xsbug / mcsim (GUI) も mcconfig でビルドするので、
#      その 2 行は実行せず、sub-makefile (xsc/xsid/xsl/serial2xsbug/tools) だけを
#      直接叩く。
#
# バージョンを上げる場合 (deno task bump:moddable-sdk が下記を自動で行う):
#   1. public ブランチの HEAD コミットを解決し rev を更新する。
#   2. そのコミットの tools/VERSION を version 文字列に反映する。
#   3. fetchFromGitHub の hash を nix store prefetch (fetchTree) で取得する。
{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  pkg-config,
  glib,
  dash,
  which,
}:

let
  version = "8.2.3";
  rev = "48ee02d8cfe0dccb51ee2465cf6716b3468684a4";

  # ラップする CLI ツール。実体が存在するものだけ $out/bin に出す (install で存在チェック)。
  cliTools = [
    "mcconfig"
    "mcrun"
    "mcpack"
    "mclocal"
    "mcrez"
    "mcbundle"
    "mchex"
    "mcdevicetree"
    "png2bmp"
    "image2cs"
    "buildclut"
    "cdv"
    "colorcellencode"
    "compressbmf"
    "nodered2mcu"
    "rle4encode"
    "wav2maud"
    "bles2gatt"
    "xsc"
    "xsl"
    "xsid"
    "serial2xsbug"
  ];

  # mcconfig が実行時にアプリをビルドする際に必要なツール群を PATH へ前置する。
  # cc / make は stdenv.cc / stdenv が提供。x-cli-lin は pkg-config + gio-2.0 (glib) も要る。
  runtimeInputs = [
    stdenv.cc
    dash
    which
    pkg-config
    glib
  ];

  # 実行時 pkg-config が gio-2.0 を解決できるよう PKG_CONFIG_PATH を構成する。
  pkgConfigPath = lib.makeSearchPathOutput "dev" "lib/pkgconfig" [ glib ];
in
stdenv.mkDerivation {
  pname = "moddable-sdk";
  inherit version;

  src = fetchFromGitHub {
    owner = "Moddable-OpenSource";
    repo = "moddable";
    inherit rev;
    hash = "sha256-eKz2q+0wt/Rqx/wVNrr0PlZFgX3IxUh3X9UhNBp0h+8=";
  };

  nativeBuildInputs = [
    makeWrapper
    which
    # tools.mk が `SHELL = dash` を指定するため、ビルド時 PATH に dash が要る。
    dash
    pkg-config
  ];

  buildInputs = [ glib ];

  buildPhase = ''
    runHook preBuild

    export MODDABLE="$(pwd)"
    # 上流 top makefile (build/makefiles/lin/makefile) は sub-makefile 呼び出し前に
    # この 2 つを export する。sub-makefile を直接叩くとき、これを再現しないと xsc.mk 等の
    # 相対パス default が cwd 基準でずれ、ヘッダのパスが解決できずビルドが落ちる。
    export XS_DIR="$MODDABLE/xs"
    export BUILD_DIR="$MODDABLE/build"
    cd build/makefiles/lin

    # GUI (xsbug / mcsim) を除いた sub-makefile のみをビルドする。
    # 上流 release ターゲットの先頭 5 行と同じ。末尾 2 行 (GUI) は実行しない。
    make GOAL=release -f "$MODDABLE/xs/makefiles/lin/xsc.mk"
    make GOAL=release -f "$MODDABLE/xs/makefiles/lin/xsid.mk"
    make GOAL=release -f "$MODDABLE/xs/makefiles/lin/xsl.mk"
    make GOAL=release -f serial2xsbug.mk
    make GOAL=release -f tools.mk

    runHook postBuild
  '';

  # mcconfig は実行時に SDK ツリー全体 (xs/ modules/ tools/ build/ のフラグメント) を
  # 参照する。バイナリだけでは動かないのでツリーを丸ごと配置する。
  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/moddable"
    cp -a "$MODDABLE/." "$out/share/moddable/"

    mkdir -p "$out/bin"
    binDir="$out/share/moddable/build/bin/lin/release"
    for t in ${lib.concatStringsSep " " cliTools}; do
      [ -e "$binDir/$t" ] || continue
      makeWrapper "$binDir/$t" "$out/bin/$t" \
        --set MODDABLE "$out/share/moddable" \
        --prefix PATH : "$binDir" \
        --prefix PATH : "${lib.makeBinPath runtimeInputs}" \
        --prefix PKG_CONFIG_PATH : "${pkgConfigPath}"
    done

    runHook postInstall
  '';

  meta = {
    description = "Moddable SDK command-line tools (mcconfig/mcrun/mcpack), Linux, GUI excluded";
    homepage = "https://github.com/Moddable-OpenSource/moddable";
    license = lib.licenses.gpl3Plus;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "mcconfig";
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
