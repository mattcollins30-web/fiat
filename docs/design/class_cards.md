# The class cards - cue sheet (25 Oct)

Matt, 25 Oct: "a story beat for every class unlock because at the moment it's silent". Each class that opens gets its
card once, back at camp after the head falls (the Drifter after Kev's first story): the room-intro card, the class's
portrait and place, two lines in its own voice, its Training card lines as the tiles, "To Training". The canvas board
'A class opens: its card' (25 Oct) has the layout; the lines are fitted at the card's width.

Matt makes the takes by hand in ElevenLabs. Until a take is there the lines come up on the clock, as a room card's do.

## The takes

One file a class, both lines in one take, a short beat between them. Drop each at `art/intro/classes/<file>.mp3`, then
tell Claude the time (in seconds) the second line starts, for its `cues` in Words.CLASS_CARDS (the first is 0.0).

| Class | File | Voice brief | Lines |
|---|---|---|---|
| Paramedic | paramedic.mp3 | A woman in her thirties, Welsh valleys; tired and practical, quick | "Half of what's in the vet's bag works on people. I checked." / "The doctor keeps the Clinic. Somebody has to go out to them." |
| Doorman | doorman.mp3 | A big man in his fifties, south London; slow and flat, a smoker's chest | "Twelve years on his door. Near the end he paid me in rugs." / "Nobody got past me then. Nobody gets past me now." |
| Scrapper | scrapper.mp3 | A man in his forties, Black Country; chatty, dry | "I kept the Bank's lifts running till there was nothing left to lift." / "Give me a bin bag and an afternoon. I'll give you a gun." |
| Recruit | recruit.mp3 | A lad of nineteen, north-east; clipped, like the drill instructor he's copying | "Nobody signed me out. I took the stores and I walked." / "I can drill you. I can drill the lot of you. Show me where." |
| Drifter | drifter.mp3 | A woman in her twenties, Bristol; light and restless | "Kev found me on the ring road, walking the way the lorries go." / "I don't stop anywhere long. Lucky for you, I'm quick." |

The Poacher has the opening.

## In the code

- Words.CLASS_CARD (the kicker, the button, the hint) and Words.CLASS_CARDS (a class's face, title, the line under it,
  its place, its take's name, its lines).
- scripts/ui/room_intro.gd: a card keyed `class:<name>` reads them (`data_of`); its tiles are the class's `short` lines
  from Data.CLASSES, its trees when it has under three; CLASS_STRIPS the boxes' art; CLASS_VOICE the take.
- scripts/ui/main.gd: `class_card_due()` / `show_class_card()`, ahead of the rooms' cards; `sim.met` keeps
  `class:<name>` once shown; "To Training" takes you there. A save from before them has met its open classes.
- tests/smoke.gd: every class's lines and tiles fit, the tiles are Training's lines, the face and place are drawn,
  each open class's card comes once and leaves you in Training.
