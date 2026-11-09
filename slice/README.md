# slice/ - the ARPG slice (build 72, 9 Nov)

A prototype, option A on the canvas "Lesser England - the ARPG slice": top-down and close, Hotline Miami for feel,
the game's real maths. It asks one question - is moving and shooting under your own hands fun? - before anything
else depends on it. Opened from the title's "Try the ARPG slice" button (the camp's runner, read from the autosave,
or a level-14 Poacher on a fresh camp); a sandbox, nothing it does is saved to the camp.

In: the Estate's car park, three gangs then the clear, the Poacher and three skills, the worn kit's primary and spare,
its affixes and the web as the sim reads them, men who take cover, flank and fire, a hard man, crates searched under
fire, the way out. Out: every other site and class, final art (tokens drawn in code), the heads, the County.

- slice.tscn / slice.gd (SliceWorld, W) - the world: steps everything in tick(dt); signals for the HUD; the geometry
  (sight, cover spots, collision as circles against rectangles)
- level.gd - the car park's layout and look; crate.gd - a crate; fx.gd - tracers, flashes, prompts (W)
- runner.gd (W) - the runner: moving, aiming (mouse, or right stick with a soft lock-on), the gun, crates, the way
  out, death and Last legs
- bridge.gd (G) - the game's maths per round, on its own copy of the runner's Sim (the camp is never written)
- gang.gd, man.gd (G) - the three gangs, the hard man, the men's cover, flanking and fire, their drops
- hud.gd (H) - the HUD per board A; pause.gd - the pause with board C's controls and the test settings;
  end_screen.gd - cleared / got out / dead; launch.gd - opening it from the title and giving the title back
- tuning.gd - every figure the sim has none for (pixels, feel, AI timings): W's block, then G's

## The two tuning knobs (build 72, the coordinator's call for feel)

- `MAN_HP_X` (tuning.gd, default 0.25): a gang man's HP is the sim's times this. At the game's own figures a man
  takes about 38 rounds - a sponge under your own hands; at 0.25 about 10, a few seconds. The pause's "Gang HP"
  button (a test setting) switches ×1, ×0.5 and ×0.25 live, so the difference can be felt.
- The site's level follows the runner: the runner's level minus 2 (`SITE_LEVEL_UNDER`), at least 1. The fixture is
  the level-14 Poacher, so its car park is level 12.

The rounds: each gun's spare magazines, then (the sim's refill) a magazine filled by hand from the pack's box of its
rounds at REFILL_MULT times the reload. The box is the camp's boxes of that type; a runner with none gets
`G_BOX_ROUNDS` (250). Boxes found in crates or on men go in. A primary that can't fire here (no rate, no magazine) is
swapped for the fixture's rifle, said on the HUD; skills the slice doesn't play show greyed, "Not in the slice".

Controls (board C; round 2: R reloads, the third skill moved to C): WASD / left stick, mouse / right stick, left button
/ RT fire, right button / Y swap, R or Space / X reload, Q E C / LB RB LT skills, 1-4 / d-pad meds, F / A held search,
X / B held to get out, Tab / Back the kit and runner sheet (the fight held), Esc / Start pause.

Round 2's test knobs on the pause: "Gang HP" ×0.5 / ×0.25 (MAN_HP_X, the start) / ×0.15, and "Magazine" ×1 / ×2.5
(MAG_X, the start) / ×4 - a magazine's size in the slice only. The HUD's top line says which are in force.

kit_sheet.gd (H, round 2) - Tab's sheet: the worn kit in slot order (a piece picked shows the game's item head), the rig
and the pack's finds (a med into the rig, a gun worn: the bridge reads it again), the runner's stats in the game's words.

Stand-in art (round 3): Kenney's Top-down Shooter pack, by Kenney (kenney.nl), CC0 - slice/art/kenney/ holds only
the files the slice uses, with the pack's License.txt. slice/art.gd reads them straight from the PNGs (never load()),
so a picture with no .import shows in the headless smoke too.
