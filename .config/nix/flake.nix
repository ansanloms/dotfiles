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
          # llm-agents の claude-code (prebuilt) で nixpkgs 版を上書きする。
          # upstream は overlays 出力を廃止し packages.<system> のみ公開のため、そこから注入する。
          (final: prev: { inherit (llm-agents.packages.${system}) claude-code; })

          # 自前配布の claude-statusline (Claude Code の statusline レンダラ) を callPackage で注入する。
          (final: prev: { claude-statusline = final.callPackage ./claude-statusline.nix { }; })

          # 自前配布の md2html (markdown → 自己完結 HTML 変換 CLI) を callPackage で注入する。
          (final: prev: { md2html = final.callPackage ./md2html.nix { }; })

          # nixpkgs 未収録の playwright-cli を callPackage で注入する。
          (final: prev: { playwright-cli = final.callPackage ./playwright-cli.nix { }; })

          # nixpkgs 未収録の sonarqube-cli (sonar コマンド) を callPackage で注入する。
          (final: prev: { sonarqube-cli = final.callPackage ./sonarqube-cli.nix { }; })

          # nixpkgs 未収録の Moddable SDK CLI ツール (mcconfig 等) を callPackage で注入する。
          (final: prev: { moddable-sdk = final.callPackage ./moddable-sdk.nix { }; })

          # apm-cli は nixpkgs 収録済みだが upstream リリースから遅れるため、自前 derivation で上書きする。
          (final: prev: { apm-cli = final.callPackage ./apm-cli.nix { }; })

          # nixpkgs の percona-toolkit 3.7.1 は src の fetchFromGitHub が leaveDotGit = true で .git を出力に含めるため、
          # 固定ハッシュが取得時の git によるパック生成結果に依存し、nixpkgs が計算した値と食い違ってビルドできない。
          # 取得コミットはタグ v3.7.1 と一致しており、差はツリーの中身ではなく .git のパックデータ。
          # perlPackages.PerconaToolkit の fetchFromGitHub を差し替え、この環境での実測ハッシュで取得する。
          # goDeps (buildGoModule) も同じ src を inherit するため、src ではなく fetcher ごと差し替える。
          # upstream の src のハッシュが nixpkgs の (食い違う) 値と一致するときだけ適用し、
          # upstream が version・ハッシュ・leaveDotGit のいずれかを変えたら自動で外れる。
          # 条件は属性値の内側に置く (optionalAttrs で属性名自体を条件付きにすると overlay 合成時に即時評価され infinite recursion になる)。
          # 再びハッシュ不一致になったときの対処は、エラーの specified: で場合を分ける。
          # - specified: が下の hash と同じ: overlay は効いたまま (git-minimal の更新等でパック生成が変わった)。
          #   got: を hash に取り直す。brokenHash は nixpkgs 側の値なので触らない。
          # - specified: が brokenHash と違う: upstream がハッシュを変え、overlay は自動で外れている。
          #   それでも直っていなければ、specified: を brokenHash に、got: を hash に取り直す。
          # 削除の判断は「この overlay を消しても nix build が通るか」で行い、通るなら削除する。
          (
            final: prev:
            let
              upstream = prev.perlPackages.PerconaToolkit or null;
              # nixpkgs が計算した、この環境では一致しないハッシュ。
              brokenHash = "sha256-bdEc+vaWxEN5jzd1bcScBj1QV7Oz7Xn3XWeW6TvkE/E=";
              needsOverride = upstream != null && (upstream.src.outputHash or null) == brokenHash;
            in
            {
              percona-toolkit =
                if !needsOverride then
                  prev.percona-toolkit
                else
                  prev.percona-toolkit.override {
                    perlPackages = prev.perlPackages // {
                      PerconaToolkit = upstream.override {
                        fetchFromGitHub =
                          args:
                          final.fetchFromGitHub (
                            removeAttrs args [
                              "hash"
                              "sha256"
                            ]
                            // {
                              hash = "sha256-DKypgv6J9QxMVoKvv+5oRp85V14cVkzt+tHj5jG5arY=";
                            }
                          );
                      };
                    };
                  };
            }
          )
        ];
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "claude"
            "claude-code"
            "google-chrome"
            "devin-cli"
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
