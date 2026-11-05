# Fiat: words on screen

The house rules for every player-facing string. v2 (18 Oct): Matt's four calls made (depth, "the", the Pitch,
first shot); the rest as the reviewers proposed, for sign-off with the approval table. v3 (24 Oct, Matt, the skills'
language pass): "skill" unbanned and given its own meaning; affix lines number first; seconds in lines and chips. The smoke checks the parts a
machine can check (caps by role, banned glossary variants, fit); the rest is for the reviewers and for whoever writes
the next line.

## 1. Two voices

Every string is one of two kinds. Decide which before writing it.

**Mechanics** says what a thing does. The player reads it to make a choice.

- Plain English. In a sentence (perk, unique, class, trait lines) the effect leads: "Rest twice as fast on the Pitch",
  "The pack holds 6 more cells". In a chip, tile, stat row or affix line the number leads: "+8% damage", "+40 cells",
  "6 HP a second". Never mix the two in one list.
- Half, twice, double and triple are fine. Quarter, third, fifth, tenth, "half again" and spelled-out numbers are
  not: write the figure ("25% less").
- One idea a line. No jokes, no character, no hedging.
- Numbers as figures: "6 more cells", not "six more cells". Percentages as "+7%", "−25%" (a real minus sign).
- Conditions after the effect: "Take 25% less damage with three or more on you", not "With three on you, take a
  quarter less".
- Name things by their glossary name (section 3). Never invent a synonym for variety.
- Where it lives: tooltips, stat rows, chips, item and affix lines, perk explanations, buttons, tile labels and values,
  odds and reasons, settings, errors and confirmations.
- The Map's site card says shares in words (a little, some, half, most, nearly all) - the designer's call, 2 Nov.

**Flavour** gives the world its character. The player reads it for pleasure; nothing in it is needed to play.

- The dry, understated South Wales voice of the opening and the radio (Matt, 18 Oct: the game is set in a South Wales town). Short sentences. British, working-class,
  specific nouns (a P45, a betting slip, a bum bag), no melodrama, no exclamation marks.
- Flavour may be oblique. It may never contradict the mechanics, and never be the only place a rule is stated.
- Where it lives: names (sites, people, uniques, sets, perks, crates), the opening, radio lines, room intros, chronicle,
  papers, story beats, a unique's one-line lore.

**Perks** (Matt, 18 Oct): the perk's name is flavour ("Pack horse", "The dog's share"). Its explanation is mechanics
("The pack holds 6 more cells"; "When the runner dies, their rig comes home"). The same holds for uniques, sets,
Yard works and Atlas nodes: the name has character, the line under it is plain.

## 2. Caps by role

| Role | Style | Examples |
|---|---|---|
| Section and box labels (the small headers over a group or tile) | ALL CAPS | THEY FIRE, ON THE AIR, ROOMS, DEPTH |
| Screen titles, card titles, buttons, tabs, chip text, keys, values, body | Sentence case | Set off, Site guide, Take it, Auto-run off |
| Names of places, people and unique things | As named | The Allotments, Kev, The Last Orders, The Fence |
| Item bases and affixes | Sentence case, an affix's number first (v3) | Pump shotgun, Bum bag, +7% damage |
| Room names on the rail | As named (they are places) | The Map, The Kit, Training |

- Sentence case means: capital on the first word and on names only. "Auto-run off", not "Auto-Run Off".
- "The" is part of a name when the thing is a place or a unique ("The Fence", "The Last Orders"). How it reads
  mid-sentence is Matt's call, below.
- No letter-spaced kickers ("M Y T H I C"): use ALL CAPS with tracking in the font, so screen readers and the fit
  checks see a word.
- Abbreviations stay as they are: HP, XP, SMG, P45.

**Mid-sentence "the" (Matt, 18 Oct):** lower-case "the" in running text ("Sell it to the Fence", "back from the
Allotments"); capital only when the name stands alone (a title, a heading, a button, the rail).
- Never lower-case a name in code (`.to_lower()` on a site, unique, class or item base). Mid-sentence item bases keep
  their acronyms ("an army SMG").
- Rarity names as named when they name the rarity (Common, Uncommon, Rare, Epic, Legendary, Mythic); lower case only
  as plain nouns ("half the commons").

## 3. Glossary: one name for each thing

The name on the left is the only one used on screen. Variants on the right are banned in mechanics text (the smoke
fails on them); flavour may use them only where a character is talking.

| Thing | Use | Not |
|---|---|---|
| The money the Fence pays | tins | cash, money, coins (the "$" glyph stays) |
| The one sent out | the runner | operator, merc, the player, your guy |
| The person playing | you | the player |
| A site's last fight / its leader | head | boss, leader (the "Boss" button becomes "Head"); never a headcount ("one head short" → "one fewer") |
| One of a gang | man, one ("one fewer on you") | head |
| The armed men on a site | gang | crew (a crew is a faction: the Doormen, the Poachers) |
| Where the runner goes | site | location, map, level |
| How hard a site or a signal is (Matt, 18 Oct) | level, on the runner's scale ("a level 14 signal") | depth (internal only: never on screen) |
| A site's place on the Map | tier | — |
| One of a site's three fights, in order (5 Nov, docs/design/stages.md) | stage, in sentences ("the next stage"); "1/3", "2/3", "3/3" as a figure on buttons and pins ("The Allotments · 2/3"); a gate "After Top Farm 2/3" | Not: depth, level, part |
| The runner's level | level | rank |
| An item's power band | item level | ilvl |
| The big Map areas | the Outskirts, the Estate, the Town, the City | zone, area (in mechanics, "area" if a generic word is needed) |
| The Radio's currency | notes | papers (papers are the items that carry codes) |
| What the papers carry | codes | frequencies (flavour only) |
| A code tuned in | signal | — |
| The Workshop's material | scrap | parts |
| Copper, safe steel, army surplus | salvage | — |
| Home storage | stash | lock-up, storage |
| What the runner carries out | pack | bag, inventory |
| What the runner wears on the chest for meds/ammo | rig | belt |
| Everything worn | kit | loadout, gear (gear only as the generic "gear" contract kind) |
| A point bought in Training | perk | node, talent |
| Something slotted before a run and fired in a fight; costs energy, has a cooldown (v3) | skill | ability, power, move, skill node |
| A bleed, burn, poison, chill or shock on the runner (v3) | ailment | debuff, status, dot |
| What skills cost (v3) | energy | mana, stamina, pool |
| Home (Matt, 18 Oct) | the Pitch | camp, base, home |
| The tree of works on the Pitch | the Yard | — |
| A save | game ("New game", "Load game") | camp |
| Bandages, painkillers... | meds | medical, health items |
| A trip out | run | mission, raid, deploy |
| Runs the runner goes on unwatched, one after another ("Run it ×5", 29 Oct) | a repeat (the lot); a repeat run (each run of it) | auto-run, idle run, farm |
| Any run that isn't a repeat run: the one on screen | a watched run | live run, normal run |
| The runner while on a repeat, between runs too | away ("The runner is away") | gone |
| A crew sent to a far place (the Bunkhouse's line B, 29 Oct; built with the trips) | expedition | trip (the glossary's "a trip out" is a run), journey |
| Chance to clear | odds | chance, win rate |
| An expedition's chance of a bad roll (29 Oct) | risk ("18% risk", "−2% risk") | danger, threat |
| Those sent on an expedition: the lead and the hands (29 Oct) | the party | crew (a faction), convoy (the head's convoy) |
| A trip to a far place (29 Oct) | expedition | trip (a trip out is a run) |
| HP | HP | health, life |
| The bonus to the first man of each gang (Matt, 18 Oct) | damage to the first of each gang | first shot, first hit |
| What guns fire | rounds | ammo (the cell code AMO stays) |
| What a search opens | crate | cache |
| How fast things happen | quicker | faster |
| How good finds are | loot quality | rarer finds, better finds (flavour only) |
| Gangs arriving later | gangs come N% later (chips), take N% longer to arrive (sentences) | gang delay, slower to arrive |
| Fire, poison, bleed together | damage over time | dots |
| Below full HP / carrying a wound | hurt / wounded | — |
| Gun parts | gun part | attachment, part (cell code ATT stays) |
| Any probability that isn't the odds to clear | chance | — |

Terms that need a one-line definition where they first show (a tooltip): Guard, pace (how fast the runner fights),
joint, keystone, notable, capstone, reach, paragon, sealed, Twist, the Dial, salvage.

A crew is a faction (the Doormen's crew); the men on a site are a gang. "Heavy crews" can stay as a flavour name.
Two things must never share a name: the reviewers' clash list (Live wire, Quick hands, Steady hands ...) is in the
approval table.

## 4. Grammar and spelling

- British spelling: armour, colour, favourite, defence, -ise (organise, recognise), grey, programme (not software).
- Numbers: figures in mechanics ("3 in 10"), words allowed in flavour. Times as m:ss ("1:50"). A duration in a line is
  "8 seconds"; in a chip "8 s" (v3). Thousands with a comma
  ("1,288 tins").
- Punctuation: no full stop on buttons, chips, tile values or one-line tooltips; full stops on any line of two
  sentences or more and on flavour sentences. Curly apostrophes are not needed (the font draws straight ones well);
  be consistent. En dash with spaces ( – ) or a colon for an aside, never a hyphen with spaces.
- "×" for multipliers ("×2"), "−" for minus, "·" as a separator between facts in one line, at most two.
- Contractions are fine in both voices. "a second" in sentences ("6 HP a second", the house idiom); "/s" in figures
  ("26 dmg/s", "0.5 HP/s"). "dmg/s" for damage a second in figures, never "damage/s".
- Ranges with an en dash and no spaces: "levels 10–11".
- The run log follows the same full-stop rule as everything else.
- Plurals with numbers handled in code, never "1 finds".

## 5. Say it once

A fact appears once per screen, in the place the player looks for it. When the same fact shows twice (the odds in a
card's heading and again in a tile; a level in the top row and a panel), keep the one nearest the decision and drop
the other, unless the second adds something. The reviewers list every duplicate per screen.

## 6. Fit

Every label must fit its box at its size without clipping (the smoke's fit checks). If it doesn't, shorten the words
before shrinking the font. The corpus (docs/language/strings.md) gives each label's room where the source states it.
