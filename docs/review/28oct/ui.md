# Review 3, stage 2: the UI (scripts/ui/*.gd), fe0fbef..HEAD

Read: the UI diff (4,154 lines over 24 files), the code in fiatnow/, and the screenshots (pitch_b, n_air_full, n_dial_pick, n_story_mid, n_town, pack_huge, training, exchange_a, run_mags, kit_rig, clinic_supplies).
Counts: A 8 (0 high, 3 medium, 5 low) · B 2 · C 4 · D 4.

## A. Bugs

### A1. Training's "Reset trees" button is live when the sim will refuse it (confirmed, medium)
- **Where:** barracks.gd:1045 (`_respec.disabled = sim.tree.is_empty() or ...`); barracks.gd:1218 (the clipboard write); sim.gd:3509 (the sim's refusal).
- **What:** the UI checks whether *any* node is in the tree. `sim.respec()` refuses unless the class has a node of its *own* (`not is_camp`). The tree also holds the Pitch, element and ring nodes, so a runner with only camp nodes gets a live button. The first press arms it. The second press copies the build code to the clipboard, overwriting whatever was there, and then nothing happens.
- **Player sees:** training.png shows exactly this case: "Reset trees for 0 tins", live, with Poacher at 19 of 19 free. Pressing it twice does nothing, gives no message, and replaces the clipboard.
- **Change:** `_respec.disabled = sim.points_spent() == 0 or sim.cash < sim.respec_cost()` (or the same `tree.filter(not is_camp)` test the sim uses). Copy to the clipboard only once `sim.respec()` has returned true.
- **Effort:** S

### A2. "Strip all parts" / "Strip all N" is live with a full stash, and a refusal is silent (confirmed, medium)
- **Where:** armoury.gd:334, workshop.gd:804; sim.gd:5520 (`strip` refuses without stash room) and sim.gd:5535 (`strip_all` returns [off, left], which both callers ignore).
- **What:** the button is enabled whenever the runner isn't out. With the stash full, `strip_all` takes nothing off, and with only partial room it takes some. The log line only appears when off > 0, and the UI never reads `left`.
- **Player sees:** they press "Strip all" and nothing happens, or two of four parts come off with nothing said on screen. The single "Strip" button beside it is correctly disabled on `stash_fits`.
- **Change:** enable it only when at least one part fits (`attachments.values().any(func(a): return a != null and (sim.stash_fits(a) or sim._stack_room(a)))`). After the press, toast or hint "%d left on: no room" when left > 0.
- **Effort:** S

### A3. The Fence's rate list shows a figure no trade gives (confirmed, medium; the UI misreports the sim)
- **Where:** fence_list.gd:79-95 (`exchange_worth`); sim.gd:1625-1635 (`exchange_rate`: spread taken off, the drift's upside capped "so it only goes against you").
- **What:** the side list is headed "TODAY'S RATES IN TINS" and shows each currency's *mid worth*, before the spread and with the upside drift included. The trade uses `exchange_rate`, which takes off 15% (less with Contacts) and never pays a ▲ drift on what you give.
- **Player sees:** exchange_a.png: the list says Notes "590 tins ▲22%", while the panel beside it says "1 note = 501 tins". A ▲ on the list reads as "a good day to sell", but the sim was built so selling on a ▲ day pays nothing extra.
- **Change:** show `exchange_rate(cur, "tins")` (what selling one gets) and base ▲/▼ on that against yesterday's rate. Or relabel the column "worth" and add "he keeps n%" to the note line. Matt's call on which (D4).
- **Effort:** S

### A4. The pack's drag picture is drawn at full cell size over a shrunk pack (likely, medium)
- **Where:** inventory.gd:634 (`t.size = ItemCell.px(f)`), inventory.gd:660 (`turn_live` uses `ItemCell.px`); the cells and the ghost use `pack_cell` (inventory.gd:404, 704-705).
- **What:** once the pack shrinks (cells at 28-40 px), a dragged 2x3 piece is drawn at the 64 px cell size, roughly twice the green or red ghost under it. The drop goes by the cell under the mouse, so the picture and the ghost disagree on where the piece lands.
- **Player sees:** on a big bag (pack_huge.png) the piece in hand covers about twice the cells it will take up. This is the "sorting a bag" case that motivated the change.
- **Change:** give `drag_preview(it, rot, cell := Pal.CELL)` a cell size, pass `cell_px()` from `_cell_input`, and keep it in a static for `turn_live`.
- **Effort:** S

### A5. The scrolling pack's page label sticks and its › does nothing at the bottom (confirmed, low)
- **Where:** inventory.gd:471-473 (`page = top_row / _view_rows`; `pages = ceil(reach / view)`); inventory.gd:1358-1360 (`_turn` scrolls a whole screen, clamped).
- **What:** take reach 25 rows with 10 in view. `top_row` maxes at 15, so `page` maxes at 1 and the label reads "2/3" at the bottom. "›" stays enabled, but `scroll_by(10)` clamps and nothing moves. From the top, one "›" lands on row 10 ("2/3") and the next lands on row 15, still "2/3".
- **Player sees:** with the Removal Van, a live arrow that does nothing and a page count that never reaches its last page.
- **Change:** `page = 0 if top_row == 0 else (pages - 1 if top_row >= reach - view else ceili(float(top_row) / view))`. Or compute pages as `ceil((reach - view) / view) + 1`, and set `_page_next.disabled = top_row >= reach - view`.
- **Effort:** S

### A6. The edge scroll keeps going after the drag leaves the pack (confirmed, low)
- **Where:** inventory.gd:716-737 (`_edge_dir` is set in `_can_drop_data` and cleared only at NOTIFICATION_DRAG_END or when no drag is on).
- **What:** `_can_drop_data` stops being called once the mouse leaves the pack. If the pointer was in the top or bottom half-row band when it left (dragging up to the tabs, or down past the grid), `_process` keeps scrolling a row every 0.25 s until the drag ends.
- **Player sees:** the pack runs away to its top or bottom while they hover over something else.
- **Change:** in `_process`, reset `_edge_dir = 0` when `not get_global_rect().has_point(get_global_mouse_position())` (or `_grid`'s rect). Alternatively, clear it on `mouse_exited`.
- **Effort:** S

### A7. The Workshop's Select-many "Scrap" button goes stale across a run's start or end (confirmed, low)
- **Where:** inventory.gd:310 (the signature has no `on_mission`); inventory.gd:385-387 (`disabled ... or (scrapping and sim.on_mission())` and the tooltip).
- **What:** the button's disabled state and its "Not while the runner's out" tooltip depend on `on_mission`, but `show_items` returns early on an unchanged signature.
- **Player sees:** come home with parts already chosen and the Workshop open, and Scrap stays greyed out until they change the selection.
- **Change:** add `str(sim.on_mission())` to the signature when `scrapping`. Also clear `tooltip_text` when the button isn't disabled.
- **Effort:** S

### A8. A Kit rig cell keeps an ammo pouch's tooltip after a med takes its place (confirmed, low)
- **Where:** containers.gd:133-136.
- **What:** `tooltip_text` is set only on the ammo branch. Rig cells are pooled by index, so when the rig's order changes (after a run, or Take/Leave) a med or grenade cell keeps "Rifle rounds · 3 magazines".
- **Change:** `c.tooltip_text = ...ammo... if Items.is_ammo(it) else str(it["base"])` (or the med words, as run.gd:1317 does).
- **Effort:** S

## B. Layout and fit risks

### B1. Standing 1 and 2 never say where they open (confirmed by width and screenshot, low-medium)
- **Where:** radio.gd:865-866.
- **What:** the first form, "Standing 1 · not open yet · the Relay on the Dial" (or "the whole band on the Dial"), needs about 360 px at 14 pt, and the slot's line is 293 px. `UI.fit` falls back to "Standing 1 · not open yet". The filter's shorter form, "Clear air on the Dial", fits.
- **Player sees:** n_air_full.png: the filter says where it opens; the two standing codes don't, so the hint added today only reaches one of the three.
- **Change:** put the opener on the slot's big line, which is free while shut ("Shut · the Relay on the Dial" at 18 pt, about 250 px). Or add a middle form, "Standing 1 · the Relay, on the Dial".
- **Effort:** S

### B2. A cure in a one-cell pouch reads "MED / Stops" (confirmed by screenshot, low)
- **Where:** item_cell.gd:437 (the 1x1 words take `h[0]` from `Items.headline`).
- **What:** a cure's headline starts "Stops …", and a single cell shows only its first word.
- **Player sees:** kit_rig.png and run_mags.png show "MED Stops", and the Clinic's shelf (clinic_supplies.png) shows two of them. You can't tell which element a cure stops without hovering, and on a run the rig is where you'd want to know.
- **Change:** for `Items.is_cure(it)`, make the second word the element (`str(Items.cure_of(it)).capitalize()`), and tint the cell in the element's tone as item_head's chip does.
- **Effort:** S

Checked and fine at 1920x1080 (no finding):
- **Radio:** the left column comes to 916 exactly. The signals column at its tallest (three held, six crews in two rows) is 702 of 728. The book's 3x5 cards and the "Still to learn" row fit in 536.
- **The Pitch:** detail panel ends at 634 with Build at 660. Cards and lines fit, and the Gives rows end at 310 of 424.
- **The exchange:** 7 rows by 2 currencies, plus the amount row, fit.
- **The Fence's list:** 12 rows plus the mate fit.
- **Clinic:** the supplies strip clears three wound rows and the note by 16 px.
- **The Dial:** the panel's buttons sit under the title row.
- **Hit areas:** all new labels are created with MOUSE_FILTER_IGNORE (UI.label's default), and Dashed is IGNORE. Dial filler keys are unique, so the tile toggle can't pick a twin.

## C. Lost or inconsistent

### C1. "Bin at the Clinic" isn't reachable on screen (confirmed, low)
- **Where:** vendor.gd:256 sets `_stash.binning` for the Clinic. vendor.gd's show_state keeps the Clinic's stash grid hidden (`_stash.visible = showing == "stash" and kind != "clinic"`); its second tab is the med cards.
- **What:** the agreed "Bin in the Clinic" has no surface. That's harmless, but the line is dead code and the agreement doesn't match the game.

### C2. The Dial lost its node glyphs; pictures only show in the panel (confirmed, low)
- **Where:** map_web.gd rewrite; atlas.gd:216-222.
- **What:** the old web drew `NodeGlyphs.of_atlas` glyphs and painted pictures on every node. The tiles are now words only, and a picture appears at 88 px in the panel only when one is painted (4 map_ art files exist). The region focus buttons and `focus_column` went too. Nothing calls them, and with every node now on screen they aren't needed.
- **Player sees:** the Dial no longer shares Training's visual language of glyphs on nodes. That's fine if intended.

### C3. The Pitch dropped the town note and its pictures; yard_web.gd is now dead code (confirmed, low)
- **Where:** yard_tree.gd; main.gd:1429 still builds `left.note`, and nothing reads it.
- **What:** with nothing picked, the old strip said "Heads down open the next" (or "Deepest clear on each"). That line no longer appears anywhere, though it's minor. yard_web.gd (and web_view.gd's comment naming it) remain, unused; tools/make_generator_energy_manifest.py still says "yard_web finds them".
- **Change:** delete yard_web.gd, or say so in CLAUDE.md. Drop `left.note` from `_town_purse`, or show it in `_status`.

### C4. A box of rounds found on a run can't go into the rig any more (confirmed; intended by the magazines design?)
- **Where:** run.gd:907-910 (no "Take into the rig" for an ammo box from the pack).
- **What:** before today, a found box could be taken into a free pouch mid-run. Now it only says it fills the magazines at home.
- **Player sees:** a dry gun and a box in the pack, with nothing to press. This is a loss of capability if Matt didn't mean it; see D.

## D. For Matt's call

1. **Select-many in the Kit room now always bins, for nothing, with no "press again".** armoury.gd:176; inventory.gd:883-901. Before today, with the Fence open, the same button in the same place sold. Uniques and set pieces are kept out, but a rare piece goes with one press. The single-pick bin asks twice for a unique; the many-bin never asks. Suggest the Arm (press again) on "Bin N", as the Fence's rarity Sell has. Effort S.
2. **The exchange can't reverse a pair in one move.** fence_exchange.gd:708-709 disables, on each side, the currency picked on the other. Going from notes→tins to tins→notes takes three presses (get→scrap, give→tins, get→notes). Either let a press on the other side's pick swap the two (show_state already re-picks when they match), or add a ⇄ button. Effort S.
3. **The reset follows the node picked.** The class-trees reset only shows with nothing or a class node picked. The Pitch's needs a Pitch node; an element's needs one of its nodes. The button's words change, but nothing on the panel tells a player that the Pitch and elements have their own resets until they pick one. A one-line hint under "Reset trees", or a small key, would fix it. Agreed with Matt as designed, so it's flagged for discoverability only.
4. **The Fence's list figure (A3).** Show what a sale gets today (after the spread, upside capped), or keep "worth" and explain the spread. Then ▲/▼ on the list should mean what the panel's ▲ means.
5. **C4.** Should a found box still be takeable into a free pouch mid-run, or is home-only filling the point of magazines?
