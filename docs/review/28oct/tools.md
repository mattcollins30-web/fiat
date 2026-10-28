# Review 3 of 3: the tests and tools (28 Oct)

Scope: tests/smoke.gd, tests/bot.gd as a harness, tools/make_meds_mags_manifest.py and its JSON, and how well the day's changes are covered. I read the code only and ran nothing against the repo. As a side check I ran tools/art_lint.py, from the snapshot, on a copy of the manifest taken out of the diff and saved in scratchpad/r3work/.

Line numbers are in the snapshot (fiatnow/). Where a line comes from today's diff, it is marked "diff L".

Counts: 3 high, 10 medium, 15 low (the B table's rows aren't counted). By section: A has 1 high, 4 medium and 6 low; C has 1 medium and 2 low; D has 1 high, 3 medium and 2 low; E has 1 high, 1 medium and 2 low; the coverage list has 1 medium and 3 low.

---

## A. Holes in the smoke

### A1. "Run (the biggest pack, one screen)" never measures the pack (confirmed, high)
- **Where:** tests/smoke.gd `_pack_one_screen_checks` (diff L7635-7636).
- **What:** Each bag's loop iteration ends with `sim.extract_now()`. The `_check_fit` after the loop therefore runs with no mission. `_check_fit` only measures `main._run` when `main.room == MISSIONS and sim.on_mission()`, so here it measures the Runs screen (`main._missions`). No bag's pack is ever fit-checked, and neither is the scrolled pack.
- **Why it matters:** This is the UI fix Matt asked for after he died sorting a split bag. The rule is that every UI bug gets a fit assertion. This check is named for that fix but tests a different screen.
- **Change:** Call `main.refresh(); _check_fit(main, "Run (%s, one screen)" % bag["name"])` inside the loop, before `extract_now()`. Add one `_check_fit` after the scroll section, while still on the run.
- **Effort:** S.

### A2. The cures' and the magazines' screen checks sit behind a silent guard (confirmed, medium)
- **Where:** `_cures_checks` (diff L8019-8041) and `_magazine_checks` (diff L8265-8294): `sim.deploy(3)` then `if sim.on_mission():` with no else.
- **What:** Neither block sets `sim.hp = sim.max_hp()` before deploying. `deploy` returns quietly if `hp <= 0` or tier 3 is shut. If it does, these checks all vanish without a single fail:
  - the chill and shock chips, and the lit Tourniquet with its tooltip;
  - the pouch's magazine pips staying inside the pouch and off its words;
  - the Rounds tile, and the Reload tile;
  - three `_check_fit`s.
- **Why it matters:** These are the new UI checks for the meds and the magazines. Today they pass by luck of state, not by design.
- **Change:** Set `sim.hp = sim.max_hp()` before each `deploy(3)` and add `else: _check(false, "the fixture: no run")`. This is the pattern `_picked_clean_checks` already uses.
- **Effort:** S.

### A3. The bot's picked-clean check can pass without testing anything (likely, medium)
- **Where:** `_leave_checks` (diff L8812-8822).
- **What:** `_check(t2 != t1 or not others, ...)` passes whenever no other site reads PUSH. Nothing asserts that the fixture has such a site. Two smaller points:
  - `others` is worked out after `pick_tier` has already stepped depths back and armed or disarmed heads, so it reads a changed sim.
  - Only the non-campaign branch is reached. The `campaign_done()` two-pass loop is never exercised.
- **Why it matters:** A regression that sends the bot back to a picked-clean site would still pass whenever the smoke camp has only one holding site.
- **Change:** Build the fixture: open two farmed tiers, force `survival` to PUSH (or set the depths so both hold), and assert `others` with a "the fixture: ..." check. Add a second case with `campaign_done` true.
- **Effort:** M.

### A4. "Only the open two fill" has no positive control (confirmed, medium)
- **Where:** `_two_elements_checks` (diff L8469-8475).
- **What:** The check asserts that fire did not fill for the Scrapper. It would also pass if `extract_now()` never extracted, if the meters stopped filling altogether, or if the pool maths moved. `_fill_meters` runs only inside `_extract`, and `extract_now` does nothing when `can_extract()` is false.
- **Why it matters:** "Only the open two work and fill" is half of the new rule, and the check can't tell a working rule from a broken meter.
- **Change:** Put shock (open for the Scrapper) into the same `dealt_by` and assert that shock's points rise. Assert `not sim.on_mission()` after the extract.
- **Effort:** S.

### A5. The exchange's board checks loop over whatever the camp has (likely, medium)
- **Where:** `_exchange_checks` (diff L7237-7240).
- **What:** `for k in sim.salvage_kinds(): _check(on.has(k))` and the same loop over `materials_met()` both pass with zero iterations if the camp has dug nothing to `SALVAGE_DEPTH` and cleared no material site. The removed `_contract_material_checks` pinned those two functions directly:
  - D15 at the Barracks gives `["steel"]`;
  - the Outskirts alone gives no materials and no salvage;
  - fuses appear once the rebuild opens.
  
  Today those functions feed only the exchange board, so this is where their rules should be checked. See also B13.
- **Change:** Set `best_depth` to make one kind due (as the old check did), then assert `salvage_kinds() == ["steel"]` and that it's on the board. Do the same for one site's material, the Outskirts-only case and fuses.
- **Effort:** S.

### A6. The box-in-the-pack pick never asserts the box is drawn (confirmed, low)
- **Where:** `_run_screen` (diff L7104-7107).
- **What:** `_inv._pick(_inv.cell_of(box["id"]))` is called without checking that `cell_of >= 0`. If the box isn't drawn, the pick is -1, nothing is selected, and "a box in the pack offers Take into the rig" passes with nothing tested.
- **Change:** `var bk := cell_of(...); _check(bk >= 0, "the fixture: the box isn't drawn")` before the pick.
- **Effort:** S.

### A7. The flames-lean check hides behind a silent guard (confirmed, low)
- **Where:** `_hit_register_checks` (diff L7555): `if fp_fx != null and state in ["pop","up"]:`.
- **What:** If the kicked figure isn't up, or the emitter key changes, the check disappears without a fail.
- **Change:** Add `_check(fp_fx != null and state in [...], "the fixture: ...")`.
- **Effort:** S.

### A8. "Never a money pump" holds inflation still (likely, low)
- **Where:** diff L7488-7500.
- **What:** The loop over `d1`/`d2` varies only the drift day. `exchange_worth` reads today's `inflation()` for any day. Inflation climbs with `elapsed` (`1 + INFLATION_RATE*h`, capped), so the likely nominal pump is never modelled: tins to scrap or notes now, back to tins once prices are up more than about 12% (1/0.893).
- **Why it matters:** The check's message says "across any two days", which claims more than it tests. Whether a nominal gain counts as a pump is a design question (see F2).
- **Change:** Either narrow the message to "at one day's prices", or add a case that moves `elapsed` between the two legs and assert whatever Matt decides.
- **Effort:** S.

### A9. The Workshop's Select-many figure check accepts a figure-less button (confirmed, low)
- **Where:** `_select_many_checks` (diff L8602-8603).
- **What:** `contains("%d scrap") or text == "Scrap 1"` passes with no figure shown. The scrap delta checked afterwards does cover the sim side.
- **Change:** Drop the `or`, or assert the figure only when `scrap_yield > 0`.
- **Effort:** S.

### A10. The Fence's Select-many isn't shown to sell (confirmed, low)
- **Where:** same function.
- **What:** At the Fence the check only asserts that the item left. A bin would pass too.
- **Change:** Assert `sim.cash > cash0` for the MARKET row.
- **Effort:** S.

### A11. The Pitch's price buttons skip most of the new line steps (confirmed, low)
- **Where:** `_yard_wide_checks`, the "every buy button says what it costs" loop.
- **What:** The loop checks column 0 only. The new line `sim.yard_picks["stash"] = ["ab","ab","ab","ab",""]` (diff L8658) also means stash's column 0 is fully built, so stash is skipped silently. A line's later steps ("After ..." tiles, then Build) never get their price or width checked.
- **Change:** Check each building's next step on each line, using `Bot._next_step` or an equivalent.
- **Effort:** S.

---

## B. Lost or weakened checks

Every removed `_check` in the diff, grouped by function.

| # | Removed check | What replaced it | Intent kept? |
|---|---|---|---|
| 1 | `_contracts_checks`: three open, the mate has notes | Board starts tins, notes, scrap; the mate has notes | yes (the feature itself is gone) |
| 2 | 60 contract rolls inside their bounds | 60 days of drift inside ±EXCHANGE_DRIFT | yes (the same idea, carried over) |
| 3 | Scrap contract: the cheapest that fit picked, handed in through the screen, right helmets gone | Trade through the screen (give, get, 25/10/All, Trade, disabled with a reason) | yes (the screen path; "cheapest first" no longer exists) |
| 4 | A notes contract pays, the Fixer doubles it | The Fixer +5%, Contacts narrows the spread | yes |
| 5 | Passing a contract replaces it | none | n/a (gone) |
| 6 | The mate refuses a note short, sells the unique | The same, now through the screen's Buy | yes (stronger) |
| 7 | runs_total counts MATE_RUNS | The same, plus `exchange_day >= day0+1+MATE_RUNS` | partly: `>=` would hide a double day-step on one run home |
| 8 | Fit: Fence (contracts), (contracts, after) | Four Fence (the exchange ...) fit checks | yes |
| 9 | The rail: no badge until ready, "Ready" when ready, tab "Contracts ✓1" | The rail shows no Fence badge | partly: always true, since `_rail_status` has no Fence branch now. The idea that a waiting hand-in is flagged didn't move to the Clinic's supplies (F3) |
| 10 | What's next points at a ready contract | `not Words.NEXT.has("contract")` | no: nothing points the player at the exchange or at supplies to hand in (F3) |
| 11 | Contracts survive a save | The exchange's day and rate survive a save | yes |
| 12 | A row's title and count; every affix named; the tight form fits the row | Rate rows = currencies-1; first row's worth and move | partly (only row 0 is read; the other rows are left to `_check_fit`) |
| 13 | `_contract_material_checks`: salvage_kinds by depth (D15 → steel), Outskirts-only gives none, materials_met, the weights | Loops over the current state (A5) | no for `salvage_kinds`/`materials_met` rules; n/a for the weights |
| 14 | Turn-down price doubling, free after a run | none | n/a |
| 15 | An old save's unique, socketable or papers pay re-rolled; papers contract dropped | none (load ignores "contracts", per a sim.gd comment) | n/a (Matt's no-old-save rule; a save carrying `contracts` isn't load-tested, low) |
| 16 | Orders opens five rows, Pass and tag | none | n/a |
| 17 | `_fence_ab_checks` B: marks, swaps, pick handed in, a pass or load ends the pick | none | n/a (gone) |
| 18 | A patterned piece is never a contract's | Kept: never junk | yes |
| 19 | `_yard_pick_checks`: Orders +2 contracts; a refit off Orders gives them back | Contacts narrows the spread; refit restores it; the Fixer adds | yes |
| 20 | `_yard_wide_checks`: the strip inside the room, a 200 px heading, LANES_Y; regions = YARD names, 15 nodes each | Eight cards, 2 lines × 5; the detail inside the room; tiles above the rank | yes (cards vs the "gives" and detail panels aren't checked against each other; the constants fit today) |
| 21 | `_check_fit`: Pitch web nodes don't sit on each other | Pitch cards inside the room, none overlapping | yes |
| 22 | `_map_screen_checks`: focus_all puts every node on the canvas; the web buttons, Codes zoom | Columns inside the room and apart; tiles inside their column, none overlapping; the spine; fillers smaller; a tile pressed picks; the panel's words clear of its buttons | yes (stronger) |
| 23 | `_web_checks`: link-through, pictured size and draw calls on three canvases | The Training canvas only | partly: the Dial and the Pitch no longer have a frame-call budget. The tiles are Buttons and Labels now (the 23 Oct fan issue was draw calls) |
| 24 | The Dial's fillers borrow Training's pictures (`map_f_`) | The keystone's panel picture only | partly: atlas.gd:164's filler `map_f_` path is untested |
| 25 | `_stack_checks`: the full stack goes to the rig whole; top-up to cap_nails | A pouch of MAG_POUCH magazines, the rest stays; top-up to `pouch_n` | yes (by design) |
| 26 | `_stack_checks`: leaving merges into one stack | The same count of stacks, rounds + pouch | yes |
| 27 | `_ammo_checks`: Fill up takes Slugs and Shells (every grade) | Slugs, and 1..ceil(share) pouches | yes (by design: the best grade first) |
| 28 | `_run_screen`: found rounds go into the rig | The box stays whole; the pick has no "Take into the rig"; fit | yes (A6 aside) |
| 29 | Every med card says " HP " | " HP ", or "Stops" for a cure | yes |
| 30 | The rig takes any med or box dropped on it | Non-ammo only; the comment says "the magazines' own drag is _magazine_checks'" | partly: `_magazine_checks` has no drag. A box dropped on a rig with a free pouch (fills a pouch, the rest stays) has no `_can_drop`/`_drop_data` check |
| 31 | Kev's pile inside the decoder box | Inside the papers box | yes |
| 32 | The bot builds "its other side" | "its other line" | yes |
| 33 | `_element_bot_checks`: `contracts = []` fixture | dropped | n/a |
| 34 | `_pitch_scramble_checks`: web node name | The tile name after `_pick_building` | yes |
| 35 | `_web_rule_checks`: `is_medical` | `is_heal` | yes |

---

## C. Leaks and flakes

### C1. Two tools still call the removed contracts (confirmed, medium)
- **Where:** tests/shot_fence.gd:28,35 (`sim.contracts[0] =`, `_show("contracts")`, `_pick_contract`); tests/fp_dbg.gd:44-46 (`sim.contracts`, `contracts_open()`, `roll_contract()`).
- **What:** Both now fail at runtime. tests/fingerprint.gd was updated; its debug twin wasn't.
- **Change:** Drop those lines, or move shot_fence to `_show("exchange")`.
- **Effort:** S.

### C2. `_select_many_checks` leaves the Fence and the grids changed (confirmed, low)
- **What:** The Fence's tab is left on "stash". The `continue` path leaves `inv.many = true`. `main._armoury.selected` is left on Primary by `_strip_all_checks`. The sim is restored by `load_dict`, but these UI fields aren't.
- **Change:** `main._fence._show("shelf")` at the end; put `inv.many = false` before the `continue`.
- **Effort:** S.

### C3. Dice-dependent checks under `-- seed random` (likely, low)
- **What:** These ride the seeded sim dice. They're stable at SMOKE_SEED but could go red on another seed:
  - frost and shock landing in 4 ticks;
  - the bleed grace's positive leg;
  - Magic and Rare both in 30 restocks;
  - over 10 supply finds in 200;
  - the SMG pause pattern.
  
  The exchange's drift is hash-seeded and not at risk.
- **Change:** None needed unless Matt runs random seeds as a gate. If he does, raise the counts or seed the rng in each fixture.
- **Effort:** S.

No sim-state leaks found. Every new check function snapshots with `to_dict()` and restores. `elements_open` is restored in `_web_pool_checks` (by `load_dict`) and in `_element_checks` (`crowd_open`). The money-pump fixture puts `yard_picks` and `_yard_dirty` back. `_yard_set` maps every `YARD_OLD` id: I checked all 80, and each still exists in `Data.YARD`.

---

## D. The bot

### D1. Magazines plus cures leave small rigs with no heals (likely, high; the probable cause of the 2-3x slower climb)
- **Where:** tests/bot.gd `_restock_meds` (1515-1536): `_restock_rounds` fills ammo up to `mag_room = ceil(med_capacity*0.5)`, then `_pack_cures` takes a pouch per front element (up to `TOP_UP_CURES` = 2), and the heals get what's left. The gate's `_top_up` in sim.gd keeps the same order.
- **What:** `want = rof*120*pair` is never met by 3-magazine pouches, so the ammo always takes its full share. On the early rigs that leaves:

  | Rig | Pouches | Mags | Cures | Heals |
  |---|---|---|---|---|
  | Bum bag | 3 | 2 | 1 | 0 |
  | Fishing vest | 5 | 3 | 1-2 | 0-1 |
  | Chest rig | 7 | 4 | 2 | 1 |

  The Outskirts cure is for poison, which is 10% of the gangs' damage. The bot only heals with `first_med()`, which now excludes cures. Add the reload pause in the damage figures, and the early hours run with almost no heals.
- **Why it matters:** This fits a 1 h read that climbs 2-3x slower after magazines. The smoke's gate-cure fixture (`_cures_checks`, diff L8007-8011) has no ammo in the stash, so it never reaches this crowded path.
- **Change (bot side, smallest):** In `_pack_cures`, skip a cure when it would leave fewer than one or two heal pouches, or when the element's share of the zone is under a floor. Add a smoke check: a 5-pouch rig with ammo, cures and bandages in the stash comes out with at least one heal.
- **Effort:** S (bot) / M (if the gate changes too; that's for the sim reviewer).

### D2. The primary's pouches take the whole share, so the secondary goes dry (confirmed, medium)
- **Where:** `_restock_rounds` (bot.gd, the `mag_room` line in the `while`).
- **What:** One counter of ammo pouches covers both guns. The Primary pass fills `mag_room` first, so the Secondary's loop never runs when the types differ. The gate keeps one pouch back for a second type (`sec_quota`), but after the bot has filled the share, `mag_pouch_room()` is 0, so the gate can't fix it.
- **Change:** Mirror the gate's split: `room - 1` for the primary when the secondary fires a different type and its rounds are in the stash.
- **Effort:** S.

### D3. The bot closes an element it can't replace (confirmed, medium)
- **Where:** `_train_tree` (bot.gd, "two a class (28 Oct): the oldest closed").
- **What:** The close runs whenever the build's element isn't open and two are. The open after it needs `pitch_free() > 0 or element_trained(element)`, and the starter needs `can_train`. When neither holds, the bot drops a working element and opens nothing. Its nodes go idle until a Pitch point comes. No smoke check covers this path.
- **Change:** Close only when the open that follows is possible: `pitch_free() > 0 or element_trained(element)`, and the starter `can_train` once the close is done. Add a smoke case for the bot's close and open.
- **Effort:** S.

### D4. `_exchange_short` buys salvage for steps the bot won't build yet (likely, medium)
- **Where:** bot.gd:1262-1290.
- **What:** It gathers "Wants" from both sides of every open column. That includes the other line's next step, which the bot builds only after its own lines are done, at 1.5x cash. So it turns tins into salvage early, through the spread. The spending limits are sound: 25% of cash at most, `_reserve` plus the build's own price kept back, and only what's short. There is no smoke check of `_exchange_short` at all.
- **Change:** Gather wants only from `BOT_LINE`'s `_next_step` per building (and the other line only when `_build_yard` would buy it), plus the rank. Add a smoke case: salvage short for the bot's line's next step, tins enough. It buys exactly the gap and keeps the reserve.
- **Effort:** S.

### D5. Untested bot rules (confirmed, low)
- **What:** None of these has a smoke check:
  - `_cheap_heal`: the cheapest one-cell heal once her shelf moves past bandages;
  - `_sell_spares` keeping three cures of each;
  - the `mag_room` cap in `_restock_rounds`;
  - `_build_yard`'s BOT_LINE first pass, beyond the "other line" case.
  
  (`_pack_cures` and the supplies hand-in are covered.)
- **Change:** One small smoke function, `_bot_meds_mags_checks`.
- **Effort:** S.

### D6. Dead code left in the bot (confirmed, low)
- **What:** `LORRY_WATCH_COL := 4` and `_lorry_watch_saving` (returns 0) are no longer read by `_build_yard`. Removing them changes nothing.
- **Effort:** S.

Nothing found that a player can't do. `close_element` matches Training's Close/Open buttons. `hand_in_supplies` matches the Clinic's strip. `exchange` matches the Fence's Trade. `buy_med` uses her list, as before.

---

## E. The art manifest

art_lint.py on the extracted JSON:
- **Seeds:** clean. 121000-121011, shared with no other manifest; the snapshot's highest is 120011.
- **Outs:** clean. No duplicates.
- **Style refs:** all 12 reported not on disk, but `art/reference/items/` isn't in the snapshot at all, so this is unverified, not a fault.

The out paths match what the code reads:
- `Items.art` → `res://art/items/<slug(base)>.png`: tourniquet, burn_gel, activated_charcoal, hot_flask, smelling_salts, medical_supplies.
- `Items.mag_art` → `mag_<type>`: smg, rifle, pistol, shotgun, improvised, plus `mag_belt` for Belt links (type smg). Together these cover all 15 ammo bases.

### E1. Three jobs ask for a second object or debris (likely, high, given the art lessons)
- **What:** The template's TAIL says "One object centred ... Nothing else in the frame". These jobs contradict it:
  - Burn gel: "a tube ... **beside a folded square of gel-soaked dressing**" is two objects.
  - Activated charcoal: "**a little black powder spilled beside it**" is debris on a surface, which reads as setting.
  - Hot flask: "**with its cup-lid off**" invites a second object (the cup) in frame.
- **Why it matters:** These break the project's lesson of one object alone with no setting. That lesson exists because of credits spent on images that came back wrong.
- **Change:** Burn gel: "a small squeezed tube of clear burn gel, plain white, unprinted". Charcoal: drop the spill ("the cork out, a little powder at the neck"). Flask: "its lid off" with no cup.
- **Effort:** S.

### E2. The magazine counts in the pictures don't match MAG_POUCH = 3 (confirmed, medium)
- **What:** The cell draws three pips (`Data.MAG_POUCH` = 3, checked by `mag_pips().size() == MAG_POUCH`). The pictures show two SMG magazines, two rifle magazines, three pistol magazines, six shells and two nail strips.
- **Change:** "three loaded ... magazines" for the smg, rifle and pistol; keep the shotgun caddy, belt and nails as they are (see F4).
- **Effort:** S.

### E3. Naming what to leave out can bring it in (likely, low)
- **What:** "sealed syringes **with no markings or numbers on them**" and "**no red cross**" name the very things to avoid. The other jobs say only "unprinted / no markings", which is safer.
- **Change:** "sealed plain syringes", and drop "no red cross" (the TAIL already says no logos).
- **Effort:** S.

### E4. Nothing ties the manifest to the code (confirmed, low)
- **What:** No check fails if an ammo base or a cure is added without art, or if a manifest `out` stops matching `Items.art`/`mag_slug`. The smoke checks `mag_slug` names (diff L8308-8311) but not the manifest. Separately, `make_item_manifests.py`'s "new" groups ("whatever is not drawn yet") may also emit the cures and supplies. If it's regenerated before this batch runs, art_lint's "out" check will report two different jobs writing one file.
- **Change:** Have art_lint (or the generator) assert every `mag_slug` and every MEDICAL/SUPPLIES base without art has a job, and run make_meds_mags_manifest first.
- **Effort:** S.

---

## Coverage of the day's changes (what's missing)

- **Strip all (medium):** only the Kit room is tested. Not tested:
  - the Workshop's "Strip all N" button, and its fit;
  - the "as room allows" case (a stash with room for fewer parts than are on);
  - the button off on a run.
- **Names (low):** `region_words` and `plain_name` are checked. barracks.gd's lane words (`plain_name` for element trees) and web_key.gd's element rows aren't asserted, so only `_check_fit` stands behind them.
- **A box dropped on the rig with a free pouch (low):** see B30.
- **The Removal Van (low):** the real scroll case is untested. The scroll is driven with `set_rows(2)` instead, which is fine as a mechanism check.

---

## F. For Matt's call

1. **The rig split (D1).** Should cures be packed at all when they'd leave no heal pouch? Should the gate's ammo share be a share of the pouches left after one heal? This is the most likely cause of the 2-3x slower 1 h read, and it's design, not a bot bug. The bot copies the gate.
2. **Inflation and the exchange (A8).** Should a tins-to-scrap-to-tins trade across an inflation rise be allowed to come back ahead in nominal tins? That makes it a hedge, not a free lunch. The smoke currently claims "never a pump" without testing this.
3. **A flag for things waiting on the player (B9, B10).** The ready-contract badge and the What's next line went with the contracts. Supplies to hand in now have no rail badge and no What's next line. Should the Clinic be flagged the way a ready contract was?
4. **Magazines in the pictures (E2).** Three to a pouch to match the pips, or leave the art loose?
5. **Draw-call budget for the new Dial and Pitch (B23).** Worth a frame-call check on the tile screens, given the 23 Oct fan issue?
