# Run timers (9 Oct 2026)

From Matt's playtest: "Current timers count up so the game is can I take a 0% chance zone and face tank it with
meds and luck ... a timer counting down that stops when the gangs are clear to allow searching ... would add some
stakes. Each tier adds time limits ... and if you don't extract (kill all gangs) by the time the timer ends then
it counts as a loss, same as other extraction games. This also adds DPS checks to the game so it does need
careful implementation and balance."

Agreed with Matt (9 Oct): **a time-out loses the pack and a few random pieces of worn kit, the runner lives**;
**the budget is a reference DPS check**; **nothing buys more time yet** (the balance pass decides).

## 1. The clock

- One clock a run, counting down. It ticks only while a gang is on you - the first lot, every gang after the
  clear, a head - and stands still while the site is clear and the runner searches.
- It hits zero with anyone still standing: the run is **out of time**. The runner gets out alive; the pack is
  lost (as on a death, to the estate) and **two random pieces of worn kit** with it (the insurance pays for those
  as on a death; a rig lost takes what was in it). A lost gun, armour, bag or rig is replaced by the
  hand-me-down a new runner arrives with (and a box of nails with the nail gun), so a time-out never leaves a
  runner with fists against a clock - a spiral. The Insurance desk keeps the pack, Fetch the best of it, as on a
  death. Leaving before then is as now.
- The dry runs behind the odds read the clock: a dry run out of time is a run lost, so "A bad idea" can say *out
  of time*.

## 2. The budget: a DPS check

- A site's budget is the same for every build: **CLOCK_BASE + CLOCK_PER_HEAD × (its pool + CLOCK_GANGS heads
  for the gangs after the clear)**, read off the site *as plain* (no Radio words; the depth's own pool). Since a
  head's HP grows with the depth and the level while its seconds don't, the damage a site needs grows with them:
  the check.
- A head (the crews' bosses, the convoy) adds CLOCK_HEAD_S × his HP in heads when he comes out.
- The Radio's words don't change the budget, so a word that adds HP or the pack bites through the clock too;
  Last bus halves the budget instead of its four-minute clock.
- First figures (as built): CLOCK_BASE 60 s, CLOCK_PER_HEAD 12 s, CLOCK_GANGS 5. The bot's median at the sites it
  picks was 6 s a head (probes, 9 Oct: Drifter 4 h, Poacher 9 h - 4 time-outs in 224 runs); 12 is twice that,
  and the base lets the starting kit (12/s on the streets' 200 HP heads, 17 s a head) through its first site.
  The balance pass sets them, with a gate: *the bot's chosen sites time out under one run in twenty, a site two depths past its
  climb over half*.

## 3. The screens (Clock-A on the canvas)

- **The run:** A - the band's headline is the clock counting down ("1:24 left · ticks while they're on you"),
  a bar under the kills draining with it, amber in its last fifth, the time in and the budget in the corner; or
  B - the band as now, the clock the fight row's fourth tile.
- **The Runs card:** the Fight tile becomes "Fight · clock", "0:52 of 1:40", red when the fight estimate is over
  the clock (A was chosen for the run screen).
