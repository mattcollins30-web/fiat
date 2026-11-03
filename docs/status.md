# Fiat — status

The idler cut of FIAT. Concept: `docs/design/concept.md`. Repo at `C:\Users\mattc\Documents\fiat`.

## Now, next, parked (the board: updated with every delivery commit)

- **Now (3 Nov):** 0.12.1 - the skill web (0.12.0) with its art back: small nodes' pictures and glyphs, the regions'
  emblems, the class portrait. Fresh save from 0.12.0 (SAVE_VERSION 23). The spec: docs/design/skill_web.md. Art
  flagged: one job (Guarded, the centre's Guard small).
- **Next:** Matt's playtest of 0.12.1, through to the County and fiat. No balance pass until then (CLAUDE.md, 2 Nov).
  The language redesign (docs/design/language.md) - the rename pass, parked 3 Nov.
- **Matt's word wanted (the skill web, 3 Nov):** the Quartermaster's Manual has no rule left (its words still promise
  more than 2 elements); 25 hung notables have no slot on the web (data.gd WEB_DROPPED - the three open gates could
  take some); the Headmaster's Cap's words don't say its capstone waits for 40 spent; Second wind reads "at home";
  the six third keystones and the hung skills sit on filler slots (builder's call, so nothing left the game); Training's
  intro line re-records (docs/voice/recording_list.md); the room card's tiles still say "Their trees".
- **Voice (3 Nov):** Matt regenerates the lot from docs/voice/scripts.md and passes the takes back for wiring and
  cue-syncing. Today Training's and the Fence's cards play old takes under new text; the five class intros were never
  recorded (no cues); the Workshop's new line waits for its take. Stale lines suggested there (the Pitch -> home,
  "camp", "move on", "deeper", "the doctor"). No ElevenLabs voice ids are on record: write them into recording_list.md.
- **A game gap found by the flake fix (Matt's word):** at a picked-over site a rolled run event never comes - the lull
  waits for a first search there's nothing to make. Suggested: open the lull when nothing's left to search.
- **For the balance pass (from the reviews, 2 Nov):** the swap affix lifts a gun's fire share to 1.0 (+13-30%); the
  bot packs up to a quarter of its pack in rounds boxes; "Press on" (+25-50% loot quality for the run) taken at 80%
  odds by default; "Go through the pockets" a trap against "Search it"; "Cut it open" beats "Strip it"; rooms at half
  last until that site's next clear (the bot only clears it by chance).
- **Matt's word wanted (small):** the site card's low-HP and wound chips go to the Clinic (the design said the Kit);
  the foot button that takes a head on now reads "Take him on" (the glossary had "Head"); the card's fight rows stay
  in words (the style guide now says so for this card).
- **Open notes (small, no date):** the bot never spends on another class's start or skills, but no check holds it to
  that; a path's step count can run through a neighbour's useless start; the web's picked-name plate keeps its spot
  after a pan; rounds_panel.gd's short row line logs a formatting error (16 a smoke, older than 0.12.0); a late-save fight isn't timed by the smoke's speed guard (it prints 0); dogs on a
  repeat run read their odds in one lump (~0.3 s); the Scrapper never ran the Mint (the bot's build); "13 ObjectDB
  instances leaked at exit" at the smoke's end (not in the bar).
- **Parked from the playtest:** (none open - the 0.10.6 three are built in 0.11.0)

## First slice (2026-10-01)

Built. One operator, the Ring Road in three tiers, missions as the idle action with combat as numbers, loot with
affixes, KIA takes the loadout, Extract now, the Black Market, the Medic Tent, the depot clear as the win. One
autosave at `user://fiat.save`. Esc pauses, F8 is ×10 speed.

## Second slice (2026-10-01, same day)

From the first playtest (the depot in 33 minutes, no deaths, a real gear choice with no way to act on it):

- **Variance**: both sides' damage swings ±25% a second. Combat was deterministic, which is why it felt safe.
- **Survival %** on every open tier card, from forty dry runs of the fight with the current loadout and HP;
  cached until the figures it depends on change. Card edge green ≥ 90%, amber ≥ 60%, red below.
- **Two-card combat**: a *Contact* card (the hostile in front: its HP as the bar, incoming, your fire, kills)
  and the *Mission* card (progress bar, pack, cash, XP, Extract now), plus *In the pack* listing what's found.
- **The search phase**: clearing the pool ends the fight, not the mission. A cache gives up an item every 5 s;
  a patrol arrives every 20 s, each one bigger (2, 3, 4...), and has to be fought before searching goes on.
  Extract any time. Outcomes: Extracted, Early out, Under fire, KIA.
- **Auto-run** toggle on each tier card: rests to 95% HP (70% until the balance pass), redeploys, extracts at the first patrol or a full pack,
  stops on KIA or a full stash.
- **The Armoury screen** (`scripts/ui/armoury.gd`): the first thing in the shell that isn't eight cards. The
  body's six slots down the left, the stash as an 8×5 grid on the right (a cell: slot short name, headline
  figure, tier, rarity as the border - the shape an icon drops into later), and a compare panel under the grid:
  the selection against what's fitted in its slot with the deltas, and Equip / Unequip / Sell.

Playtest two (same day) fixes: the tier cards hide while a mission runs; the Contact bar is labelled "Hostile
HP" and an Operator card carries "Your HP" in green; the Armoury's compare panel is taller (stash cells 104 px)
so its four lines clear the buttons, the swap line splits in two, and the selection follows the item after
Equip / Unequip; the Black Market's Sell card has a button per rarity, coloured by it.

Engagement cap (playtest two): at most three hostiles fire at once (`Sim.CONTACT`); the rest join as the ones in
front drop. Before, every hostile alive fired, so a fight was decided in its first twenty seconds and the back
half was safe; now incoming stays level and the search phase's patrols are fights rather than spikes. The dry
runs behind the survival % use the same rule. The bot's depot run went from 1.3 to 2.6 simulated hours, mostly
rest time, with the tier numbers untouched.

## Meds and the rig (2026-10-01, playtest two)

The rig carries consumables, the backpack carries loot - Tarkov's split. Medical items (Bandage 25 HP in 3 s,
Medkit 60 in 6, Surgical kit 120 in 10; a `heal_pct` affix on the rarer ones) are items like any other: in the
stash, in the Armoury grid as MED, found rarely in caches (8% of finds), bought common at the Medic Tent at
×1.5. The Armoury's body column has a seventh row, *Carried*, showing the rig's contents; a med selected in the
stash offers Take, one in the rig (the Carried row cycles through them) offers Leave. On a mission the Operator
card offers "Use bandage" / "Use medkit" - manual only for now; using one takes its seconds under whatever fire
there is, then heals. KIA loses the rig's meds with the loadout. The survival % assumes a med is used under 40%
HP, as the bot does. The starter kit is a chest rig with two bandages.

Bot after this: the depot in 21 missions, 90 meds used, no KIA, 2.1 simulated hours.

## The tree (2026-10-01, playtest three)

Barracks, the sixth room, is a screen: three branches as three columns of twelve nodes each, a chain, with a
notable every fourth. Marksmanship (+3–4% damage; Double tap, Overwatch, Headshots), Conditioning (+4–5 max HP;
Triage, Second wind, Plates), Fieldcraft (+3–4% loot find; Scavenger, Quiet feet, Pack mule). Points are the
camp's: one a level, kept across operators, so a KIA costs the levels not the training; a respec is £50 a
point. `Data.TREE` is where classes plug in next. A save from before gets level − 1 points.

Bot after this: the depot in 8 missions and 0.7 simulated hours with every point spent — the content is now the
ceiling, not the operator. Map modifiers or a fourth tier is the next lever on that.

## Depth and intel (2026-10-01, playtest three)

The ladder. Every tier has a **depth**, 1 up: each step is hostiles +25% HP and fire, rewards +30%, drops +5
points, rarer finds; clearing a depth opens the next on that tier (Depth − / + on the tier card). **Intel** is
the mission's modifiers, Path of Exile's maps as a brief: one on tier 1 at shallow depth, two otherwise, from
a pool of ten with an upside and a downside each (Reinforced, Dug in, Night, Resupply run, Known route,
Scattered, Flush, Quiet, Veterans, Looted already), re-rolled after every mission (and, until the playtest caught it being gamed, on a depth change), shown
on an Intel card beside each tier. `Sim.effective(i)` is the tier as it will be fought; the mission snapshots
it, and the survival % reads it.

Tree costs now rise down each chain: 1 point for the first four nodes, 2 for the next four, 3 for the last
four, a notable one more - 27 a branch, 81 in all, against 49 points by level 50. Fieldcraft's small nodes
alternate loot find and **search speed** (+15% each, four of them), so searching has somewhere to improve.

Bot: the depot (depth 1) in 5–10 missions as before, then climbing; after 1.5 simulated hours it sits around
depth 4–8 across the tiers with every point it can afford spent and still no KIA, because it only climbs when
the odds read ≥ 90%. A human who climbs faster will meet the deaths the bot refuses.

Missions is now a screen between missions (`scripts/ui/missions.gd`): a column per tier with the survival %
big and coloured, the depth with − / + either side, the hostiles and rewards as figures, the intel's two
modifiers with their words, and Deploy with Auto-run under it. The tier-plus-intel card pairs that replaced
it read as six unrelated cards. While the operator is out, the live cards (Contact, Operator, Mission, In
the pack) take the grid.

## The Workshop (2026-10-01, playtest three)

Attachments are a new item category: twelve of them across the five mounts the guns already carried (red dot,
holographic sight, scope; flash hider, compensator, suppressor; extended and drum magazines; foregrip and rail
handguard; folding and heavy stocks), each with effects the sim already read - damage, pace, first-hostile
damage, patrol delay - and affixes on the rarer ones. They turn up in caches (12% of finds), on the Black
Market (a third of its stock), and show in the stash as ATT. A gun's damage/s is its damage as fitted, so the
Armoury, the compare panel and the operator's figures all see them.

The Workshop is the seventh room and a screen on the Armoury's shape: the two guns and their mounts down the
left, the stash's attachments for the selected mount on the right, a compare panel ("Fitting it: 43 → 51
dmg/s") with Fit, Strip and Sell, and the bench's level under the guns. The level is the cash sink: £800
opens optics and muzzles, £2,500 adds magazines, £6,000 opens every mount. A mount above the bench's level
reads "Needs workshop 3".

Bot: buys the bench as soon as it can with £500 spare, fits the best of each mount after every mission, and
with the tree, attachments and depth climbing together reaches depth 17–25 on the deeper tiers inside 1.5
simulated hours at level 50 and ~270 dmg/s, still without dying. The depth ladder's +25% a step is now
clearly flatter than the operator's growth; that's the next balance pass, after a human has climbed it.

## The Docks and classes (2026-10-01, playtest three)

**The Docks** is the second zone: container yard, customs sheds, the bonded warehouse - bigger pools (12 / 16
/ 20), more fire, cash-heavy caches, and the newest tier-3 bases only found there (bullpup rifle, combat
shotgun, machine pistol, ceramic plates). It opens when the depot is cleared. `Data.ZONES` lists the zones and
the global tier indices they own (0–2, 3–5); the Missions screen has a zone row across the top and shows the
chosen zone's three columns. A zone's tiers open in order within it (`Sim.tier_open`). Old saves extend their
depth / intel arrays.

**Classes** are the operator's, picked on a bar across the top of the Barracks, free to change in camp:
Recon (+40% first-hostile damage, patrols 25% slower, −10% HP), Enforcer (+15% damage, armour counts 20%
more, −10% pace), Medic (meds heal 50% more and are used by themselves under 40% HP, −10% damage), Saboteur
(searches 30% faster, +15% loot find, −5% damage), Ghost (one fewer in contact, +10% pace, −15% HP). Each is a
set of multipliers the sim reads by key (`Sim.cm`); nothing gates what can be fitted. Auto-use of meds lives
in the Medic rather than as a toggle.

Bot: picks Enforcer; the Docks' tiers reach depth 6–10 inside the run. Every feature on the concept's list is
now in except offline missions, save slots and hardcore; the balance pass waits for those.

## The inventory rework (2026-10-01)

Items have a footprint in cells (a rifle or armour 3, a pistol, helmet or rig 2, a pack 3, a med or attachment
1); the stash is 48 cells at level 0 and 64 / 80 / 96 by camp upgrade; the pack's capacity is cells too (day
pack 6, assault pack 12, rucksack 20), so a rifle in the pack is three bandages' worth of room, and a find
with no room swaps for the cheapest thing at least its size. `scripts/ui/inventory.gd` is one grid for the
Armoury and the Workshop: cells sized by footprint flowed eight a row, four rows a page with paging; a bar of
kind filters (All, Guns, Armour, Carry, Meds, Attach), rarity filters, a sort (value, newest, slot), and a
Select-many mode with "Sell 3 for £412". Rarity stays the border. The Workshop's grid is the same component
fixed to attachments and narrowed to the selected mount. The decision taken on footprints: sized cells in a
flow, not Tarkov's 2D Tetris - the size matters to what fits, the shape doesn't, and a 2×1 cell wants a
picture the no-art rule doesn't have yet.

The smoke test no longer uses `assert` (a failed one ends `_init` before `quit()` and leaves the headless
process hanging); `_check` logs and counts, and the run exits 1 at the end.

## Comms Tower and camp upgrades (2026-10-01)

Four cash sinks beside the Workshop, each a card with an Upgrade button in its room: the **stash** (48 → 64
→ 80 → 96 cells, on the Camp's Cash card), the **Medic Tent** (rest 0.5 → 1 → 2 HP/s), the **Black Market**'s
shelf (3 → 5 → 8 items), and the **Comms Tower**, the eighth room: level 1 buys fresh intel on a tier for cash
(£60 to £650 by tier), level 2 pins a tier's intel so missions don't re-roll it. A pinned
tier says so on the Missions screen. The Comms room shows every open tier's intel with New intel / Pin.

## Offline, save slots, hardcore (2026-10-01)

The feature roster is done; what's left is the balance pass and art.

**Offline**: the autosave stamps the time it was written. On Continue, the time away (60 s or more) is run
through the sim in ten-minute chunks up to a cap of eight hours (`Data.AWAY_CAP_S`): rest if the operator was
in camp, auto-run missions if auto-run was on. `Sim.advance` was rewritten to run any span - a frame or hours -
through rest, the redeploy point and missions in order, so the offline span plays as the live one would
(before, a mission ending mid-chunk dropped the rest of the chunk). A "While you were away" screen gives the
time, the cash and item change and the level, or "The operator rested."

**Save slots**: three, beside the autosave (`user://fiat_slot1..3.save`). "Save to a slot" on the pause menu
(overwrite asks twice), "Load a slot" on the title; each slot and the Continue row show level, cash, time
played and when it was saved. Loading a slot settles its time away too.

**Hardcore**: "New camp, hardcore" on the title. A KIA sets `camp_lost`: nothing restocks, the autosave is
removed, an opaque "The camp is lost" screen goes back to the title. Slots survive it (a hardcore slot loaded
is still hardcore). The pause menu says "Hardcore camp".

The smoke test now round-trips a slot, runs three hours away on auto-run and a day away resting (checks the
cap holds and the HP fills), loads a save stamped two hours old and expects the away screen, and ends a
hardcore camp with a KIA (no save written, autosave gone, slot kept, title with no sim).

## The balance pass (2026-10-01)

One pass, with the bot as the first reader, now that the feature set is final. `tests/balance.gd` is the
reader: `tests/bot.gd` plays like a pushy player (deploys where the survival estimate is 75% or better,
steps a tier's depth back when it isn't, climbs when it reads 90%, bails at a quarter HP, leaves after two
patrols or a full pack, fits the best of everything, trains, buys the camp with £500 to spare, sells spares)
and the reader prints a line every thirty simulated minutes. `-- 8 Enforcer` reads eight hours;
`-- 8 Enforcer 25` prints the first 25 missions one by one. Read it before touching a number.

Before: the Docks opened at 18 min, every tier was cleared by 28 min, level 50 and every camp upgrade by
1.5 h, £1.4M by 5 h, and depth climbed to 39 on the first tier because rewards (+30% a depth) outgrew
hostiles (+25%) and both were linear while the operator compounded.

What changed, and why:

- **Depth compounds** - hostiles ×1.25 a depth, rewards ×1.12 - so every tier has a depth the loadout
  holds and a deeper one it can't, instead of a ladder that gets easier. The Rewards line on the Missions
  screen reads the new figure.
- **The gun ladder is flatter**: tier 1 → 2 → 3 base damage a second is now 17–22 → 31–35 → 46–52 (it was
  17–22 → 43–48 → 56–68), so one lucky drop no longer doubles the operator. Attachments trimmed a touch
  (drum 14%, holo 8%).
- **Armour** mitigates a/(a+150), not a/(a+100): a tier-1 set stops 12%, tier 2 24%, tier 3 39%, the full
  Enforcer-with-Plates stack 48%. It was hitting 44% at minute 12.
- **Tiers**: hostile HP 200/280/420 on the Ring Road and 1100/1300/1500 on the Docks, fire 0.4/0.35/0.7 and
  1.4/1.8/2.4 a second, drops 20–30% a kill. The Docks are a real step - about three times the depot.
- **XP** a kill 2/3/6/10/15/20 (was 12–140) and the clear bonus is 0.3 of a kill per hostile in the pool
  (was 0.5). Level 10 lands about an hour in, 20 at two, 30 at three and a half, 40 at six; 50 is the
  long tail.
- **Cash**: a kill pays 6/9/14/22/24/30; tier 2–3 gear and attachments are worth half what they were (a
  rare ceramic plate sells for ~£770, not £2.5k); the market marks up ×3. Camp upgrades cost more at the
  top (stash to £15k, bench to £14k, £64k for the lot) and land between 0:36 and 3:50.
- **Searches** every 10 s, not 5.
- **A KIA hands the new operator worn kit** (rifle, vest, rig, pack, two bandages) - with the old numbers a
  death with an empty stash and no cash left the camp with fists and no way back.
- **Auto-run rests to 95%**, not 70%: a worn operator redeploying at 70 HP into a run that costs 60 was
  dying offline.

After, eight hours as the Enforcer: tiers 1 and 2 at 0:29 and 0:36, the Docks at 1:06, 1:27 and 2:31;
camp bought out by 3:50; level 40 at six hours; depth 3–4 on the Docks; £70k in hand at 5.5 h with nothing
left to buy, which is the one open end - loot is cash and the sinks run out. Recon, Ghost and Medic read
within half an hour of the Enforcer. The bot never dies because it never deploys under 75% - the KIA rate
is a human's to find.

## The language pass (2026-10-01)

The words were Tarkov's. Now they're Fiat's: Britain after the money stopped, *The Rover*'s tone - plain,
local, nothing military unless it was looted from the army. Code keys (`depot_cleared`, `operators_lost`,
`patrols`, slot names) are unchanged; only what the player reads. Old saves map the class and branch names
on load.

| Was | Is |
|---|---|
| Camp · Missions · Armoury · Workshop · Barracks · Medic Tent · Black Market · Comms | The Yard · Runs · Lock-up · Bench · Caravan · Clinic · The Fence · Radio |
| operator, mission, deploy, extract, KIA, loadout | runner, run, set off, get out, dead, kit |
| hostiles, in contact, patrol, cache, intel, pinned | them, on you, a lot (the next lot comes), pickings / picking it over, word, pinned |
| Extracted / Early out / Under fire | Back / Cut and run / Back, chased |
| The Ring Road: outer checkpoints, fuel yards, the depot | The Estate: ransacked streets, the parade, the retail park |
| The Docks: container yard, customs sheds, bonded warehouse | The Town: the pleasure park, shopping centre, the bank |
| Worn hunting rifle, pump shotgun / AK, AR carbine / marksman, bullpup, combat shotgun | Nail gun, farmer's shotgun / semi-auto .22, workshop SMG / stalking rifle, army bullpup, AR-pattern rifle |
| Makarov, 9mm service pistol, revolver, machine pistol | Converted blank-firer, service pistol, old revolver, machine pistol |
| Soft vest, plate carrier, heavy plates; ballistic helmet | Stab vest, police body armour, army plates; army helmet |
| Chest rig, load-bearing vest; day pack, assault pack, rucksack | Bum bag, fishing vest; school bag, hiking pack, bergen |
| Medkit, surgical kit; holographic sight, scope, suppressor | First aid kit, trauma kit; holo sight, telescopic sight, oil-can silencer |
| Recon, Enforcer, Medic, Saboteur, Ghost | Poacher, Doorman, Paramedic, Scrapper, Drifter (what the runner was, before) |
| Marksmanship, Conditioning, Fieldcraft | Shooting, Hard living, Scavenging (nodes reworded to match) |
| Reinforced, Dug in, Resupply run, Known route, Scattered, Flush, Quiet, Veterans, Looted already | Numbers, Tooled up, Delivery day, Quiet road, Spread out, Cash about, Lying low, Ex-army, Picked over |

The AR-pattern rifle took the combat shotgun's tier-3 slot (16 dmg × 3.0/s, same 48 dps). The smoke test
caught one line that no longer fit ("The town opens at the retail park" on the Yard's zone card) and it's
"Clear the retail park" now.

## Builds (2026-10-01): class trees, weapon types, conditional affixes, keystones, the yard's upgrades

The first systems slice after the balance pass - the thing that makes "what the runner was" a build rather
than a multiplier.

**Trees.** One common tree, *The yard* (12 nodes: damage, HP, loot, looks; Double tap, Second wind, Pack
horse as its notables), and two 8-node trees per class, shown as three columns in the Caravan with the
yard's in the middle. Each class tree has a notable at 4 and a **keystone** at 8 that breaks a rule outright.
Costs: 1/1/1/2 · 2/2/2/4 down a class tree (keystone +2), 27 for the yard's, 57 on show against 49 points, so
nobody finishes. Changing class refunds its two trees for nothing and keeps the yard's; Respec (cash)
clears everything trained. Old saves keep what's on show and refund the rest. Poacher: Stalking (first-hit,
lots later; *One shot* - the first of every lot drops) and Snares (looks, loot, rarer; *Trapline* - every lot
one short). Doorman: Muscle (damage, armour; *Bodyline* - with three on you, half damage) and The door (HP,
armour; *One at a time* - one on you ever, −25% pace). Paramedic: Triage (meds heal more and faster, +1
carried; *Field surgery* - meds work at once) and Shifts (rest, cheaper treatment, *Walk it off* heals 1/s
while picking over; *Not today* - the first death in a run is half HP instead). Scrapper: Stripping (more
attachments found, looks, *Bodger* +40% with improvised guns; *Nothing wasted* - every kill drops) and
Fencing (the fence pays more, cash, rarer; *Buyer's market* - the fence pays double, buying costs double).
Drifter: Moving on (pace, lots later, *Spray* +25% with SMGs; *Never there* - no lot ever comes, pickings
take twice as long) and Luck (rarer, cash, *Dead man's shoes* +20% damage under half HP; *All or nothing* -
nothing common is found, half as much is).

**Weapon types.** Every gun is improvised, shotgun, rifle, SMG or pistol (`type` in `BASES`; the Lock-up
shows it). A node with a `type` only counts while the primary is that type - Rifleman (Poacher: the first of
a lot takes double), Shotgunner (Doorman +25%), Bodger (Scrapper), Spray (Drifter). A trained node that's
idle for want of the gun shows grey-edged in the Caravan and says so in the panel.

**Conditional affixes** - five that pay only in a situation: damage under half HP (guns), damage on the
first lot (primary), loot per lot survived (pack, rig), armour per med carried (rig, armour), cash a kill
(helmet, pack). `Sim.dps()`, `armour()`, `loot_bonus()` and `_kill` read them.

**The yard's upgrades**, three cards on the Yard: Generator (hours away that count: 8 → 12 → 24; £4k,
£12k), Lookout (the first lot takes ×1.5 then ×2 as long; at level 2 the odds come from 200 dry runs, not 40;
£3k, £9k), Kennel (a dog finds one more every look; a good dog hears the next lot 20% later; £2.5k, £7k).
`Data.AWAY_CAP_S` is gone; `sim.away_cap_s()` reads the generator. Selling goes through `sim.sell_price()`
everywhere so Fencing and Buyer's market show on the buttons.

Balance after, same reader, eight hours as the Doorman: tiers 1–5 at 0:14, 0:36, 0:38, 1:09, 3:28; the
sinks now run to 4:19 (kennel 1:23, generator 1:43, lookout 1:59, then the second levels to 4:19), which is
what the late cash was for. Level 33 at 5 h. The bot trains the trees greedily in column order, not as a
build; what a human does with One shot and a stalking rifle is the playtest.

## Fixes from the playtest (2026-10-01)

- Stepping a tier's depth up and down re-rolled its word each time, so the word could be fished for.
  `set_depth` no longer touches it; the word changes after a run only. Juicing a site PoE-style - paying to
  shape the word - is noted for later.
- "Pack 6 of 6 cells" beside "In the pack: 3 items" read as a contradiction because cells were never shown
  on a run. The pack card now carries a cells bar (6 of 6), each item's cells on its line, and two buttons
  for making room while the site is picked over: Ditch worst (the cheapest thing, named in the note) and
  Ditch junk (every common). `Sim.ditch(id)`, `ditch_commons()`, `cheapest_in_pack()`.

## The fit check, properly (2026-10-01, after the Run screen clipped)

The Run screen went out with its lines drawn over each other - the panels were laid out on paper and the
test only measured text widths. Greenhorn's lesson again, so the test is the fix: `_check_fit` is one
generic pass over whatever is showing (cards, the rail, every screen) and it asserts three things for every
label and visible button with text. Its text fits its box (a button's text plus the 32 px of margin a
button needs - which caught "Attach", "Select many" and "Sort: newest" on the grid bars, and "Uncommons" on
the Fence). Its box sits inside its parent top to bottom. And no text sits on any other text: each label's
text rect, from its alignment, against every other - so a headline and its unit can share a box, but a
note drawn over a line fails, and so does a page label under a sell button. Label-and-value pairs on a line
are still checked as pairs with 16 px of air. The check walks positions up the tree by hand because,
headless, a child's cached global transform lags a parent that moved since the last frame.

What it found and what changed: the Run screen's panels are relaid (title, headline, bar, lines, note; a
panel with a button shows two lines and its note above the button, one without shows three and a status
line), the grid's two bars are relaid to measured widths ("↕ Value", "Select"/"Single", "Sell 3: £240",
"Ditch 3: 5 cells", pages as "1/2"), the Fence sells by "Common / Uncommon / Rare / Elite", and the top bar's
"Out: …" slot is measured with the font it uses so it doesn't ellipsise.

## The rig and the pack as grids, with drag and drop (2026-10-02)

The Lock-up's Carried row is gone; under the six body rows the rig is a row of slots (`scripts/ui/
containers.gd`) and the pack is its cells, drawn empty - what a run brings home; nothing goes out in it.
Drag a med or a stack from the stash onto the rig to take it, drag a rig slot back onto the stash to leave
it, or press a rig slot to select it for the panel's Leave. The stash grid gives drags out (`drag_src`) and
takes drops (`accepts`, `dropped`); the rig row forwards drops through `set_drag_forwarding`. A press that
moves ten pixels becomes a drag, so a plain press still selects. Take and Leave on the panel stay. The
smoke test drops through `_can_drop`/`_drop` directly, since a headless run can't move a mouse.

## Footprints, the body, the art hooks, the studio card (2026-10-02)

Matt: "on the bag cells we probably need to rethink what the cell size actually is. we also need a body to
drag items onto in terms of slots rather than a flat list". Built as agreed:

- **Footprints.** A cell is 64 px (`Pal.CELL`, gap 6). Every base has a W×H footprint - the slot's default
  in `Data.SIZE` (primary 4×1, secondary 2×1, helmet 2×2, armour 3×3, rig 3×2, pack 3×3, med/ammo/part
  1×1) with the exceptions in `Data.FOOTPRINTS` (short guns 3×1, scoped 5×1, riot suit and plate carrier
  3×4, small bags 2×2, big packs 3×4, kits 2×1, surgeon's kit 2×2, optics 2×1). `Items.footprint(it)`;
  `Items.size(it)` is the area, so the sim's capacities still count cells: stash 98/140/196/252 (fourteen
  a row, seven rows a page), pack capacities doubled (12 to 72), Pack horse +6, no pack 2. Rig pouches
  stay a slot each.
- **The grid packs.** `inventory.gd` places items first-fit (rows then columns, never across a page edge)
  into 14 columns; the sim counts areas, the grid places. When first-fit can't fit everything inside the
  capacity's outlines, the outlines extend to the reach - every item on a drawn cell, and the bag reads as
  awkward rather than merely full. Manual placement is a later slice if this feels wrong in play.
- **One cell, everywhere** (`scripts/ui/item_cell.gd`): a button the footprint's size, rarity as a 2 px
  border, the item's picture from `art/items/<slug>.png` if it exists (fit and centred, nearest-neighbour;
  ammo keeps its rounds in the corner) and short words if not - two 16 px lines in a 1×1, name and figure
  across a row, name/figure/tier in anything taller; the slot's short code when the name won't fit. `Items.
  slug(base)` lowercases and turns every run of non-alphanumerics into one underscore (`farmer_s_shotgun`,
  `semi_auto_22`); uniques draw as their base. Looked for once; an export loads the imported texture.
- **The body** (`scripts/ui/body.gd`): the six slots as boxes laid out as a figure - helmet and secondary
  down the left, armour and rig on the right, the backpack down the left under them, the primary along the
  bottom - each box the slot's largest footprint. A stash item dropped on its own slot's box equips (a
  swap puts the old one in the stash; `Sim.can_equip_item` checks the room, since footprints differ now);
  on any other box it is refused. Drag the fitted item off and the stash takes it (`src: "body"`) -
  unequip. Press it to select it for the compare panel, which keeps Equip / Unequip / Sell. The six text
  rows are gone; the compare panel is where the affixes read now. The rig pouches and the pack map sit
  under the body (pack map 15×6 small cells for the 78-cell worst case).
- **Art pipeline** (`tools/`): Greenhorn's `pixellab_batch_v2.gd` copied in unchanged; `make_item_manifests.
  py` writes nine manifests from `data.gd` - one a type, two seeds a base, each job sized footprint × 64 -
  to `art/items/candidates/<slug>_a|b.png`; promote by copying up to `art/items/<slug>.png`. Long guns run
  first with no style image; three or four promoted guns go to `art/reference/items/ref_01..04.png` and
  every other manifest rides them as `style_image`. The secret isn't copied. Second cut the same day (Matt: "only a single image ... place them directly in
  the correct folder with the correct name"): one job a base, `"single": true` (a flag added to Fiat's copy
  of the runner: the first candidate written to `out` exactly, no `_NN`, no sheet, no `_response.json`),
  `out` the live `art/items/<slug>.png`, existing files skipped so a rerun fills gaps. A tenth manifest,
  `uniques`, gives the four uniques their own pictures at their base's footprint (`grandad_s_shotgun.png`
  etc.); `Items.art` looks for the unique's own slug first and falls back to the base's.
- **Studio card and title** (`scripts/ui/intro.gd`, `menu.gd`): black, the mark from `art/studio.png`
  (the name in type until then) fading in and out, any key skips; then the title, which stands on
  `art/title.png` when it exists (covering the screen, the menu panel on dark glass at the left) and on
  the plain ground until it does. `Main.intro = false` for the tests.

Second pass the same hour, from Matt's screenshot: a fitted item FILLS its box whatever its own footprint
(`ItemCell.show_item`'s `box` argument; the picture keeps its aspect inside it), and the dead strip down the
right of the screen is gone - the grid is thirteen columns (904 px, stash 91/130/182/234) and the left column
takes the rest (`Inventory.SIDE_W`, 608) on every grid screen, so the body lays out in three columns (helmet
and secondary, armour, rig and backpack; the primary along the bottom, 420 tall) with the rig's pouches as
full 64 px item cells (eight a row, two rows) and the pack map at 32 px cells (16 × 5) under it.
Then a paper doll (Matt: "the silhouette would be good for the armory regardless"): a flat figure drawn by
`body.gd` itself (`_draw`, head/shoulders/arms/legs in the card-line colour) stands between the columns -
helmet, secondary and backpack down the left, armour and rig down the right, the primary along the bottom
under all three, 560 tall; `art/body.png` replaces the flat one: Matt's standing runner, generated at 208 × 488 and cropped to its
99 × 291 of figure, scaled to the box's height (1.68×, nearest) - reads well; a regeneration that fills the
frame would make it crisp. A first cut put the figure *behind* the boxes on dark glass and it didn't read (the boxes
cover the column by design) - rendered, judged, not committed. The rig and pack under it lay themselves out
in the 296 px left: the rig a row (two for the medic's harness), the pack at full 64 px cells while they fit
(Matt: "give the pack its full 12 cells here" - up to 16), then the biggest of 48/40/32/24/16 that holds
its capacity in the room; `pack_inside()` asserted on every Lock-up fit check.
The people (same day): seven of Greenhorn's 128 × 128 portraits, Matt's picks, named here - `art/people/
poacher.png` (the old countryman in the brown hat), `doorman.png` (black beanie, stubble), `paramedic.png`
(grey crop, green scarf), `scrapper.png` (dark hair tied back), `drifter.png` (the eye patch), `fence.png`
(grey beard, brown leather), `medic.png` (white beard, blue beanie). `scripts/ui/people.gd` finds them by
slug, load-if-exists, and draws at 1× or 2×, never between. The Caravan shows the class's face at the left of
its panel with the words beside it (no class, no face, the words slide back); the Fence and the Clinic show
theirs at 1× at the foot of the side panel with the name beside - 2× was tried and sat under the fence's ammo
buttons, so `Vendor.face_clear()` is asserted every time either screen is fit-checked. The Yard's Runner card
is full; no face there.
`tests/shot.gd` renders the Lock-up to a PNG under xvfb so a layout can be looked at, not only measured;
`tests/shot_title.gd` the studio card and the title; `tests/shot_rooms.gd` the Yard, Caravan, Fence and Clinic.

The art, landing (same day): the first nine long guns are in `art/items/` (renamed from the candidates'
`<slug>_a_01.png` to `<slug>.png`) and draw at their own pixels, centred, when they fit the cell
(`STRETCH_KEEP_CENTERED`; only a bigger picture is scaled). The studio card is Greenhorn's splash exactly -
"MUNDANE STUDIOS" in Inter at 60 with 15 px of letter spacing, white on black, 0.5 s in, 1 s held, 0.5 s out
(`intro.gd`; sized from the viewport by hand, since a full-rect preset applied before the node is in the tree
leaves it at nothing). The title stands on Matt's painting (`art/title.png`, 640 × 360 drawn at 3×): the menu
panel loses its heading, shrinks to its rows and sits at the foot of the painting, and a wordmark
(`art/wordmark.png`, Matt's, generated at 280 × 120 and cropped to its 260 × 108 of lettering, drawn at the
painting's 3× directly above the panel, 24 px up; the panel's foot is 40 px off the bottom to make the room)
carries the name.

Assertions added with it (`tests/smoke.gd`): `_check_grid` on the stash every time the Lock-up is fit-checked
and on the pack on the Run screen - every footprint inside the columns, none overlapping, none across a page
edge, every drawn cell over an outline, outlines exactly the capacity or the reach; `_body_drops` - a plain
item of every slot dropped on every box (own slot taken, the other five refused), the swap returns the old
item, the selection follows, dragging off unequips, and a swap with no stash room for what comes off is
refused; the body's boxes inside the panel, non-overlapping, and the fitted cell inside its box. The 16 px
cell words go through the fit check like everything else (it caught "Visored helmet" at 132 px in a 130 px
cell on the first run; the cell falls back to the slot code).

## Narrative, item words, the language pass (2026-10-02)

Matt: "start thinking about narrative" - then "build it - also in the same register - item descriptions
for everything. Also a full language pass ... the terminology of 'lots' doesn't work - gangs or similar".
Design in `docs/design/narrative.md`; every line in `scripts/sim/words.gd` (no rules there, words only).

- **The frame**: the yard is the player, runners pass through. A death writes the runner into `sim.past`
  (class, level, runs, where); the Caravan reads it back under the class words. The class pick says what
  the runner was; a death says how the next one turns up.
- **The ending**: the bank's vault holds *the deeds* - every mortgage on the estate - dropped once on the
  first clear of the bank (two by two, £5,000). Ditch it, sell it, or bring it home: burned, sold, held;
  `sim.ending` records which and the log says it in the voice. Ditch-commons and sell-commons step round
  it. No win screen.
- **The channels**: a site line once per depth and a clear line once per site in the log (`sim.seen`),
  the same site line on the Runs card under the word; the fence and the medic speak beside their faces
  (a visit line that rotates, buy/sell/treat/shelf/town/new-runner lines; `Vendor._says`); every item
  has its line under its figures in all four pick panels (113 bases, 4 uniques' pasts); **papers** - a
  new item class, `Data.PAPER`, 14 bases a cell each, 6% of a site's finds, pennies at the fence.
- **The panels** were relaid to carry the words: title at 10, lines at 48 + 28 a row, the item's line in
  two 18 px rows at 162/182, buttons 44 tall at the foot (Lock-up, Fence, Clinic, Bench, Run). `UI.wrap`
  flows a sentence over labels a line each and leaves the overflow for the fit check to catch.
- **The language pass**: "lot" is "gang" everywhere a player reads it (stat keys unchanged); "looks" are
  "searches"; the Radio's word lines rewritten to read and still fit a card; a dozen log and panel lines
  rephrased ("Not today: back up on half HP", "The clinic is better kitted: resting heals ..."); the kinds
  bar is seven buttons (Paper added, Carry is Bags) measured to the grid's width; sort is "New" not
  "Newest" (it didn't fit).

Asserted (`tests/smoke.gd` `_narrative_checks`): the bank's site line on setting off, the deeds dropped
on the clear and 2×2, ditch-commons leaves them, burned/held/sold each set the ending and the sale pays,
a death writes the past and the Caravan shows it, four hundred searches find paper, every base and
attachment has words and every unique a past, both vendors say something on a visit; every new line goes
through the fit check (the first run caught "Paper" at 89 px in an 88 px button and the Radio's longer
word lines).

## The City, the campaign, the endgame, the bosses and the notes (2026-10-02)

Matt: "we need another zone added and then the player needs to complete all 3 zones before depths opens up
which would be the 'campaign' - at which point it actually needs to be viable to run each map"; then "we
then also need to add bosses - one per zone at this stage with a unique drop pool ... a second currency
dropped everywhere that the bosses require a certain amount of to fight in the endgame with the campaign
versions being free."

- **The City** (zone 3): the services, the hospital, the barracks - fourteen tier-6 bases (the section
  gun, the marksman rifle, issue plates, the hospital kit, belt links and so on), their words, their site
  lines, their footprints; the manifests regenerated (the long-guns pass has four more to do).
- **The campaign**: a zone opens when the one before it is *complete* - its three sites cleared and its
  boss beaten (`Sim.zone_complete`, `campaign_done`). Until all three are, the depth ladder is locked at
  1 (the card reads "Depth · Locked") and the radio's call-in is locked too; hold-a-word stays.
- **The endgame** (`Data.CURVE`, `Sim.effective`): from depth 2 on, after the campaign, every site fights
  at the depth's numbers bent by its *shape* (`TIERS[].shape`: many and thin, few and hard, gangs often or
  rarely, cash-heavy, med- or ammo- or paper-heavy) with every base in the pool, so the sites differ by
  what they drop and not how hard they are - asserted within a ×3 band at depth 2 with the words off.
  What they drop (`TIERS[].drops`): slot weights a site, a gun type it leans to half the time, and two or
  three bases found there and nowhere else (`Items.exclusive_to`; a third of a site's rolls are its own) -
  the night optic is the barracks', the hospital kit the hospital's, the sawn-off the parade's.
- **The bosses** (`Data.BOSSES`): one a zone, the crew's head, at the zone's last site - the carpet man at
  the retail park, the manager at the bank, the quartermaster at the barracks. A toggle beside Set off
  arms them; the fight is the pool, then them alone (their HP and fire a multiple of the site's; the dry
  runs behind the odds include them). Down, they drop one of their own uniques (two each, `"boss": true`,
  never from a loose roll), ten kills' worth of XP and cash, and notes by depth. The first fight is free
  and completes the zone; after that the crew's price in notes by depth (`boss_cost`).
- **Notes** (`Sim.notes`): the old paper money, which the crews still take. Every kill carries some, more
  by depth; a search turns some up; they come home on extract and show in the top bar. Nothing else
  spends them yet.

Asserted (`tests/smoke.gd` `_campaign_checks`): the Town stays shut with every Estate site cleared and the
boss standing; depth 2 refuses before the campaign; the first boss fight is free, the boss comes out when
the pool is down, goes down, marks the zone, drops their own, the run carries notes and they come home;
the Town opens; the second fight costs; after the campaign depth 2 opens everywhere and the sites sit in a
band; a boss can't be armed without the notes; every exclusive base drops at its own site in 300 rolls and
at no other; every boss, unique and exclusive has its words. The bots (smoke and reader) arm a boss when
the zone's last site is cleared and the odds hold with them in.

Reader, Doorman, 6 h (real-time capped at 4 h): the Estate's boss down by about 1:30 and the Town open (tier
3 cleared at 1:39), the bank at 3:46, no deaths, level 28 at 4:00; the city not reached in the cap. The
reader's survival column read 0% for the picked tier through 3:01–3:32 while the bot kept running it without
a death - a display or cache oddity in the reader, not the sim; noted, not chased.

## The endgame built out (2026-10-02, "do it all now and balance after")

Matt, after the playtest list: "No do it all now and balance after"; then "also a magic find mechanic ...
a 'charm' slot that carries magic find and cash stats. Also along with workbench its worth adding sockets
... 6 socketable items with gear having random amount of slots ... provide the manifest for the extra
items when you can." Everything below is in, with its checks, and the balance pass after it.

- **Trees as webs** (`Data.TREES`): a class tree is ten nodes - a spine of four to its notable, then two
  branches off it (`needs`: the node before), one to the keystone and one to a rule of its own (Night
  work, Early doors, Loud, Stand, Walking wounded, Second shift, Quiet hands, Hoarder, Hit and run, Light
  fingers, Pack cells), so a tree is a choice of which way, not a ladder. The Caravan indents a branch.
- **The second past** (`Data.ASCEND_LEVEL` 30, `Sim.cls2`, `set_second`): from level 30, a second class
  for its first tree, beside your own; the middle column swaps between the yard's and the second's.
- **Traits** (`Data.TRAITS`): a runner turns up with one (Lucky, Heavy-handed, Wary, Greedy, Tough, Light,
  Careful, Nosy); when one dies two turn up and you pick (`candidates`, the menu on the Yard); a runner
  freed on a run is promised to the yard (`promised`) and is one of the two.
- **The bosses' rules**: the six boss uniques have rules now (the van's spare fires at full damage,
  Underlay takes the first two seconds, the manager's coat halves again and takes no notes, the branch
  pistol doubles under half, the quartermaster's rifle never runs dry, Issue webbing holds two a pouch).
- **The charm and magic find** (`Data.CHARM`): one cell on the body beside the primary, eight bases
  (a lucky penny to the bank's own pen), each with `find` (magic find: rarer finds) and `cash`; affixes
  `rarity_pct` (charm, helmet), `cash_pct`, `loot_pct`. Loot find was quantity; magic find is quality,
  and `rarity_bonus()` reads it. Charms are 5% of a site's finds. "CHM" in a cell.
- **Sockets** (`Data.SOCKET_*`): a gun, a helmet or armour rolls 0/1/2 sockets (45/40/15), stored as
  `attachments["socket N"]`; six socketables in the world (lighter fluid: fire, +damage; antifreeze:
  frost, less incoming; rat poison: they drop more; a car battery: shock, first-shot; road salt: armour;
  copper wire: cash) go in any socket at any bench. The Workshop has a Guns / Sockets view: four groups
  (primary, secondary, helmet, armour), two rows each, the grid filtered to socketables.
- **The map** (`Data.ATLAS`): the endgame's own tree, a fourth button on the Runs screen after the
  campaign. A point for every new depth cleared past the first on any site; six passives with ranks
  (Picked over: a site's own things more often; Paid in notes; Two of everything: a crew's head drops
  two; Deeper pockets: searches quicker; Word travels: call-ins cost half; Quiet roads: gangs later);
  "Start the map again" refunds.
- **Contracts and the fence's mate** (`Data.CONTRACT_*`, `MATE_*`): a Contracts tab on the Fence - three
  open, each wanting so many of a slot at a rarity, paying cash, notes or (one in five, three rares) a
  loose unique; the cheapest that fit go; a handed-in one is replaced; turn one down for nothing. The
  mate sells a loose unique for notes (150 × its base's tier), a different one every five runs.
- **Run events** (1 Nov, docs/design/run_events.md; `Data.EVENT_FAMILIES`): on three runs in ten, in the lull after
  the first search: someone in need, a threat passing (dogs), a locked thing, the Scrap man - in the scene, a choice in
  the panel (the clock stopped but for a threat), standing orders for runs nobody watches. The convoy, trapped and cache
  events folded in.
- **Pinnacles and the convoy** (`Data.PINNACLE_*`, `CONVOY_*`): from depth 10 a crew's head comes at
  full strength (×2.5 HP, ×1.6 fire, twice the price) with their charm in the pool - the van keys
  (you drive: pace +25%), the manager's pen (notes come in twos), the quartermaster's ledger (a kill's
  drop is a tier up). The services at depth 12 and up: the convoy, all three heads one after another for
  all three prices, and the lorry's load at the end (every empty cell comes home as notes).
- **The bench's crafting** (`Data.CRAFT`): a Bench button on the Lock-up's panel for any non-unique
  gear, stashed or worn, opening a menu: re-roll the affixes, add an affix (a rarity up, never a
  duplicate), cut a socket (up to two), strip to plain. Notes × tier × (rarity + 1); needs a bench.
- **Moving the yard** (`Data.MOVE_*`): after the campaign, from the Town card: start again with the
  uniques (worn or stashed), the yard's own tree, the list of runners before, half the notes, and the
  move's bonus (+5% magic find and cash a move, two training points a move). Asked twice.
- Words for all of it: the charms, the socketables, the four new uniques, the fence's contract and
  mate lines, the events, the move. Manifests: `sockets` (6, their own prompts) and `charms` (8, 64×64)
  are new; `uniques` has the four new ones at the end; 157 jobs in all.

Asserted (`tests/smoke.gd`): `_charm_sockets` (the charm equips, its find and cash read, 5% of finds,
two sockets, fit/fit_socket/strip and the effects, the Sockets view through the screen), `_webs_traits`
(the fork, both branches, the second past at 30 and not before, the swap, the two who turn up, the
promised one), `_atlas_checks` (a point at depth 2 and not 1, ranks and their maxes, every effect, two
of everything, reset, the save), `_contracts_checks` (bounds, the cheapest that fit, cash, notes, a
unique, the mate, the five-run clock, the save), `_events_checks` (the odds, each event), `_pinnacle_checks`
(full strength from 10, the charm only from it, the convoy's price and order, the load, the four rules),
`_craft_checks` (each kind, the rules, the menu), `_move_checks` (what comes and what doesn't, the bonus,
the save). The fit check caught: the charm's box label at 64 px, the Caravan's node lines with the web's
longer labels, the past line under the new buttons, the swap over the head, the map's buttons, the mate's
line - all fixed by measure, as the house rule has it.

The odds: `survival()` ran 200 dry runs a tier with the glasses lookout, a second at a time, to a
3000-step guard - seconds per screen refresh with nine tiers open, and the reader crawled. Now 24/24/60
runs, two seconds a step, a 450-step guard, and the cache key quantises HP to a tenth of the bar.

## The balance pass after it (2026-10-02)

What the reader turned up, in order, and what changed:

- **The odds were wrong and slow.** `survival()` ran 200 dry runs a tier with the glasses lookout, a
  second a step, to a 3000-step guard - seconds per refresh with nine tiers open - and the dry run
  missed Bodyline, the Doorman's jacket and first-gang damage, so a Doorman who cleared the barracks
  read 0% on it. Now 24/24/60 runs, two seconds a step, a 450-step guard, HP quantised to a tenth of
  the bar in the cache key, and the crowd rules and `first_lot_pct` in the dry run; ammo stacks no
  longer count as meds in it. Checked against real fights from a saved endgame: 1.00 reads clear
  without a death at depths 1 and 2 on the estate, the town and the barracks.
- **Saves shared their items.** `to_dict()` handed back the live dictionaries and `load_dict()` kept
  the ones it was given, so an in-memory save-and-restore (the tests, moving the yard) drained the
  rig's rounds through the save. Both deep-copy now. The on-disk saves were never affected (JSON).
- **The ladder works.** From a saved end-of-campaign Doorman (level 48, 460 dmg/s), the bot climbed a
  depth a run to 8–10 on the barracks and plateaued there with the odds flipping, which is where the
  bench, the map and the pinnacle at 10 should take over. Depth 2 was then a step *down* from the
  barracks, so the curve's base rose (CURVE hp 1600 → 3200, dps 2.5 → 3.6, grow 0.15 → 0.14): the
  plateau for that kit should sit nearer 6, with 10 the thing to build for.
- **The city fell in 25 minutes** after a town that took two hours (services 2200 / hospital 2600 /
  barracks 3000 HP against the bank's 1500). At ×1.6 the city took four hours and the hospital was a
  wall; at 3000 / 3600 / 4200 the services were (the Scrapper sat on them from 2:57 to 5:43). Settled
  at 2600 / 3300 / 4200 HP, 3.2 / 3.9 / 4.8 fire - a gentler step in, steeper within - with XP and
  cash up with them. Worth a look in the playtest: the city should be the long zone, not a wall.
- **The mate was too cheap** at 150 notes × tier: the bot bought eight uniques in 1.7 hours of depth
  8. 400 × tier now. A pinnacle at depth 10 is 400–1200 notes; the convoy 2880; notes come in at about
  60 a run at depth 8 with Paid in notes ranked, so a pinnacle is a dozen runs and the convoy an
  evening.
- The bot (`tests/bot.gd`) plays the endgame now: fits socketables, hands in contracts when the items
  aren't its best, ranks the map, buys the mate with notes three times over, adds an affix at the
  bench when the notes stay above twice the dearest boss, and leaves a bandage for a box of rounds
  when the rig's full and the gun's dry.

Reads (10 h, real-time capped): Doorman before the city change, Estate 0:48, Town 2:44, City 3:32;
at ×1.6, Estate 0:48, Town 3:14, City 7:16. Poacher and Scrapper at 3000 / 3600 / 4200: Estate 0:40,
Town 4:34 and 2:57, the services at 5:38 and 5:43, cut by the clock before the rest. No deaths in any
read (the bot bails at a quarter). Cash piles up past 3:30 once the yard's upgrades are bought (£330k
by 7:00 with nothing to spend it on) - the next cash sink is still an open item.

## The late cash sinks (2026-10-02)

Matt: "so whats the late game cash sink?" - there wasn't one: every sink had a ceiling by 3:30. Two
built at his call ("do one and two"):

- **Call-ins priced by depth.** `juice_cost(i)` is `INTEL_CASH[tier] × 3 × depth × (1 + words already
  on the site)`, halved by Word travels. Flat per tier before; PoE's map crafting is the sink and now
  it is here too.
- **Insurance** (`Data.INSURE_RATE` 0.15): a toggle beside Auto-run on every Runs card, "Insure £x" -
  15% of what's worn and carried, times the depth, paid at Set off. Dies, and the kit comes back to
  the stash whatever the room (the runner doesn't); the fence's lines: "I'll hold the paper on it. If
  they don't come back, you do." Uninsured, the kit goes as before.

Asserted (`_sink_checks`): depth 4 is four times depth 1, two words on the site treble it, Word
travels halves it; the premium is the rate × depth on the kit's worth, refuses a pound short, is paid
at deploy and clears the toggle, an insured death reports nothing lost and every worn and carried item
is in the stash, an uninsured one loses it. The bot calls in a word and insures past the campaign while
it holds ten times the price.

## From the playtest (2026-10-02, evening)

- **"Nothing on the gun tells you what ammo type it takes."** `Items.ammo_words`: "Takes shells" on a
  gun's panel line in the Lock-up and the Fence, and beside the dmg/s in the Workshop's head. Checked
  for every gun base.
- **A two-cell kit went into one pouch.** The rig counted items, not cells. It counts cells now
  (`rig_used`, `rig_room`): a first aid kit takes two pouches, a surgeon's kit four, and the rig row
  draws an item across as many pouches as it takes. Asserted: a kit refuses one free pouch and takes
  two.
- **"Did the skill tree change go in? Looks the same."** It had, and the drawing hid it: a 24 px indent
  on the first node of a branch. A class tree now draws as its spine down the column to the notable,
  then the two branches side by side under it - the keystone's on the left, the rule's on the right -
  each node its name (with the cost) over its effect. The yard's tree stays a ladder. Every class's
  trees go through the fit check now, not only the three the test happened to show; "Searches 15%
  faster" became "Search 15% faster" and "Next gang 10% later" "Gangs 10% later" to fit the halves.
- The quartermaster: with the barracks up he was unbeatable for the kit that cleared it (0 of 6 real
  fights at level 38); at ×6 HP / ×2.5 fire it's 5–6 of 6 with the pool before him as the real fight.
  The odds with a boss in missed meds against him and the first-shot bonuses that hold on him the
  whole way down (he's the first of his gang); both in the dry run now, and it reads 25% on a fight
  the real thing wins five in six - honest for a coin-flip, pessimistic by a margin.
- `item_by_id` looks at what's worn before the stash, so the Bench button on a worn item hits it.
- **"A pipe shotgun takes nails?"** Ammo was keyed off the gun's *type*, and "improvised" is a build
  type (the Scrapper's), not what the thing fires. Bases carry an `ammo` override now, apart from the
  type: the pipe shotgun takes shells, the garage rifles rifle rounds, the workshop and armourer's
  carbines 9mm, the blank-firer pistol rounds; the nail gun, bolt gun, crossbow, air and flare pistols
  stay on nails and bolts. The Scrapper's notables still count them all as improvised.

## The builds pass, step 1: affixes wide and tiered, the bench in cash (2026-10-04)

The spec is concept.md's "Builds" section. This step:

- **Tiers.** Every affix's `min`..`max` is cut in five: T1 the worst fifth, T5 the best, counting up
  like the bases' tiers do (not PoE's way round, so one word means one direction everywhere). What can
  roll comes from the item's level, `ilvl` = the base's tier + the depth it dropped at (`Items.tier_cap`:
  T2 from 3, T3 from 6, T4 from 10, T5 from 15); the better the tier the rarer (8:5:3:2:1). Affixes
  carry `{stat, value, tier}`; picks are by weight and never doubled.
- **The pool**, first batch: HP a second, HP a kill, armour %, less from three or more, rate of fire,
  pouches, quicker meds, quicker searches, gangs later, notes; the old ones' spans widened. The
  elemental and resist affixes come with the damage model (step 2).
- **The bench in cash** (notes only for raising the level): re-roll everything, lock one and re-roll
  the rest (×3), re-roll one (same tier mostly; up a step one in four at T1 falling to one in sixteen
  at T4, down one in ten; the price × the tier), add, cut a socket, strip, and bump the level by three
  (to the base's tier + 20). Prices × the item's level × (rarity + 1). The menu is two pages: the
  whole-item jobs, then the affix picks.
- **The room.** One line of log, the latest (`Pal.EVENTS_H` 36, `EVENT_LINES` 1); every room is
  `Pal.ROOM_H` (916) now, the Yard's card grid keeps `GRID_H`. The Lock-up's panel spends it on six
  lines a column: the figure, what it takes, three affixes with tiers ("+8% quicker searches · T4"),
  the swap word; the fitted side the same, the chips under them.

Asserted: the cap by level, the ranges cut without overlap, a tier-1 base at depth 0 rolls T1 only
and depth 20 rolls some T5 and more T1, every bench job and its price, the lock keeps its affix, sixty
re-rolls of one move its tier, the bump and its cap, the menus and the panel's tier line fit.

## The builds pass, step 2 and 3: the damage model as layers, their side (2026-10-04)

- **Six types** (`Data.TYPES`): physical, fire, frost, poison, shock, bleed. A hit is split by
  `Sim.conversion()` (sockets and `conv_<type>_pct` affixes; physical is what's left), each share ×
  (1 + `increased(type)`) × `more(type)` (1 for now - keystones and uniques go there), cut by their
  resist to it (`damage_rate`); shocked, +15% of everything. The socketables are conversions now
  (15% as fire/frost/poison/shock; salt and wire as they were).
- **Dots** (`Data.DOTS`): fire burns half the hit over four seconds, poison 80% over eight and stacks to
  five, bleed 60% over six; a pool a type on the target, drained a share a second, reset on a kill.
  Frost chills (their fire −20% for a second), shock shocks. The same on you from their elemental
  share; a dressing stops the bleeding; nothing ticks on you in the picking over. The run panel's
  "On you: burning, bleeding".
- **Armour stops physical only**; the elements only resists stop (`resist(type)`: affixes, all
  resists, capped at 75%). `incoming_rate` does both; the dry run runs on the same two rates, with
  the dots as the share they add.
- **Their side** (`Data.ZONE_TYPES`): the estate's fire is 15% bleed, the town's fire and poison,
  the city's shock and fire, each share growing 2% a depth to 60%; resists by zone (the town's
  jackets against bleed, the city's kit against most things) plus 1.5% to everything a depth from
  depth 8, capped at 70%. Seven new words: Burners, Cutters, Wired (a third of their fire a type),
  Jacketed, Rubbered, Hardened (a resist), Resistant (all, from depth 8).
- **Affixes**: increased a type (six), a share as a type (five, half weight), a resist a type (five),
  all resists (rare), burn/poison/bleed damage.

Asserted (`_damage_model_checks`): a plain gun is all physical; the fluid makes 15% fire and the fire
affix raises that share alone; their resist halves it; shocked takes more; over-conversion shares out;
resists add and cap; incoming is physical through armour and fire through the resist, chilled slower;
the estate's types, the words, Resistant plus depth; the dot pools and ticks and the poison cap; a
cutters' gang bleeds you and a dressing stops it.

## The builds pass, step 4: the element trees (2026-10-04)

- Five trees (`Data.ELEMENT_TREES`): Petrol, The cold, The rat man, Live, Blades - a web each: a spine
  of conversion and increased to a notable (Lit, Chill, Dosed, Live, Opened up: +30% and the element's
  twist - dots last twice, chill 40%, shock 30%), a branch to the keystone (Spreads: fire hits
  everyone on you; Frozen solid: chilled gangs barely fire (85% off), frost does half; Builds: poison to fifteen
  stacks; Live wire: shock on the first of a gang hits every one; Won't stop: bleeds don't fade), a
  branch to a notable with a cost (×1.4 more of the element; you burn for 2% / pace −15% / loot find
  −20% / armour −20% / meds 30% slower). A committed tree plus a socket plus the class's notable is
  about 100% conversion.
- **Affinities** (`Data.AFFINITY`): Drifter fire/shock, Doorman bleed/physical, Poacher poison/frost,
  Scrapper shock/fire, Paramedic poison/frost. Off the pair a node costs double and the keystone
  refuses until the second past brings the affinity.
- **The class webs' spare branches** carry an element notable now, in place of a small node: Rat
  bait, Cold snap, Glassing, Knuckles, Syringe, Ice pack, Live wire, Blowtorch, Petrol bomb, Jump
  start - 15% as the type.
- **The Caravan**: the middle column cycles the yard's tree, the second past's and the five elements'
  ("Next: Petrol ▸"); an element's head says its type and "double" off affinity; costs come through
  the sim so the double shows.

Asserted (`_element_checks`): the affinities and the double; Petrol to its keystone and its 45%; Lit's
double burn; the costly branch's ×1.4; the rat man's keystone refused to a Drifter and opened by a
Poacher past; Spreads multiplies fire by those on you in a real fight; Frozen solid's chill and half;
Builds' fifteen; Won't stop's bleed that doesn't fade; Glassing's 15%; the Caravan through every
middle tree.

## The builds pass, step 5: melee (2026-10-04)

Seven primaries (spiked bat, machete, pipe wrench, fire axe, bayonet on a stick, sledgehammer, breaker
bar) and three secondaries (knife, knuckle duster, cosh), type "melee", ammo "none" ("Takes nothing":
`has_rounds` is always true, nothing is spent), a share of the hit bleed from the base (5–40%), grip
and head mounts of their own (tape, cord wrap, lanyard; nails through it, a blade on it, lead in it),
grips at bench 1 and heads at bench 2. In among them: their fire on you ×1.25 with a melee primary,
and each gang's first second lands before your first swing (`MELEE_WAIT`). The Doorman's "Knuckles"
became "Through the lot": with a bat or a blade, a swing hits everyone on you. The Workshop's five rows
a gun now show the gun's own mounts in the bench's order rather than the five gun mounts, so a bat
reads "Grip, Head, —, —, —". Words for all sixteen; three manifests more (melee 7, melee_small 3,
melee_parts 6): 176 jobs in all.

Asserted (`_melee_checks`): the bat's mounts and words, never dry, 20% bleed and 35% with nails, the
×1.25, no swing in the first half second and a swing after, the Workshop's rows and a fit to the grip,
Through the lot with a bat and not with a gun.

## The builds pass, step 6: twenty-one more uniques, each a rule (2026-10-04)

Matt: "may as well go big ... nothing too formulaic though, needs to be inventive and fun." Gated by
depth on the loose pool (`"depth"`: 12 or 25; the first four stay ungated), the mate's stock opening as
the yard goes deeper (`loose_uniques(deepest())`), the fence's contracts paying only with the ungated
ones. A paper with a rule counts from the stash. The rules, in the sim:

the council's weed burner (all fire, hits everyone on you, takes nothing), jump leads (a third shock,
the first of a gang is every one), the rat man's bag (poison never caps, carries to the next), the
butcher's steel (bleed ×2, carries), the gritter's hopper (everyone chilled always, chilled gangs one
at a time), the sparky's gloves (their shock resist is nothing, Earthed costs no armour), the
quartermaster's manual (every element yours), a blue plaque (all resists +40, nothing else on you
counts), the lollipop lady's sign (the first drops where it stands, gangs half as often), the
bookie's pencil (magic find ×2, cash ×½), the float (pace +40%, pack ×1.5, no meds), nan's cardigan
(3% HP a second, no armour), the dinner lady's ladle (a tenth back a kill, meds do nothing), a
traffic warden's hat (gangs one short, notes ×2), the vicar's thermos (burns on you heal, no fire
resist), the scout leader's whistle (every gang after the first is one), the sergeant's whistle (two
more on you, everything ×1.6), the electrician's tester (shocked stays shocked, shock ×½), the
gamekeeper's flask (their poison poisons them back), the caretaker's keys (an event every run, every
cache opens), the lorry driver's log (notes ×2, insurance free). Words for all.

The bot sells meds past a dozen cells' worth (they piled to 90 cells once kits took pouches, which
filled the stash and broke the drop tests); stacking will do this properly for the player.

Asserted (`_unique_rules_checks`): every unique rolls and has words; the gates; the mate; each rule.

## What a thing is (2026-10-05)

Matt, at a bag of road salt: "how am I supposed to know what this does? what type of item is it?
what is salt?" Every card leads with its kind now (`Items.kind_words`): "Primary · rifle",
"Secondary · melee", "Helmet", "Rounds · shotgun", "Gun part · optic", "Socketable", "Med",
"Paper", "Charm" - first on the figures line in the Lock-up, the fence, the run's pick and the
bench. A socketable's figures say what it does rather than name the stat ("+12 armour", not
"+12 salt"; "15% of hits as fire"), and its right column says where it goes and what for: "A
socketable: packed into any socket, +12 armour" / "in any socket, 15% of your hits land as
fire" / "+12% cash from every kill", under "Fitted at the bench, Sockets view".

Asserted: thirteen kinds read right; a card line leads with its kind at every width; salt and
fluid's figures; the Lock-up and the fence say a socketable is one; both fit.

## The green among the red (2026-10-05)

Matt: "even if I saw a green +1 on the bar amongst the −1s I would know as a player regen is
working." Your bar's numbers were the net change in HP, so regen under fire never showed. The sim
counts what you took (`m["taken"]`, their fire) and what came back (`m["healed"]`: regen, the
cardigan, a med, life on a kill, the ladle, the thermos) apart, and the run screen shows both
every half second - "−6" in red and "+1" in green, side by side on your bar. Regen on gear
still counts only out on a run, as Matt wants; the yard's rest is the Clinic's.

Asserted: a second that took 20 and gave 3 shows a red twenty-odd and a green +3; five seconds of
+2 regen count nine or more healed; their fire counts as taken.

## Numbers that read, and the boss toast (2026-10-05)

Matt: "all in the same place fading up doesn't read as anything". A damage number comes off
their bar at most every third of a second (the hits since the last one added up), scattered along
the bar at a different height each time, drifting a little sideways as it rises, bigger from a
hundred. Your own bar has them too: red "−12" for what you took, green "+25" for what came back
(a med, regen, life on a kill), the same cadence. Positions are taken from the panels' global
place, so they sit on the bars wherever the room is.

The boss toast: a repeat is checked against the whole line now (it was checked against the
fitted short form, "The carpet man", which never matched the line, so the check never held), and
the Runs card's toggle is under test: one press, one toast, through four refreshes; off and on
again while the first shows, still one.

Asserted: eight refreshes of a long fight give four to eighteen numbers in three or more places;
−20 on a hit taken and +20 on a heal, both on your bar; the toggle's single toast.

## The Runs screen's lag (2026-10-05)

Matt: "a few seconds between clicking the menu and the menu appearing", only on Runs. Cause: the
odds are the real fight run dry now, and the Runs screen asked for nine tiers' worth at once -
up to 9 × 24 fights of 450 ticks - whenever the cache missed (a tenth of the HP bar, a word, the
weather). The shell gives the sim a budget (`odds_budget`, 3 dry runs a tier a refresh): the
screen comes up at once with the odds dimmed and "reading the odds" under them, keeps refreshing
while any open tier is unsettled, and settles in about a second. The bots and the tests leave
the budget at 0 and get the whole answer in one call, as before. The cache key carries the
weather and the clock's night too, since they change the fight.

Asserted: with a budget of three a refresh does not settle every tier at once; forty refreshes
settle them all; the screen fits settling and settled; without a budget the odds read at once.

## The shelf's box price (5 Oct)

*The fence sold 300 pistol rounds for £79 on the shelf while the box row sold the same 300 for £40.* The
shelf priced ammo like gear (value × 3); the box row prices it at value × 1.5. `price()` now charges a
standard box on the shelf exactly what the box row does; special rounds (the ones with `damage_pct`) and
anything with affixes keep the gear markup. Asserted for every box type, and that a special box is dearer.

## Fill up, then go (5 Oct)

Matt, with gangs delayed three minutes by the tree: the fight won, the search ticking, nothing to do
but watch the clock or leave the finds on the table. Once the fight's won a manual run gets a second
button, "Fill up, then go": the run searches on and leaves by itself when the pack's full or the next
gang comes - the auto-run's rule, for one run, without the redeploy (`set_leave_full`,
`mission["leave_full"]`). The button reads "Filling up ✓" while set and the note says what will end it;
pressing again cancels. Asserted: the button appears at the clear, sets the flag, a gang's arrival ends
the run alive, a full pack ends it.

Also: the Fence's rail badge is "Ready" whatever the count (two ready overlapped the name); "what's next"
gives the campaign's line before a ready contract.

## Parked for after the playtest: crafting, grenades, the pack grid (5 Oct)

Shaped in the chat, written into `docs/design/concept.md` as items 23, 25 and 26, nothing built: the
pack as a real grid; crafting at the bench from one material (scrap: found, or stripped from any item)
- standard rounds, the better grades from a standard box of the type, meds up the grades, improvised guns
of a chosen type that fire nails and key Bodger; grenades as rig items thrown like a med, one an element,
through the damage model, built from scrap and the element's socketable.

## The contracts, where you'd see them (5 Oct)

Matt played seven hours without opening the fence's Contracts tab. Now: the Fence's rail button says
"3 contracts" on its second line and carries a badge - "Unique" while a contract pays with one, "Ready" /
"2 ready" (green) when one can be handed in; the tab reads "Contracts ★" or "Contracts ✓1" and lights
green when one's ready; and "what's next" (the Runner card's note, the log) says "The fence has a contract
you can fill. Contracts, on his screen: hand it in" ahead of the site line. Asserted: the badge, the
status, the tab and the next words for a unique contract and a ready one.

Matt's save at 7.3 h (`tests/matt.save` in the scratch project): 100 runs, 7 runners lost, two zones'
heads down, the quartermaster not; £30,905 and 226 notes with the market at level 0; the last scrapper
died in the barracks in 29 s with £13,765 of kit on (hardened, wired), now in the loose kit; a fresh
level-1 runner with a nail gun reads Safe on the streets and A bad idea everywhere else. The clip probe
over it: nothing clipped.

## The odds in words (5 Oct)

The site cards' big figure was "72%". It's the yard's word now (`Words.ODDS`, `odds_words`): Safe (90%
up), Likely (75), Risky (60), A coin toss (40), Long odds (20), A bad idea; the figure sits small beside
it ("72% to clear"), and the Radio's cards read the same ("Likely" / "72%, D1"). The edge's tone is as
it was. Asserted: the headline is a band and the figure beside it; every band and the widest figure
share the row.

## The elements' trees go with the runner too (5 Oct)

Matt: the Caravan kept Petrol, The cold, the rat's tree and the rest through a death, so getting out of a
fire build on a new runner cost tens of thousands at the respec. The elements' trees are the runner's
now: a death refunds them with the class's, and only the yard's tree stays. The Caravan's scope line says
"The runner's" on an element node. Asserted: a trained element node is gone after a KIA, the yard's stays.

## The trait as a stat (5 Oct)

Matt asked where the stat he picks on a death adds up. It doesn't: the pick is the new runner's trait,
one each, gone with them. So it now reads as a stat where the runner is: a chip on the Yard's Runner card
("Tough: +15% max HP", green, beside the class chip; the rig's pouches fold into the pack line to make
the room) and a line on the Caravan's panel with nothing picked ("Tough: +15% max HP · the runner's
trait, one each, goes with them"). Asserted both.

## What's on the gun (5 Oct)

Matt's SMG with four parts and a socketable read as a bare gun. The head's tail is its own line under
the headline now, the whole column wide, and for a gun it leads with what's fitted (`Items.fitted_words`:
"Holo sight, Bipod, Drum magazine, Wire stock + lighter fluid", then "4 parts + 1 socketable", then
"5 fitted" as the room shrinks; "nothing fitted" when bare), then the rounds ("takes SMG rounds, 600 in
the rig", "600 SMG rounds", "takes SMG rounds"). The fit keeps the first clause long while the rest
shorten or go. The Lock-up's right column, when the pick is the fitted gun, lists each part with its
figures ("Red dot · +10% first", "Lighter fluid · 15% of your hits land as fire") above the stash's room.
Every panel runs the compact head; the flavour is one row under it, shortening by sentence, then clause,
then words (`UI.fit_sentences`). Asserted: a kitted gun's tail names a part, its column lists the parts
and the socketable, `fitted_words` in its three forms.

## The Yard as option A; the Runs cards' elements; the Radio's cards (5 Oct)

The card widget grew two things the new screens needed: a row of **chips** ([words, tone], in the first
line's place after the bar; those past the row are left off) and a **tone on a line's value** (the
element's colour on a resist). With them:

- **The Yard**, eight cards: Runner (level, class, XP; damage, armour, pace, pack, rig), **Elements** (the
  share of your damage dealt as elements as the headline; chips for what the open sites fire; a line an
  element, "deal 8% · res 30%" in the element's colour), **Finds** (loot quality the headline; quantity,
  cash, notes, search, gangs), The town, Cash (notes, kit worth, stash, prices), **The yard's works** (the
  generator, lookout and kennel on one card; one button for the cheapest next job, the note names the
  rest), Last run, **The log** (the last five lines, shortened to the card). Generator, Lookout, Kennel and
  Played as cards are gone.
- **Runs**: each site's column has a chip row under its figures - an element they fire, in its colour, with
  the share and your resist ("Fire 15% · you resist 30%", shorter when the row's full; "Physical only ·
  armour takes 56%" when they fire nothing else) - and "They resist fire 20%, shock 20%" takes the rewards
  row where a site resists anything (the site's wear still comes first). The intel rows tightened to make
  the room.
- **Radio**: a site's card leads with the odds to clear it with the words on, the words as chips (amber
  when a word makes the fight harder, green when easier or richer), each word's figures on a line under.

Asserted (`_yard_checks`): the eight cards; the fire line's words and colour; a torch's 20% reads as the
deal share and the headline; the Finds card's lead; the town's card chips fire and resist; the radio's
odds headline and chips; every fit check on the three screens.

## The item panel, option B (5 Oct)

Matt picked B from the mockups: the item's head is one control now (`scripts/ui/item_head.gd`), mounted
in the left column of the Lock-up's panel, the fence's and the clinic's, and the run's pick panel:

- the name; a row of chips for what it is - slot, type (or "Gun part · Handguard", "Melee part", "Rounds",
  "Med", "Paper"), "Rifles only" on a typed part, the rarity in its tone, the level, the cells when more than
  one - chips that don't fit the row are left off from the right;
- the headline figure big (a gun's dmg/s, armour, a med's HP, a box's rounds, a part's own first stat) with
  its unit and a tail after it ("takes SMG rounds · 600 in the rig · 3 mounts"; "heals 42 for you, over 6 s";
  "from before" on a paper), the tail dropping clauses from the end until it fits;
- the affix rows: a tier tag (T1..T5, in the tier's colour) and the affix's words in the same colour, then
  an "open" row ("One more can be added at the bench") while the rarity's below Elite, or a set's line.
  The Lock-up's 252 px panel runs the compact form (three rows, a smaller figure); the open row gives way
  to the set's words there.

The right columns stay what they were (the compare with its deltas and verdict, the rig's room, the shelf's
notes), the fence's price lines are gone since the buttons carry the price (the hint says "No room in your
stash" or "Short by £n"), the run's pick shows "The fence pays £n" and what's fitted on the right, and the
Lock-up's swap verdict takes the flavour's first row, the flavour shortening by sentence to one. Asserted:
the head on every panel's pick, the bipod's head (figure +18%, "−6% pace" in the tail, its affix on a
banded row, chips Gun part / Handguard / Rifles only / Uncommon), the shotgun's tail, the council's set
line, a paper's "from before", and every fit check.

## Loot quality and loot quantity (5 Oct)

Three names for two stats: "magic find" (the affix), "rarer finds" (the tree, the traits, the site words)
and `rarity` were one thing - the chance a find rolls a higher rarity; "loot find" was the other - how
much comes out of a search. Now **loot quality** and **loot quantity**, everywhere the player reads them
(affix labels, the charm's headline, the tree's rows and panel, the traits, the lanyard, the modifiers'
words - "rarer loot" where a card line is short). The stat keys are unchanged.

Not shown anywhere yet: the resists and the two loot figures. The Yard's cards are the place; two mockups
are on the item-panel canvas (option A: Resists and Finds cards, the three works merged, a log card;
option B: the runner's sheet two cards tall with resists as pills). Nothing built yet.

## The Caravan's panel, the notables' words, a part's affixes (5 Oct)

- *"Cash +10%, for every runner the yard sends"* read as a bonus per runner sent. It never was: the tail
  meant the yard's tree holds for every runner. The panel now gives a plain node its fuller words
  (`PANEL_WORDS`: "+10% cash on every run's take", "Your first shot on every gang does 20% more", ...)
  and a third line says whose the node is: "The yard's: trained once, kept through every runner" or
  "The runner's: goes with them when they go; a new past starts it over".
- The "N points free of M earned · one a level · changing class refunds its two trees" line is gone
  from the panel; "3 of 29 points free" sits top right of it instead.
- A language pass on the notables: "Hit and run" is "Leaves as the first gang arrives, the loot kept;
  every kill pays 50% more"; "Stand and fight", "Not today", "Rifleman", "One shot", "Loud",
  "Chokepoints", "One at a time", "Bodyline", "Never there", "All or nothing", "Trapline", "Frozen
  solid", "On your hands", "Walk it off", "Quiet hands" and the lanyard's words all say what they do in
  a sentence. Asserted: the points line, both scopes, no "the yard sends", the old phrasings gone.
- A part's panel: its kind line has shorter forms (the bipod's "Gun part · handguard · Uncommon T2 · 1
  cell" trailed off), its own figures sit on their line (`att_words(it, short, base_only)`), and its
  rolled affixes get a line each in their tier's colour like a gun's. Asserted on a bipod with a T2 affix.
- The Craft panel's hint stops at its buttons and shortens, like the Lock-up's; the Workshop's other
  views get the full width back each refresh.

## The pouches are the controls; rounds top up a full rig (5 Oct)

The Runner panel's "Use" button is gone: a med's pouch on the run screen is the control, lit when HP is
under 35% and nothing's in use, and the note says "press a pouch to use one". Asserted: no button, a
pressed pouch uses its med.

Dragging rounds onto a full rig in the Lock-up was refused (`_can_drop` wanted a pouch free) though the
take itself would have topped up the rig's stack of the same rounds - so stacking only worked rig to
stash. `sim.rig_tops_up(it)` says whether any rig stack of the same rounds has room, and the drop, the
run's Take and the Lock-up's take all allow it. Asserted: a full rig takes a drop of nails and its own
stack grows by them, no new pouch.

## The bench says what it did; the run screen's rig (5 Oct)

- **The bench's words.** Every job at the bench now says what it did, in words the player can check against
  the piece (`sim.last_craft`, `_craft_words`): "Added +12% damage · T2", "Re-rolled: a, b → c, d", "Kept
  x; re-rolled the rest: ...", "+4% damage · T1 → +12% damage · T3", "A socket cut: 2 now", "Stripped: ...
  gone", "Level 4 → 6: up to T3 can roll". The words toast as the menu closes, stay on the Craft panel's
  hint line (green) while that piece is picked, and the log line carries them. Asserted for add, re-roll,
  bump and one.
- **The run screen.** The run's panel (the clock, cash, Get out) is 20 px shorter, its top level with the
  pack's; the Runner panel takes the room and shows the rig's pouches in it - a cell a pouch, empties as
  outlines, a med's cell uses that med (eight at 64 px, smaller past eight). A med or rounds found out
  there can go in the rig during the run: `sim.take_from_pack(id)` (the Lock-up's `take` and it share
  `_take_from`; rounds top up the rig's stack first), a "Take into the rig" button on the pick panel
  beside Ditch, "The rig is full" / "No rig fitted" when it can't. Asserted: the tops level, the Runner
  panel clear of the run's, the pouches shown and inside the panel and off the button, a found med
  offered and taken, rounds topping up.

## Damage numbers by type (5 Oct)

The numbers off a hit come one a type, in the type's colour: physical white, fire orange-red, frost ice,
poison green, shock yellow, bleed crimson (`Pal.ELEMENT_COLOURS`; `tone_color` knows the type names). On
their bar and on yours: a gang that fires half poison puts a white and a green number on you, a torch
that converts half to fire puts a white and a red one on them; what came back stays the green "+". The
sim keeps `dealt_by` and `taken_by` per mission (the direct hits by type, the dots by their own type via
`_dot_tick`'s `by`, the fire on you the thermos drinks left out), beside `dealt` and `taken`; whole points
show, the rest carries to the next. Asserted: fire and physical colours on them, poison on you, and
`dealt_by` adds up to `dealt`.

## Affix tiers as colour bands; charms roll again (5 Oct)

- **Bands.** Wherever an item's affixes are one a line - the Lock-up's panel (the pick and the fitted
  piece), the Bench's craft panel, the bench's pick menu - the whole line is in its tier's colour:
  T1 white, T2 green, T3 blue, T4 violet, T5 gold (`Pal.TIER_COLOURS`, `Pal.tier_color`; the first cut
  had T1 grey and T2 white, which read as no colour at all on a T1/T2 piece). The fence's and the run's panels put the affixes on one line and stay
  one colour. A menu item takes a `color` for its name. Asserted on the Lock-up for a three-affix item.
- **Charms.** Matt had only ever seen magic find on a charm, and the bench would only bump one. Both were
  real: the stacks build (e2a7dea) had lumped the charm in with the boxes and bottles and rolled every
  charm plain, common and bare - a regression - and the bench had refused "Add an affix" on charms since the
  base build. Charms roll rarities and affixes from their own list again (HP a second, gangs later,
  notes, the five elements' damage and resists, all resists, dots, magic find, cash, loot find), and the
  bench adds to them like any other piece. Asserted: 200 rolls at level 3 give rarities above common and
  six or more stats; the bench prices and performs an add on a charm; no socket on a charm still.

## The secondary spends what it fires (5 Oct)

Matt: a pistol with 600 rounds in the rig, run after run, and the count never moved. The secondary gave
a third of its damage while the primary was live and spent nothing for it; it only spent rounds when it
was the gun in hand (the primary dry or gone, or Double tap). Now it spends at the share it fires: a
third of its rate backing a live primary, the full rate in hand (Double tap and the van's spare count as
in hand, as they do for the damage). Asserted: a pistol backing a nail gun spends rounds over thirty
seconds, and more than twice as many when the nail gun is dry.

## A death takes the runner's past with them (5 Oct)

Matt's call after a death: the Caravan looked exactly as before - same class, same points taken - which
jarred. Now a KIA (not hardcore, which ends the yard) refunds the dead runner's own trees - the class's
two and the second past's - as points, and unpicks the class and the second past, so the next runner's
past is picked from the start and the points spent fresh. The yard's tree and the elements' are the
yard's and stay taken. The log says so ("The last runner's training went with them: N points back to
spend, and a past to pick for the next"), and "what's next" says to pick a past. Asserted: after a KIA
the class is empty, the class's nodes are gone, the yard's node stays, the points are free, the log line.

The smoke's ammo check then flaked: with no tree the runner could die in its twenty seconds; it fights
a gang that fires nothing now. The fence's special rounds (on the shelf since the box change) needed a
shorter form of their line: "Rounds · 120 rounds, +15%".

## dmg/s on the top bar (5 Oct)

The runner's damage a second, between HP and XP, from `sim.dps()` (so a dry gun reads as it fights: 0 from
that gun). Asserted on every fit check: present, ends in "dmg/s", and sits between HP and XP.

## Business ends, and what the bench's upgrade buys (5 Oct)

The melee mount "head" is "business end" now (data, the bench's rows, the parts: "Nails through it",
"A blade on it", "Lead in it" go on a bat's business end; the mount column is 190 px to hold the word).
The bench panel's title carries what the level fits ("Bench level 1 · optics, muzzles, grips") and the
line under it what the next level adds ("Next: magazines and business ends"), so the upgrade's price
buys something readable; the top level keeps its own words and no button. Asserted at every level.

## "head" (5 Oct)

*"Lead in it - head, Common T3, £160 - No gun with a head mount."* A bat's parts (grip, head) read like a
gun's. `Items.is_melee_mount`, `mount_words` ("a bat's head" / "a gun's optic") and `mount_name` ("Head")
carry the wording: the kind reads "Melee part · head" (kind_words, and now leading the Bench's panel line
in place of the bare mount), the Lock-up and the Fence say "Goes on a bat's head", and the Bench says
"No bat or blade with a head mount". Mount names are capitalised where they lead a line ("Primary ·
Head: empty"). Asserted: the kinds for a head and a grip part; the Bench's panel for a bat part leads
with its kind and never calls a bat a gun.

## Three more from the playtest, 5 Oct

- *The shelf stocks a standard box.* It no longer does: `restock()` rerolls a plain box (the box row has
  those without end) and the shelf's rounds are the special grades; at gear tier 1, where there are none,
  the slot rolls gear instead. Asserted over forty restocks.
- *The clinic with nothing picked showed "Leave smg rounds".* The empty panel's button acted on the last
  thing in the rig, which the player hadn't picked. The panel keeps the rig's summary and says leaving is
  done in the Lock-up (where the rig is a grid and each pouch has its own Leave); the button is gone.
  Asserted: the empty panel shows no button.
- *The Bench's upgrade button clipped the words above it.* The bench panel was 120 px: the words' line ran
  to 66 and the button started at 64. The panel is 136 now. The fit check gained a sibling rule: no button
  may sit on a label's text in the same panel (same parent only: headless, panels placed by the shell's
  layout can still be at their birth positions, so rects across panels don't compare).
- Found by the sweep on the way: the bench-one menu's title (an affix line, "+2 loot find a med carried ·
  T1") ran past the panel. `Menu.open` takes a title as a list of forms, long to short, and fits the first.

## Clipping, 5 Oct (the away menu, and a sweep)

*"Back, then." trailed off* ("Gone 3 m. The runner slept, the radio played to nobody. The f..."). The
menu's line under the heading was one 40 px label, and the fit check never looked at the menu. Now:

- The menu's sub wraps over up to four lines (`UI.wrap`; the away report at its longest - every clause,
  long numbers - takes three), and the rows move down to make room. A row's detail wraps over two lines,
  the row growing 28 px for the second, so the trade menu's "Won't stop for every class, for good: ...",
  the move menu's "Start again. The uniques, ...", and the second past's class lines no longer trail off.
  The panel grows past 760 px when it must; the title screen's panel is still only as tall as its rows.
- `_check_fit` now judges the menu whenever one is open (every label, each row inside the panel, the panel
  on the screen) and the toasts, and then **sweeps every Label and Button showing anywhere under the shell**
  for width, whether or not its screen lists it in `text_nodes()`. The sweep is width only (a menu over a
  room sits on the room's words by design). Found by it in the test's states: the three menus above.
- `tests/clip_probe.gd -- <save>` tours a player's save through every room, slot, cell, shelf, bench mount,
  menu and twenty seconds of a run with the same sweep. On Matt's save it found the Bench's
  "secondary · magazine: empty" (7 px over; it fits now with a shorter form) and **a crash: a paper picked
  on the Fence's stash tab** (`it["mount"]` on a paper) - the same hole as the Lock-up's, closed the same
  way (the drawer panel), and anything else with no slot, mount or kind shows no right panel rather than
  dying. The part's "mount, rarity T, value" line on the Bench drops the value when inflation makes it long.

Asserted: the away report in both forms fits and a two-line one moves the row down; the worst report keeps
every word and takes at most four lines; every menu the smoke opens fits; a paper at the fence's stash tab
shows the drawer and fits; every label and button on every screen the smoke shows fits its box.

## From the playtest, 5 Oct (Matt's six)

1. *HP read 94 of 93.* The bar ceilinged your HP and floored the max. `hp_shown()` / `max_hp_shown()`
   round the same way and never read past the max; `advance` clamps HP when the max drops (kit off).
2. *"Depth · Locked" sat in the middle.* The figure is centred between its − and + when the ladder's
   open; locked, the buttons go and it is right-justified across the row.
3. *The boss toggle's toast came three times.* Each arming logs its line (toggling on, off, on is
   three), and a toast could repeat a line still showing; a toast now shows only once while it's up,
   and only for a line logged in the last five seconds, so a load or a settle never brings old ones.
4. *The "Level 3: 1 training point" toast came back after the point was spent.* The same cause - old
   lines re-toasted after a batch; fixed by (3), and `events_total` is saved so a load counts right.
5. *Some log lines trailed off with an ellipsis.* The one-line log shortens by sentence now - the
   whole line, then fewer sentences, then the first clause - and the fit check holds it to the box.
6. *A paper picked in the Lock-up froze the game* (`sim.equipped["Paper"]`: a paper has no slot on the
   body). Papers have their own panel: "From before", read and in the drawer or not, Sell.

Asserted (`_playtest_checks`): full HP reads equal, a fraction under never past; HP clamps when
the kit comes off; Locked is right-justified to the row's edge and fits; the same line toasts once;
a line a minute old does not toast; a long line shortens by sentence, fits and ends with a stop;
the sentence forms; a paper's panel, fit, and sale.

## Sound (2026-10-05)

`scripts/ui/sound.gd` on the shell, following the sim at every refresh: the zone's ambient
while the runner's out (`ambient_estate` wind, `ambient_town` hum and a drip, `ambient_city` roar),
rain over it when the site's raining, the gun's tick at the gun's rate while the fight's on (a
clack for the nail gun, a thump for shotguns, a crack for rifles, a rattle for SMGs, a snap for
pistols, a thud for a bat; a garage rifle sounds like a rifle), a two-note sting when a gang
arrives, the boss's door when the head comes out, a short note when a rare lands in the pack.
Nothing in the yard. The pause menu has "Sound: on/off", kept in `user://fiat_settings.save`.
The files are `art/sound/<name>.wav`, read by hand (no import step); `tools/make_sounds.py`
synthesised the thirteen placeholders (2.5 MB; wind is filtered noise, the drip a sine - they
are stand-ins, and any real recording of the same name replaces one). A missing file plays
nothing.

Asserted (`_sound_checks`): every file reads; the estate's ambient and the rain out on a wet
estate; the gun ticks; the sting on a gang; nothing in the yard; off stays off; the pause menu's
toggle, and the menu fits.

## Juice (2026-10-05)

`scripts/ui/juice.gd`, an overlay the shell owns: damage numbers float off the run screen's Them
panel as the hits land (what landed since the last look, amber, rising and fading over 0.8 s); a
rare, a unique or a set piece flashes its cell when it comes into the pack; and the log's best
lines come up as toasts under the top bar for three seconds, three deep - a find ("Found: Lucky
cap", green), a head coming out (amber) or going down (green), a level, "Not today", the yard
moving, the trade, what came off him, a death (red). `Words.toast_tone` says which lines and
what colour; the rest stay in the log. The sim counts what's dealt (`m["dealt"]`) and every line
ever logged (`events_total`, the log keeps twenty) for it.

Asserted (`_juice_checks`): a find toasts and training doesn't; the tones; the stack caps at
three; toasts fit; numbers come off the hits; a rare flashes.

## The collection: the shelf (2026-10-05)

The last of the collection: uniques found go on `sim.shelf` by name, in the order found (the
pack, the heads' drops, the convoy's load, the mate, a piece that came off a gang member), and
the Caravan's middle column cycles to "The shelf · 7 of 35 found", four a page with each unique's
three lines under its name. The drawer and the shelf share the page machinery (`_pages_branch`):
rows sized to their lines, as many to a page as a tree's column takes (five papers, four
uniques), a click turning the page. So the collection is the Caravan: the past on its wall, the
papers in its drawer, the uniques on its shelf. Saved; comes with a move.

Asserted (in `_book_checks`): the shelf holds the uniques once, in order; the column, its head and
rows; the fit with three lines of words.

## Idle quality of life (2026-10-05)

Two toggles on the Lock-up, where the buttons sit when nothing's selected: "Equip if better" (the
best of each slot by score goes on when a run comes home; "Put on: Riot suit, Army helmet.") and
"Sell the junk on return" (common gear to the fence on the way in - never rounds, meds, bottles,
papers, uniques or set pieces; "The fence took the junk: 6 things, £84."). `sim.auto_equip`,
`sim.auto_sell`, `sell_junk()`, `_idle_tidy()` on every extract; saved. The old "Sell commons"
button is untouched (it sells everything common, on purpose, by hand).

Asserted (`_idle_checks`): the toggles show and fit, on and off; a run home sells the junk and
keeps the rounds, med and bottle; the better armour goes on; the lines; the save.

## The first ten minutes: what's next (2026-10-05)

No objective line, no tutorial: the yard says what's next, in its voice, on the Runner card's note
("Pick a past in the caravan" / "The streets are outside" / "Next: The parade" / "Arm the carpet
man on Runs" / "Depth is the game now") and the log carries the long form once, when it changes
("The runner's in the caravan. Ask what they were, before." / "Ransacked streets is outside. Go
and see what's left." / "The parade hasn't been cleared. That's where the next lot are." / "The
carpet man is behind the retail park. Arm him on Runs when the odds hold." / "The town's yours.
Depth is the game now; the yard can move when you've had enough." / after a move, "A new yard, the
same list on the wall. Start at the streets."). `sim.next_words(short)`, `Words.NEXT` and
`NEXT_SHORT`; said at the yard's set, a class pick, every extract, the move.

Asserted (`_next_checks`): the past, the first run, the next site, the head, the next lot, the
log carrying the change once, the campaign done, the move's line, the Yard fitting.

## Stacks (2026-10-05)

Matt: "a lot of different stacks of nails felt wrong". Rounds of a base merge into one stack in the
stash, the pack and the rig, up to five boxes' worth (`STACK_BOXES`; 1,000 nails, 750 shells);
socketables are plain now (a bottle is a bottle: no affixes, common) and merge by count to ten
(`SOCKET_STACK`), the cell showing "×3". `sim.stash_put` does the merging for everything that
comes home, is bought, is left from the rig or stripped from a socket; a stack's value follows
what it holds. A take tops up the rig's stack of the same rounds first and the rest takes a
pouch or stays. Fitting takes one bottle off the stack; a strip puts it back on. A full stack
starts the next. Saved as the dicts they are.

Asserted (`_stack_checks`): two boxes make one stack of 400 worth two boxes; seven make a full
and a second; shells keep apart; a bought box joins without a cell; the rig top-up and the split;
the leave merges back; found rounds join the found stack; bottles roll plain and stack to ten;
one off for a socket and back on from the strip; the Lock-up fits; the save.

## Faces for the people who matter (2026-10-05)

The three heads have a line when you arm them ("The carpet man: Word goes to the warehouse that
you're coming. He puts the kettle on." / "The manager: The branch is told to expect you. He has
the staff tidy the counters." / "The quartermaster: The depot's gate is left open for you. That's
not a kindness.") beside the lines they had for coming out and going down; the run screen has a
64 px face slot at the top right of Them that shows the head while he's out, where the art
exists. `tools/pixellab_people_heads_manifest.json` has the three portraits (128 x 128, in the
fence's style) - that one's Matt's to run. The Caravan's runners before are a wall of faces now:
up to six small (64 px) class faces, newest first, at the foot of the panel, with the line beside
them ("Before: a scrapper, 3 runs, died in ransacked streets; ... and 2 more"), the sentence alone
when nothing fits.

Asserted (`_faces_checks`): every head has an armed line; arming logs it once and not again;
the face slot follows whether the art is there; the run fits with the head out; the wall shows
three, newest first, the line clear of the faces, nothing with nobody before.

## The balance pass, from the element read (2026-10-05)

The reader with the real-fight odds, eight minutes of wall-clock a build (four to five yard
hours), one line each: when the bank fell and how deep the campaign went.

    fire    Scrapper   bank 2:16   keystone 1:27   L41   tier 7 cleared
    frost   Poacher    bank 2:58   keystone 1:13   L31   every tier at depth 1
    poison  Poacher    bank 3:11   keystone 1:35   L34   tier 6
    shock   Scrapper   bank 4:28 → 4:02 after the first buff; a second applied below
    bleed   Doorman    bank 4:55 → 3:32 after the buff
    plain   Scrapper   bank about 3:45 (the class reads)

Changes made, all defaults of mine, Matt to overrule: **shock** - shocked gangs take 25% more
(`SHOCK`, was 15), 40% under Live (was 30), and Live wire / the jump leads chain shock to everyone
on you while the shock holds, not only on the first of a gang ("Shock on one of them is shock on
all of them"); **bleed** - bleeds take 70% of a hit (`DOTS` ratio, was 60) and under Won't stop they
stack to three. Fire's self-burn and Frozen solid's take were fixed above (the first walled the
fire build at the bank; the second made frost unkillable). The band now runs 2:16 to about 3:30
for the five against 3:45 for a build with no element, which is the point of the builds: an
element is a spike, and each spikes somewhere different (fire at the estate and the city, frost
anywhere its damage holds, poison at the city, bleed and shock where they aren't resisted). The
estate's boss is the gate most reads stall at for a while (the odds with him in sit under 75%
until the kit catches up), which reads as right. The run-to-run spread of a single read is
about ±40 minutes, so none of these is a precise figure.

Also found and fixed on the way: the Lock-up's hint line ran under the buttons when it said "No
room in the stash for what comes off" - the hint stops where the buttons start now, and shortens
to its first clause when it has to; three state-sensitive tests (the equip, the rig's pouches,
the body drops) make stash room before they act.

## The voice, the book, the places changing (2026-10-05)

**The voice.** The away screen is "Back, then." and reads like the log: "Gone 3 h. 11 runs on
ransacked streets: +£1,240 in, 9 things on the shelf, level 4 to 9." / "Gone 11 h. The runner
slept, the radio played to nobody." with the generator's share ("The yard kept going for 8 h of
it; the rest is just the clock."), a lost runner, and the prices ("The fence's prices are up 42% on
when the yard opened."). The fence's contracts are his asks - "Wants two rare armours, if you're
asking." / "Could use three common helmets. No questions." / "Someone's after one elite rig; the
fence is in the middle." - five phrasings turned by run. The Yard's zone card: "Heads down open
the next" / "Deepest clear on each" / "The runner's patch"; the generator "Keeps the yard going
while you're gone". `Words.AWAY`, `CONTRACT_ASKS`, `NOTES`.

**The papers as the book.** A paper picked up is read and goes in `sim.book` by name, once, in
the order found; six deep ones (`"depth"` on the base: a ration book at 12, a council minute at
18, a bus timetable amended at 24, a letter to the bank at 30, a list of names at 40, the
manager's note at 50) only roll past their depth, so the full twenty is a reason to go there. The
Caravan's middle column cycles to "The drawer · 7 of 20 found": the papers six a page, name over
words, a click turning the page. The book survives a save and comes with a move (it's the
player's reading, not the yard's).

**The places changing.** A cleared site is picked over: drops lose half and cash 30% at full,
coming back over two yard hours (`RECOVER_H`); the Runs card's last row reads "The site · Picked
over · back in 1h20" then "Settling". The clock: the yard opens at 09:00 and from 21:00 to 06:00
every site is Night (the word's effects, from the clock rather than the radio); the weather by
zone, rolled every yard hour (estate 35% rain / 15% fog, town 25/20, city 20/25) - Rain: slower
search, gangs later; Fog: one fewer on you, drops −10%. The sky's words sit in the card's word
rows (a third row for them) and never roll from the radio or sell at it; the card's note line is
the clock: "23:00, night, raining · new word after every run". Saved with the yard. The run
view, when it exists, gets the same.

Asserted: the away report's title and shape both ways and that it fits; a contract's ask;
`_book_checks` (twenty pages, the deep ones gated by depth in 200 shallow and 300 deep rolls,
their lines, read once in order, the deeds not in it, the drawer's head and rows and page turn,
the save); `_places_checks` (fresh at 11:00, picked over on the clear with the thinner drops and
cash, settling, back; 23:00 is Night with the pace; rain and fog's effects; never at the radio;
forty hours bring all three; the card's rows, clock line and site row fit; the save).

## The estate recycles, and three fight fixes (2026-10-05)

Matt: "Nothing on the estate is new; it's all off someone." A dead runner's worn kit (uninsured)
and any unique sold to the fence go on `sim.loose_kit` ("Someone on the estate will be wearing it
by the week's end."). From three runs later (`RECYCLE_RUNS`), three runs in ten (`RECYCLE_ODDS`),
one of a gang is wearing the oldest piece - "One of them is in the last doorman's riot suit." /
"One of them has Lucky cap. The fence said someone would want it." - and it comes off him when
the site's cleared, affixes and all, into the pack whatever it holds: "Riot suit came off him. The
last doorman's, by the name in the collar." / "Sold once, found twice." The list holds twelve;
saved with the yard; a move leaves it on the old estate.

Three things the real-fight odds found, all fixed: (1) a chill or a shock set on a tick wore off
on the same tick at one-second steps, so Frozen solid, Chill and Live never held in the reader or
the odds - they wear off at the top of the next tick now; (2) On your hands burned you for 2% of
the *spread* fire, which at level 40 with Spreads was 25 HP a second and walled every fire build
at the bank - it is 2% of a single hit now, never past 1% of your HP a second; (3) Frozen solid
took all of a chilled gang's fire, which made the frost build unkillable at any depth - it takes
85% (`FREEZE`); "Chilled gangs barely fire; frost does half".

Asserted (`_recycle_checks`): the dead runner's kit and the sold unique go on the list with the
line; nothing on the very next run; worn when due, with the line; off him on the clear with its
affix; home in the stash; the list saves. The chill test reads `FREEZE`.

## Money that goes off (2026-10-04)

Matt: "The game's called Fiat and cash never loses value. It should." Every cash price and every
cash the gangs carry runs through `sim.inflation()`: 1.0 for the first hour of the yard
(`INFLATION_GRACE_H`), then +7% of the opening price an hour (`INFLATION_RATE`, linear, so 7 h in
is ×1.42, a day is ×2.6), settling at ×12 (`INFLATION_CAP`, "the new normal", about a week of
yard hours). Through it: the fence's asking and paying prices, meds, rounds, treatment, every camp
upgrade, call-ins, insurance, the bench's cash jobs, the respec, the fence's cash contracts (quoted
at today's price when rolled), a kill's cash, the cash-per-kill and cash-per-cell affixes, and the
float after a move (`STARTING_CASH` × inflation). Notes don't move: the boss prices, the mate, the
bump, the notes contracts. So cash held loses, cash earned keeps pace, and the late pile is worth
less by the hour from the other end. The fence's panel says "Prices up 42% since the yard opened;
notes hold" once it's more than nothing; the Yard's Played card has a Prices line. Away time counts
(the generator's hours are yard hours), which is the point.

Asserted (`_inflation_checks`): nothing in the grace hour; the rate ten hours past it on the
asking price, the paying price, meds, shells, the bench's upgrade, treatment, the bench's cash
jobs; a kill carries today's money; the ceiling; the fence's line; the Yard fits.

Found on the way: `_move_checks` had dropped out of the run order at some point, so the move, the
late sinks, the damage model and the ammo-word checks had not run for a while. Restored, and three
stale expectations fixed (over-conversion with the socket's fluid still in, the poison cap after
enough stacks to reach it, the ammo line's row on the Lock-up panel). The yard's trade check from
step 9a ran for the first time with it and passed once the log lines were read before training.

## The builds pass, step 9a: the yard's trade (2026-10-04)

Prestige's build piece. Moving the yard asks a second question after "Move the yard?": which trade
comes with it - Petrol, The cold, The rat man, Live or Blades - and from then on every class takes
that element's keystone at the class's own price, for good (`sim.trades`, one a move, five in all;
`affinity()` counts them, so the nodes come at single cost and the keystone opens without the second
past). The town card lists them ("Yard's trade · Petrol, Live"); the move's second line in the log
names it. Saved with the yard. All thirty-five uniques carry a rule the sim reads, so "the rest of
the uniques" is the manifest and the art, not code.

Asserted (in `_move_checks`): the trade's menu opens with the five; a Doorman can't take poison's
keystone before and can after; the trade can't be taken twice; the cost drops to one; the line; the
save round-trip keeps it.

## The builds pass, step 8: a bot an element, and the band (2026-10-04)

`tests/bot.gd` takes an `element`. With one set the bot is a build: it trains the element's tree
before the class's and saves its odd point for an off-affinity node at double rather than spend it
elsewhere; at the second past it picks a class with the element's affinity when the first lacks it
(the keystone needs one); it holds the primary that carries the most of the element (the base's
share, its affixes, what's in its sockets, weighed with the score - a plain gun has to be well ahead
to displace one that carries it), keeps such guns and the element's socketables out of the fence's
pile, seats the element's socketable before the best by score, primary first, buys one off the
market when a worn socket wants it, and weighs a market gun its own way. At the bench
(`_craft_toward`): a socket when the primary has none, an affix added until the element's conversion
and increased are both on it, and when the piece is full without them, the rest re-rolled around
the one it has, or the lot - two grand kept back, four goes a visit.

`tests/balance.gd -- 6 elements [class]` reads the five builds one line each: the class (the
element's affinity unless given), when the bank fell, when the keystone was taken, the element's
share of a hit and its damage a second, runs and KIA, the deepest on every tier (where the build
walls), the kit, and the bench and second-past lines.

Their side changed to make the band mean something: from depth 8 a zone's *own* resists rise with
depth - what it wears (its res) and what it throws (its types) - and the rest stay open. The estate
hardens against bleed, the town against bleed, physical, fire and poison, the city against fire,
shock, physical and frost (greatcoats: frost 10% added to the city). Before, every resist rose
together, which was a flat tax on everyone rather than a reason to pick. "Resistant" still adds to
all six.

Asserted (`_element_bot_checks`): for each element as a Doorman - own tree first, the odd point
saved, the second past taken with the affinity, the keystone reached, the gun carrying the element
held over a stronger plain one, a socket bought and the element's socketable seated, the increased
affix added, the build mostly its element; and the band: at depth 30 on every site, some build lands
60% or better, something is resisted 30% or more, and something lands untouched. Three reads made
robust against the worn kit (conversions read relative or on a plain gun; the yard's node trained
before the class change; the rig drop makes room first).

## The builds pass, step 7: the Craft view (2026-10-04)

The Workshop's third view, beside Guns and Sockets. The grid shows the stash's gear the bench can work
on (`_craftable`: not parts, meds, rounds, papers or uniques, dearest first); the panel reads the piece
- name and base, figures, "Level 14 · up to T3 can roll", each affix on its own line with its tier,
then what the bench charges for a re-roll, an added affix, a socket and a bump (cash, or notes for the
bump). Bench opens the same menu the Lock-up uses (`signal bench(id)` → `main._open_bench`), so the
lock/one/strip jobs live there; Sell is beside it. The view buttons are a third of the body each;
the stash grid's filter switches with the view. Worn gear still goes to the bench from the Lock-up.

Asserted (`_craft_view_checks`): the panel is up and asks for a piece; the grid holds only craftable
gear and the rolled piece; picking fills the level line, the affix's tier and a priced job; Bench
opens the menu; the panel goes with the view; every label fits with nothing picked, a piece picked
and the menu open.

## The builds pass, step 6c: sets (2026-10-04)

Matt: "set gear/bonuses - find all of the council gear etc. ... Sets need a special tint outside of
the coloured tiers." Five sets (`Data.SETS`): the council's (4: hi-vis, hard hat, rucksack, lanyard;
all resists +20 at two, +4 HP a second at three, searches 30% quicker and notes +50% and every cache
opens at four), the ambulance's (3: rig, overalls, crew helmet; meds 50% quicker at two, the first med
free and meds heal double at three), the bank's (3: blazer, cashier's pen, holdall; cash +30% at two,
cash from kills ×2 and the fence pays +25% at three), the army's (4: helmet, carrier, bergen, rifle;
armour +15% at two, first shot +40% at three, one fewer on you and everything ×1.3 at four), the
carpet man's (2: knife, knee pads; 30% as bleed and bleeds last twice at two). A piece is a fixed
base with its own name and two fixed affixes, rare-valued, rolled like a unique, found loose from the
set's depth (5/8/10/15/5) at `SET_DROP` × depth. Bonuses are stats added through `_affix_sum`
(`set_stat`) and a rule at the top (`has_set_rule`). Drawn in `Pal.SET` (teal), apart from the
rarity colours; the cell shows the piece's name; the Lock-up's panel says "The council's · 2 of 4
worn · next: +4 HP a second" in the tint. Words for the sixteen pieces; a `sets` manifest (16 jobs).

Asserted (`_set_checks`): every piece rolls, is named and tinted and has words; the count and the
bonuses at two and four; no rule at two; the panel's line; the army's contact and ×1.3; the carpet
man's bleed and doubled seconds; the depth gates.

## Ammo (2026-10-02)

Guns fire rounds now. Five types match the gun types - nails, shells, rifle rounds, 9mm, pistol rounds -
each a stack in the rig (a slot, like a med; rigs are a slot bigger for it), spent per shot at the gun's
rate while it fights: the primary's while it has rounds, the secondary's when it's the one firing. A gun
with none is dry: the secondary fires at full, and with neither it's fists. The log says "Nail gun: dry"
and the Run's note reads "2 meds · primary dry". Tarkov's shape: you pack what you take; nothing refills
in the field.

A stack is a bag, sized so a run takes about a third at the type's rate (nails 200, shells 150, rifle 400,
9mm 600, pistol 300). Two grades a type: standard, and a better one at 60% of the rounds for +15–20%
damage (hardened bolts, slugs, match rounds, hollow points). Standard boxes are at the fence without end
(`buy_ammo`, a box a cell to the stash, by the box down the Fence's left column); better grades are
found - 22% of a kill's drops are rounds, half a look's share, and half the rounds found fit what's in
your hands - or on the fence's shelf. The Lock-up's Take and the Clinic's take rounds into the rig like
meds. Items: `slot` "Ammo", `rounds`, `Items.is_ammo`, `ammo_type(gun)`; sim: `rounds_for`, `has_rounds`,
`grade_bonus`, `_spend_rounds`, `first_med` (the Use button and the Paramedic's rule find the first med,
not the first thing in the rig). The bot and the smoke bot carry rounds for two runs and buy boxes when the
stash has none; the reader's curve held (depot about an hour, the Town after two).

## Vendors as grids, the art out, the check tightened again (2026-10-02)

- **The Fence and the Clinic share one screen** (`scripts/ui/vendor.gd`; fence.gd and clinic.gd are gone).
  The grid on the right is either the vendor's shelf or your stash, switched by two buttons at the top of
  the left column. The shelf is finite and shows as cells - the clinic stocks 6 / 10 / 16 meds by level
  (`Sim.clinic`, `_restock_clinic`, cheaper ones more often), the fence 3 / 5 / 8 items - and what's bought
  leaves it until the next run restocks. Pick a shelf cell to Buy; a stash cell to Sell (or Take into the
  rig at the clinic). The left column is the vendor's own business: the fence's sell-by-rarity buttons and
  bigger shelf; the clinic's treatment, Treat, and its level. The by-name `buy_med` stays for the bot.
- **The glyphs are out** - not asked for, and generated art replaces them. glyph.gd and the two old screens
  are in `_to_delete/` on the Legion with a `.gdignore` so the editor skips them; delete the folder.
- **The check treats a button as its whole rect**: a button's background covers whatever is under it, so a
  label the button overlaps fails even where the glyphs don't - which is how the Clinic's treatment panel
  got through before. Several vendor lines were too long for the panel on the worst-case pass and are shorter.

## From the playtest of that build (2026-10-02)

- **Gear tiers run to 5.** The Town's three sites drop to tiers 3, 4 and 5 (`MAX_TIER`), with bases at
  4 and 5 in every slot - a scoped .308 and a sniper rifle, a drum and an automatic shotgun, an army and a
  belt-fed SMG, a workshop carbine and a tooled-up garage rifle; ballistic and full-face helmets; a ballistic
  vest, a full plate carrier and light plates; a medic's harness and a plate rig; an expedition pack and a
  cargo frame; a surgeon's kit; five parts. The fence and the clinic stock to `gear_tier()`, the best any open
  site drops (the cap at 3 on `best_tier` is gone). The Town's hostiles were balanced against tier-3 kit, so
  tier-5 gear outgrows the bank - depth is the ladder past it; the reader after the playtest says by how much.
- **No screen on the retail park.** The clear goes to the log ("The town is open") and the Runs rail; the
  menu that stopped play mid-run is gone.
- **Names without the rarity word.** Rarity is the colour on a row's edge and the word on its figure line,
  so rows and titles say "Hiking pack", not "Uncommon Hiking pack". Uniques keep their own names.
- **XP as N / N.** The Yard's bar reads "XP 312 / 1,154" - into this level, of what the next takes - and
  the top bar carries the same after HP.

## Items 11–15, built in one go (2026-10-02, at Matt's call, during the playtest)

**13 first - the pool.** 18 primaries (five improvised from a nail gun to a garage-built rifle with every
mount; five shotguns; six rifles; two SMGs), 8 secondaries, 6 helmets, 7 armours, 5 rigs, 6 packs, 5 meds, 23
attachments, 4 uniques. Armour and helmets carry weight as pace (`pace` on the base: a riot suit stops 85 and
costs 8% pace, leathers stop 25 and give 4%); so do a few rigs and packs. Attachments come in full sets a
mount with trade-offs, and the first are made for a type - a choke and a heat shield for shotguns, a bipod
for rifles, a belt box for SMGs, a wire stock for improvised guns - and only count on a gun of that type
(`Items.att_fits`). Uniques are named items with a fixed affix set and a rule the sim reads like a
keystone: Grandad's shotgun (the first of every lot takes triple), the Postman's bag (every look finds one
more), the Doorman's jacket (a quarter less with three on you), the Lucky cap (finds half as likely to be
common). They drop at depth 2 and past at 1% a find per depth, and go by their own name everywhere. The
runner's worn kit is built by name now (`_plain`), so the pool can be reordered freely.

**11 - juicing.** Radio level 3 (£15k, "a transmitter: call in words"): Call in adds a word of your
choosing to a site, up to three, at three times the tier's word price, chosen from a menu four at a time;
Hold keeps one word and re-rolls the rest at twice the price. A run still spends the site unless it's
pinned. The tier cards drop their note when three words and four buttons fill them.

**12 - synergies.** Four affixes keyed off the build: damage an attachment fitted (primary), armour an
empty pack cell (armour, pack), loot find a med carried (rig, helmet), cash a pack cell filled on the way
out (pack, rig). Typed attachments and uniques above. Nothing is scripted to pair; the pairs are what the
rules do together - Not today with under-half-HP damage, Never there with the look bonuses, Delivery day
under Bodyline, a choke on a shotgun under Shotgunner. The guard is in the reader: `-- 6 all` runs every
class with a bot that trains its class trees to their keystones first (saving points for a keystone rather
than spending them elsewhere) and holds its class's gun type, and prints a line each - when the bank fell,
level, cash, which keystones it reached, what it was carrying.

**14 - the Clinic on the grid** (`scripts/ui/clinic.gd`): treatment (HP, rest, Treat for cash) and the
clinic's level down the left with the shelf of meds a row each; the stash's meds as the grid on the right;
pick a shelf row to Buy, a stash cell to Take into the rig or Sell; with nothing picked the panel is the rig
with Leave for the last thing taken. The medic cards are gone from main.gd.

**15 - the first art** (`scripts/ui/glyph.gd`): a glyph per kind of item - the five gun types, helmet,
armour, rig, pack, med, and one per mount - drawn as line art, so it scales and tints. A faint silhouette
behind every cell's words (tinted by rarity), a mark on the Lock-up's body rows and the Fence's shelf.
Placeholder for drawn art, but the shapes are the shapes an artist would be given.

The worst-case pass covers the whole pool and the uniques; the smoke test drives juicing, the Clinic and
the pool's rules (a choke counts on a shotgun and not on a rifle; a unique's rule and name; weight as pace).

## Before the one balance pass: the numeric features (2026-10-06)

The plan is concept.md's "Before the one balance pass" section (items 27–37 in build order, the gates
table under them). Each lands as its own commit with a reviewer pass; nothing is tuned while they go in.

**27 · The loot roll straightened.** `Items.roll` reads `rarity_bonus()` and the intel's rarity, not
`loot_bonus()` too, so Rat's share's −20% quantity no longer takes 20 off quality. Quantity reaches
searches: `_search` carries `m["extra"] += loot_bonus()` and a whole point of it is an extra find (+25% is a
fourth find one search in four; the mission dictionary holds the fraction, an old save starts it at 0).
Quality's sources widen: the dog adds 5% then 10% (`KENNEL_LEVELS.quality`), loot quality rolls on
backpacks, and the two classes without a rarity node have one appended at the end of a tree so no node id
moves under a live save (Muscle's *Spoils*, Triage's *Pockets checked*, 15 each off the notable). Smoke:
a +100% pack doubles what a search brings, the dog adds 5% quality, Rat's share moves quantity and not
quality, the two trees carry a rarity node, the backpack affix rolls. Reviewer: clean.

**28 · Capstones, one a tree.** A sixteenth node appended last to every tree (so no node id moves under a
live save), `{"capstone": true, "effect": "cap_*", "needs": <the keystone>}`, costing a third of the rest
of the tree (`Data.capstone_cost`), and trainable only once the keystone and every notable are. Each is a
rule, not a stat: The yard's *The dog's share* (the rig comes home to the stash when an uninsured runner
dies), Stalking's *Dead quiet* (patrols arrive as one gang, never grown), Snares' *Poached* (a patrol's
arrival is a find), Muscle's *Iron* (a kill heals), The door's *Held* (no hit over a tenth of max HP, with
a grace after), Triage's *Clean hands* (a patch clears the runner's dots and gives three seconds' immunity),
Shifts' *Transfusion* (heal overflow becomes bonus armour), Stripping's *Jerry-rigged* (improvised guns
×1.5), Fencing's *The lot* (double cash on an extract with a full pack), Moving on's *Ghost* (the first
gang never comes, and a full pack brought home is the clear: the tree's keystone is Never there, so no gang
ever arrives on that tree and a clear by fighting could never happen), Luck's *Loaded dice*
(a find rolls twice and keeps the better), Petrol's *Spread*, The cold's *Shatter* (physical ×2 on a
chilled target), The rat man's *Lingers*, Live's *Arc* (shock does not wear off), Blades' *Bleed out*
(bleeds ×1.5). The Caravan shows it as a wide ◆◆ tile under the keystone (TILE_H 52, seven rows), the
panel titles it "capstone", the ticks and the sum count it, and the run band's third right line names the
runner's capstones. Smoke: one a tree, the cost, the gate, Poached finds on arrival, the wide tile, the
band's line, Dead quiet's size, Ghost's start, no clear on arrival or on a light extract and the clear on a
full one, Held's cap, Iron's heal. Reviewer: Ghost as first written ("clears on the first gang beaten") was
unreachable behind Never there, so it became the full-pack clear; Held now caps after the dots on you are
added, not before; Transfusion keeps a med's overflow only, not the regen trickle's; Jerry-rigged scales the
primary alone; Clean hands' grace runs down in the search too; Bleed out scales the bleed's rate as well as
its hit; the dog's share leaves the rig out of "Kit lost"; the yard's capstone scope line asks for every
notable, not a keystone it has not got. Also caught by the fence check on the way: *Nails through it* (a
business end whose only stat is a bleed share) had no headline and no words, as the bleed share was in
neither attachment list; it is in both now, and every part is asserted to have a headline.

**29 · Picked over inside a run.** The between-run curve applied within one. A site gives `thin_after`
searches in full (`THIN_AFTER` 6, +`THIN_PER_DEPTH` 2 a depth, the lot scaled up by the quantity bonus:
+25% is a quarter more searches), then each search's finds thin by `THIN_STEP` a fifth, to `THIN_FLOOR`
two fifths. It lands in `_search`: the search's finds (the base, Scavenger's, the dog's, the postman's and
the quantity fraction's) are counted first, then each is a roll against the share still there, so nothing
changes before the searches are up and no random number is spent there. The run screen's Searching bar
reads "Thinning: finds at 80%" in the warning tone, then "Thinned out: finds at 40%" at the floor ("picked
over" is a weather and an atlas rank already); the searches-in-full figure ratchets through a run, as a med
used would shrink the quantity bonus and jump the share; the
fight box's head says "every gang the size of the first" under Dead quiet. Smoke: fresh and at the limit
the share is 1, one past it a fifth off, far past it the floor; the two bar readings fit; at the floor sixty
searches bring under four fifths of a fresh site's; +100% quantity near doubles the searches, depth adds
two each.

**30 · Wounds.** `sim.wound` is "" or one of pace, armour, hp. The hit that takes the runner from a quarter
of max HP or more to under it (`WOUND_AT` 0.25, in `_fight` after the second's damage lands, never in a dry
run) rolls one of the three and cuts it a tenth (`WOUND_PCT`) through `wound_mult` in `_pace_raw`,
`armour()` and `_max_hp_raw`; a second wound replaces the first. The clinic treats it: `treat_cost` adds
`WOUND_CASH` 20 a level (the clinic's discount and inflation on the whole), `needs_treating` is HP short or
a wound, Treat clears both; the button reads "See to the wound (£)" at full HP, the band's unit "wounded:
pace −10%" in the bad tone. The run's runner head reads "THE RUNNER · WOUNDED: PACE −10%", the yard's
Runner card carries a bad chip first in its row (the trait's words are long and a full row drops from
the right), the Last run card's status "XP +93 · wounded", and the report carries `wounded`. Saved as
`wound`; cleared in `_kia`; auto-run stops on a wound (the clinic stays a decision). The bot sees to a
wound on return when it has three times the price. Reviewer: the odds' cache key carries the wound (an
armour wound on small armour could leave it stale), a stray save value reads as none, Not today's save does
not wound (no double punishment on the save). Smoke:
through the fight a hair over the quarter; one stat cut and the other two whole; a second still one; the
run, yard and clinic words fit; the price by level; Treat clears it; saved, loaded, gone with the dead.

**31 · The works' top levels.** A fourth level on each, a rule not a figure, priced as the top sink: the
generator's "The works wired" (£30,000) adds a second row of pouches to the rig (`RIG_ROW` 8, the rig never
past `RIG_CAP` 24, which the Lock-up's three rows and the run's row hold); the lookout's "A lookout on the
radio" (£24,000) holds the first gang after the clear until the call, and the call is a full pack (the
clock does not run while the pack has room; the second gang comes as it would); the kennel's "The best dog"
(£18,000) carries the dearest thing in the pack home to the stash when the runner dies, insured or not,
and the Last run card says so. The works card reads "a rig row", "the call", "carries home" for them.
Reviewer: both rig displays now hold `Data.RIG_CAP` (they clipped at 18, which Issue webbing on a big
rig already passed); the run's rig goes to two rows of 29 px past twelve pouches, in the one row's height,
a small pouch carrying the slot's short word alone; the Next gang tile reads "on the call" while held; the
deeds carried home count as held; the report's "left" leaves the carried one out. Smoke: the row and the
cap, a 24-pouch rig inside its box on the run and in the Lock-up, the held clock, the tile, the full pack's
call, the second gang unheld, the dog's carry and the report, the deeds held, the card fitted.

**32 · Grenades in the rig.** A slot of their own (`Data.GRENADE`, one pouch, no rarity, no affixes, so
they read plain like rounds): Petrol bomb (fire 80), Nail bomb (bleed 70), Bottle of something (poison 90),
Dry-ice bag (frost 60), Wired battery (shock 100), each with its line. `sim.use_grenade(id)` throws one from
a pouch at everyone on you: the base damage through the type's increases and mores and their resist to it
(Sparky's gloves clear shock's, a shock on them adds its share), times the crowd on you, off their HP; the
dot lands on the gang through `_dot_add`; dry ice chills for two seconds, the battery shocks (held by the
Tester and Arc); the pouch is spent (Second shift covers meds, not these); nothing throws at no one. A
look's finds carry them (`GRENADE_DROP` 4%), the fence's shelf has one in fourteen, `Items.rig_item` is
meds, rounds or grenades wherever the rig took meds or rounds (Take, the drag, the Lock-up's and the run's
panels, the kind tabs), the run's pouch lights while a gang is on you and throws when pressed, the head's
chips read "Grenade · Fire". Guns are a damage and a rate now, so a grenade is not a gun anywhere. The bench
builds them under crafting (34). Smoke: the five plain, the throw's figure against the model and the
resist, the dot, the chill, the shock, no one there, the pouch pressed, the pick's Take, the Lock-up's
Take and chips, the shelf. Reviewer: the idle junk run left grenades alone from the start (it sold them);
a throw's dot cap is the gun's own rate or the throw's, whichever is bigger, so a petrol bomb never shrinks
a burn a fire build has going; Bleed out takes a nail bomb too; the bots do not throw yet, so the balance
reader will not measure grenades until a bot carries them.

**33 · Ammo grades with an element.** A grade's base can carry `conv_<type>_pct` or `first_pct` beside
its `damage_pct`: SMG and pistol hollow point 20% as bleed, Match rounds first shot +25% (the flat crit),
and three new tier-3 grades, Incendiary shells and Incendiary SMG rounds 30% as fire, Salted rounds (rifle)
30% as frost, each with its line. `grade_stat(gun, stat)` reads the gun's live stack (`grade_bonus` is it
for damage); `_conversion_raw` adds the primary's grade share like a conversion affix on the gun, so the
trees' increases, the resists and the dots all read it; the first-shot weight joins the fitted parts' in
`_fight`. The rounds' headline reads "360 rounds, +15%, 20% as bleed". Crafting (34) gets these in its
ladder. Smoke: the words on every graded base, the three new ones present, the live stack's share in the
conversion, none from an empty stack or shells on an SMG, match rounds' first shot and damage, the first
shot heavier through the fight, the odds with no gun in hand. Reviewer: `grade_stat` takes an untyped gun
(a typed parameter would refuse the empty slot and the odds reader meets it); a stack emptying in a dry run
clears the conversion's memo, so the share goes with the stack; the secondary's grade is damage only, as
the primary's base conversion already was.

**34 · Crafting at the bench.** One material, scrap, a count in hand (`sim.scrap`; a count rather than a
stackable, so it takes no stash cells and the gates' "scrap in hand" is one figure): a handful on one
search in five (`SCRAP_SEARCH`, `SCRAP_HANDFUL` 3–6, carried on the mission and home on the extract), an
item's value over `SCRAP_PER_POUND` 20 for scrapping it at the bench (`scrap_item`, the craft view's "Scrap
it (+N)") or ditching it on a run (the log says what the ditch paid). The Build column, `build_options(kind)`
and `build(kind, name)`: a standard box of any type you have a gun for (`BUILD_BOX` 8); a grade from scrap
plus a full box of the one below it (`"from"` on the graded bases, `BUILD_GRADE` × tier; the rounds come off
the stash's stacks, fullest first), the tier-3 grades from the tier-2 ones so the fence keeps the top; a
med from scrap plus the one below (`BUILD_MED` × tier; painkillers and a bandage from scrap alone); an
improvised gun up to the bench's level (`BUILD_GUN` × tier), Common, plain, `"nails": true` so it fires nails
whatever it is (`Items.ammo_type` reads it); a grenade from scrap plus its element's socketable, one off the
stack (`BUILD_GRENADE` × tier; the nail bomb scrap alone). Each option says what it wants and why not ("No
gun for it", "Wants a box of shells", "Short of scrap"). The craft view with nothing picked offers "Build
for scrap", which opens a menu of the five kinds and then the builds four a page with their prices; the
bench band and the Cash card show the scrap in hand. Costs untuned. Smoke: scrap from a search, a ditch and
a scrapping; a box; slugs from a box of shells (and not the incendiaries until slugs are there); the med
ladder; a plain gun firing nails; a petrol bomb taking one lighter fluid; the refusals, the runner out
too; the view and the menus fitted. Reviewer: scrap moves with the yard the way notes do; the run report
and the Last run card carry the run's scrap; a build with the stash full lands over capacity like the deeds
do (left as is).

**35 · Contracts paying in craft materials.** A third of the contracts that do not pay a unique
(`CONTRACT_MATERIAL_ODDS`) pay in materials, one of three: scrap by the handful (`CONTRACT_SCRAP` 6 a rarity
a piece), a socketable of the zone's element (the best tier's zone, its types' first socketable, a bottle
of lighter fluid in the town), or a graded box of rounds for a gun held (one of the grades of a type in
`gun_types_held`; cash when none). `pay` is "scrap", "socketable" or "rounds" with `what` naming the thing;
`hand_in` pays it (a box or a socketable into the stash whatever the room, like a unique), the words read
"6 scrap", "Lighter fluid", "a box of slugs". Saved with `what`. Smoke: three hundred rolls cover every
pay with the right amounts and names, each of the three paid on a hand-in, the tab fitted. Reviewer: the
estate's zone has no bottle for its blades, so its socketable contract pays road salt instead of falling
to scrap; one held type is picked before the grades are filtered. Two flakes fixed on the way: the
workshop test picks the optic mount only when the primary has one, and the resists card's "deal · res"
line has a shorter form.

**36 · Retirement.** At `RETIRE_LEVEL` 30 (the second past's level) the Caravan offers "Retire to the
wall", the owner asks, and `sim.retire()` sends the runner off as a death would without the dying: the
wall's line reads "retired", their kit comes off into the stash whatever the room, the rig with it, the
class and its trees refund (`_refund_runner_trees`, as a death), two new runners turn up to pick from, and
the yard keeps `RETIRE_SHARE` a third of their trait for good (`retired`, up to `RETIRED_MAX` 3, the oldest
making way; two of the same stack). `trait_mult` and the new `trait_add` (the Lucky one's loot quality)
read the runner's trait whole and each retired one's good third (a Greedy one's HP cut stays with the
runner who had it). The Runner card's status line reads "Wall: Tough, Lucky" once anyone is on it (a chip
would push the runner's own trait off the row); the wall moves with the yard, the move's menu says so;
the arrival line logs as a death's does; saved as `retired`. Smoke: the level gate, the
wall's line and class, the kit to the stash, the reset and the candidates, Tough's third on max HP, two
Lucky ones' thirds, the cap making way, the button, the chip, the menu, the save.

**38 · The pool's last add.** Nine tier-6 bases at the top of every slot, seven pieces of resist gear with
the resist in the base (`base_res`, a new term in `_resist_raw`; `Items.base_res_words` on the head's
tail), the elements' five uniques with their rules (`arsonists_rig` → `_alight` on a med used, a petrol
bomb's worth; `gritters_keys` → chill 999 and frost ×2 on the chilled; `rat_mans_overalls` → poison stacks
999 and half the seconds; `substation_key` → the shock chain and `shock_amount` 0.6; `butchers_apron` → the
bleed carried and three stacks) and The fire crew's set at depth 9. Every one has its line and its art job
(the manifest words for all of them; three existing names - Riot shotgun, Fire helmet, Bergen - made the
new ones Riot squad's shotgun, Station helmet (visored), Full bergen). Smoke: the words, the uniques, the
set, the tunic's resist through the model and on the head, each rule's effect, the set's bonus at two.
Reviewer: the dot rules (the overalls, the apron, the bag, Won't stop, the notables' doubled seconds) shape
dots on them only now (`dot_seconds`/`dot_stacks` take `theirs`), so enemy poison on the overalls' wearer
keeps its plain figures; a blue plaque silences base resists too; the arsonist's rig reads a shock on them
like a throw does; the odds' cache key carries the kit's ids, so a swap that moves only a resist or a rule
reads the odds again.

**The balance runner (6 Oct).** Matt: "is that something I can run here locally with my i9 ... just tell me
exactly what to run ... ideally I just have a single command." `tools\balance.bat [hours]` from the repo
root runs eleven Godot reads side by side (the five classes keystones-first, the five element builds on
their affinity class - fire and shock as the Drifter, frost and poison as the Poacher, bleed as the
Doorman - and the loot probe), each `tests/balance.gd -- <hours> gate <Class> [element]` into
`docs\balance\<build>.txt`, waits on `.done` sentinels, then `python tools\balance_summary.py` writes
`docs\balance\summary.md`: the concept's gates table with each row read RED or GREEN from the `GATES`
JSON line every read ends on (the firsts in hours, the odds at every open tier in the kit as it stands,
the depth clears as [hour, tier, depth], runs, deaths, wounded runs, cash against the top bench, scrap
against the dearest craft, the kit) and a line a build under it. Godot's path comes from `tools\godot.txt`
(the `_console.exe`, so the output reaches the files; the file is local and ignored) or `godot` on the
PATH. Eight hours a build is about three minutes of wall here, so the whole pass is a coffee's worth on
the i9; the wall cap is thirty minutes a read. The probe reads the Elite share at +35% quality and
finds a search at +25% quantity from a fresh Doorman (no class loot share; reviewer: the Scrapper's +15%
was in the plain read). Reviewer's other catches: the firsts were seconds where the summary read hours;
depth pace is scored over the hours actually run, not the hours asked for; a quoted or trailing-space
path in godot.txt is trimmed and a missing exe stops the run with its name. A finding for the pass, not
tuned: `_roll_rarity` scales every non-common weight by the quality bonus alike, so +35% quality moves the
Elite share from 2.0% to 2.4% - the "Loot quality visible" gate (3.0% boosted) can't go green on the
current weights, which is what the pass is for.

**The first full read, and the bot fixed (6 Oct).** Matt ran the pass on the Legion: eleven reads in 7 to
27 minutes of wall, `docs/balance/summary.md` nine of eleven red. The summary is GDScript now
(`tools/balance_summary.gd`, run by Godot like the reads; the Legion has no Python), and `tools\read.bat
<hours> <Class> [element]` does one read for a quick look - Matt: "just create something for me to run
these and I'll run them in 2/3 mins instead of the 10+ it's taking you". Three of the reds were the bot,
not the game, and are fixed before any number moves: (1) the wall time was the odds reader - sixty dry
runs a tier - read on every open tier every mission; the pick now scans from the top tier down and stops
at the first that reads PUSH, the climb reads only the tier just run, and the runner is made whole
(treated or rested) before each pick; four hours of the shock Drifter went from 398 s to 201 s with the
same progress. (2) The Scrapper never reached the bank because the bot went dry at hour 4.4: it swapped to
a Workshop carbine with Nails and Rifle rounds still in the rig and a stash full of hoarded improvised
guns (every primary of the class's type was kept), so `buy_ammo` had no room for a box and it fought
unarmed at 5.9 dps for four hours. The bot keeps only the best spare of its type, leaves rig stacks
neither gun fires, restocks the secondary too, and sells its cheapest spare (never a paper or the
build's socketable) when a box has no room; the Scrapper now banks at 3.6 h with its capstone at 4.4 h.
(3) The 0% odds on tiers a build had just cleared (Poacher T3 to T6) are the same dry gun. Reviewer:
the pick's fallback ties go to the lower tier as before; spare ammo of the secondary's type is kept now
that it's bought; the "dry gun beats a bandage" leave is the primary's alone. Still the bot's, not
measured yet: deaths and wounds, since the bot bails at a quarter HP, and depth pace, since the bot
climbs tiers before it digs; the dig rule is next.

**The dig rule (6 Oct).** Depth is clamped to 1 until the campaign is done (`set_depth`), and past it every
site at a depth is the same fight (`Data.CURVE`), the sites differing by what they drop - so a player digs
one site. The bot now does: past the campaign `pick_tier` keeps to the site it has dug deepest while it
reads PUSH at its depth (stepping back a depth at a time when it doesn't), and the climb digs it a depth
at CLIMB; a runner that can't hold any depth falls back to the top-down pick. Before this the pick took
the highest tier at PUSH, so a build left a 100% site for a 76% one and never dug. The depth-pace gate
(a depth an hour from hour 4) assumes the campaign is done by hour 4, which the first read says it isn't
for most builds - the bank at 2.8 to 7.4 h - so that row stays with the pass. Smoke: `_dig_checks` - a
strong runner past the campaign keeps to its deepest site and digs it; a weak one steps back and picks by
the odds. `tools\smoke.bat` runs the smoke on the Legion and prints the failures and the verdict.

**The second read; the bot leaves a picked-over site (6 Oct).** With the dry gun fixed the second pass
read eight red: the keystone row green (every build by 1.7 h), the bank 1.4 to 5.0 h, the 0% odds gone
from the tiers a build had cleared. One build stood still: the plain Drifter took Never there at 0.9 h
(no gang ever comes), its pack would not fill once the site was picked over, so its run never ended; the
bot's 3000-tick guard handed back with the run still on, and from 1:50 to 8:00 it waited at 95/165 HP
with £315 - the treat refused on a run, the rest not happening on one. The bot's leaving is one rule now
(`should_leave`: under a quarter, or with the site cleared the pack full, a second gang in, or the site
picked over - `thinning` at the floor), and it never hands back with a run on. Smoke: `_leave_checks` -
a Never there runner stays on a fresh cleared site and leaves a picked-over one.

**The bot spends at the bench; the plan wired to the code (6 Oct).** Matt: "wire the rest up similar to
cash - everything will be ready by the time this pass finishes". The plan in concept.md ("The pass plan")
now names the code each lever touches, from a survey against the sim: income has two shapes (the tier's
cash before the campaign, `CURVE.cash` 40 × 1.10 a depth past it), so lever 1's base is one reader, the
open tier's pay through `effective()`; a gun is built only at a tier the bench has reached and the bench
stops at level 3, so `BUILD_GUN` reaches T1–T3 only (a question for lever 2); Pipe shotgun and Carrier
bags sit under the starting kit too; the affix tier has no item-level floor today (`TIER_CAP` and
`TIER_WEIGHT` only), so the floor in Matt's rarity shape is new, and T5 needs item level 15, which the
rarity's cap overrides; the Builds section had the tiers backwards (T1 is the worst, as built). The
reader for the cash row: `_bench_worn` re-rolls the worn kit's weakest affix, one job a run at most, while
two grand stays (a player with £200k re-rolls; the bot added one affix a piece and stopped), so the spend
is bounded by the runs and what piles up past it is the prices'. Smoke: `_bench_worn_checks`. Reviewer:
set pieces skipped - their affixes are the set's, with no tier, and `craft_cost` would re-roll one
anyway: **a game gap, raised, not fixed** - the bench lets a set piece be re-rolled (`craft_cost`
excludes uniques, ammo and paper, not sets), and `reroll_one` on a set stat outside `AFFIXES` would
error; for Matt to call.

**The third read, and the scrap reader (6 Oct).** The third pass (the dig and leave rules in, the bench
rule not yet): 8 red, the keystone and quantity rows green, the bank 1.5 to 6.0 h, cash £47k–£492k,
scrap 4.4 to 6.3 crafts' worth, the odds reds now on tiers above the builds' best, which is the reader
being honest. Before the scrap number moves, its reader: the bot never built anything with scrap, so
the row read income alone. `_build_one`: one build a run at most, the best grade of rounds for the
primary's type the stash can make, else the best med, while the scrap stays at twice the price. Smoke:
`_build_one_checks`. Reviewer: the check's scrap arithmetic. The next read carries both bench rules;
cash and scrap move on what it says. A flake seen once this run, to pin: "match rounds' first shot did
not land heavier: 25.9 against 25.7" with the stats read right, so the half-second fight fired the same
either way - the check wants the shot itself, not a half-second of fight. Matt runs the smoke on the
Legion from here (`tools\smoke.bat`); a commit waits on his verdict.

**The starting kit is the worst kit (lever 3, the kit half; 6 Oct).** Three bases of their own under
the pool, flagged `"start": true` and skipped by `Items.roll` (never found) and by the bench's gun builds:
the Hand-me-down nail gun (24 × 0.5 = 12 a second, no mounts, under the Pipe shotgun's 15), the Work
jacket (6 armour, under the Padded jacket's 10), the Plastic bag (9 cells, under the Carrier bags' 10 -
nine so a found vest, 3 × 3, comes home; the Carrier bags went 8 → 10 to stay above it, still under the
School bag's 12 with their pace). Words for all three; the manifest words for the jacket (the gun and
the bag take their group's). The gate, as a smoke check (`_start_kit_checks`): every base in the pool
beats the start of its slot on its own figures, and a thousand rolls a slot at the top tier never turn
one up. Reviewer: the bench listed the hand-me-down as a build; a six-cell bag could never carry an
armour home; the smoke's "smaller backpack" check read `BASES[0]` as the smallest found pack. Art: three
new jobs on the next `python3 tools/make_item_manifests.py` on the Legion (the generator seeds by list
order, so the inserts shift the seeds of the long guns, armour and bags after them - files already
drawn are skipped, but a forced redraw of one gets a different seed). The match-rounds flake pinned:
the swing's dice seeded right before the fight, not before the deploy that spent them.

**The fourth read; scrap read as income (6 Oct).** With both bench rules in: cash red in two builds
(the poison Poacher £108k, the plain Poacher £43k against a £42k line) where it was seven, so most of
that row was the bot not spending and lever 1 is a small move; scrap 0.1 to 0.7 crafts' worth in hand
everywhere, the bot's reserve (it builds at twice a grade's price), not the economy. The gate reads
scrap earned an hour now: `_gate` counts what the builds spent, `scrap_per_h` = (in hand + spent) over
the hours, the summary's band in the dearest craft's worth an hour (older reads fall back to in hand
over the hours). On the reads so far the economy yields about half a craft an hour, so lever 2 reads
the other way from the plan's "dearer": the ladder is cheap against the stash but scrap is slow against
the ladder; the band's figure is Matt's to set. The summary skips `smoke.txt`. The Pick-A check puts a
School bag on first (Equip on a run wants room for what comes off; the start's bag has nine cells); the
match-rounds check reads the class's first-shot share (a Poacher's +40% is on both shots); the dig
check asserts the rule (the deepest depth that reads PUSH, a dig at CLIMB), not the depths, since the
odds read by the night, the weather and the tree.

## The pass: the first moves (6 Oct)

Each move one commit, the summary line before and after in this entry as the reads come in. The fourth
read is the before: the bank 1.4–4.2 h; the capstone 4.2–5.9 h on five; cash red on the two Poachers
(£108k, £43k); scrap half a craft an hour; the keystone late on the Scrapper (2.1 h).

**Cash (lever 1), as a reader:** the bench is already dear - a lock on a T8 gun is £7k, seven runs' pay -
and the bot spends one job a run; what a flush player buys every run is a word (the words go with the
run: `reroll_intel` after each, so a word is a sink every run) and insurance, which the bot bought only
at ten times the price. The reserve is three times now (`_endgame`). No price moved; the read says
whether one needs to.
**Scrap (lever 2):** `SCRAP_SEARCH` 0.2 → 0.4, `SCRAP_HANDFUL` [3, 6] → [4, 8]: a handful every two and a
half searches rather than five, and a bigger one - search scrap ×3. The ladder's prices stay.
**The band (lever 3, the classes):** the Paramedic's −10% damage and the Scrapper's −5% went (their
words with them); they were the two slowest to the bank, at 6.0 h and 4.4 h on the third read against
1.5 h for the fastest, and the only classes with a damage figure under one. Everything else about them
stays (the heal, the auto-med, the search pace, the loot share).

**Rarity as quality (lever 5).** Matt: "rarity tier means more affix slots available - common can have 1
and it can only ever roll tier 1 affix and so on ... a nail gun rolled as epic with 4 affixes available
stays relevant for levelling builds in the stash", and "common, uncommon, rare, epic, legendary, unique".
Five rarities to the five affix tiers (`RARITIES`: Common one affix to T1, Uncommon two to T2, Rare three
to T3, Epic four to T4, Legendary five to T5; weights 50/30/13/6/1, values ×1/1.8/3.5/6/10; Elite gone;
uniques at the top index, sets at Rare). The rarity caps the tier (`roll_affix` takes the cap on a drop,
over `TIER_CAP`, so a Legendary from the first site is five T5s on a tier-1 base) and the item level
floors it (`TIER_FLOOR` [0, 6, 10, 14]: a deep find rolls no T1s, the floor never above the cap, so a
deep Common is one T1). Quality compounds up the ladder (`_roll_rarity`: a rank's weight × (1 +
quality)^rank), so +35% is ×1.35 on Uncommon and ×3.3 on Legendary: the probe reads Legendary 0.98%
plain, 2.75% boosted, where Elite went 2.0% → 2.4%; the gate is a Legendary share now (2% boosted, 0.8%
plain - the weights give 2.5% and 1.0%, the probe's noise ±0.1). The bench: an add rolls at the new
rarity's cap; the re-rolls keep the level's cap (a Common can be re-rolled past its rarity - the bench's
point) - reviewer: three rules at one bench (reroll and lock take the floor, re-roll one does not), **for
Matt to call**. The shell: `Pal.rarity_tone` (Epic lilac, Legendary orange) in place of four arrays; the
Lock-up's filter row six buttons at 70 (the row fits in front of the pages); the fence sells by five
rarities (`SIDE_TILES` 11). Smoke: five to five, each rarity's count and cap, four hundred shallow and
deep rolls inside floor and cap, a T5 from the first site, no T1s deep, the bench's add to the top, the
fence's tiles; the label-fit sweep's worst items are Legendaries with five affixes at the top roll. Old
saves: an Elite reads as Epic. Noted, not changed: a plain item taken up the bench ends a Legendary with
four affixes (one short of a drop), as a set piece is a Rare with two. Smoke: the Lock-up's filter row
needed 17 px for six buttons; the fence's five tiles take the short names ("Uncommon" would not fit);
the away check sold four rarities of five, so auto-run stopped on a full stash.

**The fifth read, and two readers more (6 Oct).** With the words, the scrap and the class figures in:
cash green on nine of ten (the shock Drifter £121k), scrap 1.1 to 1.8 crafts an hour on seven with
three under, the keystone row green. Two things in it for the reading rather than the game: the plain
Poacher banked at 6.1 h this read and 2.5 h the last with nothing about it changed, so one eight-hour
run is a noisy sample of the bank and the band flickers - `tools\balance.bat` runs each build twice now
(twenty-one jobs) and the summary merges a build's reads (the firsts and the odds by the median, cash
and scrap by the mean, the counts summed; each read still on its own line in the builds table). And the
"No reds" row was reading the endgame ladder - a build that cleared T8 showed it at 0% at the depth the
dig rule had pushed it to - so `_gate` reads every open tier at depth 1, the campaign's odds, and puts
the depth back. Wounds read 2 to 10% in every build across five reads against a 10 to 25% band, with
a quarter being where the bot and the odds call a run lost: `WOUND_AT` 0.25 → 0.33.

**One rule at the bench; no bench job on a set piece (6 Oct, Matt: "take defaults and build").** The
bench works as a drop does: within the rarity's cap and the level's floor (`Items.rarity_cap`; re-roll
and lock, re-roll one - which steps up only under the cap and down only above the floor - and add at
the new rarity's cap), so rarity means the same at the bench as in the loot and the way up a tier is an
add (a rarity up) or a better drop; a tier already past the cap on an old save is left where it is. The
level's bump raises the floor now, and its words say so ("the worst tiers stop rolling"; the craft
view's line "Level 16 · T4 to T5 roll"). A set piece gets no bench job (`craft_cost` −1, the Lock-up's
and the bench's lists and buttons leave it out, the empty-pick words name sets): its affixes are the
set's, with no tier, and a re-roll of one outside the affix table would have errored. The bot's bench
rule stops at the rarity's cap, not T5, or it would pay for "no change" every run. Smoke: re-roll one
and a full re-roll on a level-16 Rare stay T3; every bench kind refused on a set piece; the re-roll-one
tier walk reads 240 rolls (a T4 at the floor only moves up, one in sixteen).

**The sixth read (twenty reads merged; rarity, the readers and the wound threshold in).** The band 1.3
to 2.6 h (was 1.4 to 6.1 on single reads), the keystone green, the Legendary share green (2.57%
boosted, 0.91% plain), wounds in the band on five builds and 28-32% on four, depth pace one build
short, the capstone late on three at 4.3-4.6 h. Cash back on seven at £100k-£390k, and the table says
why: the rich reads dug T8 to depth 9-15 (the bleed Doorman £261k at depth 15), the poor stayed at
depth 1 (£300-£6k); the curve pays 10% a depth compounding and the word - the sink that scales with
depth - is £70k a run at depth 15, so the bot's three-times reserve stopped it buying and the pile
sat under three words. The gate's figure (three times a £14k bench) was the wrong shape for a ladder:
the cash row reads hours of the build's takings in hand now (`cash_per_h` in the gate, two hours the
band), and the word reserve is twice. The moves with it: `WOUND_AT` 0.33 → 0.30; `SCRAP_SEARCH` 0.4
→ 0.5 (three builds at 0.5-0.8 a craft an hour); `capstone_cost` a third → a quarter of the tree
(lever 4's one touch; the barracks' words with it). The builds table reads wounds, crafts and pace
for every read now, not only the merged line.

**The seventh read: the word priced off the run's pay (lever 1 proper).** Six red; depth pace green,
the capstone late on one at 4.1 h, the band 1.3-2.5 h. Cash red on seven, and the pairs say what it
is: one read of a pair ends on £170-£4k and the other on £140k-£228k, the same build - the rich read
is the one that dug deep. The word cost the tier's price × 3 × the depth × the words on it: at depth 9
on T8 that is £194k against a run paying a few thousand, so the bot's reserve never met it and the pile
sat; at depth 1 it was £22k and bought every run. A sink that scales with depth faster than the pay
does is no sink. `juice_cost` is half of what a run on the site pays in kills now (`run_pay`:
`effective(i)` cash × pool, so the curve's depth is in it), never under the tier's word price three
times over, the words' multiplier and Word travels as before. Smoke: the depth-4 call-in is half the
run's pay there. Reader: the odds at the end were read in whatever state the last run left the runner
(a Doorman read T2-T8 at 0% hurt, 100% whole), so `_gate` reads them at full HP. Wounds swung from
28-32% over on four builds to 5-10% under on five with the threshold moved 0.03, so that stat is noisy
at two reads a build; left at 0.30 for one more read before it moves again.

## The fence's gamble, and deaths read (6 Oct)

Matt: "lets just design a late game cash spend now ... the mechanics of it need to copy diablo 2 - each
item rotated in a new stash tab at the fence. A base image of a rifle for example which then rolls you
a random rifle. Not all items available at a time so you have to do a run or two to get a refresh you
want to gamble on. Also need to include uniques at any stage so you could always gamble a unique on a
fresh save with some immense luck." The sim side, built: `GAMBLE_KINDS` (eleven: the five gun types,
a sidearm, a helmet, body armour, a rig, a pack, a charm), `GAMBLE_SHOWN` five of them on offer at a
time, rotated with every restock (so after every run) and only the kinds the fence can source at the
tier opened (a fresh yard sees nine, no rifle or SMG at tier 1); the price `GAMBLE_RUNS` (two) runs'
pay on the top open tier, never under `GAMBLE_FLOOR` (£300), at the day's prices; the roll
(`roll_gamble`) a drop of the slot at the loot tier opened, at the best depth there, with the fence's
quality on it (`GAMBLE_QUALITY` +50%, which compounds up the rarity ladder) and never Common, of the
kind's type; and on `GAMBLE_UNIQUE` (one in fifty) a unique of the kind, from the first save on, when
the pool has one for it (every kind but the charm has). Pay and it lands in the stash, the kind leaves
the offer. Saved as `gamble`; a save from before gets its offer rolled at load. The bot gambles its
primary's kind, else armour or a helmet, one a run, at three times the price in hand. Reviewer: the
older-save fallback ran before the tiers were loaded, and an empty offer is also a bought-out one -
keyed on the key's absence, at the end of the load. Smoke: `_gamble_checks` - the offer's size and
rotation, the price, refused short, the kind and never Common, the stash and the offer, the unique on
the dice, a fresh yard's offer, the bot's rule. The figures are untuned until the read.

**Deaths, read.** Matt's save: 46,841 s of yard time (13.0 h), `operators_lost` 7 - one every 1.9 h,
seven runners over 116 runs. The bot never dies (it bails at a quarter), but a bail-out at a quarter is
the run that kills a player who pushes on, so the gate reads the bot's bail-outs an hour (`bails` in
the bot and the gate; the summary's row: one every 1 to 4 hours, Matt's 1.9 the middle).

**The fence's screen (built after the canvas board Fence-B, Matt: "design is good").** The fence's
fourth tab, "The word": where the grid would be, the title and a line with the price, five tiles across
with a picture of a base of the kind (the first with art), the kind's words (a short form where the
long one would clip), "sealed · any rarity" and Pay with the price; a kind bought reads Taken, "back
after a run", until the restock; under the offer "The last word", the thing the last gamble got you as
the item head (the stash's item by `last_craft`), or a line saying nothing yet; a note at the foot. The
four tabs run the band's foot from its edge at 16 px (the reviewer measured "Contracts ✓1" at 146 px
against a 142 px tab at 18). The fence says a line on a gamble. Smoke: the tab's panel alone, the tiles
against the offer, the fit, Pay through the screen (the stash cleared to make room), the last word, the
taken tile. `tests/shot.gd "word"` renders it.

## The evening's pass (6 Oct, Matt to bed: "take defaults on anything that needs it and record where required")

The ninth read (the deaths row live, the end odds on the plain site at full HP, the gamble in the bot's
hands): eight red, and three of them readers or the bot's appetite rather than the game.

**The odds, a third time.** Half the merged odds read 50%: one read 100%, the other 0%, and the
diagnostic says why - "rounds true 26": the gun had 26 rounds left at the end, the dry run burns them in
seconds, and an unarmed runner reads 0% on every tier. The read arms both guns with a full box for the
reading and takes it back after.

**The sinks priced off the yard's takings.** The poison Poacher gambled fifty times a read and still
ended on £105k-£195k: the price (two runs' pay in kills) was £300-£700 against runs that brought in ten
times that, because the money is the loot sold, not the kills' cash. The sim keeps `takings` now - the
run's cash and the fence's money since the last run, averaged over the last few (`_earn` counts every
cash-in: the run, a sale, a contract) - and the word and the gamble are priced off that
(`a_runs_takings`; the top tier's kills before a run has come home). Saved. Smoke: the call-in half a
run's takings, the depth not moving it, the gamble's price, a run's cash reaching the takings.

**Deaths: the bot's risk to Matt's.** Bail-outs under a quarter read one every 0.5-0.8 h on the pushy
builds (the element Drifters, the Poacher) against Matt's one death every 1.9 h: the bot at PUSH 0.75
takes a one-in-four run, Matt's save says one in seventeen. `PUSH` 0.75 → 0.85, `CLIMB` 0.9 → 0.92: the
bot plays to Matt's appetite. This moves every row that depends on how hard the bot pushes (the band,
wounds, depth), which is why wounds move with it: `WOUND_AT` 0.30 → 0.35, since a bot that stays over
85% is under a third less often. `SCRAP_HANDFUL` [4, 8] → [6, 12] for the builds that search least (the
Doorman 0.2 of a craft an hour). The band's unit beside the headline fits by the line the two make (a
radio card read two pixels over).

The reads for the rest of the evening run here, one build each (the Legion's twenty-one is a
two-core night).

**The tenth read (one read a build, here, 22:18-00:08).** Eight red, but a different eight. The odds row
down to one tier (the Drifter's T8 at 25%, the tier it had just opened and not yet held) - the armed read
works; the gate reads the tiers held (up to the best cleared) now, since the one just opened reads what
it reads until the kit catches up. Deaths one in 4-8 runs on the pushy builds still; the gate reads
runs a bail-out now (Matt's one in seventeen; an hour's reading depended on runs an hour), band one in
10 to 30, and `PUSH` 0.85 → 0.9, `CLIMB` 0.95. Wounds 8-39% (the Poacher and Scrapper high; the
safer bot should bring them down). Scrap 0.6 to 4.9 crafts an hour - [6, 12] overshot on the builds
that run most - back to [5, 10], and the band to half a craft to four, since the spread between a
melee Doorman and a fire Drifter is eightfold by their searches. Cash red on six at 2.5-5.6 hours'
takings: the bot wanted its primary's kind, armour or a helmet, and those are on offer five of eleven at
a time; it gambles whatever is on offer at six times the price in hand now. The capstone's gate 4 → 5 h
(four builds at 4.0-4.7 h with the bot playing to Matt's risk; a default to overrule).

**The eleventh read (00:10-01:40, two builds re-run after the box restarted under them).** Six red,
and five of the eleven rows green together for the first time (the keystone, the capstone, the odds,
the Legendary share, quantity). The odds row is green with the tiers held read armed, whole and
without the site's words: that row has been a reader problem four times and is honest now. Cash red on
one build (the Doorman £51k, 3.9 hours' takings). Deaths one in 33-47 runs on four builds, too safe:
0.9 overshot (0.85 read one in eight), `PUSH` 0.88. Depth pace under one an hour on four with the bot
wanting 95% to dig: `CLIMB` 0.92. Wounds 8-40% across builds, a wide stat at one read a build. Scrap
4.3-4.8 on the two builds that run most against a band to 4: the band to 5 (the spread between a melee
Doorman at 0.6-0.9 and a poison Poacher at 4.8 is tenfold, and both are the game, not a figure). The
band reads within the classes (0.7 to 2.8 h: the Drifter banked at 0.7 h this read and 1.8-2.9 h in
others) and within the element builds (1.3 to 2.1 h) now - the element builds are meant to be ahead -
and at one read a build it cannot be judged; the Legion's double read is the one to read it on. A
twelfth read ran overnight here and died with the box six minutes in (a background job does not keep
the box awake); Matt ran it on the Legion in the morning.

**The twelfth read (the Legion, 7 Oct morning: twenty reads of ten builds).** Five red, and depth pace
green with the rest (every build a depth an hour or better from hour 4). Two of the five reds are the
reader's, and both come from the same thing. *The odds*: the Drifter's and the Poacher's T8 at 50%,
each one read at 100% and one at 0% - and the 0% reads are a runner whole, with 350-700 dps, against a
site doing 4.8, which is no fight lost. `boss_armed` is never cleared after a run: the bot arms a
tier's boss when the odds hold with them in, runs it, and when it picks another tier next the old one
keeps its boss, reads red for the rest of the run (both 0% reads cleared T8 once and sat on T7 and T6
after), and the end-of-read odds read it armed too. The bot turns off every stale boss before a pick
(`_disarm_stale`; the one it picks is armed again below as before), the reader before the end read, and
the smoke arms the quartermaster on T8 and checks a pick turns him off. The sim's toggle staying on is
the game's (a player who leaves it ticked pays the notes every run): recorded for Matt, not moved. *Cash*:
the Doorman, the frost Poacher and the Scrapper at 2.6-4.1 hours' takings - measured against the runs'
cash alone, when the piles form on deep digs where the fence's sales of what came up bring in more than
the runs do (the Doorman went £4.5k to £56k in one half hour with £15k of run cash). The sim counts every
pound in now (`cash_in`: runs, sales, contracts - what `takings` is made of), the reader's cash row and
its half-hour column read that, and the sinks were working where the piles formed (words on tier 8 at
£39-50k each in the last quarter hour). The bot gambled 0-1 times in eight hours: its rule holds six to
twelve runs' takings before it spends, and at depth a run takes £20k; the bot being tight, not the price.
The three real reds: deaths too safe on four strong builds (bleed Doorman one in 51, Drifter one in 34,
fire one in 50, shock one in 45; the Doorman, Paramedic and Poacher in band at PUSH 0.88); wounds 8-40%
(Paramedic 8%, Poacher 40%, Scrapper 37%) - the builds that never bail are the ones with the margin, and
the ones that bail most are wounded most, a spread between classes a single `PUSH` cannot close; and
the band, where every build is 1.3-2.4 h but the plain Poacher, at the bank 3.1 and 3.5 h on both
reads, sat on T3-T4 from hour 2 to 3 with odds reading 0-21% at full HP (the same smell as the odds
row: a mid-run read with the rifle's rounds low, or something else stale) - for a closer look before a
number moves. The thirteenth read goes on these fixes alone, so deaths, wounds and the Poacher are
judged on a read that is not contaminated.

**Defaults taken (7 Oct, morning).** The boss's arm is one run: `deploy` takes the tick off when the
run goes out (the mission carries its own boss), so the notes are paid once a choice, like the
insurance, and a player who leaves it ticked is not quietly charged every run; arm him again to go
back. Smoke: the tick is off past the deploy. `PUSH` stays at 0.88 (the lower band is the strong
four's margin, not the bot's appetite: a lower PUSH would push the Scrapper and Poacher, at one in
12-16, past the floor) and `WOUND_AT` stays at 0.35 (a figure that moves everyone cannot close a
spread between classes): both judged on the thirteenth read.

**The thirteenth read (the Legion, 7 Oct, twenty reads of ten builds).** Four red, and cash green for the
first time (every build under two hours' income, most 0.6: the measure was the problem, the sinks were
not). The four reds are two kinds of thing. *Noise between two reads of the same build:* the band is
red on the classes (2.1-3.9 h) because the plain Poacher banked at 2.2 h in one read and 5.6 h in the
other, the Drifter at 1.7 and 4.3, the Scrapper at 1.9 and 3.8 - the slow read of each sat three hours
on T2-T3 with its loadout's worth flat (the Poacher: £8.8k from 2:00 to 5:30, dps 90-190 against the
quick read's 260 at the same level): no better gun came, from the sites or the shelf. The sites lean
to a gun type half their rolls (improvised, pistol, improvised, shotgun, pistol, SMG, SMG, none, rifle
by tier) so a rifle class is on the other half until T8, but the slow reads come to every class; it is
the luck of the drop, and a read of two cannot band it. The Scrapper's T8 at 26% is the same thing
read at the end: one read with a 728-dps shotgun at 52%, one with a 472-dps one at 0%, both whole, no
boss, no wound - T8 at full strength takes 700 dps or more to hold, and the kit at hour 8 is what the
run turned up. *The spread between classes:* deaths out of band on two builds only now (bleed Doorman
one in 42, shock Drifter one in 32; the rest 9-29), wounds 10-40% - the fire Drifter 50 wounded runs
in one read and 100 in the other, the stat is how often a hit takes the runner under a third, and it
swings with the push. No number moved: Matt's call (7 Oct) is no further number decisions until he has
played the campaign through and put ten to twelve hours into a save, and the four reds left are the
kind his save will read better than the bot - whether a gun drought at T2-T3 is a real wall or a bot
that will not buy, and how often a player who plays to his own risk is wounded. The pass pauses here,
reds recorded with their causes, not accepted: it resumes on his save with the levers named (the drop
lean by tier against the classes' types, a gun on the shelf when the loadout stalls, the strong
builds' top-end margin, `WOUND_AT`).

**The six decided (8 Oct, Matt: "yeah ok do it").** The lorry's price is the plain three heads' (960 notes
at depth 8; it was the full-strength rate, 2,160). The ladders' spread is read at the first lorry (the
first yard's ladders, before the move; at the end only when it never fell) against the same band. The
scrap row reads the first sixteen hours. The deaths row reads Matt's save (`MATT_DEATHS`, seven lost
in 116 runs, one in 16.6) and shows the bot's bail-outs beside, not judged. `WOUND_AT` 0.33. The plain
Drifter waits on the twentieth; the bank's band stays red and labelled luck until the rest is green,
then three reads a build.

**The rail and the top bar, round two (8 Oct, Matt on the ledger as built: "this doesn't read at all -
the rail should span to the bottom of the log bar"; the status bar "could use some love - icons for the
cash and notes, a bar for XP and HP, anything else that would read as not default godot").** Mocked on
the canvas (Rail-B: the top bar now, B boxes, C lines; the rail D full-height ledger with a glyph a
row, E tiles, F stamps); Matt: "Rail should F, Bar is C". Built. *The glyphs:* fourteen line
drawings, white on transparent at 64 px, `art/ui/<name>.png` (yard, runs, lockup, bench, caravan,
clinic, fence, radio, cash, notes, hp, xp, dps, where), drawn in `mock/glyphs.py` and loaded by
`UI.glyph_texture` like the portraits - imported if Godot has, from the file if not - and placed by
`UI.glyph` as a tinted TextureRect. *The rail (F):* the panel runs from the band's top to the log's
bottom (`_rail_panel`, the layout), the rows sharing what's under the heading (`set_row_height`); a
row is a stamped square (`STAMP`, 56) with the room's glyph, the name beside it and one status line
under, or the badge in the status line's place when the room wants a decision (the row is 312 wide and
the stamp takes 72: a badge beside the status overran it, so the badge is the status); the lit row in
the cards' colour with the stamp gold and the glyph dark on it, the tongue to the card kept; the
figures of the first build gone (zeros said nothing). *The top bar (C):* the level a figure at the
title size with LEVEL after it (the caption placed after the figure on every refresh), HP and XP as
figures with a 150 px line under each (`TRACK` under `GOOD` and `ACCENT`, the fill the share), a
glyph before every figure, the place with its pin centred in the room between the runner's figures
and the purse (so the widest XP never meets it), notes and cash with their glyphs set before the
right-aligned figures on every refresh, cash in gold. `TOP_WORST` re-stated without the words the
glyphs now carry. *Assertions:* the rail ends where the log does; every row and every top-bar key has
its glyph; LEVEL clears the level's figure; the join and the badge checks kept; the paragon test reads
the new words. Shot here on the Yard and Runs. *The first smoke on it* caught two faults of mine: the
rail-ends-at-the-log check read the log's place in a shell the smoke never lays out (it runs once laid
out now), and "Upgrade affordable" was 221 px in the 206 the status line has ("Upgrade ready"). The
layout also floors the rows at 72 on a screen too short for them. *The glyphs in the house style
(Matt: "create a manifest for the items that need art in the house style and I'll generate"):*
`tools/make_ui_manifest.py` writes `tools/pixellab_ui_manifest.json`, fourteen jobs, each a painted
still-life of one bold object (a padlocked shed, work boots, a padlock, a spanner, a caravan, a
first-aid tin, a luggage tag, a CB handset; a wad of notes, a bundle of slips, an enamel heart badge, a
brass star, a cartridge, a pocket compass) in the items' voice with their style refs, written over the
line drawings with `--force`. The shell tells a painting from a line drawing by its colour
(`UI.glyph_mono`): a painting shows as it is, a line drawing is tinted, so the set swaps one at a time
and a glyph that doesn't read goes back to its line (`git checkout art/ui/<name>.png`).

**The last pass of refinement (8 Oct, Matt: the status bar, the rooms, the Yard "looks like a total mess - we
are combining runner stats and yard upgrades", the works "need the same treatment as the caravan and the map
... except cash is the cost", "the yard and runner stats need their own menus", "caravan doesn't make any
sense when it displays perk points/skill trees", the class traits "always visible under N of N points free",
"free up space when selecting a perk"; and on the Runner, "split out attack and defence into their own cards
... which then leaves one card for the runner's current stats - time alive, best loot, most damage, most
kills").** Mocked on the canvas (Refine-A), Matt: "ok on everything but just build and smoke the lot in one".
Built. *The top bar:* LEVEL, the figure and the class as one group ("LEVEL 9 Poacher"); HP, XP then damage at
one gap with one line under each; the place, notes and cash right-justified at the same gap, their glyphs
set before the text on every refresh. *The rail:* names only, nine rooms - the status lines went (a room's
state is in the room; a badge still says when it wants a decision, under the name) - and Runner joined; the
caravan's room is Training (the caravan stays as the place on its screen); a `runner` glyph drawn and added
to the pixellab manifest (fifteen). *The Runner room* (`_runner_cards`): eight cards - Runner (level, the
XP bar, the past and trait chips, pace, pack, runs, time in the yard), Attack (the damage a second and what
makes it: guns, level, affixes and tree, the past, first shot; the elements dealt as chips; growth in the
note past the cap), Defence (max HP, armour and the five resists in their colours, what the open sites fire
in the foot), Finds, The record (the best run by kills, the most damage and cash in a run, the dearest find,
runs back, alive - `Sim.record`, kept per runner and saved, reset with them), Kit (what's worn, its worth),
Last run, The wall (the runners before, newest first, the retired). *The Yard* (`yard_tree.gd`): the works
as a tree - a column a work, a level a tile top to bottom, the built ones edged gold, the next one its own
Build carrying its price (on when affordable), the later ones dim with theirs; the clinic, the fence and the
radio are built here too (`_yard_jobs` carries all eight with every level's name and words) and run in
their rooms; the purse and the town as chips in the heading with Move the yard at its right; the town's
note and the clock in the foot. `yard_works.gd` and `yard_town.gd` are no longer used. *Training:* the
band 180 tall with the class's line always up under the points (`_class_line`), the classes across its top
right as before; the detail a strip - the title, its chip and its sentence on one line (a capstone's wants
after the sentence), the buttons and the runners-before line on the second; the faces went (the wall is a
card in the Runner room); the trees' tiles 62 tall from 52. *Smoke:* the Runner room's eight cards by
title, the Defence card's resist line in its colour and its headline the max HP, a torch's share as an
Attack chip; the yard tree's works in order, every tile's state against the sim (built, the next on only
with the cash, the later ones priced), a column's next tile builds, the Upgrade badge, the purse chips, Move
the yard; Training's class line up and the trait's figures on the strip; the wall card's order; the yard
tiles' words inside their tiles; the top bar's order. Run clean here before it goes to the Legion.

**From play on the last pass (8 Oct, Matt).** "DMG needs to be next to XP": the slots step by the line's
width now (`TOP_LINE_W` 180), not by the widest text, so the three sit at one gap, and the XP figures read
123k from a hundred thousand up (`_short`) so the widest XP is "99,999 / 99,999" and fits its line. The
Attack card's headline is "115 dmg/s" with no unit ("damage a second" clipped). The log line is
left-justified: the time at the left and the line right after it, re-placed on every refresh (the time was
right-aligned in a "99:59:59" box, so a "15:15" sat forty pixels in). The dead space at the log's right
is open - a question for Matt. *The caps pass* Matt asked for ("the entire game needs a caps pass -
there's too much to list"): the rule to apply, proposed below in the conversation, then the sweep.

**The caps pass and the log's line before (8 Oct).** The rule, agreed with Matt: a name is capitalised
wherever it stands - the rooms (the Yard, the Fence, the Clinic, the Bench), the zones and sites (The
Parade, The Retail Park, Shopping Centre, The Bank, The Services, The Hospital, The Barracks), the
classes, the trees, the bosses (The Carpet Man, The Manager, The Quartermaster), the uniques and the
sets; everything else is sentence case; acronyms stay upper; nodes and base items stay sentence case.
Mid-sentence a name's own "The" drops to "the" through `Words.mid` ("Arm the Carpet Man", "the Parade
is outside"), never `to_lower` on the whole. The sweep (`/tmp/caps.py` over a 59-entry mapping) ran
across `scripts/sim` and `scripts/ui` and the smoke; the balance tools and tests were swept too and
restored, since their text is the readers' and not the player's. Old names in a save migrate on load:
`Data.RENAMES` (old → new) and `_rename_old`/`_renamed` in `load_dict` walk the tiers, the atlas, the
items and the record, with "The yard/N" nodes to "The Yard/N". *The line before:* the dead space at
the log's right now holds the previous line, dim (`TEXT_3`), starting `PREV_GAP` after the latest
line's text ends; the latest line is fitted to `PREV_X` (1000) at most so there is usually room, and
when the line before cannot fit whole in what is left - no `_by_sentence` form does - it goes rather
than trails off. The smoke checks the pair fit, that the line before starts after the latest, and the
capitalised classes and names in the lines it reads ("Before: a Scrapper, 3 runs"). Local smoke
clean; on the Legion as the caps pass.

**The Bench's treatment (8 Oct, Matt: "last UI we haven't touched since it was introduced - needs
similar treatment to the rest"; mocked as Bench-B on the canvas, built as drawn).** The band goes. The
heading takes the Yard tree's shape across the top: "The Bench / Level 2 · fits optics, muzzles and
magazines", the three views as a tab row beside it (off the art; all three plain buttons now - Guns
had been made as a primary and kept its dark text when `_style` re-skinned it, which was Matt's "Guns
needs to be white"), the purse as chips at the top right, "Next: handguards, stocks" and Upgrade under
them. The grid under the heading runs five rows a page (`set_rows(5)`); the pick panel keeps the foot.
*Guns:* a gun's head is a card (`GUN_CARD_H` 250): slot and figure on the first line, the name, its
chips, the mounts as tiles - a fitted part edged in its tier's colour, an empty mount plain, a locked
one dim with 🔒 and "Bench 3", a mount the gun hasn't a hollow slot (only to square the last row).
Sockets the same, an uncut socket hollow. *Craft:* the piece as a card - name and figure, chips for
rarity, level, "Rolls T2 to T5" and the sockets, its affixes as rows with a tier dot and T-number
(the missing ones "No third affix"); pressing an affix row puts its two jobs along the card's foot
("Re-roll it · £179", "Re-roll the rest · £537", the longest forms that fit side by side). Under it
THE JOBS: six tiles - re-roll, add an affix, cut a socket, strip, raise the level, scrap it - each
with its words and price, gold when it can be paid, grey when short, hollow with no price when the
piece can't take it or nothing is picked; the last job's words (green) and Build for scrap along the
foot. The jobs run in the room through `craft(id, kind, stat)` → main's `_craft` (the toast, the
refresh); the three-page menu stays only for the Lock-up's Bench button on worn gear. The pick panel
shows the piece with its figures and no buttons (Sell is the Fence's). *Caps, the slips the sweep
missed:* "Needs a bench" / "a bigger bench" / "bench level" → Bench; the Radio wherever it stands
(the lookout's and the trees' words, the Runs card's "pinned at the Radio", the set card's kicker);
the cache's "Bench's tools". The smoke: the view buttons' text white, the piece card's chips and
rows, the tiles priced or hollow, the affix jobs inside the card, a re-roll from the room keeping the
count and the foot saying so, the Next words clear of the tabs, the chips inside the heading, the
bat's third tile a hollow slot. Local smoke clean.

**The menus in the rail's shape (8 Oct, Matt: "looks like a default godot project - same changes need
to be made for the in game escape key menu"; Menu-A on the canvas, Title A and Pause B picked).** What
read as the default was the box in a box: five equal grey rows, each its own button, inside a dark glass
panel. `menu.gd` now has three shapes on one component. The rows are a ledger everywhere: ruled by
hairlines, no boxes, the lit row (the focus) on the card ground with a gold bar at its left, a stamp
with a line-drawing glyph where the item brings one (`glyph` on the item: `art/ui/menu_*.png`, eight,
rendered as the rail's were - mine, not Matt's), names at 30 over details at 20, a plain row 72 tall
and one with a detail 92. *The title* (`opaque` over the painting): a column down the painting's left
(`COLUMN_W` 650, a `GradientTexture2D` from the ground's dark to nothing), the wordmark at its head,
the rows under it 570 wide, MUNDANE STUDIOS and FIAT (with `application/config/version` when the
project sets one) at the foot; no panel, no heading - the wordmark is the heading. *The pause*
(`dock`: main passes the rail's rect): a drawer in the rail's place over the dimmed game, the rail's
panel edged gold, "PAUSED · HARDCORE CAMP" as a kicker strip, names only (the rail's width), the
column's empty foot left as Matt chose it. *The card* (everything else: the slots, the builds, the
Bench on worn gear, Move the Yard, the away report): heading and sub as before, the rows ruled. The
dim is sized by hand in `layout` (a full-rect preset set before the node is in the tree left it at
nothing - the pause had been drawing over an undimmed room). *The wordmark:* Matt took the mock's
lettering over a pixellab job - `art/wordmark.png` is now the mock's FIAT / LET IT BE DONE (DejaVu
Sans Bold, off-white with a 2 px charcoal offset) rendered at 200 × 80 by chromium
(`mock/menu_glyphs.py`), cropped to its 154 × 72 of lettering, drawn at the painting's 3× so it sits on
the same pixel grid. The save's words read "Level 24 · £25,161 · 10 h 37 m · 8 Oct, 16:37" (middle
dots, no "played") so they fit the column's row on one line. The smoke: every menu's rows inside the
panel (the card keeps its PAD under them, the column and the drawer end at their rows), a row with a
glyph has its stamp and texture and its name clear of the stamp, the title's rows and wordmark inside
the column with the wordmark above the rows and the foot below, the drawer's rect the rail's exactly
with its kicker up and no details, the card with its heading; the add-words test picks the piece's
own grid cell (`cell_of`) rather than `_craftable()`'s index, which could point at another piece of
the same value (a flake seen once). Local smoke clean twice.

**The Steam Deck's screen (8 Oct, Matt: "the lower part of the screen is unclickable - anything from
fence down").** The project asks for a 1920 × 1080 window, "maximized"; the Deck under gamescope has a
1280 × 800 screen and no window manager to maximize into, so the window stayed 1920 × 1080: the picture
is scaled to fit (everything renders), but the pointer stops at the screen's 800 px, which is canvas
y 800 of 1080 - the rail from the Fence (864) down. Reproduced here under a 1280 × 800 X screen with
the window forced to 1920 × 1080 (`tests/deck.gd`: Clinic, Fence and Radio past the window). The fix
(`main._fit_window_to_screen`, at `_ready`): a window bigger than its screen's usable rect is sized to
it through the Window node (so the canvas follows at once; `DisplayServer.window_set_size` left the
stretch at 1080 until an event that never came), and placed at the screen's origin; fullscreen modes
are left alone. The canvas then stretches to 1920 × 1200 as on any 16:10 screen and every rail row
ends inside the window. `tests/deck.gd` needs a display (a window to size): `xvfb-run -s "-screen 0
1280x800x24" godot --path . -s tests/deck.gd`, exit 1 on a row past the window; it is not in the
headless smoke. Also: the menu's dim is a plain ColorRect sized in `layout` (the anchored one warned
and sat at nothing); the add-words test pins its piece to the grid's first page by value (the flake
again - it had packed onto page two). Local smoke clean three times.

*The Legion's smoke on the pass (8 Oct):* one sweep misfit, the log's line before holding "One of them is
in the last Doorman's station helmet, visored." ten pixels over its box, which the explicit line-before
check in the same `_check_fit` did not flag; not reproduced here under a display or headless, nor by a
probe of that line against forty current-line widths. Two things done rather than guessed: the line
before is checked after its fit and blanked if the fitted form still does not fit (never trails off);
and a sweep error now names the label's chain (`_chain`: script and node names up five parents) so the
next one says which label it was. Found on the way: `show_camp_lost` opened its menu `opaque`, which
the new shapes read as the title (the column and the wordmark, the heading and the words hidden) - the
old menu hid them over the painting too. `open` takes `picture` now; the title alone passes it, the
lost camp is the card on the plain ground with "The Yard is lost" and its words up; the smoke opens it
and checks.

*The Deck, second cut (8 Oct, Matt: "still exactly the same").* The first cut's gate - "the window is
bigger than the screen" - never fires under gamescope, which reports no such thing. Greenhorn met this
and wrote it down (`game_manager.gd`, `_apply_native_window_size`): gamescope places the window at the
size it asks for, scales it to the panel, and reports the pointer in panel pixels, which the engine's
content-scale transform reads as the window's; the error is nil at the origin and grows down the
screen. Greenhorn's fix, now Fiat's: on Linux, ask for the window at `screen_get_size` unconditionally
and let the stretch do the rest. Linux only, as Greenhorn's is - its notes record an exported Windows
build under GL Compatibility segfaulting on any window-geometry change from script, and Windows never
has the bug. The Bench's jobs foot falls back through its words to their first word ("Added",
"Re-rolled") rather than the job's name, so it always says what was done. *The pck:* Fiat's Linux
export preset has Embed PCK off (`binary_format/embed_pck=false` in `export_presets.cfg`, untracked);
Greenhorn's has it on, which is why Greenhorn runs as one file on the Deck and Fiat wants the .pck
beside it.

*The Deck, third cut (8 Oct, Matt: still the same in game mode, fine in desktop mode - exactly as
Greenhorn was).* The second cut resized the window, but the project opens it maximized
(`window/size/mode=2`) and the X11 display server ignores a resize of a maximized window; Greenhorn's
project sets no mode, so its resize took. Now: on Linux the window goes windowed first, then to the
screen's size. Desktop mode was fine both times because a window manager fitted the window itself.
`tests/deck.gd` asks for the window maximized first, as the project does (under Xvfb, with no window
manager, that is not the proof the Deck is; the title's foot now reads the window and the canvas as
the game sees them - "FIAT · 1280×800 → 1920×1200" - so the Deck can say what it got).

*The Deck, fourth cut (8 Oct, the foot in game mode: "1920×1080 → 1920×1080").* So the window was
never resized because the screen the game was shown was already 1920 × 1080: gamescope follows a
window's requested mode, and the project's maximized 1920 × 1080 window had it set its own screen to
that; `screen_get_size` then equals the window and the fix has nothing to size to. Greenhorn's window
opens windowed, so its screen stays the panel's 1280 × 800 and the resize takes. `project.godot`:
`window/size/mode=2` → `window/size/mode.windows=2` (a feature override: Windows still opens
maximized; Linux opens windowed, the Greenhorn path, and `_fit_window_to_screen` sizes it to the
panel). Not provable here (no gamescope); the foot's line says what the Deck gets.
Confirmed on the Deck (Matt: "job done"). The whole of it - symptom, mechanism, fix, the four traps,
the test, the pck - is `docs/deck.md`, so it is not chased again.
*The wordmark on the Deck (same day):* missing in both modes while the Windows export and the editor
run had it. `_load_art` read the wordmark with `Image.load_from_file` on a globalized `res://` path,
which finds nothing inside a `.pck`; it reads the bytes through `FileAccess` now (a pack serves
those) and falls back to the imported resource. The smoke checks the wordmark loaded at 154 × 72
whenever the file exists. Noted in `docs/deck.md`.

**The Radio's buttons (9 Oct, the playtest list, item one: "the buttons flicker and sometimes catch a
click ... on hover the buttons flicker on/off consistently", on the Windows and Linux exports and in
the editor).** The Radio is the one room still drawn on the card grid, and `refresh` - ten times a
second - hid all eight cards and showed the used ones again. A hidden control drops its hover and any
press in progress, and a shown one gets no hover back until the mouse moves: a still pointer saw the
button flicker at the refresh rate, and a click landed only when its press and release fell between
two refreshes. The rail's Radio button is not on a card, which is why it worked. A probe across every
room found the Radio's buttons and the Runner room's one card button toggled; nothing else. The fix:
each card's visibility set once to where it ends up. The smoke (`_refresh_toggle_checks`): every room,
the Radio with a tier open and its buttons up, one refresh, and no showing button - nor any control
above it - may lose and regain its visibility. Watched up the chain because the smoke runs before the
tree has drawn: nothing reports visible in the tree there, and a hidden parent does not pass
`visibility_changed` on to its buttons (the first cut watched the buttons alone and saw nothing - its
own guard, "the Radio showed 0 card buttons", failed it on the Legion). Under that same condition it
fails on the old loop (the Runner's card button, the Radio's Build and New word) and passes on the fix;
it puts the room back after.

**The trees as lanes, the joints, a class change that costs, the camp's high-water mark (9 Oct, the playtest
list, item two; the spec is `docs/design/trees.md`, layout A on the canvas).** Matt: the element trees sat
behind one arrow under the core tree and "there's no real cohesion between skill points for the classes and
then the elemental ones"; a class click was a free respec; dying and re-levelling grew the points without end.
*Data:* every tree is six columns of two (`col`, `row` on each node; ids stay `Tree/index`); the `needs`
chains are gone. A column opens on the points spent in that tree, ⌈0.6 × the base cost of the columns before
it⌉ (`Data.gate`, `sim.points_in`); cost by column 1, 1, 2, 2, 3, a notable +1, a keystone +2; the capstone a
quarter of the rest, a class's half counted once. Ten joints (`Data.JOINTS`): a class tree's fourth-column
notable and a class-only notable in its element's tree; both trained by a runner of that class (or the second
past) close it; an element tree's last two columns work and train only with a joint closed there, the Yard's
trade of it, or the Quartermaster's Manual. The Doorman's physical half is new ("Hands on" in The door), and so
is Knuckles, the physical tree (Bust them up, Heavy, Flattened). *The payoffs* (`_joints_on_hit`,
`_joints_on_incoming`, `_joint_hit_mult`, `_dot_fill`, `_dose`, `phys_resist`, the kill's flags): the
Drifter's bursts ignite and a burning gang takes a quarter more from the SMG; a shocked kill's drop rolls its
rarity twice; every improvised hit shocks; a kill while it burns always drops and the Fence pays a fifth more;
the Poacher's first shot lands full poison, and every gang comes chilled and a head short; a med doses them
with poison; chilled, they do 30% less and meds heal a fifth more; a bleeding gang does a fifth less; shells
and swings stagger them 25% slower. *A class change* costs the respec of what it gives back - the old class's
trees, another class's half, an element off the new pair - and takes two presses ("Change to Poacher: £1,240
— press again"); free for a new runner; refused to the second past's class. *Points:* a level earns one only
above the camp's `best_level` (saved); this replaces level-locking gear. *Saves:* `tree_v`; an older save's
tree comes back as points once, its best level its runner's. *The Training screen* (`barracks.gd`, rewritten):
a header (the face, the class and trait, the points, the classes top right); five lanes - the class's first
tree, the element it joins, its second, that one's element, the Yard's - each a label block (name, whose, points
in and the next gate, trained) and the tiles by column, the capstone the lane's height; a link between a class
lane and its element in the fourth column, "⇄ JOINED · ..." or "⇄ OPEN · Petrol bomb and Drifter's can, one
half each"; the Also row (the off-pair elements, the second past's tree, the drawer and the shelf with their
counts) swaps the Yard's lane, the drawer and the shelf take the lanes' area as cards; the sum strip ends on
"Joints 1 of 2"; the strip under it gives the node's sentence, its joint and why it won't train yet. *The bot*
trains left to right, skips other classes' halves, takes the joint's class tree straight after its element,
and a second past whose first tree holds that element's half. *The smoke:* the gates by formula, points in one
tree opening nothing in another, every joint open on one half and closed on both for its class alone, every
payoff where it lives (the ignite never shrinks a burn already there - the reviewer's catch), off-pair
elements stopped at their joint, the second past closing its own, the lanes against the table for every
class, the Also chips each swapping the fifth lane and back, a change's price and presses and what it gives
back, the high-water mark, the old save refunded once. The reviewer also caught a change leaving an off-pair
element at double (points free below nothing), the physical bot crafting for a conversion that doesn't exist,
an armed change outliving a death, and the Joints count including a joint that can't close; its second
read caught the first of those fixes giving back the Yard's tree on a new runner's pick (a runner with no class
read every classless tree as theirs), and the second past's class offered as a change it would refuse. All
fixed, each with a check. *The sum strip after Matt's first look (option A):* the elements in play as chips
in their colours - the share of the hit the trees convert and the increase ("Fire 80% of hits · +52%"), cut
back together past the whole hit as the fight does - Physical when Knuckles or Hands on is in, and Dots (their
increase, a burn lasting twice as long, poison to fifteen, bleeds that don't fade); a plain figure at nothing
is left off. Too long for the row, the middle forms come first, then the plain figures but Damage and Max HP
go, then the shortest forms; an element's chip and the Joints are never dropped. The smoke checks no zero is
shown, every element the trees give is on the row (read off the screen), and a crowded strip (the Yard and
four elements at once) needs its fallbacks and keeps Damage, the four elements, Dots and the Joints last. The
reviewer caught a Physical chip reading "+0%" on a build with only the Doorman's knuckles, the nothing-fits
case dropping the Joints, the dots' "×2 long" reading the kit as well as the trees, and the first cut of the
checks reading the strip back from what they'd just laid themselves; all fixed. Then (Matt: "may as well be consistent")
the plain figures count every trained tree's notables and "also" figures too, as the fight reads them - Spray's
+25% with an SMG in hand, nothing without - where before they counted only the small nodes in the lanes.

**The Yard as lanes (9 Oct, the playtest list, item three; the spec is `docs/design/yard.md`, layout A on the
canvas).** Matt: "quickly unlocked most of them before I'd unlocked the third zone ... I still need yard upgrades
even when I'm 9 depths deep", and crafting shouldn't wait on the Bench. *Data:* the eight buildings' levels are
gone (`STASH_LEVELS` ... `KENNEL_LEVELS`, `WORKSHOP`); `Data.YARD` gives each a salvage kind, five columns of two
picks (one taken; the other stays on show) and a rank; columns open from the start, the Town, the City, the
campaign done, depth 6 held, depth 9 held (`YARD_GATES`) and stay open (`yard_open`, saved); a refit is half the
column's price; column 5 wants 10 salvage, a rank £50k × 1.25ⁿ and 5 + n salvage, all at today's prices. *Salvage*
(copper, safe steel, army surplus, one a zone): 1% a kill a depth past 3 on that zone's sites, home with the run,
lost with a death. *Crafting* is open from the first minute: every job, mount, socket, build tier and the cache
events; the Bench's lane makes it better (`roll_affix`'s top half, `reroll_one`'s no-down, a third socket, six-level
bumps, the gunsmith's level). *Every pick does something in the sim* - the Stash's free cells for racks, uniques
and papers (`stash_free`, `stash_fits` in every room check), the Bins on a run's commons, the Clinic's drip and
field kit, the Fence's stock, orders, back room, insurance desk, the Radio's Scanner, Tip line (`fresh_word_price`),
Pin, Two channels, Call in / Lock (now exclusive), Long range, Jammer and band, the Generator's hours, pouches,
overtime, floodlights, charger, the Lookout's gangs, glasses and flares, the Kennel's finds, fetch, tracker,
ratter - and the odds read them (`_yard_setting_off` in the dry run). *A move keeps the buildings,* picks, ranks,
columns and salvage. *Old saves:* each level becomes the matching pick, free, side A. *The screen*
(`yard_tree.gd`, rewritten): eight lanes like the trees - a label block, six columns, the rank tile - the purse
with the three salvages in their colours, Move the Yard in the header, and the strip naming the pick, its other
half, its price and Build / Refit; the rail badge lights when anything is buyable. The Bench, Clinic, Fence and
Radio cards read their picks ("3 of 5"). *The bot* builds the cheapest open pick (a few B sides set), keeps £500,
ranks at 1.5× their price. *The smoke:* the screen fits, build and refit, gates kept, every building's picks,
salvage at depth 8, ranks, the move, an old save. The reviewer's two reads caught a Fence pick re-rolling every
site's words, any build refilling a shelf bought from, Orders and Pin outliving a refit, the Tip line making
Lock free, the free cells missed in room checks, the Charger and the Field kit unseen by the odds, the Bins not
on the run's finds, the depth gates reading the selector rather than the depth held, Long range never rolling
its word, Floodlights missing a rolled Night, and the Insurance desk's deeds not ending the game; all fixed,
most with a check.
*Matt's five (same day):* old saves keep side A (refit at half); the bot counts one hour in three as away
(`AWAY_SHARE`, cleared in `tidy`) so Overtime and the Generator's rank pay, and takes Overtime over Battery; a
refit that takes cells is allowed and the strip says first how far over it leaves the stash
(`yard_refit_over`, amber); the column-5 gate reads "before the first campaign"; the rail's badge is news only
(`yard_news`: a column opened or something newly buyable since the Yard was last looked at; `yard_seen`, saved,
kept on a move, marked before the rail paints). The reviewer caught the runner being out stopping the Yard from
counting as seen, the move and old saves lighting the badge, the badge painted before the mark, the warning
hiding a refit's block, and the bot's between-run sales earning the away bonus; all fixed with checks. A smoke
flake fixed on the way: the Yard-pick check failed when the bot had built those picks first.

**Map juicing (9 Oct, the playtest list, item four; the spec is `docs/design/juicing.md`, Radio-J A and Map-L on
the canvas).** Matt: the Radio was "a ways off the PoE system of juicing a map with stupid modifiers for stupid
rewards"; no rerolled words on campaign sites; a note found in the wild should unlock a modifier; words crafted
from pools, in harmony with the map; the map screen in the trees' and the Yard's layout. Agreed: papers teach the
words, a site's words stay until changed, crafts in notes, the map as lanes. *Data:* `MODIFIERS` keeps only the
sky (Night, Rain, Fog); `WORDS` (33: four known when the depths open, fourteen taught by the plain papers, nine
zone words heard once a zone's site is cleared at depth 2, six deep ones from the deep papers - Rationed, Curfew,
Last bus, Foreclosure, Everyone's here, The Manager walks), each a bite and a pay at tier I; tiers I-III by depth
(2, 8, 15), a multiplier as m^1/1.75/2.5 (3.5 for Twist's IV); words a site 2/3/4 at depth 2/5/9; pools 40% the
zone's, 50% the general, 10% the deep; `CRAFTS` (Tune in, Broadcast, Retune, Hold, Call in, Clear, Twist) at notes
× depth; `INTEL_CASH`, `OPEN_CHANNEL_NOTES`, `JUICE_*` gone. *Sim:* `words[i]` ([{w, t}]) and `sealed[i]` replace
`intel` and `pinned`; nothing re-rolls after a run; `juiceable` (the campaign done, depth 2 up); `active_words`
(the site's first `max_words`, at the tier the depth allows now, and the standing words); `word_effect` (the
Jammer roots the bite, the band, the Radio's rank and the map's Booster grow the pay); the flags in the run
(Rationed's no meds, Overdrawn's no cash off kills or the head, Last bus's clock, Pawned's armour through
`incoming_rate`, The Manager walks' free head); a paper read logs the word it teaches. *The map* as three lanes
(`ATLAS_GATES` 0/2/4/7/10/14 points in the lane), the air rebuilt as the juicing tree (Good reception, Clear air,
Booster, Held frequency, Long wave, Tip-offs, Strong signal, Early word, Relay, Bent, the whole band); Fair
weather, Night eyes, the forecast and Dead air moved to the Yard's Radio, whose lane is now Weather set / Night
set, the forecast / Dead air, Scanner / Two channels, Lorry watch / Long range, Jammer / Military band; an old
save's dropped nodes give their points back. *Screens:* the Radio (`radio.gd`): the sites with ladders down the
left (pips by tier, the pay line), the picked site's totals, its words a row each, the seven crafts with prices
and a hover line, the book with the unheard words named by what teaches them and the standing word and filter
buttons; before the depths, "Nothing on the air". The Runs card's word chips carry their tier. The map
(`atlas.gd`) as lanes. A paper's card says the word it teaches. *The bot* broadcasts and tunes the site it runs,
clears one that reads under even odds, sets the standing words and the filter. *The smoke:* a new
`_radio_juice_checks` (campaign plain, the book, depth's words and tiers, the pools, the seven crafts and their
blocks, Twist's outcomes and the seal, the flags, the save, the screen) and every check that read the old
words, the map's chains and the Radio's cards rewritten. The reviewer caught no fit check on the Radio screen at
all, Clear air's filter outliving a map reset, a site run shallow working all its words, the screen showing six
of eight, the totals leaving out searches/armour/resists/types, the deploy button greyed under a free walking
head, meds lit under Rationed, and the walking head scaled by the words; all fixed, with checks. Two smoke flakes
the change exposed (a test deploying to `best_tier` with its zone shut, the band's tone with zone 1 shut) are
guarded.

**The Fence's contracts (9 Oct, the playtest list, item five; the spec is `docs/design/contracts.md`, Deals-A on
the canvas).** Matt: turning contracts down until "20k cash for a rare primary" turns up is the abuse; the same
four uniques get old; "remove unique from the pool and keep it to currency only". Agreed: one free turn-down a
run then notes doubling, cash/notes/scrap/salvage only, pay sized by income, new kinds of ask. *Data:*
`CONTRACT_KINDS` (gear 50%, deep gear, an affix, papers, meds 12.5% each), `CONTRACT_PAYS` (cash 40, notes 25,
scrap 20, salvage 15), `CONTRACT_PASS_NOTES` 5, `CONTRACTS_MAX` 5; the unique and material odds gone. *Sim:*
`roll_contract` by kind, `contract_weight` (gear count × rarity, deep 3 a piece, an affix 3, papers 1, meds ½),
`_price_contract` (cash half a run's takings × the weight held to 4 - two runs at most - never for meds; notes
and scrap × (1 + the deepest depth / 5); salvage only from zones dug to depth 4), `contract_fits` by kind (never a
unique or set piece), `pass_cost`/`can_pass_contract` (`passes`, saved, reset on a run home), contract cash paid
straight in so it doesn't feed the takings that price the next; an old save's contracts rolled again. A deep ask
only once the deepest site's level allows one. *The tab* (`vendor.gd`): a strip (open, ready, the next
turn-down's price), a row a contract - five with Orders, where only three rows were ever drawn - the kind and
what you have, the ask, the Fence's line (shorter lines of his before none), the pay as a chip in its
currency's colour, Turn it down with its price, Hand in; the mate under. The rail's Unique badge goes. *The
bot* hands in meds and papers asks. *The smoke:* the kinds and pays rolled, the amounts by formula, every slot
alike, salvage from its depth, each kind's fit, the turn-down's price and its reset, the save and an old save,
five rows, every slot × affix named on its row with the Fence's line never blank. The reviewer caught contract
cash compounding through the takings, affix asks unreadable (two armours, "of damage as fire"), a reload
resetting the turn-downs, the bot skipping meds and papers, and the Fence's line going blank; all fixed, with
checks.

**Run timers (9 Oct, the playtest list, item six; the spec is `docs/design/timers.md`, Clock-A on the canvas).**
Matt: a count-up clock lets a 0% site be face-tanked on meds and luck; a countdown that stops while the site is
clear, a loss if it runs out, "same as other extraction games", a DPS check. Agreed: out of time the runner lives,
the pack goes and two random pieces of worn kit with it; the budget is a reference DPS check, the same for every
build; nothing buys more time yet. *Data:* `CLOCK_BASE` 60 s, `CLOCK_PER_HEAD` 12 s, `CLOCK_GANGS` 5,
`CLOCK_LOSE_KIT` 2, `CLOCK_WARN` 0.2. *Sim:* `clock_budget` reads the site as plain (`plain_pool`/`plain_hp`,
recorded before the words and the head form) - base + 12 s × (pool + 5); Last bus halves it in place of its
forced extract; a head brings `clock_for_head` (12 s per plain head's worth of his HP), a convoy 12 s a truck.
`_tick` runs the clock only while heads remain; `_time_out`: the dry runs count it a loss (`prof.dry_timeouts`);
a real run stops the auto-run, loses two worn pieces (to the stash if insured; a lost rig takes its pouches),
hands out the new-runner hand-me-downs (and nails) for a lost gun, armour, bag or rig - a time-out never leaves
fists against the next clock - keeps the deeds, the Kennel's Fetch carries the best of the rest straight to the
stash, the Insurance desk keeps the pack; "Out of time" in the report, no Ghost clear or The lot on it. Old
saves' runs get the site's clock on load. *The run* (`run.gd`): the band's headline is the clock ("1:24 left ·
ticks while they're on you" / "stopped while it's clear"), a bar draining under the kills, amber in the last
fifth, red under ten seconds; "X in · clock Y" in the corner. *The Runs card:* "Fight · clock", "0:52 of 1:40",
red when the estimate is over the clock. *Balance:* probes at 20/8 timed the early game out; 60/12 is twice the
bot's median 6 s a head (Poacher 9 h: 4 time-outs in 224 runs). The gate (chosen sites time out under one run in
twenty, two depths past the climb over half) needs the bot to report real time-outs - for the balance pass.
*The smoke:* the budget and a head's time, ticking only in a fight, the headline and its stopped form, out of time
(runner home, exactly two slots changed, a gun after, the line), insured kit to the stash, a dry run on fists
timing out, the Runs card's clock and its red. The reviewer caught the auto-run running on after a time-out, the
deeds lost to it, the hand-me-downs handed out before the second loss, old saves' runs, the convoy's time, the
head's time read after the words, a Ghost run clearing on a kept pack, and Fetch going through the stash's room;
all fixed, with checks where testable.

**The rooms renamed, the old Bench menu gone, place art wired (9 Oct, the playtest's UI list).** Matt: "I click
runner expecting to see my loadout and gear but that's actually under lockup." The loadout room is **Runner**
(was the Lock-up), the runner's sheet is **Stats** (was Runner), the Bench is the **Workshop**; the rail runs
the Yard, Stats, Runner, Runs, Training, Workshop, Clinic, the Fence, Radio. Rooms only: the Yard's Lock-up
and Bench keep their names as buildings; lines that send you to a room name the new one ("fit one in Runner",
"Fitted in the Workshop", "1 open in the Workshop"). The rail's glyph follows the name: Stats wants
`art/ui/stats.png` (not painted; an empty stamp till then - the fit check counts a glyph named but unpainted
as an art gap, not a failure). *The old menu:* `_open_bench`/`_picks`/`_one` are gone; the Runner room's
button on a piece is **Workshop** and opens the Workshop on it - Craft with the piece picked, worn pieces too
(the Workshop finds a picked id in the kit; Scrap is hollow on a worn piece), a part or a socketable on the
Guns or Sockets view with its mount picked. *Place art:* `UI.place_texture` reads `art/places/<slug>.png`; a
site's band (the Runs card, behind the run's clock) shows it covering the band under a shade, the skyline when
there's none; a zone's tab shows its art under a dark glass, ringed in the accent when picked. Matt is painting
the Estate and Ransacked Streets first. *The smoke:* the rail's names, order and rooms; the Workshop button on
a stash piece, a worn gun (a job on it takes, no scrap) and a part; place art in a band and behind a tab, and
the tab back to plain without it. The reviewer caught the button sending a part to Craft; fixed, with a check.
Raised, then fixed on Matt's word: a job on a worn piece clears the odds' cache (a resist-only re-roll had kept
the old odds), with a check; the Workshop's foot and the craft and build log lines say the Workshop, not the
Bench. *The first place art* (Matt, 688×296, the generator's limit): `art/places/the_estate.png` and
`ransacked_streets.png` - covering the 608 and 501 bands and the 372×56 tab, smoothed when scaled down,
crisp when scaled up. Seen once locally and not since (two clean runs after): the Manager's Pen and the
Lorry's Load notes checks reading double or single - a notes-doubling flake to chase in the balance pass.

**The balance pass (9 Oct, the twenty-fifth to twenty-ninth reads, five a build from the twenty-eighth).** Seven
red on the twenty-fifth; Matt's calls, a pass each: the bot saves for the Radio's Lorry watch and stops
re-broadcasting a site whose words it cleared (a plain Drifter looped 270 times, never bought the pick, never
beat the lorry); the Drifter's −15% max HP went, then its +15% damage to +5% (with its HP back it was first to the
Bank at 0.6 h); the Poacher's −10% max HP went; the Paramedic +10% damage; the Scrapper's loot +15% to +10% and
its scrap band to 8; bleed's early tree lifted (Sharpened conv 35, Butcher's to +20% bleed, An edge 25, Deep 20)
and its keystone and capstone two points under their column (`cost_less`, Data.base_cost); frost's capstone
one under; fire's A can of it 30 to 20 (the smoke's fire total 70%). The summary: time-outs merge only where
read, the Clock row green on every pass (every build under 1%). *The twenty-ninth (the last before the
playtest):* green on loot, quantity, cash, depth pace, the ladders, the clock, scrap, no reds; the element
builds' band 1.1-1.7 h. Red: the classes' band 1.3-3.0 h (the plain Poacher's median 3.0, its five reads
1.4-4.1); the keystone (the bleed Doorman 3.1 h, the poison Poacher 2.2); the capstone (the frost Poacher 5.5);
the lorry (the plain Poacher 21.7 h, never on two of five; the plain Drifter never on two of five at +5%).
The Poacher was not touched on the last pass and read 1.8 h and green on the lorry the pass before: the plain
builds swing more than the changes move them. *Wounds and deaths* wait on Matt's playtest of this build
(Matt: "so much has changed that it's not worth looking at my previous save"): the old save's 7 in 116 is
retired and both rows read "waiting on the playtest", an accepted red till then. *Open for the pass after the
playtest:* the plain Poacher's and Drifter's lorry and the bank band, the element keystones; the playtest's
save fills wounds and deaths. Passes kept in `docs/balance/pass25`-`pass29`.

**Training as glyphs, and the Clinic's, the Fence's and the Map's art (9 Oct, Tree-G A on the canvas).** Matt: the
tree "is displaying boxes of text rather than small boxes with a glyph". A node is a 44 px tile with a line glyph
for its effect (`node_glyphs.gd`: SVG drawn by the engine, cached, tinted; damage, armour, HP, each element, a
bag, a search, the clock...; a star where none fits), centred in its column (`node_rect`): a notable round, a
keystone a diamond (the button turned 45°), the capstone a bigger diamond on its lane; trained filled in the
tree's tone, trainable white, locked dim, the picked one ringed white; the cost a chip beside its corner (a tick
once trained), a joint's half ⇄ at its left; two faint rails a lane. The words are the panel's. The drawer's and
the shelf's cards keep their look (`_style_card`). The Clinic's and the Fence's bands read `the_clinic.png` and
`the_fence.png`, the Map's `the_map.png` (all painted, the manifest's last three jobs); the face's check skips
the band's backdrop. *The smoke:* a glyph and no words on every node, centred in its column, its cost chip on
the lane, the diamonds' true extent in the overlap check, the capstone centred on its lane; the bands' places
and the Fence's face clear over painted art. The reviewer's catches: the drawer's cards had changed look, the ⇄
mark and the diamonds' extent weren't in the checks; fixed. The Legion's first run with the art caught the face
check counting the backdrop; fixed with a check.

**Deep bases: tiers 7-9 on every slot a runner wears (10 Oct, Guns-D, docs/design/deep_guns.md).** Matt: "a 100dps
SMG at the bank" and nothing past it; agreed, new bases at depth, the campaign as it is; then "complement them with
other gear types". 42 bases: three a gun line (the SMGs to 192/s, rifles 180, shotguns 189, improvised 180, melee
180, pistols 93, machine pistols 120) and helmets, armour (the resist lines carried on), rigs, packs and charms.
`Data.CAMPAIGN_TIER` 6 is the campaign's top, `MAX_TIER` 9; a site's tier steps at level 12, 16 and 20
(`DEEP_TIER_LEVELS`: the Barracks at depth 4, 8, 12); a campaign site's "a tier up" (Local knowledge, a word, a
cache, the ledger) stops at 6 (`loot_cap`). The Arms dealer stocks them at your depth; the Workshop builds a deep
improvised gun once a site drops its tier. Words for each; `tools/make_item_manifests.py` prompts them and
`tools/pixellab_items_new_manifest.json` is their 42 jobs (every other item already has its art); the script's
unique lookup is case-blind now (it had stopped on "Grandad's Shotgun"). *The smoke:* the tiers by level, the
cap, a base at each deep tier on every slot with words and a footprint, campaign rolls never deep, each gun
line climbing, the campaign's gun builds at 6 and the deep ones at depth; the campaign checks (the SMG line,
the bases by level) scoped to the campaign. The reviewer's catches: the Workshop offered the deep improvised
guns from the first hour; a shop's unique took its level from a deep throwaway base; both fixed with checks.

**The way out (10 Oct, Run-P B, docs/design/way_out.md).** Matt: an early leave "should cost something - maybe its
own timer and a gang you have to see off". Get out now before the clear is the way out: the gangs on you left
behind (a head with them), one last gang of the site's own at the door (the first post-clear gang's size: Trapline,
Flares, the snare shrink it; the Radio's words on it), and `WAY_OUT_S` 20 s + 2 a site along (Matt: it grows with
the tier), never past the run's clock. Seen off: home with the pack. Out of time: a time-out as the clock has it.
Down: a death. After the clear it's free and at once, as before. The band's headline is the way out counting down
in amber, the fight box the door's gang, the button "Getting out · 0:14"; before the clear the button says its price.
The bot presses it as a player would (`get_out`); `extract_now` stays the tools' instant leave. *The smoke:* the
price, the door's gang, the time and its cap, seen off, out of time, a second press, free after the clear, a Ghost's
first gang, a head left behind, a save and load mid way out, the price following the clock. The reviewer's catches:
a Ghost's run left for free; the button's redraw ran every second through the pick panel; the price went stale
under the clock; Stand and fight showed a price it never charged; all fixed, the gaps tested.

**Faces beside the run's boxes (10 Oct, Run-P A, docs/design/faces_and_bands.md 1).** Matt: the Carpet Man's art sat
over the fight box; "make the stat boxes smaller ... profile picture to the left ... both the enemy and you", the
gangs' faces from Greenhorn. A 92 px face at each box's left, the four tiles and the bar narrowed to its right,
neither box taller: the head's portrait while he's out, else the zone's gang (`art/people/gang_the_estate.png`,
`gang_the_town.png`, `gang_the_city.png`: Matt's to drop in), else a drawn figure; the runner's class portrait. The
head's name joins the kicker ("THE FIGHT · THE CARPET MAN"); the old floating face is gone; the fight's numbers
scatter over the narrowed bar. Tile words that no longer fit the narrower tiles: "Gangs", "held" for "on the call",
"Door". *The smoke:* each face in its box and its frame, clear of the head, tiles, bar, key, chips and note, art
or the drawn figure and never neither, the class's and the zone's art followed, the head's name in the kicker. The
reviewer's catches: the runner's face ran 2 px into its head; the faces scaled down with nearest filtering; both
fixed (92 px, linear). Found on the way and fixed with a check (Matt to know): the Lock-up's rig pick said "Feeds
the hand-me-down nail gun and the flare pistol", past its panel - two guns now read "Feeds both guns".

**The purse on the top bar (10 Oct, Bar-C, docs/design/faces_and_bands.md 2).** Matt: scrap and the other currencies
on the bar. Right-justified from the cash: the place, notes, scrap, then copper, safe steel and army surplus once
there's any of each (the campaign reads notes and scrap), each a line glyph in its own tone drawn by the engine
(`node_glyphs.gd`), a tooltip on each. The purse lays out by its figures as they read; where it would reach the
HP, XP and damage it tightens - the place without "Out:", the salvage closer, the place to its glyph (the tooltip
keeps the words), every gap closer. *The smoke:* in every fit check, the purse in order, each glyph before its
figure and clear of the next, the lot clear of the runner's figures; the campaign's purse, one kind joining, every
currency at its worst out on a run. The reviewer's catches: the place's glyph ignored the mouse, so its tooltip
never showed; the figures' boxes were as wide as their worst and put their tooltips over their neighbours; scrap's
worst was 99,999; fixed, with checks.

**The Stats room as a sheet (10 Oct, Stats-R A, docs/design/faces_and_bands.md 5).** Matt: the one room that "reads like
a sample Godot project"; keep the information. `scripts/ui/stats_room.gd`: a 96 px band (`Band.compact()`: the title
and the headline on one row; the runner's face, the damage in gold; `the_stats.png` once painted) over three rows -
the runner (level, XP, the class, trait and wound as chips, pace, pack and rig, runs, alive, the deepest hold, kit
worth), attack and defence as the tall cards, finds, the record and the last run, and the wall along the foot.
Attack draws `Sim.damage_parts()` - dps()'s own parts in its order - as a chain of bars from the guns to the total,
the elements as one split bar and chips; defence the resists as bars against the cap, red where the open sites fire
an element you have none of; finds as bars; the record as four tiles; the last run with an edge in its outcome's tone
(a time-out amber); the wall as the runners' plates, newest first, a lost one's face greyed. The Kit card's slot
list went (the Runner room has the kit); its worth is in the runner's rows. The card grid now shows for no room.
*The smoke:* the sheet's geometry (parts in the room and apart, every piece in its part, the band's words in the
band, title and headline apart), its fit, the old card checks rewritten against it, the parts making dps(), the XP
after a move, a time-out's last run. The reviewer's catches: the chain used a formula of its own (the Past bar could
pass the total); the XP read below nought after a Yard move (the banked paragon); a time-out showed as a success;
fixed with checks. The growth check now holds the runner over half HP (the under-half damage rode on it). Open for
Matt: the top bar's XP figure has the same banked-paragon flaw after a move (not touched).

**A backdrop behind the runner (10 Oct, Kit-B A with B under it, docs/design/faces_and_bands.md 6).** Matt: "a semi
transparent backdrop ... behind the character model / gear slot selection". Under the Runner room's figure and its
slots, in a hairline frame: `art/places/the_kit_room.png` at 40% with a vignette (the rooms manifest's sixth job),
the slots as glass (an empty slot's fill, or the item's cell, at 80%: one layer, so a fifth of the wall shows); while
the art is missing, a cone of cold light from above and a shadow at the feet, drawn. The flat figure (no body art)
has its own layer over both. *The smoke:* the layers' order and that none takes the mouse, each slot one layer of
glass, the slots inside the frame, the art followed, a stand-in painted backdrop's fit. The reviewer's catches: a
filled slot was two glass layers and nearly solid; the flat figure would have sat under the wall; fixed, with checks.

**The Yard in the tree's glyphs (10 Oct, Lanes-G, docs/design/faces_and_bands.md 3).** Matt: the Yard and the map
"look really bad now" beside Training. Each building a 64 px lane: its name, picks and rank, its salvage; each
column's two picks as 48 px glyph tiles side by side (built gold, its other dim, buyable white, shut dimmer, the
picked one ringed), the column's price beside them (the first shut column says what opens it); the rank a star
tile with its figure, price and five pips. A pick's name and words are its tooltip and the strip's; every pick has
its own glyph (`NodeGlyphs.PICK_GLYPH`), no column's two alike. The strip sits under the lanes at its own height,
its button level with its title. *The smoke:* every tile in its lane with a glyph, none on another, prices and the
rank's words in the lane and off the tiles; every pick its own drawn glyph and no pair alike; the strip in the room.
The reviewer's catches: the strip had grown to the rest of the room, its words at the top and its button adrift;
the keyword rules gave nine pairs one glyph and some odd ones; fixed. The fists check now drops the secondary too
(a good secondary had taken the streets in time).

**The map in the tree's glyphs (10 Oct, Lanes-G, docs/design/faces_and_bands.md 3).** The map's nodes as 52 px glyph
tiles (`NodeGlyphs.ATLAS_GLYPH`, each its own) in their columns, two rows a lane; the shapes say what a node is, as
on Training - a notable round, a keystone a diamond (turned 45°, its glyph upright), the rest square; the ranks as
pips under a node of two ranks or more; taken gold, open white, locked dim, the picked one ringed. The words are the
panel's and the tooltip's. *The smoke:* a glyph on every node, roundness following notable, the diamond following
keystone, every node and its pips inside its lane, the keystone a diamond in the lane's last column. The reviewer's
catches: the second row's pips hung below the lane; keystones and notables had lost their marks (round meant one
rank); two glyphs read wrong (Open ground's crowd, Wages' star); fixed, with checks. The smoke on the way caught the
way out's price running past the half-width button on an auto-run ("Get out · 0:20, a gang"): it now takes the
longest form that fits.

**The rooms' bands (10 Oct, Rooms-B, docs/design/faces_and_bands.md 4).** Matt: replicate the Clinic's and the Fence's
art for every other room. Training, the Workshop, the Radio and the Yard take their painted places under their
headings (`UI.head_art`: `the_caravan`, `the_workshop`, `the_radio`, `the_yard`; the rooms manifest), covering
each from the centre inside its line, shaded from the left, the words with a shadow; the plain card until the file
is there. Stats has its short band (`the_stats`). Each heading kept its height and layout. *The smoke:* each band
names its place, follows its file, sits under the words inside the line, filters by its true scale, a stand-in's
fit, the shadows gone on the plain card. The reviewer's catches: nearest filtering at a 2.23x scale; the art
covered the heading's line; shadows stayed on the plain card; fixed with checks. Open for Matt: at these heights
only the middle sixth of a 688x296 painting shows - paint the room art as wide strips, or take taller headings.
The way out's seen-off checks now wait past a melee runner's first swing (one run's melee primary missed it in a second).

**Matt's notes on the pass (10 Oct).** Training's node panel: the sentence under the title over two lines (the room
the title left), and never "wants 1 point" - the cost is the tree's and the button's to say, the button off without a
point. The Workshop's heading says "The Workshop" (it still said the Bench). The top bar's XP is this runner's own
after a move (it counted the banked paragon and went below nought). The Runner room's backdrop is the drawn light
alone (Matt: it "will look better"); the kit-room job left the rooms manifest. *The smoke:* the sentence under the
title, clear of the buttons, never the points; every node's sentence in two lines at 430 px (four buttons late on);
the Workshop's heading; the top bar's XP after a move; the backdrop with nothing painted on it. The reviewer's catch:
four buttons late on left a one-line sentence ~430 px and long ones fell to nothing; two lines now, with the check.

**The Yard's tall heading (10 Oct).** Matt: the Yard is the one room the painted place doesn't suit, and it has
room to spare at the foot. The eight lanes and the strip move down to the room's foot and the heading takes the
space made (`HEAD_H` from `ROOM_H`, the lanes and the strip: 270 px), so the painting shows nearly whole; *Move the
Yard* sits at the band's foot and the purse chips take the width it left. *The smoke:* the heading's height from the
constants, the lanes and strip at the room's foot, nothing below the room, Move inside the band, the chips clear of
it. The way out's button text now fits the button less its padding (48 px).

**Training's gates (10 Oct, Tree-J B).** Matt: the joined halves sat a row apart, and nothing said the next
column needs points from the one before. Each lane's two rails become curves from a column's rows into a numbered
gate between the columns and out to the next: the disc shows the points in that tree the column needs, filled and in
the tree's tone once reached. The lane's label says "N points in". A joint's half takes the row by the line that
joins its two lanes (the upper lane's bottom row, the lower's top), so the two halves face each other across it.
*The smoke:* a gate between each two columns, its number the tree's gate and lit once reached, inside the lane and on
no tile, cost chip or ⇄; the joint halves at the line, for every class with a second past that shares its element
trees; no rail into a ⇄. The reviewer's catches: with a second past, the other class's half in the element tree's
joint column could take the line; the rail into a joint half ran through its ⇄; fixed, with checks.

**The purse's painted glyphs (10 Oct).** Matt: a manifest for the currency glyphs on the top bar.
`tools/pixellab_ui_purse_manifest.json` has four jobs, `art/ui/scrap`, `copper`, `steel` and `army`, in the UI icons'
style; the top bar takes the painted file once it's there (tinted if it's a line drawing) and the drawn glyph until
then. *The smoke:* both cases.

**The thirtieth read (10 Oct, after the deep bases and the way out; fifty reads, five a build).** Matt: balance with
the accepted reds before the playtest. Green: loot, quantity, the cash sink, depth pace, **the lorry** (every build by
9.0 h; red on the last read), the ladders, the clock (every build under 1%, the way out included), scrap, no reds.
The deep bases drop (13 of the fifty end kits carry one) and nothing they touch went red. Red, as on the twenty-ninth:
the classes' band 1.2-2.8 h (the plain Poacher's five reads 0.8-3.9 again: the swing, not a lever), the keystone (the
bleed Doorman 2.4 h, the frost and poison Poachers 2.1), the capstone (the frost Poacher 6.6 h). These were left
for the pass after the playtest; wounds and deaths stay accepted reds until his save fills them. Kept in
`docs/balance/pass30`.

**The Yard's purse down the left; upgrades; papers read (10 Oct).** Matt: the Yard's chips cluttered the art across
the top - they go down the left under the title, up to three rows in its width, on the band's shaded side. The
Yard's buildings' choices are "upgrades" wherever a player reads them (the Yard's and the Workshop's "upgrades built",
the Bench's line, the Clinic's tile); the code keeps `yard_picks`. Papers are read on pickup and their word goes to
the Radio, so a read paper now says so: the Lock-up's line reads "read · the Radio knows <word>" (unread still
"teaches"), and the Lock-up and the Fence's stash say "Read: safe to sell, the word stays", or "Works from the stash:
keep it" for a paper with a rule (`Items.paper_keep`). *The smoke:* the purse under the headline, in the title's
width and the band, clear of Move, all six chips at the largest figures; a paper unread, then read, then a rule
paper. The reviewer's catches: the worst case left notes and scrap small; the Fence said "safe to sell" of a paper
on its own shelf; fixed.

**One art band on every room (10 Oct, Bands-U A on the canvas).** Matt: the Yard's band works; Stats, Training, the
Workshop and the Radio want more of their art, and the Clinic and the Fence want the same band as everywhere else
(the Runner and Runs stay). Every one of those rooms now has a 180 px band (`Pal.BAND_H`; the Yard keeps 270) laid
as the Yard's: the room in the kicker, its figure in gold under it, chips down the shaded left, a face where the
room has one (128 px), the room's buttons at the band's foot, right. `Band.room_band()` gives Stats and the vendors
that layout (the art shaded from the left, no title line). Paid for from each room's spare: Stats' rows 28 → 24 and
its cards 32-34 px shorter; Training's lanes 104 → 100 (the tiles keep 44) and its "Add up to" strip moved into the
band under the points, the class's line over the classes; the Workshop's grid four rows a page; the Radio's site rows
82 → 74 and its detail 36 px shorter; the Clinic and the Fence lose the side band - the face, the name and the figure
go into the full band, the tabs to its foot, the side column under it, the grid four rows a page, and the word and
the contracts take the whole right column (the pick panel hides there). *The smoke:* each room's band at the one
height, its words, chips and buttons in their places and apart; the heaviest Training sum (every element, a second
past) keeps every element and the Joints; the Radio's book rows apart. The reviewer's catches: the sum's room in
the band unproven at its heaviest; three Stats labels touching; the book's rows with no slack; fixed or checked.

**Two tidies before the playtest (10 Oct).** The smoke's damage-line check flaked when a fight landed about the
sheet's figure (the line barely moves there): it now reads the exact place the line eases to - the Yard's share
scaled by landed over the sheet's figure - within 0.005. The Workshop's Upgrade button, hidden since the Bench's
levels went to the Yard and sitting behind the views since the band, is gone.

**The Runner room as the loadout (10 Oct, Runner-R A, docs/design/runner_room.md).** Matt: the Runner is now the
worst-looking screen. A runner strip over the column (face, level, HP and its bar, damage, armour, pace, cells);
under it the figure on the painted kit room again (Matt: "add the art we have for that screen back in"), seven
glass cards of one size in his order - the weapons, the charm and what's worn on the left, the helmet over the
armour, the rig and the pack on the right - each naming its slot, the item and its one figure, edged in its
rarity; a long gun lies across its card. *The smoke:* the cards glass, named, on their side and off the figure, in
order, their words the item's, no picture a sliver; the worn card, the strip, the column inside the room; the kit
room's art following its file. The reviewer's catches: a rifle in a 56 px cell was a sliver; the cards' figures,
edge and worth went stale when worn kit changed in place; fixed with checks. Open: a full 24-pouch rig of
multi-cell kits wrapped a fourth row and pushed the pack out of the room - fixed, the next entry.

**The rig and the pack stay in the room (10 Oct).** Found reviewing the loadout: a full rig of wide kits wrapped a
fourth row and a deep pack ran out of the room. The rig's items are laid first, then the pouches take the biggest
size (64, 52, 44, 36, 28) that leaves the pack 16 px cells or more across the column's whole width (10 and 12 px as
the last resort). A small pouch shows its short word whichever way it's small. *The smoke:* the worst state with a
24-pouch rig that wraps and the deepest pack - the pack inside the room and readable, no pouch's words outside it.

**The loadout's art, loud (10 Oct).** Matt: the cards lost the gear's art - "the best thing about the previous
iteration was the art showing loud and proud"; make the boxes fit the gear. Each card is sized for its gear now (the
weapons' column 246 wide, the worn column 150; an armour or pack tall, a rig short, a helmet near square) and the
item's art fills it; the slot's name and the figure sit over the art with a shadow, the item's name in its tooltip.
*The smoke:* the art filling its card, no picture under 36 px tall, the captions drawn above it (the button check
lets a caption tagged over the art be).

**The pack's map goes; the loadout grows (10 Oct).** Matt: the pack's empty cells were never usable and never full
(a run's finds go to the stash) - remove them and give the room to the cards and the rig. The Lock-up's column is
the strip, the loadout (516 → 648: every card taller, the art bigger) and the rig (two rows of full pouches, three at
44 for a 24-pouch rig, smaller for a wrap). A shrunk pouch's count goes small ("2k" in the smallest). The pack's
size stays on the Backpack card and the strip. *The smoke:* the pack's map gone; the rig inside its room in every
state, the worst wrap (four-pouch kits among singles, rounds in the thousands) with its words inside its pouches.

**The loadout, tidied (10 Oct).** Matt: the backpack's words clipped its art; no words at the foot at all (the figure
is on the strip, in the panel and the tooltip); the charm smaller; his redrawn figure looked too small. The art sits
under the slot's name now, never under words; the charm's card 110 (the guns' 180 and 170); the figure's drawing is
cropped to what's drawn and scaled to fill the gap between the columns (his 131 × 390 drawn at about 192 × 572,
nearest, as the gear's art is). *The smoke:* the art clear of the slot's name, no foot words, the figure binding on
the gap, the charm under the primary.

**The loadout's last order (10 Oct).** Matt: the pack big over the primary and the secondary down the left; the
charm where the pack was, a little smaller; the worn card gone; the armour bigger with the room. The left column is
the pack (240), the primary (192), the secondary (184); the right the helmet (140), the armour (240), the rig (118),
the charm (110). *The smoke:* the order, no worn card, each column filling the loadout, each card on its side.

**A figure a class (10 Oct).** Matt drew the five pasts' figures (art/body_poacher, _doorman, _paramedic, _scrapper,
_drifter.png, from the prompts in docs/design/runner_room.md). The Runner room shows the runner's past's own,
art/body.png while one is missing, the flat silhouette with neither; it follows a change of past. Each is cropped and
fitted to the gap as before. *The smoke:* each past shows its own figure, filling the gap. The reviewer's catch:
with no art at all the figure re-set itself every refresh; fixed.

**The playtest record (11 Oct).** Matt: the save didn't log what a playtest needs. The sim keeps a record now
(sim.chronicle, design in docs/design/playtest_record.md): a line for every run (site, depth, outcome, time, kills,
cash, XP, HP lost, wounds, the clock, the way out, the kit's worth, damage and armour at the start), level, training
node, respec, class change, the second past, Yard pick and rank, first clears and new depths, bosses, the deeds, the
lorry, the move, retiring, the map, the bench's jobs, scrapping, the Fence's word, contracts, each first paper and
unique, every change of kit, heals and treatment, each session's away time, and a snapshot of the purse and the
runner every ten minutes at the game. Each line has the sim's time, the player's own time at the game (played_s,
the real seconds the game was open) and the wall clock. Dry runs write nothing. The lines go to a file beside the
save (user://fiat.record.jsonl), appended on each save, not into the save itself; a slot takes a copy, a new game
keeps the old record aside.
tools\playtest.bat (or docs\balance\playtest.flag through the watcher) reads a save into docs\balance\playtest.md:
the time, the milestones by played hours, the balance gates read from play against the bot's targets, the sites,
the half-hour curve, the spending, the kit. Old saves start with an empty record (Matt starts a new one). *The
smoke:* runs, levels, training, a Yard pick and a class change each write a line; a dry run writes none; ten
minutes played snapshots once; the move keeps the record; a save writes the lines to the file once and the save
doesn't grow; a slot carries the record out and back; a new game starts a fresh one; the read, from the files
through JSON, has every section. The reviewer's catches: the record in the save grew without limit and every
30-second autosave copied it (moved to the file); a hardcore death deleted it with the save (written first now);
the read untested on a save through JSON; the session line after the runs it settled; the Radio's notes unrecorded; then a save from the first build losing
its lines on load, a record that couldn't be moved aside (held open) mixed with the next game's, and the read silent
on a record running past the save's count.

**Three off the ideas list (11 Oct).** Matt, away for the day: items 2, 3 and 4, nothing linked, no numbers.
*Upgrade arrows*: a small ▲ on a green-ringed disc, top right of any spare that beats what's worn in its slot by the
slot's score (the compare's own "▲ Upgrade"; an empty slot takes anything) - in the stash, the pack, the Fence's
shelf and stash, the Workshop's; never on the body. A picture-less one-row cell's words drop 6 px clear of it.
*What came back*: a card over the Runs screen adding up every run since the player last pressed Seen - runs, cash,
XP, items, the level climbed, the dearest find (its cell, its worth, whether it beats what's worn, or worn, or sold)
and up to four firsts (a clear, a new depth, a head down, a unique, a paper, the deeds, the lorry; then "and N
more"); a death's cost in red; Seen at its head's right. It sits over the right-hand column (the left when the last
run came from the right), between the tiles and the buttons, so nothing under it can be pressed; not on the map.
A move keeps the tally and counts as a first. The tally is the sim's (came_back, in the save), so
away runs are on it when he's back. *Junk rules* in place of the junk toggle, on the Lock-up with nothing picked:
Sell: off / commons / to uncommon / to rare, and Keep: upgrades / upgrades and guns, body, bags or parts; the
panel says the rules in a line. Never an upgrade, never what the old junk run never took (rounds, meds, grenades,
papers, socketed parts, uniques, sets, the deeds, a built gun). An old save's toggle reads as commons. *The smoke:*
the sell and keep rules going round and fitting, what goes and what stays, the rules saved, an old save's toggle;
the arrow on the better piece alone, inside its cell, never on the body, gone once worn; the card after two runs,
its tiles, find, capped firsts and level, off the run's column, no button or note under it, inside the screen,
fitting, saved, kept by a move, put away by Seen, and no dry run on it. The reviewer's catches: a move wiped the
tally; the card sat over a column's buttons; the arrows worked out twice a cell a refresh.

**Better, tried on (11 Oct).** Matt: his Van's Spare (+18% damage, a T3 unique) read worse than a machine pistol,
and putting the pistol on cost him damage. "Better" was each piece's own score, alone: a damage % counted on that gun
only (it multiplies the whole of the damage), a secondary counted at full (it fires at a third behind a live
primary - the Van's Spare's rule is what lifts that), and no unique's rule, tree gun type or set seen. Now a piece is
tried on: put in its slot for a moment, every gun counted fed, the runner's figures read, put back (sim.compare,
fit_value). A gun is better when the runner's damage goes up; a body piece by its armour and half its max HP on the
runner's totals, bags and charms by their own score - and either way a piece that costs damage is a trade
("Sidegrade", no arrow), not an upgrade. The Lock-up's and the pack's verdict, the Fence's line, the stash arrow, the
junk rules' keep, Equip if better and the bot's shop all go by it; a gun's damage delta is the runner's with it on.
The answers are cached per piece until the kit changes (40 cells: 15 ms once, under 1 ms after). The bot wears what
the player would now, so its reads move; its gates wait on the playtest anyway. *The smoke:* the machine pistol over
the Van's Spare reads ▼ Downgrade with no arrow, the damage lost first in the deltas, junk to the rules, left alone by
Equip if better; the Van's Spare over the pistol the upgrade and taken; a riot suit over a stab vest better, and a
trade when the vest carried 30 damage %. The reviewer's catches: the bot's shop weighed a share against score units
(a build's gun) and blew an empty slot up to a hundredfold (now a share throughout, an empty slot 1.0); the bot's
sell loop tried every gun on for every stash item (fit_value cached with the verdicts); the cache missed the first
lot's clear.

**The try-on's cache through a run (11 Oct).** Matt asked what the try-on costs; answering it turned up that the
cache's key held the rig's stacks whole, rounds and all, so every shot of a run threw the answers away and the pack's
arrows were worked out again each refresh (about 6 ms a refresh with a 15-item pack). The key holds the grades of
rounds in the rig now (each stack with rounds left, by name) and how many things it holds, not the counts; and, from
the reviewer, the pack's fill on a run (armour a free cell), a run's bonus armour and the Yard (the Clinic's HP),
which it had missed before. *The smoke:* five seconds of a run's shooting spend rounds and leave the key as it was;
a med used changes it.

**The rig on a run (11 Oct).** Matt, three from play. *The best rounds first*: a gun fired the first stack of its
type in the rig, so Depot rounds put in behind plain ones did nothing until those ran out. It fires the best grade of
its type now, by the grade's worth (Rifle 40, Match 100, Salted 150, Depot 170), and the next best takes over when
that's spent (sim.feed_stack: the damage and the spending both read it). *Rig to pack*: tapping a stack of rounds in
the rig on a run picks it for the pick panel - firing now, waiting behind a better grade, or fired by no gun worn -
with Into the pack when there's a cell (a better gun's rounds need the pouch); a second tap lets go; meds and grenades
keep their one tap. *What a med heals*: the hover on a rig med says "+42 HP over 3 s", a med picked in the pack says
the same, both from the one figure the heal uses (med_heal); the log says what it healed after the max HP: "Bandage
used: +38 HP (112 of 140)". *The smoke:* the Depot rounds behind plain ones fire first and the plain take over; Into
the pack from the run screen, refused into a full pack, let go on a second tap; the hover, the pack's pick and the
log's figure against the heal; the words fit; rounds moved to the pack home to the rig with a full stash, not loot.
The reviewer's catches: rounds moved to the pack were counted as loot and, with the stash full, dropped at the gate
without a word (now home to the rig, or the stash, or a log line); a med could be stowed by the sim (rounds only);
a second stack of the same grade read "a better grade fires first".

**Three calls before the playtest (11 Oct).** Matt agreed all three. *A build's rounds first*: a grade carrying an
element the runner has trained into (any node of that element's tree) fires before a dearer grade - a frost build's
Salted rounds before Depot - then by worth (build_elements, read again as the tree grows). *A worn unique*: its rule
may be worth more than the figures show, so nothing reads as better than it without a quarter's gain on the slot's
figure for a gun or body piece (UNIQUE_MARGIN 0.25 - dropped the same day for guns and body pieces, see "A worn
unique gun, judged like any other"), and never for a bag or charm; an early unique is still outgrown, a near-match never takes the arrow or Equip if
better. *No rounds said*: a gun picked in the stash or the pack with no rounds for it in the rig says so under its
verdict (the try-on counts every gun fed). Also: the playtest read run on the Legion through the watcher for the first
time, on the old save - it reads it and says there's no record, as it should. *The smoke:* Depot first with no
element, Salted first for a frost build and Depot again with the tree gone; a piece a few percent over a worn unique
a sidegrade, a quarter over it the upgrade; the no-rounds line under a gun with none, fitting. The reviewer's
catches: the build's elements were read again only when the tree's size changed (a respec to the same count kept
the old build's rounds order); the secondary fired element rounds first though its grade is damage only (the
primary alone now); the no-rounds line was missing over an empty slot and lost under the no-room one (both now, on
one line); a bag's or charm's figure never sees a unique's rule, so over a worn unique one it's never the upgrade.

**A worn unique gun, judged like any other (11 Oct).** The balance pass after today's changes (16 h, two reads a
build) showed the Drifter's bot holding a T2 Van's Spare to hour 16 and its depths stalling. On the same dice with
and without the quarter's margin over a worn unique: services at depth 5 at 11.6 h against 3.4 h, the Bank 1.1 h
against 0.8 h. The try-on already counts a gun's or body piece's rule where it touches the damage or the armour (the
Van's Spare's full-damage secondary), so the margin only kept it past its time; Matt agreed it goes for guns and
body pieces. A worn unique bag or charm still never reads as beaten (their score never sees the rule). *The smoke:*
a pistol a few percent better on the runner's damage reads better than a worn Van's Spare.

**The bar's skull (11 Oct).** Matt asked whether a bar whose last stretch is all damage-over-time should finish
the enemy; no execute (a hidden buff to every dot build, and the carry nodes are the answer to the waste), but a
mark: a dark skull at the bar's left when what the dots still have to take off covers the HP left - on their bar,
and on yours (the bleed will have you unless something heals it). Shown only. The rest went to the ideas list: a
probe of how much dot damage the kills throw away, by build, then decide between keeping it, half carrying by
default, or an execute. *The smoke:* the skull with 110 of dots over 100 HP and not with 40, on yours with a bleed
past your HP and gone with none, and the fight unchanged.

**The pass judges the element builds (11 Oct).** Matt: every class has two elements; anyone playing without one
should expect it slow, so balancing around plain builds isn't worth it. tools\balance.bat runs the ten element
builds - every class on each of its affinities, the Scrapper's shock and fire, the Paramedic's poison and frost and
the Doorman's physical new - and every gate in summary.md reads those alone (the Bank's band within them only). The
five plain classes run at least 24 hours a read and sit on one row, the plain floor: every read beats the lorry by
hour 24 (each read, not the median - one read stuck is what it's there to catch). Thirty-one jobs, two reads a build
and the probe. A local 8-hour read of the physical Doorman: the Bank 1.1 h, the keystone 2.8 h, the capstone 7.9 h,
the lorry 4.0 h - the first figures for it.

**Three from Matt before the Deck (11 Oct).** *The Runner's cards*: the slot's name floats over its card, not
inside it - a picked slot read as two frames, the card's and the gear's cell inside it. A full card is the gear's
cell now, one frame: the pick's colour when picked, its rarity's otherwise (a common keeps the card's outline until
picked); an empty card is its outline. The smoke's idle check put a hard hat in the stash as junk with whatever helmet was worn; with
the junk rules keeping upgrades it read as an upgrade when the helmet was weaker and went on instead of to the
Fence (no junk line) - it wears a visored helmet first now. *The title*: the window-and-canvas line that settled the Deck's fix (8 Oct)
is gone; the foot reads the version, "FIAT · v0.1" (menu.gd's VERSION: the second number for each build Matt plays,
the first for a milestone). *The title painting*: a prompt at 688x384 in docs/design/faces_and_bands.md. *The
smoke:* every card's name over the card, a picked full card's one frame, an empty card's outline; the foot's
version.

**Uniques by tier, built (12 Oct, docs/design/uniques.md).** Matt asked for it built now and the numbers left to the
pass after his Poison Poacher save; the Deck's build is the playtest's, so nothing here reaches it. Every unique but
the paper has a band (levelling 1-4, core 4-7, chase 7-9; weights 10 / 4 / 1, `Data.UNIQUE_BAND_WEIGHT`) and a range.
It rolls at the find's loot tier held inside its range, on the best base of its slot at that tier (a gun's of its own
type; a helmet or armour without a resist built in): `Items.unique_body`, cached. A type with no base at the tier
(the melee secondary stops at the Cosh; no pistol at T5) takes its best below, lifted - part way to its next base up,
or past its top by the slot's curve (`it["lift"]` on `Items.dps`). A loose find drops only the uniques whose range
takes its tier (`sim.loose_at`, cached), the band's weight picking; a site's own, a head's, a pinnacle's and the
lorry's come at the find's tier, held in range, so a deep Carpet Man drops a better Van's Spare. The shops come at the
deepest tier dug (`shop_unique_tier`): the mate's offer carries its tier and prices by it (old offers roll at their
base's), the Back room sells an ungated one held in range, a gamble's unique is one whose range takes the tier or a
plain roll. The shelf keeps the best tier of each (`shelf_tier`, saved, kept through a move; an old save's filled
from what's owned) and the Caravan's shelf card says it. The nine build uniques open at depth 6 (from 12); the Scout
Leader's Whistle and the Traffic Warden's Hat are found anywhere. Four new, Matt's pick of the candidates: *the
Starting Pistol* (chase secondary: the secondary's first shot at each of them lands, triple - one shot through the
runner's whole damage chain), *the Miner's Lamp* (core helmet: searches take half as long), *the Paramedic's Bumbag*
(levelling rig: meds heal half again; one is used for you under 40%, as the Paramedic's are), *the Plumber's Belt*
(core rig: every status on them lasts twice as long - a dot's seconds, a chill's and a shock's, like the trees'
notables). Art: tools/pixellab_items_gap_uniques_manifest.json, the four at their bases' footprints. The reviewer's
catches, fixed before the smoke: a site's own base was left out of the bodies (gaps at T4 and T6), the mate's tier
dropped on a reload, a lifted T5 pistol outscored the T6, a gamble could hand a T7 unique to a T1 yard, the convoy
gave a damaged target a second opening shot, the shot skipped the runner's chain; and on the second pass, a T5 copy
on a rig that carries less than the T4's (the body is now the best figure at or under the tier, labelled the tier it
came at).

**Before the pass, from that list (12 Oct, Matt: "make any changes you can now").** *A unique's body keeps its family*:
a `body` hint on the unique narrows the bases it scales onto - Nan's Cardigan wears only what costs no pace (its rule
takes the armour anyway: the Ceramic plates to the Light plates, never the heavy suits), the Butcher's Steel only a
blade that bleeds a quarter or more (the Bayonet, the Rescue axe, lifted between and past). *The Plumber's Belt*: a
burn, a poison or a bleed on them builds twice as deep and drains at the same seconds (`dot_depth`), so it ticks twice
as hard and a quick kill loses nothing; chills and shocks still last twice as long. Its words say so. Left: a city
site at depth 2-5 drops no loose unique (it dropped only the four outgrown ungated ones before) - the pass's to read.

**Over the cap and Guard, built (12 Oct, Matt: "agreed across the board"; docs/design/over_the_cap.md, shields.md).**
*Over the cap*: `resist_raw` is a resist before the cap (less a Water cannon's soak on the run), `resist` caps it at
75, `over_cap` is what's past it to 50, and every point is +1% of that element in `increased` - everyone's. A notable
beside each element tree's capstone (Fireproof, Thermals, Immune, Rubber soles, Scar tissue: +20 resist, the point
counts twice); Knuckles' Thick-skinned (armour past 200, a tenth of it as physical, to +50%). The resists roll on the
rig too; a "-proofed" line a element (its resist and its damage, 5-20) on armour and helmets. The word "Water cannon"
(the city's, from depth 10): your resists down for the run. The Blue Plaque never goes over. The Stats sheet's resist
rows and the Runs card's chips say "+N" past the cap. *Guard*: a second bar over HP, their fire and what they left on
you off it first (`_take`), its cap a quarter of max HP; it lasts the run. The Paramedic's class line: healing past
full is Guard. Transfusion: Guard holds half your max HP and a med fills it (its overflow-as-armour went). Beside the
capstone: Overtime (Shifts: +50% cap, meds faster with Guard up), Squared up (The door: 15% at every gang, the head
included), In the hide (Stalking: 15% at the first of a gang down), Sheet metal (Stripping: 6% a cache searched),
Breather (Moving on: a tenth of the cap a second with no one on you). Lines: Guard every gang (armour, helmet), Guard
holds more (rig, armour), a med's overflow as Guard. The run screen's HP bar carries a steel band (Guard over max
HP), the top bar "+N", the log "Guard gone" (a Guard worth a twentieth of the cap). *Beside the capstone*: the twelve
new nodes sit in column 6, row 2 - after the capstone in the list, so no node id moves - flagged `beside`: the
capstone's cost and its "every notable first" skip them. *The old burn bug*: a dot on them or on you is told apart by
the dictionary itself now (`is_same`), not its contents. The reviewer's catches, fixed: the head's arrival gave no
Guard; "Guard gone" could fill the log on a Paramedic's trickle; the skull read HP alone and the band hid the dots'
segments; the Blue Plaque went over the cap with Fireproof; the dry run's first Guard read the last memo; the red
numbers counted what Guard took. Left: the Stats sheet's Guard row; Guard's share in its own colour on the run screen;
the petrol on your hands still takes HP direct (self-inflicted: Guard doesn't cover it). *The smoke:* over the cap
(110 is 75 and +35, held at 50, all resists, never physical, the Plaque, -proofed, soaked, the lines' slots, the six
nodes); Guard (first off Guard, the cap, overheal and a med's line, Squared up with the guard line, the next run at
nothing, In the hide, Sheet metal and Breather through the run's own code, Overtime, Transfusion's cap and its med).

**The Outskirts (12 Oct, Matt; docs/design/outskirts.md).** A zone before the Estate, built after Guard and over
the cap: the Allotments, the Garden Centre and Top Farm, gentler than the Streets, with no crew (the zone is done when
its three are cleared). Every site's index moved up three and every zone's up one, so `Data.BANK` is 8,
`CONVOY_TIER` 9 and the Barracks 11. The tables and per-zone lists moved with them; the bossless zone's head is
`zone_boss(z)`, `{}` for the Outskirts. A site's level counts from the Streets (`Sim.lv_at`), so every old site keeps
its level. The Outskirts' depths don't count for the map's points, the deepest dig, the uniques' depth gates or the
Yard's depth columns. A save from before is moved on load (`Sim._shift_sites`: the Outskirts counted cleared, every
index up three, what's been seen with it), and the playtest read moves an old save and its record the same way.
Runs: four zone tabs and no map, opening on the furthest zone open. The map is on the Radio (the air / the map at
the band's right), and the Radio's site rows are two lines so twelve fit. Art: four jobs in
tools/pixellab_places_outskirts_manifest.json. The reviewer's catches, fixed: the ladders' spread read the wrong two
sites; the weather had one row too few (each zone took the one before's); the Manager walking crashed on a site with
no crew; the screenshot tool's map; what's been seen kept the old numbers; the probe ran at the Allotments; the read
moved items' tiers on old lines. *The smoke:* the Outskirts (first, three sites, no crew, the Estate after, levels, an
old save moved and moved only once, Runs' four zones, the Radio's map); every test's site moved up three (the fresh
yards' to the Allotments), the map's tests on the Radio. The bot clears the Outskirts in about ten runs.

**Guard's last two (12 Oct).** The Stats sheet's defence card says where Guard comes from and how far it fills, in
Guard's steel ("Guard to 80: overheal, 15% a gang"; the cap's note when nothing fills it), and the run screen shows
what Guard took as its own numbers in that colour - the red figures by type now count only what reached HP (scaled by
what reached it of what the types made, so Held's cut is out of them too: the review's catch). The band's the same
steel. *The smoke:* Guard's share kept out of the red, the Stats sheet's line and its fit.

**The first read with Guard and the Outskirts (12 Oct), and what it changed.** The probe hung the pass: it set off for
the Streets on a fresh yard, locked behind the Outskirts now (fixed: it walks them first). The thirty reads: the lorry
at 2.0-6.7 h with 8-15 moves in sixteen hours (the 7 Oct read had 3-8 in about twenty), the bank 0.6-1.3 h, every
site at 100% - Guard's quarter of HP on top of everything, compounding through the lorries' ×1.25. Matt: "these games
aren't supposed to be a cake walk" - Guard's cap 25% to 15% of max HP (Transfusion's words: "twice as much"). Scrap
read 7.1-9.0 crafts an hour against 7 and the Scrapper 10.7-11.8 against 8: a search's handful one in 0.35 (from 0.5)
and scrapping an item a pound in 24 (from 20). Run again with the probe. For the pass (not fixed, numbers or
Matt's call): a body is the best by its figure alone, so Nan's Cardigan (no armour by its rule) wears the heaviest
plates and their pace, and the Butcher's Steel loses the Machete's 30% bleed for the Door ram's 5%; the Plumber's
Belt drains a dot at half the rate, so a fast kill deals less of it; a site at loot tier 6 or more and depth 2-5
drops no loose unique (the levelling ones stop at 5, the core ones open at 6). *The smoke:* every unique held in its
range at both ends with its name, rule, type and its body's mounts; a top copy beats a bottom; the sign a lifted Cosh;
a T9 steel an upgrade on a T4; the bands by tier; the shelf's best through a save; the mate's tier, old and new; the
four rules.

**The twenty-fourth read (the Legion, 8 Oct, thirty reads, three a build: the Drifter at +15%, the band at
2×).** Three red, two of them not the game's. *The bank's band:* the classes 1.4-2.2 h; the element
builds 1.1-2.2 h, 2.0× exactly, which the reader called red on a float (2.2/1.1 = 2.0000000004) - a
hundredth's tolerance now. *Wounds:* the Drifter 4%, the frost Poacher 4%, waiting on Matt's save.
*The lorry:* the plain Drifter 31.7, 12.4, 17.4 h, median 17.4 - the +15% moved nothing because the
problem is variance: one read in three stalls. Read on four seeded fourteen-hour Drifters here, one
stalled (seed 22: tier 6 depth 1-4 from hour 2.6 to 7.6, damage 356 to 478, cash under £8k while the
quick read had 1,100 damage and £32k by hour 8), and its bought list says why: *the bot re-rolled its
gun's fire_pct eighteen times at £7-8k a go* - a plain Drifter fires no fire, so the affix does nothing
whatever its tier, the re-roll never lifts the weakest tier it keys on, and a run's whole take went to
the bench for five hours (`_bench_worn`: the weakest affix under the cap, one a run, while £2k stays).
Two bot fixes: an element's damage share the build has no conversion to is skipped (`_dead_stat`), and
an affix is re-rolled three times at most (`REROLLS_MAX`). The same seed again: the lorry at 13.0 h,
damage 773 by hour 6.5; the twenty-fourth's quick reads were never the problem. A player wouldn't do
this eighteen times, which is the point: the Drifter's late lorry was the bot's bench habit on the one
build with no element to lock. *To confirm on a pass when Matt is next off the machine.*

**The rail and the top bar, round three (8 Oct, Matt on the art: "the art reads ok - only change is to
remove the rail's extension into the menu - just keep the button as the button"; "top left reads 1
level and should be level 1"; "a bar under dmg/s so it reads the same as HP and XP").** The tongue
went (and its smoke check); LEVEL sits before the figure (the smoke reads the figure clears it); the
damage figure has the same line as HP and XP, filled by a minute's fire against the best open site's
first gang at its depth (`_dps_share`: full when the gang falls inside the minute, so it grows with the
kit and drops back as a harder site opens), in the figure's grey; the smoke proves the three lines
share one width and one row. *From play (Matt):* "the DPS bar should fluctuate based on damage dealt, even
if it's only cosmetic - a static bar looks weird", and a line showing past the Radio. The line moves now:
the sim keeps what landed this tick a second on the mission (`landed_rate`), and on a run the top bar
eases the damage line toward the kit's share scaled by what's landing against what it can put out
(`_move_dps_line`, every frame), so it swings with the spread, spikes on a first shot, climbs with walking
fire, drops under a resist and falls away while the runner searches; in the yard it settles to the share.
The line past the Radio was the last row's hairline: `last` was set after the row built and the rule read
it once, at build - a setter now. Smoke: a fight five seconds in has landed something, and the eased line
sits off the yard's share mid-fight; the hairline is off on the last row and on the rest.

**From the playtest: "11 of 10 down" (8 Oct, Matt: "no search happened and the count continued over -
it went to 12 out of 10 before I had to bail. level doesn't count as complete").** A convoy event (30% of
runs, 15-70 s in: four more on the pool, notes a kill, "A convoy comes through" in the log) had put four on
the parade's ten, and the run screen's bar read the site's pool, not the pool as it stood - so the run was
right and the screen was wrong. The bar's "of" is kills + remaining now, and the band's gang line says "a
convoy's crew in" (or "a convoy and N gangs so far"). Smoke: with a convoy in, the bar reads the grown
pool and the band says so.

**The twenty-third read, the final pass (the Legion, 8 Oct, thirty reads of ten builds, three a build,
thirty-two hours; the Drifter's +10%, wounds at 5-30 on the merged builds).** Twenty minutes for
thirty-one jobs. Three red. *The lorry* on every build but the plain
Drifter, 16.1 h merged (24.3, 16.1, 15.8) against the gate's 16 - the +10% took it from 24.1; the
rest 4.0-15.5 h, the Paramedic 7.6 (one read 19.3), the Poacher 12.2. *Wounds* 5-30 on every build
but the Drifter 3% and the frost Poacher 4%, the two built to be hit least (one fewer on you; the
slows). *The bank's band*: the Doorman 1.3 h median, the Poacher 2.6 h (1.8, 3.2, 2.6), the Paramedic
2.0 (2.0, 4.0, 1.7) - twice the fastest against the band's 1.5. Read against the cuts: a seeded Poacher
here with and without the read cap banked 2.2 against 1.5 h and 2.5 against 3.4 - no direction, so the
cuts didn't slow it; its bank hour is noisy on the same start. Spread, scrap, deaths, depth pace, cash,
no reds green. *Decided (Matt: "go for it"):* the Drifter to +15% damage, the Doorman's figure,
confirmed on a pass while Matt's away from the machine; `BANK_BAND` 2.0 - the Doorman starts fast by
design (+15% damage and armour from level 1) and the Poacher's +40% on a gang's first is one kill in
six at depth 1, so 1.3 h against 2.6 h is the classes, not luck, and 1.5 was the figure before any
class had a number; wounds on the Drifter and the frost Poacher stand as the bot's until Matt's save
carries `wounded_total`, which the playtest supplies - the row then reads him. *Matt playtests from
here.*

**The rail as a ledger (8 Oct, Matt: the room buttons "look very AI made in Godot - whereas the rest of
the game and its menus look pretty custom").** Mocked on the design canvas (Rail-A: now and three ways -
tabs cut into the wall, plates with a stamp, the ledger); Matt took the ledger with the tabs' join.
Built: the rail is one panel (`PANEL`, the cards' line, a "ROOMS" heading at the floor size) with the
eight rooms as rows of 96 under hairlines (`RAIL_BTN_H` 96, `RAIL_GAP` 0, `RAIL_HEAD_H` 40,
`RAIL_RULE`, `RAIL_HOVER`); a row is the name with its figure at the right in the cards' number style
(the yard's levels built "10/15", Runs "T8", the Lock-up's slots "6/7", the bench's level, the
caravan's points spent, the clinic "Fit" or the HP share, the fence's items for sale, the set's
level) or the badge in the figure's place, and one status line under (the second line's words moved
into the first where they were the better ones: the stash count, "Upgrade affordable", the contracts,
the pins). The lit row takes the cards' colour, the gold edge and the name in gold, and a tongue
(`_tongue`) reaches across the margin to meet the room's first card, so the rail and the room read as
one piece. `badge_gap()` reads the figure as it read the badge, so the fit check proves the figure
clears the name; the smoke also checks the join is lit on the lit row alone and lands on the room's
edge. Shot here on the Yard and Runs; the smoke runs on the Legion after the final pass.

**Before the final pass (8 Oct, Matt: "ok thats my save - make the changes and run balance").** Three.
*The plain Drifter +10% damage* (`CLASSES`, `"damage": 1.1`, the words "+10% damage; one fewer on you at
a time; +10% pace; −15% max HP"): last to the lorry on every read since the engine, 24.1 h merged on the
twenty-second against 4-13 h for the rest. *Wounds:* Matt's save carries runs and deaths (116, 7) but
no wounded count, so the row can't read it yet - the sim now counts `wounded_total` (saved, every
runner) and the summary reads `MATT_WOUNDS` as the deaths row reads `MATT_DEATHS` once a save carries
it; until then the row judges the merged builds against 5-30% (it was 10-25, a player's close calls;
the bot at 0.88 reads 2-27% across the builds, the two that run most at the top). *The final pass at
three reads a build:* `tools\balance.bat <hours> <reads>`, the flag "32 3", thirty-one jobs; the
bank's band read on three medians rather than two.

**The twenty-second read (the Legion, 8 Oct, twenty reads of ten builds, thirty-two hours: the cuts' first,
the climb fix in).** Two red. *The pass in fifteen minutes* (flagged 10:01, done 10:16 UTC), the reads
309-862 s against the twenty-first's 795-2,992 - three and a half to one on the slowest, under Matt's
twenty; the wall table reads the odds reads at 75-90% of every read still (the Doorman 773 of 862 s,
two million dry ticks), the tidy 100-220 s, the run 30-90 s, the ladders nothing. *The lorry on twenty of
twenty* for the first time, the first at 3.3-31.8 h; the Paramedic 9.4 h and 7.2 h (the twenty-first's
19.7 and never: the climb fix), the Scrapper 10.8 and 9.5 (16.8), the bleed Doorman eighteen moves, the
poison Poacher seventeen, the shock Drifter fourteen and thirteen. *The one late: the plain Drifter*, 31.8 h
and 16.3 h, merged 24.1 - last on every read since the engine; the first read sat at level 9 at hour 4
and level 50 only by hour 24, its cash flat at £41k from hour 20. Spread green, scrap green, deaths
green, depth pace green. *Wounds* 2-27%: the Poacher 20/26% and the Scrapper 27/23% at the band's top,
five builds under 10% (frost Poacher 2%, Drifter 4%, Paramedic 7%, bleed Doorman and shock Drifter 8%) -
the spread again; the band was set for a player's close calls, and the bot at 0.88 with a kit past its
sites has few. The bank's band 1.1-3.4 h on the classes (the Poacher's two reads 3.3 and 3.5 h, the
Scrapper's 0.9), luck as labelled. A real KIA on a Doorman read, the first the bot has taken.

**The twenty-first read (the Legion, 8 Oct, twenty reads of ten builds, thirty-two hours: the six's first).**
Three red (the twentieth's five). *The spread at the first lorry green, scrap green, deaths green.* *The
lorry on eighteen of twenty* (the twentieth's nineteen at the old price), the first at 4.0-29.9 h, the
bleed Doorman seventeen moves, the poison Poacher fifteen, the shock Drifter thirteen; late merged: the
plain Drifter 25.5 h (21.1 h and 29.9 h), the Paramedic 19.7 h (one read never), the Scrapper 16.8 h.
The two nevers: a Paramedic at level 50 with the services at depth 7 and 11,273 notes in hand - a depth
short of the lorry and never dug the last one; a fire Drifter at depth 8 with 44,590 notes. The
Paramedic's is a bot fault found in the wall work below: the climb read the odds hurt, straight off the
run, so a 0.92 read that the pick (read whole) would pass failed every run; fixed with the cuts, so the
twenty-second reads it. The plain Drifter took the lorry on both reads again at 960 - late, not never;
the +10% stays on hold until the climb fix has read. *Wounds* 4-27%: `WOUND_AT` 0.33 put the Poacher
and the Scrapper at 25-27% (the band's top 25) and left the rest at 4-9% - a spread between builds,
not a level; the Poacher and Scrapper are the two that run the most and search the longest (973-1,006
runs), so they take the most close calls. To think on, not to tune blind: the row might read the merged
builds, or the band's top might be 30. The bank's band red as luck (1.9-2.2 h on the classes). Wall
795-2,992 s a read, the pass fifty minutes.

**Where the wall goes (8 Oct, Matt: the pass at an hour and "only going to get longer").** Counters, not
cuts: `Sim.prof` counts the odds reads (`survival` calls and the reads the cache misses, the dry runs
and their ticks, the snapshot's time) and the real run's ticks, the gate times the bot's step, its
tidy and the ladder reads, prints a `wall` line and a `prof` key in GATES, and the summary ends with
"Where the wall went", a table a read, slowest first. A two-hour Scrapper here: 61 s of wall, 42 s
in the odds reads (2,312 dry runs, 96,000 dry ticks against 5,800 real), 17 s the run, 5 s the tidy,
the snapshots nothing - so the dry runs are the cost, sixteen ticks to one, and the snapshot copy is
not. The cuts to pick from once the twenty-second has read it on every build: the bot reading at a
budget of its own, the ladder read halving rather than stepping, a coarser dry step.

*The cuts (8 Oct, Matt: "build the cuts now ... can you find time elsewhere to get it sub 20").* Six,
none touching what the game does for a player: (1) `Sim.fast_memo` - the gate keeps the dry run's
kit memo on through a real run too, cleared every thirty seconds of the run, at the gate and wherever
the kit changes, so a tick reads the kit once rather than thirty times a second (the run's ticks 17 s
to 3 s on a two-hour read; the shell leaves it off); (2) the odds key rounds the HP tenth (a rest to
full that landed a hair under read as nine tenths and re-read every pick) and takes the figures in
steps of 2% (`_odds_bucket`), so a paragon level or an affix's hair doesn't re-read - this one the
shell shares: the Runs screen re-reads when a figure moves 2%, not for any change; (3)
`Sim.odds_runs_max` - the gate caps a read at twenty-four dry runs, glasses or not (the player's
number is sixty; the bot's verdict at PUSH is the same), and under the cap a read three down by the
eighth stands as it is, since it can't reach PUSH over twenty-four (a boss's read runs on - the lorry
is taken at better than even); (4) the ladder read halves rather than steps (five or six reads a site
for thirty); (5) a bot fault: `_endgame` ran a full site-pick every run to choose the tier for a word,
and the word it put on changed that site's key, so the step's pick read it all again - two picks a
run; it uses the tier just run now; (6) a bot fault with a balance edge: `_climb` read the odds hurt,
straight off the run, where the pick reads whole - a fresh read every run at odds the pick never sees,
and a 0.92 that a whole runner would pass failed, so the services stuck a depth short of the lorry
(the twenty-first's Paramedic at depth 7 with 11,273 notes); it reads whole now. Read here on a
seeded twelve-hour Scrapper (`-- 12 gate Scrapper "" 7`, the fifth argument the yard's seed, new):
434 s against 1,250+ s before the cuts, about three to one, the odds reads still 374 s of the 434 -
1,109 reads of 1,387 calls, and the misses are real changes (a level, a word bought, a depth stepped
back), not the key. The dry tick itself is the floor now, 0.6 ms a tick of `_fight` in GDScript; the
next cut is in the fight, not around it. Expected on the Legion: the slowest read from 50 to
15-20 minutes.

**The twentieth read (the Legion, 8 Oct, twenty reads of ten builds, thirty-two hours; the six landed
while it ran, so the sim is the nineteenth's - the old price, 0.30 - and the rows are the new ones).**
Five red, deaths green on Matt's save. *The lorry on nineteen reads of twenty* (the nineteenth's
seventeen), the first at 5.9-28.2 h, the bleed Doorman moved sixteen times in thirty-two hours (a
leg every two hours), the poison Poacher fourteen and thirteen, the Paramedic ten, the shock Drifter
ten; the one never a Doorman at level 50 with the services at depth 7, its notes short of the old
price. The plain Drifter took it on both reads (14.7 h and 27.1 h at 2,160 notes), so the +10%
waits on the twenty-first at 960 before it is wanted. *The late three* (Drifter 20.9 h, Poacher
19.7 h, Scrapper 19.0 h merged) are the old price again: every one stands with the services at
depth 8-10 by hour 14 and pays at 2,160. *The spread at the first lorry* holds the band 7-11 on every read that
lorried with a ladder but one, a Doorman at 21/9 (twelve); five reads never left the T0-T2 ladders
(both bleed Doormans and both fire Drifters at level 1-5 at the end, a frost Poacher at level 1) -
the lorry at depth 8 falls to a cheap run on those builds and the bot never climbs, which the row
cannot read; to watch on the twenty-first, a bot fault if it holds. *Scrap* 1.4-6.8 crafts an hour on the first sixteen with the Scrapper's second read at 7.7,
just over the band's top. *Wounds* 1-17% at 0.30 (the Scrapper 17% both reads; the rest 1-12%),
the 0.33 reads on the twenty-first. The bank's band 0.6-2.2 h, luck as labelled. Smoke clean on the
six after it. Nothing moved; the twenty-first is the six's first read. *One gate fault found after it
was flagged:* the first-lorry ladder read went without the end read's full ammo box, and a gun with
a few rounds left reads 0% - the lorry's fight leaves few. `_ladder_read` now arms and heals the
runner itself for both reads (from the twenty-second; a 0/0 spread on the twenty-first is this).

**The nineteenth read (the Legion, 8 Oct morning, twenty reads of ten builds, thirty-two hours).** Six red,
No reds and depth pace green. *The loop runs:* the lorry on seventeen reads of twenty, the first at
6.0-24.9 h; the bleed Doorman moved ten and twelve times in thirty-two hours (a leg every two and a half
hours), the poison Poacher ten and eight, the fire and shock Drifters six and seven; the ladders on the
tenth yard at 29/19 and 30/20 against the first yard's 16/6, so the growth outruns the curve - the
second leg's figure, answered: ×1.25 a lorry with the paragon banked keeps pace and then some. *The
three that never, and the two late:* every saved yard reads the convoy at its depth at 1.00 again, and
sits short of its price - the plain Drifter at 1,679 notes against 1,680, the Paramedic at 844 and the
Poacher at 1,355 against 2,160 - the notes gone on the mate's uniques and the heads re-armed at twice
their price. Fixed in the bot: once the services stand within a depth of the lorry, the lorry's price is
kept back from the mate, the heads and the words in notes (`_notes_kept`). A number for Matt beside
it: the convoy's price is still the three heads at full-strength rate (`PINNACLE_COST` ×2, 2,160 notes
at depth 8) though the heads now come light; the plain three would be 960. *The rest:* the ladders'
spread on the fire Drifter's seventh yard 26/14 (the spread widens as the yards compound: the band was
set on first yards; proposed: the row reads the first yard, or the band is 7-13); scrap 8.7 crafts an
hour on a Scrapper (the loop's late game is richer still; the band's top to 10, or the row reads the
first sixteen hours); deaths one in 48-232 and wounds 2-7%, the pair as before - a bot playing to 0.88
with a kit that outruns the sites it runs is never wounded; the bank's band 1.7-3.3 h on the classes,
the drop's luck. Nothing moved but the bot.

**The eighteenth read (the Legion, overnight 7-8 Oct, twenty reads of ten builds, thirty-two hours, every
read to the end in 20-50 minutes of wall).** Seven red. *The lorry on eleven reads of twenty* (8.9 h
to 29.4 h), the loop run to seven moves on a poison Poacher (its ladders 24/13 against the first
yard's 16/6), to three on a Scrapper; nine reads never, with the services at depth 8 and the yard
flush (a shock Drifter with 50,900 notes, a Doorman with 28,600). Read from the saved yards: *every
one of them reads the convoy at its depth at 1.00* - the bot was not taking it. Three bot faults,
all fixed: it left the run when the site read picked over, which with the pool half down and the
heads still to come meant walking out on the convoy at 12 of 16 (`should_leave` stays while a head or
the lorry stands); a pick disarms everything first and the lorry was only re-armed when its odds were
read again, twenty minutes apart, so the run after a good read went out plain (`lorry_ok` keeps the
read's verdict and arms on it); and it built a box of rounds a run for thirty hours - `build` lands
the thing "whatever the room" - until the stash sat at 327 of 234 (291 boxes) and every find was
dropped, the kit stood still and the services were run at depth 8 for fifteen hours at 0 items (the
sim's `build_options` now want room for what they make, "No room in the stash"; the bot builds rounds
only under three boxes of its type). On the shock Drifter's saved yard the lorry falls in 74 seconds
once the bot stays. *The second leg's shape:* a move starts a new runner at level 1, and the paragon
levels went with the old one, so a fresh yard's runner at level 44 read the stations the last one held
at 1.00 at 0.00 (the Scrapper on its fourth yard, the lorry at depth 11 and the services' depth 8
plain at 0.00) - the paragon is now the yard's, banked by the move (`paragon_banked`, saved) and added
to by every runner since, so the loop carries its growth. *The rest:* deaths one in 30-162 (the bot's
appetite at PUSH 0.88 and now a kit far past the sites it runs), wounds 1-9% (0.30 over-corrects),
the Scrapper's second read at T8 50% and the fire Drifter's depth pace at 0.7 an hour are the stash
wall. Nothing moved but the bot and the stash's room; the nineteenth read is the first that can read
the second leg.

**The seventeenth read (the Legion, 7 Oct, twenty reads of ten builds, thirty-two hours asked: the
engine's first).** Every read was cut by the gate's wall limit (an hour) at 9-23 simulated hours, so
the rows read against sixteen are not comparable - but the lorry row is the finding. *The loop works
and compounds:* the bleed Doorman beat the lorry at 7.3 h and 7.6 h and went on to eight and seven
moves in 22 hours, its ladders at 22-23 against 14-15 (the first yard's 16/7); the shock Drifter at
5.0 h (five moves) and 9.7 h (three); the poison Poacher at 11.5 h (three). The others had the
services at 7-8 when they were cut at 9-15 hours, where the sixteenth read had them at 8-10 by
sixteen. *The pace:* past level 14 a fight is minutes of the yard's time, and the odds reader runs
twenty-four of them a read; the bot read every open site a pick (nine) and the convoy (three heads)
every run, so an hour of the yard cost 400 s of wall against 115 before. Fixed in the bot: the sites
are read in level order and the first that holds is taken (one read a pick most of the time); the
lorry's odds are read once in twenty minutes of the yard's time; the summary's median of a lorry hour
left the reads that never got there out (two reads had averaged a never into "505 h"). *The rest* as
the sixteenth: deaths one in 35-72 on five builds and wounds 4-8% on six (0.30 over-corrects; 0.33
proposed), the bank's band the drop's luck, one Poacher's T8 at 50%, the fire Drifter's depth pace at
exactly one an hour. The second leg's figure - whether ×1.25 a lorry and 6% an item level keep pace
with +14% a level - needs a read that reaches it. *The convoy, re-sized from two saved yards:* the
hour-16 bleed Doorman of a local read (1,316 dps, 577 HP, 382 armour, stronger than the Poacher the
first sizing came from) read the convoy at 35% HP and full fire at 0.00 where the Poacher read 0.80 -
the Poacher's +40% on the first of a gang counts on every head, so the same heads are two different
fights by class. At 25% HP and 0.75 fire the Doorman reads 0.93 and the Poacher 1.00: `CONVOY_HP`
0.25, `CONVOY_DPS` 0.75 ("they come light and tired"). The same read showed the bot's rig with no
meds at hour 16 and the stash over its cap (264 of 234), to be looked at.

## The engine: the first leg sized, and what grows without end (7 Oct)

Matt, on the sixteenth read: "infinite scaling is kinda the point - we want players to be having and
dealing millions of HP/damage ... getting past the first leg and then scaling compounds", and "if you
can play the whole game with kit you've had for the last 40+ hours the loot loop of the ARPG has
failed." The read had shown the player side did not compound at all: `MAX_LEVEL` 50 by hour 8, HP and
damage linear in the level, the kit capped at T6 with capped affix tiers, against a curve at +14% a
level for ever - a wall at level 14-15 of every ladder for every build. Built, all in one batch:
*The first leg.* The stations at level 14 on each head's own site: `PINNACLE_DEPTH` by zone [12, 9, 6]
(`pinnacle_depth(i)`); full strength is twice the crew at the same fire (`PINNACLE_HP` 2.0,
`PINNACLE_DPS` 1.0 - the probe read a fire multiplier at 0.00 whatever the HP); the lorry at depth 8
(`CONVOY_DEPTH` 8, level 14) with its three heads at plain strength and `CONVOY_HP` 0.35 of their HP
each ("they come light, the crews left with the load": three in a row at 35% read 0.80 for the hour-16
kit, at 50% 0.17); the bot arms the lorry at `LORRY_ODDS` 0.6 with the kit insured, the ending taken
at better than even. *The ending climbs.* `pinnacle_depth` and `convoy_depth` add `yard_moves`: each
yard's stations and lorry are a depth (×1.14) deeper than the last. *The prestige.* `LORRY_MULT` 1.25
on damage and HP a lorry beaten (`lorry_mult`, the lorries kept across moves): ten lorries is ×9.
*Paragon.* `Data.xp_for_level` runs past the cap on the same curve (the table grows as asked);
`paragon()` is the levels past 50, `PARAGON_PCT` 2 on damage and HP each, no top; the top bar reads
"Level 50 +12" and the XP line keeps counting to the next. `growth_mult()` is the two together, in
`max_hp` and the damage. *The deep drop.* `Items.ilvl_mult`: an affix's rolled value times
1 + `ILVL_SCALE` 0.06 a level past `ILVL_FROM` 15 (nothing before: the campaign's drops are as they
were), in `roll_affix` so the bench's rolls grow with the item's level too; a unique or a set piece
found deep carries the site's level (`roll_unique` and `roll_set_piece` take `level`; every find and
head's drop passes it) and its fixed affixes scale the same - a depth-25 barracks find is level 33 at
×2.08. Smoke: the stations' depths by zone, full strength twice the HP at the same fire, the convoy
three in a row and light, the ending a depth deeper after a move and the multiplier by the lorries;
paragon at ten levels on HP, damage and the top bar, the curve past the cap, three lorries ×1.95, the
deep affix at the same tier, a unique carrying its depth, the barracks at depth 25 giving level 33.
The pass now needs two legs to read: `balance.bat 32`.

**The sixteenth read (the Legion, 7 Oct, twenty reads of ten builds, sixteen hours, the four in).** Five
red; the spread and scrap bands green as re-stated, No reds back to red on one Poacher. *The lorry: no
build, again*, the services at 8-10 on every build, the convoy never armed - and this time with the
depth at 10 and a poison Poacher holding 15,800 notes against the 2,400 the convoy asks. So it is the
odds, not the depth or the price. Read offline from a gate's end save (`balance.gd` now writes
`docs/balance/<build>.save` at the end of a read; a scratch probe arms the convoy and reads
`survival`): the hour-16 poison Poacher - level 50, 906 dps, 439 HP, 270 armour, as strong as any read
ends - reads the services plain at depth 8 (level 14) 1.00 and at 9 (level 15) 0.00; the barracks' plain
quartermaster at depth 6 (level 14) 1.00, at 7 0.28-0.32, at 9 0.00; the quartermaster at full strength
at depth 10 (level 18: 469k HP, 143 dps against the runner's 439 HP) 0.00; the convoy at depth 10
(1.36M HP across the three, 95-134 dps each) 0.00, and 0.00 at depth 8 whatever the heads' HP, until
their fire comes down. Every build caps at level 50 by hour 8, so the hour-16 kit is the end kit, and
its edge is level 14-15 on every ladder: the stations (full strength at depth 10, the lorry at 10-12)
sit two to four levels past where the end kit can stand at all, and `PINNACLE_HP` 2.5 × `PINNACLE_DPS`
1.6 on top. Varying the figures on the probe: the fight is attrition, incoming fire against HP, so the
dps multiplier is what kills - at ×1.25 fire the convoy reads 0.00 even with the heads at a quarter of
their HP; at plain fire a single head at twice its HP reads 1.00, three heads in a row read 0.80 at 35%
of their HP each (9.8 site-HP units in all), 0.17 at 50% (14 units), 0.00 past that. *Proposed, not
moved:* the stations at level 14 on their own sites (`PINNACLE_DEPTH` by zone [12, 9, 6], as the sites'
own uniques; the map's Full strength two sooner), full strength as twice the crew and the same fire
(`PINNACLE_HP` 2.0, `PINNACLE_DPS` 1.0: "he's brought the whole warehouse"), the lorry at depth 8
(`CONVOY_DEPTH` 8, level 14; the keystone from 6) with its three heads at plain strength and 35% of
their HP each (`CONVOY_HP` 0.35: they come light, the crews left with the load), and the bot arming the
lorry at 0.6 odds with the kit insured - the ending taken at better than even, not at PUSH. *The rest:*
wounds 2-9% on four builds under the band's floor (0.30 over-corrected from 0.35's 31-44%: 0.33
proposed); deaths one in 32-82 on six builds - the bot's bail rate at PUSH 0.88 is the bot's appetite,
not the game's, and the row should read Matt's save, not the bot (proposed: the row stays, read from
the save's count, the bot's figure shown beside); the one Poacher read at T7/T8 50% ran the services
hurt and wounded for seven hours at £3k a run with the stash filling, because every run's take went on
the bench before the clinic's price was there - the bot now keeps the treatment's price three times
over back from the bench, the gamble and the words (`_reserve`); the bank's band is the drop's luck.

**The four moved (7 Oct, Matt: "make the changes and I'll run the balance after before playing").**
`CONVOY_DEPTH` 10 (the lorry at level 16, where sixteen hours lands; the map's keystone runs it from
8; the yard's "done" line and the map's empty panel read the figure); `WOUND_AT` 0.30; the spread
band 7-11; the scrap band's top 7. The sixteenth read is the first with them.

**The fifteenth read (the Legion, 7 Oct, twenty reads of ten builds, sixteen hours each: the SMG line
and walking fire in).** Six red; No reds and depth pace back to green, the probe, the keystone, the
capstone and cash green. *The SMG line is in the game:* the armoured car gun on a bleed Doorman, a
Paramedic, a shock Drifter and a poison Poacher at hour 16, the riot squad's SMG on a Poacher, the
courier's on a frost Poacher; no read sat at depth 1 - both plain Drifters dug to 8-9 (one took until
hour 10 to leave depth 1 and 380 dps, then went 379 → 770 dps and £500k a half hour by 14), level 45
against the others' 50. *The lorry: still no build at sixteen hours*, the services at 8-11 on every
build, the convoy never armed. Every build sits at level 16-17 on the services (depth 10-11) at hour
16; depth 12 is level 18. The read says: the lorry at hour 16 is the services at depth 10
(`CONVOY_DEPTH` 10, level 16; the map's keystone would then run it from 8), or the growth past the
campaign is too slow for depth 12 by 16 - Matt's call, and I would move the depth, since level 16 is
where sixteen hours of every build lands. *The ladders' spread 7-12*, half the reads in the band
(Doorman 16/9, 16/8, Drifter 18/9), half over (Drifter 17/6, the fire Drifter 20/8, 19/7); the
streets 14-20 at PUSH, the barracks 4-13. The design's figure (7) was written before any read; the
shapes were set a site at a time and read as meant; I would re-state the band as 7-11 from the read
rather than move the shapes. *Deaths one in 31-69 on five builds and wounds 31-44% on six*: the pair
again, and now plainly one thing - the bot's runs end between a quarter and a third of HP often
(`WOUND_AT` 0.35 counts them wounded) and under a quarter rarely (a bail). One figure fixes both
rows: `WOUND_AT` at 0.30 or the wound band at 20-40%. *Scrap 5.3-6.3 crafts an hour on four builds*
over a band of 1-5 set on eight-hour reads: the late game is richer in scrap; the band's top to 7, or
scrap's late sources read. *The bank's band* (the element builds 1.0-1.8 h) is the drop's luck, as
every read. No number moved; four decisions on the sheet, each with a figure proposed.

## The SMG line, walking fire, the lorry's hour (7 Oct)

Matt, on the fourteenth read's Drifters: "the solution is more guns and better SMGs at the top end",
and "SMG was the one thing I really enjoyed playing", so it goes in before the save. Built from
concept.md's proposal: four bases - Security guard's carbine (T3, 18 × 3.0), Courier's SMG (T4,
21 × 3.6), Armoured car gun (T5, 25 × 4.0), Riot squad's SMG (T6, 28 × 4.4, the slot's four-cell
footprint) - and the Section gun lifted to 27 × 4.4, so the line runs a gun a tier from T2 to T6 with
two at T6 like the shotguns and its top at 123 against their 115. Their words in `Words.ITEMS`. *Walking
fire*: every SMG primary carries `sustain` [4, 40] - the fight's stream grows 4% a second on one gang
to +40% (`sustain_mult`, read in `_fight` with the headshot; `sustain_t` on the mission, reset when a
gang arrives, the convoy comes or a head comes out) - the long fight's gun, nothing for a rifle's first
shot; the panel's tail says "walking fire +4%/s to +40%" (`Items.base_res_words`). The odds reader
runs the same fight, so it is in the odds. The art: four jobs in `tools/pixellab_items_new_manifest.json`
(`security_guard_s_carbine`, `courier_s_smg`, `armoured_car_gun` at 192 × 64, `riot_squad_s_smg` at
256 × 64), the manifests regenerated on the Legion (the seeds after the insertion shift; existing files
are skipped). *The gates*: `LORRY_BY` 16 (Matt: "16 hours would be right given the type of game"),
`balance.bat` sixteen hours by default, the gate read's wall limit an hour. The ladders' spread band
stays at 5-9 until Matt says whether the design's spread or the shapes move. Smoke: the line's tiers
and count, the top a shade over the others', walking fire on every SMG, its figures at nought, five and
thirty seconds and not on a shotgun, the tail's words.

## The pass resumes: the endgame's two gates and the bot's loop (7 Oct)

All four parts in, the balance pass gains the two rows concept.md named. *The lorry*: beaten by hour
`LORRY_BY` (8) on every build; the read is the hour of the first lorry (`lorry_at`), the moves made and
the services' deepest clear when it never came. *The ladders' spread*: at the end, in the kit as it
stands, the deepest depth the streets and the barracks read `PUSH` (the depth set past the ladder for
the read, the plain site), the streets' less the barracks' in `SPREAD` [5, 9] (by level they sit eight
apart; the streets' shape is gentler). The bot plays the endgame as designed: past the campaign it runs
the site that reads PUSH at the highest level (the better kit) except that the services come first
while the lorry stands, and the climb digs them toward it; the convoy is armed at its depth when the
notes are there and the odds hold with it in; the lorry beaten, the yard moves on (`moves`, the class
put back, the campaign again from the floor); the map's points go a rank each, the columns in turn,
each down its chain; a site climbed past its clear that no longer reads PUSH steps back to the clear
(the fourteenth read: three builds sat at depth 1 for eight hours with every site's depth 2 unread).
The summary's builds table gains Lorry (moves) and Ladders S/B. The pass's
baseline is now a different game from the thirteenth read (the ladders by level, the lorry, the move,
the map): the first read after the parts is the fourteenth and starts the sheet again.

**The fourteenth read (the Legion, 7 Oct, twenty reads of ten builds, twelve hours each: the first after
the four parts).** Eight red; the probe, the keystone, the capstone and cash green. Read with the new
game in mind, not against the thirteenth. *The lorry: no build.* The services' ladder is now by level
(6 + depth), so depth 12 is level 18, the hardest fight in the game, and the convoy on top of it. The
fastest dig had the services at 12 at 11.7 h (the frost Poacher, both reads 12 and 10), the plain
classes at 8-10 by hour 12; nobody armed it. By the bot, the lorry is a 14-16 hour thing. Levers, all
Matt's: the gate's hour (16 and sixteen-hour reads), `CONVOY_DEPTH` (10 is level 16; the map's
keystone would then make it 8), or the services' shape. *The ladders' spread: 10-11 on most builds*
(the streets 16-19 at PUSH, the barracks 6-7; the band 5-9 was the design's "streets 15 against
barracks 8"). By level the two sit eight apart; the shapes make the streets about two depths gentler
than the design said and the barracks one steeper. Lever: the sites' `shape` (hp, dps) or the band.
The Poacher reads 13-16 against 3-6 (the same spread, lower on both: the rifle). *Three reads stuck at
depth 1 for eight hours* (both plain Drifters, one Scrapper): a belt-fed SMG in hand, dps flat at
380-485 from hour 4, level 34-35 at 12 h against the others' 50, 100-110 runs against 200-350, cash
under £500 at every mark while the half-hour earned £6-28k, the stash 130-148 of 182. The first
guess - the SMG's rounds - was wrong: a read with every pound out tallied by what took it (an
eight-hour Drifter, a scratch setter on `cash`) put rounds at £724 of £850k earned (the rounds come
off the bench for scrap), the bench's affixes and re-rolls at £378k (44%), called-in words at £118k,
the fence's buys at £37k, the yard's upgrades at £250k. The wall is the SMG's damage line: the type's
top bases (the Section gun 26 × 4.2, the belt-fed 24 × 3.8) are the lowest dps of the types, the
Drifter has no damage of its own (−15% HP, a man fewer on it) and the bot holds the class to its
type, so there is nothing better of its kind to buy and the cash goes on re-rolling what it has. The
bot had the larger part, fixed below: a site climbed to depth 2 that did not read PUSH sat there
unread and the pick never came back to it, so the three reads ran depth 1 everywhere; the same build
with the fix dug to depths 3-5 and held £57k by hour 8, still level 32 against the others' 50. The
Drifter's T8 at 50% (No reds) and the depth pace 0.0 are the same reads. *Deaths one in 31-42 on four builds* (the band 10-30): the bot's bail-outs are rarer
with the level-based pick, which runs the barracks at depth 1 at 100% rather than a site at its
edge; whether that is too safe is Matt's save's to say. *Wounds 26-41% on five builds* (the band
10-25) and *the bank's band* (1.4-2.7 h, the slow reads 2.6-2.9 h, the drop's luck as before) are the
thirteenth read's causes unchanged. *Scrap 5.0 crafts/h on the poison Poacher* is the band's edge.
No number moved: the two new gates' figures (8 h, 5-9) were defaults for a first read and the read
says what they should be if the design stands; the shape and the convoy's depth are design.

## The endgame, part 4: the map at thirty-six (7 Oct)

Built as concept.md's part 4, mocked as Map-B. `Data.ATLAS` is thirty-six nodes in three columns of
twelve (`column`, in chain order; `max`, `notable`, `keystone`, `figures` a rank, `sum` for the strip,
`sentence` for the panel), each column a chain: a node opens when the one before it has a rank
(`atlas_open`), fifty-nine ranks in all, fed by the same point a new depth. The six passives are the
first ranks of their columns. The sites: Picked over, Deeper pockets, Quiet roads, ★ After dark (every
site is Night, the dark's rarer finds half again), Second look (a search finds one more, every other then every), Worn in (recovery half
again as fast a rank, `recover_s`), Easy pickings (drops +10% a rank), ★ Local knowledge (the bases a
gear tier up), Short cuts (pace +5% a rank), ★ Open ground (one fewer on you), Every penny (cash
+10% a rank), ◆ The lie of the land (every ladder opens one past the deepest cleared, in `set_depth`).
The crews: Paid in notes, Two of everything, Heads up (a head's price a third less a rank), ★ Full
strength (the pinnacle two depths sooner: `pinnacle_depth(i)`, by zone since the engine), Bounties (a head's notes half again a rank),
Wages (XP +10% a rank), ★ Heavy crews (one more on you, kills pay half again in cash and XP), Their
own kit (a kill drops 10% more often a rank), ★ Marked men (+25% on the first of a gang), Long memory
(a crew's head's price paid once a depth: `boss_paid`, the depths paid, saved), ★ Head start (a head at full strength pays a
map point), ◆ The lorry's route (the convoy from depth 10: `convoy_depth()`). The air: Word travels,
Good reception (fresh word a quarter cheaper a rank), Clear air (the radio never hears Resistant), ★
Long wave (one more word a site, `max_words()`), Fair weather (Rain and Fog half as hard a rank,
`_softened`; lifted at two), Night eyes (Night's pace halved a rank, the rolled word too), ★ The forecast (+20% cash under
Rain or Fog), Early word (a called-in word a quarter cheaper a rank), Tip-offs (+5% loot quality a
rank), ★ Dead air (gangs a quarter later at night), Held word (a pinned word holds through a move), ◆
Open channel (every word costs notes, never cash: `words_in_notes`, `intel_notes`, `juice_notes`,
`OPEN_CHANNEL_NOTES` by zone; the radio's buttons and menus say the price in notes). The map moves with
the yard (its ranks and points are kept: it is the long tail). The screen (`atlas.gd`): the caravan's
tiles two across, the keystone the width, ★ and ◆ on the names, a locked tile dim, the column head
counting its ranks, the sum strip as the taken nodes' figures (seven and a count), the panel naming what
a locked node needs. `shot.gd`'s map mode takes sixteen ranks. Smoke: the chain (open from the top only,
in order), every column twelve ending in a keystone the width, the strip's count, a locked node's panel,
and every new node's effect read through the sim: After dark, Worn in, Easy pickings, Local knowledge,
Short cuts, Open ground, Every penny, The lie of the land, Heads up, Full strength, Wages, Heavy
crews, Long memory, Head start, Bounties, The lorry's route, Good reception, Clear air, Long wave, Fair
weather at one and two ranks, Night eyes, The forecast, Early word, Tip-offs, Dead air, Open channel
paying in notes, the ranks adding to fifty-nine, Held word and the map through a move.

## A log line of one long sentence (7 Oct)

Matt's smoke: "One of them is in the last doorman's station helmet, visored." needed 696 px of the log
line's 688 - one sentence, no semicolon or colon, so `_by_sentence` had no shorter form. It now ends
with the line cut at its last comma, with a full stop, as the last resort. Smoke reads the forms.

## The endgame, part 3: a site's own unique, the shelf's gaps (7 Oct)

Built as concept.md's part 3. The nine uniques gated at depth 25 - never reached by anyone, and the
rules already in the sim - are now the sites' own: a `site` on each in `Data.UNIQUES` (the streets' is
the gritter's hopper, the parade's the sergeant's whistle, the retail park's the sparky's gloves, the
pleasure park's the gamekeeper's flask, the shopping centre's the float, the bank's a blue plaque, the
services' the lorry driver's log, the hospital's the vicar's thermos, the barracks' the quartermaster's
manual). One drops only on its site, past `SITE_UNIQUE_DEPTH` for the zone (the estate's at 12, the
town's at 9, the city's at 6: the streets' is the deepest dig in the game and the barracks' the hardest
fight), `SITE_UNIQUE_DROP` 3% a find there until it is on the shelf and a quarter of that after (`SITE_UNIQUE_AGAIN`); never loose, never the mate's or a contract's
(`loose_uniques` leaves them out; `site_unique`, `site_unique_depth`). The caravan's shelf shows the
chase first (`shelf_chase`): thirteen rows - the nine sites' own, the three heads' charms, the lorry's load -
each a gap in the quiet grey until found, with where it is under it ("Ransacked streets, depth 12 and
past. A rule only that depth gives."; "The carpet man at full strength, depth 10 of his site. The charm
only he carries."), then the rest found in the order found. The Runs card's note names a site's own
until it is on the shelf ("Depth 6: its own, The quartermaster's manual"), after the stations. The fence's gamble no longer hands out a site's own or a head's (it could roll any unique of the kind before): the chase is the ladders' only.
Nothing new saved: the shelf is by name as before. Smoke: none of the nine loose; the gates by zone; the
barracks' own never at depth 5 and within 400 finds at depth 6; the note names it and stops once found;
the shelf's thirteen gaps, their order, the first gap's words and colour, a found one filling its gap.

## The endgame, part 2: the lorry as the ending, the move as the loop, the wall as the score (7 Oct)

Built as concept.md's part 2, mocked as Yard-E. *The ending*: the convoy's last head down writes
`lorry_done` (this yard) and counts `lorries` (across yards); the log says the lorry's load is yours and the
yard can move on; the yard's next line reads "The lorry's beaten: move the yard"; the town card's note
turns green with it and Move the yard becomes the primary button. *The move compounds*: a moved yard's
ladders start at `ladder_floor()` (the moves made, to `LADDER_FLOOR_MAX` 3) - a site's first clear opens it
to the floor, said in the log, no map point for it - and its first `yard_moves` nodes of the yard's tree
cost nothing (`node_cost`: the first taken, in the order taken, or the next when fewer are taken); the
move's menu says what the next yard starts with. *The score*: `best_dig` (site, depth, which yard) is
kept on every clear and across moves and shown on the town card in the accent; a retired or dead runner's
record carries the deepest site and depth they held, and the caravan's line reads "a scrapper, 17 runs,
the bank at depth 9, retired". Saved: `lorry_done`, `lorries`, `best_dig`; the past's `site` and `depth`.
Smoke: the lorry written and said; the Yard lit; the best dig and the wall's record; the move keeps the
lorries and the dig, clears `lorry_done`, frees the first yard node and not the second, and a site's first
clear opens to the floor without a map point; the round trip.

## The endgame, part 1: a site's level (7 Oct)

Matt: "the loot part of this needs to work - the barracks should drop high level top tier stuff with the
streets dropping lower tier gear. On the UI it just needs to be clear that you increase the site and the
depth you get better stuff - Diablo 4 handles this well with the torment scaling. Start building with
that in mind." Built: `Sim.site_level(i)` is the tier and the depth (the streets at depth 8 is 8, the
barracks at depth 1 is 9); past the campaign `effective()` runs the curve by the level (`CURVE` by
`grow` and `reward` to the power level − 9), never under the site's own campaign curve, so the streets'
ladder is gentle and long and the barracks' steep and short; the bases a find draws from are by level
(`loot_tier_at`: level × 6 / 9 floored - the streets reach the city's bases at depth 9, the barracks from
depth 1); a site's find carries the site's level as its item level (`Items.roll` takes a `level`; the
shelf, the gamble and the clinic roll as before). The rarity bonus and the notes a kill stay by depth.
The Runs card: the kicker reads "Tier 1 · The Estate · level 8" past the campaign, the Drops tile is
Finds ("level 8 · tier 5 gear"), and the note line names the stations ahead when nothing else needs it
("Depth 10: the quartermaster at full strength · Depth 12: the lorry"); the map's empty panel says
where the lorry runs. Smoke: the gear tier by level, the two sites' levels, the barracks at depth 2
harder than the streets at depth 8 and never under its campaign curve, a find's item level the site's,
the kicker, the Finds tile, the services' note. Parts 2-4 follow; the balance pass stays paused.

## The endgame playtest ends; what depth is for (7 Oct)

Matt stopped the playtest at 3.8 h with the campaign done, the map seven of fourteen ranks spent and the
ransacked streets dug to depth 8: "what am I climbing depths for? Classic ARPG issue but we need to solve
it somehow." The save shows why: past the campaign every site at a depth is the same fight and drops the
same pool at the same item level, so the easiest site's depth 8 is worth the hardest's and one site dug
is every site dug; the stations that exist (the heads at full strength at 10, the lorry at 12) are
unreached and unnamed; the map is an afternoon; the move is offered as a way out, not a reason. The
answer is written up as "The endgame (7 Oct 2026): what depth is for" in concept.md, four parts in
order: a site's level (tier + depth) driving the curve and the item level, so the ladder is nine
ladders; the lorry as the ending and the move as a compounding loop (the ladder's floor by move, a free
yard node a move, the wall as the score); one deep-only unique a site as the chase; the map at
thirty-six nodes as the long tail. Mocked first: Runs-D on the canvas (the level as a badge on the
band, the finds' item level, the ladder as twelve rungs with the stations marked and named). Map-B and
Yard-E follow once the spine is agreed. The balance pass stays paused until all four parts are in.

## The rarities' colours (7 Oct)

Matt: "the rig is legendary, post bag unique and helmet rare - they all look the same. uniques could be
pink? legendary should stay gold. not sure about rare? do we use blue?" Rare wore the amber warn tone,
Legendary an orange a shade off it, a unique the legendary's, and the pick ring was the same amber.
Mocked as Rarity-A; built as B: Common none, Uncommon green, Rare blue (`Pal.RARE`), Epic purple,
Legendary gold (`LEGENDARY` f2c94c), Unique pink (`UNIQUE`), Set teal, and the ring round a picked cell or
bench tile white (`Pal.PICK`), so gold only ever means a legendary. One rule for every cell, chip and
tile: `Pal.item_tone(it)` (a set's, a unique's, else its rarity's), used by the cells, the bench, the
Lock-up and the item head. The caravan's and the map's tiles keep their amber ring: those are trees, not
items. Smoke: the six tones each their own and none the ring's or the plain text's; a unique's cell
pink; a picked cell's ring the pick ring.

## The smoke wrote over the player's saves (7 Oct)

Matt: "you wiped fiat_slot1.save?" Yes - the smoke did, every run: its slot round-trip saved to
`user://fiat_slot1.save` and its lost-camp check wrote and removed `user://fiat.save`, the real autosave
and slot 1 on the Legion. The shell's save paths are instance variables now (`save_file`, `slot_file`,
the old constants their defaults); the smoke and the shots point them at files of their own
(`smoke_autosave.save`, `smoke_slot%d.save`, `shot_*`) and remove them at the end, and the smoke records
the size and time of every player save at the start and checks them unchanged at the end, so it cannot
happen again without the run failing. The slot Matt sent that morning is in `saves/fiat_slot1.save`
(gitignored) to copy back to `%APPDATA%\Godot\app_userdata\Fiat\`.

## The map in the caravan's shape (7 Oct)

Matt, reaching the map for the first time: "needs to look similar to the caravan for point selection - it
looks out of place against everything else." It was a list, a row a passive with a button each. Mocked as
Map-A and built as `scripts/ui/atlas.gd`, in the Runs room where the columns stand: a band (the points
free as the headline, what earns one at the right, the zones' depths as chips; 170 tall so the chips sit
under the headline), the six passives as tiles in three columns by what they touch - the sites (Picked
over, Deeper pockets, Quiet roads), the crews (Paid in notes, Two of everything), the air (Word travels)
- each with its ranks as pips, lined in the accent once a rank is taken, the column head counting its
ranks; the sum strip as chips (own finds, notes, heads, searches, the word, gangs; muted where nothing is
taken); and the panel: the pick's name and rank, its figure as a chip with the next rank's beside it,
one sentence (`FIGURES` in atlas.gd), Take a rank and Start the map again at the right. Picking a tile
fills the panel; the per-row buttons went. `tests/shot.gd` has a `map` mode. Smoke: six tiles inside
the room and apart, the pips a passive's max and lit to its rank, the six sum chips, a pick fills the
panel and a rank through it takes.

## The Runs screen's lag, and a depth as a fresh site (7 Oct)

Matt: "there's still lag on run selection when odds are calculated - enough to annoy me ... now I'm
selecting depth it's really noticeable." On his save a dry run cost 20-90 ms (T8 at depth 1: 92 ms), and
the Runs screen ran three a tier for nine tiers every 0.1 s refresh: half a second of stall a refresh,
and a depth change re-read its tier the same way. Three things: `Items.base_of` was a scan of the base
table and is called a few hundred times a tick - an index by slot and name halves a dry run; a read
that is plainly settled settles early (`EARLY_RUNS` 8 all alive with HP never under half, or all dead,
reads as the lookout's full count - the safe tiers, most of them, read in a third of the time); and
the shell reads the odds a few milliseconds a frame rather than a count a refresh (`main._read_odds`
from `_process`, `ODDS_MS` 5, the zone on screen first, then the rest; `sim.odds_time_ms` and
`odds_frame_start` are the brake: no new dry run starts past it, one always runs). The screens show
`odds_now` (the read so far, never running one) and say "reading the odds" until a tier settles; the
radio reads the same way. Smoke: a refresh settles nothing itself, one frame's odds take under the
brake plus a dry run, every tier settles, and a level-90 runner on the first site reads a settled 100%.

Matt: "depth needs to reset the site being picked over - otherwise where's the incentive." A site's
wear is kept with the depth it was cleared at (`worn_depth`, saved; an older save takes the depth it
stands at): another depth is another site, fresh; back at the worn depth it is still picked over until
it recovers, so flipping depth is no way round the wear. Smoke: a depth deeper reads fresh, back at
depth 1 still picked over.

## The clinic's two jobs; the caravan's sum as chips, a node as a chip and a sentence (7 Oct)

Matt, from the first play of the morning: "I should be able to heal my HP and treat the wound separately -
two separate buttons"; the sum strip's tiles clipped; "the two lines under what the skill point does are
repeated on every single skill point and are completely useless"; the node words need a language pass and
"the stats can be better displayed in the chip style across the board". Mocked as Clinic-B and Caravan-E;
built as mocked.

*The clinic.* Treatment is two jobs priced apart: `heal_cost` (the HP back at TREAT_CASH_PER_HP a point),
`wound_cost` (WOUND_CASH a level), the clinic's discount on both; `heal()`, `treat_wound()`, `can_heal`,
`can_treat_wound`; `treat()` and `treat_cost()` stay as both (the bot, the old tests). Four tiles (Resting,
Heal, The wound, Clinic) and two buttons side by side under them: Heal and The wound, each with its price,
the one that applies the primary, the other reading what it is (Fit, Fit for duty, No wound, The runner is
out); the bar names the wound. Smoke: at full HP the wound's button is the primary and Heal reads Fit; hurt
and wounded the prices add up to the old one, Heal heals alone and leaves the wound, The wound clears it
alone; the two buttons apart; the bar's words.

*The caravan.* The sum strip is one line - "Add up to" and eight key-value chips (`Chips` takes a count
now; the key as the chip's small tag, green, muted at zero, the notables in the accent) - 46 px tall where
the tiles took 100 and were cut off at the foot. The node panel: the node's figure as a chip in its tone
(`_chip_words`: a plain node's figure, a notable's figure where it has one, Keystone, Capstone;
`_effect_tone`: an element's colour for its damage or conversion, the accent for the notables, green
otherwise), the type as a muted chip, and one sentence after them (`_sentence`: the node's own words, or
`PANEL_WORDS`, rewritten as what happens rather than the figure again: "The fight and the search go
quicker."). The capstone's wants line stays. The notables' words that restated their chip were rewritten
in `data.gd` (the five conversions, Rifleman, Shotgunner, Spray, Bodger, Through the lot, Night work);
every other notable's words already said what happens. `tests/shot.gd` has a `node` mode. Smoke: the
eight chips shown and inside the strip, the node's sentence after its chips and ending in a full stop.

## The Yard, again: the works on one card, and the rail says so (7 Oct)

Matt: "the character stats are good but there's a whole load of cards there that either duplicate info or just
don't need to exist - the glaring issue is yard upgrades live there and nothing ever tells the player to go
look there." Mocked as Yard-C and Yard-D on the canvas; built as C's bottom with D's bench row (Matt: "I'll
go with your pick"). The left two columns keep the four cards that are the run and the runner: Runner,
Elements, Finds, Last run (`YARD_SLOTS`). The right two columns are two cards two wide. *The yard*
(`yard_works.gd`): a row a job - Generator, Lookout, Kennel, Stash, Bench - with its level, what it does
now over what the next does (`_yard_jobs` gives the forms, longest first), and its own Build button
(the price in it, the price alone when the long form will not fit; "Built" at the top), so no job hides
behind "the cheapest first, the rest in a note". The Bench room keeps its own button. *The town and the
purse* (`yard_town.gd`): the zones with their depths, the trade and what opens the next zone on the
left; cash, notes and scrap, kit worth, the stash's cells and prices on the right; the clock and the
autosave in the foot, Move the yard at its right when the yard can move. The town, cash, works and log
cards go (the log sits under every room). The rail's Yard button carries an "Upgrade" badge whenever a
job on the card is affordable, as the fence's "Ready" does for a contract, and clears when it is built
or the cash drops under it. Smoke (`_yard_wide_checks`): the four cards in the left columns and nothing
under the wide pair, the pair apart and in the right columns, the five rows in order, every button off
with no cash and reading its price, the badge off with no cash and on with every job affordable, a
press builds the kennel, the purse's cash line, Move the yard shown only when it can; the fit check
reads both cards' text.

## Two pieces, two boxes (7 Oct)

Matt: "each piece of gear needs an outline similar to everywhere else so the runs you and them have a
border - the gear needs that too so its easy to see side by side you're looking at two pieces of gear."
Mocked as Pick-B on the canvas (each column in its own box on the run screen's line, the pick's in the
accent; a third panel with both on the plain line) and built as the first: `pick_panel.gd` puts a box a
column (transparent, 1 px, radius 8, `BOX_PAD` 12 inside; `Pal.ACCENT` for the pick, `Pal.CARD_LINE`
for the fitted or the right column's words), the kicker, tag, head and the right column's lines inset to
it, the box shown with its column and off when the panel is empty. The run's pack, the Lock-up and the
Workshop share the panel, so all three have it. Smoke: `_pick_boxes_check` on the run's pick and the
Lock-up's - a box a column shown, every text node and the price tag inside its box, the two apart, both
above the foot.

Art, the gaps (checked on the Legion against the manifests and the code's hooks): the items are all
there but the deeds (every other paper draws `paper.png`; the deeds are kept out of that on purpose and
have no picture: `art/items/the_deeds.png`, 128 × 128); the three bosses' heads have a manifest and no
pictures (`art/people/the_carpet_man.png`, `the_manager.png`, `the_quartermaster.png`, 128 × 128; the run
screen looks for them when a boss is on); `art/studio.png`, the intro card, optional. Matt reuses
Greenhorn's. Zone art waits for a design pass (the run view, concept item 3). Matt: no further number or
heavy art decisions until he has played the campaign through and put ten to twelve hours into a save.

## The dots as the end of the bar (6 Oct)

Matt: "health bars need to show dot damage as part of the bar so you can see how much of each type you are
receiving or dealing", then on the first cut (the lost part coloured by what took it): "the poison, bleed
etc should be the actual bar that moves down, not detached from it." So the dots' pools are the end of
the fill: what fire, poison and bleed still have to take off them sits at the right end of their HP fill
in the elements' colours, a segment a type, and the fill goes down into it as the dots tick; yours the
same for what is on you. `_bar(d, fill, text, tone, pending, of)` lays the pools from the fill's right
edge leftwards, never past its left end; no pools, no segments (the search bar). Item 37, the pack grid,
goes to the backlog at Matt's call; the pass starts after 34, 35 and 36. Smoke: the pools' widths from the
amounts, in a row at the fill's end, cut at the fill's left end, cleared with the dots.

## The bench on the pick frame; a typed part refused (6 Oct)

Matt: "Gun attachments need the same chips treatment as everything else - also I can still attach a shotgun
only part to a rifle." The bench's Guns and Sockets views use the pick panel now: the part at the left
("THE PICK · IN THE STASH"), the one on the mount at the right ("ON THE PRIMARY · OPTIC") laid the same, or
"Empty" with what fitting it does to the gun's damage; the verdict and the deltas (the gun's damage a
second, then each stat the part moves); Fit at the right, Strip for a fitted part picked. Sell is gone from
the bench, the craft view's too. A part made for a type is refused on any other gun: `sim.fit_refusal`
says why ("Shotguns only", "SMGs only", "Improvised guns only"; `Items.only_words`), `can_fit` gates
`fit`, the panel greys Fit with the reason, and `attachments_for(mount, gun_type)` leaves such parts off
the lists the bots fit from, so a choke never outranks a part that goes on. The craft view keeps its own
panel until crafting (34) rebuilds it. Smoke: the choke refused on a rifle and left in the stash, Fit greyed
with the reason, a red dot's verdict and fit through the frame, the fitted part's Strip, the lists by type,
the words.

## The pick panel, Pick-A (6 Oct)

Matt: "the display on the left should be exactly the same as on the right so you can clearly compare both
items"; drop the ditched line and the fence line for a price tag; the run and the Lock-up consistent; no Sell
in the Lock-up (the fence's); Equip or Ditch on a run; use the dead space. Mocked as Pick-A on the canvas
and built as `scripts/ui/pick_panel.gd`, one widget both screens use: two columns of the one shape, a kicker
with the place and the cells ("THE PICK · IN THE PACK · 9 CELLS", "FITTED NOW · 9 CELLS") and a price tag
at its right, then the item head. The head's open slots, a set's words and "No affixes" are chips in the
affix rows now (`ItemHead.ROWS` 0, the cells chip optional), so the head is 190 tall and the foot has its
44. The foot: the verdict ("▲ Upgrade", "Sidegrade", "▼ Downgrade" by the slot's score) and the deltas
against the fitted, dropped from the right past the buttons; under them the item's own line, or a hint
when something stops a button. The right column is words where there is nothing to lay the same (a med's
rig, a part's bench, a paper's drawer, "Nothing fitted as armour"). Buttons at the right: on a run Equip
and Ditch (a med or rounds: Take into the rig, Ditch), in the Lock-up Equip and Bench, Unequip and Bench
for a fitted piece, Take or Leave for a med; a paper has none there. `sim.equip_from_pack` fits gear found
on a run, what comes off going into the pack, so it needs the cells the swap frees plus any more the fitted
piece takes; otherwise Equip greys and the hint says "No room in the pack for what comes off (12 cells)".
Also from the playtest: the run's rig showed a two-pouch kit as one pouch, so a full rig read as having
room; it lays items by their size now like the Lock-up's. Smoke: the two heads side by side, the kickers
with the cells, the tags, the verdict and deltas, Equip and Ditch, the swap into the pack, the full pack's
hint, the Lock-up's frame without Sell, everything fitted; the rig's pouches add up to the rig. Reviewer: a
smaller backpack or rig found is measured with it on (what's carried must still fit); the rig's row-end skip
only when the cap allows it, so a full rig of kits and meds shows every item and no free pouch; Bench on a
fitted piece keeps the slot picked.

## On them, on you: the dots as chips (6 Oct)

Matt: "on you: poisoned - the poisoned etc should be in the chip format. also add an 'on them:' line under
the enemy". The run's fight box has a row under their HP bar, a muted "On them" key and chips in the
elements' tones (Burning, Poisoned, Bleeding, Chilled, Shocked; `sim.dots_on_them()`, nothing while no one is
there), and the runner's note line becomes an "On you" key and chips when their fire has left something on
the runner, the med in use riding beside them as a muted chip with its seconds; the line is the chips' alone
("Press a pouch to use its med" and "No meds in the rig" are gone, Matt: they said what the rig's head says),
and the rig's head reads "The rig · use an item in the rig". The fight box grew a row (`FIGHT_THEM_Y`, `KEY_W` 88) and everything under it moved down;
twenty pixels stay above the buttons. Smoke: four chips on them in order, two on you, the med as a third, the
row gone with no one there, everything cleared, each fitted and inside its box.

## Chips everywhere: the word and the affixes (2026-10-06)

Matt's call: the radio's words as chips on the Runs card and the radio alike, and gear affixes as chips
coloured by tier, so one shape reads the same across the game. Built from the canvas board (Chips-A):
`Chips` takes items as dictionaries ({forms, colour, tag, tail}), wraps to `rows` rows in `show_chips`, and
lays one full-width chip a row in `show_rows` (the name in its tone, the effect muted inside the chip as the
tail, shortened by clause). The Runs card's THE WORD box holds four such rows (the radio's words first, the
sky's after; a fifth is dropped off the end, the reviewer's catch) over the site's line, now one sentence-
fitted row. The radio's site cards use the same rows (`Card` takes `"word_rows"`; `Missions.word_rows` and
`word_tone` are the shared helpers). The item head's three affix rows are a Chips over two rows, each chip
in its tier's colour with the T-tag inside and the short words; the open line, a set's words or "No
affixes" sit under. Smoke: the Runs rows carry a tail each and cap at four with five words showing none
past the site line; the radio card's rows match its words, tone and position; every affix shows as a chip
over two rows at most, in its tier's colour, with a three-affix piece fitting.

## The A style, screen by screen (2026-10-05)

The design canvas's A layout, built. Shared pieces first: `scripts/ui/band.gd` (the art band: a sky in the
zone's tone, a skyline of blocks seeded from the site's name with the odd lit window, a fade into the card;
kicker, title, headline in a tone with its unit, up to three right-hand lines, a chip row or a progress bar
along the foot; `set_words`, `set_right`, `set_chips`, `set_bar`, `set_site`, `set_tone`,
`headline_under_title`), `scripts/ui/chips.gd` (a row of chips with long and short words, dropped from the
right), and in `ui.gd` `tile` / `set_tile` / `tile_row` (a key over a figure on the dark ground, the figure
fitted from options), `head` (a section head in small capitals) and `shadow`. `tests/shot.gd` renders rooms
to PNG through xvfb (`xvfb-run -a -s "-screen 0 1920x1080x24" Godot --path . --rendering-driver opengl3
-s tests/shot.gd -- <save> Runs,Bench ../shots`), so a screen can be looked at as well as measured.

**Runs cards** (`missions.gd`): the band (tier · zone, the site, the odds in words as the headline with the
figure beside), six tiles (them, their fire, fight, drops, depth, rewards or the site's state), "They fire"
with the element chips, "They resist" as chips in the same shape ("Shock 40%" in its colour; "Nothing" when
they resist nothing), THE WORD head carrying the sky and the radio's note, three
word rows name-left effect-right (the effect shortened by clause with "+N"), the site's lines, the buttons as
before. The depth's −/+ stack at the right of the depth tile in the endgame. The three parts under the band (the fight,
the elements, the word with the site lines) each sit in an outlined box with a gap between, as on the run
screen. Smoke: the boxes hold their parts, sit apart and clear the note; the resist chips match the site;
the band's words inside
it, the odds bands fit the band's foot, the tiles' keys, the word rows right-aligned with an effect each, the
depth buttons inside their tile with a minimum no taller than their box, the sky's tone following the zone.
A reviewer pass caught the tone never following the zone and the depth buttons under Button's minimum height.

**The run in flow** (`run.gd`): the three left panels are one column. The band carries depth · zone, the
site, the clock as the headline, cash and gangs so far on the right, and the fight's progress as the bar along
its foot (the search's "Cleared" once the pool's down). Then THE FIGHT (on you, incoming, your fire, kills as
tiles; their HP bar, or the search bar and next gang / gangs so far / kills / found while picking over; the
crew head's face between the band and the tiles on a boss fight), THE RUNNER (your HP bar; armour, damage,
meds, rounds as tiles, rounds red when dry; a note: the med in use, what's on you, no meds, press a pouch),
THE RIG (the pouches as before), THE TAKE (cash, passed over, swapped, pack), the run's own line, the two
buttons. The fight and the runner each sit in an outlined box (`BOX_PAD` 10, the card line's colour, no
fill) with a gap between, after Matt found them running together; the rig and the take moved down into the
room under the note. Smoke: each box holds its head, tiles and bar, and the two sit apart. The hit numbers scatter over their bar, yours and the heals over your bar. Smoke: the band's words
and bar, the sections' order with no overlap, the tiles' keys, the face clear of the band and the tiles, the
hits on their bar and the reds on yours; a reviewer pass caught the face on the Kills tile, the Take button
missing from the fit list, and a same-size swap leaving the pick panel stale (swapped is in the sig now).

**The bench** (`workshop.gd`): the bottom panel is gone. The band carries "The bench · Level N" with what the
level fits beside it, the next level and its cost on the right (or "The top bench"), the Upgrade button at
its top right and Guns / Sockets / Craft along its foot. Each gun: its head (slot, figure, name), a chip row
(type, rarity in its tone, "5 fitted" in green), and its mounts as six tiles three across, the fitted part's
name in its tier's colour (`Pal.tier_color`) with the rarity's bar down the tile's left; a name too long for
its tile falls back to its first word ("Drum" under "Magazine"; `_short_names`), never an ellipsis. The
sockets view is the same shape, two tiles a group. Smoke: the band's level and words at every bench level,
the upgrade inside the band, a fitted tile in its part's tier colour, a drum magazine on a tile, and a bench
job on the craft view's piece showing without a re-pick (the reviewer caught the craft view's signature not
reading the piece: notes, last_craft and the piece's level, affixes and sockets are in it now).

**The clinic and the fence** (`vendor.gd`): the left column is one panel with the band at the top: the
vendor's face in it (`Band.portrait_width`), the clinic's level or the fence's prices as the kicker, the name,
the headline (the runner's HP; the stash's worth to the fence) with its unit fitted from forms, the tabs
along the band's foot, and what the vendor said as one line under the band. The clinic: TREATMENT (the HP
bar, resting / treatment / clinic tiles, the Treat and Upgrade buttons), YOUR MEDS (a tile a kind in the
stash with what it heals for you and over how long, the rig's pouches). The fence: SELL BY RARITY (four tile
buttons in the rarity colours, count and worth), BY THE BOX (the five boxes and the bigger shelf as tile
buttons), THE CONTRACTS head with open and ready counts (the tab has the lot). Smoke: both bands, the line
under the band, the tabs inside it, the tiles' keys and tones, the med kinds counted, the words clear of the
face, and a heal node trained elsewhere moving the clinic's figures (the reviewer's catch: the tree and the
class are in the vendor's signature now).

**The radio** (`card.gd`, `main.gd`): a card can carry a band (`"band": {site, tone, kicker, colour}`): the
title, headline and unit move into it and the lines start under it; a line's value can be forms long to
short, and a fourth entry tones the label. The radio's site cards get the Runs card's band (zone · depth,
the site, the odds in words with the figure beside), and each word is a row with its name in its tone (amber
harder, green easier) and its effect beside it, or on the row under when the two won't share one and there
is room (`_word_rows`; a word never takes more lines than the card has under its buttons). The set's card has
a band too: the set's name, its level, what it hears, the next set and its cost. Smoke: the band carries the
title and odds, the first row sits under the band, the word's name is in its tone, the set's band.

**The caravan as D** (`barracks.gd`): the band carries the runner's face, class · trait, "N of M points free"
as the headline, the trait's line on the right and the five class buttons across its top right. Each tree:
its head, a rail down the left (filled as far as the tree is taken, a half-taken row filling half; a tick a
notable, amber when taken; the taken count over it, the tree's size under), and the nodes as tiles two
across in the tree's order (`_tile_rects`), the keystone the width, ★ a notable and ◆ the keystone, the name
left and the cost right on the first line, the effect under (a notable's words cut to their first clause).
The drawer and the shelf keep their full-width rows, no rail. Under the trees a strip of what the small nodes
add up to (damage, max HP, first shot, search, gangs, loot quality, loot quantity, notables taken and open);
under that the panel as before, the face gone to the band. Smoke: the band and the classes in it, every tile
inside its column with none overlapping, the keystone the width, the rail's fill inside its track and full
on a full tree, the sum strip's keys, the drawer paging by what the column takes, and a gun swap refreshing a
typed node (the reviewer's catch: the gun in hand, the level and the yard's trades are in the signature).

## The Caravan's middle head: back and next (2026-10-05)

The middle column cycled one way ("Next: Petrol ▸"); an overshoot meant going round all eight again. Now a
"◂ Petrol" on the left and a "Live ▸" on the right of the head, the tree's name centred between them
(`SWAP_W` 160 a side; a name that won't fit its button reads "◂ Back" / "Next ▸", `_arrow_text`). `_on_back`
wraps. Smoke: both buttons present, the name centred and fitting between them, next then back returns to
the same tree, back from the first wraps to the last, fit checks on the way. The checks caught "The rat man"
at 151 px in a 150 px button and the name at 166 px between 170 px buttons, which set the widths.

The design canvas holds the A style on every screen (Runs cards A picked; the run in flow, bench, clinic,
fence, radio as drawn; the Caravan as D, tiles two across with a rail). All built, each its own commit with
a reviewer pass before it; the clip probe over Matt's save runs clean (it caught the Runner card's
"Arm the quartermaster on Runs" at 355 px in 332: a card's note takes forms now, and the Yard drops
" on Runs" when the long one won't fit). The Yard and the Lock-up are as they were.

## The Finds card's figures, checked against a save (2026-10-05)

Matt's second save (8.2 h, 110 runs, a Poacher) read "+35% loot quality / Loot quantity +-5%". Both figures were
what the sim says: quality is Night eyes 20 + the Dog tag's find 15; quantity is the Snares' 12 + Knowing the
streets 3 − Rat's share 20. The "+-5%" was a sign bug: every bonus on the card went through `"+%.0f%%"`.
`Main._signed_pct` now reads "+8%", "−5%" or "0%" (rounded, so −0.2 is "0%"), used for quality, quantity, cash
and notes. Smoke: `_yard_checks` trains Rat's share, asserts no figure on the card carries a doubled sign and a
quantity below nought starts with "−", and checks the helper on −5, 8, 0 and −0.2.

Noted, not changed: at roll time `Items.roll` gets `loot_bonus() + rarity_bonus() + the intel's rarity`, so the
quantity figure feeds the rarity weights too (Rat's share takes 20 off quality as well as quantity); the "quality"
bonus scales the non-common weights (60/28/10/2), so +35% moves Common from 60% to 53% and Elite from 2.0% to
2.4%. Both are for the balance pass.

## The top bar (2026-10-02)

Level and HP on the left, where the runner is in the centre, cash on the right in semibold; the game's
name and the stash count are gone from it (the stash has its own screens). The top bar's labels are in the
fit check now too.

## No ellipses (2026-10-02)

Item lines were trailing off - "Common T1 improvised · 3…", "+16% dmg 1st lot, +8% pace, +…" - because the
fit check only ever saw the bot's random items, never an elite with three long affixes. Two things fixed
that. `UI.fit(label, options)` sets a label to the first of its options that fits, so every line that
carries item words is built long-to-short (`Items.figure_options`: "17 dmg/s · Common T1 improvised · 3
cells" down to "17 dmg/s · T1"; `Items.affix_options`: the long words, the short words, "3 affixes") and
the Fence, the Run's pick panel and the Lock-up use it. And the smoke test ends with a worst-case pass:
an elite of every base with every affix at its top roll and every mount fitted, in the stash, on the shelf,
on the body, in the rig and in the pack, then every room, every Lock-up slot and kind, every Bench mount,
every shelf row and every pack cell shown and fit-checked. Random content isn't a test; the worst content is.

## The Fence as a screen (2026-10-02)

The Fence is on the grid too (`scripts/ui/fence.gd`): the shelf down the left, a row per item for sale
(name, figure, tier and type, the price, its affixes), and the stash as the cell grid on the right. Pick a
row for its figures against what's fitted in that slot ("▲ Better than it") and Buy; pick a stash cell for
what the fence pays and Sell; Select many sells the lot. With nothing picked the panel is the sell-by-rarity
row (Common / Uncommon / Rare / Elite, with counts and worth) and the shelf's upgrade. The market cards are
gone from main.gd. On the Run panels the unit now sits beside its headline - "3 on you, 2 more", "80 of 100
HP" - instead of at the far edge.

## The grid drawn, and the check by glyph height (2026-10-02)

The run's note lines still clipped under the buttons: boxes that touched, with 24 px text in 26 px boxes
and the descenders drawn past the edge. The check now measures text by its font's height, centred in the
box - the rect the glyphs occupy, not the box - for both the overlap and the inside-the-parent asserts
(with a few px of tolerance for a font's line spacing), so a label touching a button fails. The Run's left
column is relaid again on that: Them 244 tall with three lines and a note, the Runner and the run 298 each
with two lines, a note and the button, 30 px lines throughout. The Bench's gun heads were 7 px into each
other too and are relaid.

The grid draws the container now: an outline per cell of capacity, in rows of eight, so a school bag is six
empty boxes with the finds sitting in them and the stash is six rows of eight (four a page). Cells are 112 px
(from 104) - 952 wide - which uses the room on the right and still leaves the compare panel under it 264 px
for its four lines and the buttons. Items flow into the outlines left to right; a row's leftover cells show
empty, which is honest: a rifle doesn't straddle rows.

## The Run screen and where loot comes from (2026-10-01)

The run is a screen now (`scripts/ui/run.gd`), not four cards: three panels down the left - Them (the
fight or the picking-over, their HP or the look's progress, the next lot), the Runner (HP, armour, damage,
Use <med>), the run (clock, depth, cash, Get out now / Stop auto) - and the pack on the right as the same cell
grid the Lock-up and Bench use (`inventory.gd` with `ditching = true`). Pick a cell for its figures, what's
fitted in that slot and what the fence would pay, and Ditch it; Select many ditches a few at once ("Ditch 3,
5 cells"). Under the grid the panel says what the pack holds in cells and, when it's full, what the next find
will swap out. The Ditch worst / Ditch junk buttons went with the cards; the automatic swap-the-cheapest rule
stays for auto-run and offline.

Loot now comes from the fight as much as the picking-over. A kill drops at 40–50% (was 20–30%) and drops
what they were carrying - guns, armour, helmets, rigs (`Data.KILL_SLOTS`, meds rarely). A look over the site
comes every 15 s (was 10) and turns up what's lying there - packs, rigs, a share of gear, and attachments
at 30% (`SITE_SLOTS`, `ATT_DROP`), with meds at 8%. The Scrapper's attachment share and the dog act on
looks. On a ransacked-streets run that moves the fight from about one item to two or three against the
look's four, and the Town's tiers, with bigger pools, drop more than they're searched for. The reader after:
tiers 2–5 at 0:18, 0:38, 2:03, 2:29, level 31 at 3.5 h - within the balance pass's spread.

## Shell

Storeys' (`scripts/ui/palette.gd`, `ui.gd`, `card.gd`, `rail_button.gd`, `menu.gd`, `fmt.gd`, the Inter fonts),
via Clade, with two extensions here: a card may carry four buttons in two rows (which takes the last two
lines' place), and a button with a `tone` is coloured that tone (`UI.style_button`'s third argument). Five rooms on the rail. "Missions" rather than "Mission Control" because the rail's name
label holds about fourteen characters at its size.

## Sim (`scripts/sim/`)

`data.gd` — the body's slots, the base items (with attachment slot lists on every gun), rarities, affixes, the
zone's three tiers, the market and medic constants, the XP curve.
`items.gd` — rolling items (slot, base from the tier's pool, rarity by weight shifted by loot find, affixes from
the slot's allowed set, attachment map), reading them, the per-slot score the Armoury uses for "best".
`sim.gd` — the camp: operator figures from level and gear (damage = primary + secondary/3, ×level and affixes;
armour → mitigation a/(a+100); carry from rig + pack), the mission tick (kill progress against the pool; enemy
dps × remaining × (1 − mitigation) against HP; drops a kill), extract / extract now / KIA, stash and market,
treatment, save.

## Checked

`tests/smoke.gd` (`godot --headless --path . --import` once, then `-s tests/smoke.gd`) builds the shell, runs a
cautious bot (deploys to the highest tier it expects to survive, bails at a quarter HP, fits the best of each
slot, sells spares, buys the best upgrade on the market), shows every room every ten missions with the label-fit
check, and round-trips the save. Under Godot 4.5 headless after the second slice: the depot is cleared after 34
missions and 1.7 simulated hours, level 35, no KIA (the bot bails at a quarter HP), a full tier-3 loadout,
£69k in hand. The test also drives the Armoury screen (pick a cell, equip through the panel, pick a slot) and
runs auto-run on tier 1 for ten minutes.

Balance notes from that run: cash piles up with nothing late to spend it on (the Workshop will be the sink);
the bot never dies because it extracts at a quarter HP, so whether KIA bites is for a human to find out; first
numbers for the tiers were far too easy (depot at 0.4 h) and then far too hard (14 hostiles at 1.6 dps each
killed any loadout in 25 s), so the enemy dps is low and the pools are deep — missions are 60–90 s.

Not yet opened in the 4.7 editor on the Legion.

**The lorry-fix read (12 Oct, the Legion, 31 jobs; docs/balance/summary_lorry_fix.md).** After the A/B reads (uniques on
their old bases moved nothing; with the lorries' multiplier off the moves in 16 h fell from 9-20 to 1-9), commit fc9db48:
`CONVOY_DEPTH` 8 to 10, `CONVOY_HP` 0.25 to 0.4, `LORRY_MULT` 1.25 to 1.12, the Scrapper's loot +10% to +5%. Nine red.
*The lorry split in two:* poison, frost, bleed and physical still take it at 1.5-7.9 h (the poison Paramedic 1.5 and
2.5 h with ten moves; the poison Poacher 2.3-2.7 h with ladders 29-30/18-21 at the first lorry, the next deepest 19/9),
while every fire and shock read but one never did - their Services stall at depth 6-8 (depth pace 0.2-0.9/h), so depth
10 is past their reach; before, Lorry watch brought it to 6. Every plain read stuck. Scrap 8.7 against 8. Read: the
lorry was never uniformly easy - poison is the outlier, and fire and shock plateau.

**Poison's full dose (12 Oct, commit 5905148).** Read from the lorry-fix read's end saves (a headless kit read): over the
cap wasn't it (only the fire Scrapper sat over, by 16). The poison builds wore the Rat Man's Bag (the bot takes it on
nearly every build, for its capacity), and `_dot_fill` - the Poacher's joint (the first shot on a gang at full stacks)
and the Paramedic's dose - multiplied by `dot_stacks`, which the Bag and the Overalls lift to 999: one shot was a pool
of thousands of seconds of the gun, and the Bag carried it gang to gang. `dot_fill_stacks` fills to the tree's stacks
(15 with Builds, else 5); the uncapped build-up from hits is the Bag's rule and stays. A smoke check holds the Bag's
fill to the tree's stacks. `CONVOY_DEPTH` back to 8; `CONVOY_HP` 0.4 and `LORRY_MULT` 1.12 stay. Also seen, for Matt:
the city (the Services, the lorry) resists fire and shock 20% and frost 10%, poison and bleed nothing - the order the
builds reach the lorry in.

**The poison-fix read (12 Oct, the Legion, 31 jobs; docs/balance/summary_poison_fix.md).** Nine red. *The fix holds:* the
poison Poacher's ladders at the first lorry 18/8 and 17/6 (were 29-30/18-21). *Every element build beats the lorry*
(latest 7.7 h), fire and shock included, and three plain reads of ten stick. *Still early:* the first lorry at 1.3-7.7 h
(median about 3 h) against the 16 it was sized for, and the loop runs to 9-15 moves on the poison and bleed builds
(the city resists neither), 1-6 on fire and shock. The bank's band 0.6-1.4 h (2.3x). Ladders' spread: the poison
Paramedic 19/7. Scrap: the shock Scrapper 9.3 against 8 - the loot cut didn't move it; the search pace is the source.

**The city's poison, the convoy, the Scrapper's search (12 Oct, commit c254b15; Matt: "do it all").** The city resists
poison 15% - bleed left open, not 10% as proposed: the reviewer caught that every zone leaves an open type (the band
check, smoke 2176-2178) and both would have grown from depth 8. `CONVOY_HP` 0.4 to 0.7, `CONVOY_DPS` 0.75 to 1.0. The
Scrapper searches 25% faster (was 30%), loot back to +10%. Found on the way, not fixed (Matt's call): the Runs card's
"They resist" row is one line of 313 px and silently drops chips - the city showed 2 of its 3 before today, 2 of 4
now. A smoke check counting the chips is written and held uncommitted until the fix is agreed. The Workshop's
"two sockets" check failed once on the same run (the known Workshop flake's area).

**The Runs card's resists wrap (12 Oct; Matt: "make the change", no mockup).** "They resist" runs to two rows
(`RESIST_ROWS`), paid for by the band (200 to 180, the rooms' one height) and the gaps between the boxes (12 to 9).
`show_resists` lays the chips; if the names still don't all fit (all five, past Kitted out) every chip falls back to its
figure in its element's colour, so none is dropped. The smoke counts the chips on each zone's first site and on a
site resisting all five at 70%, and holds them inside the elements' box. Waiting on the smoke (the watcher is on the
balance pass). Training's band: mockups of the class lines over the caravan (now, one pill, a pill a line, a pill with
brighter text, a fade from the right) sent to Matt.

**Committed (12 Oct): the resists' wrap and Training's pills.** Smoke clean on the watcher. Training's band: the class's
line and the notice on glass pills (`PILL_H` 28, a hairline between two), the text in `Pal.TEXT`; a lone line drops to
the notice's place. Reviewer notes left for Matt: the Runs card's band is 180 now and the run screen's still 200 (a
20 px step on Set off); the word box now ends flush on the note (0 px, was 4).

**The city/convoy read (12 Oct, the Legion; docs/balance/summary_city_convoy.md).** Nine red. Green now: scrap (every
build in the band), the ladders' spread. *The lorry:* the frost and poison Paramedics 1.8-3.0 h with 8-11 moves, the
bleed Doorman 3.4-4.1 h (8-10), the frost and poison Poachers 3.0-4.1 h; the fire Drifter never, the shock Scrapper
never and one fire Scrapper never - their Services stall at depth 6 (Lorry watch's convoy depth), depth pace 0.0-0.7/h.
The plain builds 6-23 h, three stuck. Read: the convoy's three heads in a row favour what lasts - chill, meds and
Guard, poison and bleed's pools - over fire and shock; a stronger convoy strands fire and shock before it slows the
Paramedic.

**The convoy-halfway read (12 Oct, commit d25a361; docs/balance/summary_convoy_half.md).** `CONVOY_HP` 0.55,
`CONVOY_DPS` 0.85. Nine red. The lorry: the Scrapper's fire and shock never (both reads, the Services stall at depth 6;
the shock Scrapper's depth pace 0.0/h); one fire Drifter read and one poison Paramedic read never; the rest 2.0-8.8 h,
the Paramedics fastest (2.1-2.5 h, 6-9 moves). Ladders' spread green. Scrap: the shock Scrapper 8.4 against 8. The
plain floor: three of ten stuck. The playtest build picked for Matt: the Scrapper as shock - the weakest at the lorry,
and it reads the scrap row too.

**Matt's playtest list (12 Oct, the shock Scrapper on the exported build; "just do it all").** Built, smoke clean in the
cloud copy (the device smoke hung on a mid-edit parse error - Matt to close it):
- *What came back*: off the columns. A button at the zone row's right while there's a tally (the zone tabs narrow to
  make room, and take the row back after Seen); pressed, the card drops under it at the screen's right, clear of every
  button (smoke: column 3's depth +/- included).
- *Contracts*: a gear, deep or affix ask pays at least `CONTRACT_OVER_FENCE` 1.5x what its pieces fetch - cash at the
  Fence's price, scrap at what they'd scrap for - from the slot's bases a find draws now (the loot tier and two under,
  held to the slot's top; no starting kit, site-only bases or socketables). A save's asks come up to it on load.
- *Split*: a stack of rounds or bottles halves into its own (Lock-up, rig or stash; the Racks count).
- *The Scrapper*: "improvised guns do 20% more damage" in the class line (the only class with no damage in it).
- *Portraits*: tools/pixellab_people_all_manifest.json, fourteen new heads to art/people_new/ (the Fence first, unstyled;
  the rest in its style), the Outskirts' gang new. art/people untouched.
- *Flavour text*: every base, ammo and attachment has its line and the Lock-up shows it (rendered: Incendiary shells,
  Antifreeze) - asked Matt where it's missing.

**The playtest-fixes read (12 Oct, commit 935d202; docs/balance/summary_playtest_fixes.md) and Matt's shock Scrapper
save (docs/balance/playtest.md).** The bot: the lorry green (every element build by 16 h), the ladders' spread and scrap
green; the Scrappers now take the lorry (fire 2.9 and 7.5 h, shock 5.2 and 10.7 h; the plain Scrapper on a Tooled-up
garage rifle and a Workshop gauss). Slowest now: the fire Drifter (3.8 and 13.7 h, depth pace 0.4/h). Still red: the
bank's band (0.7-1.7 h), the keystone/capstone hours (the physical Doorman), depth pace (four builds), the plain floor
(five reads stuck). Matt's save, 1.1 h played: deaths one in 27 and wounds 19% - both in their bands, the first read of
the two gates off play. The Shopping Centre was his wall: three runs, two cut and run, the death at level 13 (150
dmg/s); the Bank not reached in 68 minutes. Next playtest: the fire Drifter (the bot's slowest; his 10 Oct fire Drifter
reached the Bank in 47 minutes, a before-and-after).

**The new portraits wired in (12 Oct).** Matt's run of tools/pixellab_people_all_manifest.json: eleven heads (the Fence,
the medic, the five runners, the four gangs - the Outskirts' new) now in art/people; the Greenhorn faces moved to
art/people/greenhorn (a .gdignore keeps them out of the build). The three heads didn't run; the manifest's style image
now points at art/people/fence.png for them. Smoke: every zone has its gang's face and every class its own.
**The figures to match**: tools/pixellab_bodies_manifest.json, the five art/body_<class>.png redrawn at 208 x 488 into
art/body_new/, each from its class's new portrait (reference and style) in the old figure's pose (reference).

**The figures and two flakes (12 Oct).** Matt's Claude Code wired the five redrawn figures (art/body_<class>.png; the old
ones in art/body_greenhorn/) and evened them: `body.gd` draws every past's figure at one height, the widest (the
Scrapper) filling the gap's width, so heads and boots line up; the smoke reads all five the same height, none past the
gap. Two smoke flakes, both test state left by earlier tests, not the game: *Equip if better* (another secondary in the
stash could rightly beat the Van's Spare - the check now weighs the pistol against it alone) and *two sockets* (240
re-rolls could spend the cash first - the check now has the cash, and reads the Yard's third socket). Smoke clean.

**The lore pass (12 Oct; Matt: "just do it all"; docs/design/lore.md).** The notes as the spine: the crews hold the old
money for an exchange at par, the lorry is the collection, the Mint never stopped, and the radio's last line is the
decree ("Let it be done"). Built: the opening (three lines on a new camp); the radio (seventeen lines in three voices -
the loop, Kev, the army net - gated by zone and lorries, one every three runs home, a toast, the last on a pill in the
Radio's band, all of them on the Caravan's new Also page, The radio); the drawer as a book (every paper in the story's
order, gaps saying where; eight new papers, each its site's own - twenty-eight pages); the gangs by name with a line as
they arrive; a line on the Yard's list when a runner dies; a line for each trait, said of the one who stays. The
reviewer's catches fixed: the trait's line was said before the pick; two radio lines ran past a two-line card (three
now, and the smoke runs every line and every paper through the pages); the radio's chip is asserted on the row; "the
wall" is the retired's, so the dead go on the Yard's list. Smoke clean in the cloud copy; on the Legion the one
failure was the save check - Matt's game was open and autosaved mid-run.

**The odds at the gate, and the bot rushing the campaign (12 Oct).** Matt's fire Drifter (slot 1, 39 min): the campaign
done at 36 minutes, the Bank at 21, one run a site at depth 1, no deaths, no wounds, every card "Safe" - a regen
helmet and charm (+5 HP/s together) carried it. Matt: no numbers touched; record what a player sets off at, and play the
bot as a person does, then read a fresh save. Built: every run line carries the Runs card's odds at the gate (settled,
else -1), the site's fire and HP and the regen worn; the playtest read gains "The odds set off at", runs banded by the
card's words with deaths, wounds, cut-and-runs and the median regen. The bot's `RUSH`: no climbing until the campaign's
done (one run a site at depth 1, straight on when the next reads PUSH); the endgame climbs as before. The reviewer's
catch fixed: a part-read card logged its share as the odds. The Equip-if-better flake's second half fixed the same way.

**The rush read (12 Oct, commit 9dfd990; docs/balance/summary_rush.md).** With the bot rushing the campaign at depth 1
the campaign barely moved: the fire Drifter's Bank 0.59 and 0.68 h, the campaign done at 1.37 and 1.66 h (Matt's: 21 and
36 minutes); the element builds' campaigns 1.1-2.7 h. So the climbing wasn't the gap. What's left between the bot and
a person: the bot waits out its HP between runs (`advance` to full at the rest rate) where Matt pays the Clinic, and it
holds a site until the next reads 88% where Matt's regen gear made every card Safe. Matt's next save carries the odds.

**The body's figure (12 Oct).** Matt kept a 5-armour helmet and a charm for their +5 HP/s over 50-armour drops, and
the game's "better" called the drops the upgrade: a helmet or coat was scored as armour and half the HP, a charm by its
find alone, so regen and resists counted nothing in the arrow, Equip if better, the junk rules or the bot. Matt's
call, option A: score the body by survival where the runner is. `survival_value()`: HP, regen over the fight and HP a
kill, against their fire through armour and resists over the same seconds, at `front_tier()` (the open site that hits
hardest at its set depth); the fight's length held at the worn kit's (`front_fight`, every gun fed) so a piece's damage
and pace aren't counted twice. `compare` reads each way - damage, the piece's own job, and survival for helmet, coat,
charm and rig - up on one and down on none is better, both is a trade. The pick panel leads with "N% survival". The
bot's shop counts a charm's or rig's survival (`upgrade_gain`). Reviewer catches fixed: the front's key (bosses, words,
atlas), an easy front's 1 HP floor that hid armour, the fight read once a kit, the smoke's regen sized to its fight.

**The survival read (12 Oct, commit c9df501; docs/balance/summary_survival.md, 16 h).** Against the rush read, nothing
else changed: 8 RED to 7. The Bank's band green (the element builds 0.5-0.9 h, from 0.5-1.5); the lorry far sooner
(element builds 1.3-3.1 h, from 2.4-14.1 h) with more moves; the bot's wounds down (1-17% from 4-22%). Keystone and
capstone later for Doorman bleed and physical and the frost Poacher (5.2-7.6 h). New reds: depth pace (fire and shock
Drifter 0.3/h, fire Scrapper 0.2/h after hour 4) and the Scrapper as shock's scrap at 8.1 crafts a hour (cap 8). The
plain floor narrowed to the plain Drifter alone (Services 6), from three builds. Still far from Matt's 21 minutes.

**Parked for after the fire Drifter playtest - FIRST on the list (12 Oct, Matt).** The pick panel, from his Branch
Pistol vs Van's Spare screenshot (the verdict is right: the Van's Spare fires its secondary at full, the Branch Pistol
at a third above half HP): (1) `deltas_of` loops Data.AFFIXES, where damage_pct and speed_pct appear twice (gun rows
and attachment rows), so "2% dmg" shows twice and pushes the deciding deltas (dmg <½HP, dmg 1st gang) off the line -
dedupe by stat, plus a smoke assertion that no delta repeats; (2) a unique's rule isn't on its card - show the rule as a
line under the chips (mockup first unless waived). Then the playtest read: the Clinic-paying bot and PUSH from his odds.

**The campaign's gates designed (13 Oct, docs/design/campaign_gates.md).** Matt's design: tins for cash (a label only);
a boss a zone opening a room each (a new Outskirts boss, the Gamekeeper, opens the Clinic; the Carpet Man the Fence; the
Manager's deeds the Yard; the Quartermaster's military radio and tool roll the Radio and the Workshop); the papers
carry radio codes in place of words; a live radio line under the top bar, scrolling, no speaker names, the medic and
the Fence speaking on it once open. The art: tools/pixellab_campaign_manifest.json (16 jobs: the tin, the nine rail
glyphs to art/ui_new, the five unlock items, the Gamekeeper). Build order in the doc; the pick panel's fixes first.

**The pick panel's deltas (13 Oct).** A stat listed twice in Data.AFFIXES (damage %, pace, quantity: the guns' row and
the attachments' or charms') made its delta twice and pushed the deciding ones off the line; one delta a stat now, and the
smoke checks the Branch Pistol against the Van's Spare shows no word twice and both rules' damage lines. The Split
check's flake fixed (a Shells stack the smoke's runs left read as a third half). The unique's rule on its card: three
mockups to Matt (a chip, the tail line grey, the tail line in the unique's pink), short forms needed for all 49 rules.

**A unique's rule on its card (13 Oct, Matt: chips).** Every unique's card leads its affix chips with its rule in the
unique's pink (★); each of the 44 uniques has a `short` form in Data.UNIQUES, taken when the long one would push an affix
off (the item head's chips lay again all short then: `show_chips(..., shorten)`, the item head only - the Caravan's sum
keeps its own order, the reviewer's catch). The smoke checks every unique at every head width shows its rule first and
every affix. Armour % reads "armour" now, flat armour "arm" (they read alike in the deltas).

**Tins (13 Oct, docs/design/campaign_gates.md).** Everything is paid in tins on screen: Fmt.money "4,816 tins" / "1 tin" /
"12.4M tins", short forms "4.8k tins" and "4.8k" (Fmt.money_k, money_forms) for the tiles and buttons that "£4,816" fitted
and the unit outgrew (the multi-sell button, the Clinic's Heal and wound, the run's take tile, the Fence's rarity tiles;
UI.fit_button); the top bar shows the bare figure by its glyph; the Words, Data labels and lore lines that meant the game's
money say tins (the pre-collapse lines about real cash stay); "Every tin", "Found tins". Internal keys stay `cash`. The
smoke fails any label showing £, and checks the Clinic and the Fence at level 50 with a wound. The tin glyph waits on the
campaign manifest (art/ui_new/tins.png). Flakes fixed: the came-back card's firsts (papers read on the test's two runs).
Open: a toast with no full stop or comma to cut at can run past its box ("One of them is in the last Doorman's
hand-me-down nail gun.") - seen once, not from tins; to Matt.

**Toasts that can't be cut (13 Oct).** A toast takes the log's sentence cuts, then the line's own short form
(Words.short_line: "One of them is in the last Doorman's kit." for a lost runner's piece, cut at the person's apostrophe,
not a "butcher's chainmail"'s), then a smaller size down to 20 (the Deck's two-thirds); the smoke toasts the worst ones.

**The radio line (13 Oct, mockup C).** scripts/ui/radio_line.gd: the top bar's second row (Pal.RADIO_H 36), always on, one
line scrolling right to left at 70 px a second and never stopping, a pulsing dot, soft ends; no speaker anywhere (the log
says "On the radio: ..." - Words.RADIO_LEAD - and the Radio room's last-heard pill the words alone). A line just heard
is next (first heard, first played); with nothing new it plays what's been heard in turn, the loop's first before
anything. A click opens the Radio. A new or loaded camp starts it clean; a loaded camp's old lines aren't pushed. Radio
lines don't toast now. The 36 px came from the gaps, not the rooms: over them 24 to 8 (TOP_GAP), under to the log 16 to 8
(LOG_GAP), the foot 24 to 12 (BOTTOM). The smoke checks the row, the rooms under it, the scroll, the queue, a real click,
the clean start. Two old flakes fixed on the way (the bot's run finding the deeds before the deeds' check; the deeds
counted as a common the Fence wouldn't take).

**Codes, and the campaign art wired (13 Oct).** The Radio's words are codes on screen (the yard's Radio picks, the map,
the crafts, the Radio room, the Runs card's "THE CODES", the menus; the mechanics and the keys as they were); the
Fence's own "word in the right ear" stays his. The twenty papers that carry a code say where it's written, first on
their card (Words.PAPERS "code"; the drawer's story leaves it off); reading one logs "a code on it. The Radio has ...".
The art from the campaign manifest: the rail's nine glyphs from art/rail (UI.glyph "rail/yard"), the top bar's tin
(art/ui/tins.png), the Gamekeeper's portrait in art/people (for the gates), the unlock items in art/items. The smoke
checks every coded paper, the Radio and the Runs cards off the air and on it for the word, the rail and the tin loaded.
Needs the editor opened once before an export: the new PNGs have no .import yet.

**The rail's order and names (13 Oct, Matt).** Stats, The Kit (was Runner), The Map (was Runs), Training, The Clinic,
The Fence, Workshop, The Yard, Radio. The Caravan's gone from the words (Training, the drawer in Training). The Map's
card heads "ON THE AIR" (the sky and the codes). A painted rail glyph sits on a lighter stamp.

**The campaign's gates built (13 Oct, docs/design/campaign_gates.md).** A fresh camp has the Clinic, the Fence, the Yard,
the Radio and the Workshop shut (the rail says Shut, says what opens it, won't go there; the sim won't do their jobs; a
new camp starts on the Map). A new Outskirts head, the Gamekeeper (Top Farm, soft), and each head's things: his drop
opens his room there and then (Matt: the drop is the sign); the deeds come off the Manager now, not the Bank's first
clear, come home for the ending, and drop again while there's no ending and none held. A line on the radio before each
gate (once the head's site is open) and after; the medic's and the Fence's own lines in the turn once their rooms open.
A Yard building for a shut room waits on it. The convoy is still the three crews. Saves from before keep every room; a
move keeps them. The bot pays the Clinic whenever it's open and the price is there twice over, takes a first clear or
an unbeaten head at 0.65 (Matt's recorded odds) and farms what's cleared at 0.88.
**Open, to Matt: the ammo trap.** Rounds are only sold at the Fence, shut till the Carpet Man; a try-on reads every gun
fed, so Equip if better (and the bot) can swap the nail gun for a gun with no rounds and fall to fists. Four 1.5-2 h
Drifter reads: three ran the campaign (the Bank at 0:39-1:09, done at 0:57-1:25), one stalled at the Allotments on
3 dmg/s for the whole read. Options in the reply.

**The ammo trap fixed (13 Oct, Matt: 1 and 2).** With the Fence shut, a try-on reads a gun fed only if its rounds are in
the rig or the stash (the arrow, Equip if better and the bot alike), and Equip if better moves a box of them to the rig;
a gun found while the Fence is shut comes with a box of its own rounds. Four 1.5 h Drifter reads after: all four ran the
campaign (the Bank at 0:43-1:00, the Barracks at 1:06-1:17). The smoke checks the rifle with no rounds, with them, and
put on by Equip if better. tools/smoke.bat runs Godot through tools/run_limited.ps1: killed past 25 minutes, or when the
log ends on a script error and goes quiet three minutes - the watcher never waits for ever again (no restart needed:
the watcher calls smoke.bat afresh each time).

**The search as crates built (13 Oct, docs/design/search_crates.md; Matt: mockup B, a filing cabinet for papers, a
jewellery box for charms, the endgame map is the Dial).** A cleared site rolls its crates: the dice's order, no pick,
their searches adding to what the thinning gave in full (6 + 2 a depth, quantity pushes it); each search of the crate
in hand gives the usual finds, leaning to its kind (an ammo tin's rounds, a toolbox's parts and scrap, a medicine
cabinet's meds, a filing cabinet's papers and notes, a jewellery box's charms, a safe's tins and notes and doubled
unique odds, a military crate's guns and armour a quality up). The thinning is gone: all open, the site's picked clean
and nothing more is found; the auto-run, "Fill up, then go" and the bot go then, a Ghost counts it its clear, the
Lookout's Hold fire stops holding. The sites lean: the Bank's safes, the Barracks' and the Services' military crates,
the Shopping Centre's jewellery, the Hospital's medicine; no safe before the Estate, no military crate before the Town;
depth adds both. The Kennel's top rank noses each crate's best find at the clear: its rarity on the shut crate, the
next line says it, and it's that crate's first find. The run screen: the crates in the pick panel's place while nothing's
picked (a pick brings the panel back - the review: a pack cut to two rows split a 3x3 vest), the row of crates, what came
out of the last one, a ? under the magnifier, the bar, and "Next: a safe, three searches. The next gang's due in 0:34."
The fight box's bar names the crate. Crates save with the run. Placeholder line crates in each crate's colour until the
art's in: tools/pixellab_crates_manifest.json (sixteen, each shut and open, art/crates/). Fight drops not touched yet:
the balance pass. The Dial not renamed yet.

**Codes add crates (13 Oct, Matt).** A code's pay can carry crates: their weight on the site times its figure, grown by
the code's tier and the Radio's boost, and a crate the site wouldn't have yet, it has. Delivery day, Squaddies and
Kitted out bring military crates; Bailiffs, Overdrawn, Lock-ins and Foreclosure safes; Pawned, Shoplifters and
Everyone's in jewellery boxes; Laid off and Curfew filing cabinets; Checkpoints ammo tins; Wired toolboxes; Cutters
medicine cabinets. The code's pay says so ("military crates ×2"); the site's totals line doesn't add them up yet. The
smoke's upgrade-arrow check now uses helmets without pace (it flaked: on a front that can't touch the runner, the
faster Cycle helmet is rightly better than the slow Visored one).

**Locked crates and the Caretaker's Keys (13 Oct, Matt).** A jewellery box, toolbox, medicine or filing cabinet, safe or
military crate comes locked 15% of the time, over and above the site's searches. Without the Caretaker's Keys a locked
crate is passed over (a grey padlock; the head says "· 2 LOCKED"); with them it opens (an amber padlock), its finds a
quality up (+0.25). The Keys keep their event every run; their words say "every locked crate opens".

**The endgame map is the Dial (13 Oct, Matt).** The Radio's second tab, its band and title, Head start's words and the
log's point line say the Dial. The rail's The Map (the sites) stays; the band keeps the map's picture.

**The balance pass after the crates (13 Oct).** Gates set before it: the summary's gates as they stand, every one green
but the bot-timing ones (the bank's band, the keystone and capstone hours, the depth pace - Matt, 10 Oct) and the two
read on Matt's save (deaths, wounds); and the crates' own, a site's take (finds' sell value and tins, the search and
the kills) within 0.9-1.15 of the old search's on every site, by tests/crate_probe.gd. The probe first read the crates
at 0.85-0.98 (they'd dropped the thinned tail) and kills are a tenth to a third of a run's take, so the fight drops
stay as they are and the crates got the search back: THIN_AFTER 6 to 7; a safe's tins 1-3 to 0.5-2 of the site's cash
a search; notes a jewellery box 1.5 to 1.2, a filing cabinet 2 to 1.6, a safe 3 to 2; a toolbox's scrap 2.5 to 1.8; a
military crate's quality 0.25 to 0.4. The probe after: 0.93-1.12. The first pass read a third of the plain builds
stalled for hours under the Retail Park on tier-2 kit (the Fence and the Workshop shut till the heads; the same on
the code before the crates, three cloud reads each): the Parade's loot to tier 3 (the stuck seeds came through; the
Clinic's tier-3 meds arrive a site sooner with it). The second pass: the Bank 0.4-2.9 h every build (5.8 h one plain
Poacher read), the lorry by 5.9 h on the element builds, the plain floor by 17 h, cash, scrap, the clock and the loot
gates green. Red: the bank's band (0.6-1.4 h, 2.3x), the keystone and capstone hours, the depth pace (three builds
0.7 an hour) - all bot timing; the ladders' spread (Poacher as frost 13 past the barracks both reads, 9-11 the pass
before); deaths and wounds, on Matt's save. tests/balance.gd's probe sets the Gamekeeper down (it hung on the Estate's
gate).

**The crate art is in, and the pass read again (13 Oct).** Matt's sixteen crates (art/crates/, shut and open) draw on
the crates panel as they are; the editor makes their .import files before an export. The third pass: green as the second
but the ladders' spread now Paramedic as poison 12 (Poacher as frost 12 and 11: it moves build to build at 11-13 since
the crates, 9-11 before); the bank's band 0.6-1.8 h. Both plain Doorman reads held at the Carpet Man for three hours (the
Retail Park cleared at 0.8 and 2.1 h, the Town at 4.2 and 3.9), one of them at 6 damage a second for half an hour of it -
rounds out with the Fence shut, the ammo trap's edge. To Matt with the playtest.

**The crates are a toggle (13 Oct, Matt's playtest: a rig still picked when the fight ended hid the crates).** The fight
box's search bar is a button ("· show the crates"); the crates' own bar gives the pick back ("· show the pick"); one
search bar shows at a time. A new search opens on the crates whatever's picked; a pick in the pack or the rig shows its
comparison.

**A hammer to start (13 Oct, Matt: a bat found "trivialised ammo concerns").** A new runner (and one who loses his kit)
starts with a Claw hammer: 12 a second like the nail gun was, no rounds, never found; no nails in the rig. Melee sits
behind its tier's best gun now: the Spiked bat 20 to 17 a second, the Breaker bar, Demolition bar, Rescue axe and Door
ram a tenth down (the smoke holds every melee base under 0.9 of its tier's best gun). The Rounds tile reads "none
needed" for melee. The title's New camp line and the Yard's first line say a hammer.

**The floor (13 Oct, Matt).** By hand, a search's finds wait on the site's floor - the row under the crates, newest
first, nine a page - and go into the pack only when the player drags one there or double-clicks it, and only if it fits
(no swapping: the player chose it). A click shows its comparison with Take. What's left is passed over when you go.
Kill drops still go straight in. A thing ditched mid-run lands on the floor with its scrap paid, and comes back without
it (a ditched stack whole or not at all). "Fill up, then go" picks up what fits, dearest first, and from then on finds
go straight in, as on an auto-run, away, and for the bot (Bot.step sets loot_by_hand off). The pack-full lines say so.

**The pass on the hammer and the floor (13 Oct).** The Bank 0.4-2.1 h on every build but one Doorman as bleed read (4.2 h:
melee down a tenth); the lorry by 6.4 h, the plain floor by 11.4 h, cash, the clock, the loot gates green. The scrap
economy just over (Scrapper as shock 8.4 crafts an hour against 8, Poacher as poison 7.3 against 7): a toolbox's scrap
1.8 to 1.5, to read on the next pass. The ladders' spread (Paramedic as frost 12) sits at 11-13 build to build since the
crates - to Matt. Timing reds as before; deaths and wounds on Matt's playtest.

**The Kit room's bin (13 Oct, Matt's playtest: the stash full with the Fence and the Workshop shut).** A stash pick has
Bin: it goes for the scrap a ditch gives, gone for good; a unique or set piece asks twice ("Bin it: N scrap"); never
the deeds. With the Fence shut, Select-many's button bins the plain things ("Bin 4: 32 scrap"). Two smoke flakes the
hammer start shook loose fixed in the tests: the junk run's nails go to the rig now there's a free pouch; the Craft
view's piece picked by its cell, not its place in the list.

**Fixed in dceac06 (was parked, 13 Oct, Matt's playtest): a gate's "before" line keeps playing after its room's open.** The
medic's "Anyone near Top Farm: the keeper there has a vet's bag" still runs on the radio line with the Clinic open. The
cause: radio_line.gd's loop (`_next_line`) plays every line in `sim.heard` in turn, and a gate's "before" line stays
heard. The fix: the loop skips a `<head>/before` line once every room its head opens is open (the "after" lines stay);
the smoke asserts it - open the Clinic, and the medic's before line never comes round again.

**The run view, the slice (13 Oct, Matt: "proceed and build the slice so I can test").** scripts/ui/run_view.gd: a light-gun
frame over the run screen's fight and runner boxes - the Parade's test art (art/fight_test) on every site for now. The
gang up as many as are on you (three at most: by the car, close, a far doorway), each firing now and then; a kill drops
one; a hit jolts the frame and reddens its edges; the search pans along to the next crates in the street; your hands and
revolver bottom right with a kick at the gun's rate and a marker on the one you're hitting (guns only - melee shows no
hands yet). Their bar and chips over the frame's top, yours at its foot; six tiles under it (Fire in or Gang in, Your
fire, Kills, Armour, Meds, Rounds); the search bar under those. Without the art on disk, the boxes as they were. The
editor must import art/fight_test before an export (load() needs the .import; the off-disk read is the editor's only).

**The run view, from Matt's recording (13 Oct).** The faces' pictures are off the frame (their art is _left's, it kept
showing). A kill drops any of them, not the first every time; each shot of yours lands on one of them at random, a
marker and a white flash. You duck behind the wall now and then under fire and on a big hit - the wall comes up, the
gun goes down, no shots while you're down.

**The run view's numbers off the chips (13 Oct, 6a87054).** Your hits' numbers rise off the one you hit (about its chest),
what you take from the frame's foot right of your bar; a spot whose rise would cross a bar, the head, a key or a chip is
tried again, then the frame's clear middle right. The smoke scatters 120 with chips on both sides, and again with your
chips as wide as they go.

**From Matt's save (13 Oct, dceac06).** The gamble's price is GAMBLE_RUNS of its own base: a run's takings (Fence money
in), but one run home moves it GAMBLE_STEP (15%) at most - a clear-out creeps it up, never lurches it (305 to 2366 off
one sale before; the pass's saves had takings from 1x to 195x a run's kill pay). Takings themselves unchanged (the
contracts read them). "Out to ..., depth N" has no colon with no codes. The cache's words name no Bench. Matt picked
the capped takings over pricing off the item (steady but no late sink).

**The elements in engine (13 Oct, b695263).** On them, on every one up: fire - an orange tint, a flicker and additive
flames; poison - green and bubbles; bleed - red and drips; frost (chilled) - blue, flakes, and they pop and fire at half
pace; shock - a flash, a twitch and an arc across them. On you: the frame's edges in the colour of what's on you,
breathing. The chips' thresholds; nothing on them once the fight's over; the view ticks only while it's on screen.

**Seen once, not chased (13 Oct):** two smoke reds on one run that passed on the next - "an arrow stayed once the
better helmet went on" and "the log does not say what the bandage healed" (_class_trees' chain). Flakes; parked.

**The fight's full art manifest (13 Oct, 1a15aac).** tools/make_fight_manifest.py writes tools/pixellab_fight_manifest.json:
66 jobs into art/fight/ - a plate (688x296) and a taller cover (688x160, for the duck) per site, every plate asked for the
same layout (open ground centre-right, a far doorway left, room right foreground); two gang members a zone and the four
heads, each standing, firing, going down (128x192); your hands per weapon type, hammer and blade among them (256x192).
The Parade's plate is the test's, copied. Matt running it. Not wired in yet: the view still reads art/fight_test.

**The run view from the second recording (13 Oct, acab0ab).** Ducked, the wall runs on down to the frame's foot (the
cover's own bricks, cut from its lower 28% and tiled); the cover starts 20 px further right so it spans the frame at the
search's pan too. The figures stand by their feet; the far one down the street at the kerb, 0.32. The crates stand on
the ground in depth with a shadow each, riding the pan in; a magnifying glass bobs over the one being opened, its ring
the search so far.

**The fight's full art wired (13 Oct).** All 67 of the manifest's pictures landed in art/fight/ (the Garden Centre's plate
on a retry). The run view takes each site's own plate and cover as a pair (else the Parade's test pair), the cover's drawn
top on its line whatever its height, the wall's fill cut from it; the zone's two gang members, one picked as each comes
up; the head drawn as himself while he's out (each figure keeps whose picture it came up with, so the last of the gang
falls as gang and the head falls as the head); the hands for the gun's type (a blade's for a bleeding edge), each tucked
into the bottom-right corner by where its picture ends, at 0.85; feet on the slots by where each picture's drawn part
ends. The smoke: every site resolves its pair, the cover's top, the zone's gang, feet on the slots, the heads, the
head's arrival and fall, the hands' corner. art/fight isn't committed (Matt's); the editor must import it before an
export, and its import stays Lossless (the feet and the cover's top read the pictures).

**The figures placed, and your hits on your shots (13 Oct, Matt's playtest of the full art).** The near one left of
your gun (405), the middle one in from the right (255), the far one on each site's own ground down the middle, read off
each plate (SITE_FAR), between the other two; the hands at 0.8. The smoke checks every site's far spot (above the wall,
smaller, clear of the other two) and, pixel by pixel, that no gun's hands hide a third of the near one. Your gun's hit
numbers are held and come out on the frame's shots, on the one hit - none while you're ducked (what's dealt then comes
out on the first shot back up) or between shots; the ticks of what's on them show as they land (the sim counts them
apart: m.ticked_by, display only). Time away from the run screen isn't saved up for one big number. The enemies' bar
is still the truth and drains between shots. A sound fix on the way: a load that winds the clock back reset the gun's
and the hits' stamps with it (the gun went quiet till the clock caught up).

**The second placement pass (13 Oct, Matt's playtest of the Outskirts, the Estate, the Town).** Sites can move the
middle and near ones too (SITE_MID, SITE_NEAR): the Allotments' middle one right of the water butt; Ransacked Streets'
middle one left of the sofa, the near one right of it, the far one over on the right pavement; the Pleasure Park's
middle and near ones further left, the far one between. A figure coming in fades in where it stands (0.35 s) - no more
rising up through the floor - its flames fading in with it. The smoke checks every site's three apart and on their
ground, and a figure half way in half there with its feet down. The City's sites wait for Matt's playtest.

**The fight's placement tool, F3/F5 (13 Oct, Matt: "Greenhorn's F3/F5 - each enemy a zone I can drag and drop").**
scripts/ui/fight_placement.gd, cut from Greenhorn's hotspot_placement_overlay.gd to what the run view needs. Debug
builds only; on the run screen, on a site with its own art: F3 holds the game (the sim stops), clears the bars and chips
off the frame, and stands all three of the gang on their slots, outlined and named (middle, near, far) with a dot at
their feet. Drag to move one's feet; its bottom-right corner or the mouse wheel sizes it, feet kept. F5 saves the site's
three to data/fight_slots.tres (a Resource, so it ships in an export; other sites kept), F4 prints them, F3 again lets
the game go on. Saved spots win over the tables (SITE_FAR/MID/NEAR, SLOTS). Leaving the run screen lets the tool go.
The smoke drives it end to end against a user:// file. Matt's saved spots are checked only for being in the frame.

**The opening (14 Oct, Matt: "new game -> fade from black to an art sequence").** scripts/ui/opening.gd, on New Game
before the first screen: six scenes (2028, 2029, 2031, 2032, 2033, Now - the Pitch), each a picture from
art/intro/scene_N.png (the white bands the generator left trimmed off) and its lines from words.gd's OPENING_SCENES,
read aloud by Matt's takes in art/intro/voice/. Each line comes up on its cue in the take (read off a word-timing pass);
a click, Space or the pad's accept moves the reading on to the next line, then the next scene; Esc or the pad's cancel
skips to the game. With Sound off the takes are unheard and the lines keep their time. Without a take a scene falls
back to a fixed time a line. The smoke checks the cues against the takes, the lines on them, a press moving the take,
and no white band at the picture's edges.

**The Yard is the Pitch (14 Oct, Matt: "The Pitch is good too for the rename").** On screen only: every word the
player reads, the room on the rail, Move the Pitch, the common tree ("The Pitch", its nodes "The Pitch/N"). Code and
save keys keep "yard". An old save's "The Yard/N" (and the older "The yard/N") nodes load as the Pitch's. The smoke
fails any shown label that still says "Yard".

**The rooms' first visits (14 Oct, docs/design/room_intros.md).** scripts/ui/room_intro.gd: the first time each of the
nine rooms is on screen, a card over it - the room's place art, who runs it (the medic's and the Fence's portraits;
the narrator and Kev without), their lines read by Matt's takes in art/intro/rooms/ on cues read off them, three tiles
naming the screen's parts, "Go on". A press brings the next line then closes; Esc closes; the game's held while it's
up. Rooms met go in the save (an old save has met what it has open); not over a menu, the opening or a run's Map. The
"?" on the rail's ROOMS heading brings the room's card back. Kev's Manager line says "a pitch" now.

**The cog (14 Oct, Matt: "a cog ... top right that opens the game 'esc' key menu ... for the deck").** At the top bar's
end: the pause, or back out of a menu, as Esc. Drawn in engine (a ring, eight teeth) until one's painted. Room for it:
the place shrinks to its pin when the purse is full, and the HP/XP/damage lines went 180 to 160. The smoke checks the
purse at its widest clears it, and the pause open and shut by it.

**The melee swing (14 Oct, Matt: "we need an attack frame for melee ... the action just hangs"; in engine first).** A
hammer's or a blade's picture splits where a clean column parts the off hand from the weapon's; the weapon's arm winds
back, chops toward the one it's hitting round the forearm, and settles, a streak following the head. The hit - its
marker, its number - lands on the chop, not as the swing starts; none if the hands go down behind the wall mid-swing.
Guns keep their kick. Generated swing frames only if this doesn't sell it.

**The warnings cleared, and a check for them (14 Oct, Matt: the editor's Debugger full of GDScript warnings; "a way
of checking in the future and clearing before commits").** All 278 in the game's scripts fixed in code: whole-number
divisions marked as meant, locals that shadowed a property or a function renamed, unused locals and parameters gone or
underscored, mixed ternaries and float-to-int narrowing typed properly, a signal never sent removed. tools/gdlint.py
asks Godot's own language server for every warning in the project (the smoke, headless, can't see them); it reads 0,
and runs before each commit from now on.

**On the air (14 Oct, docs/design/on_the_air.md).** The campaign's close and the endgame's door: the Quartermaster's set
home, the Radio open, and Kev on it in three scenes - Channel 19 (the set), Long wave (everywhere else gone dark, the
army's lorries), The codes (the papers' codes are frequencies; deeper, more to hear). The opening's player
(Opening.new(Words.AIR_SCENES)): Matt's pictures (art/intro/air_N.png) and Kev's takes (art/intro/voice/air_N.mp3) on cues
read off them. Once, at home, before the Radio's own card; never for a save that had met the Radio.

**The seven silent sounds wired, and the flaky checks (14 Oct).** grenade, reload, duck, no room, the dog at the crates,
the set coming on as the Radio opens, the deeds burned or sold (finding them no longer plays the fire). The four flaky
checks: two causes fixed (the gun's look inside its slowest beat; a test swing with nobody standing), two found and
guarded (the odds read with a run left on; the upgrade arrows' cache missing the front's weather and night - a real
one), each failure message now carrying the state that would explain it.

**Settings (14 Oct, Matt: a Settings row with sound, music and room intros).** The pause's Sound row is Settings: a card
with Effects, Music and Voice (each its own bus, a press steps 100, 75, 50, 25, off and round), Room intros on or off,
Back. The voices (the opening, On the air, the rooms' cards) are the Voice bus. An old settings file reads as it did
(Sound off: the effects and the voice off). A pad stays on the row it pressed.

**The search under the fight art (14 Oct, Matt; mockups search_mockup3/4).** The crates moved from under the pack into
the left column under the six: the take folded into their head, the tiles ("+N more" past five), the floor, the rig
under them. The pick panel stays the pick's, so a thing on the floor compares against what's worn; the toggle's gone.
The search's bar sits at the frame's foot in your HP bar's place till a gang comes. A crate opened is set down open at
the front left, "Opened · N finds", for two seconds, the bar naming it. HP low puts the warning on the crates' head.

**The next gang's clock holds while a gang's on you (14 Oct, Matt: "no search time before the next gang shows up which
just compounds").** It ran through the fights: on the Allotments with the starting kit the first gang took 19 s, left
1 s of quiet, and the gangs on you went 2, 3, 5, 8, 12, 17, 23 - one search a run. Now it counts only the quiet, so
every gang beaten gives the search its window back; the gangs still grow and the run's clock still ticks while they're
on you.

**Parked for the next balance pass (14 Oct, Matt).**
- *The search against the gangs.* A search takes 15 s and the gangs come 20 s apart: one search a gap on the
  Allotments. Set the two together (and what Keen eyes / Quick hands / Fast strip and Patience / Lying up / Soft
  ground / Head start / Never still and the affixes buy) once the gang clock's pause has been played.
- *Gangs harder, not just larger.* Each gang is one head bigger and nothing else. Raise the stakes of staying: later
  gangs drawn from the next zone's crew (its figures, its HP and damage), or a gang's heads growing with the gangs
  so far. To design with Matt before the pass - it changes numbers, so it goes in before the pass, not after.

**Training's pasts as cards; the joints' links say OPEN or JOINED (14 Oct, Matt; docs/design/mockups/class_cards_mockup.png).**
The five class buttons are cards: the past's face, its name, its short lines (Data.CLASSES "short": green, a cost
red), the runner's lit and ticked "your past", the rest dimmed, an armed one "press again"; the whole sentence the
card's tooltip. No past yet: a ? in the band's face and every card lit to compare. One line over them: the trait, a
change's price, or the prompt. The links between a class lane and its element's read "⇄ OPEN" or "⇄ JOINED" and
nothing more - the joint's words are on its halves once picked.

## Parked for before the balance pass (14 Oct, Matt)

Matt, 14 Oct: "everything here gets parked for before the balance pass and we don't touch anything until I provide an
endgame save (game breaking bugs aside)." He's playing the exported build to the endgame as a bleed Doorman. Nothing
below starts until that save lands; then each is designed with him, one at a time, before the pass.

1. **The odds, faster.** A profiled read (Doorman as physical, 4 h, 160 s of wall in the cloud): the odds took about
   140 s, 87% of it, and the real runs 13 s. They played 3,758 dry runs, 159,547 ticks against the game's 13,908,
   about 15 a read. Every site read 100% by the end. Proposed: stop a read early when the first dry runs all agree,
   and keep a read longer while nothing it depends on has changed (124 of 381 calls were already cache hits).
   Expected: a read in a third to a quarter of the wall, timed before and after. The bot pushes on the odds, so this
   moves its results; it lands before the pass, never in it. The cards' odds in the game get quicker with it.
2. **The refactor** (the plan given Matt, 14 Oct), each step its own commit, proved by a fixed-seed fingerprint
   (every run's outcome, loot, tins, XP and times identical before and after) as well as the smoke:
   1. The fingerprint, and dead code: `has_node("plates")` and `has_node("headshots")` read nodes the trees no
      longer have, plus whatever else the editor finds unused.
   2. The effects' numbers into data. 151 of sim.gd's 276 has_node / has_rule / yard_has / joint / atlas lines carry
      their number inline. They move to their entries in data.gd, so the pass tunes one table. A smoke check flags
      a node the data has and the sim never reads, or the reverse.
   3. sim.gd (7,636 lines) split by system (the fight, the search, the economy, the Yard, the trees, the save) behind
      the same Sim the UI calls.
   4. smoke.gd (12,452 lines) split by area, with a way to run one area alone.
   5. The run's 85 keys in one list, the smoke checking nothing reads a key outside it.
   6. The dated history out of the comments: the why stays, the when is in git and here.
3. **The papers, a full pass.** From Matt's playtest: a paper's pick still says "In the drawer, in Training", and the
   papers no longer live there. The flavour line (e.g. "The garden centre's. Nine stamps of ten. The free coffee's
   still owed.") goes in the paper's description. The code it carries wants a better way of being shown. Matt's
   lean: a paper stays encrypted until the Radio's open, so papers become things to hold on to that build the lore
   as they're kept. To design with him.
   Matt, 14 Oct, with it: **the heads' room-openers come home as keepsakes.** Beating the Gamekeeper gives nothing in
   the pack: the vet's bag opens the Clinic at the drop and "goes to the medic" ("it felt odd"). The vet's bag, the
   Carpet Man's ledger and the Quartermaster's set and tool roll come home as things to keep, in the drawer with their
   story, still opening their room at the drop.
4. **The flaky scrap check.** "searches brought no scrap in 600 seconds" failed once and passed when the smoke ran
   again (14 Oct). A site picked clean before a scrap roll stops searching; the check wants a site that can't run
   dry.
5. **From the gang-clock change**, already parked above for the pass: the search against the gangs, and gangs harder,
   not just larger.
6. **Their HP bar: the hits in chunks, the dots chipping (Matt, 14 Oct: "dots damage should chip away at it and then
   the big chunks you take off as flat damage should come off the health bar as displayed").** Why it reads wrong:
   the sim takes your fire off their HP a little every tick (`landed_total`, your damage a second times the tick), so
   the bar slides down smoothly like a dot. The numbers, meanwhile, come out in lumps as the gun's shots land in the
   frame (`_hit_pending`, `_release_hits`). The bar and the numbers disagree. Proposed, the display alone: the bar
   shows their HP plus the hit damage not yet shown as a number, so it holds while a shot's being "loaded" and drops
   by the number's size as it lands. The dots keep ticking it down smoothly, their coloured segments as now. The sim's
   untouched, so no balance read moves. Smoke: the bar's drop on a shot matches the number shown, within a point.
7. **The Gamekeeper's loot (Matt, 14 Oct: "killing him and getting absolutely nothing felt bad").** He's the one head
   with no uniques (`"uniques": []`), so his drop is the cash, the XP, the notes and the vet's bag, which never reaches
   the pack. He wants a loot table like the other heads': two uniques of his own, rolled at the depth he's fought at.
   To design with Matt (a keeper's things: the shoot's gun, his coat, the dogs' whistle...), test art first, then the
   art manifest.
8. **"The ending" in the code means the deeds' fate, and it isn't the ending.** The game ends on the Radio (the
   Quartermaster's set, Kev, the codes; docs/design/on_the_air.md). The deeds drop off the Manager and the City plays on
   after the Bank. `sim.ending` ("burned", "sold", "held") and the comments that say the deeds come home "for the
   ending" date from the build before the City. Rename them in the refactor's step 6 (e.g. `deeds_fate`), with
   the save's key read under both names.
9. **Your muzzle flash (Matt, 14 Oct: "I don't think player muzzle flash works ... doesn't work on shotgun or bolt
   gun").** There isn't one to work. A shot is only the kick (`_recoil`: the hands shoved 10,12 px for 0.08 s);
   no hands picture has a flash painted in (blade, improvised, melee, pistol, rifle, shotgun, SMG all checked), and
   the gangs' flashes are their own `_fire` frames. Proposed, in engine first as the melee swing was: a flash drawn at
   each picture's muzzle (a point a kind, read off the art), its shape the gun's - the shotgun's wide and both
   barrels, the bolt gun's long, the pistol's small, the SMG's quick and small, the nail gun a spark; none on a blade
   or a hammer - on the shot's beat, with the kick. Smoke: a shot puts the flash up inside the frame at the muzzle,
   for every gun kind. Generated flash frames only if this doesn't sell it.
10. **A full pack's swap judges by worn kit, not tins (Matt, 14 Oct: a 6-pouch rig in the pack, an upgrade on his bum
    bag, was swapped out for an epic school bag worse than the legendary one he wore).** Today (`_place_find`) a find
    into a full pack takes the place of the cheapest thing its size if it sells for more, blind to what's worn and to
    what in the pack is an upgrade. Agreed (Matt, 14 Oct):
    - **By hand:** a full pack sends a drop to the floor (as the search's finds go), so nothing is swapped without
      the player.
    - **On an auto-run and "Fill up, then go":** a find swaps in only if it beats what's worn in its slot
      (`is_upgrade`), and a thing in the pack that's itself an upgrade is never swapped out.
    It moves the auto-runs' take (fewer swaps), so it lands before the pass. Smoke: by hand, a drop into a full pack
    lands on the floor and the pack's unchanged; on auto, a non-upgrade find never swaps, an upgrade in the pack never
    leaves, an upgrade find swaps the cheapest non-upgrade its size. The note under the pack ("Pack full: a better find
    swaps in") says the new rule.
11. **A bar over each of them (Matt, 14 Oct: "it's odd having 3 enemies and one bar shared"; option A of
    docs/design/mockups/hpbars_mockup.png).** The bar was never shared: the sim fights them one at a time, and "Their
    HP" is the one being hit (`target_hp`); the others on screen are untouched. Agreed: a small bar over each figure
    in the frame, sized to it, following it as it moves and falls. The one being hit is outlined amber, with its HP
    over it ("83 / 120") and the dots' shares at its end; the rest show full till their turn; one walking in for a
    gang bigger than three comes up with a fresh bar. The bar across the top of the frame goes; the gang's head and
    "On them" stay, "On them" moving up into its place. The head (a boss) gets the same bar, bigger, not the top bar
    back. Built with item 6: the hit bar drops in chunks as the numbers land, the dots chip it. Smoke: a bar a figure
    up, inside the frame and clear of the head line and the chips; the hit one's numbers matching `target_hp`; the
    rest full; none on a figure down.
12. **The Van's Spare is too strong (Matt, 14 Oct, at the Hospital as a bleed Doorman: "nothing beats the Van's Spare";
    it makes the secondary-at-full perk "a waste of time" and "makes you skip pretty much everything").** What it is
    (data.gd, the Carpet Man's): an old revolver whose rule `vans_spare` fires the secondary at full damage, not the
    usual third (sim.gd's dps and the fight's share both read it), plus +18% damage, +25% on the first lot and 4 tins
    a kill. It rolls at the depth he's fought at (12 Oct), so a deeper Carpet Man hands out a deeper copy and it never
    falls behind. Its rule is Double tap's (the trees' notable, "The secondary fires at full damage, not a third") for
    free, so the node is dead weight while it's worn, and a whole second gun at full outdamages any primary upgrade
    found. To design with Matt; options to weigh: the rule weaker (the secondary at two thirds; or at full only for a
    gang's first seconds); the +18% damage off; the rule doing something new with Double tap rather than the same (both
    worn: the secondary fires twice); or it rolled only at the depth it first drops. It changes numbers: before the pass.
13. **A bigger fight frame (Matt, 14 Oct: "looks great but it's a tad small").** The frame is 588 x 262 in the run's
    left column (608 wide); the rail takes 312 of the 1920 (Pal.RAIL_W) and the pack's grid 904 (Inventory.WIDTH, a
    cell's width fixed). Width can come off the rail: names smaller, or the rail folding to its icons with the names on
    hover, would give the column 100-200 px, a frame about 1.2-1.3x. Height is the harder half: the column's full top
    to bottom since the search moved into it (the rig ends 6 px over the buttons), so a taller frame wants the site's
    band at the top (200 px: the place, the clock, the progress bar) slimmer too. The pixel art reads best at a clean
    scale. Mockups first: rail options, the band slimmed, the frame at 1.25x, the search's column checked at its
    fullest.
14. **The odds don't count the events (Matt's first death, 14 Oct: the Services at depth 5, the card at 100%).** The
    dry runs behind a card start with `"event_at": -1.0`, so no event ever happens in them. His run: a convoy came
    through (four more heads, `_event`'s "convoy"), four wounds in twenty seconds, three bandages and a first aid kit,
    dead at 82 s with 13 of 16 down. The card said 100% and the run read "odds 1.0". To design with Matt: roll the
    events into the dry runs at their real chance, or keep the odds event-free and say so on the card ("before any
    surprises"). The first is honest and costs odds time (item 1 helps); it moves the bot's pushes, so before the pass.
15. **The Fence's gamble out-gears the drops (a balance note, from the same save).** 25 gambles at 300-393 tins; out of
    them came The Paramedic's Bumbag (a unique, 3,300), the Sniper rifle and the Scoped .308 he fought with, the Full
    bergen, the Casino chip. The price sat at a flat 300 until level 20. For the pass's loot gates: what a tin spent
    at the gamble buys against what a run finds.
16. **"Wounded again" reads as stacking.** A second wound replaces the first (one at a time, `_wound`), but the log says
    "Wounded again: armour −10%" four times in a fight. The words: "Wounded: armour −10% (replaces pace)".
17. **The loot tables (Matt, 14 Oct: "firstly inconsistent").** From his save: the gamble out-geared the drops (item
    15); uniques roll at the depth their head's fought at, so the strong ones never fall behind (item 12); a melee
    weapon dropping saved a run gone dry ("some emergent gameplay") - keep melee in the drops as the fallback. A full
    read of what each site, crate, kill and the gamble hands out, then one design.
18. **The campaign's and the endgame's length (Matt, 14-15 Oct: "a design question not a balance one").** The Bank at
    47 min, the Quartermaster at 67, kitted out by the end. Being designed now: docs/design/endgame_radio.md (the
    Radio's missions in place of the depth buttons, and gear gated by level). Sets (data.gd SETS, six, from depth 5
    to 15, 0.4% a find a depth past the first) are one of its hooks.
19. **For the art pass (Matt, 15 Oct): the fight's guns, down the sight.** Along with the new uniques' art (the
    Keeper's Twelve-Bore and Wax Jacket, test art from their bases till then), redraw the fight art for the improvised
    guns, the SMGs and the pistols: "the rifle and shotgun for example read correctly down the sight but the ones I
    listed are side on and look plain weird". Parked for the art pass.

## The running order to the next playtest (15 Oct, Matt: "backlog + balance before I play again")

The items above, the Radio's endgame (docs/design/endgame_radio.md) and Training's gating, built in this order. Each
is its own commit: design or mockup where it needs one, the smoke, the reviewer, the fingerprint once it exists.

**A. The ground first** (no player-facing change; makes everything after safer and quicker)
1. The fingerprint and dead code (item 2, step 1).
2. The effects' numbers into data (item 2, step 2).
3. sim.gd split by system, smoke.gd by area with one-area runs (item 2, steps 3-4); the run's keys in one list and
   `ending` renamed (items 2.5, 8) ride along.
4. The odds: quicker reads, and the events in them (items 1, 14).

**B. The structure** (changes numbers: all before the pass)
5. Gear gated by level: the level to wear, the padlock (endgame_radio.md §5; signals_kit.png).
6. Training's gating and retirement at 50 (§8; gating_training.png).
7. The Radio's endgame, in parts: the papers encrypted till the Radio, each carrying its code (item 3); the depth
   buttons off the campaign (signals_map.png); the decoder and signals with the reach (signals_radio.png); Kev's story
   signals and their papers; full-strength heads and the convoy moved onto signals; the bot making signals; old saves
   converted to a reach.
8. Loot: the heads' keepsakes (item 3), the Gamekeeper's own (item 7), the Van's Spare (item 12), the full pack's
   swap (item 10), then the loot tables read whole (item 17).
9. Gangs harder, not just larger (item 5, its second half).

**C. The fight's feel** (no numbers)
10. The bigger frame first (item 13, mockups), then the bar over each of them with the hits in chunks (items 6, 11)
    and the muzzle flash (item 9) on it.
11. The small ones: the wound's words (item 16), the scrap flake (item 4).

**D. The balance pass**
12. Gates set first. The campaign's length measured against Matt's 14 Oct save (the Bank at 47 min, the Quartermaster
    at 67, first death at 82, as a fire Drifter's Bank was 47 too) against its target: **twice that, the
    Quartermaster about 2 h 15 by hand** (Matt, 15 Oct: "aim for 2x campaign as it stands and see how it feels"); the search against the gangs
    (item 5), the gamble's worth (item 15), the loot tables' numbers (item 17), the signals' ladder. Then one pass.

**A1: the fingerprint and dead code (15 Oct).** tests/fingerprint.gd plays four bot builds for three simulated hours
on fixed dice (the fourth by hand, through a save and a load every eighth run), hashing every run's outcome, kills,
loot, tins, XP and time and each build's end state (ids stripped). Run in the cloud workspace before and after each
refactor step: the hash must not move. One fix made it possible: a Yard's move rolled fresh dice mid-read (start() and
load_dict() both randomised); `Sim.fixed_seed` (0 in the game, so unchanged there) gives them fixed ones. Removed, with
the hash unmoved (b687fd57…, 340 lines): 22 functions nothing called, 12 constants nothing read, and three dead terms -
`has_node("plates")` and `has_node("headshots")` (no tree has either) and `tree_sum("pack_cells")` (no node gives it).

**A2: the effects' numbers in one table (15 Oct).** `Data.FX`, 167 rows keyed "kind/id[.what]" (node, rule, set,
joint, yard, yard_rank, atlas), each with the data's own words: 181 figures sim.gd had inline under has_node,
has_rule, yard_has, has_joint, has_set_rule, atlas_rank and yard_rank now read from it - the ternaries, the per-rank
steps, and a lone figure under an `if` on one effect. Left inline: neutral values (0, 1), the 999 sentinels, and
figures inside a condition with more than one number to it (about 20, listed by the review for the pass to judge).
The fingerprint is unmoved (b687fd57…). The smoke checks every key names something the data has and the sim reads
every key. One effect, one row: Trapline's, the Flares' and the Poacher's snare's "a head short" each one row for
the clear and the gangs; Picked over's base is in with its step.

**A3 (15 Oct).** `ending` is `deeds_fate` (the game ends on the Radio; the deeds are a choice: held, sold or burned),
read from an old save's "ending"; the player's "Held, sold or burned: the ending" lost "the ending". A dead read
went: `mission.get("bonus_armour")`, never written. The smoke runs one area alone: `godot --path . -s
tests/smoke.gd -- only crates fx gang_pause` (a camp set some way in, no bot run, seconds; the whole smoke is still
the one before a commit). The fingerprint unmoved. **Not done, with reasons:** sim.gd split by system - an
inheritance chain can't, the systems call each other both ways; composition can (each system an object holding the
sim) but every moved function's state reads become `sim.` reads and the save reaches into each, too much churn
before the pass for navigation alone. smoke.gd split into files - possible (a base of the helpers, areas on it),
left: the one-area runs got the time it was for. A run-keys list - `m` holds the modifiers' dicts too, so a check
would be noise; a one-off scan found the one real case (bonus_armour).

**A4: the odds quicker, and the events in them (15 Oct; items 1 and 14 done).** A dry run's tick about 45% cheaper,
exactly (the same fights to the tick, the fingerprint unmoved by it): the damage figure kept while nothing it reads
moves (keyed on which ammo stacks have rounds, not their count, which moves every tick); the set bonuses read once a
run, not twice a tick by `contact()`; a tick's rounds taken off the stack at once, not a rig scan a round; `level()`
read once an XP. The memos clear on a train, a respec and a class change (the review). Then two that change what the
odds say: **the events now roll in the dry runs** at their real chance, on the odds' own dice, as a run rolls them - a
convoy's extra lot counts; a cache is loot, so skipped; one that falls after the clear still isn't counted (a dry run
ends at the clear). And the gate's reads (only theirs: the Map's own number reads on) settle at four runs when all
four come back over 70%, or all four die. Measured, Doorman as physical, 4 h gate in the cloud: wall 63 s -> 36 s, the
odds 53 s -> 27 s; a fixed camp's dry run 17.9 -> 9.5 ms. The fingerprint moves for the events and the four-run stop
(the bots push on the odds): new baseline **c2cf909a…** (302 lines). The bots' campaign shifts with it; the pass
measures it fresh.

**B5: gear gated by level (15 Oct; endgame_radio.md §5, signals_kit.png).** Every worn piece has a level to wear: its
item level x3 - 2 (Data.WEAR_PER_ILVL, Matt's pick: the first sites' gear at 1, the Quartermaster's, item level 9, at
25; to 50), one figure for the pass. Over the runner's level it's carried, stashed and sold as any other and can't go
on: Equip, Equip if better, a drag onto the body and Equip from the pack all wait. Greyed in the grids under a red
padlock with its level; the pick reads "Level N to wear", the foot "Level N to wear, your runner's L", the button
"Equip at N"; no upgrade arrow, and the Fence's shelf says the level, not "Better"; the junk rules keep an upgrade that
waits. The gear chip is the level to wear; parts and the Workshop say "Item level". The gamble rolls as it did - the
gating holds its top pulls. The bot buys and holds only what it can wear. **Old saves (Matt, 15 Oct, standing rule):
no conversions** - SAVE_VERSION 2, an older save isn't loaded and its slot says "From before an update: can't be
loaded". Checked in the smoke (`only gear_gate`).

**B6: Training's gating, retirement at 50 (15 Oct; endgame_radio.md §8, gating_training.png).** The class tree is the
core, as Last Epoch's: an element tree's third and fourth columns want 6 points in its core (the class tree its joint
is in for this runner, or the first class tree off the pair), the fifth and sixth 12, its capstone 18
(Data.CORE_GATES, CORE_CAPSTONE). Keystones open at level 20, capstones at 30, in every tree. The second past at 30
wants 20 in the first class tree. Retirement at 50 (the cap stays 50 until Matt's full save). On the screen: a
padlocked pill in the gap before each locked band ("6 in Muscle", a bar under the first), "Lv 20" / "Lv 30" by each
keystone and capstone (red till the level, green with a tick), the node's line saying why, and from level 20 the
second past's line with its bar ("Second past at level 30 · 20 in Muscle: 4 of 20") in the runners-before line's
place. The bot banks no points for a level's wait. The smoke's mechanics areas (joints, keystones, capstones, the
move's trade) turn the gates off (`sim.core_gates`, not saved, always on in the game) and `only training_gate`
checks them.

**B7.1: the papers encrypted till the Radio (15 Oct; endgame_radio.md §2, the papers' parked item 3).** A paper found
before the Quartermaster opens the Radio isn't read: its code is "A code in the margin, encrypted.", its pick says
"Encrypted · Read once the Radio's open · Keep it: a key to the endgame" (not "In the drawer, in Training"), and the
Kit's line "a code, encrypted". When the Radio opens it reads every paper held at once ("The Radio reads your
papers: N codes on them"). Read, a paper says the code it carries ("Carries laid off") and "Three make a signal".
Papers roll common to rare now (Data.PAPER_RARITY_MAX); a rare one will roll its signal one deeper. The bulk sells
and Ditch commons pass papers over, and the bot keeps them. Still possible one at a time, for Matt to call: selling
one, scrapping one, a Fence contract that takes papers.

**B7.2: signals (15 Oct; endgame_radio.md §1-4, signals_radio.png, signals_map.png).** The Radio's air is the
endgame now. Three papers (read, in the stash; not the deeds, a head's thing or a unique's rule paper) decrypt into a
signal: a campaign site at random, a crew from any of the four zones (their fire's types and resists), a depth rolled
round your reach (-1 20%, 0 60%, +1 15%, +2 5%; one deeper with a rare paper; never under 2), each paper's code at
the depth's tier, and the extras rolled (15% the crew's head at full strength, free; 15% a convoy's crew on the way),
with a line from Kev. Three held at most, seen before they're run (the card: Them, their fire, the finds' level, the
codes' bite and pay, the odds read in the frame's budget, Tune in / Retune / Twist in notes, Set off, Bin it). Run,
it's gone; beaten at your reach or past it raises the reach (the deepest beaten, plus one; it starts at 2) and pays a
point on the Dial (the per-site "a new depth" point is gone); lost (a death, out of time, cut and run, the head left
standing, a Ghost that never cleared) the reach stays. The signal is laid on its site for a read or a run and taken
off after; the site stays its campaign self (its own codes, seal, wear). The Map has no depth's −/+: its tiles are
Them, Their fire, Fight · clock, Finds (the level), Papers (1 in N finds) and The site. Kept through a Yard move:
the signals held and the reach. **Not yet:** Kev's story signals and the lorry (B7.3); the bot and the balance
reader making signals (B7.4) - until then the bots still climb the old per-site depths internally. For Matt: a
signal's clear still raises its site's best depth (the Yard's columns, the deepest site level the contracts and the
Arms dealer read follow the signals, as intended), and its salvage and zone codes are the site's zone's, not the
crew's.

**B7.3: Kev's story (15 Oct; endgame_radio.md §3).** Three beats, each three papers found only once the Radio's on
the air (a signal beaten brings the beat's next missing paper home half the time; none while the beat's signal is
held): Where they go (a tachograph disc, a route card, a fuel receipt), Whose they are (a movement order, a ration
chit, a signals log), The depot (a gate pass, a loading manifest, a depot plan). A beat's three go in the decoder
together, never mixed with another paper, and make its signal: a fixed site and crew at your reach (the Services with
the Town's crew; the Barracks with the City's), the crew's head at full strength; the third is the depot's convoy -
the three heads in a row and the Lorry's Load, the old Services-at-depth-8 fight, now the only way to the lorry (it
still counts once a Yard for the lorry's prestige). Beaten, the story moves on, with Kev's line; past the third the
depot comes round again. On the Radio: the papers carry a STORY badge and "Kev's story · where they go · 2 of 3
found", the card says the beat, the band counts the story. Kev's papers aren't the drawer's. The Map's and the next
step's lorry lines point at the Radio and Kev's depot. Scenes in the On the air style for the beats wait on art.

**B7.4: the bot and the reader on signals (15 Oct).** Past the campaign the bot makes a signal whenever it has three
papers and room (Kev's beat when its three are held, else three plain papers, the rare first), runs the deepest held
that reads PUSH (Kev's at FIRST, a head's odds; insured at the signal's depth, sim.signal_insure_cost), and otherwise
farms the campaign site worth most that reads PUSH - its level and its papers (the Bank's three times) - at depth 1.
No more climbing, no lorry arming, no notes or Lorry watch saved for the old convoy. GATES gains reach, story_beat,
signals_made and papers_held. A nine-hour probe (Doorman as physical): the campaign done at ~1 h 30, the reach 9 by
2 h and 20 by 9 h, Kev's story not reached - **papers are the bottleneck** (two plain papers in two hours of farming at
one in 16 finds): the pass's to tune (PAPER_DROP, the story's drop). **For Matt, left in the game and now dead:** the
Yard's Radio pick Lorry watch and the Dial's keystone The lorry's route both bring the old convoy shallower, and it no
longer exists (the depot's signal replaced it) - they want new effects; the Map's depth-based uniques (a site's own,
a head's charm at full strength) still drop on signals deep enough at that site. Depth-based balance figures
(depth_clears, the ladder read) still print; a signal's clear reads as its random site's depth.

**The two lorry perks, given new jobs (15 Oct, Matt: "I'll take your suggestions").** The Yard's Radio pick Lorry
watch: Kev's story papers come home twice as often. The Dial's keystone The lorry's route: a signal can roll three
over your reach, not two (the decoder's band a depth wider at the top). The Dial's empty line says where its points
come from (a new reach), not the convoy's depth.

**B8.1: the heads' keepsakes and the Gamekeeper's loot (15 Oct; parked items 3, 7).** A head's thing that opens a room
(the vet's bag, the Carpet Man's ledger, the military radio, the armourer's tool roll) now lands in the pack at the
drop - "Found: The vet's bag" - and opens its room there and then, as before; home, it goes to the drawer as a
keepsake, not the stash ("The keeper's, for the dogs. A keepsake: it opened the Clinic."), first in the drawer. The
Gamekeeper has his own two (Matt's pick): The Keeper's Twelve-Bore (a pump shotgun: every kill is 3% of your HP back;
+12% damage, +15% on the first lot) and The Keeper's Wax Jacket (poison and bleed on you do half; +10 armour, +15 HP),
levels 1-4, rolled at the depth he's fought at as the other heads' are. Test art: their bases' until the manifest.

**B8.2: the Van's Spare cut (15 Oct; parked item 12, Matt's pick).** Its rule fires the secondary at two thirds behind
the primary, not all of it (the usual third; Double tap or a dry primary still all of it, so the node counts again
with it worn); its +18% damage is gone; +25% on the first lot and 4 tins a kill stay. sim.secondary_share holds the rule.

**B8.3: a full pack's swap (15 Oct; parked item 10, as agreed).** By hand, once the search is on, a find into a full
pack goes to the floor - nothing is swapped without the player; in the fight before the clear (the floor isn't on
screen yet) the auto-run's rule holds. On an auto-run, "Fill up, then go", away and for the bot: only an upgrade on
what's worn, or a paper, swaps in, for the cheapest thing at least its size that isn't one (or a head's thing);
anything else is passed over; an upgrade in the pack never leaves. The pack's notes say so. Expect the bot's and
away-time's takings to dip a little against earlier reads (fewer valuable swaps). Fingerprint 55119646.

**B8.4: the loot tables (15 Oct; parked items 15, 17; the read at docs/design/loot_read.md, after at
loot_read_after.md; Matt's picks).** The read (tests/loot_read.gd): drops were one rarity campaign-wide (~60% common,
6% epic or better); the gamble never common and a fifth epic or better but at a low level (wear 7 at the City against
the drops' 25), so it out-geared them; uniques never dropped loose in the campaign and then flooded the signals (1 kill
in 10 at depth 6). Now: a zone's quality on its drops' rarity (the Outskirts nothing, the Estate +15%, the Town +30%,
the City +45%: ~61% common there down to ~47%); the gamble at your deepest site's level (never past what the runner can
wear) and its quality off (commons still out; epic or better ~7%); a loose unique from the Town on at 1 find in 200,
+1% a depth past the first, never past 1 in 25 (a Safe's double too); set pieces never past 1 in 50. Melee stays in
the drops (Matt: the wrench that saved a dry run). **For Matt:** at depth 1 the Hospital and the Barracks (loot tier 6)
have no loose unique whose range takes their tier, so the City's trickle comes only from the Services; widening a
"core" unique's range would fill it.

**B9: gangs harder, not just larger (15 Oct; parked item 5, its second half).** From the second gang on, a gang can be
the next zone's crew: 20% a gang past the first, to 80% (Data.GANG_NEXT_STEP, GANG_NEXT_MAX). Their heads are 1.6x the
site's HP and 1.5x its fire (GANG_NEXT_HP, GANG_NEXT_DPS), their fire made of the next zone's types and resists at the
site's depth, the site's words still on top; the City's own "hard core" past the last. The log says so ("The High
Street lot, 4 of them, in from the town."). The run holds the site's own aside while they stand and takes it back
when they're down (`_gang_harder`, `t_home`, through a save). The first gang never; the clear's fight and the odds
untouched (the odds read to the clear). Fingerprint b5f5db65…. **For the balance pass:** a harder gang pays the
site's XP, cash, notes and drops (about 2.4x the risk for the same pay, a push to leave), and brings no extra clock
(the clock counts gangs at the site's HP, so late searching runs out of time sooner); a convoy event arriving while
one stands fights at their stats (rare: the event usually comes before the clear); the fight art still draws the
site's own gang.

**C10.1: the bigger fight frame (15 Oct; parked item 13; Matt: "B it is", docs/design/mockups/frame_mockup_B.png, A
beside it).** On a run the rail folds to its glyphs (Pal.RAIL_FOLDED_W, 88 px): a room's name, its badge's word and
what opens a shut one on hover; a badge a dot in its tone on the stamp's corner; shut rooms dimmed. The run and the log
under it take the width (Pal.RUN_W, 1760); every other room has the rail as it was, and the pause drawer keeps the
unfolded rail's shape. The run's column is 832 (was 608): the frame drawn 1.38x at 812 x 362 (about twice the area),
its own 588 x 262 space scaled, so the slots, the plates and the placement tool keep their numbers; the site's band
slim at 100 (was 200): the place and the clock on one row, the depth, the capstones and the time and gangs under it,
the bar. The capstones fall back to a count, then nothing, at the band's widest. The rig and the take in a fight sit
under the six. Smoke: the frame's scale and place, the rail folded with its tooltips and back off the run, the run
and the log beside it, the slim band at its widest with nothing on anything. **For Matt to look at:** the frame's own
text (a crate's finds over the open one) is drawn scaled with it; if it reads soft, its size goes up and its scale
comes off.

**C10.2: a bar over each of them, the hits in chunks (15 Oct; parked items 11 and 6, as agreed; hpbars_mockup.png A).**
In a fight their HP is a small bar over each figure in the frame, following it: the one you're hitting outlined amber,
its HP over it ("83 / 120"), the dots' shares at its end and the skull when they'll finish it; the rest full till
their turn; the head's bigger; none on one falling. The bar across the top went ("On them" moved up into its place);
it stays the search's bar at the frame's foot. Your shots land on the one with the amber bar, a kill drops it, the
next is any of the rest (Matt, 13 Oct: not the first every time), and the numbers rise off it. The bar holds your hits
till their number lands and drops by it; the dots chip it in between (display only: the sim and the odds untouched).
The bars are drawn at the screen's pixels over the scaled frame, so the words stay crisp. Smoke: a bar a figure up,
in the frame, clear of the head line and the chips; the hit one's HP and words; the rest full; a held hit then out;
a kill.

**C10.3: your muzzle flash (15 Oct; parked item 9).** A flash at each gun picture's muzzle (the point read off the
art: `RunView.MUZZLE`), on the shot's beat with the kick, following the gun through the kick and the duck: the
shotgun's wide and both barrels, the bolt gun's long, the pistol's small, the SMG's quick and small, the nail gun a
spark; none on a blade or a hammer, or on a stand-in picture. Drawn additive, at least one frame however slow the
frames. The improvised, SMG and pistol pictures are to be redrawn down the sight (item 19): their muzzle points move
with them. Smoke: each kind's flash on a drawn pixel of its gun, in the frame, for its moment; none on a blade.

**C11: the small ones (15 Oct; parked items 16 and 4).** A second wound's line says what it replaced ("Wounded: armour
−10% (replaces pace)", or "(the same wound: one at a time)"), never "Wounded again", which read as stacking. The
smoke's scrap check searches a site that can't be picked clean before a scrap roll (`crates_off`), so its flake is
gone. **Group C done**; next is D, the balance pass.

**The art pass manifest (15 Oct, Matt: "provide art manifest now so I can run in the background", then the balance
pass, then the muzzle flash looked at again).** tools/make_art_pass_manifest.py writes
tools/pixellab_art_pass_manifest.json, five jobs: the Gamekeeper's two uniques (the Twelve-Bore, 256 x 64; the Wax
Jacket, 192 x 192) to art/items/, which the game picks up by name; the pistol's, the SMG's and the nail gun's hands
redrawn down the sight (the rifle's hands as the reference) to art/fight_new/, to be looked at and copied over
art/fight/hands_<kind>.png. Every other unique already has its own picture. **After the balance pass:** the muzzle
flash's points and directions (RunView.MUZZLE) read again off the new hands, if they need it.

**D1: the balance pass's gates, set (15 Oct; docs/design/balance_gates.md, Matt approved).** Fifteen gates for twice
the campaign as it stands, the bot read at 0.85 of a hand's time (the 13 Oct reads against Matt's save; his playtest
re-measures it): the Manager at 1.1-1.6 h and the Quartermaster at 1.6-2.3 h (bot), the builds within 2x, level 18-22
at him and 30 within two hours after, the Radio's ladder (a signal every 20 min, reach every 45, to hour 12), Kev's
story by 10, level 50 between 12 and 24, no reds, two searches a gap between gangs, staying costs, the loot read's
tables and the gamble under the drops, cash and scrap. Deaths and wounds are judged at the playtest, shown beside.
tests/balance.gd reads them (`_gate_firsts`, `_longest_gap`, the gang clock in the end odds loop);
tools/balance_summary.gd judges them (a never counts as later than any in a build's median); tools/balance.bat runs
24 h a build and the loot read; tools/playtest_summary.gd reads the same from play. Old gates retired with what they
measured (the keystone and capstone hours, depth pace, the lorry, the ladders' spread).

**D2: signals roll under the reach too (15 Oct; Matt: "go with your recommendation").** The baseline (docs/balance/
summary_d1_baseline.md, 9 reds): every build made its signals in the first two hours, then held three it couldn't run
(0-12% at level 50 in campaign kit) and made none for 22 hours; Kev's story never began. SIGNAL_ROLL now reaches three
under the reach ([-3 .1, -2 .15, -1 .2, 0 .4, +1 .1, +2 .05]): a win under it pays drops and the story paper's chance,
not reach. The bot, holding three it can't run with papers for another, bins the worst (never Kev's), as a player
would. Read (summary_d2.md): reach 7-25 (was 3-17), 50-102 signals made; papers now run out; the story still never.
**Found:** a signal's depth isn't a difficulty - a site's level is its index past the Outskirts plus the depth, so
depth 20 is level 17 on the Allotments and 28 on the Barracks. The bot climbs reach on the soft sites; Kev's beats
sit on the Services and the Barracks at the reach, levels above anything it can win (the Services at depth 12 reads
0% at level 50 where the Allotments at depth 20 reads 100%). For Matt.

**D3: reach is a level (15 Oct; Matt chose it).** A signal rolls a level round the reach (REACH_START 10: the campaign
tops at 9) and lands at the depth that puts its site at that level (`depth_for_level`, never under 2); with it laid on,
the site is fought, juiced, looted and counted at the depth that level is on the hardest site (`site_depth`,
`tier_depth`: the Barracks' depth at that level), so a level is the same fight on every site - Kev's beats included.
The reach rises past a win at or over it (`signal_level`). The Radio speaks in levels ("Level 14", "A signal at level
12-16", a card's "Level 14 (depth 6) · 2 over your reach"); the bot runs the highest level that reads PUSH.
SAVE_VERSION 3 (the rule: old saves shown incompatible).

**D4: Kev's beats five levels under the reach (15 Oct).** D3's read (summary_d3.md): reach 17-33 on every element
build, Kev's story still not finished on any (one build two beats in). Read off the end saves: the odds fall from
100% to 0% in two levels, and a beat's head at full strength is about three levels' worth, so a beat at the reach was
never winnable. Data.STORY_UNDER 5: a beat's signal comes five levels under your reach. Also seen once in the smoke
and not again on a rerun: "an arrow stayed once the better helmet went on" (the parked flake, 13 Oct).

**D4's read (summary_d4.md, 9 reds, was 12):** Kev's story finished on 7 of the 20 element reads (4.2-18.4 h), the
gang clock and the builds' band green. Still red: the pace (the Manager 0.9 h, the Quartermaster 1.5 h), the level at
him (27-38), retirement (3-8 h), the Radio's ladder's gaps, the loot tables, the gamble, cash.

**D5: the XP curve x2.4 (15 Oct; gate 4).** Data.XP_SCALE 2.4 on every level's cost: the curve doubles every seven
levels, so level 28's XP comes at level 20. The try-on smoke's runner levelled to wear the Van's Spare it rolls.

**D5's read (summary_d5.md, 10 reds):** the Manager green at 1.6 h; the Quartermaster 2.5 h (just past 2.3), level
20-32 at him (median about 25); retirement green on eight of ten (13-20 h); Kev's story on 6 of 20 reads; the gang
clock back under 2 (1.7) with the slower pace.

**D6: the loot gates, the gamble, the gang clock (15 Oct).** The gamble draws at the deepest site *cleared*
(`deepest_cleared_level`): the next zone's first site, open and not yet cleared, had put it a level past every drop.
The loot read counts rarity over the gear alone (rounds and meds have no rarity worth reading; the Services' ammo
made the City read more common than the Town), its points at the levels D5 reached them, its signals by level; the
City's epic-or-better gate restated for gear, 8-16% (5-10% of every find was that). A loose unique 1 find in 100 from
the Town (was 1 in 200: by the Quartermaster on 2-4 builds of 10). PATROL_S 24 (was 20): two searches a gap.

**D6's read (summary_d6.md, 8 reds):** the gamble and the gang clock green; the Manager 1.6 h green; the Quartermaster
2.6 h (past 2.3) at level 23-28; Kev's story on few reads; the City's gear 18% epic or better; a loose unique by him on
4 of 10. The end saves: every build held three signals at 0% - the odds fall from 100% to 0% in two levels, so rolls at
and past the reach can't be won and the bot waits on papers to bin them.

**D7: the band under the reach, the City's quality, the trickle (15 Oct).** SIGNAL_ROLL four under to one over (was
three under to two over; the Lorry's route reads "two over your reach, not one"); the City's ZONE_QUALITY .38 (was
.45); a loose unique 1 find in 50 from the Town.

**D7's read (summary_d7.md, 10 reds):** Kev's story green on 7 of 10 builds (was 1); retirement worse (five never by
24 h); the Quartermaster still 2.6 h at level 23-27; the City's gear 16.2% epic or better (just over 16); the wall 45
minutes (the endgame now runs all 24 hours: four times the odds reads, and 31 jobs on the laptop at once).

**D8: gear worn sooner; the pass quicker (15 Oct).** WEAR_PER_ILVL 2.5 (was 3; Matt's x3 of 15 Oct, a figure for the
pass): the Quartermaster's item level wears at 21 (was 25), the City's drops at 16-21 (19-25), so the campaign stops
waiting on levels. The bot's endgame tidy re-picks the site it farms every ten simulated minutes, not every run
(`_farm_tier`: a third of a tidy). Iteration reads one a build (the flag "24 1", 16 jobs); the final read two.
The smoke flaked once on "tier 11's odds never settled in 2000 frames" right after the balance read (the machine
still loaded) and passed on the rerun.

**D8's read (summary_d8.md; one read a build, Scrapper as fire killed at 15 h):** the Quartermaster 2.5 h median at
level 20-28 (most now 20-23); a loose unique by him on 7 of 9; cash green; Kev's story late on five; the wall about 30
minutes for every read but the Scrapper's - level 50 by hour 5, then the Bank at depth 1 in three-second runs.

**D9: a site well under you pays less (15 Oct; Matt: "fall off past 5 levels").** `over_level_share`: your level read
as a site's (the item level you wear at), whole to OVER_LEVEL_FREE 5 site levels under, OVER_LEVEL_STEP 15% less XP
and tins a level past, never under OVER_LEVEL_FLOOR 10%; the rest of the site as it was. Not yet shown on the Map's
cards (a line for the UI, for Matt). Two smoke flakes fixed, not accepted: the upgrade arrow's hats are the two it put
there, by id (a magic hard hat the camp already had could rightly carry the arrow); the odds-settle loop waits 6000
frames (2000 flaked on the Barracks' long dry runs with the machine still loaded).

**D9's read (summary_d9.md, 8 reds; the pass back to 25 minutes):** the Manager 1.3 h and the Quartermaster 2.1 h
green, level 20-24 at him on most; Kev's story on six; retirement never on eight - the levels stall from hour 4 (the
Drifter 35 at 4 h, 43 at 24 h): the Radio waits hours for papers between signals, so the bot farms the campaign at a
tenth of the pay.

**D10: papers twice as common (15 Oct).** PAPER_DROP 0.12 (was 0.06; the 15 Oct note had it the endgame's
bottleneck). The review's tidies: the Lorry's route's Dial figures and sentence in levels (+1/+2, "a level further");
the bot's farm read fresh after a Yard move.

**D10's read (summary_d10.md, 8 reds; 22 minutes):** the loot tables green; Kev's story on six (the rest by 10-15 h);
the signals' gaps down to 1-2 h; retirement never on nine (level 35-50 at 24 h); the Quartermaster 2.7 h median on one
read a build (two Poachers at 5.8 and 7.6 h pull it - one read's noise).

**D11: the XP curve eases past the campaign (15 Oct).** `Data.xp_scale(l)`: x2.4 to level 22, easing to x0.4 by 40 and
on: level 30 at about 29k XP (was 32k), 40 at 51k (89k), 50 at 76k (243k). The campaign's levels unchanged.

**D11's read (summary_d11x2.md, two reads a build, 10 reds):** the Manager 1.8 h; the Quartermaster 2.4 h median
(2.1-5.1), level 23-34 at him; the Radio's gaps; story late on three, retirement off on four; the Paramedic-frost
gang clock 1.9; the Scrappers' cash; the plain Doorman and Scrapper never past the Carpet Man - over-levelled for the
Estate, D9's falloff cut their pay to a tenth, a poverty spiral.

**D12: the falloff reads your furthest progress, not just your level (16 Oct).** `over_level_share` caps your level's
site at the deepest site you've cleared (or the reach less one once a signal's won): a build held at a wall farms its
last sites at full pay. Smoke: the held-at-a-wall case.

**D12's read (summary_d12.md, one read a build, 7 reds; 14 minutes):** the plain floor green; the gang clock green;
retirement at hour 4-6 on five (the falloff cap read the reach after the campaign too - the review's catch, fixed below).

**D12, the review:** the cap holds only while the campaign isn't done (a runner who's finished it and wins no signal
was paid whole on the City forever); the reach term gone with it. Smoke: the campaign-done case, the held case's step.

**D13: three bot faults that stalled the Radio (16 Oct).** Read off one Drifter's log in the cloud:
- the bandage flood: `_restock_meds` tried the stash's first med (a four-cell kit, no room), failed and bought a
  bandage for the stash, over and over - a hundred, the cash gone, the stash full, no pickups and so no papers for
  hours. Now every med is tried and a bandage bought only when the stash has no one-cell med;
- signals binned on a part-read: a fresh signal read "0%" before its odds were run; nothing's binned now until every
  held one's settled (and `odds_settled` reads the gate's 24-run cap as `survival()` does, or a build with the Glasses
  never settled);
- the move at the lorry: the bot moved the Yard the moment the lorry fell (hour 5-6), a new runner at level 1 - the
  ladder and level 50 cut off for the hours the campaign took again. It moves at level 50 now, a tidy after it's seen.
- Signal runs logged in the read ("ran a signal: level, odds, reach a -> b").

**D13's read (summary_d13.md, 6 reds; 21 minutes):** the Bank 1.4 h and the Quartermaster 1.9 h median, green; the
plain floor green; level 50 at hour 4-7 on every element build (the faults gone, XP flows); the Radio's signals binned
four in five at 0% - all on the City's and the Hospital's sites, won on the Outskirts' at the same level.

**D14: a signal's level is one fight on any site; XP's taper off (16 Oct).** A signal's fight is the endgame curve
alone, bent by its site's shape (the site's campaign floor - 4200 x 1.25^13 on the Barracks against the curve's 3200 x
1.14^13 - made a City site's level 22 seven times the Allotments'). XP_TAPER_END 2.4: x2.4 on (level 50 at 243k XP).
Smoke: the same level on the Allotments and the Barracks reads the shapes' ratio.

**D14's read (summary_d14.md, 5 reds):** Kev's story green on all ten; signals made every 8-30 min on most; the reach
still stands 2-7 hours at a time; level 50 from 6.6 h to never; the Scrappers level 28-30 at the Quartermaster.

**D15 (16 Oct).** The review of D14: a signal's pay is the curve's too (a City site's level paid more), and a signal's
clear keeps its site's own depth (`_clear` wrote the Barracks-scale depth against the site, so the cleared level read
low - the gamble, the Fence's uniques, the contracts' asks). CURVE grow 0.14 to 0.11: the reach is the runner's power
against that slope. The bot keeps six stacks of rounds a type (a bleed Doorman's and a frost Poacher's stash held 176
stacks, full, and picked nothing up - no papers - for the read's last ten hours). Smoke: a signal's clear keeps its depth.

**D15's read (summary_d15.md, 4 reds):** the cash sink green; the band 1.4-3.9 h; levels 23-29 at the Quartermaster on
five; the reach still stands 2.5-6 hours; level 50 at 7-11 h on five, never on three. The stall read off a shock
Drifter: the reach to 24 by hour 3.7 (the runner level 39), then every roll at 21-26 unwinnable, the bot on the campaign
at the falloff's tenth, and level 39 to 46 over twenty hours.

**D16 (16 Oct).** The roll seven under to one over (`[-7 .1, -5 .1, -3 .15, -2 .15, -1 .15, 0 .2, +1 .15]`): a runner
at the wall gets winnable signals at full pay, so the levels and the kit keep coming. XP_TAPER_END 3.6: the scale rises
from x2.4 at 22 to x3.6 at 40 (level 50 at 343k). The D15 review: what a depth opens (the Yard's columns 5 and 6, a
zone's salvage) reads `dug_depth` - a site's clear as the Barracks' depth at its level - not which site a signal fell
on; the bot keeps the dearest six stacks of rounds (grade, then count).

**D16's read (summary_d16.md, 6 reds):** level 50 at 14-23 h on nine of twelve; signals every 5-18 min; the reach
still stands 3-7 hours; the campaign slower on three single reads (the Manager 4.4-4.9 h). The dps of three builds fell
by half for hours mid-read: worn kit lost to the clock - a run out of time takes two pieces - 10-17 times a read.

**D17: out of time less often (16 Oct).** The odds of a signal with a convoy now carry the convoy (deploy_signal sets
it on every run; the dry run rolled its own events and left it out, so Kev's convoy beats read 100% and ran out of
time with one of sixteen down). The bot gets out when the kills so far say the rest won't fall before the clock and
there's time for the door's gang (after 90 s and four kills), and logs every run out of time.

**D17's read (summary_d17.md, 6 reds):** runs out of time down on most builds (0-3), but a shock Scrapper held at the
Carpet Man to hour 21 (the Estate's kit, a dps of 50, nothing better dropping) and a plain Paramedic to hour 10; level
50 at 8-9 h on two poison builds; the reach still stands 3.5-7 hours.

**D18 (16 Oct).** The Carpet Man 10/3.0 to 8/2.5 (HP and fire on the site's). The bot: a held signal unread after
twenty minutes can be binned (a kit changed at the bench restarts the read, so some never settled and plain papers piled
past a hundred); the rarest thirty plain papers kept, the rest sold. The review of D17: the dry run's convoy only when
no other event was rolled, as on a real run.

**D18's read (summary_d18.md, 5 reds; 18 minutes):** the Bank 1.5 h and the Quartermaster 2.1 h, green; signals
every 5-14 min on all (gate 6's first half green); the band 1.6-3.4 h (2.1x); level 23-26 at the Quartermaster on seven;
level 50 never on three element builds; the reach still stands 2.5-6.5 hours; a 0% campaign site on one read's end kit.

**D19 (16 Oct).** XP_SCALE 2.4 to 2.9 (the campaign's levels, gate 4). CURVE grow 0.11 to 0.08: a signal's level is
8% harder, not 11, against the 10% more it pays - the reach is the runner's power against this slope, and the power
grows about a third an hour past the campaign. The D18 review: plain papers are only sold once the Radio's open
(before it they're unread, kept for their codes). Note for Matt: the Carpet Man's change also softens his convoy head
and a full-strength Estate head on a signal.

**D19's read (summary_d19.md, 7 reds):** level at the Quartermaster green but one (25); the campaign slower (the Bank
1.9 h, the Quartermaster 2.5 h); the reach to 31-47 and its longest stretch down to 86-100 min on two; level 50 at
6.5-11 h on five (a fire Scrapper paid £7M a half hour at reach 40: the curve paid 10% a level against 8% harder).

**D20 (16 Oct).** CAMPAIGN_HOSTILE 0.9: the campaign's (depth 1) crews' HP and fire, heads with them, so the
campaign's pace comes back at the slower levels. CURVE reward 0.10 to 0.08, with its grow.

**D20's read (summary_d20.md, 4 reds):** the Bank 1.6 h and the Quartermaster 2.1 h green; the band 1.5-3.0 h; level
at the Quartermaster off on four (16-24); level 50 at 7.8-11 h on three, never on five; the reach's longest stretch
93-489 min. A poison Paramedic's read: the reach to 25 early, then 777 signals binned against 48 run, its dps flat at
600 for eighteen hours - the reach climbed on the soft sites and the rest of the rolls past the kit.

**D21: a signal's crew is as tough on any site (16 Oct).** On a signal the site's shape keeps its crowd (pool) but not
its toughness: the crew's whole HP is the curve's for SIGNAL_POOL 11, shared over the site's pool, and fire the curve's.
(An Allotments crew at x0.6 HP against the Barracks' x1.5 was twelve levels at the 8% slope.) Smoke: the same level on
the Allotments and the Barracks reads the pools' inverse.

**D21's read (summary_d21.md, 4 reds):** level at the Quartermaster off on two (25); the band 1.4-3.1 h; level 50
never on four (47-49 at 24 h), at 9.9 h on one; the reach's longest stretch 92-475 min.

**D22 (16 Oct).** The review of D21: a signal's head, gangs and clock are formed from a crew member's HP, so sharing
the crew's HP over the pool made them hang on the pool's size. Back to the shape's HP on a signal (the soft sites'
many and the hard sites' few come to much the same crew HP); the shape's fire alone dropped (x0.7 to x1.4, the spread
that let the reach run ahead). XP_TAPER_END 3.6 to 3.2.

**D22's read (summary_d22.md, 7 reds):** a shock Scrapper held at the Estate to hour 22 again (its first hour's
element gun at half the damage, never swapped back); level at the Quartermaster 23-29 on five; level 50 7.2-7.9 h on
two, never on four; the reach's longest stretch 116-411 min; one read's cash over and one 0% end site.

**D23 (16 Oct).** The bot keeps its element's gun only while it's within ELEM_DPS_FLOOR 0.8 of the damage it had: a
swap under that goes back. The two-read confirmation read next.

**D23's two-read (summary_d23x2.md, 30 reads, 4 reds; 21 minutes):** the Bank 1.4 h, the Quartermaster 2.0 h, the
band 1.8-3.1 h - green; the plain floor, the cash sink, scrap, loot, the gang clock, no reds - green. Red: level at the
Quartermaster on two (23, 26); Kev's story never on two (a beat lost - one cut and run before its head came out - and
its papers to find again); level 50 never on four (one read of each in the window, the other at 44-48), 10.5-11.8 h on
the two Scrappers; the reach's longest stretch 188-387 min (signals every 8-16 min on eight of ten).

**D24 (16 Oct).** The bot never cuts and runs on a head's run (`_clock_short` skips a mission with a boss).
XP_TAPER_END 3.2 to 3.0. The art: the new hands (pistol, SMG, improvised) aren't in the game yet - Godot's import cache
(.godot/imported) still holds the 13 Oct pictures until the editor opens; the muzzle points for the new art, with a
smoke check that each fires into open air, wait in docs/muzzle_after_reimport.diff (`git apply`, after a reimport).

**D24's two-read (summary_d24x2.md, 30 reads, 4 reds):** Kev's story green on all ten; the band green; the
Quartermaster 2.4 h (one tenth over); level at the Quartermaster off on two (23, 25); level 50 never on one, 8.4-11.9 h
on three; the reach's longest stretch 140-384 min. Read off the logs: the reach climbs 1.6-3.9 levels an hour on
average from the Radio to hour 12 (reach 26-44 by then) - three to five times the gate's pace - but in a burst and
then a wall: a roll over the reach set it to the roll's level plus one, two and three at a time.

**D25 (16 Oct).** A signal won at or past the reach raises it one level, not to the signal's level plus one. The D23
review: the element bot reads its element gun's damage on a try-on (`fit_value`) rather than swapping and swapping back
every tidy (two chronicle lines and the caches cleared a tidy).

**D25's two-read (summary_d25x2.md, 30 reads, 3 reds):** level at the Quartermaster green on all ten (19-22); the
Bank 1.5 h, the Quartermaster 2.1 h; the reach's longest stretch down to 101-302 min (120-144 on four); but level 50 at
7.7-11.4 h on eight (every signal winnable, every one paying) and signals every 43-82 min on seven (papers short); the
band 1.5-3.7 h on its slowest read.

**D26 (16 Oct).** XP_TAPER_END 3.0 to 5.0 (levels 30-50 about x1.6 the XP). PAPER_DROP 0.12 to 0.18.

**D26's two-read (summary_d26x2.md, 30 reads, 8 reds - most from one read):** a shock Scrapper's second read held at
the Outskirts and the Estate all 24 hours (dps 20-30, £400 of kit, nothing kept) - its first read was fine; with two
reads its "never" is the median, so it reds the Bank, the Quartermaster, the band, levels, the capstone, the ladder and
the story. Otherwise: the Bank 1.2 h and the Quartermaster 2.0 h, levels 19-22 but one (24); signals every 7-14 min on
six; the reach's longest stretch 101-377 min; level 50 now never on five (the x5.0 taper overshot; 3.0 had 7.7-11.4 h).
Stopped here for Matt's review (morning, 16 Oct).

**D27 (16 Oct, Matt: "proceed with your thoughts for XP and scrapper; change the ladder's reach clause").**
- The shock Scrapper's trap: before the Carpet Man's ledger the Fence is shut and nothing sells, so the bot's spares
  filled the stash (91 of 91 cells: eight secondaries, six primaries, nine stacks of rounds), nothing more was picked
  up, and the runner never got the kit for him. The bot bins a spare for its scrap while the Fence is shut (the Kit
  room's bin, 13 Oct), sells it after. Reproduced on a fixed seed and cleared.
- XP_TAPER_END 4.0 (between 3.0's 7.7-11.4 h and 5.0's nevers).
- Gate 6's reach clause (balance_gates.md, the summary): the reach a level an hour or better on average from the
  Radio to hour 12, and never 3 h without one; signals every 20 min kept. The read records `reach_rate`.

**D27's two-read (summary_d27x2.md, 30 reads, 3 reds):** the shock Scrapper's trap gone - the Bank 1.6 h, the
Quartermaster 2.2 h, the band 1.7-2.8 h, the capstone, Kev's story, the plain floor all green. Red: level at the
Quartermaster on one (24); gate 6 on eight - the reach 1.9-3.4 levels an hour (the pace green on all), but its longest
stretch over 3 h on four (175-430 min) and signals 28-84 min apart on seven (the hour-9-10 Yard moves among them);
level 50 at 9.3-10.1 h on four, never on two.

**D28 (16 Oct).** The review of D27: the rounds restock throws out a spare for a box only when the Fence is open (with
it shut it binned one a pass, six a tidy, for nothing); the summary merges `reach_rate` by the median, a never if any
read's Radio never opened. CURVE reward 0.08 to 0.05: the strong builds out-earned the rest up the reach (level 50 from
9.3 h to never); a signal's pay now rises slower than it gets harder.

**D28's two-read (summary_d28x2.md, 30 reads, 2 reds):** every campaign gate green, levels at the Quartermaster green
on all ten. Red: gate 6 on three (the reach's longest stretch 134-344 min; signals 25 min apart on one); level 50
never on six (41-49 at 24 h), 11.6 h on one.

**D29 (16 Oct).** XP_TAPER_END 4.0 to 3.4.

**D29's two-read (summary_d29x2.md, 30 reads, 5 reds):** the band (1.4-3.5 h), levels at the Quartermaster (two
Scrappers, 24-25) and the cash sink (one read) red on single reads against D28's green - read noise; gate 6 on four
(longest 212-267 min, signals 37 min on one); level 50 "never" on five. Read by read, level 50 runs from 8.2 h to past
24 h, and the same build lands either side of the window (a fire Drifter 8.2 h and never; a frost Paramedic 17.9 h
and never): the spread is read to read, not build to build, so no one XP setting holds both reads of every build in
12-24 h. Stopped for Matt's call on gates 6 and 8 (16 Oct, morning).

**Gates 6 and 8 by the median (16 Oct, Matt: "judge by the median").** Gate 8: level 50 on the median element read
(a never counts later than any) between hour 12 and 24, and no read before hour 8. Gate 6: per build the signals (20
min) and the reach's pace (a level an hour); the reach's 3 h longest stretch on the median read. D29's reads under
them: retirement green (the median read 16.9 h, 7 of 20 never); gate 6 red on one build's signals (37 min, the move at
hour 8); the band, two Scrappers' levels and one cash read red as single reads (green on D28). The confirmation next.

**The confirmation (summary_d29x2b.md, D29's numbers, 30 reads, 2 reds):** every campaign gate green (the Bank 1.5 h,
the Quartermaster 2.0 h, the band 1.7-2.3 h, levels 18-21 on all ten), Kev's story, loot, cash, scrap, the plain floor
green; retirement's median read 16.6 h (4 of 20 never) but one poison Paramedic read at 7.2 h, under the 8 h floor;
gate 6 red on three builds' signals (42-55 min) - every one of those gaps after a Yard move at level 50 (hour 7-11),
the campaign again and the Radio shut till its Quartermaster.

**The read's ladder ends at the first move (16 Oct).** balance.gd measures gate 6 (and the reach's pace) to hour 12 or
the first Yard move, whichever is sooner: the ladder is the first Yard's. The re-read next.

**The pass closed (summary_final.md, D29's numbers, 30 reads, 2 reds; Matt, 16 Oct: "stop after this").** Green: the
Bank 1.5 h, the Quartermaster 2.2 h, the band 1.5-2.7 h, the capstone, Kev's story on all ten, retirement (the median
read 21.0 h, no read before 8 h), no reds, the gang clock, the loot tables, the gamble, the cash sink, scrap, the
plain floor. Red, left for the playtest to calibrate: levels at the Quartermaster on one (a fire Scrapper at 23, a
level over); the reach's longest stretch on the median read 196 min (the gate 180). Every other gate held on the last
three two-reads. Next: the mythic uniques' design and their art, then Matt's playtest of the 15-16 Oct UI.

**The mythics (16 Oct, Matt: "mythics look good - lets get them in the game").** Seven, one a slot (docs/design/
mythics.md, as built at its foot): one find in 10,000 anywhere on their own dice, none held twice before all seven,
worn at any level, never lost (the clock, a death, a lot sale, Equip if better), off in the balance read and the loot
read. Smoke: `_mythic_checks` (the seven and their words, the pools, the roll's rate on fixed dice and the main dice
untouched, none twice, any level, each rule, never lost to the clock). The review's: the Cap without keystones, the Van
x4 (not endless), a worn mythic never swapped or lot-sold, the shelf's total without them.

**The art in (16 Oct).** Matt reimported in the editor, applied docs/muzzle_after_reimport.diff (the muzzle points on
the new pistol, SMG and improvised hands; the smoke's flash check now wants open air 6 px ahead of each muzzle - the
old points sat on the arm and passed) and generated the seven mythic pictures (tools/pixellab_items_mythics_manifest.
json); the full smoke passes. All seven read as their objects at their footprints.

**The papers' codes as chips (16 Oct, Matt's playtest: "the notes are inconsistent ... chips for what the notes
unlock but literally scrambled and garbled unicode").** Before the Radio every paper reads alike - "encrypted till the
Radio's open", its words its flavour alone - with three chips of glyphs (Greek, Cyrillic, symbols, all in Inter), the
same paper garbled the same way, coded or not. After it: the code, its bite in red and its pay in green; a paper with
none says "no code: a line of the before" and has no chips. Smoke: `_paper_pass`, every paper's card in the Kit both
ways (fits; glyphs only before; the code first after). Was: the eight codeless papers said "from before", and the
coded ones' words opened "A code in the margin, encrypted".

## Parked for the UI pass after the playtest (16 Oct, Matt)

1. **The fight's walls at the new frame's size.** The bigger frame (C10.1) scales the walls up and the patched joins
   show: repeated textures, clipped seams. Regenerate the backdrops at the size they're drawn (a manifest, test art
   first).
2. **Special rounds' bonus as a chip.** A grade's "+N% damage" shows as the card's big headline figure; it reads as a
   chip, as the papers' codes do now.
3. **Everything on an item a chip** but its headline figure (a gun's damage, armour, cells, finds and the like): the
   affixes, rules, codes and grades already are; the rest of the card's loose text lines to follow - a design pass
   with mockups first.
4. **Hands art for every weapon (16 Oct, Matt: "equipping a bat and seeing a hammer just reads wrong").** The run's
   first-person hands are drawn by kind (`RunView._hands_kind`: pistol, SMG, rifle, shotgun, improvised, melee,
   blade - seven pictures), so a bat shows the hammer. One picture a base: 60 primaries (13 rifles, 12 improvised, 12
   shotguns, 12 SMGs, 11 melee) and 22 secondaries (10 pistols, 6 SMGs, 3 improvised, 3 melee) - 82, fewer where a
   secondary shares a primary's look. The lookup by base with the kind's as the fallback, each gun's muzzle point and
   direction with it (the smoke's open-air check per picture), and melee's swing split. A manifest, test art first;
   likely in batches by kind.
5. **The pick card's flavour line cut short (16 Oct, Matt: "we're losing flavour text").** Since the Bin button
   joined the action row, the card's bottom sentence (`PickPanel._words`, `UI.fit_sentences`) shares the row with
   Equip / Workshop / Bin and fits to a word or two ("Light...", "A bat from the sports shop..."). The sentence wants
   its own line (or the row's room), with an assertion that a card's flavour is never cut.
6. **The radio line with more life (16 Oct, Matt: "colour code the text from the various voices and broadcasts and
   add some garbled unicode messages into the mix").** `radio_line.gd` scrolls every line in one colour. Each voice
   (`Words.RADIO_VOICES`: the loop, Kev, the army net, the Clinic, the Fence) gets its own colour, and garbled
   broadcasts (`ItemHead.garble`'s glyphs) are mixed in among the ambient lines - unread traffic on the air. A
   mockup of the palette and the garble's share first; an assertion that each voice's colour reads against the panel.
   **Done (16 Oct):** `radio_line.gd`'s VOICE colours as the canvas drew them (loop aab4bf, Kev f0a868, the net
   c2b67e, the medic 8ccbe6, the Fence d6a0e0), a line's voice from its `Words.RADIO` entry. `Words.RADIO_TRAFFIC`
   (eight lines of air under what you can hear) plays as traffic: before the Radio a line in five, all glyphs in
   6f7780; after it a line in twelve, with a word or two through in its voice's colour. A line just heard is never
   held back for traffic. Smoke: Kev in Kev's colour, the shares shut and open, every glyph in Inter's cmap, each
   voice at 4.5:1 or better against the panel (7.8-9.2) and the grey at 3:1 (3.6).
7. **The Manager redrawn, and an arena for each head (16 Oct, Matt).** The Manager reads small beside the other
   heads. Measured, he's full height on the 128x192 frame but thin: 62 px wide standing (the others 78-82) and 53 px
   firing (the others 80-84) - a slim figure in a suit, so a rescale alone would stretch him; likely a regen at the
   others' build, or a wider pose. And each head gets his own backdrop in place of the site's plate: the Gamekeeper's
   barn, the Carpet Man's warehouse floor, the Manager's vault, the Quartermaster's stores - four pictures at the
   fight's new frame size (with item 1's walls), test art first, then a manifest.
8. **Moving through a site (16 Oct, Matt: "3 changes per level so the player moves position in each - ending in an
   extract site in the last one").** A run's pool split in thirds, a new position at each: the frame moves on (a pan
   or a cut, as the search's pan does now) to a new plate and wall. The third is the way out - the extract, where the
   search's crates are; on a head's run the third is his arena (item 7). Visual only: `RunView` already knows the kills
   and the pool, so no sim change. The cost is the art: 12 sites have one plate and wall each; three positions is 24
   more pairs, plus the extracts (one a site, or one a zone - 4), each with its three figures' feet read off the
   picture (`SITE_MID` / `SITE_NEAR` / `SITE_FAR`) and the smoke's floor check over each. Made with item 1's walls at
   the new frame size, as one manifest; test art first - likely one site through first to see it reads.
9. **Running dry at the Bank (16 Oct, Matt's playtest).** Level 10, the Bank again: the drum shotgun went dry mid-run
   ("Drum shotgun: dry"), the run's dps fell to 4.5 (the Van's Spare near dry too: 15 hollow points in the stash), the
   clock ran out at the door, and CLOCK_LOSE_KIT took the riot suit and plate rig (and the rig's rounds and meds) - as
   designed; both are in `loose_kit`. The cause: 110 slugs sat in the stash, and `_feed` only moves rounds when the rig
   has none of the type. Three changes, agreed:
   - **Top up at the start of a run:** the worn guns' rounds from the stash into the rig's spare room, not only when
     it's empty (a sim change: smoke and reviewer). **Done (16 Oct):** `_top_up()` at the gate (before the insurance
     and the odds read) and on coming home (so the card reads the rig that goes out); each gun's best grade before
     either's second; meds kept; logged. Smoke: `_ammo_checks`. (A smoke flake seen once: `_events_checks` 3 of 40.)
   - **A "rounds short" chip** on the site pick when the rig's rounds won't last the site's heads at the runner's fire.
   - **The time-out's line says it all:** the rig's contents went with it, and the lost pieces may turn up on a gang
     member later (`loose_kit`), so the loss doesn't read as final.
10. **A site's gear level, as the runner wears it, and finds he can use (16 Oct, Matt's playtest).** The site card's
   Finds tile and kicker (`missions.gd:235, 248`) show the site's item level - the Bank's "level 6 gear" - while
   `Items.wear_level` asks level 14 of it (ilvl x WEAR_PER_ILVL - 1.5); the Radio's card (`radio.gd:463`) already
   converts. Matt: "if the bank says it drops level 6 gear then my expectation is that i need to be level 6" - the
   formula stays, the card says the level to wear it. And every find rolls at the site's item level exactly, so a runner
   under it brings home a stash he can't wear. Agreed: **20% of gear finds roll at the highest item level the runner
   can wear now, capped at the site's** (the Bank at level 10: level-9 gear), the card reading the range ("level 9-14
   gear"); uniques, sets and mythics as now. **Signals too (16 Oct, Matt: level 22, a signal dropping level-29
   gear):** a signal's finds go through the same roll (`t["level"]` is the signal's), so the fifth at the runner's
   level lands on both; the Radio's signal card (`radio.gd:463`, already the wear level) reads the range as the site
   card does. A sim change that moves gear supply: smoke, reviewer, and a bot balance read for the gates after; an
   assertion that both cards' level is `wear_level` of the finds, and one that a signal's finds carry the fifth.
   **Done (16 Oct):** `FIND_AT_MINE` 0.2 in `_find` (the plain roll and its re-rolls; uniques, sets and mythics at the
   site's), the fifth on a base no deeper than `gear_tier()` (the review: a deep signal's tier-7+ bases at a low item
   level, as a gamble already rolls); the Runs kicker "gear for level N", both Finds tiles `finds_words`. Smoke:
   `_find_at_mine_checks`.
11. **A "?" on the map: what a site pays (16 Oct, Matt: D4's Torment list).** Mockup on the canvas ("Fiat - Map tier
   guide"): a Depths tab (a site picked by zone; depth 1-12 rows with the site level, the gear level to wear, gangs,
   XP and cash, drops, rarity, unique odds, and what opens - sets, the site's own unique, a head at full strength, the
   convoy, the deep tiers; the runner's depth marked) and a Where-to-farm tab (the heads, the sites' own uniques and
   their depths, what each site leans to). Built after item 10 (its gear column reads the wear level); UI only.
   **Done (16 Oct):** "What a site pays ?" at the Map's zone row's end opens `tier_guide.gd` over the room, on the
   zone's first site. By level (the review: a site runs at depth 1 since B7.2 and depth comes by signals, by level, so
   the ladder is a signal's, not the mockup's depth rows): the sites down the left by zone; a row a signal level from
   four under your reach (never under the site's own) - the gear to wear (red past your level, "20% at N" under it
   when your fifth is lower), gang HP and XP & tins against a campaign run there, drops and rarity on it, the
   loose-unique chance, and chips for what opens (set pieces, the site's own unique, a deep tier, uniques at their
   cap); your reach marked. Where to farm: the heads, their uniques, what they open; mythics, sets and loose uniques;
   each site's own unique, the signal level it drops from and whether it's on the shelf; where each gun type and kit
   kind leans. From level 10, the lowest a signal rolls; the endgame curve shown before the campaign is done too.
   From `sim.guide_rows` over `depth_figures` (effective's plain part split out; the fingerprint
   unmoved, 2 h a build), at `tier_depth(level)` as a signal plays. The zone tabs fit their names every refresh
   ("· locked" dropped when the tally's button narrows them).
12. **"Fire proof" and "fire resist" read alike (16 Oct, Matt).** Two stats: `fire_res` is the resist alone (5-35);
   `fire_proofed` (armour and helmets, 5-20) is the resist AND the element's damage, its chip "+N% fire proof" hiding
   the damage half - and the Fire tree's notable is called Fireproof too. The chip says both halves ("fire res & dmg"
   or two chips), with item 3's chip pass.
13. **BUG: the trees' damage-over-time nodes do nothing (16 Oct, found on Matt's question).** Fumes (Petrol, +20%),
   Cumulative (poison, +15%) and Nicked (bleed, +20%) carry `effect: dot_pct`, but `_dot_add` reads
   `_affix_sum("dot_pct")` only - gear, never `tree_sum`. Checked headless: Fumes trained, `tree_sum("dot_pct")` 20, a
   burn pool from 100 landed the same 50 with it as without. Every other node effect has a reader. Fix: the tree's
   share in `_dot_add`; and a smoke check that every effect in `Data` trees moves a number when trained (an orphan
   can't recur). Matt parked it for after the playtest (16 Oct). Moves the dot builds' numbers: a balance read after.
   **Done (16 Oct):** the tree's share in `_dot_add`, on their pools only (the review: `_dot_add` fills `my_dots` too);
   `_tree_effect_checks` reads every node effect's reader in the source and Fumes grows a burn on them, not on you.
   A `dot_pct` affix on the runner's gear grew the dots on the runner too; Matt (17 Oct): "gear boosts only your
   dots" - `dot_grow(false)` is 1, and the smoke checks a burn on you ignores the gear's +50% while one on them takes it.
14. **One damage figure that holds everything (16 Oct, Matt: "hard to gauge what anything in the petrol tree actually
   does for my damage").** `dps()` is the hits alone (guns x level, affixes, attack); a burn, poison or bleed is extra
   and shown nowhere, so a DoT node reads as nothing. To design together (mockups): the headline damage a second
   includes the dots at their steady rate; the Stats sheet's chain splits it (hits, then burn / poison / bleed); and a
   tree node says what it would add ("+N a second, +M%"), worked by the try-on as an item's compare is.
   **Done (16 Oct):** `sim.damage_split()` - the hits by type (`type_dps`) and each dot's settled rate, rate x ratio x
   grow (worked against `_dot_add` / `_dot_tick` in the smoke: a pool fed for 200 s deals the split's burn). The total
   is the top bar's figure (the split in its tip: the slot's fixed width has no room for the mockup's "N of it burns"),
   the Armoury strip's, the run's "Your fire" x pace, and the Stats sheet's headline with "321 from hits · 31 burning"
   under the chain (its last row now "= base", the hits before the types' increases; first shot moved to the status).
   A node's chip reads "For you: +N a second (+M%)" or, trained, "Adds +N", by `node_damage_gain` (the tree with it
   and without; none when it adds nothing). **Found building it:** a fire or bleed pool (one stack) already sat at
   its cap, so `dot_pct` - Fumes, Nicked, the affix - only filled it sooner: about +0 in a long fight. Matt: "make the
   change but don't balance after" - the cap grows with `dot_grow()` too (in `_dot_add` and `_dot_fill`), so +20% is
   +20% burn. The dot builds' numbers move: balanced after his next playtest, with its new numbers.
15. **The run's band, simpler (16 Oct, Matt: "too much info here now ... keep that panel simple").** `run.gd`'s band
   (around line 262): the kicker "Depth 1 · The City" goes; the right column's "1:38 in · clock 7:12" goes (the
   clock's headline, time left, is the one clock kept); the unit loses "ticks while they're on you" / "stopped while
   it's clear" (just "left"). Kept: the site's name, the time left and its bar, the kills bar, the gangs / convoy line
   and the capstones. The way out keeps its own unit ("to the way out · see them off"). The fit check over the band
   with the shorter words.
16. **The run's runner panel, below the band (16 Oct, Matt's playtest).** `run.gd`'s fight tiles, the rig and the take:
   art on each tile (Matt's painted `dps`, `hp` and `cash` icons where they fit; Their fire, Kills, Armour, Rounds new,
   with the art pass); "Fire in" becomes "Their fire", as the site card says it; the rig's cells larger, each keeping its width (they read as thumbnails now); the take one strip - tins with the icon, the pack's
   fill as a bar, "passed over" and "swapped" small - moved down to sit above the button (Matt), the hint ("Leaving
   keeps the loot") inside the button, so the rig takes the space between: 72 px cells over two rows. Mockup on the
   UI pass canvas, approved by Matt (16 Oct); a fit check that a rig cell is never under 72 px.
17. **Affix chips always in their short form (16 Oct, Matt: "res not resistance - looks odd when you see them side by
   side").** `Chips.show_chips(..., shorten)` lays every chip long and drops to the short forms only when one won't
   fit, so a pick and its compare beside it can read "+14 bleed res" against "+19 bleed resist". The item head's
   affix chips take the short form always; the shorts read over once for any that only make sense long (with
   item 3's and 12's chip pass), and the smoke checks two heads side by side use one form.
18. **Papers: no price, and the story's line whole (16 Oct, Matt: "remove tin price from all papers - adds nothing").**
   A paper's pick shows its worth twice - the kicker's "8 tins" and the headline "6 tins at the Fence"; both go for
   every paper (the headline becomes what the paper is: Kev's story, a code, encrypted). The right column's third line
   (`Sim.paper_lines`, "Its three together make the beat's signal") is fit to one line and clips; it wraps, with an
   assertion that no paper's lines are cut. And a story paper's tail says "no code: a line of the before" - true of
   the code, wrong of the paper: it says Kev's story's beat instead.
19. **Kev's papers: a gamble for papers at the Radio (16 Oct, Matt's playtest).** Five papers, a signal made of three,
   and it won a story piece: two plain and one of Kev's left, and neither kind makes a signal (`decrypt_block`: any
   three plain, or a beat's three together), so the papers stall till a plain one drops. Agreed: "Ask Kev" at the
   Radio buys a plain paper for **notes** (the Radio's own money; about two runs' notes on the deepest site, as
   `GAMBLE_RUNS` prices the Fence's in tins), rolled at `gamble_level()` with a find's rarity (a rare one rolls a
   signal deeper); **never a story piece** - those stay earned on the signals. And the Radio's papers show the two
   kinds side by side, each with its count of the three and where the next comes from. Mockup on the UI pass canvas.
   A number-changer: in with 9, 10 and 13 before the balance read; the price is the read's to set.
   **Done (16 Oct):** `kev_price` / `kev_block` / `ask_kev` (the campaign first, as a signal; deep papers on `dug_depth`'s
   scale, the review), Kev's box under the decoder, the papers' line counting plain and Kev's; the bot buys the rest of
   a signal; the playtest read counts Kev's notes. Smoke: `_kev_checks`. (The papers' page arrows 40 to 44 px: the smoke
   with 30 papers caught them short.)
20. **Decrypt, animated (16 Oct, Matt: "a decrypt animation ... the panel to the right shows some codes").** On Decrypt:
   the three papers fade off toward the panel; the panel's lines come in as `ItemHead.GARBLE` glyphs flickering,
   then lock left to right one line after another (the fix, the site, the level and gear level, an extra, the codes
   last, each code's chip lighting in amber as it locks); a frequency readout tunes and locks, a level meter settles,
   a scan line runs down. About 2.5 s, a tap skips; nothing in the sim waits on it. Interactive mockup on the UI
   pass canvas.
   **Done (16 Oct):** the signal is made at the press as before; over the new card a panel 2.5 s long (`radio.gd`
   `start_decrypt`): the frequency hunting, a meter, the card's lines - "A FIX ON", the site, level and depth, the crew,
   the codes - resolving left to right out of the radio line's glyphs, each at its moment, and a scan line down it.
   The Decrypt button reads Skip meanwhile; it, or a tap on the panel, goes to the end; leaving the room ends it.
   Smoke: running and the button a Skip; 1.3 s in the site is through, the codes still coming; at the end the card's
   own; a tap skips with no second signal; the glyphs in Inter Regular, Medium and SemiBold.

**The playtest closed (16 Oct, Matt: "the gear gating is frustrating").** The read (docs/balance/playtest.md): 2.0 h
played, 36 runs, no deaths; the Manager at 1.3 h (level 14), the Quartermaster at 1.5 h (level 17 - the bot's target
18-22), level 22 at 2 h; the Bank wounded 5 runs in 6; 1 run out of time (the dry shotgun). Matt's call: work through
the fixes and changes above now, **but park the fight's look until after another playtest** - items 1 (the walls),
4 (hands per weapon), 7 (the Manager, the arenas), 8 (moving through a site, the depth-map test) and item 16's new
tile icons (its layout goes in with the icons it has). Order: the number-changers (13, 9's top-up, 10, 19), a bot
balance read, then the UI items one at a time.

**The read after the number-changers (16 Oct, 30 reads, 5 red -> Matt: "I'll take your read on it").** The four in, the
campaign ran ~40% faster for the bot (the Manager 0.9 h, the Quartermaster 1.6 h), a Doorman as bleed bought 48 papers
off Kev and retired at 6.5 h, two builds at level 23 at the Quartermaster, the City's epic+ 18%. Done: gates 1-2's bands
set from Matt's playtest (BANK 0.8-1.4, QM 1.1-1.8 bot hours, his 1.3 h / 1.5 h by hand); Kev's price a kill's notes at
the reach's depth (44 notes at the campaign's end, 88 at reach 22). Gates 4 and 12 to re-read after the next playtest.
**Done from the UI list (16 Oct):** 15 (the band: the site, the time left), 18 (papers: no worth, Kev's story's tail
and its line whole), 17 and 12 (affix chips always short; proofs "res & dmg"; loot/gang, loot/med).
Then 2, 3, 5 (the tail as chips; rounds led by their count, the grade a chip; the gun's feed a chip; the flavour whole in
the pick's column), 9's chip ("Rounds short: N of ~M" on the Runs card, the stash's rounds counted when there's a pouch)
and its line (the rig's contents, where the kit went, the gun that ran dry). And the odds' key: its runner half worked
once a frame while the Runs screen reads (the smoke's City tiers starved on Matt's machine; 78 frames now).
Then 16 (the runner panel: the rig at full 64 px cells over two rows down to the take - the room between the six and
the take holds two rows of the stash's own cell, not the mockup's 72; the take one strip; the run's line over the
button; "Their fire"; Matt's dps and hp icons on two of the six).

Mockups for the pass (16 Oct, the canvas "Fiat - UI pass mockups"): 14 (the one damage figure, the Stats sheet's
hits-and-burn split, a node's "+N a second"); 2, 3, 5, 12 (the item card: the tail as chips, special rounds led by
their count, proof naming both halves, the flavour on its own line); 9, 10 (the site card's gear to wear, the
rounds-short chip); 6, 9 (the radio's colour a voice with the colours as tweaks, garbled traffic 1 line in 5, and the
out-of-time line). Item 11's on "Fiat - Map tier guide". **All approved by Matt (16 Oct)**, the radio's voice colours
and the garble's 1 in 5 as drawn.

**The first levels quicker (16 Oct, Matt's playtest).** A fire Drifter by hand: level 2 at 27 minutes on the Retail
Park (site level 3), every drop wanting level 4-6 - the bot farms to its levels, a player pushes on under them, and
D19's XP_SCALE 2.9 slowed the first levels a fifth. `xp_scale` climbs from XP_RAMP_FROM 1.0 at level 1 to XP_SCALE by
XP_RAMP_TO 12, unchanged past it: level 2 at 83 XP (was 240), 6 at 706 (1,486), 10 at 2,080 (3,346), 20 at 11,588
(12,963). Matt starts a fresh save on it; a balance read after his session (the bot's level at the Quartermaster
likely a level up).

**Before the second playtest (17 Oct, Matt: "anything outside of balance").** Gear's +% dots grow only the runner's
own dots (above, item 13). An encrypted paper's chip glyphs checked against Inter Regular, Medium and SemiBold, as the
radio's are. The playtest read's new section, "The dots and the drops": a run line carries what it dealt and the dots'
ticks of it, the one figure and its dot part, the +% dots worn and trained, and its gear finds - wearable when found,
and at the runner's level from a site over it - so the balance after reads the dot change and the fifth at yours from
Matt's play, the campaign's and the signals' apart.

**The flavour cut on two rows (17 Oct, Matt's shot: the blank-firer's "It fires...." beside a Knife).** Two rows were
laid at FLAVOUR_H each, 20 px, under the label's real 22 (font height and line spacing), and the label ellipsised the
second. Now two rows are measured from the font at 16, 15 and 14, the first whose two rows the room holds and whose wrap
falls in two lines; else the whole sentences of one row. Smoke: the shot's own pair, every row showing, inside the box.
The smoke clean with the game closed (one earlier run passed bar the saves guard: Matt was playing).

**The quick balance pass (17 Oct, Matt's second playtest: "too quick to the point that the outskirts are pointless - I
hit the parade while still at level 1 and dropping level 4 gear at level 1 feels off").** Gates set up front: 16, the
level at each site's first clear from the Parade on within 1 under and 3 over the level to wear its gear; 17, the
Gamekeeper beaten at 0.3-0.5 bot hours (Matt: "about 25 minutes" by hand) at level 3 or more; the Bank and the
Quartermaster 20 min later (1.1-1.7 h, 1.4-2.1 h); the level at the Quartermaster 20-24 (the Barracks' gear is 21).
Reads (summary_E0/E1/E2.md under docs/balance):
- E0, the build as it was, 5 RED: the Parade at level 2 (gear 4), the Bank at 10 (gear 14), the Gamekeeper at 6 min at level 1.
- E1, 4 RED: the Outskirts and the Streets 2.5x the HP, 2x the fire, 3x the XP; the Town and the City XP x1.3; the City's
  quality .38 to .32 (the loot gate's epic share 18% to 15.8%, green). The Gamekeeper overshot to 48 min; the Town two short.
- E2, 5 RED (stopped here, Matt: "unless there's something major, stop after this one"): the Outskirts eased a quarter
  (240/290/330 HP, 0.35-0.5 fire), the Streets 330/0.5; the Town's XP 17/24/28, the Retail Park's 10, the City's 37/45/57.
  The Outskirts green (0.4 h at level 3); levels/gear Parade 4/4, Retail Park 5/6, Pleasure Park 8/9, Shopping Centre
  10/11, Bank 12/14, Services 16/16, Hospital 18/19, Barracks 21/21 - the Bank one past the gate's one under. Red: the
  Bank's time 1.0 h (a bot timing gate, Matt's playtest calibrates it), and the slowest build's noise - the band 0.9-2.2 h,
  the Scrapper as fire at level 26 at the Quartermaster and a 22-min signal gap. Matt playtests on this; the rest after.

**The fight kit's manifest (17 Oct, Matt: "per weapon fight arms, wall regens, missing art for the fight stat boxes",
before the parked Doom-style fight).** tools/make_fight_kit_manifest.py writes two: the test
(tools/pixellab_fight_kit_test_manifest.json, 14 jobs: hands for a bat, a pump shotgun, a bullpup, a carbine, a crossbow,
a big revolver, a knife and a garage rifle; the Parade's plate and wall at the new size; the four tile icons) and the set
(tools/pixellab_fight_kit_manifest.json, 110: hands for all 82 gun bases, 12 plates and 12 walls, the 4 icons). Hands to
art/fight/hands/<base>.png at 280x210 (the 256x192 at HANDS_SCALE x VIEW_SCALE on screen), styled on each base's item art
and framed on the kind's hands; plates 744x320 and walls 744x173 to art/fight_new/ (the frame draws them at 950 wide; the API caps at about 512x512s worth, so the largest at their shape, scaled x1.28)
beside the live ones; icons their_fire, kills, armour, rounds to art/ui_new/ (64x64, styled on Matt's dps and hp). The
code that reads them (a base's hands first, the kind's the fallback; each new picture's muzzle point; the new plates and
walls; the tiles' icons) once the test pieces are judged.

**The fight kit in code (17 Oct, Matt: "start working on step 3 ... as the art generates").** `run_view.gd`:
- Hands per gun: `hands_tex` takes a base's own picture (art/fight/hands/<art_slug>.png, the manifest's slug) before its
  kind's; drawn HANDS_VIEW_W wide whatever its pixels (`hands_scale`: the kit's 280 at 0.73, the kind's 256 at 0.8), its
  drawn corner on HANDS_CORNER as before. The gun in hand (`gun_in_hand`) is the primary while it fires, else the
  secondary - the fight's own rule - so a secondary's hands show behind a dry primary.
- Its flash: the kind's shape at the picture's muzzle - `find_muzzle` in its upper part (the kit's arms come up from the
  foot), a pistol's or SMG's topmost drawn pixel, else the long gun's furthest toward the top left, pointing from the
  gun's middle out through it; `MUZZLE_AT` puts right one it misses (the police carbine's: the finder took its sight).
- The kit's plate and wall (art/fight_new/, read before art/fight/ for _plate and _cover names) drawn as the old 688
  across (PLATE_VIEW_W, COVER_VIEW_W), the wall's top at COVER_TOP and its fill scaled with it; the slots and the pan keep
  their numbers. A kit pair's slots are placed under "<site>@kit" (F3/F5 saves there - the review caught it saving over
  the old pair's), the old pair's placing its start.
- `run.gd`: the six's icons - Matt's dps and hp and the kit's their_fire, kills, armour, rounds (art/ui first, else
  art/ui_new, read off the disk if not yet imported); 30 px with the keys at 16 so "Their fire" fits a sixth of the row.
Smoke: `_kit_hands_checks` - the slugs, every base picture there its own and at the kind's width, a kind's fallback where
none, every kit flash on a drawn pixel into open air, the gun in hand dry/fed/a bat, the kit's Parade pair drawn as the
old with its slots under @kit, every tile with art its icon; the near one's cover check over every base picture too.
Seen once and passed on a rerun: "Paid in notes did not add a note" (the atlas check, kit-dependent) - raised with Matt.

## While the fight kit generates (17 Oct, Matt: "anything you can do in the meantime?" - all four)
- 54256f0: MUZZLE_AT by hand for the police carbine, security guard's carbine, army SMG and riot squad's SMG (the finder
  took a sleeve or stock); the atlas check's "Paid in notes" flake was the Traffic Warden's Hat doubling notes a kill -
  the check expects its multiplier now. Smoke all pass, reviewer OK.
- Hands checked as they land: 40 in, all read (the last, the machete and pipe wrench, fine). Matt's side moved the guns
  to the big revolver's down-the-barrel view (the manifest's DOWN_BARREL / LIKE_REVOLVER / STOCK_LOW) - the four
  overrides are for the pictures as they are; a reroll of one of those four wants its override looked at again.
- The Doom-style mockup on the canvas "Fiat - Moving through a site": 1 in, the move (three stills, ~0.5 s push, the
  wall drops), 2 deeper, 3 the way out (the last third, then the crates on the floor - the search), the head's arena in
  place of 3 on a head run (the head plus the last third as guards). The pool in thirds, the first taking the
  remainder (the Parade's 10: 4/3/3). Deeper and the way out are stand-ins (the Parade pushed in / mirrored); the arena's
  is the Retail Park.
- tools/make_doom_test_manifest.py -> tools/pixellab_doom_test_manifest.json: the Parade's deeper plate and wall and its
  way-out plate (no wall, an open floor for the crates), styled on the new Parade pair, written to art/fight_doom/.
  Not committed till Matt passes the mockup.
- (17 Oct, Matt: "A plus your suggestions with the grouping"; convoy on the first Allotments run) the six rebuilt -
  mockup A in THEM | YOU panels, red on fast fire / no meds / dry, a blade's 'melee', smoke _six_checks; roll_event()
  keeps a random convoy out of runs_total < CONVOY_FROM_RUN (5). Smoke pass, reviewer OK. Raised, not done: the Weed
  Burner reads 'dry' (red) with no rounds though it needs none; no bandage source before the Gamekeeper opens the Clinic.
- (17 Oct, Matt) START_STASH_BANDAGES 5 in a new camp's stash (start() - a Yard move's fresh camp gets them too); the
  Weed Burner's rounds '∞' muted. Smoke pass, reviewer OK. Balance around his playtest use of the bandages.
- (17 Oct) tools/review_art.bat: the fight art review, headless - every site's fight (kit or OLD ART marked), the four
  heads at their sites, all 82 guns' hands with the muzzle marked -> docs/review/. Reviewer fixes in (the wall fill's
  tile scale, off a swing's frame). Not painted: flash, bars, words, glass, particles.
- (17 Oct, Matt: "do everything as you suggest") Sound in engine: World/Bed buses, indoor echo, duck/hurt low-pass,
  gang-arrival dip, placed incoming shots (run_view.shooter_spot), kill-streak pitch (real seconds), find_mythic,
  decrypt ticks. Smoke pass, reviewer OK. Raised: the swing-parts check flakes (the test's shotgun has no rounds, so
  gun_in_hand can keep a melee secondary) - a test fix, asked first.
- (17 Oct, Matt: "make the UI changes and the swing hands fix") Item cell dressing (wash, glow from epic, sheen on
  unique/mythic, mythic pulse); LEGENDARY fff07a, SET 3fd4e8, MYTHIC ff4a1c; mythic_moment.gd (held game, flash, grey,
  card, Take it); site card's reasons under the odds below 60% (missions.odds_reasons); swing-hands flake fixed. Smoke
  pass, reviewer OK. Raised, not done: a mythic can be passed over or swapped out of a full pack (_pack_keeps).
- (17 Oct, Matt: "make the mythic change") _pack_keeps counts a mythic. Smoke pass, reviewer OK. Raised, not done: a
  mythic still lost when nothing in a full pack is big enough to swap with, and one left on the floor at the run's end
  (extract, time-out, death bring home only the pack's).
- (17 Oct, Matt: "go for it") A mythic into a full pack with nothing its size (over the size), and floor mythics home on
  extract, time-out and death (_floor_mythics_in). Smoke pass, reviewer OK. Raised, not done: a normal extract into a
  full stash drops a mythic (stash_put fails, the loop moves on); deaths and time-outs append, so they're safe.
- (17 Oct, Matt: "go for it") A mythic home to a full stash is appended whatever the room. Reviewer: every automatic
  path now brings a mythic home (pack, floor, extract, time-out, death, insurance, Yard move). The bulk sell already skips
  mythics. Not a loss: auto-equip (equip_best) can take off a worn mythic for a better figure; it goes to the stash.
- (17 Oct, the art review; Matt: "agreed on the code fix for the walls", reroll 5 hands, the Bank wall after he's seen
  it in game) RunView.wall_top: a wall's first row >=60% drawn at COVER_TOP; smoke asserts every wall's (WALLS_OPEN for
  any on purpose). review_art shoots undocked. Smoke camps mythics_on=false after new/load (a new and loaded camp
  checked on first). Raised: 'no number came off the hits' failed once, passed on rerun - wants its state printed.
- (17 Oct) The five rerolled hands and the air pistol checked: all read, the down-barrel view; close protection SMG's
  muzzle by hand (the suppressor's end). The numbers check prints its state on a miss. Base fight art: complete.
- (17 Oct, Matt's two playtests: "early game still needs a little work"; "build all 4 but don't run a balance pass")
  The first gun (Data.FIRST_GUNS on a Garden Centre clear while no gun owned and none home; _pack_keeps and the Bins keep
  it, home whatever the room), rounds only for owned types (half the hand's), no wound before the Clinic, resting shown
  (main.resting_words, the HP reason's "full in"). Smoke pass, reviewer OK. For the balance pass after his play: the
  Gamekeeper and the Outskirts against a gun at the second site (the 25-minute target).
- (18 Oct, Matt: "a language and general UI pass ... lets do it all today") The words pass: tools/strings_corpus.py
  (4,482 strings by screen), a 46-shot gallery, style guide v2 (docs/language/style_guide.md: two voices, caps by role,
  the glossary; Matt's calls: levels only on screen, lower "the" mid-sentence, the Pitch + the Yard, "first of each
  gang", set in South Wales), two reviewers and an editor -> 832 string changes, 24 renames, 37 duplicates, 18
  questions, every one approved by Matt on the words-pass page. Batch 1 of 4 (wrong facts + cuts): 112 strings, the
  Clinic's Heal/wound tiles cut (they duplicated and disagreed with the buttons), the Council 4-piece's locked crates
  wired (never was), stale depth log lines gone. Room cards: each box a strip of existing art (Matt: option C, "use the
  art as you have it"), card 840 high, smoke asserts it. Two smoke flakes fixed (sell-commons counted papers; the
  reasons check read unsettled odds). Smoke pass x2, reviewer OK. Raised for Matt: tests/bot.gd still climbs site
  depths, so the bot earns Dial points and depths a player can't (balance reads).
- (18 Oct) Words pass batch 2 of 4 (depth, glossary, caps): 130 strings plus the code under them. Every depth on screen
  is a level now (lv_at for a site's own depth, Sim.tier_level for a signal's/paper's/site unique's Barracks-equivalent
  depth); the Yard's last two columns say the signal level that opens them (Data.yard_gate). The tree "The Rat Man"
  renamed with every key. UI.track for caps kickers (MYTHIC). The Backpack slot's card says PACK. Smoke: the inventory
  filters must name real slots (the pass had emptied the Meds tab - reviewer caught it); two more flakes fixed (the torch
  split sat on the 0.5/s line; the crowded strip). Held for Matt: S3053 (the rail's "The Pitch" -> "The Yard" contradicts
  his call 3).
- (18 Oct) Words pass batch 3 of 4 (grammar, clarity, flavour): ~540 strings. Code under them: articles and acronyms
  (Words.mid_base, a_thing), plurals in the logs, affix lines (pouch/pouches, no "+" on crowd_less_pct), the joint words
  lower-case only their first letter, "Sell when home" with the duplicate rules line gone, Stats/Clinic notes fitted,
  Map chips "40% fire · you resist", "After the Garden Centre" on a locked site, Sim.DECRYPT_NEEDS_PAPERS (a words change
  had broken the decoder note's match). Renames on nodes, Yard picks, the Dial and codes (none a lookup key). The apply
  script's line-nearest match hit wrong targets (the Triage/Live trees, the capacity stat key, half-changed duplicate
  strings); all found by the reviewer and a whole-diff key scan, all fixed. Fit-driven: "Fight · clock", "till the
  Quartermaster", "Lasting", class/unique/keystone lines shortened. Fencing's sell node "Gift of the gab" (clash).
  Held: the four voiced room-card lines (Matt: a separate change later), Daisy chain's condition (for Matt).
- (18 Oct) Words pass batch 4 of 4: the duplicates said once (Clinic bar/rig tile, Fence tab counts and shelf tile,
  run pick title, Stats band and record foot, Workshop chips, Pitch purse, Radio chips, Dial/Training/Map kickers,
  Settings, the lorry line); Matt's question calls: the Float stops meds only (rig kept; the Field kit's bandage too),
  Lie of the land = no signal rolls more than 3 under the reach, Watch rota = gangs 20% later at night, Second dog =
  searches 15% quicker, the Spare Key spends no rounds (Items.free_rounds, the bot too), the Weather set rounds away
  from zero, the wound shows its real cut, the opening's log lines gone, The mantelpiece, Radio/Workshop kickers,
  Scrap not Bin, Weapons tab, Daisy chain's condition; base/unique renames with their art (Duty pistol, Stab plates,
  Quick magazine, The Paramedic's Bum Bag, The Crash Bag; Quick fingers); the bot's depth climb gone. The words check
  is live in the smoke (banned words in the data's mechanics lines; no depth/camp/Boss/spaced kickers/format codes on
  any room). Old .import files for the five renamed pictures are left on disk untracked (deleting needs Matt's OK).
  Next: the endgame loop discussion (Matt, 18 Oct: materials per zone, combined to rebuild the world, true pinnacles).

## The rebuild (18 Oct)

- Matt went with the picks in docs/design/rebuild.md section 8 ("no balance yet"). Built: materials from runs (an
  area's two, signals' fuses; counts, never lost, kept by a move and a save), six places in the Radio's third view
  "The town" (ranks without end, costs growing, fuses and the order's things from later ranks), the town's worth, the
  Map's fifth tab "The order" with the Grid, the Archive and the Mint (signals on a host site under their own head),
  their uniques and drops, the mint's pay, Kev's closing line opening it. Purse: Materials and The town's worth.
  The bot builds the cheapest place it can. Every number a placeholder for the balance pass.

## Playtest fixes (18 Oct, evening)

- The pick panel: the item's own line always on the foot left of the buttons; hints (no rounds, no room, the level,
  the Workshop's reasons) an amber chip at the front of the tail. A locked piece against a worn one says its level once.
- The run screen: the line under the take is gone; the strip sits over the button, the run's warnings at the right of
  the take's head, nothing when all's well.
- The Map and the Radio's card: Finds is Gear level, just the number (the wear level an item's Level chip shows); the
  site kicker is just its tier. The "20% at your level" note left the tile.
- Flaky smoke checks seen today, not touched (house rule): "no number came off the hits" (1 in 4) and "the
  Twelve-Bore's kill healed" (1 in 6; likely a level-up mid-kill moving max HP in the check's sum).
- Gear verdicts (the Kit's and the run's pick, the ▲ on cells, the bot) weigh a gun by the top bar's figure, hits and
  burn together (Sim.damage_total); before, a fire build's Epic read as a downgrade from a plain Common.
- Fixed on Matt's say: the Workshop's part verdict and "Fitting it: X → Y" (Sim.damage_with_part), and the top bar's
  damage line, all on the top bar's figure. Still silent on damage: a socketable's fit (a feature, not a bug).
- Flaky smoke checks seen today, for the batch: "no number came off the hits", "the Twelve-Bore's kill healed",
  "a pistol backing a live primary spent no rounds", "no skull on your own bar with a bleed", "their poison on you
  did not come up green" (each once, each passing on re-run; give each a message that prints its state first).
- The list for after the playtest (18 Oct, Matt), in order:
  1. The flaky smoke checks (five, above): each prints what it saw, then fixed.
  2. Socketables show their damage in the Workshop (damage_with_part through the socket, a verdict and a delta).
  3. The drawn Map, layout B (canvas "Fiat – The drawn map"): the map left, a pin's card right, the order's places as
     pins appearing with their rebuild, the fifth tab gone; test art first.
  4. The Clinic (canvas "Fiat – The Clinic and the Fence", Clinic A and B): wounds stack to three, one each to the
     head (max HP), the chest (armour), the legs (pace); a fourth bad run home adds nothing; the body outline with
     each wound, what it costs, the run it came from, Treat per wound and Treat everything; the Clinic the only cure.
     The meds panel as cards: total, HP a second, stash or rig.
  5. Meds heal as they say: a share every second over the timer, stopping at full (it's a heal at the end now). A
     numbers change: in before the balance pass.
  6. The Fence (same canvas, Fence A and B): sell by rarity as rows, rounds by the box as cards (your guns' rounds
     lit), a part's pick says whether it fits your guns; the contracts as compact rows with the stash showing what
     goes (green), what would do (dashed), the rest dimmed; and the player can SWAP what goes by picking cells
     (new: today the game picks).
- The art manifest, once each reads with test art (no credits before):
  - The room intro cards their own art: today each card's three strips are cuts of the room's place art (option C,
    18 Oct); each wants pictures of its own, made for the card.
  - The rebuild: the three order uniques' icons (the Lineman's Lamp, the Registrar's Satchel, the Issuer's Robes),
    plates for the Grid, the Archive and the Mint, faces for the Lineman, the Registrar and the Issuer if the columns
    want them, glyphs for the seven materials if the counts want them.
  - The drawn Map's painted version, once layout B reads with the drawn shapes.


## The Radio's pile (18 Oct, night; Matt: "the papers dropping needs to be fixed now")

- Papers never touch the stash: a run's papers, Kev's, the story's go straight to the Radio's own pile (Sim.papers),
  read on arrival; decrypt draws from it. An old save's stash papers move there on load. The deeds, a key's paper and a
  unique (rule papers) stay in the stash.
- A signal's run home brings two papers at the least (SIGNAL_PAPERS_HOME): what it found counts (not Kev's), plain
  common or uncommon ones make up the rest, only ones a find could be at that depth and site. Beaten signals only
  (Matt): a death, a time-out or the head left standing brings none.
- The Fence's papers contracts are gone; an old save's are rolled again on load.
- Parked from the same playtest (Matt: "the rest can be parked"):
  - The odds lag after the Yard's Lookout pick, flipping fight the head or not.
  - The fight panel's "Your fire" 510 against the top bar's 362: two figures for one thing.
  - The radio loop says it's stopped, then plays straight on.
  - The Radio's town view missed the caps review ("pumping station" lost its "The" in the fit fallback; NOT BUILT,
    "Opens the Grid · the Lineman").
  - The Yard's Paper rack: half dead now papers live on the pile (charms, rule papers, keepsakes only); new job or
    new words. Matt's pick, parked for the next batch: the Filing cabinet, beaten signals bring 3 papers home
    instead of 2 (the loop breaks even), against the Container's +60 cells.
- Read from Matt's save (fiat_slot1, 1h44m played, level 25, 26 runs), for the balance pass:
  - No deaths, no wounds: the worst run cost 47 of 152 HP; at the Barracks regen out-heals their 4.3 a second. 16
    painkillers and 2 bandages sit unused in the Clinic. The Clinic's wounds (item 4) won't show in play unless runs hurt.
  - The Fence's deep contracts paid 15-32k tins each (about 92k in ten minutes) against 1.3-2.6k for a Barracks run.
  - The paper loop: 8 of 11 papers came off Kev (704 notes). A beaten signal costs 3 and brings 2 back, so it runs
    down without finds or Kev. The save sits at 2 papers and 24 notes, with Kev at 88.
  - The Bank at 39 minutes of play, all four heads by 79.
- Matt (18 Oct, night): slow the campaign so a runner enters a site at its gear level, one under at worst; and rethink
  how the balance pass runs. From his record: on first entry he was 1 level under the site's drops at the Parade and 5
  under at the Barracks (wear = 2.5 x the site's level - 1.5). 14 of the 49 gear finds from level 4 to 19 were wearable.
  To agree tomorrow: a level gate per site against fitting the scale (2 x level - 2 fits his entry levels), and the
  pass gates read from his records as well as the bot's.

## Today's list (19 Oct, Matt)

1. The exported build saves in its own folder (Godot's custom user dir, for exports only), so Matt can play while the
   smoke runs: one test export on his machine first to check the setting takes, then his slot and its record copied
   across once. The smoke's check of his saves stays as it is.
2. The odds lag after Glasses (60 test runs, not 24): the 24-run odds at once, the rest worked out over the next
   frames; a smoke check that working out the odds never holds a frame past a set time.
3. The campaign's pace (Matt took both): each site opens at its gear's level less one ("Opens at level N" on the
   Map card), and the gear-level scale moves towards 2 x the site's level - 2.
4. The balance pass's way of working: gates for what Matt feels as well as the bot's times (level on entry against the
   site's gear level, the share of gear finds he can wear, wounds an hour, contracts' income against runs'), read by
   one tool from the bot's runs and from his record.jsonl.
5. The batch, in order: the five flaky smoke checks; socketables' damage in the Workshop; the drawn Map, layout B;
   the Clinic's wounds; meds over their timer; the Fence redesign with the swap; the Filing cabinet.
6. The parked: the fight panel's "Your fire" against the top bar; the radio loop playing on after it's stopped; a caps
   pass on the Radio's town screen (Matt, 19 Oct).
Matt exports and plays once all of it is done, and tests it at once; changes then go in while he plays that build.
- Done (19 Oct): the exported build saves in %APPDATA%\Fiat (project.godot, use_custom_user_dir for exports only);
  the editor and the smoke keep %APPDATA%\Godot\app_userdata\Fiat. tools\playtest.bat reads the exported build's
  autosave first. At the next export, Matt copies every fiat* file from the old folder to the new one, once. Playing
  from the editor (F5) is a separate set of saves from now on.
- Done (19 Oct): the Map's lag. Measured on Matt's save: a Map paint (ten a second) cost 25 ms - the odds' key worked
  for every site (12 x dps, armour, HP, pace) and the came-back button restyled from scratch (11 ms, thirteen theme
  overrides). Now 7-8 ms: the key once a paint (Sim.odds_scope), a button's look set once (UI.style_button skips the
  look it has). With Glasses the figure shows at 24 runs and the rest read behind it (Sim.odds_ready). Still: one dry
  run a frame always runs, 10-20 ms for a head's fight on the cloud's CPU; less on Matt's.
- Flaky smoke checks seen today, for the batch's first item: "the Manager down did not drop the deeds" and "the
  fight tiles are off" (the Fight tile fell to its "clock 5:12" form); each passed on re-run.
- Done (19 Oct): the campaign's pace. Gear wears at 2 x the item level - 2 (was 2.5 x - 1.5); each site first opens
  at its drops' level less one (Sim.site_gate): the Parade 1, the Retail Park 3, the Pleasure Park 5, the Shopping
  Centre 7, the Bank 9, the Services 11, the Hospital 13, the Barracks 15; the Map says "Opens at level N". A cleared
  site stays open (a new runner after a death goes back). On Matt's record he'd never have met a gate, and every
  site's drops would have been his to wear on entry. Every item's level to wear drops on load: pieces he couldn't wear
  can be worn now.
  - For the balance pass: until the runner reaches a new zone's gate, the gamble's level and price, the deep
    contracts' level, the Fence's and the Clinic's stock tier and the body pieces' verdicts read the last open site.
  - Matt's call, later: a new zone can open with all three sites shut for the level; the Map lands on that tab.
- Done (19 Oct): the balance pass's way of working (docs/design/balance_gates.md, "How it felt"). tools/feel_gates.gd
  reads five gates off a chronicle - level on entry, gear to wear, wounds, deaths, contracts against runs - and judges
  them the same on Matt's record (playtest.md, "How it felt, judged") and on every bot read (summary.md, "(as
  played)"). A gate is green when both are. Two thresholds PROPOSED, for Matt: 60% of the campaign's gear wearable
  as it drops; contracts' tins at most half the runs'. On his 18 Oct record: gear 35% RED, wounds 0 of 23 runs with
  the Clinic open RED, contracts 382% of the runs' tins RED; level on entry green at the new scale. A one-hour bot read
  went red the other way on entry (the Bank at 15 against its gear's 10): the bot grinds where Matt pushes on.
- Flaky, for the batch: "charms are 3 of 400 finds; 5% was the aim" (device, once; 11-22 on twenty fresh reads).
- Done (19 Oct): the flaky smoke checks, all eight. Each was the fixture, not the game: the deeds' fate left from
  earlier play, a target still coming in when the shot fired, a level-up inside the Twelve-Bore's sum, a gang killed
  and searched before the pistol fired, Guard outlasting the bleed, too little poison to number, codes leaning the
  charms. Each message now prints what it saw. One wording fix with them: a fight too long to print says "over 5:12"
  (it fell to "clock 5:12", the fight gone). Eight loops on Matt's machine before: one red; nine after: none.
- Done (19 Oct): socketables in the Workshop. In a gun's socket: "Fitting it: X → Y dmg/s" and a verdict on the top
  bar's figure (Sim.damage_with_part with the socket named). In a helmet's or the armour's socket: the body's figure
  the Kit judges by, "Fitting it: stands the fight 1.8× → 2.0×", and its verdict (Sim.body_with_part). Like the gun
  parts, the figure is the gun fed: with the rounds out the top bar reads lower.
- Done (19 Oct): the drawn Map, layout B, in test art. The map at the left (scripts/ui/map_view.gd): the four zones
  as areas with their roads and river, a shut zone hatched, each site a pin in its odds' colour, the order's places as
  amber diamonds once their rebuild opens them; the picked pin's card at the right (the old column, one now). The tabs
  are gone, the order's fifth with them. A pad or the keys step the pins (left/right, up/down). The smoke checks no
  two names on the map cross and all sit inside it. For the art manifest later: the painted map in these shapes.
- Done (19 Oct): the Clinic's wounds and meds over time (Clinic A and B). Wounds stack: one a run, to the head (max
  HP), the chest (armour) or the legs (pace), three at most - a fourth bad run adds nothing and says so. The Clinic's
  left: the body with each wound marked, a row a wound (what, its cut, the run it came from and the HP when it hit,
  Treat), the HP resting, and one button for the lot; the band's chips are the cuts. The Meds tab is cards: what each
  heals over its time, HP a second, stops at full (or the share to Guard), stash or rig, Into the rig. Meds heal as
  they say: a share every second, the end-of-heal work (Transfusion, Clean hands...) as it finishes; a med at full
  HP with nowhere to spill isn't taken. For the balance pass: three wounds cost three times one; meds land slower.
- Done (19 Oct): the Fence redesign (Fence A and B). Shelf and Stash: the side sells by rarity - a row a rarity, its
  pieces, what they fetch, Sell - keeping back an upgrade on what's worn (and papers, mythics, the deeds); then rounds
  by the box, your guns' types first and lit, the rest named under them. A part picked says which gun it fits, a line a
  gun. Contracts: his list as rows (kind, ask, pay, how far the stash gets it, Hand in, Pass) and his mate; the stash
  stays beside it, marked for the picked contract - what goes (green ring), what would do (dashed), the rest shaded -
  with the marked cells first. Pick a cell to swap: one going stays back and the next cheapest steps in; one that would
  do goes and the dearest going steps out. The pick lasts while that contract does (a pass, a hand-in or a load ends
  it); one picked sold, the gap fills cheapest first, never with one kept back unless nothing else will do.
  - New smoke check: no code name shows in the words (it caught the band's "3 n_ready" from a rename).
  - For Matt: the rarity rows still sell rounds, meds and grenades (as the old Com tile did) - the starter bandages go
    with Sell on Common. Keep them out of the rows (rounds have their boxes)? One line in Sim._spare.
  - Device run 61 logged a one-off leak at exit (2 objects, 1 resource); run 62 clean. Watch for it.
- Done (19 Oct): the Filing cabinet. The Stash's fourth pick's other side (was the Paper rack): a beaten signal brings
  at least 3 papers home, not 2 (Sim.signal_papers_min). Papers and charms take their cells again. The bot never picks
  that side, so the balance reads don't move.
- Done (19 Oct), the parked:
  - Your fire: every fire tile on the run screen shows the top bar's figure (damage, the hits and the burn), the pace
    beside it while it fits ("362/s ×1.41") - the fight lands the two multiplied. It showed the product (510) before.
  - The radio loop: the strip plays only the loop's latest heard line, so once "The loop's stopped" is heard, it's
    stopped - in the traffic too - till the new currency's message brings it back.
  - The caps pass on the Radio's town: "Rank 2" and "Not built" in sentence case; the name gets the room the rank
    leaves ("The pumping station" whole); "Opens the Grid · The Lineman"; the chips' short forms capitalised.
- Done (19 Oct, Matt's answers): the rarity rows keep rounds, meds and grenades out (Sim._spare); a zone stays locked
  till the runner reaches its first site's level (Sim.zone_gate, zone_level_shut; a site cleared keeps it open for a new
  runner), the Map's zone says "Locked · level N required" and what's next names it; the Clinic's body is the runner's
  own drawing from the Kit, the wounds marked over it (the drawn outline only for a past with no drawing); the room
  cards' tiles: the Map's "Zones · Each opens at its level", the Clinic's "Treatment · Wounds and HP, for tins".
  Open questions closed: the feel gates' thresholds to be judged on Matt's playtest; a new save each build.
- Done (19 Oct): the Map's painting wired (map_view.gd). A zone's ground (art/map/zone_<key>.png) fills its shape, drawn x2
  nearest; a site's picture (art/map/site_<slug>.png, 64 px) stands above its pin with a pool of shade, a click on it
  picks the site; a zone or site without its picture keeps the drawn look. The names keep room for the pictures whether
  made or not; four pins moved clear of them (the Garden Centre, the Shopping Centre, the Grid's and the Archive's). The
  smoke: every picture inside the map and on no name, pin, diamond or other picture; the ground 2x its box; a site's
  picture 64 px. In: the Outskirts' test (its ground and three sites). Next: the rest of the manifest.
- Done (19 Oct, Matt: "fill those sections with cloud or fog in engine"): the land past the zones is fog - a shader
  (map_view.gd FOG_SHADER) behind the map's drawing, banded cloud in 4 px blocks drifting slowly. Known: Godot's TIME
  rolls over hourly, so the fog jumps to a new pattern once an hour; it runs under the zones too (a quarter-size
  SubViewport would cut its cost to a sixteenth, if the Deck's battery asks).
- Done (19 Oct): the room cards' boxes show their own pictures (art/room_boxes/<room>_<n>.png, all 27), cut to the box
  across the middle; the old cut of the room's art only where one's missing. The Map's land past the zones: Matt found
  the fog alone too sparse - tools/pixellab_map_land_manifest.json makes art/map/land.png (508 x 420, drawn x2 under
  the lot); with it in, the fog drifts over it as thin banks (the shader's over_land), without it the fog stays solid.
- Done (19 Oct, Matt: "a single image with everything on it ... then we carve it up in the game"): the Map is one
  painting, art/map/map.png (512 x 424, Matt's, prompted by hand), drawn x2 from (-3, -2). The zones' shapes, the pins
  and the order's diamonds are traced off it; the picked site's zone is lit (a warm wash, an accent outline), a shut one
  hatched. Gone: the zones' grounds, the sites' pictures, the land and the fog (their files sit unused in art/map/;
  their manifest jobs dropped). The smoke: the painting fills the map, every pin and diamond inside its own zone, no two
  pins too close to click apart, the lit zone follows the pick.
- Done (19 Oct): the order's three heads' art in - each one's place on the order card (Data.PINNACLES' art) and on an
  order run's band, a face, the fight's stand/fire/down, the unique's icon (found by name). Their fights still stand on
  the host site's plate (the Services, the Bank, the Barracks); plates of their own would be another art job.
- Done (19 Oct, Matt on the painted Map): a pin's name is the name only (the odds, the gate, what's before it are the
  card's), sitting snug on its own pin; the key a small packed strip of dots and words. Two smoke fixtures that left
  state behind fixed (an incendiary box in the rig fed the "plain" gun; a bought box of rounds topped up a stack).
- Done (19 Oct, Matt: "tiled clouds ... cover the entire map except unlocked regions"): art/map/clouds.png (114 px,
  Matt's) tiled x2 over everything but the open zones, two drifts crossed and mirrored top to bottom to hide the seam;
  the open zones cut out of a mask at a sixth of the map (soft edge), cut again when a zone opens. Over the painting
  and the pins, under every word; the key on its own layer above it. The hatch only stands in without the tile.
  Known: the drift snaps once an hour (TIME wraps). The smoke: the cloud under the words and off the clicks, its mask
  clear on an open zone's pin and clouded on a shut one's and the moor, every pin 12 px clear of its zone's edge.
  - For Matt: a gun found with the Fence shut brings its box only if the pack has room; a full pack passes the box
    over (a smoke fixture tripped on it; it now gives the pack room).
- The outstanding art's manifests (19 Oct, Matt: "everything outstanding - the map ... needs drawn art either way"):
  tools/make_outstanding_manifest.py writes three. The test (4): the Map's Outskirts - its ground, clipped in code to the
  zone's shape (so it can't drift off the pins; roads, river, pins and hatch stay drawn on top), and its three sites'
  64 px vignettes under their pins. The rest (30): the other three grounds and nine sites; the order's three heads - a
  face, the fight's stand/fire/down, their place for the order card, their unique's icon. Optional (9): the order's
  three keys and six materials (copper wire has its item's). Layout references: art/reference/map_layout*.png. Every
  file new; nothing live touched. Wiring after the art lands: map_view.gd draws art/map/zone_<key>.png and
  site_<slug>.png; Data.PINNACLES' "art" to the order's own places (The Grid, The Archive, The Mint).
  - Already written, not in these: the room cards' strips (tools/make_room_box_manifest.py: the Map's 3 as the test,
    then 24). Parked till after a playtest: the fight's look (the head arenas, moving through a site, the Doom test).
- Today's list is done. Matt exports and plays: at the export, copy every fiat* file from
  %APPDATA%\Godot\app_userdata\Fiat to %APPDATA%\Fiat once.

## What you haven't found (20 Oct, Matt: "scrambled like the radio broadcasts ... removed the 'locked' text entirely")

- Done: Fmt.scramble(text) - the Radio's glyphs, the same each time for the same name, spaces kept. A place is known
  once its zone is open. Scrambled while not: the rail's shut rooms (no "Shut" badge; the name trimmed to fit), the
  Map's zone names and every pin's name (a shut zone's status reads "Level N required" or "After <the zone before>",
  no "Locked"), the Site guide's zone headers, sites (disabled), its title and the farm tab's heads, uniques and opens
  lines, the Barracks shelf's gaps and their "where". What's-next and the Yard gates no longer name a shut place.
- Done: the cloud seam. The mirror (the V Matt saw) is gone; each axis crossfades into a half-tile-shifted copy near
  the tile's edge, so any tile Matt drops in as art/map/clouds.png tiles without a seam either way.
- Matt's call: known follows the zone gate, so a death that shuts a zone by level scrambles its names again. The other
  way is a stored "known" that never goes back.
- The smoke: a fresh camp's rail, map, guide and shelf name nothing shut; a sweep of next_words, the shelf's gaps and
  the Yard gates for shut names.
- Matt (20 Oct): known stays tied to the zone gate (names scramble again under a level shut); fine as built.
- The Radio, agreed (20 Oct): a signal from 1, 2 or 3 papers. 1 (faint): 7 to 2 under the reach, up to 2 codes, no
  head or convoy. 2 (clear): 5 under to the reach, 3 codes, the extras at half odds. 3 (full): 3 under to 1 over,
  4 codes, the extras as before. A rare paper still +1; Kev's beats still their three; a signal's run still brings 2
  papers home, so a faint one grows the pile. Mockup on the canvas "Fiat – The decoder, one to three papers" (Matt: "yep build it").
- Done (20 Oct): Data.SIGNAL_GRADES (replaces SIGNAL_ROLL); a laid-on signal's codes capped at its grade's, Long wave
  and Long range on top; both ends of the band floored at REACH_START, and a faint win never moves the reach (at the
  first reach its band is the reach itself), so it pays no Dial point either. The decoder: the grade in its head, the
  slots past the first "optional", the most codes and the extras, whether a win moves the reach, "Decrypt · N papers".
  The bot makes a one- or two-paper signal only when none is held. The smoke: none to four papers' blocks, each grade's
  band, codes and extras, its odds summing to 1, six faint signals at reach 20 (no head, no convoy, under the reach, two
  codes at most), a faint win at the first reach leaving it, and the decoder with one paper in.
- Done (20 Oct, Matt's red lines on the painting: "repaint your zones in accordance with the attached"): the four zones
  retraced off his guide (his image registered to map.png, the areas between the lines filled, each line split
  between its two sides). The motorway strip along the top and the moor south of the Town stay no zone; the road strip
  between the Estate and the Outskirts on the west edge went to the Outskirts. The Estate's name moved down to
  (12, 180), inside its new top edge. Every pin 30+ px inside its zone, the order's three inside theirs.
- Done (20 Oct, Matt: "the grid, archive and mint also need to be encoded"): Sim.order_known - an order's place
  rebuilt and its host site's zone open. Till then scrambled: its name on the Map (dim, and its pin doesn't pick), its
  card (place, head, words, drops, Go), the Town's "Opens X · who", the shelf's order gaps, the rebuild's log line, and
  the order's key items (Sim.key_known: held, or the place that drops it known) in the Town's rows, chips and notes. A
  picked place gone unknown gives the Map's card back. Words.scramble holds the glyphs now (Fmt's calls it), so the
  sim never loads a UI script.
  - For Matt: the smoke's "the takings took the sale" check is wrong when takings already sit above the sale (takings
    is a moving average); it failed once at run 85. Fixed (Matt: "change it now"): the check reads the takings moving
    at a quarter's weight toward the run's sale and cash, exactly; the away bonus held off for it.
- Done (20 Oct, Matt: "Where to farm and the X button dont work on the site guide"): the guide's two pages were its
  full size and over its tabs and close, passing the mouse, so a click never reached them (the smoke only emitted
  pressed). Both pages ignore the mouse now. The smoke clicks for real: _click_target picks the control under a point
  as Godot does, and every visible button (disabled too) in each room at the start, and the guide's on both tabs, has
  to take a click on its middle. A sweep before the fix found only the guide's three.
  - For Matt: "no site read low enough to show its reasons" failed once (run 92): it needs a Risky site and the
    camp the earlier smoke rolled can read all six high even hurt with no meds. Fix proposed, not made.

## The playtest batch (20 Oct, Matt: "we're back into batch mode now so nothing gets done until i provide a save file")

Logged, nothing built till the save lands:
1. The smoke's "no site read low enough to show its reasons" fixture (run 92's one-off fail): parked till after the
   playtest (Matt).
2. A gun's compare (the Kit's pick against what's fitted) reads right only with its rounds in the rig; it should read
   the same with or without them.
3. Gun sounds, the runner's and the gangs': one shot's sound on every muzzle flash. Now the sound keeps its own cadence,
   apart from the flashes, the gangs' in their firing pose too; inconsistent by gun (the shotgun's seems right).
4. For the balance pass: HP regen is too strong in the campaign (1 HP/s on any piece steamrolls; Matt's compare: a
   Padded jacket, 10 armour and +1 HP/s, read as an upgrade over a Riot suit, 85 armour, at "21% odds"). His options:
   keep it out of the pool till the Barracks, or tone it down (0.2, 0.4, ... the higher tiers 1, 2); and look at the
   other strong affixes for a gate the same way.
5. The Pitch: a row whose room isn't open yet (the Radio's, the Bench's in Matt's shot) reads scrambled, its name and its
   upgrades' words, till the room unlocks; the same rule as the rail's shut rooms.
6. The Map: with the City open, the last cloud goes too - the motorway strip along the top and the moor south of the
   Town (no zone of their own) clear with it, so an all-open map has no cloud left.
7. The Kit: an attachment's name clips in its slot on the gun card (the Hundred-round drum reads "Hundre" in the
   Magazine slot). Fix the fit, and an assertion over every attachment's name in every slot.
8. The Pitch: a node's cost climbs on every click of it, without buying (Matt's video, 20 Oct). Fix, and a smoke check
   that picking a node changes nothing but the pick.
9. The fight screen's rig shows empty pouches (two, in Matt's shot) while the rig is full on the Kit ("12 of 12
   pouches filled", Take into the rig off): the two screens count pouches differently in some case. Find the case,
   make them agree, and assert it.
10. The Fence's stashed items (the shelf to buy from) want the standard compare against what's fitted, as the Kit has
    (Matt's shot: the Paramedic's Bum Bag shows a "Fitted now" line and Sidegrade, not the full side-by-side).
11. Kev's story has no payoff on screen (Matt: two beats done, "where are the story beats explained or displayed once
    you complete a mission?"). Today: the beat's "made" line on its signal card, a "Kev's story n of 3" chip on the
    Radio, and the "won" line only in the log ticker. To design with Matt: Kev's won line on the came-back card after
    a story win, and a place on the Radio to read the beats done (the story so far).
12. The stash's tabs, refreshed (Matt: "one of the last things that hasn't been touched by our refresh work"): Uniques
    and Sets tabs; Paper goes (the pile's on the Radio since 18 Oct; only the deeds, a head's thing and a unique's rule
    paper still keep the stash - they fold in elsewhere); Meds splits from rounds (inventory.gd's Meds tab is Medical,
    Ammo and Grenade today) - Rounds a tab of its own, grenades placed in the mockup. A mockup on the canvas first.
13. The Workshop's affix jobs (Matt: "how do i lock an affix on this screen? this one and the rest makes no sense"):
    picking an affix row gives two jobs, "Re-roll this one" and "Keep it, re-roll the rest" (the lock), but the card's
    width drops them to their last forms, "This one" / "The rest", which say neither what's kept nor what's rolled.
    Redo them: the job names the affix ("Keep +15% fire damage, re-roll the rest"), full width or stacked so the long
    form always fits, and a line before any pick saying a row can be picked to keep it or re-roll it. Mockup first.
    Matt (20 Oct): two kinds of re-roll, told apart - the figures (the same affix, a new value and tier) and the affix
    itself (replaced by a different one). What the Bench does today (Items.reroll_one / reroll_affixes): "this one"
    re-rolls the picked affix's figures; "the rest" keeps the picked one and replaces the others with different
    affixes; the job "Re-roll the affixes" replaces every affix. Missing: every affix's figures at once, the affixes
    kept. The mockup names each by what it does (figures vs new affixes) and adds that one.
    Matt's design (20 Oct), replacing the above: a padlock on each affix row, and two jobs for what isn't locked -
    "Re-roll values" (the same affixes, new figures) and "Re-roll affixes" (new ones). To settle in the mockup: how many
    padlocks (one today; the Pitch's Two locks keeps the best of the rest - it could become a second padlock) and what a
    lock adds to the price.
    And a range on every affix (Matt: "is 15% fire the max i can ever roll?"): its tier's low-high, and the best tier
    this piece can reach (its rarity's cap, its item level's floor), so a roll reads against what's possible.
14. The Workshop shows three affix rows, fixed (workshop.gd builds range(3)); an Epic has four and a Legendary five, so
    the last one or two can't be seen or picked. Rows to the most a rarity carries (five), laid out with item 13's
    padlocks; a smoke check that every affix on a piece has its row, at every rarity.

### The save's read (20 Oct, docs/test_saves/playtest_20oct.save; docs/balance/playtest.md)

Fire Drifter, 2.7 h played (+1.6 h away), 41 runs: the Bank 29 m (level 10), the Quartermaster 50 m (17), Kev's story
and the lorry 1.8 h, level 30 2.6 h. No deaths, one wound; every run set off at Safe 100%, regen worn 1.0 HP/s (median).
28 signals, all three papers, all 25 run won; the reach to 21, no stall. Matt and I agree: too easy end to end, regen
first. His points for the pass, to design:
15. Materials after Kev's story: flooded in some, short of others (this save: cable drums 49, copper wire 14, fuses 12,
    army kit 6, ledgers 4, glass 3, paving 3; nothing rebuilt), and no way to farm what's short - a signal's material is
    its site's (Data.SITE_MATERIAL: paving, ledgers and army kit one site each, the others two; an Outskirts landing
    gives its crew's area's first), and the site is random. And it's never said when or where a material drops
    (material_odds is on no screen).
16. The Pitch's move: open once the campaign's done (can_move_yard); Matt wants it the last thing you do, once progress
    has truly stalled and you need what a move gives.
    Agreed (20 Oct, Matt "agree on all counts"): 15 - a signal's material is its crew's area's, of the two the one held
    fewer of more likely; the odds on the signal card ("Brings: paving · 32%") and on each campaign site's card; one
    paid way to aim (a Dial node, or Kev's pile picking a crew's area for notes). 16 - the move shut till the reach has
    stood for a stretch (say 10 signals with no gain), the Pitch saying the ground's played out when it opens.
17. Kev's story signals came in 3+ under the reach every time (Matt): STORY_UNDER is 5 (D4: the head at full strength
    reckoned three levels' worth). For the pass: nearer the reach.

### The batch, built (20 Oct)

- Done (items 2, 3, 7, 9): a gun's try-on reads its best grade of rounds in the stash as well as the rig; on the fight
  screen each shot shown is one shot's sound and each figure's firing pose one of theirs (off screen the sounds keep
  their own time); a part's name in its slot is whole or its first word, the type stepping down rather than a word cut;
  the fight's rig places every item (first fit, else the widest first, else one row). Smoke checks for each.
- Item 8 (the Pitch's prices climbing on a click): not the click - prices rise with the camp's clock (inflation), and the
  screen only redraws on a click, so they jump then. For Matt to decide (see the reply).
- Found: the smoke's main is never in the tree (added in _init), so is_visible_in_tree reads false - checks filtering on
  it checked nothing. The room-wide click sweep is dropped (anchor-laid controls have no size out of the tree); the
  guide's, sized in code, stays. Next: the other checks that filter on it.
- Flake seen once (run 107): "a ammo_tin's finds are 0 of 300 Ammo" - passed on the rerun; logged with run 92's.
- Done (items 5, 6): a Pitch row whose room isn't open reads scrambled (its name, its upgrades' names and words, its
  rank), its prices and glyphs plain; with every zone open the Map has no cloud left. Smoke checks for both.
- Found by the words sweep, now really reading the screen: the Radio's empty-signals line ("Three papers ... a campaign
  site") - now one to three papers, "a site".
- Mockups for Matt (canvas "Fiat – The playtest batch"): the Bench with padlocks, tier ranges and five rows, two jobs
  for what isn't locked (13, 14); the stash's nine tabs, the sort an icon (12); the Fence's shelf in the Kit's
  side-by-side (10); the move shut till the reach stands ten signals (16); Kev's line on the came-back card and the
  story so far on the Radio, the depot again explained (11); a signal's materials on its card, the decoder's paid
  crew pick, a site's chance on the Map's card (15). Build after his OK.
- For the balance pass: regen rolls whole numbers on a 1-6 spread over five tiers, so its T1 is already 1 HP/s - the
  floor itself is the steamroll (Items.tier_range).
- Done (items 13, 14; Matt: "2 locks with one as an upgrade"): the Bench's padlocks. A row's press padlocks its affix
  (one; the Pitch's Two locks a second; one always left unlocked); two jobs for the rest, Re-roll values (the same
  affixes, new figures) and Re-roll affixes (new ones), a padlock adding LOCK_PRICE to the price (first figures). Five
  rows, each with its tier's range at the piece's level and a mark for where the roll sits. The bot padlocks then
  re-rolls. Smoke checks for the cap, the price, the keep, five rows on a Legendary.
  - Noted (the review): the affix padlock is the same glyph as a gear piece's level lock; a tint apart if it confuses.
- Done (items 8, 12, 10): the Pitch's prices rounded (to the 100, the 1,000 past 100k) so the clock's rise moves them in
  steps; the stash's nine tabs (All, Guns, Body, Bags, Meds with grenades, Rounds, Parts, Uniques, Sets; no Paper),
  each sized to its words, the sort an icon; the Fence's shelf and stash compare as the Kit's - the worn piece's card
  beside the pick, the verdict and what changes under it. Smoke checks for each.
- Found: a script error in a check ends only its function and the smoke still read "all pass" (the craft view's
  checks, runs 118-124, after the padlocks). Fixed the check; tools/smoke.bat now fails the verdict on a script error.
- Done (item 11): Kev's story's payoff. A beat beaten puts his line on the came-back card, which opens itself for it
  once; the Radio's fourth view, The story: the three beats with his lines (made, then beaten), the hours played at
  each, a beat to come still scrambled, and what's on now - its papers held and wanted, or past the third the depot
  again and what it's for. Smoke checks for the card, the view and the depot again.
- Done (items 15, 16): a signal's materials are its crew's area's two, the one held fewer of the likelier
  (1 / (held + MATERIAL_LEAN)); the signal card says what it brings and the chance, a site's Map card leads its
  conditions with its material once the campaign's done; the decoder calls a crew's area for Kev's AIM_NOTES (the crew,
  so its materials and its head if one comes). The Pitch's move waits till the reach has stood MOVE_STALL (10) signals
  run at its band (a faint one doesn't count, the review), the Pitch saying how many; the button shows, shut, till then.
  - For the balance pass: the bot's moves now wait on the same stall.
- Done (item 1, parked till after the playtest): the reasons-under-the-odds fixture reads at 3% HP, not 30%, so a site
  reads low whatever the camp the smoke rolled (runs 92 and 134).

## How the game moves on from here (20 Oct, Matt, agreed)

Features or number changes -> one balance pass with the bots -> Matt playtests -> then either more features or
changes, or straight on with his playtests. Bot balance passes don't repeat: this one (the gates above, agreed as a
starting place) is the only one. The bots set the shape (deaths, odds, stalls, every build finishing); Matt's play sets
the times.


## The balance pass (20 Oct, Matt: "Agreed - go for it")

The gates (hand hours; the bot's read at BOT_PACE): the Bank 1.5-2.5 h; the campaign 3-4 h; a death one run in 10-30,
the first by about 2 h; 5-30% of runs wounded; the median run in at 70-90%; Kev's story by about 10 h; the lorry about
16 h; the reach never standing more than about 1 h; faint signals about 90% won, full ones at the reach a coin flip;
every class's elements finish, plain builds just finish. The levers in order: regen, STORY_UNDER, the campaign's
difficulty and length, the endgame placeholders.

- Done: regen rolls tenths. The affix runs 0.2 (T1) to 0.9-1.0 (T5) HP/s at the campaign's levels, the item level's
  edge on top past it (min 2, max 10, "div" 10 in its def; Items.fig/is_tenths); the fixed ones scaled with it - the
  Vicar's Thermos 3 to 1.0, the Ambulance's overalls 2 to 0.5, its three-piece 2 to 0.5, the Council's three-piece 4
  to 1.0. Its line, the Bench's range and the Kit's compare read "0.4". Smoke checks for the roll, the row, the compare.
- Done: STORY_UNDER 5 to 2 (Kev's signals came 3+ under the reach).
- The reads: tests/balance.gd now records the signals by grade (a faint one won, a full one at the reach), the reach's
  longest stand over the whole read, the median run's odds at the gate and the first death; the summary judges the
  agreed gates as P1-P6 with the hand figures times BOT_PACE. The signal's record carries its grade and the reach.
- The baseline read (24 h, two reads, regen and STORY_UNDER in): the Bank 1.1 h and the campaign 1.8 h on the bot (Matt
  29 min and 50 min by hand: the bot is the slower here, it farms where he walked through), no deaths, 1-4% wounded,
  every run at 100%, the story and the lorry at 4.7 h, the reach standing 5-16 h once the kit stops growing.
- Found: the story and the lorry are one moment - Kev's third beat is the depot, its convoy the lorry. Matt (20 Oct):
  "One gate, ~10-13 h". The summary's story gate is 13 h, the lorry 10-13 h, both by hand.
- Done: CAMPAIGN_HOSTILE by zone, [0.9, 1.0, 1.15, 1.05] (the Outskirts as they were). Six-hour reads, one a build:
  1.5 everywhere killed eleven builds of fifteen at level 1; [0.9, 1.0, 1.25, 1.4] the Bank 2.1 h, five short of the
  Quartermaster; [.., 1.15, 1.2] the Bank 1.6 h, three short; [.., 1.15, 1.05] the Bank 1.3 h, the campaign 3.0 h, all
  ten through, 2-21% wounded.
- Done: STORY_DROP 0.5 to 0.15 (0.3 still had the story at 4.5-6 h).
- The bot (tests/bot.gd): COIN 0.5 - three held and none at PUSH, a full signal at the reach is run at a coin flip
  before one's binned (the gate's own figure); the move once the lorry's ever been beaten and the move's open (the
  ground played out), not only at level 50 (the review: lorry_done is a yard's and never comes back after a move).
- The pass's read (24 h, two reads a build; docs/balance/summary.md, 18 RED): the Bank 2.0 h and the campaign 3.0 h on
  the bot, both green (1.3-2.1 and 2.5-3.4: the hand gates at 0.85). Still red:
  - The builds' band (1.7 h to 9.3 h) and the levels: the bot farms the campaign far over its gear (the Bank at 20,
    gear 10), where Matt walked it at his gear's level.
  - Deaths (four in 30 reads), wounds over the whole read 1-4% (2-21% on the six-hour reads: the campaign's), the odds
    at 100%: the bot only runs what reads PUSH (0.88) or a first clear at FIRST (0.65), so these three are its policy's
    as much as the game's - judged at Matt's playtest.
  - The endgame's wall (P5, P4, 7, 8): the reach stands 4-16 h. The kit stops growing at the reach's 30-45 (no upgrade
    for 14 h on one read, its cash piling), the signals two under the reach read 0%, nothing runs, so the move never
    opens (it counts signals run). STORY_DROP 0.15 then left the story and its lorry never on eight builds of ten:
    back to 0.3, so it lands before the wall. The wall is the next loop's: the endgame placeholders (materials, the
    Bench's prices) and how cash buys power past the campaign.
  - Faint signals: the bot never makes one with three papers in hand, so it's unread.

### The bot's Bench, needs-led (20 Oct, Matt: "cap resistances, roll perfect gear for your build and increase hp/armour")

- Done (tests/bot.gd _bench_needs): the kit read as one figure - survival_value with the fight's length off
  damage_total (the element's hit, its increase, the dots) - and each affix's share of it. Every worn piece but a bag:
  its level raised with notes, an affix added while there's room, then dead lines (an element it doesn't fire, a resist
  past the cap) rolled away with the build's own padlocked first (conversion, increase, dots), or the weakest read
  line's values; up to six rolls a piece, stopping when it reads better, no undo. Loot, tins, notes and the like are
  never dead. Smoke checks: a dead line rolled away with HP kept, nothing under the floor, nothing done at the cap, loot
  kept, each element's own lines read live.
- What it showed (cloud 24 h reads, a build each): the frost Poacher still stood 4.5 h at reach 40 - its kit's value
  flat from hour 9 to 24, the Bench's re-rolls £110-430k for +0-7%, every signal two under the reach at 0%; the fire
  Drifter stood 1.7 h, then moved the Pitch at hour 16 and climbed to 43 again. CURVE grow 0.08 to 0.06 (an experiment,
  not kept) only moved the Poacher's wall to reach 45 by hour 11, then 7 h stood.
- The wall, read: the crews grow 8% a level both ways (HP and fire, 17% a level together), compounding; the kit's
  growth past level 20 is the affixes' 6% an item level, straight-line (no base past the deep tier 9), and level 50's
  cap. So the reach outruns the kit at 35-45 whatever the Bench does. For Matt.

## The crew (21 Oct, Matt: "this isn't an idler anymore, it's an arpg auto battler")

- docs/design/vision.md: the new vision (replaces concept.md's "idler cut" as the statement; concept.md stays as the
  history). Decided: class swap, not respec - each class its own level, XP, tree, element, kit, wounds, insurance; no
  catch-up XP; retirement and the Pitch move gone, their bonuses to an infinite paragon board shared by the crew;
  stash tabs (one shared, one or two a class); the second past gone; hardcore hidden for now; Kev's story as it is,
  no move after; gear scaling with item level past the deep tier. The reviewer runs on code in balance work, not on
  number tweaks.
- Mockups (canvas "Fiat – The crew"): the class swap screen, a signal's odds for every class, the stash's tabs, the
  paragon board. Build after Matt's OK.
- Done (step 1): retirement, the Pitch move (and its stall, its bonuses, the free nodes, the ladder floor), the Yard's
  trade and the second past are out; hardcore is hidden from the title (the code stays). Two picks that only did a
  move's work changed: the Stash's Dry store is "a second tab a class" (step 4 builds it), the map's Held frequency is
  Hold at half price. The next line after the lorry is the Radio's, not "move the Pitch". An element off a class's
  pair still stops at column 4 (a dip, not a build): the second past and the trade were the only ways past it.
- Done (step 2): the crew. Each class keeps its own runner - level, XP, tree, element, worn kit and rig, wounds,
  trait, insurance - in the roster while another's out; the Training screen's class cards swap them (the first
  press shows that class's runner in the panel, "Swap to the Poacher", the second sends them out; free, at camp
  only). A class not played comes in at level 1 with the arrival's kit. A death puts that class back to level 1
  with a trait pick and its trees refunded; the class stays. Matt (21 Oct): the Pitch's tree is the camp's, bought
  once for every class, with its own points - one a level of the crew's best class; a reset is the class's trees
  only, the Pitch's stays. The Pitch's lane says its free points. The bot trains the Pitch first from its pool.
  Smoke checks for the swap, the roster's kit, a run refusing it, the save, the Pitch's points. Three old flakes fixed
  at the root (a graded box's conversion read into the Glassing, Carpet Man and socket checks; the streak on an
  ended run; the grenade count).
  - For the balance pass: a crew has more points than one runner did (each class its own, the Pitch's beside).
  - Voiced lines to re-record (Matt): the opening's "Now" last line, the Pitch's and Training's room intros' second
    lines (proposed words sent); the text waits for the takes.
- Done (step 3): the crew's odds on a signal. Under Set off, a button a class played - its level and its odds on
  this signal as read for its own runner, the best lit, the one out greyed; a press swaps them out at camp, their
  odds coming with them. The shell reads them in its frame budget once the picked signal settles, a class a frame.
  Found and fixed on the way: a read for another class left that runner's rig a stale array (a dry run restores it
  as a new one), and the frame's odds key memo was the runner out's.
- Done (step 4): the stash's tabs. The Kit's, the Workshop's and the Market's grids carry tabs on bar two: Shared
  (every class sees it, the stash's cells as before) and the class's own, 60 cells; the Dry store adds a second own
  tab. A drop on a tab moves the piece there. A swap takes the own tabs with the class and brings the next one's.
  Pieces out of the stash (worn, sold, binned, a piece off a stack) lose their tab; a split stays in its tab, room
  read there. The junk run, the rarity row and contracts sell from Shared only. The Dry store refitted away folds the
  second tab into the first (it can read over 60 then; nothing is lost, and nothing new goes in until it's under).
  An old flake fixed at the root: the try-on key check ran out a stack or crossed dusk in its window.
- Matt (21 Oct), for step 6: all gear scales, uniques, mythics and sets included (sets went useless fast). And one
  "broken" build a class - gear and points that combine into an infinite or runaway scale, outside the balance
  passes as mythics are, there for theorycrafters to find. His playtests: one baseline build, one broken build.
- Done (step 5): the paragon board. XP past level 50, any class's, goes into the crew's pool (the runner's stops at the
  cap); each paragon level is a point on the board - damage +2%, HP +2%, every resist +1 to the cap (never past it),
  find +3%, tins +3% off a run - every class reading every point, a death keeping it. The Barracks' Also row has a
  Paragon chip once a class has gone past the cap: five cards over the lanes, a press a point; the panel says the
  level, the XP to the next, and "Reset the board" for tins as the trees' reset. The top bar and the stats sheet
  show the paragon's progress at the cap. The bot puts a point in three on resists while one is under the cap,
  damage and HP the rest; find and tins it leaves. The reviewer's two: the map's odds now re-read on a board change
  (a resist point moved nothing in their key), and the resists stop at the cap rather than spill into over-cap damage.
- Done (step 6): gear scaling. Past level 20 (the deep tier) a gun's damage and a piece's armour grow 7% a level,
  compounding, from the item level the find carries (its signal's); the flat combat lines (HP, armour, regen, life a
  kill, armour a cell or a med) grow the same way; the percent lines keep their straight 6%. Every rarity alike:
  uniques and mythics carry their find's level as before, the shop's uniques (the mate, the Back room, the gamble's)
  now the gamble's level. Set pieces keep their own base (its resist, its conversion, its look) lifted to the best
  of their type at the find's tier - damage, armour, a charm's find and cash; a bag's cells don't lift. The armour's
  cut reads the level fought (at camp the front site's), so at-level armour holds its share; a med's heal and a
  grenade's hit grow with the level fought too (they're bought low). The campaign, under 20, is as it was.
  - For the pass: base values don't grow (sell prices, the gamble's price stay flat past 20).
  - Two flakes fixed at the root in the smoke: the drop on Shared with Shared full; the Bench check, where another
    piece's added affix fired the "dead" element.
- Matt (21 Oct): no seeded saves for the broken builds - a doc per build of the points, gear and affixes to build it;
  the baseline needs nothing.
- Done (step 6b): the broken builds, one a class (Data.COMBOS; docs/design/broken_builds.md is the recipe: points, gear,
  affixes, where each drops). Each is the class's set at its count, a findable unique and its element's keystone and
  capstone; together a run's stack with no top - Embers (Drifter, a burning kill +4% fire), Clean kills (Poacher, a
  chilled kill: the first shot's bonus holds, +5% a stack), Overdose (Paramedic, poison's ticks heal; past full it's
  more poison), Opened for good (Doorman, the bleed uncapped, ×1.25 a kill), Live load (Scrapper, a shocked kill +2%
  shock). Nothing on screen says so; the run log's one line the first time it catches. Outside the balance: the read
  switches them off. No mythic in any (one find in 10,000 can't be built toward). Figures past an int's top now read
  in e-notation (1.0e30) and the run's numbers and the chronicle keep them as floats.
  - For Matt, found mapping them, not fixed: an item's or a set's "first of each gang" line is read nowhere in the
    fight (the Army 3-piece, the Issue rifle, Jump Leads, the Lollipop, the Starting Pistol); the Headmaster's Cap
    grants every notable and capstone, Hit and run included, against its own comment.
- Matt (21 Oct): "Yes fix both items." Done: an item's and a set's "first of each gang" line now counts in the fight
  (Sim.first_pct_total, read by the fight and the stats sheet alike: the Army 3-piece, the Issue rifle, Jump Leads,
  the Lollipop, the Starting Pistol); the Headmaster's Cap leaves out keystones and the nodes marked "cost" in Data
  (Hoarder, Light fingers, Ghost, Hit and run, Loud, Night work, Quiet hands, Stand and fight, Walking wounded).
- Step 7, the bot's crew: the reach stood two hours with nothing to run, another class goes out - a played one
  reading PUSH on a held signal, else the next not played, at the crew's build for it; each class keeps its own build
  to come back to; the lorry's read and the farm are reset on a swap. The read records the swaps, the crew's levels
  and the paragon.
- Matt (21 Oct): auto-run goes, as retirement and the moves did. Done: no auto-run in the sim, the save or the
  screens; the site card's foot is Set off and the insurance, the run screen's second button "Fill up, then go".
  Away (his pick): the run in hand plays out and comes home as "Fill up, then go" would (Sim.settling, the shell's
  settle only - the bot's away_on doesn't), then rest; the report says if the run's still out at the cap. In its
  upgrades' places (his picks): the Lookout's Early warning (after the clear, no gang till the first crate's
  searched; the whistle's place) and the bus depot's pack (+2 cells, +1 a rank; auto-run's rest's).
  - Comments in sim.gd still speak of an auto-run in places (6316, 7264, 7303, 7663, 7948, 9411); the code doesn't.
- Step 7, the first cloud reads (24 h, a build a class): gear scaling took the Poacher's 24 h reach from 40 to 59,
  but every read walled at the reach's ~45, and the Paramedic ran 50 → 221 in 2.5 h at 100% odds. The cause was the
  wear rule, not the curve: 2 × item level − 2 put every endgame find (item level = its signal's, 26 and up) at
  level 50, so a class under 50 fought the reach in its campaign kit and one at 50 put on a stash of deep finds at
  once. Done: Items.wear_for - the campaign's curve to WEAR_FLAT 16 (the City's 12-16), then the item level itself (a
  level-43 runner wears a level-43 signal's finds), 50 the top; Items.max_ilvl_for its inverse, read by the gamble,
  the over-level pay and wearable_level (no top at 50).
  - For Matt: the over-level pay now reads your level past 16 (it read half of it): a level-45 runner farming a
    level-20 campaign site is paid a tenth - D9's "fall off past 5 levels" as written, but less than before.
  - The bot's crew: the first cut sent a new class out every two hours (five level-1 runners, nobody at the reach);
    now the best played class goes back out, and a new one only once the one out is at the cap.
- Matt (21 Oct): the over-level fall-off stays as it is. And the reads run on his machine (the watcher's
  balance.flag), not the cloud: the convention had dropped out of my notes.
- ILVL_GROW 0.07 to 0.05: the second cloud reads (wear by item level in) ran away the other way - a Drifter at level
  50 and 10M dmg/s by hour 7. A kit probe (best of 40 rolls a slot at each level, 4 seeds): at 0.07 a fixed edge
  over the crews halves every ~25 levels, so the bot's edge (uniques, the Bench, paragon - about 100× a random kit)
  lasted ~165 levels; at 0.05 it halves in ~10. The pass on Matt's machine reads it.
- Matt (21 Oct, after the pass): one bot pass, then his playtest. The pass (24 h, two reads a build, 14:34): the
  runaway gone - the reach ends at 53-93 (it ran to 221) - then a slow climb, one long stall a read (5-17 h, most of it
  past his 10-12 h of endgame); level 50 early (median 6.3 h), the lorry at 4.2 h, Kev's story in its gate; deaths and
  wounds near nothing on the bot. 20 RED, none drastic: notes for his playtest, not tuning.
- Done: socketables a find of their own (his save: 4 in 300 finds, none his element's): Data.SOCKET_FIND 4% of every
  find, kills too, SOCKET_OWN half of them his class's pair's elements, at the find's tier or under; a mythic still
  comes first (the review). For Matt: the Fence's rarity row ("sell commons") sells plain socketables too, as before.
- Matt (21 Oct): "Proceed with all 5 and then ill play" - socketables (done above), the Build view, the Radio's code
  book in the room, the death pick in the room, the dead word menu out.
- Done: the Build view (canvas A) - the Workshop's fourth view; the old Build for scrap menu is gone (Craft's button
  opens the view). Five kind tiles with how many can be built, twelve cards a page (a pager past that), each with its
  cost and what it wants or why not; a card picked fills the pick panel (what it makes, what it takes, Build · N
  scrap). The grid shows what the kind takes (a grenade's socketable: the review) and rings the picked build's input,
  turning once to the tab that holds it. SAVE_VERSION 4 rides with it (the crew's save shape).
  - The kit key's parts are apart now (Sim._kit_parts): a try-on flake showed once (key changed in the window); the
    smoke now says which part.
- Done: the Radio's code book in the room (canvas 1). The papers' foot is a "standing codes · every site" box -
  standing 1, standing 2, the filter, each saying its code, "picking" or "not open yet" (the papers five a page, 7
  before, for the room). A slot opens the book over the decoder and the signals: None, every known code with its
  cost and pay, the ones still to learn scrambled, what's left to learn by where (papers, zones, deep), Done. A code
  picked sets it and shuts the book. The menu's gone (its title clipped). And the dead word menu (_choose_word) out.
- Done: the death pick in the room (canvas 2). After a death the Map's card column is the pick: "The Drifter · back
  at level 1", the two traits as cards with their chips (a cost in red), what the death took (the kit worn, the
  levels) and what stays (the tree's points, the stash, the crew, paragon), Set off shut till one's picked; a card
  picks it and the site's card comes back. The menu's gone; off the Map a toast says so once; the Radio's Set off
  waits for the pick too, and the came-back card stays shut over it (the review). All five done: Matt's playtest next.

## 3 Nov (afternoon): 0.12.1 - the web's art back

Matt, on 0.12.0's web: "whats with the lack of art?" - then "Fix it and run the art manifest for the missing nodes - if
those nodes arent already wired so that art can just drop in when avilable then do that too." 0.12.0's screen drew
pictures only in the big nodes: the small nodes were bare discs, the regions' emblems and the class portrait gone.
Back: every small node draws its picture by name (art/nodes/<slug>.png; one picture serves every node of that name),
else its effect's glyph (new glyphs: Guard, energy, grenades), dots at the whole web and growing as far as their
neighbours allow closer in; 20 emblems (six elements, twelve class trees, the centre, the ring) placed clear of nodes and
names; the runner's portrait faint under its start's flower. Art drops in: a picture that appears is found within 3 s
when the game runs from the project (an export needs re-exporting). Matt's machine already had all 140 small-node
pictures (the 23 Oct manifests); only Guarded, new with the web, was missing - flagged (tools/pixellab_web_small2_manifest.json,
one job, $0.08; made, art.done 15:30: a plain black padded forearm guard). Reviewed (fit; its two test findings fixed). The smoke on
Matt's machine then showed two flaky event checks (the Scrap man, "going in a tier up": they read the Allotments' kept
crates and dice left by earlier areas) - made deterministic in themselves, reviewed. Smoke green in the cloud and on
Matt's machine; lint 0. Voice: every voiced script gathered in docs/voice/scripts.md for Matt's regen (Matt: "Provide
the scripts for all the story opening scenes, room cards and class intros").

## 3 Nov (afternoon): 0.12.0 - the skill web (SAVE_VERSION 23; BUILD47 W, V and the merge)

Matt (3 Nov): "I'd like to try and get it in before I playtest - it impacts balance but we're out of whack there
anyway"; and "lets reorganise the room layout so that the rooms appear in the order they unlock". Built to
docs/design/skill_web.md: the layout generated by tools/make_skill_web.py (scripts/sim/web_layout.gd: 379 nodes, 444
links); one pool a runner, buy next to what you own, keystones at 15 points spent, capstones at 40; the start owned and
free; the element meter, element points, the Pitch's points, opened elements, the bridge, the camp owning the centre
and the elements, the level gates and the column prices gone; reset and death keep the start; a load replays a tree
under the rule; paste in passes. The Training screen redrawn (owned / can take / not yet, the node card with "Take it",
pairs, big nodes, one counter; another class's start and skills say "no use" but can be walked through); the rail:
the Clinic, the Workshop, the Fence, the Pitch, the Radio. The bot buys toward targets by the shortest path: a keystone
at 17, 40 spent at 41, the capstone at 49-53, every class. Builder's calls: the hung skills and the six third keystones
on filler slots, 25 plain hangs dropped (WEB_DROPPED), Word of mouth on an open gate, Long walks and Circuits on the
life ring. Review: two rounds of fixes (the Headmaster's Cap's capstone at 40 spent, paste and load under the rule, the
picked label's cost); fit to deliver. Smoke green in the cloud and on Matt's machine; lint 0.

## 3 Nov: the skill web designed (docs/design/skill_web.md)

Matt (3 Nov): "the class rings themselves are a bit of a mess and if you compare to poe it's just nowhere close
aesthetically or choice wise ... the center pitch tree should be the start of concentric circles that spread out and
interconnect." Six canvas rounds (https://claude.ai/artifact/4iDWcoDcXdut6c8TrQF8ku): two layouts (orbits, petals -
Matt took the petals), where a runner starts (its class's start), one pool and home no longer owning the centre, longer
paths and a capstone at 40 spent, today's nodes in the new slots (every keystone kept, one capstone a class stepped
down, nothing cut), the final screen, then each class as four small flowers (Matt: "Yes much better"). Matt asked for
the build before his playtest, and the rail in the order the rooms open with it. No code changed in this commit.

## 2 Nov (night): 0.11.0 - the lot (SAVE_VERSION 22)

Matt: "Lets just do the lot now - I havent sunk any time in". His calls: a head's thing left behind - the room at
half until fetched; the two-magazine refill - a rig affix; rival crews can kill; threads can sometimes cost you;
"the events themselves play well". Three builders in parallel (R rounds, E events, S site card), merged 3-way, a
per-diff review each, a fix round, two language passes and their fixes, a re-review, the smoke green here.
- Rounds and magazines: a magazine shows its rounds (a coloured dot, "8 of 8 · Shells · Feeds the ..."); Unload and
  Load with ▾ in the stash; "Rounds ▾" on the site card opens the rounds picker (a grade and N boxes a gun, the
  top-up tick, "Enough: 331 of ~260"), kept per site; the one-box rule gone; the bot packs ~1.2x its need. The rig
  affix "No reload pause" (a spare magazine swaps in while the spent one refills).
- Run events: the other six families (a dangerous place, a haul with a catch, a body, a wreck, a broadcast, the
  weather turning), rival crews (a fight that can kill), the Vagabond (tins and materials for gear and rumours),
  threads (tips, a robbed crew coming back, a head's weakness). The original four kept at 60%+ of events. The art
  manifest: tools/pixellab_run_events_manifest.json (38 jobs, $3.04; test 4, $0.32).
- The Map's site card redesigned (docs/design/site_card.md): one fixed layout, the Gang / Head toggle with the head
  in his interior, you against them, what it takes (with Rounds), fix chips that act, what you'll bring home, your
  record.
- A head's thing left behind: its room at half (the Clinic rests at half speed and half the shelf, the Fence's shelf,
  the Workshop's scrap, the Pitch's builds at double, the Radio holds 2 signals); it turns up again on that site's
  next clear.

## 2 Nov: 0.10.6 - the odds read, the bot's loops, speed on every screen (SAVE_VERSION 20; 92abfbb)

Matt: "just do everything now before I play" (after the second long pass and the perf review, perf44). Builders A
(game/bot) and B (UI speed) in parallel, merged 3-way, a per-diff review each, two fix rounds, the smoke green here.
- The odds' dry run steps 1 s as the live fight (DRY_STEP 2 s let a gang killed under 2 s die before it hit: County
  places read 1.00 where the runner died 5 in 6). The all-dead early settle kept (a 1-in-6 fight can read 0%: the
  alternative cost the Map and County 2.7x the reading).
- The bot: the 30-min spacing kept after a death (the 1,000+ deaths were one place retried), a place backed off 2 h
  after two losses; the best 3 of each socketable kept (the Drifter's 589 lighter fluids filled its stash, ending
  its repeats); the gauntlet never takes the build's armour.
- Past runners: the newest 100 kept, older folded into totals (`past_folded`, `past_count()`).
- Speed: the stash's arrows judged lazily on the shown page; Training laid out ahead and restated in slices; the
  floor-bag preview light; idle rooms not repainted (up to 1 s); the Radio/County/Map odds not re-asked once
  settled; sounds warmed behind the title; a boot scene (scenes/boot.tscn) shows the card while main compiles.
  Late save on Matt's machine: wear 17 ms (was ~700), a sale 47 (300+), Training 20 (900), bag pick 110 (1,500).
- Smoke: b45_budget (a mid and a late camp, tests/fixtures/), b45a areas, tests/boot_check.gd (cloud only).
- The long pass on db4ae2b (2 Nov) before it: level 50 median 13.4 h (green); the deaths and the Drifter's stall
  were the bot bugs above; the gauntlet's wall is the Docks (bleed resisted).

## 1 Nov (late): 0.10.5 - the frame-time fix (db4ae2b)

Matt: lag in fights and on the Map ("the rain"). Measured (perf43): the rain was a bystander; script work was the
lag - the stats re-read several times a frame (no live memo), the DPS line re-reading every frame. A live stat memo
(cleared by `_stats_dirty()`, a per-read context, a once-a-frame guard), the Map's and the dogs' reads stepped across
frames, the HP bars and hidden cells off per-frame work. Speed only: the fingerprint identical before and after. A
fight frame's script 13 ms median / 31 p95 -> ~2 / ~8.

## 1 Nov (evening): 0.10.4 - equip from the floor (5baa33b)

Matt, playtest: a unique on the floor couldn't be worn ("No room in the pack"); a bigger sack couldn't replace the
worn one. Any wearable on the floor has a live Equip: the replaced piece goes to the floor, a bag's or rig's contents
move across (what won't fit to the floor, said first); equip from the pack never blocked for room; a head's unique
lands on the floor like any find and still comes home if left. The bot wears upgrades the same way.

## 1 Nov: the long pass's fixes (BUILD41; PROBE40; SAVE_VERSION 19)

The designer's calls on the long pass (level 50 at 7-9 h on four of six reads; 75-100 deaths after the Quartermaster on
three builds; the gauntlets 0 of 15, the harness's doing):
- Level pace: REPEAT_XP halved on every step (25/35/45/60% of a watched run's to 12/17/22/30%; the Bunkhouse's lines
  say so) and XP_TAPER_END 4.0 to 8.0. The analyst's estimate: level 50 at 11.3-21.2 h, median 14.7. The fingerprint
  moves (XP). SAVE_VERSION 19: on the new curve an old save's level 50 reads as 44.
- A death past 50 keeps the paragon levels: only the XP into the current paragon level goes, as the XP into the level
  does below 50 since 31 Oct; the ring stays trained. One phrase for the loss: the death card ("XP towards paragon
  8" gone, "Paragon 7" kept; the kicker "still level 50"), the log ("The XP towards paragon 8 went with them; the crew
  keeps paragon 7.", only when XP went), and a new came-back line ("Kept paragon 7: the XP towards paragon 8 went with
  them"; "Kept level 36: the XP towards level 37 ..." below 50). Below 50 the chip and log say "level 37" the same way.
- The gauntlet's harness: G2 (the hour-20 camp) leaves the kit as it stood; G1's re-roll carries each piece's tempers;
  the issued step stamps the build's own piece in any slot before it buys (the coat stays on at six wanted);
  STANDARD_REACH 56, STANDARD_PARAGON 7 (12 levels' XP on the old curve buys 7 at taper 8). The h20
  Doorman's G2 in the cloud: 4 of 15 (HP 5,737 held through every place), as the analyst's probe.
- The bot past 50: acts on finished odds reads only, insures County runs and runs with half its DPS in the kit at 1.5x
  the price in hand (the stake read against the best spare in the stash), skips the coin flip under 0.8 past level
  50, and reads every figure again after a death. A run's record now keeps a signal's or order's own odds at the gate
  (they all logged -1 before); that record also feeds the run events' "Fight at the site's odds" standing order, so on
  signal and order runs it now reads their real odds where it read -1.

## 1 Nov: materials in the pack, run events (0.10.3, SAVE_VERSION 18)

Matt: "move all materials into the inventory during fights ... finding clinical supplies and having to make a decision
over bringing them or gear is a real choice"; then the runs' events: "art ... a pause in the gunplay ... choices",
recurring traders, "more than 3 ... procedural", "the events should happen in the fight window".
- Materials in the pack: scrap (stacks of 50) and the rebuild's materials (stacks of 10) are pack finds; tins and notes
  stay counters; no stash cells. A run home counts them in; a bail, a time-out or a death loses them with the pack
  (Matt: lost, like other finds); the dog's fetch and the Insurance desk can bring some home (the dog takes worn kit
  first, then the dearest of the rest). The material "Copper wire" is now "Copper cable" (the socketable keeps its
  name); its picture: tools/make_copper_cable_manifest.py (not run). The Gang-in tile's "late" form (79 px in 73) went
  in with it (Matt: keep).
- Run events (docs/design/run_events.md, the canvas approved): four families as a slice (Someone in need, A locked
  thing, A threat passing - the dogs, a fight with no pause - and A trader, the Scrap man, paid in pack scrap,
  run-only buffs, standing at 3/10/25 trades); in the lull after a site's first search; the clock stops for a choice
  with its odds on the face; standing orders for repeat runs and the bot, player-like by default (Matt). Test art in
  the scene (placeholders); the art manifest after Matt plays it. The dogs nearly always lose as tuned: the pass.
- Process: builder, per-diff review x2, the three-stage review, two language passes, two fix rounds, the smoke green.

## 31 Oct, the night round: everything open, Matt's calls (0.10.2, SAVE_VERSION 16)

Matt: "push everything thru ... put everything to me as a question and we'll do the whole lot"; then, asleep: "take
your recommendations on anything that comes up and run balance passes as required". Three builders (E the endgame,
G the loose ends, C the clean-up), merged 3-way, a three-stage review (docs-level copies: the scratchpad's
review37_*.md), a fix round, a language pass, a per-diff review, the smoke green on Matt's machine.

- **The endgame** (docs/design/endgame_runaway_31oct.md): after the Quartermaster a death costs the XP towards the
  next level, never the level (before him, as before; past 50 the paragon); signals steeper (CURVE grow 0.12 to 0.16,
  CURVE_LATE_GROW 0.07 to 0.12); percent lines stop growing past item level 20 (PCT_LINE_TOP); signal XP growth 0.05
  to 0.02 and XP_TAPER_END 3.1 to 4.0; sale worth grows 2% an item level past 20 (WORTH_GROW); the words' pool and
  drop cap at WORD_TIER_POW 1.75 (WORD_POOL_POW_TOP); the paragon adds instead of compounding and each level costs
  25% more (PARAGON_XP_GROW 0.25). Drafts for the pass.
- **The Quartermaster's Manual, the Last Orders and the Headmaster's Cap** lift the two-elements-a-class cap while
  worn; taken off, those past two idle ("idle without ..."). Their words say so.
- **Camp keystones and capstones idle below their level** (20 / 30) for any runner (C's rule, Matt: keep): "Idle until
  level N". The level gates on training were already on.
- **The Mint pays on clears only.** **The three T4 heavies** (Stab plates, Medic's harness, the Cargo frame) keep their
  home site's draw and also drop across their zone. **Expeditions average about x1.2 the cargo** with the bot's hands
  (EXP_RETURN 1.55, bad rolls and hold-ups in); shipping scrap still never beats the Fence; the exchange round trip
  can pay on small low-risk trips (Matt: acceptable; per trip x0.74-1.31 by risk and the exchange's perks, before
  wages).
- **An open element's bar fills from all the class's damage at a quarter** (ELEMENT_METER_SHARE 0.25).
- **The clean-up:** sell_commons, ditch_commons, auto_sell, buy_med, best_in_stash (moved to the bot), site_state,
  med_price, affinity(), word_totals, lane_colour, ATLAS_GLYPH, YARD_OLD, CORE_GATES, CORE_CAPSTONE gone; paper_keep
  wired (the Lock-up's Log line).
- **Words** (the language pass): the death card "still level N" and its paragon chips; the Ratter "Poison and bleed
  do 10% more damage"; the FIAT note "Beat the Issuer again and he prints more"; the Mint's chip "Pays tins by worth
  on clears"; the paragon rows "+2% damage a point".
- **The gauntlet's standard camp** is a draft (reach 55, paragon 5) until the full pass gives hour-20 figures.
- **Docs still to bring in line** (the tools review): vision.md 24, 43 and trees.md 102 (a death to level 1);
  rebuild.md 82, 95, 142 (the Mint pays every run, double with the note); trips.md 74, 178 (x0.85, "convert, don't
  print"); resets_strip_exchange.md 45 (two elements, no lift); mythics.md 23; uniques.md 21, 61; web.md (the idle
  rule); yard.md 62 (the Ratter).

## Parked from the playtest (30 Oct, 0.10.1 plus the clean-up; taken up after it)

Taken up the same evening (Matt paused the playtest for magazines as items): all six built in 0.10.2 - item 1 the
smaller rig's overflow (and taking the rig off) to the stash; item 4 by the refill from a box in the pack; items 2, 3,
5, 6 the labels, each with its smoke check (docs/design/meds_ammo_clinic.md, "Magazines as items").

1. Bug: a smaller rig keeps the bigger one's load. Three bandages in a Bum bag, swapped to a Body warmer (2 pouches):
   the Kit reads "Rig 3 / 2 pouches", the run shows two, and using one counts down from the three (Matt: "fight showed
   two but i used one and it counted it from the three"). Likely: equipping a rig doesn't send what's over its
   pouches back to the stash, and the run's view clips to capacity while the count reads the whole list. Fix: on a rig
   swap, the overflow goes to the stash (last packed first), or the swap is refused with no stash room. Smoke: swap a
   full Bum bag for a Body warmer, assert rig_used() <= med_capacity(), the overflow in the stash, and the run's meds
   count equal to the Kit's.
2. UI: while away, the rail's room labels clip through the "Away" badge ("The Map" under it; screenshot, Garden
   Centre, run 1 of 5). Fix: the label fits beside the badge (shrink or the badge moves to the corner). Smoke: every
   rail button with a badge, label and badge rects don't overlap and the label fits.

3. UI: the Barracks' selected class card reads "✓ your past" (screenshot, the Poacher). It was the pick-once
   wording; with swapping at will it should just say selected (Matt: "shouldnt say past anymore - just selected").
   The literal is in barracks.gd's card paint (UI.fit on c["tag"]); the new word goes through words.gd and the
   language pass ("✓ selected", or the style guide's word for the class you're playing). Smoke: the current class's
   card tag reads the new word and never "past".

4. Bug: the first gun can't be fired on the run it's found (screenshot, Top Farm cleared: a shotgun and a box of
   450 in the pack, Rounds "melee"). Matt first: "first gun find needs to include ammo AND the relevant mag"; then,
   corrected: the shells couldn't go into the rig during the fight, but at home, taking the box into the rig made a
   24-round pouch of shells. So the rounds were enough - the gap is the run: a found gun can be fitted from the pack
   (can_equip_from_pack) but nothing in the pack can go into the rig while a run's out (sim.gd _rig_take: no take
   with a mission on). The 28 Oct design (docs/design/meds_ammo_clinic.md) had "one by hand mid-run, slowly" - never
   built. Matt's call (30 Oct): A - the hand-load as designed. Was weighed against: rounds (and meds?) from the pack into a rig pouch mid-run, room
   permitting, or the first gun's box loaded straight into the rig. Smoke: find a gun and its rounds mid-run, fit
   the gun, load a pouch from the pack, and the next fight fires the gun.
5. UI: an ammo card's type chip reads lowercase ("Rounds" · "shotgun"; screenshot, Shells in the rig). The chip is
   item_head.gd's ammo branch (Items.type_word / the base's type, uncapitalised). Fix: sentence case on the chip
   (the SMG stays SMG). Smoke: every ammo base's card chips start with a capital.
6. UI: the Clinic's cure card clips: the big "Stops bleed" line sits under its chip below (screenshot, the
   Tourniquet; Matt: "we have so much extra space so it should be an easy one"). Seen with it on the same card: the
   chip reads "heals 0 for you, over 0 s" - vendor.gd gives every med the heal tail, a cure included; a cure's tail
   wants what it stops (or none). Fix: the head's figure line and its tail laid out with room (the card has plenty),
   and the cure's own tail. Smoke: every cure and heal on the Clinic's shelf, the figure and tail rects don't
   overlap, and no cure card reads "heals 0".

## Parked from the playtest (21 Oct, the Scrapper as shock; taken up after it)

1. The radio line repeats: "Anyone near Top Farm: the keeper there has a vet's bag. I can work with that. I can't
   work with nothing." runs twice across the row, back to back (screenshot; Matt: "still happening"). Fixed once for
   the Clinic open (dceac06); this is a fresh camp, so likely the loop with only one line heard.
   - Done: the strip never plays the same line twice running - the turn's pick keyed on the last played (a pushed
     line then its turn too); with one line heard the loop's latest fills in. Smoke checks it. Also two smoke
     flakes at the root: a build card's why-not fell back to "T2" alone (the why outlives the tier now, with a short
     form), and the kill-streak sound check ran on real seconds (a busy machine read 2 s between).
2. The Gamekeeper's unique is a downgrade: The Keeper's Twelve-Bore (Unique, level 1) reads 23 dmg/s against a
   Common Pump shotgun found earlier at 34 (screenshot: ▼ 7.9 dmg/s, with +12% dmg and +15% dmg pre-clear and "a
   kill heals 3% max HP"). Matt: "the unique drop from the gamekeeper should be better than a random gun found
   earlier - the unique here is pointless and should be the first big find of the game."
   - Done: the cause was the body's tier - a head's unique rolled at the site's loot tier (Top Farm: 1), so the
     Twelve-Bore wore a T1 Farmer's shotgun body under its own Pump. Off a head now (Items.roll_unique off_head):
     the body a tier past the site's loot, never under the unique's own base, and BOSS_UNIQUE_LIFT 1.2 on its figure
     - the Keeper's gun about 45 dmg/s against the plain Pump's 34. Off the Fence (the mate, the Back room, the
     gamble) a unique is as before. Smoke checks both. Known gap (the review): the lift reads on damage, armour and
     find, not a bag's or a rig's cells - a head's backpack or rig gets the tier, not the 1.2.
3. Training's two pools aren't clear: the band's "0 of 1 point free" is the class's pool only, the rail's "1 free"
   is the Pitch's, and the Pitch's own pool shows only in its lane's small "1 free". Matt had two points, could spend
   one in the Scrapper's trees and one in the Pitch, and asked if that was meant (it is: the Pitch is the camp's,
   one a level of the crew's best class). Matt: "it just needs to be clear" - the band to say both, e.g. "Scrapper
   0 of 1 · the Pitch 1 free", and the rail to match.
4. The rig's top-up before a run should be the player's call: it fills the rig with rounds and meds on its own, and
   Matt had to move rounds out it had put there. Matt: a toggle, or three ways - off / fill up / fill up with the
   best only.
   - Mocked up 21 Oct on the canvas "Training's two pools and the rig's top-up" (the TopUp board): on the Map's card
     above Set off, "THE RIG AT THE GATE" with Leave it / Fill up / Best grades only, a line each, kept once set.
     Shown, not yet approved in words, not built (22 Oct, Matt: "I'm 100% sure I've seen the mockup" - he had).
5. A piece ditched in a fight gives its scrap (as meant), then lies on the floor and can be picked up again at the
   search: drop, scrap, pick it up (a second ditch gives no scrap, but it's a gap). Matt: a ditched piece is gone
   once its scrap's paid - destroyed, not left on the floor.
   - Done: sim.ditch pays the scrap and the piece is gone; the floor's take-back of a ditched piece (and its scrap
     coming off again) is out, the ditch sound off the run's ditched count. Smoke checks it. For Matt (the review):
     a mythic ditched by hand is now gone for its scrap too - the "never lost" design doesn't cover a ditch; refuse
     it, or leave it to the player?
6. Art: the Scrapper's figure and portrait regenerated (Matt: "just awful"), and the Poacher's figure and portrait
   too - he reads too much like the Gamekeeper. And every skill tree node gets its own art (Matt: "the placeholder
   glyphs have served their purpose"). And the fight's cover walls: they still show heavy duplication (a tile
   repeated); Matt: generate them much bigger, one large piece you crouch behind, so there's nothing in code to fix.
   A manifest for all of it to agree with Matt before any credits go.
7. A gun's upgrade verdict in the fight still wants its rounds on hand: the fix that lets a gun read as an upgrade in
   the stash without its rounds in the rig (the try-on feeding from the stash's grades, 20 Oct) didn't reach the
   fight's pick, so a find there only shows as an upgrade if its rounds are already held. Matt: "that change didnt
   make its way through to the fight".
   - Done: the gap was the pack - a box found in the same run sat in mission["found"], and the try-on read the
     stash's rounds only (his save, Fence shut: an SMG with its rounds in the pack read 56 against 170 worn; in the
     stash at camp, 213). Sim._rounds_held: the stash's rounds, and the pack's on a run - has_rounds, feed_stack's
     try-on read and the kit key read it; the firing itself stays the rig's. Smoke checks the fight's try-on.
8. Weapon sounds still aren't sorted: with a Pattern AR worn, Matt says "it feels like none of the muzzle flashes are
   getting a sound effect attached" - the fight's flashes and the shot sounds out of step, or the rifle's shots
   unvoiced.
   - Done: the files were the cause - the three rifle takes peaked at -29 to -33 dB and the pistol's at -23 to -27
     (the shotgun's and SMG's at 0), so a rifle's shots played and couldn't be heard. tools/sound_levels.py lists
     every take's peak (ffmpeg) and --fix lifts a fight one-shot under -6 dB to -1: the six shot takes and
     swing_melee_2 lifted, in place. Run it after any sound batch; the smoke can't decode audio.

9. The Radio's pile has no cap and no way to bin or sell from it (22 Oct, found profiling the pass: the bot's runaway
   reads piled 9,000-28,000 papers; a long player session will show "THE PAPERS · 400" too). A cull, or a sell from
   the pile, once the balance is in.

10. The broken builds (docs/design/broken_builds.md: one a class - Embers, Clean kills, Overdose, Opened for good, Live
    load) want tuning again for the web (22 Oct, Matt): their paths name nodes by the old lanes (the joint half, the
    element's keystone and capstone - about 45 points), and the fillers and the keystone choice change what a path
    costs and what else is on it. Outside the balance read as before (Sim.combos_off); a pass of their own after the
    playtest, with their node paths rewritten on the web.


## 0.7.2: the 0.7.1 playtest's first five (23 Oct; Matt: "do those 5 - the playtest after as they are going to
## impact my playtest")

- The five below, built. 1: inside the class's lit wheel the disc is darker than the links (Pal.BG at 0.55, a faint
  accent and a 1.5 px rim) and the links read LINK_LIT_DIM at 1.4x the width; outside it LINK_DIM, a step above the
  old CARD_LINE so they hold against the backdrop. 2: tools/make_web_small_manifest.py - 104 small nodes and the 8
  fillers, still-lifes to art/nodes/ by slug, no wiring needed (Matt: "art batch for item 2"); about 70 small nodes
  (the Map's crews and codes, the Workshop's crafts, the papers' words) stay dots. 3: one starter a region for the
  elements and the Pitch (data.gd _web_build: the first column's row-1 node isn't an entry; the rung reaches it);
  every node carries "region". 4: PIC_ZOOM 0.8 → 0.5. 5: a class's starter draws its first lane's emblem at R_ENTRY
  20; the class's rim label drops the emblem. Smoke asserts each; run 209 green. Reviewer: a 0.7.1 save that opened a
  region from the old second starter strands it, and every keystone swap would refuse - SAVE_VERSION 6 (Matt: "I
  don't care about saves, we never care if one gets broken"; CLAUDE.md's save rule says so now). VERSION 0.7.2.
- And the small nodes' art, wired (Matt: "why aren't the other nodes in this batch? send the manifest", then "ok go
  ahead"). The first list was read off data.gd's sources and missed the lanes' extras and the elements' resist
  fillers; the second wave (tools/pixellab_web_small2_manifest.json, 32 jobs) was read off what the three canvases
  draw: Training's 22 more and the Dial's 10 fillers (map_f_<slug>, so its "Light fingers" never takes the Training
  notable's). The "about 70 left as dots" was wrong - those were crafts, signal words and classes, not nodes. The
  canvas drew pictures only on notables and diamonds: now every node with one draws it, a small node 9 → 13 px from
  zoom 0.5, a filler 6 → 10 px from 0.9 (a dot below that keeps a dot's size). No overlaps at the pictured sizes on
  any canvas (web_view.assume_pics, the smoke). Reviewer: slugs built once a name; the filler's size by zoom. Run 211.
- And three more of Matt's, "do these now": (1) the launch error "Can't add child" from missions.gd's death-pick
  divider (UI.panel parents it; the second add_child went) - in the game since 21 Oct and written off here on 22 Oct
  as the shot script's, wrongly; tools/smoke.bat now fails a run whose log has "Can't add child". (2) The node
  pictures brighter (Matt: "way too dark"): taken ×1.25, reachable ×1.1, untaken 0.85 (was 0.5). (3) Every Training
  region's name by its first node (_labels_by_entry: beside the one starter, the first spot clear of every node and
  name, measured at the closest zoom it shows at) from zoom 0.8; on the rim below that, where twelve starters round
  the centre would stack twelve names. Reviewer: the boxes first measured at zoom 1 (fixed); the cold's name fell
  150 px off at 0.6, so 0.8. The smoke checks the names on screen at 0.8 and 1. Also the "harder gang down" check
  compared with the site read again after the clock moved; it compares with the held gang now. Run 214.

## 0.7.3: the skill tree's draw calls (23 Oct; Matt: the fans spin on Training and stop when the game closes)

- The cause, measured: Training's whole web drew ~2,500 GL draw calls a frame (the other rooms ~230). Every
  draw_circle, AA draw_arc and polygon is a call of its own (an AA arc three), and a picture drawn between them broke
  the batch again; Godot re-submits the canvas every frame though it doesn't redraw. Not an off-screen image (Matt:
  "every time i look around the tree my CPU is taking a hit"): each frame made cheap instead. web_view.gd now packs
  every node picture, glyph and region emblem into one 2048 atlas (static, shared by the three canvases; packed on a
  canvas's first show, lazily after; edges extruded, linear as before), and draws a node's disc and ring as atlas
  sprites in four sizes (the ring a disc of the line's colour under the fill's, the arc's width either side of r), so
  every node batches into one call. The links go one draw_multiline a colour and width; the words last, a font and
  size at a time (so names now sit over the nodes, not under later ones). Measured in the cloud: the whole screen
  ~223 calls at the whole web, the canvas itself ~20; the Map's and the Pitch's 5-7. Renders diffed against the old:
  ring edges only (anti-aliased now). The smoke runs the passes dry (web_view.count_batches; the smoke never draws)
  and holds each canvas under BATCH_MAX 60 at its whole view and close in, and every picture packed.
- And an old intermittent red found: "a level-90 runner on the first site did not read as settled 100%: 0.00" (runs
  243 and 215). The bot's run can leave the gun dry; the settle loop fed a box of rounds and took it out again before
  the level-90 read, and a dry gun loses all eight there. The box now comes out after it. Reviewer: pack once, not a
  frame at a time while panning (done); the Map's and Pitch's counts were trivial without a sim (lent one). Run 216.
- Parked (Matt, after 0.7.3: "park this until the art gen has done"): the fans still spin up from game start. The
  art batch's headless Godot is running and uncapped; Matt restarts the laptop after it to rule that out, then we
  look again (next suspects: the sky's _process on when it isn't raining, the title screen).
- Parked, not a playtest item: a runner with an empty gun reads 0% and the odds chips don't say why; a "No rounds"
  chip beside "No meds" would. For after Matt's playtest.

## 0.7.4: the fog, the clouds, the sky's idle tick (23 Oct)

- The fog (Matt: "the fog needs some work on the map, it's drawing weirdly"; mockup approved, "looks awesome"): the
  flat sheet and the two hard bands gone; one layer, a shader drifting two scales of a seamless noise (sky.gd
  noise(), shared) into banks over a faint tint, thinner and quicker on the fight (SkyLayer.new(size, true)). Nothing
  on the CPU. Commit dbdad0a, with the sky's fix: Godot turned the layer's _process on at ready, so the Map's and the
  fight's ticked every frame dry; _ready turns it off unless it rains (Matt: "fix it in this round too").
- The Map's clouds (mockup of a soft moving edge and a visible drift approved; Matt: "make the cloud change"): the
  cloud shader's drifts four times as fast (~5 px a second), the edge wandering on the same noise and thinning into
  wisps. Reviewer: the soft band reached pins 31-47 px inside their zones (the Parade, the Services, Ransacked
  Streets), so the open land is grown SOFT_GROW cells into the shut before the mask is softened (halved twice,
  averaging, a straight shrink lost thin strips), and the wander is ±20 px; the smoke bounds the cloud over every
  open site's pin with one, two and three zones open (cloud_cover_bound, all 0). The wisps reach a little less far
  over the open land than the mockup's. And the picked zone's yellow outline gone, its warm wash kept (Matt: "the
  yellow boundaries just read wrong"); the wash alone is faint (LIT 8%), 15% offered if it doesn't read.
  Smoke green on run 219. VERSION 0.7.4.

## 0.7.5: the elements in their colour (23 Oct; Matt: "the coloured boxes for the elements just look cheap")

- Mockup approved ("All approved"). web_view: ELEMENT_HULLS off; link_colour() - inside an element's region an
  untaken link its tone at ELEMENT_LINK_DIM, a reach link reach_tone() (lighter, or darker where the tone is near
  white: Knuckles), two taken the tone; rings the tone mixed in at ELEMENT_RING_DIM, reach_tone once reachable, the
  tone once taken and active, the dim ring for trained-but-idle (the review: another class's half, a gun not in
  hand). The classes and the Pitch unchanged. Smoke: hulls off, element links in colour, class links grey. Run 220.
- And 0.7.6, from the mockups (Matt: "square sand + portraits"): the Pitch its own - square nodes (an atlas "square"
  shape), its links and rings in PITCH_TONE sand under the element scheme (tinted()), its emblem the hub on its
  starting node and off its label, its hit area widened for the corners (the review); and the class's portrait
  (art/people/<class>.png, faded out over its outer third) at 16% under its lit wheel. Smoke: the Pitch's tone, hub
  and squares; every class's portrait faded at the rim. Run 221.
- The art, counted (Matt: "every single node on every single tree will have art?"): the three canvases draw 420
  pictures; 369 landed, the other 51 in the two running manifests (25 small, 26 small2), none unplanned. The
  starters draw their emblems.

## The fight's walls, tall (23 Oct; Matt: ducking "you can see the same tiled wall 3 times")

- Parked item 6 (21 Oct) asked for the cover walls much bigger, one piece, nothing in code to fix. They went into the
  web art manifest on 22 Oct and I dropped them the same day as "ran with the fight kit on 17 Oct" - wrong: those are
  the same 744x173 strips, and ducked (the wall up DUCK_COVER 80 px) their picture stops short of the frame's foot,
  so run_view's _cover_fill tiles the bottom 28% of the bricks down under it: the repeat Matt sees.
- tools/make_fight_walls_manifest.py writes a walls-only manifest (Matt: "a new manifest with only these walls"):
  the test (the Parade) and the set (12), 744x256, the body the lower 85% down to the bottom edge, ~200 px drawn
  against the ~130 the full duck needs; to art/fight_walls/ (nothing overwritten), styled on the 17 Oct walls, new
  seeds. Once judged: the fight view loads art/fight_walls/ first, _cover_fill goes, and the smoke checks the wall
  reaches the frame's foot at the full duck.
- Done (0.7.8): the twelve ran on 23 Oct (21:01-21:16, from the first version of the manifest); the generator then
  checked against docs/art/pixellab_lessons.md - seeds moved to 101000+ (98500+ were the web art's), "signs" out of
  the wording, "a low" dropped against "tall" - for any reroll. run_view reads art/fight_walls/ first; the tiled fill
  is gone, the fallback with it (the review: nothing untested left); cover_reaches() and the smoke hold every site's
  wall to the frame's foot at the full duck. Run 222. Three walls (barracks, hospital, services) have no .import yet:
  the editor makes them on its next open, and they want committing then.

## Milestone 8 opened (24 Oct): skills, energy, the Recruit, the unlock order, the Pitch

- Matt: "Our skill tree has no skills and fights devolve into watching bats and clicking meds. We need active skills
  ... 8 per character with 3 available for a fight ... an energy system plus a cooldown reduction affix." Designed
  together and written up in docs/design/skills.md: auto-cast with a manual override; energy (100, 4 a second, a
  quarter of pace's bonus); three new affixes; 48 skills, 8 a class taught by the tree; defensive skills clear
  ailments, meds stay the heal; the sixth class the Recruit on the wheel's free spoke; the unlock order by heads
  (start the Poacher; the Gamekeeper the Clinic and the Paramedic; the Carpet Man the Doorman; the Manager the Fence
  and the Scrapper; the Quartermaster the Recruit; Kev's first story the Drifter); the Pitch's tree reworked.
- Matt's answers: the Recruit (not the Deserter); Bung keeps its tin cost; Leg it changed (surviving death is Code
  blue's alone); the removal skills never work on heads.
- The language pass (house rule): two reviewers (docs/language/review_m8_a.md, review_m8_b.md), my calls folded into
  the design's section 11: 17 renames for clashes, no crits or reloads (the game has neither), the rule labels
  replaced, figures not words. Six calls left for Matt (section 11): unbanning "skill", Code blue against Not today,
  3+ on you under Chokepoints, the Paramedic's and the Scrapper's stories, the style guide v3.
- CLAUDE.md's plan updated: balance is milestone 9. Next: the Pitch's quick fixes, then the mockups.

## Parked from the playtest (23 Oct, 0.7.6; Matt: "park the fact we need to revisit this")

1. The wheels' links through their middle track. A class half's row -1 node links its row -2.3 one; on the wheel
   rows -1, +1 and +/-2.3 sit on tracks 8.7, 10.3 and 12.1 at the same angle, so the link runs straight through the
   row +1 node between them (Matt: Tough's line to Lucky read as Tough to Keen; "the skill tree is why I stopped
   playing the last playtest"). 33 on Training (six spots on each of the ten halves), 1 on the Dial. Fixed for the
   playtest in the drawing (0.7.7): a link that would pass a node not its own bends round it (web_view.link_path,
   _find_bends), the smoke holding every link clear. To revisit: the layout itself - the rows' order on the tracks,
   or the links - so nothing needs bending; with the balance phase, as a link change moves paths and costs. Also
   then (the review): the dashed joins and bridges are still straight and unchecked, and a bend takes the side that
   clears first, not the one away from the hub.

## Parked from the playtest (23 Oct, 0.7.1; taken up after it)

1. The class's wheel, highlighted: the lines between its nodes are far too faint to read (Matt: "selected class
   highlighted means the lines connecting nodes is far too faint and really hard to read"). The warm disc under the
   wheel and the backdrop behind it both sit under the links, which draw dim where a node isn't reachable yet; the
   three together lose the lines. A drawing fix: the links over the lit wheel want a brighter, thicker stroke (or
   the disc wants to be darker than the links, not warmer), checked against the backdrop.

2. Most nodes have no art (Matt: "why are there no art in most of the nodes?", screenshot: the plain discs beside
   Magpie and Haggler). The manifest's rule (22 Oct, agreed with the list): pictures for the notables, keystones and
   capstones; small nodes and fillers stay dots. Counted 23 Oct: 366 named nodes, 176 with a picture, 190 without -
   the small tier; Still air and Arc owed a re-roll; 22 of the 343 jobs didn't land. The choice after the playtest:
   a second manifest for the 190 (a day of the batch), or dots with a glyph or a stat tint so they aren't blank.

3. The elements' regions and the Pitch's need a single starting node each, as the classes have now (Matt: "elemental
   trees and the pitches tree need a single starting node same as the classes"). Batch A gave each class one entry
   (the first lane's first node, the second lane's first column linked to it); the elements and the Pitch kept their
   two. The same builder change (data.gd _web_build / _web_wheel) for those regions; their nodes and costs stay.
   Changes a path's cost by a point or two at the join, so it goes in before the balance phase.

4. Zoomed out, the nodes' pictures give way to glyphs (Matt, screenshot of the whole web: "at a certain view distance
   the icons revert to glyphs instead of art"). By design in batch A: PIC_ZOOM 0.8 draws the picture from that zoom
   and the glyph under it. The pictures are 64 px pixel art, so under 0.8 they'd be drawn smaller than painted; the
   call is whether a small picture still beats a glyph (likely yes down to about 0.5, with the filter nearest) - a
   threshold change and a look, not a system.

5. Each class's picture (the emblem beside its label on the outer rim) should sit on the class's first node instead,
   so it's plain where that class's journey starts (Matt: "the art for each class needs to move from its outer rim to
   be the first node of the tree so its clear where each classes node journey starts"). With item 3 every region has
   one entry; the entry node draws the class's face or emblem as its picture, bigger than a notable, and the rim
   label loses the emblem (keeps the words). A drawing change in web_view.

## Parked from the playtest (22 Oct, the web's settings; taken up after it)

1. Training's canvas: the class you're on should have its region highlighted, subtly, so you know where you're
   starting from (Matt: "when you have a class selected its tree should be highlighted subtly so you know where
   you're starting").
2. One starter node a class, not two: today each of a class's two lanes has its own entry at the join. Matt: "each
   class should have one starter node". The entry becomes the class's single join node, both lanes off it.
3. A sixth class: there's room on the star (five classes at 72° leave the sixth angle open) and on the panel's class
   pills. Matt: "worth doing now while we're in balance mode" - a class, its two lanes, its element pair, its joint
   halves, its broken build, its figure and face, its ring entry. The concept wants agreeing first.
   - And (Matt, later the same playtest): stagger the classes' unlocks through the campaign, so each is new when it
     comes ("players have a reason to play each of them because it's new and exciting"). A design item with the
     sixth class: which site or head opens which class, and what the crew does before then. It changes numbers (the
     crew's reads, the campaign's pace), so it goes in with the parked list, before the balance phase, or not at all
     until after it (the PM's call, CLAUDE.md).
4. The run's pack card, empty: "A long gun takes 4 or 5 cells by 1, armour 3 by 3, a bandage 1 / 12 cells free /
   Nothing found yet" (screenshot). Matt: unchanged since the first version, "it needs to go" - cut the sizes line,
   or replace the empty state with something better. New words get the language pass.
5. Points free, all of them, in one place: a level-1 Drifter with a free Knuckles point (the physical meter) saw it
   only as "1 free" in that region's label on the canvas; the band said "0 of 0 points free" (the class's pool) and
   the rail's badge "1 free" (screenshot). Matt: "something somewhere needs to tell you all points that are
   available - a key on the map tree itself would be easiest". A key on the canvas (a corner panel): every pool with
   points free - the class's, the Pitch's, each element's, the ring's - and the band to match. Takes in the 21 Oct
   parked item 3 (the two pools' band).
   - And (Matt, later): the key carries each element's use meter as a drawn meter (a bar), not a figure, and the
     "meter 15%" / "1 free" words come off the region labels on the canvas - the label is the region's name alone;
     the key is where the pools and the meters live.
6. The elements on the canvas: each element's region gets a coloured outline in its element's colour, so it reads at a
   glance; and the joint lines between an element's region and a class's lane are coloured the same (today they're
   dashed in the plain tone). Matt, with the art running: "each element needs a coloured outline so it's easy to
   identify and ... the join lines between element and class tree need to be coloured too". With the art manifest's
   wiring (item 1's highlight is the same drawing pass).
7. The odds at 0% on a site's card say nothing of why or what to do. Matt: "we need to do a better job of telling
   players why the odds are 0% and what they can do to bump things up - recommended DPS, armour, HP etc." The site
   guide has the fight's figures; the card wants the gap in the player's own terms: which of damage, HP, armour or a
   resist is the short one, and by how much, read off the dry runs (what killed the runner, how far the pool got).
8. Day, night and the weather are words only: the Map's card says "09:12, day" and "Rain · searches 30% slower, gangs
   25% later", and nothing in the game shows it - not the map, not the fight's plate, not the run. Matt: "we
   advertise night/day on the map and then rain but nothing in game signifies those states." A tint and a layer on
   the map (the clouds are there already) and on the fight's plate (night's dark, rain's streaks), the run's card
   naming it. A drawing pass, not a system; no new numbers.
9. A class region's shape: the two lanes run out as parallel rails with the notables hung off one side, so a player
   who paths up one lane sees "all the good stuff" (the keystones, the hung notables, the halves) off to the other
   side with no way across but back (screenshot: the Drifter's Moving on and Luck). Matt: "I love this design but as
   with PoE I think those nodes ... should be in a spiral/circle with the nodes around and then you reach the middle
   on your way or through somewhere else - mock up first once we get there." A layout change to the web builder (the
   lanes' geometry: a loop or wheel per region with the keystones in the middle, reachable from either rail), on the
   canvas first; the nodes and their costs stay as they are. With the single starter node (item 2) and the outlines
   (item 6): one canvas pass.
10. The Clinic's shelf sells one med a click. Matt: "select multiple meds in the clinic to buy - single buying at a
    time is a chore." A count on the buy (×1 / ×5 / fill the rig, or a stepper), the price shown for the lot; the
    Fence's shelf the same if it has the same chore.
11. The armour compare's verdict (two screenshots): the Doorman's Jacket (Unique, 152 armour, +12 arm, +20 HP, −25%
    damage taken with 3+ on you) over Light plates (Rare, 110 armour, +6% pace, +0.4 HP/s, +8 fire res & dmg) reads
    "Downgrade · −2% odds · +42 arm · −0.4 HP/s"; the plates over the Jacket read "Upgrade · +5% odds · −42 arm".
    Matt: "discrepancy here". Two things to check: the unique's rule (−25% taken with three on you) isn't in the
    try-on's survival figure, or the front fight it reads has under three on you, so 42 armour and 20 HP lose to
    0.4 HP/s; and the odds delta isn't symmetric (−2 one way, +5 the other), so one side of the compare reads a
    stale or differently-keyed odds. The verdict should be the same figure either way round, and a unique's rule
    should count in it (the design: the body's figure is the fight being pushed, 12 Oct).

- The project manager (22 Oct, Matt, mid-playtest): Claude carries the plan, the version and the scope from here
  (CLAUDE.md, "The project manager"). The plan: his playtest, then every parked item, then balance and nothing else.
  The version on the title had sat at 0.1 since the first slice: the scheme is 0.<milestone>.<build>, the web build
  he's playing 0.7.0 (bumped in the parked-list commit, not mid-playtest), the parked-list build 0.7.1.

## The tuning batch (21 Oct, after Matt's first playtest of the Scrapper)

Matt's save at 40 min: level 9, 13 runs, 100% at every site to the Pleasure Park (75% there, 0% at the Shopping
Centre - the frontier), 2-3 min a run, every run ending at the first gang ("Back, chased", two searches in), no
deaths, no wounds. Matt: "I'm concerned we aren't looking at all the variables and levers" - the mission timers for
one; "Yes to campaign getting harder. Split the difference and aim for 4/5 mins." The levers pulled (numbers for the
pass; the reviewer on the code):
- The campaign gets harder with the runner's level (Sim.campaign_level_mult): a site CAMPAIGN_LEVEL_FREE 8 levels
  under the runner fights as it is (the pass: a first clear comes 5-10 levels over a site's own level), past that
  its heads' HP and fire compound CAMPAIGN_LEVEL_GROW 0.08 a level, CAMPAIGN_LEVEL_MAX 2.0 at most (9 past). The
  clock keeps pace (clock_mult: the tax is on the fight, not the time). The odds' key carries the level (the
  review: the Map's reading went stale on a level-up). Matt's frontier reads as before; the Outskirts harden from
  level 12.
- The run's length: PATROL_FIRST 2.0 - the first gang after the clear waits twice the gap (38-48 s at depth 1), the
  gangs after at the zone's gap, PATROL_ZONE [1.0, 0.9, 0.8, 0.7]; SEARCH_S 15 → 20; GANG_NEXT_STEP 0.2 → 0.3 (the
  next zone's crew from the second gang more often). A first cut of CAMPAIGN_POOL 1.5 read his Pleasure Park 75% →
  0%: dropped (1.0); the length comes from the gangs, not a longer fight.
- The clock runs through the searches at CLOCK_SEARCH_RATE 0.5 (it stood while the site was clear: a strong build
  never saw it), CLOCK_BASE 60 → 90; out of time in a search ends the run as in a fight.
- Notes for the pass (the review): KEV_RUNS reads the raw pool (unchanged); the tier guide's rows past the campaign
  read against a taxed base (presentation only).
- The pass's gates to read against: P1 deaths, P2 wounds, P3 odds at the gate, 10 the gang clock (the first gang's
  wait is 2x now: the gate reads searches a gap), 11 staying costs, 14 cash, 15 scrap, and the run's length
  (new: minutes a run, Matt's 4-5).
- The pass on the batch (21 Oct, 23:33; kept as docs/balance/summary_tuning1.md): drastic - four builds never
  reached the Bank (the Scrapper as shock sat at the Pleasure Park and the Shopping Centre for 24 h, 0% ↔ 100%).
  The tax was keyed to the site's own level (the Bank's 6), and a first clear comes 10-22 levels over that, so the
  frontier itself hardened to x2 as the runner levelled under it. Fixed: the tax is keyed to the runner's own first
  clear of the site (Sim.clear_level, saved): a site never cleared is as it is at any level, a cleared one x1 for
  CAMPAIGN_LEVEL_FREE 3 levels after, then 1.08 a level to x2. The odds' key carries it. One pass again.
  - For Matt (the review): the clear level is the camp's, not the class's - a second class reaching a site a
    first one cleared pays the tax from the first's clear. Simpler; bounded at x2. Per-class if it bites.
- The second pass (22 Oct, 08:50; docs/balance/summary_tuning2.md): the frontier wall gone but one - the Scrapper
  as shock cleared the Shopping Centre at level 14 on lucky kit, its kit then stalled at ~280 dmg/s while its level
  ran to 28, both its sites hardened to the x2 cap and the Bank stayed out of reach, 20 h. Levels come steadily, kit
  is luck: a tax keyed to levels punishes a lagging kit. Matt: soften it - CAMPAIGN_LEVEL_GROW 0.08 → 0.04,
  CAMPAIGN_LEVEL_MAX 2.0 → 1.3. The rest held: the Bank at a median 1.0 h, the Quartermaster 2.0 h, the lorry 3.9 h;
  deaths one in 445-2842 runs, wounds 0-5%, every run in at 100%, no build into a third gang (the bot leaves at the
  first gang: the gangs and the clock never bit it). Gang clock and no-reds green. A third pass.
- The third pass (22 Oct, 09:28; docs/balance/summary_tuning3.md, 20 RED): no wall - every element build
  through the campaign, the Bank at a median 0.9 h (0.6-1.7), the Quartermaster 2.4 h (1.1-3.6), the lorry 4.2 h,
  the plain Poacher the one read short of him. Deaths one in 480-2306 and none on four builds, wounds 0-4%, every
  run in at 100%, no build into a third gang. Not drastic; no tuning off it (the web, below, moves every number).
- Matt (22 Oct): the trees become one web (docs/design/web.md). Slices built end to end, no playtest between
  them, one balance pass at the end. The Training band's class cards stay where they are: the web's figures and
  buttons fold into the band as it is.

## The web (22 Oct, docs/design/web.md): the build

- Slice 1a, the sim: a node is reached by pathing (Data.web_links off the lane's shape, Sim.touches_trained,
  path_next for the screen's hint and "wants a path to it: X first"), not a column's gate; the column gates, the
  core gates, the element-top joint gate and the capstone's "every notable first" are gone - full access, every
  element's region to any class, a column of class halves bypassed (the review: the hint never names another
  class's half). The keystone and capstone level gates stay. The bot's walk is as it was (column by column).
  Smoke's gate checks rewritten as pathing checks. Dead in the sim now, out in 1b: core_need, core_tree,
  _tops_open, Data.gate, CORE_GATES, ELEMENT_GATED_COL.
- Slice 1b, the canvas: scripts/ui/web_view.gd in the lanes' place in Training - every tree a region of one web
  (slice 1's layout: the Pitch across the centre, three elements' lanes left and three right, the classes beyond;
  the drawn layout and the fillers are slice 2), links lit between taken nodes, the joints dashed, glyphs and names
  from a zoom, Lv 20/30 tags; right-drag pans, the wheel zooms about the pointer, a click picks into the panel;
  Whole web / The class's / The Pitch over its corner. The lanes, their gates, rails and the core pills are gone
  from barracks.gd; the Also row is the pages alone. Smoke: _web_checks (placed, no overlaps, fits, the camera,
  a pick, a drag released off the canvas). Not yet: "find a node" (slice 2, with the fillers).
- Slice 2, the nodes (22 Oct; web.md §2a, Matt: "all looks good"; the two language reviewers' pass on every new word -
  now a standing rule in CLAUDE.md - and the editor's calls: no "head" for a man of a gang, figures not words, the
  clashes and the American names renamed). Data.TREES and ELEMENT_TREES are built from TREES_SRC/ELEMENT_TREES_SRC by
  _web_build: a lane is two rails with a filler between each pair of columns (the ladder; a lone node on the axis, both
  rails into it), a class's halves hang off their rail, four notables a lane (six the Pitch) hang past a branch filler,
  and a new keystone a class sits between its two lanes, linked to both (xlinks). Every node carries "at" and "links";
  web_links reads them, web_links_all merges the trees for the pathing. 525 nodes (250 fillers; the paragon ring is slice 4). Fillers: one stat each, eight
  cycled a lane (Hardy +4 HP, Keen, Brisk, Mending +0.2 HP/s - regen_rate -, Tough, Lucky, Nimble, the region's
  resist). The keystone choice: a class's three, one held - taking another lets the held one go for its points, free
  (the review: the held one's points pay for it), unless a trained node hangs off it ("X hangs off Y: let that go
  first"; strands_without). The new rules in the sim: Snare and wait, Twine, B-roads, Bin lid, Clocked, Last orders,
  Jab (+20% damage and pace, the rounds with it), Capacitor, Overload, Brittle, Arterial, Floored, Backdraught,
  Catching, Worst first, Clocking off, Spare change, Word of mouth, On a roll, Breaker's yard, Back pocket, Workbench
  (workbench_day, saved), Salvage, Shop local, Light pack, the dots' lengths. The kettle became a rest chip (a wound is
  the Clinic's alone). The canvas: the drawn layout from the canvas mockup - the Pitch across the centre, the elements
  out from R_ELEMENT at 60° each (a class's pair side by side), the classes out from R_CLASS between their elements
  with their notables hung outward; names only at the cluster zoom (1.3) or on the hovered and picked node (every
  name at once overlapped on a diagonal lane); "Find a perk" over the canvas centres the first name that fits. The
  bot walks by place (the rails before what hangs off them), keeps its first keystone, skips a notable typed for a
  gun it doesn't hold. The sum strip drops Lasting last (the web's figures run to three digits). Smoke: the ladder's
  links, the swap and its block, the counts, a resist filler, and a check a rule (_web_rule_checks). Reviewer's
  finds fixed. Not yet: slice 3 (use meters, camp-wide allocation, the bridge), slice 4 (paragon ring, Map/Pitch).
  - For Matt: the long dashed joint lines cross the web at the whole-web zoom (a class's region isn't beside both its
    elements); the whole-web zoom is an overview, the work is at a region's.
- Slice 3, the pools and the bridge (22 Oct; web.md §1, §3, §4). The Pitch's and the elements' nodes are the camp's
  (Sim.is_camp): kept through a swap, a death and a reset; a runner's record holds its class region alone. Element
  points are earned, not bought: at a run's end (a death's too) _fill_meters turns the damage dealt by type over the
  site's pool of HP into element_xp, ELEMENT_METER 1.5 of it a point (two a run at most: a broken build's 1e30 was
  a region); element_points spend in the element's region alone (free_for; no off-pair doubling - the element's own
  currency), saved. Another class's half on the camp's tree does nothing for the runner out. The bridge: "The second
  past", a node a side of each class past its lane's last filler, 3 points at level 30, one a class, from your own
  region; it puts the neighbour's whole region (Data.BRIDGES, both lanes) on show for the class's points; a reset or
  a death takes it and what's past it. The halves and the joints stay the class's own (the review: a bridge opens a
  region, not its halves). The canvas: an element's label carries its free points and meter; a dashed line from a
  bridge to the region it opens; the rail's badge counts every pool. SAVE_VERSION 5. The bot trains each element's
  region from its own pool, skips the bridges, takes a joint's half whatever gun's in hand. Smoke: _web_pool_checks.
  The first cut's meter loop hung the smoke on the broken builds' 1e30 (Matt killed it; division now).
  - For the balance pass: points_spent is class-only now (not like for like with the last pass); an element build
    earns its first element point off kit and its class's joint conversion alone, so keystone_at for the element
    builds will read later - §8's Quartermaster gate on the meters is for the pass to set.
  - For Matt: element nodes have no reset of their own (a reset is the class's region); say if the elements want one.
- Slice 4a, the paragon ring (22 Oct; web.md §6). The board is gone: Data.RING, 30 nodes 12° apart round the outside
  of the web (R_RING), the board's five rows cycled (the cycle slips a row every five so the five entries at the
  classes' angles aren't one row); a node holds up to RING_STACK 10 paragon points (no top, as the board had none);
  a point costs one, pathed round from an entry. Sim.ring {id: points}, saved; paragon_pts/paragon_spent read it;
  paragon_add(key) (the bot's and the tests' way) stacks the fullest reached node of the row or steps round toward
  the nearest; the ring is the camp's (is_camp). The panel: a ring node picked reads "Damage · the ring · 3 of 10",
  Train puts a paragon point on, the reset button is the ring's. The bot's class loop leaves the ring alone (the
  review). Two stray copies my file delivery left (barracks-1.gd, smoke-1.gd, 11:14) are moved to _to_delete/ as
  .txt (no delete permission; Godot would have parsed them): Matt to bin the folder.
- Matt (22 Oct): the Map's atlas, the Pitch's buildings and the Radio's codes as pathed webs with real choices
  ("do you path into loot quality or signal strength; the stash bigger or more useful"): the design next.
- Slices 4b and 4c, the Map's web and the Pitch's web (22 Oct; docs/design/web_map_pitch.md, Matt: "build it all").
  web_view.gd is a base - the camera, the drawing, the input - with the web behind hooks (node_of, links_all,
  lay_out, state_for, state_sig, stack_of, region_words, level_tag, glyph_of, draw_between, focus_named); Training's
  is the default, map_web.gd and yard_web.gd override them. The Map (the Radio's Dial view): Data.MAP_WEB from
  MAP_REGIONS - the sites, the crews, the codes, each a spine to its keystone with two branches (the quiet way or
  the rich way; the heads or the pay; the quality or the reach), a filler between a branch's nodes (29, atlas
  nodes of one rank in ATLAS_ALL, each a share of a ranked node's figure: Sim.atlas_level, read where atlas_rank
  was); pathing in place of the column gates (atlas_block, atlas_open, atlas_path_next; ATLAS_GATES gone); a
  keystone wants MAP_KEYSTONE_POINTS 10 in its region (the review); a ranked node a stack. The Pitch: Data.YARD_WEB,
  a building a region, a column's two picks each linked to both of the column before (one or the other, as now),
  the ranks a chain past them; the sim's Yard rules as they were (the column gates, the prices), the names
  scrambled until the room opens. atlas.gd and yard_tree.gd host the canvases in the lanes' place with their bands,
  strips and panels (the Dial's sentence moved under its chips: beside them a long one went blank). The bot ranks
  the Map in web order. Rendered and checked before the smoke. Matt: "the star like map on the class tree is
  what's needed for both - same layout so it's consistent for a player": both redrawn as stars out from a centre
  (the Dial's three regions at 180°, −60°, 60°; the Pitch's eight lanes at 45° each), the names past the lanes'
  ends running away from them (web_view's label align). Smoke: the Dial's pathing and canvas, the Pitch's canvas, the fixtures by pathing (_rank_to).
  - For Matt: the two new scripts have no .uid files yet (the headless smoke makes none): the editor will write
    them on its next open - commit those with the next change. The Radio's "Juice" is the Dial's "The codes"
    button (no separate chip). The web is all in: the balance pass next.
- The pass's wall halved (22 Oct, 23b427d; Matt: "we're losing too much time on balance passes"). A 24-hour read
  had gone from 30 to 60 minutes after the web. Profiled on two end-of-pass saves (20 simulated minutes each): the
  time was has_rule walking the stash fifty times a tick; the bot's sell culling "plain papers" that live on the
  Radio's pile since 18 Oct, where the Fence can't reach them - a pile of 9,000-28,000 papers sorted and
  failed-to-sell every tidy; best_in_stash asked once an item with the kit's key hashed per ask; a find into a full
  pack trying on every pack item; the compare's baseline tried on per piece; the signal-making filtering the pile
  four times a step; attachment sorting scoring per comparison. The sim caches each (has_rule's shape, a try-on's
  own memo and feed, the worn affixes by stat, the pack's keep verdicts, the pile's ids, the parts' scores); the
  bot's kit tidy runs once a camp minute (the Yard, the meds and the endgame's business every run), reads the pile
  once a shape and the sell's keepers once; a plain build's read ends at the Quartermaster; the summary's wall table
  splits tidy into its parts. The Doorman's 20 minutes 30 s -> 11 s, the Scrapper as fire's 17.6 s -> 7.6 s.
  Reviewer two rounds (the has_rule key's swap of equals, the keeps' key, the tidy's split, the pile's key); smoke
  run 51.
- The web's balance pass (22 Oct, 15:32-17:34, summary.md: 19 RED, as the morning's 20): the campaign too quick
  (the Bank 1.0 h, the Quartermaster 1.7 h), odds 100% everywhere, one death in a thousand runs, the lorry at
  3.5 h, level 50 at 4.9 h, then the runaway: 2-3 second runs, hundreds of millions of tins, 270k HP off the
  lorries compounding. The reds and the settings next, against Matt's save.
- The web's art manifest (22 Oct, Matt: "proceed with the art manifest ... all the tree nodes and whatever else we
  had parked", then the regions' and the Map's labels and the Dial's and Pitch's canvases too): tools/
  make_web_art_manifest.py -> tools/pixellab_web_art_manifest.json (343) and _test_ (16). The nodes (304: every
  notable, keystone, capstone and bridge of Training's regions, the Map's 35 ranked, the Pitch's 80 picks and 8
  ranks, the ring's 5 kinds; 64 px to art/nodes/, the UI icons' style; small nodes and fillers stay dots), the
  regions' emblems (21: the six elements, the Map's three, the ring, the Pitch, and the ten class lanes; 96 px to
  art/web/), the three canvases' backdrops (744 wide, the API's most, drawn x2), the Scrapper's and Poacher's new
  face and figure (parked item 6), the eleven cover walls not yet run from the fight kit (one piece at the frame's
  width; the duplication was the live tiles). Wiring once judged: web_view draws a node's picture in place of its
  glyph when the file exists, an emblem beside a label, a backdrop under the links. The test first (no credits
  before it reads).
- The final pass on the web's settings (22 Oct, 18:21-19:11, 364b2ee; summary.md, kept as summary_web1.md; the
  read before it as the figures in brackets): the Bank 1.3 h (1.0; the gate 1.3-2.1), the Quartermaster 2.4 h (1.7;
  2.5-3.4), level 23-35 at him (22-34; 20-24), level 50 on the median read 15.1 h (4.9; 12-24, four never, one at
  7.9), the lorry 4.4 h (3.5; 8.5-11), the reach at 24 h 38-54 (63-149), full signals at the reach won 87% (96%;
  35-65), odds 100% everywhere still, deaths one in 500-9,000, cash in hand 20-400M. 20 red to 19: the campaign is
  at or near its gates now and the Outskirts as Matt played them; the endgame is still a runaway in shape - the
  reach climbs 3-4 levels an hour at 87% won until a wall (then stands 10-17 h), the farmed sites at 100% pay
  compounding tins (the Drifter as fire ran 9,591 runs in 24 h), and the cash sink and scrap gates read off it.
  That shape (the coin flip at the reach, the wall, the rewards past it) is the design question for after Matt's
  playtest, not a number. The wall: 1-49 min a build (the Drifter as fire's 9,591 runs the long one; the plain
  reads a minute each to the Quartermaster), the pass 50 min end to end; tidy's parts now read in the wall table.
  Next: Matt plays; a further pass only if something's drastically wrong.

## 0.7.1: the parked list (23 Oct; Matt: "do everything up to 14, 15 and 16 - they are all annoying enough to make
## my playtest miserable")

- Batch A, the canvas pass (items 1, 2, 5, 6, 9 of the 22 Oct list and the art's wiring; the mockup on the web
  canvas, boards 2 and 3, Matt: "wheel's size is fine and alternate strictly. Proceed."). data.gd _web_wheel: a
  class's two lanes are the two halves of one ring ("wheel" [degrees, rows] on every node; "at" and the ids stay) -
  the rails on two tracks, fillers between columns on the arc, the hung notables outward off the inter-column
  fillers so they alternate with the stations, the halves inward toward their element, the keystones on a hub, the
  capstones at the centre and linked to their lane's keystones (the middle off either half: three or four points
  cheaper from the second lane, the review), the bridges past the far pole; one starter a class (the first lane's
  first node, the second lane's first column linked to it). web_view: _lay_wheel; a warm disc under the wheel of
  the class on; each element's region in a hull of its colour, the joint lines in it open or closed; one label a
  class, the elements' labels the name alone; R_RING 1480 (outside the wheels); a node's picture (art/nodes/
  <slug>.png) across its disc from zoom 0.8 when the file exists, the glyph else; a pictured notable at radius 17.
  web_key.gd: the points key over the canvas's corner - the class's, the Pitch's and the ring's free points, the
  six elements' meters as bars with their free points (99+ past that); the band's headline the total across the
  web; the rail's badge counts paragon too. Smoke: the wheel's shape, one entry a class, the key's fit at its
  widest (a level-50 Paramedic, 412 shock points), labels without meter words; run 58 green. Reviewer's two notes
  in (the key's widest case; a picture's load quiet where a clone has no import cache).
  - For Matt: web_key.gd has no .uid yet (the editor writes it); the shot's "Can't add child" line in the cloud
    render is the shot script's, not the game's.
- Batch B, the sim pass (item 11 of the 22 Oct list; item 9 of the pre-playtest list). The compare's discrepancy:
  the Doorman's Jacket's rule (a quarter off their fire with three or more on you) lived in the fight alone; the
  body's figure (survival_value, the compare's verdict and odds delta) never saw it, so 42 armour and 20 HP lost to
  0.4 HP/s one way and the odds delta read a different mix each way round. sim.crowd_mult(on_you) - Bodyline, the
  crowd_less affixes, the Jacket's rule - read by the fight and survival_value alike; the verdict is one figure
  either way now. The Radio's pile capped at Data.PILE_CAP 60 (the pass's bot piled 28k papers in a day): past it
  the plainest plain papers go - lowest rarity, oldest first, sorted once and sliced (the review) - never Kev's;
  one log line a trim (Words.PILE_FULL), the Radio's title "THE PAPERS · n OF 60". Smoke: the vest with the
  Jacket's rule reads better by the rule's share with three on you and the same with fewer; the cap holds 60, the
  rare and Kev's stay, the oldest plainest go first; run 60 green. Reviewer clean; its two notes: the trim
  one-at-a-time was O(n^2) on a 28k save (now sort-and-slice); the cap bites on signal_papers() reads, not every
  append (fine - every reader goes through it).
- Batch C, the Map's card (items 4 of the 21 Oct list and 7 of the 22 Oct list). The rig at the gate: sim.top_up_mode
  - "fill" (every grade of the worn guns' rounds, then the meds from the stash, the best first, into the pouches
  left), "best" (the top grade of each, nothing plainer), "leave" (the rig goes as packed) - saved, one button on the
  card's foot that cycles the three, sharing the insurance's row (the 21 Oct board had three buttons and a head; the
  card had no room once the hints came in). The 0% hints: a dry run records how it ended (killed or out of time, the
  seconds, the heads down, what reached HP by type); survival() tallies them a site under the odds' key
  (_odds_tally; odds_read, odds_gap with the levers that would close the gap - the HP, the armour by the a/(a+K)
  inversion, the damage a second, the resist); odds_reasons turns that into chips: "Not enough HP / armour /
  <element> resist / damage / meds in the rig" after the hard reasons, and a green "Grind <the site before> first"
  leading - hints only, no figures, never a word of how the odds are read (Matt, on the first mockup: "we don't
  expose that that's how we work out the odds"; the dry runs' box with its figures came out). The band's chips take
  two rows (band.chip_rows). Smoke: the three settings and their save, the button's cycle and words, the foot's row,
  the hints at 0% (the green one first where there's a site before, no figure or method in any), the chips' rows
  inside the band; the pile fixture's stash fill fixed (hammers refused forever on the odd cell the meds' top-up
  left - the smoke hung at it for three runs while stale smoke_N files read green; CLAUDE.md has the rule now).
  Reviewer's three notes in (the tally pairs with its own run; the rig's modes from the sim's list; the HP chip
  counts as the HP hint). To the backlog: the odds swing 0% to 100% between plain weather and fog on the same Bank
  (contact 3 to 2) - a number for the balance phase.
- Batch D, the three drawn ones (item 8 of the 22 Oct list, item 4 of the 21 Oct list, item 10; the canvas "Fiat -
  The sky, the pack, the shelf", three boards, Matt: "approved for everything apart from the rain - it needs to read
  like showers and drops ... the rain we had in Greenhorn", then "perfect - build all of D"). The sky shown
  (scripts/ui/sky.gd, new): a layer over a scene - night's blue wash, fog's pale one heavier top and foot, and the
  rain as Greenhorn's watch_deck_fx/atmosphere rig ported: two CPUParticles2D layers of pixel streaks (40 light, 150
  heavy a full screen, scaled by the view's area with floors so the fight's window still rains), the heavy one
  coming and going in showers on a 14 s swell, both leaning with gusts; it emits only while its screen shows (the
  walk up stops before the root Window - headless reads the root as hidden, the smoke on Matt's machine). The Map
  draws it over the painting and its pins on a layer of their own above it (_draw_pins), the clouds and words above
  those; the fight has it between the plate and the wall, under the figures' numbers; the run's band kicker carries
  sky_words ("18:49, day, raining"). Nothing in it changes a number. The pack card's empty words: Words.PACK_EMPTY
  ("Nothing found yet. What the run turns up lands here; pick a cell to read it."), the sizes line gone, the cells
  free left to the header; the full rule as before. Select-many buying on both shelves (inventory.buying "clinic" /
  "fence"): Select, tap cells, "Buy n for X" and "All n · X" (_choose_all); the button counts the cells the lot wants
  the way the buys do (a stack that merges whole wants none) and what won't go stays picked; the vendor's panel lists
  what's picked and what it comes to. Also: "Topped up: 2 meds ..." when only meds moved. Smoke: the sky on the Map
  and the fight against the sim (rain on, rain off, the layer order), the kicker, the shelves' many (Buy 2, All, a lot
  the stash can't hold), `only clinic_shelf fence_shelf` as areas. Three red runs on the way: the many block's
  `return` skipped the cells' layout; restart() turned the dry rain back on; the fixture's filler bandages left the
  stash full for eleven checks after it. Reviewer's notes in (the room check, the visibility, the emitter's width,
  the lifetimes). The art commit (3d7b49f) took everything the manifests had landed, so a checkout reads the art.
- The build's last commit: the art wired, the words passed, the version. The regions' emblems (art/web/region_<slug>.png)
  lead every label on the three canvases; the backdrops (backdrop_training / dial / pitch) cover each canvas under
  the links, proportions kept; web_view.art_at loads by path with a file fallback for a clone without the import
  cache. The Scrapper's and the Poacher's new face and figure read first (people_new/, body_new/; Matt: "swap both
  faces and figures"), the old files kept. The language pass (two reviewers briefed with the style guide, the
  editor's call mine): "the camp's" → "the Yard" (the key, the Pitch's label); THE ELEMENTS as a caps label with its
  note in sentence case; the pile line as mechanics ("The papers are at 60, the cap: the lowest one was burnt"); the
  rig's "Fill up" → "Top up" (one verb with the log's "Topped up"; "fill up" beside Petrol read as fuel), lower case
  after the button's colon, "nothing lower", "Press to change"; the hint shorts "Low …" → "More …" (Low HP read as
  hurt); "Grind before" → "Grind first"; the sky words "raining"/"fog down" → "rain"/"fog"; the shelf's "Buy 4 ·
  180 tins" / "Buy all 6 · 270 tins"; the shelf hint without an input verb. Declined: "free" → "to spend" for points
  (the house idiom across the rail, the Dial and Training; the clash they named was with a string not in the build);
  renaming the element Live (clashes with the perk Live wire) and capping The Cold / The Ring - Matt's names, put to
  him as questions. VERSION "0.7.1" on the title (menu.gd). Smoke green on run 207 (two old checks wanted the old
  words and the old figure path). Next: Matt plays 0.7.1; items 14-16 and the backlog wait for the balance phase.

## Milestone 8, step 1: the Pitch's quick fixes (24 Oct)

- Every buy button on the Pitch says its price: "Build (2,500 tins, 3 copper)", "Refit (...)", shorter when it won't
  fit; a rank's button is just "Buy (79,000 tins)" (Matt: the rank is in the title). Smoke: every building's rank and
  first build button carry their price and fit. One red on the way (run 223): the rank check wanted "Buy rank 2 (",
  the button had fallen to its short form - Matt's call, the price alone.
- Offline progress is gone (Matt: "remove all offline stuff"): the away settle, its report, the cap, the sim's away
  and settling flags, the bot's away third. A save loads as it was saved, a run out included. SAVE_VERSION 7.
- The Generator's away side is energy: Jerry can, Dynamo, Kickback, Flywheel, Pilot light, the rank +2 max energy
  (docs/design/skills.md section 7). The sim reads the figures (generator_*); nothing spends them until the skill
  engine. Pilot light became "the first skill free" - skills start every fight ready. The five pictures need an art
  run; the web-art manifest still lists the old picks. The bot now builds Battery over Overtime: expect drift in the
  balance gates that isn't the skills'.
- Smoke green on run 224. Not a build to play (the picks do nothing yet), so VERSION stays 0.7.8.

## Milestone 8, steps 2-3 (24 Oct): the mockups, the engine, the Poacher's eight, on screen, the bot

- Step 2 (d3852c9): the mockups agreed on the canvas (the fight's buttons at the frame's foot, the picker on the Runs
  card, the Pitch's columns option B), the words through the language pass (skills.md section 11), the Generator's
  five energy pictures run.
- Step 3a (6285452): the skill engine in the sim: energy (a pool filled each fight, regen with a share of pace),
  cooldowns (capped cut), the auto rules, the press and the switch, the Poacher's eight in the fight; the odds' dry runs
  read them through the same code. Smoke 228.
- Step 3b (2c21422): the Poacher's eight on his tree (the hung notables, swaps agreed on the canvas), only your class
  learns its skills, the Headmaster's Cap never teaches one; cdr, energy gain and max energy affixes. SAVE_VERSION 8.
  Smoke 230.
- Step 3c (6c7496b): the fight's energy bar and three buttons, the Runs card's foot in thirds with the skills' button,
  the picker, skill nodes ringed on the web. Smoke 232.
- Step 3d (c21ce2f): the bot picks its three. Smoke 233.

## Milestone 8, step 4 (24 Oct): every class's skills, the Recruit, the unlocks, the broken builds

- Every class's eight on its tree (32 hung notables swapped; the table in skills.md "Step 4's swaps"); the effects
  generalised in the sim (wards, cleanses, buffs, holds, hits, energy, kills, Code blue's last stand, Bung's tins, Back
  of the van's grenade once a fight).
- The Recruit, the sixth class (the Quartermaster opens him): Ordnance and Drill at 0° on the wheel, joints with
  Knuckles and Blades (Petrol had no free place; its class halves' generic +20% folded onto Deep and Weight behind it),
  skills 10% cheaper and energy 20% quicker. The ring's 0° node is now a resists entry.
- The unlock order: the Poacher first; the Gamekeeper opens the Paramedic, the Carpet Man the Doorman, the Manager the
  Scrapper (and the Fence, moved off the Carpet Man), the Quartermaster the Recruit, Kev's first story the Drifter.
- Training's band (Matt: option B on the canvas's Band board): the class cards in two rows of three, a lock and the
  head's name on a locked one, the perks in the tooltip; the words column back to 718 px.
- Matt's calls (all recommended): Not today now "Under 25% HP, you take 40% less damage" (Code blue took the killing
  hit); Look lively "+40% pace for 6 seconds"; Sedative dart "One man on you sleeps for 4 seconds"; the Poacher's card
  "+40% to the first"; Barred pays XP only; Smoke and Suppressing fire don't stack.
- The broken builds redone (docs/design/broken_builds.md): each recipe now four nodes in Data.COMBOS, walked from
  nothing under the real gates by the smoke (the web had left the doc's paths behind); the Recruit's Drilled (the
  Army's three, the Quartermaster's Rifle, Bust them up and Flattened; a kill while a skill of his runs, +3% physical a
  stack).
- Art (tools/make_skills_art_manifest.py, 65 jobs, about $5.20): the 48 skills' pictures (art/skills/<id>.png, the web's
  skill nodes draw the same), the Recruit's 13 tree pictures, his two emblems, face and figure.
- The reviewer's catches over three rounds, all in with checks a mutation turned red: Ringing ears froze a gang with
  nothing slotted; Code blue could be pressed as a cleanse; Back of the van was once a run; Barred paid out; Drilled
  missed an effect's last tick; the language pass twice (skills.md section 11).
- For Matt: Not today only works under 25% HP, where the bot and the odds' dry runs have already left (they bail at a
  quarter), so the balance read never sees it.

## Milestone 8, step 5 (24 Oct): the Pitch's columns, option B; the art in

- Nothing locks (Matt: "B"): either side of a column builds first at its price, the other later at 2.5 times; refit
  and its over-the-stash warning are gone. The header counts both sides (of 80), and so do the record's and the
  balance's yard_built. The bot builds a column's other side once every open column has its first (cash aside), no
  dearer than its cheapest rank; a second side lights no badge. Reviewer's notes in (the bot's condition with its
  reverse check, the count, the badge). Smoke green on run 237.
- The skills' art (65 images, $5.27): the 48 skills (art/skills/), the Recruit's 13 tree pictures, his emblems, face
  and figure; found by name, no wiring. The runner's look-alikes for Matt: Chancer and Four leaf (clovers), Shoulder
  charge and Broad shoulders, the round grenades (Back of the van, Lob one in, Cook it off, the Ordnance emblem), the
  boots (Quick march, Recruit's boots, the Drill emblem), the bayonets. Their .import files come when the editor next
  opens; until then the fight's buttons show the glyphs (SkillBar reads the import), the web the pictures.

## Milestone 8, the balance run and 0.8.0 (24 Oct)

- The Recruit in the reads (tools/balance.bat: plain, physical, bleed) and the bot's crew turn; the Radio's crew row
  holds six (a sixth class played had no button; a check holds every class's button and its fit). Smoke 238.
- One pass (24 Oct, 15:39-16:42; summary.md kept as summary_m8.md, Matt's latest save read alongside as
  playtest_m8.md): 21 RED (19 on the 22 Oct pass), the same shape. The campaign: the Bank 1.5 h median (green; 1.3
  on 22 Oct), the Quartermaster 2.2 h (2.4; the gate 2.5-3.4), level 22-30 at him, retirement's median 16.3 h (15.1),
  the lorry 3.4 h (4.4). The endgame still runs away as before (odds 100% everywhere, cash in hand 3-1,255M,
  deaths one in 2,000-13,000): the design question parked for after Matt's playtest, not a number. The Recruit's
  builds sit in the band: the Quartermaster at 2.1-3.1 h, level 50 at 6.5-15.9 h or never. Doorman as physical's
  first read ends at level 3: its crew turn sent a fresh Drifter out at the cap (by design), the deep sites read in
  the new runner's kit. Nothing drastic (no wall, no unwinnable stretch): no second pass (CLAUDE.md).
- Matt's save (0.7.8, a Drifter, 57 min played): the Manager at 54 min at level 13, every site entered at its
  gear's level, wounds 8%.
- Parked items left: the fans from game start (Matt's look after the art batch: a laptop restart first); the wheels'
  links (the bends hold them clear; revisit only if the playtest still reads them wrong).
- VERSION 0.8.0 (milestone 8's first build to play). Smoke 239. Next: Matt's playtest.

## The endgame slowed (24 Oct): contracts without tins, ranks, the paragon, the crews

Matt: the endgame ran away (the 0.8.0 read had the bot's reach climbing at the pace of its power and tins piling to
the hundreds of millions); "at least 30ish" hours of endgame for an indie ARPG autobattler.
- Contracts pay notes (45%), a rebuild material of a cleared site (35%, the ask's weight, 1 to 6) or salvage (20%);
  no tins, no scrap (Matt: "in the early game they don't offer enough and in the end game they offer too much"). An
  old save's cash or scrap contract is rolled again. The feel gate "Contracts against runs" retired with them.
  docs/design/contracts.md section 2.
- The Pitch's ranks ask salvage up to rank 5 (`YARD_RANK_SALVAGE_TO`), tins alone past it.
- The paragon: a level past 50 costs level 49's step and 5% more a level (`PARAGON_XP_GROW`), not doubling every
  seven (the paragon had stopped and the reach walled at 50).
- The crews past level 50 grow 7% a level (`CURVE_LATE_FROM`, `CURVE_LATE_GROW`), not the curve's 12% compounding.
- Tried and reverted: the reach climbing only after three wins at it (the bot won 97% at the reach; the climb is
  power-limited, not signal-limited).
- Next: the 32-hour balance pass (a read of this slowdown), Matt's evening playtest, then on his go-ahead the endgame's
  chase (docs/design/endgame_chase.md: the breakdown, the pinnacles' mechanics and uniques, moving a unique's power,
  the filter, the collection log, loadouts), then the single balance pass and his playtest on 0.9.0.
- The 32-hour read (36 reads, 18 red): no runaway past 50 now, but the reach climbs fast to about hour 8, then stands
  12-24 h at 43-79 by read (P5 red on every build; full at the reach won 85%, the climb power-limited). Cash still piles
  on five builds (kill tins); deaths and wounds near none, as before. For after the playtest, with the chase plan.
- VERSION 0.8.1 (the endgame slowed). Smoke 242. Next: Matt's evening playtest.

## Parked from the 0.8.1 playtest (24 Oct evening)

1. The web's joints: make each class-to-element joint symmetric, as Live (shock)'s two are: split evenly between its
   two neighbours round the circle, by moving classes or elements round the wheel, if the layout allows.
2. The Pitch has no visible link to the elements, though the classes join them: the web would read better with an
   obvious one. Matt's idea: the Pitch becomes a circle in the middle, and each element's starter node sits on it,
   open at any time with no pathing, but it takes a Pitch point committed there to start levelling that element. It
   also stops physical being a free tree just from the way the game is played.
   Mocked on the canvas for items 1 and 2 (24 Oct, "Fiat – The web's joints and the Pitch circle"): moving classes or
   elements alone tops out at 3 of 6 even joints (as now); 6 of 6 needs three classes to swap one element (option B:
   Paramedic poison to shock, Recruit bleed to poison, Drifter shock to bleed). Waiting on Matt's word.
3. A new game opens on a blank runner and then the Poacher pick: with the unlocks, a new game should start with the
   Poacher already chosen.
4. The first active skill a class unlocks sits behind level 7 / 7 points in its tree: it should come with the first
   point into that class's tree.

## The endgame chase, built (24-25 Oct): 0.9.0

Matt's go (24 Oct): "everything plus a single balance pass after everything using the new balance method", mockups on
the canvas ("Fiat – The endgame chase and the web"), the calls in docs/design/endgame_chase.md "The go". Built in
order, each reviewed, each with its smoke area:

- **The parked four.** Joints B (the Paramedic shock/frost, the Recruit physical/poison, the Drifter fire/bleed; the
  swapped notables and halves renamed: Defib, Cut-throat, Tear gas, Paramedic's paddles, Drifter's razor, Recruit's
  gas); the Pitch circle (an element's starter costs a Pitch point and opens it for every class; only an opened
  element's meter fills; "shut" in the key); a new game starts as the Poacher; each class's first skill comes with
  the first point in its tree. Overdose went with the Paramedic's poison: Flatline (shock) replaces it
  (broken_builds.md). SAVE_VERSION 9.
- **The fight's breakdown.** The Stats room's Last run: "The fight ›", damage by source (guns by name, dots, skills,
  grenades, rules), what hit you by type, the skills used.
- **The true pinnacles' mechanics.** The Lineman: a shield of 30% of his HP, 6 s to break it, then a 3 s stun. The
  Registrar: stamps a skill every 12 s for 5 s; none slotted, red tape (−30% gun damage). The Issuer: prints a man
  every 8 s, six on you at most. Their uniques beside the old: the Lineman's Tool Bag (backpack; the Ambulance set has
  the rig), the Registrar's Stamp, the Issuer's Revolver; the first win gives one of the two.
- **Patterns** (the Workshop's fifth view): break a unique down (asks twice) to keep its power as a one-use pattern;
  put it on a Rare or better of the same slot for a pinnacle drop, the zone's material and tins. A patterned piece is
  kept like a unique (never junk, never a contract's).
- **The loot filter** ("Loot rules" on the Kit's stash bar): up to 8 rules by kind, rarity, slot, weapon, best affix;
  keep, highlight (an amber edge) or scrap; checked top down as a run comes home, before the Bins; a kept piece is
  never sold or binned; a unique, set piece, mythic or patterned piece is never scrapped; the runner's own come-back
  kit is spared; a new rule starts off.
- **The collection** (the Record's "The collection ›"): uniques and mythics found, sites by level marks, classes at
  50, the order beaten, sets complete; every unique listed, the unfound by slot. No power.
- **Kits and build codes.** Three saved kits a runner in the Kit's empty pick panel (Wear, Save worn, asks twice over
  one); a build code in Training (Copy build, Paste build, the plan and the reset's price before Retrain; versioned,
  the class's own perks only).
- **The language pass** (skills.md §11, the chase's words): two reviewers, my calls; banned words off screen (Kit not
  loadout, perk not node, level not depth), one meaning a word (stamped, printed, build code), the broken pattern
  lines fixed, the hidden consequences said before the press.
- **The harness plays one save** (step 8). Each element build is a read from a new game as the Poacher, taking its
  class when it opens (its head, or Kev's first story for the Drifter); the crew swaps after the target reaches the
  cap. A checkpoint run writes the save as the Radio opens; every build plays 4 h from it at the checkpoint runner's
  level, points and kit (the parity table and gate P). balance.bat rewritten; the plain-class reads retired (their
  floor row goes with them); the campaign gates now read the Poacher's route on every read.
- **Art.** tools/pixellab_chase_art_manifest.json (23 jobs, about $1.84): the three uniques and the 20 web nodes with
  no picture (the renamed six and the Recruit's fourteen fillers), checked against pixellab_lessons.md; art.flag set.
- VERSION 0.9.0. Smoke: the cloud's full run green but for its known art-less reds (the watcher was off).
- The single pass (25 Oct, 32 h, the one-save method, 24 reads and 12 parity reads; docs/balance/summary.md): 20 red
  (0.8.1's pass: 18). Green: the Bank, the builds' band, no reds at depth 1, the gang clock, the loot tables, the
  gamble, loot quality and quantity, gear to wear. Red as before: the campaign's bot timings and levels (the QM at
  2.3 h, level 25-27 at him, over the gear at each site), the bot's safety (deaths one in 1,200-8,500, wounds 0-2%,
  odds 100%), and the endgame (the lorry at 4 h, the reach standing 11-26 h, level 50 before hour 8 on five reads,
  cash and scrap piling). New: build parity (from the Radio's checkpoint, 4 h: Poacher as poison +46 levels of reach,
  the rest +24 to +34; the Paramedic's two +17 and +19 and Poacher as frost +18 under half the best) and the
  capstone gate (four builds 2.1-2.7 h after the QM). Matt's last record (24 Oct): the Manager at 54 min, level 13.
  The smoke on his machine found Knuckles' name off its starter (Windows measures the words wider): placed with slack,
  the far name first; smoke 243 green.

## The review's fixes and the second pass's numbers (25 Oct)

From the full review (docs/review/{game,ui,tools}.md), every recommendation Matt took:
- **Sim bugs.** A respec reads the camp's nodes back; a runner's skill slots and Auto are its own; the Revolver's
  printed hit is one shot's, not the volley's; Flattened halves one man's fire, not the gang's (the floor likewise);
  Clean kills pays its own bonus; printed men down heal and count for the skills; skills hit off your hits and are cut
  by resist and lifted by shock as a gun's are; the Arsonist's Rig grows with the fight; the element notables' dots and
  Hit and run's pay come from the effects table. The fight's swing is held a second, and a skill casts as often as
  its quarter-second tick lets it, so the tick no longer changes a build's damage.
- **UI safety.** The Fence's Sell and Training's Reset ask twice (Reset copies the build code first); the Fence's
  rarity rows keep uniques, sets, patterned and built pieces, ruled ones and any class's kit; the top bar's figures
  shorten rather than cut; the Clinic says Hurt under 90%; "dmg/s" and "Item level" on screen.
- **Tools.** Balance reads write to docs/balance/pass/ (the smoke log survives the wipe), each read time-limited by
  tools/balance_read.bat (run_limited.ps1) and the import too; the summary marks each red design, bot timing or bot
  play. The smoke's dice are fixed (seed 1025; `-- seed N` or `random`).
- **The endgame.** Tempering at the Bench (+1 item level a press, scrap 20 × 1.10 a temper, cash by level; not on a
  mythic; never past the level you can wear); item level now raises a piece's worth at the Fence, the scrapper and the
  market (insurance stays on base value); paragon points compound (each on the last); the Weed Burner spends rounds;
  greed after the clear (+10% quality, +5% finds a gang that comes after it, a chip by Your HP); over-level free
  levels 5 → 3.
- Smoke: the cloud's full run green but for its 12 art-less reds. The second 32 h pass follows.
- The second pass (25 Oct, 32 h, on the fixes; docs/balance/summary.md): 19 red - 9 design, 5 bot timing, 5 bot play
  (the first: 20). Kev's story went green; the Bank 1.6 h, the Radio open at 3:06 (2:07 before). Still red: cash held
  2.2-2.5 h of income, scrap 10-80 crafts an hour, the reach standing 10-22 h, full signals won 82%, five builds under
  half the best's reach, levels over each site's gear, retirement's median 25.8 h (11 of 24 never), the bot's
  safety (deaths one in 1,250-2,350, odds 100%). Compounding paragon and greed show no runaway.
- The rain halved (half the drops at half the speed) and none in the four roofed sites' fights (smoke 245 green).
- The second review (docs/review/game2.md, ui2.md, tools2.md, manifests.md): tempering's price and its wear cap at the
  heart of the stall, OVER_LEVEL_FREE clamped out in the campaign, the Fence's arm never clearing, the temper tile not
  saying why it's blocked, gate 17's window and P3's odds measured so they can't pass; the outstanding art and sound.

## The second review's fixes (25 Oct, Matt's go on all of it)
- One ask-twice arm (scripts/ui/arm.gd) for the Fence's rows, Training's reset, the Workshop's break, the Kit's bin and
  kit save: armed on what it would act on (the Fence's on the very pieces, "Sell N?"), gone after 8 s, on another pick,
  or out of the room. The temper tile says why it can't, and "Needs N scrap" when short.
- Tempering: priced by item level (100 scrap × 1.035 a level past 20), its tins four times the piece's worth; it grows
  the piece's flat lines as a deeper drop's; not on a rig, pack or charm; a piece's first three tempers don't raise the
  level to wear it. The bot tempers the gun first.
- The campaign's over-level pay reads your level against the site's gear (D12's clamp gone), so OVER_LEVEL_FREE 3
  bites. The Weed Burner's +40% fire off. Paragon tins add again. A death clears the dead runner's skills; greed's
  finds counted once a search; a class's own tab counted kept at the Fence.
- Under a roof the rain bites nothing and pays no forecast; the card says Roofed; the sound is rain on the roof
  (tools/sound_manifest.json `rain_roof`, the rain until made: `powershell -File tools/eleven_batch.ps1 -Only rain_roof`).
- Boss dens: the fight reads art/fight_boss/<boss>_plate and _cover while he's out (tools/pixellab_boss_backdrops,
  7 bosses, seeds 105000-105013, a Manager test pair first; not run). tools/art_lint.py and tools\art.bat.
- The summary: gate 17 at the bot's pace, P1 the campaign's with bails, P3 on first clears and heads, P6 bot play,
  parity twice a build on the mean, each read's ending named. .gitattributes: .bat and .ps1 CRLF.
- The chase art flagged again for the art session (it wasn't open the first time). Smoke 246 green.
- The third pass (25 Oct, 32 h, on 22ee2ac; 50 reads, all ended ok): 15 red - 6 design, 3 bot timing, 6 bot play (the
  second: 19). Green now: the Quartermaster at 2.8 h, levels at him (21-23 on every build), the Outskirts at the bot's
  pace, the Radio's ladder (2.3-4.9 reach levels an hour to hour 12). Parity: one build behind (Recruit as physical +20,
  the mean of +17 and +23, against the best's +42; five before). Still red: levels over the sites from the Services on
  (5 over), cash held 2.0-3.8 h on four builds, scrap 5-60 crafts an hour (the gate's yardstick, 120 scrap, is
  stale), the reach standing 5-25 h late on, retirement's median 31 h (11 of 24 never), the capstone and the lorry
  (bot timing), and the bot's safety (odds 100% even on first clears, deaths and bails one in 50-1,000). No runaway:
  the top reach 70, tempers 47-228 a read.
- The fourth pass's numbers (25 Oct, Matt: "do as you recommend"): TEMPER_CASH 4 to 8, OVER_LEVEL_STEP 0.15 to 0.25,
  XP_TAPER_END 3.4 to 3.1; gate 15 judges scrap held in hours of the whole read's scrap income, as gate 14 cash.
  Smoke 247 green; the fourth 32 h pass flagged 16:43 GMT.
- The fourth pass (25 Oct, 32 h, on 3ee77d4; 50 reads, all ok): 17 red - 7 design, 4 bot timing, 6 bot play (the third:
  15). Retirement's median into its window (18.9 h, 4 of 24 never; one read at 4.0 h keeps it red); cash nearer (three
  builds at 2.0-2.2 h). Levels against the sites 1 better and still one over the window from the Bank on; at the
  Quartermaster 20-22, the bottom of gate 4's 20-24 - the two gates can't both hold (the Barracks' gear 16 + 3 = 19).
  The stall now waits on tins: tempers x8 priced the bot out (Recruit as physical at level 50 with its kit at item
  levels 25-30, 18,792 scrap held, one temper a pass); gate 15's new measure shows the scrap stranded behind it (2.3-13.4 h
  held on five builds). Gate 6 red at a 190 min stretch, Kev's story late on one read.
- After the fourth pass (Matt, 25 Oct: "as you suggest"): TEMPER_CASH back to 4 (tempering on scrap again; the cash
  held waits for the Issue), the XP taper kept, gate 4 to level 19-23 at the Quartermaster (so it and gate 16 can both
  hold). The bot passes stop here: Matt's playtest next. Smoke 248 green.
- The class cards (25 Oct, Matt: "a story beat for every class unlock"): each class that opens shows its card once,
  back at camp (the Drifter after Kev's first story), with the rooms' intros off too - the room card keyed
  class:<name>, two lines in the class's own voice, its Training lines as the tiles, "To Training". The takes are
  Matt's by hand from docs/design/class_cards.md (voice briefs, lines, files) into art/intro/classes/; the lines come
  on the clock till then. The canvas: the class card, the Issue's moment and the Issuer's counter. Smoke 249 green.

## The Issue and the County (25 Oct, Matt: "let's push and do the lot"; docs/design/the_issue.md)

- Stage 1, the Issue: the first Issuer win at the Mint puts the town on fiat for good - tins and notes converted at
  0.8 x the square root of the pile (hard on hoarders), every price and pay x FIAT_SCALE from there, prices by the fiat
  in circulation (not the clock), the Issuer's rate the Fence buys at (a sale lowers it, time brings it back), the burn
  (fiat out, prices down), a big print on every later Issuer win (the Mint's doubling gone). The Issuer's counter, the
  Fence's fifth tab: six pieces of issued kit (stamped, numbered, a rule each; kept on a death, never broken into
  patterns). The Issue's card once, then the Fence. Money reads ƒ after it. Smoke 250 green.
- Stages 2-4, the County and the remix: four zones of three places past the City (the Motorway, the Docks, the Big
  Houses, the Treasury), each place fought as the order's are on a host site's crew, at the reach + its step, a level
  more a win; each zone wants issued kit worn (2, 3, 4, 6); the heads' own fights (the Bailiff seizes your best piece,
  the Auditor taxes and seals skills, the Collector's bill grows, the Treasurer shields and prints); a head drops issued
  kit. The Map's "The County" button shows the board. After the Treasurer the Radio remixes: signals on the County's
  places, its heads away from home, issued kit off the deepest. The bot runs the order and the County and buys and wears
  issued kit; the balance read reports the Issue and the County (gate 18). Art is the host sites' plates for now.
  Smoke 251 green. Then the full 32 h pass.
- The fifth pass (25-26 Oct, 32 h, everything in): 18 RED (7 design, 5 bot timing, 6 bot play); the campaign's and
  the Radio's gates read as the fourth pass did. New gate 18: the Issue on 1 of 24 reads (the Doorman as bleed, at
  20.7 h, on a broken build at reach 154) - the Mint sits at the reach + 6 + a level every 4 of the town's worth, about
  level 160, past most builds' reach (41-80); no read reached the County. After the Issue that read earned 25-30M fiat a
  half hour and hit the price cap in an hour. Bot fixes from it: no issued kit it can't wear (140 bought for a level-1
  runner), a burn an hour (2,380). The Mint's level is Matt's call before any further pass. Smoke 252 green.
- Matt's calls after the fifth pass (26 Oct): the Mint at a set level 60 (a level more a win), not past the reach; the
  issued cap's rule kept (the Fence never under the face rate); the kit counted in the Issue's pile - the stash, the
  runner's and the crew's worn kit at their sale worth, each piece selling after at the pile's rate. The County's art
  manifest written (tools/make_county_art_manifest.py: 4-job test, 54-job set); the test run (07:55, $0.46) for Matt's
  eye in the frame. Smoke 253 green.
- The County's art in (26 Oct, Matt's go): every place's fight plate and wall (art/fight_county/, read on its runs by
  RunView; the smoke holds each drawn wall to the duck), its map card (the County board), the four heads (portrait,
  stand, fire, down) and the six pieces of issued kit. Rerolls: the Treasury's wall (inset), the Treasurer's fire (her
  rifle), the Truck Stop's wall four times (flat counter fronts keyed out with the background; tipped tables held).
  About $7.40 in all. Smoke 255 green. Next: the County's drawn map on Matt's painting (docs/design/county_map_brief.md).
- The County's drawn map (26 Oct, Matt's painting art/map/county.png, 512 x 424 drawn x2): the four zones traced as a
  first pass (the Motorway the top strip, the Docks the quay down the right, the Treasury the town, the Big Houses the
  country west and south - Matt plays and corrects), a pin a place (a head's a diamond) in its odds' colour, a shut zone
  dark and hatched with its names scrambled, the picked zone lit, the place's card at the right. The smoke: each pin in
  its zone and clear of its edge, the pins apart enough to click, a click picks, every name inside the map. Smoke 257
  green. Ready for Matt's playtest.
- The sixth pass (26 Oct, 32 h, on 73365bd): 20 RED (8 design, 6 bot timing, 6 bot play); gates 2 and 6 tipped red at
  their edges (bot timing), the rest as the fifth. The Issue on none of 24: the Grid at the reach + 2 + the worth read
  0% on every save, so its key - which the Mint's rebuild wants - never dropped (3 reads built the Mint off an early
  Grid win); and the Issuer at level 60 read 0% under reach ~70 (100% at 50 for a reach-70 Recruit). The Doorman as
  physical's 1.8M dmg/s was the no-top ladder at reach 120 (kit at item level 120, paragon x3.3), not a broken build -
  the combos are off in reads. Matt's calls: the Grid at a set 35 and the Mint at 45 (a level more a win; the Archive
  as was), the bot's Grid first win at FIRST before the Issue and the Mint built first once the key's in, the spread
  left. Smoke 258 green. The seventh pass next.
- The seventh pass (26 Oct, on b38b255): 17 RED (6 design, 5 bot timing, 6 bot play); gate 18 green - the Issue on
  most reads (5.4-31.6 h) now the Grid's at 35 and the Mint's at 45; gates 6 and 7 green again, the stall shorter,
  parity one build behind. The County stalled at its first head on the two reads that got in: its places sat at the
  reach + 2 to + 14 and nothing past + 3 was won (the Bailiff 0% at reach + 4 however soft he was made, 88% at reach -
  6). Matt's calls: the County at set levels (50/52/55, 60/62/65, 70/72/75, 80/82/85, a level more a win); gate 3 left
  for the playtest; and the broken builds read on their own in every pass - each of the six 16 h from the checkpoint
  at level 50, the combos on for that read alone, its set and unique held at the reach (tests/balance.gd _broken,
  bot.gd _hold_broken), what it beat and when in a table of the summary's own, outside the gates. Smoke 259 green.
- The eighth pass (26 Oct, on d48618c): 19 RED; the Issue on 8 of 12 builds (7.7-29.4 h), the County entered by 3 (the
  Doorman as bleed 7 of 12, past the Bailiff and the Auditor); gate 7 red (the Recruit as poison never finished Kev's
  story). The broken builds weak - my fixture's: their set pieces and unique were rolled with no tier, so on the
  campaign's bases (55 armour against a deep suit's 260). Matt's calls: issued kit counts as a piece of the set you
  wear (one set a piece, the one with the most real pieces on); the County's own crews drawn (28 jobs, $2.24; RunView
  draws a County run's crew once all six of its figures are on disk); the broken builds re-run alone on his machine,
  each beside a plain baseline, broken when it beats everything and gains 1.5x its baseline's reach. Smoke 260 green.
- The third review (26 Oct, the same three passes as the second: game3, tools3, ui3 in docs/review) and its batches. The
  hunt and the build-stage gauntlet before it (tests/balance.gd _gauntlet: each build's end state through the Grid,
  the Archive, the Mint and the County's 12, 3 tries each). Matt's calls, money first: circulation halves every
  CIRC_HALF_H and a burn takes a quarter of it; notes after the Issue are income; held kit is stamped at the Issue's
  rate for good; an order's set level for its first win only; the Archive at 40; the bot wears only what the next
  zone wants; stamping your own piece at the Bench for the slot's issued price (it counts towards the County's want).
  Batch 1 (the plain bugs: loot once a search, the counter's piece one roll, issued kit off the shelf, a death past 50
  keeps 50 and takes the paragon, red tape -50% every 10 s, the order card's "Pays xN") and batch 2 (the smoke's
  gaps: the Auditor, the remix before the Treasurer, the County's art, the shut names, the Kit's set line) 9f32ab6.
  Batch 3, the open UI items: endgame figures on the run screen never cut; chips can carry hover words (greed's);
  "Gang in: after time's up"; grouped scrap, runs and notes; the paragon rows say compounding (1d5dad2). Matt asleep,
  my recommendations taken: a picked-clean run with nothing before time's up comes home on its own (3e6c812); every
  ask-twice "<what goes> - press again" / "Again?", four seconds, the Rules' Delete included (3b81b37); a remixed
  signal draws the crew the Radio named (E1) and the Mint's card warns what the win turns the pile into (A1(a)).
  Smokes 269-274 green. Then the final pass, 32 h with the gauntlet.
- The pinnacle builds and the wall (27 Oct, docs/design/pinnacle_and_exploits.md). Matt: "There's no point my playing if
  we know there's a wall." The orders on a set ladder after their first win (35/40/45, then 90/95/100 and 2 a win);
  the gauntlet from a standard camp (level 50, reach 90, paragon 30, kit at its level) and as gates G1 (the six
  pinnacle builds: every place first try, no deaths) and G2 (the rest inside three tries), run twice, the better
  kept; the crews 7% a level from 35 (was 50); a pinnacle build's stacks guard 1% each to 60% and a run starts with
  40; Embers 12%; the repeat orders' heads x0.65 (the Mint x0.55); the Treasurer 18 HP, 2.5 fire; HP on the Bank's
  and the Fire Crew's pieces. Gauntlet 8: five pinnacle builds 15/15 first try, Embers 12; the rest 12-15. The full
  pass on f8f53bd: the Issue on 22 of 24 reads (12 before), the County cleared on 8, the reach's longest stand 4-10 h
  on most (6-21 before). Smokes 276-280 green. Matt plays.
- Parked for after the playtest (27 Oct): Embers' last three places (the Archive, the Mint, the Treasury); the bot's
  stuck reads (Paramedic-frost-2, Recruit-physical-2 at reach 31-32: it never makes a one- or two-paper signal when
  Full reads 0%); the summary of the pass once its last read (Scrapper-fire-2, an overfull stash, slow) lands; the
  exploits (the design's step 3, six recipes in the doc).
- Before the playtest after all (27 Oct, Matt): the six exploits and the bot's fix in (275b94a, smoke 281 green). The
  pass on f8f53bd landed: 18 RED; the Issue on 22 of 24; P5 still red, though the long stands are the runaways sat
  past the content (reach 160-310) and the two stuck reads; G1 from this pass's own end states weaker than the last
  gauntlet's (drilled 9, Embers 9, live_load 12, opened_for_good 14 of 15) - the camp evens the reach, kit and paragon
  but not the Yard's ranks, the town's rebuild or the trees, so the end states still differ. Parked: even those too
  (or run the gauntlet from one shared camp per class), Embers, the next pass to read the bot's Clear and Faint
  signals.
- The pack as a real grid (27 Oct, Matt: "the slots are taken but there are two rows of slots showing - revisit the
  inventory tetris idea properly"; docs/design/pack_grid.md). True tetris for the pack only (the stash stays a flow).
  Each bag its own shape: a width "w" (5 to 13), its cells row by row in pages of seven, a piece never across a page's
  edge; the Plastic bag 5x3 (15), the Carrier bags 8x2 (16), the School bag 6x3 (18) up to the Long-range bergen 12x8.
  Pieces lie at "pos", turned by "rot": a find lands where it first fits, either way round; by hand one with no place
  waits on the floor (in the fight too: the game never swaps for the player); the player drags pieces about the pack
  (R or the right button turns the one in hand, green where it lies, red where it won't), from the floor to a cell, and
  out of the pack onto the floor. Auto and the bot pack with the same packer; full, an upgrade takes the place of the
  cheapest piece that frees room for it by shape. A head's unique, the first gun or a mythic with no room is strapped
  on (carried, drawn past the pack's rows) and goes in when room is made. A bag swapped mid-run must hold what's
  carried, packed afresh. Smoke: _pack_grid_checks and _check_pack_grid. A balance pass to follow (what comes home
  changes).
- The pack grid's playtest tweaks (27 Oct, Matt): a selected piece turns in place with R or a right-click; the floor's
  row on screen all run at one height (the rig over it in a fight, under it in the search, one row either way); Ditch
  puts a piece down on the floor with no scrap and Fill up leaves it; Salvage moved to scrapping at the Workshop.
  Smoke: _floor_all_run_checks.
- The deeds' fate (27 Oct, Matt; docs/design/deeds.md): sold, held and burned read by the Bailiff (sold: he takes your
  kit and drops the deeds once when down; held: he seizes the deeds instead and keeps them if the run ends in his hands;
  burned: his warrant's void) and by the Issue (held deeds out of the pile, unstamped); a Radio line each; Burn at home
  from the Kit room. Smoke: _deeds_bailiff_checks.
- Parked from play (27 Oct evening, Matt: "park all 5 but we do the mockup and design work now so its ready"; the
  canvas's "Hit registers" and "Words pass"): (1) Training's caps pass, and a locked class's level "Level N", not
  "L4"; (2) "Knife on" -> "Knife equipped" (and "X equipped, Y into the pack"); (3) the caps pass on the search bar - a
  capital after every "·" in running words, done once in the label helpers, small-caps heads as they are; (4) the class
  cards' three headlines written per class (drafts on the board for Matt to edit); (5) hit registers: bigger outlined
  numbers that pop, a white flash and a spark on them, their muzzle flash and a tracer, a red vignette and a white
  lost-chunk on your bar, a frame jolt on a big hit.
- Parked (27 Oct, Matt: "what does the picked over mechanic actually do?"): the name does three jobs - a cleared
  site's wear (kill drops -50%, cash -30%, fading over RECOVER_H 2 h of play; a new depth is fresh; the Atlas's Worn in
  speeds it), "picked clean" (every crate open on a run) and the Atlas's Picked over rank (a site's own things more of
  its finds). To talk through after the playtest.
- Parked, designed (27 Oct, Matt's answers): hit registers take 2 (hit-stop, stagger, a spray, the bar's chunk flying,
  bigger kills; their tracer dropped); picked over as the crates across runs, the next crate yours to pick, a refill 20
  min after picked clean, the wear gone; the Workshop to the Carpet Man (docs/design/picked_over.md). Canvas: "Hit
  registers", "Picked over, as the crates".
- Parked (27 Oct, Matt): the Kit room's Scrap button becomes "Bin", the piece gone for nothing (scrapping is the
  Workshop's, and with the Workshop at the Carpet Man it opens soon enough); Select-many's bin likewise. A loot rule's
  Scrap and the Stash's Bins keep paying scrap (Matt's call: automation set up and earned). The wear on cleared sites
  stays for now (Matt: "I'll deal with it for now unless it really starts to annoy me").
- Built, out of the parked list (27 Oct, Matt: "the loot change needs to go in ... you may as well do the rest"):
  picked over as the crates (249c0d2: a site keeps what you didn't open, a crate back every 3 min, the next crate
  yours to pick, the wear gone, the Atlas's Local stock); the Workshop at the Carpet Man with the fitter's kit and the
  Kit room's Bin for nothing (1e10b6a); the words pass (ce7bcd3: a capital after every ·, Level N, Knife equipped, the
  class cards' headlines); the hit registers (the hold, the knock, the spray, the chunk, the kill's throw; bigger
  edged numbers; your bar's white chunk; the red by the hit and the jolt on a big one). Smokes 288-291 green. Parked:
  the Workshop's voiced room card still says "The armourer's roll" (a recorded line); the bot grinds one site, so the
  next pass's search and scrap gates move; the bot's early scrap from binning is gone.
- Parked, designed (28 Oct, mid-playtest): the tutorial (docs/design/tutorial.md, the canvas's "The tutorial"); the
  voice lines owed (docs/voice/recording_list.md); the endgame's activities brainstorm (docs/design/endgame_activities.md:
  single player, rotating); meds by what they treat, magazines with real reloads, the Clinic's quality from supplies
  (docs/design/meds_ammo_clinic.md). Matt playing a fresh camp through to the County to time it (target: 20 h+).
- Parked from play (28 Oct): the Workshop's padlocks draw at their picture's own size over the affix words (workshop.gd
  sets the TextureRect's size before EXPAND_IGNORE_SIZE; the Crates panel has the order right). Fix: the expand mode
  first, and a smoke check that each padlock is 22 px and clear of its line. The figures' flames don't follow a dying
  body's tilt (cosmetic, the reviewer's follow-up to e3216f5).
- Parked, designed (28 Oct): three tree resets (class, the Pitch, the elements), every part off a weapon at once, and
  the exchange in the contracts' place (docs/design/resets_strip_exchange.md).
- Parked from play (28 Oct, Matt died on Signal 4, the Barracks, sorting a pack split over two pages): Select-many
  never sells outside the Fence - the Kit room always Bins (armoury.gd sets `binning` only while the Fence is shut) and
  the Workshop's grid Scraps (it has no mode, so it fell back to Sell), with a smoke check that neither shows Sell. The
  big pack on one page (Matt's pick): the cells shrink till every row fits, floor about 28 px; only a pack past that
  (the Removal Van) scrolls, with drag auto-scrolling at the edges, and `pack_one_page` goes. Mockup first.
- Mocked (28 Oct, Matt: "do the mockup of the pitch now and add the radio in too"; canvas boards PitchA, PitchB,
  RadioAir, RadioDial, TwoElements), waiting on his decision: the Pitch room as building cards with the picked one's
  rows (A, the rules as now) or two themed lines a building climbed in order (B, recommended); the Radio's tabs as a
  bar, the air's decoder as one row, three fixed signal slots, the Dial's regions side by side with every node named,
  the story's beats in a row. Matt (28 Oct): two elements at most in the skill tree; whose two (the camp's, a class's,
  or the joints') and whether Knuckles counts are on the TwoElements board. After his call: every parked item before
  he plays again, then 0.9.1.

## Every parked item built, 0.9.1 (28 Oct, Matt: "I'll take your recommendations - build it all"; the tutorial left for later)

Each reviewed, its smoke area added, the device smoke green before its commit:
- Select-many sells only at the Fence (737cf38): the Kit room and the Clinic bin, the Workshop scraps.
- The whole pack on one screen (a5217d0): the cells shrink till every row fits, a scroll past the smallest cell.
- Three small fixes (ebc29cc): the Workshop's padlocks at 22 px, the flames lean with a tilted body, the bot passes a
  site picked clean.
- Two elements a class, Knuckles counting; the Pitch's and an element's resets; every part off a gun at once (147fc9c).
- The exchange in the contracts' place (bc6568a), Contacts and the Fixer on the Fence's Prices line.
- The Pitch as two lines a building (86da52a): the canvas's "Pitch B"; an old save's picks moved by id.
- The Radio reworked (f578b4c): the tab bar, the air in two columns, the Dial as three columns of named tiles (its node
  pictures no longer drawn; the picked strip shows one), the story's beats in a row.
- The cures, the Clinic's supplies and magazines (SAVE_VERSION 10: an old save shows the incompatible warning).
- Not built: the tutorial (Matt: later); the endgame activities (a brainstorm: the playtest's hours decide).
- For the balance pass next: the magazines slow the bot's climb 2-3x (the pouch size); the exchange's drafts; the
  contracts' notes and materials income gone; the Pitch's ranks now wait on a line's fifth step.
- Voice: the Fence's card's third line changed with the contracts (docs/voice/recording_list.md).

## The names, the three-stage review and its fixes (28 Oct, Matt: "fix all now")

- The skill tree's names (Matt): an element reads by its name ("Rat Man", no "The" or "·"), a class by the class's
  name, in the Dial, the key and the Barracks' Also row (`WebView.plain_name`).
- The review (docs/review/28oct/): every A and B fixed, smoke area `review28`. Matt's calls: scrap is bought at the
  exchange, never sold; a rig packs one heal, one magazine, the cures, then magazines to their share and heals
  (`Sim.pack_rig`, the gate's and the bot's); scrap, salvage and materials held join the Issue's pile (its card:
  "kit and goods worth"); the Clinic shows a Supplies badge and What's next a hand-in line.
- The bot buys heals and cures only off the Clinic's shelf now, so its figures move.
- Open for Matt: salvage and materials parked before the Issue still sell after at the straight rate (a stamped rate,
  or the exchange shut on the Issue's run); a camp with one element hands it and the next one trained to every class
  that hasn't picked (pin at any size if he wants it explicit); tests/shot_fence.gd and fp_dbg.gd (his) still call
  the contracts.
- The balance pass on 1bda16d (before the fixes, its rigs packed no heals): 23 reds against 27 Oct's 18; a fresh
  `24 1` pass follows.
- Designed, for after the 0.9.1 playtest (28 Oct, Matt's calls): repeat runs on a cleared site (×5 to start), runs
  safe to leave (a bail loses the pack, never the loadout), trips (a runner of another class and hired hands on a
  route, resolved by the odds sim), the Bunkhouse on the Pitch, the wagers first of the endgame's activities.
  docs/design/trips.md; canvas boards RepeatRuns, Trips, Bunkhouse.
- The `24 1` pass on c252141 (20:14-21:52, 1 h 38 min; Scrapper-fire's one-save read the long pole to 21:51, the
  gauntlet in the last minute): 21 red (1bda16d's 23, 27 Oct's 18). Campaign walls down from four builds to two
  (Drifter as fire and Scrapper as shock never beat the Bank). Deaths and bails back with the heals packed; faint
  signals won 70% (target 85%+); the gauntlet's live_load fell to 3 of 15 first try. Next, agreed with Matt: the
  iterating flag at 16 h with a per-read cap and no gauntlet (~25 min), then his playtest from fresh.
- The first quick pass (`16 1 quick`, 23c71d1): 24 min (23:15-23:39), four reads capped. 22 red. Drifter as fire now
  beats the Bank (the fists wall gone); Scrapper as shock, Doorman as physical and Recruit as physical don't by hour 16:
  no collapse, a slow climb (about 100 damage a second at level 20, farming tiers 4-6, the loadout's worth flat). Bot
  timing, not tuned before a playtest (Matt's rule); one read a build, so a single unlucky read reads the same way.
  Faint signals 90%. Next: Matt plays 23c71d1 from fresh.
- UI, raised 29 Oct (Matt): "it becomes really difficult to compare an item 1:1 if you have attachments and sockets
  because it changes the base damage ... we need a way to display the base stats vs base stats." Mocked on the canvas
  (Compare): A, three readings (as they stand, base to base, with your parts moved over - the verdict's, and a
  "Swap, parts and all"), recommended; B, two readings. Matt (29 Oct): A.

## The overruled build (29 Oct, Matt: "build everything as planned"; real times, UTC = GMT)

| Piece | Built | Review + fixes | Committed |
|---|---|---|---|
| Itemisation + the compare (A) | 52 min (lost to the container's restart), rebuilt 11:20-12:50 (90 min) | review 12:52-13:23; fixes 13:45-15:03 (78 min) | 2f8a734, 17:39 |
| Repeat runs, the Bunkhouse line A, Kev's wagers | 60 min (lost), rebuilt 12:52-13:43 (51 min) | review 15:04-15:54; fixes 16:00-16:30 (30 min) | 2f8a734 |
| The expeditions, the Bunkhouse line B | 16:30-17:23 (53 min) | review 17:40-19:30; fixes 19:30-19:59 (30 min) | 3ff30e3, 458fd2c |
| Art manifests (items 179 jobs, expeditions 35) | 17:40-17:47 | lint clean | 458fd2c; the test batches flagged 20:05 |

- Lesson (CLAUDE.md): the cloud scratchpad was wiped at 11:10 with two builds unsent; every workspace is now
  snapshotted each phase, and each piece goes to this repo as soon as it's green.
- Each piece had the three-stage review (game, UI, tests) and a language pass before its commit; every fix's check was
  shown to fail without it. Matt's calls on the way: repeat runs cut XP only; "Expeditions" on screen; the expeditions
  convert, never print (x0.85 base, hands capped x1.2).
- Next: the `16 1 quick` pass on 458fd2c (dropped 20:09), the endgame read from the Radio's checkpoint, Matt's look at
  the 14 test pictures, then the full art runs.

## Tuning history (moved from the code, 30 Oct)

The changelogs that sat on scripts/sim/data.gd's const lines, moved here as they stood by the clean-up
(docs/review30.md, refactor item 4). Each const keeps one line of current rationale in the code.

- `UNIQUE_CAMPAIGN := 0.02`: D6-7: 0.005 and 0.01 put a loose unique by the Quartermaster on 2-4 builds in 10
- `ZONE_QUALITY := [0.0, 0.15, 0.30, 0.32]`: E1 (17 Oct): .38 to .32, the City read 18% epic or better (gate 12: 8-16%). D7: the City at .45 read 18% epic or better in its gear (gate 12: 8-16%)
- `CURVE := {"hp": 3200.0, "dps": 3.6, "xp": 30.0, "cash": 40.0, "drop": 0.5, "grow": 0.12, "reward": 0.05, "rarity": 0.10}`: D15: grow 0.14 to 0.11, D19 0.08 (D20: reward 0.10 to 0.08 with it - level 50 at 6.5-11 h on five; D28 0.05: the strong builds out-earned the rest up the reach, level 50 from 9.3 h to never) - the reach is the runner's power against this slope (signals since D3), and at 14% a level a signal past the reach went from 100% to 0% in one level and the reach stood hours at a time. grow 0.08 to 0.12 (22 Oct, the web pass: the reach ran 11 to 70 in 1.4 h at 96% won at the reach, then 149; a probe at 0.12 held it to 39 by hour 6)
- `CONVOY_HP := 0.55`: 0.25 to 0.4 to 0.7 to 0.55 (12 Oct: at 0.7/1.0 the fire Drifter and the shock Scrapper never took it and the Paramedics still did at 1.8-3 h - the halfway, for the playtest); the convoy's heads at this much of their HP each and CONVOY_DPS of their fire: they come light and tired, the crews left with the load (the probe, 7 Oct: at 35%/full fire a Poacher read 0.80 and a stronger Doorman 0.00 - the Poacher's first-of-the-gang bonus counts on every head; at 25%/0.75 both read 0.93-1.00)
- `CONVOY_DPS := 0.85`: 0.75 to 1.0 to 0.85 (12 Oct, with CONVOY_HP)
- `LORRY_MULT := 1.12`: 1.25 to 1.12 (12 Oct: with the lorry off, the moves in 16 h fell from 9-20 to 1-9 - the ×1.25 outran a depth's ×1.14 and each leg came easier than the last); the Yard's damage and HP, times this a lorry beaten, kept across moves: the prestige
- `ILVL_GROW := 0.05`: 0.07 to 0.05 (21 Oct, the crew's reads and a kit probe): at 0.07 an at-level kit kept pace with the crews (an edge's half-life 25 levels) and the bot's edge - uniques, the Bench, paragon - ran the reach to 221; at 0.05 an edge halves in about 10 levels: a few levels a find, then the next
- `SCRAP_SEARCH := 0.35`: 0.5 to 0.35 (12 Oct, the same read). The pass (6 Oct): 0.2 read half a craft an hour against the dearest build; 0.4 left three builds at 0.5-0.8
- `SCRAP_HANDFUL := [5, 10]`: the pass (6 Oct): [3, 6], [4, 8], then [6, 12] which read 3-5 crafts an hour on the builds that run most
- `CAMPAIGN_LEVEL_MAX := 1.5`: 1.3 to 1.5 (22 Oct, the web pass: every site 100%); was ...to 1.3 at most (7 levels on). 0.08 to x2 (22 Oct, the second pass): a Scrapper whose kit stalled at level 14's while its level ran to 28 found both its sites at the cap and the Bank out of reach, for 20 h - levels come steadily, kit is luck (Matt's stance): a lagging runner slows, never sticks
- `CAMPAIGN_HOSTILE := [0.9, 1.15, 1.3, 1.3]`: 22 Oct, the web pass (the fillers +40-60% by level 30, web.md §8): the Estate +15%, the Town and the City +30%; the Outskirts as Matt played them. / by zone (the pass, 20 Oct): the Outskirts as they were, the Town and the City harder (six-hour reads: Town 1.15 and City 1.2 left three builds of ten short of the Quartermaster; 1.25 and 1.4 five) - 0.9 everywhere had the Bank at 29 min by hand, every run at 100% and no death in 41; 1.5 everywhere killed eleven builds of fifteen at level 1. D20: 0.9, with XP_SCALE 2.9 the Bank at 1.9 h
- `WEAR_PER_ILVL := 2.0`: 2.5 - 1.5 from D8 to 18 Oct (D8: x3 had the City's drops at wear 19-25); 2 - 2 now: the City's 12-16
- `XP_SCALE := 3.3`: 22 Oct, the web pass: 2.9 to 3.3 (level 25-34 at the Quartermaster against 20-24; the sites cleared 5-8 levels over their gear). D19: 2.4 to 2.9 - level 23-26 at the Quartermaster on seven of ten (the gate 18-22)
- `XP_TAPER_END := 3.1`: 3.4 to 3.1 (the third pass: level 50's median at 31 h, 11 of 24 never; want 12-24);  D29 3.4 (D28's slower pay: six ended at 41-49 at 24 h); D27 4.0, between (Matt, 16 Oct); D26 5.0 (D25's one-a-win reach: level 50 at 7.7-11.4 h on eight); D24 3.0 (the two-read: one read of four builds in the window, the other at 44-48 at 24 h); D14: no taper (level 50 at hour 4-7 at 0.4); D16 rising to x3.6 by 40 - 50 at 7-11 h on five; D22 x3.2 (four ended at 47-49)
