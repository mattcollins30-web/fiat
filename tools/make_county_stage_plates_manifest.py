"""The County's stage backdrops (6 Nov, Matt: "We also need the same treatments for the county - stages, art, gear spread,
full size map, UI changes from campaign"; docs/design/county_stages.md §5): one plate for each County place's 2/3 and 3/3,
24 jobs at 744x320 (the County plate's size, art/fight_county/<place>_plate.png), $0.15 each.

  python3 tools/make_county_stage_plates_manifest.py  -> tools/pixellab_county_stage_plates_manifest.json

Out art/fight_county/<place>_2_plate.png and _3_plate.png: RunView's stage key reads them by name on a County stage and
stands each on its place's own wall (art/fight_county/<place>_cover.png) - BUILD61-U's key, nothing else to wire. Nothing
live is overwritten: new names, no --force.

The 6 Nov lesson (docs/art/pixellab_lessons.md, the stages' reroll): a stage plate styled on its own place's plate came
back a near-copy. So each takes ANOTHER place of the same zone as its style image (the spec §5's column), palette only,
and says in words what must differ from its own place's plate. The kit's POV, EMPTY, LAYOUT and TAIL as every County
plate's (make_county_art_manifest.py) - the first-person crouching view and the three-figure layout.

Checked against docs/art/pixellab_lessons.md:
- Style images pull view and subject: "Only the palette, light and painting style of the style image - nothing of its
  view, its place or its subject" (the 6 Nov reroll's line), and a different spot said in words.
- Lettering: no place or shop is named where its name would be painted (the drivers' showers, the ship's shop, the
  clubhouse bar's honours boards, the terminal); "sign" never used; clocks, notes, displays, panels, keys, ledgers, boxes,
  totes, bottles and the gantry said plain / blank / no numbers; nothing hand-written.
- Framing: the painting fills the whole canvas to all four edges, no border, frame or margin.
- Nobody in it: EMPTY and "no people or figures"; never describe what's drawn over a backdrop (the figures and the wall).
- Prompts that fight: the spec's Toll Plaza 2/3 ("a window onto the canopy" and "no canopy view") is resolved to a window
  of grey sky only.
- Seeds 641000-641023, clear of every manifest (checked here: it stops on a clash); no two jobs share an out."""
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_fight_kit_manifest as kit  # noqa: E402  (POV, EMPTY, LAYOUT, TAIL, STYLE, the plate size)

ROOT = kit.ROOT
OWN = "pixellab_county_stage_plates_manifest.json"
SEED0 = 641000      # clear of every other manifest's (the County art 106xxx, the stages' 612xxx-632xxx)
STYLE_LINE = ("Only the palette, light and painting style of the style image - nothing of its view, its place or its "
              "subject, which is somewhere else entirely. A crouching viewpoint, with near, middle and far ground.")
FILL = "The painting fills the whole canvas to all four edges, no border, frame or margin."
NOBODY = "No people or figures anywhere."
BLANK = "Every board, panel, screen and label in it blank, no lettering, numbers or pictures anywhere."

# The spec §5's table: place key -> (the style plate: another place of the same zone, (2/3 scene, what differs), (3/3 ...)).
# "# LESSON" marks a brief reworded for a lesson.
SCENES = {
    "toll_plaza": ("the_distribution_centre",
        ("into the cash office behind a motorway toll plaza's booths: a counter of blank cash tills with their drawers "
         "open, a squat safe standing open and empty, plain grey filing cabinets, a strip light, a small high window of "
         "grey sky, a dark corridor doorway on the left",
         "Indoors, in a small office: no booths, no canopy, no road in view."),       # LESSON: the spec's window onto the canopy fought "no canopy view"
        ("out past a toll plaza's barriers onto the open motorway carriageway: abandoned cars at angles across the "
         "lanes, a jack-knifed tanker in plain grey paint with no lettering, an overhead gantry carrying plain blank grey "
         "panels with nothing on them, crash barriers, a dark gap between two cars on the left",
         "Out on the open road under a wide grey sky: no booths, no canopy roof overhead.")),   # LESSON: gantries carry lettering
    "distribution": ("the_truck_stop",
        ("across a distribution warehouse's loading yard in rain: lorry trailers in plain unpainted grey with no "
         "lettering backed onto a row of loading bays, a small yard shunter cab, pallets under tarpaulin sheeting, "
         "puddles on the concrete, a dark open bay door on the left",
         "Outdoors in the rain under a grey sky: no racking, no warehouse roof overhead."),      # LESSON: trailers carry livery
        ("along a warehouse's mezzanine pick floor high up under the roof: long rollers of conveyor, wheeled steel roll "
         "cages, plain unprinted plastic totes with no labels, strip lights hanging low, a steel stair going down on the "
         "left",
         "Up high on a steel mezzanine floor among conveyors: not the tall pallet racking at ground level.")),   # LESSON: totes carry labels
    "truck_stop": ("the_toll_plaza",
        ("across a truck stop's lorry park at dusk on a grey day, the floodlights on: rows of parked lorry cabs in plain faded paint with no lettering, "
         "their curtains drawn behind the windscreens, a fuel island with plain pumps with dark displays and no numbers, "
         "puddles under tall floodlights, a dark gap between two cabs on the left",
         "Outdoors at dusk under floodlights: no cafe, no tables, no counter."),     # LESSON: cabs carry livery, pumps numbers
        ("down a tiled corridor at the back of a truck stop to a caged lock-up: white tiles, a row of plain shower "
         "cubicle doors, then a steel mesh cage full of plain unprinted cardboard boxes and rows of keys on hooks with "
         "no tags, a dark doorway on the left",
         "A narrow tiled corridor and a cage: no cafe, no lorry park, no windows.")),   # LESSON: "the drivers' showers" would be a sign; key tags carry numbers
    "container_port": ("the_ferry_terminal",
        ("along a port's quay under a giant gantry crane: the plain grey hull of a moored ship towering up on the right "
         "with no name or numbers on it, steel lashing bars racked on the quay, a bin of twist-locks, bollards and mooring "
         "ropes, dark water at the quay's edge, a dark gap between machinery on the left",
         "At the water's edge beside a ship's hull: not a corridor between container stacks."),   # LESSON: hulls carry names and draught marks
        ("down a row of refrigerated shipping containers at dusk on a grey day, each plugged into a power post by a thick cable, "
         "their plain ribbed doors lit by small lamps, their little control panels dark and blank with no numbers, wet "
         "concrete, a dark gap between two containers on the left",
         "Dusk, lamplight on refrigerated containers in one long row: no crane.")),   # LESSON: reefer displays show numbers
    "ferry_terminal": ("the_customs_shed",
        ("inside a ferry's car deck: lanes of abandoned cars with no number plates and a coach in plain paint, lashing "
         "chains and wheel chocks on the steel floor, the steel ceiling low overhead, the bow door half down at the far "
         "end showing grey sea, a dark stairwell door on the left",
         "Inside the ship's steel car deck: no departure hall, no seats, no glass wall."),   # LESSON: plates and a coach's livery
        ("across a ferry's upper passenger lounge: rows of bolted-down seats, a small shop counter with bare empty "
         "shelves and a plain panel above it with nothing on it, salt-streaked windows on a grey sea, a dark doorway on "
         "the left",
         "On board, high up with the sea through the windows: not the terminal building on land.")),   # LESSON: "a ship's shop" invites its fascia
    "customs_shed": ("the_container_port",
        ("inside a customs shed's seized goods cage: steel mesh bays stacked with plain wooden crates, rolled carpets, "
         "rows of plain unlabelled bottles in boxes, a pallet truck, a strip light, the mesh gate open on the left",
         "Inside a mesh cage of seized goods: no long benches, no X-ray tunnel, no roller door."),   # LESSON: bottles carry labels
        ("down a customs shed's long office: rows of grey filing cabinets, a long counting table covered with closed "
         "plain ledgers and blank paper, desk lamps, a window of small panes looking down onto the shed floor, a dark "
         "doorway on the left",
         "An office with a window over the shed: not the shed floor itself.")),
    "golf_club": ("the_gated_close",
        ("into a golf clubhouse bar: dark wood panelling with plain varnished wooden boards on the walls with nothing "
         "painted on them, a long bar with brass taps and no badges on them, rows of plain unlabelled bottles, leather "
         "armchairs pushed over, a dark doorway on the left",
         "Indoors in a panelled bar: no terrace, no green, no buggies."),   # LESSON: honours boards carry names; taps carry badges
        ("across a golf course's far fairway to the greenkeeper's sheds: a ride-on mower left on the grass, a reedy pond, "
         "a corrugated shed with its door open, a lookout platform built of scaffold poles and boards, mist over the "
         "trees, a dark gap in the trees on the left",
         "Far out on the course by the sheds and the pond: no clubhouse, no terrace.")),
    "gated_close": ("the_manor",
        ("inside one of the big new houses: an open-plan kitchen with an island, glass doors onto a garden, sofas pushed "
         "against the glass doors as a barricade, plain white walls, a dark hallway doorway on the left",
         "Inside the house, its kitchen and glass doors: not the street of houses outside."),
        ("into the gatehouse at the entrance of a gated close: a small guard cabin with a desk of dark blank screens, the "
         "barrier arm down outside the window, a dog kennel and an empty bowl, a dark doorway on the left",
         "Inside the small gatehouse: not the street of big houses, no drives or garages.")),   # LESSON: screens plain
    "manor": ("the_golf_club",
        ("across a manor's cobbled stable yard: stable doors in a row, a clock tower above them with a plain white face "
         "with no numbers or hands, two horseboxes in plain paint with no lettering, straw on the cobbles, an archway on "
         "the left going into the dark",
         "Outdoors in a cobbled yard of stables: no long hall, no panelling."),   # LESSON: clock faces; horseboxes carry lettering
        ("into a manor's library: tall shelves of books with plain blank spines, a wooden library ladder, a desk heaped "
         "with papers, every page blank, a green-shaded lamp, a dark doorway on the left",
         "A book-lined library: no long dining table, no staircase.")),   # LESSON: spines and pages blank
    "counting_house": ("the_bullion_vault",
        ("into a counting house's basement note store: steel cages stacked with bundles of plain grey-green notes with "
         "no faces or numbers, a note-sorting machine with a dark blank display, a concrete floor, a single strip light, "
         "a dark doorway on the left",
         "Underground among steel cages: no clerks' desks, no tall windows."),   # LESSON: notes and displays
        ("down from a counting house's managers' gallery: glass-walled offices along a balcony, and below them "
         "the long room's rows of desks seen from above, the desks bare, plain paper, a stair going down on the left",
         "From above, high on the gallery looking down: not along the long room at desk height.")),
    "bullion_vault": ("the_treasury",
        ("into a bullion vault's loading bay: plain grey armoured vans with no lettering or numbers backed in, a "
         "weighbridge plate set in the concrete, a heavy steel shutter half up on grey daylight, a dark doorway on the "
         "left",
         "A loading bay with vans and a shutter: no round vault door, no mesh cages."),   # LESSON: vans carry livery
        ("deep inside a bullion vault: walls of small plain steel safe-deposit doors from floor to ceiling with no "
         "numbers on them, one wall blown open into rubble and twisted steel, dust in the air, a dark hole on the left",
         "The deepest room, walled with small steel doors: no shelving cages, no trolleys.")),   # LESSON: box numbers
    "treasury": ("the_counting_house",
        ("into the Treasury's print room: heavy printing presses in a row, sheets of plain grey-green notes with no "
         "faces or numbers drying on racks, ink drums, a dark doorway on the left",
         "A print room of presses: no marble hall, no columns, no counter."),   # LESSON: notes
        ("across the square and up the Treasury's steps: tall stone columns, a barricade of plain grey armoured vans "
         "with no lettering across the steps, a flagpole with a plain grey flag with nothing on it, wet paving, a dark "
         "archway on the left",
         "Outdoors in the square before the steps: not the great hall inside.")),   # LESSON: vans and the flag plain
}


def county():
    """data.gd COUNTY: [key, place]."""
    s = open(os.path.join(ROOT, "scripts", "sim", "data.gd"), encoding="utf-8").read()
    i = s.index("const COUNTY := [")
    return re.findall(r'\{"key": "([^"]+)", "place": "([^"]+)"', s[i:s.index("\n]", i)])


def plate_job(place, st, style, scene, differ, seed):
    return {"out": "art/fight_county/%s_%d_plate.png" % (kit.slug(place), st), "width": kit.PLATE_W, "height": kit.PLATE_H,
            "no_background": False, "seed": seed, "endpoint": "generate-image-v2", "single": True,
            "style_options": kit.STYLE, "style_image": "res://art/fight_county/%s_plate.png" % style,
            "description": " ".join([kit.POV + "looking " + scene + ".", differ, kit.EMPTY, NOBODY, kit.LAYOUT,
                                     STYLE_LINE, FILL, BLANK, kit.TAIL]),
            "_where": "the %d/3's plate: %s (styled on art/fight_county/%s_plate.png, palette only; stands on the place's wall)" % (st, place, style)}


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
    places = county()
    if sorted(k for k, _p in places) != sorted(SCENES):
        sys.exit("data.gd COUNTY is %s; this maker has scenes for %s" % ([k for k, _p in places], sorted(SCENES)))
    jobs = []
    seed = SEED0
    for key, place in places:
        style = SCENES[key][0]
        if style == kit.slug(place):
            sys.exit("%s is styled on its own plate (the 6 Nov lesson: a near-copy)" % place)
        for st, (scene, differ) in zip((2, 3), SCENES[key][1:]):
            jobs.append(plate_job(place, st, style, scene, differ, seed))
            seed += 1
    used = used_seeds()
    clash = {j["seed"]: used[j["seed"]] for j in jobs if j["seed"] in used}
    if clash:
        sys.exit("seeds already used elsewhere: %s - move SEED0" % clash)
    for j in jobs:
        if not os.path.exists(os.path.join(ROOT, j["style_image"].replace("res://", ""))):
            sys.exit("no %s on disk (%s)" % (j["style_image"], j["out"]))
        if os.path.exists(os.path.join(ROOT, j["out"])):
            print("warning: on disk already (skipped unless --force): %s" % j["out"])
    readme = [
        "FIAT COUNTY STAGE PLATES (6 Nov; docs/design/county_stages.md §5): a plate for each County place's 2/3 and 3/3, "
        "%d jobs at 744x320, $0.15 each (about $%.2f)." % (len(jobs), 0.15 * len(jobs)),
        "Out art/fight_county/<place>_2_plate.png / _3_plate.png: the County stage key finds them by name and stands each on "
        "its place's own wall (art/fight_county/<place>_cover.png) - nothing to wire.",
        "Each styled on ANOTHER place of its zone (palette only - the 6 Nov lesson: a plate styled on its own place's came "
        "back a near-copy), what must differ said in words. ++ --parallel 3. After Matt has read the slice on test art.",
        "Regenerate with python3 tools/make_county_stage_plates_manifest.py; check with python3 tools/art_lint.py.",
    ]
    with open(os.path.join(ROOT, "tools", OWN), "w", encoding="utf-8") as f:
        json.dump({"_readme": readme, "jobs": jobs}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print("county stage plates: %d jobs, seeds %d-%d" % (len(jobs), SEED0, seed - 1))


if __name__ == "__main__":
    main()
