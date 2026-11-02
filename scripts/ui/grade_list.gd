extends Panel
## The grades of rounds as a list to pick from (BUILD46-R, 2 Nov, the canvas "Fiat – Rounds and magazines"): a row a
## grade - its box's picture, its dot in the rounds' own colour (Pal.ROUND_COLOURS), its name with its tag ("Slugs ·
## +20%", "Incendiary shells · fire") and how many rounds the stash holds. A head over them and a foot under, either
## left off. The stash's "Load with ▾" opens one over the pick panel's right column; the rounds picker's "Shells ▾" one
## under its row. Pressing a row emits `picked` with the grade.

signal picked(grade)

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const Sim := preload("res://scripts/sim/sim.gd")

const ROWS := 5
const ROW_H := 36
const ROW_GAP := 2
const PAD := 12
const ICON := 28
const DOT := 10
const COUNT_W := 84
const FOOT_LINES := 3
const FOOT_H := 20

var w := 300
var _head: Label
var rows: Array = []                   # {btn, icon, dot, name, count, grade}
var _foot: Array[Label] = []


func _init(width: int) -> void:
	w = width
	add_theme_stylebox_override("panel", UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	mouse_filter = Control.MOUSE_FILTER_STOP
	_head = UI.head(self, Rect2(PAD, 8, w - 2 * PAD, UI.HEAD_H), "")
	for k in range(ROWS):
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.size = Vector2(w - 2 * PAD + 8, ROW_H)
		b.position = Vector2(PAD - 4, 0)
		for st in ["normal", "disabled"]:
			b.add_theme_stylebox_override(st, UI.box(Color.TRANSPARENT, 6))
		b.add_theme_stylebox_override("hover", UI.box(Pal.SELECT, 6))
		b.add_theme_stylebox_override("pressed", UI.box(Pal.BUTTON_PRESS, 6))
		b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 6))
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_child(b)
		var icon := TextureRect.new()
		icon.position = Vector2(4, (ROW_H - ICON) / 2.0)
		icon.size = Vector2(ICON, ICON)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(icon)
		var dot := UI.panel(b, Rect2(4 + ICON + 8, (ROW_H - DOT) / 2.0, DOT, DOT), UI.box(Pal.TEXT_2, 5))
		var nx: float = 4 + ICON + 8 + DOT + 10
		var nm := UI.label(b, Rect2(nx, 0, b.size.x - nx - COUNT_W - 8, ROW_H), "", "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var cnt := UI.label(b, Rect2(b.size.x - COUNT_W - 8, 0, COUNT_W, ROW_H), "", "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
		for l in [nm, cnt]:
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var k_i := k
		b.pressed.connect(func(): _press(k_i))
		rows.append({"btn": b, "icon": icon, "dot": dot, "name": nm, "count": cnt, "grade": ""})
	for i in range(FOOT_LINES):
		_foot.append(UI.label(self, Rect2(PAD, 0, w - 2 * PAD, FOOT_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false))
	visible = false


## The list: `head` over it ("" none), `grades` [[grade, rounds], ...] a row each (ROWS at most), `foot` under it ("" none),
## `none` the line in a row's place when there are no grades. `chosen` the grade lit. Sizes itself; `min_h` its least height.
func show_list(head: String, grades: Array, foot := "", none := "", chosen := "", min_h := 0.0) -> void:
	_head.visible = head != ""
	_head.text = head.to_upper()
	var y: float = 8.0 + (UI.HEAD_H + 6.0 if _head.visible else 0.0)
	for k in range(ROWS):
		var r: Dictionary = rows[k]
		var on: bool = k < grades.size() or (k == 0 and grades.is_empty() and none != "")
		r["btn"].visible = on
		if not on:
			r["grade"] = ""
			continue
		r["btn"].position.y = y
		y += ROW_H + ROW_GAP
		if grades.is_empty():
			r["grade"] = ""
			r["btn"].disabled = true
			r["icon"].visible = false
			r["dot"].visible = false
			r["name"].text = none
			r["name"].add_theme_color_override("font_color", Pal.TEXT_3)
			r["count"].text = ""
			continue
		var g: String = str(grades[k][0])
		r["grade"] = g
		r["btn"].disabled = false
		var tex: Texture2D = Items.art({"slot": Data.AMMO, "base": g})
		r["icon"].texture = tex
		r["icon"].visible = tex != null
		r["dot"].visible = true
		r["dot"].add_theme_stylebox_override("panel", UI.box(Pal.round_colour(g), roundi(DOT / 2.0), 1, Color(Pal.BG, 0.9)))
		var tag: String = Sim.grade_tag(g)
		UI.fit(r["name"], ["%s · %s" % [g, tag], g] if tag != "" else [g])
		r["name"].add_theme_color_override("font_color", Pal.ACCENT if g == chosen else Pal.TEXT)
		r["count"].text = Words.group(int(grades[k][1]))
	y += 4.0
	# the foot: at the list's foot when it has a height (min_h), on as many lines as fit under the rows - none when it
	# won't go in them whole
	for l in _foot:
		l.text = ""
		l.visible = false
	if foot != "":
		var avail: int = FOOT_LINES if min_h <= 0.0 else clampi(int((min_h - 8.0 - y) / FOOT_H), 0, FOOT_LINES)
		if avail > 0:
			var lines: Array = _foot.slice(0, avail)
			UI.wrap(lines, foot)
			var last: Label = lines[-1]
			var fits: bool = UI.text_width(last, last.text) <= last.size.x
			var used := 0
			for l in lines:
				if l.text != "":
					used += 1
			var fy: float = (min_h - 8.0 - used * FOOT_H) if min_h > 0.0 else y
			for i in range(lines.size()):
				lines[i].position.y = fy + i * FOOT_H
				lines[i].visible = fits and lines[i].text != ""
			if fits and min_h <= 0.0:
				y += used * FOOT_H
	size = Vector2(w, maxf(min_h, y + 8.0))
	visible = true


func _press(k: int) -> void:
	var g: String = str(rows[k]["grade"])
	if g != "":
		picked.emit(g)


## The row's grade shown at k, "" for none (the tests).
func grade_at(k: int) -> String:
	return str(rows[k]["grade"]) if rows[k]["btn"].visible else ""


## A row pressed as a click would (the tests).
func press(k: int) -> void:
	if k < ROWS and rows[k]["btn"].visible and not rows[k]["btn"].disabled:
		_press(k)


func text_nodes() -> Array:
	if not visible:
		return []
	var out: Array = []
	if _head.visible:
		out.append(_head)
	for r in rows:
		if r["btn"].visible:
			out.append_array([r["name"], r["count"]])
	for l in _foot:
		if l.visible and l.text != "":
			out.append(l)
	return out
