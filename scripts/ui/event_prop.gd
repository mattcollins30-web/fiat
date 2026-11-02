extends Control
## A run event in the scene (1 Nov, run events): placeholder shapes drawn in code with a small caption, as the canvas's
## boards have them, until the art lands. It stands on one of the site's own slots (run_view.gd's: the ones the gangs
## use): the one in need under what pins them (or sat hurt), the locked thing shut or open, a trader at his barrow, the
## dogs on the gang's three spots - standing, lunging when they bite (their firing pose), going down - in the gang
## figures' places while they're fought. The view's pan moves it with the street.
## BUILD46-E (2 Nov): the art by name - art/events/<name>_<pose>.png (tools/make_run_events_manifest.py) - each picture
## drawn at the slot's scale on its feet, as the gang's figures are, and today's shapes wherever one isn't on disk. A
## rival crew stands in the lull as the zone's gang does (its own crew_<zone> picture, else the zone's gang art, else
## shapes) and is fought as the gang's figures; the other six families' things on the first slot; the weather turning
## draws nothing but its caption.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Words := preload("res://scripts/sim/words.gd")
const Data := preload("res://scripts/sim/data.gd")

const HOLD_S := 4.0                       # the outcome stays in the scene this long after the choice
const PERSON := Color("48525c")
const WOOD := Color("6b5a44")
const STEEL := Color("52606c")
const DOG := Color("5a4a3a")
const MID_SCALE := 0.62                   # the middle slot's scale: the shapes are drawn at their size there
const ZONE_KEYS := ["the_outskirts", "the_estate", "the_town", "the_city"]     # run_view.gd's
const THINGS := ["danger", "stash", "body", "wreck", "broadcast"]                # one thing on the first slot, shut then open

## Where the event art is looked for (the tests point it at a folder of their own for the with-and-without check).
static var art_dir := "res://art/events/%s.png"
static var _art := {}

var view                                   # run_view.gd
var ev: Dictionary = {}
var shown := false                         # something's in the scene (for the tests)
var what := ""                             # what's drawn: "need", "need_freed", "locked", "locked_open", "trader", "dogs", "crew", "thing", "weather"
var art_drawn: Array = []                  # for the tests: the pictures found by name for what's in the scene now
var art_missing: Array = []                # and the names drawn as shapes instead
var _cap: Label
var _boxes := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cap = UI.label(self, Rect2(0, 0, 10, 18), "", "Medium", 13, Color("c9ced3"), HORIZONTAL_ALIGNMENT_CENTER, false)
	UI.shadow(_cap)
	for k in [["person", PERSON, 10], ["wood", WOOD, 3], ["steel", STEEL, 4], ["dog", DOG, 12], ["lock", Pal.ACCENT, 2], ["dark", Color("1b1e22"), 2]]:
		var sb := UI.box(k[1], k[2])
		_boxes[k[0]] = sb


## An event picture by name (art/events/<name>.png), imported or straight off the disk; null when it isn't there.
static func art(nm: String) -> Texture2D:
	var path: String = art_dir % nm
	if _art.has(path):
		return _art[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	elif FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			t = ImageTexture.create_from_image(img)
	_art[path] = t
	return t


## The cache emptied (the tests, after laying a picture down or taking it away).
static func art_reset() -> void:
	_art.clear()


## The event as the run has it, and whether it's in the scene now: asking, being fought, or just done (HOLD_S).
func set_event(e: Dictionary, elapsed: float) -> void:
	ev = e
	var st: String = str(e.get("state", ""))
	var outcome: String = str(e.get("outcome", ""))
	shown = not e.is_empty() and (st in ["ask", "fight"] or (st == "done" and not (outcome in ["out", "fought", "home"]) and elapsed - float(e.get("done_at", 0.0)) < HOLD_S))
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
			cap = Words.EV["cap_vagabond"] if str(e.get("who", "")) == "vagabond" else Words.EV["cap_trader"]
		"threat":
			if str(e.get("who", "dogs")) == "crew":
				what = "crew"
				cap = Words.EV["cap_crew"] % int(e.get("n", 0))
			else:
				what = "dogs"
				cap = Words.EV["cap_dogs"] % int(e.get("n", 0))
		"danger", "stash", "body", "wreck", "broadcast":
			what = "thing"
			if st == "done":
				cap = Words.EV["cap_left"] if outcome == "leave" else str(Words.EV["cap_done"][fam])
			elif fam == "body":
				cap = Words.EV["cap_body"] % Words.low1(str(e.get("who", "")))
			else:
				cap = Words.EV["cap_thing"] % Words.low1(str(e.get("what", "")))
		"weather":
			what = "weather"
			if st == "done":
				cap = Words.EV["cap_passed"] if outcome == "leave" else str(Words.EV["cap_done"]["weather"])
			else:
				cap = Words.EV["cap_thing"] % Words.low1(str(e.get("what", "")))
	var key: String = what + "/" + outcome
	_note_art()
	if _cap.text != cap or key != _drawn_what:
		_drawn_what = key
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
	if float(view._pan) != _drawn_pan or (str(ev.get("state", "")) == "fight" and what == "dogs"):
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


## The zone's key ("the_estate"), for the pictures named by zone.
func _zone() -> String:
	return ZONE_KEYS[clampi(int(ev.get("zone", 0)), 0, ZONE_KEYS.size() - 1)]


## The art names this event draws now, in the order they're drawn (the tests read it; the manifest names the same).
func art_names() -> Array:
	var st: String = str(ev.get("state", ""))
	var outcome: String = str(ev.get("outcome", ""))
	var opened: bool = st == "done" and outcome != "leave"
	match what:
		"need":
			return ["person_%s_down" % _zone()]
		"need_freed":
			return ["person_%s_up" % _zone()]
		"locked", "locked_open":
			return ["%s_%s" % [str(ev.get("art", "cabinet")), "open" if what == "locked_open" else "shut"]]
		"trader":
			return ["%s_barrow" % str(ev.get("who", "scrap_man"))]
		"thing":
			return ["%s_%s" % [str(ev.get("art", "hazard")), "open" if opened else "shut"]]
		"crew":
			return [] if st == "fight" else ["crew_%s_stand" % _zone()]     # in the fight the gang's figures draw them
	return []


## The things' pictures (sim.gd's ev["art"] for a dangerous place, a stash, a body, a wreck, a broadcast).
const THING_ARTS := ["hazard", "stash_bag", "body", "wreck", "radio"]
const DOG_POSES := ["stand", "fire", "down"]     # _draw_dogs': standing, the lunge, going down


## Every name this file can draw (fix 46, E3: the manifest makes these and nothing else; the smoke holds them to it): the
## one in need a zone down and up, a rival crew a zone standing (in the fight the gang's figures stand in), the dogs'
## three poses, the traders at their barrows, the locked things' and the things' pictures shut and open.
static func all_names() -> Array:
	var out: Array = []
	for zk in ZONE_KEYS:
		out.append_array(["person_%s_down" % zk, "person_%s_up" % zk, "crew_%s_stand" % zk])
	for b in ["dog_lean", "dog_big"]:
		for ps in DOG_POSES:
			out.append("%s_%s" % [b, ps])
	for trk in Data.TRADERS:
		out.append("%s_barrow" % trk)
	var arts: Array = []
	for e in Data.EVENT_POOLS["locked_what"]:
		if not (str(e.get("art", "cabinet")) in arts):
			arts.append(str(e.get("art", "cabinet")))
	for a in THING_ARTS:
		if not (a in arts):
			arts.append(a)
	for a in arts:
		out.append_array([a + "_shut", a + "_open"])
	return out


## The names the scene wants now (art_names, and the dogs' and a crew's standing pose), split into those found on disk
## and those drawn as shapes (the tests' with-and-without check reads them; the draw finds the same).
func _note_art() -> void:
	art_drawn = []
	art_missing = []
	var names: Array = art_names()
	if what == "dogs":
		names = ["%s_stand" % ("dog_lean" if int(ev.get("zone", 0)) <= 1 else "dog_big")]
	for nm in names:
		if art(str(nm)) != null:
			art_drawn.append(nm)
		else:
			art_missing.append(nm)


## Where a picture stands on slot k: its used rect's foot on the slot's feet, at the slot's scale (as the gang's figures).
func art_rect(t: Texture2D, k: int) -> Rect2:
	var sc: float = float(view.slot_of(k)["scale"])
	var used: Rect2 = view.used_of(t)
	var pos: Vector2 = _spot(k)[0] - Vector2(used.get_center().x, used.end.y) * sc
	return Rect2(pos, t.get_size() * sc)


## A picture on slot k (art_rect); the top of what's drawn of it in the frame, for the caption.
func _draw_art(t: Texture2D, k: int, a := 1.0) -> float:
	var r: Rect2 = art_rect(t, k)
	draw_texture_rect(t, r, false, Color(1, 1, 1, a))
	return r.position.y + view.used_of(t).position.y * float(view.slot_of(k)["scale"])


func _draw() -> void:
	if not shown or view == null:
		return
	var sp: Array = _spot(0)
	var f: Vector2 = sp[0]
	var s: float = sp[1]
	var top: float = 116.0                      # the shape's height over its feet, at the middle slot: the caption over it
	var art_top := -1.0
	if what != "crew":
		for nm in art_names():
			var t: Texture2D = art(nm)
			if t != null:
				art_top = _draw_art(t, 0)
	if art_top < 0.0:
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
				if str(ev.get("who", "")) == "vagabond":
					draw_style_box(_boxes["dark"], Rect2(f.x + 8 * s, f.y - 104 * s, 30 * s, 44 * s))      # his pack on his back
				draw_circle(f + Vector2(-44 * s, -6 * s), 7 * s, Color("2a2f35"))
				draw_circle(f + Vector2(44 * s, -6 * s), 7 * s, Color("2a2f35"))
			"dogs":
				_draw_dogs()
				top = 60.0
			"crew":
				_draw_crew()
			"thing":
				top = _draw_thing(f, s)
	if art_top >= 0.0:
		_cap.position = Vector2(clampf(f.x - _cap.size.x * 0.5, 2.0, size.x - _cap.size.x - 2.0), maxf(2.0, art_top - _cap.size.y - 2.0))
	else:
		_cap.position = Vector2(clampf(f.x - _cap.size.x * 0.5, 2.0, size.x - _cap.size.x - 2.0), maxf(2.0, f.y - top * s - _cap.size.y - 2.0))


## One of the other six's things on the first slot, shut (asking) or open (taken): test shapes. Returns its height.
func _draw_thing(f: Vector2, s: float) -> float:
	var opened: bool = str(ev.get("state", "")) == "done" and str(ev.get("outcome", "")) != "leave"
	match str(ev.get("art", "")):
		"hazard":
			draw_style_box(_boxes["dark"], Rect2(f.x - 70 * s, f.y - 18 * s, 140 * s, 18 * s))           # the hole, the water
			if opened:
				draw_style_box(_boxes["wood"], Rect2(f.x - 80 * s, f.y - 24 * s, 160 * s, 8 * s))        # a plank across it
			return 40.0
		"stash_bag":
			draw_style_box(_boxes["dark"], Rect2(f.x - 26 * s, f.y - 30 * s, 52 * s, 30 * s))
			if not opened:
				draw_line(f + Vector2(-90 * s, -4 * s), f + Vector2(-26 * s, -12 * s), Pal.ACCENT, 1.5)     # the catch
			return 44.0
		"body":
			draw_style_box(_boxes["person"], Rect2(f.x - 58 * s, f.y - 22 * s, 116 * s, 22 * s))         # lying
			if opened:
				draw_style_box(_boxes["dark"], Rect2(f.x + 50 * s, f.y - 12 * s, 26 * s, 12 * s))        # their things out
			return 40.0
		"wreck":
			draw_style_box(_boxes["steel"], Rect2(f.x - 90 * s, f.y - 62 * s, 180 * s, 50 * s))
			draw_style_box(_boxes["dark"], Rect2(f.x - 70 * s, f.y - 56 * s, 60 * s, 20 * s))           # its windows out
			if opened:
				draw_style_box(_boxes["dark"], Rect2(f.x + 10 * s, f.y - 50 * s, 60 * s, 34 * s))        # stripped
			draw_circle(f + Vector2(-60 * s, -10 * s), 12 * s, Color("2a2f35"))
			draw_circle(f + Vector2(60 * s, -10 * s), 12 * s, Color("2a2f35"))
			return 80.0
		"radio":
			draw_style_box(_boxes["steel"], Rect2(f.x - 24 * s, f.y - 34 * s, 48 * s, 34 * s))
			draw_style_box(_boxes["lock"] if opened else _boxes["dark"], Rect2(f.x - 16 * s, f.y - 28 * s, 14 * s, 14 * s))     # its dial lit when heard
			return 50.0
	return 60.0


## A rival crew in the lull: on the gang's three spots, as many as there are (three at most), standing - their own
## picture, else the zone's gang's, else shapes. In the fight the gang's own figures are them (run_view.gd).
func _draw_crew() -> void:
	if str(ev.get("state", "")) == "fight":
		return
	var n: int = mini(3, int(ev.get("n", 0)))
	var t: Texture2D = art("crew_%s_stand" % _zone())
	if t == null:
		t = view.tex("gang_%s_a_stand" % _zone())     # the zone's gang art, as test art
	for k in range(n):
		if t != null:
			_draw_art(t, k)
			continue
		var sp: Array = _spot(k)
		var f: Vector2 = sp[0]
		var s: float = sp[1]
		draw_style_box(_boxes["person"], Rect2(f.x - 18 * s, f.y - 100 * s, 36 * s, 100 * s))


## The dogs: on the gang's three spots, as many as there are (three at most drawn); in the fight each follows the
## figure in its spot (its pop, its bite, its fall), standing in the lull before. Their picture by pose (stand, fire for
## the lunge, down), a lean one in the Outskirts and the Estate, a big one in the Town and the City; shapes without.
func _draw_dogs() -> void:
	var fighting: bool = str(ev.get("state", "")) == "fight"
	var n: int = mini(3, int(ev.get("n", 0)))
	var breed: String = "dog_lean" if int(ev.get("zone", 0)) <= 1 else "dog_big"
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
		var nm: String = "%s_%s" % [breed, "fire" if pose == "lunge" else pose]
		var tx: Texture2D = art(nm)
		if tx != null:
			_draw_art(tx, k, a * ((1.0 - clampf(t / 0.7, 0.0, 1.0) * 0.6) if pose == "down" else 1.0))
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
