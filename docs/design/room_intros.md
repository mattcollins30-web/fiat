# Room intros (draft, 14 Oct)

Matt: "now it's onto the room introductions". The opening says what the world is; these say what each room is
for, the first time you walk in. Mockup: docs/design/mockups/room_intro_mockup.png (the Clinic).

## How it plays
- **When:** the first time a room is shown. For the five gated rooms (Clinic, Fence, Workshop, Pitch, Radio) that's
  the first visit after the head's drop opens them, so the radio line and the log toast stay as they are. The intro
  is what you get when you walk in.
- **What:** a card over the dimmed room. The room's place art (art/places/) runs across the top, shaded from the left
  like the room bands, with the person who runs it (their portrait) or the room's glyph when nobody does. Under that
  come two or three lines in their voice, then three tiles naming the screen's parts in plain words, with "Go on".
- **Voiced:** the same pattern as the opening. The lines come up on their cues, and a press moves on. The narrator
  speaks for the rooms with nobody in them. The medic, the Fence and Kev each get a voice. Without a take, a line
  shows every few seconds.
- **Once:** seen rooms go in the save (`met`). An old save counts every room it has open as already met, so nobody
  who's playing gets nine cards at once. The "?" at the end of the rail's ROOMS heading brings the room's card back
  (built 14 Oct; the top bar had no room for it with every currency showing). The pause menu's on/off waits for the
  cog work: the pause holds five rows and has five.
- **Not in the turn:** never during a run's first seconds or with a menu up. The card waits until the room is
  actually on screen.

## The nine (words are drafts: change anything)

**The Map** · the narrator · first screen of a new game
"The town, from the ring road in. Every site on it was somebody's once.
Pick one. Send the runner. They come back with what they carry, or they don't."
Tiles: *Sites* (where to go, and the odds) · *Depth* (deeper pays more, hits harder) · *The heads* (each one opens
something on the Pitch)

**The Kit** · the narrator
"What the runner takes out is all they've got.
What stays behind is the stash. What's worn out there can be lost out there."
Tiles: *The body* (what's worn) · *The rig* (pouches, meds first) · *The stash* (what's kept back)

**Stats** · the narrator
"The runner, on paper. What they hit for, what they can take, what they've done."
Tiles: *Attack* · *Defence* · *The record*

**Training** · the narrator (the Caravan)
"The caravan at the back. Whoever runs for you sleeps here, and gets better here.
Their past decides what they can learn. The Pitch's tree stays when they don't."
Tiles: *Their past* · *Their trees* · *The Pitch's tree*

**The Clinic** · the medic
"Sit down. Don't bleed on that, it's the only clean one.
Resting on the Pitch heals, slowly.
I'm quicker, I cost tins and I'm the only one that can heal a lasting wound.
Meds go in the rig. Your runner takes them first when it gets bad out there." (Matt's, 14 Oct)
Tiles: *Treatment* (heal faster, for tins) · *The shelf* (meds to buy, new each run) · *Your meds* (in the rig, used
under fire)

**The Fence** · the Fence
"Everything's for sale. That's the one thing that hasn't changed.
You bring, I price. The price is the price.
Want steady work? I've got contracts."
Tiles: *Sell* (finds for tins) · *Buy* (the shelf, and sealed lots) · *Contracts* (what he wants, what he pays)

**Workshop** · the narrator
"The armourer's roll, laid out on the bench. Proper tools, for once.
Guns get better here, part by part."
Tiles: *Jobs* · *Mounts* · *The Bench's upgrades*

**The Pitch** · the narrator
"The deeds say it's yours. Paper's about all anyone still agrees on.
Build on it. What's built here comes with you when you move."
Tiles: *The buildings* · *Ranks* · *Moving on* (when the lorry's beaten)

**Radio** · Kev
"Kev here. Well, you know that. You've got a set now.
Everything worth hearing comes over this. Most of it isn't worth hearing.
Keep listening anyway."
Tiles: *What's on the air* · *Who's talking* · *Heard so far*

## Questions for Matt (14 Oct: all three as recommended)
1. Voiced, or words only for now? (Recommended: voiced. It's four voices and nine short takes, and it matches the
   opening.)
2. The four rooms open from the start (Map, Kit, Stats, Training): should they get cards on first visit like the
   rest, or should the Map's card alone point at the other three? (Recommended: a card each, short; the Map's first.)
3. The "?" to bring a card back: on each room's band, or only the pause-menu toggle?

## The voice manifest (once the words are agreed)
Nine takes in art/intro/rooms/<room>.mp3, cues read off the same way as the opening's. Voices: the narrator (the
opening's), the medic (an older woman, tired, kind under it), the Fence (flat, careful, a little amused), Kev
(pirate DJ, warm, Welsh valleys).
