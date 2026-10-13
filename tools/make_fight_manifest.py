"""The fight's full art (13 Oct, Matt: the slice reads - "provide the manifest now"). Writes
tools/pixellab_fight_manifest.json: per site a plate and its cover; per zone two gang members three ways; the four
heads three ways; the runner's hands per weapon type. Out to art/fight/. The Parade's plate is the test one, copied
over by hand (cleaned by Matt); its cover is new - taller, for the duck (Matt: "the wall is too short when crouching").

Run: python tools/make_fight_manifest.py, then
  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_fight_manifest.json
(++ --dry-run to list; one wrong: ++ --only <name> ++ --force). Stands come before their poses - the poses use them."""
import json

TAIL = ("Realistic painted pixel art, soft overcast light, muted cool northern palette, worn and lived-in, "
        "post-collapse Britain on a grey day; no black outlines, not anime, not a cartoon, not glossy; no text, no logos.")
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}
# the frame's layout, so every plate takes the slice's three places: the near one close on the right, the middle one
# centre-right on open ground, the far one in a doorway or gap on the left a long way off
LAYOUT = ("Composed for three figures to stand in later: clear open ground in the middle distance just right of centre, "
          "a dark doorway or gap on the left side well down the scene, and room in the right foreground. "
          "The ground runs across the lower third; the horizon sits a third of the way down.")
POV = "A first-person view at crouching eye level, as if from behind cover in a light-gun arcade game, "
EMPTY = "Nobody in the scene, empty and waiting."

SITES = [  # key, the place's art, what's there, the cover across the frame's foot
    ("the_allotments", "the_allotments", "across overgrown allotments at the edge of a town: sheds of corrugated iron and old doors, runner-bean canes, water butts, a polytunnel with its plastic torn, a rusting wheelbarrow, a shed with its door hanging open",
     "a raised vegetable bed built of old railway sleepers, weeds and a broken cane over the top"),
    ("the_garden_centre", "the_garden_centre", "down an aisle of a looted garden centre: a glasshouse roof with panes out, toppled shelving of pots, dead plants on trolleys, a café counter, the exit doors at the end standing open",
     "a pallet stacked with split compost bags, soil spilling over the edge"),
    ("top_farm", "top_farm", "across a farmyard: a stone barn with its big doors open, a rusting tractor, round bales in black plastic, a muddy yard with puddles, a farmhouse back door ajar",
     "a low dry-stone wall with a gate post, nettles at its foot"),
    ("ransacked_streets", "ransacked_streets", "down a ransacked terraced street: front doors kicked in, a sofa in the road, a car on its roof, washing still on a line between houses, a ginnel between two terraces",
     "a low front-garden wall of pebbledash with a toppled wheelie bin against it"),
    ("the_parade", "the_parade", None,
     "a low wall of grimy red brick with a broken concrete coping, moss in the joints, a crisp packet caught on it"),
    ("the_retail_park", "the_retail_park", "across a retail park car park: big box stores with their shutters half up, abandoned cars at angles, a trolley shelter, lamp posts, a carpet warehouse's loading bay open on the left",
     "a long concrete planter with dead shrubs and a run of trolleys jammed against it"),
    ("the_pleasure_park", "the_pleasure_park", "into a dead seaside pleasure park: a stalled waltzer, a ghost train's dark entrance, a burger kiosk with its hatch up, bunting in tatters, a helter-skelter in the haze",
     "the side of an overturned dodgem car, its pole bent"),
    ("shopping_centre", "shopping_centre", "along a shopping centre's upper mall in failing daylight from the roof: shop shutters, a dead escalator, a fountain dried up, a department store's dark entrance, litter everywhere",
     "a row of upturned mall benches and a broken planter edge"),
    ("the_bank", "the_bank", "across a high-street bank's banking hall: teller windows with their glass starred, a queue rope fallen, leaflets on the floor, a door marked private open onto the dark, the vault corridor beyond",
     "the front of a wooden counter with a cracked glass screen above it, pens on chains hanging"),
    ("the_services", "the_services", "across a motorway services forecourt: petrol pumps, a shop with its glass smashed, a jack-knifed lorry, the canopy lights out, the slip road in haze",
     "a run of steel crash barrier, dented, with a traffic cone tipped against it"),
    ("the_hospital", "the_hospital", "down a hospital corridor: trolleys left at angles, curtains pulled round bays, a nurses' station, fire doors propped open, signs to wards, strip lights out but for one",
     "an overturned hospital trolley and its thin mattress on its side"),
    ("the_barracks", "the_barracks", "across an army barracks' parade ground: brick accommodation blocks, a guardroom with its barrier up, a Land Rover with flat tyres, a flagpole with no flag, a hangar door open on the left",
     "a low wall of sandbags, some split, a strip of hessian flapping"),
]

GANGS = [  # zone, two members: who, what they hold standing, what they fire
    ("the_outskirts", "the_people/gang_the_outskirts", [
        ("a man in his thirties from a gang off the allotments and the farms: a wax jacket with a hi-vis vest over it, a balaclava rolled up as a hat, wellies, mud on his face", "a billhook held low", "a double-barrelled shotgun"),
        ("a weathered woman in her fifties from the same gang: a fleece and a body-warmer, a woolly hat, wellies, a scarf round the neck", "a garden fork held across her", "an air rifle"),
    ]),
    ("the_estate", "the_people/gang_the_estate", [
        ("a young estate gang member in a grey hoodie with the hood up, a scarf over the lower face, tracksuit bottoms and dirty trainers", "a spiked baseball bat low at his side", "a sawn-off shotgun"),
        ("a young woman from the same estate gang in a black puffer jacket, a cap under her hood, a snood up over her nose, leggings and trainers", "a kitchen knife held low", "a small pistol held sideways"),
    ]),
    ("the_town", "the_people/gang_the_town", [
        ("a man in his thirties from a town-centre gang: a padded work jacket, a rag tied round one wrist, a hard face with a cut lip, work boots", "a crowbar held low", "a pistol"),
        ("a heavy-set man from the same town gang in a road-crew orange jacket gone grey with dirt, a beanie, a dust mask pulled down", "a sledgehammer over his shoulder", "a pump-action shotgun"),
    ]),
    ("the_city", "the_people/gang_the_city", [
        ("a soldier turned gangster from the city: an army greatcoat, a beret pushed back, webbing over the chest, a gas mask hanging at the neck, a scar through one eyebrow", "a rifle held across the body at the ready, not aimed", "a rifle"),
        ("a second soldier turned gangster from the same city crew: a combat helmet, body armour over a camouflage smock, knee pads, a face mask", "a submachine gun held down at the hip", "a submachine gun in a short burst"),
    ]),
]

HEADS = [  # file, who, standing, firing
    ("the_gamekeeper", "a gamekeeper in his sixties: a tweed shooting jacket and flat cap, a waxed cartridge bag over one shoulder, moleskin trousers, green wellies, a weathered face that has stood in the rain for years", "a broken-open shotgun over his arm", "a shotgun"),
    ("the_carpet_man", "a heavy man in his fifties who ran a carpet warehouse: a fleece with the shop's name half unpicked, a flat cap, grey stubble, a roll of carpet tape on a lanyard, work trousers", "a carpet knife held low", "a nail gun held like a pistol"),
    ("the_manager", "a bank branch manager in his forties still in the suit, which fits: a clean collar, a tie done properly, a name badge with the name scratched off, hair combed with water, polished shoes", "his hands clasped in front of him, a pistol in one", "a pistol, one-handed, arm straight"),
    ("the_quartermaster", "an army quartermaster in his sixties, out of the army and still in it: an issue jumper with the rank unpicked, combat trousers, polished boots, reading glasses pushed up", "a clipboard held like a weapon under one arm, a rifle slung", "a scoped rifle"),
]

HANDS = [  # type, the item art, what's held and how
    ("pistol", "old_revolver", "an old revolver, held out forward and slightly up in both hands"),
    ("shotgun", "farmer_s_shotgun", "a farmer's double-barrelled shotgun, the barrels pointing forward up the frame, one hand at the fore-end and one at the stock"),
    ("rifle", "bolt_action_garage_rifle", "a bolt-action rifle shouldered, the barrel pointing forward up the frame, one hand on the bolt-side grip and one under the fore-end"),
    ("smg", "army_smg", "a compact submachine gun held out forward in both hands"),
    ("improvised", "hand_me_down_nail_gun", "a battered nail gun held forward like a pistol in one hand, its hose trailing back past the wrist"),
    ("melee", "claw_hammer", "a claw hammer raised, ready to swing, gripped near the end of the handle, the other hand held out for balance"),
    ("blade", "machete", "a machete raised, ready to swing, the blade catching the light, the other hand held out for balance"),
]

jobs = []
seed = 95000


def job(out, w, h, desc, where, style_image, refs=None, bg=True, s=None):
    global seed
    j = {"out": out, "width": w, "height": h, "no_background": bg, "seed": s if s is not None else seed,
         "style_image": style_image, "description": desc, "_where": where,
         "endpoint": "generate-image-v2", "single": True, "style_options": STYLE}
    if refs:
        j["reference_images"] = refs
    if s is None:
        seed += 1
    jobs.append(j)


for key, art, scene, cover in SITES:
    if scene is not None:
        job("art/fight/%s_plate.png" % key, 688, 296, POV + "looking " + scene + ". " + EMPTY + " " + LAYOUT + " " + TAIL,
            "the plate: %s" % key, "res://art/places/%s.png" % art, bg=False)
    job("art/fight/%s_cover.png" % key, 688, 160,
        "Seen very close from behind, running across the whole width of the frame at the bottom: " + cover +
        ", as the cover a player crouches behind in a light-gun arcade game. Only the cover, nothing above or behind it; "
        "its top edge uneven, filling the lower two thirds of the image. " + TAIL,
        "the cover across the frame's foot: %s (taller than the test's, for the duck)" % key, "res://art/places/%s.png" % art)

BODY = "One person alone, full body head to feet, facing the viewer, centred, filling the frame top to bottom, plain dark neutral background. "
for zone, _, members in GANGS:
    for n, (who, hold, fire) in enumerate(members):
        base = "art/fight/gang_%s_%s" % (zone, "ab"[n])
        style = "res://art/people/gang_%s.png" % zone
        s = seed
        seed += 1
        job(base + "_stand.png", 128, 192, "%s, standing wary, %s. %s%s" % (who[0].upper() + who[1:], hold, BODY, TAIL),
            "%s gang, %s: standing" % (zone, "ab"[n]), style, s=s)
        job(base + "_fire.png", 128, 192, "The same %s, aiming %s straight at the viewer, a bright muzzle flash. %s%s" % (who, fire, BODY, TAIL),
            "%s gang, %s: firing at you" % (zone, "ab"[n]), style, refs=["res://" + base + "_stand.png"], s=s)
        job(base + "_down.png", 128, 192, "The same %s, hit and falling backwards, arms flung out, what they held dropping. %s%s" % (who, BODY, TAIL),
            "%s gang, %s: hit and going down" % (zone, "ab"[n]), style, refs=["res://" + base + "_stand.png"], s=s)

for name, who, hold, fire in HEADS:
    base = "art/fight/head_%s" % name
    style = "res://art/people/%s.png" % name
    s = seed
    seed += 1
    job(base + "_stand.png", 128, 192, "%s, standing, %s, unafraid. %s%s" % (who[0].upper() + who[1:], hold, BODY, TAIL),
        "%s: standing" % name, style, refs=["res://art/people/%s.png" % name], s=s)
    job(base + "_fire.png", 128, 192, "The same %s, aiming %s straight at the viewer, a bright muzzle flash. %s%s" % (who, fire, BODY, TAIL),
        "%s: firing at you" % name, style, refs=["res://" + base + "_stand.png", "res://art/people/%s.png" % name], s=s)
    job(base + "_down.png", 128, 192, "The same %s, hit and falling backwards, arms flung out, what he held dropping. %s%s" % (who, BODY, TAIL),
        "%s: beaten, going down" % name, style, refs=["res://" + base + "_stand.png", "res://art/people/%s.png" % name], s=s)

for ty, item, held in HANDS:
    job("art/fight/hands_%s.png" % ty, 256, 192,
        "First-person view of the player's own two hands in fingerless wool gloves holding %s, coming in from the bottom right "
        "corner of the frame, as in a light-gun arcade game; the sleeves of a worn work jacket at the wrists. Only the hands "
        "and what they hold, coming in from the bottom right edge. %s" % (held, TAIL),
        "your hands: %s" % ty, "res://art/items/%s.png" % item, refs=["res://art/fight_test/hands_revolver.png"])

out = {"_readme": [
    "FIAT FIGHT ART, the full pass (13 Oct, Matt: the slice reads; docs/design/fight_art.md): per site a plate (688x296) and a taller cover (688x160); per zone two gang members standing, firing, going down (128x192); the four heads the same three ways; your hands per weapon type (256x192). art/fight/.",
    "The Parade's plate is the test's: copy art/fight_test/parade_plate.png to art/fight/the_parade_plate.png before or after the run.",
    "Run: godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_fight_manifest.json   (++ --dry-run to list; one that came out wrong: ++ --only <name> ++ --force). Each stand is made before its poses, which use it.",
], "jobs": jobs}
json.dump(out, open("tools/pixellab_fight_manifest.json", "w"), indent=1)
print("%d jobs" % len(jobs))
