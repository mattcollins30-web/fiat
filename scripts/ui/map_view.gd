extends Control
## The drawn Map (19 Oct, Matt's pick B on the canvas "Fiat – The drawn map"): the four zones as areas of one map -
## the Outskirts' fields, the Estate's grid, the Town's ring road, the City past the river - each site a pin in its
## odds' colour, a shut zone under a hatch, the order's places as pins once their rebuild has opened them. A pin picked
## shows its card at the Map's right (missions.gd). The painting (19 Oct, Matt: "a single image with everything on it ...
## then we carve it up in the game"): art/map/map.png - Matt's redraw (5 Nov, BUILD52: "lets redraw the map - ill do it
## manually"), 688 x 384 - drawn x2 nearest from the land's top left, the land its size x2; the zones' shapes and the
## pins are traced off it, in its own pixels, and read from data/map_places.tres (the F3/F5 tool, map_placement.gd,
## moves them). The picked site's zone is lit, a shut zone hatched. Without the picture the old flat drawing stands in.
##
## Signals: `picked(i)` for a site, `picked_order(key)` for an order's place.

signal picked(i: int)
signal picked_order(key: String)
signal picked_town(key: String)     # a town's place's pin (BUILD50-T): its card on the Radio's Town tab
signal empty_clicked                # a click on the land, no pin under it (BUILD51-U, item 2): the side panel goes

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const Items := preload("res://scripts/sim/items.gd")
const SkyLayer := preload("res://scripts/ui/sky.gd")
const MapPan := preload("res://scripts/ui/map_pan.gd")
## The land (BUILD52; BUILD51-U made it pan): the painting drawn PX times nearest, the game's pixel size, the land its
## size - read from the texture, not a table. Every place's point is in the painting's pixels; _px() puts it on the land.
## Its frame (missions.gd) shows a part, panned by drag and wheel; a frame bigger than the land shows it centred.
const PX := 2.0                        # a painting's pixel on the screen
const PAINT_FALLBACK := Vector2(688, 384)    # the land's painting size with no painting (the flat drawing stands in)
const OLD_SPACE := Vector2(1000, 844)  # the flat drawing's roads and river, as the first canvas drew them
const PIN_R := 12.0
const PIN_R_SHUT := 7.0
const HIT_R := 30.0                # a click within this of a pin picks it
const LABEL_W := 300.0
const LABEL_H := 24.0

## The zones' areas, fills and where their names sit, in the painting's pixels (BUILD52: re-traced to Matt's redraw - the
## Outskirts the fields bottom left, the Estate the towers and the retail park, the Town in and on the ring road, the
## City east of the river; the motorway strip and the river are no zone). The fallback: data/map_places.tres rules.
const ZONE_SHAPES := [
	{"points": [Vector2(0, 232), Vector2(150, 236), Vector2(190, 248), Vector2(235, 282), Vector2(262, 300), Vector2(250, 340), Vector2(240, 384), Vector2(0, 384)], "fill": Color("222c25"), "name_at": Vector2(8, 345)},
	{"points": [Vector2(0, 34), Vector2(205, 34), Vector2(205, 100), Vector2(185, 135), Vector2(165, 170), Vector2(158, 215), Vector2(150, 232), Vector2(0, 228)], "fill": Color("282b30"), "name_at": Vector2(8, 34)},
	{"points": [Vector2(210, 92), Vector2(260, 85), Vector2(330, 78), Vector2(390, 88), Vector2(440, 105), Vector2(470, 125), Vector2(495, 150), Vector2(505, 185), Vector2(500, 225), Vector2(480, 262), Vector2(455, 300), Vector2(430, 318), Vector2(380, 320), Vector2(330, 310), Vector2(280, 300), Vector2(240, 280), Vector2(195, 252), Vector2(165, 222), Vector2(162, 180), Vector2(180, 135)], "fill": Color("2d2a2c"), "name_at": Vector2(260, 150)},
	{"points": [Vector2(470, 32), Vector2(688, 32), Vector2(688, 384), Vector2(455, 384), Vector2(470, 330), Vector2(505, 290), Vector2(535, 250), Vector2(540, 200), Vector2(530, 150), Vector2(500, 118), Vector2(465, 95), Vector2(455, 60)], "fill": Color("262c34"), "name_at": Vector2(555, 268)},
]
## Each site's pin, by its index in Data.TIERS (the Outskirts' three, the Estate's, the Town's, the City's), in the
## painting's pixels: the fallback (data/map_places.tres rules).
const SITE_AT := [Vector2(25, 282), Vector2(215, 315), Vector2(125, 285),
	Vector2(60, 80), Vector2(172, 115), Vector2(55, 172),
	Vector2(400, 132), Vector2(415, 212), Vector2(450, 170),
	Vector2(540, 55), Vector2(632, 112), Vector2(655, 245)]
## Where a pin's name sits: below it, above, to its right or its left - so no two names cross, nor a zone's name.
enum { BELOW, ABOVE, RIGHT, LEFT }
const SITE_LABEL := [BELOW, RIGHT, ABOVE, BELOW, BELOW, ABOVE, BELOW, BELOW, BELOW, BELOW, BELOW, LEFT]
## The order's places (18 Oct), by key: off their host site, out along the road east.
const ORDER_AT := {"grid": Vector2(628, 182), "archive": Vector2(415, 296), "mint": Vector2(630, 330)}
const ORDER_LABEL := {"grid": BELOW, "archive": ABOVE, "mint": BELOW}
## The town's places (act two §1, BUILD50-T; the canvas "The town on the Map"): a square each in the Town and the City,
## clear of the sites' and the order's pins and names - ringed while not built, dashed the next step, lit running (a
## glow), red-ringed and unlit stopped, unpaid. Shown once the rebuild's open.
const TOWN_AT := {"substation": Vector2(325, 62), "pumping": Vector2(530, 322), "bus_depot": Vector2(250, 48),
	"market_hall": Vector2(360, 245), "library": Vector2(330, 330), "mint": Vector2(470, 255)}
const TOWN_R := 9.0
const TOWN_LIT := Color("e9d3a1")    # a running place's name, the canvas's
const ART_DIR := "res://art/map/"
const KEY_H := 30.0
const KEY_PAD := 12.0
const KEY_GAP := 14.0
const KEY_DOT := 10.0
const LIT := Color(1.0, 0.86, 0.6, 0.08)    # the picked site's zone, lit

var sim
var selected := -1
var order_key := ""
var _zone_names: Array = []        # [name Label, state Label] a zone
var _pin_labels: Array = []        # a Label a site
var _order_labels: Dictionary = {}  # key -> Label
var _town_labels: Dictionary = {}   # a town's place: key -> Label (BUILD50-T)
var town_states: Dictionary = {}    # key -> "running", "stopped", "next", "ringed" as drawn (the smoke reads them)
var _legend: Array = []            # [Label, colour, hollow]
var _key_rect := Rect2()           # the key's panel, fitted to its words
var _label_at := {}                # Label -> [the pin's point, its side]: a name sits snug on its own pin
var _shown := ""
var _clouds: ColorRect                 # the cloud over all but the open zones (19 Oct, Matt), when art/map/clouds.png is made
var _sky                               # the sky's layer (23 Oct): night, rain, fog over the painting, under the pins
var _pins: Control                     # the pins, drawn on their own layer over the sky
var _clouds_open := "-"
var _sky_clip: Control                 # the sky's clip: the land in the view (BUILD52)
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
uniform float land_k = 1.0;             // the land over today's map (BUILD51-U): the cloud read in today's pixels, drawn bigger
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
	vec2 px = floor(UV * px_size / (2.0 * land_k)) * 2.0;      // whole steps of the painting's pixels, in today's map's px
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
	clip_contents = false                  # the frame clips (BUILD52): a frame bigger than the land shows the key on its corner
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL         # a pad or the keys step the pins (the zone tabs were buttons: the Deck's d-pad got there)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST     # the painting's pixels whole at x2; the words below set back to smooth
	# the sky over the painting (23 Oct, parked item 8), the pins on a layer over it so they keep their colour
	_sky_clip = Control.new()              # the weather over the land in the view, not the room round it (BUILD52)
	_sky_clip.clip_contents = true
	_sky_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sky_clip)
	_sky = SkyLayer.new(Vector2(Pal.GRID_W, Pal.ROOM_H))     # the weather over the view, not the land: it stays as the land pans (BUILD51-U)
	_sky_clip.add_child(_sky)
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
		mat.set_shader_parameter("warp_px", CLOUD_WARP * land_k())
		mat.set_shader_parameter("land_k", land_k())
		_clouds.material = mat
		add_child(_clouds)
	_key_layer = Control.new()             # the key on the view's corner, over the cloud: it stays as the land pans (BUILD51-U)
	_key_layer.size = size
	_key_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_key_bg = Control.new()
	_key_bg.size = size
	_key_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_key_bg.draw.connect(_draw_key)
	_key_layer.add_child(_key_bg)
	for z in range(Data.ZONES.size()):
		var at: Vector2 = zone_name_pin(z)
		var room: float = minf(320.0, size.x - at.x - 8.0)
		var nm := UI.label(self, Rect2(at.x, at.y, room, 32), str(Data.ZONES[z]["name"]), "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var st := UI.label(self, Rect2(at.x, at.y + 32, room, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		UI.shadow(nm)
		UI.shadow(st)
		_zone_names.append([nm, st])
	for i in range(Data.TIERS.size()):
		var l := _pin_label(pin_at(i), int(SITE_LABEL[i]), Pal.TEXT)
		_pin_labels.append(l)
	for k in ORDER_AT:
		_order_labels[k] = _pin_label(order_pin_at(k), int(ORDER_LABEL[k]), Pal.ACCENT)
	for k in TOWN_AT:
		_town_labels[k] = _pin_label(town_pin_at(k), BELOW, Pal.TEXT_2)
		_town_labels[k].add_theme_font_size_override("font_size", Pal.CELL_TEXT - 2)
		_town_labels[k].visible = false
	# the key, bottom right: what a pin's colour says - a dot and its word, packed tight (19 Oct, Matt: "too big ... too
	# spread out")
	var items := [["Safe", Pal.GOOD, false], ["Risky", Pal.WARN, false], ["A bad idea", Pal.BAD, false], [Words.MAP_OLD_READ, old_tone(1.0), false], ["Locked", Pal.TEXT_3, true]]     # a last read since moved (BUILD48 A, item 3)
	var widths: Array = []
	var total := KEY_PAD
	for e in items:
		var l := UI.label(_key_layer, Rect2(0, 0, 10, KEY_H), str(e[0]), "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2 if e[2] else Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var w: float = ceilf(UI.text_width(l, l.text)) + 2.0
		l.size.x = w
		widths.append(w)
		_legend.append([l, e[1], e[2]])
		total += KEY_DOT + 6.0 + w + KEY_GAP
	total += KEY_PAD - KEY_GAP
	_key_w = total
	_key_widths = widths
	add_child(_key_layer)
	for c in get_children():
		if c is CanvasItem:
			c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pan = MapPan.new(self, size)
	pan.moved = _panned
	_placer = preload("res://scripts/ui/map_placement.gd").new()     # F3/F5 (BUILD52), debug builds
	_placer.view = self
	_placer.size = size
	add_child(_placer)
	_lay_key()


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
	(_clouds.material as ShaderMaterial).set_shader_parameter("mask", ImageTexture.create_from_image(soft_mask(cloud_mask(key, size / land_k()))))     # cut at today's map's size: read by UV, the same cloud (BUILD51-U)


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
			polys.append(zone_points(z))
	var to_paint: Vector2 = paint_size() / map_size      # a cell's middle in the painting's pixels (BUILD52)
	for y in range(h):
		for x in range(w):
			var p := Vector2((x + 0.5) * MASK_DIV, (y + 0.5) * MASK_DIV) * to_paint
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
	var l := UI.label(self, Rect2(0, 0, LABEL_W, LABEL_H), "", "SemiBold", Pal.CELL_TEXT, col, HORIZONTAL_ALIGNMENT_CENTER, false)
	UI.shadow(l)
	_lay_label(l, p, side)
	return l


## A pin's name's box at its pin (BUILD52: again when the F3 tool moves the pin).
func _lay_label(l: Label, p: Vector2, side: int) -> void:
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
	l.position = r.position
	l.size = r.size
	l.horizontal_alignment = align
	_label_at[l] = [p, side]
	_snug(l)


## A pin's name hugging its own pin (19 Oct, Matt: the Allotments' name drifted off its dot): above or below, its box the
## word's own width centred on the pin, kept inside the map; left or right as laid.
func _snug(l: Label) -> void:
	var at: Array = _label_at.get(l, [])
	if at.is_empty() or not (int(at[1]) == BELOW or int(at[1]) == ABOVE):
		return
	var w: float = ceilf(UI.text_width(l, l.text)) + 4.0
	l.size.x = w
	l.position.x = clampf(at[0].x - w / 2.0, 4.0, size.x - 4.0 - w)


## A point of the painting's pixels on the land.
func _px(p: Vector2) -> Vector2:
	return p * PX


## The pin's tone: the odds as read, grey while they're read, hollow when shut. A pin not read now shows its last read
## (BUILD48 A, parked item 3: the Map reads the picked place alone) - in its colour while it's current, dimmed (OLD_DIM of
## the way to the grey) once the kit, the level or the HP has moved since; grey with none.
const OLD_DIM := 0.6
func _tone(i: int) -> Color:
	if not sim.tier_open(i):
		return Pal.CARD_LINE
	if sim.odds_ready(i):
		return odds_tone(sim.odds_now(i))
	var last: Array = sim.odds_last(i)
	if last.is_empty():
		return Pal.TEXT_3
	return odds_tone(float(last[0])) if bool(last[1]) else old_tone(float(last[0]))


static func odds_tone(o: float) -> Color:
	return Pal.GOOD if o >= 0.9 else (Pal.WARN if o >= 0.6 else Pal.BAD)


## A last read kept since the runner moved: its colour, dimmed toward the grey.
static func old_tone(o: float) -> Color:
	return odds_tone(o).lerp(Pal.TEXT_3, OLD_DIM)


## The pins' tones as drawn (the smoke reads them): worked in show_state, where the paint's odds scope holds the key.
var tones: Array = []


func show_state(s, sel: int, okey: String) -> void:
	sim = s
	selected = sel
	order_key = okey
	var settled := ""
	tones = []
	for i in range(Data.TIERS.size()):
		tones.append(_tone(i))
		settled += "%d%d%d%s" % [int(sim.tier_open(i)), int(sim.odds_ready(i)), roundi(sim.odds_now(i) * 100.0), tones[i].to_html()]
	var opens := ""
	for p in Data.PINNACLES:
		opens += "1" if sim.order_open(p["key"]) else "0"
	var sig := "%s|%d|%s|%s|%s|%s|%s|%d|%d" % [settled, selected, order_key, opens, str(sim.best_depth), str(sim.bosses_beaten), str(sim.weather), sim.level(), int(sim.is_night())]
	sig += "|" + _town_show()                  # the town's places (BUILD50-T)
	sig += "|%d" % int(placing)                # the F3 tool: the fog off and every name plain while placing (BUILD53, Matt: "the fog is preventing me from placing")
	if sig == _shown:
		return
	_shown = sig
	_cut_clouds()
	_sky.set_sky(sim.is_night(), sim.weather_of(selected) if selected >= 0 else "")     # the picked site's zone's sky, as its card says (23 Oct)
	for z in range(Data.ZONES.size()):
		var nm: Label = _zone_names[z][0]
		var st: Label = _zone_names[z][1]
		var open_z: bool = sim.zone_open(z) or placing     # placing: every zone as known (BUILD53)
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
		var known: bool = sim.zone_open(z) or placing     # placing: every name plain (BUILD53)
		l.visible = true
		l.text = str(Data.TIERS[i]["name"]) if known else Fmt.scramble(str(Data.TIERS[i]["name"]))     # the name only (19 Oct); scrambled till its zone's open (20 Oct)
		_snug(l)
		var picked_now: bool = i == selected and order_key == ""
		l.add_theme_color_override("font_color", Pal.ACCENT if picked_now else (Pal.TEXT if sim.tier_open(i) else (Pal.TEXT_2 if known else Pal.TEXT_3)))
	for p in Data.PINNACLES:
		var l: Label = _order_labels[p["key"]]
		l.visible = sim.order_open(p["key"]) or placing     # placing: every place named (BUILD53)
		if l.visible:
			var ok: bool = sim.order_known(p["key"]) or placing
			l.text = str(p["place"]) if ok else Fmt.scramble(str(p["place"]))     # scrambled till its zone's open (20 Oct)
			_snug(l)
			l.add_theme_color_override("font_color", Pal.ACCENT if order_key == p["key"] else (Pal.TEXT if ok else Pal.TEXT_3))
	queue_redraw()
	_pins.queue_redraw()


func _draw() -> void:
	var pic := painting()
	if pic != null:
		draw_texture_rect(pic, painting_rect(), false)
	else:
		_draw_flat()
	# the picked site's zone, lit: its shape washed warm (its yellow outline gone, 23 Oct, Matt: "the yellow boundaries
	# just read wrong")
	var lit_z := lit_zone()
	if lit_z >= 0 and sim != null and sim.zone_open(lit_z):
		draw_colored_polygon(_scaled(zone_points(lit_z)), LIT)
	# a shut zone under a hatch, where there's no cloud
	for z in range(Data.ZONES.size()):
		if _clouds == null and sim != null and not sim.zone_open(z) and not placing:     # placing: no hatch (BUILD53)
			_hatch(zone_points(z))
	# the pins: their own layer (_draw_pins), over the sky
	# the key's panel and its dots: their own layer (_draw_key), over the cloud


## The pins, on their own layer over the sky (23 Oct): the sites in their odds' colour, the order's places as diamonds.
func _draw_pins() -> void:
	if sim == null:
		return
	for i in range(Data.TIERS.size()):
		var c: Vector2 = pin_at(i)
		var open: bool = sim.tier_open(i)
		var zone_open: bool = sim.zone_open(int(Data.TIERS[i]["zone"]))
		var r: float = PIN_R if zone_open else PIN_R_SHUT
		if i == selected and order_key == "":
			_pins.draw_circle(c, r + 9.0, Color(Pal.ACCENT, 0.25))
			_pins.draw_circle(c, r + 5.0, Pal.ACCENT)
		_pins.draw_circle(c, r + 3.0, Pal.BG)
		if open:
			_pins.draw_circle(c, r, tones[i] if i < tones.size() else _tone(i))
		else:
			_pins.draw_circle(c, r, Pal.BUTTON)
			_pins.draw_arc(c, r, 0.0, TAU, 24, Pal.TEXT_3 if zone_open else Color("5a6068"), 2.0)
	for p in Data.PINNACLES:
		if not sim.order_open(p["key"]) and not placing:     # the F3 tool shows every place (BUILD52)
			continue
		var c: Vector2 = order_pin_at(p["key"])
		if order_key == p["key"]:
			_pins.draw_circle(c, PIN_R + 9.0, Color(Pal.ACCENT, 0.25))
		var d := PIN_R + 3.0                 # a diamond: the order's places aren't the campaign's
		_pins.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d - 3), c + Vector2(d + 3, 0), c + Vector2(0, d + 3), c + Vector2(-d - 3, 0)]), Pal.BG)
		_pins.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0), c + Vector2(0, d), c + Vector2(-d, 0)]), Pal.ACCENT)
	_draw_town()


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
		var pts := _scaled(zone_points(z))
		draw_colored_polygon(pts, ZONE_SHAPES[z]["fill"])
		pts.append(pts[0])
		draw_polyline(pts, Pal.CARD_LINE, 2.0)
	_curve([Vector2(560, 0), Vector2(620, 160), Vector2(610, 300), Vector2(690, 470), Vector2(800, 640), Vector2(1000, 800)], Color("26394b"), 16.0)
	_curve([Vector2(0, 120), Vector2(300, 100), Vector2(560, 100), Vector2(720, 140), Vector2(1000, 150)], Color("3d4249"), 11.0)


## The zone lit: the picked site's, or the picked order place's host site's; -1 for none.
func lit_zone() -> int:
	if order_key != "":
		return order_zone(order_key)
	if selected >= 0 and selected < Data.TIERS.size():
		return int(Data.TIERS[selected]["zone"])
	return -1


## The zone an order's place lights: the one its diamond sits in on the painting (Matt placed the Grid and the Mint by
## the ring road, BUILD54), else its own zone in the data.
func order_zone(key: String) -> int:
	var at: Vector2 = order_pin_at(key) / PX
	for z in range(Data.ZONES.size()):
		if Geometry2D.is_point_in_polygon(at, zone_points(z)):
			return z
	return int(Data.pinnacle(key).get("zone", -1))


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
			out.append(_catmull(a0, a, b, b1, t) * size / OLD_SPACE)
	out.append(pts.back() * size / OLD_SPACE)
	draw_polyline(out, col, w * size.x / OLD_SPACE.x, true)


static func _catmull(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


## Diagonal strokes over a zone, clipped to its shape by stepping along each stroke.
func _hatch(points: PackedVector2Array) -> void:
	var poly := PackedVector2Array()
	for p in points:
		poly.append(p)
	draw_colored_polygon(_scaled(poly), Color(0, 0, 0, 0.35))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	var step := 9.0                         # in the painting's pixels: 18 on the screen
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
				reveal(pin_at(to))
				accept_event()
			return
	# the pan (BUILD51-U, item 2): a drag or the wheel moves the land; a click with no pin under it, let go where it was
	# pressed, puts the side panel away
	var act: String = pan.input(ev)
	if act == "pan":
		accept_event()
		return
	if act == "click":
		if not _press_hit:
			empty_clicked.emit()
		accept_event()
		return
	if act != "press":
		return
	_press_hit = false
	var at: Vector2 = ev.position
	var best := HIT_R
	var hit_i := -1
	var hit_k := ""
	for i in range(Data.TIERS.size()):
		if not sim.zone_open(int(Data.TIERS[i]["zone"])):
			continue
		var d: float = at.distance_to(pin_at(i))
		if d < best:
			best = d
			hit_i = i
	var hit_t := ""
	for k in town_states:
		var dt: float = at.distance_to(town_pin_at(k))
		if dt < best:
			best = dt
			hit_t = str(k)
			hit_i = -1
	for p in Data.PINNACLES:
		if sim.order_known(p["key"]):          # a place in a shut zone doesn't pick, as its pins don't (20 Oct)
			var d: float = at.distance_to(order_pin_at(p["key"]))
			if d < best:
				best = d
				hit_k = p["key"]
				hit_i = -1
				hit_t = ""
	_press_hit = hit_t != "" or hit_k != "" or hit_i >= 0
	if hit_t != "" and hit_k == "":
		picked_town.emit(hit_t)
		accept_event()
	elif hit_k != "":
		picked_order.emit(hit_k)
		accept_event()
	elif hit_i >= 0:
		picked.emit(hit_i)
		accept_event()
	else:
		accept_event()                         # the land's: a drag may follow


## The next site along (1) or back (-1) from the picked one among the open zones' sites, round the end; -1 for none.
func step_site(by: int) -> int:
	var sites: Array = range(Data.TIERS.size()).filter(func(i): return sim.zone_open(int(Data.TIERS[i]["zone"])))
	if sites.is_empty():
		return -1
	var at: int = sites.find(selected)
	return int(sites[posmod((at if at >= 0 else 0) + by, sites.size())])


## Where a site's pin is, on the control (for the tests' clicks): its point from data/map_places.tres (BUILD52).
func pin_at(i: int) -> Vector2:
	return _px(place_of("sites", site_key(i)))


func order_pin_at(key: String) -> Vector2:
	return _px(place_of("order", key))


## The names on the screen: those whose words sit wholly in the view (BUILD51-U: the land's others are panned off it, or
## cut by its edge); land_nodes() for every one on the land.
func text_nodes() -> Array:
	var vr := Rect2(pan.offset(), pan.view)
	var kr := Rect2(_key_rect.position + pan.offset(), _key_rect.size)     # the key over the land: a name under it is under it
	return land_nodes().filter(func(l): return l.text == "" or (vr.encloses(word_rect(l)) and not kr.intersects(word_rect(l))))


func land_nodes() -> Array:
	var out: Array = []
	for pair in _zone_names:
		out.append_array(pair)
	for l in _pin_labels:
		if l.visible:
			out.append(l)
	for k in _order_labels:
		if _order_labels[k].visible:
			out.append(_order_labels[k])
	for k in _town_labels:
		if _town_labels[k].visible:
			out.append(_town_labels[k])
	return out


## A name's words on the land, at its alignment.
static func word_rect(l: Label) -> Rect2:
	var w: float = UI.text_width(l, l.text)
	var x: float = l.position.x + ((l.size.x - w) / 2.0 if l.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER else (l.size.x - w if l.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT else 0.0))
	return Rect2(x, l.position.y, w, l.size.y)


## The key's words (BUILD51-U): on the view, not the land - the screen's fit checks read them with the Map's.
func key_nodes() -> Array:
	return _legend.map(func(e): return e[0])


# ------------------------------------------------------------------ the town on the Map (BUILD50-T, act two §1)

## Each place's state and its name under its pin; the signature for show_state's redraw.
func _town_show() -> String:
	town_states = {}
	var open: bool = sim.rebuild_open()
	var nk: String = sim.town_next_key()
	for r in Data.REBUILDS:
		var k: String = str(r["key"])
		var l: Label = _town_labels[k]
		l.visible = open
		if not open:
			continue
		var st: String = "running" if sim.town_on(k) else ("stopped" if sim.rebuild_rank(k) > 0 else ("next" if k == nk else "ringed"))
		town_states[k] = st
		l.text = str(r["name"])
		_snug(l)
		l.add_theme_color_override("font_color", {"running": TOWN_LIT, "stopped": Pal.BAD, "next": TOWN_LIT, "ringed": Pal.TEXT_2}[st])
	return str(town_states)


## The places' squares, on the pins' layer: a glow and a lit square running; red-ringed and dark stopped; a dashed ring
## the next step; a plain ring not yet built.
func _draw_town() -> void:
	var drawn: Dictionary = town_states
	if placing:                             # the F3 tool shows every place, built or not (BUILD52)
		drawn = {}
		for k in TOWN_AT:
			drawn[k] = town_states.get(k, "ringed")
	for k in drawn:
		var c: Vector2 = town_pin_at(k)
		var r := TOWN_R
		var box := Rect2(c - Vector2(r, r), Vector2(2 * r, 2 * r))
		match str(drawn[k]):
			"running":
				_pins.draw_circle(c, r + 12.0, Color(Pal.ACCENT, 0.16))
				_pins.draw_circle(c, r + 7.0, Color(Pal.ACCENT, 0.3))
				_pins.draw_rect(box.grow(3.0), Pal.BG)
				_pins.draw_rect(box, Pal.ACCENT)
			"stopped":
				_pins.draw_rect(box.grow(3.0), Pal.BG)
				_pins.draw_rect(box, Pal.BUTTON)
				_pins.draw_rect(box, Pal.BAD, false, 2.5)
			"next":
				_pins.draw_rect(box.grow(3.0), Color(Pal.BG, 0.7))
				var pts: Array = [box.position, box.position + Vector2(2 * r, 0), box.end, box.position + Vector2(0, 2 * r), box.position]
				for e in range(4):
					var a: Vector2 = pts[e]
					var b: Vector2 = pts[e + 1]
					for q in range(3):               # three dashes a side
						_pins.draw_line(a.lerp(b, q / 3.0 + 0.04), a.lerp(b, q / 3.0 + 0.24), Pal.ACCENT, 2.5)
			_:
				_pins.draw_rect(box.grow(3.0), Color(Pal.BG, 0.7))
				_pins.draw_rect(box, Pal.TEXT_3, false, 2.0)


## A place's pin's words on the hover: its name and state, what it does, what came back with it (or what it wants).
func town_tip(k: String) -> String:
	var r: Dictionary = Data.rebuild(k)
	var st: String = str(town_states.get(k, ""))
	var w: String = Fmt.money(sim.town_wage(k))
	var lines: Array = []
	match st:
		"running":
			lines.append("%s · %s" % [r["name"], Words.T50_TOWN["running"] % w])
		"stopped":
			lines.append("%s · %s" % [r["name"], Words.T50_TOWN["stopped_day"] % w])
		"next":
			lines.append("%s · %s" % [r["name"], Words.T50_TOWN["next"]])
		_:
			lines.append("%s · %s" % [r["name"], Words.T50_TOWN["not_yet"]])
	var fx: Array = sim.rebuild_words(k, maxi(1, sim.rebuild_rank(k)))
	if not fx.is_empty():
		lines.append(" · ".join(fx))
	if st == "running" or st == "stopped":
		lines.append(str(Words.T50_TOWN["back"][k]))
	return "\n".join(lines)


func _get_tooltip(at: Vector2) -> String:
	if sim == null:
		return ""
	for k in town_states:
		if at.distance_to(town_pin_at(k)) < HIT_R:
			return town_tip(str(k))
	return ""


## Where a town's place's pin is, on the control (for the tests).
func town_pin_at(key: String) -> Vector2:
	return _px(place_of("town", key))


# ------------------------------------------------------------------ the land and its pan (BUILD51-U, item 2)

var pan                                 # map_pan.gd: the land in its frame
var _key_layer: Control                 # the key, kept on the view's bottom right
var _key_w := 0.0
var _key_widths: Array = []
var _press_hit := false                 # the last press picked a pin (its let-go isn't the empty land's)


## The land over the cloud's own scale (its tile and its warp were set for a painting drawn x2): 1 at PX 2 (BUILD52).
func land_k() -> float:
	return PX / 2.0


## The painting's place on the land: the whole land, its pixels PX times (BUILD52).
func painting_rect() -> Rect2:
	return Rect2(Vector2.ZERO, paint_size() * PX)


## The frame's size (the side panel on: the map's two columns; off: the whole width): the view clamped, the key and the
## weather to its corner.
func set_view(v: Vector2) -> void:
	pan.set_view(v)
	_lay_key()


## After a pan: what stays on the view goes with it.
func _panned() -> void:
	var off: Vector2 = pan.offset()
	_key_layer.position = off
	var seen := Rect2(off, pan.view).intersection(Rect2(Vector2.ZERO, size))     # the land in the view: the sky over that alone (BUILD52)
	_sky_clip.position = seen.position
	_sky_clip.size = seen.size
	_sky.position = off - seen.position
	if _placer != null:
		_placer.queue_redraw()                 # the F3 tool's line on the view's top


func _lay_key() -> void:
	var v: Vector2 = pan.view
	_key_layer.size = v
	_key_bg.size = v
	_key_rect = Rect2(v.x - _key_w - 12.0, v.y - KEY_H - 12.0, _key_w, KEY_H)
	var kx: float = _key_rect.position.x + KEY_PAD
	for k in range(_legend.size()):
		var l: Label = _legend[k][0]
		l.position = Vector2(kx + KEY_DOT + 6.0, _key_rect.position.y)
		kx += KEY_DOT + 6.0 + float(_key_widths[k]) + KEY_GAP
	_key_bg.queue_redraw()
	_panned()


## The view centred on a land point (the Map opening on its step).
func centre_on(p: Vector2) -> void:
	pan.centre_on(p)


## A pin brought into the view if it's off it (a pad's step), else the view left where it is.
func reveal(p: Vector2) -> void:
	if not pan.shows(p, 60.0):
		pan.centre_on(p)


## Where the Map opens: the picked place when the player's picked one (`sel` a site, `okey` an order's place), else the
## town's next step's pin while the rebuild's open, else the site the card shows.
func open_at(s, sel: int, okey: String, by_hand: bool) -> Vector2:
	if by_hand and okey != "":
		return order_pin_at(okey)
	if by_hand and sel >= 0:
		return pin_at(sel)
	var nk: String = str(s.town_next_key()) if s.rebuild_open() else ""
	if TOWN_AT.has(nk):
		return town_pin_at(nk)
	return pin_at(maxi(0, sel))



# ------------------------------------------------------------------ the places from data (BUILD52)

## Matt: "can you do an f3/f5 piece for the places? some of the ones you've selected I'd want to move". Every pin's point
## and every zone's name point and shape: data/map_places.tres (map_places.gd) where it has an entry, the tables above
## where it hasn't; points in the painting's pixels, the file's rescaled from the size it was placed on.
const PLACES_FILE := "res://data/map_places.tres"
static var places_file: String = PLACES_FILE     # the tests point it at a fixture
static var _places = null                        # {kind: {key: point}} in this painting's pixels, read once


## The painting's size in its own pixels (the land is this x PX); the fallback's with no painting.
static func paint_size() -> Vector2:
	var pic := painting()
	return pic.get_size() if pic != null else PAINT_FALLBACK


## The land's size on the screen: the painting's x PX.
static func land_size() -> Vector2:
	return paint_size() * PX


## A site's key in the file: its name's slug (the_allotments), as the fight's slots.
static func site_key(i: int) -> String:
	return Items.slug(str(Data.TIERS[i]["name"]))


static func zone_key(z: int) -> String:
	return Items.slug(str(Data.ZONES[z]["name"]))


## What the file holds, read once (again after use_places / forget_places): kind -> key -> point, rescaled to this
## painting; "zones" -> key -> PackedVector2Array.
static func places() -> Dictionary:
	if _places == null:
		_places = {}
		if ResourceLoader.exists(places_file):
			var r = ResourceLoader.load(places_file, "", ResourceLoader.CACHE_MODE_IGNORE)
			if r != null and r.get("sites") is Dictionary:
				use_places(r)
	return _places


## A map_places.gd's points taken as the Map's from now on (F5's save, a fresh read).
static func use_places(r) -> void:
	_places = {}
	var from: Vector2 = r.paint_size if r.paint_size.x > 0.0 and r.paint_size.y > 0.0 else paint_size()
	var k: Vector2 = paint_size() / from
	for kind in ["sites", "order", "town", "zone_names"]:
		var d: Dictionary = {}
		var src: Dictionary = r.get(kind)
		for key in src:
			if src[key] is Vector2:
				d[str(key)] = src[key] * k
		_places[kind] = d
	var zs: Dictionary = {}
	for key in r.zones:
		var pts := PackedVector2Array()
		for p in PackedVector2Array(r.zones[key]):
			pts.append(p * k)
		if pts.size() >= 3:
			zs[str(key)] = pts
	_places["zones"] = zs


## The next places() reads the file again.
static func forget_places() -> void:
	_places = null


## A place's point in the painting's pixels, from the file, else the tables: kind "sites" (a site's key), "order",
## "town", "zone_names" (a zone's key).
static func placed(kind: String, key: String) -> Vector2:
	var d: Dictionary = places().get(kind, {})
	if d.has(key):
		return d[key]
	match kind:
		"sites":
			for i in range(Data.TIERS.size()):
				if site_key(i) == key:
					return SITE_AT[i]
		"order":
			return ORDER_AT.get(key, Vector2.ZERO)
		"town":
			return TOWN_AT.get(key, Vector2.ZERO)
		"zone_names":
			for z in range(Data.ZONES.size()):
				if zone_key(z) == key:
					return ZONE_SHAPES[z]["name_at"]
	return Vector2.ZERO


## A zone's shape in the painting's pixels: the file's, else the table's.
static func zone_points(z: int) -> PackedVector2Array:
	var d: Dictionary = places().get("zones", {})
	if d.has(zone_key(z)):
		return d[zone_key(z)]
	return PackedVector2Array(ZONE_SHAPES[z]["points"])


## A place's point as it is now: the F3 tool's while placing, else placed().
func place_of(kind: String, key: String) -> Vector2:
	if placing and _edit.has(kind) and _edit[kind].has(key):
		return _edit[kind][key]
	return placed(kind, key)


## A zone's name's top left on the land.
func zone_name_pin(z: int) -> Vector2:
	return _px(place_of("zone_names", zone_key(z)))


## Every place the F3 tool moves: [kind, key, its name on the tool].
func all_places() -> Array:
	var out: Array = []
	for i in range(Data.TIERS.size()):
		out.append(["sites", site_key(i), str(Data.TIERS[i]["name"])])
	for p in Data.PINNACLES:
		out.append(["order", str(p["key"]), str(p["place"])])
	for r in Data.REBUILDS:
		out.append(["town", str(r["key"]), str(r["name"])])
	for z in range(Data.ZONES.size()):
		out.append(["zone_names", zone_key(z), str(Data.ZONES[z]["name"])])
	return out


# ------------------------------------------------------------------ the placement tool (F3, debug builds; BUILD52)

var placing := false                    # F3's on: every place shown and draggable
var top_clear := Callable()             # the frame's first y clear of what the room lays over the Map (missions.gd: the goal line)
var _edit: Dictionary = {}              # kind -> key -> point, as they're being dragged
var _placer: Control                    # map_placement.gd


## Whether F3 can start here: a debug build (the tool's gate, as the fight's), the Map up (not the County), a game on it.
func can_place() -> bool:
	return _placer != null and _placer.in_debug and on_screen() and sim != null


## The Map's showing: it and every room it's in visible (as the run view's _shown).
func on_screen() -> bool:
	var n: Node = self
	while n is CanvasItem:
		if not (n as CanvasItem).visible:
			return false
		n = n.get_parent()
	return true


func set_placing(on: bool) -> void:
	placing = on
	if _clouds != null:
		_clouds.visible = not on            # the fog off while placing, back after (BUILD53)
	_edit = {}
	if on:
		for e in all_places():
			if not _edit.has(e[0]):
				_edit[e[0]] = {}
			_edit[e[0]][e[1]] = placed(e[0], e[1])
	relay()
	if sim != null:
		_shown = ""
		show_state(sim, selected, order_key)     # the names plain or scrambled at once, not on the next refresh (BUILD53, the review)


## A place moved (painting pixels, kept on the painting).
func set_place(kind: String, key: String, p: Vector2) -> void:
	if not (placing and _edit.has(kind)):
		return
	_edit[kind][key] = p.clamp(Vector2.ZERO, paint_size())
	relay()


## Every name back on its pin, the pins redrawn: after a move, a save, F3 on or off.
func relay() -> void:
	for i in range(_pin_labels.size()):
		_lay_label(_pin_labels[i], pin_at(i), int(SITE_LABEL[i]))
	for k in _order_labels:
		_lay_label(_order_labels[k], order_pin_at(k), int(ORDER_LABEL[k]))
	for k in _town_labels:
		_lay_label(_town_labels[k], town_pin_at(k), BELOW)
	for z in range(_zone_names.size()):
		var at: Vector2 = zone_name_pin(z)
		var room: float = minf(320.0, size.x - at.x - 8.0)
		_zone_names[z][0].position = at
		_zone_names[z][0].size.x = room
		_zone_names[z][1].position = at + Vector2(0, 32)
		_zone_names[z][1].size.x = room
	queue_redraw()
	_pins.queue_redraw()
	if _placer != null:
		_placer.queue_redraw()
