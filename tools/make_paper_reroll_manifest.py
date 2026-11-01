"""The papers' picture, rerolled (1 Nov, Matt: "the found papers art needs a reroll - it's the only Greenhorn asset
left and it shows"). Every paper shares art/items/paper.png in the cell (00c0c39); this replaces it in the items'
template. It exists, so the run needs --force (the flag says so). Run: python3 tools/make_paper_reroll_manifest.py"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TAIL = ("One object centred and filling the frame, soft directional overcast daylight, natural material rendering "
        "with fine detail and painterly shading; no black outlines, no flat cel shading, not anime, not a cartoon, "
        "not a glossy video-game item; the look of a real object photographed on a grey day in a country that has run "
        "out of money. Muted cool northern palette, worn and repaired, nothing new. Nothing else in the frame, no gun, "
        "no hands, no person, no text, no logos, no floor, wall, ground or sky around it, a plain dark neutral background.")
CABLE = [
    ("Paper", "a small loose bundle of old folded papers and envelopes, creased and damp-stained, the top sheet's corner curling, its lines only faint grey smudges with no readable writing", 123392, 2),
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
        "description": "A realistic painted pixel-art still-life seen from above at a slight angle: %s, no letters, no numbers, no logos, no stamps, filling the frame. %s" % (what, TAIL),
        "width": 64, "height": 64, "no_background": True, "seed": seed, "single": True,
        "style_image": "res://art/reference/items/ref_%02d.png" % ref,
        "style_options": {"color_palette": True, "outline": True, "detail": True, "shading": True},
    })
m = {"_readme": ["FIAT ITEMS - the papers' picture rerolled (1 Nov, Matt). Written by tools/make_paper_reroll_manifest.py; "
                 "the items' template. art/items/paper.png exists: run with --force."], "jobs": jobs}
with open(os.path.join(ROOT, "tools", "pixellab_paper_reroll_manifest.json"), "w", encoding="utf-8", newline="\n") as f:
    json.dump(m, f, indent=1, ensure_ascii=False)
    f.write("\n")
print(len(jobs), "jobs")
