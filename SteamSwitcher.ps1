Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Steam-Pfad
$steamReg  = 'HKCU:\Software\Valve\Steam'
$steamPath = (Get-ItemProperty $steamReg -ErrorAction SilentlyContinue).SteamPath
if (-not $steamPath) { $steamPath = 'C:\Program Files (x86)\Steam' }
$steamExe  = Join-Path $steamPath 'steam.exe'
$vdfPath   = Join-Path $steamPath 'config\loginusers.vdf'

# loginusers.vdf parsen (nur lesen, nie schreiben)
$accounts = [System.Collections.Generic.List[hashtable]]::new()
if (Test-Path $vdfPath) {
    $current = $null
    foreach ($line in (Get-Content $vdfPath)) {
        $t = $line.Trim()
        if ($t -match '^"(\d{10,20})"$')               { $current = @{ SteamID = $Matches[1]; AccountName = ''; PersonaName = '' } }
        elseif ($current -and $t -match '"AccountName"\s+"([^"]+)"')  { $current.AccountName = $Matches[1] }
        elseif ($current -and $t -match '"PersonaName"\s+"([^"]+)"')  { $current.PersonaName = $Matches[1] }
        elseif ($t -eq '}' -and $current -and $current.AccountName)   { $accounts.Add($current); $current = $null }
    }
}

if ($accounts.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show(
        "Keine gespeicherten Accounts gefunden.`nSteam muss mindestens einmal mit 'Passwort merken' angemeldet worden sein.",
        'Steam Switcher', 'OK', 'Warning')
    exit
}

$currentUser = (Get-ItemProperty $steamReg -Name AutoLoginUser -ErrorAction SilentlyContinue).AutoLoginUser

# Account wechseln: nur Registry ändern + Steam neu starten
function Switch-SteamAccount {
    param($AccountName)
    Set-ItemProperty $steamReg -Name AutoLoginUser    -Value $AccountName
    Set-ItemProperty $steamReg -Name RememberPassword -Value 1 -Type DWord

    if (Get-Process steam -ErrorAction SilentlyContinue) {
        Start-Process $steamExe -ArgumentList '-shutdown'
        $w = 0
        while ((Get-Process steam -ErrorAction SilentlyContinue) -and $w -lt 20) {
            Start-Sleep -Milliseconds 500
            $w++
        }
        Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Milliseconds 500
    }
    Start-Process $steamExe
}

# Farben
$clrBg     = [Drawing.Color]::FromArgb(27,  40,  56)
$clrPanel  = [Drawing.Color]::FromArgb(42,  71,  94)
$clrAccent = [Drawing.Color]::FromArgb(103, 193, 245)
$clrText   = [Drawing.Color]::FromArgb(193, 210, 227)
$clrSub    = [Drawing.Color]::FromArgb(120, 150, 175)
$clrSel    = [Drawing.Color]::FromArgb(57,  97,  133)

# Formular
$form = New-Object Windows.Forms.Form
$form.Text            = 'Steam Account Switcher'
$form.ClientSize      = [Drawing.Size]::new(360, 430)
$form.StartPosition   = 'CenterScreen'
$form.FormBorderStyle = 'None'
$form.BackColor       = $clrBg

# Draggable ohne Titelleiste
$dragStart = [Drawing.Point]::new(0,0)
$dragging  = $false
$form.Add_MouseDown({ param($s,$e); if ($e.Button -eq 'Left') { $script:dragging = $true; $script:dragStart = $e.Location } })
$form.Add_MouseMove({ param($s,$e); if ($script:dragging) { $form.Location = [Drawing.Point]::new($form.Left + $e.X - $script:dragStart.X, $form.Top + $e.Y - $script:dragStart.Y) } })
$form.Add_MouseUp({   param($s,$e); $script:dragging = $false })

# X-Button oben rechts
$btnClose = New-Object Windows.Forms.Button
$btnClose.Text      = 'X'
$btnClose.Size      = [Drawing.Size]::new(32, 28)
$btnClose.Location  = [Drawing.Point]::new(328, 0)
$btnClose.FlatStyle = 'Flat'
$btnClose.FlatAppearance.BorderSize = 0
$btnClose.BackColor = $clrBg
$btnClose.ForeColor = $clrSub
$btnClose.Font      = [Drawing.Font]::new('Segoe UI', 10)
$btnClose.Cursor    = [Windows.Forms.Cursors]::Hand
$btnClose.Add_Click({ $form.Close() })
$form.Controls.Add($btnClose)

# Titel-Label (auch draggable)
$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text      = 'Steam Account Switcher'
$lblTitle.Font      = [Drawing.Font]::new('Segoe UI', 13, [Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $clrAccent
$lblTitle.Location  = [Drawing.Point]::new(15, 14)
$lblTitle.AutoSize  = $true
$lblTitle.Add_MouseDown({ param($s,$e); if ($e.Button -eq 'Left') { $script:dragging = $true; $script:dragStart = $e.Location } })
$lblTitle.Add_MouseMove({ param($s,$e); if ($script:dragging) { $form.Location = [Drawing.Point]::new($form.Left + $e.X - $script:dragStart.X, $form.Top + $e.Y - $script:dragStart.Y) } })
$lblTitle.Add_MouseUp({ param($s,$e); $script:dragging = $false })
$form.Controls.Add($lblTitle)

$lblSub = New-Object Windows.Forms.Label
$lblSub.Text      = 'Doppelklick oder auswählen + Wechseln'
$lblSub.Font      = [Drawing.Font]::new('Segoe UI', 8.5)
$lblSub.ForeColor = $clrSub
$lblSub.Location  = [Drawing.Point]::new(15, 42)
$lblSub.AutoSize  = $true
$form.Controls.Add($lblSub)

$sep = New-Object Windows.Forms.Panel
$sep.Location  = [Drawing.Point]::new(0, 62)
$sep.Size      = [Drawing.Size]::new(360, 1)
$sep.BackColor = $clrPanel
$form.Controls.Add($sep)

$listBox = New-Object Windows.Forms.ListBox
$listBox.Location       = [Drawing.Point]::new(12, 72)
$listBox.Size           = [Drawing.Size]::new(336, 290)
$listBox.BackColor      = $clrPanel
$listBox.ForeColor      = $clrText
$listBox.Font           = [Drawing.Font]::new('Segoe UI', 10)
$listBox.BorderStyle    = 'None'
$listBox.DrawMode       = [Windows.Forms.DrawMode]::OwnerDrawFixed
$listBox.ItemHeight     = 46
$listBox.IntegralHeight = $false

foreach ($acc in $accounts) { $listBox.Items.Add($acc) | Out-Null }

for ($i = 0; $i -lt $accounts.Count; $i++) {
    if ($accounts[$i].AccountName -eq $currentUser) { $listBox.SelectedIndex = $i; break }
}

$listBox.Add_DrawItem({
    param($s, $e)
    $acc        = $listBox.Items[$e.Index]
    $isSelected = ($e.State -band [Windows.Forms.DrawItemState]::Selected) -ne 0
    $isCurrent  = $acc.AccountName -eq $currentUser

    $bg = if ($isSelected) { $clrSel } else { $clrPanel }
    $e.Graphics.FillRectangle([Drawing.SolidBrush]::new($bg), $e.Bounds)

    if ($isCurrent) {
        $bar = [Drawing.Rectangle]::new($e.Bounds.X, $e.Bounds.Y, 4, $e.Bounds.Height)
        $e.Graphics.FillRectangle([Drawing.SolidBrush]::new($clrAccent), $bar)
    }

    $fBold   = [Drawing.Font]::new('Segoe UI', 10, [Drawing.FontStyle]::Bold)
    $fNormal = [Drawing.Font]::new('Segoe UI', [float]8.5)
    $nameCol = if ($isCurrent) { $clrAccent } else { $clrText }
    $persona = if ($acc.PersonaName) { $acc.PersonaName } else { $acc.AccountName }
    $pt1     = [Drawing.PointF]::new($e.Bounds.X + 14, $e.Bounds.Y + 6)
    $pt2     = [Drawing.PointF]::new($e.Bounds.X + 14, $e.Bounds.Y + 26)

    $e.Graphics.DrawString($persona,           $fBold,   [Drawing.SolidBrush]::new($nameCol), $pt1)
    $e.Graphics.DrawString($acc.AccountName,   $fNormal, [Drawing.SolidBrush]::new($clrSub),  $pt2)
    $fBold.Dispose(); $fNormal.Dispose()
})

$form.Controls.Add($listBox)

$btn = New-Object Windows.Forms.Button
$btn.Text      = 'Konto wechseln'
$btn.Location  = [Drawing.Point]::new(12, 374)
$btn.Size      = [Drawing.Size]::new(336, 40)
$btn.BackColor = $clrAccent
$btn.ForeColor = $clrBg
$btn.Font      = [Drawing.Font]::new('Segoe UI', 10, [Drawing.FontStyle]::Bold)
$btn.FlatStyle = 'Flat'
$btn.FlatAppearance.BorderSize = 0
$btn.Cursor    = [Windows.Forms.Cursors]::Hand
$btn.Add_Click({
    $idx = $listBox.SelectedIndex
    if ($idx -ge 0) {
        Switch-SteamAccount $accounts[$idx].AccountName
        $form.Close()
    }
})
$form.Controls.Add($btn)

$listBox.Add_DoubleClick({ $btn.PerformClick() })
$form.KeyPreview = $true
$form.Add_KeyDown({
    if ($_.KeyCode -eq 'Return') { $btn.PerformClick() }
    if ($_.KeyCode -eq 'Escape') { $form.Close() }
})

[void]$form.ShowDialog()
