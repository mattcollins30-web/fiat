# Mythic uniques (16 Oct - agreed by Matt, "mythics look good"; built)

Matt, 16 Oct: "a really powerful unique per slot - think mythic uniques from Diablo 4 - with a flat % drop rate across
the entire game - same drop rate in campaign as depth 9. We don't need to balance around it ... if you do get one then
the point is that it does break game balance by its nature."

## The rules

- **Seven, one a slot:** Primary, Secondary, Helmet, Armour, Rig, Backpack, Charm.
- **One flat chance a find, everywhere:** the Allotments' first search and a level-40 signal alike, no depth, quantity,
  quality or Lucky Cap in it. Proposed `MYTHIC_ODDS` 1 in 10,000 finds: the bot's reads find 150-350 a hour past the
  campaign, so one in roughly 30-60 hours of play, earlier for a lucky few. (1 in 20,000 halves that.)
- **Which one:** any of the seven, evenly; one you already hold isn't rolled again until you've seen all seven.
- **Wearable at any level** (no item level gate), never sold by the bot, never lost to the clock or a death (the Fence
  holds the paper on it), kept through a Yard move as uniques are.
- **Outside the gates:** the balance read rolls none (`mythics_off` in the bot, as crates_off), so a read is never one.
- **Its own look:** a fourth band past chase, its own colour on the card and a line on the Events log when it drops.

## Seven to pick from (names and effects are drafts)

| Slot | Name | What it does |
|---|---|---|
| Primary | The Last Orders | Every shot is all four elements at once at full strength: burns, chills, shocks and poisons, every element's keystone counted as yours |
| Secondary | The Spare Key | The secondary fires as a primary: both guns at full rate, every primary rule and node applying to it too |
| Helmet | The Headmaster's Cap | Every node in your class's tree is taken, and every element's keystones open - the tree's points still yours to spend on the Yard's |
| Armour | The Bomb Disposal Suit | Nothing does more than a twentieth of your HP a second, whatever's on you; the clock never runs out on you |
| Rig | The Ambulance's Bag | Meds are never used up, and one goes on by itself whenever you're under half |
| Backpack | The Removal Van | The pack never fills, every find is a tier up, and every search finds two more |
| Charm | The Freedom of the Borough | Gangs never come after the clear; every search's crates open; tins, notes and XP doubled |

Each is a rule (as the uniques are), so most of the work is the rule's line in the fight, the search or the loot, plus
the drop roll, the card's band and the art: seven item pictures in art/items at the uniques' size, and the band's colour.

## Order of work (house rules)

1. Matt picks and shapes the seven (this doc).
2. Mockup on the design canvas: the mythic card, the drop's toast and the Events line.
3. Build: the roll, the seven rules, the band, smoke checks (the roll's rate on fixed dice, each rule's effect, the
   balance read rolling none); the reviewer; the watcher's smoke.
4. The art manifest for the seven (tools/make_art_pass_manifest.py), test art first.

## As built (16 Oct)

- The Removal Van's "never fills" became **four times the pack** (MYTHIC_PACK): an endless pack paged the run's grid
  past a hundred pages and the Lorry's Load paid notes for every empty cell of it (the review).
- The Headmaster's Cap gives every node of the class's own trees **but their keystones** - their costs are the point
  (Hit and run would end every run at the first gang). The tree screen still draws only what's trained.
- A worn mythic is never swapped out by Equip if better or the bot (its rule is in no figure), never sold in a lot.
- The card (docs/design/mythic_card.png): the band's colour (#ff5a36) on its edge and its rule chip, "Mythic" on the
  figure line, worn at level 1. The drop logs "A mythic: <name>". Test art: each wears its base's picture until its own
  is made.
