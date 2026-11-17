<#
  Gemensam språkladdare för bambu_filament_import.ps1 och bambu_filament_gui.ps1 (dot-sourcas).
  Varje språk är en fil lang/<kod>.psd1; lang/en.psd1 är referensen och reserven för saknade texter.
  / Shared language loader for bambu_filament_import.ps1 and bambu_filament_gui.ps1 (dot-sourced).
  Each language is one file lang/<code>.psd1; lang/en.psd1 is the reference and the fallback for missing texts.
#>

$script:LangDir   = Join-Path $PSScriptRoot 'lang'
$script:LangText  = @{}
$script:LangFiles = $null   # kod -> innehåll, läses en gång / code -> contents, read once

# Läser alla lang/*.psd1 en gång; en trasig fil hoppas över med en varning
# / reads every lang/*.psd1 once; a broken file is skipped with a warning
function Get-LanguageFiles {
    if ($null -eq $script:LangFiles) {
        $script:LangFiles = @{}
        foreach ($f in Get-ChildItem $script:LangDir -Filter '*.psd1' -ErrorAction SilentlyContinue) {
            try { $script:LangFiles[$f.BaseName.ToLowerInvariant()] = Import-PowerShellDataFile $f.FullName }
            catch { Write-Warning "$($f.Name): $($_.Exception.Message)" }
        }
    }
    return $script:LangFiles
}

# Tillgängliga språk: kod -> LanguageName, sorterat på namnet / available languages: code -> LanguageName, sorted by name
function Get-Languages {
    $files = Get-LanguageFiles
    $langs = [ordered]@{}
    foreach ($code in @($files.Keys | Sort-Object { [string] $files[$_]['LanguageName'] })) { $langs[$code] = [string] $files[$code]['LanguageName'] }
    return $langs
}

# Begärt språk om det finns, annars Windows-språket om det finns, annars engelska
# / requested language if available, otherwise the Windows language if available, otherwise English
function Resolve-Language([string] $requested) {
    $files = Get-LanguageFiles
    if ($requested -and $files.ContainsKey($requested.Trim().ToLowerInvariant())) { return $requested.Trim().ToLowerInvariant() }
    $windows = (Get-Culture).TwoLetterISOLanguageName.ToLowerInvariant()
    if ($files.ContainsKey($windows)) { return $windows }
    return 'en'
}

# Laddar en sektion (Cli/Gui) med engelska som bas, så saknade nycklar visas på engelska
# / loads one section (Cli/Gui) on top of English, so missing keys are shown in English
function Use-Language([string] $code, [string] $section) {
    $files  = Get-LanguageFiles
    $merged = @{}
    foreach ($c in @('en', $(if ($code) { $code.ToLowerInvariant() }))) {
        if ($c -and $files.ContainsKey($c) -and $files[$c][$section] -is [hashtable]) {
            foreach ($k in $files[$c][$section].Keys) { $merged[$k] = $files[$c][$section][$k] }
        }
    }
    $script:LangText = $merged
}

function T([string] $key, [object[]] $fmt = @()) { $s = $script:LangText[$key]; if ($fmt.Count) { $s -f $fmt } else { $s } }
