# Windows のセットアップ

Windows 端末を CLI で整え、Windows 側に dotfiles を適用する手順。dotfiles の導入全体は [../getting-started.md](../getting-started.md)、WSL ディストリビューションの初期設定は [wsl-archlinux.md](wsl-archlinux.md) にある。

## 方針

- セットアップは原則 CLI で完結させる。GUI 操作が避けられない手順は、その理由とともに記録する。
- 開発作業は WSL 上で行う。Windows 側に入れる開発系ツールは、dotfiles の適用など Windows 側で必要な用途に限定する。

## 開発者向け設定

開発者モードと Sudo for Windows を有効化する前に、ポリシーで制御されていないことを確認する。「指定されたレジストリ キーまたは値が見つかりませんでした」と出ればポリシー未構成。

```powershell
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Appx /v AllowDevelopmentWithoutDevLicense
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Sudo /v EnableSudo
```

Sudo for Windows をインラインモード (`normal`) で有効化する (管理者ターミナルで実行)。以降の手順の `sudo` はこれを使う。

```powershell
sudo config --enable normal
```

開発者モードを有効化する。シンボリックリンクを管理者権限なしで作成できるようになる。

```powershell
sudo reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 1 /f
```

## アプリの導入 (winget)

パッケージは ID と完全一致 (`--id <ID> -e`) で指定する。

| パッケージ ID               | 用途                                                                                               |
| --------------------------- | -------------------------------------------------------------------------------------------------- |
| AmanThanvi.noctty           | ターミナル (Ghostty のターミナルコアを使う Windows ネイティブ実装。旧名 winghostty)。              |
| nathancorvussolis.corvusskk | 日本語入力 (SKK 方式の IME)。インストーラはマシンスコープ。                                        |
| Git.Git                     | Git for Windows                                                                                    |
| Neovim.Neovim               | エディタ (Neovim 安定版)                                                                           |
| Microsoft.PowerShell        | PowerShell 7 (pwsh)。dotfiles の PowerShell プロファイルはこちらの場所に配る。                     |
| Microsoft.PowerToys         | Windows ユーティリティ集。winget の既定はユーザースコープ (`%LOCALAPPDATA%\Microsoft\PowerToys`)。 |
| Microsoft.Coreutils         | Windows ネイティブの UNIX 系コマンド群 (uutils/coreutils ベース。findutils と grep を同梱)。       |
| 7zip.7zip                   | 圧縮・展開。Windows 11 標準の圧縮機能はパスワード付きアーカイブを扱えない。                        |
| Microsoft.VisualStudioCode  | VS Code。開発は WSL で行うため、WSL 拡張機能 `ms-vscode-remote.remote-wsl` も導入する。            |
| twpayne.chezmoi             | dotfiles の適用                                                                                    |
| Microsoft.WSL               | WSL 本体 (Store 版)。管理者権限が要る。                                                            |

```powershell
winget install --id AmanThanvi.noctty -e
winget install --id nathancorvussolis.corvusskk -e
winget install --id Git.Git -e --source winget
winget install --id Neovim.Neovim -e
winget install --id Microsoft.PowerShell -e
winget install --id Microsoft.PowerToys -e --source winget
winget install --id Microsoft.Coreutils -e
winget install --id 7zip.7zip -e --source winget
winget install --id Microsoft.VisualStudioCode -e
winget install --id twpayne.chezmoi -e
sudo winget install --id Microsoft.WSL -e
```

仕上げに `winget upgrade` で対象一覧を確認してから `winget upgrade --all` で導入済みパッケージを更新する。

## Scoop とフォント

[Scoop](https://scoop.sh/) 本体は管理者ではない通常の PowerShell で導入する (管理者コンソールでのインストールは既定で拒否される)。

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

自前バケットを追加し、フォント Moralerspace を導入する。Monaspace と IBM Plex Sans JP などを合成したプログラミング向けフォントで、SIL Open Font License 1.1。出典: [yuru7/moralerspace](https://github.com/yuru7/moralerspace)

```powershell
scoop bucket add ansanloms https://github.com/ansanloms/scoop-ansanloms.git
sudo scoop install ansanloms/moralerspace
```

このマニフェストはフォントをシステムのフォントフォルダ (`%WINDIR%\Fonts`) に入れるため管理者権限が要り、`sudo` 付きで実行する (Scoop 本体の導入とは逆で、こちらは昇格が前提)。

## WSL

WSL 本体 (上記の `Microsoft.WSL`) を入れた後、仮想マシン プラットフォームを有効化する。再起動が要る。

```powershell
sudo wsl --install --no-distribution
Restart-Computer
```

再起動後に状態を確認する。

```powershell
wsl --status
wsl --list --online
```

ディストリビューションの導入と初期設定は [wsl-archlinux.md](wsl-archlinux.md) に続く。

## dotfiles の適用

Windows 側にもリポジトリを `%USERPROFILE%\dev\github.com\ansanloms\dotfiles` へ clone し、chezmoi 自身の設定 `%USERPROFILE%\.config\chezmoi\chezmoi.toml` をリポジトリ直下の `.chezmoi.toml.tmpl` から `chezmoi init` で生成する。

```powershell
git clone https://github.com/ansanloms/dotfiles.git "$env:USERPROFILE\dev\github.com\ansanloms\dotfiles"
chezmoi --source "$env:USERPROFILE\dev\github.com\ansanloms\dotfiles" init
```

生成後は `--source` 無しでよい。

Neovim と noctty は設定ディレクトリの解決に `XDG_CONFIG_HOME` を使う (Neovim は未設定なら `%LOCALAPPDATA%\nvim`、noctty は未設定なら `%LOCALAPPDATA%\noctty`)。dotfiles は両者を Linux / macOS と同じ `~/.config` 配下に配るため、`XDG_CONFIG_HOME` を `%USERPROFILE%\.config` に設定する。`setx` はユーザー環境変数を永続化するが、既に開いているシェルには反映されないので、設定後にシェルを開き直す。alacritty は Windows では `%APPDATA%` しか見ないため `XDG_CONFIG_HOME` の影響を受けず、`AppData\Roaming\alacritty` に配る。

```powershell
setx XDG_CONFIG_HOME "$env:USERPROFILE\.config"
```

シェルを開き直してから差分を確認して適用する。

```powershell
chezmoi diff
chezmoi apply
```

適用後、`nvim` で `:echo stdpath("config")` が `%USERPROFILE%\.config\nvim` を指すことを確認する。
