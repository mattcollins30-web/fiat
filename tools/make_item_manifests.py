#!/usr/bin/env python3
"""Writes tools/pixellab_items_<type>_manifest.json, one per gear type, for
tools/pixellab_batch_v2.gd (Greenhorn's v2 runner, copied here unchanged).

Footprints and slugs come from the same tables the game uses: a base's
picture is drawn at footprint x 64 px, and loaded from
art/items/<slug>.png where slug is Items.slug(base) - lowercase, every run of
anything that isn't a letter or digit an underscore ("Semi-auto .22" ->
semi_auto_22). Change a footprint in data.gd and rerun this; the manifest
sizes follow.

Run (from the project root):
  python3 tools/make_item_manifests.py
  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_items_long_guns_manifest.json

One job a base, "single": the runner writes the first candidate straight to
art/items/<slug>.png and nothing else; existing files are skipped, so a
rerun only fills gaps.
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "scripts", "sim", "data.gd")
CELL = 64

# the slot's default footprint and the exceptions, read from data.gd so the
# two can't drift
src = open(DATA, encoding="utf-8").read()


def gd_dict(name):
    m = re.search(r"const %s := \{(.*?)\n\}" % name, src, re.S)
    body = m.group(1) if m else re.search(r"const %s := \{(.*?)\}" % name, src, re.S).group(1)
    out = {}
    for k, w, h in re.findall(r'"([^"]+)":\s*\[(\d+),\s*(\d+)\]', body):
        out[k] = (int(w), int(h))
    return out


SIZE = gd_dict("SIZE")
FOOTPRINTS = gd_dict("FOOTPRINTS")


def names(section):
    """Base names in a BASES section, or ATTACHMENTS."""
    if section == "Attachment":
        m = re.search(r"const ATTACHMENTS := \[(.*?)\n\]", src, re.S)
    else:
        m = re.search(r'\n\t"%s": \[\n(.*?)\n\t\],' % section, src, re.S)
    return re.findall(r'\{"name": "([^"]+)"', m.group(1))


def footprint(slot, base):
    return FOOTPRINTS.get(base, SIZE[slot])


def slug(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


TAIL = (" One object centred and filling the frame, soft directional overcast daylight, natural material rendering with fine "
        "detail and painterly shading; no black outlines, no flat cel shading, not anime, not a cartoon, not a glossy "
        "video-game item; the look of a real object photographed on a grey day in a country that has run out of money. "
        "Muted cool northern palette, worn and repaired, nothing new. Nothing else in the frame, no hands, no person, "
        "no text, no logos, a plain dark neutral background.")

GUN_WORDS = {
    "improvised": "cobbled together from hardware-shop parts, pipe, tape and timber",
    "shotgun": "a farmer's or a security firm's gun, scuffed stock, oiled steel",
    "rifle": "a stalking or ex-army rifle, worn bluing, a sling",
    "smg": "a police or workshop-made carbine, black polymer gone grey",
    "pistol": "an old service or compact pistol, holster-worn finish",
}


def gun_type(base):
    m = re.search(r'\{"name": "%s", "type": "(\w+)"' % re.escape(base), src)
    return m.group(1) if m else ""


def long_gun(base):
    return ("A realistic painted pixel-art still-life of a single %s, seen exactly side-on with the muzzle pointing left, "
            "laid level and filling the frame left to right, as it might be found in post-collapse Britain - %s."
            % (base.lower(), GUN_WORDS[gun_type(base)]))


def handgun(base):
    t = gun_type(base)
    words = "a converted or air pistol held together with tape" if t == "improvised" else GUN_WORDS["pistol"] if t == "pistol" else "a machine pistol, black polymer gone grey"
    return ("A realistic painted pixel-art still-life of a single %s, seen exactly side-on with the muzzle pointing left, "
            "filling the frame, %s." % (base.lower(), words))


def helmet(base):
    return ("A realistic painted pixel-art still-life of a single %s seen from the front and slightly above, resting on "
            "nothing, filling the frame top to bottom, scratched shell, frayed strap, the markings worn off." % base.lower())


ARMOUR_WORDS = {
    # "plates" on its own reads as crockery: say what the thing is
    "Army plates": "army-issue body armour, a plate carrier vest in faded olive with the ceramic plates inside it",
    "Ceramic plates": "a black plate carrier vest with ceramic armour plates inside it, the front plate's edge showing at the chest",
    "Light plates": "a slim low-profile plate carrier vest in grey, the thin plates inside it, worn under a jacket",
    "Full plate carrier": "a full military plate carrier with front, back and side plates, pouches and cummerbund, heavy",
    "Ballistic vest": "a black ballistic vest, the soft armour panels inside a nylon cover",
    "Police body armour": "a police stab-and-ballistic vest in black with the POLICE label picked off",
    "Stab vest": "a security guard's stab vest in black, the panels inside a nylon cover",
    "Padded jacket": "a thick padded work jacket, nothing armoured about it but the padding",
    "Motorbike leathers": "a motorcycle leather jacket with the armour inserts at the shoulders and elbows",
    "Riot suit": "a police riot suit's torso and arm armour, hard black plates over padding",
    "Issue plates": "the army's own plate carrier in olive, front and back plates inside, pouches on the front, a name tape",
}


def armour(base):
    what = ARMOUR_WORDS.get(base, base.lower())
    return ("A realistic painted pixel-art still-life of a single piece of body armour - %s - hung flat as if on a hook, "
            "seen from the front, filling the frame top to bottom, straps loose, stained fabric, dented where it has "
            "been hit. Clothing or a vest, never crockery." % what)


def bag(base):
    return ("A realistic painted pixel-art still-life of a single %s standing upright as if set down on the floor, seen "
            "from the front, filling the frame, half full, zips and buckles worn, repaired with tape and stitching." % base.lower())


def medical(base):
    return ("A realistic painted pixel-art still-life of a single %s seen from above at a slight angle, filling the frame, "
            "packaging faded and opened, the contents real and used." % base.lower())


def ammo(base):
    what = {"Nails": "a cardboard box of nails", "Hardened bolts": "a box of hardened steel bolts"}.get(base, "an open box of %s" % base.lower())
    return ("A realistic painted pixel-art still-life of %s seen from above at a slight angle, filling the frame, cardboard "
            "soft and torn, a few loose rounds beside it." % what)


MELEE_WORDS = {
    "Spiked bat": "a wooden baseball bat with roofing nails hammered through the thick end",
    "Machete": "a garden-centre machete with a black plastic handle, the blade nicked and oiled",
    "Pipe wrench": "a heavy red Stillson pipe wrench, paint chipped, jaws rusted",
    "Fire axe": "a red and black fire axe with a pick on the back of the head",
    "Bayonet on a stick": "an army bayonet lashed to a broom handle with black tape",
    "Sledgehammer": "a long-handled sledgehammer, the head scarred, the ash handle worn pale",
    "Breaker bar": "a long steel breaker bar with a knurled grip, oil-dark",
    "Knife": "a kitchen knife with the handle wrapped in grey tape",
    "Knuckle duster": "a brass knuckle duster, old and worn smooth",
    "Cosh": "a short leather cosh with a wrist loop",
}


def melee(base):
    return ("A realistic painted pixel-art still-life of a single %s lying flat, seen from above, filling the frame, "
            "worn and used." % MELEE_WORDS[base])


MELEE_PARTS = {"Tape", "Cord wrap", "Lanyard", "Nails through it", "A blade on it", "Lead in it"}


def melee_part(base):
    what = {"Tape": "a roll of black gaffer tape", "Cord wrap": "a hank of green paracord", "Lanyard": "a leather wrist lanyard with a steel ring",
            "Nails through it": "a handful of galvanised roofing nails", "A blade on it": "a length of hacksaw blade with two bolt holes",
            "Lead in it": "a small ingot of grey lead, rough-cast"}[base]
    return ("A realistic painted pixel-art still-life of %s seen from above at a slight angle, filling the frame, on a workbench." % what)


def part(base):
    return ("A realistic painted pixel-art still-life of a single %s gun part seen side-on, filling the frame, anodised "
            "finish worn to bare metal at the edges." % base.lower())


# socketables: things from a shed that go in a socket. Not gun parts, so
# their own prompt, each its own object.
SOCKET_WORDS = {
    "Lighter fluid": "a dented yellow tin of lighter fluid with a red cap",
    "Antifreeze": "a plastic bottle of blue antifreeze from a garage, label peeling",
    "Rat poison": "a council-issue cardboard box of rat poison, a warning triangle on the side, corner chewed",
    "Car battery": "a car battery with both terminals bare and a short length of cable clipped to one",
    "Road salt": "an open hessian sack of coarse road salt, grey-brown, spilling",
    "Copper wire": "a reel of bare copper wire stripped from a wall, bright where it was cut",
}


def socketable(base):
    return ("A realistic painted pixel-art still-life of %s seen from the front at a slight angle, filling the frame, "
            "worn and dirty, the kind of thing found in a shed." % SOCKET_WORDS[base])


# charms: the one cell kept for luck. Small, worn, one object, lit like a
# thing held in a hand.
CHARM_WORDS = {
    "Lucky penny": "a single old copper penny, worn smooth, green at the rim",
    "Rabbit's foot": "a rabbit's foot on a tarnished keyring chain, fur worn thin",
    "St Christopher": "a St Christopher medal on a thin broken chain, silver gone dull",
    "Horseshoe nail": "a horseshoe nail bent into a ring, iron, rusted",
    "Wedding ring": "a plain gold wedding ring, scratched, slightly out of round",
    "Dog tag": "a single military dog tag on a ball chain, the stamped letters worn",
    "Casino chip": "a casino chip, dark green with a gold edge, the printing scuffed",
    "Bank's own pen": "a bank counter's ballpoint pen on its short bead chain, the chain snapped",
}


def charm(base):
    return ("A realistic painted pixel-art still-life of %s, a single small object filling the frame, seen from above "
            "at a slight angle, lit from one side." % CHARM_WORDS[base])


# one manifest a type; the long guns first, with no style image - what gets
# promoted from them becomes the style reference for everything after
TYPES = [
    ("long_guns", "Primary", lambda b: b not in MELEE_WORDS, long_gun),
    ("handguns", "Secondary", lambda b: b not in MELEE_WORDS, handgun),
    ("helmets", "Helmet", lambda b: True, helmet),
    ("armour", "Armour", lambda b: True, armour),
    ("rigs", "Rig", lambda b: True, bag),
    ("bags", "Backpack", lambda b: True, bag),
    ("medical", "Medical", lambda b: True, medical),
    ("ammo", "Ammo", lambda b: True, ammo),
    ("parts", "Attachment", lambda b: b not in SOCKET_WORDS and b not in MELEE_PARTS, part),
]
# added later (the charm and the sockets): their own seeds, so the earlier
# manifests' seeds don't move
EXTRA = [
    ("sockets", "Attachment", lambda b: b in SOCKET_WORDS, socketable),
    ("charms", "Charm", lambda b: True, charm),
    ("melee", "Primary", lambda b: b in MELEE_WORDS, melee),
    ("melee_small", "Secondary", lambda b: b in MELEE_WORDS, melee),
    ("melee_parts", "Attachment", lambda b: b in MELEE_PARTS, melee_part),
]
SEED_EXTRA = 75000                    # SEED0 + 5000
REFS = ["res://art/reference/items/ref_%02d.png" % i for i in range(1, 5)]
SEED0 = 70000


# the uniques: their base's footprint and view, their own look
UNIQUE_WORDS = {
    "Grandad's shotgun": ("A realistic painted pixel-art still-life of a single old side-by-side farmer's shotgun, seen exactly "
                          "side-on with the muzzle pointing left, laid level and filling the frame left to right: a gun kept "
                          "for sixty years, the walnut stock dark with hand oil and worn pale at the grip, the barrels "
                          "browned, a leather sling repaired with baler twine, initials scratched into the stock plate."),
    "The Postman's bag": ("A realistic painted pixel-art still-life of a single Royal Mail postman's delivery sack converted "
                          "into a rucksack, standing upright as if set down on the floor, seen from the front, filling the "
                          "frame: faded red-and-grey canvas, a cracked crown badge, straps added from an old rucksack, "
                          "stuffed full."),
    "The Doorman's jacket": ("A realistic painted pixel-art still-life of a single black bouncer's jacket with police body "
                             "armour sewn inside it, hung flat as if on a hook, seen from the front, filling the frame top to "
                             "bottom: a nightclub security logo half picked off the chest, armour plate edges showing at the "
                             "seams, cuffs scuffed white."),
    "Lucky cap": ("A realistic painted pixel-art still-life of a single yellow building-site hard hat seen from the front and "
                  "slightly above, resting on nothing, filling the frame top to bottom: covered in faded stickers and biro "
                  "writing, a four-leaf clover painted on the front, a lucky rabbit's foot wired to the strap, badly scratched "
                  "and never replaced."),
    # the bosses'
    "The van's spare": ("A realistic painted pixel-art still-life of a single old six-shot revolver seen exactly side-on with "
                        "the muzzle pointing left, filling the frame: nickel finish worn to brass at the edges, grip wrapped in "
                        "electrical tape, a van key on a ring through the trigger guard."),
    "Underlay": ("A realistic painted pixel-art still-life of a single padded work jacket hung flat as if on a hook, seen from "
                 "the front, filling the frame top to bottom: the lining visibly stuffed with thick grey carpet underlay, "
                 "stitched in by hand with carpet thread, a carpet shop's name on the breast."),
    "The manager's coat": ("A realistic painted pixel-art still-life of a single good dark wool overcoat hung flat as if on a "
                           "hook, seen from the front, filling the frame top to bottom, the front open to show a black "
                           "ballistic vest underneath, a bank's name badge still pinned to the lapel."),
    "The branch pistol": ("A realistic painted pixel-art still-life of a single modern black service pistol with a rail and a "
                          "torch, seen exactly side-on with the muzzle pointing left, filling the frame, a strip of a bank's "
                          "counter-top rubber mat still stuck to the grip."),
    "The quartermaster's rifle": ("A realistic painted pixel-art still-life of a single army marksman rifle with a large scope "
                                  "and a bipod, seen exactly side-on with the muzzle pointing left, laid level and filling the "
                                  "frame left to right, immaculately clean, a stores tag wired to the trigger guard."),
    "Issue webbing": ("A realistic painted pixel-art still-life of a single set of army webbing, a belt and yoke with full "
                      "pouches, standing upright as if set down on the floor, seen from the front, filling the frame, olive "
                      "nylon faded and clean, a folded stores docket showing from one pouch."),
    # the pinnacles' charms and the convoy's
    "The van keys": ("A realistic painted pixel-art still-life of a bunch of van keys on a worn leather fob, a single small "
                     "object filling the frame, seen from above at a slight angle, lit from one side, the brass worn bright."),
    "The manager's pen": ("A realistic painted pixel-art still-life of a single heavy black and gold fountain pen, capped, a small "
                          "object filling the frame, seen from above at a slight angle, lit from one side, the gold worn at the clip."),
    "The quartermaster's ledger": ("A realistic painted pixel-art still-life of a small green cloth-bound army ledger, closed, "
                                   "a single small object filling the frame, seen from above at a slight angle, lit from one side, "
                                   "the corners worn to the board, a pencil under the elastic."),
    "The lorry's load": ("A realistic painted pixel-art still-life of a single large cargo-frame backpack with a green lorry tarp "
                         "lashed over it, standing upright as if set down on the floor, seen from the front, filling the frame, "
                         "banknotes showing at one edge under the tarp."),
}


def unique_jobs(seed):
    jobs = []
    body = re.search(r"const UNIQUES := \[(.*?)\n\]", src, re.S).group(1)
    for name, slot, base in re.findall(r'\{"name": "([^"]+)", "slot": "(\w+)", "base": "([^"]+)"', body):
        w, h = footprint(slot, base)
        jobs.append({
            "out": "art/items/%s.png" % slug(name),
            "endpoint": "generate-image-v2",
            "description": UNIQUE_WORDS[name] + TAIL,
            "width": w * CELL,
            "height": h * CELL,
            "no_background": True,
            "seed": seed,
            "single": True,
            "style_image": REFS[seed % len(REFS)],
            "style_options": {"color_palette": True, "outline": True, "detail": True, "shading": True},
        })
        seed += 1
    return jobs, seed


def main():
    seed = SEED0
    index = []
    for ti, (key, slot, keep, prompt) in enumerate(TYPES + [("uniques", None, None, None)] + EXTRA):
        if (key, slot, keep, prompt) == EXTRA[0]:
            seed = SEED_EXTRA
        jobs = []
        if key == "uniques":
            jobs, seed = unique_jobs(seed)
        for base in (names(slot) if slot else []):
            if not keep(base):
                continue
            w, h = footprint(slot, base)
            # one job a base, written straight to the live name: a job that
            # didn't work is rerun with ++ --only <slug> ++ --force
            job = {
                "out": "art/items/%s.png" % slug(base),
                "endpoint": "generate-image-v2",
                "description": prompt(base) + TAIL,
                "width": w * CELL,
                "height": h * CELL,
                "no_background": True,
                "seed": seed,
                "single": True,
            }
            if key != "long_guns":
                job["style_image"] = REFS[seed % len(REFS)]
                job["style_options"] = {"color_palette": True, "outline": True, "detail": True, "shading": True}
            jobs.append(job)
            seed += 1
        readme = [
            "FIAT GEAR - %s. %d bases, one job each, written straight to the LIVE name art/items/<slug>.png ('single': "
            "one file, no _NN, no sheet, no _response.json). Each job's size is the base's footprint x %d px (data.gd "
            "SIZE / FOOTPRINTS): the game draws the picture at its own pixels, centred, when it fits the cell." % (key.replace("_", " "), len(jobs), CELL),
            "Run: godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_items_%s_manifest.json   "
            "(++ --dry-run to list). A job whose file exists is skipped, so a rerun only does what's missing; one that "
            "came out wrong: ++ --only <slug> ++ --force, or delete the file and rerun." % key,
            "Items.slug(base) is the name: lowercase, runs of anything but a letter or digit become one underscore. The "
            "cells load the file if it exists and show text if not, so the pool fills in any order.",
            "ORDER: run long_guns first - it has no style image. Promote three or four of the best and copy them to "
            "art/reference/items/ref_01.png .. ref_04.png; every other manifest rides those as style_image with every "
            "style option on, rotated, so the whole pool shares the guns' palette and rendering.",
            "If the API refuses a wide aspect (a 5x1 gun is 320x64), regenerate at the same width and twice the height; "
            "the loader fits and centres it.",
            "Regenerate these manifests with python3 tools/make_item_manifests.py after any footprint change.",
        ]
        path = os.path.join(ROOT, "tools", "pixellab_items_%s_manifest.json" % key)
        with open(path, "w", encoding="utf-8") as f:
            json.dump({"_readme": readme, "jobs": jobs}, f, indent=2, ensure_ascii=False)
            f.write("\n")
        index.append((key, len(jobs)))
    for key, jobs in index:
        print("%-12s %3d jobs" % (key, jobs))


if __name__ == "__main__":
    main()
