# Three resets, a weapon stripped at once, and the exchange in the contracts' place

Agreed with Matt on 28 Oct, mid-playtest: "no way to reset pitch or elemental skill trees; no way to strip
everything off a weapon at once; we need currency conversion - contracts should be replaced by currency
conversion - notes, tins, scrap with varying rates for each". Parked until after his playtest; numbers are drafts.
The Training panel's resets and the exchange go on the canvas before they're built.

## Three resets (Matt's call)

- Training gets a reset for each region: the class's trees (as now), the Pitch, the elements.
- Each costs tins by the points it frees (RESPEC_CASH a point, at today's prices), asks twice, and leaves the others
  as they are: a build can change its element without losing the Pitch.
- The Pitch's and the elements' points are the camp's, so their reset frees them for every class.
- The ring (paragon) keeps its own reset as it is.

## A weapon stripped at once (Matt's call)

- "Take every part off" on a gun's pick at the Workshop and the Kit: every attachment and socketable back into the
  stash, as room allows (what doesn't fit stays on, and the line says so). Free, as taking one off is.
- The affixes' Strip job is untouched; it stays its own job.

## The exchange (Matt's call: it replaces the contracts)

- The Fence's contracts go (their tab, the board, the Fence B contract marks, the contract pay).
- In their place, the exchange: the Fence posts a rate for each pair each day (play-day), drifting a little day to
  day. A spread both ways (draft 15%): converting is a choice, never free money.
- Trades: notes, tins and scrap; salvage (copper, safe steel, army surplus) and the County's materials too (Matt's
  call), each at its own rate, so a short material is never a wall.
- After the Issue, tins read as fiat; the rates follow the Issuer's money (circulation) as prices do.
- What it touches: the Fence's screen (the contracts' tab becomes the exchange), the smoke's contract checks, the
  balance's notes and materials income (contracts were 45% notes, 35% materials, 20% salvage of their pay), the bot.

## Order, when it's built

1. The weapon stripped (small). 2. The three resets (small). 3. The exchange (medium; it changes the economy, so it
goes in before the balance pass).

## Built (28 Oct, Matt: "build it all")

- Strip all parts: `sim.strip_all(slot)`; the Kit room's "Strip all parts" (two or more parts on), the Workshop's
  "Strip all N".
- The resets: Training's one reset button follows the node picked - the ring, the Pitch (its nodes; the elements'
  starters on its circle stay), an element (its nodes but the starter), else the class's trees. Each RESPEC_CASH a
  point, asked twice.
- Two elements a class (Matt, 28 Oct; Knuckles counts): `sim.elements_open`; a class opens two, another class's
  (31 Oct, Matt: the Quartermaster's Manual, the Last Orders and the Headmaster's Cap lift the cap while worn; taken off, those past two idle. A class's own two open free, 31 Oct.)
  element opens for nothing, closing one is free and leaves its nodes the camp's; only the open two work and fill.
- The exchange: the Fence's third tab. New rates every run home (there's no short play-day), ±12% drift that only
  ever goes against the trader (the review: a free drift beat the spread - a money pump), 15% spread; the Fence's
  Prices line has Contacts (10% spread) and the Fixer (+5%) where Orders and the old Fixer were. The contracts are
  gone, the mate kept on the tab. Drafts all, for the balance pass.
