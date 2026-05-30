# 導入するパッケージの一覧。
# flake.nix から `import ./packages.nix pkgs` で読み込まれ、buildEnv の paths になる。
pkgs: with pkgs; [
  nodejs
  deno
  rustup
  go
  tree-sitter
  zellij
  tmux
  starship
  awscli2
  eza
  sheldon
  wsl-open
  devcontainer
  claude-code
  just
  neovim
  platformio-core
  shellcheck
  statix
  deadnix
  nixfmt-rfc-style
]
