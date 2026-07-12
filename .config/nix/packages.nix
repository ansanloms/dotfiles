# 導入するパッケージの一覧。
# flake.nix から `import ./packages.nix pkgs` で読み込まれ、buildEnv の paths になる。
pkgs: with pkgs; [
  apm-cli
  awscli2
  bun
  claude-code
  curl
  deadnix
  deno
  devcontainer
  devin-cli
  drawio
  eza
  ffmpeg
  gh
  git
  go
  google-chrome
  hadolint
  jq
  just
  moddable-sdk
  neovim
  # nix client を nixpkgs 版で先勝ちさせる (~/.nix-profile/bin が daemon profile より PATH 先行)。
  # installer 同梱バイナリの libgit2 が古く (1.9.2 < 1.9.4)、relativeWorktrees 拡張のある
  # リポジトリを git fetcher が開けないため。nixpkgs 版は nixpkgs の libgit2 (1.9.4+) にリンクする。
  nix
  nixfmt
  nodejs
  noto-fonts-cjk-sans
  noto-fonts-cjk-serif
  percona-toolkit
  platformio-core
  playwright-cli
  ripgrep
  rustup
  sheldon
  shellcheck
  sonar-scanner-cli
  sonarqube-cli
  ssm-session-manager-plugin
  starship
  statix
  tlaplus
  tmux
  tree-sitter
  wsl-open
  zellij
  zsh
]
