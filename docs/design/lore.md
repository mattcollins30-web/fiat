# Fiat — the story underneath (12 Oct 2026)

Matt, 12 Oct: "adding some story and lore ... open to suggestions", then "just do it all". The voice and the frame
stay docs/design/narrative.md's (the yard is the player; nobody explains the collapse; flat, dry, British). This is the
thread the pieces hang on, and the six things built to carry it. The lines live in `scripts/sim/words.gd`.

## The spine: the notes

The game is called *Fiat*: money that is worth something because somebody says so. The pieces already pointed at it -
the crews still take the old notes, the Fence's mate pays in them and "still thinks they're money", the convoy's load
is notes baled under a tarp "and nobody says what for". The story says what for.

Somebody is buying up the old money. The crews aren't hoarding it for themselves; they're the "registered holders" a
coming exchange will honour at par - whoever holds the most old paper when the new money is declared owns the new
world, the way whoever held the deeds would own the estate. The lorry is the collection run. The Mint never stopped.
The last thing the radio says is the decree: *a new currency will be issued; its value is as stated; by order. Let it
be done.* The deeds are the estate's ending; the notes are the world's. Neither is explained; both are heard.

## What carries it

1. **The radio** (`Words.RADIO`, `sim.heard`, `Data.RADIO_EVERY` 3). Three voices: the official emergency loop, which
   wears down to a tone as the zones open; Kev, a pirate on the estate's frequency from the Estate on; the army's net
   in the City. Every third run home the next unheard line whose gate is open (a zone open, or lorries beaten) goes in
   the log ("Kev, on the radio: ...") as a toast. The Radio shows the last line on a glass pill at its band's foot;
   the Caravan's Also row has **The radio**, every line heard in order. Seventeen lines; the last six are the notes'
   story, gated one a lorry.
2. **The opening** (`Words.OPENING`): three lines in the log on a new camp, before "The Yard is set". Once.
3. **The drawer, a book** (`Words.PAPERS`, the Caravan): every paper in the story's order, the found ones with their
   words, the rest a gap that says where it turns up (its one site, or the depth it's found from). Eight new papers,
   each its own site's ("only"): the Outskirts' (a seed order, an allotment waiting list, a loyalty card, a milk quota
   letter) and the City's (a delivery note at the Services, a drug chart at the Hospital, a leave pass and a requisition
   at the Barracks). Twenty-eight pages.
4. **The gangs** (`Words.GANGS`): now they have faces, a name a zone - the field lads, the Parade boys, the High Street
   lot, the Garrison - and a line as one arrives, in turn ("The Parade boys, 3 of them. Hoods up.").
5. **The runners**: a line on the wall when one dies, in their past's terms (`Words.PASTS[class].wall`: "Kept walking.
   Not far enough."), and a sentence each for the traits, said when a runner turns up (`Words.TRAITS`).

## Not built, deliberately

A cutscene or a win screen: the log is the narrator and the radio is the world. Any explanation of the collapse.
Voiced lines. A choice on the notes: the deeds are the player's one choice and stay so; the notes are a thing that
happens to the world, overheard.
