@echo off
rem The smoke test: every screen, every check, the label fit. About ten
rem minutes; prints the failures (if any) and the verdict at the end.
rem Writes the full log to docs\balance\smoke.txt.
setlocal
cd /d "%~dp0.."
set GODOT=godot
if exist tools\godot.txt for /f "usebackq delims=" %%G in ("tools\godot.txt") do set "GODOT=%%~G"
if not exist docs\balance mkdir docs\balance
"%GODOT%" --headless --path . -s tests/smoke.gd > docs\balance\smoke.txt 2>&1
findstr /i /c:"CHECK FAILED" /c:"SCRIPT ERROR" /c:"Parse Error" /c:"FAIL:" /c:"needs " /c:"overlaps" /c:"all labels" /c:"out of its box" /c:"sits on" docs\balance\smoke.txt
echo -^> docs\balance\smoke.txt
endlocal
