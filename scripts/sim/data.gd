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
## the fence. Their words live in words.gd; the deeds are the one that matters.
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
	"Nail gun": [3, 1], "Bolt gun": [3, 1], "Pipe shotgun": [3, 1], "Sawn-off": [3, 1], "Workshop SMG": [3, 1],
	"Police carbine": [3, 1], "Army SMG": [3, 1], "Belt-fed SMG": [3, 1], "Army bullpup": [3, 1], "Workshop carbine": [3, 1],
	# scoped long guns
	"Old .303": [5, 1], "Scoped .308": [5, 1], "Sniper rifle": [5, 1], "Marksman rifle": [5, 1], "Section gun": [5, 1],
	# heavy armour
	"Riot suit": [3, 4], "Full plate carrier": [3, 4], "Issue plates": [3, 4],
	# bags
	"School bag": [2, 2], "Carrier bags": [2, 2], "Holdall": [2, 2],
	"Framed pack": [3, 4], "Expedition pack": [3, 4], "Cargo frame": [3, 4], "Patrol pack": [3, 4],
	# medical
	"First aid kit": [2, 1], "Trauma kit": [2, 1], "Surgeon's kit": [2, 2], "Hospital kit": [2, 2],
	# the deeds
	"The deeds": [2, 2],
	# optics
	"Red dot": [2, 1], "Torch": [2, 1], "Holo sight": [2, 1], "Telescopic sight": [2, 1], "Thermal sight": [2, 1], "Night optic": [2, 1], "Laser module": [2, 1],
}

## The stash in cells, by its level - a camp upgrade, cash. The first is free.
## Thirteen cells a row, seven rows a page: the first stash is one page.
const STASH_LEVELS := [
	{"cells": 91, "cost": 0},
	{"cells": 130, "cost": 1500},
	{"cells": 182, "cost": 6000},
	{"cells": 234, "cost": 15000},
]

## The camp's other upgrades, cash: the Medic Tent's rest rate, the Black
## Market's stock, and the Comms Tower, which buys intel.
const MEDIC_LEVELS := [
	{"rest": 0.5, "stock": 6, "cost": 0},
	{"rest": 1.0, "stock": 10, "cost": 1200},
	{"rest": 2.0, "stock": 16, "cost": 5000},
]
const MARKET_LEVELS := [
	{"stock": 3, "cost": 0},
	{"stock": 5, "cost": 2000},
	{"stock": 8, "cost": 7000},
]
const COMMS_LEVELS := [
	{"cost": 0, "words": "No set: word of mouth"},
	{"cost": 1500, "words": "A CB set: buy fresh word"},
	{"cost": 6000, "words": "A scanner: pin word across runs"},
	{"cost": 15000, "words": "A transmitter: call in words"},
]
const INTEL_CASH := [0, 60, 150, 250, 400, 650, 900, 1200, 1600]       # fresh word on a tier, by tier index

## The yard's own upgrades, cash, late: the generator runs the yard while
## you're away for longer; the lookout sees the first lot coming; the kennel
## is a dog.
const GENERATOR_LEVELS := [
	{"hours": 8, "cost": 0, "words": "No generator: eight hours away counts"},
	{"hours": 12, "cost": 4000, "words": "A generator: twelve hours away counts"},
	{"hours": 24, "cost": 12000, "words": "Diesel and a tank: a day away counts"},
	{"hours": 24, "cost": 30000, "rig_row": true, "words": "The works wired: a second row of pouches on the rig"},
]
const LOOKOUT_LEVELS := [
	{"first": 1.0, "runs": 24, "cost": 0, "words": "No lookout: odds are a guess"},
	{"first": 1.5, "runs": 24, "cost": 3000, "words": "A lookout: the first gang takes half as long again to arrive"},
	{"first": 2.0, "runs": 60, "cost": 9000, "words": "A lookout with glasses: the first gang takes twice as long to arrive, and the odds shown are good ones"},
	{"first": 2.0, "runs": 60, "cost": 24000, "call": true, "words": "A lookout on the radio: the first gang after the clear waits for the call, and the call is a full pack"},
]
const KENNEL_LEVELS := [
	{"finds": 0, "patrol": 1.0, "cost": 0, "words": "No dog"},
	{"finds": 1, "patrol": 1.0, "cost": 2500, "quality": 5, "words": "A dog: one more find every look, +5% loot quality"},
	{"finds": 1, "patrol": 1.2, "cost": 7000, "quality": 10, "words": "A good dog: it hears the next gang coming, so they arrive 20% later; +10% loot quality"},
	{"finds": 1, "patrol": 1.2, "cost": 18000, "quality": 10, "carries": true, "words": "The best dog: when a runner dies it carries the best thing in the pack home"},
]
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
		# SMGs - the Drifter's
		{"name": "Workshop SMG", "type": "smg", "tier": 2, "damage": 15.0, "rof": 2.3, "value": 100,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Police carbine", "type": "smg", "tier": 3, "damage": 17.0, "rof": 2.8, "value": 175,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		# tiers 4 and 5: the town's, and past it
		{"name": "Workshop carbine", "type": "improvised", "ammo": "smg", "tier": 4, "damage": 34.0, "rof": 1.9, "value": 260,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Drum shotgun", "type": "shotgun", "tier": 4, "damage": 44.0, "rof": 1.5, "value": 280,
			"attachments": ["optic", "muzzle", "magazine", "stock"]},
		{"name": "Scoped .308", "type": "rifle", "tier": 4, "damage": 80.0, "rof": 0.85, "value": 300,
			"attachments": ["optic", "muzzle", "magazine", "stock"]},
		{"name": "Army SMG", "type": "smg", "tier": 4, "damage": 20.0, "rof": 3.4, "value": 290,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Tooled-up garage rifle", "type": "improvised", "ammo": "rifle", "tier": 5, "damage": 40.0, "rof": 2.3, "value": 420,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Automatic shotgun", "type": "shotgun", "tier": 5, "damage": 46.0, "rof": 2.0, "value": 460,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Sniper rifle", "type": "rifle", "tier": 5, "damage": 110.0, "rof": 0.85, "value": 480,
			"attachments": ["optic", "muzzle", "magazine", "stock"]},
		# tier 6: the city's - the services, the hospital, the barracks
		{"name": "Armourer's carbine", "type": "improvised", "ammo": "smg", "tier": 6, "damage": 44.0, "rof": 2.6, "value": 650,
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
		{"name": "Section gun", "type": "smg", "tier": 6, "damage": 26.0, "rof": 4.2, "value": 700,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
		{"name": "Belt-fed SMG", "type": "smg", "tier": 5, "damage": 24.0, "rof": 3.8, "value": 470,
			"attachments": ["optic", "muzzle", "magazine", "handguard", "stock"]},
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
		{"name": "Issue pistol", "type": "pistol", "tier": 6, "damage": 22.0, "rof": 2.4, "value": 300,
			"attachments": ["optic", "muzzle", "magazine"]},
		{"name": "Automatic pistol", "type": "smg", "tier": 5, "damage": 14.0, "rof": 4.2, "value": 240,
			"attachments": ["optic", "muzzle", "magazine", "stock"]},
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
	],
	"Armour": [
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
	],
	"Backpack": [
		{"name": "School bag", "tier": 1, "capacity": 12, "value": 30},
		{"name": "Carrier bags", "tier": 1, "capacity": 8, "pace": 3, "value": 15},
		{"name": "Hiking pack", "tier": 2, "capacity": 24, "value": 60},
		{"name": "Holdall", "tier": 2, "capacity": 20, "pace": 2, "value": 70},
		{"name": "Bergen", "tier": 3, "capacity": 40, "value": 110},
		{"name": "Framed pack", "tier": 3, "capacity": 48, "pace": -5, "value": 160},
		{"name": "Expedition pack", "tier": 4, "capacity": 56, "pace": -3, "value": 260},
		{"name": "Cargo frame", "tier": 5, "capacity": 72, "pace": -8, "value": 400},
		{"name": "Patrol pack", "tier": 6, "capacity": 60, "value": 480},
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
	],
	## Papers: the before, on paper. Worth their value to the fence and nothing
	## else; the deeds are dropped by the bank once and are the ending.
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
		{"name": "A letter to the bank", "tier": 1, "value": 5, "depth": 30},
		{"name": "A list of names", "tier": 1, "value": 5, "depth": 40},
		{"name": "The manager's note", "tier": 1, "value": 6, "depth": 50},
		{"name": "The deeds", "tier": 5, "value": 5000},
	],
	## Medical: heals `heal` HP over `use` seconds, under fire the whole time.
	"Medical": [
		{"name": "Painkillers", "tier": 1, "heal": 15.0, "use": 1.5, "value": 12},
		{"name": "Bandage", "tier": 1, "heal": 25.0, "use": 3.0, "value": 15},
		{"name": "First aid kit", "tier": 1, "heal": 60.0, "use": 6.0, "value": 45},
		{"name": "Field dressing", "tier": 2, "heal": 40.0, "use": 2.0, "value": 50},
		{"name": "Trauma kit", "tier": 2, "heal": 120.0, "use": 10.0, "value": 120},
		{"name": "Surgeon's kit", "tier": 3, "heal": 200.0, "use": 12.0, "value": 220},
		{"name": "Hospital kit", "tier": 4, "heal": 300.0, "use": 14.0, "value": 380},
	],
	## Grenades (32): a pouch each, thrown at everyone on you; the hit is the type's, through the damage model
	"Grenade": [
		{"name": "Petrol bomb", "tier": 1, "damage": 80.0, "type": "fire", "value": 30},
		{"name": "Nail bomb", "tier": 1, "damage": 70.0, "type": "bleed", "value": 30},
		{"name": "Bottle of something", "tier": 2, "damage": 90.0, "type": "poison", "value": 45},
		{"name": "Dry-ice bag", "tier": 2, "damage": 60.0, "type": "frost", "value": 45},
		{"name": "Wired battery", "tier": 3, "damage": 100.0, "type": "shock", "value": 60},
	],
	## Ammo: a stack of `rounds` for a gun `type`, standard or a better grade
	## (damage_pct). Standard is always at the fence by the box; the better
	## grades are found, or on its shelf.
	"Ammo": [
		# a stack is a bag of rounds, sized so a run takes about a third of one at the type's rate
		{"name": "Nails", "type": "improvised", "tier": 1, "rounds": 200, "value": 20},
		{"name": "Hardened bolts", "type": "improvised", "tier": 2, "rounds": 120, "value": 50, "damage_pct": 15},
		{"name": "Shells", "type": "shotgun", "tier": 1, "rounds": 150, "value": 30},
		{"name": "Slugs", "type": "shotgun", "tier": 2, "rounds": 90, "value": 75, "damage_pct": 20},
		{"name": "Rifle rounds", "type": "rifle", "tier": 1, "rounds": 400, "value": 40},
		## grades with an element (33): a share of the gun's hits land as the type, through the model like a conversion affix
		{"name": "Match rounds", "type": "rifle", "tier": 2, "rounds": 240, "value": 100, "damage_pct": 15, "first_pct": 25},
		{"name": "SMG rounds", "type": "smg", "tier": 1, "rounds": 600, "value": 40},
		{"name": "SMG hollow point", "type": "smg", "tier": 2, "rounds": 360, "value": 100, "damage_pct": 15, "conv_bleed_pct": 20},
		{"name": "Pistol rounds", "type": "pistol", "tier": 1, "rounds": 300, "value": 25},
		{"name": "Pistol hollow point", "type": "pistol", "tier": 2, "rounds": 180, "value": 65, "damage_pct": 15, "conv_bleed_pct": 20},
		{"name": "Belt links", "type": "smg", "tier": 3, "rounds": 500, "value": 160, "damage_pct": 20},
		{"name": "Depot rounds", "type": "rifle", "tier": 3, "rounds": 300, "value": 170, "damage_pct": 25},
		{"name": "Incendiary shells", "type": "shotgun", "tier": 3, "rounds": 80, "value": 140, "damage_pct": 10, "conv_fire_pct": 30},
		{"name": "Incendiary SMG rounds", "type": "smg", "tier": 3, "rounds": 320, "value": 150, "damage_pct": 10, "conv_fire_pct": 30},
		{"name": "Salted rounds", "type": "rifle", "tier": 3, "rounds": 220, "value": 150, "damage_pct": 10, "conv_frost_pct": 30},
	],
}
const AMMO_PRICE := 1.5             # the fence's markup on a standard box
const AMMO_DROP := 0.22             # the share of a kill's drops that are rounds; a look's is half that
## Where loot comes from. A kill drops what they carried; a look over the
## site turns up what's lying there. Meds are rare either way; attachments
## are the site's. The weights are the lists: a slot listed twice is twice as likely.
const KILL_SLOTS := ["Primary", "Primary", "Secondary", "Helmet", "Armour", "Armour", "Rig"]
const SITE_SLOTS := ["Backpack", "Rig", "Secondary", "Helmet", "Primary", "Armour"]
const MED_PRICE := 1.5            # the clinic's markup on a common med
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
const DOTS := {"fire": {"ratio": 0.5, "s": 4.0, "stacks": 1}, "poison": {"ratio": 0.8, "s": 8.0, "stacks": 5}, "bleed": {"ratio": 0.7, "s": 6.0, "stacks": 1}}
const CHILL := 0.2                 # their fire, while chilled
const FREEZE := 0.85               # Frozen solid: how much of their fire a chilled gang loses (not all: a sliver keeps the depth honest)
const SHOCK := 0.25                # more of everything they take, while shocked
## Their side, by zone: what their fire is made of at depth 1 (physical is the
## rest) and what they resist. The element's share grows with depth (ZONE_GROW
## a depth, to ZONE_SHARE_CAP); "Resistant" and the depth add to the resists.
const ZONE_TYPES := [
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
	# socketables: the six things that go in a socket, found and fitted at the bench
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
const UNIQUES := [
	{"name": "Grandad's shotgun", "slot": "Primary", "base": "Farmer's shotgun", "rule": "grandads",
		"words": "The first of every gang takes triple", "affixes": [{"stat": "damage_pct", "value": 10}, {"stat": "first_lot_pct", "value": 20}]},
	{"name": "The Postman's bag", "slot": "Backpack", "base": "Hiking pack", "rule": "postman",
		"words": "Every search finds one more", "affixes": [{"stat": "capacity", "value": 4}, {"stat": "loot_pct", "value": 15}]},
	{"name": "The Doorman's jacket", "slot": "Armour", "base": "Police body armour", "rule": "doormans",
		"words": "With three on you, take a quarter less", "affixes": [{"stat": "armour", "value": 12}, {"stat": "hp", "value": 20}]},
	{"name": "Lucky cap", "slot": "Helmet", "base": "Hard hat", "rule": "lucky_cap",
		"words": "Finds are half as likely to be common", "affixes": [{"stat": "loot_pct", "value": 20}, {"stat": "cash_per_kill", "value": 6}]},
	# the bosses' - only from them; their rules are the affixes, for now
	{"name": "The van's spare", "slot": "Secondary", "base": "Old revolver", "rule": "vans_spare", "boss": true,
		"words": "The secondary fires at full damage, always", "affixes": [{"stat": "damage_pct", "value": 18}, {"stat": "first_lot_pct", "value": 25}, {"stat": "cash_per_kill", "value": 4}]},
	{"name": "Underlay", "slot": "Armour", "base": "Padded jacket", "rule": "underlay", "boss": true,
		"words": "The first two seconds of every gang land on the underlay", "affixes": [{"stat": "armour", "value": 30}, {"stat": "hp", "value": 25}, {"stat": "speed_pct", "value": 6}]},
	{"name": "The manager's coat", "slot": "Armour", "base": "Ballistic vest", "rule": "managers_coat", "boss": true,
		"words": "Cash half again; no notes - he doesn't take paper", "affixes": [{"stat": "armour", "value": 20}, {"stat": "cash_per_kill", "value": 8}, {"stat": "hp", "value": 20}]},
	{"name": "The branch pistol", "slot": "Secondary", "base": "Tactical pistol", "rule": "branch_pistol", "boss": true,
		"words": "Under half HP the secondary fires twice as fast", "affixes": [{"stat": "damage_pct", "value": 20}, {"stat": "damage_low_pct", "value": 25}, {"stat": "speed_pct", "value": 6}]},
	{"name": "The quartermaster's rifle", "slot": "Primary", "base": "Marksman rifle", "rule": "qm_rifle", "boss": true,
		"words": "Never runs dry; he signed for the rounds", "affixes": [{"stat": "damage_pct", "value": 20}, {"stat": "first_lot_pct", "value": 30}, {"stat": "damage_per_att", "value": 5}]},
	{"name": "Issue webbing", "slot": "Rig", "base": "Assault rig", "rule": "issue_webbing", "boss": true,
		"words": "Every pouch holds two", "affixes": [{"stat": "capacity", "value": 3}, {"stat": "armour", "value": 15}, {"stat": "loot_per_med", "value": 5}]},
	# the pinnacles' - a charm each, from a crew's head at full strength
	{"name": "The van keys", "slot": "Charm", "base": "Horseshoe nail", "rule": "van_keys", "boss": true, "pinnacle": 0,
		"words": "You drive: pace +25%", "affixes": [{"stat": "rarity_pct", "value": 10}, {"stat": "cash_pct", "value": 10}, {"stat": "loot_pct", "value": 8}]},
	{"name": "The manager's pen", "slot": "Charm", "base": "Bank's own pen", "rule": "managers_pen", "boss": true, "pinnacle": 1,
		"words": "Notes come in twos: every note found is two", "affixes": [{"stat": "rarity_pct", "value": 12}, {"stat": "cash_pct", "value": 15}, {"stat": "loot_pct", "value": 5}]},
	{"name": "The quartermaster's ledger", "slot": "Charm", "base": "Dog tag", "rule": "qm_ledger", "boss": true, "pinnacle": 2,
		"words": "Signed for: what a kill drops is a tier up", "affixes": [{"stat": "rarity_pct", "value": 15}, {"stat": "cash_pct", "value": 8}, {"stat": "loot_pct", "value": 10}]},
	# the convoy's
	{"name": "The lorry's load", "slot": "Backpack", "base": "Cargo frame", "rule": "lorrys_load", "boss": true, "convoy": true,
		"words": "The pack comes home full: every empty cell is notes", "affixes": [{"stat": "capacity", "value": 8}, {"stat": "loot_pct", "value": 15}, {"stat": "cash_per_cell", "value": 3}]},
	# the build-defining ones: a rule each, found loose from `depth` on, and from the mate once you've been that deep
	{"name": "The council's weed burner", "slot": "Primary", "base": "Pipe shotgun", "rule": "weed_burner", "depth": 12,
		"words": "A flamethrower: all fire, fire hits everyone on you, takes nothing", "affixes": [{"stat": "fire_pct", "value": 40}, {"stat": "dot_pct", "value": 30}, {"stat": "speed_pct", "value": -10}]},
	{"name": "Jump leads", "slot": "Secondary", "base": "Service pistol", "rule": "jump_leads", "depth": 12,
		"words": "A third of your damage as shock; shock on one of them is shock on all of them", "affixes": [{"stat": "shock_pct", "value": 40}, {"stat": "first_pct", "value": 20}]},
	{"name": "The rat man's bag", "slot": "Backpack", "base": "Hiking pack", "rule": "rat_mans_bag", "depth": 12,
		"words": "Poison never caps and carries to the next of them", "affixes": [{"stat": "poison_pct", "value": 40}, {"stat": "capacity", "value": 6}, {"stat": "dot_pct", "value": 20}]},
	{"name": "The butcher's steel", "slot": "Primary", "base": "Machete", "rule": "butchers_steel", "depth": 12,
		"words": "Bleed does double, and a bleed carries to the next of them", "affixes": [{"stat": "bleed_pct", "value": 40}, {"stat": "conv_bleed_pct", "value": 25}, {"stat": "attack_pct", "value": 10}]},
	{"name": "The gritter's hopper", "slot": "Armour", "base": "Riot suit", "rule": "gritters_hopper", "depth": 25,
		"words": "Everyone on you is chilled, always; chilled gangs come one at a time", "affixes": [{"stat": "frost_pct", "value": 40}, {"stat": "armour", "value": 30}, {"stat": "frost_res", "value": 30}]},
	{"name": "The sparky's gloves", "slot": "Charm", "base": "Horseshoe nail", "rule": "sparkys_gloves", "depth": 25,
		"words": "Their shock resist counts for nothing; shock costs you no armour", "affixes": [{"stat": "shock_pct", "value": 30}, {"stat": "shock_res", "value": 40}]},
	{"name": "The quartermaster's manual", "slot": "Charm", "base": "Dog tag", "rule": "qm_manual", "depth": 25,
		"words": "Every element counts as the runner's: no doubled tree, every keystone open", "affixes": [{"stat": "rarity_pct", "value": 10}, {"stat": "all_res", "value": 8}]},
	{"name": "A blue plaque", "slot": "Charm", "base": "St Christopher", "rule": "blue_plaque", "depth": 25,
		"words": "All resists +40%; nothing else on anything you wear counts", "affixes": [{"stat": "all_res", "value": 40}]},
	{"name": "The lollipop lady's sign", "slot": "Secondary", "base": "Cosh", "rule": "lollipop", "depth": 12,
		"words": "Stop: the first of every gang drops where it stands; gangs come half as often", "affixes": [{"stat": "first_pct", "value": 30}, {"stat": "patrol_pct", "value": 15}]},
	{"name": "The bookie's pencil", "slot": "Charm", "base": "Lucky penny", "rule": "bookies_pencil", "depth": 12,
		"words": "Loot quality doubled; cash halved", "affixes": [{"stat": "rarity_pct", "value": 15}, {"stat": "loot_pct", "value": 10}]},
	{"name": "The float", "slot": "Backpack", "base": "Cargo frame", "rule": "the_float", "depth": 25,
		"words": "Pace +40% and the pack half again; you carry no meds", "affixes": [{"stat": "capacity", "value": 10}, {"stat": "speed_pct", "value": 15}, {"stat": "cash_pct", "value": 20}]},
	{"name": "Nan's cardigan", "slot": "Armour", "base": "Padded jacket", "rule": "nans_cardigan", "depth": 12,
		"words": "3% of your HP back a second; no armour at all", "affixes": [{"stat": "hp", "value": 40}, {"stat": "all_res", "value": 10}]},
	{"name": "The dinner lady's ladle", "slot": "Primary", "base": "Pipe wrench", "rule": "ladle", "depth": 12,
		"words": "Every kill is a tenth of your HP back; meds do nothing", "affixes": [{"stat": "damage_pct", "value": 20}, {"stat": "attack_pct", "value": 15}]},
	{"name": "A traffic warden's hat", "slot": "Helmet", "base": "Hard hat", "rule": "wardens_hat", "depth": 12,
		"words": "Every gang arrives one short; every kill's notes doubled", "affixes": [{"stat": "notes_pct", "value": 25}, {"stat": "armour", "value": 10}]},
	{"name": "The vicar's thermos", "slot": "Charm", "base": "Casino chip", "rule": "vicars_thermos", "depth": 25,
		"words": "A burn on you heals you instead; your fire resist is nothing", "affixes": [{"stat": "regen", "value": 3}, {"stat": "fire_pct", "value": 20}]},
	{"name": "The scout leader's whistle", "slot": "Charm", "base": "Rabbit's foot", "rule": "scouts_whistle", "depth": 12,
		"words": "Every gang after the first is one", "affixes": [{"stat": "patrol_pct", "value": 10}, {"stat": "loot_pct", "value": 10}]},
	{"name": "The sergeant's whistle", "slot": "Helmet", "base": "Composite helmet", "rule": "sergeants_whistle", "depth": 25,
		"words": "Two more on you at once; everything you do does 60% more", "affixes": [{"stat": "armour", "value": 20}, {"stat": "hp", "value": 30}, {"stat": "crowd_less_pct", "value": 10}]},
	{"name": "The electrician's tester", "slot": "Secondary", "base": "Compact pistol", "rule": "tester", "depth": 12,
		"words": "Shocked stays shocked until they're down; shock does half", "affixes": [{"stat": "conv_shock_pct", "value": 25}, {"stat": "shock_pct", "value": 20}]},
	{"name": "The gamekeeper's flask", "slot": "Charm", "base": "Wedding ring", "rule": "gamekeepers_flask", "depth": 25,
		"words": "Poison on you poisons them back", "affixes": [{"stat": "poison_res", "value": 30}, {"stat": "poison_pct", "value": 30}]},
	{"name": "The caretaker's keys", "slot": "Charm", "base": "Bank's own pen", "rule": "caretakers_keys", "depth": 12,
		"words": "Something happens on every run, and every cache opens", "affixes": [{"stat": "loot_pct", "value": 15}, {"stat": "search_pct", "value": 10}]},
	{"name": "The lorry driver's log", "slot": "Paper", "base": "A pawn ticket", "rule": "drivers_log", "depth": 25,
		"words": "Notes found doubled; insurance is free", "affixes": [{"stat": "notes_pct", "value": 50}]},
]
## Sets: whose gear it was. A piece is a fixed base with its own name and a
## couple of fixed affixes, rolled like a unique, drawn in the set's own
## tint; the bonuses come at two pieces worn and at the full set - stats,
## added to what's worn, and a rule at the top. Found loose from `depth` on.
const SET_DROP := 0.004            # a share of finds a depth past the first
const SETS := [
	{"name": "The council's", "depth": 5, "words": "Parks, highways, pest control: the council's gear, orange and stamped",
		"pieces": [
			{"name": "Council hi-vis", "slot": "Armour", "base": "Stab vest", "affixes": [{"stat": "armour", "value": 10}, {"stat": "hp", "value": 12}]},
			{"name": "Council hard hat", "slot": "Helmet", "base": "Hard hat", "affixes": [{"stat": "armour", "value": 8}, {"stat": "search_pct", "value": 8}]},
			{"name": "Council rucksack", "slot": "Backpack", "base": "School bag", "affixes": [{"stat": "capacity", "value": 4}, {"stat": "loot_pct", "value": 10}]},
			{"name": "Council lanyard", "slot": "Charm", "base": "Lucky penny", "affixes": [{"stat": "notes_pct", "value": 15}, {"stat": "rarity_pct", "value": 6}]},
		],
		"bonuses": {2: {"stats": {"all_res": 20}, "words": "All resists +20%"}, 3: {"stats": {"regen": 4}, "words": "+4 HP a second"},
			4: {"stats": {"search_pct": 30, "notes_pct": 50}, "rule": "council", "words": "Searches 30% quicker, notes +50%, every cache opens"}}},
	{"name": "The ambulance's", "depth": 8, "words": "A crew's kit from the one ambulance that kept going",
		"pieces": [
			{"name": "Ambulance rig", "slot": "Rig", "base": "Paramedic's rig", "affixes": [{"stat": "med_cap", "value": 2}, {"stat": "med_speed_pct", "value": 15}]},
			{"name": "Green overalls", "slot": "Armour", "base": "Padded jacket", "affixes": [{"stat": "hp", "value": 25}, {"stat": "regen", "value": 2}]},
			{"name": "Crew helmet", "slot": "Helmet", "base": "Cycle helmet", "affixes": [{"stat": "armour", "value": 10}, {"stat": "med_speed_pct", "value": 10}]},
		],
		"bonuses": {2: {"stats": {"med_speed_pct": 50}, "words": "Meds 50% quicker"},
			3: {"rule": "ambulance", "words": "The first med of a run isn't spent; meds heal double"}}},
	{"name": "The bank's", "depth": 10, "words": "Staff, they called themselves. The blazers say so",
		"pieces": [
			{"name": "Branch blazer", "slot": "Armour", "base": "Ballistic vest", "affixes": [{"stat": "armour", "value": 20}, {"stat": "cash_pct", "value": 15}]},
			{"name": "Cashier's pen", "slot": "Charm", "base": "Bank's own pen", "affixes": [{"stat": "cash_pct", "value": 20}, {"stat": "rarity_pct", "value": 8}]},
			{"name": "Branch holdall", "slot": "Backpack", "base": "Hiking pack", "affixes": [{"stat": "capacity", "value": 6}, {"stat": "cash_per_cell", "value": 4}]},
		],
		"bonuses": {2: {"stats": {"cash_pct": 30}, "words": "Cash +30%"},
			3: {"stats": {"sell_pct": 25}, "rule": "bank", "words": "Cash from kills doubled; the fence pays +25%"}}},
	{"name": "The army's", "depth": 15, "words": "Issue kit, the lot of it, off the one lorry that got through",
		"pieces": [
			{"name": "Issue helmet", "slot": "Helmet", "base": "Composite helmet", "affixes": [{"stat": "armour", "value": 20}, {"stat": "hp", "value": 15}]},
			{"name": "Issue carrier", "slot": "Armour", "base": "Full plate carrier", "affixes": [{"stat": "armour", "value": 30}, {"stat": "all_res", "value": 8}]},
			{"name": "Issue bergen", "slot": "Backpack", "base": "Bergen", "affixes": [{"stat": "capacity", "value": 8}, {"stat": "hp", "value": 10}]},
			{"name": "Issue rifle", "slot": "Primary", "base": "Marksman rifle", "affixes": [{"stat": "damage_pct", "value": 15}, {"stat": "first_pct", "value": 20}]},
		],
		"bonuses": {2: {"stats": {"armour_pct": 15}, "words": "Armour +15%"}, 3: {"stats": {"first_pct": 40}, "words": "First shot +40%"},
			4: {"rule": "army", "words": "One fewer on you at once; everything you do does 30% more"}}},
	{"name": "The carpet man's", "depth": 5, "words": "A fitter's kit: the knife, the knee pads",
		"pieces": [
			{"name": "Carpet knife", "slot": "Secondary", "base": "Knife", "affixes": [{"stat": "bleed_pct", "value": 25}, {"stat": "attack_pct", "value": 10}]},
			{"name": "Fitter's knee pads", "slot": "Armour", "base": "Padded jacket", "affixes": [{"stat": "armour", "value": 12}, {"stat": "bleed_res", "value": 20}]},
		],
		"bonuses": {2: {"stats": {"conv_bleed_pct": 30}, "rule": "carpet", "words": "30% of your damage as bleed; bleeds last twice as long"}}},
]

## Workshop levels: what each opens, and what it costs to reach.
const WORKSHOP := [
	{"cost": 0, "mounts": [], "words": "No bench: nothing can be fitted"},
	{"cost": 1000, "mounts": ["optic", "muzzle", "grip"], "words": "A bench: optics, muzzles, grips"},
	{"cost": 5000, "mounts": ["optic", "muzzle", "magazine", "grip", "business end"], "words": "Tooling: magazines, business ends"},
	{"cost": 14000, "mounts": ["optic", "muzzle", "magazine", "handguard", "stock", "grip", "business end"], "words": "A gunsmith's: every mount"},
]

## Rarity: how many affixes an item rolls, its share of drops, its value multiple.
const RARITIES := [
	{"name": "Common", "affixes": 0, "weight": 60, "value": 1.0},
	{"name": "Uncommon", "affixes": 1, "weight": 28, "value": 1.8},
	{"name": "Rare", "affixes": 2, "weight": 10, "value": 3.5},
	{"name": "Elite", "affixes": 3, "weight": 2, "value": 8.0},
]

## Affixes: a stat and its roll range per tier. "pct" ones are percentages of
## the whole operator's figure; the rest add to it. `slots` says which items
## can carry it.
## Affixes. `min`..`max` is the whole span, T1 (the worst fifth) to T5 (the
## best) - tiers count up like the bases' do; which tiers an item can roll
## comes from its level (its base's tier plus the depth it dropped at:
## `Items.tier_cap`). `weight` is its share of a roll (1 if absent).
const AFFIX_TIERS := 5
const TIER_CAP := [0, 3, 6, 10, 15]  # the item level that opens T1, T2, T3, T4, T5
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
	{"stat": "fire_res", "label": "fire resist", "short": "fire res", "min": 5, "max": 35, "slots": ["Armour", "Helmet", "Charm"]},
	{"stat": "frost_res", "label": "frost resist", "short": "frost res", "min": 5, "max": 35, "slots": ["Armour", "Helmet", "Charm"]},
	{"stat": "poison_res", "label": "poison resist", "short": "poison res", "min": 5, "max": 35, "slots": ["Armour", "Helmet", "Charm"]},
	{"stat": "shock_res", "label": "shock resist", "short": "shock res", "min": 5, "max": 35, "slots": ["Armour", "Helmet", "Charm"]},
	{"stat": "bleed_res", "label": "bleed resist", "short": "bleed res", "min": 5, "max": 35, "slots": ["Armour", "Helmet", "Charm"]},
	{"stat": "all_res", "label": "all resists", "short": "all res", "min": 3, "max": 15, "slots": ["Armour", "Helmet", "Charm"], "weight": 0.3},
	{"stat": "dot_pct", "label": "burn, poison and bleed damage", "short": "dots", "min": 8, "max": 40, "slots": ["Primary", "Secondary", "Charm"], "weight": 0.6},
	{"stat": "armour", "label": "armour", "short": "arm", "min": 3, "max": 24, "slots": ["Helmet", "Armour", "Rig"], "flat": true},
	{"stat": "hp", "label": "max HP", "short": "HP", "min": 5, "max": 40, "slots": ["Helmet", "Armour", "Rig", "Backpack"], "flat": true},
	{"stat": "loot_pct", "label": "loot quantity", "short": "quantity", "min": 5, "max": 30, "slots": ["Rig", "Backpack", "Helmet"]},
	{"stat": "capacity", "label": "capacity", "short": "cap", "min": 1, "max": 6, "slots": ["Backpack"], "flat": true},
	{"stat": "speed_pct", "label": "pace", "short": "pace", "min": 3, "max": 15, "slots": ["Primary", "Secondary", "Armour"]},
	{"stat": "heal_pct", "label": "healing", "short": "heal", "min": 10, "max": 40, "slots": ["Medical"]},
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
const ZONES := [
	{"name": "The Estate", "words": "Ransacked streets, a parade of shops, the retail park", "tiers": [0, 1, 2]},
	{"name": "The Town", "words": "A dead theme park, the shopping centre, the bank - held by a crew", "tiers": [3, 4, 5]},
	{"name": "The City", "words": "The services on the motorway, the hospital, the barracks the lorries never reached", "tiers": [6, 7, 8]},
]
const ZONE := "The Estate"
## A site: its campaign numbers (depth 1), its shape at the endgame (how the
## depth curve is bent for it - many and thin, or few and hard; gangs often
## or rarely; cash-heavy), and its drops: which slots its finds favour, a gun
## type it leans to, and the bases found there and nowhere else.
const TIERS := [
	{"name": "Ransacked streets", "zone": 0, "pool": 6, "hp": 200.0, "dps": 0.4, "drop": 0.4, "loot_tier": 1, "xp": 2, "cash": 6,
		"shape": {"pool": 14, "hp": 0.7, "dps": 0.8, "patrol": 0.8, "cash": 0.9},
		"drops": {"slots": {"Primary": 2, "Secondary": 3, "Helmet": 2, "Armour": 1, "Rig": 1, "Backpack": 1}, "type": "improvised", "only": ["Pipe shotgun", "Carrier bags"]}},
	{"name": "The parade", "zone": 0, "pool": 10, "hp": 280.0, "dps": 0.35, "drop": 0.4, "loot_tier": 2, "xp": 3, "cash": 9,
		"shape": {"pool": 12, "hp": 0.9, "dps": 0.8, "patrol": 1.0, "cash": 1.2},
		"drops": {"slots": {"Primary": 1, "Secondary": 3, "Helmet": 1, "Armour": 1, "Rig": 2, "Backpack": 2}, "type": "pistol", "only": ["Sawn-off", "Holdall"]}},
	{"name": "The retail park", "zone": 0, "pool": 14, "hp": 420.0, "dps": 0.7, "drop": 0.45, "loot_tier": 3, "xp": 6, "cash": 14,
		"shape": {"pool": 12, "hp": 1.0, "dps": 1.0, "patrol": 1.0, "cash": 1.0, "att": 2.0},
		"drops": {"slots": {"Primary": 3, "Secondary": 1, "Helmet": 1, "Armour": 2, "Rig": 1, "Backpack": 1}, "type": "improvised", "only": ["Garage-built rifle", "Drum magazine", "Wire stock"]}},
	{"name": "The pleasure park", "zone": 1, "pool": 12, "hp": 1100.0, "dps": 1.4, "drop": 0.45, "loot_tier": 3, "xp": 10, "cash": 22,
		"shape": {"pool": 10, "hp": 1.0, "dps": 1.1, "patrol": 1.2, "cash": 1.0},
		"drops": {"slots": {"Primary": 1, "Secondary": 1, "Helmet": 1, "Armour": 1, "Rig": 3, "Backpack": 3}, "type": "shotgun", "only": ["Framed pack", "Fishing vest"]}},
	{"name": "Shopping centre", "zone": 1, "pool": 16, "hp": 1300.0, "dps": 1.8, "drop": 0.5, "loot_tier": 4, "xp": 15, "cash": 24,
		"shape": {"pool": 11, "hp": 1.1, "dps": 1.0, "patrol": 0.9, "cash": 1.1},
		"drops": {"slots": {"Primary": 1, "Secondary": 2, "Helmet": 3, "Armour": 3, "Rig": 1, "Backpack": 1}, "type": "pistol", "only": ["Tactical pistol", "Ballistic vest"]}},
	{"name": "The bank", "zone": 1, "pool": 20, "hp": 1500.0, "dps": 2.4, "drop": 0.5, "loot_tier": 5, "xp": 20, "cash": 30,
		"shape": {"pool": 7, "hp": 1.4, "dps": 1.3, "patrol": 1.5, "cash": 1.6, "paper": 3.0},
		"drops": {"slots": {"Primary": 2, "Secondary": 2, "Helmet": 1, "Armour": 2, "Rig": 1, "Backpack": 1}, "type": "smg", "only": ["Compact pistol", "Light plates"]}},
	{"name": "The services", "zone": 2, "pool": 16, "hp": 2600.0, "dps": 3.2, "drop": 0.5, "loot_tier": 5, "xp": 30, "cash": 40,
		"shape": {"pool": 12, "hp": 1.0, "dps": 1.0, "patrol": 0.7, "cash": 1.0, "ammo": 2.5},
		"drops": {"slots": {"Primary": 2, "Secondary": 2, "Helmet": 1, "Armour": 1, "Rig": 2, "Backpack": 2}, "type": "smg", "only": ["Belt links", "Depot rounds", "Cargo frame"]}},
	{"name": "The hospital", "zone": 2, "pool": 18, "hp": 3300.0, "dps": 3.9, "drop": 0.5, "loot_tier": 6, "xp": 36, "cash": 44,
		"shape": {"pool": 10, "hp": 1.2, "dps": 1.0, "patrol": 1.0, "cash": 0.9, "med": 3.0},
		"drops": {"slots": {"Primary": 1, "Secondary": 1, "Helmet": 1, "Armour": 2, "Rig": 3, "Backpack": 1}, "type": "", "only": ["Hospital kit", "Surgeon's kit", "Medic's harness"]}},
	{"name": "The barracks", "zone": 2, "pool": 22, "hp": 4200.0, "dps": 4.8, "drop": 0.55, "loot_tier": 6, "xp": 46, "cash": 50,
		"shape": {"pool": 8, "hp": 1.5, "dps": 1.4, "patrol": 1.3, "cash": 0.8},
		"drops": {"slots": {"Primary": 3, "Secondary": 1, "Helmet": 2, "Armour": 3, "Rig": 2, "Backpack": 1}, "type": "rifle", "only": ["Section gun", "Issue plates", "Night optic"]}},
]

const BANK := 5                    # the tier whose vault holds the deeds

## The endgame's depth curve: once the campaign is done, every site fights
## at the depth's numbers bent by its shape, so the choice between sites is
## what they drop, not how hard they are. Depth 2 is the first rung.
const CURVE := {"hp": 3200.0, "dps": 3.6, "xp": 30.0, "cash": 40.0, "drop": 0.5, "grow": 0.14, "reward": 0.10, "rarity": 0.10}

## The bosses: one a zone, the crew's head, fought at the zone's last site
## after its pool is down. Free the first time (the campaign); after that
## the crew's price in notes, by depth. Each has their own drops.
const BOSSES := [
	{"zone": 0, "name": "The carpet man", "tier": 2, "hp": 10.0, "dps": 3.0, "notes": 20,
		"words": "The crew in the carpet warehouse have a leader. He had a van and a lock-up before; he has the car park now.",
		"uniques": ["The van's spare", "Underlay"]},
	{"zone": 1, "name": "The manager", "tier": 5, "hp": 12.0, "dps": 3.5, "notes": 40,
		"words": "The bank's crew call themselves staff. He was. He's behind the vault, and he's not coming out for you.",
		"uniques": ["The manager's coat", "The branch pistol"]},
	{"zone": 2, "name": "The quartermaster", "tier": 8, "hp": 6.0, "dps": 2.5, "notes": 60,     # the barracks went up; he came down to match: the pool before him is the fight
		"words": "The lorry that never reached the barracks reached him. He's been issuing it ever since, to people he chooses.",
		"uniques": ["The quartermaster's rifle", "Issue webbing"]},
]
## Pinnacles: from PINNACLE_DEPTH a crew's head comes at full strength -
## harder, dearer, and with one more thing of theirs (a charm) in the pool.
## The convoy: the services at CONVOY_DEPTH and up can take on all three
## crews at once, one head after another, for all three prices; what comes
## home is the lorry's load.
const PINNACLE_DEPTH := 10
const PINNACLE_HP := 2.5
const PINNACLE_DPS := 1.6
const PINNACLE_COST := 2
const CONVOY_DEPTH := 12
const CONVOY_TIER := 6             # the services
const CONVOY_UNIQUE := "The lorry's load"
const BOSS_HP_MULT := 1.0          # boss HP = site hp × boss "hp"; scales with the curve past the campaign
const NOTES_KILL := 1              # notes a kill, times the depth factor
const NOTES_SEARCH := 0.3          # chance a search turns up a note or two
const NOTES_BOSS := 5              # notes a boss kill, times depth

## Training - the yard's, kept across runners. One common tree, and two for
## what the runner was (the class). Each tree is a chain: a node needs the one
## before it. Small nodes add a number; a notable (every fourth) changes a
## rule; a class tree's last node is a keystone that breaks one outright.
## A node with a "type" only counts while the primary is a gun of that type.
## A point a level; respec costs RESPEC_CASH a point spent; changing class
## refunds its two trees for nothing.
const COMMON_TREE := "The yard"
const TREES := [
	{"name": "The yard", "nodes": [
		{"name": "Dry fire", "effect": "damage_pct", "value": 3},
		{"name": "Long walks", "effect": "hp", "value": 4},
		{"name": "Knowing the streets", "effect": "loot_pct", "value": 3},
		{"name": "Double tap", "effect": "double_tap", "notable": true, "words": "The secondary fires at full damage, not a third"},
		{"name": "Zeroing", "effect": "damage_pct", "value": 3},
		{"name": "Circuits", "effect": "hp", "value": 4},
		{"name": "Keen eyes", "effect": "search_pct", "value": 15},
		{"name": "Second wind", "effect": "second_wind", "notable": true, "words": "Rest at the yard twice as fast"},
		{"name": "Practice", "effect": "damage_pct", "value": 4},
		{"name": "Sleeping rough", "effect": "hp", "value": 5},
		{"name": "Stashing", "effect": "loot_pct", "value": 4},
		{"name": "Pack horse", "effect": "pack_mule", "notable": true, "words": "The pack carries six cells more"},
		{"name": "The dog's share", "effect": "cap_dogs_share", "capstone": true, "needs": 11, "words": "A dead runner's rig comes home: the dog carries it"},
	]},
	# A class tree is a web: a spine of four to its notable, then two branches
	# off it - one to the keystone, one to a rule of its own - so a tree is a
	# choice of which way to go, not a ladder. `needs` is the node before.
	# Poacher
	{"name": "Stalking", "class": "Poacher", "nodes": [
		{"name": "Still hands", "effect": "first_pct", "value": 5},
		{"name": "Breathing", "effect": "damage_pct", "value": 3},
		{"name": "Patience", "effect": "patrol_pct", "value": 10},
		{"name": "Rifleman", "effect": "first_pct", "value": 100, "type": "rifle", "notable": true, "words": "With a rifle: your first shot on every gang does double"},
		{"name": "Wind reading", "effect": "first_pct", "value": 10, "needs": 3},
		{"name": "Long shot", "effect": "damage_pct", "value": 4},
		{"name": "One shot", "effect": "one_shot", "keystone": true, "words": "The first of every gang drops to your first shot"},
		{"name": "Lying up", "effect": "patrol_pct", "value": 10, "needs": 3},
		{"name": "Rat bait", "effect": "conv_poison_pct", "value": 15, "notable": true, "words": "15% of your damage as poison"},
		{"name": "Night work", "effect": "night_work", "notable": true, "words": "Every site you run is Night: +50% loot quality, pace −20%"},
		{"name": "Dead quiet", "effect": "cap_dead_quiet", "capstone": true, "needs": 6, "words": "Every gang is the size of the first: they never grow"},
	]},
	{"name": "Snares", "class": "Poacher", "nodes": [
		{"name": "Quick hands", "effect": "search_pct", "value": 15},
		{"name": "Hedgerows", "effect": "loot_pct", "value": 3},
		{"name": "Soft ground", "effect": "patrol_pct", "value": 10},
		{"name": "Quiet feet", "effect": "quiet_feet", "notable": true, "words": "The next gang comes every 30 seconds, not 20"},
		{"name": "Night eyes", "effect": "rarity", "value": 20, "needs": 3},
		{"name": "Snare lines", "effect": "loot_pct", "value": 4},
		{"name": "Trapline", "effect": "trapline", "keystone": true, "words": "Every gang arrives one head short, the first included"},
		{"name": "Knowing the land", "effect": "loot_pct", "value": 5, "needs": 3},
		{"name": "Cold snap", "effect": "conv_frost_pct", "value": 15, "notable": true, "words": "15% of your damage as frost"},
		{"name": "Early doors", "effect": "early_doors", "notable": true, "words": "The first gang takes twice as long to come"},
		{"name": "Poached", "effect": "cap_poached", "capstone": true, "needs": 6, "words": "Every gang arrives already light: a find is yours the moment they come"},
	]},
	# Doorman
	{"name": "Muscle", "class": "Doorman", "nodes": [
		{"name": "Heavy hands", "effect": "damage_pct", "value": 4},
		{"name": "Gym", "effect": "hp", "value": 4},
		{"name": "Broad shoulders", "effect": "armour_pct", "value": 5},
		{"name": "Shotgunner", "effect": "damage_pct", "value": 25, "type": "shotgun", "notable": true, "words": "With a shotgun: +25% damage"},
		{"name": "Weights", "effect": "damage_pct", "value": 5, "needs": 3},
		{"name": "Thick skin", "effect": "armour_pct", "value": 8},
		{"name": "Bodyline", "effect": "bodyline", "keystone": true, "words": "With three on you, you take half the damage"},
		{"name": "Big frame", "effect": "hp", "value": 6, "needs": 3},
		{"name": "Glassing", "effect": "conv_bleed_pct", "value": 15, "notable": true, "words": "15% of your damage as bleed"},
		{"name": "Loud", "effect": "loud", "notable": true, "words": "Gangs come sooner and one head bigger; +30% drops"},
		{"name": "Spoils", "effect": "rarity", "value": 15, "needs": 3},
		{"name": "Iron", "effect": "cap_iron", "capstone": true, "needs": 6, "words": "Under half HP, every kill heals a tenth of you"},
	]},
	{"name": "The door", "class": "Doorman", "nodes": [
		{"name": "Stance", "effect": "hp", "value": 5},
		{"name": "Heads down", "effect": "damage_pct", "value": 3},
		{"name": "Eye contact", "effect": "armour_pct", "value": 5},
		{"name": "Chokepoints", "effect": "overwatch", "notable": true, "words": "Only two of a gang can fire on you at once, not three"},
		{"name": "Bouncing", "effect": "hp", "value": 5, "needs": 3},
		{"name": "Keep back", "effect": "armour_pct", "value": 5},
		{"name": "One at a time", "effect": "one_at_a_time", "keystone": true, "words": "Only one of a gang can ever fire on you at once; pace −25%"},
		{"name": "Composure", "effect": "hp", "value": 5, "needs": 3},
		{"name": "Through the lot", "effect": "melee_sweep", "type": "melee", "notable": true, "words": "With a bat or a blade: a swing hits everyone on you"},
		{"name": "Stand and fight", "effect": "stand", "notable": true, "words": "No leaving before the fight is won; the bonus for winning it is doubled"},
		{"name": "Held", "effect": "cap_held", "capstone": true, "needs": 6, "words": "No second of their fire takes more than a tenth of you"},
	]},
	# Paramedic
	{"name": "Triage", "class": "Paramedic", "nodes": [
		{"name": "Steady hands", "effect": "heal_pct", "value": 10},
		{"name": "Fast hands", "effect": "med_speed_pct", "value": 15},
		{"name": "Kit bag", "effect": "heal_pct", "value": 10},
		{"name": "Triage", "effect": "triage", "notable": true, "words": "Meds take half the time"},
		{"name": "Good veins", "effect": "heal_pct", "value": 15, "needs": 3},
		{"name": "Stock take", "effect": "med_cap", "value": 1},
		{"name": "Field surgery", "effect": "field_surgery", "keystone": true, "words": "Meds work at once, not over seconds"},
		{"name": "Pressure", "effect": "heal_pct", "value": 15, "needs": 3},
		{"name": "Syringe", "effect": "conv_poison_pct", "value": 15, "notable": true, "words": "15% of your damage as poison"},
		{"name": "Walking wounded", "effect": "walking_wounded", "notable": true, "words": "Under half HP: +40% damage; meds heal half"},
		{"name": "Pockets checked", "effect": "rarity", "value": 15, "needs": 3},
		{"name": "Clean hands", "effect": "cap_clean_hands", "capstone": true, "needs": 6, "words": "A med clears everything on you, and nothing lands for three seconds"},
	]},
	{"name": "Shifts", "class": "Paramedic", "nodes": [
		{"name": "Night shift", "effect": "hp", "value": 5},
		{"name": "Rest easy", "effect": "rest_pct", "value": 25},
		{"name": "Mates' rates", "effect": "treat_pct", "value": 20},
		{"name": "Walk it off", "effect": "walk_it_off", "notable": true, "words": "1 HP a second comes back while a site is being searched"},
		{"name": "Long shift", "effect": "hp", "value": 5, "needs": 3},
		{"name": "Cold tea", "effect": "rest_pct", "value": 25},
		{"name": "Not today", "effect": "not_today", "keystone": true, "words": "The first hit on a run that would kill you leaves you on half HP instead"},
		{"name": "Discount", "effect": "treat_pct", "value": 20, "needs": 3},
		{"name": "Ice pack", "effect": "conv_frost_pct", "value": 15, "notable": true, "words": "15% of your damage as frost"},
		{"name": "Second shift", "effect": "second_shift", "notable": true, "words": "The first med used on a run isn't spent"},
		{"name": "Transfusion", "effect": "cap_transfusion", "capstone": true, "needs": 6, "words": "Healing past full becomes armour for the run, two HP to one"},
	]},
	# Scrapper
	{"name": "Stripping", "class": "Scrapper", "nodes": [
		{"name": "Nose for parts", "effect": "att_share", "value": 5},
		{"name": "Quick hands", "effect": "search_pct", "value": 15},
		{"name": "Tools", "effect": "damage_pct", "value": 3},
		{"name": "Bodger", "effect": "damage_pct", "value": 40, "type": "improvised", "notable": true, "words": "With something improvised: +40% damage"},
		{"name": "Spare parts", "effect": "att_share", "value": 5, "needs": 3},
		{"name": "Fast strip", "effect": "search_pct", "value": 15},
		{"name": "Nothing wasted", "effect": "nothing_wasted", "keystone": true, "words": "Every kill drops something"},
		{"name": "Magpie eye", "effect": "loot_pct", "value": 4, "needs": 3},
		{"name": "Live wire", "effect": "conv_shock_pct", "value": 15, "notable": true, "words": "15% of your damage as shock"},
		{"name": "Quiet hands", "effect": "quiet_hands", "notable": true, "words": "Every search finds two things, and kills drop nothing"},
		{"name": "Jerry-rigged", "effect": "cap_jerry", "capstone": true, "needs": 6, "words": "Something improvised hits half again as hard"},
	]},
	{"name": "Fencing", "class": "Scrapper", "nodes": [
		{"name": "Haggling", "effect": "sell_pct", "value": 10},
		{"name": "Contacts", "effect": "cash_pct", "value": 10},
		{"name": "Weighing it up", "effect": "sell_pct", "value": 10},
		{"name": "Magpie", "effect": "scavenger", "notable": true, "words": "Every search finds two things"},
		{"name": "Known face", "effect": "cash_pct", "value": 10, "needs": 3},
		{"name": "Fair price", "effect": "sell_pct", "value": 10},
		{"name": "Buyer's market", "effect": "buyers_market", "keystone": true, "words": "The fence pays double; buying costs double"},
		{"name": "Lucky find", "effect": "rarity", "value": 20, "needs": 3},
		{"name": "Blowtorch", "effect": "conv_fire_pct", "value": 15, "notable": true, "words": "15% of your damage as fire"},
		{"name": "Hoarder", "effect": "hoarder", "notable": true, "words": "The pack carries double; −30% pace"},
		{"name": "The lot", "effect": "cap_the_lot", "capstone": true, "needs": 6, "words": "A pack that comes home full pays double cash"},
	]},
	# Drifter
	{"name": "Moving on", "class": "Drifter", "nodes": [
		{"name": "Light feet", "effect": "pace_pct", "value": 5},
		{"name": "Road legs", "effect": "hp", "value": 5},
		{"name": "Head start", "effect": "patrol_pct", "value": 10},
		{"name": "Spray", "effect": "damage_pct", "value": 25, "type": "smg", "notable": true, "words": "With an SMG: +25% damage"},
		{"name": "Keep moving", "effect": "pace_pct", "value": 5, "needs": 3},
		{"name": "Never still", "effect": "patrol_pct", "value": 10},
		{"name": "Never there", "effect": "never_there", "keystone": true, "words": "No gang ever comes; searching takes twice as long"},
		{"name": "Wiry", "effect": "hp", "value": 5, "needs": 3},
		{"name": "Petrol bomb", "effect": "conv_fire_pct", "value": 15, "notable": true, "words": "15% of your damage as fire"},
		{"name": "Hit and run", "effect": "hit_and_run", "notable": true, "words": "Leaves as the first gang arrives, the loot kept; every kill pays 50% more"},
		{"name": "Ghost", "effect": "cap_ghost", "capstone": true, "needs": 6, "words": "The first gang never comes: a run starts at the search, and a full pack brought home is the clear"},
	]},
	{"name": "Luck", "class": "Drifter", "nodes": [
		{"name": "Lucky", "effect": "rarity", "value": 10},
		{"name": "Found money", "effect": "cash_pct", "value": 10},
		{"name": "Charmed", "effect": "loot_pct", "value": 3},
		{"name": "Dead man's shoes", "effect": "damage_low_pct", "value": 20, "notable": true, "words": "Under half HP: +20% damage"},
		{"name": "Rabbit's foot", "effect": "rarity", "value": 15, "needs": 3},
		{"name": "Pockets", "effect": "cash_pct", "value": 10},
		{"name": "All or nothing", "effect": "all_or_nothing", "keystone": true, "words": "Nothing common is ever found, and half as many things are"},
		{"name": "Four-leaf", "effect": "loot_pct", "value": 4, "needs": 3},
		{"name": "Jump start", "effect": "conv_shock_pct", "value": 15, "notable": true, "words": "15% of your damage as shock"},
		{"name": "Light fingers", "effect": "light_fingers", "notable": true, "words": "Papers three times as often; cash −20%"},
		{"name": "Loaded dice", "effect": "cap_loaded_dice", "capstone": true, "needs": 6, "words": "A Rare or better find rolls twice and keeps the better"},
	]},
]
## The second past: at ASCEND_LEVEL the runner takes a second class, whose
## first tree opens beside the first's. Its keystone and rule are theirs too.
## The element trees: one a type, a web like the class ones - a spine of
## conversion and increased to a notable, a branch to a keystone that breaks
## the element's rule, a branch to a notable with a cost. Any class can walk
## any of them; its two affinities (AFFINITY) come at the normal price, the
## others cost double and their keystone needs the second past.
const ELEMENT_TREES := [
	{"name": "Petrol", "element": "fire", "nodes": [
		{"name": "A can of it", "effect": "conv_fire_pct", "value": 10},
		{"name": "Rags", "effect": "fire_pct", "value": 10},
		{"name": "Siphoned", "effect": "conv_fire_pct", "value": 15},
		{"name": "Lit", "effect": "fire_pct", "value": 30, "notable": true, "words": "+30% fire; burns last twice as long"},
		{"name": "Wick", "effect": "fire_pct", "value": 12, "needs": 3},
		{"name": "Splash", "effect": "conv_fire_pct", "value": 20},
		{"name": "Spreads", "effect": "fire_spread", "keystone": true, "words": "Fire hits everyone on you"},
		{"name": "Fumes", "effect": "dot_pct", "value": 20, "needs": 3},
		{"name": "Jerry can", "effect": "conv_fire_pct", "value": 20},
		{"name": "On your hands", "effect": "fire_more", "notable": true, "words": "Fire does 40% more; every hit of it burns you for 2% of it"},
		{"name": "Spread", "effect": "cap_spread", "capstone": true, "needs": 6, "words": "The burn on one of them carries to the next"},
	]},
	{"name": "The cold", "element": "frost", "nodes": [
		{"name": "Antifreeze", "effect": "conv_frost_pct", "value": 10},
		{"name": "Frost", "effect": "frost_pct", "value": 10},
		{"name": "A hard winter", "effect": "conv_frost_pct", "value": 15},
		{"name": "Chill", "effect": "frost_pct", "value": 30, "notable": true, "words": "+30% frost; chilled gangs fire 40% slower, not 20"},
		{"name": "Numb", "effect": "frost_pct", "value": 12, "needs": 3},
		{"name": "Black ice", "effect": "conv_frost_pct", "value": 20},
		{"name": "Frozen solid", "effect": "frost_freeze", "keystone": true, "words": "Chilled gangs fire at 15%; your frost does half damage"},
		{"name": "Wind chill", "effect": "frost_pct", "value": 15, "needs": 3},
		{"name": "Deep freeze", "effect": "conv_frost_pct", "value": 20},
		{"name": "Cold hands", "effect": "frost_more", "notable": true, "words": "Frost does 40% more; pace −15%"},
		{"name": "Shatter", "effect": "cap_shatter", "capstone": true, "needs": 6, "words": "A chilled target takes double from the physical"},
	]},
	{"name": "The rat man", "element": "poison", "nodes": [
		{"name": "Under the sink", "effect": "conv_poison_pct", "value": 10},
		{"name": "Bait", "effect": "poison_pct", "value": 10},
		{"name": "Council issue", "effect": "conv_poison_pct", "value": 15},
		{"name": "Dosed", "effect": "poison_pct", "value": 30, "notable": true, "words": "+30% poison; poison lasts twice as long"},
		{"name": "Cumulative", "effect": "dot_pct", "value": 15, "needs": 3},
		{"name": "Blue pellets", "effect": "conv_poison_pct", "value": 20},
		{"name": "Builds", "effect": "poison_stacks", "keystone": true, "words": "Poison stacks to fifteen, not five"},
		{"name": "Slow acting", "effect": "poison_pct", "value": 15, "needs": 3},
		{"name": "The whole tin", "effect": "conv_poison_pct", "value": 20},
		{"name": "Rat's share", "effect": "poison_more", "notable": true, "words": "Poison does 40% more; loot quantity −20%"},
		{"name": "Lingers", "effect": "cap_lingers", "capstone": true, "needs": 6, "words": "The poison on one of them carries to the next"},
	]},
	{"name": "Live", "element": "shock", "nodes": [
		{"name": "Jump leads", "effect": "conv_shock_pct", "value": 10},
		{"name": "Charge", "effect": "shock_pct", "value": 10},
		{"name": "Off the mains", "effect": "conv_shock_pct", "value": 15},
		{"name": "Live", "effect": "shock_pct", "value": 30, "notable": true, "words": "+30% shock; shocked gangs take 40% more, not 25"},
		{"name": "Amps", "effect": "shock_pct", "value": 12, "needs": 3},
		{"name": "Bare wire", "effect": "conv_shock_pct", "value": 20},
		{"name": "Live wire", "effect": "shock_chain", "keystone": true, "words": "Shock on one of them is shock on all of them"},
		{"name": "Volts", "effect": "shock_pct", "value": 15, "needs": 3},
		{"name": "Substation", "effect": "conv_shock_pct", "value": 20},
		{"name": "Earthed", "effect": "shock_more", "notable": true, "words": "Shock does 40% more; armour −20%"},
		{"name": "Arc", "effect": "cap_arc", "capstone": true, "needs": 6, "words": "A shock holds as long as you fire"},
	]},
	{"name": "Blades", "element": "bleed", "nodes": [
		{"name": "Stanley knife", "effect": "conv_bleed_pct", "value": 10},
		{"name": "An edge", "effect": "bleed_pct", "value": 10},
		{"name": "Sharpened", "effect": "conv_bleed_pct", "value": 15},
		{"name": "Opened up", "effect": "bleed_pct", "value": 30, "notable": true, "words": "+30% bleed; bleeds last twice as long"},
		{"name": "Deep", "effect": "bleed_pct", "value": 12, "needs": 3},
		{"name": "Serrated", "effect": "conv_bleed_pct", "value": 20},
		{"name": "Won't stop", "effect": "bleed_forever", "keystone": true, "words": "Bleeds don't fade until they're down, and stack to three"},
		{"name": "Nicked", "effect": "dot_pct", "value": 20, "needs": 3},
		{"name": "Butcher's", "effect": "conv_bleed_pct", "value": 20},
		{"name": "Blood up", "effect": "bleed_more", "notable": true, "words": "Bleed does 40% more; your meds 30% slower"},
		{"name": "Bleed out", "effect": "cap_bleed_out", "capstone": true, "needs": 6, "words": "A bleed carries to the next, and bleeds half again as hard"},
	]},
]
const AFFINITY := {"Drifter": ["fire", "shock"], "Doorman": ["bleed", "physical"], "Poacher": ["poison", "frost"], "Scrapper": ["shock", "fire"], "Paramedic": ["poison", "frost"]}
const OFF_AFFINITY_COST := 2       # an element off the class's pair costs double a node

const ASCEND_LEVEL := 30

## Insurance: the fence holds the paper on the kit for a run. Dies, and the
## kit comes back to the yard's stash. A share of what's worn, by depth.
const INSURE_RATE := 0.15
## Calling in a word costs by depth and by the words already on the site:
## the endgame's cash sink (JUICE_COST × INTEL_CASH × depth × (1 + words)).
const JUICE_WORDS_MULT := 1.0

## Moving the yard: after the campaign, start again somewhere else. What
## comes: the uniques, the yard's own tree, the list of runners before, half
## the notes, and a yard whose name travels - magic find and cash a move.
const MOVE_FIND := 5               # percent magic find a move
const MOVE_CASH := 5               # percent cash a move
const MOVE_POINTS := 2             # training points a move, free at the start
const MOVE_NOTES_KEPT := 0.5

## The bench's crafting, paid in notes: times the item's tier and its rarity + 1.
## The bench's crafting, in cash: a price × the item's level × (rarity + 1).
## Perfection is dear and bottomless; that's the late game's cash sink.
## "bump" is in notes: the crews' thing, not the fence's.
const CRAFT := {
	"reroll": {"name": "Re-roll the affixes", "cash": 40, "words": "The same number, rolled again, tiers and all"},
	"lock": {"name": "Lock one, re-roll the rest", "cash": 120, "words": "The one you pick stays as it is", "pick": true},
	"one": {"name": "Re-roll one", "cash": 80, "words": "Rolled again; a chance up a tier, a smaller one down", "pick": true},
	"add": {"name": "Add an affix", "cash": 100, "words": "One more, a rarity up"},
	"socket": {"name": "Cut a socket", "cash": 80, "words": "One more socket, up to two"},
	"strip": {"name": "Strip the affixes", "cash": 10, "words": "Back to plain; the value goes with them"},
	"bump": {"name": "Raise the item's level", "notes": 10, "words": "Three levels up: better tiers can roll; up to the base's tier plus 20"},
}
const BUMP_LEVELS := 3
const BUMP_CAP := 20

## Events: something happens on a run, once at most, EVENT_ODDS of runs,
## some way in. A convoy passes (a bigger gang, and they carry notes); a
## runner trapped under something (freed, they turn up at the yard next:
## `promised`); a locked cache (the bench's tools open it for a find
## a tier up, or it stays shut).
const EVENT_ODDS := 0.3
const EVENT_WINDOW := [15.0, 70.0]  # seconds in, when it happens
const EVENT_CACHE_BENCH := 2        # the bench level that opens a cache
const EVENTS := ["convoy", "trapped", "cache"]

## Contracts: the fence wants so many of a slot at a rarity, and pays in
## cash, in notes, or - now and then - with one of the loose uniques. Three
## open at a time; a handed-in one is replaced. The fence's mate sells a
## loose unique for notes, a different one every MATE_RUNS runs.
const CONTRACTS_OPEN := 3
const CONTRACT_SLOTS := ["Primary", "Secondary", "Helmet", "Armour", "Rig", "Backpack", "Attachment"]
const CONTRACT_CASH := 2.5         # times the items' sell price
const CONTRACT_NOTES := 4          # a note a rarity a piece, times this
const CONTRACT_UNIQUE_ODDS := 0.2  # a contract paying a unique: three rares
const MATE_RUNS := 5
const MATE_NOTES := 400            # a unique from the mate, times the tier

## The map: the endgame's own tree. A point for every new depth cleared on
## any site past the first; spent on how the sites run, for every site.
const ATLAS := [
	{"key": "picked_over", "name": "Picked over", "max": 3, "words": "A site's own things turn up more: a third of finds, then half, then two-thirds"},
	{"key": "paid_in_notes", "name": "Paid in notes", "max": 3, "words": "Every kill carries a note more a rank"},
	{"key": "two_of_everything", "name": "Two of everything", "max": 1, "words": "A crew's head drops two of theirs"},
	{"key": "deeper_pockets", "name": "Deeper pockets", "max": 3, "words": "Searches 10% quicker a rank"},
	{"key": "word_travels", "name": "Word travels", "max": 1, "words": "Calling in a word on the radio costs half"},
	{"key": "quiet_roads", "name": "Quiet roads", "max": 3, "words": "Gangs come 10% later a rank"},
]

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

## Classes - what the runner was, before: chosen in the caravan, changed in the yard for free.
## Each is a set of rules on how the sim plays - what a weapon does, not what
## can be fitted - with a cost to go with it. Numbers are multipliers the sim
## reads by key; "words" is what the Barracks says.
const CLASSES := [
	{"name": "Poacher", "words": "+40% damage to the first of every gang; the next gang 25% slower to arrive; −10% max HP",
		"first_pct": 40, "patrol": 1.25, "hp": 0.9},
	{"name": "Doorman", "words": "+15% damage; armour counts 20% more; −10% pace",
		"damage": 1.15, "armour": 1.2, "pace": 0.9},
	{"name": "Paramedic", "words": "Meds heal 50% more and are used by themselves under 40% HP; −10% damage",
		"heal": 1.5, "auto_med": true, "damage": 0.9},
	{"name": "Scrapper", "words": "Searches 30% faster; +15% loot quantity; −5% damage",
		"search": 0.7, "loot": 0.15, "damage": 0.95},
	{"name": "Drifter", "words": "One fewer on you at a time; +10% pace; −15% max HP",
		"contact": -1, "pace": 1.1, "hp": 0.85},
]


## A node's cost in points: 1 for the first four of a tree, 2 for the next
## four, 3 for the last four; a notable one more, a keystone two more. The
## common tree is 27, a class tree 15: 57 for the three on show, against 49
## points by level 50.
static func node_cost(i: int, notable: bool, keystone := false) -> int:
	return 1 + i / 4 + (2 if keystone else (1 if notable else 0))


## A capstone costs a third of what the rest of its tree does, rounded up.
static func capstone_cost(t: Dictionary) -> int:
	var total := 0
	for i in range(t["nodes"].size()):
		var n: Dictionary = t["nodes"][i]
		if not n.get("capstone", false):
			total += node_cost(i, n.get("notable", false), n.get("keystone", false))
	return maxi(1, ceili(total / 3.0))


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


## The node a node needs trained first: the one before it, or the fork it hangs off.
static func node_needs(t: Dictionary, i: int) -> int:
	if i == 0:
		return -1
	return int(t["nodes"][i].get("needs", i - 1))


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
const MODIFIERS := [
	{"name": "Numbers", "words": "+50% HP, drops +40%", "hp": 1.5, "drop": 1.4},
	{"name": "Tooled up", "words": "Fire +40%, loot a tier up", "dps": 1.4, "loot_tier": 1},
	{"name": "Night", "words": "Pace −20%, rarer loot", "pace": 0.8, "rarity": 0.5},
	{"name": "Delivery day", "words": "Gangs ×2, cash +80%", "patrol": 0.6, "cash": 1.8},
	{"name": "Quiet road", "words": "Gangs ×½, drops −30%", "patrol": 1.5, "drop": 0.7},
	{"name": "Spread out", "words": "−1 on you, HP +30%", "contact": -1, "hp": 1.3},
	{"name": "Cash about", "words": "Cash +50%, XP −20%", "cash": 1.5, "xp": 0.8},
	{"name": "Lying low", "words": "Fire −30%, XP −30%", "dps": 0.7, "xp": 0.7},
	{"name": "Ex-army", "words": "HP, fire +30%, XP +60%", "hp": 1.3, "dps": 1.3, "xp": 1.6},
	{"name": "Picked over", "words": "Slow pickings, cash +40%", "search": 2.0, "cash": 1.4},
	# the sky's: never rolled as a word; the clock and the weather put them on
	{"name": "Rain", "words": "Slower search, gangs later", "search": 1.3, "patrol": 1.25, "sky": true},
	{"name": "Fog", "words": "−1 on you, drops −10%", "contact": -1, "drop": 0.9, "sky": true},
	# the types: what their fire is made of, and what they resist
	{"name": "Burners", "words": "A third fire, drops +20%", "type": "fire", "share": 0.33, "drop": 1.2},
	{"name": "Cutters", "words": "A third bleed, drops +20%", "type": "bleed", "share": 0.33, "drop": 1.2},
	{"name": "Wired", "words": "A third shock, drops +20%", "type": "shock", "share": 0.33, "drop": 1.2},
	{"name": "Jacketed", "words": "Fire res 40%, cash +30%", "res": "fire", "res_add": 0.4, "cash": 1.3},
	{"name": "Rubbered", "words": "Shock res 40%, £ +30%", "res": "shock", "res_add": 0.4, "cash": 1.3},
	{"name": "Hardened", "words": "Phys res 30%, cash +30%", "res": "physical", "res_add": 0.3, "cash": 1.3},
	{"name": "Resistant", "words": "All res 25%, rarer loot", "res": "all", "res_add": 0.25, "rarity": 0.5, "min_depth": 8},
]
## Depth - the ladder on each tier. Each step compounds: hostiles +25% HP and
## fire, rewards +12%, drops +3 points, rarer finds - so every tier has a depth
## the loadout can hold and a deeper one it can't. Clearing a depth opens the next.
const DEPTH_HOSTILE := 0.25       # hostile HP and dps compound by this a depth
const DEPTH_REWARD := 0.12        # XP and cash compound by this a depth - slower, so each tier has a natural depth
const DEPTH_DROP := 0.03
const ARMOUR_K := 150.0           # mitigation = armour / (armour + ARMOUR_K)
const CLEAR_BONUS := 0.3          # the clear bonus: this many kills' worth of XP per hostile in the pool
const DEPTH_RARITY := 0.10

## The operator. Level n: +HP_PER_LEVEL max HP and +DMG_PER_LEVEL damage a level.
const BASE_HP := 100.0
const HP_PER_LEVEL := 6.0
const DMG_PER_LEVEL := 0.02
const UNARMED_DPS := 3.0          # fists; a mission with no gun is a bad idea
const REST_HP_PER_S := 0.5        # the Medic Tent, for free, slowly
const TREAT_CASH_PER_HP := 2.0    # or paid for, at once
## Wounds (30): a hit that takes the runner under WOUND_AT of max HP leaves a
## wound, one of WOUND_STATS cut by WOUND_PCT until the clinic treats it for
## WOUND_CASH a level. One at a time; a second replaces it.
const WOUND_AT := 0.25
const WOUND_PCT := 10
const WOUND_STATS := ["pace", "armour", "hp"]
const WOUND_CASH := 20
const STASH_CAP := 40
const MARKET_STOCK := 3           # items for sale, re-rolled after every mission
const MARKET_MARKUP := 3.0        # buying is dearer than selling
const STARTING_CASH := 150
## Money that goes off. The fence's prices rise with the yard's hours - every
## cash price and every cash the gangs carry - so cash held loses, cash earned
## keeps pace, and the notes (the crews' own prices) don't move. A grace hour
## for the first run; linear after it; a ceiling where the new normal settles.
const INFLATION_GRACE_H := 1.0
const INFLATION_RATE := 0.07        # a hour, of the opening price
const INFLATION_CAP := 12.0
## The estate recycles. Nothing on it is new; it's all off someone. A dead
## runner's worn kit, and a unique sold to the fence, go on the list, and a
## few runs later one of a gang is wearing it; it comes off him when the
## site's cleared. RECYCLE_RUNS runs before it can turn up, RECYCLE_ODDS a
## run after that; the list holds RECYCLE_KEEP pieces, the oldest first.
const RECYCLE_RUNS := 3
const RECYCLE_ODDS := 0.3
const RECYCLE_KEEP := 12
## The places changing. A cleared site is picked over for a while: its drops
## and cash thin and come back over RECOVER_H yard hours. The clock: the yard
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
const WEATHER_ODDS := [[0.35, 0.15], [0.25, 0.2], [0.2, 0.25]]   # by zone: rain, fog
## Stacks. Rounds of a base merge into one stack, up to STACK_BOXES boxes'
## worth; socketables (no affixes, a bottle is a bottle) merge by count, up
## to SOCKET_STACK. A stack is one cell whatever it holds; taking rounds to
## the rig tops up the rig's stack first and splits what's left.
const STACK_BOXES := 5
const SOCKET_STACK := 10

## XP a level: Melvor's curve, like Clade.
const MAX_LEVEL := 50
const MAX_TIER := 6               # gear tiers: the town drops to 5, the city 6
static var _xp_table: Array = []


static func xp_for_level(level: int) -> float:
	if _xp_table.is_empty():
		var total := 0.0
		_xp_table.append(0.0)
		for l in range(1, MAX_LEVEL):
			total += floorf((l + 300.0 * pow(2.0, l / 7.0)) / 4.0)
			_xp_table.append(total)
	return _xp_table[clampi(level, 1, MAX_LEVEL) - 1]


static func level_for_xp(xp: float) -> int:
	var l := 1
	while l < MAX_LEVEL and xp >= xp_for_level(l + 1):
		l += 1
	return l
