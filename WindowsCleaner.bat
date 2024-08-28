@TITLE Windows Cleaner
@echo off
color 0A

:: BatchGotAdmin
:-------------------------------------
::  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

:: --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------    


cls


:: Check If User Has Admin Privileges
timeout /t 1 /nobreak > NUL
openfiles > NUL 2>&1
if %errorlevel%==0 (
    echo Running..
) else (
    echo You must run me as an Administrator. Exiting..
    echo.
    echo Right-click on me and select ^'Run as Administrator^' and try again.
    echo.
    echo Press any key to exit..
    pause > NUL
    exit
)

echo.

:: Delete Temporary Files
del /s /f /q %WinDir%\Temp\*.*
del /s /f /q %WinDir%\Prefetch\*.*
del /s /f /q %Temp%\*.*
del /s /f /q %AppData%\Temp\*.*
del /s /f /q %HomePath%\AppData\LocalLow\Temp\*.*
del /s /f /q %localappdata%\Temp\*.*
del /f /s /q %systemdrive%\*.tmp
del /f /s /q %systemdrive%\*._mp

:: Remove log, trace, old and backup files.
del /f /s /q %systemdrive%\*.log
del /f /s /q %systemdrive%\*.old
del /f /s /q %systemdrive%\*.trace
del /f /s /q %windir%\*.bak

:: Remove restored files created by an checkdisk utility.
del /f /s /q %systemdrive%\*.chk

:: Remove powercfg energy report.
del /f /s /q %windir%\system32\energy-report.html

:: Delete Used Drivers Files (Not needed because already installed)
del /s /f /q %SYSTEMDRIVE%\AMD\*.*
del /s /f /q %SYSTEMDRIVE%\NVIDIA\*.*
del /s /f /q %SYSTEMDRIVE%\INTEL\*.*

:: Delete Temporary Folders
rd /s /q %WinDir%\Temp
rd /s /q %WinDir%\Prefetch
rd /s /q %Temp%
rd /s /q %AppData%\Temp
rd /s /q %HomePath%\AppData\LocalLow\Temp
rd /s /q %localappdata%\Temp

:: Delete Used Drivers Folders (Not needed because already installed)
rd /s /q %SYSTEMDRIVE%\AMD
rd /s /q %SYSTEMDRIVE%\NVIDIA
rd /s /q %SYSTEMDRIVE%\INTEL

:: Recreate Empty Temporary Folders
md %WinDir%\Temp
md %WinDir%\Prefetch
md %Temp%
md %AppData%\Temp
md %HomePath%\AppData\LocalLow\Temp
md %localappdata%\Temp

:: Clearing Thumbnail Cache
echo Clearing Thumbnail Cache...
del /s /q "%LocalAppData%\Microsoft\Windows\Explorer\*.db"

:: Clearing Microsoft Store Cache
echo Clearing Microsoft Store Cache ...
WSReset.exe

:: Flush DNS
echo Flushing DNS...
ipconfig /flushdns

:: Remove event logs.
wevtutil.exe cl Application
wevtutil.exe cl System

:: Disable Hibernation (removes hiberfil.sys)
powercfg -h off
timeout /t 5
del /f /q C:\hiberfil.sys

:: The $GetCurrent directory is created during the upgrade process. It contains log files
:: about that last Windows upgrade process and may also contain the installation files for that update.
rd C:\$GetCurrent /s /q

:: If you choose to delete the $WINDOWS.~BT folder on Windows 10, you won’t be able to downgrade
:: to the previous build of Windows 10 or previous version of Windows your PC had installed.
rd C:\$WINDOWS.~BT /s /q
rd C:\$WINDOWS.~WS /s /q

:: The /Cleanup-Image parameter of Dism.exe provides advanced users more options to
:: further reduce the size of the WinSxS folder. All existing service packs and updates
:: cannot be uninstalled after this command is completed. This will not block the
:: uninstallation of future service packs or updates.
Dism.exe /online /Cleanup-Image /StartComponentCleanup
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBasecmd

:: To reduce the amount of space used by a Service Pack:
:: remove any backup components needed for uninstallation of the service pack.
Dism.exe /online /Cleanup-Image /SPSuperseded

:: Remove some more superseded versions ("All existing update packages can't be uninstalled
:: after this command is completed, but this won't block the uninstallation of future update packages.")
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

:: Reclaim reserved storage
:: https://www.windowslatest.com/2020/03/15/windows-10-will-finally-allow-you-to-reclaim-reserved-storage/
:: Windows 10 2004 only
DISM.exe /Online /Set-ReservedStorageState /State:Disabled

:: Run the StartComponentCleanup task in Task Scheduler to clean up and compress components
schtasks.exe /Run /TN "\Microsoft\Windows\Servicing\StartComponentCleanup"

:: After you have installed all the pending updates, it is safe to delete all the
:: files and folder under C:\WINDOWS\SoftwareDistribution\Download\
:: https://superuser.com/a/53274
net stop wuauserv
del /q C:\WINDOWS\SoftwareDistribution\Download\*
for /d %%x in (C:\WINDOWS\SoftwareDistribution\Download\*) do @rd /s /q "%%x"
net start wuauserv

:: Delete our own Temp directory
rd C:\Temp /s /q

:: Delete Logitech G Hub caches
rd C:\ProgramData\LGHUB\cache /s /q

:: Delete Windows memory dumps (not useful unless you're having specific problems to diagnose)
del /q C:\Windows\MEMORY.dmp

:: Possibly reclaim some space from the .NET Native Images
"%windir%\Microsoft.NET\Framework\v2.0.50727\ngen" update
"%windir%\Microsoft.NET\Framework\v4.0.30319\ngen" update

:: Run Disk Cleanup in "System" mode, without displaying the window first
:: (a final success message is still displayed)
cleanmgr.exe /verylowdisk /d c

setlocal

set /p choice="Do you want to perform storage optimization? (y/n): "
if "%choice%"=="y" (
    defrag C: /O /W /V /U
    echo Storage optimization completed.
) else if "%choice%"=="n" (
    echo Storage optimization skipped.
) else (
    echo Invalid choice. Please enter 'y' or 'n'.
)

endlocal

powershell -command "$ErrorActionPreference = 'Stop';$notificationTitle = 'Windows Clean Up Completed';[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null;$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText01);$toastXml = [xml] $template.GetXml();$toastXml.GetElementsByTagName('text').AppendChild($toastXml.CreateTextNode($notificationTitle)) > $null;$xml = New-Object Windows.Data.Xml.Dom.XmlDocument;$xml.LoadXml($toastXml.OuterXml);$toast = [Windows.UI.Notifications.ToastNotification]::new($xml);$toast.Tag = 'Test1';$toast.Group = 'Test2';$toast.ExpirationTime = [DateTimeOffset]::Now.AddSeconds(5);$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('xsukax Windows Cleaner');$notifier.Show($toast);"
echo.
echo Windows Clean Up Done!, You can exit by pressing any key.
echo.

pause > NUL
