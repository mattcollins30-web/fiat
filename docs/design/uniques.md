# Uniques by tier (12 Oct 2026, design - not built)

Matt, 12 Oct: most uniques were made before most of the bases, so plain bases simply outclass them whatever their
rule. He wants uniques tiered like the bases: levelling uniques at the bottom that drop almost commonly, chase
uniques at the top that hardly drop, the gaps filled in between, and the ones good enough to keep for good dropping
at several tiers of their own. **Design only: nothing is built until Matt's Poison Poacher playtest save is in, and
then this lands with that balance pass** (it changes numbers, so it goes in before the pass, never after). The
model was agreed on 12 Oct (section 6).

## 1. What we have (the audit, 12 Oct)

Forty uniques. The bases go to tier 9 in every gear slot; the uniques sit on tier 1-6 bases and none above.

| A unique's base tier | Uniques |
| --- | --- |
| 1-2 | 22 |
| 3-4 | 8 |
| 5-6 | 10 |
| 7-9 | **0** |

A unique's affixes grow with the depth it's found at (`_scaled` by item level); its base never does, and in the
endgame the base is most of the figure. Against a plain tier-9 base with no affixes at all, by the figure the
game's try-on reads (damage a second for a gun; armour and half the max HP for a body piece):

| Unique | Found from | Base tier | Its figure | Plain T9 base |
| --- | --- | --- | --- | --- |
| The Council's Weed Burner | depth 12 | 1 | 15 dmg/s | 192 |
| The Butcher's Steel | depth 12 | 2 | 27 dmg/s | 192 |
| The Dinner Lady's Ladle | depth 12 | 2 | 33 dmg/s | 192 |
| Jump Leads | depth 12 | 2 | 24 dmg/s | 120 |
| Nan's Cardigan | depth 12 | 1 | 30 | 260 |
| The Rat Man's Overalls | depth 14 | 2 | 45 | 260 |
| Lucky Cap | anywhere | 1 | 5 | 100 |

The worst are the build-defining ones: found at depth 12 or deeper, when the runner already wears tier 7-9, on a
tier 1-2 body - an eighth to a fifth of a plain item. The try-on (11 Oct) now says so too: they read ▼ Downgrade
and Equip if better never puts them on. What holds up: the bosses' (the Manager's Coat tier 4, the Quartermaster's
Rifle tier 6, the Lorry's Load tier 5, found about where those tiers are worn) and most charms (a charm's base
barely grows with tier).

## 2. The model

### Three bands

| Band | Tiers | What it's for | How often (first figures, the pass tunes them) |
| --- | --- | --- | --- |
| **Levelling** | 1-4 | a lucky find on the way up; outgrown by the town | the commonest unique: weight 10 |
| **Core** | 4-7 | the bulk; the builds start here | weight 4 |
| **Chase** | 7-9 | the reason to dig; hardly drops | weight 1 |

A unique can only drop where the find's own tier is inside its range (the tier a plain base from that find would
roll at). Among the uniques that can drop there, the band weights pick one. The overall rate stays a share of finds
as now (`UNIQUE_DROP` a find, times the depth past the first); the bands decide which unique, not how many.

### Two kinds

- **Fixed**: one base, one tier, as now - only for the uniques whose point is the moment they drop (a boss's).
  Even these move to the tier where they're fought (see the table).
- **Scaling**: the rule is the point, so it's kept for good. The unique drops **at the find's tier, inside its
  range**, on that tier's body: its stats are the best base of its slot (and gun type) at that tier; its name, its
  art (art follows the unique's name already) and its rule stay its own; its affixes scale with the item level as
  now. A Weed Burner found at a tier-7 find is a tier-7 flamethrower; a better copy later replaces the first, the
  same rule on a stronger body. That's Matt's "drop in various tiers within themselves".
- Where a gun type has no base at some tier (a melee secondary stops at the Cosh, tier 3), the unique takes the
  type's highest base and raises its figure by the slot's own tier curve - so the Lollipop Lady's Sign at tier 8
  hits like a tier-8 secondary while still being a lollipop sign.

### The rest of the rules

- **The shelf** (the Caravan's) records the best tier found of each; the gap shows until the first.
- **A duplicate** of a scaling unique at a higher tier is an upgrade by the try-on, so the stash arrow and Equip if
  better handle it with no new code; the old copy sells.
- **The site uniques** keep their site and their depth gate; their tier is the site's at the depth dug, inside
  their range.
- **The bosses' and the pinnacles'** scale with the depth the boss is fought at on the map (the endgame's boss
  runs), inside their range, so a deep Carpet Man drops a better Van's Spare.
- **The Fence's mate** offers a loose unique at the player's deepest tier, inside its range.
- **The tier shows** on a unique's card and tooltip ("T7"), as on any item, so two copies read apart.

## 3. Every unique

Kind: S scaling, F fixed. Range: the tiers it can drop at. "Moves" is how its source changes; blank keeps it.

### Levelling (tiers 1-4)

| Unique | Slot | Kind | Range | Found | Moves |
| --- | --- | --- | --- | --- | --- |
| Grandad's Shotgun | Primary (shotgun) | S | 1-4 | anywhere | |
| The Postman's Bag | Backpack | S | 1-4 | anywhere | |
| The Doorman's Jacket | Armour | S | 2-5 | anywhere | |
| Lucky Cap | Helmet | S | 1-4 | anywhere | |
| The Van's Spare | Secondary (pistol) | S | 3-6 | the Carpet Man | scales with the boss's depth |
| Underlay | Armour | S | 3-6 | the Carpet Man | scales with the boss's depth |
| The Scout Leader's Whistle | Charm | S | 1-4 | anywhere | from depth 12 to anywhere |
| A Traffic Warden's Hat | Helmet | S | 2-5 | anywhere | from depth 12 to anywhere |

### Core (tiers 4-7)

| Unique | Slot | Kind | Range | Found | Moves |
| --- | --- | --- | --- | --- | --- |
| The Manager's Coat | Armour | S | 5-8 | the Manager | scales with the boss's depth |
| The Branch Pistol | Secondary (pistol) | S | 5-8 | the Manager | scales with the boss's depth |
| The Council's Weed Burner | Primary (improvised) | S | 4-9 | depth 12 | gate to depth 6 |
| Jump Leads | Secondary (pistol) | S | 4-9 | depth 12 | gate to depth 6 |
| The Rat Man's Bag | Backpack | S | 4-9 | depth 12 | gate to depth 6 |
| The Butcher's Steel | Primary (melee) | S | 4-9 | depth 12 | gate to depth 6 |
| The Lollipop Lady's Sign | Secondary (melee) | S | 4-9 | depth 12 | gate to depth 6 |
| The Bookie's Pencil | Charm | S | 4-9 | depth 12 | gate to depth 6 |
| Nan's Cardigan | Armour | S | 4-9 | depth 12 | gate to depth 6 |
| The Dinner Lady's Ladle | Primary (melee) | S | 4-9 | depth 12 | gate to depth 6 |
| The Electrician's Tester | Secondary (pistol) | S | 4-9 | depth 12 | gate to depth 6 |
| The Gamekeeper's Flask | Charm | S | 4-8 | the Pleasure Park | |
| The Sparky's Gloves | Charm | S | 4-8 | the Retail Park | |

The build-defining ones open at depth 6 rather than 12, so a build can start forming in the town; their range runs
to 9, so they're kept to the end.

### Chase (tiers 7-9)

| Unique | Slot | Kind | Range | Found | Moves |
| --- | --- | --- | --- | --- | --- |
| The Quartermaster's Rifle | Primary (rifle) | S | 7-9 | the Quartermaster | scales with the boss's depth |
| Issue Webbing | Rig | S | 7-9 | the Quartermaster | scales with the boss's depth |
| The Van Keys | Charm | S | 6-9 | the Carpet Man at full strength | |
| The Manager's Pen | Charm | S | 7-9 | the Manager at full strength | |
| The Quartermaster's Ledger | Charm | S | 7-9 | the Quartermaster at full strength | |
| The Lorry's Load | Backpack | S | 7-9 | the convoy | |
| The Caretaker's Keys | Charm | S | 7-9 | depth 12 | |
| The Arsonist's Rig | Rig | S | 7-9 | depth 14 | |
| The Gritter's Keys | Charm | S | 7-9 | depth 14 | |
| The Rat Man's Overalls | Armour | S | 7-9 | depth 14 | |
| The Substation Key | Charm | S | 7-9 | depth 14 | |
| The Butcher's Apron | Armour | S | 7-9 | depth 14 | |
| The Gritter's Hopper | Armour | S | 6-9 | Ransacked Streets | |
| The Quartermaster's Manual | Charm | S | 7-9 | the Barracks | |
| A Blue Plaque | Charm | S | 6-9 | the Bank | |
| The Float | Backpack | S | 6-9 | the Shopping Centre | |
| The Vicar's Thermos | Charm | S | 6-9 | the Hospital | |
| The Sergeant's Whistle | Helmet | S | 7-9 | the Parade | |

### Outside the tiers

| Unique | Why |
| --- | --- |
| The Lorry Driver's Log | a paper: no tier, its rule is the whole of it; unchanged |

## 4. The gaps

Counted by band and slot after the moves above (paper aside):

| Slot | Levelling | Core | Chase |
| --- | --- | --- | --- |
| Primary | 1 | 3 | 1 |
| Secondary | 1 | 4 | **0** |
| Helmet | 2 | **0** | 1 |
| Armour | 2 | 2 | 3 |
| Rig | **0** | **0** | 2 |
| Backpack | 1 | 1 | 2 |
| Charm | 1 | 3 | 8 |

The holes: **a chase secondary**, **a core helmet**, **a levelling and a core rig**. Matt, 12 Oct: fill them with
new uniques; nothing existing moves across. Charm stays top-heavy (eight chase) as it is.

Two candidates a gap, Matt picks one (or neither) and the name and words are his to change. Each is a rule on the
hooks the game already has (statuses, meds, rounds, pace, searches), so none needs a new system:

| Gap | Slot | Band | Range | Candidate | Words |
| --- | --- | --- | --- | --- | --- |
| A | Secondary (pistol) | Chase | 7-9 | The Starting Pistol | Every gang opens on the secondary: its first shot at each of them lands, triple |
| A | Secondary (melee) | Chase | 7-9 | The Nightwatchman's Truncheon | Every status on one of them makes the rest hit it 15% harder |
| B | Helmet | Core | 4-7 | The Miner's Lamp | Every cache shows; searches take half as long |
| B | Helmet | Core | 4-7 | The Foundry Man's Visor | Burns, shocks and chills on you last half as long |
| C | Rig | Levelling | 1-4 | The Paramedic's Bumbag | Meds heal half again, and one is used for you under a third HP |
| C | Rig | Levelling | 1-4 | The Paper Round Satchel | Every kill puts a round back in the pouch |
| D | Rig | Core | 4-7 | The Plumber's Belt | Every status you put on them lasts twice as long |
| D | Rig | Core | 4-7 | The Bin Man's Tabard | Everything picked up is worth a quarter more; junk sells at full |

The pass gives each its affixes and art (a unique without its own art draws its base's, as now).

## 5. How it's checked (in the pass)

- **The probe**: a unique's share of finds by band at a tier-3, a tier-6 and a tier-9 find, against the weights.
- **The audit again**: every scaling unique at the top of its range against a plain base of that tier - inside a
  band either side of it (a unique is never the best stats by a mile, never a downgrade by a mile; the rule is the
  difference), the same figure the try-on reads.
- **A smoke**: a unique rolled at tiers 1, 5 and 9 takes its range's nearest tier, keeps its name, art and rule,
  and a higher copy reads ▲ over a lower.

## 6. Decided (Matt, 12 Oct)

1. Bands and weights 10 / 4 / 1 as first figures: **yes**.
2. The build-defining ones open at depth 6 (from 12) and run 4-9: **yes**.
3. The bosses' and pinnacles' scale with the boss's depth on the map: **yes**.
4. The gaps: **new uniques, nothing moved**. Open: which candidate per gap (section 4).

Built in the balance pass after the Poison Poacher playtest, before that pass's runs.
