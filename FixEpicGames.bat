@echo off
taskkill /f /im EpicGamesLauncher.exe
timeout /t 5 /nobreak >nul
start "" "C:\Program Files\Epic Games\Launcher\Portal\Binaries\Win32\EpicGamesLauncher.exe"
