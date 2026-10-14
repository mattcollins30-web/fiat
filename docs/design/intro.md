# The opening (14 Oct, Matt; agreed - the script with his one edit, the Pitch)

Matt: on a new game, fade from black into an art sequence that sets the tone in five scenes - Fallout 2's opening as
the model. Real-world threads, no world war, no bang: proxy wars backed by the big powers, an energy shock driving
migration and squeezing food and water, AI as the bubble, and the money going when all of it lands at once -
currency worthless, governments failing, people back to their own. 2028 to the collapse around 2033. Then a scene
on what you're doing: keeping a camp, sending out whoever's willing, moving on. Character and room intros after.
"The voice" means the game's written voice, not a spoken one - a generated narration is a maybe, to try later.

## How it plays (mockup: docs/design/mockups/intro_mockup.png)
- New camp → black → each scene fades up: one picture full screen, drifting slowly (a slow pan or push, never still),
  the year small at the top left, two to four short lines fading in one at a time at the foot. A click or a key brings
  the next line or the next scene; Esc skips the lot. About a minute if left alone.
- The radio's own lines are the sound bed where they fit (the recorded message in scene 4 is the one the strip plays
  in the game) - the music under it all is music_title.
- Seen once a camp; Watch the opening again on the title.

## The script (draft - to cut and change)
The register is the game's: short, plain, British, past tense, nobody named, nothing explained twice.

**1 · 2028 · Somewhere else**
The wars were always somewhere else.
Other people's wars. Their reasons, their profits, our money. We watched them on the news.
We felt them at the till.
*Art: a front room at night, a television showing a burning city far away; on the table, a supermarket receipt.*

**2 · 2029 · The bills**
Then the petrol went up, and up again.
The heating went off in the flats. The boats kept coming; where they came from was worse.
Bread doubled. The reservoirs didn't fill.
*Art: a terraced street in winter, the windows dark; a queue outside a church hall food bank; a dry reservoir beyond.*

**3 · 2031 · The machines**
They said the machines would do the work. For a while the money said so too.
Fields of servers, drinking the rivers, burning the power we couldn't afford.
The jobs went first. The money went after them.
*Art: a vast grey data centre beside a shrunken reservoir, cooling towers, a closed office block with its lights still on.*

**4 · 2032 · The money**
It didn't crash. It stopped.
The cards stopped. The banks shut for a day, then a week. The pound was paper.
Then the radio broadcasts:
*This is a recorded message. Remain in your homes. Cash withdrawals are limited to fifty pounds a day.*
*Art: a queue outside a shuttered high-street bank, a cash machine reading Temporarily unavailable, notes in the gutter.*

**5 · 2033 · Let it be done**
Nobody fired a shot. The lights just went out one town at a time.
The council stopped coming. The lorries stopped coming. The police stopped coming.
People kept to their own. The estate kept the estate.
A new currency was promised. Its value is as stated. Let it be done.
*Art: an empty motorway at dusk, a jack-knifed lorry, a checkpoint of trolleys and pallets on the slip road.*

**6 · Now · The Pitch**
You keep a camp. A few vans, a fire, a fence of pallets.
You don't go out. Somebody does - whoever's willing, for a share of what comes back.
Tins are money now. What's in a tin is worth something.
Send them out. Bring back what you can. When a place is picked clean, or someone wants it more than you do, you move on.
*Art: a camp at night - a brazier, two vans, pallet fencing, a figure at the gate looking out at a dark town.*

## The camp's name (the Yard's, everywhere it's said)
The Yard reads as fixed and owned - the opening says you move on. Options:
- **The Pitch** (Matt, 14 Oct: picked): what Travellers and market traders call the ground you set up on and leave; reads
  British and temporary; "Move the Pitch", "turns up at the Pitch", "The deeds are the Pitch's. Build on it."
- **The Lay-by**: where you'd stop off a road; bleaker, a little comic.
- **The Compound**: harder, more held; doesn't say temporary.
- **The Stand**: a market stand and a last stand; short.
The rename touches the words (about 26 in words.gd), the room and rail name, the Move button, the tests' strings and
the save's words (keys stay "yard" in the code and saves - only what's on screen changes).

## Art (a manifest once the script's agreed)
Six pictures, 640×360 (shown at 3x, 1920×1080), the house style (style images from art/places), each with room to
drift. Optionally a second picture per scene (a close detail) if one feels thin.

## Built later, separately
Characters' and rooms' intros on first visit (after this is nailed down); a narrated version via ElevenLabs speech
(a maybe).
