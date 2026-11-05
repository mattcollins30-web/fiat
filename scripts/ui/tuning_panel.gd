extends Panel
## The tuning rules (BUILD50 N, act_two.md §3): a night's rolled links take their codes by these - codes wanted, codes
## never taken, Kev's wagers accepted (none by default) - checked top down, the first rule naming a code or a wager
## deciding it, as the loot rules; and the odds floor "Auto: keep going" holds to. On the Radio, over the papers and the
## decoder while open, as Kev's wagers are.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Words := preload("res://scripts/sim/words.gd")
const Data := preload("res://scripts/sim/data.gd")
const Sim := preload("res://scripts/sim/sim.gd")

const W := 1012
const PAD := 24
const INNER := W - 2 * PAD
const ROWS_Y := 128
const ROW_H := 44
const ROW_GAP := 6
const NUM_W := 30
const KIND_W := 190
const VALUE_W := 330
const ON_W := 90
const UP_W := 80
const DROP_W := 120

var sim
var kicker: Label
var title: Label
var sub: Label
var rows: Array = []                   # {panel, num, kind, value, on, up, drop}
var none: Label
var floor_head: Label
var floor_down: Button
var floor_value: Label
var floor_up: Button
var add: Button
var done: Button


func _init() -> void:
	size = Vector2(W, 620)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 2, Pal.ACCENT))
	kicker = UI.label(self, Rect2(PAD, 14, INNER, 22), Words.NIGHT["rules_kicker"], "Medium", Pal.CELL_TEXT, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.track(kicker, 1)
	title = UI.label(self, Rect2(PAD, 38, INNER, 40), Words.NIGHT["rules_title"], "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	sub = UI.label(self, Rect2(PAD, 84, INNER, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(Data.NIGHT_RULES_MAX):
		var p := UI.panel(self, Rect2(PAD, ROWS_Y + k * (ROW_H + ROW_GAP), INNER, ROW_H), UI.box(Pal.PANEL, 6, 1, Pal.CARD_LINE))
		var r := {"panel": p}
		r["num"] = UI.label(p, Rect2(10, 0, NUM_W, ROW_H), str(k + 1), "SemiBold", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT)
		var x: float = 10 + NUM_W
		r["kind"] = _btn(p, Rect2(x, 4, KIND_W, ROW_H - 8), _step.bind(k, "kind"))
		x += KIND_W + 8
		r["value"] = _btn(p, Rect2(x, 4, VALUE_W, ROW_H - 8), _step.bind(k, "value"))
		x += VALUE_W + 8
		r["on"] = _btn(p, Rect2(x, 4, ON_W, ROW_H - 8), _step.bind(k, "on"))
		x += ON_W + 8
		r["up"] = _btn(p, Rect2(x, 4, UP_W, ROW_H - 8), _up.bind(k))
		x += UP_W + 8
		r["drop"] = _btn(p, Rect2(x, 4, DROP_W, ROW_H - 8), _drop.bind(k))
		rows.append(r)
	none = UI.label(self, Rect2(PAD, ROWS_Y, INNER, ROW_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	floor_head = UI.label(self, Rect2(PAD, 0, 380, ROW_H), Words.NIGHT["floor_head"], "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	floor_down = _btn(self, Rect2(PAD + 390, 0, 56, ROW_H), _floor.bind(-1))
	floor_down.text = "−"
	floor_value = UI.label(self, Rect2(PAD + 452, 0, 150, ROW_H), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	floor_up = _btn(self, Rect2(PAD + 608, 0, 56, ROW_H), _floor.bind(1))
	floor_up.text = "+"
	add = UI.button(self, Rect2(PAD, 0, 240, Pal.BUTTON_H), false)
	add.pressed.connect(_add)
	done = UI.button(self, Rect2(W - PAD - 200, 0, 200, Pal.BUTTON_H), true)
	done.pressed.connect(func():
		visible = false
		acted.emit())
	for b in [add, done]:
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG + 2)
	visible = false


func _btn(parent: Control, r: Rect2, fn: Callable) -> Button:
	var b := UI.button(parent, r, false)
	b.add_theme_font_size_override("font_size", Pal.CELL_TEXT)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.pressed.connect(fn)
	return b


func open(s) -> void:
	sim = s
	visible = true
	show_state(sim)


func show_state(s) -> void:
	sim = s
	if not visible:
		return
	UI.fit(sub, [Words.NIGHT["rules_sub"], Words.NIGHT["rules_sub"].get_slice(":", 0)])
	var n: int = sim.night_rules.size()
	none.visible = n == 0
	UI.fit(none, [Words.NIGHT["rule_none"], Words.NIGHT["rule_none"].get_slice(":", 0)])
	for k in range(rows.size()):
		var r: Dictionary = rows[k]
		r["panel"].visible = k < n
		if k >= n:
			continue
		var rule: Dictionary = sim.night_rules[k]
		var kind: String = str(rule["kind"])
		UI.fit_button(r["kind"], [Words.NIGHT["rule_" + kind]])
		UI.style_button(r["kind"], false, "good" if kind == "want" else ("bad" if kind == "never" else "warn"))
		var v: String = Sim.wager_cond_chip({"cond": str(rule["cond"])}) if kind == "wager" else str(rule["code"])
		UI.fit_button(r["value"], [v])
		var on: bool = bool(rule.get("on", true))
		UI.fit_button(r["on"], [Words.NIGHT["on"] if on else Words.NIGHT["off"]])
		r["up"].visible = k > 0
		UI.fit_button(r["up"], [Words.NIGHT["up"]])
		UI.fit_button(r["drop"], [Words.NIGHT["drop"]])
	var y: float = ROWS_Y + maxi(1, n) * (ROW_H + ROW_GAP) + 14
	for c in [floor_head, floor_down, floor_value, floor_up]:
		c.position.y = y
	floor_value.text = Words.NIGHT["floor"] % roundi(sim.night_floor * 100.0)
	y += ROW_H + 20
	add.position.y = y
	done.position.y = y
	add.disabled = n >= Data.NIGHT_RULES_MAX
	UI.fit_button(add, [Words.NIGHT["add"]])
	UI.fit_button(done, [Words.NIGHT["done"]])
	size.y = y + Pal.BUTTON_H + PAD


func _step(k: int, what: String) -> void:
	sim.night_rule_step(k, what)
	show_state(sim)
	acted.emit()


func _up(k: int) -> void:
	sim.night_rule_up(k)
	show_state(sim)
	acted.emit()


func _drop(k: int) -> void:
	sim.night_rule_drop(k)
	show_state(sim)
	acted.emit()


func _floor(by: int) -> void:
	sim.night_floor_step(by)
	show_state(sim)
	acted.emit()


func _add() -> void:
	sim.night_rule_add()
	show_state(sim)
	acted.emit()


func text_nodes() -> Array:
	if not visible:
		return []
	var out: Array = [kicker, title, sub, floor_head, floor_down, floor_value, floor_up, add, done]
	if none.visible:
		out.append(none)
	for r in rows:
		if r["panel"].visible:
			out.append_array([r["num"], r["kind"], r["value"], r["on"], r["drop"]])
			if r["up"].visible:
				out.append(r["up"])
	return out
