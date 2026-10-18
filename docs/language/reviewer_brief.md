# Language review brief

You are reviewing the on-screen words of FIAT, a Godot idle/extraction game set in a collapsed South Wales town.
A runner is sent from a camp (the Pitch) to sites on a map, fights gangs, brings back finds, sells to the Fence for
tins. You have not seen this game before. That is the point: read every string as a first-time player would.

Project root: the project folder (read-only for you:
do not edit any file except your output file).

Inputs:
- The house style: docs/language/style_guide.md. Read it first; it is a draft, so also flag where it seems wrong.
- Your strings: the chunk file named in your task (docs/language/chunks/*.md). Each line is
  `` `S#### L<line> [entry] [field] [w= h=] [xN]` text ``: the id, the source line, the data entry it belongs to,
  the data field, the label's box where known, and how many times it repeats. The file path is in the bold heading
  above each group. `%s`, `%d`, `%.1f` are filled in by code: read the code at that line to see what goes in.
- Screenshots of every room and state at 1920x1080: a folder of screenshots made by tests/gallery.gd (cloud only)
  (file names say the state: fresh = new camp, early = a real player's camp after 5 runs, late = everything open).
  Look at the ones for your screens with the Read tool; they show how strings combine and what sits next to what.
- The source, to check facts: scripts/sim/sim.gd (rules), scripts/sim/data.gd (numbers), scripts/ui/*.gd (screens).
  When a string states a rule or a number, check it against the code. Example of a stale fact: the Map's DEPTH tile
  says "Deeper pays, hits harder", but depths moved to Radio signals on 15 Oct: check what depth means now
  (grep "depth" in sim.gd and missions.gd) before accepting text like that.

Output: write ONE markdown file at the path in your task, with:

1. A table of proposed changes, one row per string you would change:
   `| id | screen | current | proposed | kind | reason |`
   kind is one of: clarity, fact, glossary, caps, grammar, spelling, register, duplicate, fit, cut.
   - Keep `current` exact (copy it). `proposed` is the full replacement text, with the same %s/%d placeholders in
     the same order unless the reason says the code must change too.
   - "cut" means the string (or the element showing it) should go; say why.
   - Only propose a change when it is a real improvement. No churn for taste. If the string is fine, leave it out.
   - Names (sites, people, uniques, perks, sets, crates) are flavour and keep their character: only flag a name if it
     is unclear which thing it is, clashes with another name, or breaks the caps rules.
2. A section "Duplicates per screen": for each screen, facts shown twice or more, where each shows (screenshot name +
   what), and which one to keep.
3. A section "Glossary and style guide notes": variants you found in use, and anything in the guide that the game's
   strings suggest is wrong or missing.
4. A section "Facts to check": strings whose claim you could not confirm in the code, with what you looked at.

Be thorough over your whole chunk: every line is in scope. Work through it group by group. Expect 100-300 rows for a
chunk; fewer is fine if the text is good. Finish with a one-paragraph summary at the top of the file of the biggest
problems.
