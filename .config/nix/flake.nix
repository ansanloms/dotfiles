{
  description = "User package environment";

  # inputs: この flake が依存する外部ソースを定義。
  inputs = {
    # nixpkgs: パッケージリポジトリ。nixos-unstable は最新パッケージが入るチャンネル。
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nix-claude-code: Anthropic 公式の Bun ビルド済み Claude Code バイナリを配布する flake。
    nix-claude-code.url = "github:ryoppippi/nix-claude-code";
  };

  # outputs: inputs を受け取り、この flake が提供するものを定義する。
  outputs =
    { nixpkgs, nix-claude-code, ... }:
    let
      # builtins.currentSystem: 実行環境のアーキテクチャ (例: "x86_64-linux")。
      system = builtins.currentSystem;

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # nix-claude-code の overlay を適用した pkgs を構築する。
          nix-claude-code.overlays.default

          # nixpkgs 未収録の playwright-cli を callPackage で注入する。
          (final: prev: { playwright-cli = final.callPackage ./playwright-cli.nix { }; })
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
