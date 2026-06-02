# 導入するパッケージの一覧。
# flake.nix から `import ./packages.nix pkgs` で読み込まれ、buildEnv の paths になる。
pkgs: with pkgs; [
  zsh
  nodejs
  deno
  bun
  rustup
  go
  tree-sitter
  zellij
  starship
  tmux
  starship
  awscli2
  eza
  sheldon
  wsl-open
  devcontainer
  claude-code
  apm
  just
  neovim
  platformio-core
  shellcheck
  statix
  deadnix
  nixfmt
  gh
  drawio
]
