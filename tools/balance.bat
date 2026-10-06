@echo off
rem The balance pass, in one command: every gate read at once, then the summary.
rem   tools\balance.bat           eight simulated hours a build (about three minutes of wall each)
rem   tools\balance.bat 4         four hours a build
rem Runs eleven Godot jobs side by side: the five classes keystones-first, the five
rem element builds on their affinity class, and the loot probe. Each writes
rem docs\balance\<build>.txt; the summary lands in docs\balance\summary.md.
rem Godot: the path in tools\godot.txt if that file exists (point it at the
rem _console.exe so the output reaches the files), else "godot" on the PATH.
setlocal enabledelayedexpansion
cd /d "%~dp0.."
set HOURS=%1
if "%HOURS%"=="" set HOURS=8
set GODOT=godot
if exist tools\godot.txt for /f "usebackq delims=" %%G in ("tools\godot.txt") do set "GODOT=%%~G"
if not "%GODOT%"=="godot" if not exist "%GODOT%" (
	echo Godot not found at "%GODOT%"; fix tools\godot.txt.
	exit /b 1
)
if not exist docs\balance mkdir docs\balance
del /q docs\balance\*.txt docs\balance\*.done 2>nul

set N=0
for %%C in (Doorman Drifter Poacher Scrapper Paramedic) do (
	set /a N+=1
	start "" /b cmd /c ""%GODOT%" --headless --path . -s tests/balance.gd -- %HOURS% gate %%C > docs\balance\%%C.txt 2>&1 & echo done > docs\balance\%%C.done"
)
for %%E in ("fire Drifter" "shock Drifter" "frost Poacher" "poison Poacher" "bleed Doorman") do (
	for /f "tokens=1,2" %%A in (%%E) do (
		set /a N+=1
		start "" /b cmd /c ""%GODOT%" --headless --path . -s tests/balance.gd -- %HOURS% gate %%B %%A > docs\balance\%%B-%%A.txt 2>&1 & echo done > docs\balance\%%B-%%A.done"
	)
)
set /a N+=1
start "" /b cmd /c ""%GODOT%" --headless --path . -s tests/balance.gd -- 0 probe > docs\balance\probe.txt 2>&1 & echo done > docs\balance\probe.done"

echo %N% reads running, %HOURS% simulated hours a build. Waiting.
:wait
timeout /t 10 /nobreak >nul
set DONE=0
for %%F in (docs\balance\*.done) do set /a DONE+=1
echo   %DONE% of %N% finished
if %DONE% lss %N% goto wait
del /q docs\balance\*.done 2>nul

"%GODOT%" --headless --path . -s tools/balance_summary.gd
if errorlevel 1 (
	echo The summary failed; the raw reads are in docs\balance\*.txt all the same.
	exit /b 1
)
echo Done: docs\balance\summary.md
endlocal
