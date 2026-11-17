# Engelska texter – referensfilen för alla språk / English texts – the reference file for all languages.
# Nycklar och {n}-platshållare måste finnas i alla språkfiler / keys and {n} placeholders must exist in every language file.
@{
    LanguageName = 'English'

    # bambu_filament_import.ps1
    Cli = @{
        NoFiles       = 'No files given. Drop JSON files on the .bat file or pass paths as arguments.'
        StudioRunning = 'Bambu Studio is running. Close it completely (also in the system tray) and run again.'
        UserDirs      = 'Found {0} user folders under {1} – expected exactly one (are you logged in to Studio?).'
        SkipNoVendor  = 'SKIPPED: missing filament_vendor/filament_type'
        SkipIdUsed    = "SKIPPED: filament_id {0} is already used by '{1}'"
        Exists        = "ALREADY EXISTS: '{0}' (use -Force to overwrite)"
        DiffValues    = '{0}: differing values ({1} / {2}) – took the first'
        NoGeneric     = 'no Generic {0} profile found – missing fields get Studio defaults'
        Name          = 'name:       '
        Id            = 'filament_id:'
        TempBed       = 'temp/bed/flow:'
        Added         = '{0} missing fields added from Generic {1}'
        Filled        = 'filled from Generic {0}: {1}'
        Note          = 'note:'
        DryRun        = '(dry run – nothing written)'
        Backup        = 'existing preset backed up to {0}'
        Written       = 'WRITTEN -> {0}'
        Done          = "{0} preset(s) created. Start Bambu Studio: they are uploaded to the cloud and then appear in the AMS list under '{1}'."
        Nothing       = 'Nothing written.'
        UnknownLang   = "Unknown language '{0}'. Available: {1}"
    }

    # bambu_filament_gui.ps1
    Gui = @{
        Title        = 'Bambu filament import'
        Top          = 'Drop filament JSON files here (e.g. from addnorth) or use the button. Printer: {0}'
        ColFile      = 'File'
        ColPreset    = 'Becomes preset'
        ColTemp      = 'Temp / bed'
        ColStatus    = 'Status'
        DropHint     = 'Drop files here'
        BtnAdd       = 'Add files…'
        BtnClear     = 'Clear list'
        ChkForce     = 'Overwrite presets that already exist'
        BtnImport    = 'Import to Bambu Studio'
        BtnStudio    = 'Start Bambu Studio'
        Language     = 'Language:'
        Ready        = 'Ready. Bambu Studio must be closed while importing.'
        NoScript     = "Cannot find bambu_filament_import.ps1 in`n{0}"
        NotProfile   = 'missing vendor/type – not a filament profile'
        Unreadable   = 'cannot be read: {0}'
        StWaiting    = 'waiting'
        StError      = 'error'
        StDone       = 'done'
        StExists     = 'exists'
        StSkipped    = 'skipped'
        StudioRuns   = "Bambu Studio is running.`n`nClose it completely (also in the system tray) and press Import again."
        Importing    = '----- Importing {0} file(s) -----'
        Failed       = 'ERROR: {0}'
        Created      = '{0} preset(s) created. Start Bambu Studio and they are uploaded and appear in the AMS list.'
        DlgTitle     = 'Select filament profiles'
        DlgFilter    = 'Filament profile (*.json)|*.json'
    }
}
