<#
  Gemensam språkladdare för bambu_filament_import.ps1 och bambu_filament_gui.ps1 (dot-sourcas).
  Varje språk är en fil lang/<kod>.psd1; lang/en.psd1 är referensen och reserven för saknade texter.
  / Shared language loader for bambu_filament_import.ps1 and bambu_filament_gui.ps1 (dot-sourced).
  Each language is one file lang/<code>.psd1; lang/en.psd1 is the reference and the fallback for missing texts.
#>

$script:LangDir  = Join-Path $PSScriptRoot 'lang'
$script:LangText = @{}

# Tillgängliga språk: kod -> LanguageName, sorterat på namnet / available languages: code -> LanguageName, sorted by name
function Get-Languages {
    $found = foreach ($f in Get-ChildItem $script:LangDir -Filter '*.psd1' -ErrorAction SilentlyContinue) {
        try { $data = Import-PowerShellDataFile $f.FullName }
        catch { Write-Warning "$($f.Name): $($_.Exception.Message)"; continue }
        $name = if ($data['LanguageName']) { [string] $data['LanguageName'] } else { $f.BaseName.ToLowerInvariant() }
        [pscustomobject]@{ Code = $f.BaseName.ToLowerInvariant(); Name = $name }
    }
    $langs = [ordered]@{}
    foreach ($l in @($found | Sort-Object Name)) { $langs[$l.Code] = $l.Name }
    return $langs
}

# Begärt språk om det finns, annars Windows-språket om det finns, annars engelska
# / requested language if available, otherwise the Windows language if available, otherwise English
function Resolve-Language([string] $requested) {
    $langs = Get-Languages
    if ($requested -and $langs.Contains($requested.Trim().ToLowerInvariant())) { return $requested.Trim().ToLowerInvariant() }
    $windows = (Get-Culture).TwoLetterISOLanguageName.ToLowerInvariant()
    if ($langs.Contains($windows)) { return $windows }
    return 'en'
}

# Laddar en sektion (Cli/Gui) med engelska som bas, så saknade nycklar visas på engelska
# / loads one section (Cli/Gui) on top of English, so missing keys are shown in English
function Use-Language([string] $code, [string] $section) {
    $merged = @{}
    $en = Import-PowerShellDataFile (Join-Path $script:LangDir 'en.psd1')
    if ($en[$section]) { foreach ($k in $en[$section].Keys) { $merged[$k] = $en[$section][$k] } }
    $file = Join-Path $script:LangDir "$($code.ToLowerInvariant()).psd1"
    if ($code -and $code -ne 'en' -and (Test-Path $file)) {
        $sel = Import-PowerShellDataFile $file
        if ($sel[$section] -is [hashtable]) { foreach ($k in $sel[$section].Keys) { $merged[$k] = $sel[$section][$k] } }
    }
    $script:LangText = $merged
}

function T([string] $key, [object[]] $fmt = @()) { $s = $script:LangText[$key]; if ($fmt.Count) { $s -f $fmt } else { $s } }
