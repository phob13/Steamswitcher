@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0SteamSwitcher.ps1"
if %errorlevel% neq 0 (
    echo.
    echo Fehler beim Ausfuehren! ErrorLevel: %errorlevel%
    pause
)
