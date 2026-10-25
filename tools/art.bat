@echo off
rem One art manifest through the PixelLab batch, the dry run first (25 Oct, the tools review item 13):
rem   tools\art.bat <manifest> [extra batch args]
rem   <manifest>: boss_backdrops, pixellab_boss_backdrops_manifest.json, tools\pixellab_..., or res://tools/...
rem   extra args go to tools/pixellab_batch_v2.gd as they are: --only <name>  --force  --parallel <N>  (a "++" is dropped)
rem e.g. tools\art.bat boss_backdrops_test      tools\art.bat boss_backdrops --only the_manager_plate --force
rem The dry run lists what would be made (what's on disk is skipped); then it asks, and only a "y" spends credits.
rem Logs: docs\art\handoff\<manifest>.dry.log and <manifest>.log (the real run's, with its "Done: ... Batch cost" line).
rem Run python3 tools/art_lint.py over a new manifest before it comes here.
setlocal EnableExtensions
cd /d "%~dp0.."
set GODOT=godot
if exist tools\godot.txt for /f "usebackq delims=" %%G in ("tools\godot.txt") do set "GODOT=%%~G"
if "%~1"=="" goto usage

set "ARG=%~1"
set "ARG=%ARG:/=\%"
if /i "%ARG:~0,6%"=="res:\\" set "ARG=%ARG:~6%"
for %%F in ("%ARG%") do set "NAME=%%~nxF"
for %%F in ("%ARG%") do set "EXT=%%~xF"
if /i not "%EXT%"==".json" (
	if exist "tools\pixellab_%NAME%_manifest.json" (set "NAME=pixellab_%NAME%_manifest.json") else (set "NAME=%NAME%.json")
)
if not exist "tools\%NAME%" (
	echo No manifest tools\%NAME% - give its name ^(boss_backdrops^) or its file in tools\.
	exit /b 2
)

set "EXTRA="
set "DRYONLY="
:args
shift
if "%~1"=="" goto argsdone
if "%~1"=="++" goto args
if /i "%~1"=="--dry-run" (set "DRYONLY=1" & goto args)
set "EXTRA=%EXTRA% %1"
goto args
:argsdone

set "LOGDIR=docs\art\handoff"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
set "BASE=%NAME:~0,-5%"
set "DRY=%LOGDIR%\%BASE%.dry.log"
set "LOG=%LOGDIR%\%BASE%.log"

echo Dry run: tools\%NAME%%EXTRA%
"%GODOT%" --headless --path . --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/%NAME% --dry-run%EXTRA% > "%DRY%" 2>&1
set "RC=%ERRORLEVEL%"
type "%DRY%"
echo.
if not "%RC%"=="0" (
	echo The dry run failed ^(exit %RC%^) - see %DRY%. Nothing was run.
	exit /b %RC%
)
set "TODO=0"
set "SKIP=0"
for /f %%N in ('find /c "  would " ^< "%DRY%"') do set "TODO=%%N"
for /f %%N in ('find /c "  skip (exists)" ^< "%DRY%"') do set "SKIP=%%N"
findstr /c:"PixelLab v2 batch" "%DRY%"
echo To make: %TODO% job(s). Already on disk, skipped: %SKIP%.
findstr /i /c:"estimat" "%DRY%" >nul && (findstr /i /c:"estimat" "%DRY%") || echo Cost: the batch gives no estimate on a dry run; the real run prints its cost in the Done line.
if "%TODO%"=="0" (
	echo Nothing to make.
	exit /b 0
)
if defined DRYONLY exit /b 0

set "ANS="
set /p "ANS=Run it? (y/n) "
if /i not "%ANS%"=="y" (
	echo Not run.
	exit /b 1
)
echo Running: tools\%NAME%%EXTRA%   ^(log: %LOG%^)
"%GODOT%" --headless --path . --log-file "%LOG:\=/%" --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/%NAME%%EXTRA%
set "RC=%ERRORLEVEL%"
echo.
findstr /c:"Done:" "%LOG%"
echo Exit %RC%. Log: %LOG%
exit /b %RC%

:usage
echo Usage: tools\art.bat ^<manifest^> [--only ^<name^>] [--force] [--parallel ^<N^>] [--dry-run]
echo   ^<manifest^>: e.g. boss_backdrops or pixellab_boss_backdrops_manifest.json ^(in tools\^)
exit /b 2
