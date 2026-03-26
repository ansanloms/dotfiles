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

    # neovim-nightly-overlay: Neovim の nightly ビルドを提供する。
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
    };
  };

  # outputs: inputs を受け取り、この flake が提供するものを定義する。
  # home-manager の場合は homeConfigurations を定義する。
  outputs = { nixpkgs, home-manager, neovim-nightly-overlay, ... }:
    let
      # builtins.getEnv は環境変数を取得する。
      # flakes の pure evaluation では禁止されるため、--impure フラグが必要。
      username = builtins.getEnv "USER";
      homeDirectory = builtins.getEnv "HOME";

      # builtins.currentSystem: 実行環境のアーキテクチャ (例: "x86_64-linux")。
      # これも impure な値。
      system = builtins.currentSystem;
    in
    {
      # homeConfigurations."<ユーザー名>" で home-manager の設定を定義する。
      # `home-manager switch` 実行時にこの定義が適用される。
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        # pkgs: このシステム向けの nixpkgs パッケージセット。
        pkgs = nixpkgs.legacyPackages.${system};

        # extraSpecialArgs: ここで渡した値が home.nix のモジュール引数として使える。
        # 例えば neovim-nightly-overlay を home.nix 側で参照するために渡している。
        extraSpecialArgs = {
          inherit neovim-nightly-overlay system;
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
