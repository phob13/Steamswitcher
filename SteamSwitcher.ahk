#Requires AutoHotkey v2
#SingleInstance

; Hotkey: Strg + Ende  (aenderbar: z.B. ^!s = Strg+Alt+S)
^End:: Run 'wscript.exe "' A_ScriptDir '\SteamSwitcher.vbs"'
