{
  description = "User package environment";

  # inputs: この flake が依存する外部ソースを定義。
  inputs = {
    # nixpkgs: パッケージリポジトリ。nixos-unstable は最新パッケージが入るチャンネル。
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # llm-agents: Claude Code を含む AI コーディングエージェント群を配布する flake (numtide、毎日自動更新)。
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  # outputs: inputs を受け取り、この flake が提供するものを定義する。
  outputs =
    { nixpkgs, llm-agents, ... }:
    let
      # builtins.currentSystem: 実行環境のアーキテクチャ (例: "x86_64-linux")。
      system = builtins.currentSystem;

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # llm-agents の overlay を適用した pkgs を構築する (prebuilt をそのまま使う default)。
          llm-agents.overlays.default

          # nixpkgs 未収録の playwright-cli を callPackage で注入する。
          (final: prev: { playwright-cli = final.callPackage ./playwright-cli.nix { }; })

          # nixpkgs 未収録の sonarqube-cli (sonar コマンド) を callPackage で注入する。
          (final: prev: { sonarqube-cli = final.callPackage ./sonarqube-cli.nix { }; })
        ];
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude" "claude-code" "google-chrome" "devin-cli" ];
      };
    in
    {
      packages.${system}.default = pkgs.buildEnv {
        name = "home-packages";
        paths = import ./packages.nix pkgs;
      };
    };
}
