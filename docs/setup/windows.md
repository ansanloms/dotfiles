# Windows のセットアップ

Windows 端末を CLI で整え、Windows 側に dotfiles を適用する手順。dotfiles の導入全体は [../getting-started.md](../getting-started.md)、WSL ディストリビューションの初期設定は [wsl-archlinux.md](wsl-archlinux.md) にある。

## 方針

- セットアップは原則 CLI で完結させる。GUI 操作が避けられない手順は、その理由とともに記録する。
- 開発作業は WSL 上で行う。Windows 側に入れる開発系ツールは、dotfiles の適用など Windows 側で必要な用途に限定する。
- 組織の管理下にある端末では、設定がグループポリシーで上書きされることがある。管理状態は通常ユーザーの PowerShell で `dsregcmd /status` の Device State (AzureAdJoined/DomainJoined) を見る。適用中の GPO は `gpresult /r` で確認できる。出典: [Troubleshoot devices by using the dsregcmd command](https://docs.azure.cn/en-us/entra/identity/devices/troubleshoot-device-dsregcmd)、[gpresult](https://learn.microsoft.com/nl-nl/windows-server/administration/windows-commands/gpresult)
- winget は GPO で無効化できる。`winget --info` の末尾に適用中のポリシーが表示される。出典: [Policy CSP - DesktopAppInstaller](https://learn.microsoft.com/pl-pl/windows/client-management/mdm/policy-csp-desktopappinstaller)
- PowerShell の実行ポリシーは GPO の「Turn on Script Execution」が全スコープより優先され、`Set-ExecutionPolicy` では上書きできない。`Get-ExecutionPolicy -List` の MachinePolicy/UserPolicy が Undefined 以外なら GPO で固定されている。出典: [about_Execution_Policies](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)
- UAC は既定のまま維持する。昇格プロンプトの煩わしさは、管理者ターミナルを 1 つ開いてまとめて作業する運用で対応する。EnableLUA の無効化と ConsentPromptBehaviorAdmin=0 (確認なし昇格) は、Microsoft が UAC の保護を最小化すると明記しているため採用しない。出典: [Behavior of the elevation prompt for administrators in Admin Approval Mode](https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/user-account-control-behavior-of-the-elevation-prompt-for-administrators-in-admin-approval-mode)、[EnableLUA](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-lua-settings-enablelua)

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

| パッケージ ID               | 用途                                                                                             |
| --------------------------- | ------------------------------------------------------------------------------------------------ |
| AmanThanvi.noctty           | ターミナル (Ghostty のターミナルコアを使う Windows ネイティブ実装。旧名 winghostty)              |
| nathancorvussolis.corvusskk | 日本語入力 (SKK 方式の IME)。インストーラはマシンスコープ                                        |
| Git.Git                     | Git for Windows                                                                                  |
| Neovim.Neovim               | エディタ (Neovim 安定版)                                                                         |
| Microsoft.PowerShell        | PowerShell 7 (pwsh)。dotfiles の PowerShell プロファイルはこちらの場所に配る                     |
| Microsoft.PowerToys         | Windows ユーティリティ集。winget の既定はユーザースコープ (`%LOCALAPPDATA%\Microsoft\PowerToys`) |
| Microsoft.Coreutils         | Windows ネイティブの UNIX 系コマンド群 (uutils/coreutils ベース。findutils と grep を同梱)       |
| 7zip.7zip                   | 圧縮・展開。Windows 11 標準の圧縮機能はパスワード付きアーカイブを扱えない                        |
| Microsoft.VisualStudioCode  | VS Code。開発は WSL で行うため、WSL 拡張機能 `ms-vscode-remote.remote-wsl` も導入する            |
| twpayne.chezmoi             | dotfiles の適用                                                                                  |
| Microsoft.WSL               | WSL 本体 (Store 版)。管理者権限が要る                                                            |

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

### 注意点

noctty は個人 1 名がメンテナンスする若いプロジェクトで、winget 経由のインストーラは PATH を追加しない。起動時に既定で GitHub API へ更新確認を行う。設定は `%LOCALAPPDATA%\noctty\config.ghostty` で、dotfiles が配る。出典: [noctty getting started](https://raw.githubusercontent.com/amanthanvi/noctty/main/docs/getting-started.md)、[noctty PRIVACY.md](https://raw.githubusercontent.com/amanthanvi/noctty/main/PRIVACY.md)

Neovim Nightly (`Neovim.Neovim.Nightly`) は使わない。インストーラの URL は固定の nightly リリースを指し、中身は毎日差し替わる。winget-pkgs 側のハッシュ更新との合間はハッシュ不一致で失敗し、バージョン番号も変わらないため `winget upgrade` で日々の更新は追えない。ハッシュ検証を無効化して回避はしない。出典: [winget-pkgs PR #417698](https://github.com/microsoft/winget-pkgs/pull/417698)

Microsoft.Coreutils の `find.exe`・`sort.exe` は Windows 標準と同名で、PowerShell では `ls` などの既定エイリアスが優先されるため、Coreutils 版を使うにはエイリアスの削除が必要。GitHub リポジトリ上はプレビュー扱い。出典: [Coreutils for Windows overview](https://learn.microsoft.com/en-us/windows/core-utils/overview)

## Scoop とフォント

Scoop 本体は管理者ではない通常の PowerShell で導入する (管理者コンソールでのインストールは既定で拒否される)。

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

再起動後に状態を確認する。「仮想化が有効になっていないため WSL2 を開始できない」と出る場合は、まず上記の有効化が済んでいるかを疑う。BIOS 側の仮想化が有効な端末でも、仮想マシン プラットフォームが無効なまま同じ表示が出て、有効化と再起動で解消した。

```powershell
wsl --status
wsl --list --online
```

ディストリビューションの導入と初期設定は [wsl-archlinux.md](wsl-archlinux.md) に続く。

## dotfiles の適用

Windows 側には chezmoi 管理分のうち Windows 向けの設定 (nvim・git・noctty・alacritty・CorvusSKK・Windows Terminal・PowerShell プロファイル等) だけを配る。前提として上記の Git for Windows・Neovim・PowerShell 7・chezmoi が入っていること。

Windows 側にもリポジトリを clone し、`sourceDir` にその絶対パスを書く。TOML のダブルクォート文字列ではバックスラッシュがエスケープになるため、パスはシングルクォートで書く。

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\chezmoi" | Out-Null
Set-Content "$env:USERPROFILE\.config\chezmoi\chezmoi.toml" "sourceDir = 'C:\path\to\dotfiles'"
setx XDG_CONFIG_HOME "$env:USERPROFILE\.config"
```

`XDG_CONFIG_HOME` を `%USERPROFILE%\.config` にすると nvim が `~/.config/nvim` を読むため、nvim の source に OS 分岐が無くなる。`XDG_CONFIG_HOME` を読む他ツールの探索先も変わりうる点に注意する。`setx` の反映には新しいシェルが要るので、シェルを開き直してから適用する。

```powershell
chezmoi diff
chezmoi apply
```

適用後、nvim で `:echo stdpath("config")` が `~/.config/nvim` を指すことを確認する。

`Documents/PowerShell/profile.ps1` は PowerShell 7 (pwsh) のプロファイルの場所に配る。Windows PowerShell 5.1 は `Documents/WindowsPowerShell` を読むため、pwsh が無いとプロファイルは効かない。
