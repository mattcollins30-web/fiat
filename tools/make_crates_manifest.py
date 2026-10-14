#!/usr/bin/env python3
"""Writes tools/pixellab_crates_manifest.json (13 Oct, docs/design/search_crates.md): the eight crates of the search,
each shut and open, for the run screen's crate row (art/crates/<key>.png and <key>_open.png, 64 x 64, shown at 52).
Until a crate's art is in, the panel draws a line crate in the crate's colour.

  python3 tools/make_crates_manifest.py
  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_crates_manifest.json
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REFS = ["res://art/reference/items/ref_%02d.png" % k for k in range(1, 5)]
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}
TAIL = (" One object centred and filling the frame, seen from a little above and to the side, a single bold silhouette that "
        "still reads at a quarter of this size, soft directional overcast daylight, natural material rendering with painterly "
        "shading; no black outlines, no flat cel shading, not anime, not a cartoon, not a glossy video-game icon; the look of "
        "a real object photographed on a grey day in a country that has run out of money. Muted cool northern palette, worn "
        "and scuffed, nothing new. Nothing else in the frame, no hands, no person, no text, no logos, a plain dark neutral "
        "background.")

# key (Data.CRATES), the thing shut, the same thing opened
CRATES = [
    ("cardboard", "A realistic painted pixel-art still-life of a battered brown cardboard box, its flaps folded shut, parcel tape peeling, one corner crushed and water-stained.",
     "A realistic painted pixel-art still-life of a battered brown cardboard box, its flaps pulled open and hanging, parcel tape torn, empty and dark inside, one corner crushed and water-stained."),
    ("ammo_tin", "A realistic painted pixel-art still-life of an olive-drab steel ammunition tin, its hinged lid latched shut, the paint chipped to bare metal at the edges, a carry handle on top.",
     "A realistic painted pixel-art still-life of an olive-drab steel ammunition tin with its hinged lid thrown back open, empty inside, the paint chipped to bare metal at the edges."),
    ("jewellery", "A realistic painted pixel-art still-life of a small old wooden jewellery box with a tarnished brass clasp, its lid shut, faded velvet showing at the seam.",
     "A realistic painted pixel-art still-life of a small old wooden jewellery box with its lid open, the faded pink velvet lining inside empty, a tarnished brass clasp hanging loose."),
    ("toolbox", "A realistic painted pixel-art still-life of a dented red metal cantilever toolbox, latched shut, the red paint scratched through to grey steel.",
     "A realistic painted pixel-art still-life of a dented red metal cantilever toolbox opened out, its trays fanned up and empty, the red paint scratched through to grey steel."),
    ("medicine", "A realistic painted pixel-art still-life of a small white wall-mounted medicine cabinet with a mirrored door, shut, a faded green cross on it, the enamel chipped.",
     "A realistic painted pixel-art still-life of a small white wall-mounted medicine cabinet with its mirrored door swung wide open on its side hinges, the door standing out at a right angle to the cabinet so we see its thin edge and the faded green cross is turned away, the inside of the cabinet in full view: a dark empty box with two bare glass shelves. The open door and the empty inside are the most obvious things in the picture."),
    ("filing", "A realistic painted pixel-art still-life of a grey steel two-drawer office filing cabinet, both drawers shut, dented, a paper label holder on each drawer.",
     "A realistic painted pixel-art still-life of a grey steel two-drawer office filing cabinet with the top drawer pulled out, empty hanging file rails inside, dented."),
    ("safe", "A realistic painted pixel-art still-life of a heavy dark-grey steel office safe, its thick door shut, a brass combination dial and a chrome handle, scuffed and pry-marked.",
     "A realistic painted pixel-art still-life of a heavy dark-grey steel office safe with its thick door hanging open, empty shelves inside, a brass combination dial, scuffed and pry-marked."),
    ("military", "A realistic painted pixel-art still-life of a long olive-green military transit crate of wooden slats, its lid nailed shut, faded stencilled marks on the side, rope handles.",
     "A realistic painted pixel-art still-life of a long olive-green military transit crate of wooden slats with its lid prised off and leaning against it, straw packing inside and nothing else, rope handles."),
]

# The open crate is drawn FROM the shut one (13 Oct, Matt: the ammo tins faced opposite ways at different thicknesses,
# the filing cabinets came out different colours - "they don't read as the same items"): the shut PNG goes in as the
# reference and the style image, and the prompt holds it to the same object.
SAME = ("The same object as the reference image, drawn again from the identical angle and facing, at the identical size, "
        "thickness and proportions, in the identical paint colour, wear and damage (where these words and the reference "
        "differ on colour, follow the reference); only now it is opened. ")

jobs = []
for k, (key, shut, opened) in enumerate(CRATES):
    shut_png = "res://art/crates/%s.png" % key
    jobs.append({"out": "art/crates/%s.png" % key, "endpoint": "generate-image-v2", "description": shut + TAIL,
                 "width": 64, "height": 64, "no_background": True, "seed": 93000 + k, "single": True,
                 "style_image": REFS[k % 4], "style_options": STYLE, "_where": "the search: the %s, shut" % key})
    jobs.append({"out": "art/crates/%s_open.png" % key, "endpoint": "generate-image-v2", "description": SAME + opened + TAIL,
                 "width": 64, "height": 64, "no_background": True, "seed": 93000 + k, "single": True,
                 "reference_images": [shut_png], "style_image": shut_png, "style_options": STYLE,
                 "_where": "the search: the %s, open (drawn from the shut one)" % key})

readme = [
    "FIAT CRATES (13 Oct, docs/design/search_crates.md): the eight crates of the search, each shut and open (art/crates/, 64 x 64, shown at 52 on the run screen's crate row). The shut and open of a crate share a seed, and the open one is drawn from the shut PNG (reference + style image), so they read as the same thing. Redo a pair as: ++ --only <key> ++ --force (the shut is written first).",
    "Run: godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_crates_manifest.json   (++ --dry-run to list). A job whose file exists is skipped; one that came out wrong: ++ --only <name> ++ --force.",
    "Regenerate with python3 tools/make_crates_manifest.py.",
]
with open(os.path.join(ROOT, "tools", "pixellab_crates_manifest.json"), "w") as f:
    json.dump({"_readme": readme, "jobs": jobs}, f, indent=1)
print(len(jobs), "jobs")
