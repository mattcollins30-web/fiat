extends Control
## Juice: the small things that make a number feel like a hit. Damage
## numbers float off the run panel, a rare's cell flashes when it lands in
## the pack, and the log's best lines come up as toasts under the top bar.
## Nothing here changes the sim; everything here is safe to miss.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")

const TOAST_W := 720
const TOAST_H := 48
const TOAST_S := 3.2               # seconds a toast stays
const TOAST_MAX := 3               # stacked under the top bar
const NUMBER_S := 0.8              # a damage number's rise and fade
const NUMBER_RISE := 44.0

var _toasts: Array = []            # {panel, label, left}
var _numbers: Array = []           # {label, left}
var _toast_y := 0.0                # where the first toast sits (set by the shell)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func set_top(y: float) -> void:
	_toast_y = y


## A line worth a moment of its own, under the top bar; the newest on top.
func toast(text: String, tone := "") -> void:
	var p := UI.panel(self, Rect2(0, 0, TOAST_W, TOAST_H), UI.box(Pal.CARD, 8, 1, Pal.tone_color(tone) if tone != "" else Pal.CARD_LINE))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(p, Rect2(16, 0, TOAST_W - 32, TOAST_H), "", "SemiBold", Pal.FLOOR, Pal.tone_color(tone) if tone != "" else Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
	UI.fit(l, [text, text.get_slice(". ", 0) + ".", text.get_slice(":", 0)])
	_toasts.push_front({"panel": p, "label": l, "left": TOAST_S, "line": text})
	while _toasts.size() > TOAST_MAX:
		var old: Dictionary = _toasts.pop_back()
		old["panel"].queue_free()
	_lay_toasts()


func _lay_toasts() -> void:
	var x: float = (size.x - TOAST_W) / 2.0
	for k in range(_toasts.size()):
		var t: Dictionary = _toasts[k]
		t["panel"].position = Vector2(x, _toast_y + k * (TOAST_H + 8))


## A number off a hit: rises and fades from `at` (in this control's space).
func number(at: Vector2, text: String, tone := "", big := false) -> void:
	var l := UI.label(self, Rect2(at.x - 60, at.y, 120, 36), text, "SemiBold", Pal.TITLE if big else Pal.LINE, Pal.tone_color(tone) if tone != "" else Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_numbers.append({"label": l, "left": NUMBER_S, "from": at.y, "drift": randf_range(-18.0, 18.0), "x": at.x - 60})
	if _numbers.size() > 12:
		var old: Dictionary = _numbers.pop_front()
		old["label"].queue_free()


## A control lit for a moment: a rare in the pack, a level, a head down.
func flash(c: Control, tone := "") -> void:
	if c == null or not is_instance_valid(c):
		return
	var colour: Color = Pal.tone_color(tone) if tone != "" else Pal.ACCENT
	c.modulate = colour.lerp(Color.WHITE, 0.5)
	var tw := c.create_tween()
	tw.tween_property(c, "modulate", Color.WHITE, 0.6)


func _process(delta: float) -> void:
	var gone := []
	for t in _toasts:
		t["left"] -= delta
		if t["left"] <= 0.0:
			gone.append(t)
		elif t["left"] < 0.6:
			t["panel"].modulate.a = t["left"] / 0.6
	for t in gone:
		_toasts.erase(t)
		t["panel"].queue_free()
	if not gone.is_empty():
		_lay_toasts()
	var done := []
	for n in _numbers:
		n["left"] -= delta
		var k: float = 1.0 - maxf(0.0, n["left"]) / NUMBER_S
		n["label"].position.y = n["from"] - NUMBER_RISE * k
		n["label"].position.x = n["x"] + n["drift"] * k          # a little sideways too, so two never share a path
		n["label"].modulate.a = 1.0 - k * k
		if n["left"] <= 0.0:
			done.append(n)
	for n in done:
		_numbers.erase(n)
		n["label"].queue_free()


## For the tests: what's showing.
func toasts() -> Array:
	var out := []
	for t in _toasts:
		out.append(t["label"].text)
	return out


## The whole lines showing, fitted or not: what a repeat is checked against.
func lines() -> Array:
	var out := []
	for t in _toasts:
		out.append(t["line"])
	return out


func numbers() -> int:
	return _numbers.size()


func clear_numbers() -> void:
	for n in _numbers:
		n["label"].queue_free()
	_numbers = []


func text_nodes() -> Array:
	var out := []
	for t in _toasts:
		out.append(t["label"])
	return out
