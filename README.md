# Bambu filament import

Make third‑party filament profiles (e.g. the JSON presets that **addnorth** and other
vendors publish for Bambu Studio) show up in the **AMS filament dropdown** – without
clicking through *Create New Filament* for every single profile.

*Svensk sammanfattning längre ner.*

## The problem

Bambu Studio only lists a user filament in the AMS slot dropdown if it was created through
**Prepare → Custom Filaments → Create New**. A vendor JSON that you *import* (or place in
the user preset folder) shows up in the Prepare filament list, but **not** in the AMS list –
even though it is synced to the cloud and has the right printer/nozzle selected.

The difference is the `filament_id`. Studio computes it locally when you create a filament
(see `CreatePresetsDialog.cpp` in the BambuStudio source):

```
filament_id = "P" + md5("<vendor> <type> <serial>@<your user id>")[0..6]
```

Vendor files carry a made‑up id (e.g. `GF_ANXP`) that Studio does not treat as a custom
filament, so the AMS list ignores them.

## What the tool does

`bambu_filament_import.ps1` produces exactly what *Create New Filament* would have produced,
but with the vendor's tuned values instead of a Generic base:

* computes the `filament_id` with the formula above (your user id is read from the
  `%APPDATA%\BambuStudio\user\<id>` folder),
* names the preset `<vendor> <type> <serial> @<printer>` and limits it to that printer,
* collapses dual‑extruder (H2D) value pairs like `["260","260"]` to a single value,
* fills in the ~50 fields most vendor files omit from Studio's own *Generic <type>* profile
  (drying, overhang speeds, …),
* writes the `.json` and a `.info` with an empty `setting_id`, which makes Studio's cloud
  sync upload the preset on next start.

Verified against presets created by Studio 2.8.2 itself: identical `filament_id`, name and
metadata.

## Requirements

* Windows with Windows PowerShell 5.1 (built in) – no extra installs
* Bambu Studio, logged in, with *Auto sync user presets* enabled (custom filaments in the
  AMS require cloud mode)
* **Bambu Studio must be closed while importing** – otherwise it overwrites the files

## Usage

### GUI (recommended)

Run `Bambu filament import.bat`. Drag the vendor JSON files (or a whole folder) into the
window, press **Import to Bambu Studio**, then start Studio. The presets appear under
the vendor's name in the AMS dropdown (e.g. *addnorth → PETG → Base*).

The window and the messages are available in every language in the `lang/` folder – today
**English and Swedish**. Pick the language in the top‑right corner. The first time, the tool
uses your Windows language when it is available, otherwise English, and then remembers your
choice.

To get a desktop shortcut, create one pointing to:

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "<path>\bambu_filament_gui.ps1"
```

### Drag‑and‑drop on a .bat

Drop one or more JSON files onto `Import filament to Bambu.bat`.

### Command line

```powershell
powershell -ExecutionPolicy Bypass -File bambu_filament_import.ps1 "AN BBL PETG Base_....json" "AN BBL PLA X-PLA_....json"
```

Options:

| Flag | Meaning |
|------|---------|
| `-Printer "Bambu Lab X1C 0.4 nozzle"` | Target printer/nozzle. Default: `Bambu Lab P1S 0.4 nozzle`. Use the exact name Studio uses. |
| `-Lang <code>` | Language of the messages: any language in `lang/`, e.g. `en` or `sv`. Default: your Windows language when it is available, otherwise `en`. |
| `-Force` | Overwrite a preset with the same name (a backup is taken first). |
| `-DryRun` | Show what would be created without writing anything. |
| `-OutDir <dir>` | Write to a different folder instead of the Studio user folder (for testing). |

## Adding a language

Each language is one file `lang/<code>.psd1`, where `<code>` is the two‑letter ISO 639‑1
code (e.g. `de`). Both scripts find the languages from these files, so no code changes
are needed:

1. Copy `lang/en.psd1` to `lang/<code>.psd1`.
2. Translate the values, including `LanguageName` (the language's own name, e.g. `Deutsch`).
   Keep the keys and the `{0}`, `{1}` … placeholders as they are. A missing text is shown
   in English.
3. Save the file as UTF‑8 with BOM, so Windows PowerShell 5.1 reads the special characters.
4. Run the check script, which compares every language file with `lang/en.psd1`:

   ```powershell
   powershell -ExecutionPolicy Bypass -File tests\Test-LangFiles.ps1   # Windows
   pwsh -File tests/Test-LangFiles.ps1                                  # Linux/macOS
   ```

## Notes and caveats

* Vendor "process" (print settings) files are not filament profiles and are skipped.
* To **remove** a preset, delete it inside Studio (*Custom Filaments → trash icon*).
  Deleting the files on disk is not enough – cloud sync may restore them.
* Bambu's cloud stores at most 200 user presets.
* A vendor that types a material unusually (addnorth's PVDF is typed as `PA`) gets that
  type in the name: *addnorth PA PVDF Adamant S1*. Harmless, but looks odd.
* Tested with Bambu Studio 2.8.2 on Windows 11 and addnorth's preset pack (May 2026).
  The id formula is read from the BambuStudio source; if Bambu changes it, this breaks.

## Svensk sammanfattning

Bambu Studio visar bara egna filament i AMS‑listan om de skapats via *Create New Filament*.
Importerade tillverkarprofiler (t.ex. från addnorth) hamnar i Prepare‑listan men inte i
AMS:en, eftersom de saknar rätt `filament_id`. Det här verktyget räknar fram ID:t på samma
sätt som Studio och skriver presetet direkt till Studios användarmapp.

1. Stäng Bambu Studio.
2. Starta `Bambu filament import.bat`, välj *Svenska* uppe till höger, dra in JSON‑filerna,
   tryck **Importera**.
3. Starta Studio – filamenten ligger nu under tillverkarens namn i AMS‑dropdownen.

Ta bort presets inifrån Studio, inte genom att radera filer. Standardskrivare är P1S 0.4;
ange `-Printer` för andra.

## License

MIT – see [LICENSE](LICENSE).
