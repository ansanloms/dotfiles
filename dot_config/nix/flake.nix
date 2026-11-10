{
  description = "User package environment";

  # inputs: この flake が依存する外部ソースを定義。
  inputs = {
    # nixpkgs: パッケージリポジトリ。nixos-unstable は最新パッケージが入るチャンネル。
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # nixpkgs-stable: unstable で build が壊れているパッケージの退避先。対象と理由は overlay 側のコメントを参照。
    # unstable 側で直ったらその項目を overlay から外し、overlay で pkgsStable を参照する項目が全て外れたらこの input も削除する。
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    # llm-agents: Claude Code を含む AI コーディングエージェント群を配布する flake (numtide、毎日自動更新)。
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  # outputs: inputs を受け取り、この flake が提供するものを定義する。
  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      llm-agents,
      ...
    }:
    let
      # builtins.currentSystem: 実行環境のアーキテクチャ (例: "x86_64-linux")。
      system = builtins.currentSystem;

      pkgsStable = import nixpkgs-stable { inherit system; };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # llm-agents の claude-code (prebuilt) で nixpkgs 版を上書きする。
          # upstream は overlays 出力を廃止し packages.<system> のみ公開のため、そこから注入する。
          (final: prev: { inherit (llm-agents.packages.${system}) claude-code; })

          # 自前配布の claude-statusline (Claude Code の statusline レンダラ) を callPackage で注入する。
          (final: prev: { claude-statusline = final.callPackage ./claude-statusline.nix { }; })

          # 自前配布の md2html (markdown → 自己完結 HTML 変換 CLI) を callPackage で注入する。
          (final: prev: { md2html = final.callPackage ./md2html.nix { }; })

          # リポジトリ内の shell スクリプト git-worktree-select (fzf で worktree を選ぶ) を callPackage で注入する。
          (final: prev: { git-worktree-select = final.callPackage ./git-worktree-select.nix { }; })

          # nixpkgs 未収録の backlog-bee-cli (Backlog CLI の bee コマンド) を callPackage で注入する。
          # nixpkgs の `bee` は別物 (ethersphere/bee) のため attribute 名を分けている。
          (final: prev: { backlog-bee-cli = final.callPackage ./backlog-bee-cli.nix { }; })

          # nixpkgs 未収録の sonarqube-cli (sonar コマンド) を callPackage で注入する。
          (final: prev: { sonarqube-cli = final.callPackage ./sonarqube-cli.nix { }; })

          # nixpkgs 未収録の Moddable SDK CLI ツール (mcconfig 等) を callPackage で注入する。
          (final: prev: { moddable-sdk = final.callPackage ./moddable-sdk.nix { }; })

          # unstable で build が壊れているパッケージは stable から取る。
          # - git-remote-codecommit: 依存の awscli v1 が botocore / s3transfer のバージョン不一致で落ちる
          # - psd-tools: checkPhase のテストが落ちる (stable 版も同じテストで落ちるため doCheck = false)
          # - sheldon: libgit2-sys が system libgit2 を見つけられず落ちる
          # unstable 側で直ったらその項目を外す。pkgsStable を参照する項目が全て外れたら nixpkgs-stable input も削除する。
          # 外してよいかは、該当行を外して nix build が通るかで確認する。
          (final: prev: {
            git-remote-codecommit = pkgsStable.git-remote-codecommit;
            sheldon = pkgsStable.sheldon;
            pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
              (python-final: python-prev: {
                psd-tools = python-prev.psd-tools.overridePythonAttrs (_: {
                  doCheck = false;
                });
              })
            ];
          })
        ];
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "claude"
            "claude-code"
            "google-chrome"
          ];
      };
    in
    {
      packages.${system}.default = pkgs.buildEnv {
        name = "home-packages";
        paths = import ./packages.nix pkgs;
      };
    };
}
