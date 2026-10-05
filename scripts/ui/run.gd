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

const BODY_W := Inventory.SIDE_W                              # 608
const GAP := 24
const PANEL_GAP := 12
const THEM_H := 244                                           # no button: three lines and a note
const GRID_X := BODY_W + GAP
const GRID_W := Inventory.WIDTH                                # 904
const GRID_H := Inventory.HEIGHT                               # 588
const PICK_Y := GRID_H + GAP                                  # 612
const PICK_H := Pal.ROOM_H - PICK_Y                           # 304
const RUN_Y := PICK_Y                                         # the run's panel, its top level with the pack's
const RUN_H := PICK_H
const RUNNER_Y := THEM_H + PANEL_GAP                          # 256
const RUNNER_H := RUN_Y - PANEL_GAP - RUNNER_Y                # 344: two lines, a note, the rig's pouches, a button
const RIG_Y := 216                                            # the pouches' row in the Runner panel, under the note
const RUNNER_FOOT := 12                                       # the Runner panel's button sits lower, to make the pouches room
const RIG_MAX := 18
const PAD := 20
const INNER := BODY_W - 2 * PAD
const LINE_H := 30                                            # a 24 px font is 29 tall
const BAR_H := 26
const LINES := 3
const TITLE_Y := 6
const HEAD_Y := 40
const BAR_Y := 86
const LINES_Y := 116
const NOTE_Y := LINES_Y + 3 * LINE_H + 2                      # 204 in Them
const NOTE_Y_BUTTON := LINES_Y + 2 * LINE_H + 2               # 174 above a button

var sim
var _panels: Array = []            # three: {panel, title, head, unit, track, fill, bar_text, lines[], note, status, button}
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
	for i in range(3):
		var y: int = [0, RUNNER_Y, RUN_Y][i]
		var h: int = [THEM_H, RUNNER_H, RUN_H][i]
		var button_y: int = h - (RUNNER_FOOT if i == 1 else PAD) - Pal.BUTTON_H
		var p := UI.panel(self, Rect2(0, y, BODY_W, h), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
		var d := {"panel": p}
		d["title"] = UI.label(p, Rect2(PAD, TITLE_Y, INNER, 28), "", "SemiBold", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		d["head"] = UI.label(p, Rect2(PAD, HEAD_Y, INNER, 40), "", "SemiBold", Pal.HEADLINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		d["unit"] = UI.label(p, Rect2(PAD, HEAD_Y, INNER, 40), "", "Medium", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		var track := UI.panel(p, Rect2(PAD, BAR_Y, INNER, BAR_H), UI.box(Pal.BG, 6))
		d["track"] = track
		d["fill"] = UI.panel(track, Rect2(0, 0, 0, BAR_H), UI.box(Pal.ACCENT, 6))
		d["bar_text"] = UI.label(track, Rect2(0, 0, INNER, BAR_H), "", "Medium", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		var lines := []
		for k in range(LINES):
			var ly := LINES_Y + k * LINE_H
			lines.append([UI.label(p, Rect2(PAD, ly, INNER, LINE_H), "", "Regular", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false),
				UI.label(p, Rect2(PAD, ly, INNER, LINE_H), "", "Medium", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)])
		d["lines"] = lines
		# a panel with a button shows two lines and its note above the button;
		# one without shows three, a note and a status line
		var has_button := i > 0
		d["note"] = UI.label(p, Rect2(PAD, NOTE_Y_BUTTON if has_button else NOTE_Y, INNER, LINE_H), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		d["status"] = UI.label(p, Rect2(PAD, 0, INNER, LINE_H), "", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		d["status"].visible = false      # Them's note carries its status now
		if has_button:
			lines[2][0].visible = false
			lines[2][1].visible = false
		var b := UI.button(p, Rect2(PAD, button_y, INNER, Pal.BUTTON_H), true)
		b.visible = false
		d["button"] = b
		var b2 := UI.button(p, Rect2(PAD, button_y, INNER, Pal.BUTTON_H), false)
		b2.visible = false
		d["button2"] = b2
		_panels.append(d)
	_head_face = People.rect(_panels[0]["panel"], Vector2(BODY_W - PAD - 64, TITLE_Y), 0.5)
	# the rig's pouches in the Runner panel: what's carried, a cell a pouch;
	# a med's cell uses that med
	for k in range(RIG_MAX):
		var o := UI.panel(_panels[1]["panel"], Rect2(PAD, RIG_Y, Pal.CELL, Pal.CELL), UI.box(Color.TRANSPARENT, 6, 1, Pal.CARD_LINE))
		o.visible = false
		o.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rig_outlines.append(o)
		var c := ItemCell.new()
		c.position = Vector2(PAD, RIG_Y)
		c.visible = false
		c.pressed.connect(_rig_pressed.bind(k))
		_panels[1]["panel"].add_child(c)
		_rig_cells.append(c)
	_panels[1]["button"].visible = false        # the pouches are the controls: a med's cell uses it
	_panels[2]["button"].pressed.connect(_get_out)
	_panels[2]["button2"].pressed.connect(_stop_auto)
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
	# them
	var them: Dictionary = _panels[0]
	them["title"].text = "Them"
	var boss_on: bool = m.has("boss") and m["boss"]["started"] and m["boss"]["alive"]
	People.show(_head_face, m["boss"]["name"] if boss_on else "")
	if boss_on:
		them["title"].text = m["boss"]["name"]
		_head(them, "1", "on you: the crew's head")
		_bar(them, clampf(m["target_hp"] / float(m["boss"]["hp"]), 0.0, 1.0), "Their HP %d / %d" % [ceili(m["target_hp"]), int(m["boss"]["hp"])], "bad")
		_lines(them, [["Incoming", "%.1f/s" % m["last_incoming"]], ["Your fire", "%.0f/s" % (sim.dps() * sim.pace())], ["Kills", "%d" % m["kills"]]])
		them["note"].text = "The boss"
	elif m["remaining"] > 0:
		var on_you: int = mini(m["remaining"], sim.contact(t))
		_head(them, "%d" % on_you, ("on you, %d more" % (m["remaining"] - on_you)) if m["remaining"] > on_you else ("on you" if on_you > 1 else "left"))
		_bar(them, clampf(m["target_hp"] / t["hp"], 0.0, 1.0), "Their HP %d / %d" % [ceili(m["target_hp"]), int(t["hp"])], "bad")
		_lines(them, [["Incoming", "%.1f/s" % m["last_incoming"]], ["Your fire", "%.0f/s" % (sim.dps() * sim.pace())], ["Kills", "%d" % m["kills"]]])
		them["note"].text = "Gang %d" % m["patrols"] if m["cleared"] else ("The fight; then %s" % m["boss"]["name"].to_lower() if m.has("boss") and m["boss"]["alive"] else "The fight")
	else:
		_head(them, "Clear", "")
		_bar(them, clampf(m["search"] / sim.search_s(t), 0.0, 1.0), "Picking it over", "good")
		var next: float = sim.patrol_s(t, m["patrols"] == 0) - m["patrol_timer"]
		_lines(them, [["Next gang in", Fmt.mss(next) if next < 1e8 else "never"], ["Gangs so far", "%d" % m["patrols"]], ["Kills", "%d" % m["kills"]]])
		them["note"].text = "Each gang that comes is bigger than the last"
	# the runner
	var op: Dictionary = _panels[1]
	op["title"].text = "Runner"
	_head(op, "%d" % sim.hp_shown(), "of %d HP" % sim.max_hp_shown())
	_bar(op, clampf(sim.hp / sim.max_hp(), 0.0, 1.0), "Your HP %d / %d" % [sim.hp_shown(), sim.max_hp_shown()], "bad" if low else "good")
	var on_you_words: Array = sim.dots_on_you()
	_lines(op, [["Armour", "%.0f (%s)" % [sim.armour(), Fmt.pct(sim.mitigation())]], ["Damage", "%.0f/s" % (sim.dps() * sim.pace())],
		["On you", ", ".join(on_you_words).capitalize()] if not on_you_words.is_empty() else ["", ""]])
	var med_sig := ""
	if m["using"] != null:
		op["note"].text = "%s, %.0f s to go" % [m["using"]["name"], ceilf(m["using"]["left"])]
		med_sig = "using"
	elif sim.first_med().is_empty():
		op["note"].text = _rounds_words("No meds")
		med_sig = "none"
	else:
		UI.fit(op["note"], [_rounds_words("%d med%s" % [sim.meds_carried(), "" if sim.meds_carried() == 1 else "s"]) + " · press a pouch to use one",
				_rounds_words("%d med%s" % [sim.meds_carried(), "" if sim.meds_carried() == 1 else "s"])])
		med_sig = "use:" + sim.first_med()["base"]
	_show_rig()
	# the run
	var run: Dictionary = _panels[2]
	run["title"].text = t["name"]
	_head(run, Fmt.mss(m["elapsed"]), "depth %d" % t["depth"])
	_bar(run, (float(m["kills"]) / float(t["pool"])) if not m["cleared"] else 1.0, ("Cleared" if m["cleared"] else "%d of %d down" % [m["kills"], t["pool"]]), "")
	_lines(run, [["Cash", Fmt.money(m["cash"])], ["Passed over", "%d · swapped %d" % [m["left"], int(m.get("swapped", 0))]]])
	run["note"].text = "HP low: get out or lose it all" if low else ("Auto-run: leaving ends it" if sim.auto_tier >= 0 else
		("Pack full: a better find swaps in" if sim.pack_used(m) >= sim.capacity() else ("Push for loot, or go" if m["cleared"] else "Leaving keeps the loot")))
	run["note"].add_theme_color_override("font_color", Pal.BAD if low else Pal.TEXT_2)
	# the pack
	_inv.show_items(sim, m["found"], sim.pack_used(m), sim.capacity(), "Pack")
	_juice_tick(m)
	# buttons and the pick panel change rarely; a redraw under the mouse drops presses
	var sig := "%s|%s|%d|%d|%s|%d|%d" % [med_sig, str(sim.auto_tier >= 0), _inv.selected, m["found"].size(), str(low or m["cleared"]), sim.pack_used(m), sim.rig.size()]
	if sig == _shown:
		return
	_shown = sig
	var auto: bool = sim.auto_tier >= 0
	run["button"].text = "Get out now"
	run["button"].visible = true
	UI.style_button(run["button"], low or m["cleared"])
	run["button2"].visible = auto
	run["button2"].text = "Stop auto"
	if auto:
		run["button"].size.x = (INNER - 12) / 2
		run["button2"].position.x = PAD + run["button"].size.x + 12
		run["button2"].size.x = INNER - run["button"].size.x - 12
	else:
		run["button"].size.x = INNER
	_show_pick(m)


## The headline and its unit read as one line: "3 on you, 2 more", "80 of 100 HP".
func _head(d: Dictionary, head: String, unit: String) -> void:
	d["head"].text = head
	d["unit"].text = unit
	var w := ceilf(UI.text_width(d["head"], head)) + 10
	d["unit"].position.x = PAD + w
	d["unit"].size.x = INNER - w


func _bar(d: Dictionary, fill: float, text: String, tone: String) -> void:
	(d["fill"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.ACCENT if tone == "" else Pal.tone_color(tone)
	d["fill"].size.x = roundf(INNER * clampf(fill, 0.0, 1.0))
	d["bar_text"].text = text


func _lines(d: Dictionary, rows: Array) -> void:
	for k in range(LINES):
		d["lines"][k][0].text = rows[k][0] if k < rows.size() else ""
		d["lines"][k][1].text = rows[k][1] if k < rows.size() else ""


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
		_numbers_by(m.get("dealt_by", {}), _dealt_seen_by, _panels[0]["panel"], "", 100)
		_dealt_seen = dealt
	# and on your own bar: what you took, by type, and green for what came back - counted apart,
	# so a helmet's +1 a second shows among the hits even when the hits are winning
	var taken: float = float(m.get("taken", 0.0))
	var healed: float = float(m.get("healed", 0.0))
	if juice != null and float(m["elapsed"]) - _hp_at >= 0.5:
		var you: Panel = _panels[1]["panel"]
		var shown := false
		if taken - _taken_seen >= 1.0:
			_numbers_by(m.get("taken_by", {}), _taken_seen_by, you, "−", 40)
			_taken_seen = taken
			shown = true
		if healed - _healed_seen >= 1.0:
			var n: int = int(round(healed - _healed_seen))
			juice.number(_scatter(you), "+%d" % n, "good", n >= 40)
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
func _numbers_by(by: Dictionary, seen: Dictionary, panel: Panel, sign: String, big_at: int) -> void:
	for ty in Data.TYPES:
		var total: float = float(by.get(ty, 0.0))
		var n: int = int(floor(total - float(seen.get(ty, 0.0))))
		if n >= 1:
			juice.number(_scatter(panel), "%s%d" % [sign, n], ty, n >= big_at)
			seen[ty] = float(seen.get(ty, 0.0)) + n


## A spot along a panel's bar, at a different height each time, in the juice's own space.
func _scatter(panel: Panel) -> Vector2:
	var local := Vector2(PAD + 60 + randf() * (INNER - 120), BAR_Y - 6 + randf_range(-16.0, 16.0))
	return panel.global_position + local - (juice.global_position if juice != null else Vector2.ZERO)


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


## "2 meds · 38 rounds", or "2 meds · dry" when the primary has none left.
func _rounds_words(lead: String) -> String:
	var gun = sim.equipped["Primary"]
	if gun == null:
		return lead
	var n: int = sim.rounds_for(gun)
	return "%s · %s" % [lead, ("%d rounds" % n) if n > 0 else "primary dry"]
	acted.emit()


func _get_out() -> void:
	sim.extract_now()
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
	for d in _panels:
		out.append_array([d["title"], d["head"], d["unit"], d["bar_text"], d["note"], d["status"]])
		for pair in d["lines"]:
			out.append_array(pair)
		for key in ["button", "button2"]:
			if d[key].visible:
				out.append(d[key])
	out.append_array(_inv.text_nodes())
	return out


## Label + value pairs that share a line, and the headline + unit, for the fit check.
func line_pairs() -> Array:
	var out := []
	if _pick_head.visible:
		out.append_array(_pick_head.line_pairs())
	for d in _panels:
		out.append([d["head"], d["unit"]])
		for pair in d["lines"]:
			out.append(pair)
	return out
