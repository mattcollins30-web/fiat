"""The bosses' own fight backdrops (25 Oct): a plate and a wall for each boss, so a head's fight or a true pinnacle's
reads as his own den, not the site's ordinary ground. The four heads (data.gd BOSSES) and the three true pinnacles
(data.gd PINNACLES). Writes two manifests:

  tools/pixellab_boss_backdrops_test_manifest.json  - the Manager's pair, to judge in the frame first (Matt's rule: the
                                                      slice reads with test art before credits go on the set)
  tools/pixellab_boss_backdrops_manifest.json       - every boss's pair (14; the test's Manager skipped as made)

To art/fight_boss/<boss>_plate.png (744x320, the kit's plate size) and <boss>_cover.png (744x256, the tall walls'
size), a folder of their own: nothing live is overwritten, no --force needed. Each boss's names hold no site's name,
so ++ --only the_manager picks his pair alone.

The style: a head's pair on his own site's live pair (art/fight_new/<site>_plate.png, art/fight_walls/<site>_cover.png);
a pinnacle's on the pair of the site he's fought on (data.gd PINNACLES `site`: the Grid on the Services, the Archive on
the Bank, the Mint on the Barracks), with his map card (art/places/<place>.png) as a reference image for the place.
The words are the site's place but the boss's own den; the kit's POV, EMPTY, LAYOUT and TAIL as every plate's, and the
walls' wording as make_fight_walls_manifest.py's (the lessons: nobody in the plate, the wall is a foreground cover the
player ducks behind, its top edge reads as cover, nothing printed on anything).

Seeds: SEED0 on, a block clear of every other manifest's (checked when this runs: it stops on a clash).

Run: python3 tools/make_boss_backdrops_manifest.py (then python3 tools/art_lint.py), then the test:
  tools\\art.bat boss_backdrops_test
and, once the Manager's reads, the set:
  tools\\art.bat boss_backdrops
(art.bat does the dry run first and asks before it spends; one that came out wrong: tools\\art.bat boss_backdrops
--only <boss>_plate --force)."""
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_fight_kit_manifest as kit  # noqa: E402  (the plates' words, the style, the tail, the sites)

ROOT = kit.ROOT
PLATE_W, PLATE_H = kit.PLATE_W, kit.PLATE_H     # 744x320
WALL_W, WALL_H = 744, 256                       # make_fight_walls_manifest.py's tall walls
SEED0 = 105000      # clear of every other manifest's seeds (fight kit 97xxx, web 98xxx, walls 101xxx, generator 102xxx, skills 103xxx, chase 104xxx)
OUT_DIR = "art/fight_boss"
REROLL = {"The Quartermaster": 2000, "The Registrar": 2000}    # 25 Oct: covers came back inset twice (margin at the sides and bottom)
OWN = ("pixellab_boss_backdrops_manifest.json", "pixellab_boss_backdrops_test_manifest.json")
SITE_KEYS = [k for k, _s, _c in kit.SITES]      # by data.gd's site index (the kit's SITES are in the same order)

# The heads: the boss, his site (the zone's last, where he's fought), his den, his wall.
HEADS = [
    ("The Gamekeeper", "top_farm",
     "into the gamekeeper's larder at the back of a stone farm barn, its big doors open onto a muddy yard: a rail of "
     "dead pheasants hung by their necks from a beam, rusted gin traps and wire snares on nails along the wall, a game "
     "cart, galvanised feed bins, straw bales, a chest freezer with its lid up, a torn pheasant pen in the yard beyond",
     "a row of rough wooden game crates with a pheasant feed hopper on its side against them, straw spilling out"),
    ("The Carpet Man", "the_retail_park",
     "down the inside of a carpet warehouse on a retail park: rolls of carpet stacked high on steel racking, offcuts "
     "heaped on the concrete floor, a forklift with a carpet pole, a sample stand of fanned plain swatches, a roller "
     "shutter half up on the grey car park, a dark lock-up door on the left",
     "a stack of rolled carpets lying on their sides, bound with parcel tape, a roll of grey underlay over the top"),
    ("The Manager", "the_bank",
     "into the branch manager's office behind the bank's banking hall: a heavy wooden desk and a leather chair, filing "
     "cabinets with their drawers pulled out, the round steel vault door standing open on the left onto the dark, "
     "safe-deposit boxes along the wall with their little doors hanging, loose banknotes and paper over the carpet, "
     "the notes plain and blank with no faces or numbers on them, a frosted glass partition, the blinds half down",
     "the front of a heavy wooden manager's desk, its panels scuffed, a brass desk lamp and a wire tray of paper on its edge"),
    ("The Quartermaster", "the_barracks",
     "into the quartermaster's stores at an army barracks: a long brick storeroom, steel shelving of folded kit and "
     "boxed rations in olive drab, a mesh armoury cage with its gate open on the left onto the dark, empty rifle racks, "
     "plain unmarked ammunition boxes stacked on pallets, an issue counter with a hatch, one strip light hanging",
     "a stack of olive steel ammunition boxes on a pallet, no markings on them, a coil of webbing over the top, "
     "running off the frame, cut off by its left, right and bottom edges"),
]
# The true pinnacles: their den, their wall; who, where and the site they're fought on come from data.gd PINNACLES.
PINNACLE_WORDS = {
    "grid": ("across a substation yard behind a high wire fence: grey transformers on concrete plinths, insulators "
             "and busbars overhead, big wooden cable drums stacked on their sides, a brick switch house with its steel "
             "door open on the left, pylons going away into the haze, gravel underfoot, one work lamp on a pole",
             "a pair of big wooden cable drums on their sides, thick black cable wound round them"),
    "archive": ("down the stacks of a records archive: tall steel shelving packed with bound ledgers and box files, "
                "their spines blank, a rolling library ladder, a reading table with a green-shaded lamp, papers drifted "
                "across the floor, a card-index cabinet, a dark aisle opening on the left, high windows grey with dust",
                "a heaped barricade of bound ledgers and box files on a toppled book trolley, their spines blank, "
                "running off the frame, cut off by its left, right and bottom edges"),
    "mint": ("across the floor of a mint: heavy printing presses in a row, sheets of uncut banknotes on drying racks, "
             "bundles of notes stacked on pallets and wrapped in film, a guillotine, ink drums, a caged dispatch door "
             "open on the left onto the dark, factory roof lights grey overhead; the notes plain grey-green, no faces "
             "or numbers on them",
             "a pallet of banknote bundles wrapped in clear film, the notes plain grey-green with no faces or numbers"),
}
MAP_CARD = "The same place as the reference image, its buildings, materials and colours, from the viewpoint described."


def slug(name):
    return kit.slug(name)


def pinnacles():
    """data.gd PINNACLES: [key, place, who, site index]."""
    s = open(os.path.join(ROOT, "scripts", "sim", "data.gd"), encoding="utf-8").read()
    i = s.index("const PINNACLES := [")
    k = s.index("\n]", i)
    return [(key, place, who, int(site)) for key, place, who, site in
            re.findall(r'\{"key": "([^"]+)", "place": "([^"]+)", "who": "([^"]+)",[^\n]*?"site": (\d+)', s[i:k])]


def boss_names():
    s = open(os.path.join(ROOT, "scripts", "sim", "data.gd"), encoding="utf-8").read()
    i = s.index("const BOSSES := [")
    return re.findall(r'"zone": \d+, "name": "([^"]+)"', s[i:s.index("\n]", i)])


def plate_job(boss, site, scene, seed, card=None):
    words = kit.POV + "looking " + scene + ". " + kit.EMPTY + " " + kit.LAYOUT + " "
    j = {"out": "%s/%s_plate.png" % (OUT_DIR, slug(boss)), "width": PLATE_W, "height": PLATE_H, "no_background": False,
         "seed": seed, "endpoint": "generate-image-v2", "single": True, "style_options": kit.STYLE,
         "style_image": "res://art/fight_new/%s_plate.png" % site}
    if card:
        j["reference_images"] = [card]
        words += MAP_CARD + " "
    j["description"] = words + kit.TAIL
    j["_where"] = "%s's fight, the plate: his den at %s (styled on art/fight_new/%s_plate.png%s)" % (
        boss, site, site, (", the place from " + card.replace("res://", "")) if card else "")
    return j


def wall_job(boss, site, cover, seed):
    cover = cover.replace("a low ", "a ")    # "low" fights "tall, filling the lower 85%" (make_fight_walls_manifest.py)
    return {"out": "%s/%s_cover.png" % (OUT_DIR, slug(boss)), "width": WALL_W, "height": WALL_H, "no_background": True,
            "seed": seed + REROLL.get(boss, 0), "endpoint": "generate-image-v2", "single": True, "style_options": kit.STYLE,
            "style_image": "res://art/fight_walls/%s_cover.png" % site,
            "description": ("Seen very close from behind, running unbroken across the whole width of the frame: " + cover +
                            ", as the cover a player crouches behind in a light-gun arcade game. One single continuous piece "
                            "edge to edge, no repeated sections, no seams, no tiles. It touches the left, right and bottom "
                            "edges of the image: no margin or border on any side. The cover is tall and fills the lower 85% "
                            "of the image as one solid face, running all the way down to the bottom edge of the image with no "
                            "gap, no ground and nothing below it, so a player crouched low behind it sees only the cover; only "
                            "its uneven top edge sits above that, nothing above or behind it. Everything on it plain and "
                            "unprinted, no lettering, numbers or pictures anywhere. " + kit.TAIL),
            "_where": "%s's fight, the wall, tall enough for the full duck (styled on art/fight_walls/%s_cover.png)" % (boss, site)}


def used_seeds():
    """Every seed in the other manifests: {seed: [out, ...]}."""
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
    names = boss_names()
    for boss, _site, _scene, _cover in HEADS:
        if boss not in names:
            sys.exit("data.gd BOSSES has no %s (it has: %s)" % (boss, ", ".join(names)))
    pins = pinnacles()
    if sorted(p[0] for p in pins) != sorted(PINNACLE_WORDS):
        sys.exit("data.gd PINNACLES are %s; this maker has words for %s" % ([p[0] for p in pins], sorted(PINNACLE_WORDS)))
    jobs = []
    tests = []
    seed = SEED0
    for boss, site, scene, cover in HEADS:
        p, w = plate_job(boss, site, scene, seed), wall_job(boss, site, cover, seed + 1)
        seed += 2
        jobs += [p, w]
        if boss == "The Manager":
            tests += [p, w]
    for key, place, who, site_i in pins:
        site = SITE_KEYS[site_i]
        scene, cover = PINNACLE_WORDS[key]
        card = "res://art/places/%s.png" % slug(place)
        if not os.path.exists(os.path.join(ROOT, card.replace("res://", ""))):
            card = None
        jobs += [plate_job(who, site, scene, seed, card), wall_job(who, site, cover, seed + 1)]
        seed += 2
    used = used_seeds()
    clash = {j["seed"]: used[j["seed"]] for j in jobs if j["seed"] in used}
    if clash:
        sys.exit("seeds already used elsewhere: %s - move SEED0" % clash)
    for j in jobs:
        for ref in [j["style_image"]] + j.get("reference_images", []):
            if not os.path.exists(os.path.join(ROOT, ref.replace("res://", ""))):
                print("warning: no %s on disk (%s)" % (ref, j["out"]))
    run = "tools\\art.bat %s   (the dry run first, then it asks; one that came out wrong: ++ --only <boss>_plate ++ --force; or godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/%s)"
    common = [
        "Boss backdrops: art/fight_boss/<boss>_plate.png 744x320 and _cover.png 744x256 (the wall's body filling the lower 85% down to the bottom edge, as art/fight_walls/). A head's pair styled on his site's live pair; a pinnacle's on his host site's pair with his map card (art/places/) as a reference image. Nothing live is touched.",
        "The code doesn't show them yet: RunView.tex() needs art/fight_boss/ in its folders and a boss's fight needs _site(<boss>) (Matt's go first).",
        "Regenerate with python3 tools/make_boss_backdrops_manifest.py; check with python3 tools/art_lint.py.",
    ]
    test = {"_readme": ["FIAT BOSS BACKDROPS, THE TEST (25 Oct): the Manager's office and desk. Judge them in the frame before the set.",
                        "Run: " + run % ("boss_backdrops_test", "pixellab_boss_backdrops_test_manifest.json")] + common, "jobs": tests}
    full = {"_readme": ["FIAT BOSS BACKDROPS, THE SET (25 Oct): every boss's plate and wall (%d jobs: four heads, three pinnacles). After the test reads; the test's Manager is skipped as made." % len(jobs),
                        "Run: " + run % ("boss_backdrops", "pixellab_boss_backdrops_manifest.json")] + common, "jobs": jobs}
    for name, m in ((OWN[1], test), (OWN[0], full)):
        with open(os.path.join(ROOT, "tools", name), "w", encoding="utf-8") as f:
            json.dump(m, f, indent=1, ensure_ascii=False)
    print("boss backdrops: test %d jobs, set %d jobs, seeds %d-%d" % (len(tests), len(jobs), SEED0, seed - 1))


if __name__ == "__main__":
    main()
