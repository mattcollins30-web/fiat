# Fiat — status

The idler cut of FIAT. Concept: `docs/design/concept.md`. Repo at `C:\Users\mattc\Documents\fiat`.

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
- **Events** (`Data.EVENTS`): on three runs in ten, some way in: a convoy (a bigger gang, carrying
  notes), someone trapped (freed, `promised` to the yard), a locked cache (a bench at level 2 opens it:
  a find a tier up with +0.5 rarity; else it stays shut).
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
