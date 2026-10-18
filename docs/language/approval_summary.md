# Language review: approval summary

Editor's reconciliation of the two reviews (new player, copy editor) against style guide v2 and Matt's four calls. The full table, one row per string with file, line and code notes, is the words-pass page (the approval artifact) and its seed data (`changes`, `renames`, `duplicates`, `questions`, `dead`, `dropped`).

- Review rows: 1,180 over 852 string ids. **793 ids change**, 59 are dropped (churn, taste, contradicts the guide, not shown, or dead).
- Another **39 strings** that no reviewer listed are in the table because Matt's calls reach them (depth on the Radio, Stats, the Pitch card, the Dial and the Yard gates; "first shot" in Training, items and Stats; and three renames). They are marked "Not in the reviews".
- 85 changes need a code change too (see `code_note`).

## Changes per group

| Group | Count | What it covers |
|---|---:|---|
| fact | 112 | the text states something the code contradicts |
| depth | 45 | call 1: depth off screen, signals show a level |
| glossary | 90 | one name for each thing (incl. call 3: the Pitch, the Yard, game) |
| caps | 35 | caps by role, names as named, no case-folding in code |
| grammar | 153 | grammar, spelling, punctuation, figures for numbers |
| clarity | 350 | mechanics rewrites for understanding |
| flavour | 41 | flavour lines and renamed names |
| cut | 6 | remove the string or the element |
| **Total** | **832** | |

## The 10 most important fact fixes

1. **"First shot" is not one shot.** Range cards, Rifleman, the Army's Issue rifle, the Training chip, item lines and Stats all said "first shot"; the bonus holds the whole time the first man of each gang is alive. Reworded to "damage to the first of each gang" (call 4).
2. **Dial points come from signals, not depths.** The Dial's band, sum strip and empty panel said "a point a new depth"; points come from a signal won at your reach or past it (sim.gd L4963). A signal won at your reach also pays.
3. **The Float takes the whole rig.** It said "no meds"; with no rig there are no rounds or grenades either, so guns run dry after the first fight. Also a question.
4. **An insured time-out does not pay tins.** The log said "the Fence pays for the kit"; the kit goes back to the stash.
5. **Picked over's figures were a rank behind.** The base is already 33%; the ranks give 50%, 67% and 83%.
6. **Full strength was never "depth 8, not 10".** The start depends on the area and the moves; the node brings it 2 levels sooner.
7. **Quiet feet: the gang timer is 24 seconds, not 20.**
8. **Heavy crews and the Poacher.** Heavy crews puts one more on you (it said bigger gangs); the Poacher slows every gang (it said the next one).
9. **Lorry watch and Military band.** Lorry watch makes Kev's paper come every time (it said twice as often); Military band, the Radio rank and Booster grow a code's bonus, not the whole reward.
10. **Room intros describe old screens.** The Map's DEPTH tile, the Workshop's Jobs/Mounts/Bench, the Fence's Sell/Buy and the Radio's "heard so far" tiles now name the tabs the player will click; Moving on opens with the campaign done, not the lorry.

Also in the fact group: two runners turn up, not one; the Fence's word is never Common (one line said any rarity); the Branch Pistol doubles damage, not rate; the Council's 4-piece clause does nothing; Third socket covers helmets; Bent gives 57%, not double.

## Renames (one name used for two things)

| Old name | Kept for | Renamed | New name | Why |
|---|---|---|---|---|
| Live wire | Stripping notable (S2055) | S2187 | **Daisy chain** | The Live tree's keystone had the Scrapper notable's name; a daisy chain is how the shock goes round. |
| Jump Leads | the unique (S1509) | S2180 | **Sparks** | The first Live perk shared the unique's name and its title case. |
| Petrol bomb | the grenade (S1390) | S2092 | **Bottle and rag** | The Moving on notable shared the grenade's name. |
| Antifreeze | the socketable (S1452) | S2138 | **De-icer** | The cold's first perk shared the socketable's name. |
| Steady hands | the Bench's Yard pick (S0920) | S2011 | **Steady pulse** | The Triage perk shared a Yard pick's name. |
| Haggling | the Fence's Yard pick (S1022) | S2064 | **Mates' rates** | The Fencing perk shared a Yard pick's name. |
| Overtime | the Generator's Yard pick (S1100) | S2042 | **Double shift** | The Shifts notable shared a Yard pick's name; it sits in a tree called Shifts. |
| Head start | the Drifter's Moving on perk (S2084) | S2410 | **Heads roll** | The Dial node (a point for a head at full strength) shared a perk's name. |
| Lucky | the trait (S2484) | S2100 | **Jammy** | The Luck perk shared the trait's name. |
| Rabbit's foot | the charm base (S1330) | S2105 | **Touch wood** | The Luck perk shared a charm's name. |
| Spread / Spreads | Spreads (S2125) | S2133 | **Wildfire** | Two perks in one tree, one letter apart. |
| Live | the tree | S2179 | **Current** | The notable had its own tree's name. |
| Triage | the tree | S2009 | **Fast work** | The notable had its own tree's name. |
| Quick hands | Snares (S1954, data.gd L1446) | S1954 (Stripping, data.gd L1519) | **Quick fingers** | The same name in two class trees. |
| The pack | the runner's pack (glossary) | S1170 | **The litter** | A Kennel pick called The pack reads as the runner's bag. |
| Lock-up | the banned stash word | S0971 | **Container** | A Stash pick called Lock-up reads as the stash itself. |
| Issue pistol | the Army's Issue set (Issue helmet, carrier, bergen, rifle) | S1253 | **Duty pistol** | A plain base read as a set piece. |
| Issue plates | the Army's Issue set | S1289 | **Stab plates** | A plain base read as a set piece, beside the Issue carrier. |
| The Ambulance's Bag | The Ambulance's set | S1608 | **The Crash Bag** | A mythic read as the set's fourth piece. |
| Everyone's here | Everyone's in (S2570) | S2590 | **Full house** | Two Radio codes read as the same code. |
| The radio | the Radio room | S3507, S3510, S3544 | **The wireless** | The Training Also collection sat beside the room called Radio. |
| The air | the Radio's tab (S3864) | S2483 | **The codes** | The Dial lane and the Radio tab on one screen; matches The sites and The crews. |
| Knuckle-duster | the base Knuckle duster (S1242) | S2230 | **Sovereign rings** | The same thing spelled two ways. |
| An edge | the Blades perk (S2200) | S2621 | **Melee** | The gamble short clashed with the perk, and the melee pool holds hammers with no edge. |

## Duplicates per screen

| Screen | Fact | Shows | Keep | Cut | Code |
|---|---|---|---|---|---|
| The Clinic | Heal price | the Heal tile (vendor.gd L306-310) and the Heal button (L600-608); they disagree (211 against 212 tins) because the tile refreshes every frame and the button on its signature | the button | the Heal tile (S3618) | vendor.gd: remove the tile. |
| The Clinic | Wound price | The wound tile (vendor.gd L590) and the Treat the wound button | the button | The wound tile (S3670) | vendor.gd L590: remove the tile. |
| The Clinic | HP and the wound | top bar; band "91 of 160 HP · wounded: max HP −10%"; TREATMENT bar "Your HP 91 / 160 · wounded" (vendor.gd L535) | the band (and the global top bar) | the bar's text: let it be a plain bar | vendor.gd L535: drop the HP and wound words from the bar. |
| The Clinic | The rig | "The rig 0 of 3 pouches" tile and the panel's "The rig: 0 of 3" (vendor.gd L699/L756) | the panel line | the tile |  |
| The Clinic | The shelf | tab "Shelf (6)", grid header "Shelf 6 / 6", panel "The shelf: 6 of 6" (vendor.gd L718) | the grid header | the tab count (vendor.gd L315) and the panel title count | vendor.gd L315: tab text "Shelf" only. |
| The Fence | The shelf, in two units | tab "Shelf (3)" (items), grid "Shelf 4 / 4" (cells), tile "Their shelf · 3 on it" (vendor.gd L674), panel "Their shelf: 3 of 3" (L726) | the grid header, in cells (it is what limits buying) | the "Their shelf" tile, the tab count, and the count in the panel title | vendor.gd L674 remove the tile; L315 tab "Shelf"; L726 title "Their shelf". |
| The Fence | Price rise | band "prices up 50%" (vendor.gd L640) and panel "Prices up 50%; notes keep their value" (L723) | the panel (it adds the notes) | the band's price clause; the band keeps "pays full value, charges three times" | vendor.gd L640. |
| The Fence | Stash count | band "for the lot · 8 in the stash" (vendor.gd L641) and tab "Stash (8)" | the tab | the band's count ("for the lot") | vendor.gd L641: use the "for the lot" form. |
| The Fence | Contracts count | tab "Contracts (3)" (vendor.gd L327) and "THE CONTRACTS · 3 OPEN, 0 READY" | the header | the tab count | vendor.gd L327: tab "Contracts". |
| The Fence | The word's refresh | header "new ones after every run" (S3607) and the body's "the kinds change after every run" | the header | the body clause (S3647) |  |
| The Fence | First visit lines | intro lines 1-2 are FENCE.visit[0] and [2], and visit[0] shows under the band the moment the card closes | the intro | the band's first line on the first visit | vendor.gd L871: start the first visit's band at visit[1]. |
| Run | Pack fill | grid header "Pack 3 / 9", THE TAKE "Pack 3 of 9", pick panel "The pack: 3 of 9 cells" (run.gd L752) and "9 cells free" | the grid header, and the pick panel's "cells free" | the pick panel's "The pack: %d of %d cells" title and THE TAKE's count text (its bar stays) | run.gd L752. |
| Run | Damage | top bar "24 dmg/s" (dps()) and frame "Your fire 26/s" (fire_now): two different figures under one idea | both, named apart | nothing; rename the frame's tile "Firing now" | run.gd L373-385: tile key "Your fire" becomes "Firing now". |
| Run | Their fire | tile "Incoming" (renamed Their fire, S3311) and the six's "Their fire" under the frame | the six's | the tile when the six shows | run.gd L373/378/385. |
| The Kit | Sell rule | "When a run comes home: nothing's sold" (armoury.gd L188) right above the button "Sell: off" | the button, labelled "Sell when home:" (S4098) | the line | armoury.gd L188: drop the two junk_words lines. |
| Stats | dmg/s | top bar, band headline "29 dmg/s" (stats_room.gd L248), ATTACK "29 dmg/s" | ATTACK (and the global top bar) | the band's figure |  |
| Stats | Level and class | top bar, band "Stats · Drifter, level 14" (stats_room.gd L248), THE RUNNER | THE RUNNER | the level from the band ("Stats · Drifter") | stats_room.gd L248. |
| Stats | Alive and runs | THE RUNNER "Alive 8:10:23" and "Runs, this runner 6"; the record's foot "5 runs back · alive 8:10:23" (stats_room.gd L448-449); the wall "6 runs, every runner": 5 and 6 read as a contradiction | THE RUNNER's rows | "runs back" and "alive" from the record's foot | stats_room.gd L448-449. |
| Workshop | Tins, notes, scrap | top bar, band chips, Craft panel "In hand: …" (workshop.gd L658) | the Craft panel line (where you decide) and the top bar | the band chips |  |
| Workshop | Empty mounts | "Grip · Empty" tiles and the chip "nothing fitted" (workshop.gd L308) | the tiles | the chip | workshop.gd L308. |
| The Pitch | Tins, notes, scrap | band purse and the top bar (main.gd L1341) | the top bar, and the salvage on the band (the top bar hides it at 0) | tins, notes and scrap from the band | main.gd L1341. |
| The Pitch / log | The lorry's beaten | YARD["lorry"] ("…can move on whenever you like"), NEXT["lorry"] ("Move the Pitch when you're ready…") and the town card note (main.gd L1335) | NEXT on the Runner card | the move clause from YARD["lorry"] |  |
| Radio | Signals held | chip "Signals 0 of 3 held" (radio.gd L462), head "SIGNALS · 0 OF 3 HELD", decoder note "3 more signals can be held" | the head, and the decoder note (it sits at the decision) | the chip | radio.gd L462. |
| Radio | Papers | chip "Papers 0" and head "THE PAPERS · 0" | the head | the chip | radio.gd L462. |
| Radio | Notes | top bar, chip "Notes 220" (radio.gd L462), Ask Kev "(you have 220)" (L600) | the top bar | the chip and "(you have %d)" (the button greys out when short) | radio.gd L462, L600: drop the first fit form. |
| The Dial | The name | kicker "The Dial · the endgame's tree" (atlas.gd L188), title, panel title | title and panel | the name from the kicker ("The endgame's tree") | atlas.gd L188. |
| The Dial | The point rule | band right lines (S4177-S4179), sum strip (S4191), panel empty (S0483/S0484); they disagreed | the band, now correct; the strip and panel now say the same | if one must go, the panel's short line (S0484) |  |
| Training | Class | band "Drifter · Training" (barracks.gd L720), the card "✓ your past", the panel title | the card and the panel | the class from the band |  |
| Training | Also: Radio lines | "The radio · 2 of 33" in one state and "Radio 2/33" in another | one form, now "The wireless" | the second form |  |
| Settings | How to change | header "A press steps each one" and every row's ": press to change" (main.gd L690) | the header | ": press to change" on the rows | main.gd L690. |
| Site guide | The name | the button "Site guide ?" and the panel title "What a site pays" | "Site guide" | the panel title (S4344) |  |
| Map | Area name | the selected tab and every card's kicker "Tier 1 · The Outskirts" (missions.gd L269) | the tab | the area from the kicker | missions.gd L269: kicker "Tier %d". |
| Map | Weather | the box head (CONDITIONS · fog), the row "Fog: one fewer on you, drops −10%", the log | the row (it alone gives the effect) | the weather from the head (it keeps the time of day) | missions.gd L308. |
| Map | Codes clause | "ON THE AIR · … · a plain site" on every card | nothing | "a plain site" (S3247): codes never land on a Map site | missions.gd L307-308. |
| Room intros | Stats, Training, Clinic, Radio | Stats line repeats title and tiles; Training line repeats its title; three medic lines open "Sit down"; "Kev here" twice in a row | the titles and tiles | the repeated words (S0066, S0074, S0291, S0122) |  |
| Item card | Typed mounts | flavour ends "Shotguns only" etc. and the mechanics line says the same (items.gd L233) | the mechanics line | the flavour clause (S0702, S0741, S0745, S0746, S0749) |  |
| Item card | Issue Webbing | words and short identical | the words | a real short (S1493) |  |

## Questions for Matt

1. **The Float takes the whole rig away, so the runner carries no rounds or grenades: guns run dry after the first fight.** med_capacity() is 0 with the Float (sim.gd L733) and rounds are read only from the rig (L2677). The text now says so (S1537). *Recommendation:* Let the Float stop meds only and keep rounds and grenades; it reads as a pace-and-pack unique, not a melee-only one.
2. **The Council's 4-piece bonus "every cache opens" is not wired.** has_set_rule("council") is called nowhere (sim.gd); the text now drops the clause (S1632). *Recommendation:* Wire it into has_keys() and put the clause back as "every locked crate opens"; the set is short a bonus without it.
3. **The lie of the land (a Dial keystone) does nothing.** Its only effect is in set_depth(), which no screen reaches since 15 Oct (missions.gd L272 hides the −/+). S2349 and its figures are reworded, but the node stays dead. *Recommendation:* Give it a signal effect (for example: a won signal can roll 1 more level past your reach), or replace the node.
4. **Bent says "twice as often" but gives 57%, not 80%.** The tier IV weight doubles and the four odds are then normalised (sim.gd L3546). The text now says 57%. *Recommendation:* Keep the code and the honest figure; or change the code to 80% if "twice" is the design.
5. **Two Yard picks in one building do the same thing.** Tripwires and Watch rota (the Lookout) are both gangs 10% later with the same words; A dog and Second dog (the Kennel) are both +1 find. Guard dog and Crow's nest are the same figure in two buildings; Spotter and Lookout post stack. *Recommendation:* Give Watch rota and Second dog effects of their own; a row of tiles should never offer the same pick twice.
6. **The Spare Key (a mythic) is exactly the Double tap notable.** secondary_share() returns 1.0 for both (sim.gd L330). *Recommendation:* Give the Spare Key something Double tap lacks (for example the secondary spends no rounds).
7. **The Weather set halves Fog's "one fewer on you" to nothing.** _softened() rounds int(−1 × 0.5) to 0 (sim.gd L4245), so the pick removes Fog's only upside. *Recommendation:* Round contact away from zero (or leave contact out of the softening).
8. **A wound always shows −10%, even with Physio.** wound_words() prints Data.WOUND_PCT (sim.gd L362), while the cut is 6.7% with Physio (L355). *Recommendation:* Print the real figure from wound_mult().
9. **The opening is told twice, with two timelines.** sim.gd L185 logs OPENING (done in four days) on top of the opening scenes ("the banks shut for a day, then a week"). S0001-S0003 were left unchanged for this. *Recommendation:* Cut the OPENING log lines; the scenes carry the story.
10. **"Shelf" names three or four things.** The Fence's stock, the Clinic's stock, a Clinic Yard pick called Shelf, and Training's uniques collection "The shelf". *Recommendation:* Keep "shelf" for the two shops; rename the Training collection (for example "The mantelpiece").
11. **Rail names and screen titles differ.** The rail says Workshop, Radio, Training, Stats; the screens title themselves The Workshop, The Radio. *Recommendation:* Drop "The" from the screen kickers so each room has one name; the rail is the fit-checked one.
12. **Bin and Scrap it both turn a stash item into scrap.** Bin is the Kit's button, Scrap it the Workshop's job. *Recommendation:* If they pay the same, keep one verb (Scrap); if not, say the difference on each.
13. **The Workshop's Guns tab shows the claw hammer and the knife.** The tab and the Guns filter both include melee weapons. *Recommendation:* Rename the tab and the filter "Weapons", or keep melee out of them.
14. **The setting: the guide says a northern English town; the strings name Swansea, Llantrisant and the Mint.** Reviewer C's note (S0039, S0192). *Recommendation:* Confirm the place; then fix whichever is wrong, the guide or the lines.
15. **Register flag: "The boats kept coming; where they came from was worse." (S0010)** Can read as a line about migrants; it is a recorded take. *Recommendation:* Your call; no edit proposed.
16. **The Lucky Cap says "half as likely to be common".** The code rerolls a Common half the time, so a find stays Common at about 62% of the base, not 50% (items.gd L48). *Recommendation:* Accept as near enough, or reword to "less likely to be Common".
17. **Stats shows "Last run: None yet" beside "5 runs back".** last_report is saved (sim.gd L8504), so it may be the gallery save only. *Recommendation:* Check a loaded real save shows its last run before the next playtest.
18. **Calls 1 and 4 reach 36 strings no reviewer listed.** Depth lines on the Radio, Stats, the Pitch card, the Dial and the Yard gates; "first shot" in Training, items and Stats. *Recommendation:* They are in the changes list, marked "Not in the reviews"; approve them with the rest.

## Dead strings

Nothing reads these: S0136, S0137, S0138, S0139, S0140, S0819, S0851, S0865, S0873, S0874, S3269 (RADIO_SHORT, EVENTS cache_shut, NEXT lot, NOTES generator, YARD dead and first_run, missions.gd `_station_words`). Delete them with the code pass.

## Dropped, by reason

| Reason | Ids |
|---|---:|
| dead: never read | 10 |
| guide: chips number-first | 10 |
| art key, unshown | 8 |
| Matt's call; question | 3 |
| voice, Fence catchphrase | 3 |
| taste, repetition minor | 3 |
| taste, stock phrase | 2 |
| guide: number-first fine | 2 |
| internal key, unshown | 1 |
| kept; perk renamed | 1 |
| fine as short | 1 |
| taste, alight fine | 1 |
| fine, glossary quicker | 1 |
| kept; keystone renamed | 1 |
| guide idiom "on you" | 1 |
| churn, number-first fine | 1 |
| chips need short form | 1 |
| guard, never shown | 1 |
| reads as noun | 1 |
| taste, echo acceptable | 1 |
| 3-letter cell code | 1 |
| guide keeps ATT code | 1 |
| guide keeps AMO code | 1 |
| kept; panel renamed instead | 1 |
| taste; value explains | 1 |
| fine with Pack slot | 1 |
