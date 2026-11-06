"""The County's new bases' pictures (6 Nov; docs/design/county_stages.md §4-5: 24 bases, data.gd C61_NEW_BASES). One
picture a base, 24 jobs, every canvas under 65k px at $0.08.

  python3 tools/make_items_county_manifest.py  -> tools/pixellab_items_county_manifest.json

The item template, as make_items_stages_manifest.py's (make_items29_manifest.py's describe() and job(): the still-life by
slot, the side-on muzzle-left view for guns, TAIL with "no floor, wall, ground or sky around it", ref_01..04 as the style
image, every style option on), at each base's footprint x 64 px (data.gd FOOTPRINTS, else the slot's SIZE). Out straight
to the live name art/items/<slug>.png. Items.art reads a base's picture through Items.art_name (ART_AS first), so these
show only once the 24 ART_AS entries for these bases come off - the wiring step after art.done.

Checked against docs/art/pixellab_lessons.md: the object alone, no setting named ("Cut-out icons must not name a
setting": no road, port, ferry, golf course, manor, vault or Treasury in a look); everything usually printed, branded or
stamped said plain / no lettering / no numbers in its subject (the hi-vis coat, the hard hat, the lifejacket, the duty-free
bag, the evidence bag, the fob, the ingot, the despatch box, the visor); nothing hand-written. Seeds 643000-643023
(checked here and by tools/art_lint.py)."""
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_item_manifests as items  # noqa: E402  (slug, footprint, CELL, src)
import make_items29_manifest as i29  # noqa: E402  (the item template: describe, job, section_of, base_type)

ROOT = i29.ROOT
OWN = "pixellab_items_county_manifest.json"
SEED0 = 643000      # clear of every other manifest's (the County dens 642000-642007)
PLAIN = i29.PLAIN   # "plain, unprinted, no lettering, no numbers, no logo"

# The 24 bases' looks, one line each, from county_stages.md §4 and the item lines (words.gd). "# LESSON" marks the lesson
# a look answers.
LOOKS = {
    # Primary / Secondary
    "Lashing bar": "a long heavy steel lashing bar for container twist-locks: a straight thick steel rod with a hooked "
                   "forked end and a flattened handle end, grey and scraped, " + PLAIN,
    "Sidelock shotgun": "a fine side-by-side double-barrelled shotgun with a figured walnut stock, two long blued barrels "
                        "and engraved steel side plates with scrollwork and no lettering or names",       # LESSON: engraving invites a maker's name
    "Bullion carbine": "a short black and grey carbine with a folding stock, a short barrel and a straight magazine, "
                             + PLAIN,                                                                    # LESSON: guns are stamped
    "Loading hook": "a docker's cargo hook: a curved pointed steel hook coming out between the fingers of a wooden "
                    "T-shaped cross handle, worn smooth",
    # Helmet
    "Crane driver's hat": "a white plastic safety hard hat with a peak and a chin strap, scuffed, no stickers, " + PLAIN,   # LESSON: hard hats carry logos
    "Deerstalker": "a brown and green check tweed deerstalker hat with a peak front and back and its ear flaps tied up on top",
    "Cashier's visor": "a green celluloid eyeshade visor on a thin elastic band",
    "Treasury guard's helmet": "a polished dark steel ceremonial guard's helmet with a small crest ridge and a chin strap, "
                               "no badge, " + PLAIN,                                                     # LESSON: helmets carry badges
    # Armour
    "Highways coat": "an orange high-visibility waterproof coat with two plain grey reflective bands round the body and "
                     "arms, a hood rolled into the collar, " + PLAIN,                                    # LESSON: hi-vis carries lettering
    "Shooting jacket": "a brown tweed shooting jacket with a suede shoulder patch on the right and bellows pockets",
    "Enforcement vest": "a heavy black stab-proof vest with a high collar and a plain black panel on the front, no "
                        "badges, " + PLAIN,                                                              # LESSON: enforcement vests carry lettering
    "Estate tweeds": "a three-piece suit in heathery green estate tweed: a jacket and waistcoat laid together with "
                     "breeches folded beneath them",
    # Gloves
    "Examiner's gloves": "a pair of thin blue nitrile examination gloves, one laid over the other, " + PLAIN,
    "Clerk's mitts": "a pair of black knitted fingerless wool mitts, the fingers cut off at the knuckle, laid side by side",
    # Rig
    "Picker's harness": "a light grey nylon chest harness with shoulder straps, a holster pouch for a handheld scanner and "
                        "two small pouches, " + PLAIN,                                                   # LESSON: usually branded
    "Ferry lifejacket": "an orange inflatable ferry lifejacket worn flat as a collar and front panels, a whistle on a cord, "
                       "two small pouches, " + PLAIN,                                                    # LESSON: lifejackets carry printing
    # Backpack
    "Cartridge bag": "a leather and canvas cartridge bag with a brass clasp on its flap and a long worn leather strap",
    "Duty-free bag": "a clear plastic tamper-evident shopping bag sealed across the top, bottles and boxes inside it, the "
                     "bag and everything in it " + PLAIN,                                                # LESSON: duty-free bags and what's in them are printed
    "Seizure bag": "a large clear plastic evidence bag sealed with a strip across its top, bundles of plain grey-green "
                   "notes and a small plain box inside it, the bag " + PLAIN,                            # LESSON: evidence bags carry printed panels; notes plain
    "Despatch box": "a red leather despatch box with rounded corners, a brass lock and a brass carrying handle, no crest, "
                    + PLAIN,                                                                             # LESSON: despatch boxes carry a crest and lettering
    # Charm
    "Cat's eye": "a single road reflector stud: a rubber-cased block in a cast iron base with two round glass reflectors "
                 "set in its face",
    "Gate fob": "a small black plastic key fob with one plain grey button, on a steel ring, " + PLAIN,
    "Seized keys": "a large steel key ring crowded with many different keys, no tags, no labels",       # LESSON: a tag invites a number
    "Small ingot": "a small gold bar, smooth and plain with rounded edges, no stamp, no lettering, no numbers",   # LESSON: ingots carry stamps
}


def c61_bases():
    m = re.search(r"const C61_NEW_BASES := \[(.*?)\]", items.src, re.S)
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
    want = c61_bases()
    assert sorted(want) == sorted(LOOKS), "LOOKS aren't data.gd's C61_NEW_BASES: missing %s, extra %s" % (
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
        sys.exit("on disk already (a new name was expected): %s" % on_disk)
    over = [j["out"] for j in jobs if j["width"] * j["height"] > 65536]
    assert not over, "over the $0.08 band: %s" % over
    readme = [
        "FIAT ITEMS, THE COUNTY (6 Nov; docs/design/county_stages.md §4-5): the 24 new bases' pictures, %d jobs, all at "
        "$0.08 (every canvas under 65k px; about $%.2f)." % (len(jobs), 0.08 * len(jobs)),
        "The item template of make_items29_manifest.py, straight to the live name art/items/<slug>.png. They show once the "
        "24 ART_AS entries for these bases come off (data.gd; Items.art_name reads ART_AS first) - the wiring step. ++ --parallel 3.",
        "Regenerate with python3 tools/make_items_county_manifest.py; check with python3 tools/art_lint.py.",
    ]
    with open(os.path.join(ROOT, "tools", OWN), "w", encoding="utf-8") as f:
        json.dump({"_readme": readme, "jobs": jobs}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    from collections import Counter
    print("items county: %d jobs (%s), seeds %d-%d" % (len(jobs), ", ".join("%s %d" % kv for kv in Counter(
        j["_where"].split(",")[0] for j in jobs).items()), SEED0, seed - 1))


if __name__ == "__main__":
    main()
