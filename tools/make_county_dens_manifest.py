"""The County heads' dens (6 Nov; docs/design/county_stages.md §5): a plate and a wall for each of the four, so a head's
own fight reads as his den from the first man, as the campaign heads' and the order's do (make_boss_backdrops_manifest.py).
8 jobs: plates 744x320 and walls 744x256, $0.15 each.

  python3 tools/make_county_dens_manifest.py  -> tools/pixellab_county_dens_manifest.json

Out art/fight_boss/<head>_plate.png and _cover.png (the_bailiff, the_auditor, the_collector, the_treasurer): the den key
(BUILD61-U, RunView's head_den taught a County head's fight) reads them by name. New names, nothing live overwritten.

The style: the zone's FIRST place's pair (art/fight_county/<place>_plate.png / _cover.png), not the head's own place's -
his place is the zone's last, and the 6 Nov lesson is that a plate styled on its own place's comes back a near-copy. So the
palette only, and the den said in words. The kit's POV, EMPTY, LAYOUT and TAIL; the walls in make_boss_backdrops_manifest.py's
words (a tall foreground cover, its body the lower 85% down to the bottom edge, no margin).

Checked against docs/art/pixellab_lessons.md: nobody in the plate; never what's drawn over a backdrop; the painting to
all four edges; lettering - keys with no tags, plain unprinted boxes, blank ledgers, a whiteboard wiped clean (the spec's
"plain wall chart" invites lines and labels), plain printing plates, lockers and cabinets with no numbers or labels;
"sign" never used. Seeds 642000-642007, clear of every manifest (checked here and by tools/art_lint.py)."""
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_fight_kit_manifest as kit  # noqa: E402  (POV, EMPTY, LAYOUT, TAIL, STYLE, the plate size)

ROOT = kit.ROOT
OWN = "pixellab_county_dens_manifest.json"
SEED0 = 642000      # clear of every other manifest's (the County stage plates 641000-641023)
WALL_W, WALL_H = 744, 256
OUT_DIR = "art/fight_boss"
STYLE_LINE = ("Only the palette, light and painting style of the style image - nothing of its view, its place or its "
              "subject, which is somewhere else entirely.")
FILL = "The painting fills the whole canvas to all four edges, no border, frame or margin."
NOBODY = "No people or figures anywhere."

# The spec §5's dens: head -> (his den, his wall).
DENS = {
    "The Bailiff": (
        "into a truck stop's back office made into a bailiff's store: hundreds of keys hanging on rows of hooks with no "
        "tags on them, wheel clamps stacked on the floor, plain unprinted cardboard boxes of seized goods piled to the "
        "ceiling, a battered desk, a strip light, a dark doorway on the left",
        "a row of grey steel lockers, their doors dented and some hanging open, no numbers or labels on them"),
    "The Auditor": (
        "into a glass-walled audit room: a long table stacked high with closed plain ledgers and box files with blank "
        "spines, a whiteboard on the wall wiped clean, office chairs pushed back, glass partitions all round, a dark "
        "doorway on the left",
        "a row of grey steel filing cabinets, their drawers pulled out and empty, no labels on them"),
    "The Collector": (
        "into a country manor's study: a fire lit in a stone fireplace, a heavy safe standing open and empty, a big "
        "desk covered in open ledgers with blank pages, leather armchairs, dark wood panelling, a dark doorway on the "
        "left",
        "a long barricade of heavy carved wooden desks tipped onto their sides end to end, running off both the left and the right edges of the frame, their carved panels towards the viewer"),
    "The Treasurer": (
        "into a grand chamber under a high dome: a marble floor, a great desk raised on a dais at the back, plain metal "
        "printing plates with nothing engraved on them laid on a table, tall columns round the walls, a dark archway on "
        "the left",
        "a grey marble balustrade of heavy turned posts under a thick rail"),
}


def county():
    """data.gd COUNTY: [key, place, cz, who or ""]."""
    s = open(os.path.join(ROOT, "scripts", "sim", "data.gd"), encoding="utf-8").read()
    i = s.index("const COUNTY := [")
    out = []
    for entry in s[i:s.index("\n]", i)].split('{"key": ')[1:]:
        m = re.match(r'"([^"]+)", "place": "([^"]+)", "cz": (\d+)', entry)
        w = re.search(r'"who": "([^"]+)"', entry)
        out.append((m.group(1), m.group(2), int(m.group(3)), w.group(1) if w else ""))
    return out


def plate_job(who, first, scene, seed):
    return {"out": "%s/%s_plate.png" % (OUT_DIR, kit.slug(who)), "width": kit.PLATE_W, "height": kit.PLATE_H,
            "no_background": False, "seed": seed, "endpoint": "generate-image-v2", "single": True,
            "style_options": kit.STYLE, "style_image": "res://art/fight_county/%s_plate.png" % kit.slug(first),
            "description": " ".join([kit.POV + "looking " + scene + ".", kit.EMPTY, NOBODY, kit.LAYOUT, STYLE_LINE, FILL,
                                     "Everything in it plain and unprinted, no lettering, numbers or pictures anywhere.", kit.TAIL]),
            "_where": "%s's own fight, the plate: his den (styled on %s's plate, palette only)" % (who, first)}


def wall_job(who, first, cover, seed):
    return {"out": "%s/%s_cover.png" % (OUT_DIR, kit.slug(who)), "width": WALL_W, "height": WALL_H, "no_background": True,
            "seed": seed, "endpoint": "generate-image-v2", "single": True, "style_options": kit.STYLE,
            "style_image": "res://art/fight_county/%s_cover.png" % kit.slug(first),
            "description": ("Seen very close from behind, running unbroken across the whole width of the frame: " + cover +
                            ", as the cover a player crouches behind in a light-gun arcade game. One single continuous piece "
                            "edge to edge, no repeated sections, no seams, no tiles. It touches the left, right and bottom "
                            "edges of the image: no margin or border on any side. The cover is tall and fills the lower 85% "
                            "of the image as one solid face, running all the way down to the bottom edge of the image with no "
                            "gap, no ground and nothing below it, so a player crouched low behind it sees only the cover; only "
                            "its uneven top edge sits above that, nothing above or behind it. " + STYLE_LINE + " Everything on "
                            "it plain and unprinted, no lettering, numbers or pictures anywhere. " + kit.TAIL),
            "_where": "%s's own fight, the wall, tall enough for the full duck (styled on %s's wall, palette only)" % (who, first)}


def used_seeds():
    seen = {}
    for path in glob.glob(os.path.join(ROOT, "tools", "pixellab_*manifest.json")):
        if os.path.basename(path) == OWN:
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
    rows = county()
    heads = [(who, cz) for _k, _p, cz, who in rows if who]
    if sorted(w for w, _z in heads) != sorted(DENS):
        sys.exit("data.gd COUNTY's heads are %s; this maker has dens for %s" % ([w for w, _z in heads], sorted(DENS)))
    # Rerolled 6 Nov (the runner): the Collector's desk came back short of the left, right and bottom edges (opaque
    # x 35-708, y to 243 of 744x256), and again at +10000 (x 72-670): one desk has ends, so it is a row of desks now. Seed +20000.
    REROLL = {"The Collector": 20000}
    jobs = []
    seed = SEED0
    for who, cz in heads:
        first = next(p for _k, p, z, _w in rows if z == cz)      # the zone's first place
        scene, cover = DENS[who]
        jobs += [plate_job(who, first, scene, seed), wall_job(who, first, cover, seed + 1 + REROLL.get(who, 0))]
        seed += 2
    used = used_seeds()
    clash = {j["seed"]: used[j["seed"]] for j in jobs if j["seed"] in used}
    if clash:
        sys.exit("seeds already used elsewhere: %s - move SEED0" % clash)
    try:    # this maker's own outs, once run, are its to rewrite (a reroll); anything else on disk is someone else's
        own_outs = {j["out"] for j in json.load(open(os.path.join(ROOT, "tools", OWN), encoding="utf-8"))["jobs"]}
    except (ValueError, OSError):
        own_outs = set()
    for j in jobs:
        if not os.path.exists(os.path.join(ROOT, j["style_image"].replace("res://", ""))):
            sys.exit("no %s on disk (%s)" % (j["style_image"], j["out"]))
        if os.path.exists(os.path.join(ROOT, j["out"])) and j["out"] not in own_outs:
            sys.exit("on disk already (a new name was expected): %s" % j["out"])
    readme = [
        "FIAT COUNTY DENS (6 Nov; docs/design/county_stages.md §5): the four County heads' own fights, a plate (744x320) and "
        "a wall (744x256) each, %d jobs at $0.15 (about $%.2f)." % (len(jobs), 0.15 * len(jobs)),
        "Out art/fight_boss/<head>_plate.png / _cover.png; the den key reads them by name from the first man. Styled on the "
        "zone's first place's pair, palette only (the 6 Nov lesson). ++ --parallel 3. After Matt has read the slice on test art.",
        "Regenerate with python3 tools/make_county_dens_manifest.py; check with python3 tools/art_lint.py.",
    ]
    with open(os.path.join(ROOT, "tools", OWN), "w", encoding="utf-8") as f:
        json.dump({"_readme": readme, "jobs": jobs}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print("county dens: %d jobs, seeds %d-%d" % (len(jobs), SEED0, seed - 1))


if __name__ == "__main__":
    main()
