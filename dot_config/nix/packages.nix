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
  wsl2-ssh-agent # WSL から Windows 側の ssh-agent.exe (OpenSSH Authentication Agent) へ橋渡しする
  zsh

  # CLI ユーティリティ
  eza
  fzf
  gnutar
  jq
  just
  mdcat
  pandoc
  pueue
  ripgrep
  rsync
  unzip
  xz
  zip

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
  git-worktree-select # リポジトリ内の shell スクリプト (fzf で worktree を選ぶ)

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
  betterleaks
  devcontainer
  hadolint
  shellcheck
  sonar-scanner-cli
  sonarqube-cli
  tlaplus

  # クラウド / インフラ
  awscli2
  cloudflared
  google-cloud-sdk
  ssm-session-manager-plugin

  # ネットワーク / 証明書
  mkcert
  nssTools # certutil / pk12util 等 (mkcert が Firefox/Chromium の NSS DB へ CA を入れる際に certutil を使う)

  # データベース
  percona-toolkit
  postgresql

  # AI エージェント
  apm-cli
  claude-code
  claude-statusline

  # 組み込み
  moddable-sdk
  platformio-core

  # ディスク / ISO イメージ
  dosfstools
  libisoburn # xorriso
  mtools

  # メディア / 文書 / GUI
  drawio
  ffmpeg
  google-chrome
  md2html
  mkvtoolnix
  python3Packages.psd-tools

  # フォント
  dejavu_fonts
  noto-fonts-cjk-sans
  noto-fonts-cjk-serif
]
