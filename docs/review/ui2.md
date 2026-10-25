# Fiat: UI re-review, after the second pass (25 Oct)

Sources: scratchpad/fiatnow (current code), rr/second_pass.diff, rr/review/ui.md (this morning's review, items numbered as
there). Read-only: no repo file was edited. Everything below was checked in the source. Line numbers are fiatnow's.

Effort: S = under an hour, M = half a day, L = a day or more.

---

## A. The second pass: what's right, what's incomplete

### 1. The Fence's ask-twice never disarms on its own. Code-checked
- **Where:** fence_sell.gd 159–171 (`_armed`); vendor.gd 997 (the only visibility handler, and it only counts visits).
- **Why:** the arm clears only on the second press, or when its row empties (115). It survives leaving the room, the
  Contracts tab, buying a box (`_buy` 174), and a run coming home. Arm Legendary, go out for 20 minutes, come back to a
  stash with 30 more Legendaries, press Sell once: it sells them all, at a count the player never saw armed. Barracks
  clears its arm on hide (barracks.gd 1267); the Fence doesn't.
- **Change:** clear `_armed` on `NOTIFICATION_VISIBILITY_CHANGED` (not visible), on `_buy`, and when the armed row's
  `rarity_spare` count or worth changes from what was shown at arming. A short timeout (about 4 s) is the common pattern
  for press-again buttons and would cover all of these.
- **Assertion:** arm row r, hide the Fence, show it again: the row reads "Sell". Arm row r, add a piece of that rarity:
  disarmed.
- **Effort:** S

### 2. The Fence row's count includes pieces the press won't sell. Code-checked (the first review missed it)
- **Where:** sim.gd 10008–10012 (`sell_rarity` skips `tab_of(it) != ""`) against 10039–10050 (`rarity_spare` doesn't).
- **Why:** a class's own tab is left out of the sale but counted in "52 pieces · 7.0M". The armed press then sells fewer
  pieces for less money than the row said.
- **Change:** put the same `tab_of(it) == ""` test in `rarity_spare` (or move it into `_spare`). Add a smoke check that
  `rarity_spare(r)[0]` equals what `sell_rarity(r)` returns.
- **Effort:** S

### 3. The Fence's smoke check passes without testing anything. Code-checked
- **Where:** smoke.gd, `_review_fix_checks`: `_check(sim.stash.size() == n_before and …text == Words.FENCE_SURE or …disabled, …)`.
- **Why:** `and` binds tighter than `or`, so a disabled row 0 (no spare commons) passes whatever happens. The check never
  presses twice to confirm the sale, and the survive check covers only a unique and a patterned piece. ui.md 1 also
  asked for a set piece, a rule-kept piece and a kit piece.
- **Change:** give the stash a spare common first, then assert: the first press arms (text Sure?, stash unchanged), the
  second press sells, and then the arm is clear. Add the set, rule-keep and kit pieces to the survive check.
- **Effort:** S

### 4. The ring's reset arms silently, and an arm moves between targets. Code-checked
- **Where:** barracks.gd 1011–1017, 1154–1171, `_pick` 1075.
- **Why:** (a) with a ring node selected, the label stays "Reset the ring for X". Only the red style changes, so the first
  press seems to do nothing. (b) `_pick`, `pick_also`, `_pick_class` and `_on_train` clear `_armed` but not
  `respec_armed`. Arm the trees, click a ring node, press again: the ring resets, and the player never armed that. Arm,
  then train a node: the next Reset press resets at once, with the new node gone too.
- **Change:** give the ring reset the armed wording too ("Again: reset the ring for X"). Clear `respec_armed` wherever
  `_armed` is cleared (`_pick`, `pick_also`, `_pick_class`, `_on_train`, the code panel).
- **Assertion:** arm the trees, pick another node: disarmed. With a ring node selected, the armed label differs from the
  unarmed one.
- **Effort:** S

### 5. The Barracks arm leaves a stale label on return. Code-checked
- **Where:** barracks.gd 1267–1268, and the show_state signature at 484 (it doesn't contain `respec_armed`).
- **Why:** hiding sets `respec_armed = false` but leaves `_shown` alone. Come back within the same minute, with no change
  to cash or tree, and the button still reads "Again: reset for X" in red while disarmed. The smoke does the same
  (`bk.respec_armed = false` with no redraw).
- **Change:** add `respec_armed` to the signature (the Fence does this with `_armed`), or set `_shown = ""` in the hide branch.
- **Effort:** S

### 6. The temper tile never shows why it can't be done. Code-checked
- **Where:** workshop.gd 1031–1066; sim.gd 2102–2118 (`temper_block`, `_temper_cash`).
- **Why:** when blocked, `_temper_cash` returns −1, so the tile goes hollow with a blank price. The four reasons in
  Words.TEMPER (`no_piece`, `mythic`, `raise_first`, `too_high`) never reach the screen. Only the smoke reads them. A
  player with an un-raised piece sees a dead tile and doesn't learn to press "Item level +3" first. Short of scrap, the
  price turns grey without saying that scrap (not tins) is short.
- **Change:** when `kind == "temper"` and `cost < 0`, write `sim.temper_block(it)` into the price label, muted (or into the
  words line). When `scrap < temper_scrap(it)`, say "Short of scrap: 24 of 31".
- **Assertion:** select a plain un-raised piece in the Workshop; the temper tile's text equals `Words.TEMPER["raise_first"]`.
  Select a mythic; it reads `Words.TEMPER["mythic"]`.
- **Effort:** S

### 7. The temper words hard-code "+5%" and an undefined word, "the raise". Code-checked
- **Where:** workshop.gd 67 (`"Past the raise: damage and armour +5%"`); data.gd 2411 (CRAFT temper words).
- **Why:** the figure is Data.ILVL_GROW (0.05), and it applies only past ILVL_GROW_FROM (20) (items.gd 421). A unique
  under item level 20 can temper (`special` skips the raise check), and it doesn't grow 5%. If the balance pass moves
  ILVL_GROW, the words go stale. "The raise" names the tile the player sees as "Item level +3" (JOB_NAMES), so the
  player meets two names for one job.
- **Change:** build the line from Data.ILVL_GROW ("+%d%% damage and armour"). Say "After Item level +3", not "Past the
  raise", and do the same in Words.TEMPER["raise_first"] ("Do Item level +3 first").
- **Effort:** S

### 8. The fire figures are fixed. The fight's other figures still print raw. Code-checked
- **Where:** run.gd 402, 407, 414, 750 (`"%.1f/s" % last_incoming`, one form), 440 and 773 (Armour `"%.0f"`), and the
  skill fight line in stats_room.gd 621 (fine, it uses Fmt.num).
- **Why:** ui.md 5 asked for every figure on the run screen. "Their fire" grows with the gangs. At endgame levels
  "123456.7/s" has a single form, so it will clip in a 128 px tile, the same bug as 25661.
- **Change:** `[group + "/s", short_num + "/s"]` for Their fire. `[group, short_num]` for Armour.
- **Assertion:** the general one ui.md 5 asked for and the pass didn't add: on the run screen, no tile value's text is a
  strict prefix of its first form. At the least, feed `six_rows` a 1e6 incoming value and check that the shortest form fits.
- **Effort:** S

### 9. Indoor sites: the picture is dry but the sound and the rules still have rain. Code-checked
- **Where:** run_view.gd 720 uses `fight_weather_of`; sound.gd 497 still uses `weather_of` (the rain loop plays under the
  roof); data.gd 2947 (Rain: "Searches 30% slower, gangs 25% later") still applies indoors; the Map card's CONDITIONS line
  (missions.gd 435 → `sky_words`) says rain.
- **Why:** in the Bank, the Shopping Centre, the Garden Centre and the Hospital you hear rain you can't see, and you pay
  rain's search cost.
- **Talk first (design):** either indoors is dry for everything (rules, card, sound), or the card says "rain outside" and
  the rain's effect is kept. Either way, sound.gd 497 should match whatever the picture does. Fog and the night wash still
  show indoors; check that's wanted. No smoke covers the indoor sky. Add one: for each INDOOR_SITES site with its zone
  set to Rain, `_sky.showing()["rain"]` is false in the fight.
- **Effort:** S (once agreed)

### 10. The "On you" row narrowing has no assertion. Code-checked
- **Where:** run.gd 289–298 (`_skill_shift`), 478–485; the smoke's run text_nodes/line_pairs (run.gd 1312, 1341) don't
  pair the chips with the skill buttons.
- **Why:** the bug (a med chip under "Auto") was fixed by width alone. The house rule wants a check, and nothing would
  catch a regression.
- **Change:** in the run-screen smoke, with skills on and greed plus a med in use, assert that
  `_runner["chips"].used_rect()` (in the parent's space) doesn't intersect any skill button's rect.
- **Effort:** S

### 11. The greed chip is an unexplained term with a vague figure. Code-checked
- **Where:** run.gd 478–479; words.gd GREED.
- **Why:** the chip now shows only "Greed +10%". The style guide's §3 rule (new terms get a one-line tooltip where they
  first show) isn't met. "+10%" doesn't say of what, and quantity is dropped. The figure leaves out the Bookie's Pencil
  multiplier that `rarity_bonus` applies (sim.gd 1046). `GREED["chip"]` is now dead, and its "+5% finds" is off-glossary
  (the house word is "loot quantity", barracks.gd 349).
- **Change:** a tooltip on the chip: "Each gang after the clear: +10% loot quality, +5% loot quantity, for the rest of
  the run". Either fix or drop `GREED["chip"]`.
- **Effort:** S

### 12. Four phrasings for "press again" now. Code-checked
- "– press again" (barracks.gd 533, main.gd 590/647), "Again: reset for %s" and "Again: replace it" (words.gd 1172/1177),
  "Press again: it's gone for good" (words.gd 1203), and "Sure?" (words.gd 1168). ui.md 22 asked for one form.
- **Change:** pick one, e.g. "Again to sell" or "Sell 52 – press again" where there's room. "Sure?" fits the Fence's
  96 px button but doesn't restate what will go. Rules' Delete (rules_panel.gd 241) still deletes in one press (left over
  from ui.md 22).
- **Effort:** S

### 13. Verified fine
- Top bar: `top_dps_forms` and `top_hp_forms` (main.gd 1180–1186) end on a short form, and the smoke checks it fits.
  "Hurt" under 90% or with a wound, and the Training badge without the element meters, are both as approved, with
  assertions.
- The `fire_forms` forms (run.gd 737–740) are grouped and end short. pick_panel's dmg/s map is cleaned up. The
  "Gear level" → "Item level" change is consistent across missions.gd, radio.gd and smoke. The new screen-banned words are
  in place.
- Temper price forms: `"%s scrap · %s"` drops to `short_num` / `money_k`. At JOB_W − 24 = 256 px that fits up to millions.
- Every sell-by-rarity path goes through `_sell` (the only `sell_rarity` caller in the UI). The only respec paths are
  `_on_respec` and the build-code retrain (it has its own card, which ui.md 22 accepted).
- Rain halved (sky.gd 43–46): amount and speed halved, and lifetime follows speed, so the fall still crosses the view.

---

## B. Missed by the first review

### 14. No ask-twice arm in the game clears on leaving the room, except Training's. Code-checked
- workshop.gd 1374 `_break_armed` (a unique's break-down) and armoury.gd `_bin_armed` / `_save_armed` clear on the next
  press or a new pick, never on hide. Go back to the same piece later and one press breaks it down.
- **Change:** one small helper (arm, the key, the time armed, a 4 s expiry, cleared on hide) used by the Fence,
  Training, the Workshop, the Kit and the menu.
- **Assertion:** one generic smoke loop: arm each, change the room, come back: each is disarmed.
- **Effort:** S–M

### 15. Stale words in code. Code-checked
- run.gd 763: the comment "∞ … the Council's Weed Burner" (it takes shells now; `free_rounds` is the Spare Key only,
  items.gd 818). Only the comment is out of date: the code reads `free_rounds`.
- workshop.gd 466, 1048, 1077: `"%d scrap in hand"`, `"+%d scrap"`, raw `%d`. Scrap passes 999 in the endgame (the temper
  now spends it), so use Fmt.group (style guide §4).
- **Effort:** S

### 16. The paragon rows' new words read oddly. data.gd 1498–1502
- "+2% damage a point, each on the last" doesn't say "compounding" in plain words. Something like "+2% damage a point,
  each point on top of the last" or "+2% a point, compounding" (then add a tooltip, since it's a new idea). It's longer,
  so re-run the ring panel's fit.
- **Effort:** S

---

## C. Art the UI looks up by name (for the art manifest)

Caveat: this snapshot carries only part of art/ (450 PNGs, for example 41 of several hundred item pictures), so "missing"
here means not in the snapshot. Check on Matt's machine. Every lookup below has a fallback, so nothing crashes.

| Lookup (file:line) | Path pattern | Fallback when missing | Not in this snapshot |
|---|---|---|---|
| skill_bar.gd 198, web_view.gd 569 | art/skills/<id>.png | NodeGlyphs line glyph | **all 48** (folder absent); all in pixellab_skills_art_manifest |
| people.gd 18, web_view.gd 724 | art/people_new/<slug>.png then art/people/ | old face; nothing if neither | people_new folder absent; **Recruit has no face at all**; the Gamekeeper, the Quartermaster, gang_* |
| body.gd 49/48/46 | art/body_new/body_<cls>.png, art/body_<cls>.png, art/body.png | the generic body | body_new absent; **Recruit has no class body** |
| main.gd 226 | art/ui/copper.png, steel.png, army.png | NodeGlyphs (the purse manifest) | all three |
| ui.gd 98 (bands, cards) | art/places/<site>.png | band without art | the Allotments, the Garden Centre, Top Farm, the Outskirts |
| room_intro.gd 37 (Yard strip) | art/places/the_garden_centre, the_outskirts | strip left blank | both (the Yard's room card shows two empty strips) |
| web_view.gd 570, 1178 | art/nodes/<node slug>.png | node drawn plain | about 400 named in the web manifests; 30 present |
| web_view.gd 760, 850 | art/web/region_<tree>.png, backdrop_<slug>.png | no emblem / plain BG | region_ordnance (the Recruit's tree) |
| items.gd 197 | art/items/<base slug>.png | the slot's cell glyph | most bases, uniques, sets, parts, sockets, ammo, meds, order goods |
| run_view.gd 28–36, 208 | art/fight_walls, fight_new, fight, fight_test /<name>.png | the next folder; no art → the old two-box run screen | fight_doom set (test only) |
| run.gd 83, 199 | art/ui/{their_fire,kills,armour,rounds}.png, then art/ui_new/; dps, hp, cash | none (no icon) | all present |
| map_view.gd 185 | art/map/<nm>.png | null (no layer) | art/map/land.png (map_land manifest) |
| opening.gd 14 | art/intro/air_1..3.png | picture hidden, the words alone (opening.gd 146–147) | all three On-the-air scenes |
| crates_panel.gd 145 | art/crates/<key>[_open].png | tinted line glyph | none (all 8 kinds, both states) |

The second pass added no art: the temper tile and the greed chip are text only, and that's fine.

---

## Suggested order
1. Before the playtest (all S): 1, 4, 6, 2, 3, 5, 8, and 9's sound line once 9 is agreed.
2. Then 10, 11, 12, 14 (one arm helper fixes 1, 4, 5 and 14 together).
3. Polish: 7, 15, 16.
