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
const SkyLayer := preload("res://scripts/ui/sky.gd")

const W0 := 1000.0                 # the drawing's own space, as the canvas drew it
const H0 := 844.0
const PIN_R := 12.0
const PIN_R_SHUT := 7.0
const HIT_R := 30.0                # a click within this of a pin picks it
const LABEL_W := 300.0
const LABEL_H := 24.0

## The zones' areas, fills and where their names sit (20 Oct: traced off Matt's red lines on the painting; the moor south of the Town and the motorway strip are no zone).
const ZONE_SHAPES := [
	{"points": [Vector2(279, 431), Vector2(271, 433), Vector2(264, 459), Vector2(250, 467), Vector2(94, 466), Vector2(0, 457), Vector2(0, 844), Vector2(412, 844), Vector2(420, 798), Vector2(336, 729), Vector2(305, 713), Vector2(310, 701), Vector2(391, 641), Vector2(395, 630), Vector2(336, 578), Vector2(285, 507), Vector2(279, 489)], "fill": Color("222c25"), "name_at": Vector2(12, 770)},
	{"points": [Vector2(575, 65), Vector2(528, 63), Vector2(457, 53), Vector2(327, 57), Vector2(144, 97), Vector2(94, 117), Vector2(44, 149), Vector2(0, 170), Vector2(0, 454), Vector2(94, 465), Vector2(250, 466), Vector2(262, 461), Vector2(277, 422), Vector2(281, 350), Vector2(288, 322), Vector2(340, 257), Vector2(373, 233), Vector2(449, 193), Vector2(564, 166), Vector2(567, 89)], "fill": Color("282b30"), "name_at": Vector2(12, 180)},
	{"points": [Vector2(356, 245), Vector2(334, 266), Vector2(287, 327), Vector2(277, 429), Vector2(281, 435), Vector2(280, 489), Vector2(292, 515), Vector2(338, 578), Vector2(381, 613), Vector2(398, 633), Vector2(433, 642), Vector2(512, 646), Vector2(627, 689), Vector2(666, 690), Vector2(651, 593), Vector2(652, 575), Vector2(706, 489), Vector2(721, 451), Vector2(725, 423), Vector2(724, 374), Vector2(717, 341), Vector2(689, 286), Vector2(567, 167), Vector2(449, 194)], "fill": Color("2d2a2c"), "name_at": Vector2(400, 300)},
	{"points": [Vector2(577, 63), Vector2(568, 89), Vector2(565, 165), Vector2(686, 281), Vector2(715, 331), Vector2(724, 365), Vector2(727, 423), Vector2(723, 451), Vector2(707, 489), Vector2(653, 575), Vector2(652, 593), Vector2(668, 689), Vector2(803, 822), Vector2(809, 844), Vector2(1000, 844), Vector2(1000, 67), Vector2(782, 70)], "fill": Color("262c34"), "name_at": Vector2(770, 450)},
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
const KEY_H := 30.0
const KEY_PAD := 12.0
const KEY_GAP := 14.0
const KEY_DOT := 10.0
const MAP_AT := Vector2(-3, -2)        # the painting's top left: 1024 x 848 drawn, 3 px off each side, 2 off top and bottom
const LIT := Color(1.0, 0.86, 0.6, 0.08)    # the picked site's zone, lit

var sim
var selected := -1
var order_key := ""
var _zone_names: Array = []        # [name Label, state Label] a zone
var _pin_labels: Array = []        # a Label a site
var _order_labels: Dictionary = {}  # key -> Label
var _legend: Array = []            # [Label, colour, hollow]
var _key_rect := Rect2()           # the key's panel, fitted to its words
var _label_at := {}                # Label -> [the pin's point, its side]: a name sits snug on its own pin
var _shown := ""
var _clouds: ColorRect                 # the cloud over all but the open zones (19 Oct, Matt), when art/map/clouds.png is made
var _sky                               # the sky's layer (23 Oct): night, rain, fog over the painting, under the pins
var _pins: Control                     # the pins, drawn on their own layer over the sky
var _clouds_open := "-"
var _key_bg: Control                   # the key's panel and dots, over the cloud, under its words                # the open zones the cloud's mask was cut for
const MASK_DIV := 6.0                  # the mask at a sixth of the map: smoothed up, a soft edge
const CLOUD_SHADER := """
shader_type canvas_item;
uniform sampler2D tile : repeat_enable, filter_nearest;
uniform sampler2D mask : filter_linear;
uniform sampler2D noise : repeat_enable, filter_linear;
uniform vec2 warp_px = vec2(40.0, 34.0);
uniform vec2 px_size = vec2(1018.0, 844.0);
uniform float tile_px = 228.0;
// a tile's edges needn't meet: near an edge, a copy shifted half a tile takes over (its own edge lies mid-tile, where
// the first is whole) - a crossfade, across and then down, not a mirror (20 Oct, Matt: the mirror's V)
float edge_w(float f) {
	return smoothstep(0.0, 0.18, f) * (1.0 - smoothstep(0.82, 1.0, f));
}
vec3 across(vec2 uv) {
	return mix(texture(tile, uv + vec2(0.5, 0.0)).rgb, texture(tile, uv).rgb, edge_w(fract(uv.x)));
}
vec3 seamless(vec2 uv) {
	return mix(across(uv + vec2(0.0, 0.5)), across(uv), edge_w(fract(uv.y)));
}
// the edge (23 Oct, Matt's yes to the mockup): the softened mask, sampled where two drifting noises push it, so the
// line wanders a little either side; near it the cloud thins in patches into wisps over the open land. The drifts
// four times what they were (1.4 px a second read as a still painting)
void fragment() {
	vec2 px = floor(UV * px_size / 2.0) * 2.0;                 // whole 2 px steps, the painting's pixels
	vec2 a = px / tile_px + vec2(TIME * 0.024, TIME * 0.01);
	vec2 b = px / (tile_px * 1.37) + vec2(0.43, 0.29) - vec2(TIME * 0.016, -TIME * 0.006);
	vec3 col = mix(seamless(a), seamless(b), 0.42);            // two drifts crossed: no repeat
	float n1 = texture(noise, px / 420.0 + vec2(TIME * 0.012, TIME * 0.005)).r;
	float n2 = texture(noise, px / 150.0 - vec2(TIME * 0.02, -TIME * 0.008)).r;
	vec2 warp = (vec2(n1, n2) - 0.5) * warp_px / px_size;
	float open = texture(mask, UV + warp).r;
	float near = smoothstep(0.0, 0.25, open) * (1.0 - smoothstep(0.75, 1.0, open));
	float edge = open + (n2 - 0.5) * 1.1 * near;
	COLOR = vec4(col, 1.0 - smoothstep(0.15, 0.85, edge));
}
"""
static var _art := {}                  # path -> Texture2D or null, looked for once
func _init(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL         # a pad or the keys step the pins (the zone tabs were buttons: the Deck's d-pad got there)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST     # the painting's pixels whole at x2; the words below set back to smooth
	# the sky over the painting (23 Oct, parked item 8), the pins on a layer over it so they keep their colour
	_sky = SkyLayer.new(size)
	add_child(_sky)
	_pins = Control.new()
	_pins.size = size
	_pins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pins.draw.connect(_draw_pins)
	add_child(_pins)
	var tile := art("clouds")
	if tile != null:                        # over the map's drawing and the pins, under every word
		_clouds = ColorRect.new()
		_clouds.size = size
		_clouds.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sh := Shader.new()
		sh.code = CLOUD_SHADER
		var mat := ShaderMaterial.new()
		mat.shader = sh
		mat.set_shader_parameter("tile", tile)
		mat.set_shader_parameter("px_size", size)
		mat.set_shader_parameter("tile_px", tile.get_width() * 2.0)
		mat.set_shader_parameter("noise", SkyLayer.noise())
		mat.set_shader_parameter("warp_px", CLOUD_WARP)
		_clouds.material = mat
		add_child(_clouds)
	_key_bg = Control.new()
	_key_bg.size = size
	_key_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_key_bg.draw.connect(_draw_key)
	add_child(_key_bg)
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
	# the key, bottom right: what a pin's colour says - a dot and its word, packed tight (19 Oct, Matt: "too big ... too
	# spread out")
	var items := [["Safe", Pal.GOOD, false], ["Risky", Pal.WARN, false], ["A bad idea", Pal.BAD, false], ["Locked", Pal.TEXT_3, true]]
	var widths: Array = []
	var total := KEY_PAD
	for e in items:
		var l := UI.label(self, Rect2(0, 0, 10, KEY_H), str(e[0]), "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2 if e[2] else Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var w: float = ceilf(UI.text_width(l, l.text)) + 2.0
		l.size.x = w
		widths.append(w)
		_legend.append([l, e[1], e[2]])
		total += KEY_DOT + 6.0 + w + KEY_GAP
	total += KEY_PAD - KEY_GAP
	_key_rect = Rect2(size.x - total - 12.0, size.y - KEY_H - 12.0, total, KEY_H)
	var kx: float = _key_rect.position.x + KEY_PAD
	for k in range(_legend.size()):
		var l: Label = _legend[k][0]
		l.position = Vector2(kx + KEY_DOT + 6.0, _key_rect.position.y)
		kx += KEY_DOT + 6.0 + float(widths[k]) + KEY_GAP
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


## The cloud's mask: white over the open zones, black elsewhere, at a sixth of the map; cut again when a zone opens.
func _cut_clouds() -> void:
	if _clouds == null or sim == null:
		return
	var key := ""
	for z in range(Data.ZONES.size()):
		key += "1" if sim.zone_open(z) else "0"
	if key == _clouds_open:
		return
	_clouds_open = key
	(_clouds.material as ShaderMaterial).set_shader_parameter("mask", ImageTexture.create_from_image(soft_mask(cloud_mask(key, size))))


## The mask softened for the cloud's edge (23 Oct): the open land grown SOFT_GROW cells into the shut first, so the ramp
## and the wisps fall mostly on the cloud's side and the open sites' pins stay clear (the review: a pin 31 px in sat
## under them); then halved twice, each an average of four (a shrink straight to a quarter samples, and loses a thin
## strip), and grown back.
const SOFT_GROW := 2
const CLOUD_WARP := Vector2(40.0, 34.0)  # the most the edge wanders, px, the two noises' full swing
static func soft_mask(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_L8)
	for y in range(h):
		for x in range(w):
			var m := 0.0
			for dy in range(-SOFT_GROW, SOFT_GROW + 1):
				for dx in range(-SOFT_GROW, SOFT_GROW + 1):
					m = maxf(m, img.get_pixel(clampi(x + dx, 0, w - 1), clampi(y + dy, 0, h - 1)).r)
			out.set_pixel(x, y, Color(m, m, m))
	for i in range(2):
		out.resize(maxi(1, int(out.get_width() / 2.0)), maxi(1, int(out.get_height() / 2.0)), Image.INTERPOLATE_BILINEAR)
	out.resize(w, h, Image.INTERPOLATE_CUBIC)
	return out


## The most cloud the shader can lay over a point (the smoke: every open site's pin under 0.1): the least open of the
## soft mask across the edge's wander, the wisps' pull at their strongest.
static func cloud_cover_bound(soft: Image, p: Vector2, map_size: Vector2) -> float:
	var lo := 1.0
	for fy in [-0.5, -0.25, 0.0, 0.25, 0.5]:
		for fx in [-0.5, -0.25, 0.0, 0.25, 0.5]:
			var q: Vector2 = (p + Vector2(fx, fy) * CLOUD_WARP) / map_size * Vector2(soft.get_width(), soft.get_height())
			lo = minf(lo, soft.get_pixel(clampi(int(q.x), 0, soft.get_width() - 1), clampi(int(q.y), 0, soft.get_height() - 1)).r)
	var near: float = smoothstep(0.0, 0.25, lo) * (1.0 - smoothstep(0.75, 1.0, lo))
	return 1.0 - smoothstep(0.15, 0.85, lo - 0.55 * near)


## The mask for a set of open zones ("1100": the first two): each cell white when its middle is in an open zone.
## With every zone open, the whole map, the ground that's no zone's included.
static func cloud_mask(key: String, map_size: Vector2) -> Image:
	var w := int(ceilf(map_size.x / MASK_DIV))
	var h := int(ceilf(map_size.y / MASK_DIV))
	var img := Image.create(w, h, false, Image.FORMAT_L8)
	if key.length() >= ZONE_SHAPES.size() and not key.contains("0"):
		img.fill(Color.WHITE)                # every zone open, the City last (20 Oct, Matt): the motorway and the moor clear with it
		return img
	var polys: Array = []
	for z in range(mini(key.length(), ZONE_SHAPES.size())):
		if key[z] == "1":
			polys.append(PackedVector2Array(ZONE_SHAPES[z]["points"]))
	for y in range(h):
		for x in range(w):
			var p := Vector2((x + 0.5) * MASK_DIV * W0 / map_size.x, (y + 0.5) * MASK_DIV * H0 / map_size.y)
			var inside := false
			for poly in polys:
				if Geometry2D.is_point_in_polygon(p, poly):
					inside = true
					break
			img.set_pixel(x, y, Color.WHITE if inside else Color.BLACK)
	return img


## The painting, if made.
static func painting() -> Texture2D:
	return art("map")


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
	_label_at[l] = [p, side]
	return l


## A pin's name hugging its own pin (19 Oct, Matt: the Allotments' name drifted off its dot): above or below, its box the
## word's own width centred on the pin, kept inside the map; left or right as laid.
func _snug(l: Label) -> void:
	var at: Array = _label_at.get(l, [])
	if at.is_empty() or not (int(at[1]) == BELOW or int(at[1]) == ABOVE):
		return
	var w: float = ceilf(UI.text_width(l, l.text)) + 4.0
	l.size.x = w
	l.position.x = clampf(at[0].x - w / 2.0, 4.0, size.x - 4.0 - w)


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
	var sig := "%s|%d|%s|%s|%s|%s|%s|%d|%d" % [settled, selected, order_key, opens, str(sim.best_depth), str(sim.bosses_beaten), str(sim.weather), sim.level(), int(sim.is_night())]
	if sig == _shown:
		return
	_shown = sig
	_cut_clouds()
	_sky.set_sky(sim.is_night(), sim.weather_of(selected) if selected >= 0 else "")     # the picked site's zone's sky, as its card says (23 Oct)
	for z in range(Data.ZONES.size()):
		var nm: Label = _zone_names[z][0]
		var st: Label = _zone_names[z][1]
		var open_z: bool = sim.zone_open(z)
		nm.text = str(Data.ZONES[z]["name"]) if open_z else Fmt.scramble(str(Data.ZONES[z]["name"]))     # not yet known (20 Oct, Matt)
		nm.add_theme_color_override("font_color", Pal.TEXT if open_z else Pal.TEXT_2)
		if not open_z and sim.zone_level_shut(z):
			UI.fit(st, ["Level %d required" % sim.zone_gate(z), "Level %d" % sim.zone_gate(z)])
			st.add_theme_color_override("font_color", Pal.TEXT_2)
		elif not open_z:
			var before: Dictionary = sim.zone_boss(z - 1) if z > 0 else {}
			var after: String = str(before["name"]) if not before.is_empty() else str(Data.ZONES[maxi(0, z - 1)]["name"])
			if z > 0 and not sim.zone_open(z - 1):
				after = Fmt.scramble(after)        # a head of a zone not yet known: scrambled too
			UI.fit(st, ["After %s" % Words.mid(after), ""])
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
		var known: bool = sim.zone_open(z)
		l.visible = true
		l.text = str(Data.TIERS[i]["name"]) if known else Fmt.scramble(str(Data.TIERS[i]["name"]))     # the name only (19 Oct); scrambled till its zone's open (20 Oct)
		_snug(l)
		var picked_now: bool = i == selected and order_key == ""
		l.add_theme_color_override("font_color", Pal.ACCENT if picked_now else (Pal.TEXT if sim.tier_open(i) else (Pal.TEXT_2 if known else Pal.TEXT_3)))
	for p in Data.PINNACLES:
		var l: Label = _order_labels[p["key"]]
		l.visible = sim.order_open(p["key"])
		if l.visible:
			var ok: bool = sim.order_known(p["key"])
			l.text = str(p["place"]) if ok else Fmt.scramble(str(p["place"]))     # scrambled till its zone's open (20 Oct)
			_snug(l)
			l.add_theme_color_override("font_color", Pal.ACCENT if order_key == p["key"] else (Pal.TEXT if ok else Pal.TEXT_3))
	queue_redraw()
	_pins.queue_redraw()


func _draw() -> void:
	var pic := painting()
	if pic != null:
		draw_texture_rect(pic, Rect2(MAP_AT, pic.get_size() * 2.0), false)
	else:
		_draw_flat()
	# the picked site's zone, lit: its shape washed warm (its yellow outline gone, 23 Oct, Matt: "the yellow boundaries
	# just read wrong")
	var lit_z := lit_zone()
	if lit_z >= 0 and sim != null and sim.zone_open(lit_z):
		draw_colored_polygon(_scaled(PackedVector2Array(ZONE_SHAPES[lit_z]["points"])), LIT)
	# a shut zone under a hatch, where there's no cloud
	for z in range(Data.ZONES.size()):
		if _clouds == null and sim != null and not sim.zone_open(z):
			_hatch(ZONE_SHAPES[z]["points"])
	# the pins: their own layer (_draw_pins), over the sky
	# the key's panel and its dots: their own layer (_draw_key), over the cloud


## The pins, on their own layer over the sky (23 Oct): the sites in their odds' colour, the order's places as diamonds.
func _draw_pins() -> void:
	if sim == null:
		return
	for i in range(Data.TIERS.size()):
		var c: Vector2 = _px(SITE_AT[i])
		var open: bool = sim.tier_open(i)
		var zone_open: bool = sim.zone_open(int(Data.TIERS[i]["zone"]))
		var r: float = PIN_R if zone_open else PIN_R_SHUT
		if i == selected and order_key == "":
			_pins.draw_circle(c, r + 9.0, Color(Pal.ACCENT, 0.25))
			_pins.draw_circle(c, r + 5.0, Pal.ACCENT)
		_pins.draw_circle(c, r + 3.0, Pal.BG)
		if open:
			_pins.draw_circle(c, r, _tone(i))
		else:
			_pins.draw_circle(c, r, Pal.BUTTON)
			_pins.draw_arc(c, r, 0.0, TAU, 24, Pal.TEXT_3 if zone_open else Color("5a6068"), 2.0)
	for p in Data.PINNACLES:
		if not sim.order_open(p["key"]):
			continue
		var c: Vector2 = _px(ORDER_AT[p["key"]])
		if order_key == p["key"]:
			_pins.draw_circle(c, PIN_R + 9.0, Color(Pal.ACCENT, 0.25))
		var d := PIN_R + 3.0                 # a diamond: the order's places aren't the campaign's
		_pins.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d - 3), c + Vector2(d + 3, 0), c + Vector2(0, d + 3), c + Vector2(-d - 3, 0)]), Pal.BG)
		_pins.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0), c + Vector2(0, d), c + Vector2(-d, 0)]), Pal.ACCENT)


## The key's panel and its dots, on their own layer over the cloud.
func _draw_key() -> void:
	_key_bg.draw_rect(_key_rect, Color(Pal.PANEL, 0.88))
	_key_bg.draw_rect(_key_rect, Pal.CARD_LINE, false, 1.0)
	for e in _legend:
		var l: Label = e[0]
		var dc := Vector2(l.position.x - 6.0 - KEY_DOT / 2.0, l.position.y + KEY_H / 2.0)
		if e[2]:
			_key_bg.draw_arc(dc, KEY_DOT / 2.0 - 1.0, 0.0, TAU, 16, e[1], 2.0)
		else:
			_key_bg.draw_circle(dc, KEY_DOT / 2.0, e[1])


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
		if sim.order_known(p["key"]):          # a place in a shut zone doesn't pick, as its pins don't (20 Oct)
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
