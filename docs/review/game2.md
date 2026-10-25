# Fiat - game re-review (the morning's fixes, the misses, the 19 reds), 25 Oct

Scope: scripts/sim/sim.gd, data.gd, items.gd, tests/bot.gd, tests/balance.gd, tools/balance_summary.gd, read against
rr/review/game.md, rr/second_pass.diff and rr/summary.md (the 32 h pass). Read only; nothing edited. Line numbers are
the fiatnow snapshot's. The snapshot has moved on since the diff in places (temper_over is now "tempers on the piece",
loadout_value is back on raw value, the Revolver reads the gun in hand), so everything below is checked against the
snapshot, not the diff.
Effort: S = under an hour, M = a session, L = several. Confidence: "confirmed" = traced through the code path (and the
read where a figure is quoted); "likely" = the code reads this way, worth one read to be sure.

---

## 1. The morning's fixes

### 1a. What holds

| Fix | Where | Verdict |
| --- | --- | --- |
| A1 odds read keeps the camp's nodes | sim.gd:6140, 6148-6154 | Holds. `is_camp` both ways; skills ride `_runner_out`/`_runner_in` so the read puts them back too. |
| A2 skills are the runner's | sim.gd:1097 (RUNNER_KEYS), 1125-1127, 1138-1141, 3107, 11684 | Holds for swap, respec and load. Not on a death: see R6. |
| A3 Revolver re-lands one shot | sim.gd:7527-7529, 7583-7590 | Holds: one shot of the single-target hit (no spread, no dots), capped at a man's HP, booked to its top type. Still chains through a gang the shot one-shots; the words say so ("a kill from it does the same"). |
| A4 Floored / Flattened on one man | sim.gd:7768-7773 | Holds: `1 - 1/on` and `1 - cut/on`. On the last man (on = 1) both are whole again, which is right. |
| A5 Clean kills | sim.gd:7398-7399 | Holds: own `if`, first bonus once. |
| A6 printed men heal and trigger on-kill skills | sim.gd:7225-7228, 7973 | Holds (no XP, drops or combos, as intended). |
| A7 skills cut by resist and lifted by shock | sim.gd:10578, 10742, 10747, 10925-10939 | Holds. Note: `_skill_base` is the hits of every type, then cut by the skill's own type (physical for most). A fire build's physical skill is cut by physical resist. Consistent with the words; flagged only so it's a known choice. |
| A8 Arsonist's Rig grows | sim.gd:7872 | Holds. |
| A12 smalls | sim.gd:594-595, 660-665, 919-924, 7980-ish | Jump Leads, element_lasts, incoming_shares, Hit and run pay all hold. Workbench (one job per 24 h, sim.gd:2051) and the tree-index notables (D3) are still open. |
| Held swing | sim.gd:7378-7382, their side ~7612 | Holds. The bot (1 s ticks) rerolls each tick; a player now rolls once a second. The odds' dry runs (DRY_STEP 2.0, sim.gd:6609) still hold one roll for 2 s, so the odds' spread is about 1.4x the live fight's. Minor. |
| SKILL_CAST_EVERY multi-cast | sim.gd:4820, 10585-10601 | Holds: 4 casts a 1 s tick, 8 a 2 s step. A skill whose cooldown is under the tick still fires once a tick (a player gets dt/cd). Minor. |
| sell_kept | sim.gd:10020-10037 | Holds; checks every class's saved kits. |
| Item worth by level | items.gd:447-452; sim.gd:1050 (sell), 2170 (scrap), 9912 (buy) | Holds on sell, scrap and buy. Insurance went back to raw value (sim.gd:4801-4808) on purpose; see R11. |
| Compounding paragon | sim.gd:294-295 | Holds for damage and HP. Tins was made compounding too: see R4. |
| Greed | sim.gd:1031-1040, 1015, 1045 | Works as written; inert for the bot (see 3, greed). |
| Tempering | sim.gd:2055-2056, 2094-2118, 2403-2406; bot.gd:694-724 | Works; three design problems, R1-R3. |
| OVER_LEVEL_FREE 3 | data.gd:3340; sim.gd:4260-4265 | Does nothing where the bot plays: R5. |

### 1b. New bugs and regressions from the fixes

#### R1. Rig, Backpack and Charm temper for nothing, and the bot spends three in seven tempers on them (confirmed)
- Where: sim.gd:2102-2112 (`temper_block` accepts any Data.SLOTS piece), data.gd:14 (SLOTS), data.gd:492/503/523 (the
  rig, pack and charm bases have capacity or find, no damage or armour); bot.gd:697 (`TEMPER_SLOTS` lists all seven),
  bot.gd:706-713 (cheapest first).
- What: a temper adds an item level, which only grows base damage and armour (items.gd:746-754). The three bag slots
  have neither. The bot picks the cheapest temper across seven slots, so it rotates evenly: the gun, which is the whole
  offence, gets one temper in seven.
- Why it matters: each reach level past 50 needs about 1.4 gun tempers to hold offence (crews 1.07 a level against 1.05
  a temper). The bot's rotation under-feeds the gun about 5x, so the read under-states what tempering does.
- Change: sim, block tempering on pieces with no damage or armour base (words: "Nothing on it grows"). Bot: temper only
  Primary, Armour, Helmet, Secondary, and pick by gain per scrap (the gun first) rather than cheapest.
- Effort: S.

#### R2. A temper grows the base, not the piece's flat lines; a drop at the same item level does (confirmed code; impact likely)
- Where: sim.gd:2403-2406 (temper only bumps `ilvl`), items.gd:427-441 (a drop's FLAT_GROW lines, hp, armour, regen,
  life_per_kill, are scaled at roll time), data.gd:1549 (FLAT_GROW).
- What: a tempered piece at item level 70 has its drop's HP and regen lines; a fresh 70 has them grown 5% a level.
  HP has no other compounding source below 50, and past 50 only the paragon's 2% a point. Armour stops physical only.
- Why it matters: past 50 the crews' fire grows 7% a reach level. Tempering the armour holds mitigation's share
  (armour_k grows with fight level, sim.gd:568), but nothing paid grows HP, so the defence side has no price to pay
  and the reach stalls there. This is the likeliest reason the level-50 reads still stand (Doorman as physical: depth
  level 72 by hour 12, then flat for 20 h at level 50 with 57k scrap held).
- Change: on a temper, scale the piece's FLAT_GROW affixes by (1 + ILVL_GROW), as a drop one level deeper would have
  them. One loop in the "temper" branch.
- Effort: S, then the read.

#### R3. A temper's tins are linear in item level, so it sinks no cash (confirmed)
- Where: sim.gd:2115-2118: `150 × (ilvl + 1) × inflation`.
- What: at item level 70 and hour 30 (inflation about 3.1) that's 33k tins. The reds hold 28-270M and earn 3-200M an
  hour. The Fence pays by `worth` (×1.05 an item level), so income grows geometrically and this price does not.
- Change: in section 3, gate 14.
- Effort: S.

#### R4. The paragon's tins row was made compounding; nobody asked for that and it feeds the cash flood (confirmed)
- Where: data.gd:1502 ("each on the last"), sim.gd:8808 (`m["cash"] *= paragon_mult("tins")`).
- What: the review asked for damage and HP to compound (B1.2) and for tins and find to go behind them (B9). 3% a point
  compounding is ×4.4 at 50 points against ×2.5 added. The bot never buys tins (bot.gd:1055), so the read can't see it;
  a player who stacks it will.
- Change: tins back to added (`1 + pct × pts / 100`) and the words back.
- Effort: S.

#### R5. OVER_LEVEL_FREE can't bite in the campaign, and hides a cliff at WEAR_FLAT (confirmed)
- Where: sim.gd:4260-4265; items.gd:475-480 (`max_ilvl_for`).
- What: in the campaign `mine = min(max_ilvl_for(level), deepest_cleared_level())`. The bot always runs the frontier
  or its deepest cleared site, so `beyond = deepest - lv - 3` is never above 0: every run pays whole. The 5 → 3 change
  only touches sites four or more levels under the deepest clear, which the bot doesn't farm. Separately,
  `max_ilvl_for` jumps from 8 at level 15 to 16 at level 16, so without the clamp the pay would drop from whole to the
  10% floor between levels 15 and 16 at the Bank. The clamp is all that stands between the code and that cliff.
- Why it matters: gates 4 and 16 (the bot 4-7 levels over each site's gear) were meant to be fixed by this. They
  weren't (Bank 17 against gear 10, as before).
- Change: in the campaign, compare in wear terms: `beyond = level() - wear_of(lv) - OVER_LEVEL_FREE`, and drop the
  D12 clamp. At the Bank: the bot at 17 against wear 10 pays 0.40; Matt at 13 (his last record) pays whole. Past the
  campaign keep the item-level form, where max_ilvl_for = level.
- Effort: S. It's a design call (D12 said "held at a wall, its last sites pay whole"), so it's Matt's.

#### R6. A death leaves the dead runner's skills in the slots (confirmed, low)
- Where: sim.gd:1137 (the comment says "a swap, a load, a death, a respec"), 9131-9145 (`_refund_runner_trees`, no
  call), 3077-3080 (a skill learnt only fills an empty slot).
- What: the new runner of the same class relearns the slotted ones fine, but a different first skill can't auto-slot
  until all three are relearnt or cleared by hand.
- Change: call `_skills_known_only()` at the end of `_refund_runner_trees`.
- Effort: S.

#### R7. Gate 15 measures scrap against a price nothing pays any more (confirmed)
- Where: balance.gd:452 (`dearest_build = BUILD_GUN × 3` = 120), balance_summary.gd:66, 580-586.
- What: the dearest craft is now a temper, whose price grows with use. Scrap income now also grows ×1.05 an item level
  (sim.gd:2170, by `worth`). The gate divides a growing income by a fixed 120.
- Change: section 3, gate 15.
- Effort: S.

#### R8. The summary can't show whether tempering ran (confirmed)
- Where: balance.gd:462 records `tempers`; balance_summary.gd never reads it.
- Change: a "Tempers" column (count, and the kit's item levels at the end against the runner's level and the reach),
  plus how many passes ended on "too_high". Without it the P5 read can't tell a price stall from a wear stall.
- Effort: S.

#### R9. The bot's Weed Burner penalty doesn't stop it, so the gun still decides five builds (confirmed)
- Where: bot.gd:853-854 (−0.45 share), 869-870 (`_elem_score`), 873-883 (`_hold_the_element` swaps only to a gun at
  ≥ ELEM_DPS_FLOOR 0.8 of `damage_total`), 303-308 (`equip_best` first, by try-on), bot.gd:1263.
- What: `equip_best` fits it by damage, then the element check only swaps when an element gun reaches 80% of it. None
  does, so it stays. The parity kits show it on Recruit as poison, Poacher as frost and Scrapper as shock, three of the
  five laggards, each with its own element switched off. On the end kits it fell from 11 of 24 to 6 (the fire builds
  and two frost).
- Why it matters: the Weed Burner's single-target figure (all fire, +40% fire, +30% dot, the burn on top) beats every
  element gun by more than 25% before its spread is even counted (`damage_total` is single-target and resist-blind,
  sim.gd:713-737). That's a design fact, not a bot one. See parity in section 3.
- Effort: data S.

#### R10. The pack drops by raw value while the Fence pays by worth (confirmed, low)
- Where: sim.gd:8331 (pack order), 8611 (`cheapest_in_pack`).
- What: a full pack throws out the lowest `value`, so a deep rare (worth ×7 at item level 60) goes before a shallow epic
  that sells for less.
- Change: `Items.worth` in both.
- Effort: S.

#### R11. Insurance is on raw value again (design note, not a bug)
- Where: sim.gd:4801-4808, 3626-3629.
- What: the comment says it was reverted because priced by item level it "outgrew a deep run's takings". So the kit's
  risk at depth stays cheap to cover, and C7 ("death that costs at the reach") is off the table. Fine if intended;
  it removes one cash sink the cash gate was counting on.

---

## 2. What the first review missed

#### M1. Below level 50, tempering and the kit are capped at the runner's level, so the reach depends on XP (confirmed)
- Where: sim.gd:2110-2111 (`wear_for(ilvl + 1) > level()` blocks), items.gd:470-480 (past WEAR_FLAT wear = item
  level; no cap only at MAX_LEVEL), sim.gd:10075 (`can_wear`).
- What: a level-40 runner can't wear or temper past item level 40, whatever the scrap. The reach runs 10-25 levels over
  the runner's level (summary builds table: reach 59 at level 37, 53 at 41). Every read that reached 50 by hour 8
  ended at reach 69-76; every read that never reached 50 ended at 29-53.
- Why it matters: this links P5, gate 8, gate 15 and parity into one loop. XP a kill grows 5% a reach level
  (sim.gd:5058-5062, CURVE reward), so a strong build's reach pays it up to ~9x the XP of a weak one's (reach 76 against
  30), it reaches 50, the wear cap goes, tempering opens up, and the reach runs. A weak build stays wear-capped, its
  scrap piles (Poacher as frost: 27,591 held at level 44), and its reach stands. The first review's "nothing on the
  runner's side compounds" is true past 50 only; below 50 the binding limit is level, not price.
- Change: no single constant. The levers are in section 3 (gate 8, parity). Worth knowing before tuning TEMPER_GROW:
  below 50 the price barely matters.
- Effort: n/a.

#### M2. A death past 50 puts the runner back to level 1, and the read shows it (confirmed)
- Where: sim.gd:9097-9100 (`xp = 0`), 9131 (trees refunded); the summary's end levels.
- What: every read that reached 50 ends under 50 (Doorman as physical 27, Poacher as poison 47 and 19, Paramedic as
  shock 38, Scrapper as shock 45). The kit, insured or not, then can't be worn (wear = item level). Re-levelling at a
  high reach is quick (the crew's 1 → 50 in 2.0-2.2 h, Recruit as poison read 2), but it's a stand each time.
- Why it matters: gate P1 asks for a death one run in 10-30. With this death cost, that rate would erase the endgame.
  The two gates are in tension, and P1 is classed as bot play.
- Change: Matt's call. Either P1's band is for the campaign only, or a death past 50 keeps some level (say 50 → 40).
- Effort: S once decided.

#### M3. The bot can never meet a third gang, so gate 11 and greed can't be read (confirmed)
- Where: bot.gd:249 (`m["patrols"] >= 2` leaves).
- What: greed tops out at two gangs for the bot: +20% quality, +10% quantity. Gate 11 is "—" by construction.
- Change: let the bot stay while greed's next step beats the risk (HP over 60%, odds on the site ≥ PUSH, pack not
  full), up to five gangs. Or drop gate 11.
- Effort: S.

#### M4. Greed's quantity is counted three times (confirmed; A9 still open)
- Where: sim.gd:1015 (in `loot_bonus`), used at 8015 (drop chance a kill), 8433 (`thin_after`: more searches) and 8577
  (extra a search).
- What: +10% greed quantity is about 1.1³ = 1.33x the finds on a picked-clean site. "Quantity honest" reads finds a
  search and can't see it.
- Change: keep `loot_bonus` in one of the three (the review's A9).
- Effort: S.

#### M5. The odds are a cliff, so P6's coin flip can't happen (likely)
- Where: sim.gd:4819 (VARIANCE 0.25, now held a second), data.gd:1454-1456 (×1.12 a level to 50, ×1.07 past it, on
  both HP and fire), data.gd:3220-3223 (Full rolls −3 to +1).
- What: a fight is many seconds of a ±25% swing, so its outcome averages out and the odds are close to a step function
  of the power ratio. One level is ×1.25 (pre-50) or ×1.145 (past 50) on the fight. The data.gd comments already say
  it: "the odds fall from 100% to 0% in two levels". A full signal at the reach therefore reads either ≥0.88 (the bot
  runs it and wins 82%) or under 0.5 (it waits).
- Change: section 3, P6.

---

## 3. The reds

The design reds first, by Matt's priority. Bot timing and bot play at the end, briefly.

### Gate 14, cash sink (5 builds at 2.2-2.5 h of income held; 28-270M tins)
- Cause: income grows geometrically (kill cash ×1.05 a reach level, the Fence's prices ×1.05 an item level since
  `worth`, inflation ×3 by hour 32); every sink is flat or linear (R3, and insurance on raw value, R11). The red is
  marginal in hours (2.2-2.5 against 2.0), so a modest sink that scales clears it.
- Try: the temper's tins as a share of the piece's own sale: `_temper_cash = sell_price(it) × TEMPER_CASH`, new
  `TEMPER_CASH := 4.0` (sim.gd:2115-2118), in place of `150 × (ilvl + 1)`. A tier-6 epic gun at item level 60 sells for
  about 86k at inflation 3, so a temper is about 350k; five a reach level is about 1.7M, a quarter of an hour's income
  for the Doorman as bleed (7.4M/h). Expected: about 0.3-0.6 h of income off the held figure on builds that temper,
  which puts the five under 2.0. And revert the tins row (R4), which doesn't move the read but stops a player's flood.
- Interacts with: P5 (the tins become a second limit on tempering; if cash binds before scrap, lower TEMPER_CASH).

### Gate 15, scrap (10-140 crafts/h against 0.5-7)
- Cause: two. The yardstick is 120 scrap (R7), a price nothing pays now. And below 50 the wear cap strands scrap (M1):
  Poacher as poison holds 107k at level 47 (died after 50), Poacher as frost 27.6k at 44. Where the cap isn't in the
  way, tempering spends it: Drifter as bleed ends with 55-68.
- Try: change the gate before the sim. Measure scrap like cash: "scrap in hand at the end no more than 2 h of scrap
  income", and report tempers an hour (R8). Then set the sim's price (P5 below). Leave SCRAP_PER_POUND at 24: with
  `worth` in `scrap_of`, scrap income now grows with item level as the new temper price would, which is the point.
- Interacts with: P5's price and M1's cap. Builds stuck under 50 will stay red on "held" until gate 8 moves.

### P5, the endgame's stall (the reach stands 10-27 h) and gate 6 (204 min on the median read)
- Cause, past 50 (confirmed arithmetic, likely as the main cause): a piece that's kept needs about 1.4 tempers a reach
  level to hold offence (ln 1.07 / ln 1.05). At TEMPER_GROW 1.10 a temper, the price grows 1.10^1.4 = 1.14 a reach level
  while income grows 1.05: each level costs about 9% more time than the last, so the pace halves every 8 levels. That's
  a ceiling in all but name. R1 (a seventh of tempers on the gun) and R2 (no HP from tempering) make it worse. Below
  50, M1: the wear cap, not the price.
- Try, in this order:
  1. Price by the piece's item level, not its temper count: `temper_scrap = CRAFT.temper.scrap ×
     pow(TEMPER_GROW, max(0, ilvl - ILVL_GROW_FROM))` (sim.gd:2094-2099). This matches `worth` and `scrap_of`, so price
     and income grow together, and a lagging build tempering a low piece pays less: catch-up, not a ceiling.
  2. TEMPER_GROW 1.10 → 1.035 (data.gd:2415). 1.035^1.4 = 1.049, matching income's 1.05. The pace then holds level on
     level.
  3. CRAFT.temper.scrap 20 → 100 (data.gd:2411) to set the pace: about 280 scrap a temper at item level 50 and 560 at
     70, so the four or five a reach level cost about 0.5-1 h of the median build's scrap. Expected: 1-2 reach levels
     an hour past 50. That's gate 6's rate, and the stand should drop under 2 h.
  4. R2 (flat lines grow on a temper) and R1 (bag slots out; the bot tempers the gun first).
- Risk: runaway past 50 if the base is too low. If a read shows over 3 reach levels an hour, raise the base, not the
  growth.
- Interacts with: gates 14 and 15 (the same price), parity (the strong builds' scrap income is about 15x the weak
  ones'; pricing by item level softens it), gate 8 (M1).

### P6, the signals (full at the reach won 82%; band 35-65%)
- Cause: mostly the bot's choice. It runs a signal at ≥ PUSH 0.88 (bot.gd:563-570) and at COIN 0.5 only with three held
  and none at PUSH (bot.gd:571-580). With odds that jump from 100% to 0% inside two levels (M5), almost all its at-reach
  runs are near-sure ones. 82% won on picks at 0.88+ also says the odds read a little high, which fits the dry runs'
  2 s swing (1a).
- Try: (a) re-class P6 as bot play (balance_summary.gd:19-20), or measure the odds of full at-reach signals when they
  are made rather than the win rate of the ones the bot chose. (b) For the design side, widen the odds: hold the swing a
  gang rather than a second (sim.gd:7378-7382 and the enemy side: reroll on `_gang_arrives`). A gang then runs ±25%
  as a whole and one level stops being a cliff. Expected: the 100→0 fall goes from about 2 levels to 3-4. Needs a
  read. It also moves P1-P3 in the right direction (more wounds, more deaths).
- Interacts with: P1-P3, M2.

### P. Build parity (5 builds under half the best's +57)
- Cause, three parts:
  1. The Weed Burner (R9): three of the five laggards wear it as a non-fire build.
  2. A death decides a 4 h read: Recruit as physical (+13) and Paramedic as shock (+18) both died (level 28 → 16, damage
     fell to 598 and 1,272). One read a build, one death, half the spell gone.
  3. M1's loop: the read starts at level 28, so every build is wear-capped at item level 28-40 for most of the spell,
     and the one with the most XP a kill pulls away.
- Try: (1) the Weed Burner's `fire_pct 40` → 0 (data.gd:822-823), keeping the conversion, the dot and the spread. That
  cuts its all-fire hit by about 29% with no other fire% in the kit, roughly the 25% gap the bot's floor shows. If the
  three still wear it, the spread has to go to burning men only (sim.gd:7469). (2) Harness: insure the parity reads, or
  judge each on its reach before its first death, and run two a build (balance.bat). (3) Nothing on the cap until gate
  8 is settled.
- Interacts with: the fire builds (Drifter and Scrapper as fire lose some), gate 15 (fewer scrap piles once the
  laggards climb).

### Gates 16 and 4, levels against the sites (Bank 17 against gear 10; Quartermaster 25-28 against 20-24)
- Cause: R5. OVER_LEVEL_FREE can't cut pay at the frontier. And the bot is slower than Matt: the Manager at a median
  1.6 h against his 54 min at level 13 (3 over the Bank's gear 10, which is green). The extra hour is extra levels. So
  most of this red is the bot's pace, and the hand figure is inside the band.
- Try: R5's wear-terms comparison with OVER_LEVEL_FREE 3 and OVER_LEVEL_STEP 0.15 as they are. Expected: the bot's pay
  at the Bank falls to about 0.4 once it's 7 over, so the levels track gear to about 3-4 over; Matt's runs are
  untouched. Don't raise XP_SCALE for this: 3.3 → 4.5 would take the bot's Quartermaster to about 23 but Matt's to about
  14, under the Barracks' gear 16.
- Interacts with: gates 2 and 5 (the bot's later levels push level 30 later; gate 5 is already late), gate 8.

### Gate 8, retirement (median 25.8 h, 11 of 24 never; 3 reads before hour 8)
- Classed bot timing, but it drives M1. The spread (5.1 h to never) is what's wrong, not the median, and XP_SCALE can't
  fix a spread: faster XP makes the 5.1 h reads earlier.
- Try: leave it for this pass. If Matt wants one number: XP_TAPER_END 3.4 → 3.0 (data.gd:3369): levels 40-50 cost 12%
  less (192k XP against 218k). The real compression comes from parity and P5.
- Note gate 5 (level 30 within 2 h of the Quartermaster) is partly an artefact of the one-save route: the Drifter and
  Recruit targets open at 2.0-4.0 h, at or after the Quartermaster, and start at level 1.

### Runaway checks
- Compounding paragon: no sign. The reach tops out at 69-76 on the four reads at 50 by hour 8, and their depth-level
  climb flattens after hour 12 (Poacher as poison 36/63/63/75/76/76 at hours 4/8/12/16/24/32). Against the old adding
  it's worth +6% at 20 points, +23% at 40 and +49% at 60. Points come as about the square root of XP (each costs 5%
  more), so the risk is only over a 100 h+ save where the reach climbs steadily and XP a kill compounds. Worth one long
  read after P5's change, not before.
- Greed: no sign, and no effect for the bot (M3): at most +20% quality and +10% quantity (×1.33 with M4) for a few
  seconds a run.
- Tempering: no runaway at 1.10. With P5's 1.035 it needs watching: the read should report reach levels an hour past
  50 (R8).

### Bot timing (low priority; his play calibrates)
- 2 (Quartermaster 2.4 h against 2.5-3.4), 17 (Gamekeeper 0.3 h, on the band's edge), P4 (lorry 4.0 h against
  8.5-11): the bands come from older hand figures. Matt's last record (the Manager at 54 min) makes the bot about 0.56
  of a hand, not the gates' 0.85. Re-anchor BOT_PACE before reading these again. P4's lorry at 4 h is likely tempering
  and the uniques making the convoy light; CONVOY_HP 0.55 is the lever if his play agrees.

### Bot play (P1, P2, P3 and the "as played" rows)
- One cause: PUSH 0.88 (bot.gd:11) plus odds that are a cliff (M5) put every run at 100%. Not for tuning now. M2 says
  P1's band and the death cost need a decision before any bot change chases it.

---

## Interactions, in one place
- TEMPER_GROW, the temper's base price, TEMPER_CASH, gate 15's yardstick and R8 are one change: do them together and
  read once.
- R2 (HP on a temper) and P5's price: R2 makes each temper worth more, so with R2 in, the base price is likelier to need
  the high side (100 rather than 50).
- Weed Burner, parity and the fire builds: the cut moves Drifter and Scrapper as fire down while the others come up.
- R5 (over-level pay) lowers the bot's campaign levels, which moves gates 2, 4, 5, 16 and slightly gate 8.
- Per-gang swing (P6b) moves P1, P2, P3 and P6 together, and makes deaths (M2) more frequent.
- Gate 8 and M1: anything that speeds XP pre-50 also loosens the wear cap, so it speeds the reach and tempering too.

## Order I'd take them in
1. R1, R2, R6, R10 and M4: small, no tuning.
2. The temper package (P5 1-3, gate 14's TEMPER_CASH, R4, R7, R8), then one read.
3. The Weed Burner's fire_pct and the parity harness (insured, two reads), in the same read as step 2 if time is short.
4. R5 (Matt's call on D12), then gates 4 and 16 again.
5. The P6 and P1 calls with Matt (re-class or the per-gang swing; the death cost), before any bot change.
