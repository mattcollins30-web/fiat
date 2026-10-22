"""The web's art and what was parked with it (22 Oct, Matt: "proceed with the art manifest ... all the tree nodes and
whatever else we had parked"; then "we need art for the regions elements, maps regions labels and dial and pitch
canvases too. build the full manifest"). Two manifests:

  python3 tools/make_web_art_manifest.py
    -> tools/pixellab_web_art_test_manifest.json   (16: a dozen node pictures across the kinds, two region emblems,
                                                    the Dial's backdrop, the Scrapper's new face)
    -> tools/pixellab_web_art_manifest.json        (the lot, the test's jobs included)

  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_web_art_manifest.json
  (++ --dry-run to list; ++ --only <name> ++ --force to reroll)

What's in it, and where each lands (every file new; nothing live is touched until the wiring, below):
- The nodes (art/nodes/<slug>.png, 64 px, transparent): every notable, keystone, capstone and bridge of Training's
  class and element regions, the Map's 35 ranked nodes, the Pitch's 80 picks and 8 ranks, the ring's five kinds.
  Small nodes and fillers stay dots (6-9 px: nothing reads there). The slug is the node's name (Training: one
  picture a name - the ten bridges share "the second past"; the Map's by its atlas key; the Pitch's by its pick id).
- The regions' emblems (art/web/region_<slug>.png, 96 px, transparent): the six elements, the Map's three regions,
  the ring, the Pitch; and the ten class lanes (optional, the same shape).
- The canvases' backdrops (art/web/backdrop_<room>.png, 744 wide - the API's most - drawn x2 under the web): Training's,
  the Dial's, the Pitch's. Dark, even, nothing in them that competes with a node.
- The two figures parked from the playtest: the Scrapper's and the Poacher's portrait (art/people_new/, 128) and
  full-length figure (art/body_new/, 208 x 488), each a new look (the Scrapper "just awful"; the Poacher "reads too
  much like the Gamekeeper").
- The fight's cover walls (art/fight_new/<site>_cover.png, 744 x 173): the eleven not yet run from the fight kit's
  manifest (tools/pixellab_fight_kit_manifest.json; the Parade's and Ransacked Streets' landed with its test). One
  continuous piece at the API's widest - the duplication Matt saw was the live tiles repeating; a one-piece wall
  at the frame's width has nothing to tile. (The fight kit's 82 hands, 12 plates and 4 icons stay in that manifest.)

Wiring once the art is judged: web_view draws art/nodes/<slug>.png in place of the glyph when the file exists
(untinted; the glyph stays the fallback), a region's emblem beside its label, the backdrop under the links;
atlas.gd/yard_tree.gd/barracks.gd pass their backdrop; the figures and walls swap in by file name as before.
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}

# ------------------------------------------------------------------ the prompts' tails

ICON = ("A realistic painted pixel-art still-life of %s. One object centred and filling the frame, a single bold "
        "silhouette that still reads at a quarter of this size, soft directional overcast daylight, natural material "
        "rendering with painterly shading; no black outlines, not anime, not a cartoon, not a glossy video-game icon. "
        "Muted cool northern palette, worn, nothing new. Nothing else in the frame, no hands, no person, no text, no "
        "logos, no numbers, a transparent background.")
EMBLEM = ("A realistic painted pixel-art emblem of %s, as a painted sign on weathered metal would show it: one strong "
          "shape, centred, filling the frame, read at a glance from across a room. Soft overcast daylight, painterly "
          "shading, muted cool northern palette with %s; no black outlines, not anime, not a cartoon, not a glossy "
          "video-game badge. Nothing else in the frame, no person, no text, no lettering, no numbers, a transparent "
          "background.")
BACKDROP = ("Pixel art, a flat surface seen straight on, filling the whole frame edge to edge with no border, no frame, "
            "no vignette, no horizon: %s. Very dark and even, low contrast, muted blue-grey and slate palette with %s; "
            "a chart of lines and small discs is drawn on top of this, so nothing in it may stand out - no single object, "
            "no bright patch, no text, no lettering, no numbers, no people.")
PORTRAIT = ("A realistic painted pixel-art portrait, head and shoulders, of %s. Looking just past the viewer. Post-collapse "
            "Britain, overcast light. One person centred, filling the frame, no text, no border, plain dark background.")
FIGURE = ("A realistic painted pixel-art full-length figure of %s. The same person and clothes as the first reference "
          "image, in the pose and framing of the second: standing still, facing the viewer, weight on both feet, arms "
          "down and a little away from the body, hands empty, no weapon, no bag, no helmet. Head top near the top edge, "
          "boot soles near the bottom edge, the whole figure inside the middle of the frame. Cold light from above and "
          "slightly in front, the legs darker towards the boots, no ground shadow. Muted post-collapse British palette, "
          "one dark outline. Transparent background, no text, no border.")
WALL = ("Seen very close from behind, running unbroken across the whole width of the frame at the bottom: %s, as the cover "
        "a player crouches behind in a light-gun arcade game. One continuous piece edge to edge, no repeated sections, no "
        "seams. Only the cover, nothing above or behind it; its top edge uneven, filling the lower two thirds of the "
        "image. No packaging, signs or anything with lettering on it. Realistic painted pixel art, soft overcast light, "
        "muted cool northern palette, worn and lived-in, post-collapse Britain on a grey day; no black outlines, not "
        "anime, not a cartoon, not glossy; no text, no logos.")

# ------------------------------------------------------------------ the nodes: a name, an object

# Training's class regions: the notables, keystones, capstones hung and on the rails (data.gd TREES_SRC and WEB_EXTRA)
NODES = {
    # The Pitch (the camp's)
    "Double tap": "two spent brass pistol cases standing side by side on a plank",
    "Second wind": "a dented tin mug of tea steaming on an upturned crate",
    "Pack horse": "a heavy canvas rucksack with a bedroll strapped under it, standing on the ground",
    "The dog's share": "a muddy dog's rope lead and collar laid in a coil, the tag blank",
    "Home ground": "a wooden gate post with a faded red rag tied round it, seen from the front",
    "Good boots": "a pair of worn brown leather walking boots, relaced with string, seen from the side",
    "Well stocked": "a tin first-aid box with the lid open and three rolled bandages inside",
    "Market day": "a wooden market stall's trestle with a set of brass scales on it",
    "The kettle": "a battered steel camping kettle on a gas ring, steam from the spout",
    "Word of mouth": "a cheap chalkboard easel with a few chalk strokes on it and no words, outside a pub door",
    # Stalking (the Poacher)
    "Rifleman": "a scoped hunting rifle laid flat on a folded wax jacket",
    "One shot": "a single long rifle cartridge standing upright on a wooden post",
    "Rat bait": "a brown glass bottle with a cork, a hand-painted skull on a tied-on tag, no lettering",
    "Night work": "a dark hedgerow under a thin crescent moon, one lit window far off",
    "Dead quiet": "a rabbit snare's brass wire noose set on a peg in short grass",
    "In the hide": "a canvas hide's slit window from inside, a rifle barrel resting on the sill",
    "The second past": "an old leather suitcase with two different railway labels pasted on it, standing by a door",
    "Still air": "a wet finger held up to the wind, a wisp of chimney smoke going straight up behind it",
    "Long glass": "a brass telescopic rifle sight with its lens caps hanging on cords",
    "Sit tight": "a folding canvas shooting stool with a flask leaning against its leg",
    "Clocked": "a brass pocket watch open on a plank, its glass cracked",
    "Snare and wait": "a square of wire-mesh trap on four pegs, a trail of grain leading in",
    # Snares
    "Quiet feet": "a pair of soft-soled poacher's boots with their laces tied round the ankles",
    "Trapline": "three brass snares on a long cord, laid out on a flat stone",
    "Cold snap": "a steel rabbit trap with frost on its jaws",
    "Early doors": "a pub's wooden door with the bolt drawn and a milk bottle on the step",
    "Poached": "a brace of pheasants hung by the neck on a nail in a barn door",
    "Gaps in the hedge": "a hawthorn hedge with a gap pushed through it, a tuft of wool on a thorn",
    "Game bag": "a canvas-and-leather game bag with a net front, bulging, slung on a fence post",
    "Off the path": "a muddy track forking off a tarmac lane into bracken",
    "Twine": "a ball of orange baler twine with a loose end hanging, on a bale",
    # Muscle (the Doorman)
    "Shotgunner": "a sawn-down pump shotgun laid across a pair of knuckles",
    "Bodyline": "a heavy leather belt with a steel buckle, cinched tight, seen from the front",
    "Glassing": "a broken pint glass held by its base, the edge jagged",
    "Loud": "a big silver handbell on a wooden handle, mid-swing",
    "Iron": "a cast-iron kettlebell on a concrete floor, its handle worn bright",
    "Bulk": "a pair of broad padded shoulders in a black bomber jacket, seen from behind, no head in frame",
    "Shoulder": "a shotgun's wooden stock with a rubber recoil pad, seen end on",
    "Hard case": "a scuffed black steel flight case with brass corners, closed",
    "Off the canvas": "a boxing ring's corner post and ropes, a towel over the top rope",
    "Bin lid": "a dented galvanised steel dustbin lid held up like a shield, seen from the front",
    # The door
    "Chokepoints": "a narrow brick alley mouth with a wooden pallet wedged across it",
    "One at a time": "a nightclub's velvet rope on two brass posts across a doorway",
    "Hands on": "a pair of big scarred bare knuckles clenched together, seen from the front",
    "Through the lot": "a baseball bat mid-swing, three skittles flying",
    "Stand and fight": "a doormat on a stone step that reads nothing, a boot planted on it",
    "Held": "a riot shield's scratched perspex face, a crack across one corner",
    "Squared up": "a pair of boots planted shoulder-width on wet tarmac, seen from above",
    "Doorframe": "a heavy wooden doorframe with a steel strike plate and no door",
    "Hands up": "a pair of raised open palms in fingerless gloves, seen from the front",
    "Big lad": "a wide black bouncer's overcoat on a hook, a clip-on tie over the collar",
    "Last orders": "a brass bar bell on a chain over a pub counter, a hand pulling the rope",
    # Triage (the Paramedic)
    "Fast work": "a roll of bandage half unwound beside a pair of trauma shears",
    "Field surgery": "a steel kidney dish with a scalpel and a curved needle in it",
    "Syringe": "a glass syringe with a steel plunger, a drop at the needle's tip",
    "Walking wounded": "a crutch leaning on a wall with a bloodied bandage tied round its grip",
    "Clean hands": "a pair of blue nitrile gloves laid flat on a steel tray",
    "Good hands": "a pair of hands pressing a folded dressing to a bandaged forearm",
    "Quick dressing": "a torn-open sterile dressing pack, the pad half out",
    "Grab bag": "a green paramedic's shoulder bag with a reflective strip, the flap open",
    "Worst first": "a paper triage tag with a red stripe on a string, no lettering",
    "Jab": "a plastic auto-injector pen with its cap off, standing on a tin lid",
    # Shifts
    "Walk it off": "a pair of ambulance-green trousers' legs mid-stride on a wet pavement",
    "Not today": "a hospital's resuscitation paddles on their coiled leads",
    "Ice pack": "a blue gel ice pack frosted white, on a folded towel",
    "Second shift": "two tin mugs of coffee on an ambulance's dashboard at dawn",
    "Transfusion": "a bag of blood hung on a steel drip stand, its line coiled",
    "Double shift": "a wall clock with both hands near twelve, a tea ring on the wall beside it",
    "Flask": "a steel vacuum flask with its cup lid half off, steaming",
    "Regulars": "a row of three worn plastic waiting-room chairs bolted together",
    "Last bus": "a bus stop's timetable board with the paper torn off, a bus's tail lights far down the road",
    "Clocking off": "a time clock on a wall with a card half punched in",
    # Stripping (the Scrapper)
    "Bodger": "a nail gun with a sawn-off stock bolted to it, held together with tape",
    "Nothing wasted": "a workbench's biscuit tin full of bent nails, screws and washers",
    "Live wire": "a frayed black cable with its copper core bared and sparking",
    "Quiet hands": "a pair of oily hands in cut-off gloves turning a small screwdriver",
    "Jerry-rigged": "a pipe-and-plank rifle lashed together with wire and hose clips",
    "Sheet metal": "a dented square of galvanised sheet with a bolt through one corner",
    "Socket set": "an open steel socket set, half the sockets missing",
    "Oily rag": "a filthy oil-soaked rag hanging from the back pocket of overalls",
    "Salvage": "a shopping trolley heaped with copper pipe and a car battery",
    "Workbench": "a wooden workbench with a bench vice and a hacksaw hung on a nail",
    "Breaker's yard": "a crushed car on top of another in a yard, a crane's hook above",
    # Fencing
    "Magpie": "a magpie perched on a fence post with a ring in its beak",
    "Buyer's market": "a set of brass pan scales with a stack of coins on one side and a gun part on the other",
    "Blowtorch": "a brass plumber's blowtorch with a blue flame",
    "Hoarder": "a lock-up garage crammed to the door with boxes and a bicycle wheel",
    "The lot": "an auctioneer's wooden gavel on its block",
    "Haggler": "two hands shaking over a market stall, one in a fingerless glove",
    "Shop local": "a corner shop's bell on a coiled spring over a door",
    "Pub talk": "two pint glasses half full on a beer mat, a folded note between them",
    "Back pocket": "a worn leather wallet half out of the back pocket of jeans",
    # Moving on (the Drifter)
    "Spray": "a compact submachine gun with a magazine taped to a spare, muzzle up",
    "Never there": "an empty wet car park at night with one streetlamp, no one in it",
    "Bottle and rag": "a glass bottle with a rag stuffed in its neck, the rag's tip burning",
    "Hit and run": "a moped on its side stand with its engine running, exhaust haze",
    "Ghost": "a closed door with a key still in the lock and a dropped glove on the step",
    "Breather": "a cigarette burning on the edge of a low wall, nobody holding it",
    "Tarmac": "a wet strip of road with a white dashed line running off into the distance",
    "Thumb out": "a thumb out at the roadside, a holdall on the verge, a lorry's headlights far off",
    "Light pack": "a small faded daysack with one strap, nearly empty",
    "B-roads": "a leaning cast-iron road signpost with its finger boards blank",
    "On a roll": "three dice on a pub table, all showing sixes",
    # Luck
    "Dead man's shoes": "a pair of polished black shoes left neatly at the end of a bed",
    "All or nothing": "a single poker chip balanced on edge on a green baize",
    "Jump start": "a pair of red and black jump leads clipped to a car battery, a spark at the clip",
    "Light fingers": "a hand slipping a folded paper out of a coat's inside pocket",
    "Loaded dice": "two dice, one cut open to show the lead inside",
    "Lucky penny": "an old copper penny with a hole drilled in it, on a string",
    "Coppers": "a cupped hand full of old copper coins, green with age",
    "Beady eye": "a pair of small binoculars with one lens cap hanging",
    "Spare change": "a handful of loose change found under a sofa cushion, fluff on it",
    # Petrol (fire)
    "Lit": "a struck match flaring in the dark, held in two fingers",
    "Drifter's can": "a red jerrycan with its cap off and a rag in the spout",
    "Spreads": "fire spreading along a spilled trail of petrol on concrete",
    "Scrapper's torch": "a propane blowtorch head on a hose, its flame roaring blue and orange",
    "On your hands": "a pair of hands with the fingers blistered and sooty, palms up",
    "Wildfire": "a line of burning gorse on a hillside at dusk, the flames leaning in the wind",
    "Fireproof": "a fire blanket in its red wall pouch with the tabs hanging",
    "Accelerant": "a plastic bottle of lighter fluid with its nozzle open",
    "Oil drum": "a rusted oil drum with flames coming out of its top",
    "Flashpoint": "a cigarette lighter's wheel struck, the spark caught mid-air",
    "Backdraught": "a doorway with smoke rolling along its top and a glow behind the door",
    # The cold (frost)
    "Chill": "a thermometer in a wooden case, the mercury down in the blue",
    "Poacher's snare": "a wire snare frozen stiff with hoar frost on the grass",
    "Frozen solid": "a padlock cased in clear ice on a frozen chain",
    "Paramedic's ice": "a stack of blue instant ice packs in a cool box",
    "Cold hands": "a pair of red raw bare hands cupped together, breath misting them",
    "Shatter": "a pane of ice shattering into shards from a single crack",
    "Thermals": "a folded set of grey thermal long johns and a wool hat",
    "Chilblains": "a pair of knitted fingerless mittens, the fingertips red",
    "Deep freeze": "a chest freezer's open lid with frost built up inside its rim",
    "Sleet": "sleet driving sideways past a streetlamp at night",
    "Brittle": "a frozen branch snapped clean in two, the ends white",
    # The Rat Man (poison)
    "Dosed": "a brown bottle with a dropper, a drop falling from its tip",
    "Poacher's bait": "a dead rat on its back beside a tin of grain",
    "Builds": "a stack of five small brown pill bottles, one on its side",
    "Paramedic's dose": "a glass ampoule snapped open beside a syringe",
    "Rat's share": "a torn sack of grain with rat droppings and a bite out of the corner",
    "Lingers": "a damp cellar's stone floor with a green stain spreading from a cracked drum",
    "Immune": "a used vaccine vial with a cotton wool ball and a plaster",
    "Strychnine": "a small blue poison bottle with a ridged side and a skull on its tag, no lettering",
    "Takes its time": "a sand timer with the sand half run through",
    "Tainted": "a tin of food with its lid bulged and a dark drip down the side",
    "Catching": "a rat's tail disappearing into a hole in a skirting board, a trail of crumbs",
    # Live (shock)
    "Current": "a bare copper busbar with a blue arc jumping across a gap",
    "Drifter's leads": "a set of jump leads coiled on a car bonnet, the clips crossed",
    "Daisy chain": "three extension-lead blocks plugged into one another in a row",
    "Scrapper's mains": "a fuse box with its cover off and a screwdriver wedged in it",
    "Earthed": "a copper earthing rod driven into mud with a green and yellow wire clamped to it",
    "Arc": "a long electric arc jumping between two steel rods, blue-white",
    "Rubber soles": "a pair of black rubber-soled work boots, the soles turned to show their tread",
    "Live rail": "a railway's third rail on its ceramic pot insulators, wet and gleaming",
    "Capacitor": "a big cylindrical capacitor with two bent legs, standing on a circuit board",
    "Stripped wire": "a length of wire with its insulation stripped back to bright copper strands",
    "Overload": "a plug socket with a blackened scorch mark and melted plastic round the pins",
    # Blades (bleed)
    "Opened up": "a kitchen knife with its edge nicked, a line of blood along the blade",
    "Doorman's glass": "a broken bottle neck held by its base, the edge sharp",
    "Won't stop": "a dripping tap with a red drop hanging from its spout",
    "Blood up": "a pair of boxing wraps on the hands, stained red at the knuckles",
    "Bleed out": "a pool of blood spreading across cracked lino from the frame's edge",
    "Scar tissue": "a forearm with a long healed scar across it, pale and ridged",
    "Honed": "a long blade being drawn across a whetstone, a line of water on the stone",
    "Serrated": "a bread knife's serrated edge in close-up, light along the teeth",
    "Whetstone": "a grey whetstone in its wooden box, a worn groove in its face",
    "Arterial": "a tourniquet strap pulled tight on an upper arm, the windlass turned",
    # Knuckles (physical)
    "Stagger": "a fist mid-punch, the knuckles wrapped, seen from the front",
    "Doorman's knuckles": "a set of brass knuckles on a bar top",
    "Bust them up": "a cricket bat with its edges splintered and a nail through the toe",
    "Heavy": "a lead-cored cosh in a leather sleeve on a wooden table",
    "Flattened": "a man's shape pressed into a wet lawn, the grass flattened, no one there",
    "Thick-skinned": "a thick rhino-hide-like leather jerkin with steel studs, hung flat",
    "Knuckleduster": "a steel knuckleduster held in a fist, seen from the front",
    "Shin pads": "a pair of scuffed plastic shin pads with their straps hanging",
    "Low blow": "a boot heel coming down on a bare instep, seen from the side",
    "Floored": "a dropped pint and a man's hand flat on a pub floor, seen from above",
}

# the Map's web: by atlas key, an object (Data.ATLAS's names)
MAP_NODES = {
    "picked_over": "a wooden drawer pulled out and tipped, its contents sorted into small piles",
    "second_look": "a hand lifting a loose floorboard, a tin box underneath",
    "local_knowledge": "a hand-drawn map on a torn paper bag with an X and no words",
    "lie_of_the_land": "a hilltop view across a town at dusk, drawn like a surveyor's sketch",
    "quiet_roads": "an empty country lane at dawn with the hedges wet and no tracks",
    "open_ground": "a wide empty car park with one shopping trolley in the middle",
    "short_cuts": "a hole cut in a chain-link fence, the wire bent back",
    "worn_in": "a path worn through long grass to a gap in a wall",
    "deeper_pockets": "a long coat's inside pocket turned out, lined with sewn-in extra pockets",
    "easy_pickings": "a dropped wallet open on wet pavement, notes showing",
    "after_dark": "a torch beam on a wall at night, the bulb's glow and nothing else",
    "every_penny": "a row of old tea tins on a shelf, each with its lid off",
    "paid_in_notes": "a wad of worn banknotes held by a bulldog clip, no printing readable",
    "their_own_kit": "a dead man's dropped rifle and webbing on the ground, seen from above",
    "marked_men": "a crossed-out face in a photograph pinned to a corkboard with a drawing pin",
    "lorrys_route": "a lorry's tyre track in mud leading away round a corner",
    "heads_up": "a photograph's torn corner pinned to a board under a red drawing pin",
    "two_of_everything": "a pair of identical steel cases side by side on a table",
    "full_strength": "a boxer's gumshield and a taped fist on a stool",
    "long_memory": "a notebook open on a bar, a name scored through with a pen",
    "head_start": "a bowling ball rolling down a wet lane, pins at the far end",
    "wages": "a brown wage packet with coins and a folded note sticking out",
    "bounties": "a tin money box with a slot in its lid and a coin half in",
    "heavy_crews": "a row of five black bomber jackets on hooks on a wall",
    "good_reception": "a radio's telescopic aerial fully extended with a wire clipped to its tip",
    "clear_air": "a radio's tuning dial with its needle between two marks, no numbers",
    "long_wave": "a tall radio mast with three guy wires against a grey sky",
    "whole_band": "a radio's glowing frequency dial window with the needle swept across it, no numbers",
    "tip_offs": "a folded note pushed under a door, a shadow of a shoe outside",
    "booster": "a bolt-on amplifier box with a coaxial cable screwed into each side",
    "strong_signal": "a signal strength meter's needle buried at the far end",
    "bent": "a bent coat-hanger aerial taped to a radio's back",
    "early_word": "an old brass telegraph key with a finger on it",
    "held_frequency": "a radio's dial with a strip of tape holding the needle in place",
    "relay": "a car battery wired to a relay box with a green lamp lit",
}

# the Pitch's picks and ranks, by building
PICKS = {
    "bench": {
        "steady_hands": "a pair of steady hands holding a tiny screwdriver to a gun's trigger group",
        "cheap_parts": "a cardboard box of loose gun springs and pins, a chalk price with no figures",
        "third_socket": "a steel drill bit boring a third hole into a gun's receiver, swarf curling",
        "two_locks": "two brass padlocks on one hasp, side by side",
        "gunsmith": "a gunsmith's bench with a receiver in a padded vice and files in a row",
        "strip_for_parts": "a gun stripped to its parts laid out in order on a cloth",
        "overbump": "a steel hammer striking a stamp into a receiver, sparks",
        "fine_tuning": "a tiny brass adjustment screw being turned with a jeweller's screwdriver",
        "masterwork": "a rifle receiver engraved with scrollwork, oiled and gleaming",
        "salvage_line": "a steel ingot stamped with a plain mark beside a pile of scrap",
        "rank": "a bench vice with a brass rank stripe painted on its jaw",
    },
    "stash": {
        "shelving": "a bay of steel shelving with crates on every shelf",
        "racks": "a wall rack of ammunition boxes and med tins in neat rows",
        "another_unit": "a second steel shipping container stacked on the first, its doors open",
        "bins": "a row of three dustbins with a broken gun sticking out of one",
        "strongroom": "a steel strongroom door with a wheel lock, ajar",
        "wall_of_fame": "a glass-fronted cabinet with a single gun on velvet and a brass plaque with no lettering",
        "lock_up": "a rusted blue shipping container with one door open onto darkness",
        "filing_cabinet": "a green steel filing cabinet with one drawer open full of papers",
        "dry_store": "a dry inside store with wooden shelves and labelled tins, the labels blank",
        "annex": "a breeze-block lean-to with a corrugated roof built onto a container",
        "rank": "a steel shelf bracket with a rank stripe painted on it",
    },
    "clinic": {
        "beds": "an army cot with a grey blanket folded at its foot",
        "shelf": "a wooden shelf with six brown medicine bottles in a row",
        "ward": "two camp beds with a screen between them and a drip stand",
        "stockroom": "a cupboard stacked with bandage boxes and tins of plasters",
        "surgery": "a steel tray of surgical tools under a lamp",
        "physio": "a pair of crutches and a resistance band on a wooden chair",
        "drip": "a saline drip bag on a stand, its line running down and out of frame",
        "field_kit": "a single rolled bandage tucked into a chest rig's pouch",
        "theatre": "an operating lamp's round head switched on over an empty table",
        "med_lab": "a rack of test tubes with coloured liquids and a bunsen burner",
        "rank": "a red cross's painted square on a tin box with a rank stripe",
    },
    "fence": {
        "stall": "a market stall's table with a few tools and tins laid out on a cloth",
        "haggling": "two hands over a counter, one holding out a note, the other holding up two fingers",
        "shopfront": "a lock-up's roller shutter half up with goods on a table inside",
        "orders": "a nail on a post with a stack of paper order slips spiked on it, no writing readable",
        "back_room": "a doorway with a bead curtain and a lit lamp beyond",
        "fixer": "a man's hand with rings on it holding out a business card with no printing",
        "gamblers_table": "a round baize table with cards face down and a stack of coins",
        "insurance_desk": "a leather ledger with a brass stamp and a red wax seal on it",
        "arms_dealer": "a steel case open on a table with a pistol in cut foam",
        "dealers_cut": "a banknote with one corner torn off, the corner beside it",
        "rank": "a brass shop bell with a rank stripe painted on its mount",
    },
    "radio": {
        "weather_set": "a barometer in a round brass case on a wall, no lettering",
        "night_set": "a radio's dial lamp glowing in a dark room",
        "forecast": "a hand-drawn weather map with cloud and rain symbols and no words",
        "dead_air": "a microphone on a stand with its switch off and a cloth over it",
        "scanner": "a handheld radio scanner with its aerial up and a row of lamps",
        "two_channels": "a radio with two tuning dials side by side",
        "lorry_watch": "a pair of binoculars on a windowsill looking out at a road",
        "long_range": "a tall radio mast on a hilltop with a red lamp on top",
        "jammer": "a black box with a stubby aerial and a single red lamp",
        "military_band": "an olive-green army field radio with its handset hooked on the side",
        "rank": "a radio's dial with a rank stripe painted beside it",
    },
    "generator": {
        "twelve_hours": "a wind-up alarm clock with both hands at twelve",
        "rig_wiring": "a chest rig with extra pouches sewn on, laid flat",
        "a_day": "a calendar's single page pinned to a wall, the day circled, no numbers",
        "floodlights": "a floodlight on a pole lighting a muddy yard at night",
        "battery": "a big lead-acid battery with its terminals wired up",
        "overtime": "a time clock's card with extra punches down its edge",
        "two_days": "two calendar pages torn off and laid side by side, no numbers",
        "arc_lamps": "an arc lamp's twin carbon rods with the arc burning between them",
        "grid": "a pylon's steel lattice against a grey sky",
        "charger": "a battery charger's dial and clips on a workbench, its lamp green",
        "rank": "a petrol generator's pull cord handle with a rank stripe on its case",
    },
    "lookout": {
        "spotter": "a man's silhouette on a roof edge with binoculars, seen from below",
        "glasses": "a pair of army binoculars on a folded map",
        "lookout_post": "a wooden watchtower on four legs with a ladder up",
        "range_cards": "a hand-drawn range card with arcs and no numbers, on a sandbag",
        "hold_fire": "a raised open hand in a glove, palm out",
        "tripwires": "a thin wire stretched across a doorway at ankle height, a tin can on its end",
        "early_warning": "a string of tin cans on a wire across a gap in a fence",
        "watch_rota": "a clipboard with a rota of empty boxes and ticks, no words",
        "crows_nest": "a crow on a lamp post against a grey sky",
        "flares": "a red signal flare burning in a hand against a dark sky",
        "rank": "a watchtower's rail with a rank stripe painted on it",
    },
    "kennel": {
        "a_dog": "a scruffy brown mongrel sitting, looking up, ears forward",
        "good_nose": "a dog's nose and muzzle sniffing at a tin, in close-up",
        "guard_dog": "a big black dog standing at a gate with its hackles up",
        "pedigree": "a lean grey lurcher standing in profile",
        "fetch": "a dog carrying a leather satchel in its mouth",
        "second_dog": "two dogs side by side at a gate, one brown, one black",
        "tracker": "a hound with its nose to a muddy track",
        "ratter": "a terrier with a rat in its jaws",
        "pack": "four puppies in a cardboard box lined with a blanket",
        "champion": "a dog's red rosette pinned to a kennel door",
        "rank": "a kennel's wooden door with a rank stripe painted on it",
    },
}

RING = {
    "damage": "a steel pipe wrench with its jaws open, seen from the side",
    "hp": "a heavy wool army greatcoat buttoned up, on a hook",
    "resists": "a gas mask with its filter canister, on a hook",
    "find": "a magnifying glass over a scattering of coins and buttons",
    "tins": "a stack of tins of food with their labels gone",
}

# the regions' emblems: slug, the subject, its tint
REGIONS = [
    ("petrol", "a red jerrycan with a flame curling from its spout", "a hot orange glow"),
    ("the_cold", "a six-pointed frost crystal over a cracked windowpane", "pale ice blues"),
    ("the_rat_man", "a rat sitting up on a tin, a bottle with a skull tag behind it", "sickly greens"),
    ("live", "a lightning bolt striking a pylon's crossarm", "electric blue-white"),
    ("blades", "two crossed kitchen knives over a drop of blood", "a deep red"),
    ("knuckles", "a clenched fist in a steel knuckleduster", "iron greys"),
    ("the_sites", "a hand-drawn map of a town with pins in it", "paper creams and browns"),
    ("the_crews", "a row of three hooded figures seen from behind", "dark slate greys"),
    ("the_codes", "a radio's glowing dial window with its needle", "a warm amber glow"),
    ("the_ring", "a ring of thirty small brass studs round a dark centre", "dull brass"),
    ("the_pitch", "a tarpaulin lean-to with a fire drum glowing under it", "warm firelight on canvas"),
    # the class lanes (optional: the same shape, so the ten read as one family with the rest)
    ("stalking", "a scoped rifle laid across a flat cap", "heather browns and greens"),
    ("snares", "a brass wire snare on a peg in grass", "muddy greens"),
    ("muscle", "a sawn-off shotgun across a pair of knuckles", "black leather and steel"),
    ("the_door", "a heavy door with a brass strike plate, ajar on darkness", "dark wood and brass"),
    ("triage", "a paper triage tag on a string over a pair of shears", "green and white"),
    ("shifts", "an ambulance's blue lamp on a dark roof", "blue and white"),
    ("stripping", "a nail gun and a hacksaw crossed on an oily rag", "oil black and rust"),
    ("fencing", "a set of brass pan scales with a gun part on one pan", "brass and dull gold"),
    ("moving_on", "a thumb out at a roadside with a holdall on the verge", "wet tarmac greys"),
    ("luck", "three dice showing sixes on a beer mat", "faded red and cream"),
]

# the canvases' backdrops: room, size (the canvas drawn x2: the API's widest is 744), the surface, its tint
BACKDROPS = [
    ("training", (744, 276), "a wide slate blackboard with the ghosts of old chalk lines wiped off it, a faint "
     "chalk dust haze, a hairline crack across one corner", "a chalky grey"),
    ("dial", (744, 216), "a radio operator's dark baize table top under a desk lamp's dim pool, a faint ring from a "
     "mug, worn to the weave at the edges", "a warm amber tinge at the centre"),
    ("pitch", (744, 270), "muddy trampled ground seen straight down from above, puddles reflecting a grey sky, a few "
     "duckboards and a tarpaulin's edge", "cold wet browns"),
]

# the two figures: slug, the portrait's look, the figure's look
PEOPLE = [
    ("scrapper", 0,
     "the Scrapper, a lean wiry man in his thirties who builds guns out of anything: a shaved head with a welder's "
     "burn on the scalp, a thick stubbled jaw, a filthy orange hi-vis vest over a torn grey hoodie, a nail gun's "
     "strap across his chest, grease to the elbows, a quick sharp look",
     "the Scrapper: a lean wiry man in his thirties, shaved head, thick stubble; a filthy orange hi-vis vest over a "
     "torn grey hoodie, oil-black cargo trousers with a hacksaw hung from the belt, steel-toed boots"),
    ("poacher", 1,
     "the Poacher, a tall gaunt man in his forties from the hills: a camouflage army-surplus smock with the hood "
     "down, a dark knitted hat, a long grey-streaked beard, a dead rabbit's hind legs over one shoulder, pale "
     "patient eyes, nothing like a gamekeeper's tweed",
     "the Poacher: a tall gaunt man in his forties with a long grey-streaked beard and a dark knitted hat; a "
     "camouflage army-surplus smock with the hood down over a dark jumper, baggy green trousers tucked into "
     "muddy wellington boots"),
]

# the fight's cover walls (the fight kit's prompts, the eleven not yet run; the Parade's and Ransacked Streets' landed)
WALLS = [
    ("the_allotments", "a raised vegetable bed built of old railway sleepers, weeds and a broken cane over the top"),
    ("the_garden_centre", "a pallet stacked with split compost bags, soil spilling over the edge"),
    ("top_farm", "a low dry-stone wall with a gate post, nettles at its foot"),
    ("the_retail_park", "a long concrete planter with dead shrubs and a run of trolleys jammed against it"),
    ("the_pleasure_park", "the side of an overturned dodgem car, its pole bent"),
    ("shopping_centre", "a row of upturned mall benches and a broken planter edge"),
    ("the_bank", "the front of a wooden counter with a cracked glass screen above it, pens on chains hanging"),
    ("the_services", "a run of steel crash barrier, dented, with a traffic cone tipped against it"),
    ("the_hospital", "an overturned hospital trolley and its thin mattress on its side"),
    ("the_barracks", "a low wall of sandbags, some split, a strip of hessian flapping"),
    ("the_parade", "a low wall of grimy red brick with a broken concrete coping, moss in the joints, a weed growing from a crack"),
]
WALL_W, WALL_H = 744, 173

# the test: a dozen nodes across the kinds, two emblems, one backdrop, one face
TEST_NODES = ["Snare and wait", "Iron", "The second past", "Jab", "Breaker's yard", "Lucky penny", "Spreads", "Arc",
              "map:lie_of_the_land", "map:relay", "pick:kennel/a_dog", "ring:damage"]
TEST_OTHER = ["region:petrol", "region:the_codes", "backdrop:dial", "portrait:scrapper"]


def slug(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


def node_job(out_slug, obj, where, seed):
    return {"out": "art/nodes/%s.png" % out_slug, "endpoint": "generate-image-v2", "width": 64, "height": 64,
            "no_background": True, "single": True, "seed": seed, "style_options": STYLE,
            "style_image": "res://art/ui/dps.png", "reference_images": ["res://art/ui/dps.png", "res://art/ui/hp.png"],
            "description": ICON % obj, "_where": where}


def emblem_job(key, what, tint, seed):
    return {"out": "art/web/region_%s.png" % key, "endpoint": "generate-image-v2", "width": 96, "height": 96,
            "no_background": True, "single": True, "seed": seed, "style_options": STYLE,
            "style_image": "res://art/ui/dps.png", "reference_images": ["res://art/ui/dps.png", "res://art/ui/hp.png"],
            "description": EMBLEM % (what, tint), "_where": "the region's emblem beside its label: %s" % key}


def backdrop_job(room, size, what, tint, seed):
    return {"out": "art/web/backdrop_%s.png" % room, "endpoint": "generate-image-v2", "width": size[0], "height": size[1],
            "no_background": False, "single": True, "seed": seed, "style_options": STYLE,
            "style_image": "res://art/places/the_yard.png", "description": BACKDROP % (what, tint),
            "_where": "the %s canvas's backdrop, drawn x2 under the web" % room}


def people_jobs(slug_v, i, portrait, figure):
    face = {"out": "art/people_new/%s.png" % slug_v, "endpoint": "generate-image-v2", "width": 128, "height": 128,
            "no_background": False, "single": True, "seed": 98300 + i, "style_options": STYLE,
            "style_image": "res://art/people/fence.png", "description": PORTRAIT % portrait,
            "_where": "the %s's face, a new look (parked from the playtest, 21 Oct)" % slug_v.capitalize()}
    body = {"out": "art/body_new/body_%s.png" % slug_v, "endpoint": "generate-image-v2", "width": 208, "height": 488,
            "no_background": True, "single": True, "seed": 98310 + i, "style_options": STYLE,
            "style_image": "res://art/people_new/%s.png" % slug_v,
            "reference_images": ["res://art/people_new/%s.png" % slug_v, "res://art/body_%s.png" % slug_v],
            "description": FIGURE % figure, "_where": "the %s's figure, the new face's (run after it)" % slug_v.capitalize()}
    return [face, body]


def wall_job(key, what, seed):
    return {"out": "art/fight_new/%s_cover.png" % key, "endpoint": "generate-image-v2", "width": WALL_W, "height": WALL_H,
            "no_background": True, "single": True, "seed": seed, "style_options": STYLE,
            "style_image": "res://art/fight/%s_cover.png" % key, "description": WALL % what,
            "_where": "the wall at the frame's width, one piece: %s" % key}


def main():
    jobs = []
    keyed = {}
    seed = 98000
    # Training's nodes: one picture a name
    for name, obj in NODES.items():
        j = node_job(slug(name), obj, "Training's web: %s" % name, seed)
        seed += 1
        jobs.append(j)
        keyed[name] = j
    for key, obj in MAP_NODES.items():
        j = node_job("map_" + key, obj, "the Map's web: %s" % key, seed)
        seed += 1
        jobs.append(j)
        keyed["map:" + key] = j
    for b, picks in PICKS.items():
        for pid, obj in picks.items():
            j = node_job("pick_%s_%s" % (b, pid), obj, "the Pitch's web: %s / %s" % (b, pid), seed)
            seed += 1
            jobs.append(j)
            keyed["pick:%s/%s" % (b, pid)] = j
    for key, obj in RING.items():
        j = node_job("ring_" + key, obj, "the ring: %s" % key, seed)
        seed += 1
        jobs.append(j)
        keyed["ring:" + key] = j
    for i, (key, what, tint) in enumerate(REGIONS):
        j = emblem_job(key, what, tint, 98500 + i)
        jobs.append(j)
        keyed["region:" + key] = j
    for i, (room, size, what, tint) in enumerate(BACKDROPS):
        j = backdrop_job(room, size, what, tint, 98600 + i)
        jobs.append(j)
        keyed["backdrop:" + room] = j
    for slug_v, i, portrait, figure in PEOPLE:
        face, body = people_jobs(slug_v, i, portrait, figure)
        jobs += [face, body]
        keyed["portrait:" + slug_v] = face
    for i, (key, what) in enumerate(WALLS):
        jobs.append(wall_job(key, what, 98700 + i))
    test = [keyed[k] for k in TEST_NODES + TEST_OTHER]
    readme = __doc__.strip()
    counts = "nodes %d (Training %d, Map %d, Pitch %d, ring %d), emblems %d, backdrops %d, people %d, walls %d" % (
        len(NODES) + len(MAP_NODES) + sum(len(p) for p in PICKS.values()) + len(RING), len(NODES), len(MAP_NODES),
        sum(len(p) for p in PICKS.values()), len(RING), len(REGIONS), len(BACKDROPS), 2 * len(PEOPLE), len(WALLS))
    with open(os.path.join(ROOT, "tools", "pixellab_web_art_manifest.json"), "w") as f:
        json.dump({"_readme": readme + "\n\n" + counts, "jobs": jobs}, f, indent=1)
    with open(os.path.join(ROOT, "tools", "pixellab_web_art_test_manifest.json"), "w") as f:
        json.dump({"_readme": "The test: " + ", ".join(TEST_NODES + TEST_OTHER) + ". Judge these before the rest runs.", "jobs": test}, f, indent=1)
    print("%d jobs (%s); the test %d" % (len(jobs), counts, len(test)))


if __name__ == "__main__":
    main()
