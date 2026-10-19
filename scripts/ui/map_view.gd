extends Control
## The drawn Map (19 Oct, Matt's pick B on the canvas "Fiat – The drawn map"): the four zones as areas of one map -
## the Outskirts' fields, the Estate's grid, the Town's ring road, the City past the river - each site a pin in its
## odds' colour, a shut zone under a hatch, the order's places as pins once their rebuild has opened them. A pin picked
## shows its card at the Map's right (missions.gd). The painting (19 Oct, Matt: "a single image with everything on it ...
## then we carve it up in the game"): art/map/map.png, 512 x 424, drawn x2 nearest from (-3, -2) so it fills the
## 1018 x 844; the zones' shapes and the pins are traced off it. The picked site's zone is lit, a shut zone hatched.
## Without the picture the old flat drawing stands in (shapes, roads, river).
##
## Signals: `picked(i)` for a site, `picked_order(key)` for an order's place.

signal picked(i: int)
signal picked_order(key: String)

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const Items := preload("res://scripts/sim/items.gd")

const W0 := 1000.0                 # the drawing's own space, as the canvas drew it
const H0 := 844.0
const PIN_R := 12.0
const PIN_R_SHUT := 7.0
const HIT_R := 30.0                # a click within this of a pin picks it
const LABEL_W := 300.0
const LABEL_H := 24.0

## The zones' areas, fills and where their names sit (the canvas's shapes).
const ZONE_SHAPES := [
	{"points": [Vector2(0, 483), Vector2(282, 476), Vector2(321, 558), Vector2(410, 628), Vector2(370, 698), Vector2(390, 844), Vector2(0, 844)], "fill": Color("222c25"), "name_at": Vector2(12, 770)},
	{"points": [Vector2(0, 108), Vector2(243, 58), Vector2(547, 58), Vector2(557, 168), Vector2(459, 208), Vector2(370, 238), Vector2(292, 298), Vector2(282, 468), Vector2(0, 473)], "fill": Color("282b30"), "name_at": Vector2(12, 116)},
	{"points": [Vector2(292, 328), Vector2(351, 248), Vector2(459, 208), Vector2(547, 198), Vector2(626, 228), Vector2(685, 298), Vector2(685, 418), Vector2(645, 538), Vector2(640, 600), Vector2(650, 668), Vector2(560, 668), Vector2(540, 612), Vector2(488, 618), Vector2(370, 588), Vector2(302, 498)], "fill": Color("2d2a2c"), "name_at": Vector2(400, 300)},
	{"points": [Vector2(675, 38), Vector2(1000, 38), Vector2(1000, 844), Vector2(842, 844), Vector2(763, 678), Vector2(744, 518), Vector2(753, 328), Vector2(724, 198), Vector2(665, 118)], "fill": Color("262c34"), "name_at": Vector2(770, 450)},
]
## Each site's pin, by its index in Data.TIERS (the Outskirts' three, the Estate's, the Town's, the City's).
const SITE_AT := [Vector2(36, 638), Vector2(262, 778), Vector2(223, 628),
	Vector2(135, 418), Vector2(292, 268), Vector2(390, 118),
	Vector2(547, 238), Vector2(616, 418), Vector2(567, 528),
	Vector2(832, 108), Vector2(852, 388), Vector2(852, 598)]
## Where a pin's name sits: below it, above, to its right or its left - so no two names cross, nor a zone's name.
enum { BELOW, ABOVE, RIGHT, LEFT }
const SITE_LABEL := [BELOW, RIGHT, ABOVE, BELOW, BELOW, ABOVE, BELOW, BELOW, BELOW, BELOW, BELOW, LEFT]
## The order's places (18 Oct), by key: off their host site, out along the road east.
const ORDER_AT := {"grid": Vector2(842, 248), "archive": Vector2(596, 643), "mint": Vector2(940, 728)}
const ORDER_LABEL := {"grid": BELOW, "archive": ABOVE, "mint": BELOW}
const ART_DIR := "res://art/map/"
const MAP_AT := Vector2(-3, -2)        # the painting's top left: 1024 x 848 drawn, 3 px off each side, 2 off top and bottom
const LIT := Color(1.0, 0.86, 0.6, 0.08)    # the picked site's zone, lit

var sim
var selected := -1
var order_key := ""
var _zone_names: Array = []        # [name Label, state Label] a zone
var _pin_labels: Array = []        # a Label a site
var _order_labels: Dictionary = {}  # key -> Label
var _legend: Array = []            # [Label, colour, hollow]
var _shown := ""
static var _art := {}                  # path -> Texture2D or null, looked for once
func _init(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL         # a pad or the keys step the pins (the zone tabs were buttons: the Deck's d-pad got there)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST     # the painting's pixels whole at x2; the words below set back to smooth
	for z in range(Data.ZONES.size()):
		var at: Vector2 = _px(ZONE_SHAPES[z]["name_at"])
		var room: float = minf(320.0, size.x - at.x - 8.0)
		var nm := UI.label(self, Rect2(at.x, at.y, room, 32), str(Data.ZONES[z]["name"]), "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var st := UI.label(self, Rect2(at.x, at.y + 32, room, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		UI.shadow(nm)
		UI.shadow(st)
		_zone_names.append([nm, st])
	for i in range(Data.TIERS.size()):
		var l := _pin_label(_px(SITE_AT[i]), int(SITE_LABEL[i]), Pal.TEXT)
		_pin_labels.append(l)
	for k in ORDER_AT:
		_order_labels[k] = _pin_label(_px(ORDER_AT[k]), int(ORDER_LABEL[k]), Pal.ACCENT)
	# the key, bottom right: what a pin's colour says
	var x := size.x - 470.0
	for e in [["Safe", Pal.GOOD, false], ["Risky", Pal.WARN, false], ["A bad idea", Pal.BAD, false], ["Locked", Pal.TEXT_3, true]]:
		var l := UI.label(self, Rect2(x + 20, size.y - 44, 96, 26), str(e[0]), "Regular", Pal.CELL_TEXT, Pal.TEXT_2 if e[2] else Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		_legend.append([l, e[1], e[2]])
		x += 116.0
	for c in get_children():
		if c is CanvasItem:
			c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


## A picture of the map's, if made: imported, or dropped in and not yet imported; null when there's none.
static func art(nm: String) -> Texture2D:
	var path: String = ART_DIR + nm + ".png"
	if not _art.has(path):
		_art[path] = null
		if ResourceLoader.exists(path):
			_art[path] = load(path)
		elif FileAccess.file_exists(path):
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))
			if img != null:
				_art[path] = ImageTexture.create_from_image(img)
	return _art[path]


## The painting, if made.
static func painting() -> Texture2D:
	return art("map")


## The drawing's box round a zone's shape: its ground's picture covers it.
static func zone_box(z: int) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in ZONE_SHAPES[z]["points"]:
		lo = lo.min(p)
		hi = hi.max(p)
	return Rect2(lo, hi - lo)


## A pin's name: its box on the side asked, kept inside the map.
func _pin_label(p: Vector2, side: int, col: Color) -> Label:
	var r := Rect2(p.x - LABEL_W / 2.0, p.y + PIN_R + 6, LABEL_W, LABEL_H)
	var align := HORIZONTAL_ALIGNMENT_CENTER
	match side:
		ABOVE:
			r.position.y = p.y - PIN_R - 6 - LABEL_H
		RIGHT:
			r = Rect2(p.x + PIN_R + 8, p.y - LABEL_H / 2.0, LABEL_W, LABEL_H)
			align = HORIZONTAL_ALIGNMENT_LEFT
		LEFT:
			r = Rect2(p.x - PIN_R - 8 - LABEL_W, p.y - LABEL_H / 2.0, LABEL_W, LABEL_H)
			align = HORIZONTAL_ALIGNMENT_RIGHT
	r.position.x = clampf(r.position.x, 4.0, size.x - 4.0 - r.size.x)
	var l := UI.label(self, r, "", "SemiBold", Pal.CELL_TEXT, col, align, false)
	UI.shadow(l)
	return l


## A point of the drawing's space on the control.
func _px(p: Vector2) -> Vector2:
	return Vector2(p.x * size.x / W0, p.y * size.y / H0)


## The pin's tone: the odds as read, grey while they're read, hollow when shut.
func _tone(i: int) -> Color:
	if not sim.tier_open(i):
		return Pal.CARD_LINE
	if not sim.odds_ready(i):
		return Pal.TEXT_3
	var o: float = sim.odds_now(i)
	return Pal.GOOD if o >= 0.9 else (Pal.WARN if o >= 0.6 else Pal.BAD)


func show_state(s, sel: int, okey: String) -> void:
	sim = s
	selected = sel
	order_key = okey
	var settled := ""
	for i in range(Data.TIERS.size()):
		settled += "%d%d%d" % [int(sim.tier_open(i)), int(sim.odds_ready(i)), roundi(sim.odds_now(i) * 100.0)]
	var opens := ""
	for p in Data.PINNACLES:
		opens += "1" if sim.order_open(p["key"]) else "0"
	var sig := "%s|%d|%s|%s|%s|%s|%s|%d" % [settled, selected, order_key, opens, str(sim.best_depth), str(sim.bosses_beaten), str(sim.weather), sim.level()]
	if sig == _shown:
		return
	_shown = sig
	for z in range(Data.ZONES.size()):
		var nm: Label = _zone_names[z][0]
		var st: Label = _zone_names[z][1]
		var open_z: bool = sim.zone_open(z)
		nm.add_theme_color_override("font_color", Pal.TEXT if open_z else Pal.TEXT_2)
		if not open_z and sim.zone_level_shut(z):
			UI.fit(st, ["Locked · level %d required" % sim.zone_gate(z), "Level %d required" % sim.zone_gate(z), "Level %d" % sim.zone_gate(z)])
			st.add_theme_color_override("font_color", Pal.TEXT_2)
		elif not open_z:
			var before: Dictionary = sim.zone_boss(z - 1) if z > 0 else {}
			var after: String = str(before["name"]) if not before.is_empty() else str(Data.ZONES[maxi(0, z - 1)]["name"])
			UI.fit(st, ["Locked · after %s" % after, "Locked"])
			st.add_theme_color_override("font_color", Pal.TEXT_3)
		elif sim.zone_complete(z):
			st.text = "Cleared"
			st.add_theme_color_override("font_color", Pal.GOOD)
		else:
			var sky: String = sim.sky_words(int(Data.ZONES[z]["tiers"][0]), false)
			UI.fit(st, [sky, sky.get_slice(",", 0)])
			st.add_theme_color_override("font_color", Pal.TEXT_2)
	for i in range(Data.TIERS.size()):
		var l: Label = _pin_labels[i]
		var z: int = int(Data.TIERS[i]["zone"])
		l.visible = sim.zone_open(z)
		if not l.visible:
			continue
		var nm: String = str(Data.TIERS[i]["name"])
		if sim.tier_open(i):
			var o: String = Fmt.pct(sim.odds_now(i)) if sim.odds_ready(i) else "…"
			UI.fit(l, ["%s · %s" % [nm, o], nm])
		elif sim.level_gated(i) and (Data.ZONES[z]["tiers"].find(i) == 0 or int(sim.best_depth[i - 1]) > 0):
			UI.fit(l, ["%s · opens at level %d" % [nm, sim.site_gate(i)], "%s · level %d" % [nm, sim.site_gate(i)], nm])
		else:
			UI.fit(l, ["%s · after %s" % [nm, Words.mid(Data.TIERS[i - 1]["name"])], nm])
		var picked_now: bool = i == selected and order_key == ""
		l.add_theme_color_override("font_color", Pal.ACCENT if picked_now else (Pal.TEXT if sim.tier_open(i) else Pal.TEXT_2))
	for p in Data.PINNACLES:
		var l: Label = _order_labels[p["key"]]
		l.visible = sim.order_open(p["key"])
		if l.visible:
			var od: Array = sim.order_odds_now(p["key"])
			UI.fit(l, ["%s · %s" % [p["place"], Fmt.pct(float(od[0])) if bool(od[1]) else "…"], str(p["place"])])
			l.add_theme_color_override("font_color", Pal.ACCENT if order_key == p["key"] else Pal.TEXT)
	queue_redraw()


func _draw() -> void:
	var pic := painting()
	if pic != null:
		draw_texture_rect(pic, Rect2(MAP_AT, pic.get_size() * 2.0), false)
	else:
		_draw_flat()
	# the picked site's zone, lit: its shape washed warm and outlined
	var lit_z := lit_zone()
	if lit_z >= 0 and sim != null and sim.zone_open(lit_z):
		var pts := _scaled(PackedVector2Array(ZONE_SHAPES[lit_z]["points"]))
		draw_colored_polygon(pts, LIT)
		pts.append(pts[0])
		draw_polyline(pts, Color(Pal.ACCENT, 0.7), 2.0)
	# a shut zone under a hatch
	for z in range(Data.ZONES.size()):
		if sim != null and not sim.zone_open(z):
			_hatch(ZONE_SHAPES[z]["points"])
	if sim == null:
		return
	for i in range(Data.TIERS.size()):
		var c: Vector2 = _px(SITE_AT[i])
		var open: bool = sim.tier_open(i)
		var zone_open: bool = sim.zone_open(int(Data.TIERS[i]["zone"]))
		var r: float = PIN_R if zone_open else PIN_R_SHUT
		if i == selected and order_key == "":
			draw_circle(c, r + 9.0, Color(Pal.ACCENT, 0.25))
			draw_circle(c, r + 5.0, Pal.ACCENT)
		draw_circle(c, r + 3.0, Pal.BG)
		if open:
			draw_circle(c, r, _tone(i))
		else:
			draw_circle(c, r, Pal.BUTTON)
			draw_arc(c, r, 0.0, TAU, 24, Pal.TEXT_3 if zone_open else Color("5a6068"), 2.0)
	for p in Data.PINNACLES:
		if not sim.order_open(p["key"]):
			continue
		var c: Vector2 = _px(ORDER_AT[p["key"]])
		if order_key == p["key"]:
			draw_circle(c, PIN_R + 9.0, Color(Pal.ACCENT, 0.25))
		var d := PIN_R + 3.0                 # a diamond: the order's places aren't the campaign's
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d - 3), c + Vector2(d + 3, 0), c + Vector2(0, d + 3), c + Vector2(-d - 3, 0)]), Pal.BG)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0), c + Vector2(0, d), c + Vector2(-d, 0)]), Pal.ACCENT)
	# the key's panel and its dots
	var kx: float = size.x - 486.0
	draw_rect(Rect2(kx, size.y - 56, 470, 44), Color(Pal.PANEL, 0.92))
	draw_rect(Rect2(kx, size.y - 56, 470, 44), Pal.CARD_LINE, false, 1.0)
	for e in _legend:
		var l: Label = e[0]
		var dc := Vector2(l.position.x - 10, l.position.y + 13)
		if e[2]:
			draw_arc(dc, 6.0, 0.0, TAU, 16, e[1], 2.0)
		else:
			draw_circle(dc, 6.0, e[1])


## No painting: the old drawn map - the zones' fills, the river, the motorway.
func _draw_flat() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("181b1f"))
	for z in range(ZONE_SHAPES.size()):
		var pts := _scaled(PackedVector2Array(ZONE_SHAPES[z]["points"]))
		draw_colored_polygon(pts, ZONE_SHAPES[z]["fill"])
		pts.append(pts[0])
		draw_polyline(pts, Pal.CARD_LINE, 2.0)
	_curve([Vector2(560, 0), Vector2(620, 160), Vector2(610, 300), Vector2(690, 470), Vector2(800, 640), Vector2(1000, 800)], Color("26394b"), 16.0)
	_curve([Vector2(0, 120), Vector2(300, 100), Vector2(560, 100), Vector2(720, 140), Vector2(1000, 150)], Color("3d4249"), 11.0)


## The zone lit: the picked site's, or the picked order place's host site's; -1 for none.
func lit_zone() -> int:
	if order_key != "":
		var p: Dictionary = Data.pinnacle(order_key)
		return int(p.get("zone", -1))
	if selected >= 0 and selected < Data.TIERS.size():
		return int(Data.TIERS[selected]["zone"])
	return -1


## A road or the river: a polyline through the drawing's points, smoothed.
func _curve(pts: Array, col: Color, w: float) -> void:
	var out := PackedVector2Array()
	for k in range(pts.size() - 1):
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var a0: Vector2 = pts[maxi(0, k - 1)]
		var b1: Vector2 = pts[mini(pts.size() - 1, k + 2)]
		for s in range(8):
			var t := s / 8.0
			out.append(_px(_catmull(a0, a, b, b1, t)))
	out.append(_px(pts.back()))
	draw_polyline(out, col, w * size.x / W0, true)


static func _catmull(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


## Diagonal strokes over a zone, clipped to its shape by stepping along each stroke.
func _hatch(points: Array) -> void:
	var poly := PackedVector2Array()
	for p in points:
		poly.append(p)
	draw_colored_polygon(_scaled(poly), Color(0, 0, 0, 0.35))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	var step := 18.0
	var c := lo.x - (hi.y - lo.y)
	while c < hi.x:
		var a := Vector2(c, hi.y)
		var b := Vector2(c + (hi.y - lo.y), lo.y)
		var inside := false
		var from := Vector2.ZERO
		for k in range(41):
			var p: Vector2 = a.lerp(b, k / 40.0)
			var now: bool = Geometry2D.is_point_in_polygon(p, poly)
			if now and not inside:
				from = p
			elif not now and inside:
				draw_line(_px(from), _px(p), Color("1c1f23"), 5.0)
			inside = now
		if inside:
			draw_line(_px(from), _px(b), Color("1c1f23"), 5.0)
		c += step


func _scaled(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(_px(p))
	return out


func _gui_input(ev: InputEvent) -> void:
	if sim == null:
		return
	for dir in [["ui_right", 1], ["ui_left", -1], ["ui_down", 1], ["ui_up", -1]]:
		if ev.is_action_pressed(str(dir[0])):
			var to: int = step_site(int(dir[1]))
			if to >= 0:
				picked.emit(to)
				accept_event()
			return
	if not (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
		return
	var at: Vector2 = ev.position
	var best := HIT_R
	var hit_i := -1
	var hit_k := ""
	for i in range(Data.TIERS.size()):
		if not sim.zone_open(int(Data.TIERS[i]["zone"])):
			continue
		var d: float = at.distance_to(_px(SITE_AT[i]))
		if d < best:
			best = d
			hit_i = i
	for p in Data.PINNACLES:
		if sim.order_open(p["key"]):
			var d: float = at.distance_to(_px(ORDER_AT[p["key"]]))
			if d < best:
				best = d
				hit_k = p["key"]
				hit_i = -1
	if hit_k != "":
		picked_order.emit(hit_k)
		accept_event()
	elif hit_i >= 0:
		picked.emit(hit_i)
		accept_event()


## The next site along (1) or back (-1) from the picked one among the open zones' sites, round the end; -1 for none.
func step_site(by: int) -> int:
	var sites: Array = range(Data.TIERS.size()).filter(func(i): return sim.zone_open(int(Data.TIERS[i]["zone"])))
	if sites.is_empty():
		return -1
	var at: int = sites.find(selected)
	return int(sites[posmod((at if at >= 0 else 0) + by, sites.size())])


## Where a site's pin is, on the control (for the tests' clicks).
func pin_at(i: int) -> Vector2:
	return _px(SITE_AT[i])


func order_pin_at(key: String) -> Vector2:
	return _px(ORDER_AT[key])


func text_nodes() -> Array:
	var out: Array = []
	for pair in _zone_names:
		out.append_array(pair)
	for l in _pin_labels:
		if l.visible:
			out.append(l)
	for k in _order_labels:
		if _order_labels[k].visible:
			out.append(_order_labels[k])
	for e in _legend:
		out.append(e[0])
	return out
