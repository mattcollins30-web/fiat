# Fiat: UI and player experience review (before the 0.9.0 playtest)

Sources: the screenshots in chase/now and chase (some predate the 0.9.0 language pass, e.g. "Loadout 1" is now "Kit 1"
and the Workshop's fifth tab, Patterns, is missing from them), scripts/ui/*.gd, scripts/sim/sim.gd, docs/language/style_guide.md,
and the end of docs/status.md. Missing art in the cloud shots (AMO/ATT words, glyphs in place of skill pictures) is not
counted. **Code-checked** means I confirmed it in the source, not just in a screenshot. No files were edited.

Effort: S = under an hour, M = half a day, L = a day or more.

---

## A. Lose-your-stuff traps (fix before the playtest)

### 1. The Fence's "Sell Legendary" sells uniques, set pieces, patterned pieces, rule-kept pieces and kit pieces. Code-checked
- **Where:** fence_sell.gd `_sell` → sim.gd `sell_rarity` / `_spare` (around line 9909).
- **Why:** a unique's rarity is set to Legendary (items.gd 622: `RARITIES.size() - 1`). `_spare` leaves out only rig items, papers,
  mythics, the deeds and upgrades. It does **not** leave out `unique`, `set`, `pattern`, a loot rule's keep or highlight
  (`loot_rule_act`), or a piece saved in a kit. `is_junk` (line 9937) does guard all of those, so the two paths disagree. The status
  doc says "a kept piece is never sold or binned", and this row breaks that. In the screenshot the Legendary row reads "52 pieces ·
  4 kept · 7.0M", and most of the Kit's stash is pink (unique) Door rams and Engineer's pieces. One press, no confirmation, no buyback.
- **Change:** make `_spare` use the same exclusions as `is_junk` (unique, set, pattern, rule keep/highlight, kit pieces, built guns).
  Have the row say what it skips ("52 · 31 uniques kept"). Make the press ask twice, the house pattern ("Sell 52 · 7.0M – press again").
  Add a smoke check that a unique, a set piece, a patterned piece, a rule-kept piece and a kit piece all survive `sell_rarity(4)`.
- **Effort:** S

### 2. A run that's "picked clean" sits idle until the clock runs out, then loses the pack. Code-checked + run_0..7
- **Where:** run.gd (the six tiles, the clock), sim.gd 8329 (the picked-clean return only with `hold_fire` and no gangs) and 6877 (out of time).
- **Why:** run_0 → run_7 show Ransacked Streets "Picked clean: every crate open" at 4:48 left, with "Gang in 14:22". Nothing can happen
  before time runs out. The screen stays the same for five minutes, the clock goes amber only at 0:26, and the run ends "Out of time"
  (the pack lost, plus up to `CLOCK_LOSE_KIT` pieces). The log line at the foot, "Out of time from Ransacked Streets: 5 kills, 0 items,
  402 tins", doesn't say the pack went. In an auto-battler people look away, so this will happen to real players.
- **Change:** (a) When the site is picked clean and the next gang lands after the clock, bring the runner home on their own. If that's
  a design no, at least pulse "Get out now", turn the clock amber, and swap the band line for "Nothing left before time's up: get out
  or lose the pack". (b) Show "Gang in: after time's up" instead of a time that will never come. (c) Make the log and toast line for a
  timeout name the loss in red: "Out of time: the pack's gone (13 pieces)".
- **Effort:** S–M

### 3. "Reset trees" wipes every perk in one press. Code-checked
- **Where:** barracks.gd `_on_respec` (1148). The build-code panel shows "237 of 237 perks trained".
- **Why:** a misclick on a 7,767-tin button throws away a 237-perk build with no confirmation. Class swaps already ask twice in this
  room, so the house pattern exists here already.
- **Change:** the same press-again arming: "Reset 237 perks for 7,767 tins – press again". Better still, copy the current build code to
  the clipboard as it resets, and say so in the log.
- **Effort:** S

### 4. Loot is always picked up by hand, one item at a time. Code-checked
- **Where:** sim.gd 30 `loot_by_hand := true` (no setting anywhere) and crates_panel.gd (the floor: drag, or double-click one item).
- **Why:** run_0 shows "ON THE FLOOR · 91 THINGS · 1/12" with the pack at 13 of 69. Taking loot means paging through 12 pages and
  double-clicking each piece. The loot rules apply only "when a run comes home", so they don't help here. The only automatic path is
  hidden inside "Fill up, then go", which turns hand looting off (`leave_full`) without saying so. Over 30 hours this is the most
  repetitive click in the game.
- **Change:** add "Take all that fits" (best value first) and "Take what the rules keep" buttons to the floor's header row. Add a
  setting or a Kit toggle, "Pick up: by hand / by the rules / everything". Give "Fill up, then go" a tooltip and a subtitle that say it
  also loads the pack itself.
- **Effort:** M

---

## B. Readability of large figures (the design promises millions)

### 5. Large figures clip or drop digits instead of shortening. Code-checked + screenshots
- **Where:** run.gd `fire_forms` (the "Your fire" tile), the top bar's damage readout (main.gd), and every spot that prints `%d` / `%.0f` raw.
- **Why:** the run tile shows **"25661"** for a runner the top bar and Stats put at 256,613 dmg/s. Both of `fire_forms`' forms are
  too wide, and the last one is cut. That's a figure ten times too low at the one moment you judge a fight. The top bar always shows
  "256613 d..." and "1088 / 1088 ..." on the run screen. The map's "Insure · 0" has lost its unit. Fiat is meant to scale into millions,
  so this will get worse.
- **Change:** a compact form in Fmt (256.6k, 14.0M, already used for tins in places) as the last fit form on every figure. Add a smoke
  assertion that no figure's shown text is a prefix of its full text (that is, a digit was clipped). Per the house rule, fix this and
  add the check.
- **Effort:** S–M

### 6. Thousands separators are missing in many places (style guide §4). Screenshots
- **Where:** "13202 runs", "36732 free", "Items 262102", the Pitch chips "Scrap 72017 / Notes 9778", Workshop "9778 notes and 72017
  scrap", "256613 dmg/s", "Before: Drifter 3135, Drifter 3231…".
- **Why:** it breaks the "1,288 tins" rule, and next to "223,905,182" the same screen uses two formats.
- **Change:** use `Fmt.group` everywhere a count can pass 999. A smoke grep can catch `%d` on figures that can grow.
- **Effort:** S

### 7. Small text won't survive the Steam Deck. Code-checked
- **Where:** web_view.gd (labels at 13–15 px, fixed), barracks.gd (tabs and Find at CELL_TEXT−2 = 14 px), stats_room fight (CELL_TEXT−3 =
  13 px), map key (14 px), Training's POINTS panel, the Pitch tree labels.
- **Why:** the game is laid out at 1080p and Matt plays on the Deck (1280×800, ×0.67). There 13 px becomes about 8.7 px. The Training
  and Pitch labels already look tiny in the 1080p shots.
- **Change:** a 16 px floor for anything the player reads, and an "Interface size" option (100/115/130%) in Settings via
  `content_scale_factor`. At minimum, test-render each room at 1280×800 before the playtest.
- **Effort:** M (the floor), L (the scale option)

### 8. The Attack card's "how it's built" doesn't add up to the headline. room_stats.png
- **Where:** stats_room.gd, the ATTACK card.
- **Why:** "= base 4764/s" sits under a headline of "256613 dmg/s", a gap of about 54× that nothing explains (conversions, ailments,
  first of each gang?). This is the screen where a player checks their build, and the sum doesn't reconcile.
- **Change:** add the missing rows (elements ×, ailments +, skills +) so the last row equals the headline, or relabel the block as
  "Before elements and ailments".
- **Effort:** S–M

### 9. Unexplained double figures. Screenshots
- **Where:** resists "75% +50" (Stats DEFENCE and the Map's THEY FIRE), Training chips "Fire 21% · +67%", the fight's "1 use · 0".
- **Why:** each shows two numbers with no key. The style guide asks for one idea per chip and a first-show tooltip.
- **Change:** "75% (+50 over the cap)" or a one-time tooltip. "21% as fire · +67% fire". "1 use · 0 damage".
- **Effort:** S

---

## C. Decisions with information hidden or missing

### 10. "What came back" covers the site panel's header, including the odds. room_the_map.png, came_back.png
- **Where:** missions.gd `_show_came_back` (forced open while Kev's story is in it, line 678), came_back.gd.
- **Why:** in every Map shot the card sits over the top of the chosen site's panel. The site name and the first tile row (the odds)
  are hidden, and "Gear level 16" is half under it. Those are the facts you decide on. The card also shows a running total since
  "Seen" was last pressed ("13,202 runs · 14.0M"), not the run that just ended: after run_7 the last run's result is only in the log.
- **Change:** put the card in the space between the map's top edge and the site panel, or have it collapse to its button once a site
  is picked or after one look. Lead with the last run ("Back from Ransacked Streets · 4 items · 438 tins"), with the running total under it.
- **Effort:** S–M

### 11. A new rule can't be tried out, and the rules don't apply to the stash already held. Code-checked
- **Where:** rules_panel.gd and sim `apply_loot_rules` (used only at 8717, on the run's way home).
- **Why:** a player who sets up rules at hour 20 with 328 pieces in the stash gets nothing for the backlog. Scrap is destructive and
  there's no "this would match N pieces" preview. The panel also covers the stash, so you can't see what a rule picks.
- **Change:** show a match count on every rule row ("Scrap · 41 in the stash"), add an "Apply to the stash now" button (asks twice
  when it would scrap), and give highlighted matches their amber edge in the stash while the panel is open.
- **Effort:** M

### 12. Duplicate uniques pile up forever. kit / fence_stash shots + code
- **Where:** the Kit stash (about 20 Door rams and Engineer's pieces), the rules (they never scrap a unique), Sell when home (never a unique).
- **Why:** none of the automatic paths can clear a spare copy, so the stash fills with copies at 2×1 cells each. The only bulk exit is
  the indiscriminate Legendary row (item 1).
- **Change:** a "Spare copies" row at the Fence (sell every copy but the best roll of each unique), and/or a rule kind "Duplicate
  unique" with "Sell" and "Break down" (into a pattern) as actions.
- **Effort:** M

### 13. Two overlapping junk systems. Code-checked
- **Where:** the Kit's "Sell when home: off" and "Keep: upgrades" (armoury.gd 241, the old junk rules) next to "Loot rules" (the new filter).
- **Why:** both decide what a run's finds turn into, in two places, with different words and order (rules first, then the Bins). A
  new player won't know which one wins.
- **Change:** fold "Sell when home" into the rules as a fourth action, Sell (with "Keep upgrades" as the default guard), and retire the
  two cycling buttons. Until then, the rules panel's note should say the Bins run after it.
- **Effort:** M

### 14. The Kit's empty panel holds the kits and three toggles, and they vanish on any selection. Code-checked + loadouts.png
- **Where:** armoury.gd `_show_panel` (kits and "Equip if better / Sell when home / Keep" only when nothing is picked).
- **Why:** the first click on any item hides the kits. There's no visible way back to the empty state (no deselect button, Esc opens
  the pause menu). Kits are a new 0.9.0 feature, and this hides them.
- **Change:** a fixed strip for Kit 1/2/3 on the runner strip (beside HP) or under the body. Clicking the selected item again or
  pressing Esc deselects it.
- **Effort:** S–M

### 15. "Gang in 14:22" next to "4:48 left". run_0
- Covered by item 2, but on its own as well: a time after the clock is noise. Say "after time's up" and mute it.
- **Effort:** S

### 16. The build-code plan shows "The Pitch · −4 free". buildcode.png
- **Where:** barracks.gd plan preview / POINTS panel.
- **Why:** negative points in a preview that also says "237 of 237 perks trained, no reset". Either the plan over-spends the Pitch, or
  the panel counts against the wrong pool. Either way the player can't tell what Retrain will do. Check this in code before the playtest.
- **Change:** clamp the shown value and list what can't be trained (the "missed" words exist: "%d can't be trained yet").
- **Effort:** S (after a look)

### 17. The fight breakdown covers the last run only, and its empty rows. stats_fight.png
- **Where:** stats_room.gd `show_fight`.
- **Why:** "What hit you" lists Bleed 0, Physical 0. Took 0 and Meds 0 fill the tiles. Only one run can be read, so a player can't
  compare builds across runs.
- **Change:** hide rows at 0 ("Nothing hit you"). Keep the last five breakdowns with small tabs (the site and time).
- **Effort:** S (rows), M (history)

---

## D. Consistency between rooms

### 18. Esc doesn't close overlays: it opens the pause menu on top. Code-checked
- **Where:** main.gd `_unhandled_input`. stats_room (fight, collection), rules_panel, tier_guide (Site guide), skill picker, order card
  and the build-code plan don't handle Esc. Only room intros and the opening do (the `_overlay_closed` trick).
- **Why:** the Esc reflex is to close what's open. Here it stacks the pause menu over the collection.
- **Change:** one overlay stack in main. Esc (and the pad's B) closes the top overlay first and pauses only when none is open. A click
  outside an overlay's panel closes it too.
- **Effort:** M

### 19. Close buttons differ in place and wording. Screenshots + code
- Collection: "Close", top right. Fight: "Close", bottom right. Site guide: "×", top right. Rules: "Close" in a row with "Add a rule"
  and "Rules on". Came back: "Seen". Build plan: "Cancel".
- **Change:** one rule: "×" (or "Close") top right, always the same size, with Esc as above. Keep "Seen" only if it does more than close.
- **Effort:** S

### 20. Room tabs use three styles. Screenshots
- Workshop: big text, white outline on the active tab. Clinic and Fence: orange fill. Radio: small orange fill. Training and Pitch:
  small dark chips in a second row ("Whole web / The class's / The Pitch", "The whole Pitch / The Bench…").
- **Change:** one tab component (size, active style, place in the band), and one style for sub-filters.
- **Effort:** S–M

### 21. Cycling buttons pretend to be dropdowns, and toggles look like actions. Code-checked
- Rules "From Rare ▾ / To Legendary ▾" step one way per press (`_step`). "Top up ▾" cycles. The stash's rarity "Any" cycles through six
  with no label. "↕" sort cycles three. "Head" and "Equip if better" are toggles shown as plain buttons (a ✓ appears only when on).
- **Why:** ▾ promises a list. Cycling back to Common from Legendary takes up to five presses. On the Deck the only label is a
  tooltip, and tooltips need hover.
- **Change:** real popups (a small list) for From, To, rarity and sort. Show the current sort in words ("Value ↕"). Give toggles a
  consistent on/off look (a switch, or "On"/"Off" chips as the rules rows already use).
- **Effort:** M

### 22. Confirmation for destructive actions is inconsistent. Code-checked
- Ask twice: class swap, overwriting a kit, breaking a unique down, a new game. Not asked: Reset trees (3), Sell by rarity (1), Delete
  a rule, Bin n in the Kit, Retrain from a code (it has a card, fine).
- **Change:** one rule: anything that loses an item, perks or more than X tins arms on the first press, in the same words ("… –
  press again").
- **Effort:** S

### 23. Colours collide. Screenshots
- Amber means selection, a Legendary border, the rules' Highlight edge and the primary button all at once. Fire (orange-red) and
  Bleed (red) look nearly alike in the resist bars. The map's Safe/Risky/A bad idea pins differ by colour only (green/amber/red), which
  fails for colour-blind players.
- **Change:** give Highlight its own mark (a corner tag or a dashed edge, not amber). Add a shape or letter to the map pins (✓ / ! / ✕).
  Move Bleed towards crimson or magenta, or add element glyphs to the bars.
- **Effort:** S–M

---

## E. Finding the new features

### 24. 0.9.0's features have no "new" marker. Screenshots + code
- Loot rules (a button among the stash filters), the collection ("The collection ›" small, in the Record's header), the fight
  breakdown ("The fight ›"), Patterns (the Workshop's fifth tab, no badge), kits (the empty panel only), build codes (Training's
  ALSO strip).
- **Why:** an existing save has met every room's intro, so nothing tells the player these exist.
- **Change:** a one-time "New" dot on the rail room and on the control, cleared on first use (rail badges already exist in
  main `_rail_status`). A one-line radio or log line per feature on the first load of 0.9.0 ("The Kit's stash has loot rules now").
- **Effort:** S–M

### 25. The Training badge is always lit: "36732 free". Code-checked
- **Where:** main.gd `_rail_status` BARRACKS adds `element_free` for every element (shown as "99+ free" each).
- **Why:** the points you can actually act on are "Drifter 0 of 49 · the Pitch 2 · the ring 0". A badge that never clears is ignored,
  and then real points get missed.
- **Change:** count only the class, Pitch and paragon pools. Show the elements as a dot only when a meter has just filled.
- **Effort:** S

### 26. The Clinic says "Hurt" at 1087 / 1088 HP. room_stats.png
- **Where:** main.gd `_rail_status` MEDIC (0.5 HP threshold).
- **Change:** "Hurt" below 90%, or when wounded. Otherwise nothing.
- **Effort:** S

### 27. The collection is a list you can't use. collection.png
- Unfound entries read "? · Charm" with no clue where they drop. Found names aren't clickable (what it does, where it came from). The
  Training ALSO strip shows "The mantelpiece 38 of 49" (and 38 of 52 in another shot) while the collection says "Uniques found 38 of
  52", which looks like the same count with different totals.
- **Change:** a source hint on unfound entries ("from a head in the City", "the Lineman"). A hover or press shows a found unique's
  card. Line up or rename the mantelpiece count.
- **Effort:** M

---

## F. Long-play irritations (30+ hours)

### 28. No bulk select in the stash. Code-checked
- **Where:** inventory.gd: "Select" mode exists, but "All n" (`_all_button`) shows only for shop buying.
- **Change:** "All on this page" and "All matching the filter" in Select mode for Sell, Bin and Ditch. Shift-click for ranges.
- **Effort:** S

### 29. Stash sort and filter are thin. Code-checked
- **Where:** inventory.gd `SORTS := ["Value", "New", "Slot"]`, a rarity cycle, no search.
- **Why:** 701 cells over 8–14 pages. You can't sort by dmg/s, armour or item level, filter "wearable now" or "upgrades only", or search
  by name.
- **Change:** add sorts (dmg/s or armour, item level, upgrade first), an "Upgrades" chip and a "Wearable" chip, and a name search like
  Training's "Find a perk".
- **Effort:** M

### 30. Sockets: 14 pages of identical "ATT ×10". workshop_sockets.png
- **Where:** `Data.SOCKET_STACK := 10`. The Workshop's Sockets view.
- **Why:** each stack tops out at 10, so hundreds of the same socketable take whole pages and stash cells. The tiles don't say which
  stat they carry.
- **Change:** raise the socket stack cap (or no cap). Group the view by type with a total ("+35% fire ×48"). Put the stat on the tile.
- **Effort:** S (the cap), M (grouping)

### 31. No mouse wheel or keys for paging. Code-checked
- **Where:** the stash and floor pagers (‹ 1/8 ›). Only the web and fight placement read the wheel.
- **Change:** the wheel and PgUp/PgDn page any pager under the cursor.
- **Effort:** S

### 32. No hotkeys or pad shortcuts for frequent actions. Code-checked
- Nothing binds rooms (1–9 or the shoulder buttons), Set off, Get out now, or the three fight skills. skill_bar.gd buttons are
  `FOCUS_NONE`, so a pad can't reach them at all. web_view is `FOCUS_CLICK`, so Training needs the trackpad.
- **Why:** Fiat is framed as active play ("Melvor-like") and Matt plays on the Deck.
- **Change:** an input map: 1–3 skills, Space Set off or Get out, Q/E (LB/RB) to change room, Esc/B to close or pause. Show the keys on the buttons.
- **Effort:** M

### 33. The radio ticker scrolls forever and repeats. Screenshots
- Every shot across hours shows "Kev here, on whatever this is…" and "Someone on the Parade's buying old tenners…". A scrolling strip
  runs above every room, the log runs below it, and toasts arrive too: three news channels.
- **Change:** drop lines once heard twice. Pause the scroll when there's nothing new. Add a Settings toggle (scroll, static, off).
- **Effort:** S

### 34. The log can't be read back. Code-checked
- **Where:** main.gd `_events` shows two lines, with no history.
- **Why:** "what happened to my pack?" has no answer once two more lines arrive.
- **Change:** click the log bar to open the last 100 lines (with filters: runs, loot, story).
- **Effort:** M

### 35. Settings are volume only. Code-checked
- **Where:** main.gd `show_settings` (volumes, room intros).
- **Change:** add window/fullscreen, interface size (item 7), the ticker (33), reduced motion, and a key list that also shows F8's hidden ×10 speed.
- **Effort:** M

### 36. Bulk actions give no feedback. Code-checked
- **Where:** sim `sell_rarity` and `sell` log nothing. Bin and Sell n only change the numbers.
- **Change:** a toast and log line: "Sold 280 commons · +1.9M tins".
- **Effort:** S

---

## G. Polish

### 37. Training at level 1 shows the whole six-class web. web_mid.png
- A new Poacher sees all six classes, every element and "Lv 20 / Lv 30" tags. The POINTS panel covers part of the web, and the web
  draws under the tab bar ("The cold · frost" is clipped at the top).
- **Change:** open on "The class's" until a second class opens. Let the POINTS panel fold. Clip the canvas below the tabs.
- **Effort:** S

### 38. Labels collide on the Training and Pitch canvases. room_training.png, room_the_pitch.png
- "The Rat Man · poison", "Blades · bleed" and "The Pitch · the Yard" sit under links and nodes. The Pitch's "rank 17" runs into the
  first node on the Kennel, Lookout and Generator spokes. The Pitch foot card reads "Deepest clear on each" with nothing under it
  (main.gd 1311: the note shows, the zone lines don't).
- **Change:** move the labels clear, and add a fit or overlap assertion for these labels against nodes (house rule). Drop the orphan caption, or show the lines.
- **Effort:** S

### 39. Training's words. room_training.png
- "Before: Drifter 3135, Drifter 3231, …" is a list of run counts with no meaning. "new" on every unplayed class card. "The class's"
  as a tab name. Thin 14 px "Find a perk".
- **Change:** "8 Drifters before you · the most runs 3,231". "Not played" for an unplayed class. "Class" for the tab.
- **Effort:** S

### 40. Language slips the smoke doesn't catch. Code-checked
- items.gd 999 returns "damage/s" (style guide: "dmg/s", never "damage/s"). It appears on every stash tile ("697 damage/s").
  barracks.gd 348 "Search %d%% faster" ("quicker" is the house word). The map's "Gear level" (the glossary says "item level"; "gear"
  is banned). "A rule 3" in older shots (now "Rule 3"). A full stop is missing from the two-sentence rules note.
- **Change:** fix the strings, and add "damage/s", "faster" and "Gear level" to the smoke's banned list.
- **Effort:** S

---

## Suggested order

1. Before the playtest (all S): 1, 3, 2(a+c), 5, 25, 26, 22, 40, 16 (check it).
2. Next: 4, 10, 11, 14, 18/19, 24, 28, 36.
3. Then: 7 (Deck size), 12/13 (one junk system), 21, 29–32, 34–35.
4. Polish as it comes: the rest.
