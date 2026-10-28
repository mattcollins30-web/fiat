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

## 4. Record fresh: the tutorial and the Poacher (drafts, 28 Oct; docs/design/tutorial.md - change any words)

The Poacher's card. File: `art/intro/classes/poacher.mp3`.
1. I had the village in rabbits before anyone knew they'd need them.
2. Quiet's the trick. You don't hear me coming, and neither do they.

The tutorial: one take a beat, the narrator (the room cards' voice) unless marked. Files: `art/intro/tutorial/<take>.mp3`.

| Take | Line |
|---|---|
| `1_arrive.mp3` | The garages behind the camp. Nothing on you but a coat. Someone's in there. |
| `2_one_man.mp3` | He's seen you. You hit what you can; he hits back. Watch your HP, not his. |
| `3_med.mp3` | A bandage. In the rig it's used when it gets bad. Click it to use it now. |
| `4_move.mp3` | Throw a brick. It costs energy and takes a while to come back. The one in front can't fire while he's seeing stars. |
| `5_gang.mp3` | More of them. The number over a man is the one you're hitting. Two can fire on you; the rest wait their turn. |
| `6_crate.mp3` | Cleared. Now you search, a crate at a time. What it gives lands on the floor. |
| `7_pack.mp3` | Drag it into the pack. It has a shape, and so does the pack. R turns what you're holding. |
| `8_way_out.mp3` | Another gang's coming. Get out now, or stay and lose it all. |
| `9_poacher.mp3` | A shot from the hedge. Then another. *(narrator)* / Up. You're not built for this, and I'm not carrying you. *(the Poacher)* |
