"""The County's art (26 Oct, Matt: "write the County manifest now"; docs/design/the_issue.md §4, §10). Written, not
run: the credits wait for Matt's go after he's played the County on its test art (the host sites' plates).

Writes two manifests:

  tools/pixellab_county_test_manifest.json  - the Truck Stop's pair and the Bailiff (portrait, standing): judge them in
                                              the frame before the set
  tools/pixellab_county_manifest.json       - the lot (the test's four skipped as made)

What, by data.gd COUNTY / COUNTY_ZONES:
  - a plate (744x320) and a wall (744x256) for each of the twelve places: art/fight_county/<place>_plate.png and
    _cover.png, styled on the host site's live pair (as make_boss_backdrops_manifest.py styles a pinnacle's); a head's
    place is his den
  - a map card (496x296) for each place: art/places/<place>.png, styled on the host's card - the County board's
    pictures (county.gd reads it first, else the host's)
  - the four heads: a portrait (128x128, art/people/<head>.png) and three fight figures (128x192,
    art/fight/head_<head>_stand/_fire/_down.png), as the order's heads were made (pixellab_outstanding_manifest.json)
  - the six pieces of issued kit (art/items/issued_<piece>.png), as the uniques' pictures

Code still to do once the art is in (Matt's go first): RunView reads art/fight_county/<place> for a County run's
plate and wall (today the host site's). The heads' figures and the map cards are read as soon as they exist.

Seeds: SEED0 on, a block clear of every other manifest's (checked: it stops on a clash).

Run: python3 tools/make_county_art_manifest.py (then python3 tools/art_lint.py), then the test:
  tools\\art.bat county_test
and, once it reads, the set:
  tools\\art.bat county"""
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_fight_kit_manifest as kit  # noqa: E402  (the plates' words, the style, the tail, the sites)

ROOT = kit.ROOT
PLATE_W, PLATE_H = kit.PLATE_W, kit.PLATE_H     # 744x320
WALL_W, WALL_H = 744, 256
CARD_W, CARD_H = 496, 296                       # the order's map cards (pixellab_outstanding_manifest.json)
SEED0 = 106000      # clear of the others (fight kit 97xxx, web 98xxx, walls 101xxx, generator 102xxx, skills 103xxx, chase 104xxx, boss backdrops 105xxx)
OWN = ("pixellab_county_manifest.json", "pixellab_county_test_manifest.json")
SITE_KEYS = [k for k, _s, _c in kit.SITES]
TEST = ("truck_stop", "The Bailiff")
# 26 Oct: the Truck Stop's wall rerolled (its face only the lower 58%); a fixed seed gives near-identical rerolls, so
# it moves - by 3000, as 107xxx holds the boss walls' rerolls
WALL_REROLL = {"The Truck Stop": 10000, "The Treasury": 3000}    # 26 Oct: the Truck Stop rerolled four times (two flat fronts keyed out, the barricade inset with a frame); the Treasury came inset with a frame

# A place: its den (the plate's view), its wall (the cover) and its card (a wide view at dusk). The words keep the
# lessons: nobody in the plate, the wall a foreground cover, nothing printed on anything.
PLACES = {
    "toll_plaza": (
        "across a motorway toll plaza: a row of booths under a long concrete canopy, the barriers down, cones and a "
        "jack-knifed lorry trailer in plain faded paint with no lettering across two lanes, the tarmac wet, a lane of sodium lamps going off into the haze",
        "a row of orange plastic traffic barriers filled with water, linked end to end, scuffed and dirty",
        "a motorway toll plaza at dusk, a long concrete canopy over a row of booths, the barriers down, a single "
        "lorry stopped at them, sodium lamps along the empty carriageway"),
    "distribution": (
        "down the inside of a vast distribution warehouse: high steel racking of shrink-wrapped pallets in rows, a "
        "forklift parked across an aisle, roller doors along the left wall with one half up onto a grey loading yard, "
        "strip lights hanging, plain cardboard boxes with no labels",
        "a stack of shrink-wrapped pallets of plain cardboard boxes, the film torn on one side",
        "a vast grey distribution warehouse beside a motorway at dusk, a row of loading bays, trailers backed up to "
        "them, floodlights on tall poles"),
    "truck_stop": (
        "into a motorway truck stop's drivers' cafe: formica tables and fixed stools, a counter with a tea urn and a "
        "glass cake stand, a bailiff's clipboard with a blank sheet and a box of confiscated keys on the counter, the "
        "window onto a lorry park full of parked cabs in plain faded paint with no lettering on them, a door open on "
        "the left onto the dark",
        "a barricade of cafe tables tipped onto their sides in a row, their scuffed undersides and steel legs towards the viewer, plastic chairs piled and jammed between and against them, the barricade running straight off the left and right edges of the image with no frame or border round it",     # third try 26 Oct (Matt): two flat counter fronts were keyed out with the background     # rerolled 26 Oct: the urn and mugs stood above a 58% face
        "a truck stop at dusk, a low cafe with lit windows beside a lorry park of parked cabs and trailers in plain "
        "faded paint with no lettering on them, a fuel canopy, rain on the tarmac"),
    "container_port": (
        "down a corridor between stacks of shipping containers at a port, four high in faded reds, blues and greens, "
        "a straddle carrier parked at the end, a gantry crane over the quay beyond, puddles on the concrete, the "
        "containers plain with no writing on them",
        "a line of concrete port barriers with a coil of mooring rope over them, rust streaks down the faces",
        "a container port at dusk, ship-to-shore gantry cranes over a quay, stacks of plain coloured containers, a "
        "ship tied up, sodium lights reflected in the water"),
    "ferry_terminal": (
        "across a ferry terminal's departure hall: rows of joined plastic seats, a closed cafe kiosk with its shutter "
        "down, a glass wall onto the linkspan and a ferry's open bow door beyond, luggage trolleys abandoned, a long "
        "check-in desk on the left",
        "a row of joined plastic airport-style seats knocked onto their backs, a holdall caught under them",
        "a ferry terminal at dusk, a low glass building beside the water, a ferry tied up with its bow door open onto "
        "a lit linkspan, gulls over the car lanes"),
    "customs_shed": (
        "into a customs examination shed: long steel benches with opened cases and boxes laid out on them, a big "
        "X-ray tunnel for parcels, a counting table stacked with seized goods and ledgers, a caged store on the left, "
        "strip lights, a roller door up onto the quay",
        "the front of a long steel examination bench, a cardboard box and an open suitcase on its edge",
        "a customs shed at dusk on a dock, a long corrugated building with a lit roller door, a lorry inside being "
        "unloaded, a security gate and a guard hut"),
    "golf_club": (
        "across a golf club's terrace and the last green beyond: patio tables with parasols folded, a plain putting "
        "flag with no number on it leaning, golf buggies parked in a row, the clubhouse's glass doors on the left, a sand bunker and the "
        "fairway going away into mist, the grass cut short and neat",
        "a row of parked golf buggies side by side, their white roofs dirty, a golf bag in the back of one",
        "a golf club at dusk, a long low clubhouse with lit windows and a terrace, a rolling fairway and a plain flag with "
        "no number on the green, a high fence along the road"),
    "gated_close": (
        "down a private gated close of big new houses: block-paved drive, matching double garages, neat hedges and "
        "lollipop trees, a black wrought-iron gate standing open on the left, a security camera on a post, a parked "
        "4x4 with its door open and no number plate, everything tidy and quiet",
        "a low wall of reconstituted stone with a hedge along its top and a stone ball on the gate pier",
        "a gated close at dusk, six large new houses round a turning circle, black iron gates and a gatehouse with a "
        "light on, cameras on posts"),
    "manor": (
        "into a country manor's long hall: dark wood panelling, oil paintings with their faces blank and dark, a "
        "huge stone fireplace, a long dining table piled with ledgers, deeds and boxed papers, every page blank, a grand staircase on "
        "the left going up into the dark, a chandelier unlit",
        "the side of a long heavy oak dining table tipped onto its edge, its carved legs towards the viewer",
        "a country manor at dusk, a big stone house at the end of a long drive between trees, a few lit windows, a "
        "line of parked cars on the gravel"),
    "counting_house": (
        "down a counting house's long room: rows of clerks' desks with adding machines and stacks of banknotes "
        "bound in paper bands, ledgers open on blank pages, green-shaded lamps, a tall window of small panes, a barred cashier's "
        "cage on the left, the notes plain grey-green with no faces or numbers",
        "a row of heavy clerks' desks pushed together, ledgers and bound bundles of plain grey-green notes on top",
        "a counting house at dusk, a heavy stone building with tall barred windows lit from inside, guards at a door, "
        "a van backed up to it"),
    "bullion_vault": (
        "into a bullion vault: a round steel vault door standing open on the left, steel cages of empty shelving "
        "behind mesh, trolleys for gold bars standing empty, a single strip light, a concrete floor painted with "
        "plain lines, everything grey and steel and nothing of worth on it",
        "a row of empty steel bullion trolleys pushed together, their flat beds scuffed and bare",
        "a bullion vault's building at dusk, a windowless concrete block behind a double fence and razor wire, a "
        "heavy steel gate, floodlights and a guard tower"),
    "treasury": (
        "across the Treasury's great hall: marble floor and columns, a long counter with brass grilles, a raised "
        "desk on a dais at the back under a tall arched window, blank printing plates and stacks of new notes on a table, "
        "a pair of great doors open on the left, the notes plain grey-green with no faces or numbers",
        "a long grey marble counter with brass grilles along its top, its front running straight off the left and right edges of the image with no frame or border round it, a stack of plain grey-green note bundles on it",
        "the Treasury at dusk, a grand pillared stone building on a square, a flag on a pole, lit high windows, "
        "barricades and armoured vans across its steps"),
}

# The heads: a portrait line and their figure (what they wear, what they hold).
HEADS = {
    "The Bailiff": (
        "a broad bailiff in his fifties, shaven head, a plain hi-vis tabard with no lettering or badge over a stab "
        "vest, a body camera on his chest, a clipboard of blank papers and a ring of other people's keys, a face that "
        "has heard every excuse",
        "a broad shaven-headed bailiff in his fifties in a plain hi-vis tabard with no lettering or badge over a stab "
        "vest, a body camera on his chest, "
        "a ring of keys on his belt, holding a pump shotgun across his body"),
    "The Auditor": (
        "a thin precise woman in her forties, auditor, reading glasses on a chain, a grey suit and a lanyard with a "
        "blank card, a pencil behind her ear, a face that has already found the mistake",
        "a thin precise woman in her forties in a grey suit and reading glasses on a chain, a lanyard, a ledger under "
        "one arm, holding a compact machine pistol"),
    "The Collector": (
        "a heavy man in his sixties, debt collector, a camel overcoat over a cardigan, gold rings, a soft voice and "
        "hard eyes, a small plain notebook in his top pocket",
        "a heavy man in his sixties in a camel overcoat over a cardigan, gold rings, a small plain notebook in his top pocket, "
        "holding a revolver low at his side"),
    "The Treasurer": (
        "a tall cold woman in her fifties, the Treasurer, an immaculate black suit, a chain of office, silver hair "
        "cut short, a face that decides what money is worth",
        "a tall woman in her fifties in an immaculate black suit with a chain of office, short silver hair, a plain "
        "riot shield with no lettering on one arm and a short rifle held in the other"),
}

# Issued kit's pictures: stamped and numbered, the Issuer's.
ISSUED_ART = {
    "Issued rifle": (192, 64, "ref_01", "a single long heavy anti-materiel rifle, seen exactly side-on with the muzzle "
                     "pointing left, laid level and filling the frame left to right, olive drab, a big muzzle brake, a "
                     "bipod folded, a small stamped brass plate on the stock with no readable marks"),
    "Issued sidearm": (128, 64, "ref_01", "a single heavy black service pistol, seen exactly side-on with the muzzle "
                       "pointing left, a small stamped brass plate on the grip with no readable marks"),
    "Issued cap": (128, 128, "ref_03", "a single olive command helmet with a visor folded up, a small stamped brass "
                   "plate riveted to the front with no readable marks"),
    "Issued plate": (192, 256, "ref_03", "a single heavy olive armour suit hung flat as if on a hook, seen from the "
                     "front, thick plates in the chest and shoulders, a stamped brass plate stitched on with no "
                     "readable marks"),
    "Issued webbing": (192, 192, "ref_03", "a single olive command chest rig laid flat, pouches in rows, a stamped "
                       "brass plate stitched to the front with no readable marks"),
    "Issued seal": (64, 64, "ref_04", "a single heavy gold seal stamp with a short turned handle, its face plain and "
                    "smooth with no design, a small object filling the frame, seen from above at a slight angle"),
}
ITEM_TAIL = ("One object centred and filling the frame, soft directional overcast daylight, natural material rendering "
             "with fine detail and painterly shading; no black outlines, no flat cel shading, no lettering.")
FIGURE_TAIL = ("One person alone, full body head to feet, facing the viewer, centred, filling the frame top to bottom, "
               "plain dark neutral background. Realistic painted pixel art, soft overcast light, muted palette.")
CARD_TAIL = ("Muted blue-grey and slate palette with sparse warm orange lights, low cloud. Quiet; no people, no text, "
             "no readable signs. The subject across the middle of the frame (it is cropped to a card's top from either "
             "side); darker at the bottom edge.")


def slug(name):
    return kit.slug(name)


def county():
    """data.gd COUNTY: [key, place, site index, who or ""]."""
    s = open(os.path.join(ROOT, "scripts", "sim", "data.gd"), encoding="utf-8").read()
    i = s.index("const COUNTY := [")
    body = s[i:s.index("\n]", i)]
    out = []
    for entry in body.split('{"key": ')[1:]:
        m = re.match(r'"([^"]+)", "place": "([^"]+)", "cz": \d+, "site": (\d+)', entry)
        w = re.search(r'"who": "([^"]+)"', entry)
        out.append((m.group(1), m.group(2), int(m.group(3)), w.group(1) if w else ""))
    return out


def plate_job(place, site, scene, seed):
    return {"out": "art/fight_county/%s_plate.png" % slug(place), "width": PLATE_W, "height": PLATE_H, "no_background": False,
            "seed": seed, "endpoint": "generate-image-v2", "single": True, "style_options": kit.STYLE,
            "style_image": "res://art/fight_new/%s_plate.png" % site,
            "description": kit.POV + "looking " + scene + ". " + kit.EMPTY + " " + kit.LAYOUT + " " + kit.TAIL,
            "_where": "%s's fight, the plate (styled on its host's, art/fight_new/%s_plate.png)" % (place, site)}


def wall_job(place, site, cover, seed):
    return {"out": "art/fight_county/%s_cover.png" % slug(place), "width": WALL_W, "height": WALL_H, "no_background": True,
            "seed": seed + WALL_REROLL.get(place, 0), "endpoint": "generate-image-v2", "single": True,
            "style_options": kit.STYLE, "style_image": "res://art/fight_walls/%s_cover.png" % site,
            "description": ("Seen very close from behind, running unbroken across the whole width of the frame: " + cover +
                            ", as the cover a player crouches behind in a light-gun arcade game. One single continuous piece "
                            "edge to edge, no repeated sections, no seams, no tiles. It touches the left, right and bottom "
                            "edges of the image: no margin or border on any side. The cover is tall and fills the lower 85% "
                            "of the image as one solid face, running all the way down to the bottom edge of the image with no "
                            "gap, no ground and nothing below it, so a player crouched low behind it sees only the cover; only "
                            "its uneven top edge sits above that, nothing above or behind it. Everything on it plain and "
                            "unprinted, no lettering, numbers or pictures anywhere. " + kit.TAIL),
            "_where": "%s's fight, the wall (styled on art/fight_walls/%s_cover.png)" % (place, site)}


def card_job(place, site, view, seed):
    return {"out": "art/places/%s.png" % slug(place), "endpoint": "generate-image-v2", "width": CARD_W, "height": CARD_H,
            "no_background": False, "single": True, "seed": seed, "style_options": kit.STYLE,
            "style_image": "res://art/places/%s.png" % site,
            "description": "Pixel art, a wide view of " + view + ". " + CARD_TAIL,
            "_where": "the County board's card for %s (county.gd; today the host's, art/places/%s.png)" % (place, site)}


# A pose that came back wrong (26 Oct): the Treasurer's fire lost her rifle, the flash from an empty hand.
FIRE_WORDS = {"The Treasurer": ", the short rifle raised to her shoulder in her free hand and aimed straight at the viewer, "
              "the shield still on her other arm, a bright muzzle flash at the rifle's barrel."}


def head_jobs(who, seed):
    face, body = HEADS[who]
    s = slug(who)
    portrait = {"out": "art/people/%s.png" % s, "endpoint": "generate-image-v2", "width": 128, "height": 128,
                "no_background": False, "single": True, "seed": seed, "style_options": kit.STYLE,
                "style_image": "res://art/people/fence.png",
                "description": ("A realistic painted pixel-art portrait, head and shoulders, of " + face + ". Looking just past "
                                "the viewer. Post-collapse Britain, overcast light. One person centred, filling the frame, no "
                                "text, no border, plain dark background."),
                "_where": "%s's face: the County board, the fight's head" % who}
    ref = "res://art/people/%s.png" % s
    stand = {"out": "art/fight/head_%s_stand.png" % s, "endpoint": "generate-image-v2", "width": 128, "height": 192,
             "no_background": True, "single": True, "seed": seed + 1, "style_options": kit.STYLE, "style_image": ref,
             "reference_images": [ref], "description": body + ", standing still. " + FIGURE_TAIL, "_where": "%s: standing" % s}
    after = [ref, "res://art/fight/head_%s_stand.png" % s]
    fire = dict(stand, out="art/fight/head_%s_fire.png" % s, reference_images=list(after), _where="%s: firing at you" % s,
                description="The same person as the reference image: " + body + FIRE_WORDS.get(who, ", aiming straight at the viewer, a bright "
                "muzzle flash.") + " " + FIGURE_TAIL)
    down = dict(stand, out="art/fight/head_%s_down.png" % s, reference_images=list(after), _where="%s: beaten, going down" % s,
                description="The same person as the reference image: " + body + ", hit and falling backwards, arms flung "
                "out, what they held dropping. " + FIGURE_TAIL)
    return [portrait, stand, fire, down]


def item_job(name, seed):
    w, h, ref, what = ISSUED_ART[name]
    return {"out": "art/items/%s.png" % slug(name), "endpoint": "generate-image-v2", "width": w, "height": h,
            "no_background": True, "seed": seed, "single": True, "style_options": kit.STYLE,
            "style_image": "res://art/reference/items/%s.png" % ref,
            "description": "A realistic painted pixel-art still-life of " + what + ". " + ITEM_TAIL,
            "_where": "%s's picture: the Issuer's counter, the stash, the kit" % name}


def used_seeds():
    seen = {}
    for path in glob.glob(os.path.join(ROOT, "tools", "pixellab_*manifest.json")):
        if os.path.basename(path) in OWN:
            continue
        try:
            jobs = json.load(open(path, encoding="utf-8")).get("jobs", [])
        except (ValueError, OSError):
            continue
        for j in jobs:
            if isinstance(j, dict) and j.get("seed") is not None:
                seen.setdefault(int(j["seed"]), []).append(j.get("out", "?"))
    return seen


def main():
    places = county()
    if sorted(p[0] for p in places) != sorted(PLACES):
        sys.exit("data.gd COUNTY is %s; this maker has words for %s" % ([p[0] for p in places], sorted(PLACES)))
    heads = [p[3] for p in places if p[3]]
    if sorted(heads) != sorted(HEADS):
        sys.exit("data.gd COUNTY's heads are %s; this maker has %s" % (heads, sorted(HEADS)))
    jobs, tests = [], []
    seed = SEED0
    for key, place, site_i, who in places:
        site = SITE_KEYS[site_i]
        scene, cover, view = PLACES[key]
        pair = [plate_job(place, site, scene, seed), wall_job(place, site, cover, seed + 1)]
        jobs += pair + [card_job(place, site, view, seed + 2)]
        seed += 3
        if key == TEST[0]:
            tests += pair
    for who in heads:
        hj = head_jobs(who, seed)
        seed += 2                       # the three figures share the standing one's seed, as the order's did
        jobs += hj
        if who == TEST[1]:
            tests += hj[:2]
    for name in ISSUED_ART:
        jobs.append(item_job(name, seed))
        seed += 1
    used = used_seeds()
    clash = {j["seed"]: used[j["seed"]] for j in jobs if j["seed"] in used}
    if clash:
        sys.exit("seeds already used elsewhere: %s - move SEED0" % clash)
    for j in jobs:
        ref = j.get("style_image", "")
        if ref and not ref.endswith(tuple("%s.png" % slug(w) for w in HEADS)) and not os.path.exists(os.path.join(ROOT, ref.replace("res://", ""))):
            print("warning: no %s on disk (%s)" % (ref, j["out"]))
    run = "tools\\art.bat %s   (the dry run first, then it asks; one that came out wrong: ++ --only <name> ++ --force)"
    common = [
        "Fight pairs to art/fight_county/<place>_plate.png 744x320 and _cover.png 744x256, styled on the host site's pair; map cards to art/places/<place>.png 496x296; the heads' portraits to art/people/, their figures to art/fight/head_<head>_stand/_fire/_down.png; issued kit to art/items/issued_<piece>.png. Nothing live is overwritten.",
        "Code once it's in (Matt's go): RunView reads art/fight_county/<place> on a County run. The cards, the heads and the items are read as they land.",
        "Regenerate with python3 tools/make_county_art_manifest.py; check with python3 tools/art_lint.py.",
    ]
    test = {"_readme": ["FIAT, THE COUNTY'S ART: THE TEST (26 Oct): the Truck Stop's pair and the Bailiff (portrait, standing). Judge them in the frame before the set.",
                        "Run: " + run % "county_test"] + common, "jobs": tests}
    rest = [j for j in jobs if j not in tests]
    full = {"_readme": ["FIAT, THE COUNTY'S ART: THE SET (26 Oct): %d jobs - twelve places (plate, wall, card), four heads (portrait, three figures), six pieces of issued kit. The test's %d are skipped as made." % (len(rest), len(tests)),
                        "Run: " + run % "county"] + common, "jobs": rest}
    for name, m in ((OWN[1], test), (OWN[0], full)):
        with open(os.path.join(ROOT, "tools", name), "w", encoding="utf-8") as f:
            json.dump(m, f, indent=1, ensure_ascii=False)
    print("county art: test %d jobs, set %d jobs (%d in all), seeds %d-%d" % (len(tests), len(rest), len(jobs), SEED0, seed - 1))


if __name__ == "__main__":
    main()
