# Review 3, stage 1: the game (sim, data, systems, the bot)

Scope: fe0fbef..HEAD in scripts/sim/{sim,data,items,words}.gd and tests/bot.gd, read against the code as it stands in
fiatnow/. File:line references are to fiatnow. I didn't flag missing old-save migration (SAVE_VERSION 10, as agreed).

Counts: A. Bugs: 6 (1 high, 3 medium, 2 low). B. Gaps: 6 (2 medium, 4 low). C. For Matt's call: 5.

---

## A. Bugs

### A1. Scrapping and then selling the scrap on the exchange pays more than the Fence, and the Clinic's shelf becomes a money pump (confirmed, high)
- **Where:** sim.gd:2501 `scrap_of`, sim.gd:2530 `scrap_yield`, data.gd EXCHANGE_BASE `"scrap": SCRAP_PER_POUND`, sim.gd `exchange_rate`; sim.gd:11922 `clinic_price`.
- **What:** `scrap_of` = worth / 24, ×2 with Strip for parts; `scrap_yield` ×1.5 with the Salvage node. The exchange values one scrap at 24 tins × inflation, less the spread (0.85, or 0.90 with Contacts) and ×1.05 with Fixer. Per unit of an item's worth W, scrap sold back for tins brings in:
  - nothing built: 0.85W (below the Fence's ~1.1–1.4W, so fine);
  - Strip for parts: 1.7W;
  - Strip + Salvage: 2.55W;
  - Strip + Salvage + Contacts + Fixer: 2.84W.

  The Fence pays W × (1 + sell%), and after the Issue × fence_rate (from 0.6). The exchange reads `inflation()` alone and never fence_rate.
- **Why it matters:** once Strip for parts is built (Bench, Parts line, 4th step), every find is worth 1.5–2.5× more scrapped at the Workshop (now a select-many) and exchanged than sold. The Fence's selling becomes a trap. The Clinic sells at 1.5W (`clinic_price`), so each run's shelf can be bought, scrapped and exchanged at a profit: +13% with Strip alone, +70–89% with the rest. For example, a Surgeon's kit costs 330 and gives 18 scrap, 367 tins with Strip alone, or 27 scrap, 551–612 tins with Salvage too. The shelf restocks every run. For the bot the loop has no limit at all, because `buy_med` has none (see B3). The Fence's ammo boxes break even with all four boosts (60 tins in, 68 out). Before today scrap had no way back to tins, so this is new.
- **Change:** make scrap one-way on the exchange (tins → scrap only), or price scrap's sell side at or below its worst-case return, `SCRAP_PER_POUND / (strip ×2 × salvage ×1.5)` ≈ 8 tins. Either way, add a smoke assert that `scrap_yield(it) × exchange_rate("scrap","tins") < sell_price(it)` with every boost on.
- **Effort:** S

### A2. Parking tins in exchange currencies before the Issue gets round its square-root "hard on piles" conversion (confirmed mechanism, medium)
- **Where:** sim.gd:1195 `issue_preview`, sim.gd:1205 `issue()`; sim.gd:1159 `inflation()` after the Issue; the exchange.
- **What:** the Issue converts `cash + notes + kit sale worth` at `0.8 × sqrt(pile)`. Scrap, salvage and materials held aren't in the pile. Their exchange worth after the Issue is linear: base × fiat_issue_inf × FIAT_SCALE × circ. Tins → scrap before the Issue and scrap → fiat after it comes back at about 0.72 (0.89 with Contacts and Fixer) of the linear rate, × circ_mult ≥ 1. That beats the root once the pile passes about 3–5M tins.
- **Why it matters:** this reopens the dodge the 26 Oct kit rule closed ("kit bought to dodge the root doesn't"). A rich endgame player keeps their money through the Issue.
- **Change:** add the exchange worth of held scrap, salvage and materials to `held` in both `issue()` and `issue_preview()`. Or shut the exchange for the run the Issue is fought on. Matt's call on which.
- **Effort:** S

### A3. Wearing a saved kit takes one pouch per box, so a kit's rig of magazines comes up short (confirmed, medium)
- **Where:** sim.gd:13542–13553 (wearing a loadout: `for it in stash.filter(...)`, one `take` per item).
- **What:** `take` now makes one pouch of `pouch_cap` (3 magazines) off a box per call. The loop takes each stash item once. A kit saved with three SMG pouches, worn with one 600-round box in the stash, gets one pouch (90 rounds), logs "worn_short … SMG rounds", and the box keeps 510.
- **Why it matters:** the Kit room reports a kit as short when the stash has plenty. In Leave-it mode the runner goes out with a third of the rounds the kit was saved with. In fill mode the gate's `_top_up` partly covers it.
- **Change:** inside the per-base loop, `while have < want and stash.has(it) and take(id): have += 1` (`_top_up` already loops this way).
- **Effort:** S

### A4. The Clinic's Magic and Rare meds roll their affixes at item level 1 (confirmed, medium)
- **Where:** sim.gd:234 `_plain` (rolls `Items.roll(slot, 1, rng)`, so `ilvl` is the tier-1 base's 1 and is never reset); sim.gd `_roll_med` uses `Items.ilvl(it)`.
- **What:** `_plain` overwrites base, tier and value but leaves the roll's `ilvl` (1). The old shelf rolled at the base's own tier. `_roll_med` rolls affix tiers and `affix_mult` at ilvl 1 whatever her step or the kit's tier.
- **Why it matters:** the supplies' payoff, "Rare meds on her shelf", gives low-tier heal%, Guard and quicker-to-use rolls. A Rare Hospital kit rolls like one from the first site.
- **Change:** in `_restock_clinic`, set `it["ilvl"]` before `_roll_med`, either to the base's tier (as before) or to the front's level for a step that should scale.
- **Effort:** S

### A5. Medical supplies replace papers and mythics in a find (confirmed, low)
- **Where:** sim.gd:9595 `if not from_kill and not socket_find and rng.randf() < supply_odds(...)`, then the SUPPLIES branch ahead of `myth`.
- **What:** the supply roll comes after the paper roll and isn't kept off PAPER (the socket roll is). The SUPPLIES branch is checked before `myth`, so a mythic rolled on that find is lost.
- **Why it matters:** at the Hospital (med 3.0) 9% of looks, and 35%+ of a medicine cabinet's, turn would-be papers (the endgame's keys) into supplies. A one-in-10,000 mythic can be silently swallowed.
- **Change:** add `slot != Data.PAPER and myth.is_empty()` to the supply roll's condition.
- **Effort:** S

### A6. The bot closes one of its two elements before checking it can open its own (confirmed, low)
- **Where:** bot.gd:1389–1391.
- **What:** with two open and the build's element not among them, the bot closes the oldest, then tries to open its own only if `pitch_free() > 0 or element_trained(element)`. With no Pitch point free it runs a closed element's nodes for nothing until a point comes.
- **Why it matters:** the balance reads under-report that class's power for those runs.
- **Change:** close only when the open will follow: `if ... and (sim.pitch_free() > 0 or sim.element_trained(element)): close_element(...)`.
- **Effort:** S

---

## B. Gaps

### B1. "The build's element" grade choice still reads the camp's elements, not the class's two (confirmed, medium)
- **Where:** sim.gd:3771 `build_elements()` (any node of any element in the camp's tree), read by `_feed_stack_raw` (3749) and `_top_up` (10975).
- **What:** two elements a class closed off the runner's element nodes in `_nodes_for` and `node_active`, but `build_elements` was missed. A frost/poison Poacher in a camp where the Drifter trained fire still loads and fires incendiary rounds first, and the gate packs them first.
- **Why it matters:** the runner fires the wrong element's grade, which feeds a meter that class doesn't fill and an element its nodes don't boost. The odds read it the same wrong way.
- **Change:** `build_elements()` keeps only `element_opened(el)`, and its key hashes `[tree, class_elements()]`.
- **Effort:** S

### B2. The odds don't re-read when an element is closed or opened for nothing (likely, medium)
- **Where:** sim.gd:7607 `_odds_key_common` (tree.size(), dps/armour/HP buckets, `_kit_ids`; nothing for `elements_open`); sim.gd `close_element` and `train_node`'s free-open path (the tree is unchanged).
- **What:** closing or swapping an element leaves `tree` and its size as they were. Only effects that move the dps, armour or max-HP bucket re-key the odds. Dot%, resists, keystones (Spreads, On your hands) and pace don't.
- **Why it matters:** after a swap the Map shows the old element's odds. The bot's `pick_tier` reads the same stale cache.
- **Change:** add `str(class_elements())` to `_odds_key_common`.
- **Effort:** S

### B3. The bot buys meds and cures the player can't (confirmed, medium)
- **Where:** bot.gd `_pack_cures`, `_cheap_heal` → sim.gd:11965 `buy_med`. No UI calls `buy_med` (grep). The player buys only `clinic`'s shelf via `buy_clinic`.
- **What:** the bot buys any base on `med_stock()`, any number, any time. That includes cures of every element. The player's shelf has `CLINIC_CURES` = 2 cures a restock, the front's elements first. `_cheap_heal` also extends the off-shelf bandage buy to whatever one-cell heal her tier carries.
- **Why it matters:** the bot's cure coverage, and so its odds and run figures, isn't reachable by a player, which skews the balance gates on the very system being tuned. With A1 in place it's also an unlimited pump open to the bot.
- **Change:** have the bot buy from `clinic` by id (`buy_clinic`), as the player does, or give the player the same list. Matt's call; the first keeps the bot honest.
- **Effort:** S–M

### B4. A found box sits in the pack but still counts as feed in the on-run try-on (confirmed, low)
- **Where:** sim.gd:3707 `_rounds_held` (adds `mission["found"]` ammo on a run), read by `has_rounds` (Fence shut) and `feed_stack` under `_trying`; sim.gd:11263 `_take_from` now refuses a found box into the rig.
- **What:** the 21 Oct rule ("a gun found with its box … read as a downgrade") counted the pack's box because it could go to the rig. It can't now. A found gun and its box read as an upgrade at the box's grade, but equipped from the pack it has no rounds in the rig. With the Fence shut it fires the secondary or fists.
- **Why it matters:** the pack's "better" arrow leads the player to equip a gun that goes dry at once. The Fence-shut case is exactly the early game's.
- **Change:** on a run, count only the rig's rounds and `from_rig` boxes: `mission.get("found", []).filter(func(x): return Items.is_ammo(x) and x.get("from_rig", false))`.
- **Effort:** S

### B5. A class with no saved elements has its pair shift when another class trains an earlier element (confirmed, low)
- **Where:** sim.gd:3208 `class_elements()` (derived each call when `elements_open` has no entry for the class).
- **What:** a class that never trained or closed a starter gets "the camp's first two in the circle's order", worked out fresh every call. When the Drifter later trains Petrol (first in the circle), a Doorman who had The cold and The Rat Man derived now has Petrol and The cold. That changes with nothing done by the Doorman, and his poison nodes go dark.
- **Why it matters:** the derived pair changes silently between sessions. The design meant the pair a class "takes" to stay its own.
- **Change:** the first time `class_elements()` derives a pair for a class, write it to `elements_open[cls]` (or do it on class swap).
- **Effort:** S

### B6. The Belt-fed SMG's 100-round belt doesn't fit in a pouch of 90 (confirmed, low)
- **Where:** items.gd `pouch_cap_of(type)` = MAG_POUCH × MAG_SIZE[type] (smg 30 → 90); data.gd Belt-fed `"mag": 100`; items.gd `pouch_words` and `pouch_fills` use MAG_SIZE by type.
- **What:** a pouch's size and its magazine words follow the rounds' type, never the gun's own mag. Belt links show as "3 mags" of 30, and one pouch holds less than one belt.
- **Why it matters:** the pouch reads three magazines but holds less than one belt. A Belt-fed runner needs two pouches per reload.
- **Change:** size a pouch of Belt links by the belt (a `"mag"` on the Belt links box, read by `pouch_cap`), or drop the Belt-fed's `"mag"`.
- **Effort:** S

Checked and clean: contracts, Orders and PACK_PAGE_ROWS have no readers left (grep across scripts, tests and tools). The exchange can't be pumped in a round trip: the drift only goes against the trader, so A→B→A ≤ 0.945². The dry runs restore the rig, HP and log, and `_cure` and the reloads touch only the scratch mission. The new state (supplies_in, elements_open, exchange_day, yard_v, the mission's mag/reload_t/fire_x/my_ails/cure_t/using.cures) round-trips through `_state`/`load_dict`. Reloads are in the dry runs (`_mags_tick` inside `_fight`) and in the analytic figures (`mag_share`). Ammo-to-rig paths cap at a pouch (`take`, `_feed`, `_skills_on_kill`, `rig_tops_up`). `pitch_reset` keeps the element starters. Ranks gate on a line's fifth step.

---

## C. For Matt's call

1. **Scrap on the exchange** (with A1): one-way (buy only), or a sell price below what Strip for parts and Salvage make? With it two-way at 24 tins, Strip for parts makes scrapping beat the Fence for every item.
2. **Fuses and the rebuild's materials for tins.** `exchange_offered` lists every material once its site is cleared, and fuses once the rebuild opens. A rebuild, and each rank's REBUILD_FUSES (the signals' reward), can be bought with tins outright. The bot now does this from a quarter of its cash (`_exchange_short`). That shortens the signals → rebuild loop. Leave fuses off the exchange, or keep them buy-at-a-premium only?
3. **The second line's price.** `yard_pick_cost` charges YARD_SECOND (2.5×) for any column whose other side is built. With two lines climbed in order, the second line costs 2.5× at every step, and which line a column counts as "first" depends on which was built first there. Was the second line meant to be dearer all the way?
4. **Her shelf's floor.** `med_stock` drops every heal at or under the lift. From the second step (lift 2) she stocks only Surgeon's and Hospital kits, both 2×2, and no one-pouch heals at all. Small rigs can then only buy cures from her. Keep a one-pouch heal on the shelf at every step?
5. **The Fence's third intro line changed** ("Notes, tins, scrap. I'll change any of it. At a price.") and its cue times are the old recording's (`ROOM_INTROS.fence.cues`). The voice needs recording again, as the comment says.
