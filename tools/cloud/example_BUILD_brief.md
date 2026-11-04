# Build 48-A: the odds and the sim's fixes (workspace x48a, lint port 6050)

Read $S/BUILD48_COMMON.md first. S = /tmp/claude-0/-home-claude/17fbe8af-3b8e-5c47-af2f-5ddb8fb0f07d/scratchpad
Matt's saves for reproducing: $S/saves48/ (fiat.save, his latest; playtest_odds_stall_4nov.save, a level-13 Doorman
mid-run; *.before_restore_4nov). Load one in a headless script to measure (copy to the test's user:// as the smoke's
fixtures do).

## Items (status.md's parked list)

1. **Item 9 + item 3 - the Map's odds stop reading; read only the picked place.** Reproduce on Matt's save first
   (pick the Bank, count frames to settled; main._read_odds / _odds_base / sim.odds_state). Fix the cause. Then
   Matt's item 3: the Map reads the odds of the place picked only; every other pin shows its last read (keep each
   place's last read; a read made under a different kit/level/HP than now shows dimmed - pick the clearest form,
   list it). Smoke: on a late save every open site's odds settle within N frames when picked; an unpicked pin shows
   its last read; picking reads it fresh.
2. **Item 13 - a death at 100% odds with the head ticked.** Find which fight the 1.0 read (the gang without the
   head? a stale read?) from the record in status.md; fix; smoke: with the head ticked the odds read are the head's
   fight's (they fall against the gang alone when the head is harder).
3. **Item 17 - the odds don't count Kev's wagers.** signal_odds and the odds' key apply the wagers taken (no meds, a
   bigger gang, the clock, harder fire), keyed on them; the run screen's shut meds say why ("No meds: Kev's wager",
   through words.gd). Smoke: a signal's odds fall with No meds on against off; the shut meds' line.
4. **Item 22 - a piece's verdict on and off a run.** Confirm the cause on Matt's save (the "% odds" on the pick panel
   is survival_gain against front_tier()'s fight, read with a signal's codes on a run and without at home). Fix: one
   stated yardstick - the figure says against what ("against the Barracks" at home, "against this run" on a run) and
   is never called "odds"; the same piece, the same fight, the same verdict. Smoke: on and off a run against the same
   fight the verdict matches; the line names its fight and doesn't say "odds".
5. **Item 26 - Retune spins the fans.** Measure (frames and ms to settled after a retune, frame time while the
   decrypt runs) on Matt's save; cap it: the picked class's read first, the crew's only when the crew row's shown,
   the animation not stacking on the odds' frames, a retune mid-read not restarting more than it must. Smoke: a
   retune's reads settle within N frames and no frame of it runs the odds over its budget by more than X ms (pick N,
   X from the measurement and list them).
6. **Item 16 - the Vagabond takes the camp's tins** (Matt's pick): his gear and rumour priced as today, paid from
   the tins at home (sim.cash), not the run's take; his card says "your tins at home: N". Smoke: with tins at home
   and none on the run, a trade goes through and home's tins fall by the price.
7. **Item 24 - the rig's top-up** (Matt's pick): the gate refills only the magazines the last run used (what went out
   and came back short), never more than went out; meds untouched by the fill; the "Filled: ..." line only when
   something was filled. Smoke: a run that used two magazines comes home to two refilled and no more; a run that used
   none fills none and logs nothing.
8. **Item 4's open check** - a Get out pressed during a gang fight or a magazine refill isn't lost (status.md item 4:
   "Still to check while there"). If it is lost, fix it. Smoke: Get out pressed mid-refill takes effect.

## Not yours
Item 4's countdown timer, every other UI item (builder B), the skill web, act two.
