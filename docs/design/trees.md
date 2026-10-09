# The trees: lanes and joints (9 Oct 2026) — the build spec

From Matt's playtest: the element trees sat behind one arrow under the core tree ("I totally forgot they
existed"), and "other than a few points here and there there's no real cohesion between skill points for
the classes and then the elemental ones". Last Epoch's layout as the model: left to right, some
verticality, several trees at once. Agreed with Matt: layout A (Trees-A on the canvas), the joints table
below, a class change that costs, and the points high-water mark in place of level-locked gear.

## 1. The layout: every tree a lane on one screen

- Training is a header strip (class, points free, trait, the five classes), then lanes, then an "Also" row,
  the sum chips and the detail strip at the foot.
- A lane is one tree read left to right: a label block at the left (name, whose it is, points in it, the next
  gate), then **six columns of two rows**. Eleven nodes: two in each of the first five columns, the capstone
  alone in the sixth.
- The lanes, top to bottom: the class's first tree, **the element it joins**, the class's second tree, the
  element it joins, the Yard's tree. A class tree sits directly over the element its joint is in, so a joint is
  a short link between neighbouring lanes in the same column.
- **Also** (one compact row): the element trees off the class's pair, the second past's tree (from level 30),
  the drawer and the shelf. Each is a named chip; a click swaps the Yard's lane for it, a second click puts the
  Yard back. Nothing is behind an arrow; everything is named on screen. (Built: the drawer and the shelf take
  the lanes' whole area as three columns of cards, a page at a time - a paper's words don't fit a tile - and
  their chips carry the count, "The drawer · 12 of 20 · page 1 of 2".)
- The detail strip keeps its job: a tile carries a name and one figure; the strip carries the whole sentence,
  the cost and Train / Respec.

| Class | Lane 1 | Lane 2 (joins lane 1) | Lane 3 | Lane 4 (joins lane 3) | Lane 5 |
|---|---|---|---|---|---|
| Drifter | Moving on | Petrol | Luck | Live | The Yard |
| Scrapper | Stripping | Live | Fencing | Petrol | The Yard |
| Poacher | Stalking | The rat man | Snares | The cold | The Yard |
| Paramedic | Triage | The rat man | Shifts | The cold | The Yard |
| Doorman | Muscle | Blades | The door | Knuckles | The Yard |

No class picked yet (a new runner): the Yard's lane and the Also row only.

## 2. The columns: gates instead of chains

- A node needs only **its column open**. A column opens on the points spent in **that tree** (Last Epoch's
  rule), so a deep node cannot be bought with a dip. The `needs` chains go.
- Cost by column: 1, 1, 2, 2, 3 points; a notable +1, a keystone +2. The capstone keeps its rule: a third of
  the rest of its tree, rounded up, and it needs the tree's keystone and every notable.
- Gate for column *c* = ⌈0.6 × the cost of every node in the columns before it⌉ — most of what comes before,
  never all of it, so there is always a choice in what to leave. Computed per tree, not hand-set.
- Where each tree's eleven go (by today's index): column 1: 0, 1 · column 2: 2, 4 · column 3: 3 (the notable),
  5 · column 4: **the joint half**, 7 · column 5: the keystone, the other notable · column 6: the capstone.

## 3. The joints

A joint is two notables in **column 4** of two neighbouring lanes. The class half is the class tree's
conversion notable (it exists in nine of the ten trees today); the element half is a new class-only notable in
the element tree. Each half works alone; with both trained the joint **closes** and adds the payoff.

**The rule that makes a build:** an element tree's last two columns (its keystone and capstone) need a closed
joint in that tree. An off-pair element has no joint for this class, so it stops at column 4: a dip, double
cost, not a build. The second past's first tree brings its own class half, so a second past can close a joint
in its own pair.

| Class | Element | Class half (tree) | Element half | Joined |
|---|---|---|---|---|
| Drifter | Fire | Petrol bomb (Moving on): 15% of hits as fire | Drifter's can (Petrol): +25% fire from SMGs | Your bursts ignite; burning gangs take 25% more from SMGs |
| Drifter | Shock | Jump start (Luck): 15% as shock | Drifter's leads (Live): +25% shock; shocked gangs come 10% later | A shocked kill's drop rolls its rarity twice |
| Scrapper | Shock | Live wire (Stripping): 15% as shock | Scrapper's mains (Live): +25% shock from improvised guns | Every hit from an improvised gun shocks |
| Scrapper | Fire | Blowtorch (Fencing): 15% as fire | Scrapper's torch (Petrol): +25% fire; burns last longer | A gang killed while burning drops a find; finds sell for 20% more |
| Poacher | Poison | Rat bait (Stalking): 15% as poison | Poacher's bait (The rat man): +25% poison from rifles | Your first shot on a gang lands its poison at full stacks |
| Poacher | Frost | Cold snap (Snares): 15% as frost | Poacher's snare (The cold): +25% frost; chilled gangs come 10% later | Every gang arrives chilled, and one head short |
| Paramedic | Poison | Syringe (Triage): 15% as poison | Paramedic's dose (The rat man): +25% poison | Using a med doses every gang on you with five stacks of poison |
| Paramedic | Frost | Ice pack (Shifts): 15% as frost | Paramedic's ice (The cold): +25% frost | Chilled gangs do 30% less to you; meds heal 20% more while any are chilled |
| Doorman | Bleed | Glassing (Muscle): 15% as bleed | Doorman's glass (Blades): +25% bleed from shotguns and melee | Every shell and swing opens a bleed; bleeding gangs do 20% less to you |
| Doorman | Physical | Hands on (The door, new): +20% physical from shotguns and melee | Doorman's knuckles (Knuckles): physical ignores 20% of their resist | Every shell and swing staggers: the gangs on you fire 25% slower |

Figures are first figures; the balance pass at the end of the playtest list sets them.

## 4. Knuckles: the physical tree (new)

Physical is the share of a hit that is not converted. Knuckles scales it, as Petrol scales fire. Its pair is
the Doorman's; any other class can dip it at double cost to column 4. A melee or unconverted shotgun build
has a lane of its own.

| Column | Row 1 | Row 2 |
|---|---|---|
| 1 | Bare hands: +10% physical | Wraps: +5% armour |
| 2 | Half a brick: +15% physical | Thick skull: +5% armour |
| 3 | ★ Stagger: +30% physical; hits slow their fire 10% | Weight behind it: +12% physical |
| 4 | ★ Doorman's knuckles (the Doorman's half) | Knuckle-duster: +20% physical |
| 5 | ◆ Bust them up: physical ignores their armour and resist; no conversion lands | ★ Heavy: physical does 40% more; pace −15% |
| 6 | ◆◆ Flattened: a kill with physical staggers the next gang for two seconds | |

## 5. A class change costs

Changing class gives the old class's trees back as points and **costs the respec price of what it gives
back** (those points × the respec rate, inflated as the Fence's prices are). The class buttons take two
presses: the first arms the button and the header reads "Change to Poacher: £1,240 — press again". A runner
with no class yet picks for free. Element trees in the new class's pair stay trained; a joint whose class half
went reopens, and an element tree's keystone and capstone, if trained, stay but stop working until a joint
there closes again. (Built, after the review: an element **off** the new pair, and another class's half in an
element tree, come back as points too and are in the price - kept, they would have cost double and could leave
the points free below nothing. A change to the second past's class is refused.)

## 6. Points: the camp's high-water mark

Today a new runner starts at level 1 and every level gained adds a point to the camp again, so dying and
re-levelling grows the pool without end. From this pass a level earns a point only when it is above the camp's
**best level** (`best_level`, saved): a new runner re-levels for nothing until they pass the old best. The
moves' points (`MOVE_POINTS × yard_moves`) are unchanged. This replaces level-locking gear (Matt, 9 Oct).

## 7. Saves

Node ids are `Tree/index` and the indexes move with the columns. A save whose layout is older than this pass
has its trees refunded to points once on load (the log says so), and `best_level` starts at the save's level.

## 8. The smoke

- Every lane fits; every tile's name and figure fit; the lanes match the class's table row.
- The gates: a column-5 node can't be trained with column 4 empty; the gate figure equals the formula.
- Each joint: either half alone gives its own effect and not the payoff; both give the payoff; an element
  keystone can't be trained without the closed joint; an off-pair element stops at column 4.
- A class change charges the price, takes two presses, and is free for a new runner.
- High-water: a new runner levelling to the old best earns no points; past it, one a level.
- An old save's trees come back as points once.
- The Also row: every chip swaps the fifth lane and back.
