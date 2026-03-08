# Steam Account Switcher

A lightweight Steam account switcher for Windows — no re-login required.

![Windows 11](https://img.shields.io/badge/Windows-11-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- Shows all saved Steam accounts (PersonaName + AccountName)
- Switches account by updating the Windows registry
- Gracefully restarts Steam — no password re-entry needed
- Borderless dark UI (Steam theme)
- Global hotkey support via AutoHotkey (optional)

## Requirements

- Windows 10/11
- Steam installed with at least one account saved ("Remember password")
- PowerShell 5.1 (built into Windows)
- [AutoHotkey](https://www.autohotkey.com/) *(optional, for global hotkey)*

## Installation

1. Download and extract the ZIP
2. Double-click `SteamSwitcher.vbs` to launch

**Optional — Global Hotkey (Ctrl+End):**
1. Install [AutoHotkey](https://www.autohotkey.com/) (free)
2. Double-click `SteamSwitcher.ahk`
3. To run at startup: press `Win+R` → type `shell:startup` → copy `SteamSwitcher.ahk` there

## Usage

- **Double-click** an account or select it and click "Konto wechseln"
- **Enter** = switch, **Escape** = close
- The active account is highlighted with a blue bar on the left

## Changing the Hotkey

Open `SteamSwitcher.ahk` in any text editor and change `^End` to your preferred key:

| Symbol | Key |
|--------|-----|
| `^`    | Ctrl |
| `!`    | Alt |
| `+`    | Shift |
| `#`    | Win |

Examples: `^!s` = Ctrl+Alt+S, `#s` = Win+S

## How it works

1. Sets `AutoLoginUser` + `RememberPassword` in the Windows registry (`HKCU\Software\Valve\Steam`)
2. Gracefully shuts down Steam via `-shutdown`
3. Restarts Steam — it auto-logs into the selected account using the stored token

No passwords are read, stored, or transmitted. The script only reads `loginusers.vdf` (your existing Steam file) to display account names.

## License

MIT — free to use, modify and distribute.
