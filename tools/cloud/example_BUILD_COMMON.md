# Build 49 (4 Nov): 0.13.0 phase 1 - the skill web version two, its screen, and the fix round's UI reworks

S = /tmp/claude-0/-home-claude/17fbe8af-3b8e-5c47-af2f-5ddb8fb0f07d/scratchpad

- Read: $S/AGENT_RULES.md (wherever it says "b29" read **b49**); $S/b49/CLAUDE.md (Stop checks, "How work goes in");
  $S/b49/docs/language/style_guide.md; and your brief's design docs.
- Base: $S/b49 = Matt's repo HEAD (4d98e3f: 0.12.2 plus the fix round's part 1) plus every art file. **Never write
  to it.** `cp -a $S/b49 $S/<ws>`. Snapshot `$S/snap.sh <ws>` every 30 min and last.
- Three builders at once on 2 CPUs: W (the web's rules, ws w49, lint port 6060), V (the Training screen, ws v49, port
  6061), U (the UI reworks, ws u49, port 6062). Smoke with `-- only <area>` while working, the full smoke
  (`$S/smoke.sh <ws>`, timeout 600000) at the end. Bar: 0 failed, 0 SCRIPT ERROR, "all labels fit"; lint TOTAL 0.
- Every fix or feature gets a smoke check that fails without it (try it); every UI change a check it fits and shows
  the right thing. No vacuous checks. Your own new smoke functions; change existing areas only where your change breaks
  them, and list each.
- The split, so the three merge: W owns scripts/sim/data.gd, scripts/sim/sim.gd's web rules, the layout data and its
  generator, tests/bot.gd, the save (SAVE_VERSION 24 in scripts/ui/main.gd; W owns that one line). V owns
  scripts/ui/web_view.gd, web_key.gd, barracks.gd's Training parts, node_glyphs.gd. U owns the other screens it's
  briefed on. words.gd: append your own keys only. smoke.gd: your own functions. If you must touch another's file, keep
  the edit minimal and list it.
- Until W's sim lands, V stubs the web API it needs (a block at the very end of sim.gd / data.gd between
  `# --- V49 STUB (the merge drops this) ---` and `# --- end V49 STUB ---`), reading docs/design/skill_web_layout.json.
  W writes $S/w49_notes.md as it goes and "API READY" at its top when the API's in and the game boots; V then copies
  W's sim.gd, data.gd and layout files over its own and re-runs.
- New player-facing words: list every one in your report (a language pass follows).
- Report (keep it under 500 words): times, files, new words, decisions, questions with your recommendation, smoke and
  lint results, the snapshot, and `diff -ruN --exclude=.godot --exclude='*.import' $S/b49 $S/<ws> > $S/<ws>.diff`.
