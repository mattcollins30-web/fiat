extends Control
## The one card every room uses - 372 x 424 (Pithole's menu_shell.md §3).
##
## A title, the one headline figure the card is about, up to six figure lines, the
## consequence line, and up to two buttons - four in two rows in Fiat, which
## takes the last two lines' place; a button with a `tone` is coloured that
## tone. A card with nothing to do shows a state line where the buttons would
## be, so its shape never changes.
##
## Data, as the room presenters build it:
##   {title, headline, unit, bar: {fill, text, tone}, lines: [[label, value], ...],
##    note, note_tone, buttons: [{text, action: Callable, enabled, primary}], status,
##    tone}
##
## `unit` is the headline figure's unit in words, set smaller beside it, so a
## unit in plain words fits beside its figure.
##
## `chips` is a row of short words in boxes - what a site is, what a thing
## is - each [words, tone]; it takes a line's place after the bar. A line may
## carry a third entry, a tone, that colours its value (an element's colour for
## a resist or a damage type).
##
## `bar` is something running - a job, a wait, an offer ending - drawn under the
## headline, 0 to 1 full, with its timer inside (Pithole's menu_shell.md §16).
## It takes the first line's place, so a card with a bar holds five lines. The
## text is drawn twice, dark over the fill and light over the rest, so it reads
## wherever the fill has got to.
##
## `sketch` is a drawing from the sim's state - a building going up, a site's
## plan (scripts/ui/sketch.gd) - in the last three lines' place, so a card with
## a sketch holds three lines fewer. `corner` is a small one - the ground under
## a plot - at the right of the title's row, which the title makes room for.
##
## A job's bar is its button (Pithole's loop.md): `bar.action` makes it one.
## `ready` draws it as the card's main button - the job is stopped with work
## waiting; `repeat`, in seconds, presses it again every so often while the bar
## is held, by mouse or by the Deck's A - Storeys' stages take a click a second
## held; `smooth` eases the fill between the sim's ticks.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Sketch := preload("res://scripts/ui/sketch.gd")
const Band := preload("res://scripts/ui/band.gd")

const SKETCH_LINES := 3         # the lines a sketch takes
const CORNER_W := 64            # a corner sketch: at the right of the title's row
const CORNER_H := 36

## Off in the tests, so a bar is where the sim says the moment it's shown.
static var smooth_bars := true

const HEAD_Y := 54
const HEAD_H := 52
const UNIT_GAP := 10            # between the headline figure and its unit
const UNIT_H := 34
const BUTTON_GAP := 8
const BUTTON_ROOM := 32         # a button's text needs this much more: margins, and air
const LINES_Y := 112
const BAR_Y := 113              # in the first line's place
const BAR_H := 30
const CHIPS := 6
const CHIP_H := 26
const CHIP_PAD := 8
const CHIP_GAP := 6
const BAND_H := 140             # a card with a band: the title and the headline in it, the lines under
const LINES_Y_BAND := BAND_H + 8

var _bg: Panel
var _band: Band                 # the art band, for a card that's a place (the radio's sites)
var _lines_y := LINES_Y         # where the lines start: under the band when there is one
var _edge: Panel                # the tone, down the left edge
var _track: Button              # the bar: its track - a button, when it's a job's - its fill, its text twice
var _fill: Panel
var _clip_on: Control
var _clip_off: Control
var _bar_on: Label
var _bar_off: Label
var _title: Label
var _headline: Label
var _unit: Label
var _labels: Array[Label] = []
var _values: Array[Label] = []
var _chips: Array[Panel] = []
var _chip_labels: Array[Label] = []
var _note: Label
var _status: Label
var _sketch: Control
var _corner: Control
var _buttons: Array[Button] = []
var _looks: Array[String] = ["", "", "", ""]     # each button's style now: "primary", "plain" or a tone
var _actions: Array = [Callable(), Callable(), Callable(), Callable()]
var _bar_action := Callable()
var _bar_repeat := 0.0             # seconds between presses while held; 0, none
var _next_repeat_ms := 0
var _bar_ready := false
var _bar_look := ""             # the track's style now: "", "ready" or "off"
var _fill_w := 0.0              # the fill as drawn, easing toward the sim's
var _fill_tween: Tween
var _shown_ms := 0              # when show_data last ran: the ease takes that long


func _init() -> void:
	size = Vector2(Pal.CARD_W, Pal.CARD_H)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_PASS
	_bg = UI.panel(self, Rect2(Vector2.ZERO, size), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	var edge := StyleBoxFlat.new()
	edge.bg_color = Pal.GOOD
	edge.corner_radius_top_left = 8
	edge.corner_radius_bottom_left = 8
	_edge = UI.panel(self, Rect2(0, 0, 6, Pal.CARD_H), edge)
	_band = Band.new(Pal.CARD_W, BAND_H)
	_band.visible = false
	add_child(_band)
	move_child(_band, _edge.get_index())          # under the tone's edge, so a pinned site's green runs the card's whole height
	var x := Pal.PAD
	var w := Pal.INNER
	_track = Button.new()
	_track.position = Vector2(x, BAR_Y)
	_track.size = Vector2(w, BAR_H)
	_track.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS      # a job starts on the press
	_track.pressed.connect(_on_bar_pressed)
	add_child(_track)
	_style_track("")
	_fill = UI.panel(_track, Rect2(0, 0, 0, BAR_H), UI.box(Pal.ACCENT, 6))
	_clip_on = Control.new()
	_clip_on.clip_contents = true
	_clip_on.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip_on.size = Vector2(0, BAR_H)
	_track.add_child(_clip_on)
	_bar_on = UI.label(_clip_on, Rect2(0, 0, w, BAR_H), "", "SemiBold", Pal.FLOOR, Pal.ACCENT_TEXT,
			HORIZONTAL_ALIGNMENT_CENTER)
	_clip_off = Control.new()
	_clip_off.clip_contents = true
	_clip_off.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip_off.size = Vector2(w, BAR_H)
	_track.add_child(_clip_off)
	_bar_off = UI.label(_clip_off, Rect2(0, 0, w, BAR_H), "", "SemiBold", Pal.FLOOR, Pal.TEXT,
			HORIZONTAL_ALIGNMENT_CENTER)
	_track.visible = false
	_title = UI.label(self, Rect2(x, 14, w, 40), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_headline = UI.label(self, Rect2(x, HEAD_Y, w, HEAD_H), "", "SemiBold", Pal.HEADLINE, Pal.TEXT)
	# the unit sits on the figure's baseline
	var hf := UI.font("SemiBold")
	var uf := UI.font("Medium", false)
	var base := HEAD_Y + (HEAD_H - hf.get_height(Pal.HEADLINE)) / 2.0 + hf.get_ascent(Pal.HEADLINE)
	var uy := roundf(base - uf.get_ascent(Pal.LINE) - (UNIT_H - uf.get_height(Pal.LINE)) / 2.0)
	_unit = UI.label(self, Rect2(x, uy, w, UNIT_H), "", "Medium", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(Pal.LINES):
		var y := LINES_Y + i * Pal.LINE_H
		_labels.append(UI.label(self, Rect2(x, y, w, Pal.LINE_H), "", "Regular", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		_values.append(UI.label(self, Rect2(x, y, w, Pal.LINE_H), "", "Medium", Pal.LINE, Pal.TEXT,
				HORIZONTAL_ALIGNMENT_RIGHT))
	for i in range(CHIPS):
		var cp := UI.panel(self, Rect2(x, LINES_Y + 3, 10, CHIP_H), UI.box(Pal.BUTTON, 6))
		cp.visible = false
		_chips.append(cp)
		_chip_labels.append(UI.label(cp, Rect2(CHIP_PAD, 0, 10, CHIP_H), "", "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_note = UI.label(self, Rect2(x, 308, w, 34), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sketch = Sketch.new()
	_sketch.position = Vector2(x, LINES_Y + (Pal.LINES - SKETCH_LINES) * Pal.LINE_H)
	_sketch.size = Vector2(w, SKETCH_LINES * Pal.LINE_H)
	_sketch.visible = false
	add_child(_sketch)
	_corner = Sketch.new()
	_corner.position = Vector2(x + w - CORNER_W, 16)
	_corner.size = Vector2(CORNER_W, CORNER_H)
	_corner.visible = false
	add_child(_corner)
	var by := Pal.CARD_H - Pal.PAD - Pal.BUTTON_H
	_status = UI.label(self, Rect2(x, by, w, Pal.BUTTON_H), "", "Medium", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(4):
		var b := UI.button(self, Rect2(x, by, w, Pal.BUTTON_H), false)
		b.pressed.connect(_on_pressed.bind(i))
		b.visible = false
		_buttons.append(b)


func show_data(d: Dictionary) -> void:
	_title.text = d.get("title", "")
	var corner: Dictionary = d.get("corner", {})
	_corner.show_sketch(corner)
	_title.size.x = Pal.INNER - ((CORNER_W + UNIT_GAP) if not corner.is_empty() else 0)
	_headline.text = d.get("headline", "")
	# the unit takes what the figure leaves of the line, so the geometry test's
	# fit check on it is the pair's
	_unit.text = d.get("unit", "")
	var used := ceilf(UI.text_width(_headline, _headline.text)) + UNIT_GAP
	_unit.position.x = Pal.PAD + used
	_unit.size.x = Pal.INNER - used
	# a band: {"site": name, "tone": zone, "kicker": words, "colour": the headline's}; the title, headline and unit move into it
	var band: Dictionary = d.get("band", {})
	_band.visible = not band.is_empty()
	_lines_y = LINES_Y_BAND if _band.visible else LINES_Y
	for l in [_title, _headline, _unit]:
		l.visible = not _band.visible
	if _band.visible:
		_band.set_site(str(band.get("site", _title.text)))
		_band.set_tone(int(band.get("tone", 0)))
		_band.set_words(str(band.get("kicker", "")), _title.text, _headline.text, d.get("unit_forms", [_unit.text]), band.get("colour", Pal.ACCENT))
		_band.headline_under_title(true)
		_band.set_right([])
	var first := _show_bar(d.get("bar", null))
	var sketch: Dictionary = d.get("sketch", {})
	var sketch_lines: int = int(sketch.get("lines", SKETCH_LINES))
	_sketch.position.y = LINES_Y + (Pal.LINES - sketch_lines) * Pal.LINE_H
	_sketch.size.y = sketch_lines * Pal.LINE_H
	_sketch.show_sketch(sketch)
	first += _show_chips(d.get("chips", []), first)
	var room: int = Pal.LINES - first - (sketch_lines if not sketch.is_empty() else 0)
	var lines: Array = d.get("lines", [])
	assert(lines.size() <= room, "a card holds six lines, five with a bar or chips, two fewer with a sketch: " + _title.text)
	for i in range(Pal.LINES):
		var on := i < lines.size()
		_labels[i].text = lines[i][0] if on else ""
		# the value as a string, or its forms long to short: the first that shares the line with its label
		if on and lines[i][1] is Array:
			var label_w: float = UI.text_width(_labels[i], _labels[i].text) + 16.0
			_values[i].text = str(lines[i][1].back())
			for form in lines[i][1]:
				if label_w + UI.text_width(_values[i], str(form)) <= Pal.INNER:
					_values[i].text = str(form)
					break
		else:
			_values[i].text = str(lines[i][1]) if on else ""
		_values[i].add_theme_color_override("font_color", Pal.tone_color(lines[i][2]) if on and lines[i].size() > 2 and lines[i][2] != "" else Pal.TEXT)
		# a fourth entry tones the label (the radio's words in their tone)
		_labels[i].add_theme_color_override("font_color", Pal.tone_color(lines[i][3]) if on and lines[i].size() > 3 and lines[i][3] != "" else Pal.TEXT_2)
		_labels[i].position.y = _lines_y + (i + first) * Pal.LINE_H
		_values[i].position.y = _labels[i].position.y
	_note.text = d.get("note", "")
	_note.add_theme_color_override("font_color", Pal.tone_color(d.get("note_tone", "")))
	var tone: String = d.get("tone", "")
	_edge.visible = tone != ""
	if tone != "":
		(_edge.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.tone_color(tone)
	var buttons: Array = d.get("buttons", [])
	assert(buttons.size() <= 4, "a card holds four buttons: " + _title.text)
	assert(buttons.size() <= 2 or lines.size() <= Pal.LINES - 2, "four buttons take two lines' place: " + _title.text)
	var x := Pal.PAD
	var by := Pal.CARD_H - Pal.PAD - Pal.BUTTON_H
	var rows := 2 if buttons.size() > 2 else 1
	for i in range(4):
		var b := _buttons[i]
		if i >= buttons.size():
			b.visible = false
			_actions[i] = Callable()
			continue
		var row := i / 2
		var pair := buttons.slice(row * 2, row * 2 + 2)
		var widths := _button_widths(pair)
		var bd: Dictionary = buttons[i]
		b.visible = true
		b.position = Vector2(x + (0.0 if i % 2 == 0 else widths[0] + BUTTON_GAP), by - (rows - 1 - row) * (Pal.BUTTON_H + BUTTON_GAP))
		b.size = Vector2(widths[i % 2], Pal.BUTTON_H)
		b.text = bd.get("text", "")
		b.disabled = not bd.get("enabled", true)
		var primary: bool = bd.get("primary", i == 0)
		var look: String = bd.get("tone", "primary" if primary else "plain")
		if look != _looks[i]:
			UI.style_button(b, primary, look if look != "primary" and look != "plain" else "")
			_looks[i] = look
		_actions[i] = bd.get("action", Callable())
	_status.visible = buttons.is_empty()
	_status.text = d.get("status", "")


## The chips, or none: returns the line places they take (one, when there are any).
## Chips that don't fit the row are left off from the right.
func _show_chips(chips: Array, after: int) -> int:
	var x := 0.0
	var y := _lines_y + after * Pal.LINE_H + 3
	var shown := false
	for k in range(CHIPS):
		var on := k < chips.size()
		_chips[k].visible = on
		if not on:
			continue
		var words: String = chips[k][0]
		var tone: String = chips[k][1] if chips[k].size() > 1 else ""
		var l := _chip_labels[k]
		l.text = words
		var w: float = ceilf(UI.text_width(l, words)) + 2 * CHIP_PAD
		if x + w > Pal.INNER:
			for j in range(k, CHIPS):
				_chips[j].visible = false
			break
		_chips[k].position = Vector2(Pal.PAD + x, y)
		_chips[k].size = Vector2(w, CHIP_H)
		l.size.x = w - 2 * CHIP_PAD
		var colour: Color = Pal.tone_color(tone) if tone != "" else Pal.TEXT_2
		l.add_theme_color_override("font_color", colour)
		_chips[k].add_theme_stylebox_override("panel", UI.box(colour.darkened(0.72) if tone != "" else Pal.BUTTON, 6))
		x += w + CHIP_GAP
		shown = true
	return 1 if shown else 0


## The bar, or none: returns how many line places it takes.
func _show_bar(bar) -> int:
	var now := Time.get_ticks_msec()
	var since := clampf((now - _shown_ms) / 1000.0, 0.05, 1.0)
	_shown_ms = now
	_track.visible = bar != null
	if bar == null:
		_bar_setup(Callable(), false, false, false)
		return 0
	var action: Callable = bar.get("action", Callable())
	var ready: bool = action.is_valid() and bar.get("ready", false)
	_bar_setup(action, bar.get("enabled", true), ready, float(bar.get("repeat", 0.0)))
	var tone: String = bar.get("tone", "")
	(_fill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.ACCENT if tone == "" else Pal.tone_color(tone)
	var target := Pal.INNER * clampf(float(bar.get("fill", 0.0)), 0.0, 1.0)
	if ready:
		target = Pal.INNER                    # the whole bar is the button, its text dark across it
	if _fill_tween != null:
		_fill_tween.kill()
		_fill_tween = null
	if smooth_bars and bar.get("smooth", false) and not ready and target > _fill_w and is_inside_tree():
		_fill_tween = create_tween()
		_fill_tween.tween_method(_set_fill, _fill_w, target, since)
	else:
		_set_fill(target)
	_bar_on.text = bar.get("text", "")
	_bar_off.text = _bar_on.text
	return 1


func _set_fill(fw: float) -> void:
	_fill_w = fw
	var r := roundf(fw)
	_fill.size.x = r
	_fill.visible = r >= 1.0 and not _bar_ready
	_clip_on.size.x = r
	_clip_off.position.x = r
	_clip_off.size.x = Pal.INNER - r
	_bar_off.position.x = -r


## Whether the bar is a button, and how it looks: the main button when its job
## waits for a click, the plain track otherwise.
func _bar_setup(action: Callable, enabled: bool, ready: bool, repeat: float) -> void:
	var live := action.is_valid()
	_bar_action = action
	_bar_repeat = repeat if live else 0.0
	_bar_ready = ready
	_track.disabled = not (live and enabled)
	_track.mouse_filter = Control.MOUSE_FILTER_STOP if live else Control.MOUSE_FILTER_IGNORE
	_track.focus_mode = Control.FOCUS_ALL if live else Control.FOCUS_NONE
	var look := ("ready" if enabled else "off") if ready else ""
	if look != _bar_look:
		_style_track(look)
	_bar_on.add_theme_color_override("font_color", Pal.TEXT_3 if look == "off" else Pal.ACCENT_TEXT)


func _style_track(look: String) -> void:
	_bar_look = look
	if look != "":
		UI.style_button(_track, true)
		return
	for key in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		_track.add_theme_stylebox_override(key, UI.box(Pal.SELECT if key == "hover" else Pal.BG, 6))
	_track.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 6, 2, Pal.TEXT))


func _on_bar_pressed() -> void:
	if _bar_action.is_valid():
		_next_repeat_ms = Time.get_ticks_msec() + int(_bar_repeat * 1000.0)
		_bar_action.call()
		acted.emit()


## A job's bar held down presses itself again every `repeat` seconds.
func _process(_delta: float) -> void:
	if _bar_repeat <= 0.0 or not visible or not _track.visible or _track.disabled or not _track.is_pressed():
		return
	var now := Time.get_ticks_msec()
	if now >= _next_repeat_ms:
		_next_repeat_ms = now + int(_bar_repeat * 1000.0)
		if _bar_action.call() == true:
			acted.emit()


## One button spans the card. Two split it in half - unless one's text needs more
## than half, when each gets what it needs and they share what's left.
func _button_widths(buttons: Array) -> Array:
	if buttons.size() < 2:
		return [float(Pal.INNER), 0.0]
	var room := float(Pal.INNER - BUTTON_GAP)
	var need := []
	for bd in buttons:
		need.append(ceilf(UI.text_width(_buttons[0], bd.get("text", ""))) + BUTTON_ROOM)
	if need[0] <= room / 2.0 and need[1] <= room / 2.0:
		return [floorf(room / 2.0), floorf(room / 2.0)]
	var spare := maxf(0.0, room - need[0] - need[1])
	var w0 := floorf(need[0] + spare / 2.0)
	return [w0, room - w0]


func _on_pressed(i: int) -> void:
	if _actions[i].is_valid():
		_actions[i].call()
		acted.emit()


## Every label and button with text, for the geometry test.
func text_nodes() -> Array:
	var out: Array = [_title, _headline, _unit, _note, _status]
	if _band.visible:
		out.append_array(_band.text_nodes())
	if _track.visible:
		out.append(_bar_off)            # the whole bar wide: the text has to fit it
	out.append_array(_labels)
	out.append_array(_values)
	for k in range(CHIPS):
		if _chips[k].visible:
			out.append(_chip_labels[k])
	for b in _buttons:
		if b.visible:
			out.append(b)
	if _sketch.visible:
		out.append_array(_sketch.text_nodes())
	return out


## Label/value pairs that share a line: together they must fit, with a gap.
func line_pairs() -> Array:
	var out: Array = []
	for i in range(Pal.LINES):
		if _labels[i].text != "":
			out.append([_labels[i], _values[i]])
	if _band.visible:
		out.append([_band.headline, _band.unit])
	return out
