# microsoft/apm (Agent Package Manager) のプリビルドバイナリパッケージ。
# nixpkgs 未収録のため、公式リリースの PyInstaller onedir バンドルを取得して導入する。
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  openssl,
  zlib,
  sqlite,
  libffi,
  bzip2,
  libuuid,
  readline,
  xz,
}:

let
  version = "0.19.0";

  # プラットフォームごとのリリースアセット名とハッシュ。
  # ハッシュは各 .tar.gz.sha256 を SRI 形式へ変換したもの。
  sources = {
    "x86_64-linux" = {
      asset = "apm-linux-x86_64";
      hash = "sha256-k8RH2ghX2lX/EucHGlr5dMD4XelxcVXn3AZoK8Gv42I=";
    };
    "aarch64-linux" = {
      asset = "apm-linux-arm64";
      hash = "sha256-GjgfAwpHX4BsONUaM7mvX24ur1HPIP1in3Mi2gyj3Xg=";
    };
    "x86_64-darwin" = {
      asset = "apm-darwin-x86_64";
      hash = "sha256-SFhHBz4gjNJiFZyk6TTjnIW1TQKyfDTto2pq/IAbILM=";
    };
    "aarch64-darwin" = {
      asset = "apm-darwin-arm64";
      hash = "sha256-Br/OxL46/31lbpAaI35ly4NfJEy8DgLgLHgOcvts8pQ=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "apm: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "apm";
  inherit version;

  src = fetchurl {
    url = "https://github.com/microsoft/apm/releases/download/v${version}/${source.asset}.tar.gz";
    inherit (source) hash;
  };

  # autoPatchelfHook は Linux 専用。ELF インタプリタと RPATH を nix の glibc へ張り替える。
  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  # 同梱 PyInstaller バンドルの Python 拡張モジュールが要求する native ライブラリ。
  # バンドルに含まれないため明示的に補う (openssl: _ssl/_hashlib, zlib: zlib/binascii,
  # sqlite: _sqlite3, libffi: _ctypes, bzip2: _bz2, libuuid: _uuid,
  # readline: readline, xz: _lzma)。
  buildInputs = lib.optionals stdenv.isLinux [
    stdenv.cc.cc.lib
    openssl
    zlib
    sqlite
    libffi
    bzip2
    libuuid
    readline
    xz
  ];

  # PyInstaller onedir 形式は apm 本体と _internal/ が同階層にある必要がある。
  # bin/ には symlink を張り、実体は libexec/ に配置する。
  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/apm $out/bin
    cp -r . $out/libexec/apm
    ln -s $out/libexec/apm/apm $out/bin/apm

    runHook postInstall
  '';

  meta = {
    description = "Open-source, community-driven dependency manager for AI agents";
    homepage = "https://github.com/microsoft/apm";
    license = lib.licenses.mit;
    platforms = builtins.attrNames sources;
    mainProgram = "apm";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
