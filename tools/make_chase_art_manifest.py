"""The endgame chase's art (25 Oct, Matt: "proceed with the lot + any art without my intervention"). One manifest:

  python3 tools/make_chase_art_manifest.py  ->  tools/pixellab_chase_art_manifest.json

  C:\\Godot\\godot.console.exe --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_chase_art_manifest.json ++ --parallel 3
  (++ --dry-run to list; one that came out wrong: ++ --only <name> ++ --force)

What's in it, and where each lands (every file new; nothing on disk is overwritten):
- The order's three new uniques (art/items/<slug>.png, the base's footprint x 64 px, as make_item_manifests' uniques):
  The Lineman's Tool Bag (a Hiking pack, 3x3), The Registrar's Stamp (a charm, 1x1), The Issuer's Revolver (a
  secondary, 2x1, side-on, the muzzle left, as every item picture). Found by name, no wiring.
- The web's nodes with no picture (art/nodes/<slug>.png, 64 px, transparent): joints B's renamed notables and element
  halves (Defib, Cut-throat, Tear gas, Paramedic's paddles, Drifter's razor, Recruit's gas) and the Recruit's
  fourteen fillers (Ordnance and Drill), which the skills' run left out. The web art's node template.

Checked against docs/art/pixellab_lessons.md: every object alone with no setting; everything usually printed or
stamped said plain, unprinted, no lettering, no number (the stamp's face is blank rubber); no dials or labels with
marks; no "sign"; a seed range of its own (104xxx).
"""
import json
import os

SEED0 = 104000                # clear of every other manifest's seeds (web art 98xxx, walls 101xxx, generator 102xxx, skills 103xxx)
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}

ICON = ("A realistic painted pixel-art still-life of %s. The object alone and cut out, centred and filling the frame: no floor, wall, ground or sky around it, a single bold "
        "silhouette that still reads at a quarter of this size, soft directional overcast daylight, natural material "
        "rendering with painterly shading; no black outlines, not anime, not a cartoon, not a glossy video-game icon. "
        "Muted cool northern palette, worn, nothing new. Nothing else in the frame, no hands, no person, no text, no "
        "logos, no numbers, every label, clock face, page, note and packet plain and blank, a transparent background.")

TAIL = (" One object centred and filling the frame, soft directional overcast daylight, natural material rendering with fine "
        "detail and painterly shading; no black outlines, no flat cel shading, not anime, not a cartoon, not a glossy "
        "video-game item; the look of a real object photographed on a grey day in a country that has run out of money. "
        "Muted cool northern palette, worn and repaired, nothing new. Nothing else in the frame, no hands, no person, "
        "no text, no logos, a plain dark neutral background.")

UNIQUES = [
    ("the_lineman_s_tool_bag", 192, 192, "res://art/reference/items/ref_02.png",
     "a single battered canvas lineman's tool bag worn as a backpack, heavy brown duck cloth gone dark with oil, leather "
     "straps and corners, a coil of copper wire and the rubber handles of insulated pliers poking from its open top, "
     "a pair of rubber gloves clipped to one strap, plain, no lettering, no badge"),
    ("the_registrar_s_stamp", 64, 64, "res://art/reference/items/ref_03.png",
     "a single old rubber desk stamp with a turned wooden handle worn smooth and a brass collar, its rubber face "
     "blank and smeared with red ink, plain, no lettering, no numbers, nothing printed on it"),
    ("the_issuer_s_revolver", 128, 64, "res://art/reference/items/ref_01.png",
     "a single old officer's service revolver, seen exactly side-on with the muzzle pointing left, laid level and "
     "filling the frame left to right: blued steel worn silver at the edges, a lanyard ring on the butt, chequered "
     "walnut grips, kept clean and never fired, plain, no engraving, no lettering"),
]

NODES = [
    # joints B's renamed notables and element halves (24 Oct)
    ("defib", "Shifts: Defib (the Paramedic)", "a pair of old defibrillator paddles with coiled grey leads, plain, no lettering"),
    ("cut_throat", "Luck: Cut-throat (the Drifter)", "an open cut-throat razor with a bone handle, its blade nicked, plain"),
    ("tear_gas", "Drill: Tear gas (the Recruit)", "a dented olive tear-gas canister with a pale wisp leaking from its top, plain, unprinted, no markings"),
    ("paramedic_s_paddles", "Live: Paramedic's paddles", "a single defibrillator paddle with a spark jumping from its plate, plain, no lettering"),
    ("drifter_s_razor", "Blades: Drifter's razor", "a folded straight razor wrapped in a strip of bloodied rag"),
    ("recruit_s_gas", "The Rat Man: Recruit's gas", "an old army respirator with round eyepieces and a green filter canister, plain, no markings"),
    # the Recruit's fillers, Ordnance
    ("cookhouse", "Ordnance: Cookhouse", "a dented aluminium army mess tin with a folding handle, plain"),
    ("detonators", "Ordnance: Detonators", "a small bundle of copper detonator tubes with twisted wire tails, plain, unprinted"),
    ("flak_jacket", "Ordnance: Flak jacket", "an olive flak jacket with padded panels, worn at the collar, plain, no badge"),
    ("pull_the_pin", "Ordnance: Pull the pin", "a grenade's pin and ring on their own, the ring bent, the pin bright steel"),
    ("sandbags", "Ordnance: Sandbags", "two stacked hessian sandbags, tied at the neck, plain, unprinted"),
    ("spare_pouch", "Ordnance: Spare pouch", "an olive webbing ammunition pouch with its flap buttoned down, plain, no markings"),
    ("square_bashing", "Ordnance: Square bashing", "a pair of black parade boots with polished toecaps, laces tight"),
    # the Recruit's fillers, Drill
    ("at_ease", "Drill: At ease", "a khaki beret folded flat, plain, no badge"),
    ("brasso", "Drill: Brasso", "a small round tin of brass polish with its lid off and a yellow cloth, plain, unprinted, no lettering"),
    ("kit_inspection", "Drill: Kit inspection", "a neatly folded olive army blanket with a mess tin and a razor laid square on top of it"),
    ("lights_out", "Drill: Lights out", "an old army torch with its lens dark, plain, no markings"),
    ("range_day", "Drill: Range day", "a single round paper target with its rings left blank and three holes torn near the middle, no numbers"),
    ("reveille", "Drill: Reveille", "a dented brass bugle with a frayed khaki cord, plain"),
    ("spit_and_polish", "Drill: Spit and polish", "a single black boot with a mirror toecap beside a round tin of black polish and a cloth, the tin plain, unprinted"),
]


def jobs():
    out = []
    seed = SEED0
    for slug, w, h, ref, subject in UNIQUES:
        out.append({"out": "art/items/%s.png" % slug, "endpoint": "generate-image-v2",
                    "description": "A realistic painted pixel-art still-life of %s." % subject + TAIL,
                    "width": w, "height": h, "no_background": True, "seed": seed, "single": True,
                    "style_image": ref, "style_options": STYLE, "_where": "the item's picture: the stash, the pick, the card"})
        seed += 10
    seed = SEED0 + 100
    for slug, where, obj in NODES:
        out.append({"out": "art/nodes/%s.png" % slug, "endpoint": "generate-image-v2", "width": 64, "height": 64,
                    "no_background": True, "single": True, "seed": seed, "style_options": STYLE,
                    "style_image": "res://art/ui/dps.png", "reference_images": ["res://art/ui/dps.png", "res://art/ui/hp.png"],
                    "description": ICON % obj, "_where": "Training's web: " + where})
        seed += 10
    return out


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    m = {"_readme": [__doc__.strip().splitlines()[0], "Generated by tools/make_chase_art_manifest.py: fix the generator, then mirror into this file."],
         "jobs": jobs()}
    with open(os.path.join(here, "pixellab_chase_art_manifest.json"), "w") as f:
        json.dump(m, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print("%d jobs" % len(m["jobs"]))


if __name__ == "__main__":
    main()
