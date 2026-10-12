# The Outskirts (12 Oct, built the same day; numbers in the pass)

Matt, 12 Oct: a new zone and three sites before the first stage, so the order runs the Outskirts, the Estate, the
Town, the City. On screen everything moves up one, and the map moves to the Radio as a menu, since the Radio is
where the runs' modifiers already live. One of the three sites is a farm; the other two were mine to pick.

## The zone and its sites

| Site | Pool | HP | Fire | Finds | Loot tier | XP | Cash | Leans to | Its shape |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| The Allotments | 4 | 120 | 0.2 | 0.35 | 1 | 1 | 3 | melee | many and thin |
| The Garden Centre | 5 | 150 | 0.25 | 0.4 | 1 | 1 | 4 | improvised | meds ×1.5 |
| Top Farm | 6 | 170 | 0.3 | 0.4 | 1 | 2 | 5 | shotguns | ammo ×1.5 |

- **Gentler than the Streets** (pool 6, HP 200, fire 0.4). It's the first runs: the Allotments are open, and the
  rest follow as each site before is cleared.
- **No crew and no head.** The zone is done once its three sites are cleared, and that opens the Estate.
- **What they fire:** the plain, plus a tenth as poison (the weedkiller). Their resists rise with depth like
  everyone's. No salvage, no site uniques, no pinnacle.
- **Weather:** the Estate's odds.
- **The tab's sky:** a green-grey of its own.
- **Ambient sound:** the Estate's, until there's one of its own.

### Levels

- A site's level is now its place counted from the Streets, plus its depth: `Sim.lv_at(i, d) = max(1, i - 3 + d)`.
- So every old site keeps the level it had: the Streets at depth 1 is level 1, the Barracks at depth 1 is level 9.
- The Outskirts sit at level 1 until their depth climbs past their place.
- Loot tiers, item levels and the deep tiers all read this, so the Estate onwards is unchanged.

### The depths that count are from the Streets

The Outskirts' ladders exist, but they're the gentle ones, so they don't count towards any of these:

- the map's points;
- the deepest dig (the wall's score);
- `deepest()` (the loose uniques' gates, the mate's stock);
- `deepest_dug()` (the Yard's depth-6 and depth-9 columns).

Without that, the Allotments at depth 6 would open what the Streets at depth 6 used to.

## The numbering

Every site's index moved up three and every zone's up one:

- the Streets is now 3, the Bank 8 (`Data.BANK`), the Services 9 (`Data.CONVOY_TIER`) and the Barracks 11;
- the Estate is now zone 1, the Town 2 and the City 3.

The tables moved with them: the bosses' zones and sites, the uniques' sites and pinnacles, the words' zones, and the
per-zone lists (site uniques' depth, pinnacle depth, zone types, salvage, weather). "The slice's win" (the Retail
Park) and the way out's time both count from the Streets.

### Saves

- **A save from before** (nine sites, `sites_v` 1) is moved on load by `Sim._shift_sites`:
  - every per-site list gets the Outskirts' three at the front, counted as cleared at depth 1, since that runner was
    already past them;
  - every per-zone list gets the Outskirts at the front;
  - every stored site index moves up three: the best tier, the auto-run, the mission out with its head and its
    queue, the last report, the deepest dig, and what the yard has seen.
- **Saves now carry `sites_v` 2,** and every record line carries `"sv": 2`.
- **The playtest read** (`tools/playtest_summary.gd`) moves an old save the same way, and moves the site and zone of
  record lines that have no `sv`. Matt's Poison Poacher save and record read as they did.

## On screen

- **Runs:** the zone row is the four zones, the Outskirts first, with no map tab. The screen opens on the furthest
  zone that's open, not the Outskirts every launch.
- **The Radio:**
  - Two buttons sit at the band's right: **The air** (the sites and their words, as before) and **The map** (the
    endgame's tree, the room's whole height; locked until the campaign's done).
  - Its site list is twelve rows now, so each row is shorter: the name and depth on the first line, the words' pips
    and the pay on the second.
- **New words:**
  - the three sites' depth lines and their cleared lines;
  - the first-run nudge ("The Allotments are out past the ring road");
  - the move's line ("Start at the allotments");
  - the campaign's line ("The edge of it, the estate, the town, the city").

## Art

`tools/pixellab_places_outskirts_manifest.json`: four jobs, the zone's tab and the three sites' bands, at
688×296 like the other places (`art/places/the_outskirts.png`, `the_allotments.png`, `the_garden_centre.png`,
`top_farm.png`). The zone uses `the_estate.png` as its style image and the sites use `ransacked_streets.png`. Until
they're drawn, the drawn skyline shows.

## For the pass

- **The bank hour, the keystone and the capstone hours** all now include the Outskirts' time. They're timing gates
  that the playtests calibrate anyway.
- **The Outskirts' numbers** are first figures. The bot clears them in about ten runs: in the smoke, the slice's win
  came after 12-13 runs, against 3 before.
