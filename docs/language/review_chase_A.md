# Language review: the endgame chase (reviewer A)

Scope: the new lines in `scripts/sim/words.gd` (lang/words_new.txt) and `scripts/sim/data.gd` (lang/data_new.txt),
checked against style guide v3, the approval summary, skills.md section 11 and the code. No game file was edited.
"Code" in a reason means the text alone can't fix it.

**The short version.** The voice is mostly right. The problems are:
- **Banned glossary words on screen.** *Loadout* is banned outright (glossary; skills.md section 11, call 1) and
  *node* is banned for a perk.
- **Broken output.** Three pattern lines lower-case names in code, or put "the" and "'s" around names that already
  carry them, so they print things like "Wants a the grid's key" and "the The Lineman's Tool Bag's pattern".
- **Depth on screen.** The collection shows depth, which Matt's call 1 took off the screen.
- **Words with two meanings.** *Sealed* (already a Radio term), *print* (the Issuer's men, and the Revolver's
  repeat hit) and bare *code* (Radio codes).
- **Lines that say something the code doesn't do.** Covered in the second half of the report.

---

## 1. Changes

### The fight's breakdown (words.gd: BREAKDOWN, FIGHT_*)

| Key | Current | Suggested | Why |
|---|---|---|---|
| BREAKDOWN dot:fire / dot:bleed | Burning / Bleeding | Fire / Bleed | Inconsistent forms in one list: two are participles, three are nouns (Poison, Shock, Frost). The web's element labels use the nouns ("Petrol · fire", "Blades · bleed"). `_src_tone` matches on these words, so it follows them with no code change. |
| BREAKDOWN rule:issuers_revolver | The Issuer's Revolver, printed | The Issuer's Revolver · repeat hits | Elsewhere *printed* means the Issuer's extra men ("Printed · 3 on you"). The fit falls back to the slice before " · ", which is the unique's name. |
| FIGHT_SUB | the last run · %s fighting · %d gangs, %d kills | %d gangs, %d kills · %s fighting | "The last run" repeats the card the button sits on. The current line has three separators (the guide allows two). Sentence case. Code: reorder the args. Plurals aren't handled ("1 gangs", "1 kills"): code. |
| FIGHT_HEADS[1] | A second | dmg/s | The guide's form for damage a second in figures. "A second" alone, as a head, doesn't say what it measures. |
| FIGHT_HEADS[2] | Took | Taken | Reads as a pair with "Damage". "Took" is a verb with no object. |
| FIGHT_HEADS[4] | Meds | Meds used | The value is a count of meds used. "Meds" alone reads as meds held (the rig). |

### The order's fights (ORDER_CHIPS, SKILL_SEALED)

| Key | Current | Suggested | Why |
|---|---|---|---|
| SKILL_SEALED, ORDER_CHIPS sealed | Sealed / A skill sealed | Pending / A skill pending | Clash: *sealed* is already a Radio term (a Twisted site is "Sealed", and the guide's tooltip list defines it). "Pending" is the Registrar's world. Any dry office word works if Matt prefers another. |
| ORDER_CHIPS taped | Red tape %d s | Red tape · −30% fire %d s | The chip names the effect but not what it does. The code cuts your gun's fire only (sim.gd L7329), not skill hits, so "fire" is the true word. See fact F1 for where the chip shows. |
| ORDER_CHIPS printed | Printed · %d on you | Printed men · %d | `m["printed"]` counts every printed man alive. Only `min(printed, contact)` are on you (sim.gd L7527), so with fog or Chokepoints "on you" overstates. |

### Patterns (PATTERNS)

| Key | Current | Suggested | Why |
|---|---|---|---|
| broken | Broken down: the %s's pattern is kept at the Workshop | %s broken down: its pattern is kept at the Workshop | %s is the unique's full name, and every chase unique starts "The" and most end in "'s". It prints "the The Lineman's Tool Bag's pattern". With the name first, its capital "The" is right. |
| put_on | The %s's pattern put on the %s | Pattern put on the %s: %s's | Same double "The …'s'". Code: swap the args (the item first, then the unique). The output reads "Pattern put on the Assault pack: The Lineman's Tool Bag's". Or, cleaner: "%s now carries %s's pattern". |
| wants | Wants a %s | Wants 1: %s | The code lower-cases a KEY_ITEMS name and puts "a" in front: "Wants a the grid's key", "Wants a ledger seals". Code: drop `.to_lower()` (the guide: never lower-case a name in code). The same bug is in the cost chip, workshop.gd L1356: "1 the grid's key". |
| wants_n | Wants %d %s | Wants %d: %s | The same lower-casing ("Wants 12 army kit"). The same form as `wants`, keeping names as named. |
| wrong_slot | That pattern goes on a %s | That pattern goes on: %s | `str(slot).to_lower()` with "a" gives "a armour". Code: drop `.to_lower()`. |
| has_one | It has a power of its own | Only a plain piece takes a pattern | Shown for a unique, a set piece, a mythic or a patterned piece. "Power" is a banned skill synonym, and "it has one" doesn't tell you what to pick instead. "Plain piece" matches the loot rules' kind (below). |
| put_head | 2 · Put it on a rare of the same slot | 2 · Put it on a Rare or better, same slot | It drops "or better", which `too_plain` and `pick_rare` both say. The capital is the guide's rule for naming a rarity. |
| pick_rare | Pick a rare or better of its slot | Pick a Rare or better of its slot | Caps: names the rarity. |
| too_plain | Rare or better takes a pattern | Only Rare or better takes a pattern | Ambiguous: as written it reads as a rule about Rares, not why this piece is refused. |
| break_sure | Again: break it for good | Press again: it's gone for good | "Again:" reads as a label. The label beside the button already says "gone for good", so one says it, the other tells you what to do. |
| kept_note | One use each. They sit here, not in the stash. | (show it, under PATTERNS KEPT) | Never read (no `PATTERNS["kept_note"]` anywhere). Nothing else on screen says a pattern is one use. Code: draw it under `kept_head`. |

### The loot filter (LOOT_RULES)

| Key | Current | Suggested | Why |
|---|---|---|---|
| title | The rules | Loot rules | The button opening it says "Loot rules". The Kit also has a sell rule, so "The rules" is loose. One name per thing. |
| sub | applied when a run comes home · the first that fits wins | As a run comes home · the highest rule that fits wins | "First" doesn't say which way the list reads, and the ↑ button moves rules up. Sentence case. "As" matches the log and the note. |
| scrapped | The rules scrapped %d thing%s as they came in: %d scrap | Loot rules scrapped %d find%s: +%d scrap | "Thing" is loose: the game calls them finds. The same name as the button. |
| note | Scrap: scrapped for its scrap as it comes in. Highlight: an amber edge in the stash. Nothing fits: kept, as now. | Highlight: an amber edge in the stash. No rule fits: kept. Uniques, sets and mythics are never scrapped. | "Scrapped for its scrap" says the button's word twice. "As now" means nothing to a new player. A Scrap rule on the special kind silently keeps everything (sim.gd L10050), and the note must say so. The suggestion is no longer than the current line (the 860 px line). |
| special | Any unique, set piece or mythic | Uniques, sets, mythics | The rule's own words should match its chip (`kinds`). Patterned pieces count as special too (sim.gd L10006). Either add ", patterned" to both or let the note cover it. |
| plain | Plain gear | Plain pieces | *Gear* is banned outside the contract kind. Ties in with the patterns' `has_one`. |
| tier | a T%d affix | T%d+ affix | The rule is "best affix at least T%d", and the panel's chip says "T4+". As written it reads as exactly T4. |
| edit_head | A rule | Rule | The code appends " %d", so the head reads "A rule 3". |
| full | Eight rules: the most | 8 rules at most | Numbers as figures in mechanics. |

### Loadouts (LOADOUTS)

| Key | Current | Suggested | Why |
|---|---|---|---|
| name | Loadout %d | Kit %d | Glossary: everything worn is *kit*, and *loadout* is banned. Skills.md section 11, call 1: "'loadout' stays off screen". It sits in the Kit, so "Kit 2" reads as "the second set of kit". |
| worn | Loadout %d on | Kit %d on | As above (log line). |
| worn_short | Loadout %d on, but not: %s | Kit %d on, without: %s | As above. Code: the rig's bases are lower-cased into this list (sim.gd L11722) beside gear names as named, so one list mixes cases. Drop the `.to_lower()`. |
| head | Loadouts | Saved kits | As above. It is never read, so delete it or use it. |
| ready | all in the stash | all to hand | "ready" also covers a kit that is half worn and half in the stash (loadout_state). "In the stash" is wrong for the worn half. |
| skills | %d skills | (code: plural) | "1 skills" when one skill is saved (armoury.gd L433). |

### Build codes (BUILD)

| Key | Current | Suggested | Why |
|---|---|---|---|
| title | A build: %s · %d nodes · %d skills | %s build · %d perks · %d skills | *Node* is banned. The glossary word is *perk*, and Training's own search says "Find a perk". Plurals: code. |
| plan | Reset for %s, then %d of %d nodes trained | Reset for %s, then %d of %d perks trained | Glossary. |
| plan_free | %d of %d nodes trained, no reset | %d of %d perks trained, no reset | Glossary. |
| done | Retrained: %d of %d nodes | Retrained: %d of %d perks | Glossary. |
| missed | short of points for %d | %d can't be trained yet | Wrong fact. `train_node` fails for level gates, paths, bridges and keystones as well as points (sim.gd L2838–2865). |
| class | A %s's build: change to them first | Swap to the %s first: it's their build | Training's button is "Swap to the %s". "Change to them" doesn't say change what. |
| short | The reset wants %s tins | Short of tins: the reset is %s | Leads with the reason, like the other blocks. Code: `cost` is an int put in raw, so "1288" has no comma. Pass `Fmt.money(cost)`, which adds the unit. |
| copied | The build's code is copied | Build code copied | Shorter log line. Always "build code", never bare "code". |
| old | A code from another version: the web has moved since | A build code from an older version: the web has changed since | Bare "code" is the Radio's word (glossary: what papers carry). "Older" says which way. |

### The collection (COLLECTION)

| Key | Current | Suggested | Why |
|---|---|---|---|
| sites | Sites to depth 100 | Sites with every mark | Matt's call 1: depth is internal, never on screen. |
| sites_head | Sites · a mark at 10, 25, 50, 75 and 100 deep | Sites · a mark at levels 10, 25, 50, 75 and 100 | Depth again. Code: COLLECTION_DEPTHS are depths, and a site's level is `lv_at(i, d)`, so turn the marks into levels on the runner's scale (as atlas.gd and main.gd already do for best_depth). Or keep depths and say "5 marks to the top". |
| depth | depth %d | level %d | Depth again. Code: show `sim.lv_at(i, d)`. |
| classes | Classes to 50 | Classes at level 50 | "To 50" is missing its unit. |
| grid_head | Uniques · %d of %d · the found ones in colour | Every unique · the found ones in colour | Say it once: the Uniques found tile right above shows the same %d of %d. |
| sub | every runner's, kept for the crew | Every runner's, in one place · it gives no power | Sentence case. "Crew" is the glossary's faction word (see notes). The screen should say the one rule a player will wonder about. |
| mythics | Mythics | Mythics found | Matches "Uniques found" beside it. |

### Uniques (data.gd words/short, words.gd lore)

| Key | Current | Suggested | Why |
|---|---|---|---|
| The Issuer's Revolver words | A kill prints the killing hit again on the next man; a printed kill prints again | A kill lands the killing hit again on the next man; a kill from that hit does it again | Mechanics must be plain. *Print* is flavour, and it already means the Issuer's spawned men. |
| The Issuer's Revolver short | A kill's hit prints on the next | A kill's hit lands again on the next | As above. |
| The Issuer's Revolver lore | He never fired it. He didn't need to: anything it hit was paid for twice. | He never fired it. He never had to. Whatever it was pointed at got paid for twice. | Contradiction: never fired, yet "anything it hit". |
| The Registrar's Stamp lore | … Three of anything and she'd sign the third off without reading it. | … Three of anything and the third went through without her reading it. | A stamp doesn't sign. The Issuer's Robes already "signs money into being". |
| The Registrar's Stamp short | Every third skill free, twice | Every third skill: free, fires twice | "Free, twice" reads as "free twice". |
| The Lineman's Tool Bag words | … shocked men take 20% more from your skills | … shocked men take 20% more damage from your skills | "More" of what. The siblings say "damage". |

### Notables, element halves, joints (data.gd)

| Key | Current | Suggested | Why |
|---|---|---|---|
| Shifts notable "Paddles" | Paddles | Defib | Clash: the same joint's other half is "Paramedic's paddles", so the Flatline recipe reads "Paddles + Paramedic's paddles". The other pairs are two different nouns (Live wire / Scrapper's mains, Bottle and rag / Drifter's can). |
| Drill notable "Gas drill" | Gas drill | Gas, gas, gas | It echoes its own lane's name, which is why "Mag drill" was renamed in the last pass. It also sits beside "Recruit's gas". The British Army's gas alarm is a real callout. If commas in a name won't do, "Tear gas". |
| joint paramedic_shock | Every med you use shocks them for 3 seconds | Every med you use shocks the man you're fighting for 3 seconds | "Them" has nothing to refer to on a perk card. The code shocks the current target (`m["shock_t"]`). |
| joint recruit_poison | Hits and throws from your skills poison them | Hits and throws from your skills poison the men they hit | Same: "them" has nothing to refer to. |
| joint drifter_bleed | Killing a bleeding target: its drop rolls rarity twice, keeping the better | A bleeding man you kill rolls his drop's rarity twice; the better stays | The effect leads. *Man*, not *target* (skills.md section 11). Code: the reroll skips uniques and sets, which is fine unsaid. |

### The Pitch circle

| Key | Current | Suggested | Why |
|---|---|---|---|
| ELEMENTS_NOTE | A Pitch point opens one | A Pitch point opens each | "One" can read as "only one can be opened". Each element needs its own. The old note's fact ("a point when the meter fills") is now gone from the key. Either is fine at 11 px in the 190 px it has. |

---

## 2. Terms used inconsistently across the new strings

- **Loadout / kit.** "Loadout" is banned. The room and the glossary say kit.
- **Node / perk.** Only BUILD uses "nodes". Everything else in Training says perk.
- **Code.** The build code sits beside the Radio's codes (what papers carry). Always write "build code".
- **Sealed.** Used for the Registrar's skill lock, but already a Radio state (a sealed site after a Twist).
- **Print / printed.** Used for the Issuer's men (chip), the Revolver's repeat hit (unique words) and the breakdown
  row. Keep *printed* for the men and plain words for the Revolver.
- **Depth / level.** The collection uses depth three times. Everything else on screen says level.
- **The special kind.** Written as "Any unique, set piece or mythic" (rule words), "Uniques, sets, mythics" (chip),
  "It has a power of its own" (patterns) and "Only a unique has a pattern". The code also counts patterned pieces as
  special. Use one pair throughout: *Uniques, sets, mythics* and *plain pieces*.
- **Rare.** Written "Rare or better", "a rare of the same slot" and "a rare or better of its slot". Use one form
  with the capital.
- **When the loot rules run.** "When a run comes home" (sub), "as they came in" (log) and "as it comes in" (note).
  Use one.
- **Element words in the breakdown.** Burning, Bleeding, Poison, Shock, Frost. Use the nouns.
- **Lower-case subtitles.** FIGHT_SUB, LOOT_RULES sub and COLLECTION sub start in lower case. The guide's caps table
  puts body and card text in sentence case. Older subs ("new ones after every run") were approved lower case, so the
  guide should say which rule holds.

## 3. Strings that contradict how the feature works

- **F1. Red tape and "A skill sealed" show under "On them".** These are on you, not on the head. `order_chips()` is
  pushed into the On them row (run.gd L460). Code: send the archive's two chips to the On you row.
- **F2. Red tape cuts gun fire, not all damage.** The cut is in the gun tick (sim.gd L7329). The skill hit path
  (L10796) has no tape. The brief says it "cuts your damage", so either the words say fire (as suggested above) or the
  code takes it into skills too.
- **F3. "Printed · %d on you" overcounts.** It shows all printed men, not those within contact.
- **F4. "Short of points for %d".** A perk can fail to train for reasons other than points (see BUILD missed).
- **F5. One use is never stated.** `kept_note` is never read.
- **F6. A Scrap rule on the special kind does nothing.** A rule of "Uniques, sets, mythics → Scrap" silently keeps,
  and the note doesn't say so.
- **F7. "all in the stash" is wrong for a kit that is part worn.**

## 4. Facts to check (data, not words)

- **The Lineman's Tool Bag is on a Hiking pack** (tier 2, 24 cells). The other chase backpack, the Registrar's
  Satchel, is on an Assault pack (tier 7, 72 cells). The base sets the pack size shown on its card. Intentional?
- **The Registrar's Stamp is on the "Bank's own pen" base**, whose lore is a counter pen. There is precedent: the
  Caretaker's Keys and the Manager's Pen share it. Still, a stamp shown as "Bank's own pen" reads oddly.
- **The Revolver's repeat hit is counted as physical** whatever the killing hit was (sim.gd L7488). Any per-type split built
  on `dealt_by` will lean physical.
- **Possible double stun chip.** The Lineman's stun chip ("Stunned %d s") and the run's own skill-stun chip use the
  same words. If `_stunned_s()` also reads the head's stun, two identical chips show. Not confirmed.
- **"The second past" is the name of 12 bridge notables.** That is fine on the web, but the build plan's missed-names
  list and "Find a perk" will show identical names. Consider adding the class to the name, or accept it.
- **The glossary vs "the crew".** The game already uses "the crew" for the player's roster ("The rest of the crew",
  `_crew_tag`). The glossary says a crew is a faction. The guide needs a line on this. Until then, keep it out of
  new strings.

---

## Top 5

1. **Take the banned words off screen.** Loadout → Kit (`Kit %d`, `Saved kits`), and nodes → perks in every BUILD
   line.
2. **Fix the broken pattern lines.** `broken`, `put_on`, `wants`, `wants_n` and `wrong_slot`, plus the cost chip's
   `.to_lower()`. Today they print "the The …'s", "Wants a the grid's key" and "a armour".
3. **Take depth off the collection.** Show levels via `lv_at` (`sites`, `sites_head`, `depth`), per Matt's call 1.
4. **Give each word one meaning.** Registrar's "Sealed" → "Pending" (the Radio owns sealed). Revolver: plain words,
   with *printed* left to the Issuer's men. Always "build code". Paddles → Defib, and Gas drill renamed.
5. **Make the words match the mechanics.** Red tape and the seal chip move to On you, and red tape says "fire".
   "Printed men · %d". BUILD `missed` → "%d can't be trained yet". Show `kept_note` (one use). The loot note says
   uniques, sets and mythics are never scrapped.
