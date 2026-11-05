extends Panel
## Rounds for the run (BUILD46-R, 2 Nov, Matt's playtest: "no way of selecting which rounds to take with you in the
## pack"; the canvas "Fiat – Rounds and magazines", board 2): a row a worn gun's rounds type - its name, what goes out
## ("16 loaded + 300 · 2 cells"), its grade ▾ from what the stash holds of the type, and − N + boxes of it for the pack -
## then a tick for topping the magazines up from the stash first, the read against the fight's want ("Enough: 331 of
## ~260 needed", green, or short in red) and where it's remembered. Over the Map, opened by the site card's "Rounds ▾"
## and by its red rounds chip (missions.gd open_rounds). Every change is the site's plan (Sim.plan_set_*): remembered
## for the site, the camp's for sites never set, a repeat's too.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const GradeList := preload("res://scripts/ui/grade_list.gd")

const W := 640
const PAD := 20
const HEAD_Y := 16
const ROW_Y := 52
const ROW_H := 64
const ROW_GAP := 8
const ROWS := 2
const GRADE_W := 160
const STEP_W := 44
const COUNT_W := 40
const TICK := 24
const LINE_H := 22
const FOOT_LINES := 5
const DONE_W := 140

var sim
var site := -1                         # the site whose plan shows
var _head: Label
var _read: Label                       # "Enough: 331 of ~260 needed"
var rows: Array = []                   # {panel, name, line, grade, minus, count, plus, type}
var _none: Label
var _tick: Button
var _tick_box: Panel
var _tick_mark: Label
var _tick_label: Label
var _room: Label                       # the boxes the pack can't take
var _foot: Array[Label] = []
var _done: Button
var grades: GradeList                  # a row's "Shells ▾" open: the stash's grades of the type
var _grades_row := -1
var _sig := ""                         # what the panel was last laid out for


func _init() -> void:
	add_theme_stylebox_override("panel", UI.box(Pal.PANEL, 10, 1, Pal.CARD_LINE))
	mouse_filter = Control.MOUSE_FILTER_STOP
	_head = UI.head(self, Rect2(PAD, HEAD_Y, 260, UI.HEAD_H), Words.ROUNDS["head"])
	_read = UI.label(self, Rect2(PAD + 260, HEAD_Y - 2, W - 2 * PAD - 260, 28), "", "Medium", Pal.CELL_TEXT_BIG, Pal.GOOD, HORIZONTAL_ALIGNMENT_RIGHT, false)
	for k in range(ROWS):
		var p := UI.panel(self, Rect2(PAD - 8, ROW_Y + k * (ROW_H + ROW_GAP), W - 2 * PAD + 16, ROW_H), UI.box(Pal.CARD, 8))
		var right: float = p.size.x - 12.0
		var plus := UI.button(p, Rect2(right - STEP_W, (ROW_H - STEP_W) / 2.0, STEP_W, STEP_W), false)
		var count := UI.label(p, Rect2(right - STEP_W - COUNT_W, 0, COUNT_W, ROW_H), "", "SemiBold", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var minus := UI.button(p, Rect2(right - 2 * STEP_W - COUNT_W, (ROW_H - STEP_W) / 2.0, STEP_W, STEP_W), false)
		var grade := UI.button(p, Rect2(right - 2 * STEP_W - COUNT_W - 12 - GRADE_W, (ROW_H - STEP_W) / 2.0, GRADE_W, STEP_W), false)
		for b in [plus, minus, grade]:
			b.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
		plus.text = "+"
		minus.text = "−"
		var tw: float = grade.position.x - 12.0 - 12.0
		var nm := UI.label(p, Rect2(12, 8, tw, 26), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var line := UI.label(p, Rect2(12, 36, tw, 20), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		var k_i := k
		plus.pressed.connect(func(): _step(k_i, 1))
		minus.pressed.connect(func(): _step(k_i, -1))
		grade.pressed.connect(func(): _grades_open(k_i))
		rows.append({"panel": p, "name": nm, "line": line, "grade": grade, "minus": minus, "count": count, "plus": plus, "type": ""})
	_none = UI.label(self, Rect2(PAD, ROW_Y, W - 2 * PAD, 28), Words.ROUNDS["no_guns"], "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_tick = Button.new()
	_tick.focus_mode = Control.FOCUS_NONE
	_tick.flat = true
	_tick.size = Vector2(W - 2 * PAD, TICK + 8)
	_tick.position = Vector2(PAD - 4, 0)
	_tick.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(_tick)
	_tick_box = UI.panel(_tick, Rect2(4, 4, TICK, TICK), UI.box(Pal.ACCENT, 5))
	_tick_mark = UI.label(_tick_box, Rect2(0, 0, TICK, TICK), "✓", "SemiBold", 16, Pal.ACCENT_TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
	_tick_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tick_label = UI.label(_tick, Rect2(4 + TICK + 12, 0, _tick.size.x - TICK - 20, TICK + 8), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_tick_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tick.pressed.connect(_toggle_top)
	_room = UI.label(self, Rect2(PAD, 0, W - 2 * PAD, LINE_H), "", "Regular", Pal.CELL_TEXT, Pal.WARN, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(FOOT_LINES):
		_foot.append(UI.label(self, Rect2(PAD, 0, W - 2 * PAD - DONE_W - 16, LINE_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false))
	_done = UI.button(self, Rect2(W - PAD - DONE_W, 0, DONE_W, 44), true)
	_done.text = Words.ROUNDS["done"]
	_done.pressed.connect(func():
		visible = false
		_grades_shut()
		acted.emit())
	grades = GradeList.new(GRADE_W + 2 * STEP_W + COUNT_W + 60)
	grades.picked.connect(_grade_pick)
	add_child(grades)
	visible = false


## Open on a site's plan (missions.gd open_rounds).
func open(s, i: int) -> void:
	sim = s
	site = i
	_sig = ""
	_grades_shut()
	visible = true
	show_state(s)


func show_state(s) -> void:
	sim = s
	if not visible or sim == null:
		return
	if sim.runner_busy():
		visible = false                       # set off: the plan's gone out with the runner
		_grades_shut()
		return
	var plan: Dictionary = sim.rounds_plan(site)
	# laid again only when what it reads moves (main refreshes ten times a second): the plan, the kit's figures, the
	# stash's rounds, the rig, the pack's room
	var sig := "%s|%d|%s|%s|%d|%d" % [str(plan), sim.stat_v, str(sim._grade_counts()), str(sim.rig.map(func(x): return [x["id"], x.get("rounds", 0)])), sim.capacity(), _grades_row]
	if sig == _sig:
		return
	_sig = sig
	var data: Array = sim.rounds_rows(site)
	var y: float = ROW_Y
	for k in range(ROWS):
		var r: Dictionary = rows[k]
		var on: bool = k < data.size()
		r["panel"].visible = on
		if not on:
			r["type"] = ""
			continue
		var d: Dictionary = data[k]
		r["type"] = str(d["type"])
		r["panel"].position.y = y
		y += ROW_H + ROW_GAP
		UI.fit(r["name"], [str(d["gun"])])
		UI.fit(r["line"], row_forms(d))
		var g: String = str(d["grade"])
		r["grade"].disabled = Array(d["grades"]).is_empty()
		if g == "":
			UI.fit_button(r["grade"], [Words.ROUNDS["no_grades"], Words.ROUNDS["no_grades_short"]])
		else:
			UI.fit_button(r["grade"], grade_forms(g))
		r["count"].text = str(int(d["boxes"]))
		r["minus"].disabled = int(d["boxes"]) <= 0
		r["plus"].disabled = int(d["boxes"]) >= Data.PLAN_BOXES_MAX or Array(d["grades"]).is_empty()
	_none.visible = data.is_empty()
	if data.is_empty():
		y += 36.0
	# the tick: the rig packed and its magazines topped up from the stash first
	var top: bool = bool(plan.get("load", true))     # the magazines' fill (fix 46, R2: the rig's meds aren't the tick's)
	_tick.position.y = y + 2.0
	_tick_box.add_theme_stylebox_override("panel", UI.box(Pal.ACCENT if top else Color.TRANSPARENT, 5, 0 if top else 2, Pal.TEXT_2))
	_tick_mark.visible = top
	UI.fit(_tick_label, [Words.ROUNDS["tick"], Words.ROUNDS["tick_short"]])
	y += TICK + 8 + 10
	# the read against the fight's want
	var read: Array = sim.rounds_read(site) if site >= 0 else []
	_read.visible = not read.is_empty()
	if _read.visible:
		var have: String = Words.group(int(read[0]))
		var want: String = Words.group(int(read[1]))
		var ok: bool = int(read[0]) >= int(read[1])
		UI.fit(_read, [Words.ROUNDS["enough"] % [have, want], Words.ROUNDS["enough_short"] % [have, want]] if ok else [Words.ROUNDS["short"] % [have, want], Words.ROUNDS["short_short"] % [have, want]])
		_read.add_theme_color_override("font_color", Pal.GOOD if ok else Pal.BAD)
	# the pack's room: what doesn't go stays home, said
	var room: Array = sim.rounds_room(site)
	_room.visible = int(room[1]) < int(room[0]) and int(room[1]) >= int(room[2])
	if _room.visible:
		_room.position.y = y
		UI.fit(_room, [Words.ROUNDS["room"] % [int(room[1]), int(room[0])], Words.ROUNDS["room_short"] % [int(room[1]), int(room[0])]])
		y += LINE_H + 6
	UI.wrap(_foot, Words.ROUNDS["foot"])
	var used := 0
	for l in _foot:
		l.position.y = y + used * LINE_H
		if l.text != "":
			used += 1
	_done.position.y = y + maxf(0.0, (used * LINE_H - 44.0) / 2.0)
	y += maxf(float(used * LINE_H), 44.0) + 16
	size = Vector2(W, y)
	if grades.visible:
		_grades_lay()


## The grade button's words, long to short: "Hardened bolts ▾", then its short name, then its first word ("Hardened ▾":
## the smoke's nail gun, a name that's its own short one, ran out of the button).
static func grade_forms(g: String) -> Array:
	var sg: String = short_grade(g)
	var first: String = sg.get_slice(" ", 0)
	return ["%s ▾" % g, "%s ▾" % sg, "%s ▾" % first, first]


## A grade's name short for the button: "Pistol rounds" → "Pistol", "SMG hollow point" → "Hollow point", "Incendiary
## shells" → "Incendiary".
static func short_grade(g: String) -> String:
	if g.ends_with(" rounds") and g.count(" ") == 1:
		return g.trim_suffix(" rounds")
	if g.ends_with("hollow point"):
		return "Hollow point"
	if g.begins_with("Incendiary"):
		return "Incendiary"
	return g


func _step(k: int, by: int) -> void:
	var ty: String = str(rows[k]["type"])
	if ty == "" or sim == null:
		return
	var n: int = sim.plan_boxes(site, ty)
	sim.plan_set_boxes(site, ty, n + by)
	show_state(sim)
	acted.emit()


func _toggle_top() -> void:
	if sim == null:
		return
	sim.plan_set_load(site, not bool(sim.rounds_plan(site).get("load", true)))
	show_state(sim)
	acted.emit()


func _grades_open(k: int) -> void:
	if _grades_row == k and grades.visible:
		_grades_shut()
		return
	_grades_row = k
	_grades_lay()


func _grades_lay() -> void:
	var data: Array = sim.rounds_rows(site)
	if _grades_row < 0 or _grades_row >= data.size():
		_grades_shut()
		return
	var d: Dictionary = data[_grades_row]
	grades.show_list("", Array(d["grades"]), "", Words.ROUNDS["no_grades"], str(d["grade"]))
	var b: Button = rows[_grades_row]["grade"]
	var p: Panel = rows[_grades_row]["panel"]
	grades.position = Vector2(clampf(p.position.x + b.position.x, 0.0, W - grades.size.x), p.position.y + b.position.y + b.size.y + 4.0)
	grades.move_to_front()


func _grades_shut() -> void:
	_grades_row = -1
	grades.visible = false


func _grade_pick(g: String) -> void:
	if _grades_row < 0 or sim == null:
		return
	sim.plan_set_grade(site, str(rows[_grades_row]["type"]), g)
	_grades_shut()
	show_state(sim)
	acted.emit()


## The rows' types showing (the tests).
func row_types() -> Array:
	return rows.filter(func(r): return r["panel"].visible).map(func(r): return str(r["type"]))


## The read's words (the tests).
func read_text() -> String:
	return _read.text if _read.visible else ""


## The tick, as the tests press it.
func tick_on() -> bool:
	return _tick_mark.visible


func press_tick() -> void:
	_toggle_top()


func press_step(k: int, by: int) -> void:
	_step(k, by)


func text_nodes() -> Array:
	if not visible:
		return []
	var out: Array = [_head, _tick_label, _done]
	if _read.visible:
		out.append(_read)
	if _none.visible:
		out.append(_none)
	if _room.visible:
		out.append(_room)
	for l in _foot:
		if l.text != "":
			out.append(l)
	for r in rows:
		if r["panel"].visible:
			out.append_array([r["name"], r["line"], r["grade"], r["count"], r["minus"], r["plus"]])
	if grades.visible:
		var gr: Rect2 = grades.get_global_rect()
		out = out.filter(func(n): return not gr.intersects(n.get_global_rect()))     # the open list covers what's under it
		out.append_array(grades.text_nodes())
	return out


## A gun's row line, long to short (BUILD51-U, item 6: the short form was given the cells too - "not all arguments
## converted" logged at every open, 16 a smoke).
static func row_forms(d: Dictionary) -> Array:
	var lo: String = Words.group(int(d["loaded"]))
	if int(d["packed"]) <= 0:
		return [Words.ROUNDS["row_none"] % lo, Words.ROUNDS["row_none_short"] % lo]
	var cells: String = (Words.ROUNDS["cells"] % int(d["cells"])) if int(d["cells"]) == 1 else (Words.ROUNDS["cells_n"] % int(d["cells"]))
	var bx: String = Words.group(int(d["box_rounds"]))
	return [Words.ROUNDS["row"] % [lo, bx, cells], Words.ROUNDS["row_short"] % [lo, bx]]

