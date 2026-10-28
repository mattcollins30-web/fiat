extends Control
## The Clinic's runner (19 Oct, Matt's Clinic A on "Fiat – The Clinic and the Fence"): the body as an outline with each
## wound where it is, a row a wound - what it is, what it costs the runner, the run it came home from, Treat - the
## empty areas dashed, the HP as it rests, and one button for the lot. Three wounds at most, one an area; the Clinic is
## the only cure.
##
## Her supplies (28 Oct, docs/design/meds_ammo_clinic.md): a strip over the HP - the medical supplies in the stash, her
## shelf's step and the next, Hand in.
##
## Signals: `acted` after a treatment; `handed` after supplies go in.

signal acted
signal handed

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const Body := preload("res://scripts/ui/body.gd")

const BODY_W := 190.0
const BODY_H := 400.0
const ROW_X := BODY_W + 16.0
const ROW_H := 118.0
const EMPTY_H := 44.0
const ROW_GAP := 10.0
const TREAT_W := 140.0
const BAR_H := 58.0
const SUP_H := 66.0
const HAND_W := 170.0

var sim
var _head: Label
var _rows: Array = []                 # an area each, in Data.WOUND_AREAS' order: {panel, title, effect, from, treat}
var _note: Label
var _bar: Panel
var _bar_left: Label
var _bar_right: Label
var _track: Panel
var _fill: Panel
var _all: Button
var _upgrades: Button
var _sup: Panel                       # her supplies (28 Oct): the strip, its head and line, Hand in
var _sup_head: Label
var _sup_line: Label
var _hand: Button
var _marks: Array = []                # [area, number] drawn on the body, in the rows' order
var _figure: TextureRect              # the runner's own drawing, the Kit's (19 Oct, Matt: yes to the class's body art)
var _over: Control                    # the wounds, drawn over the figure
var _figure_path := ""
var _shown := ""


func _init(w: float, h: float) -> void:
	size = Vector2(w, h)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_head = UI.head(self, Rect2(0, 0, w, UI.HEAD_H), "THE RUNNER")
	_figure = TextureRect.new()
	_figure.position = Vector2(0, UI.HEAD_H + 10)
	_figure.size = Vector2(BODY_W, BODY_H)
	_figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_figure)
	_over = Control.new()
	_over.position = _figure.position
	_over.size = _figure.size
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.draw.connect(_draw_marks)
	add_child(_over)
	for a in Data.WOUND_AREAS:
		var r := {"area": a}
		r["panel"] = UI.panel(self, Rect2(ROW_X, 0, w - ROW_X, ROW_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
		var p: Panel = r["panel"]
		var tw: float = p.size.x - 20
		r["title"] = UI.label(p, Rect2(44, 8, tw - 34, 30), "", "SemiBold", Pal.CELL_TEXT_BIG + 3, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["effect"] = UI.label(p, Rect2(12, 40, tw, 24), "", "Regular", Pal.CELL_TEXT, Pal.BAD, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["from"] = [UI.label(p, Rect2(12, 66, tw - TREAT_W - 8, 22), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false),
			UI.label(p, Rect2(12, 88, tw - TREAT_W - 8, 22), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)]
		r["treat"] = UI.button(p, Rect2(p.size.x - TREAT_W - 10, 66, TREAT_W, 42), false)
		r["treat"].add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
		r["treat"].pressed.connect(_treat.bind(a))
		r["empty"] = UI.label(p, Rect2(12, 0, tw, EMPTY_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["num"] = UI.panel(p, Rect2(12, 11, 24, 24), UI.box(Pal.BAD, 12))
		r["num_l"] = UI.label(r["num"], Rect2(0, 0, 24, 24), "", "SemiBold", Pal.CELL_TEXT - 2, Pal.BG, HORIZONTAL_ALIGNMENT_CENTER, false)
		_rows.append(r)
	_note = UI.label(self, Rect2(ROW_X, 0, w - ROW_X, 22), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sup = UI.panel(self, Rect2(0, h - Pal.BUTTON_H - 12 - BAR_H - 10 - SUP_H, w, SUP_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_sup_head = UI.label(_sup, Rect2(12, 8, w - HAND_W - 34, 22), "", "SemiBold", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sup_line = UI.label(_sup, Rect2(12, 34, w - HAND_W - 34, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_hand = UI.button(_sup, Rect2(w - HAND_W - 10, (SUP_H - 44.0) / 2.0, HAND_W, 44), false)
	_hand.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
	_hand.pressed.connect(_hand_in)
	_bar = UI.panel(self, Rect2(0, h - Pal.BUTTON_H - 12 - BAR_H, w, BAR_H), UI.box(Pal.BG, 8))
	_bar_left = UI.label(_bar, Rect2(12, 6, w * 0.4, 26), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_bar_right = UI.label(_bar, Rect2(w * 0.4, 8, w * 0.6 - 12, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_track = UI.panel(_bar, Rect2(12, 38, w - 24, 10), UI.box(Pal.BUTTON, 5))
	_fill = UI.panel(_track, Rect2(0, 0, 0, 10), UI.box(Pal.GOOD, 5))
	_all = UI.button(self, Rect2(0, h - Pal.BUTTON_H, w - 216, Pal.BUTTON_H), true)
	_all.pressed.connect(_treat_all)
	_upgrades = UI.button(self, Rect2(w - 200, h - Pal.BUTTON_H, 200, Pal.BUTTON_H), false)
	_upgrades.disabled = true                 # built on the Pitch: the count, not a door
	_upgrades.tooltip_text = "The Clinic's upgrades are built on the Pitch"


func show_state(s) -> void:
	sim = s
	var sig := "%s|%d|%d|%s|%d|%s|%.1f|%s|%d|%d" % [str(sim.wounds), int(sim.hp), int(sim.max_hp()), str(sim.on_mission()), int(sim.cash), str(sim.yard_picks.get("clinic", [])), sim.rest_rate(), sim.cls, sim.supplies_held(), sim.supplies_in]
	if sig == _shown:
		return
	_shown = sig
	var path: String = Body.figure_for(str(sim.cls))
	if path != _figure_path:
		_figure_path = path
		_figure.texture = null if path == "" else Body._cropped(load(path) if ResourceLoader.exists(path) else ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(path))))
	var n: int = sim.wounds.size()
	_head.text = "THE RUNNER · %d OF 3 WOUNDS" % n if n > 0 else "THE RUNNER · NO WOUNDS"
	# the rows: the wounds first, numbered as they're drawn on the body, then the areas unhurt, dashed
	var order: Array = Data.WOUND_AREAS.filter(func(a): return sim.wounds.has(a)) + Data.WOUND_AREAS.filter(func(a): return not sim.wounds.has(a))
	var y: float = UI.HEAD_H + 10
	_marks = []
	var out: bool = sim.on_mission()
	for k in range(order.size()):
		var a: String = order[k]
		var r: Dictionary = _rows[Data.WOUND_AREAS.find(a)]
		var p: Panel = r["panel"]
		var spec: Dictionary = Data.WOUND_AREA[a]
		p.position.y = y
		var hurt: bool = sim.wounds.has(a)
		for l in [r["title"], r["effect"], r["num"]] + r["from"]:
			l.visible = hurt
		r["treat"].visible = hurt
		r["empty"].visible = not hurt
		if hurt:
			var w: Dictionary = sim.wounds[a]
			_marks.append([a, _marks.size() + 1])
			r["num_l"].text = str(_marks.size())
			p.size.y = ROW_H
			(p.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color(Pal.BAD, 0.6)
			UI.fit(r["title"], ["%s · %s" % [spec["name"], w["what"]], str(spec["name"])])
			r["effect"].text = "−%d%% %s until treated" % [sim.wound_pct(), sim.wound_stat_name(str(w["stat"]))]
			var site: String = Words.mid(str(w["from"]))
			UI.fit(r["from"][0], ["Came back from %s" % site, "From %s" % site, site])
			UI.fit(r["from"][1], ["%d%% HP when it hit" % int(w["hp_pct"]), "%d%% HP" % int(w["hp_pct"])])
			var w_cost: int = sim.wound_cost(a)
			UI.fit_button(r["treat"], ["Treat · %s" % Fmt.group(w_cost), "Treat · %s" % Fmt.short_num(w_cost), "Treat"])
			r["treat"].disabled = out or not sim.can_treat_wound(a)
			y += ROW_H + ROW_GAP
		else:
			p.size.y = EMPTY_H
			(p.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Pal.CARD_LINE
			r["empty"].text = "%s · nothing" % spec["name"]
			y += EMPTY_H + ROW_GAP
	_note.position.y = y
	UI.fit(_note, ["Three is the most a runner carries: one to the head, the chest, the legs", "Three at most: head, chest, legs"] if n > 0 else ["A bad run home leaves a wound; the Clinic sees to it", "Wounds are seen to here"])
	# the HP as it rests
	var full: bool = sim.hp >= sim.max_hp() - 0.5
	_bar_left.text = "HP %d of %d" % [sim.hp_shown(), sim.max_hp_shown()]
	if full:
		_bar_right.text = "Full"
		_bar_right.add_theme_color_override("font_color", Pal.GOOD)
	elif out:
		_bar_right.text = "Out on a run"
		_bar_right.add_theme_color_override("font_color", Pal.TEXT_2)
	else:
		var rr: float = sim.rest_rate()
		var left: String = Fmt.mss((sim.max_hp() - sim.hp) / rr) if rr > 0.0 else ""
		UI.fit(_bar_right, ["Resting +%.1f a second · full in %s" % [rr, left], "+%.1f/s · full in %s" % [rr, left], "full in %s" % left])
		_bar_right.add_theme_color_override("font_color", Pal.TEXT_2)
	var share: float = clampf(sim.hp / maxf(sim.max_hp(), 1.0), 0.0, 1.0)
	_fill.size.x = roundf(_track.size.x * share)
	(_fill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.GOOD if share > 0.5 else Pal.WARN
	# one button for the lot: every wound and the HP; one wound alone and full HP, that wound by name
	var cost: int = sim.treat_cost()
	if out:
		_all.text = "The runner is out"
		_all.disabled = true
	elif n == 0 and full:
		_all.text = "Fit for duty"
		_all.disabled = true
	elif n == 0:
		UI.fit_button(_all, ["Heal · %s" % Fmt.money(cost), "Heal · %s" % Fmt.short_num(cost)])
		_all.disabled = sim.cash < cost
	elif n == 1 and full:
		var a1: String = sim.wounds.keys()[0]
		var nm: String = str(Data.WOUND_AREA[a1]["name"]).to_lower()
		UI.fit_button(_all, ["Treat the %s · %s" % [nm, Fmt.money(cost)], "Treat the %s · %s" % [nm, Fmt.money_k(cost)], "Treat · %s" % Fmt.money_k(cost)])
		_all.disabled = sim.cash < cost
	else:
		UI.fit_button(_all, ["Treat everything · %s" % Fmt.money(cost), "Treat everything · %s" % Fmt.money_k(cost), "Treat everything · %s" % Fmt.short_num(cost), "Treat all · %s" % Fmt.short_num(cost)])
		_all.disabled = sim.cash < cost
	UI.style_button(_all, not _all.disabled)
	var picks: int = 0
	for c in range(5):
		if sim.yard_side("clinic", c) != "":
			picks += 1
	_upgrades.text = "Upgrades %d/5" % picks
	_show_supplies(out)
	queue_redraw()
	_over.queue_redraw()


## Her supplies' strip (28 Oct): what's in the stash, the step she's at and what the next gives, Hand in.
func _show_supplies(out: bool) -> void:
	var held: int = sim.supplies_held()
	var step: int = sim.clinic_step()
	var steps: int = Data.CLINIC_STEPS.size()
	UI.fit(_sup_head, ["MEDICAL SUPPLIES · %d IN THE STASH" % held, "SUPPLIES · %d HELD" % held, "SUPPLIES · %d" % held])
	var next: int = sim.clinic_next_need()
	if next < 0:
		UI.fit(_sup_line, ["Her shelf's at its best: step %d of %d" % [step, steps], "Her shelf's at its best", "At its best"])
	else:
		var what: String = Words.SUPPLIES_NEXT[step]
		UI.fit(_sup_line, ["Step %d of %d · next, %d more: %s" % [step, steps, next, what.to_lower()], "Step %d of %d · %d more: %s" % [step, steps, next, what.to_lower()],
			"Step %d/%d · %d to the next" % [step, steps, next], "%d to the next" % next])
	UI.fit_button(_hand, ["Hand in %d" % held, "Hand in"] if held > 0 else (["The runner is out", "Out"] if out else ["None to hand in", "None held"]))
	_hand.disabled = not sim.can_hand_in()
	UI.style_button(_hand, not _hand.disabled)


func _hand_in() -> void:
	if sim != null and sim.hand_in_supplies() > 0:
		_shown = ""
		handed.emit()


## The figure as drawn: the drawing's rect in the box (kept to its aspect, centred), or the box for the outline.
func figure_rect() -> Rect2:
	if _figure.texture == null:
		return Rect2(Vector2.ZERO, Vector2(BODY_W, BODY_H))
	var ts: Vector2 = _figure.texture.get_size()
	var k: float = minf(BODY_W / ts.x, BODY_H / ts.y)
	var fs: Vector2 = ts * k
	return Rect2((Vector2(BODY_W, BODY_H) - fs) / 2.0, fs)


## Where a wound shows: the head, the chest, the legs, by their share of the figure's height; the number at its side.
func mark_at(area: String) -> Vector2:
	var r := figure_rect()
	var y: float = {"head": 0.11, "chest": 0.32, "legs": 0.72}.get(area, 0.5)
	var x: float = 0.30 if area == "legs" else 0.72
	return r.position + Vector2(r.size.x * x, r.size.y * y)


func _draw() -> void:
	var o := Vector2(0, UI.HEAD_H + 10)
	draw_rect(Rect2(o, Vector2(BODY_W, BODY_H)), Pal.BG)
	if _figure.texture != null:
		return
	# no drawing for the past: the outline - a head, a neck, the shoulders and the arms, the trunk, two legs
	var skin := Pal.BUTTON
	var line := Color("4a515a")
	var body := func(pts: Array) -> void:
		var poly := PackedVector2Array()
		for p in pts:
			poly.append(o + p)
		draw_colored_polygon(poly, skin)
		poly.append(poly[0])
		draw_polyline(poly, line, 2.0)
	draw_circle(o + Vector2(95, 50), 28, skin)
	draw_arc(o + Vector2(95, 50), 28, 0, TAU, 32, line, 2.0)
	body.call([Vector2(85, 78), Vector2(105, 78), Vector2(105, 94), Vector2(85, 94)])
	body.call([Vector2(50, 96), Vector2(140, 96), Vector2(148, 112), Vector2(166, 196), Vector2(156, 200), Vector2(138, 140), Vector2(136, 206), Vector2(54, 206), Vector2(52, 140), Vector2(34, 200), Vector2(24, 196), Vector2(42, 112)])
	body.call([Vector2(56, 206), Vector2(92, 206), Vector2(88, 376), Vector2(64, 376)])
	body.call([Vector2(98, 206), Vector2(134, 206), Vector2(126, 376), Vector2(102, 376)])


## The wounds over the figure: the area washed red, its number beside it.
func _draw_marks() -> void:
	if sim == null:
		return
	var r := figure_rect()
	var hurt := Color(Pal.BAD, 0.35)
	for m in _marks:
		var a: String = m[0]
		var cx: float = r.position.x + r.size.x * 0.5
		match a:
			"head":
				var hc := Vector2(cx, r.position.y + r.size.y * 0.11)
				_over.draw_circle(hc, r.size.y * 0.065, hurt)
			"chest":
				_over.draw_rect(Rect2(Vector2(cx - r.size.x * 0.22, r.position.y + r.size.y * 0.2), Vector2(r.size.x * 0.44, r.size.y * 0.24)), hurt)
			"legs":
				_over.draw_rect(Rect2(Vector2(cx - r.size.x * 0.2, r.position.y + r.size.y * 0.6), Vector2(r.size.x * 0.4, r.size.y * 0.25)), hurt)
		var c: Vector2 = mark_at(a)
		c.x = clampf(c.x, 14.0, BODY_W - 14.0)
		_over.draw_circle(c, 13, Pal.BAD)
		var f: Font = get_theme_default_font()
		var t: String = str(m[1])
		var tw: float = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		_over.draw_string(f, c + Vector2(-tw / 2.0, 6), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Pal.BG)


func _treat(a: String) -> void:
	if sim != null and sim.treat_wound(a):
		_shown = ""
		acted.emit()


func _treat_all() -> void:
	if sim == null:
		return
	var ok: bool = sim.treat() if (sim.hp < sim.max_hp() - 0.5 or sim.wounds.size() != 1) else sim.treat_wound()
	if ok:
		_shown = ""
		acted.emit()


## For the tests: the supplies' strip, its Hand in.
func supplies_strip() -> Dictionary:
	return {"panel": _sup, "head": _sup_head, "line": _sup_line, "hand": _hand}


## For the tests: a row by its area.
func row(a: String) -> Dictionary:
	return _rows[Data.WOUND_AREAS.find(a)]


func text_nodes() -> Array:
	var out: Array = [_head, _note, _bar_left, _bar_right, _all, _upgrades, _sup_head, _sup_line, _hand]
	for r in _rows:
		for l in [r["title"], r["effect"], r["empty"], r["treat"]] + r["from"]:
			if l.visible:
				out.append(l)
	return out
