extends Control
## The town and the purse on one card two wide (Yard-C, 7 Oct): the cards that
## were pure information, side by side. Left, the town: the zones with their
## depths, the Yard's trade, what opens the next zone. Right, the purse: cash,
## notes and scrap, kit worth, prices. The foot: the clock and the autosave at
## the left, Move the Yard at the right when the Yard can move. The owner
## fills it (`show_data`): {title, headline, unit, left: {kicker, lines, note},
## right: {kicker, lines, note}, status, button: {text, action, enabled}}.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")

const W := 2 * Pal.CARD_W + Pal.CARD_GAP                     # 760
const H := Pal.CARD_H                                        # 424
const PAD := Pal.PAD
const INNER := W - 2 * PAD
const COL_GAP := 24
@warning_ignore("integer_division")
const COL_W := (INNER - COL_GAP) / 2                         # 348
const KICK_Y := 112
const LINES_Y := KICK_Y + 30
const LINES := 5
const NOTE_H := 30
const BUTTON_W := 220

var _title: Label
var _headline: Label
var _unit: Label
var _status: Label
var _kickers: Array[Label] = []
var _labels: Array = []                                      # [column][row]
var _values: Array = []
var _notes: Array[Label] = []
var _button: Button
var _action := Callable()


func _init() -> void:
	size = Vector2(W, H)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_PASS
	UI.panel(self, Rect2(Vector2.ZERO, size), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_title = UI.label(self, Rect2(PAD, 14, INNER, 40), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_headline = UI.label(self, Rect2(PAD, 54, INNER, 52), "", "SemiBold", Pal.HEADLINE, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	var hf := UI.font("SemiBold")
	var uf := UI.font("Medium", false)
	var base := 54 + (52 - hf.get_height(Pal.HEADLINE)) / 2.0 + hf.get_ascent(Pal.HEADLINE)
	var uy := roundf(base - uf.get_ascent(Pal.LINE) - (34 - uf.get_height(Pal.LINE)) / 2.0)
	_unit = UI.label(self, Rect2(PAD, uy, INNER, 34), "", "Medium", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(2):
		var x: int = PAD + k * (COL_W + COL_GAP)
		_kickers.append(UI.head(self, Rect2(x, KICK_Y, COL_W, 24), ""))
		var ls: Array = []
		var vs: Array = []
		for i in range(LINES):
			var y := LINES_Y + i * Pal.LINE_H
			ls.append(UI.label(self, Rect2(x, y, COL_W, Pal.LINE_H), "", "Regular", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
			vs.append(UI.label(self, Rect2(x, y, COL_W, Pal.LINE_H), "", "Medium", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT))
		_labels.append(ls)
		_values.append(vs)
		_notes.append(UI.label(self, Rect2(x, LINES_Y + LINES * Pal.LINE_H + 4, COL_W, NOTE_H), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	var by := H - PAD - Pal.BUTTON_H
	_status = UI.label(self, Rect2(PAD, by, INNER - BUTTON_W - 16, Pal.BUTTON_H), "", "Medium", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_button = UI.button(self, Rect2(W - PAD - BUTTON_W, by, BUTTON_W, Pal.BUTTON_H), false)
	_button.pressed.connect(_press)
	_button.visible = false


func show_data(d: Dictionary) -> void:
	_title.text = str(d.get("title", ""))
	_headline.text = str(d.get("headline", ""))
	_unit.text = str(d.get("unit", ""))
	_unit.position.x = PAD + ceilf(UI.text_width(_headline, _headline.text)) + 10 if _headline.text != "" else float(PAD)
	for k in range(2):
		var col: Dictionary = d.get("left" if k == 0 else "right", {})
		_kickers[k].text = str(col.get("kicker", "")).to_upper()
		var lines: Array = col.get("lines", [])
		for i in range(LINES):
			var on: bool = i < lines.size()
			_labels[k][i].text = str(lines[i][0]) if on else ""
			if on and lines[i][1] is Array:
				# forms, longest first, fitted to what the label leaves of the line (the pair rule the tests read)
				_values[k][i].size.x = COL_W - 16 - ceilf(UI.text_width(_labels[k][i], _labels[k][i].text))
				UI.fit(_values[k][i], lines[i][1])
				_values[k][i].size.x = COL_W
			else:
				_values[k][i].text = str(lines[i][1]) if on else ""
			var tone: String = str(lines[i][2]) if on and lines[i].size() > 2 else ""
			_values[k][i].add_theme_color_override("font_color", Pal.ACCENT if tone == "accent" else (Pal.tone_color(tone) if tone != "" else Pal.TEXT))
		var note: Variant = col.get("note", "")
		if note is Array:
			UI.fit(_notes[k], note)
		else:
			_notes[k].text = str(note)
		var nt: String = str(col.get("note_tone", ""))
		_notes[k].add_theme_color_override("font_color", Pal.tone_color(nt) if nt != "" else Pal.TEXT_2)
	var b: Dictionary = d.get("button", {})
	_button.visible = not b.is_empty()
	if _button.visible:
		_button.text = str(b["text"])
		_button.disabled = not bool(b.get("enabled", true))
		_action = b["action"]
		UI.style_button(_button, bool(b.get("primary", false)))
	_status.size.x = INNER - (BUTTON_W + 16 if _button.visible else 0)     # the room first, then the fit
	var status: Variant = d.get("status", "")
	if status is Array:
		UI.fit(_status, status)
	else:
		_status.text = str(status)


func _press() -> void:
	if _action.is_valid():
		_action.call()
		acted.emit()


func text_nodes() -> Array:
	var out: Array = [_title, _headline, _unit, _status]
	for k in range(2):
		out.append(_kickers[k])
		out.append_array(_labels[k])
		out.append_array(_values[k])
		out.append(_notes[k])
	if _button.visible:
		out.append(_button)
	return out


func line_pairs() -> Array:
	var out: Array = []
	for k in range(2):
		for i in range(LINES):
			if _labels[k][i].text != "":
				out.append([_labels[k][i], _values[k][i]])
	return out
