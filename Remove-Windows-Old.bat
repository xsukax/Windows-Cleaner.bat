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

takeown /F "C:\Windows.old" /A /R /D Y
icacls "C:\Windows.old" /grant *S-1-5-32-544:F /T /C /Q
RD /S /Q "C:\Windows.old"

powershell -command "$ErrorActionPreference = 'Stop';$notificationTitle = 'Windows.old Clean Up Completed';[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null;$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText01);$toastXml = [xml] $template.GetXml();$toastXml.GetElementsByTagName('text').AppendChild($toastXml.CreateTextNode($notificationTitle)) > $null;$xml = New-Object Windows.Data.Xml.Dom.XmlDocument;$xml.LoadXml($toastXml.OuterXml);$toast = [Windows.UI.Notifications.ToastNotification]::new($xml);$toast.Tag = 'Test1';$toast.Group = 'Test2';$toast.ExpirationTime = [DateTimeOffset]::Now.AddSeconds(5);$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('xsukax Windows Cleaner');$notifier.Show($toast);"
echo.
echo Windows.old Clean Up Done!, You can exit by pressing any key.
echo.

pause > NUL
