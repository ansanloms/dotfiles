# @playwright/cli (Playwright CLI) の npm パッケージ。
# nixpkgs 未収録のため、自前の package.json + package-lock.json を src にして
# buildNpmPackage で node_modules を再現する。本体は純 JS (CommonJS) でビルド不要。
#
# ブラウザはバンドルせず、nixpkgs の google-chrome を駆動させる。
# 依存する playwright-core が要求する chromium リビジョンと nixpkgs の
# playwright-driver のリビジョンが一致しないため、宣言的に google-chrome を指定する。
{
  lib,
  buildNpmPackage,
  nodejs,
  makeWrapper,
  google-chrome,
}:

buildNpmPackage {
  pname = "playwright-cli";
  version = "0.1.19";

  src = ./playwright-cli;

  # package-lock.json から得た npm 依存 FOD のハッシュ。
  # lockfile を更新したら nix run nixpkgs#prefetch-npm-deps で再取得すること。
  npmDepsHash = "sha256-uS7/KFrDJAIwim98Q5vK6fSyEk0OILUJMzc0/BWyjEg=";

  # 本体は純 JS でビルドスクリプトを持たない。build phase を無効化する
  # (省略すると npmBuildHook が build script 不在でハードエラーになる)。
  dontNpmBuild = true;

  # 既定の npmInstallHook は root パッケージ自身を pack する前提のため、
  # 依存をラップする本ケースには合わない。install は自前で行う。
  dontNpmInstall = true;

  # 当該バージョンは install script を持たないため実質不要だが、
  # 上流仕様変更でブラウザ DL が復活した場合の保険。
  env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

  nativeBuildInputs = [ makeWrapper ];

  # npmConfigHook が node_modules を $PWD/node_modules へ展開した後、
  # それを $out/lib/$pname/node_modules にコピーし、実バイナリを wrapper で公開する。
  # 自前 installPhase を書く derivation 同士では $out/lib/node_modules への平坦展開が
  # buildEnv で衝突するため、パッケージ名付きディレクトリに分離する（詳細は CLAUDE.md）。
  installPhase = ''
    runHook preInstall

    # パッケージ名を 3 箇所に持つと片方だけ直したときにビルドが通ったまま実行時に
    # module 解決へ失敗するため、$pname (stdenv.mkDerivation が渡す) で連動させる。
    mkdir -p $out/lib/$pname $out/bin
    cp -r node_modules $out/lib/$pname/node_modules
    # npm の管理ファイルで実行時に読まれず、buildEnv の衝突の直接原因だったため出力へ持ち込まない。
    rm -f $out/lib/$pname/node_modules/.package-lock.json

    makeWrapper ${nodejs}/bin/node $out/bin/playwright-cli \
      --add-flags $out/lib/$pname/node_modules/@playwright/cli/playwright-cli.js \
      --set PLAYWRIGHT_MCP_BROWSER chrome \
      --set PLAYWRIGHT_MCP_EXECUTABLE_PATH ${lib.getExe google-chrome} \
      --prefix PATH : ${lib.makeBinPath [ nodejs google-chrome ]}

    runHook postInstall
  '';

  meta = {
    description = "Playwright CLI (browser automation) driven by nixpkgs google-chrome";
    homepage = "https://github.com/microsoft/playwright-cli";
    license = lib.licenses.asl20;
    mainProgram = "playwright-cli";
    platforms = lib.platforms.linux;
  };
}
