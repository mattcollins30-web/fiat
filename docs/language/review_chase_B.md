# Language review B: the endgame chase's new words

Reviewer B, new-player view. Read against style guide v3, the approval summary, skills.md §11, the five chase
screenshots plus stats_fight.png and web_mid_c.png, and the code in rules_panel, armoury, stats_room, barracks,
workshop, skill_bar, web_key and sim. No game file edited.

**The biggest problems:**
1. A **Keep** rule doesn't keep anything safe. Sell when home and the Yard's Bins still take the item.
2. **Put it on** spends a pinnacle drop and the pattern, and the pattern can't come off. Nothing on screen says so.
3. Two banned words show on screen: **loadout** and **node** (both are off screen per skills.md §11, call 1), and
   **depth** is all over the collection (call 1 of v2).
4. **"Wants a %s"** prints "Wants a the grid's key" and "Wants a ledger seals". It also lower-cases a name.
5. **"the %s's pattern"** prints "the The Lineman's Tool Bag's pattern".

Box widths come from the code: the rules head buttons are 150/170 px, a rule row's act button 130, a loadout card's
buttons about 125, Break 290, Put 200, Retrain 260, the fight button 150 and the collection button 190.

---

## 1. The loot filter (words.gd LOOT_RULES, rules_panel.gd, armoury.gd)

| Key | Current | Suggestion | Why |
|---|---|---|---|
| `note` | Scrap: scrapped for its scrap as it comes in. Highlight: an amber edge in the stash. Nothing fits: kept, as now. | Scrap: turned to scrap on the way in; it never reaches the stash. Highlight: an amber edge. No rule fits: kept. | The current line explains scrap with "scrap" and hides that the item is gone. "as now" means nothing to a new player. At about 105 characters it stays on one line, as now. |
| `keep` (behaviour) | Keep | Keep. Code: make Keep and Highlight items exempt from `is_junk()` and `_bin_commons()`. If not, say so in the note: "Keep: stashed as usual; Sell when home still applies" | sim.gd L9930 and L8714: a kept or highlighted piece can still be sold by Sell when home, and the Bins run before the rules. As it stands, "Keep" promises something the code doesn't do. |
| `title` | The rules | Loot rules | It should match the button that opens it. "The rules" reads as the game's rules. |
| `sub` | applied when a run comes home · the first that fits wins | checked top down when a run comes home · the first that fits wins | The order is the whole mechanic, and ↑ only makes sense once the player knows rules are read top down. |
| `on` / `off` | Rules on / Rules off | Rules: on / Rules: off | It's a state toggle, so use the Kit's own pattern beside it ("Sell when home: off", "Keep: upgrades"). Without the colon "Rules off" reads as the action it performs. 150 px fits. |
| `up` (button, no tooltip) | ↑ | ↑, with the tooltip "Move up: checked before the one above" | A bare arrow, and the reason to press it (order matters) isn't on it. |
| row act button (no tooltip) | Keep / Highlight / Scrap | Same words, with the tooltip "Press to change: keep, highlight, scrap" | A press on the row cycles the action straight to Scrap with no hint, so a misclick quietly turns on scrapping. |
| `edit_head` | A rule (shows as "A rule 3") | Rule | The code builds "%s %d", so "Rule 3". "A rule 3" isn't English. |
| `full` | Eight rules: the most | 8 rules at most | Figures in mechanics (guide §4). |
| `from` / `to` | From %s / To %s | From %s ▾ / To %s ▾ | They cycle on each press. The house marks a cycling button with ▾. 200 px fits "To Legendary ▾". |
| `gun` | Gun | Weapon | The row offers Melee and Improvised. "Gun: Melee" contradicts itself (approval Q13, the same fault on the Workshop tab). |
| `kinds` | Uniques, sets, mythics | Uniques, set pieces, mythics | It should match `special` ("Any unique, set piece or mythic"). A "set" is the whole set, not the piece. |
| Scrap chip when Kind = Uniques (disabled, no tooltip) | Scrap | Scrap, with the tooltip "Never scrapped by a rule" | The greyed button is the right place for "uniques are safe", and it frees the note line. |
| `tier` | a T%d affix | a T%d+ affix (keep "a T5 affix" for 5) | The chip says "T3+" and the rule matches T3 or better, but the row reads "a T3 affix". |
| `plain` | Plain gear | Everything else | Kind "any" means anything not unique, set or mythic. "Plain" sounds like Common, and the Radio already uses "plainest" for a rarity sense. Fits as a chip. |
| `button` | Loot rules · %d | Loot rules · %d on | The figure counts only the rules that are switched on. With 5 rules and 1 off it says 4. Fits 200 px. |
| `scrapped` (log) | The rules scrapped %d thing%s as they came in: %d scrap | Loot rules scrapped %d thing%s on the way in: +%d scrap | Name the feature, as the button does. "+" marks a gain, as the Bins' log line beside it should too. |
| Slot chips (no tooltip) | Body / Bags | Body (tooltip "Helmet, armour, charm") / Bags (tooltip "Rig, backpack") | "Body" takes in the charm and helmet (sim.gd L10014). No new player would guess that. |

## 2. Loadouts (LOADOUTS, armoury.gd)

| Key | Current | Suggestion | Why |
|---|---|---|---|
| `name` | Loadout %d | Kit %d | "Loadout" is banned (glossary: kit, not loadout; skills.md §11: "loadout stays off screen"). The room is The Kit. |
| `head` | Loadouts | Saved kits (or delete it: nothing reads it) | The same ban applies. No code reads this key. |
| `worn` (log) | Loadout %d on | Kit %d on | Same ban. |
| `worn_short` (log) | Loadout %d on, but not: %s | Kit %d on; missing: %s | "on, but not:" is hard to parse. Also, sim.gd L11722 `.to_lower()`s rig bases, which the guide forbids (§2: never lower-case an item base in code). |
| `save` (behaviour) | Save worn | Save worn. On a card that isn't empty, the first press arms "Again: replace it" (the Workshop's break_sure pattern) | A press overwrites a saved kit, rig and skills with no warning. It's the one press here that loses something. "Again: replace it" fits about 125 px at CELL_TEXT. |
| `wear` (no tooltip) | Wear | Wear, with the tooltip "Puts on its gear, tops up its rig, slots its skills" | Wear also swaps your skills and pulls rounds and meds from the stash. That isn't obvious from "Wear". |
| `ready` | all in the stash | ready to wear | It also shows when some pieces are already worn (sim.gd L11681), so "all in the stash" can be untrue. |
| `short` | %s gone | gone: %s | A run of item names then "gone" reads badly ("Rescue axe, Bomb suit gone"). Put the state first. |

## 3. Build codes (BUILD, barracks.gd)

| Key | Current | Suggestion | Why |
|---|---|---|---|
| `title` | A build: %s · %d nodes · %d skills | A %s build · %d perks · %d skills | "node" is banned (glossary: perk). |
| `plan` | Reset for %s, then %d of %d nodes trained | Resets every perk for %s, then trains %d of %d | The current text hides that a reset wipes the whole class region. "trained" reads as done, but this is a plan. Also "node". |
| `plan_free` | %d of %d nodes trained, no reset | Trains %d of %d perks, no reset | Tense and "node". |
| `missed` | short of points for %d | %d need more points | Hard to parse as it stands. Lead with the figure. |
| `done` (log) | Retrained: %d of %d nodes | Retrained: %d of %d perks | "node". |
| `short` | The reset wants %s tins | The reset costs %s | The code passes a bare int (sim.gd L11848), so it shows "12000 tins". Pass `Fmt.money(cost)` for "12,000 tins" (guide §4: thousands with a comma). Code change. |
| `class` | A %s's build: change to them first | A %s build: pick that class in Training first | "change to them" doesn't say where or how. "them" refers to a class. |
| `out` (also PATTERNS `out`) | The runner is out | Not while the runner's out on a run | "out" alone could mean dead, sacked or away. The line should also say it's a block. |
| `go` | Retrain into it | Retrain | Shorter, and it says the same. Keep the current text if the plan line is ever hidden. Low priority. |

## 4. Patterns (PATTERNS, workshop.gd, sim.gd)

| Key | Current | Suggestion | Why |
|---|---|---|---|
| `wants` | Wants a %s | Short of: %s (and drop `.to_lower()` at sim.gd L7017 and workshop.gd cost chip) | It prints "Wants a the grid's key" and "Wants a ledger seals". The lower-casing also breaks the Grid's name (guide §2). The cost chip "1 the grid's key" has the same fault. |
| `broken` (log) | Broken down: the %s's pattern is kept at the Workshop | Broken down: %s. Its pattern is kept at the Workshop. | Every chase unique starts with "The", so it reads "the The Lineman's Tool Bag's pattern". |
| `put_on` (log) | The %s's pattern put on the %s | Put on %s: the pattern of %s (swap the arguments in code) | Same double "The", and a double possessive ("Tool Bag's pattern"). |
| `gone` | gone for good | The unique goes for good; its power stays here as one pattern | It sits beside the Break button. Say what's lost and what's kept before the first press. The 44 px label wraps to two lines. |
| `break` | Break it down · free | Break it down | "free" frames the press as costless, but the unique is destroyed. The cost is the point. |
| new `put_note` (the why label when nothing blocks) | (empty) | Uses the pattern and the costs above; it can't come off | apply_pattern spends a pinnacle drop, materials, tins and the pattern. A patterned piece can't be broken again (`can_break` needs `unique`). That's the second big hidden consequence. |
| `put_head` | 2 · Put it on a rare of the same slot | 2 · Put it on a Rare or better, same slot | "or better" was dropped, and the code takes Epic and Legendary (`too_plain`). A rarity keeps its capital (§2). |
| `too_plain` | Rare or better takes a pattern | Only Rare or better takes a pattern | As written it reads as a rule statement, not as why this pick is refused. |
| `pick_rare` | Pick a rare or better of its slot | Pick a Rare or better, same slot | The rarity's capital, and the same words as the head. |
| `not_unique` | Only a unique has a pattern | Only a unique has a pattern; a mythic has none | A mythic is a unique to the player (the collection counts them together), but can_break refuses it with this line. |
| `not_stashed` | In the stash first | Take it off first: only a stashed unique breaks | Too terse: a worn unique gives this, and the player has to work out why. |
| `has_one` | It has a power of its own | It has a power already: one a piece | It says why: one rule per item. |
| `kept_note` | One use each. They sit here, not in the stash. | Delete it, or show it under PATTERNS KEPT | Nothing reads it. The fact is useful, though: the one-use rule appears nowhere else on screen. |

## 5. The fight's breakdown (FIGHT_*, BREAKDOWN, stats_room.gd)

| Key | Current | Suggestion | Why |
|---|---|---|---|
| `FIGHT_HEADS[1]` | A second | dmg/s | The guide's form for figures (§4). "A second" under a number reads as a time. |
| `FIGHT_HEADS[2]` | Took | Damage taken | A lone "Took" doesn't say took what. 160 px fits. |
| `FIGHT_HEADS[3]` | Stopped | Damage stopped | Beside "Took 0" a bare "Stopped 91%" is a puzzle. It's the armour's share. |
| `FIGHT_HEADS[4]` | Meds | Meds used | It's a count of uses, not of meds held. |
| `FIGHT_SUB` | the last run · %s fighting · %d gangs, %d kills | the last run · %s fighting · %d gangs after the clear, %d kills | `patrols` counts only the gangs after the clear, so the screenshot reads "0 gangs, 5 kills", which looks like a contradiction. The UI.fit fallback already covers a narrow box. |
| "What hit you" rows (`ty.capitalize()`, stats_room.gd L610) | Bleed / Physical / Frost … | Bleeding / Burning / Poison / Chill / Shock / Physical, from a words table | The left column says "Bleeding" and the right "Bleed". Frost on the runner is a *chill* (skills.md §11). Code: map the types through Words instead of capitalize(). |
| `BREAKDOWN["rule:issuers_revolver"]` | The Issuer's Revolver, printed | Repeat hits · The Issuer's Revolver | It reads as the revolver itself printed. The fit fallback (slice 0) keeps "Repeat hits". See the Revolver's words below. |
| skill rows (stats_room.gd L619, hard-coded) | 1 use · 0 | 1 use · 0 dmg, or no figure when 0 | An unlabelled 0 beside Look lively reads as a fault. Most utility skills deal none. |

## 6. The pinnacles on screen (ORDER_CHIPS, SKILL_SEALED, skill_bar.gd)

| Key | Current | Suggestion | Why |
|---|---|---|---|
| `taped` | Red tape %d s | Red tape · −30% damage · %d s | The chip is the only place the player meets red tape, and it doesn't say what it does (sim.gd L7329: your damage −30%). |
| `printed` | Printed · %d on you | %d printed on you | Chips lead with the number (§1). |
| `shield` | Shielded · %d s to break it | Shield · break it in %d s | The shorter form keeps the clock. Better still, add a tooltip: "Break it in time and he's stunned 3 s; miss it and it fills again". |
| `SKILL_SEALED` tooltip (skill_bar.gd L183) | (none: the normal tooltip shows) | First line while sealed: "Sealed by the Registrar: can't fire for %d s" | The glossary lists *sealed* among the words that need a one-line definition where they first show. This is where. |

## 7. The collection (COLLECTION, stats_room.gd)

| Key | Current | Suggestion | Why |
|---|---|---|---|
| `sites` | Sites to depth 100 | Sites to the last mark | Depth is banned on screen (call 1). The code needs no change for this one. |
| `sites_head` | Sites · a mark at 10, 25, 50, 75 and 100 deep | Sites · the highest level won, a mark at each step | Same ban. |
| `depth` | depth %d | level %d (fed `lv_at(i, d)`) | Same ban. Level is the runner's scale (sim.gd L4919). Code change: stats_room.gd L744. |
| `sub` | every runner's, kept for the crew | every runner's, for the record · no power in it | *Crew* is a faction (glossary). The brief says the collection gives no power, and a new player will expect one. |
| `grid_head` | Uniques · %d of %d · the found ones in colour | Uniques · found in colour, the rest by slot | The tile above already shows "38 of 52" (§5, say it once). The new text says what "? · Charm" means. |
| `order` | The order beaten | The order's three beaten (tooltip: "The Lineman, the Registrar, the Issuer") | "The order" is only named in Kev's lines. On a tile it needs anchoring. |
| `classes` | Classes to 50 | Classes to level 50 | "to 50" could mean anything. Fits the 320 px tile. |

## 8. The Pitch circle (web_key.gd)

| Key | Current | Suggestion | Why |
|---|---|---|---|
| `ELEMENTS_NOTE` | A Pitch point opens one | Each opens with a Pitch point | "opens one" sounds like a point picks one element for you. Also drawn at 11 px: fine. Since 31 Oct (a class's own two open free): "Own two free; others a Pitch point" (178 of its 178 px). |
| `ELEMENT_SHUT` | shut | shut | Keep it. It reads well with the note. |

## 9. Uniques, notables, joints (data_new.txt)

| Line | Current | Suggestion | Why |
|---|---|---|---|
| Issuer's Revolver `words` | A kill prints the killing hit again on the next man; a printed kill prints again | A kill lands the killing hit again on the next man; a kill from that hit does the same | "Print" is flavour in a mechanics line, and it clashes with the Issuer's chip, where "printed" means a new man. |
| Issuer's Revolver `short` | A kill's hit prints on the next | A kill's hit lands again on the next | Same reason. |
| Lineman's Tool Bag `words` | … shocked men take 20% more from your skills | … shocked men take 20% more damage from your skills | "20% more" of what. |
| Paddles / Paramedic's paddles | two Paramedic nodes on the same joint (paramedic_shock) | Rename one: for example "Defib" for the Shifts notable | The approval table's clash rule: two names one word apart in the same class and joint. |
| drifter_bleed joint | Killing a bleeding target: its drop rolls rarity twice, keeping the better | A bleeding man you kill rolls his drop's rarity twice and keeps the better | *target* isn't the game's word (man). Lead with the effect. |
| paramedic_shock joint | Every med you use shocks them for 3 seconds | Every med you use shocks everyone on you for 3 seconds | "them" has no antecedent in a lone line. |
| paramedic_frost joint | Chilled gangs do 30% less damage to you; … | Chilled men do 30% less damage to you; … | The effect is per man. Gang is the group. |
| The second past `words` (×12) | Opens the Doorman's region to your points. One bridge a class. | Opens the Doorman's lanes to your points. Only one bridge per class. | "Region" appears nowhere else on screen, while a class's lanes are named on the web. "One bridge a class" reads as a price. |

---

## Duplicates per screen

- **Collection:** "Uniques found 38 of 52" (tile) and "UNIQUES · 38 OF 52" (grid head). Keep the tile and cut the
  count from the head (row above). Training's ALSO "The mantelpiece · 38 of 52" is the same fact on another screen,
  which is fine.
- **The Kit with the rules panel:** "Loot rules · 4" on the button and five rows with On/Off. Fine once the button
  says "on".
- **Fight panel:** a skill's uses show twice: "Look lively · 1 use" in the sources (src_words appends uses) and
  "1 use · 0" under YOUR SKILLS. Keep it under YOUR SKILLS and drop the suffix from src_words.

## Glossary and style guide notes

- New variants on screen: *loadout* (four keys), *node* (four keys), *depth* (three keys), *crew* for the player's own
  side, *target*, *region*.
- *Printed* now means two things: the Issuer's new men, and the Revolver's repeated hit. Keep it for the Issuer.
- *Scrap* against *bin*: the rules say Scrap and the Kit's button says Bin. Approval Q12 recommended one verb. The
  new strings follow Scrap, which is right.
- *Keep* now names two systems on one screen: the rules' Keep action and the "Keep: upgrades" button, which belongs
  to Sell when home. A new player will take them as linked. They aren't. This is one more reason for the code fix in
  section 1.
- Suggest adding to the guide: a state toggle reads "Thing: state" ("Rules: on"), and a cycling button carries ▾.

## Facts to check

- **Keep doesn't protect** (above). This is a design call for Matt: exempt kept and highlighted pieces from
  Sell when home and the Bins, or say so on screen.
- **Fight time:** stats_fight.png shows "0:01 fighting" for 219,102 damage, so dmg/s is 146,068. The `fight_s`
  counter looks wrong (sim.gd fight_breakdown).
- **Training key:** "The Pitch · the Yard · −4 free" (buildcode.png). `pitch_free()` goes negative and isn't
  clamped, and it prints a hyphen, not "−".
- **Build title against plan:** the title counts every node in the code, Pitch nodes included. The plan's "of"
  leaves them out, so "237 nodes" and "of 237" can differ.
- **Patterned pieces and the rules:** `loot_rule_fits` treats a patterned piece as special, so "Plain gear" rules
  never touch one. Nothing on screen says so. The tooltip on "Uniques, set pieces, mythics" could add "and patterned
  pieces".
- **The flatline combo** carries `rule: "linemans_bag"` in data.gd L1528, the Tool Bag's rule on an Ambulance set
  combo. It may be intended. Worth a look.

## Top 5

1. **Keep must mean kept:** exempt kept and highlighted pieces from Sell when home and the Bins, or say on screen
   that it doesn't. Also rewrite the rules' `note` so Scrap says the item never reaches the stash.
2. **Put it on:** add "Uses the pattern and the costs above; it can't come off", and change `gone` to "The unique goes
   for good; its power stays here as one pattern".
3. **Banned words off screen:** Loadout → Kit, nodes → perks, depth → level (the collection, with the `lv_at` code
   change), crew → "for the record · no power in it".
4. **The broken strings:** "Wants a %s" (prints "Wants a the grid's key"), "the %s's pattern" (prints "the The
   Lineman's…"), "The reset wants %s tins" (no comma), and `.to_lower()` on names and bases.
5. **The pinnacle chips say what they do:** "Red tape · −30% damage · %d s", a tooltip for Sealed, and the Revolver
   should say "lands again", not "prints", so *printed* means only the Issuer's men.
