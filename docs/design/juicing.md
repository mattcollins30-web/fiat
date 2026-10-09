# Map juicing: the Radio's words as PoE maps (9 Oct 2026)

From Matt's playtest: "The radio is a good start but it's a ways off the PoE system of juicing a map with stupid
modifiers for stupid rewards ... it shouldn't even be an option until you unlock the map and depths - rerolling
words on campaign levels is just wrong ... maybe a note found in the wild unlocks a modifier permanently that can
be selected or rolled. We then need to work on how those words are crafted and applied to a zone - not just a flat
random roll - picking from pools - basically PoE's maps system - needs to work in harmony with the map ... The map
screen also needs to be updated to follow the changes we've made to the skill tree and yard."

Agreed with Matt (9 Oct): **papers teach the words**; **a site's words stay until you change them**; **crafting is
paid in notes**; **the map becomes lanes like the trees**.

## Today

- Every run home re-rolls the unpinned words on every site, campaign sites included; Pin is the only brake.
- One flat pool of 17 words, no tiers; Resistant's `min_depth: 8` is never read.
- Juicing is Pin + Call in at a price that climbs with the word count; no crafting.
- The map's "The air" column and the Yard's Radio lane overlap (two "+1 word", two price cuts, two bite/pay
  scalers).

## 1. When

- **Campaign sites carry no radio words.** The sky (Night by the clock, rain, fog) stays as it is: the world, not
  juice. A site gets words once its ladder is open - the campaign done - and only at depth 2 or deeper.
- The Radio room before then: the sky's forecast and "Nothing on the air until the depths open".

## 2. Learning words: the book

- **Reading a paper into the book teaches the Radio its word, for good** (`book` already moves with the Yard). The
  paper's card names the word it teaches; the Radio's book shows every word known, and the shapes of the ones
  not yet heard.
- Four words are known when the campaign ends. The fourteen plain papers teach fourteen more. The six deep papers
  (the ration book at depth 12 ... the Manager's note at 50) teach the six **deep words**, the stupid ones.
- **Zone words**: three a zone, known once a site of that zone is cleared at depth 2.

## 3. Words, tiers, totals

- Each word has a **bite** (what makes the run harder) and a **pay** (what it brings home). Three **tiers** by the
  site's depth: **I** from depth 2, **II** from 8, **III** from 15. As built: a multiplier m at tier I is m^1,
  m^1.75, m^2.5 (m^3.5 at Twist's IV) - HP +40% is +80% at II, +132% at III; an added figure (quality, a share,
  a resist) ×1, ×1.75, ×2.5; a count (one more on you, loot tiers) and a flag stay as they are. A roll lands the
  highest tier the depth allows half the time, a lower one otherwise. A word works at the tier the site's depth
  allows now: a site juiced deep and run shallow works shallow.
- A site shows its **totals**, the way a PoE map shows quantity and rarity:
  *You get: Finds +64% · Quality +40% · Pack +30% · Cash +25% · XP +50%* and
  *They bring: HP +70% · Fire +30% · Gangs 30% sooner · One more on you*.
- **How many**: 2 words at depth 2, 3 at depth 5, 4 at depth 9; the map's Long wave and the Yard's Long range
  one more each (6 at most).

## 4. Pools

A roll draws from three pools, only words known and only words the depth allows:

| Pool | Weight | Holds |
|---|---|---|
| The zone's | 40% | its three zone words |
| The general | 50% | the four starting words and the fourteen from papers |
| The deep | 10% | the six deep words, each from its own depth (12 ... 50) |

No word twice on a site. (The draft's lean by the site's shape is not built: the words' pays don't map onto the
shapes' leanings - papers, ammo, meds. A question for the balance pass.)

## 5. The words (first figures, tier I; the balance pass sets them)

| Learned from | Word | Bite | Pay |
|---|---|---|---|
| known | Numbers | HP +40% | Finds +30% |
| known | Tooled up | Fire +30% | Quality +25% |
| known | Delivery day | Gangs 30% sooner | Cash +40% |
| known | Ex-army | HP, fire +20% | XP +40% |
| A council tax reminder | Bailiffs | Pack +30% | Cash +30% |
| A P45 | Laid off | One more on you | XP +50% |
| A betting slip | Long odds | Fire +50% | Quality +40% |
| A pawn ticket | Pawned | Your armour counts a quarter less | Finds +35% |
| A bank statement | Overdrawn | No cash from kills | Finds +60%, quality +30% |
| A food bank voucher | Hungry | Searches half as slow again | Finds +40% |
| A mortgage offer | Burners | A third of their fire is fire | Finds, cash +20% |
| A school report | Cutters | A third of their fire bleeds | Finds, cash +20% |
| A lottery ticket | Wired | A third of their fire is shock | Finds, cash +20% |
| A wage slip | Jacketed | Fire res 40% | Cash +30% |
| A parking ticket | Rubbered | Shock res 40% | Cash +30% |
| An eviction notice | Hardened | Physical res 30% | Cash +30% |
| A boarding pass | Night owls | Pace −20% | Quality +50% |
| A Christmas list | Everyone's in | Pack +25%, gangs 20% sooner | Finds +40%, XP +20% |
| The Estate | Dogs off the lead | Gangs 20% sooner, pace −10% | Finds +30% |
| The Estate | Kids on bikes | One more on you | Cash +25% |
| The Estate | Lock-ins | Searches slower | Quality +30% |
| The Town | Security | Physical res 20%, HP +20% | Cash +35% |
| The Town | Market day | Pack +40% | Cash +40% |
| The Town | Shoplifters | Gangs 25% sooner | Finds +35% |
| The City | Squaddies | Fire +40% | XP +60% |
| The City | Checkpoints | Pace −15%, HP +20% | Quality +40% |
| The City | Kitted out (depth 8) | All res 25% | Quality +50% |
| A ration book (12) | Rationed | No meds on the run | Finds +100% |
| A council minute (18) | Curfew | Every gang twice the size | Finds, cash +80% |
| A bus timetable, amended (24) | Last bus | The run ends at four minutes | Quality +120% |
| A letter to the Bank (30) | Foreclosure | HP ×2.5 | Loot two tiers up |
| A list of names (40) | Everyone's here | Pack ×3, two more on you | Finds +150%, XP +100% |
| The Manager's note (50) | The Manager walks | The zone's head on every run, free | His drops every run |

Today's Night word is Night owls; Quiet road, Lying low, Spread out, Cash about and Picked over go (they paid
for an easier run, which juicing isn't). Resistant becomes Kitted out.

## 6. Crafting a site's words (notes; first prices, d = the site's depth)

| Craft | PoE | Does | Notes |
|---|---|---|---|
| **Tune in** | transmute / aug | adds one word, rolled from the pools | d |
| **Full broadcast** | alchemy | an empty site filled to its most | 3d |
| **Retune** | chaos | every word rolled again | 2d |
| **Hold** | (fossil) | one word kept, the rest rolled again | 4d |
| **Call in** | essence | one word of your choosing from the book | 8d |
| **Clear** | scour | every word off | ½d |
| **Twist** | vaal | one of four (below); the site is **sealed** | 6d |

- **Twist**: 40% one word goes to **tier IV** (×3.5 of tier I); 25% a deep word lands, known or not, any depth;
  25% nothing; 10% every word rolled again at its depth's top tier. Sealed: no craft but Clear, and Clear on a
  sealed site costs ten times as much.
- **Words stay until you change them.** No re-roll after a run, so Pin and Lock go; a juiced site runs for hours.
- A Yard move: the new yard's sites start silent (the map's Held frequency keeps them).

## 7. The map as lanes (the trees' layout)

Three lanes - **The sites**, **The crews**, **The air** - each six columns of two nodes, ranked with map points as
now, a column opening on the points spent in that lane (the trees' gate, ⌈0.6 × the cost of the columns
before⌉). The sites' and the crews' twelve nodes keep their effects, paired in their present order; the air's
twelve are new - the juicing tree:

| Col | Pick | Pick |
|---|---|---|
| 1 | Good reception (2): every craft 15% cheaper a rank | Clear air (1): name a known word the Radio never hears |
| 2 | Booster (3): every word's pay +10% a rank | Held frequency (1): a site's words hold through a move |
| 3 | ★ Long wave (1): one more word a site | Tip-offs (2): quality +5% a rank |
| 4 | Strong signal (2): a roll lands its top tier more, then one past the depth's cap | Early word (2): Call in a quarter cheaper a rank |
| 5 | ★ Relay (1): a **standing word** from the book on every site past depth 2, at its top tier, over its own (the sextant) | ★ Bent (1): Twist's tier IV twice as often |
| 6 | ◆ The whole band (1): a second standing word | |

Word travels, Open channel, Dead air go; Fair weather, Night eyes and the Forecast move to the Yard's Radio
(below).

## 8. The Yard's Radio lane

Its columns open from the start, before any word is on the air. Proposed: its first two columns help the
campaign through the sky, the rest the juicing:

| Col | A | B |
|---|---|---|
| 1 (start) | Weather set: rain and fog bite half | Night set: Night's slower feet halved |
| 2 (Town) | The forecast: +20% cash under rain or fog | Dead air: at Night the gangs come a quarter later |
| 3 (City) | Scanner: every craft a quarter cheaper | Two channels: Tune in and Retune roll twice, the better kept |
| 4 (campaign) | Lorry watch: the convoy two depths shallower | Long range: one more word a site |
| 5 (depth 6) | Jammer: every word's bite halved | Military band: every word's pay half again |
| ◆ rank | every word's pay +5% a rank | |

## 9. The screens

- **The Radio** (Radio-J A, as built: `scripts/ui/radio.gd`): the sites with ladders, each with its words (tier,
  bite, pay) and totals; the seven crafts with their prices in notes (a hover names what a craft does, its price
  and why it can't); the book, its unheard words shown by what teaches them, the standing words and Clear air's
  filter set from its buttons.
- **The Runs card**: the word chips carry their tier (II); the totals line under them.
- **The map** (Map-L): three lanes like the Training screen.

## 10. Saves and balance

- An older save's site words are cleared (the campaign sites lose theirs); the book teaches its words at once.
- Balance gates for the pass: a juiced site (four words, tier II) brings home at least twice the finds of a silent
  one at the same depth for no worse than a third lower odds; the notes from a run at depth d pay a Retune at d.
