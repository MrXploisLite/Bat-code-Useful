@echo off
setlocal enabledelayedexpansion

:: Set the target drive (change to the appropriate drive letter if needed)
set /p TARGET_DRIVE=Enter the target drive letter (e.g., C): 

:: Set the log file path
set LOG_FILE_PATH=%TARGET_DRIVE%:\Logs
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
echo 3. Remove Windows Update Files
echo 4. Remove System Restore Points
echo 5. Optimize Drives
echo 6. Uninstall Unused Programs
echo 7. Check Disk for Errors
echo 8. System File Checker (SFC)
echo 9. Disk Cleanup Manager (cleanmgr.exe /lowdisk)
echo 10. Exit
echo.

set /p CLEANUP_OPTIONS=Enter your choice (1-10): 

if not "%CLEANUP_OPTIONS%" geq "1" if not "%CLEANUP_OPTIONS%" leq "10" (
    echo Invalid option. Please enter a number between 1 and 10.
    timeout /nobreak /t 3 >nul
    goto :CleanupOptions
)

if "%CLEANUP_OPTIONS%"=="10" (
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
if "%1"=="9" (
    call :RunDiskCleanupManager
) else if "%1"=="8" (
    call :RunSFC
) else if "%1"=="7" (
    call :RunCheckDisk
) else if "%1"=="6" (
    call :UninstallUnusedPrograms
) else if "%1"=="5" (
    call :OptimizeDrives
) else if "%1"=="4" (
    call :RemoveSystemRestorePoints
) else if "%1"=="3" (
    call :RemoveWindowsUpdateFiles
) else (
    call :RunDiskCleanup %1
)

:: Ask if the user wants to return to the main menu
set /p RETURN_TO_MENU=Do you want to return to the main menu? (Y/N): 
if /i "%RETURN_TO_MENU%"=="Y" (
    goto :CleanupMenu
) else (
    goto :EndScript
)
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

:: Ask for confirmation before uninstalling the program
set /p CONFIRM_UNINSTALL=Are you sure you want to uninstall %UNINSTALL_PROGRAM%? (Y/N): 
if /i "%CONFIRM_UNINSTALL%"=="Y" (
    echo.
    echo Uninstalling program: %UNINSTALL_PROGRAM%...
    wmic product where name="%UNINSTALL_PROGRAM%" call uninstall
    call :LogAction "Program '%UNINSTALL_PROGRAM%' uninstalled on drive %TARGET_DRIVE%."
) else (
    echo Uninstall canceled by user.
)

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
cleanmgr /d %TARGET_DRIVE%
call :LogAction "Disk Cleanup Manager executed on drive %TARGET_DRIVE%."
exit /b

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

:LogAction
:: Log the provided action to the file with a timestamp
echo. >> "%LOG_FILE%"
echo Action: %1 - !DATE! !TIME! >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"
exit /b
