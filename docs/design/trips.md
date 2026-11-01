# Repeat runs, trips and the Bunkhouse (28 Oct, a design for after the 0.9.1 playtest)

Matt (28 Oct), on the dead time in the runs: "I know it's an auto battler however staring at the same animations over
and over gets old". Agreed the same day: repeat runs on a cleared site, runs safe to leave, the endgame's activities
(wagers first), and trips - "something like a long campaign run headed up by a runner and then some other staff would
fit the game here - especially if we're trying to rebuild or sustain our pitch" (Dragon Cliff's farming: hired staff
mixed with your fighters, sent as a team, bringing back by where they went and who went).

Nothing here is built. Every number is a placeholder for the balance pass. Words on screen are drafts for the language
pass. Build order: the first item after Matt's playtest from fresh to the County and a pinnacle (28 Oct); everything
else he raises queues behind it in docs/design/ideas_backlog.md.

## Matt's calls (28 Oct)

1. A run nobody watches **bails** at its HP line: the pack is lost, never the loadout. Death only on a watched run.
2. A trip is **resolved by the odds sim** on its route (the dry reads the gate shows), the crew's kit and the hands'
   trades in, not a new fight model.
3. A trip's crew is **a runner and hired hands**: one of the camp's other classes' runners leads; hands are hired, each
   with one trade, levelled by trips and paid a wage a trip.
4. **Designed now, built after the 0.9.1 playtest.**
5. A repeat run's XP **starts low and is upgraded** (my figures: 25% up to 60%, capped under a watched run's).
6. **The selected runner can't go on a trip**: a watched run always pays more or is worth it.
7. Trips are **late** (after the Quartermaster), to **far places** with their own art, no fight art; paying consumables
   and gear (uniques, sockets). **Cargo in**; **the hold-up**.
8. **The hands come in the gear's tiers with affixes**, hired and fired from a pool (Dragon Cliff).
9. **New art for the lot** (the PixelLab pipeline).

Two older calls this changes, said to Matt before his calls: "no auto-run, nothing sets off by itself" (21 Oct) - a
repeat run is one the player starts, nothing goes out again on its own; "materials from runs only" (18 Oct, the
rebuild) - a trip counts as a run (a crew goes and fights). The world still waits while the game's shut (24 Oct): a
trip's clock is played time.

## 1. Repeat runs: "Run it ×5"

- On a site's card once it's cleared, and only while the gate's odds are 90% or better (the dry read the card already
  shows). Below that the button is shut, the reason on it.
- The runs take their real played time, one after another; the run screen isn't shown. The runner is away (the rail
  says so, with a bar for the five); the camp's rooms are free to use. "Bring them back" ends it after the run out.
- Between runs the runner rests at camp as a hand would (the Clinic's rest rate), tops up the rig from the stash
  (`Sim.pack_rig`), and goes again.
- The pack: the sorting rule keeps an upgrade on what's worn, a paper, a deed and a mythic (the full-pack rule of 15 Oct)
  and sells or bins the rest at the gate by the Stash's rules - the Sorting line on the Pitch.
- The report: one card when they're back - runs done, kills, finds kept (by rarity), tins, scrap, materials, wounds,
  bails, XP and levels. Each run's line under it, folded.
- The bail: a run under its HP line (25%, the bail the bot already uses) leaves at once; its pack is lost, the next run
  goes only at full HP; two bails in a row end the repeat.
- XP (Matt, 28 Oct): starts low, 25% of a watched run's, raised on the Bunkhouse to 60% at most, so a watched run
  always pays more. Halved on every step 1 Nov (the designer's call, the long pass's level pace): 12%, 17, 22, 30.
- Upgrades (a Pitch line, section 4): ×5 from the start, then ×10, ×20, then "until the stash is full".

## 2. Safe to leave

- Every unwatched run bails (1). The watched run is as now: it can die.
- The pack sorts itself on an unwatched run (1, the sorting rule); a full pack ends that run, not the repeat.
- A wound on an unwatched run ends the repeat (the Clinic first).
- On a watched run nothing changes; the wagers (section 5) live there.

## 3. Trips (the endgame's: after the Quartermaster)

Matt (28 Oct, the second round): trips are late, an endgame activity, to far-flung places with art of their own and
no fight art; they pay consumables and gear (uniques, sockets). Taken from Path of Exile's Settlers of Kalguur
(3.25, Kingsmarch's shipping and workers), with Matt's calls: **cargo in**, **the hold-up**, **open after the
Quartermaster**.

### The shape

A crew - a runner of another class leading, up to two hired hands - takes **cargo** to a **far place** and comes back
after a stretch of played time with that place's rewards, scaled by the cargo, rolled by the crew.

- **The lead**: any of the camp's runners but the selected one (Matt: the runner you have selected can't go, so a
  watched run always pays more or is worth it). Their kit and level go into the odds; their class weights the return
  (Scrapper parts, Paramedic supplies, Poacher hides, Doorman tins, Drifter papers, Recruit army surplus).
- **Cargo**: salvage, rebuild materials, meds, scrap, notes - what the camp has farmed. Each kind has a worth; the
  return's size and quality follow the cargo's worth (Settlers: "shipment value"). Trips convert, they don't print:
  (31 Oct, Matt: an average expedition, bad rolls and hold-ups in, brings home about x1.2 the cargo; shipped scrap still never beats the Fence; the exchange round trip may pay on small low-risk trips - accepted.)
  the contracts' problem (24 Oct) answered by an input, not a cap. The Outskirts and the Estate stay worth farming late,
  as the cargo's source.
- **The risk**: the cargo's worth over the crew's strength fills a risk meter; the hands' trades bring it down. A bad
  roll loses 25-100% of the return. No one dies (Matt's call 1).
- **The hold-up**: now and then (rare; more at high risk) the crew comes back held. Three ways out: the selected runner
  goes and gets them (a watched run at a site we already have fight art for, its head the holder, its own drop), pay
  the ransom (tins or fiat), or walk away (the cargo and the hands sent are lost to the pool - they leave the camp).

### The far places

Country-wide (Matt, 28 Oct: "the places need to be further out, Kev's story intro talks about London and others so
we go country wide"; the air's second scene: "Swansea's gone quiet. Bristol's one big checkpoint. Nobody's answered
from London since the spring."). Each its own reward class, so the player picks a place for what they want:

| Place (names for the language pass) | Pays most | Its quota pays | Time |
|---|---|---|---|
| Swansea, gone quiet | meds, the Clinic's supplies | a mythic chance | 30 min |
| The Bristol checkpoint | tins or fiat, gamble tokens | the Gambler's table rerolled free | 50 min |
| Salisbury Plain | issued parts, army surplus | an issued set piece | 1 h 20 min |
| The Birmingham depots | rebuild materials, fuses | a rebuild done half price | 1 h 40 min |
| The Liverpool docks | sockets, charms, gems | a socketed unique | 2 h |
| London | uniques by slot (pick the slot) | a named unique | 3 h |

- Distance sets the time (30 min to 3 h played). Each place shows its **quota** (what it wants this week, by the
  exchange's day): meeting it adds 20-100% and the quota's item (Settlers: a unique, usually).
- Art: one painted picture a place (a card and the Map's far edge), the hands' faces, the Bunkhouse. No fight art.

### Resolved

- When the time's up, the crew's odds are read with the odds sim (Matt's call 2) against the place's strength (a tier
  and a gang type, no art), the scout's odds in; the result sets the risk's roll; the return is rolled from the place's
  table at the cargo's worth, then the lead's and the hands' weights.
- Trips out at once: one, then two and three on the Bunkhouse.

### The hands: hired like gear (Dragon Cliff)

Matt: hands come in the gear's tiers with affixes, "a reason to hire and fire from a pool rather than a set and forget".

- A hand is built as a piece of gear: the **trade** is its base (porter, medic, scout, cracker, driver, and a
  quartermaster: more cargo carried), a **tier** and a **rarity**, and 1-4 **affixes** from a pool for trips only
  ("+8% odds on trips", "−10% risk", "+1 cargo slot", "+15% sockets from Liverpool", "never held up in London").
  Rolled by the item code, shown in item cells - one system, not two.
- **The pool**: the Bunkhouse shows a pool of hands to hire (six); a reroll costs tins, a better reroll more
  (Settlers: 2,000 / 16,000 gold). Hired hands are kept on a roster with a cap; **firing** frees a place.
- A wage only for a hand sent (not Settlers' drain), by tier and rarity. A hand gains levels by trips (their affixes'
  rolls rise, as an item's quality).
- Hurt for a trip when a trip goes badly; lost (leaves the camp) only when the player walks away from a hold-up.

## 4. The Pitch: the Bunkhouse

A ninth building, two lines (as the Pitch's buildings since 86da52a); the hands' pool and roster on its card.

| Step | A: Repeat (from the start) | B: Trips (after the Quartermaster) |
|---|---|---|
| 1 | Run it ×10 · XP 17% (35% before 1 Nov) | A hand on a trip · the pool of six |
| 2 | The sorting rule's own list · XP 22% (45% before 1 Nov) | Two hands on a trip · the better reroll |
| 3 | Run it ×20 | Two trips at once |
| 4 | Rest between runs twice as fast · XP 30% (60% before 1 Nov) | The roster's cap +4 · the far places' quotas |
| 5 | Until the stash is full | Three trips at once |
| Rank | runs a day back to full sooner | the risk −2% a rank |

×5 at 12% XP (25% before 1 Nov) is from the start (Matt: "could start at run 5 times and have upgrades available"); line B opens with
the Quartermaster, a trip with the lead alone from then. Canvas boards RepeatRuns, Trips and Bunkhouse (28 Oct,
the second round: cargo, the far places, the hands as gear).

## 5. The wagers (the endgame's first activity)

From docs/design/endgame_activities.md, row 1: before a watched run (a signal, a first clear, a head), Kev offers one
to three words that make it harder (a bigger gang, no meds, the clock halved) for a multiplier on one payout (notes, a
slot's finds, a rarity). Watching is where the risk is; the dead time goes to repeat runs and trips.

## 6. What it costs

- New: the away state for the runner (save), the repeat queue and its report card, the trips (cargo, the far places,
  the risk and the hold-up, quotas), the hands as gear (a base, the trips' affix pool, the pool and roster), the
  Bunkhouse building and its lines, the wagers on the gate.
- The bot: repeat runs on its farm, trips with its spare cargo, a hold-up fought, the wagers off; the balance pass redone.
- Art (Matt: new art for the lot, the PixelLab pipeline): six far places, six trades' faces (a few looks each, by
  rarity), the Bunkhouse (room card and building), the cargo icons.
- Smoke: each screen's fit, the bail rule, the report's sums, a trip's odds equal to the gate's, a hand's roll as an
  item's, the hold-up's three ways out.
- Size: four to five build days of 28 Oct's size (the hands as gear the biggest), then the balance pass from scratch.

## Open

- The far places' names and their quota items (the language pass).
- The ransom's price, and whether a walked-away hand can turn up in the pool again.

## Built: the expeditions (29 Oct, the trips' build and its fix round after review 29d)

Section 3, line B of section 4 and section 6's expedition parts, with the designer's calls since: open after the
Quartermaster; the selected runner never leads; cargo out, the return by its worth; six far places with weekly quotas;
the gate's dry read; the hold-up's three ways out; hands as gear; line B real. On screen "Expeditions" (a trip out is a
run); the lead and the hands are "the party". Code: Sim's "expeditions" section, Items.roll_hand, Data.EXP_* and HAND_*,
Words.EXPEDITIONS; the Map's tab (expeditions_panel.gd), the report (expedition_report.gd), the Bunkhouse's hands
(hands_panel.gd, hand_cell.gd); the bot's `_expeditions`; the balance read's `exp` field and the summary's
"Expeditions (shown)" row; smoke `-- only expeditions`. SAVE_VERSION 13.

The calls (every number a placeholder for the balance pass):

- Converts, never prints: the cargo is valued as a trade would value it - the exchange's give rate (its spread and the
  day's drift against you), scrap at what the find it came from fetches at the Fence (its exchange worth over the
  Bench's scrap multipliers, less the spread: scrapping and shipping can't beat selling), meds at the Fence's price less
  the spread. The return is ×0.85 of that; the hands' bonuses all told (porters, "+% finds", the crackers' crates at 5%
  (31 Oct: EXP_RETURN 1.55, the hands' cap x1.2 on top: x1.86 at best, about x1.2 on average with the bot's hands.)
  of the cargo a crate, a better find of the place's first kind) are capped at ×1.2. At the best hands every place comes
  back at about ×1.0 of the cargo's worth (the smoke rolls it 100 times a place). Returns are income (`_earn`).
- A far place's fight: the hardest site (the Barracks) read as a signal at the place's level - its own floor (9 to 15)
  or the reach plus its offset (−4 to +2), whichever is higher - at depth 2 at the least (never the campaign's depth 1),
  with its gang's zone types. The lead reads it at full HP.
- The risk (the glossary: the chance of a bad roll): 0.3 × the cargo's worth over the lead's kit's worth, plus 0.8 × the
  odds short of 100%, less the hands' "−% risk" and 2% a Bunkhouse rank; 2-95%. The card says Safe under 20%, Risky
  under 50%, A bad idea from 50% (Send styled as a warning, not shut). The hold-up: 4% + 25% of the risk, less "−%
  hold-ups"; never with "Never held up near" the place. A bad roll loses 25-100% of the return, a nurse's share less.
- The return splits by the place's shares, 20% to the lead's class's kind (Scrapper gun parts, Paramedic the Clinic's
  supplies, Poacher charms, Doorman tins, Drifter papers, Recruit army surplus). Loot quality: +10% a doubling of the
  cargo's worth over 2,000 tins at today's prices. Twelve finds at most; the rest as scrap; a currency's fraction kept as
  a chance. Finds with no stash room are sold to the Fence on Take it (a mythic and the quota's item come home).
- The quota: a week of 7 hours of the world's played time; the kinds frozen at the week's start (meds, the salvage and
  materials met or held - never scrap); a count worth 3,000-9,000 tins at today's prices; met once a week a place. Its
  bonus, +20-50%, is on the quota's own slot. Swansea's mythic chance is 5% (an hour's finds at 1 in 10,000); London's
  named unique is fixed when sent; Bristol's is the Fence's gamble restocked on Take it; Birmingham's the next rebuild at
  half; Salisbury's a set piece (an issued piece after the Issue).
- The Issue: expeditions out and returns waiting join the pile at their cargo's worth and convert with it (their worth,
  a waiting return's tins and budget at the pile's rate; its finds stamped as the stash's).
- The hold-up: Go after them sends the selected runner to the place's hold site (Swansea and Birmingham the Retail Park,
  Bristol and Liverpool the Bank, Salisbury and London the Barracks) with its head free; the head down brings the party
  home with the return as rolled, the hands unhurt; not down, they stay held. The ransom is half of what's coming back
  after the roll (500 tins at today's prices at the least). Walk away: the hands sent leave for good. Walk away and Let
  go take a second press.
- The lead earns a repeat run's share of a run's XP there for the expedition.
- The hands: hired free from the pool (the wage only for a hand sent: 50 × tier × the rarity's value, at today's
  prices); New faces 2,000 and Better faces 16,000 tins at today's prices. A level every two expeditions home, to 10.
  Hurt (a bad roll, no nurse along) for as long as that expedition took. Trades: porter, nurse (the design's medic),
  scout, cracker, driver, loader (the design's quartermaster).
- The Bunkhouse's rank does both lines' work: 5% quicker rest and −2% risk a rank.
