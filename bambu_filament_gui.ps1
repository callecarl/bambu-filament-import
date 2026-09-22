<#
  Grafiskt fönster för bambu_filament_import.ps1.
  Dra filament-JSON (Bambu-format, t.ex. från Addnorth) till fönstret, tryck "Importera".
  Startas via "Bambu filamentimport.bat" (eller genvägen på skrivbordet).
#>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$scriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$importScript = Join-Path $scriptDir 'bambu_filament_import.ps1'
if (-not (Test-Path $importScript)) {
    [System.Windows.Forms.MessageBox]::Show("Hittar inte bambu_filament_import.ps1 i`n$scriptDir", 'Bambu filamentimport', 'OK', 'Error') | Out-Null
    exit 1
}
$printer = 'Bambu Lab P1S 0.4 nozzle'
$studioExe = @("$env:ProgramFiles\Bambu Studio\bambu-studio.exe", "${env:ProgramFiles(x86)}\Bambu Studio\bambu-studio.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1

# --- Förhandsvisning: samma namnlogik som importscriptet ---------------------------------
function Get-PresetPreview([string] $path) {
    try {
        $j = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8) | ConvertFrom-Json
        $vendor = @($j.filament_vendor) | Select-Object -First 1
        $type   = @($j.filament_type)   | Select-Object -First 1
        if (-not $vendor -or -not $type) { return [pscustomobject]@{ Ok = $false; Text = 'saknar tillverkare/typ – inte en filamentprofil' } }
        $serial = ($j.name -split ' @')[0].Trim()
        if ($serial.StartsWith($vendor, 'InvariantCultureIgnoreCase')) { $serial = $serial.Substring($vendor.Length).Trim() }
        if ($serial.StartsWith($type,   'InvariantCultureIgnoreCase')) { $serial = $serial.Substring($type.Length).Trim() }
        $serial = $serial -replace '^[\-_: ]+', ''
        if (-not $serial) { $serial = ($j.name -split ' @')[0].Trim() }
        $typeForName = if ($type -eq 'PLA-AERO') { 'PLA Aero' } else { $type }
        return [pscustomobject]@{ Ok = $true; Text = "$vendor $typeForName $serial"; Temp = (@($j.nozzle_temperature) | Select-Object -First 1); Bed = (@($j.hot_plate_temp) | Select-Object -First 1) }
    } catch { return [pscustomobject]@{ Ok = $false; Text = "kan inte läsas: $($_.Exception.Message)" } }
}

# --- Fönster ------------------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Bambu filamentimport'
$form.Size = New-Object System.Drawing.Size(760, 600)
$form.MinimumSize = New-Object System.Drawing.Size(620, 480)
$form.StartPosition = 'CenterScreen'
$form.AllowDrop = $true
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)

$lblTop = New-Object System.Windows.Forms.Label
$lblTop.Text = "Dra filament-JSON hit (Bambu-format, t.ex. från Addnorth) – eller använd knappen. Skrivare: $printer"
$lblTop.Location = New-Object System.Drawing.Point(12, 12)
$lblTop.AutoSize = $true

$list = New-Object System.Windows.Forms.ListView
$list.View = 'Details'
$list.FullRowSelect = $true
$list.GridLines = $true
$list.AllowDrop = $true
$list.Location = New-Object System.Drawing.Point(12, 40)
$list.Size = New-Object System.Drawing.Size(720, 250)
$list.Anchor = 'Top, Left, Right'
[void]$list.Columns.Add('Fil', 300)
[void]$list.Columns.Add('Blir preset', 260)
[void]$list.Columns.Add('Temp / bädd', 90)
[void]$list.Columns.Add('Status', 60)

$dropHint = New-Object System.Windows.Forms.Label
$dropHint.Text = "Släpp filer här"
$dropHint.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Italic)
$dropHint.ForeColor = [System.Drawing.Color]::Gray
$dropHint.AutoSize = $true
$dropHint.BackColor = [System.Drawing.Color]::Transparent
$list.Controls.Add($dropHint)
$dropHint.Location = New-Object System.Drawing.Point(280, 100)

$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = 'Lägg till filer…'
$btnAdd.Location = New-Object System.Drawing.Point(12, 300)
$btnAdd.Size = New-Object System.Drawing.Size(130, 30)

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = 'Rensa listan'
$btnClear.Location = New-Object System.Drawing.Point(150, 300)
$btnClear.Size = New-Object System.Drawing.Size(110, 30)

$chkForce = New-Object System.Windows.Forms.CheckBox
$chkForce.Text = 'Skriv över presets som redan finns'
$chkForce.Location = New-Object System.Drawing.Point(275, 305)
$chkForce.AutoSize = $true

$btnImport = New-Object System.Windows.Forms.Button
$btnImport.Text = 'Importera till Bambu Studio'
$btnImport.Location = New-Object System.Drawing.Point(522, 296)
$btnImport.Size = New-Object System.Drawing.Size(210, 38)
$btnImport.Anchor = 'Top, Right'
$btnImport.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$btnImport.BackColor = [System.Drawing.Color]::FromArgb(0, 174, 66)   # Bambu-grön
$btnImport.ForeColor = [System.Drawing.Color]::White
$btnImport.FlatStyle = 'Flat'
$btnImport.Enabled = $false

$log = New-Object System.Windows.Forms.TextBox
$log.Multiline = $true
$log.ReadOnly = $true
$log.ScrollBars = 'Vertical'
$log.Font = New-Object System.Drawing.Font('Consolas', 9)
$log.Location = New-Object System.Drawing.Point(12, 345)
$log.Size = New-Object System.Drawing.Size(720, 170)
$log.Anchor = 'Top, Bottom, Left, Right'
$log.Text = "Klar. Bambu Studio måste vara stängt när du importerar.`r`n"

$btnStudio = New-Object System.Windows.Forms.Button
$btnStudio.Text = 'Starta Bambu Studio'
$btnStudio.Location = New-Object System.Drawing.Point(582, 523)
$btnStudio.Size = New-Object System.Drawing.Size(150, 30)
$btnStudio.Anchor = 'Bottom, Right'
$btnStudio.Visible = $false

$form.Controls.AddRange(@($lblTop, $list, $btnAdd, $btnClear, $chkForce, $btnImport, $log, $btnStudio))

# --- Logik --------------------------------------------------------------------------------
function Write-Log([string] $s) { $log.AppendText(($s -replace "`n", "`r`n") + "`r`n") }

function Add-Files([string[]] $paths) {
    foreach ($p in $paths) {
        if (Test-Path $p -PathType Container) { Add-Files ((Get-ChildItem $p -Filter *.json).FullName); continue }
        if ([IO.Path]::GetExtension($p) -ne '.json') { continue }
        if ($list.Items | Where-Object { $_.Tag -eq $p }) { continue }
        $pv = Get-PresetPreview $p
        $item = New-Object System.Windows.Forms.ListViewItem([IO.Path]::GetFileName($p))
        $item.Tag = $p
        [void]$item.SubItems.Add($pv.Text)
        [void]$item.SubItems.Add($(if ($pv.Ok) { "$($pv.Temp) / $($pv.Bed)" } else { '' }))
        [void]$item.SubItems.Add($(if ($pv.Ok) { 'väntar' } else { 'fel' }))
        if (-not $pv.Ok) { $item.ForeColor = [System.Drawing.Color]::Firebrick }
        [void]$list.Items.Add($item)
    }
    $dropHint.Visible = ($list.Items.Count -eq 0)
    $btnImport.Enabled = (($list.Items | Where-Object { $_.SubItems[3].Text -eq 'väntar' }).Count -gt 0)
}

$dragEnter = { param($s, $e) if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) { $e.Effect = 'Copy' } }
$dragDrop  = { param($s, $e) Add-Files ([string[]]$e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)) }
$form.Add_DragEnter($dragEnter); $form.Add_DragDrop($dragDrop)
$list.Add_DragEnter($dragEnter); $list.Add_DragDrop($dragDrop)

$btnAdd.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = 'Filamentprofil (*.json)|*.json'
    $dlg.Multiselect = $true
    $dlg.Title = 'Välj filamentprofiler'
    $dl = Join-Path $env:USERPROFILE 'Downloads'; if (Test-Path $dl) { $dlg.InitialDirectory = $dl }
    if ($dlg.ShowDialog() -eq 'OK') { Add-Files $dlg.FileNames }
})

$btnClear.Add_Click({ $list.Items.Clear(); $dropHint.Visible = $true; $btnImport.Enabled = $false })

$btnStudio.Add_Click({ if ($studioExe) { Start-Process $studioExe }; $btnStudio.Visible = $false })

$btnImport.Add_Click({
    if (Get-Process -Name 'bambu-studio' -ErrorAction SilentlyContinue) {
        [System.Windows.Forms.MessageBox]::Show("Bambu Studio körs.`n`nStäng det helt (även i systemfältet) och tryck Importera igen.", 'Bambu filamentimport', 'OK', 'Warning') | Out-Null
        return
    }
    $files = @($list.Items | Where-Object { $_.SubItems[3].Text -eq 'väntar' } | ForEach-Object { $_.Tag })
    if ($files.Count -eq 0) { return }

    $btnImport.Enabled = $false; $btnAdd.Enabled = $false; $btnClear.Enabled = $false
    $form.Cursor = 'WaitCursor'
    Write-Log "----- Importerar $($files.Count) fil(er) -----"
    [System.Windows.Forms.Application]::DoEvents()

    $created = 0
    try {
        $args = @{ Files = $files }
        if ($chkForce.Checked) { $args.Force = $true }
        $output = & $importScript @args -Printer $printer *>&1 | Out-String
        Write-Log $output.TrimEnd()
        foreach ($item in $list.Items) {
            $name = [IO.Path]::GetFileName($item.Tag)
            $block = ($output -split '=== ') | Where-Object { $_.StartsWith($name) } | Select-Object -First 1
            if (-not $block) { continue }
            if     ($block -match 'SKRIVET')      { $item.SubItems[3].Text = 'klar';      $item.ForeColor = [System.Drawing.Color]::ForestGreen; $created++ }
            elseif ($block -match 'finns redan')  { $item.SubItems[3].Text = 'finns';     $item.ForeColor = [System.Drawing.Color]::DarkOrange }
            elseif ($block -match 'HOPPAR ÖVER')  { $item.SubItems[3].Text = 'hoppad';    $item.ForeColor = [System.Drawing.Color]::Firebrick }
        }
    } catch {
        Write-Log "FEL: $($_.Exception.Message)"
    }

    $form.Cursor = 'Default'
    $btnAdd.Enabled = $true; $btnClear.Enabled = $true
    $btnImport.Enabled = (($list.Items | Where-Object { $_.SubItems[3].Text -eq 'väntar' }).Count -gt 0)
    if ($created -gt 0) {
        Write-Log "$created preset skapade. Starta Bambu Studio så laddas de upp och syns i AMS-listan."
        if ($studioExe) { $btnStudio.Visible = $true }
    }
})

[void]$form.ShowDialog()
