"""The art still outstanding after the 19 Oct list (Matt: "lets get the art manifest for everything outstanding - the
map looks great but it needs drawn art either way"). Three manifests:

  python3 tools/make_outstanding_manifest.py
    -> tools/pixellab_outstanding_test_manifest.json   (4: the Map's Outskirts - its ground and its three sites)
    -> tools/pixellab_outstanding_manifest.json        (the rest: the Map, the order's three heads and places)
    -> tools/pixellab_order_glyphs_manifest.json       (9, optional: the order's three keys, six materials - copper wire has its item's picture)

  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_outstanding_test_manifest.json
  (++ --dry-run to list; ++ --only <name> ++ --force to reroll)

Test first: the Outskirts' ground and its three site pictures go in the game before the other zones are made.
The room cards' strips have their own manifests already (tools/make_room_box_manifest.py: the Map's three as the
test, then 24).

Nothing live is touched: every file here is new (art/map/, and names art/items, art/people and art/fight don't have).

The Map: each zone's ground is its own picture, the game clips it to the zone's shape (map_view.gd ZONE_SHAPES), so
the painting can never drift off the pins; the roads, the river, the pins, the names and the hatch stay drawn on top.
Each zone's picture is its bounding box at half size (drawn x2 on the 1018 x 844 map). A site's picture sits under
its pin (64 x 64, drawn at 64: no uneven pixels). art/reference/map_layout_<zone>.png is the drawn map's shapes cut
to each zone's box (the river and the roads where they cross it), for its layout.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}

GROUND = ("Pixel art, seen straight down from directly above like an aerial photograph turned into a painted map: %s. "
          "The whole frame filled edge to edge with ground, no horizon, no sky, no border, no frame, no vignette. "
          "Only the palette, light and painting style of the style image, not its view: no horizon, no sky, nothing at "
          "eye level. "
          "Muted blue-grey and slate palette with %s, dusk light, a few warm orange lights; quiet and empty, no people, "
          "no vehicles moving, no text, no labels, no readable signs or numbers. Even detail all over: the picture is "
          "cut to an irregular shape and drawn under markers, so nothing in it should be the only thing worth looking at.")

SITE = ("Pixel art, a small map vignette seen from above at a steep angle, as on a hand-painted town map: %s. One place "
        "only, centred, about two thirds of the frame, on a transparent background, no ground beyond its own edge, no "
        "border. Only the palette, light and painting style of the style image, not its view: no horizon, no sky, "
        "nothing at eye level. Muted blue-grey palette with %s, dusk light, one or two warm orange lights; no people, no text, no "
        "readable signs or numbers. It must read at this size: a single strong shape.")

# zone key, Data.ZONES name, bounding box of its ZONE_SHAPES points in the drawing's 1000 x 844 space, the ground,
# its tint, the style picture
ZONES = [
    ["outskirts", "The Outskirts", (0, 520, 380, 844),
     "farmland on the edge of a northern English town: small fields with hedgerows and dry-stone walls, a lane between "
     "them, a copse, allotment plots with sheds, a farmyard's roofs, ploughed earth and overgrown grass", "muted greens and browns",
     "the_outskirts"],
    ["estate", "The Estate", (0, 170, 420, 560),
     "a 1960s council estate and its high street: rows of terraced roofs, three grey tower blocks' flat roofs, car "
     "parks, a parade of shop roofs, a retail park's big flat sheds and their car park, scrubby greens between", "slate greys",
     "the_estate"],
    ["town", "The Town", (360, 110, 720, 560),
     "an old town centre inside a ring road: dense Victorian roofs, a church, a shopping centre's long glass roof, a "
     "bank's stone block, a fairground's rides and a big wheel on a park, narrow streets", "brick reds and browns",
     "the_town"],
    ["city", "The City", (660, 40, 1000, 640),
     "the edge of a big city past the river: a motorway services and its car park, a hospital's tower and wings, an "
     "army barracks' parade ground and huts behind a fence, warehouses, railway lines, cranes", "cold blues",
     "the_city"],
]

# Data.TIERS's order: [the site, its zone key, what it looks like from above]
SITES = [
    ["The Allotments", "outskirts", "a patchwork of allotment plots with sheds, a greenhouse and water butts, a path down the middle"],
    ["The Garden Centre", "outskirts", "a garden centre: a long glasshouse, rows of plant tables, a car park with one van"],
    ["Top Farm", "outskirts", "a farmyard: a stone farmhouse, a big barn with a curved roof, a muddy yard, a tractor"],
    ["Ransacked Streets", "estate", "a corner of terraced streets, back yards, a burnt-out car and bins in an alley"],
    ["The Parade", "estate", "a short parade of shops under a concrete canopy, flats above, a bus shelter"],
    ["The Retail Park", "estate", "a retail park: three big flat-roofed sheds round a car park, trolley shelters"],
    ["The Pleasure Park", "town", "a small fairground in a park: a big wheel, a carousel's round roof, a helter-skelter"],
    ["Shopping Centre", "town", "a shopping centre's long glass roof and its multi-storey car park"],
    ["The Bank", "town", "a stone bank on a corner, a columned front, a clock over the door, a strongroom's vents on the roof"],
    ["The Services", "city", "motorway services: a flat canopy over petrol pumps, a low building, lorries parked in rows"],
    ["The Hospital", "city", "a big hospital: a tower block, wings off it, a painted helipad circle, ambulance bays"],
    ["The Barracks", "city", "an army barracks: a parade ground, rows of huts, a watchtower, a chain-link fence round it"],
]

PORTRAIT = ("A realistic painted pixel-art portrait, head and shoulders, of %s. Looking just past the viewer. Post-collapse "
            "Britain, overcast light. One person centred, filling the frame, no text, no border, plain dark background.")
FIGURE = ("%s, %s. One person alone, full body head to feet, facing the viewer, centred, filling the frame top to bottom, "
          "plain dark neutral background. Realistic painted pixel art, soft overcast light, muted cool northern palette, "
          "worn and lived-in, post-collapse Britain on a grey day; no black outlines, not anime, not a cartoon, not "
          "glossy; no text, no logos.")
POSES = [["stand", "standing", ""], ["fire", "firing at you", "The same person as the reference image: "], ["down", "beaten, going down", "The same person as the reference image: "]]
OBJECT = ("A realistic painted pixel-art still-life of %s. One object centred and filling the frame, soft directional "
          "overcast daylight, natural material rendering with fine detail and painterly shading; no black outlines, no "
          "flat cel shading, not anime, not a cartoon, not a glossy video-game item; the look of a real object "
          "photographed on a grey day in a country that has run out of money. Muted cool northern palette, worn and "
          "repaired, nothing new. Nothing else in the frame, no hands, no person, no text, no logos, a plain dark "
          "neutral background.")
PLACE = ("Pixel art, a wide view of %s at dusk. Muted blue-grey and slate palette with sparse warm orange lights, low "
         "cloud. Quiet; no people, no text, no readable signs. The subject across the middle of the frame (it is cropped "
         "to a card's top from either side); darker at the bottom edge.")

# Data.PINNACLES: key, who, the head's slug, him or her, the portrait, his look, his three poses, his place's picture,
# the place's style picture, his unique [slug, size, the object]
ORDER = [
    ["grid", "The Lineman", "the_lineman",
     "the Lineman, a big man in his fifties who kept the lights on for the order's people only: a cracked rubber "
     "lineman's coat, a high-cut helmet with a lamp on its front, climbing spurs slung round his neck, a coil of cable "
     "over one shoulder, a face burnt red down one side",
     "a big electricity lineman in his fifties in a cracked black rubber lineman's coat and a high-cut helmet with a lamp "
     "on its front, climbing spurs at his belt, a coil of cable over one shoulder",
     ["holding a carbine low across his body, the helmet lamp lit", "aiming a carbine, two-handed, straight at the viewer, a bright muzzle flash, the helmet lamp lit",
      "hit and falling backwards, arms flung out, the carbine dropping, the helmet lamp swinging"],
     "a city's electricity substation behind a chain-link fence hung with blank warning plates, transformers and pylons, cables humming overhead, its "
     "windows the only lit ones for miles", "the_city",
     ["the_lineman_s_lamp", 128, 128, "a single high-cut helmet with a heavy miner's lamp bolted to its front, the lamp's "
      "glass lit amber, scuffed paint, a strip of reflective tape round it, seen from the front"]],
    ["archive", "The Registrar", "the_registrar",
     "the Registrar, a thin woman in her sixties who decides who was born, who owns and who's owed: a buttoned grey "
     "cardigan over a high collar, reading glasses on a chain, a pen behind one ear, an ink-stained finger, hair pinned "
     "back hard, the look of someone checking your name against a list",
     "a thin woman in her sixties in a buttoned grey cardigan and a long dark skirt, reading glasses on a chain, a "
     "leather satchel of papers over one shoulder",
     ["standing with a ledger held to her chest, a revolver in her other hand at her side", "aiming a revolver, one-handed, arm straight at the viewer, a bright muzzle flash, the ledger under her arm",
      "hit and falling backwards, papers flying from her satchel, the revolver dropping"],
     "a town's old records office: a Victorian stone building with tall windows, filing shelves seen through them by "
     "lamplight, a locked iron gate", "the_town",
     ["the_registrar_s_satchel", 192, 256, "a single old leather document satchel converted into a rucksack, standing "
      "upright as if set down, seen from the front, stuffed with folded papers and ledgers, a brass lock and a worn "
      "crest with no lettering stamped into the flap, straps added from an army pack"]],
    ["mint", "The Issuer", "the_issuer",
     "the Issuer, a heavy pale man in his sixties who prints money nobody believes in: heavy embroidered robes over a "
     "ballistic vest, a chain of office, rings on every finger, a face that has never been told no, thin grey hair "
     "combed flat",
     "a heavy pale man in his sixties in long heavy embroidered robes over a ballistic vest, a chain of office round his "
     "neck, rings on his fingers",
     ["standing still with a shotgun held upright beside him like a staff", "aiming a shotgun from the hip straight at the viewer, a bright muzzle flash, the robes swinging",
      "hit and falling backwards, arms flung out, the shotgun dropping, the chain of office flying up"],
     "a fortified state printing works: a concrete block with no windows, razor wire, a lorry bay with its shutter half "
     "up and light inside, sheets of blank printed paper drying on racks glimpsed through it", "the_bank",
     ["the_issuer_s_robes", 192, 256, "a single set of heavy dark embroidered ceremonial robes hung flat as if on a hook, "
      "seen from the front, gold thread worn dull, the front open on a ballistic vest sewn into the lining, a chain of "
      "office hung over it"]],
]

KEYS = [
    ["the_grid_s_key", 64, 64, "a single heavy brass key to an electricity substation, a red plastic tag on its ring stamped with a lightning bolt"],
    ["ledger_seals", 64, 64, "a single small brass seal for pressing wax, its end engraved with a crest, a lump of red wax stuck to it"],
    ["a_true_fiat_note", 128, 64, "a single crisp new banknote of no country you know, laid flat, its ink still bright, illegible printing and a portrait"],
]
MATERIALS = [
    ["paving", "a stack of three grey paving slabs, one corner broken"],
    ["glass", "a pane of salvaged window glass in its old frame, one corner cracked"],
    ["ledgers", "a stack of three old bound ledgers tied with string"],
    ["cable_drums", "a wooden cable drum wound with thick black cable"],
    ["army_kit", "a folded olive army tarpaulin with a webbing strap round it"],
    ["fuses", "a handful of ceramic cartridge fuses in a small tin"],
]


def ground(i, z):
    key, name, box, what, tint, style = z
    w = (box[2] - box[0]) // 2 // 4 * 4
    h = (box[3] - box[1]) // 2 // 4 * 4
    return {"out": "art/map/zone_%s.png" % key, "endpoint": "generate-image-v2", "width": w, "height": h,
            "no_background": False, "single": True, "seed": 96000 + i, "style_options": STYLE,
            "style_image": "res://art/places/%s.png" % style, "reference_images": ["res://art/reference/map_layout_%s.png" % key],
            "description": GROUND % (what, tint),
            "_where": "the Map: %s's ground, clipped to its shape (box %s in the 1000 x 844 drawing, drawn x2)" % (name, str(box))}


def site(i, s):
    name, zkey, what = s
    z = [x for x in ZONES if x[0] == zkey][0]
    slug = _slug(name)
    return {"out": "art/map/site_%s.png" % slug, "endpoint": "generate-image-v2", "width": 64, "height": 64,
            "no_background": True, "single": True, "seed": 96100 + i, "style_options": STYLE,
            "style_image": "res://art/places/%s.png" % z[5], "description": SITE % (what, z[4]),
            "_where": "the Map: %s under its pin" % name}


def _slug(s):
    out, gap = "", False
    for ch in s.lower():
        if ch.isascii() and ch.isalnum():
            if gap and out:
                out += "_"
            gap = False
            out += ch
        else:
            gap = True
    return out


def order_jobs(i, o):
    key, who, slug, portrait, look, poses, place, place_style, uniq = o
    out = [{"out": "art/people/%s.png" % slug, "endpoint": "generate-image-v2", "width": 128, "height": 128,
            "no_background": False, "single": True, "seed": 96200 + i, "style_options": STYLE,
            "style_image": "res://art/people/fence.png", "description": PORTRAIT % portrait,
            "_where": "%s's face: the order card, the room lines" % who}]
    for k, p in enumerate(POSES):
        refs = ["res://art/people/%s.png" % slug] if k == 0 else ["res://art/fight/head_%s_stand.png" % slug, "res://art/people/%s.png" % slug]
        out.append({"out": "art/fight/head_%s_%s.png" % (slug, p[0]), "endpoint": "generate-image-v2", "width": 128,
                    "height": 192, "no_background": True, "single": True, "seed": 96210 + i, "style_options": STYLE,
                    "style_image": "res://art/people/%s.png" % slug, "reference_images": refs,
                    "description": FIGURE % (p[2] + look, poses[k]), "_where": "%s: %s" % (slug, p[1])})
    out.append({"out": "art/places/the_%s.png" % key, "endpoint": "generate-image-v2", "width": 496, "height": 296,
                "no_background": False, "single": True, "seed": 96220 + i, "style_options": STYLE,
                "style_image": "res://art/places/%s.png" % place_style, "description": PLACE % place,
                "_where": "the order card's picture for %s (Data.PINNACLES art; today the zone's)" % key})
    u_slug, uw, uh, uwhat = uniq
    out.append({"out": "art/items/%s.png" % u_slug, "endpoint": "generate-image-v2", "width": uw, "height": uh,
                "no_background": True, "single": True, "seed": 96230 + i, "style_options": STYLE,
                "style_image": "res://art/reference/items/ref_0%d.png" % (i % 4 + 1), "description": OBJECT % uwhat,
                "_where": "%s's unique, in the stash and the kit" % who})
    return out


def write(path, readme, jobs):
    with open(os.path.join(ROOT, path), "w", encoding="utf-8") as f:
        json.dump({"_readme": readme, "jobs": jobs}, f, indent=1, ensure_ascii=False)
    print(path, len(jobs))


RUN = "Run: godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://%s   (++ --dry-run to list; ++ --only <name> ++ --force to reroll). Regenerate with python3 tools/make_outstanding_manifest.py."

test = [ground(0, ZONES[0])] + [site(k, SITES[k]) for k in range(3)]
rest = [ground(k, ZONES[k]) for k in range(1, 4)] + [site(k, SITES[k]) for k in range(3, 12)]
for k, o in enumerate(ORDER):
    rest += order_jobs(k, o)
glyphs = [{"out": "art/items/%s.png" % s, "endpoint": "generate-image-v2", "width": w, "height": h, "no_background": True,
           "single": True, "seed": 96300 + k, "style_options": STYLE, "style_image": "res://art/reference/items/ref_03.png",
           "description": OBJECT % what, "_where": "the order's key, on the Radio's town list"} for k, (s, w, h, what) in enumerate(KEYS)]
glyphs += [{"out": "art/items/%s.png" % s, "endpoint": "generate-image-v2", "width": 64, "height": 64, "no_background": True,
            "single": True, "seed": 96310 + k, "style_options": STYLE, "style_image": "res://art/reference/items/ref_03.png",
            "description": OBJECT % ("a single " + what), "_where": "a rebuild material, on the Radio's town list and its cards' chips"}
           for k, (s, what) in enumerate(MATERIALS)]

write("tools/pixellab_outstanding_test_manifest.json",
      ["FIAT OUTSTANDING ART, THE TEST (19 Oct, Matt): the Map's Outskirts - its ground, clipped to the zone's shape, and its three sites under their pins. In the game before the rest.",
       RUN % "tools/pixellab_outstanding_test_manifest.json"], test)
write("tools/pixellab_outstanding_manifest.json",
      ["FIAT OUTSTANDING ART (19 Oct, Matt): the Map's other three zones and nine sites; the order's three heads - a face, the fight's three poses, their place for the order card, their unique. After the test reads.",
       RUN % "tools/pixellab_outstanding_manifest.json"], rest)
write("tools/pixellab_order_glyphs_manifest.json",
      ["FIAT ORDER GLYPHS, OPTIONAL (19 Oct): the order's three keys and six of the rebuild materials (copper wire has its item's picture), for the Radio's town list and chips, if those want pictures.",
       RUN % "tools/pixellab_order_glyphs_manifest.json"], glyphs)

# The land past the zones (19 Oct, Matt: the fog alone "too sparse ... draw some art for this that matches the map"):
# one picture under the whole map at half size, drawn x2; the zones paint over it, the fog drifts over it thin.
LAND = ("Pixel art, seen straight down from directly above like an aerial photograph turned into a painted map: the "
        "empty country round a northern English town - rough moorland and bracken, bare hills with dry-stone walls "
        "running over them, rough grazing gone to scrub, a reservoir's edge, a few abandoned farmsteads and a quarry, "
        "lanes going nowhere, banks of low fog lying in the hollows. The whole frame filled edge to edge with land, no "
        "horizon, no sky, no border, no vignette. Only the palette, light and painting style of the style image, not its "
        "view. Darker, plainer and emptier than a town: muted greys, slate blues and "
        "dull olive, dusk light, no lights at all; no people, no vehicles, no text, no labels, no readable signs. Even "
        "detail all over: the town's districts are drawn over most of it, so nothing in it should be the only thing "
        "worth looking at.")
land = [{"out": "art/map/land.png", "endpoint": "generate-image-v2", "width": 508, "height": 420, "no_background": False,
         "single": True, "seed": 96400, "style_options": STYLE, "style_image": "res://art/map/zone_outskirts.png",
         "description": LAND,
         "_where": "the Map: the land past the zones, under all of it (1000 x 844 drawing at half size, drawn x2)"}]
write("tools/pixellab_map_land_manifest.json",
      ["FIAT THE MAP'S LAND (19 Oct, Matt): the country past the zones, one picture under the whole map; the fog drifts over it thin. Styled on the Outskirts' ground: after the Outskirts test.",
       RUN % "tools/pixellab_map_land_manifest.json"], land)
