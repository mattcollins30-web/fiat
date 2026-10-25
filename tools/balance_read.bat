@echo off
rem One balance read with a time limit (25 Oct, the tools review: a hung read blocked the watcher for good):
rem   tools\balance_read.bat <name> <minutes> <tests/balance.gd's arguments...>
rem   tools\balance_read.bat <name> <minutes> script <res path> <its arguments...>   another script (the loot read, 25 Oct)
rem writes docs\balance\pass\<name>.txt and, when it ends or is killed, docs\balance\pass\<name>.done: "done" and how
rem it ended (25 Oct, the tools review: a killed read read as crashed) - ok, killed-time (past its minutes),
rem killed-error (silent after a SCRIPT ERROR) or crashed (Godot's own error code); the summary names any but ok
setlocal
cd /d "%~dp0.."
set GODOT=godot
if exist tools\godot.txt for /f "usebackq delims=" %%G in ("tools\godot.txt") do set "GODOT=%%~G"
set "SCRIPT=tests/balance.gd"
set "ARGS=%3 %4 %5 %6 %7 %8 %9"
if /i "%~3"=="script" (
	set "SCRIPT=%~4"
	set "ARGS=%5 %6 %7 %8 %9"
)
powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_limited.ps1 -Godot "%GODOT%" -GodotArgs "--headless --path . -s %SCRIPT% -- %ARGS%" -Log docs\balance\pass\%1.txt -Minutes %2 -Quiet 900
set RC=%ERRORLEVEL%
set OUTCOME=crashed
if "%RC%"=="0" set OUTCOME=ok
if "%RC%"=="3" set OUTCOME=killed-time
if "%RC%"=="4" set OUTCOME=killed-error
>"docs\balance\pass\%1.done" echo done %OUTCOME%
endlocal
