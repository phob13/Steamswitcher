Add-Type -AssemblyName System.Windows.Forms

# PSScriptRoot-Fallback falls leer (z.B. bei VBS-Start)
$dir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$vbsPath = Join-Path $dir 'SteamSwitcher.vbs'

Add-Type -ReferencedAssemblies 'System.Windows.Forms' @"
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
    public NotifyIcon Tray;

    protected override void OnLoad(EventArgs e) {
        base.OnLoad(e);
        this.Visible       = false;
        this.ShowInTaskbar = false;
        bool ok = RegisterHotKey(this.Handle, 1, MOD_CTRL, VK_END);
        if (!ok) {
            MessageBox.Show("Hotkey (Strg+Ende) konnte nicht registriert werden.\nMoeglicherweise wird er von einem anderen Programm belegt.",
                "Steam Switcher Hotkey", MessageBoxButtons.OK, MessageBoxIcon.Warning);
        }
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_HOTKEY && m.WParam.ToInt32() == 1) {
            System.Diagnostics.Process.Start("wscript.exe", "\"" + VbsPath + "\"");
        }
        base.WndProc(ref m);
    }

    protected override void OnFormClosing(FormClosingEventArgs e) {
        UnregisterHotKey(this.Handle, 1);
        if (Tray != null) { Tray.Visible = false; Tray.Dispose(); }
        base.OnFormClosing(e);
    }
}
"@

$listener         = New-Object HotkeyListener
$listener.VbsPath = $vbsPath

# Tray-Icon damit man sieht dass es laeuft
$tray                      = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon                 = [System.Drawing.SystemIcons]::Application
$tray.Text                 = 'Steam Switcher  (Strg+Ende)'
$tray.Visible              = $true
$listener.Tray             = $tray

# Tray-Kontextmenu: Beenden
$menu    = New-Object System.Windows.Forms.ContextMenuStrip
$item    = $menu.Items.Add('Beenden')
$item.Add_Click({ $listener.Close() })
$tray.ContextMenuStrip = $menu

# Doppelklick auf Tray = Switcher oeffnen
$tray.Add_DoubleClick({ Start-Process 'wscript.exe' -ArgumentList "`"$vbsPath`"" })

[System.Windows.Forms.Application]::Run($listener)
