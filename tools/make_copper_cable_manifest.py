"""Copper cable (1 Nov, materials in the pack: the rebuild material renamed off the socketable "Copper wire", which
keeps art/items/copper_wire.png). One 64x64 icon written to art/items/copper_cable.png, in the cargo icons' template
(plain, unprinted; tools/make_expeditions_manifest.py). Run: python3 tools/make_copper_cable_manifest.py"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TAIL = ("One object centred and filling the frame, soft directional overcast daylight, natural material rendering "
        "with fine detail and painterly shading; no black outlines, no flat cel shading, not anime, not a cartoon, "
        "not a glossy video-game item; the look of a real object photographed on a grey day in a country that has run "
        "out of money. Muted cool northern palette, worn and repaired, nothing new. Nothing else in the frame, no gun, "
        "no hands, no person, no text, no logos, no floor, wall, ground or sky around it, a plain dark neutral background.")
CABLE = [
    ("Copper cable", "a coil of thick grey-sheathed copper cable, its cut end showing bright copper strands, on a scrap of broken pallet", 123390, 5),
]


def slug(name):
    out, prev = "", False
    for ch in name.lower():
        if ch.isalnum():
            out += ch
            prev = False
        elif not prev:
            out += "_"
            prev = True
    return out.strip("_")


jobs = []
for name, what, seed, ref in CABLE:
    jobs.append({
        "out": "art/items/%s.png" % slug(name),
        "endpoint": "generate-image-v2",
        "description": "A realistic painted pixel-art still-life of a single salvaged material seen from above at a slight angle: %s, plain and unprinted, no markings, filling the frame. %s" % (what, TAIL),
        "width": 64, "height": 64, "no_background": True, "seed": seed, "single": True,
        "style_image": "res://art/reference/items/ref_%02d.png" % ref,
        "style_options": {"color_palette": True, "outline": True, "detail": True, "shading": True},
    })
m = {"_readme": ["FIAT MATERIALS - Copper cable (1 Nov). Written by tools/make_copper_cable_manifest.py; the cargo icons' "
                 "template. A job whose file exists is skipped."], "jobs": jobs}
with open(os.path.join(ROOT, "tools", "pixellab_copper_cable_manifest.json"), "w", encoding="utf-8", newline="\n") as f:
    json.dump(m, f, indent=1, ensure_ascii=False)
    f.write("\n")
print(len(jobs), "jobs")
