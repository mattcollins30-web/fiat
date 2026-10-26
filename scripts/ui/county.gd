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
signal to_issuer                       # the card's "The Issuer, at the Fence" (the third review, the canvas 'The County board')
signal to_bench                        # its "Stamp your own, at the Bench"

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const Sim := preload("res://scripts/sim/sim.gd")

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
const SLOT_ORDER := ["Helmet", "Armour", "Rig", "Charm", "Secondary", "Primary"]
const SLOT_WORDS := {"Helmet": "Helmet", "Armour": "Armour", "Rig": "Rig", "Charm": "Charm", "Secondary": "Sidearm", "Primary": "Gun"}
const CHIP_H := 40.0
const LINK_H := 46.0

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
var _slots: Array = []              # the card's issued slots worn: [panel, label] a slot, ISSUED_FIRST's order
var _key: Panel                     # the map's key strip, bottom left
var _shut: Panel                    # a shut zone's card where it was clicked
var _shut_lines: Array = []
var _shut_zone := -1
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
	_build_key()
	_shut = UI.panel(_map, Rect2(0, 0, 430, 130), UI.box(Color(Pal.BG, 0.95), 8, 2, Pal.CARD_LINE))
	_shut.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shut.visible = false
	_shut_lines.append(UI.label(_shut, Rect2(16, 12, 398, 20), Words.COUNTY["shut_kicker"], "SemiBold", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false))
	_shut_lines.append(UI.label(_shut, Rect2(16, 34, 398, 32), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))
	for n in range(2):
		_shut_lines.append(UI.label(_shut, Rect2(16, 70 + n * 24, 398, 24), "", "Regular", Pal.CELL_TEXT + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))


## The key strip (the canvas 'The County board', A): the pins' colours, shut and taken, bottom left of the map.
func _build_key() -> void:
	_key = UI.panel(_map, Rect2(12, size.y - 50, 10, 38), UI.box(Color("0f1214", 0.86), 6))
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
	y += 44
	# the issued kit worn, slot by slot, then the two ways to meet the want (the canvas 'The County board', A)
	_card["slots_head"] = UI.label(panel, Rect2(PAD, y, INNER, 22), "", "SemiBold", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	y += 30
	var cw: float = (INNER - 2 * 12.0) / 3.0
	for k in range(SLOT_ORDER.size()):
		@warning_ignore("integer_division")
		var r := Rect2(PAD + (k % 3) * (cw + 12.0), y + (k / 3) * (CHIP_H + 8.0), cw, CHIP_H)
		var cp := UI.panel(panel, r, UI.box(Pal.PANEL, 6, 2, Pal.CARD_LINE))
		cp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cl := UI.label(cp, Rect2(12, 0, cw - 16, CHIP_H), "", "SemiBold", Pal.CELL_TEXT + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		_slots.append([cp, cl])
	y += 2 * CHIP_H + 8 + 26
	_card["to_issuer"] = UI.button(panel, Rect2(PAD, y, INNER, LINK_H), false)
	_card["to_issuer"].pressed.connect(func(): to_issuer.emit())
	y += LINK_H + 10
	_card["to_bench"] = UI.button(panel, Rect2(PAD, y, INNER, LINK_H), false)
	_card["to_bench"].pressed.connect(func(): to_bench.emit())
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
	if _shut_zone >= 0 and sim.county_zone_open(_shut_zone):
		hide_shut()                              # its zone opened: the card's wrong now
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
		line = "%s %s %s" % [line, str(Words.COUNTY["mech"].get(str(d.get("mech", "")), "")), Words.COUNTY["drops_issued"] + "."]     # his fight, before Go (the third review)
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
	_card["slots_head"].visible = zone_open
	UI.fit(_card["slots_head"], [Words.COUNTY["slots_head"] % [worn, want, str(zone["name"]).to_upper().trim_prefix("THE "), want], Words.COUNTY["slots_short"] % [worn, want]])
	for n in range(SLOT_ORDER.size()):
		var it = sim.equipped.get(SLOT_ORDER[n])
		var on: bool = it != null and (it.get("issued", false) or it.get("stamped", false))
		_slots[n][0].visible = zone_open
		(_slots[n][0].get_theme_stylebox("panel") as StyleBoxFlat).border_color = Pal.GOOD if on else Pal.CARD_LINE
		UI.fit(_slots[n][1], ["%s %s" % ["✓" if on else "—", SLOT_WORDS[SLOT_ORDER[n]]]])
		_slots[n][1].add_theme_color_override("font_color", Pal.TEXT if on else Pal.TEXT_3)
	for b in ["to_issuer", "to_bench"]:
		_card[b].visible = zone_open
		UI.fit_button(_card[b], [Words.COUNTY[b], Words.COUNTY[b + "_short"]])
		UI.style_button(_card[b], false, "")
	var why: String = sim.order_block(k)
	_card["button"].visible = open and why == ""
	_card["note"].visible = not _card["button"].visible
	UI.fit_button(_card["button"], ["Go: %s" % Words.mid(str(d["place"])), "Go"])
	var want_line: bool = why == Words.COUNTY["want"] % [want, worn]
	UI.fit(_card["note"], [Words.COUNTY["want_how"], "The Issuer, at the Fence"] if want_line else [why, ""])     # where it comes from, not the want twice (the third review)
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
		if pin_state(k) == "taken":
			_tick(_pins, c, r)                    # taken: a tick on its pin (the canvas 'The County board', A)
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
	hide_shut()
	if hit != "":
		select(hit)
		return
	var z := zone_at(ev.position)
	if z >= 0 and not sim.county_zone_open(z):
		show_shut(z, ev.position)


## The zone under a point of the map (its painting space), or -1.
func zone_at(at: Vector2) -> int:
	var p: Vector2 = (at - MAP_AT) / 2.0
	for z in range(ZONE_SHAPES.size()):
		if Geometry2D.is_point_in_polygon(p, PackedVector2Array(ZONE_SHAPES[z])):
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
	_shut.position = Vector2(clampf(at.x - 40.0, 8.0, _map.size.x - _shut.size.x - 8.0), clampf(at.y - 20.0, 8.0, _map.size.y - _shut.size.y - 60.0))
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


## A place picked: its card at the right (a place in a shut zone doesn't pick).
func select(k: String) -> void:
	if sim == null or Data.county(k).is_empty() or not sim.county_zone_open(zone_of(k)):
		return
	selected = k
	hide_shut()
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


## A pin as drawn: "taken", "open", "known" (its zone open, the place not yet) or "shut".
func pin_state(k: String) -> String:
	if int(sim.order_beaten.get(k, 0)) > 0:
		return "taken"
	if sim.order_open(k):
		return "open"
	return "known" if sim.county_zone_open(zone_of(k)) else "shut"


## For the tests: the card's slot chips' words, the shut card, the key.
func slot_words() -> Array:
	return _slots.filter(func(s): return s[0].visible).map(func(s): return s[1].text)


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
	out.append_array([_card["state"], _card["place"], _card["who"], _card["want"], _card["status"]] + _card["words"])
	out.append(_card["button"] if _card["button"].visible else _card["note"])
	out.append(_card["slots_head"])
	for sl in _slots:
		out.append(sl[1])
	for c in _key.get_children():
		if c is Label:
			out.append(c)
	if _shut.visible:
		out.append_array(_shut_lines)
	return out
