extends Control
## The County on the Map (26 Oct, the drawn map on Matt's painting, art/map/county.png): its four zones traced, a pin a
## place in its odds' colour, a head's place a diamond; a shut zone dark and hatched, its names scrambled; the picked
## place's zone lit. Without the painting, the zones drawn flat.
##
## BUILD61-U (6 Nov, docs/design/county_stages.md §6): the campaign's treatment. The picked place's card is the Map's site
## card (missions.gd shows it in the right third, site_card.gd's show_county: the picture, the stage picker, "Head" on a
## zone's last place, Set off and "Run it ×N"); the County's own card is gone. The pins say "· 2/3", the done colour at
## 3/3, "· New" breathing (map_view.gd's marks, shared). The painting is drawn x2 from its top left, its size read from
## the texture (today's 512 x 424 till Matt's 688 x 384 lands), the land panned and centred as the Map's. The places,
## the zones' names and shapes come from data/county_places.tres (map_places.gd's schema, in the painting's pixels,
## rescaled if the painting's size changes), this file's tables the fallback; F3/F5/F4 move and save them
## (map_placement.gd, debug builds only), the hatch off and every name plain while placing.
##
## Signals: `picked(k)` a place picked (its card), `card_changed` the card on or off.

signal picked(k: String)
signal card_changed

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const Sim := preload("res://scripts/sim/sim.gd")
const Items := preload("res://scripts/sim/items.gd")
const MapPan := preload("res://scripts/ui/map_pan.gd")
const MapViewRef := preload("res://scripts/ui/map_view.gd")
const MapPlacement := preload("res://scripts/ui/map_placement.gd")

const PX := 2.0                              # a painting's pixel on the screen, as the Map's (BUILD61-U)
const OLD_PAINT := Vector2(512, 424)         # the tables below are in today's painting's pixels: rescaled to another's
const PAINT_FALLBACK := Vector2(512, 424)    # the land's painting size with no painting (the flat drawing stands in)

const COL_GAP := 16
@warning_ignore("integer_division")
const COL_W := (Pal.GRID_W - 2 * COL_GAP) / 3
const MAP_W := 2 * COL_W + COL_GAP
const PIN_R := 12.0
const PIN_R_SHUT := 7.0
const HIT_R := 30.0
const LABEL_W := 260.0
const LABEL_H := 24.0
const PAINTING := "res://art/map/county.png"
const LIT := Color(1.0, 0.86, 0.6, 0.08)

## The fallback (data/county_places.tres rules), in today's painting's 512 x 424, in Data.COUNTY_ZONES' order: the
## Motorway along the top, the Docks down the right, the Big Houses the country west and south, the Treasury the town.
const ZONE_SHAPES := [
	[Vector2(0, 0), Vector2(512, 0), Vector2(512, 92), Vector2(410, 92), Vector2(165, 100), Vector2(0, 92)],
	[Vector2(410, 92), Vector2(512, 92), Vector2(512, 424), Vector2(330, 424), Vector2(345, 305), Vector2(360, 305), Vector2(400, 250)],
	[Vector2(0, 92), Vector2(165, 100), Vector2(165, 305), Vector2(345, 305), Vector2(330, 424), Vector2(0, 424)],
	[Vector2(165, 100), Vector2(410, 92), Vector2(400, 250), Vector2(360, 305), Vector2(165, 305)],
]
const ZONE_NAME_AT := [Vector2(176, 6), Vector2(420, 396), Vector2(6, 104), Vector2(170, 240)]     # the Docks' in from the edge: the F3 tool grabs it (BUILD61-U)
## A place's pin, in the painting's space, and where its name sits (the side stays here; the point is the file's).
enum { BELOW, ABOVE, RIGHT, LEFT }
const PLACE_AT := {
	"toll_plaza": [Vector2(62, 42), BELOW], "distribution": [Vector2(264, 30), BELOW], "truck_stop": [Vector2(405, 32), BELOW],
	"container_port": [Vector2(440, 210), LEFT], "ferry_terminal": [Vector2(462, 270), BELOW], "customs_shed": [Vector2(400, 335), LEFT],
	"golf_club": [Vector2(90, 205), BELOW], "gated_close": [Vector2(120, 290), RIGHT], "manor": [Vector2(36, 372), RIGHT],
	"counting_house": [Vector2(300, 130), ABOVE], "bullion_vault": [Vector2(365, 150), BELOW], "treasury": [Vector2(340, 212), LEFT],
}

var sim
var selected := ""
var _map: Control
var _pins: Control
var _pin_labels := {}               # key -> Label
var _pin_marks := {}                # key -> its "New" (BUILD61-U): a Label on its pin's label, amber, breathing
var _zone_labels: Array = []        # a Label a zone
var _shown := ""
var _key: Panel                     # the map's key strip, bottom left
var _shut: Panel                    # a shut zone's card where it was clicked
var _shut_lines: Array = []
var _shut_zone := -1
var pulse_t := 0.0                  # the "New" marks' breath (map_view.gd's)
static var _painting = null
static var _painting_read := false


func _init(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE     # the card's column under it takes its own clicks (BUILD61-U)
	_frame = Control.new()                   # the land's frame (BUILD51-U): the sheet's two columns, the width with the card off
	_frame.size = Vector2(MAP_W, rect.size.y)
	_frame.clip_contents = true
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_map = Control.new()
	_map.position = Vector2.ZERO
	_map.size = land_size()                  # the painting's size x2 (BUILD61-U)
	_map.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST     # the painting's pixels whole
	_map.draw.connect(_draw_map)
	_map.gui_input.connect(_map_input)
	_frame.add_child(_map)
	pan = MapPan.new(_map, _frame.size)
	_pins = Control.new()
	_pins.size = _map.size
	_pins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pins.draw.connect(_draw_pins)
	_map.add_child(_pins)
	for z in range(Data.COUNTY_ZONES.size()):
		var l := UI.label(_map, Rect2(0, 0, 300, 30), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		UI.shadow(l)
		_zone_labels.append(l)
	for c in Data.COUNTY:
		var k: String = str(c["key"])
		var l := UI.label(_map, Rect2(0, 0, LABEL_W, LABEL_H), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
		UI.shadow(l)
		_pin_labels[k] = l
		var mk := UI.label(l, Rect2(0, 0, 60, LABEL_H), Words.U55["new"], "SemiBold", Pal.CELL_TEXT, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
		UI.shadow(mk)
		mk.visible = false
		_pin_marks[k] = mk
	_build_key()
	for c in _map.get_children():
		if c is CanvasItem:
			c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR     # the words smooth (BUILD51-U)
	_shut = UI.panel(_map, Rect2(0, 0, 430, 130), UI.box(Color(Pal.BG, 0.95), 8, 2, Pal.CARD_LINE))
	_shut.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shut.visible = false
	_shut_lines.append(UI.label(_shut, Rect2(16, 12, 398, 20), Words.COUNTY["shut_kicker"], "SemiBold", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false))
	_shut_lines.append(UI.label(_shut, Rect2(16, 34, 398, 32), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))
	for n in range(2):
		_shut_lines.append(UI.label(_shut, Rect2(16, 70 + n * 24, 398, 24), "", "Regular", Pal.CELL_TEXT + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))
	_placer = MapPlacement.new()             # F3/F5 on the County (BUILD61-U): the Map's tool, on this land and this file
	_placer.view = self
	_placer.save_path = PLACES_FILE
	_map.add_child(_placer)
	relay()
	set_process(false)


## The key strip (the canvas 'The County board', A): the pins' colours, shut and taken, bottom left of the map.
func _build_key() -> void:
	_key = UI.panel(_frame, Rect2(12, size.y - 50, 10, 38), UI.box(Color("0f1214", 0.86), 6))     # on the frame: it stays as the land pans (BUILD51-U)
	_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var x := 14.0
	for e in [["safe", Pal.GOOD], ["risky", Pal.WARN], ["bad", Pal.BAD], ["shut", Color.TRANSPARENT], ["taken", Pal.GOOD]]:
		var dot := Control.new()
		dot.position = Vector2(x, 12)
		dot.size = Vector2(15, 15)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var kind: String = e[0]
		var col: Color = e[1]
		dot.draw.connect(func():
			if kind == "shut":
				dot.draw_arc(Vector2(7.5, 7.5), 5.5, 0.0, TAU, 20, Pal.TEXT_3, 2.0)
			else:
				dot.draw_circle(Vector2(7.5, 7.5), 6.5 if kind != "taken" else 7.5, col)
				if kind == "taken":
					_tick(dot, Vector2(7.5, 7.5), 7.5))
		_key.add_child(dot)
		x += 22
		var l := UI.label(_key, Rect2(x, 7, 200, 24), Words.COUNTY["key"][kind], "Medium", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		l.size.x = ceilf(UI.text_width(l, l.text)) + 2.0
		x += l.size.x + 18
	_key.size.x = x - 4


## A tick in a pin (a taken place, the key's Taken).
static func _tick(c: CanvasItem, at: Vector2, r: float) -> void:
	c.draw_polyline(PackedVector2Array([at + Vector2(-0.45, 0.0) * r, at + Vector2(-0.1, 0.38) * r, at + Vector2(0.5, -0.38) * r]), Pal.BG, maxf(2.0, r * 0.28))


## A pin's name laid by its pin: below or above it hugging its own width, or to its right or left; inside the land.
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
	if side == BELOW or side == ABOVE:
		var w: float = ceilf(UI.text_width(l, l.text)) + 4.0     # hugging the pin: the word's own width, centred
		r.position.x = p.x - w / 2.0
		r.size.x = w
	r.position.x = clampf(r.position.x, 4.0, _map.size.x - 4.0 - r.size.x)
	l.position = r.position
	l.size = r.size
	l.horizontal_alignment = align


## A painting's point on the land: drawn x2 from the land's top left (BUILD61-U).
static func _px(p: Vector2) -> Vector2:
	return p * PX


static func painting() -> Texture2D:
	if not _painting_read:
		_painting_read = true
		if ResourceLoader.exists(PAINTING):
			_painting = load(PAINTING)
		elif FileAccess.file_exists(PAINTING):
			var img := Image.load_from_file(ProjectSettings.globalize_path(PAINTING))
			if img != null:
				_painting = ImageTexture.create_from_image(img)
	return _painting


## The painting's size in its own pixels, read from the texture (BUILD61-U: 512 x 424 today, Matt's 688 x 384 when it lands).
static func paint_size() -> Vector2:
	var pic := painting()
	return pic.get_size() if pic != null else PAINT_FALLBACK


## The land's size on the screen: the painting's x PX.
static func land_size() -> Vector2:
	return paint_size() * PX


static func zone_of(k: String) -> int:
	return int(Data.county(k).get("cz", -1))


static func zone_key(z: int) -> String:
	return Items.slug(str(Data.COUNTY_ZONES[z]["name"]))


## The land the F3 tool lays its outlines on (map_placement.gd's _land).
func land() -> Control:
	return _map


## A pin's tone: the odds as read, grey while they're read, hollow when shut.
func _tone(k: String) -> Color:
	if not sim.order_open(k):
		return Pal.CARD_LINE
	var od: Array = sim.order_odds_now(k)
	if not bool(od[1]):
		return Pal.TEXT_3
	var o: float = float(od[0])
	return Pal.GOOD if o >= 0.9 else (Pal.WARN if o >= 0.6 else Pal.BAD)


## A zone's names plain: open, or the F3 tool's on (every name plain while placing).
func _known(z: int) -> bool:
	return placing or sim.county_zone_open(z)


func show_state(s) -> void:
	sim = s
	if sim == null:
		return
	if selected == "" or not sim.county_zone_open(zone_of(selected)):
		selected = _default_place()
	var reads := ""
	for c in Data.COUNTY:
		reads += str(sim.order_odds_now(str(c["key"])))
	var sig := "%s|%s|%s|%d|%d|%d|%s|%d|%s|%s|%s|%s|%d" % [selected, str(sim.order_beaten), reads, sim.reach, sim.issued_worn(), int(sim.on_mission()), str(sim.can_deploy()), int(sim.issued),
		str(sim.cs_done), str(sim.cs_new), str(sim.cs_pick), str(sim.county_heads), int(placing)]
	if _shut_zone >= 0 and sim.county_zone_open(_shut_zone):
		hide_shut()                              # its zone opened: the card's wrong now
	if sig == _shown:
		return
	_shown = sig
	for z in range(_zone_labels.size()):
		var nm: String = str(Data.COUNTY_ZONES[z]["name"])
		UI.fit(_zone_labels[z], [nm if _known(z) else Fmt.scramble(nm)])
		_zone_labels[z].add_theme_color_override("font_color", Pal.TEXT if _known(z) else Pal.TEXT_3)
	var any_new := false
	for k in _pin_labels:
		var l: Label = _pin_labels[k]
		var known: bool = _known(zone_of(k))
		var place: String = str(Data.county(k)["place"]).trim_prefix("The ")
		var mark: String = pin_mark(k) if known and not placing else ""     # "· 2/3", "· New" (BUILD61-U); the F3 tool its name only
		l.text = place if known else Fmt.scramble(place)
		if mark != "":
			l.text = Words.U55["pin"] % [l.text, mark]
		var done: bool = mark != "" and sim.county_stage_done(k) >= Data.STAGES
		l.add_theme_color_override("font_color", Pal.ACCENT if k == selected else (Pal.GOOD if done else (Pal.TEXT if known else Pal.TEXT_3)))     # 3/3: the done colour
		_lay_label(l, pin_at(k), int(PLACE_AT[k][1]))
		var on: bool = mark == Words.U55["new"]
		MapViewRef.lay_mark(l, _pin_marks[k], on, pulse_t)
		any_new = any_new or on
	set_process(any_new)                     # ticking only while a "New" shows
	_map.queue_redraw()
	_pins.queue_redraw()


## A pin's mark after its name (BUILD61-U, as the Map's): "New" while opened and unpicked, else the furthest stage
## cleared; "" in a shut zone or none cleared.
func pin_mark(k: String) -> String:
	if not sim.county_zone_open(zone_of(k)):
		return ""
	return MapViewRef.mark_of(sim.county_site_new(k), sim.county_stage_done(k))


func _ready() -> void:
	set_process(_pin_marks.values().any(func(m): return m.visible))     # a defined _process ticks from here unless told


func _process(delta: float) -> void:
	pulse_t = fmod(pulse_t + delta, MapViewRef.NEW_PULSE_S)
	var a: float = MapViewRef.pulse_alpha(pulse_t)
	for k in _pin_marks:
		if _pin_marks[k].visible:
			_pin_marks[k].modulate.a = a


## The place the board opens on: the furthest open place, else the first.
func _default_place() -> String:
	var out := str(Data.COUNTY[0]["key"])
	for c in Data.COUNTY:
		if sim.order_open(str(c["key"])):
			out = str(c["key"])
	return out


func _draw_map() -> void:
	var pic := painting()
	if pic != null:
		_map.draw_texture_rect(pic, Rect2(Vector2.ZERO, paint_size() * PX), false)     # x2 from the land's top left (BUILD61-U)
	else:
		_map.draw_rect(Rect2(Vector2.ZERO, _map.size), Color("181b1f"))
		for z in range(Data.COUNTY_ZONES.size()):
			var pts := _scaled(zone_points(z))
			_map.draw_colored_polygon(pts, [Color("282b30"), Color("262c34"), Color("222c25"), Color("2d2a2c")][z % 4])
			pts.append(pts[0])
			_map.draw_polyline(pts, Pal.CARD_LINE, 2.0)
	if sim == null:
		return
	var lit: int = zone_of(selected)
	if lit >= 0 and sim.county_zone_open(lit) and not placing:
		_map.draw_colored_polygon(_scaled(zone_points(lit)), LIT)
	for z in range(Data.COUNTY_ZONES.size()):
		if not _known(z):
			_hatch(zone_points(z))               # the hatch off while placing (BUILD61-U): the painting plain under the tool


func _draw_pins() -> void:
	if sim == null:
		return
	for c in Data.COUNTY:
		var k: String = str(c["key"])
		var at: Vector2 = pin_at(k)
		var known: bool = _known(zone_of(k))
		var r: float = PIN_R if known else PIN_R_SHUT
		var head: bool = c.has("who")
		if k == selected:
			_pins.draw_circle(at, r + 9.0, Color(Pal.ACCENT, 0.25))
			_pins.draw_circle(at, r + 5.0, Pal.ACCENT)
		var col: Color = _tone(k) if sim.order_open(k) else Pal.BUTTON
		if head:                                 # a head's place keeps its diamond
			var d := r + 3.0
			_pins.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -d - 3), at + Vector2(d + 3, 0), at + Vector2(0, d + 3), at + Vector2(-d - 3, 0)]), Pal.BG)
			_pins.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -d), at + Vector2(d, 0), at + Vector2(0, d), at + Vector2(-d, 0)]), col)
		else:
			_pins.draw_circle(at, r + 3.0, Pal.BG)
			_pins.draw_circle(at, r, col)
		if pin_state(k) == "taken":
			_tick(_pins, at, r)                  # taken: a tick on its pin (the canvas 'The County board', A)
		if not sim.order_open(k):
			_pins.draw_arc(at, r, 0.0, TAU, 24, Pal.TEXT_3 if known else Color("5a6068"), 2.0)


func _scaled(pts) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(_px(p))
	return out


## A shut zone, darkened and hatched, the strokes clipped to its shape (in the painting's pixels).
func _hatch(points: PackedVector2Array) -> void:
	_map.draw_colored_polygon(_scaled(points), Color(0, 0, 0, 0.5))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in points:
		lo = lo.min(p)
		hi = hi.max(p)
	var c := lo.x - (hi.y - lo.y)
	while c < hi.x:
		var a := Vector2(c, hi.y)
		var b := Vector2(c + (hi.y - lo.y), lo.y)
		var inside := false
		var from := Vector2.ZERO
		for n in range(41):
			var p: Vector2 = a.lerp(b, n / 40.0)
			var now: bool = Geometry2D.is_point_in_polygon(p, points)
			if now and not inside:
				from = p
			elif not now and inside:
				_map.draw_line(_px(from), _px(p), Color("1c1f23"), 5.0)
			inside = now
		if inside:
			_map.draw_line(_px(from), _px(b), Color("1c1f23"), 5.0)
		c += 9.0


func _map_input(ev: InputEvent) -> void:
	if sim == null:
		return
	# the pan (BUILD51-U, item 2): a drag or the wheel moves the land; a click on the open land, no pin under it, puts
	# the card away
	var act: String = pan.input(ev)
	if act == "click" and not _press_hit:
		set_card(false)
	if act != "press":
		return
	_press_hit = false
	var hit := ""
	var best := HIT_R
	for c in Data.COUNTY:
		var k: String = str(c["key"])
		var dist: float = (ev.position as Vector2).distance_to(pin_at(k))
		if dist <= best and sim.county_zone_open(zone_of(k)):
			best = dist
			hit = k
	hide_shut()
	if hit != "":
		_press_hit = true
		select(hit)
		return
	var z := zone_at(ev.position)
	if z >= 0 and not sim.county_zone_open(z):
		_press_hit = true                      # a shut zone's card, not the land's click
		show_shut(z, ev.position)


## The zone under a point of the land, or -1.
func zone_at(at: Vector2) -> int:
	var p: Vector2 = at / PX
	for z in range(Data.COUNTY_ZONES.size()):
		if Geometry2D.is_point_in_polygon(p, zone_points(z)):
			return z
	return -1


## A shut zone clicked (the canvas 'The County board', B): its card where it was clicked - its name still scrambled,
## the head to take first, the issued kit it'll want.
func show_shut(z: int, at: Vector2) -> void:
	var nm: String = Fmt.scramble(str(Data.COUNTY_ZONES[z]["name"]))
	var prev: int = maxi(0, z - 1)
	var head_k: String = str(Sim.county_places(prev)[2])
	var known: bool = sim.county_zone_open(prev)
	var place: String = str(Data.county(head_k)["place"])
	var who: String = str(Data.county(head_k)["who"])
	var line: String = Words.COUNTY["shut_line"] % [Words.mid(place) if known else Fmt.scramble(place), Words.mid(who) if known else Fmt.scramble(who), sim.county_want(z)]
	UI.fit(_shut_lines[1], [nm])
	UI.wrap([_shut_lines[2], _shut_lines[3]], line)
	# kept on the view, not just the land (BUILD61 merge: on Matt's wider painting a shut zone's pin can sit past the
	# frame's edge, under the site card's column)
	var v0: Vector2 = pan.offset().max(Vector2.ZERO) if pan != null else Vector2.ZERO
	var v1: Vector2 = (pan.offset() + pan.view).min(_map.size) if pan != null else _map.size
	_shut.position = Vector2(clampf(at.x - 40.0, v0.x + 8.0, maxf(v0.x + 8.0, v1.x - _shut.size.x - 8.0)), clampf(at.y - 20.0, v0.y + 8.0, maxf(v0.y + 8.0, v1.y - _shut.size.y - 60.0)))
	_shut.visible = true
	_shut_zone = z
	_shut.move_to_front()
	_cover_labels()


## The shut card down (the review: it outlived the board, a select and its zone's opening).
func hide_shut() -> void:
	_shut.visible = false
	_shut_zone = -1
	_cover_labels()


## The map's names under the shut card hidden while it's up (it sits over them), shown again after.
func _cover_labels() -> void:
	var r := Rect2(_shut.position, _shut.size)
	for l in _zone_labels + _pin_labels.values():
		l.visible = not (_shut.visible and r.intersects(Rect2(l.position, l.size)))


## A place picked: its card at the right (missions.gd's site card; a place in a shut zone doesn't pick); its "New" goes.
func select(k: String) -> void:
	if sim == null or Data.county(k).is_empty() or not sim.county_zone_open(zone_of(k)):
		return
	selected = k
	hide_shut()
	picked_by_hand = true
	sim.mark_county_seen(k)                    # its pin's "New" goes once picked (BUILD61-U, as the Map's)
	_shown = ""
	card_on = true                             # a place picked: its card (BUILD51-U)
	_card_lay()
	show_state(sim)
	picked.emit(k)


func pin_at(k: String) -> Vector2:
	return _px(place_of("sites", k))


## A pin as drawn: "taken" (its 2/3 cleared, BUILD61-U: the stage that takes a place), "open", "known" (its zone open,
## the place not yet) or "shut".
func pin_state(k: String) -> String:
	if sim.county_stage_done(k) >= Data.STAGE_OPENS:
		return "taken"
	if sim.order_open(k):
		return "open"
	return "known" if sim.county_zone_open(zone_of(k)) else "shut"


func shut_card() -> Panel:
	return _shut


func key_strip() -> Panel:
	return _key


func text_nodes() -> Array:
	var out: Array = []
	for l in _zone_labels:
		out.append(l)
	for k in _pin_labels:
		out.append(_pin_labels[k])
	var vr := Rect2(pan.offset(), pan.view)     # the names on the view (BUILD51-U): those panned off it, or cut, aren't the screen's
	out = out.filter(func(l): return l.text == "" or vr.encloses(MapViewRef.word_rect(l)))
	for c in _key.get_children():
		if c is Label:
			out.append(c)
	if _shut.visible:
		out.append_array(_shut_lines)
	return out


# ------------------------------------------------------------------ the land and the card's toggle (BUILD51-U, item 2)

var pan                                    # map_pan.gd
var _frame: Control
var card_on := true
var picked_by_hand := false
var _press_hit := false


## The card on or off (missions.gd shows the site card while it's on): off, the land takes the width.
func set_card(on: bool) -> void:
	if card_on == on:
		return
	card_on = on
	_card_lay()
	card_changed.emit()


func _card_lay() -> void:
	var w: float = float(MAP_W) if card_on else size.x
	if not is_equal_approx(_frame.size.x, w):
		_frame.size.x = w
		pan.set_view(_frame.size)


## The sheet opens on the picked place, centred.
func open_view() -> void:
	if sim == null:
		return
	_card_lay()
	pan.centre_on(pin_at(selected) if Data.county(selected).has("key") else _map.size / 2.0)


# ------------------------------------------------------------------ the places from data (BUILD61-U, as the Map's BUILD52)

const PLACES_FILE := "res://data/county_places.tres"
static var places_file: String = PLACES_FILE     # the tests point it at a fixture
static var _places = null                        # {kind: {key: point}} in this painting's pixels, read once


## What the file holds, read once (again after use_places / forget_places): "sites" (a place's key) and "zone_names" (a
## zone's key) -> point, "zones" -> PackedVector2Array, rescaled to this painting.
static func places() -> Dictionary:
	if _places == null:
		_places = {}
		if ResourceLoader.exists(places_file):
			var r = ResourceLoader.load(places_file, "", ResourceLoader.CACHE_MODE_IGNORE)
			if r != null and r.get("sites") is Dictionary:
				use_places(r)
	return _places


## A map_places.gd's points taken as the County's from now on (F5's save, a fresh read).
static func use_places(r) -> void:
	_places = {}
	var from: Vector2 = r.paint_size if r.paint_size.x > 0.0 and r.paint_size.y > 0.0 else paint_size()
	var k: Vector2 = paint_size() / from
	for kind in ["sites", "zone_names"]:
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


static func forget_places() -> void:
	_places = null


## A place's point in the painting's pixels, from the file, else the tables rescaled from today's painting.
static func placed(kind: String, key: String) -> Vector2:
	var d: Dictionary = places().get(kind, {})
	if d.has(key):
		return d[key]
	var k: Vector2 = paint_size() / OLD_PAINT
	match kind:
		"sites":
			if PLACE_AT.has(key):
				return PLACE_AT[key][0] * k
		"zone_names":
			for z in range(Data.COUNTY_ZONES.size()):
				if zone_key(z) == key:
					return ZONE_NAME_AT[z] * k
	return Vector2.ZERO


## A zone's shape in the painting's pixels: the file's, else the table's rescaled.
static func zone_points(z: int) -> PackedVector2Array:
	var d: Dictionary = places().get("zones", {})
	if d.has(zone_key(z)):
		return d[zone_key(z)]
	var out := PackedVector2Array()
	for p in ZONE_SHAPES[z]:
		out.append(p * (paint_size() / OLD_PAINT))
	return out


## A place's point as it is now: the F3 tool's while placing, else placed().
func place_of(kind: String, key: String) -> Vector2:
	if placing and _edit.has(kind) and _edit[kind].has(key):
		return _edit[kind][key]
	return placed(kind, key)


## Every place the F3 tool moves: [kind, key, its name on the tool] - the twelve places and the four zones' names.
func all_places() -> Array:
	var out: Array = []
	for c in Data.COUNTY:
		out.append(["sites", str(c["key"]), str(c["place"])])
	for z in range(Data.COUNTY_ZONES.size()):
		out.append(["zone_names", zone_key(z), str(Data.COUNTY_ZONES[z]["name"])])
	return out


# ------------------------------------------------------------------ the placement tool (F3, debug builds; BUILD61-U)

var placing := false
var top_clear := Callable()             # nothing laid over the County's land: the tool's line at the view's top
var _edit: Dictionary = {}
var _placer: Control                    # map_placement.gd


## Whether F3 can start here: a debug build, the County up, a game on it.
func can_place() -> bool:
	return _placer != null and _placer.in_debug and on_screen() and sim != null


func on_screen() -> bool:
	var n: Node = self
	while n is CanvasItem:
		if not (n as CanvasItem).visible:
			return false
		n = n.get_parent()
	return true


## F3 on or off: every place's point copied to move, the names plain and the hatch off while it's on.
func set_placing(on: bool) -> void:
	placing = on
	_edit = {}
	if on:
		hide_shut()
		for e in all_places():
			if not _edit.has(e[0]):
				_edit[e[0]] = {}
			_edit[e[0]][e[1]] = placed(e[0], e[1])
	relay()
	if sim != null:
		_shown = ""
		show_state(sim)


func set_place(kind: String, key: String, p: Vector2) -> void:
	if not (placing and _edit.has(kind)):
		return
	_edit[kind][key] = p.clamp(Vector2.ZERO, paint_size())
	relay()


## Every name back on its pin and the zones' names on their points, the pins redrawn.
func relay() -> void:
	for k in _pin_labels:
		_lay_label(_pin_labels[k], pin_at(k), int(PLACE_AT[k][1]))
	for z in range(_zone_labels.size()):
		var at: Vector2 = _px(place_of("zone_names", zone_key(z)))
		var right: bool = at.x + 300.0 > _map.size.x          # a name against the land's right edge, set from it
		_zone_labels[z].position = Vector2(_map.size.x - 308.0 if right else at.x, at.y)
		_zone_labels[z].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	_map.queue_redraw()
	_pins.queue_redraw()
	if _placer != null:
		_placer.queue_redraw()
