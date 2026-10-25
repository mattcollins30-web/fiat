"""The fight art with a border, rerolled (25 Oct, Matt: "reroll everything with a border").

A scan of every live fight plate and wall (a row or column blank when over 60% of it is clear or pale) found:
  art/fight_new/ransacked_streets_plate.png, the_bank_plate.png - a 12 px band top and bottom, 28 at the sides
    (both styled on their old art/fight plates, which carry the border: styled here on a clean neighbour instead)
  art/fight_walls/shopping_centre_cover.png, the_allotments_cover.png - inset: 20-24 px at the sides, 6-8 at the foot
  art/fight_boss/the_registrar_cover.png - its bottom 4 rows empty
(art/fight_walls/the_bank_cover.png had 1 px at the right: filled by hand. The kit's old covers in art/fight_new are
read only when a wall is missing, and all twelve walls are there.)

Each job is copied from its own manifest - its words, size and style options - with a fresh seed, the edge sentence
the boss walls proved, and a clean style image. The source makers and JSONs are left alone (the fight kit's are Matt's,
uncommitted).

    python3 tools/make_border_reroll_manifest.py
"""
import json

SRC = {
    "art/fight_new/ransacked_streets_plate.png": ("tools/pixellab_fight_kit_manifest.json", "res://art/fight_new/the_parade_plate.png"),
    "art/fight_new/the_bank_plate.png": ("tools/pixellab_fight_kit_manifest.json", "res://art/fight_new/shopping_centre_plate.png"),
    "art/fight_walls/shopping_centre_cover.png": ("tools/pixellab_fight_walls_manifest.json", "res://art/fight_walls/the_pleasure_park_cover.png"),
    "art/fight_walls/the_allotments_cover.png": ("tools/pixellab_fight_walls_manifest.json", "res://art/fight_walls/top_farm_cover.png"),
    "art/fight_boss/the_registrar_cover.png": ("tools/pixellab_boss_backdrops_manifest.json", "res://art/fight_walls/the_bank_cover.png"),
}
SEED0 = 108000
PLATE_EDGE = " The picture fills the whole frame to every edge: no border, no margin, no frame, no letterbox bands at the top, bottom or sides."
COVER_EDGE = " Running off the frame, cut off by its left, right and bottom edges: it touches the left, right and bottom edges of the image, no margin or border on any side."
# 25 Oct: the Shopping Centre's wall came back inset again (31/28 px at the sides, 11 at the foot); the cut-off words
# inside the subject are what fixed the Quartermaster's and the Registrar's walls, so it gets them there, on a new seed
RETRY = {"art/fight_walls/shopping_centre_cover.png": (1000, "a row of upturned mall benches and a broken planter edge",
                                                       "running off the frame, cut off by its left, right and bottom edges")}


def jobs_of(path):
    d = json.load(open(path))
    return d if isinstance(d, list) else d["jobs"]


def main():
    out = []
    for k, (path, (src_path, style_img)) in enumerate(SRC.items()):
        job = dict(next(j for j in jobs_of(src_path) if j["out"] == path))
        job["seed"] = SEED0 + k
        job["style_image"] = style_img
        job["description"] = job["description"].rstrip() + (PLATE_EDGE if path.endswith("_plate.png") else COVER_EDGE)
        if path in RETRY:
            bump, subject, cut = RETRY[path]
            job["seed"] += bump
            job["description"] = job["description"].replace(subject, subject + ", " + cut, 1)
        job["_where"] = "the border reroll (25 Oct): from %s" % src_path
        out.append(job)
    doc = {"_readme": ["The fight art with a border, rerolled (25 Oct): tools/make_border_reroll_manifest.py."], "jobs": out}
    json.dump(doc, open("tools/pixellab_border_reroll_manifest.json", "w"), indent=1)
    print("border reroll: %d jobs, seeds %d-%d" % (len(out), SEED0, SEED0 + len(out) - 1))


if __name__ == "__main__":
    main()
