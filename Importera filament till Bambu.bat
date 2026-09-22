@echo off
rem Dra en eller flera filament-JSON (Bambu-format, t.ex. fran Addnorth) pa den har filen.
rem Bambu Studio maste vara stangt.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bambu_filament_import.ps1" %*
echo.
pause
