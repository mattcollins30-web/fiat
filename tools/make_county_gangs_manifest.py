"""The County's crews (26 Oct, Matt: "did we generate new enemies for the new zones ... if existing then generate a new
manifest for all new enemy types required"). Till now a County place's gang is its host site's zone's (the Services' a
City crew, the Bank's a Town crew); these are the Issuer's own people, a crew a zone, as the first campaign's are made
(tools/pixellab_people_all_manifest.json's faces, tools/pixellab_fight_manifest.json's figures): a face for the crew,
and two members (a, b), each standing, firing and going down. RunView draws them on a County run once they're on disk
(run_view.gd county_gang), else the host's.

Written, not run: Matt's go first (credits). Three manifests, in this order (the art runner's lesson, 26 Oct: a figure
references the face, a pose the standing figure - run each step only once the one before is on disk):

  tools/pixellab_county_gangs_faces_manifest.json   - 4 faces, art/people/gang_<zone>.png 128x128
  tools/pixellab_county_gangs_stands_manifest.json  - 8 standing figures, art/fight/gang_<zone>_<a|b>_stand.png 128x192
  tools/pixellab_county_gangs_poses_manifest.json   - 16 poses (fire, down), referencing the standing figure

28 jobs in all at the small rate. Seeds SEED0 on (checked against every other manifest: it stops on a clash).

Run: python3 tools/make_county_gangs_manifest.py (then python3 tools/art_lint.py), then in turn:
  tools\\art.bat county_gangs_faces
  tools\\art.bat county_gangs_stands
  tools\\art.bat county_gangs_poses"""
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEED0 = 120000
POSE_SEED0 = 120100   # the poses' own seeds (26 Oct, the runner: a pose shared its stand's seed - no two jobs share one)
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}
OWN = ("pixellab_county_gangs_faces_manifest.json", "pixellab_county_gangs_stands_manifest.json", "pixellab_county_gangs_poses_manifest.json")
FIG_TAIL = ("One person alone, full body head to feet, facing the viewer, centred, filling the frame top to bottom, plain "
            "dark neutral background. Realistic painted pixel art, soft overcast light, muted cool northern palette, worn "
            "and lived-in, post-collapse Britain on a grey day; no black outlines, not anime, not a cartoon, not glossy; no "
            "text, no logos, no lettering or badges on any clothing.")

# A zone's crew: (the zone's key as RunView names it, the face's words, member a: [who, weapon, held], member b: [...]).
# Every uniform plain: no lettering, badges or numbers (the lessons: printed things come back printed).
CREWS = [
    ("the_motorway", "an enforcement agent of the Issuer's road gangs: a plain hi-vis tabard with no lettering over a stab vest, a body camera, a "
     "shaved head and a two-day beard, the look of a man who's clamped a thousand cars",
     ["an enforcement agent of the Issuer's road gangs: a plain hi-vis tabard with no lettering over a stab vest, a body camera, "
      "a shaved head, cargo trousers, work boots", "a pump shotgun"],
     ["a tow-truck driver turned enforcer: a quilted plain hi-vis jacket with no lettering, a plain hard hat with no markings, heavy gloves, a crowbar through his belt",
      "a heavy revolver"]),
    ("the_docks", "a port customs officer working for the Issuer: a plain dark uniform jacket, a flat cap with no badge, reading "
     "glasses pushed up, a face weighing up whoever stands in front of it",
     ["a port customs officer working for the Issuer: a plain dark uniform jacket and trousers, a flat cap with no badge, a "
      "plain clipboard with blank pages, no writing, clipped to his belt", "a compact pistol"],
     ["a docker turned guard: a donkey jacket, a woolly hat, ear defenders round the neck, rigger boots, a hi-vis vest with "
      "no lettering", "a submachine gun"]),
    ("the_big_houses", "a private security man from the big houses: a black suit, an earpiece, close-cropped grey hair, a "
     "signet ring, a face that has thrown people off driveways",
     ["a private security man from the big houses: a black suit, an earpiece, a plain black tie, polished shoes, a holster "
      "under the jacket", "a pistol"],
     ["an estate keeper for the big houses: a wax jacket, a tweed flat cap, a checked shirt, breeches and boots",
      "a side-by-side shotgun"]),
    ("the_treasury", "a Treasury guard: a dark high-collared tunic with plain brass buttons, a peaked cap with no badge, a "
     "neat moustache, a face that has stood very still for a long time",
     ["a Treasury guard: a dark high-collared tunic with plain brass buttons, a peaked cap with no badge, white gloves, "
      "polished boots", "a bolt-action rifle"],
     ["a Treasury riot officer: plain black body armour with no lettering or patches, a visored helmet with no markings, a clear riot shield with no lettering on one arm",
      "a short carbine"]),
]


def used_seeds():
    seen = {}
    for path in glob.glob(os.path.join(ROOT, "tools", "pixellab_*manifest.json")):
        if os.path.basename(path) in OWN:
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
    faces, stands, poses = [], [], []
    seed = SEED0
    pose_seed = POSE_SEED0
    for zone, face, a, b in CREWS:
        face_path = "res://art/people/gang_%s.png" % zone
        faces.append({"out": "art/people/gang_%s.png" % zone, "endpoint": "generate-image-v2", "width": 128, "height": 128,
                      "no_background": False, "single": True, "seed": seed, "style_image": "res://art/people/fence.png",
                      "style_options": STYLE,
                      "description": "A realistic painted pixel-art portrait, head and shoulders, of " + face + ". Looking just "
                      "past the viewer. Post-collapse Britain, grey light. One person centred, filling the frame, no text, no "
                      "border, no lettering or badges, plain dark background.",
                      "_where": "the %s crew's face" % zone})
        seed += 1
        for tag, (who, gun) in (("a", a), ("b", b)):
            stand_out = "art/fight/gang_%s_%s_stand.png" % (zone, tag)
            base = {"width": 128, "height": 192, "no_background": True, "seed": seed, "endpoint": "generate-image-v2",
                    "single": True, "style_options": STYLE, "style_image": face_path}
            first = who[0].upper() + who[1:] if tag == "a" else "A second of the same crew, " + who
            stands.append(dict(base, out=stand_out, _where="the %s crew, %s: standing" % (zone, tag),
                               description=first + ", standing wary, " + gun + " held across the body at the ready, not aimed. " + FIG_TAIL))
            ref = ["res://" + stand_out]
            poses.append(dict(base, out="art/fight/gang_%s_%s_fire.png" % (zone, tag), reference_images=ref, seed=pose_seed,
                              _where="the %s crew, %s: firing at you" % (zone, tag),
                              description="The same person as the reference image: " + who + ", aiming " + gun + " straight at the viewer, the weapon held firmly in both hands, a bright muzzle flash. " + FIG_TAIL))
            poses.append(dict(base, out="art/fight/gang_%s_%s_down.png" % (zone, tag), reference_images=ref, seed=pose_seed + 1,
                              _where="the %s crew, %s: hit, going down" % (zone, tag),
                              description="The same person as the reference image: " + who + ", hit and falling backwards, arms flung out, what they held dropping. " + FIG_TAIL))
            seed += 1
            pose_seed += 2
    every = faces + stands + poses
    used = used_seeds()
    clash = {j["seed"]: used[j["seed"]] for j in every if j["seed"] in used}
    if clash:
        sys.exit("seeds already used elsewhere: %s - move SEED0" % clash)
    common = ["The County's crews: a face a zone (art/people/gang_<zone>.png) and two members' standing, firing and going-down figures (art/fight/gang_<zone>_<a|b>_<pose>.png). RunView draws them on a County run (run_view.gd county_gang), else the host site's crew.",
              "Regenerate with python3 tools/make_county_gangs_manifest.py; check with python3 tools/art_lint.py."]
    steps = [("faces", faces, "1 of 3: the four faces"), ("stands", stands, "2 of 3: the eight standing figures (each references its crew's face - run once the faces are on disk)"),
             ("poses", poses, "3 of 3: the sixteen poses (each references its standing figure - run once the stands are on disk)")]
    for (name, jobs, words), fname in zip(steps, OWN):
        m = {"_readme": ["FIAT, THE COUNTY'S CREWS (26 Oct), step " + words + ": %d jobs." % len(jobs),
                         "Run: tools\\art.bat county_gangs_%s (the dry run first, then it asks)" % name] + common, "jobs": jobs}
        with open(os.path.join(ROOT, "tools", fname), "w", encoding="utf-8", newline="\n") as f:
            json.dump(m, f, indent=1, ensure_ascii=False)
    print("county crews: %d faces, %d stands, %d poses (%d jobs), seeds %d-%d" % (len(faces), len(stands), len(poses), len(every), SEED0, pose_seed - 1))


if __name__ == "__main__":
    main()
