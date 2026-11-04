# Canvas 48: the fix round's UI reworks, as mockups for Matt to pick from (folder $S/ui48)

S = /tmp/claude-0/-home-claude/17fbe8af-3b8e-5c47-af2f-5ddb8fb0f07d/scratchpad

You draw design-canvas boards (.dc.html files); the coordinator publishes them. You write nothing to the game.

## Read first
- $S/b48/docs/status.md - the board's "Parked from the playtest (0.12.2, 3 Nov)" list: items 6, 12, 14, 15, 18, 19,
  21, 23, 25 are yours (Matt's words, the diagnosis, the direction agreed). Item 19 goes with item 17 (the odds counting
  the wagers) and with docs/design/act_two.md §3 (wagers offered at a night's breaks).
- $S/b48/docs/language/style_guide.md (the game's words: sentence case, figures not words, the glossary's names).
- The game's own screens as they stand: Matt's screenshots in $S/ui48/shots/ (item numbers in the names; item 19 has
  none - read scripts/ui for the wagers panel and describe/draw it as it stands from the code). The code under
  $S/b48/scripts/ui/ (site_card.gd is the overhauled card the others should follow: its picture header, the two
  portraits, "How long you last", their fire / your fire, meds and rounds, what you'll bring home, Set off).
- The house look: dark ground #15181c, cards #1d2025 with #2c3137 lines, text #eceded / #c3c8ce / #a9afb6, amber
  accent #e3a33b, good #5fc28f, bad #e0705a; Inter; the game's pixel art with image-rendering: pixelated.

## The boards (each its own file in $S/ui48/project/, at the game's size)
For each item: the screen as it stands (Matt's screenshot, placed as an image, labelled "As it stands") beside the
proposal - two proposals where the item says so or the choice is real. One board per item, named Item06.dc.html etc.,
1920 wide (the height what it needs). Draw the proposal at the game's real scale for that panel (the screenshot's
size tells you the panel's width at 1920x1080).

- Item06 - the class swap card: what the class does (its line, its skill, its two trees, its two elements), the level
  it joins at, Swap. Words: from the game's data (data.gd CLASSES, the class intros in docs/voice/scripts.md).
- Item12 - the record card in the game's art: art/ui_new/kills.png, art/ui/dps.png, art/ui/tins.png, the dearest
  find's own item picture (art/items*/<slug>.png - find the Arctic smock's or similar) and its full name.
- Item14 - the Dial with every node's picture on its box: art/nodes/map_<key>.png (data.gd ATLAS keys), map_f_<name>
  for the small ones; notables and keystones bigger and framed; the layout kept.
- Item15 - the Expeditions place card: two layouts in the site card's language (picture header - art/places/
  far_swansea.png -, the party as portraits, the cargo as item cells, one risk figure in the odds' words).
- Item18 - the death line on the site card: the Bank card from the screenshot with one line by Set off saying what
  a death costs now (before the Quartermaster: "A death: back to level 1 · the kit worn"; after: "A death: the kit
  worn, the level kept"; insured kit excepted) - show both states.
- Item19 - Kev's wagers: each wager's cost and pay side by side, the odds with and without it, what's on said on the
  site card and the fight screen; and the same offered at a night on the air's break (act_two.md §3).
- Item21 - after Kev's story: what points at the next step (Kev's last line, the Radio's Town tab, the Map's goal line
  from act_two.md §1). A small board.
- Item23 - the order's places (the Grid, the Archive, the Mint) drawn as the site card draws a site with a head (art/
  places/the_grid.png, art/people/the_lineman.png).
- Item25 - the Radio's signal card, a pass: every figure whole, every price shown, one odds figure, the chips not
  reading as warnings, Set off the clear first button; plus "Start a night" beside Set off (act_two.md §3).

## Images
Copy each image you use into $S/ui48/project/ and name it by a relative path in the board (`<img src="./x.png">`).
Matt's screenshots too. Keep the total under 30 images.

## Each board's file
The format: $S/act2/project/Night.dc.html is a working example (copy its head, helmet, root and closing script block
exactly; the root a fixed width x height; inline styles; no scripts building UI; real <a>/<button> for buttons).

## Fit-check every board (Matt's rule: nothing overflows)
`bash $S/ui48/look.sh Item06 1920 <h>` renders it in the real viewer and prints a screenshot path; Read the PNG and look
at it: no text cut or overflowing its box, nothing overlapping, the screenshots legible. Fix and re-render until clean.

## Report
Each board: its file, its size (w x h), what it proposes in two lines, the choices for Matt (A/B where you drew two),
and every image file used. Snapshot `$S/snap.sh ui48` last.
