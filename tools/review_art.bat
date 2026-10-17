@echo off
rem The fight art review (17 Oct): every site's fight as the run view draws it, every head
rem at his site, and every gun's hands with its muzzle marked - painted headless, no window.
rem Writes docs\review\sites.png, heads.png, hands.png and site_<key>.png. A few seconds.
setlocal
cd /d "%~dp0.."
set GODOT=godot
if exist tools\godot.txt for /f "usebackq delims=" %%G in ("tools\godot.txt") do set "GODOT=%%~G"
"%GODOT%" --headless --path . -s tools/review_art.gd
echo -^> docs\review\
endlocal
