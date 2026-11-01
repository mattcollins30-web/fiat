extends Panel
## The standing orders (1 Nov, run events; the canvas's board 4): beside the loot rules, over the Kit's stash and pick
## panel - what the runner does when a run event comes up on a run nobody's watching (repeat runs, away, the bot). A row
## a family, its name and a drop-down of its orders; a new family shows its first ("Leave it") until it's set. A run you
## watch always asks. Changes are made in place.

signal closed
signal changed

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")

const W := 904
const H := 916
const PAD := 22
const HEAD_BTN_H := 44
const LIST_Y := 112
const ROW_H := 50
const ROW_GAP := 6
const DROP_W := 420

var sim
var _title: Label
var _sub: Label
var _intro: Label
var _close: Button
var _rows: Array = []              # {panel, name, drop, fam} a family
var _foot: Label
var _menu: PopupMenu
var _menu_fam := ""


func _init() -> void:
	size = Vector2(W, H)
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	mouse_filter = Control.MOUSE_FILTER_STOP
	_title = UI.label(self, Rect2(PAD, 16, 260, 40), Words.ORDERS["title"], "SemiBold", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_close = UI.button(self, Rect2(W - PAD - 110, 14, 110, HEAD_BTN_H), false)
	_close.text = Words.ORDERS["close"]
	_close.pressed.connect(func(): closed.emit())
	_sub = UI.label(self, Rect2(PAD + 270, 22, W - 2 * PAD - 270 - 110 - 16, 30), Words.ORDERS["sub"], "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_intro = UI.label(self, Rect2(PAD, 66, W - 2 * PAD, 30), Words.ORDERS["intro"], "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(Data.EVENT_ORDER.size()):
		var fam: String = Data.EVENT_ORDER[k]
		var y: float = LIST_Y + k * (ROW_H + ROW_GAP)
		var p := UI.panel(self, Rect2(PAD, y, W - 2 * PAD, ROW_H), UI.box(Pal.BG, 6))
		var nm := UI.label(p, Rect2(12, 0, W - 2 * PAD - 24 - DROP_W - 12, ROW_H), str(Data.EVENT_FAMILIES[fam]["name"]), "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var dr := UI.button(p, Rect2(W - 2 * PAD - 8 - DROP_W, 6, DROP_W, ROW_H - 12), false)
		dr.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 1)
		dr.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dr.pressed.connect(_open_menu.bind(fam))
		_rows.append({"panel": p, "name": nm, "drop": dr, "fam": fam})
	_foot = UI.label(self, Rect2(PAD, H - 44, W - 2 * PAD, 26), Words.ORDERS["foot"], "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_menu = PopupMenu.new()
	_menu.add_theme_font_override("font", UI.font("Regular"))
	_menu.add_theme_font_size_override("font_size", Pal.CELL_TEXT)
	# the game's own look (the fix round, U12): the card's panel and line, the button's hover, the text's tones
	var pb := UI.box(Pal.CARD, 6, 1, Pal.CARD_LINE)
	pb.set_content_margin_all(6)
	_menu.add_theme_stylebox_override("panel", pb)
	_menu.add_theme_stylebox_override("hover", UI.box(Pal.BUTTON_HOVER, 4))
	_menu.add_theme_stylebox_override("separator", UI.box(Pal.CARD_LINE, 0))
	_menu.add_theme_color_override("font_color", Pal.TEXT)
	_menu.add_theme_color_override("font_hover_color", Pal.TEXT)
	_menu.add_theme_color_override("font_disabled_color", Pal.TEXT_3)
	_menu.add_theme_constant_override("v_separation", 10)
	_menu.add_theme_constant_override("h_separation", 10)
	_menu.id_pressed.connect(_chosen)
	add_child(_menu)


## A family's order in words.
static func order_words(fam: String, key: String) -> String:
	return str(Words.ORDERS.get(fam, {}).get(key, Words.ORDERS["default"]))


func show_state(s) -> void:
	sim = s
	for r in _rows:
		var o: String = sim.event_order(str(r["fam"]))
		r["drop"].text = order_words(str(r["fam"]), o) + " ▾"


func _open_menu(fam: String) -> void:
	_menu_fam = fam
	_menu.clear()
	var ch: Array = Data.EVENT_ORDERS.get(fam, ["leave"])
	for k in range(ch.size()):
		_menu.add_radio_check_item(order_words(fam, str(ch[k])), k)
		_menu.set_item_checked(k, sim != null and sim.event_order(fam) == str(ch[k]))
	var r: Dictionary = _rows[Data.EVENT_ORDER.find(fam)]
	var b: Button = r["drop"]
	_menu.position = Vector2i(b.get_screen_position() + Vector2(0, b.size.y))
	_menu.popup()


func _chosen(id: int) -> void:
	choose(_menu_fam, id)


## A family's order set by its place in Data.EVENT_ORDERS (the drop-down's pick; the tests' too).
func choose(fam: String, k: int) -> void:
	var ch: Array = Data.EVENT_ORDERS.get(fam, [])
	if sim == null or k < 0 or k >= ch.size():
		return
	sim.set_order(fam, str(ch[k]))
	show_state(sim)
	changed.emit()


## For the tests: a family's drop-down.
func drop(fam: String) -> Button:
	return _rows[Data.EVENT_ORDER.find(fam)]["drop"]


func text_nodes() -> Array:
	var out: Array = [_title, _sub, _intro, _close, _foot]
	for r in _rows:
		out.append_array([r["name"], r["drop"]])
	return out
