Dim shell, script
Set shell  = CreateObject("WScript.Shell")
script = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\SteamSwitcher.ps1"
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & script & """", 0, False
