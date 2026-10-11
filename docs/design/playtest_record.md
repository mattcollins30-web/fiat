# The playtest record

*11 Oct. Matt: "did we actually log everything required? The answer is not really."*

The balance work tunes the bot against targets (`tools/balance_summary.gd`'s gates). Those targets were guesses
from Matt's notes. The record lets the targets come from a person's play instead: the same figures, read off a real
save.

## What's kept

A file beside the save: `user://fiat.record.jsonl` for the autosave, one JSON object a line. The sim gathers lines
in `sim.chronicle` and the shell appends them on every save (`main._flush_record`), so the save itself only carries
`chron_count`, `chronicle_v` and `played_s` and stays the same size however long the playtest runs. A slot save
copies the record beside the slot; loading a slot brings its record back as the autosave's. A new game (or a slot
loaded over a game) moves the old record aside as `fiat.record.<unix ms>.jsonl`, and a hardcore death writes its
line before the save is deleted, so the record outlives it.

Every line has:

| Field | |
| --- | --- |
| `k` | the kind |
| `t` | the sim's clock (seconds) |
| `p` | played: real seconds with the game open (`main._process` -> `sim.tick_played`) |
| `w` | the wall clock (unix) |
| `lv`, `cls`, `yard` | the runner's level, past, and which yard (moves + 1) |
| `away` | set when the line came out of the away settle |

The kinds:

- **run**: tier, site, depth, site level, outcome, time, kills of the pool, auto, the second past, HP max, damage,
  armour, kit worth, a wound going in, boss and convoy. On a return: loot, what was left, cash, XP, notes, scrap,
  salvage, HP lost, wounded, out of time, the way out, the clock used, searches, patrols, cleared, pack, cap. On a
  death: what was lost, what was insured, the runner's run count.
- **level**, **train**, **respec**, **class**, **ascend**
- **yard**, **yard_rank**, **build**, **atlas**
- **clear** (a first clear or a new depth), **boss**, **deeds**, **lorry**, **move**, **retire**
- **craft**, **scrap**, **gamble**, **word**, **contract**
- **paper**, **unique** (first finds)
- **equip** (slot, how: best, by hand, from the pack; what went on and came off)
- **heal**, **treat**
- **start**, **session** (each load: the away seconds settled, the runs it held)
- **snap** every ten minutes played: cash, money in, notes, scrap, salvage, XP, best tier and depth, points,
  spend, Yard built, map, stash, damage, max HP, armour, runs, lost, kit worth

Dry runs (the odds) write nothing. A three-hour bot run writes about 270 lines (70 KB). A long away settle on
auto-run can add a couple of thousand run lines; they go to the file, not the save, so the 30-second autosave never
copies them. Played time counts while the game is open and unpaused, focused or not (the auto-battler runs in the
background too).

## Reading it

`tools\playtest.bat [save]` (the live autosave when no path is given; its record is found beside it), or a save
path in `docs\balance\playtest.flag` for the watcher. It writes `docs/balance/playtest.md`:

1. The time: played, the sim's clock, away settled, sessions, runs live and away, runners lost.
2. Milestones by played hours: first clears, depths, bosses, the deeds, the lorry, moves, levels, the first
   keystone and capstone, class changes, the first death.
3. The gates read from play, beside the bot's targets: the bank, keystone, capstone, lorry, deaths, wounds, the
   clock, the way out, depth pace.
4. Runs site by site.
5. The curve, half hour by half hour.
6. Where the money and points went, and the Yard in the order built.
7. The kit as it changed.

The raw record file is there for anything the page doesn't show.
