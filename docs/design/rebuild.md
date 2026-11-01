# The rebuild: a reason past the lorry

Draft for discussion, 18 Oct. Matt's brief: "plenty to do up to and including moving the yard, but why? Outside of
Kev's story what reason is there to keep grinding? Materials that drop (in their own stash tab), each zone a chance
at a certain material, combined in the Radio (or Workshop) to unlock something based around rebuilding the game world
to tie back to Fiat. True pinnacle bosses or similar that then drop something else you need."

His four calls (18 Oct):

1. Rebuilds survive a move of the Pitch.
2. Open-ended, no ending screen.
3. Materials come from runs only (not the Fence, not contracts).
4. True pinnacles are new characters in new places, not the existing heads at their sites.

Nothing here is built. Every number is a placeholder for the balance pass.

## 1. The idea in one paragraph

The order on the radio is issuing a new currency, "its value is as stated". Nobody believes it, because nothing in
the town works. The Pitch can change that: bring back what the town was built from, and put the places that made it
a town back together one at a time (the substation, the pumping station, the bus depot, the mint). Each rebuilt place
does something for every run from then on, and some of them light up somewhere new on the map, where someone who has
been running things since the money stopped is waiting. Beat them and they drop what the next rebuild needs. The
town's worth (every rebuild, every rank) only goes up, it survives every move, and it is the number the endgame chases.

## 2. Where it sits in the loop

| Stage | What you chase now | What the rebuild adds |
|---|---|---|
| The campaign (Outskirts to City) | The heads, the rooms they open | The first materials start dropping from the Estate on, a slow trickle: you see them before you can use them |
| Kev's story (signals, the depot) | Reach, the Dial, the story beats | The rebuild opens with the Radio (Kev knows who used to run what); signals drop materials faster with their level |
| Past the depot | Mythics, sets, a better build, moving the Pitch | Rebuilds, their ranks, the true pinnacles, the town's worth |
| Every move of the Pitch | The move's bonus | Rebuilds stay; materials in hand stay; a move raises the material drop a little (the new Pitch knows the ground) |

Salvage stays what it is: copper, safe steel and army surplus build the Pitch (the Yard). Materials build the town.
Two different jobs, two different screens, never the same word.

## 3. Materials

- **One tab of their own** beside the stash, as counts, not cells. They never take stash room and are never sold.
- **They ride in the pack** (1 Nov, the designer's call, build 39-M): found on the run as stacks (a material 10 to a
  cell, scrap 50), they compete with gear for pack room. A run home (the extract) counts them into the town's materials
  and the items go. A bail or the clock running out loses them with the pack; a death too - only the dog's fetch (the
  Kennel) or the Fence's Insurance desk brings any home. The dog takes the dearest wearable kit first (guns, armour,
  the rig, the pack, a charm); with none in the pack, the dearest of the rest by sale worth - rounds, meds, magazines,
  scrap and material stacks alike.
- **Copper cable** (1 Nov, Matt): the Estate's first material was "Copper wire", a socketable's name; it reads Copper
  cable on screen and its picture is art/items/copper_cable.png. Its key stays `copper_wire` (costs, saves, odds).
- **Each area drops its own**, two per area from the Estate on, one per site pair, so a player knows where to farm:

| Area | Material | From | Fiction |
|---|---|---|---|
| The Estate | Copper cable | Ransacked Streets, the Parade | Stripped out of every house, coiled in a bin bag |
| The Estate | Paving | the Retail Park | Stacked slabs from the car park works that stopped |
| The Town | Glass | the Pleasure Park, the Shopping Centre | Whole panes, which nobody has any more |
| The Town | Ledgers | the Bank | The records of who owned what |
| The City | Cable drums | the Services, the Hospital | The heavy stuff, off the motorway works |
| The City | Army kit | the Barracks | Generators, radios, the lorries' spares |
| Signals, any area | Fuses | any signal | Rarer; every rebuild of rank 2 and up wants some |

  The Outskirts drop none: it's the tutorial, and the first material arriving on the Estate is a small moment of its
  own ("Copper cable. Kev says someone used to want that.").

- **The drop**: a run's chance at its area's material, higher on a signal and higher with its level; a head's kill a
  guaranteed handful. Placeholder: 8% a run on a campaign site, 20% on a signal plus 1% a level past 10, cap 50%.
  Magic find doesn't touch it (it's not loot), so builds don't diverge on it.

## 4. The rebuilds

A rebuild is a named place in the town, built in the Radio's new view (section 6). Each costs materials from more than
one area, so the whole map stays worth farming, and each gives a lasting effect to every run and a rank to the town's
worth. A first build is rank 1; every place ranks up without end (its cost growing, its effect growing slower), which
is where the open end lives.

| Rebuild | Costs (rank 1) | Does | Opens |
|---|---|---|---|
| The substation | Copper cable 20, Cable drums 10 | Night runs lose their slower feet (the lights are on) | The Grid: the first true pinnacle |
| The pumping station | Paving 20, Glass 10 | +HP regen at the Pitch, and the Clinic's prices down | — |
| The bus depot | Paving 15, Army kit 10 | Runs set off quicker; the auto-run's gap halves | — |
| The library | Glass 15, Ledgers 15 | Papers drop more; Kev's lines come back as readable pages | The Archive: the second true pinnacle |
| The market hall | Glass 20, Copper cable 20 | The Fence's shelf grows and his prices fall | — |
| The mint | Ledgers 30, Army kit 20, Fuses 5, the Grid's key | The town's worth starts paying: tins a run by worth | The Mint: the third true pinnacle |

Six to start; more places are content we add later without touching the system (a new row and its art). A place's
later ranks add Fuses and a pinnacle's drop to the cost, so the pinnacles stay worth beating.

**The town's worth** is the sum of every rank built. It shows on the Pitch's town card and on the title screen. It
never goes down, a move keeps it, and from the mint on it pays a little on every run. It is the number a player
(31 Oct, Matt: the mint pays on clears only.)
compares, the "Pitch no. 4, worth 61" line.

## 5. The true pinnacles

New people in new places, opened by a rebuild, not by depth. Each is a site of its own on the Map's new fifth tab
(beside the City), with its own art, a fight harder than any signal at the player's reach, and one unique each plus a
key item the next rebuild or rank needs.

| Pinnacle | Opened by | Who | Drops |
|---|---|---|---|
| The Grid | The substation | The Lineman: kept the lights on for the order's people only | The Grid's key (the mint wants it), his unique |
| The Archive | The library | The Registrar: decides who was born, who owns, who's owed | Ledger seals (later ranks), her unique |
| The Mint | The mint | The Issuer: prints the money nobody believes in. "Its value is as stated." | The first true FIAT note: a keepsake for the drawer, the town's worth doubles in pay |
(31 Oct: the doubling with the FIAT note went with the Issue on 25 Oct; the note now reads "Beat the Issuer again and he prints more.")

They scale with the town's worth, so they're never farmed out: each kill makes the next one a little harder and pay
a little more. The Issuer is the closest the game comes to an ending, without being one: beating him is a line in the
chronicle and a keepsake, and the mint keeps ranking.

## 6. Where it lives on screen

- **The Radio gets a third view, "The town"**, beside the decoder and the Dial: Kev knows who used to run what, and
  the Radio is already the endgame's room. The view: the six places as cards (built, rank, what the next rank costs,
  what it does), the materials in hand down the side, a Build button.
- **The materials tab**: in the Radio's view itself (the counts down the side), and a "Materials" line on the Pitch's
  purse. Matt asked for their own stash tab: the stash's filters could carry a seventh, "Materials", that shows counts
  rather than cells. Section 8 asks which.
- **The Map's fifth tab, "The order"**: the true pinnacles, shut until their rebuild.

A mockup of the Radio's town view and the fifth Map tab goes on the canvas before any code.

## 7. What it does to everything else

- **The balance pass** gets a new gate: the first rebuild within N hours of the depot (placeholder 2 h), the mint
  within N more. The bot gets a rebuild rule (build the cheapest it can afford) so the reads see it.
- **Moving the Pitch**: rebuilds and materials kept, the move's bonus adds a material drop share. So a move is no
  longer only a reset with better numbers: it's how to farm the town faster.
- **Kev's story**: the depot beat ends the story, and Kev's last line points at the town ("Someone has to put it back
  together. Might as well be the people who know where everything went."). The rebuild opens on that line.
- **Saves**: new, so an old save starts with nothing built (the no-old-save rule).

## 8. Decided (18 Oct, Matt: "go with your picks and build it up - no balance yet")

1. The screen: a third Radio view, "The town".
2. The materials: counts in the town view and two lines on the Pitch's purse (Materials, The town's worth); no stash filter.
3. Six places, as above.
4. ~~A death never costs materials.~~ Changed 1 Nov (materials in the pack): a death costs the pack's materials, bar
   what the dog's fetch or the Insurance desk brings home.
5. The pinnacles on the Map's fifth tab, "The order".
6. No new art in the first slice: the City, Town and Bank plates stand in until it reads (test art first).

## 9. As built (18 Oct)

- The order's pinnacles run as signals laid on a host site (the Grid on the Services, the Archive on the Bank, the
  Mint on the Barracks): its crew and drops, their own head and name. No notes or papers to go. A win never moves the
  reach. Their level: reach + their step (2, 4, 6) + a level every 4 worth + a level every win.
- Their three uniques (`Data.UNIQUES`, "order"): the Lineman's Lamp (night: full pace, finds x2), the Registrar's
  Satchel (papers x2), the Issuer's Robes (tins +1% a point of worth). Always the first win, a quarter after.
- The places' effects in `Data.REBUILDS` "fx"; what each does in the game: the substation lifts night's slower feet
  (as the Floodlights do), the pumping station rests and cuts the Clinic's prices, the bus depot rests the auto-run
  quicker between runs, the library raises papers, the market hall grows the Fence's shelf and cuts his prices, the
  mint pays tins on every run home by the worth (twice that with the FIAT note).
  (31 Oct: on clears only, and no doubling.)
- Materials roll on their own dice (`material_rng`), so the balance reads' other draws are untouched.
- The bot builds the cheapest place it can; it doesn't run the order yet (its reads won't reach the mint until it does).
- Not built: Kev's lines as readable pages (the library's second half in section 4); a move's material share is the
  flat MATERIAL_MOVE a move, not the move's bonus pick.
