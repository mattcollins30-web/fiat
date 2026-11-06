"""The stages' backdrops (6 Nov, Matt: "include the new backdrops and items from yesterday - just drop the flag when
ready"; docs/design/stages.md §6, call 7: a new plate per stage on the site's existing wall). One plate for each site's
2/3 and 3/3: 24 jobs, 744x320 (the kit's plate size, art/fight_new/<site>_plate.png), $0.15 each.

  python3 tools/make_stage_plates_manifest.py  -> tools/pixellab_stage_plates_manifest.json

Out art/fight_new/<site>_2_plate.png and <site>_3_plate.png. RunView.stage_key reads `<site>_N_plate` by name and stands
it on the site's own wall (art/fight_walls/<site>_cover.png) - nothing to wire; the figures stand on the site's placed
slots until F3 places the stage's own. Nothing live is overwritten: new names, no --force.

Each plate is styled on its site's own plate (art/fight_new/<site>_plate.png) and keeps the site's view: the kit's POV,
EMPTY, LAYOUT and TAIL (make_fight_kit_manifest.py), the same viewpoint and layout family, a different spot of the same
place. The briefs are stages.md §6's (Words.SITES' stage lines), reworded where they invite lettering or a figure.

Checked against docs/art/pixellab_lessons.md:
- Landscape style images pull the view: "Only the palette, light and painting style of the style image, not its view
  or its subject" - and the view is then given in words (the kit's POV and LAYOUT, the same as the site's plate).
- Lettering: no place or shop is named where its name would be painted on it (the bookmaker's, the launderette, the
  jeweller's, the arcade, the supermarket, the cafe, A&E, the pharmacy): blank fascia boards, plain unprinted packaging,
  dark blank screens and displays, no numbers on pumps, tills, clocks or plates; no "sign" (a pictogram where one is
  wanted); nothing hand-written (the Quartermaster's signing book is a closed plain ledger).
- Framing: the painting fills the whole canvas to all four edges, no border, frame or margin.
- Nobody in it: EMPTY and "no people or figures" - the briefs' people ("the crew as staff", "at drill", "someone
  guards", "someone lives in") are drawn as the traces they leave.
- Never describe what's drawn over a backdrop: the figures and the wall are not mentioned (LAYOUT keeps their room).
- Seeds 612000-612023, clear of every manifest (checked here: it stops on a clash); no two jobs share an out."""
import glob
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_fight_kit_manifest as kit  # noqa: E402  (POV, EMPTY, LAYOUT, TAIL, STYLE, the plate size, SITES)

ROOT = kit.ROOT
OWN = "pixellab_stage_plates_manifest.json"
SEED0 = 612000      # clear of every other manifest's (the 6 Nov reroll's 611000-611005 the last)
STYLE_LINE = ("Only the palette, light and painting style of the style image, not its view or its subject: this is a "
              "different spot of the same place, seen from the same crouching viewpoint, with the same layout of near, "
              "middle and far ground.")
FILL = "The painting fills the whole canvas to all four edges, no border, frame or margin."
NOBODY = "No people or figures anywhere."

# stages.md §6's briefs (2/3, 3/3) as scenes, in kit.SITES' order. "# LESSON" marks a brief reworded for a lesson.
SCENES = {
    "the_allotments": (
        # Further in: water butts tipped over, shed doors off
        "further into the overgrown allotments: plastic water butts tipped over on their sides, a puddle spread from "
        "them, sheds with their doors torn off and lying in the weeds, rows of broken bean canes, a dark open shed "
        "doorway on the left",
        # A dug plot behind pallet fences, a potato bed someone guards
        "across a freshly dug allotment plot fenced in with upright wooden pallets lashed together: a long earthed-up "
        "potato bed, a spade stood in the soil, an upturned crate for a lookout seat by a gap in the pallets on the "
        "left, a tarpaulin lean-to, the sheds of the allotments beyond"),          # LESSON: "someone guards" - no figure, his traces
    "the_garden_centre": (
        # The cafe stripped to its "scones" sign
        "into a garden centre's stripped cafe: tables and chairs stacked and toppled, an empty glass-fronted cake "
        "counter, a bare wooden menu board on the wall wiped blank, a dead coffee machine, a dark kitchen doorway on "
        "the left, the glasshouse roof beyond the far windows",                      # LESSON: the "scones" sign is lettering - a blank board
        # The glasshouse walled with compost bags
        "inside a garden centre's glasshouse: its glass roof with panes out, the walls heaped high with plain "
        "unprinted compost bags stacked like sandbags, empty plant benches, a dark gap between the bag walls on the "
        "left, grey daylight through the roof"),                                     # LESSON: compost bags are printed
    "top_farm": (
        # The barn, stacked with feed nobody's feeding
        "inside a big stone barn: plain unprinted feed sacks stacked high on pallets, empty cattle pens with their "
        "gates hanging open, straw on the floor, a dusty feed trough, the big doors open on a grey muddy yard, a dark "
        "tack-room doorway on the left",                                            # LESSON: feed sacks are printed
        # The farmhouse, the gun cabinet open and empty
        "into a farmhouse's stone-floored back kitchen: a big range cooker, a long scrubbed table, coats on pegs, wellies "
        "by the door, a tall plain steel gun cabinet standing open and empty, a dark passage doorway on the left"),
    "ransacked_streets": (
        # A house with the copper chased out of its walls
        "into the ground floor of a terraced house stripped for its copper: the plaster hacked open in long channels "
        "where the pipes and wires were, floorboards up, a radiator gone from its wall leaving brackets, a dark "
        "stairway doorway on the left, a window onto the grey street",
        # A back street, a car on bricks with a child seat
        "down a back street behind a row of terraces: brick back-yard walls and gates, wheelie bins with no numbers on "
        "them, a car up on bricks with its wheels gone and its number plates gone, a child's car seat still in the "
        "back, a dark ginnel on the left"),                                          # LESSON: bins and plates carry numbers
    "the_parade": (
        # The bookmaker's, its shutter the only one down
        "along a different stretch of the estate's parade of shops: every shop open and gutted but one, whose steel "
        "shutter alone is pulled down and padlocked, its fascia board above it a blank faded panel, the others' "
        "fascias blank too, a dark alley between two shops on the left",            # LESSON: naming the bookie's invites its lettering
        # The launderette someone lives in
        "into a gutted launderette on the parade: a row of front-loading washing machines along one wall, their round "
        "doors open, a mattress and blankets made up on the folding counter, a camping stove and a kettle, clothes "
        "hung to dry on a line, plain blank walls, a dark back-room doorway on the left"),   # LESSON: "someone lives in" - no figure
    "the_retail_park": (
        # The DIY shed's aisles, where the nail guns came from
        "down an aisle of a huge DIY warehouse store: tall orange steel racking half emptied, plain unprinted boxes "
        "torn open, timber lengths spilled across the floor, power-tool shelves stripped bare, a dark cross-aisle on "
        "the left, the roof lights grey overhead",                                   # LESSON: the shed's name invites lettering
        # The supermarket, its freezers dead
        "down a looted supermarket: rows of empty shelving, chest freezers along one side with their lids open and "
        "dark inside, abandoned trolleys, plain blank price rails with no labels, a dark doorway to the stock room on "
        "the left, the roof lights out"),                                            # LESSON: supermarkets carry signs and labels
    "the_pleasure_park": (
        # The arcade, lit off a generator
        "into a seaside amusement arcade lit off a generator: rows of arcade cabinets, a few glowing with soft plain "
        "coloured light on their dark blank screens, no pictures or words on them, a penny-falls machine, a fat cable "
        "snaking across the patterned carpet to a small generator, a dark doorway on the left",   # LESSON: arcade screens and fronts carry lettering
        # The log flume as a guarded reservoir
        "across a pleasure park's log flume made into a reservoir: the long fibreglass trough brimming with still grey "
        "water, its splash pool dammed with sandbags, plastic jerrycans lined up along the edge, the flume's tower "
        "going up into the haze, a dark tunnel mouth on the left"),                  # LESSON: "guarded" - no figure, the dam and the cans
    "shopping_centre": (
        # The jeweller's done over, watches left on the floor
        "into a ransacked jeweller's in the shopping centre: glass display counters smashed, empty velvet ring trays, "
        "wristwatches scattered across the floor with plain faces and no numbers, a small safe open behind the "
        "counter, the shop's fascia blank, a dark back-room doorway on the left",    # LESSON: watch faces, the jeweller's name
        # The upper floor's camp in the children's clothes shop
        "into a children's clothes shop on the shopping centre's upper floor made into a camp: racks of small clothes "
        "pushed back, mattresses and sleeping bags on the floor, a camping stove, washing strung between the rails, "
        "plain blank walls, a dark fitting-room doorway on the left"),
    "the_bank": (
        # Behind the counter, the crew as staff
        "from behind a high-street bank's counter: the teller positions from the staff side, swivel chairs, cash "
        "drawers pulled open, plain blank paper on the desks, the starred glass screens looking out onto the empty "
        "banking hall, a dark staff doorway on the left",                            # LESSON: "the crew as staff" - no figure
        # The back office, its tills on a generator
        "into a bank's back office: desks pushed together, cash tills with their drawers open and their small displays "
        "lit with no numbers on them, cables running to a small generator on the carpet, filing cabinets, a dark "
        "corridor doorway on the left, blinds half down"),                            # LESSON: displays, tills - no numbers
    "the_services": (
        # The lorry park: trailers as houses, cabs as shops
        "across a motorway services lorry park: plain unpainted curtain-sided trailers parked in rows with no lettering "
        "on them, their curtains pulled back on beds and furniture inside, lorry cabs with their doors open and goods "
        "laid out on their steps, a dark gap between two trailers on the left",     # LESSON: trailers carry livery
        # The forecourt and the tanks they fight over
        "across the far side of a motorway services forecourt: the underground fuel tanks' steel covers prised open in "
        "the concrete, hand pumps and hoses run into them, plain pumps with their displays dark and no numbers, the "
        "canopy overhead, a dark shop doorway on the left, the slip road in haze"),   # LESSON: pump displays carry numbers
    "the_hospital": (
        # A&E as the gate, a triage desk
        "into a hospital's emergency entrance made into a gate: the ambulance bay outside, the sliding doors jammed "
        "open, a triage desk pushed across the entrance as a checkpoint, wheelchairs and trolleys stacked as a "
        "barrier, plain blank panels where the signs were, a dark corridor on the left",   # LESSON: "A&E" is lettering
        # The pharmacy, emptied by rota
        "into a hospital pharmacy: long rows of steel shelving almost bare, a few plain unprinted boxes left neatly "
        "spaced on them, a dispensing counter with its hatch open, a locked steel cupboard standing open, plain blank "
        "walls, a dark store-room doorway on the left"),                             # LESSON: medicine boxes are printed
    "the_barracks": (
        # The armoury's hatch, the Quartermaster's signing book
        "into an army barracks' armoury corridor: a steel issue hatch in a brick wall with its shutter up, a closed "
        "plain ledger lying on its counter, empty rifle racks behind a mesh cage, a dark doorway on the left",   # LESSON: a signing book invites hand-writing
        # The parade square at drill
        "across a barracks' wide parade square swept clean and marked out with painted lines for drill, a saluting "
        "dais at one side, brick accommodation blocks round it, a flagpole with no flag, a dark archway on the left"),   # LESSON: "at drill" - no figures
}


def plate_job(key, st, scene, seed):
    return {"out": "art/fight_new/%s_%d_plate.png" % (key, st), "width": kit.PLATE_W, "height": kit.PLATE_H,
            "no_background": False, "seed": seed, "endpoint": "generate-image-v2", "single": True,
            "style_options": kit.STYLE, "style_image": "res://art/fight_new/%s_plate.png" % key,
            "description": " ".join([kit.POV + "looking " + scene + ".", kit.EMPTY, NOBODY, kit.LAYOUT, STYLE_LINE, FILL,
                                     "Every board, panel, screen and label in it blank, no lettering, numbers or pictures anywhere.",
                                     kit.TAIL]),
            "_where": "the %d/3's plate: %s (styled on art/fight_new/%s_plate.png; stands on the site's wall)" % (st, key, key)}


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
    keys = [k for k, _s, _c in kit.SITES]
    assert sorted(keys) == sorted(SCENES), "SCENES aren't the kit's twelve sites"
    jobs = []
    seed = SEED0
    for key in keys:
        for st, scene in zip((2, 3), SCENES[key]):
            jobs.append(plate_job(key, st, scene, seed))
            seed += 1
    used = used_seeds()
    clash = {j["seed"]: used[j["seed"]] for j in jobs if j["seed"] in used}
    if clash:
        sys.exit("seeds already used elsewhere: %s - move SEED0" % clash)
    for j in jobs:
        if not os.path.exists(os.path.join(ROOT, j["style_image"].replace("res://", ""))):
            sys.exit("no %s on disk (%s)" % (j["style_image"], j["out"]))
    readme = [
        "FIAT STAGE PLATES (6 Nov, Matt: \"include the new backdrops and items from yesterday\"; docs/design/stages.md §6): "
        "a plate for each site's 2/3 and 3/3, %d jobs at 744x320, $0.15 each (about $%.2f)." % (len(jobs), 0.15 * len(jobs)),
        "Out art/fight_new/<site>_2_plate.png / _3_plate.png: RunView.stage_key finds them by name and stands each on its "
        "site's own wall (art/fight_walls/), the site's placed slots till F3 places the stage's - nothing to wire.",
        "Each styled on its site's plate (palette, light, painting style), the same viewpoint and layout family, a "
        "different spot of the same place. ++ --parallel 3.",
        "Regenerate with python3 tools/make_stage_plates_manifest.py; check with python3 tools/art_lint.py.",
    ]
    with open(os.path.join(ROOT, "tools", OWN), "w", encoding="utf-8") as f:
        json.dump({"_readme": readme, "jobs": jobs}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print("stage plates: %d jobs, seeds %d-%d" % (len(jobs), SEED0, seed - 1))


if __name__ == "__main__":
    main()
