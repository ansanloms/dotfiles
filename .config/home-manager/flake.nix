{
  description = "Home Manager configuration";

  # inputs: この flake が依存する外部ソースを定義する。
  # `nix flake update` で全 inputs の lock を最新に更新できる。
  inputs = {
    # nixpkgs: パッケージリポジトリ。nixos-unstable は最新パッケージが入るチャンネル。
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager: ユーザー環境のパッケージを宣言的に管理するツール。
    # `inputs.nixpkgs.follows = "nixpkgs"` で、home-manager が使う nixpkgs を
    # 上で定義した nixpkgs に統一する。これがないと nixpkgs が二重評価されて遅くなる。
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-claude-code: Anthropic 公式の Bun ビルド済み Claude Code バイナリを
    # 配布する flake。nixpkgs の Node.js ベース版より起動が速い。
    nix-claude-code.url = "github:ryoppippi/nix-claude-code";
  };

  # outputs: inputs を受け取り、この flake が提供するものを定義する。
  # home-manager の場合は homeConfigurations を定義する。
  outputs = { nixpkgs, home-manager, nix-claude-code, ... }:
    let
      # builtins.getEnv は環境変数を取得する。
      # flakes の pure evaluation では禁止されるため、--impure フラグが必要。
      username = builtins.getEnv "USER";
      homeDirectory = builtins.getEnv "HOME";

      # builtins.currentSystem: 実行環境のアーキテクチャ (例: "x86_64-linux")。
      # これも impure な値。
      system = builtins.currentSystem;

      # nix-claude-code の overlay を適用した pkgs を構築する。
      # overlay により pkgs.claude-code が ryoppippi/nix-claude-code 提供版に
      # 差し替わる。allowUnfreePredicate もここで指定する必要がある
      # (home.nix 側の nixpkgs.config は pkgs を外から渡すと無視されるため)。
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nix-claude-code.overlays.default ];
        config.allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "claude"
          ];
      };
    in
    {
      # homeConfigurations."<ユーザー名>" で home-manager の設定を定義する。
      # `home-manager switch` 実行時にこの定義が適用される。
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
        };

        # modules: 読み込む設定ファイルのリスト。
        # インラインで属性セットを書くとそのまま設定として適用される。
        modules = [
          ./home.nix
          {
            home.username = username;
            home.homeDirectory = homeDirectory;
          }
        ];
      };
    };
}
