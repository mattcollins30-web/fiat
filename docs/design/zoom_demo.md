# The live demo for Zoom's AI champions (plan, 7 Nov; pick up Monday 9 Nov)

Matt has been invited into Zoom's AI champions team and will demo the process next week: what's been built, then live
- he asks for a change, the bots build and review it, the smoke check fails first (proving it catches the problem),
the change makes it pass, and the game shows it. Transparent, not cooked up beforehand, all under 5 minutes.
Nothing below is built yet.

## The problem today

| Step | Today | Problem |
| --- | --- | --- |
| The watcher sees the flag | up to 15 s | tools/watch.bat looks every 15 s |
| The smoke | 5+ min on the Legion | every area, one after another (~290) |
| Claude's side | minutes | built in the cloud workspace, then delivered and md5-checked |
| The reviewer | 1-2 min | can run while the smoke runs |

## The plan

1. **A targeted smoke on the watcher.** smoke.flag's contents name the areas (`-- only <area> ...`, which the smoke
   already takes); empty runs the whole smoke as now. The watcher looks every 2 s. Tooling only, ~30 min.
2. **The full smoke in parallel.** The areas are independent: split across 4 Godot processes, the full smoke should
   drop from 5+ min to ~1.5 min on the Legion. Pays back on every build, not just the demo.
3. **Demo day: work on the Legion directly** (device shell) for a small change - no cloud workspace, no delivery step,
   everything in the repo the audience is watching. A demo-day setup to rehearse, not a change to the everyday process
   (the cloud workspace and the md5 base check keep Matt's copies safe day to day).

## The five minutes

| Time | On screen |
| --- | --- |
| 0:00 | Matt asks for the change, out loud |
| 0:30 | Claude writes the check first; the targeted smoke runs it and it FAILS - the game doesn't do it yet (red proved, not staged) |
| 1:30 | Claude makes the change; the reviewer reads it while the check runs again and PASSES |
| 2:30 | The commit; `git log` on screen |
| 3:00 | Matt boots the game and shows the change, then the rest of it |

## Keeping it honest

- The audience picks the change, inside one rule said up front: one item, one word, one number or one colour.
- The watcher window, the smoke's output and `git log` stay on screen.
- Rehearse the process (one or two dry runs with different changes), never the change itself.

## Monday

Matt's go on 1 and 2; then a dry run of 3 together.
