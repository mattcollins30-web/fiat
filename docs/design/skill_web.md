# The skill web, version two (4 Nov 2026) - the design spec

Replaces version one of this file (3 Nov, built as 0.12.0-0.12.2): the petals layout of 379 nodes, one point a level,
the 15/40 gates. What version one settled and still holds: one web with each runner its own lit path on it; a runner
starts lit at its class's start; buy any node joined to one you own, one point a node; keystones and capstones gated by
points spent; the pairs (JOINTS); every node's name, effect and words; the rail's order (built in 0.12.0).

Asked for by Matt during his playtest of 0.12.2 (status.md, parked item 5): "I think we can afford to go bigger.
Skills surrounded by lesser nodes - we already have the art so there's no harm repeating the weaker ones. Poe doesn't
by one track covering energy or shield and another covering hp or damage ... I'd advise you to directly compare poe
when designing ours." Then: "let's aim for some symmetry"; "two points a level ... plus X amount as rewards"; "lets
keep the 50 cap ... the key here will be to make sure the elemental trees merge with the class trees". Settled over
six canvas rounds on 4 Nov: https://claude.ai/artifact/4iDWcoDcXdut6c8TrQF8ku (the rows "The web, round two" to
"Round six"; the agreed web is the board "Round six", Matt: "ok sounds good").

## Matt's calls
- Bigger: every skill and notable a cluster, its own lesser nodes round it (round two).
- Themed tracks, not mixed smalls: a class's attack track, its other track, staying up, finds, skills (round two).
- PoE's layout as the comparison, not a copy (round two, the board "PoE's layout as the comparison").
- Symmetry: every class on one template, mirrored about the class's line (round two: "aim for some symmetry").
- Two points a level, the level cap staying at 50, plus reward points (round two and three).
- The elements merged into the classes, not beside them (round three).
- Round four's takes (denser element columns, a tighter centre, the classes' tops varied) and round five's (each
  class's top corner its own shape): taken (Matt: "lets see it with your takes", "ok lets see round 6 with your takes").
- Round six: the Recruit's corner a ladder, each corner's notable a full cluster, the class names clear of the nodes,
  each element's middle cluster dropped (it crowded the two classes' pair clusters).

## The rule for spending
1. Each runner has its own points: **two a level** (today's rule, `_points_up`, doubled: two for each level past the
   class's best), **plus reward points**, the same for every runner of the camp:
   - +1 the first time each head falls (11 heads: 11);
   - +1 each chapter of Kev's story (9);
   - +2 the Issue, fiat (2).
   22 in all. A runner at level 50 with every reward has 2 x 49 + 22 = **120 points** (PoE at 99: 122-123).
   Paragon points stay apart and buy only the Paragon board.
2. A runner starts with one node lit: its class's start, which carries the class's skill.
3. Buy any node joined to one you own. Every node costs one point.
4. Big nodes also need points spent first: **a keystone 30, a capstone 80**.
5. A reset gives every point back (the reset's price as today).

Two counters on screen, as today: points and paragon points. The header's line changes to say where points come from
("two a level past the Poacher's best, and rewards").

## The shape
1,549 nodes: 918 in the classes (153 a class), 444 in the elements (74 an element), 187 at the centre and on the
roads between. 120 points buys about 8% of the web (PoE: about 9%). The layout as data, the reference for the build:
**docs/design/skill_web_layout.json** (every node's id, place, kind, track, region and name; every join). Web units,
the centre at 0,0; the web's radius ~1,080, the Paragon ring at 1,120.

- **The classes**, on the same angles as version one: Poacher at 12 o'clock, then clockwise Paramedic, Scrapper,
  Drifter, Doorman, Recruit, 60 degrees apart. The start at r ~480; the capstone at r ~980.
- **The elements**, each on the line between its two classes, as version one: The cold, Live, Petrol, Blades,
  Knuckles, The Rat Man. A class's left element is the one anticlockwise of it (the Poacher's is the Rat Man).
- **The centre**: the centre node; an inner ring of six clusters on the elements' lines (life, Guard, pace, round
  twice), one step out from the centre and joined round; an outer ring of six clusters, one under each class's start,
  joined to the inner ring on both sides and one step to the start. A start reaches the centre in about ten nodes.

### A class (153 nodes, the template)
Mirrored about the class's line: the class's attack track on the left, its other track on the right (the Poacher's:
the gangs), three skills a side, staying up and finds up the middle, the capstone at the far end. Every skill and
notable is a cluster: the node with five lesser nodes of its track round it. Tracks run out from the start.

| Place | The Poacher (the worked example) |
|---|---|
| The start, alone with its own wheel of six lesser nodes | Clean shot |
| Left track: the first cluster, the pair, the second notable, the keystone | Rifleman, Rat bait, Clocked, One shot |
| Right track, the same, mirrored | Quiet feet, Cold snap, Twine, Trapline |
| Left skills, from the start out | Flush them out, Go to ground, One for the pot |
| Right skills, the same | Collared, Gin trap, Decoy |
| Up the middle: staying up, a skill, finds, finds | In the hide, Net every hole, Night work, Poached |
| The capstone, the far end | Dead quiet |
| The corner (its own shape, below): the third keystone and a notable | Snare and wait, Early doors |

The other five classes fill the same places from their trees as today: the left tree's notables down the left
track, the right tree's down the right, the pair halves (AFFINITY unchanged) in the pair places, today's keystones at
the tracks' ends, today's capstone at the far end, the stepped-down second capstone as the last finds notable, the
third keystone in the corner. The builder lists each class's table here before the build (the slots and today's names
for them); where a class has fewer skills or notables than places, the place goes on the open list below.

**The corner.** Above the side skills, either side of the finds and the capstone: 17 nodes in every class (one
keystone, one notable with four of its own round it, the roads). Each class's corner is its own shape:

| Class | The corner |
|---|---|
| Poacher | the long walk: out to the keystone and nothing comes back |
| Paramedic | the ward round: a loop, the keystone on its far side |
| Scrapper | the scrapheap: two tight lattices, take them in any order |
| Drifter | the fork: one road that splits, a keystone one way, the notable the other |
| Doorman | the wall: a bar across the top, the keystone at one end, the notable at the other |
| Recruit | the ladder: the keystone up a short march, the notable at the top of two rails and their rungs |

### An element (74 nodes, a column)
A column of clusters along the element's line, between its two classes, coloured the element's. From the centre out:

| Place | The Rat Man (the worked example) |
|---|---|
| In from the centre (version one's slot 0) | Under the sink |
| A pair low down, either side | Bait, Council issue |
| The centre notable | Dosed |
| The two pair halves, facing each class's pair | Recruit's gas, Poacher's bait |
| The tip (the cost notable) | Rat's share |
| A pair either side of the tip | Cumulative, (new) |
| The run's notable (resist) | Immune |
| A pair either side of it | Slow acting, (new) |
| The keystone, the capstone | Builds, Lingers |

Every other element the same, its names from version one's table (its four smalls' names on the new clusters; two
new names an element, 12 in all, on the open list).

### The merge (how the elements join the classes)
- A class's start runs into both its elements low down (its wheel's outer nodes to each element's first clusters).
- An element's centre notable runs out into both its classes' pair clusters; a class's pair cluster runs up into the
  element's pair half facing it, and on to the element's tip. A pair is lit when both halves are owned, as today.
- Wherever a class's cluster and an element's come within a short step, a join links them. An element is walked
  through its classes, not beside them.

### Lesser nodes
Every lesser node takes its track's value: a few % of what the track is about (damage on the attack track, Guard and
HP on staying up, loot and search on finds, cooldown and energy on skills, the element's own on its column; life,
Guard and pace at the centre). Today's class smalls and the fillers (FILLERS) seed them; the balance pass sets them.

## Pacing (the Poacher, by the rule, fewest nodes from the start)
The centre 10; Rat Man's centre notable (Dosed) 6; One shot or Trapline 14, so the 30-spent gate holds them (level 16
with no rewards, about 15 with a reward or two); Dead quiet 18 and Builds 20, then the 80-spent gate (level 41 with no rewards,
level 30-35 with most); Snare and wait 21; Lingers 22. At 50 a runner has a class's two tracks and one element in
depth, or a class and a taste of both elements; not the lot.

## The screen (Training)
As built in 0.12.0, with:
- The web at the new size: whole web, the class's corner, and the Paragon board as tabs; zoom and pan as today. At
  the whole-web zoom, clusters read as their node; lesser nodes as dots.
- The header's line: "two a level past the <Class>'s best, and rewards"; a reward's point says where it came from
  (the node card's "points" line or a tooltip, the builder's call, fit-checked).
- The node card: "Skill" for a skill node, not "Notable" (playtest item 2). Gates: "Keystones open at 30 points
  spent", "Capstones open at 80".
- The class's start carries its one skill; the others sit in their own clusters on the tracks (playtest item 2:
  "too many skills around the starting node").

## The build (after Matt's playtest; not before)
- Data: the web from skill_web_layout.json (or its generator, ported into tools/make_skill_web.py); node ids keep
  "Tree/Node" where today's node goes on; new nodes new ids.
- Sim: two points a level; the reward points (+1 a head's first fall, +1 a Kev chapter, +2 the Issue) for every
  runner, past and future; the gates at 30 and 80.
- Save: SAVE_VERSION up, a fresh save (the incompatible-save warning, house rule).
- The screen as above; the bot's targets rewritten for the new places (shortest path, waiting for 30/80).
- The smoke: every node reachable from every start; every named node placed once; a keystone refused under 30
  spent and a capstone under 80; reward points counted once each; the labels fit at 1920x1080 and the smallest window.
- No balance pass with it (CLAUDE.md, 2 Nov); the bot's builds only need to run.

## The places filled (4 Nov, Matt: "ill take you suggestions on 1-3")
Every place on the web is filled from today's nodes where one exists; 18 new names in all (marked new).

**The elements' six new clusters.** Low down (the pair either side, in from the centre): the element's two hung
notables (data.gd WEB_EXTRA, off the web since 0.12.0). Beside the tip: version one's two hangs. Beside the resist
notable, before the keystone: two new. The four small names (Frost, Bait ...) stay on named lesser nodes in the column.

| Element | Low pair | Beside the tip | Before the keystone (new) |
|---|---|---|---|
| The cold | Chilblains, Sleet | Deep freeze, Brittle | Black ice, Brass monkeys |
| Live | Live rail, Stripped wire | Capacitor, Overload | Crossed wires, Fuse box |
| Petrol | Accelerant, Flashpoint | Oil drum, Backdraught | Forecourt, Bonfire night |
| Blades | Honed, Whetstone | Serrated, Arterial | Paper cuts, Shiv |
| Knuckles | Knuckleduster, Shin pads | Low blow, Floored | Sucker punch, Bare-knuckle |
| The Rat Man | Strychnine, Tainted | Takes its time, Catching | Nest, Rat run |

**The classes' places**, by the template (the Poacher's table above): the left tree's centre, pair, second notable
and keystone down the left track; the right tree's down the right; the left tree's three skills left, the right
tree's first three right and its fourth up the middle; the start's flower's outer notable (version one) as staying
up; the far flower's two notables as finds; the capstone at the far end; the corner's notable the start's flower's
centre notable (version one), its keystone the third keystone.

| Class | Corner keystone | Corner notable | Staying up | Middle skill | Finds |
|---|---|---|---|---|---|
| Poacher | Snare and wait | Early doors | In the hide | Net every hole | Night work, Poached |
| Paramedic | Jab | Second shift | Double shift | Code blue | Walking wounded, Transfusion |
| Scrapper | Breaker's yard | Workbench | Sheet metal | Everything must go | Quiet hands, The lot |
| Drifter | On a roll | Light fingers | Breather | Jackpot | Hit and run, Loaded dice |
| Doorman | Bin lid | Through the lot | Squared up | Chucking-out time | Loud, Iron |
| Recruit | Firing blanks | Square-bashing (new) | Double time | Fire and manoeuvre | Blast burns, Passing-out parade |

- The Recruit's two empty second notables (new): Fuse cut short (Ordnance, the left), By the numbers (Drill, the right).
- Each class's old starter notable (Still hands, Steady pulse, Nose for parts, Light feet, Heavy hands, Pull the pin)
  steps down to a named lesser node on its start's wheel: the first thing a runner can take.
- The Scrapper's Hoarder and the Doorman's Stand and fight (version one's third far notable) step down to named lesser
  nodes in their finds clusters, as the stepped-down capstones did: words kept, numbers to the balance pass.

**The centre's 13 clusters.** The centre: The dog's share. The inner ring (life, Guard, pace, twice): Circuits, Home
ground (life); Chin down, Elbows in (Guard, new); Good boots, Shortcuts (pace, Shortcuts new). The outer ring, one
under each class's start: Double tap, Second wind, Pack horse, Word of mouth, Market day, Well stocked. The kettle
(resting, as Second wind's words) steps down to a named lesser node in Second wind's cluster; Long walks stays a named
lesser node in a life cluster, as today.

**Points for a new runner of a class:** unchanged from today, doubled: two for each level past the class's best (a
replacement runner doesn't re-earn levels the class has had), and every reward point to every runner, past and future.

## Open (the balance pass, after Matt's playtest)
- The new names' effects (the 18 above) and the stepped-down nodes' numbers.
- The lesser nodes' values; the stepped-down capstones' numbers; the corners' keystones' numbers.
