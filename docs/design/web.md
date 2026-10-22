# The web: one skill tree for the camp (22 Oct 2026) — the design spec

From Matt's playtest of the Scrapper: "the current nodes are just an A to B rush with zero choice other than what
element to spec into." Path of Exile's passive tree as the model: one web, pan and zoom, a node bought by pathing
to it, fillers between the notables so every level is a decision. Replaces docs/design/trees.md's lanes (the
joints, the gates' spirit and the nodes designed there carry over; the layout and the pools don't).

Agreed with Matt (22 Oct): one web; the class is the runner, the web is the camp's; element nodes earned on a use
meter, not bought; a class can path into another class's region from level 30 (the second past, reskinned); full
access to every element (the pair gates go); 500 nodes and up, more notables rather than more filler; a keystone
choice per class.

## 1. The shape

The Pitch at the centre. Round it the five elements, a region each, joined to the Pitch. Round the outside the
five classes, a region each, joined to its pair of elements where the joints are now (Scrapper: Live and Petrol;
Poacher: the Rat Man and the cold; Paramedic: the same two; Doorman: Blades and Knuckles; Drifter: Petrol and Live).
Between neighbouring class regions, a bridge that opens at level 30 (§4).

```
                 Scrapper
          Live  ----------  Petrol
    Drifter   \   PITCH   /   Doorman
          Knuckles -- Blades
     Poacher  / the cold \  Paramedic
                Rat Man
```
(a sketch of the adjacency, not the drawn layout: the mockup on the canvas "Fiat – The web" is the drawn one)

- A **region** is a cluster: its entry node at the join, the lane's old nodes as its notables and keystones, fillers
  between them, and branches so there are two or three ways through.
- **Live for the runner out**: every allocated Pitch node, every allocated element node (any element), and the
  runner's own class region. Another class's region is dark unless bridged (§4). So a level-30 fire Drifter's Petrol
  and Pitch work for a level-1 Paramedic brought out after.
- **Pathing** (PoE's rule, within a region): a node can be taken only if it touches an allocated node, counting
  from the region's entry. The Pitch's entry is its centre; an element's entry is its join to the Pitch; a class's
  entry is its join to its first element. The joints are nodes on the web like any other: a class's conversion
  notable sits on the bridge between the class region and the element, and is the way in from either side.

## 2. The nodes

| Kind | What it is | Today | Added | Drawn as |
|---|---|---|---|---|
| Filler | one stat: HP +4%, damage +3%, pace +2%, regen +0.2/s, armour +4, find +2%, search 5% quicker, a resist +3% | 0 | ~250 | a small dot, the stat's glyph |
| Notable | a named effect with a sentence | ~120 | ~40 | a disc |
| Keystone | a build-defining rule, level 20 | 16 | 5 (the choice) | a framed icon |
| Capstone | a region's end, level 30 | 17 | 0 | a large framed icon |
| Paragon | past level 50, the outer ring (§6) | 5 board nodes | ~30 | a ring node |

Counts a region: a class ~50 (its two lanes' 24, 6 new notables, 20 fillers), an element ~32 (its 12, 4 notables,
16 fillers), the Pitch ~47 (its 11, 6 notables, 30 fillers), the paragon ring ~30. About 520 in all.

- **The keystone choice**: each class region ends in three keystones on three branches (its two today and one
  new), and only one can be allocated; taking a second unallocates the first (a respec of that one node, free).
  The new one per class, to design with Matt: a build the class doesn't have yet (the Scrapper a scrap build, the
  Poacher a trap build, the Paramedic a stim build, the Doorman a shield build, the Drifter a luck build).
- Fillers are cheap on purpose: a class's 20 are its levelling, the two-a-level a PoE path feels like. A filler's
  figure is the smallest step of its stat; the notables carry the build.
- A node's words and figures as they are: the detail strip at the foot shows the picked node, its cost and Train.

## 3. The points: one currency a region

- **Class points**: one a level of the class, spend in that class's region only (and over its level-30 bridge, §4).
  A death refunds the class's region as now.
- **Pitch points**: one a level of the crew's best class, spend in the Pitch only. Never refunded, never reset by a
  class change (as now).
- **Element points are not bought.** Each element has a **use meter**: damage dealt in that element (conversion,
  grades, the element's own effects) fills it; every ELEMENT_METER (a figure for the pass: the damage a run deals
  at the element's share, scaled to the site's level so the meter is runs, not numbers) it grants one element
  point, spent in that element's region, by the player, pathing as any other. A fire build earns fire nodes by
  burning things; a frost dip earns a few frost nodes. The Training screen shows each element's meter on its
  region's entry ("Petrol · 3 points free · the next in 2 runs").
- **Paragon points**: XP past 50 as now, spent on the outer ring (§6).

The pair gates go: any class can path any element's region to its end. What stays is the joint: the class's
conversion notable is only in its own region, so a Scrapper gets all of frost's nodes but not a frost joint. And a
keystone no longer waits on a joint: the path reaches it (slice 1: a column of class halves is bypassed by a link
two columns long); the joint's payoff still wants both halves.

## 4. Another class's region: the second past, reskinned

At level 30 a class may take the bridge into one neighbouring class's region (the two regions that touch its own
on the ring: the Scrapper's are the Drifter's and the Doorman's); the bridge node costs 3 class points and names
the pick ("The second past · the Doorman's"). From there the class spends its own points in that region, which
then counts as live for it. One bridge a class. A respec of the bridge refunds everything past it.

## 5. The screen

- The Training room's body is the canvas: the web drawn at a scale, right-drag pans, the wheel zooms (three
  stops: the whole web, a region, a cluster), left-click picks a node for the foot strip. The header strip stays
  (class, points free by pool, the five class cards); the Also row stays for the drawer, the shelf and the Wireless.
- A region's name floats over it at the whole-web zoom; the nodes' names show from the region zoom; a picked node
  rings; the path it would take from the nearest allocated node highlights on hover (PoE's shortest path).
- The Map's atlas and the Pitch's buildings get the same canvas, each a small web of its own, in a second slice.
- Node art is now needed, not nice: a glyph a notable and keystone, and a glyph a filler stat (eight). In the art
  manifest (status.md's parked item 6).

## 6. Paragon

The board goes; the ring stays. Past level 50, paragon points buy the outer ring's nodes (damage, HP, resists,
find, tins, as the board's five were, as ~30 ring nodes with the same caps), pathed round the ring from any class's
entry. A reset for tins as now.

## 7. The sim and the save

- A node's id becomes "region/name"; `tree` stays the list of allocated ids, the camp's. What's live for a runner
  is a filter over it (§1), computed once a kit key.
- `Data.WEB`: regions, their nodes with `at` (x, y on the region's grid) and `links` (ids), replacing TREES' cols and
  rows. The lanes' gates (CORE_GATES, ELEMENT_GATED_COL, JOINT_COL) go; the level gates for keystones (20) and
  capstones (30) stay.
- The use meters: `element_xp` {element: float}, `element_points` {element: int}, saved.
- SAVE_VERSION up. No conversion (the rule).
- The bot: trains by pathing to the notables its build names, fillers on the way; the balance harness reads the
  class's points spent and the element points as before.

## 8. Balance

The fillers move every number: a level-30 runner carries +40-60% damage and HP from fillers alone, on top of the
notables. This is the feature change that triggers the next pass (the rule: everything that changes numbers in,
then one pass): the hostile curve, XP_SCALE and ILVL_GROW read against it. The gates stay; the use meters get one
(an element build's region filled by the Quartermaster).

## 9. The slices

1. The model and the canvas: Data.WEB with today's nodes laid out as regions, the Training canvas (pan, zoom,
   pick, Train), one currency a region as today's pools, the pair gates gone. No new nodes. Smoked and playable.
2. The fillers and the new notables, the keystone choice.
3. The use meters, the camp-wide allocation (a class brought out reads the camp's elements and Pitch), the bridge.
4. Paragon folded into the ring; the Map's and the Pitch's canvases.
Mockups on the canvas before slice 1; the art manifest alongside slice 2.
