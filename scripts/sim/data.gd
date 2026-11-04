extends RefCounted
## Fiat's tables - the first slice. The body and its slots, the base items,
## the affixes, one zone in three tiers, the market. Numbers only.
##
## The gear model is Tarkov's / an ARPG's: the operator is a body with a slot
## per item, and a gun is itself a body with slots for attachments. Attachments
## are modelled (every gun carries its slot map) but none exist yet; the slice
## keeps them empty so the loot and the sim can be built on the final shape.
##
## Item data stays clean - slot, base, rarity, affixes, attachments, value - so
## icons and art can hang off it later without the sim changing.

## The body, in the order the Armoury shows it.
## Gloves (29 Oct, docs/design/itemisation.md §4): the eighth slot, pace and the like; the Kit room shows them on the right,
## level with the figure's hands.
const SLOTS := ["Primary", "Secondary", "Helmet", "Armour", "Gloves", "Rig", "Backpack", "Charm"]
const GLOVES := "Gloves"
## The charm: one cell on the body for the thing kept for luck. It carries
## magic find (rarer finds) and cash, and nothing else does much of either.
const CHARM := "Charm"
const CHARM_DROP := 0.05           # the share of a site's finds that are charms

## A gun's `type` is its build (the notables and keystones key off it); what it
## fires follows the type unless `ammo` says otherwise - a pipe shotgun is an
## improvised gun that takes shells.
## Medical items aren't fitted: they ride in the rig, which is their capacity.
## The backpack's capacity is loot.
const MEDICAL := "Medical"
const GRENADE := "Grenade"        # thrown from a pouch (32): damage to everyone on you, by type
## Medical supplies (28 Oct, docs/design/meds_ammo_clinic.md): a stack in the pack, found in medicine cabinets and on
## the sites that lean to meds (the Hospital most); handed to the medic, her shelf gets better for good.
const SUPPLIES := "Supplies"
## Scrap and the rebuild's materials in the pack (1 Nov, the designer's call: they stop being invisible run counters and
## take pack room, competing with gear): a stack each, found on the run; home, each stack counts into the Pitch's scrap
## or materials (the counters the Bench, the Workshop and the rebuild spend) and the item goes.
const MATERIAL := "Material"
const SCRAP_STACK := 50             # draft: scrap a stack, one cell
const MATERIAL_STACK := 10          # draft: a material a stack, one cell
## Ammo: boxes of rounds, in the stash and the pack (30 Oct: never the rig - the rig carries magazines, filled from
## the boxes). A gun fires its type's rounds and runs dry without them: then the secondary, then fists.
const AMMO := "Ammo"
## Papers: a line of the before, found lying about, a cell each, pennies at
## the Fence. Their words live in words.gd; the deeds are the one that matters.
const PAPER := "Paper"
## The share of a site's finds that are papers (D10: 0.06 left the Radio waiting hours between signals; D26: 0.12 to 0.18 -
## with every signal winnable after D25 they went faster than the papers came, a signal every 43-82 min on seven).
const PAPER_DROP := 0.18
const RADIO_EVERY := 3             # the radio comes on every this many runs home (12 Oct, the lore pass): the next line heard

## An item's footprint in cells, W x H - what it takes in the stash and the
## pack, and the size its picture is drawn at (64 px a cell). The slot gives
## the default; FOOTPRINTS names the bases that differ. The art is generated
## to these: change a footprint and its picture no longer fits.
const SIZE := {"Primary": [4, 1], "Secondary": [2, 1], "Helmet": [2, 2], "Armour": [3, 3], "Gloves": [2, 2], "Rig": [3, 2], "Backpack": [3, 3],
	"Medical": [1, 1], "Attachment": [1, 1], "Ammo": [1, 1], "Paper": [1, 1], "Charm": [1, 1], "Grenade": [1, 1], "Supplies": [1, 1], "Magazine": [1, 1], "Material": [1, 1]}
const FOOTPRINTS := {
	# melee
	"Spiked bat": [3, 1], "Machete": [3, 1], "Pipe wrench": [2, 1], "Fire axe": [3, 1], "Bayonet on a stick": [4, 1], "Sledgehammer": [3, 1], "Breaker bar": [3, 1],
	"Knife": [1, 1], "Knuckle duster": [1, 1], "Cosh": [1, 1], "Claw hammer": [2, 1],
	# short long guns
	"Hand-me-down nail gun": [3, 1], "Nail gun": [3, 1], "Bolt gun": [3, 1], "Pipe shotgun": [3, 1], "Sawn-off": [3, 1], "Workshop SMG": [3, 1],
	"Police carbine": [3, 1], "Army SMG": [3, 1], "Belt-fed SMG": [3, 1], "Army bullpup": [3, 1], "Workshop carbine": [3, 1],
	"Security guard's carbine": [3, 1], "Courier's SMG": [3, 1], "Armoured car gun": [3, 1],      # the SMG line (7 Oct); the riot squad's SMG is the slot's four
	# scoped long guns
	"Old .303": [5, 1], "Scoped .308": [5, 1], "Sniper rifle": [5, 1], "Marksman rifle": [5, 1], "Section gun": [5, 1], "Police marksman's rifle": [5, 1],
	"Range rifle": [5, 1], "Service rifle": [5, 1], "Anti-materiel rifle": [5, 1], "Bolt-action garage rifle": [5, 1],     # the deep bases (10 Oct)
	"Demolition bar": [3, 1], "Rescue axe": [3, 1], "Door ram": [3, 1],
	# heavy armour
	"Riot suit": [3, 4], "Full plate carrier": [3, 4], "Stab plates": [3, 4], "Bomb suit": [3, 4], "Butcher's chainmail": [3, 4],
	"Military plate carrier": [3, 4], "Special forces plates": [3, 4], "CBRN suit": [3, 4], "Heavy armour suit": [3, 4], "Full EOD suit": [3, 4],
	# bags
	"Plastic bag": [2, 2], "School bag": [2, 2], "Carrier bags": [2, 2], "Holdall": [2, 2],
	"Framed pack": [3, 4], "Expedition pack": [3, 4], "Cargo frame": [3, 4], "Patrol pack": [3, 4], "Full bergen": [3, 4],
	"Assault pack": [3, 4], "Long-range bergen": [3, 4], "Mountain-troop bergen": [3, 4], "Special forces bergen": [3, 4],
	# medical
	"First aid kit": [2, 1], "Trauma kit": [2, 1], "Surgeon's kit": [2, 2], "Hospital kit": [2, 2],
	# the deeds, and what the other heads hold (13 Oct, the gates)
	"The deeds": [2, 2], "The vet's bag": [2, 2], "The Carpet Man's ledger": [2, 2], "A military radio": [2, 2], "The fitter's kit": [2, 2],
	# the itemisation's (29 Oct)
	"Lump hammer": [2, 1], "Billhook": [2, 1], "Bike chain": [2, 1], "Meat cleaver": [2, 1], "Hot poker": [3, 1], "Platelayer's maul": [3, 1], "Cattle prod": [3, 1],
	"Cavalry sabre": [3, 1], "Collier's pick": [3, 1], "Felling axe": [3, 1], "Civic mace": [3, 1], "Court sword": [3, 1],
	"Wartime SMG": [3, 1], "Unmarked SMG": [3, 1], "Customs SMG": [3, 1], "Navy SMG": [3, 1], "Briefcase SMG": [3, 1], "Spiral-mag SMG": [3, 1], "Ministerial SMG": [3, 1],
	"Slam-fire shotgun": [3, 1], "Lathe-bored rifle": [5, 1], "Punt gun": [5, 1], "Big-game rifle": [5, 1], "Heavy-barrel rifle": [5, 1], "Prototype rifle": [5, 1],
	"Derringer": [1, 1], "Pocket pistol": [1, 1], "Catapult": [1, 1], "Screwdriver": [1, 1], "Commando dagger": [1, 1], "Pen gun": [1, 1],
	"Arctic smock": [3, 4], "Chainmail shark suit": [3, 4], "Mule pack": [3, 4], "Alpine pack": [3, 4], "Freefall pack": [3, 4],
	# magazines (30 Oct): a drum two pouches
	"Pistol drum": [2, 1], "Rifle drum": [2, 1], "Shotgun drum": [2, 1], "SMG drum": [2, 1], "Nail drum": [2, 1], "Belt box": [2, 1], "Hundred-round drum": [2, 1],
	# optics
	"Red dot": [2, 1], "Torch": [2, 1], "Holo sight": [2, 1], "Telescopic sight": [2, 1], "Thermal sight": [2, 1], "Night optic": [2, 1], "Laser module": [2, 1],
}

## The pack as a grid (27 Oct): no bag wider than the screen's thirteen columns, and its rows in pages of seven - a
## piece never lies across a page's edge, so every page is whole on screen.
const PACK_MAX_W := 13

## The stash in cells before the Yard's picks: one page, thirteen cells a row, seven rows.
const STASH_CELLS := 91
const CLASS_TAB_CELLS := 60          # a class's own stash tab (21 Oct, the crew): and a second as big with the Dry store
## The Clinic's rest and shelf, the Fence's shelf, the odds' dry runs before the Yard's picks.
const REST_BASE := 0.5
const CLINIC_STOCK := 6
const ODDS_RUNS := 24

## The Yard's buildings as lanes (9 Oct, docs/design/yard.md; Matt: the upgrades were done before the City, "I
## still need yard upgrades even when I'm 9 depths deep", "the choices need to be more memorable and scale more").
## Each building: five columns of two picks - take one, the other stays on show; refit for half - and a rank in
## the sixth, bought again and again. A column opens on the campaign and the depth (YARD_GATES), once for good;
## its price is the building's `costs` entry × inflation, the fifth column and the rank salvage too. The
## buildings move with the Yard. `short` is the tile's figure, `words` the strip's sentence.
const YARD_COLS := 6
const YARD_GATES := ["From the start", "With the Town open", "With the last area open", "With the campaign done", "With a level %d signal beaten", "With a level %d signal beaten"]
const YARD_GATE_SHORT := ["start", "the Town", "the last area", "the campaign", "level %d", "level %d"]
const YARD_GATE_DEPTHS := [0, 0, 0, 0, 6, 9]     # the depth dug (deepest_dug) that opens the last two columns; shown as the signal level it is (18 Oct)


## A column's gate as the screens say it: the last two by the signal level that opens them, never a depth.
static func yard_gate(col: int, short := false) -> String:
	var w: String = YARD_GATE_SHORT[col] if short else YARD_GATES[col]
	return w % (int(YARD_GATE_DEPTHS[col]) + TIERS.size() - 1 - OUTSKIRTS_SITES) if w.contains("%d") else w
const YARD_PICK_SALVAGE := 10            # the fifth column's salvage
const YARD_RANK_CASH := 50000            # a rank's cash, × YARD_RANK_GROWTH a rank bought, × inflation
const YARD_RANK_GROWTH := 1.5             # 1.25 to 1.5 (22 Oct, the web pass: 340 ranks on the endgame's tins; 24 Oct: salvage stops at rank YARD_RANK_SALVAGE_TO, tins alone past it)
const YARD_RANK_SALVAGE := 5             # a rank's salvage, one more a rank bought
const YARD_RANK_SALVAGE_TO := 5          # ranks past this want tins alone (24 Oct: the endgame held 100M+ tins, the ranks stopped on salvage - a rank is the tins' sink, each 1.5 times the last)
const YARD_SECOND := 2.5                # a column's other side, built after the first (24 Oct, Matt: option B - nothing locks, nothing to refit)
## Salvage (9 Oct): one kind a zone, from kills on its sites from SALVAGE_DEPTH, SALVAGE_KILL a kill a depth past.
const SALVAGE := ["copper", "steel", "army"]
const ZONE_SALVAGE := ["", "copper", "steel", "army"]     # by zone (12 Oct): the Outskirts has none
const SALVAGE_NAMES := {"copper": "Copper", "steel": "Safe steel", "army": "Army surplus"}
const SALVAGE_DEPTH := 4
const SALVAGE_KILL := 0.01
const YARD := [
	{"key": "bench", "name": "The Bench", "salvage": "steel", "costs": [2000, 7000, 16000, 40000, 80000], "lines": ["Rolls", "Parts"], "picks": [
		[{"id": "steady_hands", "name": "Steady hands", "short": "Re-roll values: tier-up ×2", "words": "Re-rolling values: twice the chance an affix goes up a tier"},
		 {"id": "cheap_parts", "name": "Cheap parts", "short": "−25% on Bench jobs", "words": "Every job at the Bench costs 25% less"}],
		[{"id": "two_locks", "name": "Two locks", "short": "A second padlock", "words": "A second padlock at the Bench: two affixes kept through a re-roll"},
		 {"id": "third_socket", "name": "Third socket", "short": "3 sockets (4 improvised)", "words": "A third socket can be cut in a gun, helmet or armour; a fourth in something improvised"}],
		[{"id": "overbump", "name": "Overbump", "short": "+6 levels a bump", "words": "A bump raises an item 6 levels, not 3"},
		 {"id": "gunsmith", "name": "Gunsmith", "short": "Built guns at your best site's level", "words": "Improvised guns you build come at the item level of your highest open site, if that is higher"}],
		[{"id": "fine_tuning", "name": "Fine tuning", "short": "Never rolls down", "words": "Re-rolling values never takes an affix down a tier"},
		 {"id": "strip_for_parts", "name": "Strip for parts", "short": "Scrap ×2", "words": "Scrapping gives twice the scrap"}],
		[{"id": "masterwork", "name": "Masterwork", "short": "Top-half rolls", "words": "An affix the Bench rolls lands in the top half of its tier"},
		 {"id": "salvage_line", "name": "Salvage line", "short": "Rares give safe steel", "words": "Scrapping a Rare or better also gives 1 safe steel"}]],
	 "rank": {"short": "Bump cap +1 item level", "words": "Bumps can reach 1 item level higher a rank"}},
	{"key": "stash", "name": "The Stash", "salvage": "copper", "costs": [1500, 6000, 15000, 35000, 80000], "lines": ["Room", "Sorting"], "picks": [
		[{"id": "shelving", "name": "Shelving", "short": "+40 cells", "words": "40 more cells in the stash"},
		 {"id": "racks", "name": "Racks", "short": "Rounds, meds, grenades: no cells", "words": "Rounds, meds and grenades in the stash take no cells"}],
		[{"id": "another_unit", "name": "Another unit", "short": "+50 cells", "words": "50 more cells in the stash"},
		 {"id": "bins", "name": "Bins", "short": "Commons to scrap", "words": "The common gear a run brings home goes straight to scrap"}],
		[{"id": "lock_up", "name": "Container", "short": "+60 cells", "words": "60 more cells in the stash"},
		 {"id": "wall_of_fame", "name": "Wall of fame", "short": "Uniques take no room", "words": "Uniques and set pieces in the stash take no cells"}],
		[{"id": "annex", "name": "Annex", "short": "+100 cells", "words": "100 more cells in the stash"},
		 {"id": "strongroom", "name": "Strongroom", "short": "Insurance half price", "words": "Insuring a run costs half"}],
		[{"id": "dry_store", "name": "Dry store", "short": "A second tab a class", "words": "Every class gets a second stash tab of its own"},     # 21 Oct: was a move's notes kept, the move gone
		 {"id": "filing_cabinet", "name": "Filing cabinet", "short": "Signals bring 3 papers", "words": "A signal you beat brings at least 3 papers home, not 2"}]],
	 "rank": {"short": "+20 cells", "words": "20 more stash cells a rank"}},
	{"key": "clinic", "name": "The Clinic", "salvage": "steel", "costs": [1200, 5000, 12000, 30000, 80000], "lines": ["Rest", "Meds"], "picks": [
		[{"id": "beds", "name": "Beds", "short": "Rest +0.5 HP/s", "words": "Resting heals 0.5 HP a second more"},
		 {"id": "shelf", "name": "Shelf", "short": "10 meds stocked", "words": "10 meds on the Clinic's shelf, not 6"}],
		[{"id": "ward", "name": "Ward", "short": "Rest +1 HP/s", "words": "Resting heals 1 HP a second more"},
		 {"id": "stockroom", "name": "Stockroom", "short": "+6 meds stocked", "words": "6 more meds on the Clinic's shelf"}],
		[{"id": "surgery", "name": "Surgery", "short": "Wounds half price", "words": "Treating a wound costs half"},
		 {"id": "field_kit", "name": "Field kit", "short": "A bandage a run", "words": "Every run sets off with a free bandage in the rig, if there's room"}],
		[{"id": "physio", "name": "Physio", "short": "−33% from wounds", "words": "A wound cuts its stat by 7%, not 10%"},
		 {"id": "drip", "name": "Drip", "short": "1% HP/s searching", "words": "Heal 1% of max HP a second while searching"}],
		[{"id": "theatre", "name": "Theatre", "short": "+10% max HP", "words": "Max HP +10%"},
		 {"id": "med_lab", "name": "Med lab", "short": "Meds +25%", "words": "Every med heals 25% more"}]],
	 "rank": {"short": "+3% max HP", "words": "Max HP +3% a rank"}},
	{"key": "fence", "name": "The Fence", "salvage": "army", "costs": [2000, 7000, 18000, 40000, 80000], "lines": ["Stock", "Prices"], "picks": [
		[{"id": "stall", "name": "Stall", "short": "+2 for sale", "words": "2 more things on the Fence's shelf"},
		 {"id": "haggling", "name": "Haggling", "short": "+10% sell prices", "words": "Everything sells for 10% more"}],
		[{"id": "shopfront", "name": "Shopfront", "short": "+3 for sale", "words": "3 more things on the Fence's shelf"},
		 {"id": "contacts", "name": "Contacts", "short": "Exchange spread 10%", "words": "The exchange keeps 10% either way, not 15%"}],     # was Orders (28 Oct: the contracts gone for the exchange)
		[{"id": "back_room", "name": "Back room", "short": "A unique in stock", "words": "A unique always on the shelf"},
		 {"id": "fixer", "name": "Fixer", "short": "+5% on trades", "words": "Every trade at the exchange gets 5% more"}],
		[{"id": "arms_dealer", "name": "Arms dealer", "short": "Stock at your best site's level", "words": "The Fence's stock rolls at the level of your highest open site"},
		 {"id": "insurance_desk", "name": "Insurance desk", "short": "Insured: pack kept", "words": "If an insured runner dies, the pack comes home too"}],
		[{"id": "gamblers_table", "name": "Gambler's table", "short": "Gambles half price", "words": "Every gamble costs half"},
		 {"id": "dealers_cut", "name": "Dealer's cut", "short": "+25% sell prices", "words": "Everything sells for 25% more"}]],
	 "rank": {"short": "+2% sell prices", "words": "Everything sells for 2% more a rank"}},
	{"key": "radio", "name": "The Radio", "salvage": "army", "costs": [1500, 6000, 15000, 40000, 80000], "lines": ["The sky", "The codes"], "picks": [
		[{"id": "weather_set", "name": "Weather set", "short": "Rain, fog halved", "words": "Rain and fog do half as much, good and bad"},
		 {"id": "scanner", "name": "Scanner", "short": "Crafts −25%", "words": "Every craft at the Radio costs 25% less"}],
		[{"id": "night_set", "name": "Night set", "short": "Night pace halved", "words": "Night's pace −20% becomes −10%"},
		 {"id": "two_channels", "name": "Two channels", "short": "Rolls twice", "words": "Tune in and Retune roll twice; you keep the better roll"}],
		[{"id": "forecast", "name": "The forecast", "short": "+20% tins in rain or fog", "words": "A run in rain or fog brings 20% more tins home"},
		 {"id": "long_range", "name": "Long range", "short": "+1 code a site", "words": "A site carries 1 more code"}],
		[{"id": "dead_air", "name": "Dead air", "short": "Night: gangs 25% later", "words": "At night, every gang takes 25% longer to arrive"},
		 {"id": "jammer", "name": "Jammer", "short": "Code bites halved", "words": "Every code's bite – their HP, their fire, more on you – is halved"}],
		[{"id": "lorry_watch", "name": "Lorry watch", "short": "Kev's papers every time", "words": "Every signal won brings Kev's next story paper home, not half the time"},     # 15 Oct, Matt: was the old convoy two shallower
		 {"id": "military_band", "name": "Military band", "short": "Code reward bonuses ×1.5", "words": "Every code's reward bonus is 50% bigger: tins, XP, drops, loot quality"}]],
	 "rank": {"short": "Code reward bonuses +5%", "words": "Every code's reward bonus 5% bigger a rank"}},
	{"key": "generator", "name": "The Generator", "salvage": "copper", "costs": [2500, 8000, 20000, 50000, 80000], "lines": ["Energy", "Power"], "picks": [
		[{"id": "jerry_can", "name": "Jerry can", "short": "+10 max energy", "words": "Max energy +10"},
		 {"id": "rig_wiring", "name": "Rig wiring", "short": "+4 pouches", "words": "The rig holds 4 more pouches"}],
		[{"id": "dynamo", "name": "Dynamo", "short": "+0.5 energy a second", "words": "Energy refills 0.5 more a second"},
		 {"id": "floodlights", "name": "Floodlights", "short": "Night, no pace cut", "words": "Night's loot quality without its pace −20%"}],
		[{"id": "kickback", "name": "Kickback", "short": "+5 energy a kill", "words": "Every kill gives 5 energy"},
		 {"id": "battery", "name": "Battery", "short": "+8 pouches", "words": "The rig holds 8 more pouches"}],
		[{"id": "flywheel", "name": "Flywheel", "short": "5% shorter cooldowns", "words": "Every skill's cooldown is 5% shorter"},
		 {"id": "arc_lamps", "name": "Arc lamps", "short": "Fire, shock +10%", "words": "Fire and shock do 10% more"}],
		[{"id": "pilot_light", "name": "Pilot light", "short": "First skill free", "words": "Each fight, your first skill costs no energy"},
		 {"id": "charger", "name": "Charger", "short": "Runs start on full HP", "words": "Every run sets off on full HP"}]],
	 "rank": {"short": "+2 max energy", "words": "Max energy +2 a rank"}},
	{"key": "lookout", "name": "The Lookout", "salvage": "steel", "costs": [2500, 8000, 20000, 45000, 80000], "lines": ["Early", "The watch"], "picks": [
		[{"id": "spotter", "name": "Spotter", "short": "First gang 50% later", "words": "The first gang takes 50% longer to arrive"},
		 {"id": "glasses", "name": "Glasses", "short": "Odds from 60 test runs", "words": "The odds are worked out from 60 test runs, not 24"}],
		[{"id": "lookout_post", "name": "Lookout post", "short": "First gang 50% later", "words": "The first gang takes a further 50% longer to arrive"},
		 {"id": "range_cards", "name": "Range cards", "short": "+50% damage to the first of each gang", "words": "Do 50% more damage to the first of each gang"}],
		[{"id": "hold_fire", "name": "Hold fire", "short": "First gang waits for a full pack", "words": "After the clear, the first gang waits until the pack is full"},
		 {"id": "tripwires", "name": "Tripwires", "short": "Gangs 10% later", "words": "Every gang takes 10% longer to arrive"}],
		[{"id": "early_warning", "name": "Early warning", "short": "No gang before the first crate", "words": "After the clear, no gang comes until the first crate is searched"},     # 21 Oct, Matt: the whistle went with auto-run
		 {"id": "watch_rota", "name": "Watch rota", "short": "Night: gangs 20% later", "words": "On night runs, every gang takes 20% longer to arrive"}],
		[{"id": "crows_nest", "name": "Crow's nest", "short": "Gangs 20% later", "words": "Every gang takes 20% longer to arrive"},
		 {"id": "flares", "name": "Flares", "short": "Gangs one man short", "words": "Every gang arrives one man short"}]],
	 "rank": {"short": "Gangs 2% later", "words": "Every gang takes 2% longer to arrive a rank"}},
	{"key": "kennel", "name": "The Kennel", "salvage": "copper", "costs": [2500, 7000, 18000, 40000, 80000], "lines": ["Finds", "Nose"], "picks": [
		[{"id": "a_dog", "name": "A dog", "short": "+1 find a search", "words": "Every search finds 1 more"},
		 {"id": "good_nose", "name": "A good nose", "short": "+5% quality", "words": "Loot quality +5%"}],
		[{"id": "guard_dog", "name": "Guard dog", "short": "Gangs 20% later", "words": "Every gang takes 20% longer to arrive"},
		 {"id": "pedigree", "name": "Pedigree", "short": "+10% quality", "words": "Loot quality +10%"}],
		[{"id": "second_dog", "name": "Second dog", "short": "Searches 15% quicker", "words": "Searches are 15% quicker"},
		 {"id": "fetch", "name": "Fetch", "short": "Death: best find home", "words": "When the runner dies, the dog brings the most valuable thing in the pack home"}],
		[{"id": "tracker", "name": "Tracker", "short": "Papers ×2", "words": "Papers and charms turn up twice as often"},
		 {"id": "ratter", "name": "Ratter", "short": "Poison, bleed +10%", "words": "Poison and bleed do 10% more damage"}],
		[{"id": "pack", "name": "The litter", "short": "+2 finds a search", "words": "Every search finds 2 more"},
		 {"id": "champion", "name": "Champion", "short": "+20% quality", "words": "Loot quality +20%"}]],
	 "rank": {"short": "+2% loot quality", "words": "Loot quality +2% a rank"}},
	# the Bunkhouse (29 Oct, docs/design/trips.md 4): line A the repeat runs', line B the expeditions' (shut till the
	# Quartermaster falls: Sim.yard_stub)
	{"key": "bunkhouse", "name": "The Bunkhouse", "salvage": "army", "costs": [2000, 7000, 18000, 40000, 80000], "lines": ["Repeat", "Expeditions"], "picks": [
		[{"id": "rr_ten", "name": "Ten in a row", "short": "×10 runs · 17% XP", "words": "Run it ×10 on a cleared site. Repeat runs earn 17% of a watched run's XP"},
		 {"id": "trip_hand", "name": "A hand along", "short": "1 hand · a pool of 6", "words": "1 hired hand on each expedition; a pool of 6 to hire from"}],
		[{"id": "rr_list", "name": "Your own list", "short": "Loot rules decide · 22% XP", "words": "Your loot rules decide what a repeat keeps. Repeat runs earn 22% of a watched run's XP"},
		 {"id": "trip_two_hands", "name": "Two along", "short": "2 hands · Better faces", "words": "Two hired hands on an expedition; Better faces, the dearer reroll"}],
		[{"id": "rr_twenty", "name": "Twenty in a row", "short": "×20 runs", "words": "Run it ×20 on a cleared site"},
		 {"id": "trip_two", "name": "Two at once", "short": "2 expeditions at once", "words": "2 expeditions out at once"}],
		[{"id": "rr_rest", "name": "Bunk beds", "short": "Rest twice as fast · 30% XP", "words": "Rest between repeat runs twice as fast. Repeat runs earn 30% of a watched run's XP"},
		 {"id": "trip_roster", "name": "More bunks", "short": "+4 on the roster · weekly quotas", "words": "4 more hands on the roster; the far places' weekly quotas"}],
		[{"id": "rr_full", "name": "Till it's full", "short": "Till the stash is full", "words": "Repeat runs go on till the stash is full"},
		 {"id": "trip_three", "name": "Three at once", "short": "3 expeditions at once", "words": "3 expeditions out at once"}]],
	 "rank": {"short": "5% quicker rest · −2% risk", "words": "Rest between repeat runs 5% quicker and expeditions' risk 2% lower a rank"}},
]
## The repeat runs (29 Oct, docs/design/trips.md 1-2): "Run it ×5" on a cleared site at REPEAT_ODDS or better; the runs
## unwatched, a bail at Sim.BAIL never a death; XP a share of a watched run's (the Bunkhouse raises it).
const REPEAT_RUNS := 5
const REPEAT_ODDS := 0.9
const REPEAT_XP := [0.12, 0.17, 0.22, 0.30]        # from the start; Ten in a row; Your own list; Bunk beds. x0.5 on every step (the designer's call, 1 Nov, PROBE40: the long pass had level 50 at 7-9 h on four of six, repeats 59-86% of the XP; was 0.25, 0.35, 0.45, 0.60)
const REPEAT_RANK_REST := 0.05                     # the Bunkhouse's rank: rest between repeat runs 5% quicker a rank
const REPEAT_MAX := 200                            # Till it's full: runs at most, a guard
const REPEAT_MED_UNDER := 0.4                      # an unwatched run's med, under 40% HP, as the bot's
## Kev's wagers (29 Oct, docs/design/endgame_activities.md row 1): the harder words and what they pay, a watched run's.
const WAGER_CONDS := [
	{"id": "gang", "chip": "+50% men", "words": "50% more men in every gang"},
	{"id": "no_meds", "chip": "No meds", "words": "No meds: the rig's heals and cures stay shut"},
	{"id": "clock", "chip": "−50% clock", "words": "Half the clock"},
	{"id": "hard", "chip": "+25% gang damage", "words": "The gang hits 25% harder"},
]
const WAGER_PAYS := [
	{"id": "notes", "chip": "×1.5 notes", "x": 1.5},
	{"id": "slot", "chip": "×3 %s finds", "x": 3},
	{"id": "quality", "chip": "+50% loot quality", "x": 0.5},
]
const WAGER_SLOTS := ["Primary", "Armour", "Helmet", "Gloves", "Backpack", "Rig", "Charm"]
const WAGER_SLOT_WORDS := {"Primary": "gun", "Armour": "armour", "Helmet": "helmet", "Gloves": "gloves", "Backpack": "pack", "Rig": "rig", "Charm": "charm"}     # the slots as the chips say them (the language pass)
const WAGER_GANG := 1.5
const WAGER_HARD := 1.25
const WAGER_CLOCK := 0.5



static func yard_building(key: String) -> Dictionary:
	for b in YARD:
		if b["key"] == key:
			return b
	return {}


## Where a pick is: [building key, column, side 0 or 1], or [] for no such pick.
static func yard_where(id: String) -> Array:
	for b in YARD:
		for c in range(b["picks"].size()):
			for side in range(2):
				if b["picks"][c][side]["id"] == id:
					return [b["key"], c, side]
	return []


## The works' top levels (31): the generator's second rig row is RIG_ROW pouches; the rig never shows past RIG_CAP.
const RIG_ROW := 8
const RIG_CAP := 24

## What a slot's item is scored by, when the Armoury picks the best in the stash.
const SLOT_SCORE := {
	"Primary": "dps", "Secondary": "dps", "Helmet": "armour", "Armour": "armour", "Gloves": "grip",     # gloves: the fight's damage a second, pace in (29 Oct)
	"Rig": "capacity", "Backpack": "capacity", "Medical": "heal", "Attachment": "attach", "Ammo": "rounds", "Paper": "value", "Grenade": "throw", "Supplies": "value", "Magazine": "mag", "Material": "value",
	"Charm": "find",
}

## Base items. A gun: its type (improvised, shotgun, rifle, smg, pistol - the
## class trees key off the primary's), damage a shot, shots a second, its attachment slots.
## Armour: armour (mitigation: armour / (armour + 100)). Rig and pack: capacity,
## the loot a mission can bring back. `tier` is the lowest zone tier that drops
## it; `value` is its cash at the Black Market, before rarity.
const BASES := {
	## Guns: type, damage a shot, shots a second, mounts. Several a type a tier,
	## each with a reason - rate, first-shot weight, mounts, value - so a type is
	## a build you can stay in, not a ladder you climb off.
	"Primary": [
		# the start: the worst gun in the game, never found, so every base in the pool is someone's first upgrade
		{"name": "Hand-me-down nail gun", "type": "improvised", "tier": 1, "damage": 24.0, "rof": 0.5, "value": 20, "start": true,
			"attachments": []},
		# improvised - the Bodger's
		{"name": "Nail gun", "type": "improvised", "tier": 1, "damage": 28.0, "rof": 0.6, "value": 90,
			"attachments": ["optic", "muzzle"]},
		{"name": "Bolt gun", "type": "improvised", "tier": 1, "damage": 38.0, "rof": 0.4, "value": 70,
			"attachments": ["muzzle"]},
		{"name": "Pipe shotgun", "type": "improvised", "ammo": "shotgun", "tier": 1, "damage": 50.0, "rof": 0.3, "value": 60, "mag": 11,
			"attachments": ["stock"]},
		{"name": "Crossbow", "type": "improvised", "tier": 2, "damage": 60.0, "rof": 0.45, "value": 75,
			"attachments": ["optic", "stock"]},
		{"name": "Garage-built rifle", "type": "improvised", "ammo": "rifle", "tier": 2, "damage": 19.0, "rof": 1.5, "value": 85, "mag": 18,     # the Retail Park's own: T3 to its site's T2 (29 Oct)
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		# shotguns - the Doorman's
		{"name": "Farmer's shotgun", "type": "shotgun", "tier": 1, "damage": 45.0, "rof": 0.5, "value": 120,
			"attachments": ["muzzle", "stock"]},
		{"name": "Sawn-off", "type": "shotgun", "tier": 1, "damage": 55.0, "rof": 0.35, "value": 100,
			"attachments": ["stock"]},
		{"name": "Pump shotgun", "type": "shotgun", "tier": 2, "damage": 42.0, "rof": 0.8, "value": 90,
			"attachments": ["muzzle", "sling", "stock"]},
		{"name": "Riot shotgun", "type": "shotgun", "tier": 3, "damage": 50.0, "rof": 1.0, "value": 170, "mag": 11,
			"attachments": ["optic", "muzzle", "sling", "stock"]},
		{"name": "Semi-auto shotgun", "type": "shotgun", "tier": 3, "damage": 38.0, "rof": 1.4, "value": 180, "mag": 11,
			"attachments": ["optic", "muzzle", "sling", "handguard"]},
		# rifles - the Poacher's
		{"name": "Semi-auto .22", "type": "rifle", "tier": 2, "damage": 18.0, "rof": 1.7, "value": 90, "mag": 19,
			"attachments": ["optic", "muzzle", "sling", "handguard"]},
		{"name": "Old .303", "type": "rifle", "tier": 2, "damage": 65.0, "rof": 0.5, "value": 85,
			"attachments": ["optic", "stock"]},
		{"name": "Stalking rifle", "type": "rifle", "tier": 3, "damage": 58.0, "rof": 0.8, "value": 160,
			"attachments": ["optic", "muzzle", "sling", "stock"]},
		{"name": "Army bullpup", "type": "rifle", "tier": 3, "damage": 20.0, "rof": 2.6, "value": 180, "mag": 11,
			"attachments": ["optic", "muzzle", "sling", "handguard"]},
		{"name": "AR-pattern rifle", "type": "rifle", "tier": 3, "damage": 16.0, "rof": 3.0, "value": 170, "mag": 17,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Battle rifle", "type": "rifle", "tier": 3, "damage": 36.0, "rof": 1.4, "value": 190,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		# SMGs - the Drifter's. The line (7 Oct): a gun a tier from T2 to T6, two at T6 like the shotguns, the top a shade
		# over theirs and paid for in rounds; every SMG primary carries walking fire (`sustain`: the stream grows so much a
		# second on one gang, to the cap), the long fight's gun
		{"name": "Workshop SMG", "type": "smg", "tier": 2, "damage": 15.0, "rof": 2.3, "value": 100, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Police carbine", "type": "smg", "tier": 3, "damage": 17.0, "rof": 2.8, "value": 175, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Security guard's carbine", "type": "smg", "tier": 3, "damage": 18.0, "rof": 3.0, "value": 190, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Courier's SMG", "type": "smg", "tier": 4, "damage": 21.0, "rof": 3.6, "value": 310, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Armoured car gun", "type": "smg", "tier": 5, "damage": 25.0, "rof": 4.0, "value": 520, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Riot squad's SMG", "type": "smg", "tier": 6, "damage": 28.0, "rof": 4.4, "value": 760, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		# tiers 4 and 5: the town's, and past it
		{"name": "Workshop carbine", "type": "improvised", "ammo": "smg", "tier": 4, "damage": 34.0, "rof": 1.9, "value": 260,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Drum shotgun", "type": "shotgun", "tier": 4, "damage": 44.0, "rof": 1.5, "value": 280, "mag": 12,
			"attachments": ["optic", "muzzle", "sling", "stock"]},
		{"name": "Scoped .308", "type": "rifle", "tier": 4, "damage": 80.0, "rof": 0.85, "value": 300,
			"attachments": ["optic", "muzzle", "sling", "stock"]},
		{"name": "Army SMG", "type": "smg", "tier": 4, "damage": 20.0, "rof": 3.4, "value": 290, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Tooled-up garage rifle", "type": "improvised", "ammo": "rifle", "tier": 5, "damage": 40.0, "rof": 2.3, "value": 420, "mag": 20,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Automatic shotgun", "type": "shotgun", "tier": 5, "damage": 46.0, "rof": 2.0, "value": 460, "mag": 15,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Sniper rifle", "type": "rifle", "tier": 5, "damage": 110.0, "rof": 0.85, "value": 480,
			"attachments": ["optic", "muzzle", "sling", "stock"]},
		# tier 6: the city's - the Services, the Hospital, the Barracks
		{"name": "Armourer's carbine", "type": "improvised", "ammo": "smg", "tier": 6, "damage": 44.0, "rof": 2.6, "value": 650,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		## the top of the pool (6 Oct): the firearms squad's and the Barracks' own
		{"name": "Police marksman's rifle", "type": "rifle", "tier": 6, "damage": 125.0, "rof": 0.9, "value": 820,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Riot squad's shotgun", "type": "shotgun", "tier": 6, "damage": 52.0, "rof": 2.2, "value": 760,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		# melee: no rounds ever, slow, hard, a fifth of it bleed; in among them, so they hit you harder
		# and their first shot lands before your first swing. Grip and head mounts of their own.
		# the start since 13 Oct (Matt: a bat found "trivialised ammo concerns"): a hand-me-down hammer, the nail gun's
		# 12 a second and no rounds; never found. Melee sits behind the tier's best gun from here (the Spiked bat 20 to 17,
		# the top four a tenth or so down): rounds a trade you choose, not a trap
		{"name": "Claw hammer", "type": "melee", "ammo": "none", "tier": 1, "damage": 24.0, "rof": 0.5, "value": 10, "conv_bleed_pct": 10, "start": true,
			"attachments": ["grip"]},
		{"name": "Spiked bat", "type": "melee", "ammo": "none", "tier": 1, "damage": 34.0, "rof": 0.5, "value": 30, "conv_bleed_pct": 20,
			"attachments": ["grip", "business end"]},
		{"name": "Machete", "type": "melee", "ammo": "none", "tier": 2, "damage": 30.0, "rof": 0.9, "value": 70, "conv_bleed_pct": 20,
			"attachments": ["grip"]},
		{"name": "Pipe wrench", "type": "melee", "ammo": "none", "tier": 2, "damage": 55.0, "rof": 0.5, "value": 60, "conv_bleed_pct": 10,
			"attachments": ["grip", "business end"]},
		{"name": "Fire axe", "type": "melee", "ammo": "none", "tier": 3, "damage": 70.0, "rof": 0.6, "value": 150, "conv_bleed_pct": 15,
			"attachments": ["grip", "business end"]},
		{"name": "Bayonet on a stick", "type": "melee", "ammo": "none", "tier": 4, "damage": 60.0, "rof": 0.9, "value": 260, "conv_bleed_pct": 15,
			"attachments": ["grip", "business end"]},
		{"name": "Sledgehammer", "type": "melee", "ammo": "none", "tier": 5, "damage": 160.0, "rof": 0.45, "value": 420, "conv_bleed_pct": 5,
			"attachments": ["grip", "business end"]},
		{"name": "Breaker bar", "type": "melee", "ammo": "none", "tier": 6, "damage": 82.0, "rof": 1.2, "value": 640, "conv_bleed_pct": 15,
			"attachments": ["grip", "business end"]},
		{"name": "Assault shotgun", "type": "shotgun", "tier": 6, "damage": 48.0, "rof": 2.4, "value": 680,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Marksman rifle", "type": "rifle", "tier": 6, "damage": 90.0, "rof": 1.1, "value": 720,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Section gun", "type": "smg", "tier": 4, "damage": 16.5, "rof": 4.4, "value": 290, "sustain": [4, 40],     # the Barracks' own: T6 to T4 (29 Oct)     # lifted (7 Oct): 26 × 4.2 read 109 against the shotguns' 115
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Belt-fed SMG", "type": "smg", "tier": 5, "damage": 24.0, "rof": 3.8, "value": 470, "sustain": [4, 40], "mag": 100, "reload": 3.0,     # its belt (28 Oct, magazines): draft
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		## the deep bases (10 Oct, docs/design/deep_guns.md): tiers 7-9, found from level 12, 16 and 20 (the Barracks at depth
		## 4, 8, 12); about +18% damage a second a tier on each type's own line, so the climb has a base to chase all the way down
		{"name": "Security service SMG", "type": "smg", "tier": 7, "damage": 31.0, "rof": 4.6, "value": 1050, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Close protection SMG", "type": "smg", "tier": 8, "damage": 34.0, "rof": 4.9, "value": 1450, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Special forces SMG", "type": "smg", "tier": 9, "damage": 37.0, "rof": 5.2, "value": 2000, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Range rifle", "type": "rifle", "tier": 7, "damage": 96.0, "rof": 1.4, "value": 1100,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Service rifle", "type": "rifle", "tier": 8, "damage": 104.0, "rof": 1.5, "value": 1500, "mag": 11,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Anti-materiel rifle", "type": "rifle", "tier": 9, "damage": 150.0, "rof": 1.2, "value": 2100,
			"attachments": ["optic", "muzzle", "sling", "stock"]},
		{"name": "Breaching shotgun", "type": "shotgun", "tier": 7, "damage": 60.0, "rof": 2.25, "value": 1050, "mag": 16,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Entry shotgun", "type": "shotgun", "tier": 8, "damage": 66.0, "rof": 2.4, "value": 1450,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Combat shotgun", "type": "shotgun", "tier": 9, "damage": 74.0, "rof": 2.55, "value": 2000, "mag": 18,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Bolt-action garage rifle", "type": "improvised", "ammo": "rifle", "tier": 7, "damage": 112.0, "rof": 1.2, "value": 900,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Workshop gauss", "type": "improvised", "tier": 8, "damage": 52.0, "rof": 3.0, "value": 1250,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "The engineer's piece", "type": "improvised", "ammo": "smg", "tier": 9, "damage": 50.0, "rof": 3.6, "value": 1700,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Demolition bar", "type": "melee", "ammo": "none", "tier": 7, "damage": 90.0, "rof": 1.3, "value": 900, "conv_bleed_pct": 15,
			"attachments": ["grip", "business end"]},
		{"name": "Rescue axe", "type": "melee", "ammo": "none", "tier": 8, "damage": 108.0, "rof": 1.3, "value": 1250, "conv_bleed_pct": 15,
			"attachments": ["grip", "business end"]},
		{"name": "Door ram", "type": "melee", "ammo": "none", "tier": 9, "damage": 195.0, "rof": 0.82, "value": 1700, "conv_bleed_pct": 5,
			"attachments": ["grip", "business end"]},
		## the itemisation's (29 Oct, docs/design/itemisation.md §2): three a tier in T1-4, two in T5-9 (worn: a heavy, a light and a specialist every tier)
		{"name": "Lump hammer", "type": "melee", "ammo": "none", "tier": 1, "damage": 40.0, "rof": 0.42, "value": 25, "conv_bleed_pct": 5,
			"attachments": ["grip", "business end"]},
		{"name": "Billhook", "type": "melee", "ammo": "none", "tier": 1, "damage": 24.0, "rof": 0.72, "value": 30, "conv_bleed_pct": 20,
			"attachments": ["grip"]},
		{"name": "Bike chain", "type": "melee", "ammo": "none", "tier": 2, "damage": 26.0, "rof": 1.05, "value": 65, "conv_bleed_pct": 20,
			"attachments": ["grip"]},
		{"name": "Meat cleaver", "type": "melee", "ammo": "none", "tier": 3, "damage": 46.0, "rof": 0.9, "value": 140, "conv_bleed_pct": 20,
			"attachments": ["grip"]},
		{"name": "Hot poker", "type": "melee", "ammo": "none", "tier": 3, "damage": 55.0, "rof": 0.78, "value": 150, "conv_fire_pct": 25,
			"attachments": ["grip", "business end"]},
		{"name": "Platelayer's maul", "type": "melee", "ammo": "none", "tier": 4, "damage": 100.0, "rof": 0.55, "value": 250, "conv_bleed_pct": 5,
			"attachments": ["grip", "business end"]},
		{"name": "Cattle prod", "type": "melee", "ammo": "none", "tier": 4, "damage": 45.0, "rof": 1.2, "value": 270, "conv_shock_pct": 30,
			"attachments": ["grip"]},
		{"name": "Cavalry sabre", "type": "melee", "ammo": "none", "tier": 5, "damage": 60.0, "rof": 1.2, "value": 430, "conv_bleed_pct": 20,
			"attachments": ["grip"]},
		{"name": "Collier's pick", "type": "melee", "ammo": "none", "tier": 6, "damage": 180.0, "rof": 0.55, "value": 650, "conv_bleed_pct": 10,
			"attachments": ["grip", "business end"]},
		{"name": "Felling axe", "type": "melee", "ammo": "none", "tier": 7, "damage": 210.0, "rof": 0.55, "value": 920, "conv_bleed_pct": 15,
			"attachments": ["grip", "business end"]},
		{"name": "Civic mace", "type": "melee", "ammo": "none", "tier": 8, "damage": 255.0, "rof": 0.55, "value": 1280, "conv_bleed_pct": 5,
			"attachments": ["grip", "business end"]},
		{"name": "Court sword", "type": "melee", "ammo": "none", "tier": 9, "damage": 120.0, "rof": 1.35, "value": 1720, "conv_bleed_pct": 20,
			"attachments": ["grip"]},
		{"name": "Speargun", "type": "improvised", "tier": 2, "damage": 70.0, "rof": 0.4, "value": 80,
			"attachments": ["optic", "stock"]},
		{"name": "Compound bow", "type": "improvised", "tier": 3, "damage": 90.0, "rof": 0.5, "value": 160,
			"attachments": ["optic", "stock"]},
		{"name": "Converted air rifle", "type": "improvised", "ammo": "rifle", "tier": 3, "damage": 20.0, "rof": 2.25, "value": 170, "mag": 36,
			"attachments": ["optic", "muzzle", "sling", "stock"]},
		{"name": "Slam-fire shotgun", "type": "improvised", "ammo": "shotgun", "tier": 3, "damage": 60.0, "rof": 0.75, "value": 150, "mag": 14,
			"attachments": ["muzzle", "stock"]},
		{"name": "Punt gun", "type": "improvised", "ammo": "shotgun", "tier": 4, "damage": 200.0, "rof": 0.33, "value": 270,
			"attachments": ["stock"]},
		{"name": "Paintball gun", "type": "improvised", "tier": 4, "damage": 26.0, "rof": 2.5, "value": 280, "mag": 120,
			"attachments": ["optic", "muzzle", "sling"]},
		{"name": "Arc-welder gun", "type": "improvised", "tier": 5, "damage": 46.0, "rof": 2.0, "value": 450, "conv_shock_pct": 35,
			"attachments": ["optic", "muzzle", "sling", "stock"]},
		{"name": "Lathe-bored rifle", "type": "improvised", "ammo": "rifle", "tier": 6, "damage": 228.0, "rof": 0.5, "value": 660,
			"attachments": ["optic", "muzzle", "stock"]},
		{"name": "Chain-driven repeater", "type": "improvised", "ammo": "smg", "tier": 7, "damage": 34.0, "rof": 3.95, "value": 960, "mag": 60,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Bench-made autocannon", "type": "improvised", "ammo": "rifle", "tier": 8, "damage": 260.0, "rof": 0.6, "value": 1300,
			"attachments": ["optic", "muzzle", "sling", "stock"]},
		{"name": "Prototype rifle", "type": "improvised", "ammo": "rifle", "tier": 9, "damage": 300.0, "rof": 0.6, "value": 1750,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Four-ten", "type": "shotgun", "tier": 1, "damage": 26.0, "rof": 0.8, "value": 90, "mag": 9,
			"attachments": ["muzzle", "stock"]},
		{"name": "Goose gun", "type": "shotgun", "tier": 2, "damage": 70.0, "rof": 0.48, "value": 90,
			"attachments": ["muzzle", "stock"]},
		{"name": "Over-and-under", "type": "shotgun", "tier": 2, "damage": 40.0, "rof": 0.85, "value": 110,
			"attachments": ["optic", "muzzle", "handguard", "stock"]},
		{"name": "Ten-bore", "type": "shotgun", "tier": 3, "damage": 105.0, "rof": 0.5, "value": 170,
			"attachments": ["muzzle", "stock"]},
		{"name": "Magnum pump", "type": "shotgun", "tier": 4, "damage": 120.0, "rof": 0.55, "value": 270,
			"attachments": ["muzzle", "sling", "stock"]},
		{"name": "Pigeon gun", "type": "shotgun", "tier": 4, "damage": 30.0, "rof": 2.2, "value": 290, "mag": 18,
			"attachments": ["optic", "muzzle", "sling", "handguard"]},
		{"name": "Rifled slug gun", "type": "shotgun", "tier": 5, "damage": 185.0, "rof": 0.5, "value": 470,
			"attachments": ["optic", "muzzle", "sling", "stock"]},
		{"name": "Marine shotgun", "type": "shotgun", "tier": 7, "damage": 245.0, "rof": 0.55, "value": 1060,
			"attachments": ["optic", "muzzle", "sling", "stock"]},
		{"name": "Dragon's-breath gun", "type": "shotgun", "tier": 8, "damage": 66.0, "rof": 2.4, "value": 1480, "conv_fire_pct": 30,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Siege shotgun", "type": "shotgun", "tier": 9, "damage": 345.0, "rof": 0.55, "value": 2050,
			"attachments": ["optic", "muzzle", "sling", "stock"]},
		{"name": "Lever-action rifle", "type": "rifle", "tier": 2, "damage": 40.0, "rof": 0.8, "value": 90, "mag": 14,
			"attachments": ["optic", "sling", "stock"]},
		{"name": "Self-loading rifle", "type": "rifle", "tier": 4, "damage": 30.0, "rof": 2.25, "value": 290, "mag": 14,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Vermin rifle", "type": "rifle", "tier": 4, "damage": 34.0, "rof": 2.0, "value": 300, "mag": 20,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Regimental rifle", "type": "rifle", "tier": 5, "damage": 38.0, "rof": 2.45, "value": 470, "mag": 14,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Big-game rifle", "type": "rifle", "tier": 7, "damage": 268.0, "rof": 0.5, "value": 1080,
			"attachments": ["optic", "muzzle", "stock"]},
		{"name": "Heavy-barrel rifle", "type": "rifle", "tier": 8, "damage": 285.0, "rof": 0.55, "value": 1480,
			"attachments": ["optic", "muzzle", "sling", "stock"]},
		{"name": "Castle guard rifle", "type": "rifle", "tier": 9, "damage": 66.0, "rof": 2.75, "value": 2080, "mag": 13,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Wartime SMG", "type": "smg", "tier": 2, "damage": 22.0, "rof": 1.55, "value": 95, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Unmarked SMG", "type": "smg", "tier": 2, "damage": 11.0, "rof": 3.1, "value": 100, "sustain": [4, 40], "mag": 40,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Customs SMG", "type": "smg", "tier": 3, "damage": 24.0, "rof": 2.1, "value": 175, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Navy SMG", "type": "smg", "tier": 6, "damage": 35.0, "rof": 3.5, "value": 740, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Briefcase SMG", "type": "smg", "tier": 7, "damage": 41.0, "rof": 3.5, "value": 1040, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Spiral-mag SMG", "type": "smg", "tier": 8, "damage": 34.0, "rof": 4.9, "value": 1460, "sustain": [4, 40], "mag": 50,
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
		{"name": "Ministerial SMG", "type": "smg", "tier": 9, "damage": 52.0, "rof": 3.7, "value": 2010, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "sling", "handguard", "stock"]},
	],
	# no sling mount on a secondary (the three-stage review, UI 6, the project manager's call): the sling only lifts the secondary from the primary
	"Secondary": [
		{"name": "Converted blank-firer", "type": "improvised", "ammo": "pistol", "tier": 1, "damage": 12.0, "rof": 1.5, "value": 40,
			"attachments": ["muzzle"]},
		{"name": "Flare pistol", "type": "improvised", "tier": 1, "damage": 30.0, "rof": 0.5, "value": 30,
			"attachments": []},
		{"name": "Knife", "type": "melee", "ammo": "none", "tier": 1, "damage": 9.0, "rof": 1.8, "value": 15, "conv_bleed_pct": 20,
			"attachments": ["grip"]},
		{"name": "Knuckle duster", "type": "melee", "ammo": "none", "tier": 2, "damage": 14.0, "rof": 1.5, "value": 40, "conv_bleed_pct": 10,
			"attachments": []},
		{"name": "Cosh", "type": "melee", "ammo": "none", "tier": 3, "damage": 24.0, "rof": 1.0, "value": 90, "conv_bleed_pct": 5,
			"attachments": ["grip"]},
		{"name": "Air pistol", "type": "improvised", "tier": 1, "damage": 8.0, "rof": 2.0, "value": 25,
			"attachments": ["optic"]},
		{"name": "Service pistol", "type": "pistol", "tier": 2, "damage": 15.0, "rof": 1.6, "value": 40,
			"attachments": ["optic", "muzzle"]},
		{"name": "Old revolver", "type": "pistol", "tier": 2, "damage": 28.0, "rof": 0.8, "value": 40,
			"attachments": ["optic"]},
		{"name": "Compact pistol", "type": "pistol", "tier": 2, "damage": 13.0, "rof": 2.0, "value": 45,
			"attachments": ["muzzle"]},
		{"name": "Machine pistol", "type": "smg", "tier": 3, "damage": 9.0, "rof": 3.2, "value": 100,
			"attachments": ["muzzle", "stock"]},
		{"name": "Big revolver", "type": "pistol", "tier": 3, "damage": 40.0, "rof": 0.8, "value": 90,
			"attachments": ["optic", "muzzle"]},
		{"name": "Tactical pistol", "type": "pistol", "tier": 3, "damage": 15.0, "rof": 2.2, "value": 95,     # the Shopping Centre's own: T4 to T3 (29 Oct)
			"attachments": ["optic", "muzzle"]},
		{"name": "Officer's revolver", "type": "pistol", "tier": 6, "damage": 48.0, "rof": 1.2, "value": 360,
			"attachments": ["optic", "muzzle"]},
		{"name": "Army machine pistol", "type": "smg", "tier": 6, "damage": 16.0, "rof": 4.6, "value": 380,
			"attachments": ["muzzle", "stock"]},
		{"name": "Duty pistol", "type": "pistol", "tier": 6, "damage": 22.0, "rof": 2.4, "value": 300, "mag": 16,
			"attachments": ["optic", "muzzle"]},
		{"name": "Automatic pistol", "type": "smg", "tier": 5, "damage": 14.0, "rof": 4.2, "value": 240,
			"attachments": ["optic", "muzzle", "stock"]},
		## the deep bases (10 Oct): tiers 7-9 on the pistol and the machine pistol lines
		{"name": "Close quarters pistol", "type": "pistol", "tier": 7, "damage": 24.0, "rof": 2.8, "value": 500,
			"attachments": ["optic", "muzzle"]},
		{"name": "Bodyguard's pistol", "type": "pistol", "tier": 8, "damage": 27.0, "rof": 2.9, "value": 700,
			"attachments": ["optic", "muzzle"]},
		{"name": "Special issue pistol", "type": "pistol", "tier": 9, "damage": 30.0, "rof": 3.1, "value": 950, "mag": 16,
			"attachments": ["optic", "muzzle"]},
		{"name": "Legation machine pistol", "type": "smg", "tier": 7, "damage": 19.0, "rof": 4.6, "value": 530,
			"attachments": ["muzzle", "stock"]},
		{"name": "Embassy PDW", "type": "smg", "tier": 8, "damage": 21.0, "rof": 4.9, "value": 740,
			"attachments": ["muzzle", "stock"]},
		{"name": "Protection squad PDW", "type": "smg", "tier": 9, "damage": 24.0, "rof": 5.0, "value": 1000,
			"attachments": ["muzzle", "stock"]},
		## the itemisation's (29 Oct, docs/design/itemisation.md §2): three a tier in T1-4, two in T5-9 (worn: a heavy, a light and a specialist every tier)
		{"name": "Derringer", "type": "pistol", "tier": 1, "damage": 22.0, "rof": 0.7, "value": 30,
			"attachments": []},
		{"name": "Pocket pistol", "type": "pistol", "tier": 1, "damage": 8.0, "rof": 2.0, "value": 30,
			"attachments": ["muzzle"]},
		{"name": "Target pistol", "type": "pistol", "tier": 3, "damage": 11.0, "rof": 2.9, "value": 95, "mag": 16,
			"attachments": ["optic"]},
		{"name": "Police revolver", "type": "pistol", "tier": 4, "damage": 55.0, "rof": 0.8, "value": 150,
			"attachments": ["optic"]},
		{"name": "Polymer pistol", "type": "pistol", "tier": 4, "damage": 18.0, "rof": 2.45, "value": 150,
			"attachments": ["optic", "muzzle"]},
		{"name": "Long-slide pistol", "type": "pistol", "tier": 4, "damage": 22.0, "rof": 2.0, "value": 160, "mag": 20,
			"attachments": ["optic", "muzzle"]},
		{"name": "Hunting revolver", "type": "pistol", "tier": 5, "damage": 62.0, "rof": 0.8, "value": 240,
			"attachments": ["optic", "muzzle"]},
		{"name": "Competition pistol", "type": "pistol", "tier": 5, "damage": 20.0, "rof": 2.5, "value": 250,
			"attachments": ["optic", "muzzle"]},
		{"name": "Cavalry revolver", "type": "pistol", "tier": 7, "damage": 84.0, "rof": 0.8, "value": 510,
			"attachments": ["optic", "muzzle"]},
		{"name": "Ambassador's revolver", "type": "pistol", "tier": 8, "damage": 98.0, "rof": 0.8, "value": 710,
			"attachments": ["optic", "muzzle"]},
		{"name": "Field marshal's revolver", "type": "pistol", "tier": 9, "damage": 116.0, "rof": 0.8, "value": 960,
			"attachments": ["optic", "muzzle"]},
		{"name": "Broomhandle pistol", "type": "smg", "tier": 2, "damage": 7.0, "rof": 3.1, "value": 45,
			"attachments": ["muzzle"]},
		{"name": "Stockless SMG", "type": "smg", "tier": 2, "damage": 9.0, "rof": 2.4, "value": 45,
			"attachments": ["muzzle", "stock"]},
		{"name": "Three-round pistol", "type": "smg", "tier": 3, "damage": 12.0, "rof": 2.4, "value": 95,
			"attachments": ["muzzle", "stock"]},
		{"name": "Compact PDW", "type": "smg", "tier": 4, "damage": 10.0, "rof": 4.4, "value": 150,
			"attachments": ["muzzle", "stock"]},
		{"name": "Select-fire pistol", "type": "smg", "tier": 4, "damage": 15.0, "rof": 2.95, "value": 150, "mag": 30,
			"attachments": ["muzzle", "stock"]},
		{"name": "Folding PDW", "type": "smg", "tier": 5, "damage": 18.0, "rof": 3.3, "value": 245,
			"attachments": ["muzzle", "stock"]},
		{"name": "Escort PDW", "type": "smg", "tier": 6, "damage": 22.0, "rof": 3.35, "value": 375,
			"attachments": ["muzzle", "stock"]},
		{"name": "Consular PDW", "type": "smg", "tier": 7, "damage": 26.0, "rof": 3.35, "value": 525,
			"attachments": ["muzzle", "stock"]},
		{"name": "Overcoat machine pistol", "type": "smg", "tier": 8, "damage": 30.0, "rof": 3.43, "value": 735,
			"attachments": ["muzzle", "stock"]},
		{"name": "Crown PDW", "type": "smg", "tier": 9, "damage": 35.0, "rof": 3.43, "value": 990,
			"attachments": ["muzzle", "stock"]},
		{"name": "Catapult", "type": "improvised", "tier": 2, "damage": 18.0, "rof": 1.15, "value": 40,
			"attachments": []},
		{"name": "Screwdriver", "type": "melee", "ammo": "none", "tier": 2, "damage": 11.0, "rof": 1.9, "value": 40, "conv_bleed_pct": 20,
			"attachments": ["grip"]},
		{"name": "Bike lock", "type": "melee", "ammo": "none", "tier": 2, "damage": 26.0, "rof": 0.8, "value": 40, "conv_bleed_pct": 5,
			"attachments": []},
		{"name": "Hatchet", "type": "melee", "ammo": "none", "tier": 3, "damage": 26.0, "rof": 0.92, "value": 90, "conv_bleed_pct": 15,
			"attachments": ["grip"]},
		{"name": "Zip gun", "type": "improvised", "ammo": "pistol", "tier": 3, "damage": 30.0, "rof": 0.8, "value": 85,
			"attachments": []},
		{"name": "Extendable baton", "type": "melee", "ammo": "none", "tier": 3, "damage": 16.0, "rof": 1.5, "value": 90,
			"attachments": ["grip"]},
		{"name": "Commando dagger", "type": "melee", "ammo": "none", "tier": 4, "damage": 18.0, "rof": 1.65, "value": 150, "conv_bleed_pct": 20,
			"attachments": ["grip"]},
		{"name": "Wheel brace", "type": "melee", "ammo": "none", "tier": 4, "damage": 40.0, "rof": 0.75, "value": 145,
			"attachments": []},
		{"name": "Pen gun", "type": "improvised", "ammo": "pistol", "tier": 4, "damage": 30.0, "rof": 1.0, "value": 150,
			"attachments": []},
		{"name": "Spring gun", "type": "improvised", "tier": 4, "damage": 45.0, "rof": 0.67, "value": 150,
			"attachments": ["optic"]},
	],
	## Armour and helmets: armour, and weight as pace - a riot suit stops a lot and
	## slows you; leathers stop less and don't.
	"Helmet": [
		{"name": "Hard hat", "tier": 1, "armour": 5.0, "value": 20, "role": "heavy"},
		{"name": "Cycle helmet", "tier": 1, "armour": 4.0, "pace": 2, "value": 15, "role": "light"},
		{"name": "Riot helmet", "tier": 2, "armour": 12.0, "value": 40, "role": "heavy"},
		{"name": "Fire helmet", "tier": 2, "armour": 14.0, "pace": -3, "value": 35, "role": "heavy"},
		{"name": "Army helmet", "tier": 3, "armour": 22.0, "value": 80, "role": "heavy"},
		{"name": "Visored helmet", "tier": 3, "armour": 28.0, "pace": -5, "value": 110, "role": "heavy"},
		{"name": "Ballistic visor", "tier": 4, "armour": 36.0, "pace": -3, "value": 180, "role": "heavy"},
		{"name": "Full-face helmet", "tier": 5, "armour": 48.0, "pace": -6, "value": 280, "role": "heavy"},
		{"name": "Composite helmet", "tier": 6, "armour": 60.0, "pace": -4, "value": 420, "role": "heavy"},
		## resist gear (6 Oct): a resist built into the base, read by resist() beside the affixes
		{"name": "Welder's mask", "tier": 3, "armour": 23.0, "pace": -2, "value": 150, "res": {"fire": 35}, "role": "specialist"},
		{"name": "Station helmet, visored", "tier": 4, "armour": 40.0, "pace": -3, "value": 300, "res": {"fire": 25}, "role": "specialist"},
		{"name": "Bomb-squad helmet", "tier": 6, "armour": 72.0, "pace": -8, "value": 560, "res": {"fire": 20, "shock": 20}, "role": "specialist"},
		## the deep bases (10 Oct): tiers 7-9, about +18% armour a tier, and the resist line carried on
		{"name": "High-cut helmet", "tier": 7, "armour": 70.0, "pace": -3, "value": 600, "role": "heavy"},
		{"name": "Special forces helmet", "tier": 8, "armour": 82.0, "pace": -3, "value": 850, "role": "heavy"},
		{"name": "CBRN helmet", "tier": 8, "armour": 70.0, "pace": -5, "value": 900, "res": {"poison": 30, "frost": 20}, "role": "specialist"},
		{"name": "Command helmet", "tier": 9, "armour": 96.0, "pace": -4, "value": 1200, "role": "heavy"},
		{"name": "Full EOD helmet", "tier": 9, "armour": 100.0, "pace": -8, "value": 1300, "res": {"fire": 25, "shock": 25}, "role": "specialist"},
		## the itemisation's (29 Oct, docs/design/itemisation.md §2): three a tier in T1-4, two in T5-9 (worn: a heavy, a light and a specialist every tier)
		{"name": "Beekeeper's hat", "tier": 1, "armour": 4.0, "res": {"poison": 25}, "value": 25, "role": "specialist"},
		{"name": "Caving helmet", "tier": 2, "armour": 10.0, "stats": {"search_pct": 10}, "value": 40, "role": "light"},
		{"name": "Scrum cap", "tier": 2, "armour": 12.0, "res": {"bleed": 30}, "value": 40, "role": "specialist"},
		{"name": "Comms headset", "tier": 3, "armour": 14.0, "stats": {"patrol_pct": 10}, "value": 90, "role": "light"},
		{"name": "Bump helmet", "tier": 4, "armour": 26.0, "stats": {"search_pct": 14}, "value": 170, "role": "light"},
		{"name": "Thermal headset", "tier": 5, "armour": 32.0, "stats": {"patrol_pct": 14}, "value": 270, "role": "light"},
		{"name": "Respirator helmet", "tier": 5, "armour": 40.0, "pace": -2, "res": {"poison": 35}, "value": 290, "role": "specialist"},
		{"name": "Night-sight helmet", "tier": 6, "armour": 42.0, "stats": {"search_pct": 16}, "value": 420, "role": "light"},
		{"name": "Ghillie hood", "tier": 7, "armour": 48.0, "stats": {"patrol_pct": 18}, "value": 580, "role": "light"},
		{"name": "Arctic helmet", "tier": 7, "armour": 58.0, "pace": -3, "res": {"frost": 35}, "value": 600, "role": "specialist"},
		{"name": "Search-team helmet", "tier": 8, "armour": 58.0, "stats": {"search_pct": 20}, "value": 820, "role": "light"},
		{"name": "Surveillance helmet", "tier": 9, "armour": 70.0, "stats": {"patrol_pct": 20}, "value": 1150, "role": "light"},
	],
	"Armour": [
		{"name": "Work jacket", "tier": 1, "armour": 6.0, "value": 10, "start": true},     # the start: the worst there is, never found
		{"name": "Stab vest", "tier": 1, "armour": 15.0, "value": 60, "role": "heavy"},
		{"name": "Padded jacket", "tier": 1, "armour": 10.0, "pace": 2, "value": 40, "role": "light"},
		{"name": "Police body armour", "tier": 2, "armour": 35.0, "value": 80, "role": "heavy"},
		{"name": "Motorbike leathers", "tier": 2, "armour": 25.0, "pace": 4, "value": 90, "role": "light"},
		{"name": "Army plates", "tier": 3, "armour": 60.0, "value": 160, "role": "heavy"},
		{"name": "Ceramic plates", "tier": 3, "armour": 72.0, "value": 220, "role": "heavy"},
		{"name": "Riot suit", "tier": 3, "armour": 85.0, "pace": -8, "value": 260, "role": "heavy"},
		{"name": "Ballistic vest", "tier": 3, "armour": 80.0, "pace": -2, "value": 220, "role": "heavy"},     # the Shopping Centre's own: T4 to T3 (29 Oct)
		{"name": "Full plate carrier", "tier": 5, "armour": 140.0, "pace": -10, "value": 680, "role": "heavy"},
		{"name": "Light plates", "tier": 3, "armour": 62.0, "pace": 2, "value": 230, "role": "light"},     # the Bank's own: T5 to T3 (29 Oct)
		{"name": "Stab plates", "tier": 4, "armour": 105.0, "pace": -6, "value": 420, "role": "heavy"},     # the Barracks' own: T6 to T4 (29 Oct)
		## resist gear (6 Oct): what the trades wore against their own hazards
		{"name": "Fireman's tunic", "tier": 4, "armour": 85.0, "pace": -2, "value": 380, "res": {"fire": 40}, "role": "specialist"},
		{"name": "Lineman's rubber coat", "tier": 4, "armour": 85.0, "value": 360, "res": {"shock": 45}, "role": "specialist"},
		{"name": "Cold-store parka", "tier": 4, "armour": 85.0, "pace": -2, "value": 340, "res": {"frost": 45}, "role": "specialist"},
		{"name": "Hazmat suit", "tier": 5, "armour": 115.0, "pace": -4, "value": 520, "res": {"poison": 50}, "role": "specialist"},
		{"name": "Butcher's chainmail", "tier": 5, "armour": 115.0, "pace": -4, "value": 600, "res": {"bleed": 45}, "role": "specialist"},
		{"name": "Bomb suit", "tier": 6, "armour": 190.0, "pace": -14, "value": 1200, "res": {"fire": 20, "shock": 20}, "role": "heavy"},
		## the deep bases (10 Oct): tiers 7-9, about +16% armour a tier, and the resist line carried on
		{"name": "Military plate carrier", "tier": 7, "armour": 185.0, "pace": -6, "value": 1300, "role": "heavy"},
		{"name": "Turnout coat", "tier": 7, "armour": 150.0, "pace": -4, "value": 1100, "res": {"fire": 50}, "role": "specialist"},
		{"name": "Special forces plates", "tier": 8, "armour": 215.0, "pace": -6, "value": 1700, "role": "heavy"},
		{"name": "CBRN suit", "tier": 8, "armour": 175.0, "pace": -6, "value": 1500, "res": {"poison": 55, "frost": 30}, "role": "specialist"},
		{"name": "Heavy armour suit", "tier": 9, "armour": 250.0, "pace": -12, "value": 2200, "role": "heavy"},
		{"name": "Full EOD suit", "tier": 9, "armour": 260.0, "pace": -16, "value": 2400, "res": {"fire": 30, "shock": 30}, "role": "heavy"},
		## the itemisation's (29 Oct, docs/design/itemisation.md §2): three a tier in T1-4, two in T5-9 (worn: a heavy, a light and a specialist every tier)
		{"name": "Spraying overalls", "tier": 1, "armour": 12.0, "res": {"poison": 30}, "value": 45, "role": "specialist"},
		{"name": "Slash-proof jacket", "tier": 2, "armour": 28.0, "res": {"bleed": 35}, "value": 85, "role": "specialist"},
		{"name": "Foundry coat", "tier": 3, "armour": 70.0, "pace": -2, "res": {"fire": 35}, "value": 230, "role": "specialist"},
		{"name": "Low-profile vest", "tier": 4, "armour": 80.0, "pace": 3, "value": 400, "role": "light"},
		{"name": "Prison officer's vest", "tier": 5, "armour": 110.0, "pace": 3, "value": 690, "role": "light"},
		{"name": "Skeleton carrier", "tier": 6, "armour": 160.0, "pace": 3, "value": 880, "role": "light"},
		{"name": "Arctic smock", "tier": 6, "armour": 155.0, "pace": -4, "res": {"frost": 45}, "value": 900, "role": "specialist"},
		{"name": "Plainclothes vest", "tier": 7, "armour": 165.0, "pace": 3, "value": 1250, "role": "light"},
		{"name": "Tailored body armour", "tier": 8, "armour": 190.0, "pace": 3, "value": 1650, "role": "light"},
		{"name": "State protection vest", "tier": 9, "armour": 215.0, "pace": 3, "value": 2150, "role": "light"},
		{"name": "Chainmail shark suit", "tier": 9, "armour": 210.0, "pace": -8, "res": {"bleed": 50}, "value": 2250, "role": "specialist"},
	],
	## Gloves (29 Oct, §4): a role each - grip (quicker reloads), pace, rate of fire - its figure built in (`stats`, read beside the
	## affixes); three a tier. Quicker reloads is the gloves' alone.
	"Gloves": [
		{"name": "Gardening gloves", "tier": 1, "stats": {"reload_pct": 20}, "value": 25, "role": "grip"},
		{"name": "Woolly gloves", "tier": 1, "pace": 2, "value": 25, "role": "pace"},
		{"name": "Work gloves", "tier": 1, "stats": {"attack_pct": 3}, "value": 30, "role": "rate"},
		{"name": "Rigger gloves", "tier": 2, "stats": {"reload_pct": 28}, "value": 55, "role": "grip"},
		{"name": "Cycling mitts", "tier": 2, "pace": 3, "value": 55, "role": "pace"},
		{"name": "Driving gloves", "tier": 2, "stats": {"attack_pct": 4}, "value": 60, "role": "rate"},
		{"name": "Leather gloves", "tier": 3, "stats": {"reload_pct": 35}, "value": 110, "role": "grip"},
		{"name": "Goalkeeper gloves", "tier": 3, "pace": 4, "value": 110, "role": "pace"},
		{"name": "Shooting gloves", "tier": 3, "stats": {"attack_pct": 5}, "value": 120, "role": "rate"},
		{"name": "Roofer's gloves", "tier": 4, "stats": {"reload_pct": 42}, "value": 210, "role": "grip"},
		{"name": "Racing gloves", "tier": 4, "pace": 5, "value": 210, "role": "pace"},
		{"name": "Tactical gloves", "tier": 4, "stats": {"attack_pct": 6}, "value": 220, "role": "rate"},
		{"name": "Cut-resistant gloves", "tier": 5, "stats": {"reload_pct": 50}, "value": 350, "role": "grip"},
		{"name": "Fell-runner's gloves", "tier": 5, "pace": 6, "value": 350, "role": "pace"},
		{"name": "Armourer's gloves", "tier": 5, "stats": {"attack_pct": 7}, "value": 360, "role": "rate"},
		{"name": "Riot gauntlets", "tier": 6, "stats": {"reload_pct": 58}, "value": 510, "role": "grip"},
		{"name": "Pilot's gloves", "tier": 6, "pace": 7, "value": 510, "role": "pace"},
		{"name": "Stalker's gloves", "tier": 6, "stats": {"attack_pct": 8}, "value": 520, "role": "rate"},
		{"name": "Firefighter's gloves", "tier": 7, "stats": {"reload_pct": 65}, "value": 790, "role": "grip"},
		{"name": "Paratrooper's gloves", "tier": 7, "pace": 8, "value": 790, "role": "pace"},
		{"name": "Close-combat gloves", "tier": 7, "stats": {"attack_pct": 9}, "value": 800, "role": "rate"},
		{"name": "Flight-deck gloves", "tier": 8, "stats": {"reload_pct": 72}, "value": 1090, "role": "grip"},
		{"name": "Abseiling gloves", "tier": 8, "pace": 9, "value": 1090, "role": "pace"},
		{"name": "Counter-sniper gloves", "tier": 8, "stats": {"attack_pct": 10}, "value": 1100, "role": "rate"},
		{"name": "EOD gauntlets", "tier": 9, "stats": {"reload_pct": 80}, "value": 1490, "role": "grip"},
		{"name": "Dress uniform gloves", "tier": 9, "pace": 10, "value": 1490, "role": "pace"},
		{"name": "Special forces gloves", "tier": 9, "stats": {"attack_pct": 11}, "value": 1500, "role": "rate"},
	],
	## Rigs carry meds and ammo, a slot each; packs carry loot, in cells. Capacity in cells for packs:
	## a rifle is 3, a pistol or helmet 2, a med or an attachment 1.
	"Rig": [
		{"name": "Bum bag", "tier": 1, "capacity": 3, "value": 40, "role": "heavy"},
		{"name": "Fishing vest", "tier": 2, "capacity": 5, "value": 60, "role": "heavy"},
		{"name": "Paramedic's rig", "tier": 2, "capacity": 6, "pace": -2, "value": 90, "role": "heavy"},
		{"name": "Chest rig", "tier": 3, "capacity": 7, "value": 140, "role": "heavy"},
		{"name": "Webbing", "tier": 3, "capacity": 6, "pace": 3, "value": 120, "role": "light"},
		{"name": "Medic's harness", "tier": 4, "capacity": 9, "pace": -2, "value": 220, "role": "heavy"},
		{"name": "Plate rig", "tier": 5, "capacity": 8, "pace": 2, "value": 340, "stats": {"guard_gang": 6}, "role": "specialist"},
		{"name": "Assault rig", "tier": 6, "capacity": 9, "value": 460, "role": "heavy"},
		{"name": "Bomb-disposal rig", "tier": 6, "capacity": 11, "pace": -3, "value": 620, "stats": {"guard_gang": 7}, "role": "specialist"},
		## the deep bases (10 Oct): tiers 7-9
		{"name": "Special forces rig", "tier": 7, "capacity": 12, "value": 800, "role": "heavy"},
		{"name": "Breacher's rig", "tier": 8, "capacity": 13, "pace": 2, "value": 1000, "role": "heavy"},
		{"name": "Command rig", "tier": 9, "capacity": 15, "pace": -2, "value": 1300, "role": "heavy"},
		## the itemisation's (29 Oct, docs/design/itemisation.md §2): three a tier in T1-4, two in T5-9 (worn: a heavy, a light and a specialist every tier)
		{"name": "Gardening apron", "tier": 1, "capacity": 2, "stats": {"med_speed_pct": 10}, "value": 30, "role": "light"},
		{"name": "Body warmer", "tier": 1, "capacity": 2, "stats": {"guard_gang": 3}, "value": 35, "role": "specialist"},
		{"name": "Lifeguard's vest", "tier": 2, "capacity": 4, "stats": {"med_speed_pct": 12}, "value": 60, "role": "light"},
		{"name": "Tweed waistcoat", "tier": 2, "capacity": 4, "stats": {"guard_gang": 4}, "value": 70, "role": "specialist"},
		{"name": "Door staff vest", "tier": 3, "capacity": 6, "stats": {"guard_gang": 5}, "value": 130, "role": "specialist"},
		{"name": "Quick-release rig", "tier": 4, "capacity": 7, "stats": {"med_speed_pct": 15}, "value": 210, "role": "light"},
		{"name": "Public order rig", "tier": 4, "capacity": 7, "stats": {"guard_gang": 6}, "value": 220, "role": "specialist"},
		{"name": "Load carrier", "tier": 5, "capacity": 10, "value": 340, "role": "heavy"},
		{"name": "Slick rig", "tier": 5, "capacity": 7, "stats": {"med_speed_pct": 18}, "value": 330, "role": "light"},
		{"name": "Air ambulance vest", "tier": 6, "capacity": 8, "stats": {"med_speed_pct": 20}, "value": 470, "role": "light"},
		{"name": "Pathfinder rig", "tier": 7, "capacity": 9, "stats": {"med_speed_pct": 22}, "value": 760, "role": "light"},
		{"name": "Counter-terror rig", "tier": 7, "capacity": 10, "stats": {"guard_gang": 8}, "value": 800, "role": "specialist"},
		{"name": "Hostage-rescue rig", "tier": 8, "capacity": 10, "stats": {"med_speed_pct": 24}, "value": 960, "role": "light"},
		{"name": "Shield-team rig", "tier": 8, "capacity": 11, "stats": {"guard_gang": 9}, "value": 1000, "role": "specialist"},
		{"name": "Desert patrol rig", "tier": 9, "capacity": 11, "stats": {"med_speed_pct": 26}, "value": 1250, "role": "light"},
		{"name": "Royal escort rig", "tier": 9, "capacity": 12, "stats": {"guard_gang": 10}, "value": 1300, "role": "specialist"},
	],
	## a pack's "w" (Matt, 27 Oct, the pack as a real grid): its width in cells, never under 5 so a long gun lies flat;
	## its capacity is its cells, row by row (the Plastic bag 9 to 15, 5x3: a rifle or a jacket; the School bag 12 to 18,
	## the Carrier bags 10 to 16, 8x2, so no early pack is under the start); never over PACK_MAX_W, the grid's columns
	"Backpack": [
		{"name": "Plastic bag", "tier": 1, "capacity": 15, "w": 5, "value": 5, "start": true},     # the start: the worst there is, never found; 5x3, so a found vest (3×3) or a rifle (5×1) comes home
		{"name": "School bag", "tier": 1, "capacity": 18, "w": 6, "value": 30, "role": "heavy"},
		{"name": "Carrier bags", "tier": 1, "capacity": 16, "w": 8, "pace": 3, "value": 15, "role": "light"},     # two bags side by side, 8x2: long things, never a vest
		{"name": "Hiking pack", "tier": 2, "capacity": 24, "w": 6, "value": 60, "role": "heavy"},
		{"name": "Holdall", "tier": 2, "capacity": 20, "w": 5, "pace": 2, "value": 70, "role": "light"},
		{"name": "Bergen", "tier": 3, "capacity": 40, "w": 8, "value": 110, "role": "heavy"},
		{"name": "Framed pack", "tier": 3, "capacity": 48, "w": 8, "pace": -5, "value": 160, "role": "heavy"},
		{"name": "Expedition pack", "tier": 4, "capacity": 56, "w": 8, "pace": -3, "value": 260, "role": "heavy"},
		{"name": "Cargo frame", "tier": 4, "capacity": 64, "w": 8, "pace": -8, "value": 260, "role": "heavy"},     # the Services' own: T5 to T4 (29 Oct)
		{"name": "Patrol pack", "tier": 6, "capacity": 60, "w": 10, "value": 480, "role": "heavy"},
		{"name": "Full bergen", "tier": 6, "capacity": 80, "w": 10, "pace": -6, "value": 640, "role": "heavy"},
		## the deep bases (10 Oct): tiers 7-9
		{"name": "Assault pack", "tier": 7, "capacity": 72, "w": 9, "value": 820, "role": "heavy"},
		{"name": "Long-range bergen", "tier": 7, "capacity": 96, "w": 12, "pace": -6, "value": 860, "role": "heavy"},
		{"name": "Mountain-troop bergen", "tier": 8, "capacity": 104, "w": 13, "pace": -6, "value": 1100, "role": "heavy"},
		{"name": "Special forces bergen", "tier": 9, "capacity": 130, "w": 10, "pace": -6, "value": 1450, "role": "heavy"},
		## the itemisation's (29 Oct, docs/design/itemisation.md §2): three a tier in T1-4, two in T5-9 (worn: a heavy, a light and a specialist every tier)
		{"name": "Feed sack", "tier": 1, "capacity": 16, "w": 8, "stats": {"loot_pct": 10}, "value": 20, "role": "specialist"},
		{"name": "Tartan shopper", "tier": 2, "capacity": 20, "w": 5, "stats": {"loot_pct": 12}, "value": 55, "role": "specialist"},
		{"name": "Daysack", "tier": 3, "capacity": 32, "w": 8, "stats": {"search_pct": 10}, "value": 100, "role": "light"},
		{"name": "Dumpy bag", "tier": 3, "capacity": 36, "w": 6, "stats": {"loot_pct": 14}, "value": 110, "role": "specialist"},
		{"name": "Messenger bag", "tier": 4, "capacity": 40, "w": 8, "stats": {"search_pct": 12}, "value": 230, "role": "light"},
		{"name": "Sailor's bag", "tier": 4, "capacity": 48, "w": 8, "stats": {"loot_pct": 16}, "value": 240, "role": "specialist"},
		{"name": "Mule pack", "tier": 5, "capacity": 72, "w": 9, "pace": -6, "value": 390, "role": "heavy"},
		{"name": "Sniper's drag bag", "tier": 5, "capacity": 56, "w": 8, "stats": {"search_pct": 14}, "value": 380, "role": "light"},
		{"name": "Swag bag", "tier": 5, "capacity": 60, "w": 10, "stats": {"loot_pct": 18}, "value": 400, "role": "specialist"},
		{"name": "Search-and-rescue pack", "tier": 6, "capacity": 64, "w": 8, "stats": {"search_pct": 16}, "value": 470, "role": "light"},
		{"name": "Security van bag", "tier": 6, "capacity": 60, "w": 10, "stats": {"loot_pct": 20}, "value": 500, "role": "specialist"},
		{"name": "Clamshell pack", "tier": 7, "capacity": 64, "w": 8, "stats": {"search_pct": 18}, "value": 800, "role": "light"},
		{"name": "Ingot sack", "tier": 7, "capacity": 72, "w": 9, "stats": {"loot_pct": 22}, "value": 840, "role": "specialist"},
		{"name": "Alpine pack", "tier": 8, "capacity": 80, "w": 10, "stats": {"search_pct": 20}, "value": 1080, "role": "light"},
		{"name": "Strongroom bag", "tier": 8, "capacity": 80, "w": 10, "stats": {"loot_pct": 24}, "value": 1120, "role": "specialist"},
		{"name": "Freefall pack", "tier": 9, "capacity": 100, "w": 10, "stats": {"search_pct": 22}, "value": 1420, "role": "light"},
		{"name": "Wax-sealed bag", "tier": 9, "capacity": 100, "w": 10, "stats": {"loot_pct": 26}, "value": 1480, "role": "specialist"},
	],
	## Charms: `find` is magic find - rarer finds, in percent - and `cash`
	## percent on top. Every runner carries something.
	"Charm": [
		{"name": "Lucky penny", "tier": 1, "find": 5, "cash": 5, "value": 30, "role": "heavy"},
		{"name": "Rabbit's foot", "tier": 1, "find": 8, "cash": 0, "value": 40, "role": "light"},
		{"name": "St Christopher", "tier": 2, "find": 10, "cash": 5, "value": 90, "role": "light"},
		{"name": "Horseshoe nail", "tier": 2, "find": 6, "cash": 12, "value": 90, "role": "heavy"},
		{"name": "Wedding ring", "tier": 3, "find": 12, "cash": 10, "value": 180, "role": "light"},
		{"name": "Dog tag", "tier": 4, "find": 15, "cash": 8, "value": 320, "role": "light"},
		{"name": "Casino chip", "tier": 5, "find": 18, "cash": 15, "value": 520, "role": "light"},
		{"name": "Bank's own pen", "tier": 6, "find": 20, "cash": 20, "value": 800, "role": "light"},
		{"name": "Mayor's chain", "tier": 6, "find": 24, "cash": 24, "value": 1100, "role": "heavy"},
		## the deep bases (10 Oct): tiers 7-9
		{"name": "Signet ring", "tier": 7, "find": 28, "cash": 26, "value": 1500, "role": "light"},
		{"name": "Regimental medal", "tier": 8, "find": 32, "cash": 30, "value": 2000, "role": "light"},
		{"name": "Gold sovereign", "tier": 9, "find": 36, "cash": 36, "value": 2700, "role": "heavy"},
		## the itemisation's (29 Oct, docs/design/itemisation.md §2): three a tier in T1-4, two in T5-9 (worn: a heavy, a light and a specialist every tier)
		{"name": "Box of matches", "tier": 1, "find": 2, "cash": 0, "stats": {"fire_pct": 8}, "value": 25, "role": "specialist"},
		{"name": "Old spark plug", "tier": 2, "find": 3, "cash": 0, "stats": {"shock_pct": 10}, "value": 70, "role": "specialist"},
		{"name": "Gold tooth", "tier": 3, "find": 6, "cash": 16, "value": 170, "role": "heavy"},
		{"name": "Barber's razor", "tier": 3, "find": 4, "cash": 0, "stats": {"bleed_pct": 12}, "value": 170, "role": "specialist"},
		{"name": "Pocket watch", "tier": 4, "find": 8, "cash": 20, "value": 300, "role": "heavy"},
		{"name": "Brass canary", "tier": 4, "find": 5, "cash": 0, "stats": {"poison_pct": 14}, "value": 310, "role": "specialist"},
		{"name": "Gold cufflinks", "tier": 5, "find": 10, "cash": 26, "value": 500, "role": "heavy"},
		{"name": "Ice-hockey puck", "tier": 5, "find": 6, "cash": 0, "stats": {"frost_pct": 16}, "value": 510, "role": "specialist"},
		{"name": "Dragon brooch", "tier": 6, "find": 7, "cash": 0, "stats": {"fire_pct": 18}, "value": 780, "role": "specialist"},
		{"name": "Diamond tiepin", "tier": 7, "find": 16, "cash": 36, "value": 1450, "role": "heavy"},
		{"name": "Glass insulator", "tier": 7, "find": 8, "cash": 0, "stats": {"shock_pct": 20}, "value": 1460, "role": "specialist"},
		{"name": "Gold cigarette case", "tier": 8, "find": 18, "cash": 42, "value": 1950, "role": "heavy"},
		{"name": "Sword knot", "tier": 8, "find": 9, "cash": 0, "stats": {"bleed_pct": 22}, "value": 1960, "role": "specialist"},
		{"name": "Uncut diamond", "tier": 9, "find": 40, "cash": 20, "value": 2650, "role": "light"},
		{"name": "Apothecary's vial", "tier": 9, "find": 10, "cash": 0, "stats": {"poison_pct": 24}, "value": 2660, "role": "specialist"},
	],
	## Papers: the before, on paper. Worth their value to the Fence and nothing
	## else; the deeds are dropped by the Bank once; what's done with them is the player's.
	"Paper": [
		{"name": "A council tax reminder", "tier": 1, "value": 2},
		{"name": "A P45", "tier": 1, "value": 2},
		{"name": "A betting slip", "tier": 1, "value": 3},
		{"name": "A pawn ticket", "tier": 1, "value": 3},
		{"name": "A bank statement", "tier": 1, "value": 2},
		{"name": "A food bank voucher", "tier": 1, "value": 2},
		{"name": "A mortgage offer", "tier": 1, "value": 3},
		{"name": "A school report", "tier": 1, "value": 2},
		{"name": "A lottery ticket", "tier": 1, "value": 4},
		{"name": "A wage slip", "tier": 1, "value": 2},
		{"name": "An eviction notice", "tier": 1, "value": 3},
		{"name": "A boarding pass", "tier": 1, "value": 4},
		{"name": "A parking ticket", "tier": 1, "value": 2},
		{"name": "A Christmas list", "tier": 1, "value": 3},
		# the Outskirts' and the City's (12 Oct, the lore pass): each in its site's "only" list
		{"name": "A seed order", "tier": 1, "value": 2},
		{"name": "An allotment waiting list", "tier": 1, "value": 2},
		{"name": "A loyalty card", "tier": 1, "value": 2},
		{"name": "A milk quota letter", "tier": 1, "value": 3},
		{"name": "A delivery note", "tier": 1, "value": 4},
		{"name": "A drug chart", "tier": 1, "value": 3},
		{"name": "A leave pass", "tier": 1, "value": 3},
		{"name": "A requisition", "tier": 1, "value": 4},
		# the deep ones: only past these depths, so the whole book is a reason to go there
		{"name": "A ration book", "tier": 1, "value": 4, "depth": 12},
		{"name": "A council minute", "tier": 1, "value": 4, "depth": 18},
		{"name": "A bus timetable, amended", "tier": 1, "value": 4, "depth": 24},
		{"name": "A letter to the Bank", "tier": 1, "value": 5, "depth": 30},
		{"name": "A list of names", "tier": 1, "value": 5, "depth": 40},
		{"name": "The Manager's note", "tier": 1, "value": 6, "depth": 50},
		# Kev's story (15 Oct, endgame_radio.md §3): three papers a beat, found once the Radio's on the air, that only
		# matter together - tier 5, as the deeds: never a search's roll
		{"name": "A tachograph disc", "tier": 5, "value": 6, "story": 0},
		{"name": "A route card", "tier": 5, "value": 6, "story": 0},
		{"name": "A fuel receipt", "tier": 5, "value": 6, "story": 0},
		{"name": "A movement order", "tier": 5, "value": 8, "story": 1},
		{"name": "A ration chit", "tier": 5, "value": 8, "story": 1},
		{"name": "A signals log", "tier": 5, "value": 8, "story": 1},
		{"name": "A gate pass", "tier": 5, "value": 10, "story": 2},
		{"name": "A loading manifest", "tier": 5, "value": 10, "story": 2},
		{"name": "A depot plan", "tier": 5, "value": 10, "story": 2},
		{"name": "The deeds", "tier": 5, "value": 5000},
		# the gates (13 Oct, docs/design/campaign_gates.md): a head's own, home in the pack whatever it holds; each opens a room
		{"name": "The vet's bag", "tier": 5, "value": 0},           # tier 5, as the deeds: never a paper's roll
		{"name": "The Carpet Man's ledger", "tier": 8, "value": 0},
		{"name": "A military radio", "tier": 5, "value": 0},
		{"name": "The fitter's kit", "tier": 5, "value": 0},     # the Carpet Man's, opening the Workshop (27 Oct: was the Quartermaster's armourer's tool roll, its picture kept)
	],
	## Medical: heals `heal` HP over `use` seconds, under fire the whole time.
	"Medical": [
		{"name": "Painkillers", "tier": 1, "heal": 15.0, "use": 1.5, "value": 12},
		{"name": "Bandage", "tier": 1, "heal": 25.0, "use": 3.0, "value": 15},
		{"name": "First aid kit", "tier": 1, "heal": 60.0, "use": 6.0, "value": 45, "from": "Bandage"},
		{"name": "Field dressing", "tier": 2, "heal": 40.0, "use": 2.0, "value": 50, "from": "First aid kit"},
		{"name": "Trauma kit", "tier": 2, "heal": 120.0, "use": 10.0, "value": 120, "from": "Field dressing"},
		{"name": "Surgeon's kit", "tier": 3, "heal": 200.0, "use": 12.0, "value": 220, "from": "Trauma kit"},
		{"name": "Hospital kit", "tier": 4, "heal": 300.0, "use": 14.0, "value": 380, "from": "Surgeon's kit"},
		# the cures (28 Oct, Matt: "different meds for different things like bleed/poison etc"): `cure` the element it
		# stops on you, at once, and CURE_IMMUNE_S before it can land again; no heal; a pouch each
		{"name": "Tourniquet", "tier": 1, "cure": "bleed", "use": 0.0, "value": 18},     # draft
		{"name": "Burn gel", "one": "a tube of burn gel", "plural": "tubes of burn gel", "tier": 1, "cure": "fire", "use": 0.0, "value": 18},     # draft
		{"name": "Activated charcoal", "one": "a packet of activated charcoal", "plural": "packets of activated charcoal", "tier": 1, "cure": "poison", "use": 0.0, "value": 18},     # draft
		{"name": "Hot flask", "tier": 2, "cure": "frost", "use": 0.0, "value": 30},     # draft
		{"name": "Smelling salts", "tier": 2, "cure": "shock", "use": 0.0, "value": 30},     # draft
	],
	## Medical supplies (28 Oct): a stack of `count`, for the Clinic
	"Supplies": [
		{"name": "Medical supplies", "tier": 1, "value": 6},     # draft
	],
	## Scrap and the rebuild's materials as pack items (1 Nov): a stack of `count`; `key` the counter it goes into at home;
	## `value` a unit's, its worth on the exchange (EXCHANGE_BASE), so a full pack's swap gives up the least worth first
	"Material": [
		{"name": "Scrap", "key": "scrap", "tier": 1, "value": 24},     # SCRAP_PER_POUND
		{"name": "Copper cable", "key": "copper_wire", "tier": 1, "value": 900},     # "Copper cable" on screen (1 Nov, Matt: Copper wire is the socketable); the key stays copper_wire, the saves' and the costs'
		{"name": "Paving", "key": "paving", "tier": 1, "value": 900},
		{"name": "Glass", "key": "glass", "tier": 1, "value": 900},
		{"name": "Ledgers", "key": "ledgers", "tier": 1, "value": 900},
		{"name": "Cable drums", "key": "cable_drums", "tier": 1, "value": 900},
		{"name": "Army kit", "key": "army_kit", "tier": 1, "value": 900},
		{"name": "Fuses", "key": "fuses", "tier": 1, "value": 900},
	],
	## Grenades (32): a pouch each, thrown at everyone on you; the hit is the type's, through the damage model
	"Grenade": [
		{"name": "Petrol bomb", "tier": 1, "damage": 80.0, "type": "fire", "value": 30, "from": "Lighter fluid"},
		{"name": "Nail bomb", "tier": 1, "damage": 70.0, "type": "bleed", "value": 30},
		{"name": "Bottle of something", "one": "a bottle of something", "plural": "bottles of something", "tier": 2, "damage": 90.0, "type": "poison", "value": 45, "from": "Rat poison"},
		{"name": "Dry-ice bag", "tier": 2, "damage": 60.0, "type": "frost", "value": 45, "from": "Antifreeze"},
		{"name": "Wired battery", "tier": 3, "damage": 100.0, "type": "shock", "value": 60, "from": "Car battery"},
	],
	## Ammo: a stack of `rounds` for a gun `type`, standard or a better grade
	## (damage_pct). Standard is always at the Fence by the box; the better
	## grades are found, or on its shelf.
	"Ammo": [
		# a stack is a bag of rounds, sized so a run takes about a third of one at the type's rate
		{"name": "Nails", "type": "improvised", "tier": 1, "rounds": 200, "value": 20},
		{"name": "Hardened bolts", "type": "improvised", "tier": 2, "rounds": 120, "value": 50, "damage_pct": 15, "from": "Nails"},
		{"name": "Shells", "type": "shotgun", "tier": 1, "rounds": 150, "value": 30},
		{"name": "Slugs", "type": "shotgun", "tier": 2, "rounds": 90, "value": 75, "damage_pct": 20, "from": "Shells"},
		{"name": "Rifle rounds", "type": "rifle", "tier": 1, "rounds": 400, "value": 40},
		## grades with an element (33): a share of the gun's hits land as the type, through the model like a conversion affix
		{"name": "Match rounds", "type": "rifle", "tier": 2, "rounds": 240, "value": 100, "damage_pct": 15, "first_pct": 25, "from": "Rifle rounds"},
		{"name": "SMG rounds", "type": "smg", "tier": 1, "rounds": 600, "value": 40},
		{"name": "SMG hollow point", "type": "smg", "tier": 2, "rounds": 360, "value": 100, "damage_pct": 15, "conv_bleed_pct": 20, "from": "SMG rounds"},
		{"name": "Pistol rounds", "type": "pistol", "tier": 1, "rounds": 300, "value": 25},
		{"name": "Pistol hollow point", "type": "pistol", "tier": 2, "rounds": 180, "value": 65, "damage_pct": 15, "conv_bleed_pct": 20, "from": "Pistol rounds"},
		{"name": "Belt links", "type": "smg", "tier": 3, "rounds": 500, "value": 160, "damage_pct": 20, "from": "SMG hollow point"},     # (30 Oct: its own "mag" went - a magazine's size is the gun's)
		{"name": "Depot rounds", "type": "rifle", "tier": 3, "rounds": 300, "value": 170, "damage_pct": 25, "from": "Match rounds"},
		{"name": "Incendiary shells", "type": "shotgun", "tier": 3, "rounds": 80, "value": 140, "damage_pct": 10, "conv_fire_pct": 30, "from": "Slugs"},
		{"name": "Incendiary SMG rounds", "type": "smg", "tier": 3, "rounds": 320, "value": 150, "damage_pct": 10, "conv_fire_pct": 30, "from": "SMG hollow point"},
		{"name": "Salted rounds", "type": "rifle", "tier": 3, "rounds": 220, "value": 150, "damage_pct": 10, "conv_frost_pct": 30, "from": "Match rounds"},
	],
	## Magazines (30 Oct, Matt: "you need to be able to find magazines and then fill them up out of boxes - then put
	## them into the rig"; docs/design/meds_ammo_clinic.md, "Magazines as items"): one a pouch (a drum two, its
	## footprint), by the ammo type it takes - any gun of the type. Its size the gun's own magazine times its kind
	## (MAG_KINDS); it holds rounds of one grade (`ammo`, the box's base) and `rounds` of them. Tiers and values: drafts
	## on the old magazine parts'.
	"Magazine": [
		{"name": "Pistol magazine", "type": "pistol", "kind": "standard", "tier": 1, "value": 30},
		{"name": "Extended pistol magazine", "type": "pistol", "kind": "extended", "tier": 1, "value": 70},
		{"name": "Quick pistol magazine", "type": "pistol", "kind": "quick", "tier": 2, "value": 90},
		{"name": "Pistol drum", "type": "pistol", "kind": "drum", "tier": 2, "value": 90},
		{"name": "Rifle magazine", "type": "rifle", "kind": "standard", "tier": 1, "value": 30},
		{"name": "Extended rifle magazine", "type": "rifle", "kind": "extended", "tier": 1, "value": 70},
		{"name": "Quick rifle magazine", "type": "rifle", "kind": "quick", "tier": 2, "value": 90},
		{"name": "Rifle drum", "type": "rifle", "kind": "drum", "tier": 2, "value": 90},
		{"name": "Shotgun magazine", "type": "shotgun", "kind": "standard", "tier": 1, "value": 30},
		{"name": "Extended shotgun magazine", "type": "shotgun", "kind": "extended", "tier": 1, "value": 70},
		{"name": "Quick shotgun magazine", "type": "shotgun", "kind": "quick", "tier": 2, "value": 90},
		{"name": "Shotgun drum", "type": "shotgun", "kind": "drum", "tier": 2, "value": 90},
		{"name": "SMG magazine", "type": "smg", "kind": "standard", "tier": 1, "value": 30},
		{"name": "Extended SMG magazine", "type": "smg", "kind": "extended", "tier": 1, "value": 70},
		{"name": "Quick SMG magazine", "type": "smg", "kind": "quick", "tier": 2, "value": 90},
		{"name": "SMG drum", "type": "smg", "kind": "drum", "tier": 2, "value": 90},
		{"name": "Nail magazine", "type": "improvised", "kind": "standard", "tier": 1, "value": 30},
		{"name": "Extended nail magazine", "type": "improvised", "kind": "extended", "tier": 1, "value": 70},
		{"name": "Quick nail magazine", "type": "improvised", "kind": "quick", "tier": 2, "value": 90},
		{"name": "Nail drum", "type": "improvised", "kind": "drum", "tier": 2, "value": 90},
		{"name": "Belt box", "type": "smg", "kind": "belt", "tier": 3, "value": 240},
		{"name": "Hundred-round drum", "type": "smg", "kind": "hundred", "tier": 5, "value": 460},
	],
}
## Magazines (28 Oct, Matt: "carrying 3000 smg rounds in a rig doesn't make much sense for the realistic tone we
## have"; docs/design/meds_ammo_clinic.md): a gun fires from its magazine, MAG_SIZE rounds by what it fires (a base's
## own "mag" over it), and empty it reloads - RELOAD_S of no fire from it (a base's "reload" over it), shortened by
## reload_pct. Magazines are items (30 Oct): the rig carries them, a pouch each (a drum two), each loaded with one
## grade; boxes stay in the stash and the pack, and fill them at home, free, at the gate.
const MAG_SIZE := {"smg": 30, "rifle": 10, "pistol": 15, "shotgun": 8, "improvised": 50}     # draft
const RELOAD_S := {"smg": 2.0, "rifle": 2.5, "pistol": 1.5, "shotgun": 3.0, "improvised": 2.0}     # draft
## A magazine's kind (30 Oct): `x` the gun's own magazine (or `flat` rounds whatever the gun), `reload` the gun's reload
## into it. Drafts.
const MAG_KINDS := {
	"standard": {"x": 1.0, "reload": 1.0},
	"extended": {"x": 1.5, "reload": 1.0},
	"quick": {"x": 1.0, "reload": 0.6},
	"drum": {"x": 2.0, "reload": 1.4},
	"belt": {"x": 2.5, "reload": 1.5},
	"hundred": {"flat": 100, "reload": 1.8},
}
const MAGAZINE := "Magazine"
const REFILL_MULT := 2.0            # draft (3 to 2.5 to 2, the fix round: the estate read's Poacher at the Pleasure Park under a coin flip): a magazine refilled by hand mid-run from a box in the pack, the gun's reload times this
const PLAN_BOXES_MAX := 9           # BUILD46-R (2 Nov): the most boxes of a type the rounds picker's − N + goes to (the pack's room bounds it again)
const BOT_ROUNDS_X := 1.2           # BUILD46-R: the bot's boxes bring its primary's rounds to this times the fight's want
const RIG_MAG_SHARE := 0.5          # draft: the gate's top-up packs magazines into up to this share of the rig's pouches, the meds the rest
const SHELF_MAGS := 2               # draft: the Fence's standard magazines on the shelf, of each type a gun you hold takes, every restock
const MAG_OF_PARTS := 0.2          # draft: of a find that would be a gun part, the share that's a magazine instead (the five magazine parts were a seventh of the parts)
const AMMO_PRICE := 1.5             # the Fence's markup on a standard box
const AMMO_DROP := 0.22             # the share of a kill's drops that are rounds; a look's is half that
const MED_PRICE := 1.5            # the Clinic's markup on a common med
const MED_DROP := 0.08            # the share of finds that are medical
## Medical supplies' finds (28 Oct): a look's share at a site leaning to meds, times its lean (the Garden Centre 1.5,
## the Hospital 3); a medicine cabinet's share of its finds on top; so many a find; a stack's most.
const SUPPLY_FIND := 0.03           # draft
const SUPPLY_CABINET := 0.35        # draft
const SUPPLY_COUNT := [1, 3]        # draft
const SUPPLY_STACK := 30            # draft
## The Clinic's shelf as supplies come in (28 Oct): each step `need` handed in all told; `tier` lifts what she stocks,
## then `magic` and `rare` are the shares of her heals rolled with med affixes. Her shelf's size stays the Yard's picks.
const CLINIC_STEPS := [
	{"need": 10, "tier": 1},                               # draft
	{"need": 30, "tier": 2},                               # draft
	{"need": 60, "tier": 2, "magic": 0.35},                # draft
	{"need": 100, "tier": 2, "magic": 0.45, "rare": 0.15},     # draft
	{"need": 160, "tier": 3, "magic": 0.45, "rare": 0.35},     # draft
]
const CLINIC_CURES := 2             # draft: of her shelf, so many are cures, the front's elements first
const GRENADE_DROP := 0.04        # the share of a look's finds that are grenades (32)
const ATT_DROP := 0.30            # the share of a look's finds that are attachments
const SOCKET_FIND := 0.04         # a socketable, a find of its own (21 Oct, Matt's save: 4 in 300 finds, none his element's): kills too
const SOCKET_OWN := 0.5           # and this share of them one of the class's own elements'

## Attachments: items that fit a gun's slots at the Workshop. `mount` is the
## gun slot they go in; the effects are read off the fitted gun. Rarer ones
## roll affixes like gear. The Workshop's level says which mounts can be
## fitted at all - the camp's cash sink.
const ATTACHMENT := "Attachment"
const MOUNTS := ["optic", "muzzle", "sling", "handguard", "stock", "grip", "business end"]
## Each gun type's edge (29 Oct, docs/design/itemisation.md §3; drafts for the pass): the primary's, in the fight and in the
## figures that read it (Sim.edge_read). A rifle ignores `pierce` of a man's armour (their physical resist) and lands
## `opener` more on its first round into each man; a shotgun's every round hits the next in line for `x` of it; a melee
## weapon does `x` more with `on_you` or more on you; something improvised takes `sockets` more than another gun.
## Walking fire (an SMG's) is its base's own `sustain`; the pistol's quick draw is the sling's (30 Oct: while the primary
## reloads the secondary keeps its backing share, lifted to the primary's sling's; at full while it's dry or refilling).
const EDGE := {"rifle": {"pierce": 0.3, "opener": 0.5}, "shotgun": {"x": 0.4}, "melee": {"x": 0.2, "on_you": 2}, "improvised": {"sockets": 1}}
const MELEE_INCOMING := 1.25       # in among them: their fire on you, with a melee primary
const MELEE_WAIT := 1.0            # seconds: their first shot lands before your first swing, each gang
## Sockets: a gun, a helmet or armour rolls up to SOCKET_MAX of them; a
## socketable (mount "socket") goes in any. What they add can't be had
## elsewhere: fire, frost, poison, shock, salt, wire.
const SOCKET_SLOTS := ["Primary", "Secondary", "Helmet", "Armour"]
const SOCKET_MAX := 2
const SOCKET_ODDS := [0.45, 0.4, 0.15]     # 0, 1, 2 sockets
## A find's base by tier (30 Oct, the designer's call on the review's loot rolls: at T9 an even draw made 1 find in 10 a
## T9): the find's own tier, one under, and every tier lower shared evenly (Items._tier_pick).
const LOOT_OWN_TIER := 0.5
const LOOT_TIER_UNDER := 0.3
const LOOT_LOWER := 0.2
## A zone's own kit (31 Oct, the designer, on the review's "T4 heavies at one site each"; the fix round: keep the home
## rate, add the zone): a site's own base (its "only" list) that also drops at every other site of its home's zone, in
## the pool at a plain base's weight there; at its home it keeps its own-share draw as before; nowhere else (not the
## shelf's, not another zone's).
const ZONE_KIT := ["Stab plates", "Medic's harness", "Cargo frame"]     # the City's T4 heavy armour, heavy rig and heavy backpack

## Damage types. A hit is split by type (`Sim.conversion`), each share
## multiplied by its own increased and more, cut by their resist to it, and
## some leave something behind: fire burns, poison poisons, bleed bleeds (a
## share of the hit over seconds; poison stacks), frost chills (their fire
## slower), shock shocks (they take more of everything). Physical is what's
## left after the conversions, and armour only ever stops physical; the
## rest only resists do.
const TYPES := ["physical", "fire", "frost", "poison", "shock", "bleed"]
const ELEMENTS := ["fire", "frost", "poison", "shock", "bleed"]
const RESIST_CAP := 75.0
const GUARD_SHARE := 0.15          # Guard (12 Oct, docs/design/shields.md): its cap, a share of max HP; 0.25 to 0.15 (Matt, the first read: the lorry at 2-7 h, 8-15 moves in 16 - "not supposed to be a cake walk")
const OVER_CAP := 50.0             # over the cap (12 Oct, docs/design/over_the_cap.md): a resist past RESIST_CAP is +1% of that element's damage a point, to this many points
const THICK_SKIN_FROM := 200.0     # Thick-skinned: armour past this, a tenth of it as physical
const DOTS := {"fire": {"ratio": 0.5, "s": 4.0, "stacks": 1}, "poison": {"ratio": 0.8, "s": 8.0, "stacks": 5}, "bleed": {"ratio": 0.7, "s": 6.0, "stacks": 1}}
const CHILL := 0.2                 # their fire, while chilled
const FREEZE := 0.85               # Frozen solid: how much of their fire a chilled gang loses (not all: a sliver keeps the depth honest)
const SHOCK := 0.25                # more of everything they take, while shocked
## Their side, by zone: what their fire is made of at depth 1 (physical is the
## rest) and what they resist. The element's share grows with depth (ZONE_GROW
## a depth, to ZONE_SHARE_CAP); "Resistant" and the depth add to the resists.
const ZONE_TYPES := [
	{"types": {"poison": 0.1}, "res": {}},                                   # the Outskirts (12 Oct): sticks, spades and the weedkiller
	{"types": {"bleed": 0.15}, "res": {}},                                   # the estate: blades and bats; nothing on but a coat
	{"types": {"fire": 0.15, "poison": 0.1}, "res": {"bleed": 0.2, "physical": 0.1}},   # the town: petrol and whatever's in the bottles; jackets
	{"types": {"shock": 0.15, "fire": 0.15, "frost": 0.15}, "res": {"fire": 0.2, "shock": 0.2, "physical": 0.2, "frost": 0.1, "poison": 0.15}},   # the city: army kit, greatcoats, gas masks (poison 0.15, 12 Oct: the poison builds ran the loop to 9-15 moves, fire and shock 1-6; bleed stays open - every zone leaves one, the band check)
]
const ZONE_GROW := 0.02
## Harder gangs (B9, 15 Oct): from the second gang on, a gang can be the next zone's crew - their HP, their fire and
## what it's made of; the City's are its own hard core, as hard. The chance climbs a step a gang past the first.
const GANG_NEXT_STEP := 0.3        # 0.2 to 0.3 (the tuning batch, 21 Oct): the next zone's crew from the second gang more often
const GANG_NEXT_MAX := 0.8
const GANG_NEXT_HP := 1.6
const GANG_NEXT_DPS := 1.5
const ZONE_SHARE_CAP := 0.6
const RESIST_DEPTH := 8            # from here, the zone's own resists (what it wears and what it throws) rise a step a depth; the rest stay open
const RESIST_DEPTH_STEP := 0.015
const RESIST_ENEMY_CAP := 0.7
const ATTACHMENTS := [
	# optics
	{"name": "Red dot", "mount": "optic", "tier": 1, "value": 60, "damage_pct": 5},
	{"name": "Torch", "mount": "optic", "tier": 1, "value": 30, "first_pct": 15, "speed_pct": -3},
	{"name": "Holo sight", "mount": "optic", "tier": 2, "value": 70, "damage_pct": 8},
	{"name": "Telescopic sight", "mount": "optic", "tier": 2, "value": 90, "first_pct": 30},
	{"name": "Thermal sight", "mount": "optic", "tier": 3, "value": 200, "first_pct": 50, "patrol_pct": -10},
	# muzzles
	{"name": "Flash hider", "mount": "muzzle", "tier": 1, "value": 40, "damage_pct": 3},
	{"name": "Choke", "mount": "muzzle", "tier": 1, "value": 45, "damage_pct": 15, "type": "shotgun"},
	{"name": "Compensator", "mount": "muzzle", "tier": 2, "value": 70, "damage_pct": 8, "speed_pct": -3},
	{"name": "Oil-can silencer", "mount": "muzzle", "tier": 3, "value": 120, "damage_pct": -5, "patrol_pct": 25},
	{"name": "Muzzle brake", "mount": "muzzle", "tier": 3, "value": 180, "damage_pct": 12, "speed_pct": -5},
	# slings (30 Oct, magazines as items: the magazine mount became the sling): while the primary reloads between
	# magazines, the secondary fires at sling_pct of its fire - the designer's B: a lift over its usual backing share,
	# never under it; drafts
	# the slings' damage back (31 Oct, PROBE33, the designer's call: the magazine parts' damage went with them), drafts
	{"name": "Rope sling", "mount": "sling", "tier": 1, "value": 40, "sling_pct": 50, "damage_pct": 8},
	{"name": "Webbing sling", "mount": "sling", "tier": 2, "value": 90, "sling_pct": 65, "damage_pct": 10},
	{"name": "Leather sling", "mount": "sling", "tier": 4, "value": 300, "sling_pct": 80, "damage_pct": 12},
	{"name": "Two-point sling", "mount": "sling", "tier": 6, "value": 520, "sling_pct": 100, "damage_pct": 15},
	# handguards
	{"name": "Foregrip", "mount": "handguard", "tier": 1, "value": 50, "damage_pct": 6},
	{"name": "Rail handguard", "mount": "handguard", "tier": 2, "value": 80, "damage_pct": 4, "speed_pct": 4},
	{"name": "Heat shield", "mount": "handguard", "tier": 2, "value": 100, "damage_pct": 10, "type": "shotgun"},
	{"name": "Bipod", "mount": "handguard", "tier": 2, "value": 150, "damage_pct": 18, "speed_pct": -6, "type": "rifle"},
	# stocks
	{"name": "Folding stock", "mount": "stock", "tier": 1, "value": 60, "speed_pct": 6},
	{"name": "Wire stock", "mount": "stock", "tier": 1, "value": 50, "damage_pct": 8, "type": "improvised"},
	# melee: the grip and the head
	{"name": "Tape", "mount": "grip", "tier": 1, "value": 20, "speed_pct": 4},
	{"name": "Cord wrap", "mount": "grip", "tier": 2, "value": 60, "first_pct": 10, "speed_pct": 2},
	{"name": "Lanyard", "mount": "grip", "tier": 3, "value": 120, "damage_pct": 4, "speed_pct": 4},
	{"name": "Nails through it", "mount": "business end", "tier": 1, "value": 30, "conv_bleed_pct": 8},     # bleed halved (31 Oct, the designer: the melee bleed cut, was 15)
	{"name": "A blade on it", "mount": "business end", "tier": 2, "value": 90, "damage_pct": 10, "conv_bleed_pct": 5},     # bleed halved (31 Oct, the designer: the melee bleed cut, was 10)
	{"name": "Lead in it", "mount": "business end", "tier": 3, "value": 160, "damage_pct": 18, "speed_pct": -6},
	{"name": "Heavy stock", "mount": "stock", "tier": 2, "value": 80, "damage_pct": 9, "speed_pct": -4},
	{"name": "Cheek riser", "mount": "stock", "tier": 2, "value": 90, "first_pct": 10},
	{"name": "Recoil pad", "mount": "stock", "tier": 3, "value": 160, "damage_pct": 6, "first_pct": 3},
	# tiers 4 and 5
	{"name": "Night optic", "mount": "optic", "tier": 4, "value": 320, "first_pct": 40, "damage_pct": 5},
	{"name": "Ported brake", "mount": "muzzle", "tier": 4, "value": 300, "damage_pct": 15},
	{"name": "Angled grip", "mount": "handguard", "tier": 4, "value": 280, "damage_pct": 8, "speed_pct": 4},
	{"name": "Precision stock", "mount": "stock", "tier": 5, "value": 420, "first_pct": 15, "damage_pct": 8},
	{"name": "Laser module", "mount": "optic", "tier": 6, "value": 520, "first_pct": 20, "damage_pct": 6},
	# socketables: the six things that go in a socket, found and fitted at the Bench
	{"name": "Lighter fluid", "mount": "socket", "tier": 1, "value": 120, "conv_fire_pct": 15},
	{"name": "Antifreeze", "mount": "socket", "tier": 1, "value": 120, "conv_frost_pct": 15},
	{"name": "Rat poison", "mount": "socket", "tier": 2, "value": 160, "conv_poison_pct": 15},
	{"name": "Car battery", "mount": "socket", "tier": 2, "value": 160, "conv_shock_pct": 15},
	{"name": "Road salt", "mount": "socket", "tier": 1, "value": 100, "salt": 12},
	{"name": "Copper wire", "mount": "socket", "tier": 3, "value": 200, "wire_pct": 12},
	{"name": "Suppressor", "mount": "muzzle", "tier": 6, "value": 560, "damage_pct": -3, "patrol_pct": 35},
]

## Uniques: named items with a fixed affix set and one rule of their own, found
## at depth (UNIQUE_DROP a find, times the depth past the first). The things a
## build is found around. `rule` is a flag the sim reads like a keystone's.
const UNIQUE_DROP := 0.01
## The loot tables (15 Oct, the loot read, Matt's picks): a loose unique from the Town on at UNIQUE_CAMPAIGN a find,
## growing UNIQUE_DROP a depth past the first and never past UNIQUE_CAP; set pieces, SET_DROP a depth, to SET_CAP; and
## a zone's quality on the rarity roll (the Outskirts' nothing to the City's +45%), so a City drop is rarer.
const UNIQUE_CAMPAIGN := 0.02     # a loose unique's chance in the campaign
const UNIQUE_FROM_ZONE := 2
const UNIQUE_CAP := 0.04
## The mythics (16 Oct, docs/design/mythics.md): one find in MYTHIC_ODDS_IN is one, everywhere alike - no depth,
## quantity, quality or charm in it; one held isn't rolled again until all seven are.
const MYTHIC_ODDS_IN := 10000
const MYTHIC_HURT_A_SECOND := 0.05     # the Bomb Disposal Suit: never more than this of your HP a second
const MYTHIC_AUTO_MED := 0.5           # the Ambulance's Bag: a med by itself under this
## The cures (28 Oct, docs/design/meds_ammo_clinic.md): one is used by itself when its element on you is heavy - what
## its pool would still take is CURE_AT of the HP left - as a heal is under 40%; then CURE_IMMUNE_S before it lands again.
const CURE_AT := 0.25                  # draft
const CURE_IMMUNE_S := 6.0             # draft
const TOP_UP_CURES := 2                # draft: the gate packs a cure for each of the front's elements, so many at most
## Frost and shock on you (28 Oct, the cures: there was nothing of theirs on the runner to cure): their fire's frost
## and shock fill a pool as a burn's does (`ratio` of what landed, draining over `s`), and the pool at `full` of your
## max HP is the whole effect - frost your fire `most` slower, shock `most` more of theirs taken.
const MY_AILS := {"frost": {"ratio": 0.5, "s": 4.0, "full": 0.25, "most": 0.2}, "shock": {"ratio": 0.5, "s": 4.0, "full": 0.25, "most": 0.2}}     # draft
const MYTHIC_SEARCH_FINDS := 2         # the Removal Van: finds a search, more
const MYTHIC_PACK := 4                 # and the pack this many times over
const MYTHIC_PAY := 2.0                # the Freedom of the Borough: tins, notes and XP
const SET_CAP := 0.02
const ZONE_QUALITY := [0.0, 0.15, 0.30, 0.32]     # by zone, on the rarity roll: the City's held to gate 12's 8-16% epic or better
## Uniques by tier (12 Oct, docs/design/uniques.md): every unique but a paper has a band and a range of tiers. It drops at
## the find's loot tier inside its range, on the best base of its slot (and gun type) at that tier; a loose one only where
## the find's tier is inside its range, the band's weight picking among those that can.
const UNIQUE_BAND_WEIGHT := {"levelling": 10.0, "core": 4.0, "chase": 1.0, "mythic": 0.0}     # a mythic is never a pool's pick: its own roll
const SITE_UNIQUE_DEPTH := [99, 12, 9, 6]   # a site's own unique, by zone: the depth it drops from
const SITE_UNIQUE_DROP := 0.03          # a find past that depth, on that site, until it is on the shelf
const SITE_UNIQUE_AGAIN := 0.25         # of that, once it is: a second is for the Fence, not the chase
const UNIQUES := [
	{"name": "Grandad's Shotgun", "slot": "Primary", "base": "Farmer's shotgun", "rule": "grandads", "band": "levelling", "range": [1, 3],
		"words": "Triple damage to the first of each gang", "short": "×3 damage to each gang's first", "affixes": [{"stat": "damage_pct", "value": 10}, {"stat": "first_lot_pct", "value": 20}]},
	{"name": "The Postman's Bag", "slot": "Backpack", "base": "Hiking pack", "rule": "postman", "band": "levelling", "range": [1, 3],
		"words": "Every search finds 1 more", "short": "+1 find a search", "affixes": [{"stat": "capacity", "value": 4}, {"stat": "loot_pct", "value": 15}]},
	{"name": "The Doorman's Jacket", "slot": "Armour", "base": "Police body armour", "rule": "doormans", "band": "levelling", "range": [2, 3],
		"words": "Take 25% less damage with three or more on you", "short": "−25% damage taken, 3+ on you", "affixes": [{"stat": "armour", "value": 12}, {"stat": "hp", "value": 20}]},
	{"name": "Lucky Cap", "slot": "Helmet", "base": "Hard hat", "rule": "lucky_cap", "band": "levelling", "range": [1, 3],
		"words": "Finds are half as likely to be common", "short": "Half the commons", "affixes": [{"stat": "loot_pct", "value": 20}, {"stat": "cash_per_kill", "value": 6}]},
	# the bosses' - only from them; their rules are the affixes, for now
	# the Gamekeeper's (15 Oct, Matt: "killing him and getting absolutely nothing felt bad")
	{"name": "The Keeper's Twelve-Bore", "slot": "Primary", "base": "Pump shotgun", "rule": "keepers_gun", "band": "levelling", "range": [1, 3], "boss": true,
		"words": "Every kill heals 3% of max HP", "short": "A kill heals 3% max HP", "affixes": [{"stat": "damage_pct", "value": 12}, {"stat": "first_lot_pct", "value": 15}]},
	{"name": "The Keeper's Wax Jacket", "slot": "Armour", "base": "Padded jacket", "rule": "keepers_wax", "band": "levelling", "range": [1, 3], "boss": true,
		"words": "Poison and bleed on you do half damage", "short": "Poison, bleed on you halved", "affixes": [{"stat": "armour", "value": 10}, {"stat": "hp", "value": 15}]},
	{"name": "The Van's Spare", "slot": "Secondary", "base": "Old revolver", "rule": "vans_spare", "band": "levelling", "range": [2, 4], "boss": true,
		"words": "The secondary does 67% of its damage beside the primary, not 33%", "short": "Secondary at 67%", "affixes": [{"stat": "first_lot_pct", "value": 25}, {"stat": "cash_per_kill", "value": 4}]},     # 15 Oct, Matt: was at full and +18% damage - "nothing beats the Van's Spare"; Double tap takes it to full
	{"name": "Underlay", "slot": "Armour", "base": "Padded jacket", "rule": "underlay", "band": "levelling", "range": [2, 4], "boss": true,
		"words": "The first 2 seconds of every gang's fire do no damage", "short": "No damage for each gang's first 2 s", "affixes": [{"stat": "armour", "value": 30}, {"stat": "hp", "value": 25}, {"stat": "speed_pct", "value": 6}]},
	{"name": "The Manager's Coat", "slot": "Armour", "base": "Ballistic vest", "rule": "managers_coat", "band": "core", "range": [3, 7], "boss": true,
		"words": "Tins from kills +50%; kills drop no notes", "short": "Kill tins ×1.5, no kill notes", "affixes": [{"stat": "armour", "value": 20}, {"stat": "cash_per_kill", "value": 8}, {"stat": "hp", "value": 20}]},
	{"name": "The Branch Pistol", "slot": "Secondary", "base": "Tactical pistol", "rule": "branch_pistol", "band": "core", "range": [3, 7], "boss": true,
		"words": "The secondary does double damage under half HP", "short": "Secondary ×2 under ½ HP", "affixes": [{"stat": "damage_pct", "value": 20}, {"stat": "damage_low_pct", "value": 25}, {"stat": "speed_pct", "value": 6}]},
	{"name": "The Quartermaster's Rifle", "slot": "Primary", "base": "Marksman rifle", "rule": "qm_rifle", "band": "chase", "range": [4, 9], "boss": true,
		"words": "Never runs out of rounds", "short": "Never runs dry", "affixes": [{"stat": "damage_pct", "value": 20}, {"stat": "first_lot_pct", "value": 30}, {"stat": "damage_per_att", "value": 5}]},
	{"name": "Issue Webbing", "slot": "Rig", "base": "Assault rig", "rule": "issue_webbing", "band": "chase", "range": [4, 9], "boss": true,
		"words": "The rig has twice as many pouches", "short": "Pouches ×2", "affixes": [{"stat": "capacity", "value": 3}, {"stat": "armour", "value": 15}, {"stat": "loot_per_med", "value": 5}]},
	# the pinnacles' - a charm each, from a crew's head at full strength
	{"name": "The Van Keys", "slot": "Charm", "base": "Horseshoe nail", "rule": "van_keys", "band": "chase", "range": [4, 9], "boss": true, "pinnacle": 1,
		"words": "Pace +25%", "short": "Pace +25%", "affixes": [{"stat": "rarity_pct", "value": 10}, {"stat": "cash_pct", "value": 10}, {"stat": "loot_pct", "value": 8}]},
	{"name": "The Manager's Pen", "slot": "Charm", "base": "Bank's own pen", "rule": "managers_pen", "band": "chase", "range": [5, 9], "boss": true, "pinnacle": 2,
		"words": "Notes from a run doubled", "short": "Notes ×2", "affixes": [{"stat": "rarity_pct", "value": 12}, {"stat": "cash_pct", "value": 15}, {"stat": "loot_pct", "value": 5}]},
	{"name": "The Quartermaster's Ledger", "slot": "Charm", "base": "Dog tag", "rule": "qm_ledger", "band": "chase", "range": [5, 9], "boss": true, "pinnacle": 3,
		"words": "Kill drops roll one loot tier higher", "short": "Kill drops a tier up", "affixes": [{"stat": "rarity_pct", "value": 15}, {"stat": "cash_pct", "value": 8}, {"stat": "loot_pct", "value": 10}]},
	# the convoy's
	{"name": "The Lorry's Load", "slot": "Backpack", "base": "Cargo frame", "rule": "lorrys_load", "band": "chase", "range": [5, 9], "boss": true, "convoy": true,
		"words": "Every empty pack cell comes home as notes, more on a higher signal", "short": "Empty cells home as notes", "affixes": [{"stat": "capacity", "value": 8}, {"stat": "loot_pct", "value": 15}, {"stat": "cash_per_cell", "value": 3}]},
	# the order's (18 Oct, docs/design/rebuild.md §5): one each from the true pinnacles, nowhere else
	{"name": "The Lineman's Lamp", "slot": "Helmet", "base": "High-cut helmet", "rule": "linemans_lamp", "band": "chase", "range": [5, 9], "boss": true, "order": "grid",
		"words": "At night: no slower feet, and the dark's finds count double", "short": "Night: full pace, finds ×2", "affixes": [{"stat": "armour", "value": 24}, {"stat": "rarity_pct", "value": 15}]},
	{"name": "The Registrar's Satchel", "slot": "Backpack", "base": "Assault pack", "rule": "registrars_satchel", "band": "chase", "range": [5, 9], "boss": true, "order": "archive",
		"words": "Papers turn up twice as often", "short": "Papers ×2", "affixes": [{"stat": "capacity", "value": 6}, {"stat": "loot_pct", "value": 15}]},
	{"name": "The Issuer's Robes", "slot": "Armour", "base": "Heavy armour suit", "rule": "issuers_robes", "band": "chase", "range": [7, 9], "boss": true, "order": "mint",
		"words": "A run's tins +1% for every point of the town's worth", "short": "Tins +1% a point of worth", "affixes": [{"stat": "armour", "value": 40}, {"stat": "hp", "value": 40}, {"stat": "cash_pct", "value": 10}]},
	# a build to make of each (24 Oct, the endgame chase): beside the old one, the first win gives one of the two
	{"name": "The Lineman's Tool Bag", "slot": "Backpack", "base": "Hiking pack", "rule": "linemans_bag", "band": "chase", "range": [5, 9], "boss": true, "order": "grid",
		"words": "Every shock you put on a man arcs to everyone else on you at half strength; shocked men take 20% more damage from your skills", "short": "Shock arcs to all; skills +20% on shocked", "affixes": [{"stat": "capacity", "value": 4}, {"stat": "shock_pct", "value": 20}]},
	{"name": "The Registrar's Stamp", "slot": "Charm", "base": "Bank's own pen", "rule": "registrars_stamp", "band": "chase", "range": [5, 9], "boss": true, "order": "archive",
		"words": "Every third skill you use costs nothing and goes off twice", "short": "Every third skill: free, fires twice", "affixes": [{"stat": "cdr_pct", "value": 10}]},
	{"name": "The Issuer's Revolver", "slot": "Secondary", "base": "Officer's revolver", "rule": "issuers_revolver", "band": "chase", "range": [7, 9], "boss": true, "order": "mint",
		"words": "A kill lands the killing hit again on the next man; a kill from that hit does the same", "short": "A kill's hit lands again on the next", "affixes": [{"stat": "damage_pct", "value": 20}]},
	# the build-defining ones: a rule each, found loose from `depth` on, and from the mate once you've been that deep;
	# nine of them are a site's own (`site`, endgame part 3, 7 Oct): found only on that site, past SITE_UNIQUE_DEPTH for its
	# zone, SITE_UNIQUE_DROP a find - the estate's at 12, the town's at 9, the city's at 6, so the streets' is the deepest dig
	# in the game and the Barracks' the hardest fight. Never loose, never the mate's: the shelf shows the nine as gaps until found.
	{"name": "The Council's Weed Burner", "slot": "Primary", "base": "Pipe shotgun", "rule": "weed_burner", "band": "core", "range": [3, 9], "depth": 6,
		"words": "All damage is fire and hits everyone on you", "short": "All fire, hits all on you", "affixes": [{"stat": "dot_pct", "value": 30}, {"stat": "speed_pct", "value": -10}]},     # its +40% fire off (the second review: it out-hit every element gun on five builds)
	{"name": "Jump Leads", "slot": "Secondary", "base": "Service pistol", "rule": "jump_leads", "band": "core", "range": [3, 9], "depth": 6,
		"words": "33% of damage becomes shock; shock hits everyone on you", "short": "33% as shock, hits all", "affixes": [{"stat": "shock_pct", "value": 40}, {"stat": "first_pct", "value": 20}]},
	{"name": "The Rat Man's Bag", "slot": "Backpack", "base": "Hiking pack", "rule": "rat_mans_bag", "band": "core", "range": [3, 9], "depth": 6,
		"words": "Poison has no stack cap and carries to the next man when one dies", "short": "Poison uncapped, carries", "affixes": [{"stat": "poison_pct", "value": 40}, {"stat": "capacity", "value": 6}, {"stat": "dot_pct", "value": 20}]},
	{"name": "The Butcher's Steel", "slot": "Primary", "base": "Machete", "rule": "butchers_steel", "band": "core", "range": [3, 9], "body": {"bleed_min": 25}, "depth": 6,
		"words": "Bleed does double damage and carries to the next man when one dies", "short": "Bleed ×2, carries", "affixes": [{"stat": "bleed_pct", "value": 40}, {"stat": "conv_bleed_pct", "value": 25}, {"stat": "attack_pct", "value": 10}]},
	{"name": "The Gritter's Hopper", "slot": "Armour", "base": "Riot suit", "rule": "gritters_hopper", "band": "chase", "range": [4, 9], "site": 3,
		"words": "Everyone on you is always chilled, and only one can fire on you at once", "short": "Always chilled; 1 on you", "affixes": [{"stat": "frost_pct", "value": 40}, {"stat": "armour", "value": 30}, {"stat": "frost_res", "value": 30}]},
	{"name": "The Sparky's Gloves", "slot": "Gloves", "base": "Leather gloves",     # a charm till the gloves (29 Oct)
		 "rule": "sparkys_gloves", "band": "core", "range": [3, 7], "site": 5,
		"words": "Their shock resist is ignored; Earthed no longer costs armour", "short": "Shock resist ignored", "affixes": [{"stat": "shock_pct", "value": 30}, {"stat": "shock_res", "value": 40}]},
	{"name": "The Quartermaster's Manual", "slot": "Charm", "base": "Dog tag", "rule": "qm_manual", "band": "chase", "range": [5, 9], "site": 11,
		"words": "The class can open more than 2 elements; taken off, those past 2 idle", "short": "More than 2 elements", "affixes": [{"stat": "rarity_pct", "value": 10}, {"stat": "all_res", "value": 8}]},
	{"name": "A Blue Plaque", "slot": "Charm", "base": "St Christopher", "rule": "blue_plaque", "band": "chase", "range": [4, 9], "site": 8,
		"words": "All resists +40%; no other affix on your kit counts", "short": "Resists +40%, nothing else", "affixes": [{"stat": "all_res", "value": 40}]},
	{"name": "The Lollipop Lady's Sign", "slot": "Secondary", "base": "Cosh", "rule": "lollipop", "band": "core", "range": [3, 9], "depth": 6,
		"words": "The first of each gang dies at once; gangs take twice as long to arrive", "short": "First of each gang dies; gangs ×2 later", "affixes": [{"stat": "first_pct", "value": 30}, {"stat": "patrol_pct", "value": 15}]},
	{"name": "The Bookie's Pencil", "slot": "Charm", "base": "Lucky penny", "rule": "bookies_pencil", "band": "core", "range": [3, 9], "depth": 6,
		"words": "Loot quality ×2; tins from kills halved", "short": "Quality ×2, tins ½", "affixes": [{"stat": "rarity_pct", "value": 15}, {"stat": "loot_pct", "value": 10}]},
	{"name": "The Float", "slot": "Backpack", "base": "Cargo frame", "rule": "the_float", "band": "chase", "range": [4, 9], "site": 7,
		"words": "Pace +40%, pack +50%; you carry no meds", "short": "Pace +40%; no meds", "affixes": [{"stat": "capacity", "value": 10}, {"stat": "speed_pct", "value": 15}, {"stat": "cash_pct", "value": 20}]},
	{"name": "Nan's Cardigan", "slot": "Armour", "base": "Padded jacket", "rule": "nans_cardigan", "band": "core", "range": [3, 9], "body": {"pace_min": 0}, "depth": 6,
		"words": "Heals 3% of max HP a second; no armour at all", "short": "3% max HP/s, no armour", "affixes": [{"stat": "hp", "value": 40}, {"stat": "all_res", "value": 10}]},
	{"name": "The Dinner Lady's Ladle", "slot": "Primary", "base": "Pipe wrench", "rule": "ladle", "band": "core", "range": [3, 9], "depth": 6,
		"words": "Every kill heals 10% of max HP; meds do nothing", "short": "10% HP a kill, no meds", "affixes": [{"stat": "damage_pct", "value": 20}, {"stat": "attack_pct", "value": 15}]},
	{"name": "A Traffic Warden's Hat", "slot": "Helmet", "base": "Hard hat", "rule": "wardens_hat", "band": "levelling", "range": [2, 3],
		"words": "Every gang arrives one man short; kills drop double notes", "short": "Gangs one short, notes ×2", "affixes": [{"stat": "notes_pct", "value": 25}, {"stat": "armour", "value": 10}]},
	{"name": "The Vicar's Thermos", "slot": "Charm", "base": "Casino chip", "rule": "vicars_thermos", "band": "chase", "range": [4, 9], "site": 10,
		"words": "A burn on you heals you instead; your fire resist is 0", "short": "Burns heal you", "affixes": [{"stat": "regen", "value": 1.0}, {"stat": "fire_pct", "value": 20}]},
	{"name": "The Scout Leader's Whistle", "slot": "Charm", "base": "Rabbit's foot", "rule": "scouts_whistle", "band": "levelling", "range": [1, 3],
		"words": "Every gang after the first is one man", "short": "Gangs after the first: 1 man", "affixes": [{"stat": "patrol_pct", "value": 10}, {"stat": "loot_pct", "value": 10}]},
	{"name": "The Sergeant's Whistle", "slot": "Helmet", "base": "Composite helmet", "rule": "sergeants_whistle", "band": "chase", "range": [5, 9], "site": 4,
		"words": "Damage +60%; 2 more on you at once", "short": "+60% damage, +2 on you", "affixes": [{"stat": "armour", "value": 20}, {"stat": "hp", "value": 30}, {"stat": "crowd_less_pct", "value": 10}]},
	{"name": "The Electrician's Tester", "slot": "Secondary", "base": "Compact pistol", "rule": "tester", "band": "core", "range": [3, 9], "depth": 6,
		"words": "Shock lasts until the target is down; shock does half damage", "short": "Shock holds, does half", "affixes": [{"stat": "conv_shock_pct", "value": 25}, {"stat": "shock_pct", "value": 20}]},
	{"name": "The Gamekeeper's Flask", "slot": "Charm", "base": "Wedding ring", "rule": "gamekeepers_flask", "band": "core", "range": [3, 7], "site": 6,
		"words": "Poison on you poisons them back", "short": "Poison on you poisons them", "affixes": [{"stat": "poison_res", "value": 30}, {"stat": "poison_pct", "value": 30}]},
	{"name": "The Caretaker's Keys", "slot": "Charm", "base": "Bank's own pen", "rule": "caretakers_keys", "band": "chase", "range": [5, 9], "depth": 12,
		"words": "An event on every run, and every locked crate opens", "short": "An event a run; locked crates open", "affixes": [{"stat": "loot_pct", "value": 15}, {"stat": "search_pct", "value": 10}]},
	{"name": "The Lorry Driver's Log", "slot": "Paper", "base": "A pawn ticket", "rule": "drivers_log", "site": 9,
		"words": "Notes from a run doubled; insurance is free", "short": "Notes ×2, free insurance", "affixes": [{"stat": "notes_pct", "value": 50}]},
	# the elements' own (6 Oct): one a type, each leaning the whole way into it, for the builds that break the game
	{"name": "The Arsonist's Rig", "slot": "Rig", "base": "Assault rig", "rule": "arsonists_rig", "band": "chase", "range": [5, 9], "depth": 14,
		"words": "Every med used sets everyone on you alight", "short": "Meds set them alight", "affixes": [{"stat": "fire_pct", "value": 40}, {"stat": "med_cap", "value": 2}, {"stat": "conv_fire_pct", "value": 20}]},
	{"name": "The Gritter's Keys", "slot": "Charm", "base": "Wedding ring", "rule": "gritters_keys", "band": "chase", "range": [5, 9], "depth": 14,
		"words": "A chill lasts until the target dies; chilled targets take double frost damage", "short": "Chill holds, frost ×2", "affixes": [{"stat": "frost_pct", "value": 40}, {"stat": "conv_frost_pct", "value": 25}]},
	{"name": "The Rat Man's Overalls", "slot": "Armour", "base": "Motorbike leathers", "rule": "rat_mans_overalls", "band": "chase", "range": [5, 9], "depth": 14,
		"words": "Poison stacks without limit and deals its damage twice as fast", "short": "Poison: no cap, ×2 speed", "affixes": [{"stat": "poison_pct", "value": 50}, {"stat": "poison_res", "value": 35}, {"stat": "armour", "value": 20}]},
	{"name": "The Substation Key", "slot": "Charm", "base": "Horseshoe nail", "rule": "substation_key", "band": "chase", "range": [5, 9], "depth": 14,
		"words": "Shock hits everyone on you; shocked targets take 60% more damage", "short": "Shock spreads, +60%", "affixes": [{"stat": "shock_pct", "value": 40}, {"stat": "conv_shock_pct", "value": 20}]},
	{"name": "The Butcher's Apron", "slot": "Armour", "base": "Butcher's chainmail", "rule": "butchers_apron", "band": "chase", "range": [5, 9], "depth": 14,
		"words": "A bleed stacks to 3 and carries to the next man when one dies", "short": "Bleed carries, stacks to 3", "affixes": [{"stat": "bleed_pct", "value": 50}, {"stat": "conv_bleed_pct", "value": 25}, {"stat": "armour", "value": 25}]},
	# the gaps' (12 Oct, docs/design/uniques.md): a chase secondary, a core helmet, a levelling and a core rig
	{"name": "The Starting Pistol", "slot": "Secondary", "base": "Close quarters pistol", "rule": "starting_pistol", "band": "chase", "range": [5, 9], "depth": 12,
		"words": "Each man in every gang first takes a free shot from the secondary at triple damage", "short": "Free ×3 secondary shot", "affixes": [{"stat": "damage_pct", "value": 20}, {"stat": "first_pct", "value": 25}]},
	{"name": "The Miner's Lamp", "slot": "Helmet", "base": "Ballistic visor", "rule": "miners_lamp", "band": "core", "range": [3, 5], "depth": 6,
		"words": "Searches take half as long", "short": "Searches twice as quick", "affixes": [{"stat": "search_pct", "value": 20}, {"stat": "loot_pct", "value": 10}, {"stat": "armour", "value": 10}]},
	{"name": "The Paramedic's Bum Bag", "slot": "Rig", "base": "Bum bag", "rule": "paramedics_bumbag", "band": "levelling", "range": [1, 3],
		"words": "Meds heal 50% more; one is used by itself under 40% HP", "short": "Meds +50%, auto under 40%", "affixes": [{"stat": "med_cap", "value": 1}, {"stat": "hp", "value": 15}]},
	{"name": "The Plumber's Belt", "slot": "Rig", "base": "Medic's harness", "rule": "plumbers_belt", "band": "core", "range": [3, 5], "depth": 6,
		"words": "Burns, poison and bleeds on them deal double; chills and shocks last twice as long", "short": "Damage over time ×2; chill, shock last ×2", "affixes": [{"stat": "dot_pct", "value": 20}, {"stat": "capacity", "value": 2}]},
	# the gloves' (29 Oct, §4): a levelling pair and a chase pair
	{"name": "The Milkman's Gloves", "slot": "Gloves", "base": "Woolly gloves", "rule": "milkmans", "band": "levelling", "range": [1, 3],
		"words": "15% more pace until the site is cleared", "short": "+15% pace before the clear", "affixes": [{"stat": "reload_pct", "value": 10}, {"stat": "speed_pct", "value": 4}]},
	{"name": "The Safecracker's Gloves", "slot": "Gloves", "base": "Leather gloves", "rule": "safecrackers", "band": "chase", "range": [5, 9], "depth": 12,
		"words": "Reloads take no time · −15% rate of fire", "short": "No reloads · −15% rate of fire", "affixes": [{"stat": "attack_pct", "value": 10}, {"stat": "cdr_pct", "value": 5}]},
	# the mythics (16 Oct, Matt: "a really powerful unique per slot ... a flat % drop rate across the entire game ... if
	# you do get one then the point is that it does break game balance"; docs/design/mythics.md): one a slot, at
	# MYTHIC_ODDS a find wherever it is, worn at any level, never lost; their own band, outside every other pool
	{"name": "The Last Orders", "slot": "Primary", "base": "Old .303", "rule": "last_orders", "band": "mythic", "mythic": true, "range": [2, 9],
		"words": "Every hit does full damage as physical and each of the 5 elements", "short": "Full damage as every type", "affixes": [{"stat": "damage_pct", "value": 30}, {"stat": "attack_pct", "value": 10}]},
	{"name": "The Spare Key", "slot": "Secondary", "base": "Old revolver", "rule": "spare_key", "band": "mythic", "mythic": true, "range": [2, 9],
		"words": "The secondary always does its full damage beside the primary, and never spends a round", "short": "Secondary: full damage, no rounds", "affixes": [{"stat": "damage_pct", "value": 30}, {"stat": "attack_pct", "value": 10}]},
	{"name": "The Headmaster's Cap", "slot": "Helmet", "base": "Composite helmet", "rule": "headmasters_cap", "band": "mythic", "mythic": true, "range": [1, 9],
		"words": "Every perk in the class's trees is yours except keystones", "short": "Every class perk yours", "affixes": [{"stat": "hp", "value": 40}, {"stat": "armour_pct", "value": 15}]},
	{"name": "The Bomb Disposal Suit", "slot": "Armour", "base": "Police body armour", "rule": "bomb_suit", "band": "mythic", "mythic": true, "range": [1, 9],
		"words": "You never lose more than 5% of max HP a second, and the clock never runs out", "short": "At most 5% max HP lost a second; no clock", "affixes": [{"stat": "hp", "value": 40}, {"stat": "armour_pct", "value": 15}]},
	{"name": "The Crash Bag", "slot": "Rig", "base": "Assault rig", "rule": "ambulance_bag", "band": "mythic", "mythic": true, "range": [1, 9],
		"words": "Meds are never used up; one is used by itself under 50% HP", "short": "Meds never used up; auto under 50%", "affixes": [{"stat": "capacity", "value": 3}, {"stat": "med_speed_pct", "value": 30}]},
	{"name": "The Removal Van", "slot": "Backpack", "base": "Cargo frame", "rule": "removal_van", "band": "mythic", "mythic": true, "range": [1, 9],
		"words": "The pack holds 4 times as much, finds roll one loot tier higher, and every search finds 2 more", "short": "Pack ×4, finds tier up, +2 a search", "affixes": [{"stat": "loot_pct", "value": 25}, {"stat": "search_pct", "value": 20}]},
	{"name": "The Freedom of the Borough", "slot": "Charm", "base": "Horseshoe nail", "rule": "freedom", "band": "mythic", "mythic": true, "range": [1, 9],
		"words": "No gangs come after the clear, locked crates open, and tins, notes and XP are doubled", "short": "No gangs after the clear; pay ×2", "affixes": [{"stat": "rarity_pct", "value": 20}, {"stat": "cash_pct", "value": 20}]},
]
## The effects' numbers (15 Oct, refactor A2): every figure a tree node, a unique's or a set's rule, a joint, a
## Yard pick or rank and a map node puts into the sim, in one table, so the balance pass tunes them here. Key:
## "kind/id", ".what" after it where one effect has more than one number. Sim reads Data.FX["..."]; the
## figures are as they were in sim.gd (the fingerprint unmoved). What each is comes from the data's own words.
## Skills (24 Oct, milestone 8: docs/design/skills.md). Energy: a pool that fills at the start of every fight (each
## gang), refills at ENERGY_REGEN a second plus a share of pace's bonus; every skill costs energy and has a cooldown.
const ENERGY_POOL := 100.0
const ENERGY_REGEN := 4.0
const ENERGY_PACE_SHARE := 0.25          # a quarter of pace's bonus: pace 1.20 gives +5% regen
const CDR_CAP := 40.0                    # cooldown reduction, per cent, at most
const SKILL_SLOTS := 3
const OPENER_S := 5.0                    # the Opener rule: the first five seconds of a fight
const FINISHER_AT := 0.25                # the Finisher rule: a man on you under a quarter HP
## The rules a skill fires on by itself (the chips' words are skills.md section 11's).
const SKILL_RULES := {"ready": "When ready", "on_you_2": "2+ on you", "on_you_3": "3+ on you", "under_half": "Under half HP",
	"ailing": "Ailing", "finisher": "Finisher", "opener": "Opener", "opener_ready": "Opener, then ready", "bleeding": "Bleeding",
	"poison_burn": "Poisoned or burning", "ailments_2": "2+ ailments", "low_rounds": "Low on rounds", "no_grenade": "No grenade",
	"last_stand": "Last stand", "on_you_3_half": "3+ on you, over half HP"}
const LOW_ROUNDS := 60                   # the Low on rounds rule: fewer in the rig for the gun in hand
## A skill: its class and lane, cost, cooldown (s), its kind (damage, cleanse, control, defence: the bot's pick reads
## it), rule and what it does (`fx`, read by sim._skill_fire). Names and
## lines are the language pass's; `fx` figures are first figures for the balance pass.
const SKILLS := {
	"clean_shot": {"name": "Clean shot", "cls": "Poacher", "lane": "Stalking", "cost": 25, "cd": 8, "kind": "damage", "rule": "ready",
		"line": "Your next shot does ×2.5 damage", "fx": {"shot_mult": 2.5, "shot_s": 1.0}},
	"flush_them_out": {"name": "Flush them out", "cls": "Poacher", "lane": "Stalking", "cost": 30, "cd": 15, "kind": "damage", "rule": "on_you_3",
		"line": "Pulls the man at the back to the middle; he takes 20% more damage for 8 seconds", "fx": {"exposed": 0.2, "exposed_s": 8.0}},
	"go_to_ground": {"name": "Go to ground", "cls": "Poacher", "lane": "Stalking", "cost": 35, "cd": 25, "kind": "cleanse", "rule": "ailing",
		"line": "Out of sight for 3 seconds: nothing can hit you. Clears bleed and poison on you.", "fx": {"hidden_s": 3.0, "clears": ["bleed", "poison"]}},
	"one_for_the_pot": {"name": "One for the pot", "cls": "Poacher", "lane": "Stalking", "cost": 50, "cd": 30, "kind": "damage", "rule": "finisher", "signature": true,
		"line": "A man on you under 25% HP dies at once. A head takes ×5 damage instead.", "fx": {"execute": true, "head_mult": 5.0}},
	"collared": {"name": "Collared", "cls": "Poacher", "lane": "Snares", "cost": 25, "cd": 12, "kind": "control", "rule": "on_you_2",
		"line": "The nearest man is stunned for 3 seconds: he can't fire", "fx": {"stun_one_s": 3.0}},
	"gin_trap": {"name": "Gin trap", "cls": "Poacher", "lane": "Snares", "cost": 30, "cd": 15, "kind": "damage", "rule": "opener_ready",
		"line": "The next man to join the fight takes ×3 damage and starts to bleed", "fx": {"trap_mult": 3.0, "bleed_s": 1.0}},
	"decoy": {"name": "Decoy", "cls": "Poacher", "lane": "Snares", "cost": 35, "cd": 20, "kind": "defence", "rule": "under_half",
		"line": "Everyone on you does 30% less damage to you for 6 seconds", "fx": {"less_in": 0.3, "less_in_s": 6.0}},
	"net_every_hole": {"name": "Net every hole", "cls": "Poacher", "lane": "Snares", "cost": 60, "cd": 40, "kind": "control", "rule": "on_you_3", "signature": true,
		"line": "Everyone on you is stunned for 2 seconds and starts to bleed", "fx": {"stun_all_s": 2.0, "bleed_s": 1.0}},
	# the Paramedic (24 Oct, step 4): the cleanse class; her signature the one way back from going down
	"tourniquet": {"name": "Tourniquet", "cls": "Paramedic", "lane": "Triage", "cost": 20, "cd": 12, "kind": "cleanse", "rule": "bleeding",
		"line": "Clears bleed on you; no new bleed lands for 10 seconds", "fx": {"clears": ["bleed"], "ward": ["bleed"], "ward_s": 10.0}},
	"antidote": {"name": "Antidote", "cls": "Paramedic", "lane": "Triage", "cost": 25, "cd": 15, "kind": "cleanse", "rule": "poison_burn",
		"line": "Clears poison and burns on you; neither lands again for 8 seconds", "fx": {"clears": ["poison", "fire"], "ward": ["poison", "fire"], "ward_s": 8.0}},
	"adrenaline": {"name": "Adrenaline", "cls": "Paramedic", "lane": "Triage", "cost": 30, "cd": 20, "kind": "damage", "rule": "on_you_3",
		"line": "+25% damage and rate of fire for 8 seconds", "fx": {"hit_mult": 1.5625, "hit_s": 8.0}},
	"major_incident": {"name": "Major incident", "cls": "Paramedic", "lane": "Triage", "cost": 55, "cd": 40, "kind": "cleanse", "rule": "ailments_2", "signature": true,
		"line": "Clears every ailment on you, and you take no wound this run", "fx": {"clears": ["bleed", "poison", "fire"], "clear_all": true, "no_wound_run": true}},
	"two_sugars": {"name": "Two sugars", "cls": "Paramedic", "lane": "Shifts", "cost": 15, "cd": 25, "kind": "defence", "rule": "ready",
		"line": "Energy refills 50% quicker for 10 seconds", "fx": {"regen_mult": 1.5, "regen_s": 10.0}},
	"sedative_dart": {"name": "Sedative dart", "cls": "Paramedic", "lane": "Shifts", "cost": 25, "cd": 14, "kind": "control", "rule": "on_you_3",
		"line": "One man on you sleeps for 4 seconds", "fx": {"stun_one_s": 4.0}},
	"strapped_up": {"name": "Strapped up", "cls": "Paramedic", "lane": "Shifts", "cost": 30, "cd": 25, "kind": "defence", "rule": "under_half",
		"line": "The next hit that would wound you leaves no wound", "fx": {"wound_ward": true}},
	"code_blue": {"name": "Code blue", "cls": "Paramedic", "lane": "Shifts", "cost": 60, "cd": 0, "kind": "defence", "rule": "last_stand", "signature": true, "once_run": true,
		"line": "Once a run, a hit that would kill you leaves you on 30% HP with every ailment cleared", "fx": {"last_stand_hp": 0.3, "clears": ["bleed", "poison", "fire"], "clear_all": true}},
	# the Doorman: control and armour
	"shoulder_charge": {"name": "Shoulder charge", "cls": "Doorman", "lane": "Muscle", "cost": 25, "cd": 10, "kind": "damage", "rule": "ready",
		"line": "Hits the nearest man for ×3 damage and sends him to the back", "fx": {"hit_now": 3.0, "stun_one_s": 2.0}},
	"headbutt": {"name": "Headbutt", "cls": "Doorman", "lane": "Muscle", "cost": 20, "cd": 9, "kind": "control", "rule": "on_you_3",
		"line": "Hits the nearest man for ×1.5 damage and stuns him for 2 seconds", "fx": {"hit_now": 1.5, "stun_one_s": 2.0}},
	"brace": {"name": "Brace", "cls": "Doorman", "lane": "Muscle", "cost": 30, "cd": 18, "kind": "defence", "rule": "on_you_3",
		"line": "+60% armour for 6 seconds", "fx": {"armour_mult": 1.6, "armour_s": 6.0}},
	"barred": {"name": "Barred", "cls": "Doorman", "lane": "Muscle", "cost": 60, "cd": 45, "kind": "control", "rule": "on_you_3", "signature": true,
		"line": "Throws the nearest man out: a kill, but he drops nothing. Not on a head.", "fx": {"barred": true}},
	"not_on_the_list": {"name": "Not on the list", "cls": "Doorman", "lane": "The door", "cost": 30, "cd": 20, "kind": "control", "rule": "on_you_3",
		"line": "One fewer on you for 10 seconds", "fx": {"stun_one_s": 10.0}},
	"shutters_down": {"name": "Shutters down", "cls": "Doorman", "lane": "The door", "cost": 35, "cd": 22, "kind": "defence", "rule": "under_half",
		"line": "Take 80% less damage for 4 seconds", "fx": {"less_in": 0.8, "less_in_s": 4.0}},
	"pat_down": {"name": "Pat down", "cls": "Doorman", "lane": "The door", "cost": 25, "cd": 15, "kind": "damage", "rule": "opener_ready",
		"line": "The nearest man loses his armour and resists for 10 seconds", "fx": {"pat_down_s": 10.0}},
	"chucking_out_time": {"name": "Chucking-out time", "cls": "Doorman", "lane": "The door", "cost": 60, "cd": 40, "kind": "control", "rule": "on_you_3", "signature": true,
		"line": "Stuns everyone on you for 2 seconds, then they take 50% more for 6 seconds", "fx": {"stun_all_s": 2.0, "exposed": 0.5, "exposed_s": 8.0}},
	# the Scrapper: kit and wiring
	"ring_main": {"name": "Ring main", "cls": "Scrapper", "lane": "Stripping", "cost": 25, "cd": 9, "kind": "damage", "rule": "ready",
		"line": "×1.5 shock damage that jumps through 3 men", "fx": {"hit_now": 1.5, "spread": 3, "shock": true}},
	"hot_work": {"name": "Hot work", "cls": "Scrapper", "lane": "Stripping", "cost": 25, "cd": 10, "kind": "damage", "rule": "ready",
		"line": "Sets the nearest man burning for ×2 fire damage over 4 seconds", "fx": {"dot": "fire", "dot_x": 2.0}},
	"breakdown": {"name": "Breakdown", "cls": "Scrapper", "lane": "Stripping", "cost": 20, "cd": 15, "kind": "defence", "rule": "low_rounds",
		"line": "The next man you kill drops 20 rounds for your gun", "fx": {"rounds_on_kill": 20}},
	"short_circuit": {"name": "Short circuit", "cls": "Scrapper", "lane": "Stripping", "cost": 60, "cd": 40, "kind": "control", "rule": "on_you_3", "signature": true,
		"line": "Shocks everyone on you and stuns them for 1.5 seconds. Your shock damage +30% for 6 seconds.", "fx": {"stun_all_s": 1.5, "shock": true, "type_mult": {"shock": 1.3}, "type_s": 6.0}},
	"bung": {"name": "Bung", "cls": "Scrapper", "lane": "Fencing", "cost": 20, "cd": 20, "kind": "control", "rule": "on_you_3", "cash": 20,
		"line": "Pay 20 tins: the nearest man is stunned for 8 seconds", "fx": {"stun_one_s": 8.0}},
	"knock_off_kit": {"name": "Knock-off kit", "cls": "Scrapper", "lane": "Fencing", "cost": 30, "cd": 18, "kind": "damage", "rule": "ready",
		"line": "+30% gun damage for 8 seconds", "fx": {"hit_mult": 1.3, "hit_s": 8.0}},
	"back_of_the_van": {"name": "Back of the van", "cls": "Scrapper", "lane": "Fencing", "cost": 40, "cd": 0, "kind": "damage", "rule": "no_grenade", "once_fight": true,
		"line": "Puts a grenade in your rig. Once a fight.", "fx": {"grenade_to_rig": "Nail bomb"}},
	"everything_must_go": {"name": "Everything must go", "cls": "Scrapper", "lane": "Fencing", "cost": 60, "cd": 45, "kind": "damage", "rule": "opener", "signature": true,
		"line": "For 5 seconds, every shot fires twice", "fx": {"hit_mult": 2.0, "hit_s": 5.0}},
	# the Recruit (24 Oct, the sixth class): he casts most often
	"lob_one_in": {"name": "Lob one in", "cls": "Recruit", "lane": "Ordnance", "cost": 25, "cd": 10, "kind": "damage", "rule": "on_you_3",
		"line": "Throws a grenade at everyone on you without using one from your rig", "fx": {"lob": "Petrol bomb"}},
	"flashbang": {"name": "Flashbang", "cls": "Recruit", "lane": "Ordnance", "cost": 30, "cd": 16, "kind": "control", "rule": "on_you_3",
		"line": "Stuns everyone on you for 1.5 seconds; they do 50% less damage to you for 4 seconds", "fx": {"stun_all_s": 1.5, "less_in": 0.5, "less_in_s": 5.5}},
	"smoke": {"name": "Smoke", "cls": "Recruit", "lane": "Ordnance", "cost": 30, "cd": 18, "kind": "defence", "rule": "under_half",
		"line": "Half their shots at you miss for 6 seconds", "fx": {"less_in": 0.5, "less_in_s": 6.0}},
	"danger_close": {"name": "Danger close", "cls": "Recruit", "lane": "Ordnance", "cost": 60, "cd": 40, "kind": "damage", "rule": "on_you_3_half", "signature": true,
		"line": "×4 blast damage to everyone on you; you lose 10% of max HP", "fx": {"hit_now": 4.0, "spread": 99, "self_hp": 0.1}},
	"suppressing_fire": {"name": "Suppressing fire", "cls": "Recruit", "lane": "Drill", "cost": 30, "cd": 18, "kind": "defence", "rule": "on_you_3",
		"line": "Everyone on you fires 35% slower for 8 seconds", "fx": {"less_in": 0.35, "less_in_s": 8.0}},
	"make_ready": {"name": "Make ready", "cls": "Recruit", "lane": "Drill", "cost": 15, "cd": 8, "kind": "damage", "rule": "ready",
		"line": "+25% damage for your next 10 shots", "fx": {"hit_mult": 1.25, "hit_shots": 10}},
	"stand_to": {"name": "Stand to", "cls": "Recruit", "lane": "Drill", "cost": 0, "cd": 30, "kind": "defence", "rule": "ready",
		"line": "Gives 30 energy and takes 2 seconds off every cooldown", "fx": {"energy_now": 30.0, "cd_cut": 2.0}},
	"fire_and_manoeuvre": {"name": "Fire and manoeuvre", "cls": "Recruit", "lane": "Drill", "cost": 60, "cd": 50, "kind": "damage", "rule": "opener", "signature": true,
		"line": "For 10 seconds, skills cost half and cooldowns pass twice as quickly", "fx": {"fam_s": 10.0}},
	# the Drifter: evasion, big single hits and chance
	"duck_and_weave": {"name": "Duck and weave", "cls": "Drifter", "lane": "Moving on", "cost": 25, "cd": 12, "kind": "defence", "rule": "on_you_3",
		"line": "The next 3 hits on you miss", "fx": {"dodge_hits": 3}},
	"look_lively": {"name": "Look lively", "cls": "Drifter", "lane": "Moving on", "cost": 30, "cd": 18, "kind": "damage", "rule": "ready",
		"line": "+40% pace for 6 seconds", "fx": {"hit_mult": 1.4, "hit_s": 6.0}},
	"elbow_room": {"name": "Elbow room", "cls": "Drifter", "lane": "Moving on", "cost": 30, "cd": 18, "kind": "defence", "rule": "on_you_3",
		"line": "Everyone on you does 25% less damage to you and takes 15% more from you, for 8 seconds", "fx": {"less_in": 0.25, "less_in_s": 8.0, "exposed": 0.15, "exposed_s": 8.0}},
	"gone": {"name": "Gone", "cls": "Drifter", "lane": "Moving on", "cost": 60, "cd": 40, "kind": "defence", "rule": "under_half", "signature": true,
		"line": "Out of sight for 4 seconds: nothing can hit you. Your next shot does triple damage.", "fx": {"hidden_s": 4.0, "clears": [], "shot_mult": 3.0, "shot_s": 1.0}},
	"coin_toss": {"name": "Coin toss", "cls": "Drifter", "lane": "Luck", "cost": 20, "cd": 10, "kind": "damage", "rule": "ready",
		"line": "A 50% chance of double damage for 8 seconds", "fx": {"coin": 0.5, "hit_mult": 2.0, "hit_s": 8.0}},
	"close_shave": {"name": "Close shave", "cls": "Drifter", "lane": "Luck", "cost": 25, "cd": 15, "kind": "cleanse", "rule": "ailing",
		"line": "The next ailment that would land on you misses", "fx": {"close_shave": true}},
	"chancer": {"name": "Chancer", "cls": "Drifter", "lane": "Luck", "cost": 30, "cd": 20, "kind": "damage", "rule": "finisher",
		"line": "The next man you kill always drops something, at +50% loot quality", "fx": {"chancer": 0.5}},
	"jackpot": {"name": "Jackpot", "cls": "Drifter", "lane": "Luck", "cost": 60, "cd": 45, "kind": "damage", "rule": "opener", "signature": true,
		"line": "For 8 seconds, every kill takes 2 seconds off every cooldown", "fx": {"jackpot_s": 8.0, "jackpot_cut": 2.0}},
}

const FX := {
	"rule/linemans_bag.arc": 0.5, "rule/linemans_bag.skills": 1.2,     # the Lineman's Tool Bag (24 Oct): the arc at half, skills +20% on the shocked
	# node
	"node/bleed_more.med_time": 1.3,     # Blood up: Bleed does 40% more; your meds 30% slower
	"node/buyers_market.buy": 2.0,     # Buyer's market: The Fence pays double; buying costs double
	"node/buyers_market.sell": 2.0,     # Buyer's market: The Fence pays double; buying costs double
	"node/cap_transfusion": 2.0,     # Transfusion: Guard holds twice as much, and a med fills it to the top
	"node/early_doors": 2.0,     # Early doors: The first gang takes twice as long to come
	"node/frost_more.pace": 0.85,     # Cold hands: Frost does 40% more; pace −15%
	"node/hit_and_run.kill_pay": 1.5,     # Hit and run: Leaves as the first gang arrives, the loot kept; every kill pays 50% more
	"node/hoarder.capacity": 2,     # Hoarder: The pack carries double; −30% pace
	"node/hoarder.pace": 0.7,     # Hoarder: The pack carries double; −30% pace
	"node/light_fingers.cash": 0.8,     # Light fingers: Papers three times as often; tins −20%
	"node/light_fingers.papers": 3.0,     # Light fingers: Papers three times as often; tins −20%
	"node/loud.drop": 1.3,     # Loud: Gangs come sooner and one head bigger; +30% drops
	"node/loud.gang": 1,     # Loud: Gangs come sooner and one head bigger; +30% drops
	"node/never_there.search": 2.0,     # Never there: No gang ever comes; searching takes twice as long
	"node/one_at_a_time.pace": 0.75,     # One at a time: Only one of a gang can ever fire on you at once; pace −25%
	"node/overtime.guard": 50.0,     # Overtime: Guard holds 50% more; with Guard up, meds take half the time
	"node/pack_mule": 6,     # Pack horse: The pack carries six cells more
	"node/physical_more.pace": 0.85,     # Heavy: Physical does 40% more; pace −15%
	"node/second_wind": 2.0,     # Second wind: Rest on the Pitch twice as fast
	"node/salvage": 1.5,         # Salvage: scrapping at the Workshop gives half again (27 Oct: was a ditch's)
	"node/squared_up": 15.0,     # Squared up: Every gang, as they arrive: Guard of 15% of your max HP
	"node/stand": 2.0,     # Stand and fight: No leaving before the fight is won; the bonus for winning it is doubled
	"node/trapline.heads": 1,     # Trapline: Every gang arrives one head short, the first included
	"node/triage": 0.5,     # Triage: Meds take half the time
	"node/walking_wounded.damage_low": 40.0,     # Walking wounded: Under half HP: +40% damage; meds heal half
	"node/walking_wounded.heal": 0.5,     # Walking wounded: Under half HP: +40% damage; meds heal half
	# rule
	"rule/bookies_pencil.cash": 0.5,     # The Bookie's Pencil: Loot quality doubled; tins halved
	"rule/bookies_pencil.rarity": 2.0,     # The Bookie's Pencil: Loot quality doubled; tins halved
	"rule/issue_webbing": 2,     # Issue Webbing: Every pouch holds two
	"rule/ladle.med_heal": 0.0,     # The Dinner Lady's Ladle: Every kill is a tenth of your HP back; meds do nothing
	"rule/lollipop": 2.0,     # The Lollipop Lady's Sign: Stop: the first of every gang drops where it stands; gangs come half as often
	"rule/managers_coat": 1.5,     # The Manager's Coat: Tins half again; no notes - he doesn't take paper
	"rule/miners_lamp": 0.5,     # The Miner's Lamp: Searches take half as long
	"rule/paramedics_bumbag": 1.5,     # The Paramedic's Bum Bag: Meds heal half again; one is used for you under 40% HP
	"rule/plumbers_belt": 2.0,     # The Plumber's Belt: Burns, poison and bleeds on them build twice as deep; chills and shocks last twice as long
	"rule/postman": 1,     # The Postman's Bag: Every search finds one more
	"rule/sergeants_whistle.contact": 2,     # The Sergeant's Whistle: Two more on you at once; everything you do does 60% more
	"rule/the_float.capacity": 1.5,     # The Float: Pace +40% and the pack half again; you carry no meds
	"rule/the_float.pace": 1.4,     # The Float: Pace +40% and the pack half again; you carry no meds
	"rule/van_keys": 1.25,
	"rule/milkmans": 1.15,     # The Milkman's Gloves: pace +15% until the site is cleared (29 Oct)
	"rule/safecrackers": 0.85,     # The Safecracker's Gloves: reloads take no time; rate of fire −15% (29 Oct)     # The Van Keys: You drive: pace +25%
	"rule/wardens_hat.gang": 1,     # A Traffic Warden's Hat: Every gang arrives one short; every kill's notes doubled
	"rule/wardens_hat.notes": 2,     # A Traffic Warden's Hat: Every gang arrives one short; every kill's notes doubled
	# set
	"set/ambulance.heal": 2.0,     # The Ambulance's: meds heal double
	"set/army.contact": 1,     # The Army's: one fewer on you at once
	"set/bank.kill_cash": 2.0,     # The Bank's: tins from kills doubled
	# joint
	"joint/poacher_frost.heads": 1,     # Every gang arrives chilled, and one head short
	"joint/scrapper_fire.sell": 20.0,     # A kill while it burns always drops something; finds sell for 20% more
	# yard
	"yard/a_dog": 1,     # A dog: One more find every search
	"yard/annex": 100,     # Annex: A hundred more cells in the stash
	"yard/filing_cabinet": 1,     # Filing cabinet (19 Oct, Matt): a beaten signal's papers home, one more (3, not 2)
	"yard/another_unit": 50,     # Another unit: Fifty more cells in the stash
	"yard/beds": 0.5,     # Beds: Resting heals half an HP a second more
	"yard/champion": 20.0,     # Champion: Twenty per cent better finds
	"yard/contacts": 0.10,     # Contacts: The exchange keeps 10% either way, not 15% (28 Oct, the exchange; a draft)
	"yard/crows_nest": 1.2,     # Crow's nest: Every gang takes a fifth longer to arrive
	"yard/dealers_cut": 25.0,     # Dealer's cut: Everything sells for a quarter more
	"yard/fixer": 1.05,     # Fixer: Every trade at the exchange gets 5% more (28 Oct, the exchange; a draft)
	"yard/flares.heads": 1,     # Flares: Every gang arrives one head short
	"yard/gamblers_table": 0.5,     # Gambler's table: Every gamble costs half
	"yard/good_nose": 5.0,     # A good nose: Five per cent better finds
	"yard/guard_dog": 1.2,     # Guard dog: It hears them coming: every gang a fifth later
	"yard/haggling": 10.0,     # Haggling: Everything sells for a tenth more
	"yard/lock_up": 60,     # Lock-up: Sixty more cells in the stash
	"yard/long_range": 1,     # Long range: A site carries one more code
	"yard/lookout_post": 0.5,     # Lookout post: The first gang takes half as long again to arrive, on top
	"yard/lorry_watch": 2.0,     # Lorry watch: Kev's story papers come home twice as often
	"yard/med_lab": 1.25,     # Med lab: Every med heals a quarter more
	"yard/military_band": 0.5,     # Military band: Every code's reward - tins, XP, drops, quality - half again
	"yard/night_set": 0.5,     # Night set: Night's slower feet halved
	"yard/overbump": 2,     # Overbump: A bump raises an item six levels, not three
	"yard/jerry_can": 10.0,     # Jerry can: Max energy +10 (24 Oct, milestone 8: the Generator's away picks gone)
	"yard/dynamo": 0.5,     # Dynamo: Energy refills 0.5 more a second
	"yard/kickback": 5.0,     # Kickback: Every kill gives 5 energy
	"yard/flywheel": 5.0,     # Flywheel: Every skill's cooldown is 5% shorter (inside the 40% cap)
	"yard/pack": 2,     # The pack: Two more finds every search
	"yard/pedigree": 10.0,     # Pedigree: Ten per cent better finds
	"yard/rig_wiring": 4,     # Rig wiring: Four more pouches on the rig
	"yard/scanner": 0.75,     # Scanner: Every craft at the Radio a quarter cheaper
	"yard/second_dog": 0.85,     # Second dog: searches 15% quicker (18 Oct, Matt: its own effect, not A dog's again)
	"yard/shelf": 4,     # Shelf: Ten meds on the Clinic's shelf, not six
	"yard/shelving": 40,     # Shelving: Forty more cells in the stash
	"yard/shopfront": 3,     # Shopfront: Three more things on the Fence's shelf
	"yard/spotter": 0.5,     # Spotter: The first gang takes half as long again to arrive
	"yard/stall": 2,     # Stall: Two more things on the Fence's shelf
	"yard/stockroom": 6,     # Stockroom: Six more meds on the Clinic's shelf
	"yard/strip_for_parts": 2,     # Strip for parts: Scrapping gives twice the scrap
	"yard/strongroom": 0.5,     # Strongroom: Insuring a run costs half
	"yard/surgery": 0.5,     # Surgery: Treating a wound costs half
	"yard/theatre": 0.1,     # Theatre: Ten per cent more max HP
	"yard/third_socket": 1,     # Third socket: A third socket can be cut in a gun or armour
	"yard/tracker.charms": 2.0,     # Tracker: Papers and charms turn up twice as often
	"yard/tracker.papers": 2.0,     # Tracker: Papers and charms turn up twice as often
	"yard/tripwires": 1.1,     # Tripwires: Every gang takes a tenth longer to arrive
	"yard/ward": 1.0,     # Ward: Resting heals an HP a second more
	"yard/watch_rota": 1.2,     # Watch rota: on night runs, gangs 20% later (18 Oct, Matt: its own effect, not Tripwires' again)
	# yard_rank
	"yard_rank/clinic": 0.03,     # a rank of the Yard's clinic
	"yard_rank/fence": 2.0,     # a rank of the Yard's fence
	"yard_rank/generator": 2.0,     # a rank of the Yard's generator: max energy +2
	"yard_rank/kennel": 2.0,     # a rank of the Yard's kennel
	"yard_rank/lookout": 0.02,     # a rank of the Yard's lookout
	"yard_rank/radio": 0.05,     # a rank of the Yard's radio
	"yard_rank/stash": 20,     # a rank of the Yard's stash
	# atlas
	"atlas/after_dark": 1.5,     # After dark: Every site is Night, and Night's rarer finds half again
	"atlas/booster": 0.1,     # Booster: Every code's pay +10% a rank
	"atlas/bounties": 0.5,     # Bounties: The notes a head holds, half again a rank
	"atlas/deeper_pockets": 0.1,     # Deeper pockets: Searches 10% quicker a rank
	"atlas/early_word": 0.25,     # Early code: Call in a quarter cheaper a rank
	"atlas/easy_pickings": 0.1,     # Easy pickings: Drops +10% a rank
	"atlas/every_penny": 0.1,     # Every tin: Tins +10% a rank
	"atlas/full_strength": 2,     # Full strength: A head comes at full strength from depth 8, not 10
	"atlas/good_reception": 0.15,     # Good reception: Every craft at the Radio 15% cheaper a rank
	"atlas/heavy_crews.cash": 1.5,     # Heavy crews: One more on you at a time; kills pay half again in tins and XP
	"atlas/heavy_crews.contact": 1,     # Heavy crews: One more on you at a time; kills pay half again in tins and XP
	"atlas/heavy_crews.xp": 1.5,     # Heavy crews: One more on you at a time; kills pay half again in tins and XP
	"atlas/lorrys_route": 1,     # The lorry's route: the decoder's band a level wider at the top
	"atlas/lie_of_the_land": 3,     # The lie of the land: a signal rolls at worst this many levels under the reach (18 Oct)
	"atlas/open_ground": 1,     # Open ground: One fewer on you at a time
	"atlas/picked_over.base": 0.33,     # a site's own things: the share of finds before the map's Picked over
	"atlas/picked_over": 0.1667,     # Picked over: A site's own things turn up more: a third of finds, then half, then two-thirds
	"atlas/quiet_roads": 0.1,     # Quiet roads: Gangs come 10% later a rank
	"atlas/short_cuts": 0.05,     # Short cuts: Pace +5% a rank
	"atlas/their_own_kit": 0.1,     # Their own kit: A kill drops something 10% more often a rank
	"atlas/tip_offs": 0.05,     # Tip-offs: Rarer finds: +5% loot quality a rank
	"atlas/wages": 0.1,     # Wages: XP +10% a rank
	"atlas/worn_in": 0.5,     # Worn in: A picked-over site's crates come back half again as fast a rank
	# the second pass: figures in a statement under an effect, and a ternary with more to its condition
	"joint/doorman_bleed": 0.8,     # Every shell and swing opens a bleed; bleeding gangs do 20% less to you
	"joint/doorman_physical": 0.75,     # Every shell and swing staggers: the gangs on you fire 25% slower
	"joint/drifter_fire": 1.25,     # Your bursts ignite: burning gangs take 25% more from SMGs
	"joint/paramedic_frost.heal": 1.2,     # Chilled gangs do 30% less to you; meds heal 20% more while one is
	"joint/paramedic_frost.taken": 0.7,     # Chilled gangs do 30% less to you; meds heal 20% more while one is
	"joint/poacher_frost.chill_s": 2.0,     # Every gang arrives chilled, and one head short
	"node/not_today": 0.6,     # Not today: under a quarter HP, 40% less in (24 Oct: Code blue took its killing hit)
	"node/not_today.under": 0.25,
	"node/bodyline": 0.5,     # Bodyline: With three on you, you take half the damage
	"node/cap_bleed_out": 1.5,     # Bleed out (capstone): bleed builds half again
	"node/cap_flattened": 2.0,     # Flattened: A kill with the plain staggers the next gang: they fire at half for two seconds
	"node/cap_flattened.cut": 0.5,     # and by how much: the next of them at half (25 Oct: one man's share, not the gang's)
	"rule/arsonists_rig.blast": 80.0,     # the Arsonist's Rig's blast, grown with the fight as a grenade's (25 Oct, the review)
	"node/fire_pct.notable_s": 2.0,     # Lit, Dosed, Opened up: their dot lasts twice as long - fire, poison and bleed alike; named under fire_pct for the table's check (25 Oct, the review)
	"rule/issued_seal.burn": 2.0,     # the issued seal: your burns count double
	"rule/issued_rifle.kill": 1.5,     # the issued rifle: a kill pays half again
	"rule/issued_plate.cut": 0.8,     # the issued plate: the order's and the County's people hit you at this
	"node/cap_held": 0.1,     # Held: No second of their fire takes more than a tenth of you
	"node/cap_iron": 0.1,     # Iron: Under half HP, every kill heals a tenth of you
	"node/cap_jerry": 1.5,     # Jerry-rigged: Something improvised hits half again as hard
	"node/cap_shatter": 2.0,     # Shatter (capstone): a chilled target takes double from the physical
	"node/cap_the_lot": 2.0,     # The lot: A pack that comes home full pays double tins
	"node/frost_freeze": 0.5,     # Frozen solid: Chilled gangs fire at 15%; your frost does half damage
	"node/loud.patrol": 0.6,     # Loud: Gangs come sooner and one head bigger; +30% drops
	"node/overwatch": 2,     # Chokepoints: Only two of a gang can fire on you at once, not three
	"node/poison_more.quantity": 0.2,     # Rat's share: Poison does 40% more; loot quantity −20%
	"node/poison_stacks": 15,     # Builds: Poison stacks to fifteen, not five
	"node/quiet_feet": 30.0,     # Quiet feet: The next gang comes every 30 seconds, not 20
	"node/shock_more.armour": 0.8,     # Earthed: Shock does 40% more; armour −20%
	"node/thick_skinned.armour_per_pct": 10.0,     # Thick-skinned: every 10 armour past 200 is +1% physical
	"rule/branch_pistol": 2.0,     # The Branch Pistol: Under half HP the secondary fires twice as fast
	"rule/butchers_steel": 2.0,     # The Butcher's Steel: Bleed does double, and a bleed carries to the next of them
	"rule/doormans": 0.75,     # The Doorman's Jacket: With three on you, take a quarter less
	"rule/drivers_log": 2,     # The Lorry Driver's Log: Notes found doubled; insurance is free
	"rule/grandads": 2.0,     # Grandad's Shotgun: The first of every gang takes triple
	"rule/gritters_keys": 2.0,     # The Gritter's Keys: A chill holds as long as you fire; chilled, they take double frost
	"rule/jump_leads": 0.33,     # Jump Leads: A third of your damage as shock; shock on one of them is shock on all of them
	"rule/ladle.kill_heal": 0.1,
	"rule/vans_spare": 2.0 / 3.0,     # The Van's Spare: the secondary at two thirds behind the primary, not a third
	"rule/keepers_gun": 0.03,     # The Keeper's Twelve-Bore: every kill is 3% of your HP back
	"rule/keepers_wax": 0.5,     # The Keeper's Wax Jacket: poison and bleed on you do half     # The Dinner Lady's Ladle: Every kill is a tenth of your HP back; meds do nothing
	"rule/managers_pen": 2,     # The Manager's Pen: Notes come in twos: every note found is two
	"rule/rat_mans_overalls": 0.5,     # The Rat Man's Overalls: Poison stacks without end and ticks twice as fast
	"rule/sergeants_whistle.damage": 1.6,     # The Sergeant's Whistle: Two more on you at once; everything you do does 60% more
	"rule/substation_key": 0.6,     # The Substation Key: Shock on one of them is shock on all; shocked, they take 60% more
	"rule/tester": 0.5,     # The Electrician's Tester: Shocked stays shocked until they're down; shock does half
	"set/army.damage": 1.3,     # The Army's: everything you do does 30% more
	"set/carpet.bleed_s": 2.0,     # The Carpet Man's: bleeds last twice as long
	"yard/arc_lamps": 1.1,     # Arc lamps: Fire and shock do a tenth more
	"yard/arms_dealer": 0.33,     # Arms dealer: The shelf rolls at your deepest site's level
	"yard/cheap_parts": 0.75,     # Cheap parts: Every job at the Bench costs a quarter less
	"yard/dead_air": 1.25,     # Dead air: At Night the gangs come a quarter later
	"atlas/held_frequency": 0.5,     # Held frequency: Hold at half price (21 Oct)
	"yard/forecast": 1.2,     # The forecast: A run under rain or fog brings a fifth more tins home
	"yard/glasses": 60,     # Glasses: The odds shown are read from sixty dry runs, not twenty-four
	"yard/range_cards": 0.5,     # Range cards: The first shot on every gang does half again
	"yard/ratter": 1.1,     # Ratter: Poison and bleed do 10% more damage
	"yard/steady_hands": 2.0,     # Steady hands: re-rolling values, twice the chance an affix goes up a tier
	"yard/weather_set": 0.5,     # Weather set: Rain and fog bite half as hard
}


## Sets: whose gear it was. A piece is a fixed base with its own name and a
## couple of fixed affixes, rolled like a unique, drawn in the set's own
## tint; the bonuses come at two pieces worn and at the full set - stats,
## added to what's worn, and a rule at the top. Found loose from `depth` on.
const SET_DROP := 0.004            # a share of finds a depth past the first
const SETS := [
	{"name": "The Fire Crew's", "depth": 9, "words": "Breathing kit and a tunic from the station that answered the last call.",
		"pieces": [
			{"name": "Station tunic", "slot": "Armour", "base": "Fireman's tunic", "affixes": [{"stat": "armour", "value": 20}, {"stat": "hp", "value": 20}]},
			{"name": "Station helmet", "slot": "Helmet", "base": "Station helmet, visored", "affixes": [{"stat": "armour", "value": 12}, {"stat": "hp", "value": 15}, {"stat": "fire_res", "value": 15}]},     # HP as a helmet set piece carries it (Matt, 27 Oct)
			{"name": "Breathing set", "slot": "Rig", "base": "Medic's harness", "affixes": [{"stat": "med_cap", "value": 2}, {"stat": "poison_res", "value": 25}]},
		],
		"bonuses": {2: {"stats": {"fire_res": 40}, "words": "Fire resist +40%"},
			3: {"stats": {"all_res": 15, "regen": 0.5}, "words": "All resists +15%, +0.5 HP a second"}}},
	{"name": "The Council's", "depth": 5, "words": "Parks, highways, pest control: the Council's gear, orange and stamped.",
		"pieces": [
			{"name": "Council hi-vis", "slot": "Armour", "base": "Stab vest", "affixes": [{"stat": "armour", "value": 10}, {"stat": "hp", "value": 12}]},
			{"name": "Council hard hat", "slot": "Helmet", "base": "Hard hat", "affixes": [{"stat": "armour", "value": 8}, {"stat": "search_pct", "value": 8}]},
			{"name": "Council rucksack", "slot": "Backpack", "base": "School bag", "affixes": [{"stat": "capacity", "value": 4}, {"stat": "loot_pct", "value": 10}]},
			{"name": "Council lanyard", "slot": "Charm", "base": "Lucky penny", "affixes": [{"stat": "notes_pct", "value": 15}, {"stat": "rarity_pct", "value": 6}]},
		],
		"bonuses": {2: {"stats": {"all_res": 20}, "words": "All resists +20%"}, 3: {"stats": {"regen": 1.0}, "words": "+1 HP a second"},
			4: {"stats": {"search_pct": 30, "notes_pct": 50}, "rule": "council", "words": "Searches 30% quicker, notes +50%, every locked crate opens"}}},
	{"name": "The Ambulance's", "depth": 8, "words": "A crew's kit from the one ambulance that kept going.",
		"pieces": [
			{"name": "Ambulance rig", "slot": "Rig", "base": "Paramedic's rig", "affixes": [{"stat": "med_cap", "value": 2}, {"stat": "med_speed_pct", "value": 15}]},
			{"name": "Green overalls", "slot": "Armour", "base": "Padded jacket", "affixes": [{"stat": "hp", "value": 25}, {"stat": "regen", "value": 0.5}]},
			{"name": "Crew helmet", "slot": "Helmet", "base": "Cycle helmet", "affixes": [{"stat": "armour", "value": 10}, {"stat": "med_speed_pct", "value": 10}]},
		],
		"bonuses": {2: {"stats": {"med_speed_pct": 50}, "words": "Meds 50% quicker"},
			3: {"rule": "ambulance", "words": "The first med on a run isn't used up; meds heal double"}}},
	{"name": "The Bank's", "depth": 10, "words": "Staff, they called themselves. The blazers say so.",
		"pieces": [
			{"name": "Branch blazer", "slot": "Armour", "base": "Ballistic vest", "affixes": [{"stat": "armour", "value": 20}, {"stat": "hp", "value": 25}, {"stat": "cash_pct", "value": 15}]},     # HP as the body's pieces carry it (Matt, 27 Oct: live_load came in at 750 HP)
			{"name": "Cashier's pen", "slot": "Charm", "base": "Bank's own pen", "affixes": [{"stat": "cash_pct", "value": 20}, {"stat": "rarity_pct", "value": 8}]},
			{"name": "Branch holdall", "slot": "Backpack", "base": "Hiking pack", "affixes": [{"stat": "capacity", "value": 6}, {"stat": "hp", "value": 10}, {"stat": "cash_per_cell", "value": 4}]},
		],
		"bonuses": {2: {"stats": {"cash_pct": 30}, "words": "Tins +30%"},
			3: {"stats": {"sell_pct": 25}, "rule": "bank", "words": "Tins from kills doubled; the Fence pays 25% more"}}},
	{"name": "The Army's", "depth": 15, "words": "Issue kit, the lot of it, off the one lorry that got through.",
		"pieces": [
			{"name": "Issue helmet", "slot": "Helmet", "base": "Composite helmet", "affixes": [{"stat": "armour", "value": 20}, {"stat": "hp", "value": 15}]},
			{"name": "Issue carrier", "slot": "Armour", "base": "Full plate carrier", "affixes": [{"stat": "armour", "value": 30}, {"stat": "all_res", "value": 8}]},
			{"name": "Issue bergen", "slot": "Backpack", "base": "Bergen", "affixes": [{"stat": "capacity", "value": 8}, {"stat": "hp", "value": 10}]},
			{"name": "Issue rifle", "slot": "Primary", "base": "Marksman rifle", "affixes": [{"stat": "damage_pct", "value": 15}, {"stat": "first_pct", "value": 20}]},
		],
		"bonuses": {2: {"stats": {"armour_pct": 15}, "words": "Armour +15%"}, 3: {"stats": {"first_pct": 40}, "words": "+40% damage to the first of each gang"},
			4: {"rule": "army", "words": "Damage +30%; one fewer on you at once"}}},
	{"name": "The Carpet Man's", "depth": 5, "words": "A fitter's kit: the knife, the knee pads.",
		"pieces": [
			{"name": "Carpet knife", "slot": "Secondary", "base": "Knife", "affixes": [{"stat": "bleed_pct", "value": 25}, {"stat": "attack_pct", "value": 10}]},
			{"name": "Fitter's knee pads", "slot": "Armour", "base": "Padded jacket", "affixes": [{"stat": "armour", "value": 12}, {"stat": "bleed_res", "value": 20}]},
		],
		"bonuses": {2: {"stats": {"conv_bleed_pct": 30}, "rule": "carpet", "words": "30% of damage becomes bleed; bleeds last twice as long"}}},
]

## Workshop levels: what each opens, and what it costs to reach.
## (The Bench's levels went with the Yard's lanes, 9 Oct: every mount, every job, from the start.)

## Rarity (the pass, Matt, 6 Oct): the affixes an item rolls AND the best tier any of them can be -
## "common can have 1 and it can only ever roll tier 1 affix and so on", five rarities to the five
## affix tiers, so an Epic nail gun is four affixes up to T4 on a tier-1 base, a stash gun that carries
## a levelling build. `tier` is the cap; the item level sets a floor under it (TIER_FLOOR). The share
## of drops by weight, the value multiple. Uniques sit at the top index, sets at Rare.
const RARITIES := [
	{"name": "Common", "affixes": 1, "tier": 1, "weight": 50, "value": 1.0},
	{"name": "Uncommon", "affixes": 2, "tier": 2, "weight": 30, "value": 1.8},
	{"name": "Rare", "affixes": 3, "tier": 3, "weight": 13, "value": 3.5},
	{"name": "Epic", "affixes": 4, "tier": 4, "weight": 6, "value": 6.0},
	{"name": "Legendary", "affixes": 5, "tier": 5, "weight": 1, "value": 10.0},
]
const RARITY_SHORT := ["Com", "Unc", "Rare", "Epic", "Leg"]

## Affixes: a stat and its roll range per tier. "pct" ones are percentages of
## the whole operator's figure; the rest add to it. `slots` says which items
## can carry it.
## Affixes. `min`..`max` is the whole span, T1 (the worst fifth) to T5 (the
## best) - tiers count up like the bases' do; which tiers an item can roll
## comes from its level (its base's tier plus the depth it dropped at:
## `Items.tier_cap`). `weight` is its share of a roll (1 if absent).
const AFFIX_TIERS := 5
const TIER_CAP := [0, 3, 6, 10, 15]  # the item level that opens T1, T2, T3, T4, T5: the old rule, a fallback in roll_tier only; the cap is the rarity's, on a drop and at the Bench
const TIER_FLOOR := [0, 6, 10, 14, 99]  # the item level from which an affix rolls no lower than T1, T2, T3, T4 (T5 never a floor): deep finds roll no T1s
const TIER_WEIGHT := [8.0, 5.0, 3.0, 2.0, 1.0]  # T1 .. T5: the better, the rarer
const AFFIXES := [
	{"stat": "damage_pct", "label": "damage", "short": "dmg", "min": 4, "max": 24, "slots": ["Primary", "Secondary"]},
	# the body: regen, life on kill, armour as a share, less from a crowd
	{"stat": "regen", "label": "HP a second", "short": "HP/s", "min": 2, "max": 10, "div": 10, "slots": ["Armour", "Helmet", "Charm"], "flat": true},     # tenths (the pass, 20 Oct): T1 0.2 to T5 0.9-1.0 HP/s, the item level's edge on top
	{"stat": "life_per_kill", "label": "HP a kill", "short": "HP/kill", "min": 2, "max": 12, "slots": ["Primary", "Secondary", "Helmet"], "flat": true},
	# armour % short "armour", not "arm": that's the flat armour's, and "5% arm" by "3 arm" read the same (13 Oct)
	{"stat": "armour_pct", "label": "armour", "short": "armour", "min": 3, "max": 18, "slots": ["Armour", "Helmet"]},
	{"stat": "crowd_less_pct", "label": "less damage with three or more on you", "short": "less/crowd", "min": 4, "max": 16, "slots": ["Armour"]},
	# the guns: rate of fire
	{"stat": "attack_pct", "label": "rate of fire", "short": "RoF", "min": 3, "max": 15, "slots": ["Primary", "Secondary", "Gloves"]},
	{"stat": "reload_pct", "label": "quicker reloads", "short": "reload", "min": 10, "max": 40, "slots": ["Gloves"]},     # magazines (28 Oct): draft; the gloves' alone (29 Oct)
	# the carry: pouches, meds, searches, gangs later, notes
	{"stat": "med_cap", "label": "pouch", "short": "pouch", "min": 1, "max": 3, "slots": ["Rig"], "flat": true},
	{"stat": "med_speed_pct", "label": "quicker meds", "short": "med spd", "min": 5, "max": 30, "slots": ["Rig", "Helmet", "Gloves"]},
	{"stat": "search_pct", "label": "quicker searches", "short": "search", "min": 4, "max": 20, "slots": ["Backpack", "Helmet", "Gloves"]},
	{"stat": "patrol_pct", "label": "gangs later", "short": "gangs later", "min": 4, "max": 18, "slots": ["Helmet", "Charm"]},
	{"stat": "notes_pct", "label": "notes", "short": "notes", "min": 5, "max": 25, "slots": ["Charm", "Backpack"]},
	# the types: increased a type, a share of the hit as a type, resists
	{"stat": "fire_pct", "label": "fire damage", "short": "fire", "min": 6, "max": 30, "slots": ["Primary", "Secondary", "Charm"]},
	{"stat": "frost_pct", "label": "frost damage", "short": "frost", "min": 6, "max": 30, "slots": ["Primary", "Secondary", "Charm"]},
	{"stat": "poison_pct", "label": "poison damage", "short": "poison", "min": 6, "max": 30, "slots": ["Primary", "Secondary", "Charm"]},
	{"stat": "shock_pct", "label": "shock damage", "short": "shock", "min": 6, "max": 30, "slots": ["Primary", "Secondary", "Charm"]},
	{"stat": "bleed_pct", "label": "bleed damage", "short": "bleed", "min": 6, "max": 30, "slots": ["Primary", "Secondary", "Charm"]},
	{"stat": "physical_pct", "label": "physical damage", "short": "phys", "min": 6, "max": 30, "slots": ["Primary", "Secondary"]},
	{"stat": "conv_fire_pct", "label": "of damage as fire", "short": "as fire", "min": 5, "max": 25, "slots": ["Primary", "Secondary"], "weight": 0.5},
	{"stat": "conv_frost_pct", "label": "of damage as frost", "short": "as frost", "min": 5, "max": 25, "slots": ["Primary", "Secondary"], "weight": 0.5},
	{"stat": "conv_poison_pct", "label": "of damage as poison", "short": "as poison", "min": 5, "max": 25, "slots": ["Primary", "Secondary"], "weight": 0.5},
	{"stat": "conv_shock_pct", "label": "of damage as shock", "short": "as shock", "min": 5, "max": 25, "slots": ["Primary", "Secondary"], "weight": 0.5},
	{"stat": "conv_bleed_pct", "label": "of damage as bleed", "short": "as bleed", "min": 5, "max": 25, "slots": ["Primary", "Secondary"], "weight": 0.5},
	{"stat": "fire_res", "label": "fire resist", "short": "fire res", "min": 5, "max": 35, "slots": ["Armour", "Helmet", "Charm", "Rig"]},
	{"stat": "frost_res", "label": "frost resist", "short": "frost res", "min": 5, "max": 35, "slots": ["Armour", "Helmet", "Charm", "Rig"]},
	{"stat": "poison_res", "label": "poison resist", "short": "poison res", "min": 5, "max": 35, "slots": ["Armour", "Helmet", "Charm", "Rig"]},
	{"stat": "shock_res", "label": "shock resist", "short": "shock res", "min": 5, "max": 35, "slots": ["Armour", "Helmet", "Charm", "Rig"]},
	{"stat": "bleed_res", "label": "bleed resist", "short": "bleed res", "min": 5, "max": 35, "slots": ["Armour", "Helmet", "Charm", "Rig"]},
	{"stat": "all_res", "label": "all resists", "short": "all res", "min": 3, "max": 15, "slots": ["Armour", "Helmet", "Charm", "Rig"], "weight": 0.3},
	# -proofed (12 Oct, over the cap): an element's resist and its damage on one line, the stacker's line
	{"stat": "fire_proofed", "label": "fire resist and fire damage", "short": "fire res & dmg", "min": 5, "max": 20, "slots": ["Armour", "Helmet"], "weight": 0.4},
	{"stat": "frost_proofed", "label": "frost resist and frost damage", "short": "frost res & dmg", "min": 5, "max": 20, "slots": ["Armour", "Helmet"], "weight": 0.4},
	{"stat": "poison_proofed", "label": "poison resist and poison damage", "short": "poison res & dmg", "min": 5, "max": 20, "slots": ["Armour", "Helmet"], "weight": 0.4},
	{"stat": "shock_proofed", "label": "shock resist and shock damage", "short": "shock res & dmg", "min": 5, "max": 20, "slots": ["Armour", "Helmet"], "weight": 0.4},
	{"stat": "bleed_proofed", "label": "bleed resist and bleed damage", "short": "bleed res & dmg", "min": 5, "max": 20, "slots": ["Armour", "Helmet"], "weight": 0.4},
	{"stat": "dot_pct", "label": "burn, poison and bleed damage", "short": "damage over time", "min": 8, "max": 40, "slots": ["Primary", "Secondary", "Charm"], "weight": 0.6},
	{"stat": "armour", "label": "armour", "short": "arm", "min": 3, "max": 24, "slots": ["Helmet", "Armour", "Rig"], "flat": true},
	{"stat": "hp", "label": "max HP", "short": "HP", "min": 5, "max": 40, "slots": ["Helmet", "Armour", "Rig", "Backpack"], "flat": true},
	{"stat": "armour", "label": "armour", "short": "arm", "min": 1, "max": 6, "slots": ["Gloves"], "flat": true, "weight": 0.6},     # the gloves' small armour (29 Oct, §4: "armour (small)")
	{"stat": "loot_pct", "label": "loot quantity", "short": "quantity", "min": 5, "max": 30, "slots": ["Rig", "Backpack", "Helmet"]},
	{"stat": "capacity", "label": "pack cells", "short": "cells", "min": 1, "max": 6, "slots": ["Backpack"], "flat": true},
	{"stat": "speed_pct", "label": "pace", "short": "pace", "min": 3, "max": 15, "slots": ["Armour", "Gloves"]},     # off the guns (29 Oct)
	{"stat": "heal_pct", "label": "healing", "short": "heal", "min": 10, "max": 40, "slots": ["Medical"]},
	# Guard (12 Oct): anyone's, a little
	{"stat": "overflow_pct", "label": "of its overheal as Guard", "short": "overflow", "min": 50, "max": 100, "slots": ["Medical"], "weight": 0.5},
	# the Clinic's rolled meds (28 Oct, docs/design/meds_ammo_clinic.md: "heals more, works faster, a cure built in, a
	# beat of Guard"): heals more is heal_pct; the rest are a med's own, read off it as it's used - drafts
	{"stat": "med_fast_pct", "label": "quicker to use", "short": "quicker", "min": 10, "max": 40, "slots": ["Medical"]},
	{"stat": "med_guard_pct", "label": "of max HP as Guard when it's done", "short": "Guard", "min": 4, "max": 15, "slots": ["Medical"], "weight": 0.6},
	{"stat": "cure_bleed", "label": "Stops a bleed too", "short": "stops bleed", "min": 1, "max": 1, "slots": ["Medical"], "weight": 0.2, "flag": true},
	{"stat": "cure_fire", "label": "Stops burns too", "short": "stops burns", "min": 1, "max": 1, "slots": ["Medical"], "weight": 0.2, "flag": true},
	{"stat": "cure_poison", "label": "Stops poison too", "short": "stops poison", "min": 1, "max": 1, "slots": ["Medical"], "weight": 0.2, "flag": true},
	{"stat": "cure_frost", "label": "Stops a chill too", "short": "stops chill", "min": 1, "max": 1, "slots": ["Medical"], "weight": 0.2, "flag": true},
	{"stat": "cure_shock", "label": "Stops a shock too", "short": "stops shock", "min": 1, "max": 1, "slots": ["Medical"], "weight": 0.2, "flag": true},
	{"stat": "guard_gang", "label": "of max HP as Guard as each gang arrives", "short": "guard/gang", "min": 2, "max": 8, "slots": ["Armour", "Helmet"], "weight": 0.5},
	{"stat": "guard_pct", "label": "Guard cap", "short": "guard", "min": 10, "max": 50, "slots": ["Rig", "Armour"], "weight": 0.5},
	# the rig's swap (BUILD46-R, 2 Nov, Matt's call: a rig affix): a gun with a second loaded magazine swaps with no reload,
	# the spent one refilled from the pack's box as it fires, at a hand refill's pace (Sim.hot_swap). On or off. `tier_w`:
	# its weight by the rig's base tier, 1 to 9 - likelier on the better rigs (drafts)
	{"stat": "hot_swap", "label": "No reload pause: a spare magazine swaps in while the spent one refills", "short": "No reload pause", "min": 1, "max": 1, "slots": ["Rig"], "flag": true,
		"weight": 0.4, "tier_w": [0.08, 0.12, 0.18, 0.25, 0.32, 0.4, 0.5, 0.6, 0.7]},
	# the skills' (24 Oct, milestone 8): "8% shorter cooldowns" (CDR_CAP the most), "+8% energy gain", "+10 max energy"
	{"stat": "cdr_pct", "label": "shorter cooldowns", "short": "cooldowns", "min": 2, "max": 8, "slots": ["Helmet", "Armour", "Gloves", "Rig", "Backpack", "Charm"], "weight": 0.5},
	{"stat": "energy_regen_pct", "label": "energy gain", "short": "energy", "min": 3, "max": 12, "slots": ["Helmet", "Armour", "Gloves", "Rig", "Backpack", "Charm"], "weight": 0.5},
	{"stat": "energy_max", "label": "max energy", "short": "max energy", "min": 3, "max": 12, "slots": ["Helmet", "Armour", "Rig", "Backpack", "Charm"], "flat": true, "weight": 0.5},
	{"stat": "damage_pct", "label": "damage", "short": "dmg", "min": 2, "max": 6, "slots": ["Attachment"]},
	# conditional: they pay only in a situation, which is where builds come from
	{"stat": "damage_low_pct", "label": "damage under half HP", "short": "dmg <½HP", "min": 8, "max": 20, "slots": ["Primary", "Secondary"]},
	{"stat": "first_lot_pct", "label": "damage before the clear", "short": "dmg pre-clear", "min": 10, "max": 25, "slots": ["Primary"]},
	{"stat": "loot_per_lot", "label": "loot quantity a gang seen off", "short": "loot/gang", "min": 3, "max": 8, "slots": ["Backpack", "Rig"]},
	{"stat": "armour_per_med", "label": "armour a med carried", "short": "arm/med", "min": 2, "max": 5, "slots": ["Rig", "Armour"]},
	{"stat": "cash_per_kill", "label": "tins a kill", "short": "tins/kill", "min": 2, "max": 6, "slots": ["Helmet", "Backpack"]},
	# keyed off the build: they scale with a choice, not a number
	{"stat": "damage_per_att", "label": "damage an attachment fitted", "short": "dmg/part", "min": 2, "max": 4, "slots": ["Primary"]},
	{"stat": "armour_per_free", "label": "armour an empty pack cell", "short": "arm/cell", "min": 1, "max": 3, "slots": ["Armour", "Backpack"]},
	{"stat": "loot_per_med", "label": "loot quantity a med carried", "short": "loot/med", "min": 2, "max": 5, "slots": ["Rig", "Helmet"]},
	{"stat": "cash_per_cell", "label": "tins a filled pack cell, on the way out", "short": "tins/cell", "min": 3, "max": 8, "slots": ["Backpack", "Rig"]},
	{"stat": "speed_pct", "label": "pace", "short": "pace", "min": 2, "max": 5, "slots": ["Attachment"]},
	# the charm's: loot quality is rarer finds; loot quantity is more of them
	{"stat": "rarity_pct", "label": "loot quality", "short": "quality", "min": 5, "max": 15, "slots": ["Charm", "Helmet", "Backpack"]},
	{"stat": "cash_pct", "label": "tins", "short": "tins", "min": 5, "max": 15, "slots": ["Charm"]},
	{"stat": "loot_pct", "label": "loot quantity", "short": "quantity", "min": 5, "max": 12, "slots": ["Charm"]},
]
## Stats a unique or a set piece carries that no piece rolls (30 Oct, the review's I5: a card read "+20% first_pct"):
## their words for a card, as an affix's label and short.
const AFFIX_SHOWN := {
	"first_pct": {"label": "damage to the first of each gang", "short": "dmg to first"},
}

## The one zone, in three tiers. `pool` is enemy count; each has `hp` and
## deals `dps` while alive. Drop chance a kill; drops roll from tiers up to
## `loot_tier`. XP a kill. The depot clear is the slice's win.
## Two zones, three tiers each; a tier's index is global (0–5). The Docks open
## when the depot is cleared. Its hostiles are organised - bigger pools, more
## fire - and its caches pay in cash more than gear; its tier-3 loot is where
## the newest bases live.
## Three zones, three sites each. A zone opens when the one before it is
## complete: its three sites cleared and its boss beaten. All three complete
## is the campaign; then the depth ladder and the radio's call-in open.
## The Outskirts (12 Oct): a zone before the Estate - the allotments, the garden centre, the farm - with no crew and no
## head: the first runs, before the streets. Every site's index moved up three with it, and every zone's up one.
const ZONES := [
	{"name": "The Outskirts", "words": "The Allotments, the Garden Centre, Top Farm – the edge of it, where it started.", "tiers": [0, 1, 2]},
	{"name": "The Estate", "words": "Ransacked Streets, the Parade, the Retail Park.", "tiers": [3, 4, 5]},
	{"name": "The Town", "words": "The Pleasure Park, the Shopping Centre, the Bank – held by a crew.", "tiers": [6, 7, 8]},
	{"name": "The City", "words": "The Services on the motorway, the Hospital, the Barracks the lorries never reached.", "tiers": [9, 10, 11]},
]
const OUTSKIRTS_SITES := 3         # the sites before the Streets: a site's level is its index past these and its depth (Streets, depth 1: level 1)
## A site: its campaign numbers (depth 1), its shape at the endgame (how the
## depth curve is bent for it - many and thin, or few and hard; gangs often
## or rarely; cash-heavy), and its drops: which slots its finds favour, a gun
## type it leans to, and the bases found there and nowhere else.
const TIERS := [
	# the Outskirts (12 Oct): gentler than the Streets, no crew; finds at tier 1
	{"name": "The Allotments", "zone": 0, "pool": 4, "hp": 240.0, "dps": 0.35, "drop": 0.35, "loot_tier": 1, "xp": 3, "cash": 3,     # E1-2 (17 Oct, Matt: the Outskirts pointless, the Parade at level 1-2): 120/0.2/1; E1 300/0.4 put the Gamekeeper at 0.8 h
		"shape": {"pool": 14, "hp": 0.6, "dps": 0.7, "patrol": 0.9, "cash": 0.7},
		"drops": {"slots": {"Primary": 2, "Secondary": 3, "Helmet": 1, "Armour": 1, "Rig": 1, "Gloves": 1, "Backpack": 2}, "type": "melee", "only": ["A seed order", "An allotment waiting list"]}},
	{"name": "The Garden Centre", "zone": 0, "pool": 5, "hp": 290.0, "dps": 0.42, "drop": 0.4, "loot_tier": 1, "xp": 3, "cash": 4,     # E1-2: 150/0.25/1
		"shape": {"pool": 13, "hp": 0.7, "dps": 0.8, "patrol": 1.0, "cash": 0.9, "med": 1.5},
		"drops": {"slots": {"Primary": 1, "Secondary": 2, "Helmet": 2, "Armour": 1, "Rig": 2, "Gloves": 1, "Backpack": 2}, "type": "improvised", "only": ["A loyalty card"]}},
	{"name": "Top Farm", "zone": 0, "pool": 6, "hp": 330.0, "dps": 0.5, "drop": 0.4, "loot_tier": 1, "xp": 6, "cash": 5,     # E1-2: 170/0.3/2
		"shape": {"pool": 12, "hp": 0.8, "dps": 0.8, "patrol": 1.1, "cash": 1.0, "ammo": 1.5},
		"drops": {"slots": {"Primary": 3, "Secondary": 1, "Helmet": 1, "Armour": 2, "Rig": 1, "Gloves": 1, "Backpack": 1}, "type": "shotgun", "only": ["A milk quota letter"]}},
	{"name": "Ransacked Streets", "zone": 1, "pool": 6, "hp": 330.0, "dps": 0.5, "drop": 0.4, "loot_tier": 2, "xp": 5, "cash": 6,     # E1-2: 200/0.4/2
		"shape": {"pool": 14, "hp": 0.7, "dps": 0.8, "patrol": 0.8, "cash": 0.9},
		"drops": {"slots": {"Primary": 2, "Secondary": 3, "Helmet": 2, "Armour": 1, "Rig": 1, "Gloves": 1, "Backpack": 1}, "type": "improvised", "only": ["Pipe shotgun", "Carrier bags"]}},
	{"name": "The Parade", "zone": 1, "pool": 10, "hp": 300.0,     # 280 to 300 (29 Oct: the Estate's T2 its gear now, the Streets' T2 brought to it - never easier than the Streets' first clear)
		 "dps": 0.35, "drop": 0.4, "loot_tier": 2,     # 2 (29 Oct, one tier a zone); was 2 to 3 (the pass, 13 Oct): with the Fence and the Workshop shut till the heads, tier-2 kit stalled a third of the plain reads under the Retail Park for hours
		 "xp": 5, "cash": 9,     # E1: 3
		"shape": {"pool": 12, "hp": 0.9, "dps": 0.8, "patrol": 1.0, "cash": 1.2},
		"drops": {"slots": {"Primary": 1, "Secondary": 3, "Helmet": 1, "Armour": 1, "Rig": 2, "Gloves": 1, "Backpack": 2}, "type": "pistol", "only": ["Sawn-off", "Holdall"]}},
	{"name": "The Retail Park", "zone": 1, "pool": 14, "hp": 315.0, "dps": 0.61, "drop": 0.45, "loot_tier": 2, "xp": 10, "cash": 14,     # E1-2: 6
		"shape": {"pool": 12, "hp": 1.0, "dps": 1.0, "patrol": 1.0, "cash": 1.0, "att": 2.0},
		"drops": {"slots": {"Primary": 3, "Secondary": 1, "Helmet": 1, "Armour": 2, "Rig": 1, "Gloves": 1, "Backpack": 1}, "type": "improvised", "only": ["Garage-built rifle", "Webbing sling", "Wire stock"]}},
	{"name": "The Pleasure Park", "zone": 2, "pool": 12, "hp": 520.0,     # ×0.75 to ×0.47 of 1100, its fire ×0.875 to ×0.47 (the fix round, 29 Oct: the Town's door on the Estate's T2 kit, the gate reads)
		 "dps": 0.65, "drop": 0.45, "loot_tier": 3, "xp": 17, "cash": 22,     # E1-2: the Town 10/15/20 to 17/24/28 (the Town two levels under its gear at E1), the City 30/36/46 to 37/45/57
		"shape": {"pool": 10, "hp": 1.0, "dps": 1.1, "patrol": 1.2, "cash": 1.0},
		"drops": {"slots": {"Primary": 1, "Secondary": 1, "Helmet": 1, "Armour": 1, "Rig": 3, "Gloves": 1, "Backpack": 3}, "type": "shotgun", "only": ["Framed pack", "Fishing vest"]}},
	{"name": "Shopping Centre", "zone": 2, "pool": 16, "hp": 1235.0, "dps": 1.75, "drop": 0.5, "loot_tier": 3, "xp": 24, "cash": 24,
		"shape": {"pool": 11, "hp": 1.1, "dps": 1.0, "patrol": 0.9, "cash": 1.1},
		"drops": {"slots": {"Primary": 1, "Secondary": 2, "Helmet": 3, "Armour": 3, "Rig": 1, "Gloves": 1, "Backpack": 1}, "type": "pistol", "only": ["Tactical pistol", "Ballistic vest"]}},
	{"name": "The Bank", "zone": 2, "pool": 20, "hp": 1200.0, "dps": 2.16, "drop": 0.5, "loot_tier": 3, "xp": 28, "cash": 30,
		"shape": {"pool": 7, "hp": 1.4, "dps": 1.3, "patrol": 1.5, "cash": 1.6, "paper": 3.0},
		"drops": {"slots": {"Primary": 2, "Secondary": 2, "Helmet": 1, "Armour": 2, "Rig": 1, "Gloves": 1, "Backpack": 1}, "type": "smg", "only": ["Compact pistol", "Light plates"]}},
	{"name": "The Services", "zone": 3, "pool": 16, "hp": 1950.0, "dps": 2.56, "drop": 0.5, "loot_tier": 4, "xp": 37, "cash": 40,
		"shape": {"pool": 12, "hp": 1.0, "dps": 1.0, "patrol": 0.7, "cash": 1.0, "ammo": 2.5},
		"drops": {"slots": {"Primary": 2, "Secondary": 2, "Helmet": 1, "Armour": 1, "Rig": 2, "Gloves": 1, "Backpack": 2}, "type": "smg", "only": ["A delivery note", "Belt links", "Depot rounds", "Cargo frame"]}},     # the Cargo frame a ZONE_KIT too (31 Oct)
	{"name": "The Hospital", "zone": 3, "pool": 18, "hp": 2376.0, "dps": 3.08, "drop": 0.5, "loot_tier": 4, "xp": 45, "cash": 44,
		"shape": {"pool": 10, "hp": 1.2, "dps": 1.0, "patrol": 1.0, "cash": 0.9, "med": 3.0},
		"drops": {"slots": {"Primary": 1, "Secondary": 1, "Helmet": 1, "Armour": 2, "Rig": 3, "Gloves": 2, "Backpack": 1}, "type": "", "only": ["A drug chart", "Hospital kit", "Surgeon's kit", "Medic's harness"]}},     # Medic's harness a ZONE_KIT too (31 Oct)
	{"name": "The Barracks", "zone": 3, "pool": 22, "hp": 2604.0, "dps": 3.58, "drop": 0.55, "loot_tier": 4, "xp": 57, "cash": 50,
		"shape": {"pool": 8, "hp": 1.5, "dps": 1.4, "patrol": 1.3, "cash": 0.8},
		"drops": {"slots": {"Primary": 3, "Secondary": 1, "Helmet": 2, "Armour": 3, "Rig": 2, "Gloves": 2, "Backpack": 1}, "type": "rifle", "only": ["A leave pass", "A requisition", "Section gun", "Stab plates", "Night optic"]}},     # Stab plates a ZONE_KIT too (31 Oct)
]

const BANK := 8                    # the tier whose vault holds the deeds

## The endgame's depth curve: once the campaign is done, every site fights
## at the depth's numbers bent by its shape, so the choice between sites is
## what they drop, not how hard they are. Depth 2 is the first rung.
## The reach is the runner's power against this slope (signals since D3): too steep a grow and a signal past the reach
## goes from won to lost in one level.
const CURVE := {"hp": 3200.0, "dps": 3.6, "xp": 30.0, "cash": 40.0, "drop": 0.5, "grow": 0.16, "reward": 0.02, "rarity": 0.10}     # grow 0.12 to 0.16, reward 0.05 to 0.02 (the designer's call, 31 Oct, PROBE36: the reach ran 20-60 levels an hour past the Quartermaster)
## The gangs to the new tiers (29 Oct, docs/design/itemisation.md §1: tuned to T6 gear at the Barracks, down to T4's): the
## campaign sites' own hp and dps above carry it (every level of them, the depths past the first clear too: 7 Oct's
## curve is a floor under the site's own), each by the gear a runner brings to it now against before - the Retail Park
## and the Pleasure Park ×0.75 (the Pleasure Park ×0.47 HP and fire, the fix round: the Estate's T2 at its door), the Shopping Centre ×0.95, the Bank ×0.8, the City ×0.62-0.75 (their fire half way
## back to 1, the armour's share of it; the City's ×0.92 more for its new frost). The endgame curve by the level's gear
## against before (the signals' T5 at 10 where it was T6): CURVE_K's figure from each level on, hp by it, fire half way.
## Drafts for the balance pass.
const CURVE_K := [[1, 0.7], [10, 0.75], [12, 0.69], [13, 0.82], [16, 0.86], [20, 0.88], [24, 1.0]]     # 12 at 0.69 (the fix round, the review's B5: the old gear stepped there, so its gangs did)


static func curve_k(lv: int) -> float:
	var k := 1.0
	for row in CURVE_K:
		if lv >= int(row[0]):
			k = float(row[1])
	return k


const CURVE_LATE_FROM := 35       # 50 to 35 (Matt, 27 Oct: the reach stood at 40-50 in the 12% band, kit at 5%; docs/design/pinnacle_and_exploits.md)
                                  # past this level the crews grow CURVE_LATE_GROW a level, not CURVE's grow (24 Oct, Matt: an endgame "at least 30ish" hours -
const CURVE_LATE_GROW := 0.12     # 0.07 to 0.12 (the designer's call, 31 Oct, PROBE36: the runner grew ~10% a level past 35 against the content's 7%). Before: at 12% a level the kit's ~10% and the paragon's flat points fell behind by level 45-68 and the reach stood 7-19 h; a slope, not a wall)

## The bosses: one a zone, the crew's head, fought at the zone's last site
## after its pool is down. Free the first time (the campaign); after that
## the crew's price in notes, by depth. Each has their own drops.
## `opens`: the rooms a head's things open, brought home (13 Oct, Matt: the campaign's pacing): the Gamekeeper's vet's bag
## the Clinic, the Manager's deeds the Yard and the Carpet Man's ledger from his vault the Fence, the Quartermaster's set and roll the Radio
## and the Workshop. Until then the room is shut.
const BOSSES := [
	{"zone": 0, "name": "The Gamekeeper", "tier": 2, "hp": 5.0, "dps": 2.0, "notes": 10,     # the Outskirts' edge: soft
		"words": "Top Farm's shoot had a keeper. It still has. He walks the hedges with the dogs and a gun, and he kept the vet's bag.",
		"uniques": ["The Keeper's Twelve-Bore", "The Keeper's Wax Jacket"], "opens": {"clinic": "The vet's bag"}},
	{"zone": 1, "name": "The Carpet Man", "tier": 5, "hp": 6.0, "dps": 2.0, "notes": 20,     # 8/2.5 to 6/2 (the fix round, 29 Oct: the Estate drops T2 now, his men the Retail Park's); D18: 10/3.0 to 8/2.5 - a read in seven held at him for hours (the Estate's kit, a dps of 50, nothing better dropping)
		"words": "The crew in the carpet warehouse have a head. He had a van and a lock-up before; he has the car park now.",
		"uniques": ["The Van's Spare", "Underlay"], "opens": {"workshop": "The fitter's kit"}},     # the Doorman his (24 Oct, milestone 8); the ledger went to the Manager's vault
	{"zone": 2, "name": "The Manager", "tier": 8, "hp": 12.0, "dps": 3.5, "notes": 40,
		"words": "The Bank's crew call themselves staff. He was. He's behind the vault, and he's not coming out for you.",
		"uniques": ["The Manager's Coat", "The Branch Pistol"], "opens": {"yard": "The deeds", "fence": "The Carpet Man's ledger"}},     # the Fence with the Yard (24 Oct, milestone 8: skills.md §6) - the Carpet Man banked with him
	{"zone": 3, "name": "The Quartermaster", "tier": 11, "hp": 6.0, "dps": 2.5, "notes": 60,     # the Barracks went up; he came down to match: the pool before him is the fight
		"words": "The lorry that never reached the Barracks reached him. He's been issuing it ever since, to people he chooses.",
		"uniques": ["The Quartermaster's Rifle", "Issue Webbing"], "opens": {"radio": "A military radio"}},     # the Workshop went to the Carpet Man (27 Oct, Matt: he opened nothing, this one two)
]
const ROOMS_SHUT := ["clinic", "workshop", "fence", "yard", "radio"]     # the rooms a head opens, in the campaign's order
## Pinnacles: from PINNACLE_DEPTH a crew's head comes at full strength -
## harder, dearer, and with one more thing of theirs (a charm) in the pool.
## The convoy: the Services at CONVOY_DEPTH and up can take on all three
## crews at once, one head after another, for all three prices; what comes
## home is the Lorry's Load.
const PINNACLE_DEPTH := [99, 12, 9, 6]  # by zone: level 14 on the head's own site (the Retail Park at 12, the Bank at 9, the Barracks at 6), plus the moves made
## The first leg (7 Oct, the sixteenth read): the stations and the lorry sized to the end kit of hour 16, which stands at
## level 14-15 on every ladder - full strength is twice the crew at the same fire (the fight is attrition, a fire multiplier
## reads 0.00 whatever the HP), at level 14 on each head's own site; the lorry's three come light. The ending climbs a depth a
## move (the loop), and the lorries beaten multiply the Yard (LORRY_MULT), so the second leg reaches further than the first.
const PINNACLE_HP := 2.0
const PINNACLE_DPS := 1.0
const PINNACLE_COST := 2
const CONVOY_DEPTH := 8           # back from 10 (12 Oct, the lorry-fix read: fire and shock stall at Services depth 6-8 and never reached 10; poison was the outlier, not the lorry): level 14 on the Services, plus the moves made (the sixteenth read: the end kit holds level 14, not 16)
const CONVOY_HP := 0.55           # the convoy's heads at this much of their HP each and CONVOY_DPS of their fire: they come light and tired, the crews left with the load
const CONVOY_DPS := 0.85          # the convoy's heads' fire, with CONVOY_HP
const LORRY_MULT := 1.12          # the Yard's damage and HP, times this a lorry beaten, kept across moves: the prestige; under a depth's step, so each leg stays harder than the last
## The paragon board (21 Oct, the crew): a point a paragon level, the crew's, on any row, no top. "pct" a point.
const PARAGON_COMPOUND := []     # the rows that compound, each point on the last: none (the designer's call, 31 Oct, PROBE36: ×3.28 damage from 60 points in 34 min) - every row adds
const PARAGON_BOARD := [
	{"key": "damage", "name": "Damage", "pct": 2.0, "words": "+2% damage a point"},
	{"key": "hp", "name": "HP", "pct": 2.0, "words": "+2% max HP a point"},
	{"key": "resists", "name": "Resists", "pct": 1.0, "words": "+1% to every resist a point, to the cap"},
	{"key": "find", "name": "Find", "pct": 3.0, "words": "+3% loot quality a point"},
	{"key": "tins", "name": "Tins", "pct": 3.0, "words": "+3% tins off a run a point"},
]


static func paragon_row(key: String) -> Dictionary:
	for r in PARAGON_BOARD:
		if r["key"] == key:
			return r
	return {}
const ILVL_SCALE := 0.06          # an affix's rolled value grows this much an item level past ILVL_FROM: the deep drop beats the shallow one of the same tier
const ILVL_FROM := 15
## The broken builds (21 Oct, Matt: "a combination of gear and skill points ... outside of balance passes (like mythics
## do)"): a class's set at its count, a unique's rule, its element's keystone and capstone; together a stack a run with
## no top. The words never say so; docs/design/broken_builds.md says how each is built. "step" is a stack's worth;
## "recipe" the nodes it needs, by tree/name, the smoke walking each from nothing (24 Oct: the web had left the doc's paths behind).
##   embers - a burning kill: fire +step a stack. clean_kills - a chilled kill: the first shot's bonus holds on the
##   next, +step a stack. flatline - the Paramedic's (joints B, 24 Oct; Overdose went with his poison): a shocked kill:
##   shock +step and FLATLINE_HEAL of max HP. opened_for_good - the bleed has no cap; a kill carries it +step. live_load - a shocked kill: shock +step.
##   drilled - the Recruit's (24 Oct): a kill while a skill of his runs: physical +step a stack.
const LOADOUTS := 3                 # a runner's (24 Oct, the endgame chase)
const BUILD_PREFIX := "FIAT1-"      # a build code's head: the version of the lists it indexes
const COLLECTION_LEVELS := [10, 25, 50, 75, 100]     # the collection's marks a site, by level (24 Oct): the last is the tile's
const COLLECTION_CLASS_LEVEL := 50
const BREAKDOWN_ROWS := 7          # the fight's breakdown (24 Oct): the biggest sources shown, the rest "Other"
const COMBO_GUARD_STEP := 0.01     # a pinnacle build's stack takes this off their fire (Matt, 27 Oct)
const COMBO_GUARD_CAP := 0.6       # and no more than this
const COMBO_WARM := 40.0           # a pinnacle build's stacks at a run's start (Matt, 27 Oct)
const COMBO_CEILING := 1e30        # what a stack or a pool runs to: past any gang, short of INF (the save's JSON has none)
## The exploits (Matt, 27 Oct, docs/design/pinnacle_and_exploits.md): one a class, two nodes of its own trees and one
## unique, and the code behaves like a bug - a runaway inside one run, gone at home. No screen names one and nothing logs
## it; the balance reads switch them off (Sim.exploits_off) and the bot never aims at one. "grow": what a kill (or a
## second, for Never trips) multiplies the run's exploit figure by.
const EXPLOITS := {
	"bad_blood": {"class": "Drifter", "nodes": ["Luck/Dead man's shoes", "Luck/Cut-throat"], "rule": "butchers_apron", "grow": 1.2},
	"first_of_many": {"class": "Poacher", "nodes": ["Stalking/Clocked", "Stalking/One shot"], "rule": "starting_pistol", "grow": 1.1},
	"second_opinion": {"class": "Paramedic", "nodes": ["Triage/Second shift", "Triage/Field surgery"], "rule": "paramedics_bumbag"},
	"last_orders_again": {"class": "Doorman", "nodes": ["The door/Last orders", "Muscle/Through the lot"], "rule": "issuers_revolver", "grow": 1.4},
	"never_trips": {"class": "Scrapper", "nodes": ["Stripping/Ring main", "Stripping/Live wire"], "rule": "tester", "grow": 1.5},
	"overdrawn": {"class": "Recruit", "nodes": ["Drill/Quick march", "Drill/Passing-out parade"], "rule": "registrars_stamp"},
}
const EXPLOIT_CD := 0.25           # Overdrawn: a skill's cooldown, seconds (every skill, every tick or so)
const FLATLINE_HEAL := 0.05        # Flatline: a shocked kill heals this share of max HP (joints B, 24 Oct)
const COMBOS := {
	"embers": {"class": "Drifter", "set": "The Fire Crew's", "pieces": 3, "rule": "weed_burner", "nodes": ["fire_spread", "cap_spread"], "recipe": ["Moving on/Bottle and rag", "Petrol/Drifter's can", "Petrol/Spreads", "Petrol/Wildfire"], "step": 0.12},     # 0.04 to 0.08 to 0.12 with the warm start (Matt, 27 Oct, the gauntlet)
	"clean_kills": {"class": "Poacher", "set": "The Army's", "pieces": 4, "rule": "gritters_keys", "nodes": ["frost_freeze", "cap_shatter"], "recipe": ["Snares/Cold snap", "The cold/Poacher's snare", "The cold/Frozen solid", "The cold/Shatter"], "step": 0.05},
	"flatline": {"class": "Paramedic", "set": "The Ambulance's", "pieces": 3, "rule": "linemans_bag", "nodes": ["shock_chain", "cap_arc"], "recipe": ["Shifts/Defib", "Live/Paramedic's paddles", "Live/Daisy chain", "Live/Arc"], "step": 0.05},     # joints B (24 Oct): Overdose went with the Paramedic's poison
	"opened_for_good": {"class": "Doorman", "set": "The Carpet Man's", "pieces": 2, "rule": "butchers_steel", "nodes": ["bleed_forever", "cap_bleed_out"], "recipe": ["Muscle/Glassing", "Blades/Doorman's glass", "Blades/Won't stop", "Blades/Bleed out"], "step": 0.25},
	"live_load": {"class": "Scrapper", "set": "The Bank's", "pieces": 3, "rule": "jump_leads", "nodes": ["shock_chain", "cap_arc"], "recipe": ["Stripping/Live wire", "Live/Scrapper's mains", "Live/Daisy chain", "Live/Arc"], "step": 0.02},
	"drilled": {"class": "Recruit", "set": "The Army's", "pieces": 3, "rule": "qm_rifle", "nodes": ["bust_them_up", "cap_flattened"], "recipe": ["Ordnance/Brute force", "Knuckles/Recruit's boots", "Knuckles/Bust them up", "Knuckles/Flattened"], "step": 0.03},
}


## Gear scaling (21 Oct, the crew; docs/design/vision.md): past the deep tier a base's damage and armour, and the flat
## combat lines, compound this a level - a little under the crews' CURVE grow - every rarity the same; the armour's cut
## reads against the level fought at the same rate, so it holds its share rather than run to a hundred.
const ILVL_GROW := 0.05            # an edge halves in about 10 levels: a few levels a find, then the next
## A head's own unique off the head (21 Oct, Matt's playtest: the Keeper's Twelve-Bore read 23 dmg/s against a 34 Pump
## found before him - "the unique here is pointless and should be the first big find of the game"): its body one
## tier past the site's loot (never under its own base's), and BOSS_UNIQUE_LIFT on its figure.
const BOSS_UNIQUE_LIFT := 1.2
const ILVL_GROW_FROM := 20         # DEEP_TIER_LEVELS' last: the campaign and the deep tiers as they were
const PCT_LINE_TOP := ILVL_GROW_FROM     # a percent affix line stops growing with item level here (the designer's call, 31 Oct, PROBE36 lever 2): flat lines and bases grow on
const WORTH_GROW := 0.02           # an item's worth (the Fence's sale, its shelf, a temper's tins, scrap) grows this an item level past ILVL_GROW_FROM, not ILVL_GROW (the designer's call, 31 Oct, PROBE36 lever 5b)
const FLAT_GROW := ["hp", "armour", "regen", "life_per_kill", "armour_per_free", "armour_per_med"]
const CONVOY_TIER := 9             # the Services
const CONVOY_UNIQUE := "The Lorry's Load"
const NOTES_KILL := 1              # notes a kill, times the depth factor
const NOTES_SEARCH := 0.3          # chance a search turns up a note or two
const NOTES_BOSS := 5              # notes a boss kill, times depth

## Training - the Yard's, kept across runners. One common tree, and two for
## what the runner was (the class). Each tree is a chain: a node needs the one
## before it. Small nodes add a number; a notable (every fourth) changes a
## rule; a class tree's last node is a keystone that breaks one outright.
## A node with a "type" only counts while the primary is a gun of that type.
## A point a level; respec costs RESPEC_CASH a point spent; changing class
## refunds its two trees for nothing.
## The caps pass (8 Oct): names are capitalised wherever they stand - rooms, zones, sites, classes, trees, the
## heads, uniques, sets; everything else is sentence case; acronyms upper.
## A base whose picture was made under an older name (the fix round, 29 Oct): its art is read under that one.
const ART_AS := {"Legation machine pistol": "Diplomatic machine pistol", "Turnout coat": "Fire service turnout gear"}

const COMMON_TREE := "The Pitch"
const TREES_SRC := [
	{"name": "The Pitch", "nodes": [
		{"name": "Dry fire", "col": 0, "row": 0, "effect": "damage_pct", "value": 3},
		{"name": "Long walks", "col": 0, "row": 1, "effect": "hp", "value": 4},
		{"name": "Knowing the streets", "col": 1, "row": 0, "effect": "loot_pct", "value": 3},
		{"name": "Double tap", "col": 2, "row": 0, "effect": "double_tap", "notable": true, "words": "The secondary does its full damage beside the primary, not 33%"},
		{"name": "Zeroing", "col": 1, "row": 1, "effect": "damage_pct", "value": 7},
		{"name": "Circuits", "col": 2, "row": 1, "effect": "hp", "value": 9},
		{"name": "Keen eyes", "col": 3, "row": 0, "effect": "search_pct", "value": 15},
		{"name": "Second wind", "col": 4, "row": 0, "effect": "second_wind", "notable": true, "words": "Resting at home heals twice as fast"},
		{"name": "Stashing", "col": 3, "row": 1, "effect": "loot_pct", "value": 4},
		{"name": "Pack horse", "col": 4, "row": 1, "effect": "pack_mule", "notable": true, "words": "The pack holds 6 more cells"},
		{"name": "The dog's share", "col": 5, "row": 0, "effect": "cap_dogs_share", "capstone": true, "words": "When the runner dies, their rig comes home"},
	]},
	# A tree is a lane (9 Oct, docs/design/trees.md): six columns of two, read left to right, "col" and "row"
	# on every node. A node wants only its column open - points spent in that tree, Data.gate - so a deep
	# node can't be bought with a dip. A class tree's conversion notable is its half of a joint (column 4).
	# Poacher
	{"name": "Stalking", "class": "Poacher", "nodes": [
		{"name": "Clean shot", "col": 0, "row": 0, "effect": "skill_clean_shot", "skill": "clean_shot", "notable": true, "words": "Your next shot does ×2.5 damage"},
		{"name": "Breathing", "col": 0, "row": 1, "effect": "damage_pct", "value": 3},
		{"name": "Patience", "col": 1, "row": 0, "effect": "patrol_pct", "value": 10},
		{"name": "Rifleman", "col": 2, "row": 0, "effect": "first_pct", "value": 100, "type": "rifle", "notable": true, "words": "Do double damage to the first of each gang with a rifle"},
		{"name": "Wind reading", "col": 1, "row": 1, "effect": "first_pct", "value": 10},
		{"name": "Clocked", "col": 2, "row": 1, "effect": "clocked", "notable": true, "words": "Killing the first of each gang gives +10% damage for the rest of it"},     # moved off its hang for One for the pot (24 Oct, milestone 8)
		{"name": "One shot", "col": 4, "row": 0, "effect": "one_shot", "keystone": true, "words": "The first of each gang dies at once"},
		{"name": "Lying up", "col": 3, "row": 1, "effect": "patrol_pct", "value": 25},     # 10 + Sit tight's 15 (24 Oct: its hang went to Go to ground)
		{"name": "Rat bait", "col": 3, "row": 0, "effect": "conv_poison_pct", "value": 15, "notable": true, "joint": "poacher_poison", "words": "15% of every hit becomes poison"},
		{"name": "Night work", "cost": true, "col": 4, "row": 1, "effect": "night_work", "notable": true, "words": "Every run counts as night: loot quality up, pace −20%"},
		{"name": "Dead quiet", "col": 5, "row": 0, "effect": "cap_dead_quiet", "capstone": true, "words": "Every gang is the size of the first; they never grow"},
		{"name": "In the hide", "col": 5, "row": 1, "beside": true, "effect": "in_the_hide", "notable": true, "words": "Killing the first of each gang gives Guard of 15% of max HP"},     # Guard (12 Oct)
	]},
	{"name": "Snares", "class": "Poacher", "nodes": [
		{"name": "Quick hands", "col": 0, "row": 0, "effect": "search_pct", "value": 25},     # 15 + Gaps in the hedge's 10 (24 Oct)
		{"name": "Hedgerows", "col": 0, "row": 1, "effect": "loot_pct", "value": 3},
		{"name": "Soft ground", "col": 1, "row": 0, "effect": "patrol_pct", "value": 20},     # 10 + Off the path's 10 (24 Oct)
		{"name": "Quiet feet", "col": 2, "row": 0, "effect": "quiet_feet", "notable": true, "words": "A new gang comes every 30 seconds, not 24"},
		{"name": "Night eyes", "col": 1, "row": 1, "effect": "rarity", "value": 20},
		{"name": "Snare lines", "col": 2, "row": 1, "effect": "loot_pct", "value": 10},     # 4 + Game bag's 6 (24 Oct)
		{"name": "Trapline", "col": 4, "row": 0, "effect": "trapline", "keystone": true, "words": "Every gang arrives one man short, the first included"},
		{"name": "Twine", "col": 3, "row": 1, "effect": "twine", "notable": true, "words": "The next gang arrives one fewer after every search"},     # moved off its hang for Net every hole (24 Oct)
		{"name": "Cold snap", "col": 3, "row": 0, "effect": "conv_frost_pct", "value": 15, "notable": true, "joint": "poacher_frost", "words": "15% of every hit becomes frost, which slows their fire"},
		{"name": "Early doors", "col": 4, "row": 1, "effect": "early_doors", "notable": true, "words": "The first gang takes twice as long to arrive"},
		{"name": "Poached", "col": 5, "row": 0, "effect": "cap_poached", "capstone": true, "words": "Every gang that arrives gives you a find"},
	]},
	# Doorman
	{"name": "Muscle", "class": "Doorman", "nodes": [
		{"name": "Shoulder charge", "col": 0, "row": 0, "effect": "skill_shoulder_charge", "skill": "shoulder_charge", "notable": true, "words": "Hits the nearest man for ×3 damage and sends him to the back"},
		{"name": "Gym", "col": 0, "row": 1, "effect": "hp", "value": 14},     # 4 + Bulk's 10 (24 Oct, step 4: its hang went to Shoulder charge),
		{"name": "Broad shoulders", "col": 1, "row": 0, "effect": "armour_pct", "value": 17},     # 5 + Hard case's 12 (24 Oct, step 4: its hang went to Brace),
		{"name": "Shotgunner", "col": 2, "row": 0, "effect": "damage_pct", "value": 25, "type": "shotgun", "notable": true, "words": "Shotgun damage +25%"},
		{"name": "Weights", "col": 1, "row": 1, "effect": "damage_pct", "value": 5},
		{"name": "Off the canvas", "col": 2, "row": 1, "effect": "off_the_canvas", "notable": true, "words": "Guard of 20% max HP at 33% HP, once a run"},     # moved off its hang for Barred (24 Oct, step 4)
		{"name": "Bodyline", "col": 4, "row": 0, "effect": "bodyline", "keystone": true, "words": "Take 50% less damage with three or more on you"},
		{"name": "Big frame", "col": 3, "row": 1, "effect": "hp", "value": 6},
		{"name": "Glassing", "col": 3, "row": 0, "effect": "conv_bleed_pct", "value": 15, "notable": true, "joint": "doorman_bleed", "words": "15% of every hit becomes bleed"},
		{"name": "Loud", "cost": true, "col": 4, "row": 1, "effect": "loud", "notable": true, "words": "Gangs come 40% sooner and one bigger; drops +30%"},
		{"name": "Spoils", "col": 5, "row": 1, "effect": "rarity", "value": 15},
		{"name": "Iron", "col": 5, "row": 0, "effect": "cap_iron", "capstone": true, "words": "Every kill heals 10% of max HP under half HP"},
	]},
	{"name": "The door", "class": "Doorman", "nodes": [
		{"name": "Stance", "col": 0, "row": 0, "effect": "hp", "value": 18},     # 10 + Big lad's 8 (24 Oct, step 4: its hang went to Pat down),
		{"name": "Heads down", "col": 0, "row": 1, "effect": "damage_pct", "value": 3},
		{"name": "Eye contact", "col": 1, "row": 0, "effect": "armour_pct", "value": 15},     # 5 + Doorframe's 10 (24 Oct, step 4: its hang went to Not on the list),
		{"name": "Chokepoints", "col": 2, "row": 0, "effect": "overwatch", "notable": true, "words": "Only 2 of a gang can fire on you at once, not 3"},
		{"name": "Bouncing", "col": 1, "row": 1, "effect": "hp", "value": 5},
		{"name": "Last orders", "col": 2, "row": 1, "effect": "last_orders", "notable": true, "words": "+40% damage to the last of each gang"},     # moved off its hang for Chucking-out time (24 Oct, step 4)
		{"name": "One at a time", "col": 4, "row": 0, "effect": "one_at_a_time", "keystone": true, "words": "Only one of a gang can ever fire on you at once; pace −25%"},
		{"name": "Hands on", "col": 3, "row": 0, "effect": "physical_pct", "value": 20, "type": ["shotgun", "melee"], "notable": true, "joint": "doorman_physical", "words": "Shotguns and melee do 20% more physical damage"},
		{"name": "Through the lot", "col": 3, "row": 1, "effect": "melee_sweep", "type": "melee", "notable": true, "words": "With melee, every swing hits everyone on you"},
		{"name": "Stand and fight", "cost": true, "col": 4, "row": 1, "effect": "stand", "notable": true, "words": "You can't leave before the clear; the clear's XP bonus is doubled"},
		{"name": "Held", "col": 5, "row": 0, "effect": "cap_held", "capstone": true, "words": "You never lose more than 10% of max HP in a second"},
		{"name": "Squared up", "col": 5, "row": 1, "beside": true, "effect": "squared_up", "notable": true, "words": "Each gang that arrives gives Guard of 15% of max HP"},     # Guard (12 Oct)
	]},
	# Paramedic
	{"name": "Triage", "class": "Paramedic", "nodes": [
		{"name": "Tourniquet", "col": 0, "row": 0, "effect": "skill_tourniquet", "skill": "tourniquet", "notable": true, "words": "Clears bleed on you; no new bleed lands for 10 seconds"},     # 10 + Good hands's 20 (24 Oct, step 4: its hang went to Tourniquet),
		{"name": "Fast hands", "col": 0, "row": 1, "effect": "med_speed_pct", "value": 35},     # 15 + Quick dressing's 20 (24 Oct, step 4: its hang went to Antidote),
		{"name": "Kit bag", "col": 1, "row": 0, "effect": "heal_pct", "value": 10},
		{"name": "Fast work", "col": 2, "row": 0, "effect": "triage", "notable": true, "words": "Meds take half the time"},
		{"name": "Good veins", "col": 1, "row": 1, "effect": "heal_pct", "value": 15},
		{"name": "Stock take", "col": 2, "row": 1, "effect": "med_cap", "value": 2},     # 1 + Grab bag's 1 (24 Oct, step 4: its hang went to Adrenaline),
		{"name": "Field surgery", "col": 4, "row": 0, "effect": "field_surgery", "keystone": true, "words": "Meds work at once, not over seconds"},
		{"name": "Worst first", "col": 3, "row": 1, "effect": "worst_first", "notable": true, "words": "A med heals +50% under 50% HP"},     # moved off its hang for Major incident (24 Oct, step 4)
		{"name": "Ice pack", "col": 3, "row": 0, "effect": "conv_frost_pct", "value": 15, "notable": true, "joint": "paramedic_frost", "words": "15% of every hit becomes frost, which slows their fire"},
		{"name": "Walking wounded", "cost": true, "col": 4, "row": 1, "effect": "walking_wounded", "notable": true, "words": "Meds heal 50% less; damage +40% under half HP"},
		{"name": "Pockets checked", "col": 5, "row": 1, "effect": "rarity", "value": 15},
		{"name": "Clean hands", "col": 5, "row": 0, "effect": "cap_clean_hands", "capstone": true, "words": "A med clears burns, poison and bleeds on you, and you take no damage for 3 seconds"},
	]},
	{"name": "Shifts", "class": "Paramedic", "nodes": [
		{"name": "Night shift", "col": 0, "row": 0, "effect": "hp", "value": 13},     # 5 + Last bus's 8 (24 Oct, step 4: its hang went to Strapped up),
		{"name": "Rest easy", "col": 0, "row": 1, "effect": "rest_pct", "value": 55},     # 25 + Flask's 30 (24 Oct, step 4: its hang went to Two sugars),
		{"name": "Mates' rates", "col": 1, "row": 0, "effect": "treat_pct", "value": 40},     # 20 + Regulars's 20 (24 Oct, step 4: its hang went to Sedative dart),
		{"name": "Walk it off", "col": 2, "row": 0, "effect": "walk_it_off", "notable": true, "words": "Heal 1 HP a second while searching"},
		{"name": "Long shift", "col": 1, "row": 1, "effect": "hp", "value": 5},
		{"name": "Clocking off", "col": 2, "row": 1, "effect": "clocking_off", "notable": true, "words": "The first search after a clear is instant"},     # moved off its hang for Code blue (24 Oct, step 4)
		{"name": "Not today", "col": 4, "row": 0, "effect": "not_today", "keystone": true, "words": "Under 25% HP, you take 40% less damage"},
		{"name": "Discount", "col": 3, "row": 1, "effect": "treat_pct", "value": 20},
		{"name": "Defib", "col": 3, "row": 0, "effect": "conv_shock_pct", "value": 15, "notable": true, "joint": "paramedic_shock", "words": "15% of every hit becomes shock"},
		{"name": "Second shift", "col": 4, "row": 1, "effect": "second_shift", "notable": true, "words": "The first med you use on a run isn't used up"},
		{"name": "Transfusion", "col": 5, "row": 0, "effect": "cap_transfusion", "capstone": true, "words": "Guard holds twice as much, and a med fills it to the top"},     # Guard (12 Oct): was overflow as armour, two to one; the class does overflow now
		{"name": "Double shift", "col": 5, "row": 1, "beside": true, "effect": "overtime", "notable": true, "words": "Guard holds 50% more; with Guard up, meds take half the time"},
	]},
	# Scrapper
	{"name": "Stripping", "class": "Scrapper", "nodes": [
		{"name": "Ring main", "col": 0, "row": 0, "effect": "skill_ring_main", "skill": "ring_main", "notable": true, "words": "×1.5 shock damage that jumps through 3 men"},     # 5 + Socket set's 10 (24 Oct, step 4: its hang went to Ring main),
		{"name": "Quick fingers", "col": 0, "row": 1, "effect": "search_pct", "value": 15},
		{"name": "Tools", "col": 1, "row": 0, "effect": "damage_pct", "value": 3},
		{"name": "Bodger", "col": 2, "row": 0, "effect": "damage_pct", "value": 40, "type": "improvised", "notable": true, "words": "Improvised gun damage +40%"},
		{"name": "Spare parts", "col": 1, "row": 1, "effect": "att_share", "value": 5},
		{"name": "Salvage", "col": 2, "row": 1, "effect": "salvage", "notable": true, "words": "+50% scrap from scrapping at the Workshop"},     # moved off its hang for Breakdown (24 Oct, step 4)
		{"name": "Nothing wasted", "col": 4, "row": 0, "effect": "nothing_wasted", "keystone": true, "words": "Every kill drops something"},
		{"name": "Workbench", "col": 3, "row": 1, "effect": "workbench", "notable": true, "words": "One Bench job a day is free"},     # moved off its hang for Short circuit (24 Oct, step 4)
		{"name": "Live wire", "col": 3, "row": 0, "effect": "conv_shock_pct", "value": 15, "notable": true, "joint": "scrapper_shock", "words": "15% of every hit becomes shock"},
		{"name": "Quiet hands", "cost": true, "col": 4, "row": 1, "effect": "quiet_hands", "notable": true, "words": "Every search finds 1 more; kills drop nothing"},
		{"name": "Jerry-rigged", "col": 5, "row": 0, "effect": "cap_jerry", "capstone": true, "words": "An improvised primary does 50% more damage"},
		{"name": "Sheet metal", "col": 5, "row": 1, "beside": true, "effect": "sheet_metal", "notable": true, "words": "Every crate searched gives Guard of 6% of max HP"},     # Guard (12 Oct)
	]},
	{"name": "Fencing", "class": "Scrapper", "nodes": [
		{"name": "Gift of the gab", "col": 0, "row": 0, "effect": "sell_pct", "value": 25},     # 10 + Haggler's 15 (24 Oct, step 4: its hang went to Bung),
		{"name": "Contacts", "col": 0, "row": 1, "effect": "cash_pct", "value": 25},     # 10 + Pub talk's 15 (24 Oct, step 4: its hang went to Back of the van),
		{"name": "Weighing it up", "col": 1, "row": 0, "effect": "sell_pct", "value": 10},
		{"name": "Magpie", "col": 2, "row": 0, "effect": "scavenger", "notable": true, "words": "Every search finds 1 more"},
		{"name": "Known face", "col": 1, "row": 1, "effect": "cash_pct", "value": 10},
		{"name": "Back pocket", "col": 2, "row": 1, "effect": "back_pocket", "notable": true, "words": "The Fence keeps one piece of kit free on a death"},     # moved off its hang for Everything must go (24 Oct, step 4)
		{"name": "Buyer's market", "col": 4, "row": 0, "effect": "buyers_market", "keystone": true, "words": "The Fence pays double, and everything you buy costs double"},
		{"name": "Lucky find", "col": 3, "row": 1, "effect": "rarity", "value": 20},
		{"name": "Blowtorch", "col": 3, "row": 0, "effect": "conv_fire_pct", "value": 15, "notable": true, "joint": "scrapper_fire", "words": "15% of every hit becomes fire"},
		{"name": "Hoarder", "cost": true, "col": 4, "row": 1, "effect": "hoarder", "notable": true, "words": "The pack holds twice as much; pace −30%"},
		{"name": "The lot", "col": 5, "row": 0, "effect": "cap_the_lot", "capstone": true, "words": "Bring the pack home full and the run pays double tins"},
	]},
	# Drifter
	{"name": "Moving on", "class": "Drifter", "nodes": [
		{"name": "Duck and weave", "col": 0, "row": 0, "effect": "skill_duck_and_weave", "skill": "duck_and_weave", "notable": true, "words": "The next 3 hits on you miss"},     # 5 + Tarmac's 6 (24 Oct, step 4: its hang went to Duck and weave),
		{"name": "Road legs", "col": 0, "row": 1, "effect": "hp", "value": 5},
		{"name": "Head start", "col": 1, "row": 0, "effect": "patrol_pct", "value": 20},     # 10 + Thumb out's 10 (24 Oct, step 4: its hang went to Look lively),
		{"name": "Spray", "col": 2, "row": 0, "effect": "damage_pct", "value": 25, "type": "smg", "notable": true, "words": "SMG damage +25%"},
		{"name": "Keep moving", "col": 1, "row": 1, "effect": "pace_pct", "value": 5},
		{"name": "B-roads", "col": 2, "row": 1, "effect": "b_roads", "notable": true, "words": "The first gang after a clear takes 100% longer to arrive"},     # moved off its hang for Gone (24 Oct, step 4)
		{"name": "Never there", "col": 4, "row": 0, "effect": "never_there", "keystone": true, "words": "No gangs ever come; searches take twice as long"},
		{"name": "Wiry", "col": 3, "row": 1, "effect": "hp", "value": 5},
		{"name": "Bottle and rag", "col": 3, "row": 0, "effect": "conv_fire_pct", "value": 15, "notable": true, "joint": "drifter_fire", "words": "15% of every hit becomes fire"},
		{"name": "Hit and run", "cost": true, "col": 4, "row": 1, "effect": "hit_and_run", "notable": true, "words": "The runner leaves with the loot as the first gang arrives; kills pay 50% more"},
		{"name": "Ghost", "cost": true, "col": 5, "row": 0, "effect": "cap_ghost", "capstone": true, "words": "No fight before the search: runs start searching, and bringing a full pack home counts as the clear"},
		{"name": "Breather", "col": 5, "row": 1, "beside": true, "effect": "breather", "notable": true, "words": "While searching, Guard refills 10% of its cap a second"},     # Guard (12 Oct)
	]},
	{"name": "Luck", "class": "Drifter", "nodes": [
		{"name": "Jammy", "col": 0, "row": 0, "effect": "rarity", "value": 25},     # 10 + Lucky penny's 15 (24 Oct, step 4: its hang went to Coin toss),
		{"name": "Found tins", "col": 0, "row": 1, "effect": "cash_pct", "value": 22},     # 10 + Coppers's 12 (24 Oct, step 4: its hang went to Close shave),
		{"name": "Charmed", "col": 1, "row": 0, "effect": "loot_pct", "value": 9},     # 3 + Beady eye's 6 (24 Oct, step 4: its hang went to Chancer),
		{"name": "Dead man's shoes", "col": 2, "row": 0, "effect": "damage_low_pct", "value": 20, "notable": true, "words": "Damage +20% under half HP"},
		{"name": "Touch wood", "col": 1, "row": 1, "effect": "rarity", "value": 15},
		{"name": "Spare change", "col": 2, "row": 1, "effect": "spare_change", "notable": true, "words": "20% chance a search finds a note"},     # moved off its hang for Jackpot (24 Oct, step 4)
		{"name": "All or nothing", "col": 4, "row": 0, "effect": "all_or_nothing", "keystone": true, "words": "No Common finds, and half as many finds"},
		{"name": "Four-leaf", "col": 3, "row": 1, "effect": "loot_pct", "value": 4},
		{"name": "Cut-throat", "col": 3, "row": 0, "effect": "conv_bleed_pct", "value": 15, "notable": true, "joint": "drifter_bleed", "words": "15% of every hit becomes bleed"},
		{"name": "Light fingers", "cost": true, "col": 4, "row": 1, "effect": "light_fingers", "notable": true, "words": "Papers turn up 3 times as often; tins from kills −20%"},
		{"name": "Loaded dice", "col": 5, "row": 0, "effect": "cap_loaded_dice", "capstone": true, "words": "A Rare or better find rolls twice; you keep the better"},
	]},
	# Recruit (24 Oct, milestone 8: the sixth class, docs/design/skills.md §5): the class built round skills - Ordnance
	# the throws, Drill the casting
	{"name": "Ordnance", "class": "Recruit", "nodes": [
		{"name": "Lob one in", "col": 0, "row": 0, "effect": "skill_lob_one_in", "skill": "lob_one_in", "notable": true, "words": "Throws a grenade at everyone on you without using one from your rig"},
		{"name": "Cookhouse", "col": 0, "row": 1, "effect": "hp", "value": 5},
		{"name": "Spare pouch", "col": 1, "row": 0, "effect": "med_cap", "value": 1},
		{"name": "Cook it off", "col": 2, "row": 0, "effect": "grenade_extra", "notable": true, "words": "Every grenade also hits a man who isn't on you yet"},
		{"name": "Square bashing", "col": 1, "row": 1, "effect": "damage_pct", "value": 4},
		{"name": "Flak jacket", "col": 2, "row": 1, "effect": "armour_pct", "value": 6},
		{"name": "Grenadier", "col": 4, "row": 0, "effect": "danger_area", "keystone": true, "words": "Grenades do double damage; the rig holds one fewer pouch"},
		{"name": "Detonators", "col": 3, "row": 1, "effect": "grenade_pct", "value": 15},
		{"name": "Brute force", "col": 3, "row": 0, "effect": "physical_pct", "value": 15, "notable": true, "joint": "recruit_physical", "words": "Physical damage +15%"},
		{"name": "Blast burns", "cost": true, "col": 4, "row": 1, "effect": "blast_burns", "notable": true, "words": "Every grenade sets everyone it hits burning; you take 10% more fire damage"},
		{"name": "Sandbags", "col": 5, "row": 1, "effect": "armour_pct", "value": 10},
		{"name": "Ringing ears", "col": 5, "row": 0, "effect": "cap_shock_awe", "capstone": true, "words": "Every grenade stuns everyone it hits for 1 second"},
	]},
	{"name": "Drill", "class": "Recruit", "nodes": [
		{"name": "Reveille", "col": 0, "row": 0, "effect": "energy_regen_pct", "value": 10},
		{"name": "Lights out", "col": 0, "row": 1, "effect": "hp", "value": 5},
		{"name": "At ease", "col": 1, "row": 0, "effect": "cdr_pct", "value": 4},
		{"name": "Cover me", "col": 2, "row": 0, "effect": "cover_pct", "value": 25, "notable": true, "words": "Take 25% less damage while one of your skills is in effect"},
		{"name": "Range day", "col": 1, "row": 1, "effect": "damage_pct", "value": 4},
		{"name": "Kit inspection", "col": 2, "row": 1, "effect": "energy_max", "value": 10},
		{"name": "Quick march", "col": 4, "row": 0, "effect": "on_the_double", "keystone": true, "words": "Cooldowns 30% shorter; skills cost 25% more"},
		{"name": "Brasso", "col": 3, "row": 1, "effect": "energy_regen_pct", "value": 15},
		{"name": "Tear gas", "col": 3, "row": 0, "effect": "conv_poison_pct", "value": 15, "notable": true, "joint": "recruit_poison", "words": "15% of every hit becomes poison"},
		{"name": "Double time", "cost": true, "col": 4, "row": 1, "effect": "double_time", "notable": true, "words": "Energy refills twice as quickly; max energy −30"},
		{"name": "Spit and polish", "col": 5, "row": 1, "effect": "cdr_pct", "value": 4},
		{"name": "Passing-out parade", "col": 5, "row": 0, "effect": "cap_passing_out", "capstone": true, "words": "Every skill you use gives 5 energy back"},
	]},
]
## The element trees: one a type, lanes like the class ones - conversion and increased to a notable, then
## column 4's halves of the joints (a class's alone: "class"), then a keystone that breaks the element's rule
## and a notable with a cost, which want a closed joint in the tree (JOINTS), then the capstone. Any class
## can walk any of them; its two affinities (AFFINITY) come at the normal price, the others cost double and
## stop at column 4 - a dip, not a build. Knuckles is the physical: the share of a hit that isn't converted.
const ELEMENT_TREES_SRC := [
	{"name": "Petrol", "element": "fire", "nodes": [
		{"name": "A can of it", "col": 0, "row": 0, "effect": "conv_fire_pct", "value": 20},     # 30 to 20 (the twenty-seventh read: the fire Drifter to the Bank in 0.3-0.8 h, the next element build 1.0)
		{"name": "Rags", "col": 0, "row": 1, "effect": "fire_pct", "value": 10},
		{"name": "Siphoned", "col": 1, "row": 0, "effect": "conv_fire_pct", "value": 35},
		{"name": "Lit", "col": 2, "row": 0, "effect": "fire_pct", "value": 30, "notable": true, "words": "Fire damage +30%; burns last twice as long"},
		{"name": "Wick", "col": 1, "row": 1, "effect": "fire_pct", "value": 12},
		{"name": "Drifter's can", "col": 3, "row": 0, "effect": "fire_pct", "value": 25, "type": "smg", "class": "Drifter", "notable": true, "joint": "drifter_fire", "words": "SMGs do 25% more fire damage"},
		{"name": "Spreads", "col": 4, "row": 0, "effect": "fire_spread", "keystone": true, "words": "Fire damage hits everyone on you"},
		{"name": "Fumes", "col": 2, "row": 1, "effect": "dot_pct", "value": 20},
		{"name": "Scrapper's torch", "col": 3, "row": 1, "effect": "fire_pct", "value": 25, "type": "improvised", "class": "Scrapper", "notable": true, "joint": "scrapper_fire", "words": "Improvised guns do 25% more fire damage"},
		{"name": "On your hands", "col": 4, "row": 1, "effect": "fire_more", "notable": true, "words": "Fire damage +40%; every fire hit burns you for 2% of it"},
		{"name": "Wildfire", "col": 5, "row": 0, "effect": "cap_spread", "capstone": true, "words": "A burn carries to the next man when one dies"},
		{"name": "Fireproof", "col": 5, "row": 1, "beside": true, "effect": "proof_fire", "value": 1, "also": {"fire_res": 20}, "notable": true,
		 "words": "Fire resist +20%; past the 75% cap, each 1% adds 2% fire damage"},     # over the cap (12 Oct)
	]},
	{"name": "The cold", "element": "frost", "nodes": [
		{"name": "De-icer", "col": 0, "row": 0, "effect": "conv_frost_pct", "value": 30},
		{"name": "Frost", "col": 0, "row": 1, "effect": "frost_pct", "value": 10},
		{"name": "A hard winter", "col": 1, "row": 0, "effect": "conv_frost_pct", "value": 35},
		{"name": "Chill", "col": 2, "row": 0, "effect": "frost_pct", "value": 30, "notable": true, "words": "Frost damage +30%; chilled gangs fire 40% slower, not 20%"},
		{"name": "Numb", "col": 1, "row": 1, "effect": "frost_pct", "value": 12},
		{"name": "Poacher's snare", "col": 3, "row": 0, "effect": "frost_pct", "value": 25, "also": {"patrol_pct": 10}, "class": "Poacher", "notable": true, "joint": "poacher_frost", "words": "Frost damage +25%; every gang takes 10% longer to arrive"},
		{"name": "Frozen solid", "col": 4, "row": 0, "effect": "frost_freeze", "keystone": true, "words": "Chilled gangs fire at 15% of their rate; frost damage −50%"},
		{"name": "Wind chill", "col": 2, "row": 1, "effect": "frost_pct", "value": 15},
		{"name": "Paramedic's ice", "col": 3, "row": 1, "effect": "frost_pct", "value": 25, "class": "Paramedic", "notable": true, "joint": "paramedic_frost", "words": "Frost damage +25%"},
		{"name": "Cold hands", "col": 4, "row": 1, "effect": "frost_more", "notable": true, "words": "Frost damage +40%; pace −15%"},
		{"name": "Shatter", "col": 5, "row": 0, "effect": "cap_shatter", "capstone": true,
		  "words": "Chilled targets take double physical damage"},
		{"name": "Thermals", "col": 5, "row": 1, "beside": true, "effect": "proof_frost", "value": 1, "also": {"frost_res": 20}, "notable": true,
		 "words": "Frost resist +20%; past the 75% cap, each 1% adds 2% frost damage"},     # over the cap (12 Oct)
	]},
	{"name": "The Rat Man", "element": "poison", "nodes": [
		{"name": "Under the sink", "col": 0, "row": 0, "effect": "conv_poison_pct", "value": 30},
		{"name": "Bait", "col": 0, "row": 1, "effect": "poison_pct", "value": 10},
		{"name": "Council issue", "col": 1, "row": 0, "effect": "conv_poison_pct", "value": 35},
		{"name": "Dosed", "col": 2, "row": 0, "effect": "poison_pct", "value": 30, "notable": true, "words": "Poison damage +30%; poison lasts twice as long"},
		{"name": "Cumulative", "col": 1, "row": 1, "effect": "dot_pct", "value": 15},
		{"name": "Poacher's bait", "col": 3, "row": 0, "effect": "poison_pct", "value": 25, "type": "rifle", "class": "Poacher", "notable": true, "joint": "poacher_poison", "words": "Rifles do 25% more poison damage"},
		{"name": "Builds", "col": 4, "row": 0, "effect": "poison_stacks", "keystone": true, "words": "Poison stacks to 15, not 5"},
		{"name": "Slow acting", "col": 2, "row": 1, "effect": "poison_pct", "value": 15},
		{"name": "Recruit's gas", "col": 3, "row": 1, "effect": "poison_pct", "value": 20, "class": "Recruit", "notable": true, "joint": "recruit_poison", "words": "Poison damage +20%"},     # the Paramedic's dose's place (24 Oct, joints B: the Recruit takes poison)
		{"name": "Rat's share", "col": 4, "row": 1, "effect": "poison_more", "notable": true, "words": "Poison damage +40%; loot quantity −20%"},
		{"name": "Lingers", "col": 5, "row": 0, "effect": "cap_lingers", "capstone": true, "words": "Poison carries to the next man when one dies"},
		{"name": "Immune", "col": 5, "row": 1, "beside": true, "effect": "proof_poison", "value": 1, "also": {"poison_res": 20}, "notable": true,
		 "words": "Poison resist +20%; past the 75% cap, each 1% adds 2% poison damage"},     # over the cap (12 Oct)
	]},
	{"name": "Live", "element": "shock", "nodes": [
		{"name": "Sparks", "col": 0, "row": 0, "effect": "conv_shock_pct", "value": 30},
		{"name": "Charge", "col": 0, "row": 1, "effect": "shock_pct", "value": 10},
		{"name": "Off the mains", "col": 1, "row": 0, "effect": "conv_shock_pct", "value": 35},
		{"name": "Current", "col": 2, "row": 0, "effect": "shock_pct", "value": 30, "notable": true, "words": "Shock damage +30%; shocked gangs take 40% more, not 25%"},
		{"name": "Amps", "col": 1, "row": 1, "effect": "shock_pct", "value": 12},
		{"name": "Paramedic's paddles", "col": 3, "row": 0, "effect": "shock_pct", "value": 25, "class": "Paramedic", "notable": true, "joint": "paramedic_shock", "words": "Shock damage +25%"},     # the Drifter's leads' place (24 Oct, joints B: the Paramedic takes shock)
		{"name": "Daisy chain", "col": 4, "row": 0, "effect": "shock_chain", "keystone": true, "words": "While the target is shocked, your shock damage hits everyone on you"},
		{"name": "Volts", "col": 2, "row": 1, "effect": "shock_pct", "value": 15},
		{"name": "Scrapper's mains", "col": 3, "row": 1, "effect": "shock_pct", "value": 25, "type": "improvised", "class": "Scrapper", "notable": true, "joint": "scrapper_shock", "words": "Improvised guns do 25% more shock damage"},
		{"name": "Earthed", "col": 4, "row": 1, "effect": "shock_more", "notable": true, "words": "Shock damage +40%; your armour −20%"},
		{"name": "Arc", "col": 5, "row": 0, "effect": "cap_arc", "capstone": true, "words": "A shock lasts until the target dies"},
		{"name": "Rubber soles", "col": 5, "row": 1, "beside": true, "effect": "proof_shock", "value": 1, "also": {"shock_res": 20}, "notable": true,
		 "words": "Shock resist +20%; past the 75% cap, each 1% adds 2% shock damage"},     # over the cap (12 Oct)
	]},
	{"name": "Blades", "element": "bleed", "nodes": [
		{"name": "Stanley knife", "col": 0, "row": 0, "effect": "conv_bleed_pct", "value": 30},
		{"name": "An edge", "col": 0, "row": 1, "effect": "bleed_pct", "value": 25},          # 10 to 25 (the twenty-fifth read): bleed meets the town's 20% resist on the way to the Bank, fire and poison don't
		{"name": "Sharpened", "col": 1, "row": 0, "effect": "conv_bleed_pct", "value": 35},     # 15 to 35, as every element's second conversion (the twenty-fifth read: bleed the slowest to the Bank, 2.6 h against fire's 0.7)
		{"name": "Opened up", "col": 2, "row": 0, "effect": "bleed_pct", "value": 30, "notable": true, "words": "Bleed damage +30%; bleeds last twice as long"},
		{"name": "Deep", "col": 1, "row": 1, "effect": "bleed_pct", "value": 40},             # 12 to 20, the same; 20 to 40, Butcher's 20 (24 Oct: its place is the Recruit's half)
		{"name": "Doorman's glass", "col": 3, "row": 0, "effect": "bleed_pct", "value": 25, "type": ["shotgun", "melee"], "class": "Doorman", "notable": true, "joint": "doorman_bleed", "words": "Shotguns and melee do 25% more bleed damage"},
		{"name": "Won't stop", "col": 4, "row": 0, "effect": "bleed_forever", "keystone": true,
		 "words": "Bleeds last until the target dies, and stack to 3"},
		{"name": "Nicked", "col": 2, "row": 1, "effect": "dot_pct", "value": 20},
		{"name": "Drifter's razor", "col": 3, "row": 1, "effect": "bleed_pct", "value": 25, "also": {"patrol_pct": 10}, "class": "Drifter", "notable": true, "joint": "drifter_bleed", "words": "Bleed damage +25%; every gang takes 10% longer to arrive"},     # the Recruit's bayonet's place (24 Oct, joints B: the Drifter takes bleed)
		{"name": "Blood up", "col": 4, "row": 1, "effect": "bleed_more", "notable": true, "words": "Bleed damage +40%; meds take 30% longer"},
		{"name": "Bleed out", "col": 5, "row": 0, "effect": "cap_bleed_out", "capstone": true,
		 "words": "Bleed damage +50%; a bleed carries to the next man when one dies"},
		{"name": "Scar tissue", "col": 5, "row": 1, "beside": true, "effect": "proof_bleed", "value": 1, "also": {"bleed_res": 20}, "notable": true,
		 "words": "Bleed resist +20%; past the 75% cap, each 1% adds 2% bleed damage"},     # over the cap (12 Oct)
	]},
	{"name": "Knuckles", "element": "physical", "nodes": [
		{"name": "Bare hands", "col": 0, "row": 0, "effect": "physical_pct", "value": 10},
		{"name": "Wraps", "col": 0, "row": 1, "effect": "armour_pct", "value": 5},
		{"name": "Half a brick", "col": 1, "row": 0, "effect": "physical_pct", "value": 15},
		{"name": "Stagger", "col": 2, "row": 0, "effect": "physical_pct", "value": 30, "also": {"stagger": 10}, "notable": true, "words": "Physical damage +30%; your physical hits slow their fire 10%"},
		{"name": "Thick skull", "col": 1, "row": 1, "effect": "armour_pct", "value": 5},
		{"name": "Doorman's knuckles", "col": 3, "row": 0, "effect": "phys_pen", "value": 20, "class": "Doorman", "notable": true, "joint": "doorman_physical", "words": "Your physical damage ignores 20% of their resist"},
		{"name": "Bust them up", "col": 4, "row": 0, "effect": "bust_them_up", "keystone": true, "words": "Physical damage ignores armour and resist; none of it becomes an element"},
		{"name": "Weight behind it", "col": 2, "row": 1, "effect": "physical_pct", "value": 32},     # 12 + Sovereign rings' 20 (24 Oct: its place is the Recruit's half)
		{"name": "Recruit's boots", "col": 3, "row": 1, "effect": "physical_pct", "value": 20, "class": "Recruit", "notable": true, "joint": "recruit_physical", "words": "Physical damage +20%"},     # Sovereign rings' place (24 Oct: the Recruit's half)
		{"name": "Heavy", "col": 4, "row": 1, "effect": "physical_more", "notable": true, "words": "Physical damage +40%; pace −15%"},
		{"name": "Flattened", "col": 5, "row": 0, "effect": "cap_flattened", "capstone": true, "words": "A physical kill halves the fire of everyone on you for 2 seconds"},
		{"name": "Thick-skinned", "col": 5, "row": 1, "beside": true, "effect": "thick_skinned", "notable": true,
		 "words": "Every 10 armour over 200 gives +1% physical damage, up to +50%"},     # over the cap's physical (12 Oct): armour is its resist
	]},
]

## The skill web (3 Nov, docs/design/skill_web.md): one web, the layout generated into web_layout.gd (tools/
## make_skill_web.py), each runner its own path on it. The trees above are the nodes; each layout slot holds one of
## them - a named slot today's node of that name, moved into the slot's tree; an unnamed small one from its pool:
## "class:<tree>" that tree's own smalls in order (the ones no slot names), then fillers; "stat:hp/guard/pace" the
## centre's rings (STAT_SMALLS); "filler" the FILLERS cycle, its resist the region's element (armour elsewhere).
## A tree's nodes: its own source nodes the layout keeps in it, in source order (so their ids, "<Tree>/<index>", as
## they were where nothing moved), then the rest in slot order. Every web node carries "at" (web units, the centre
## at 0,0, y down), "slot", "kind" and "web_region"; the links are WEB_LINKS (ids, both ways).
const FILLERS := [
	{"name": "Hardy", "effect": "hp", "value": 4}, {"name": "Keen", "effect": "damage_pct", "value": 3},
	{"name": "Brisk", "effect": "pace_pct", "value": 2}, {"name": "Mending", "effect": "regen", "value": 0.2},
	{"name": "Tough", "effect": "armour_pct", "value": 4}, {"name": "Lucky", "effect": "loot_pct", "value": 2},
	{"name": "Nimble", "effect": "search_pct", "value": 5}, {"name": "Proofed", "effect": "res", "value": 3},
]
const RES_NAMES := {"fire": "Singed", "frost": "Wrapped up", "poison": "Hardened", "shock": "Insulated", "bleed": "Clotted"}
const STAT_SMALLS := {"stat:hp": {"name": "Hardy", "effect": "hp", "value": 4}, "stat:guard": {"name": "Guarded", "effect": "guard_pct", "value": 3},
	"stat:pace": {"name": "Brisk", "effect": "pace_pct", "value": 2}}     # the centre's two rings (skill_web.md "The centre"): 4 HP, 3% Guard, 2% pace
## The one rule's two gates (skill_web.md version two, 4 Nov: 15/40 to 30/80): a keystone wants this many points spent
## first, a capstone this many.
const KEYSTONE_SPENT := 30
const CAPSTONE_SPENT := 80
## The points (skill_web.md version two, "The rule for spending"): two a level past the class's best, and the camp's
## reward points, every runner's, past and future - each reward counted once: a head's first fall (the campaign's four
## crews, the order's three, the County's four: 11), each of Kev's story papers decrypted (three a beat: 9), the Issue (2).
const POINTS_A_LEVEL := 2
const REWARD_HEAD := 1
const REWARD_KEV := 1
const REWARD_ISSUE := 2
## A lesser node's track once its pool is dry (skill_web.md version two, "Lesser nodes": each takes its track's value -
## the class's smalls first, then these; the balance pass sets them). "el" and "ctl" cycle FILLERS as version one did.
const TRACK_FILLERS := {
	"dmg": [{"name": "Keen", "effect": "damage_pct", "value": 3}],
	"skill": [{"name": "Practised", "effect": "cdr_pct", "value": 2}],
	"def": [{"name": "Hardy", "effect": "hp", "value": 4}, {"name": "Guarded", "effect": "guard_pct", "value": 3}, {"name": "Tough", "effect": "armour_pct", "value": 4}],
	"loot": [{"name": "Lucky", "effect": "loot_pct", "value": 2}, {"name": "Nimble", "effect": "search_pct", "value": 5}],
}
const WL := preload("res://scripts/sim/web_layout.gd")
## The physical floor (31 Oct, the designer: the Recruit's camp poison and his own Tear gas converted every hit, and
## Knuckles' meter - the unconverted share - never moved): a hit's element conversion caps at this in all, shared out as
## before past it, so a tenth of every hit stays physical. Bust them up, the Weed Burner and the Last Orders keep their own.
const CONV_CAP := 0.9
## The hung notables (the lanes' "hang" and the keystones' "at" are the old wheel's, kept as the nodes' history): each
## placed by the slot that names it - every one since the web's version two (4 Nov: the elements' low pairs, the old
## starters stepped down to their start's wheel), with the 18 new names of "The places filled" beside them.
const WEB_EXTRA := {
	"Ordnance": [
		{"name": "Pull the pin", "hang": [1.5, -1], "effect": "grenade_pct", "value": 10, "notable": true},     # was the starter: the first skill comes with the first point (24 Oct, Matt)
		{"name": "Flashbang", "hang": [2.5, -1], "effect": "skill_flashbang", "skill": "flashbang", "notable": true, "words": "Stuns everyone on you for 1.5 seconds; they do 50% less damage to you for 4 seconds"},
		{"name": "Smoke", "hang": [3.5, -1], "effect": "skill_smoke", "skill": "smoke", "notable": true, "words": "Half their shots at you miss for 6 seconds"},
		{"name": "Danger close", "hang": [4.5, -1], "effect": "skill_danger_close", "skill": "danger_close", "notable": true, "words": "×4 blast damage to everyone on you; you lose 10% of max HP"},
		{"name": "Fuse cut short", "effect": "grenade_pct", "value": 25, "notable": true},     # new (4 Nov, skill web version two): the Ordnance track's second notable
		{"name": "Firing blanks", "col": 4, "effect": "live_firing", "keystone": true, "links": ["Detonators"], "xlinks": ["Drill/Tear gas"],
		 "words": "Skills cost 25% less; you do 15% less damage"},
	],
	"Drill": [
		{"name": "Suppressing fire", "hang": [1.5, 1], "effect": "skill_suppressing_fire", "skill": "suppressing_fire", "notable": true, "words": "Everyone on you fires 35% slower for 8 seconds"},
		{"name": "Make ready", "hang": [2.5, 1], "effect": "skill_make_ready", "skill": "make_ready", "notable": true, "words": "+25% damage for your next 10 shots"},
		{"name": "Stand to", "hang": [3.5, 1], "effect": "skill_stand_to", "skill": "stand_to", "notable": true, "words": "Gives 30 energy and takes 2 seconds off every cooldown"},
		{"name": "By the numbers", "effect": "cdr_pct", "value": 10, "notable": true},     # new (4 Nov, skill web version two): the Drill track's second notable
		{"name": "Bulled boots", "effect": "energy_regen_pct", "value": 25, "notable": true},     # new (4 Nov, skill web version two): the Recruit's corner notable
		{"name": "Fire and manoeuvre", "hang": [4.5, 1], "effect": "skill_fire_and_manoeuvre", "skill": "fire_and_manoeuvre", "notable": true, "words": "For 10 seconds, skills cost half and cooldowns pass twice as quickly"},
	],
	"The Pitch": [
		{"name": "Home ground", "hang": [0.5, -1], "effect": "hp", "value": 8, "notable": true},
		{"name": "Good boots", "hang": [2.5, -1], "effect": "pace_pct", "value": 4, "notable": true},
		{"name": "Well stocked", "hang": [4.5, -1], "effect": "med_cap", "value": 1, "notable": true},
		{"name": "Market day", "hang": [1.5, 1], "effect": "sell_pct", "value": 10, "notable": true},
		{"name": "The kettle", "hang": [3.5, 1], "effect": "rest_pct", "value": 15, "notable": true},     # a wound is the Clinic's alone, so the kettle is the rest
		{"name": "Word of mouth", "hang": [4.5, 1], "effect": "word_of_mouth", "notable": true, "words": "A note on each site's first clear"},
		{"name": "Chin down", "effect": "guard_pct", "value": 6, "notable": true},     # new (4 Nov, skill web version two): the inner ring's Guard clusters
		{"name": "Elbows in", "effect": "guard_pct", "value": 6, "notable": true},
		{"name": "Shortcuts", "effect": "pace_pct", "value": 4, "notable": true},      # new: the inner ring's second pace cluster, as Good boots
	],
	"Stripping": [
		{"name": "Nose for parts", "hang": [1.5, -1], "effect": "att_share", "value": 15, "notable": true},     # was the starter: the first skill comes with the first point (24 Oct, Matt)
		{"name": "Hot work", "hang": [2.5, -1], "effect": "skill_hot_work", "skill": "hot_work", "notable": true, "words": "Sets the nearest man burning for ×2 fire damage over 4 seconds"},
		{"name": "Breakdown", "hang": [3.5, -1], "effect": "skill_breakdown", "skill": "breakdown", "notable": true, "words": "The next man you kill drops 20 rounds for your gun"},
		{"name": "Short circuit", "hang": [4.5, -1], "effect": "skill_short_circuit", "skill": "short_circuit", "notable": true, "words": "Shocks everyone on you and stuns them for 1.5 seconds. Your shock damage +30% for 6 seconds."},
		{"name": "Breaker's yard", "col": 4, "effect": "breakers_yard", "keystone": true, "links": ["Workbench"], "xlinks": ["Fencing/Blowtorch"],
		 "words": "1 kill in 3 drops a gun part or a socketable. No plain kit drops."},
	],
	"Fencing": [
		{"name": "Bung", "hang": [1.5, 1], "effect": "skill_bung", "skill": "bung", "notable": true, "words": "Pay 20 tins: the nearest man is stunned for 8 seconds"},
		{"name": "Knock-off kit", "hang": [2.5, 1], "effect": "skill_knock_off_kit", "skill": "knock_off_kit", "notable": true, "words": "+30% gun damage for 8 seconds"},
		{"name": "Back of the van", "hang": [3.5, 1], "effect": "skill_back_of_the_van", "skill": "back_of_the_van", "notable": true, "words": "Puts a grenade in your rig. Once a fight."},
		{"name": "Everything must go", "hang": [4.5, 1], "effect": "skill_everything_must_go", "skill": "everything_must_go", "notable": true, "words": "For 5 seconds, every shot fires twice"},
	],
	"Stalking": [
		{"name": "Still hands", "hang": [1.5, -1], "effect": "first_pct", "value": 5, "notable": true},     # was the starter: the first skill comes with the first point (24 Oct, Matt)     # the skills take the hung notables (24 Oct, milestone 8)
		{"name": "Flush them out", "hang": [2.5, -1], "effect": "skill_flush_them_out", "skill": "flush_them_out", "notable": true, "words": "Pulls the man at the back to the middle; he takes 20% more damage for 8 seconds"},
		{"name": "Go to ground", "hang": [3.5, -1], "effect": "skill_go_to_ground", "skill": "go_to_ground", "notable": true, "words": "Out of sight for 3 seconds: nothing can hit you. Clears bleed and poison on you."},
		{"name": "One for the pot", "hang": [4.5, -1], "effect": "skill_one_for_the_pot", "skill": "one_for_the_pot", "notable": true, "words": "A man on you under 25% HP dies at once. A head takes ×5 damage instead."},
		{"name": "Snare and wait", "col": 4, "effect": "snare_and_wait", "keystone": true, "links": ["Lying up"], "xlinks": ["Snares/Cold snap"],
		 "words": "Each gang arrives one fewer, snared before it fires. −50% damage to the first of each gang."},
	],
	"Snares": [
		{"name": "Collared", "hang": [1.5, 1], "effect": "skill_collared", "skill": "collared", "notable": true, "words": "The nearest man is stunned for 3 seconds: he can't fire"},
		{"name": "Gin trap", "hang": [2.5, 1], "effect": "skill_gin_trap", "skill": "gin_trap", "notable": true, "words": "The next man to join the fight takes ×3 damage and starts to bleed"},
		{"name": "Decoy", "hang": [3.5, 1], "effect": "skill_decoy", "skill": "decoy", "notable": true, "words": "Everyone on you does 30% less damage to you for 6 seconds"},
		{"name": "Net every hole", "hang": [4.5, 1], "effect": "skill_net_every_hole", "skill": "net_every_hole", "notable": true, "words": "Everyone on you is stunned for 2 seconds and starts to bleed"},
	],
	"Muscle": [
		{"name": "Heavy hands", "hang": [1.5, -1], "effect": "damage_pct", "value": 4, "notable": true},     # was the starter: the first skill comes with the first point (24 Oct, Matt)
		{"name": "Headbutt", "hang": [2.5, -1], "effect": "skill_headbutt", "skill": "headbutt", "notable": true, "words": "Hits the nearest man for ×1.5 damage and stuns him for 2 seconds"},
		{"name": "Brace", "hang": [3.5, -1], "effect": "skill_brace", "skill": "brace", "notable": true, "words": "+60% armour for 6 seconds"},
		{"name": "Barred", "hang": [4.5, -1], "effect": "skill_barred", "skill": "barred", "notable": true, "words": "Throws the nearest man out: a kill, but he drops nothing. Not on a head."},
		{"name": "Bin lid", "col": 4, "effect": "bin_lid", "keystone": true, "links": ["Big frame"], "xlinks": ["The door/Hands on"],
		 "words": "Guard of 25% as each gang arrives. −20% damage while it holds."},
	],
	"The door": [
		{"name": "Not on the list", "hang": [1.5, 1], "effect": "skill_not_on_the_list", "skill": "not_on_the_list", "notable": true, "words": "One fewer on you for 10 seconds"},
		{"name": "Shutters down", "hang": [2.5, 1], "effect": "skill_shutters_down", "skill": "shutters_down", "notable": true, "words": "Take 80% less damage for 4 seconds"},
		{"name": "Pat down", "hang": [3.5, 1], "effect": "skill_pat_down", "skill": "pat_down", "notable": true, "words": "The nearest man loses his armour and resists for 10 seconds"},
		{"name": "Chucking-out time", "hang": [4.5, 1], "effect": "skill_chucking_out_time", "skill": "chucking_out_time", "notable": true, "words": "Stuns everyone on you for 2 seconds, then they take 50% more for 6 seconds"},
	],
	"Triage": [
		{"name": "Steady pulse", "hang": [1.5, -1], "effect": "heal_pct", "value": 30, "notable": true},     # was the starter: the first skill comes with the first point (24 Oct, Matt)
		{"name": "Antidote", "hang": [2.5, -1], "effect": "skill_antidote", "skill": "antidote", "notable": true, "words": "Clears poison and burns on you; neither lands again for 8 seconds"},
		{"name": "Adrenaline", "hang": [3.5, -1], "effect": "skill_adrenaline", "skill": "adrenaline", "notable": true, "words": "+25% damage and rate of fire for 8 seconds"},
		{"name": "Major incident", "hang": [4.5, -1], "effect": "skill_major_incident", "skill": "major_incident", "notable": true, "words": "Clears every ailment on you, and you take no wound this run"},
		{"name": "Jab", "col": 4, "effect": "jab", "keystone": true, "links": ["Worst first"], "xlinks": ["Shifts/Defib"],
		 "words": "+20% damage and pace for 8 seconds after a med. A med costs 5% max HP."},
	],
	"Shifts": [
		{"name": "Two sugars", "hang": [1.5, 1], "effect": "skill_two_sugars", "skill": "two_sugars", "notable": true, "words": "Energy refills 50% quicker for 10 seconds"},
		{"name": "Sedative dart", "hang": [2.5, 1], "effect": "skill_sedative_dart", "skill": "sedative_dart", "notable": true, "words": "One man on you sleeps for 4 seconds"},
		{"name": "Strapped up", "hang": [3.5, 1], "effect": "skill_strapped_up", "skill": "strapped_up", "notable": true, "words": "The next hit that would wound you leaves no wound"},
		{"name": "Code blue", "hang": [4.5, 1], "effect": "skill_code_blue", "skill": "code_blue", "notable": true, "words": "Once a run, a hit that would kill you leaves you on 30% HP with every ailment cleared"},
	],
	"Moving on": [
		{"name": "Light feet", "hang": [1.5, -1], "effect": "pace_pct", "value": 11, "notable": true},     # was the starter: the first skill comes with the first point (24 Oct, Matt)
		{"name": "Look lively", "hang": [2.5, -1], "effect": "skill_look_lively", "skill": "look_lively", "notable": true, "words": "+40% pace for 6 seconds"},
		{"name": "Elbow room", "hang": [3.5, -1], "effect": "skill_elbow_room", "skill": "elbow_room", "notable": true, "words": "Everyone on you does 25% less damage to you and takes 15% more from you, for 8 seconds"},
		{"name": "Gone", "hang": [4.5, -1], "effect": "skill_gone", "skill": "gone", "notable": true, "words": "Out of sight for 4 seconds: nothing can hit you. Your next shot does triple damage."},
		{"name": "On a roll", "col": 4, "effect": "on_a_roll", "keystone": true, "links": ["Wiry"], "xlinks": ["Luck/Cut-throat"],
		 "words": "+5% find and loot quality a kill untouched, to +50%. A hit resets it."},
	],
	"Luck": [
		{"name": "Coin toss", "hang": [1.5, 1], "effect": "skill_coin_toss", "skill": "coin_toss", "notable": true, "words": "A 50% chance of double damage for 8 seconds"},
		{"name": "Close shave", "hang": [2.5, 1], "effect": "skill_close_shave", "skill": "close_shave", "notable": true, "words": "The next ailment that would land on you misses"},
		{"name": "Chancer", "hang": [3.5, 1], "effect": "skill_chancer", "skill": "chancer", "notable": true, "words": "The next man you kill always drops something, at +50% loot quality"},
		{"name": "Jackpot", "hang": [4.5, 1], "effect": "skill_jackpot", "skill": "jackpot", "notable": true, "words": "For 8 seconds, every kill takes 2 seconds off every cooldown"},
	],
	"Petrol": [
		{"name": "Accelerant", "hang": [1.5, -1], "effect": "fire_pct", "value": 15, "notable": true},
		{"name": "Oil drum", "hang": [2, 1], "effect": "fire_last_pct", "value": 25, "notable": true, "words": "Burns last 25% longer"},
		{"name": "Flashpoint", "hang": [4.5, -1], "effect": "conv_fire_pct", "value": 10, "notable": true},
		{"name": "Backdraught", "hang": [4, 1], "effect": "backdraught", "notable": true, "words": "A burning one that dies lights the next"},
		{"name": "Forecourt", "effect": "fire_res", "value": 15, "notable": true},     # new (4 Nov, skill web version two): before the keystone
		{"name": "Bonfire night", "effect": "fire_pct", "value": 15, "notable": true},     # new (4 Nov, skill web version two): before the keystone
	],
	"Live": [
		{"name": "Live rail", "hang": [1.5, -1], "effect": "shock_pct", "value": 15, "notable": true},
		{"name": "Capacitor", "hang": [2, 1], "effect": "capacitor", "notable": true, "words": "The first of each gang is shocked"},
		{"name": "Stripped wire", "hang": [4.5, -1], "effect": "conv_shock_pct", "value": 10, "notable": true},
		{"name": "Overload", "hang": [4, 1], "effect": "overload", "notable": true, "words": "A shocked one dies under 20% HP"},
		{"name": "Crossed wires", "effect": "shock_pct", "value": 15, "notable": true},     # new (4 Nov, skill web version two): before the keystone
		{"name": "Fuse box", "effect": "shock_res", "value": 15, "notable": true},     # new (4 Nov, skill web version two): before the keystone
	],
	"Blades": [
		{"name": "Honed", "hang": [1.5, -1], "effect": "bleed_pct", "value": 15, "notable": true},
		{"name": "Serrated", "hang": [2, 1], "effect": "bleed_last_pct", "value": 25, "notable": true, "words": "Bleeds last 25% longer"},
		{"name": "Whetstone", "hang": [4.5, -1], "effect": "conv_bleed_pct", "value": 10, "notable": true},
		{"name": "Arterial", "hang": [4, 1], "effect": "arterial", "notable": true, "words": "Bleed does ×2 for its first second"},
		{"name": "Paper cuts", "effect": "dot_pct", "value": 15, "notable": true},     # new (4 Nov, skill web version two): before the keystone
		{"name": "Shiv", "effect": "bleed_pct", "value": 15, "notable": true},     # new (4 Nov, skill web version two): before the keystone
	],
	"Knuckles": [
		{"name": "Knuckleduster", "hang": [1.5, -1], "effect": "physical_pct", "value": 15, "notable": true},
		{"name": "Shin pads", "hang": [2, 1], "effect": "armour_pct", "value": 8, "notable": true},
		{"name": "Low blow", "hang": [4.5, -1], "effect": "first_pct", "value": 15, "notable": true},
		{"name": "Floored", "hang": [4, 1], "effect": "floored", "notable": true, "words": "A staggered one loses a second of fire"},
		{"name": "Sucker punch", "effect": "physical_pct", "value": 15, "notable": true},     # new (4 Nov, skill web version two): before the keystone
		{"name": "Bare-knuckle", "effect": "armour_pct", "value": 8, "notable": true},     # new (4 Nov, skill web version two): before the keystone
	],
	"The cold": [
		{"name": "Chilblains", "hang": [1.5, -1], "effect": "frost_pct", "value": 15, "notable": true},
		{"name": "Deep freeze", "hang": [2, 1], "effect": "frost_last_pct", "value": 25, "notable": true, "words": "Chills last 25% longer"},
		{"name": "Sleet", "hang": [4.5, -1], "effect": "conv_frost_pct", "value": 10, "notable": true},
		{"name": "Brittle", "hang": [4, 1], "effect": "brittle", "notable": true, "words": "+30% physical to a frozen one"},
		{"name": "Black ice", "effect": "frost_pct", "value": 15, "notable": true},     # new (4 Nov, skill web version two): before the keystone
		{"name": "Brass monkeys", "effect": "frost_res", "value": 15, "notable": true},     # new (4 Nov, skill web version two): before the keystone
	],
	"The Rat Man": [
		{"name": "Strychnine", "hang": [1.5, -1], "effect": "poison_pct", "value": 15, "notable": true},
		{"name": "Takes its time", "hang": [2, 1], "effect": "poison_last_pct", "value": 25, "notable": true, "words": "Poison lasts 25% longer"},
		{"name": "Tainted", "hang": [4.5, -1], "effect": "conv_poison_pct", "value": 10, "notable": true},
		{"name": "Catching", "hang": [4, 1], "effect": "catching", "notable": true, "words": "A poisoned one that dies doses the next"},
		{"name": "Nest", "effect": "poison_res", "value": 15, "notable": true},     # new (4 Nov, skill web version two): before the keystone
		{"name": "Rat run", "effect": "poison_pct", "value": 15, "notable": true},     # new (4 Nov, skill web version two): before the keystone
	],
}
static var _WEB: Dictionary = _web_build_all()
static var TREES: Array = _WEB["trees"]
static var ELEMENT_TREES: Array = _WEB["elements"]
## The paragon ring (slice 4, web.md §6): the board's five rows as RING_NODES nodes round the outside of the web, RING_STEP
## degrees apart, cycling damage, HP, resists, find, tins; the five at the classes' angles are entries. A node holds up
## to RING_STACK paragon points (the board had no top); a point costs one. The crew's, as the board was.
const RING_TREE := "The ring"
const RING_NODES := 30
const RING_STEP := 12.0
const RING_STACK := 10
const RING_ENTRY_ANGLES := [-90.0, -30.0, 30.0, 90.0, 150.0, -150.0]     # the classes' angles on the skill web (tools/make_skill_web.py CLASSES; 3 Nov, merge 47: were the wheel's)
const RING_R := 1120.0             # the ring's radius in web units (the skill web version two, 4 Nov: the layout's Paragon ring; was 500)
static var RING: Dictionary = _ring_build()


static func _ring_build() -> Dictionary:
	var nodes := []
	for i in range(RING_NODES):
		var row: Dictionary = PARAGON_BOARD[(i + floori(i / 5.0)) % PARAGON_BOARD.size()]     # the cycle slips a row every five: the entries aren't all one row
		var angle: float = RING_ENTRY_ANGLES[0] + i * RING_STEP     # from the Poacher's angle: every class's angle lands on a node
		var a: float = angle if angle <= 180.0 else angle - 360.0
		nodes.append({"name": row["name"], "effect": "paragon", "key": row["key"], "value": row["pct"], "ring": a, "at": [a, 0.0], "stack": RING_STACK,
			"words": row["words"], "entry": a in RING_ENTRY_ANGLES, "links": [(i + RING_NODES - 1) % RING_NODES, (i + 1) % RING_NODES]})
	return {"name": RING_TREE, "ring": true, "nodes": nodes}


## The web built from the layout (see FILLERS' note): {"trees", "elements", "ids" (every web id in slot order),
## "of_slot" slot -> id, "links" id -> [ids], "starts" class -> id, "dropped" [today's names no slot holds]}.
static func _web_build_all() -> Dictionary:
	var srcs: Array = []
	for t in TREES_SRC + ELEMENT_TREES_SRC:
		var st: Dictionary = t.duplicate(true)
		for ex in WEB_EXTRA.get(st["name"], []):
			st["nodes"].append(ex.duplicate(true))         # the hung notables, after the lane's own (their ids follow)
		srcs.append(st)
	var named := {}                                        # name -> slot
	for s in WL.SLOTS:
		if str(s["name"]) != "":
			named[str(s["name"])] = s
	var trees := {}                                        # name -> the built tree
	var order: Array = []
	var smalls := {}                                       # tree -> its own smalls no slot names, in order
	var src_of := {}                                       # name -> [tree, node]
	for st in srcs:
		var t: Dictionary = st.duplicate()
		t["nodes"] = []
		trees[st["name"]] = t
		order.append(st["name"])
		smalls[st["name"]] = []
		for nd in st["nodes"]:
			src_of[str(nd["name"])] = [st["name"], nd]
			var big: bool = nd.get("notable", false) or nd.get("keystone", false) or nd.get("capstone", false) or nd.has("skill") or nd.has("hang")
			if not named.has(str(nd["name"])) and not big:
				smalls[st["name"]].append(nd)
	# each slot's node: [tree, node] - a named one found, a pool's taken in turn
	var pool_at := {}                                      # tree -> the next of its own smalls
	var fill_at := {}                                      # tree -> the fillers made, for the cycle
	var got := {}                                          # slot -> [tree, node]
	var dropped: Array = []
	var track_at := {}                                     # track -> the track fillers made, for the cycle
	for s in WL.SLOTS:
		var tn: String = str(s["tree"])
		var nd: Dictionary
		var pool: String = str(s["pool"])
		var track: String = str(s.get("track", ""))
		if str(s["name"]) != "":
			assert(src_of.has(str(s["name"])), "a web slot names a node that isn't there: " + str(s["name"]))
			nd = Dictionary(src_of[str(s["name"])][1]).duplicate(true)
			if tn == "":
				tn = str(src_of[str(s["name"])][0])        # version two: a named node stays in its own tree, so its id is its source's
		elif pool.begins_with("class:") and int(pool_at.get(pool.substr(6), 0)) < smalls[pool.substr(6)].size():
			var own: String = pool.substr(6)
			nd = Dictionary(smalls[own][int(pool_at.get(own, 0))]).duplicate(true)
			pool_at[own] = int(pool_at.get(own, 0)) + 1
		elif STAT_SMALLS.has(pool):
			nd = Dictionary(STAT_SMALLS[pool]).duplicate()
			nd["filler"] = true
		elif TRACK_FILLERS.has(track):
			var tf: Array = TRACK_FILLERS[track]
			nd = Dictionary(tf[int(track_at.get(track, 0)) % tf.size()]).duplicate()
			track_at[track] = int(track_at.get(track, 0)) + 1
			nd["filler"] = true
		else:
			var k: int = order.find(tn) % 6
			var f: Dictionary = FILLERS[(int(fill_at.get(tn, 0)) + k * 3) % FILLERS.size()].duplicate()
			fill_at[tn] = int(fill_at.get(tn, 0)) + 1
			if f["effect"] == "res":
				var el: String = str(trees[tn].get("element", ""))
				f = {"name": "Tough", "effect": "armour_pct", "value": 4} if el == "" or el == "physical" else {"name": RES_NAMES[el], "effect": "%s_res" % el, "value": 3}
			nd = f
			nd["filler"] = true
		for k in ["links", "xlinks", "hang", "link_at", "entry", "wheel", "beside", "notable", "keystone", "capstone"]:
			nd.erase(k)
		var kind: String = str(s["kind"])
		if kind == "notable" or kind == "start" or kind == "skill":
			nd["notable"] = true
		elif kind == "keystone":
			nd["keystone"] = true
		elif kind == "capstone":
			nd["capstone"] = true
		if kind == "start":
			nd["start"] = true
		nd["at"] = [float(s["at"][0]), float(s["at"][1])]
		nd["slot"] = str(s["slot"])
		nd["kind"] = kind
		nd["web_region"] = str(s["region"])
		nd["theme"] = str(s.get("theme", ""))
		nd["region"] = tn
		got[str(s["slot"])] = [tn, nd]
	# each tree's nodes: its own source nodes kept in it, in source order, then the rest in slot order
	var by_tree := {}
	for sl in got:
		var tn: String = got[sl][0]
		if not by_tree.has(tn):
			by_tree[tn] = []
		by_tree[tn].append(sl)
	var of_slot := {}
	for st in srcs:
		var tn: String = st["name"]
		var t: Dictionary = trees[tn]
		var here: Array = by_tree.get(tn, [])
		var used := {}
		for nd0 in st["nodes"]:
			var hit := ""
			for sl in here:
				if not used.has(sl) and str(got[sl][1]["name"]) == str(nd0["name"]) and not got[sl][1].get("filler", false):
					hit = sl
					break
			if hit != "":
				used[hit] = true
				t["nodes"].append(got[hit][1])
				of_slot[hit] = "%s/%d" % [tn, t["nodes"].size() - 1]
			elif src_of.get(str(nd0["name"]), [""])[0] == tn and not named.has(str(nd0["name"])) and not _taken(got, str(nd0["name"]), tn):
				dropped.append("%s/%s" % [tn, nd0["name"]])
		for sl in here:
			if not used.has(sl):
				t["nodes"].append(got[sl][1])
				of_slot[sl] = "%s/%d" % [tn, t["nodes"].size() - 1]
	var links := {}
	for s in WL.SLOTS:
		links[of_slot[str(s["slot"])]] = []
	for l in WL.LINKS:
		var a: String = of_slot[str(l[0])]
		var b: String = of_slot[str(l[1])]
		if not (b in links[a]):
			links[a].append(b)
		if not (a in links[b]):
			links[b].append(a)
	var ids: Array = []
	for s in WL.SLOTS:
		ids.append(of_slot[str(s["slot"])])
	var starts := {}
	for c in WL.STARTS:
		starts[c] = of_slot[str(WL.STARTS[c])]
	var out_t: Array = []
	var out_e: Array = []
	for st in TREES_SRC:
		out_t.append(trees[st["name"]])
	for st in ELEMENT_TREES_SRC:
		out_e.append(trees[st["name"]])
	return {"trees": out_t, "elements": out_e, "ids": ids, "of_slot": of_slot, "links": links, "starts": starts, "dropped": dropped}


## A small of `tn` that a class pool took (it sits in some slot of its own tree): not dropped.
static func _taken(got: Dictionary, nm: String, tn: String) -> bool:
	for sl in got:
		if got[sl][0] == tn and str(got[sl][1]["name"]) == nm and not got[sl][1].get("filler", false):
			return true
	return false


static func _web_link(nodes: Array, a: int, b: int) -> void:
	assert(a >= 0 and b >= 0, "a web link to nothing")
	if not (b in nodes[a]["links"]):
		nodes[a]["links"].append(b)
	if not (a in nodes[b]["links"]):
		nodes[b]["links"].append(a)


## --- the web's API (BUILD47_COMMON.md: the Training screen's and the tests'; static, the layout's) ---

## Every node id on the web, in the layout's slot order (not the paragon ring).
static func web_ids() -> Array:
	return _WEB["ids"]


static func _web_node(id: String) -> Dictionary:
	var t := tree_named(id.get_slice("/", 0))
	var i := int(id.get_slice("/", 1))
	if t.is_empty() or i < 0 or i >= t.get("nodes", []).size():
		return {}
	return t["nodes"][i]


## A node's place in web units (the centre 0,0, 12 o'clock up: y negative). The ring's at RING_R.
static func web_at(id: String) -> Vector2:
	var n := _web_node(id)
	if n.has("ring"):
		return Vector2.from_angle(deg_to_rad(float(n["ring"]))) * RING_R
	var a: Array = n.get("at", [0.0, 0.0])
	return Vector2(float(a[0]), float(a[1]))


## small / notable / keystone / capstone / start ("" off the web).
static func web_kind(id: String) -> String:
	return str(_web_node(id).get("kind", ""))


## The ids joined to it (both ways).
static func web_links(id: String) -> Array:
	return _WEB["links"].get(id, [])


## The layout's region: "centre", "el:<element tree>" or "class:<Class>".
static func web_region(id: String) -> String:
	return str(_web_node(id).get("web_region", ""))


## The node's track (version two): "dmg" (the class's attack track), "ctl" (its other), "skill", "def" (staying up),
## "loot" (finds), "start", "el" (an element's column), "centre"; "" off the web.
static func web_theme(id: String) -> String:
	return str(_web_node(id).get("theme", ""))


## The layout's slot name ("c0:rifleman", "e5:tip", "h0.2").
static func web_slot(id: String) -> String:
	return str(_web_node(id).get("slot", ""))


## A class's start: the node with its skill, owned from level 1.
static func web_start(cls: String) -> String:
	return str(_WEB["starts"].get(cls, ""))


## A slot's node id, or "".
static func web_of_slot(slot: String) -> String:
	return str(_WEB["of_slot"].get(slot, ""))


## Today's nodes (BUILD47) no slot holds: "Tree/Name", dropped from the web.
static func web_dropped() -> Array:
	return _WEB["dropped"]


const AFFINITY := {"Drifter": ["fire", "bleed"], "Doorman": ["bleed", "physical"], "Poacher": ["poison", "frost"], "Scrapper": ["shock", "fire"], "Paramedic": ["shock", "frost"], "Recruit": ["physical", "poison"]}     # joints B (24 Oct, Matt): every element between the two classes that join it (the Recruit Knuckles and the Rat Man)     # the Recruit: Knuckles and Blades, his joints (24 Oct)

## The joints (9 Oct, docs/design/trees.md): one notable split across a class tree and an element tree of the
## class's pair, in column 4 of both. Each half works alone; both trained, the joint closes and its payoff
## holds. `lane` is the class tree's place on the Training screen: the first tree joins lane 2's element, the second
## lane 4's.
const JOINTS := [
	{"key": "drifter_fire", "class": "Drifter", "tree": "Moving on", "element_tree": "Petrol", "words": "With an SMG, your hits set them burning; burning gangs take 25% more SMG damage"},
	{"key": "drifter_bleed", "class": "Drifter", "tree": "Luck", "element_tree": "Blades", "words": "A bleeding man you kill rolls his drop's rarity twice and keeps the better"},
	{"key": "scrapper_shock", "class": "Scrapper", "tree": "Stripping", "element_tree": "Live", "words": "Every hit from an improvised gun shocks the target"},
	{"key": "scrapper_fire", "class": "Scrapper", "tree": "Fencing", "element_tree": "Petrol", "words": "A kill on a burning man always drops something; the Fence pays 20% more"},
	{"key": "poacher_poison", "class": "Poacher", "tree": "Stalking", "element_tree": "The Rat Man", "words": "Your poison on the first of each gang goes on at full stacks"},
	{"key": "poacher_frost", "class": "Poacher", "tree": "Snares", "element_tree": "The cold", "words": "Every gang arrives chilled for 2 seconds and one man short"},
	{"key": "paramedic_shock", "class": "Paramedic", "tree": "Shifts", "element_tree": "Live", "words": "Every med you use shocks the man you're fighting for 3 seconds"},
	{"key": "paramedic_frost", "class": "Paramedic", "tree": "Triage", "element_tree": "The cold", "words": "Chilled men do 30% less damage to you; meds heal 20% more while any are chilled"},
	{"key": "doorman_bleed", "class": "Doorman", "tree": "Muscle", "element_tree": "Blades", "words": "With a shotgun or melee, every hit opens a bleed; bleeding gangs do 20% less damage to you"},
	{"key": "doorman_physical", "class": "Doorman", "tree": "The door", "element_tree": "Knuckles", "words": "With a shotgun or melee in hand, the gangs on you fire 25% slower"},
	{"key": "recruit_physical", "class": "Recruit", "tree": "Ordnance", "element_tree": "Knuckles", "words": "Hits and throws from your skills do 25% more damage"},
	{"key": "recruit_poison", "class": "Recruit", "tree": "Drill", "element_tree": "The Rat Man", "words": "Hits and throws from your skills poison the men they hit"},
]
const JOINT_COL := 3               # the column both halves sit in (the fourth)


static func joint(key: String) -> Dictionary:
	for j in JOINTS:
		if j["key"] == key:
			return j
	return {}


## A class's joint in a tree: the class tree's ("Moving on") or the element tree's ("Petrol"), or {}.
static func joint_in(cls: String, tree_name: String) -> Dictionary:
	for j in JOINTS:
		if j["class"] == cls and (j["tree"] == tree_name or j["element_tree"] == tree_name):
			return j
	return {}


## Insurance: the Fence holds the paper on the kit for a run. Dies, and the
## kit comes back to the Yard's stash. A share of what's worn, by depth.
const INSURE_RATE := 0.15

## The bench's crafting, paid in notes: times the item's tier and its rarity + 1.
## The bench's crafting, in cash: a price × the item's level × (rarity + 1).
## Perfection is dear and bottomless; that's the late game's cash sink.
## "bump" is in notes: the crews' thing, not the Fence's.
const CRAFT := {
	# 20 Oct (Matt, the canvas "Fiat – The playtest batch"): padlocks on the affixes, and two jobs for what isn't locked -
	# the same affixes with new figures, or new affixes in their place. "values" is priced by the unlocked affixes'
	# tiers, both by LOCK_PRICE more a padlock. First figures; the balance pass sets them.
	"values": {"name": "Re-roll values", "cash": 25, "words": "The same affixes, new figures: a chance to go up a tier, a smaller one to go down"},
	"affixes": {"name": "Re-roll affixes", "cash": 40, "words": "New affixes in their place; the count stays the same"},
	"add": {"name": "Add an affix", "cash": 100, "words": "Adds one affix and raises the rarity one step"},
	"socket": {"name": "Cut a socket", "cash": 80, "words": "Adds a socket, up to %d"},
	"strip": {"name": "Strip the affixes", "cash": 10, "words": "Removes every affix; it becomes Common, worth less"},
	"bump": {"name": "Raise the item's level", "notes": 10, "words": "+3 item levels, so the lowest affix tiers stop rolling; up to item level base tier + 20"},
	# 25 Oct (the review, Matt's go: the endgame stall): past the raise, a level at a time, on any piece but a mythic -
	# the base's damage and armour grow with it; scrap by item level (TEMPER_GROW past ILVL_GROW_FROM), tins a share of its sale
	"temper": {"name": "Temper", "scrap": 100, "cash": 0, "words": "+1 item level past Item level +3: its damage, armour and flat lines grow as a deeper drop's; not a mythic, a rig, a pack or a charm"},     # scrap 20 to 100, priced by item level; tins a share of its sale (the second review)
}
const GREED_QUALITY := 0.10          # greed after the clear (25 Oct): loot quality a gang that comes after it, for the rest of the run
const GREED_QUANTITY := 0.05         # and quantity
const TEMPER_GROW := 1.035             # a temper's scrap, 1.10 to 1.035 (the second review): this much dearer an item level past ILVL_GROW_FROM, as income grows: the climb's pace is its price
const TEMPER_CASH := 4.0              # 8 back to 4 (25 Oct, the fourth pass: at 8 the tins priced tempering out and the scrap piled up behind it; the cash held waits for the Issue, docs/design/the_issue.md); a temper's tins: four times the piece's worth
const TEMPER_PAST_WEAR := 3           # a piece's first three tempers don't raise the level to wear it (Matt, 25 Oct: ease "reach 50 or stall")
const LOCK_PRICE := 1.0               # a padlock adds this share of a re-roll's price (20 Oct)
const LOCKS := 1                      # padlocks at the Bench; the Pitch's Two locks adds one (Matt: "2 locks with one as an upgrade")
const BUMP_LEVELS := 3
const BUMP_CAP := 20

## Crafting (34): one material, scrap, a count in hand. Found on a search
## (SCRAP_SEARCH of them a handful), made by scrapping an item at the Bench
## (its value over SCRAP_PER_POUND; a ditch on a run gave it too, till 27 Oct). The Build column:
## a standard box of rounds for scrap; the grades, scrap plus the box below
## ("from"); a med, scrap plus the one below; an improvised gun of a type for
## scrap by its tier, Common, firing nails whatever it is; a grenade, scrap
## plus the element's socketable. Costs are untuned until the pass.
const SCRAP_PER_POUND := 24         # 20 to 24 (12 Oct, the read: 7.1-9.0 crafts an hour against 7, the Scrapper 10.7-11.8 against 8)
const SCRAP_SEARCH := 0.35          # scrap off a search, with SCRAP_PER_POUND for about seven crafts an hour
const SCRAP_HANDFUL := [5, 10]      # a handful of scrap: its low and high
const BUILD_BOX := 8                # a standard box of any type you have a gun for
const BUILD_GRADE := 15             # a grade, with the box below
const BUILD_MED := 8                # a med, times its tier, with the one below (painkillers and a bandage: scrap alone)
const BUILD_GUN := 40               # an improvised gun, times its tier
const BUILD_GRENADE := 12           # with the element's socketable; the nail bomb scrap alone

## Events: something happens on a run, once at most, EVENT_ODDS of runs (1 Nov, docs/design/run_events.md: run events in
## the fight). An event is a family (its rules), its slots filled from pools matched to the moment, and the choices the
## family offers. It comes in the lull between gangs, never mid-volley, at the first lull from EVENT_WINDOW's seconds
## in; never two a run, never the same family two runs running. A threat is a fight with no pause; everything else
## stops the gang clock while the choice waits in the panel under the scene. Runs nobody watches use the standing
## orders. The convoy, trapped and cache events folded into A threat passing, Someone in need and A locked thing.
const EVENT_ODDS := 0.3
const EVENT_WINDOW := [15.0, 70.0]  # seconds in, when it's due: it comes at the first lull from then
const EVENT_SLICE := ["need", "threat", "locked", "trader"]     # the slice's four (1 Nov): "the events themselves play well"
const EVENT_SLICE_MIN := 0.6        # of a site's events at least, the slice's four (fix 46, E7): the six scaled to fit
const EVENT_ORDER := ["need", "threat", "locked", "trader", "danger", "stash", "body", "wreck", "broadcast", "weather"]     # the families, in the standing orders' order (the canvas's board 4; BUILD46-E the other six after the slice's four)
## A family: its name (the panel's head, the orders' row), whether it's a threat (a fight, no pause), its weight on the
## dice, and its weights by site kind, zone, weather, night (a multiplier each; 1 where unnamed) and the site's level
## (`level`: so much more a level). `from_run`: not before that many runs; a threat never before CONVOY_FROM_RUN.
const EVENT_FAMILIES := {
	"need": {"name": "Someone in need", "weight": 1.0, "kind": {"medical": 1.5, "estate": 1.2}, "weather": {"Rain": 1.2}},
	"locked": {"name": "A locked thing", "weight": 1.0, "kind": {"retail": 1.3, "civic": 1.3, "military": 1.5}, "level": 0.02},
	"threat": {"name": "A threat passing", "threat": true, "weight": 0.8, "kind": {"farm": 1.5}, "zone": [1.3, 1.0, 1.0, 1.1], "night": 1.6},     # from CONVOY_FROM_RUN
	"trader": {"name": "A trader", "weight": 0.7, "weather": {"Fog": 1.4}, "night": 0.5, "from_run": 2},
	# BUILD46-E (2 Nov): the other six families
	"danger": {"name": "A dangerous place", "weight": 0.7, "kind": {"civic": 1.3, "medical": 1.3, "estate": 1.2}, "weather": {"Rain": 1.3}, "level": 0.02},
	"stash": {"name": "A haul with a catch", "weight": 0.8, "kind": {"retail": 1.2, "estate": 1.3}, "night": 1.2},
	"body": {"name": "A body", "weight": 0.6, "kind": {"military": 1.5, "medical": 1.3}, "from_run": 3},
	"wreck": {"name": "A wreck", "weight": 0.7, "kind": {"farm": 1.2, "retail": 1.4}, "zone": [0.8, 1.0, 1.2, 1.4]},
	"broadcast": {"name": "A broadcast", "weight": 0.5, "night": 1.4, "from_run": 3},
	"weather": {"name": "The weather turning", "weight": 0.5, "weather": {"Fog": 0.5, "Rain": 0.7}},
}
## Each site's kind, by index (the pools lean on it): farm, retail, estate, civic, military, medical.
const SITE_KIND := ["farm", "retail", "farm", "estate", "retail", "retail", "civic", "retail", "civic", "civic", "medical", "military"]
## The pools: what fills a family's slots. Each entry: its words ("w"), its weight (1 unnamed), and its leanings - "zones"
## (only there), "kind" (a multiplier by site kind), "night", "weather". A person's entry carries their pronoun ("he" or
## "she"); a need's "what" is a pin (the HP risk; "it" names what slips) or a hurt (a med).
const EVENT_POOLS := {
	"need_who": [
		{"w": "A farmhand", "he": "he", "zones": [0], "kind": {"farm": 3.0}},
		{"w": "A woman in wellies", "he": "she", "zones": [0]},
		{"w": "An old boy with a dog lead", "he": "he", "zones": [0]},
		{"w": "A lad in a tracksuit", "he": "he", "zones": [1]},
		{"w": "A woman from the flats", "he": "she", "zones": [1], "kind": {"estate": 2.0}},
		{"w": "A delivery driver", "he": "he", "zones": [1, 2], "kind": {"retail": 1.5}},
		{"w": "A security guard", "he": "he", "zones": [2, 3], "kind": {"retail": 1.5, "civic": 1.5}},
		{"w": "A cashier", "he": "she", "zones": [1, 2], "kind": {"retail": 2.0}},
		{"w": "A man in a suit", "he": "he", "zones": [2], "kind": {"civic": 2.0}},
		{"w": "A soldier", "he": "he", "zones": [3], "kind": {"military": 4.0}},
		{"w": "A nurse", "he": "she", "zones": [3], "kind": {"medical": 4.0}},
		{"w": "A lorry driver", "he": "he", "zones": [3], "kind": {"retail": 2.0}},
	],
	"need_what": [
		{"w": "a fallen beam", "it": "the beam", "pin": true, "kind": {"farm": 2.0}},
		{"w": "a fence panel", "it": "the panel", "pin": true, "zones": [0], "kind": {"farm": 1.5}},
		{"w": "a collapsed shelf unit", "it": "the shelving", "pin": true, "kind": {"retail": 2.5}},
		{"w": "a car on its side", "it": "the car", "pin": true, "zones": [1, 2, 3], "kind": {"estate": 2.0}},
		{"w": "rubble", "it": "the rubble", "pin": true},
		{"w": "a vending machine", "it": "the machine", "pin": true, "zones": [2, 3], "kind": {"civic": 1.5, "medical": 1.5}},
		{"w": "a bad cut to the leg", "pin": false, "weight": 0.8},
		{"w": "a gash across the arm", "pin": false, "weight": 0.6},
		{"w": "a broken ankle", "pin": false, "weight": 0.6, "weather": {"Rain": 1.5}},
	],
	"locked_what": [
		{"w": "A council cabinet", "art": "cabinet", "kind": {"civic": 2.0, "estate": 1.5}},
		{"w": "A tin shed", "art": "shutter", "door": true, "zones": [0], "kind": {"farm": 2.5}},
		{"w": "A garage, shuttered", "art": "shutter", "door": true, "zones": [1, 2], "kind": {"estate": 2.5}},
		{"w": "A shop's cash office", "art": "shutter", "door": true, "zones": [1, 2, 3], "kind": {"retail": 3.0}},
		{"w": "A works van", "art": "van", "kind": {"retail": 1.2}},
		{"w": "A drugs cupboard", "art": "cabinet", "zones": [3], "kind": {"medical": 5.0}},
		{"w": "An armoury cage", "art": "cabinet", "zones": [3], "kind": {"military": 5.0}},
		{"w": "A safe in a back office", "art": "safe", "zones": [2, 3], "kind": {"civic": 3.0}},
	],
	# BUILD46-E (2 Nov): the other six families' slots. "art": the prop's picture (art/events/<art>_shut / _open.png).
	"danger_what": [
		{"w": "A flooded cellar", "it": "the water", "zones": [0, 1], "kind": {"farm": 1.5}, "weather": {"Rain": 2.0}},
		{"w": "A grain store with its roof sagging", "it": "the roof", "zones": [0], "kind": {"farm": 3.0}},
		{"w": "A floor that's half gone", "it": "the floor", "kind": {"retail": 1.5, "civic": 1.5}},
		{"w": "A basement that smells of gas", "it": "the gas", "zones": [1, 2, 3], "kind": {"estate": 2.0}},
		{"w": "A stairwell with its treads rotten", "it": "the stairs", "zones": [1, 2, 3], "kind": {"estate": 1.5, "civic": 1.5}},
		{"w": "A ward with its ceiling down", "it": "the ceiling", "zones": [3], "kind": {"medical": 4.0}},
		{"w": "A store hut with the floor rotted through", "it": "the floor", "zones": [3], "kind": {"military": 4.0}},
	],
	"danger_prize": [
		{"w": "a holdall"}, {"w": "a locker at the back"}, {"w": "something glinting at the bottom"},
		{"w": "a rucksack hung on a hook", "zones": [1, 2, 3]}, {"w": "a toolbox left on a shelf", "kind": {"farm": 2.0, "retail": 1.5}},
	],
	"stash_what": [
		{"w": "A holdall in plain sight"}, {"w": "A rucksack under a car", "zones": [1, 2, 3], "kind": {"estate": 1.5}},
		{"w": "A pile of boxes under a tarp", "kind": {"farm": 2.0, "retail": 1.5}}, {"w": "A sports bag stuffed in a bin", "zones": [1, 2]},
		{"w": "A crate on a pallet, lid on", "kind": {"retail": 2.0, "military": 2.0}}, {"w": "A cool box under a hedge", "zones": [0]},
	],
	# the catch: "trip" costs HP, "watched" brings the next gang now
	"stash_catch": [
		{"w": "a tripwire", "catch": "trip"}, {"w": "a rotten board under it", "catch": "trip"},
		{"w": "someone watching it", "catch": "watched"}, {"w": "a lad keeping an eye on it", "catch": "watched", "zones": [1, 2]},
	],
	"body_who": [
		{"w": "A courier in a hi-vis"}, {"w": "A lad with a rucksack", "zones": [0, 1]}, {"w": "A woman in walking boots", "zones": [0]},
		{"w": "A man in a council fleece", "zones": [1, 2], "kind": {"civic": 2.0}}, {"w": "Someone in a stab vest", "zones": [2, 3]},
		{"w": "A man in fatigues", "zones": [3], "kind": {"military": 4.0}}, {"w": "A woman in scrubs", "zones": [3], "kind": {"medical": 4.0}},
	],
	"wreck_what": [
		{"w": "A tractor in a ditch", "zones": [0], "kind": {"farm": 3.0}}, {"w": "A burnt-out car"},
		{"w": "A van on its side", "zones": [1, 2, 3], "kind": {"retail": 1.5}}, {"w": "A bus with no windows", "zones": [1, 2]},
		{"w": "A crashed lorry", "zones": [2, 3], "kind": {"retail": 2.0, "civic": 1.5}},
		{"w": "An army truck, stripped once already", "zones": [3], "kind": {"military": 5.0}},
		{"w": "An ambulance with its doors open", "zones": [3], "kind": {"medical": 5.0}},
	],
	"radio_what": [
		{"w": "A radio in a parked car, still on"}, {"w": "A wind-up radio on a windowsill", "zones": [0, 1]},
		{"w": "A scanner hissing in a guard's hut", "zones": [2, 3], "kind": {"civic": 2.0, "military": 3.0}},
		{"w": "A phone in the gutter, a voice on it", "zones": [1, 2, 3]}, {"w": "A tannoy crackling into life", "zones": [2, 3], "kind": {"retail": 2.0, "medical": 2.0}},
	],
	# the weather turning: "loot" (loot quality, %) and "harder" (the gangs' damage, %) for the rest of the run if you press on;
	# "not": no turn into the weather the site already has; "alone": only the zone's line that reads as its own sentence
	"turn": [
		{"w": "Fog rolls in", "loot": 40, "harder": 20, "not": "Fog"},
		{"w": "The rain comes on hard", "loot": 30, "harder": 15, "not": "Rain"},
		{"w": "The light's going early", "loot": 50, "harder": 25, "alone": true},
		{"w": "A wind gets up", "loot": 25, "harder": 10},
		{"w": "The power comes back on", "loot": 35, "harder": 20, "zones": [1, 2, 3], "alone": true},
	],
}
## Someone in need: Pull them out (NEED_FREE_S; a pin's HP risk at the odds below, a hurt's med from the rig) for a runner
## at the Yard (the `promised` one: they turn up looking for work); Take the bag (NEED_BAG_S: a find, and they remember it:
## a thread flag, no cost yet); Leave them. The clean odds: NEED_CLEAN, less a night's and weather's share and the share
## under half HP, between NEED_CLEAN_MIN and NEED_CLEAN_MAX.
const NEED_FREE_S := 15.0
const NEED_BAG_S := 5.0
const NEED_CLEAN := 0.75
const NEED_CLEAN_NIGHT := 0.1
const NEED_CLEAN_WEATHER := 0.05
const NEED_CLEAN_LOW_HP := 0.15     # under half HP
const NEED_CLEAN_MIN := 0.3
const NEED_CLEAN_MAX := 0.9
const NEED_SLIP := 0.2              # the pin slips: this share of max HP (never the last of it)
## A locked thing: Force it (LOCK_FORCE_S, and the noise: the next gang LOCK_NOISE_S sooner), or Shoot the lock off
## (LOCK_SHOOT_S and LOCK_ROUNDS from the gun in hand's magazines): a find a tier up (the cache's, as it paid); Leave it.
const LOCK_FORCE_S := 10.0
const LOCK_NOISE_S := 30.0
const LOCK_SHOOT_S := 5.0
const LOCK_ROUNDS := 10
const LOCK_RARITY := 0.5            # the find's rarity over the site's (the cache's)
## A threat passing, dogs (the convoy's fold): a pack the size of the next gang (DOGS_MORE more), each DOG_HP of a man's HP
## and DOG_DPS of his fire, the site gang's damage types and resists - a normal gang's difficulty at the site, as specced
## (the fix round: 0.6 / 0.8 and a bite through armour won 29 of 30 the gang would lose) - carrying nothing; DOG_XP of
## a man's XP a dog. They stand DOGS_CLOSE_S in the lull (Get out now, or Stand and fight), then come on. Fought off, the
## site's next gang comes DOGS_PUSH_S later. The odds on their face: DOG_READS dry fights through the real fight code.
const DOG_READS := 6              # the face's odds: dry fights of the dogs (the fix round)
const DOG_READ_STEP := 1.0      # the live fight's own tick: a coarser one read marginal packs short
const DOG_READ_MAX_S := 180.0     # a dogs' fight longer than this reads as lost (as fifteen minutes is for the odds)
const DOGS_MORE := 0               # the pack: the next gang's size (the fix round: a normal gang's difficulty, as specced)
const DOG_HP := 1.0
const DOG_DPS := 1.0
const DOG_XP := 0.5
const DOGS_MAX := 5
const DOGS_CLOSE_S := 10.0
const DOGS_PUSH_S := 20.0
const EVENT_FIGHT_AT := 0.8         # a threat's standing order "at the run's odds" with no odds read at the gate
## A trader, the Scrap man (recurring): he takes scrap from the pack's stacks for run-only buffs, one of each a visit.
## Standing: a camp's trades with him, any class (trader_standing); at each step his shelf grows. A buff lasts the run.
const TRADERS := {"scrap_man": {"name": "The Scrap man"}, "vagabond": {"name": "The Vagabond"}}     # the Vagabond: BUILD46-E
const TRADER_SHELF := [
	{"key": "plate", "price": 15, "armour_pct": 10.0},     # +armour this run (10-20% of one stat, the design's guardrail)
	{"key": "mags", "price": 10},                          # the worn guns' magazines topped up, rounds of his own
	{"key": "held", "price": 20, "held_s": 30.0},          # the next gang held up
	{"key": "bandage", "price": 5},                        # a bandage (BUILD40E 4); from the first step the first a visit is on the house
]
## The steps (trades, counted as a visit ends: one step a visit at most): 3, a bandage on the house a visit; 10, 33% off
## everything; 25, his good plate (+20% armour).
const TRADER_STEPS := [3, 10, 25]
const TRADER_STEP_OFF := 1.0 / 3.0
const TRADER_GOOD_PLATE := 20.0
## The standing orders (for runs nobody's watching: repeat runs, away, the bot): a family's choices, the first its default
## - a player's (1 Nov, the designer's call on the fix round: player-like defaults for everyone, the bot too); a family not
## listed defaults to "leave". A watched run always asks.
const EVENT_ORDERS := {
	"need": ["help_cheap", "leave", "bag"],
	"threat": ["odds_80", "out", "odds_run", "always"],
	"locked": ["force", "leave", "shoot"],
	"trader": ["all", "leave", "armour30"],
	# BUILD46-E (2 Nov): the other six, their first a player's (as the slice's: the designer's player-like defaults)
	"danger": ["careful", "leave", "go"],
	"stash": ["check", "take", "leave"],
	"body": ["search", "pockets", "leave"],
	"wreck": ["strip", "cut", "leave"],
	"broadcast": ["listen", "short", "leave"],
	"weather": ["press_80", "leave", "press", "home"],
}
const NEED_HELP_AT := 0.7           # "Help if it's a med or 70% clean": a pin's clean chance the order frees at
const CONVOY_FROM_RUN := 5         # no threat passing before the sixth run (17 Oct, Matt: a convoy on the first Allotments run used both starter bandages)
## BUILD46-E (2 Nov, docs/design/run_events.md: the rest of the run events). Every figure a draft for the pass, inside the
## design's guardrails: an event's best choice about a third of a run's loot (a find or two, a tier up at best), a rival
## crew x1.5 a normal gang's difficulty, a trader's buff 10-20% of one stat for the run.
## The odds on a risky choice move as the pin's do (NEED_CLEAN_NIGHT, _WEATHER, _LOW_HP), between NEED_CLEAN_MIN and _MAX.
## A dangerous place: Go in (DANGER_S, DANGER_CLEAN; the bad outcome DANGER_HURT of max HP, never the last of it), or Go
## in carefully (DANGER_CAREFUL_S at DANGER_CAREFUL_CLEAN): a find a tier up (LOCK_RARITY, the locked thing's); Leave it.
const DANGER_S := 15.0
const DANGER_CLEAN := 0.6
const DANGER_CAREFUL_S := 35.0
const DANGER_CAREFUL_CLEAN := 0.9
const DANGER_HURT := 0.25
## A stash with a catch: Take it (STASH_TAKE_S; STASH_CATCH the catch: a trip, STASH_TRIP of max HP, or watched, the
## next gang now), or Check it first (STASH_CHECK_S, the catch found and cleared): STASH_FINDS finds; Leave it.
const STASH_TAKE_S := 3.0
const STASH_CHECK_S := 20.0
const STASH_CATCH := 0.4
const STASH_TRIP := 0.2
const STASH_FINDS := 2
## A body: Search it (BODY_S: a find, and BODY_CLUE a clue to what killed them - the site's next gang tougher, BODY_GANG
## its HP and fire and BODY_GANG notes a man for its trouble, warned; or the site's head's weakness, BODY_HEAD_CUT off
## his HP the next run he's out, a thread); Go through the pockets (BODY_POCKETS_S: BODY_TINS a man's tins); Leave it.
const BODY_S := 10.0
const BODY_POCKETS_S := 3.0
const BODY_CLUE := 0.5
const BODY_GANG := 1.3
const BODY_GANG_NOTES := 2
const BODY_HEAD_CUT := 0.15
const BODY_TINS := 4.0
## A wreck: Strip it (WRECK_S: WRECK_SCRAP scrap), or Cut it open (WRECK_CUT_S and WRECK_CUT_SCRAP scrap from the pack for
## the torch: the site's material, WRECK_MAT of it, and a find a tier up); Leave it.
const WRECK_S := 20.0
const WRECK_SCRAP := [15, 25]
const WRECK_CUT_S := 8.0
const WRECK_CUT_SCRAP := 10
const WRECK_MAT := [2, 4]
## A broadcast: Listen (RADIO_S: a tip), or Catch the end (RADIO_SHORT_S: RADIO_SHORT_TIP a tip); Leave it. A tip is a
## thread: a stash at another open site on a later run there (the site's next run has it, no catch, STASH_FINDS finds a
## tier up), or, TIP_TRADER of them, the Vagabond's whereabouts (the next run's event is him). A tip goes stale after
## TIP_RUNS runs.
const RADIO_S := 20.0
const RADIO_SHORT_S := 8.0
const RADIO_SHORT_TIP := 0.5
const TIP_TRADER := 0.25
const TIP_RUNS := 12
## The weather turning: Press on (the turn's loot quality and the gangs' damage for the rest of the run: its "loot" and
## "harder" in EVENT_POOLS.turn), Head home (out now with the pack), or Let it pass (the family's "Leave it").
const WEATHER_PRESS_AT := 0.8        # the default order presses on at the run's odds this or better
## A rival crew (A threat passing, beside the dogs: BUILD46-E; the designer, 2 Nov: a normal fight, it can kill the
## runner, odds shown, Get out now always open): the next gang's size, each CREW_HP and CREW_DPS of a man of the site's gang
## (x1.5 a normal gang's difficulty), a man's XP; seen off, what they carry - CREW_NOTES notes a man, or (CREW_FIND) a find
## a tier up. CREW_SHARE of threats by zone are a crew, none before CREW_FROM_RUN.
const CREW_HP := 1.25
const CREW_DPS := 1.2
const CREW_NOTES := 3
const CREW_FIND := 0.4
const CREW_SHARE := [0.25, 0.4, 0.5, 0.6]
const CREW_FROM_RUN := 8
## Threads (BUILD46-E): what carries between runs, each list THREAD_MAX at most (the oldest goes). A bag taken from someone
## in need, or a crew seen off (CREW_ROBBED of them), leaves a robbed crew: while one's out there a threat's weight is
## x ROBBED_THREAT and ROBBED_BACK of threats are them, back for you (a rival crew, at their own words). A freed person
## is a runner to come (`promised`, as the slice); a trader remembers you (his standing, his own words).
const THREAD_MAX := 3
const CREW_ROBBED := 0.5
const ROBBED_THREAT := 1.5
const ROBBED_BACK := 0.6
## The Vagabond (the second trader, BUILD46-E): he takes tins (the run's) and the rebuild materials (the pack's stacks).
## His shelf: VAG_GEAR pieces of gear at the site's tier (VAG_UP of them one above), priced off its worth
## (the Fence's x VAG_SELL_X, fix 46); now and then (VAG_RUMOUR) a rumour - a tip, as a
## broadcast's - for VAG_RUMOUR_MAT materials, or VAG_RUMOUR_TINS a man's tins with none. Standing, as the Scrap man's
## (TRADER_STEPS): 3, a third piece; 10, 33% off; 25, the shelf a tier up and a rumour every visit. Gear off his shelf
## goes into the pack (it comes home, as a find); a rumour's tip is a thread.
const VAG_FROM_RUN := 4
const VAG_GEAR := 2
const VAG_UP := 0.25
const VAG_SELL_X := 1.5            # his gear's price: the Fence's for it x this (fix 46, E1); his 33% off still over it
const VAG_RUMOUR := 0.35
const VAG_RUMOUR_MAT := 3
const VAG_RUMOUR_TINS := 3.0
const VAG_SHARE := 0.5              # of traders, once he's about, the Vagabond
## The first gun (17 Oct, Matt's two playtests: with no gun a save spiralled, with a shotgun the Gamekeeper fell at level 2):
## a Garden Centre clear leaves one of these, plain, with a box of its rounds, while there's no gun anywhere and none has
## come home yet - the same step for every save, and for the bot; kept by a full pack, given again if the run loses it.
const FIRST_GUN_SITE := 1
const FIRST_GUNS := [["Primary", "Farmer's shotgun"], ["Primary", "Pump shotgun"], ["Secondary", "Old revolver"]]
const START_STASH_BANDAGES := 5    # a new camp's stash (17 Oct, Matt: "add 4 or 5 to the stash on a new save"): no meds to buy till the Gamekeeper opens the Clinic

## The Fence's mate (9 Oct) sells a loose unique for notes, a new one every MATE_RUNS. (His contracts went for the
## exchange, 28 Oct: EXCHANGE_* by the Issue's figures below.)
const MATE_RUNS := 5
const MATE_NOTES := 400            # a unique from the mate, times the tier

## The Dial (the map until 13 Oct, Matt): the endgame's own tree. A point for every new depth cleared on
## any site past the first; spent on how the sites run, for every site.
## The map at thirty-six (endgame part 4, 7 Oct): three columns of twelve - the
## sites, the crews, the air - each a chain (a node needs the one before it
## taken) with four notables and a keystone, fed by the same point a new depth.
## `column` 0-2, in chain order; `max` the ranks; `notable`; `keystone`;
## `figures` the panel's and the strip's figure at each rank (rank 0 first).
const ATLAS := [
	# the sites
	{"key": "picked_over", "column": 0, "name": "Local stock", "max": 3, "words": "A site's own things make up more of its finds: 50%, then 67%, then 83% (33% without)",
		"sum": "Own finds", "figures": ["33% of finds", "50% of finds", "67% of finds", "83% of finds"], "sentence": "A site's own things turn up more of the time."},
	{"key": "deeper_pockets", "column": 0, "name": "Deeper pockets", "max": 3, "words": "Searches 10% quicker a rank",
		"sum": "Searches", "figures": ["as they come", "10% quicker", "20% quicker", "30% quicker"], "sentence": "The picking-over goes quicker, on every site."},
	{"key": "quiet_roads", "column": 0, "name": "Quiet roads", "max": 3, "words": "Gangs come 10% later a rank",
		"sum": "Gangs", "figures": ["as they come", "10% later", "20% later", "30% later"], "sentence": "The next gang takes longer to arrive, on every site."},
	{"key": "after_dark", "column": 0, "name": "After dark", "max": 1, "notable": true, "words": "Every run counts as night; night's loot quality bonus +50%",
		"sum": "Night", "figures": ["by the clock", "every site, rarer"], "sentence": "Every run counts as night, and night's loot quality bonus is 50% bigger (+75%). Night's pace −20% still applies."},
	{"key": "second_look", "column": 0, "name": "Second look", "max": 2, "words": "+1 find every other search; every search at rank 2",
		"sum": "Searches find", "figures": ["as they come", "+1 every other", "+1 every search"], "sentence": "The picking-over finds more: another every other search, then every search."},
	{"key": "worn_in", "column": 0, "name": "Worn in", "max": 2, "words": "A picked-over site's crates come back 50% quicker a rank",
		"sum": "Crates back", "figures": ["one in 3 min", "one in 2 min", "one in 90 s"], "sentence": "A picked-over site's crates come back sooner."},     # the trickle (27 Oct): was the wear's two hours
	{"key": "easy_pickings", "column": 0, "name": "Easy pickings", "max": 2, "words": "Drops +10% a rank",
		"sum": "Drops", "figures": ["as they come", "+10%", "+20%"], "sentence": "More of what they carry comes off them, on every site."},
	{"key": "local_knowledge", "column": 0, "name": "Local knowledge", "max": 1, "notable": true, "words": "Finds roll one loot tier higher",
		"sum": "Bases", "figures": ["by the level", "a tier up"], "sentence": "You know where the good stuff is: finds roll one loot tier higher, on every site."},
	{"key": "short_cuts", "column": 0, "name": "Short cuts", "max": 2, "words": "Pace +5% a rank",
		"sum": "Pace", "figures": ["as it is", "+5%", "+10%"], "sentence": "The runner knows the way: quicker on every site."},
	{"key": "open_ground", "column": 0, "name": "Open ground", "max": 1, "notable": true, "words": "One fewer on you at a time",
		"sum": "On you", "figures": ["as they come", "one fewer"], "sentence": "One fewer on you at a time, on every site."},
	{"key": "every_penny", "column": 0, "name": "Every tin", "max": 2, "words": "Tins +10% a rank",
		"sum": "Tins", "figures": ["as they come", "+10%", "+20%"], "sentence": "Every run brings a little more home."},
	{"key": "lie_of_the_land", "column": 0, "name": "The lie of the land", "max": 1, "keystone": true, "words": "A signal never rolls more than 3 levels under your reach",
		"sum": "Low rolls", "figures": ["as they fall", "3 under at worst"], "sentence": "You know the ground: a signal never rolls more than 3 levels under your reach."},     # 18 Oct (Matt, Q2): it opened a depth no screen sets any more
	# the crews
	{"key": "paid_in_notes", "column": 1, "name": "Paid in notes", "max": 3, "words": "Every kill carries 1 more note a rank",
		"sum": "Notes", "figures": ["as they come", "+1 a kill", "+2 a kill", "+3 a kill"], "sentence": "Every kill carries a note more."},
	{"key": "two_of_everything", "column": 1, "name": "Two of everything", "max": 1, "words": "A crew's head drops 2 of his uniques, not 1",
		"sum": "Heads", "figures": ["drop one", "drop two"], "sentence": "A crew's head drops 2 of his uniques, not 1."},
	{"key": "heads_up", "column": 1, "name": "Heads up", "max": 2, "words": "A head's price in notes 33% less a rank",
		"sum": "Heads cost", "figures": ["full price", "33% less", "67% less"], "sentence": "The crews' heads come cheaper."},
	{"key": "full_strength", "column": 1, "name": "Full strength", "max": 1, "notable": true, "words": "A crew's head comes at full strength 2 levels sooner",
		"sum": "Full strength", "figures": ["as it stands", "2 levels sooner"], "sentence": "The heads come at full strength 2 levels sooner, their charms with them."},
	{"key": "bounties", "column": 1, "name": "Bounties", "max": 2, "words": "A head's notes +50% a rank",
		"sum": "Head's notes", "figures": ["as they come", "half again", "doubled"], "sentence": "The crews' heads hold more of the old paper."},
	{"key": "wages", "column": 1, "name": "Wages", "max": 3, "words": "XP +10% a rank",
		"sum": "XP", "figures": ["as it comes", "+10%", "+20%", "+30%"], "sentence": "Every kill teaches a little more."},
	{"key": "heavy_crews", "column": 1, "name": "Heavy crews", "max": 1, "notable": true, "words": "One more on you at a time; kills pay 50% more tins and XP",
		"sum": "On you", "figures": ["as they come", "+1 on you, pay +50%"], "sentence": "One more on you at a time, and every kill pays 50% more in tins and XP."},
	{"key": "their_own_kit", "column": 1, "name": "Their own kit", "max": 2, "words": "A kill drops something 10% more often a rank",
		"sum": "Kill drops", "figures": ["as they come", "+10%", "+20%"], "sentence": "More of them are carrying something when they go down."},
	{"key": "marked_men", "column": 1, "name": "Marked men", "max": 1, "notable": true, "words": "Damage +25% to the first of each gang",
		"sum": "The first", "figures": ["as they come", "+25% damage"], "sentence": "The first of each gang is marked: 25% more damage to him."},
	{"key": "long_memory", "column": 1, "name": "Long memory", "max": 1, "words": "Pay a head's price once a level; after that he comes out free at that level",
		"sum": "Head's price", "figures": ["every run", "once a level"], "sentence": "Pay a head's price at a level once; he comes out for nothing at that level after."},
	{"key": "head_start", "column": 1, "name": "Heads roll", "max": 1, "notable": true, "words": "A head beaten at full strength pays a point on the Dial",
		"sum": "Heads pay", "figures": ["nothing", "a point at full strength"], "sentence": "Beat a crew's head at full strength and the Dial gains a point."},
	{"key": "lorrys_route", "column": 1, "name": "The lorry's route", "max": 1, "keystone": true, "words": "A signal can roll up to 2 levels past your reach, not 1",
		"sum": "The decoder", "figures": ["to reach +1", "to reach +2"], "sentence": "You know the lorry's route: half the time, a signal can roll 1 level further past your reach."},     # 15 Oct, Matt: was the old convoy two sooner
	# the air (9 Oct, docs/design/juicing.md §7): the juicing tree
	{"key": "good_reception", "column": 2, "name": "Good reception", "max": 2, "words": "Every craft at the Radio costs 15% less a rank",
		"sum": "Crafts", "figures": ["full price", "15% less", "30% less"], "sentence": "Every craft at the Radio comes cheaper."},
	{"key": "clear_air", "column": 2, "name": "Clear air", "max": 1, "words": "Name a code the Radio never hears",
		"sum": "Never heard", "figures": ["every code", "one code filtered"], "sentence": "Name one code you know: the Radio never rolls it again. Change it at the Radio."},
	{"key": "booster", "column": 2, "name": "Booster", "max": 3, "words": "Every code's reward bonus 10% bigger a rank",
		"sum": "Codes pay", "figures": ["as they are", "+10%", "+20%", "+30%"], "sentence": "Every code brings a little more home, on every site."},
	{"key": "held_frequency", "column": 2, "name": "Held frequency", "max": 1, "words": "Hold costs half at the Radio",
		"sum": "Hold", "figures": ["full price", "half price"], "sentence": "Keeping one code and rolling the rest costs half."},     # 21 Oct: was the codes through a move, the move gone
	{"key": "long_wave", "column": 2, "name": "Long wave", "max": 1, "notable": true, "words": "+1 code on every site",
		"sum": "Codes a site", "figures": ["by the level", "one more"], "sentence": "Every site carries one more code."},
	{"key": "tip_offs", "column": 2, "name": "Tip-offs", "max": 2, "words": "Loot quality +5% a rank",
		"sum": "Quality", "figures": ["as it comes", "+5%", "+10%"], "sentence": "Word of what's where: rarer finds on every site."},
	{"key": "strong_signal", "column": 2, "name": "Strong signal", "max": 2, "words": "A roll lands its top tier more; then one past the usual top",
		"sum": "Tiers", "figures": ["as it falls", "the top more often", "one past the usual top"], "sentence": "A rolled code lands its top tier 3 times in 4; at the second rank it can land 1 tier past the usual top."},
	{"key": "early_word", "column": 2, "name": "Early code", "max": 2, "words": "Call in costs 25% less a rank",
		"sum": "Call in", "figures": ["full price", "25% less", "half price"], "sentence": "Calling a code in comes cheaper."},
	{"key": "relay", "column": 2, "name": "Relay", "max": 1, "notable": true, "words": "Pick a code you know: it runs on every site with codes",
		"sum": "Standing", "figures": ["none", "one code"], "sentence": "Name a code you know: it stands on every site with codes, at that site's top tier, over its own."},
	{"key": "bent", "column": 2, "name": "Bent", "max": 1, "notable": true, "words": "Twist lands tier IV more often: 57%, not 40%",
		"sum": "Twist", "figures": ["as it falls", "tier IV 57%"], "sentence": "A Twist lands a tier IV code more often: 57% of the time, not 40%."},
	{"key": "whole_band", "column": 2, "name": "The whole band", "max": 1, "keystone": true, "words": "Pick a second code to run on every site",
		"sum": "Standing", "figures": ["one code", "two codes"], "sentence": "Two standing codes on every site with codes."},
]
const ATLAS_COLUMNS := ["The sites", "The crews", "The codes"]
## The Map's web (22 Oct, docs/design/web_map_pitch.md §1): the atlas's three lanes as three regions off a centre,
## pathed, not gated (ATLAS_GATES went). A region: a spine (its first node the entry, its last the keystone) and two
## branches off the spine's first node, back into its last; a filler between the nodes of a branch, each one small
## stat that counts as a share of a ranked node's figure ("as" and "ranks": atlas_level reads them).
const MAP_REGIONS := [
	{"name": "The sites", "column": 0, "angle": 180.0, "spine": ["picked_over", "second_look", "local_knowledge", "lie_of_the_land"],
	 "branches": [["quiet_roads", "open_ground", "short_cuts", "worn_in"], ["deeper_pockets", "easy_pickings", "after_dark", "every_penny"]],
	 "fillers": [["deeper_pockets", 0.3, "Searches 3% quicker", "Quick feet"], ["quiet_roads", 0.3, "Gangs come 3% later", "Back ways"], ["easy_pickings", 0.3, "Drops +3%", "Light fingers"], ["every_penny", 0.3, "Tins +3%", "Loose change"]]},
	{"name": "The crews", "column": 1, "angle": 0.0, "spine": ["paid_in_notes", "their_own_kit", "marked_men", "lorrys_route"],
	 "branches": [["heads_up", "two_of_everything", "full_strength", "long_memory", "head_start"], ["wages", "bounties", "heavy_crews"]],
	 "fillers": [["wages", 0.3, "XP +3%", "Lessons"], ["paid_in_notes", 1.0, "+1 note a kill", "Pocket money"], ["every_penny", 0.3, "Tins +3%", "Loose change"], ["easy_pickings", 0.3, "Drops +3%", "Light fingers"]]},
	{"name": "The codes", "column": 2, "angle": 90.0, "spine": ["good_reception", "clear_air", "long_wave", "whole_band"],
	 "branches": [["tip_offs", "booster", "strong_signal", "bent"], ["early_word", "held_frequency", "relay"]],
	 "fillers": [["good_reception", 0.333, "Crafts −5%", "Spare valves"], ["booster", 0.3, "Codes pay +3%", "Gain"], ["early_word", 0.2, "Call in −5%", "Short dial"], ["tip_offs", 0.4, "Loot quality +2%", "Hearsay"]]},
]
const MAP_KEYSTONE_POINTS := 10    # a region's keystone wants this many points in the region (the lanes' last gate was 14; the review: pathing alone put it three ranks in)
const MAP_SPINE_STEP := 1.3
const MAP_BRANCH_Y := 2.4
static var ATLAS_ALL: Array = []       # the atlas's nodes and the Map web's fillers: what atlas_of reads (filled as MAP_WEB builds, below it in order)
static var MAP_WEB: Array = _map_build()


## The Map's web built: a tree a region, its nodes the atlas's by key with "at" and "links"; the fillers made here and
## added to ATLAS_ALL as atlas nodes of one rank.
static func _map_build() -> Array:
	var out := []
	ATLAS_ALL = ATLAS.duplicate()
	for rg in MAP_REGIONS:
		var t := {"name": rg["name"], "map": true, "column": rg["column"], "angle": rg["angle"], "nodes": []}
		var nodes: Array = t["nodes"]
		var by_key := {}
		var spine: Array = rg["spine"]
		for i in range(spine.size()):
			var a: Dictionary = atlas_of(spine[i])
			assert(not a.is_empty(), "no atlas node " + str(spine[i]))
			nodes.append({"name": a["name"], "key": spine[i], "at": [i * MAP_SPINE_STEP, 0.0], "links": [], "notable": a.get("notable", false) or a.get("keystone", false), "keystone": a.get("keystone", false), "entry": i == 0})
			by_key[spine[i]] = nodes.size() - 1
			if i > 0:
				_web_link(nodes, by_key[spine[i - 1]], by_key[spine[i]])
		var fcount := 0
		for b in range(rg["branches"].size()):
			var side: float = -1.0 if b == 0 else 1.0
			var branch: Array = rg["branches"][b]
			var last: int = by_key[spine[0]]
			for j in range(branch.size()):
				var x: float = 0.65 + j * MAP_SPINE_STEP
				var f := _map_filler(rg, t, [x - 0.65 + (0.3 if j == 0 else 0.0), side * (MAP_BRANCH_Y / 2.0 if j == 0 else MAP_BRANCH_Y)], fcount)
				fcount += 1
				_web_link(nodes, last, f)
				var a: Dictionary = atlas_of(branch[j])
				assert(not a.is_empty(), "no atlas node " + str(branch[j]))
				nodes.append({"name": a["name"], "key": branch[j], "at": [x, side * MAP_BRANCH_Y], "links": [], "notable": a.get("notable", false)})
				by_key[branch[j]] = nodes.size() - 1
				_web_link(nodes, f, by_key[branch[j]])
				last = by_key[branch[j]]
			# the branch's end back into the spine's last node (the keystone) by a filler
			var f2 := _map_filler(rg, t, [(spine.size() - 1) * MAP_SPINE_STEP - 0.3, side * MAP_BRANCH_Y / 2.0], fcount)
			fcount += 1
			_web_link(nodes, last, f2)
			_web_link(nodes, f2, by_key[spine[spine.size() - 1]])
		out.append(t)
	return out


static func _map_filler(rg: Dictionary, t: Dictionary, at: Array, n: int) -> int:
	var fl: Array = rg["fillers"][n % rg["fillers"].size()]
	var key := "%s_f%d" % [str(rg["spine"][0]), n]
	var words: String = str(fl[2])
	ATLAS_ALL.append({"key": key, "column": int(rg["column"]), "name": str(fl[3]), "max": 1, "filler": true, "as": str(fl[0]), "ranks": float(fl[1]),
		"words": words, "sum": words, "figures": ["as it is", words], "sentence": words + ", on every site."})
	t["nodes"].append({"name": str(fl[3]), "key": key, "at": at, "links": [], "filler": true})
	return t["nodes"].size() - 1


## A Map web node's id for an atlas key, or "".
static func map_id(key: String) -> String:
	for t in MAP_WEB:
		for i in range(t["nodes"].size()):
			if t["nodes"][i]["key"] == key:
				return "%s/%d" % [t["name"], i]
	return ""


static func map_node(id: String) -> Dictionary:
	for t in MAP_WEB:
		if t["name"] == id.get_slice("/", 0):
			var i := int(id.get_slice("/", 1))
			return t["nodes"][i] if i < t["nodes"].size() else {}
	return {}


static var _map_links := {}
static func map_links() -> Dictionary:
	if not _map_links.is_empty():
		return _map_links
	var out := {}
	for t in MAP_WEB:
		for i in range(t["nodes"].size()):
			var ia := "%s/%d" % [t["name"], i]
			out[ia] = []
			for j in t["nodes"][i]["links"]:
				out[ia].append("%s/%d" % [t["name"], int(j)])
	_map_links = out
	return out


## The Pitch's web (web_map_pitch.md §2): a building a region, its five columns' picks as forks along the spine (a
## column's two picks link to both of the column before: one or the other, as now) and its ranks a chain past them.
const YARD_PICK_Y := 1.3
static var YARD_WEB: Array = _yard_build()


static func _yard_build() -> Array:
	var out := []
	for k in range(YARD.size()):
		var b: Dictionary = YARD[k]
		var t := {"name": b["name"], "yard": b["key"], "angle": -90.0 + k * 45.0, "nodes": []}
		var nodes: Array = t["nodes"]
		var prev: Array = []
		for c in range(b["picks"].size()):
			var now: Array = []
			for side in range(2):
				var pk: Dictionary = b["picks"][c][side]
				nodes.append({"name": pk["name"], "pick": pk["id"], "yard": b["key"], "col": c, "side": "a" if side == 0 else "b", "at": [c * 1.2, (-YARD_PICK_Y if side == 0 else YARD_PICK_Y)], "links": [], "notable": true, "entry": c == 0})
				now.append(nodes.size() - 1)
			for i in prev:
				for j in now:
					_web_link(nodes, i, j)
			prev = now
		for r in range(1, 6):
			nodes.append({"name": ("Rank %d" % r) if r < 5 else "Rank 5 and on", "rank": r, "yard": b["key"], "at": [b["picks"].size() * 1.2 + (r - 1) * 0.9, 0.0], "links": [], "keystone": r == 5})
			var i := nodes.size() - 1
			if r == 1:
				for j in prev:
					_web_link(nodes, j, i)
			else:
				_web_link(nodes, i - 1, i)
		out.append(t)
	return out


static func yard_node(id: String) -> Dictionary:
	for t in YARD_WEB:
		if t["name"] == id.get_slice("/", 0):
			var i := int(id.get_slice("/", 1))
			return t["nodes"][i] if i < t["nodes"].size() else {}
	return {}


static var _yard_links := {}
static func yard_links() -> Dictionary:
	if not _yard_links.is_empty():
		return _yard_links
	var out := {}
	for t in YARD_WEB:
		for i in range(t["nodes"].size()):
			var ia := "%s/%d" % [t["name"], i]
			out[ia] = []
			for j in t["nodes"][i]["links"]:
				out[ia].append("%s/%d" % [t["name"], int(j)])
	_yard_links = out
	return out


## A map node by key, or {} - the atlas's and the Map web's fillers (ATLAS_ALL, once built).
static func atlas_of(key: String) -> Dictionary:
	for a in (ATLAS_ALL if not ATLAS_ALL.is_empty() else ATLAS):
		if a["key"] == key:
			return a
	return {}

## Traits: what a runner turns up with. Two turn up when one dies; you pick.
const TRAITS := [
	{"name": "Lucky", "words": "Loot quality +10%", "rarity": 0.1},
	{"name": "Heavy-handed", "words": "Damage +8%, pace −5%", "damage": 1.08, "pace": 0.95},
	{"name": "Wary", "words": "Gangs come 20% later", "patrol": 1.2},
	{"name": "Greedy", "words": "Tins +15%, max HP −10%", "cash": 1.15, "hp": 0.9},
	{"name": "Tough", "words": "Max HP +15%", "hp": 1.15},
	{"name": "Light", "words": "Pace +8%", "pace": 1.08},
	{"name": "Careful", "words": "Meds heal 20% more", "heal": 1.2},
	{"name": "Nosy", "words": "Searches 15% quicker", "search": 0.85},
]
const TRAIT_WORDS := {"Lucky": "a lucky one", "Heavy-handed": "heavy-handed", "Wary": "a wary one", "Greedy": "a greedy one",
	"Tough": "a tough one", "Light": "light on their feet", "Careful": "careful with the kit", "Nosy": "nosy"}
const RESPEC_CASH := 50

## Classes - what the runner was, before: chosen in the Caravan, changed in the Yard for free.
## Each is a set of rules on how the sim plays - what a weapon does, not what
## can be fitted - with a cost to go with it. Numbers are multipliers the sim
## reads by key; "words" is what the Barracks says.
const CLASSES := [
	{"name": "Poacher", "words": "Damage +40% to the first of each gang; every gang takes 25% longer to arrive",
		"short": [["+40% to the first", true], ["Gangs 25% later", true]],     # the card's lines (14 Oct, Training's cards): the words a tooltip
		"first_pct": 40, "patrol": 1.25},          # the −10% max HP went (Matt, 9 Oct, the twenty-sixth read: the slowest class to the Bank two passes running, 2.2 and 2.8 h against the Drifter's 0.9)
	{"name": "Doorman", "words": "Damage +15%; armour +20%; pace −10%",
		"short": [["+15% damage", true], ["+20% armour", true], ["−10% pace", false]],
		"damage": 1.15, "armour": 1.2, "pace": 0.9},
	{"name": "Paramedic", "words": "Damage +10%; meds heal 50% more and one is used by itself under 40% HP; healing past full HP becomes Guard",
		"short": [["+10% damage", true], ["Meds heal +50%", true], ["Auto-meds, Guard", true]],
		"damage": 1.1, "heal": 1.5, "auto_med": true, "overheal": true},     # overheal (12 Oct, docs/design/shields.md)     # +10% damage (Matt, 9 Oct, the twenty-eighth read: the slowest class to the Bank, 2.3 h on five reads)            # the pass (6 Oct): the −10% damage went; the slowest to the Bank by two hours
	{"name": "Scrapper", "words": "Searches 25% quicker; loot quantity +10%; improvised guns do 20% more damage",
		"short": [["Search 25% quicker", true], ["+10% loot quantity", true], ["+20% improvised", true]],
		"search": 0.75, "loot": 0.10, "improvised": 1.2},     # improvised +20% (12 Oct, Matt's playtest: the only class with no damage in its line; the bot's Scrappers ended on an SMG, their improvised nodes idle)             # searches 30% to 25% faster, the loot back to +10% (12 Oct: +5% loot read 9.3 crafts an hour against 8 - the search pace is the source)              # +15% to +10% (Matt, 9 Oct, the twenty-sixth read: 8.4 crafts of scrap an hour against its band's 8)              # the pass (6 Oct): the −5% damage went; second slowest to the Bank
	{"name": "Recruit", "words": "Skills cost 10% less; energy refills 20% quicker",
		"short": [["Skills 10% cheaper", true], ["+20% energy gain", true]],
		"skill_cost": 0.9, "energy_regen": 1.2},     # the sixth class (24 Oct, milestone 8): the Quartermaster's
	{"name": "Drifter", "words": "Damage +5%; one fewer on you at a time; pace +10%",
		"short": [["+5% damage", true], ["One fewer on you", true], ["+10% pace", true]],
		"damage": 1.05,     # +15% to +5% (Matt, 9 Oct, the twenty-eighth read: with its HP back, the fastest to the Bank at 0.6 h)
		 "contact": -1, "pace": 1.1},     # the −15% max HP went (Matt, 9 Oct, the twenty-fifth read: level 32, 272 HP and 8-10 runs an hour at hour 4 against the Doorman's 41, 354 and 25; the lorry beaten on 2 of 4 reads with the bot fixed). Before that:      # +15% damage (Matt, 8 Oct): last to the lorry on every read since the engine, 24 h merged on the twenty-second against 4-13 h for the rest; +10% read 16.1 h on three reads, six minutes over the gate
]


## A tree's own links ("links" indices in it) as ids, both ways: the paragon ring's (the web's are WEB_LINKS).
static var _tree_links := {}
static func tree_links(t: Dictionary) -> Dictionary:
	var key: String = str(t.get("name", ""))
	if _tree_links.has(key):
		return _tree_links[key]
	var out := {}
	var nodes: Array = t.get("nodes", [])
	for i in range(nodes.size()):
		var ia := "%s/%d" % [key, i]
		if not out.has(ia):
			out[ia] = []
		for j in nodes[i].get("links", []):
			var ib := "%s/%d" % [key, int(j)]
			if not (ib in out[ia]):
				out[ia].append(ib)
	_tree_links[key] = out
	return out


## Every link in one dictionary: the web's and the paragon ring's.
static var _web_all := {}
static func web_links_all() -> Dictionary:
	if not _web_all.is_empty():
		return _web_all
	var out: Dictionary = Dictionary(_WEB["links"]).duplicate(true)
	var rl := tree_links(RING)
	for a in rl:
		out[a] = Array(rl[a]).duplicate()
	_web_all = out
	return out


## "Tree/Name" to the node's id, or "".
static func node_id_named(path: String) -> String:
	var t := tree_named(path.get_slice("/", 0))
	var nm := path.get_slice("/", 1)
	for i in range(t.get("nodes", []).size()):
		if str(t["nodes"][i].get("name", "")) == nm:
			return "%s/%d" % [t["name"], i]
	return ""


## A paragon ring's entry (a node at a class's angle): a point goes there first.
static func web_entry(nd: Dictionary) -> bool:
	return nd.get("entry", false)


## A class's own two trees with the centre's between: its first, the Pitch's (the centre), its second.
static func trees_for(cls: String) -> Array:
	var mine := []
	for t in TREES:
		if t.get("class", "") == cls:
			mine.append(t)
	var out := []
	if mine.size() > 0:
		out.append(mine[0])
	out.append(tree_named(COMMON_TREE))
	if mine.size() > 1:
		out.append(mine[1])
	return out


static func element_tree(name: String) -> Dictionary:
	for t in ELEMENT_TREES:
		if t["name"] == name:
			return t
	return {}


## The element tree for a damage type ("fire" is Petrol's), or {}.
static func element_tree_of(ty: String) -> Dictionary:
	for t in ELEMENT_TREES:
		if t.get("element", "") == ty:
			return t
	return {}


static func tree_named(name: String) -> Dictionary:
	for t in ELEMENT_TREES:
		if t["name"] == name:
			return t
	for t in TREES:
		if t["name"] == name:
			return t
	if name == RING_TREE:
		return RING
	return {}


## Word - the run's modifiers, Path of Exile's maps framed as what's been heard.
## Each tier carries one or two, re-rolled after every mission. Multipliers
## on the hostiles and the rewards; `contact` shifts how many fire at once.
## The sky's words: never on the Radio; the clock puts Night on, the weather Rain and Fog.
const MODIFIERS := [
	{"name": "Night", "words": "Pace −20%, loot quality +50%", "pace": 0.8, "rarity": 0.5, "sky": true},
	{"name": "Rain", "words": "Searches 30% slower, gangs 25% later", "search": 1.3, "patrol": 1.25, "sky": true},
	{"name": "Fog", "words": "One fewer on you, drops −10%", "contact": -1, "drop": 0.9, "sky": true},
	{"name": "Roofed", "words": "Raining outside, dry in here", "sky": true},     # a roofed site in the zone's rain: nothing bites (25 Oct)
]

## Map juicing (9 Oct, docs/design/juicing.md): the Radio's words. Each has a bite (what makes the run harder)
## and a pay (what it brings home), at tier I; a word's tier by the site's depth (WORD_TIER_DEPTH) grows both:
## a multiplier m becomes m^WORD_TIER_POW[t], an added figure ×WORD_TIER_POW[t]; a count (on you, loot tiers)
## and a flag stay as they are. `learn`: "start" known when the depths open; "paper" taught by `paper` read into
## the book; "zone" known once a site of `zone` is cleared at depth 2; "deep" taught by its paper, heard only at
## `depth` or deeper. The bite's keys: hp, dps, pool (the pack), patrol (<1 sooner), pace, search, contact,
## armour (yours), type/share, res/res_add, no_meds, no_kill_cash, clock (seconds), boss_walks. The pay's:
## drop (finds), rarity (quality), cash, xp, loot_tier, crates (13 Oct: a crate's weight on the site times this, its
## tier's power like a multiplier; a crate the site wouldn't have yet, it has).
const WORD_TIER_DEPTH := [2, 8, 15]          # depth for tiers I, II, III
const WORD_TIER_POW := [1.0, 1.75, 2.5, 3.5] # I, II, III, IV (Twist's)
const WORD_POOL_POW_TOP := 1.75     # a word's pool and drop multipliers stop at tier II's power (the designer's call, 31 Oct, PROBE36 lever 5a: Full house took a signal from 13-36 kills to 105-249)
const WORD_POOL_KEYS := ["pool", "drop"]
const WORD_TIER_NAMES := ["I", "II", "III", "IV"]
const WORD_MAX_DEPTH := [[2, 2], [5, 3], [9, 4]]   # [depth, words a site]
const WORD_POOLS := {"zone": 0.4, "general": 0.5, "deep": 0.1}
const WORDS := [
	{"name": "Numbers", "learn": "start", "bite": {"hp": 1.4}, "pay": {"drop": 1.3}},
	{"name": "Tooled up", "learn": "start", "bite": {"dps": 1.3}, "pay": {"rarity": 0.25}},
	{"name": "Delivery day", "learn": "start", "bite": {"patrol": 0.7}, "pay": {"cash": 1.4, "crates": {"military": 2.0}}},
	{"name": "Ex-army", "learn": "start", "bite": {"hp": 1.2, "dps": 1.2}, "pay": {"xp": 1.4}},
	{"name": "Bailiffs", "learn": "paper", "paper": "A council tax reminder", "bite": {"pool": 1.3}, "pay": {"cash": 1.3, "crates": {"safe": 2.0}}},
	{"name": "Laid off", "learn": "paper", "paper": "A P45", "bite": {"contact": 1}, "pay": {"xp": 1.5, "crates": {"filing": 2.0}}},
	{"name": "Long odds", "learn": "paper", "paper": "A betting slip", "bite": {"dps": 1.5}, "pay": {"rarity": 0.4}},
	{"name": "Pawned", "learn": "paper", "paper": "A pawn ticket", "bite": {"armour": 0.75}, "pay": {"drop": 1.35, "crates": {"jewellery": 2.5}}},
	{"name": "Overdrawn", "learn": "paper", "paper": "A bank statement", "bite": {"no_kill_cash": true}, "pay": {"drop": 1.6, "rarity": 0.3, "crates": {"safe": 2.5}}},
	{"name": "Hungry", "learn": "paper", "paper": "A food bank voucher", "bite": {"search": 1.5}, "pay": {"drop": 1.4}},
	{"name": "Burners", "learn": "paper", "paper": "A mortgage offer", "bite": {"type": "fire", "share": 0.33}, "pay": {"drop": 1.2, "cash": 1.2}},
	{"name": "Cutters", "learn": "paper", "paper": "A school report", "bite": {"type": "bleed", "share": 0.33}, "pay": {"drop": 1.2, "cash": 1.2, "crates": {"medicine": 2.0}}},
	{"name": "Wired", "learn": "paper", "paper": "A lottery ticket", "bite": {"type": "shock", "share": 0.33}, "pay": {"drop": 1.2, "cash": 1.2, "crates": {"toolbox": 2.0}}},
	{"name": "Jacketed", "learn": "paper", "paper": "A wage slip", "bite": {"res": "fire", "res_add": 0.4}, "pay": {"cash": 1.3}},
	{"name": "Rubbered", "learn": "paper", "paper": "A parking ticket", "bite": {"res": "shock", "res_add": 0.4}, "pay": {"cash": 1.3}},
	{"name": "Hardened", "learn": "paper", "paper": "An eviction notice", "bite": {"res": "physical", "res_add": 0.3}, "pay": {"cash": 1.3}},
	{"name": "Night owls", "learn": "paper", "paper": "A boarding pass", "bite": {"pace": 0.8}, "pay": {"rarity": 0.5}},
	{"name": "Everyone's in", "learn": "paper", "paper": "A Christmas list", "bite": {"pool": 1.25, "patrol": 0.8}, "pay": {"drop": 1.4, "xp": 1.2, "crates": {"jewellery": 1.5}}},
	{"name": "Dogs off the lead", "learn": "zone", "zone": 1, "bite": {"patrol": 0.8, "pace": 0.9}, "pay": {"drop": 1.3}},
	{"name": "Kids on bikes", "learn": "zone", "zone": 1, "bite": {"contact": 1}, "pay": {"cash": 1.25}},
	{"name": "Lock-ins", "learn": "zone", "zone": 1, "bite": {"search": 1.3}, "pay": {"rarity": 0.3, "crates": {"safe": 1.5}}},
	{"name": "Security", "learn": "zone", "zone": 2, "bite": {"res": "physical", "res_add": 0.2, "hp": 1.2}, "pay": {"cash": 1.35}},
	{"name": "Market day", "learn": "zone", "zone": 2, "bite": {"pool": 1.4}, "pay": {"cash": 1.4}},
	{"name": "Shoplifters", "learn": "zone", "zone": 2, "bite": {"patrol": 0.75}, "pay": {"drop": 1.35, "crates": {"jewellery": 2.0}}},
	{"name": "Squaddies", "learn": "zone", "zone": 3, "bite": {"dps": 1.4}, "pay": {"xp": 1.6, "crates": {"military": 2.0}}},
	{"name": "Checkpoints", "learn": "zone", "zone": 3, "bite": {"pace": 0.85, "hp": 1.2}, "pay": {"rarity": 0.4, "crates": {"ammo_tin": 2.0}}},
	{"name": "Kitted out", "learn": "zone", "zone": 3, "depth": 8, "bite": {"res": "all", "res_add": 0.25}, "pay": {"rarity": 0.5, "crates": {"military": 2.5}}},
	{"name": "Water cannon", "learn": "zone", "zone": 3, "depth": 10, "bite": {"soaked": 0.3}, "pay": {"drop": 1.4}},     # over the cap (12 Oct): your resists down, so the overflow defends
	{"name": "Rationed", "learn": "deep", "paper": "A ration book", "depth": 12, "bite": {"no_meds": true}, "pay": {"drop": 2.0}},
	{"name": "Curfew", "learn": "deep", "paper": "A council minute", "depth": 18, "bite": {"pool": 2.0, "patrol": 0.75}, "pay": {"drop": 1.8, "cash": 1.8, "crates": {"filing": 2.0}}},
	{"name": "Last bus", "learn": "deep", "paper": "A bus timetable, amended", "depth": 24, "bite": {"clock_half": true}, "pay": {"rarity": 1.2}},
	{"name": "Foreclosure", "learn": "deep", "paper": "A letter to the Bank", "depth": 30, "bite": {"hp": 2.5}, "pay": {"loot_tier": 2, "crates": {"safe": 3.0}}},
	{"name": "Full house", "learn": "deep", "paper": "A list of names", "depth": 40, "bite": {"pool": 3.0, "contact": 2}, "pay": {"drop": 2.5, "xp": 2.0}},
	{"name": "The Manager walks", "learn": "deep", "paper": "The Manager's note", "depth": 50, "bite": {"boss_walks": true}, "pay": {}},
]
## The Radio's crafts (juicing.md §6): notes × the site's depth × this.
const CRAFTS := [
	{"key": "tune", "name": "Tune in", "cost": 1.0, "words": "Adds a code", "sentence": "Adds 1 random code."},
	{"key": "broadcast", "name": "Broadcast", "cost": 3.0, "words": "Fills an empty site", "sentence": "Fills a site with no codes to its full count."},
	{"key": "retune", "name": "Retune", "cost": 2.0, "words": "Rolls them all again", "sentence": "Rerolls every code on the site."},
	{"key": "hold", "name": "Hold", "cost": 4.0, "words": "Keeps one, rolls the rest", "sentence": "Keeps one code you pick; rerolls the rest."},
	{"key": "call", "name": "Call in", "cost": 8.0, "words": "A code of your choosing", "sentence": "Adds a code you choose from the ones you know."},
	{"key": "clear", "name": "Clear", "cost": 0.5, "words": "Every code off", "sentence": "Removes every code. Costs 10 times as much on a sealed site."},
	{"key": "twist", "name": "Twist", "cost": 6.0, "words": "A gamble; seals the site", "sentence": "A gamble: one code goes to tier IV (40%), a deep code is added (25%), nothing (25%), or every code goes to its top tier (10%). The site is then sealed."},
]
const TWIST_ODDS := [0.4, 0.25, 0.25, 0.1]   # tier IV, a deep word, nothing, all at the top tier
const SEALED_CLEAR := 10.0


## A word by name, or {}.
static func word_of(name: String) -> Dictionary:
	for w in WORDS:
		if w["name"] == name:
			return w
	return {}


static func craft_of(key: String) -> Dictionary:
	for c in CRAFTS:
		if c["key"] == key:
			return c
	return {}


## Depth - the ladder on each tier. Each step compounds: hostiles +25% HP and
## fire, rewards +12%, drops +3 points, rarer finds - so every tier has a depth
## the loadout can hold and a deeper one it can't. Clearing a depth opens the next.
## The tuning batch (21 Oct, Matt's playtest: 100% at every campaign site to the Pleasure Park, 2-3 min a run, no deaths
## and no wounds on the bots): the campaign gets harder with the runner's level, the fights are longer, the gangs come
## sooner a zone along, and the clock runs through the searches.
const CAMPAIGN_LEVEL_FREE := 3     # a site cleared this many levels ago fights as it was (the first pass keyed the tax to the site's own
                                   # level and walled four builds at the frontier: the Bank's first clear comes 10-22 levels over its
                                   # level 6, so the frontier itself hardened to x2 as the runner levelled under it; a site never cleared
                                   # takes no tax now)...
const CAMPAIGN_LEVEL_GROW := 0.04  # ...and past that its heads' HP and fire compound by this a level you've gained since (5 levels on: x1.22)...
const CAMPAIGN_LEVEL_MAX := 1.5    # ...to x1.5 at most: levels come steadily, kit is luck (Matt's stance) - a lagging runner slows, never sticks
const CAMPAIGN_POOL := 1.0         # the campaign's pools as they are (1.5 read Matt's Pleasure Park 75% to 0%: the length comes from the gangs)
const PATROL_FIRST := 2.0          # the first gang after the clear waits twice the gap (the run's length, 4-5 min: Matt's runs ended at the first
                                   # gang, "Back, chased", two searches in); the gangs after come at the zone's gap
const PATROL_ZONE := [1.0, 0.9, 0.8, 0.7]     # the gangs' gap by zone: the City's a third sooner
const CLOCK_SEARCH_RATE := 0.5     # the clock runs through a search at half pace (it stood while the site was clear)
const CAMPAIGN_HOSTILE := [0.9, 1.15, 1.3, 1.3]     # by zone: the Outskirts as Matt played them, the Estate +15%, the Town and the City +30% (the web's fillers, web.md §8)
const DEPTH_HOSTILE := 0.25       # hostile HP and dps compound by this a depth
const DEPTH_REWARD := 0.12        # XP and cash compound by this a depth - slower, so each tier has a natural depth
const DEPTH_DROP := 0.03
const ARMOUR_K := 150.0           # mitigation = armour / (armour + ARMOUR_K)
const CLEAR_BONUS := 0.3          # the clear bonus: this many kills' worth of XP per hostile in the pool
const DEPTH_RARITY := 0.10

## Run timers (9 Oct, docs/design/timers.md): one clock a run, ticking only while a gang is on you. A site's
## budget is the same for every build - CLOCK_BASE + CLOCK_PER_HEAD a head of its plain pool and CLOCK_GANGS
## heads for the gangs after - so the damage it asks grows with its heads' HP: a DPS check. A crew's head adds
## CLOCK_PER_HEAD for every plain head's HP he carries when he comes out. Out of time: the pack and CLOCK_LOSE_KIT
## random pieces of worn kit lost, the runner home. First figures; the balance pass sets them.
const CLOCK_BASE := 90.0            # 60 to 90 (21 Oct: the clock runs through the searches now, at CLOCK_SEARCH_RATE); the starting kit's 12/s on the streets' 200 HP heads is 17 s a head: the clock must let a new runner through
const CLOCK_PER_HEAD := 12.0        # the bot's median at the sites it picks is 6 s a head (9 Oct probe): twice that
const CLOCK_GANGS := 5
const CLOCK_LOSE_KIT := 2
const CLOCK_WARN := 0.2            # the clock's last fifth: amber
const WAY_OUT_S := 20.0           # the way out (10 Oct, docs/design/way_out.md): a paid early leave, so long at the first site
const WAY_OUT_PER_TIER := 2.0     # and so much longer a site along (Matt: it grows with the tier)

## The operator. Level n: +HP_PER_LEVEL max HP and +DMG_PER_LEVEL damage a level.
const BASE_HP := 100.0
const HP_PER_LEVEL := 6.0
const DMG_PER_LEVEL := 0.02
const UNARMED_DPS := 3.0          # fists; a mission with no gun is a bad idea
const TREAT_CASH_PER_HP := 2.0    # the Clinic's healing, paid for at once
## Wounds (30): a hit that takes the runner under WOUND_AT of max HP leaves a
## wound, one of WOUND_STATS cut by WOUND_PCT until the Clinic treats it for
## WOUND_CASH a level. They stack (19 Oct, Matt: "up to 3 at a time"): one a run, one to each of WOUND_AREAS - the
## head's cuts the max HP, the chest's the armour, the legs' the pace - and a fourth bad run home adds nothing.
const WOUND_AT := 0.33            # 0.35 read 31-44% wounded and 0.30 2-9% (Matt, 8 Oct); the fifteenth read (7 Oct): at 0.35 the bot read 31-44% wounded and one bail in 31-69 - its close calls end between a quarter and a third; the pass (6 Oct): a quarter read 2-10% wounded, a third 28-32% on four builds, 0.30 4-9% on five with the bot pushing to 0.75; the bot plays to 0.85 now, so the wound comes from higher
const WOUND_PCT := 10
const WOUND_STATS := ["pace", "armour", "hp"]
const WOUND_AREAS := ["head", "chest", "legs"]
const WOUND_AREA := {
	"head": {"stat": "hp", "name": "Head", "what": ["a concussion", "a split brow", "a cracked cheekbone"]},
	"chest": {"stat": "armour", "name": "Chest", "what": ["cracked ribs", "a deep graze", "a winded lung"]},
	"legs": {"stat": "pace", "name": "Leg", "what": ["a torn hamstring", "a twisted knee", "a bad ankle"]},
}
const WOUND_CASH := 20
const MARKET_STOCK := 3           # items for sale, re-rolled after every mission
const MARKET_MARKUP := 3.0        # buying is dearer than selling

## The Fence's gamble (Matt, 6 Oct; the endgame's cash sink): a handful of kinds on offer, a picture
## each - a rifle, a helmet - rotated with the Fence's restock; pay and get a random one of the kind,
## rolled at the top tier opened with the Fence's quality on it, never Common; and any gamble can be a
## unique of the kind, from the first save on. The price is GAMBLE_RUNS of a run's takings, a run moving it
## GAMBLE_STEP at most (13 Oct), never under GAMBLE_FLOOR. Untuned until the pass reads it.
const GAMBLE_KINDS := [
	{"kind": "rifle", "slot": "Primary", "type": "rifle", "words": "A rifle"},
	{"kind": "shotgun", "slot": "Primary", "type": "shotgun", "words": "A shotgun"},
	{"kind": "smg", "slot": "Primary", "type": "smg", "words": "An SMG"},
	{"kind": "improvised", "slot": "Primary", "type": "improvised", "words": "Something improvised", "short": "Improvised"},
	{"kind": "melee", "slot": "Primary", "type": "melee", "words": "Something to swing", "short": "Melee"},
	{"kind": "pistol", "slot": "Secondary", "type": "", "words": "A sidearm"},
	{"kind": "helmet", "slot": "Helmet", "type": "", "words": "A helmet"},
	{"kind": "armour", "slot": "Armour", "type": "", "words": "Body armour"},
	{"kind": "rig", "slot": "Rig", "type": "", "words": "A rig"},
	{"kind": "backpack", "slot": "Backpack", "type": "", "words": "A pack"},
	{"kind": "gloves", "slot": "Gloves", "type": "", "words": "Gloves"},
	{"kind": "charm", "slot": "Charm", "type": "", "words": "A charm"},
]
const GAMBLE_SHOWN := 5             # kinds on offer at once, of the twelve (the gloves the twelfth, 29 Oct)
const GAMBLE_RUNS := 2.0            # the price, in runs' pay on the top open tier
const GAMBLE_STEP := 0.15           # the most one run home moves the gamble's base, up or down (13 Oct)
const GAMBLE_FLOOR := 300           # and never under this, at the opening day's prices
const GAMBLE_QUALITY := 0.0         # the Fence's quality on the roll (15 Oct, the loot read: was +50%, a fifth epic or better; never common still)
const GAMBLE_UNIQUE := 0.02         # the chance any gamble is a unique of the kind
const STARTING_CASH := 150
## Money that goes off. The Fence's prices rise with the Yard's hours - every
## cash price and every cash the gangs carry - so cash held loses, cash earned
## keeps pace, and the notes (the crews' own prices) don't move. A grace hour
## for the first run; linear after it; a ceiling where the new normal settles.
const INFLATION_GRACE_H := 1.0
const INFLATION_RATE := 0.07        # a hour, of the opening price
const INFLATION_CAP := 12.0
## The estate recycles. Nothing on it is new; it's all off someone. A dead
## runner's worn kit, and a unique sold to the Fence, go on the list, and a
## few runs later one of a gang is wearing it; it comes off him when the
## site's cleared. RECYCLE_RUNS runs before it can turn up, RECYCLE_ODDS a
## run after that; the list holds RECYCLE_KEEP pieces, the oldest first.
const RECYCLE_RUNS := 3
const RECYCLE_ODDS := 0.3
const RECYCLE_KEEP := 12
## The places changing. A cleared site is picked over in its crates (CRATE_TRICKLE_S below). The clock: the Yard
## opens at CLOCK_START; from NIGHT_FROM to NIGHT_TO every site is Night. The
## weather by zone, re-rolled every WEATHER_H: the odds of rain, then fog.
## A campaign site's crates kept between runs (27 Oct, Matt; docs/design/picked_over.md): what wasn't opened waits, and
## a fresh crate comes back every CRATE_TRICKLE_S of play up to the site's full set. The wear on drops and cash is gone.
const CRATE_TRICKLE_S := 180.0
## The crates (13 Oct, Matt; docs/design/search_crates.md): a cleared site's search is its crates, opened in the
## dice's order, each so many searches; all open, it's picked over. The crates' searches add up to THIN_AFTER +
## THIN_PER_DEPTH a depth (quantity pushes it), what the thinning gave in full before.
const THIN_AFTER := 7
const THIN_PER_DEPTH := 2
## A crate: its searches; `lean`, the share of its finds that come from `slots` (else the site's own find);
## `notes`/`scrap`, its odds of those against a plain search; `tins`, a handful of the site's cash a search; `unique`,
## the odds of a unique; `rarity`, added to the finds' quality; `w`, its weight on a site; `from_zone` the first
## zone it's met in, `depth_w` its weight added a depth past the first; `shape` the site's leaning that grows it.
const CRATES := [
	{"key": "cardboard", "name": "Cardboard box", "short": "Cardboard", "searches": 1, "w": 4.0},
	{"key": "ammo_tin", "name": "Ammo tin", "searches": 1, "w": 1.5, "shape": "ammo", "lean": 0.7, "slots": ["Ammo"]},
	{"key": "jewellery", "name": "Jewellery box", "short": "Jewellery", "searches": 1, "locks": true, "w": 0.8, "lean": 0.5, "slots": ["Charm"], "notes": 1.2},
	{"key": "toolbox", "name": "Toolbox", "searches": 2, "locks": true, "w": 1.5, "shape": "att", "lean": 0.5, "slots": ["Attachment"], "scrap": 1.5},
	{"key": "medicine", "name": "Medicine cabinet", "short": "Medicine", "searches": 2, "locks": true, "w": 1.2, "shape": "med", "lean": 0.6, "slots": ["Medical"]},
	{"key": "filing", "name": "Filing cabinet", "short": "Filing", "searches": 2, "locks": true, "w": 1.0, "shape": "paper", "lean": 0.4, "slots": ["Paper"], "notes": 1.6},
	{"key": "safe", "name": "Safe", "searches": 3, "locks": true, "w": 0.4, "from_zone": 1, "depth_w": 0.2, "notes": 2.0, "tins": true, "unique": 2.0},
	{"key": "military", "name": "Military crate", "short": "Military", "searches": 4, "locks": true, "w": 0.4, "from_zone": 2, "depth_w": 0.3, "lean": 0.6,
		"slots": ["Primary", "Secondary", "Helmet", "Armour", "Gloves"], "rarity": 0.4},
]
## Locked crates (13 Oct, the Caretaker's Keys): a crate that `locks` comes locked CRATE_LOCK of the time, over and above
## the site's searches; without the Keys it's passed over, with them it opens, its finds CRATE_LOCK_RARITY better.
const CRATE_LOCK := 0.15
const CRATE_LOCK_RARITY := 0.25
## A site's own crates, its weights times these: the Bank's safes, the Barracks' military crates.
const CRATE_SITES := {
	"The Bank": {"safe": 6.0}, "The Barracks": {"military": 5.0}, "The Services": {"military": 2.0, "ammo_tin": 1.5},
	"Shopping Centre": {"jewellery": 2.5}, "The Hospital": {"medicine": 1.5},
}
const CLOCK_START := 9.0
const NIGHT_FROM := 21.0
const NIGHT_TO := 6.0
const WEATHER_H := 1.0
## The sites under a roof (the Shopping Centre's atrium, the Bank's hall, the Garden Centre's glasshouse, the
## Hospital's ward): the zone's rain is on the Map, never in their fight (25 Oct, Matt); the sound's echo too.
const INDOOR_SITES := ["Shopping Centre", "The Bank", "The Garden Centre", "The Hospital"]
const WEATHER_ODDS := [[0.35, 0.15], [0.35, 0.15], [0.25, 0.2], [0.2, 0.25]]   # by zone: rain, fog (the Outskirts' the Estate's, 12 Oct)
## Stacks. Rounds of a base merge into one stack, up to STACK_BOXES boxes'
## worth; socketables (no affixes, a bottle is a bottle) merge by count, up
## to SOCKET_STACK. A stack is one cell whatever it holds; taking rounds to
## the rig tops up the rig's stack first and splits what's left.
const STACK_BOXES := 5
const SOCKET_STACK := 10

## XP a level: Melvor's curve, like Clade.
const MAX_LEVEL := 50
## The crew's floor (30 Oct, Matt, shared XP option B: "felt annoying to have a level 1 class when your other was 15"): a
## class swapped in joins at least this many levels under the best of the crew's other classes.
const CREW_FLOOR_UNDER := 3
## The papers (15 Oct, the Radio's endgame): rolled common to rare, no higher; a rare one (PAPER_DEEPER_AT) rolls its
## signal one deeper.
const PAPER_RARITY_MAX := 2
const PAPER_DEEPER_AT := 2
## Signals (15 Oct, endgame_radio.md §1-4): three papers decrypt at the Radio into one mission - a campaign site at
## random, a crew from any zone, a level rolled round your reach, each paper's code. Held a few at a time, seen
## before they're run, gone once run (a lost run loses it). Your reach: the highest level of a signal beaten, plus one.
## D3 (15 Oct, Matt: "reach is a level"): a site's level is its place past the Outskirts plus its depth, so a depth was
## no difficulty (depth 20 level 17 on the Allotments, 28 on the Barracks); a signal now lands at the depth that puts
## its site at the rolled level, every site alike, Kev's included.
const SIGNAL_PAPERS := 3
## Kev's papers (16 Oct, Matt's playtest: two plain papers and a story piece, and neither kind made a signal): the Radio
## sells a plain paper for notes - this many runs' notes on the top open site (a kill a note at depth 1), never under
## KEV_FLOOR - rolled as a find there; never one of Kev's story. First figures; the balance read sets them.
const KEV_RUNS := 2.0
const KEV_FLOOR := 10
const SIGNALS_HELD := 3
const REACH_START := 10                      # a level: the campaign tops at 9 (the Barracks at depth 1); the first signal's at 10
const STORY_UNDER := 2                       # Kev's beats come this many levels under your reach (D4: the head at full strength is
                                             # three levels' worth, and the odds fall from 100% to 0% in two; at the reach no build won one)
## The depth round the reach: [step, odds]. D2 (15 Oct, Matt: "go with your recommendation"): the band reaches three
## under the reach, so there's always one to win for the gear (the baseline: every build stalled with three it couldn't
## run and the campaign's kit); under the reach a win pays its drops and its story paper, not reach.
## D7: four under to one over (was three under to two over): the odds fall from 100% to 0% in two levels, so the
## rolls at and past the reach were all unwinnable and the D5 read's held three read 0% at the end of every build.
## D16: seven under to one over - at the wall (the reach a level or two past the kit) the rolls were all unwinnable, the
## bot farmed the campaign at the falloff's tenth and the levels stood still for hours; a deep roll keeps it moving.
## 20 Oct: the band is the papers' grade now (SIGNAL_GRADES); three papers roll three under to one over.
const SIGNAL_HEAD_ODDS := 0.15               # an extra: the crew's head, at full strength
## A signal from one, two or three papers (20 Oct, Matt: "allow a signal to be created on 1, 2 or 3 papers ... the
## quality of signal that is rolled and the max amount of modifiers"; the canvas "Fiat – The decoder, one to three
## papers"): the papers in set its grade - the band round the reach ([step, odds], as SIGNAL_ROLL was), the most codes it
## carries, and the head's and convoy's odds as a share of SIGNAL_HEAD_ODDS / SIGNAL_CONVOY_ODDS. Faint never reaches
## the reach: a win's for the gear and the papers home (SIGNAL_PAPERS_HOME), so a short pile still makes a signal.
const SIGNAL_GRADES := [
	{"papers": 1, "name": "Faint", "roll": [[-7, 0.2], [-5, 0.25], [-3, 0.3], [-2, 0.25]], "codes": 2, "extras": 0.0},
	{"papers": 2, "name": "Clear", "roll": [[-5, 0.15], [-3, 0.2], [-2, 0.2], [-1, 0.2], [0, 0.25]], "codes": 3, "extras": 0.5},
	{"papers": 3, "name": "Full", "roll": [[-3, 0.15], [-2, 0.2], [-1, 0.2], [0, 0.25], [1, 0.2]], "codes": 4, "extras": 1.0},
]
const SIGNAL_CONVOY_ODDS := 0.15             # an extra: a convoy's crew joins on the way
## Kev's story (15 Oct, §3): three beats, each a story signal made of its beat's three papers - a fixed site and crew
## at your reach, the crew's head at full strength; the third is the depot, the lorry's convoy (the old Services at
## depth 8). A signal beaten past the Radio's open has STORY_DROP to bring the beat's next paper home.
const STORY_BEATS := [
	{"key": "route", "name": "Where they go", "site": 9, "zone": 2},
	{"key": "army", "name": "Whose they are", "site": 11, "zone": 3},
	{"key": "depot", "name": "The depot", "site": 9, "zone": 3, "convoy": true},
]
const STORY_DROP := 0.3                    # the pass (20 Oct): 0.15 left the story and the lorry never in 24 h on most builds (the reach walls by hour 6-10 and its signals stop: the story has to land before it); 0.3 had the story at 4.5-6 h on the six-hour reads; 0.5 had the story and its lorry at 4.7 h on the bot, 1.8 h by hand (the gate 10-13 h)
const SIGNAL_PAPERS_HOME := 2               # a signal's run home brings this many papers at the least (18 Oct, Matt)
const PILE_CAP := 60                        # the Radio's pile holds this many (23 Oct, parked item 9: it had no top - the pass's bot piled
                                            # 28,000; a long session hundreds); past it the plainest plain paper goes, never Kev's

## The rebuild (18 Oct, docs/design/rebuild.md; Matt: "a reason to keep grinding past the lorry"): materials from runs,
## the town's places put back with them, and the order's true pinnacles behind them. Every number here is a
## placeholder for the balance pass (Matt: "no balance yet").
## The materials: counts at home, never sold; on a run pack items (1 Nov: Data.MATERIAL, lost as the pack's finds are).
## An area's two, the signals' fuses.
const MATERIALS := {
	"copper_wire": {"name": "Copper cable", "area": 1},     # shown as Copper cable (1 Nov): the key kept, so the counts in a save still load
	"paving": {"name": "Paving", "area": 1},
	"glass": {"name": "Glass", "area": 2},
	"ledgers": {"name": "Ledgers", "area": 2},
	"cable_drums": {"name": "Cable drums", "area": 3},
	"army_kit": {"name": "Army kit", "area": 3},
	"fuses": {"name": "Fuses", "area": -1},
}
const MATERIAL_ORDER := ["copper_wire", "paving", "glass", "ledgers", "cable_drums", "army_kit", "fuses"]
const SITE_MATERIAL := ["", "", "", "copper_wire", "copper_wire", "paving", "glass", "glass", "ledgers", "cable_drums", "cable_drums", "army_kit"]     # by site: the Outskirts none
const MATERIAL_RUN := 0.08               # a campaign site's run: the chance at its material
const MATERIAL_SIGNAL := 0.20            # a signal's run, at REACH_START
const MATERIAL_SIGNAL_STEP := 0.01       # and this more a level past it
const MATERIAL_CAP := 0.5
const MATERIAL_LEAN := 3.0               # a signal's two by its crew's area: each 1 / (held + this), the fewer held the likelier (20 Oct)
const AIM_NOTES := 40                    # Kev tunes a signal to a crew's area for this (20 Oct); first figure
const MATERIAL_HANDFUL := [1, 3]         # a drop
const MATERIAL_HEAD := [3, 6]            # a crew's head down: theirs, guaranteed
const FUSE_SIGNAL := 0.10                # a signal's run: the chance at fuses too
## The order's things, kept as counts: what a true pinnacle drops for the next rebuild or rank.
const KEY_ITEMS := {
	"grid_key": {"name": "The Grid's key"},
	"ledger_seal": {"name": "Ledger seals"},
	"fiat_note": {"name": "A true FIAT note"},
}
const KEY_ORDER := ["grid_key", "ledger_seal", "fiat_note"]
## The places. `costs` a first build's; a rank on grows them by REBUILD_GROWTH, adds REBUILD_FUSES fuses a rank past the
## first and, from REBUILD_KEY_RANK, one of `rank_key`. `first` is extra on the first build only (the mint's key).
## `fx`: what it does, base at rank 1 and step a rank after (cap where given), summed by stat (Sim.town_stat).
const REBUILDS := [
	{"key": "substation", "name": "The substation", "costs": {"copper_wire": 20, "cable_drums": 10}, "rank_key": "grid_key", "opens": "grid",
		"fx": [{"stat": "night_feet", "base": 1, "step": 0, "say": "Night runs keep their pace"}, {"stat": "night_rarity_pct", "base": 0, "step": 5, "say": "+%d%% night finds"}]},
	{"key": "pumping", "name": "The pumping station", "costs": {"paving": 20, "glass": 10}, "rank_key": "grid_key",
		"fx": [{"stat": "rest_pct", "base": 50, "step": 10, "say": "+%d%% rest"}, {"stat": "clinic_pct", "base": 10, "step": 2, "cap": 40, "say": "Clinic −%d%%"}]},
	{"key": "bus_depot", "name": "The bus depot", "costs": {"paving": 15, "army_kit": 10}, "rank_key": "grid_key",
		"fx": [{"stat": "pack_cells", "base": 2, "step": 1, "say": "Pack +%d cells"}]},     # 21 Oct, Matt: auto-run's rest went with it
	{"key": "library", "name": "The library", "costs": {"glass": 15, "ledgers": 15}, "rank_key": "ledger_seal", "opens": "archive",
		"fx": [{"stat": "paper_pct", "base": 25, "step": 5, "say": "+%d%% papers"}]},
	{"key": "market_hall", "name": "The market hall", "costs": {"glass": 20, "copper_wire": 20}, "rank_key": "ledger_seal",
		"fx": [{"stat": "shelf", "base": 1, "step": 0.5, "say": "Fence's shelf +%d"}, {"stat": "fence_pct", "base": 5, "step": 2, "cap": 40, "say": "Fence −%d%%"}]},
	{"key": "mint", "name": "The mint", "costs": {"ledgers": 30, "army_kit": 20}, "first": {"fuses": 5, "grid_key": 1}, "rank_key": "ledger_seal", "opens": "mint",
		"fx": [{"stat": "mint_pay", "base": 1.0, "step": 0.25, "say": "Pays tins by worth on clears"}]},     # on clears only (31 Oct, the designer)
]
const REBUILD_GROWTH := 1.35
const REBUILD_FUSES := 2                 # fuses a rank past the first
const REBUILD_KEY_RANK := 3              # from this rank, one of the place's rank_key
## Issued kit (25 Oct, Matt's picks): sold only by the Issuer, in fiat, after the Issue. Stamped and numbered, a tier
## past mythic: the deepest base of its slot, lifted ISSUED_LIFT, its item level the reach's + ISSUED_OVER, one rule each.
## Off the counter, and off a County head (a tier over the counter's); never lost (as a mythic). The County's sites want
## ISSUED_WANT of them worn (a piece of your own stamped at the Bench counts too).
const ISSUED := [
	{"name": "Issued rifle", "slot": "Primary", "base": "Anti-materiel rifle", "rule": "issued_rifle", "issued": true,
		"words": "Every kill pays half again", "short": "Kills pay ×1.5", "affixes": [{"stat": "damage_pct", "value": 25}]},
	{"name": "Issued sidearm", "slot": "Secondary", "base": "Special issue pistol", "rule": "issued_sidearm", "issued": true,
		"words": "The Issuer's own make: its damage grows with its level", "short": "Damage by its level", "affixes": [{"stat": "damage_pct", "value": 20}]},
	{"name": "Issued cap", "slot": "Helmet", "base": "Command helmet", "rule": "issued_cap", "issued": true,
		"words": "The Fence never pays you under the face rate", "short": "Rate never under 1.0", "affixes": [{"stat": "all_res", "value": 15}]},
	{"name": "Issued plate", "slot": "Armour", "base": "Heavy armour suit", "rule": "issued_plate", "issued": true,
		"words": "A fifth less from the order and the County's people", "short": "−20% from the order, the County", "affixes": [{"stat": "hp", "value": 60}]},
	{"name": "Issued webbing", "slot": "Rig", "base": "Command rig", "rule": "issued_webbing", "issued": true,
		"words": "Meds heal more, and one more is carried", "short": "Meds heal more, +meds", "affixes": [{"stat": "heal_pct", "value": 50}, {"stat": "med_cap", "value": 1}]},
	{"name": "Issued seal", "slot": "Charm", "base": "Gold sovereign", "rule": "issued_seal", "issued": true,
		"words": "Your burns count double; finds come better", "short": "Burns ×2, better finds", "affixes": [{"stat": "rarity_pct", "value": 20}]},
]
const ISSUED_LIFT := 1.5
const ISSUED_OVER := 5
const ISSUED_PRICE := 6.0              # an issued piece's price: its worth x this, at the day's (fiat) prices
const ISSUED_WANT := [2, 3, 4, 6]      # issued pieces worn to stand in the County's zones, one a zone

## The County (25 Oct, the Issue's second campaign: docs/design/the_issue.md §4): four zones of three places past the
## City, each held by one of the Issuer's people. A place is fought as the order's are - laid on a host site's crew and
## drops (`site`, `zone`), under its own name - at its set `level` (26 Oct, the seventh pass: at the reach + 2 to + 14
## nothing past + 3 was won), a level more every time it's beaten. A zone
## wants ISSUED_WANT issued pieces worn; its places open in turn; its last is its head's; the head down opens the next
## zone. The Treasurer down opens the Radio's remix. The art is the host site's plate until the County's is drawn.
const COUNTY_ZONES := [
	{"name": "The Motorway", "head": "The Bailiff", "words": "The Toll Plaza, the Distribution Centre, the Truck Stop - the road out, and what it carries."},
	{"name": "The Docks", "head": "The Auditor", "words": "The Container Port, the Ferry Terminal, the Customs Shed - everything in, counted."},
	{"name": "The Big Houses", "head": "The Collector", "words": "The Golf Club, the Gated Close, the Manor - where the money went to live."},
	{"name": "The Treasury", "head": "The Treasurer", "words": "The Counting House, the Bullion Vault, the Treasury - where it's made to stick."},
]
const COUNTY := [
	{"key": "toll_plaza", "place": "The Toll Plaza", "cz": 0, "site": 9, "zone": 3, "level": 50},
	{"key": "distribution", "place": "The Distribution Centre", "cz": 0, "site": 5, "zone": 1, "level": 52},
	{"key": "truck_stop", "place": "The Truck Stop", "cz": 0, "site": 9, "zone": 3, "level": 55,
		"who": "The Bailiff", "mech": "bailiff", "hp": 14.0, "dps": 3.0},
	{"key": "container_port", "place": "The Container Port", "cz": 1, "site": 11, "zone": 3, "level": 60},
	{"key": "ferry_terminal", "place": "The Ferry Terminal", "cz": 1, "site": 6, "zone": 2, "level": 62},
	{"key": "customs_shed", "place": "The Customs Shed", "cz": 1, "site": 7, "zone": 2, "level": 65,
		"who": "The Auditor", "mech": "auditor", "hp": 16.0, "dps": 3.5},
	{"key": "golf_club", "place": "The Golf Club", "cz": 2, "site": 2, "zone": 0, "level": 70},
	{"key": "gated_close", "place": "The Gated Close", "cz": 2, "site": 3, "zone": 1, "level": 72},
	{"key": "manor", "place": "The Manor", "cz": 2, "site": 10, "zone": 3, "level": 75,
		"who": "The Collector", "mech": "collector", "hp": 18.0, "dps": 3.5},
	{"key": "counting_house", "place": "The Counting House", "cz": 3, "site": 8, "zone": 2, "level": 80},
	{"key": "bullion_vault", "place": "The Bullion Vault", "cz": 3, "site": 8, "zone": 2, "level": 82},
	{"key": "treasury", "place": "The Treasury", "cz": 3, "site": 8, "zone": 2, "level": 85,
		"who": "The Treasurer", "mech": "treasurer", "hp": 18.0, "dps": 2.5},     # fire 4.5 to 3.6 to 3.0 to 2.5, HP 22 to 18 (Matt, 27 Oct, the gauntlet: the County's one wall)
]
## The heads' fights (Matt, 25 Oct), each a different check:
const BAILIFF_CUT := {"Primary": 0.4, "Secondary": 0.15}   # the Bailiff seizes your best piece: a gun's share of your fire lost while he holds it
const BAILIFF_TAKEN := 1.25            # a piece you wear for its armour seized: you take this much
const BAILIFF_FREE := 0.5              # under this share of his HP he lets it go
const AUDITOR_TAX := 1.5               # the Auditor: every skill costs half again (and he seals one, ORDER_SEAL_EVERY)
const COLLECTOR_GROW := 0.05           # the Collector: what you take grows this much
const COLLECTOR_EVERY := 3.0           # every this many seconds he's out, back to nothing each time one of his men drops
const COLLECTOR_MEN_EVERY := 6.0       # he calls a debtor in this often (ORDER_PRINT_MAX on you at most)
const COUNTY_HEAD_ISSUED := 1          # a head beaten: this many issued pieces of his level, stamped and numbered
const REMIX_COUNTY_ODDS := 0.4         # the remix (after the Treasurer): a signal laid on one of the County's places
const REMIX_HEAD_ODDS := 0.5           # a signal's head, one of the Issuer's people away from home
const REMIX_ISSUED_ODDS := 0.2         # a signal won at the reach or past it: an issued piece at its level


static func county(key: String) -> Dictionary:
	for c in COUNTY:
		if c["key"] == key:
			return c
	return {}

## The Issue (25 Oct, docs/design/the_issue.md): the first Issuer win puts the town on fiat for good.
const FIAT_SCALE := 0.0005             # a fiat's worth against the day's tins: every price and pay after the Issue is the tins' x this
const FIAT_PILE_K := 0.8               # the conversion, hard on piles: fiat = this x the square root of tins held (and notes at NOTE_TINS)
const NOTE_TINS := 500.0               # a note's worth in the day's tins at the Issue (the crews' prices read through it after)

## The exchange (28 Oct, Matt: "contracts should be replaced by currency conversion - notes, tins, scrap with varying
## rates for each"; salvage and the County's materials too): a worth in tins at inflation 1 a currency, the day's
## prices on it and a drift of ±EXCHANGE_DRIFT a run home; EXCHANGE_SPREAD kept either way. All drafts for the balance pass.
const EXCHANGE_BASE := {
	"notes": NOTE_TINS, "scrap": float(SCRAP_PER_POUND),
	"copper": 600.0, "steel": 600.0, "army": 600.0,
	"copper_wire": 900.0, "paving": 900.0, "glass": 900.0, "ledgers": 900.0, "cable_drums": 900.0, "army_kit": 900.0, "fuses": 900.0,
}
const EXCHANGE_DRIFT := 0.12            # a day's move a currency, either way (draft)
const EXCHANGE_SPREAD := 0.15           # kept either way; the Fence's Contacts 10% (draft)
const FIAT_CIRC_SPAN := 100000.0       # every this-much fiat in circulation adds 100% to prices
const FIAT_CIRC_CAP := 4.0             # prices never past x4 the Issue's
const RATE_MIN := 0.6                  # the Issuer's rate: the Fence buys at it
const RATE_MAX := 1.25
const RATE_SALE_STEP := 0.01           # a sale of RATE_SALE_UNIT (tins of the opening day, at today's prices) takes 1% off the rate
const RATE_SALE_UNIT := 600000.0
const RATE_RECOVER_H := 0.05           # the rate drifts back to 1.0 this much an hour
const BURN_SHARE := 0.25               # a burn takes this share of the fiat in circulation out (Matt, 26 Oct: "burns a share")
const BURN_MULT := 2.0                 # and costs half of what it takes out
const CIRC_HALF_H := 1.0               # the fiat in circulation halves every this many hours (Matt, 26 Oct: "it decays"; the pass's number)
const PRINT_HAUL := 20000000.0         # the Issuer beaten again: he prints - this many of the opening day's tins in fiat
const PRINT_CIRC := 1.0                # and it goes into circulation again on top (the prices jump)
const PRINT_DECAY := 0.8               # each print this much of the last (Matt, 26 Oct: the Mint "a choice, not a farm")
const MINT_TINS := 2.0                   # a run's tins from the mint: the town's worth × this × mint_pay, at today's prices
## The true pinnacles: new people in new places, opened by a rebuild, fought on a host site's crew and drops (`site`,
## `zone`) under their own name and art; their first fight at their set `level` (the Grid 35, the Archive 40, the Mint 45),
## after it max(the set level, the reach + `over`) and a level more every time they're beaten. One unique each (always the first time, PINNACLE_UNIQUE after), `drop` every win,
## `first` on the first win only.
const PINNACLES := [
	{"key": "grid", "place": "The Grid", "who": "The Lineman", "opened_by": "substation", "site": 9, "zone": 3, "art": "The Grid", "hp": 14.0, "dps": 3.0, "over": 2, "level": 35, "again": 90,
		"drop": "grid_key", "unique": "The Lineman's Lamp", "unique2": "The Lineman's Tool Bag"},
	{"key": "archive", "place": "The Archive", "who": "The Registrar", "opened_by": "library", "site": 8, "zone": 2, "art": "The Archive", "hp": 16.0, "dps": 3.5, "over": 4, "level": 40, "again": 95,
		"drop": "ledger_seal", "unique": "The Registrar's Satchel", "unique2": "The Registrar's Stamp"},
	{"key": "mint", "place": "The Mint", "who": "The Issuer", "opened_by": "mint", "site": 11, "zone": 3, "art": "The Mint", "hp": 20.0, "dps": 4.0, "over": 6, "level": 45, "again": 100, "again_soft": 0.55,
		"drop": "ledger_seal", "first": "fiat_note", "unique": "The Issuer's Robes", "unique2": "The Issuer's Revolver"},
]
const PINNACLE_WORTH := 4
const ORDER_AGAIN_SOFT := 0.65    # an order's head on its ladder: HP and fire this much (Matt, 27 Oct)
const ORDER_AGAIN_STEP := 2     # an order won before: its "again" level, then this a win past the second (Matt, 27 Oct: a set ladder over the Treasury)
## Patterns (24 Oct, the endgame chase, phase 4): a unique's rule moved onto a rare or better of its slot.
const PATTERN_RARITY := 2          # rare or better takes one
const PATTERN_MATERIAL := 12       # of the material you hold most of
const PATTERN_TINS := 20000        # tins at item level 1, at today's prices
const PATTERN_GROW := 1.06         # and this much more an item level
const STAMP_EVERY := 3             # the Registrar's Stamp: every this-many-th skill free and twice (24 Oct)
## The true pinnacles' fights (24 Oct, the endgame chase; endgame_chase.md calls 5-7): each a different check.
const ORDER_SHIELD := 0.3          # the Lineman: a shield of this share of his HP over it
const ORDER_SHIELD_WINDOW := 6.0   # not broken in this many seconds, it fills again
const ORDER_SHIELD_STUN := 3.0     # broken: he's stunned this long
const ORDER_SHIELD_BACK := 8.0     # and it comes back up after this
const ORDER_SEAL_EVERY := 10.0     # the Registrar: a skill sealed this often (12 to 10, Matt 26 Oct: red tape with a bite)
const ORDER_SEAL_FOR := 5.0        # for this long
const ORDER_TAPE_CUT := 0.5        # with no skill to seal, your fire cut this much while it holds (0.3 to 0.5, Matt 26 Oct)
const ORDER_PRINT_EVERY := 8.0     # the Issuer: a man printed this often
const ORDER_PRINT_MAX := 6         # and never more than this on you
const PINNACLE_UNIQUE := 0.25


static func rebuild(key: String) -> Dictionary:
	for r in REBUILDS:
		if r["key"] == key:
			return r
	return {}


static func pinnacle(key: String) -> Dictionary:
	for p in PINNACLES:
		if p["key"] == key:
			return p
	return county(key)     # a County place reads as one of the order's (25 Oct): its host site, its level past the reach
## Gear gated by level (15 Oct, Matt; docs/design/endgame_radio.md §5): a piece's level to wear is its item level
## times this, less (this - 1) - the first sites' at 1, the Quartermaster's (item level 9) at 25 - to MAX_LEVEL.
## Carried, stashed and sold as any other; it waits for the runner's level. One figure for the pass to tune.
## Over-levelled (D9, 15 Oct, Matt; the D8 read: a level-50 Scrapper farmed the Bank at depth 1 in three-second runs at full
## pay): past OVER_LEVEL_FREE site levels under you a site pays OVER_LEVEL_STEP less XP and tins a level, to OVER_LEVEL_FLOOR.
const OVER_LEVEL_FREE := 3.0     # 5 to 3 (25 Oct, Matt: the campaign's levels track its gear; the bot was 4-8 over each site's)
const OVER_LEVEL_STEP := 0.25     # 0.15 to 0.25 (the third pass: from the Services on, the bot 5 over each site's gear)
const OVER_LEVEL_FLOOR := 0.1
## The level to wear an item level: WEAR_PER_ILVL x it - WEAR_OFFSET, at least 1 (19 Oct, Matt's playtest: at x2.5 - 1.5 he
## reached the Parade a level under its drops and the Barracks five under; 2 x - 2 is the levels he reached them at:
## the Parade 2, the Retail Park 4 ... the Barracks 16). Each site also opens at its drops' level less one (site_gate).
const WEAR_OFFSET := 2.0
const WEAR_FLAT := 16               # past this a find's wear is its item level (21 Oct): the endgame's finds are their signal's level
const WEAR_PER_ILVL := 2.0           # with WEAR_OFFSET 2: the City's drops at wear 12-16
## A fifth of a site's or a signal's plain gear finds at the level the runner can wear (16 Oct, Matt's playtest: "the gear
## gating is frustrating" - level 10 at the Bank, every drop for level 14), never past the site's own. Uniques, set pieces
## and mythics roll at the site's.
const FIND_AT_MINE := 0.2
const CAMPAIGN_TIER := 4          # gear tiers (29 Oct, one tier a zone): the Outskirts 1, the Estate 2, the Town 3, the City 4
const MAX_TIER := 9               # the deep bases (10 Oct): 7, 8 and 9, past the campaign
const DEEP_TIER_LEVELS := [10, 13, 16, 20, 24]   # the signal level a tier past the campaign drops from (29 Oct): T5 from level 10, T6 13, T7 16, T8 20, T9 24
static var _xp_table: Array = []
const PARAGON_XP_GROW := 0.25     # 0.05 to 0.25 (the designer's call, 31 Oct, PROBE36: paragon 53 to 590 in 15 min). A paragon level costs level 50's XP and this much more a level past it (24 Oct, Matt: an endgame "at least 30ish" hours)
## D5 (15 Oct, the pass's gate 4): the XP a level costs, times this. The reads had the Quartermaster at level 26-39 and
## level 50 by hour 3-8; the curve doubles every seven levels, so 2.4 puts level 28's XP at level 20.
const XP_SCALE := 3.3     # keeps the sites cleared near their gear's level, not 5-8 over
## D11: past the campaign the scale eases, XP_SCALE at XP_TAPER_FROM to XP_TAPER_END at XP_TAPER_TO and on: the reads had
## the levels stall from hour 4 at x2.4 (level 35-43 at 24 h; retirement never on nine builds of ten).
## The first levels (16 Oct, Matt's playtest: level 2 at 27 minutes on the Retail Park, every drop four levels over him):
## the scale climbs from XP_RAMP_FROM at level 1 to XP_SCALE by XP_RAMP_TO - level 6 at about 510 XP, not 1,500.
const XP_RAMP_FROM := 1.0
const XP_RAMP_TO := 12
const XP_TAPER_FROM := 22
const XP_TAPER_TO := 40
const XP_TAPER_END := 8.0     # 4.0 to 8.0 (the designer's call, 1 Nov, PROBE40, with REPEAT_XP x0.5: the long pass had level 50 at 7-9 h on four of six; the analyst's estimate 11.3-21.2 h, median 14.7); 3.1 to 4.0 (31 Oct, PROBE36). The scale from level 40 on: level 50 wanted at 12-24 h


static func xp_scale(l: int) -> float:
	if l < XP_RAMP_TO:
		return lerpf(XP_RAMP_FROM, XP_SCALE, float(l - 1) / float(XP_RAMP_TO - 1))     # the first levels quicker (16 Oct)
	if l <= XP_TAPER_FROM:
		return XP_SCALE
	var f: float = clampf(float(l - XP_TAPER_FROM) / float(XP_TAPER_TO - XP_TAPER_FROM), 0.0, 1.0)
	return lerpf(XP_SCALE, XP_TAPER_END, f)


static func xp_for_level(level: int) -> float:
	if _xp_table.is_empty():
		_xp_table.append(0.0)
	while _xp_table.size() < maxi(level, MAX_LEVEL):        # the curve runs on past the cap: the paragon levels (7 Oct)
		var l: int = _xp_table.size()
		var step: float = floorf((mini(l, MAX_LEVEL - 1) + 300.0 * pow(2.0, mini(l, MAX_LEVEL - 1) / 7.0)) / 4.0 * xp_scale(mini(l, MAX_LEVEL - 1)))
		if l >= MAX_LEVEL:
			step = floorf(step * (1.0 + PARAGON_XP_GROW * (l - MAX_LEVEL + 1)))     # a paragon level: the last level's XP, a little more each (24 Oct: doubling every seven, the paragon stopped and the reach walled)
		_xp_table.append(float(_xp_table[l - 1]) + step)
	return _xp_table[maxi(level, 1) - 1]


static func level_for_xp(xp: float) -> int:
	var l := 1
	while l < MAX_LEVEL and xp >= xp_for_level(l + 1):
		l += 1
	return l


## Levels past the cap, on the same curve: nothing until MAX_LEVEL, then one a step.
static var _paragon_memo: Array = [-1.0, 0]
static func paragon_for_xp(xp: float) -> int:
	if not is_finite(xp):
		return 0
	if _paragon_memo[0] == xp:
		return _paragon_memo[1]                  # read many times a tick from the HP and the damage
	var l := MAX_LEVEL
	if xp > float(_paragon_memo[0]) and int(_paragon_memo[1]) > 0:
		l = MAX_LEVEL + int(_paragon_memo[1])     # XP only climbs in a run: walk on from the last answer
	while l < 10000 and xp >= xp_for_level(l + 1):
		l += 1
	_paragon_memo = [xp, l - MAX_LEVEL]
	return l - MAX_LEVEL


# ------------------------------------------------------------------ expeditions (29 Oct, docs/design/trips.md 3, 4, 6)
## The endgame's expeditions (the design doc's "trips"; on screen "Expeditions": the glossary's "a trip out" is a run): a
## crew - a runner of another class leading, up to two hired hands - takes cargo to a far place and comes back after a
## stretch of played time with that place's rewards, sized by the cargo's worth, rolled by the crew. Open once the
## Quartermaster falls. Every number a placeholder for the balance pass; the words drafts for the language pass.
## A far place: `lv` its level at the least, `reach` its level against the reach (the higher wins: the far places climb
## with the camp); `zone` its gang (the crew types of that zone; never fought on screen); `time` played seconds; `pays`
## its return as [kind, share]; `hold` the campaign site (one with fight art and a head) a hold-up is fetched from.
const EXP_PLACES := [
	{"key": "swansea", "name": "Swansea", "short": "Swansea", "tag": "Swansea", "line": "Gone quiet", "time": 1800, "lv": 9, "reach": -4, "zone": 3, "hold": 5,
		"pays": [["meds", 0.6], ["supplies", 0.4]], "quota": "mythic"},
	{"key": "bristol", "name": "The Bristol checkpoint", "short": "Bristol", "tag": "Bristol", "time": 3000, "lv": 10, "reach": -3, "zone": 2, "hold": 8,
		"pays": [["tins", 0.75], ["tokens", 0.25]], "quota": "gamble"},
	{"key": "salisbury", "name": "Salisbury Plain", "short": "Salisbury", "tag": "Salisbury", "time": 4800, "lv": 11, "reach": -2, "zone": 3, "hold": 11,
		"pays": [["parts", 0.5], ["army", 0.5]], "quota": "set"},
	{"key": "birmingham", "name": "The Birmingham depots", "short": "Birmingham", "tag": "Brum", "time": 6000, "lv": 12, "reach": -1, "zone": 1, "hold": 5,
		"pays": [["materials", 0.7], ["fuses", 0.3]], "quota": "rebuild"},
	{"key": "liverpool", "name": "The Liverpool docks", "short": "Liverpool", "tag": "Liverpool", "time": 7200, "lv": 13, "reach": 0, "zone": 2, "hold": 8,
		"pays": [["socketables", 0.4], ["charms", 0.3], ["socketed", 0.3]], "quota": "socketed"},
	{"key": "london", "name": "London", "short": "London", "tag": "London", "time": 10800, "lv": 15, "reach": 2, "zone": 3, "hold": 11,
		"pays": [["uniques", 1.0]], "quota": "named"},
]
const EXP_HOST := 11                   # the site a far place's fight is read on (the hardest), laid on as a signal is
const EXP_SIG_ID := 900000             # a far place's read apart from every signal's (its id + the place's index)
## The lead's class weights the return (trips.md 3): this share of it goes to the class's own kind.
const EXP_CLASS_KIND := {"Scrapper": "parts", "Paramedic": "supplies", "Poacher": "charms", "Doorman": "tins", "Drifter": "papers", "Recruit": "army"}
const EXP_CLASS_SHARE := 0.2
const EXP_RETURN := 1.55               # the return's worth, the cargo's times this (scrap at its cut worth: Sim.cargo_unit); the hands' bonus (EXP_BONUS_CAP) on top. An average expedition - at the bot's risk (0.45), the hands it sends, its bad rolls and hold-ups (ransomed) in - brings about x1.2 home before wages (31 Oct, the designer's x1.2; the exchange round trip "acceptable"): a draft for the pass
const EXP_BONUS_CAP := 1.2             # the hands' bonuses all told (porters, "+% finds", crackers' crates) never past ×1.2 on that
const EXP_SLOTS := 3                   # cargo slots, the quartermaster's and "+1 cargo slot" on top
const EXP_SLOTS_MAX := 6
const EXP_SHARES := [0.25, 0.5, 0.75, 1.0]     # a cargo slot's amount: a share of what's held
const EXP_RISK_K := 0.3                # the cargo's worth over the lead's kit's, times this, fills the risk
const EXP_ODDS_W := 0.8                # and the odds short of 100%, times this
const EXP_RISK_MIN := 0.02
const EXP_RISK_MAX := 0.95
const EXP_RANK_RISK := 0.02            # the Bunkhouse's rank: the risk 2% lower a rank
const EXP_LOSS := [0.25, 1.0]          # a bad roll loses this share of the return
const EXP_HOLD := 0.04                 # the hold-up: rare, more at high risk
const EXP_HOLD_RISK := 0.25
const EXP_RANSOM := 0.5                # the ransom: the cargo's worth times this, never under EXP_RANSOM_MIN tins
const EXP_RANSOM_MIN := 500
const EXP_TIME_FLOOR := 0.5            # the driver and "−% time" never take an expedition under half its time
const EXP_ITEMS_MAX := 12              # items a return carries at most; the rest of its worth comes back as scrap
const EXP_QUALITY_K := 0.1             # the return's loot quality: this a doubling of the cargo's worth over EXP_QUALITY_UNIT
const EXP_QUALITY_UNIT := 2000.0
const EXP_ITEM_FLOOR := 20.0           # an item counted at this worth at least against the return
const EXP_CRATE_SHARE := 0.05          # a cracker's crate: 5% of the cargo's worth a crate, a find of the place's first kind (inside the cap: never from nothing)
const EXP_MED_UNIT := 60.0             # a med's worth for a quota when none are held
const EXP_WEEK_H := 7.0                # a quota's week: 7 hours of the world's played time (the fix round: the exchange's day was a run home)
const EXP_QUOTA_WORTH := [3000.0, 4000.0, 5000.0, 6000.0, 7000.0, 9000.0]     # a place's weekly quota, in tins at today's prices
const EXP_QUOTA_BONUS := [0.2, 0.5]    # meeting it: +20-50% on the quota's own slot (not the whole shipment), and the quota's item
const EXP_MYTHIC_CHANCE := 0.05        # Swansea's quota: the chance at a mythic - an hour's finds (about 500) at the game's 1 in MYTHIC_ODDS_IN
## The hands (trips.md 3, Dragon Cliff): built as gear by the item code - a trade the base, a tier, a rarity, 1-4 affixes
## from the expeditions' own pool. The trade's figure grows by tier (`fig` a tier, to `cap`) and with the hand's level.
const HAND_SLOT := "Hand"
const HAND_TRADES := [
	{"trade": "porter", "name": "Porter", "stat": "finds", "fig": 5, "cap": 60},
	{"trade": "medic", "name": "Nurse", "stat": "bail", "fig": 6, "cap": 60},     # "Nurse" on screen (the Clinic's medic, the Paramedic)
	{"trade": "scout", "name": "Scout", "stat": "odds", "fig": 2, "cap": 25},
	{"trade": "cracker", "name": "Cracker", "stat": "crates", "fig": 1, "cap": 4},
	{"trade": "driver", "name": "Driver", "stat": "time", "fig": 4, "cap": 40},
	{"trade": "quartermaster", "name": "Loader", "stat": "cargo", "fig": 1, "cap": 2},     # the design's quartermaster: "Loader" on screen, the Quartermaster being a head (the glossary: one name a thing)
]
## The expeditions' affixes: rolled with the gear's tiers (Items.roll_affix); `less` reads "−8% risk"; `place` names a
## far place, rolled with the affix; `flag` has no figure.
const HAND_AFFIXES := [
	{"stat": "x_odds", "short": "odds", "min": 2, "max": 12, "pct": true},
	{"stat": "x_risk", "short": "risk", "min": 2, "max": 12, "pct": true, "less": true},
	{"stat": "x_slot", "short": "cargo slot", "tight": "cargo", "min": 1, "max": 1, "weight": 0.5},
	{"stat": "x_finds", "short": "finds", "min": 4, "max": 24, "pct": true},
	{"stat": "x_quality", "short": "loot quality", "tight": "quality", "min": 4, "max": 24, "pct": true},
	{"stat": "x_time", "short": "time", "min": 3, "max": 15, "pct": true, "less": true},
	{"stat": "x_hold", "short": "hold-ups", "min": 10, "max": 50, "pct": true, "less": true},
	{"stat": "x_wage", "short": "wage", "min": 5, "max": 30, "pct": true, "less": true},
	{"stat": "x_place", "short": "finds from %s", "tight": "%s finds", "min": 8, "max": 30, "pct": true, "place": true},
	{"stat": "x_safe", "short": "never held up near %s", "tight": "safe near %s", "min": 1, "max": 1, "flag": true, "place": true, "weight": 0.5},
]
const HAND_RARITY_MAX := 4             # Common to Legendary; affixes one a rarity step, four at most
const HAND_AFFIX_MAX := 4
const HAND_POOL := 6
const HAND_ROSTER := [4, 8]            # the roster's cap; More bunks' +4
const HAND_REROLL := [2000, 16000]     # New faces, Better faces (Settlers: 2,000 / 16,000), at today's prices
const HAND_WAGE := 50.0                # a hand's wage an expedition: this × tier × the rarity's value, at today's prices
const HAND_LV_MAX := 10
const HAND_LV_EVERY := 2               # expeditions home a level
const HAND_LV_GROW := 0.1              # a level's rise on the trade's figure and every affix's roll
