# The search as crates (13 Oct, Matt; built 13 Oct)

The search was a bar to wait out. Now a cleared site shows its **crates**, opened one at a time in the order they come
(rng - the player doesn't pick), each one search or more, its finds revealed one by one under a magnifier, Tarkov-style.

## Rules [Matt]
- No choice of crate: the order is the dice's. The decision is the one the run already has - stay or go - and the
  crates make it a real one: a military crate three crates down the row, four searches deep, with a gang due.
- What's inside is unseen until opened; the Kennel's top rank lets the dog sniff it (the contents' rarity shown on the
  crates still shut).
- Fight drops come down so a run's total evens out against today's (the balance pass, after it's built).

## Mockups (13 Oct)
A: the fight box turns into THE SEARCH while the site's searched (a gang in, it's the fight again): the row of
crates small, the open one under the magnifier, the bar under them. B: the right column, the room the pack leaves
early on: the crates big, and IN THE <CRATE> - its finds as ? cells revealed one by one under the magnifier - and a
line on what's next ("a military crate, four searches; the next gang's due in 0:40").

## The crates (a first list, to settle)
| Crate | Searches | Leans to |
| --- | --- | --- |
| Cardboard box | 1 | commons, anything |
| Ammo tin | 1 | rounds |
| Toolbox | 2 | parts, scrap |
| Medicine cabinet | 2 | meds |
| Filing cabinet | 2 | papers, notes |
| Safe | 3 | tins, notes, the odd unique |
| Military crate | 4 | guns and armour, a rarity up |

- A site has a set number of crates, its total searches about today's before the thinning (6 + 2 a depth): the
  crates replace the picked-over thinning - all open is picked over, and that's the run's natural end.
- A site's shape picks its crates (the Hospital's medicine cabinets, the Barracks' military crates, the Bank's safes);
  the depth adds crates and better ones; a code can add a kind (Delivery day: military crates).
- What already touches the search: search speed opens a crate faster; quantity adds finds to a crate; the dogs, the
  Scavenger and the Postman's Bag add a find a crate; the Caretaker's Keys "every cache opens" (locked crates?).
- Auto-run and away: unchanged - the crates open in their order, the leave rules as now.

## Settled (13 Oct, Matt)
Mockup B. The list as above plus a Jewellery box (1 search, charms), the Filing cabinet carrying the papers and their
codes. The Kennel's top rank is the fifth column (the pack or Champion), either pick.

## As built (13 Oct)
- Data.CRATES (searches, lean, notes/scrap odds, a safe's tins, unique odds, quality, weight, first zone, weight a
  depth) and Data.CRATE_SITES (a site's own). sim: `_roll_crates` at the clear (or the first search, a Ghost's),
  `crate_now`, `crates_done`, `dog_sniffs`, `crate_weights`; `_find` takes the crate and can roll without landing
  (the nose); `_land` logs and places. The thinning (THIN_STEP, THIN_FLOOR, `thinning`) is gone.
- Picked clean ends the site's finds; the auto-run and "Fill up, then go" leave, a Ghost counts it the clear, Hold fire
  lets the gang come.
- The panel (scripts/ui/crates_panel.gd) takes the pick panel's place on the run screen while nothing's picked; the
  pack keeps its seven rows. Up to seven crates show, the window sliding with the one in hand.
- Not yet: the codes adding crates (Delivery day's military crates), the Caretaker's Keys and locked crates, the art
  (tools/pixellab_crates_manifest.json), fight drops brought down (the balance pass).
