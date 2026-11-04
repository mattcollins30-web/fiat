# Language pass, build 48 (the fix round, part 1)

Read $S/b48/docs/language/style_guide.md (the rules and the glossary) and check the new or changed player-facing words
below, as they'd read in the game. The code is in $S/m48 (scripts/sim/words.gd and the files named) - grep for each to
see where it shows. For each string: OK, or the change you'd make and why (a rule or glossary entry). Also say if any
clashes with an existing name (grep words.gd and data.gd). Be brief.

1. Training's node card for a skill node: chip "Skill"; where line "a skill" (was "Notable").
2. The fight's clock: a toast "1:00 left on the clock" / "0:30 left on the clock" (Words.RUN_CLOCK["warn"] "%s left on the clock").
3. The Kit's loot rules button, short form: "Loot rules · 2" (full form "Loot rules · 2 on").
4. The class swap card (barracks.gd): "A new runner: level 8, the arrival's kit, their own points from here." and "A new runner at level 8."
5. The Workshop's gear card with no sockets: "<the piece's name>: no sockets".
6. The pick panel's body figure (was "▲ 12% odds"): "▲ 12% against the Barracks" at home, "▲ 12% against this run" on a run; short form "▲ 12%".
7. The run's rig heading when Kev's No meds wager is on: "The rig · no meds: Kev's wager"; a med's hover: "No meds: Kev's wager".
8. The Map's key entry for a pin whose odds are an old read: "Old read".
9. The Vagabond's card: "5,200 tins at home" (was the run's take).
10. The site card: the Gang / Head toggle is now what takes the head on (the foot's "Take him on" button is gone); on the Services' convoy the toggle reads "Head" where the old button said "Convoy".
