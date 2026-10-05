extends Control
## A vendor's screen - the Fence and the Clinic share it. The grid on the
## right is either the vendor's shelf (what they have, so many, and no more
## until a run restocks it) or your stash, switched by two buttons at the top
## of the left column. Pick a cell on the shelf for its figures and Buy; pick
## one in the stash to Sell (or, at the clinic, Take into the rig). Under the
## grid the panel for the pick; with nothing picked, the vendor's own
## business: the Fence's sell-by-rarity and its bigger shelf, the Clinic's
## treatment and level. Fixed geometry inside the card grid's 1536 x 864.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const Inventory := preload("res://scripts/ui/inventory.gd")
const ItemHead := preload("res://scripts/ui/item_head.gd")
const People := preload("res://scripts/ui/people.gd")
const Band := preload("res://scripts/ui/band.gd")

const BODY_W := Inventory.SIDE_W                              # 608
const GAP := 24
const GRID_X := BODY_W + GAP
const GRID_W := Inventory.WIDTH
const GRID_H := Inventory.HEIGHT
const PANEL_Y := GRID_H + GAP
const PANEL_H := Pal.ROOM_H - PANEL_Y
const PAD := 20
const INNER := BODY_W - 2 * PAD
const LINE_H := 30
const PANEL_LINES := 4
const COL_W := (GRID_W - 3 * PAD) / 2
const TAB_H := 40                                             # the tabs, along the band's foot
const BAND_H := 200                                           # the vendor's band: the face, the name, the headline figure
const FACE := 116                                             # the portrait in the band
const TOP := BAND_H + 36                                      # the sections under the band and the vendor's line
const TILE_GAP := 8
const SIDE_TILES := 10                                        # the fence's tile-shaped buttons: four rarities, five boxes, the shelf

var kind := "fence"                # "fence" or "clinic"
var sim
var showing := "shelf"             # which grid: "shelf" or "stash"
var selected := {}                 # {"kind": "shelf"|"stash", "id": n}, or {}
var _tabs: Array[Button] = []
var _deals: Panel                  # the fence's contracts and the mate, in the grid's place
var _deal_rows: Array = []         # per contract: {title, pay, have, hand, pass}
var _mate_title: Label
var _mate_line: Label
var _mate_note: Label
var _mate_buy: Button
const DEAL_H := 150
var _shelf                         # the vendor's grid
var _stash                         # your grid
var _side: Panel
var _band: Band
var _side_title: Label             # the first section's head
var _face: TextureRect             # the vendor, in the band
var _said: Array[Label] = []       # what they said: one line under the band
var _heads: Array[Label] = []      # the section heads under the band
var _side_tiles: Array = []        # the fence's tile buttons: {button, key, value}
var _med_tiles: Array = []         # the clinic's: your meds by kind
var _side_tiles_c: Array = []      # the clinic's figures: resting, treatment, the clinic's level
var _visits := 0
var _said_n := 0
var _line := ""
var _lost_seen := -1               # the medic notices a new runner
var _town_said := false            # the fence, once, when the town opens
var _side_track: Panel
var _side_fill: Panel
var _side_bar_text: Label
var _side_buttons: Array[Button] = []
var _side_actions: Array = []
var _panel: Panel
var _left_title: Label             # the fence's or the rig's line with nothing picked; a pick shows the head
var _head                          # the pick's name, chips, headline and affix rows (item_head.gd)
var _left_lines: Array[Label] = []
var _right_title: Label
var _right_lines: Array[Label] = []
var _hint: Label
var _words: Array[Label] = []      # the item's own line, two rows under the figures
var _buttons: Array[Button] = []
var _actions: Array = []
var _shown := ""


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	# the left column: the band with the tabs along its foot, the vendor's business under it
	_side = UI.panel(self, Rect2(0, 0, BODY_W, Pal.ROOM_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_band = Band.new(BODY_W, BAND_H, 3)
	_side.add_child(_band)
	_face = People.rect(_band, Vector2(PAD, 16), FACE / 128.0)
	_band.portrait_width(FACE)
	_said.append(UI.label(_side, Rect2(PAD, BAND_H + 4, INNER, 26), "", "Regular", Pal.CELL_TEXT_BIG + 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false))
	for k in range(3):
		var b := UI.button(_side, Rect2(PAD + k * ((INNER - 8) / 2 + 8), BAND_H - 14 - TAB_H, (INNER - 8) / 2, TAB_H), k == 0)
		b.pressed.connect(_show.bind(["shelf", "stash", "contracts"][k]))
		b.visible = k < 2
		_tabs.append(b)
	# the contracts: three cards and the mate's, where the grid would be
	_deals = UI.panel(self, Rect2(GRID_X, 0, GRID_W, GRID_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_deals.visible = false
	for k in range(Data.CONTRACTS_OPEN):
		var y := PAD + k * DEAL_H
		var r := {}
		r["title"] = UI.label(_deals, Rect2(PAD, y, GRID_W - 2 * PAD, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["pay"] = UI.label(_deals, Rect2(PAD, y + 38, GRID_W - 2 * PAD - 420, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["have"] = UI.label(_deals, Rect2(PAD, y + 66, GRID_W - 2 * PAD - 420, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["hand"] = UI.button(_deals, Rect2(GRID_W - PAD - 200, y + 38, 200, Pal.BUTTON_H), true)
		r["hand"].text = "Hand in"
		r["hand"].pressed.connect(_hand_in.bind(k))
		r["pass"] = UI.button(_deals, Rect2(GRID_W - PAD - 200 - 12 - 180, y + 38, 180, Pal.BUTTON_H), false)
		r["pass"].text = "Turn it down"
		r["pass"].pressed.connect(_pass.bind(k))
		_deal_rows.append(r)
	var my := PAD + Data.CONTRACTS_OPEN * DEAL_H
	_mate_title = UI.label(_deals, Rect2(PAD, my, GRID_W - 2 * PAD, 36), "The fence's mate", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_mate_line = UI.label(_deals, Rect2(PAD, my + 38, GRID_W - 2 * PAD - 270, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_mate_note = UI.label(_deals, Rect2(PAD, my + 66, GRID_W - 2 * PAD - 270, 28), "A different one every %d runs. Notes, not cash." % Data.MATE_RUNS, "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_mate_buy = UI.button(_deals, Rect2(GRID_W - PAD - 250, my + 38, 250, Pal.BUTTON_H), true)
	_mate_buy.pressed.connect(_buy_mate)
	_shelf = Inventory.new()
	_shelf.position = Vector2(GRID_X, 0)
	_shelf.can_many = false
	_shelf.picked.connect(_on_pick.bind("shelf"))
	add_child(_shelf)
	_stash = Inventory.new()
	_stash.position = Vector2(GRID_X, 0)
	_stash.visible = false
	_stash.picked.connect(_on_pick.bind("stash"))
	_stash.acted.connect(_on_acted)
	add_child(_stash)
	# the vendor's own business, as sections under the band
	for i in range(4):
		var h := UI.head(_side, Rect2(PAD, TOP + i * 100, INNER, UI.HEAD_H), "")
		h.visible = false
		_heads.append(h)
	_side_title = _heads[0]
	# the clinic: the HP bar, three figures, your meds by kind
	_side_track = UI.panel(_side, Rect2(PAD, TOP + UI.HEAD_H + 2, INNER, 24), UI.box(Pal.BG, 6))
	_side_fill = UI.panel(_side_track, Rect2(0, 0, 0, 24), UI.box(Pal.GOOD, 6))
	_side_bar_text = UI.label(_side_track, Rect2(0, 0, INNER, 24), "", "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_side_tiles_c = UI.tile_row(_side, PAD, TOP + UI.HEAD_H + 2 + 24 + 6, INNER, 3)
	_med_tiles = UI.tile_row(_side, PAD, 0, INNER, 2) + UI.tile_row(_side, PAD, 0, INNER, 2)
	for t in _side_tiles_c + _med_tiles:
		t["panel"].visible = false
	for i in range(2):
		var b := UI.button(_side, Rect2(PAD, 0, INNER, 48), false)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_side_press.bind(i))
		b.visible = false
		_side_buttons.append(b)
	for i in range(SIDE_TILES + 2):
		_side_actions.append(Callable())
	# the fence: tile-shaped buttons, four rarities then the boxes and the bigger shelf
	for i in range(SIDE_TILES):
		var b := Button.new()
		b.position = Vector2(PAD, 0)
		b.size = Vector2(100, UI.TILE_H)
		b.text = ""
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_side_press.bind(i))
		b.visible = false
		_side.add_child(b)
		var t := {"button": b}
		t["key"] = UI.label(b, Rect2(10, 4, 80, 22), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		t["value"] = UI.label(b, Rect2(10, 26, 80, 30), "", "SemiBold", UI.TILE_TEXT, Pal.TEXT)
		_side_tiles.append(t)
	# the panel under the grid: the pick
	_panel = UI.panel(self, Rect2(GRID_X, PANEL_Y, GRID_W, PANEL_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_left_title = UI.label(_panel, Rect2(PAD, 10, COL_W, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_right_title = UI.label(_panel, Rect2(PAD * 2 + COL_W, 14, COL_W, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(PANEL_LINES):
		_left_lines.append(UI.label(_panel, Rect2(PAD, 48 + i * 28, COL_W, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		_right_lines.append(UI.label(_panel, Rect2(PAD * 2 + COL_W, 48 + i * 28, COL_W, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_head = ItemHead.new(COL_W, true)
	_head.position = Vector2(PAD, 10)
	_head.visible = false
	_panel.add_child(_head)
	_hint = UI.label(_panel, Rect2(PAD, PANEL_H - 6 - 44, GRID_W - 2 * PAD, 44), "", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(2):
		_words.append(UI.label(_panel, Rect2(PAD, 228 + i * 20, COL_W, 20), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	for i in range(3):
		var b := UI.button(_panel, Rect2(0, PANEL_H - 6 - 44, 200, 44), i == 0)
		b.pressed.connect(_press.bind(i))
		b.visible = false
		_buttons.append(b)
		_actions.append(Callable())


func setup(k: String) -> void:
	kind = k
	if kind == "fence":
		var tw := (INNER - 16) / 3
		for i in range(3):
			_tabs[i].position.x = PAD + i * (tw + 8)
			_tabs[i].size.x = tw
			_tabs[i].visible = true
			_tabs[i].add_theme_font_size_override("font_size", 22)
	if kind == "clinic":
		_shelf.fixed_kind = Data.MEDICAL
		_stash.fixed_kind = Data.MEDICAL
	if not People.show(_face, "medic" if kind == "clinic" else "fence"):
		_band.portrait_width(0)           # no art yet: the words take the band


# ------------------------------------------------------------------ showing

func _stock() -> Array:
	return sim.clinic if kind == "clinic" else sim.market


func _price(it: Dictionary) -> int:
	return sim.clinic_price(it) if kind == "clinic" else sim.price(it)


func show_state(s) -> void:
	sim = s
	if _line == "" and visible:
		_visits += 1                      # shown before the sim arrived: the first visit's line now
		_on_visit()
	var stock := _stock()
	var cells := 0
	for it in stock:
		cells += Items.size(it)
	var shelf_cap: int = Data.MEDIC_LEVELS[sim.medic_level]["stock"] if kind == "clinic" else cells
	_shelf.show_items(sim, stock, cells, maxi(shelf_cap, cells), "Shelf")
	_stash.show_items(sim, sim.stash, sim.stash_used(), sim.stash_cap(), "Stash")
	_shelf.visible = showing == "shelf"
	_stash.visible = showing == "stash"
	_deals.visible = showing == "contracts"
	if kind == "clinic":
		_show_treatment()                 # HP moves while resting: every refresh
		for t in _side_tiles_c:
			if t["panel"].visible and t["key"].text == "Treatment":
				var full_now: bool = sim.hp >= sim.max_hp() - 0.5
				UI.set_tile(t, "Treatment", ["not needed" if full_now else Fmt.money(sim.treat_cost())], Pal.TEXT_2 if full_now else Pal.TEXT)
	var sig := _signature()
	if sig == _shown:
		return
	_shown = sig
	_tabs[0].text = "Shelf (%d)" % stock.size()
	_tabs[1].text = ("Stash (%d)" % sim.stash.size()) if kind == "fence" else ("Your meds (%d)" % _stash_meds())
	UI.style_button(_tabs[0], showing == "shelf")
	UI.style_button(_tabs[1], showing == "stash")
	if kind == "fence":
		var ready := 0
		var unique_pay := 0
		for k in range(sim.contracts.size()):
			if sim.can_hand_in(k):
				ready += 1
			elif sim.contracts[k].get("pay", "") == "unique":
				unique_pay += 1
		_tabs[2].text = ("Contracts ✓%d" % ready) if ready > 0 else (("Contracts ★") if unique_pay > 0 else "Contracts (%d)" % sim.contracts.size())
		UI.style_button(_tabs[2], showing == "contracts", "good" if (ready > 0 and showing != "contracts") else "")
		_show_deals()
	_show_side()
	_show_panel()


## The fence's contracts: what's wanted, what it pays, what you have.
func _show_deals() -> void:
	for k in range(Data.CONTRACTS_OPEN):
		var r: Dictionary = _deal_rows[k]
		if k >= sim.contracts.size():
			for key in ["title", "pay", "have"]:
				r[key].text = ""
			r["hand"].visible = false
			r["pass"].visible = false
			continue
		var c: Dictionary = sim.contracts[k]
		UI.fit(r["title"], [_cap(Words.CONTRACT_ASKS[(k + sim.runs_total) % Words.CONTRACT_ASKS.size()] % sim.contract_words(c)), _cap(sim.contract_words(c))])
		r["pay"].text = "Pays %s" % sim.contract_pay_words(c) if c["pay"] != "unique" else "Pays with %s" % c["unique"]
		var have: int = sim.contract_items(c).size()
		r["have"].text = "You have %d of %d in the stash" % [have, int(c["count"])] if have < int(c["count"]) else "Ready: the cheapest %d that fit go" % int(c["count"])
		r["hand"].visible = true
		r["hand"].disabled = not sim.can_hand_in(k)
		r["pass"].visible = true
		r["pass"].disabled = sim.on_mission()
	if sim.mate.is_empty():
		_mate_line.text = "Not about."
		_mate_buy.visible = false
	else:
		UI.fit(_mate_line, ["%s, for %d notes. You have %d." % [sim.mate["unique"], int(sim.mate["notes"]), sim.notes], "%s: %d notes, you have %d" % [sim.mate["unique"], int(sim.mate["notes"]), sim.notes]])
		_mate_buy.visible = true
		_mate_buy.text = "Buy for %d notes" % int(sim.mate["notes"])
		_mate_buy.disabled = not sim.can_buy_mate()


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


func _hand_in(k: int) -> void:
	if sim.hand_in(k):
		_says("contract")
		acted.emit()
	_shown = ""
	show_state(sim)


func _pass(k: int) -> void:
	sim.pass_contract(k)
	_shown = ""
	show_state(sim)


func _buy_mate() -> void:
	if sim.buy_mate():
		_says("mate")
		acted.emit()
	_shown = ""
	show_state(sim)


func _stash_meds() -> int:
	var n := 0
	for it in sim.stash:
		if Items.is_medical(it):
			n += 1
	return n


func _signature() -> String:
	var parts := [kind, showing, str(selected), str(sim.on_mission()), str(int(sim.cash)), str(_stash.many), str(sim.market_level), str(sim.medic_level),
		str(sim.hp >= sim.max_hp() - 0.5), str(int(sim.treat_cost() / 10)), str(sim.contracts), str(sim.mate), str(sim.notes),
		str(hash(sim.tree)), sim.cls]          # the tree and the class move the heal and rest figures
	for it in _stock():
		parts.append("m" + str(it["id"]))
	for it in sim.stash:
		parts.append(str(it["id"]))
	for it in sim.rig:
		parts.append("r" + str(it["id"]))
	for s in Data.SLOTS:
		parts.append(str(sim.equipped[s]["id"]) if sim.equipped[s] != null else "-")
	return "|".join(parts)


## The clinic's treatment block, at the top of the side panel.
func _show_treatment() -> void:
	var full: bool = sim.hp >= sim.max_hp() - 0.5
	_band.set_words("The clinic · level %d of %d" % [sim.medic_level, Data.MEDIC_LEVELS.size() - 1], "The medic", "%d" % sim.hp_shown(),
		["of %d HP · %s" % [sim.max_hp_shown(), "fit for duty" if full else ("out on a run" if sim.on_mission() else "resting")], "of %d HP" % sim.max_hp_shown()], Pal.GOOD if full else Pal.ACCENT)
	_band.headline_under_title(true)
	_side_title.text = "TREATMENT"
	_side_title.visible = true
	var fill: float = clampf(sim.hp / sim.max_hp(), 0.0, 1.0)
	_side_fill.size.x = roundf(INNER * fill)
	(_side_fill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.GOOD if fill > 0.5 else Pal.WARN
	_side_bar_text.text = "Your HP %d / %d" % [sim.hp_shown(), sim.max_hp_shown()]
	_side_track.visible = true


func _side_button(i: int, y: float, text: String, action: Callable, enabled: bool, tone := "", primary := false) -> void:
	var b := _side_buttons[i]
	b.visible = true
	b.position.y = y
	b.text = text
	b.disabled = not enabled
	UI.style_button(b, primary, tone)
	_side_actions[i] = action


## A tile-shaped button: its key over its figure, the figure in a tone; `w` wide at (x, y).
func _side_tile(i: int, x: float, y: float, w: float, key: String, options: Array, tone: Color, action: Callable, enabled: bool) -> void:
	var t: Dictionary = _side_tiles[i]
	var b: Button = t["button"]
	b.visible = true
	b.position = Vector2(x, y)
	b.size = Vector2(w, UI.TILE_H)
	b.disabled = not enabled
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(state, UI.box(Pal.BG if state != "hover" else Pal.SELECT, 6))
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 6, 2, Pal.TEXT))
	t["key"].size.x = w - 20
	t["value"].size.x = w - 20
	t["key"].text = key
	UI.fit(t["value"], options)
	t["value"].add_theme_color_override("font_color", tone if enabled else Pal.TEXT_3)
	t["key"].add_theme_color_override("font_color", Pal.TEXT_2 if enabled else Pal.TEXT_3)
	_side_actions[i] = action


## The vendor's own business, down the left, under the band.
func _show_side() -> void:
	for b in _side_buttons:
		b.visible = false
	for t in _side_tiles:
		t["button"].visible = false
	for t in _side_tiles_c + _med_tiles:
		t["panel"].visible = false
	for h in _heads:
		h.visible = false
	_side_track.visible = false
	if kind == "clinic":
		_show_treatment()
		var full: bool = sim.hp >= sim.max_hp() - 0.5
		var y: float = TOP + UI.HEAD_H + 2 + 24 + 6
		for t in _side_tiles_c:
			t["panel"].visible = true
		UI.set_tile(_side_tiles_c[0], "Resting", ["+%.1f HP a second" % sim.rest_rate(), "+%.1f HP/s" % sim.rest_rate()])
		UI.set_tile(_side_tiles_c[1], "Treatment", ["not needed" if full else Fmt.money(sim.treat_cost())], Pal.TEXT_2 if full else Pal.TEXT)
		if sim.medic_cost() > 0:
			UI.set_tile(_side_tiles_c[2], "Clinic", ["level %d of %d" % [sim.medic_level, Data.MEDIC_LEVELS.size() - 1], "level %d" % sim.medic_level])
		else:
			UI.set_tile(_side_tiles_c[2], "Clinic", ["fully kitted", "level %d" % sim.medic_level], Pal.GOOD)
		y += UI.TILE_H + 10
		_side_button(0, y, "Fit for duty" if full else ("The runner is out" if sim.on_mission() else "Treat (%s)" % Fmt.money(sim.treat_cost())),
			sim.treat, not full and not sim.on_mission() and sim.cash >= sim.treat_cost(), "", not full)
		y += 48 + 8
		if sim.medic_cost() > 0:
			var nxt: Dictionary = Data.MEDIC_LEVELS[sim.medic_level + 1]
			_side_button(1, y, "Upgrade (%s): +%.1f HP/s, %d meds" % [Fmt.money(sim.medic_cost()), nxt["rest"], nxt["stock"]], sim.upgrade_medic, sim.can_upgrade_medic())
			y += 48 + 8
		# your meds, by kind: what each heals for you, and how many there are
		y += 8
		_heads[1].position.y = y
		_heads[1].text = "YOUR MEDS · IN THE STASH, WHAT EACH DOES FOR YOU"
		_heads[1].visible = true
		y += UI.HEAD_H + 2
		var counts := {}
		var order := []
		for it in sim.stash:
			if Items.is_medical(it):
				if not counts.has(it["base"]):
					counts[it["base"]] = {"n": 0, "it": it}
					order.append(it["base"])
				counts[it["base"]]["n"] += 1
		for k in range(_med_tiles.size()):
			var t: Dictionary = _med_tiles[k]
			t["panel"].position.y = y + (k / 2) * (UI.TILE_H + TILE_GAP)
			if k < order.size():
				var it: Dictionary = counts[order[k]]["it"]
				var heal: float = Items.heal(it) * sim.cm("heal") * (1.0 + sim.tree_sum("heal_pct") / 100.0)
				t["panel"].visible = true
				UI.set_tile(t, "%s ×%d" % [order[k], counts[order[k]]["n"]], ["heals %.0f over %.0f s" % [heal, sim.use_time(it)], "heals %.0f" % heal])
			elif k == order.size():
				t["panel"].visible = true
				UI.set_tile(t, "The rig", ["%d of %d pouches" % [sim.rig_used(), sim.med_capacity()], "%d of %d" % [sim.rig_used(), sim.med_capacity()]] if sim.med_capacity() > 0 else ["no rig fitted"], Pal.TEXT if sim.med_capacity() > 0 else Pal.TEXT_3)
		return
	# the fence: the band, then sell by rarity, the boxes and the shelf, the contracts
	var worth_all := 0
	for it in sim.stash:
		worth_all += sim.sell_price(it)
	_band.set_words("The fence · %s" % ("prices up %d%%" % sim.inflation_pct() if sim.inflation_pct() > 0 else "pays worth, asks three times"), "The fence",
		Fmt.money(worth_all), ["for the lot · %d in the stash" % sim.stash.size(), "for the lot of %d" % sim.stash.size(), "for the lot"], Pal.ACCENT)
	_band.headline_under_title(true)
	_side_title.text = "SELL BY RARITY"
	_side_title.visible = true
	var counts := [0, 0, 0, 0]
	var worth := [0, 0, 0, 0]
	for it in sim.stash:
		counts[it["rarity"]] += 1
		worth[it["rarity"]] += sim.sell_price(it)
	var y: float = TOP + UI.HEAD_H + 2
	var tw4 := (INNER - 3 * TILE_GAP) / 4.0
	for r in range(4):
		var tone: Color = [Pal.TEXT, Pal.GOOD, Pal.WARN, Pal.BAD][r]
		_side_tile(r, PAD + r * (tw4 + TILE_GAP), y, tw4, Data.RARITIES[r]["name"], ["%d · %s" % [counts[r], Fmt.money(worth[r])], Fmt.money(worth[r])], tone, sim.sell_rarity.bind(r), counts[r] > 0)
	y += UI.TILE_H + 12
	_heads[1].position.y = y
	_heads[1].text = "BY THE BOX · TO THE STASH"
	_heads[1].visible = true
	y += UI.HEAD_H + 2
	# boxes of standard rounds, without end: a cell in your stash each; the bigger shelf beside them
	var tw3 := (INNER - 2 * TILE_GAP) / 3.0
	var k := 4
	var types := ["improvised", "shotgun", "rifle", "smg", "pistol"]
	for n in range(types.size()):
		var box: Dictionary = sim.ammo_box(types[n])
		_side_tile(k, PAD + (n % 3) * (tw3 + TILE_GAP), y + (n / 3) * (UI.TILE_H + TILE_GAP), tw3, "%s ×%d" % [box["name"], int(box["rounds"])], [Fmt.money(sim.ammo_price(types[n]))], Pal.TEXT,
			sim.buy_ammo.bind(types[n]), sim.cash >= sim.ammo_price(types[n]) and sim.stash_room(1))
		k += 1
	if sim.market_cost() > 0:
		_side_tile(k, PAD + 2 * (tw3 + TILE_GAP), y + UI.TILE_H + TILE_GAP, tw3, "Bigger shelf · %d" % Data.MARKET_LEVELS[sim.market_level + 1]["stock"], [Fmt.money(sim.market_cost())], Pal.ACCENT, sim.upgrade_market, sim.can_upgrade_market())
	else:
		_side_tile(k, PAD + 2 * (tw3 + TILE_GAP), y + UI.TILE_H + TILE_GAP, tw3, "Their shelf", ["%d, the biggest" % Data.MARKET_LEVELS[sim.market_level]["stock"], "the biggest"], Pal.TEXT_2, Callable(), false)
	y += 2 * UI.TILE_H + TILE_GAP + 12
	# the contracts, in brief: the tab has the lot
	_heads[2].position.y = y
	var ready := 0
	for c in range(sim.contracts.size()):
		if sim.can_hand_in(c):
			ready += 1
	_heads[2].text = ("THE CONTRACTS · %d OPEN, %d READY" % [sim.contracts.size(), ready]) if not sim.contracts.is_empty() else "THE CONTRACTS · NONE OPEN"
	_heads[2].visible = true


func _show_panel() -> void:
	for b in _buttons:
		b.visible = false
	for l in _left_lines:
		l.text = ""
	for l in _right_lines:
		l.text = ""
	var it := _selected_item()
	_say(it)
	_head.visible = not it.is_empty()
	_left_title.visible = it.is_empty()
	if it.is_empty():
		if kind == "clinic":
			_left_title.text = "The rig: %d of %d" % [sim.rig_used(), sim.med_capacity()]
			if sim.med_capacity() == 0:
				_left_lines[0].text = "No rig fitted - fit one in the lock-up to carry meds"
			elif sim.rig.is_empty():
				UI.fit(_left_lines[0], ["Nothing carried: take from Your meds", "Nothing carried: take from the grid", "Nothing carried"])
			else:
				var counts := {}
				var order := []
				for m in sim.rig:
					if not counts.has(m["base"]):
						counts[m["base"]] = 0
						order.append(m["base"])
					counts[m["base"]] += 1
				var words := []
				for name in order:
					words.append(name if counts[name] == 1 else "%s ×%d" % [name, counts[name]])
				UI.fit(_left_lines[0], [", ".join(words), "%d meds" % sim.rig.size()])
				UI.fit(_left_lines[1], ["Used under fire; first taken, first used", "Used under fire, first taken first"])
				UI.fit(_left_lines[2], ["Taken out again in the Lock-up, from the rig", "Taken out in the Lock-up"])
			_right_title.text = "The shelf: %d of %d" % [sim.clinic.size(), Data.MEDIC_LEVELS[sim.medic_level]["stock"]]
			_right_lines[0].text = "No more until the next run"
		else:
			_left_title.text = "The fence"
			if sim.inflation_pct() > 0:
				UI.fit(_left_lines[0], ["Prices up %d%% since the yard opened; notes hold" % sim.inflation_pct(), "Prices up %d%%; notes hold" % sim.inflation_pct()])
			else:
				UI.fit(_left_lines[0], ["Pays what a thing is worth; asks three times that", "Pays worth; asks three times"])
			_right_title.text = "Their shelf: %d of %d" % [sim.market.size(), Data.MARKET_LEVELS[sim.market_level]["stock"]]
			_right_lines[0].text = "No more until the next run"
		_hint.text = "Pick a cell on either grid"
		_lay_buttons()
		return
	_hint.text = ""
	# the left column is the head; the tail says what the runner would get out of it
	var tail = ""
	if Items.is_medical(it):
		tail = "heals %.0f for you, over %.0f s" % [Items.heal(it) * sim.cm("heal") * (1.0 + sim.tree_sum("heal_pct") / 100.0), sim.use_time(it)]
	elif Items.is_gun(it):
		tail = [Items.fitted_words(it), Items.ammo_words(it).to_lower().replace("smg", "SMG")]
	elif Items.is_attachment(it) and not Items.is_socketable(it):
		tail = Items.att_words(it, true, true)
	_head.show_item(it, sim, tail)
	var fitted = sim.equipped.get(it["slot"], null) if it["slot"] in Data.SLOTS else null
	if fitted != null:
		var fh := Items.headline(fitted)
		UI.fit(_right_title, ["Fitted now: " + fitted["base"], "Fitted: " + fitted["base"], "Fitted now"])
		_right_lines[0].text = "%s %s" % [fh[0], fh[1]]
		UI.fit(_right_lines[1], Items.affix_options(fitted))
		var gain := Items.score(it) - Items.score(fitted)
		_right_lines[2].text = "Sidegrade" if absf(gain) < 0.05 else ("▲ Better than it" if gain > 0 else "▼ Worse than it")
		_right_lines[2].add_theme_color_override("font_color", Pal.WARN if absf(gain) < 0.05 else (Pal.GOOD if gain > 0 else Pal.BAD))
	elif it["slot"] in Data.SLOTS:
		_right_title.text = "Nothing fitted as %s" % it["slot"].to_lower()
	elif Items.is_medical(it) or Items.is_ammo(it):
		_right_title.text = "The rig: %d of %d" % [sim.rig_used(), sim.med_capacity()]
	elif Items.is_socketable(it):
		UI.fit(_right_title, ["Fitted at the bench, Sockets view", "Fitted at the bench"])
		UI.wrap([_right_lines[0], _right_lines[1]], Items.socket_words(it))
	elif Items.is_paper(it):
		_right_title.text = "The drawer" if not Items.is_deeds(it) else "The deeds"
		if Items.is_deeds(it):
			UI.fit(_right_lines[0], ["Held, sold or burned: the ending", "Held, sold or burned"])
		elif it["base"] in sim.book:
			UI.fit(_right_lines[0], ["Read, and kept in the caravan's drawer", "Read; in the caravan's drawer", "In the drawer"])
		else:
			_right_lines[0].text = "Not read yet"
	elif it.has("mount"):
		_right_title.text = "Fitted at the bench"
		_right_lines[0].text = "Goes on %s" % Items.mount_words(it["mount"])
	else:
		_right_title.text = ""
	if selected["kind"] == "shelf":
		var room: bool = sim.stash_room(Items.size(it)) or sim._stack_room(it)
		if not room:
			_hint.text = "No room in your stash"
		elif sim.cash < _price(it):
			_hint.text = "Short by %s" % Fmt.money(_price(it) - sim.cash)
		var action: Callable = sim.buy_clinic.bind(it["id"]) if kind == "clinic" else sim.buy_id.bind(it["id"])
		_button(0, "Buy for %s" % Fmt.money(_price(it)), action, sim.cash >= _price(it) and room)
	else:
		if (kind == "clinic" and Items.is_medical(it)) or Items.is_ammo(it):
			var room: bool = sim.rig_room(Items.size(it))
			_right_lines[0].text = "" if room else ("No rig fitted" if sim.med_capacity() == 0 else ("The rig is full" if Items.size(it) == 1 else "No room: it takes %d pouches" % Items.size(it)))
			_button(0, "Take", sim.take.bind(it["id"]), not sim.on_mission() and room)
			_button(1, "Sell for %s" % Fmt.money(sim.sell_price(it)), sim.sell.bind(it), true)
		else:
			_button(0, "Sell for %s" % Fmt.money(sim.sell_price(it)), sim.sell.bind(it), true)
	_lay_buttons()


func _button(i: int, text: String, action: Callable, enabled: bool) -> void:
	var b := _buttons[i]
	b.visible = true
	b.text = text
	b.disabled = not enabled
	b.size.x = ceilf(UI.text_width(b, text)) + 48
	_actions[i] = action


## The item's own line, under the figures: who it was, where it came from.
func _say(it: Dictionary) -> void:
	UI.fit_sentences(_words[0], "" if it.is_empty() else (Words.UNIQUES.get(it["unique"], Words.item_words(it["base"])) if it.has("unique") else Words.item_words(it["base"])))
	_words[1].text = ""


func _lay_buttons() -> void:
	var x := GRID_W - PAD
	for i in range(_buttons.size() - 1, -1, -1):
		if _buttons[i].visible:
			x -= _buttons[i].size.x
			_buttons[i].position.x = x
			x -= 12
	_hint.size.x = maxf(100.0, x - PAD - 12)
	if x - PAD - 12 < ceilf(UI.text_width(_hint, _hint.text)):
		_hint.text = ""


func _selected_item() -> Dictionary:
	if selected.is_empty() or sim == null:
		return {}
	for it in (_stock() if selected["kind"] == "shelf" else sim.stash):
		if it["id"] == selected["id"]:
			return it
	return {}


# ------------------------------------------------------------------ acting

func _show(which: String) -> void:
	showing = which
	selected = {}
	_shelf.selected = -1
	_stash.selected = -1
	show_state(sim)


func _on_pick(id: int, which: String) -> void:
	if id >= 0:
		selected = {"kind": which, "id": id}
	elif _stash.many or _selected_item().is_empty():
		selected = {}
	show_state(sim)


func _on_acted() -> void:
	if _selected_item().is_empty():
		selected = {}
	acted.emit()


## What the fence or the medic says: a visit line when the screen opens,
## a word on a buy, a sell, a treatment, the town opening, a new runner.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible and sim != null:
		_visits += 1
		_on_visit()


func _on_visit() -> void:
	if kind == "clinic":
		if _lost_seen >= 0 and sim.operators_lost > _lost_seen:
			_line = Words.MEDIC["new_runner"]
		elif sim.hp < sim.max_hp() * 0.5:
			_line = Words.MEDIC["hurt"]
		else:
			_line = Words.rotate(Words.MEDIC["visit"], _visits - 1)
		_lost_seen = sim.operators_lost
	else:
		if sim.depot_cleared and not _town_said:
			_town_said = true
			_line = Words.FENCE["town"]
		else:
			_line = Words.rotate(Words.FENCE["visit"], _visits - 1)
	_show_said()


func _says(key: String) -> void:
	var book: Dictionary = Words.MEDIC if kind == "clinic" else Words.FENCE
	var v = book.get(key, "")
	_said_n += 1
	_line = Words.rotate(v, _said_n) if v is Array else str(v)
	_show_said()


func _show_said() -> void:
	UI.fit_sentences(_said[0], _line)


func _side_press(i: int) -> void:
	var was_hp: float = sim.hp
	var was_level: int = sim.medic_level + sim.market_level
	var was_n: int = sim.stash.size()
	if _side_actions[i].is_valid():
		_side_actions[i].call()
	if kind == "clinic" and sim.hp > was_hp:
		_says("fit" if sim.hp >= sim.max_hp() else "treated")
	elif sim.medic_level + sim.market_level > was_level:
		_says("shelf")
	elif sim.stash.size() < was_n:
		_says("sold")
	elif sim.stash.size() > was_n:
		_says("bought")
	if _selected_item().is_empty():
		selected = {}
	acted.emit()


func _press(i: int) -> void:
	var it := _selected_item()
	var was_n: int = sim.stash.size()
	var was_cash: float = sim.cash
	if _actions[i].is_valid():
		_actions[i].call()
	if sim.cash > was_cash:
		_says("deeds" if not it.is_empty() and Items.is_deeds(it) else ("papers" if not it.is_empty() and Items.is_paper(it) else "sold"))
	elif sim.cash < was_cash:
		_says("bought")
	if _selected_item().is_empty():
		selected = {}
		_shelf.selected = -1
		_stash.selected = -1
	acted.emit()


## For the tests: the vendor's face sits clear of everything else showing in
## the side panel (the fence's ammo buttons reach down towards it).
func face_clear() -> bool:
	if not _face.visible:
		return true
	var mine := Rect2(_face.position, _face.size)
	for c in _band.get_children():
		if c == _face or not (c is Control) or not c.visible or (c is Label and c.text == ""):
			continue
		if mine.intersects(Rect2(c.position, c.size)):
			return false
	for b in _tabs:
		if b.visible and mine.intersects(Rect2(b.position, b.size)):
			return false
	return true


## For the tests: every label and visible button with text.
func text_nodes() -> Array:
	var out: Array = [_left_title, _right_title, _hint]
	out.append_array(_words)
	if _head.visible:
		out.append_array(_head.text_nodes())
	out.append_array(_band.text_nodes())
	out.append_array(_said)
	for h in _heads:
		if h.visible:
			out.append(h)
	if _side_track.visible:
		out.append(_side_bar_text)
	for t in _side_tiles_c + _med_tiles:
		if t["panel"].visible:
			out.append_array([t["key"], t["value"]])
	for t in _side_tiles:
		if t["button"].visible:
			out.append_array([t["key"], t["value"]])
	for b in _side_buttons:
		if b.visible:
			out.append(b)
	for t in _tabs:
		if t.visible:
			out.append(t)
	if showing == "contracts":
		out.append_array([_mate_title, _mate_line, _mate_note])
		if _mate_buy.visible:
			out.append(_mate_buy)
		for r in _deal_rows:
			out.append_array([r["title"], r["pay"], r["have"]])
			for b in [r["hand"], r["pass"]]:
				if b.visible:
					out.append(b)
	out.append_array(_left_lines)
	out.append_array(_right_lines)
	for b in _buttons:
		if b.visible:
			out.append(b)
	if showing != "contracts":
		out.append_array((_shelf if showing == "shelf" else _stash).text_nodes())
	return out


func line_pairs() -> Array:
	var out := []
	if _head.visible:
		out.append_array(_head.line_pairs())
	out.append([_band.headline, _band.unit])
	return out
