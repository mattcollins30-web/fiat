@echo off
rem The balance pass, in one command: the one-save reads, the parity reads, then the summary (25 Oct, the endgame
rem chase's step 8: Matt, the per-class reads were "effectively a different game" once the classes opened through
rem the campaign and swapped freely).
rem   tools\balance.bat           thirty-two simulated hours a one-save read (the chase's pass)
rem   tools\balance.bat 8         eight hours a read
rem   tools\balance.bat 32 3      thirty-two hours, three reads a build
rem   tools\balance.bat 16 1 quick  the quick pass for iterating (28 Oct, Matt: "buy time on balance passes"): each
rem                                  one-save read stopped at 20 minutes of wall (its GATES line says where), no gauntlet
rem   tools\balance.bat 0 0 broken    the six broken builds' gauntlets alone, from the last pass's end states (a pass
rem                                  first): docs\balance\broken.md, the pass's own files left
rem   tools\balance.bat 0 0 gauntlet  the gauntlet alone (27 Oct, the retune): every build's as played and the six pinnacle
rem                                  builds', from the last pass's end states, then the summary; the pass's other reads kept
rem   tools\balance.bat 2 0 hunt     the build hunt (26 Oct, Matt): stage 1 (every joint with every set or none), stage 2 (stage
rem                                  1's best twenty with every unique that fits), each read 2 h; then stage 2's best six
rem                                  through the gauntlet from the last pass's end states: docs\balance\hunt.md
rem After the one-save reads, the gauntlet (26 Oct, Matt): each build's end state through the endgame in order, as played
rem and with the six broken builds' pieces on (tests\balance.gd _gauntlet); the summary's two tables.
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
rem a flag it can't read deletes nothing (the third review: a typo fell through to the full pass and wiped pass\)
del /q docs\balance\flag_error.txt 2>nul
echo %HOURS%| findstr /r "^[0-9][0-9]*$ ^[0-9][0-9]*\.[0-9][0-9]*$" >nul || goto badflag
echo %READS%| findstr /r "^[0-9][0-9]*$" >nul || goto badflag
if not "%~3"=="" if /i not "%~3"=="broken" if /i not "%~3"=="hunt" if /i not "%~3"=="gauntlet" if /i not "%~3"=="quick" goto badflag
set CAPARG=
if /i "%~3"=="quick" set CAPARG=cap20
if /i "%~3"=="broken" goto broken_only
if /i "%~3"=="gauntlet" goto gauntlet_only
if /i "%~3"=="hunt" goto hunt
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
			start "" /b cmd /c tools\balance_read.bat %%B-%%A-%%S 240 %HOURS% one %%B %%A 0 read%%S %CAPARG%
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
	goto gauntlets
)
if %DONE% lss %N% goto wait
:gauntlet_only
if /i not "%~3"=="gauntlet" goto gauntlets
if not exist docs\balance\pass\*.save (
	>docs\balance\flag_error.txt echo No end states in docs\balance\pass: a full pass first.
	exit /b 1
)
del /q docs\balance\pass\gauntlet-*.* 2>nul
del /q docs\balance\pass\broken-*.* 2>nul
if exist docs\balance\pass\expected.txt (
	findstr /v /b "gauntlet- broken-" docs\balance\pass\expected.txt > docs\balance\pass\expected.tmp
	move /y docs\balance\pass\expected.tmp docs\balance\pass\expected.txt >nul
)
for /f %%C in ('git rev-parse --short HEAD 2^>nul') do echo The gauntlet on %%C>> docs\balance\pass\commit.log
:gauntlets
rem the quick pass has no gauntlet (28 Oct): straight to the summary
if /i "%~3"=="quick" goto summary
rem the gauntlet (26 Oct, Matt: "test they are broken and can smash all content at least once"; its kit "the final
rem pass's end states"): each build's end state as played, and the six broken builds' pieces on their class's
rem each twice (27 Oct, Matt): the summary takes the better of the two, a build's run of luck either way read out
for /l %%S in (1,1,2) do (
	for %%E in ("fire Drifter" "bleed Drifter" "poison Poacher" "frost Poacher" "bleed Doorman" "physical Doorman" "shock Scrapper" "fire Scrapper" "shock Paramedic" "frost Paramedic" "physical Recruit" "poison Recruit") do (
		for /f "tokens=1,2" %%A in (%%E) do (
			>>docs\balance\pass\expected.txt echo gauntlet-%%B-%%A-%%S
			start "" /b cmd /c tools\balance_read.bat gauntlet-%%B-%%A-%%S 60 0 gauntlet %%B %%A
		)
	)
	for %%K in (embers clean_kills flatline opened_for_good live_load drilled) do (
		>>docs\balance\pass\expected.txt echo broken-%%K-%%S
		start "" /b cmd /c tools\balance_read.bat broken-%%K-%%S 60 0 broken %%K
	)
)
echo The gauntlet: 36 reads running.
call :waitfor "gauntlet-*.done" 24 400
call :waitfor "broken-*.done" 12 400
:summary

"%GODOT%" --headless --path . -s tools/balance_summary.gd
if errorlevel 1 (
	echo The summary failed; the raw reads are in docs\balance\pass\*.txt all the same.
	exit /b 1
)
echo Done: docs\balance\summary.md
endlocal
exit /b 0

:hunt
rem the build hunt (26 Oct, Matt: "cook some different builds up"): twelve shards a stage side by side, each stage waiting on
rem the last (stage 2's list is made from stage 1's lines), then the finalists; the pass's own reads and summary left
powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_limited.ps1 -Godot "%GODOT%" -GodotArgs "--headless --path . --import" -Log docs\balance\pass\import.log -Minutes 5 -Quiet 120
del /q docs\balance\pass\hunt-*.* 2>nul
del /q docs\balance\pass\broken-*.* 2>nul
del /q docs\balance\hunt.md 2>nul
for /f %%C in ('git rev-parse --short HEAD 2^>nul') do echo The build hunt on %%C> docs\balance\pass\broken_commit.log
if not exist docs\balance\pass\radio_checkpoint.save (
	echo No checkpoint from a pass: making one first.
	call tools\balance_read.bat checkpoint 90 40 one Drifter fire 0 checkpoint
	ren docs\balance\pass\checkpoint.done checkpoint.end 2>nul
)
for %%G in (1 2) do (
	for /l %%S in (0,1,11) do start "" /b cmd /c tools\balance_read.bat hunt-s%%G-%%S 300 %HOURS% hunt %%G %%S 12
	echo Stage %%G of the hunt: 12 shards running, %HOURS% h a build.
	call :waitfor "hunt-s%%G-*.done" 12 1900
)
for /l %%N in (0,1,5) do start "" /b cmd /c tools\balance_read.bat broken-hunt%%N 60 0 broken hunt%%N
echo The hunt's six finalists through the gauntlet.
call :waitfor "broken-*.done" 6 400
"%GODOT%" --headless --path . -s tools/balance_summary.gd -- hunt
echo Done: docs\balance\hunt.md
endlocal
exit /b 0

rem wait for <pattern> in pass\ to reach <count>, or <ticks> of ten seconds
:waitfor
set TICKS=0
:wf_loop
timeout /t 10 /nobreak >nul
set /a TICKS+=1
set DONE=0
for %%F in (docs\balance\pass\%~1) do set /a DONE+=1
echo   %DONE% of %~2 finished
if %TICKS% geq %~3 exit /b 0
if %DONE% lss %~2 goto wf_loop
exit /b 0

:badflag
echo Bad flag: "%*" - expected ^<hours^> [reads] [broken^|hunt]. Nothing was run or deleted.
>docs\balance\flag_error.txt echo bad flag: "%*" - expected ^<hours^> [reads] [broken^|hunt]; nothing run or deleted
endlocal
exit /b 1

:broken_only
rem the broken builds' gauntlets alone (26 Oct, Matt): from the last pass's end states; the pass's own reads and summary
rem stay as they were
if not exist docs\balance\pass\Drifter-fire-1.save if not exist docs\balance\pass\Drifter-fire-2.save (
	echo No end states from a pass: run a full pass first.
	>docs\balance\flag_error.txt echo no end states in pass\ for the broken builds' gauntlets: run a full pass first
	endlocal
	exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File tools\run_limited.ps1 -Godot "%GODOT%" -GodotArgs "--headless --path . --import" -Log docs\balance\pass\import.log -Minutes 5 -Quiet 120
del /q docs\balance\pass\broken-*.* 2>nul
del /q docs\balance\broken.md 2>nul
for /f %%C in ('git rev-parse --short HEAD 2^>nul') do echo The broken builds' gauntlets on %%C> docs\balance\pass\broken_commit.log
for %%K in (embers clean_kills flatline opened_for_good live_load drilled) do start "" /b cmd /c tools\balance_read.bat broken-%%K 60 0 broken %%K
echo Six gauntlets running.
call :waitfor "broken-*.done" 6 400
"%GODOT%" --headless --path . -s tools/balance_summary.gd -- broken
echo Done: docs\balance\broken.md
endlocal
