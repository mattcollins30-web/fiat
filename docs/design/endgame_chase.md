# The endgame's chase (24 Oct): the plan

Matt: "this genre is defined by endgame becoming boring once my build is complete and there's nothing more to see...
I'd expect at least 30ish for an indie arpg auto battler." Compared with its inspirations (Path of Exile, Diablo 4,
Last Epoch, Melvor), Fiat has the core (classes, the web, skills, affixes, uniques and mythics, the Bench, contracts,
the Map, the Radio, the rebuild and its three true pinnacles, paragon, hardcore). What it lacks is what keeps a
finished build looking: pinnacle fights that check a build, drops that change one, and the tools around the loot.

Agreed (24 Oct): Matt took every recommendation below. The work starts after the 32-hour balance pass (a read of the
endgame slowdown, 1bff05e) and his evening playtest, on his go-ahead; what that playtest raises is added then.

## Order

Each phase: talked through, the canvas where there's UI, built, smoked on Matt's machine, reviewed, committed. New
words through the language pass; the art in one manifest at the end, once the slice reads with test art.

1. **The fight's breakdown** (small). Damage by source and element, damage taken, each skill's uses, on the run's
   result. First, because it is how phases 2-3 are checked, and it sharpens the balance and playtest reads.
2. **A mechanic for each true pinnacle** (large). One build check each, three different ones:
   - The Lineman (the Grid): the Grid shields him, and the shield refills; break it inside its window. Checks burst.
   - The Registrar (the Archive): red tape; every so often she seals one of your three skills for a few seconds.
     Checks a build that doesn't lean on one skill.
   - The Issuer (the Mint): he prints men, and they keep coming. Checks spread and area damage.
   The bot and the odds' dry runs must play them, or the balance read is blind to them.
3. **A build-defining unique from each pinnacle** (medium), beside the Lamp, the Satchel and the Robes: a power you
   build around, tied to its mechanic (e.g. the Issuer's: a kill prints a copy of the hit onto the next man). Three
   proposals each on the canvas; Matt picks. The first win always drops it, a quarter after, as now.
4. **Moving a unique's power** (large). At the Bench: break a unique down to its pattern (the unique is used up) and
   put the pattern on a rare of the same slot; one pattern an item; mythics excluded. Paid in materials and a
   pinnacle's drop, so the late materials and the pinnacles stay worth farming.
5. **The loot filter and auto-salvage** (medium, the canvas). Rules by rarity, slot and affix tier: keep, bin or
   highlight. Applied when a run comes home (nothing binned mid-run unseen); off by default.
6. **The collection log** (small to medium). Every unique found, each site at each depth, each class to 50, each
   pinnacle beaten. No power from it (it would turn mandatory); Steam's achievements can hang off it later.
7. **Loadouts and build codes** (medium). Three loadouts a runner, holding gear and skills (the tree stays out: its
   respec has its own price); a code that exports the tree and skills. SAVE_VERSION 9.
8. **The balance harness plays one save** (medium, bot and harness code, reviewed). Matt (24 Oct): the per-class
   reads play "effectively a different game" now that classes unlock through the campaign and swap freely. The main
   read starts as the Poacher with `class_open` honoured (`set_class` skips it today), takes its target build when
   that class opens, and switches to the next class in the same world when the main's reach has stood a set time:
   the 30 hours are one save's. Build parity: every class and element run a fixed spell from one checkpoint save
   (the Radio's opening). The campaign gates re-aimed at the Poacher's route; each gate retired or re-aimed listed to
   Matt first. His playtest's route (when each class opened, what he switched to) is what the one-save read copies.
9. **The art batch, the language pass, then the single balance pass at 32 hours.** Then Matt's playtest on 0.9.0.

## Not in this plan (product, before any release)

Onboarding, the sound redo (ElevenLabs), the settings (keys, text size).

## The go (24 Oct, Matt): everything, then one pass

Matt: "lets do everything plus a single balance pass after everything using the new balance method - then ill playtest
earnestly. Produce mockups for everything now as well as any questions that need settling - you can then proceed with
the lot + any art without my intervention." Joints: option B. The Pitch circle: as mocked. The parked four go in
first. Mockups: the canvas "Fiat – The endgame chase and the web" (eight boards).

### The calls I've taken (Matt can overrule any; each is what gets built otherwise)

1. Joints B: the Paramedic poison to shock, the Recruit bleed to poison, the Drifter shock to bleed. The swapped
   notables and element halves renamed (the language pass); the wheel reordered as on the board.
2. The Pitch circle: an element's starter costs 1 Pitch point; it opens that element for every class (the camp's);
   only an opened element's meter fills. Starters don't count towards the Pitch's columns.
3. A new game starts as the Poacher; no pick.
4. Each class's first skill comes with the first point in its tree (its hang moved to the entry's).
5. The Lineman: a shield of 30% of his HP over it; not broken in 6 s, it fills again; broken, he's stunned 3 s.
6. The Registrar: every 12 s she seals the skill you'd fire next for 5 s; with none slotted, your secondary.
7. The Issuer: a man printed every 8 s (one of the host site's crew at his level), 6 on you at most.
8. The uniques: the Lineman's Tool Bag (backpack, on a Hiking pack - the Ambulance set has the rig, 24 Oct: your
   shock arcs to everyone else on you at half; shocked men take 20% more damage from your skills), the Registrar's Stamp (charm: every third skill free and twice), the Issuer's Revolver
   (secondary: a kill lands the killing hit again on the next man; a kill from that hit does the same). Each beside the old
   one; the first win gives one of the two.
9. Patterns: breaking a unique is free and uses it up; putting a pattern on a rare of the same slot costs a ledger
   seal (the Grid's key for a helmet or rig), 12 of the slot's zone material and tins by level; one pattern an item;
   no mythics; a pattern is one use.
10. The filter: off till a rule is added; applied as a run comes home; the first rule that fits wins; "scrap" scraps
    for scrap; "highlight" is an amber edge.
11. The collection: no power; every runner's for the crew; opened from the Stats room's Record.
12. Loadouts: three a runner, guns, body, rig and the three skills; a missing piece left empty and named. The build
    code: the class, the web's nodes, the skills; pasting shows the retrain's cost first.
13. The harness: the main read plays its target build from the Poacher, switches to the next class when the reach
    has stood 2 h; the parity reads run 4 h from the Radio's checkpoint save.
14. Art: the three uniques, the renamed notables and halves, the collection's and patterns' icons only where a
    picture is shown; checked against pixellab_lessons.md and run.
15. VERSION 0.9.0, SAVE_VERSION 9.
