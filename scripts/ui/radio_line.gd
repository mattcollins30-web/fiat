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

signal pressed

var sim
var _clip: Control                 # the words scroll inside it
var _items: Array = []             # {"label": Label, "dot": Label or null}: on the strip, left to right
var _queue: Array = []             # lines heard just now, first out first
var _next_heard := 0               # the ambient turn through what's been heard
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
		it["label"].queue_free()
		if it["dot"] != null:
			it["dot"].queue_free()
	_items.clear()
	_queue.clear()
	_next_heard = 0
	_started = false


## A line just heard: next on the strip, before the ambient ones.
func push(text: String) -> void:
	if text != "" and not (text in _queue):
		_queue.append(text)


## The words showing, left to right (the tests).
func texts() -> Array:
	return _items.map(func(it): return it["label"].text)


## What plays next: a line just heard, else the next of those heard in turn, else the loop's first.
func _next_line() -> String:
	if not _queue.is_empty():
		return _queue.pop_front()
	var pool: Array = []
	if sim != null:
		for key in sim.heard:
			var r: Dictionary = Sim.radio_line(str(key))
			if not r.is_empty():
				pool.append(str(r["text"]))
	if pool.is_empty():
		return str(Words.RADIO[0]["text"])
	_next_heard = _next_heard % pool.size()
	var s: String = pool[_next_heard]
	_next_heard += 1
	if pool.size() > 1 and not _items.is_empty() and s == _items.back()["label"].text:
		s = pool[_next_heard % pool.size()]          # not the line just played again (a heard line pushed, then its turn)
		_next_heard += 1
	return s


func _tail_x() -> float:
	if _items.is_empty():
		return -INF
	var last: Label = _items.back()["label"]
	return last.position.x + last.size.x


func _add(text: String, x: float) -> void:
	var dot: Label = null
	if not _items.is_empty():
		dot = UI.label(_clip, Rect2(x + GAP / 2.0 - 8, 0, 16, H - 1), "·", "SemiBold", SIZE, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, false)
		x += GAP
	var l := UI.label(_clip, Rect2(x, 0, 10, H - 1), text, "Medium", SIZE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	l.size.x = ceilf(UI.text_width(l, text)) + 2
	_items.append({"label": l, "dot": dot})


## Moves the words `dx` left; drops what's gone off the left; fills from the right.
func step(dx: float) -> void:
	for it in _items:
		it["label"].position.x -= dx
		if it["dot"] != null:
			it["dot"].position.x -= dx
	while not _items.is_empty() and _items[0]["label"].position.x + _items[0]["label"].size.x < 0.0:
		var gone: Dictionary = _items.pop_front()
		gone["label"].queue_free()
		if gone["dot"] != null:
			gone["dot"].queue_free()
		if not _items.is_empty() and _items[0]["dot"] != null:
			_items[0]["dot"].queue_free()
			_items[0]["dot"] = null
	var guard := 0
	while (_items.is_empty() or _tail_x() + GAP < _clip.size.x) and guard < 8:
		_add(_next_line(), (FADE if not _started else _clip.size.x) if _items.is_empty() else _tail_x())     # on at once the first time
		_started = true
		guard += 1


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
