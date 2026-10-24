"""The Generator's five energy picks (24 Oct, milestone 8: the away picks gone - docs/design/skills.md section 7).
One manifest, five 64 px node pictures, the web art's own template (make_web_art_manifest.node_job: its ICON tail,
style and references):

  python3 tools/make_generator_energy_manifest.py
    -> tools/pixellab_generator_energy_manifest.json

  C:\\Godot\\godot.console.exe --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_generator_energy_manifest.json ++ --parallel 3
  (++ --dry-run to list; one that came out wrong: ++ --only <id> ++ --force)

To art/nodes/pick_generator_<id>.png: new files, nothing on disk is overwritten; yard_web finds them by the pick's id,
so they need no wiring. The rank's picture (a pull cord handle) stays. The old five (twelve_hours, a_day, overtime,
two_days, grid) are orphans once these land. Checked against docs/art/pixellab_lessons.md: the objects alone, no
setting; everything usually printed said plain and unprinted; no dials or numbers; a seed range of its own."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_web_art_manifest as web  # noqa: E402  (node_job, the ICON tail)

SEED0 = 102000                # clear of every other manifest's seeds (web art 98xxx, walls 101xxx)
PICKS = [
    ("jerry_can", "a battered steel jerry can, plain olive-drab paint chipped to bare metal at the edges, its three handles on top, "
                  "unprinted, no lettering, no stencil, no number on it"),
    ("dynamo", "a small old hand-crank dynamo, a plain grey metal casing with a folding crank handle sticking out of its side, "
               "unprinted, no lettering, no dial"),
    ("kickback", "a pair of jump lead crocodile clamps, one red, one black, their jaws touching with a small bright spark between "
                 "them, a short twist of cable trailing off, plain, no lettering"),
    ("flywheel", "a heavy cast-iron flywheel with six thick spokes, worn smooth at the rim and oil-stained, plain, no numbers or "
                 "lettering cast into it"),
    ("pilot_light", "a small brass gas burner nozzle with a single steady blue pilot flame at its tip, plain, unprinted, no dial, "
                    "no lettering"),
]


def main():
    jobs = [web.node_job("pick_generator_%s" % pid, obj, "the Pitch's web: generator / %s" % pid, SEED0 + i)
            for i, (pid, obj) in enumerate(PICKS)]
    out = os.path.join(web.ROOT, "tools", "pixellab_generator_energy_manifest.json")
    with open(out, "w") as f:
        json.dump({"_readme": "The Generator's five energy picks (24 Oct). tools/make_generator_energy_manifest.py writes this.",
                   "jobs": jobs}, f, indent=1)
    print("%d jobs -> %s" % (len(jobs), out))


if __name__ == "__main__":
    main()
