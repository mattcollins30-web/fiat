# Fiat full review, 30 Oct (0.10.0, c5e3c61)

**How it was done**
- Six reviewers each took one area: the sim core, items and data, the UI, the bot and balance harness, test quality, and structure.
- Each reviewer worked read-only and proved its findings with headless probes.
- A seventh agent then tried to refute 30 of the headline findings:
  - 23 confirmed
  - 6 partly true
  - 1 refuted (the odds ignoring wagers: that's intended, and the wagers panel says so)

## Verdict on the code

It isn't broken, but it isn't tight. It works, and each change has been added on top of the last instead of fitted into it.

**What holds:**
- 4,142 smoke checks
- the fixed-seed fingerprint
- the save round trip, which covers everything added this week
- the fight loop, magazines, reloads and cures
- the new screens: one consistent pattern, with no leaks and no double connections

**What doesn't:** nearly every system added this week brought its own cache, guard or copy of an existing rule. The three worst knots:

1. **About 28 caches**, each cleared by hand, each with its own key. Two of today's bugs (T1, T2) are stale caches.
2. **"Another class's odds" is worked out three ways**: on the Radio, on the Expeditions board, and in the bot. The three have already drifted apart.
3. **Rig packing is split between the game and the bot.** Two commits in two days each patched the other's stall.

## Bugs, checked

### Player-facing

| ID | What | Where |
|---|---|---|
| S1 | Buy ammo or meds and sell them straight back at a profit (Buyer's market, or 50%+ sell bonus) | sim.gd ammo_price / med_price / clinic_price vs sell_price |
| S2 | Fence shelf resale at a profit late on: the buy discount is capped, the sell bonus isn't | sim.gd price() vs sell_price |
| S3 | Save and load during a repeat: the runner's earlier wounds are healed | sim.gd _rest_off_wounds |
| S4 | An expedition lead's XP gives no training points, passes the level cap and feeds no paragon | sim.gd ~15516 |
| S5 | An expedition sent while a run is out gives its lead 0 XP | sim.gd _exp_xp_run, exp_send_block |
| S6 | A lead's XP is cut by the selected runner's level, not the lead's own | sim.gd _exp_xp_run |
| T1 | Slot a skill: the site keeps showing its old odds | sim.gd _odds_key_common (no skill slots) |
| T2 | The Radio's crew row keeps stale odds for a benched class | sim.gd signal_odds_class / _crew_now |
| U1 | "Run it ×5" stays on "Reading the odds" while the runner's hurt | sim.gd odds key memo vs repeat_read |
| U2 | The repeat button's state can disagree with the press | missions.gd _repeat_lay in the paint scope |
| U3 | A refused repeat always says "The runner is away" | sim.gd ~8709 |
| U4 | "Swap, parts and all" lit with no stash room; pressing it does nothing | armoury.gd:316 |
| I1 | Set pieces get another base's mounts (the Issue rifle with a shotgun's) | items.gd roll_set_piece |
| I2 | Uniques can exceed their socket cap; improvised uniques miss their extra socket | items.gd roll / roll_unique |
| I3 | An expedition's set-piece reward gets a random item level | items.gd roll_set_piece (level −1) |
| I4 | A secondary's conversion chip shows (Knife 40% bleed) but never applies | sim.gd _conversion_raw, item_head |
| I5 | Cards read "+20% first_pct" | data.gd: no def for first_pct |
| I6 | Auto-equip can wear a worse piece when the parts-and-all swap is refused, and can overfill the stash | sim.gd equip_best |
| S7 | Kev's "+25% gang damage" doesn't reach the head | sim.gd _wagers_on |
| S9 | A repeat packs cures for the front, not the site it's farming | sim.gd _repeat_go → pack_rig |
| T3 | The Quartermaster's Manual does nothing: its rule was orphaned by the web rework | sim.gd affinity / _tops_open |
| T4 | The rig can be changed between repeat runs (only the run-out check guards it) | sim.gd take / leave, med_cards.gd |

### UI oddities

- Expedition and hands panels use a 3-second ask-twice, not the 4 seconds you set.
- "…and Loader leave for good" has no singular form.
- Repeat times over an hour read "143:12".
- "Runs 1–1 not shown" for a single hidden run.
- "RoF" against "rate of fire".
- A spaced hyphen in the held-up log line.
- The top bar says "Resting" between repeat runs, not "Away".
- An expedition report with many finds can silently drop the tins and tokens chips.
- A hidden cargo slot still counts as taken.
- CLAUDE.md still says the version is 0.9.1.

### Balance harness: these change what goes red

| ID | What |
|---|---|
| H3 | End-of-read figures come from whichever class is out, not the read's build |
| H4 | A Poacher read undoes its first wall swap on the very next step |
| H6 | With two reads per build, the summary's Walls, Repeats, Expeditions, bases-worn and damage rows show read 1 only |
| H7 | Repeats overrun the parity read's 4 h spell |
| H8 | The gauntlet never treats wounds or slots skills between places |
| H1 | Parity reads are killed at 60 min with no line (partly; this was raised before and is still open) |
| H2 | The bot may sit out the clock after a site's cleared (partly) |

Also:
- Gate 16 ignores builds that never cleared a site.
- The gauntlet's second read reuses read 1's save.
- `wagers_on` is never set, so no balance read measures Kev's wagers.

### Test quality

- **Art-dependent checks.** With your 179 new pictures in, the "every base's name in its cell" check now checks nothing on your machine. The gloves-unit and cure checks test different things depending on whether pictures exist. Other checks require pictures to pass.
- **The smoke writes your clipboard** twice a run while the watcher runs it.
- **Branch gaps:**
  - three of the wall rule's four branches
  - Kev's quality and slot pays
  - the hold-up fixture's silent guards
- **There's no whole-save before-and-after compare.**

## Design calls (yours)

1. **I4, secondary conversion:** apply it on the secondary's share, or hide the chip off the Primary. My view: hide it now, and decide after playtest.
2. **S7, the "hard" wager:** should it reach the head? My view: yes, it's the fight the wager is about.
3. **T3, the Quartermaster's Manual:** give it a new rule, or reword it. The Last Orders has the same dead clause.
4. **Loot rolls:** a find draws evenly from every base at or under its tier, so at T9 only about 10% of finds are T9. That undercuts one tier a zone. My view: weight toward the zone's tier. It changes the feel, so it's worth deciding before you play.
5. **Magazines against guns:**
   - Pouches count three of the *box's* magazines, not the gun's.
   - Bows, crossbows, catapults and the flare pistol hold 50-round "nail" magazines.
   - The Extended or Drum magazine parts don't extend anything.
6. **T4 heavy armour and rigs** drop at one site each.
7. **The Mint's tins** pay on bails and time-outs too.
8. **The cash runaway** follows the uncapped reward curve on runaway builds; sinks don't keep pace.

## Refactor list (after the playtest; sized in real time)

1. One runner-state key that every runner cache checks, about 1 h.
2. One "read as class" helper for the Radio, expeditions and bot, about 1 h.
3. `pack_rig` as the only packer; the bot just buys, about 1 h.
4. A dead-code and old-save sweep, about 1–1.5 h:
   - pre-v13 migrations
   - `tops_open`, `worn` / `worn_depth`
   - about 25 dead functions
   - a comment pass
5. `runner_busy()` on every kit move, and one art-slug rule, about 1 h.
6. Move the 74 literal log lines into words.gd so the language pass sees them.

Not worth it now: splitting sim.gd or smoke.gd, or turning the fight's inline rules into data.

## Your stray copies

`data-1.gd`, `data-2.gd`, `sim-1.gd`, `main-1.gd`, `web_view-1.gd`, `smoke-1.gd`, `smoke-2.gd`:
- They get linted and they ship inside exports.
- Diff each against HEAD, then remove it.
- Add `*-[0-9].gd` to .gitignore.
