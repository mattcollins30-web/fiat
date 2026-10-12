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
const SLOTS := ["Primary", "Secondary", "Helmet", "Armour", "Rig", "Backpack", "Charm"]
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
## Ammo rides in the rig too, a stack a cell. A gun fires its type's rounds
## and runs dry without them: then the secondary, then fists.
const AMMO := "Ammo"
## Papers: a line of the before, found lying about, a cell each, pennies at
## the Fence. Their words live in words.gd; the deeds are the one that matters.
const PAPER := "Paper"
const PAPER_DROP := 0.06           # the share of a site's finds that are papers
const AMMO_FOR := {"improvised": "Nails", "shotgun": "Shells", "rifle": "Rifle rounds", "smg": "SMG rounds", "pistol": "Pistol rounds", "none": ""}

## An item's footprint in cells, W x H - what it takes in the stash and the
## pack, and the size its picture is drawn at (64 px a cell). The slot gives
## the default; FOOTPRINTS names the bases that differ. The art is generated
## to these: change a footprint and its picture no longer fits.
const SIZE := {"Primary": [4, 1], "Secondary": [2, 1], "Helmet": [2, 2], "Armour": [3, 3], "Rig": [3, 2], "Backpack": [3, 3],
	"Medical": [1, 1], "Attachment": [1, 1], "Ammo": [1, 1], "Paper": [1, 1], "Charm": [1, 1], "Grenade": [1, 1]}
const FOOTPRINTS := {
	# melee
	"Spiked bat": [3, 1], "Machete": [3, 1], "Pipe wrench": [2, 1], "Fire axe": [3, 1], "Bayonet on a stick": [4, 1], "Sledgehammer": [3, 1], "Breaker bar": [3, 1],
	"Knife": [1, 1], "Knuckle duster": [1, 1], "Cosh": [1, 1],
	# short long guns
	"Hand-me-down nail gun": [3, 1], "Nail gun": [3, 1], "Bolt gun": [3, 1], "Pipe shotgun": [3, 1], "Sawn-off": [3, 1], "Workshop SMG": [3, 1],
	"Police carbine": [3, 1], "Army SMG": [3, 1], "Belt-fed SMG": [3, 1], "Army bullpup": [3, 1], "Workshop carbine": [3, 1],
	"Security guard's carbine": [3, 1], "Courier's SMG": [3, 1], "Armoured car gun": [3, 1],      # the SMG line (7 Oct); the riot squad's SMG is the slot's four
	# scoped long guns
	"Old .303": [5, 1], "Scoped .308": [5, 1], "Sniper rifle": [5, 1], "Marksman rifle": [5, 1], "Section gun": [5, 1], "Police marksman's rifle": [5, 1],
	"Range rifle": [5, 1], "Service rifle": [5, 1], "Anti-materiel rifle": [5, 1], "Bolt-action garage rifle": [5, 1],     # the deep bases (10 Oct)
	"Demolition bar": [3, 1], "Rescue axe": [3, 1], "Door ram": [3, 1],
	# heavy armour
	"Riot suit": [3, 4], "Full plate carrier": [3, 4], "Issue plates": [3, 4], "Bomb suit": [3, 4], "Butcher's chainmail": [3, 4],
	"Military plate carrier": [3, 4], "Special forces plates": [3, 4], "CBRN suit": [3, 4], "Heavy armour suit": [3, 4], "Full EOD suit": [3, 4],
	# bags
	"Plastic bag": [2, 2], "School bag": [2, 2], "Carrier bags": [2, 2], "Holdall": [2, 2],
	"Framed pack": [3, 4], "Expedition pack": [3, 4], "Cargo frame": [3, 4], "Patrol pack": [3, 4], "Full bergen": [3, 4],
	"Assault pack": [3, 4], "Long-range bergen": [3, 4], "Mountain-troop bergen": [3, 4], "Special forces bergen": [3, 4],
	# medical
	"First aid kit": [2, 1], "Trauma kit": [2, 1], "Surgeon's kit": [2, 2], "Hospital kit": [2, 2],
	# the deeds
	"The deeds": [2, 2],
	# optics
	"Red dot": [2, 1], "Torch": [2, 1], "Holo sight": [2, 1], "Telescopic sight": [2, 1], "Thermal sight": [2, 1], "Night optic": [2, 1], "Laser module": [2, 1],
}

## The stash in cells before the Yard's picks: one page, thirteen cells a row, seven rows.
const STASH_CELLS := 91
## The Clinic's rest and shelf, the Fence's shelf, the hours away, the odds' dry runs before the Yard's picks.
const REST_BASE := 0.5
const CLINIC_STOCK := 6
const AWAY_HOURS := 8
const ODDS_RUNS := 24

## The Yard's buildings as lanes (9 Oct, docs/design/yard.md; Matt: the upgrades were done before the City, "I
## still need yard upgrades even when I'm 9 depths deep", "the choices need to be more memorable and scale more").
## Each building: five columns of two picks - take one, the other stays on show; refit for half - and a rank in
## the sixth, bought again and again. A column opens on the campaign and the depth (YARD_GATES), once for good;
## its price is the building's `costs` entry × inflation, the fifth column and the rank salvage too. The
## buildings move with the Yard. `short` is the tile's figure, `words` the strip's sentence.
const YARD_COLS := 6
const YARD_GATES := ["From the start", "With the Town open", "With the City open", "With the campaign done", "At depth 6", "At depth 9"]
const YARD_GATE_SHORT := ["start", "the Town", "the City", "the campaign", "depth 6", "depth 9"]
const YARD_PICK_SALVAGE := 10            # the fifth column's salvage
const YARD_RANK_CASH := 50000            # a rank's cash, × YARD_RANK_GROWTH a rank bought, × inflation
const YARD_RANK_GROWTH := 1.25
const YARD_RANK_SALVAGE := 5             # a rank's salvage, one more a rank bought
const YARD_REFIT := 0.5                  # changing a pick: this share of the column's price
## Salvage (9 Oct): one kind a zone, from kills on its sites from SALVAGE_DEPTH, SALVAGE_KILL a kill a depth past.
const SALVAGE := ["copper", "steel", "army"]
const ZONE_SALVAGE := ["", "copper", "steel", "army"]     # by zone (12 Oct): the Outskirts has none
const SALVAGE_NAMES := {"copper": "Copper", "steel": "Safe steel", "army": "Army surplus"}
const SALVAGE_DEPTH := 4
const SALVAGE_KILL := 0.01
const YARD := [
	{"key": "bench", "name": "The Bench", "salvage": "steel", "costs": [2000, 7000, 16000, 40000, 80000], "picks": [
		[{"id": "steady_hands", "name": "Steady hands", "short": "One-affix odds ×2", "words": "Re-rolling one affix: twice the chance it goes up a tier"},
		 {"id": "cheap_parts", "name": "Cheap parts", "short": "Every job −25%", "words": "Every job at the Bench costs a quarter less"}],
		[{"id": "third_socket", "name": "Third socket", "short": "Sockets to three", "words": "A third socket can be cut in a gun or armour"},
		 {"id": "two_locks", "name": "Two locks", "short": "A lock keeps two", "words": "A lock keeps the affix you pick and the best of the rest"}],
		[{"id": "gunsmith", "name": "Gunsmith", "short": "Guns at your depth", "words": "Improvised guns built at your deepest site's level, not their own"},
		 {"id": "strip_for_parts", "name": "Strip for parts", "short": "Scrap ×2", "words": "Scrapping gives twice the scrap"}],
		[{"id": "overbump", "name": "Overbump", "short": "A bump +6 levels", "words": "A bump raises an item six levels, not three"},
		 {"id": "fine_tuning", "name": "Fine tuning", "short": "Never rolls down", "words": "Re-rolling one affix never takes it down a tier"}],
		[{"id": "masterwork", "name": "Masterwork", "short": "Top-half rolls", "words": "An affix the Bench rolls lands in the top half of its tier"},
		 {"id": "salvage_line", "name": "Salvage line", "short": "Rares give steel", "words": "Scrapping a Rare or better also gives a Safe steel"}]],
	 "rank": {"short": "Item-level cap +1", "words": "Bumps go one item level higher a rank"}},
	{"key": "stash", "name": "The Stash", "salvage": "copper", "costs": [1500, 6000, 15000, 35000, 80000], "picks": [
		[{"id": "shelving", "name": "Shelving", "short": "+40 cells", "words": "Forty more cells in the stash"},
		 {"id": "racks", "name": "Racks", "short": "Rounds take no room", "words": "Rounds, meds and grenades in the stash take no cells"}],
		[{"id": "another_unit", "name": "Another unit", "short": "+50 cells", "words": "Fifty more cells in the stash"},
		 {"id": "bins", "name": "Bins", "short": "Commons to scrap", "words": "The common gear a run brings home goes straight to scrap"}],
		[{"id": "strongroom", "name": "Strongroom", "short": "Insurance half", "words": "Insuring a run costs half"},
		 {"id": "wall_of_fame", "name": "Wall of fame", "short": "Uniques take no room", "words": "Uniques and set pieces in the stash take no cells"}],
		[{"id": "lock_up", "name": "Lock-up", "short": "+60 cells", "words": "Sixty more cells in the stash"},
		 {"id": "paper_rack", "name": "Paper rack", "short": "Papers take no room", "words": "Papers and charms in the stash take no cells"}],
		[{"id": "dry_store", "name": "Dry store", "short": "Moves keep 75%", "words": "A move keeps three quarters of the notes and scrap, not half"},
		 {"id": "annex", "name": "Annex", "short": "+100 cells", "words": "A hundred more cells in the stash"}]],
	 "rank": {"short": "+20 cells", "words": "Twenty more cells a rank"}},
	{"key": "clinic", "name": "The Clinic", "salvage": "steel", "costs": [1200, 5000, 12000, 30000, 80000], "picks": [
		[{"id": "beds", "name": "Beds", "short": "Rest +0.5 HP/s", "words": "Resting heals half an HP a second more"},
		 {"id": "shelf", "name": "Shelf", "short": "Ten meds stocked", "words": "Ten meds on the Clinic's shelf, not six"}],
		[{"id": "ward", "name": "Ward", "short": "Rest +1 HP/s", "words": "Resting heals an HP a second more"},
		 {"id": "stockroom", "name": "Stockroom", "short": "Six more meds", "words": "Six more meds on the Clinic's shelf"}],
		[{"id": "surgery", "name": "Surgery", "short": "Wounds half price", "words": "Treating a wound costs half"},
		 {"id": "physio", "name": "Physio", "short": "Wounds a third less", "words": "A wound takes a third less off"}],
		[{"id": "drip", "name": "Drip", "short": "1% HP/s searching", "words": "1% of max HP a second back while a site is searched"},
		 {"id": "field_kit", "name": "Field kit", "short": "A bandage a run", "words": "Every run sets off with a free bandage in the rig, if there's room"}],
		[{"id": "theatre", "name": "Theatre", "short": "+10% max HP", "words": "Ten per cent more max HP"},
		 {"id": "med_lab", "name": "Med lab", "short": "Meds +25%", "words": "Every med heals a quarter more"}]],
	 "rank": {"short": "+3% max HP", "words": "Three per cent more max HP a rank"}},
	{"key": "fence", "name": "The Fence", "salvage": "army", "costs": [2000, 7000, 18000, 40000, 80000], "picks": [
		[{"id": "stall", "name": "Stall", "short": "Two more for sale", "words": "Two more things on the Fence's shelf"},
		 {"id": "haggling", "name": "Haggling", "short": "Sells 10% more", "words": "Everything sells for a tenth more"}],
		[{"id": "shopfront", "name": "Shopfront", "short": "Three more for sale", "words": "Three more things on the Fence's shelf"},
		 {"id": "orders", "name": "Orders", "short": "Five contracts", "words": "Five contracts open, not three"}],
		[{"id": "back_room", "name": "Back room", "short": "A unique in stock", "words": "A unique always on the shelf"},
		 {"id": "fixer", "name": "Fixer", "short": "Contracts notes ×2", "words": "Contracts that pay notes pay twice the notes"}],
		[{"id": "gamblers_table", "name": "Gambler's table", "short": "Gambles half price", "words": "Every gamble costs half"},
		 {"id": "insurance_desk", "name": "Insurance desk", "short": "Insured: pack kept", "words": "An insured run that dies keeps the pack too"}],
		[{"id": "arms_dealer", "name": "Arms dealer", "short": "Stock at your depth", "words": "The shelf rolls at your deepest site's level"},
		 {"id": "dealers_cut", "name": "Dealer's cut", "short": "Sells 25% more", "words": "Everything sells for a quarter more"}]],
	 "rank": {"short": "+2% on sales", "words": "Two per cent more for everything sold, a rank"}},
	{"key": "radio", "name": "The Radio", "salvage": "army", "costs": [1500, 6000, 15000, 40000, 80000], "picks": [
		# map juicing (9 Oct, docs/design/juicing.md §8): the first two columns help the campaign through the sky, the rest the words
		[{"id": "weather_set", "name": "Weather set", "short": "Rain, fog half", "words": "Rain and fog bite half as hard"},
		 {"id": "night_set", "name": "Night set", "short": "Night pace halved", "words": "Night's slower feet halved"}],
		[{"id": "forecast", "name": "The forecast", "short": "Weather pays +20%", "words": "A run under rain or fog brings a fifth more cash home"},
		 {"id": "dead_air", "name": "Dead air", "short": "Night gangs later", "words": "At Night the gangs come a quarter later"}],
		[{"id": "scanner", "name": "Scanner", "short": "Crafts −25%", "words": "Every craft at the Radio a quarter cheaper"},
		 {"id": "two_channels", "name": "Two channels", "short": "Rolls twice", "words": "Tune in and Retune roll twice and keep the better"}],
		[{"id": "lorry_watch", "name": "Lorry watch", "short": "Convoy 2 shallower", "words": "The convoy comes two depths shallower"},
		 {"id": "long_range", "name": "Long range", "short": "A word more", "words": "A site carries one more word"}],
		[{"id": "jammer", "name": "Jammer", "short": "Words bite half", "words": "Every word's bite - their health, their fire, more on you - is halved"},
		 {"id": "military_band", "name": "Military band", "short": "Rewards ×1.5", "words": "Every word's reward - cash, XP, drops, quality - half again"}]],
	 "rank": {"short": "Rewards +5%", "words": "Every word's reward five per cent more, a rank"}},
	{"key": "generator", "name": "The Generator", "salvage": "copper", "costs": [2500, 8000, 20000, 50000, 80000], "picks": [
		[{"id": "twelve_hours", "name": "Twelve hours", "short": "12 h away", "words": "Twelve hours away count, not eight"},
		 {"id": "rig_wiring", "name": "Rig wiring", "short": "+4 pouches", "words": "Four more pouches on the rig"}],
		[{"id": "a_day", "name": "A day away", "short": "24 h away", "words": "A day away counts"},
		 {"id": "floodlights", "name": "Floodlights", "short": "Night, not slow", "words": "Night's rarer finds without its slower feet"}],
		[{"id": "battery", "name": "Battery", "short": "+8 pouches", "words": "Eight more pouches on the rig"},
		 {"id": "overtime", "name": "Overtime", "short": "Away pays +25%", "words": "Cash made while you're away comes in a quarter higher"}],
		[{"id": "two_days", "name": "Two days", "short": "48 h away", "words": "Two days away count"},
		 {"id": "arc_lamps", "name": "Arc lamps", "short": "Fire, shock +10%", "words": "Fire and shock do a tenth more"}],
		[{"id": "grid", "name": "The grid", "short": "72 h away", "words": "Three days away count"},
		 {"id": "charger", "name": "Charger", "short": "Runs start full", "words": "Every run sets off on full HP"}]],
	 "rank": {"short": "Away +3%", "words": "Cash made while you're away three per cent higher, a rank"}},
	{"key": "lookout", "name": "The Lookout", "salvage": "steel", "costs": [2500, 8000, 20000, 45000, 80000], "picks": [
		[{"id": "spotter", "name": "Spotter", "short": "First gang ×1.5 later", "words": "The first gang takes half as long again to arrive"},
		 {"id": "glasses", "name": "Glasses", "short": "Odds from 60 runs", "words": "The odds shown are read from sixty dry runs, not twenty-four"}],
		[{"id": "lookout_post", "name": "Lookout post", "short": "First gang +50% later", "words": "The first gang takes half as long again to arrive, on top"},
		 {"id": "range_cards", "name": "Range cards", "short": "First shot +50%", "words": "The first shot on every gang does half again"}],
		[{"id": "hold_fire", "name": "Hold fire", "short": "Waits for a full pack", "words": "After the clear, the first gang waits until the pack is full"},
		 {"id": "tripwires", "name": "Tripwires", "short": "Gangs 10% later", "words": "Every gang takes a tenth longer to arrive"}],
		[{"id": "whistle", "name": "The whistle", "short": "Auto runs on wounded", "words": "Auto-run carries on through a wound"},
		 {"id": "watch_rota", "name": "Watch rota", "short": "Gangs 10% later", "words": "Every gang takes a tenth longer to arrive"}],
		[{"id": "crows_nest", "name": "Crow's nest", "short": "Gangs 20% later", "words": "Every gang takes a fifth longer to arrive"},
		 {"id": "flares", "name": "Flares", "short": "A head short", "words": "Every gang arrives one head short"}]],
	 "rank": {"short": "Gangs 2% later", "words": "Every gang two per cent later, a rank"}},
	{"key": "kennel", "name": "The Kennel", "salvage": "copper", "costs": [2500, 7000, 18000, 40000, 80000], "picks": [
		[{"id": "a_dog", "name": "A dog", "short": "+1 find a search", "words": "One more find every search"},
		 {"id": "good_nose", "name": "A good nose", "short": "+5% quality", "words": "Five per cent better finds"}],
		[{"id": "guard_dog", "name": "Guard dog", "short": "Gangs 20% later", "words": "It hears them coming: every gang a fifth later"},
		 {"id": "pedigree", "name": "Pedigree", "short": "+10% quality", "words": "Ten per cent better finds"}],
		[{"id": "fetch", "name": "Fetch", "short": "Best piece home", "words": "On a death the dog carries the best thing in the pack home"},
		 {"id": "second_dog", "name": "Second dog", "short": "+1 find a search", "words": "One more find every search"}],
		[{"id": "tracker", "name": "Tracker", "short": "Papers ×2", "words": "Papers and charms turn up twice as often"},
		 {"id": "ratter", "name": "Ratter", "short": "Poison, bleed +10%", "words": "Poison and bleed do a tenth more"}],
		[{"id": "pack", "name": "The pack", "short": "+2 finds a search", "words": "Two more finds every search"},
		 {"id": "champion", "name": "Champion", "short": "+20% quality", "words": "Twenty per cent better finds"}]],
	 "rank": {"short": "+2% quality", "words": "Two per cent better finds, a rank"}},
]


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
	"Primary": "dps", "Secondary": "dps", "Helmet": "armour", "Armour": "armour",
	"Rig": "capacity", "Backpack": "capacity", "Medical": "heal", "Attachment": "attach", "Ammo": "rounds", "Paper": "value", "Grenade": "throw",
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
		{"name": "Pipe shotgun", "type": "improvised", "ammo": "shotgun", "tier": 1, "damage": 50.0, "rof": 0.3, "value": 60,
			"attachments": ["stock"]},
		{"name": "Crossbow", "type": "improvised", "tier": 2, "damage": 60.0, "rof": 0.45, "value": 75,
			"attachments": ["optic", "stock"]},
		{"name": "Garage-built rifle", "type": "improvised", "ammo": "rifle", "tier": 3, "damage": 30.0, "rof": 1.5, "value": 150,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		# shotguns - the Doorman's
		{"name": "Farmer's shotgun", "type": "shotgun", "tier": 1, "damage": 45.0, "rof": 0.5, "value": 120,
			"attachments": ["muzzle", "stock"]},
		{"name": "Sawn-off", "type": "shotgun", "tier": 1, "damage": 55.0, "rof": 0.35, "value": 100,
			"attachments": ["stock"]},
		{"name": "Pump shotgun", "type": "shotgun", "tier": 2, "damage": 42.0, "rof": 0.8, "value": 90,
			"attachments": ["muzzle", "magazine", "stock"]},
		{"name": "Riot shotgun", "type": "shotgun", "tier": 3, "damage": 50.0, "rof": 1.0, "value": 170,
			"attachments": ["optic", "muzzle", "magazine", "stock"]},
		{"name": "Semi-auto shotgun", "type": "shotgun", "tier": 3, "damage": 38.0, "rof": 1.4, "value": 180,
			"attachments": ["optic", "muzzle", "magazine", "handguard"]},
		# rifles - the Poacher's
		{"name": "Semi-auto .22", "type": "rifle", "tier": 2, "damage": 18.0, "rof": 1.7, "value": 90,
			"attachments": ["optic", "muzzle", "magazine", "handguard"]},
		{"name": "Old .303", "type": "rifle", "tier": 2, "damage": 65.0, "rof": 0.5, "value": 85,
			"attachments": ["optic", "stock"]},
		{"name": "Stalking rifle", "type": "rifle", "tier": 3, "damage": 58.0, "rof": 0.8, "value": 160,
			"attachments": ["optic", "muzzle", "magazine", "stock"]},
		{"name": "Army bullpup", "type": "rifle", "tier": 3, "damage": 20.0, "rof": 2.6, "value": 180,
			"attachments": ["optic", "muzzle", "magazine", "handguard"]},
		{"name": "AR-pattern rifle", "type": "rifle", "tier": 3, "damage": 16.0, "rof": 3.0, "value": 170,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Battle rifle", "type": "rifle", "tier": 3, "damage": 36.0, "rof": 1.4, "value": 190,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		# SMGs - the Drifter's. The line (7 Oct): a gun a tier from T2 to T6, two at T6 like the shotguns, the top a shade
		# over theirs and paid for in rounds; every SMG primary carries walking fire (`sustain`: the stream grows so much a
		# second on one gang, to the cap), the long fight's gun
		{"name": "Workshop SMG", "type": "smg", "tier": 2, "damage": 15.0, "rof": 2.3, "value": 100, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Police carbine", "type": "smg", "tier": 3, "damage": 17.0, "rof": 2.8, "value": 175, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Security guard's carbine", "type": "smg", "tier": 3, "damage": 18.0, "rof": 3.0, "value": 190, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Courier's SMG", "type": "smg", "tier": 4, "damage": 21.0, "rof": 3.6, "value": 310, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Armoured car gun", "type": "smg", "tier": 5, "damage": 25.0, "rof": 4.0, "value": 520, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Riot squad's SMG", "type": "smg", "tier": 6, "damage": 28.0, "rof": 4.4, "value": 760, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		# tiers 4 and 5: the town's, and past it
		{"name": "Workshop carbine", "type": "improvised", "ammo": "smg", "tier": 4, "damage": 34.0, "rof": 1.9, "value": 260,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Drum shotgun", "type": "shotgun", "tier": 4, "damage": 44.0, "rof": 1.5, "value": 280,
			"attachments": ["optic", "muzzle", "magazine", "stock"]},
		{"name": "Scoped .308", "type": "rifle", "tier": 4, "damage": 80.0, "rof": 0.85, "value": 300,
			"attachments": ["optic", "muzzle", "magazine", "stock"]},
		{"name": "Army SMG", "type": "smg", "tier": 4, "damage": 20.0, "rof": 3.4, "value": 290, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Tooled-up garage rifle", "type": "improvised", "ammo": "rifle", "tier": 5, "damage": 40.0, "rof": 2.3, "value": 420,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Automatic shotgun", "type": "shotgun", "tier": 5, "damage": 46.0, "rof": 2.0, "value": 460,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Sniper rifle", "type": "rifle", "tier": 5, "damage": 110.0, "rof": 0.85, "value": 480,
			"attachments": ["optic", "muzzle", "magazine", "stock"]},
		# tier 6: the city's - the Services, the Hospital, the Barracks
		{"name": "Armourer's carbine", "type": "improvised", "ammo": "smg", "tier": 6, "damage": 44.0, "rof": 2.6, "value": 650,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		## the top of the pool (6 Oct): the firearms squad's and the Barracks' own
		{"name": "Police marksman's rifle", "type": "rifle", "tier": 6, "damage": 125.0, "rof": 0.9, "value": 820,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Riot squad's shotgun", "type": "shotgun", "tier": 6, "damage": 52.0, "rof": 2.2, "value": 760,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		# melee: no rounds ever, slow, hard, a fifth of it bleed; in among them, so they hit you harder
		# and their first shot lands before your first swing. Grip and head mounts of their own.
		{"name": "Spiked bat", "type": "melee", "ammo": "none", "tier": 1, "damage": 40.0, "rof": 0.5, "value": 30, "conv_bleed_pct": 20,
			"attachments": ["grip", "business end"]},
		{"name": "Machete", "type": "melee", "ammo": "none", "tier": 2, "damage": 30.0, "rof": 0.9, "value": 70, "conv_bleed_pct": 30,
			"attachments": ["grip"]},
		{"name": "Pipe wrench", "type": "melee", "ammo": "none", "tier": 2, "damage": 55.0, "rof": 0.5, "value": 60, "conv_bleed_pct": 10,
			"attachments": ["grip", "business end"]},
		{"name": "Fire axe", "type": "melee", "ammo": "none", "tier": 3, "damage": 70.0, "rof": 0.6, "value": 150, "conv_bleed_pct": 25,
			"attachments": ["grip", "business end"]},
		{"name": "Bayonet on a stick", "type": "melee", "ammo": "none", "tier": 4, "damage": 60.0, "rof": 0.9, "value": 260, "conv_bleed_pct": 30,
			"attachments": ["grip", "business end"]},
		{"name": "Sledgehammer", "type": "melee", "ammo": "none", "tier": 5, "damage": 160.0, "rof": 0.45, "value": 420, "conv_bleed_pct": 5,
			"attachments": ["grip", "business end"]},
		{"name": "Breaker bar", "type": "melee", "ammo": "none", "tier": 6, "damage": 90.0, "rof": 1.2, "value": 640, "conv_bleed_pct": 15,
			"attachments": ["grip", "business end"]},
		{"name": "Assault shotgun", "type": "shotgun", "tier": 6, "damage": 48.0, "rof": 2.4, "value": 680,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Marksman rifle", "type": "rifle", "tier": 6, "damage": 90.0, "rof": 1.1, "value": 720,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Section gun", "type": "smg", "tier": 6, "damage": 27.0, "rof": 4.4, "value": 700, "sustain": [4, 40],     # lifted (7 Oct): 26 × 4.2 read 109 against the shotguns' 115
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Belt-fed SMG", "type": "smg", "tier": 5, "damage": 24.0, "rof": 3.8, "value": 470, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		## the deep bases (10 Oct, docs/design/deep_guns.md): tiers 7-9, found from level 12, 16 and 20 (the Barracks at depth
		## 4, 8, 12); about +18% damage a second a tier on each type's own line, so the climb has a base to chase all the way down
		{"name": "Security service SMG", "type": "smg", "tier": 7, "damage": 31.0, "rof": 4.6, "value": 1050, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Close protection SMG", "type": "smg", "tier": 8, "damage": 34.0, "rof": 4.9, "value": 1450, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Special forces SMG", "type": "smg", "tier": 9, "damage": 37.0, "rof": 5.2, "value": 2000, "sustain": [4, 40],
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Range rifle", "type": "rifle", "tier": 7, "damage": 96.0, "rof": 1.4, "value": 1100,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Service rifle", "type": "rifle", "tier": 8, "damage": 104.0, "rof": 1.5, "value": 1500,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Anti-materiel rifle", "type": "rifle", "tier": 9, "damage": 150.0, "rof": 1.2, "value": 2100,
			"attachments": ["optic", "muzzle", "magazine", "stock"]},
		{"name": "Breaching shotgun", "type": "shotgun", "tier": 7, "damage": 60.0, "rof": 2.25, "value": 1050,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Entry shotgun", "type": "shotgun", "tier": 8, "damage": 66.0, "rof": 2.4, "value": 1450,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Combat shotgun", "type": "shotgun", "tier": 9, "damage": 74.0, "rof": 2.55, "value": 2000,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Bolt-action garage rifle", "type": "improvised", "ammo": "rifle", "tier": 7, "damage": 112.0, "rof": 1.2, "value": 900,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Workshop gauss", "type": "improvised", "tier": 8, "damage": 52.0, "rof": 3.0, "value": 1250,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "The engineer's piece", "type": "improvised", "ammo": "smg", "tier": 9, "damage": 50.0, "rof": 3.6, "value": 1700,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Demolition bar", "type": "melee", "ammo": "none", "tier": 7, "damage": 100.0, "rof": 1.3, "value": 900, "conv_bleed_pct": 15,
			"attachments": ["grip", "business end"]},
		{"name": "Rescue axe", "type": "melee", "ammo": "none", "tier": 8, "damage": 120.0, "rof": 1.3, "value": 1250, "conv_bleed_pct": 25,
			"attachments": ["grip", "business end"]},
		{"name": "Door ram", "type": "melee", "ammo": "none", "tier": 9, "damage": 220.0, "rof": 0.82, "value": 1700, "conv_bleed_pct": 5,
			"attachments": ["grip", "business end"]},
	],
	"Secondary": [
		{"name": "Converted blank-firer", "type": "improvised", "ammo": "pistol", "tier": 1, "damage": 12.0, "rof": 1.5, "value": 40,
			"attachments": ["muzzle"]},
		{"name": "Flare pistol", "type": "improvised", "tier": 1, "damage": 30.0, "rof": 0.5, "value": 30,
			"attachments": []},
		{"name": "Knife", "type": "melee", "ammo": "none", "tier": 1, "damage": 9.0, "rof": 1.8, "value": 15, "conv_bleed_pct": 40,
			"attachments": ["grip"]},
		{"name": "Knuckle duster", "type": "melee", "ammo": "none", "tier": 2, "damage": 14.0, "rof": 1.5, "value": 40, "conv_bleed_pct": 10,
			"attachments": []},
		{"name": "Cosh", "type": "melee", "ammo": "none", "tier": 3, "damage": 24.0, "rof": 1.0, "value": 90, "conv_bleed_pct": 5,
			"attachments": ["grip"]},
		{"name": "Air pistol", "type": "improvised", "tier": 1, "damage": 8.0, "rof": 2.0, "value": 25,
			"attachments": ["optic"]},
		{"name": "Service pistol", "type": "pistol", "tier": 2, "damage": 15.0, "rof": 1.6, "value": 40,
			"attachments": ["optic", "muzzle", "magazine"]},
		{"name": "Old revolver", "type": "pistol", "tier": 2, "damage": 28.0, "rof": 0.8, "value": 40,
			"attachments": ["optic"]},
		{"name": "Compact pistol", "type": "pistol", "tier": 2, "damage": 13.0, "rof": 2.0, "value": 45,
			"attachments": ["muzzle"]},
		{"name": "Machine pistol", "type": "smg", "tier": 3, "damage": 9.0, "rof": 3.2, "value": 100,
			"attachments": ["muzzle", "magazine", "stock"]},
		{"name": "Big revolver", "type": "pistol", "tier": 3, "damage": 40.0, "rof": 0.8, "value": 90,
			"attachments": ["optic", "muzzle"]},
		{"name": "Tactical pistol", "type": "pistol", "tier": 4, "damage": 20.0, "rof": 2.2, "value": 150,
			"attachments": ["optic", "muzzle", "magazine"]},
		{"name": "Officer's revolver", "type": "pistol", "tier": 6, "damage": 48.0, "rof": 1.2, "value": 360,
			"attachments": ["optic", "muzzle"]},
		{"name": "Army machine pistol", "type": "smg", "tier": 6, "damage": 16.0, "rof": 4.6, "value": 380,
			"attachments": ["muzzle", "magazine", "stock"]},
		{"name": "Issue pistol", "type": "pistol", "tier": 6, "damage": 22.0, "rof": 2.4, "value": 300,
			"attachments": ["optic", "muzzle", "magazine"]},
		{"name": "Automatic pistol", "type": "smg", "tier": 5, "damage": 14.0, "rof": 4.2, "value": 240,
			"attachments": ["optic", "muzzle", "magazine", "stock"]},
		## the deep bases (10 Oct): tiers 7-9 on the pistol and the machine pistol lines
		{"name": "Close quarters pistol", "type": "pistol", "tier": 7, "damage": 24.0, "rof": 2.8, "value": 500,
			"attachments": ["optic", "muzzle", "magazine"]},
		{"name": "Bodyguard's pistol", "type": "pistol", "tier": 8, "damage": 27.0, "rof": 2.9, "value": 700,
			"attachments": ["optic", "muzzle", "magazine"]},
		{"name": "Special issue pistol", "type": "pistol", "tier": 9, "damage": 30.0, "rof": 3.1, "value": 950,
			"attachments": ["optic", "muzzle", "magazine"]},
		{"name": "Diplomatic machine pistol", "type": "smg", "tier": 7, "damage": 19.0, "rof": 4.6, "value": 530,
			"attachments": ["muzzle", "magazine", "stock"]},
		{"name": "Embassy PDW", "type": "smg", "tier": 8, "damage": 21.0, "rof": 4.9, "value": 740,
			"attachments": ["muzzle", "magazine", "stock"]},
		{"name": "Protection squad PDW", "type": "smg", "tier": 9, "damage": 24.0, "rof": 5.0, "value": 1000,
			"attachments": ["muzzle", "magazine", "stock"]},
	],
	## Armour and helmets: armour, and weight as pace - a riot suit stops a lot and
	## slows you; leathers stop less and don't.
	"Helmet": [
		{"name": "Hard hat", "tier": 1, "armour": 5.0, "value": 20},
		{"name": "Cycle helmet", "tier": 1, "armour": 4.0, "pace": 2, "value": 15},
		{"name": "Riot helmet", "tier": 2, "armour": 12.0, "value": 40},
		{"name": "Fire helmet", "tier": 2, "armour": 14.0, "pace": -3, "value": 35},
		{"name": "Army helmet", "tier": 3, "armour": 22.0, "value": 80},
		{"name": "Visored helmet", "tier": 3, "armour": 28.0, "pace": -5, "value": 110},
		{"name": "Ballistic visor", "tier": 4, "armour": 36.0, "pace": -3, "value": 180},
		{"name": "Full-face helmet", "tier": 5, "armour": 48.0, "pace": -6, "value": 280},
		{"name": "Composite helmet", "tier": 6, "armour": 60.0, "pace": -4, "value": 420},
		## resist gear (6 Oct): a resist built into the base, read by resist() beside the affixes
		{"name": "Welder's mask", "tier": 3, "armour": 22.0, "pace": -2, "value": 150, "res": {"fire": 35}},
		{"name": "Station helmet, visored", "tier": 4, "armour": 40.0, "pace": -3, "value": 300, "res": {"fire": 25}},
		{"name": "Bomb-squad helmet", "tier": 6, "armour": 72.0, "pace": -8, "value": 560, "res": {"fire": 20, "shock": 20}},
		## the deep bases (10 Oct): tiers 7-9, about +18% armour a tier, and the resist line carried on
		{"name": "High-cut helmet", "tier": 7, "armour": 70.0, "pace": -3, "value": 600},
		{"name": "Special forces helmet", "tier": 8, "armour": 82.0, "pace": -3, "value": 850},
		{"name": "CBRN helmet", "tier": 8, "armour": 70.0, "pace": -5, "value": 900, "res": {"poison": 30, "frost": 20}},
		{"name": "Command helmet", "tier": 9, "armour": 96.0, "pace": -4, "value": 1200},
		{"name": "Full EOD helmet", "tier": 9, "armour": 100.0, "pace": -8, "value": 1300, "res": {"fire": 25, "shock": 25}},
	],
	"Armour": [
		{"name": "Work jacket", "tier": 1, "armour": 6.0, "value": 10, "start": true},     # the start: the worst there is, never found
		{"name": "Stab vest", "tier": 1, "armour": 15.0, "value": 60},
		{"name": "Padded jacket", "tier": 1, "armour": 10.0, "pace": 2, "value": 40},
		{"name": "Police body armour", "tier": 2, "armour": 35.0, "value": 80},
		{"name": "Motorbike leathers", "tier": 2, "armour": 25.0, "pace": 4, "value": 90},
		{"name": "Army plates", "tier": 3, "armour": 60.0, "value": 160},
		{"name": "Ceramic plates", "tier": 3, "armour": 72.0, "value": 220},
		{"name": "Riot suit", "tier": 3, "armour": 85.0, "pace": -8, "value": 260},
		{"name": "Ballistic vest", "tier": 4, "armour": 100.0, "pace": -2, "value": 420},
		{"name": "Full plate carrier", "tier": 5, "armour": 140.0, "pace": -10, "value": 680},
		{"name": "Light plates", "tier": 5, "armour": 110.0, "pace": 2, "value": 720},
		{"name": "Issue plates", "tier": 6, "armour": 160.0, "pace": -6, "value": 900},
		## resist gear (6 Oct): what the trades wore against their own hazards
		{"name": "Fireman's tunic", "tier": 4, "armour": 55.0, "pace": -2, "value": 380, "res": {"fire": 40}},
		{"name": "Lineman's rubber coat", "tier": 4, "armour": 45.0, "value": 360, "res": {"shock": 45}},
		{"name": "Cold-store parka", "tier": 4, "armour": 40.0, "pace": -2, "value": 340, "res": {"frost": 45}},
		{"name": "Hazmat suit", "tier": 5, "armour": 50.0, "pace": -4, "value": 520, "res": {"poison": 50}},
		{"name": "Butcher's chainmail", "tier": 5, "armour": 90.0, "pace": -4, "value": 600, "res": {"bleed": 45}},
		{"name": "Bomb suit", "tier": 6, "armour": 190.0, "pace": -14, "value": 1200, "res": {"fire": 20, "shock": 20}},
		## the deep bases (10 Oct): tiers 7-9, about +16% armour a tier, and the resist line carried on
		{"name": "Military plate carrier", "tier": 7, "armour": 185.0, "pace": -6, "value": 1300},
		{"name": "Fire service turnout gear", "tier": 7, "armour": 110.0, "pace": -4, "value": 1100, "res": {"fire": 50}},
		{"name": "Special forces plates", "tier": 8, "armour": 215.0, "pace": -6, "value": 1700},
		{"name": "CBRN suit", "tier": 8, "armour": 120.0, "pace": -6, "value": 1500, "res": {"poison": 55, "frost": 30}},
		{"name": "Heavy armour suit", "tier": 9, "armour": 250.0, "pace": -12, "value": 2200},
		{"name": "Full EOD suit", "tier": 9, "armour": 260.0, "pace": -16, "value": 2400, "res": {"fire": 30, "shock": 30}},
	],
	## Rigs carry meds and ammo, a slot each; packs carry loot, in cells. Capacity in cells for packs:
	## a rifle is 3, a pistol or helmet 2, a med or an attachment 1.
	"Rig": [
		{"name": "Bum bag", "tier": 1, "capacity": 3, "value": 40},
		{"name": "Fishing vest", "tier": 2, "capacity": 5, "value": 60},
		{"name": "Paramedic's rig", "tier": 2, "capacity": 6, "pace": -2, "value": 90},
		{"name": "Chest rig", "tier": 3, "capacity": 7, "value": 140},
		{"name": "Webbing", "tier": 3, "capacity": 6, "pace": 3, "value": 120},
		{"name": "Medic's harness", "tier": 4, "capacity": 9, "pace": -2, "value": 220},
		{"name": "Plate rig", "tier": 5, "capacity": 8, "pace": 2, "value": 340},
		{"name": "Assault rig", "tier": 6, "capacity": 9, "value": 460},
		{"name": "Bomb-disposal rig", "tier": 6, "capacity": 11, "pace": -3, "value": 620},
		## the deep bases (10 Oct): tiers 7-9
		{"name": "Special forces rig", "tier": 7, "capacity": 12, "value": 800},
		{"name": "Breacher's rig", "tier": 8, "capacity": 13, "pace": 2, "value": 1000},
		{"name": "Command rig", "tier": 9, "capacity": 15, "pace": -2, "value": 1300},
	],
	"Backpack": [
		{"name": "Plastic bag", "tier": 1, "capacity": 9, "value": 5, "start": true},     # the start: the worst there is, never found; nine cells, so a found vest (3×3) comes home
		{"name": "School bag", "tier": 1, "capacity": 12, "value": 30},
		{"name": "Carrier bags", "tier": 1, "capacity": 10, "pace": 3, "value": 15},
		{"name": "Hiking pack", "tier": 2, "capacity": 24, "value": 60},
		{"name": "Holdall", "tier": 2, "capacity": 20, "pace": 2, "value": 70},
		{"name": "Bergen", "tier": 3, "capacity": 40, "value": 110},
		{"name": "Framed pack", "tier": 3, "capacity": 48, "pace": -5, "value": 160},
		{"name": "Expedition pack", "tier": 4, "capacity": 56, "pace": -3, "value": 260},
		{"name": "Cargo frame", "tier": 5, "capacity": 72, "pace": -8, "value": 400},
		{"name": "Patrol pack", "tier": 6, "capacity": 60, "value": 480},
		{"name": "Full bergen", "tier": 6, "capacity": 80, "pace": -6, "value": 640},
		## the deep bases (10 Oct): tiers 7-9
		{"name": "Assault pack", "tier": 7, "capacity": 72, "value": 820},
		{"name": "Long-range bergen", "tier": 7, "capacity": 96, "pace": -6, "value": 860},
		{"name": "Mountain-troop bergen", "tier": 8, "capacity": 112, "pace": -6, "value": 1100},
		{"name": "Special forces bergen", "tier": 9, "capacity": 130, "pace": -6, "value": 1450},
	],
	## Charms: `find` is magic find - rarer finds, in percent - and `cash`
	## percent on top. Every runner carries something.
	"Charm": [
		{"name": "Lucky penny", "tier": 1, "find": 5, "cash": 5, "value": 30},
		{"name": "Rabbit's foot", "tier": 1, "find": 8, "cash": 0, "value": 40},
		{"name": "St Christopher", "tier": 2, "find": 10, "cash": 5, "value": 90},
		{"name": "Horseshoe nail", "tier": 2, "find": 6, "cash": 12, "value": 90},
		{"name": "Wedding ring", "tier": 3, "find": 12, "cash": 10, "value": 180},
		{"name": "Dog tag", "tier": 4, "find": 15, "cash": 8, "value": 320},
		{"name": "Casino chip", "tier": 5, "find": 18, "cash": 15, "value": 520},
		{"name": "Bank's own pen", "tier": 6, "find": 20, "cash": 20, "value": 800},
		{"name": "Mayor's chain", "tier": 6, "find": 24, "cash": 24, "value": 1100},
		## the deep bases (10 Oct): tiers 7-9
		{"name": "Signet ring", "tier": 7, "find": 28, "cash": 26, "value": 1500},
		{"name": "Regimental medal", "tier": 8, "find": 32, "cash": 30, "value": 2000},
		{"name": "Gold sovereign", "tier": 9, "find": 36, "cash": 36, "value": 2700},
	],
	## Papers: the before, on paper. Worth their value to the Fence and nothing
	## else; the deeds are dropped by the Bank once and are the ending.
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
		# the deep ones: only past these depths, so the whole book is a reason to go there
		{"name": "A ration book", "tier": 1, "value": 4, "depth": 12},
		{"name": "A council minute", "tier": 1, "value": 4, "depth": 18},
		{"name": "A bus timetable, amended", "tier": 1, "value": 4, "depth": 24},
		{"name": "A letter to the Bank", "tier": 1, "value": 5, "depth": 30},
		{"name": "A list of names", "tier": 1, "value": 5, "depth": 40},
		{"name": "The Manager's note", "tier": 1, "value": 6, "depth": 50},
		{"name": "The deeds", "tier": 5, "value": 5000},
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
	],
	## Grenades (32): a pouch each, thrown at everyone on you; the hit is the type's, through the damage model
	"Grenade": [
		{"name": "Petrol bomb", "tier": 1, "damage": 80.0, "type": "fire", "value": 30, "from": "Lighter fluid"},
		{"name": "Nail bomb", "tier": 1, "damage": 70.0, "type": "bleed", "value": 30},
		{"name": "Bottle of something", "tier": 2, "damage": 90.0, "type": "poison", "value": 45, "from": "Rat poison"},
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
		{"name": "Belt links", "type": "smg", "tier": 3, "rounds": 500, "value": 160, "damage_pct": 20, "from": "SMG hollow point"},
		{"name": "Depot rounds", "type": "rifle", "tier": 3, "rounds": 300, "value": 170, "damage_pct": 25, "from": "Match rounds"},
		{"name": "Incendiary shells", "type": "shotgun", "tier": 3, "rounds": 80, "value": 140, "damage_pct": 10, "conv_fire_pct": 30, "from": "Slugs"},
		{"name": "Incendiary SMG rounds", "type": "smg", "tier": 3, "rounds": 320, "value": 150, "damage_pct": 10, "conv_fire_pct": 30, "from": "SMG hollow point"},
		{"name": "Salted rounds", "type": "rifle", "tier": 3, "rounds": 220, "value": 150, "damage_pct": 10, "conv_frost_pct": 30, "from": "Match rounds"},
	],
}
const AMMO_PRICE := 1.5             # the Fence's markup on a standard box
const AMMO_DROP := 0.22             # the share of a kill's drops that are rounds; a look's is half that
## Where loot comes from. A kill drops what they carried; a look over the
## site turns up what's lying there. Meds are rare either way; attachments
## are the site's. The weights are the lists: a slot listed twice is twice as likely.
const KILL_SLOTS := ["Primary", "Primary", "Secondary", "Helmet", "Armour", "Armour", "Rig"]
const SITE_SLOTS := ["Backpack", "Rig", "Secondary", "Helmet", "Primary", "Armour"]
const MED_PRICE := 1.5            # the Clinic's markup on a common med
const MED_DROP := 0.08            # the share of finds that are medical
const GRENADE_DROP := 0.04        # the share of a look's finds that are grenades (32)
const ATT_DROP := 0.30            # the share of a look's finds that are attachments

## Attachments: items that fit a gun's slots at the Workshop. `mount` is the
## gun slot they go in; the effects are read off the fitted gun. Rarer ones
## roll affixes like gear. The Workshop's level says which mounts can be
## fitted at all - the camp's cash sink.
const ATTACHMENT := "Attachment"
const MOUNTS := ["optic", "muzzle", "magazine", "handguard", "stock", "grip", "business end"]
const MELEE_INCOMING := 1.25       # in among them: their fire on you, with a melee primary
const MELEE_WAIT := 1.0            # seconds: their first shot lands before your first swing, each gang
## Sockets: a gun, a helmet or armour rolls up to SOCKET_MAX of them; a
## socketable (mount "socket") goes in any. What they add can't be had
## elsewhere: fire, frost, poison, shock, salt, wire.
const SOCKET_SLOTS := ["Primary", "Secondary", "Helmet", "Armour"]
const SOCKET_MAX := 2
const SOCKET_ODDS := [0.45, 0.4, 0.15]     # 0, 1, 2 sockets
const SOCKET_WORDS := {"conv_fire_pct": "fire", "conv_frost_pct": "frost", "conv_poison_pct": "poison", "conv_shock_pct": "shock", "salt": "salt", "wire_pct": "wire"}

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
	{"types": {"shock": 0.15, "fire": 0.15}, "res": {"fire": 0.2, "shock": 0.2, "physical": 0.2, "frost": 0.1}},   # the city: army kit, greatcoats
]
const ZONE_GROW := 0.02
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
	# magazines
	{"name": "Extended magazine", "mount": "magazine", "tier": 1, "value": 70, "damage_pct": 8},
	{"name": "Quick mag", "mount": "magazine", "tier": 2, "value": 90, "damage_pct": 4, "speed_pct": 4},
	{"name": "Drum magazine", "mount": "magazine", "tier": 3, "value": 110, "damage_pct": 14, "speed_pct": -8},
	{"name": "Belt box", "mount": "magazine", "tier": 3, "value": 240, "damage_pct": 20, "speed_pct": -12, "type": "smg"},
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
	{"name": "Nails through it", "mount": "business end", "tier": 1, "value": 30, "conv_bleed_pct": 15},
	{"name": "A blade on it", "mount": "business end", "tier": 2, "value": 90, "damage_pct": 10, "conv_bleed_pct": 10},
	{"name": "Lead in it", "mount": "business end", "tier": 3, "value": 160, "damage_pct": 18, "speed_pct": -6},
	{"name": "Heavy stock", "mount": "stock", "tier": 2, "value": 80, "damage_pct": 9, "speed_pct": -4},
	{"name": "Cheek riser", "mount": "stock", "tier": 2, "value": 90, "first_pct": 10},
	{"name": "Recoil pad", "mount": "stock", "tier": 3, "value": 160, "damage_pct": 6, "first_pct": 3},
	# tiers 4 and 5
	{"name": "Night optic", "mount": "optic", "tier": 4, "value": 320, "first_pct": 40, "damage_pct": 5},
	{"name": "Ported brake", "mount": "muzzle", "tier": 4, "value": 300, "damage_pct": 15},
	{"name": "Angled grip", "mount": "handguard", "tier": 4, "value": 280, "damage_pct": 8, "speed_pct": 4},
	{"name": "Hundred-round drum", "mount": "magazine", "tier": 5, "value": 460, "damage_pct": 25, "speed_pct": -15},
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
## Uniques by tier (12 Oct, docs/design/uniques.md): every unique but a paper has a band and a range of tiers. It drops at
## the find's loot tier inside its range, on the best base of its slot (and gun type) at that tier; a loose one only where
## the find's tier is inside its range, the band's weight picking among those that can.
const UNIQUE_BAND_WEIGHT := {"levelling": 10.0, "core": 4.0, "chase": 1.0}
const SITE_UNIQUE_DEPTH := [99, 12, 9, 6]   # a site's own unique, by zone: the depth it drops from
const SITE_UNIQUE_DROP := 0.03          # a find past that depth, on that site, until it is on the shelf
const SITE_UNIQUE_AGAIN := 0.25         # of that, once it is: a second is for the Fence, not the chase
const UNIQUES := [
	{"name": "Grandad's Shotgun", "slot": "Primary", "base": "Farmer's shotgun", "rule": "grandads", "band": "levelling", "range": [1, 4],
		"words": "The first of every gang takes triple", "affixes": [{"stat": "damage_pct", "value": 10}, {"stat": "first_lot_pct", "value": 20}]},
	{"name": "The Postman's Bag", "slot": "Backpack", "base": "Hiking pack", "rule": "postman", "band": "levelling", "range": [1, 4],
		"words": "Every search finds one more", "affixes": [{"stat": "capacity", "value": 4}, {"stat": "loot_pct", "value": 15}]},
	{"name": "The Doorman's Jacket", "slot": "Armour", "base": "Police body armour", "rule": "doormans", "band": "levelling", "range": [2, 5],
		"words": "With three on you, take a quarter less", "affixes": [{"stat": "armour", "value": 12}, {"stat": "hp", "value": 20}]},
	{"name": "Lucky Cap", "slot": "Helmet", "base": "Hard hat", "rule": "lucky_cap", "band": "levelling", "range": [1, 4],
		"words": "Finds are half as likely to be common", "affixes": [{"stat": "loot_pct", "value": 20}, {"stat": "cash_per_kill", "value": 6}]},
	# the bosses' - only from them; their rules are the affixes, for now
	{"name": "The Van's Spare", "slot": "Secondary", "base": "Old revolver", "rule": "vans_spare", "band": "levelling", "range": [3, 6], "boss": true,
		"words": "The secondary fires at full damage, always", "affixes": [{"stat": "damage_pct", "value": 18}, {"stat": "first_lot_pct", "value": 25}, {"stat": "cash_per_kill", "value": 4}]},
	{"name": "Underlay", "slot": "Armour", "base": "Padded jacket", "rule": "underlay", "band": "levelling", "range": [3, 6], "boss": true,
		"words": "The first two seconds of every gang land on the underlay", "affixes": [{"stat": "armour", "value": 30}, {"stat": "hp", "value": 25}, {"stat": "speed_pct", "value": 6}]},
	{"name": "The Manager's Coat", "slot": "Armour", "base": "Ballistic vest", "rule": "managers_coat", "band": "core", "range": [5, 8], "boss": true,
		"words": "Cash half again; no notes - he doesn't take paper", "affixes": [{"stat": "armour", "value": 20}, {"stat": "cash_per_kill", "value": 8}, {"stat": "hp", "value": 20}]},
	{"name": "The Branch Pistol", "slot": "Secondary", "base": "Tactical pistol", "rule": "branch_pistol", "band": "core", "range": [5, 8], "boss": true,
		"words": "Under half HP the secondary fires twice as fast", "affixes": [{"stat": "damage_pct", "value": 20}, {"stat": "damage_low_pct", "value": 25}, {"stat": "speed_pct", "value": 6}]},
	{"name": "The Quartermaster's Rifle", "slot": "Primary", "base": "Marksman rifle", "rule": "qm_rifle", "band": "chase", "range": [7, 9], "boss": true,
		"words": "Never runs dry; he signed for the rounds", "affixes": [{"stat": "damage_pct", "value": 20}, {"stat": "first_lot_pct", "value": 30}, {"stat": "damage_per_att", "value": 5}]},
	{"name": "Issue Webbing", "slot": "Rig", "base": "Assault rig", "rule": "issue_webbing", "band": "chase", "range": [7, 9], "boss": true,
		"words": "Every pouch holds two", "affixes": [{"stat": "capacity", "value": 3}, {"stat": "armour", "value": 15}, {"stat": "loot_per_med", "value": 5}]},
	# the pinnacles' - a charm each, from a crew's head at full strength
	{"name": "The Van Keys", "slot": "Charm", "base": "Horseshoe nail", "rule": "van_keys", "band": "chase", "range": [6, 9], "boss": true, "pinnacle": 1,
		"words": "You drive: pace +25%", "affixes": [{"stat": "rarity_pct", "value": 10}, {"stat": "cash_pct", "value": 10}, {"stat": "loot_pct", "value": 8}]},
	{"name": "The Manager's Pen", "slot": "Charm", "base": "Bank's own pen", "rule": "managers_pen", "band": "chase", "range": [7, 9], "boss": true, "pinnacle": 2,
		"words": "Notes come in twos: every note found is two", "affixes": [{"stat": "rarity_pct", "value": 12}, {"stat": "cash_pct", "value": 15}, {"stat": "loot_pct", "value": 5}]},
	{"name": "The Quartermaster's Ledger", "slot": "Charm", "base": "Dog tag", "rule": "qm_ledger", "band": "chase", "range": [7, 9], "boss": true, "pinnacle": 3,
		"words": "Signed for: what a kill drops is a tier up", "affixes": [{"stat": "rarity_pct", "value": 15}, {"stat": "cash_pct", "value": 8}, {"stat": "loot_pct", "value": 10}]},
	# the convoy's
	{"name": "The Lorry's Load", "slot": "Backpack", "base": "Cargo frame", "rule": "lorrys_load", "band": "chase", "range": [7, 9], "boss": true, "convoy": true,
		"words": "The pack comes home full: every empty cell is notes", "affixes": [{"stat": "capacity", "value": 8}, {"stat": "loot_pct", "value": 15}, {"stat": "cash_per_cell", "value": 3}]},
	# the build-defining ones: a rule each, found loose from `depth` on, and from the mate once you've been that deep;
	# nine of them are a site's own (`site`, endgame part 3, 7 Oct): found only on that site, past SITE_UNIQUE_DEPTH for its
	# zone, SITE_UNIQUE_DROP a find - the estate's at 12, the town's at 9, the city's at 6, so the streets' is the deepest dig
	# in the game and the Barracks' the hardest fight. Never loose, never the mate's: the shelf shows the nine as gaps until found.
	{"name": "The Council's Weed Burner", "slot": "Primary", "base": "Pipe shotgun", "rule": "weed_burner", "band": "core", "range": [4, 9], "depth": 6,
		"words": "A flamethrower: all fire, fire hits everyone on you, takes nothing", "affixes": [{"stat": "fire_pct", "value": 40}, {"stat": "dot_pct", "value": 30}, {"stat": "speed_pct", "value": -10}]},
	{"name": "Jump Leads", "slot": "Secondary", "base": "Service pistol", "rule": "jump_leads", "band": "core", "range": [4, 9], "depth": 6,
		"words": "A third of your damage as shock; shock on one of them is shock on all of them", "affixes": [{"stat": "shock_pct", "value": 40}, {"stat": "first_pct", "value": 20}]},
	{"name": "The Rat Man's Bag", "slot": "Backpack", "base": "Hiking pack", "rule": "rat_mans_bag", "band": "core", "range": [4, 9], "depth": 6,
		"words": "Poison never caps and carries to the next of them", "affixes": [{"stat": "poison_pct", "value": 40}, {"stat": "capacity", "value": 6}, {"stat": "dot_pct", "value": 20}]},
	{"name": "The Butcher's Steel", "slot": "Primary", "base": "Machete", "rule": "butchers_steel", "band": "core", "range": [4, 9], "body": {"bleed_min": 25}, "depth": 6,
		"words": "Bleed does double, and a bleed carries to the next of them", "affixes": [{"stat": "bleed_pct", "value": 40}, {"stat": "conv_bleed_pct", "value": 25}, {"stat": "attack_pct", "value": 10}]},
	{"name": "The Gritter's Hopper", "slot": "Armour", "base": "Riot suit", "rule": "gritters_hopper", "band": "chase", "range": [6, 9], "site": 3,
		"words": "Everyone on you is chilled, always; chilled gangs come one at a time", "affixes": [{"stat": "frost_pct", "value": 40}, {"stat": "armour", "value": 30}, {"stat": "frost_res", "value": 30}]},
	{"name": "The Sparky's Gloves", "slot": "Charm", "base": "Horseshoe nail", "rule": "sparkys_gloves", "band": "core", "range": [4, 8], "site": 5,
		"words": "Their shock resist counts for nothing; shock costs you no armour", "affixes": [{"stat": "shock_pct", "value": 30}, {"stat": "shock_res", "value": 40}]},
	{"name": "The Quartermaster's Manual", "slot": "Charm", "base": "Dog tag", "rule": "qm_manual", "band": "chase", "range": [7, 9], "site": 11,
		"words": "Every element counts as the runner's: no doubled tree, every keystone open", "affixes": [{"stat": "rarity_pct", "value": 10}, {"stat": "all_res", "value": 8}]},
	{"name": "A Blue Plaque", "slot": "Charm", "base": "St Christopher", "rule": "blue_plaque", "band": "chase", "range": [6, 9], "site": 8,
		"words": "All resists +40%; nothing else on anything you wear counts", "affixes": [{"stat": "all_res", "value": 40}]},
	{"name": "The Lollipop Lady's Sign", "slot": "Secondary", "base": "Cosh", "rule": "lollipop", "band": "core", "range": [4, 9], "depth": 6,
		"words": "Stop: the first of every gang drops where it stands; gangs come half as often", "affixes": [{"stat": "first_pct", "value": 30}, {"stat": "patrol_pct", "value": 15}]},
	{"name": "The Bookie's Pencil", "slot": "Charm", "base": "Lucky penny", "rule": "bookies_pencil", "band": "core", "range": [4, 9], "depth": 6,
		"words": "Loot quality doubled; cash halved", "affixes": [{"stat": "rarity_pct", "value": 15}, {"stat": "loot_pct", "value": 10}]},
	{"name": "The Float", "slot": "Backpack", "base": "Cargo frame", "rule": "the_float", "band": "chase", "range": [6, 9], "site": 7,
		"words": "Pace +40% and the pack half again; you carry no meds", "affixes": [{"stat": "capacity", "value": 10}, {"stat": "speed_pct", "value": 15}, {"stat": "cash_pct", "value": 20}]},
	{"name": "Nan's Cardigan", "slot": "Armour", "base": "Padded jacket", "rule": "nans_cardigan", "band": "core", "range": [4, 9], "body": {"pace_min": 0}, "depth": 6,
		"words": "3% of your HP back a second; no armour at all", "affixes": [{"stat": "hp", "value": 40}, {"stat": "all_res", "value": 10}]},
	{"name": "The Dinner Lady's Ladle", "slot": "Primary", "base": "Pipe wrench", "rule": "ladle", "band": "core", "range": [4, 9], "depth": 6,
		"words": "Every kill is a tenth of your HP back; meds do nothing", "affixes": [{"stat": "damage_pct", "value": 20}, {"stat": "attack_pct", "value": 15}]},
	{"name": "A Traffic Warden's Hat", "slot": "Helmet", "base": "Hard hat", "rule": "wardens_hat", "band": "levelling", "range": [2, 5],
		"words": "Every gang arrives one short; every kill's notes doubled", "affixes": [{"stat": "notes_pct", "value": 25}, {"stat": "armour", "value": 10}]},
	{"name": "The Vicar's Thermos", "slot": "Charm", "base": "Casino chip", "rule": "vicars_thermos", "band": "chase", "range": [6, 9], "site": 10,
		"words": "A burn on you heals you instead; your fire resist is nothing", "affixes": [{"stat": "regen", "value": 3}, {"stat": "fire_pct", "value": 20}]},
	{"name": "The Scout Leader's Whistle", "slot": "Charm", "base": "Rabbit's foot", "rule": "scouts_whistle", "band": "levelling", "range": [1, 4],
		"words": "Every gang after the first is one", "affixes": [{"stat": "patrol_pct", "value": 10}, {"stat": "loot_pct", "value": 10}]},
	{"name": "The Sergeant's Whistle", "slot": "Helmet", "base": "Composite helmet", "rule": "sergeants_whistle", "band": "chase", "range": [7, 9], "site": 4,
		"words": "Two more on you at once; everything you do does 60% more", "affixes": [{"stat": "armour", "value": 20}, {"stat": "hp", "value": 30}, {"stat": "crowd_less_pct", "value": 10}]},
	{"name": "The Electrician's Tester", "slot": "Secondary", "base": "Compact pistol", "rule": "tester", "band": "core", "range": [4, 9], "depth": 6,
		"words": "Shocked stays shocked until they're down; shock does half", "affixes": [{"stat": "conv_shock_pct", "value": 25}, {"stat": "shock_pct", "value": 20}]},
	{"name": "The Gamekeeper's Flask", "slot": "Charm", "base": "Wedding ring", "rule": "gamekeepers_flask", "band": "core", "range": [4, 8], "site": 6,
		"words": "Poison on you poisons them back", "affixes": [{"stat": "poison_res", "value": 30}, {"stat": "poison_pct", "value": 30}]},
	{"name": "The Caretaker's Keys", "slot": "Charm", "base": "Bank's own pen", "rule": "caretakers_keys", "band": "chase", "range": [7, 9], "depth": 12,
		"words": "Something happens on every run, and every cache opens", "affixes": [{"stat": "loot_pct", "value": 15}, {"stat": "search_pct", "value": 10}]},
	{"name": "The Lorry Driver's Log", "slot": "Paper", "base": "A pawn ticket", "rule": "drivers_log", "site": 9,
		"words": "Notes found doubled; insurance is free", "affixes": [{"stat": "notes_pct", "value": 50}]},
	# the elements' own (6 Oct): one a type, each leaning the whole way into it, for the builds that break the game
	{"name": "The Arsonist's Rig", "slot": "Rig", "base": "Assault rig", "rule": "arsonists_rig", "band": "chase", "range": [7, 9], "depth": 14,
		"words": "Every med used sets everyone on you alight", "affixes": [{"stat": "fire_pct", "value": 40}, {"stat": "med_cap", "value": 2}, {"stat": "conv_fire_pct", "value": 20}]},
	{"name": "The Gritter's Keys", "slot": "Charm", "base": "Wedding ring", "rule": "gritters_keys", "band": "chase", "range": [7, 9], "depth": 14,
		"words": "A chill holds as long as you fire; chilled, they take double frost", "affixes": [{"stat": "frost_pct", "value": 40}, {"stat": "conv_frost_pct", "value": 25}]},
	{"name": "The Rat Man's Overalls", "slot": "Armour", "base": "Motorbike leathers", "rule": "rat_mans_overalls", "band": "chase", "range": [7, 9], "depth": 14,
		"words": "Poison stacks without end and ticks twice as fast", "affixes": [{"stat": "poison_pct", "value": 50}, {"stat": "poison_res", "value": 35}, {"stat": "armour", "value": 20}]},
	{"name": "The Substation Key", "slot": "Charm", "base": "Horseshoe nail", "rule": "substation_key", "band": "chase", "range": [7, 9], "depth": 14,
		"words": "Shock on one of them is shock on all; shocked, they take 60% more", "affixes": [{"stat": "shock_pct", "value": 40}, {"stat": "conv_shock_pct", "value": 20}]},
	{"name": "The Butcher's Apron", "slot": "Armour", "base": "Butcher's chainmail", "rule": "butchers_apron", "band": "chase", "range": [7, 9], "depth": 14,
		"words": "A bleed carries to the next of them and cuts three deep", "affixes": [{"stat": "bleed_pct", "value": 50}, {"stat": "conv_bleed_pct", "value": 25}, {"stat": "armour", "value": 25}]},
	# the gaps' (12 Oct, docs/design/uniques.md): a chase secondary, a core helmet, a levelling and a core rig
	{"name": "The Starting Pistol", "slot": "Secondary", "base": "Close quarters pistol", "rule": "starting_pistol", "band": "chase", "range": [7, 9], "depth": 12,
		"words": "Every gang opens on the secondary: its first shot at each of them lands, triple", "affixes": [{"stat": "damage_pct", "value": 20}, {"stat": "first_pct", "value": 25}]},
	{"name": "The Miner's Lamp", "slot": "Helmet", "base": "Ballistic visor", "rule": "miners_lamp", "band": "core", "range": [4, 7], "depth": 6,
		"words": "Searches take half as long", "affixes": [{"stat": "search_pct", "value": 20}, {"stat": "loot_pct", "value": 10}, {"stat": "armour", "value": 10}]},
	{"name": "The Paramedic's Bumbag", "slot": "Rig", "base": "Bum bag", "rule": "paramedics_bumbag", "band": "levelling", "range": [1, 4],
		"words": "Meds heal half again; one is used for you under 40% HP", "affixes": [{"stat": "med_cap", "value": 1}, {"stat": "hp", "value": 15}]},
	{"name": "The Plumber's Belt", "slot": "Rig", "base": "Medic's harness", "rule": "plumbers_belt", "band": "core", "range": [4, 7], "depth": 6,
		"words": "Burns, poison and bleeds on them build twice as deep; chills and shocks last twice as long", "affixes": [{"stat": "dot_pct", "value": 20}, {"stat": "capacity", "value": 2}]},
]
## Sets: whose gear it was. A piece is a fixed base with its own name and a
## couple of fixed affixes, rolled like a unique, drawn in the set's own
## tint; the bonuses come at two pieces worn and at the full set - stats,
## added to what's worn, and a rule at the top. Found loose from `depth` on.
const SET_DROP := 0.004            # a share of finds a depth past the first
const SETS := [
	{"name": "The Fire Crew's", "depth": 9, "words": "Breathing kit and a tunic from the station that answered the last call",
		"pieces": [
			{"name": "Station tunic", "slot": "Armour", "base": "Fireman's tunic", "affixes": [{"stat": "armour", "value": 20}, {"stat": "hp", "value": 20}]},
			{"name": "Station helmet", "slot": "Helmet", "base": "Station helmet, visored", "affixes": [{"stat": "armour", "value": 12}, {"stat": "fire_res", "value": 15}]},
			{"name": "Breathing set", "slot": "Rig", "base": "Medic's harness", "affixes": [{"stat": "med_cap", "value": 2}, {"stat": "poison_res", "value": 25}]},
		],
		"bonuses": {2: {"stats": {"fire_res": 40}, "words": "Fire resist +40%"},
			3: {"stats": {"all_res": 15, "regen": 2}, "words": "All resists +15%, +2 HP a second"}}},
	{"name": "The Council's", "depth": 5, "words": "Parks, highways, pest control: the Council's gear, orange and stamped",
		"pieces": [
			{"name": "Council hi-vis", "slot": "Armour", "base": "Stab vest", "affixes": [{"stat": "armour", "value": 10}, {"stat": "hp", "value": 12}]},
			{"name": "Council hard hat", "slot": "Helmet", "base": "Hard hat", "affixes": [{"stat": "armour", "value": 8}, {"stat": "search_pct", "value": 8}]},
			{"name": "Council rucksack", "slot": "Backpack", "base": "School bag", "affixes": [{"stat": "capacity", "value": 4}, {"stat": "loot_pct", "value": 10}]},
			{"name": "Council lanyard", "slot": "Charm", "base": "Lucky penny", "affixes": [{"stat": "notes_pct", "value": 15}, {"stat": "rarity_pct", "value": 6}]},
		],
		"bonuses": {2: {"stats": {"all_res": 20}, "words": "All resists +20%"}, 3: {"stats": {"regen": 4}, "words": "+4 HP a second"},
			4: {"stats": {"search_pct": 30, "notes_pct": 50}, "rule": "council", "words": "Searches 30% quicker, notes +50%, every cache opens"}}},
	{"name": "The Ambulance's", "depth": 8, "words": "A crew's kit from the one ambulance that kept going",
		"pieces": [
			{"name": "Ambulance rig", "slot": "Rig", "base": "Paramedic's rig", "affixes": [{"stat": "med_cap", "value": 2}, {"stat": "med_speed_pct", "value": 15}]},
			{"name": "Green overalls", "slot": "Armour", "base": "Padded jacket", "affixes": [{"stat": "hp", "value": 25}, {"stat": "regen", "value": 2}]},
			{"name": "Crew helmet", "slot": "Helmet", "base": "Cycle helmet", "affixes": [{"stat": "armour", "value": 10}, {"stat": "med_speed_pct", "value": 10}]},
		],
		"bonuses": {2: {"stats": {"med_speed_pct": 50}, "words": "Meds 50% quicker"},
			3: {"rule": "ambulance", "words": "The first med of a run isn't spent; meds heal double"}}},
	{"name": "The Bank's", "depth": 10, "words": "Staff, they called themselves. The blazers say so",
		"pieces": [
			{"name": "Branch blazer", "slot": "Armour", "base": "Ballistic vest", "affixes": [{"stat": "armour", "value": 20}, {"stat": "cash_pct", "value": 15}]},
			{"name": "Cashier's pen", "slot": "Charm", "base": "Bank's own pen", "affixes": [{"stat": "cash_pct", "value": 20}, {"stat": "rarity_pct", "value": 8}]},
			{"name": "Branch holdall", "slot": "Backpack", "base": "Hiking pack", "affixes": [{"stat": "capacity", "value": 6}, {"stat": "cash_per_cell", "value": 4}]},
		],
		"bonuses": {2: {"stats": {"cash_pct": 30}, "words": "Cash +30%"},
			3: {"stats": {"sell_pct": 25}, "rule": "bank", "words": "Cash from kills doubled; the Fence pays +25%"}}},
	{"name": "The Army's", "depth": 15, "words": "Issue kit, the lot of it, off the one lorry that got through",
		"pieces": [
			{"name": "Issue helmet", "slot": "Helmet", "base": "Composite helmet", "affixes": [{"stat": "armour", "value": 20}, {"stat": "hp", "value": 15}]},
			{"name": "Issue carrier", "slot": "Armour", "base": "Full plate carrier", "affixes": [{"stat": "armour", "value": 30}, {"stat": "all_res", "value": 8}]},
			{"name": "Issue bergen", "slot": "Backpack", "base": "Bergen", "affixes": [{"stat": "capacity", "value": 8}, {"stat": "hp", "value": 10}]},
			{"name": "Issue rifle", "slot": "Primary", "base": "Marksman rifle", "affixes": [{"stat": "damage_pct", "value": 15}, {"stat": "first_pct", "value": 20}]},
		],
		"bonuses": {2: {"stats": {"armour_pct": 15}, "words": "Armour +15%"}, 3: {"stats": {"first_pct": 40}, "words": "First shot +40%"},
			4: {"rule": "army", "words": "One fewer on you at once; everything you do does 30% more"}}},
	{"name": "The Carpet Man's", "depth": 5, "words": "A fitter's kit: the knife, the knee pads",
		"pieces": [
			{"name": "Carpet knife", "slot": "Secondary", "base": "Knife", "affixes": [{"stat": "bleed_pct", "value": 25}, {"stat": "attack_pct", "value": 10}]},
			{"name": "Fitter's knee pads", "slot": "Armour", "base": "Padded jacket", "affixes": [{"stat": "armour", "value": 12}, {"stat": "bleed_res", "value": 20}]},
		],
		"bonuses": {2: {"stats": {"conv_bleed_pct": 30}, "rule": "carpet", "words": "30% of your damage as bleed; bleeds last twice as long"}}},
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
	{"stat": "regen", "label": "HP a second", "short": "HP/s", "min": 1, "max": 6, "slots": ["Armour", "Helmet", "Charm"], "flat": true},
	{"stat": "life_per_kill", "label": "HP a kill", "short": "HP/kill", "min": 2, "max": 12, "slots": ["Primary", "Secondary", "Helmet"], "flat": true},
	{"stat": "armour_pct", "label": "armour", "short": "arm", "min": 3, "max": 18, "slots": ["Armour", "Helmet"]},
	{"stat": "crowd_less_pct", "label": "less from three or more on you", "short": "less/crowd", "min": 4, "max": 16, "slots": ["Armour"]},
	# the guns: rate of fire
	{"stat": "attack_pct", "label": "rate of fire", "short": "RoF", "min": 3, "max": 15, "slots": ["Primary", "Secondary"]},
	# the carry: pouches, meds, searches, gangs later, notes
	{"stat": "med_cap", "label": "pouches", "short": "pouch", "min": 1, "max": 3, "slots": ["Rig"], "flat": true},
	{"stat": "med_speed_pct", "label": "quicker meds", "short": "med spd", "min": 5, "max": 30, "slots": ["Rig", "Helmet"]},
	{"stat": "search_pct", "label": "quicker searches", "short": "search", "min": 4, "max": 20, "slots": ["Backpack", "Helmet"]},
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
	{"stat": "fire_proofed", "label": "fire resist and fire damage", "short": "fire proof", "min": 5, "max": 20, "slots": ["Armour", "Helmet"], "weight": 0.4},
	{"stat": "frost_proofed", "label": "frost resist and frost damage", "short": "frost proof", "min": 5, "max": 20, "slots": ["Armour", "Helmet"], "weight": 0.4},
	{"stat": "poison_proofed", "label": "poison resist and poison damage", "short": "poison proof", "min": 5, "max": 20, "slots": ["Armour", "Helmet"], "weight": 0.4},
	{"stat": "shock_proofed", "label": "shock resist and shock damage", "short": "shock proof", "min": 5, "max": 20, "slots": ["Armour", "Helmet"], "weight": 0.4},
	{"stat": "bleed_proofed", "label": "bleed resist and bleed damage", "short": "bleed proof", "min": 5, "max": 20, "slots": ["Armour", "Helmet"], "weight": 0.4},
	{"stat": "dot_pct", "label": "burn, poison and bleed damage", "short": "dots", "min": 8, "max": 40, "slots": ["Primary", "Secondary", "Charm"], "weight": 0.6},
	{"stat": "armour", "label": "armour", "short": "arm", "min": 3, "max": 24, "slots": ["Helmet", "Armour", "Rig"], "flat": true},
	{"stat": "hp", "label": "max HP", "short": "HP", "min": 5, "max": 40, "slots": ["Helmet", "Armour", "Rig", "Backpack"], "flat": true},
	{"stat": "loot_pct", "label": "loot quantity", "short": "quantity", "min": 5, "max": 30, "slots": ["Rig", "Backpack", "Helmet"]},
	{"stat": "capacity", "label": "capacity", "short": "cap", "min": 1, "max": 6, "slots": ["Backpack"], "flat": true},
	{"stat": "speed_pct", "label": "pace", "short": "pace", "min": 3, "max": 15, "slots": ["Primary", "Secondary", "Armour"]},
	{"stat": "heal_pct", "label": "healing", "short": "heal", "min": 10, "max": 40, "slots": ["Medical"]},
	# Guard (12 Oct): anyone's, a little
	{"stat": "overflow_pct", "label": "of its heal past full as Guard", "short": "overflow", "min": 50, "max": 100, "slots": ["Medical"], "weight": 0.5},
	{"stat": "guard_gang", "label": "max HP as Guard every gang", "short": "guard/gang", "min": 2, "max": 8, "slots": ["Armour", "Helmet"], "weight": 0.5},
	{"stat": "guard_pct", "label": "Guard holds more", "short": "guard", "min": 10, "max": 50, "slots": ["Rig", "Armour"], "weight": 0.5},
	{"stat": "damage_pct", "label": "damage", "short": "dmg", "min": 2, "max": 6, "slots": ["Attachment"]},
	# conditional: they pay only in a situation, which is where builds come from
	{"stat": "damage_low_pct", "label": "dmg under ½ HP", "short": "dmg <½HP", "min": 8, "max": 20, "slots": ["Primary", "Secondary"]},
	{"stat": "first_lot_pct", "label": "damage on the first gang", "short": "dmg 1st gang", "min": 10, "max": 25, "slots": ["Primary"]},
	{"stat": "loot_per_lot", "label": "loot quantity a gang seen off", "short": "qty/gang", "min": 3, "max": 8, "slots": ["Backpack", "Rig"]},
	{"stat": "armour_per_med", "label": "armour a med carried", "short": "arm/med", "min": 2, "max": 5, "slots": ["Rig", "Armour"]},
	{"stat": "cash_per_kill", "label": "cash a kill", "short": "£/kill", "min": 2, "max": 6, "slots": ["Helmet", "Backpack"]},
	# keyed off the build: they scale with a choice, not a number
	{"stat": "damage_per_att", "label": "damage an attachment fitted", "short": "dmg/part", "min": 2, "max": 4, "slots": ["Primary"]},
	{"stat": "armour_per_free", "label": "armour an empty pack cell", "short": "arm/free", "min": 1, "max": 3, "slots": ["Armour", "Backpack"]},
	{"stat": "loot_per_med", "label": "loot quantity a med carried", "short": "qty/med", "min": 2, "max": 5, "slots": ["Rig", "Helmet"]},
	{"stat": "cash_per_cell", "label": "cash a pack cell filled, on the way out", "short": "£/cell", "min": 3, "max": 8, "slots": ["Backpack", "Rig"]},
	{"stat": "speed_pct", "label": "pace", "short": "pace", "min": 2, "max": 5, "slots": ["Attachment"]},
	# the charm's: loot quality is rarer finds; loot quantity is more of them
	{"stat": "rarity_pct", "label": "loot quality", "short": "quality", "min": 5, "max": 15, "slots": ["Charm", "Helmet", "Backpack"]},
	{"stat": "cash_pct", "label": "cash", "short": "cash", "min": 5, "max": 15, "slots": ["Charm"]},
	{"stat": "loot_pct", "label": "loot quantity", "short": "quantity", "min": 5, "max": 12, "slots": ["Charm"]},
]

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
## head: the first runs, before the streets. Every site's index moved up three with it, and every zone's up one (a save
## from before is moved on load: Sim._shift_sites).
const ZONES := [
	{"name": "The Outskirts", "words": "The allotments, the garden centre, Top Farm - the edge of it, where it started", "tiers": [0, 1, 2]},
	{"name": "The Estate", "words": "Ransacked Streets, a parade of shops, the Retail Park", "tiers": [3, 4, 5]},
	{"name": "The Town", "words": "A dead theme park, the Shopping Centre, the Bank - held by a crew", "tiers": [6, 7, 8]},
	{"name": "The City", "words": "The Services on the motorway, the Hospital, the Barracks the lorries never reached", "tiers": [9, 10, 11]},
]
const OUTSKIRTS_SITES := 3         # the sites before the Streets: a site's level is its index past these and its depth (Streets, depth 1: level 1)
const ZONE := "The Estate"
## A site: its campaign numbers (depth 1), its shape at the endgame (how the
## depth curve is bent for it - many and thin, or few and hard; gangs often
## or rarely; cash-heavy), and its drops: which slots its finds favour, a gun
## type it leans to, and the bases found there and nowhere else.
const TIERS := [
	# the Outskirts (12 Oct): gentler than the Streets, no crew; finds at tier 1
	{"name": "The Allotments", "zone": 0, "pool": 4, "hp": 120.0, "dps": 0.2, "drop": 0.35, "loot_tier": 1, "xp": 1, "cash": 3,
		"shape": {"pool": 14, "hp": 0.6, "dps": 0.7, "patrol": 0.9, "cash": 0.7},
		"drops": {"slots": {"Primary": 2, "Secondary": 3, "Helmet": 1, "Armour": 1, "Rig": 1, "Backpack": 2}, "type": "melee", "only": []}},
	{"name": "The Garden Centre", "zone": 0, "pool": 5, "hp": 150.0, "dps": 0.25, "drop": 0.4, "loot_tier": 1, "xp": 1, "cash": 4,
		"shape": {"pool": 13, "hp": 0.7, "dps": 0.8, "patrol": 1.0, "cash": 0.9, "med": 1.5},
		"drops": {"slots": {"Primary": 1, "Secondary": 2, "Helmet": 2, "Armour": 1, "Rig": 2, "Backpack": 2}, "type": "improvised", "only": []}},
	{"name": "Top Farm", "zone": 0, "pool": 6, "hp": 170.0, "dps": 0.3, "drop": 0.4, "loot_tier": 1, "xp": 2, "cash": 5,
		"shape": {"pool": 12, "hp": 0.8, "dps": 0.8, "patrol": 1.1, "cash": 1.0, "ammo": 1.5},
		"drops": {"slots": {"Primary": 3, "Secondary": 1, "Helmet": 1, "Armour": 2, "Rig": 1, "Backpack": 1}, "type": "shotgun", "only": []}},
	{"name": "Ransacked Streets", "zone": 1, "pool": 6, "hp": 200.0, "dps": 0.4, "drop": 0.4, "loot_tier": 1, "xp": 2, "cash": 6,
		"shape": {"pool": 14, "hp": 0.7, "dps": 0.8, "patrol": 0.8, "cash": 0.9},
		"drops": {"slots": {"Primary": 2, "Secondary": 3, "Helmet": 2, "Armour": 1, "Rig": 1, "Backpack": 1}, "type": "improvised", "only": ["Pipe shotgun", "Carrier bags"]}},
	{"name": "The Parade", "zone": 1, "pool": 10, "hp": 280.0, "dps": 0.35, "drop": 0.4, "loot_tier": 2, "xp": 3, "cash": 9,
		"shape": {"pool": 12, "hp": 0.9, "dps": 0.8, "patrol": 1.0, "cash": 1.2},
		"drops": {"slots": {"Primary": 1, "Secondary": 3, "Helmet": 1, "Armour": 1, "Rig": 2, "Backpack": 2}, "type": "pistol", "only": ["Sawn-off", "Holdall"]}},
	{"name": "The Retail Park", "zone": 1, "pool": 14, "hp": 420.0, "dps": 0.7, "drop": 0.45, "loot_tier": 3, "xp": 6, "cash": 14,
		"shape": {"pool": 12, "hp": 1.0, "dps": 1.0, "patrol": 1.0, "cash": 1.0, "att": 2.0},
		"drops": {"slots": {"Primary": 3, "Secondary": 1, "Helmet": 1, "Armour": 2, "Rig": 1, "Backpack": 1}, "type": "improvised", "only": ["Garage-built rifle", "Drum magazine", "Wire stock"]}},
	{"name": "The Pleasure Park", "zone": 2, "pool": 12, "hp": 1100.0, "dps": 1.4, "drop": 0.45, "loot_tier": 3, "xp": 10, "cash": 22,
		"shape": {"pool": 10, "hp": 1.0, "dps": 1.1, "patrol": 1.2, "cash": 1.0},
		"drops": {"slots": {"Primary": 1, "Secondary": 1, "Helmet": 1, "Armour": 1, "Rig": 3, "Backpack": 3}, "type": "shotgun", "only": ["Framed pack", "Fishing vest"]}},
	{"name": "Shopping Centre", "zone": 2, "pool": 16, "hp": 1300.0, "dps": 1.8, "drop": 0.5, "loot_tier": 4, "xp": 15, "cash": 24,
		"shape": {"pool": 11, "hp": 1.1, "dps": 1.0, "patrol": 0.9, "cash": 1.1},
		"drops": {"slots": {"Primary": 1, "Secondary": 2, "Helmet": 3, "Armour": 3, "Rig": 1, "Backpack": 1}, "type": "pistol", "only": ["Tactical pistol", "Ballistic vest"]}},
	{"name": "The Bank", "zone": 2, "pool": 20, "hp": 1500.0, "dps": 2.4, "drop": 0.5, "loot_tier": 5, "xp": 20, "cash": 30,
		"shape": {"pool": 7, "hp": 1.4, "dps": 1.3, "patrol": 1.5, "cash": 1.6, "paper": 3.0},
		"drops": {"slots": {"Primary": 2, "Secondary": 2, "Helmet": 1, "Armour": 2, "Rig": 1, "Backpack": 1}, "type": "smg", "only": ["Compact pistol", "Light plates"]}},
	{"name": "The Services", "zone": 3, "pool": 16, "hp": 2600.0, "dps": 3.2, "drop": 0.5, "loot_tier": 5, "xp": 30, "cash": 40,
		"shape": {"pool": 12, "hp": 1.0, "dps": 1.0, "patrol": 0.7, "cash": 1.0, "ammo": 2.5},
		"drops": {"slots": {"Primary": 2, "Secondary": 2, "Helmet": 1, "Armour": 1, "Rig": 2, "Backpack": 2}, "type": "smg", "only": ["Belt links", "Depot rounds", "Cargo frame"]}},
	{"name": "The Hospital", "zone": 3, "pool": 18, "hp": 3300.0, "dps": 3.9, "drop": 0.5, "loot_tier": 6, "xp": 36, "cash": 44,
		"shape": {"pool": 10, "hp": 1.2, "dps": 1.0, "patrol": 1.0, "cash": 0.9, "med": 3.0},
		"drops": {"slots": {"Primary": 1, "Secondary": 1, "Helmet": 1, "Armour": 2, "Rig": 3, "Backpack": 1}, "type": "", "only": ["Hospital kit", "Surgeon's kit", "Medic's harness"]}},
	{"name": "The Barracks", "zone": 3, "pool": 22, "hp": 4200.0, "dps": 4.8, "drop": 0.55, "loot_tier": 6, "xp": 46, "cash": 50,
		"shape": {"pool": 8, "hp": 1.5, "dps": 1.4, "patrol": 1.3, "cash": 0.8},
		"drops": {"slots": {"Primary": 3, "Secondary": 1, "Helmet": 2, "Armour": 3, "Rig": 2, "Backpack": 1}, "type": "rifle", "only": ["Section gun", "Issue plates", "Night optic"]}},
]

const BANK := 8                    # the tier whose vault holds the deeds

## The endgame's depth curve: once the campaign is done, every site fights
## at the depth's numbers bent by its shape, so the choice between sites is
## what they drop, not how hard they are. Depth 2 is the first rung.
const CURVE := {"hp": 3200.0, "dps": 3.6, "xp": 30.0, "cash": 40.0, "drop": 0.5, "grow": 0.14, "reward": 0.10, "rarity": 0.10}

## The bosses: one a zone, the crew's head, fought at the zone's last site
## after its pool is down. Free the first time (the campaign); after that
## the crew's price in notes, by depth. Each has their own drops.
const BOSSES := [
	{"zone": 1, "name": "The Carpet Man", "tier": 5, "hp": 10.0, "dps": 3.0, "notes": 20,
		"words": "The crew in the carpet warehouse have a leader. He had a van and a lock-up before; he has the car park now.",
		"uniques": ["The Van's Spare", "Underlay"]},
	{"zone": 2, "name": "The Manager", "tier": 8, "hp": 12.0, "dps": 3.5, "notes": 40,
		"words": "The Bank's crew call themselves staff. He was. He's behind the vault, and he's not coming out for you.",
		"uniques": ["The Manager's Coat", "The Branch Pistol"]},
	{"zone": 3, "name": "The Quartermaster", "tier": 11, "hp": 6.0, "dps": 2.5, "notes": 60,     # the Barracks went up; he came down to match: the pool before him is the fight
		"words": "The lorry that never reached the Barracks reached him. He's been issuing it ever since, to people he chooses.",
		"uniques": ["The Quartermaster's Rifle", "Issue Webbing"]},
]
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
const CONVOY_DEPTH := 10          # 8 to 10 (12 Oct, the A/B reads: the element builds took the first lorry at 1.4-4.5 h against the 16 it was sized for): level 16 on the Services, plus the moves made. Before: level 14 (the sixteenth read: the end kit holds level 14, not 16)
const CONVOY_HP := 0.4            # 0.25 to 0.4 (12 Oct, the same reads); the convoy's heads at this much of their HP each and CONVOY_DPS of their fire: they come light and tired, the crews left with the load (the probe, 7 Oct: at 35%/full fire a Poacher read 0.80 and a stronger Doorman 0.00 - the Poacher's first-of-the-gang bonus counts on every head; at 25%/0.75 both read 0.93-1.00)
const CONVOY_DPS := 0.75
const LORRY_MULT := 1.12          # 1.25 to 1.12 (12 Oct: with the lorry off, the moves in 16 h fell from 9-20 to 1-9 - the ×1.25 outran a depth's ×1.14 and each leg came easier than the last); the Yard's damage and HP, times this a lorry beaten, kept across moves: the prestige
const PARAGON_PCT := 2.0          # past MAX_LEVEL: damage and HP +this% a paragon level, uncapped, on the same XP curve
const ILVL_SCALE := 0.06          # an affix's rolled value grows this much an item level past ILVL_FROM: the deep drop beats the shallow one of the same tier
const ILVL_FROM := 15
const CONVOY_TIER := 9             # the Services
const CONVOY_UNIQUE := "The Lorry's Load"
const BOSS_HP_MULT := 1.0          # boss HP = site hp × boss "hp"; scales with the curve past the campaign
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
## heads, uniques, sets; everything else is sentence case; acronyms upper. A save from before carries the old
## names: `load_dict` reads them through this.
const RENAMES := {
	"A blue plaque": "A Blue Plaque",
	"A traffic warden's hat": "A Traffic Warden's Hat",
	"At the bench": "At the Bench",
	"Grandad's shotgun": "Grandad's Shotgun",
	"Issue webbing": "Issue Webbing",
	"Jump leads": "Jump Leads",
	"Lucky cap": "Lucky Cap",
	"Nan's cardigan": "Nan's Cardigan",
	"Ransacked streets": "Ransacked Streets",
	"Shopping centre": "Shopping Centre",
	"The Doorman's jacket": "The Doorman's Jacket",
	"The Postman's bag": "The Postman's Bag",
	"The ambulance's": "The Ambulance's",
	"The army's": "The Army's",
	"The arsonist's rig": "The Arsonist's Rig",
	"The bank": "The Bank",
	"The bank's": "The Bank's",
	"The barracks": "The Barracks",
	"The bookie's pencil": "The Bookie's Pencil",
	"The branch pistol": "The Branch Pistol",
	"The butcher's apron": "The Butcher's Apron",
	"The butcher's steel": "The Butcher's Steel",
	"The caretaker's keys": "The Caretaker's Keys",
	"The carpet man": "The Carpet Man",
	"The carpet man's": "The Carpet Man's",
	"The council's": "The Council's",
	"The council's weed burner": "The Council's Weed Burner",
	"The dinner lady's ladle": "The Dinner Lady's Ladle",
	"The electrician's tester": "The Electrician's Tester",
	"The fire crew's": "The Fire Crew's",
	"The float": "The Float",
	"The gamekeeper's flask": "The Gamekeeper's Flask",
	"The gritter's hopper": "The Gritter's Hopper",
	"The gritter's keys": "The Gritter's Keys",
	"The hospital": "The Hospital",
	"The lollipop lady's sign": "The Lollipop Lady's Sign",
	"The lorry driver's log": "The Lorry Driver's Log",
	"The lorry's load": "The Lorry's Load",
	"The manager": "The Manager",
	"The manager's coat": "The Manager's Coat",
	"The manager's pen": "The Manager's Pen",
	"The parade": "The Parade",
	"The pleasure park": "The Pleasure Park",
	"The quartermaster": "The Quartermaster",
	"The quartermaster's ledger": "The Quartermaster's Ledger",
	"The quartermaster's manual": "The Quartermaster's Manual",
	"The quartermaster's rifle": "The Quartermaster's Rifle",
	"The rat man's bag": "The Rat Man's Bag",
	"The rat man's overalls": "The Rat Man's Overalls",
	"The retail park": "The Retail Park",
	"The scout leader's whistle": "The Scout Leader's Whistle",
	"The sergeant's whistle": "The Sergeant's Whistle",
	"The services": "The Services",
	"The sparky's gloves": "The Sparky's Gloves",
	"The substation key": "The Substation Key",
	"The van keys": "The Van Keys",
	"The van's spare": "The Van's Spare",
	"The vicar's thermos": "The Vicar's Thermos",
	"The yard": "The Yard",
}

const COMMON_TREE := "The Yard"
const TREES := [
	{"name": "The Yard", "nodes": [
		{"name": "Dry fire", "col": 0, "row": 0, "effect": "damage_pct", "value": 3},
		{"name": "Long walks", "col": 0, "row": 1, "effect": "hp", "value": 4},
		{"name": "Knowing the streets", "col": 1, "row": 0, "effect": "loot_pct", "value": 3},
		{"name": "Double tap", "col": 2, "row": 0, "effect": "double_tap", "notable": true, "words": "The secondary fires at full damage, not a third"},
		{"name": "Zeroing", "col": 1, "row": 1, "effect": "damage_pct", "value": 7},
		{"name": "Circuits", "col": 2, "row": 1, "effect": "hp", "value": 9},
		{"name": "Keen eyes", "col": 3, "row": 0, "effect": "search_pct", "value": 15},
		{"name": "Second wind", "col": 4, "row": 0, "effect": "second_wind", "notable": true, "words": "Rest at the Yard twice as fast"},
		{"name": "Stashing", "col": 3, "row": 1, "effect": "loot_pct", "value": 4},
		{"name": "Pack horse", "col": 4, "row": 1, "effect": "pack_mule", "notable": true, "words": "The pack carries six cells more"},
		{"name": "The dog's share", "col": 5, "row": 0, "effect": "cap_dogs_share", "capstone": true, "words": "A dead runner's rig comes home: the dog carries it"},
	]},
	# A tree is a lane (9 Oct, docs/design/trees.md): six columns of two, read left to right, "col" and "row"
	# on every node. A node wants only its column open - points spent in that tree, Data.gate - so a deep
	# node can't be bought with a dip. A class tree's conversion notable is its half of a joint (column 4).
	# Poacher
	{"name": "Stalking", "class": "Poacher", "nodes": [
		{"name": "Still hands", "col": 0, "row": 0, "effect": "first_pct", "value": 5},
		{"name": "Breathing", "col": 0, "row": 1, "effect": "damage_pct", "value": 3},
		{"name": "Patience", "col": 1, "row": 0, "effect": "patrol_pct", "value": 10},
		{"name": "Rifleman", "col": 2, "row": 0, "effect": "first_pct", "value": 100, "type": "rifle", "notable": true, "words": "Your first shot on every gang does double"},
		{"name": "Wind reading", "col": 1, "row": 1, "effect": "first_pct", "value": 10},
		{"name": "Long shot", "col": 2, "row": 1, "effect": "damage_pct", "value": 4},
		{"name": "One shot", "col": 4, "row": 0, "effect": "one_shot", "keystone": true, "words": "The first of every gang drops to your first shot"},
		{"name": "Lying up", "col": 3, "row": 1, "effect": "patrol_pct", "value": 10},
		{"name": "Rat bait", "col": 3, "row": 0, "effect": "conv_poison_pct", "value": 15, "notable": true, "joint": "poacher_poison", "words": "A share of every hit lands as poison and keeps working"},
		{"name": "Night work", "col": 4, "row": 1, "effect": "night_work", "notable": true, "words": "Every site you run is Night: rarer finds, slower feet"},
		{"name": "Dead quiet", "col": 5, "row": 0, "effect": "cap_dead_quiet", "capstone": true, "words": "Every gang is the size of the first: they never grow"},
		{"name": "In the hide", "col": 5, "row": 1, "beside": true, "effect": "in_the_hide", "notable": true, "words": "The first of every gang down: Guard of 15% of your max HP"},     # Guard (12 Oct)
	]},
	{"name": "Snares", "class": "Poacher", "nodes": [
		{"name": "Quick hands", "col": 0, "row": 0, "effect": "search_pct", "value": 15},
		{"name": "Hedgerows", "col": 0, "row": 1, "effect": "loot_pct", "value": 3},
		{"name": "Soft ground", "col": 1, "row": 0, "effect": "patrol_pct", "value": 10},
		{"name": "Quiet feet", "col": 2, "row": 0, "effect": "quiet_feet", "notable": true, "words": "The next gang comes every 30 seconds, not 20"},
		{"name": "Night eyes", "col": 1, "row": 1, "effect": "rarity", "value": 20},
		{"name": "Snare lines", "col": 2, "row": 1, "effect": "loot_pct", "value": 4},
		{"name": "Trapline", "col": 4, "row": 0, "effect": "trapline", "keystone": true, "words": "Every gang arrives one head short, the first included"},
		{"name": "Knowing the land", "col": 3, "row": 1, "effect": "loot_pct", "value": 5},
		{"name": "Cold snap", "col": 3, "row": 0, "effect": "conv_frost_pct", "value": 15, "notable": true, "joint": "poacher_frost", "words": "A share of every hit lands as frost and slows them"},
		{"name": "Early doors", "col": 4, "row": 1, "effect": "early_doors", "notable": true, "words": "The first gang takes twice as long to come"},
		{"name": "Poached", "col": 5, "row": 0, "effect": "cap_poached", "capstone": true, "words": "Every gang arrives already light: a find is yours the moment they come"},
	]},
	# Doorman
	{"name": "Muscle", "class": "Doorman", "nodes": [
		{"name": "Heavy hands", "col": 0, "row": 0, "effect": "damage_pct", "value": 4},
		{"name": "Gym", "col": 0, "row": 1, "effect": "hp", "value": 4},
		{"name": "Broad shoulders", "col": 1, "row": 0, "effect": "armour_pct", "value": 5},
		{"name": "Shotgunner", "col": 2, "row": 0, "effect": "damage_pct", "value": 25, "type": "shotgun", "notable": true, "words": "Every shell hits a quarter harder"},
		{"name": "Weights", "col": 1, "row": 1, "effect": "damage_pct", "value": 5},
		{"name": "Thick skin", "col": 2, "row": 1, "effect": "armour_pct", "value": 8},
		{"name": "Bodyline", "col": 4, "row": 0, "effect": "bodyline", "keystone": true, "words": "With three on you, you take half the damage"},
		{"name": "Big frame", "col": 3, "row": 1, "effect": "hp", "value": 6},
		{"name": "Glassing", "col": 3, "row": 0, "effect": "conv_bleed_pct", "value": 15, "notable": true, "joint": "doorman_bleed", "words": "A share of every hit lands as bleed and keeps bleeding"},
		{"name": "Loud", "col": 4, "row": 1, "effect": "loud", "notable": true, "words": "Gangs come sooner and one head bigger; +30% drops"},
		{"name": "Spoils", "col": 5, "row": 1, "effect": "rarity", "value": 15},
		{"name": "Iron", "col": 5, "row": 0, "effect": "cap_iron", "capstone": true, "words": "Under half HP, every kill heals a tenth of you"},
	]},
	{"name": "The door", "class": "Doorman", "nodes": [
		{"name": "Stance", "col": 0, "row": 0, "effect": "hp", "value": 10},
		{"name": "Heads down", "col": 0, "row": 1, "effect": "damage_pct", "value": 3},
		{"name": "Eye contact", "col": 1, "row": 0, "effect": "armour_pct", "value": 5},
		{"name": "Chokepoints", "col": 2, "row": 0, "effect": "overwatch", "notable": true, "words": "Only two of a gang can fire on you at once, not three"},
		{"name": "Bouncing", "col": 1, "row": 1, "effect": "hp", "value": 5},
		{"name": "Keep back", "col": 2, "row": 1, "effect": "armour_pct", "value": 5},
		{"name": "One at a time", "col": 4, "row": 0, "effect": "one_at_a_time", "keystone": true, "words": "Only one of a gang can ever fire on you at once; pace −25%"},
		{"name": "Hands on", "col": 3, "row": 0, "effect": "physical_pct", "value": 20, "type": ["shotgun", "melee"], "notable": true, "joint": "doorman_physical", "words": "Shotguns and melee hit 20% harder in the plain"},
		{"name": "Through the lot", "col": 3, "row": 1, "effect": "melee_sweep", "type": "melee", "notable": true, "words": "A swing hits everyone on you"},
		{"name": "Stand and fight", "col": 4, "row": 1, "effect": "stand", "notable": true, "words": "No leaving before the fight is won; the bonus for winning it is doubled"},
		{"name": "Held", "col": 5, "row": 0, "effect": "cap_held", "capstone": true, "words": "No second of their fire takes more than a tenth of you"},
		{"name": "Squared up", "col": 5, "row": 1, "beside": true, "effect": "squared_up", "notable": true, "words": "Every gang, as they arrive: Guard of 15% of your max HP"},     # Guard (12 Oct)
	]},
	# Paramedic
	{"name": "Triage", "class": "Paramedic", "nodes": [
		{"name": "Steady hands", "col": 0, "row": 0, "effect": "heal_pct", "value": 10},
		{"name": "Fast hands", "col": 0, "row": 1, "effect": "med_speed_pct", "value": 15},
		{"name": "Kit bag", "col": 1, "row": 0, "effect": "heal_pct", "value": 10},
		{"name": "Triage", "col": 2, "row": 0, "effect": "triage", "notable": true, "words": "Meds take half the time"},
		{"name": "Good veins", "col": 1, "row": 1, "effect": "heal_pct", "value": 15},
		{"name": "Stock take", "col": 2, "row": 1, "effect": "med_cap", "value": 1},
		{"name": "Field surgery", "col": 4, "row": 0, "effect": "field_surgery", "keystone": true, "words": "Meds work at once, not over seconds"},
		{"name": "Pressure", "col": 3, "row": 1, "effect": "heal_pct", "value": 15},
		{"name": "Syringe", "col": 3, "row": 0, "effect": "conv_poison_pct", "value": 15, "notable": true, "joint": "paramedic_poison", "words": "A share of every hit lands as poison and keeps working"},
		{"name": "Walking wounded", "col": 4, "row": 1, "effect": "walking_wounded", "notable": true, "words": "Under half HP: +40% damage; meds heal half"},
		{"name": "Pockets checked", "col": 5, "row": 1, "effect": "rarity", "value": 15},
		{"name": "Clean hands", "col": 5, "row": 0, "effect": "cap_clean_hands", "capstone": true, "words": "A med clears everything on you, and nothing lands for three seconds"},
	]},
	{"name": "Shifts", "class": "Paramedic", "nodes": [
		{"name": "Night shift", "col": 0, "row": 0, "effect": "hp", "value": 5},
		{"name": "Rest easy", "col": 0, "row": 1, "effect": "rest_pct", "value": 25},
		{"name": "Mates' rates", "col": 1, "row": 0, "effect": "treat_pct", "value": 20},
		{"name": "Walk it off", "col": 2, "row": 0, "effect": "walk_it_off", "notable": true, "words": "1 HP a second comes back while a site is being searched"},
		{"name": "Long shift", "col": 1, "row": 1, "effect": "hp", "value": 5},
		{"name": "Cold tea", "col": 2, "row": 1, "effect": "rest_pct", "value": 25},
		{"name": "Not today", "col": 4, "row": 0, "effect": "not_today", "keystone": true, "words": "The first hit on a run that would kill you leaves you on half HP instead"},
		{"name": "Discount", "col": 3, "row": 1, "effect": "treat_pct", "value": 20},
		{"name": "Ice pack", "col": 3, "row": 0, "effect": "conv_frost_pct", "value": 15, "notable": true, "joint": "paramedic_frost", "words": "A share of every hit lands as frost and slows them"},
		{"name": "Second shift", "col": 4, "row": 1, "effect": "second_shift", "notable": true, "words": "The first med used on a run isn't spent"},
		{"name": "Transfusion", "col": 5, "row": 0, "effect": "cap_transfusion", "capstone": true, "words": "Guard holds twice as much, and a med fills it to the top"},     # Guard (12 Oct): was overflow as armour, two to one; the class does overflow now
		{"name": "Overtime", "col": 5, "row": 1, "beside": true, "effect": "overtime", "notable": true, "words": "Guard holds 50% more; with Guard up, meds take half the time"},
	]},
	# Scrapper
	{"name": "Stripping", "class": "Scrapper", "nodes": [
		{"name": "Nose for parts", "col": 0, "row": 0, "effect": "att_share", "value": 5},
		{"name": "Quick hands", "col": 0, "row": 1, "effect": "search_pct", "value": 15},
		{"name": "Tools", "col": 1, "row": 0, "effect": "damage_pct", "value": 3},
		{"name": "Bodger", "col": 2, "row": 0, "effect": "damage_pct", "value": 40, "type": "improvised", "notable": true, "words": "Whatever you cobbled together hits harder"},
		{"name": "Spare parts", "col": 1, "row": 1, "effect": "att_share", "value": 5},
		{"name": "Fast strip", "col": 2, "row": 1, "effect": "search_pct", "value": 15},
		{"name": "Nothing wasted", "col": 4, "row": 0, "effect": "nothing_wasted", "keystone": true, "words": "Every kill drops something"},
		{"name": "Magpie eye", "col": 3, "row": 1, "effect": "loot_pct", "value": 4},
		{"name": "Live wire", "col": 3, "row": 0, "effect": "conv_shock_pct", "value": 15, "notable": true, "joint": "scrapper_shock", "words": "A share of every hit lands as shock"},
		{"name": "Quiet hands", "col": 4, "row": 1, "effect": "quiet_hands", "notable": true, "words": "Every search finds two things, and kills drop nothing"},
		{"name": "Jerry-rigged", "col": 5, "row": 0, "effect": "cap_jerry", "capstone": true, "words": "Something improvised hits half again as hard"},
		{"name": "Sheet metal", "col": 5, "row": 1, "beside": true, "effect": "sheet_metal", "notable": true, "words": "Every cache searched: Guard of 6% of your max HP"},     # Guard (12 Oct)
	]},
	{"name": "Fencing", "class": "Scrapper", "nodes": [
		{"name": "Haggling", "col": 0, "row": 0, "effect": "sell_pct", "value": 10},
		{"name": "Contacts", "col": 0, "row": 1, "effect": "cash_pct", "value": 10},
		{"name": "Weighing it up", "col": 1, "row": 0, "effect": "sell_pct", "value": 10},
		{"name": "Magpie", "col": 2, "row": 0, "effect": "scavenger", "notable": true, "words": "Every search finds two things"},
		{"name": "Known face", "col": 1, "row": 1, "effect": "cash_pct", "value": 10},
		{"name": "Fair price", "col": 2, "row": 1, "effect": "sell_pct", "value": 10},
		{"name": "Buyer's market", "col": 4, "row": 0, "effect": "buyers_market", "keystone": true, "words": "The Fence pays double; buying costs double"},
		{"name": "Lucky find", "col": 3, "row": 1, "effect": "rarity", "value": 20},
		{"name": "Blowtorch", "col": 3, "row": 0, "effect": "conv_fire_pct", "value": 15, "notable": true, "joint": "scrapper_fire", "words": "A share of every hit lands as fire and keeps burning"},
		{"name": "Hoarder", "col": 4, "row": 1, "effect": "hoarder", "notable": true, "words": "The pack carries double; −30% pace"},
		{"name": "The lot", "col": 5, "row": 0, "effect": "cap_the_lot", "capstone": true, "words": "A pack that comes home full pays double cash"},
	]},
	# Drifter
	{"name": "Moving on", "class": "Drifter", "nodes": [
		{"name": "Light feet", "col": 0, "row": 0, "effect": "pace_pct", "value": 5},
		{"name": "Road legs", "col": 0, "row": 1, "effect": "hp", "value": 5},
		{"name": "Head start", "col": 1, "row": 0, "effect": "patrol_pct", "value": 10},
		{"name": "Spray", "col": 2, "row": 0, "effect": "damage_pct", "value": 25, "type": "smg", "notable": true, "words": "Every burst hits a quarter harder"},
		{"name": "Keep moving", "col": 1, "row": 1, "effect": "pace_pct", "value": 5},
		{"name": "Never still", "col": 2, "row": 1, "effect": "patrol_pct", "value": 10},
		{"name": "Never there", "col": 4, "row": 0, "effect": "never_there", "keystone": true, "words": "No gang ever comes; searching takes twice as long"},
		{"name": "Wiry", "col": 3, "row": 1, "effect": "hp", "value": 5},
		{"name": "Petrol bomb", "col": 3, "row": 0, "effect": "conv_fire_pct", "value": 15, "notable": true, "joint": "drifter_fire", "words": "A share of every hit lands as fire and keeps burning"},
		{"name": "Hit and run", "col": 4, "row": 1, "effect": "hit_and_run", "notable": true, "words": "Leaves as the first gang arrives, the loot kept; every kill pays 50% more"},
		{"name": "Ghost", "col": 5, "row": 0, "effect": "cap_ghost", "capstone": true, "words": "The first gang never comes: a run starts at the search, and a full pack brought home is the clear"},
		{"name": "Breather", "col": 5, "row": 1, "beside": true, "effect": "breather", "notable": true, "words": "While no one's on you, Guard comes back a tenth of its cap a second"},     # Guard (12 Oct)
	]},
	{"name": "Luck", "class": "Drifter", "nodes": [
		{"name": "Lucky", "col": 0, "row": 0, "effect": "rarity", "value": 10},
		{"name": "Found money", "col": 0, "row": 1, "effect": "cash_pct", "value": 10},
		{"name": "Charmed", "col": 1, "row": 0, "effect": "loot_pct", "value": 3},
		{"name": "Dead man's shoes", "col": 2, "row": 0, "effect": "damage_low_pct", "value": 20, "notable": true, "words": "Under half HP: +20% damage"},
		{"name": "Rabbit's foot", "col": 1, "row": 1, "effect": "rarity", "value": 15},
		{"name": "Pockets", "col": 2, "row": 1, "effect": "cash_pct", "value": 10},
		{"name": "All or nothing", "col": 4, "row": 0, "effect": "all_or_nothing", "keystone": true, "words": "Nothing common is ever found, and half as many things are"},
		{"name": "Four-leaf", "col": 3, "row": 1, "effect": "loot_pct", "value": 4},
		{"name": "Jump start", "col": 3, "row": 0, "effect": "conv_shock_pct", "value": 15, "notable": true, "joint": "drifter_shock", "words": "A share of every hit lands as shock"},
		{"name": "Light fingers", "col": 4, "row": 1, "effect": "light_fingers", "notable": true, "words": "Papers three times as often; cash −20%"},
		{"name": "Loaded dice", "col": 5, "row": 0, "effect": "cap_loaded_dice", "capstone": true, "words": "A Rare or better find rolls twice and keeps the better"},
	]},
]
## The second past: at ASCEND_LEVEL the runner takes a second class, whose
## first tree opens beside the first's. Its keystone and rule are theirs too.
## The element trees: one a type, lanes like the class ones - conversion and increased to a notable, then
## column 4's halves of the joints (a class's alone: "class"), then a keystone that breaks the element's rule
## and a notable with a cost, which want a closed joint in the tree (JOINTS), then the capstone. Any class
## can walk any of them; its two affinities (AFFINITY) come at the normal price, the others cost double and
## stop at column 4 - a dip, not a build. Knuckles is the physical: the share of a hit that isn't converted.
const ELEMENT_TREES := [
	{"name": "Petrol", "element": "fire", "nodes": [
		{"name": "A can of it", "col": 0, "row": 0, "effect": "conv_fire_pct", "value": 20},     # 30 to 20 (the twenty-seventh read: the fire Drifter to the Bank in 0.3-0.8 h, the next element build 1.0)
		{"name": "Rags", "col": 0, "row": 1, "effect": "fire_pct", "value": 10},
		{"name": "Siphoned", "col": 1, "row": 0, "effect": "conv_fire_pct", "value": 35},
		{"name": "Lit", "col": 2, "row": 0, "effect": "fire_pct", "value": 30, "notable": true, "words": "+30% fire; burns last twice as long"},
		{"name": "Wick", "col": 1, "row": 1, "effect": "fire_pct", "value": 12},
		{"name": "Drifter's can", "col": 3, "row": 0, "effect": "fire_pct", "value": 25, "type": "smg", "class": "Drifter", "notable": true, "joint": "drifter_fire", "words": "SMGs do 25% more fire"},
		{"name": "Spreads", "col": 4, "row": 0, "effect": "fire_spread", "keystone": true, "words": "Fire hits everyone on you"},
		{"name": "Fumes", "col": 2, "row": 1, "effect": "dot_pct", "value": 20},
		{"name": "Scrapper's torch", "col": 3, "row": 1, "effect": "fire_pct", "value": 25, "type": "improvised", "class": "Scrapper", "notable": true, "joint": "scrapper_fire", "words": "Improvised guns do 25% more fire"},
		{"name": "On your hands", "col": 4, "row": 1, "effect": "fire_more", "notable": true, "words": "Fire does 40% more; every hit of it burns you for 2% of it"},
		{"name": "Spread", "col": 5, "row": 0, "effect": "cap_spread", "capstone": true, "words": "The burn on one of them carries to the next"},
		{"name": "Fireproof", "col": 5, "row": 1, "beside": true, "effect": "proof_fire", "value": 1, "also": {"fire_res": 20}, "notable": true,
		 "words": "+20% fire resist; every 1% past the cap is +2% fire, not +1%"},     # over the cap (12 Oct)
	]},
	{"name": "The cold", "element": "frost", "nodes": [
		{"name": "Antifreeze", "col": 0, "row": 0, "effect": "conv_frost_pct", "value": 30},
		{"name": "Frost", "col": 0, "row": 1, "effect": "frost_pct", "value": 10},
		{"name": "A hard winter", "col": 1, "row": 0, "effect": "conv_frost_pct", "value": 35},
		{"name": "Chill", "col": 2, "row": 0, "effect": "frost_pct", "value": 30, "notable": true, "words": "+30% frost; chilled gangs fire 40% slower, not 20"},
		{"name": "Numb", "col": 1, "row": 1, "effect": "frost_pct", "value": 12},
		{"name": "Poacher's snare", "col": 3, "row": 0, "effect": "frost_pct", "value": 25, "also": {"patrol_pct": 10}, "class": "Poacher", "notable": true, "joint": "poacher_frost", "words": "+25% frost; gangs come 10% later"},
		{"name": "Frozen solid", "col": 4, "row": 0, "effect": "frost_freeze", "keystone": true, "words": "Chilled gangs fire at 15%; your frost does half damage"},
		{"name": "Wind chill", "col": 2, "row": 1, "effect": "frost_pct", "value": 15},
		{"name": "Paramedic's ice", "col": 3, "row": 1, "effect": "frost_pct", "value": 25, "class": "Paramedic", "notable": true, "joint": "paramedic_frost", "words": "+25% frost"},
		{"name": "Cold hands", "col": 4, "row": 1, "effect": "frost_more", "notable": true, "words": "Frost does 40% more; pace −15%"},
		{"name": "Shatter", "col": 5, "row": 0, "effect": "cap_shatter", "capstone": true, "cost_less": 1,     # a point under (the twenty-eighth read: the frost Poacher's capstone 5.6 h against 5)
		  "words": "A chilled target takes double from the physical"},
		{"name": "Thermals", "col": 5, "row": 1, "beside": true, "effect": "proof_frost", "value": 1, "also": {"frost_res": 20}, "notable": true,
		 "words": "+20% frost resist; every 1% past the cap is +2% frost, not +1%"},     # over the cap (12 Oct)
	]},
	{"name": "The rat man", "element": "poison", "nodes": [
		{"name": "Under the sink", "col": 0, "row": 0, "effect": "conv_poison_pct", "value": 30},
		{"name": "Bait", "col": 0, "row": 1, "effect": "poison_pct", "value": 10},
		{"name": "Council issue", "col": 1, "row": 0, "effect": "conv_poison_pct", "value": 35},
		{"name": "Dosed", "col": 2, "row": 0, "effect": "poison_pct", "value": 30, "notable": true, "words": "+30% poison; poison lasts twice as long"},
		{"name": "Cumulative", "col": 1, "row": 1, "effect": "dot_pct", "value": 15},
		{"name": "Poacher's bait", "col": 3, "row": 0, "effect": "poison_pct", "value": 25, "type": "rifle", "class": "Poacher", "notable": true, "joint": "poacher_poison", "words": "Rifles do 25% more poison"},
		{"name": "Builds", "col": 4, "row": 0, "effect": "poison_stacks", "keystone": true, "words": "Poison stacks to fifteen, not five"},
		{"name": "Slow acting", "col": 2, "row": 1, "effect": "poison_pct", "value": 15},
		{"name": "Paramedic's dose", "col": 3, "row": 1, "effect": "poison_pct", "value": 25, "class": "Paramedic", "notable": true, "joint": "paramedic_poison", "words": "+25% poison"},
		{"name": "Rat's share", "col": 4, "row": 1, "effect": "poison_more", "notable": true, "words": "Poison does 40% more; loot quantity −20%"},
		{"name": "Lingers", "col": 5, "row": 0, "effect": "cap_lingers", "capstone": true, "words": "The poison on one of them carries to the next"},
		{"name": "Immune", "col": 5, "row": 1, "beside": true, "effect": "proof_poison", "value": 1, "also": {"poison_res": 20}, "notable": true,
		 "words": "+20% poison resist; every 1% past the cap is +2% poison, not +1%"},     # over the cap (12 Oct)
	]},
	{"name": "Live", "element": "shock", "nodes": [
		{"name": "Jump Leads", "col": 0, "row": 0, "effect": "conv_shock_pct", "value": 30},
		{"name": "Charge", "col": 0, "row": 1, "effect": "shock_pct", "value": 10},
		{"name": "Off the mains", "col": 1, "row": 0, "effect": "conv_shock_pct", "value": 35},
		{"name": "Live", "col": 2, "row": 0, "effect": "shock_pct", "value": 30, "notable": true, "words": "+30% shock; shocked gangs take 40% more, not 25"},
		{"name": "Amps", "col": 1, "row": 1, "effect": "shock_pct", "value": 12},
		{"name": "Drifter's leads", "col": 3, "row": 0, "effect": "shock_pct", "value": 25, "also": {"patrol_pct": 10}, "class": "Drifter", "notable": true, "joint": "drifter_shock", "words": "+25% shock; gangs come 10% later"},
		{"name": "Live wire", "col": 4, "row": 0, "effect": "shock_chain", "keystone": true, "words": "Shock on one of them is shock on all of them"},
		{"name": "Volts", "col": 2, "row": 1, "effect": "shock_pct", "value": 15},
		{"name": "Scrapper's mains", "col": 3, "row": 1, "effect": "shock_pct", "value": 25, "type": "improvised", "class": "Scrapper", "notable": true, "joint": "scrapper_shock", "words": "Improvised guns do 25% more shock"},
		{"name": "Earthed", "col": 4, "row": 1, "effect": "shock_more", "notable": true, "words": "Shock does 40% more; armour −20%"},
		{"name": "Arc", "col": 5, "row": 0, "effect": "cap_arc", "capstone": true, "words": "A shock holds as long as you fire"},
		{"name": "Rubber soles", "col": 5, "row": 1, "beside": true, "effect": "proof_shock", "value": 1, "also": {"shock_res": 20}, "notable": true,
		 "words": "+20% shock resist; every 1% past the cap is +2% shock, not +1%"},     # over the cap (12 Oct)
	]},
	{"name": "Blades", "element": "bleed", "nodes": [
		{"name": "Stanley knife", "col": 0, "row": 0, "effect": "conv_bleed_pct", "value": 30},
		{"name": "An edge", "col": 0, "row": 1, "effect": "bleed_pct", "value": 25},          # 10 to 25 (the twenty-fifth read): bleed meets the town's 20% resist on the way to the Bank, fire and poison don't
		{"name": "Sharpened", "col": 1, "row": 0, "effect": "conv_bleed_pct", "value": 35},     # 15 to 35, as every element's second conversion (the twenty-fifth read: bleed the slowest to the Bank, 2.6 h against fire's 0.7)
		{"name": "Opened up", "col": 2, "row": 0, "effect": "bleed_pct", "value": 30, "notable": true, "words": "+30% bleed; bleeds last twice as long"},
		{"name": "Deep", "col": 1, "row": 1, "effect": "bleed_pct", "value": 20},             # 12 to 20, the same
		{"name": "Doorman's glass", "col": 3, "row": 0, "effect": "bleed_pct", "value": 25, "type": ["shotgun", "melee"], "class": "Doorman", "notable": true, "joint": "doorman_bleed", "words": "Shotguns and melee do 25% more bleed"},
		{"name": "Won't stop", "col": 4, "row": 0, "effect": "bleed_forever", "keystone": true, "cost_less": 2,     # two under (the twenty-seventh read 3.1 h, the twenty-eighth 2.9, against the 2 h gate)
		 "words": "Bleeds don't fade until they're down, and stack to three"},
		{"name": "Nicked", "col": 2, "row": 1, "effect": "dot_pct", "value": 20},
		{"name": "Butcher's", "col": 3, "row": 1, "effect": "bleed_pct", "value": 20},          # was conv 20: the conversion moved up the tree to Sharpened
		{"name": "Blood up", "col": 4, "row": 1, "effect": "bleed_more", "notable": true, "words": "Bleed does 40% more; your meds 30% slower"},
		{"name": "Bleed out", "col": 5, "row": 0, "effect": "cap_bleed_out", "capstone": true, "cost_less": 2,     # two under (its capstone 8.9 h, then 5.8, against 5)
		 "words": "A bleed carries to the next, and bleeds half again as hard"},
		{"name": "Scar tissue", "col": 5, "row": 1, "beside": true, "effect": "proof_bleed", "value": 1, "also": {"bleed_res": 20}, "notable": true,
		 "words": "+20% bleed resist; every 1% past the cap is +2% bleed, not +1%"},     # over the cap (12 Oct)
	]},
	{"name": "Knuckles", "element": "physical", "nodes": [
		{"name": "Bare hands", "col": 0, "row": 0, "effect": "physical_pct", "value": 10},
		{"name": "Wraps", "col": 0, "row": 1, "effect": "armour_pct", "value": 5},
		{"name": "Half a brick", "col": 1, "row": 0, "effect": "physical_pct", "value": 15},
		{"name": "Stagger", "col": 2, "row": 0, "effect": "physical_pct", "value": 30, "also": {"stagger": 10}, "notable": true, "words": "+30% physical; your hits slow their fire 10%"},
		{"name": "Thick skull", "col": 1, "row": 1, "effect": "armour_pct", "value": 5},
		{"name": "Doorman's knuckles", "col": 3, "row": 0, "effect": "phys_pen", "value": 20, "class": "Doorman", "notable": true, "joint": "doorman_physical", "words": "Physical ignores 20% of their resist"},
		{"name": "Bust them up", "col": 4, "row": 0, "effect": "bust_them_up", "keystone": true, "words": "Physical ignores their armour and resist; nothing you fire converts"},
		{"name": "Weight behind it", "col": 2, "row": 1, "effect": "physical_pct", "value": 12},
		{"name": "Knuckle-duster", "col": 3, "row": 1, "effect": "physical_pct", "value": 20},
		{"name": "Heavy", "col": 4, "row": 1, "effect": "physical_more", "notable": true, "words": "Physical does 40% more; pace −15%"},
		{"name": "Flattened", "col": 5, "row": 0, "effect": "cap_flattened", "capstone": true, "words": "A kill with the plain staggers the next gang: they fire at half for two seconds"},
		{"name": "Thick-skinned", "col": 5, "row": 1, "beside": true, "effect": "thick_skinned", "notable": true,
		 "words": "Every 10 armour past 200 is +1% physical, to +50%"},     # over the cap's physical (12 Oct): armour is its resist
	]},
]
const AFFINITY := {"Drifter": ["fire", "shock"], "Doorman": ["bleed", "physical"], "Poacher": ["poison", "frost"], "Scrapper": ["shock", "fire"], "Paramedic": ["poison", "frost"]}
const OFF_AFFINITY_COST := 2       # an element off the class's pair costs double a node

## The joints (9 Oct, docs/design/trees.md): one notable split across a class tree and an element tree of the
## class's pair, in column 4 of both. Each half works alone; both trained, the joint closes and its payoff
## holds. An element tree's last two columns want a closed joint in that tree. `lane` is the class tree's
## place on the Training screen: the first tree joins lane 2's element, the second lane 4's.
const JOINTS := [
	{"key": "drifter_fire", "class": "Drifter", "tree": "Moving on", "element_tree": "Petrol", "words": "Your bursts ignite: burning gangs take 25% more from SMGs"},
	{"key": "drifter_shock", "class": "Drifter", "tree": "Luck", "element_tree": "Live", "words": "A shocked kill's drop rolls its rarity twice"},
	{"key": "scrapper_shock", "class": "Scrapper", "tree": "Stripping", "element_tree": "Live", "words": "Every hit from an improvised gun shocks"},
	{"key": "scrapper_fire", "class": "Scrapper", "tree": "Fencing", "element_tree": "Petrol", "words": "A kill while it burns always drops something; finds sell for 20% more"},
	{"key": "poacher_poison", "class": "Poacher", "tree": "Stalking", "element_tree": "The rat man", "words": "Your first shot on a gang lands its poison at full stacks"},
	{"key": "poacher_frost", "class": "Poacher", "tree": "Snares", "element_tree": "The cold", "words": "Every gang arrives chilled, and one head short"},
	{"key": "paramedic_poison", "class": "Paramedic", "tree": "Triage", "element_tree": "The rat man", "words": "Every med you use doses them with a full stack of poison"},
	{"key": "paramedic_frost", "class": "Paramedic", "tree": "Shifts", "element_tree": "The cold", "words": "Chilled gangs do 30% less to you; meds heal 20% more while one is"},
	{"key": "doorman_bleed", "class": "Doorman", "tree": "Muscle", "element_tree": "Blades", "words": "Every shell and swing opens a bleed; bleeding gangs do 20% less to you"},
	{"key": "doorman_physical", "class": "Doorman", "tree": "The door", "element_tree": "Knuckles", "words": "Every shell and swing staggers: the gangs on you fire 25% slower"},
]
const JOINT_COL := 3               # the column both halves sit in (the fourth)
const ELEMENT_GATED_COL := 4       # an element tree's columns from here want a closed joint


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

const ASCEND_LEVEL := 30
## Retirement (36): a runner at RETIRE_LEVEL can retire to the wall; the Yard keeps RETIRE_SHARE of their
## trait for good, up to RETIRED_MAX retired (the oldest makes way), their kit stays, their trees refund.
const RETIRE_LEVEL := 30
const RETIRE_SHARE := 1.0 / 3.0
const RETIRED_MAX := 3

## Insurance: the Fence holds the paper on the kit for a run. Dies, and the
## kit comes back to the Yard's stash. A share of what's worn, by depth.
const INSURE_RATE := 0.15

## Moving the Yard: after the campaign, start again somewhere else. What
## comes: the uniques, the Yard's own tree, the list of runners before, half
## the notes, and a yard whose name travels - magic find and cash a move.
const MOVE_FIND := 5               # percent magic find a move
const MOVE_CASH := 5               # percent cash a move
const MOVE_POINTS := 2             # training points a move, free at the start
const MOVE_NOTES_KEPT := 0.5
const LADDER_FLOOR_MAX := 3        # a moved yard's ladders start this many depths up at most (the endgame, 7 Oct): the fourth yard opens every site at depth 4

## The bench's crafting, paid in notes: times the item's tier and its rarity + 1.
## The bench's crafting, in cash: a price × the item's level × (rarity + 1).
## Perfection is dear and bottomless; that's the late game's cash sink.
## "bump" is in notes: the crews' thing, not the Fence's.
const CRAFT := {
	"reroll": {"name": "Re-roll the affixes", "cash": 40, "words": "The same number, rolled again, tiers and all"},
	"lock": {"name": "Lock one, re-roll the rest", "cash": 120, "words": "The one you pick stays as it is", "pick": true},
	"one": {"name": "Re-roll one", "cash": 80, "words": "Rolled again; a chance up a tier, a smaller one down, within the rarity", "pick": true},
	"add": {"name": "Add an affix", "cash": 100, "words": "One more, a rarity up"},
	"socket": {"name": "Cut a socket", "cash": 80, "words": "One more socket, up to two"},
	"strip": {"name": "Strip the affixes", "cash": 10, "words": "Back to plain; the value goes with them"},
	"bump": {"name": "Raise the item's level", "notes": 10, "words": "Three levels up: the worst tiers stop rolling; up to the base's tier plus 20"},
}
const BUMP_LEVELS := 3
const BUMP_CAP := 20

## Crafting (34): one material, scrap, a count in hand. Found on a search
## (SCRAP_SEARCH of them a handful), made by scrapping an item at the Bench or
## ditching it on a run (its value over SCRAP_PER_POUND). The Build column:
## a standard box of rounds for scrap; the grades, scrap plus the box below
## ("from"); a med, scrap plus the one below; an improvised gun of a type for
## scrap by its tier, Common, firing nails whatever it is; a grenade, scrap
## plus the element's socketable. Costs are untuned until the pass.
const SCRAP_PER_POUND := 24         # 20 to 24 (12 Oct, the read: 7.1-9.0 crafts an hour against 7, the Scrapper 10.7-11.8 against 8)
const SCRAP_SEARCH := 0.35          # 0.5 to 0.35 (12 Oct, the same read). The pass (6 Oct): 0.2 read half a craft an hour against the dearest build; 0.4 left three builds at 0.5-0.8
const SCRAP_HANDFUL := [5, 10]      # the pass (6 Oct): [3, 6], [4, 8], then [6, 12] which read 3-5 crafts an hour on the builds that run most
const BUILD_BOX := 8                # a standard box of any type you have a gun for
const BUILD_GRADE := 15             # a grade, with the box below
const BUILD_MED := 8                # a med, times its tier, with the one below (painkillers and a bandage: scrap alone)
const BUILD_GUN := 40               # an improvised gun, times its tier
const BUILD_GRENADE := 12           # with the element's socketable; the nail bomb scrap alone

## Events: something happens on a run, once at most, EVENT_ODDS of runs,
## some way in. A convoy passes (a bigger gang, and they carry notes); a
## runner trapped under something (freed, they turn up at the Yard next:
## `promised`); a locked cache (the Bench's tools open it for a find
## a tier up, or it stays shut).
const EVENT_ODDS := 0.3
const EVENT_WINDOW := [15.0, 70.0]  # seconds in, when it happens
const EVENT_CACHE_BENCH := 2        # the Bench level that opens a cache
const EVENTS := ["convoy", "trapped", "cache"]

## Contracts (9 Oct, docs/design/contracts.md): the Fence wants gear - so many of a slot at a rarity, a deep
## piece, one carrying a named affix - or papers or meds, and pays in currency only: cash sized to a run's
## takings, notes and scrap by the deepest depth, or a salvage from a zone dug to SALVAGE_DEPTH. Three open
## (five with the Fence's Orders); a handed-in one is replaced. The first turn-down after a run home is free,
## then CONTRACT_PASS_NOTES doubling. The Fence's mate sells a loose unique for notes, a new one every MATE_RUNS.
const CONTRACTS_OPEN := 3
const CONTRACTS_MAX := 5
const CONTRACT_SLOTS := ["Primary", "Secondary", "Helmet", "Armour", "Rig", "Backpack", "Attachment"]
const CONTRACT_KINDS := {"gear": 0.5, "deep": 0.125, "affix": 0.125, "papers": 0.125, "meds": 0.125}
const CONTRACT_KIND_NAMES := {"gear": "Gear", "deep": "Deep gear", "affix": "An affix", "papers": "Papers", "meds": "Meds"}
const CONTRACT_PAYS := {"cash": 0.4, "notes": 0.25, "scrap": 0.2, "salvage": 0.15}
const CONTRACT_CASH := 0.5         # a run's takings, times the ask's weight
const CONTRACT_CASH_WEIGHT_MAX := 4.0   # a cash contract pays two runs' takings at most
const CONTRACT_NOTES := 4          # notes, times the weight and (1 + the deepest depth / 5)
const CONTRACT_SCRAP := 6          # scrap, the same
const CONTRACT_DEEP_LESS := 3      # a deep piece: from the deepest site's level less this
const CONTRACT_DEEP_FROM := 6      # and asked for only once that's this level or more
const CONTRACT_PASS_NOTES := 5     # the second turn-down in a run; doubling after
const MATE_RUNS := 5
const MATE_NOTES := 400            # a unique from the mate, times the tier

## The map: the endgame's own tree. A point for every new depth cleared on
## any site past the first; spent on how the sites run, for every site.
## The map at thirty-six (endgame part 4, 7 Oct): three columns of twelve - the
## sites, the crews, the air - each a chain (a node needs the one before it
## taken) with four notables and a keystone, fed by the same point a new depth.
## `column` 0-2, in chain order; `max` the ranks; `notable`; `keystone`;
## `figures` the panel's and the strip's figure at each rank (rank 0 first).
const ATLAS := [
	# the sites
	{"key": "picked_over", "column": 0, "name": "Picked over", "max": 3, "words": "A site's own things turn up more: a third of finds, then half, then two-thirds",
		"sum": "Own finds", "figures": ["as they come", "a third of finds", "half of finds", "two-thirds of finds"], "sentence": "A site's own things turn up more of the time."},
	{"key": "deeper_pockets", "column": 0, "name": "Deeper pockets", "max": 3, "words": "Searches 10% quicker a rank",
		"sum": "Searches", "figures": ["as they come", "10% quicker", "20% quicker", "30% quicker"], "sentence": "The picking-over goes quicker, on every site."},
	{"key": "quiet_roads", "column": 0, "name": "Quiet roads", "max": 3, "words": "Gangs come 10% later a rank",
		"sum": "Gangs", "figures": ["as they come", "10% later", "20% later", "30% later"], "sentence": "The next gang takes longer to arrive, on every site."},
	{"key": "after_dark", "column": 0, "name": "After dark", "max": 1, "notable": true, "words": "Every site is Night, and Night's rarer finds half again",
		"sum": "Night", "figures": ["by the clock", "every site, rarer"], "sentence": "Every run is a night run - rarer finds, slower feet - and the dark gives half again as much."},
	{"key": "second_look", "column": 0, "name": "Second look", "max": 2, "words": "A search finds one more, every other search a rank",
		"sum": "Searches find", "figures": ["as they come", "+1 every other", "+1 every search"], "sentence": "The picking-over finds more: another every other search, then every search."},
	{"key": "worn_in", "column": 0, "name": "Worn in", "max": 2, "words": "A picked-over site comes back half again as fast a rank",
		"sum": "Sites recover", "figures": ["in two hours", "in 80 minutes", "in an hour"], "sentence": "A picked-over site is fresh again sooner."},
	{"key": "easy_pickings", "column": 0, "name": "Easy pickings", "max": 2, "words": "Drops +10% a rank",
		"sum": "Drops", "figures": ["as they come", "+10%", "+20%"], "sentence": "More of what they carry comes off them, on every site."},
	{"key": "local_knowledge", "column": 0, "name": "Local knowledge", "max": 1, "notable": true, "words": "Finds draw from the bases a gear tier up",
		"sum": "Bases", "figures": ["by the level", "a tier up"], "sentence": "You know where the good stuff is: finds draw from the bases a gear tier up, on every site."},
	{"key": "short_cuts", "column": 0, "name": "Short cuts", "max": 2, "words": "Pace +5% a rank",
		"sum": "Pace", "figures": ["as it is", "+5%", "+10%"], "sentence": "The runner knows the way: quicker on every site."},
	{"key": "open_ground", "column": 0, "name": "Open ground", "max": 1, "notable": true, "words": "One fewer on you at a time",
		"sum": "On you", "figures": ["as they come", "one fewer"], "sentence": "One fewer on you at a time, on every site."},
	{"key": "every_penny", "column": 0, "name": "Every penny", "max": 2, "words": "Cash +10% a rank",
		"sum": "Cash", "figures": ["as it comes", "+10%", "+20%"], "sentence": "Every run brings a little more home."},
	{"key": "lie_of_the_land", "column": 0, "name": "The lie of the land", "max": 1, "keystone": true, "words": "Every ladder opens one depth past the deepest cleared",
		"sum": "Ladders", "figures": ["to the deepest cleared", "one past it"], "sentence": "You know the ground: every site's ladder opens one depth past the deepest you've cleared on it."},
	# the crews
	{"key": "paid_in_notes", "column": 1, "name": "Paid in notes", "max": 3, "words": "Every kill carries a note more a rank",
		"sum": "Notes", "figures": ["as they come", "+1 a kill", "+2 a kill", "+3 a kill"], "sentence": "Every kill carries a note more."},
	{"key": "two_of_everything", "column": 1, "name": "Two of everything", "max": 1, "words": "A crew's head drops two of theirs",
		"sum": "Heads", "figures": ["drop one", "drop two"], "sentence": "A crew's head drops two of theirs."},
	{"key": "heads_up", "column": 1, "name": "Heads up", "max": 2, "words": "A crew's head's price in notes a third less a rank",
		"sum": "Heads cost", "figures": ["full price", "a third less", "two-thirds less"], "sentence": "The crews' heads come cheaper."},
	{"key": "full_strength", "column": 1, "name": "Full strength", "max": 1, "notable": true, "words": "A head comes at full strength from depth 8, not 10",
		"sum": "Full strength", "figures": ["from depth 10", "from depth 8"], "sentence": "The heads come at full strength two depths sooner, their charms with them."},
	{"key": "bounties", "column": 1, "name": "Bounties", "max": 2, "words": "The notes a head holds, half again a rank",
		"sum": "Head's notes", "figures": ["as they come", "half again", "doubled"], "sentence": "The crews' heads hold more of the old paper."},
	{"key": "wages", "column": 1, "name": "Wages", "max": 3, "words": "XP +10% a rank",
		"sum": "XP", "figures": ["as it comes", "+10%", "+20%", "+30%"], "sentence": "Every kill teaches a little more."},
	{"key": "heavy_crews", "column": 1, "name": "Heavy crews", "max": 1, "notable": true, "words": "One more on you at a time; kills pay half again in cash and XP",
		"sum": "Crews", "figures": ["as they come", "heavy, pay half again"], "sentence": "The gangs come one bigger, and every kill pays half again in cash and XP."},
	{"key": "their_own_kit", "column": 1, "name": "Their own kit", "max": 2, "words": "A kill drops something 10% more often a rank",
		"sum": "Kill drops", "figures": ["as they come", "+10%", "+20%"], "sentence": "More of them are carrying something when they go down."},
	{"key": "marked_men", "column": 1, "name": "Marked men", "max": 1, "notable": true, "words": "+25% damage to the first of every gang",
		"sum": "The first", "figures": ["as they come", "+25% damage"], "sentence": "The first of every gang is marked: a quarter more damage to him."},
	{"key": "long_memory", "column": 1, "name": "Long memory", "max": 1, "words": "A crew's head's price is paid once a depth: every run back at that depth is free",
		"sum": "Head's price", "figures": ["every run", "once a depth"], "sentence": "Pay a head's price at a depth once; he comes out for nothing at that depth after."},
	{"key": "head_start", "column": 1, "name": "Head start", "max": 1, "notable": true, "words": "A head beaten at full strength pays a map point",
		"sum": "Heads pay", "figures": ["nothing", "a point at full strength"], "sentence": "Beat a crew's head at full strength and the map gains a point."},
	{"key": "lorrys_route", "column": 1, "name": "The lorry's route", "max": 1, "keystone": true, "words": "The lorry runs the Services from depth 10, not 12",
		"sum": "The lorry", "figures": ["from depth 12", "from depth 10"], "sentence": "You know the lorry's route: the convoy runs the Services two depths sooner."},
	# the air (9 Oct, docs/design/juicing.md §7): the juicing tree
	{"key": "good_reception", "column": 2, "name": "Good reception", "max": 2, "words": "Every craft at the Radio 15% cheaper a rank",
		"sum": "Crafts", "figures": ["full price", "15% less", "30% less"], "sentence": "Every craft at the Radio comes cheaper."},
	{"key": "clear_air", "column": 2, "name": "Clear air", "max": 1, "words": "Name a word the Radio never hears",
		"sum": "Never heard", "figures": ["every word", "one word filtered"], "sentence": "Name one word you know: the Radio never rolls it again. Change it at the Radio."},
	{"key": "booster", "column": 2, "name": "Booster", "max": 3, "words": "Every word's pay +10% a rank",
		"sum": "Words pay", "figures": ["as they are", "+10%", "+20%", "+30%"], "sentence": "Every word brings a little more home, on every site."},
	{"key": "held_frequency", "column": 2, "name": "Held frequency", "max": 1, "words": "A site's words hold through a move",
		"sum": "Words", "figures": ["go with the move", "hold through it"], "sentence": "When the Yard moves, every site keeps its words."},
	{"key": "long_wave", "column": 2, "name": "Long wave", "max": 1, "notable": true, "words": "One more word a site",
		"sum": "Words a site", "figures": ["by the depth", "one more"], "sentence": "Every site carries one more word."},
	{"key": "tip_offs", "column": 2, "name": "Tip-offs", "max": 2, "words": "Rarer finds: +5% loot quality a rank",
		"sum": "Quality", "figures": ["as it comes", "+5%", "+10%"], "sentence": "Word of what's where: rarer finds on every site."},
	{"key": "strong_signal", "column": 2, "name": "Strong signal", "max": 2, "words": "A roll lands its top tier more; then one past the depth's",
		"sum": "Tiers", "figures": ["by the depth", "the top more often", "one past the depth"], "sentence": "A rolled word lands its top tier three times in four; at the second rank it can land one tier past what the depth allows."},
	{"key": "early_word", "column": 2, "name": "Early word", "max": 2, "words": "Call in a quarter cheaper a rank",
		"sum": "Call in", "figures": ["full price", "a quarter less", "half price"], "sentence": "Calling a word in comes cheaper."},
	{"key": "relay", "column": 2, "name": "Relay", "max": 1, "notable": true, "words": "A standing word from the book on every site",
		"sum": "Standing", "figures": ["none", "one word"], "sentence": "Name a word you know: it stands on every site with words, at that site's top tier, over its own."},
	{"key": "bent", "column": 2, "name": "Bent", "max": 1, "notable": true, "words": "Twist's tier IV twice as often",
		"sum": "Twist", "figures": ["as it falls", "tier IV ×2"], "sentence": "A twisted site lands a tier IV word twice as often."},
	{"key": "whole_band", "column": 2, "name": "The whole band", "max": 1, "keystone": true, "words": "A second standing word",
		"sum": "Standing", "figures": ["one word", "two words"], "sentence": "Two standing words on every site with words."},
]
## The map as lanes (9 Oct): a node's column in its lane is its place in the lane's list, two to a column; a
## column opens on the points spent in that lane (the mockup's figures).
const ATLAS_GATES := [0, 2, 4, 7, 10, 14]
const ATLAS_COLUMNS := ["The sites", "The crews", "The air"]


## A map node by key, or {}.
static func atlas_of(key: String) -> Dictionary:
	for a in ATLAS:
		if a["key"] == key:
			return a
	return {}

## Traits: what a runner turns up with. Two turn up when one dies; you pick.
const TRAITS := [
	{"name": "Lucky", "words": "+10% loot quality", "rarity": 0.1},
	{"name": "Heavy-handed", "words": "+8% damage, −5% pace", "damage": 1.08, "pace": 0.95},
	{"name": "Wary", "words": "Gangs come 20% later", "patrol": 1.2},
	{"name": "Greedy", "words": "+15% cash, −10% max HP", "cash": 1.15, "hp": 0.9},
	{"name": "Tough", "words": "+15% max HP", "hp": 1.15},
	{"name": "Light", "words": "+8% pace", "pace": 1.08},
	{"name": "Careful", "words": "Meds heal +20%", "heal": 1.2},
	{"name": "Nosy", "words": "Searches 15% faster", "search": 0.85},
]
const TRAIT_WORDS := {"Lucky": "a lucky one", "Heavy-handed": "heavy-handed", "Wary": "a wary one", "Greedy": "a greedy one",
	"Tough": "a tough one", "Light": "light on their feet", "Careful": "careful with the kit", "Nosy": "nosy"}
const RESPEC_CASH := 50

## Classes - what the runner was, before: chosen in the Caravan, changed in the Yard for free.
## Each is a set of rules on how the sim plays - what a weapon does, not what
## can be fitted - with a cost to go with it. Numbers are multipliers the sim
## reads by key; "words" is what the Barracks says.
const CLASSES := [
	{"name": "Poacher", "words": "+40% damage to the first of every gang; the next gang 25% slower to arrive",
		"first_pct": 40, "patrol": 1.25},          # the −10% max HP went (Matt, 9 Oct, the twenty-sixth read: the slowest class to the Bank two passes running, 2.2 and 2.8 h against the Drifter's 0.9)
	{"name": "Doorman", "words": "+15% damage; armour counts 20% more; −10% pace",
		"damage": 1.15, "armour": 1.2, "pace": 0.9},
	{"name": "Paramedic", "words": "+10% damage; meds heal 50% more and are used by themselves under 40% HP; healing past full is Guard",
		"damage": 1.1, "heal": 1.5, "auto_med": true, "overheal": true},     # overheal (12 Oct, docs/design/shields.md)     # +10% damage (Matt, 9 Oct, the twenty-eighth read: the slowest class to the Bank, 2.3 h on five reads)            # the pass (6 Oct): the −10% damage went; the slowest to the Bank by two hours
	{"name": "Scrapper", "words": "Searches 30% faster; +5% loot quantity",
		"search": 0.7, "loot": 0.05},              # +10% to +5% (12 Oct: 8.9-9.1 crafts an hour against 8)              # +15% to +10% (Matt, 9 Oct, the twenty-sixth read: 8.4 crafts of scrap an hour against its band's 8)              # the pass (6 Oct): the −5% damage went; second slowest to the Bank
	{"name": "Drifter", "words": "+5% damage; one fewer on you at a time; +10% pace",
		"damage": 1.05,     # +15% to +5% (Matt, 9 Oct, the twenty-eighth read: with its HP back, the fastest to the Bank at 0.6 h)
		 "contact": -1, "pace": 1.1},     # the −15% max HP went (Matt, 9 Oct, the twenty-fifth read: level 32, 272 HP and 8-10 runs an hour at hour 4 against the Doorman's 41, 354 and 25; the lorry beaten on 2 of 4 reads with the bot fixed). Before that:      # +15% damage (Matt, 8 Oct): last to the lorry on every read since the engine, 24 h merged on the twenty-second against 4-13 h for the rest; +10% read 16.1 h on three reads, six minutes over the gate
]


## A node's cost in points by its column (the lanes, 9 Oct): 1, 1, 2, 2, 3, 3 across; a notable one more,
## a keystone two more. The capstone's is its own (capstone_cost).
const COLUMN_COST := [1, 1, 2, 2, 3, 3]
const COLUMNS := 6
const GATE_SHARE := 0.6            # a column opens on this share of what the columns before it cost, in that tree


static func node_cost(col: int, notable: bool, keystone := false) -> int:
	return int(COLUMN_COST[clampi(col, 0, COLUMNS - 1)]) + (2 if keystone else (1 if notable else 0))


## A node's base cost from its data, the capstone's included: what a gate counts (a move's free node and
## an off-pair element's doubling are the runner's price, not the tree's shape).
static func base_cost(t: Dictionary, nd: Dictionary) -> int:
	var less: int = int(nd.get("cost_less", 0))        # a node priced under its column (bleed's keystone and capstone, 9 Oct)
	if nd.get("capstone", false):
		return maxi(1, capstone_cost(t) - less)
	return maxi(1, node_cost(int(nd.get("col", 0)), nd.get("notable", false), nd.get("keystone", false)) - less)


## Whether a node is for these classes: a class's half in an element tree is that class's alone.
static func for_classes(nd: Dictionary, classes: Array) -> bool:
	return not nd.has("class") or nd["class"] in classes


## The points spent in a tree that open column `col`: GATE_SHARE of what every node before it costs - the
## nodes these classes could train (another class's half doesn't count) - rounded up. Column 0 is open.
static func gate(t: Dictionary, col: int, classes: Array) -> int:
	if col <= 0:
		return 0
	var before := 0
	for nd in t["nodes"]:
		if int(nd.get("col", 0)) < col and not nd.get("capstone", false) and for_classes(nd, classes):
			before += base_cost(t, nd)
	return ceili(before * GATE_SHARE)


static func capstone_cost(t: Dictionary) -> int:
	var total := 0
	var half := 0                                      # a class's half counts once: one class trains one of them
	for nd in t["nodes"]:
		if nd.get("capstone", false) or nd.get("beside", false):
			continue                                       # a node beside the capstone (12 Oct) is its peer, not behind it
		var c := node_cost(int(nd.get("col", 0)), nd.get("notable", false), nd.get("keystone", false))
		if nd.has("class"):
			half = maxi(half, c)
		else:
			total += c
	return maxi(1, ceili((total + half) / 4.0))     # the pass (6 Oct): a third left three builds at 4.3-4.6 h against the 4 h gate


## The trees a class sees: its first, the common one, its second - and the
## second past's first, when there is one.
static func trees_for(cls: String, cls2 := "") -> Array:
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
	if cls2 != "" and cls2 != cls:
		for t in TREES:
			if t.get("class", "") == cls2:
				out.append(t)
				break
	return out


static func element_tree(name: String) -> Dictionary:
	for t in ELEMENT_TREES:
		if t["name"] == name:
			return t
	return {}


## The tree of an element ("fire" -> Petrol).
static func tree_of_element(element: String) -> Dictionary:
	for t in ELEMENT_TREES:
		if t["element"] == element:
			return t
	return {}


static func tree_named(name: String) -> Dictionary:
	for t in ELEMENT_TREES:
		if t["name"] == name:
			return t
	for t in TREES:
		if t["name"] == name:
			return t
	return {}


## Word - the run's modifiers, Path of Exile's maps framed as what's been heard.
## Each tier carries one or two, re-rolled after every mission. Multipliers
## on the hostiles and the rewards; `contact` shifts how many fire at once.
## The sky's words: never on the Radio; the clock puts Night on, the weather Rain and Fog.
const MODIFIERS := [
	{"name": "Night", "words": "Pace −20%, rarer loot", "pace": 0.8, "rarity": 0.5, "sky": true},
	{"name": "Rain", "words": "Slower search, gangs later", "search": 1.3, "patrol": 1.25, "sky": true},
	{"name": "Fog", "words": "−1 on you, drops −10%", "contact": -1, "drop": 0.9, "sky": true},
]

## Map juicing (9 Oct, docs/design/juicing.md): the Radio's words. Each has a bite (what makes the run harder)
## and a pay (what it brings home), at tier I; a word's tier by the site's depth (WORD_TIER_DEPTH) grows both:
## a multiplier m becomes m^WORD_TIER_POW[t], an added figure ×WORD_TIER_POW[t]; a count (on you, loot tiers)
## and a flag stay as they are. `learn`: "start" known when the depths open; "paper" taught by `paper` read into
## the book; "zone" known once a site of `zone` is cleared at depth 2; "deep" taught by its paper, heard only at
## `depth` or deeper. The bite's keys: hp, dps, pool (the pack), patrol (<1 sooner), pace, search, contact,
## armour (yours), type/share, res/res_add, no_meds, no_kill_cash, clock (seconds), boss_walks. The pay's:
## drop (finds), rarity (quality), cash, xp, loot_tier.
const WORD_TIER_DEPTH := [2, 8, 15]          # depth for tiers I, II, III
const WORD_TIER_POW := [1.0, 1.75, 2.5, 3.5] # I, II, III, IV (Twist's)
const WORD_TIER_NAMES := ["I", "II", "III", "IV"]
const WORD_MAX_DEPTH := [[2, 2], [5, 3], [9, 4]]   # [depth, words a site]
const WORD_POOLS := {"zone": 0.4, "general": 0.5, "deep": 0.1}
const WORDS := [
	{"name": "Numbers", "learn": "start", "bite": {"hp": 1.4}, "pay": {"drop": 1.3}},
	{"name": "Tooled up", "learn": "start", "bite": {"dps": 1.3}, "pay": {"rarity": 0.25}},
	{"name": "Delivery day", "learn": "start", "bite": {"patrol": 0.7}, "pay": {"cash": 1.4}},
	{"name": "Ex-army", "learn": "start", "bite": {"hp": 1.2, "dps": 1.2}, "pay": {"xp": 1.4}},
	{"name": "Bailiffs", "learn": "paper", "paper": "A council tax reminder", "bite": {"pool": 1.3}, "pay": {"cash": 1.3}},
	{"name": "Laid off", "learn": "paper", "paper": "A P45", "bite": {"contact": 1}, "pay": {"xp": 1.5}},
	{"name": "Long odds", "learn": "paper", "paper": "A betting slip", "bite": {"dps": 1.5}, "pay": {"rarity": 0.4}},
	{"name": "Pawned", "learn": "paper", "paper": "A pawn ticket", "bite": {"armour": 0.75}, "pay": {"drop": 1.35}},
	{"name": "Overdrawn", "learn": "paper", "paper": "A bank statement", "bite": {"no_kill_cash": true}, "pay": {"drop": 1.6, "rarity": 0.3}},
	{"name": "Hungry", "learn": "paper", "paper": "A food bank voucher", "bite": {"search": 1.5}, "pay": {"drop": 1.4}},
	{"name": "Burners", "learn": "paper", "paper": "A mortgage offer", "bite": {"type": "fire", "share": 0.33}, "pay": {"drop": 1.2, "cash": 1.2}},
	{"name": "Cutters", "learn": "paper", "paper": "A school report", "bite": {"type": "bleed", "share": 0.33}, "pay": {"drop": 1.2, "cash": 1.2}},
	{"name": "Wired", "learn": "paper", "paper": "A lottery ticket", "bite": {"type": "shock", "share": 0.33}, "pay": {"drop": 1.2, "cash": 1.2}},
	{"name": "Jacketed", "learn": "paper", "paper": "A wage slip", "bite": {"res": "fire", "res_add": 0.4}, "pay": {"cash": 1.3}},
	{"name": "Rubbered", "learn": "paper", "paper": "A parking ticket", "bite": {"res": "shock", "res_add": 0.4}, "pay": {"cash": 1.3}},
	{"name": "Hardened", "learn": "paper", "paper": "An eviction notice", "bite": {"res": "physical", "res_add": 0.3}, "pay": {"cash": 1.3}},
	{"name": "Night owls", "learn": "paper", "paper": "A boarding pass", "bite": {"pace": 0.8}, "pay": {"rarity": 0.5}},
	{"name": "Everyone's in", "learn": "paper", "paper": "A Christmas list", "bite": {"pool": 1.25, "patrol": 0.8}, "pay": {"drop": 1.4, "xp": 1.2}},
	{"name": "Dogs off the lead", "learn": "zone", "zone": 1, "bite": {"patrol": 0.8, "pace": 0.9}, "pay": {"drop": 1.3}},
	{"name": "Kids on bikes", "learn": "zone", "zone": 1, "bite": {"contact": 1}, "pay": {"cash": 1.25}},
	{"name": "Lock-ins", "learn": "zone", "zone": 1, "bite": {"search": 1.3}, "pay": {"rarity": 0.3}},
	{"name": "Security", "learn": "zone", "zone": 2, "bite": {"res": "physical", "res_add": 0.2, "hp": 1.2}, "pay": {"cash": 1.35}},
	{"name": "Market day", "learn": "zone", "zone": 2, "bite": {"pool": 1.4}, "pay": {"cash": 1.4}},
	{"name": "Shoplifters", "learn": "zone", "zone": 2, "bite": {"patrol": 0.75}, "pay": {"drop": 1.35}},
	{"name": "Squaddies", "learn": "zone", "zone": 3, "bite": {"dps": 1.4}, "pay": {"xp": 1.6}},
	{"name": "Checkpoints", "learn": "zone", "zone": 3, "bite": {"pace": 0.85, "hp": 1.2}, "pay": {"rarity": 0.4}},
	{"name": "Kitted out", "learn": "zone", "zone": 3, "depth": 8, "bite": {"res": "all", "res_add": 0.25}, "pay": {"rarity": 0.5}},
	{"name": "Water cannon", "learn": "zone", "zone": 3, "depth": 10, "bite": {"soaked": 0.3}, "pay": {"drop": 1.4}},     # over the cap (12 Oct): your resists down, so the overflow defends
	{"name": "Rationed", "learn": "deep", "paper": "A ration book", "depth": 12, "bite": {"no_meds": true}, "pay": {"drop": 2.0}},
	{"name": "Curfew", "learn": "deep", "paper": "A council minute", "depth": 18, "bite": {"pool": 2.0, "patrol": 0.75}, "pay": {"drop": 1.8, "cash": 1.8}},
	{"name": "Last bus", "learn": "deep", "paper": "A bus timetable, amended", "depth": 24, "bite": {"clock_half": true}, "pay": {"rarity": 1.2}},
	{"name": "Foreclosure", "learn": "deep", "paper": "A letter to the Bank", "depth": 30, "bite": {"hp": 2.5}, "pay": {"loot_tier": 2}},
	{"name": "Everyone's here", "learn": "deep", "paper": "A list of names", "depth": 40, "bite": {"pool": 3.0, "contact": 2}, "pay": {"drop": 2.5, "xp": 2.0}},
	{"name": "The Manager walks", "learn": "deep", "paper": "The Manager's note", "depth": 50, "bite": {"boss_walks": true}, "pay": {}},
]
## The Radio's crafts (juicing.md §6): notes × the site's depth × this.
const CRAFTS := [
	{"key": "tune", "name": "Tune in", "cost": 1.0, "words": "adds a word", "sentence": "One word added, rolled from the pools."},
	{"key": "broadcast", "name": "Broadcast", "cost": 3.0, "words": "fills an empty site", "sentence": "An empty site filled to its most."},
	{"key": "retune", "name": "Retune", "cost": 2.0, "words": "rolls them all again", "sentence": "Every word rolled again from the pools."},
	{"key": "hold", "name": "Hold", "cost": 4.0, "words": "keeps one, rolls the rest", "sentence": "One word kept; the rest rolled again."},
	{"key": "call", "name": "Call in", "cost": 8.0, "words": "a word of your choosing", "sentence": "A word of your choosing, from the book."},
	{"key": "clear", "name": "Clear", "cost": 0.5, "words": "every word off", "sentence": "Every word off. Ten times the price on a sealed site."},
	{"key": "twist", "name": "Twist", "cost": 6.0, "words": "a gamble; seals the site", "sentence": "A gamble: a word to tier IV, a deep word, nothing, or every word at its top tier. Either way the site is sealed."},
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
const CLOCK_BASE := 60.0            # the starting kit's 12/s on the streets' 200 HP heads is 17 s a head: the clock must let a new runner through
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
const REST_HP_PER_S := 0.5        # the Medic Tent, for free, slowly
const TREAT_CASH_PER_HP := 2.0    # or paid for, at once
## Wounds (30): a hit that takes the runner under WOUND_AT of max HP leaves a
## wound, one of WOUND_STATS cut by WOUND_PCT until the Clinic treats it for
## WOUND_CASH a level. One at a time; a second replaces it.
const WOUND_AT := 0.33            # 0.35 read 31-44% wounded and 0.30 2-9% (Matt, 8 Oct); the fifteenth read (7 Oct): at 0.35 the bot read 31-44% wounded and one bail in 31-69 - its close calls end between a quarter and a third; the pass (6 Oct): a quarter read 2-10% wounded, a third 28-32% on four builds, 0.30 4-9% on five with the bot pushing to 0.75; the bot plays to 0.85 now, so the wound comes from higher
const WOUND_PCT := 10
const WOUND_STATS := ["pace", "armour", "hp"]
const WOUND_CASH := 20
const STASH_CAP := 40
const MARKET_STOCK := 3           # items for sale, re-rolled after every mission
const MARKET_MARKUP := 3.0        # buying is dearer than selling

## The Fence's gamble (Matt, 6 Oct; the endgame's cash sink): a handful of kinds on offer, a picture
## each - a rifle, a helmet - rotated with the Fence's restock; pay and get a random one of the kind,
## rolled at the top tier opened with the Fence's quality on it, never Common; and any gamble can be a
## unique of the kind, from the first save on. The price is GAMBLE_RUNS of what a run on the top open
## tier pays, never under GAMBLE_FLOOR. Untuned until the pass reads it.
const GAMBLE_KINDS := [
	{"kind": "rifle", "slot": "Primary", "type": "rifle", "words": "A rifle"},
	{"kind": "shotgun", "slot": "Primary", "type": "shotgun", "words": "A shotgun"},
	{"kind": "smg", "slot": "Primary", "type": "smg", "words": "An SMG"},
	{"kind": "improvised", "slot": "Primary", "type": "improvised", "words": "Something improvised", "short": "Improvised"},
	{"kind": "melee", "slot": "Primary", "type": "melee", "words": "Something with an edge", "short": "An edge"},
	{"kind": "pistol", "slot": "Secondary", "type": "", "words": "A sidearm"},
	{"kind": "helmet", "slot": "Helmet", "type": "", "words": "A helmet"},
	{"kind": "armour", "slot": "Armour", "type": "", "words": "Body armour"},
	{"kind": "rig", "slot": "Rig", "type": "", "words": "A rig"},
	{"kind": "backpack", "slot": "Backpack", "type": "", "words": "A pack"},
	{"kind": "charm", "slot": "Charm", "type": "", "words": "A charm"},
]
const GAMBLE_SHOWN := 5             # kinds on offer at once, of the eleven
const GAMBLE_RUNS := 2.0            # the price, in runs' pay on the top open tier
const GAMBLE_FLOOR := 300           # and never under this, at the opening day's prices
const GAMBLE_QUALITY := 0.5         # the Fence's quality on the roll (+50%: the rarity weights compound by rank)
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
## The places changing. A cleared site is picked over for a while: its drops
## and cash thin and come back over RECOVER_H yard hours. The clock: the Yard
## opens at CLOCK_START; from NIGHT_FROM to NIGHT_TO every site is Night. The
## weather by zone, re-rolled every WEATHER_H: the odds of rain, then fog.
const RECOVER_H := 2.0
const WORN_DROP := 0.5             # drops lose this much at fully picked over
const WORN_CASH := 0.3
## Picked over inside a run (29): after THIN_AFTER searches on a site (more by
## depth, and quantity bonuses push it) each search's finds thin by THIN_STEP,
## down to THIN_FLOOR of them.
const THIN_AFTER := 6
const THIN_PER_DEPTH := 2
const THIN_STEP := 0.2
const THIN_FLOOR := 0.4
const CLOCK_START := 9.0
const NIGHT_FROM := 21.0
const NIGHT_TO := 6.0
const WEATHER_H := 1.0
const WEATHER_ODDS := [[0.35, 0.15], [0.35, 0.15], [0.25, 0.2], [0.2, 0.25]]   # by zone: rain, fog (the Outskirts' the Estate's, 12 Oct)
## Stacks. Rounds of a base merge into one stack, up to STACK_BOXES boxes'
## worth; socketables (no affixes, a bottle is a bottle) merge by count, up
## to SOCKET_STACK. A stack is one cell whatever it holds; taking rounds to
## the rig tops up the rig's stack first and splits what's left.
const STACK_BOXES := 5
const SOCKET_STACK := 10

## XP a level: Melvor's curve, like Clade.
const MAX_LEVEL := 50
const CAMPAIGN_TIER := 6          # gear tiers: the town drops to 5, the city 6
const MAX_TIER := 9               # the deep bases (10 Oct): 7, 8 and 9, past the campaign
const DEEP_TIER_LEVELS := [12, 16, 20]   # the site level a deep tier drops from: the Barracks at depth 4, 8 and 12
static var _xp_table: Array = []


static func xp_for_level(level: int) -> float:
	if _xp_table.is_empty():
		_xp_table.append(0.0)
	while _xp_table.size() < maxi(level, MAX_LEVEL):        # the curve runs on past the cap: the paragon levels (7 Oct)
		var l: int = _xp_table.size()
		_xp_table.append(float(_xp_table[l - 1]) + floorf((l + 300.0 * pow(2.0, l / 7.0)) / 4.0))
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
	while l < 10000 and xp >= xp_for_level(l + 1):
		l += 1
	_paragon_memo = [xp, l - MAX_LEVEL]
	return l - MAX_LEVEL
