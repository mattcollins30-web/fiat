# Working rules for Fiat

Matt's standing conventions for any session on this repo (house rule, 21 Oct: they live here so they survive a new
chat or a compacted one). Read this first. Design is in docs/design/ (the statement: docs/design/vision.md); what's
been done and why is docs/status.md.

## Running things - on Matt's machine, never the cloud

The watcher (`tools\watch.bat`, a window Matt leaves open) runs jobs from flag files in `docs\balance\`:

| Job | Drop | Runs | Results | Done |
|---|---|---|---|---|
| Smoke | `smoke.flag` (empty) | `tools\smoke.bat` (~1.5 min) | `docs\balance\smoke.txt`; last line is the verdict | `smoke.done` (a timestamp) |
| Balance pass | `balance.flag` with the hours in it, e.g. `32` | `tools\balance.bat <hours>`: first the Radio's checkpoint (a new game to the Radio, `radio_checkpoint.save`), then side by side every element build as one save from the Poacher (its class taken when it opens) twice, every build 4 h from the checkpoint (`parity-*.txt`, `PARITY {json}`), and the loot probe (25 Oct) | `docs\balance\<build>-N.txt` (half-hour lines, purchases, a `GATES {json}` line), the summary `docs\balance\summary.md` | `balance.done`, each read `<build>-N.done` |
| Playtest read | `playtest.flag` with a save path (or empty) | `tools\playtest.bat` | the playtest summary | `playtest.done` |

- From a cloud session the smoke is `bash $HOME/flaky/run.sh N` in the device shell: it drops the flag, waits for a
  fresh `smoke.done`, copies the log to `$HOME/flaky/smoke_N.txt` and greps `CHECK FAILED\|SCRIPT ERROR`. Check the
  done timestamp is new (it's Matt's local time, UTC+1). The verdict is run.sh's own "run N (done ...)" line, never
  `smoke_N.txt` read on its own: the numbers wrap and an old run's file sits there (23 Oct: runs 61-63 read "green" off
  the 19th's files while the smoke hung). A run that writes no done file within run.sh's wait has hung: find where
  `docs/balance/smoke.txt` stopped, and the hung Godot has to be killed on Matt's machine before the next flag.
- The watcher runs one job at a time: no smoke while a balance pass runs.
- With the watcher off, a cloud session runs the full smoke in the cloud on a snapshot of its copy (xvfb, opengl3). Its
  known cloud-only reds are art the cloud copy lacks: gang faces, muzzle flashes, the Recruit's portraits, item
  pictures (a cell's words standing in, e.g. 'AMO'); every other red is real.
- Long sim and balance runs are Matt's machine's (6 Oct: it's about twice as fast). One quick read between passes:
  `tools\read.bat <hours> <class> [element]`.
- gdlint shows 0 before any commit (`tools/gdlint.py`).

## How work goes in

- Do the job asked first. Something else caught on the way: stop and talk about it before fixing it - no unasked-for
  fixes bundled in. It's a two-way street.
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
- While iterating, one read a build is enough (`balance.flag` with `24 1`, about half the time); two for a final.
- Old saves: no compatibility work. When the save's shape changes, bump `SAVE_VERSION` in scripts/ui/main.gd so the
  old slot shows the incompatible-save warning. A change that would leave an old save wrong (not just a new shape)
  gets the same bump, without asking: Matt never cares if a save breaks (23 Oct).
- docs/status.md is Claude's: keep it current as the work goes. Docs Claude wrote are Claude's to update.

## The project manager (22 Oct, Matt: "I'm assigning you the official role of project manager ... carry versioning
## and act as a creep warden")

- Matt is design director; Claude runs the project: the plan, the version, the scope, the parked list, the order of
  work, and says so when something asked for breaks the plan. Design calls stay Matt's.
- The plan as set (22 Oct): 1. Matt's playtest of the web build. 2. Every parked item (docs/status.md's "Parked from
  the playtest" lists, oldest first), designed together, built, smoked, committed. 3. Then balance and nothing else:
  the endgame's shape, the gates, the passes, Matt's playtests, until the game's balanced. Nothing new goes into the
  build in phase 3.
- Changed 24 Oct (Matt overruled in words: "Our skill tree has no skills and fights devolve into watching bats and
  clicking meds"): milestone 8 is active skills and energy, the sixth class (the Recruit), the unlock order and the
  Pitch's tree, per docs/design/skills.md; balance moves to milestone 9 and starts once 8 is in.
- The creep rule: a new feature or system raised after phase 2 begins goes to docs/design/ideas_backlog.md with the
  date and Matt's words, not into the build, and Claude says where it went. It comes back when phase 3 is done or
  Matt overrules in words. A parked item that grows a feature in the designing is the same: the fix goes in, the
  growth goes to the backlog. Something that changes numbers (a class, a node, a rule) belongs before the balance
  phase or after it, never during.
- The version (scripts/ui/menu.gd VERSION, shown on the title): 0.<milestone>.<build>. The milestone counts the
  systems that changed what the game is - 1 the first slice, 2 the tree, 3 depth and intel, 4 the Yard, 5 the
  Radio's endgame, 6 the crew, 7 the web; the build counts the commits Matt plays within it (a playtest build bumps
  it). The web build Matt is playing is 0.7.0; the parked-list build after it 0.7.1 and so on; milestone 8 is the
  skills (docs/design/skills.md; 0.8.0 its first build to play, 24 Oct), and the balance phase starts milestone 9. SAVE_VERSION is its own count and stays so. Claude bumps the version in the commit Matt plays
  and notes it in docs/status.md.

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
- Fiat is an auto-battler ARPG: active play, no idle systems - no offline progress (removed 24 Oct; auto-run removed 21 Oct). The world waits while the game is shut.
- Balance is judged on element builds; plain builds only have to finish (11 Oct).

## After a compaction or in a new chat

Re-read this file, then the newest entries in docs/status.md, before carrying on. A compacted summary has dropped
standing rules before (21 Oct: balance reads were run in the cloud against the rule above).

## Things to know

- Voiced lines: the story, the room intros and Kev's story intro are ElevenLabs recordings. Changing their text means
  a re-record (propose the words to Matt; the text waits for his takes).
- Times to Matt in his local time, UTC+1.
- Images to Matt as files (SendUserFile), not described.
- Generated art (PixelLab manifests): the lessons every manifest is checked against, the costs, and the handoff between
  the session that writes a manifest and the one that runs it (`docs/art/handoff/art.flag` -> `art.done`) are in
  docs/art/pixellab_lessons.md (23 Oct). Read it before writing, checking or running a manifest.
- The web canvases (web_view.gd and its Map and Pitch hooks) draw every node from one atlas (23 Oct, Matt's fans:
  ~2,500 draw calls a frame before). A new node mark goes through _sprite/_shape/_text, never a draw_circle or
  draw_arc per node; the smoke holds each canvas under BATCH_MAX.
