# The endgame on the Radio (draft, 15 Oct)

Matt, 15 Oct: "the endgame is the wrong way round." Today the campaign's own sites grow depth buttons once it's done,
and the Radio's codes are bolted onto them. Instead: the campaign stays the campaign, and the endgame is something you
make on the Radio, out of the papers you've kept, with Kev reading what comes back. Gear is gated by level so the
campaign lasts and you aren't endgame-kitted when it ends.

Nothing here is agreed yet. Each section ends with what's to decide.

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
- **A death.** A dead runner's replacement starts at level 1, keeping the training points. With gating, they can't
  wear what's in the stash. Options: the new runner arrives at the old one's level less a share, or a share of the
  Yard's levels carries over, or the stash's top gear waits. (This is the big one.)
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
