"""The expeditions' pictures (29 Oct, docs/design/trips.md; the list: the build's tr_art.md): the six far places, the
eighteen hands' faces, the Bunkhouse's three room-card pictures and its rail icon, and seven cargo icons.

  python3 tools/make_expeditions_manifest.py
    -> tools/pixellab_expeditions_manifest.json        (every job, 35)
    -> tools/pixellab_expeditions_test_manifest.json   (the test: five of the same jobs, one of each kind)

Where the game finds each (nothing to wire for the far places and the faces):
  art/places/far_<key>.png    688 x 296, UI.place_texture("far <key>") (the Expeditions card crops it from the centre;
                              the Map's far edge would take the full width). Styled on the zones' panoramas.
  art/hands/<trade>_<look>.png 128 x 128 portraits, HandCell.face (look 0 Common/Uncommon, 1 Rare/Epic, 2 Legendary),
                              in the Fence's portrait style (art/people/fence.png) like every face in the game.
  art/room_boxes/bunkhouse_<n>.png 384 x 96, the room boxes' template (make_room_box_manifest), styled on the Yard's
                              header (the Bunkhouse stands on the Pitch). Wiring when it gets a room: ROOM_INTROS + STRIPS.
  art/rail/bunkhouse.png      64 x 64, the rail glyphs' template (make_campaign_manifest: a painted still-life object on
                              the item references, not a line pictogram - that is what art/rail/*.png are). Wiring: a
                              GLYPH_OF row when it gets a rail button.
  art/items/<key>.png         64 x 64 cargo icons, the item template; wired in the follow-up beside the cargo words.

Checked against docs/art/pixellab_lessons.md: the far places are described, never named (a named place comes back with
its name on a sign); every van, vest, cap, sack, box and drum is plain / unprinted; the Bunkhouse's job cards blank (no
"hand-written"); the cut-out icons name no setting; seeds of their own (123xxx)."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_item_manifests as items  # noqa: E402  (TAIL, REFS)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}

# -- the far places (seed 123000+) --------------------------------------------------------------------------------
PLACE_TAIL = (" Muted blue-grey and slate palette with sparse warm orange lights, low overcast cloud, dusk. Quiet, not busy; "
              "no people in the foreground. The subject sits in the middle of the frame (a card crops a small window from "
              "the centre), flat even detail side to side, darker at the bottom edge. Only the palette, light and painting "
              "style of the style image, not its subject. The painting fills the whole canvas to all four edges, no border, "
              "frame or margin. No text, no signs, no lettering, no numbers anywhere.")
FAR = [
    # key, style (a zone panorama), the look (tr_art.md), described, not named
    ("swansea", "the_city", "a tall hospital block with every window dark standing in the very centre of the frame, a wet "
                            "seafront promenade curving in front of it along a wide flat grey bay, empty railings and lamp "
                            "posts unlit on both sides"),
    ("bristol", "the_city", "the approach road to a long suspension bridge over a deep river gorge, blocked by a wall of "
                            "plain rusted shipping containers and a red-and-white barrier arm, floodlights on poles and coils "
                            "of razor wire, the bridge's towers beyond"),
    ("salisbury", "the_outskirts", "open rolling chalk downland under a huge pale sky, a long wire army-range fence with "
                                   "blank plates on its posts, a burnt-out armoured vehicle on a white chalk track, a "
                                   "small clump of trees on the skyline"),
    ("birmingham", "the_city", "a tangle of concrete motorway flyovers looping over each other above rows of long grey "
                               "distribution sheds, their loading bays shuttered, plain unprinted walls, orange sodium "
                               "light on the slip roads"),
    ("liverpool", "the_city", "a long row of old brick dock warehouses and tall cranes along a wide grey river, stacks of "
                              "plain containers on the quay, a ferry rusting at its berth, low cloud over the water"),
    ("london", "the_city", "a great city's river skyline seen from far off across the water, many tall towers unlit, one "
                           "of them smoking, a long bridge with a gap blown out of its middle, nothing moving"),
]

# -- the hands' faces (seed 123100+) -----------------------------------------------------------------------------
FACE_TAIL = (" Looking just past the viewer. Post-collapse Britain, grey light. One person centred, filling the frame, a "
             "clear face that still reads when shown very small. No text, no border, no lettering or badges, plain dark "
             "background.")
FACES = [
    ("porter", 0, "a tired young man under a huge rucksack strap, a plain hi-vis vest with no lettering, a woolly hat"),
    ("porter", 1, "a broad woman with a frame pack and a cargo net over one shoulder, work gloves"),
    ("porter", 2, "a grizzled old docker with a sack truck handle over his shoulder, a scarred, patient face"),
    ("medic", 0, "a teenage first-aider in a too-big green jacket, a bum bag of plasters"),
    ("medic", 1, "a nurse in faded scrubs under a parka, a stethoscope round the neck and a head torch"),
    ("medic", 2, "a field surgeon with a cropped grey head, a plain faded white armband from an old army uniform and a steady stare"),
    ("scout", 0, "a wiry kid in a hoodie with cheap binoculars round his neck"),
    ("scout", 1, "a rambler in a waxed jacket with a clear plastic map case on a cord, the map inside only green and brown "
                 "shapes, and a walking pole"),
    ("scout", 2, "a gaunt ex-soldier in a ghillie hood, a rangefinder pushed up on the brow"),
    ("cracker", 0, "a lad with a crowbar over his shoulder and a split lip, safety goggles on his forehead"),
    ("cracker", 1, "a locksmith in a cardigan with a ring of lock picks and a stethoscope"),
    ("cracker", 2, "an old safe-breaker in a flat cap, a jeweller's loupe in one eye, a cigarette behind the ear"),
    ("driver", 0, "a delivery driver in a plain polo shirt with a pale patch where a badge was unpicked, keys on a plain lanyard"),
    ("driver", 1, "a lorry driver with a beard and a plain trucker's cap, a CB radio handset clipped to the collar"),
    ("driver", 2, "a former getaway driver, a leather jacket, driving gloves, a calm half-smile"),
    ("quartermaster", 0, "a warehouse picker with a roll of pallet wrap and a pencil behind the ear"),
    ("quartermaster", 1, "a stores clerk with a clipboard of blank paper and a tape gun, reading glasses on a cord"),
    ("quartermaster", 2, "a retired regimental storeman, a pressed shirt, a closed plain ledger under his arm, thin and "
                         "bald with a neat white moustache"),     # not the Quartermaster himself (art/people/the_quartermaster.png)
]
TRADE_WORDS = {"porter": "who carries for an expedition crew", "medic": "who patches up an expedition crew",
               "scout": "who goes ahead of an expedition crew", "cracker": "who opens locked things for an expedition crew",
               "driver": "who drives an expedition crew's van", "quartermaster": "who loads an expedition crew's van"}

# -- the Bunkhouse (seed 123200+) ---------------------------------------------------------------------------------
BOX_LOOK = ("Muted blue-grey palette, dark navy shadows, overcast evening light, one or two warm orange lamps. A wide, low "
            "strip: the subject sits across the middle, filling the width, with nothing important in the top or bottom eighth "
            "(the strip is cropped to fit its box). Only the palette, light and painting style of the style image, not its "
            "view or its subject. One continuous scene edge to edge, no border, no frame. No people unless the brief names "
            "them, no text, no readable signage, numbers or lettering.")
BOXES = [
    "rows of metal bunk beds in a portakabin, plain kit bags hung on hooks, a strip light on the ceiling",
    "a cork board of blank cream cards pinned in rows, nothing written on them, a road atlas pinned open showing only "
    "coloured roads and no names, plain mugs on a trestle table below",                     # LESSON: "hand-written job cards"
    "a yard at dawn: a plain white van with no number plate and no lettering, its back doors open and loaded, three small "
    "figures of a crew climbing in, seen from behind",
]
RAIL = ("a small steel-framed bunk bed, two thin mattresses and a folded grey army blanket on the top bunk, seen from the "
        "front at a slight angle")

# -- the cargo icons (seed 123300+) ---------------------------------------------------------------------------------
CARGO = [
    ("paving", "a stack of three grey paving slabs, one chipped at the corner, on a scrap of broken pallet"),
    ("glass", "two panes of glass leaning together, pale blue reflections, a cross of tape across one"),
    ("ledgers", "a pile of bound ledgers with plain red spines, no lettering or numbers, tied with string"),
    ("cable_drums", "a wooden cable drum wound with black cable, side on, " + "plain, unprinted, no stencil, no numbers"),
    ("army_kit", "a folded olive webbing set and a canteen strapped together, no name tape or lettering"),
    ("fuses", "a handful of white ceramic cartridge fuses spilling from a small plain cardboard box, unprinted, no numbers"),
    ("meds_cargo", "a small open plain unprinted cardboard box, no markings on it, of mixed medical supplies: plain unprinted foil blister packs, a bandage roll "
                   "and a small brown bottle with no label, no red cross, no lettering"),
]

# Six of the seven already have jobs (same names) in the optional, never-run pixellab_order_glyphs_manifest.json (19 Oct,
# make_outstanding_manifest.py: the rebuild materials for the Radio's town list). Two different jobs can't write one
# file (art_lint), so by default this manifest carries those jobs as they are (same seed and words: one job, not a
# clash) and the icon serves both screens. CARGO above is the lesson-checked rewrite of the six (plain/unprinted, and
# tr_art.md's looks: two panes, webbing and a canteen): to use it, set USE_ORDER_GLYPHS = False AND take the six jobs
# out of make_outstanding_manifest.py / pixellab_order_glyphs_manifest.json in the same change (Matt's call).
USE_ORDER_GLYPHS = False   # 29 Oct, Matt: "switch to the rewrite" - the six left the order glyphs manifest
ORDER_GLYPHS = os.path.join(ROOT, "tools", "pixellab_order_glyphs_manifest.json")

TEST = ["art/places/far_swansea.png", "art/hands/porter_0.png", "art/hands/cracker_2.png",
        "art/room_boxes/bunkhouse_2.png", "art/rail/bunkhouse.png", "art/items/meds_cargo.png"]


def still(out, what, seed, where, view="seen from above at a slight angle"):
    return {"out": out, "endpoint": "generate-image-v2",
            "description": "A realistic painted pixel-art still-life of %s, %s, filling the frame, worn and used." % (what, view)
                           + items.TAIL + " No floor, wall, ground or sky around it.",
            "width": 64, "height": 64, "no_background": True, "seed": seed, "single": True,
            "style_image": items.REFS[seed % len(items.REFS)], "style_options": STYLE, "_where": where}


def main():
    jobs = []
    for i, (key, style, look) in enumerate(FAR):
        jobs.append({"out": "art/places/far_%s.png" % key, "endpoint": "generate-image-v2",
                     "description": "Pixel art, wide side-on panorama, far off and still: " + look + "." + PLACE_TAIL,
                     "width": 688, "height": 296, "no_background": False, "seed": 123000 + i + (1000 if key == "swansea" else 0), "single": True,  # swansea rerolled 29 Oct (hospital off-centre)
                     "style_image": "res://art/places/%s.png" % style, "style_options": STYLE,
                     "_where": "the far place %s: the Expeditions card (centre crop) and the Map's far edge" % key})
    for i, (trade, look, who) in enumerate(FACES):
        jobs.append({"out": "art/hands/%s_%d.png" % (trade, look), "endpoint": "generate-image-v2",
                     "description": "A realistic painted pixel-art portrait, head and shoulders, of %s, %s." % (who, TRADE_WORDS[trade])
                                    + FACE_TAIL,
                     "width": 128, "height": 128, "no_background": False, "seed": 123100 + i, "single": True,
                     "style_image": "res://art/people/fence.png", "style_options": STYLE,
                     "_where": "a %s hand's face, look %d (%s)" % (trade, look, ["Common/Uncommon", "Rare/Epic", "Legendary"][look])})
    for i, scene in enumerate(BOXES):
        jobs.append({"out": "art/room_boxes/bunkhouse_%d.png" % (i + 1), "endpoint": "generate-image-v2",
                     "width": 384, "height": 96, "no_background": False, "single": True, "seed": 123200 + i,
                     "style_options": STYLE, "style_image": "res://art/places/the_yard.png",
                     "description": "Pixel art, a wide close view: " + scene + ". " + BOX_LOOK,
                     "_where": "the Bunkhouse room card's box %d" % (i + 1)})
    jobs.append(still("art/rail/bunkhouse.png", RAIL, 123210, "the rail: the Bunkhouse (when it gets a button)",
                      view="a single bold silhouette that still reads at a quarter of this size"))
    shared = {}
    if USE_ORDER_GLYPHS:
        with open(ORDER_GLYPHS, encoding="utf-8") as f:
            shared = {j["out"]: j for j in json.load(f)["jobs"]}
    for i, (key, what) in enumerate(CARGO):
        out = "art/items/%s.png" % key
        if out in shared:
            j = dict(shared[out])
            j["_where"] = "cargo icon: %s (the order glyphs' job, as it is)" % key
            jobs.append(j)
        else:
            jobs.append(still(out, what, 123300 + i, "cargo icon: %s" % key))
    for j in jobs:
        assert j["out"] in TEST or not os.path.exists(os.path.join(ROOT, j["out"])), "already on disk: %s" % j["out"]
    readme = [
        "FIAT EXPEDITIONS (29 Oct): %d jobs - six far places (688x296, $0.15 each), eighteen hands' faces (128x128), the "
        "Bunkhouse's three room-card strips (384x96) and its rail icon (64x64), seven cargo icons (64x64) - $0.08 each "
        "but the places. One file a job, straight to its name; the far places and the faces are found by name." % len(jobs),
        "Run the test first: tools/pixellab_expeditions_test_manifest.json. Then this, ++ --parallel 3.",
        "Regenerate with python3 tools/make_expeditions_manifest.py; check with python3 tools/art_lint.py.",
    ]
    tools = os.path.join(ROOT, "tools")
    with open(os.path.join(tools, "pixellab_expeditions_manifest.json"), "w", encoding="utf-8") as f:
        json.dump({"_readme": readme, "jobs": jobs}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    test = [next(j for j in jobs if j["out"] == o) for o in TEST]
    with open(os.path.join(tools, "pixellab_expeditions_test_manifest.json"), "w", encoding="utf-8") as f:
        json.dump({"_readme": ["FIAT EXPEDITIONS - THE TEST (29 Oct): %d of the full manifest's jobs (same out, seed, "
                               "words), one of each kind: a far place, two faces (the youngest and the oldest look), a "
                               "Bunkhouse strip (the blank cards), the rail icon, a cargo icon. A kept picture is skipped "
                               "by the full run." % len(test),
                               "Regenerate with python3 tools/make_expeditions_manifest.py."], "jobs": test},
                  f, indent=1, ensure_ascii=False)
        f.write("\n")
    print("expeditions: %d jobs (places %d, faces %d, boxes %d, rail 1, cargo %d); test %d"
          % (len(jobs), len(FAR), len(FACES), len(BOXES), len(CARGO), len(test)))


if __name__ == "__main__":
    main()
