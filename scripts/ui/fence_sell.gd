extends Control
## The Fence's side, on the shelf and the stash (19 Oct, Matt's Fence A): sell what you don't wear by rarity - a row a
## rarity with its pieces, what they fetch and Sell, the upgrades on what's worn kept back - and the rounds by the box,
## the ones your guns take first and lit, the rest named under them.
##
## Signals: `acted` after a sale or a box bought.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const Words := preload("res://scripts/sim/words.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")
const Arm := preload("res://scripts/ui/arm.gd")

const ROW_H := 50.0
const ROW_GAP := 6.0
const SELL_W := 96.0
const BOX_H := 158.0
const BOXES := 3
const TYPES := ["smg", "pistol", "rifle", "shotgun", "improvised"]

var sim
var _rows: Array = []               # a rarity each: {panel, dot, name, count, worth, sell}
var _box_head: Label
var _boxes: Array = []              # {panel, icon, name, line, buy, type}
var _rest: Label
var _head: Label
var _shown := ""


func _init(w: float) -> void:
	size = Vector2(w, 600)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_head = UI.head(self, Rect2(0, 0, w, UI.HEAD_H), "SELL WHAT YOU DON'T WEAR · BY RARITY")
	var y: float = UI.HEAD_H + 6
	for r in range(Data.RARITIES.size()):
		var row := {}
		row["panel"] = UI.panel(self, Rect2(0, y, w, ROW_H), UI.box(Pal.PANEL, 6))
		var p: Panel = row["panel"]
		row["dot"] = UI.panel(p, Rect2(12, (ROW_H - 12) / 2.0, 12, 12), UI.box(Pal.TEXT_2, 2))
		row["name"] = UI.label(p, Rect2(34, 10, 118, 30), str(Data.RARITIES[r]["name"]), "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		row["count"] = UI.label(p, Rect2(156, 12, w - 156 - SELL_W - 100 - 14, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		row["worth"] = UI.label(p, Rect2(w - SELL_W - 8 - 100, 10, 92, 30), "", "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
		row["sell"] = UI.button(p, Rect2(w - SELL_W - 6, 5, SELL_W, ROW_H - 10), false)
		row["sell"].text = "Sell"
		row["sell"].add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
		row["sell"].pressed.connect(_sell.bind(r))
		_rows.append(row)
		y += ROW_H + ROW_GAP
	y += 10
	_box_head = UI.head(self, Rect2(0, y, w, UI.HEAD_H), "ROUNDS BY THE BOX · INTO THE STASH")
	y += UI.HEAD_H + 6
	var bw: float = (w - (BOXES - 1) * 8) / BOXES
	for k in range(BOXES):
		var b := {}
		b["panel"] = UI.panel(self, Rect2(k * (bw + 8), y, bw, BOX_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
		var p: Panel = b["panel"]
		var icon := ItemCell.new()
		icon.position = Vector2(10, 10)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(icon)
		b["icon"] = icon
		b["name"] = UI.label(p, Rect2(10, 64, bw - 20, 26), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		b["line"] = [UI.label(p, Rect2(10, 88, bw - 20, 20), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)]
		b["buy"] = UI.button(p, Rect2(10, BOX_H - 10 - 38, bw - 20, 38), false)
		b["buy"].add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
		b["buy"].pressed.connect(_buy.bind(k))
		b["type"] = ""
		_boxes.append(b)
	y += BOX_H + 8
	_rest = UI.label(self, Rect2(0, y, w, 22), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	size.y = y + 24


## The ammo types your worn guns take, in the order worn.
func worn_types() -> Array:
	var out: Array = []
	for s in ["Primary", "Secondary"]:
		var g = sim.equipped.get(s, null)
		if g != null:
			var ty: String = Items.ammo_type(g)
			if ty in TYPES and not out.has(ty):
				out.append(ty)
	return out


func show_state(s) -> void:
	sim = s
	var sig := "%s|%d|%s|%s|%s" % [_arm.sig(), int(sim.cash), str(sim.stash.map(func(it): return int(it["id"]))), str(worn_types()), str(sim.yard_has("racks"))]
	if sig == _shown:
		return
	_shown = sig
	_rows_due = range(_rows.size())
	_show_boxes()


## BUILD45 (2 Nov, perf44 1: a sale read every rarity's row in its click, 290-380 ms late): the rows read a rarity a frame
## after a change, each on one try-ons' key (held_kit_key); the Sell's press reads its row afresh as ever. The tests'
## readers (row_of, text_nodes) finish them first.
var _rows_due: Array = []


func _process(_dt: float) -> void:
	if not _rows_due.is_empty() and sim != null:
		var r: int = _rows_due.pop_front()
		sim.held_kit_key(_show_row.bind(r))


## Every row waiting read now.
func finish_rows() -> void:
	while not _rows_due.is_empty() and sim != null:
		var r: int = _rows_due.pop_front()
		sim.held_kit_key(_show_row.bind(r))


func _show_row(r: int) -> void:
	if r < _rows.size():
		var row: Dictionary = _rows[r]
		var spare: Array = sim.rarity_spare(r)
		var tone: Color = Pal.TEXT if r == 0 else Pal.tone_color(Pal.rarity_tone(r))
		(row["dot"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = tone
		row["name"].add_theme_color_override("font_color", tone)
		var n: int = int(spare[0])
		var kept: int = int(spare[2])
		var words: Array = []
		if n > 0:
			words = ["%d piece%s" % [n, "" if n == 1 else "s"]]
		else:
			words = ["none spare"]
		if kept > 0:
			UI.fit(row["count"], ["%s · %d kept" % [words[0], kept], words[0]])     # upgrades, uniques, sets, kit pieces, a rule's keep (25 Oct)
		else:
			row["count"].text = words[0]
		UI.fit(row["worth"], [Fmt.group(int(spare[1])), Fmt.short_num(int(spare[1]))] if n > 0 else ["–"])
		row["sell"].disabled = n == 0
		var armed: bool = _arm.holds(r, _spare_fp(r))     # armed on this row and the very pieces it showed
		if armed:
			UI.fit_button(row["sell"], UI.ask_forms(Words.FENCE_SURE % n))
		else:
			row["sell"].text = "Sell"
		UI.style_button(row["sell"], false, "bad" if armed else "")


func _show_boxes() -> void:
	# the boxes: your guns' first, lit; then the others in a fixed order; the rest named under them
	var worn: Array = worn_types()
	var order: Array = worn.duplicate()
	for ty in TYPES:
		if not order.has(ty):
			order.append(ty)
	for k in range(_boxes.size()):
		var b: Dictionary = _boxes[k]
		var ty: String = order[k]
		b["type"] = ty
		var box: Dictionary = sim.ammo_box(ty)
		b["icon"].show_item(sim._plain(Data.AMMO, str(box["name"])), false, Vector2(48, 48))
		UI.fit(b["name"], ["%s ×%d" % [box["name"], int(box["rounds"])], str(box["name"])])
		var lit: bool = worn.has(ty)
		var takes: String = ("your two guns take these" if _both(ty) else "your gun takes these") if lit else "nothing worn takes these"
		UI.fit(b["line"][0], [takes, "yours" if lit else "not worn"])
		b["line"][0].add_theme_color_override("font_color", Pal.ACCENT if lit else Pal.TEXT_2)
		(b["panel"].get_theme_stylebox("panel") as StyleBoxFlat).border_color = Pal.ACCENT if lit else Pal.CARD_LINE
		var price: int = sim.ammo_price(ty)
		UI.fit_button(b["buy"], ["Buy · %s" % Fmt.group(price), "Buy · %s" % Fmt.short_num(price), "Buy"])
		b["buy"].disabled = sim.cash < price or not (sim.stash_room(1) or sim.yard_has("racks"))
		UI.style_button(b["buy"], lit and not b["buy"].disabled)
	var rest: Array = []
	for k in range(_boxes.size(), order.size()):
		var box: Dictionary = sim.ammo_box(order[k])
		rest.append("%s ×%d · %s" % [box["name"], int(box["rounds"]), Fmt.group(sim.ammo_price(order[k]))])
	UI.fit(_rest, ["%s show when a gun you hold takes them" % " and ".join(rest), " and ".join(rest), ""])


## Both worn guns take this type.
func _both(ty: String) -> bool:
	var n := 0
	for s in ["Primary", "Secondary"]:
		var g = sim.equipped.get(s, null)
		if g != null and Items.ammo_type(g) == ty:
			n += 1
	return n > 1


## A row's Sell asks twice (25 Oct, the review: one press sold a rarity's worth): the first arms it on the count it
## shows, the second sells; a changed count, a while, or leaving the room disarms it (the second review).
var _arm := Arm.new()


func _sell(r: int) -> void:
	if sim == null:
		return
	if not _arm.press(r, _spare_fp(r)):
		_shown = ""
		show_state(sim)
		return
	if sim.sell_rarity(r) > 0:
		_shown = ""
		acted.emit()


## The pieces a row's Sell would sell, as a fingerprint for its arm (the reviewer: one sold and one found kept the count).
func _spare_fp(r: int) -> String:
	var ids: Array = sim.rarity_sells(r).map(func(it): return int(it["id"]))     # what the button sells, the cascade in (the second review)
	ids.sort()
	return str(hash(ids))


func _buy(k: int) -> void:
	if sim != null and sim.buy_ammo(str(_boxes[k]["type"])):
		_shown = ""
		acted.emit()


## For the tests: a rarity's row, a box by its place.
func row_of(r: int) -> Dictionary:
	finish_rows()
	return _rows[r]


func box_of(k: int) -> Dictionary:
	return _boxes[k]


func text_nodes() -> Array:
	finish_rows()
	var out: Array = [_head, _box_head, _rest]
	for r in _rows:
		out.append_array([r["name"], r["count"], r["worth"], r["sell"]])
	for b in _boxes:
		out.append_array([b["name"], b["buy"]] + b["line"])
	return out


## Out of the room, the Sell's arm goes (the second review).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_arm.clear()
		_shown = ""
