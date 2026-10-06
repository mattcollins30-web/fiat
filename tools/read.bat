@echo off
rem One balance read, for a quick look between passes:
rem   tools\read.bat 5 Scrapper          five simulated hours of the Scrapper, keystones first
rem   tools\read.bat 8 Drifter shock     the shock build on the Drifter
rem   tools\read.bat 0 probe             the loot probe alone
rem Writes docs\balance\<build>.txt (the half-hour lines, the camp purchases,
rem the GATES line) and prints it when done. The full pass is tools\balance.bat.
setlocal
cd /d "%~dp0.."
if "%~2"=="" (
	echo usage: tools\read.bat ^<hours^> ^<Class^> [element]   or   tools\read.bat 0 probe
	exit /b 1
)
set GODOT=godot
if exist tools\godot.txt for /f "usebackq delims=" %%G in ("tools\godot.txt") do set "GODOT=%%~G"
if not exist docs\balance mkdir docs\balance
set OUT=docs\balance\%~2.txt
if not "%~3"=="" set OUT=docs\balance\%~2-%~3.txt
if "%~2"=="probe" (
	"%GODOT%" --headless --path . -s tests/balance.gd -- 0 probe > "%OUT%" 2>&1
) else (
	"%GODOT%" --headless --path . -s tests/balance.gd -- %~1 gate %~2 %~3 > "%OUT%" 2>&1
)
type "%OUT%"
echo.
echo -^> %OUT%
endlocal
