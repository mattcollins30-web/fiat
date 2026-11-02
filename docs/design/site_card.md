# The Map's site card, redesigned (2 Nov, Matt; parked for the next round)

Canvas: "Fiat – The Map's site card" (https://claude.ai/artifact/7gwYQSSt2aYiV59hf36syF) - three rounds; round 3 is
the base, with the changes below.

Matt, 2 Nov: "profile pics of the gangs and heads - less raw numbers - more use of the space available - a full
redesign". Round 2: "a combination of A and B". Round 3: "I like the addition of personal best and records".

## Agreed
- **One fixed layout, never resizing.** Every site's card is the same size with every block in the same place; the
  only differences are what the blocks show. No block appears or disappears.
- **The picture** (the site's own art, ~200-350 px tall, to be fixed once) with the figures standing in it.
- **A Gang / Head toggle** in the head's row: Gang shows the gang standing in the site's picture; Head shows the head
  standing in their own interior (art/fight_boss/<head>_plate.png - the Gamekeeper's, the Manager's...). A site
  without a head keeps the row, the Head side greyed ("No head here"), so nothing moves.
- **You against them:** the runner's class portrait (art/people/<class>.png, as Training's class pick uses) against
  the gang's or the head's portrait (art/people/gang_<zone>.png / <head>.png), the verdict and odds between them.
- **What it takes:** you last N s of the fight (a bar against the fight's length), their fire against your resist,
  your fire against their resists, meds in the rig as slots - words over raw numbers.
- **Fix chips that act:** meds -> Top up, armour/HP -> the Kit, "<site> first" -> picks that site.
- **What you'll bring home:** icon tiles - gear and its level, scrap, papers, the site's rebuild material (none in
  the Outskirts), the head's thing when the head is shown.
- **You here:** the site's record - times cleared, best time, the last run's end (a small per-site record; most of it
  is in the run record already).
- Buttons as today.

## Open for the build
- The picture's fixed height once every block's size is set; check the longest site and head names fit.
- Which heads lack an interior plate (all eleven have art/fight_boss/*_plate.png as of 2 Nov - check the County's).

## Built (2 Nov, BUILD46-S; scripts/ui/site_card.gd)
- The picture fixed at 190 px: the site's painted place (art/places) with the gang's figures standing in it (as many
  as fight at once, three at most), or the head standing in his own interior (art/fight_boss/<head>_plate.png; all
  four Map heads have one). The clock and the sky on a chip at its top right; the site's line and what the sky does
  ("Rain: searches 30% slower.") at its foot - the Conditions box's job, said once.
- Gang / Head is a view toggle; the foot's Head button (taking him on) turns the view to Head, letting him be turns it
  back. A site with no head keeps the row: "No head here", Head greyed.
- What it takes: you last (the bar is the run's clock, the tick the fight's end), their fire against your resist,
  your fire against their resists, the rig's pouches as slots (in words past eight), the rounds.
- The fix chips are the odds' reasons, one row: the rounds' first when short, what's short, the site before last
  (kept whatever else drops). Meds turn the gate's top-up on, then the Kit; rounds the rounds picker; a wound or HP the
  Clinic; the rest the Kit; "Grind <site> first" picks it.
- Bring home: gear and its level; scrap (or a head's thing left at this site, or the head's own thing / "One of his
  own" in the Head view); a paper in N; the site's material (muted before the campaign's done; "None here" in the
  Outskirts). You here: cleared N times and the best clear time, the site's crates at the right; the last run's end.

## A head's thing left behind (2 Nov, BUILD46-S)
The drop opens its room at half until the thing is home; it turns up as a find on the next clear of that site. The
halves: the Clinic rests at half speed and stocks half her shelf; the Fence's shelf half; the Workshop's scrap from
breaking down half; the Pitch builds at double; the Radio holds 2 signals, not 3. The deeds' fate decided (sold,
burned) frees the Pitch. The room's band says it ("At half: the vet's bag is still at Top Farm · rests at half
speed, half the shelf").
