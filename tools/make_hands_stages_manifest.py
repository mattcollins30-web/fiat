"""The fight's hands for the stages' new weapons (6 Nov, Matt: "include the new backdrops and items from yesterday";
docs/design/stages.md §5): every Primary/Secondary among data.gd's C55_NEW_BASES - the Garden fork, the Bone saw, the
Humane killer and the Scalpel - one picture each at art/fight/hands/<slug>.png (280x210, $0.08 each).

  python3 tools/make_hands_stages_manifest.py  -> tools/pixellab_hands_stages_manifest.json

The job is the 6 Nov reroll's template (tools/pixellab_reroll_6nov_manifest.json), not hands_job's: no style_image (a
side-on item icon as the style image wins over the words - the 6 Nov lesson: six hands came back side-on), the weapon
described in words with what it is not, big_revolver.png kept as the reference for the view, "one weapon only" and the
hands counted. A blade or the fork: the point or blade towards the scene, held in the right hand with the left forward
(the fork two-handed, like a spear). No long gun among them, so no "stock low" line.

RunView.hands_tex reads a base's hands through Items.art_name (ART_AS first): they show once the four ART_AS entries come
off (the wiring step after art.done). Until then the borrowed base's hands (Billhook, Machete, Derringer, Knife) show.

Checked against docs/art/pixellab_lessons.md: guns down the barrel with the revolver as reference and "not a side view,
not in profile"; no side-on style image; no setting; the out is the live art/fight/hands/ folder (new names - nothing on
disk is overwritten); seeds 614000-614003, clear of every manifest (checked here and by tools/art_lint.py)."""
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_fight_kit_manifest as fk  # noqa: E402  (bases, kind, slug, the hands size)

ROOT = fk.ROOT
OWN = "pixellab_hands_stages_manifest.json"
SEED0 = 614000      # clear of every other manifest's (the stage items 613000-613023)
REF = "res://art/fight/hands/big_revolver.png"
OPEN = "First-person view of the player's own two hands in fingerless wool gloves holding "
SLEEVES = ("coming in from the bottom right corner of the frame, as in a light-gun arcade game; the sleeves of a worn work "
           "jacket at the wrists.")
GUN_VIEW = ("Seen from behind and just above the weapon, looking straight down the barrel, strongly foreshortened: the muzzle "
            "points away into the scene towards the middle of the frame and the back of the weapon comes towards the viewer "
            "at the bottom right; not a side view, not in profile. The same viewpoint, framing and grip as the reference "
            "image of the revolver. One weapon only, held by exactly two hands.")
BLADE_VIEW = ("Seen from behind and just above the right hand, strongly foreshortened: the %s points away into the scene "
              "towards the middle of the frame and the handle comes towards the viewer at the bottom right; not a side view, "
              "not in profile. The same viewpoint and framing as the reference image of the revolver. One %s only, and "
              "exactly two hands: the right hand holding it, the left hand empty and held forward.")
FORK_VIEW = ("Seen from behind and just above the hands, strongly foreshortened: the tines point away into the scene towards "
             "the middle of the frame and the handle comes towards the viewer at the bottom right; not a side view, not in "
             "profile. The same viewpoint and framing as the reference image of the revolver. One fork only, held by exactly "
             "two hands.")
CLOSE = "Only the hands and what they hold, coming in from the bottom right edge. " + fk.TAIL

# name: (what's held and how - the weapon in words, what it is not; the view)
WORDS = {
    "Garden fork": ("a single garden digging fork with four steel tines, a wooden shaft and a D-shaped wooden handle, held "
                    "forward low like a spear, the right hand on the D-handle and the left hand round the shaft near the "
                    "tines - a fork, not a pitchfork, not a rake", FORK_VIEW),
    "Bone saw": ("a single surgeon's bone saw with a steel bow frame over a fine-toothed straight blade and a dark wooden "
                 "handle, held forward in the right hand ready to saw, the left hand empty and held forward - a bow saw, "
                 "not a hacksaw, not a knife", BLADE_VIEW % ("blade", "saw")),
    "Humane killer": ("a single slaughterman's captive-bolt pistol: a fat short steel cylinder with a flat round muzzle and a "
                      "short plain grip under its back end, held out forward in both hands wrapped together round its one "
                      "grip - a stunning tool, not a revolver, not a torch, no cylinder, no magazine", GUN_VIEW),
    "Scalpel": ("a single small steel surgical scalpel with a flat handle and a short curved blade, held low and forward in "
                "the right hand like a knife, the left hand empty and held forward - small and thin, not a "
                "kitchen knife, not a dagger", BLADE_VIEW % ("blade", "scalpel")),
}


def c55_weapons():
    """C55_NEW_BASES that are Primary/Secondary (the weapons the fight draws in hand): [slot, name, type, ammo, bleed]."""
    s = open(os.path.join(ROOT, "scripts", "sim", "data.gd"), encoding="utf-8").read()
    new = re.findall(r'"([^"]+)"', re.search(r"const C55_NEW_BASES := \[(.*?)\]", s, re.S).group(1))
    return [b for b in fk.bases() if b[1] in new]


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
    weapons = c55_weapons()
    assert sorted(b[1] for b in weapons) == sorted(WORDS), "the new weapons are %s" % [b[1] for b in weapons]
    jobs = []
    seed = SEED0
    for slot, name, t, ammo, bleed in weapons:
        held, view = WORDS[name]
        k = fk.kind(t, ammo, bleed)
        jobs.append({"out": "art/fight/hands/%s.png" % fk.slug(name), "width": fk.HANDS_W, "height": fk.HANDS_H,
                     "no_background": True, "seed": seed, "endpoint": "generate-image-v2", "single": True,
                     "style_options": fk.STYLE, "reference_images": [REF],
                     "description": OPEN + held + ", " + SLEEVES + " " + view + " " + CLOSE,
                     "_where": "your hands: %s (%s; falls back to hands_%s) - the stages' new weapon, the 6 Nov reroll's template" % (name, slot.lower(), k)})
        seed += 1
    used = used_seeds()
    clash = {j["seed"]: used[j["seed"]] for j in jobs if j["seed"] in used}
    if clash:
        sys.exit("seeds already used elsewhere: %s - move SEED0" % clash)
    on_disk = [j["out"] for j in jobs if os.path.exists(os.path.join(ROOT, j["out"]))]
    if on_disk:
        sys.exit("on disk already (a new name was expected): %s" % on_disk)
    readme = [
        "FIAT HANDS, THE STAGES (6 Nov, Matt: \"include the new backdrops and items from yesterday\"): the fight's hands for "
        "the stages' %d new weapons, 280x210 at $0.08 each (about $%.2f)." % (len(jobs), 0.08 * len(jobs)),
        "The 6 Nov reroll's template: no style_image, the weapon in words, big_revolver.png the reference. Straight to "
        "art/fight/hands/<slug>.png; they show once the ART_AS entries for these bases come off (the wiring step).",
        "Regenerate with python3 tools/make_hands_stages_manifest.py; check with python3 tools/art_lint.py.",
    ]
    with open(os.path.join(ROOT, "tools", OWN), "w", encoding="utf-8") as f:
        json.dump({"_readme": readme, "jobs": jobs}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print("hands stages: %d jobs (%s), seeds %d-%d" % (len(jobs), ", ".join(j["out"].split("/")[-1] for j in jobs), SEED0, seed - 1))


if __name__ == "__main__":
    main()
