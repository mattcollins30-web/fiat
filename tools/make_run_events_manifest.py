#!/usr/bin/env python3
"""The run events' art (BUILD46-E, 2 Nov; docs/design/run_events.md "Art"): the figures and props a run event puts in
the fight's scene, in the fight kit's style. Writes two manifests:

  tools/pixellab_run_events_test_manifest.json  - four jobs first (Matt's rule: the slice reads with test art before
                                                  credits go on the set): a lean dog standing, the Estate's rival crew
                                                  standing, the Town's person on the ground, a safe shut
  tools/pixellab_run_events_manifest.json       - the whole set (the test's four are the same jobs: skipped once on disk)

What's in it (event_prop.gd finds each by name, art/events/<name>.png, and draws today's shapes where one isn't there):
  - the dogs standing / firing / going down (dog_lean: the Outskirts and the Estate; dog_big: the Town and the City),
    192x128, and a rival crew a zone standing (crew_<zone>_stand, 128x192 like the gang figures; in the fight the gang's
    own figures stand in for them), drawn at the gang's slots' scale, their feet on the slot;
  - people, two poses: the one in need a zone, on the ground (person_<zone>_down: trapped or hurt) and up (_up: freed);
    the Scrap man and the Vagabond at their barrows (<who>_barrow);
  - props, shut and open: the locked things (cabinet, shutter, van, safe), a dangerous place (hazard), a stash bag, a
    body (searched: _open), a wreck (stripped), a radio (heard).

Every job references only art already on disk (python3 tools/art_lint.py must say CLEAN): the gang's own figures for the
style and the pose, the crates for the props' look. Seeds 140000-140099 (one a job; none shared with any manifest).

Run (once the slice reads with test art and Matt has agreed it): python3 tools/make_run_events_manifest.py, then
python3 tools/art_lint.py tools/pixellab_run_events_test_manifest.json tools/pixellab_run_events_manifest.json, then the
art.flag handoff (docs/art/pixellab_lessons.md): the test first, the set after.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}
TAIL = ("Realistic painted pixel art, soft overcast light, muted cool northern palette, worn and lived-in, post-collapse "
        "Britain on a grey day; no black outlines, not anime, not a cartoon, not glossy; no text, no logos, no lettering, "
        "badges or numbers on anything.")
ALONE = ("One person alone, full body head to feet, facing the viewer, centred, filling the frame top to bottom, plain dark "
         "neutral background.")
LYING = ("One person alone, the whole body in frame, lying across the frame from side to side, centred, plain dark neutral "
         "background.")
DOG = ("One dog alone, the whole animal in frame from nose to tail, side-on across the frame, centred, plain dark neutral "
       "background.")
THING = ("One thing alone, the whole of it in frame, seen from the front and a little above at the eye level of someone "
         "crouched behind cover, centred, nothing else around it: no floor, wall, ground or sky, a plain dark neutral "
         "background.")
ZONES = ["the_outskirts", "the_estate", "the_town", "the_city"]
FIG_W, FIG_H = 128, 192        # the gang figures' (art/fight/gang_<zone>_<a|b>_<pose>.png)
SEED0 = 140000

POSE = {
    "stand": "standing ready, weapon held low across the body",
    "fire": "aiming straight at the viewer, the weapon held firmly in both hands, a bright muzzle flash",
    "down": "hit and falling backwards, arms flung out, what they held dropping",
}
# a rival crew a zone: other scavengers, not the zone's gang (Words.EV["crew"]: "off the lane", "hoods up between the
# blocks", "through the precinct", "kitted out")
CREW = {
    "the_outskirts": "a scavenger from a rival crew off the lanes: a waxed jacket gone shiny at the elbows, a plain wool hat, wellies, a sack over one shoulder, a single-barrel shotgun",
    "the_estate": "a scavenger from a rival estate crew: a plain red zip-up tracksuit top done up to the chin, a plain grey beanie, a bright yellow cloth tied round one arm as the crew's mark, plain cargo trousers, a crowbar through the belt, a sawn-off shotgun",
    "the_town": "a scavenger from a rival town crew: a plain grey workman's fleece, a plain dark beanie, a utility belt of pouches, work boots, an old revolver",
    "the_city": "a scavenger from a rival city crew, well kitted out: a plain dark plate carrier with no badges over a plain jacket, a plain balaclava rolled up, knee pads, a short carbine",
}
# the one in need a zone (Data.EVENT_POOLS.need_who's leanings)
PERSON = {
    "the_outskirts": "a farmhand in a plain worn checked shirt and a padded gilet, muddy jeans and wellies",
    "the_estate": "a woman from the flats in a plain dark puffer jacket, plain leggings and trainers, hair scraped back",
    "the_town": "a security guard in a plain black jumper with no badges, dark trousers and work boots",
    "the_city": "a nurse in plain dark blue scrubs with no badges and a plain cardigan, flat shoes",
}
DOGS = {
    "dog_lean": ("a thin feral farm dog, a lean lurcher cross with a rough brindle coat and its ribs showing, a frayed collar", "the_outskirts"),
    "dog_big": ("a big feral dog, a heavy mastiff cross with a short fawn coat, scarred muzzle, a chain collar", "the_city"),
}
DOG_POSE = {
    "stand": "standing square, head low, hackles up, teeth bared",
    "fire": "lunging to the left mid-leap, side-on, jaws wide open",
    "down": "hit and collapsing onto its side, legs folding",
}
TRADER = {
    "scrap_man": "the Scrap man, an old rag-and-bone man in a flat cap and a long brown coat over a plain jumper, standing behind a wooden market barrow piled with plain scrap metal, copper pipe and old radiators, two big spoked wheels",
    "vagabond": "the Vagabond, a weathered wandering trader with a long grey beard, a plain wide-brimmed hat and layers of patched coats, a big plain rucksack on his back, standing behind a wooden handcart piled with plain unlabelled tins, coils of cable and a few odd boots and jackets, two big spoked wheels",
}
# props: (name, size, the crate it takes its look from, shut, open)
PROPS = [
    ("cabinet", (128, 160), "filing", "a plain grey steel cabinet on its own with two doors shut and a heavy padlock through the handles, no labels",
     "a plain grey steel cabinet on its own with both doors hanging open, empty steel shelves inside, a broken padlock hanging from one handle, no labels"),
    ("shutter", (160, 160), "military", "a plain steel roller shutter on its own, rolled all the way down, dented, a padlock at its bottom edge, no lettering, no graffiti",
     "a plain steel roller shutter on its own, forced half up, its bottom edge bent, darkness behind it, no lettering, no graffiti"),
    ("van", (240, 160), "toolbox", "a plain white works van with no lettering and no number plate, side-on, its sliding side door shut and padlocked, rust at the arches",
     "a plain white works van with no lettering and no number plate, side-on, its sliding side door wrenched open, the back dark and empty, rust at the arches"),
    ("safe", (128, 128), "safe", "a heavy dark grey steel office safe on its own, its thick door shut, a plain dial with no numbers and a chrome handle, scuffed and pry-marked",
     "a heavy dark grey steel office safe on its own, its thick door hanging open, empty shelves inside, a plain dial with no numbers, scuffed and pry-marked"),
    ("hazard", (192, 128), "cardboard", "a broken floorboard section on its own, a square of old wooden boards splintered through the middle into a jagged hole, black water showing through it",
     "a broken floorboard section on its own, a square of old wooden boards splintered through the middle into a jagged hole, a scaffold plank laid across the hole"),
    ("stash_bag", (128, 96), "cardboard", "a plain dark unbranded holdall sitting on its own, zipped shut, bulging, a thin wire running from its handle",
     "a plain dark unbranded holdall sitting on its own, unzipped and gaping open, its insides pulled half out, empty"),
    ("body", (192, 96), "military", "someone lying dead face down, still and grey, in a plain worn coat and boots, a plain rucksack still on their back; nothing gratuitous, no blood",
     "someone lying dead face down, still and grey, in a plain worn coat and boots, their plain rucksack beside them opened and emptied, pockets turned out; nothing gratuitous, no blood"),
    ("wreck", (240, 160), "toolbox", "a burnt-out car, side-on, scorched bare metal and rust, its windows gone, no wheels, no number plate",
     "a burnt-out car, side-on, scorched bare metal and rust, stripped: its doors, bonnet and panels cut away, the bare frame showing, no number plate"),
    ("radio", (128, 96), "toolbox", "a battered old portable radio on its own, its plain dial blank with no numbers, its telescopic aerial down, switched off",
     "a battered old portable radio on its own, its plain dial blank with no numbers, its telescopic aerial up and its little dial light glowing amber"),
]

jobs = []


def job(out, w, h, seed, words, style, refs=None, where=""):
    j = {"out": "art/events/%s.png" % out, "width": w, "height": h, "no_background": True, "seed": seed,
         "endpoint": "generate-image-v2", "single": True, "style_options": STYLE, "style_image": style,
         "description": words + " " + TAIL, "_where": where}
    if refs:
        j["reference_images"] = refs
    jobs.append(j)


seed = SEED0
# rival crews: styled on the zone's gang (the fight kit's figures), framed on the gang's own pose - standing only (fix 46,
# E3: in the fight the gang's own figures stand in for them, so a fire or down picture would never be drawn)
for z in ZONES:
    for pose in ("stand",):
        job("crew_%s_%s" % (z, pose), FIG_W, FIG_H, seed,
            "A different person from the reference image, in the same pose and framing: %s, %s. %s" % (CREW[z], POSE[pose], ALONE),
            "res://art/fight/gang_%s_a_stand.png" % z, ["res://art/fight/gang_%s_a_%s.png" % (z, pose)],
            "a rival crew, %s: %s (event_prop.gd; falls back to the zone's gang art)" % (z, pose))
        seed += 1
# dogs: styled on the zone's gang art for the palette only
for k, (desc, z) in DOGS.items():
    for pose in ("stand", "fire", "down"):
        job("%s_%s" % (k, pose), FIG_H, FIG_W, seed,
            "%s, %s. %s Only the palette, light and painting style of the style image, not its subject." % (desc[0].upper() + desc[1:], DOG_POSE[pose], DOG),
            "res://art/fight/gang_%s_b_stand.png" % z, None, "the dogs (%s): %s, the fire pose their lunge" % (k, pose))
        seed += 1
# the one in need: on the ground (trapped or hurt) and freed
for z in ZONES:
    job("person_%s_down" % z, FIG_H, FIG_W, seed,
        "A frightened person on the ground, %s, lying on their side propped on one elbow, one leg caught and held down, reaching out a hand for help. %s Only the palette, light and painting style of the style image, not its subject." % (PERSON[z], LYING),
        "res://art/fight/gang_%s_b_stand.png" % z, None, "someone in need, %s: on the ground, trapped or hurt" % z)
    seed += 1
    job("person_%s_up" % z, FIG_W, FIG_H, seed,
        "A tired person just pulled free, %s, standing up stiffly, one hand on a sore shoulder, dusty and shaken. %s Only the palette, light and painting style of the style image, not its subject." % (PERSON[z], ALONE),
        "res://art/fight/gang_%s_b_stand.png" % z, None, "someone in need, %s: freed, up on their feet" % z)
    seed += 1
# the traders at their barrows
for k, desc in TRADER.items():
    job("%s_barrow" % k, 192, 192, seed,
        "%s, facing the viewer, the whole of him and his barrow in frame, centred, plain dark neutral background. Only the palette, light and painting style of the style image, not its subject." % (desc[0].upper() + desc[1:]),
        "res://art/fight/gang_the_town_b_stand.png", None, "a trader: %s at his barrow" % k)
    seed += 1
# props, shut and open
for name, (w, h), crate, shut, opened in PROPS:
    for state, words in (("shut", shut), ("open", opened)):
        job("%s_%s" % (name, state), w, h, seed,
            "A realistic painted pixel-art view of %s. %s Only the palette, light and painting style of the style image, not its subject." % (words, THING),
            "res://art/crates/%s.png" % crate, None, "a run event's prop: %s, %s" % (name, state))
        seed += 1

TEST = ["art/events/dog_lean_stand.png", "art/events/crew_the_estate_stand.png", "art/events/person_the_town_down.png", "art/events/safe_shut.png"]
COST = 0.08


def write(path, js, readme):
    with open(os.path.join(ROOT, "tools", path), "w", encoding="utf-8") as f:
        json.dump({"_readme": readme, "jobs": js}, f, indent=1, ensure_ascii=False)
        f.write("\n")


test = [j for j in jobs if j["out"] in TEST]
assert len(test) == len(TEST)
common = [
    "Every job is generate-image-v2 at 65k px or under: $%.2f a job (docs/art/pixellab_lessons.md)." % COST,
    "event_prop.gd finds each by name (art/events/<name>.png) and draws the slice's shapes where one isn't on disk.",
    "Regenerate with python3 tools/make_run_events_manifest.py; check with python3 tools/art_lint.py.",
]
write("pixellab_run_events_test_manifest.json", test, [
    "FIAT RUN EVENTS, THE TEST (BUILD46-E, 2 Nov): %d jobs, $%.2f - a lean dog standing, the Estate's rival crew standing, the Town's person on the ground, a safe shut. Judge these in the fight's scene before the set." % (len(test), len(test) * COST),
    "Run: tools\\art.bat run_events_test (the dry run first, then it asks)."] + common)
write("pixellab_run_events_manifest.json", jobs, [
    "FIAT RUN EVENTS (BUILD46-E, 2 Nov; docs/design/run_events.md): %d jobs, $%.2f - a rival crew a zone standing, two dogs standing, firing and going down; the one in need a zone, down and up; the Scrap man and the Vagabond at their barrows; nine props shut and open. The test's four are the same jobs (skipped once on disk)." % (len(jobs), len(jobs) * COST),
    "Run: tools\\art.bat run_events (the dry run first, then it asks)."] + common)
print("%d jobs ($%.2f), the test %d ($%.2f)" % (len(jobs), len(jobs) * COST, len(test), len(test) * COST))
