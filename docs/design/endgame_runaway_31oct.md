# PROBE36: the endgame runs away after the Quartermaster (31 Oct, 17:30-18:50 UTC)

Copy: `pr36` (p35 = 9f22bcf, untouched). Probe: `pr36/tests/p36.gd`, hooked into `sim.gd` (`_gain_xp` / `_earn` take a
source tag; `_extract` logs the run's cash parts; Fence sales logged by item) and into `balance.gd` (`_gate` and
`parity_play`). Every 15 game minutes it prints `P36` (level, reach, dps, XP/h and cash/h by source, spend/h),
`P36D` (dps in its parts), `P36R` (per run: kills, XP, pay against the curve, pool, items sold) and `P36S` (spend by
sink). Logs and the lever copies are in `pr36/probe36/`. Snapshot: `/mnt/user-data/outputs/snap/pr36.tgz`.

Caveats:
- The cloud runs 2 CPUs, at about half the speed of Matt's machine. Seed 0 means random dice.
- 4 of 9 one-save reads stalled in the campaign at levels 17-21 with the Fence never open (DB, PCT twice, the first
  checkpoint). Not this question, but the quick pass will see it too.
- The lever A/Bs are parity reads from one Radio checkpoint (written by this copy at 1.78 h, level 21). They run
  without the crew or repeats, with the tree re-spent. One read each.

Reads used:
- PP / PP_a: Poacher as poison (gun).
- DB / DB_a: Doorman as bleed (melee).
- AP: Poacher as played.
- PB: the baseline parity read.

## 1. The curves (one-save reads, from the Quartermaster)

| read | QM (h) | level 30 | 40 | 50 | reach at QM +0.5 / +1 / +1.5 / +2 h | dps (total) at the end |
|---|---|---|---|---|---|---|
| PP_a Poacher poison | 1.75 | 2.25 | 2.25 | **2.50** | 44 / 96 / - / - | 402k (2.75 h) |
| PP Poacher poison | 1.52 | 2.51 | 3.00 | **3.25** | 18 / 28 / 47 / 79 | 20.2M (3.77 h) |
| DB_a Doorman bleed | 2.53 | 4.25 | 4.75 | **5.00** | 16 / 20 / 26 / 37 | 105k sheet (5.75 h) |
| DB Doorman bleed | 5.52 | 6.50 | 6.77 | **7.25** | 20 / 37 / 51 / 66 | 16.5M (7.75 h) |
| AP Poacher as played | 1.77 | 3.01 | 3.53 | **4.00** | 19 / 23 / 36 / 52 | 7.9M (4.31 h) |
| PB parity baseline | 1.83 | 2.76 | 3.00 | **3.26** | 20 / 32 / 60 / 73 | 2.9M (3.52 h) |

Level 50 came 0.75-2.25 h after the Quartermaster in every read. Once it started, the reach climbed 20-60 levels an
hour; in 25 Oct's pass it was 2.3-4.9.

PP, every 15 min (the shape is the same in every read):

| h | lv | reach | sheet dps | total dps | XP/h | cash in/h | held |
|---|---|---|---|---|---|---|---|
| 2.51 | 32 | 28 | 3.1k | 25.6k | 100k | 11.2M | 0.47M |
| 2.76 | 38 | 34 | 3.7k | 36.7k | 176k | 19.5M | 2.2M |
| 3.00 | 45 | 47 | 7.1k | 87.9k | 449k | 65.1M | 4.7M |
| 3.25 | 50 | 63 | 45.9k | 638k | 4.79M | 251M | 6.9M |
| 3.50 | 50 | 79 | 237k | 5.89M | 14.0M | 306M | 34k (the Issue) |
| 3.77 | 50 (paragon 60) | 87 | 809k | 20.2M | 200M | 4.6M fiat | 59k |

PP_a reached paragon 590 at 2.75 h, with XP at 1.1 G/h.

## 2. Where the XP comes from (Q1)

- **Signals: 80-100% of the XP past the Quartermaster.**
  - Kev's story signals: 4-38%.
  - The orders and the County: 0-10%, in only a few windows.
  - Repeats: 0%, except one 15 min window at 31% (AP 3.75 h).
  - Expeditions and the crew lift: under 1%.
  - Within a run, kills are about 75%, the clear about 22% and the head about 3%.
- **XP/h grows about 12% a reach level** (PB: 48.6k/h at reach 28, 213k at 32, 804k at 51, 1.64M at 60). It is
  the product of four things:
  - **CURVE reward 5% a level** on every kill: ×5.5 from reach 15 to 50.
  - **The pay against the curve** (`P36R xpk_vs_curve`): 0.1-0.45 just past the QM (the over-level share), 1.0-2.5 by
    reach 30-80 (the words' XP pay), and 4-7 once the deep words come in.
    - **Full house** (pool ×3, xp ×2, at Radio level 40) is raised to `WORD_TIER_POW` 2.5-3.5 and gets the radio
      ranks' pay boost.
    - It took signal pools from 13-36 to **105 (AP) and 249 (PP)** kills a run.
    - XP a run went from 3.6k to 1.9-4.5M (PP 3.50 → 3.77 h: XP/h 14M → 200M).
  - **Runs an hour**: 80-400 signal runs an hour (9-45 s each), rising as the runner overpowers the sites.
  - **The reach itself**: +1 a win at it (`sim.gd` 8248), so its pace is how fast the bot wins full signals at the
    reach. Here that's about 50 an hour, the signal-limited ceiling, because the bot never fails.
- **XP_SCALE and the taper don't decide it.** Level 22 → 50 is 300k XP. The band (12-24 h) needs an average of about
  14-30k XP/h. The reads pass 30k/h at reach about 25 and 300k/h at about 45, within the first hour.
  - Even a frozen reach doesn't hold it. PBOTH stood at reach 54-61 for 1.5 h, earned 120-460k XP/h there, and took
    level 50 at QM +1.4 h.
  - The runs alone, with no growth: about 150 runs × 13 kills × 30 XP × 1.3 ≈ 75k/h at reach 10. That's level 50 in
    about 4 h. **The run rate makes the 316k-XP curve too short even before the reach runs.**
- **Paragon after 50** (`PARAGON_XP_GROW` 0.05): level costs grow linearly while XP/h grows exponentially. The paragon
  went 0 → 60 in 34 min (AP) and 53 → 590 in 15 min (PP_a).

## 3. Where the cash comes from, and the sinks (Q2)

- **Before the Issue, 94-99% of cash in is Fence sales of loot.** Run cash (kills, heads, the mint) is 1-6%.
  - PP 3.25 h: 251M/h, of which 98% was the Fence: 4,646 items sold an hour at a mean of 53k, ilvl 39.5.
  - PP 3.50 h: 5,466 an hour at 55k, ilvl 50.6.
- **Why it grows by orders of magnitude (no compounding multiplier):**
  - The item's worth is `value × 1.05^(ilvl-20)`, and ilvl follows the reach (drops at the signal's level, gambles at
    the deepest level). Mean sale: 7.3k (ilvl 17) → 55k (ilvl 51).
  - Items an hour: 1,000 → 5,500 (runs an hour, words' drop ×1.4-2.5^pow, pools of 36-249).
  - Inflation adds only 1.0-1.3.
  - So cash/h tracks the reach: ×10 every 30 min while it runs (PB: 4.35M → 17.7M → 113M → 175M/h at reach 20 /
    32 / 51 / 60).
- **The sinks take almost all of it.** Spend/h ≈ income/h in every window.
  - What takes it (`P36S`, PB):
    - Pitch ranks: 60-175M/h at the peak. Each rank is ×1.5 the last, so they absorb only the log of income.
    - Bench crafts: 1.4-10M/h.
    - Gambles: 0.4-6M/h. Priced at 2 runs' takings, Fence money included.
    - Exchange and picks: the rest.
  - Cash held at the 15-min marks: 0.5-18M before the Issue. Between purchases it peaks in the tens of millions;
    a capped read that ends there, or never beats the Mint, shows hundreds of millions to £1bn.
  - Gate 14 stays green because held and income both scale with the reach.
- **The sinks feed power.** Gambles roll at the deepest level, Bench crafts and re-rolls improve kit, and radio ranks
  add +5% word pay each. So income is part of the power loop.
- **After the Issue**: fiat income falls about ×1000 (PB 66M → 0.1-0.3M/h). Runs a few hundred to 2,000 a window
  (repeats) of sales at ƒ33-163 each. Circulation hits the ×4 cap within 15-30 min (PP_a, AP). The reach climb slows
  where gambles stop (L12: about 14/h after the Issue against about 28/h before).

## 4. Power or rewards? Both, and they feed each other (Q3)

**Power outgrows the content.** Total dps from the parts (`P36D`), PB 2.76 → 3.52 h, reach 32 → 73 (41 levels):

| part | growth (ln) | note |
|---|---|---|
| guns' dps (primary + secondary) | 2.33 | ilvl 29 → 68 at ILVL_GROW 5% (1.90), base swaps to a deeper tier (0.46) |
| level + damage% pool | 0.82 | % lines grow linearly with ilvl (ILVL_SCALE 0.06 from ilvl 15) |
| increased element, conversion, dot grow | 0.66 | inc 276% → 465% |
| paragon damage (compounding 2%/pt) | 0.18 | 9 points; 60 by AP 4.31 h (×3.28) |
| attack% | 0.15 | |
| **runner, total** | **4.14 (10.1%/level)** | |
| content (CURVE 12% to 35, CURVE_LATE_GROW 7% after) | 2.91 (7.1%/level) | |

- **Melee** (DB 6.01 → 7.75 h, reach about 25 → 80) grows 12.4%/level against the content's 7.6%. Its dots are 92% of
  its damage (dot 15.2M of 16.5M; bleed more ×2.8; inc 315 → 597%).
- **Between the QM and reach 35** (the 12% band) the runner climbs 20-30 levels an hour. It arrives with a margin:
  signals at reach 10-24 are softened by `curve_k` (0.7-0.88). Then the deep-tier bases land at levels 10/13/16/20/24,
  and the % lines grow fastest from their low base (×1.9 from ilvl 15 to 30). PB 1.83 → 2.76: total dps ×22 against
  content about ×15.
- **The rewards' own curve** (CURVE reward 5% a level, words' pay and pool raised to WORD_TIER_POW, item worth 5% an
  ilvl) turns every reach level into about 12% more XP and cash an hour. The cash buys the gambles and crafts that
  push the reach. After 50, the paragon's compounding damage on levels that cost a linear 5% more becomes
  double-exponential.

## 5. Levers tried (parity reads from one checkpoint at 1.78 h, level 21, reach 11)

| read | change | level 50 at | reach at QM +1 / +1.5 / +2 / +2.5 h | deaths |
|---|---|---|---|---|
| PB | none | 3.26 (QM +1.4) | 32 / 60 / 73 / 73 | 0 |
| PL12 | CURVE_LATE_GROW 0.07 → 0.12 | 3.00 (QM +1.2) | 41 / 66 / 73 / 73 | 0 |
| PPCT | % affix lines stop growing past ilvl 20 (rule) | 3.52 (QM +1.7) | 28 / 44 / 66 / 73 | 0 |
| PBOTH | PL12 + PPCT | 3.25 (QM +1.4) | 46 / 54 / 59 / 60, then held 54-61 for 1.5 h | 0 |
| PALL | PBOTH + CURVE grow 0.12 → 0.16 | none: level 38 at QM +1.9 h, then died twice | 26 / 32 / 38 / 39 | 2 |
| PRW | CURVE reward 0.05 → 0.02 alone | none: 36 at QM +1.2 h, then died 4 times | 34 / 48 / 48 / 50 | 4 |

The L12 one-save read (seed differs) took level 50 at 3.76 h (QM +1.75).

What they showed:
- The late-band levers (PBOTH) **hold the reach** past about 55: the bot is power-limited there again. They don't
  move level 50, because the early band (10 → 50 in 1.2 h) is untouched.
- grow 0.16 slows the early band to about 13 levels an hour and roughly doubles the time to level 38.
- Reward 0.02 cuts XP a run to 0.4-0.5 at reach 34-41 (PRW 92-120k/h against PB's 213-804k/h).
- **New finding: a death below 50 sets XP to 0.** The bot runs a full signal at the reach at COIN 0.5. Any lever that
  makes the bot level slower than its reach (PRW), or the content bite (PALL), turned into repeated deaths (lv 36 →
  18, 36 → 6). In the baseline reads it never dies because it's overpowered. **That rule will decide where level 50
  lands for any slower curve.**

## 6. Levers, ranked

Each says where I think level 50 and the cash would land. Estimates are from one-read A/Bs and are rough.

1. **Hold the reach to a pace: content at least the runner's growth, early and late (numbers).** CURVE grow 0.12 →
   0.15-0.16 and CURVE_LATE_GROW 0.07 → 0.12.
   - Measured: the early climb 10 → 38 took 2 h instead of 1 h, and past 55 the reach stood.
   - Estimate: the reach at about 10-15 levels an hour, not 30-60. Level 50 at QM +3-5 h (about 5-7 h of read), still
     under 8 on its own.
   - Cash/h about 10× lower at a given hour, since it tracks the reach.
   - Risk: the 50% full signals then kill the runner (2 deaths in PALL).
2. **The percent lines stop growing with item level past the deep tier (`affix_mult`: `ilvl_mult(mini(ilvl,
   ILVL_GROW_FROM))`). A rule change.**
   - Measured: alone it slowed the climb by about 35% (level 50 at +0.25 h). With lever 1 it took the runner's
     late-band growth from 10.1% to about 5-7% a level, so the content leads.
   - It also removes the % pools' compounding behind the melee dots.
   - Paired with 1: the reach is power-limited from about level 40.
   - It changes how deep drops feel. That's Matt's call.
3. **Less XP a run as the reach grows, then the taper (numbers).** CURVE reward 0.05 → 0.02, then XP_TAPER_END from
   3.1 as the reads say.
   - Measured: XP a run ×0.4-0.5 at reach 34-41.
   - With 1 + 2, from about 30-120k/h at reach 25-40 down to 12-50k/h. Estimate: level 50 at about 10-16 h, inside
     the band. Fine-tune with XP_TAPER_END: 3.1 → 4 is about ×1.3 on levels 40-50.
   - Kill cash falls too, but it's 1-6% of income.
   - **Only with the death rule settled**: on its own it caused 4 deaths in 3.7 h (level resets) and level 50 never.
4. **The death below 50 at 50% signals (design).** Either the bot runs full signals at the reach at FIRST (0.65) or
   PUSH, or a death past the Quartermaster costs a slice of the level, not the whole.
   - Without one of these, every slower curve in 1-3 reads as "never" or swings by hours on one bad roll.
   - Estimate: it turns the PALL/PRW reads back into steady climbs.
5. **The word pool's power and the Fence's curve (numbers, two dials):**
   - (a) Cap `pool` (and `drop`) in `word_effect` at WORD_TIER_POW 1.75 (about ×2 at most from Full house, not ×15-47).
     That cuts deep-signal XP a run and items an hour 5-20× once the reach passes Radio level 40.
   - (b) An item's sale worth on a slower growth than its damage (e.g. 2% an ilvl past 20 in `Items.worth`, not 5%).
     That puts the Fence's mean at ilvl 50 about ×0.42 and at ilvl 80 about ×0.18.
   - Estimate with 1 + 2: cash in about 1-10M/h by hour 8 instead of 100-500M/h at hour 3-4.
   - (b) also slows the gambles and crafts, since they're priced off income.
   - Matt's design stance ("infinite scaling is the point") is kept: both set the pace, not a ceiling.

Not ranked: the paragon (PARAGON_COMPOUND damage/hp, PARAGON_XP_GROW 0.05). It's downstream of 50, so it doesn't move
the retirement gate. It is behind the post-50 millions: ×3.28 damage from 60 points in 34 min; 590 levels in 15 min
in PP_a. If 1-3 hold the reach it slows by itself. If not, PARAGON_XP_GROW 0.05 → 0.25 or the rows adding (not
compounding) is the next dial.
