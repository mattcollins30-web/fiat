extends Control
## The County on the Map (26 Oct, the drawn map on Matt's painting, art/map/county.png; docs/design/county_map_brief.md):
## the painting at the left, as the first campaign's (512 x 424 drawn x2), its four zones traced (a first pass - Matt
## plays and corrects), a pin a place in its odds' colour, a head's place a diamond; a shut zone dark and hatched, its
## names scrambled; the picked place's zone lit. The picked place's card at the right: its own card picture (else its
## host's), its name and line, its zone's head and the issued kit it wants, the level and the odds, and Go, or what
## keeps it shut. Without the painting, the zones drawn flat.
##
## Signals: `acted` after a run sets off.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")

const COL_GAP := 16
@warning_ignore("integer_division")
const COL_W := (Pal.GRID_W - 2 * COL_GAP) / 3
const MAP_W := 2 * COL_W + COL_GAP
const PAD := 20
const INNER := COL_W - 2 * PAD
const ART_H := 220
const LINE_H := 26
const PIN_R := 12.0
const PIN_R_SHUT := 7.0
const HIT_R := 30.0
const LABEL_W := 260.0
const LABEL_H := 24.0
const MAP_AT := Vector2(-3, -2)          # the painting drawn x2 from here, as the first map
const PAINTING := "res://art/map/county.png"
const LIT := Color(1.0, 0.86, 0.6, 0.08)

## The zones, in the painting's own 512 x 424 (26 Oct, a first pass off the painting), in Data.COUNTY_ZONES' order:
## the Motorway along the top, the Docks down the right, the Big Houses the country west and south, the Treasury the town.
const ZONE_SHAPES := [
	[Vector2(0, 0), Vector2(512, 0), Vector2(512, 92), Vector2(410, 92), Vector2(165, 100), Vector2(0, 92)],
	[Vector2(410, 92), Vector2(512, 92), Vector2(512, 424), Vector2(330, 424), Vector2(345, 305), Vector2(360, 305), Vector2(400, 250)],
	[Vector2(0, 92), Vector2(165, 100), Vector2(165, 305), Vector2(345, 305), Vector2(330, 424), Vector2(0, 424)],
	[Vector2(165, 100), Vector2(410, 92), Vector2(400, 250), Vector2(360, 305), Vector2(165, 305)],
]
const ZONE_NAME_AT := [Vector2(176, 6), Vector2(440, 396), Vector2(6, 104), Vector2(170, 240)]
## A place's pin, in the painting's space, and where its name sits.
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
var _zone_labels: Array = []        # a Label a zone
var _card := {}                     # the picked place's card: panel, art, state, place, who, words, want, status, button, note
var _shown := ""
static var _painting = null
static var _painting_read := false


func _init(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	mouse_filter = Control.MOUSE_FILTER_PASS
	_map = Control.new()
	_map.position = Vector2.ZERO
	_map.size = Vector2(MAP_W, rect.size.y)
	_map.clip_contents = true
	_map.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.draw.connect(_draw_map)
	_map.gui_input.connect(_map_input)
	add_child(_map)
	_pins = Control.new()
	_pins.size = _map.size
	_pins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pins.draw.connect(_draw_pins)
	_map.add_child(_pins)
	for z in range(Data.COUNTY_ZONES.size()):
		var at: Vector2 = _px(ZONE_NAME_AT[z])
		var right: bool = at.x + 300.0 > MAP_W                # the Docks' name against the map's right edge, set from it
		var l := UI.label(_map, Rect2(Vector2(MAP_W - 308.0 if right else at.x, at.y), Vector2(300, 30)), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT, false)
		UI.shadow(l)
		_zone_labels.append(l)
	for k in PLACE_AT:
		_pin_labels[k] = _pin_label(_px(PLACE_AT[k][0]), int(PLACE_AT[k][1]))
	_build_card()


func _build_card() -> void:
	var x: float = MAP_W + COL_GAP
	var panel := UI.panel(self, Rect2(x, 0, COL_W, size.y), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	panel.clip_contents = true
	_card["panel"] = panel
	var art := TextureRect.new()
	art.position = Vector2(1, 1)
	art.size = Vector2(COL_W - 2, ART_H)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(art)
	_card["art"] = art
	_card["state"] = UI.label(panel, Rect2(PAD, 14, INNER, 24), "", "SemiBold", Pal.CELL_TEXT, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.shadow(_card["state"])
	_card["place"] = UI.label(panel, Rect2(PAD, ART_H - 52, INNER, 44), "", "SemiBold", Pal.HEADLINE - 6, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.shadow(_card["place"])
	var y := ART_H + 16.0
	_card["who"] = UI.label(panel, Rect2(PAD, y, INNER, 32), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	y += 38
	_card["words"] = []
	for n in range(3):
		_card["words"].append(UI.label(panel, Rect2(PAD, y + n * LINE_H, INNER, LINE_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	y += 3 * LINE_H + 14
	_card["want"] = UI.label(panel, Rect2(PAD, y, INNER, 28), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	y += 34
	_card["status"] = UI.label(panel, Rect2(PAD, y, INNER, 30), "", "SemiBold", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var fy: float = size.y - PAD - Pal.BUTTON_H
	_card["button"] = UI.button(panel, Rect2(PAD, fy, INNER, Pal.BUTTON_H), true)
	_card["button"].pressed.connect(func(): _go(selected))
	_card["note"] = UI.label(panel, Rect2(PAD, fy, INNER, Pal.BUTTON_H), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER, false)


func _pin_label(p: Vector2, side: int) -> Label:
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
	r.position.x = clampf(r.position.x, 4.0, _map.size.x - 4.0 - r.size.x)
	var l := UI.label(_map, r, "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, align, false)
	UI.shadow(l)
	return l


## The painting's point on the map: drawn x2 from MAP_AT.
static func _px(p: Vector2) -> Vector2:
	return MAP_AT + p * 2.0


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


static func zone_of(k: String) -> int:
	return int(Data.county(k).get("cz", -1))


## A pin's tone: the odds as read, grey while they're read, hollow when shut.
func _tone(k: String) -> Color:
	if not sim.order_open(k):
		return Pal.CARD_LINE
	var od: Array = sim.order_odds_now(k)
	if not bool(od[1]):
		return Pal.TEXT_3
	var o: float = float(od[0])
	return Pal.GOOD if o >= 0.9 else (Pal.WARN if o >= 0.6 else Pal.BAD)


func show_state(s) -> void:
	sim = s
	if sim == null:
		return
	if selected == "" or not sim.county_zone_open(zone_of(selected)):
		selected = _default_place()
	var reads := ""
	for c in Data.COUNTY:
		reads += str(sim.order_odds_now(str(c["key"])))
	var sig := "%s|%s|%s|%d|%d|%d|%s|%d" % [selected, str(sim.order_beaten), reads, sim.reach, sim.issued_worn(), int(sim.on_mission()), str(sim.can_deploy()), int(sim.issued)]
	if sig == _shown:
		return
	_shown = sig
	for z in range(_zone_labels.size()):
		var open: bool = sim.county_zone_open(z)
		var nm: String = str(Data.COUNTY_ZONES[z]["name"])
		UI.fit(_zone_labels[z], [nm if open else Fmt.scramble(nm)])
		_zone_labels[z].add_theme_color_override("font_color", Pal.TEXT if open else Pal.TEXT_3)
	for k in _pin_labels:
		var l: Label = _pin_labels[k]
		var known: bool = sim.county_zone_open(zone_of(k))
		var place: String = str(Data.county(k)["place"]).trim_prefix("The ")
		UI.fit(l, [place if known else Fmt.scramble(place)])
		l.add_theme_color_override("font_color", Pal.ACCENT if k == selected else (Pal.TEXT if known else Pal.TEXT_3))
		_snug(l, k)
	_show_card()
	_map.queue_redraw()
	_pins.queue_redraw()


## A name above or below its pin hugs it: its box the word's own width, centred on the pin, inside the map.
func _snug(l: Label, k: String) -> void:
	var side: int = int(PLACE_AT[k][1])
	if side != BELOW and side != ABOVE:
		return
	var p: Vector2 = _px(PLACE_AT[k][0])
	var w: float = ceilf(UI.text_width(l, l.text)) + 4.0
	l.size.x = w
	l.position.x = clampf(p.x - w / 2.0, 4.0, _map.size.x - 4.0 - w)


## The place the board opens on: the furthest open place, else the first.
func _default_place() -> String:
	var out := str(Data.COUNTY[0]["key"])
	for c in Data.COUNTY:
		if sim.order_open(str(c["key"])):
			out = str(c["key"])
	return out


func _show_card() -> void:
	var k: String = selected
	var d: Dictionary = Data.county(k)
	var z: int = int(d["cz"])
	var zone_open: bool = sim.county_zone_open(z)
	var open: bool = sim.order_open(k)
	var en := func(t: String) -> String: return t if zone_open else Fmt.scramble(t)
	var own: Texture2D = UI.place_texture(str(d["place"]))
	_card["art"].texture = own if own != null else UI.place_texture(str(Data.TIERS[int(d["site"])]["name"]))
	_card["art"].modulate = Color(0.8, 0.8, 0.8) if open else Color(0.35, 0.35, 0.37)
	var beaten: int = int(sim.order_beaten.get(k, 0))
	_card["state"].text = ("TAKEN" if beaten > 0 else ("OPEN" if open else "SHUT"))
	UI.fit(_card["place"], [en.call(str(d["place"])), en.call(str(d["place"]).trim_prefix("The "))])
	var zone: Dictionary = Data.COUNTY_ZONES[z]
	var who: String = (Words.COUNTY["head"] % str(d["who"])) if d.has("who") else str(zone["name"])
	UI.fit(_card["who"], [en.call(who)])
	var line: String = str(Words.COUNTY_WORDS.get(k, ""))
	if d.has("who"):
		line = "%s %s" % [line, Words.COUNTY["drops_issued"] + "."]
	UI.wrap(_card["words"], line if zone_open else "")
	var want: int = sim.county_want(z)
	var worn: int = sim.issued_worn()
	UI.fit(_card["want"], [Words.COUNTY["want"] % [want, worn], Words.COUNTY["want_short"] % want])
	_card["want"].add_theme_color_override("font_color", (Pal.GOOD if worn >= want else Pal.BAD) if zone_open else Pal.TEXT_3)
	var bits: Array = [Words.COUNTY["level"] % sim.order_level(k)]
	if beaten > 0:
		bits.append(Words.COUNTY["beaten"] % beaten)
	var tone := Pal.TEXT_2
	if open:
		var od: Array = sim.order_odds_now(k)
		if bool(od[1]):
			bits.append("%s to clear" % Fmt.pct(float(od[0])))
			tone = Pal.tone_color("good" if float(od[0]) >= 0.9 else ("warn" if float(od[0]) >= 0.6 else "bad"))
		else:
			bits.append(Words.COUNTY["odds_reading"])
	UI.fit(_card["status"], [" · ".join(bits), " · ".join(bits.slice(0, 1))] if zone_open else [""])
	_card["status"].add_theme_color_override("font_color", tone)
	var why: String = sim.order_block(k)
	_card["button"].visible = open and why == ""
	_card["note"].visible = not _card["button"].visible
	UI.fit_button(_card["button"], ["Go: %s" % Words.mid(str(d["place"])), "Go"])
	UI.fit(_card["note"], [why, ""])
	(_card["panel"].get_theme_stylebox("panel") as StyleBoxFlat).border_color = Pal.ACCENT if open else Pal.CARD_LINE


func _draw_map() -> void:
	var pic := painting()
	if pic != null:
		_map.draw_texture_rect(pic, Rect2(MAP_AT, pic.get_size() * 2.0), false)
	else:
		_map.draw_rect(Rect2(Vector2.ZERO, _map.size), Color("181b1f"))
		for z in range(ZONE_SHAPES.size()):
			var pts := _scaled(ZONE_SHAPES[z])
			_map.draw_colored_polygon(pts, [Color("282b30"), Color("262c34"), Color("222c25"), Color("2d2a2c")][z])
			pts.append(pts[0])
			_map.draw_polyline(pts, Pal.CARD_LINE, 2.0)
	if sim == null:
		return
	var lit: int = zone_of(selected)
	if lit >= 0 and sim.county_zone_open(lit):
		_map.draw_colored_polygon(_scaled(ZONE_SHAPES[lit]), LIT)
	for z in range(ZONE_SHAPES.size()):
		if not sim.county_zone_open(z):
			_hatch(ZONE_SHAPES[z])


func _draw_pins() -> void:
	if sim == null:
		return
	for k in PLACE_AT:
		var c: Vector2 = _px(PLACE_AT[k][0])
		var known: bool = sim.county_zone_open(zone_of(k))
		var r: float = PIN_R if known else PIN_R_SHUT
		var head: bool = Data.county(k).has("who")
		if k == selected:
			_pins.draw_circle(c, r + 9.0, Color(Pal.ACCENT, 0.25))
			_pins.draw_circle(c, r + 5.0, Pal.ACCENT)
		var col: Color = _tone(k) if sim.order_open(k) else Pal.BUTTON
		if head:
			var d := r + 3.0
			_pins.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d - 3), c + Vector2(d + 3, 0), c + Vector2(0, d + 3), c + Vector2(-d - 3, 0)]), Pal.BG)
			_pins.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0), c + Vector2(0, d), c + Vector2(-d, 0)]), col)
		else:
			_pins.draw_circle(c, r + 3.0, Pal.BG)
			_pins.draw_circle(c, r, col)
		if not sim.order_open(k):
			_pins.draw_arc(c, r, 0.0, TAU, 24, Pal.TEXT_3 if known else Color("5a6068"), 2.0)


func _scaled(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(_px(p))
	return out


## A shut zone, darkened and hatched, the strokes clipped to its shape.
func _hatch(points: Array) -> void:
	var poly := PackedVector2Array(points)
	_map.draw_colored_polygon(_scaled(points), Color(0, 0, 0, 0.5))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in poly:
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
			var now: bool = Geometry2D.is_point_in_polygon(p, poly)
			if now and not inside:
				from = p
			elif not now and inside:
				_map.draw_line(_px(from), _px(p), Color("1c1f23"), 5.0)
			inside = now
		if inside:
			_map.draw_line(_px(from), _px(b), Color("1c1f23"), 5.0)
		c += 9.0


func _map_input(ev: InputEvent) -> void:
	if sim == null or not (ev is InputEventMouseButton) or not ev.pressed or ev.button_index != MOUSE_BUTTON_LEFT:
		return
	var hit := ""
	var best := HIT_R
	for k in PLACE_AT:
		var dist: float = (ev.position as Vector2).distance_to(_px(PLACE_AT[k][0]))
		if dist <= best and sim.county_zone_open(zone_of(k)):
			best = dist
			hit = k
	if hit != "":
		select(hit)


## A place picked: its card at the right (a place in a shut zone doesn't pick).
func select(k: String) -> void:
	if sim == null or Data.county(k).is_empty() or not sim.county_zone_open(zone_of(k)):
		return
	selected = k
	_shown = ""
	show_state(sim)


func _go(k: String) -> void:
	if sim != null and sim.deploy_order(k):
		_shown = ""
		acted.emit()


## For the tests: the card, shown for `k` (picked first).
func card(k: String) -> Dictionary:
	if k != selected:
		select(k)
	return _card


func pin_at(k: String) -> Vector2:
	return _px(PLACE_AT[k][0])


func text_nodes() -> Array:
	var out: Array = []
	for l in _zone_labels:
		out.append(l)
	for k in _pin_labels:
		out.append(_pin_labels[k])
	out.append_array([_card["state"], _card["place"], _card["who"], _card["want"], _card["status"]] + _card["words"])
	out.append(_card["button"] if _card["button"].visible else _card["note"])
	return out
