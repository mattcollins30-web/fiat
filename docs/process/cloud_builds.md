# Cloud builds - the repeatable process (4 Nov 2026)

How a feature or fix round goes from Matt's word to a commit on his machine when Claude builds it in a cloud session
with builder agents. The rules it serves are CLAUDE.md's ("How work goes in", "Running things", the Stop checks); this
is the mechanics. The scripts are in tools/cloud/ (copy them into the session's scratch folder; set `S` in env.sh).
Matt asked (4 Nov): "The tooling for repeatable game dev, did you put it into a document?" - this is it.

## The pieces

| Piece | Where | What it's for |
|---|---|---|
| env.sh | tools/cloud | S (the scratch folder), GODOT (4.7.2, as on Matt's machine), SNAP (the durable snapshot folder) |
| setup.sh | tools/cloud | a base workspace from Matt's HEAD + his untracked art; Godot; one import pass |
| smoke.sh | tools/cloud | the full smoke under xvfb (or `-- only <area>`); 10-25 min - run it in the background |
| lint.sh | tools/cloud | tools/gdlint.py through Godot's language server; TOTAL 0 |
| snap.sh | tools/cloud | a workspace to the durable outputs folder (/tmp is wiped on a container restart) |
| merge.sh | tools/cloud | 3-way merge of a builder's workspace into the merge workspace |
| canvas_look.sh | tools/cloud | a mockup board rendered in the real canvas viewer, for the fit check |
| AGENT_RULES.md | tools/cloud | the rules every builder and reviewer agent reads first |
| example_*.md | tools/cloud | the briefs as written for build 48/49: a common brief, a builder's, a canvas round's, a language pass |

## 1. The base (Matt's HEAD, never written to)

1. On Matt's machine (the device shell): `git archive -o .stageNN/head.tar HEAD`, and his untracked art
   (`git ls-files --others --exclude-standard art | grep -vi secret` into a tar). Never a secret file.
2. Stage both tars up; `tools/cloud/setup.sh bNN head.tar art_untracked.tar`. Delete .stageNN on his machine after.
3. Matt's saves, if the work needs them: stage from `C:\Users\mattc\AppData\Roaming\Fiat` into `$S/savesNN/`.
4. Disk: the cloud's allowance is fixed; delete old workspaces before a new base (snapshots keep them).

## 2. The briefs

- A common brief (example_BUILD_COMMON.md): the base, the workspaces and lint ports, the bar (smoke 0 failed / 0
  SCRIPT ERROR / all labels fit, lint 0, a check that fails without each fix, a fit check for each UI change), who owns
  which files (so the merge is clean), the report's shape (times, files, new words, decisions, questions with a
  recommendation, results, snapshot, diff) and a word limit.
- One brief per builder (example_BUILD_brief.md): the items by their status.md numbers, Matt's picks, what's not theirs.
- When one builder needs another's API: the provider writes `$S/<ws>_notes.md` with "API READY" at its top; the other
  stubs in a marked block at the very end of the file until then.
- Two or three builders at once on the cloud's 2 CPUs; frame-time checks flake under that load - judge them alone.

## 3. Build, merge, check

1. Builder agents in parallel (the Agent tool), each in its own workspace copied from the base.
2. Merge: copy the first builder's workspace to mNN, `merge.sh bNN mNN <next>` for each other, resolve conflicts
   (appended blocks at one spot: keep both), **copy the base's .godot into mNN** (without the imports the smoke fails
   on every font and picture).
3. The full smoke on mNN in the background (`nohup tools/cloud/smoke.sh mNN &`), poll until the verdict line; lint.
4. The reviewer: one agent on the merged diff (`diff -ruN --exclude=.godot --exclude='*.import' bNN mNN`), briefed
   with the items' intent and the rules, asked for verified findings most severe first. A builder fixes them in mNN.
5. The language pass on every new player-facing string (example_LANG_brief.md): two reviewer agents side by side,
   then the editor's call (Claude's), applied in mNN.
6. After a major step: the three-stage review (game, UI, tools) as CLAUDE.md says.

## 4. Delivery to Matt's machine

1. The Stop check 6: md5 every file the build changes, the base's copy against Matt's working tree; any that differ,
   3-way merge first - never overwrite his work.
2. Copy the changed files into `/mnt/user-data/outputs/dNN/` at their repo paths; `device_commit_files` with each
   `stagedPath` (a fresh dNN folder each time - a reused path isn't re-uploaded).
3. The smoke on his machine: `mv -n smoke.done smoke.done.<tag>`, `touch docs/balance/smoke.flag`, wait for a new
   smoke.done, read smoke.txt: "all labels fit, all checks pass" and no CHECK FAILED / SCRIPT ERROR.
4. Commit with an explicit file list (never `git add -A`; never Matt's uncommitted files), `timeout 100 git commit`,
   the trailer. docs/status.md's dated entry and its board in the same commit. Version bump only in a build Matt plays.
5. Git on his machine leaves lock files when deletes aren't allowed: ask once for delete permission on the repo
   folder, or move a stale lock aside under .git.

## 5. Mockups (the design canvas)

1. A Design artifact per round; the boards as `.dc.html` files at the game's size.
2. Pictures: copy them into the scratch folder (a batch upload refuses files outside it), upload them as the
   artifact's assets, and swap each `./x.png` for its `/_blob/<id>`.
3. Fit-check every board with canvas_look.sh and look at the screenshot before Matt sees it (22 Oct).
4. Matt picks; the picks go into status.md's board before the build.

## 6. Matt's saves

- His saves: `C:\Users\mattc\AppData\Roaming\Fiat` (fiat.save, the autosave; fiat_slotN.save, his slots;
  fiat.record.jsonl, the run record - read it for what happened and when).
- A dead runner's worn kit is kept in the save's `loose_kit` (who, run, the whole item): putting it back is moving
  those entries into `stash` (4 Nov, the Doorman's eight pieces). Back the save up beside it first
  (`*.before_<what>_<date>`), and only with the game shut (the autosave every 30 s overwrites).

## Lessons (each cost time once)

- A smoke cut by its timeout prints "fails 0" with no verdict: read the last line, not the count.
- A copied workspace without .godot/imported fails on fonts (`has_char` on null) and draws text at the wrong size.
- A Control can't shrink below its old minimum size in the same call: set the minimum first (item 8, 4 Nov).
- Frame-time checks: judge a percentile with a pace scale, never a single frame's wall clock.
- A builder's "the old check passes" can mean the check never reached the state - prove each check red first.
