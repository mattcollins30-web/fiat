# The skill web (3 Nov 2026) - the design spec

Replaces the layout and the points of docs/design/web.md (22 Oct) and the lanes of docs/design/trees.md. What those
designed and still holds: the nodes themselves (names, effects, words), the pairs (JOINTS), the keystones and
capstones, the skills that hang off notables. What goes: the wheel layout, the four pools, the element use meter,
the camp owning the centre and the elements, the column gates, the affinity price (double for an off-class element),
the bridge.

Asked for by Matt (3 Nov): "the poacher the first class should be rotated to the 12 o'clock position"; "the class
rings themselves are a bit of a mess and if you compare to poe it's just nowhere close aesthetically or choice wise";
"the pitch's loop at the center needs to have a connection to the element trees which in turn need a connection to
the class starting nodes"; "everything needs to be logical in how points are selected and spent"; "the center pitch
tree should be the start of concentric circles that spread out and interconnect". Settled over six canvas rounds the
same day: https://claude.ai/artifact/4iDWcoDcXdut6c8TrQF8ku (the last row is the agreed design: "Classes as four
flowers each").

## Matt's calls
- Layout B, the petals (round 1): the centre, six element flowers round it, a class between each two elements.
- A runner starts at its own class's start, lit for free (round 2, option 1).
- One web, each runner its own lit path on it; home no longer owns the centre or the elements (round 2: "yes ok it
  can go").
- Longer paths, a centre worth reaching, the capstone gated at 40 points spent (round 3).
- Today's nodes in the new slots, every keystone kept, one capstone a class stepped down (round 4: "I'll take your
  suggestions").
- Each class as four small flowers, not one ring (round 6, Matt: "much better").

## The one rule for spending
1. Each runner has its own points: one a level past its class's best (today's rule, `_points_up`). Paragon points
   stay apart and buy only the Paragon board.
2. A runner starts with one node lit: its class's start, which carries the class's skill.
3. Buy any node joined to one you own. Every node costs one point.
4. Big nodes also need points spent first: a keystone 15, a capstone 40.
5. A reset gives every point back (the reset's price as today).

Two counters on screen: points and paragon points. The element meter, element points and the shared points go.

## The shape (geometry for the build; the canvas generator is the reference)
Coordinates in a 1000 box, the centre at (500, 500), angles in degrees, 0 to the right, clockwise.

- **The classes**, at -90 Poacher (12 o'clock), -30 Paramedic, 30 Scrapper, 90 Drifter, 150 Doorman, 210 Recruit.
- **The elements**, each between its two classes: -60 The cold, 0 Live, 60 Petrol, 120 Blades, 180 Knuckles,
  240 The Rat Man. A class's left element is the one anticlockwise of it (the Poacher's is the Rat Man), its right
  the one clockwise (the cold). The pairs follow AFFINITY unchanged.
- **The centre** (25 nodes): the centre node; an inner ring of 6 stat nodes (r 50, one at each element's angle);
  an outer ring of 12 (r 92, at each element's angle ±15); a gate notable at r 128 on each element's angle, joined
  to the two outer-ring nodes beside it. Rings joined round; the inner to the centre and to the outer.
- **An element flower** (14 nodes): a ring of 8 (radius 44) centred at r 200 on the element's angle; slot 0 faces
  the centre and joins the gate; slot 2 faces the class anticlockwise, slot 6 the class clockwise; slot 4 is the tip.
  A notable at the flower's centre, joined to slot 0. From the tip a run out along the element's angle: small (r 266),
  small (288), notable (310), small (332), the keystone (356), the capstone (388).
- **A join** (4 small nodes, the element's colour): from a class's start to the facing side of each of its two
  elements (slot 2 or slot 6), evenly spaced.
- **A class** (36 nodes), four flowers of 8 round a centre notable (radius 34), each flower's slot 0 facing the web's
  centre:
  - the start's flower at r 300 on the class's angle; its slot 0 is the start;
  - the left tree's flower at r 372, class angle -17; the right tree's at r 372, +17;
  - the far flower at r 440 on the class's angle; its slot 4 (the outer tip) is the capstone.
  - Joins: the start's flower to each tree's flower, and each tree's flower to the far flower, nearest slot to
    nearest slot. The far flower is reached through either tree.
- **The Paragon board**: its own view, a tab beside the web (as today), drawn as a dashed ring round the web.

379 nodes in all: 25 at the centre, 84 in the elements, 48 in the joins, 216 in the classes. A runner at level 50
has 49 points, about an eighth of the web.

## What sits where
### A class's four flowers
| Slot | Poacher | Paramedic | Scrapper | Drifter | Doorman | Recruit |
|---|---|---|---|---|---|---|
| Start (the skill) | Clean shot | Tourniquet | Ring main | Duck and weave | Shoulder charge | Lob one in |
| Start's flower, centre | Early doors | Second shift | Workbench | Light fingers | Through the lot | (small) |
| Start's flower, outer slot | In the hide | Double shift | Sheet metal | Breather | Squared up | Double time |
| Left tree | Stalking | Triage | Stripping | Moving on | Muscle | Ordnance |
| Left flower, centre | Rifleman | Fast work | Bodger | Spray | Shotgunner | Cook it off |
| Left pair (faces the left element) | Rat bait | Ice pack | Live wire | Bottle and rag | Glassing | Brute force |
| Left flower, second notable | Clocked | Worst first | Salvage | B-roads | Off the canvas | (small) |
| Left keystone (outer tip) | One shot | Field surgery | Nothing wasted | Never there | Bodyline | Grenadier |
| Right tree | Snares | Shifts | Fencing | Luck | The door | Drill |
| Right flower, centre | Quiet feet | Walk it off | Magpie | Dead man's shoes | Chokepoints | Cover me |
| Right pair (faces the right element) | Cold snap | Defib | Blowtorch | Cut-throat | Hands on | Tear gas |
| Right flower, second notable | Twine | Clocking off | Back pocket | Spare change | Last orders | (small) |
| Right keystone (outer tip) | Trapline | Not today | Buyer's market | All or nothing | One at a time | Quick march |
| Far flower, centre (the cost notable) | Night work | Walking wounded | Quiet hands | Hit and run | Loud | Blast burns |
| Far flower, a notable | Poached | Transfusion | The lot | Loaded dice | Iron | Passing-out parade |
| Far flower, a second notable | (small) | (small) | Hoarder | (small) | Stand and fight | (small) |
| Capstone (far flower's tip) | Dead quiet | Clean hands | Jerry-rigged | Ghost | Held | Ringing ears |

"Far flower, a notable" is the class's second capstone today, stepped down; its words keep, its numbers go to the
balance pass. Every keystone is kept. Nothing is cut. The Recruit's four (small) slots are open for new notables.

### An element's flower
| Slot | The cold | Live | Petrol | Blades | Knuckles | The Rat Man |
|---|---|---|---|---|---|---|
| Slot 0, in from the centre | De-icer | Sparks | A can of it | Stanley knife | Bare hands | Under the sink |
| Slots 1, 3, 5, 7 (small) | Frost, A hard winter, Numb, Wind chill | Charge, Off the mains, Amps, Volts | Rags, Siphoned, Wick, Fumes | An edge, Sharpened, Deep, Nicked | Wraps, Half a brick, Thick skull, Weight behind it | Bait, Council issue, Cumulative, Slow acting |
| Centre notable | Chill | Current | Lit | Opened up | Stagger | Dosed |
| Slot 2, the anticlockwise class's pair half | Poacher's snare | Paramedic's paddles | Scrapper's torch | Drifter's razor | Doorman's knuckles | Recruit's gas |
| Slot 6, the clockwise class's pair half | Paramedic's ice | Scrapper's mains | Drifter's can | Doorman's glass | Recruit's boots | Poacher's bait |
| Slot 4, the tip (the cost notable) | Cold hands | Earthed | On your hands | Blood up | Heavy | Rat's share |
| The run's notable (resist) | Thermals | Rubber soles | Fireproof | Scar tissue | Thick-skinned | Immune |
| Keystone | Frozen solid | Daisy chain | Spreads | Won't stop | Bust them up | Builds |
| Capstone | Shatter | Arc | Wildfire | Bleed out | Flattened | Lingers |

A pair is the class's half and the element's half facing each other across one join (Rat bait and Poacher's bait);
owning both lights the pair, as JOINTS does today.

### The centre
- The centre node: The dog's share (today the Pitch's capstone; now a notable, no gate).
- The six gates: Double tap, Second wind (its words: resting at home), Pack horse; three open.
- The two rings: life, Guard and pace (the inner node at each element's angle, then round in that order). Long walks
  and Circuits fold into the life nodes.
- The Pitch's damage, loot and search smalls (Dry fire, Zeroing, Knowing the streets, Keen eyes, Stashing) and the
  fillers (FILLERS) go on the joins and the runs, 3 a node as today's small values.

### Small nodes
Every unnamed node takes a small value: today's class smalls on their own class's flowers, the fillers elsewhere.
About 20 a class are fillers for now; the balance pass gives them real values.

## Pacing (the canvas's Poacher, by the rule)
Out to the Rat Man's keystone (Builds) with its 16th point, level 17; up the Stalking flower to One shot with its 25th;
1 point free at level 34. A beeline to an element's keystone is 13 nodes; to a class keystone about 7, so the 15-spent
rule is what holds it back. The capstone opens at 40 spent, level 41 at the soonest.

## The screen (Training)
- The header: the class portrait, "N points free", "M of T spent · one a level past the class's best", the chips,
  the six runner cards.
- The web: whole web, the class's corner, and the Paragon board as tabs; find a perk. Owned nodes lit in their colour;
  nodes you can take (next to one you own, gates met) ringed amber; the rest dark. Notables, keystones and capstones
  show their icon (art/nodes, art/skills).
- The node card on the right: icon, name, where it sits, its words, why it can or can't be taken, "Take it · 1 point".
- Pairs (done / how many steps away), big nodes (keystones open at 15, capstones at 40, a bar), Copy build, Paste
  build, Reset.

## The rail, in the order rooms open (Matt, 3 Nov; goes in with the web)
Stats, The Kit, The Map, Training, then the rooms the heads open: The Clinic (the Gamekeeper), The Workshop (the
Carpet Man), The Fence and Home (the Manager, both at once), The Radio (the Quartermaster). `Main.ROOMS` today has
the Fence before the Workshop. The rail reorders only; the shortcuts keep their keys.

## The build
- Data: the web generated from the geometry above into data (each node: id, position, kind, the effect it carries,
  its joins). Node ids keep today's "Tree/Node" form where the node exists, so effects, the smoke's ids and the
  save's names carry over; new nodes get new ids.
- Sim: one pool per runner; the buy rule (joined to one owned, 15/40 gates); the reset; the pairs from owned halves.
  Remove the meter, element points, shared points, camp ownership, the bridge, column gates, the affinity price.
- Save: SAVE_VERSION 23, a fresh save (old slots show the incompatible-save warning).
- The screen: the Training web redrawn to the new positions with the frontier, the node card, the one counter.
- The bot: buys toward a list of target nodes by the shortest path (its class's build plan rewritten as targets).
- The smoke: the rule (an unjoined node refused, a keystone refused under 15 spent, a capstone under 40), every node
  reachable from every start, every named node placed once, the rail's order, and the screen's labels fit.
- No balance pass with it (CLAUDE.md, 2 Nov); the bot's builds only need to run.

## Open (the balance pass, after Matt's playtest)
The small nodes' values; the stepped-down capstones' numbers; the open slots (the Recruit's four, three gates).
