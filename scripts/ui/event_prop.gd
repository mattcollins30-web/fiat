extends Control
## A run event in the scene (1 Nov, run events): test art only - placeholder shapes drawn in code with a small caption, as
## the canvas's boards have them, until the designer has played it and the art manifest is agreed. It stands on one of
## the site's own slots (run_view.gd's: the ones the gangs use): the one in need under what pins them (or sat hurt), the
## locked thing shut or open, the Scrap man at his barrow, the dogs on the gang's three spots - standing, lunging when
## they bite (their firing pose), going down - in the gang figures' places while they're fought. The view's pan moves it
## with the street.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Words := preload("res://scripts/sim/words.gd")

const HOLD_S := 4.0                       # the outcome stays in the scene this long after the choice
const PERSON := Color("48525c")
const WOOD := Color("6b5a44")
const STEEL := Color("52606c")
const DOG := Color("5a4a3a")
const MID_SCALE := 0.62                   # the middle slot's scale: the shapes are drawn at their size there

var view                                   # run_view.gd
var ev: Dictionary = {}
var shown := false                         # something's in the scene (for the tests)
var what := ""                             # what's drawn: "need", "need_freed", "locked", "locked_open", "trader", "dogs"
var _cap: Label
var _boxes := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cap = UI.label(self, Rect2(0, 0, 10, 18), "", "Medium", 13, Color("c9ced3"), HORIZONTAL_ALIGNMENT_CENTER, false)
	UI.shadow(_cap)
	for k in [["person", PERSON, 10], ["wood", WOOD, 3], ["steel", STEEL, 4], ["dog", DOG, 12], ["lock", Pal.ACCENT, 2], ["dark", Color("1b1e22"), 2]]:
		var sb := UI.box(k[1], k[2])
		_boxes[k[0]] = sb


## The event as the run has it, and whether it's in the scene now: asking, being fought, or just done (HOLD_S).
func set_event(e: Dictionary, elapsed: float) -> void:
	ev = e
	var st: String = str(e.get("state", ""))
	var outcome: String = str(e.get("outcome", ""))
	shown = not e.is_empty() and (st in ["ask", "fight"] or (st == "done" and outcome != "out" and outcome != "fought" and elapsed - float(e.get("done_at", 0.0)) < HOLD_S))
	visible = shown
	if not shown:
		what = ""
		_drawn_what = ""
		return
	var fam: String = str(e["fam"])
	what = fam
	var cap: String = ""
	match fam:
		"need":
			var who: String = Words.low1(str(e.get("who", "")))     # the first letter only (U13): never a name lowered
			if outcome == "free":
				what = "need_freed"
				cap = Words.EV["cap_freed"]
			elif outcome == "bag":
				cap = Words.EV["cap_bag"]
			elif outcome == "leave":
				cap = Words.EV["cap_left"]
			else:
				cap = Words.EV["cap_need"] % [who, str(e.get("what", ""))] if bool(e.get("pin", true)) else Words.EV["cap_hurt"] % who
		"locked":
			if outcome in ["force", "shoot"]:
				what = "locked_open"
				cap = Words.EV["cap_open"]
			else:
				cap = Words.EV["cap_locked"] % Words.low1(str(e.get("what", "")))
		"trader":
			cap = Words.EV["cap_trader"]
		"threat":
			what = "dogs"
			cap = Words.EV["cap_dogs"] % int(e.get("n", 0))
	if _cap.text != cap or what != _drawn_what:
		_drawn_what = what
		_cap.text = cap
		_cap.size.x = ceilf(UI.text_width(_cap, cap)) + 8
		_redraw()


var _drawn_pan := -1.0
var _drawn_what := ""
var redraws := 0                           # for the tests: redraws asked for - a picture standing still asks none (U16)
func _process(_dt: float) -> void:
	if not shown or view == null:
		return
	# drawn again only when something moves: the street's pan, or the dogs in the fight (U16)
	if float(view._pan) != _drawn_pan or str(ev.get("state", "")) == "fight":
		_redraw()


func _redraw() -> void:
	redraws += 1
	_drawn_pan = float(view._pan) if view != null else -1.0
	queue_redraw()


## In the scene and not just done: the crates in the street make way for it (U15: they're back as the search resumes).
func holds_street() -> bool:
	return shown and str(ev.get("state", "")) in ["ask", "fight"]


## Where slot k's feet are in the frame now (the street pans with the search) and its size against the middle slot's.
func _spot(k: int) -> Array:
	var slot: Dictionary = view.slot_of(k)
	var pan: float = float(view._pan) * -0.6
	return [slot["foot"] + Vector2(pan, 0.0), float(slot["scale"]) / MID_SCALE]


func _draw() -> void:
	if not shown or view == null:
		return
	var sp: Array = _spot(0)
	var f: Vector2 = sp[0]
	var s: float = sp[1]
	var top: float = 116.0                      # the shape's height over its feet, at the middle slot: the caption over it
	match what:
		"need":
			top = 70.0
			if bool(ev.get("pin", true)):
				draw_style_box(_boxes["person"], Rect2(f.x - 54 * s, f.y - 54 * s, 108 * s, 54 * s))     # lying
				draw_style_box(_boxes["wood"], Rect2(f.x - 85 * s, f.y - 66 * s, 170 * s, 20 * s))      # what pins them
			else:
				draw_style_box(_boxes["person"], Rect2(f.x - 34 * s, f.y - 66 * s, 68 * s, 66 * s))     # sat against the wall
			if str(ev.get("outcome", "")) != "bag":
				draw_style_box(_boxes["dark"], Rect2(f.x + 40 * s, f.y - 22 * s, 28 * s, 22 * s))      # the bag
		"need_freed":
			top = 100.0
			draw_style_box(_boxes["person"], Rect2(f.x - 20 * s, f.y - 96 * s, 40 * s, 96 * s))        # up on their feet
			draw_style_box(_boxes["wood"], Rect2(f.x + 30 * s, f.y - 14 * s, 150 * s, 14 * s))         # what pinned them, down
		"locked", "locked_open":
			draw_style_box(_boxes["steel"], Rect2(f.x - 45 * s, f.y - 110 * s, 90 * s, 110 * s))
			if what == "locked":
				draw_style_box(_boxes["dark"], Rect2(f.x - 1 * s, f.y - 104 * s, 2 * s, 98 * s))         # the seam
				draw_style_box(_boxes["lock"], Rect2(f.x - 8 * s, f.y - 62 * s, 16 * s, 14 * s))         # the padlock
			else:
				draw_style_box(_boxes["dark"], Rect2(f.x - 40 * s, f.y - 104 * s, 80 * s, 98 * s))        # open: dark inside
				draw_style_box(_boxes["steel"], Rect2(f.x + 45 * s, f.y - 112 * s, 18 * s, 112 * s))      # the door swung out
		"trader":
			draw_style_box(_boxes["person"], Rect2(f.x - 25 * s, f.y - 112 * s, 50 * s, 82 * s))
			draw_style_box(_boxes["wood"], Rect2(f.x - 65 * s, f.y - 34 * s, 130 * s, 26 * s))        # the barrow
			draw_circle(f + Vector2(-44 * s, -6 * s), 7 * s, Color("2a2f35"))
			draw_circle(f + Vector2(44 * s, -6 * s), 7 * s, Color("2a2f35"))
		"dogs":
			_draw_dogs()
			top = 60.0
	_cap.position = Vector2(clampf(f.x - _cap.size.x * 0.5, 2.0, size.x - _cap.size.x - 2.0), maxf(2.0, f.y - top * s - _cap.size.y - 2.0))


## The dogs: on the gang's three spots, as many as there are (three at most drawn); in the fight each follows the
## figure in its spot (its pop, its bite, its fall), standing in the lull before.
func _draw_dogs() -> void:
	var fighting: bool = str(ev.get("state", "")) == "fight"
	var n: int = mini(3, int(ev.get("n", 0)))
	for k in range(3):
		var pose := "stand"
		var a := 1.0
		var t := 0.0
		if fighting:
			var fg: Dictionary = view._figs[k]
			var st: String = str(fg["state"])
			if st == "":
				continue
			pose = "down" if st == "down" else ("lunge" if float(fg.get("fire_t", 0.0)) > 0.0 else "stand")
			a = float(fg["rect"].modulate.a)
			t = float(fg["t"])
		elif k >= n:
			continue
		var sp: Array = _spot(k)
		var f: Vector2 = sp[0]
		var s: float = sp[1]
		var body := Rect2(f.x - 38 * s, f.y - 38 * s, 76 * s, 38 * s)
		var head := f + Vector2(-44 * s, -40 * s)
		var col := DOG
		match pose:
			"lunge":
				body.position += Vector2(-10 * s, -12 * s)
				head += Vector2(-14 * s, -14 * s)
				col = DOG.lightened(0.25)
			"down":
				body = Rect2(f.x - 42 * s, f.y - 14 * s, 84 * s, 14 * s)
				head = f + Vector2(-48 * s, -8 * s)
				a *= 1.0 - clampf(t / 0.7, 0.0, 1.0) * 0.6
		var sb: StyleBoxFlat = _boxes["dog"].duplicate()
		sb.bg_color = Color(col, a)
		draw_style_box(sb, body)
		draw_circle(head, 13 * s, Color(col, a))


## For the tests: the caption on show.
func caption() -> Label:
	return _cap
