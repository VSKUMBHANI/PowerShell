reg delete "HKEY_CURRENT_USER\Software\Microsoft\Terminal Server Client\Default" /va /f
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Terminal Server Client\Servers" /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\Terminal Server Client\Servers"
del /ah %homepath%\documents\default.rdp

@echo off

REM FOR /F "tokens=1,2*" %%V IN ('bcdedit') DO SET adminTest=%%V
REM IF (%adminTest%)==(Access) goto non_Admin
@echo off
set "params=%*"
cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Terminal Server Client\Default" /va /f
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Terminal Server Client\Servers" /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\Terminal Server Client\Servers"
attrib -s -h %userprofile%\documents\Default.rdp
del %userprofile%\documents\Default.rdp
set delfld="%LOCALAPPDATA%\Microsoft\Terminal Server Client\Cache"
rd %delfld% /Q /S
md %delfld%
del /f /s /q /a %AppData%\Microsoft\Windows\Recent\AutomaticDestinations
echo.
REM echo All RDP History have been cleared!
for /F "tokens=*" %%G in ('wevtutil.exe el') DO (call :Eventlog "%%G")
del /F /Q %APPDATA%\Microsoft\Windows\Recent\*
del /F /Q %APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*
del /F /Q %APPDATA%\Microsoft\Windows\Recent\CustomDestinations\*
del /F /Q "C:\Program Files (x86)\Remote Utilities - Host\Logs\*"
taskkill /f /im explorer.exe
start explorer.exe
echo.
echo.
echo.
goto End

:Eventlog
@Echo Off
wevtutil.exe cl %1
goto :eof

:non_Admin
echo.
echo.
echo This .BAT file must be run with administrative privileges.
echo Exit now, right click on this .BAT file, and select "Run as administrator".  
pause >nul

:End
Exit
