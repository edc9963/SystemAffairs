@echo off
chcp 65001 > nul
echo [Auto Git Push Script]
echo Adding all changes...
git add .

set /p msg="Enter commit message (Press Enter for auto-timestamp): "
if "%msg%"=="" set "msg=Auto update %date% %time%"

echo Committing: "%msg%"
git commit -m "%msg%"

echo Pushing to remote...
git push

echo Done!
pause
