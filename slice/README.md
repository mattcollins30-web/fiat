# slice/ - the ARPG slice (build 72, 9 Nov; round 6 the same day)

A prototype, option A on the canvas "Lesser England - the ARPG slice": top-down and close, Hotline Miami for feel,
the game's real maths. It asks one question - is moving and shooting under your own hands fun? - before anything
else depends on it. Opened from the title's "Try the ARPG slice" button (the camp's runner, read from the autosave,
or a level-14 Poacher on a fresh camp); a sandbox, nothing it does is saved to the camp.

In: the Estate's car park, three gangs then the clear, the Poacher and three skills, the worn kit's primary and spare,
its affixes and the web as the sim reads them, men who take cover, flank and fire, a hard man, crates searched under
fire, the way out. Out: every other site and class, final art (tokens drawn in code), the heads, the County.

- slice.tscn / slice.gd (SliceWorld, W) - the world: steps everything in tick(dt); signals for the HUD; the geometry
  (sight, cover spots, collision as circles against rectangles)
- level.gd - the car park's layout and look; crate.gd - a crate; fx.gd - tracers, flashes, prompts, the crosshair (W)
- run_log.gd (10 Nov) - a line a run ended in docs/balance/slice_runs.jsonl: the run against the game's own fight
- sounds.gd (round 6) - the game's own sounds (scripts/ui/sound.gd), cued off the world's signals; no new files
- runner.gd (W) - the runner: moving, aiming (mouse, or right stick with a soft lock-on), the gun, crates, the way
  out, death and Last legs
- bridge.gd (G) - the game's maths per round, on its own copy of the runner's Sim (the camp is never written)
- gang.gd, man.gd (G) - the three gangs, the hard man, the men's cover, flanking and fire, their drops
- hud.gd (H) - the HUD per board A; pause.gd - the pause with board C's controls and the test settings;
  end_screen.gd - cleared / got out / dead; launch.gd - opening it from the title and giving the title back
- tuning.gd - every figure the sim has none for (pixels, feel, AI timings): W's block, then G's

## The two tuning knobs (build 72, the coordinator's call for feel)

- `MAN_HP_X` (tuning.gd, default 0.06 since 10 Nov, Matt: "Enemy HP is off - you don't do any damage to them"): a
  gang man's HP is the sim's times this - about a dozen landed rounds of the test Poacher's rifle a man at level 12
  (11-16 by his kit's roll). It was 0.5 from round 4, which round 5's real fire rates turned into 96-133 rounds. The
  pause's "Gang HP" button (a test setting) switches ×0.06, ×0.1 and ×0.04 live.
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
/ RT fire, right button held aim down sights (10 Nov; no pad button yet), Space dodge (round 7; no pad button yet), mouse wheel or V / Y swap, R / X reload, Q E C / LB RB LT skills, 1-4 / d-pad meds, F / A held search,
X / B held to get out, Tab / Back the Kit room (the fight held), Esc / Start pause.

The test knobs on the pause: "Gang HP" ×0.06 (MAN_HP_X, the start) / ×0.1 / ×0.04, and "Gang damage": THEIR_DMG_X
×2 (the start) / ×3 / ×1, its own (10 Nov: round 6 tied it to the gang HP knob, so turning their HP down turned their
damage up - ×6.7 at ×0.15 - and that went on Matt's "go"). The button and the HUD show the figure in force: "Test
settings: gang HP ×0.06 · gang damage ×2". A hit's shove (10 Nov, Matt: "hitting them flings them across the map"):
KNOCK_PX over the gun's rate a round, so a second of any gun's hits moves a man about 14 px, never more than
KNOCK_MAX_PX outstanding; it was added to his speed every frame and kept (3,417 px in a second of rifle fire). The magazine's knob went with build 76's
real magazine sizes by gun kind. The gun's line over its rounds reads "AR · 10 a second".

## Round 6 (9 Nov, board E; Matt: "Build it")

- The gang as a threat (man.gd, gang.gd): a man in cover leans out to a clear line, fires for G_LEAN_OUT_S, ducks back
  (G_DUCK_MAX_S and the walk at most; a stunned man's time isn't counted), and after G_LEANS leans moves to other
  cover. Waiting men file up in cover's shadow. A hurt man (under G_RETREAT_HP) falls back once of his own accord, and
  whenever he's hit.
- The search: when none of the front has seen the runner for G_SEARCH_AFTER_S, G_SEARCHERS walk to where they last saw
  him and look about; the rest hold their cover. Each search after is G_SEARCH_CLOSER_PX nearer where he really is, so a
  hidden runner is found in the end.
- The gun's kick and the crosshair (runner.gd, fx.gd): held fire opens the spread (G_KICK_HOLD_S, G_KICK_SETTLE_S),
  bursts keep it tight; the crosshair's gap is the spread at the aim, and the mouse arrow is hidden in the fight. The
  figures are first guesses; a slow gun's kick does nothing yet.
- Sound (sounds.gd): fire, the dry click (a jam too), reload, hits taken, Guard breaking, meds, kills and the streak,
  a gang arriving, the park cleared, the low-HP loop under SOUND_LOW_HP; their fire is the game's one "incoming"
  sound. None yet for crates, death or getting out; the title's music plays on under the fight.
- The end screen (end_screen.gd): cleared, it sets you against the runner alone - its time and HP lost against what
  the game's own fight would expect at this level (the bridge runs it), meds and Guard not counted.

## The run log (10 Nov, Matt: "is there anything in the slice that records this info for you to read? If not let's build it")

Every run that ends (cleared, got out, dead) adds one JSON line to docs/balance/slice_runs.jsonl (the folder git
ignores; the project run from its folder or the .exe sat in it, else the game's own folder): the time on the machine,
the class, level and guns, the car park's level, gang HP and gang damage in force, time, HP lost, kills, headshots,
rounds and hits, damage done, finds, the gang reached and men left, searches, Last legs, and the game's own fight
(game_time_s, game_hp_lost). A cleared run also carries you over the game's: time_x and hp_lost_x, the two figures
the review of what the shift keeps calibrates on. Back to the title from the pause writes none; the smoke's own runs
write none (RunLog.off). ROUND in run_log.gd is bumped with each round.

## The test runner per level (10 Nov, Matt: "level 12 with a hammer is impossible - can you provide some level appropriate gear per level selection?")

The camp's runner plays a car park up to TEST_RUNNER_UNDER (3) levels over his own. Past that, or with no runner at
camp, the test Poacher plays: SITE_LEVEL_UNDER (2) levels over the level picked (level 12: the level-14 Poacher of every
round before), the same rifle and revolver, his kit rolled at his level, the web as the bot trains a Poacher of that
level (SliceBridge.uses_test_runner, test_level, _fixture). The picker says which under its row; the HUD's plate reads
"Test Poacher · Level 14"; the run log's `fixture` and `camp_level` say who played. With the test Poacher the Kit room
is his (no camp stash). The game's own fight for him by car park level: 9 0:27, 12 3:27, 16 7:34, 22 14:22, 34 47:30,
50 123:07 - past the low 20s the same two guns fall well behind the gangs.

## Aim down sights (10 Nov, Matt: "we also need right click to aim down sights with the masin weapon with left click just being hip firing")

The right button held, the main gun up and ready (not the spare, a melee weapon, mid-reload, swap or search): the
gun's spread times G_SIGHTS_SPREAD_X (0.4), the kick counting G_SIGHTS_KICK_X (0.5), his pace G_SIGHTS_PACE_X (0.5),
the camera leaning G_SIGHTS_LEAD of the way to the aim. The hip is the gun as it was. Held at 1,300 px, 24 of 90 land
down the sights against 6 of 90 from the hip. The swap moved to the mouse wheel and V; both, and the sights' action,
are set as the runner starts (SliceRunner.ensure_actions), project.godot untouched. The run log counts `sight_shots`.
Nothing on the pad yet: LT is a skill.

## Round 7 (10 Nov, boards F to H; Matt: "build it")

Stage 1, the HUD's band and hit feedback:
- The band (board H; Matt: "the skill bar needs to sit outside of the play as the player can walk behind it and miss
  things"): the bottom HUD_BAND_H (156) px is the HUD's - the runner's panel, the gun's bar, the site's panel (with the
  test settings' line, now "Test: gang HP ×0.06 · gang damage ×2") and the minimap, all in it. The play is the screen
  above (SliceWorld.play_size); the camera stops there, so the car park's foot meets the band's top and nothing of it
  is under a panel. The mouse's aim stops at the play's foot.
- Hit feedback (board G): the crosshair's mark for a round landed (white ticks; red for a headshot; a cross for a
  kill; none for a man the fog hides), and a man's flinch - hit, he's off his aim G_FLINCH_S, at most once every
  G_FLINCH_EVERY_S. The damage numbers and the HP bar over a hurt man were there already (board A) and stay.

Stage 2, the dodge and three kinds of men (board G):
- The dodge (runner.gd): Space, DODGE_PX (240) in DODGE_S (0.25 s) the way he's walking (his aim's way stood still),
  DODGE_EVERY_S (2 s) between. It drops a reload and the sights; rounds and a rusher's swing miss him in it (a burn
  doesn't). The reload is R alone. Its tile sits between the skills and the meds.
- The men (man.gd `kind`, gang.gd kind_for, bridge.make_kind; SliceTuning's G_RUSH_, G_MARK_, G_THROW_ figures, all
  first guesses): each gang's first men are its kinds - gang 1 a rusher; gang 2 a rusher and a marksman; gang 3 those
  and a thrower - one plain man kept at least, the hard man none of them. The rusher has no gun: he comes straight
  on at 1.6 of a man's pace on 0.6 of his HP and swings in reach. The marksman stays far back on 0.8 of a man's HP:
  his line on the runner (drawn) 1.5 s unbroken, one round worth 3 s of a man's fire, 2.5 s of rest. The thrower is a
  plain man who lobs a bottle every 8 s (slice/hazards.gd): a circle on the ground 1.2 s, then a 3 s burn. Each wears
  a ring of his kind's colour till he has his sprite. `ctx["kinds_off"]` gives a check its plain gang. The game's own
  fight knows none of this.

Stage 3, the Poacher's six skills as tools (board F; Matt: "they arent interesting enough to use"). The gun stays the
star; each skill does a job it does badly. Each keeps its name, lane, energy and cooldown, and its own form in the
game's fight; this is its form under your hands (bridge.use_skill; the seconds are SliceTuning's, first guesses):
- Gin trap: put down at his feet, G_TRAPS_MAX (2) at once; the first man on it is rooted G_TRAP_HOLD_S and bleeds.
- Flush them out: thrown to the crosshair; every man within G_FLUSH_R leaves his cover for G_FLUSH_S (the smoke).
- Collared: the man under the crosshair rooted and not firing G_COLLAR_S (the hard man half).
- Clean shot: G_STEADY_S steadying (no fire), then the next round can't miss the head it's aimed at and goes through
  the first man it hits, with the game's own bonus. A dodge breaks the steadying.
- One for the pot: the nearest man to the crosshair under a quarter of his HP is down, and the magazine is filled.
- Net every hole: every man within G_NET_R of the crosshair rooted G_NET_S (they can still fire), and bleeding.
Rooted (`root_t`) is new: he can't walk, he can fire; stunned (`stun_t`) is neither. A man still waiting his turn is
none of these. A skill with no one to use it on isn't spent and says so on the news line. The marks on the ground
(the trap, the smoke, the net) are slice/hazards.gd's. The test Poacher's three slots switch on the pause between
SliceTuning.G_SKILL_SETS ("Skills: mixed / Stalking / Snares"); the camp's own runner's are his own.

Not in round 6, logged in docs/design/ideas_backlog.md: kinds of men, the hard man's own behaviour, a dodge or sprint,
head aim, half-cover, hit feedback, a sight cone.

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
set shows with no code once it lands. Not drawn yet (9 Nov): burnt_car, van, shelter_roof, drain, oil_stain, kerb,
bay_line, brick_wall, asphalt_b - in slice/art/pl/ and reachable by name (Art.pl_tex), the level still draws its own shapes.
