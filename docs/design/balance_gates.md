# The balance pass's gates (draft, 15 Oct)

Set before any number moves (Matt, 6 Oct: "select balance-pass gates up front"). The target (Matt, 15 Oct): **twice the
campaign as it stands** - his 14 Oct save had the Bank at 47 min and the Quartermaster at 67 by hand; twice is the Bank
at about 1 h 35 and the Quartermaster at about 2 h 15. Read on the ten element builds (the game, 11 Oct), two reads a
build, the median; the five plain builds only have to finish.

## How the bot stands for a hand

The bot can't play at Matt's pace, so its hours are read against his once: on the 13 Oct reads the element builds'
median Bank was 0.65 h against his 0.78 h by hand on the next day's build - **the bot runs about 0.85 of a hand's
time**. The pace gates below are his targets times 0.85. His next playtest re-measures the ratio; a gate moves with it,
not the game (10 Oct: real play calibrates the bot's timings).

## The gates

| # | Gate | Green when | Why |
|---|---|---|---|
| 1 | **The Bank** | the Manager beaten at 1.1-1.6 h (bot), the median of the element builds | 2 x 47 min by hand |
| 2 | **The Quartermaster** | beaten at 1.6-2.3 h (bot); the campaign done | 2 x 67 min by hand: the headline |
| 3 | **The builds' band** | the slowest element build's Quartermaster within 2x the fastest | classes differ by design, not by luck |
| 4 | **Levels against the campaign** | level 18-22 at the Quartermaster (the core's capstone 18, keystones and the second past at 20) | gating by level (B5, B6) lands where the campaign ends |
| 5 | **The capstone** | level 30 within 2 h of the Quartermaster, every element build | the first goal past the campaign |
| 6 | **The Radio's ladder** | from the Radio's opening to hour 12, every build: a signal made at least every 20 min (the longest stretch) and the reach a level an hour or better on average; the median read never 3 h without a level (Matt, 16 Oct: was +1 every 45 min, every read) | the endgame moves; papers never the only wall (the B7 note); the reach is the kit's power against the curve, so it comes in steps, not a metronome |
| 7 | **Kev's story** | the three beats done by hour 10, every element build | the ending is reachable (was the lorry by 16) |
| 8 | **Retirement** | level 50 between hour 12 and 24 on the median element read (a never counts later than any), and no read before hour 8 (Matt, 16 Oct: the same build lands either side read to read) | 50 is a long goal, not a wall |
| 9 | **No reds** | every open site at depth 1 at 60% or better in the kit as it stands | kept |
| 10 | **The gang clock** | on the Outskirts and the Estate at depth 1, at least two searches in a gap between gangs; under 5% of runs out of time | the search against the gangs (parked 14 Oct); the clock kept |
| 11 | **Staying costs** | from gang 3 on, a run that stays loses HP fast enough that the bot leaves by gang 5 at least half the time | harder gangs (B9) bite |
| 12 | **The loot tables** | the read (tests/loot_read.gd) by zone: commons fall zone on zone; epic or better 5-10% in the City; a campaign's loose unique at least once by the Quartermaster on most builds; set pieces under 1 in 50 | the 15 Oct read's design |
| 13 | **The gamble** | its finds' item level never past the drops' at the same point, and a tin at the gamble never buys more item level than a tin's worth of runs | parked item 15 |
| 14 | **Cash sink** | cash in hand at the end no more than 2 hours' income | kept |
| 15 | **Scrap** | scrap earned an hour worth 0.5-7 of the dearest craft (the Scrapper 8) | kept |

Not gates, judged at Matt's playtest of the passed build: deaths (a death one run in 10-30; first death by hand about
2 h 45 at twice the campaign) and wounds (5-30% of runs) - the bot at its odds doesn't take a player's risks, so its
deaths and wounds say nothing. Shown in the summary beside the gates, unjudged.

Retired with the structure they measured: the keystone by hour 2 and the capstone by hour 5 (now levels 20 and 30:
gates 4 and 5), depth pace (the depth buttons went: gate 6), the lorry by 16 (gate 7), the ladders' spread (signals).

## How it felt: gates judged on play as well as the bot (19 Oct)

Matt's playtest of 18 Oct played green on the bot's gates and still felt wrong: he reached the Barracks five levels
under its gear, could wear a third of what dropped, took no wound in 26 runs, and made more from the Fence's contracts
than from running. The bot plays slower than he does and grinds levels, so its reads missed all four.

The pass now works like this:

1. Every playtest: `tools\playtest.bat` writes docs\balance\playtest.md, whose "How it felt, judged" table holds the
   gates below, judged on Matt's record.
2. Every balance pass: docs\balance\summary.md carries the same rows, "(as played)", judged on every element read of
   the bot (green when every read is). One reader, tools/feel_gates.gd, does both.
3. A gate is green only when the bot and Matt's latest playtest are both green. A red in play that's green on the bot
   is the bot playing unlike Matt: the bot's play is fixed first (its pace, when it moves on), then the numbers.

| Gate | Green when |
| --- | --- |
| Level on entry | at each site's first clear from the Parade, within 1 under and 3 over its gear's level |
| Gear to wear | 60% or more of the campaign's plain gear finds wearable as they drop (PROPOSED) |
| Wounds | 5-30% of runs |
| Deaths | one run in 10-30, judged from 30 runs |
| Contracts against runs | the Fence's contracts' tins at most 50% of the runs' tins (PROPOSED) |

Read off Matt's 18 Oct record (at the new 2 x - 2 wear): level on entry green, gear to wear 35% RED, wounds 0% RED,
deaths too few runs to judge, contracts 382% of the runs' tins RED. A one-hour bot read (fire Drifter): level on entry
RED the other way (the Bank at 15 against its gear's 10), the rest green.
