# Stages - the spec (5 Nov 2026, Claude's draft; Matt's ten calls at the end)

Three stages on every campaign site. First figures, from the code at 0.13.3 (file:line refers to that tree), for a
fresh save. Matt's play sets the numbers, not a pass (CLAUDE.md, 2 Nov).

## Why (Matt, 5 Nov)

- "the answer to campaign length/balance is more stages per site - garden center 1/3"
- "finding a feed bag and gardening gloves in the allotments is great for the feel - thats what we need to replicate
  across the other zones"

## Matt's calls

1. Each site has three stages. A stage feels new through its own backdrop and the gear it drops.
2. 2/3 opens the next site. 3/3 is there for the grind.
3. A zone's head is his own fight, on his own backdrop: a gang first, then him. The heads' art exists.
4. Each site's finds are themed to the place. The stage steps their tier.
5. Matt starts a fresh game. SAVE_VERSION goes up, with no migration.

## 1. Today

**The sites** (data.gd:1892-1933, the row's line given). Whole HP and whole fire = gangs x a man's figure x
CAMPAIGN_HOSTILE (0.9 / 1.15 / 1.3 / 1.3 by zone, data.gd:3687): the site as fought. The x columns are the step from
the site before.

| Site (line) | Zone | Level | Gangs | HP | Fire | Tier | XP | Tins | Whole HP | Whole fire | x HP | x fire |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| The Allotments (1894) | Outskirts | 1 | 4 | 240 | 0.35 | 1 | 3 | 3 | 864 | 1.26 | - | - |
| The Garden Centre (1897) | Outskirts | 1 | 5 | 290 | 0.42 | 1 | 3 | 4 | 1,305 | 1.89 | 1.51 | 1.50 |
| Top Farm (1900) | Outskirts | 1 | 6 | 330 | 0.50 | 1 | 6 | 5 | 1,782 | 2.70 | 1.37 | 1.43 |
| Ransacked Streets (1903) | Estate | 1 | 6 | 330 | 0.50 | 2 | 5 | 6 | 2,277 | 3.45 | 1.28 | 1.28 |
| The Parade (1906-08) | Estate | 2 | 10 | 300 | 0.35 | 2 | 5 | 9 | 3,450 | 4.03 | 1.52 | 1.17 |
| The Retail Park (1911) | Estate | 3 | 14 | 315 | 0.61 | 2 | 10 | 14 | 5,072 | 9.82 | 1.47 | 2.44 |
| The Pleasure Park (1914-15) | Town | 4 | 12 | 520 | 0.65 | 3 | 17 | 22 | 8,112 | 10.14 | 1.60 | 1.03 |
| Shopping Centre (1918) | Town | 5 | 14 | 715 | 1.04 | 3 | 24 | 24 | 13,013 | 18.93 | 1.60 | 1.87 |
| The Bank (1921) | Town | 6 | 20 | 880 | 1.63 | 3 | 28 | 30 | 22,880 | 42.38 | 1.76 | 2.24 |
| The Services (1924) | City | 7 | 16 | 1,950 | 2.56 | 4 | 37 | 40 | 40,560 | 53.25 | 1.77 | 1.26 |
| The Hospital (1927) | City | 8 | 18 | 2,376 | 3.08 | 4 | 45 | 44 | 55,598 | 72.07 | 1.37 | 1.35 |
| The Barracks (1930) | City | 9 | 22 | 2,604 | 3.58 | 4 | 57 | 50 | 74,474 | 102.39 | 1.34 | 1.42 |

The steps run x1.28-1.77 in whole HP and x1.03-2.44 in fire. The worst are the Retail Park's fire, the Bank and the
Services. Allotments to Barracks: whole HP x86.2, whole fire x81.3.

**Level.** `lv_at(i, d) = max(1, i - 3 + d)` (sim.gd:7165-7166). It's the item level of a site's finds (the card's
"Item level", site_card.gd:657). A site's gate is `wear_of(level) - 1` (sim.gd:7141-7142). Wear is `min(2 x item
level - 2, max(item level, 16))` (items.gd:658-659), so the gates run 1, 1, 1, 1, 1, 3, 5, 7, 9, 11, 13, 15. Before
its first clear a site stays shut under its gate (sim.gd:7147-7148). It opens on the site before it in the zone
(sim.gd:7130-7136). A zone opens when the one before has every site cleared and its head down (sim.gd:6995-7023).

**Depth.** In the campaign, depth is always 1: `set_depth` caps it until the campaign's done (sim.gd:7486), and nobody
has set it since 15 Oct (bot.gd:1881-1884). Only signals go deeper, setting `depth[i]` for their run and putting it
back after (sim.gd:8730, 8742). Each depth multiplies HP and fire by 1 + DEPTH_HOSTILE 0.25 and XP and tins by
1 + DEPTH_REWARD 0.12. It adds DEPTH_DROP 0.03 to the drop chance and DEPTH_RARITY 0.10 to quality (data.gd:3688-3693;
sim.gd:7217-7222). Depth 1 alone takes CAMPAIGN_HOSTILE and the level tax: x1.04 a level from 3 levels past a site's
first clear, up to x1.5 (data.gd:3676-3681; sim.gd:9854-9858). From depth 2, once the campaign's done, the endgame
curve takes over (sim.gd:7235-7259). A signal's level is `lv_at(site, depth)`, and `depth_for_level` = `max(2, lv -
(i - 3))` (sim.gd:8653-8659). REACH_START is 10, "the campaign tops at 9" (data.gd:3844).

**The heads** (data.gd:1971-1984) are on Top Farm, the Retail Park, the Bank and the Barracks. Their HP multipliers on
the site's man are x5 / x6 / x12 / x6, and their fire x2 / x2 / x3.5 / x2.5 (sim.gd:7105-7108). A head is armed on his
site's card. He's free until his first fall (sim.gd:7051-7066). He comes out after the pool, with his own clock
(sim.gd:12772-12783). The backdrop is his den only while he's out (run_view.gd:787-789). He pays XP and tins x10
(sim.gd:13250-13256).

**XP.** A clear pays about 1.3 x gangs x XP a kill: the kills (sim.gd:13192) and CLEAR_BONUS 0.3 (data.gd:3692). The
curve is `xp_for_level` (data.gd:4146-4155). Level 10 takes 2,276 XP, 15 takes 6,292, 18 takes 9,963 and 20 takes
13,087. One clear of each site and each head is about 6,260 XP, level 14. Counted as in §3, the Quartermaster comes at
about 20 runs and level 17. Gate 4 wants him at level 18-22 (docs/design/balance_gates.md).

## 2. The stages

- **A stage is depth 1, 2 or 3 on a campaign site** (internal). On screen it reads "1/3", "2/3" or "3/3" with its
  level. `lv_at` is unchanged: the 1/3 is today's site level, the 2/3 one up, the 3/3 two up. A site's 1/3 shares the
  last site's 2/3 level, with harder fights.
- **What a stage changes.** A man's HP and fire grow x1.22 a stage (DEPTH_HOSTILE 0.25 to 0.22). XP and tins grow
  x1.12, drops +3 points, quality +10%, and crates 2 more searches (DEPTH_REWARD, DEPTH_DROP, DEPTH_RARITY,
  THIN_PER_DEPTH as they are; data.gd:3782). The gang count stays the site's. A stage has its own backdrop (§6), its
  finds' tier (§5), and its own foot line: Words.SITES has a line for each depth, and the card reads it by depth
  (words.gd:604-617; site_card.gd:361).
- **What opens.** Each stage needs the one before it and its own level gate (today's formula). **2/3 opens the next
  site.** On a zone's last site, 2/3 opens the head (§4), and the head opens the next zone, as today.
- **3/3 is for the grind.** It gives the site its "done" tick and gates nothing (open question 2). It's x1.03 over the
  next 1/3 and a level higher: a better grind, not a way round.
- **The signals start past the last 3/3.** The Barracks' 3/3 is level 11, so **REACH_START goes from 10 to 12**, and
  `depth_for_level`'s floor goes from 2 to 4. A signal on any site then lands at depth 4 or more (12 - 8 on the
  Barracks), so signals and stages never share a depth. DEEP_TIER_LEVELS (data.gd:4120), the curve and act two's
  levels stay: the first signal is two levels later, with T5 for one level. A level-12 signal's man on the Barracks has
  about 5,170 HP (3,200 x 1.16^3 x 0.69 x 1.5: data.gd:1942, 1950, 1931; sim.gd:7241-7252) and 4.75 fire. That's just
  over the 3/3's man (3,385, 4.65).

## 3. The numbers re-cut

Three rules. **(a)** The ends hold: the Allotments 1/3 is as Matt played it (864 / 1.26), and the Barracks 3/3 is
today's Barracks (74,474 / 102.4). **(b)** Each stage is x1.22 over the one before. **(c)** One site's 1/3 to the
next is a fixed R = (74,474 / 864 / 1.22^2)^(1/11) = **1.446** in HP, and (102.4 / 1.26 / 1.22^2)^(1/11) = **1.439**
in fire. So the path 1/3, 2/3, next 1/3 steps x1.22, then R / 1.22 = **x1.19** (HP) or **x1.18** (fire). A 3/3 sits
1.22^2 / R = x1.03 over the next 1/3. No step is over x1.22.

The gang counts are smoothed so a man's HP never jumps (open question 4): the Parade 10 to 9, the Retail Park 14 to
11, the Bank 20 to 16, the Streets 6 to 7, the Services 16 to 17, the Hospital 18 to 19. CAMPAIGN_HOSTILE is folded
in (all 1.0), so a TIERS row holds its 1/3 as fought. HP a man = whole HP / gangs. XP a clear = 1.3 x gangs x XP a
kill (below) x 1.12^(stage - 1).

| Site | Stage | Level | Gangs | HP a man | Fire a man | Whole HP | Whole fire | Tier | XP a clear |
|---|---|---|---|---|---|---|---|---|---|
| The Allotments | 1/3 | 1 | 4 | 216 | 0.32 | 864 | 1.3 | 1 | 10 |
| | 2/3 | 1 | 4 | 264 | 0.38 | 1,054 | 1.5 | 1 | 12 |
| | 3/3 | 1 | 4 | 321 | 0.47 | 1,286 | 1.9 | 1 (+2) | 13 |
| The Garden Centre | 1/3 | 1 | 5 | 250 | 0.36 | 1,250 | 1.8 | 1 | 13 |
| | 2/3 | 1 | 5 | 305 | 0.44 | 1,524 | 2.2 | 1 | 15 |
| | 3/3 | 1 | 5 | 372 | 0.54 | 1,860 | 2.7 | 1 (+2) | 16 |
| Top Farm | 1/3 | 1 | 6 | 301 | 0.43 | 1,807 | 2.6 | 1 | 31 |
| | 2/3 | 1 | 6 | 367 | 0.53 | 2,205 | 3.2 | 1 | 35 |
| | 3/3 | 2 | 6 | 448 | 0.65 | 2,690 | 3.9 | 1 (+2) | 39 |
| Ransacked Streets | 1/3 | 1 | 7 | 373 | 0.54 | 2,614 | 3.8 | 2 | 36 |
| | 2/3 | 2 | 7 | 456 | 0.65 | 3,189 | 4.6 | 2 | 41 |
| | 3/3 | 3 | 7 | 556 | 0.80 | 3,890 | 5.6 | 2 (+3) | 46 |
| The Parade | 1/3 | 2 | 9 | 420 | 0.60 | 3,780 | 5.4 | 2 | 47 |
| | 2/3 | 3 | 9 | 512 | 0.73 | 4,612 | 6.6 | 2 | 52 |
| | 3/3 | 4 | 9 | 625 | 0.89 | 5,627 | 8.0 | 2 (+3) | 59 |
| The Retail Park | 1/3 | 3 | 11 | 497 | 0.71 | 5,467 | 7.8 | 2 | 100 |
| | 2/3 | 4 | 11 | 606 | 0.86 | 6,670 | 9.5 | 2 | 112 |
| | 3/3 | 5 | 11 | 740 | 1.05 | 8,138 | 11.6 | 2 (+3) | 126 |
| The Pleasure Park | 1/3 | 4 | 12 | 659 | 0.93 | 7,907 | 11.2 | 3 | 187 |
| | 2/3 | 5 | 12 | 804 | 1.14 | 9,647 | 13.6 | 3 | 210 |
| | 3/3 | 6 | 12 | 981 | 1.39 | 11,769 | 16.6 | 3 (+4) | 235 |
| Shopping Centre | 1/3 | 5 | 14 | 817 | 1.15 | 11,436 | 16.1 | 3 | 309 |
| | 2/3 | 6 | 14 | 997 | 1.40 | 13,952 | 19.6 | 3 | 347 |
| | 3/3 | 7 | 14 | 1,216 | 1.71 | 17,022 | 23.9 | 3 (+4) | 388 |
| The Bank | 1/3 | 6 | 16 | 1,034 | 1.44 | 16,540 | 23.1 | 3 | 416 |
| | 2/3 | 7 | 16 | 1,261 | 1.76 | 20,179 | 28.2 | 3 | 466 |
| | 3/3 | 8 | 16 | 1,539 | 2.15 | 24,618 | 34.4 | 3 (+4) | 522 |
| The Services | 1/3 | 7 | 17 | 1,407 | 1.96 | 23,921 | 33.2 | 4 | 575 |
| | 2/3 | 8 | 17 | 1,717 | 2.39 | 29,184 | 40.6 | 4 | 644 |
| | 3/3 | 9 | 17 | 2,094 | 2.91 | 35,604 | 49.5 | 4 | 721 |
| The Hospital | 1/3 | 8 | 19 | 1,821 | 2.52 | 34,597 | 47.8 | 4 | 790 |
| | 2/3 | 9 | 19 | 2,221 | 3.07 | 42,208 | 58.3 | 4 | 885 |
| | 3/3 | 10 | 19 | 2,710 | 3.75 | 51,494 | 71.2 | 4 (+5) | 991 |
| The Barracks | 1/3 | 9 | 22 | 2,274 | 3.13 | 50,037 | 68.8 | 4 | 1,144 |
| | 2/3 | 10 | 22 | 2,775 | 3.81 | 61,045 | 83.9 | 4 (+5) | 1,281 |
| | 3/3 | 11 | 22 | 3,385 | 4.65 | 74,474 | 102.4 | 4 (+5) | 1,435 |

For example, the Shopping Centre's 1/3 is 864 x 1.446^7 = 11,436 whole HP, a man 11,436 / 14 = 817. That's x1.19
over the Pleasure Park's 2/3. Today it's x1.60, the wall Matt hit on 4 Nov. "(+N)" is the tier for a quarter of a
3/3's finds (§5). `loot_cap` lets T5 through only from level 10 (sim.gd:7203-7204), so the Services' 3/3 stays T4. Tins
a kill stay as they are.

**XP: the length.** The cheapest path to the Quartermaster is 24 stages and four heads: 28 runs, against 16 today. At
today's XP a kill, that reaches level 20 with no gate ever binding, and any grind goes past gate 4's band. **Proposed:
XP a kill x0.7**: 2, 2, 4, 4, 4, 7, 12, 17, 20, 26, 32, 40 (was 3, 3, 6, 5, 5, 10, 17, 24, 28, 37, 45, 57). The curve
and its taper are unchanged. The read clears stages in order. Under a gate, it grinds the best open stage, with the
over-level share applied (data.gd:4105-4107; sim.gd:6271-6281). It leaves out patrols, failed runs and nights.

| Point reached | Runs (stages and heads) | Level |
|---|---|---|
| The Gamekeeper down | 7 | 2 |
| The Carpet Man down | 15 | 6 |
| The Manager down | 25 | 12 |
| The Quartermaster down | 33 (today about 20) | 18 (today about 17) |

Five of the 33 runs are grinds the gates force. Each is a second 1/3 before the 2/3's gate, on the Retail Park, the
Pleasure Park, the Shopping Centre, the Bank and the Hospital. That's about 1.65 times today's runs. The Radio, at 3.3
h in Matt's play, would come at about 5-5.5 h by runs (the early stages' runs are shorter). That's the longer campaign
Matt asked for, past act two's 4 h target (open question 6). Nothing else in Data's XP moves.

## 4. The heads

Each head is his own fight on his zone's last site. His gang comes first: half the site's gangs, at its 3/3 man. Then
he comes out, at his BOSSES multipliers on that man. **His den is the backdrop from the first man.** **His gate is
that site's 2/3**, and his level is its 3/3. His fall opens the next zone and his room. He's free the first time, then
costs notes, as today.

| Head | Gate | Level | His gang | Him (HP / fire) | Today (HP / fire, after the whole site) |
|---|---|---|---|---|---|
| The Gamekeeper | Top Farm 2/3 | 2 | 3 x 448 HP, 0.65 | 2,240 / 1.30 | 1,485 / 0.90, after 6 |
| The Carpet Man | The Retail Park 2/3 | 5 | 5 x 740, 1.05 | 4,440 / 2.10 | 2,172 / 1.40, after 14 |
| The Manager | The Bank 2/3 | 8 | 8 x 1,539, 2.15 | 18,468 / 7.53 | 13,728 / 7.42, after 20 |
| The Quartermaster | The Barracks 2/3 | 11 | 11 x 3,385, 4.65 | 20,310 / 11.63 | 20,310 / 11.62, after 22 |

Him = the 3/3 man x the BOSSES figures (data.gd:1972-1982). His whole fight is lighter than today's (the
Quartermaster's 57,545 HP against 94,784), but it comes one step past the 2/3.

**His art exists for all four:**

| Head | Den (art/fight_boss/) | Figures (art/fight/) | Portrait (art/people/) |
|---|---|---|---|
| The Gamekeeper | the_gamekeeper_plate.png, the_gamekeeper_cover.png | head_the_gamekeeper_{stand,fire,down}.png | the_gamekeeper.png |
| The Carpet Man | the_carpet_man_plate.png, the_carpet_man_cover.png | head_the_carpet_man_{stand,fire,down}.png | the_carpet_man.png |
| The Manager | the_manager_plate.png, the_manager_cover.png | head_the_manager_{stand,fire,down}.png | the_manager.png |
| The Quartermaster | the_quartermaster_plate.png, the_quartermaster_cover.png | head_the_quartermaster_{stand,fire,down}.png | the_quartermaster.png |

His gang uses the zone's men: art/fight/gang_<zone>_{a,b}_{stand,fire,down}.png for the_outskirts, the_estate,
the_town and the_city (RunView.ZONE_KEYS, run_view.gd:47).

## 5. Themed finds

**The rule.** Each TIERS row gets a `theme` list. **60% of a site's plain gear finds roll from it** (THEME_SHARE 0.6),
taking the list's bases for the slot drawn at the stage's tiers. The rest, and any slot with nothing on the list in
reach, roll as today. The site's own bases still come first, a third of the time (Items.roll, items.gd:16-50;
data.gd:1616), and they're on its list. Another site's own are never on one (items.gd:180-191). Uniques, set pieces,
papers, meds, rounds and the slot weights are untouched.

**The stage steps the tier.** 1/3 and 2/3 roll at the zone's tier, T1 to T4 (data.gd:4118), weighted as today: own
0.5, under 0.3, lower 0.2 (items.gd:118-140; data.gd:1083-1085). At 3/3, **a quarter of finds roll one tier up**
(STAGE_TIER_UP 0.25), within `loot_cap`. The item level rises with the stage. So do quality and drops.

| Site (zone tier, 3/3's) | On its list now (tier) | Gaps: new bases (slot, tier) |
|---|---|---|
| The Allotments (1, 2) | Billhook 1, Lump hammer 1, Knife 1, Beekeeper's hat 1, Spraying overalls 1, Gardening gloves 1, Gardening apron 1, Feed sack 1, Box of matches 1, Rabbit's foot 1; Pipe wrench 2, Screwdriver 2, Tartan shopper 2 | Garden fork (Primary 2), Strimmer visor (Helmet 2), Donkey jacket (Armour 2), Rose gauntlets (Gloves 2), Tool belt (Rig 2) |
| The Garden Centre (1, 2) | Nail gun 1, Bolt gun 1, Billhook 1, Knife 1, Hard hat 1, Beekeeper's hat 1, Spraying overalls 1, Gardening gloves 1, Work gloves 1, Gardening apron 1, Feed sack 1, Lucky penny 1; Speargun 2 (the aquatics end), Screwdriver 2, Rigger gloves 2, Lifeguard's vest 2, Tartan shopper 2, Old spark plug 2 | Strimmer visor (Helmet 2, shared), Staff fleece (Armour 2) |
| Top Farm (1, 2) | Farmer's shotgun 1, Four-ten 1, Bolt gun 1, Billhook 1, Knife 1, Padded jacket 1, Spraying overalls 1, Work gloves 1, Woolly gloves 1, Body warmer 1, Feed sack 1, Rabbit's foot 1; Goose gun 2, Over-and-under 2, Old .303 2, Lever-action rifle 2, Rigger gloves 2, Tweed waistcoat 2, Horseshoe nail 2 | Flat cap (Helmet 1), Waxed coat (Armour 2), Humane killer (Secondary 2) |
| Ransacked Streets (2, 3) | Pipe shotgun 1, Carrier bags 1 (its own); Nail gun 1, Spiked bat 1, Air pistol 1, Cycle helmet 1, Bum bag 1, Body warmer 1, School bag 1, Lucky penny 1; Bike chain 2, Pipe wrench 2, Knuckle duster 2, Bike lock 2, Scrum cap 2, Motorbike leathers 2, Cycling mitts 2, Old spark plug 2; Slam-fire shotgun 3, Converted air rifle 3, Zip gun 3, Cosh 3, Hatchet 3, Welder's mask 3, Leather gloves 3, Dumpy bag 3 | Lined hoodie (Armour 3) |
| The Parade (2, 3) | Sawn-off 1, Holdall 2 (its own); Pocket pistol 1, Derringer 1, Stab vest 1, Bum bag 1, Lucky penny 1; Old revolver 2, Service pistol 2, Knuckle duster 2, Slash-proof jacket 2, Driving gloves 2, St Christopher 2; Meat cleaver 3 (the chippy), Big revolver 3, Target pistol 3, Cosh 3, Leather gloves 3, Door staff vest 3, Daysack 3, Barber's razor 3, Gold tooth 3, Wedding ring 3 | Delivery rider's helmet (Helmet 2), Sheepskin coat (Armour 3) |
| The Retail Park (2, 3) | Garage-built rifle 2 (its own); Nail gun 1, Bolt gun 1, Hard hat 1, Work gloves 1; Crossbow 2, Speargun 2, Machete 2, Pipe wrench 2, Screwdriver 2, Caving helmet 2, Motorbike leathers 2, Rigger gloves 2, Hiking pack 2, Old spark plug 2; Compound bow 3, Converted air rifle 3, Fire axe 3, Hatchet 3, Welder's mask 3, Foundry coat 3, Goalkeeper gloves 3, Shooting gloves 3, Dumpy bag 3 | Tool belt (Rig 2, shared), Hi-vis tabard (Rig 3) |
| The Pleasure Park (3, 4) | Fishing vest 2, Framed pack 3 (its own); Pump shotgun 2, Catapult 2, Lifeguard's vest 2; Riot shotgun 3, Semi-auto shotgun 3, Converted air rifle 3 (the shooting gallery), Target pistol 3, Goalkeeper gloves 3; Paintball gun 4, Pocket watch 4 | Go-kart helmet (Helmet 3), Mascot suit (Armour 4), Arcade token (Charm 3) |
| Shopping Centre (3, 4) | Tactical pistol 3, Ballistic vest 3 (its own); Security guard's carbine 3, Extendable baton 3, Comms headset 3, Visored helmet 3, Leather gloves 3, Door staff vest 3, Daysack 3, Wedding ring 3; Courier's SMG 4, Polymer pistol 4, Bump helmet 4, Low-profile vest 4, Tactical gloves 4, Messenger bag 4, Pocket watch 4 ("nobody wanted the watches") | none |
| The Bank (3, 4) | Compact pistol 2, Light plates 3 (its own); Machine pistol 3, Police carbine 3, Visored helmet 3, Comms headset 3, Leather gloves 3, Wedding ring 3; Courier's SMG 4 (the cash vans), Police revolver 4, Bump helmet 4, Low-profile vest 4, Tactical gloves 4, Pocket watch 4 | Coin bag (Backpack 3), Cash-in-transit vest (Rig 4), Branch key (Charm 4) |
| The Services (4, 5) | Cargo frame 4 (its own); Courier's SMG 4, Workshop carbine 4, Police revolver 4, Bump helmet 4, Cold-store parka 4 (the reefer trailers), Low-profile vest 4, Racing gloves 4, Quick-release rig 4, Messenger bag 4, Pocket watch 4; Armoured car gun 5, Belt-fed SMG 5, Automatic pistol 5, Folding PDW 5, Thermal headset 5, Hazmat suit 5, Load carrier 5, Mule pack 5, Casino chip 5 (the fruit machines) | none |
| The Hospital (4, 5) | Medic's harness 4 (its own); Fire axe 3, Paramedic's rig 2, Station helmet, visored 4, Low-profile vest 4, Tactical gloves 4, Messenger bag 4; Respirator helmet 5, Hazmat suit 5, Cut-resistant gloves 5 | Bone saw (Primary 4), Scalpel (Secondary 4), Hospital wristband (Charm 4), Grab bag (Backpack 5) |
| The Barracks (4, 5) | Section gun 4, Stab plates 4 (its own); Scoped .308 4, Self-loading rifle 4, Army SMG 4, Bayonet on a stick 4, Army helmet 3, Army plates 3, Webbing 3, Chest rig 3, Bergen 3, Tactical gloves 4, Dog tag 4; Regimental rifle 5, Sniper rifle 5, Belt-fed SMG 5, Automatic pistol 5, Thermal headset 5, Full plate carrier 5, Plate rig 5, Sniper's drag bag 5, Armourer's gloves 5 | Cap badge (Charm 5) |

The bases are from data.gd (Primary 309-541, Secondary 543-651, Helmet 657-688, Armour 691-728, Gloves 733-759, Rig
764-793, Backpack 799-832, Charm 837-865). "Own" means a TIERS row's "only" list. That's **22 new bases**. They go
through the language pass, then the art manifest. Their stats are drafted by role, against their tier's neighbours.

## 6. The art

**Today** a backdrop is a plate (the scene) and a cover (the wall the runner ducks behind). The run loads
`<key>_plate` and `<key>_cover` (run_view.gd:545-561). It reads art/fight_new/<site>_plate.png (744 wide) first,
art/fight_walls/<site>_cover.png (744 x 256), and the older art/fight/<site>_{plate,cover}.png as the fallback
(run_view.gd:30-37). All 12 sites have all three: the_allotments, the_garden_centre, top_farm, ransacked_streets,
the_parade, the_retail_park, the_pleasure_park, shopping_centre, the_bank, the_services, the_hospital, the_barracks.

**For the stages**, the keys are `<site>_2` and `<site>_3`. The 1/3 keeps today's pair, and a missing pair falls back
to the site's. **Test art first** (CLAUDE.md): every stage ships on today's backdrop until Matt has read the slice.
Then the manifest goes out by art.flag (docs/art/pixellab_lessons.md, `tools/art_lint.py`).

**The 24 new backdrops** are one plate each (the wall is open question 7). The briefs come from Words.SITES
(words.gd:609-727):

| Site | 2/3 | 3/3 |
|---|---|---|
| The Allotments | Further in: water butts tipped over, shed doors off | A dug plot behind pallet fences, a potato bed someone guards |
| The Garden Centre | The cafe stripped to its "scones" sign | The glasshouse walled with compost bags |
| Top Farm | The barn, stacked with feed nobody's feeding | The farmhouse, the gun cabinet open and empty |
| Ransacked Streets | A house with the copper chased out of its walls | A back street, a car on bricks with a child seat |
| The Parade | The bookmaker's, its shutter the only one down | The launderette someone lives in |
| The Retail Park | The DIY shed's aisles, where the nail guns came from | The supermarket, its freezers dead |
| The Pleasure Park | The arcade, lit off a generator | The log flume as a guarded reservoir |
| Shopping Centre | The jeweller's done over, watches left on the floor | The upper floor's camp in the children's clothes shop |
| The Bank | Behind the counter, the crew as staff | The back office, its tills on a generator |
| The Services | The lorry park: trailers as houses, cabs as shops | The forecourt and the tanks they fight over |
| The Hospital | A&E as the gate, a triage desk | The pharmacy, emptied by rota |
| The Barracks | The armoury's hatch, the Quartermaster's signing book | The parade square at drill |

The 22 new bases' pictures go on the same manifest. Until then each borrows a neighbour's picture through ART_AS
(data.gd:2090).

## 7. The UI

Mockups go on the canvas at 1920 x 1080, rendered and checked first, and need Matt's word before the build (CLAUDE.md).

- **The site card** gets a picker under the picture: "1/3", "2/3", "3/3", with the picked stage's level beside it
  ("2/3 · level 3"). It opens on the furthest open stage, and Set off and "Run it ×10" run the picked one. A shut stage
  greys with its reason in the card's words: "After 1/3" or "Opens at level 7" (site_card.gd:396-398). On a zone's last
  site a fourth button, "Head", replaces the Gang/Head toggle and the foot's button (site_card.gd:410-446). That's the
  0.12.2 playtest's item 1, one control. With Head picked, the card shows his den, his gang and him.
- **The Map's pin** reads "The Allotments · 2/3", the furthest stage cleared, in the done colour at 3/3. A shut site
  shows its name only (map_view.gd:428-436). A site that 2/3 has just opened reads "· New" until first picked (a saved
  mark). It's on the label, not a new draw call (map_view.gd:469-485).
- **Words** (the language pass): "1/3" as a figure on buttons and pins; "stage" in sentences, as a new glossary row
  ("stage. Not: depth, level, part"; open question 8); gates as "After Top Farm 2/3".
- Smoke fit checks: the picker and Head at both window sizes, "· New", and the longest pin ("The Pleasure Park · 3/3").

## 8. What else moves

- **The sim.** `set_depth` allows up to min(3, the furthest stage cleared + 1) at any time (sim.gd:7486).
  `tier_open`, `zone_complete` and `level_gated` read stages. `clear_level` is keyed by stage, so the level tax never
  hits a stage you haven't cleared (sim.gd:9854). Some guards: a signal's clear doesn't advance a site's stages
  (sim.gd:13797-13805). Stages give no Map points or `best_dig` (13806-13809). Set pieces start from depth 4, not 2
  (13527). The endgame curve starts from depth 4, or after the campaign the Allotments' 2/3 man jumps from 264 to about
  410 HP (7235). The head's fight is a run at the 3/3, half the gangs plus him, with his den as the scene from the start
  (run_view.gd:789). The shelf and the gamble read stage levels, so they rise a stage at a time (sim.gd:6283-6296).
  That's intended.
- **The bot** (tests/bot.gd:160, 197, 1026-1034, 1732-1790): it takes the next uncleared stage at FIRST odds, farms
  its highest cleared stage at PUSH, and takes the head after the 2/3. The `_climb` note (1881-1884) changes.
- **The smoke** (tests/smoke.gd). `lv_at` (129) holds, and so do the gates by formula (25366-25385), now per stage.
  These change: the story floor `lv_at(site, 2)` becomes 4 (16279); the gated pin (25591); the REACH_START reads
  (15442-15846). New checks: x1.22 a stage; 2/3 opens the next site or the head; 3/3 opens nothing; no signal under
  depth 4; no Map point or set piece from a stage; stage figures unchanged after the campaign; a quarter one tier up at
  3/3; the theme share; the den from the first man; the fits in §7.
- **The balance gates** doc (no pass: CLAUDE.md, 2 Nov): gate 1 is the Manager after the Bank's 2/3. Gate 4 stays at
  18-22. Gates 9 and 10 read "every cleared stage" and "at 1/3".
- **The tutorial**: the garages are never on the Map (docs/design/tutorial.md:15-17). Nothing moves.
- **Story and Kev.** STORY_BEATS' signals (data.gd:3870-3874) follow the new floor. Kev's lines key on the heads
  (words.gd:384-389) and hold. The sites' "cleared" lines (words.gd:617-727) move to a site's first 3/3. The Retail
  Park's "the road to the Town is open" moves to the Carpet Man's fall, or the language pass rewords it. The first gun
  stays on the Garden Centre's first clear (sim.gd:13416, 13822), and so does the slice's win (13810).
  tier_guide.gd:296's hard-coded "signals from level 10" should read REACH_START.
- **SAVE_VERSION** goes from 25 to 26 (scripts/ui/main.gd:54). **VERSION** becomes 0.14.0, a new milestone
  (scripts/ui/menu.gd:181).

## 9. The build

One release, 0.14.0, for a fresh game. Each phase is a commit with the smoke green and a reviewer on the diff, and the
three-stage review runs at the end (CLAUDE.md).

1. **Sim and numbers** (builder A): the data in §2-4, the rules and guards in §8, the head's fight, the bot,
   SAVE_VERSION.
2. **UI** (builder B; canvas and Matt's word first): the picker, Head, the pins, the words, and the stage backdrop key
   with its fallback.
3. **Themed finds** (builder C): `theme`, THEME_SHARE, STAGE_TIER_UP, and the 22 bases after the language pass.
4. **Art**: 24 plates and 22 item pictures by art.flag, after Matt reads the slice on test art.

Phases 1-3 are each itemisation-sized: about 1 h to build and 1-1.5 h to review, in parallel (B and C on A's names).
About a day.

**Open questions for Matt (Claude's recommendation first):**

1. The head's gate: the last site's 2/3 (3/3 stays optional), or its 3/3.
2. 3/3: a "done" tick only, or part of a zone's completion.
3. REACH_START 12 with the endgame's levels kept, or the whole endgame up two levels.
4. Gang counts smoothed (no man's HP jumps), or today's kept (the Bank's 20, the Parade's 10).
5. XP a kill x0.7 (the Quartermaster at 18 on the cheapest path), or unchanged (20 with no grind).
6. The Radio at about 5-5.5 h, not act two's 4 h: take it as the longer campaign, or trim from his play.
7. A new plate per stage on the site's wall (24 images), or a plate and a wall each (48).
8. "Stage" in sentences and "1/3" on screen, or the figure alone everywhere.
9. A themed share of 60%, with a quarter one tier up at 3/3.
10. All 22 new bases in this release, on borrowed pictures until the art, or the Outskirts' first.

## As built (0.14.0, 5 Nov)

Matt's calls: A (the picker a segmented row), XP a kill x0.7, the Radio at 5-5.5 h; the other open calls took Claude's
pick (the first each). Built by three builders (sim, UI, finds), reviewed, the language pass applied. Differences from
the draft above:

- **The heads' fights** form at their gate stage, the 2/3: his gang, floor(gangs/2), at the 2/3 man; him at his BOSSES
  figures on the site's **1/3** man (the draft had both at the 3/3). The 3/3 version made the Gamekeeper 0% for every
  class at levels 1-3 and the bot stuck on him at level 7; now the bot downs him at run 7, level 3. Him: the
  Gamekeeper 1,506 HP / 0.87 fire, the Carpet Man 2,982 / 1.41, the Manager 12,404 / 5.05, the Quartermaster 13,646 /
  7.82. His fight reads stage 0 (no 3/3 tier-up); his site's list applies.
- **New bases: 24** (the draft counted 22). Renamed by the language pass: "Security van vest" (was Cash-in-transit),
  "Bank bag" (Coin bag), "Joiner's apron" (Tool belt). Each borrows a neighbour's picture (ART_AS) till the art manifest.
- **The sites' "cleared" lines** come at a site's first 2/3 (the stage that opens the next), not its 3/3.
- **Kev's wagers** are offered on any stage's first clear and on a head's fight.
- **"Run it ×N"** is shut on a stage not yet cleared.
- Loose uniques rise with a stage's depth (a 3/3 rolls them at the cap): kept, as a 3/3's reward.
- The town's sixth place is "The print works" (the order's "The Mint" keeps its name).
