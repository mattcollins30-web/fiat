# Runs Godot with a time limit (13 Oct): a script error in a headless test leaves Godot running with nothing to do,
# and the watcher waited on it for ever. This starts it with its log, and kills it (and anything it started) when
# it goes past -Minutes, or when the log shows a SCRIPT ERROR and then nothing new for -Quiet seconds.
param(
	[string]$Godot,
	[string]$GodotArgs,
	[string]$Log,
	[int]$Minutes = 15,
	[int]$Quiet = 60
)
$cmd = '"' + $Godot + '" ' + $GodotArgs + ' > "' + $Log + '" 2>&1'
$p = Start-Process -FilePath $env:ComSpec -ArgumentList ('/c "' + $cmd + '"') -PassThru -WindowStyle Hidden
$deadline = (Get-Date).AddMinutes($Minutes)
$lastSize = -1
$quietSince = Get-Date
$why = ""
while (-not $p.HasExited) {
	Start-Sleep -Seconds 5
	$size = 0
	if (Test-Path $Log) { $size = (Get-Item $Log).Length }
	if ($size -ne $lastSize) { $lastSize = $size; $quietSince = Get-Date }
	if ((Get-Date) -gt $deadline) { $why = "ran past $Minutes minutes"; break }
	if ((Test-Path $Log) -and ((Get-Date) - $quietSince).TotalSeconds -ge $Quiet) {
		# stuck only when a script error is what the log ended on: a smoke carries on past one that isn't fatal
		if (Get-Content -Path $Log -Tail 12 | Select-String -Pattern "SCRIPT ERROR" -Quiet) { $why = "stopped on a script error"; break }
	}
}
if ($why -ne "") {
	& taskkill /T /F /PID $p.Id | Out-Null
	if ($LASTEXITCODE -ne 0) {
		# only when the tree kill failed: a Godot started under this cmd, never an editor opened alongside
		Get-CimInstance Win32_Process -Filter "ParentProcessId = $($p.Id)" -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
	}
	Add-Content -Path $Log -Value "SCRIPT ERROR: the watcher killed Godot: it $why"
	Add-Content -Path $Log -Value "FAIL: the run did not finish"
}
