"""Art 76 (9 Nov; slice/README.md, Matt's go of 9 Nov): the ARPG slice's own top-down sprites and tiles, replacing the
Kenney stand-ins (slice/art/kenney/) - a small PixelLab set in the game's style at Zero Sievert's scale.

  python3 tools/make_art76_manifest.py  -> tools/pixellab_art76_manifest.json

Two groups, every canvas under 65k px at $0.08 a job:

  figures   five characters x four poses, 64x64, seen from directly above facing +x (the game rotates them): the runner
            (a Poacher), gang1..3 (an Estate gang), the hard man; poses aim, fire, reload, down. Drawn at about 30 px on
            screen (2x). Transparent, the figure alone.
  tiles     ground tiles and props from above at the same 2x (a 32 px tile is a 64 px canvas): asphalt x2, paving, kerb,
            bay line, drain, oil stain, a burnt-out car and a van (2x3 / 2x3.5 tiles, one canvas each - well under the
            API's cap, so not split), two bins, a low brick wall, a fence, a floor and a wall top for the kiosk, the crate,
            a shelter roof.

Out slice/art/pl/<name>.png (res://slice/art/pl/; the batch script prefixes res:// itself). Nothing on disk overwritten.

Checked against docs/art/pixellab_lessons.md:
- Style image: the game's own top-down painting, art/map/land.png - never a side-on item icon (ref_01..04) and never the
  side-on gang figures (art/fight/gang_*), which would pull the view into profile ("Side-on style images pull shapes into
  profile"). Every prompt says "only the palette, light and painting style of the style image, not its view or its
  subject" (the landscape-style lesson: land.png is a map, its view must not come through).
- Figures take one Kenney top-down figure (slice/art/kenney/, CC0) as a reference_images entry for the VIEW only, as
  big_revolver.png is for guns: aim soldier1_gun, fire soldier1_machine, reload soldier1_reload; down has none (the pack
  has no lying figure). The words say "not a side view, not in profile, not from the front" and "one gun only, held by
  exactly two hands"; "only the view from directly above of the reference, not its colours or its flat style".
- No setting named for a cut-out (no car park, road, estate in a figure or a prop); the tail says no floor, ground,
  shadow, shadow disc or setting. The down pose: no blood pool (a pool is ground).
- Lettering: nothing that invites it is named (no bus shelter, kiosk, shop, council, "sign"); the van, the burnt-out car
  "no number plates, no livery, no lettering"; the bins "no number on it" (bins are on the usually-printed list); the
  crate no stencils; the tracksuit no stripes or logo, the donkey jacket's shoulder panel plain, the hi-vis bands plain
  grey; the bay line "no numbers or words painted".
- Tiles are bare surfaces: nothing described that the game draws over them ("Never describe what will be drawn over a
  backdrop"); they fill the canvas to all four edges, no border.
- Seeds 660000-660099 (stops on a clash with any other manifest; tools/art_lint.py checks again)."""
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OWN = "pixellab_art76_manifest.json"
SEED0 = 660000      # clear of every other manifest's (the last used 650100, art71)
OUT = "slice/art/pl/%s.png"
STYLE_IMG = "res://art/map/land.png"     # the game's own top-down painting (the map's land)
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}     # the template's (make_items29 STYLE)
KENNEY = "res://slice/art/kenney/%s.png"
VIEW_REF = {"aim": KENNEY % "soldier1_gun", "fire": KENNEY % "soldier1_machine", "reload": KENNEY % "soldier1_reload"}
PLAIN = "plain, unprinted, no lettering, no numbers, no logo"

# ------------------------------------------------------------------ figures
# The look of each man from above: what shows from directly overhead (head, shoulders, arms, the gun) - and the gun.
WHO = {
    "runner": ("a lean poacher in a worn olive waxed jacket and a brown tweed flat cap, the cap's top and peak the "
               "nearest thing to the eye",
               "a long bolt-action hunting rifle with a dark wooden stock and a scope"),
    "gang1": ("a young man in a plain grey tracksuit top with the hood down, close-cropped dark hair, no stripes, " + PLAIN,
              "a sawn-off double-barrelled shotgun"),                                                    # LESSON: tracksuits carry stripes and logos
    "gang2": ("a young man in a plain black hoodie with the hood up, " + PLAIN,
              "a small black pistol held out in both hands"),                                            # LESSON: hoodies carry prints
    "gang3": ("a man in a dark navy donkey jacket with a plain black shoulder panel across the top of the back, no "
              "lettering on the panel, short fair hair",
              "a short black submachine gun"),                                                           # LESSON: donkey jacket panels carry a firm's name
    "hard": ("a big heavy-built man, broad shoulders filling more of the frame than the others, a heavy dark work coat "
             "with a faded orange hi-visibility vest over it, the vest's bands plain grey, " + PLAIN + ", a shaved head",
             "a black pump-action shotgun"),                                                             # LESSON: hi-vis carries lettering
}
POSE = {
    "aim": "standing, aiming: both arms forward to the right holding %s pointing straight to the right",
    "fire": "standing, firing: both arms forward to the right holding %s pointing straight to the right, a small bright "
            "yellow-orange muzzle flash at its muzzle",
    "reload": "standing, reloading: %s held lowered and angled across the body, one hand at the magazine or the breech",
    "down": "down and dead, lying flat on his back with his arms flung out, %s dropped beside his hand",
}
FIG = ("Top-down pixel-art game character sprite seen from directly above, looking straight down onto the top of his head "
       "and shoulders: %s, %s. He faces right: head in the centre, shoulders running up and down the frame, the gun "
       "pointing to the right. Not a side view, not in profile, not from the front, no legs seen from the side. One gun "
       "only, held by exactly two hands. The figure small and centred, clear of every edge.")
FIG_DOWN = ("Top-down pixel-art game character sprite seen from directly above: %s, %s. Seen straight down from overhead, "
            "lying along the frame with his head to the right. Not a side view. One gun only. The figure centred, clear "
            "of every edge. No blood pool.")
FIG_TAIL = (" Only the palette, light and painting style of the style image, not its view or its subject; only the view "
            "from directly above of the reference image, not its colours or its flat style. Muted, grim, cold palette, "
            "worn and dirty clothes, painterly pixel shading. The figure alone on a transparent background: no floor, "
            "ground, shadow, shadow disc or setting around it. No text, no lettering, no logos.")

# ------------------------------------------------------------------ tiles and props (name, w, h, transparent, words)
SURF = (". Seen from directly above, flat, filling the whole canvas to all four edges, no border, frame or margin; an even "
        "surface with nothing near the edges, so it repeats side by side. Nothing on it, no marks but its own wear.")
PROP = (". Seen from directly above, looking straight down. The object alone on a transparent background, centred, no "
        "floor, ground, shadow or setting around it.")
TAIL = (" Top-down pixel-art game tile. Only the palette, light and painting style of the style image, not its view or its "
        "subject. Muted, grim, cold palette, worn, dirty and neglected, painterly pixel shading. No text, no lettering, no "
        "numbers, no logos.")
TILES = [
    ("asphalt_a", 64, 64, False, "Dark grey worn asphalt, fine grit, a faint crack" + SURF),
    ("asphalt_b", 64, 64, False, "Dark grey worn asphalt, fine grit, a patched darker square repair in the middle, loose gravel" + SURF),
    ("paving", 64, 64, False, "Grey square concrete paving slabs, two by two, cracked and mossy at the joints" + SURF),
    ("kerb", 64, 64, False, "A straight grey concrete kerb running left to right across the middle, a strip of worn "
                            "asphalt below it and a strip of grey paving above it, the kerb's top edge chipped. Seen from "
                            "directly above, filling the whole canvas to all four edges, no border, frame or margin."),
    ("bay_line", 64, 64, True, "A single straight faded white painted stripe running up the middle from top edge to "
                               "bottom edge, the paint worn and broken, no numbers or words painted. The stripe alone on a "
                               "transparent background, no asphalt or ground around it."),
    ("drain", 64, 64, True, "A square cast-iron drain grate with parallel slots, rusted at the edges, " + PLAIN + PROP),   # LESSON: covers carry a maker's name
    ("oil_stain", 64, 64, True, "A dark irregular oil stain splash, translucent black with a faint rainbow sheen at its "
                                "edges. The stain alone on a transparent background, no asphalt or ground around it."),
    ("burnt_car", 128, 192, True, "A burnt-out saloon car, its nose to the top: the roof caved, paint burnt off to "
                                  "rust-brown and black metal, the windows gone, the tyres burnt to the rims, no number "
                                  "plates, no badges, " + PLAIN + PROP),                                 # LESSON: plates and badges
    ("van", 128, 224, True, "A plain dull white panel van, its nose to the top, roof dented and streaked with grime, no "
                            "livery, no number plates, no lettering, no logo" + PROP),                   # LESSON: vans carry livery
    ("bin_wheelie", 64, 64, True, "A dark green plastic wheelie bin with its lid shut, the hinge and two wheels at one end, "
                                  "no number on it, " + PLAIN + PROP),                                   # LESSON: bins are printed
    ("bin_round", 64, 64, True, "A round black metal litter bin with an open top, rubbish inside, no number on it, "
                                + PLAIN + PROP),
    ("brick_wall", 64, 64, True, "The top of a low red-brick wall running left to right across the middle from edge to "
                                 "edge, a row of grey coping stones along it, a brick missing. Seen from directly above, "
                                 "transparent above and below the wall, no ground."),
    ("fence", 64, 64, True, "A run of rusted green steel palisade fence running left to right across the middle from edge "
                            "to edge, the pointed tops of its pales seen from above. Transparent above and below the "
                            "fence, no ground."),
    ("kiosk_floor", 64, 64, False, "Worn grey-brown lino floor tiles, scuffed, a curled corner" + SURF),
    ("kiosk_wall", 64, 64, False, "The top of a thick wall of grey painted breeze blocks running left to right across the "
                                  "whole tile, blackened with soot. Seen from directly above, filling the whole canvas to "
                                  "all four edges, no border, frame or margin."),
    ("crate", 64, 64, True, "The lid of a heavy dark wooden crate bound with two steel bands, seen from directly above, "
                            "nail heads at the corners, no stencils, " + PLAIN + PROP),                  # LESSON: crates carry stencils
    ("shelter_roof", 128, 64, True, "The flat roof of a small open-sided steel shelter, seen from directly above: a plain "
                                    "grey corrugated roof panel on a thin steel frame, dirt and dead leaves on it, "
                                    + PLAIN + PROP),                                                    # LESSON: "bus shelter" invites a timetable and a sign
]


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
    jobs = []
    seed = SEED0
    for who, (look, gun) in WHO.items():
        for pose, words in POSE.items():
            body = (FIG_DOWN if pose == "down" else FIG) % (look, words % gun)
            j = {"out": OUT % ("%s_%s" % (who, pose)), "endpoint": "generate-image-v2", "description": body + FIG_TAIL,
                 "width": 64, "height": 64, "no_background": True, "seed": seed, "single": True,
                 "style_image": STYLE_IMG, "style_options": STYLE,
                 "_where": "slice figure %s, %s (art.gd; faces +x, about 30 px on screen)" % (who, pose)}
            if pose in VIEW_REF:
                j["reference_images"] = [VIEW_REF[pose]]
            jobs.append(j)
            seed += 1
    for name, w, h, clear, words in TILES:
        jobs.append({"out": OUT % name, "endpoint": "generate-image-v2", "description": words + TAIL,
                     "width": w, "height": h, "no_background": clear, "seed": seed, "single": True,
                     "style_image": STYLE_IMG, "style_options": STYLE,
                     "_where": "slice tile/prop %s, %dx%d (%d x %d tiles of 32 px on screen)" % (name, w, h, w // 64, h // 64) if h % 64 == 0
                     else "slice prop %s, %dx%d (about %.1f x %.1f tiles of 32 px on screen)" % (name, w, h, w / 64.0, h / 64.0)})
        seed += 1

    assert seed - SEED0 <= 100, "past the range 660000-660099"
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
    over = [j["out"] for j in jobs if j["width"] * j["height"] > 65536]
    assert not over, "over the $0.08 band: %s" % over
    cost = 0.08 * len(jobs)
    readme = [
        "FIAT ART 76 (9 Nov; the ARPG slice, slice/README.md): the slice's own top-down sprites and tiles, %d jobs, all at "
        "$0.08 (every canvas under 65k px); about $%.2f, $%.2f with a 30%% reroll budget." % (len(jobs), cost, cost * 1.3),
        "20 figures (runner, gang1..3, hard x aim, fire, reload, down; 64x64, from directly above, facing +x) and 17 tiles "
        "and props (64 px canvas = one 32 px tile on screen), out to slice/art/pl/<name>.png. Style image art/map/land.png "
        "(the game's own top-down painting); the Kenney figures as a view-only reference. Nothing on disk is overwritten.",
        "Wiring after art.done: slice/art.gd reads slice/art/pl/ by name (art76_names.md). ++ --parallel 3.",
        "Regenerate with python3 tools/make_art76_manifest.py; check with python3 tools/art_lint.py tools/pixellab_art76_manifest.json.",
    ]
    with open(os.path.join(ROOT, "tools", OWN), "w", encoding="utf-8") as f:
        json.dump({"_readme": readme, "jobs": jobs}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print("art76: %d jobs (%d figures, %d tiles/props), seeds %d-%d, about $%.2f ($%.2f with rerolls)" % (
        len(jobs), len(WHO) * len(POSE), len(TILES), SEED0, seed - 1, cost, cost * 1.3))


if __name__ == "__main__":
    main()
