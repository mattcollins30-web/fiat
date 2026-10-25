@echo off
rem The balance pass, in one command: the one-save reads, the parity reads, then the summary (25 Oct, the endgame
rem chase's step 8: Matt, the per-class reads were "effectively a different game" once the classes opened through
rem the campaign and swapped freely).
rem   tools\balance.bat           thirty-two simulated hours a one-save read (the chase's pass)
rem   tools\balance.bat 8         eight hours a read
rem   tools\balance.bat 32 3      thirty-two hours, three reads a build
rem First the checkpoint: one save from a new game (the Poacher) to the Radio's opening, written to
rem docs\balance\radio_checkpoint.save. Then side by side:
rem - the twelve element builds, each its own one save: from the Poacher, its class taken the hour it opens (its head
rem   beaten, or Kev's first story for the Drifter), the crew's swaps after - twice each (READS); every gate judges them;
rem - the parity reads: every build four hours from the checkpoint, the same world (docs\balance\parity-*.txt);
rem - the loot probe and the loot read.
rem Each writes docs\balance\pass\<build>-N.txt (the pass's own folder, 25 Oct: the smoke's log and the playtest read
rem stay where they are); every read runs under a time limit (tools\balance_read.bat); the summary lands in
rem docs\balance\summary.md.
rem Godot: the path in tools\godot.txt if that file exists (point it at the
rem _console.exe so the output reaches the files), else "godot" on the PATH.
setlocal enabledelayedexpansion
cd /d "%~dp0.."
set HOURS=%1
if "%HOURS%"=="" set HOURS=32
set READS=%2
if "%READS%"=="" set READS=2
set PARITY_HOURS=4
set GODOT=godot
if exist tools\godot.txt for /f "usebackq delims=" %%G in ("tools\godot.txt") do set "GODOT=%%~G"
if not "%GODOT%"=="godot" if not exist "%GODOT%" (
	echo Godot not found at "%GODOT%"; fix tools\godot.txt.
	exit /b 1
)
if not exist docs\balance mkdir docs\balance
if not exist docs\balance\pass mkdir docs\balance\pass
del /q docs\balance\pass\*.* 2>nul
rem the import once, before the reads start side by side (the tools review: forty processes importing at once race)
powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_limited.ps1 -Godot "%GODOT%" -GodotArgs "--headless --path . --import" -Log docs\balance\pass\import.log -Minutes 5 -Quiet 120
for /f %%C in ('git rev-parse --short HEAD 2^>nul') do echo The pass on %%C> docs\balance\pass\commit.log

echo The checkpoint: a new game to the Radio's opening, Matt's route (the Poacher, then the Drifter as fire).
call tools\balance_read.bat checkpoint 90 40 one Drifter fire 0 checkpoint
del /q docs\balance\pass\checkpoint.done 2>nul
if not exist docs\balance\pass\radio_checkpoint.save echo No checkpoint written (see docs\balance\pass\checkpoint.txt): the parity reads will say so.

set N=0
for /l %%S in (1,1,%READS%) do (
	for %%E in ("fire Drifter" "bleed Drifter" "poison Poacher" "frost Poacher" "bleed Doorman" "physical Doorman" "shock Scrapper" "fire Scrapper" "shock Paramedic" "frost Paramedic" "physical Recruit" "poison Recruit") do (
		for /f "tokens=1,2" %%A in (%%E) do (
			set /a N+=1
			start "" /b cmd /c tools\balance_read.bat %%B-%%A-%%S 240 %HOURS% one %%B %%A
		)
	)
)
for %%E in ("fire Drifter" "bleed Drifter" "poison Poacher" "frost Poacher" "bleed Doorman" "physical Doorman" "shock Scrapper" "fire Scrapper" "shock Paramedic" "frost Paramedic" "physical Recruit" "poison Recruit") do (
	for /f "tokens=1,2" %%A in (%%E) do (
		set /a N+=1
		start "" /b cmd /c tools\balance_read.bat parity-%%B-%%A 60 %PARITY_HOURS% parity %%B %%A
	)
)
set /a N+=1
start "" /b cmd /c tools\balance_read.bat probe 30 0 probe
rem the loot read (15 Oct): gates 12 and 13 read its tables, docs\balance\loot_read.md
set /a N+=1
start "" /b cmd /c ""%GODOT%" --headless --path . -s tests/loot_read.gd > docs\balance\pass\loot_read.log 2>&1 & echo done > docs\balance\pass\loot_read.done"

echo %N% reads running, %HOURS% simulated hours a one-save read, %READS% reads each, %PARITY_HOURS% h a parity read. Waiting.
set TICKS=0
:wait
timeout /t 10 /nobreak >nul
set /a TICKS+=1
set DONE=0
for %%F in (docs\balance\pass\*.done) do set /a DONE+=1
echo   %DONE% of %N% finished
rem a deadline over the whole wait (the tools review): five hours, then the summary names what didn't finish
if %TICKS% geq 1800 (
	echo The pass ran past five hours: summarising what finished.
	goto summary
)
if %DONE% lss %N% goto wait
:summary

"%GODOT%" --headless --path . -s tools/balance_summary.gd
if errorlevel 1 (
	echo The summary failed; the raw reads are in docs\balance\*.txt all the same.
	exit /b 1
)
echo Done: docs\balance\summary.md
endlocal
