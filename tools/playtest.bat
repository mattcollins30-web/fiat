@echo off
rem The playtest read (11 Oct): what your save's chronicle says about the run.
rem   tools\playtest.bat                       reads the live save (user://fiat.save)
rem   tools\playtest.bat C:\path\to\fiat.save  reads a copy
rem Writes docs\balance\playtest.md (time, milestones, the gates as played,
rem sites, hour by hour, spending, kit) and prints it when done.
setlocal
cd /d "%~dp0.."
set GODOT=godot
if exist tools\godot.txt for /f "usebackq delims=" %%G in ("tools\godot.txt") do set "GODOT=%%~G"
if not exist docs\balance mkdir docs\balance
"%GODOT%" --headless --path . -s tools/playtest_summary.gd -- "%~1" > docs\balance\playtest.log 2>&1
type docs\balance\playtest.md
echo.
echo -^> docs\balance\playtest.md
endlocal
