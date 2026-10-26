@echo off
rem The balance pass, in one command: the one-save reads, the parity reads, then the summary (25 Oct, the endgame
rem chase's step 8: Matt, the per-class reads were "effectively a different game" once the classes opened through
rem the campaign and swapped freely).
rem   tools\balance.bat           thirty-two simulated hours a one-save read (the chase's pass)
rem   tools\balance.bat 8         eight hours a read
rem   tools\balance.bat 32 3      thirty-two hours, three reads a build
rem   tools\balance.bat 16 0 broken   the six broken builds alone, 16 h each with their plain baselines, from the pass's
rem                                  checkpoint (made first if missing): docs\balance\broken.md, the pass's own files left
rem First the checkpoint: one save from a new game (the Poacher) to the Radio's opening, written to
rem docs\balance\radio_checkpoint.save. Then side by side:
rem - the twelve element builds, each its own one save: from the Poacher, its class taken the hour it opens (its head
rem   beaten, or Kev's first story for the Drifter), the crew's swaps after - twice each (READS); every gate judges them;
rem - the parity reads: every build four hours from the checkpoint, the same world (docs\balance\parity-*.txt);
rem - the loot probe and the loot read.
rem Each writes docs\balance\pass\<build>-N.txt (the pass's own folder, 25 Oct: the smoke's log and the playtest read
rem stay where they are); every read runs under a time limit (tools\balance_read.bat); the summary lands in
rem docs\balance\summary.md. The pass's names go in pass\expected.txt and each read's .done says how it ended, so the
rem summary names a read that was killed, crashed, never wrote or was still going at the deadline (25 Oct, the tools review).
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
if /i "%~3"=="broken" goto broken_only
del /q docs\balance\pass\*.* 2>nul
rem and what the pass writes outside pass\ (25 Oct, the tools review: a failed loot read or summary left last pass's in place)
del /q docs\balance\summary.md 2>nul
del /q docs\balance\loot_read.md 2>nul
rem the import once, before the reads start side by side (the tools review: forty processes importing at once race)
powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_limited.ps1 -Godot "%GODOT%" -GodotArgs "--headless --path . --import" -Log docs\balance\pass\import.log -Minutes 5 -Quiet 120
for /f %%C in ('git rev-parse --short HEAD 2^>nul') do echo The pass on %%C> docs\balance\pass\commit.log

echo The checkpoint: a new game to the Radio's opening, Matt's route (the Poacher, then the Drifter as fire).
call tools\balance_read.bat checkpoint 90 40 one Drifter fire 0 checkpoint
rem its .done kept as .end, so it doesn't count towards N but the summary still reads how it ended
ren docs\balance\pass\checkpoint.done checkpoint.end 2>nul
if not exist docs\balance\pass\radio_checkpoint.save echo No checkpoint written (see docs\balance\pass\checkpoint.txt): the parity reads will say so.

set N=0
for /l %%S in (1,1,%READS%) do (
	for %%E in ("fire Drifter" "bleed Drifter" "poison Poacher" "frost Poacher" "bleed Doorman" "physical Doorman" "shock Scrapper" "fire Scrapper" "shock Paramedic" "frost Paramedic" "physical Recruit" "poison Recruit") do (
		for /f "tokens=1,2" %%A in (%%E) do (
			set /a N+=1
			>>docs\balance\pass\expected.txt echo %%B-%%A-%%S
			start "" /b cmd /c tools\balance_read.bat %%B-%%A-%%S 240 %HOURS% one %%B %%A
		)
	)
)
rem the parity reads twice a build (25 Oct, the second review: one death decided a 4 h read); the summary takes their mean
for /l %%S in (1,1,2) do (
	for %%E in ("fire Drifter" "bleed Drifter" "poison Poacher" "frost Poacher" "bleed Doorman" "physical Doorman" "shock Scrapper" "fire Scrapper" "shock Paramedic" "frost Paramedic" "physical Recruit" "poison Recruit") do (
		for /f "tokens=1,2" %%A in (%%E) do (
			set /a N+=1
			>>docs\balance\pass\expected.txt echo parity-%%B-%%A-%%S
			start "" /b cmd /c tools\balance_read.bat parity-%%B-%%A-%%S 60 %PARITY_HOURS% parity %%B %%A
		)
	)
)
rem the broken builds (26 Oct, Matt: "test they are broken and can smash all content at least once"): outside the
rem balance, each its own read from the checkpoint, the combos on for it alone (tests\balance.gd _broken); the summary
rem lists what each beat and what it never did, no gate
set BROKEN_HOURS=16
for %%K in (embers clean_kills flatline opened_for_good live_load drilled) do (
	set /a N+=2
	>>docs\balance\pass\expected.txt echo broken-%%K
	>>docs\balance\pass\expected.txt echo broken-%%K-plain
	start "" /b cmd /c tools\balance_read.bat broken-%%K 240 %BROKEN_HOURS% broken %%K
	start "" /b cmd /c tools\balance_read.bat broken-%%K-plain 240 %BROKEN_HOURS% broken %%K plain
)
set /a N+=1
>>docs\balance\pass\expected.txt echo probe
start "" /b cmd /c tools\balance_read.bat probe 30 0 probe
rem the loot read (15 Oct): gates 12 and 13 read its tables, docs\balance\loot_read.md; under a time limit as the
rem rest (25 Oct, the tools review: it was the one read the deadline could catch), its log pass\loot_read.txt
set /a N+=1
>>docs\balance\pass\expected.txt echo loot_read
start "" /b cmd /c tools\balance_read.bat loot_read 60 script tests/loot_read.gd

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
	rem the summary names the reads still going (no .done) as still going at the deadline
	>docs\balance\pass\deadline.log echo The pass ran past five hours at %date% %time%
	goto summary
)
if %DONE% lss %N% goto wait
:summary

"%GODOT%" --headless --path . -s tools/balance_summary.gd
if errorlevel 1 (
	echo The summary failed; the raw reads are in docs\balance\pass\*.txt all the same.
	exit /b 1
)
echo Done: docs\balance\summary.md
endlocal
exit /b 0

:broken_only
rem the broken builds alone (26 Oct, Matt): each with its plain baseline, from the pass's checkpoint; the pass's own reads
rem and summary stay as they were
rem the import once first, as the full pass does (concurrent imports race: the review)
powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_limited.ps1 -Godot "%GODOT%" -GodotArgs "--headless --path . --import" -Log docs\balance\pass\import.log -Minutes 5 -Quiet 120
del /q docs\balance\pass\broken-*.* 2>nul
del /q docs\balance\broken.md 2>nul
for /f %%C in ('git rev-parse --short HEAD 2^>nul') do echo The broken reads on %%C> docs\balance\pass\broken_commit.log
if not exist docs\balance\pass\radio_checkpoint.save (
	echo No checkpoint from a pass: making one first.
	call tools\balance_read.bat checkpoint 90 40 one Drifter fire 0 checkpoint
	ren docs\balance\pass\checkpoint.done checkpoint.end 2>nul
)
set N=0
for %%K in (embers clean_kills flatline opened_for_good live_load drilled) do (
	set /a N+=2
	start "" /b cmd /c tools\balance_read.bat broken-%%K 240 %HOURS% broken %%K
	start "" /b cmd /c tools\balance_read.bat broken-%%K-plain 240 %HOURS% broken %%K plain
)
echo %N% broken-build reads running, %HOURS% h each. Waiting.
set TICKS=0
:bwait
timeout /t 10 /nobreak >nul
set /a TICKS+=1
set DONE=0
for %%F in (docs\balance\pass\broken-*.done) do set /a DONE+=1
echo   %DONE% of %N% finished
if %TICKS% geq 1800 goto bsummary
if %DONE% lss %N% goto bwait
:bsummary
"%GODOT%" --headless --path . -s tools/balance_summary.gd -- broken
echo Done: docs\balance\broken.md
endlocal
