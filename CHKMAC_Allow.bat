@echo off && setlocal enabledelayedexpansion
if exist LocalAllow_MACList.txt del LocalAllow_MACList.txt
if exist LocalMacList.txt del LocalMacList.txt
getmac > LocalMacList.txt
if errorlevel 1 ( set errorMsg="ButtonClick.exe error" && goto fail )
set /a flag=0
for /f "" %%i in ( TotalAllow_MACList.txt ) do (
	set MAC=%%i
	type LocalMacList.txt | find "!MAC!" >nul
	if not errorlevel 1 echo !MAC! >>LocalAllow_MACList.txt && set /a flag=1
)
if not "%flag%" == "1" ( echo "The Local PC does not have MAC in the TotalAllow_MACList.txt") else ( type LocalAllow_MACList.txt )
del LocalMacList.txt
goto end

:fail
echo errorMsg:%errorMsg%
echo UUT-FAIL
goto end

:end
