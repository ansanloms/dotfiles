# Moddable SDK tools (mcconfig / mcrun / mcpack ... + mcsim / xsbug).
# nixpkgs 未収録。
#
# scope: Linux 専用。CLI ツールに加え、GTK ベースの GUI (mcsim シミュレータ /
# xsbug デバッガ) もビルドする (x-lin ターゲット)。GUI の実行には X/Wayland 表示
# (WSL の場合 WSLg) が要る。
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
  wrapGAppsHook3,
  pkg-config,
  glib,
  gtk3,
  freetype,
  dash,
  which,
  typescript,
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

  # GTK ベースの GUI ツール。mcconfig -p x-lin でビルドされ、実行に GTK ランタイムと
  # 表示環境が要るため CLI とは別に wrapGAppsHook3 で包装する。
  guiTools = [
    "mcsim"
    "xsbug"
  ];

  # mcconfig が実行時にアプリをビルドする際に必要なツール群を PATH へ前置する。
  # cc / make は stdenv.cc / stdenv が提供。x-cli-lin は pkg-config + gio-2.0 (glib) も要る。
  # TypeScript モジュール (.ts) を含むアプリは mcconfig が `tsc` を呼ぶため typescript も要る。
  runtimeInputs = [
    stdenv.cc
    dash
    which
    pkg-config
    glib
    typescript
  ];

  # 実行時 pkg-config が gio-2.0 / gtk+-3.0 / freetype2 を解決できるよう
  # PKG_CONFIG_PATH を構成する (x-lin / x-cli-lin アプリのビルドに必要)。
  pkgConfigPath = lib.makeSearchPathOutput "dev" "lib/pkgconfig" [
    glib
    gtk3
    freetype
  ];
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
    # GUI ツール (mcsim/xsbug) を GTK ランタイム環境付きで包装する。
    wrapGAppsHook3
    which
    # tools.mk が `SHELL = dash` を指定するため、ビルド時 PATH に dash が要る。
    dash
    pkg-config
  ];

  buildInputs = [
    glib
    gtk3
    freetype
  ];

  # GUI ツールは preFixup で makeWrapper + gappsWrapperArgs で手動包装するため、
  # wrapGAppsHook3 の自動包装 (CLI まで巻き込む) は無効化する。
  dontWrapGApps = true;

  # Moddable は ESP-IDF のバージョンを `git describe` で取得する (公式は git clone 前提)。
  # nix 提供の ESP-IDF では tag が解決できず `git describe --always` が commit hash を
  # 返してしまい、バージョンチェック (versionCheck.py) が失敗する。ESP-IDF は root の
  # version.txt に正規バージョン (例 v6.0.0) を持つので、これを優先して読む (git は fallback)。
  postPatch = ''
    substituteInPlace tools/mcconfig/make.esp32.mk \
      --replace-fail 'cd $(IDF_PATH) && git describe --always --abbrev=0")' \
                     'cat $(IDF_PATH)/version.txt 2>/dev/null || (cd $(IDF_PATH) && git describe --always --abbrev=0)")'

    # mcmanifest.js は .ts コンパイル時の TypeScript lib/target に es2025 を
    # ハードコードするが、安定版 TypeScript (5.9) は es2025 を未サポート
    # (es2024 が最新)。Moddable は将来の TS 6.0 を見込んでいる。現状の tsc で
    # ビルドできるよう es2024 へ下げる。
    substituteInPlace tools/mcmanifest.js \
      --replace-fail 'lib: ["es2025"]' 'lib: ["es2024"]' \
      --replace-fail 'target: "es2025"' 'target: "es2024"'
  '';

  buildPhase = ''
    runHook preBuild

    export MODDABLE="$(pwd)"
    # 上流 top makefile (build/makefiles/lin/makefile) は sub-makefile 呼び出し前に
    # この 2 つを export する。sub-makefile を直接叩くとき、これを再現しないと xsc.mk 等の
    # 相対パス default が cwd 基準でずれ、ヘッダのパスが解決できずビルドが落ちる。
    export XS_DIR="$MODDABLE/xs"
    export BUILD_DIR="$MODDABLE/build"
    cd build/makefiles/lin

    # 上流 release ターゲットと同じ手順。まず CLI sub-makefile を直接叩き、
    # 続けて GUI (xsbug / mcsim) を mcconfig -p x-lin でビルドする。
    make GOAL=release -f "$MODDABLE/xs/makefiles/lin/xsc.mk"
    make GOAL=release -f "$MODDABLE/xs/makefiles/lin/xsid.mk"
    make GOAL=release -f "$MODDABLE/xs/makefiles/lin/xsl.mk"
    make GOAL=release -f serial2xsbug.mk
    make GOAL=release -f tools.mk

    # 続く GUI ビルドでは mcconfig (bash ラッパ) を実行するが、ビルド成果物の shebang が
    # `#!/usr/bin/env ...` を指しており nix のビルドサンドボックスには /usr/bin/env が
    # 存在しないため "bad interpreter" で落ちる。nix の bash 等へ書き換える。
    patchShebangs "$MODDABLE/build/bin/lin/release"

    # GUI ビルドで mcconfig が生成する makefile は xsc / xsl / mcrez 等の CLI ツールを
    # PATH 上に探す。ビルド済みツールのディレクトリを前置する。
    export PATH="$MODDABLE/build/bin/lin/release:$PATH"

    # nix stdenv は cross-compile 用に STRINGS=strings 等のツール名を環境変数へ
    # 自動 export する。Moddable の GUI makefile は $(STRINGS) を「未定義=空」前提で
    # 書いているため、値が入っていると `strings` を make のターゲットと誤認し
    # "No rule to make target 'strings'" で落ちる。GUI ビルド中は unset する。
    unset STRINGS

    # GUI ツール (GTK)。pkg-config は buildInputs の gtk3/freetype/glib を解決する。
    "$MODDABLE/build/bin/lin/release/mcconfig" -m -p x-lin "$MODDABLE/tools/xsbug/manifest.json"
    "$MODDABLE/build/bin/lin/release/mcconfig" -m -p x-lin "$MODDABLE/tools/mcsim/manifest.json"

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

  # GUI ツール (mcsim / xsbug) を MODDABLE + GTK ランタイム環境付きで包装する。
  # gappsWrapperArgs は wrapGAppsHook3 が preFixup までに用意する。
  preFixup = ''
    binDir="$out/share/moddable/build/bin/lin/release"
    for t in ${lib.concatStringsSep " " guiTools}; do
      [ -e "$binDir/$t" ] || continue
      makeWrapper "$binDir/$t" "$out/bin/$t" \
        --set MODDABLE "$out/share/moddable" \
        --prefix PATH : "$binDir" \
        --prefix PATH : "${lib.makeBinPath runtimeInputs}" \
        --prefix PKG_CONFIG_PATH : "${pkgConfigPath}" \
        "''${gappsWrapperArgs[@]}"
    done
  '';

  meta = {
    description = "Moddable SDK tools (mcconfig/mcrun/mcpack + mcsim/xsbug GUI), Linux";
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
