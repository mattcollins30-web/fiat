# Fiat tooling re-review (25 Oct, after the second pass)

This covers the snapshot at `scratchpad/fiatnow` and the diff `rr/second_pass.diff`. No repo file was edited and nothing was run against the repo. `docs/art/` (pixellab_lessons.md and the handoff) and `docs/status.md` are missing from the snapshot, so I couldn't check them.
Effort: S = under an hour, M = an afternoon, L = a day or more. Items are ranked best first. Under the house rule, each one needs Matt's go-ahead before anyone builds it.

## A. Checking the changes that went in

What's sound:
- The pass folder works. `balance.bat:33-34` clears only `pass\`, the summary reads only `pass\` (`balance_summary.gd:15`), the smoke and playtest results are no longer deleted, and the checkpoint's `.done` is removed so it doesn't count towards N (`balance.bat:41`).
- Every `balance.gd` read goes through `balance_read.bat`, and the import is time-limited (`balance.bat:36`).
- Gate kinds add up: 9 design + 5 bot timing + 5 bot play = 19, which matches the header.
- `-- seed` and `-- only` work together (`smoke.gd` `_only_areas`).

What doesn't:

**1. Gate 17 is RED because the window is in hand hours and the display rounds.** Effort: S
- Where: `balance_summary.gd:41` `GK := [0.3, 0.5]`, then `:428-432`.
- Why:
  - The verdict is `gk_med >= 0.3`, but `_hours()` prints `%.1f`. A median of 0.25-0.29 h therefore prints as "0.3 h" and fails. The level part passes (it shows level 3), so the hours part is what fails.
  - The real error is in the window. Every other hand figure is scaled by `BOT_PACE` (`:31-33` BANK, QM, LORRY), but GK is Matt's "about 25 minutes" by hand, unscaled. At 0.85 the bot's window is **0.26-0.43 h**, and the read (0.2-0.4 h, median just under 0.3) would be GREEN.
- Change: `GK := [HAND_GK[0] * BOT_PACE, HAND_GK[1] * BOT_PACE]`. Print windows under an hour in minutes (`_mins`) so the number shown is the number judged.

**2. Gate 11 '—' is structural: this bot can never reach a third gang.** Effort: S (the label) / M (the bot)
- Where: `bot.gd:249` `should_leave` returns true at `m["patrols"] >= 2`. `balance.gd:330` counts `gang3_runs` only at `patrols >= 3`. Boss runs are the only exception (`bot.gd:247`).
- Why: the gate has nothing to read, and greed's quality bonus (the smoke checks `greed_gangs`) is never used by the bot. The header's "19 RED" doesn't say that one gate went unjudged.
- Change: the header adds "1 not judged (11: the bot leaves at the second gang)". The bot fix is in item 9.

**3. A killed read goes into the summary as "crashed", with no reason given.** Effort: S
- Where:
  - `run_limited.ps1:34-35` appends "the watcher killed Godot: it ran past N minutes", but always exits 0.
  - `balance_read.bat:10` writes `done` whatever happened.
  - `balance_summary.gd:111` says "the read crashed or was cut short".
- Why:
  - Killed, crashed and still-running-at-the-deadline reads all print the same message.
  - The build's gates are then judged on its one remaining read without saying so. The header just reads "23 reads".
  - A read that never wrote a `.txt` (PowerShell blocked, say) isn't named at all, because the summary only knows the files it finds.
- Change:
  - `run_limited.ps1` ends with `exit 3` when it kills.
  - `balance_read.bat` writes `%ERRORLEVEL%` and the reason into `<name>.done`.
  - `balance.bat` writes `pass\expected.txt` (the 38 names).
  - The summary names every expected read as one of: missing, killed (with the reason), unfinished, or no GATES line. It also marks builds judged on 1 of 2 reads.

**4. The 5 h deadline leaves the stragglers running.** Effort: S
- Where: `balance.bat:74-77` jumps to `:summary`, which doesn't kill anything.
- Why:
  - Every `balance.gd` read is capped below the deadline (240 min one-save, 60 parity, 30 probe). So in practice the deadline only fires for the loot read, which has **no limit** (`balance.bat:63`, still a bare `cmd /c`), or for a hung PowerShell.
  - The leftover Godot keeps running after `balance.done`. The next smoke then runs beside it, and the next pass's `del /q pass\*.*` fails on its locked log.
- Change: run the loot read through `run_limited.ps1` too. `balance_read.bat` can take the script as a parameter, or a twin `loot_read` line can do it. At the deadline, taskkill whatever is left (run_limited can write `<name>.pid`) and write its `.done` as "killed at the pass deadline".

**5. `loot_read.md` and `summary.md` sit outside `pass\`, so a failure leaves last pass's file in place.** Effort: S
- Where: `loot_read.gd:57` and `balance_summary.gd:71` use `docs/balance/loot_read.md`. `summary.md` is at `:16`. Neither is cleared at the start of a pass.
- Why:
  - If the loot read dies, gates 12 and 13 read GREEN off the previous pass's tables. The snapshot's copy is dated 15 Oct.
  - If the summary fails, the old `summary.md` stays and reads as current, with only the "Written" line to tell them apart.
- Change: write `loot_read.md` into `pass\`. Delete `summary.md` at the start of a pass. Put the commit from `pass\commit.log` in the summary's header: it's written today but nothing reads it.

**6. The `.bat` files Claude edits arrive with LF line endings.** Effort: S
- Where: `watch.bat`, `balance.bat`, `balance_read.bat`, `read.bat` and `playtest.bat` are LF-only (`file` shows no CRLF). `smoke.bat` and `review_art.bat` are CRLF. The snapshot keeps line endings as they are, and the bridge commits bytes unchanged.
- Why: cmd's label search (`goto wait`, `goto summary`, `goto loop`) is unreliable in LF files when a label lands near a 512-byte boundary. Today `:wait` is at byte 4022 (438 into its block) and `:summary` at 4407 (311), so this pass got lucky. Any edit moves them.
- Change: add a `.gitattributes` with `*.bat text eol=crlf` and `*.ps1 text eol=crlf` (none is in the snapshot; check on Matt's machine). Add a check (gdlint's step, or a smoke check) that every `tools/*.bat` contains `\r\n`.

**7. `balance_read.bat` argument edge cases.** Effort: S
- Where: `balance_read.bat:9` forwards `%3`-`%9`, which is at most 7 `balance.gd` arguments. The checkpoint already uses 6 (`40 one Drifter fire 0 checkpoint`).
- Why:
  - An 8th argument (a seed after `checkpoint`, say) is dropped without a word.
  - An empty argument (`""`, as in `balance.gd:53`'s plain-build example `-- 8 gate Scrapper "" 7`) breaks the `-GodotArgs "..."` quoting, so a plain build can't go through this wrapper.
  - Paths with spaces are fine: everything after `cd /d "%~dp0.."` is relative, `-Godot "%GODOT%"` is quoted, and `run_limited.ps1:11-12` builds `cmd /c ""exe" args > "log""` correctly.
- Change: collect the arguments with `shift /3` in a loop, and pass the empty element as a word (e.g. `plain`).

**8. Smaller mismatches.** Effort: S
- `smoke.gd` `_init`: `-- seed random` prints "SMOKE seed random", not the dice actually used, so a red on a random run can't be replayed. CLAUDE.md:27 says the line "says which". Pick `randi()`, set `Sim.fixed_seed` to it and print the number. `int("abc")` and `seed 0` also turn into random without saying so.
- The seed can't reach the smoke through the watcher: `smoke.flag` is empty and `smoke.bat` takes no arguments. Let the flag's content be the smoke's arguments (`seed 7 only web`).
- Two reads of the same build write the same `pass\<build>.save` at once (`balance.gd:528`, no read index). Add `-N`.
- The new `tempers` field in GATES (`balance.gd:462`) isn't shown anywhere in the summary.
- The summary itself runs with no time limit (`balance.bat:81`).
- Stale comments: `balance.bat:9` and `:12` (the checkpoint and parity paths), `:83` ("raw reads are in docs\balance\*.txt"), `balance.gd:527`, `smoke.bat:2` ("About ten minutes"; CLAUDE.md says ~1.5).
- CLAUDE.md:14 doesn't mention that `balance.gd`'s own 2 h wall cap (`balance.gd:298`) is what really bounds a read, ahead of the 240 min kill. The slowest read was 5497 s, which leaves 24% headroom. Nothing flags a read cut by that cap except gate 8, so it belongs in the summary's anomalies. CLAUDE.md:29's `read.bat` still runs the old `gate` mode (open from this morning's item 15).

## B. Bot behaviour that makes the reads unrepresentative

**9. P3 "odds at the gate 100%" can't come out any other way.** Effort: S (the gate) / M (a pushing bot)
- Where:
  - `bot.gd:11` `PUSH := 0.88`, with `balance.gd:258` `odds_runs_max = 24`.
  - `sim.gd:6454-6458`: four clean dry runs (none under 70% HP), or eight, set the odds to exactly 100%.
- Why: the only readings at or above PUSH are 22/24 (91.7%), 23/24 (95.8%) and 24/24 (100%), and all of them sit above P3's ceiling of 90%. Only first clears and heads at `FIRST` 0.65 can land inside 70-90%, and that's about 16 runs out of the 1,000-21,000 each read makes. The median is 100% by construction. `bot.gd:13` also notes Matt's own recorded runs were 17 of 22 at 100%.
- Change (Matt's call):
  - (a) judge P3 on first-clear and head runs only, which is where the bot plays at a person's odds, and show farm runs alongside;
  - (b) change the window; or
  - (c) give the bot a seeded "pusher" share of runs taken at the deepest depth reading ≥ 0.75.
  - I'd do (a). It's a summary change, so it moves no numbers and needs no rebalance.

**10. Deaths 1 in 1,000+ come from four stacked cautions.** Effort: S / M
- Where:
  - The run is taken at ≥ 91.7% (item 9).
  - HP is rested to full before every run, and the bot waits under 70% (`bot.gd:111-119`).
  - A med at 40% (`:160`).
  - It leaves at 25% HP, checked every simulated second (`:162-165`, `should_leave` `:239`). The dry runs behind the odds don't bail, so a real run is safer than its odds say.
  - The skills exclude `last_stand` (`:204`).
- Why: a death needs one tick to take the runner from above 25% to 0. Bails are the near-deaths: the "(shown)" row has them at one in 28-560, and `bot.gd:28` already calls them "the deaths a player who pushes on takes".
- Change: P1 counts bails plus deaths for the bot (summary only). If Matt wants the bot itself riskier, add a seeded push-on chance at 25% plus greed for the third gang (item 2). That is bot code, so it goes through the reviewer, and it moves numbers, so it belongs before the pass.
- Same root cause: P6 "full at the reach 82%" is a result of the bot running full signals only at PUSH (`bot.gd:568`), with COIN only when it holds three. That makes P6 bot play rather than design.

**11. Some kinds look wrong.** Effort: S
- Gate 3 (the builds' band) is a spread between builds, and Matt's play can't calibrate it. It's design.
- P6 is bot play (item 10).
- 14 (cash) and 15 (scrap) are driven by the bot's spending (`_reserve`, `TEMPERS_A_PASS`, `keep`). They're worth a "design (bot spend)" note.
- The duplicates still count twice: 16 and "Level on entry", P1 and "Deaths (as played)", P2 and "Wounds (as played)". The 5 bot-play reds are really 3.

## C. Smoke

**12. Flaky spots left now the seed is fixed.** Effort: S
- `smoke.gd:6583` `frame_ms < ODDS_MS + 150` is a wall-clock assertion. It goes red on a busy machine, in the cloud (about 6x slower), or at high tiers where one dry run is long.
  - Change: assert on the number of dry runs started in the frame, not on milliseconds.
- The statistical windows at `:1881` (charms of 400) and `:4578` (Van Keys of 40) are steady now under seed 1025. But any change that shifts the dice order can flip them, giving a red unrelated to the change. When one does flip, rerun on 2-3 seeds before calling it real (worth a line in CLAUDE.md).
- `smoke.bat` still runs no `--import` first. One process, so there's no race, but an art commit's import time comes out of the 25 min cap.

## D. Art and sound pipelines

**13. How a manifest runs.** There's no art job in `watch.bat`.
- A maker (`make_*_manifest.py`) writes `tools/pixellab_*_manifest.json`.
- Someone on Matt's machine runs `godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/<m>.json`, with `++ --dry-run`, `--only`, `--force` and `--parallel N`. The key is `PIXELLAB_SECRET` or the secret file, so it runs only there.
- CLAUDE.md:134-136 describes a handoff between sessions (`docs/art/handoff/art.flag` → `art.done`). That's not in the snapshot.
- Every maker's readme says bare `godot`, but the bats use `tools\godot.txt` because `godot` may not be on Matt's PATH.
- Change (Effort S): add `tools\art.bat <manifest> [dry|run]`. It reads `godot.txt`, always does the dry run first (job count, files to be skipped), logs to `docs\art\handoff\<manifest>.log`, and writes `art.done` with the batch's "Done: N generated, N skipped, N failed, $X" line. I'd keep it out of the watcher unless Matt wants that. The credits rule needs a person to say go.

**14. Seed reuse across manifests already breaks the "no two jobs share a seed" rule.** Effort: S
- A scan of all 55 manifests finds 52 seeds shared between different outputs. Some examples:
  - `make_fight_kit_manifest.py:117` `SEED_OF` Crossbow 97104 and Garage-built rifle 97105 are the same seeds as the Barracks plate and cover in the same manifest.
  - The kit's hands 97000-97003 match `intro` scene_1-4.
  - Kit plates 97100 and 97102 match `air_1` and `air_3`.
  - `doom_test` 98000-98002 match web-art nodes.
- Change: add `tools/art_lint.py`, run before any manifest goes to Matt. It checks:
  - seeds unique across every manifest;
  - no `out` already on disk unless meant;
  - nothing under `art/ui/`;
  - `width*height` ≤ 262,144 (the API's ~512² cap);
  - every `style_image` and `reference_images` file exists;
  - `--only` names unambiguous (`pixellab_batch_v2.gd:164` matches substrings, so `--only the_bank ++ --force` hits every job whose name contains it).

**15. Per-boss fight backdrops: what makes the manifest safe.** Effort: S (the manifest) + M (the code to show them)
- Bosses: `data.gd:1464` `BOSSES`, which are the Gamekeeper (tier 2), the Carpet Man (5), the Manager (8) and the Quartermaster (11). That's 8 jobs, plus 2 for a test with one boss first.
- Model it on `make_fight_walls_manifest.py`: import the kit's constants rather than copying them (`TAIL`, `STYLE`, `PLATE_W/H`, `EMPTY`, `LAYOUT`, `POV`, as `make_doom_test_manifest.py:13` does). Don't edit `make_fight_kit_manifest.py`: it's Matt's uncommitted file (CLAUDE.md:103).
- Plates are 744x320 (238,080 px) and covers 744x256 (190,464), both under the cap.
- Style each one on its own site's live pair (`art/fight_new/<site>_plate.png`, `art/fight_walls/<site>_cover.png`) so the boss backdrop reads as the same place.
- Use a fresh `SEED0` checked by item 14's lint, and write a test manifest plus a set manifest whose skip-if-exists skips the test's piece.
- Outputs go to a folder of their own, e.g. `art/fight_boss/<boss>_plate.png` and `_cover.png`, so nothing live is touched and no `--force` is needed. Use names that no site name contains, for `--only`.
- Code the art needs (separate from the manifest, so it needs Matt's go):
  - `RunView.tex()` (`run_view.gd:205`) searches only `fight_walls` (covers), `fight_new`, FULL_DIR and DIR, so it needs the new folder added.
  - `_site()` (`:524`) switches on the site key, and `_boss_key` (`:94`) never picks the art. A head's run needs to call `_site(boss_key)`. The rule that a backdrop is both of a pair or neither (`:526`) carries over.
  - The smoke's art-presence checks should list the 8 files.

**16. Sound: two traps in the documented commands.** Effort: S
- `eleven_batch.ps1:12` documents `-Only shot_pistol,kill`. Under `powershell -File`, Windows PowerShell 5.1 passes that as one string, "shot_pistol,kill". It matches no job, so the run reports "0 to make" without an error.
  - Change: `$Only = @($Only | ForEach-Object { $_ -split ',' })` after `param`.
- `sound_manifest.json:5` and its maker `make_sound_manifest.py:116` still say `python tools/eleven_batch.py`, but there's no Python on Matt's machine.
  - Change: point both at `powershell -File tools/eleven_batch.ps1` and retire the `.py` (this morning's item 26).
