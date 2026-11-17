# Svenska texter / Swedish texts.
# Nycklar och {n}-platshållare som i en.psd1 / keys and {n} placeholders as in en.psd1.
@{
    LanguageName = 'Svenska'

    # bambu_filament_import.ps1
    Cli = @{
        NoFiles       = 'Inga filer angivna. Dra JSON-filer på .bat-filen eller ange sökvägar som argument.'
        StudioRunning = 'Bambu Studio körs. Stäng det helt (även i systemfältet) och kör igen.'
        UserDirs      = 'Hittade {0} inloggade användarmappar under {1} – förväntade exakt en (är du inloggad i Studio?).'
        SkipNoVendor  = 'HOPPAR ÖVER: saknar filament_vendor/filament_type'
        SkipIdUsed    = "HOPPAR ÖVER: filament_id {0} används redan av '{1}'"
        Exists        = "FINNS REDAN: '{0}' (använd -Force för att skriva över)"
        DiffValues    = '{0}: olika värden ({1} / {2}) – tog första'
        NoGeneric     = 'hittade ingen Generic {0}-profil – saknade fält får Studios standardvärden'
        Name          = 'namn:       '
        Id            = 'filament_id:'
        TempBed       = 'temp/bädd/flöde:'
        Added         = '{0} saknade fält tillagda från Generic {1}'
        Filled        = 'fyllda från Generic {0}: {1}'
        Note          = 'obs:'
        DryRun        = '(dry run – inget skrivet)'
        Backup        = 'befintligt preset säkerhetskopierat till {0}'
        Written       = 'SKRIVET -> {0}'
        Done          = "{0} preset skapade. Starta Bambu Studio: de laddas upp till molnet och syns sedan i AMS-listan under '{1}'."
        Nothing       = 'Inget skrevs.'
        UnknownLang   = "Unknown language '{0}'. Available: {1}"
    }

    # bambu_filament_gui.ps1
    Gui = @{
        Title        = 'Bambu filamentimport'
        Top          = 'Dra filament-JSON hit (t.ex. från Addnorth) eller använd knappen. Skrivare: {0}'
        ColFile      = 'Fil'
        ColPreset    = 'Blir preset'
        ColTemp      = 'Temp / bädd'
        ColStatus    = 'Status'
        DropHint     = 'Släpp filer här'
        BtnAdd       = 'Lägg till filer…'
        BtnClear     = 'Rensa listan'
        ChkForce     = 'Skriv över presets som redan finns'
        BtnImport    = 'Importera till Bambu Studio'
        BtnStudio    = 'Starta Bambu Studio'
        Language     = 'Språk:'
        Ready        = 'Klar. Bambu Studio måste vara stängt när du importerar.'
        NoScript     = "Hittar inte bambu_filament_import.ps1 i`n{0}"
        NotProfile   = 'saknar tillverkare/typ – inte en filamentprofil'
        Unreadable   = 'kan inte läsas: {0}'
        StWaiting    = 'väntar'
        StError      = 'fel'
        StDone       = 'klar'
        StExists     = 'finns'
        StSkipped    = 'hoppad'
        StudioRuns   = "Bambu Studio körs.`n`nStäng det helt (även i systemfältet) och tryck Importera igen."
        Importing    = '----- Importerar {0} fil(er) -----'
        Failed       = 'FEL: {0}'
        Created      = '{0} preset skapade. Starta Bambu Studio så laddas de upp och syns i AMS-listan.'
        DlgTitle     = 'Välj filamentprofiler'
        DlgFilter    = 'Filamentprofil (*.json)|*.json'
    }
}
