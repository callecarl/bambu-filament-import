@echo off
rem Opens the window for importing filament profiles into Bambu Studio.
start "" powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0bambu_filament_gui.ps1"
