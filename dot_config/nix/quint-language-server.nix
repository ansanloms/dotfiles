# @informalsystems/quint-language-server (Quint の言語サーバ) の npm パッケージ。
# nixpkgs 未収録。上流は npm でのみ配布するため、
# 自前の package.json + package-lock.json を src にして buildNpmPackage で node_modules を再現する。
# 本体はビルド済みの純 JS (out/src/server.js) でビルド不要。
{
  lib,
  buildNpmPackage,
  nodejs,
  makeWrapper,
}:

buildNpmPackage {
  pname = "quint-language-server";
  version = "0.21.0";

  src = ./quint-language-server;

  # package-lock.json から得た npm 依存 FOD のハッシュ。
  # lockfile が変わったときは `quint-language-server/upgrade.sh <現在の version>` で
  # npmDepsHash を再取得する (引数を省くと最新版へ上がる)。
  npmDepsHash = "sha256-o65VPhBsWjVZTBGgWOEHZzukh2kKrcN6TObxfIZMloA=";

  # ビルド済みの純 JS でビルドスクリプトを持たない。build phase を無効化する
  # (省略すると npmBuildHook が build script 不在でハードエラーになる)。
  dontNpmBuild = true;

  # 既定の npmInstallHook は root パッケージ自身を pack する前提のため、
  # 依存をラップする本ケースには合わない。install は自前で行う。
  dontNpmInstall = true;

  nativeBuildInputs = [ makeWrapper ];

  # npmConfigHook が node_modules を $PWD/node_modules へ展開した後、
  # それを $out/lib/$pname/node_modules にコピーし、実バイナリを wrapper で公開する。
  # 自前 installPhase を書く derivation 同士では $out/lib/node_modules への平坦展開が
  # buildEnv で衝突するため、パッケージ名付きディレクトリに分離する。
  installPhase = ''
    runHook preInstall

    # $pname (stdenv.mkDerivation が渡す) で連動させ、名前の片方だけ直してビルドが通ったまま
    # 実行時に module 解決へ失敗する事態を避ける。
    mkdir -p $out/lib/$pname $out/bin
    cp -r node_modules $out/lib/$pname/node_modules
    # npm の管理ファイルで実行時に読まれず、buildEnv の衝突の原因になるため出力へ持ち込まない。
    rm -f $out/lib/$pname/node_modules/.package-lock.json

    makeWrapper ${nodejs}/bin/node $out/bin/quint-language-server \
      --add-flags $out/lib/$pname/node_modules/@informalsystems/quint-language-server/out/src/server.js \
      --prefix PATH : ${lib.makeBinPath [ nodejs ]}

    runHook postInstall
  '';

  meta = {
    description = "Language server for Quint";
    homepage = "https://github.com/informalsystems/quint";
    license = lib.licenses.asl20;
    mainProgram = "quint-language-server";
    platforms = lib.platforms.unix;
  };
}
