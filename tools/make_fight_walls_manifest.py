"""The fight's cover walls, tall (23 Oct, Matt: ducking "you can see the same tiled wall 3 times ... regenerating them
at a larger size so that it was just one continuous piece of art so there would be nothing to duplicate or fix in
code"). The 17 Oct walls are 744x173 strips: ducked, the wall rises 80 px and its picture stops short of the frame's
foot, so the code tiles its bottom bricks down under it (run_view's _cover_fill) - the repeat. These are 744x256, the
wall's body filling the lower 85% right down to the bottom edge: drawn at 688 wide (x0.925) that's ~200 px of wall
against the ~130 the full duck needs, so nothing is tiled. Once they're judged the code drops the fill.

Writes two manifests, walls only:

  tools/pixellab_fight_walls_test_manifest.json  - the Parade's wall, to judge ducked in the frame first
  tools/pixellab_fight_walls_manifest.json       - all twelve sites' walls (the test's Parade skipped as made)

To art/fight_walls/<site>_cover.png, a folder of their own: nothing live is overwritten, no --force needed, and the
17 Oct walls in art/fight_new/ stay as they are. Each styled on its 17 Oct wall, on a new seed, the cover's words
from the fight kit's manifest maker (make_fight_kit_manifest.SITES).

Run: python3 tools/make_fight_walls_manifest.py, then the test:
  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_fight_walls_test_manifest.json
and, once the Parade's reads, the set:
  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_fight_walls_manifest.json
(++ --dry-run to list; one that came out wrong: ++ --only <site> ++ --force)."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_fight_kit_manifest as kit  # noqa: E402  (the sites' words, the style, the tail)

ROOT = kit.ROOT
WALL_W, WALL_H = 744, 256
SEED0 = 101000                # clear of every other manifest's seeds (98500-98511 were the web art's: the lessons, no two jobs share a seed)
# The walls' own words where the kit's invite lettering or numbers (23 Oct manifest check); kit.SITES stays as it is.
COVER_FIX = {
    "the_garden_centre": "a pallet stacked with split plain unprinted compost bags, soil spilling over the edge",
    "ransacked_streets": "a low front-garden wall of pebbledash with a toppled wheelie bin against it, no number on it",
    "the_pleasure_park": "the side of an overturned dodgem car, no numbers on it, its pole bent",
    "the_bank": "the front of a plain wooden bank counter, pens on chains hanging over its edge",
}


def wall_job(key, cover, seed):
    cover = cover.replace("a low ", "a ")    # "low" fights "tall, filling the lower 85%" (the lessons: prompts that fight lose)
    return {"out": "art/fight_walls/%s_cover.png" % key, "width": WALL_W, "height": WALL_H, "no_background": True,
            "seed": seed, "endpoint": "generate-image-v2", "single": True, "style_options": kit.STYLE,
            "style_image": "res://art/fight_new/%s_cover.png" % key,
            "description": ("Seen very close from behind, running unbroken across the whole width of the frame: " + cover +
                            ", as the cover a player crouches behind in a light-gun arcade game. One single continuous piece "
                            "edge to edge, no repeated sections, no seams, no tiles. The cover is tall and fills the lower 85% "
                            "of the image as one solid face, running all the way down to the bottom edge of the image with no "
                            "gap, no ground and nothing below it, so a player crouched low behind it sees only the cover; only "
                            "its uneven top edge sits above that, nothing above or behind it. Everything on it plain and "
                            "unprinted, no lettering, numbers or pictures anywhere. " + kit.TAIL),
            "_where": "the wall, tall enough for the full duck: %s (styled on art/fight_new/%s_cover.png)" % (key, key)}


def main():
    jobs = []
    tests = []
    for i, (key, _scene, cover) in enumerate(kit.SITES):
        j = wall_job(key, COVER_FIX.get(key, cover), SEED0 + i)
        jobs.append(j)
        if key == "the_parade":
            tests.append(j)
    run = "godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/%s   (++ --dry-run to list; one that came out wrong: ++ --only <site> ++ --force)"
    common = [
        "Walls only: art/fight_walls/<site>_cover.png, 744x256, the body filling the lower 85% down to the bottom edge - tall enough that the full duck needs no tiled fill. The 17 Oct walls in art/fight_new/ are their style and stay untouched.",
        "Regenerate with python3 tools/make_fight_walls_manifest.py.",
    ]
    test = {"_readme": ["FIAT FIGHT WALLS, THE TEST (23 Oct, Matt): the Parade's wall, tall. Judge it ducked in the frame before the set.",
                        "Run: " + run % "pixellab_fight_walls_test_manifest.json"] + common, "jobs": tests}
    full = {"_readme": ["FIAT FIGHT WALLS, THE SET (23 Oct, Matt): every site's wall, tall (%d). After the test reads; the test's Parade is skipped as made." % len(jobs),
                        "Run: " + run % "pixellab_fight_walls_manifest.json"] + common, "jobs": jobs}
    for name, m in (("pixellab_fight_walls_test_manifest.json", test), ("pixellab_fight_walls_manifest.json", full)):
        with open(os.path.join(ROOT, "tools", name), "w", encoding="utf-8") as f:
            json.dump(m, f, indent=1, ensure_ascii=False)
    print("walls: test %d job, set %d jobs" % (len(tests), len(jobs)))


if __name__ == "__main__":
    main()
