"""Milestone 8's art (24 Oct, Matt: "anything else parked plus art for everything new"). Two manifests:

  python3 tools/make_skills_art_manifest.py
    -> tools/pixellab_skills_art_test_manifest.json   (8: the Recruit's face, one emblem, four skills, two nodes)
    -> tools/pixellab_skills_art_manifest.json        (the lot, the test's jobs included)

  C:\\Godot\\godot.console.exe --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_skills_art_manifest.json ++ --parallel 3
  (++ --dry-run to list; one that came out wrong: ++ --only <name> ++ --force)

What's in it, and where each lands (every file new; nothing on disk is overwritten):
- The 48 skills' pictures (art/skills/<id>.png, 64 px, transparent): the fight's buttons, the Runs card and the picker
  find them by id (SkillBar.picture), and the web's skill nodes draw the same picture (web_view). The web art's
  node template (make_web_art_manifest.node_job: its ICON tail, style and references), out to art/skills/.
- The Recruit's tree (art/nodes/<slug>.png, 64 px): his eleven notables, keystones and capstones, and his two halves in
  Blades and Knuckles. Found by name, no wiring.
- The Recruit's two emblems (art/web/region_ordnance.png, region_drill.png, 96 px), as the other class lanes'.
- The Recruit's face (art/people_new/recruit.png, 128) and figure (art/body_new/body_recruit.png, 208 x 488): People and
  Body read those paths first; the wheel's portrait is cut from the face. Run the face before the figure (it is the
  figure's first reference).

Checked against docs/art/pixellab_lessons.md: every object alone with no setting (no floor, table, grass or sky named);
everything usually printed or stencilled said plain, unprinted, no lettering, no number; no dials, clock faces or
labels with marks; British coins named British; no "sign"; a seed range of its own (103xxx).
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_web_art_manifest as web  # noqa: E402  (node_job, emblem_job, people_jobs' prompts)

SEED0 = 103000                # clear of every other manifest's seeds (web art 98xxx, walls 101xxx, generator 102xxx)

# the 48, by id: the object that says what the skill does
SKILLS = {
    # the Poacher
    "clean_shot": "a single brass rifle cartridge standing upright, its tip polished bright, plain, no stamp or lettering on its base",
    "flush_them_out": "a long beater's stick of rough hazel with a strip of white rag tied near its end",
    "go_to_ground": "a folded camouflage scrim net, green and brown strips of cloth knotted through it",
    "one_for_the_pot": "a small dented black cooking pot with a wire bail handle, a wisp of steam rising from it, plain",
    "collared": "a heavy worn leather dog collar with a brass buckle, closed in a loop, plain, no tag",
    "gin_trap": "an old rusted gin trap with its iron jaws sprung open, a short chain hanging from it",
    "decoy": "a carved wooden decoy duck, its paint faded and flaking",
    "net_every_hole": "a bundle of purse nets of brown twine with wooden pegs, gathered in a heap",
    # the Paramedic
    "tourniquet": "a rolled black tourniquet strap with a plain metal windlass rod through it, unprinted, no lettering",
    "antidote": "a small brown glass vial with a rubber stopper and a short syringe beside it, the vial plain, no label",
    "adrenaline": "an orange auto-injector pen, plain, unprinted, no lettering, no label, no numbers",
    "major_incident": "a hard green paramedic's response bag, unzipped, rolls of bandage showing, plain, no cross, no lettering",
    "two_sugars": "a chipped white enamel mug of strong tea with two sugar cubes beside it, plain, no print on the mug",
    "sedative_dart": "a single tranquilliser dart with a red feathered tail and a steel needle, plain, no markings",
    "strapped_up": "a tight roll of white crepe bandage held with two small metal clips",
    "code_blue": "a pair of defibrillator paddles with coiled grey leads, plain, no lettering, no numbers, no screen",
    # the Doorman
    "shoulder_charge": "a heavy padded black bomber jacket shoulder, the leather scuffed and creased, the jacket alone",
    "headbutt": "a cracked white plaster cast of a broad forehead and brow, the plaster alone",
    "brace": "a thick black leather weightlifting belt, buckled in a loop, plain, no lettering",
    "barred": "a heavy steel door bar dropped across two iron brackets, the bar and brackets alone",
    "not_on_the_list": "a black clipboard with a blank sheet of paper on it and a pen clipped to the top, the paper plain with no writing",
    "shutters_down": "a section of corrugated steel roller shutter, pulled down, dented and rust-streaked, plain, no graffiti",
    "pat_down": "a pair of black leather gloves lying open, palms up, worn",
    "chucking_out_time": "a large brass hand bell with a wooden handle, the bell plain",
    # the Scrapper
    "ring_main": "a coil of copper electrical cable, stripped bare at both ends, the copper bright",
    "hot_work": "a welding torch with a bright blue-white flame at its nozzle and a short hose trailing off",
    "breakdown": "a loose handful of brass bullet cartridges spilling from a plain steel tin, unprinted, no lettering",
    "short_circuit": "a burnt-out plain grey electrical junction box with sparks bursting from its open front, no lettering",
    "bung": "a fat folded wad of old British banknotes held by a rubber band, the notes plain and blank, no faces, no numbers",
    "knock_off_kit": "a battered plain cardboard box with its flaps open and a gun part showing inside, unprinted, no lettering",
    "back_of_the_van": "a single round green hand grenade, its pin and lever in place, plain, no markings",
    "everything_must_go": "a crowbar and a hacksaw crossed over each other, both worn",
    # the Recruit
    "lob_one_in": "a single round olive-drab hand grenade with its pin pulled out and the ring hanging free, plain, no markings",
    "flashbang": "a plain grey cylindrical stun grenade with a bright white flash bursting from its top, no markings, no lettering",
    "smoke": "a plain green smoke canister pouring thick grey-white smoke, no markings, no lettering",
    "danger_close": "a jagged burst of shrapnel fragments flying outwards from a bright orange blast, the blast alone",
    "suppressing_fire": "a long belt of brass machine-gun rounds in plain steel links, coiled",
    "make_ready": "a rifle magazine with brass rounds showing at its lips, plain steel, unprinted, no lettering",
    "stand_to": "an army bugle of dented brass with a faded red cord, plain",
    "fire_and_manoeuvre": "two olive-drab army helmets side by side, one a little ahead of the other, plain, no badges",
    # the Drifter
    "duck_and_weave": "a pair of worn black boxing gloves tied together by their laces, plain, no lettering",
    "look_lively": "a pair of battered running trainers with frayed laces, plain, no logos",
    "elbow_room": "a bent elbow pad of scuffed black plastic and foam, plain, no logos",
    "gone": "an empty hooded grey jacket hanging on nothing, slumped, as if its wearer just slipped out of it",
    "coin_toss": "a single old British penny spinning on its edge, copper, worn smooth",
    "close_shave": "an open cut-throat razor with a bone handle, its blade bright",
    "chancer": "a four-leaf clover pressed flat and dry, pale green",
    "jackpot": "a heap of old British coins spilling over each other, copper and silver, worn",
}

# the Recruit's tree, by name: notables, keystones, capstones, his two halves
NODES = {
    "Cook it off": "a hand grenade with a thin curl of smoke rising from its fuse, its pin gone, plain, no markings",
    "Grenadier": "a canvas grenade pouch on a webbing strap holding two round grenades, plain, unprinted, no lettering",
    "Brute force": "a heavy army rifle butt of scarred dark wood with a steel butt plate",
    "Blast burns": "a blackened scorched scrap of olive cloth, its edges still glowing orange",
    "Ringing ears": "a pair of foam ear defenders on a plain grey headband, one cup dented, plain, no lettering",
    "Firing blanks": "a handful of crimped brass blank cartridges, their tips closed in a star, plain, no stamps",
    "Cover me": "a waist-high wall of stacked sandbags, the sacks plain, unprinted",
    "Quick march": "a pair of polished black army boots, laced tight, standing together, plain",
    "Fix bayonets": "a steel army bayonet with a dark wooden grip, its blade long and bright",
    "Double time": "a battered steel army mess tin with a folding handle, plain, unprinted",
    "Passing-out parade": "a dark green beret with a plain brass badge with no lettering, folded neat",
    "Recruit's bayonet": "a steel bayonet tip, its edge nicked and dark at the point",
    "Recruit's boots": "one heavy black army boot with a scuffed steel toecap, plain",
}

EMBLEMS = [
    ("ordnance", "a round hand grenade with its pin and ring", "olive drab and brass"),
    ("drill", "a pair of army boots side by side at attention", "black leather and khaki"),
]

PORTRAIT = ("the Recruit, a young man of about twenty who walked out of the army barracks with the stores: a soldier's "
            "short back and sides grown out, a thin hungry face, a faded olive army-surplus jacket with the badges cut off, "
            "a plain khaki scarf, a steady wary look, a little too serious for his age")
FIGURE = ("the Recruit: a young lean man of about twenty, a grown-out army haircut; a faded olive army-surplus jacket with "
          "the badges cut off over a plain grey jumper, khaki trousers tucked into polished black army boots, webbing "
          "belt with empty pouches")

TEST = ["portrait:recruit", "region:ordnance", "skill:clean_shot", "skill:code_blue", "skill:bung", "skill:lob_one_in",
        "node:Grenadier", "node:Cover me"]


def skill_job(sid, obj, seed):
    j = web.node_job(sid, obj, "the skill %s: its button, the Runs card, the picker, its web node" % sid, seed)
    j["out"] = "art/skills/%s.png" % sid
    return j


def main():
    jobs = []
    keyed = {}
    seed = SEED0
    for sid, obj in SKILLS.items():
        j = skill_job(sid, obj, seed)
        seed += 1
        jobs.append(j)
        keyed["skill:" + sid] = j
    seed = SEED0 + 100
    for name, obj in NODES.items():
        j = web.node_job(web.slug(name), obj, "Training's web: %s (the Recruit)" % name, seed)
        seed += 1
        jobs.append(j)
        keyed["node:" + name] = j
    for i, (key, what, tint) in enumerate(EMBLEMS):
        j = web.emblem_job(key, what, tint, SEED0 + 200 + i)
        jobs.append(j)
        keyed["region:" + key] = j
    face = {"out": "art/people_new/recruit.png", "endpoint": "generate-image-v2", "width": 128, "height": 128,
            "no_background": False, "single": True, "seed": SEED0 + 300, "style_options": web.STYLE,
            "style_image": "res://art/people/fence.png", "description": web.PORTRAIT % PORTRAIT,
            "_where": "the Recruit's face: his card, the Stats room, his wheel (cut from it)"}
    body = {"out": "art/body_new/body_recruit.png", "endpoint": "generate-image-v2", "width": 208, "height": 488,
            "no_background": True, "single": True, "seed": SEED0 + 301, "style_options": web.STYLE,
            "style_image": "res://art/people_new/recruit.png",
            "reference_images": ["res://art/people_new/recruit.png", "res://art/body_new/body_poacher.png"],
            "description": web.FIGURE % FIGURE, "_where": "the Recruit's figure (run after his face)"}
    jobs += [face, body]
    keyed["portrait:recruit"] = face
    test = [keyed[k] for k in TEST]
    counts = "skills %d, nodes %d, emblems %d, people 2" % (len(SKILLS), len(NODES), len(EMBLEMS))
    root = web.ROOT
    with open(os.path.join(root, "tools", "pixellab_skills_art_manifest.json"), "w") as f:
        json.dump({"_readme": __doc__.strip() + "\n\n" + counts, "jobs": jobs}, f, indent=1)
    with open(os.path.join(root, "tools", "pixellab_skills_art_test_manifest.json"), "w") as f:
        json.dump({"_readme": "The test: " + ", ".join(TEST) + ". Judge these before the rest runs.", "jobs": test}, f, indent=1)
    print("%d jobs (%s); the test %d" % (len(jobs), counts, len(test)))


if __name__ == "__main__":
    main()
