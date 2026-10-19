"""The room cards' box art (18 Oct, Matt: "these screens could use some art for the boxes"; option C on the canvas
'Room card art': a strip of scene across the top of each box). Nine rooms, three boxes each: a 384x96 strip per box,
styled on the room's own header (art/places), so each card reads as one place.
Test art first: --test writes the Map's three only, judged in the game before the other 24 are made.
  python3 tools/make_room_box_manifest.py --test     (the Map's three: pixellab_room_boxes_test_manifest.json)
  python3 tools/make_room_box_manifest.py            (the other 24: pixellab_room_boxes_manifest.json)
  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_room_boxes_test_manifest.json
Written to art/room_boxes/, so nothing live is touched."""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 384, 96
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}
LOOK = ("Muted blue-grey palette, dark navy shadows, overcast evening light, one or two warm orange lamps. A wide, low "
        "strip: the subject sits across the middle, filling the width, with nothing important in the top or bottom eighth "
        "(the strip is cropped to fit its box). Only the palette, light and painting style of the style image, not its view or its subject. One continuous scene edge to edge, no border, no frame. No people unless "
        "the brief names them, no text, no readable signage, numbers or lettering.")

# [room key, header art, box label (for the record), the strip's scene]
BOXES = [
    ["map", "the_map", "Sites", "a folded street map spread on the bonnet of a car, only roads, blocks and a river drawn on it, no names printed, a red pin pushed into it, a torch beside it"],
    ["map", "the_map", "Zones", "a ring road at dusk seen from a footbridge, three slip roads leading off it into the haze, their road signs blank, the town getting denser beyond"],
    ["map", "the_map", "The heads", "three photographs of men in balaclavas, head and shoulders, no placards or captions, pinned to a corkboard, red string running between the pins"],
    ["kit", "the_kit_room", "The body", "a padded work jacket and a hard hat hung on hooks on a breeze-block wall, boots on the floor below"],
    ["kit", "the_kit_room", "The rig", "a chest rig laid flat on a table, its pouches open, bandages and a plain cardboard box of shells beside it"],
    ["kit", "the_kit_room", "The stash", "a row of grey steel cabinets with padlocks, one door ajar on stacked boxes and a gun case"],
    ["stats", "the_stats", "Attack", "a revolver and a claw hammer side by side on a folded oilcloth, spent cases scattered"],
    ["stats", "the_stats", "Defence", "a dented hard hat and a stab vest on a chair, a strip of tape over a split in the vest"],
    ["stats", "the_stats", "The record", "an open notebook of tally marks and struck-through lines, a pencil stub and a mug ring on the page"],
    ["training", "the_caravan", "Their past", "a creased work ID badge on a lanyard, its print worn blank, and an old photo, lying on a caravan's fold-down table"],
    ["training", "the_caravan", "Their trees", "a sapling growing in a battered paint tin on a caravan step, a kettle beside it"],
    ["training", "the_caravan", "The Pitch's tree", "a branching tree carved into an old fence post, years of knife marks around it"],
    ["clinic", "the_clinic", "Treatment", "a needle, a reel of thread and a steel kidney dish on a clean towel under a work lamp"],
    ["clinic", "the_clinic", "The shelf", "a wall shelf of plain unlabelled brown pill bottles and plain boxed dressings, a few gaps where stock has gone"],
    ["clinic", "the_clinic", "Your meds", "a bandage roll, a plain foil blister pack of painkillers and a field dressing tucked in a belt pouch"],
    ["fence", "the_fence", "The stash", "a holdall on the ground with finds spilling out: a radio, a watch, a gun part, a tin"],
    ["fence", "the_fence", "The shelf", "a trestle table of goods under a tarp, taped-up boxes stacked behind, a lantern hanging"],
    ["fence", "the_fence", "Contracts", "a scrap of card covered in scrawled pencil marks, nothing readable, hung on a nail in a wooden post, a pen tied on string"],
    ["workshop", "the_workshop", "Guns", "a pump shotgun stripped on a workbench, a scope and a stock laid out beside it"],
    ["workshop", "the_workshop", "Sockets", "an open socket set in its case on a bench, a few loose sockets and a small glowing stone"],
    ["workshop", "the_workshop", "Craft", "a bench vice gripping a gun part that glows faintly, filings and a file on the bench"],
    ["yard", "the_yard", "The buildings", "a row of sheds built from pallets and corrugated sheet in a muddy yard, smoke from a flue"],
    ["yard", "the_yard", "Ranks", "a wooden stepladder against a half-built shed wall, a new course of blocks going on"],
    ["yard", "the_yard", "Moving on", "a white van with no number plate, loaded up with its roof rack strapped down, back doors open, pulling out of a yard"],
    ["radio", "the_radio", "The decoder", "three torn paper scraps covered in scribbled pencil marks, nothing readable, under a bulldog clip beside a radio set"],
    ["radio", "the_radio", "Signals", "a lattice radio mast against a dark sky, one red light at its top, cables running down"],
    ["radio", "the_radio", "The Dial", "a big Bakelite tuning dial glowing amber on an old military radio set, plain tick marks on it and no numbers, a hand-drawn chart of lines beside it"],
]


def job(i, b):
    room, place, label, scene = b
    n = [x for x in BOXES if x[0] == room].index(b) + 1
    return {"out": "art/room_boxes/%s_%d.png" % (room, n), "endpoint": "generate-image-v2", "width": W, "height": H,
            "no_background": False, "single": True, "seed": 99000 + i, "style_options": STYLE,
            "style_image": "res://art/places/%s.png" % place,
            "description": "Pixel art, a wide close view: " + scene + ". " + LOOK,
            "_where": "the %s room card's box: %s" % (room, label)}


def main():
    test = "--test" in sys.argv
    jobs = [job(i, b) for i, b in enumerate(BOXES) if (b[0] == "map") == test]
    name = "pixellab_room_boxes_test_manifest.json" if test else "pixellab_room_boxes_manifest.json"
    m = {"_readme": ["FIAT ROOM CARD BOXES (18 Oct, Matt: option C, a strip of scene on each box). %s" % (
                         "The test: the Map's three, judged in the game before the other 24." if test else "The other 24, after the Map's test."),
                     "Run: godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/%s   (++ --dry-run to list; ++ --only <name> ++ --force to reroll)" % name,
                     "Regenerate with python3 tools/make_room_box_manifest.py%s." % (" --test" if test else "")],
         "jobs": jobs}
    with open(os.path.join(ROOT, "tools", name), "w", encoding="utf-8", newline="\n") as f:
        json.dump(m, f, indent=1, ensure_ascii=False)
    print("%d jobs -> tools/%s" % (len(jobs), name))


if __name__ == "__main__":
    main()
