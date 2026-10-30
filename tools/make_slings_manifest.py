"""The four slings (30 Oct, magazines as items: the gun's magazine mount became a sling mount; docs/design/
meds_ammo_clinic.md). One 64x64 icon each, written to the live name art/items/<slug>.png, in the parts' template
(tools/pixellab_items_parts_manifest.json) on its reference images. Run: python3 tools/make_slings_manifest.py"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TAIL = ("One object centred and filling the frame, soft directional overcast daylight, natural material rendering "
        "with fine detail and painterly shading; no black outlines, no flat cel shading, not anime, not a cartoon, "
        "not a glossy video-game item; the look of a real object photographed on a grey day in a country that has run "
        "out of money. Muted cool northern palette, worn and repaired, nothing new. Nothing else in the frame, no gun, "
        "no hands, no person, no text, no logos, no floor, wall, ground or sky around it, a plain dark neutral background.")
SLINGS = [
    ("Rope sling", "a length of frayed blue baler-twine rope tied into a loop, knotted at both ends, loosely coiled", 70900, 1),
    ("Webbing sling", "a single strap of faded olive canvas webbing with a plain steel buckle, loosely coiled", 70901, 2),
    ("Leather sling", "a strap of cracked brown leather with brass hooks at each end and a slide buckle, loosely coiled", 70902, 3),
    ("Two-point sling", "a padded two-point gun sling of dull grey webbing with two plain metal clips and a pull-tab adjuster, loosely coiled", 70903, 4),
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
for name, what, seed, ref in SLINGS:
    jobs.append({
        "out": "art/items/%s.png" % slug(name),
        "endpoint": "generate-image-v2",
        "description": "A realistic painted pixel-art still-life of a single gun sling seen from above: %s, plain and unprinted, filling the frame. %s" % (what, TAIL),
        "width": 64, "height": 64, "no_background": True, "seed": seed, "single": True,
        "style_image": "res://art/reference/items/ref_%02d.png" % ref,
        "style_options": {"color_palette": True, "outline": True, "detail": True, "shading": True},
    })
m = {"_readme": ["FIAT GEAR - the four slings (30 Oct). Written by tools/make_slings_manifest.py; the same template as "
                 "pixellab_items_parts_manifest.json. A job whose file exists is skipped."], "jobs": jobs}
with open(os.path.join(ROOT, "tools", "pixellab_slings_manifest.json"), "w", encoding="utf-8", newline="\n") as f:
    json.dump(m, f, indent=1, ensure_ascii=False)
    f.write("\n")
print(len(jobs), "jobs")
