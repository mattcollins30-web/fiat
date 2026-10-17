"""The fight's kit art (17 Oct, Matt: "lets get the manifest for: per weapon fight arms, wall regens, missing art for the
fight stat boxes"). Writes two manifests:

  tools/pixellab_fight_kit_test_manifest.json  - the test pieces first (Matt's rule: the slice reads with test art
                                                 before credits go on the set): one site's plate and wall at the new
                                                 frame's size, one pair of hands for each kind, the four tile icons
  tools/pixellab_fight_kit_manifest.json       - the whole set: hands for every gun base (82), every site's plate and
                                                 wall at the frame's drawn size (24), the four tile icons

What each is:
  - Hands, one picture a base (status item 4: "equipping a bat and seeing a hammer just reads wrong"). The run draws the
    hands by kind today (RunView._hands_kind, seven pictures); these go to art/fight/hands/<base>.png and the code will
    look a base up first, the kind's picture its fallback. Each is styled on the base's own item art, so the gun in the
    hands is the gun on the card, and framed on the kind's current hands, so every picture sits in the corner alike.
    Drawn at 280x210: the hands' 256x192 at HANDS_SCALE 0.8 x the frame's VIEW_SCALE 812/588 is 283x212 on screen.
  - The walls and their plates (status item 1: the bigger frame scales them up and the joins show). Regenerated at the
    largest the API takes at their shape, 744x320 and 744x173 (drawn at 950x409 and 950x221, the API's cap about
    512x512's worth), the frame scaling the rest. To art/fight_new/,
    beside the live ones in art/fight/, which stay until the new ones are judged.
  - The run's six tiles' missing icons (status item 16): Their fire, Kills, Armour, Rounds - Matt's painted dps and hp
    are the other two. 64x64, drawn at 36 px; to art/ui_new/ (never over art/ui), styled on the dps and hp icons.

Run: python3 tools/make_fight_kit_manifest.py, then the test first:
  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_fight_kit_test_manifest.json
and, once the test pieces read, the set:
  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_fight_kit_manifest.json
(++ --dry-run to list; one that came out wrong: ++ --only <name> ++ --force). The set skips what the test made."""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TAIL = ("Realistic painted pixel art, soft overcast light, muted cool northern palette, worn and lived-in, "
        "post-collapse Britain on a grey day; no black outlines, not anime, not a cartoon, not glossy; no text, no logos.")
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}
VIEW_SCALE = 812.0 / 588.0
HANDS_W, HANDS_H = 280, 210
# the frame draws a plate at 950x409 (688x296 x VIEW_SCALE), past the API's cap (about 512x512's worth: its widest is
# 688x384); so the largest at the plate's shape with a margin, the frame scaling the rest (x1.28, not x1.38) (17 Oct)
PLATE_W, PLATE_H = 744, 320
WALL_W, WALL_H = 744, 173


def slug(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


def bases():
    """Every gun base, primary and secondary, from data.gd: [slot, name, type, ammo, bleed]."""
    s = open(os.path.join(ROOT, "scripts", "sim", "data.gd"), encoding="utf-8").read()
    i = s.index("const BASES := {")
    out = []
    for slot in ("Primary", "Secondary"):
        j = s.index('"%s": [' % slot, i)
        k = s.index("\n\t],", j)
        for n, t, rest in re.findall(r'\{"name": "([^"]+)", "type": "([^"]+)"([^\n]*)', s[j:k]):
            am = re.search(r'"ammo": "([^"]*)"', rest)
            bl = re.search(r'"conv_bleed_pct": ([0-9.]+)', rest)
            out.append([slot, n, t, am.group(1) if am else "", float(bl.group(1)) if bl else 0.0])
    return out


def kind(t, ammo, bleed):
    """RunView._hands_kind's answer for a base: the picture it falls back to."""
    if t == "melee":
        return "blade" if bleed >= 25.0 else "melee"
    if t == "improvised" and ammo not in ("", "improvised", "none"):
        t = ammo
    return t if t in ("pistol", "shotgun", "rifle", "smg", "improvised") else "improvised"


HOLD = {  # by kind: how it's held in the corner
    "pistol": "held out forward and slightly up in both hands",
    "shotgun": "shouldered, the barrel pointing forward up the frame, one hand at the fore-end and one at the grip",
    "rifle": "shouldered, the barrel pointing forward up the frame, one hand at the grip and one under the fore-end",
    "smg": "held out forward in both hands, one at the grip and one on the fore-grip",
    "improvised": "held forward in both hands like a gun",
    "melee": "raised, ready to swing, gripped near the end of the handle, the other hand held out for balance",
    "blade": "raised, ready to swing, the edge catching the light, the other hand held out for balance",
}
HOLD_OF = {  # a base whose shape wants its own
    "Hand-me-down nail gun": "held forward like a pistol in one hand, its hose trailing back past the wrist",
    "Nail gun": "held forward like a pistol in one hand, its hose trailing back past the wrist",
    "Bolt gun": "held forward like a pistol in one hand, a battery pack on its grip",
    "Crossbow": "shouldered, the bow's limbs wide across the frame, the bolt pointing forward up the frame",
    "Workshop gauss": "held forward in both hands, coils of copper wire round its barrel, a car battery taped under it",
    "Flare pistol": "held out forward in one hand, its wide orange barrel pointing up the frame",
    "Air pistol": "held out forward in one hand, the slim barrel pointing up the frame",
    "Sawn-off": "held forward low in both hands, the short double barrels pointing up the frame",
    "Sledgehammer": "raised in both hands over the right shoulder, ready to swing down",
    "Door ram": "held forward in both hands by its two handles, its flat steel face aimed up the frame",
    "Knuckle duster": "worn on a clenched right fist raised forward, the left fist up beside it like a boxer's guard",
    "Cosh": "raised in the right hand, ready to swing, its leather strap round the wrist, the other hand held out for balance",
    "Bayonet on a stick": "held forward in both hands like a spear, the bayonet's point up the frame",
    "Knife": "held low and forward in the right hand, the blade up, the left hand out for balance",
    "Fire axe": "raised in both hands over the right shoulder, the red head catching the light",
    "Rescue axe": "raised in both hands over the right shoulder, ready to swing",
    "Pipe wrench": "raised in the right hand, ready to swing, the other hand held out for balance",
    "Breaker bar": "raised in both hands over the right shoulder, ready to swing",
    "Demolition bar": "raised in both hands over the right shoulder, ready to swing",
    "Anti-materiel rifle": "shouldered, its long heavy barrel pointing forward up the frame on a bipod, one hand at the grip",
    "Belt-fed SMG": "held forward in both hands, a belt of rounds hanging from its side",
}


def hands_job(slot, name, t, ammo, bleed, seed):
    k = kind(t, ammo, bleed)
    held = HOLD_OF.get(name, HOLD[k])
    return {"out": "art/fight/hands/%s.png" % slug(name), "width": HANDS_W, "height": HANDS_H, "no_background": True,
            "seed": seed, "endpoint": "generate-image-v2", "single": True, "style_options": STYLE,
            "style_image": "res://art/items/%s.png" % slug(name),
            "reference_images": ["res://art/fight/hands_%s.png" % k],
            "description": ("First-person view of the player's own two hands in fingerless wool gloves holding a %s, %s, coming in "
                            "from the bottom right corner of the frame, as in a light-gun arcade game; the sleeves of a worn work "
                            "jacket at the wrists. Exactly the weapon in the style image, its shape and colours. Only the hands and "
                            "what they hold, coming in from the bottom right edge. %s") % (name.lower(), held, TAIL),
            "_where": "your hands: %s (%s; falls back to hands_%s)" % (name, slot.lower(), k)}


# the sites, as the fight manifest's (make_fight_manifest.py): scene words and the wall across the frame's foot
POV = "A first-person view at crouching eye level, as if from behind cover in a light-gun arcade game, "
EMPTY = "Nobody in the scene, empty and waiting."
LAYOUT = ("Composed for three figures to stand in later: clear open ground in the middle distance just right of centre, "
          "a dark doorway or gap on the left side well down the scene, and room in the right foreground. "
          "The ground runs across the lower third; the horizon sits a third of the way down. One continuous scene edge to "
          "edge: no repeated sections, no seams. The bottom fifth of the scene is plain open ground running to the frame's edge, "
          "nothing standing in the foreground: no walls, rubble or cover there, it is drawn over later.")
SITES = [
    ("the_allotments", "across overgrown allotments at the edge of a town: sheds of corrugated iron and old doors, runner-bean canes, water butts, a polytunnel with its plastic torn, a rusting wheelbarrow, a shed with its door hanging open",
     "a raised vegetable bed built of old railway sleepers, weeds and a broken cane over the top"),
    ("the_garden_centre", "down an aisle of a looted garden centre: a glasshouse roof with panes out, toppled shelving of pots, dead plants on trolleys, a café counter, the exit doors at the end standing open",
     "a pallet stacked with split compost bags, soil spilling over the edge"),
    ("top_farm", "across a farmyard: a stone barn with its big doors open, a rusting tractor, round bales in black plastic, a muddy yard with puddles, a farmhouse back door ajar",
     "a low dry-stone wall with a gate post, nettles at its foot"),
    ("ransacked_streets", "down a ransacked terraced street: front doors kicked in, a sofa in the road, a car on its roof, washing still on a line between houses, a ginnel between two terraces",
     "a low front-garden wall of pebbledash with a toppled wheelie bin against it"),
    ("the_parade", "along a parade of shops on an estate: shutters down and sprayed, a bookie's and a chippy and a launderette, a bus shelter with its glass out, a car burnt out at the kerb, an alley between two shops",
     "a low wall of grimy red brick with a broken concrete coping, moss in the joints, a weed growing from a crack"),
    ("the_retail_park", "across a retail park car park: big box stores with their shutters half up, abandoned cars at angles, a trolley shelter, lamp posts, a carpet warehouse's loading bay open on the left",
     "a long concrete planter with dead shrubs and a run of trolleys jammed against it"),
    ("the_pleasure_park", "into a dead seaside pleasure park: a stalled waltzer, a ghost train's dark entrance, a burger kiosk with its hatch up, bunting in tatters, a helter-skelter in the haze",
     "the side of an overturned dodgem car, its pole bent"),
    ("shopping_centre", "along a shopping centre's upper mall in failing daylight from the roof: shop shutters, a dead escalator, a fountain dried up, a department store's dark entrance, litter everywhere",
     "a row of upturned mall benches and a broken planter edge"),
    ("the_bank", "across a high-street bank's banking hall: teller windows with their glass starred, a queue rope fallen, leaflets on the floor, a door marked private open onto the dark, the vault corridor beyond",
     "the front of a wooden counter with a cracked glass screen above it, pens on chains hanging"),
    ("the_services", "across a motorway services forecourt: petrol pumps, a shop with its glass smashed, a jack-knifed lorry, the canopy lights out, the slip road in haze",
     "a run of steel crash barrier, dented, with a traffic cone tipped against it"),
    ("the_hospital", "down a hospital corridor: trolleys left at angles, curtains pulled round bays, a nurses' station, fire doors propped open, signs to wards, strip lights out but for one",
     "an overturned hospital trolley and its thin mattress on its side"),
    ("the_barracks", "across an army barracks' parade ground: brick accommodation blocks, a guardroom with its barrier up, a Land Rover with flat tyres, a flagpole with no flag, a hangar door open on the left",
     "a low wall of sandbags, some split, a strip of hessian flapping"),
]


def plate_job(key, scene, seed):
    return {"out": "art/fight_new/%s_plate.png" % key, "width": PLATE_W, "height": PLATE_H, "no_background": False, "seed": seed,
            "endpoint": "generate-image-v2", "single": True, "style_options": STYLE,
            "style_image": "res://art/fight/%s_plate.png" % key,
            "description": POV + "looking " + scene + ". " + EMPTY + " " + LAYOUT + " " + TAIL,
            "_where": "the plate at the frame's drawn size: %s (the live art/fight/%s_plate.png its style)" % (key, key)}


def wall_job(key, cover, seed):
    return {"out": "art/fight_new/%s_cover.png" % key, "width": WALL_W, "height": WALL_H, "no_background": True, "seed": seed,
            "endpoint": "generate-image-v2", "single": True, "style_options": STYLE,
            "style_image": "res://art/fight/%s_cover.png" % key,
            "description": ("Seen very close from behind, running unbroken across the whole width of the frame at the bottom: " + cover +
                            ", as the cover a player crouches behind in a light-gun arcade game. One continuous piece edge to edge, no "
                            "repeated sections, no seams. Only the cover, nothing above or behind it; its top edge uneven, filling the "
                            "lower two thirds of the image. No packaging, signs or anything with lettering on it. " + TAIL),
            "_where": "the wall at the frame's drawn size: %s" % key}


ICON_TAIL = (" One object centred and filling the frame, a single bold silhouette that still reads at a quarter of this size, "
             "soft directional overcast daylight, natural material rendering with painterly shading; no black outlines, not "
             "anime, not a cartoon, not a glossy video-game icon. Muted cool northern palette, worn, nothing new. Nothing else "
             "in the frame, no hands, no person, no text, no logos, a plain dark neutral background.")
ICONS = [  # name, the tile, the object
    ("their_fire", "Their fire", "A realistic painted pixel-art still-life of a dented square of steel plate with a bullet strike punched into it, the lead smeared and the paint scorched round the hole, seen front on."),
    ("kills", "Kills", "A realistic painted pixel-art still-life of a scrap of grey slate with five chalk tally marks on it, four upright and one struck across, seen front on."),
    ("armour", "Armour", "A realistic painted pixel-art still-life of a dented steel chest plate from a stab vest, scuffed matt black with frayed webbing straps, seen front on."),
    ("rounds", "Rounds", "A realistic painted pixel-art still-life of a small open cardboard box of red shotgun shells standing in rows, the flap torn, seen from above at a slight angle."),
]


def icon_job(name, tile, prompt, seed):
    return {"out": "art/ui_new/%s.png" % name, "width": 64, "height": 64, "no_background": True, "seed": seed,
            "endpoint": "generate-image-v2", "single": True, "style_options": STYLE,
            "style_image": "res://art/ui/dps.png", "reference_images": ["res://art/ui/dps.png", "res://art/ui/hp.png"],
            "description": prompt + ICON_TAIL,
            "_where": "the run's tile: %s (36 px beside the figure, with Matt's dps and hp)" % tile}


def main():
    all_bases = bases()
    jobs = []
    seed = 97000
    test_hands = {"Spiked bat", "Pump shotgun", "Army bullpup", "Police carbine", "Crossbow", "Big revolver", "Knife", "Garage-built rifle"}
    tests = []
    for b in all_bases:
        j = hands_job(*b, seed=seed)
        seed += 1
        jobs.append(j)
        if b[1] in test_hands:
            tests.append(j)
    for key, scene, cover in SITES:
        p = plate_job(key, scene, seed)
        w = wall_job(key, cover, seed + 1)
        seed += 2
        jobs += [p, w]
        if key == "the_parade":
            tests += [p, w]
    for name, tile, prompt in ICONS:
        j = icon_job(name, tile, prompt, seed)
        seed += 1
        jobs.append(j)
        tests.append(j)
    run = "godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/%s   (++ --dry-run to list; one that came out wrong: ++ --only <name> ++ --force)"
    common = [
        "Hands: art/fight/hands/<base>.png, 280x210, styled on the base's item art and framed on the kind's current hands; the code looks a base up first, the kind's picture its fallback.",
        "Walls and plates: art/fight_new/<site>_cover.png 744x173 and _plate.png 744x320, the largest the API takes at their shape (the bigger frame draws them at 950 wide, scaling x1.28); the live ones in art/fight/ stay until these are judged. Run the test's Parade pair first: it shows the size is taken.",
        "Icons: art/ui_new/their_fire, kills, armour, rounds - 64x64, drawn at 36 px on the run's tiles beside Matt's dps and hp. Never written over art/ui.",
        "Regenerate with python3 tools/make_fight_kit_manifest.py.",
    ]
    test = {"_readme": ["FIAT FIGHT KIT, THE TEST (17 Oct, Matt): one pair of hands for each kind (a bat, a pump shotgun, a bullpup, a carbine, a crossbow, a big revolver, a knife, a garage rifle), the Parade's plate and wall at the new size, the four tile icons. Judge these in the frame before the set is run.",
                        "Run: " + run % "pixellab_fight_kit_test_manifest.json"] + common, "jobs": tests}
    full = {"_readme": ["FIAT FIGHT KIT, THE SET (17 Oct, Matt): hands for every gun base (%d), every site's plate and wall at the frame's drawn size (%d), the four tile icons. After the test reads; the test's pieces are skipped as made." % (len(all_bases), 2 * len(SITES)),
                        "Run: " + run % "pixellab_fight_kit_manifest.json"] + common, "jobs": jobs}
    for name, m in (("pixellab_fight_kit_test_manifest.json", test), ("pixellab_fight_kit_manifest.json", full)):
        with open(os.path.join(ROOT, "tools", name), "w", encoding="utf-8") as f:
            json.dump(m, f, indent=1, ensure_ascii=False)
    missing = [b[1] for b in all_bases if not os.path.exists(os.path.join(ROOT, "art", "items", slug(b[1]) + ".png"))]
    print("test %d jobs, set %d jobs (%d hands, %d plates and walls, %d icons)" % (len(tests), len(jobs), len(all_bases), 2 * len(SITES), len(ICONS)))
    if missing:
        print("no item art to style on: " + ", ".join(missing))


if __name__ == "__main__":
    main()
