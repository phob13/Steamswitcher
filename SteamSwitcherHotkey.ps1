Add-Type -AssemblyName System.Windows.Forms

# Verstecktes Fenster mit globalem Hotkey via Windows-API (kein AutoHotkey)
Add-Type @"
using System;
using System.Windows.Forms;
using System.Runtime.InteropServices;

public class HotkeyListener : Form {
    [DllImport("user32.dll")]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
    [DllImport("user32.dll")]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    public const uint MOD_CTRL  = 0x0002;
    public const uint VK_END    = 0x23;
    public const int  WM_HOTKEY = 0x0312;

    public string VbsPath;

    protected override void OnLoad(EventArgs e) {
        base.OnLoad(e);
        this.Visible       = false;
        this.ShowInTaskbar = false;
        RegisterHotKey(this.Handle, 1, MOD_CTRL, VK_END);
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_HOTKEY && m.WParam.ToInt32() == 1) {
            System.Diagnostics.Process.Start("wscript.exe", "\"" + VbsPath + "\"");
        }
        base.WndProc(ref m);
    }

    protected override void OnFormClosing(FormClosingEventArgs e) {
        UnregisterHotKey(this.Handle, 1);
        base.OnFormClosing(e);
    }
}
"@

$listener          = New-Object HotkeyListener
$listener.VbsPath  = Join-Path $PSScriptRoot 'SteamSwitcher.vbs'
[System.Windows.Forms.Application]::Run($listener)
