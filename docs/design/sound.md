# Sound (13 Oct, Matt: "the in engine stuff got old"; design, not built)

ElevenLabs again, through the API this time: a manifest of every sound (this list), and a script on Matt's machine
that calls the sound-effects endpoint for each line, writes art/sound_new/<id>.mp3, and skips what exists (as the
pixellab batch does). The key lives in tools/elevenlabs_secret.txt on Matt's machine only - never read into the
cloud, never committed (as pixellab_secret.txt). Keepers move to art/sound/; the game plays mp3 as it does wav.

Today there are thirteen: three zone ambients, rain, six gun ticks, the gang's sting, the door, a rare find.

## The list (to cut and add to before anything is spent)

Each: id · when it plays · what it is (the prompt's heart; every prompt gets the same tail - "close, dry, real, a
grey British estate, no music") · length · loop.

### Places (loops, under everything)
| id | when | what | len |
| --- | --- | --- | --- |
| amb_outskirts | a run in the Outskirts | wind over allotments, a crow, a distant dog, wire fence ticking | 30 s loop |
| amb_estate | the Estate | a tower block's hum, a car alarm far off, a shopping trolley rattling | 30 s loop |
| amb_town | the Town | an empty high street, a shutter banging in the wind, a pigeon | 30 s loop |
| amb_city | the City | a motorway with nothing on it, a helicopter far off, a siren that stops | 30 s loop |
| amb_yard | the camp, between runs | a brazier crackling, a radio murmuring in another room, a kettle | 30 s loop |
| rain | rain on a site | steady rain on corrugated roofs and puddles | 30 s loop |
| fog | fog on a site | muffled stillness, dripping, a foghorn far off | 30 s loop |
| night | a night run | crickets, a fox screaming far off, one streetlight buzzing | 30 s loop |

### The fight
| id | when | what | len |
| --- | --- | --- | --- |
| shot_improvised | a nail gun, a bolt gun | a pneumatic nail gun firing, a clack and a hiss | 0.4 s |
| shot_pistol | a pistol | a single pistol shot, short and flat | 0.5 s |
| shot_shotgun | a shotgun | a shotgun blast and the pump | 0.8 s |
| shot_rifle | a rifle | a single rifle crack with a short tail | 0.7 s |
| shot_smg | an SMG | a short burst of three | 0.5 s |
| swing_melee | melee | a heavy swing and a dull thud | 0.5 s |
| swing_blade | a knife, machete, axe | a blade whipping through air and biting | 0.5 s |
| dry_click | a gun out of rounds | the click of an empty gun | 0.3 s |
| reload | rounds into a gun from the rig | a magazine slapped in | 0.6 s |
| hit_taken | the runner hit hard (a chunk of HP) | a grunt and cloth tearing | 0.5 s |
| guard_break | Guard gone | glass-like crack, a shield giving way | 0.6 s |
| kill | one of them down | a body hitting tarmac | 0.6 s |
| gang_arrives | a gang comes (replaces the sting) | running footsteps and shouts, getting closer | 1.5 s |
| head_door | a head steps out (replaces the door) | a heavy door kicked open, a voice | 1.5 s |
| head_down | a head beaten | a body falling and a long breath out | 1.5 s |
| burn / bleed / poison / shock / frost | a dot lands on them | a whoosh of flame / a wet slash / a hiss / an electric snap / ice crackling | 0.5 s each |
| grenade | a grenade from the rig | a pin, a throw, a muffled blast | 1.5 s |
| med_use | a med used | a plaster tearing, a bottle cap | 0.8 s |
| low_hp | HP under a quarter | a heartbeat, slow | 2 s loop |
| clock_warn | the clock's last ten seconds | a wristwatch ticking, louder | 1 s loop |
| way_out | the way out starts | a door shoved, running | 1 s |
| extract | home with the pack | a van door sliding shut, an engine | 2 s |
| death | the runner dies | a fall, a radio hiss cutting out | 2 s |

### The search
| id | when | what | len |
| --- | --- | --- | --- |
| crate_cardboard | a cardboard box opened | cardboard flaps torn open | 0.8 s |
| crate_ammo_tin | an ammo tin | a steel latch snapping open | 0.6 s |
| crate_jewellery | a jewellery box | a small hinge creak and a music-box note | 0.8 s |
| crate_toolbox | a toolbox | a metal toolbox clattering open, trays sliding | 0.8 s |
| crate_medicine | a medicine cabinet | a mirrored door squeaking, bottles rattling | 0.8 s |
| crate_filing | a filing cabinet | a steel drawer rolling out | 0.8 s |
| crate_safe | a safe | a combination dial, a heavy door swinging | 1.2 s |
| crate_military | a military crate | a crowbar prising nails out of wood | 1.2 s |
| crate_locked | a locked crate passed over | a padlock rattled, no give | 0.6 s |
| crate_keys | a locked crate opened with the Keys | a ring of keys, one turning | 0.8 s |
| search_tick | each search done | rummaging through things, short | 0.5 s |
| picked_clean | every crate open | a last drawer shut, quiet | 0.8 s |
| find_common / find_rare / find_unique | a find on the floor by rarity (replaces "found") | a soft thunk / a small chime / a deeper bell | 0.5 / 0.8 / 1.2 s |
| take | off the floor into the pack | a bag zip | 0.4 s |
| ditch | ditched | something dropped on concrete | 0.4 s |
| no_room | no room in the pack | a dull bump, a strap pulling tight | 0.4 s |
| dog_sniff | the dog noses a crate | a dog sniffing, a short huff | 0.8 s |

### The camp and the UI
| id | when | what | len |
| --- | --- | --- | --- |
| ui_click | a button | a soft card click | 0.1 s |
| ui_tab | a rail room | paper turned | 0.2 s |
| equip | gear put on | a buckle, cloth | 0.5 s |
| sell / buy | the Fence | coins in a tin / a tin tipped out | 0.5 s |
| craft | the Workshop | a vice, a few hammer taps | 1 s |
| build | a Yard building | hammering and a saw, short | 1.5 s |
| level_up | a level | a match struck and a fire catching | 1 s |
| point_spent | a tree node | a pencil tick on paper | 0.3 s |
| heal_clinic | the Clinic treats | a curtain drawn, a pen on a clipboard | 1 s |
| radio_on | a radio line comes in | radio static tuning to a voice | 1 s |
| radio_code | a code tuned | a dial clicking through stations | 0.8 s |
| gate_open | a room opens (a head's thing) | a padlock dropping off a chain | 1 s |
| the_end | the deeds burned or sold | paper catching fire / a door closing quietly | 3 s |

About seventy, most under a second. Voices (the radio's lines read aloud) are a separate question: they'd cost far more
and change how the radio reads - left out unless Matt wants them.

## Build (after Matt's cut)
- tools/sound_manifest.json from this list; tools/eleven_batch.py on Matt's machine (key from the local secret file;
  skips files that exist; `--only <id>`, `--force`); the endpoint and its options checked against ElevenLabs' docs
  when it's built.
- sound.gd: one table from event to id, a few players so sounds overlap (a shot under a gang arriving), each with
  its volume; loops crossfade; the old thirteen fall back where a new one isn't there.
- The smoke: every id in the table has a file or a fallback; sounds off plays nothing.

## Built (13 Oct): the manifest and the batch
- tools/make_sound_manifest.py writes tools/sound_manifest.json: the list above (sell/buy, the five elements, the finds
  and the ending split one a file), 71 sounds, 110 files - the busy ones (shots, swings, hits, kills, clicks) in two or
  three takes - about 330 s in all. Two added for the run view: `incoming` (their shots smacking into the wall by you)
  and `duck` (dropping behind it). Loops (the places, the heartbeat, the watch) sent with `loop`.
- tools/eleven_batch.py on Matt's machine: POST https://api.elevenlabs.io/v1/sound-generation, model
  eleven_text_to_sound_v2, mp3_44100_128; the key from tools/elevenlabs_secret.txt (gitignored), sent only as the
  `xi-api-key` header; skips what's on disk; --dry-run, --only, --force. Out to art/sound_new/.
- The key: Restrict Key on, Sound Effects access on, everything else off.
- Music (13 Oct, Matt: "looping music - nothing crazy - title, menu and fight and search"): four instrumental tracks
  through ElevenLabs' music endpoint (POST /v1/music, music_v1, force_instrumental; title 75 s, camp 120 s, fight and
  search 90 s). The endpoint has no loop option: each is asked to run steady with no intro or ending, and the game
  crossfades its tail into its top. The key needs Music access as well as Sound Effects.
- sound.gd rebuilt: one table of every id (its level, the old placeholder it falls back to), takes picked at random,
  ten one-shot players, five loop layers (place, weather, heartbeat, watch, music) each crossfading. Everything
  follows the sim each refresh - shots at the gun's rate (the click when dry), their fire now and then, a gang, a head,
  a kill, a hit, Guard gone, a med, the way out, an element landing; a crate taken in hand (the keys first if locked),
  a lock passed by, each search, picked clean, a find on the floor by its worth, taken, ditched; at home the
  chronicle's moments (a level, a point, a build, a gamble, a gate, the run home or a death) and a sale. Buttons click,
  the rail's rooms turn a page. Music: the title, the camp, the fight (a head's too), the search. The pause's Sound
  row goes round: on, no music, off. New files are picked up at the title. Not wired yet: `duck`, `reload`, `grenade`,
  `no_room`, `dog_sniff`, `the_end_sell`, `radio_on` (made, played once the moments that want them say so).
