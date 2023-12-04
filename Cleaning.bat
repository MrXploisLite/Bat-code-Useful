@echo off
setlocal enabledelayedexpansion

:: Set the target drive (change to the appropriate drive letter if needed)
set TARGET_DRIVE=C:

:: Set the log file path
set LOG_FILE_PATH=C:\Logs
set LOG_FILE=%LOG_FILE_PATH%\cleanup_log.txt

:: Ensure the log file directory exists
mkdir "%LOG_FILE_PATH%" 2>nul

:CleanupMenu
cls
echo.
echo Disk space information before cleanup on drive %TARGET_DRIVE%:
fsutil volume diskfree %TARGET_DRIVE%
echo.

:: Reset cleanup execution flag
set "CLEANUP_EXECUTED="

:CleanupOptions
:: Provide options for cleanup
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

if not "%CLEANUP_OPTIONS%" geq "1" if not "%CLEANUP_OPTIONS%" leq "20" (
    echo Invalid option. Please enter a number between 1 and 20.
    timeout /nobreak /t 3 >nul
    goto :CleanupOptions
)

if "%CLEANUP_OPTIONS%"=="20" (
    echo Cleanup completed. Exiting script.
    goto :EndScript
) else if not defined CLEANUP_EXECUTED (
    :: Execute cleanup only if the flag is not defined
    set "CLEANUP_EXECUTED=1"
    call :ExecuteCleanup %CLEANUP_OPTIONS%
) else (
    echo Cleanup options already executed. Choose a different option.
    goto :CleanupOptions
)

echo.
echo Disk space information after cleanup on drive %TARGET_DRIVE%:
fsutil volume diskfree %TARGET_DRIVE%

:: Display a summary of cleaned items
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
:: Close the console window after completion
set /p CLOSE_CONSOLE=Do you want to close this console window? (Y/N): 
if /i "%CLOSE_CONSOLE%"=="Y" (
    exit
)

endlocal
exit /b

:ExecuteCleanup
:: Execute the cleanup option based on the user's choice
if "%1"=="19" (
    call :RunDiskCleanupManager
) else if "%1"=="18" (
    call :RunSFC
) else if "%1"=="17" (
    call :RunCheckDisk
) else if "%1"=="16" (
    call :DisableHibernate
) else if "%1"=="15" (
    call :UninstallUnusedPrograms
) else if "%1"=="14" (
    call :RunPowerShellCleanup
) else if "%1"=="13" (
    call :ShowCleanupOptions
) else if "%1"=="12" (
    call :OptimizeDrives
) else if "%1"=="11" (
    call :RemoveSystemRestorePoints
) else if "%1"=="10" (
    call :RemoveWindowsUpdateFiles
) else if "%1"=="9" (
    call :CompactOS
) else if "%1"=="8" (
    call :RemoveTemporaryFiles
) else if "%1"=="7" (
    call :EmptyRecycleBin
) else if "%1"=="6" (
    call :ViewCleanupLog
) else if "%1"=="5" (
    call :ScheduleAutomaticCleanup
) else if "%1"=="4" (
    call :ChooseCleanupCategories
) else (
    call :RunDiskCleanup %1
)
exit /b

:ChooseCleanupCategories
:: Allow users to choose specific cleanup categories
cleanmgr /d %TARGET_DRIVE%
call :LogCleanupSummary
exit /b

:ScheduleAutomaticCleanup
:: Schedule automatic cleanup using Task Scheduler
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
:: Log the cleanup summary to the file with a timestamp
echo. >> %LOG_FILE%
echo Cleanup Summary for %TARGET_DRIVE% - !DATE! !TIME! >> %LOG_FILE%
cleanmgr /sagerun:1 /d %TARGET_DRIVE% /L:%LOG_FILE%
echo. >> %LOG_FILE%

echo.
set /p CONTINUE_CLEANUP=Do you want to perform another cleanup? (Y/N): 
if /i "%CONTINUE_CLEANUP%"=="Y" (
    goto :CleanupMenu
)

:ViewCleanupLog
:: View the cleanup log
if exist "%LOG_FILE%" (
    echo.
    echo Cleaning Log:
    type "%LOG_FILE%"
) else (
    echo.
    echo No cleanup log found.
)

echo.
pause
exit /b

:EmptyRecycleBin
:: Empty Recycle Bin
echo.
echo Emptying Recycle Bin on drive %TARGET_DRIVE%...
rd /s /q "%TARGET_DRIVE%\$Recycle.bin"
call :LogAction "Recycle Bin emptied on drive %TARGET_DRIVE%."
exit /b

:RemoveTemporaryFiles
:: Remove Temporary Files
echo.
echo Removing temporary files on drive %TARGET_DRIVE%...
del /q /f /s "%TARGET_DRIVE%\Windows\Temp\*.*"
call :LogAction "Temporary files removed on drive %TARGET_DRIVE%."
exit /b

:CompactOS
:: Compact OS (Windows 10+)
echo.
echo Compacting OS on drive %TARGET_DRIVE%...
compact.exe /
call :LogAction "OS compacted on drive %TARGET_DRIVE%."
exit /b

:RemoveWindowsUpdateFiles
:: Remove Windows Update Files
echo.
echo Removing Windows Update files on drive %TARGET_DRIVE%...
del /q /f /s "%TARGET_DRIVE%\Windows\SoftwareDistribution\Download\*.*"
call :LogAction "Windows Update files removed on drive %TARGET_DRIVE%."
exit /b

:RemoveSystemRestorePoints
:: Remove System Restore Points
echo.
echo Removing System Restore Points on drive %TARGET_DRIVE%...
vssadmin.exe Delete Shadows /All /Quiet
call :LogAction "System Restore Points removed on drive %TARGET_DRIVE%."
exit /b

:OptimizeDrives
:: Optimize Drives
echo.
echo Optimizing drives on drive %TARGET_DRIVE%...
defrag.exe %TARGET_DRIVE% /O
call :LogAction "Drives optimized on drive %TARGET_DRIVE%."
exit /b

:ShowCleanupOptions
:: Show Cleanup Options (cleanmgr.exe)
echo.
echo Displaying Cleanup Options for drive %TARGET_DRIVE%...
cleanmgr /d %TARGET_DRIVE%
call :LogAction "Cleanup options displayed on drive %TARGET_DRIVE%."
exit /b

:RunPowerShellCleanup
:: Cleanup with PowerShell (Windows 10+)
echo.
echo Running cleanup with PowerShell on drive %TARGET_DRIVE%...
powershell.exe -Command Start-Process -FilePath cleanmgr.exe -ArgumentList "/d %TARGET_DRIVE%" -Wait
call :LogAction "Cleanup with PowerShell executed on drive %TARGET_DRIVE%."
exit /b

:UninstallUnusedPrograms
:: Uninstall Unused Programs
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
:: Disable Hibernate
echo.
echo Disabling Hibernate on drive %TARGET_DRIVE%...
powercfg.exe /h off
call :LogAction "Hibernate disabled on drive %TARGET_DRIVE%."
exit /b

:RunCheckDisk
:: Check Disk for Errors
echo.
echo Checking disk for errors on drive %TARGET_DRIVE%...
chkdsk.exe %TARGET_DRIVE% /f /r
call :LogAction "Disk checked for errors on drive %TARGET_DRIVE%."
exit /b

:RunSFC
:: System File Checker (SFC)
echo.
echo Running System File Checker on drive %TARGET_DRIVE%...
sfc.exe /scannow
call :LogAction "System File Checker executed on drive %TARGET_DRIVE%."
exit /b

:RunDiskCleanupManager
:: Disk Cleanup Manager (cleanmgr.exe /lowdisk)
echo.
echo Running Disk Cleanup Manager on drive %TARGET_DRIVE%...
cleanmgr.exe /lowdisk /d %TARGET_DRIVE%
call :LogAction "Disk Cleanup Manager executed on drive %TARGET_DRIVE%."
exit /b

:LogAction
:: Log the provided action to the file with a timestamp
echo. >> "%LOG_FILE%"
echo Action: %1 - !DATE! !TIME! >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"
exit /b
