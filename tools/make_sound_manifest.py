"""Fiat's sounds through ElevenLabs' sound-effects API (13 Oct, docs/design/sound.md - Matt: "the in engine stuff got
old"). Writes tools/sound_manifest.json from the list below; tools/eleven_batch.py runs it on Matt's machine.

Each: id, what it is (the prompt's heart), seconds, loop, variants (the busy ones get a few takes so a fight isn't one
sample over and over), and a tail by kind - the world's sounds get "close, dry, real...", the UI's stay soft and plain."""
import json

WORLD = "Close, dry and real, recorded on location in a grey post-collapse British town. No music, no voices speaking words."
AMB = "A continuous field recording, no single event dominating, no music, no voices speaking words."
UI = "A short, soft, clean interface sound for a game menu, quiet and understated, no music."

# id, prompt, seconds, loop, variants, kind
S = [
    # places: loops under everything
    ("amb_outskirts", "Wind over overgrown allotments at the edge of a town, a crow calling now and then, a dog barking far off, a wire fence ticking in the wind", 30, True, 1, "amb"),
    ("amb_estate", "The hum of a tower block estate at dusk, a car alarm far off, a shopping trolley rattling over paving somewhere, distant shouting that fades", 30, True, 1, "amb"),
    ("amb_town", "An empty high street, a metal shop shutter banging in the wind, pigeons, litter scraping along the pavement", 30, True, 1, "amb"),
    ("amb_city", "An empty motorway with nothing on it, wind across concrete, a helicopter far off, a siren that starts and stops", 30, True, 1, "amb"),
    ("amb_yard", "A camp at night: a brazier crackling, a radio murmuring in another room, a kettle starting to boil, wind against corrugated iron", 30, True, 1, "amb"),
    ("rain", "Steady rain on corrugated metal roofs and puddles in a yard", 30, True, 1, "amb"),
    ("fog", "Muffled stillness in thick fog, water dripping from gutters, a foghorn very far off", 30, True, 1, "amb"),
    ("night", "A town at night: crickets, a fox screaming far off, one streetlight buzzing", 30, True, 1, "amb"),
    # the fight
    ("shot_improvised", "A pneumatic nail gun firing once: a hard clack and a short hiss of air", 0.6, False, 3, "world"),
    ("shot_pistol", "A single pistol shot outdoors, short and flat, a little slap back off brick walls", 0.7, False, 3, "world"),
    ("shot_shotgun", "A single shotgun blast outdoors followed by the pump action racking", 1.0, False, 3, "world"),
    ("shot_rifle", "A single rifle shot outdoors, a sharp crack with a short echo down a street", 0.9, False, 3, "world"),
    ("shot_smg", "A short three-round burst from a submachine gun outdoors", 0.7, False, 3, "world"),
    ("swing_melee", "A heavy blunt swing through the air and a dull thud into a body", 0.6, False, 3, "world"),
    ("swing_blade", "A blade whipping through the air and biting into cloth and flesh", 0.6, False, 3, "world"),
    ("incoming", "Gunshots from across a street aimed at the listener, bullets smacking into a brick wall close by and chips of brick falling", 1.0, False, 3, "world"),
    ("duck", "Someone dropping into a crouch behind a low brick wall: a jacket rustling, a knee scraping concrete, a sharp breath", 0.6, False, 2, "world"),
    ("dry_click", "The hollow click of an empty gun's trigger, then nothing", 0.5, False, 1, "world"),
    ("reload", "A pistol magazine slapped into the grip and the slide racked", 0.8, False, 2, "world"),
    ("hit_taken", "A man grunting in pain as a hit lands and jacket fabric tears", 0.6, False, 3, "world"),
    ("guard_break", "A crack like thick safety glass giving way, a shield breaking", 0.7, False, 1, "world"),
    ("kill", "A body falling heavily onto wet tarmac", 0.7, False, 3, "world"),
    ("gang_arrives", "Several people running closer down a street, trainers on tarmac, rough shouts getting nearer", 2.0, False, 2, "world"),
    ("head_door", "A heavy metal door kicked open and banging against a wall, one gruff shout", 1.5, False, 1, "world"),
    ("head_down", "A big man falling to the ground and one long last breath out", 1.6, False, 1, "world"),
    ("burn", "A whoosh of flame catching on clothing and crackling", 0.7, False, 2, "world"),
    ("bleed", "A wet slash and a spatter", 0.6, False, 2, "world"),
    ("poison", "A thick hiss of gas from a canister and a cough", 0.7, False, 2, "world"),
    ("shock", "A sharp electric snap and buzz, a taser arcing", 0.6, False, 2, "world"),
    ("frost", "Ice crackling and creaking as it forms quickly", 0.7, False, 2, "world"),
    ("grenade", "A grenade pin pulled, a throw, a moment, then a heavy muffled blast down the street", 2.0, False, 1, "world"),
    ("med_use", "A sticking plaster torn off its backing and a small pill bottle cap unscrewed", 1.0, False, 1, "world"),
    ("low_hp", "A slow, heavy human heartbeat, muffled", 2.0, True, 1, "world"),
    ("clock_warn", "A wristwatch ticking loudly and steadily, close to the ear", 1.0, True, 1, "world"),
    ("way_out", "A door shoved open with a shoulder and running footsteps away", 1.2, False, 1, "world"),
    ("extract", "A van's side door sliding shut and the engine pulling away", 2.0, False, 1, "world"),
    ("death", "A man falling to the ground and a handheld radio's hiss cutting out to silence", 2.0, False, 1, "world"),
    # the search
    ("crate_cardboard", "Cardboard box flaps torn open and things shifted inside", 0.9, False, 2, "world"),
    ("crate_ammo_tin", "A steel ammunition tin's latch snapped open and the lid lifted", 0.7, False, 2, "world"),
    ("crate_jewellery", "A small jewellery box's hinge creaking open and a single tinkling music-box note", 0.9, False, 1, "world"),
    ("crate_toolbox", "A metal toolbox clattering open, its trays sliding out, tools rattling", 0.9, False, 2, "world"),
    ("crate_medicine", "A mirrored bathroom cabinet door squeaking open, pill bottles rattling", 0.9, False, 1, "world"),
    ("crate_filing", "A steel filing cabinet drawer rolling out on its runners and papers rustling", 0.9, False, 1, "world"),
    ("crate_safe", "A safe's combination dial clicking round and a heavy steel door swinging open", 1.4, False, 1, "world"),
    ("crate_military", "A crowbar prising nails out of a wooden military crate, the lid coming free", 1.4, False, 1, "world"),
    ("crate_locked", "A padlock rattled hard on a hasp that doesn't give", 0.7, False, 1, "world"),
    ("crate_keys", "A ring of keys jingling and one key turning in a padlock, which clicks open", 1.0, False, 1, "world"),
    ("search_tick", "Hands rummaging quickly through things in a box", 0.6, False, 3, "world"),
    ("picked_clean", "A last drawer pushed shut, then quiet", 0.9, False, 1, "world"),
    ("find_common", "A small object set down: a soft wooden thunk", 0.5, False, 1, "world"),
    ("find_rare", "A small bright metallic chime, like a spoon on a glass", 0.8, False, 1, "world"),
    ("find_unique", "A deep resonant bell struck once and ringing out", 1.4, False, 1, "world"),
    ("take", "A rucksack zip pulled shut quickly", 0.5, False, 2, "world"),
    ("ditch", "Something dropped on concrete", 0.5, False, 2, "world"),
    ("no_room", "A dull bump and a rucksack strap pulled tight", 0.5, False, 1, "world"),
    ("dog_sniff", "A dog sniffing eagerly at a box and giving a short huff", 0.9, False, 1, "world"),
    # the camp and the UI
    ("ui_click", "A soft card-stock click", 0.3, False, 3, "ui"),
    ("ui_tab", "A sheet of paper turned over", 0.3, False, 2, "ui"),
    ("equip", "A buckle fastened and cloth settling", 0.6, False, 2, "world"),
    ("sell", "A few coins dropped into a tin", 0.6, False, 1, "world"),
    ("buy", "A tin of coins tipped out onto a wooden counter", 0.6, False, 1, "world"),
    ("craft", "A bench vice tightened and a few light hammer taps on metal", 1.2, False, 1, "world"),
    ("build", "A short burst of hammering and a hand saw on timber", 1.6, False, 1, "world"),
    ("level_up", "A match struck and a small fire catching and growing", 1.2, False, 1, "world"),
    ("point_spent", "A pencil tick on paper", 0.4, False, 1, "ui"),
    ("heal_clinic", "A hospital curtain drawn on its rail and a pen scratching on a clipboard", 1.2, False, 1, "world"),
    ("radio_on", "Radio static tuning through noise until it settles on a clear carrier", 1.2, False, 1, "world"),
    ("radio_code", "An old radio dial clicking through stations, fragments of static", 0.9, False, 1, "world"),
    ("gate_open", "A heavy padlock and chain dropping off a gate onto the ground", 1.2, False, 1, "world"),
    ("the_end_burn", "Paper catching fire and burning steadily", 3.0, False, 1, "world"),
    ("the_end_sell", "A door closing quietly and a latch clicking", 3.0, False, 1, "world"),
]

TAIL = {"world": WORLD, "amb": AMB, "ui": UI}
INFLUENCE = {"world": 0.5, "amb": 0.35, "ui": 0.6}
jobs = []
for sid, what, secs, loop, variants, kind in S:
    for v in range(variants):
        jobs.append({"id": sid if variants == 1 else "%s_%d" % (sid, v + 1), "sound": sid,
                     "text": "%s. %s" % (what, TAIL[kind]), "duration_seconds": max(0.5, min(30.0, secs)),
                     "loop": loop, "prompt_influence": INFLUENCE[kind]})
out = {"_readme": [
    "FIAT SOUNDS (13 Oct, docs/design/sound.md): ElevenLabs sound effects, one job a file, art/sound_new/<id>.mp3. Busy sounds have takes (_1, _2, _3) the game picks between.",
    "Run on Matt's machine: python tools/eleven_batch.py   (--dry-run lists and totals the seconds; --only <id or sound>; --force remakes). The key: tools/elevenlabs_secret.txt, one line, never committed.",
], "output_format": "mp3_44100_128", "model_id": "eleven_text_to_sound_v2", "jobs": jobs}
json.dump(out, open("tools/sound_manifest.json", "w"), indent=1)
print("%d sounds, %d files, %.0f s in all" % (len(S), len(jobs), sum(j["duration_seconds"] for j in jobs)))
