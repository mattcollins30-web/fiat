<#
Runs tools/sound_manifest.json through ElevenLabs' sound-effects API (POST /v1/sound-generation) and music API
(POST /v1/music). The PowerShell port of tools/eleven_batch.py (14 Oct: no Python on Matt's machine) - same manifest,
same key file, same output, same skip-what's-there. Windows PowerShell 5.1, nothing to install.
The key is read from tools/elevenlabs_secret.txt (one line; gitignored) - never printed, never written anywhere else.
Writes art/sound_new/<id>.mp3 and skips what's there.

  powershell -File tools/eleven_batch.ps1                      all of it
  powershell -File tools/eleven_batch.ps1 -DryRun              the list and the seconds, nothing sent
  powershell -File tools/eleven_batch.ps1 -NoMusic             the sound effects only
  powershell -File tools/eleven_batch.ps1 -MusicOnly           the four music tracks only
  powershell -File tools/eleven_batch.ps1 -Only shot_pistol,kill   one sound (all its takes) or one take (shot_pistol_2)
  powershell -File tools/eleven_batch.ps1 -Force               remake even if the file's there (with -Only, usually)
#>
param([switch]$DryRun, [switch]$Force, [switch]$NoMusic, [switch]$MusicOnly, [string[]]$Only = @())

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = "SilentlyContinue"

$Root = Split-Path -Parent $PSScriptRoot
$Manifest = Join-Path $Root "tools\sound_manifest.json"
$Secret = Join-Path $Root "tools\elevenlabs_secret.txt"
$Out = Join-Path $Root "art\sound_new"

function Get-Field($obj, $name, $default) {
    if ($obj.PSObject.Properties.Name -contains $name) { return $obj.$name } else { return $default }
}

$m = [IO.File]::ReadAllText($Manifest, [Text.Encoding]::UTF8) | ConvertFrom-Json
$format = Get-Field $m "output_format" "mp3_44100_128"
$jobs = @($m.jobs | Where-Object { $Only.Count -eq 0 -or $Only -contains $_.id -or $Only -contains $_.sound })
if ($NoMusic) { $jobs = @($jobs | Where-Object { (Get-Field $_ "endpoint" "") -ne "music" }) }
if ($MusicOnly) { $jobs = @($jobs | Where-Object { (Get-Field $_ "endpoint" "") -eq "music" }) }
New-Item -ItemType Directory -Force $Out | Out-Null
$todo = @($jobs | Where-Object { $Force -or -not (Test-Path (Join-Path $Out ($_.id + ".mp3"))) })
$music = @($todo | Where-Object { (Get-Field $_ "endpoint" "") -eq "music" })
$sfxSecs = ($todo | ForEach-Object { [double](Get-Field $_ "duration_seconds" 0) } | Measure-Object -Sum).Sum
$musicSecs = ($music | ForEach-Object { [double](Get-Field $_ "music_length_ms" 0) } | Measure-Object -Sum).Sum / 1000.0
"{0} jobs, {1} to make ({2:0} s of sound, {3:0} s of music), {4} already on disk" -f $jobs.Count, $todo.Count, $sfxSecs, $musicSecs, ($jobs.Count - $todo.Count)

if ($DryRun) {
    foreach ($j in $todo) {
        $isMusic = (Get-Field $j "endpoint" "") -eq "music"
        $secs = if ($isMusic) { [double](Get-Field $j "music_length_ms" 0) / 1000.0 } else { [double](Get-Field $j "duration_seconds" 0) }
        $tag = if ($isMusic) { " music" } elseif (Get-Field $j "loop" $false) { " loop " } else { "      " }
        $text = $j.text; if ($text.Length -gt 70) { $text = $text.Substring(0, 70) }
        "  {0,-22} {1,5:0.0} s{2}  {3}" -f $j.id, $secs, $tag, $text
    }
    exit 0
}
if (-not (Test-Path $Secret)) {
    "No key: put your ElevenLabs API key on one line in tools/elevenlabs_secret.txt"
    exit 1
}
$key = ([IO.File]::ReadAllText($Secret)).Trim()
$made = 0; $failed = @()
for ($n = 0; $n -lt $todo.Count; $n++) {
    $j = $todo[$n]
    if ((Get-Field $j "endpoint" "") -eq "music") {
        $url = "https://api.elevenlabs.io/v1/music?output_format=$format"
        $body = @{ prompt = $j.text; music_length_ms = $j.music_length_ms; force_instrumental = $true
                   model_id = (Get-Field $m "music_model_id" "music_v1") }
    } else {
        $url = "https://api.elevenlabs.io/v1/sound-generation?output_format=$format"
        $body = @{ text = $j.text; duration_seconds = $j.duration_seconds; prompt_influence = $j.prompt_influence
                   model_id = (Get-Field $m "model_id" "eleven_text_to_sound_v2") }
        if (Get-Field $j "loop" $false) { $body.loop = $true }
    }
    $bytes = [Text.Encoding]::UTF8.GetBytes(($body | ConvertTo-Json -Compress))
    $dest = Join-Path $Out ($j.id + ".mp3")
    $part = "$dest.part"
    $headers = @{ "xi-api-key" = $key; "Accept" = "audio/mpeg" }
    for ($attempt = 0; $attempt -lt 3; $attempt++) {
        try {
            Invoke-WebRequest -Uri $url -Method Post -Headers $headers -ContentType "application/json" -Body $bytes `
                -OutFile $part -TimeoutSec 300 -UseBasicParsing     # music takes a while
            Move-Item -Force $part $dest
            $made++
            "[{0}/{1}] {2}  {3} KB" -f ($n + 1), $todo.Count, $j.id, [int]((Get-Item $dest).Length / 1024)
            break
        } catch {
            if (Test-Path $part) { Remove-Item -Force $part }
            $resp = $_.Exception.Response
            if ($resp -ne $null) {
                $code = [int]$resp.StatusCode
                $msg = "$($_.ErrorDetails.Message)"; if ($msg.Length -gt 300) { $msg = $msg.Substring(0, 300) }
                if ($code -eq 429 -and $attempt -lt 2) { "  busy (429), waiting 10 s"; Start-Sleep 10; continue }
                "[{0}/{1}] {2}  FAILED {3}: {4}" -f ($n + 1), $todo.Count, $j.id, $code, $msg
                if ($code -eq 401 -or $code -eq 403) {
                    "The key was refused: check it's in tools/elevenlabs_secret.txt and has Sound Effects and Music access."
                    exit 1
                }
                $failed += $j.id; break
            }
            if ($attempt -lt 2) { Start-Sleep 3; continue }
            "[{0}/{1}] {2}  FAILED: {3}" -f ($n + 1), $todo.Count, $j.id, $_.Exception.Message
            $failed += $j.id
        }
    }
}
$tail = if ($failed.Count) { ": " + ($failed -join " ") } else { "" }
"Done: {0} made, {1} failed{2}" -f $made, $failed.Count, $tail
if ($failed.Count) { exit 2 } else { exit 0 }
