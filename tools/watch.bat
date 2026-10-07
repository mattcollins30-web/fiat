@echo off
rem The watcher (7 Oct): leave this window open and Claude starts the smoke and
rem the balance pass from here without you - it drops a flag file in
rem docs\balance and this runs the job, then writes a .done file it reads.
rem   docs\balance\smoke.flag              -> tools\smoke.bat
rem   docs\balance\balance.flag (hours in) -> tools\balance.bat <hours>
rem Ctrl+C to stop. Keep the machine awake (power settings) for the pass.
setlocal enabledelayedexpansion
cd /d "%~dp0.."
if not exist docs\balance mkdir docs\balance
echo Watching docs\balance for smoke.flag and balance.flag. Ctrl+C to stop.
:loop
if exist docs\balance\smoke.flag (
	del /q docs\balance\smoke.flag
	echo %date% %time%  smoke starting
	call tools\smoke.bat
	echo %date% %time% > docs\balance\smoke.done
	echo %date% %time%  smoke done
)
if exist docs\balance\balance.flag (
	set "HOURS="
	set /p HOURS=<docs\balance\balance.flag
	del /q docs\balance\balance.flag
	echo %date% %time%  balance starting ^(!HOURS! hours^)
	call tools\balance.bat !HOURS!
	echo %date% %time% > docs\balance\balance.done
	echo %date% %time%  balance done
)
timeout /t 15 /nobreak >nul
goto loop
