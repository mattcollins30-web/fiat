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
