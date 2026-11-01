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

