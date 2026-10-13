## The trees' node glyphs (9 Oct, Tree-G A on the canvas; Matt: the Training screen "is displaying boxes of text
## rather than small boxes with a glyph - the text comes from the description box once you click a node"). A
## line drawing a kind of effect, white on transparent, drawn by the engine from SVG and tinted by the tile;
## a node's own words stay in the panel at the foot.

const Data := preload("res://scripts/sim/data.gd")

const SIZE := 64
const SVG := {
	"up": '<path d="M12 20 V5 M6 11 L12 5 L18 11"/>',     # XP, the map's Wages (10 Oct)
	# the Stats sheet's rows and trophies (10 Oct, Stats-R A)
	"pack": '<path d="M7 7 V5 a5 3 0 0 1 10 0 V7 M5 8 H19 V20 H5 Z M9 13 H15"/>',
	"runs": '<path d="M4 12 H17 M13 7 L18 12 L13 17 M20 5 V19"/>',
	"depth": '<path d="M12 4 V18 M7 13 L12 18 L17 13 M4 21 H20"/>',
	"skull": '<path d="M6 16 V11 a6 6 0 0 1 12 0 V16 H15 V19 H9 V16 Z M9.5 12 V12.5 M14.5 12 V12.5"/>',
	"gem": '<path d="M6 4 H18 L22 9 L12 21 L2 9 Z M2 9 H22"/>',
	"where": '<path d="M12 21 C8 16 5 13 5 9.5 a7 7 0 0 1 14 0 C19 13 16 16 12 21 Z"/><circle cx="12" cy="9.5" r="2"/>',
	# the purse on the top bar (10 Oct, Bar-C)
	"scrap": '<path d="M12 8 a4 4 0 1 0 0.01 0 Z M12 2 V5 M12 19 V22 M2 12 H5 M19 12 H22 M4.9 4.9 L7 7 M17 17 L19.1 19.1 M4.9 19.1 L7 17 M17 7 L19.1 4.9"/>',
	"copper": '<path d="M5 7 C5 4 19 4 19 7 C19 10 5 10 5 13 C5 16 19 16 19 13 M5 13 C5 18 19 18 19 20"/>',
	"steel": '<path d="M3 15 L7 9 H17 L21 15 Z M3 15 V19 H21 V15"/>',
	"army": '<rect x="3" y="7" width="18" height="12" rx="1"/><path d="M12 9.5 L13 12 H15.5 L13.5 13.6 L14.3 16 L12 14.5 L9.7 16 L10.5 13.6 L8.5 12 H11 Z"/>',
	"person": '<circle cx="12" cy="8" r="4"/><path d="M4 21 C4 15.5 8 13 12 13 C16 13 20 15.5 20 21"/>',     # a face we have no art for (10 Oct, the run's boxes)
	"dmg": '<path d="M5 19 L15 9 M13 7 L17 11 M15 5 L19 9 M17 3 L21 7 M4 20 L6 18"/>',
	"armour": '<path d="M12 3 L19 6 V11 C19 16 16 19 12 21 C8 19 5 16 5 11 V6 Z"/>',
	"hp": '<path d="M12 20 L5 13 a4 4 0 0 1 7 -6 a4 4 0 0 1 7 6 Z"/>',
	"med": '<rect x="4" y="4" width="16" height="16" rx="3"/><path d="M12 8 V16 M8 12 H16"/>',
	"bleed": '<path d="M12 3 C9 8 7 11 7 14 a5 5 0 0 0 10 0 C17 11 15 8 12 3 Z"/>',
	"fire": '<path d="M12 21 a6 6 0 0 1 -6 -6 C6 10 10 8 10 3 C14 6 18 10 18 15 a6 6 0 0 1 -6 6 Z M12 21 a2.5 2.5 0 0 1 -2.5 -2.5 C9.5 16 12 15 12 13 C14 15 14.5 16.5 14.5 18.5 a2.5 2.5 0 0 1 -2.5 2.5"/>',
	"frost": '<path d="M12 2 V22 M3.3 7 L20.7 17 M3.3 17 L20.7 7 M9 4 L12 6 L15 4 M9 20 L12 18 L15 20"/>',
	"poison": '<circle cx="12" cy="10" r="6"/><path d="M9 9 V9.5 M15 9 V9.5 M10 13 H14 M9 16 V21 M15 16 V21 M12 16 V21"/>',
	"shock": '<path d="M13 2 L5 13 H11 L10 22 L19 10 H13 Z"/>',
	"phys": '<path d="M7 11 V7 a1.5 1.5 0 0 1 3 0 V11 M10 10 V6 a1.5 1.5 0 0 1 3 0 V10 M13 10 V7 a1.5 1.5 0 0 1 3 0 V11 M16 11 V9 a1.5 1.5 0 0 1 3 0 V14 C19 18 16 21 12 21 C8 21 6 18 6 15 V12 a1.5 1.5 0 0 1 3 0"/>',
	"dot": '<circle cx="9" cy="9" r="3"/><circle cx="16" cy="15" r="3"/><circle cx="8" cy="17" r="1.5"/><circle cx="17" cy="7" r="1.5"/>',
	"quality": '<path d="M12 3 L14.5 9 L21 9.5 L16 13.8 L17.5 20 L12 16.8 L6.5 20 L8 13.8 L3 9.5 L9.5 9 Z"/>',
	"quantity": '<path d="M7 9 L5 20 H19 L17 9 Z M9 9 V7 a3 3 0 0 1 6 0 V9"/>',
	"search": '<circle cx="10" cy="10" r="6"/><path d="M15 15 L21 21"/>',
	"lock": '<path d="M6 11 H18 V21 H6 Z M8.5 11 V7.5 a3.5 3.5 0 0 1 7 0 V11 M12 15 V17"/>',     # a locked crate (13 Oct)
	"crate": '<path d="M3 9 H21 V20 H3 Z M3 9 L5 5 H19 L21 9 M9 13 H15"/>',     # a crate until its art is painted (13 Oct)
	"pace": '<path d="M5 18 L11 12 L5 6 M13 18 L19 12 L13 6"/>',
	"first": '<circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2"/><path d="M12 2 V6 M12 18 V22 M2 12 H6 M18 12 H22"/>',
	"clock": '<circle cx="12" cy="12" r="8"/><path d="M12 7 V12 L15.5 14"/>',
	"cash": '<rect x="2" y="7" width="20" height="11" rx="1.5"/><circle cx="12" cy="12.5" r="2.5"/>',
	"wrench": '<path d="M14 4 a5 5 0 0 0 -5 6 L4 15 L6 20 L11 15 a5 5 0 0 0 6 -5 L15 8 L18 5 Z"/>',
	"three": '<circle cx="7" cy="9" r="2.5"/><circle cx="17" cy="9" r="2.5"/><circle cx="12" cy="7" r="2.5"/><path d="M3 19 a4 4 0 0 1 8 0 M13 19 a4 4 0 0 1 8 0 M8 17 a4 4 0 0 1 8 0"/>',
	"half": '<circle cx="12" cy="12" r="8"/><path d="M12 4 V20"/><path d="M12 6 a6 6 0 0 0 0 12 Z" fill="#ffffff"/>',
	"loud": '<path d="M4 10 V14 H8 L13 18 V6 L8 10 Z M16 9 a4 4 0 0 1 0 6 M18.5 7 a7 7 0 0 1 0 10"/>',
	"forever": '<path d="M6 9 a3 3 0 1 0 0 6 C9 15 15 9 18 9 a3 3 0 1 1 0 6 C15 15 9 9 6 9 Z"/>',
	"spread": '<circle cx="6" cy="12" r="2.5"/><circle cx="18" cy="6" r="2.5"/><circle cx="18" cy="18" r="2.5"/><path d="M8.5 11 L15.5 7 M8.5 13 L15.5 17"/>',
	"stand": '<path d="M6 21 V4 H18 V21 M4 21 H20 M14 13 V13.5"/>',
	"pen": '<path d="M4 20 L20 4 M14 4 H20 V10"/>',
	"quiet": '<path d="M20 14 A8 8 0 1 1 10 4 a6 6 0 0 0 10 10 Z"/>',
	"dog": '<path d="M5 10 L7 5 L10 9 H14 L17 5 L19 10 V15 a5 5 0 0 1 -5 5 H10 a5 5 0 0 1 -5 -5 Z M10 13 V13.5 M14 13 V13.5"/>',
	"dice": '<rect x="4" y="4" width="16" height="16" rx="3"/><path d="M8.5 8.5 V9 M15.5 15.5 V16 M12 12 V12.5 M15.5 8.5 V9 M8.5 15.5 V16"/>',
	"star": '<path d="M12 4 L13.8 10.2 L20 12 L13.8 13.8 L12 20 L10.2 13.8 L4 12 L10.2 10.2 Z"/>',
}

## A plain effect's glyph.
const OF_EFFECT := {
	"damage_pct": "dmg", "damage_low_pct": "half", "hp": "hp", "armour_pct": "armour", "loot_pct": "quantity", "search_pct": "search",
	"first_pct": "first", "patrol_pct": "clock", "heal_pct": "med", "med_speed_pct": "med", "med_cap": "med", "rest_pct": "hp", "treat_pct": "med",
	"att_share": "wrench", "sell_pct": "cash", "cash_pct": "cash", "rarity": "quality", "pace_pct": "pace", "dot_pct": "dot", "phys_pen": "pen",
	"physical_pct": "phys", "physical_more": "phys", "bust_them_up": "phys", "cap_flattened": "phys", "melee_sweep": "phys",
	"bleed_forever": "forever", "fire_spread": "spread", "cap_spread": "spread", "cap_lingers": "spread", "cap_bleed_out": "spread", "shock_chain": "spread", "cap_arc": "spread",
	"frost_freeze": "frost", "cap_shatter": "frost", "poison_stacks": "poison",
	"bodyline": "three", "one_at_a_time": "three", "cap_iron": "half", "cap_held": "stand", "stand": "stand", "loud": "loud", "cap_dogs_share": "dog",
	"second_wind": "hp", "walk_it_off": "hp", "not_today": "hp", "walking_wounded": "hp", "field_surgery": "med", "triage": "med", "cap_transfusion": "med", "cap_clean_hands": "med",
	"pack_mule": "quantity", "hoarder": "quantity", "scavenger": "quantity", "light_fingers": "quantity", "nothing_wasted": "quantity", "cap_the_lot": "quantity",
	"cap_loaded_dice": "dice", "all_or_nothing": "dice", "buyers_market": "cash",
	"never_there": "quiet", "quiet_feet": "quiet", "quiet_hands": "quiet", "cap_ghost": "quiet", "cap_dead_quiet": "quiet", "night_work": "quiet",
	"double_tap": "first", "one_shot": "first", "overwatch": "first", "cap_poached": "first", "early_doors": "first",
	"hit_and_run": "pace", "trapline": "clock", "second_shift": "clock", "cap_jerry": "wrench",
	# beside the capstone (12 Oct): over the cap's by element, Guard's as armour
	"proof_fire": "fire", "proof_frost": "frost", "proof_poison": "poison", "proof_shock": "shock", "proof_bleed": "bleed", "thick_skinned": "armour",
	"overtime": "med", "squared_up": "armour", "in_the_hide": "armour", "sheet_metal": "armour", "breather": "armour",
}


## A node's glyph: its effect's; an element's figure (a conversion, "+% fire", "fire_more") its element's; else a star.
static func of(nd: Dictionary) -> String:
	var e: String = str(nd.get("effect", ""))
	if OF_EFFECT.has(e):
		return OF_EFFECT[e]
	for el in ["fire", "frost", "poison", "shock", "bleed"]:
		if e == "conv_%s_pct" % el or e == "%s_pct" % el or e == "%s_more" % el:
			return el
	return "star"


## A Yard pick's glyph (10 Oct, Lanes-G): what its line is about, read from its words; else its building's.
const PICK_RULES := [
	["cells", "pack"], ["no room", "pack"], ["pouches", "pack"], ["moves keep", "pack"],
	["max hp", "hp"], ["hp/s", "hp"], ["rest +", "hp"], ["wound", "med"], ["meds", "med"], ["bandage", "med"],
	["quality", "quality"], ["find", "search"], ["search", "search"], ["best piece", "dog"], ["full pack", "dog"],
	["sales", "cash"], ["sells", "cash"], ["for sale", "cash"], ["in stock", "cash"], ["stock at", "cash"], ["gambles", "dice"],
	["insur", "armour"], ["contracts", "pen"], ["papers", "pen"], ["rewards", "cash"], ["notes", "pen"],
	["affix", "dice"], ["rolls", "dice"], ["socket", "wrench"], ["lock", "wrench"], ["bump", "wrench"], ["level", "wrench"],
	["job", "wrench"], ["crafts", "wrench"], ["scrap", "scrap"], ["steel", "steel"], ["guns at", "dmg"], ["first shot", "first"],
	["fire, shock", "fire"], ["poison, bleed", "poison"], ["gang", "clock"], ["head short", "three"], ["convoy", "depth"],
	["night", "quiet"], ["rain", "quiet"], ["weather", "quiet"], ["word", "loud"], ["away", "clock"], [" h away", "clock"],
	["odds", "dice"], ["auto", "runs"], ["runs start", "runs"],
]
## Each pick's own (the review, 10 Oct: the rules gave nine pairs one glyph for both sides); the rules are the fallback.
const PICK_GLYPH := {
	"steady_hands": "dice", "cheap_parts": "cash", "third_socket": "wrench", "two_locks": "dice", "gunsmith": "dmg", "strip_for_parts": "scrap",
	"overbump": "wrench", "fine_tuning": "quality", "masterwork": "star", "salvage_line": "steel",
	"shelving": "pack", "racks": "first", "another_unit": "pack", "bins": "scrap", "strongroom": "armour", "wall_of_fame": "gem",
	"lock_up": "pack", "paper_rack": "pen", "dry_store": "forever", "annex": "pack",
	"beds": "hp", "shelf": "med", "ward": "hp", "stockroom": "med", "surgery": "cash", "physio": "med", "drip": "hp", "field_kit": "med",
	"theatre": "hp", "med_lab": "med",
	"stall": "quantity", "haggling": "cash", "shopfront": "quantity", "orders": "pen", "back_room": "gem", "fixer": "pen",
	"gamblers_table": "dice", "insurance_desk": "armour", "arms_dealer": "dmg", "dealers_cut": "cash",
	"weather_set": "half", "night_set": "quiet", "forecast": "cash", "dead_air": "clock", "scanner": "wrench", "two_channels": "dice",
	"lorry_watch": "depth", "long_range": "loud", "jammer": "half", "military_band": "cash",
	"twelve_hours": "clock", "rig_wiring": "pack", "a_day": "clock", "floodlights": "quiet", "battery": "pack", "overtime": "cash",
	"two_days": "clock", "arc_lamps": "fire", "grid": "clock", "charger": "hp",
	"spotter": "clock", "glasses": "dice", "lookout_post": "clock", "range_cards": "first", "hold_fire": "pack", "tripwires": "clock",
	"whistle": "runs", "watch_rota": "clock", "crows_nest": "clock", "flares": "three",
	"a_dog": "search", "good_nose": "quality", "guard_dog": "clock", "pedigree": "quality", "fetch": "dog", "second_dog": "search",
	"tracker": "pen", "ratter": "poison", "pack": "search", "champion": "quality",
}
## The map's nodes (10 Oct, Lanes-G): each its own.
const ATLAS_GLYPH := {
	"picked_over": "gem", "deeper_pockets": "search", "quiet_roads": "clock", "after_dark": "quiet", "second_look": "quantity", "worn_in": "forever",
	"easy_pickings": "quantity", "local_knowledge": "depth", "short_cuts": "pace", "open_ground": "half", "every_penny": "cash", "lie_of_the_land": "where",
	"paid_in_notes": "pen", "two_of_everything": "half", "heads_up": "first", "full_strength": "skull", "bounties": "cash", "wages": "up",
	"heavy_crews": "three", "their_own_kit": "dmg", "marked_men": "first", "long_memory": "forever", "head_start": "runs", "lorrys_route": "depth",
	"good_reception": "loud", "clear_air": "quiet", "booster": "loud", "held_frequency": "forever", "long_wave": "spread", "tip_offs": "quality",
	"strong_signal": "shock", "early_word": "clock", "relay": "spread", "bent": "dice", "whole_band": "stand",
}


static func of_atlas(key: String) -> String:
	return ATLAS_GLYPH.get(key, "star")


const BUILDING_GLYPH := {"bench": "wrench", "stash": "pack", "clinic": "med", "fence": "cash", "radio": "loud", "generator": "shock", "lookout": "search", "kennel": "dog"}


static func of_pick(pick: Dictionary, building: String) -> String:
	if PICK_GLYPH.has(str(pick.get("id", ""))):
		return PICK_GLYPH[str(pick["id"])]
	var said: String = (str(pick.get("short", "")) + " " + str(pick.get("words", ""))).to_lower()
	for rule in PICK_RULES:
		if said.contains(rule[0]):
			return rule[1]
	return BUILDING_GLYPH.get(building, "star")


static var _cache := {}
## The glyph as a white texture, drawn once.
static func texture(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var body: String = SVG.get(key, SVG["star"])
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">%s</svg>' % [SIZE, SIZE, body]
	var img := Image.new()
	var tex: Texture2D = null
	if img.load_svg_from_string(svg, 1.0) == OK:
		img.generate_mipmaps()
		tex = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex
