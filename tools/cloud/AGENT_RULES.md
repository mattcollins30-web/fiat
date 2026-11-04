# Rules for every builder and reviewer on Fiat (29 Oct)

S = the session scratch folder (tools/cloud/env.sh); the scripts below are tools/cloud/*.sh copied there

- The game: Godot 4 project, a copy of the designer's repo HEAD. Base for diffs: $S/b29 (never write to it).
- Work only in your own workspace folder(s) named in your brief. Never touch another builder's folder, b29, or anything
  outside $S except the snapshot folder below.
- **Snapshots (the container's /tmp was wiped once today, losing two builds):** at the end of every phase, and at least
  every 30 minutes of work, run `$S/snap.sh <your workspace folder name>` (it tars it, without .godot and art, to
  /mnt/user-data/outputs/snap/). Your last act before reporting is a snapshot.
- **Smoke:** `$S/smoke.sh <workspace> [-- only <area> ...]` runs the full smoke with Godot 4.7.2 under xvfb (about
  2 min; give the Bash tool a 600000 ms timeout). The bar is **0 failed checks, 0 SCRIPT ERROR, "all labels fit"** -
  every art file is in the copy. The log is `$S/<workspace>.smoke.log`.
- **Lint:** `$S/lint.sh <workspace> <port>` runs the project's own warnings check (tools/gdlint.py via Godot's language
  server, about 2.5 min). TOTAL must be 0. Use a port of your own (given in your brief) so two runs don't collide.
- Read first: <workspace>/CLAUDE.md (the Stop checks, "How work goes in"), <workspace>/docs/language/style_guide.md
  (player-facing words: "level" never "depth" on screen; glossary names, one name a thing; mechanics voice - in a chip
  or affix line the number leads, in a sentence the effect leads; sentence case; a real minus sign; no brands).
- Every UI change gets a smoke assertion (it fits its box, it shows the right thing). A fix to a bug gets the check that
  would have caught it, and that check must fail without the fix (try it).
- No vacuous checks (a `not X or ...` guard, a loop over an empty list, a fixture that never reaches the state).
- Keep changes self-contained so parallel builds merge: append new functions near related ones, new smoke areas as
  their own functions, no refactoring of code you don't need to touch.
- Note start and end times (`date -u`) for each phase: the designer wants real build times.
- You can't talk to the designer. Questions go in your report with your recommendation; where the docs leave
  something open, decide sensibly and list the decision.
- Report: times, files changed, new player-facing words (a list for the language pass), decisions, questions, the
  smoke and lint results, the snapshot name.
