# モジュール引数:
#   config - この home-manager 設定自身への参照 (他のオプション値を参照する際に使う)
#   pkgs   - nixpkgs のパッケージセット (flake.nix の pkgs が渡される)
#   neovim-nightly-overlay, system - flake.nix の extraSpecialArgs から渡された値
{ config, pkgs, neovim-nightly-overlay, system, ... }:

{
  # stateVersion: この設定を最初に作成した時点のバージョン。
  # home-manager が内部的なマイグレーションに使う値なので、一度設定したら変えない。
  # nixpkgs を更新しても、ここは変更不要。
  home.stateVersion = "25.05";

  # home-manager 自身を home-manager 経由で管理する。
  # これにより `home-manager` コマンドが PATH に入る。
  programs.home-manager.enable = true;

  # home.packages: インストールするパッケージのリスト。
  # `with pkgs;` で pkgs. のプレフィックスを省略できる。
  # nixpkgs 外のパッケージ (neovim nightly) は ++ で結合する。
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
  ]) ++ [
    # overlay を適用せず直接パッケージを参照する方式。
    # overlay 方式だと nixpkgs 内の treesitter パーサとハッシュが食い違う場合がある。
    neovim-nightly-overlay.packages.${system}.default
  ];
}
