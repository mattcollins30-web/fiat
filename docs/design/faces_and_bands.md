# Faces, the top bar, glyph lanes, room bands, Stats and the runner backdrop (10 Oct 2026, concept - not built)

Six UI items from Matt's 10 Oct playtest, agreed with him the same day (5 and 6 waiting on his pick). Each has a board on the design canvas.

## 1. Faces beside the boxes (Run-P A)

From Matt: the Carpet Man's art sits over the fight box. The stat boxes get smaller so a face fits to their left,
for both the enemy and the runner. Ordinary gangs get generic portraits, which Matt will reuse from Greenhorn.

- The fight box and the runner box take the same shape: a **96 px face on the left**, the four stat tiles
  narrowed to its right, and the bar and chips underneath. Neither box changes height.
- The fight box shows the head's own portrait while a head is out (`art/people/<head slug>.png`, as the Carpet
  Man, the Manager and the Quartermaster have now). Otherwise it shows **the zone's gang face**. Proposed files:
  `art/people/gang_the_estate.png`, `gang_the_town.png` and `gang_the_city.png`, from Matt's Greenhorn set,
  cropped square. With no file, the box shows a drawn silhouette.
- The runner box shows the runner's class portrait (`art/people/<class>.png`, as now).
- The head's name joins the fight box's kicker (*THE FIGHT · THE CARPET MAN*). The floating portrait that
  overlaps the box goes.
- Test: the smoke's fit sweep runs over both boxes with a face in, and a check confirms the face never overlaps a
  tile.

## 2. Currencies on the top bar (Bar-C)

From Matt: put scrap and the other currencies on the top bar. Agreed: **scrap, plus each salvage kind once
found**.

- The top bar runs, at one gap: the place, then notes (as now), scrap, then copper, safe steel and army surplus
  once there's any of each. Each currency has a line glyph in its own tone and its count, and the cash sits last.
- Before any salvage (the whole campaign) the bar shows notes and scrap only.
- Hover or click names the currency. The Yard's purse chips say what each one buys.
- Glyphs are drawn in engine (SVG, in `node_glyphs.gd`'s way), so no new art is needed.

## 3. The Yard and the Map in the tree's glyphs (Lanes-G)

From Matt: the Yard and the Map look bad next to the new tree. Agreed: **the same treatment as the tree**.

- **The Yard**: each building is a lane, and its five columns are pairs of glyph tiles (the A and B picks).
  - The built tile is lit gold and its partner dimmed.
  - The buyable tile is white, with its price on the corner chip.
  - Shut tiles are dim.
  - The building's rank shows as five pips at the lane's end.
  - The words, the price and *Build* sit in the strip underneath, as in the tree's panel.
  - Each lane drops from 92 px to 64 px.
- **The Map**: three lanes of glyph tiles with rank pips under each tile. A one-rank node is round. Its words sit
  in the strip.
- Glyphs come from `node_glyphs.gd`, with new keys for the Yard's buildings and the Map's nodes. Tiles, rails and
  the cost chip reuse barracks.gd's `node_rect`, `_style` and the `more` label, so all three trees share one look
  and one set of smoke checks (the glyph sweep and the diamond extent).

## 4. Art bands for the rest of the rooms (Rooms-B)

From Matt: replicate the Clinic's and the Fence's bands for every other room. Agreed: **Training, the Workshop,
the Radio, the Yard and Stats**.

| Room | Today | The band | New art |
|---|---|---|---|
| Training | 96 px header (face, points) | 110 px band; the class buttons stay at its right; lanes lose 14 px (LINK_H 22 → 18 and the gaps) | `art/places/the_caravan.png` |
| The Workshop | 96 px heading | 96 px band; the view tabs and chips stay in it, right | `art/places/the_workshop.png` |
| The Radio | 84 px heading | 96 px band; the list underneath 12 px shorter | `art/places/the_radio.png` |
| The Yard | heading (purse chips, the town) | band; fits because the glyph lanes are shorter | `art/places/the_yard.png` |
| Stats | none | 96 px band over the eight cards (each 48 px shorter across two rows); the runner's face at its left | `art/places/the_stats.png` |

- Built (10 Oct): each heading keeps its height and its layout and takes its painted place under its words
  (`UI.head_art`: covering it from the centre, shaded from the left, the words with a shadow); Stats has its own
  short band. The plain card while a file is missing.
- Each band uses `band.gd` as the Clinic's does: the art covers the band from the centre, the shade comes from
  the left so the words read, and the room's headline figure shows in gold. A missing file keeps the drawn
  skyline.
- The five jobs are in `tools/pixellab_rooms_manifest.json`, in the places style: 688×296, the site style image,
  the left third and the bottom quarter kept dark and low-detail. Run it as the places manifest was run.

## 5. The Stats room reworked (Stats-R)

From Matt: Stats is the one room that looks like a sample Godot project. Keep the information it has now.

The problem today: eight cards of the same shape, all grey rows, so nothing leads the eye. The Kit card also
repeats what the Runner room shows. Both options keep every figure, but each part gets the picture that suits it:

- **Attack**: the damage as a chain showing where it comes from (guns → level → affixes and the tree → past →
  the total, each bar growing from the last), the element split as one bar, and the notes as chips.
- **Defence**: max HP and armour % as headlines, with an armour bar. The five resists are bars against the 75%
  cap. A resist at 0% is red, with a red dot, when the sites here use that element.
- **Finds**: loot quality as the headline; quantity, cash and notes as bars.
- **The record**: four trophy tiles (best run's kills, most damage, best take, dearest find).
- **Last run**: as now, with a green or red edge for back or lost, and the wound as a pill.
- **The wall**: one plate per past runner, from `sim.past` and `sim.retired`. Each plate has the class face
  (greyed if the runner was lost), the level, the runs and how they ended. Empty slots are dashed.
- **The Kit card goes**. Its worth moves into the runner's facts.

**A · the sheet**: the Rooms-B band on top, then three rows. Row one is the runner, attack and defence; attack
and defence are the tall cards. Row two is finds, the record and the last run. The wall runs along the bottom.

**B · the runner and the sheet**: no band. The runner's full figure (`art/body.png`) stands down the left on the
Runner room's backdrop (section 6), with their facts underneath. The cards sit to the right, and the record and
the wall share one card.

## 6. A backdrop behind the runner (Kit-B)

Built (10 Oct): the drawn light (B) alone - Matt: "remove the art and just use the fall back lighting"; the
kit-room job left the rooms manifest. A below is the concept as it was.

From Matt: a semi-transparent backdrop behind the Runner room's figure and gear slots.

- **A · a painted place, the slots as glass**: a painted lock-up wall at about 40%, darker at the edges. The slot
  fills let about a fifth of it through, so the figure and the kit read as one scene. The panel gets a hairline
  frame. The art is `art/places/the_kit_room.png`, a job in `tools/pixellab_rooms_manifest.json`.
- **B · drawn in engine**: a cone of cold light from above and a shadow at the feet (a gradient and two blurred
  shapes). It needs no art and is A's fallback while the art file is missing.
