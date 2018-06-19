chcp 437
@echo off
set /p MAC_ID=Pls input the PC ID(1~10+):
ipconfig /all | find /i "Physical Address" | find /v "00-00" > SW_MAC_%MAC_ID%.txt
type SW_MAC_%MAC_ID%.txt
timeout /t 2