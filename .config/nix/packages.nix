# 導入するパッケージの一覧。
# flake.nix から `import ./packages.nix pkgs` で読み込まれ、buildEnv の paths になる。
# 用途別の群に分けて並べる。群内はアルファベット順。新しいパッケージは該当する群へ入れ、該当が無ければ群を足す。
pkgs: with pkgs; [
  # shell / 基盤
  curl
  glibcLocales
  less
  openssh
  sheldon
  sshpass
  starship
  wsl-open
  zsh

  # CLI ユーティリティ
  eza
  fzf
  jq
  just
  mdcat
  pandoc
  pueue
  ripgrep

  # ターミナルマルチプレクサ
  tmux
  zellij

  # エディタ
  neovim
  tree-sitter

  # git / forge
  backlog-bee-cli
  gh
  git
  git-crypt
  git-remote-codecommit

  # dotfiles
  chezmoi

  # 言語ランタイム / toolchain
  bun
  deno
  gcc
  go
  nodejs
  python3
  rustup

  # nix
  deadnix
  nix
  nixfmt
  statix

  # lint / 開発ツール
  devcontainer
  hadolint
  playwright-cli
  shellcheck
  sonar-scanner-cli
  sonarqube-cli
  tlaplus

  # クラウド / インフラ
  awscli2
  google-cloud-sdk
  ssm-session-manager-plugin

  # データベース
  percona-toolkit
  postgresql

  # AI エージェント
  apm-cli
  claude-code
  claude-statusline
  devin-cli

  # 組み込み
  moddable-sdk
  platformio-core

  # メディア / 文書 / GUI
  drawio
  ffmpeg
  google-chrome
  md2html
  mkvtoolnix
  python3Packages.psd-tools

  # フォント
  noto-fonts-cjk-sans
  noto-fonts-cjk-serif
]
