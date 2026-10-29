"""The itemisation's pictures (29 Oct, docs/design/itemisation.md "Art: ~135 base pictures, three unique gloves"): one
picture a new base (176: Primary 47, Secondary 31, Helmet 12, Armour 11, Rig 16, Backpack 17, Charm 15, Gloves 27) and
the three unique gloves (The Sparky's Gloves redrawn as gloves, The Milkman's, The Safecracker's).

  python3 tools/make_items29_manifest.py
    -> tools/pixellab_items29_manifest.json        (every job: the 176 bases and the three uniques)
    -> tools/pixellab_items29_test_manifest.json   (the test: eight of the same jobs, one a new kind of view)

  then, once agreed: docs/art/handoff/art.flag naming the test first, the full manifest after Matt's word on the test.

The item template (make_item_manifests: the still-life prompt, TAIL, the four style references ref_01..04, every style
option on, the footprint x 64 px from data.gd's SIZE / FOOTPRINTS), one job a picture, written straight to the live
name art/items/<slug>.png, where Items.art finds it by the base's slug (the unique's own slug first) - nothing to wire.
The test's jobs are the full manifest's jobs (same out, seed and words), so a test picture that's kept is skipped by the
full run.

The Sparky's Gloves: its 64 x 64 charm picture is on disk under the live name and the old uniques manifest holds that
job, so the redraw goes to art/items_new/the_sparky_s_gloves.png (a new name: no --force, no two jobs on one file);
the session that reads art.done copies it over the live name once Matt keeps it.

Checked against docs/art/pixellab_lessons.md: the object alone, no setting ("no floor, wall, ground or sky" in the tail);
every thing usually printed, labelled, stamped or dialled is said plain / unprinted / no numbers in its subject; no
hand-writing or signature asked for; British coins n/a; a seed range of its own (122xxx, clear of every manifest - the
last used 121011)."""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_item_manifests as items  # noqa: E402  (TAIL, REFS, CELL, slug, footprint, src)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEED0 = 122000
SEED_UNIQUE = 122500
# rerolled after the 29 Oct test (Matt: punt gun cropped, the Safecracker's a twin of leather, the vest tactical, the
# derringer one barrel): a fixed seed gives near-identical rerolls, so these four take seed + 5000 (122xxx + 1000 lands on the 123xxx expeditions)
SEED_BUMP = {"Punt gun": 5000, "Derringer": 5000, "Door staff vest": 5000, "The Safecracker's Gloves": 5000}
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}
TAIL = items.TAIL + " No floor, wall, ground or sky around it."
PLAIN = "plain, unprinted, no lettering, no numbers, no logo"

# The bases' looks: docs (it_names.md, 29 Oct, after the language pass's fix round), one line each. A look changed here
# from the list is marked "# LESSON" with the lesson it answers; those are listed for Matt in the report.
LOOKS = {
    # Primary - melee
    "Lump hammer": "a short, square-headed club hammer with a stubby wooden handle",
    "Billhook": "a hooked hedging blade on a short wooden handle, rust along the edge",
    "Bike chain": "a length of greasy bicycle chain with one end bound in black tape",
    "Meat cleaver": "a wide square meat cleaver with a pale wooden handle",
    "Hot poker": "an iron fireside poker, its tip glowing orange",
    "Platelayer's maul": "a long-handled railway maul with a narrow double-faced steel head",
    "Cattle prod": "a long yellow livestock prod with two metal prongs at the tip, " + PLAIN,      # LESSON: usually branded
    "Cavalry sabre": "a broad curved sabre in a steel scabbard, with a plain steel bowl guard",
    "Collier's pick": "a heavy two-pointed miner's pickaxe on a worn ash handle",
    "Felling axe": "a long slim curved hickory haft with a narrow head, a leather edge-guard half on and a dab of orange "
                   "forestry paint on the haft, no numbers",                                         # LESSON: "paint mark" could be a number
    "Civic mace": "an ornate silver ceremonial mace with a crowned head",
    "Court sword": "a thin needle-bladed dress sword with a gilt shell guard and a white silk knot",
    # Primary - improvised
    "Speargun": "a long black underwater speargun with rubber bands and a steel spear",
    "Compound bow": "a camouflage compound bow with cams at each limb tip, lying on its side so it runs left to right",
    "Converted air rifle": "a wooden-stocked air rifle with a crude steel sleeve on the barrel",
    "Slam-fire shotgun": "a gun made of a galvanised scaffold tube with a scaffold coupler for a fore-grip and a door strap-hinge for a stock",
    "Punt gun": "a whole punt gun from muzzle to breech, both ends inside the frame with a little space around them: a barrel as long as a man, a rope breeching loop at the breech end and a short block of punt plank bolted under it",
    "Paintball gun": "a paintball marker with a big round hopper on top, " + PLAIN,                   # LESSON: usually branded
    "Arc-welder gun": "a gun built from an arc-welding torch, cables trailing to a battery pack",
    "Lathe-bored rifle": "a long heavy rifle with a thick turned-steel barrel and a plank stock",
    "Chain-driven repeater": "a gun with an exposed chain drive and a small electric motor",
    "Bench-made autocannon": "a stubby heavy cannon on a home-made frame with a box magazine",
    "Prototype rifle": "a sleek unfinished rifle, bare metal with taped wiring",
    # Primary - shotgun
    "Four-ten": "a slim single-barrel shotgun with a light wooden stock",
    "Goose gun": "a very long single-barrel shotgun with a sling made of baler twine",
    "Over-and-under": "a sporting over-and-under shotgun with engraved silver sides, scrollwork only, no letters",
    "Ten-bore": "a side-by-side shotgun with two outside hammers and swirled Damascus barrels",
    "Magnum pump": "a pump shotgun in reed-pattern camouflage with a thick recoil pad",
    "Pigeon gun": "a slim walnut-stocked semi-automatic shotgun with a gold trigger and a ventilated rib",
    "Rifled slug gun": "a scoped shotgun with a rifled barrel and a cantilever mount",
    "Marine shotgun": "a stainless steel pump shotgun with a black synthetic stock",
    "Dragon's-breath gun": "a black automatic shotgun with a flared muzzle, scorched at the end",
    "Siege shotgun": "a massive short-barrelled shotgun with a heavy box magazine",                  # "drum-less box feed": the negative invites a drum
    # Primary - rifle
    "Lever-action rifle": "a lever-action rifle with a walnut stock and a brass receiver",
    "Self-loading rifle": "a long rifle with brown plastic-wood furniture, a carry handle and a folded flash hider, chipped by cadets",
    "Vermin rifle": "a light scoped rifle with a long curved magazine",
    "Regimental rifle": "a long olive rifle with a folding stock and a grenade launcher under the barrel",
    "Big-game rifle": "an engraved double-barrel big-game rifle with a dark stock, scrollwork only, no letters",
    "Heavy-barrel rifle": "a benchrest rifle with a fat stainless barrel and a flat-bottomed stock resting on a small leather sandbag",
    "Castle guard rifle": "a polished black ceremonial-finish automatic rifle with a white sling",
    # Primary - smg
    "Wartime SMG": "a stamped tube-bodied SMG with the magazine sticking out sideways and a skeleton stock",
    "Unmarked SMG": "a square welded box-section SMG, the magazine up through the pistol grip, wrapped in grip tape",
    "Customs SMG": "a compact grey SMG with a folding stock and a fat magazine",
    "Navy SMG": "a dark compact SMG with a suppressor and a vertical grip",
    "Briefcase SMG": "a sleek SMG folded into a black briefcase-shaped frame",
    "Spiral-mag SMG": "an SMG with a long cylindrical spiral magazine along the top",
    "Ministerial SMG": "a black SMG with gilt detailing and a heavy barrel shroud",
    # Secondary - pistol
    "Derringer": "a tiny derringer with two short barrels stacked one above the other, both muzzles showing, a hammer, a spur trigger with no trigger guard and a pearl grip",
    "Pocket pistol": "a tiny pistol in a worn suede pocket holster, its blueing rubbed silver at the edges",
    "Target pistol": "a long-barrelled target pistol with a wooden thumbhole grip",
    "Police revolver": "a short-barrelled blued revolver in a black leather flap holster, no badge",
    "Polymer pistol": "a sand-coloured polymer pistol with a weapon light under the barrel",
    "Long-slide pistol": "a pistol with a long slide and an extended magazine",
    "Hunting revolver": "a long-barrelled stainless revolver with a scope rail",
    "Competition pistol": "a bright two-tone competition pistol with a compensator",
    "Cavalry revolver": "a long-barrelled revolver on a white lanyard, with a brass butt cap and a broad hinged frame",
    "Ambassador's revolver": "an engraved silver revolver lying in a fitted blue-velvet case, scrollwork only, no letters",
    "Field marshal's revolver": "a long-barrelled black revolver with a blank cream museum tag tied to the trigger guard and "
                                "a small gold crest on the grip, the tag and the crest without any lettering",   # LESSON: "museum card" invites writing
    # Secondary - smg
    "Broomhandle pistol": "a wartime box-magazine broomhandle pistol with its wooden holster stock clipped on",
    "Stockless SMG": "a compact SMG with an empty stock lug",
    "Three-round pistol": "a squat pistol with a fold-down front grip under the barrel",
    "Compact PDW": "a short boxy personal defence weapon with a top magazine",
    "Select-fire pistol": "a slim pistol with a wire shoulder stock clipped to the butt",
    "Folding PDW": "a folding personal defence weapon half-opened like a box",
    "Escort PDW": "a short PDW on a sling, with a red-dot sight and a car-door window punch on the stock",
    "Consular PDW": "a grey PDW lying in its open foam-lined case",
    "Overcoat machine pistol": "a sleek machine pistol with a long suppressor",
    "Crown PDW": "a polished PDW with a small gilt crest, no lettering, and a cord lanyard in regimental colours",
    # Secondary - improvised and melee
    "Catapult": "a wooden Y-shaped catapult with a leather pouch",
    "Screwdriver": "a long screwdriver with a yellow handle, the tip filed sharp, " + PLAIN,
    "Bike lock": "a heavy steel D-shaped bicycle lock, " + PLAIN,                                     # LESSON: usually branded
    "Hatchet": "a small camping hatchet with a rubber grip",
    "Zip gun": "a crude single-shot pistol made of a pipe on a wooden block",
    "Extendable baton": "a black telescopic steel baton extended",
    "Commando dagger": "a slim double-edged commando dagger with a ribbed brass grip",
    "Wheel brace": "a four-way cross-shaped wheel brace",
    "Pen gun": "a fat fountain pen with a tiny barrel at the nib end",
    "Spring gun": "a short iron spring-loaded tube gun with a wooden grip",
    # Helmet
    "Beekeeper's hat": "a wide-brimmed beekeeper's hat with a mesh veil",
    "Caving helmet": "a red caving helmet with a lamp on the front",
    "Scrum cap": "a padded rugby scrum cap with a chin strap",
    "Comms headset": "a padded headset with a boom microphone and an antenna",
    "Bump helmet": "a light skate-style tan shell with a bungee cord across it and hook-and-loop patches, no lamp",
    "Thermal headset": "a strap mount with a flip-down thermal monocle",
    "Respirator helmet": "a full helmet with an integrated respirator mask and two filters",
    "Night-sight helmet": "a helmet with twin night-vision tubes on a swing arm",
    "Ghillie hood": "a helmet buried under shaggy green hessian strips",
    "Arctic helmet": "a white-covered helmet with a fur-lined neck flap",
    "Search-team helmet": "a white helmet with a side camera and a plain hi-vis band, no lettering",   # LESSON: hi-vis bands carry POLICE
    "Surveillance helmet": "a sleek helmet bristling with small sensors and an earpiece",
    # Armour
    "Spraying overalls": "a pair of stiff green rubberised overalls with taped cuffs",
    "Slash-proof jacket": "a plain dark coat with a grey cut-resistant lining showing at the cuffs",
    "Foundry coat": "a long silvered heat-reflective foundry coat",
    "Low-profile vest": "a thin black vest inside an open grey hoodie",
    "Prison officer's vest": "a white shirt with black epaulettes over a thick soft vest, no badges",
    "Skeleton carrier": "a minimal plate carrier, just two plates and thin straps",
    "Arctic smock": "a padded white winter smock over body armour",
    "Plainclothes vest": "a slim dark plate vest inside an open sports jacket",
    "Tailored body armour": "a smart grey suit jacket with armour panels inside",
    "State protection vest": "a navy vest cut like a waistcoat, a coiled earpiece wire clipped to the strap and a small plain gold crest, no lettering",
    "Chainmail shark suit": "a full-body steel mesh suit with a mesh hood and a dive mask hanging off the neck",
    # Rig
    "Gardening apron": "a canvas gardening apron with deep front pockets",
    "Body warmer": "a padded navy body warmer with zipped pockets",
    "Lifeguard's vest": "a red tabard with a plain yellow band, a whistle on a cord and one big front pouch, no lettering",  # LESSON: "yellow lettering"
    "Tweed waistcoat": "a brown tweed waistcoat with a leather shoulder patch and shell loops",
    "Door staff vest": "a plain black stab vest, smooth and slab-sided with no pouches or webbing, a clip-on badge holder on the chest with a blank card in it, a hi-vis armband, "
                       "no lettering anywhere",                                                    # LESSON: "SECURITY in white" is lettering
    "Quick-release rig": "a chest rig with bright pull tabs on each pouch",
    "Public order rig": "a padded police chest rig with shoulder guards, no badges or lettering",
    "Load carrier": "a wide olive rig with two deep rows of pouches and shoulder yokes as broad as a rucksack's",
    "Slick rig": "a slim low-profile chest rig with flat pouches",
    "Air ambulance vest": "a flight-suit-orange vest with a winch harness ring at the chest and pouches on the thighs, no lettering",
    "Pathfinder rig": "a woodland-camouflage chest rig with a compass pouch and a map case, the map blank",
    "Counter-terror rig": "a black chest rig with a gas-mask bag on the hip",
    "Hostage-rescue rig": "a black rig with rows of elastic loops holding syringes and a torch",
    "Shield-team rig": "a one-sided rig with a big plated front and a pad on the right shoulder only",
    "Desert patrol rig": "a sand-coloured chest rig with bottle pouches",
    "Royal escort rig": "a navy chest rig with red piping and a small plain gold crest, no lettering",
    # Backpack
    "Feed sack": "a green-and-yellow striped feed sack, unprinted, tied with orange baler twine",      # LESSON: "printed feed sack"
    "Tartan shopper": "a tartan shopping bag on a folded wheeled frame",
    "Daysack": "a small olive military daysack",
    "Dumpy bag": "a cut-down white builders' bulk bag with shoulder straps, " + PLAIN,                 # LESSON: bulk bags are printed
    "Messenger bag": "a black cross-body messenger bag with a big flap",
    "Sailor's bag": "a long white canvas sea bag with a rope drawstring, standing on end",
    "Mule pack": "a tall pack with bulging side pockets, a sleeping mat strapped across the top and a mess tin hanging off it",
    "Sniper's drag bag": "a long padded camouflage rifle drag bag with straps, standing on end",
    "Swag bag": "a black holdall with a stripy jumper and a torch poking out of the open zip",
    "Search-and-rescue pack": "an orange search-and-rescue pack with reflective strips, no lettering",
    "Security van bag": "a grey security case-bag with a chain and a lock",
    "Clamshell pack": "a clamshell backpack opened flat with organised pockets",
    "Ingot sack": "a heavy canvas bank bag with a faded blank stencilled patch, no numbers or lettering",  # LESSON: "stencilled numbers"
    "Alpine pack": "a narrow grey alpine climbing pack with an ice-axe loop",
    "Strongroom bag": "a long black reinforced duffel with a steel rod through both handles",
    "Freefall pack": "a streamlined jump pack with oxygen-bottle sleeves",
    "Wax-sealed bag": "a red leather bag with a plain wax seal and brass clasps",
    # Charm
    "Box of matches": "a small worn matchbox, half open, " + PLAIN,                                  # LESSON: usually printed
    "Old spark plug": "a single old spark plug with a cracked white ceramic, " + PLAIN,                # LESSON: usually printed
    "Gold tooth": "a single gold tooth crown",
    "Barber's razor": "a folded straight razor with a horn handle",
    "Pocket watch": "a silver pocket watch on a chain, case open, a plain white face with no numbers", # LESSON: clock faces
    "Brass canary": "a small brass canary ornament on a perch",
    "Gold cufflinks": "a pair of gold cufflinks engraved with a plain pattern, no initials",
    "Ice-hockey puck": "a black ice-hockey puck, scuffed, a strip of white tape round its edge, " + PLAIN,  # LESSON: "a signature" is hand-writing
    "Dragon brooch": "a red enamel Welsh dragon brooch",
    "Diamond tiepin": "a gold tiepin set with a single diamond",
    "Glass insulator": "a green glass telegraph-pole insulator, no embossed lettering",
    "Gold cigarette case": "a gold cigarette case engraved with a plain pattern, closed, no initials",
    "Sword knot": "a gold and crimson braided sword tassel",
    "Uncut diamond": "a rough uncut diamond, cloudy and pale",
    "Apothecary's vial": "a small cobalt-blue glass vial with a cork stopper, no label",
    # Gloves
    "Gardening gloves": "a pair of green gardening gloves with rubber palms",
    "Woolly gloves": "a pair of knitted woollen gloves, one darned",
    "Work gloves": "a pair of tan canvas-and-leather work gloves",
    "Rigger gloves": "a pair of thick yellow-hide rigger gloves",
    "Cycling mitts": "a pair of padded fingerless cycling mitts",
    "Driving gloves": "a pair of brown leather driving gloves with knuckle holes",
    "Leather gloves": "a pair of plain black leather gloves",
    "Goalkeeper gloves": "a pair of chunky padded goalkeeper gloves, " + PLAIN,                       # LESSON: usually branded
    "Shooting gloves": "a pair of tweed-backed leather gloves with the trigger finger cut off",
    "Roofer's gloves": "a pair of orange gloves with black rubber dots",
    "Racing gloves": "a pair of red and white motorsport racing gloves, " + PLAIN,                    # LESSON: usually branded
    "Tactical gloves": "a pair of black gloves with hard knuckle pads",
    "Cut-resistant gloves": "a pair of speckled white-and-blue steel-knit gloves with long cuffs",
    "Fell-runner's gloves": "a pair of thin bright lime-green windproof running gloves, " + PLAIN,   # colour: "bright" picked as lime (see report)
    "Armourer's gloves": "a pair of thin black-dipped gloves with oil stains",
    "Riot gauntlets": "a pair of black gauntlets with armoured backs",
    "Pilot's gloves": "a pair of thin sage-green flight gloves",
    "Stalker's gloves": "a pair of brown-and-green woodland gloves with the trigger finger folded back on a snap",
    "Firefighter's gloves": "a pair of thick black and yellow firefighter's gloves",
    "Paratrooper's gloves": "a pair of black leather gloves with long maroon cuffs and a wrist strap",
    "Close-combat gloves": "a pair of olive gloves with leather finger pads, a padded wrist strap and tape round the cuff",
    "Flight-deck gloves": "a pair of bright blue flight-deck crew gloves with grey grip patches, " + PLAIN,  # colour: "bright" picked as blue
    "Abseiling gloves": "a pair of leather-palmed climbing gloves",
    "Counter-sniper gloves": "a pair of thin grey gloves with a blank card in a clear wrist window, no numbers",  # LESSON: a "data card" carries print
    "EOD gauntlets": "a pair of bulky padded tan gauntlets with cuffs to the elbow and thin grey fingertips",
    "Dress uniform gloves": "a pair of crisp white ceremonial dress gloves",
    "Special forces gloves": "a pair of black-and-tan two-tone gloves with a carbon knuckle plate",
}

# The three unique gloves (data.gd UNIQUES: all on the Gloves slot, so the slot's footprint)
UNIQUE_LOOKS = {
    "The Sparky's Gloves": "a pair of thick orange rubber electrician's insulating gauntlets reaching to the elbow, "
                           "cracked at the knuckles, " + PLAIN + ", no stamp",                       # LESSON: the old "test stamp"
    "The Milkman's Gloves": "a pair of fingerless grey-blue knitted woollen gloves, the cuffs unravelling, a darn at one thumb",
    "The Safecracker's Gloves": "a pair of thin black kid-leather fingerless gloves, every finger cut off at the first knuckle, the bare cut edges worn pale and the leather sanded thin",
}
UNIQUE_OUT = {"The Sparky's Gloves": "art/items_new/the_sparky_s_gloves.png"}     # its old picture holds the live name

# The test: one of each new kind of view or risk, before the 179 (eight jobs, the same jobs as the full manifest).
TEST = ["Work gloves", "Leather gloves", "The Safecracker's Gloves", "Lump hammer", "Punt gun", "Derringer",
        "Door staff vest", "Pocket watch"]


# not a muzzle-left view: a bow, a catapult, and the two guns shown in their cases (a case is seen from above; "side-on"
# against "lying in its case" would fight)
FROM_ABOVE = {"Compound bow", "Catapult", "Consular PDW", "Ambassador's revolver"}


def base_type(name):
    m = re.search(r'\{"name": "%s", "type": "(\w+)"' % re.escape(name), items.src)
    return m.group(1) if m else ""


def section_of(name):
    for slot in ("Primary", "Secondary", "Helmet", "Armour", "Rig", "Backpack", "Charm", "Gloves"):
        m = re.search(r'\n\t"%s": \[\n(.*?)\n\t\],' % slot, items.src, re.S)
        if m and ('{"name": "%s"' % name) in m.group(1):
            return slot
    return ""


def describe(slot, name, look):
    """The still-life prompt for a base by its slot and type (the make_item_manifests views)."""
    w, h = items.footprint(slot, name)
    t = base_type(name)
    if slot in ("Primary", "Secondary") and (t == "melee" or name in FROM_ABOVE):
        lay = ", laid level with its long axis left to right" if w > h else ""
        return "A realistic painted pixel-art still-life of %s, one object alone, lying flat, seen from above%s, filling the frame, worn and used." % (look, lay)
    if slot in ("Primary", "Secondary"):
        lay = ", laid level and filling the frame left to right" if w >= 3 else ", filling the frame"
        return ("A realistic painted pixel-art still-life of %s, seen exactly side-on with the muzzle pointing left%s, as it "
                "might be found in post-collapse Britain, worn and used." % (look, lay))
    if slot == "Helmet":
        return ("A realistic painted pixel-art still-life of %s, seen from the front and slightly above, resting on nothing, "
                "filling the frame top to bottom, scuffed, the markings worn off, no head in it." % look)
    if slot == "Armour":
        return ("A realistic painted pixel-art still-life of a single piece of protective clothing - %s - hung flat as if on a "
                "hook, seen from the front, filling the frame top to bottom, no person wearing it, straps loose, stained, "
                "worn. Clothing or a vest, never crockery." % look)
    if slot == "Rig":
        return ("A realistic painted pixel-art still-life of %s, hung flat as if on a hook, seen from the front, filling the "
                "frame, no person wearing it, worn, repaired with tape and stitching." % look)
    if slot == "Backpack":
        return ("A realistic painted pixel-art still-life of %s, standing upright, seen from the front, filling the frame, "
                "half full, zips and buckles worn, repaired with tape and stitching." % look)
    if slot == "Charm":
        return ("A realistic painted pixel-art still-life of %s, a single small object filling the frame, seen from above at "
                "a slight angle, lit from one side." % look)
    if slot == "Gloves":
        return ("A realistic painted pixel-art still-life of %s, laid flat side by side, fingers up, seen from above, filling "
                "the frame, no hands in them, worn and used." % look)
    raise ValueError(slot)


def job(out, slot, name, look, seed, where):
    w, h = items.footprint(slot, name)
    return {
        "out": out,
        "endpoint": "generate-image-v2",
        "description": describe(slot, name, look) + TAIL,
        "width": w * items.CELL,
        "height": h * items.CELL,
        "no_background": True,
        "seed": seed,
        "single": True,
        "style_image": items.REFS[seed % len(items.REFS)],
        "style_options": STYLE,
        "_where": where,
    }


def main():
    jobs = []
    seed = SEED0
    for name, look in LOOKS.items():
        slot = section_of(name)
        assert slot, "not a base in data.gd: %s" % name
        w, h = items.footprint(slot, name)
        jobs.append(job("art/items/%s.png" % items.slug(name), slot, name, look, seed + SEED_BUMP.get(name, 0),
                        "%s, %s, %dx%d cells" % (slot, base_type(name) or "-", w, h)))
        seed += 1
    seed = SEED_UNIQUE
    body = re.search(r"const UNIQUES := \[(.*?)\n\]", items.src, re.S).group(1)
    uniq = dict((n, (s, b)) for n, s, b in re.findall(r'\{"name": "([^"]+)", "slot": "(\w+)", "base": "([^"]+)"', body))
    for name, look in UNIQUE_LOOKS.items():
        slot, base = uniq[name]
        jobs.append(job(UNIQUE_OUT.get(name, "art/items/%s.png" % items.slug(name)), slot, base, look, seed + SEED_BUMP.get(name, 0),
                        "unique on %s (%s)" % (base, slot)))
        seed += 1
    # every new base in data.gd has a look (none missed, none extra)
    assert len(LOOKS) == 176, len(LOOKS)
    tested = set(UNIQUE_OUT.get(n, "art/items/%s.png" % items.slug(n)) for n in TEST)  # the test run's, on disk by design
    for j in jobs:
        assert j["out"] in tested or not os.path.exists(os.path.join(ROOT, j["out"])), "already on disk: %s" % j["out"]
    readme = [
        "FIAT ITEMS 29 (29 Oct, the itemisation): the 176 new bases' pictures and the three unique gloves - %d jobs, "
        "all at $0.08 (every canvas under 65k px). One job a picture, straight to the live name art/items/<slug>.png "
        "(Items.art finds it by slug; nothing to wire), the footprint x 64 px from data.gd." % len(jobs),
        "The item template of make_item_manifests (TAIL, ref_01..04 as style_image rotated, every style option on). "
        "Guns side-on, muzzle left (the stash icons' view, not the fight hands').",
        "The Sparky's Gloves goes to art/items_new/ (its 64 px charm picture holds the live name): copy it over "
        "art/items/the_sparky_s_gloves.png once kept.",
        "Run the test first: tools/pixellab_items29_test_manifest.json (eight of these jobs). Then this, ++ --parallel 3.",
        "Regenerate with python3 tools/make_items29_manifest.py; check with python3 tools/art_lint.py.",
    ]
    tools = os.path.join(ROOT, "tools")
    with open(os.path.join(tools, "pixellab_items29_manifest.json"), "w", encoding="utf-8") as f:
        json.dump({"_readme": readme, "jobs": jobs}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    by_name = {}
    for name in list(LOOKS) + list(UNIQUE_LOOKS):
        out = UNIQUE_OUT.get(name, "art/items/%s.png" % items.slug(name))
        by_name[name] = next(j for j in jobs if j["out"] == out)
    test = [by_name[n] for n in TEST]
    treadme = [
        "FIAT ITEMS 29 - THE TEST (29 Oct): %d of the full manifest's jobs (same out, seed, words), one of each new kind: "
        "gloves (a new slot, 2x2 cells - the black pair and the unique beside it), a 2x1 melee, a 5x1 gun (the wide "
        "aspect), a 1x1 pistol, a lettering risk (the door staff vest's blank back) and a dial (the pocket watch). "
        "Judged in the game before the other %d; a kept picture is skipped by the full run." % (len(test), len(jobs) - len(test)),
        "Regenerate with python3 tools/make_items29_manifest.py.",
    ]
    with open(os.path.join(tools, "pixellab_items29_test_manifest.json"), "w", encoding="utf-8") as f:
        json.dump({"_readme": treadme, "jobs": test}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    from collections import Counter
    print("items29: %d jobs (%s); test %d" % (len(jobs), ", ".join("%s %d" % kv for kv in
          Counter(j["_where"].split(",")[0].split(" (")[0] for j in jobs).items()), len(test)))


if __name__ == "__main__":
    main()
