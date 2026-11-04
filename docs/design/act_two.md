# Act two - the spec (4 Nov 2026)

Why play past the campaign, and signals worth playing. Agreed with Matt on 4 Nov (his calls below; the canvas
https://claude.ai/artifact/W7fdXUELCWNCKdWidiYU5J: the road, a night on the air, the town on the Map). Built in one
release with the playtest's fix round and the skill web version two (docs/design/skill_web.md), for a fresh save.
Every figure here is a first figure: Matt's fresh play sets them, not a bot pass (CLAUDE.md, 2 Nov; Matt, 4 Nov: "on
balance i think we adjust numbers and I play fresh again rather than doing a bot pass").

## Why (Matt, 4 Nov, the 0.12.2 playtest, the Doorman at level 28, 5.7 h)

- "clearing the campaign and just playing the game - why ? why state in the story opener that you have a camp/pitch
  and tins are currency - but why ?"
- "radio signals are just too weak to sustain play - if they were more fun then I would've been willing to grind"
- "part of the friction was setting one up, tuning the codes, running it and being done in 30 secs then having to
  repeat the whole process to go again - think we need to be able to chain them together"
- "the gap between radios opening, rebuilding the town and then getting the county open is too great. XP seems to
  slow at that stage and outside of codes the repeat runs are useless for XP. I also think its too difficult to craft
  what you need, especially trying to get resistances across the board."

His save: the Radio at 3.3 h; Kev's story done at 4.5 h; six rebuilds within 5 minutes of the story's end, then the
mint behind the Grid's key and the Lineman at level 35; 52 signals, a fight's median 57 s against 132 s set-off to
set-off; 389,080 tins with nothing to buy; level 35 about 4 h on at his rate, 45 (the Issuer) about 23 h; a 20-run
repeat at the Barracks paid 978 XP; every Workshop roll random, no resist on his kit.

## Matt's calls

1. The town is the goal, the Issue is the turn: yes.
2. Signals chain - a night on the air - open-ended, something special every fifth link (option C).
3. Tins pay for the town before the Issue (wages, upkeep): yes.
4. The targets "a bit longer": the Radio about 4 h, the town half running and the Lineman about 6 h, the Issue and the
   County about 9 h, level 50 about 15 h ("ok go for it").

## 1. The town as the goal

**Said.** The opener's last line (Kev) names it: the town ran on something - the power, the water, the buses, the
market, the papers, the money; get them running and the Pitch stops being a squat. (Words: the language pass; Matt
records it, docs/voice/recording_list.md.)

**On the Map, always.** A goal line over the drawn Map from the Radio's opening: "The town: N of 6 running" with six
pips, and the next step named with what it still wants ("Next: the market hall · glass 12 of 20 · copper wire 3 of
20") and a button, "Signals that bring them", that opens the Radio filtered to signals dropping those materials. Before
the Radio: "The town: the Radio first" (the line is there from the opener, so the goal is never news).

**Seen.** Each place on the drawn Map: ringed while not built, dashed when it's the next step, lit when running (a
glow, its block lit at night). A running place's card (the Town tab on the Radio, and a tooltip on its pin) says what
it does and what came back with it in a few words ("a face at the switchgear", "water at the Pitch", "a bus that takes
runners further"). Art for the lit places and the faces: a manifest after the slice reads with test art (the house
rule).

**Order.** The six places stay (data.gd REBUILDS) and the road through them is the act:

| Step | Opens | Head | Level (was) |
|---|---|---|---|
| The substation | the Grid | the Lineman: the Grid's key | 30 (35) |
| The pumping station, the bus depot, the market hall | their effects | - | - |
| The library | the Archive | the Registrar: ledger seals | 34 (40) |
| The mint (the Grid's key, ledgers, army kit) | the Mint | the Issuer: the Issue | 38 (45) |

Data.PINNACLES' `level` 30 / 34 / 38; their `over` and `again` keep their shape. The goal line counts a place running
at its first rank.

## 2. Tins pay for the town

- **The build** costs its materials as today plus tins: REBUILD_TINS a place (first figures: 5,000 / 8,000 / 8,000 /
  10,000 / 15,000 / 25,000 in the order above), × REBUILD_GROWTH a rank.
- **Wages**: each running place draws its wage at every run home (the exchange's day, `exchange_day`): first figures
  900 (substation), 800 (pumping), 900 (bus depot), 1,000 (market hall), 1,200 (library), 1,500 (mint) a day, ×
  (1 + 0.25 a rank past the first). Paid from the tins in hand, in the town's order.
- **Unpaid**: a place the tins don't cover stops (its effects off, its pin unlit, "Stopped: unpaid") till a day it's
  paid; the goal line counts only running places. A toast and the Map's line say so. Never debt.
- The Town tab and the Map's panel show the day's bill and how many days the tins in hand cover.
- **After the Issue** the wages and builds are in fiat at the Issuer's rate (the_issue.md: every price reads in fiat).

## 3. A night on the air (the chain)

**Setting off.** A held signal's card gets "Start a night" beside Set off (Set off stays: one signal, home after).
The night starts with that signal; the night's runner is the one out.

**A link** is one signal's fight, as a run is today - its codes, its crew, its level, its drops into the pack.

**The break** between links (the canvas's Night board): the chain strip (links done, the next, the next fifth); the
next link's card - site, level, codes, what it drops, its head if a fifth, the odds to clear as you stand now (HP, meds,
magazines carried); what you carry; the night's haul so far (tins, XP, materials, kit); the night's clock. Three
buttons: **Next link**, **Get out with the haul**, **Tune it** (the Radio's tune / retune / twist on the next link, at
their prices). The break waits for the player; with "Auto: keep going" ticked it goes on by itself while the odds stay
at or over the player's floor (a setting, default 70%).

**The next link**: the next held signal, then one rolled at the reach + 1 at a site the town's next step needs
materials from where one fits (else any open site), its codes set by the tuning rules.

**Carried**: HP, meds, magazines and rounds, the pack, wounds, the wagers taken. No rest, no gate top-up, no Clinic.
Kev's wagers are offered at the break for the next links (playtest item 19's redo).

**The fifth links** (5, 10, 15 ...): in turn - a head away from home (the order's or a campaign head, at the link's
level, his drops), a stash (a room of crates, two finds a search), a fat drop (the link's loot quality ×2, a unique's
chance ×3).

**It ends** when the player gets out at a break (everything home, as a run home: XP, tins, the pack, the reach's
climbs counted link by link), the runner dies (the night's haul and the worn kit lost, as a death), the night's
clock runs out (NIGHT_CLOCK, first figure 20 minutes of fight time: home with the haul at the end of the link), or the
pack is full at a break (home with it).

**The reach** climbs per link won at or past it, as today. A night's XP is the links' XP; a link's XP rises 5% a link
past the first (NIGHT_XP_STEP), so pushing pays.

**Tuning rules** (the Radio, beside the loot rules): codes wanted, codes never taken, wagers accepted (none by
default), the odds floor for "Auto: keep going". Checked top down, the first that fits wins, as the loot rules.

## 4. Signals worth playing

- **The card says what it drops**: each signal rolls a focus - a material (the town's next needs first), a slot, an
  element's resist, or a unique's chance - shown on the card ("Drops: fuses ×3 · a shock resist piece"). The focus
  weights the loot (a resist focus: one find in three carries that resist; a material focus: +2 of it a link).
- **Resists off the air** answer "too difficult to craft resists": a resist focus is the way to them.
- **The run events** (the Vagabond, the threats, the robbed crews) roll on links as on runs.
- **The Vagabond takes the camp's tins** (playtest item 16, Claude's pick): his prices as today, paid from home.

## 5. Crafting: aimed resists

A new Workshop job, **Add a resist**: the element picked, its tier rolled as an affix's; dearer than "Add an affix"
(CRAFT add × 1.5) and only on armour, helmets, gloves and charms. Resist affixes' weight on body pieces up a third
(the affix pool's weights for frost/fire/shock/poison/bleed resist on Helmet, Armour, Gloves).

## 6. The numbers

| | Now | Act two |
|---|---|---|
| The Lineman, the Registrar, the Issuer | 35 / 40 / 45 | 30 / 34 / 38 |
| The County's zones (places) | 50-55, 60-65, 70-75, 80-85 | 40-45, 50-55, 60-65, 70-75 |
| XP_TAPER_END (the scale from level 40) | 8.0 | 4.5 |
| REPEAT_XP | 0.12 / 0.17 / 0.22 / 0.30 | 0.25 / 0.35 / 0.45 / 0.60 (before 1 Nov's halving) |
| The campaign | 3.3 h to the Quartermaster (Matt's play) | unchanged (inside 3-4 h) |

Targets by hand: the Radio about 4 h, the Lineman about 6 h, the Issue and the County about 9 h, level 50 about 15 h.
Matt's fresh play reads them; the figures move after it, not before.

## 7. Not in act two

The County's own content, the paragon board, hardcore, the language rename pass (the road's step 3), the tutorial
(step 4) - each as the road to the friends' playtest has them.

## The build

One release, 0.13.0 (a fresh save, SAVE_VERSION up), in this order, each its own commit with the smoke green:

1. **The fix round**: playtest items 1-28 (status.md's parked list) - the bugs and UI, the odds' items first (9, 13,
   17, 22). Items 16 and 19 land with §3-4; item 2 with the skill web.
2. **The skill web version two** (docs/design/skill_web.md).
3. **Act two**: §6's numbers; §1-2 the town (the goal line, the Map's pins, wages); §3 the chain (the biggest piece:
   the break screen, carried state, the fifth links, the tuning rules); §4 the focus on signals; §5 aimed resists.
4. **Art**: the lit places and the faces, a manifest via `art.flag` once the slice reads with test art.

Smoke for each: the town's goal line and next step; a place unpaid stops and starts again when paid; a chain carries HP,
meds and the pack, ends on each of its four ends, and a death loses the haul; a fifth link brings its special; the
tuning rules pick codes; a signal's focus shows on its card and weights its drops; "Add a resist" adds that element's
resist; the order's heads and the County at their new levels; every new label fits.
