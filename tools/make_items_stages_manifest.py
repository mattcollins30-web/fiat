"""The stages' new bases' pictures (6 Nov, Matt: "include the new backdrops and items from yesterday - just drop the
flag when ready"; docs/design/stages.md §5, "As built": 24 bases, data.gd C55_NEW_BASES). One picture a base, 24 jobs.

  python3 tools/make_items_stages_manifest.py  -> tools/pixellab_items_stages_manifest.json

The item template, as make_items29_manifest.py's (its describe() and job(): the still-life by slot, the side-on
muzzle-left view for guns, from above for melee, TAIL with "no floor, wall, ground or sky around it", ref_01..04 as the
style image, every style option on), at each base's footprint x 64 px (data.gd FOOTPRINTS, else the slot's SIZE). Out
straight to the live name art/items/<slug>.png. Items.art reads a base's picture through Items.art_name (ART_AS first),
so these show only once the 24 ART_AS entries for these bases come off - the wiring step after art.done.

Checked against docs/art/pixellab_lessons.md: the object alone, no setting named ("Cut-out icons must not name a
setting": no garden, bank, hospital, arcade or barracks in a look); everything usually printed, branded or written on
said plain / no lettering / no numbers in its subject (the bank bag, the wristband, the cap badge, the helmets, the
hi-vis, the fleece, the mascot suit, the scalpel's handle); "British" where a coin-like thing would come out American
(the arcade token); nothing hand-written. Seeds 613000-613023 (checked here and by tools/art_lint.py)."""
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_item_manifests as items  # noqa: E402  (slug, footprint, CELL, src)
import make_items29_manifest as i29  # noqa: E402  (the item template: describe, job, section_of, base_type)

ROOT = i29.ROOT
OWN = "pixellab_items_stages_manifest.json"
SEED0 = 613000      # clear of every other manifest's (the stage plates 612000-612023)
PLAIN = i29.PLAIN   # "plain, unprinted, no lettering, no numbers, no logo"

# The 24 bases' looks, one line each, from stages.md §5 and the language pass's names. "# LESSON" marks the lesson a look
# answers.
LOOKS = {
    # Primary / Secondary
    "Garden fork": "a four-tined garden digging fork with a wooden shaft and a D-shaped wooden handle, soil dried on its tines",
    "Bone saw": "a surgeon's bone saw with a steel bow frame, a fine-toothed blade and a dark wooden handle, no markings",
    "Humane killer": "a slaughterman's captive-bolt pistol: a fat short steel cylinder with a flat round muzzle and a short "
                     "plain grip under its back end, " + PLAIN,                          # LESSON: tools are stamped
    "Scalpel": "a single steel surgical scalpel with a flat ribbed handle and a small curved blade, no numbers or markings on it",   # LESSON: scalpel handles carry numbers
    # Helmet
    "Flat cap": "a grey-brown herringbone tweed flat cap",
    "Strimmer visor": "a wire-mesh face visor on an orange plastic headband with ear defenders on its sides, " + PLAIN,   # LESSON: usually branded
    "Delivery rider's helmet": "a scuffed full-face motorcycle helmet with a dark tinted visor, no stickers, " + PLAIN,   # LESSON: usually branded
    "Go-kart helmet": "a small full-face karting helmet in faded red and white, no stickers, " + PLAIN,                    # LESSON: race numbers
    # Armour
    "Donkey jacket": "a black wool donkey jacket with a plain black leather yoke across the shoulders, no lettering",    # LESSON: council yokes are lettered
    "Staff fleece": "a dark green zip-up fleece with no name badge, " + PLAIN,                                            # LESSON: staff fleeces carry a logo
    "Waxed coat": "an olive waxed cotton country coat with a brown cord collar and big bellows pockets, plain, no maker's badge, label or lettering on it",
    "Lined hoodie": "a grey zip-up hoodie with a thick cream fleece lining showing at the open front, " + PLAIN,           # LESSON: usually printed
    "Sheepskin coat": "a long brown sheepskin coat with a shaggy cream fleece collar and cuffs",
    "Mascot suit": "an empty furry animal mascot costume in faded yellow, its big round head off and hanging at its side, " + PLAIN,   # LESSON: mascots carry a club's lettering
    # Gloves
    "Rose gauntlets": "a pair of long thorn-proof tan leather gardening gauntlets with cuffs to the elbow",
    # Rig
    "Joiner's apron": "a heavy brown canvas joiner's apron with a row of nail pockets across the front, a hammer loop and a pencil in a pocket",
    "Hi-vis tabard": "a fluorescent yellow hi-vis tabard with two plain silver reflective bands round it, no lettering",   # LESSON: hi-vis bands carry POLICE
    "Security van vest": "a heavy grey armoured vest with a high collar, a plain grey chest panel and a radio pouch, "
                         "no lettering, badges or logos anywhere",                        # LESSON: "SECURITY in white" is lettering
    # Backpack
    "Bank bag": "a plain heavy grey canvas bank bag with a brass zip and a small padlock through the zip pull, " + PLAIN,   # the brief: plain, no lettering
    "Grab bag": "a red emergency grab-bag rucksack with grey reflective strips and a grab handle, a plain white cross patch, no lettering",   # LESSON: usually lettered
    # Charm
    "Arcade token": "a single British brass arcade token, plain on both faces with a milled edge and a hole punched "
                    "through its middle, no head, no lettering, no numbers",              # LESSON: coins come out American; plain
    "Branch key": "a single long heavy brass safe-deposit key with a deep-cut bit and a round bow, on a small plain steel ring, no tag",   # LESSON: a tag invites a number
    "Hospital wristband": "a hospital patient wristband: a thin plain white plastic band fastened in a loop with a press "
                          "stud, blank, no writing, no barcode, no lettering",          # the brief: blank band, no writing
    "Cap badge": "a plain brass regimental cap badge, a crown over a laurel wreath, no lettering, no motto scroll",       # the brief: no lettering
}


def c55_bases():
    m = re.search(r"const C55_NEW_BASES := \[(.*?)\]", items.src, re.S)
    return re.findall(r'"([^"]+)"', m.group(1))


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
    want = c55_bases()
    assert sorted(want) == sorted(LOOKS), "LOOKS aren't data.gd's C55_NEW_BASES: missing %s, extra %s" % (
        sorted(set(want) - set(LOOKS)), sorted(set(LOOKS) - set(want)))
    jobs = []
    seed = SEED0
    for name in want:
        slot = i29.section_of(name)
        assert slot, "not a base in data.gd: %s" % name
        w, h = items.footprint(slot, name)
        jobs.append(i29.job("art/items/%s.png" % items.slug(name), slot, name, LOOKS[name], seed,
                            "%s, %s, %dx%d cells (borrows ART_AS's picture till this lands)" % (slot, i29.base_type(name) or "-", w, h)))
        seed += 1
    used = used_seeds()
    clash = {j["seed"]: used[j["seed"]] for j in jobs if j["seed"] in used}
    if clash:
        sys.exit("seeds already used elsewhere: %s - move SEED0" % clash)
    on_disk = [j["out"] for j in jobs if os.path.exists(os.path.join(ROOT, j["out"]))]
    if on_disk:
        print("warning: on disk already (skipped by the batch unless --force): %s" % on_disk)
    over = [j["out"] for j in jobs if j["width"] * j["height"] > 65536]
    assert not over, "over the $0.08 band: %s" % over
    readme = [
        "FIAT ITEMS, THE STAGES (6 Nov, Matt: \"include the new backdrops and items from yesterday\"; docs/design/stages.md "
        "§5): the 24 new bases' pictures, %d jobs, all at $0.08 (every canvas under 65k px; about $%.2f)." % (len(jobs), 0.08 * len(jobs)),
        "The item template of make_items29_manifest.py, straight to the live name art/items/<slug>.png. They show once the "
        "24 ART_AS entries for these bases come off (data.gd; Items.art_name reads ART_AS first) - the wiring step. ++ --parallel 3.",
        "Regenerate with python3 tools/make_items_stages_manifest.py; check with python3 tools/art_lint.py.",
    ]
    with open(os.path.join(ROOT, "tools", OWN), "w", encoding="utf-8") as f:
        json.dump({"_readme": readme, "jobs": jobs}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    from collections import Counter
    print("items stages: %d jobs (%s), seeds %d-%d" % (len(jobs), ", ".join("%s %d" % kv for kv in Counter(
        j["_where"].split(",")[0] for j in jobs).items()), SEED0, seed - 1))


if __name__ == "__main__":
    main()
