"""The opening's pictures (14 Oct, docs/design/intro.md): six scenes, 2028 to now, one picture each, 640x360 (shown at 3x),
the house style. Writes tools/pixellab_intro_manifest.json; out to art/intro/.
Run: python tools/make_intro_manifest.py, then
  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_intro_manifest.json"""
import json

TAIL = ("Realistic painted pixel art, wide cinematic composition with room to pan, soft light, muted cool northern "
        "palette, worn and lived-in, Britain; no black outlines, not anime, not a cartoon, not glossy; no text, no "
        "logos, no readable writing.")
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}
SCENES = [
    ("scene_1", "the_estate", "Inside a small British council flat's front room at night, lit only by a television. On the "
     "screen, a city burning far away, smoke and tracer fire. On the coffee table in front of it, a long supermarket "
     "receipt and an energy bill. A sofa with a blanket, net curtains, a radiator. Nobody in the room. Ordinary, quiet, "
     "still comfortable - the last normal evening."),
    ("scene_2", "ransacked_streets", "A British terraced street in winter at dusk, frost on the cars, every window dark - "
     "no heating, no lights. A long queue of people in coats outside a church hall with a hand-written food bank sign "
     "that can't be read. A petrol station's price board glowing at the end of the street. Beyond the rooftops, a "
     "reservoir with its banks showing, half empty."),
    ("scene_3", "the_city", "A vast grey windowless data centre on the edge of a British town, rows of cooling units "
     "humming, pylons marching to it across the fields, a shrunken reservoir beside it with cracked mud banks. In the "
     "foreground, a closed office block with its lights still on and nobody inside, a car park with three cars."),
    ("scene_4", "the_bank", "A British high street by day, overcast. A long anxious queue outside a shuttered bank with "
     "its steel shutters down. A cash machine in the wall with its screen dark. Banknotes blowing in the gutter, "
     "a dropped wallet, a police officer standing apart, unsure. Shops with sale signs that can't be read."),
    ("scene_5", "the_services", "An empty British motorway at dusk, no cars moving in either direction, the overhead "
     "gantry signs dark. A jack-knifed lorry across two lanes, its trailer doors open and empty. On the slip road, a "
     "rough checkpoint of shopping trolleys, pallets and a burnt-out car, a small fire, two hooded figures watching. "
     "Town lights in the distance going out one by one."),
    ("scene_6", "the_caravan", "A makeshift camp at night on waste ground at the edge of a dead British town: two old "
     "vans and a horsebox, a brazier burning, a fence of stacked pallets and corrugated sheet, a tarpaulin on poles, "
     "jerry cans and crates. One figure stands at the gap in the fence, back to the viewer, looking out at the dark town "
     "and its broken streetlights. Firelight warm against the cold blue night."),
]
jobs = []
for n, (out, style, what) in enumerate(SCENES):
    jobs.append({"out": "art/intro/%s.png" % out, "width": 640, "height": 360, "no_background": False, "seed": 97000 + n,
                 "style_image": "res://art/places/%s.png" % style, "description": what + " " + TAIL,
                 "_where": "the opening, scene %d" % (n + 1), "endpoint": "generate-image-v2", "single": True,
                 "style_options": STYLE})
json.dump({"_readme": ["FIAT THE OPENING (14 Oct, docs/design/intro.md): six scenes, 640x360, shown at 3x drifting. art/intro/.",
                       "Run: godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_intro_manifest.json   (++ --dry-run; one wrong: ++ --only <name> ++ --force)."],
           "jobs": jobs}, open("tools/pixellab_intro_manifest.json", "w"), indent=1)
print("%d jobs" % len(jobs))
