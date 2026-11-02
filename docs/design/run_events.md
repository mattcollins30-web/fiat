# Run events: things that happen in the fight, with choices (1 Nov, design)

Matt, 1 Nov: "we also need to add art to these events and a pause in the gunplay because at the moment a log line
just doesn't make it compelling enough. Yes a choice is good ... we could introduce recurring characters like a
scrap trader or a vagabond that trades in tins or scrap or certain materials for buffs during the run as well as
gear on offer." "We need more than 3. Is there any way to introduce procedural generation to them?" "The events
should happen in the fight window ... If dogs appear then you should be able to fight them or a person needs
rescuing you should be able to see them." Trader buffs: run only. Traders get better the more you deal with them.

Depends on: materials in the pack (scrap and the rebuild materials as pack items, built 1 Nov).

## What's there today

Three events (`Data.EVENTS`: convoy, trapped, cache), EVENT_ODDS 0.3 of runs, once, 15-70 s in, a log line each,
no choice; two of the three are pure upside. Plus the run's other dice: weather and night, the site's crates, the
fight's own swing.

## The rules

1. **An event happens in the fight window.** It's a thing in the scene: a figure or an object placed in one of the
   site's slots (the slots gangs and crates already use), drawn in the fight kit's style.
2. **Threats are fights.** Dogs, a rival crew, a convoy's riders arrive as their own group - standing, firing, going
   down - and are fought on the normal rules (their own HP, damage, odds, drops). The choice is whether to stay for
   them: they come in the lull, and "Get out now" is open.
3. **Everything else pauses the gunfire.** The person, the trader, the locked van appear in the lull between gangs;
   the gang clock stops; the choice sits in the panel under the scene (where "Get out now" / "Fill up, then go"
   are), each option with its cost and its odds shown before you pick; the scene plays the outcome (they're pulled
   free, the shutter gives, the floor goes). Never mid-volley.
4. **Every choice is a trade.** Something you carry (a med, rounds, scrap, a material, tins), time (the next gang
   sooner), HP or noise, against something you want (a find a tier up, materials, notes, a future runner, a tip,
   a run-only buff). "Leave it" is always an option and costs nothing.
5. **Odds on the face.** "Pull them out: 70% clean, 30% the ceiling comes down (-20% HP)". Night, fog and your kit
   move the figures; nothing is hidden.
6. **Runs you aren't watching** (repeat runs, the bot, away) can't wait: each family has a standing order the
   player sets once (like the loot rules), else a cautious default ("leave it"; fight a threat only at the run's
   odds or better).
7. About EVENT_ODDS of runs (0.3) have one; a run never has two; the same family not twice running.

## Procedural from written parts

An event = a **family** (the situation and its rules) + **slots** filled from pools matched to the moment + the
**choices** the family offers, built from what you carry and who you are. Pools are weighted by zone, site kind
(farm, retail, estate, civic, military, medical), weather, night and how deep the run is.

| Family | In the scene | The choice, at its plainest | Pool slots |
|---|---|---|---|
| Someone in need | a person trapped, hurt or lost | free them (time, a med, HP risk) for a future runner, a tip or what they carry; or leave them | who, what's on them, what pins them |
| A trader | a figure at a barrow (recurring) | trade scrap / tins / materials for run-only buffs or gear off their shelf | which trader, their stock, today's want |
| A locked thing | a cabinet, safe, van, shutter | force it (noise: the next gang sooner; a tool or rounds), a find a tier up; or leave it | the lock, what's behind it |
| A threat passing | dogs, a rival crew, a convoy | fight them for what they carry, or get out | who, how many, what they carry |
| A dangerous place | a flooded basement, a floor that gives, a gas smell | go in for what's there (HP risk, time), or don't | the hazard, the prize |
| A stash with a catch | a bag in plain sight, a tripwire, a watched pile | take it (odds of the catch), check it first (time), or leave it | the catch, the prize |
| A body | someone else's run that ended here | search it (a find, sometimes a clue to what killed them: the site's next gang tougher or a head's weakness shown); or leave it | whose, what killed them, what's left |
| A wreck | a crashed lorry, a burnt car | strip it for materials (time, scrap to cut it) | the wreck, what's in it |
| A broadcast | a radio, a pirate signal | listen (time) for a tip that seeds a later event or site | the voice, the tip |
| The weather turning | fog rolls in, the power comes back | press on (the odds move) or leave | the turn |

The convoy, trapped and cache events fold into "A threat passing", "Someone in need" and "A locked thing".

**Threads** carry between runs: a freed person turns up at the Yard (today's `promised` runner) or as a later
event; a rival crew you robbed comes back for you; a broadcast's tip becomes a cache on a later run; a trader
remembers you.

**Words:** each family keeps a handful of hand-written lines a zone, with slots ("{who} is under {what}, alive.");
the language pass reads the line pools, not every combination. Dry and British, as "Let it be done": bodies and
rival crews, nothing gratuitous.

## The traders (recurring, run-only buffs, better with dealing)

- **The Scrap man** (draft name): takes scrap. Run-only buffs - a plate stitched into the armour (+armour this run),
  magazines topped up from his own rounds, a gang's arrival slowed (the next gap longer), a bandage.
- **The Vagabond**: takes tins and the rebuild materials. A small shelf of gear (the site's tier, now and then one
  above), the odd rumour (a broadcast-style tip).
- (Later, maybe) **A medic on the road**: takes medical supplies, patches you up mid-run.
- **Standing:** each trader keeps a count of what you've traded; at steps (draft 3 / 10 / 25 trades) their stock
  grows: more buffs, better prices, the shelf a tier up, a rumour each visit. Kept in the save, the camp's (any
  class).
- Run-only: nothing a trader sells carries home except gear off the shelf.

## Art (test art first; the manifest only when a slice reads right)

Layered, so the count stays small:
- the backdrop: the site's own picture (exists);
- **figures in the fight kit's style:** creatures and crews with stand / fire / down (dogs; a rival crew a zone,
  reusing the gang pipeline), people with one or two poses (trapped / freed; a trader at the barrow), about 20-30
  in all;
- **props with a shut and an open state:** van, shutter, safe, wreck, body, radio - about 10;
- placement by the site's existing slots.

## Balance

Rewards and costs are data tables per family, tuned in the pass. Draft guardrails: an event's best choice is worth
about a third of a run's loot; a threat's fight is a normal gang's difficulty at the site, x1.5 for a rival crew;
trader buffs about +10-20% of one stat for the run.

## The slice, then the rest

1. Mockups on the canvas: the fight view with a trapped person and the choice panel; a threat (dogs) in the scene;
   a trader's shelf in the panel; the standing orders screen. Checked for fit.
2. The language pass on the first families' line pools.
3. Build the framework and four families (Someone in need, A locked thing, A threat passing - dogs, A trader - the
   Scrap man) with test art (silhouettes / placeholders in the scene).
4. Matt plays the slice; then the art manifest; then the other families and the Vagabond.
5. A balance pass after.

## Open (for Matt)

- The traders' names and faces.
- Whether a rival crew can kill your runner (a real death) or only drive you off.
- Whether threads should ever cost you (a robbed crew coming back) or only reward.

## Built, 1 Nov (the slice: build 40-E and its fix round)

What the slice does, as built (data.gd's run events block holds every figure; words.gd's `EV` and `ORDERS` the words):

- **Families:** Someone in need, A threat passing (dogs), A locked thing, A trader (the Scrap man). EVENT_ODDS 0.3 of
  runs (every run with the Caretaker's Keys), at most one a run, never the family the last event had. Weighted by the
  site's kind (`SITE_KIND`: farm, retail, estate, civic, military, medical), zone, weather, night and level; no threat
  before run 6 (`CONVOY_FROM_RUN`), no trader before run 2. The convoy, trapped and cache events folded in; a signal's
  convoy is unchanged.
- **Timing:** due 15-70 s in, it comes at the first lull after the site's first search is done (nobody on you, no
  head waiting, not on the way out, no Ghost's clear pending); a run that ends first has none.
- **The pause:** everything but a threat stops the run (the gang clock, the run's clock, the search) while the choice
  waits in the panel under the scene; "clock stopped" by the run's clock. A choice's seconds are spent at once: the
  next gang that much sooner, the run's clock at the search rate, played time. A choice that would run the clock out
  is greyed ("Not enough time").
- **Someone in need:** pinned - Pull them out, 15 s, 75% clean less 10 at night, 5 in weather, 15 under half HP
  (30-90%), a slip costs 20% of max HP (never the last of it); hurt - Patch them up, 15 s and a med. Freed, they're a
  candidate when the next runner's needed (`promised`). Take the bag: 5 s, a find, a thread they remember (no cost
  yet). Leave them.
- **A locked thing:** Force it, 10 s and the next gang 30 s sooner; Shoot the lock off, 5 s and 10 rounds from a worn
  gun's magazines; either a find a tier up. Leave it.
- **Dogs:** the next gang's size (2-5), each `DOG_HP`/`DOG_DPS` (1.0 / 1.0) of a man of the site's gang, with its
  damage types and resists - a normal gang's difficulty, as specced - nothing carried, half the XP. No pause: they stand
  10 s (the count in their tile), then come on. Their odds are read by six short dry fights through the real fight code
  as they arrive, from the HP they found you at; the face holds that reading through their 10 s. Fought off, the next
  gang 20 s later. (For the pass and the designer: a normal gang after the clear is nearly always won, so the face
  reads 100% and "Fight at 80% odds or better" fights; the 80% bar means 5 of the 6 fights.)
- **The Scrap man:** scrap from the pack's stacks. A plate (+10% armour this run, 15), magazines topped up (10; not sold with nothing to fill), the
  next gang 30 s later (20), a bandage (5); one of each a visit. Run-only: what's left of his rounds and his bandage
  go back at the run's end. Standing (a camp's trades, counted as a visit ends): 3, the bandage on the house; 10, 33%
  off; 25, his good plate (+20%).
- **Standing orders** (the Kit's loot rules, "Standing orders"), the designer's player-like defaults for everyone, the
  bot too: Help if it's a med or 70% clean; Fight at 80% odds or better; Force it; Buy what you can. A watched run
  always asks; a repeat run and the bot use the orders.
- **Test art:** placeholder shapes on the gang's slots with a caption; the manifest waits for the designer's play.
- **The record:** a run's `event` and `event_out`; a row in balance_summary and playtest_summary.

## Built, 2 Nov (BUILD46-E: the rest of the families, the rival crew, the Vagabond, the threads, the art manifest)

The designer's calls (2 Nov): a rival crew is a normal fight and can kill the runner (odds shown before, Get out now
always open, like the dogs); threads can sometimes cost you (a crew you robbed can come back; mostly rewards); the
traders' buffs are run-only and they get better with dealing. Every figure below is a draft for the pass, in
data.gd's run events block; the words in words.gd's `EV` and `ORDERS`, drafts for the language pass.

- **The ten families**, in the standing orders' order: Someone in need, A threat passing, A locked thing, A trader,
  A dangerous place, A stash with a catch, A body, A wreck, A broadcast, The weather turning. Each new one has its
  pools (zone, site kind, weather, night, level weights), its lines a zone, its standing order and test shapes in the
  scene. Every non-threat pauses, odds and costs on the face, "Leave it" last and free (the weather's is "Let it pass").
  - *A dangerous place*: Go in (15 s, 60% clean) or Go in carefully (35 s, 90% clean), the odds moving as the pin's
    with night, weather and low HP; a slip −25% HP (never the last of it); a find a tier up either way.
  - *A stash with a catch*: Take it (3 s, 40% the catch: a trip −20% HP, or a watcher - the next gang now) or Check it
    first (20 s, no catch); two finds.
  - *A body*: Search it (10 s, a find, 50% a clue: whatever killed them still about - the next gang ×1.3 HP and fire,
    2 notes a man of it; or, at a site with a head, his weakness - −15% HP the next run he's out, a thread) or Go
    through the pockets (3 s, 4 men's tins).
  - *A wreck*: Strip it (20 s, 15–25 scrap) or Cut it open (8 s and 10 scrap off the pack: the site's material 2–4,
    and a find a tier up; greyed with no scrap).
  - *A broadcast*: Listen (20 s, a tip) or Catch the end (8 s, 50% a tip).
  - *The weather turning*: Press on (the turn's loot quality and the gangs' damage for the rest of the run: fog +40% /
    +20%, the light going early +50% / +25% ...), Head home (out now with the pack), or Let it pass.
- **A rival crew** beside the dogs: of threats, 25/40/50/60% by zone from run 8. The next gang's size, each man the
  site's gang ×1.25 HP and ×1.2 fire (×1.5 its difficulty), a man's XP; the same stand-off panel and stepped odds (the
  read through the real fight code on the crew's figures); seen off, what they carry - 3 notes a man, or (40%) a find
  a tier up. A normal fight: it can kill the runner on a watched run (a repeat run bails, as ever). The zone's gang art
  stands in for them (their own picture once drawn).
- **The Vagabond**, the second trader, from run 4, half of traders: tins off the run's and the rebuild materials off
  the pack's stacks. His shelf: two pieces of gear at the site's tier (25% a tier up), 4 men's tins each (more by
  rarity, ×1.5 a tier up); a rumour 35% of visits (a tip) for 3 materials, or 3 men's tins with none. Standing as the
  Scrap man's: 3, another piece; 10, 33% off; 25, the shelf a tier up and a rumour every visit. Gear off his shelf
  goes into the pack and comes home as a find.
- **Threads** (saved, each list three at most, the oldest dropped): a freed person (the Yard's runner, as the slice);
  a tip - a stash at another open site on a later run there (the run's event: no catch, two finds a tier up), or word
  of the Vagabond (the next run's event is him), stale after 12 runs; a robbed crew - a bag taken from someone in
  need, or a crew seen off (half the time) - while one's out there a threat is ×1.5 likelier and 60% of threats are
  them, back for you; a head's weakness; a trader remembers you (his own lines once you've traded).
- **Standing orders**, player-like as the slice's: Go in carefully, time allowing; Check it first; Search it; Strip it;
  Listen; Press on at 80% odds or better. A threat's order covers the crew. Dry runs never roll an event.
- **The art manifest** (tools/make_run_events_manifest.py): 38 jobs ($3.04; fix 46: the crews' fire and down
  dropped - in the fight the gang's figures stand in) - a rival crew a zone standing, two dogs (lean, big) standing /
  firing / going down, the one in need a zone down and up, the two traders at their barrows,
  nine props shut and open (cabinet, shutter, van, safe, hazard, stash bag, body, wreck, radio); the test manifest's
  four ($0.32) first. event_prop.gd finds each by name (art/events/<name>.png) at the slot's scale on its feet, the
  shapes where it isn't there. Not flagged: the designer drops `art.flag`.
- **SAVE_VERSION 21.**
