"""Art 71 (8 Nov; docs/design/endgame_rail.md, 0.15's BUILD66-69): every picture 0.15 borrows or lacks, in one manifest.

  python3 tools/make_art71_manifest.py  -> tools/pixellab_art71_manifest.json

Five groups, each on its proven template (nothing new in how a picture is asked for):

  boots     the 30 boots bases (data.gd BASES "Boots"; today on a pair of gloves' picture through ART_AS), 2x2 = 128x128.
            The item template of make_items29_manifest.py (TAIL, ref_01..04, every style option on) with a boots view of
            its own (the template has none): "a pair of ... side by side ... resting on nothing, no floor".
            Out art/items/<slug>.png: they show once their 30 ART_AS entries come off (the wiring step).
  uniques   the 13 of BUILD67-I and the boots' two of BUILD67-K, at their base's footprint. Items.art reads a unique's own
            art/items/<slug>.png first (every older unique has one), so these show by name - nothing to wire.
  issued    the 21 issued pieces BUILD67-K made (Issued gloves / bergen / boots, and the 18 second and third versions,
            data.gd ISSUED67_MORE), at their base's footprint. Read as uniques: their own art/items/<slug>.png first,
            today their base's picture (the versions) - nothing to wire. The look is the six issued pieces' (olive,
            a small plain brass plate) with each version's own difference.
  nodes     the web's six new notables (BUILD68-S) and the 21 filler kinds BUILD68-W added (data.gd FILLER_KINDS),
            64x64, the template of make_web_small_manifest.py (its ICON tail, dps.png style, dps/hp references).
            Out art/nodes/<slug>.png, where web_view finds them by name - nothing to wire.
  wide      the convoys' six route bands (A69: borrowed places) and the Plots banner (A69: borrowed the site's
            the_allotments.png), 688x296, the rooms' band template (pixellab_rooms_manifest.json: ransacked_streets.png
            as the style image). Route bands to art/places/route_<key>.png - ROUTE_ART69 must name them (the one code
            change); the banner to art/places/the_plots.png - allotments_view's head_art("The Allotments") becomes
            "The Plots".
  crate     the auction's sealed crate (A69: borrowed crates/military), 64x64, make_crates_manifest.py's template, to
            art/crates/sealed.png - SEALED_ART69 becomes "crates/sealed".

Checked against docs/art/pixellab_lessons.md: every item is the object alone with no setting (the tail's "no floor, wall,
ground or sky"); boots "side by side ... resting on nothing"; everything usually printed, branded or stamped said plain /
no lettering in its subject (the lifejacket, the fireworks box, the oil can, the bean tin, the ointment, the bottle, the
sandbag, the issued pieces' plates "smooth blank ... no marks at all"); nothing hand-written; a coin said British and worn
smooth; the bands: "only the palette, light and painting style of the style image", the painting to all four edges, blank
panels on any gantry, no livery or plates on any vehicle, no place named where its name would be painted. Seeds 650000-
650199 (stops on a clash with any other manifest), no two jobs on one out, nothing on disk overwritten."""
import glob
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_item_manifests as items  # noqa: E402  (slug, footprint, CELL, src, TAIL, REFS)
import make_items29_manifest as i29  # noqa: E402  (the item template: describe, job, PLAIN, TAIL, STYLE)
from make_web_art_manifest import ICON  # noqa: E402  (the nodes' tail)

ROOT = i29.ROOT
OWN = "pixellab_art71_manifest.json"
SEED0 = 650000      # clear of every other manifest's (the last used 644003)
PLAIN = i29.PLAIN   # "plain, unprinted, no lettering, no numbers, no logo"
BRASS = "a small smooth blank brass plate with no marks at all"     # the issued pieces' mark (LESSON: "stamped" invites marks: the word kept out)

# ------------------------------------------------------------------ boots (data.gd BASES "Boots", the 30)
# "# LESSON" marks a look reworded for a lesson.
BOOTS = {
    # pace
    "Plimsolls": "a pair of thin white canvas plimsolls with grey rubber soles and toecaps, the canvas greyed",
    "Trainers": "a pair of scuffed grey and white running trainers, plain, no logo or stripes",                  # LESSON: trainers carry logos
    "Running shoes": "a pair of light mesh running shoes in faded blue with thin foam soles, " + PLAIN,         # LESSON: branded
    "Fell shoes": "a pair of low green fell-running shoes with deep studded rubber soles showing at the edges, " + PLAIN,
    "Trail shoes": "a pair of grey and orange trail shoes with a toe bumper and quick laces, " + PLAIN,
    "Running spikes": "a pair of thin black running spikes, the steel spikes showing under the toes, " + PLAIN,
    "Orienteering shoes": "a pair of red and black orienteering shoes with metal-studded soles and high ankle gaiters",
    "Patrol boots": "a pair of black lightweight patrol boots, ankle high, side zips and nylon panels",
    "Hospital clogs": "a pair of white rubber hospital clogs with rows of holes across the toes and a heel strap, " + PLAIN,   # LESSON: clogs carry a maker's badge
    "Special forces boots": "a pair of sand-coloured lightweight assault boots, laced high, stitched nylon and suede, " + PLAIN,
    # quiet
    "Carpet slippers": "a pair of brown tartan carpet slippers with soft felt soles, the backs trodden down",
    "Deck shoes": "a pair of tan leather deck shoes with white soles and a leather lace round the collar",
    "Crepe soles": "a pair of brown suede desert-style shoes on thick pale crepe rubber soles",
    "Desert boots": "a pair of sand suede desert boots, ankle high, two eyelets, pale crepe soles",
    "Walking boots": "a pair of brown leather walking boots with padded collars and red laces",
    "Keeper's brogues": "a pair of heavy brown leather country brogues with punched toecaps and thick soles",
    "Stalking boots": "a pair of soft olive leather stalking boots laced to mid-calf, thin quiet soles",
    "Jungle boots": "a pair of olive canvas and black leather jungle boots, laced high, drainage eyelets on the instep",
    "Ghillie boots": "a pair of brown leather boots with long laces wound round the ankles and strips of hessian tied round them",
    "Wading boots": "a pair of tall green rubber waders' boots with felt soles, folded down at the knee",
    # heavy
    "Wellies": "a pair of tall green rubber wellington boots, mud dried on the toes, " + PLAIN,                    # LESSON: wellies carry a maker's badge
    "Work boots": "a pair of tan leather work boots with steel toecaps showing through the scuffed leather",
    "Rigger boots": "a pair of tan pull-on rigger boots, tall, with loops at the top and a toe guard, " + PLAIN,
    "Hobnail boots": "a pair of old black leather ammunition boots with rows of iron hobnails round the soles",
    "Bovver boots": "a pair of oxblood leather boots laced high, many eyelets, thick air-cushioned soles, " + PLAIN,   # LESSON: the yellow stitch and the heel tab carry a brand
    "Motorcycle boots": "a pair of black leather motorcycle boots with buckles up the side and shin plates, " + PLAIN,
    "Firefighter's boots": "a pair of black leather firefighter's boots, tall, with a reflective band round the top, " + PLAIN,   # LESSON: the band carries lettering
    "Riot boots": "a pair of black riot boots with hard shin guards strapped over them and thick soles, " + PLAIN,
    "EOD boots": "a pair of heavy green bomb-disposal over-boots with thick armoured soles and wide straps, " + PLAIN,
    "Parade boots": "a pair of black parade boots polished to a mirror shine, the toes gleaming",
}
BOOTS_VIEW = ("A realistic painted pixel-art still-life of %s, the two side by side, seen from the front and a little above "
              "at a slight angle, toes towards the viewer, filling the frame, resting on nothing, no floor or ground "
              "under them, no feet or legs in them, worn and used.")

# ------------------------------------------------------------------ uniques (BUILD67-I's 13, BUILD67-K's two)
UNIQUES = {
    "Grandad's .303": "an old wooden Lee-Enfield bolt-action rifle, its stock dark with years of oil and handling, a "
                      "brass marking disc on the butt worn blank, a leather sling",
    "The Groundsman's Shotgun": "a pump-action shotgun with its wooden stock painted grass green and chipped, a length of "
                                "garden twine wound round the fore-end",
    "The Range Officer's Rifle": "a heavy single-shot target rifle with a thick barrel, an aperture rear sight, a "
                                 "hooked butt plate and an adjustable cheek piece, polished walnut",
    "The Allotment Zip Gun": "a crude single-shot pistol made from a length of steel garden pipe bound with wire to a "
                             "carved wooden handle, a nail as its firing pin, a bean cane splint along it",
    "The Station Revolver": "a heavy old blued service revolver with a lanyard ring on the butt and a braided cord "
                            "lanyard, worn smooth at the cylinder, no badge",
    "The Armourer's Box": "a heavy olive load-carrying vest whose front is a row of steel-cornered pouches holding a "
                          "punch roll, files and a small hammer, the handles showing",
    "The Magpie's Pouches": "a black webbing belt rig crowded with odd small pouches of every colour and cloth, sewn "
                            "together, a few loose rifle rounds tucked in loops",
    "The Gun Club Sling": "a broad tan leather shooting harness with a long rifle scabbard across the back, the "
                          "scabbard empty, brass buckles",
    "The Bin Man's Gloves": "a pair of heavy orange rubberised work gauntlets, thick cuffs, grime ground into the palms, "
                            + PLAIN,
    "The Bouncer's Knuckles": "a pair of black leather gloves with thick padded knuckles sewn into the backs, the "
                              "leather split at one knuckle",
    "The Bonfire Box": "a small battered cardboard box of fireworks with its lid open, rockets and cones packed "
                       "inside, a fuse or two showing, the box and every firework " + PLAIN,                       # LESSON: fireworks are printed
    "The Football Rattle": "an old wooden football rattle: a cog and two wooden blades on a turned wooden handle, the "
                           "paint faded",
    "The Lifeboat Jacket": "an orange-and-yellow lifeboat crew's waterproof jacket with a high collar and plain grey "
                           "reflective bands, a whistle on a cord, " + PLAIN,                                         # LESSON: crew jackets carry lettering
    "The Postman's Boots": "a pair of black leather postman's boots, polished but cracked across the toes, the soles "
                           "worn down, long laces",
    "Steel Toecaps": "a pair of black leather work boots whose toes are worn through to bare shining steel toecaps",
}

# ------------------------------------------------------------------ issued (BUILD67-K: three new pieces, 18 versions)
ISSUED = {
    "Issued gloves": "a pair of olive drab assault gloves with a hard knuckle guard, " + BRASS + " on one cuff",
    "Issued bergen": "a large olive drab military bergen rucksack on a frame, side pouches strapped on, " + BRASS + " on the lid",
    "Issued boots": "a pair of olive drab lightweight assault boots, laced high, " + BRASS + " on one collar",
    "Issued steady rifle": "a long heavy olive drab anti-materiel rifle on a folded bipod, a heavy padded cheek rest and "
                           "a thick muzzle brake, " + BRASS + " on the stock",
    "Issued marksman's rifle": "a long heavy olive drab anti-materiel rifle with a large telescopic sight mounted on "
                               "top and a long slim barrel, " + BRASS + " on the stock",
    "Issued quick-draw pistol": "a black service pistol with an extended magazine and an open-topped slide, a cut-down "
                                "grip, " + BRASS + " on the grip",
    "Issued duty pistol": "a heavy black service pistol with a long barrel and a lanyard loop, " + BRASS + " on the grip",
    "Issued spotter's cap": "an olive command helmet with a pair of small binoculars clipped to its brow on a folding "
                            "mount, " + BRASS + " on the front",
    "Issued riot cap": "an olive command helmet with a clear riot visor down and a padded neck flap, " + BRASS + " on the front",
    "Issued light plate": "a slim olive plate carrier, only a front and back plate and narrow straps, " + BRASS + " on the chest",
    "Issued escort plate": "a heavy olive armour suit with broad shoulder plates and upper-arm guards, " + BRASS + " on the chest",
    "Issued ammo webbing": "an olive chest rig with a long row of magazine pouches across the front, the flaps open, "
                           + BRASS,
    "Issued scavenger's webbing": "an olive chest rig with a big open dump pouch hanging at one side and small loose "
                                  "pouches, " + BRASS,
    "Issued medal": "a single bronze campaign medal on a short plain olive ribbon, its face plain and smooth with no "
                    "design or lettering",                                                                           # LESSON: medals carry words
    "Issued bugle": "a small dented brass army bugle with a plain olive cord, no badge",
    "Issued shooting gloves": "a pair of thin olive drab shooting gloves, the trigger finger of the right one cut "
                              "away, " + BRASS + " on one cuff",
    "Issued tracker's gloves": "a pair of olive drab gloves with leather palms and a strip of green-brown camouflage "
                               "cloth along the backs, " + BRASS + " on one cuff",
    "Issued search pack": "a large olive drab bergen with its lid thrown open and long side pockets with pull tabs, "
                          + BRASS + " on the lid",
    "Issued light pack": "a slim olive drab daysack, a third of a bergen's size, compression straps pulled tight, "
                         + BRASS + " on the lid",
    "Issued quiet boots": "a pair of olive drab assault boots with soft dark rubber soles and padded cloth collars, "
                          + BRASS + " on one collar",
    "Issued combat boots": "a pair of heavy olive drab combat boots with armoured shin guards strapped over them, "
                           + BRASS + " on one collar",
}

# ------------------------------------------------------------------ the web's nodes (BUILD68-S notables, BUILD68-W fillers)
NODES = {
    # the six notables on 0.15.0's mechanics
    "Between the eyes": "a rifle's telescopic sight seen end-on, its lens showing a plain thin crosshair",
    "Elbow grease": "a small brass oil can with a long thin spout, a rag tied round its neck, " + PLAIN,         # LESSON: oil cans are branded
    "Covering fire": "a heap of spent brass cartridge cases, some still smoking",
    "Body count": "a short piece of a worn wooden rifle stock with a long row of small notches cut into its edge",
    "Change of dressing": "an empty rifle magazine with a plain white field dressing knotted round it, " + PLAIN,
    "Ride your luck": "a worn British silver sixpence on a loop of string through a hole drilled in it, its face worn "
                      "smooth, no lettering",                                                                        # LESSON: coins come out American
    # the filler kinds BUILD68-W added (the older ten have their pictures)
    "Composed": "a pair of grey foam ear plugs joined by a cord",
    "Telling": "a square of rusty tin sheet with one bullet hole through it, the edges curled back",
    "Pointed": "a single steel-cored rifle round with a sharp black tip, standing on its base",
    "Hobbling": "a short length of rope tied into a hobble knot with two loops",
    "Disarming": "a pair of plain steel handcuffs, one cuff open",
    "Pinning": "a single filled sandbag tied at the neck, plain hessian, " + PLAIN,                               # LESSON: sacks are printed
    "Thrifty": "a small dented tin of loose rifle rounds, the lid off, the tin " + PLAIN,                         # LESSON: tins are printed
    "Primed": "a grenade's pin and pull ring, pulled out, on its own",
    "Watchful": "a small round mirror on a short steel rod, the kind for seeing round corners",
    "Soothing": "a squeezed tube of ointment with its cap off, " + PLAIN,                                         # LESSON: tubes are printed
    "Deft": "a pair of fine steel tweezers",
    "Shrewd": "a small black jeweller's eye loupe",
    "Laden": "a bulging canvas sack tied at the neck, " + PLAIN,
    "Keyed up": "a chipped white enamel mug of black coffee, steam rising, " + PLAIN,
    "Full of beans": "an opened dented tin of baked beans, the lid bent back, no label, " + PLAIN,                 # LESSON: tins are printed
    "Bitter": "a single long icicle",
    "Crackling": "a single car spark plug, its white porcelain cracked",
    "Scorching": "a lit red road flare stick, sparking at one end, " + PLAIN,
    "Barbed": "a short twist of rusty barbed wire",
    "Brawny": "a hand grip exerciser: two worn wooden handles joined by a steel spring",
    "Toxic": "a small brown glass bottle with a cork stopper, no label",                                          # LESSON: bottles carry labels
}

# Kinds without a picture that 0.15 didn't add (left out, raised with Matt instead - the house rule): Practised (a
# TRACK_FILLERS kind since 4 Nov, never drawn) and Sharp-eyed (Lucky renamed in BUILD51-A: art/nodes/lucky.png is its
# picture under the old name).
OLDER_GAPS = {"Practised", "Sharp-eyed"}

# ------------------------------------------------------------------ wide: the route bands and the Plots banner
# The rooms' band template (pixellab_rooms_manifest.json): 688x296, ransacked_streets.png as the style image. The band
# is drawn 1536 wide (Pal.GRID_W) and covered from the centre: the Convoys' 180 high and the Plots' 92 show only a
# strip across the middle, so the subject runs across the middle, edge to edge.
BAND_STYLE = "res://art/places/ransacked_streets.png"
BAND_TAIL = ("Muted blue-grey palette, dark navy shadows, overcast evening light, one or two warm orange lamps. The subject "
             "runs as a long low strip across the middle of the frame from edge to edge; the left third stays darker and "
             "lower in detail (the title sits there). Only the palette, light and painting style of the style image, not "
             "its view or its subject. The painting fills the whole canvas to all four edges, no border, frame or margin. "
             "No people or figures. No text, no lettering, no numbers, no number plates; every panel and board in it blank.")
ROUTES = [   # Words.E69["routes"] in order (route 0-5); the key is the out's name
    ("m4", "a long straight motorway in a shallow cutting, three empty lanes each way, abandoned cars nosed onto the hard "
           "shoulder, crash barriers, an overhead gantry carrying plain blank grey panels with nothing on them, a line of "
           "lorry tail lights far off"),                                                          # LESSON: gantries carry lettering
    ("docks_road", "a dual carriageway running along a high dock wall, stacks of shipping containers in plain faded paint "
                   "with no lettering behind a chain-link fence, the arms of gantry cranes against the sky, sodium lamps"),   # LESSON: containers carry names
    ("treasury_road", "a wide city avenue between tall stone buildings with columns, lines of plain grey concrete "
                      "barricade blocks across it, one plain grey armoured van with no lettering far down the road, "
                      "wet paving"),                                                              # LESSON: naming the Treasury would paint its name
    ("ring_road", "an elevated concrete ring road on tall pillars curving past tower blocks, a flyover crossing it, a "
                  "burnt-out car on a slip road, weeds in the cracks"),
    ("old_a_road", "a narrow old single-carriageway road between hedges and stone walls, telegraph poles along it, a "
                   "village of stone cottages with dark windows, a shut lay-by with a plain empty trailer"),
    ("airport_spur", "a straight dual carriageway beside a tall perimeter fence, beyond it a parked airliner in plain "
                     "grey with no markings, livery or lettering, approach lights on poles running into the distance"),   # LESSON: airliners carry livery
]
PLOTS = ("the camp's own vegetable plots dug along the edge of an old council football pitch: six long raised beds edged "
         "with scaffold boards in a row, rows of young greens, bean canes, a water butt, a wheelbarrow, a lean-to shed of "
         "corrugated sheet, a rusting goalpost with no net at the far end. Not a council allotment site: no sheds in "
         "rows, no chain-link fence, no gate")

# ------------------------------------------------------------------ the sealed crate (make_crates_manifest.py's template)
CRATE_TAIL = (" One object centred and filling the frame, seen from a little above and to the side, a single bold silhouette that "
              "still reads at a quarter of this size, soft directional overcast daylight, natural material rendering with painterly "
              "shading; no black outlines, no flat cel shading, not anime, not a cartoon, not a glossy video-game icon; the look of "
              "a real object photographed on a grey day in a country that has run out of money. Muted cool northern palette, worn "
              "and scuffed, nothing new. Nothing else in the frame, no hands, no person, no text, no logos, a plain dark neutral "
              "background.")     # make_crates_manifest.py's TAIL, verbatim (that maker writes its JSON on import)
SEALED = ("A realistic painted pixel-art still-life of a heavy dark wooden crate bound with steel bands, its lid shut and "
          "sealed with twisted wire through a plain lead seal, no stencils, no lettering, no numbers, no labels.")     # LESSON: crates carry stencils


def section_of(name):
    """A base's slot, Boots included (make_items29's section_of predates the ninth slot)."""
    return i29.section_of(name) or ("Boots" if ('{"name": "%s"' % name) in boots_section() else "")


def boots_section():
    import re
    m = re.search(r'\n\t"Boots": \[\n(.*?)\n\t\],', items.src, re.S)
    return m.group(1) if m else ""


def boots_names():
    import re
    return re.findall(r'\{"name": "([^"]+)"', boots_section())


def unique_defs():
    """data.gd UNIQUES / ISSUED / ISSUED67_MORE: name -> (slot, base)."""
    import re
    return {n: (s, b) for n, s, b in re.findall(r'\{"name": "([^"]+)", "slot": "(\w+)", "base": "([^"]+)"', items.src)}


def boots_job(out, base, look, seed, where):
    w, h = items.footprint("Boots", base)
    return {"out": out, "endpoint": "generate-image-v2", "description": BOOTS_VIEW % look + i29.TAIL,
            "width": w * items.CELL, "height": h * items.CELL, "no_background": True, "seed": seed, "single": True,
            "style_image": items.REFS[seed % len(items.REFS)], "style_options": i29.STYLE, "_where": where}


def item_job(name, slot, base, look, seed, where):
    if slot == "Boots":
        return boots_job("art/items/%s.png" % items.slug(name), base, look, seed, where)
    j = i29.job("art/items/%s.png" % items.slug(name), slot, base, look, seed, where)     # describe() by the base's type and view
    return j


def node_job(name, obj, seed):     # make_web_small_manifest.node_job
    return {"out": "art/nodes/%s.png" % items.slug(name), "endpoint": "generate-image-v2", "width": 64, "height": 64,
            "no_background": True, "single": True, "seed": seed, "style_options": i29.STYLE,
            "style_image": "res://art/ui/dps.png", "reference_images": ["res://art/ui/dps.png", "res://art/ui/hp.png"],
            "description": ICON % obj, "_where": "the web: %s (web_view's art/nodes/<slug>.png; a glyph till then)" % name}


def band_job(out, scene, seed, where):
    return {"out": out, "endpoint": "generate-image-v2", "width": 688, "height": 296, "no_background": False,
            "single": True, "seed": seed, "style_image": BAND_STYLE, "style_options": i29.STYLE,
            "description": "Pixel art, wide ground-level view of %s, after a collapse. %s" % (scene, BAND_TAIL), "_where": where}


def used_seeds():
    seen = {}
    for path in glob.glob(os.path.join(ROOT, "tools", "pixellab_*manifest.json")):
        if os.path.basename(path) == OWN:
            continue
        try:
            jobs = json.load(open(path, encoding="utf-8")).get("jobs", [])
        except (ValueError, OSError):
            continue
        for j in jobs:
            if isinstance(j, dict) and j.get("seed") is not None:
                seen.setdefault(int(j["seed"]), []).append(j.get("out", "?"))
    return seen


def main():
    import re
    want = boots_names()
    assert sorted(want) == sorted(BOOTS), "BOOTS aren't data.gd's: missing %s, extra %s" % (
        sorted(set(want) - set(BOOTS)), sorted(set(BOOTS) - set(want)))
    ud = unique_defs()
    m67 = re.search(r"const ISSUED67_MORE := \[(.*?)\n\]", items.src, re.S).group(1)
    versions = re.findall(r'\{"name": "([^"]+)"', m67)
    assert sorted(versions + ["Issued gloves", "Issued bergen", "Issued boots"]) == sorted(ISSUED), "ISSUED aren't data.gd's"
    fk = re.search(r"const FILLER_KINDS := \{(.*?)\n\}", items.src, re.S).group(1)
    no_pic = [k for k in re.findall(r'"([^"]+)": \{"effect"', fk) if not os.path.exists(os.path.join(ROOT, "art", "nodes", items.slug(k) + ".png"))]
    no_pic = [k for k in no_pic if k not in OLDER_GAPS]
    fillers = [k for k in NODES if k in no_pic]
    assert sorted(fillers) == sorted(no_pic), "FILLER_KINDS without a picture: %s; NODES has %s" % (sorted(no_pic), sorted(fillers))
    words = Words_E69_routes()
    assert len(words) == len(ROUTES), "Words.E69 routes %s against %d bands" % (words, len(ROUTES))

    jobs = []
    seed = SEED0
    for name in want:
        jobs.append(boots_job("art/items/%s.png" % items.slug(name), name, BOOTS[name], seed,
                              "Boots base %s, 2x2 (borrows %s through ART_AS till its entry comes off)" % (name, borrowed(name))))
        seed += 1
    for name, look in UNIQUES.items():
        slot, base = ud[name]
        jobs.append(item_job(name, slot, base, look, seed, "unique %s (%s, on %s; shows its base's picture till this lands)" % (name, slot, base)))
        seed += 1
    for name, look in ISSUED.items():
        slot, base = ud[name]
        jobs.append(item_job(name, slot, base, look, seed, "issued %s (%s, on %s; shows its base's picture till this lands)" % (name, slot, base)))
        seed += 1
    for name, obj in NODES.items():
        jobs.append(node_job(name, obj, seed))
        seed += 1
    for k, (key, scene) in enumerate(ROUTES):
        jobs.append(band_job("art/places/route_%s.png" % key, scene, seed,
                             "the Convoys' band for route %d (%s): ROUTE_ART69[%d] -> \"Route %s\" (borrows a place today)" % (k, words[k], k, key.replace("_", " "))))
        seed += 1
    jobs.append(band_job("art/places/the_plots.png", PLOTS, seed,
                         "the Plots banner (allotments_view head_art: \"The Allotments\" -> \"The Plots\"; borrows the site's today)"))
    seed += 1
    jobs.append({"out": "art/crates/sealed.png", "endpoint": "generate-image-v2", "description": SEALED + CRATE_TAIL,
                 "width": 64, "height": 64, "no_background": True, "seed": seed, "single": True,
                 "style_image": items.REFS[seed % len(items.REFS)], "style_options": i29.STYLE,
                 "_where": "the auction's sealed crate (SEALED_ART69 \"crates/military\" -> \"crates/sealed\")"})
    seed += 1

    assert seed - SEED0 <= 200, "past the range 650000-650199"
    used = used_seeds()
    clash = {j["seed"]: used[j["seed"]] for j in jobs if j["seed"] in used}
    if clash:
        sys.exit("seeds already used elsewhere: %s - move SEED0" % clash)
    outs = [j["out"] for j in jobs]
    assert len(outs) == len(set(outs)), "an out twice"
    on_disk = [o for o in outs if os.path.exists(os.path.join(ROOT, o))]
    if on_disk:
        sys.exit("on disk already (a new name was expected): %s" % on_disk)
    for j in jobs:
        for r in [j.get("style_image")] + list(j.get("reference_images", [])):
            if r and not os.path.exists(os.path.join(ROOT, r.replace("res://", ""))):
                sys.exit("no %s on disk (%s)" % (r, j["out"]))
    small = sum(1 for j in jobs if j["width"] * j["height"] <= 65536)
    big = len(jobs) - small
    cost = 0.08 * small + 0.15 * big
    readme = [
        "FIAT ART 71 (8 Nov; 0.15, docs/design/endgame_rail.md): every picture 0.15 borrows or lacks - %d jobs: %d at $0.08 "
        "(under 65k px), %d at $0.15 (688x296 bands); about $%.2f, $%.2f with a 30%% reroll budget." % (len(jobs), small, big, cost, cost * 1.3),
        "30 boots bases, 15 uniques, 21 issued pieces (art/items/<slug>.png); 6 notables and 21 fillers (art/nodes/<slug>.png); "
        "6 route bands and the Plots banner (art/places/); the sealed crate (art/crates/sealed.png). Nothing on disk is overwritten.",
        "Shows by name: the uniques, the issued pieces, the nodes. Wiring after art.done: the 30 boots ART_AS entries off; "
        "ROUTE_ART69 to the route_ names; the banner's head_art to \"The Plots\"; SEALED_ART69 to crates/sealed. ++ --parallel 3.",
        "Regenerate with python3 tools/make_art71_manifest.py; check with python3 tools/art_lint.py tools/pixellab_art71_manifest.json.",
    ]
    with open(os.path.join(ROOT, "tools", OWN), "w", encoding="utf-8") as f:
        json.dump({"_readme": readme, "jobs": jobs}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print("art71: %d jobs (boots %d, uniques %d, issued %d, nodes %d, bands %d, crate 1), seeds %d-%d; %d x $0.08 + %d x $0.15 = $%.2f, "
          "+30%% = $%.2f" % (len(jobs), len(BOOTS), len(UNIQUES), len(ISSUED), len(NODES), len(ROUTES) + 1, SEED0, seed - 1,
                              small, big, cost, cost * 1.3))


def borrowed(base):
    import re
    m = re.search(r'"%s": "([^"]+)"' % re.escape(base), re.search(r"const ART_AS := \{(.*?)\n\t\}", items.src, re.S).group(1))
    return m.group(1) if m else "?"


def Words_E69_routes():
    import re
    s = open(os.path.join(ROOT, "scripts", "sim", "words.gd"), encoding="utf-8").read()
    m = re.search(r'const E69 := \{\n\t"routes": \[(.*?)\]', s, re.S)
    return re.findall(r'"([^"]+)"', m.group(1))


if __name__ == "__main__":
    main()
