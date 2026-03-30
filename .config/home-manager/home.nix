# モジュール引数:
#   config - この home-manager 設定自身への参照 (他のオプション値を参照する際に使う)
#   pkgs   - nixpkgs のパッケージセット (flake.nix の pkgs が渡される)
{ config, pkgs, ... }:

{
  # stateVersion: この設定を最初に作成した時点のバージョン。
  # home-manager が内部的なマイグレーションに使う値なので、一度設定したら変えない。
  # nixpkgs を更新しても、ここは変更不要。
  home.stateVersion = "25.05";

  # nixpkgs の設定。unfree ライセンスのパッケージを個別に許可する。
  # 新たに unfree パッケージを追加する場合はここにも追記が必要。
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "claude-code"
    ];

  # home-manager 自身を home-manager 経由で管理する。
  # これにより `home-manager` コマンドが PATH に入る。
  programs.home-manager.enable = true;

  # home.packages: インストールするパッケージのリスト。
  # `with pkgs;` で pkgs. のプレフィックスを省略できる。
  home.packages = (with pkgs; [
    nodejs       # npm 同梱
    deno
    rustup       # `rustup default stable` で toolchain をインストールする
    go
    tree-sitter
    zellij
    starship
    awscli2
    eza
    sheldon
    wsl-open
    devcontainer
    claude-code
    just
    neovim
  ]);
}
