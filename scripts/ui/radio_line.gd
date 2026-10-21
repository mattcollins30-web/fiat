extends Control
## The radio line (13 Oct, Matt; docs/design/campaign_gates.md; mockup C): a second row of the top bar, always on,
## one line scrolling right to left that never stops - a live radio. No speaker in front: the radio has its own voice.
## A line just heard jumps the queue; with nothing new it plays what's been heard, in turn (the loop's first line
## before anything). Pressed, it opens the Radio. Nothing here changes the sim.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Words := preload("res://scripts/sim/words.gd")
const Sim := preload("res://scripts/sim/sim.gd")

const H := 36                      # its height under the top bar (Pal.RADIO_H)
const SIZE := 20                   # the words' size: the Deck draws at two-thirds
const SPEED := 70.0                # px a second
const GAP := 56.0                  # between two lines, a dot in the middle
const FADE := 64.0                 # the soft ends
const DOT_X := 0.0                 # the live dot, at the row's left
const TEXT_X := 26.0               # where the words start to show
## A colour a voice (16 Oct, item 6; the UI pass canvas, approved): off the rarity colours where they can be.
const VOICE := {"loop": Color("aab4bf"), "kev": Color("f0a868"), "net": Color("c2b67e"), "medic": Color("8ccbe6"), "fence": Color("d6a0e0")}
const GARBLE := Color("6f7780")    # traffic you can't read
const GARBLE_GLYPHS := "ΞЖ§¤ØÞðƷΔΣΠΩψλξζЯЮЩЦФБДЛ¶†‡※∆∑∏≈≠±÷×◊#%&@"     # all in Inter (checked against its cmap)
const GARBLE_EVERY := 5            # before the Radio: a line in five is traffic, all of it garbled
const GARBLE_EVERY_OPEN := 12      # after: rarer, and a word or two comes through

signal pressed

var sim
var _clip: Control                 # the words scroll inside it
var _items: Array = []             # {"label": Label (the first part), "parts": [Label], "dot": Label or null}: on the strip, left to right
var _queue: Array = []             # lines heard just now, first out first
var _next_heard := 0               # the ambient turn through what's been heard
var _last := ""                     # the line last played, queue or turn
var _since_garble := 0             # lines played since the last garbled one
var _garbles := 0                  # garbled lines played: picks the next one's words and glyphs
static var _voice_of := {}         # a line's text -> its voice, from Words.RADIO
var _live: Panel
var _rule: Panel
var _t := 0.0
var _started := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	size = Vector2(1920, H)
	_rule = UI.panel(self, Rect2(0, 0, 1920, 1), UI.box(Pal.CARD_LINE, 0))
	_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_live = UI.panel(self, Rect2(DOT_X, (H - 8) / 2.0, 8, 8), UI.box(Pal.BAD, 4))
	_live.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip = Control.new()
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.position = Vector2(TEXT_X, 1)
	_clip.size = Vector2(100, H - 1)
	add_child(_clip)
	for side in [0, 1]:
		var g := Gradient.new()
		g.set_color(0, Color(Pal.PANEL, 1.0) if side == 0 else Color(Pal.PANEL, 0.0))
		g.set_color(1, Color(Pal.PANEL, 0.0) if side == 0 else Color(Pal.PANEL, 1.0))
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.width = int(FADE)
		tex.height = 4
		var r := TextureRect.new()
		r.texture = tex
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.name = "fade_left" if side == 0 else "fade_right"
		add_child(r)
	set_process(true)


## The row across `w` from `x0` (the top row's left): the dot at the left, the words to the right edge.
func lay(x0: float, w: float) -> void:
	_rule.size.x = size.x
	_live.position.x = x0 + DOT_X
	_clip.position.x = x0 + TEXT_X
	_clip.size.x = w - TEXT_X
	var fl: TextureRect = get_node("fade_left")
	var fr: TextureRect = get_node("fade_right")
	fl.position = Vector2(_clip.position.x, 1)
	fl.size = Vector2(FADE, H - 1)
	fr.position = Vector2(_clip.position.x + _clip.size.x - FADE, 1)
	fr.size = Vector2(FADE, H - 1)


## The camp it plays (the shell, every refresh): a new one starts the strip clean (the review: a quit camp's lines
## played on into the next).
func set_sim(s) -> void:
	if s == sim:
		return
	sim = s
	for it in _items:
		for l in it["parts"]:
			l.queue_free()
		if it["dot"] != null:
			it["dot"].queue_free()
	_items.clear()
	_queue.clear()
	_next_heard = 0
	_since_garble = 0
	_garbles = 0
	_started = false


## A line just heard: next on the strip, before the ambient ones.
func push(text: String) -> void:
	if text != "" and not (text in _queue):
		_queue.append(text)


## The words showing, left to right (the tests).
func texts() -> Array:
	return _items.map(func(it): return "".join(it["parts"].map(func(l): return l.text)))


## A line's voice: the RADIO entry it's the text of; the loop's for anything else.
static func voice_of(text: String) -> String:
	if _voice_of.is_empty():
		for r in Words.RADIO:
			_voice_of[str(r["text"])] = str(r["voice"])
	return str(_voice_of.get(text, "loop"))


## A run of text as traffic: every letter a glyph, the spaces kept. `turn` turns the glyphs.
static func garble(text: String, turn: int) -> String:
	var out := ""
	for i in range(text.length()):
		var ch := text[i]
		out += " " if ch == " " else GARBLE_GLYPHS[(i * 7 + turn * 13) % GARBLE_GLYPHS.length()]
	return out


## What goes on the strip next, as parts [[text, colour]]: a line just heard first, as it is; else, a line in
## GARBLE_EVERY (GARBLE_EVERY_OPEN once the Radio's open) is traffic - all glyphs before the Radio, a word or two of
## it through in its voice's colour after; else the next line in its voice's colour. Nothing here is the sim's.
func next_parts() -> Array:
	var open: bool = sim != null and sim.room_open("radio")
	if _queue.is_empty() and _started and _since_garble >= (GARBLE_EVERY_OPEN if open else GARBLE_EVERY) - 1:
		_since_garble = 0
		_garbles += 1
		var src: Dictionary = Words.RADIO_TRAFFIC[_garbles % Words.RADIO_TRAFFIC.size()]
		if _loop_stopped():
			while str(src["voice"]) == "loop":       # the loop's stopped: none of it in the traffic either (19 Oct, Matt)
				_garbles += 1
				src = Words.RADIO_TRAFFIC[_garbles % Words.RADIO_TRAFFIC.size()]
		var text: String = str(src["text"])
		if not open:
			return [[garble(text, _garbles), GARBLE]]
		# a word or two through: the longer words, picked by the turn, in order
		var words: PackedStringArray = text.split(" ")
		var long: Array = []
		for k in range(words.size()):
			if words[k].length() >= 5:
				long.append(k)
		var keep := {}
		if not long.is_empty():
			keep[long[_garbles % long.size()]] = true
			if long.size() >= 3:
				keep[long[(_garbles + floori(long.size() / 2.0)) % long.size()]] = true
		var parts: Array = []
		var run := ""
		for k in range(words.size()):
			var sep := " " if k > 0 else ""
			if keep.has(k):
				if run != "" or sep != "":
					parts.append([garble(run + sep, _garbles + k), GARBLE])
				parts.append([words[k], VOICE.get(str(src["voice"]), Pal.TEXT_2)])
				run = ""
			else:
				run += sep + words[k]
		if run != "":
			parts.append([garble(run, _garbles + 7), GARBLE])
		return parts
	var from_queue: bool = not _queue.is_empty()
	var line := _next_line()
	if not from_queue:
		_since_garble += 1
	return [[line, VOICE.get(voice_of(line), Pal.TEXT_2)]]


## What plays next: a line just heard, else the next of those heard in turn, else the loop's first.
func _next_line() -> String:
	_last = _pick_line()
	return _last


## The line, by the turn; never the one just played twice running (21 Oct, Matt's playtest: the medic's line, the only
## one heard on a fresh camp, ran back to back) - with one line heard, the loop's latest fills the gap.
func _pick_line() -> String:
	if not _queue.is_empty():
		return _queue.pop_front()
	var pool: Array = []
	if sim != null:
		var top: int = _loop_latest()
		for key in sim.heard:
			var r: Dictionary = Sim.radio_line(str(key))
			if r.is_empty() or sim.gate_line_done(r):      # a room's "bring me the bag" stops once it's open
				continue
			if str(r["voice"]) == "loop" and int(str(key).get_slice("/", 1)) < top:
				continue                              # the loop plays its latest only: once it's stopped, it's stopped (19 Oct, Matt)
			pool.append(str(r["text"]))
	if pool.is_empty():
		return str(Words.RADIO[0]["text"])
	_next_heard = _next_heard % pool.size()
	var s: String = pool[_next_heard]
	_next_heard += 1
	if s == _last:                                   # not the line just played again (a heard line pushed, then its turn)
		if pool.size() > 1:
			s = pool[_next_heard % pool.size()]
			_next_heard += 1
		elif not _loop_stopped():
			var top: int = _loop_latest()
			s = str(Words.RADIO[top if top >= 0 else 0]["text"])
	return s


## The latest of the loop's lines heard, by its place in RADIO; -1 for none.
func _loop_latest() -> int:
	var top := -1
	if sim == null:
		return top
	for key in sim.heard:
		var r: Dictionary = Sim.radio_line(str(key))
		if not r.is_empty() and str(r["voice"]) == "loop":
			top = maxi(top, int(str(key).get_slice("/", 1)))
	return top


## Whether the loop's latest heard is it stopping: no loop in the traffic then.
func _loop_stopped() -> bool:
	var top: int = _loop_latest()
	return top >= 0 and Words.RADIO[top].get("stopped", false)


func _tail_x() -> float:
	if _items.is_empty():
		return -INF
	var last: Label = _items.back()["parts"].back()
	return last.position.x + last.size.x


func _add(parts: Array, x: float) -> void:
	var dot: Label = null
	if not _items.is_empty():
		dot = UI.label(_clip, Rect2(x + GAP / 2.0 - 8, 0, 16, H - 1), "·", "SemiBold", SIZE, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, false)
		x += GAP
	var labels: Array = []
	for p in parts:
		var l := UI.label(_clip, Rect2(x, 0, 10, H - 1), str(p[0]), "Medium", SIZE, p[1], HORIZONTAL_ALIGNMENT_LEFT, false)
		l.size.x = ceilf(UI.text_width(l, str(p[0])))
		x += l.size.x
		labels.append(l)
	labels.back().size.x += 2
	_items.append({"label": labels[0], "parts": labels, "dot": dot})


## Moves the words `dx` left; drops what's gone off the left; fills from the right.
func step(dx: float) -> void:
	for it in _items:
		for l in it["parts"]:
			l.position.x -= dx
		if it["dot"] != null:
			it["dot"].position.x -= dx
	while not _items.is_empty() and _tail_of(_items[0]) < 0.0:
		var gone: Dictionary = _items.pop_front()
		for l in gone["parts"]:
			l.queue_free()
		if gone["dot"] != null:
			gone["dot"].queue_free()
		if not _items.is_empty() and _items[0]["dot"] != null:
			_items[0]["dot"].queue_free()
			_items[0]["dot"] = null
	var guard := 0
	while (_items.is_empty() or _tail_x() + GAP < _clip.size.x) and guard < 8:
		_add(next_parts(), (FADE if not _started else _clip.size.x) if _items.is_empty() else _tail_x())     # on at once the first time
		_started = true
		guard += 1


func _tail_of(it: Dictionary) -> float:
	var last: Label = it["parts"].back()
	return last.position.x + last.size.x


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	_live.modulate.a = 0.55 + 0.45 * absf(sin(_t * 2.0))     # on air
	step(SPEED * delta)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()
