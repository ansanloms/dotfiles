# @nulab/bee (Backlog CLI) の npm パッケージ。
# nixpkgs 未収録。nixpkgs の `bee` は別物 (ethersphere/bee = Ethereum Swarm ノード) のため、
# それを overlay で潰さないよう attribute 名を `backlog-bee-cli` にしている。コマンド名は upstream どおり `bee`。
# nixpkgs の `bee` も `$out/bin/bee` を作るため、packages.nix へ両方入れると buildEnv が file collision で失敗する。
#
# 上流は npm でのみ配布し GitHub Release にバイナリを添付しないため、
# fetchurl でのプリビルド取得は使えず npm 経由が唯一の導入経路。
# 自前の package.json + package-lock.json を src にして buildNpmPackage で node_modules を再現する。
# 本体は unbuild でビルド済みの純 JS (ESM) でビルド不要。
{
  lib,
  buildNpmPackage,
  nodejs,
  makeWrapper,
  git,
}:

buildNpmPackage {
  pname = "backlog-bee-cli";
  version = "1.1.1";

  src = ./backlog-bee-cli;

  # package-lock.json から得た npm 依存 FOD のハッシュ。
  # lockfile を更新したら nix run nixpkgs#prefetch-npm-deps で再取得すること。
  npmDepsHash = "sha256-W1uQqfeNWL/E3uPN6cO9sqMO72qn8d1ERhu41VqEAao=";

  # 本体は unbuild でビルド済みの純 JS でビルドスクリプトを持たない。build phase を無効化する
  # (省略すると npmBuildHook が build script 不在でハードエラーになる)。
  dontNpmBuild = true;

  # 既定の npmInstallHook は root パッケージ自身を pack する前提のため、
  # 依存をラップする本ケースには合わない。install は自前で行う。
  dontNpmInstall = true;

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

    # git は `bee repo clone` が spawn するため PATH に加える。
    makeWrapper ${nodejs}/bin/node $out/bin/bee \
      --add-flags $out/lib/$pname/node_modules/@nulab/bee/bin/cli.mjs \
      --prefix PATH : ${
        lib.makeBinPath [
          nodejs
          git
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "Backlog CLI by Nulab";
    homepage = "https://github.com/nulab/bee";
    license = lib.licenses.mit;
    mainProgram = "bee";
    platforms = lib.platforms.unix;
  };
}
