# Running things on Matt's machine: the full procedure

Moved out of CLAUDE.md on 28 Oct (its one-screen table points here). Read the row for a job before dropping its flag.

The watcher (`tools\watch.bat`, a window Matt leaves open) runs jobs from flag files in `docs\balance\`:

| Job | Drop | Runs | Results | Done |
|---|---|---|---|---|
| Smoke | `smoke.flag` (empty) | `tools\smoke.bat` (~1.5 min) | `docs\balance\smoke.txt`; last line is the verdict | `smoke.done` (a timestamp) |
| Balance pass | `balance.flag` with the hours in it, e.g. `32` | `tools\balance.bat <hours>`: first the Radio's checkpoint (a new game to the Radio, `radio_checkpoint.save`), then side by side every element build as one save from the Poacher (its class taken when it opens) twice, every build 4 h from the checkpoint twice (`parity-<class>-<element>-N.txt`, `PARITY {json}`, judged on the mean), then the gauntlet (26 Oct, Matt): each build's end state (`pass\<Class>-<element>-<N>.save`, one a read) through the endgame in order - the Grid, the Archive, the Mint, the County's twelve - three tries each, issued kit bought for each zone, a death or loss put back (`gauntlet-<Class>-<element>.txt`, `GAUNTLET {json}`), and the six broken builds' pieces put on their class's end state the same way (`broken-<key>.txt`, `BROKEN {json}`; broken = every place won; outside the gates - its own table in the summary), the probe and the loot read. Each read runs through `tools\balance_read.bat <name> <minutes> <args>` (or `<name> <minutes> script <res path> <args>`; run_limited.ps1: killed past its minutes, or 15 min silent after a SCRIPT ERROR), and its `.done` says how it ended (`done ok`, `killed-time`, `killed-error`, `crashed`); `pass\expected.txt` lists every read started, `pass\deadline.log` marks the 5 h deadline firing; the summary names any read that didn't end ok | `docs\balance\pass\<build>-N.txt` (half-hour lines, purchases, a `GATES {json}` line; the folder is the pass's own, wiped at its start), the summary `docs\balance\summary.md` (each red with its kind: design, bot timing, bot play) | `balance.done`, each read `pass\<build>-N.done` |
| Quick pass (iterating) | `balance.flag` with `16 1 quick` | `tools\balance.bat 16 1 quick` (28 Oct, Matt: "buy time on balance passes"): the pass as above, but each one-save read gets `cap20` (tests/balance.gd stops it after 20 minutes of wall, its GATES line carrying `capped_at`, a CAPPED line in its .txt) and there's no gauntlet; the summary's header names every capped read and how far it got (a "never" in a capped read may be the cap). The 28 Oct `24 1` pass took 1 h 38 min, nearly all of it the slowest one-save read | as the pass | `balance.done` |
| Broken builds alone | `balance.flag` with `0 0 broken` | `tools\balance.bat 0 0 broken`: the six broken builds' gauntlets from the last full pass's end states (refuses without them); the pass folder's other reads kept | `docs\balance\pass\broken-<key>.txt`, the table `docs\balance\broken.md` | `balance.done` (a bad flag: `docs\balance\flag_error.txt`, nothing run) |
| Build hunt | `balance.flag` with `2 0 hunt` | `tools\balance.bat 2 0 hunt` (26 Oct, Matt: "cook some different builds up"): from the pass's checkpoint at level 50, the runner staying out (20 patrols, the bail, or a short clock after the clear). Stage 1: every class's two joints, each with every set at its count or none, 2 h each in 12 shards (`pass\hunt-s1-<shard>.txt`, `HUNT {json}`). Stage 2: stage 1's best 20, each with every unique whose slot the set leaves free (`hunt-s2-*`). Then stage 2's best six through the gauntlet from the last pass's end states (`broken-hunt<n>`, `-- 0 broken hunt<n>`). Ranked by the damage really dealt a second fought; the finalists judged as the broken builds are | the tables `docs\balance\hunt.md` | `balance.done` |
| Playtest read | `playtest.flag` with a save path (or empty) | `tools\playtest.bat` | the playtest summary | `playtest.done` |

- From a cloud session the smoke is `bash $HOME/flaky/run.sh N` in the device shell: it drops the flag, waits for a
  fresh `smoke.done`, copies the log to `$HOME/flaky/smoke_N.txt` and greps `CHECK FAILED\|SCRIPT ERROR`. Check the
  done timestamp is new (it's Matt's local time: UK time, GMT in winter, BST in summer). The verdict is run.sh's own "run N (done ...)" line, never
  `smoke_N.txt` read on its own: the numbers wrap and an old run's file sits there (23 Oct: runs 61-63 read "green" off
  the 19th's files while the smoke hung). A run that writes no done file within run.sh's wait has hung: find where
  `docs/balance/smoke.txt` stopped, and the hung Godot has to be killed on Matt's machine before the next flag.
- The watcher runs one job at a time: no smoke while a balance pass runs.
- The gauntlet (26 Oct, in every full pass after the one-save reads): each build's end state
  (`pass/<Class>-<element>-<N>.save`) fights the Grid, the Archive, the Mint and the County's 12 in order, 3 tries each,
  the camp restored after every lost try; the six broken builds' pieces on too. The summary's `gauntlet_table`. Flags:
  `0 0 broken` (the broken builds' gauntlets alone, from the last pass's end states), `2 0 hunt` (the build hunt).
  A bad flag writes `docs\balance\flag_error.txt` and runs nothing.
- With the watcher off, a cloud session runs the full smoke in the cloud on a snapshot of its copy (xvfb, opengl3). Its
  known cloud-only reds are art the cloud copy lacks: gang faces, muzzle flashes, the Recruit's portraits, item
  pictures (a cell's words standing in, e.g. 'AMO'); every other red is real.
- The smoke's dice are fixed (seed 1025) so a red repeats; `-- seed N` runs it on another, `-- seed random` on a fresh
  one (its `SMOKE seed` line says which). `-- only <area>` runs one area.
- Long sim and balance runs are Matt's machine's (6 Oct: it's about twice as fast). One quick read between passes:
  `tools\read.bat <hours> <class> [element]`.
- gdlint shows 0 before any commit (`tools/gdlint.py`).
