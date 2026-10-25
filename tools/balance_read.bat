@echo off
rem One balance read with a time limit (25 Oct, the tools review: a hung read blocked the watcher for good):
rem   tools\balance_read.bat <name> <minutes> <tests/balance.gd's arguments...>
rem writes docs\balance\pass\<name>.txt and, when it ends or is killed, docs\balance\pass\<name>.done
setlocal
cd /d "%~dp0.."
set GODOT=godot
if exist tools\godot.txt for /f "usebackq delims=" %%G in ("tools\godot.txt") do set "GODOT=%%~G"
powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_limited.ps1 -Godot "%GODOT%" -GodotArgs "--headless --path . -s tests/balance.gd -- %3 %4 %5 %6 %7 %8 %9" -Log docs\balance\pass\%1.txt -Minutes %2 -Quiet 900
echo done > docs\balance\pass\%1.done
endlocal
