"""FIAT HANDS 29 (29 Oct): the fight's hands for the itemisation's new weapons - every Primary/Secondary base in
make_items29_manifest.py's LOOKS, one picture each at art/fight/hands/<slug>.png (280x210, $0.08 each).

Before this, the 78 new weapons fell back to their kind's picture (hands_<kind>.png) - RunView.hands_tex finds a base's
own picture by slug, so nothing to wire. The job is make_fight_kit_manifest.hands_job's, unchanged: guns down the barrel
framed on the big revolver's hands, long guns' stock low, melee off its kind's picture; the base's stash picture (the
items29 run) as the style image - so this runs AFTER pixellab_items29_manifest.json.

Checked against docs/art/pixellab_lessons.md: guns down the barrel with the revolver as reference; a side-on style image
gives "its parts and colours, but turned to point away" (hands_job's words); stocks low; the stash pictures drawn in a case
or holster say the weapon alone, out of it (a case would come back in the hands); no setting; seeds of their own
(128xxx). Matt, 29 Oct: no test batch - hands are an established template, a wrong one is rerolled.

Regenerate with python3 tools/make_hands29_manifest.py; check with python3 tools/art_lint.py."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_fight_kit_manifest as fk  # noqa: E402  (hands_job, bases, HOLD_OF, slug)
import make_items29_manifest as i29  # noqa: E402  (LOOKS: the new bases)

ROOT = fk.ROOT
SEED0 = 128000

# shapes the kind's hold doesn't fit (fk.HOLD_OF's way)
HOLD_29 = {
    "Bike chain": "swung forward in the right hand, the chain looping out ahead, its taped end wrapped round the fist, the other hand held out for balance",
    "Cattle prod": "held forward in both hands like a spear, its two metal prongs at the tip pointing up the frame",
    "Platelayer's maul": "raised in both hands over the right shoulder, ready to swing down",
    "Collier's pick": "raised in both hands over the right shoulder, ready to swing down",
    "Felling axe": "raised in both hands over the right shoulder, ready to swing",
    "Speargun": "held forward in both hands, the steel spear pointing straight ahead into the scene, its rubber bands stretched",
    "Compound bow": "drawn, the bow held upright at arm's length in the left hand, the right hand pulling the string back, the arrow pointing straight ahead into the scene",
    "Punt gun": "braced at the hip in both hands, its huge barrel as long as a man pointing straight ahead into the scene, the rope breeching loop trailing back",
    "Bench-made autocannon": "braced at the hip in both hands, its box magazine underneath, the stubby barrel pointing straight ahead into the scene",
    "Catapult": "held out at arm's length in the left hand, the right hand drawing the leather pouch back toward the viewer",
    "Bike lock": "raised in the right hand by one end of its D, ready to swing, the other hand held out for balance",
    "Screwdriver": "held low and forward in the right hand, the sharpened tip up, the left hand out for balance",
    "Commando dagger": "held low and forward in the right hand, the blade up, the left hand out for balance",
    "Wheel brace": "raised in the right hand by one arm of the cross, ready to swing, the other hand held out for balance",
    "Extendable baton": "raised in the right hand, fully extended, ready to swing, the other hand held out for balance",
    "Pen gun": "held out forward in the right hand like a pistol, the nib end pointing straight ahead into the scene",
    # 30 Oct, Matt: came out side-on, not down the barrel - the long barrel foreshortened to a stub, its muzzle toward us
    "Goose gun": "shouldered, its very long barrel pointing straight away from the viewer into the middle of the frame, foreshortened to a short stub with the round muzzle facing us, the stock low in the bottom right corner",
    "Castle guard rifle": "shouldered, the barrel pointing straight away from the viewer into the middle of the frame, foreshortened to a short stub with the muzzle facing us, the stock low in the bottom right corner",
    "Hunting revolver": "held out forward in both hands at eye level, the long barrel pointing straight away from the viewer, foreshortened so the muzzle sits just above the cylinder and faces us",
    "Broomhandle pistol": "held out forward in both hands at eye level, the barrel pointing straight away from the viewer, foreshortened so the muzzle sits just above the box magazine and faces us, the wooden stock tucked low",
}
SEED_BUMP_29 = {"Goose gun": 2000, "Castle guard rifle": 2000, "Hunting revolver": 2000, "Broomhandle pistol": 2000}     # the 30 Oct rerolls: a fixed seed rerolls near the same
# their stash pictures show them in a case or holster: the hands hold the weapon alone
OUT_OF_CASE = {"Ambassador's revolver", "Consular PDW", "Police revolver", "Pocket pistol"}
OUT_WORDS = " The weapon alone, out of its case or holster: no case, holster or box anywhere."


def main():
    fk.HOLD_OF.update(HOLD_29)
    by_name = dict((b[1], b) for b in fk.bases())
    jobs = []
    seed = SEED0
    for name in i29.LOOKS:
        b = by_name.get(name)
        if b is None:      # not a weapon (helmets, armour, rigs, packs, charms, gloves)
            continue
        slot, n, t, ammo, bleed = b
        j = fk.hands_job(slot, n, t, ammo, bleed, seed + SEED_BUMP_29.get(name, 0))
        assert j["seed"] == seed + SEED_BUMP_29.get(name, 0), "a fight-kit seed override caught %s" % name
        if name in OUT_OF_CASE:
            j["description"] = j["description"].replace(" Only the hands and what they hold", OUT_WORDS + " Only the hands and what they hold", 1)
            assert OUT_WORDS in j["description"], name
        jobs.append(j)
        seed += 1
    assert len(jobs) == 78, len(jobs)
    readme = [
        "FIAT HANDS 29 (29 Oct): the fight's hands for the itemisation's %d new weapons, 280x210 at $0.08 each (about $%.2f). "
        "Straight to art/fight/hands/<slug>.png (RunView.hands_tex finds them by slug; nothing to wire)." % (len(jobs), 0.08 * len(jobs)),
        "Style images are the items29 stash pictures: run AFTER tools/pixellab_items29_manifest.json. ++ --parallel 3.",
        "No test batch (Matt, 29 Oct: an established template; a wrong one is rerolled).",
        "Regenerate with python3 tools/make_hands29_manifest.py; check with python3 tools/art_lint.py.",
    ]
    with open(os.path.join(ROOT, "tools", "pixellab_hands29_manifest.json"), "w", encoding="utf-8") as f:
        json.dump({"_readme": readme, "jobs": jobs}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    from collections import Counter
    print("hands29: %d jobs (%s)" % (len(jobs), ", ".join("%s %d" % kv for kv in Counter(j["_where"].split("hands_")[-1].rstrip(")") for j in jobs).items())))


if __name__ == "__main__":
    main()
