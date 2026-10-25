# Fiat tooling review (25 Oct)

This review covers the snapshot at `scratchpad/rev/repo`. No repo file was edited. The stray `*-1.gd`/`*-2.gd` copies were ignored.
Effort: S = under an hour, M = an afternoon, L = a day or more. Items are ranked best first. Under the house rule, each one
needs Matt's go-ahead before anyone builds it.

## A. Reliability: lost, stale or hung results

**1. The balance pass deletes the smoke's result.** Effort: S
- Where: `tools/balance.bat` line `del /q docs\balance\*.txt docs\balance\*.done ...`. `tools/watch.bat` runs smoke, then balance, in the same loop pass.
- Why: if a smoke flag and a balance flag are both waiting, the watcher runs the smoke, starts the balance straight away, and the balance deletes `smoke.txt` and `smoke.done` before the cloud reads them. A playtest read's `.done` goes the same way. The wildcard has also forced workarounds, like `ab.cfg` being "not .txt: balance.bat clears those".
- Change: give each job its own folder, e.g. `docs\balance\pass\` (the reads, `.done` files, checkpoint and summary) and `docs\balance\smoke\`. `balance.bat` then clears only `pass\`, and `balance_summary.gd` reads only `pass\`. Its current filter (`every *.txt except smoke.txt and checkpoint.txt`) would also pick up stray `read.bat` outputs as builds.

**2. Results carry no run ID, verdict or code version.** Effort: M
- Where: the `.done` files hold only `%date% %time%` (locale format). `$HOME/flaky/run.sh` lives on the device, outside the repo, and its counter wraps (the 23 Oct runs 61-63 read "green" off files from the 19th).
- Change:
  - The flag's content becomes a run ID that the cloud picks, e.g. `smoke.flag` = `r0412`.
  - The watcher writes `smoke.running` (the ID, start time and Godot PID) while the job runs, then `smoke.done` = `r0412 PASS fails=0 misfits=0 1m31s`.
  - The log is kept as `smoke\r0412.txt`, with the last 20 kept.
  - The watcher touches `watch.alive` on every loop, so a session can see whether the watcher is on before it decides between running the job on Matt's machine and running it in the cloud.
  - `run.sh` moves into `tools/` so it is versioned, and keys on the ID rather than a counter.

**3. Balance reads and the playtest read have no time limit.** Effort: S
- Where: `balance.bat` `:wait` loops until the count of `*.done` reaches N, with no deadline. `playtest.bat` calls Godot bare.
- Why: one hung Godot blocks the watcher for good. Every later flag (smoke included) then sits unserved and nothing says why. `run_limited.ps1` exists and is used only by the smoke.
- Change: launch each read through `run_limited.ps1`, with something like a 2.5 h cap for `one` reads and 20 min for parity, and have it write `.done` with an exit status. Give the wait loop an overall deadline that writes the summary with the missing reads named. The summary already reports "No GATES line in".

**4. 38 Godot processes all start against the project at once.** Effort: S
- Where: `balance.bat` launches 24 one-save reads, 12 parity reads, the probe and the loot read in the same second.
- Why: if a commit brought new art or changed imports, every process may try to re-import into `.godot/imported` at once. That is a race, and it can corrupt the cache or crash reads. The smoke has the same risk the first time it runs after an art commit.
- Change: run `"%GODOT%" --headless --path . --import` once at the top of `balance.bat` and `smoke.bat`.

**5. Lower the smoke's time limit, and kill on silence alone.** Effort: S
- Where: `smoke.bat` calls `run_limited.ps1 -Minutes 25 -Quiet 180`. A silent hang counts only if the log's tail shows a SCRIPT ERROR.
- Why: a smoke takes about 1.5 min, so an infinite loop with no script error costs 25 min of a blocked watcher.
- Change: `-Minutes 8`, plus a kill after about 4 min with no new log output whatever the tail says. Also fix the comment in `smoke.bat` ("About ten minutes").

**6. Results don't record which code they ran on.** Effort: S
- Why: a flag dropped while the bridge is still writing files, or after an uncommitted edit, gives a result for code nobody can name.
- Change: `smoke.bat` and `balance.bat` print `git rev-parse --short HEAD` and the `git status --porcelain` count as their first line. The done line from item 2 repeats them, and `summary.md`'s header names the commit.

## B. Smoke: determinism, structure, speed

**7. The smoke's bot run is capped by wall-clock time and uses random dice.** Effort: S
- Where: `tests/smoke.gd` `_init`: `Time.get_ticks_msec() - t_start < 60000`, then `< 40000`. `Sim._reseed` randomizes unless `Sim.fixed_seed` is set; the smoke never sets it, though `loot_read.gd` and `fingerprint.gd` do.
- Why:
  - In the cloud (about 6x slower) the bot stops at the time cap rather than the depot. Every later area then starts from a different camp, so cloud and local runs test different things.
  - Random dice are what `flaky.diff` and the 33 "flake" comments are about: a red can't be reproduced.
- Change: cap the bot by runs and simulated time only. Set `Sim.fixed_seed` from `-- seed N` (default fixed, `seed random` to explore), and print the seed on the first line so any red can be replayed.

**8. Turn areas into a registry with declared setup and a snapshot and restore around each.** Effort: M
- Where:
  - The 160 `_*_checks` functions are called ad hoc from `_init` and from inside each other. For example, `_web_checks` is called only from `_element_checks`, which first leaves the Doorman's joints closed and the Barracks shown.
  - `_run_only` guesses setup from the first parameter's name (`main`/`sim`/`bk`).
  - 4 areas (`_six`, `_placement`, `_full_art`, `_line_pill`) take extra arguments and can't be run alone.
  - Areas restore state by hand, with about 184 `load_dict` calls.
- Why: `only web` crashes because the web view has no sim until the Barracks has been shown. Leaked state is also why the shared tab once "filled with the smoke's leavings" (the 21 Oct flake). An area that passes alone and an area that passes in the whole run are not the same test today.
- Change: add `const AREAS := [["web", "_web_checks", {"room": "BARRACKS", "camp": "far", "after": "element"}], ...]` and a runner `_area(name)` that:
  - snapshots `sim.to_dict()` and `main.room`;
  - applies the declared setup and calls the function;
  - checks that it reached its end (it returns `true`; a script error returns null, which reports `AREA web DIED`);
  - restores the snapshot and prints `AREA web ok 2.3s` or `AREA web FAIL 3`.
- Add `-- list` to print the area names; today a new session has to grep for them.

**9. Failure lines share no common prefix, and run.sh only greps two of the patterns.** Effort: S
- Where: `_check` prints `CHECK FAILED:`, but 27 bare `push_error` calls in the layout helpers print other text (e.g. "the sheet's X leaves the room", "rail ...: badge overlaps"). `smoke.bat` keeps a list of ten `findstr` phrases to catch them, but `run.sh` greps only `CHECK FAILED\|SCRIPT ERROR`.
- Why: the cloud sees FAIL with no reason lines for misfit failures.
- Change: route every failure through `_fail(msg)`, which prints `FAIL [<area>] msg` with the area from item 8. Both greps then become the single token `FAIL [`, and `smoke.bat`'s keyword list can go.

**10. Skip art checks when the art isn't there, instead of failing them.** Effort: S
- Where: the checks on gang faces, muzzle flashes, Recruit portraits and item pictures (e.g. lines ~5240, 10983, 11038, 13593, 13603). CLAUDE.md asks every session to triage these cloud-only reds by hand.
- Change: detect at start whether the art is present (`ResourceLoader.exists` on a few known files). Route art-dependent checks through `_check_art(ok, msg)`, which prints `SKIP (no art) msg` when the art is absent. A cloud run then reads green or red on its own merits, and the CLAUDE.md paragraph shrinks to one line.

**11. Run the smoke as parallel shards.** Effort: M, after item 8
- Change: `smoke.bat` (and a cloud `smoke.sh`) launch K processes: one for the bot-run path, and the rest each taking a slice of `AREAS` through `only`. Merge the logs and give one verdict. Use per-area timings from item 8 to balance the slices.
- Expected: about 1.5 min down to about 30-40 s on Matt's machine. In the cloud, 10 min should come down to a few minutes, which makes the "watcher off" fallback usable.

**12. Split the 19,400-line, 1.16 MB `tests/smoke.gd` into files.** Effort: L, incremental
- Why:
  - Every launch parses 1.16 MB.
  - gdlint's language server gets 1.5 s for it (item 21).
  - A session has to read huge spans to find one area.
  - Diffs and reviewer passes are expensive.
  - Its largest functions (`_init` 496 lines, `_playtest` 370, `_crates` 354, `_class_skills` 347) are each a file's worth.
- Change: `tests/smoke/<area>.gd` modules (RefCounted) that take a shared context `T` (`check`, `check_fit`, `main`). `smoke.gd` becomes the runner plus the registry. Start with new areas and the five biggest; nothing needs to move all at once.

## C. Balance pass: speed and reproducibility

**13. Throttle the 38 processes into a pool, longest first.** Effort: M
- Where: `balance.bat`'s `start /b` loops.
- Why: 38 processes against 32 hardware threads on the Legion, plus memory and laptop thermals, slows every read. Reads carry wall caps (`7200000` ms), so contention can silently cut reads short.
- Change: a small PowerShell pool with N = cores - 2, ordered by the last pass's `wall_s`, longest first (the summary's "Where the wall went" already has the figures). Total time should be about the same or better, with no thrash.

**14. Seed each read, and record the seed.** Effort: S
- Where: `balance.gd` accepts a fifth argument as a seed, but `balance.bat` never passes one.
- Why: the two reads of a build differ randomly, and a red can't be rerun.
- Change: pass seed = S × 1000 + build index, write it into GATES, and show it in the builds table.

**15. `read.bat` runs the old per-class `gate` mode, not the pass's `one` mode.** Effort: S
- Why: the "one quick read between passes" in CLAUDE.md now reads a different game from the pass (Matt: per-class reads were "effectively a different game").
- Change: switch to `-- <h> one <Class> <element>`, and write to `docs\balance\read\`.

**16. Odds reads take about 35-45% of every read's wall time.** Effort: M
- Where: `summary.md` "Where the wall went", e.g. 1192 of 3340 s and 946 of 2924 s.
- Change: memoise `survival()` per (kit signature, tier, depth, words) inside a step. Prove it changes nothing with `tests/fingerprint.gd` before the pass. This is bot or harness code, so it goes past the reviewer.

## D. summary.md: which reds matter

**17. Label each gate by kind; don't count reds that only lack data.** Effort: S
- Where: the gate table in `tools/balance_summary.gd`. The header says "20 RED" with no breakdown.
- Why: CLAUDE.md says bot-timing gates aren't tuned before a playtest, yet gates 1, 2, 17, P4, 7, 8 and 5 sit beside design gates (P5 stall, 14 cash sink, 15 scrap, parity) with the same RED. P6 reads RED on "faint 0 of 0 (-100%)", which means no data.
- Change:
  - Add a Kind column: `design`, `bot timing (calibrated by Matt's play)`, or `shown`.
  - Header: "20 RED: N design, M bot-timing (not tuned pre-playtest), K no data".
  - Sort design reds first, and print `NO DATA` instead of RED when the sample is empty.

**18. Merge the duplicated gates.** Effort: S
- Where: gate 16 and "Level on entry (as played)"; P1 and "Deaths (as played)"; P2 and "Wounds (as played)". Each pair measures the same thing, so the same fault counts twice towards the reds.
- Change: one row each, with the bot's figure and the feel-gate figure side by side.

**19. Compare each pass with the last one automatically.** Effort: S/M
- Where: `docs/balance/summary_*.md` holds 57 copies kept by hand.
- Change: the summary keeps the previous `summary.json` and adds a "was" column (e.g. `RED → GREEN`, `median 2.3 h (was 2.0)`). Each pass gets archived as `pass/<date>-<commit>/summary.md`, which replaces the hand copies.

**20. Flag anomalous reads, and move the detail out of the main file.** Effort: S
- Anomalies the summary doesn't flag today:
  - The parity row for "Doorman as physical" goes from level 26 to 2, damage 1484 to 378, kit "Grandad's Shotgun, Work jacket". That is a crew swap or reset artefact, and it is passed off as data.
  - The builds table shows level 7 for a read that reached level 50 at 12.3 h, because moves reset the level. The column needs to say so.
  - Gate 11 is vacuous: no build ever enters a third gang.
- Change:
  - Add an "Anomalies" block: level drops, kit reverting to starter gear, `cut_short` reads, empty samples.
  - Collapse odds that are all 100% to "all 100%".
  - Move "Depth clears" (24 lines of 400+ characters) and "Where the wall went" to `summary_detail.md`, so that `summary.md` holds the gates, the anomalies and one narrow builds table.

**21. Put Matt's latest save beside the bot's figures.** Effort: M
- Why: CLAUDE.md says to always read his latest save alongside the bot's. The feel gates are already shared (`feel_gates.gd` judges both).
- Change: `balance.bat` ends by running `playtest_summary.gd` on the newest save in `%APPDATA%\Fiat`, and the summary adds a "Matt" column for the gates both can read.

## E. Safety

**22. PixelLab `--force` can overwrite Matt's painted `art/ui/*.png`.** Effort: S
- Where: `tools/pixellab_batch_v2.gd`. The only guard is "skip if exists", which `--force` turns off, and 20 manifest jobs write under `art/ui/`.
- Change:
  - Never write over an existing `art/ui/*` file, even with `--force`, unless the job carries `"overwrite_painted": true`.
  - Add `--max-usd N`, which stops when the running cost passes N. Cost reports of $0 count as unknown (lessons doc), so cap by job count too.

**23. The secret files sit inside the project folder.** Effort: S
- Where: `res://tools/pixellab_secret.txt` and `tools/elevenlabs_secret.txt`. No `.gitignore` is in the snapshot, so it should be checked on Matt's machine.
- Why: an export preset that includes `*.txt` would ship the key in the game. Staging `tools/` for a cloud session, or a broad `git add`, would carry it off Matt's machine.
- Change: read the keys from `%APPDATA%\Fiat-dev\` or an environment variable (the PixelLab script already accepts `PIXELLAB_SECRET`). Add a git pre-commit hook that refuses any `*secret*` path, and an exclude filter in the export presets.

## F. Lint, clutter, dead tools, onboarding

**24. gdlint can report a false "0".** Effort: S
- Where: `tools/gdlint.py`.
- Why:
  - It waits a fixed 1.5 s per file, then 4 s at the end. A slow file (smoke.gd at 1.1 MB) whose diagnostics arrive late is silently counted clean.
  - It exits 0 even with warnings.
  - It crashes with an IndexError when run without arguments.
- Change: wait until every opened URI has received `publishDiagnostics`, or time out and report "N files not analysed". Exit 1 when the total is above 0 or files went unanalysed. Default the arguments to `tools/godot.txt` and `.`.

**25. `docs/balance` holds 381 entries, mostly scratch.** Effort: S
- Contents:
  - About 150 `.old_done_*` files and `stale/` (216 files).
  - 68 `.diff` files and 55 `xfer_*` files, including 1 MB copies of smoke and sim `.gd` files with `.uid`s.
  - `smoke_head.gd` and `barracks.gd`/`missions.gd` copies.
  - 5 MB of `.tar`.
  - `pass25..30` and `x12..x26`.
- Why: the `.gd` copies inside `res://` get scanned and uid'd by the editor (and may throw parse noise). A session also has to tell results from scratch.
- Change: add a `.gdignore` in `docs/`. `FileAccess` still works there, so the reads and the summary are unaffected. Move the scratch into `docs/balance/archive/` or delete it.

**26. Dead or duplicate tools to remove (Matt's call).** Effort: S
- `tools/eleven_batch.py`: superseded by the `.ps1`, since there is no Python on Matt's machine. `make_sound_manifest.py` still prints the `python tools/eleven_batch.py` instruction.
- `tools/__pycache__`, `tests/smoke.gd.tmp` (0 bytes).
- `tests/shot.gd`, `shot_rooms.gd`, `shot_title.gd`, `deck.gd`, `clip_probe.gd`, `crate_probe.gd`: one-offs referenced only in status.md. Move them to `tests/scratch/`. Keep `fingerprint.gd`, which item 16 uses.
- `tools/make_hands_test_saves.gd` and `make_intro_manifest.py` are unreferenced.
- The 55 manifests and 21 generators that have already run: move to `tools/art/done/` with a one-line index (date, cost, files).
- The A/B switches (`ab.cfg`, which is empty, plus `Items.fixed_uniques` and `Sim.lorry_mult_off`) and `feel_gates.gd`'s "away" branch: offline play was removed on 24 Oct.

**27. A new session has to read a 6,863-line `docs/status.md`.** Effort: S
- Why: CLAUDE.md says to read "the newest entries" after a compaction, which is expensive and easy to get wrong.
- Change: keep a "Now" block of about 40 lines at the top (milestone, version, open parked items, last smoke and pass IDs), and move older entries to `docs/status_archive.md`.

**28. Add a "tools at a glance" table to CLAUDE.md.** Effort: S
- Contents: each tool, its one command, where its output lands, how long it takes, and its known false reds. Include `-- list` and `only` (item 8), the run-ID protocol (item 2), and the rule that art-absent checks print SKIP (item 10). That removes most of the cloud-session paragraph.
