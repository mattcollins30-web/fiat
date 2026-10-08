#!/usr/bin/env python3
"""Writes tools/pixellab_ui_manifest.json: the fourteen UI glyphs (8 Oct) as
painted pixel-art still-lifes in the items' house style, one job each, written
straight to art/ui/<name>.png over the line drawings there now. The shell tells
a painting from a line drawing by its colour (UI.glyph_mono) and shows a
painting as it is, so the files can be swapped in any order.

Run (from the project root):
  python3 tools/make_ui_manifest.py
  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_ui_manifest.json ++ --force

(--force: the line drawings exist under the same names, and the runner skips a
file that exists.) The glyphs draw at 38 px on the rail's stamps and 26 px on
the top bar, so each is one strong silhouette, nothing fine.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REFS = ["res://art/reference/items/ref_%02d.png" % k for k in range(1, 5)]

TAIL = (" One object centred and filling the frame, a single bold silhouette that still reads at a quarter of this size, "
        "soft directional overcast daylight, natural material rendering with painterly shading; no black outlines, no flat "
        "cel shading, not anime, not a cartoon, not a glossy video-game icon; the look of a real object photographed on a "
        "grey day in a country that has run out of money. Muted cool northern palette, worn and repaired, nothing new. "
        "Nothing else in the frame, no hands, no person, no text, no logos, a plain dark neutral background.")

# name -> (where it shows, the object)
GLYPHS = {
    "yard": ("the rail: The Yard", "A realistic painted pixel-art still-life of a small corrugated-iron shed, front on, a padlock on the hasp of its door, rust at the edges, a weed at the step."),
    "runs": ("the rail: Runs", "A realistic painted pixel-art still-life of a pair of worn black work boots side by side, laces undone, dried mud on the soles, seen from the front and slightly above."),
    "lockup": ("the rail: Lock-up", "A realistic painted pixel-art still-life of a heavy steel padlock, closed, scratched and dulled, its shackle thick, seen front on."),
    "bench": ("the rail: Bench", "A realistic painted pixel-art still-life of an adjustable spanner, worn steel with oil on the jaws, lying at a slight diagonal."),
    "caravan": ("the rail: Caravan", "A realistic painted pixel-art still-life of a small two-berth touring caravan, cream with a green stripe, moss on the roof, one window, side on."),
    "clinic": ("the rail: Clinic", "A realistic painted pixel-art still-life of a green first-aid tin with a plain white cross on its dented lid, seen from above at a slight angle."),
    "fence": ("the rail: The Fence", "A realistic painted pixel-art still-life of a brown cardboard luggage tag on a loop of string, blank, creased at one corner."),
    "radio": ("the rail: Radio", "A realistic painted pixel-art still-life of a battered CB radio handset on a short coiled lead, black plastic worn grey at the grip."),
    "cash": ("the top bar: cash", "A realistic painted pixel-art still-life of a folded wad of worn banknotes held by a perished rubber band, no readable print, seen from above at a slight angle."),
    "notes": ("the top bar: notes", "A realistic painted pixel-art still-life of a small bundle of folded handwritten paper slips held by a paperclip, the writing an illegible scrawl, seen from above."),
    "hp": ("the top bar: HP", "A realistic painted pixel-art still-life of an old red enamel heart-shaped pin badge, chipped at one edge, the brass showing through, seen front on."),
    "xp": ("the top bar: XP", "A realistic painted pixel-art still-life of a small brass five-pointed star badge, tarnished, seen front on."),
    "dps": ("the top bar: damage a second", "A realistic painted pixel-art still-life of a single brass rifle cartridge standing upright, dull and fingerprinted, seen from the side and slightly above."),
    "where": ("the top bar: where the runner is", "A realistic painted pixel-art still-life of a brass pocket compass, lid open, the glass scratched, seen from above."),
}


def main():
    jobs = []
    for k, (name, (where, prompt)) in enumerate(GLYPHS.items()):
        seed = 91000 + k
        jobs.append({
            "out": "art/ui/%s.png" % name,
            "endpoint": "generate-image-v2",
            "description": prompt + TAIL,
            "width": 64,
            "height": 64,
            "no_background": True,
            "seed": seed,
            "single": True,
            "style_image": REFS[seed % len(REFS)],
            "style_options": {"color_palette": True, "outline": True, "detail": True, "shading": True},
            "_where": where,
        })
    manifest = {
        "_readme": [
            "FIAT UI GLYPHS - the fourteen marks on the rail and the top bar (8 Oct), one job each, written straight to the LIVE name art/ui/<name>.png over the white line drawings there now ('single': one file, no _NN, no sheet). 64 x 64: the shell draws them at 38 px on the rail's stamps and 26 px on the top bar with mipmaps, so each is one bold silhouette.",
            "Run: godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_ui_manifest.json ++ --force   (--force because the line drawings exist under the same names; ++ --dry-run to list; one that came out wrong: ++ --only <name> ++ --force).",
            "The shell tells a painting from a line drawing by its colour (UI.glyph_mono): a painting shows as it is, a line drawing is tinted grey, gold or dark by where it sits. So the set can be swapped one at a time, and a glyph that doesn't read can go back to its line drawing (git checkout art/ui/<name>.png).",
            "The stamps on the rail are dark grey, gold when the room is lit; the top bar is the panel's dark. A painting with a plain dark background cut away (no_background) sits on both.",
            "Regenerate this manifest with python3 tools/make_ui_manifest.py.",
        ],
        "jobs": jobs,
    }
    out = os.path.join(ROOT, "tools", "pixellab_ui_manifest.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=1, ensure_ascii=False)
    print("wrote %s: %d jobs" % (os.path.relpath(out, ROOT), len(jobs)))


if __name__ == "__main__":
    main()
