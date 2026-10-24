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
