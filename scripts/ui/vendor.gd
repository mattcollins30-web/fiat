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
const People := preload("res://scripts/ui/people.gd")

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
const TAB_H := 56
const SIDE_Y := TAB_H + 16                                    # the left column's own panel starts here
const SIDE_H := Pal.ROOM_H - SIDE_Y

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
var _side_title: Label
var _face: TextureRect             # the vendor, at the foot of the side panel
var _face_name: Label
var _said: Array[Label] = []       # what they said, three rows beside the face
var _visits := 0
var _said_n := 0
var _line := ""
var _lost_seen := -1               # the medic notices a new runner
var _town_said := false            # the fence, once, when the town opens
var _side_head: Label
var _side_unit: Label
var _side_track: Panel
var _side_fill: Panel
var _side_bar_text: Label
var _side_lines: Array = []        # [label, value] pairs
var _side_buttons: Array[Button] = []
var _side_actions: Array = []
var _panel: Panel
var _left_title: Label
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
	for k in range(3):
		var b := UI.button(self, Rect2(k * (INNER / 2 + 12) + 0, 0, (BODY_W - 12) / 2, TAB_H), k == 0)
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
	# the left column's panel: the vendor's own business
	_side = UI.panel(self, Rect2(0, SIDE_Y, BODY_W, SIDE_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_side_title = UI.label(_side, Rect2(PAD, 6, INNER, 28), "", "SemiBold", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_face = People.rect(_side, Vector2(PAD, SIDE_H - PAD - 128), 1)
	_face_name = UI.label(_side, Rect2(PAD + 128 + 16, SIDE_H - PAD - 128, INNER - 128 - 16, 28), "", "SemiBold", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_face_name.visible = false
	for i in range(3):
		var l := UI.label(_side, Rect2(PAD + 128 + 16, SIDE_H - PAD - 128 + 32 + i * 26, INNER - 128 - 16, 26), "", "Regular", 20, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		l.visible = false
		_said.append(l)
	_side_head = UI.label(_side, Rect2(PAD, 40, INNER, 40), "", "SemiBold", Pal.HEADLINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_side_unit = UI.label(_side, Rect2(PAD, 40, INNER, 40), "", "Medium", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_side_track = UI.panel(_side, Rect2(PAD, 86, INNER, 26), UI.box(Pal.BG, 6))
	_side_fill = UI.panel(_side_track, Rect2(0, 0, 0, 26), UI.box(Pal.GOOD, 6))
	_side_bar_text = UI.label(_side_track, Rect2(0, 0, INNER, 26), "", "Medium", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(6):
		var y := 120 + i * LINE_H
		_side_lines.append([UI.label(_side, Rect2(PAD, y, INNER, LINE_H), "", "Regular", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false),
			UI.label(_side, Rect2(PAD, y, INNER, LINE_H), "", "Medium", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)])
	for i in range(11):
		var b := UI.button(_side, Rect2(PAD, 0, INNER, 48), false)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_side_press.bind(i))
		b.visible = false
		_side_buttons.append(b)
		_side_actions.append(Callable())
	# the panel under the grid: the pick
	_panel = UI.panel(self, Rect2(GRID_X, PANEL_Y, GRID_W, PANEL_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_left_title = UI.label(_panel, Rect2(PAD, 10, COL_W, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_right_title = UI.label(_panel, Rect2(PAD * 2 + COL_W, 14, COL_W, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(PANEL_LINES):
		_left_lines.append(UI.label(_panel, Rect2(PAD, 48 + i * 28, COL_W, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		_right_lines.append(UI.label(_panel, Rect2(PAD * 2 + COL_W, 48 + i * 28, COL_W, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_hint = UI.label(_panel, Rect2(PAD, PANEL_H - 6 - 44, GRID_W - 2 * PAD, 44), "", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(2):
		_words.append(UI.label(_panel, Rect2(PAD, 162 + i * 20, GRID_W - 2 * PAD, 20), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	for i in range(3):
		var b := UI.button(_panel, Rect2(0, PANEL_H - 6 - 44, 200, 44), i == 0)
		b.pressed.connect(_press.bind(i))
		b.visible = false
		_buttons.append(b)
		_actions.append(Callable())


func setup(k: String) -> void:
	kind = k
	if kind == "fence":
		var tw := (BODY_W - 24) / 3
		for i in range(3):
			_tabs[i].position.x = i * (tw + 12)
			_tabs[i].size.x = tw
			_tabs[i].visible = true
	if kind == "clinic":
		_shelf.fixed_kind = Data.MEDICAL
		_stash.fixed_kind = Data.MEDICAL
	if People.show(_face, "medic" if kind == "clinic" else "fence"):
		_face_name.text = "The medic" if kind == "clinic" else "The fence"
		_face_name.visible = true


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
	var sig := _signature()
	if sig == _shown:
		return
	_shown = sig
	_tabs[0].text = "Shelf (%d)" % stock.size()
	_tabs[1].text = ("Stash (%d)" % sim.stash.size()) if kind == "fence" else ("Your meds (%d)" % _stash_meds())
	UI.style_button(_tabs[0], showing == "shelf")
	UI.style_button(_tabs[1], showing == "stash")
	if kind == "fence":
		_tabs[2].text = "Contracts"
		UI.style_button(_tabs[2], showing == "contracts")
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
		str(sim.hp >= sim.max_hp() - 0.5), str(int(sim.treat_cost() / 10)), str(sim.contracts), str(sim.mate), str(sim.notes)]
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
	_side_title.text = "Treatment"
	_side_head.text = "%d" % sim.hp_shown()
	_side_unit.text = "of %d HP" % sim.max_hp_shown()
	var w := ceilf(UI.text_width(_side_head, _side_head.text)) + 10
	_side_unit.position.x = PAD + w
	_side_unit.size.x = INNER - w
	var fill: float = clampf(sim.hp / sim.max_hp(), 0.0, 1.0)
	_side_fill.size.x = roundf(INNER * fill)
	(_side_fill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.GOOD if fill > 0.5 else Pal.WARN
	_side_bar_text.text = Fmt.pct(fill)
	_side_track.visible = true
	_side_head.visible = true
	_side_unit.visible = true


func _side_line(i: int, label: String, value: String) -> void:
	_side_lines[i][0].text = label
	_side_lines[i][1].text = value


func _side_button(i: int, y: float, text: String, action: Callable, enabled: bool, tone := "", primary := false) -> void:
	var b := _side_buttons[i]
	b.visible = true
	b.position.y = y
	b.text = text
	b.disabled = not enabled
	UI.style_button(b, primary, tone)
	_side_actions[i] = action


## The vendor's own business, down the left.
func _show_side() -> void:
	for pair in _side_lines:
		pair[0].text = ""
		pair[1].text = ""
	for b in _side_buttons:
		b.visible = false
	if kind == "clinic":
		var full: bool = sim.hp >= sim.max_hp() - 0.5
		_side_line(0, "Resting", "+%.1f HP a second" % sim.rest_rate())
		_side_line(1, "Treatment", Fmt.money(sim.treat_cost()) if not full else "not needed")
		_side_button(0, 120 + 2 * LINE_H + 8, "Fit for duty" if full else ("The runner is out" if sim.on_mission() else "Treat (%s)" % Fmt.money(sim.treat_cost())),
			sim.treat, not full and not sim.on_mission() and sim.cash >= sim.treat_cost(), "", not full)
		var y := 120 + 2 * LINE_H + 8 + 48 + 20
		_side_line(3, "The clinic", "level %d of %d" % [sim.medic_level, Data.MEDIC_LEVELS.size() - 1])
		_side_lines[3][0].position.y = y
		_side_lines[3][1].position.y = y
		y += LINE_H
		if sim.medic_cost() > 0:
			_side_line(4, "Next", "+%.1f HP/s, %d meds" % [Data.MEDIC_LEVELS[sim.medic_level + 1]["rest"], Data.MEDIC_LEVELS[sim.medic_level + 1]["stock"]])
			_side_lines[4][0].position.y = y
			_side_lines[4][1].position.y = y
			y += LINE_H + 8
			_side_button(1, y, "Upgrade (%s)" % Fmt.money(sim.medic_cost()), sim.upgrade_medic, sim.can_upgrade_medic())
		else:
			_side_line(4, "Fully kitted", "")
			_side_lines[4][0].position.y = y
			_side_lines[4][1].position.y = y
		return
	# the fence: sell by rarity, the shelf's size
	_side_title.text = "Sell by rarity"
	_side_head.visible = false
	_side_unit.visible = false
	_side_track.visible = false
	var counts := [0, 0, 0, 0]
	var worth := [0, 0, 0, 0]
	for it in sim.stash:
		counts[it["rarity"]] += 1
		worth[it["rarity"]] += sim.sell_price(it)
	var y := 40
	for r in range(4):
		_side_button(r, y, "%s: %d, %s" % [Data.RARITIES[r]["name"], counts[r], Fmt.money(worth[r])], sim.sell_rarity.bind(r), counts[r] > 0, ["", "good", "warn", "bad"][r])
		y += 48 + 8
	y += 8
	if sim.market_cost() > 0:
		_side_button(4, y, "Bigger shelf: %d for %s" % [Data.MARKET_LEVELS[sim.market_level + 1]["stock"], Fmt.money(sim.market_cost())], sim.upgrade_market, sim.can_upgrade_market())
		y += 48 + 12
	# boxes of standard rounds, without end: a cell in your stash each
	_side_line(0, "By the box", "to the stash")
	_side_lines[0][0].position.y = y
	_side_lines[0][1].position.y = y
	y += LINE_H + 4
	var k := 5
	for type in ["improvised", "shotgun", "rifle", "smg", "pistol"]:
		var box: Dictionary = sim.ammo_box(type)
		_side_button(k, y, "%s ×%d (%s)" % [box["name"], int(box["rounds"]), Fmt.money(sim.ammo_price(type))], sim.buy_ammo.bind(type), sim.cash >= sim.ammo_price(type) and sim.stash_room(1))
		k += 1
		y += 48 + 6


func _show_panel() -> void:
	for b in _buttons:
		b.visible = false
	for l in _left_lines:
		l.text = ""
	for l in _right_lines:
		l.text = ""
	var it := _selected_item()
	_say(it)
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
				var last: Dictionary = sim.rig.back()
				_button(0, "Leave %s" % last["base"].to_lower(), sim.leave.bind(last["id"]), not sim.on_mission() and sim.stash_room(1))
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
	UI.fit(_left_title, [Items.full_name(it), it["base"]])
	if Items.is_medical(it):
		UI.fit(_left_lines[0], ["Med · heals %.0f HP over %.0f s · 1 cell" % [Items.heal(it) * sim.cm("heal") * (1.0 + sim.tree_sum("heal_pct") / 100.0), sim.use_time(it)], "Med · heals %.0f HP over %.0f s" % [Items.heal(it) * sim.cm("heal") * (1.0 + sim.tree_sum("heal_pct") / 100.0), sim.use_time(it)]])
	elif Items.is_ammo(it):
		var h := Items.headline(it)
		UI.fit(_left_lines[0], ["%s · %s %s · 1 cell" % [Items.kind_words(it), h[0], h[1]], "%s · %s %s" % [Items.kind_words(it), h[0], h[1]]])
	else:
		UI.fit(_left_lines[0], Items.figure_options(it))
	UI.fit(_left_lines[1], Items.affix_options(it))
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
	else:
		_right_title.text = "Fitted at the bench"
		_right_lines[0].text = "Goes on a gun's %s mount" % it["mount"]
	if selected["kind"] == "shelf":
		var room: bool = sim.stash_room(Items.size(it))
		_left_lines[2].text = "They want %s" % Fmt.money(_price(it))
		_left_lines[3].text = ("" if room else "No room in your stash") if not Items.is_gun(it) or not room else Items.ammo_words(it)
		var action: Callable = sim.buy_clinic.bind(it["id"]) if kind == "clinic" else sim.buy_id.bind(it["id"])
		_button(0, "Buy for %s" % Fmt.money(_price(it)), action, sim.cash >= _price(it) and room)
	else:
		_left_lines[2].text = "The fence pays %s" % Fmt.money(sim.sell_price(it))
		if Items.is_gun(it):
			_left_lines[3].text = Items.ammo_words(it)
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
	UI.wrap(_words, "" if it.is_empty() else (Words.UNIQUES.get(it["unique"], Words.item_words(it["base"])) if it.has("unique") else Words.item_words(it["base"])))


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
	if not _face.visible:
		return
	UI.wrap(_said, _line)
	for l in _said:
		l.visible = l.text != ""


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
	var own: Array = [_face, _face_name]
	own.append_array(_said)
	for c in _side.get_children():
		if own.has(c) or not (c is Control) or not c.visible:
			continue
		if mine.intersects(Rect2(c.position, c.size)):
			return false
	return true


## For the tests: every label and visible button with text.
func text_nodes() -> Array:
	var out: Array = [_left_title, _right_title, _hint, _side_title]
	out.append_array(_words)
	if _face_name.visible:
		out.append(_face_name)
	for l in _said:
		if l.visible:
			out.append(l)
	if _side_head.visible:
		out.append_array([_side_head, _side_unit, _side_bar_text])
	for pair in _side_lines:
		out.append_array(pair)
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
	for pair in _side_lines:
		out.append(pair)
	if _side_head.visible:
		out.append([_side_head, _side_unit])
	return out
