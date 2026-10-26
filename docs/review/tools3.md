# Fiat tooling review 3 (26 Oct, before the final balance pass)

This review covers the snapshot at `rev2/repo` (commit 05b6589) and `rev2/since_review2.diff`. No repo file was edited. The only thing run was `art_lint.py`, read-only, with `-I -B` from the scratchpad. The snapshot has no `docs/balance/`, so no pass results could be checked: anything that depends on a figure from a run says so.
Effort: S = under an hour, M = an afternoon, L = a day or more. Items are ranked best first. Each one needs Matt's go-ahead.

## 1. Yesterday's items

**Still holding:** tools.md 1 (pass folder), 3 (time limits on the reads), 4 (`--import` once, in all three modes), 17 (gate kinds); tools2 1 (GK scaled, `balance_summary.gd:45`), 2 (the unjudged gates named), 3 (`.done` outcomes, `expected.txt`), 4 (the loot read is now limited; every read's cap is under the 5 h deadline), 5 (`summary.md` and `loot_read.md` cleared, the commit in the header), 8a (`seed random` prints its number), 9 (P3 on first clears), 10 (P1 adds bails), 13 (`art.bat`), 15 (the boss dens).

**Never done:**
- tools.md 2: no run ID or verdict in `.done`, no `watch.alive`. `smoke.done` is still a timestamp.
- tools.md 5: the smoke is still capped at 25 min, the silence kill still needs a SCRIPT ERROR, and `smoke.bat:2` still says "About ten minutes".
- tools.md 6: the dirty-file count isn't recorded, and the smoke prints no commit.
- tools.md 8, 9, 10, 11, 12: smoke structure. `CLAUDE.md:19` still describes run.sh grepping only `CHECK FAILED\|SCRIPT ERROR`, so a "FAIL: a node added twice" line from `smoke.bat` isn't in that grep. `smoke.gd` is now 20,117 lines.
- tools.md 13: no pool. This matters more now: see B4.
- tools.md 14: no read is seeded. `balance.gd` never sets `Sim.fixed_seed`.
- tools.md 15: `read.bat:22` still runs `gate` mode, and `CLAUDE.md:31-32` still points at it.
- tools.md 18, 19, 20, 21: duplicate gates still counted twice, no "was" column, no Anomalies block, no "Matt" column.
- tools.md 22: `pixellab_batch_v2.gd` has no art/ui guard and no `--max-usd`. Only `art_lint`'s `ui` check stands in.
- tools.md 24: gdlint still waits a fixed 1.5 s per file.
- tools.md 25 and 26: no `docs/.gdignore`; `eleven_batch.py` and the `shot*.gd` one-offs are still there.
- tools.md 27 and 28: not done.
- tools2 7: `balance_read.bat:13` still forwards only `%3`-`%9`. Every current call fits.
- tools2 8: `smoke.flag` still carries no arguments; the same-build `.save` clash remains (`balance.gd:576`); the summary has no time limit; the stale comments remain (`balance.bat:17`, `smoke.bat:2`).
- tools2 11: the duplicate gates still count twice.
- tools2 12: the wall-clock assertion `frame_ms < ODDS_MS + 150` is still at `smoke.gd:6587`.
- tools2 14: no check for ambiguous `--only` names or outputs already on disk.
- tools2 16: `eleven_batch.ps1:15` still doesn't split `-Only a,b`, and `make_sound_manifest.py:116` and `sound_manifest.json:5` still say `python tools/eleven_batch.py`.

**Half done:** tools2 6. `.gitattributes` sets CRLF, but `watch.bat`, `playtest.bat`, `read.bat` and `eleven_batch.ps1` are still LF in the snapshot, because existing files weren't renormalised. `watch.bat` is the one with a `goto loop`. No CRLF check was added.

## 2. What's new since d17b479: bugs

**B1. Gate 18 is judged on each build's first read only.** Effort: S
- Where: `balance_summary.gd:876-939` `_merged` has no `issue_at`, `county_taken` or `issued_bought`, so it keeps `gs[0]`'s. Gate 18 (`:812-819`) then reads them.
- Why: with two reads a build, the second read's Issue and County count for nothing, both in the verdict and in the text. The County's figures (`county_firsts`, `orders_beaten`, `fiat`) are written to GATES (`balance.gd:524-535`) but shown nowhere.
- Change: put `issue_at` in the median list (a never counts as later), and take `county_taken` and `issued_bought` by their median. Add Issue and County columns to the builds table, one row a read.

**B2. Gate 14 adds tins and fiat together, so any build that reached the Issue reads green.** Effort: S
- Where: `sim.gd:3843-3846` `_earn` adds to `cash_in` on both sides of the Issue. `issue()` converts `cash` (`sim.gd:1156`) but leaves `cash_in` alone. `FIAT_SCALE` is 0.0005 (`data.gd:3370`). Gate 14 (`balance_summary.gd:784-795`) divides `cash_end` (fiat) by `cash_per_h` (mostly tins).
- Why: a build that hoards fiat after the Issue shows almost no hours of income held. This is a design gate. The half-hour "£ earned" lines mix the two units the same way.
- Change: record `cash_in` at the Issue in GATES. For a read that reached the Issue, judge gate 14 on the fiat held against fiat income since the Issue, and label the unit.

**B3. After the Issue, the bot swaps every element build's gun for the issued rifle.** Effort: S/M. It is bot code, so it goes past the reviewer, and it moves numbers, so it belongs before the pass.
- Where: `bot.gd:343-354` `_wear_issued` equips the newest issued piece in every slot not in `broken_slots`, Primary included. It runs after `_hold_the_element` in `_tidy_kit` (`:497-498`) and again in `_issued` (`:251`) after every tidy.
- Why:
  - An element read's hours after the Issue measure the Anti-materiel rifle, not the build. That covers gate 9's end odds, gates 14 and 15 and the kit column.
  - The six broken combos' `broken_slots` hold Primary only when their unique is a primary (`:296`), so most of them lose their element gun after the Issue too.
  - The County wants 2, 3, 4 and then 6 pieces worn (`data.gd:3317`), so only the Treasury needs the rifle.
- Change (Matt's call): wear only as many issued pieces as the next open zone wants, filling Helmet, Rig, Charm, Armour and Secondary before Primary. Write `gun_off_at` into GATES so the summary can say when the build's own gun came off.

**B4. Reads cut short by their own wall caps go unflagged, and the pass now runs 62 processes at once.** Effort: S (the caps and the flag); M (the pool, tools.md 13)
- Where:
  - The full pass starts 24 one-save reads, 24 parity reads, 12 broken reads, the probe and the loot read: 62 processes. Yesterday's review saw 38.
  - `_gate` stops at 2 h of wall (`balance.gd:314`), but its kill is at 240 min.
  - A parity read stops at 2 h (`:1048`), but it is killed at 60 min (`balance.bat:72`). Killed, it leaves no PARITY line, so it never gets to say `cut_short`.
- Why:
  - The slowest read was 5,497 s at 38 processes (tools2.md:77). At 62 processes on 32 threads it would plausibly pass the 7,200 s cap. That stops the read before hour 32.
  - The Issue and the County come last (7.7-29.4 h in the eighth pass), so they are what a cut read loses. Gate 18 then says "no Issue" with no hint why.
  - The builds table shows the hours reached, but nothing flags a short one.
- Change:
  - First, check the eighth pass's builds table for Hours below 32.
  - Set the internal caps just under the kills: 230 min for one-save reads, 55 min for parity.
  - The header names every GATES read with `elapsed_h < hours` as "cut by its wall cap at X h".
  - The pool can wait unless reads were cut.

**B5. A mistyped flag wipes the pass.** Effort: S
- Where: `balance.bat:27-42`. Any third word other than `broken` or `hunt` (a typo, or `16 broken`, which puts `broken` into READS) falls through to `del /q docs\balance\pass\*.*`. That takes the checkpoint, the broken reads and the hunt with it. A READS that isn't a number gives a pass with no one-save reads at all.
- Change: check that HOURS and READS are numbers and that the mode is empty, `broken` or `hunt`. Otherwise write `balance.done` as "bad flag: ..." and exit without deleting anything.

**B6. The hunt's finalists are judged against a baseline that is the same build.** Effort: S (summary and bat), Matt's call on the yardstick
- Where:
  - `Sim.combos_off` only switches off the six COMBOS (`sim.gd:5033-5036`).
  - A finalist's `plain` read (`balance.bat:143`, `balance.gd:867`) has the same class, recipe, set, unique and gun, so it differs only in the dice.
  - `broken_table`'s 1.5x test (`balance_summary.gd:134`) therefore can't pass for a hunted build unless it happens to be one of the six (`combo_on`).
- Why: every non-combo finalist reads "RED: not 1.5x its baseline" by construction, and its six 16 h baseline reads are wasted.
- Change: compare a finalist with its joint alone (no set, no unique) over the same 16 h, or with the median of the six combos' reach gains. Run that one baseline a joint, not one a finalist.

**B7. Stage 2 is far bigger than stage 1 and likely runs past the 300 min kill, unevenly.** Effort: S
- Where:
  - Stage 1 is 12 joints x (6 sets + none) = 84 builds, 7 a shard.
  - Stage 2 is the top 20 x every rule-bearing unique whose slot is free (`balance.gd:823-834`). With 59 uniques that is roughly 450-1,180 builds, or 38-98 a shard, each 2 h simulated.
  - At yesterday's ~2.9 wall-minutes a simulated hour, a shard needs about 4-10 h against `balance.bat:137`'s 300 min.
  - Each shard takes `i % 12` of a list sorted by stage-1 rank, so a kill drops the lower-ranked rows' uniques first.
  - `hunt_table` names a shard only when it wrote no lines at all (`balance_summary.gd:165-168`), and never reads the hunt's `.done` files.
- Change:
  - Each shard prints `HUNT_END k of m`, and hunt.md shows each shard's coverage and how it ended.
  - Size stage 2 from stage 1's `wall_s` before it starts: more shards (the hunt runs only 12 on 32 threads), a longer cap, or a top-N under 20.
  - The whole hunt can block the watcher for about 14 h. Tell Matt before he drops the flag.

**B8. Hunt timeouts are silent, and each process builds its list on its own.** Effort: S
- Where:
  - `:waitfor` (`balance.bat:153-163`) returns at its tick limit without logging or killing anything.
  - Every stage-2 shard calls `_hunt_ranked(1)` itself (`balance.gd:823`), and every finalist calls `_hunt_ranked(2)` itself (`:746`), while the earlier stage's files may still be growing.
- Why: after a timeout, two finalists can be the same build, or a build is skipped. Nothing says so.
- Change: between stages, write the ranked list once (`pass\hunt-s1-top.json`, `pass\hunt-finalists.json`) and have the shards read that. On a timeout, kill the stragglers and write `pass\hunt-deadline.log`.

**B9. Broken-only and the hunt start from whatever checkpoint the last full pass left.** Effort: S
- Where: `balance.bat:131` and `:173` remake the checkpoint only if it's missing. The checkpoint's JSON has no commit (`balance.gd:391`). The headers print `broken_commit.log`, which is HEAD at run time (`balance_summary.gd:187` and `:204`).
- Why: after a sim change, these reads start from a world made by older code, under a header that names the new commit.
- Change: store the commit in the checkpoint, and remake it when it differs from HEAD. Print both commits in the header.

**B10. The hunt deletes the pass's broken reads, and broken-only deletes the hunt's finalists.** Effort: S
- Where: `balance.bat:128` and `:170`, both `del pass\broken-*.*`. The finalists are named `broken-hunt<n>`.
- Change: name the finalists `hunt-f<n>[-plain]`. `read_broken` takes a prefix.

**B11. Stage 2 includes builds that can't exist.** Effort: S
- Where:
  - The Lorry Driver's Log has slot "Paper" (`data.gd:862`), which isn't in `Data.SLOTS`. `_hold_broken` writes `equipped["Paper"]`, and `has_rule` loops `SLOTS` only (`sim.gd:3614`). So 20 stage-2 reads are their stage-1 build under the unique's name.
  - The 7 mythic uniques are hunted, though no balance read ever drops a mythic (`bot.gd` step sets `mythics_on = false`).
  - The six finalists can all be variants of one joint and set.
- Change: skip uniques whose slot isn't in `SLOTS`. Whether mythics stay in is Matt's call. Allow at most one finalist per joint and set.

**B12. The hunt is ranked on single, unseeded 2 h reads.** Effort: S
- Where: `_build_read` never sets `Sim.fixed_seed` (the same gap as tools.md 14).
- Change: one fixed seed a stage, so every build meets the same dice. Print it in each HUNT line.

**B13. Smaller items.** Effort: S
- `hunt_table` sorts by rate with no tie-break (`balance_summary.gd:167`), but finalists are picked with an id tie-break (`balance.gd:848-851`), so hunt.md's top six may not be the finalists. It also lists error rows as rate 0.
- A recipe step that failed to walk (`walked` with `ok` false, `balance.gd:892`) isn't shown in hunt.md or broken.md.
- `issued_bought` is `issued_serial` (`balance.gd:534`), which also counts the heads' and the remix's drops. Label it "issued pieces".

**Batch files:** the labels and `goto`s in `balance.bat` are sound. `call :waitfor` inside the `for` block works. `%HOURS%` is expanded at parse time, which is right here, because it is constant. Delayed expansion is safe, since no `!` appears in the paths or arguments. Every wait is bounded, and every read sits under a kill that comes before the deadline. Remaining problems:
- The LF files listed in section 1.
- `watch.bat` still writes `.done` files with no outcome (tools.md 2).

**Art tools:** `art_lint` isn't clean on the new manifests.
- It flags 4 seed clashes: each County head's stand, fire and down share one seed (`pixellab_county_manifest.json`, e.g. 106037-106043).
- It flags 5 `out` clashes: the border rerolls write over files that other manifests also write.
- Both are probably deliberate (a pose family, a reroll). As standing reds, though, they teach a session to ignore the lint.
- Change (S): allow `"pose_of"` or `"reroll_of"` on a job, so a deliberate clash is declared and passes. Add tools2 14's `--only` ambiguity and already-on-disk checks.
- `art.bat` is sound. Its `set /p` would block the watcher if it were ever wired to a flag, so keep it out of `watch.bat`.

## 3. The smoke's coverage of the new systems

Ranked by risk. Each line is the assertion to add.

1. **The County's crews: no check at all.** `run_view.gd:778-780` falls back to the host's crew unless all six figures exist, without a word.
   - For each of the four zones, assert all six `gang_<zone>_{a,b}_{stand,fire,down}` plus `people/gang_<zone>.png` exist (S).
   - On a Toll Plaza run, assert the figures up are the Motorway's.
2. **The County's heads in the fight: no check.** The head checks loop `Data.BOSSES` only (`smoke.gd:~11797`).
   - On each head's place, assert `head_the_<who>_stand/fire/down` are what's drawn, and that the fight's face is `People.portrait(who)` (S).
3. **The County's fight plates and walls are checked only if present** (`smoke.gd:20114` `if RV._pair_in`), so a missing pair passes.
   - Assert all 12 pairs exist whenever any County art does (S).
4. **Issued kit's pictures: no check.**
   - Assert `Items.art(sim.issued_piece(sl)) != null` for the six (S).
5. **Issued kit as a set piece, on screen:** only `set_count` is tested.
   - With one Army piece plus an issued piece worn, the Armoury's pick line (`armoury.gd:269-274`) reads "2 of N worn" and names the next bonus (S).
6. **The County map:** pin centres are checked, but not the labels or the hatch.
   - Assert no pin label overlaps another label or another pin.
   - Assert a shut zone's zone and place labels and its card text don't contain the real names (`county.gd:194`, `:200`, `:234`).
   - Check the right-hand card's fit for a head's place and a shut place, not just `toll_plaza` and `distribution` (S).
7. **The remix:** `_remix` is only called after `county_done()`.
   - Assert it changes nothing before the Treasurer.
   - Assert `_remix_issued` adds a piece at the reach and none under it.
   - A Radio card for a remixed signal ("The Distribution Centre", head "The Treasurer") fits (S).
8. **The heads' fights:** the Auditor's tax check sits under `if id0 != ""` (`smoke.gd`, the `auditor` block), so with no skill slotted it never runs.
   - Slot one in the fixture and assert it ran.
   - The Auditor's seal isn't checked at all; add it (S).
9. **The bot's new play and the harness: no check at all.** A harness self-check would catch a broken build before an 8-14 h run (M; it goes past the reviewer):
   - every stage-1 spec's recipe walks `ok`;
   - `_hold_broken` gives `set_count == pieces` and `has_rule(rule)`;
   - the held slots survive `_tidy_kit` and `_buy_upgrade`;
   - `_wear_issued` keeps the element gun (or doesn't), whichever B3 settles;
   - `_pick_order` picks the County's first place at FIRST.

   It could be a smoke area, or a 1-minute `-- 0.05 hunt 1 0 84` dry pass.
10. **The Issue and the counter are well covered.** The gaps: buying through the counter's button (not `sim.buy_issued`), and the counter showing a padlock on a piece the runner can't wear. The bot fix in 51b9eb0 suggests the counter needs one (S).

## 4. Ready for the final pass?

Almost. These are all S, and best done in one commit with the reviewer:
- **Fix before the pass:** B1 (gate 18 on both reads), B2 (gate 14's mixed units) and B5 (the flag check).
- **Matt decides before the pass:** B3 (the issued rifle on element builds). It changes what every post-Issue hour measures.
- **Check before the pass:** look at the eighth pass's Hours column. If any read stopped short of 32 h, take B4's caps and flag, and consider the pool. Without that check, gate 18 can be red for the wrong reason.
- **Before running the hunt (not needed for the pass):** B6-B12. As built, every non-combo finalist reads RED (B6), and stage 2 is likely cut and biased (B7).
- **Can wait:** smoke items 1-8 (S each; 1-3 and 6 under Matt's "every UI bug gets an assertion"), smoke item 9 (M), the art_lint allowances, and the remaining items from yesterday (run IDs, area registry, smoke split, Anomalies, "was" column, `read.bat`, CRLF renormalise).
