# Deutsche Texte / German texts.
# Nycklar och {n}-platshållare som i en.psd1 / keys and {n} placeholders as in en.psd1.
@{
    LanguageName = 'Deutsch'

    # bambu_filament_import.ps1
    Cli = @{
        NoFiles       = 'Keine Dateien angegeben. Ziehen Sie JSON-Dateien auf die .bat-Datei oder geben Sie Pfade als Argumente an.'
        StudioRunning = 'Bambu Studio läuft. Beenden Sie es vollständig (auch im Infobereich der Taskleiste) und starten Sie den Import erneut.'
        UserDirs      = '{0} Benutzerordner unter {1} gefunden – genau einer erwartet (sind Sie in Studio angemeldet?).'
        SkipNoVendor  = 'ÜBERSPRUNGEN: filament_vendor/filament_type fehlt'
        SkipIdUsed    = "ÜBERSPRUNGEN: filament_id {0} wird bereits von '{1}' verwendet"
        Exists        = "EXISTIERT BEREITS: '{0}' (mit -Force überschreiben)"
        DiffValues    = '{0}: unterschiedliche Werte ({1} / {2}) – der erste wurde übernommen'
        NoGeneric     = 'kein Profil Generic {0} gefunden – fehlende Felder erhalten die Standardwerte von Studio'
        Name          = 'Name:       '
        Id            = 'filament_id:'
        TempBed       = 'Temp./Druckbett/Flussverhältnis:'
        Added         = '{0} fehlende Felder aus Generic {1} ergänzt'
        Filled        = 'aus Generic {0} ergänzt: {1}'
        Note          = 'Hinweis:'
        DryRun        = '(Probelauf – nichts geschrieben)'
        Backup        = 'vorhandenes Profil gesichert unter {0}'
        Written       = 'GESCHRIEBEN -> {0}'
        Done          = "{0} Profil(e) erstellt. Starten Sie Bambu Studio: Die Profile werden in die Cloud hochgeladen und erscheinen dann in der AMS-Filamentliste unter '{1}'."
        Nothing       = 'Nichts geschrieben.'
        UnknownLang   = "Unknown language '{0}'. Available: {1}"
    }

    # bambu_filament_gui.ps1
    Gui = @{
        Title        = 'Bambu Filament-Import'
        Top          = 'Ziehen Sie Filament-JSON-Dateien hierher (z. B. von addnorth) oder nutzen Sie die Schaltfläche. Drucker: {0}'
        ColFile      = 'Datei'
        ColPreset    = 'Wird zum Profil'
        ColTemp      = 'Temp. / Bett'
        ColStatus    = 'Status'
        DropHint     = 'Dateien hier ablegen'
        BtnAdd       = 'Hinzufügen…'
        BtnClear     = 'Liste leeren'
        ChkForce     = 'Vorhandene Profile überschreiben'
        BtnImport    = 'In Bambu Studio importieren'
        BtnStudio    = 'Bambu Studio starten'
        Language     = 'Sprache:'
        Ready        = 'Bereit. Bambu Studio muss während des Imports geschlossen sein.'
        NoScript     = "bambu_filament_import.ps1 nicht gefunden in`n{0}"
        NotProfile   = 'Hersteller/Typ fehlt – kein Filamentprofil'
        Unreadable   = 'nicht lesbar: {0}'
        StWaiting    = 'wartet'
        StError      = 'Fehler'
        StDone       = 'fertig'
        StExists     = 'vorhanden'
        StSkipped    = 'übersprungen'
        StudioRuns   = "Bambu Studio läuft.`n`nBeenden Sie es vollständig (auch im Infobereich der Taskleiste) und klicken Sie erneut auf ‚In Bambu Studio importieren‘."
        Importing    = '----- Importiere {0} Datei(en) -----'
        Failed       = 'FEHLER: {0}'
        Created      = '{0} Profil(e) erstellt. Starten Sie Bambu Studio, dann werden sie hochgeladen und erscheinen in der AMS-Filamentliste.'
        DlgTitle     = 'Filamentprofile auswählen'
        DlgFilter    = 'Filamentprofil (*.json)|*.json'
    }
}
