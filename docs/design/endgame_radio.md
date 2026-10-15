# The endgame on the Radio (draft, 15 Oct)

Matt, 15 Oct: "the endgame is the wrong way round." Today the campaign's own sites grow depth buttons once it's done,
and the Radio's codes are bolted onto them. Instead: the campaign stays the campaign, and the endgame is something you
make on the Radio, out of the papers you've kept, with Kev reading what comes back. Gear is gated by level so the
campaign lasts and you aren't endgame-kitted when it ends.

**Agreed (Matt, 15 Oct):** the shape (§1), the signal and its name (§2), Kev's story (§3), the reach (§4), gating gear
(§5). "We're essentially just copying PoE's map system with our own twist." A death: **the top gear simply waits** -
"the same as any other game where you drop stuff, roll a new class and have to level the new one to wear the stuff you
farmed with the other class." Gear too high to wear is greyed out with a padlock. The rest of §2-5's open questions
take the recommended answers: three papers a signal; a rarer paper rolls one deeper; signals sit on the Radio, a few
held, seen before they're run; a lost run loses the signal.

Mockups (15 Oct): docs/design/mockups/signals_map.png (the campaign's cards), signals_radio.png (the Radio: the papers,
the decoder, the signals held), signals_kit.png (gear too high to wear).

**What we're borrowing (the sweep, 15 Oct):**
- PoE 1's maps: one-use keys in 16 tiers; a map drops maps of its tier or under, a boss up to two over, so the ladder
  feeds itself; crafting a map adds mods that make it harder and pay more; completing maps buys the atlas's tree.
- PoE 2's waystones: the same keys on an atlas where each node is one attempt (fail it and route round); towers and
  tablets juice an area; the pinnacle needs three keys from three factions' lieutenants.
- Ours: papers are the waystones, and you choose them (each brings its own code) instead of rolling orbs on one. A
  signal drops papers, the deeper the rarer, so it feeds itself as PoE's maps do. Kev's story signals are the three
  keys: three story papers make the beat's mission. The juicing we have (the atlas map, standing codes, Twist) is
  PoE's crafting and tablets already.

## 1. The shape

- **The campaign:** the four zones, twelve sites, four heads. Every site fights at its campaign numbers, always.
  No depth button, ever. A site can be run again for loot, XP and papers, but it never gets harder.
- **The turn:** the Quartermaster falls, his set comes home, the Radio opens, and Kev's On the air scenes play (as
  now). Kev: the papers' codes are frequencies.
- **The endgame:** at the Radio you put in **three papers**. They decrypt into a **signal**: one mission, a fix on
  somewhere the convoys have been. You run it like a site, and it's gone once it's run, won or lost.

## 2. A signal: what the papers make

A signal is rolled from what goes in, so the papers are the crafting:

| Part | Where it comes from |
|---|---|
| The place | One of the twelve campaign sites at random: its art, its crates, its shape (many and thin, few and hard). |
| The crew | At random from the four zones' crews, so the Outskirts' allotments can hold the City's soldiers. |
| Its depth | Rolled in a band around your reach (§4). Depth is the difficulty curve we have now: their HP, fire, resists, the drops' item level. |
| Its codes | **Each paper puts in its own code.** A P45 brings Laid off, a betting slip its own. Three papers, up to three codes: you choose the bite and the pay by choosing the papers. |
| The extras | Rolled: sometimes a head at full strength, a convoy event, the weather. |

Then it's **juiced the way we do today**: the map's points (the atlas), the standing codes, Twist. Nothing new to
learn there; it just lands on a signal now.

Papers are found through the whole campaign but stay **encrypted until the Radio's open** (the papers' parked item).
You've been carrying the endgame's currency all along without knowing it.

To decide:
- Three papers always, or one to three (one: plain, three: the strongest)?
- Do the papers' rarities matter (a rarer paper, a deeper signal), or only which code each one carries?
- Can you see the signal (place, crew, depth, codes) before you commit to running it, and walk away keeping it?
  (Recommended: yes, a signal sits on the Radio until it's run, a few at a time.)
- Does a lost run lose the signal? (Recommended: yes. The papers were spent, which is the stake.)

## 3. Kev's story: the convoys

Kev carries it. Each signal comes back with a line from him about what the fix tells him: whose convoy, which way,
carrying what. Most signals are **random**, the grind. Some are **story signals**: a set of papers that only matters
together (three that belong to one story, e.g. a depot's manifests) decrypts into a fixed mission that moves the
story on. Kev's arc in three beats, each a story signal and each a scene in the On the air style:

1. **Where they go:** the lorries aren't random; they run a route.
2. **Whose they are:** the Army's, still giving orders (the Garrison).
3. **The depot:** where the route ends. The endgame's head, the Lorry's Load and its own set.

The lorry/convoy fight we have (the Services at depth 8) becomes the third beat, not a button.

To decide: three beats, or more? Do the story papers drop only once the Radio's open, or are some carried from the
campaign without knowing?

## 4. Your reach: how deep a signal rolls

Today's depth curve stays as it is, rolled on the signal instead of picked. **Your reach** is the deepest signal
you've beaten, plus one. A new signal rolls around it, mostly at your reach, sometimes a step under, now and then two
over. Beating one at your reach raises it. That keeps the ladder (you climb), and it's rolled, not chosen.

Things that today hang off a site's depth move to your reach: the atlas point "a new depth" (now: a new reach),
pinnacle heads (a signal past a crew's pinnacle depth can roll their head at full strength), the Yard's gates, the
codes' tiers (WORD_TIER_DEPTH), sets dropping "from depth N".

To decide: a fixed band (reach −1 to +2) or one the Radio's Yard picks widen? Can papers push a signal deeper (a
rarer paper, +1)?

## 5. Gear gated by level

Each piece has a **level to wear**, its item level (from the site it dropped at, and a signal's depth). The runner
can't fit it until they reach it. It can still be carried, stashed, sold and worn later.

What this fixes, from Matt's save:
- The gamble's top-end pulls (the Sniper rifle, the Paramedic's Bumbag) wait for their level instead of carrying the
  campaign.
- Uniques at depth (the Van's Spare) come with their depth's level, so a deep copy isn't a free upgrade.
- The campaign's sites drop at their own levels, so the City's gear comes in the City.

To decide:
- **A death.** Settled: the top gear waits for the new runner's level.
- Does the gamble roll at your level (as now), or under it?
- Show the level on every item and an "at level N" lock on the compare, in red when it's over.

## 6. What it touches (for the build, later)

The depth ladder on the sites (`depth`, `best_depth`, `worn_depth`, the Map's depth buttons), the atlas's "a new
depth", pinnacles (PINNACLE_DEPTH by site), the convoy (CONVOY_DEPTH on the Services), the Yard's gates, the codes'
tiers, sets, the bot (it climbs depths today: it'll make signals), the balance reader's ladders, saves (a save deep in
the ladder converts to a reach), and the papers (encrypted until the Radio). Big enough that it's its own slice, in
parts, each with its checks, before the balance pass.

## 7. Order

1. Agree §1-5 (this doc).
2. Mockups: the Radio's decrypt (three papers in, a signal out), a signal's card, the lock on gear.
3. Build in parts: gating gear; the papers encrypted; signals and reach in place of the depth buttons; Kev's story
   signals; the bot and the reader.

## 8. Training's gating (draft, for the next session)

Matt, 15 Oct: "like Last Epoch, you need certain levels in one tree to be able to progress in the other or even the
same one. Put points into your core speciality to allow the higher end skill usage."

Where we are: a point a level, MAX_LEVEL 50 (paragon levels past it: +2% damage and HP each, no top), the second past
at ASCEND_LEVEL 30, retirement at RETIRE_LEVEL 30. Gating today is inside a tree only: a column opens on 60% of what
the columns before it cost (GATE_SHARE). Nothing gates one tree on another.

Last Epoch: a mastery tree only opens after 20 points in the base class tree; half of every mastery tree is open to
all, the other half only to the mastery chosen; skills unlock by level and by points in the class; a bar shows the
points still to spend before the next node or skill.

The draft for us:
- **The class tree is the core.** Its element tree's later columns need points in the class tree: columns 3-4 at 6,
  columns 5-6 at 12, the capstone at 18. The joint (column 4) needs both halves' trees past their gate.
- **The second past** at 30 opens only with 20 points in the first class tree (Last Epoch's 20).
- **Levels on the top nodes:** keystones at 20, capstones at 30, so the campaign can't hand them out early.
- A bar on each lane: "6 more in Muscle to open this".
Mockup: docs/design/mockups/gating_training.png. **Retirement moves to level 50 (Matt, 15 Oct)**, not 30. The level
cap stays at 50 until Matt has played a save to the cap and through the Radio's loop; then decide whether it rises.
