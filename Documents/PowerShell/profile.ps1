$Env:LANG = "ja"
$Env:EDITOR = "nvim"
$Env:LESSCHARSET = "UTF-8"
$Env:RIPGREP_CONFIG_PATH = (Join-Path $Env:userprofile "\.ripgreprc")

$Env:Path += ";" + (Join-Path $Env:homedrive "\msys64\usr\bin")
$Env:Path += ";" + (Join-Path $Env:homedrive "\msys64\mingw64\bin")
$Env:Path += ";" + (Join-Path $Env:userprofile "\.deno\bin")
$Env:Path += ";" + (Join-Path $Env:programfiles "\Vim\vim91")

# bash ライクな補完
Set-PSReadLineKeyHandler -Key Tab -Function Complete

# Prompt に staship を使う
Invoke-Expression (&starship init powershell)

# インライン予測のテキストの色を設定
Set-PSReadLineOption -Colors @{ InlinePrediction = $PSStyle.Foreground.BrightBlack }

# 警告音を消す
Set-PSReadlineOption -BellStyle None

# 履歴の重複を許可しない
Set-PSReadlineOption -HistoryNoDuplicates

function eza-ll() {
  eza $(@("--long"); $args)
}

function togif() {
  param (
    [string]$inputPath,
    [string]$outputPath = $null
  )

  if (-not (Test-Path $inputPath)) {
    Write-Host "input file was not found: $inputPath"
    return
  }

  if (-not $outputPath) {
    $outputPath = [System.IO.Path]::ChangeExtension($inputPath, ".gif")
  } elseif ($outputPath -notlike "*.gif") {
    $outputPath = [System.IO.Path]::ChangeExtension($outputPath, ".gif")
  }

  ffmpeg -i $inputPath -filter_complex "[0:v] fps=10,scale=480:-1, split [a][b];[a] palettegen [p];[b][p] paletteuse=dither=none" $outputPath
}

# alias
Set-Alias -Name vi -Value nvim
Set-Alias -Name vim -Value nvim
Set-Alias -Name open -Value Invoke-Item
Set-Alias -Name rm -Value (Join-Path $Env:homedrive "\msys64\usr\bin\rm.exe")
Set-Alias -Name find -Value (Join-Path $Env:homedrive "\msys64\usr\bin\find.exe")
Set-Alias -Name tree -Value (Join-Path $Env:homedrive "\msys64\usr\bin\tree.exe")
Set-Alias -Name mkdir -Value (Join-Path $Env:homedrive "\msys64\usr\bin\mkdir.exe")

if (Get-Command eza -errorAction SilentlyContinue) {
  Set-Alias -Name ls -Value eza
  Set-Alias -Name ll -Value eza-ll
} else {
  Set-Alias -Name ll -Value Get-ChildItem
}

if (Get-Command bat -errorAction SilentlyContinue) {
  Set-Alias -Name cat -Value bat
}

# mise
if (Get-Command mise -errorAction SilentlyContinue) {
  mise activate pwsh | Out-String | Invoke-Expression
}
