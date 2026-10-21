# Working rules for Fiat

Matt's standing conventions for any session on this repo (house rule, 21 Oct: they live here so they survive a new
chat or a compacted one). Read this first. Design is in docs/design/ (the statement: docs/design/vision.md); what's
been done and why is docs/status.md.

## Running things - on Matt's machine, never the cloud

The watcher (`tools\watch.bat`, a window Matt leaves open) runs jobs from flag files in `docs\balance\`:

| Job | Drop | Runs | Results | Done |
|---|---|---|---|---|
| Smoke | `smoke.flag` (empty) | `tools\smoke.bat` (~1.5 min) | `docs\balance\smoke.txt`; last line is the verdict | `smoke.done` (a timestamp) |
| Balance pass | `balance.flag` with the hours in it, e.g. `24` | `tools\balance.bat <hours>`: every element build and plain class twice, plus the loot probe, side by side | `docs\balance\<build>-N.txt` (half-hour lines, purchases, a `GATES {json}` line), the summary `docs\balance\summary.md` | `balance.done`, each read `<build>-N.done` |
| Playtest read | `playtest.flag` with a save path (or empty) | `tools\playtest.bat` | the playtest summary | `playtest.done` |

- From a cloud session the smoke is `bash $HOME/flaky/run.sh N` in the device shell: it drops the flag, waits for a
  fresh `smoke.done`, copies the log to `$HOME/flaky/smoke_N.txt` and greps `CHECK FAILED\|SCRIPT ERROR`. Check the
  done timestamp is new (it's Matt's local time, UTC+1).
- The watcher runs one job at a time: no smoke while a balance pass runs.
- Long sim and balance runs are Matt's machine's (6 Oct: it's about twice as fast). One quick read between passes:
  `tools\read.bat <hours> <class> [element]`.
- gdlint shows 0 before any commit (`tools/gdlint.py`).

## How work goes in

- Do the job asked first. Something else caught on the way: stop and talk about it before fixing it - no unasked-for
  fixes bundled in. It's a two-way street.
- A reviewer agent reviews every commit's diff before it's committed; in balance work only code changes (bot,
  harness, sim), not pure number tweaks.
- Playtest feedback: design it together, UI mockups on the design canvas (standard for any UI work), implement, smoke
  on Matt's machine, reviewer, revise until clean, commit; one thing at a time.
- A UI bug (clipping, overlap): fix it and add the assertion that would have caught it.
- Balance: features first, every number change in before the pass, gates chosen up front; no RED left as an accepted
  known issue. Judged on the element builds; plain builds only have to finish. Bot-timing gates aren't tuned before a
  playtest. The broken builds (docs/design/broken_builds.md) sit outside it (the read switches them off).
- One bot pass, then Matt's playtest, and iterate from his play - not pass after pass with bots his play upends.
  A second pass only when the first shows something drastically wrong (a runaway, a wall, an unwinnable stretch).
- While iterating, one read a build is enough (`balance.flag` with `24 1`, about half the time); two for a final.
- Old saves: no compatibility work. When the save's shape changes, bump `SAVE_VERSION` in scripts/ui/main.gd so the
  old slot shows the incompatible-save warning.
- docs/status.md is Claude's: keep it current as the work goes. Docs Claude wrote are Claude's to update.

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
- Fiat is an auto-battler ARPG: active play; the away settle is the only idle system (11 Oct; auto-run removed 21 Oct).
- Balance is judged on element builds; plain builds only have to finish (11 Oct).

## After a compaction or in a new chat

Re-read this file, then the newest entries in docs/status.md, before carrying on. A compacted summary has dropped
standing rules before (21 Oct: balance reads were run in the cloud against the rule above).

## Things to know

- Voiced lines: the story, the room intros and Kev's story intro are ElevenLabs recordings. Changing their text means
  a re-record (propose the words to Matt; the text waits for his takes).
- Times to Matt in his local time, UTC+1.
- Images to Matt as files (SendUserFile), not described.
