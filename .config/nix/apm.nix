# microsoft/apm (Agent Package Manager) のプリビルドバイナリパッケージ。
# nixpkgs 未収録のため、公式リリースの PyInstaller onedir バンドルを取得して導入する。
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  openssl,
}:

let
  version = "0.16.0";

  # プラットフォームごとのリリースアセット名とハッシュ。
  # ハッシュは各 .tar.gz.sha256 を SRI 形式へ変換したもの。
  sources = {
    "x86_64-linux" = {
      asset = "apm-linux-x86_64";
      hash = "sha256-K2rOeSVzKKlZmyVp9HUeXjcuIa6tqekLQj1R35XyT00=";
    };
    "aarch64-linux" = {
      asset = "apm-linux-arm64";
      hash = "sha256-swyKSKR7qwQW30fz4BcHX7tEmZch4qdtStog6Z20mZk=";
    };
    "x86_64-darwin" = {
      asset = "apm-darwin-x86_64";
      hash = "sha256-SrsW/pm8aVSuZDBfLaf/LphLo5tQ5kPd0yTkqiPcZ5c=";
    };
    "aarch64-darwin" = {
      asset = "apm-darwin-arm64";
      hash = "sha256-+ZDMoDlmWIB2IuA/I8ToAbH537+cBlA+Cud1FsUUxwE=";
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

  # 同梱 .so が要求するランタイム。openssl は _ssl / _hashlib が必要とするが
  # バンドルに同梱されていないため明示的に補う。
  buildInputs = lib.optionals stdenv.isLinux [
    stdenv.cc.cc.lib
    openssl
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
