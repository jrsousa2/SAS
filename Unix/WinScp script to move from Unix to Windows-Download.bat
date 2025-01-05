REM DOWNLOAD_VAR.BAT
@echo off
echo PMT: YEAR WITH 4 DIGITS
set PY4=%date:~10,4%
echo PMT: YEAR WITH 2 DIGITS
set PY2=%date:~12,2%
 
echo PMT: LAST MONTH
set /a "PM=%date:~4,2%-1"
echo FORMATS PM WITH LEADING ZEROS
set PM=00%PM%
set PM=%PM:~-2%
 
echo PMT: CURRENT MONTH
set /a "CM=%date:~4,2%"
echo FORMATS PM WITH LEADING ZEROS
set CM=00%CM%
set CM=%CM:~-2%
 
echo PMT: YEAR/MONTH (YM2 IS YEAR+CURRENT MONTH (E.G. 202104))
set YM=%PY4%%PM%
set YCM=%PY4%%CM%
 
echo CALLS WINSCP
cd "C:\Program Files\WinSCP"
WinSCP.com /log="H:\My documents\Scheduler\Var_Download.log"  /script="H:\My documents\Scheduler\Download_Var.txt" /parameter %YM% %YCM%
