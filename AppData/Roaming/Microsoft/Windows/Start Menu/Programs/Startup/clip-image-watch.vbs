' clip-image-watch.vbs
'
' Launch the clipboard watcher hidden at logon, with no console window flash.
' Placed in the Startup folder; runs clip-image-watch.ps1 from %LOCALAPPDATA%.

Set sh = CreateObject("WScript.Shell")
ps1 = sh.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\clip-image-watch.ps1"
sh.Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1 & """", 0, False
