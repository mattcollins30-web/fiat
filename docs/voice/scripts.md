# Fiat: voice scripts (3 Nov, for 0.12.1)

Every line the game plays as voice, or is built to: the story opening, On the air (Kev's story intro), the nine room
cards, the five class cards, and the Poacher's card and tutorial (designed, not built yet). Read against the code
(scripts/sim/words.gd), the design docs, and the takes. I transcribed the takes in the cloud copy's art folder (all
recorded 14 Oct, the same file names as yours) to check them word for word.

**How the changes are marked:** ~~struck~~ is the game's current text, and **bold** is the suggested line. *(why)* gives
the reason. A line with no mark is the game's text as it stands, and the take must match it. The game shows the lines
exactly as written here: punctuation is part of the text, and the cues are read off the take.

**What isn't in the repo:** no ElevenLabs voice names, voice IDs or settings are written down anywhere, in the docs,
the tools, CLAUDE.md or status.md. The briefs below are all the docs hold, quoted as written. For a consistent regen,
use the same voice each speaker had on 14 Oct (your ElevenLabs history has them) and write the IDs into
docs/voice/recording_list.md this time.

---

## Summary

| # | Scene | Audio file | On your machine? | Take matches the game's text? | Lines missing / stale | Voice |
|---|---|---|---|---|---|---|
| O1 | 2028 · Somewhere else | art/intro/voice/2028.mp3 | Yes (old: 2028-v1) | Yes | None | Narrator |
| O2 | 2029 · The bills | art/intro/voice/2029.mp3 | Yes | Yes | None | Narrator |
| O3 | 2031 · The machines | art/intro/voice/2031.mp3 | Yes | Yes | None | Narrator |
| O4 | 2032 · The money | art/intro/voice/2032.mp3 | Yes (old: 2032-v1) | Yes | None | Narrator, plus the emergency loop for the last line |
| O5 | 2033 · Let it be done | art/intro/voice/2033.mp3 | Yes (old: 2033-v1) | Yes | None | Narrator |
| O6 | Now · The Pitch | art/intro/voice/now.mp3 | Yes (old: now-v1) | Yes | Stale: the heading "The Pitch" (now Home), "camp" (now "a place"), and "you move on" (the Pitch move went on 21 Oct) | Narrator |
| A1 | Channel 19 · The set | art/intro/voice/air_1.mp3 | Yes | Yes | None | Kev |
| A2 | Long wave · Everywhere else | art/intro/voice/air_2.mp3 | Yes | Yes | None | Kev |
| A3 | The codes · Deeper | art/intro/voice/air_3.mp3 | Yes | Yes | Stale: "where to dig" and "the deeper you go" (depth and digging are gone) | Kev |
| R1 | The Map | art/intro/rooms/map.mp3 | Yes | Yes | None | Narrator |
| R2 | Stats | art/intro/rooms/stats.mp3 | Yes | Yes | None | Narrator |
| R3 | The Kit | art/intro/rooms/kit.mp3 | Yes | Yes | None | Narrator |
| R4 | Training | art/intro/rooms/training.mp3 | Yes | **No**: line 2 changed today (the skill web), and the old take still plays under the new text | Line 2 needs a take | Narrator |
| R5 | The Clinic | art/intro/rooms/clinic.mp3 | Yes | Yes | Stale: "on the Pitch" (now "at home") | The medic |
| R6 | The Workshop | art/intro/rooms/workshop.mp3 | Yes | Yes, but line 1 should change: the armourer's roll is now the Carpet Man's fitter's kit. The text is held for the take | Line 1 needs a take | Narrator |
| R7 | The Fence | art/intro/rooms/fence.mp3 | Yes | **No**: line 3 changed on 28 Oct (contracts became the exchange), and the old take still plays under the new text | Line 3 needs a take | The Fence |
| R8 | Home (was the Pitch) | art/intro/rooms/pitch.mp3 | Yes | Yes | Stale: "comes with you when you move" (the move is gone) | Narrator |
| R9 | The Radio | art/intro/rooms/radio.mp3 | Yes | Yes | None | Kev |
| C1 | The Paramedic | art/intro/classes/paramedic.mp3 | **No**, never recorded | No take | Stale: "The doctor" (now "the medic") | The Paramedic |
| C2 | The Doorman | art/intro/classes/doorman.mp3 | **No**, never recorded | No take | None | The Doorman |
| C3 | The Scrapper | art/intro/classes/scrapper.mp3 | **No**, never recorded | No take | None | The Scrapper |
| C4 | The Recruit | art/intro/classes/recruit.mp3 | **No**, never recorded | No take | None | The Recruit |
| C5 | The Drifter | art/intro/classes/drifter.mp3 | **No**, never recorded | No take | The recording list says "on the road" but the game says "on the ring road". The game's text is used here | The Drifter |
| P1 | The Poacher (not built) | art/intro/classes/poacher.mp3 | No | Not in the game | The whole card: it comes with the tutorial | The Poacher (no brief yet) |
| T1-9 | The tutorial (not built) | art/intro/tutorial/1_arrive.mp3 to 9_poacher.mp3 | No | Not in the game | Nine beats, design only | Narrator; the Poacher in beat 9 |

**The voices (from the docs):**

- **The narrator** reads the opening, the room cards with nobody in them (the Map, Stats, the Kit, Training, the
  Workshop, Home), and the tutorial. No written brief exists. The docs only say "the opening's" narrator. They do record
  that the narrator reads each scene's heading (on_the_air.md: "He doesn't read the headings (the opening's narrator
  did; Kev wouldn't)"). The register is narrative.md's: "British, flat, dry ... Nobody heroic. The worst things said
  shortest ... No exclamation marks."
- **The emergency loop** is one line in scene O4. It is the official recorded message, shown in grey as the radio's
  own line (lore.md: "the official emergency loop, which wears down to a tone"). In the current take it sits apart
  from the narrator's lines, from 16 s to 25 s. No brief exists; I suggest a flat public-announcement voice, distinct
  from the narrator.
- **The medic** (the Clinic): "an older woman, tired, kind under it" (room_intros.md).
- **The Fence**: "flat, careful, a little amused" (room_intros.md). He's a man (the opening's log: "he paid in tins").
- **Kev** (the Radio, On the air): "pirate DJ, warm, Welsh valleys" (room_intros.md). He doesn't read the headings
  (on_the_air.md).
- **The classes** (class_cards.md, briefs quoted below): Paramedic "a woman in her thirties, Welsh valleys"; Doorman
  "a big man in his fifties, south London"; Scrapper "a man in his forties, Black Country"; Recruit "a lad of
  nineteen, north-east"; Drifter "a woman in her twenties, Bristol".
- **A call for you on accents:** language.md (3 Nov) says "British, not Welsh: the flavour voice is dry,
  understated British. The style guide's 'South Wales voice' line goes." That rule is about how the words are written.
  Kev's and the Paramedic's Welsh valleys accents are casting. I'd keep them, because they're characters from a South
  Wales town, and keep the narrator neutral British. Say if the language call was meant to cover the voices too.

---

## 1. The story opening

Plays on a new game (scripts/ui/opening.gd). The text is in `Words.OPENING_SCENES` (scripts/sim/words.gd:22-51).
There's one take per scene, and **the narrator reads the year and the scene's name first**, then the lines. Each
line comes up on its cue (the second each line starts in the take), so leave about a second between lines. The
headings show at the top left. The lines show at the foot, one at a time.

### O1 · 2028 · Somewhere else
File: `art/intro/voice/2028.mp3` · Speaker: the narrator · words.gd:23 · Current cues: 3.82, 7.34, 14.50 (take 16.0 s)

> *(heading, read)* 2028. Somewhere else.
1. The wars were always somewhere else.
2. Other people's wars. Their reasons, their profits, our money. We watched them on the news.
3. We felt them at the till.

### O2 · 2029 · The bills
File: `art/intro/voice/2029.mp3` · Speaker: the narrator · words.gd:27 · Current cues: 3.74, 7.48, 13.80 (take 17.0 s)

> *(heading, read)* 2029. The bills.
1. Then the petrol went up, and up again.
2. The heating went off in the flats. The boats kept coming; where they came from was worse.
3. Bread doubled. The reservoirs didn't fill.

### O3 · 2031 · The machines
File: `art/intro/voice/2031.mp3` · Speaker: the narrator · words.gd:31 · Current cues: 3.92, 10.32, 16.52 (take 19.7 s)

> *(heading, read)* 2031. The machines.
1. They said the machines would do the work. For a while the money said so too.
2. Fields of servers, drinking the rivers, burning the power we couldn't afford.
3. The jobs went first. The money went after them.

### O4 · 2032 · The money
File: `art/intro/voice/2032.mp3` · Speaker: the narrator; line 4 is the emergency loop · words.gd:35-39 · Current
cues: 3.40, 6.28, 13.26, 16.48 (take 25.6 s)

> *(heading, read)* 2032. The money.
1. It didn't crash. It stopped.
2. The cards stopped. The banks shut for a day, then a week. The pound was paper.
3. Then the radio broadcasts:
4. *(the emergency loop: a recorded official announcement, flat, as if over a radio)* This is a recorded message. Remain in your homes. Cash withdrawals are limited to fifty pounds a day.

Note: if the loop is a different ElevenLabs voice, record it separately and join it onto the narrator's take as one
file. The game plays one file per scene.

### O5 · 2033 · Let it be done
File: `art/intro/voice/2033.mp3` · Speaker: the narrator · words.gd:40 · Current cues: 4.04, 9.60, 16.00, 20.14 (take 26.2 s)

> *(heading, read)* 2033. Let it be done.
1. Nobody fired a shot. The lights just went out one town at a time.
2. The council stopped coming. The lorries stopped coming. The police stopped coming.
3. People kept to their own. The estate kept the estate.
4. A new currency was promised. Its value is as stated. Let it be done.

### O6 · Now · Home *(was: The Pitch)*
File: `art/intro/voice/now.mp3` · Speaker: the narrator · words.gd:45-50 · Current cues: 2.52, 7.50, 13.46, 17.58,
20.80 (take 26.1 s)

> *(heading, read)* Now. ~~The Pitch.~~ **Home.** *(language.md: the Pitch is Home)*
1. You keep ~~a camp~~ **a place**. A few vans, a fire, a fence of pallets. *(language.md lists this exact fix: "camp (the opening: 'You keep a place.')")*
2. You don't go out. Somebody does~~ – whoever's~~ **. Whoever's** willing, for a share of what comes back. *(narrative.md: "Full stops, not dashes, inside a line". The take already reads it that way)*
3. Tins are money now. What's in a tin is worth something.
4. Send them out. Bring back what you can.
5. ~~When a place is picked clean, or someone wants it more than you do, you move on.~~ **When a place is picked clean, you send them further.** *(the Pitch move went on 21 Oct. status.md listed this line for a re-record then, but the words proposed weren't kept in the repo. This is my suggestion. Keep the old line if you want the theme of moving on, though nothing in the game moves now)*

---

## 2. On the air (Kev's story intro)

Plays once when the Quartermaster's set comes home and the Radio opens, before the Radio's card. It uses the
opening's player (main.gd:1048). The text is in `Words.AIR_SCENES` (words.gd:56-67). **Kev does not read the
headings**, so the first cue is 0.0.

### A1 · Channel 19 · The set
File: `art/intro/voice/air_1.mp3` · Speaker: Kev · words.gd:57 · Current cues: 0.0, 7.56 (take 12.7 s)

1. Kev here. Properly, this time. That's a military set you've got~~ – it~~ **. It** hears a long way. *(no dashes inside a line)*
2. I've had two years listening from the other end. You'd better hear what I hear.

Direction: the transcription heard "it hears a long way" as "It is a long way", so make sure "hears" lands.

### A2 · Long wave · Everywhere else
File: `art/intro/voice/air_2.mp3` · Speaker: Kev · words.gd:60 · Current cues: 0.0, 8.84, 14.06 (take 20.3 s)

1. Swansea's gone quiet. Bristol's one big checkpoint. Nobody's answered from London since the spring.
2. It isn't just the UK. Everywhere else has gone dark too.
3. The only ones still moving are the army. Their lorries run every night, and nobody knows what's in them.

### A3 · The codes · ~~Deeper~~ **Further out**
File: `art/intro/voice/air_3.mp3` · Speaker: Kev · words.gd:64 · Current cues: 0.0, 6.90, 12.70 (take 19.7 s)
*(recording_list.md §2: "Depth and digging went from the game; signals are levels now". The on-screen heading
"Deeper" goes with it. Kev doesn't read it)*

1. Those papers you keep finding. The codes on them aren't codes~~ – they're~~ **. They're** frequencies.
2. Somebody wrote them down so the right people could listen. Tune one in and it tells you where to ~~dig~~ **go**.
3. The ~~deeper~~ **further out** you go, the more you'll hear. Go carefully. Somebody's always listening back.

---

## 3. The room cards

Each room's card shows the first time you're in it (scripts/ui/room_intro.gd). The text is in `Words.ROOM_INTROS`
(words.gd:73-113), keyed by the room's code key. There's one take per card and no heading is read, so the first cue
is 0.0. Leave about a second between lines. The order below is the order the rooms open: the Map first on a new
game, then the other starting rooms in rail order, then the Clinic (Gamekeeper), the Workshop (Carpet Man), the Fence
and Home (Manager), and the Radio (Quartermaster). Keep the file names: language.md says file names and keys stay,
so Home's take is still `pitch.mp3`.

### R1 · The Map *(key "map")*
File: `art/intro/rooms/map.mp3` · Speaker: the narrator · words.gd:74 · Current cues: 0.0, 5.64 (take 11.2 s)

1. The town, from the ring road in. Every site on it was somebody's once.
2. Pick one. Send the runner. They come back with what they carry, or they don't.

Direction: the transcription heard "ring road in" as "Ring Road Inn", so leave a small beat after "ring road".

### R2 · Stats *(key "stats")*
File: `art/intro/rooms/stats.mp3` · Speaker: the narrator · words.gd:82 · Current cue: 0.0 (take 6.3 s)

1. The runner, on paper. What they hit for, what they can take, what they've done.

### R3 · The Kit *(key "kit")*
File: `art/intro/rooms/kit.mp3` · Speaker: the narrator · words.gd:78 · Current cues: 0.0, 3.58 (take 10.2 s)

1. What the runner takes out is all they've got.
2. What stays behind is the stash. What's worn out there can be lost out there.

### R4 · Training *(key "training")*: re-record
File: `art/intro/rooms/training.mp3` · Speaker: the narrator · words.gd:85-87 · Current cues: 0.0, 7.22 (take 12.8 s)

1. The caravan at the back. Whoever runs for you sleeps here, and gets better here.
2. ~~Their past decides what they can learn. The Pitch's tree stays when they don't.~~ **Each runner has their own web. They start at their class and buy outward.** *(the skill web, 3 Nov. This text is already in the game; the take is the old line)*

### R5 · The Clinic *(key "clinic")*
File: `art/intro/rooms/clinic.mp3` · Speaker: the medic · words.gd:89 · Current cues: 0.0, 4.60, 7.58, 12.74 (take 16.8 s)

1. Sit down. Don't bleed on that, it's the only clean one.
2. Resting ~~on the Pitch~~ **at home** heals, slowly. *(language.md: the Pitch is Home, "built at home", "turns up at home")*
3. I'm quicker, I cost tins and I'm the only one that can heal a lasting wound.
4. Meds go in the rig. Your runner takes them first when it gets bad out there.

Direction: the transcription heard "tins" as "tens", so say it clearly. Line 1 has no exclamation mark (the 14 Oct
take reads it as one).

### R6 · ~~Workshop~~ **The Workshop** *(key "workshop")*: re-record
File: `art/intro/rooms/workshop.mp3` · Speaker: the narrator · words.gd:100 · Current cues: 0.0, 6.46 (take 8.9 s)

1. ~~The armourer's roll, laid out on the bench. Proper tools, for once.~~ **The Carpet Man's fitter's kit, laid out on the bench. Proper tools, for once.** *(recording_list.md §1: the Workshop opens at the Carpet Man, with his fitter's kit. The game still shows the old line, held for the take)*
2. Guns get better here, part by part.

The room's name on the card becomes "The Workshop" (language.md: "the Workshop (its intro title too)"). It isn't read.

### R7 · The Fence *(key "fence")*: re-record
File: `art/intro/rooms/fence.mp3` · Speaker: the Fence · words.gd:95-98 · Current cues: 0.0, 5.44, 9.10 (take 12.3 s)

1. Everything's for sale. That's the one thing that hasn't changed.
2. You bring, I price. The price is the price.
3. ~~Want steady work? I've got contracts.~~ **Notes, tins, scrap. I'll change any of it. At a price.** *(the exchange, 28 Oct. This text is already in the game; the take is the old line)*

### R8 · ~~The Pitch~~ **Home** *(key "yard")*
File: `art/intro/rooms/pitch.mp3` (keep the name) · Speaker: the narrator · words.gd:104 · Current cues: 0.0, 4.84 (take 8.7 s)

1. The deeds say it's yours. Paper's about all anyone still agrees on.
2. Build on it. ~~What's built here comes with you when you move.~~ **What's built here stays, whoever runs for you.** *(the Pitch move went on 21 Oct. status.md listed this line for a re-record then, but the proposed words weren't kept. This is my suggestion)*

Direction: the transcription heard "Paper's" as "Papers", so the possessive should land.

### R9 · ~~Radio~~ **The Radio** *(key "radio")*
File: `art/intro/rooms/radio.mp3` · Speaker: Kev · words.gd:108 · Current cues: 0.0, 5.34, 11.14 (take 12.5 s)

1. Kev here. Well, you know that. You've got a set now.
2. Everything worth hearing comes over this. Most of it isn't worth hearing.
3. Keep listening anyway.

---

## 4. The class intros

A class's card shows once, back at camp after the head falls (the Drifter's after Kev's first story), using the room
card's player (main.gd:1083-1100; room_intro.gd:19). The text is in `Words.CLASS_CARDS` (words.gd:1804-1820), and the
voice briefs are in docs/design/class_cards.md. **None has ever been recorded, and none has `cues` in words.gd**, so
until the cues go in, the lines run on the clock even with a take in place. Per class_cards.md: one take per class,
both lines, a short beat between, saved to `art/intro/classes/<file>.mp3`. Give me the second line's start time (the
first is 0.0). The order below is the order they open.

### C1 · The Paramedic
File: `art/intro/classes/paramedic.mp3` · words.gd:1805 · Card: "Out of the Clinic, after the Gamekeeper fell"
Voice (class_cards.md): "A woman in her thirties, Welsh valleys; tired and practical, quick"

1. Half of what's in the vet's bag works on people. I checked.
2. The ~~doctor~~ **medic** keeps the Clinic. Somebody has to go out to them. *(language.md: "the medic (not the doctor)")*

### C2 · The Doorman
File: `art/intro/classes/doorman.mp3` · words.gd:1808 · Card: "Free of the Carpet Man's door, now he's down"
Voice (class_cards.md): "A big man in his fifties, south London; slow and flat, a smoker's chest"

1. Twelve years on his door. Near the end he paid me in rugs.
2. Nobody got past me then. Nobody gets past me now.

### C3 · The Scrapper
File: `art/intro/classes/scrapper.mp3` · words.gd:1811 · Card: "Out of the Bank's basement, after the Manager"
Voice (class_cards.md): "A man in his forties, Black Country; chatty, dry"

1. I kept the Bank's lifts running till there was nothing left to lift.
2. Give me a bin bag and an afternoon. I'll give you a gun.

### C4 · The Recruit
File: `art/intro/classes/recruit.mp3` · words.gd:1814 · Card: "Walked out of the Barracks with the Quartermaster gone"
Voice (class_cards.md): "A lad of nineteen, north-east; clipped, like the drill instructor he's copying"

1. Nobody signed me out. I took the stores and I walked.
2. I can drill you. I can drill the lot of you. Show me where.

### C5 · The Drifter
File: `art/intro/classes/drifter.mp3` · words.gd:1817 · Card: "Found on the road, in Kev's first story"
Voice (class_cards.md): "A woman in her twenties, Bristol; light and restless"

1. Kev found me on the ring road, walking the way the lorries go.
2. I don't stop anywhere long. Lucky for you, I'm quick.

*(The game and class_cards.md both say "on the ring road", but recording_list.md has "on the road". The game's words
are used here. The card's own line says "Found on the road", so pick one if you'd rather they matched.)*

---

## 5. Designed, not built: the Poacher's card and the tutorial

These are 28 Oct drafts from docs/design/tutorial.md and recording_list.md §4, parked behind the playtest. **None of
this is in the game's text yet**, so a take would have nothing to play under. Record them now only if you want them
ready. The words are drafts and can be changed.

### P1 · The Poacher's class card
File: `art/intro/classes/poacher.mp3` · Card (tutorial.md): "Off the hedge at the garages, the day you went out with nothing"
Voice: no brief in the docs. A suggestion in the class cards' style: "A man in his sixties, rural West Wales; quiet,
unhurried, says as little as he can"

1. I had the village in rabbits before anyone knew they'd need them.
2. Quiet's the trick. You don't hear me coming, and neither do they.

### T1-T9 · The tutorial
Files: `art/intro/tutorial/<take>.mp3`, one take per beat · Speaker: the narrator unless marked

| Take | Line |
|---|---|
| `1_arrive.mp3` | The garages ~~behind the camp~~ **out the back**. Nothing on you but a coat. Someone's in there. *(language.md: "camp" isn't the game's word; home is Home)* |
| `2_one_man.mp3` | He's seen you. You hit what you can; he hits back. Watch your HP, not his. |
| `3_med.mp3` | A bandage. In the rig it's used when it gets bad. Click it to use it now. |
| `4_move.mp3` | Throw a brick. It costs energy and takes a while to come back. The one in front can't fire while he's seeing stars. |
| `5_gang.mp3` | More of them. The number over a man is the one you're hitting. Two can fire on you; the rest wait their turn. |
| `6_crate.mp3` | Cleared. Now you search, a crate at a time. What it gives lands on the floor. |
| `7_pack.mp3` | Drag it into the pack. It has a shape, and so does the pack. R turns what you're holding. |
| `8_way_out.mp3` | Another gang's coming. Get out now, or stay and lose it all. |
| `9_poacher.mp3` | *(narrator)* A shot from the hedge. Then another. / *(the Poacher)* Up. You're not built for this, and I'm not carrying you. |

Notes: beats 3 and 7 name mouse and keyboard controls ("Click it", "R turns"). A pad player (the Deck) would hear the
wrong control, so these may want a neutral wording before they're recorded. Beat 9 has two voices in one file; join
the two clips.

---

## 6. Checked and not voiced

These name a speaker or a voice in the code, but they're text only and have no takes designed:

- **The Issue's card** (main.gd:1105, `Words.ISSUE`, words.gd:1784): it uses the voiced card's player, but with no
  take and no cues. Line 1 is the Issuer's: "Everything you've got is worth what I say it is. Today, that's this." The
  rest are figures. It could take a one-line take if you want the Issuer heard, but the_issue.md lists sound only, not
  voice.
- **The radio's lines** (`Words.RADIO`, words.gd:354-395: the loop, Kev, the army net, the medic and the Fence on the
  CB), **Kev's story beats** (`Words.STORY`, words.gd:153), **the rebuild's** and **the signals'** lines, and the
  opening's log lines (`Words.OPENING`): log and card text. "Voice" in radio.gd and kev_story.gd is only the
  speaker's text colour.
- people.gd holds portraits only. intro.gd is the studio card and has no voice.

## 7. Stale text on the voiced cards that isn't read aloud (for the rename pass)

These are on the same cards, but not in any take, so they need no recording:

- The rooms' names: "The Pitch" becomes **Home**, "Workshop" becomes **The Workshop**, "Radio" becomes **The Radio**
  (language.md).
- Training's tiles: "Their past" becomes **Their class**, "Their trees" becomes **Their web**, "The crew · Pick who goes
  out" becomes **Your runners · Pick who goes out** (crew = a faction only).
- The class card's edge "Its trees" (`Words.CLASS_CARD`) becomes **Its web**.
- The Fence's tile "His stock, and sealed lots" becomes **His stock, and closed lots**.
- Home's tile "What the Pitch holds" becomes **What home holds**.
- The Map's tile "Zones · Each opens at its level" becomes **Areas · Each opens at its level** ("zone" is off screen).
- On the air's heading "Deeper" becomes **Further out** (as A3).
- `Words.ROOM_INTROS` is still in the old order, with the Fence before the Workshop. It's harmless, but it could
  follow the new unlock order when the takes are wired in.
