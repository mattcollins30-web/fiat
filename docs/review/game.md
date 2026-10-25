# Fiat - game review (sim, systems, design), 25 Oct

Scope: scripts/sim/sim.gd, data.gd, items.gd, plus tests/bot.gd where the bot explains a balance read. Read only;
nothing edited. Line numbers are the snapshot's. Effort: S = under an hour, M = a session, L = several.

Confidence: "confirmed" = traced through the code path; "likely" = reads wrong, worth a smoke check first.

---

## A. Bugs

### A1. A crew odds read strips the live runner's element nodes and ring nodes (confirmed, high)
- Where: sim.gd:6058-6073 (`_read_as` / `_read_back`), called from `signal_odds_class` (6037), which the Radio's crew
  row calls every frame (radio.gd:651, 1069; main.gd:511-512) and the bot calls in `_crew_turn` (bot.gd:61).
- What: `_read_as` saves `"pitch": tree.filter(is_pitch)`, but `_runner_out()` (1118) already drops every `is_camp`
  node (the Pitch, the element trees, the ring). `_read_back` rebuilds the tree as `out.tree + pitch`, so every
  element-tree node (starters included) and every ring node in `tree` is gone after one read. `set_class` (1088) does
  this correctly with `is_camp`; the read uses the narrower `is_pitch`. The `now=true` path only returns early on a
  cache hit (6044); a miss still does the full swap.
- Why it matters: open the Radio with a signal selected and a second class played, and the runner silently loses
  the element half of the build. Element points and the Pitch point then read as free. The element meter stops,
  because only an opened element fills. The bot hides this because `_train_tree` buys the nodes back every step. A
  player won't. The other class's odds are also read without its element nodes, so pillar 2 ("swap to the bleed
  build") shows wrong figures.
- Change: in `_read_as`, keep `tree.filter(is_camp)` (as `set_class` does) and add it back in both places. Add a smoke
  check: tree unchanged after `signal_odds_class` for another class.
- Effort: S.

### A2. A class swap keeps the old class's skills in the slots and blocks the new class's (confirmed, high)
- Where: sim.gd:32 (`skill_slots` is global), 1078 (`RUNNER_KEYS` has no skill_slots or skill_auto), 1081-1112
  (`set_class`), 2998-3001 (auto-slot on learning), skill_picker.gd:84, 109, 152-158.
- What: after a swap the three slots still hold the last class's ids. `skill_known` is false for them, so they're
  dead. Learning a skill only auto-slots into an empty `""` slot, so nothing goes in. The picker lists only the
  current class's skills, counts the stale ids as "3 of 3 picked", and `_press` returns when there's no free slot.
  With three skills slotted on the Poacher, a fresh Paramedic can't slot any. Only "Wear" on a saved kit clears them.
- Why it matters: this hits the playtest directly. Classes open through the campaign, so every player swaps.
- Change: add `skill_slots` and `skill_auto` to the runner's packed fields (`_runner_out`/`_runner_in`/`_new_runner`).
  As a safety net, clear any slot whose id isn't `skill_known` on swap, load and death.
- Effort: S.

### A3. The Issuer's Revolver re-lands the whole tick's damage once per kill (confirmed)
- Where: sim.gd:7430 (`last_hit = hp_before - target_hp`), 7486-7493.
- What: `last_hit` is the whole tick: every type, the spread multiplier (×crowd), the dots and any skill hit. It's
  subtracted again after every kill inside the while loop, so one tick that kills one man chain-wipes the gang. The
  breakdown counts `min(last_hit, t.hp)` while the full amount is dealt. `dealt_by` books it as physical whatever the
  type.
- Why it matters: on any spread build (the Weed Burner is most of the reads) the unique deletes gangs. It's a
  pinnacle drop, so it lands right where the endgame needs a check.
- Change: re-land the single-target killing hit (the `single` landed on the man who died, before the crowd
  multiplier), capped at one man's HP per hop. Book it to the hit's own type.
- Effort: S.

### A4. Floored and Flattened switch off the whole gang's fire, not one man's (confirmed)
- Where: sim.gd:7440-7441 and 7665-7667 (Floored: `f = 0.0` for 1 s after any kill while you deal any physical);
  7470-7471 and 7662-7664 (Flattened: ×0.5 on all incoming for 2 s).
- What: the words are "a staggered one loses a second of fire" and "the next of them fire at half". The code applies
  it to every man on you. Almost every build deals some physical (the share left after conversion). A build that kills
  a man every second or faster therefore takes no gun fire at all.
- Why it matters: this likely feeds the "deaths one in 1,200-8,500" red, and it makes Knuckles' notable a safety
  keystone.
- Change: scale by one man's share: `f *= 1 - (1/on_you)` for Floored, `1 - 0.5/on_you` for Flattened. Move both
  figures into Data.FX.
- Effort: S.

### A5. Clean kills sits on Capacitor's `elif` and double-counts the first-shot bonus (confirmed)
- Where: sim.gd:7306-7309.
- What: `if fresh and has_node("capacitor") ... elif combo_on("clean_kills")`. With Capacitor trained, Clean kills
  never applies to the first man. Without it, on a fresh target `headshot` already holds the first bonus (7295) and
  then gets `first_bonus` added again.
- Change: make it its own `if`. Add `first_bonus` only when `not m["fresh"]`.
- Effort: S. (Combos are off in the balance read, so this only shows in play.)

### A6. The Issuer's printed men aren't kills to anything but the counter (confirmed)
- Where: sim.gd:7135-7144.
- What: a printed man down adds to `m["kills"]` but never runs `_kill` or `_skills_on_kill`. No life on kill (the
  Ladle, Keeper's gun, cap_iron), no Kickback energy, no Jackpot, no Drilled stack, no XP, no drop.
- Why it matters: the Issuer is the "spread" check, but against him he also turns off every sustain-on-kill build,
  which isn't the stated check. The Issuer's own Revolver does nothing in his fight either, because the boss branch
  breaks out before it.
- Change: call a light `_kill_effects(m)` (heals, energy, combos; no drops) per printed man down.
- Effort: S.

### A7. Skills' hits ignore the target's resists and shock and include your dots (confirmed)
- Where: sim.gd:10453 (Gin trap), 10613 (Execute on a head), 10618 (`hit_now`), 10797-10811 (`_skill_damage`).
- What: skill damage is `damage_total() × mult`. `damage_total` is the pre-resist hits plus the dots' steady burn
  (`damage_split`). `_skill_damage` never applies the crew's resist to its `ty`, nor the shock multiplier. Lob one
  in (10703) does apply resist, so the skills disagree with each other.
- Why it matters: at depth, crews resist up to 70% (RESIST_ENEMY_CAP). Skills then skip the game's main check
  (pillar 2), and a dot build's skill hits ride its burn figure.
- Change: use `damage_rate(t, shocked)` (or the hit part of `damage_split(res)`) as the base, and cut `ty` by their
  resist.
- Effort: S, then a read.

### A8. The Arsonist's Rig doesn't grow with level (confirmed)
- Where: sim.gd:7766. `single = 80.0 × increased × more × ...` has no `fight_grow()`, while grenades (7798) and Lob
  (10703) do.
- Why it matters: a depth-14 chase unique deals campaign-sized damage in the endgame.
- Change: `× fight_grow()`, and move the 80 to Data.FX.
- Effort: S.

### A9. Loot quantity is counted twice on a search (likely; check intent)
- Where: sim.gd:8320-8322 (`thin_after` × (1 + loot_bonus): more searches) and 8466-8469 (each search also finds
  +loot_bonus).
- What: +25% quantity gives about 1.25 × 1.25 = 1.56 times the finds on a site picked clean. The "Quantity honest"
  gate reads finds per search (1.23), so it can't see the extra searches.
- Change: keep one of the two. Or keep both and measure the gate per run. Say which is meant in the doc.
- Effort: S.

### A10. The fight's outcome depends on the frame rate and the tick length (confirmed, M)
- Where: sim.gd:6686 (a tick is up to 1 s; the shell ticks once a frame at `delta × speed`), 7292 and 7524 (the
  ±25% swing rolled per tick), 10464-10476 (at most one skill a tick), 6528 (`DRY_STEP` 2 s for the odds).
- What: at 60 fps the swing averages out within a second. The bot (1 s ticks) and the odds' dry runs (2 s) see much
  bigger swings. The bot can fire at most one skill a second and the dry runs one every two seconds. A player at 60
  fps fires as fast as energy allows.
- Why it matters: the odds the player sees and the bot's balance read are a harsher, skill-starved fight than the
  one played. That's part of why "100% odds, no deaths" sits next to Matt's 8% wounds, and why Not today and the
  skill-heavy builds read weaker than they are.
- Change: roll the swing once per second of fight (keep the roll in `m` and refresh it when `m.elapsed` crosses a
  second), or scale its width by sqrt(dt). Let `_skills_tick` fire up to `ceil(dt / 0.25)` skills a tick.
- Effort: M (a read afterwards).

### A11. The Registrar's red tape is close to a non-check (design-level bug)
- Where: sim.gd:7085-7094, data.gd:3303-3305.
- What: one slot is sealed 5 s in every 12. With none slotted, gun damage is cut 30% for 5 s in 12, about −12.5% on
  average. A three-skill build loses one of three for 40% of the fight.
- Change: seal two slots, or seal the most-used skill (`m.sk_uses`) for the whole window. Make red tape −60%.
- Effort: S.

### A12. Smaller mismatches (confirmed, each S)
- `incoming_shares` (919) uses `mitigation()` while the fire itself uses `_mitigation_under(t)` (847). Under Pawned,
  the breakdown's "what hit you" shares are off.
- Hit and run pays XP by `FX["node/hit_and_run.kill_pay"]` (7872) but cash and drop chance by a literal 1.5 (7880).
- Jump Leads adds `FX["rule/jump_leads"]` to shock but a literal `0.33` to the total (591-593). Change the FX and
  the conversion goes over 1.
- `dot_seconds` (661-662) doubles fire and poison with `FX["set/carpet.bleed_s"]`: the Carpet set's key on Lit and
  Dosed.
- Workbench (2012): "one Bench job a day" is `int(elapsed / 86400)`, one free job per 24 hours of play. Over a
  30-hour endgame that's one or two crafts: a dead notable. Make it one per run or per in-game day (`hour_of_day`).
- The balance summary prints "faint 0 of 0 (-100%)" (gate P6): a 0/0 shown as -100%. That's in the harness's
  formatting.

---

## B. Improvements: progression, the endgame stall, sinks

### B1. The endgame stall is structural: crews compound and nothing on the player's side does (most important)
- Where: data.gd:1451 (CURVE grow 0.12 a level to 50), 1452-1453 (0.07 past 50), 1538 (ILVL_GROW 0.05 from
  level 20), 1495-1499 (paragon +2% damage and +2% HP a point, added), 2405/2410 + sim.gd:2033 (the Bench's bump
  capped at base tier +20), sim.gd:2016 (no Bench job on a unique or set piece).
- What: between levels 20 and 50 the crews' HP and fire each grow about 6.7% a level faster than gear. That's about
  7 times on each axis by 50. Past 50 the gap is about 2% a level on each axis, still compounding. vision.md says
  "paragon, the Bench and the right class close it", but paragon adds (linear in points, and points come
  logarithmically as their cost grows 5% a level), and the Bench stops at +20 item levels and never touches uniques.
  The bot wears the Weed Burner or the Butcher's Steel to hour 32 at the item level it dropped at.
- Why it matters: this is why the reach climbs to about hour 8 and then stands 11-26 h on every build (P5), and why
  tuning the curve flips between a runaway (ILVL_GROW 0.07 ran the reach to 221) and a wall. A constant compounding
  ratio can only do one or the other.
- Change: give the player a compounding source that is paid for. The climb's pace is then the price, and the piles
  get spent (B2). The cheapest version is below; none of it changes the curve itself.
  1. "Temper" at the Bench: the bump goes past the cap, one item level at a time, on any piece including uniques
     (not mythics). Its price grows geometrically past the cap, e.g. `scrap × 1.12^(levels over)` plus cash ×
     inflation. The reach then climbs as fast as scrap and tins come in. Pick the price growth so a temper costs
     roughly one run's income at the reach.
  2. Paragon compounding: `pow(1.02, pts)` in place of `1 + 0.02 × pts`, so the board grows at its stated rate
     forever (CLAUDE.md: "a balance change sets the pace of the climb, never a ceiling").
- Effort: M (the craft exists), then one read. It changes numbers, so it belongs before the pass by the house rule.

### B2. Cash and scrap have no sink that scales (gates 14 and 15 red)
- Where: sim.gd:2036 (Bench prices linear in item level × rarity), items.gd:541 (an item's `value` = base ×
  rarity, never item level), sim.gd:2096 (`scrap_of` = value / 24), 3549 (insurance by kit value × depth),
  data.gd:2422-2426 (Build column prices flat), 97-99 (Yard ranks ×1.5 a rank but each rank adds a linear bonus).
- What: income grows with level (kill cash 5% a level, ×inflation, plus mint and contracts) while every price is flat
  or linear. Item value ignores item level, so a level-70 epic sells, scraps and insures like a level-20 one.
- Change: (a) B1's temper is the main sink. (b) Make `value` grow with `Items.grow(ilvl)`, so the Fence, scrap,
  insurance and contract floors keep their meaning. (c) Let scrap pay for Bench jobs (rerolls, tempering), not only
  the Build column.
- Effort: (a) M, (b) S, (c) S.

### B3. One unique decides every build: the Weed Burner (pillar 1)
- Where: data.gd:822-823; sim.gd:598-602 (converts everything to fire), 7374-7375 (fire hits everyone on you); "uses
  no rounds".
- What: it's the primary on 11 of the 24 end kits, including Paramedic as frost and as shock, Recruit as physical,
  Doorman as physical and Scrapper as shock. Each of those then deals no damage of its own element. The build-parity
  red (the Paramedic's two and the frost Poacher under half the best) is partly builds whose element tree is switched
  off by their gun.
- Change: no rounds plus all fire plus spread is three rules. Drop "uses no rounds", or limit the spread to
  burning men, or make it "fire spreads" only (keeping the conversion). Then the bot's choice of gun reflects the
  build. Also check the bot's pick (`_elem_share`): an element build shouldn't wear a weapon that zeroes its element.
- Effort: S (data), then a read.

### B4. Risk is missing for the bot, and it plays an over-levelled campaign
- Where: gates P1-P3, 4, 16; data.gd:3328 (OVER_LEVEL_FREE 5), bot.gd:11 (PUSH 0.88), sim.gd:6530 (BAIL 0.25).
- What: the bot reaches each site 4-8 levels over its gear and enters at 100% odds. A10 makes its odds pessimistic
  on top of that.
- Change: this needs no tuning before the playtest (the house rule on bot timings). Two structural levers for after
  it: OVER_LEVEL_FREE 5 → 2 to 3, so levels track gear in the campaign; and fix A10 so the odds the bot and the player
  read are the real fight's.
- Effort: S each.

### B5. Staying for more is never worth it (gate 11 never reached)
- Where: sim.gd:6751-6788 (gangs after the clear), gate 11.
- What: no build ever met a third gang. Each gang after the clear costs clock and risk, and nothing grows to pay for
  it. The extraction choice (Tarkov's) never comes up.
- Change: a stacking "greed" bonus per gang beaten after the clear, e.g. +10% quality and +5% quantity a gang for the
  rest of the run, shown on the run screen. `loot_per_lot` already exists as an affix (1010); make a baseline version.
- Effort: S.

### B6. Faint signals have no reason to exist for the bot (P6: 0 of 0)
- Where: data.gd:3209 (Faint: -7 to -2 under the reach, two codes, no extras), bot.gd:510-558 (always three
  papers).
- Change: either drop Faint, or give it a job: it always brings its papers back +1, or it rolls a material
  guaranteed. Then one-paper signals turn papers into papers and materials, and that's a decision.
- Effort: S.

### B7. Losing an at-reach signal gives nothing, so the bot won't run one under 88%
- Where: sim.gd:6141-6148 (papers home only on a win); bot.gd:563-580.
- Change: on a loss at or over the reach, return one paper, or count the attempt toward a "pressure" meter that
  makes the next at-reach signal a level easier. That's cheap fail-forward, and the climb no longer depends only on
  the PUSH threshold.
- Effort: S.

### B8. Not today never matters for the bot or the odds
- Where: sim.gd:852 (under 25% HP), 6530 (BAIL 0.25). status.md notes this already.
- Change: make it under 35%, or keep it and accept that the balance read is blind to it. Same for Code blue.
- Effort: S.

### B9. Paragon's find and tins rows feed currencies that already pile
- Where: data.gd:1498-1499.
- Change: once B1 and B2 are in, a tins point buys tempering; until then, put the two rows behind the damage and HP
  rows, or merge them.
- Effort: S.

---

## C. Design ideas, cheap given what exists

1. **Tempering (D4's masterworking)**: B1. The Bench and the bump are already built; it's a cap and a price.
   Effort M.
2. **A ladder record**: the best reach per class, the fastest pinnacle kill, the deepest signal per site in the
   collection (Diablo's rift ladder). Every figure is already in the chronicle. No power. Effort S.
3. **Uber pinnacles**: a pinnacle entry that consumes key items plus a cash fee scaled by reach, for a second tier
   of the three mechanics (shield 50% and a 4 s window, two seals, prints every 5 s). Repeatable, a sink, and it
   uses `key_items`. Effort S-M.
4. **A Fence commission at the reach**: the gamble at the reach's level for its kind, priced at ×N runs' takings
   (sim.gd gamble functions; today it's capped at the drops' level). Cash turns into a targeted at-reach piece.
   Effort S.
5. **Greed after the clear**: B5. Effort S.
6. **Signal modifiers that bite back** (PoE map mods): codes already exist. Add two endgame-only codes that raise the
   pay a lot and remove a crutch (no Guard, no regen), so a finished build has a reason to change kit. Effort S
   (data).
7. **Death that costs at the reach**: once item value scales (B2b), insurance is a real choice again, and the risk
   pillar comes back without changing the fight. Effort S.

---

## D. Code health that touches the game

### D1. The fight tick rebuilds lookups dozens of times a tick (performance, the fans)
- Where: sim.gd:2590 (`_nodes_for` hashes `[tree, cls, cap]` on every `has_node`/`tree_sum`), 3290 (`has_rule`
  builds an array of the worn rules and compares it on every call), 391-407 (`dps()` unmemoised in the shell: the
  memo is only on in dry runs or with `fast_memo`), 7344, 7440, 7470 (`type_dps()` several times a tick).
- Measured: the balance read's "Where the wall went" table shows about 2-3.5 ms of sim time per real tick with the
  memo on. The shell ticks once a frame with the memo off.
- Change: a `kit_version` counter, bumped wherever the equipped kit, the tree, the rig or the stash's rules change,
  keys one per-tick cache: the rules, the node effects, dps, type_dps, pace and contact. It replaces the hashes and
  key arrays.
- Effort: M.

### D2. Three copies of Bleed out's ×1.5 and other formulas outside Data.FX
- Where: sim.gd:723, 7389, 7814 (literal 1.5) against 7370 (`FX["node/cap_bleed_out"]`). Others in the fight: 7331
  (Clocked 1.1), 7335 (Last orders 1.4), 7337 (Bin lid 0.8), 7341-7342 (Jab 1.2), 7366 (Brittle 1.3), 637 (`_more`
  1.4), 685 and 691 (0.4), 847 (Blast burns 1.1), 7720 (Worst first 1.5), 7834 (Overtime 2.0), 10799 (1.25), 10805
  (0.3). About 49 literals sit beside effect checks.
- Why it matters: Data.FX is the balance pass's single place to tune. These literals move on nobody's word, and the
  Bleed out cap drifts from its damage the first time FX changes.
- Change: move them to FX. The existing fingerprint test catches drift.
- Effort: S-M.

### D3. Notables found by tree index
- Where: sim.gd:661, 685, 691 (`tree.has("Petrol/3")`, `"The cold/3"`, `"Live/3"`, `"The Rat Man/3"`, `"Blades/3"`).
- What: these depend on the node's position in ELEMENT_TREES_SRC and skip `_active`/`node_active`. One more node
  inserted above Lit and burns stop lasting twice as long, without an error.
- Change: give the five notables effects (`fire_long`, `chill_deep`, `shock_deep`, ...) and read them through
  `has_node`.
- Effort: S.

### D4. `_fight` (322 lines) and `load_dict` (307) are the two places bugs hide
- Where: sim.gd:7286, 11240.
- Change: split `_fight` into `_your_hit`, `_kills`, `_their_fire` (the boundaries are already comment blocks). Cut
  `load_dict`'s pre-SAVE_VERSION migrations (`_shift_sites`, `_rename_old`, the pre-13-Oct room logic,
  tree_v): CLAUDE.md says old saves get the incompatible-save warning, so that code is dead weight.
- Effort: M (the load cut is S).

### D5. The runner's state is three hand-kept lists
- Where: sim.gd:1078 (`RUNNER_KEYS`), 1118 (`_runner_out`), 1124 (`_runner_in`), 1144 (`_new_runner`), 11154
  (`_state`).
- What: A1 and A2 both come from a field missed in one of them.
- Change: one table of runner fields, with the pack, unpack, new and save all reading it, and a smoke check that
  every field survives a swap and back.
- Effort: S-M.

---

## Order I'd take them in

1. A1 and A2 before the playtest: the swap and the Radio will hit Matt. Both S, with a smoke check each.
2. A3-A8 and A12 as one fixes batch: all S, each with its check.
3. Then the design calls for Matt, in this order: B1 (tempering and compounding paragon), B3 (the Weed Burner), B2
   (value by item level), B5 (greed). Each changes numbers, so they go in before the balance pass.
4. A10 (fight tick) and D1 (per-tick cache) together, since both touch the tick. Then one read.
5. D2-D5 as housekeeping between passes.
