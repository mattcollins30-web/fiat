extends Control
## The Fence's list (19 Oct, Matt's Fence B): his contracts as compact rows - the kind, the ask, the pay, how far the
## stash gets it, Hand in and Pass - one picked to see what goes in the stash at the right; then his mate.
##
## Signals: `picked(k)` a row chosen; `hand(k)`, `pass_one(k)`, `mate` for the buttons.

signal picked(k: int)
signal hand(k: int)
signal pass_one(k: int)
signal mate

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")

const ROW_H := 84.0
const ROW_GAP := 8.0
const HAND_W := 104.0
const PASS_W := 74.0
const TAG_W := 120.0
const MATE_H := 66.0

var sim
var selected := 0
var _head: Label
var _rows: Array = []                 # {panel, tag_box, tag, title, pay, track, fill, have, hand, pass}
var _note: Label
var _mate_head: Label
var _mate: Panel
var _mate_name: Label
var _mate_sub: Label
var _mate_price: Label
var _mate_buy: Button
var _shown := ""


func _init(w: float, h: float) -> void:
	size = Vector2(w, h)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_head = UI.head(self, Rect2(0, 0, w, UI.HEAD_H), "HIS LIST · PICK ONE TO SEE WHAT GOES")
	var y: float = UI.HEAD_H + 6
	for k in range(Data.CONTRACTS_MAX):
		var r := {}
		var b := Button.new()
		b.position = Vector2(0, y)
		b.size = Vector2(w, ROW_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(func(): picked.emit(k))
		add_child(b)
		r["panel"] = b
		r["tag_box"] = UI.panel(b, Rect2(12, 10, TAG_W, 26), UI.box(Pal.BUTTON, 4))
		r["tag"] = UI.label(r["tag_box"], Rect2(6, 0, TAG_W - 12, 26), "", "SemiBold", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["title"] = UI.label(b, Rect2(TAG_W + 22, 7, w - TAG_W - 22 - 150, 30), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["pay"] = UI.label(b, Rect2(w - 12 - 146, 8, 146, 30), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT, false)
		var tw: float = w - 24 - HAND_W - PASS_W - 16 - 60
		r["track"] = UI.panel(b, Rect2(12, 58, tw, 6), UI.box(Pal.BG, 3))
		r["fill"] = UI.panel(r["track"], Rect2(0, 0, 0, 6), UI.box(Pal.ACCENT, 3))
		r["have"] = UI.label(b, Rect2(12 + tw + 8, 46, 52, 28), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["hand"] = UI.button(b, Rect2(w - 12 - PASS_W - 8 - HAND_W, 40, HAND_W, 38), false)
		r["hand"].text = "Hand in"
		r["hand"].add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
		r["hand"].pressed.connect(func(): hand.emit(k))
		r["pass"] = UI.button(b, Rect2(w - 12 - PASS_W, 40, PASS_W, 38), false)
		r["pass"].text = "Pass"
		r["pass"].add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
		r["pass"].pressed.connect(func(): pass_one.emit(k))
		for l in [r["tag"], r["title"], r["pay"], r["have"]]:
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r["tag_box"].mouse_filter = Control.MOUSE_FILTER_IGNORE
		r["track"].mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rows.append(r)
		y += ROW_H + ROW_GAP
	_note = UI.label(self, Rect2(0, 0, w, 40), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	var my: float = h - MATE_H
	_mate_head = UI.head(self, Rect2(0, my - UI.HEAD_H - 6, w, UI.HEAD_H), "HIS MATE · NEW EVERY %d RUNS" % Data.MATE_RUNS)
	_mate = UI.panel(self, Rect2(0, my, w, MATE_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_mate_name = UI.label(_mate, Rect2(12, 6, w * 0.5, 30), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_mate_sub = UI.label(_mate, Rect2(12, 36, w * 0.5, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_mate_price = UI.label(_mate, Rect2(w * 0.5, 16, w * 0.5 - 12 - 136, 30), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_mate_buy = UI.button(_mate, Rect2(w - 12 - 128, 12, 128, MATE_H - 24), false)
	_mate_buy.add_theme_font_size_override("font_size", Pal.CELL_TEXT)
	_mate_buy.pressed.connect(func(): mate.emit())


## A pay's colour: the vendor's (tins in gold, notes in the paper's, a salvage in its own).
var pay_colour: Callable


func show_state(s, title_of: Callable) -> void:
	sim = s
	var sig := "%s|%d|%d|%d|%s|%s|%s" % [str(sim.contracts), selected, sim.notes, sim.passes, str(sim.mate), str(sim.stash.map(func(it): return int(it["id"]))), str(sim.on_mission())]
	if sig == _shown:
		return
	_shown = sig
	var n: int = sim.contracts.size()
	selected = clampi(selected, 0, maxi(0, n - 1))
	var y: float = UI.HEAD_H + 6
	var pc: int = sim.pass_cost()
	for k in range(_rows.size()):
		var r: Dictionary = _rows[k]
		var on: bool = k < n
		r["panel"].visible = on
		if not on:
			continue
		var c: Dictionary = sim.contracts[k]
		var can: bool = sim.can_hand_in(k)
		var picked_now: bool = k == selected
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			r["panel"].add_theme_stylebox_override(st, UI.box(Pal.SELECT if st == "hover" else Pal.PANEL, 8, 2 if picked_now else 1, Pal.GOOD if (picked_now and can) else (Pal.ACCENT if picked_now else Pal.CARD_LINE)))
		var kind_n: String = str(Data.CONTRACT_KIND_NAMES.get(c.get("kind", "gear"), "Gear")).to_upper()
		r["tag"].text = kind_n
		r["tag"].add_theme_color_override("font_color", Pal.GOOD if can else Pal.TEXT_2)
		var t: Array = title_of.call(c)
		UI.fit(r["title"], t)
		var colour: Color = pay_colour.call(c) if pay_colour.is_valid() else Pal.ACCENT
		UI.fit(r["pay"], [sim.contract_pay_words(c), sim.contract_pay_words(c).get_slice(" ", 0)])
		r["pay"].add_theme_color_override("font_color", colour)
		var have: int = mini(sim.contract_all(c).size(), int(c["count"]))
		r["have"].text = "%d / %d" % [have, int(c["count"])]
		r["fill"].size.x = roundf(r["track"].size.x * float(have) / maxf(1.0, float(c["count"])))
		(r["fill"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.GOOD if can else Pal.ACCENT
		r["hand"].disabled = not can
		UI.style_button(r["hand"], false, "good" if can else "")
		r["pass"].disabled = not sim.can_pass_contract(k)
		r["pass"].tooltip_text = "Free this run" if pc == 0 else Fmt.notes(pc)
		y = r["panel"].position.y + ROW_H + ROW_GAP
	_note.position.y = y
	if n < Data.CONTRACTS_MAX:
		var more: int = Data.CONTRACTS_MAX - n
		UI.fit(_note, ["%s more place%s on his list come with the Fence's upgrades" % [["", "One", "Two", "Three", "Four"][mini(more, 4)], "" if more == 1 else "s"], "More with the Fence's upgrades"])
	else:
		_note.text = ""
	_note.visible = _note.text != ""
	if sim.mate.is_empty():
		_mate_name.text = "Not about"
		UI.fit(_mate_sub, ["He comes by every %d runs" % Data.MATE_RUNS, "Every %d runs" % Data.MATE_RUNS])
		_mate_price.text = ""
		_mate_buy.visible = false
	else:
		var mt: String = (" · tier %d" % int(sim.mate["tier"])) if sim.mate.has("tier") else ""
		UI.fit(_mate_name, [str(sim.mate["unique"])])
		_mate_name.add_theme_color_override("font_color", Pal.tone_color(Pal.rarity_tone(4)))
		UI.fit(_mate_sub, ["A unique%s" % mt, "Unique"])
		_mate_price.text = Fmt.notes(int(sim.mate["notes"]))
		_mate_buy.visible = true
		var short: int = int(sim.mate["notes"]) - sim.notes
		_mate_buy.text = "Buy" if short <= 0 else "Short %s" % Fmt.group(short)
		_mate_buy.disabled = not sim.can_buy_mate()


## For the tests: a row by its place.
func row_of(k: int) -> Dictionary:
	return _rows[k]


func text_nodes() -> Array:
	var out: Array = [_head, _mate_head, _mate_name, _mate_sub, _mate_price]
	if _note.visible:
		out.append(_note)
	if _mate_buy.visible:
		out.append(_mate_buy)
	for r in _rows:
		if r["panel"].visible:
			out.append_array([r["tag"], r["title"], r["pay"], r["have"], r["hand"], r["pass"]])
	return out
