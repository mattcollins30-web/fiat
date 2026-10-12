extends Control
## The pick panel (Pick-A, 6 Oct): the same column twice, so the pick and what's
## fitted in its slot read side by side. Each column: a kicker with the cells
## and a price tag, then the item head (name, chips, the figure, what it takes,
## the affixes as chips). The foot: the verdict and the deltas against the
## fitted, the item's own line under them (or a hint, when there is one), and
## the buttons at the right. The run's pack and the Lock-up's stash share it,
## so the two read the same. Each column sits in its own box on the run
## screen's line (7 Oct, Pick-B), the pick's in the accent, so two pieces of
## gear read as two pieces side by side; the box runs BOX_OUT past the column
## each side, so the column's words keep their width.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const ItemHead := preload("res://scripts/ui/item_head.gd")

const PAD := 20
const KICK_Y := 8
const KICK_H := 24
const HEAD_Y := KICK_Y + KICK_H + 4                           # 36
const FOOT_H := 44
const BUTTONS := 3
const DELTAS := 4
const LINES := 4                                              # the right column's lines when nothing is fitted (a med, a part, a paper)
const TAG_PAD := 8
const BOX_OUT := 8                                            # each piece in its own box (7 Oct): the run screen's line, drawn this far outside the column, so the column keeps its width (the words were cut for it at first)
const BOX_Y := 2

var w: int
var h: int
var col_w: int
var foot_y: int
var _panel: Panel
var _boxes: Array[Panel] = []                                 # one a column: the pick's lined in the accent, the fitted's in the card line
var _kickers: Array[Label] = []
var _tags: Array[Panel] = []
var _tag_labels: Array[Label] = []
var _heads: Array = []                                        # two ItemHeads
var _right_title: Label                                       # the right column as words: a title and lines
var _right_lines: Array[Label] = []
var _empty_title: Label                                       # nothing picked: a title and lines across the panel
var _empty_lines: Array[Label] = []
var _verdict: Label
var _deltas: Array[Label] = []
var _words: Label                                             # the item's own line, or the hint
var _buttons: Array[Button] = []
var _actions: Array = []
var _hint_on := false
var _hint_options: Array = []      # the hint's forms, long to short: fitted to the room left of the buttons


func _init(width: int, height: int) -> void:
	w = width
	h = height
	col_w = (w - 3 * PAD) / 2
	foot_y = h - 8 - FOOT_H
	size = Vector2(w, h)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_panel = UI.panel(self, Rect2(0, 0, w, h), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	for k in range(2):
		var x: int = PAD + k * (col_w + PAD)
		var box := UI.panel(_panel, Rect2(x - BOX_OUT, BOX_Y, col_w + 2 * BOX_OUT, foot_y - 8 - BOX_Y), UI.box(Color.TRANSPARENT, 8, 1, Pal.ACCENT if k == 0 else Pal.CARD_LINE))
		box.visible = false
		_boxes.append(box)
		var cx: int = x
		var cw: int = col_w
		_kickers.append(UI.head(_panel, Rect2(cx, KICK_Y, cw - 100, KICK_H), ""))
		var tag := UI.panel(_panel, Rect2(cx + cw - 10, KICK_Y + 1, 10, KICK_H - 2), UI.box(Pal.BG, 6, 1, Pal.CARD_LINE))
		_tags.append(tag)
		_tag_labels.append(UI.label(tag, Rect2(TAG_PAD, 0, 10, KICK_H - 2), "", "Medium", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT))
		var head := ItemHead.new(cw, true)
		head.position = Vector2(cx, HEAD_Y)
		head.visible = false
		_panel.add_child(head)
		_heads.append(head)
	var rx: int = PAD * 2 + col_w
	var rw: int = col_w
	_right_title = UI.label(_panel, Rect2(rx, HEAD_Y, rw, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(LINES):
		_right_lines.append(UI.label(_panel, Rect2(rx, HEAD_Y + 40 + i * 28, rw, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_empty_title = UI.label(_panel, Rect2(PAD, 10, w - 2 * PAD, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(LINES):
		_empty_lines.append(UI.label(_panel, Rect2(PAD, 48 + i * 28, w - 2 * PAD, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_verdict = UI.label(_panel, Rect2(PAD, foot_y, 10, 24), "", "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(DELTAS):
		_deltas.append(UI.label(_panel, Rect2(PAD, foot_y, 10, 24), "", "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false))
	_words = UI.label(_panel, Rect2(PAD, foot_y + 24, 10, 20), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(BUTTONS):
		var b := UI.button(_panel, Rect2(0, foot_y, 240, FOOT_H), i == 0)
		b.pressed.connect(_press.bind(i))
		b.visible = false
		_buttons.append(b)
		_actions.append(Callable())


# ------------------------------------------------------------------ showing

## Nothing picked: a title and lines across the panel; the caller sets the buttons after.
func show_empty(title: String, lines: Array) -> void:
	_clear()
	_empty_title.visible = true
	_empty_title.text = title
	for i in range(LINES):
		_empty_lines[i].visible = true
		_empty_lines[i].text = str(lines[i]) if i < lines.size() else ""


## The pick in the left column. `kicker` is its place ("The pick · in the pack"),
## the cells are added; `tail` is the head's tail (what it takes).
func show_pick(it: Dictionary, sim, kicker: String, tail = "", extra = "") -> void:
	_clear()
	_boxes[0].visible = true
	_kickers[0].visible = true
	_kickers[0].text = (kicker + " · " + _cells(it)).to_upper()
	_tag(0, Fmt.money(sim.sell_price(it)))
	_heads[0].visible = true
	_heads[0].show_item(it, sim, tail, extra, false)
	_words.text = Words.UNIQUES.get(it["unique"], Words.item_words(it["base"])) if it.has("unique") else Words.item_words(it["base"])


## The right column as the fitted item, laid the same as the pick.
func show_fitted(fitted: Dictionary, sim, kicker := "Fitted now", tail = "", extra = "") -> void:
	_boxes[1].visible = true
	_kickers[1].visible = true
	_kickers[1].text = (kicker + " · " + _cells(fitted)).to_upper()
	_tag(1, Fmt.money(sim.sell_price(fitted)))
	_heads[1].visible = true
	_heads[1].show_item(fitted, sim, tail, extra, false)


## The right column as words: a kicker, a title and lines (a med's rig, a part's bench, nothing fitted).
func show_right_words(kicker: String, title: String, lines: Array) -> void:
	_boxes[1].visible = kicker != "" or title != "" or not lines.is_empty()     # no box round nothing
	_kickers[1].visible = kicker != ""
	_kickers[1].text = kicker.to_upper()
	_kickers[1].size.x = col_w
	_right_title.visible = true
	_right_title.text = title
	for i in range(LINES):
		_right_lines[i].visible = true
		_right_lines[i].add_theme_color_override("font_color", Pal.TEXT_2)
		if i < lines.size():
			if lines[i] is Array:
				UI.fit(_right_lines[i], lines[i])
			else:
				_right_lines[i].text = str(lines[i])
		else:
			_right_lines[i].text = ""


## The foot's first row: the verdict in its tone, then the deltas, dropped from the right when they don't fit.
func set_verdict(verdict: String, tone: String, deltas: Array) -> void:
	_verdict.text = verdict
	_verdict.visible = verdict != ""
	_verdict.add_theme_color_override("font_color", Pal.tone_color(tone) if tone != "" else Pal.TEXT_2)
	_verdict.size.x = ceilf(UI.text_width(_verdict, verdict)) + 2
	var x: float = PAD + (_verdict.size.x + 18 if verdict != "" else 0.0)
	var room: float = _foot_left_edge()
	for i in range(DELTAS):
		var l := _deltas[i]
		l.visible = false
		if i >= deltas.size():
			continue
		var up: bool = float(deltas[i][0]) > 0.0
		l.text = "%s %s" % ["▲" if up else "▼", deltas[i][1]]
		l.add_theme_color_override("font_color", Pal.GOOD if up else Pal.BAD)
		l.size.x = ceilf(UI.text_width(l, l.text)) + 2
		if x + l.size.x > room:
			break
		l.position.x = x
		l.visible = true
		x += l.size.x + 16


## A hint in place of the item's own line: what stops the button, mostly.
func set_hint(text: String) -> void:
	set_hint_options([text])


## A hint in forms long to short (11 Oct: two hints on one line ran past the buttons): the first that fits is shown.
func set_hint_options(options: Array) -> void:
	_hint_options = options.filter(func(o): return str(o) != "")
	_hint_on = not _hint_options.is_empty()
	if _hint_on:
		_words.text = str(_hint_options[0])
		_lay_foot()


## The buttons at the foot's right: [{text, action, enabled, primary, tone}], the first primary by default.
func set_buttons(items: Array) -> void:
	var x: float = w - PAD
	for i in range(BUTTONS):
		var b := _buttons[i]
		b.visible = i < items.size()
		if not b.visible:
			continue
		var d: Dictionary = items[i]
		b.text = str(d["text"])
		b.disabled = not bool(d.get("enabled", true))
		b.size.x = ceilf(UI.text_width(b, b.text)) + 48
		_actions[i] = d["action"]
		UI.style_button(b, bool(d.get("primary", i == 0)), str(d.get("tone", "")))
	# laid from the right
	for i in range(items.size() - 1, -1, -1):
		if i < BUTTONS:
			x -= _buttons[i].size.x
			_buttons[i].position.x = x
			x -= 12
	_lay_foot()


## The foot's left side stops where the buttons start.
func _foot_left_edge() -> float:
	var x: float = w - PAD
	for b in _buttons:
		if b.visible:
			x = minf(x, b.position.x)
	return x - 12


func _lay_foot() -> void:
	var edge := _foot_left_edge()
	_words.size.x = maxf(80.0, edge - PAD)
	if _hint_on and not _hint_options.is_empty():
		UI.fit(_words, _hint_options)
	_words.visible = _words.text != ""
	if _hint_on:
		_words.add_theme_color_override("font_color", Pal.TEXT_3)
	else:
		_words.add_theme_color_override("font_color", Pal.TEXT_2)
		if _words.text != "":
			UI.fit_sentences(_words, _words.text)
	# the deltas past the edge go
	for l in _deltas:
		if l.visible and l.position.x + l.size.x > edge:
			l.visible = false


func _clear() -> void:
	for k in range(2):
		_boxes[k].visible = false
		_kickers[k].visible = false
		_tags[k].visible = false
		_heads[k].visible = false
	_right_title.visible = false
	for l in _right_lines:
		l.visible = false
	_empty_title.visible = false
	for l in _empty_lines:
		l.visible = false
	_verdict.visible = false
	_verdict.text = ""
	for l in _deltas:
		l.visible = false
	_words.text = ""
	_words.visible = false
	_hint_on = false
	for b in _buttons:
		b.visible = false


func _tag(k: int, text: String) -> void:
	var l := _tag_labels[k]
	l.text = text
	var tw: float = ceilf(UI.text_width(l, text))
	l.size.x = tw
	var tag := _tags[k]
	tag.visible = true
	tag.size.x = tw + 2 * TAG_PAD
	tag.position.x = PAD + k * (col_w + PAD) + col_w - tag.size.x
	_kickers[k].size.x = col_w - tag.size.x - 12


static func _cells(it: Dictionary) -> String:
	var n: int = Items.size(it)
	return "%d cell%s" % [n, "" if n == 1 else "s"]


## What fitting the pick changes: [[delta, words], ...], the headline figure first, then each affix that differs.
static func deltas_of(it: Dictionary, fitted: Dictionary) -> Array:
	var out: Array = []
	var a := Items.headline(it)
	var b := Items.headline(fitted)
	var d := float(a[0]) - float(b[0])
	if absf(d) >= 0.5:
		out.append([d, "%.0f %s" % [absf(d), {"damage/s": "dmg/s", "armour": "arm", "capacity": "cap"}.get(a[1], a[1])]])
	for ax in Data.AFFIXES:
		var da := Items.affix_total(it, ax["stat"]) - Items.affix_total(fitted, ax["stat"])
		if absf(da) >= 0.5:
			out.append([da, "%.0f%s %s" % [absf(da), "%" if ax["stat"].ends_with("_pct") else "", ax["short"]]])
	return out


## The verdict for a pick against what's worn, tried on (sim.compare, 11 Oct): [words, tone].
static func verdict_for(sim, it: Dictionary) -> Array:
	match sim.compare(it):
		1:
			return ["▲ Upgrade", "good"]
		-1:
			return ["▼ Downgrade", "bad"]
	return ["Sidegrade", "warn"]


## The deltas, a gun's damage read as the runner's with it on (its own figure alone missed what a damage % on the
## whole does, the secondary's third, a unique's rule), then each affix that differs.
static func deltas_for(sim, it: Dictionary, fitted: Dictionary) -> Array:
	var out: Array = deltas_of(it, fitted)
	if Data.SLOT_SCORE.get(str(it["slot"]), "") == "dps":
		out = out.filter(func(d): return not str(d[1]).ends_with("dmg/s"))
		var d: float = sim.fit_value(it) - sim.fit_value({}, str(it["slot"]))
		if absf(d) >= 0.05:
			out.push_front([d, ("%.1f dmg/s" if absf(d) < 10.0 else "%.0f dmg/s") % absf(d)])
	elif str(it["slot"]) in sim.SURV_SLOTS and fitted != null and not fitted.is_empty():
		# the body's figure first (12 Oct): what the arrow reads for a helmet or a coat, regen and resists in it
		var sg: float = sim.survival_gain(it) * 100.0
		if absf(sg) >= 0.5:
			out.push_front([sg, "%.0f%% survival" % absf(sg)])
	return out


func _press(i: int) -> void:
	if _actions[i].is_valid():
		_actions[i].call()
	acted.emit()


# ------------------------------------------------------------------ the tests

func text_nodes() -> Array:
	var out: Array = []
	for k in range(2):
		if _kickers[k].visible:
			out.append(_kickers[k])
		if _tags[k].visible:
			out.append(_tag_labels[k])
		if _heads[k].visible:
			out.append_array(_heads[k].text_nodes())
	if _right_title.visible:
		out.append(_right_title)
		out.append_array(_right_lines)
	if _empty_title.visible:
		out.append(_empty_title)
		out.append_array(_empty_lines)
	if _verdict.visible:
		out.append(_verdict)
	for l in _deltas:
		if l.visible:
			out.append(l)
	if _words.visible:
		out.append(_words)
	for b in _buttons:
		if b.visible:
			out.append(b)
	return out


func line_pairs() -> Array:
	var out := []
	for k in range(2):
		if _heads[k].visible:
			out.append_array(_heads[k].line_pairs())
	return out


## For the tests: the buttons showing, their text.
func button_texts() -> Array:
	var out := []
	for b in _buttons:
		if b.visible:
			out.append(b.text)
	return out


func press(i: int) -> void:
	if i < BUTTONS and _buttons[i].visible and not _buttons[i].disabled:
		_press(i)
