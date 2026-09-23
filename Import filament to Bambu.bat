@echo off
rem Drop one or more filament JSON files (Bambu format, e.g. from addnorth) on this file.
rem Bambu Studio must be closed.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bambu_filament_import.ps1" %*
echo.
pause
