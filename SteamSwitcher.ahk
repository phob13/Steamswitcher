#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

; Hotkey: Strg + Ende  (aenderbar: z.B. ^!s = Strg+Alt+S)
^End::
    Run, wscript.exe "%A_ScriptDir%\SteamSwitcher.vbs"
return
