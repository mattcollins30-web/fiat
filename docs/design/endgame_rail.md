# The endgame, the rail and the shooter mechanics (7 Nov 2026)

The design Matt agreed on 7 Nov (the doc "Lesser England – the endgame and the rail", claude.ai artifact
8R5Vg7gF5tSQpqX9kN2FSY, every call checked) and its mockups (the design canvas "Lesser England – Before the balance
pass", claude.ai artifact VfaDCHnvxNR7RhrbKPBWLi: Main, Kit, Stats, Bunkhouse, Convoys, Auction, Allotments, Fight).
Matt, on the mockups: "It's all good and approved except boots above the bag doesn't make sense. Swap charm and boots
and it makes sense. No need to mock up that change. Proceed." The list is frozen: nothing else goes in before the
short balance pass; new ideas go to ideas_backlog.md with a date.

Figures and names on the mockups are placeholders: the figures are set here as first guesses for the short balance
pass, the names go through the language pass.

## Balance (Matt, 7 Nov)

"I'd argue there's zero point in doing a full pass until we're ready to release a playtest build." Once these four
builds land: a short pass only. The full multi-hour pass on the Legion waits for a playtest build being released. A
second short pass only if the first finds a wall.

## The order: four builds, one milestone (0.15)

1. **The fight** (0.15.0): headshots, gang helmets and armour by depth, penetration, leg and arm shots, suppression,
   scavenger, the kill streak, Last Stand, jams, hard men; what the fight view shows of them. Each mechanic is a stat
   the sim reads; build 2 gives the affixes that roll them.
2. **The items** (0.15.1): the new affixes over those stats, a visible top tier (T6, the ◆: its own mark, sound and
   log line), the 13 uniques, issued versions (three a slot, gloves and backpack added: 24), boots as a ninth slot.
   The Kit: boots where the charm was, the charm above a shorter pack (Matt's swap).
3. **The web** (0.15.2): themed fillers by the notable each path leads to (3-4 kinds rotating), shorter paths, a check
   that no path repeats a node more than twice in a row; five or six skills or notables on headshots, jams, empty
   magazines and kill counts.
4. **The endgame and the screens** (0.15.3): the convoys (with the County), the auction (with the Issue), the
   allotments (with the pumping station); the training dummy on the stats page and the totals and verdict off the gear
   screens (the top bar shows reach); the Bunkhouse as its own room; the rail at ten rooms with its statuses as chips at
   each row's top right; the Radio's Set off goes to the fight.

Then the language pass on everything new, art by the flag once it reads with test art, the bot taught the new systems,
the short balance pass.

## 1. The fight

| Mechanic | Rule (first guess) | Stat (affix in build 2) |
|---|---|---|
| Headshots | every hit rolls: a base 5% lands as a headshot for x2 damage | `head_pct` (chance), `head_dmg_pct` (multiplier) |
| Gang helmets | from depth 4 a gang man wears a helmet that cuts a headshot's extra damage: 25%, rising to 60% at the deepest | `helmet_ignore_pct` |
| Gang armour | from depth 6 a gang man's armour takes a share of each hit: 10%, rising to 35% | `pierce_pct` (ignores a share) |
| Leg shots | a share of hits are leg shots; each slows the next gang's arrival (the gang clock) | `leg_pct` |
| Arm shots | a share of hits are arm shots; the man misses more for 3 s (the existing miss chance) | `arm_pct` |
| Suppression | sustained fire fills a gang's meter; full, they fire slower | `suppress_pct` (fills faster), the meter's effect base 20% slower |
| Scavenger | a kill has a chance to put a round back in the magazine | `scav_pct` |
| The streak | kills without being hit, counted on the fight view; resets on a hit | `streak_dmg_pct` (+damage a kill in the streak, capped) |
| Last Stand | once a run, at 0 HP you fight on for a few seconds | `last_stand_s` |
| Jams | guns of the lowest tiers jam now and then: a beat lost | `no_jam` / `jam_pct` |
| Hard men | now and then one man in a gang rolls a name and one or two traits (Armoured, Medic, Spotter, Runner) and drops better | - |

The fight view: a headshot pops gold above the man ("HEADSHOT" and the number), a jam shows over your gun with its
time, a hard man has a plate with his name and trait chips and a gold-edged health bar, the streak counter top left,
Last Stand beside it when the build has it (ready / used), dmg/s top right (the fight is the one place it stays).

## 2. The items

New affixes over build 1's stats; Sleight of Hand / Double Tap are today's reload and rate affixes, kept. A top tier
(T6) above today's five, rare: a drop with one gets the ◆ mark on the item, its own sound and a gold log line.

The uniques (words are drafts for the language pass):

| Unique | Slot | Band | The rule |
|---|---|---|---|
| Grandad's Lee-Enfield | Primary | chase | Every fifth round is a headshot |
| The Groundsman's Shotgun | Primary | chase | Every hit is a leg shot: the next gang comes 30% later. 15% less damage |
| The Range Officer's Rifle | Primary | chase | Headshots ignore their helmets |
| The Allotment Zip Gun | Secondary | levelling | Jams one shot in five; when it fires, triple damage |
| The Desk Sergeant's Revolver | Secondary | chase | Never jams; the last round in a cylinder is a headshot |
| The Armourer's Box | Rig | chase | Your rounds pierce half their armour; reloads take a third longer |
| The Magpie's Pouches | Rig | core | A kill puts two rounds back in the magazine; one med fewer carried |
| The Gun Club Sling | Rig | chase | A second primary rides in the rig; it takes over when the first runs dry |
| The Bin Man's Gloves | Gloves | core | Every crate searched tops up a magazine |
| The Bouncer's Knuckles | Gloves | chase | Arm shots: men you hit miss 40% for 3 seconds |
| The Bonfire Box | Charm | chase | Every eighth kill in a run sets the fireworks off: fire on everyone, a second's stun |
| The Football Rattle | Charm | core | Your fire pins them twice as fast; pinned men fire 30% slower |
| The Lifeboat Jacket | Armour | chase | Once a run, at 0 HP you fight on for 5 seconds; a kill in that time brings you back at 20% |

Issued gear: each issued slot gets three versions, each a different rule, picked at the Issuer's counter; gloves and
the backpack get issued pieces of their own: eight slots, 24 pieces.

Boots, the ninth slot: about 30 bases over nine tiers; pace (today spread over other slots), the gang clock, leg
armour; the Postman's Boots (searches quicker, gangs come later) and Steel Toecaps (a man who reaches you takes a
kick); an issued pair. The Kit: boots in the charm's place, the charm above a shorter pack.

## 3. The web

1,320 lesser nodes, 1,223 filled from about ten generic kinds (Practised 276, Keen 188; the Poacher's longest run 12
Practised in a row). Themed fillers by the notable a path leads to, 3-4 kinds rotating; shorter paths (Matt, 22 Oct:
"more notables rather than more filler"); a check that no path repeats a node more than twice in a row. Five or six
skills or notables using headshots, jams, empty magazines and kill counts.

## 4. The endgame and the screens

- **The convoys** (opens with the County; the Radio): the cargo is named in advance (a slot, a unique, or a set);
  pick two of the crew for the hit's roles (one holds the road, one cracks the load), then a timed run on the route at
  your reach. Win: the cargo is yours. Lose or let it pass: gone, another comes.
- **The auction** (opens with the Issue; the Fence's back room): market day every few runs, four lots (a unique, a
  set piece, issued kit, now and then a sealed crate with a mythic's chance); rival camps' bids rise as you run; the
  highest bid when the day closes takes the lot; an outbid bid comes back. Soaks up fiat.
- **The allotments** (opens with the pumping station's rebuild; the Workshop, the Pitch): seeds come from crates (and
  hard men); plant on a plot, it grows by runs; a harvest is a sure craft at the Bench: add a chosen element, take an
  affix off, or raise one a tier. No rerolling.
- **The training dummy** on the stats page, one click from the Kit ("Test on the dummy"): run the build against a gang
  man or a hard man for a set time; dmg/s, a timeline with the reloads, headshots, bleeds, reload time, under-half-HP
  share. Totals and the Upgrade / Sidegrade / Downgrade verdict come off the gear screens: a gun shows its own figures
  (damage a shot, rate, magazine, jams), the try-on compares affixes line by line. The top bar shows reach (the
  furthest level cleared). The site card's "% to clear" stays.
- **The Bunkhouse** as its own room on the rail (opens with the Quartermaster's fall, scrambled before): the hired
  hands, the expeditions out and back, the far places. Its chip: "2 out", "Back" in the warn colour.
- **The rail** at ten rooms: each status a small chip at its row's top right (a word as well as a colour), the space
  above and below each glyph cut (rows about 52 px); fit checks at both window sizes, the longest name with its longest
  chip, the folded rail.
- **The Radio's Set off** moves the player to the Map with the run open, as the Map's Set off does.
