@echo off
rem Oppnar fonstret for att importera filamentprofiler till Bambu Studio.
start "" powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0bambu_filament_gui.ps1"
