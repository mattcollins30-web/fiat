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
