@echo off
rem The smoke test: every screen, every check, the label fit. About ten
rem minutes; prints the failures (if any) and the verdict at the end.
rem Writes the full log to docs\balance\smoke.txt.
setlocal
cd /d "%~dp0.."
set GODOT=godot
if exist tools\godot.txt for /f "usebackq delims=" %%G in ("tools\godot.txt") do set "GODOT=%%~G"
if not exist docs\balance mkdir docs\balance
rem with a time limit (13 Oct): a script error used to leave Godot running and the watcher waiting for ever
powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_limited.ps1 -Godot "%GODOT%" -GodotArgs "--headless --path . -s tests/smoke.gd" -Log docs\balance\smoke.txt -Minutes 25 -Quiet 180
rem a script error ends only the check function it is in, and the rest of it never runs: the verdict fails (20 Oct)
findstr /c:"SCRIPT ERROR" docs\balance\smoke.txt >nul && echo FAIL: a script error cut a check short, see above>> docs\balance\smoke.txt
rem an engine error the checks can't see (23 Oct: "Can't add child" logged at every launch and the smoke passed)
findstr /c:"Can't add child" /c:"already has a parent" docs\balance\smoke.txt >nul && echo FAIL: a node added twice, see above>> docs\balance\smoke.txt
findstr /i /c:"CHECK FAILED" /c:"SCRIPT ERROR" /c:"Parse Error" /c:"FAIL:" /c:"needs " /c:"overlaps" /c:"all labels" /c:"out of its box" /c:"sits on" /c:"Can't add child" docs\balance\smoke.txt
echo -^> docs\balance\smoke.txt
endlocal
