REM UPLOAD_VAR.BAT
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
 
echo PMT: YEAR/MONTH
set YM=%PY4%%PM%
 
echo CALLS WINSCP
cd "C:\Program Files\WinSCP"
WinSCP.com /log="H:\My documents\Scheduler\Var_Upload.log"  /script="H:\My documents\Scheduler\Upload_Var.txt" /paramater %YM%
