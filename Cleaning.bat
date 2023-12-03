@echo off
:: Check if the script is run as administrator
NET SESSION >nul 2>&1
if %errorLevel% neq 0 (
    echo You must run this script as an administrator.
    echo Right-click on the script and select "Run as administrator".
    pause
    exit /b
)

setlocal enabledelayedexpansion

set CHANGEOLOGS_DIR=Changelogs
set LOG_FILE=%CHANGEOLOGS_DIR%\DiskCleanupLog.txt

:MainMenu
cls
echo Welcome to Disk Cleanup Script!

REM Prompt the user for the target drive
set /p TARGET_DRIVE=Enter the drive letter (e.g., C:) to clean up: 

REM Validate the drive letter
if not exist "%TARGET_DRIVE%:\" (
    echo Invalid drive letter. Exiting script.
    goto :EndScript
)

REM Confirm with the user before proceeding
set /p CONFIRMATION=Are you sure you want to run Disk Cleanup on drive %TARGET_DRIVE%? (Y/N): 

if /i not "%CONFIRMATION%"=="Y" (
    echo Cleanup canceled by user.
    goto :EndScript
)

REM Create Changelogs directory if it doesn't exist
if not exist "%CHANGEOLOGS_DIR%" mkdir "%CHANGEOLOGS_DIR%"

:CleanupMenu
cls
echo.
echo Disk space information before cleanup on drive %TARGET_DRIVE%:
fsutil volume diskfree %TARGET_DRIVE%

echo.
echo Running Disk Cleanup on drive %TARGET_DRIVE%...
echo Please be patient; this process may take a few moments.

REM Provide options for cleanup
echo.
echo Cleanup Options:
echo 1. Normal Cleanup
echo 2. Extended Cleanup (additional items like Windows Update Cleanup)
echo 3. Choose specific cleanup categories
echo 4. Schedule automatic cleanup
echo 5. View Cleanup Log
echo 6. Empty Recycle Bin
echo 7. Remove Temporary Files
echo 8. Compact OS (Windows 10+)
echo 9. Remove Windows Update Files
echo 10. Remove System Restore Points
echo 11. Optimize Drives
echo 12. Show Cleanup Options (cleanmgr.exe)
echo 13. Disk Cleanup Settings
echo 14. Cleanup with PowerShell (Windows 10+)
echo 15. Uninstall Unused Programs
echo 16. Disable Hibernate
echo 17. Check Disk for Errors
echo 18. System File Checker (SFC)
echo 19. Disk Cleanup Manager (cleanmgr.exe /lowdisk)
echo 20. Exit
echo.

set /p CLEANUP_OPTIONS=Enter your choice (1-20): 

if "%CLEANUP_OPTIONS%"=="20" (
    echo Cleanup completed. Exiting script.
    goto :EndScript
) else if "%CLEANUP_OPTIONS%"=="19" (
    call :RunDiskCleanupManager
) else if "%CLEANUP_OPTIONS%"=="18" (
    call :RunSFC
) else if "%CLEANUP_OPTIONS%"=="17" (
    call :RunCheckDisk
) else if "%CLEANUP_OPTIONS%"=="16" (
    call :DisableHibernate
) else if "%CLEANUP_OPTIONS%"=="15" (
    call :UninstallUnusedPrograms
) else if "%CLEANUP_OPTIONS%"=="14" (
    call :RunPowerShellCleanup
) else if "%CLEANUP_OPTIONS%"=="13" (
    call :ShowCleanupOptions
) else if "%CLEANUP_OPTIONS%"=="12" (
    call :OptimizeDrives
) else if "%CLEANUP_OPTIONS%"=="11" (
    call :RemoveSystemRestorePoints
) else if "%CLEANUP_OPTIONS%"=="10" (
    call :RemoveWindowsUpdateFiles
) else if "%CLEANUP_OPTIONS%"=="9" (
    call :CompactOS
) else if "%CLEANUP_OPTIONS%"=="8" (
    call :RemoveTemporaryFiles
) else if "%CLEANUP_OPTIONS%"=="7" (
    call :EmptyRecycleBin
) else if "%CLEANUP_OPTIONS%"=="6" (
    call :ViewCleanupLog
) else if "%CLEANUP_OPTIONS%"=="5" (
    call :ScheduleAutomaticCleanup
) else if "%CLEANUP_OPTIONS%"=="4" (
    call :ChooseCleanupCategories
) else (
    call :RunDiskCleanup %CLEANUP_OPTIONS%
)

echo.
echo Disk space information after cleanup on drive %TARGET_DRIVE%:
fsutil volume diskfree %TARGET_DRIVE%

REM Display a summary of cleaned items
echo.
echo Cleanup Summary:
call :LogCleanupSummary
type %LOG_FILE%

echo.
set /p CONTINUE_CLEANUP=Do you want to perform another cleanup? (Y/N): 
if /i "%CONTINUE_CLEANUP%"=="Y" (
    goto :CleanupMenu
)

:EndScript
REM Close the console window after completion
set /p CLOSE_CONSOLE=Do you want to close this console window? (Y/N): 
if /i "%CLOSE_CONSOLE%"=="Y" (
    exit
)

endlocal
exit /b

:RunDiskCleanup
REM Run Disk Cleanup with the specified options and target drive
if "%1"=="2" (
    cleanmgr /d %TARGET_DRIVE% /sagerun:1
) else (
    cleanmgr /d %TARGET_DRIVE%
)
call :LogCleanupSummary
exit /b

:ChooseCleanupCategories
REM Allow users to choose specific cleanup categories
cleanmgr /d %TARGET_DRIVE%
call :LogCleanupSummary
exit /b

:ScheduleAutomaticCleanup
REM Schedule automatic cleanup using Task Scheduler
echo.
echo Scheduling automatic cleanup...

schtasks /create /tn "DiskCleanupTask" /tr "cleanmgr.exe /d %TARGET_DRIVE%" /sc weekly /d SUN /st 00:00

if %errorlevel% equ 0 (
    echo Automatic cleanup scheduled successfully.
    echo To modify the schedule, use Task Scheduler.
    echo.
    goto :EndScript
) else (
    echo Error scheduling automatic cleanup. Please try again.
    goto :CleanupMenu
)

:LogCleanupSummary
REM Log the cleanup summary to the file with a timestamp
echo. >> %LOG_FILE%
echo Cleanup Summary for %TARGET_DRIVE% - !DATE! !TIME! >> %LOG_FILE%
cleanmgr /sagerun:1 /d %TARGET_DRIVE% /L:%LOG_FILE%
echo. >> %LOG_FILE%
exit /b

:ViewCleanupLog
REM View the cleanup log
if exist "%LOG_FILE%" (
    echo.
    echo Cleaning Log:
    type %LOG_FILE%
) else (
    echo.
    echo No cleanup log found.
)

echo.
pause
exit /b

:EmptyRecycleBin
REM Empty Recycle Bin
echo.
echo Emptying Recycle Bin on drive %TARGET_DRIVE%...
rd /s /q %TARGET_DRIVE%\$Recycle.bin
call :LogAction "Recycle Bin emptied on drive %TARGET_DRIVE%."
exit /b

:RemoveTemporaryFiles
REM Remove Temporary Files
echo.
echo Removing temporary files on drive %TARGET_DRIVE%...
del /q /f /s %TARGET_DRIVE%\Windows\Temp\*.*
call :LogAction "Temporary files removed on drive %TARGET_DRIVE%."
exit /b

:CompactOS
REM Compact OS (Windows 10+)
echo.
echo Compacting OS on drive %TARGET_DRIVE%...
compact.exe /CompactOS:always
call :LogAction "OS compacted on drive %TARGET_DRIVE%."
exit /b

:RemoveWindowsUpdateFiles
REM Remove Windows Update Files
echo.
echo Removing Windows Update files on drive %TARGET_DRIVE%...
del /q /f /s %TARGET_DRIVE%\Windows\SoftwareDistribution\Download\*.*
call :LogAction "Windows Update files removed on drive %TARGET_DRIVE%."
exit /b

:RemoveSystemRestorePoints
REM Remove System Restore Points
echo.
echo Removing System Restore Points on drive %TARGET_DRIVE%...
vssadmin.exe Delete Shadows /All /Quiet
call :LogAction "System Restore Points removed on drive %TARGET_DRIVE%."
exit /b

:OptimizeDrives
REM Optimize Drives
echo.
echo Optimizing drives on drive %TARGET_DRIVE%...
defrag.exe %TARGET_DRIVE% /O
call :LogAction "Drives optimized on drive %TARGET_DRIVE%."
exit /b

:ShowCleanupOptions
REM Show Cleanup Options (cleanmgr.exe)
echo.
echo Displaying Cleanup Options for drive %TARGET_DRIVE%...
cleanmgr /d %TARGET_DRIVE%
call :LogAction "Cleanup options displayed on drive %TARGET_DRIVE%."
exit /b

:RunPowerShellCleanup
REM Cleanup with PowerShell (Windows 10+)
echo.
echo Running cleanup with PowerShell on drive %TARGET_DRIVE%...
powershell.exe -Command "Start-Process -FilePath cleanmgr.exe -ArgumentList '/d %TARGET_DRIVE%' -Wait"
call :LogAction "Cleanup with PowerShell executed on drive %TARGET_DRIVE%."
exit /b

:UninstallUnusedPrograms
REM Uninstall Unused Programs
echo.
echo Listing installed programs...
wmic product get name
set /p UNINSTALL_PROGRAM=Enter the program name to uninstall (or type 'cancel' to cancel): 

if /i "%UNINSTALL_PROGRAM%"=="cancel" (
    echo Uninstall canceled by user.
    goto :EndScript
)

echo.
echo Uninstalling program: %UNINSTALL_PROGRAM%...
wmic product where name="%UNINSTALL_PROGRAM%" call uninstall
call :LogAction "Program '%UNINSTALL_PROGRAM%' uninstalled on drive %TARGET_DRIVE%."
exit /b

:DisableHibernate
REM Disable Hibernate
echo.
echo Disabling Hibernate on drive %TARGET_DRIVE%...
powercfg.exe /h off
call :LogAction "Hibernate disabled on drive %TARGET_DRIVE%."
exit /b

:RunCheckDisk
REM Check Disk for Errors
echo.
echo Checking disk for errors on drive %TARGET_DRIVE%...
chkdsk.exe %TARGET_DRIVE% /f /r
call :LogAction "Disk checked for errors on drive %TARGET_DRIVE%."
exit /b

:RunSFC
REM System File Checker (SFC)
echo.
echo Running System File Checker on drive %TARGET_DRIVE%...
sfc.exe /scannow
call :LogAction "System File Checker executed on drive %TARGET_DRIVE%."
exit /b

:RunDiskCleanupManager
REM Disk Cleanup Manager (cleanmgr.exe /lowdisk)
echo.
echo Running Disk Cleanup Manager on drive %TARGET_DRIVE%...
cleanmgr.exe /lowdisk /d %TARGET_DRIVE%
call :LogAction "Disk Cleanup Manager executed on drive %TARGET_DRIVE%."
exit /b

:LogAction
REM Log the provided action to the file with a timestamp
echo. >> %LOG_FILE%
echo Action: %1 - !DATE! !TIME! >> %LOG_FILE%
echo. >> %LOG_FILE%
exit /b
