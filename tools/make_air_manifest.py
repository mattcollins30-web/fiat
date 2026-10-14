"""On the air (14 Oct, docs/design/on_the_air.md): three scenes after the Quartermaster, Kev on the set, one picture
each, 640x360 (shown at 3x), the opening's house style. Writes tools/pixellab_air_manifest.json; out to art/intro/.
Run: python tools/make_air_manifest.py, then
  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_air_manifest.json"""
import json

TAIL = ("Realistic painted pixel art, wide cinematic composition with room to pan, soft light, muted cool northern "
        "palette, worn and lived-in, Britain; no black outlines, not anime, not a cartoon, not glossy; no text, no "
        "logos, no readable writing.")
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}
SCENES = [
    ("air_1", "the_radio", "The corner of a makeshift camp at night under a tarpaulin: a green army field radio set on a "
     "table made from a pallet, its dials and small lamps glowing amber, a pair of headphones and a coiled handset, a "
     "chipped mug, a notepad. Through a gap in the tarpaulin, the camp's brazier and two vans, and beyond them the dark "
     "outline of a dead British town. The radio is the brightest thing in the picture."),
    ("air_2", "the_city", "Britain at night from a hillside above a motorway: below, a large dark city with only a few "
     "scattered fires burning, no streetlights; the motorway empty except for a long line of army lorries with their "
     "headlights on, the only lights moving; far off on the horizon another city, just as dark. Cold, vast, quiet."),
    ("air_3", "the_bank", "A table at night lit by a single torch: old paperwork spread out - a betting slip, a pawn "
     "ticket, a bank statement, a council letter - with numbers circled and ringed in pencil, a notepad with columns of "
     "frequencies, a stub of pencil; at the edge, the dial of an army radio set glowing amber. Close and intimate, the "
     "dark all around."),
]
# a scene rerolled: a new seed, so --force doesn't draw the same picture again (14 Oct: air_2)
REROLL = {"air_2": 10}
jobs = []
for n, (out, style, what) in enumerate(SCENES):
    jobs.append({"out": "art/intro/%s.png" % out, "width": 640, "height": 360, "no_background": False,
                 "seed": 97100 + n + REROLL.get(out, 0),
                 "style_image": "res://art/places/%s.png" % style, "description": what + " " + TAIL,
                 "_where": "on the air, scene %d" % (n + 1), "endpoint": "generate-image-v2", "single": True,
                 "style_options": STYLE})
json.dump({"_readme": ["FIAT ON THE AIR (14 Oct, docs/design/on_the_air.md): three scenes, 640x360, shown at 3x drifting. art/intro/.",
                       "Run: godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_air_manifest.json   (++ --dry-run; one wrong: ++ --only <name> ++ --force)."],
           "jobs": jobs}, open("tools/pixellab_air_manifest.json", "w"), indent=1)
print("%d jobs" % len(jobs))
