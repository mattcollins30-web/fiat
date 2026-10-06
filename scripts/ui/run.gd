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
const ItemHead := preload("res://scripts/ui/item_head.gd")
const Band := preload("res://scripts/ui/band.gd")

const BODY_W := Inventory.SIDE_W                              # 608
const GAP := 24
const GRID_X := BODY_W + GAP
const GRID_W := Inventory.WIDTH                                # 904
const GRID_H := Inventory.HEIGHT                               # 588
const PICK_Y := GRID_H + GAP                                  # 612
const PICK_H := Pal.ROOM_H - PICK_Y                           # 304
const BAND_H := 200                                           # the site's art band at the top of the column
const RIG_MAX := 18
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
const FIGHT_BOX_H := FIGHT_BAR_Y + BAR_H + BOX_PAD - FIGHT_BOX_Y
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
var _fight := {}                   # {box, head, tiles[4], track, fill, bar_text}
var _runner := {}                  # {head, track, fill, bar_text, tiles[4], note}
var _rig_head: Label
var _take_head: Label
var _take_tiles: Array = []
var _note: Label                   # the run's own line: leaving keeps the loot, HP low, filling up
var _button: Button                # Get out now
var _button2: Button               # Stop auto, or Fill up then go
var _inv
var _pick: Panel
var _pick_title: Label             # the pack's state with nothing picked; a pick shows the head
var _pick_head                     # the pick's name, chips, headline and affix rows (item_head.gd)
var _pick_right: Array[Label] = [] # the right column: what's fitted, what the fence pays
var _pick_lines: Array[Label] = []
var _ditch: Button
var _hint: Label
var _words: Array[Label] = []      # the item's own line, two rows under the figures
var _shown := ""
var _head_face: TextureRect        # the crew's head, while he's out
var _rig_cells: Array = []         # ItemCells, one a pouch, in the Runner panel
var _rig_outlines: Array = []
var _take: Button                  # a med or rounds from the pack into the rig
var juice = null                   # the shell's, for numbers and flashes; null in a bare test
var _dealt_seen := 0.0             # what the numbers have shown so far this run
var _dealt_seen_by := {}           # and by type, for the coloured numbers
var _taken_seen_by := {}
var _number_at := -1.0             # the run's clock when the last number came off
var _taken_seen := 0.0             # what the red numbers have shown so far this run
var _healed_seen := 0.0            # and the green
var _hp_at := -1.0
var _found_seen: Array = []        # the finds the flashes have seen


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_left = UI.panel(self, Rect2(0, 0, BODY_W, Pal.ROOM_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_band = Band.new(BODY_W, BAND_H)
	_left.add_child(_band)
	# the fight and the runner each in an outlined box, so them and you read apart
	_fight["box"] = UI.panel(_left, Rect2(PAD - BOX_PAD, FIGHT_BOX_Y, INNER + 2 * BOX_PAD, FIGHT_BOX_H), UI.box(Color.TRANSPARENT, 8, 1, Pal.CARD_LINE))
	_runner["box"] = UI.panel(_left, Rect2(PAD - BOX_PAD, RUNNER_BOX_Y, INNER + 2 * BOX_PAD, RUNNER_BOX_H), UI.box(Color.TRANSPARENT, 8, 1, Pal.CARD_LINE))
	# the fight: a head, four tiles, their HP as the bar (or the search's)
	_fight["head"] = UI.head(_left, Rect2(PAD, FIGHT_Y, INNER - 80, UI.HEAD_H), "The fight")
	_fight["tiles"] = UI.tile_row(_left, PAD, FIGHT_TILES_Y, INNER, 4)
	_bar_make(_fight, FIGHT_BAR_Y)
	_head_face = People.rect(_left, Vector2(BODY_W - PAD - 48, FIGHT_Y - 12), 0.375)     # 48 px, between the band and the tiles
	# the runner: the head, your HP as the bar, four tiles, a note
	_runner["head"] = UI.head(_left, Rect2(PAD, RUNNER_Y, INNER, UI.HEAD_H), "The runner")
	_bar_make(_runner, RUNNER_BAR_Y)
	_runner["tiles"] = UI.tile_row(_left, PAD, RUNNER_TILES_Y, INNER, 4)
	_runner["note"] = UI.label(_left, Rect2(PAD, RUNNER_NOTE_Y, INNER, LINE_H), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	# the rig's pouches: what's carried, a cell a pouch; a med's cell uses that med
	_rig_head = UI.head(_left, Rect2(PAD, RIG_HEAD_Y, INNER, UI.HEAD_H), "The rig · a pouch is a button")
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
	_pick = UI.panel(self, Rect2(GRID_X, PICK_Y, GRID_W, PICK_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_pick_title = UI.label(_pick, Rect2(PAD, 10, GRID_W - 2 * PAD, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(4):
		_pick_lines.append(UI.label(_pick, Rect2(PAD, 48 + i * 28, GRID_W - 2 * PAD, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	var col_w: int = (GRID_W - 3 * PAD) / 2
	_pick_head = ItemHead.new(col_w, true)
	_pick_head.position = Vector2(PAD, 10)
	_pick_head.visible = false
	_pick.add_child(_pick_head)
	for i in range(3):
		_pick_right.append(UI.label(_pick, Rect2(PAD * 2 + col_w, 14 + i * 28, col_w, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_hint = UI.label(_pick, Rect2(PAD, PICK_H - 6 - 44, GRID_W - 2 * PAD - 260, 44), "", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(2):
		_words.append(UI.label(_pick, Rect2(PAD, 228 + i * 20, (GRID_W - 3 * PAD) / 2, 20), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_ditch = UI.button(_pick, Rect2(GRID_W - PAD - 240, PICK_H - 6 - 44, 240, 44), false)
	_ditch.pressed.connect(_ditch_pick)
	_ditch.visible = false
	_take = UI.button(_pick, Rect2(GRID_W - PAD - 240, PICK_H - 6 - 44, 240, 44), true)
	_take.pressed.connect(_take_pick)
	_take.visible = false


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	if not sim.on_mission():
		return
	var m: Dictionary = sim.mission
	var t: Dictionary = m["t"]
	var low: bool = sim.hp / sim.max_hp() <= 0.35
	var tier_i: int = int(m["tier"])
	# the band: the site, the clock as the headline, the fight's progress as the bar
	var zone_i := 0
	for z in range(Data.ZONES.size()):
		if tier_i in Data.ZONES[z]["tiers"]:
			zone_i = z
	_band.set_site(t["name"])
	_band.set_tone(zone_i)
	_band.set_words("Depth %d · %s" % [t["depth"], Data.ZONES[zone_i]["name"]], t["name"], Fmt.mss(m["elapsed"]), "of the run", Pal.ACCENT)
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
	_band.set_right(["Cash so far %s" % Fmt.money(m["cash"]), "%d gang%s so far" % [m["patrols"], "" if m["patrols"] == 1 else "s"], cap_line])
	_band.set_bar((float(m["kills"]) / float(t["pool"])) if not m["cleared"] else 1.0, ("Cleared" if m["cleared"] else "%d of %d down" % [m["kills"], t["pool"]]))
	# them
	var boss_on: bool = m.has("boss") and m["boss"]["started"] and m["boss"]["alive"]
	People.show(_head_face, m["boss"]["name"] if boss_on else "")
	if boss_on:
		_fight["head"].text = m["boss"]["name"].to_upper()
		_tiles(_fight["tiles"], [["On you", ["the crew's head", "1"]], ["Incoming", ["%.1f/s" % m["last_incoming"]]], ["Your fire", ["%.0f/s" % (sim.dps() * sim.pace())]], ["Kills", ["%d" % m["kills"]]]])
		_bar(_fight, clampf(m["target_hp"] / float(m["boss"]["hp"]), 0.0, 1.0), "Their HP %d / %d" % [ceili(m["target_hp"]), int(m["boss"]["hp"])], "bad")
	elif m["remaining"] > 0:
		var on_you: int = mini(m["remaining"], sim.contact(t))
		_fight["head"].text = ("GANG %d" % m["patrols"]) if m["cleared"] else ("THE FIGHT; THEN %s" % m["boss"]["name"].to_upper() if m.has("boss") and m["boss"]["alive"] else "THE FIGHT")
		_tiles(_fight["tiles"], [["On you", [("%d · %d more" % [on_you, m["remaining"] - on_you]) if m["remaining"] > on_you else "%d" % on_you, "%d" % on_you]],
			["Incoming", ["%.1f/s" % m["last_incoming"]]], ["Your fire", ["%.0f/s" % (sim.dps() * sim.pace())]], ["Kills", ["%d" % m["kills"]]]])
		_bar(_fight, clampf(m["target_hp"] / t["hp"], 0.0, 1.0), "Their HP %d / %d" % [ceili(m["target_hp"]), int(t["hp"])], "bad")
	else:
		_fight["head"].text = "PICKING IT OVER · EVERY GANG THE SIZE OF THE FIRST" if sim.has_node("cap_dead_quiet") else "PICKING IT OVER · EACH GANG BIGGER THAN THE LAST"
		var next: float = sim.patrol_s(t, m["patrols"] == 0) - m["patrol_timer"]
		_tiles(_fight["tiles"], [["Next gang", [Fmt.mss(next) if next < 1e8 else "never"]], ["Gangs so far", ["%d" % m["patrols"]]], ["Kills", ["%d" % m["kills"]]], ["Found", ["%d" % m["found"].size()]]])
		var thin: float = sim.thinning(m, t)
		var search_words: String = "Searching" if thin >= 1.0 else (("Thinned out: finds at %d%%" if is_equal_approx(thin, Data.THIN_FLOOR) else "Thinning: finds at %d%%") % int(roundf(thin * 100.0)))
		_bar(_fight, clampf(m["search"] / sim.search_s(t), 0.0, 1.0), search_words, "good" if thin >= 1.0 else "warn")
	# the runner
	_bar(_runner, clampf(sim.hp / sim.max_hp(), 0.0, 1.0), "Your HP %d / %d" % [sim.hp_shown(), sim.max_hp_shown()], "bad" if low else "good")
	var gun = sim.equipped["Primary"]
	var rounds: int = sim.rounds_for(gun) if gun != null else 0
	_tiles(_runner["tiles"], [["Armour", ["%.0f (%s)" % [sim.armour(), Fmt.pct(sim.mitigation())], "%.0f" % sim.armour()]], ["Damage", ["%.0f/s" % (sim.dps() * sim.pace())]],
		["Meds", [("%d" % sim.meds_carried()) if sim.meds_carried() > 0 else "none"]], ["Rounds", [("%d" % rounds) if rounds > 0 else ("dry" if gun != null else "no gun")]]])
	_runner["tiles"][3]["value"].add_theme_color_override("font_color", Pal.BAD if gun != null and rounds == 0 else Pal.TEXT)
	var on_you_words: Array = sim.dots_on_you()
	var med_sig := ""
	if m["using"] != null:
		_runner["note"].text = "%s, %.0f s to go" % [m["using"]["name"], ceilf(m["using"]["left"])]
		med_sig = "using"
	elif not on_you_words.is_empty():
		UI.fit(_runner["note"], ["On you: " + ", ".join(on_you_words), "On you: " + str(on_you_words[0])])
		med_sig = "dots"
	elif sim.first_med().is_empty():
		_runner["note"].text = "No meds in the rig"
		med_sig = "none"
	else:
		_runner["note"].text = "Press a pouch to use its med"
		med_sig = "use:" + sim.first_med()["base"]
	_show_rig()
	# the take
	_tiles(_take_tiles, [["Cash", [Fmt.money(m["cash"])]], ["Passed over", ["%d" % m["left"]]], ["Swapped", ["%d" % int(m.get("swapped", 0))]], ["Pack", ["%d of %d" % [sim.pack_used(m), sim.capacity()], "%d/%d" % [sim.pack_used(m), sim.capacity()]]]])
	_note.text = "HP low: get out or lose it all" if low else ("Auto-run: leaving ends it" if sim.auto_tier >= 0 else
		("Goes when the pack's full or a gang comes" if m.get("leave_full", false) else
		("Pack full: a better find swaps in" if sim.pack_used(m) >= sim.capacity() else ("Push for loot, or go" if m["cleared"] else "Leaving keeps the loot"))))
	_note.add_theme_color_override("font_color", Pal.BAD if low else Pal.TEXT_2)
	# the pack
	_inv.show_items(sim, m["found"], sim.pack_used(m), sim.capacity(), "Pack")
	_juice_tick(m)
	# buttons and the pick panel change rarely; a redraw under the mouse drops presses
	var sig := "%s|%s|%d|%d|%s|%d|%d|%s|%d" % [med_sig, str(sim.auto_tier >= 0), _inv.selected, m["found"].size(), str(low or m["cleared"]), sim.pack_used(m), sim.rig.size(), str(m.get("leave_full", false)), int(m.get("swapped", 0))]
	if sig == _shown:
		return
	_shown = sig
	var auto: bool = sim.auto_tier >= 0
	var filling: bool = m.get("leave_full", false)
	_button.text = "Get out now"
	_button.visible = true
	UI.style_button(_button, low or (m["cleared"] and not filling))
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
func _bar_make(d: Dictionary, y: float) -> void:
	var track := UI.panel(_left, Rect2(PAD, y, INNER, BAR_H), UI.box(Pal.BG, 6))
	d["track"] = track
	d["fill"] = UI.panel(track, Rect2(0, 0, 0, BAR_H), UI.box(Pal.ACCENT, 6))
	d["bar_text"] = UI.label(track, Rect2(0, 0, INNER, BAR_H), "", "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)


func _bar(d: Dictionary, fill: float, text: String, tone: String) -> void:
	(d["fill"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.ACCENT if tone == "" else Pal.tone_color(tone)
	d["fill"].size.x = roundf(INNER * clampf(fill, 0.0, 1.0))
	d["bar_text"].text = text


## The tiles' words: [[key, [long, shorter...]], ...].
func _tiles(tiles: Array, rows: Array) -> void:
	for k in range(tiles.size()):
		if k < rows.size():
			UI.set_tile(tiles[k], rows[k][0], rows[k][1])
		else:
			UI.set_tile(tiles[k], "", [""])


func _show_pick(m: Dictionary) -> void:
	var it := _picked_item(m)
	_say(it)
	_ditch.visible = not it.is_empty()
	_take.visible = false
	for l in _pick_lines:
		l.text = ""
	for l in _pick_right:
		l.text = ""
	_pick_head.visible = not it.is_empty()
	_pick_title.visible = it.is_empty()
	if it.is_empty():
		_pick_title.text = "The pack: %d of %d cells" % [sim.pack_used(m), sim.capacity()]
		_pick_lines[0].text = "A rifle is four cells by one, armour three by three, a med or a part one"
		if sim.pack_used(m) >= sim.capacity():
			var cheap: Dictionary = sim.cheapest_in_pack()
			_pick_lines[1].text = "Full: a better find swaps out the cheapest thing at least its size"
			_pick_lines[2].text = "Cheapest now: %s, %s" % [cheap["base"].to_lower(), Fmt.money(sim.sell_price(cheap))] if not cheap.is_empty() else ""
		else:
			_pick_lines[1].text = "%d cell%s free" % [sim.capacity() - sim.pack_used(m), "" if sim.capacity() - sim.pack_used(m) == 1 else "s"]
		_hint.text = "Pick a cell for its figures; Select many ditches a few at once" if m["found"].size() > 0 else "Nothing found yet"
		_hint.size.x = GRID_W - 2 * PAD
		return
	var tail = ""
	if Items.is_gun(it):
		tail = [Items.fitted_words(it), Items.ammo_words(it).to_lower().replace("smg", "SMG")]
	elif Items.is_attachment(it) and not Items.is_socketable(it):
		tail = Items.att_words(it, true, true)
	_pick_head.show_item(it, sim, tail)
	# the right column: the fence's price, and what's fitted in its slot
	_pick_right[0].text = "The fence pays %s" % Fmt.money(sim.sell_price(it))
	var fitted = sim.equipped.get(it["slot"], null) if it["slot"] in Data.SLOTS else null
	if fitted != null:
		UI.fit(_pick_right[1], ["Fitted now: %s, %s %s" % [Items.full_name(fitted), Items.headline(fitted)[0], Items.headline(fitted)[1]],
			"Fitted now: %s, %s %s" % [fitted["base"], Items.headline(fitted)[0], Items.headline(fitted)[1]], "Fitted now: %s" % fitted["base"]])
		UI.fit(_pick_right[2], Items.affix_options(fitted))
	elif it["slot"] in Data.SLOTS:
		_pick_right[1].text = "Nothing fitted as %s" % it["slot"].to_lower()
	var cells_words := "%d cell%s" % [Items.size(it), "" if Items.size(it) == 1 else "s"]
	_ditch.text = "Ditch %s" % it["base"].to_lower()
	_ditch.size.x = ceilf(UI.text_width(_ditch, _ditch.text)) + 48
	_ditch.position.x = GRID_W - PAD - _ditch.size.x
	var left_edge: float = _ditch.position.x
	# a med or rounds found out there can go in the rig now, if there's a pouch
	_take.visible = Items.is_medical(it) or Items.is_ammo(it)
	if _take.visible:
		var room: bool = sim.rig_room(Items.size(it)) or sim.rig_tops_up(it)
		_take.text = "Take into the rig" if room else ("No rig fitted" if sim.med_capacity() == 0 else "The rig is full")
		_take.disabled = not room
		_take.size.x = ceilf(UI.text_width(_take, _take.text)) + 48
		_take.position.x = _ditch.position.x - 12 - _take.size.x
		left_edge = _take.position.x
	_hint.size.x = left_edge - PAD - 12
	UI.fit(_hint, ["Ditched is gone; it frees %s" % cells_words, "Ditched frees %s" % cells_words, "Frees %s" % cells_words])


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
	var local := Vector2(PAD + 60 + randf() * (INNER - 120), bar_y - 6 + randf_range(-16.0, 16.0))
	return _left.global_position + local - (juice.global_position if juice != null else Vector2.ZERO)


## The rig in the Runner panel: a cell a pouch, the pouches' outlines for the empty ones.
func _show_rig() -> void:
	var cap: int = mini(RIG_MAX, sim.med_capacity())
	var cell: int = Pal.CELL if cap <= 8 else maxi(28, int((INNER + Pal.CELL_GAP) / cap) - Pal.CELL_GAP)
	var k := 0
	for it in sim.rig:
		if k >= cap:
			break
		var c = _rig_cells[k]
		c.position = Vector2(PAD + k * (cell + Pal.CELL_GAP), RIG_Y)
		var lit: bool = Items.is_medical(it) and sim.hp / sim.max_hp() <= 0.35 and sim.mission["using"] == null
		c.show_item(it, lit, Vector2(cell, cell))
		c.visible = true
		k += 1
	var filled := k
	for i in range(RIG_MAX):
		_rig_cells[i].visible = i < filled
		var o = _rig_outlines[i]
		o.visible = i >= filled and i < cap
		o.position = Vector2(PAD + i * (cell + Pal.CELL_GAP), RIG_Y)
		o.size = Vector2(cell, cell)


func _rig_pressed(k: int) -> void:
	if k < sim.rig.size() and Items.is_medical(sim.rig[k]) and sim.on_mission():
		sim.use_med(sim.rig[k]["id"])
		acted.emit()


func _take_pick() -> void:
	if not sim.on_mission():
		return
	var it := _picked_item(sim.mission)
	if not it.is_empty() and sim.take_from_pack(it["id"]):
		_inv.selected = -1
		acted.emit()


func _get_out() -> void:
	sim.extract_now()
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
	acted.emit()


func _on_inv_pick(_id: int) -> void:
	acted.emit()


func _on_inv_acted() -> void:
	acted.emit()


## For the tests: every label and visible button with text.
## The item's own line, under the figures: who it was, where it came from.
func _say(it: Dictionary) -> void:
	UI.fit_sentences(_words[0], "" if it.is_empty() else (Words.UNIQUES.get(it["unique"], Words.item_words(it["base"])) if it.has("unique") else Words.item_words(it["base"])))
	_words[1].text = ""


func text_nodes() -> Array:
	var out: Array = [_pick_title, _hint]
	out.append_array(_words)
	out.append_array(_pick_lines)
	out.append_array(_pick_right)
	if _pick_head.visible:
		out.append_array(_pick_head.text_nodes())
	if _ditch.visible:
		out.append(_ditch)
	if _take.visible:
		out.append(_take)
	out.append_array(_band.text_nodes())
	out.append_array([_fight["head"], _fight["bar_text"], _runner["head"], _runner["bar_text"], _runner["note"], _rig_head, _take_head, _note])
	for t in _fight["tiles"] + _runner["tiles"] + _take_tiles:
		out.append_array([t["key"], t["value"]])
	for b in [_button, _button2]:
		if b.visible:
			out.append(b)
	out.append_array(_inv.text_nodes())
	return out


## Label + value pairs that share a line, and the headline + unit, for the fit check.
func line_pairs() -> Array:
	var out := []
	if _pick_head.visible:
		out.append_array(_pick_head.line_pairs())
	out.append([_band.headline, _band.unit])
	return out
