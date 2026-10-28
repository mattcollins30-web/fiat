"""The 0.9.1 batch's missing art (28 Oct, Matt: "a manifest for any missing art like the new meds and magazines"):
the five cures, the Clinic's medical supplies, and a magazine picture for each kind of rounds a rig pouch carries.
The item template (make_item_manifests: its still-life prompt, TAIL, the four style references), one job a picture,
written straight to the live name:

  python3 tools/make_meds_mags_manifest.py
    -> tools/pixellab_meds_mags_manifest.json

  C:\\Godot\\godot.console.exe --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_meds_mags_manifest.json ++ --parallel 3
  (++ --dry-run to list; one that came out wrong: ++ --only <slug> ++ --force)

To art/items/<slug>.png: Items.art finds the cures and the supplies by their base's slug; Items.mag_art finds a rig
pouch's art/items/mag_<type>.png (mag_belt for belt links), so nothing needs wiring. A job whose file exists is
skipped. Checked against docs/art/pixellab_lessons.md: the object alone, no setting; unprinted - no labels, words or
numbers; a seed range of its own (121xxx)."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_item_manifests as items  # noqa: E402  (TAIL, REFS, CELL, slug, footprint)

SEED0 = 121000                # clear of every other manifest's seeds (the last used 120115)
MEDS = [
    ("Tourniquet", "a black military tourniquet: a nylon strap with a plastic windlass rod and a red tip, coiled loose, unprinted, no lettering"),
    ("Burn gel", "a small squeezed tube of clear burn gel beside a folded square of gel-soaked dressing, plain white, unprinted, no label, no words"),
    ("Activated charcoal", "a small brown glass bottle of black charcoal powder, the cork out, a little black powder spilled beside it, no label"),
    ("Hot flask", "a dented steel vacuum flask with its cup-lid off, steam curling from the open neck, plain, unprinted"),
    ("Smelling salts", "a tiny old glass vial of white smelling-salt crystals with a brass screw cap, plain, unlabelled"),
    ("Medical supplies", "a tied bundle of medical supplies: rolled bandages, a strip of sealed syringes with no markings or numbers on them, a few blister packs and cotton pads, "
                         "held with a rubber band, all plain and unprinted, no labels, no red cross"),
]
MAGS = [
    ("mag_smg", "two loaded straight SMG magazines side by side in a worn olive canvas pouch, the brass of the top rounds showing, no markings"),
    ("mag_rifle", "two loaded rifle magazines, slightly curved, in a worn olive canvas pouch, brass rounds showing at the top, no markings"),
    ("mag_pistol", "three loaded pistol magazines standing in a small worn black nylon pouch, brass rounds showing at the top, no markings"),
    ("mag_shotgun", "a worn leather shell caddy with six plain red shotgun shells in its loops, brass ends showing, the shells unprinted, no markings"),
    ("mag_improvised", "two long strips of collated nail-gun nails in a worn canvas tool pouch, plain, no markings"),
    ("mag_belt", "a folded belt of linked brass rounds coiled in an olive ammo pouch, plain, no markings"),
]


def job(out, what, w, h, seed):
    return {
        "out": out,
        "endpoint": "generate-image-v2",
        "description": ("A realistic painted pixel-art still-life of %s, seen from above at a slight angle, filling the frame, "
                        "worn and used." % what) + items.TAIL,
        "width": w * items.CELL,
        "height": h * items.CELL,
        "no_background": True,
        "seed": seed,
        "single": True,
        "style_image": items.REFS[seed % len(items.REFS)],
        "style_options": {"color_palette": True, "outline": True, "detail": True, "shading": True},
    }


def main():
    jobs = []
    seed = SEED0
    for base, what in MEDS:
        slot = "Supplies" if base == "Medical supplies" else "Medical"
        w, h = items.footprint(slot, base)
        jobs.append(job("art/items/%s.png" % items.slug(base), what, w, h, seed))
        seed += 1
    for name, what in MAGS:
        jobs.append(job("art/items/%s.png" % name, what, 1, 1, seed))
        seed += 1
    out = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "tools", "pixellab_meds_mags_manifest.json")
    with open(out, "w") as f:
        json.dump({"_readme": "The 0.9.1 batch's missing art (28 Oct): the five cures, the medical supplies, six magazine pouches. "
                              "tools/make_meds_mags_manifest.py writes this.", "jobs": jobs}, f, indent=1)
    print("%d jobs -> %s" % (len(jobs), out))


if __name__ == "__main__":
    main()
