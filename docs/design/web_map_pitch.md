# The Map's web and the Pitch's web (22 Oct 2026) — the design (Matt: "build it all")

Matt (22 Oct): the Map's atlas, the Radio's codes and the Pitch's buildings become pathed webs with real choices —
"do you path into loot quality or signal strength; do you make the stash bigger or more useful". The same canvas as
Training's (web_view: pan, zoom, pick, a path hint, Find), each room its own small web.

## 1. The Map's web (the atlas and the Radio's codes in one)

Three regions off a centre, the Dial's points as now (one a point; a reset for tins as now). Pathing replaces the
column gates (ATLAS_GATES go); a node with ranks is a stack (a point a rank, as the ring's nodes); fillers between.

- **The sites** (left). The spine: Picked over → Second look → Local knowledge (notable) → The lie of the land
  (keystone, the region's end). Two branches off it, one each side: *the quiet way* — Quiet roads → Open ground
  (notable) → Short cuts → Worn in; *the rich way* — Deeper pockets → Easy pickings → After dark (notable) → Every
  tin. Fillers (one stat, 3 a branch): Searches 3% quicker · Gangs come 3% later · Drops +3% · Tins +3%.
- **The crews** (right). The spine: Paid in notes → Their own kit → Marked men (notable) → The lorry's route
  (keystone). Branches: *the heads* — Heads up → Two of everything → Full strength (notable) → Long memory → Heads
  roll (notable); *the pay* — Wages → Bounties → Heavy crews (notable). Fillers: XP +3% · +1 note a kill · Tins +3%
  · Drops +3%.
- **The codes** (down: the Radio's). The spine: Good reception → Clear air → Long wave (notable) → The whole band
  (keystone). Branches: *the quality* — Tip-offs → Booster → Strong signal → Bent (notable); *the reach* — Early code
  → Held frequency → Relay (notable). Fillers: Crafts −5% · Codes pay +3% · Call in −5% · Loot quality +2%.
- The Radio room keeps its own screen (the codes, the book, Set off); its Juice chip opens the Map's web focused on
  the codes. The Map's card column stays; the atlas tab becomes the web.
- Counts: 35 nodes as they are (their ranks as stacks, their figures as they are) + 29 fillers = 64. A region's
  keystone wants MAP_KEYSTONE_POINTS (10) points in the region (the review: pathing alone put it three ranks in).
- As built: the three regions out from a centre at their angles - the sites left, the crews up and right, the codes
  down and right - the star, as Training's (Matt: "same layout so it's consistent for a player"); a filler's share
  reads into its ranked node's figure (Sim.atlas_level).

## 2. The Pitch's web (the Yard)

The eight buildings as eight regions off the centre (the Pitch), each a spine of its five ranks with a fork at
every rank: the two picks of that column, one or the other, as now. Tins and salvage pay as now (a rank its cost,
a pick free with its rank, as now); nothing's cheaper or dearer. What changes is the shape and the reading:
- A building's spine runs out from the centre: rank 1 at the join, rank 5 at the end; a pick hangs off each rank on
  its side (A left, B right), the other dims once one's taken ("Shelving, or Racks: one of the two").
- Fillers: none (the Yard's steps are its ranks). 8 × 15 = 120 nodes.
- As built: the picks keep their column gates (the campaign and the depth open a column, as before - the Yard's
  pacing); a column's two picks each link to both of the column before, so the lane reads as forks; the ranks a
  chain past the fifth column, the fifth node every rank from the fifth on. The eight lanes out from the centre at
  45° each, the star as Training's, the names past the lanes' ends.
- The Yard room keeps its building cards (the costs, the salvage, Build); the lanes under them become the web.

## 3. The canvas, shared

web_view takes a "web" (regions, nodes with at/links, a pool reader, a train call) instead of Sim's trees: the
Training web, the Map's and the Pitch's are three instances. A node's panel under the canvas as Training's: name,
chip, sentence, the Train/Build button, the block in words.

## 4. The sim

- Map: `atlas` stays {key: rank}; `atlas_block(key)` is the pathing (an entry, or touching a ranked node) and the
  points; the fillers are atlas nodes too (`Data.ATLAS` grows by the 24, each with "at"/"links"). ATLAS_GATES go.
- Pitch: `yard_picks`/`yard_ranks` stay; the web reads them; a pick's node is open when its rank is bought.
- SAVE_VERSION stays (the shapes don't change); the atlas's saved ranks read as they are.

## 5. The slices

4b the Map's web (data, pathing, canvas, the Radio's chip), 4c the Pitch's web (canvas over the Yard's model). Mockups
of both boards on the canvas first, rendered and checked.
