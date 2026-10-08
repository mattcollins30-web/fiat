extends Control
## The Yard as a tree (8 Oct, Matt: the works "need the same treatment as the
## caravan and the map in terms of skill point layout - except cash is the
## cost"). A column a work, a level a tile top to bottom: the built ones edged
## gold, the next one its own Build button carrying its price, the later ones
## dim with theirs. The clinic, the fence and the radio are built here too
## (they were "upgraded in their rooms" and easy to miss) and run in their
## rooms. The heading: the levels built, the purse and the town as chips, Move
## the yard when it can, the clock in the foot.
##
## `show_state(sim, jobs, purse)`: jobs from main._yard_jobs(), each
## {name, level, of, levels: [{name, forms} a level, index 0 the start], costs:
## [a level from the first built], can, action}; purse from main._town_purse().

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Chips := preload("res://scripts/ui/chips.gd")

const PAD := 20
const HEAD_H := 118                                 # the heading band
const COLS := 8
const COL_GAP := 12
const COL_W := (Pal.GRID_W - 2 * PAD - (COLS - 1) * COL_GAP) / COLS      # 185
const COL_HEAD_H := 40
const TILE_H := 196
const TILE_GAP := 8
const TILES := 3
const GRID_Y := HEAD_H + 14
const FOOT_H := 44
const MOVE_W := 220

var sim
var _headline: Label
var _unit: Label
var _kicker: Label
var _chips: Chips
var _move: Button
var _foot: Label
var _foot_right: Label
var _heads: Array = []              # a column each: {name, count}
var _tiles: Array = []              # [column][row] -> {button, name, words, cost, edge}
var _actions: Array = []            # a column each: the next level's Callable
var _cans: Array = []
var _shown := ""


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var head := UI.panel(self, Rect2(0, 0, Pal.GRID_W, HEAD_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_kicker = UI.label(head, Rect2(PAD, 12, 400, 26), "The yard", "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_headline = UI.label(head, Rect2(PAD, 38, 300, 48), "", "SemiBold", Pal.HEADLINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_unit = UI.label(head, Rect2(PAD, 44, 400, 40), "", "Medium", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_chips = Chips.new(Pal.GRID_W - 2 * PAD - 420 - MOVE_W - 16, 9)
	_chips.position = Vector2(PAD + 420, 14)
	head.add_child(_chips)
	_move = UI.button(head, Rect2(Pal.GRID_W - PAD - MOVE_W, HEAD_H - 16 - Pal.BUTTON_H, MOVE_W, Pal.BUTTON_H), true)
	_move.text = "Move the yard"
	_move.visible = false
	_move.pressed.connect(func(): if _move_action.is_valid(): _move_action.call())
	for c in range(COLS):
		var x: float = PAD + c * (COL_W + COL_GAP)
		var h := {}
		h["name"] = UI.label(self, Rect2(x + 2, GRID_Y, COL_W - 4, COL_HEAD_H), "", "SemiBold", Pal.CELL_TEXT_BIG + 3, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		h["count"] = UI.label(self, Rect2(x + 2, GRID_Y + 4, COL_W - 4, COL_HEAD_H - 4), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT)
		h["rule"] = UI.panel(self, Rect2(x, GRID_Y + COL_HEAD_H - 1, COL_W, 1), UI.box(Pal.CARD_LINE, 0))
		_heads.append(h)
		var col := []
		for r in range(TILES):
			var y: float = GRID_Y + COL_HEAD_H + 8 + r * (TILE_H + TILE_GAP)
			var b := Button.new()
			b.position = Vector2(x, y)
			b.size = Vector2(COL_W, TILE_H)
			b.text = ""
			b.focus_mode = Control.FOCUS_ALL
			b.pressed.connect(_press.bind(c, r))
			add_child(b)
			var t := {"button": b}
			t["edge"] = UI.panel(b, Rect2(0, 0, 4, TILE_H), UI.box(Pal.ACCENT, 2))
			t["name"] = []
			for k in range(2):
				t["name"].append(UI.label(b, Rect2(12, 10 + k * 26, COL_W - 24, 26), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))
			t["words"] = []
			for k in range(3):
				t["words"].append(UI.label(b, Rect2(12, 68 + k * 24, COL_W - 24, 24), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
			t["cost"] = UI.label(b, Rect2(12, TILE_H - 40, COL_W - 24, 30), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, true)
			col.append(t)
		_tiles.append(col)
		_actions.append(Callable())
		_cans.append(false)
	var foot_y: float = GRID_Y + COL_HEAD_H + 8 + TILES * (TILE_H + TILE_GAP) + 6
	_foot = UI.label(self, Rect2(PAD, foot_y, Pal.GRID_W - 2 * PAD - 420, FOOT_H), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_foot_right = UI.label(self, Rect2(Pal.GRID_W - PAD - 420, foot_y, 420, FOOT_H), "", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)


func show_state(s, jobs: Array, purse: Dictionary) -> void:
	sim = s
	var built := 0
	var of := 0
	for j in jobs:
		built += int(j["level"])
		of += int(j["of"])
	_headline.text = "%d of %d" % [built, of]
	_unit.position.x = PAD + ceilf(UI.text_width(_headline, _headline.text)) + 10
	_unit.text = "levels built"
	# the purse and the town as chips: cash first in gold, then the rest
	var items := [{"forms": [Fmt.money(sim.cash) + " in hand", Fmt.money(sim.cash)], "colour": Pal.ACCENT}]
	for line in purse["right"]["lines"]:
		if line[0] == "Cash":
			continue
		items.append({"forms": ["%s %s" % [line[0], line[1]]], "colour": Pal.TEXT_2})
	for line in purse["left"]["lines"]:
		items.append({"forms": ["%s · %s" % [line[0], line[1]]], "colour": Pal.TEXT_2})
	_chips.show_chips(items, 3)
	_move.visible = purse.has("button")
	if _move.visible:
		UI.style_button(_move, bool(purse["button"].get("primary", false)))
		_move_action = purse["button"]["action"]
	for c in range(COLS):
		var on: bool = c < jobs.size()
		_heads[c]["name"].visible = on
		_heads[c]["count"].visible = on
		_heads[c]["rule"].visible = on
		for r in range(TILES):
			_tiles[c][r]["button"].visible = on and r < int(jobs[c]["of"]) if on else false
		if not on:
			continue
		var j: Dictionary = jobs[c]
		var lv: int = int(j["level"])
		_heads[c]["name"].text = j["name"]
		_heads[c]["count"].text = "%d of %d" % [lv, int(j["of"])]
		_actions[c] = j["action"]
		_cans[c] = bool(j["can"])
		for r in range(mini(TILES, int(j["of"]))):
			var t: Dictionary = _tiles[c][r]
			var level: int = r + 1
			var lvd: Dictionary = j["levels"][level]
			var forms: Array = lvd["forms"]
			var state: String = "built" if level <= lv else ("next" if level == lv + 1 else "later")
			var b: Button = t["button"]
			for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
				var bg: Color = Pal.CARD if state != "later" else Color.TRANSPARENT
				if state == "next" and st in ["hover", "hover_pressed"]:
					bg = Pal.BUTTON_HOVER
				b.add_theme_stylebox_override(st, UI.box(bg, 7, 1, Pal.CARD_LINE if state != "later" else Pal.RAIL_RULE))
			b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 7, 2, Pal.TEXT))
			b.disabled = state != "next" or not bool(j["can"])
			t["edge"].visible = state == "built"
			# the level's name over up to two lines, its words over up to three
			var name_lines := _wrap([str(lvd["name"])], t["name"][0], COL_W - 24, 2)
			for k in range(2):
				t["name"][k].text = name_lines[k] if k < name_lines.size() else ""
				t["name"][k].add_theme_color_override("font_color", Pal.TEXT if state != "later" else Pal.TEXT_3)
			var lines := _wrap(forms, t["words"][0], COL_W - 24, 3)
			for k in range(3):
				t["words"][k].text = lines[k] if k < lines.size() else ""
				t["words"][k].add_theme_color_override("font_color", Pal.TEXT_2 if state != "later" else Pal.TEXT_3)
			var cost: int = int(j["costs"][r])
			if state == "built":
				t["cost"].text = "Built"
				t["cost"].add_theme_color_override("font_color", Pal.ACCENT)
			elif state == "next":
				t["cost"].text = "Build · %s" % Fmt.money(cost)
				t["cost"].add_theme_color_override("font_color", Pal.ACCENT if bool(j["can"]) else Pal.TEXT_2)
			else:
				t["cost"].text = Fmt.money(cost)
				t["cost"].add_theme_color_override("font_color", Pal.TEXT_3)
	UI.fit(_foot, purse["left"]["note"] if purse["left"]["note"] is Array else [str(purse["left"]["note"])])
	UI.fit(_foot_right, purse["status"] if purse["status"] is Array else [str(purse["status"])])


var _move_action: Callable


## Words over up to `max_lines` lines: the longest form that wraps within them, else the shortest cut short.
static func _wrap(forms: Array, measure: Label, w: float, max_lines: int) -> Array:
	for f in forms:
		var words: PackedStringArray = str(f).split(" ")
		var lines: Array = []
		var line := ""
		for wd in words:
			var next: String = wd if line == "" else line + " " + wd
			if UI.text_width(measure, next) <= w:
				line = next
			else:
				lines.append(line)
				line = wd
		lines.append(line)
		if lines.size() <= max_lines and lines.all(func(l): return UI.text_width(measure, l) <= w):
			return lines
	return [str(forms.back())]


## The tile at (column, row) pressed: the next level's Build.
func _press(c: int, r: int) -> void:
	if r == int(_count_level(c)) and _cans[c] and _actions[c].is_valid():
		_actions[c].call()
		acted.emit()


func _count_level(c: int) -> int:
	return int(str(_heads[c]["count"].text).get_slice(" ", 0))


## For the smoke: press a column's next tile.
func press_next(c: int) -> void:
	_press(c, _count_level(c))


func text_nodes() -> Array:
	var out: Array = [_headline, _unit, _kicker, _foot, _foot_right]
	for h in _heads:
		if h["name"].visible:
			out.append(h["name"])
			out.append(h["count"])
	for col in _tiles:
		for t in col:
			if t["button"].visible:
				out.append(t["cost"])
				for l in t["name"] + t["words"]:
					if l.text != "":
						out.append(l)
	return out


func line_pairs() -> Array:
	var out := []
	for h in _heads:
		if h["name"].visible:
			out.append([h["name"], h["count"]])
	return out
