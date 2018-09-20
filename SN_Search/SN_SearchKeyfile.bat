@echo off && setlocal enabledelayedexpansion
set Model=CT60
if exist %~dp0%~n0.log del %~dp0%~n0.log

for /f "" %%i in (SN_List.txt) do (
	set SSN=%%i
	set Exist_Flag=0
	call :Search 201807 !SSN!
	call :Search 201808 !SSN!
	call :Search 201809 !SSN!
	if "!Exist_Flag!"=="0" echo "!SSN!, NOT exist file" >> %~n0.log
)
goto end

:Search
set dir=%1
set keyword=%2
set file=%~dp0%dir%\%Model%%keyword%_*.txt
if exist %file% (
	set Exist_Flag=1
	for /f "" %%a in ('dir /b %file%') do set filename=%%a
	echo "%keyword%, exist !filename!" >> %~n0.log
)
goto :eof


:end
