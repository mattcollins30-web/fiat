# Over the cap: resist into damage (12 Oct, built the same day; numbers in the pass)

Matt, 12 Oct: a fire build should be able to stack fire resist past the cap, and what's over the cap should add to its
fire damage. **Design only. It's built before the next balance pass**, with the shields (docs/design/shields.md),
because both touch the trees and the affixes and so change the numbers the pass reads.

## 1. What there is now

- `sim.resist(ty)`: the affixes (`<el>_res`, `all_res`), the trees' (`tree_sum`; no node gives a resist today), the
  bases' own (the resist gear: the turnout gear's fire 50, the CBRN suit's poison 55, the EOD suit's fire and shock
  30), the sets' bonuses. Capped at `RESIST_CAP` 75. Physical has none: armour is its resist.
- Whatever's over 75 is thrown away now. A fire runner in turnout gear (50) with a 30 fire-resist helmet and a 30
  charm sits at 110 and gets 75.
- Nothing lowers the runner's resists: no Radio word, no zone. So the overflow has no defensive use either.

## 2. The rule

- **Over the cap**: an element's resist past 75, read before the cap, up to `OVER_CAP` 50 of it.
- **Every 1% over is +1% increased damage of that element.** It sits in `increased(ty)` beside the affixes and the
  trees, so it's the same kind of figure as a `fire_pct` affix and adds to them, not multiplies.
- **It's everyone's, not a node's.** It only pays a runner who stacks one element's resist, which costs the affix
  slots (Armour, Helmet, Charm) that would otherwise hold HP, armour or an element's damage. A plain build has no
  element to feed.
- The trees make it a build. A notable in each element tree's empty column-5 cell (section 3) doubles the rate
  for that element and gives some resist itself.
- **Physical** has no resist, so it can't go over a cap. Knuckles' version reads armour instead (section 3); it's
  Matt's call whether it goes in.
- `all_res` counts towards every element. One affix can't push all five past the cap, but the Blue Plaque could if
  its rule didn't already stop everything else counting (it gives 40 and nothing else adds, so it never goes over).

First figures, for the pass: 1:1, capped at 50 over, so +50% at most, or +100% with the notable. For scale, an
element's own notable gives +30% and its costly one ×1.4.

## 3. Where it comes from

### The trees: column 5, row 1, empty in all six element trees

| Tree | Node | Words |
| --- | --- | --- |
| Petrol (fire) | Fireproof | +20% fire resist; every 1% over the cap is +2% fire, not +1% |
| The cold (frost) | Thermals | +20% frost resist; every 1% over the cap is +2% frost |
| The rat man (poison) | Immune | +20% poison resist; every 1% over the cap is +2% poison |
| Live (shock) | Rubber soles | +20% shock resist; every 1% over the cap is +2% shock |
| Blades (bleed) | Scar tissue | +20% bleed resist; every 1% over the cap is +2% bleed |
| Knuckles (physical) | Thick-skinned | Every 10 armour past 200 is +1% physical (to +50%) - *Matt's call* |

These are notables in column 5 (cost 4), so a dip off the class's two affinities can't reach them: an off-pair tree
stops at column 4.

### The affixes

- **The resists roll on the rig too.** `<el>_res` and `all_res` stay on Armour, Helmet and Charm, and add the Rig.
  That gives a runner four slots to stack.
- **A new hybrid affix family, "-proofed"**: +X% of an element's resist and +X% of its damage on one line (5-20 each),
  on Armour and Helmet at weight 0.4. It's the line a stacker hopes for, and it does a little for anyone of that
  element.
- The resist bases already climb to tier 9 (the turnout gear 50, the CBRN suit 55, the EOD suit 30 and 30). Nothing
  new is needed there.

### The uniques

No new ones. Three existing uniques start to matter here:

- the Gritter's Hopper (frost resist 30);
- the Gamekeeper's Flask and the Rat Man's Overalls (poison resist 30 and 35). A poison stacker in Overalls and a
  CBRN suit is over the cap before an affix.

The Vicar's Thermos (your fire resist is nothing) is the opposite build, and stays so.

### Optional: a defensive use (Matt's call)

A Radio word that lowers your resists:

- **"Soaked"**, from a paper found deep: your resists −30% for the run; the pay is drop ×1.4.
- With it, the overflow is real armour: a runner at 105 still sits at 75 under it.
- Without it, over the cap is only damage.

## 4. In the sim

- `_resist_raw(ty)` splits in two: `resist_raw(ty)` (no cap) and `resist(ty)` (capped, as now).
- `over_cap(ty) = clamp(resist_raw(ty) − RESIST_CAP − word_cut, 0, OVER_CAP)`. Here `word_cut` is Soaked's, if it
  goes in.
- `_increased_raw(ty)` adds `over_cap(ty) × (2 if the element's notable else 1)`.
- Both are memoised as now (the kit key covers what's worn and the tree), so the fight's hot path doesn't change.
- A save needs nothing: the tree's new nodes are new ids, and the affix is new.

## 5. On screen

- **The Stats sheet's resists:** a row over the cap reads `Fire 75% · 110 · +35% fire` in the element's colour, and
  the "+35% fire" is a chip like the trees'.
- **The pick panel's deltas:** a piece that moves a resist past the cap shows the damage too
  (`fire res +30 · +30% fire`).
- **The trees' sum strip:** the element's chip counts what's over the cap in its increase, with a "cap" tag.
- **The Runs card's chips** ("Fire 15% · you resist 75%") add "· +35% fire" when over.
- Mockups on the design canvas before the build, as for any UI change.

## 6. The checks (smoke)

- A runner at 110 fire resist reads 75% resist, 35 over, and `increased("fire")` is up 35. With Fireproof it's up 70
  and its own +20 is counted.
- 200 resist is held at 50 over.
- `all_res` counts towards every element.
- Physical never goes over.
- The Blue Plaque never goes over.
- The Vicar's Thermos's fire is 0 and 0 over.
- The new affix rolls on Armour and Helmet only; the resists roll on the rig.
- The Stats sheet's over-the-cap row fits.

## 7. The pass

The element builds' gates read it as they read everything. Expect the stacker's damage to rise in the endgame, where
the resist bases are. The pass decides the rate (1:1), the cap (50) and the notable's ×2.

## 8. For Matt

1. Should over the cap be everyone's at 1:1 (my lean), or only with the element's notable?
2. Are the first figures OK: +1% per 1% over, up to 50 over, doubled by the notable?
3. Knuckles' armour version ("Thick-skinned"): in, or physical stays out of it?
4. Soaked (a word that lowers your resists, so the overflow also defends): in, or not now?

Matt, 12 Oct: agreed across the board - everyone's at 1:1, the first figures, Thick-skinned in, the word in. Built as
"Water cannon" (the city's, from depth 10: a resist point off a tier-I point, more at the higher tiers). The Blue Plaque
never goes over. What was built: docs/status.md, 12 Oct.
