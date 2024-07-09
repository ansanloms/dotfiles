$Env:LANG = "ja"
$Env:EDITOR = "vim"
$Env:LESSCHARSET = "UTF-8"

$Env:Path += ";" + (Join-Path $Env:homedrive  "\msys64\usr\bin")
$Env:Path += ";" + (Join-Path $Env:homedrive  "\msys64\mingw64\bin")
$Env:Path += ";" + (Join-Path $Env:userprofile  "\.deno\bin")
$Env:Path += ";" + (Join-Path $Env:programfiles  "\Vim\vim91")

# bash ライクな補完
Set-PSReadLineKeyHandler -Key Tab -Function Complete

# Prompt に staship を使う
Invoke-Expression (&starship init powershell)

# PSReadLine
Set-PSReadLineOption -Colors @{ InlinePrediction = $PSStyle.Foreground.BrightBlack }
Set-PSReadlineOption -BellStyle None

function eza-no-color() {
  eza $(@("--color", "never"); $args)
}

function eza-ll() {
  eza $(@("--color", "never", "--long"); $args)
}

# alias
if (Get-Command eza -errorAction SilentlyContinue) {
  # 少なくとも gvim の terminal 上では ansi color エスケープシーケンスが上手く反映されないので。
  Set-Alias -Name ls -Value eza-no-color
  Set-Alias -Name ll -Value eza-ll
} else {
  Set-Alias -Name ll -Value Get-ChildItem
}
if (Get-Command bat -errorAction SilentlyContinue) {
  Set-Alias -Name cat -Value bat
}
Set-Alias -Name vi -Value vim
Set-Alias -Name open -Value Invoke-Item
