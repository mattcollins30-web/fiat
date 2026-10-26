# Fiat - game review 3 (the Issue, the County, the remix; yesterday's two checked), 26 Oct

Scope: scripts/sim/sim.gd, data.gd, items.gd; tests/bot.gd, tests/balance.gd and tools/balance_summary.gd where they
explain a read. Snapshot 05b6589, diff since d17b479. Read only; nothing edited. Line numbers are the snapshot's.
Effort: S = under an hour, M = a session, L = several. Confidence: "confirmed" = traced through the code path;
"likely" = the code reads this way, worth a check.

Post-Issue price scale used below: `inflation()` = fiat_issue_inf x FIAT_SCALE (0.0005) x circ_mult (1-4)
(sim.gd:1096-1098). With the Issue at 5.4-31.6 h (seventh pass), fiat_issue_inf = 1 + 0.07 x (h - 1) = 1.3-3.1, so a
post-Issue price is the opening day's tins x 0.00065-0.0016 at circ 1, and x 0.0026-0.0063 at the cap.

## Top five

1. **A1.** Issued kit off a County head (and off a remix head) is lost on a death after the kill, and left at the gate
   when the stash is full. That breaks "never lost".
2. **A2/A3.** After the Issue the price scale breaks at both ends. The Clinic's shelf costs hundreds of times its own
   med price (it was never inflated), and every price under a few hundred opening-day tins rounds to ƒ0, so ammo and
   bandages are free.
3. **B1.** Circulation only goes up and its span is fixed. Prices pin at x4 within a handful of Mint prints and stay
   there, and the burn then moves nothing.
4. **B2.** Fixed levels give fixed-level rewards. The Mint at 45 + wins is a print farm for anyone at reach 70 ("a
   choice, not a farm"). The Grid's and the Mint's uniques drop at item level 35-50, and a County head's issued piece
   is weaker than the counter's.
5. **A4.** The issued webbing's "Meds heal half again" does nothing, because a worn heal_pct affix is never read.

---

## 1. Yesterday's items

### game.md (first review)

| Item | Now | Where |
|---|---|---|
| A1 odds read keeps the camp's nodes | Holds | sim.gd:6617-6631 (`is_camp` both ways) |
| A2 skills are the runner's | Holds; the death half (game2 R6) done | sim.gd:1250 RUNNER_KEYS; 9689 `_skills_known_only()` |
| A3 Revolver one shot | Holds | sim.gd:8135-8142 |
| A4 Floored / Flattened one man | Holds | sim.gd:8315-8324 |
| A5 Clean kills | Holds | sim.gd:7946-7947 |
| A6 printed men count as kills | Holds, and now covers the Collector's and Treasurer's men | sim.gd:7769-7776 |
| A7 skills cut by resist | Holds (game2's note on the physical skill stands) | - |
| A8 Arsonist's Rig grows | Holds | sim.gd:8422 |
| A9 loot quantity counted twice | **Never done** for every source but greed: `thin_after` x (1 + loot_bonus) and +loot_bonus a search | sim.gd:8983, 9127 |
| A10 frame-rate | Held swing and multi-cast hold; DRY_STEP 2.0 still makes the odds' swing about 1.4x the live one (minor) | sim.gd:7088 |
| A11 Registrar's red tape | **Never done** (5 s in 12, -30%); the Auditor now inherits it | data.gd:3409-3411; sim.gd:7636 |
| A12 smalls | Done, except **Workbench**: still one free job per 24 h of play | sim.gd:2283 |
| B1 tempering, compounding paragon | Done | - |
| B2 value by item level, scrap sink | Done (insurance on raw value by choice, game2 R11) | - |
| B3 Weed Burner | Data done (takes shells, +40% fire off); spread kept | items.gd:844; data.gd:822 |
| B4 OVER_LEVEL_FREE | Done (game2 R5) | sim.gd:4502-4513 |
| B5 greed | Done | - |
| B6 Faint signals | **Never done** (-7 to -2, one paper, no extras) | data.gd:3228 |
| B7 a loss at the reach gives nothing | **Never done** | sim.gd:6696-6706 |
| B8 Not today under 25% vs BAIL 0.25 | **Never done**: still blind in the odds | data.gd:1172; sim.gd:7090 |
| B9 paragon rows | Tins back to adding; find unchanged | sim.gd:310-316 |
| C ideas 1, 5 | Done (tempering, greed); 2, 3, 4, 6, 7 not taken up | - |
| D1 per-tick cache | **Never done** | - |
| D2 literals outside FX | **Never done** (Bleed out's 1.5 still at 748 and 8034, beside FX at 8012) | sim.gd |
| D3 notables by tree index | **Never done** | sim.gd:684, 710, 716 |
| D4 `_fight` / `load_dict` | **Never done**, and grown (`_fight` 344 lines, `load_dict` 314) | sim.gd:7918, 11938 |
| D5 runner fields in one table | **Never done** | sim.gd:1250 |

### game2.md (re-review)

| Item | Now | Where |
|---|---|---|
| R1 bag slots tempered | Done (`Items.grows`; bot temper slots and weights) | items.gd:470; sim.gd:2342; bot.gd TEMPER_SLOTS |
| R2 flat lines on a temper | Done (`temper_lines`, from v0) | items.gd:477-489; sim.gd:2644 |
| R3 temper tins | Done (worth x TEMPER_CASH 4) | sim.gd:2354-2357 |
| R4 paragon tins compounding | Done (adds again) | data.gd PARAGON_COMPOUND |
| R5 over-level in wear terms | Done | sim.gd:4502-4513 |
| R6 death clears skills | Done | sim.gd:9689 |
| R7 gate 15 yardstick | Done (hours of scrap income). The stale `dearest_build` (120) is still recorded and printed | balance.gd:483; balance_summary.gd:409 |
| R8 tempers in the summary | Partly: the count is shown; "too_high" passes and kit levels against the runner's are not | balance_summary.gd:419 |
| R9 bot's Weed Burner penalty | Data change done; the bot's -0.45 / 0.8 floor unchanged | bot.gd:1060-1061, 1088 |
| R10 pack drops by raw value | **Never done** | sim.gd:8881, 9161 |
| R11 insurance on raw value | Unchanged (design note) | - |
| M2 a death past 50 goes to level 1 | **Open, Matt's call**. It now also strips the County's issued kit until level 50 again | sim.gd:9648 (`xp = 0.0`) |
| M3 bot never meets a third gang | **Open** for the gate reads (still leaves at 2); `stay_out` covers only the broken and hunt reads. Gate 11 unjudged | bot.gd:434; balance_summary.gd:23 |
| M4 greed counted three times | Done to twice (out of `thin_after`); A9's double still applies to everything else | sim.gd:8983 |
| P5 temper price package, gate 14 TEMPER_CASH, XP taper 3.1, gate 4 band, parity twice | Done | data.gd |
| P6 per-gang swing | Not done (Matt's call; P6 re-classed bot play) | - |

Regressions: none found. Every fix listed as holding in game2 still holds.

---

## A. Bugs

### A1. A County head's issued piece is lost on a death after him, or when the stash is full (confirmed)
- Where: sim.gd:6094 (`_county_down`: the piece goes into `m["found"]`), 9416 (`_extract`: only a mythic comes home
  past a full stash, otherwise `continue`), 9627-9629 (`_kia`: only mythics in the pack come home), 9556 (the floor's
  mythics). The remix's heads take the same path (6081, via `_order_down`).
- What: issued kit worn is kept on a death (9615), but issued kit carried isn't. A head's drop is in the pack until
  the gate. If the runner dies on the way out, or meets a gang after the head, the piece is gone. With a full stash it
  goes too, and the log only counts it in "left". data.gd:3299 says "never lost (as a mythic)".
- Why it matters: the head's piece is the County's reward, and the next zone wants more pieces worn. Losing one to a
  death after the fight, or to a full stash, reads as a bug.
- Change: treat `issued` as `mythic` in `_extract`'s room check, `_kia`'s pack filter and `_floor_mythics_in`. Add a
  smoke check: a head's piece comes home after a death and with a full stash.
- Effort: S.

### A2. The Clinic's shelf has no inflation: after the Issue it costs hundreds of times its own med price (confirmed)
- Where: sim.gd:10822-10823 `clinic_price = value x MED_PRICE x discount`, against `med_price` (10858-10859), which is
  `_inf(...)`. Both are on sale in the vendor (vendor.gd:306, inventory.gd:579).
- What: before the Issue the shelf was 1/inflation of the list price (up to 1/12). After it, the shelf is in raw
  opening-day tins read as fiat. A Hospital kit costs ƒ570 on the shelf against ƒ1-4 from the list.
- Change: `_inf(...)` in `clinic_price`.
- Effort: S.

### A3. After the Issue, small prices round to ƒ0, so ammo, bandages and cheap Bench jobs are free (confirmed)
- Where: sim.gd:1228 `_inf(x) = int(round(x x inflation()))`. The comment above it says "never below the original when
  it was positive", and the code doesn't do that. Callers: `ammo_price` (3557), `med_price` (10858), Bench jobs
  (2321), the gamble floor (10399).
- What: at x 0.00065-0.0063, anything under about 80-770 opening-day tins rounds to 0. Nails (30) and Shells (45)
  are ƒ0 at any circulation, and so are a Bandage (22.5) and Painkillers (18). `cash < 0` is never true, so they're
  unlimited. The other end of A2.
- Change: `maxi(1, ...)` when x > 0, as the comment says. Or price fiat to a hundredth: cash is already a float.
- Effort: S.

### A4. The issued webbing's "Meds heal half again" does nothing (confirmed)
- Where: data.gd:3309-3310 (the webbing's `heal_pct` 50 as a worn affix); sim.gd:8351-8352 (`med_heal` reads
  `tree_sum("heal_pct")` only); items.gd:785 (`Items.heal` reads the med's own affixes).
- What: nothing sums a worn piece's `heal_pct`, so the line is dead. Its `med_cap` works (1025).
- Change: add `+ _affix_sum("heal_pct")` in `med_heal`, with a smoke check that the webbing raises a med's heal.
- Effort: S.

---

## B. Design holes and contradictions

### B1. Circulation only goes up; prices pin at x4 and the burn goes dead (confirmed code; magnitudes likely)
- Where: sim.gd:3843-3847 (every `_earn` adds to circulation), 5993-5997 (a print adds the haul twice), 1109-1111
  (`circ_mult`, cap 4), 1202-1220 (the burn); data.gd:3373-3382.
- What: SPAN is a fixed ƒ100,000 and nothing takes circulation down except a burn. Each later Mint win prints
  `_inf(20M)` and adds twice that: 20,000 x fiat_issue_inf x circ fiat, about +0.26 to +0.62 on the multiplier a win at
  circ 1. Five to twelve wins reach the cap before any run income counts. A burn takes out 2 x `_inf(2M)`, at most
  8,000 x fiat_issue_inf at the cap, against a circulation that keeps growing with income. Once circulation is past
  ƒ300,000 a burn changes nothing on screen. Pay is also x circ_mult (kill cash and the run's cash read `inflation()`),
  so the multiplier is only a tax on held fiat. The burn pays only while holding more than SPAN x circ / 2. Words.ISSUE
  "printed" ("every price up with it") is false at the cap, and the bot burns hourly into it (bot.gd `_issued`).
- Why it matters: two of §2's three rules (prices follow the money, burn it) stop being a choice soon after the Issue.
- Change (Matt's call): make circulation a stock that decays (for example, half of it gone each hour of play), or
  price by circulation against a running income figure (`takings` exists). Price a burn as a share of circulation,
  so it always moves the board. Either way, the bot burns only when it moves the multiplier.
- Effort: S-M. Check the eighth pass's gate-18 fiat column (`prices`) before choosing.

### B2. Fixed levels make fixed rewards: the Mint is a print farm, and the order's and heads' drops fall under the reach (confirmed)
- Where: sim.gd:5838-5841 (Grid 35 and Mint 45 + wins), 5993-5997 (the print isn't scaled by level), 5961 (the
  order's unique rolled at `t.level`), 6087 (a head's issued piece at place level + 5) against 1749 (the counter's at
  reach + 5).
- What: a reach-70 runner can win the Mint from 45 upwards about 25 times at near-certain odds, and each win prints
  20M opening-day tins in fiat, which is several issued pieces. the_issue.md §2 says "a choice, not a farm". §5 says
  the order's pinnacles "grow with the remix's reach", but they don't any more. The Lineman's Lamp and Tool Bag drop at
  item level 35+n and the Issuer's Revolver and Robes at 45+n, so they're dead in the endgame. To win a County place
  you need reach above its level, so a head's issued piece is always weaker than the counter's. §4 calls it "issued
  kit's next tier".
- Change (Matt's call): the set level gates the first win only. After that, use `max(set level, reach + over) +
  wins`, as the Archive still does. Roll the drops at `max(t.level, reach)`. A head's issued piece goes at
  `max(place level, reach) + ISSUED_OVER + 2`. Optionally shrink the print each win (PRINT_HAUL x 0.8^wins).
- Effort: S.

### B3. After the Issue, notes become about ninety percent of fiat income and bypass circulation (confirmed code; magnitude likely)
- Where: sim.gd:99-105 (the notes setter adds to cash directly, "not into circulation"), 8576 (`notes_a_kill` = ceil(1
  + (depth - 1) / 3)), 9372-9378 (`notes += run_notes`); data.gd:3372 NOTE_TINS 500; kill cash 40 x 1.05^(lv - 9)
  (data.gd:1457, depth_figures).
- What: at level 70 on a depth-60 signal, a kill pays about 21 notes, which is 10,500 opening-day tins, against about
  785 in kill cash. Before the Issue, notes were their own currency with their own sinks. After it, they buy everything
  tins bought: issued kit, tempers, the Yard. Effective cash income jumps about 10x on the day. That income skips
  `_earn`, so circulation, cash_in and takings see about a tenth of it. The issued rifle's x1.5 and the paragon tins
  row miss it too.
- Why it matters: "hard on hoarders" is undone within a few runs, and B1's circulation measures the wrong stream.
- Change: after the Issue, route notes pay through `_earn` (the setter's `v > old` branch), and have the balance pass
  set NOTE_TINS so that a run's notes come to about its tins. Or keep notes as notes after the Issue, priced in fiat
  only where they're spent.
- Effort: S, plus the number in the pass.

### B4. Kit held through the Issue still dodges the root once prices rise (confirmed)
- Where: sim.gd:1081-1082 (`sell_price` = worth x issue_k x inflation(), and inflation carries circ_mult), 1131-1162.
- What: held fiat stays nominal while an `issue_k` piece's sale grows with circ_mult. Example: 300M tins held as cash
  becomes ƒ13,856. The same 300M spent at the Fence first (x3 markup) leaves 100M of sale worth, so k = 0.00008 and
  issue_k = 0.16. That sells for ƒ8,000 at circ 1 and ƒ32,000 at the cap, and with the issued cap worn the rate never
  cuts it. Matt's call (26 Oct) was that kit bought to dodge the root doesn't. It does, by about 2.3x, as soon as
  prices hit the cap (B1).
- Change: price an `issue_k` piece at the Issue's prices, `inflation() / circ_mult()`. Its fiat value is then fixed,
  as the cash's is.
- Effort: S.

### B5. The Collector is close to a non-check (confirmed)
- Where: sim.gd:7760-7776 (a debtor absorbs your damage first and resets the bill when he drops), 7724 (one every
  COLLECTOR_MEN_EVERY 6 s), 7660-7661 (+5% every 3 s).
- What: a debtor is one host-crew man and dies within a second or two of arriving, so the bill swings between 0 and
  about +10% and averages about +5%. The player has no choice to make: the absorb kills the debtors for them. This is
  the Registrar's red-tape problem again (A11).
- Change: a debtor down takes the bill back one step, not to nothing. Or the debtors stand beside him and only spread
  or a kill reaches them, so the bill grows unless fire is spent on them.
- Effort: S.

### B6. The Treasury's six issued pieces leave no build (confirmed)
- Where: data.gd:3317 (ISSUED_WANT [2, 3, 4, 6]), 3300-3313 (six issued slots of seven); sim.gd:6056 (the Go's check).
- What: at the last zone every class wears the same rifle, pistol, cap, plate, webbing and seal. Only the Backpack is
  the player's, so the Weed Burner, Jump Leads, element guns and the classes' own weapons are all off. With issued kit
  counting as set pieces (4966-4983), a real Council, Bank or Army backpack completes its set. The Treasury is then
  fought in issued kit plus one of three backpack sets.
- Change (Matt's call): 6 → 4 or 5. Or let one unique worn count as "stamped" towards the want.
- Effort: S.

### B7. One real piece plus issued kit completes any set and any broken combo (confirmed; reads as intended)
- Where: sim.gd:4966-4983, 4985-5000; 5041 (`combo_on` reads `set_count`); data.gd SETS (2-4 pieces each).
- What: after the Issue, every set bonus is one real piece away, and so is every broken combo's set count. The harness
  relies on this (bot.gd `_hold_broken` keeps "one real piece of the set"). Flagged only so it's a known call: the
  set chase ends at the Issue.
- Change: none if intended. Otherwise, issued kit counts towards a set only up to (pieces - 2).
- Effort: S.

### B8. The bot wears all six issued pieces from the Issue on, so post-Issue reads are the issued kit's (confirmed)
- Where: bot.gd `_issued` (buys every slot) and `_wear_issued`, which runs in `_tidy_kit` after `_hold_the_element`
  and `_hold_the_type` and replaces any non-issued piece "whatever the score says".
- What: at the Issue, element builds lose their element gun, fire builds lose the Weed Burner and the Doorman fights
  with a rifle. Gate 18, the County firsts and any parity read that crosses the Issue measure the issued kit, not the
  build.
- Change: wear only `county_want(next zone)` pieces, picked by try-on, with the build's gun held when the want allows.
- Effort: S.

### B9. The Archive is still reach-relative, and the broken-build verdict needs it (likely)
- Where: data.gd:3392 (no `"level"`); sim.gd:5843-5844 (reach + 4 + worth/4 + wins); balance.gd:963 ("archive" in
  `content`); balance_summary.gd:120 (broken = everything beaten once).
- What: the sixth pass read the Grid at 0% "on every save" with the same formula at +2. The Archive at +4 should do no
  better, so the Registrar's two uniques are likely unreachable, and a build can be "broken" only by beating a target
  that climbs with its own reach.
- Change: a set level, as the Grid and Mint have (Matt's number, about 40), or drop it from the broken verdict.
- Effort: S.

---

## C. Smaller items

1. **Issued words with figures that scale.** data.gd:3300-3313. `_scaled` grows a percent line by 1 + 0.06 x (item
   level - 15) (items.gd:418-443), as drops do. At item level 75 the rifle reads +115% damage, the sidearm +92%, the cap
   all resists +69 (near RESIST_CAP 75 alone), the webbing +5 meds and the seal +92% quality. The words say +25%, +20%,
   +15, "one med more" and +20%. "Every fifth shot is printed twice" has no code; the damage affix is the whole effect.
   Drop the figures from "words" and "short". S.
2. **Issued plate words against code.** "the order and the Issuer's people" (data.gd:3308), but the code
   (sim.gd:1801-1806) cuts every County place's crews and remix signals laid on a County place. The doc and the short
   line say "the County". Also, `_sig` isn't site-checked at 1805, so another site's odds read during an order run
   carries the cut. S.
3. **Names.** "Issued webbing" sits beside "Issue Webbing" (the chase unique, data.gd:792) and the Army set's "Issue
   helmet/carrier/bergen/rifle". The language pass should split them. The temper's words "past Item level +3"
   (data.gd CRAFT) need the same pass. S.
4. **`tins_now` leaves out circ_mult** (sim.gd:1121). Bung's tins and the bot's floors read at the Issue's prices, a
   quarter of the rest at the cap. S.
5. **`issued_piece` rolls a fresh item, and a new item id, on every price or block check** (sim.gd:1743-1771). The
   counter asks per slot per refresh. Cache by (slot, level, serial). S.
6. **Issued kit goes on the uniques shelf** (`_read` at 1785 and 6095 → 2120-2122). Check that the Collection's "of N"
   doesn't overcount. S.
7. **`_remix_issued` skips silently with a full stash** (sim.gd:6399). Fold into A1. S.
8. **Over-level pay at the fixed levels.** A level-50 runner is paid a tenth at the Grid (50 - 35 - 3 = 12 over, x0.25
   a level) and half at the Mint (sim.gd:4511-4513). Fine if meant; the card should say so. S.
9. **Stale docs and comments.** the_issue.md:163 says the Mint is at 60 (code 45, data.gd:3394; status says 45).
   the_issue.md:140 still has the County "at the reach + `over`". data.gd:3385-3388 says "their level the reach +
   over" for all three. data.gd:3299 says issued kit is "never dropped" (heads drop it). The comment on sim.gd:2321-2324
   says the temper is "tins by item level". The FX comment for `node/fire_pct.notable_s` has been merged onto the
   issued plate's line (data.gd:1178, 1181). S.
10. **The bot's burn** (bot.gd `_issued`): one an hour at circ > 1.5 even at the cap, where it moves nothing (B1). S.

---

## 3. The endgame end to end

The path works in code, with no hard block. Each step:
- The campaign, then the substation rebuild, opens the Grid (sim.gd:5813-5818) at a set 35; its win drops `grid_key`
  (5986).
- The Mint's rebuild wants `grid_key` on its first rank (data.gd:3291); the Mint is at 45.
- The first Issuer win calls `issue()` (5989-5992): the pile is converted, the counter opens (`issued_block`,
  1764-1773).
- Issued kit is at reach + 5 and wearable at level 50 (items.gd:496-497 caps wear at MAX_LEVEL).
- The County: zone 0 is open once issued (6024-6027). Places open in turn, each Go wants 2/3/4/6 pieces worn
  (6045-6058), and each head down opens the next zone.
- The Treasurer down makes `county_done()` true, and from then on `decrypt` remixes (6367-6377). A save mid-run
  restores `_sig` with its `order` key (12142).

What makes it nonsensical or breaks it in play:
- **Lost rewards:** A1 (a head's piece lost to a death or a full stash).
- **The economy after the Issue:** A2 and A3 (the Clinic at hundreds of times the list price, ammo and meds free), B1
  (prices pinned at x4, the burn dead), B3 (notes swamp fiat income), B4 (kit beats cash).
- **The order after the Issue:** B2. The Mint is a print farm, the order's uniques and the heads' pieces drop under
  the reach, and §5's "grow with the remix's reach" no longer holds.
- **The last zone:** B6 (no build at the Treasury). B5 (the Collector barely bites).
- **A stand, not a block:** a death in the County puts the runner at level 1 (game2 M2). Issued kit comes home, but no
  County place can be entered until level 50 again, because the kit can't be worn till then.
- **The balance read:** B8 (the bot's post-Issue reads are the issued kit's) and B9 (the Archive in the broken
  verdict) mean the pass's County and broken figures don't yet say what they claim.

## Order I'd take them in
1. A1-A4: all S, no tuning. Each gets a smoke check.
2. B4 and C1-C3: small, words and one formula.
3. The fiat package for Matt, in one sitting, because the items interact: B1 (circulation decays, a burn as a share),
   B3 (notes into `_earn`, NOTE_TINS in the pass), B2 (levels after the first win, drops at the reach).
4. B5, B6 and B9: Matt's calls on the fights and the want.
5. B8 before the next pass, so gate 18 and the County reads are builds' reads.
6. Yesterday's open items (A9, A11, B6-B8, D1-D5, R10, M2, M3) as already listed; M2 now also touches the County.
