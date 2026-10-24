# The Fence's contracts (9 Oct 2026)

From Matt's playtest: "Contracts at the fence can be abused by continually turning them down until you find
something like 20k cash for a rare primary ... Just add a cost for turning them down ... Also the variety needs
expanding, seeing the same 4 unique show up gets old ... remove unique from the pool and keep it to currency only,
cash notes, scrap and depth materials that feed into the changes we've made today."

Agreed with Matt (9 Oct): **one free turn-down a run, then notes, doubling**; **cash, notes, scrap and salvage
only**; **pay sized by income**; **a few new kinds of ask**.

## Today

- Three open (five with the Fence's Orders); each asks 1-3 of a slot at magic or rare.
- Pays: 20% a loose unique (three rares), 34% materials (scrap, a socketable, a graded box), the rest notes or
  cash. Cash is the slot's middle base value × rarity × 2.5 × count: a primary or armour quotes far more than a
  helmet - £13,300 for two rare primaries on a new save.
- Turning one down is free and rolls another at once: fish until the outlier comes.

## 1. Turning one down

- The first turn-down after each run home is free; each more before the next run costs notes, doubling:
  5, 10, 20, 40 ... (`CONTRACT_PASS_NOTES`), back to free when a run comes home.
- The button says its price: "Turn it down · free", "Turn it down · 10 n".

## 2. What they pay: notes, materials, salvage

(24 Oct, Matt: "remove tins from contracts entirely, in the early game they don't offer enough and in the end game
they offer too much - instead contracts are notes and materials only." The bot's 24-hour read had contracts paying
about 26 times the runs. Salvage kept; scrap dropped, as the runs already pay plenty of it. `Data.CONTRACT_PAYS`.)

| Pay | Weight | Amount |
|---|---|---|
| Notes | 45% | 4 × the ask's weight × (1 + the deepest depth / 5) |
| Material | 35% | a rebuild material of a cleared site (`contract_materials()`), the ask's weight × `CONTRACT_MATERIAL` (1) rounded up, 1 to `CONTRACT_MATERIAL_MAX` (6); a rebuild place wants 10-30. None cleared yet (the Outskirts alone): notes |
| Salvage | 20% | the ask's weight, rounded up, of a zone's kind - only zones whose sites have been dug to depth 4 |

An older save's contract paying cash or scrap is rolled again on load.

The ask's weight: the count × 1 at magic, × 2 at rare (and the new asks' own weights, below). Every slot at a
rarity pays alike, the pay keeps pace with depth, and there is no outlier to fish for. Uniques, socketables and
graded rounds leave the pool (the mate still sells a unique for notes; the Bench still makes the rest). The
Fence's Fixer doubles notes as now.

## 3. What they ask

| Kind | Ask | Weight |
|---|---|---|
| Gear | 1-3 of a slot at magic or rare (as now) | count × rarity |
| Deep gear | 1-2 pieces of any slot at an item level from the deepest site's level less three (asked for once that's level 6 or more) | count × 3 |
| An affix | one piece of a slot carrying a named affix the slot can roll | 3 |
| Papers | 2-4 papers, any (not the deeds) | count |
| Meds | 2-5 meds, any | count / 2 |

Gear 50%, the four new kinds 12.5% each. Contracts take the cheapest that fit, never a unique or set piece, as
now.

## 4. The screen

The contracts tab (Deals-A on the canvas): a row a contract - the kind as a tag, the ask and the Fence's line
with what you have, the pay as a chip in its currency's colour, Turn it down with its price, Hand in; a strip on
top with how many are ready and the turn-down's price this run; the mate under them.

## 5. Saves and balance

- An older save's contracts paying a unique, a socketable or rounds are rolled again on load.
- Balance gates: (the cash gate and the feel gate "Contracts against runs" went with the tins, 24 Oct); turning down
  five in a run costs no more than a run's notes at the deepest site.
