"""The mythics' pictures (16 Oct, docs/design/mythics.md): seven jobs, written to the LIVE names art/items/<slug>.png at
the base's footprint x 64 px, as the gap uniques' were. Until a file exists the cell draws the base's picture (the test
art). Run: python3 tools/make_mythic_manifest.py, then
godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_items_mythics_manifest.json
(++ --dry-run to list; ++ --only <slug> ++ --force to redo one)."""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_item_manifests as M  # noqa: E402

# one more line than the other uniques: these are the ones that break the game, and should look it - but still a
# real object on a grey day, the glow faint, never a fantasy item
MYTH = (" It is the one of its kind in the country, kept and cared for when nothing else is: a faint warm red-orange glow "
        "lies along one edge of it, like the last of a sunset on metal, subtle and natural.")

JOBS = {
    "The Last Orders": ("Primary", "a single old bolt-action .303 rifle seen exactly side-on with the muzzle pointing left, "
                        "laid level and filling the frame left to right: a brass pub bell tied to the sling swivel, the "
                        "stock carved with the names of a dozen pubs, scorch marks, frost, green stains and a cut along the "
                        "barrel as if every kind of harm had passed through it"),
    "The Spare Key": ("Secondary", "a single old service revolver seen exactly side-on with the muzzle pointing left, laid "
                      "level and filling the frame: a ring of house keys hung from the lanyard loop, a front-door Yale key "
                      "taped to the grip, the cylinder worn bright"),
    "The Headmaster's Cap": ("Helmet", "a single black academic mortarboard cap fixed over a battered police riot helmet, "
                             "seen from the front and slightly above, filling the frame: the tassel gold, chalk dust in the "
                             "seams, a school crest painted on the shell"),
    "The Bomb Disposal Suit": ("Armour", "a single heavy army bomb disposal suit jacket laid flat, seen from the front and "
                               "filling the frame: thick green armour panels, a huge collar, scorch and blast marks all over "
                               "it, every one of them stopped"),
    "The Ambulance's Bag": ("Rig", "a single green paramedic's response bag with many pouches, seen from the front and "
                            "filling the frame: reflective strips, an ambulance service badge, every pouch full of "
                            "bandages and dressings to bursting, zips straining"),
    "The Removal Van": ("Backpack", "a single huge external-frame backpack stacked impossibly high with a household's "
                        "belongings strapped on - a lampshade, a kettle, boxes, a rolled rug - seen from the front, "
                        "filling the frame, a removal firm's ratchet strap round it all"),
    "The Freedom of the Borough": ("Charm", "a single heavy old iron ceremonial key on a red ribbon beside a rolled scroll "
                                   "with a wax council seal, seen from above and filling the frame"),
}


def base_of(name):
    m = re.search(r'\{"name": "%s", "slot": "([^"]+)", "base": "([^"]+)"' % re.escape(name), M.src)
    return m.group(1), m.group(2)


def main():
    jobs = []
    for n, (slot, words) in JOBS.items():
        s, base = base_of(n)
        assert s == slot, (n, s, slot)
        w, h = M.footprint(slot, base)
        jobs.append({"out": "art/items/%s.png" % M.slug(n), "endpoint": "generate-image-v2",
                     "description": "A realistic painted pixel-art still-life of " + words + "." + MYTH + M.TAIL,
                     "width": w * M.CELL, "height": h * M.CELL, "no_background": True, "seed": 81000 + len(jobs) * 37,
                     "single": True, "style_image": "res://art/reference/items/ref_01.png",
                     "style_options": {"color_palette": True, "outline": True, "detail": True, "shading": True}})
    out = {"_readme": [__doc__.replace("\n", " ")], "jobs": jobs}
    path = os.path.join(M.ROOT, "tools", "pixellab_items_mythics_manifest.json")
    json.dump(out, open(path, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    for j in jobs:
        print(j["out"], j["width"], "x", j["height"])


if __name__ == "__main__":
    main()
