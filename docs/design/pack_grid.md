# The pack as a real grid

Agreed with Matt on 27 Oct, after the playtest's screenshot: a 9/9 pack holding a jacket, and 21 empty outlines
drawn under it. The pack counted cells but the grid placed them, so the two disagreed. Mockup: the endgame canvas,
"The pack as a real grid".

## Matt's calls

- **True tetris.** A piece's shape matters as well as its cells.
- **The pack only.** The stash stays a flow, first-fit, sorted.
- **Rotate.** Pieces turn. The bot packs with the same packer as the game.
- **No room waits on the floor.** By hand, the game never swaps for the player.
- **Each pack its own shape,** never under 5 wide, so a long gun lies flat.
- **The start bag** is 5x3: 15 cells, a rifle or a vest.

## The rules (scripts/sim/sim.gd, "the pack as a grid")

**Shape**

- A bag's `w` (data.gd) is its width. Its `capacity()` cells run row by row, so the last row can be short.
- The Removal Van, the nodes, the town and the tree add cells, which means more rows.
- No bag is wider than `PACK_MAX_W` 13 (the screen's columns).
- The rows come in pages of `PACK_PAGE_ROWS` 7, and a piece never lies across a page's edge.
- No bag at all gives a 2-cell pack, 2 wide.

**Pieces**

- Each piece carries `"pos"` [x, y] and `"rot"`. Turned, its footprint's sides swap.
- `pack_spot` returns the first place a piece fits, row by row: lying as it is first, then turned.

**Finds**

- **By hand:** placed if there's room, else to the floor.
- **Auto, or the bot:** placed, or, for a find the pack keeps, the place of the cheapest piece that isn't kept and whose removal frees room for it by shape. Up to `PACK_SWAP_TRIES` 12 pieces are tried, those at least its size first.
- **Forced** (a head's unique, the wearing-off, the first gun, issued kit): appended and placed lazily by `_pack_settle`. If it doesn't fit, it's **strapped** on: carried and drawn past the rows. It goes in once room is made. A mythic with no room is strapped on too.

**Moves**

- `pack_move(id, x, y, rot)` moves a piece within the pack.
- `take_floor(id, [x, y, rot])` drops a piece from the floor at a cell.
- `put_down(id)` moves a piece from the pack to the floor, by hand only. It isn't allowed for the runner's own rounds or the deeds.

**Bags and pieces worn**

- Putting on a bag mid-run needs everything carried to fit its shape (`_pack_all_fit`). The pack is then repacked, biggest first.
- Any other piece put on from the pack gives its place to what comes off, where it lay first if that fits.
- A change of shape, `[pack_w, capacity]`, repacks the pack.
- A place that doesn't hold up (off the bag, across a page, on another's cell) is forgotten and the piece re-placed.

**Saves and the end of a run**

- The save keeps where everything lies. JSON's floats are turned back into ints on load.
- At the extract, a time-out or a death, the places are forgotten (`pack_off`). Home, the stash lays pieces out its own way.

## The screen (inventory.gd `pack_mode`, run.gd, crates_panel.gd)

- The grid draws `pack_w()` columns and exactly the page's cells as outlines.
- Each piece is drawn at its place, turned pieces with their picture a quarter round (`ItemCell.set_turned`).
- **While dragging:**
  - a ghost of the footprint shows green where the piece lies and red where it won't;
  - R or the right button turns the piece in hand;
  - a drop where it won't lie toasts "It won't lie there".
- **Dragging to and from the floor:**
  - A piece dragged from the pack onto the floor's row is put down.
  - A piece dragged from the floor to a cell is taken there.
  - A double-click takes a piece to its first place.
- The sort button hides in pack mode, because the pack's pieces lie where they lie.
