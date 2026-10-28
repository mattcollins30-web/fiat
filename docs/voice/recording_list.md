# Voice lines to record

Kept by Claude (27-28 Oct). Takes go where the game looks for them: `art/intro/voice/<take>.mp3`,
`art/intro/rooms/<take>.mp3`, `art/intro/classes/<take>.mp3`. After a take is in, its cues (when each line
starts, in seconds) go in words.gd. Claude reads them off the take.

Checked against the takes in the repo (all recorded 14 Oct). The opening's six scenes, the three on-the-air
scenes and eight of the nine room cards still match their words; only dashes and one comma moved, nothing a
listener would hear.

## 1. Re-record: the words changed under the take

| Take | File | Why | Line 1 | Line 2 |
|---|---|---|---|---|
| The Workshop's card | `art/intro/rooms/workshop.mp3` | The Workshop opens at the Carpet Man now, with his fitter's kit | The Carpet Man's fitter's kit, laid out on the bench. Proper tools, for once. | Guns get better here, part by part. *(unchanged)* |

## 2. Re-record, your call: the words still play, but the game's moved on

| Take | File | Why | Now says | Could say |
|---|---|---|---|---|
| On the air, 3 ("Deeper") | `art/intro/voice/air_3.mp3` | Depth and digging went from the game; signals are levels now | "...Tune one in and it tells you where to dig. / The deeper you go, the more you'll hear..." | "...Tune one in and it tells you where to go. / The further out you go, the more you'll hear. Go carefully. Somebody's always listening back." |

## 3. Record fresh: never had a take

The class cards (25 Oct; their lines go on the clock until a take is in). Two lines each, in the class's own
voice. File: `art/intro/classes/<voice>.mp3`.

| Class | File | Line 1 | Line 2 |
|---|---|---|---|
| The Paramedic | `paramedic.mp3` | Half of what's in the vet's bag works on people. I checked. | The doctor keeps the Clinic. Somebody has to go out to them. |
| The Doorman | `doorman.mp3` | Twelve years on his door. Near the end he paid me in rugs. | Nobody got past me then. Nobody gets past me now. |
| The Scrapper | `scrapper.mp3` | I kept the Bank's lifts running till there was nothing left to lift. | Give me a bin bag and an afternoon. I'll give you a gun. |
| The Recruit | `recruit.mp3` | Nobody signed me out. I took the stores and I walked. | I can drill you. I can drill the lot of you. Show me where. |
| The Drifter | `drifter.mp3` | Kev found me on the road, walking the way the lorries go. | I don't stop anywhere long. Lucky for you, I'm quick. |

## 4. To come: written once the tutorial's agreed

- The Poacher's card (he has none: he's open from the start). Draft below; it waits on the tutorial's design.
- The tutorial's lines.

Poacher, draft (file `art/intro/classes/poacher.mp3`):
1. I had the village in rabbits before anyone knew they'd need them.
2. Quiet's the trick. You don't hear me coming, and neither do they.
