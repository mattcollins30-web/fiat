# On the air (14 Oct; built)

Matt: the campaign ends when the Quartermaster falls and his set comes home - the Radio opens. "The ending revolves
around the radio, getting more codes and opening the endgame ... something narrated by the voice of Kev - the radio
unlocks the ability to communicate and you realise just how much worse everything is out there than you originally
thought. 2 or 3 scenes maximum." The campaign's close and the endgame's door, as the opening is the game's.

## How it plays
- **When:** the Radio open, at home, with neither "air" nor the Radio's card met (sim.met). Never mid-run. The game is
  held, as under the opening; it sits in the opening's place, so the room cards, the Esc guard and the rest wait for it
  too. Once: "air" goes in `met` as it starts. A save that has met the Radio's card (it had the set before these were
  made) never sees them.
- **What:** the opening's player, three scenes: a picture each (art/intro/air_N.png, 640x360 at 3x, drifting), a
  heading (a frequency and a name instead of a year), Kev's lines on his take's cues. A press for the next line, Esc
  to skip. Then the Radio's room card (Kev again, short: "You've got a set now").
- **Voice:** Kev, the voice of the Radio's card. One take a scene, art/intro/voice/air_N.mp3. He doesn't read the
  headings (the opening's narrator did; Kev wouldn't).

## The script (Kev)

**1 · Channel 19 · The set**
Kev here. Properly, this time. That's a military set you've got - it hears a long way.
I've had two years listening from the other end. You'd better hear what I hear.

**2 · Long wave · Everywhere else**
Swansea's gone quiet. Bristol's one big checkpoint. Nobody's answered from London since the spring.
It isn't just the UK, everywhere else has gone dark too. (Matt's lines, 14 Oct)
The only ones still moving are the army. Their lorries run every night, and nobody knows what's in them.

**3 · The codes · Deeper**
Those papers you keep finding. The codes on them aren't codes - they're frequencies.
Somebody wrote them down so the right people could listen. Tune one in and it tells you where to dig.
The deeper you go, the more you'll hear. Go carefully. Somebody's always listening back.

Kept back on purpose: what the lorries carry, the Mint, the registered holders, the new currency - the radio's own
story tells those through the endgame (Words.RADIO), and ends on "Let it be done."

## The art (tools/make_air_manifest.py -> tools/pixellab_air_manifest.json, out art/intro/)
1. air_1 - the Pitch's radio bench at night: a green army field set on a pallet table, its dials lit, headphones, a
   mug, a notepad; through a gap in the tarpaulin the camp's brazier and the dark town.
2. air_2 - Britain from a hill at night: a dark city below with a few fires, a motorway with a line of army lorries,
   headlights on, the only lights moving; far off, another city as dark.
3. air_3 - a table under a torch: the found papers spread out (a betting slip, a pawn ticket, a bank statement),
   codes circled in pencil, a notepad of frequencies, the set's dial at the edge.
