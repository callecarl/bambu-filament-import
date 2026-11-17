<#
.SYNOPSIS
  Kontrollerar språkfilerna i lang/ mot lang/en.psd1.
  / Checks the language files in lang/ against lang/en.psd1.

.DESCRIPTION
  För varje lang/*.psd1: samma nycklar per sektion som en.psd1, samma {n}-platshållare per nyckel,
  ett icke-tomt LanguageName och UTF-8 med BOM. Skriver ut varje problem och avslutar med 1,
  annars 0. Fungerar i Windows PowerShell 5.1 och pwsh.
  / For every lang/*.psd1: the same keys per section as en.psd1, the same {n} placeholders per key,
  a non-empty LanguageName and UTF-8 with BOM. Prints each problem and exits 1, otherwise 0.
  Works in Windows PowerShell 5.1 and pwsh.

.USAGE
  powershell -File tests\Test-LangFiles.ps1      (Windows)
  pwsh -File tests/Test-LangFiles.ps1            (Linux/macOS)
#>
$ErrorActionPreference = 'Stop'

$langDir   = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'lang'
$refFile   = Join-Path $langDir 'en.psd1'
$problems  = New-Object System.Collections.Generic.List[string]

# Platshållarna {0}, {1:N2} … i en text, sorterade och unika / the {0}, {1:N2} … placeholders in a text, sorted and unique
function Get-Placeholders([string] $s) {
    $set = @([regex]::Matches($s, '\{(\d+)(?:[,:][^}]*)?\}') | ForEach-Object { [int] $_.Groups[1].Value } | Sort-Object -Unique)
    return ($set -join ',')
}

function Test-Bom([string] $path) {
    $bytes = [IO.File]::ReadAllBytes($path)
    return ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
}

if (-not (Test-Path $refFile)) {
    Write-Host "Missing reference file: $refFile"
    exit 1
}

$ref = $null
try { $ref = Import-PowerShellDataFile $refFile } catch { Write-Host "en.psd1: cannot be read: $($_.Exception.Message)"; exit 1 }

foreach ($file in Get-ChildItem $langDir -Filter '*.psd1' | Sort-Object Name) {
    $name = $file.Name
    # Filnamnet är koden: två små bokstäver (ISO 639-1) / the file name is the code: two lowercase letters (ISO 639-1)
    if ($file.BaseName -cnotmatch '^[a-z]{2}$') { $problems.Add("${name}: file name must be a two-letter lowercase ISO 639-1 code, e.g. de.psd1") }
    if (-not (Test-Bom $file.FullName)) { $problems.Add("${name}: not saved as UTF-8 with BOM") }

    try { $data = Import-PowerShellDataFile $file.FullName }
    catch { $problems.Add("${name}: cannot be read: $($_.Exception.Message)"); continue }

    if (-not ($data['LanguageName'] -is [string]) -or -not $data['LanguageName'].Trim()) {
        $problems.Add("${name}: LanguageName is missing or empty")
    }

    # Nycklar på översta nivån / top-level keys
    foreach ($k in $ref.Keys) { if (-not $data.ContainsKey($k)) { $problems.Add("${name}: missing key '$k'") } }
    foreach ($k in $data.Keys) { if (-not $ref.ContainsKey($k)) { $problems.Add("${name}: extra key '$k'") } }

    # Sektionerna (Cli, Gui) nyckel för nyckel / the sections (Cli, Gui) key by key
    foreach ($section in ($ref.Keys | Where-Object { $ref[$_] -is [hashtable] } | Sort-Object)) {
        $r = $ref[$section]; $d = $data[$section]
        if ($null -eq $d) { continue }   # redan rapporterad ovan / already reported above
        if (-not ($d -is [hashtable])) { $problems.Add("${name}: $section is not a section (@{ ... })"); continue }
        foreach ($k in ($r.Keys | Sort-Object)) {
            if (-not $d.ContainsKey($k)) { $problems.Add("${name}: $section.${k}: missing key"); continue }
            $pr = Get-Placeholders ([string] $r[$k]); $pd = Get-Placeholders ([string] $d[$k])
            if ($pr -ne $pd) { $problems.Add("${name}: $section.${k}: placeholders {$pd} differ from en.psd1 {$pr}") }
            # Texten måste gå att formatera med -f (t.ex. ingen ensam { eller }) / the text must work with -f (e.g. no stray { or })
            try { [void] ([string] $d[$k] -f @(0..9)) } catch { $problems.Add("${name}: $section.${k}: not a valid format string (stray { or }?)") }
        }
        foreach ($k in ($d.Keys | Sort-Object)) {
            if (-not $r.ContainsKey($k)) { $problems.Add("${name}: $section.${k}: extra key (not in en.psd1)") }
        }
    }
}

if ($problems.Count -gt 0) {
    foreach ($p in $problems) { Write-Host $p }
    Write-Host "$($problems.Count) problem(s) found."
    exit 1
}
Write-Host 'All language files OK.'
exit 0
