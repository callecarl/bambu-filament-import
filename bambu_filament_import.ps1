<#
.SYNOPSIS
  Importerar tillverkar-filamentprofiler (Bambu-JSON, t.ex. från Addnorth) till Bambu Studio
  som riktiga "custom filaments" – dvs. så att de dyker upp i AMS-dropdownen.

.DESCRIPTION
  Bambu Studio visar bara filament i AMS-listan om de skapats via "Create New Filament".
  Det som skiljer ett sådant preset från en importerad fil är:
    * filament_id  = "P" + md5("<vendor> <typ> <serie>@<user-id>")[0..6]   (räknas lokalt av Studio)
    * name         = "<vendor> <typ> <serie> @<skrivare>"
    * compatible_printers = bara den skrivaren
    * .info med tomt setting_id  -> molnsynken laddar upp presetet vid nästa start
  Det här scriptet gör exakt det, plus normaliserar dubbla H2D-värden ("260","260") till ett
  värde och fyller tomma tork-/overhang-fält från Studios Generic-profil för samma typ.

.USAGE
  Dra en eller flera JSON-filer på "Importera filament till Bambu.bat", eller:
    powershell -File bambu_filament_import.ps1 "fil1.json" "fil2.json" [-Printer "Bambu Lab P1S 0.4 nozzle"] [-Force] [-DryRun]

  Bambu Studio MÅSTE vara stängt när scriptet körs (annars skriver Studio över filerna).
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]] $Files,
    [Parameter()] [string] $Printer = 'Bambu Lab P1S 0.4 nozzle',
    [Parameter()] [switch] $Force,      # skriv över befintligt preset med samma namn
    [Parameter()] [switch] $DryRun,     # skriv inte till Studio-mappen, visa bara vad som skulle hända
    [Parameter()] [string] $OutDir      # (för test) skriv hit i stället för till Studio-mappen
)

$ErrorActionPreference = 'Stop'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-Md5Hex([string] $s) {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    ($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes($s)) | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Read-Json([string] $path) {
    [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8) | ConvertFrom-Json
}

function Write-Utf8([string] $path, [string] $text) {
    [IO.File]::WriteAllText($path, $text, $Utf8NoBom)
}

# --- Studio-mappar -----------------------------------------------------------------------
$studioRoot = Join-Path $env:APPDATA 'BambuStudio'
$userDirs = Get-ChildItem (Join-Path $studioRoot 'user') -Directory | Where-Object { $_.Name -match '^\d+$' }
if ($userDirs.Count -ne 1) {
    throw "Hittade $($userDirs.Count) inloggade användarmappar under $studioRoot\user – förväntade exakt en (är du inloggad i Studio?)."
}
$userId     = $userDirs[0].Name
$userBase   = Join-Path $userDirs[0].FullName 'filament\base'
$systemFila = Join-Path $studioRoot 'system\BBL\filament'
$targetDir  = if ($OutDir) { $OutDir } else { $userBase }

if (-not $Files -or $Files.Count -eq 0) {
    Write-Host "Inga filer angivna. Dra JSON-filer på .bat-filen eller ange sökvägar som argument." -ForegroundColor Yellow
    exit 1
}

if (-not $DryRun -and -not $OutDir) {
    if (Get-Process -Name 'bambu-studio' -ErrorAction SilentlyContinue) {
        throw "Bambu Studio körs. Stäng det helt (även i systemfältet) och kör igen."
    }
}

# --- Studios Generic-profil per typ (för att fylla tomma fält) ---------------------------
# Systemprofilerna ärver i flera led (Generic PETG @BBL X1C -> Generic PETG @base -> fdm_filament_petg).
$script:sysCache = @{}
function Resolve-SystemPreset([string] $name) {
    if ($script:sysCache.ContainsKey($name)) { return $script:sysCache[$name] }
    $f = Join-Path $systemFila "$name.json"
    if (-not (Test-Path $f)) { return $null }
    $j = Read-Json $f
    $merged = [ordered]@{}
    if ($j.inherits) {
        $parent = Resolve-SystemPreset $j.inherits
        if ($parent) { foreach ($p in $parent.PSObject.Properties) { $merged[$p.Name] = $p.Value } }
    }
    foreach ($p in $j.PSObject.Properties) { $merged[$p.Name] = $p.Value }
    $obj = [pscustomobject]$merged
    $script:sysCache[$name] = $obj
    return $obj
}

function Get-GenericForType([string] $type) {
    $candidates = Get-ChildItem $systemFila -Filter "Generic $type @*.json" -ErrorAction SilentlyContinue
    foreach ($c in $candidates) {
        $r = Resolve-SystemPreset $c.BaseName
        if ($r -and (@($r.compatible_printers) -contains $Printer)) { return $r }
    }
    # fallback: @base-profilen
    return Resolve-SystemPreset "Generic $type @base"
}

# Fält som tillverkare ofta lämnar tomma/0 men där Studios Generic har vettiga värden.
$fillFromGeneric = @(
    'filament_dev_ams_drying_ams_limitations', 'filament_dev_ams_drying_heat_distortion_temperature',
    'filament_dev_ams_drying_temperature', 'filament_dev_ams_drying_time',
    'filament_dev_chamber_drying_bed_temperature', 'filament_dev_chamber_drying_time',
    'filament_dev_drying_cooling_temperature', 'filament_dev_drying_softening_temperature',
    'filament_overhang_2_4_speed', 'filament_overhang_3_4_speed', 'filament_overhang_4_4_speed',
    'volumetric_speed_coefficients'
)

function Test-Empty($v) {
    $s = (@($v) -join ',').Trim()
    return ($s -eq '' -or $s -eq '0' -or $s -eq 'nil' -or ($s -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '0' -and $_ -ne '' }).Count -eq 0)
}

# Version: ta högsta versionen bland befintliga user-presets så filen matchar Studios egna.
$studioVersion = $null
$existing = Get-ChildItem $userBase -Filter *.json -ErrorAction SilentlyContinue
foreach ($e in $existing) {
    try { $v = [version]((Read-Json $e.FullName).version); if (-not $studioVersion -or $v -gt $studioVersion) { $studioVersion = $v } } catch {}
}

# Befintliga filament-id:n (för kollisionskontroll, som Studio gör)
$existingIds = @{}
foreach ($e in $existing) {
    try { $j = Read-Json $e.FullName; $nm = ($j.name -split ' @')[0]; if ($j.filament_id) { $existingIds[$j.filament_id] = $nm } } catch {}
}

# --- Bearbeta varje fil ------------------------------------------------------------------
$results = @()
foreach ($file in $Files) {
    $file = (Resolve-Path $file).Path
    Write-Host "`n=== $(Split-Path $file -Leaf)" -ForegroundColor Cyan
    $src = Read-Json $file

    $vendor = (@($src.filament_vendor) | Select-Object -First 1)
    $type   = (@($src.filament_type)   | Select-Object -First 1)
    if (-not $vendor -or -not $type) { Write-Host "  HOPPAR ÖVER: saknar filament_vendor/filament_type" -ForegroundColor Red; continue }

    # Serienamn = namnet minus tillverkare och typ i början ("addnorth PETG Base" -> "Base")
    $serial = ($src.name -split ' @')[0].Trim()
    if ($serial.StartsWith($vendor, 'InvariantCultureIgnoreCase')) { $serial = $serial.Substring($vendor.Length).Trim() }
    if ($serial.StartsWith($type,   'InvariantCultureIgnoreCase')) { $serial = $serial.Substring($type.Length).Trim() }
    $serial = $serial -replace '^[\-_: ]+', ''
    if (-not $serial) { $serial = ($src.name -split ' @')[0].Trim() }

    $typeForName  = if ($type -eq 'PLA-AERO') { 'PLA Aero' } else { $type }
    $filamentName = "$vendor $typeForName $serial"                 # "addnorth PETG Base"
    $presetName   = "$filamentName @$Printer"                       # "addnorth PETG Base @Bambu Lab P1S 0.4 nozzle"
    $filamentId   = 'P' + (Get-Md5Hex "$filamentName@$userId").Substring(0, 7)

    if ($existingIds.ContainsKey($filamentId) -and $existingIds[$filamentId] -ne $filamentName) {
        Write-Host "  HOPPAR ÖVER: filament_id $filamentId används redan av '$($existingIds[$filamentId])'" -ForegroundColor Red; continue
    }

    $outJson = Join-Path $targetDir "$presetName.json"
    $outInfo = Join-Path $targetDir "$presetName.info"
    if ((Test-Path $outJson) -and -not $Force) {
        Write-Host "  HOPPAR ÖVER: '$presetName' finns redan (använd -Force för att skriva över)" -ForegroundColor Yellow; continue
    }

    # Bygg preset-objektet från källfilen
    $out = [ordered]@{}
    $notes = @()
    foreach ($p in $src.PSObject.Properties) {
        $v = $p.Value
        # H2D-format: två värden per fält -> ett (P1S har ett munstycke).
        # Tork-fälten (filament_dev_ams_drying_*) är per AMS-typ, inte per munstycke – rör ej.
        if ($v -is [array] -and $v.Count -eq 2 -and $p.Name -notlike 'filament_dev_ams_drying*') {
            if ($v[0] -ne $v[1]) { $notes += "$($p.Name): olika värden ($($v[0]) / $($v[1])) – tog första" }
            $v = @($v[0])
        }
        $out[$p.Name] = $v
    }

    # Identitet – exakt som Studios "Create New Filament"
    $out['name']                 = $presetName
    $out['filament_settings_id'] = @($presetName)
    $out['filament_id']          = $filamentId
    $out['filament_vendor']      = @($vendor)
    $out['filament_type']        = @($type)
    $out['compatible_printers']  = @($Printer)
    $out['from']                 = 'User'
    $out['inherits']             = ''
    if ($studioVersion) { $out['version'] = $studioVersion.ToString() }
    foreach ($k in 'instantiation','is_custom_defined','type','base_id','setting_id') { if ($out.Contains($k)) { $out.Remove($k) } }

    # Komplettera från Studios Generic <typ> – samma bas som "Create New Filament" utgår från:
    #  * nycklar som tillverkarfilen saknar helt läggs till med Generic-värdet
    #  * tork-/overhang-fält som tillverkaren lämnat tomma/0 ersätts med Generic-värdet
    $generic = Get-GenericForType $type
    $filled = @(); $added = @()
    $identityKeys = 'name','filament_settings_id','filament_id','filament_vendor','filament_type','compatible_printers','from','inherits','version','instantiation','is_custom_defined','type','base_id','setting_id','filament_start_gcode','filament_end_gcode','filament_notes'
    if ($generic) {
        foreach ($gp in $generic.PSObject.Properties) {
            if ($identityKeys -contains $gp.Name) { continue }
            if (-not $out.Contains($gp.Name)) {
                $out[$gp.Name] = $gp.Value; $added += $gp.Name   # systemprofilen är redan per skrivare
            }
        }
        foreach ($k in $fillFromGeneric) {
            if ($out.Contains($k) -and (Test-Empty $out[$k]) -and $generic.PSObject.Properties[$k] -and -not (Test-Empty $generic.$k)) {
                $out[$k] = $generic.$k; $filled += $k
            }
        }
    } else { $notes += "hittade ingen Generic $type-profil – saknade fält får Studios standardvärden" }

    $now  = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $info = "sync_info = create`nuser_id = $userId`nsetting_id = `nbase_id = `nupdated_time = $now`n"
    $json = [pscustomobject]$out | ConvertTo-Json -Depth 6

    Write-Host "  namn:        $presetName"
    Write-Host "  filament_id: $filamentId"
    Write-Host "  temp/bädd/flöde: $($out['nozzle_temperature'] -join ',') / $($out['hot_plate_temp'] -join ',') / $($out['filament_flow_ratio'] -join ',')"
    if ($added)  { Write-Host "  $($added.Count) saknade fält tillagda från Generic $type" -ForegroundColor DarkGray }
    if ($filled) { Write-Host "  fyllda från Generic ${type}: $($filled -join ', ')" -ForegroundColor DarkGray }
    foreach ($n in $notes) { Write-Host "  obs: $n" -ForegroundColor Yellow }

    if ($DryRun) { Write-Host "  (dry run – inget skrivet)" -ForegroundColor DarkGray; continue }

    if (Test-Path $outJson) {
        $bak = Join-Path (Split-Path $targetDir) ("_backup_import_" + (Get-Date -Format 'yyyyMMdd_HHmm'))
        New-Item -ItemType Directory -Force $bak | Out-Null
        Copy-Item $outJson, $outInfo $bak -ErrorAction SilentlyContinue
        Write-Host "  befintligt preset säkerhetskopierat till $bak" -ForegroundColor DarkGray
    }
    New-Item -ItemType Directory -Force $targetDir | Out-Null
    Write-Utf8 $outJson $json
    Write-Utf8 $outInfo $info
    Write-Host "  SKRIVET -> $outJson" -ForegroundColor Green
    $results += $presetName
}

Write-Host ""
if ($results.Count -gt 0) {
    Write-Host "$($results.Count) preset skapade. Starta Bambu Studio: de laddas upp till molnet och syns sedan i AMS-listan under '$((Read-Json $Files[0]).filament_vendor)'." -ForegroundColor Green
} elseif (-not $DryRun) {
    Write-Host "Inget skrevs." -ForegroundColor Yellow
}
