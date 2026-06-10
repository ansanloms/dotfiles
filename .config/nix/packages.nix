# 導入するパッケージの一覧。
# flake.nix から `import ./packages.nix pkgs` で読み込まれ、buildEnv の paths になる。
pkgs: with pkgs; [
  apm
  awscli2
  bun
  claude-code
  deadnix
  deno
  devcontainer
  drawio
  eza
  ffmpeg
  gh
  go
  google-chrome
  jq
  just
  neovim
  nixfmt
  nodejs
  platformio-core
  playwright-cli
  rustup
  sheldon
  shellcheck
  starship
  statix
  tmux
  tree-sitter
  wsl-open
  zellij
  zsh
  devin-cli
  hadolint
]
