@echo off && setlocal enabledelayedexpansion
rem PC date format need set to yyyy/M/d(yyyy*M*d)
set Model=%1
set SSN=%2
rem 17292D800G

set RUNEXEPATH="C:\Program Files (x86)\Honeywell\HONEdgeFactoryUtility\"
set RUNEXE=HONEdgeFactoryUtility.exe
set EXEOutputDIR="%UserProfile%"\Documents\HONEdge
set SucceededMSG="Succeeded for the Device"
set AlreadyMSG="extracted for Device"
set YYYY=%date:~0,4%
set MM=%date:~5,2%
set KeyfileServer=R:\%Model%\%YYYY%%MM%\
if "%MM:~0,1%" =="0" ( set "HideLeftZMM=%MM:~-1%" ) else ( set "HideLeftZMM=%MM%" )
set DD=%date:~8,2%
if "%DD:~0,1%" =="0" ( set "HideLeftZDD=%DD:~-1%" ) else ( set "HideLeftZDD=%DD%" )
set Logfile=%EXEOutputDIR%\%YYYY%-%HideLeftZMM%-%HideLeftZDD%_Log.txt
rem eg.2018-6-14_Log.txt

call :FindAllow_MAC
for /f "delims=: tokens=2" %%i in ('find /c "-" LocalAllow_MACList.txt') do set MACNum=%%i
for /f "delims=: tokens=1,2 " %%i in ( LocalAllow_MACList.txt ) do (
	set MACString=%%j
	set MACString=!MACString:~0,17!
	set MACAddress=!MACString:~0,2!!MACString:~3,2!!MACString:~6,2!!MACString:~9,2!!MACString:~12,2!!MACString:~15,2!
	set %%i=!MACAddress!
)
if not defined MAC1 ( set errorMsg="not defined MAC1" && goto fail )
echo MAC1:%MAC1%
set KeyfilePath1=%EXEOutputDIR%\%Model%_%MM%-%DD%-%YYYY%_%MAC1%\
rem eg.%UserProfile%\Documents\HONEdge\CT60_06-14-2018_085700F1899F
rem 085700F1899F is Local Allow PC MAC address,And One PC may have 2 allowed MAC
if defined MAC2 echo MAC2:%MAC2% && set KeyfilePath2=%EXEOutputDIR%\%Model%_%MM%-%DD%-%YYYY%_%MAC2%\
if defined KeyfilePath2 ( 
	if exist %KeyfilePath2% ( set KeyfilePath=%KeyfilePath2%) else ( set KeyfilePath=%KeyfilePath1%)
) else ( 
	set KeyfilePath=%KeyfilePath1%
)
echo KeyfilePath1:%KeyfilePath1%
echo KeyfilePath2:%KeyfilePath2%
echo KeyfilePath:%KeyfilePath%
set Keyfile=%KeyfilePath%%Model%%SSN%_%YYYY%%MM%%DD%_*.txt
if exist %EXEOutputDIR%\*_Log.txt del %EXEOutputDIR%\*_Log.txt
if exist %EXEOutputDIR%\%Model%_* (
for /f "" %%i in ('dir /b %EXEOutputDIR%\%Model%_*') do rmdir /s /q %EXEOutputDIR%\%%i
)
tasklist /v | find "%RUNEXE%" >nul
if not errorlevel 1 taskkill /im %RUNEXE% /f >nul
cd /d %RUNEXEPATH%
start %RUNEXE%
cd /d %~dp0
if exist %Logfile%  del %Logfile%
if exist %Keyfile% del %Keyfile%
call ButtonClick.exe
if errorlevel 1 ( set errorMsg="ButtonClick.exe error" && goto fail )
set /a n=0
echo waitting the %Logfile%...
:WaitLog
echo wait %n%S && ping 127.0.0.1 -n 2 >nul 
set /a n=n+1
if not exist %Logfile% if !n! leq 30 ( goto WaitLog )
if not exist %Logfile% if !n! gtr 30 ( set errorMsg="not exist %Logfile%" && goto fail )
set /a n=0
echo finding the %Logfile% keyword...
:FindLogKeyword
echo wait %n%S && ping 127.0.0.1 -n 2 >nul 
set /a n=n+1
find %AlreadyMSG% %Logfile% >nul
if errorlevel 1 (
	find %SucceededMSG% %Logfile% >nul
	if errorlevel 1 ( 
		if !n! leq 25 ( goto FindLogKeyword ) else (  
			type %Logfile%
			set errorMsg="Both not exist %SucceededMSG% and %AlreadyMSG% in %Logfile%"" 
			goto fail 
			)
	)
	goto UploadKeyfile
) else ( 
echo Already generate the %Model%%SSN%_YYYYMMDD_HHssmm.txt, next will need to check the server path if exist %Model%%SSN%_%YYYY%%MM%%DD%_HHssmm.txt 
goto CHK_S_Keyfile
)

:UploadKeyfile
if not exist "%KeyfilePath%" ( set errorMsg="not exist %KeyfilePath%" && goto fail )
if not exist %Keyfile% (set errorMsg="not exist %Keyfile%" && goto fail)
rem Transfer Keyfile* to be the only one Keyfile, and it only contains filename(no file path)
for /f "" %%i in ('dir /b %Keyfile%') do set Keyfile=%%i
call :Mapstart R: \\10.5.22.30\Reg_Key administrator usi_2010
if not exist %KeyfileServer% md %KeyfileServer%
copy /y %KeyfilePath%%Keyfile% %KeyfileServer%%Keyfile%
if errorlevel 1 (set errorMsg="Copy %Keyfile% to server error" && goto fail)
fc /b %KeyfilePath%%Keyfile% %KeyfileServer%%Keyfile% >nul
if errorlevel 1 (
	del %KeyfileServer%%Keyfile%
	set errorMsg="file compare %Keyfile% with server error" && goto fail
)
type %KeyfilePath%%Keyfile%
echo.
echo SUCCESSFUL TEST
goto end

:CHK_S_Keyfile
call :Mapstart R: \\10.5.22.30\Reg_Key administrator usi_2010
if not exist %KeyfileServer%\%Model%%SSN%_%YYYY%%MM%%DD%_*.txt  (
	echo not exist %KeyfileServer%\%Model%%SSN%_%YYYY%%MM%%DD%_*.txt
	set errorMsg="The DUT need offline re-flash Debug G2H OS,Call TE for help" 
	goto fail
)
for /f "delims=\ tokens=4" %%i in ('dir /b %KeyfileServer%\%Model%%SSN%_%YYYY%%MM%%DD%_*.txt') do set S_Keyfile_name=%%i
rem S_Keyfile_name=CT6018238D83A2_20180901_154048.txt
if "%S_Keyfile_name:~24,1%" == "0" (set /a HH_File=%S_Keyfile_name:~25,1%) else (set /a HH_File=%S_Keyfile_name:~24,1%%S_Keyfile_name:~25,1%)
set /a HH_PC="%time:~0,2%"
echo The Local PC time Hour is %HH_PC%, and the Server Keyfile time Hour is %HH_File%
set /a Diff=HH_PC-HH_File
echo Check if Diff:%Diff% is into the limit of [0,3]...
if Not %Diff%  geq 0 (
	set errorMsg="The PC time or the server file time error, call TE/TD for help" 
	goto fail
)
if Not %Diff%  leq 3 (
	echo The already exist Keyfile in server is more than 3 Hours time limit, 
	echo can not sure the DUT if something has changed, so need re-flash Debug G2H OS to clear kefile message inside
	set errorMsg="The DUT need offline re-flash Debug G2H OS,Call TE for help" 
	goto fail
)
echo Check if Diff:%Diff% is into the limit of [0,3]...Pass

type %KeyfileServer%\%Model%%SSN%_%YYYY%%MM%%DD%_%S_Keyfile_name%.txt
echo.
echo SUCCESSFUL TEST
goto end

:fail
echo errorMsg:%errorMsg%
echo FAILED TEST
goto end

:FindAllow_MAC
cd /d %~dp0
if exist LocalAllow_MACList.txt del LocalAllow_MACList.txt
if exist LocalMacList.txt del LocalMacList.txt
ipconfig /all | find "-" | find /v "00-00" > LocalMacList.txt
if errorlevel 1 ( set errorMsg="ipconfig error" && goto fail )
set /a flag=0
for /f "" %%i in ( TotalAllow_MACList.txt ) do (
	set MAC=%%i
	type LocalMacList.txt | find "!MAC!" >nul
	if not errorlevel 1 ( 
	set /a flag=flag+1 
	echo MAC!Flag!:!MAC!>> LocalAllow_MACList.txt  
	)
)
if "%flag%" == "0" ( set errorMsg="The Local PC does not have MAC in the TotalAllow_MACList.txt" && goto fail) else ( type LocalAllow_MACList.txt )
del LocalMacList.txt
goto :eof

:Mapstart
set Driver=%1
set ServerPath=%2
set User=%3
set PW=%4
for /f "tokens=1 delims=\" %%i in ('echo %ServerPath%') do set server=%%i
if exist %Driver%\ net use /d %Driver% /y
ping %server% -n 2 >nul
if errorlevel 1 (
	echo %server% ping error, Pls check the network
	goto :eof
)
net use %Driver% %ServerPath% /USER:%user% %PW% 
echo test >%Driver%\test.flag
if not exist %Driver%\test.flag (
	echo Map %Driver% ServerPath error 
	goto :eof
)
echo Successful to MAP server
del %Driver%\test.flag /f
goto :eof


:end
cd /d %~dp0
tasklist /v | find "%RUNEXE%" >nul
if not errorlevel 1 taskkill /im %RUNEXE% /f >nul