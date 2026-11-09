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

- `MAN_HP_X` (tuning.gd, default 0.5 since round 4, Matt: "0.5x HP is the better setting"): a gang man's HP is the
  sim's times this. At the game's own figures a man takes about 38 rounds - a sponge under your own hands. The pause's
  "Gang HP" button (a test setting) switches ×0.5, ×0.25 and ×0.15 live.
- (build 76) The car park's level is picked at the start (level_pick.gd, H): the default is the camp's reach (its
  furthest cleared level, Sim.deepest_cleared_level), or 12 on a fresh camp (no runner, or nothing cleared), with three
  levels either side (H_LEVEL_STEPS), never under level 9: levels 1 to 9 play the same fight (round 5's review). The
  smoke's fixed-seed open goes straight in at the default; `SITE_LEVEL_UNDER` (the runner's level less 2) is only the
  bridge's rule when no level is given.

The rounds: each gun's spare magazines, then (the sim's refill) a magazine filled by hand from the pack's box of its
rounds at REFILL_MULT times the reload. The box is the camp's boxes of that type; a runner with none gets
`G_BOX_ROUNDS` (250). Boxes found in crates or on men go in. A primary that can't fire here (no rate, no magazine) is
swapped for the fixture's rifle, said on the HUD; skills the slice doesn't play show greyed, "Not in the slice".

Controls (board C; round 2: R reloads, the third skill moved to C): WASD / left stick, mouse / right stick, left button
/ RT fire, right button / Y swap, R or Space / X reload, Q E C / LB RB LT skills, 1-4 / d-pad meds, F / A held search,
X / B held to get out, Tab / Back the Kit room (the fight held), Esc / Start pause.

The test knobs on the pause: "Gang HP" ×0.5 (MAN_HP_X, the start) / ×0.25 / ×0.15, and (build 76) "Their damage" ×1
(THEIR_DMG_X, the start) / ×1.5 / ×0.5 - their damage a round. The magazine's knob went with build 76's real magazine
sizes by gun kind. The HUD's top line says which are in force; the gun's line over its rounds reads "AR · 10 a second".

kit_room.gd (H, round 4; it replaced round 2's kit_sheet.gd, Matt: "why reinvent the wheel") - Tab's Kit room: the game's
own scripts/ui/armoury.gd on the slice's Sim (the camp's copy: its whole stash to wear), the run put by while it's open
so the room isn't locked "out on a run", the Workshop greyed, the dummy and the loot filter hidden. A run's finds go
into that Sim's stash (the room's grid; a box of a gun's rounds into the pack's count). On the way back the bridge's
kit_changed reads the guns (each with its own rounds), the rig's meds, the maxima and pace into the fight. The room's
gun cards show the game's magazine; the slice's (its kind's, build 76) is on the HUD.

Stand-in art (round 3): Kenney's Top-down Shooter pack, by Kenney (kenney.nl), CC0 - slice/art/kenney/ holds only
the files the slice uses, with the pack's License.txt. slice/art.gd reads them straight from the PNGs (never load()),
so a picture with no .import shows in the headless smoke too. (build 76) The PixelLab set (tools/make_art76_manifest.py,
by art.flag) lands in slice/art/pl/: art.gd draws a set picture by name when it's there (runner/gang1-3/hard x
aim/fire/reload/down; asphalt_a, paving, kiosk_floor, kiosk_wall, crate, the bins, fence) and Kenney's when not, so the
set shows with no code once it lands.
