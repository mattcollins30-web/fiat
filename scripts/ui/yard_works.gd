extends Control
## The yard's jobs on one card two wide (Yard-C/D, 7 Oct): a row a job - its
## name and level, what it does now, what the next level does, and its own
## Build button - so the room reads as the place the yard is built, and no
## job hides behind "the cheapest first". The rows come from the owner
## (`show_jobs`): [{name, level, of, now: [forms], next: [forms], cost, can,
## action}], the forms longest first for the fit.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")

const W := 2 * Pal.CARD_W + Pal.CARD_GAP                     # 760
const H := Pal.CARD_H                                        # 424
const PAD := Pal.PAD
const INNER := W - 2 * PAD                                   # 720
const ROWS := 5
const ROWS_Y := 112
const ROW_H := 56
const NAME_W := 130
const BUTTON_W := 236
const BUTTON_H := 40
const COL_GAP := 14
const EFFECT_W := INNER - NAME_W - BUTTON_W - 2 * COL_GAP     # 356: "Now: ..." over "Next: ..."
const EFFECT_H := 26

var _title: Label
var _headline: Label
var _unit: Label
var _status: Label
var _rules: Array[Panel] = []
var _names: Array[Label] = []
var _levels: Array[Label] = []
var _nows: Array[Label] = []
var _nexts: Array[Label] = []
var _buttons: Array[Button] = []
var _actions: Array = []


func _init() -> void:
	size = Vector2(W, H)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_PASS
	UI.panel(self, Rect2(Vector2.ZERO, size), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_title = UI.label(self, Rect2(PAD, 14, INNER, 40), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_headline = UI.label(self, Rect2(PAD, 54, INNER, 52), "", "SemiBold", Pal.HEADLINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	var hf := UI.font("SemiBold")
	var uf := UI.font("Medium", false)
	var base := 54 + (52 - hf.get_height(Pal.HEADLINE)) / 2.0 + hf.get_ascent(Pal.HEADLINE)
	var uy := roundf(base - uf.get_ascent(Pal.LINE) - (34 - uf.get_height(Pal.LINE)) / 2.0)
	_unit = UI.label(self, Rect2(PAD, uy, INNER, 34), "", "Medium", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(ROWS):
		var y := ROWS_Y + i * ROW_H
		_rules.append(UI.panel(self, Rect2(PAD, y, INNER, 1), UI.box(Pal.CARD_LINE, 0)))
		var x := PAD
		_names.append(UI.label(self, Rect2(x, y + 5, NAME_W, 26), "", "SemiBold", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))
		_levels.append(UI.label(self, Rect2(x, y + 30, NAME_W, 22), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		x += NAME_W + COL_GAP
		_nows.append(UI.label(self, Rect2(x, y + 3, EFFECT_W, EFFECT_H), "", "Regular", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))
		_nexts.append(UI.label(self, Rect2(x, y + 3 + EFFECT_H, EFFECT_W, EFFECT_H), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		x += EFFECT_W + COL_GAP
		var b := UI.button(self, Rect2(x, y + (ROW_H - BUTTON_H) / 2, BUTTON_W, BUTTON_H), false)
		b.pressed.connect(_press.bind(i))
		_buttons.append(b)
		_actions.append(Callable())
	_status = UI.label(self, Rect2(PAD, ROWS_Y + ROWS * ROW_H + 2, INNER, 24), "", "Medium", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)


func show_jobs(title: String, headline: String, unit: String, jobs: Array, status: String) -> void:
	_title.text = title
	_headline.text = headline
	_unit.text = unit
	_unit.position.x = PAD + ceilf(UI.text_width(_headline, headline)) + 10 if headline != "" else PAD
	UI.fit(_status, [status, status.get_slice(";", 0)])
	for i in range(ROWS):
		var on: bool = i < jobs.size()
		_rules[i].visible = on
		_names[i].visible = on
		_levels[i].visible = on
		_nows[i].visible = on
		_nexts[i].visible = on
		_buttons[i].visible = on
		if not on:
			continue
		var j: Dictionary = jobs[i]
		_names[i].text = str(j["name"])
		_levels[i].text = "Level %d of %d" % [int(j["level"]), int(j["of"])]
		var now_forms: Array = []
		for f in j["now"]:
			now_forms.append("Now: " + str(f))
		UI.fit(_nows[i], now_forms)
		var b := _buttons[i]
		if int(j["cost"]) > 0:
			var next_forms: Array = []
			for f in j["next"]:
				next_forms.append("Next: " + str(f))
			UI.fit(_nexts[i], next_forms)
			b.text = _fit_button(b, ["Build (%s)" % Fmt.money(int(j["cost"])), Fmt.money(int(j["cost"]))])
			b.disabled = not bool(j["can"])
			_actions[i] = j["action"]
			UI.style_button(b, bool(j["can"]))
		else:
			_nexts[i].text = ""
			b.text = _fit_button(b, ["As good as it gets", "Built"])
			b.disabled = true
			_actions[i] = Callable()
			UI.style_button(b, false)


## A button's words, longest form that fits with the margins a button needs.
static func _fit_button(b: Button, options: Array) -> String:
	for o in options:
		if UI.text_width(b, o) + 32 <= b.size.x:
			return o
	return options.back()


## The tests' finger.
func press(i: int) -> void:
	_press(i)


func _press(i: int) -> void:
	if _actions[i].is_valid():
		_actions[i].call()
		acted.emit()


func text_nodes() -> Array:
	var out: Array = [_title, _headline, _unit, _status]
	for i in range(ROWS):
		if _names[i].visible:
			out.append_array([_names[i], _levels[i], _nows[i], _nexts[i], _buttons[i]])
	return out


func line_pairs() -> Array:
	return []
