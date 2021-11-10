$Env:LANG = "ja"
$Env:EDITOR = "vim"
$Env:LESSCHARSET = "UTF-8"
$Env:FZF_DEFAULT_COMMAND = "rg --files --path-separator /"

$Env:Path += ";" + (Join-Path $Env:homedrive  "\msys64\usr\bin")
$Env:Path += ";" + (Join-Path $Env:homedrive  "\msys64\mingw64\bin")
$Env:Path += ";" + (Join-Path $Env:userprofile  "\.deno\bin")
$Env:Path += ";" + (Join-Path $Env:programfiles  "\Vim\vim82")

# bash ライクな補完
Set-PSReadLineKeyHandler -Key Tab -Function Complete

# starship
Invoke-Expression (&starship init powershell)

# alias
Set-Alias -Name vim -Value gvim
