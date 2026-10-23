"""The web's small nodes (23 Oct, Matt's 0.7.1 playtest: "why are there no art in most of the nodes?" - "art batch for
item 2"). The first manifest (make_web_art_manifest.py) drew the notables, keystones and capstones and left the small
tier as dots; this one draws the small tier - every named small node of Training's class and element regions and the
Pitch's, and the eight fillers - in the same still-life style, to the same folder, so web_view's picture lookup
(art/nodes/<slug>.png) finds them with no new wiring.

  python3 tools/make_web_small_manifest.py
    -> tools/pixellab_web_small_manifest.json

  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_web_small_manifest.json

The two re-rolls owed from the first batch (Still air, Arc) are the first manifest's jobs: ++ --only still_air ++ --force.
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from make_web_art_manifest import ICON, STYLE, slug  # noqa: E402  (the same tails and the same slug)

# The small nodes: a name, an object. The same rules as the first manifest's: one worn British object, cut out, no
# people, no text. Where a region's name is also its first node ("The Pitch", "Muscle"), the object is the region's.
SMALL = {
    # The Pitch
    "The Pitch": "a scuffed white football with its panels gone grey, on a tuft of grass",
    "Long walks": "a pair of grey walking socks rolled into a ball",
    "Knowing the streets": "a folded paper street map, creased soft, the panels blank",
    "Zeroing": "a rifle's rear iron sight, the aperture ring and its two screws",
    "Circuits": "a stopwatch on a cord, the face blank",
    "Keen eyes": "a pair of small black folding binoculars, the lenses catching light",
    "Stashing": "a biscuit tin with its lid half off and a rag inside",
    # Stalking / Snares (the Poacher)
    "Stalking": "a single muddy boot print pressed into soft earth, cut out as a clod",
    "Breathing": "a cloth face scarf, grey, loosely knotted",
    "Patience": "a camp stool of canvas and wood, folded",
    "Wind reading": "a tuft of dry grass stems bending one way",
    "Long shot": "a single long brass rifle round standing on its base",
    "Lying up": "a rolled green groundsheet tied with twine",
    "Snares": "a loop of brass snare wire with its wooden peg",
    "Hedgerows": "a sprig of hawthorn with a few red berries",
    "Soft ground": "a cut square of wet turf with a boot heel's dent",
    "Night eyes": "a small rubber torch with a red filter over the lens, off",
    "Snare lines": "three brass snares bundled together with string",
    "Knowing the land": "a hand-drawn field map on brown paper, the lines plain and no words",
    # Muscle / The door (the Doorman)
    "Muscle": "a single rusted iron dumbbell",
    "Gym": "a worn brown leather punchbag on a short chain",
    "Broad shoulders": "a black bomber jacket's padded shoulder, the seam showing",
    "Weights": "two black iron weight plates leaning together",
    "Thick skin": "a square of thick black leather, scuffed, one edge turned",
    "Big frame": "a wide black leather belt with a plain steel buckle, coiled",
    "Spoils": "a handful of loose coins and a watch on a bar towel",
    "The door": "a steel pub door's push plate with a worn brass handle",
    "Heads down": "a black knitted beanie hat, folded flat",
    "Eye contact": "a pair of round black sunglasses, one arm folded",
    "Bouncing": "a brass door chain and its slide, unhooked",
    "Keep back": "a red velvet rope's brass hook end, the rope frayed",
    # Triage / Shifts (the Paramedic)
    "Triage": "a set of coloured paper triage tags on a steel ring, no writing",
    "Fast hands": "a pair of blue nitrile gloves laid flat",
    "Kit bag": "a small green canvas medical pouch with a plain white patch",
    "Good veins": "a blue elastic tourniquet strap with its plastic clip",
    "Stock take": "a stack of three sealed gauze packets, plain",
    "Pressure": "a rolled crepe bandage with a steel safety pin",
    "Pockets checked": "a hi-vis jacket's chest pocket, the flap open",
    "Shifts": "a plain clock-in card and its steel punch clip, the card blank",
    "Rest easy": "a thin grey hospital blanket folded square",
    "Mates' rates": "a mug of tea with a biscuit on the saucer",
    "Long shift": "a half-drunk cardboard cup of coffee with a plastic lid",
    "Cold tea": "a mug of tea gone cold, a skin on it",
    "Discount": "a paper price ticket with a line through where the number was, blank",
    # Stripping / Fencing (the Scrapper)
    "Stripping": "a pair of yellow-handled wire strippers",
    "Quick fingers": "a small flat-head screwdriver with a worn red handle",
    "Tools": "an adjustable spanner, rusted at the jaw",
    "Spare parts": "a jam jar of loose screws and washers",
    "Fast strip": "a cordless drill's bare battery pack",
    "Magpie eye": "a jeweller's loupe on a cord",
    "Fencing": "a brown paper bag of mixed coins, the top rolled",
    "Contacts": "a small black address book with a rubber band round it, no writing",
    "Weighing it up": "a small brass pocket balance with its weights",
    "Known face": "a dog-eared playing card, the face down, plain back",
    "Fair price": "a hand-written price label on string, blank",
    "Lucky find": "a gold ring in the dirt, half buried",
    # Moving on / Luck (the Drifter)
    "Moving on": "a pair of worn trainers tied together by the laces",
    "Road legs": "a walking stick cut from a hedge, the bark worn where the hand goes",
    "Head start": "a bus timetable torn from a shelter, the columns blank",
    "Keep moving": "a bedroll strapped with a belt, slung",
    "Never still": "a cheap plastic wristwatch with a cracked face, blank",
    "Wiry": "a coil of thin steel wire",
    "Luck": "a horseshoe, rusted, points up",
    "Found tins": "two tins of beans with the labels gone, dented",
    "Charmed": "a rabbit's foot keyring on a brass chain",
    "Touch wood": "a short piece of sawn oak, the grain showing",
    "Pockets": "the turned-out pocket of a pair of jeans, the lining grey",
    "Four-leaf": "a four-leaf clover pressed flat",
    # Petrol (fire)
    "Petrol": "a red steel jerrycan with a brass cap, scuffed",
    "Rags": "a bundle of oily grey rags",
    "Siphoned": "a length of clear rubber tubing, coiled, a dark fluid in it",
    "Wick": "a glass milk bottle with a rag stuffed in its neck",
    "Fumes": "a petrol can's open cap with a heat shimmer above it",
    # The cold (frost)
    "The cold": "a bag of road grit salt, split at one corner",
    "Frost": "a frosted windowpane corner with ice ferns on the glass",
    "A hard winter": "a shovel blade with a crust of ice on it",
    "Numb": "a pair of fingerless wool gloves, grey",
    "Wind chill": "a wet grey woollen scarf hanging stiff",
    # The Rat Man (poison)
    "The Rat Man": "a small grey rat trap, the spring set",
    "Bait": "a paper twist of poisoned grain, blue, a few grains spilt",
    "Council issue": "a council-grey plastic bait box with its lid shut",
    "Cumulative": "a brown glass bottle with a plain label, the cork out",
    "Slow acting": "a dropper bottle of dark fluid, the dropper beside it",
    # Live (shock)
    "Live": "a bare copper wire's stripped end, the strands splayed",
    "Charge": "a square lantern battery with two spring terminals",
    "Off the mains": "a wall socket with the face plate off and the wires showing",
    "Amps": "a car battery's clamp on a cable, red",
    "Volts": "a small analogue voltmeter, the needle swung, the face blank",
    # Blades (bleed)
    "Blades": "a Stanley knife with the blade out",
    "An edge": "a grey whetstone with a dark wet patch",
    "Sharpened": "a kitchen knife ground thin, the edge bright",
    "Deep": "a short-bladed knife with a dark stain near the hilt",
    "Nicked": "a razor blade, the old double-edged kind",
    "Butcher's": "a meat cleaver on a scored wooden block",
    # Knuckles (physical)
    "Knuckles": "a brass knuckleduster, dull and worn",
    "Wraps": "a roll of white boxing hand wrap, the end loose",
    "Half a brick": "half a red house brick, broken edge towards you",
    "Thick skull": "a black cycle helmet with a crack in the shell",
    "Weight behind it": "a short length of lead pipe",
    "Sovereign rings": "three gold sovereign rings on a bar towel",
    # the fillers (every region's between-nodes; drawn only when close)
    "Hardy": "a tin of plain biscuits, the lid dented",
    "Keen": "a small pocket knife, open",
    "Brisk": "a plain brass whistle on a lanyard",
    "Mending": "a reel of thread with a needle through it",
    "Tough": "a square of canvas patched with a darker square",
    "Lucky": "a single playing die, worn",
    "Nimble": "a bent hair grip and a padlock, the lock open",
    "Proofed": "a tin of wax boot polish, the lid off",
}


# The second wave (23 Oct, Matt: "why aren't the other nodes in this batch? send the manifest"): the first list was read
# off data.gd's sources and missed the lanes' extra nodes and the elements' resist fillers; this one is read off what
# the three canvases draw (a probe of every laid-out node). Training's 17 more small nodes and 5 resist fillers:
SMALL_MORE = {
    "A can of it": "a small red tin of lighter fluid with a pointed spout",
    "Bare hands": "a pair of scarred bare knuckles' worth of white tape, torn off and balled",
    "De-icer": "a blue aerosol can of car de-icer, the label plain",
    "Dry fire": "an empty rifle magazine lying open, the follower showing",
    "Gift of the gab": "a cheap gold-coloured lighter and a packet of mints on a pub table",
    "Heavy hands": "a pair of black leather work gloves, the knuckles worn shiny",
    "Jammy": "a jar of strawberry jam with the lid off and a spoon in it",
    "Light feet": "a pair of thin black plimsolls, the soles worn smooth",
    "Night shift": "a hi-vis lanyard with a blank plastic ID card on it",
    "Nose for parts": "a cardboard box of salvaged circuit boards and loose valves",
    "Quick hands": "a set of lock picks on a leather roll, half unrolled",
    "Sparks": "a pair of jump leads, the copper jaws touching",
    "Stance": "a pair of heavy work boots planted side by side, the laces tied",
    "Stanley knife": "a yellow-handled utility knife with the blade snapped short",
    "Steady pulse": "a cheap digital blood-pressure cuff, the screen blank",
    "Still hands": "a rifle's bolt laid on an oil cloth",
    "Under the sink": "a dusty plastic bottle of bleach with a child-proof cap",
    # the elements' resist fillers (data.gd RES_NAMES)
    "Singed": "a scorched oven glove",
    "Wrapped up": "a thick knitted grey scarf wound in a coil",
    "Hardened": "a dented tin of milk powder, the label gone",
    "Insulated": "a pair of orange rubber electrician's gloves",
    "Clotted": "a roll of brown elastic bandage with a metal clip",
}
# The Dial's fillers (the Map's web, map_web.gd): ten, drawn as map_f_<slug> so none borrows a Training node's picture
# ("Light fingers" is also a Training notable).
MAP_FILLERS = {
    "Quick feet": "a pair of trainers with the laces tied together, hung over a wire",
    "Back ways": "a gap in a wooden fence, one plank pushed aside",
    "Light fingers": "a jemmy bar and a pair of thin gloves",
    "Loose change": "a small heap of copper coins on a pavement",
    "Lessons": "a dog-eared exercise book, closed, no writing on the cover",
    "Pocket money": "a folded banknote held with a bulldog clip, the note plain",
    "Spare valves": "three glass radio valves lying in a tray",
    "Gain": "a radio's volume knob, chrome and worn",
    "Short dial": "an old rotary phone dial, the numbers worn off",
    "Hearsay": "a bakelite radio's speaker grille, the cloth torn",
}


def node_job(out_slug, obj, seed):
    return {"out": "art/nodes/%s.png" % out_slug, "endpoint": "generate-image-v2", "width": 64, "height": 64,
            "no_background": True, "single": True, "seed": seed, "style_options": STYLE,
            "style_image": "res://art/ui/dps.png", "reference_images": ["res://art/ui/dps.png", "res://art/ui/hp.png"],
            "description": ICON % obj}


def main():
    jobs = []
    seen = set()
    for i, (name, obj) in enumerate(SMALL.items()):
        s = slug(name)
        if s in seen:
            continue
        seen.add(s)
        jobs.append(node_job(s, obj, 98600 + i))
    readme = ("The web's small nodes (23 Oct, Matt's 0.7.1 playtest): %d still-lifes to art/nodes/, 64 px, the first "
              "manifest's style. The fillers are the last eight." % len(jobs))
    out = os.path.join(ROOT, "tools", "pixellab_web_small_manifest.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump({"_readme": readme, "jobs": jobs}, f, indent=1)
    print("%d jobs -> %s" % (len(jobs), out))
    more = []
    for i, (name, obj) in enumerate(SMALL_MORE.items()):
        more.append(node_job(slug(name), obj, 98800 + i))
    for i, (name, obj) in enumerate(MAP_FILLERS.items()):
        more.append(node_job("map_f_" + slug(name), obj, 98900 + i))
    out2 = os.path.join(ROOT, "tools", "pixellab_web_small2_manifest.json")
    with open(out2, "w", encoding="utf-8") as f:
        json.dump({"_readme": "The second wave: Training's %d small nodes and resist fillers the first list missed, and the "
                   "Dial's %d fillers (map_f_<slug>)." % (len(SMALL_MORE), len(MAP_FILLERS)), "jobs": more}, f, indent=1)
    print("%d jobs -> %s" % (len(more), out2))


if __name__ == "__main__":
    main()
