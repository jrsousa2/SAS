@echo off
REM Check if the argument %1 is provided

REM SAVE CUR DIR
set CURDIR=%CD%

IF "%~1"=="" (
    echo Setting description to Updt
    echo .
    set Desc=Updt
) ELSE (
  set Desc=%1
)

 cd D:\SAS
 set GIT_TRACE=1
 echo TO FORCE A RE-READING OF THE .gitignore list 
 echo uncomment the line
 REM git rm -r --cached .
 REM adds new + modified files
 REM git add .
 REM ADDS EVERYTHING
 git add -A
 REM BELOW MAY NOT BE NEEDED ANYMORE
 REM git branch -M main
 git commit -m %Desc%
 REM COMMENTED OUT CODE FORCES A PUSH
 REM It loses track of remote updates
 REM The below command will only download the README.MD
 REM git pull origin main --allow-unrelated-histories
 REM DO NOT FORCE PUSH, BEST TO MERGE HISTORIES FIRST
 echo DO NOT EDIT ANYTHING REMOTELY TO NOT CAUSE CONFLICT
 REM git push origin main --force
 git push origin main
 REM echo with nothing displays echo status
 echo.
 echo.
 echo VIEWS IF BATCH SUCCEEDED
 REM USING "git log -n 1" IS NOT TOO USEFUL
 git log -1 --name-status 
 cd %CURDIR%
 echo.

