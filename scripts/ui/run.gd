extends Control
## The run, live: what the cards showed, as a screen, so the pack can be the
## real grid. Left, three panels - Them (the fight, or the picking-over),
## the Runner (HP, a med), and the run itself (the clock, the cash, Get out).
## Right, the pack as cells, the same grid as the Lock-up: pick an item for
## its figures and Ditch it, or Select many and ditch the lot. Under the grid
## a panel for the pick, and what a full pack will do with the next find.
## Fixed geometry inside the card grid's 1536 x 864.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const Inventory := preload("res://scripts/ui/inventory.gd")
const People := preload("res://scripts/ui/people.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")
const PickPanel := preload("res://scripts/ui/pick_panel.gd")
const Band := preload("res://scripts/ui/band.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")
const CratesPanel := preload("res://scripts/ui/crates_panel.gd")

const BODY_W := Inventory.SIDE_W                              # 608
const GAP := 24
const GRID_X := BODY_W + GAP
const GRID_W := Inventory.WIDTH                                # 904
const GRID_H := Inventory.HEIGHT                               # 588
const PICK_Y := GRID_H + GAP                                  # 612
const PICK_H := Pal.ROOM_H - PICK_Y                           # 304
const BAND_H := 200                                           # the site's art band at the top of the column
const RIG_MAX := Data.RIG_CAP                                 # the rig never shows past the sim's cap (24)
const PAD := 20
const INNER := BODY_W - 2 * PAD
const LINE_H := 30                                            # a 24 px font is 29 tall
const BAR_H := 24
const SECTION_GAP := 12
# the left column, top to bottom: the band, the fight in its box, the runner in its box, the rig, the take, the buttons
const BOX_PAD := 10                                           # the outline round them and round you
const FIGHT_BOX_Y := BAND_H + 14
const FIGHT_Y := FIGHT_BOX_Y + BOX_PAD
const FIGHT_TILES_Y := FIGHT_Y + UI.HEAD_H + 16                 # room over the tiles for the crew head's face
const FIGHT_BAR_Y := FIGHT_TILES_Y + UI.TILE_H + 6
const FIGHT_THEM_Y := FIGHT_BAR_Y + BAR_H + 8                   # "On them": what your fire has left on them, as chips
const KEY_W := 88                                              # the "On them" / "On you" key before the chips
# the faces (10 Oct, Run-P A; Matt: the head's art sat over the fight box): 92 px at each box's left, the tiles and
# the bar narrowed to its right, neither box any taller
const FACE := 92                                              # fits the runner's box between its head and its note (the review)
const BOXED_X := PAD + FACE + 10
const BOXED_W := INNER - FACE - 10
const FIGHT_BOX_H := FIGHT_THEM_Y + Chips.CHIP_H + BOX_PAD - FIGHT_BOX_Y
const RUNNER_BOX_Y := FIGHT_BOX_Y + FIGHT_BOX_H + SECTION_GAP
const RUNNER_Y := RUNNER_BOX_Y + BOX_PAD
const RUNNER_BAR_Y := RUNNER_Y + UI.HEAD_H + 2
const RUNNER_TILES_Y := RUNNER_BAR_Y + BAR_H + 6
const RUNNER_NOTE_Y := RUNNER_TILES_Y + UI.TILE_H + 2
const RUNNER_BOX_H := RUNNER_NOTE_Y + LINE_H + BOX_PAD - RUNNER_BOX_Y
const RIG_HEAD_Y := RUNNER_BOX_Y + RUNNER_BOX_H + SECTION_GAP
const RIG_Y := RIG_HEAD_Y + UI.HEAD_H + 4                     # the pouches' row
const TAKE_Y := RIG_Y + Pal.CELL + SECTION_GAP
const TAKE_TILES_Y := TAKE_Y + UI.HEAD_H + 2
const NOTE_Y := TAKE_TILES_Y + UI.TILE_H + 10                 # the run's own line, above the buttons
const BUTTON_Y := Pal.ROOM_H - PAD - Pal.BUTTON_H

var sim
var _left: Panel                   # the column: the band and the sections
var _band: Band
var _clock_track: Panel
var _clock_fill: Panel
var _fight := {}                   # {box, head, tiles[4], track, fill, bar_text, key, chips}
var _runner := {}                  # {head, track, fill, bar_text, tiles[4], note, key, chips}
var _rig_head: Label
var _take_head: Label
var _take_tiles: Array = []
var _note: Label                   # the run's own line: leaving keeps the loot, HP low, filling up
var _button: Button                # Get out now
var _button2: Button               # Stop auto, or Fill up then go
var _inv
var _pick                          # the pick panel (pick_panel.gd): the pick against the fitted, the buttons
var _shown := ""
var _fight_face := {}              # {frame, art, blank}: the crew's head while he's out, else the zone's gang (Matt's Greenhorn faces), else a drawn one
var _runner_face := {}             # the runner's class
var _rig_cells: Array = []         # ItemCells, one a pouch, in the Runner panel
var _rig_pick := -1                # a stack of rounds picked in the rig (11 Oct): shown in the pick panel, Into the pack
var _rig_outlines: Array = []
var juice = null                   # the shell's, for numbers and flashes; null in a bare test
var _dealt_seen := 0.0             # what the numbers have shown so far this run
var _dealt_seen_by := {}           # and by type, for the coloured numbers
var _taken_seen_by := {}
var _number_at := -1.0             # the run's clock when the last number came off
var _taken_seen := 0.0             # what the red numbers have shown so far this run
var _guarded_seen := 0.0           # what Guard's numbers have shown (12 Oct): its share in its own colour, not red
var _healed_seen := 0.0            # and the green
var _hp_at := -1.0
var _found_seen: Array = []        # the finds the flashes have seen
var _crates                        # the crates (crates_panel.gd): under the pack once the site's cleared, in the pick panel's place
var view_crates := false           # the toggle (13 Oct, Matt): the search bar shows the crates, the crates' bar the pick again; one bar at a time
var _crates_for = null             # the run's crates the view last opened on: a new search opens on the crates
var _search_button: Button         # over the fight box's bar while it's the search's


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_left = UI.panel(self, Rect2(0, 0, BODY_W, Pal.ROOM_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_band = Band.new(BODY_W, BAND_H)
	_left.add_child(_band)
	# the run's clock (9 Oct, Clock-A): a thin bar under the kills, draining as it runs
	_clock_track = UI.panel(_band, Rect2(PAD, BAND_H - 11, BODY_W - 2 * PAD, 6), UI.box(Color(Pal.BG, 0.85), 3))
	_clock_fill = UI.panel(_clock_track, Rect2(0, 0, BODY_W - 2 * PAD, 6), UI.box(Pal.ACCENT, 3))
	# the fight and the runner each in an outlined box, so them and you read apart
	_fight["box"] = UI.panel(_left, Rect2(PAD - BOX_PAD, FIGHT_BOX_Y, INNER + 2 * BOX_PAD, FIGHT_BOX_H), UI.box(Color.TRANSPARENT, 8, 1, Pal.CARD_LINE))
	_runner["box"] = UI.panel(_left, Rect2(PAD - BOX_PAD, RUNNER_BOX_Y, INNER + 2 * BOX_PAD, RUNNER_BOX_H), UI.box(Color.TRANSPARENT, 8, 1, Pal.CARD_LINE))
	# the fight: a head, four tiles, their HP as the bar (or the search's)
	_fight["head"] = UI.head(_left, Rect2(PAD, FIGHT_Y, INNER, UI.HEAD_H), "The fight")
	_fight_face = _face_make(Vector2(PAD, FIGHT_TILES_Y - 2))
	_fight["tiles"] = UI.tile_row(_left, BOXED_X, FIGHT_TILES_Y, BOXED_W, 4)
	_bar_make(_fight, FIGHT_BAR_Y, BOXED_X, BOXED_W)
	_fight["key"] = UI.label(_left, Rect2(PAD, FIGHT_THEM_Y, KEY_W - 8, Chips.CHIP_H), "On them", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT)
	_fight["chips"] = Chips.new(INNER - KEY_W)
	_fight["chips"].position = Vector2(PAD + KEY_W, FIGHT_THEM_Y)
	_left.add_child(_fight["chips"])
	# the runner: the head, your HP as the bar, four tiles, a note
	_runner["head"] = UI.head(_left, Rect2(PAD, RUNNER_Y, INNER, UI.HEAD_H), "The runner")
	_runner_face = _face_make(Vector2(PAD, RUNNER_Y + UI.HEAD_H + 1))
	_bar_make(_runner, RUNNER_BAR_Y, BOXED_X, BOXED_W)
	_runner["tiles"] = UI.tile_row(_left, BOXED_X, RUNNER_TILES_Y, BOXED_W, 4)
	_runner["note"] = UI.label(_left, Rect2(PAD, RUNNER_NOTE_Y, INNER, LINE_H), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	# "On you": what their fire has left on you, as chips in the elements' tones, with the med in use as a muted one
	_runner["key"] = UI.label(_left, Rect2(PAD, RUNNER_NOTE_Y + 2, KEY_W - 8, Chips.CHIP_H), "On you", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT)
	_runner["chips"] = Chips.new(INNER - KEY_W)
	_runner["chips"].position = Vector2(PAD + KEY_W, RUNNER_NOTE_Y + 2)
	_left.add_child(_runner["chips"])
	# the rig's pouches: what's carried, a cell a pouch; a med's cell uses that med
	_rig_head = UI.head(_left, Rect2(PAD, RIG_HEAD_Y, INNER, UI.HEAD_H), "The rig · use an item in the rig")
	for k in range(RIG_MAX):
		var o := UI.panel(_left, Rect2(PAD, RIG_Y, Pal.CELL, Pal.CELL), UI.box(Color.TRANSPARENT, 6, 1, Pal.CARD_LINE))
		o.visible = false
		o.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rig_outlines.append(o)
		var c := ItemCell.new()
		c.position = Vector2(PAD, RIG_Y)
		c.visible = false
		c.pressed.connect(_rig_pressed.bind(k))
		_left.add_child(c)
		_rig_cells.append(c)
	# the take: cash, what was passed over or swapped, the pack
	_take_head = UI.head(_left, Rect2(PAD, TAKE_Y, INNER, UI.HEAD_H), "The take")
	_take_tiles = UI.tile_row(_left, PAD, TAKE_TILES_Y, INNER, 4)
	_note = UI.label(_left, Rect2(PAD, NOTE_Y, INNER, LINE_H), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_button = UI.button(_left, Rect2(PAD, BUTTON_Y, INNER, Pal.BUTTON_H), true)
	_button.pressed.connect(_get_out)
	_button2 = UI.button(_left, Rect2(PAD, BUTTON_Y, INNER, Pal.BUTTON_H), false)
	_button2.visible = false
	_button2.pressed.connect(_second_button)
	_inv = Inventory.new()
	_inv.position = Vector2(GRID_X, 0)
	_inv.ditching = true
	_inv.picked.connect(_on_inv_pick)
	_inv.acted.connect(_on_inv_acted)
	add_child(_inv)
	_search_button = _bar_button(_fight["track"])
	_search_button.tooltip_text = "Show the crates"
	_search_button.pressed.connect(_toggle_crates)
	_crates = CratesPanel.new()
	_crates.build(GRID_W, PICK_H)
	_crates.toggled.connect(_toggle_crates)
	_crates.position = Vector2(GRID_X, PICK_Y)
	_crates.visible = false
	add_child(_crates)
	_pick = PickPanel.new(GRID_W, PICK_H)
	_pick.position = Vector2(GRID_X, PICK_Y)
	_pick.acted.connect(_on_pick_acted)
	add_child(_pick)


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	if not sim.on_mission():
		return
	var m: Dictionary = sim.mission
	var t: Dictionary = m["t"]
	if _inv.selected >= 0 or _rig_picked().is_empty():
		_rig_pick = -1                    # a pack cell picked, or the stack gone: the rig's pick goes
	var low: bool = sim.hp / sim.max_hp() <= 0.35
	var tier_i: int = int(m["tier"])
	# the band: the site, the clock as the headline, the fight's progress as the bar
	var zone_i := 0
	for z in range(Data.ZONES.size()):
		if tier_i in Data.ZONES[z]["tiers"]:
			zone_i = z
	_band.set_site(t["name"])
	_band.set_tone(zone_i)
	# the headline is the clock (9 Oct, Clock-A): counting down while a gang is on you, standing while it's clear
	var clock: float = maxf(0.0, float(m.get("clock", 0.0)))
	var clock_max: float = maxf(1.0, float(m.get("clock_max", clock)))
	var ticking: bool = int(m["remaining"]) > 0
	var clock_colour: Color = Pal.BAD if clock <= 10.0 else (Pal.ACCENT if clock <= clock_max * Data.CLOCK_WARN else Pal.TEXT)
	var clock_unit: Array = ["left · ticks while they're on you", "left · ticking", "left"] if ticking else ["left · stopped while it's clear", "left · stopped", "left"]
	var way_out: bool = m.get("way_out", false)
	if way_out:
		# the way out (10 Oct, Run-P B): the headline is the extract counting down, in amber
		_band.set_words("Depth %d · %s · the way out" % [t["depth"], Data.ZONES[zone_i]["name"]], t["name"], Fmt.mss(ceilf(maxf(0.0, float(m["way_out_t"])))),
			["to the way out · see them off", "see them off", "left"], Pal.BAD if float(m["way_out_t"]) <= 5.0 else Pal.ACCENT)
	else:
		_band.set_words("Depth %d · %s" % [t["depth"], Data.ZONES[zone_i]["name"]], t["name"], Fmt.mss(ceilf(clock)), clock_unit, clock_colour)
	_clock_fill.size.x = _clock_track.size.x * clampf(clock / clock_max, 0.0, 1.0)
	(_clock_fill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = clock_colour if clock_colour != Pal.TEXT else Pal.TEXT_2
	_band.headline_under_title(true)
	# the capstones in play on this run, by name, as the band's third line
	var caps := []
	for b in sim.trees():
		if b == null or b.get("drawer", false):
			continue
		for k in range(b["nodes"].size()):
			if b["nodes"][k].get("capstone", false) and sim.tree.has("%s/%d" % [b["name"], k]):
				caps.append(b["nodes"][k]["name"])
	var cap_line: String = ("◆◆ " + ", ".join(caps)) if not caps.is_empty() else ""
	if cap_line != "" and UI.text_width(_band.right[2], cap_line) > _band.RIGHT_W:
		cap_line = "◆◆ %d capstones" % caps.size()
	# the pool as it stands: the site's, and whatever came after - a convoy's crew counts (8 Oct, Matt: "11 of 10
	# down ... level doesn't count as complete"; the convoy event had put four on the pool and the bar read the site's)
	var convoy_in: bool = str(m.get("event_done", "")) == "convoy"
	var gangs: String = "%d gang%s so far" % [m["patrols"], "" if m["patrols"] == 1 else "s"]
	if convoy_in:
		gangs = ("convoy, %d gang%s" % [m["patrols"], "" if m["patrols"] == 1 else "s"]) if m["patrols"] > 0 else "a convoy's crew in"     # "a convoy and 2 gangs so far" was 20 px past the column
	_band.set_right(["%s in · clock %s" % [Fmt.mss(m["elapsed"]), Fmt.mss(ceilf(clock_max))], gangs, cap_line])
	var of: int = maxi(1, int(m["kills"]) + int(m["remaining"])) if not m["cleared"] else int(t["pool"])
	if m.get("way_out", false):
		var door: int = maxi(1, int(m.get("way_out_gang", 1)))
		_band.set_bar(float(door - int(m["remaining"])) / float(door), "%d of %d at the door seen off" % [door - int(m["remaining"]), door])
	else:
		_band.set_bar((float(m["kills"]) / float(of)) if not m["cleared"] else 1.0, ("Cleared" if m["cleared"] else "%d of %d down" % [m["kills"], of]))
	# them
	var boss_on: bool = m.has("boss") and m["boss"]["started"] and m["boss"]["alive"]
	_face_show(_fight_face, [m["boss"]["name"] if boss_on else "", gang_face(zone_i)])
	_face_show(_runner_face, [sim.cls])
	if boss_on:
		_fight["head"].text = "THE FIGHT · " + m["boss"]["name"].to_upper()
		_tiles(_fight["tiles"], [["On you", ["the crew's head", "1"]], ["Incoming", ["%.1f/s" % m["last_incoming"]]], ["Your fire", ["%.0f/s" % (sim.dps() * sim.pace())]], ["Kills", ["%d" % m["kills"]]]])
		_bar(_fight, clampf(m["target_hp"] / float(m["boss"]["hp"]), 0.0, 1.0), "Their HP %d / %d" % [ceili(m["target_hp"]), int(m["boss"]["hp"])], "bad", m.get("dots", {}), float(m["boss"]["hp"]))
	elif way_out:
		var door_on: int = mini(m["remaining"], sim.contact(t))
		_fight["head"].text = "THE FIGHT · THE WAY OUT"
		_tiles(_fight["tiles"], [["On you", ["%d" % door_on]], ["Incoming", ["%.1f/s" % m["last_incoming"]]], ["Your fire", ["%.0f/s" % (sim.dps() * sim.pace())]],
			["Door", ["%d of %d" % [m["remaining"], int(m.get("way_out_gang", m["remaining"]))], "%d" % m["remaining"]]]])
		_bar(_fight, clampf(m["target_hp"] / t["hp"], 0.0, 1.0), "Their HP %d / %d" % [ceili(m["target_hp"]), int(t["hp"])], "bad", m.get("dots", {}), float(t["hp"]))
	elif m["remaining"] > 0:
		var on_you: int = mini(m["remaining"], sim.contact(t))
		_fight["head"].text = ("GANG %d" % m["patrols"]) if m["cleared"] else ("THE FIGHT; THEN %s" % m["boss"]["name"].to_upper() if m.has("boss") and m["boss"]["alive"] else "THE FIGHT")
		_tiles(_fight["tiles"], [["On you", [("%d · %d more" % [on_you, m["remaining"] - on_you]) if m["remaining"] > on_you else "%d" % on_you, "%d" % on_you]],
			["Incoming", ["%.1f/s" % m["last_incoming"]]], ["Your fire", ["%.0f/s" % (sim.dps() * sim.pace())]], ["Kills", ["%d" % m["kills"]]]])
		_bar(_fight, clampf(m["target_hp"] / t["hp"], 0.0, 1.0), "Their HP %d / %d" % [ceili(m["target_hp"]), int(t["hp"])], "bad", m.get("dots", {}), float(t["hp"]))
	else:
		_fight["head"].text = "PICKING IT OVER · EVERY GANG THE SIZE OF THE FIRST" if sim.has_node("cap_dead_quiet") else "PICKING IT OVER · EACH GANG BIGGER THAN THE LAST"
		var next: float = sim.patrol_s(t, m["patrols"] == 0) - m["patrol_timer"]
		_tiles(_fight["tiles"], [["Next gang", (["on the call", "held"] if sim.gang_held(m) else [(Fmt.mss(next) if next < 1e8 else "never")])], ["Gangs", ["%d" % m["patrols"]]], ["Kills", ["%d" % m["kills"]]], ["Found", ["%d" % m["found"].size()]]])
		# the crates (13 Oct): the one in hand, or picked clean
		var cr: Dictionary = sim.crate_now(m)
		var search_words: String = "Searching" if not m.has("crates") else ("Picked clean: every crate open" if cr.is_empty() else
			"Crate %d of %d · %s" % [int(m.get("crate_i", 0)) + 1, m["crates"].size(), str(cr["name"]).to_lower()])
		_bar(_fight, 1.0 if sim.crates_done(m) else clampf(m["search"] / sim.search_s(t), 0.0, 1.0), search_words, "warn" if sim.crates_done(m) else "good")
		if m.has("crates") and UI.text_width(_fight["bar_text"], search_words + " · show the crates") <= _fight["w"] - 16:
			_fight["bar_text"].text = search_words + " · show the crates"     # the bar's a button (13 Oct): it says so
	# the runner, and their wound when they carry one (30)
	_runner["head"].text = ("THE RUNNER · " + sim.wound_words().to_upper()) if sim.wound != "" else "THE RUNNER"
	var g: float = sim.guard()
	var hp_words: String = ("Your HP %d / %d + %d" % [sim.hp_shown(), sim.max_hp_shown(), int(round(g))]) if g >= 0.5 else ("Your HP %d / %d" % [sim.hp_shown(), sim.max_hp_shown()])
	_bar(_runner, clampf(sim.hp / sim.max_hp(), 0.0, 1.0), hp_words, "bad" if low else "good", m.get("my_dots", {}), sim.max_hp(), g / maxf(1.0, sim.max_hp()))
	var gun = sim.equipped["Primary"]
	var rounds: int = sim.rounds_for(gun) if gun != null else 0
	_tiles(_runner["tiles"], [["Armour", ["%.0f (%s)" % [sim.armour(), Fmt.pct(sim.mitigation())], "%.0f" % sim.armour()]], ["Damage", ["%.0f/s" % (sim.dps() * sim.pace())]],
		["Meds", [("%d" % sim.meds_carried()) if sim.meds_carried() > 0 else "none"]], ["Rounds", [("%d" % rounds) if rounds > 0 else ("none needed" if gun != null and Items.ammo_type(gun) in ["", "none"] else ("dry" if gun != null else "no gun")), "—"]]])
	_runner["tiles"][3]["value"].add_theme_color_override("font_color", Pal.BAD if gun != null and rounds == 0 and not (Items.ammo_type(gun) in ["", "none"]) else Pal.TEXT)
	# on them: the chips under their bar; nothing while there's no one to be on
	var them: Array = sim.dots_on_them()
	_fight["key"].visible = not them.is_empty()
	_fight["chips"].visible = not them.is_empty()
	if not them.is_empty():
		_fight["chips"].show_chips(them)
	# on you: the line is the chips' alone (Matt, 6 Oct): what their fire has left on you, and the med in use as a muted one
	var on_you: Array = []
	for ty in ["fire", "poison", "bleed"]:
		if float(m.get("my_dots", {}).get(ty, 0.0)) > 0.5:
			on_you.append([{"fire": "Burning", "poison": "Poisoned", "bleed": "Bleeding"}[ty], ty])
	if m["using"] != null:
		on_you.append(["%s, %.0f s to go" % [m["using"]["name"], ceilf(m["using"]["left"])], "%s, %.0f s" % [m["using"]["name"], ceilf(m["using"]["left"])], Pal.TEXT_2])
	var med_sig: String = ("using" if m["using"] != null else ("none" if sim.first_med().is_empty() else "use:" + sim.first_med()["base"]))
	_runner["key"].visible = not on_you.is_empty()
	_runner["chips"].visible = not on_you.is_empty()
	_runner["note"].visible = false
	if not on_you.is_empty():
		_runner["chips"].show_chips(on_you)
	_show_rig()
	# the take
	_tiles(_take_tiles, [["Tins", Fmt.money_forms(m["cash"])], ["Passed over", ["%d" % m["left"]]], ["Swapped", ["%d" % int(m.get("swapped", 0))]], ["Pack", ["%d of %d" % [sim.pack_used(m), sim.capacity()], "%d/%d" % [sim.pack_used(m), sim.capacity()]]]])
	_note.text = "See them off in time: then out with the pack" if way_out else "HP low: get out or lose it all" if low else ("Auto-run: leaving ends it" if sim.auto_tier >= 0 else
		("Goes when the pack's full or a gang comes" if m.get("leave_full", false) else
		("Pack full: a better find swaps in" if sim.pack_used(m) >= sim.capacity() else ("Push for loot, or go" if m["cleared"] else "Leaving keeps the loot"))))
	_note.add_theme_color_override("font_color", Pal.ACCENT if way_out else (Pal.BAD if low else Pal.TEXT_2))
	# the crates under the pack once the site's cleared, where the pick panel sits while nothing's picked (a pick
	# brings the panel back over them: the review, 13 Oct - a 3x3 vest wouldn't fit a pack cut to two rows)
	# the crates (13 Oct, Matt): a toggle, the search bar opening them and the crates' bar giving the pick back - one
	# search bar shown at a time; a new search opens on the crates, whatever was picked when the fight ended
	var has_crates: bool = m.has("crates") and not m.get("crates_off", false)
	if has_crates and not is_same(_crates_for, m["crates"]):
		_crates_for = m["crates"]
		view_crates = true
	var crates_on: bool = has_crates and view_crates
	var searching_bar: bool = has_crates and m["remaining"] <= 0 and not boss_on and not way_out
	_fight["track"].visible = not (crates_on and searching_bar)
	_search_button.visible = searching_bar and not crates_on
	_crates.visible = crates_on
	_pick.visible = not crates_on
	if crates_on:
		_crates.show_crates(sim, m)
	# the pack
	_inv.show_items(sim, m["found"], sim.pack_used(m), sim.capacity(), "Pack")
	_juice_tick(m)
	# buttons and the pick panel change rarely; a redraw under the mouse drops presses
	var real_clear: bool = m["cleared"] and not m.get("ghost_pending", false)
	if way_out:
		_button.text = "Getting out · %s" % Fmt.mss(ceilf(maxf(0.0, float(m["way_out_t"]))))     # the seconds each frame; the restyle below only when it starts
	# the price before the clear changes only as the run's clock caps it (the review, 10 Oct)
	var sig := "%s|%s|%d|%d|%s|%d|%d|%s|%d|%s|%s|%s" % [med_sig + "|r%d" % _rig_pick, str(sim.auto_tier >= 0), _inv.selected, m["found"].size(), str(low or m["cleared"]), sim.pack_used(m), sim.rig.size(), str(m.get("leave_full", false)), int(m.get("swapped", 0)),
		str(way_out), ("%d" % ceili(sim.way_out_s(t, m))) if not real_clear and not way_out else "", str(sim.can_extract())]
	if sig == _shown:
		return
	_shown = sig
	var auto: bool = sim.auto_tier >= 0
	var filling: bool = m.get("leave_full", false)
	_button.visible = true
	_button.disabled = not sim.can_extract()
	if not sim.can_extract():
		_button.text = "Stand and fight: no way out"      # the Stand node holds you to the clear
		UI.style_button(_button, false)
	elif way_out:
		UI.style_button(_button, false, "warn")
	elif real_clear:
		_button.text = "Get out now"
		UI.style_button(_button, low or not filling)
	else:
		# before the clear it says its price (10 Oct, the way out): the seconds and a last gang
		var wo: String = Fmt.mss(ceilf(sim.way_out_s(t, m)))
		var room: float = ((INNER - 12) / 2.0 if auto else float(INNER)) - 48.0     # the half-width button on an auto-run (10 Oct); the button's own padding
		_button.text = "Get out · %s" % wo
		for o in ["Get out now · %s and a last gang" % wo, "Get out · %s, a gang" % wo]:
			if UI.text_width(_button, o) <= room:
				_button.text = o
				break
		UI.style_button(_button, low)
	# the second button: Stop auto on an auto-run; else, once the fight's won, "Fill up, then go"
	_button2.visible = auto or m["cleared"]
	_button2.text = "Stop auto" if auto else ("Filling up ✓" if filling else "Fill up, then go")
	UI.style_button(_button2, false, "good" if (filling and not auto) else "")
	if _button2.visible:
		_button.size.x = (INNER - 12) / 2
		_button2.position.x = PAD + _button.size.x + 12
		_button2.size.x = INNER - _button.size.x - 12
	else:
		_button.size.x = INNER
	_show_pick(m)


## A bar: its track, its fill and its words, at `y` across the column.
func _bar_make(d: Dictionary, y: float, x: float = PAD, w: float = INNER) -> void:
	var track := UI.panel(_left, Rect2(x, y, w, BAR_H), UI.box(Pal.BG, 6))
	d["track"] = track
	d["w"] = w
	d["fill"] = UI.panel(track, Rect2(0, 0, 0, BAR_H), UI.box(Pal.ACCENT, 6))
	# Guard (12 Oct, docs/design/shields.md): a pale steel band laid from the fill's right edge back over it, its
	# width Guard over max HP - the part of the bar their fire takes first; under the dots' segments (the review)
	d["guard"] = UI.panel(track, Rect2(0, 0, 0, BAR_H), UI.box(Color(Pal.GUARD, 0.5), 0))
	d["guard"].visible = false
	# what the dots still have to take off the bar (Matt, 6 Oct): the end of the fill, a segment a type, so the
	# fill is seen going down into them as they tick
	d["segments"] = []
	for ty in Data.TYPES:
		var seg := UI.panel(track, Rect2(0, 0, 0, BAR_H), UI.box(Pal.tone_color(ty) if ty != "physical" else Pal.TEXT_3, 0))
		seg.visible = false
		d["segments"].append(seg)
	d["bar_text"] = UI.label(track, Rect2(0, 0, w, BAR_H), "", "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	track.move_child(d["bar_text"], -1)
	# the skull (Matt, 11 Oct): what the dots still have to take off covers what's left - finished, the shooting or
	# not; on your own bar, the bleed will have you unless something heals it. Shown only, nothing changes
	var skull := TextureRect.new()
	skull.texture = NodeGlyphs.texture("skull")
	skull.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skull.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	skull.position = Vector2(3, 1)
	skull.size = Vector2(BAR_H - 2, BAR_H - 2)
	skull.modulate = Color(Pal.BG, 0.95)        # dark on the fill and the dots' colours, which it always sits over
	skull.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skull.visible = false
	track.add_child(skull)
	d["skull"] = skull


func _bar(d: Dictionary, fill: float, text: String, tone: String, pending: Dictionary = {}, of: float = 1.0, guard_share := 0.0) -> void:
	(d["fill"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.ACCENT if tone == "" else Pal.tone_color(tone)
	d["fill"].size.x = roundf(float(d.get("w", INNER)) * clampf(fill, 0.0, 1.0))
	d["bar_text"].text = text
	_bar_segments(d, pending, of)
	if d.has("guard"):
		var gw: float = minf(d["fill"].size.x, roundf(float(d.get("w", INNER)) * clampf(guard_share, 0.0, 1.0)))
		d["guard"].visible = gw >= 1.0
		d["guard"].size.x = gw
		d["guard"].position.x = d["fill"].size.x - gw
	d["skull"].visible = dots_finish(fill * of + guard_share * of, pending)     # the dots come off Guard first (the review)


## Whether the dots still to tick off cover the HP that's left (and there's some left): the bar's skull.
static func dots_finish(left: float, pending: Dictionary) -> bool:
	if left <= 0.0:
		return false
	var total := 0.0
	for ty in pending:
		total += maxf(0.0, float(pending[ty]))
	return total >= left


## The dots' pools as the end of the fill: `pending` is {type: HP still to tick off}, `of` the bar's whole in HP.
## Laid from the fill's right edge leftwards, a type each, never past the fill's left end.
func _bar_segments(d: Dictionary, pending: Dictionary, of: float) -> void:
	var right: float = d["fill"].size.x
	var left_limit: float = 0.0
	for k in range(Data.TYPES.size()):
		var ty: String = Data.TYPES[k]
		var seg: Panel = d["segments"][k]
		var amount: float = maxf(0.0, float(pending.get(ty, 0.0)))
		var w: float = floorf(float(d.get("w", INNER)) * amount / maxf(of, 1.0)) if amount > 0.0 else 0.0
		w = minf(w, right - left_limit)
		seg.visible = w >= 1.0
		seg.size.x = w
		seg.position.x = right - w
		right -= w


## A face's place in a box: a frame, the portrait in it, and a drawn figure for a face with no art.
func _face_make(at: Vector2) -> Dictionary:
	var f := {}
	f["frame"] = UI.panel(_left, Rect2(at, Vector2(FACE, FACE)), UI.box(Pal.BG, 6, 1, Pal.CARD_LINE))
	f["frame"].mouse_filter = Control.MOUSE_FILTER_IGNORE
	f["blank"] = TextureRect.new()
	f["blank"].position = Vector2(18, 18)
	f["blank"].size = Vector2(FACE - 36, FACE - 36)
	f["blank"].expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	f["blank"].stretch_mode = TextureRect.STRETCH_SCALE
	f["blank"].texture = NodeGlyphs.texture("person")
	f["blank"].modulate = Pal.TEXT_3
	f["blank"].mouse_filter = Control.MOUSE_FILTER_IGNORE
	f["frame"].add_child(f["blank"])
	f["art"] = People.rect(_left, at + Vector2(1, 1), float(FACE - 2) / 128.0)     # inside the frame's line
	f["art"].texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR                      # scaled down: nearest drops rows (the review)
	return f


## The first of `names` with art; the drawn figure when none has. Returns the name shown, or "".
func _face_show(f: Dictionary, names: Array) -> String:
	for n in names:
		if str(n) != "" and People.show(f["art"], str(n)):
			f["blank"].visible = false
			return str(n)
	People.show(f["art"], "")
	f["blank"].visible = true
	return ""


## A zone's gang face: art/people/gang_<the zone>.png (gang_the_estate, gang_the_town, gang_the_city), from Matt's
## Greenhorn set.
static func gang_face(zone_i: int) -> String:
	return "gang " + str(Data.ZONES[clampi(zone_i, 0, Data.ZONES.size() - 1)]["name"])


## The tiles' words: [[key, [long, shorter...]], ...].
func _tiles(tiles: Array, rows: Array) -> void:
	for k in range(tiles.size()):
		if k < rows.size():
			UI.set_tile(tiles[k], rows[k][0], rows[k][1])
		else:
			UI.set_tile(tiles[k], "", [""])


func _show_pick(m: Dictionary) -> void:
	var it := _picked_item(m)
	var r := _rig_picked()
	if it.is_empty() and not r.is_empty():
		_show_rig_pick(m, r)
		return
	if it.is_empty():
		var lines := ["A rifle is four cells by one, armour three by three, a med or a part one"]
		if sim.pack_used(m) >= sim.capacity():
			var cheap: Dictionary = sim.cheapest_in_pack()
			lines.append("Full: a better find swaps out the cheapest thing at least its size")
			lines.append("Cheapest now: %s, %s" % [cheap["base"].to_lower(), Fmt.money(sim.sell_price(cheap))] if not cheap.is_empty() else "")
		else:
			lines.append("%d cell%s free" % [sim.capacity() - sim.pack_used(m), "" if sim.capacity() - sim.pack_used(m) == 1 else "s"])
		lines.append("Pick a cell for its figures; Select many ditches a few at once" if m["found"].size() > 0 else "Nothing found yet")
		_pick.show_empty("The pack: %d of %d cells" % [sim.pack_used(m), sim.capacity()], lines)
		_pick.set_buttons([])
		return
	var tail = ""
	if Items.is_gun(it):
		tail = [Items.fitted_words(it), Items.ammo_words(it).to_lower().replace("smg", "SMG")]
	elif Items.is_attachment(it) and not Items.is_socketable(it):
		tail = Items.att_words(it, true, true)
	_pick.show_pick(it, sim, "The pick · in the pack", tail)
	var buttons := []
	if Items.rig_item(it):
		# a med, rounds or a grenade: the rig on the right, Take into it when there's a pouch
		var room: bool = sim.rig_room(Items.size(it)) or sim.rig_tops_up(it)
		_pick.show_right_words("The rig", "%d of %d pouches filled" % [sim.rig_used(), sim.med_capacity()],
			[("Fired by the %s" % Items.base_of(it)["type"]) if Items.is_ammo(it) else ("Thrown at everyone on you" if Items.is_grenade(it) else "%s, under fire" % sim.med_words(it)),
			"" if room else ("No rig fitted" if sim.med_capacity() == 0 else "The rig is full")])
		buttons.append({"text": "Take into the rig", "action": _take_pick, "enabled": room, "primary": true})
	elif it["slot"] in Data.SLOTS:
		var fitted = sim.equipped.get(it["slot"], null)
		if fitted != null:
			var ftail = ""
			if Items.is_gun(fitted):
				ftail = [Items.fitted_words(fitted), Items.ammo_words(fitted).to_lower().replace("smg", "SMG")]
			_pick.show_fitted(fitted, sim, "Fitted now", ftail)
			var v: Array = PickPanel.verdict_for(sim, it)
			_pick.set_verdict(v[0], v[1], PickPanel.deltas_for(sim, it, fitted))
		else:
			_pick.show_right_words("Fitted now", "Nothing fitted as %s" % it["slot"].to_lower(), ["Equipping adds everything at the left"])
		var can: bool = sim.can_equip_from_pack(it["id"])
		# the foot's hint: no rounds for it (the try-on counts it fed, 11 Oct), no room for what comes off, or both
		var hints: Array = []
		if Items.is_gun(it) and not sim.has_rounds(it):
			hints.append("No rounds for it in the rig")
		if not can and fitted != null:
			hints.append("No room in the pack for what comes off (%d cells)" % Items.size(fitted))
		if not hints.is_empty():
			_pick.set_hint_options(_hint_forms(hints))
		buttons.append({"text": "Equip", "action": _equip_pick, "enabled": can, "primary": true})
	else:
		_pick.show_right_words("", "", [])
	buttons.append({"text": "Ditch", "action": _ditch_pick, "enabled": true, "primary": buttons.is_empty()})
	_pick.set_buttons(buttons)


## A stack of rounds picked in the rig: what it is, whether it's the one firing, and Into the pack when there's room.
func _show_rig_pick(m: Dictionary, r: Dictionary) -> void:
	_pick.show_pick(r, sim, "The pick · in the rig", Items.ammo_words(r).to_lower().replace("smg", "SMG"))
	var firing := false
	var same := false                    # a stack of the same grade as the one firing: next after it
	for slot in ["Primary", "Secondary"]:
		var g = sim.equipped[slot]
		if g != null and sim.feed_stack(g) == r:
			firing = true
		elif g != null and not sim.feed_stack(g).is_empty() and sim.feed_stack(g)["base"] == r["base"]:
			same = true
	var room: bool = sim.can_rig_to_pack(r["id"])
	_pick.show_right_words("The pack", "%d of %d cells" % [sim.pack_used(m), sim.capacity()],
		["Firing now: the best in the rig" if firing else ("Next: the same rounds, after these" if same else ("Waiting: a better grade fires first" if _fires_for_worn(r) else "No gun worn fires it")),
		"" if room else "No room: ditch something first"])
	_pick.set_buttons([{"text": "Into the pack", "action": _rig_to_pack, "enabled": room, "primary": true}])


func _fires_for_worn(r: Dictionary) -> bool:
	for slot in ["Primary", "Secondary"]:
		var g = sim.equipped[slot]
		if g != null and Items.ammo_type(g) == Items.base_of(r)["type"]:
			return true
	return false


func _rig_picked() -> Dictionary:
	if _rig_pick < 0 or sim == null:
		return {}
	for it in sim.rig:
		if int(it["id"]) == _rig_pick:
			return it
	return {}


func _rig_to_pack() -> void:
	if _rig_pick >= 0 and sim.rig_to_pack(_rig_pick):
		_rig_pick = -1
	acted.emit()


func _picked_item(m: Dictionary) -> Dictionary:
	if _inv.selected < 0:
		return {}
	for it in m["found"]:
		if it["id"] == _inv.selected:
			return it
	return {}


# ------------------------------------------------------------------ acting

## The juice: a number for what's landed since the last look, a flash on a
## rare that's just come into the pack. A new run starts the count again.
func _juice_tick(m: Dictionary) -> void:
	if m.get("elapsed", 0.0) < 1.5:
		_dealt_seen = 0.0
		_dealt_seen_by = {}
		_number_at = -1.0
		_hp_at = -1.0
		_taken_seen = 0.0
		_taken_seen_by = {}
		_guarded_seen = 0.0
		_healed_seen = 0.0
		_found_seen = []
	var dealt: float = float(m.get("dealt", 0.0))
	# a number every third of a second or so, not every refresh, scattered along their bar
	# at different heights, bigger for a bigger hit - a column of them reads as nothing.
	# One a type, in the type's colour: white for the physical, red for fire, green for poison
	if juice != null and dealt - _dealt_seen >= 1.0 and m["remaining"] > 0 and float(m["elapsed"]) - _number_at >= 0.3:
		_number_at = float(m["elapsed"])
		_numbers_by(m.get("dealt_by", {}), _dealt_seen_by, FIGHT_BAR_Y, "", 100)
		_dealt_seen = dealt
	# and on your own bar: what you took, by type, and green for what came back - counted apart,
	# so a helmet's +1 a second shows among the hits even when the hits are winning
	var taken: float = float(m.get("taken", 0.0))
	var healed: float = float(m.get("healed", 0.0))
	if juice != null and float(m["elapsed"]) - _hp_at >= 0.5:
		var shown := false
		if taken - _taken_seen >= 1.0:
			_numbers_by(m.get("taken_by", {}), _taken_seen_by, RUNNER_BAR_Y, "−", 40)
			_taken_seen = taken
			shown = true
		var guarded: float = float(m.get("guarded", 0.0))
		if guarded - _guarded_seen >= 1.0:
			var gn: int = int(floor(guarded - _guarded_seen))
			juice.number(_scatter(RUNNER_BAR_Y), "−%d" % gn, "guard", gn >= 40)
			_guarded_seen += gn
			shown = true
		if healed - _healed_seen >= 1.0:
			var n: int = int(round(healed - _healed_seen))
			juice.number(_scatter(RUNNER_BAR_Y), "+%d" % n, "good", n >= 40)
			_healed_seen = healed
			shown = true
		if shown:
			_hp_at = float(m["elapsed"])

	for it in m["found"]:
		if not (it["id"] in _found_seen):
			_found_seen.append(it["id"])
			if juice != null and (int(it["rarity"]) >= 2 or it.has("unique") or it.has("set")):
				var k: int = _inv.cell_of(it["id"])
				if k >= 0:
					juice.flash(_inv.cell_node(k), "set" if it.has("set") else ("good" if it.has("unique") else ""))


## A number a type for what's new in `by` since `seen`, each in its type's
## colour, scattered along the panel; whole points only, the rest carried.
func _numbers_by(by: Dictionary, seen: Dictionary, bar_y: float, sign: String, big_at: int) -> void:
	for ty in Data.TYPES:
		var total: float = float(by.get(ty, 0.0))
		var n: int = int(floor(total - float(seen.get(ty, 0.0))))
		if n >= 1:
			juice.number(_scatter(bar_y), "%s%d" % [sign, n], ty, n >= big_at)
			seen[ty] = float(seen.get(ty, 0.0)) + n


## A spot along a bar of the column, at a different height each time, in the juice's own space.
func _scatter(bar_y: float) -> Vector2:
	var local := Vector2(BOXED_X + 30 + randf() * (BOXED_W - 90), bar_y - 6 + randf_range(-16.0, 16.0))     # over the bar, never the face
	return _left.global_position + local - (juice.global_position if juice != null else Vector2.ZERO)


## The rig in the Runner panel: a cell a pouch, the pouches' outlines for the empty ones.
func _show_rig() -> void:
	var cap: int = mini(RIG_MAX, sim.med_capacity())
	# one row of full cells to eight, one row of smaller to twelve, two rows past that (the generator's row): the same 64 px tall
	var rows: int = 1 if cap <= 12 else 2
	var per_row: int = maxi(1, ceili(float(cap) / rows))     # no rig (one lost to the clock): one empty row
	var cell: int = Pal.CELL if cap <= 8 else mini((Pal.CELL - Pal.CELL_GAP) / 2 if rows == 2 else Pal.CELL, int((INNER + Pal.CELL_GAP) / per_row) - Pal.CELL_GAP)
	var at := func(pos: int) -> Vector2: return Vector2(PAD + (pos % per_row) * (cell + Pal.CELL_GAP), RIG_Y + (pos / per_row) * (cell + Pal.CELL_GAP))
	# a pouch a cell: an item spans as many as its cells (a first aid kit two), along the row, never across a row's end
	# first fit (12 Oct, Matt's playtest): each item at the first run of free pouches on one row, so a single fills the
	# gap a wide kit left at a row's end; nothing past the cap (the cells follow the rig's order, so the first that finds no run stops the rest)
	var k := 0
	var taken := {}
	for it in sim.rig:
		var w: int = mini(Items.size(it), per_row)
		var pos := -1
		for p in range(0, maxi(cap, 1)):
			var ok: bool = p % per_row + w <= per_row and p + w <= cap
			for j in range(w):
				if taken.has(p + j):
					ok = false
			if ok:
				pos = p
				break
		if k >= RIG_MAX or pos < 0:
			break
		var c = _rig_cells[k]
		c.position = at.call(pos)
		var lit: bool = (Items.is_medical(it) and sim.hp / sim.max_hp() <= 0.35 and sim.mission["using"] == null and not sim.mission["t"].get("no_meds", false)) or (Items.is_grenade(it) and sim.mission["remaining"] > 0)
		c.show_item(it, lit or int(it["id"]) == _rig_pick, Vector2(w * cell + (w - 1) * Pal.CELL_GAP, cell))
		# the hover (11 Oct): what a med heals, what a stack is and whether it's firing
		if Items.is_medical(it):
			c.tooltip_text = "%s · %s" % [it["base"], sim.med_words(it)]
		elif Items.is_ammo(it):
			c.tooltip_text = "%s · %d rounds · tap for the pack" % [it["base"], int(it["rounds"])]
		else:
			c.tooltip_text = str(it["base"])
		c.visible = true
		for j in range(w):
			taken[pos + j] = true
		k += 1
	for i in range(k, RIG_MAX):
		_rig_cells[i].visible = false
	for i in range(RIG_MAX):
		var o = _rig_outlines[i]
		o.visible = i < cap and not taken.has(i)
		o.position = at.call(i)
		o.size = Vector2(cell, cell)


func _rig_pressed(k: int) -> void:
	if k < sim.rig.size() and sim.on_mission():
		if Items.is_ammo(sim.rig[k]):
			# rounds: picked for the pick panel (Into the pack), or let go on a second tap
			var id: int = int(sim.rig[k]["id"])
			_rig_pick = -1 if _rig_pick == id else id
			_inv.selected = -1
			view_crates = false               # its comparison shows: the crates are the search bar's click away
		elif Items.is_medical(sim.rig[k]):
			sim.use_med(sim.rig[k]["id"])
		elif Items.is_grenade(sim.rig[k]):
			sim.use_grenade(sim.rig[k]["id"])     # thrown at everyone on you (32)
		acted.emit()


func _take_pick() -> void:
	if not sim.on_mission():
		return
	var it := _picked_item(sim.mission)
	if not it.is_empty() and sim.take_from_pack(it["id"]):
		_inv.selected = -1


func _get_out() -> void:
	sim.get_out()
	acted.emit()


func _second_button() -> void:
	if sim.auto_tier >= 0:
		_stop_auto()
	elif sim.on_mission():
		sim.set_leave_full(not sim.mission.get("leave_full", false))
		acted.emit()


func _stop_auto() -> void:
	sim.stop_auto()
	acted.emit()


func _ditch_pick() -> void:
	if _inv.selected >= 0 and sim.ditch(_inv.selected):
		_inv.selected = -1


func _equip_pick() -> void:
	if _inv.selected >= 0 and sim.equip_from_pack(_inv.selected):
		_inv.selected = -1


func _on_pick_acted() -> void:
	acted.emit()


func _on_inv_pick(_id: int) -> void:
	view_crates = false                   # a pick shows its comparison: the crates are a click on the search bar away
	acted.emit()


## The search bar's toggle (13 Oct, Matt): the crates, or the pick.
func _toggle_crates() -> void:
	view_crates = not view_crates
	_shown = ""                           # the pick panel redraws when it comes back
	acted.emit()


## A flat button over a bar: the bar shows through, the pointer says it's pressable.
func _bar_button(track: Control) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.position = track.position
	b.size = track.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", UI.box(Color(1, 1, 1, 0.06), 6))
	b.add_theme_stylebox_override("pressed", UI.box(Color(1, 1, 1, 0.1), 6))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	track.get_parent().add_child(b)
	b.visible = false
	return b


func _on_inv_acted() -> void:
	acted.emit()


## For the tests: every label and visible button with text.
func text_nodes() -> Array:
	var out: Array = _pick.text_nodes()
	out.append_array(_band.text_nodes())
	out.append_array([_fight["head"], _fight["bar_text"], _runner["head"], _runner["bar_text"], _rig_head, _take_head, _note])
	if _runner["note"].visible:
		out.append(_runner["note"])
	for d in [_fight, _runner]:
		if d["chips"].visible:
			out.append(d["key"])
			out.append_array(d["chips"].text_nodes())
	for t in _fight["tiles"] + _runner["tiles"] + _take_tiles:
		out.append_array([t["key"], t["value"]])
	for b in [_button, _button2]:
		if b.visible:
			out.append(b)
	out.append_array(_inv.text_nodes())
	if _crates.visible:
		out.append_array(_crates.text_nodes())
	return out


## Label + value pairs that share a line, and the headline + unit, for the fit check.
func line_pairs() -> Array:
	var out: Array = _pick.line_pairs()
	out.append([_band.headline, _band.unit])
	return out


## The foot's hints in forms long to short: alone, no rounds says why it matters; together, both on one line; then
## each cut to its first words.
static func _hint_forms(hints: Array) -> Array:
	var out: Array = []
	if hints.size() == 1 and str(hints[0]).begins_with("No rounds"):
		out.append(str(hints[0]) + ": it won't fire until it has some")
	out.append(" · ".join(hints))
	out.append(" · ".join(hints.map(func(h): return str(h).get_slice(" (", 0).replace(" for what comes off", "").replace(" for it in the rig", ""))))
	return out
