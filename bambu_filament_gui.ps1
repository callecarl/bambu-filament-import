<#
  Grafiskt fönster för bambu_filament_import.ps1 / GUI for bambu_filament_import.ps1.
  Dra filament-JSON (Bambu-format, t.ex. från Addnorth) till fönstret, tryck "Importera".
  Språk väljs i fönstret (sparas i %APPDATA%\BambuFilamentImport\lang.txt).
#>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$scriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$importScript = Join-Path $scriptDir 'bambu_filament_import.ps1'
$printer      = 'Bambu Lab P1S 0.4 nozzle'
$studioExe    = @("$env:ProgramFiles\Bambu Studio\bambu-studio.exe", "${env:ProgramFiles(x86)}\Bambu Studio\bambu-studio.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1

# --- Språk / Language ----------------------------------------------------------------------
# Texterna ligger i lang/<kod>.psd1 / the texts live in lang/<code>.psd1
# Utan laddaren eller en.psd1 finns inga texter: visa den saknade sökvägen / without the loader or en.psd1 there are no texts: show the missing path
foreach ($need in @('bambu_filament_lang.ps1', (Join-Path 'lang' 'en.psd1'))) {
    $needPath = Join-Path $scriptDir $need
    if (-not (Test-Path $needPath)) {
        [System.Windows.Forms.MessageBox]::Show($needPath, 'bambu_filament_gui.ps1', 'OK', 'Error') | Out-Null
        exit 1
    }
}
. (Join-Path $scriptDir 'bambu_filament_lang.ps1')
$settingsDir  = Join-Path $env:APPDATA 'BambuFilamentImport'
$langFile     = Join-Path $settingsDir 'lang.txt'
$Lang = $null
if (Test-Path $langFile) { $Lang = (Get-Content $langFile -Raw).Trim() }
$Lang = Resolve-Language $Lang
$languages = Get-Languages
$langCodes = @($languages.Keys)
Use-Language $Lang 'Gui'

if (-not (Test-Path $importScript)) {
    [System.Windows.Forms.MessageBox]::Show((T NoScript @($scriptDir)), (T Title), 'OK', 'Error') | Out-Null
    exit 1
}

# --- Förhandsvisning: samma namnlogik som importscriptet / preview: same naming as the script --
function Get-PresetPreview([string] $path) {
    try {
        $j = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8) | ConvertFrom-Json
        $vendor = @($j.filament_vendor) | Select-Object -First 1
        $type   = @($j.filament_type)   | Select-Object -First 1
        if (-not $vendor -or -not $type) { return [pscustomobject]@{ Ok = $false; Text = (T NotProfile) } }
        $serial = ($j.name -split ' @')[0].Trim()
        if ($serial.StartsWith($vendor, 'InvariantCultureIgnoreCase')) { $serial = $serial.Substring($vendor.Length).Trim() }
        if ($serial.StartsWith($type,   'InvariantCultureIgnoreCase')) { $serial = $serial.Substring($type.Length).Trim() }
        $serial = $serial -replace '^[\-_: ]+', ''
        if (-not $serial) { $serial = ($j.name -split ' @')[0].Trim() }
        $typeForName = if ($type -eq 'PLA-AERO') { 'PLA Aero' } else { $type }
        return [pscustomobject]@{ Ok = $true; Text = "$vendor $typeForName $serial"; Temp = (@($j.nozzle_temperature) | Select-Object -First 1); Bed = (@($j.hot_plate_temp) | Select-Object -First 1) }
    } catch { return [pscustomobject]@{ Ok = $false; Text = (T Unreadable @($_.Exception.Message)) } }
}

# --- Fönster / Window -------------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Size = New-Object System.Drawing.Size(760, 600)
$form.MinimumSize = New-Object System.Drawing.Size(620, 480)
$form.StartPosition = 'CenterScreen'
$form.AllowDrop = $true
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)

$lblTop = New-Object System.Windows.Forms.Label
$lblTop.Location = New-Object System.Drawing.Point(12, 12)
$lblTop.AutoSize = $true
$lblTop.MaximumSize = New-Object System.Drawing.Size(535, 0)   # radbryt före språkväljaren / wrap before the language box

$lblLang = New-Object System.Windows.Forms.Label
$lblLang.AutoSize = $true
$lblLang.Location = New-Object System.Drawing.Point(560, 14)
$lblLang.Anchor = 'Top, Right'

$cmbLang = New-Object System.Windows.Forms.ComboBox
$cmbLang.DropDownStyle = 'DropDownList'
[void]$cmbLang.Items.AddRange([object[]] @($languages.Values))
$cmbLang.SelectedIndex = [array]::IndexOf($langCodes, $Lang)
$cmbLang.Location = New-Object System.Drawing.Point(632, 10)
$cmbLang.Size = New-Object System.Drawing.Size(100, 24)
$cmbLang.Anchor = 'Top, Right'

$list = New-Object System.Windows.Forms.ListView
$list.View = 'Details'
$list.FullRowSelect = $true
$list.GridLines = $true
$list.AllowDrop = $true
$list.Location = New-Object System.Drawing.Point(12, 52)
$list.Size = New-Object System.Drawing.Size(720, 238)
$list.Anchor = 'Top, Left, Right'
[void]$list.Columns.Add('', 300)
[void]$list.Columns.Add('', 260)
[void]$list.Columns.Add('', 90)
[void]$list.Columns.Add('', 60)

$dropHint = New-Object System.Windows.Forms.Label
$dropHint.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Italic)
$dropHint.ForeColor = [System.Drawing.Color]::Gray
$dropHint.AutoSize = $true
$dropHint.BackColor = [System.Drawing.Color]::Transparent
$list.Controls.Add($dropHint)
$dropHint.Location = New-Object System.Drawing.Point(280, 100)

$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Location = New-Object System.Drawing.Point(12, 300)
$btnAdd.Size = New-Object System.Drawing.Size(130, 30)

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Location = New-Object System.Drawing.Point(150, 300)
$btnClear.Size = New-Object System.Drawing.Size(110, 30)

$chkForce = New-Object System.Windows.Forms.CheckBox
$chkForce.Location = New-Object System.Drawing.Point(275, 305)
$chkForce.AutoSize = $true

$btnImport = New-Object System.Windows.Forms.Button
$btnImport.Location = New-Object System.Drawing.Point(522, 296)
$btnImport.Size = New-Object System.Drawing.Size(210, 38)
$btnImport.Anchor = 'Top, Right'
$btnImport.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$btnImport.BackColor = [System.Drawing.Color]::FromArgb(0, 174, 66)   # Bambu-grön / Bambu green
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

$btnStudio = New-Object System.Windows.Forms.Button
$btnStudio.Location = New-Object System.Drawing.Point(582, 523)
$btnStudio.Size = New-Object System.Drawing.Size(150, 30)
$btnStudio.Anchor = 'Bottom, Right'
$btnStudio.Visible = $false

$form.Controls.AddRange(@($lblTop, $lblLang, $cmbLang, $list, $btnAdd, $btnClear, $chkForce, $btnImport, $log, $btnStudio))

# Statusar lagras språkoberoende i Tag-fältet / statuses stored language-independently in Tag
$statusText = @{ waiting = 'StWaiting'; error = 'StError'; done = 'StDone'; exists = 'StExists'; skipped = 'StSkipped' }
function Set-Status($item, [string] $status) { $item.Tag = @{ Path = $item.Tag.Path; Status = $status }; $item.SubItems[3].Text = (T $statusText[$status]) }

function Apply-Language {
    $form.Text         = T Title
    $lblTop.Text       = T Top @($printer)
    $lblLang.Text      = T Language
    $list.Columns[0].Text = T ColFile
    $list.Columns[1].Text = T ColPreset
    $list.Columns[2].Text = T ColTemp
    $list.Columns[3].Text = T ColStatus
    $dropHint.Text     = T DropHint
    $btnAdd.Text       = T BtnAdd
    $btnClear.Text     = T BtnClear
    $chkForce.Text     = T ChkForce
    $btnImport.Text    = T BtnImport
    $btnStudio.Text    = T BtnStudio
    foreach ($item in $list.Items) { $item.SubItems[3].Text = (T $statusText[$item.Tag.Status]) }
    if (-not $script:logUsed) { $log.Text = (T Ready) + "`r`n" }
}
# Tills något loggas visar loggen bara Klar-texten, på valt språk / until something is logged, the log shows only the Ready text, in the chosen language
$logUsed = $false
Apply-Language

$cmbLang.Add_SelectedIndexChanged({
    if ($cmbLang.SelectedIndex -lt 0) { return }
    $script:Lang = $langCodes[$cmbLang.SelectedIndex]
    try { New-Item -ItemType Directory -Force $settingsDir | Out-Null; Set-Content $langFile $script:Lang -NoNewline } catch {}
    Use-Language $script:Lang 'Gui'
    Apply-Language
})

# --- Logik / Logic ---------------------------------------------------------------------------
function Write-Log([string] $s) { $script:logUsed = $true; $log.AppendText(($s -replace "`n", "`r`n") + "`r`n") }

function Add-Files([string[]] $paths) {
    foreach ($p in $paths) {
        if (Test-Path $p -PathType Container) { Add-Files ((Get-ChildItem $p -Filter *.json).FullName); continue }
        if ([IO.Path]::GetExtension($p) -ne '.json') { continue }
        if ($list.Items | Where-Object { $_.Tag.Path -eq $p }) { continue }
        $pv = Get-PresetPreview $p
        $item = New-Object System.Windows.Forms.ListViewItem([IO.Path]::GetFileName($p))
        $item.Tag = @{ Path = $p; Status = 'waiting' }
        [void]$item.SubItems.Add($pv.Text)
        [void]$item.SubItems.Add($(if ($pv.Ok) { "$($pv.Temp) / $($pv.Bed)" } else { '' }))
        [void]$item.SubItems.Add('')
        Set-Status $item $(if ($pv.Ok) { 'waiting' } else { 'error' })
        if (-not $pv.Ok) { $item.ForeColor = [System.Drawing.Color]::Firebrick }
        [void]$list.Items.Add($item)
    }
    $dropHint.Visible = ($list.Items.Count -eq 0)
    $btnImport.Enabled = (($list.Items | Where-Object { $_.Tag.Status -eq 'waiting' }).Count -gt 0)
}

$dragEnter = { param($s, $e) if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) { $e.Effect = 'Copy' } }
$dragDrop  = { param($s, $e) Add-Files ([string[]]$e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)) }
$form.Add_DragEnter($dragEnter); $form.Add_DragDrop($dragDrop)
$list.Add_DragEnter($dragEnter); $list.Add_DragDrop($dragDrop)

$btnAdd.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = T DlgFilter
    $dlg.Multiselect = $true
    $dlg.Title = T DlgTitle
    $dl = Join-Path $env:USERPROFILE 'Downloads'; if (Test-Path $dl) { $dlg.InitialDirectory = $dl }
    if ($dlg.ShowDialog() -eq 'OK') { Add-Files $dlg.FileNames }
})

$btnClear.Add_Click({ $list.Items.Clear(); $dropHint.Visible = $true; $btnImport.Enabled = $false })

$btnStudio.Add_Click({ if ($studioExe) { Start-Process $studioExe }; $btnStudio.Visible = $false })

$btnImport.Add_Click({
    if (Get-Process -Name 'bambu-studio' -ErrorAction SilentlyContinue) {
        [System.Windows.Forms.MessageBox]::Show((T StudioRuns), (T Title), 'OK', 'Warning') | Out-Null
        return
    }
    $files = @($list.Items | Where-Object { $_.Tag.Status -eq 'waiting' } | ForEach-Object { $_.Tag.Path })
    if ($files.Count -eq 0) { return }

    $btnImport.Enabled = $false; $btnAdd.Enabled = $false; $btnClear.Enabled = $false
    $form.Cursor = 'WaitCursor'
    Write-Log (T Importing @($files.Count))
    [System.Windows.Forms.Application]::DoEvents()

    $created = 0
    # Utdata samlas medan scriptet körs, så att det som hann hända finns kvar vid ett fel
    # / output is collected while the script runs, so what already happened is kept on an error
    $output = New-Object System.Collections.ArrayList
    $failed = $null
    try {
        $args = @{ Files = $files; Lang = $Lang; PassThru = $true }
        if ($chkForce.Checked) { $args.Force = $true }
        & $importScript @args -Printer $printer *>&1 | ForEach-Object { [void]$output.Add($_) }
    } catch {
        $failed = $_.Exception.Message
    }

    # Resultatobjekt (har Result) styr statusen, resten går till loggen som förut
    # / result objects (they have Result) set the status, everything else goes to the log as before
    $results = @($output | Where-Object { $_.PSObject.Properties['Result'] })
    $text = ($output | Where-Object { -not $_.PSObject.Properties['Result'] } | Out-String).TrimEnd()
    if ($text) { Write-Log $text }
    foreach ($r in $results) {
        $item = $list.Items | Where-Object { $_.Tag.Path -eq $r.File } | Select-Object -First 1
        if (-not $item) { continue }
        switch ($r.Result) {
            'Written' { Set-Status $item 'done';    $item.ForeColor = [System.Drawing.Color]::ForestGreen; $created++ }
            'Exists'  { Set-Status $item 'exists';  $item.ForeColor = [System.Drawing.Color]::DarkOrange }
            'Skipped' { Set-Status $item 'skipped'; $item.ForeColor = [System.Drawing.Color]::Firebrick }
        }
    }
    if ($failed) { Write-Log (T Failed @($failed)) }

    $form.Cursor = 'Default'
    $btnAdd.Enabled = $true; $btnClear.Enabled = $true
    $btnImport.Enabled = (($list.Items | Where-Object { $_.Tag.Status -eq 'waiting' }).Count -gt 0)
    if ($created -gt 0) {
        Write-Log (T Created @($created))
        if ($studioExe) { $btnStudio.Visible = $true }
    }
})

[void]$form.ShowDialog()
