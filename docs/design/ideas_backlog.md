# Ideas to revisit

## The queue after the playtest (28 Oct)

Matt plays 23c71d1 from a fresh camp to the County and a pinnacle first. Then, in order:

1. **Itemisation** (docs/design/itemisation.md, designed 29 Oct; canvas TierMap, BaseGrid, Gloves; ahead of the trips): the campaign's tiers
   cut to 1-4 with 5-6 from the early signals, more bases sideways within a tier, gloves as an eighth slot.
   Measured against Matt's playtest log of each gun held and for how long.
2. **Repeat runs, trips and the Bunkhouse** (docs/design/trips.md, designed 28 Oct; canvas RepeatRuns, Trips,
   Bunkhouse), with the wagers.
3. Anything Matt raises from here that isn't a bug fix or a UI change, below with his words and the date - if it fits
   docs/design/vision.md at all.

### Raised 29 Oct: itemisation (from play, before the fresh playtest)

Matt, on rifles and SMGs: "it feels bad in practice ... It feels crap throughout and the campaign's pacing means that
you don't actually keep anything for very long at all. I wonder if the answer is both more items in general but also
less tiers available during the campaign. The campaign stops at tier 4 with the early radios giving 5 and 6 so the step
up feels rewarding. I also think that gloves need to be added as an item type that would carry affixes for pace etc."

What the data says (23c71d1): 162 gear bases, 120 of them in the campaign (tiers 1-6); a campaign site steps the tier
four times (the Parade T3, the Shopping Centre T4, the Bank T5, the Hospital T6); rifles have one T4 gun (the Scoped
.308); tiers 7-9 hold 9 rifles and SMGs between them against the campaign's 21; SMGs out-damage rifles at every tier.

Three parts, each its own size:
1. The campaign's tiers cut to 1-4, tiers 5-6 from the early signals: a pacing and balance change (the bases'
   tiers, the sites' and signals' loot tiers, the Fence and gamble, the bot's gates), a full pass after.
2. More bases, sideways within a tier (a choice of how a gun plays, not only a bigger number), most of all where the
   lists are thin; with art (the PixelLab pipeline).
3. Gloves, an eighth slot: pace, reload and handling affixes (reload matters since the magazines), bases by tier,
   uniques, the Runner room's loadout redrawn for eight cards, art.


*Banked 11 Oct, from asking Claude what it would add. Nothing here is agreed; each goes through design with Matt
first. Matt's framing: Fiat is an auto-battler ARPG (Melvor's kind of active), the away settle its only idle
system. The guard rail: no new systems. Each of these sharpens one that's there.*

1. **The playtest record.** Built 11 Oct (docs/design/playtest_record.md).
2. **Upgrade arrows in the stash.** Built 11 Oct. A small ▲ on any stash item that beats what's worn in its slot, so the stash
   reads at a glance without opening the compare.
3. **"What came back."** Built 11 Oct. A card after each run: the best find, the money, the XP, levels gained, anything new
   (a first paper, a unique, a depth). The run's payoff, shown once instead of scattered.
4. **Junk rules.** Built 11 Oct. Replace the auto-sell toggle with a couple of rules: sell under a rarity, sell anything worth
   less than what's worn, keep a type. Fewer stash trips.
5. **A controller / Steam Deck pass.** Focus order through every room, tooltips that open on focus as well as
   hover, the shoulder buttons for rooms.

Later, if they still look right:

- **Saved loadouts per past**, swapped with the class.
- **A weekly broadcast**: one site modifier the radio announces each week, for a reason to go back to old sites.

- **Dots and the kill** (11 Oct): a kill throws away what the dots still had to tick (bar the carry nodes). The skull
  on the bar shows when they'd finish it (built). Next, after the playtest: a bot probe of the dot damage lost on
  kills, by build - small, leave it; large for poison and bleed, half carries by default and the carry nodes take it
  to all; an execute only if both fall short.

- **The odds swing on the weather** (23 Oct, found rendering the Map's hint chips on Matt's 22 Oct save, a level-12
  Drifter at the Bank): the same runner read 0% in plain weather and 100% in fog ("one fewer on you": contact 3 to 2).
  A third of their fire off turning a certain death into a certain clear says the fight's knife-edge is too sharp at
  the frontier - or that contact is too strong a lever. A number for the balance phase: read the odds across every
  weather on the pass's saves, and the contact's share of the incoming.

- **Magazines you find** - pulled forward the same day: designed in docs/design/meds_ammo_clinic.md, "Magazines as items". (30 Oct, Matt, mid-playtest: "in practice the magazine thing doesnt hold - you need to be able
  to find magazines and then fill them up out of boxes - then put them into the rig. That then allows us to increase
  mag capacity via the attachements in the workshop"). Today (28 Oct design, docs/design/meds_ammo_clinic.md):
  magazines aren't items - a rig pouch of rounds is 3 of the gun's magazines, filled free from the stash's boxes. Not
  covered yet: the Workshop's magazine parts (Extended, Quick, Drum, Belt box, Hundred-round drum) give damage and pace,
  not capacity - the review's design call 5. To design after the playtest, with parked item 4 (the hand-load mid-run,
  which this reshapes) and call 5: a magazine an item by type (found in crates, sold by the Fence), filled from boxes at
  home or by hand mid-run, carried in the rig; its size from the magazine, an Extended or Drum one bigger. Open: is a
  bigger magazine an item of its own or a part on the gun; is a gun with rounds but no magazine dead, or does it load
  one round at a time; the first gun's reward then carries a magazine too.

- **Materials in the pack** (1 Nov, Matt: "move all materials into the inventory during fights instead of finding
  them invisible and returning from runs with them. So scrap, end game materials etc - reason for the ask is that
  finding clinical supplies and having to make a decision over bringing them or gear is a real choice"). Today
  medical supplies are already a stack in the pack; scrap (a handful a search, SCRAP_SEARCH 0.35) and the rebuild's
  materials (copper wire, paving, glass, ledgers, cable drums, army kit, fuses: MATERIAL_RUN / MATERIAL_SIGNAL)
  are counters on the run that land at home, as are tins and notes. Art exists for all of them (art/items/scrap.png,
  copper_wire.png ...). To design with Matt, then build; it moves the balance (pack room against gear, the bot's
  keep/ditch, scrap and rebuild income).

- **Run events with art, a pause and choices; recurring traders** (1 Nov, Matt: "we also need to add art to these
  events and a pause in the gunplay because at the moment a log line just doesn't make it compelling enough. Yes a
  choice is good ... with materials being in inventory we could introduce recurring characters like a scrap trader or
  a vagabond that trades in tins or scrap or certain materials for buffs during the run as well as gear on offer").
  Today: three events (convoy, trapped, cache) at EVENT_ODDS 0.3, a log line each, no choice, two of three pure
  upside. To design with Matt (canvas mockups, test art before any manifest); builds on "Materials in the pack".

## Act two: why play past the campaign, and signals worth playing (raised 4 Nov, Matt, the 0.12.2 playtest)

Matt, at level 28 on the Doorman, 5.7 h, after the XP read: "clearing the campaign and just playing the game - why ?
why state in the story opener that you have a camp/pitch and tins are currency - but why ?" and "radio signals are
just too weak to sustain play - if they were more fun then I would've been willing to grind, bugs notwithstanding."
Design, ahead of the numbers plan (XP taper, the order's and the County's levels, repeats, aimed crafting - proposed
4 Nov, held): the numbers only move the wall if there's a reason to cross it. To talk through with Matt before any
design: what the camp and the money are for past the campaign; what makes a signal a thing worth running.
Then (Matt): "part of the friction was setting one up, tuning the codes, running it and being done in 30secs then having
to repeat the whole process to go again - think we need to be able to chain them together". Drafted for his calls:
docs/design/act_two.md (4 Nov).

## Leaving a head's thing behind should cost its room (parked 1 Nov, Matt, during the 0.10.3 playtest)

Matt: "we made the vet's bag and other quest items an actual item that drops - what's the penalty for just leaving it on
the ground? presumably the room opens regardless. We should make a clear choice here so that if you do leave the quest
item then the owner of that item is handicapped somehow - clinic heals slower or doesn't stock as much, fence doesn't
sell as many items etc." Today: the drop is the sign - the head's thing opens its room when it drops (sim.gd, "the drop
is the sign"), so leaving it costs nothing. To design: the room opens either way, but brought home it opens whole;
left behind it opens handicapped (the Clinic heals slower / stocks less, the Fence's shelf shorter, ...) until a later
fix (fetch it on a rerun? the head's thing turns up again?). One handicap per room, shown on the room. Not this round:
in before the next balance pass, with everything else that moves numbers.

## Two magazines in the rig: the empty one refills while you fire the other, as an upgrade (parked 1 Nov, Matt, the 0.10.3 playtest)

Matt: "if I have two mags in my rig I want the one that runs out first to be reloading while I'm shooting from the
other one - or actually let's make that some sort of upgrade." Today a spent magazine refills on its own, slowly, from
the box in the pack (0.10.2, docs/design/meds_ammo_clinic.md). The idea: an upgrade (a rig affix, a Workshop part, a
tree node or the rig's own tier - to decide) under which a spent magazine refills in the background while the next is
fired, so two magazines mean no pause. In before the next balance pass, with everything else that moves numbers.


## Animations for the skills (parked 9 Nov, Matt)

Matt: "we need animations for the skills." Today a skill firing in the fight shows its name across the frame (run.gd,
the skill word) and its effect in the numbers; the skills have a still picture each (art/skills/<id>.png, the bar
and the web) and nothing moves. To design: what a skill does on screen when it fires - over the gang (a flashbang's
white-out, a grenade's burst, a medkit's green on your bar) or on the hands (the reload, the swap) - in the rail-shooter
view Matt chose (13 Oct: no head-on characters), likely PixelLab "Animate with text" clips or code-drawn effects over
the plate, one look a skill's kind before one a skill. UI and art, moves no numbers: after Matt's 0.15 playtest, with
the design canvas first.

## An ARPG gameplay window in place of the fight window (raised 9 Nov, Matt - a design conversation first)

Matt: "This game was always an arpg first and only my experience stopped it from being designed that way from the
start. I'm wondering now if the fight window which is all sick anyway is just replaced with an arpg style gameplay
window instead." Touches vision.md's first line and pillar ("A run fights itself; your job is what goes in"), the
fight sim (rate-based ticks, not positions), the balance bot and harness, the Deck/gamepad work and the Steam dates.
Talked through 9 Nov: Matt means full control ("there's no point changing what we have to one and two as it already
works") - scoped in the chat as an option, out of interest. No build until Matt's 0.15 playtest and his call.

The slice, for the round after round 6 (9 Nov, from the slice's review; Matt: "Review the arpg slice and detail
improvements"): kinds of men (a rusher, a marksman, a man who throws); the hard man's own behaviour; a dodge or a
sprint; head aim that pays; half-cover you fire over; hit feedback (a flinch, a hit mark, their HP bars); a sight
cone or a soft edge to the fog. Each needs its mockup and Matt's word before a build.

What the shift keeps (10 Nov, Matt: "review the core game and figure out what can be retained with the shift to the
arpg fight style. Balance and bots included"): the review is the doc "Lesser England - what the ARPG fight keeps"
(https://claude.ai/artifact/FwJwFByyKs3uhEvxrQccxB). Its first open call: keep the game's fight as the runner alone
beside the fight under your hands, or only the one. No build. Matt's call the same morning: "First point is want to keep
both and allow auto runs on already cleared sites." So: the game's fight stays as the runner alone (odds, the other
runners, the hands' trips, the convoys, the balance reads), and a site cleared by hand can be run by the game on its
own. To design when the ARPG fight goes past the slice; no build.

The slice, raised 10 Nov before Matt's play of round 6 (Matt: "Don't add any of these I just want them out of my head
and onto the board for now"):
- Searching a crate in the Kit room. Matt: "the inventory screen needs to be shown when searching crates and the crate
  itself replaces the runners gear slots side of the view. Tarkov style it searches as your in the inventory and then
  you drag and drop from the crate to the inventory once searching is complete. This replaces the search we have at
  the moment."
- The same for bodies. Matt: "the above also applies to bodies during and after the fight for dropped gear - this
  presents a problem for the gear screen tho as one of the rules we have is equip from floor so you don't need the
  backpack space to equip a new item." Open question, his: with the crate or body where the worn slots are, how a
  find is worn straight off the floor without pack space.
- Laser sights and torches. Matt: "we need to add last sights as an attachment and it needs to be visible in the
  fight, same for torches we already have." (Read as laser sights - to confirm.)
- Melee, damage over time and splash. Matt: "melee needs some thought along with dots and splash damage."
Each needs the talk, its mockup and Matt's word before a build.

## Measure when the resists cap (parked 9 Nov, Matt: "Log is in the backlog after my play test")

Matt asked whether a good player can roll 75% in all five resists with every damage line for the build (a poison
Poacher). By the tables, yes: 375 points needed against ~500 reachable (a T5 element line ~33, "all resists" ~70 a
line, Immune +20, sets, "Add a resist"); the perfect poison gun is ~1 in 200,000 as a drop but a padlock, leeks, Bitter
beet and marrow chase. To do after Matt's 0.15 playtest: the long reads' HOUR line records the hour each build caps all
five resists and its share of on-build gear lines; read alongside Matt's play. Watch: capping arriving mid-game, and
"all resists" worth about twice a single element's top roll at 0.3 weight.
