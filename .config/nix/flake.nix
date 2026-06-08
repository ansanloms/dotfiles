{
  description = "User package environment";

  # inputs: この flake が依存する外部ソースを定義。
  inputs = {
    # nixpkgs: パッケージリポジトリ。nixos-unstable は最新パッケージが入るチャンネル。
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nix-claude-code: Anthropic 公式の Bun ビルド済み Claude Code バイナリを配布する flake。
    nix-claude-code.url = "github:ryoppippi/nix-claude-code";

    # deno-bin: deno 公式の最新リリースバイナリ (linux/x86_64, zip)。
    # releases/latest/download は常に最新リリースへリダイレクトするため、
    # `nix flake update` のたびに最新版へ追従する。
    # file+https スキームで解凍せず生の zip として取得する (deno.nix 側で unzip)。
    deno-bin = {
      url = "file+https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip";
      flake = false;
    };
  };

  # outputs: inputs を受け取り、この flake が提供するものを定義する。
  outputs =
    { nixpkgs, nix-claude-code, deno-bin, ... }:
    let
      # builtins.currentSystem: 実行環境のアーキテクチャ (例: "x86_64-linux")。
      system = builtins.currentSystem;

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # nix-claude-code の overlay を適用した pkgs を構築する。
          nix-claude-code.overlays.default

          # nixpkgs 未収録の apm を callPackage で注入する。
          (final: prev: { apm = final.callPackage ./apm.nix { }; })

          # nixpkgs 未収録の playwright-cli を callPackage で注入する。
          (final: prev: { playwright-cli = final.callPackage ./playwright-cli.nix { }; })

          # nixpkgs の deno を最新リリースバイナリで上書きする (deno-bin input を追従)。
          (final: prev: { deno = final.callPackage ./deno.nix { src = deno-bin; }; })
        ];
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude" "google-chrome" "devin-cli" ];
      };
    in
    {
      packages.${system}.default = pkgs.buildEnv {
        name = "home-packages";
        paths = import ./packages.nix pkgs;
      };
    };
}
