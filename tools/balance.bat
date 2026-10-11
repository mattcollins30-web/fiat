@echo off
rem The balance pass, in one command: every gate read at once, then the summary.
rem   tools\balance.bat           sixteen simulated hours a build (the lorry's gate; twenty minutes of wall each)
rem   tools\balance.bat 8         eight hours a build
rem   tools\balance.bat 32 3      thirty-two hours, three reads a build (the final pass, 8 Oct)
rem Runs thirty-one Godot jobs side by side, twice each build (one run is a noisy
rem read of when the bank falls; the summary takes the median): the ten element
rem builds - every class on each of its two affinities - which every gate judges
rem (Matt, 11 Oct: the element builds are the game), the five plain classes to
rem their keystones for at least twenty-four hours, which only have to beat the
rem lorry (the plain floor: slow is fine, stuck isn't), and the loot probe. Each writes docs\balance\<build>-N.txt; the summary lands in
rem docs\balance\summary.md.
rem Godot: the path in tools\godot.txt if that file exists (point it at the
rem _console.exe so the output reaches the files), else "godot" on the PATH.
setlocal enabledelayedexpansion
cd /d "%~dp0.."
set HOURS=%1
if "%HOURS%"=="" set HOURS=16
set READS=%2
if "%READS%"=="" set READS=2
set PLAIN_HOURS=%HOURS%
if %PLAIN_HOURS% lss 24 set PLAIN_HOURS=24
set GODOT=godot
if exist tools\godot.txt for /f "usebackq delims=" %%G in ("tools\godot.txt") do set "GODOT=%%~G"
if not "%GODOT%"=="godot" if not exist "%GODOT%" (
	echo Godot not found at "%GODOT%"; fix tools\godot.txt.
	exit /b 1
)
if not exist docs\balance mkdir docs\balance
del /q docs\balance\*.txt docs\balance\*.done 2>nul

set N=0
for /l %%S in (1,1,%READS%) do (
	for %%C in (Doorman Drifter Poacher Scrapper Paramedic) do (
		set /a N+=1
		start "" /b cmd /c ""%GODOT%" --headless --path . -s tests/balance.gd -- %PLAIN_HOURS% gate %%C > docs\balance\%%C-%%S.txt 2>&1 & echo done > docs\balance\%%C-%%S.done"
	)
	for %%E in ("fire Drifter" "shock Drifter" "frost Poacher" "poison Poacher" "bleed Doorman" "physical Doorman" "shock Scrapper" "fire Scrapper" "poison Paramedic" "frost Paramedic") do (
		for /f "tokens=1,2" %%A in (%%E) do (
			set /a N+=1
			start "" /b cmd /c ""%GODOT%" --headless --path . -s tests/balance.gd -- %HOURS% gate %%B %%A > docs\balance\%%B-%%A-%%S.txt 2>&1 & echo done > docs\balance\%%B-%%A-%%S.done"
		)
	)
)
set /a N+=1
start "" /b cmd /c ""%GODOT%" --headless --path . -s tests/balance.gd -- 0 probe > docs\balance\probe.txt 2>&1 & echo done > docs\balance\probe.done"

echo %N% reads running, %HOURS% simulated hours an element build (%PLAIN_HOURS% a plain one), %READS% reads each. Waiting.
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
