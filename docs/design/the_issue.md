# The Issue - Fiat's second act (draft, 25 Oct)

Status: design, agreed in outline with Matt on 25 Oct; nothing built. Mockups to follow on the canvas.

## Why

The Issuer prints the money nobody believes in ("its value is as stated"), and the game is named after him - but
beating him today gives a keepsake that doubles the Mint's tins. Matt (25 Oct): it should be significant. From the
Issue on, the money changes, with new rules, a new vendor, and over-powered kit the next stage needs.

It also ends the cash flood by design: gate 14 (cash held) has been red for three passes, and no price has held it.

## The decisions so far (Matt, 25 Oct)

| Question | Decision |
|---|---|
| The switch | One way. There's no going back to tins. |
| Hoarders | Hard on them: a big pile converts to little fiat. |
| The Issuer's counter | Beside the Fence, not instead of him. |
| Issued kit | A tier above mythic, over-powered, sold only by the Issuer, needed for the next stage. |
| The next stage | A second campaign, then the Radio remixes both campaigns into its maps. |
| Where | A new region past the City: four zones of three sites, new art. |
| Who | The same runner: level, paragon and kit carry on. |
| Its heads | The Issuer's people (working names: the Bailiff, the Auditor, the Collector, the Treasurer). |
| The remix | Everything mixes: any site's plate with any campaign's gang, heads away from home, one ladder. |

## 1. The Issue (the switch)

- When: the first time the Issuer falls at the Mint. The true FIAT note he drops becomes the badge of the new money
  (the keepsake line stays in the chronicle).
- What happens, once and for good: every tin and note held is converted to fiat at the Issuer's rate, hard on piles.
  Working curve: `fiat = FIAT_RATE × sqrt(tins + notes × NOTE_TINS)`, so 1,000,000 tins is about 1,000 × FIAT_RATE,
  and 100,000,000 only ten times that. Figures for the balance pass, the shape for now.
- Tins and notes stop existing. Every price, pay, contract, insurance premium and Workshop job reads in fiat.
  Scrap stays as it is: it's goods, not money.
- Its moment: the screen it happens on is a set piece (the mockups): your pile, the Issuer's rate, what came out.

## 2. Fiat's rules: its value is as stated

- Prices by circulation, not the clock. Before the Issue, prices inflate with play time (`inflation()`). After it,
  they inflate with the fiat in circulation: everything you've been paid in fiat since the Issue, less what's been
  burnt. Earn more, and everything costs more.
- The rate board. The Issuer posts a rate that drifts. The Fence buys loot at it, so when you sell matters.
- Printing. Every win over the Issuer after the first: a big fiat haul, and the circulation (so the prices) jumps.
  Beating him again is a choice, not a farm.
- Burning. The Issuer takes fiat back and burns it: the circulation falls, and every price with it. That's a sink
  with a reason.

## 3. The Issuer's counter

- Opens at the Issue, a counter beside the Fence in the same room (his own portrait and words; the Fence keeps his).
- Sells issued kit, and takes the burn.
- Issued kit: a new rarity above mythic - stamped, serial-numbered, one base a slot to start. Deliberately strong:
  each piece carries a rule of its own (as a unique's) and its own grow. Sold only for fiat, at the rate.
- The gate: the second campaign's first site wants issued kit to stand in (its fight is set past the reach, the way
  the Mint's is). The first pieces are the goal of the Issue's first fiat; later ones are the second campaign's.

## 4. The second campaign

- A new region past the City, four zones of three sites, in the first campaign's shape: each zone's head opens the
  next, a site's depth, its gangs and drops. Region and site names to work out (the motorway out to the county town,
  the docks, the big houses, the Treasury - suggestions only).
- The heads: the Issuer's people, the ones who make the new money stick - the Bailiff, the Auditor, the Collector, the
  Treasurer. Each drops a piece of issued kit's next tier, or what makes it, and the Treasurer's fall opens the remix.
- The same runner: no reset. The region's sites start past the reach, so issued kit is the way in. The paragon carries
  on.
- Its drops pay in fiat; scrap and materials as now; issued kit's makings from the heads and the deepest sites.

## 5. The Radio's remix

- After the Treasurer: the Radio's signals draw from both campaigns. Any site's plate with any campaign's gang, a head
  turning up away from home, both campaigns' drops and crews in one ladder, issued kit on the deepest signals.
- The order's pinnacles stay, and grow with the remix's reach.

## 6. What changes in what's there

| System | Before the Issue | After |
|---|---|---|
| Cash, notes | tins, notes | fiat only |
| Prices | the clock's inflation | the circulation's |
| The Fence | buys in tins | buys in fiat, at the rate |
| Workshop, Clinic, contracts, insurance | tins, notes | fiat |
| The Mint (rebuild) | tins a run | fiat a run (its doubling goes: the Issue is the note's job now) |
| Paragon tins row | +3% tins | +3% fiat |
| The Map | five tabs | the region's zones as new tabs |

## 7. Art and sound (estimates, not agreed)

- The region: 12 sites x (a plate, a wall, a map card) = 36; four heads x (portrait, three fight poses) = 16; four
  zones' gangs x two figures x three poses = 24; the region's map land; the Issuer's counter (portrait, room art);
  issued kit's pictures (one a slot to start, about 8). Roughly 100-130 PixelLab jobs, about $10-15.
- Sound: the Issue's sting, the counter's sounds, four zones' ambience, the heads' doors. About 12 ElevenLabs jobs.
- Test art first (Matt's rule): the slice reads with placeholder art before any manifest is agreed.

## 8. Build order

1. The Issue and fiat (the switch, the conversion, circulation prices, the rate, the burn), on the existing game.
2. The Issuer's counter and issued kit (first tier).
3. The second campaign: one zone first with test art, then the rest.
4. The Radio's remix.
5. Then balance - the endgame's cash and scrap tuning pauses until 1-2 are in (Matt's rule: features before balance).

## 9. Still open

- The region's name and its twelve sites; the heads' names and their fights (each a different check, as the order's).
- How many issued pieces, their rules, and whether they can be patterned or tempered.
- The rate's drift: random, or moved by what you sell?
- What the runner sees of fiat before the Issue - a hint on the Radio, the Issuer's words at the Mint.
- Whether retirement (level 50) changes once the second campaign exists.
