# Working rules for Fiat

Matt's standing conventions for any session on this repo (house rule, 21 Oct: they live here so they survive a new
chat or a compacted one). Read this first. Design is in docs/design/ (the statement: docs/design/vision.md); what's
been done and why is docs/status.md.

## Stop checks (28 Oct, Matt: "plug the gap" - three CLAUDE.md rules missed in one day; the sixth 31 Oct, the seventh 2 Nov)

This file isn't loaded by itself in a cloud session (it reaches the repo over the device bridge), so these are the
moments to come back to it. Each was missed at least once.

1. **After a compaction, or in a new chat**: read this file, then the newest entries in docs/status.md, before
   anything else. A summary carries memory of the rules, not the rules (21 Oct, 28 Oct).
2. **Matt raises anything new**: the first line of the reply says which it is - a bug, a UI change, or new. New goes
   to docs/design/ideas_backlog.md (or gets "no, because" against docs/design/vision.md) before any design or mockup
   (28 Oct: the trips designed the afternoon they were raised).
3. **Before dropping any flag**: read its row in docs/running.md - not the last flag dropped (28 Oct: `32` dropped
   where `24 1` was the rule).
4. **Before giving Matt a command to run**: is there a flag or a handoff for it? (28 Oct: an art run line, where
   `art.flag` is the way.)
5. **Any word on a mockup, a screen, or to Matt**: the glossary in docs/language/style_guide.md - talk to Matt in the
   game's words, not the code's (28 Oct: "Depth 3" on the trips boards, then "depth 5-15" in a chat answer; depth is
   internal only, the player reads a site's level).
6. **Before any build in the cloud, and before delivering one**: the cloud base must be the repo's HEAD, file by file -
   md5 every file the build will touch, cloud base against Matt's machine, and re-sync any that differ before work
   starts; at delivery, check again (Matt's side may have moved: a doc Claude edited on the device, his own change)
   and 3-way merge what differs, never overwrite (31 Oct: a stale menu.gd in the cloud base failed the version check
   through two builds; docs/running.md edited on the device conflicted with a builder's copy at delivery).
7. **Every delivery commit, and every art manifest**: in the same commit, docs/status.md gets the dated entry (what
   changed, Matt's words that asked for it, the commit) and its "Now, next, parked" board at the top is brought up to
   date; a new manifest goes with its `art.flag` (2 Nov: 0.10.4-0.10.6 shipped with no status entry; 1 Nov: the
   Copper cable manifest sat without its flag).

## No balance passes until Matt has played through (2 Nov, Matt)

"I don't think there's any point running any more balancing until I've played thru to county and fiat etc. we keep
getting wasting cycles on balancing, changing stuff and then running a pass." No balance pass (quick, full or long)
is dropped until Matt has played a save through to the County and the Issue (fiat) and says one is wanted. Findings
that would need a pass go on the status board's "For the balance pass" list instead.

## Before you start (28 Oct, Matt: "we just need to reduce the misses here")

At the start of every work item, and after every compaction, find its row and read what it names before writing
anything. A row's doc is the procedure: a summary of a long chat drops it (28 Oct: an art manifest was handed to Matt
to run by hand, the `art.flag` handoff missed for want of reading pixellab_lessons.md).

| Work | Read first | Hand it off / run it with | Then |
|---|---|---|---|
| Any change to the game | "How work goes in" and "Talk first" below | `smoke.flag` (the watcher, below) | the reviewer on the diff; commit only on a green smoke |
| UI | "How work goes in" (mockups, the assertion rule) | the design canvas, rendered and checked first | a smoke assertion for every UI fix |
| New words on screen | docs/language/style_guide.md | the language pass (two reviewers, an editor's call) | fold the calls into the design doc |
| Voiced lines (story, room intros, Kev) | docs/voice/recording_list.md | Matt records them | add a changed line to the list |
| Art (a manifest) | docs/art/pixellab_lessons.md | `python3 tools/art_lint.py`, then `docs/art/handoff/art.flag` | read `art.done`, wire what isn't found by name |
| Balance | docs/running.md and the balance lines in "How work goes in" | `balance.flag` (`16 1 quick` while iterating) | read docs/balance/summary.md against Matt's latest save |
| A save's shape | "How work goes in" (old saves) | bump `SAVE_VERSION` in scripts/ui/main.gd | |
| A build Matt plays | "The project manager" (the version) | bump `VERSION` in scripts/ui/menu.gd in that commit | |
| A playtest item | "How work goes in" (parked) | docs/status.md's parked list | built only when Matt says |
| Anything new Matt raises | "The project manager" (the plan, the creep rule) | docs/design/ideas_backlog.md | say where it went, or "no, because" |
| A mockup | the style guide's glossary; "How work goes in" (rendered first) | the design canvas | Matt's word before the build |

## Running things - on Matt's machine, never the cloud

The watcher (`tools\watch.bat`, a window Matt leaves open) runs one job at a time from flag files in `docs\balance\`.
The full procedure for each, and the cloud fallbacks, are in docs/running.md: read a job's row there before its flag.

| Job | Drop | Read |
|---|---|---|
| Smoke (~2 min) | `smoke.flag`, empty | `smoke.txt`'s last line, a new `smoke.done` |
| Balance, iterating | `balance.flag` with `16 1 quick` (~25 min: each read capped at 20 min of wall, no gauntlet) | `summary.md` (its header names the capped reads), a new `balance.done` |
| Balance, a final | `balance.flag` with the hours, e.g. `32` (two reads a build) | the same |
| Broken builds / build hunt | `balance.flag` with `0 0 broken` / `2 0 hunt` | `broken.md` / `hunt.md` |
| Playtest read | `playtest.flag` with a save path | the playtest summary, `playtest.done` |
| Art | `docs/art/handoff/art.flag` (docs/art/pixellab_lessons.md) | `art.done` |

No smoke while a balance pass runs. gdlint 0 before any commit (`tools/gdlint.py`).

## How work goes in

- Do the job asked first. Something else caught on the way: stop and talk about it before fixing it - no unasked-for
  fixes bundled in. It's a two-way street.
- The three-stage review (game, UI, tests and tools: docs/review/<date>/{game,ui,tools}.md, three agents side by
  side, each finding fixed or put to Matt) runs after every major step and before any balance pass (29 Oct, Matt: "the
  three stage review on changes should be run after every major step and before balance. We've previously encountered
  issue with changes that have impacted balance and required another run"). The per-diff reviewer stays as well.
- A reviewer agent reviews every commit's diff before it's committed; in balance work only code changes (bot,
  harness, sim), not pure number tweaks.
- During a playtest, every item Matt raises is parked, not fixed: logged in docs/status.md's "Parked from the
  playtest" list (what he saw, his words) and taken up together once the playtest's done (21 Oct). No fixes, builds
  or smokes mid-playtest unless he says otherwise.
- Playtest feedback: design it together, UI mockups on the design canvas (standard for any UI work), implement, smoke
  on Matt's machine, reviewer, revise until clean, commit; one thing at a time.
- A UI bug (clipping, overlap): fix it and add the assertion that would have caught it.
- New words on screen (perk names and lines, items, chips, any player-facing string) get the language pass before they
  go in (22 Oct): two reviewer agents, each briefed with docs/language/style_guide.md and the existing names (clashes),
  then an editor's call on their lists; the calls folded into the design doc. Rules of thumb they enforce: "head" is a
  site's boss only; figures, never words; the glossary's one name a thing.
- A mockup is rendered and checked before it goes to Matt (22 Oct: a band came to him twice with its text
  overflowing). Draw the board at the game's size (1920 x 1080, the band 1532 wide beside the 320 rail), render it
  headless (the scratchpad's shot_web.py: Chromium, no text wider than its box), look at the screenshot, then publish.
- Balance: features first, every number change in before the pass, gates chosen up front; no RED left as an accepted
  known issue. Judged on the element builds; plain builds only have to finish. Bot-timing gates aren't tuned before a
  playtest. The broken builds (docs/design/broken_builds.md) sit outside it (the read switches them off).
- One bot pass, then Matt's playtest, and iterate from his play - not pass after pass with bots his play upends.
  A second pass only when the first shows something drastically wrong (a runaway, a wall, an unwinnable stretch).
- Balancing: always read Matt's latest save alongside the bot's figures, as the comparison (his saves:
  `C:\Users\mattc\AppData\Roaming\Fiat`; `tools\playtest.bat` / `playtest.flag` summarises one).
- While iterating: `balance.flag` with `16 1 quick` (28 Oct: 16 h, one read a build, each stopped at 20 min of wall, no
  gauntlet; ~25 min against a full pass's ~1 h 40). A final: `32` (two reads a build, the gauntlet).
- Old saves: no compatibility work. When the save's shape changes, bump `SAVE_VERSION` in scripts/ui/main.gd so the
  old slot shows the incompatible-save warning. A change that would leave an old save wrong (not just a new shape)
  gets the same bump, without asking: Matt never cares if a save breaks (23 Oct).
- docs/status.md is Claude's: keep it current as the work goes. Docs Claude wrote are Claude's to update.

## The project manager (22 Oct, Matt: "I'm assigning you the official role of project manager ... carry versioning
## and act as a creep warden")

- Matt is design director; Claude runs the project: the plan, the version, the scope, the parked list, the order of
  work, and says so when something asked for breaks the plan. Design calls stay Matt's. The plan's history:
  docs/pm_history.md.
- **The plan in force (28 Oct**, Matt: "I haven't even played the game from fresh to county and pinnacle yet so that
  needs to come first before anything else. Outside of bug fixes of course"):
  1. The balance pass on c252141 read; then Matt plays from a fresh camp through the County and a pinnacle.
  2. While he plays, only bug fixes and UI changes are taken, parked, built after the playtest.
  3. Then docs/design/ideas_backlog.md's queue: the itemisation first (29 Oct), the trips (docs/design/trips.md) next,
     the rest behind them. Matt logs each gun he holds and for how long, the rework's before picture.
- **Changed 29 Oct** (Matt overruled in words: "I won't be able to playtest for 3/4 days so rather than that being dead
  time I say we build everything as planned ... that really is the last build until I play again"): the compare (A),
  the itemisation and the trips are built now, in the queue's order, on his go; then he plays that build from fresh.
- **The creep rule**: a feature, system, rework or activity Matt raises goes to docs/design/ideas_backlog.md with the
  date and his words, not into the build or a design, and Claude says where it went. Claude refuses and pushes back on
  what doesn't fit docs/design/vision.md or the plan, and says why (Matt, 28 Oct: "simply push back and refuse things
  I might raise that don't fit the vision"). It comes back when the queue reaches it or Matt overrules in words. A parked
  fix that grows a feature in the designing: the fix goes in, the growth to the backlog.
- Balance passes are bought time: shorter reads while iterating, the full pass for a final.
- The version (scripts/ui/menu.gd VERSION, shown on the title): 0.<milestone>.<build>; the build counts the commits
  Matt plays within a milestone. 0.11.0 is current (the milestones' list: docs/pm_history.md). SAVE_VERSION is its own
  count. Claude bumps the version in the commit Matt plays and notes it in docs/status.md.

## Talk first (23 Oct, Matt: "lets talk before you blindly start doing stuff")

- "Let's sort X out" is a conversation, not a go: say what's wrong, what I'd do and why, then wait for the word. No
  debugging, no commands, no fixes until the approach is agreed.
- A smoke failure is reported first - the cause and the proposed fix - before anything is touched. A fix explained in
  that report may then be applied and the smoke re-run without asking again; a new failure starts the loop over.
- A mockup needs Matt's word before the build, every time, even inside a batch he approved as a whole. "Do
  everything" is the list, not the designs.
- No sleep or poll loops in the device shell while Matt's about: they block his messages. Drop the flag, say so, and
  read the result when he says it's done (or on the next turn).

## Git

- Add files by explicit list, never `git add -A`.
- Leave Matt's uncommitted files alone: data/fight_slots.tres, project.godot, tools/make_fight_kit_manifest.py,
  tools/pixellab_fight_kit*_manifest.json.
- Art goes into the commits (so the work reads the art Matt sees).

## Never

- Overwrite Matt's painted `art/ui/*.png`.
- Copy or read `pixellab_secret.txt` or `tools/elevenlabs_secret.txt` anywhere off Matt's machine, or commit them.
- Spend credits on generated art before the slice reads right with test art and the manifest is agreed.

## Design stances (Matt's, for any balance or design call)

- Infinite scaling is the point: players should end up having and dealing millions of HP and damage (7 Oct). A
  balance change sets the pace of the climb, never a ceiling on it.
- Player luck is the point of the itemisation: don't retune numbers off one lucky run; read fresh saves first (12 Oct).
- The bot plays the campaign the way a person does (12 Oct).
- The campaign grind is intended - it's an ARPG (13 Oct); ARPGs live and die by their length (14 Oct).
- Fiat is an auto-battler ARPG: active play - no offline progress (removed 24 Oct). The world waits while the game is
  shut. Changed 28 Oct (Matt, in words): repeat runs the player starts and trips (docs/design/trips.md) come after his
  playtest; a watched run always pays more.
- Balance is judged on element builds; plain builds only have to finish (11 Oct).

## Things to know

- Estimates (29 Oct, timed for real, Matt: "time things in real time so that moving forward you have an accurate
  estimate"): a feature of the itemisation's or the expeditions' size is about 1 h to build and about 1-1.5 h to
  review (three stages side by side) and fix, with agents in parallel; three such pieces took one day (08:46-20:09,
  two hours of it lost to a restart), against the 4-5 days estimated. Estimate in those units, not "build days".

- The cloud session's scratchpad (/tmp) is wiped when its container restarts (29 Oct, 11:10: two built features, the
  itemisation and the repeat runs, and their reviews lost before they reached this repo). Snapshot every workspace to
  /mnt/user-data/outputs/snap/ (it survives) at the end of every phase, and every agent's brief says so. A fresh cloud
  copy: `git archive` of HEAD staged up, Godot 4.7.2 from its release; with every art file in it the cloud smoke's bar
  is 0 reds.

- Voiced lines: the story, the room intros and Kev's story intro are ElevenLabs recordings. Changing their text means
  a re-record (propose the words to Matt; the text waits for his takes).
- Times to Matt in his local time: UK time (GMT from 25 Oct 2026, BST from the last Sunday in March).
- Images to Matt as files (SendUserFile), not described.
- `.bat` and `.ps1` files are CRLF (`.gitattributes`); one edited from the cloud arrives as written, so write them CRLF.
- Art tools: `python3 tools/art_lint.py [manifests]` (unique seeds, sizes, style images, nothing under art/ui/) before
  any run; `tools\art.bat <manifest>` dry-runs, then asks before spending.
- Generated art (PixelLab manifests): the lessons every manifest is checked against, the costs, and the handoff between
  the session that writes a manifest and the one that runs it (`docs/art/handoff/art.flag` -> `art.done`) are in
  docs/art/pixellab_lessons.md (23 Oct). Read it before writing, checking or running a manifest.
- The web canvases (web_view.gd and its Map and Pitch hooks) draw every node from one atlas (23 Oct, Matt's fans:
  ~2,500 draw calls a frame before). A new node mark goes through _sprite/_shape/_text, never a draw_circle or
  draw_arc per node; the smoke holds each canvas under BATCH_MAX.
