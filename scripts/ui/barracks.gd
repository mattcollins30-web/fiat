extends Control
## The Caravan's screen: what the runner was, and training (9 Oct, docs/design/trees.md). Every tree a lane
## on one screen, read left to right in six columns: the class's first tree, the element it joins, the
## class's second, the element that one joins, the Yard's. A joint is the link between a class lane and the
## element lane under it, in the fourth column. Under the lanes the "Also" row - the elements off the pair,
## the second past's tree, the drawer, the shelf - each a chip that swaps the Yard's lane for it. Then what
## the trees add up to, and the strip for the selected node with Train and Respec. Fixed geometry inside the
## card grid's 1536 x 916.

signal acted
signal ascend                      # the Second past button: the owner offers the classes
signal retire                      # the Retire button (36): the owner asks, then the runner goes to the wall

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const People := preload("res://scripts/ui/people.gd")
const Words := preload("res://scripts/sim/words.gd")
const Items := preload("res://scripts/sim/items.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")

const PAD := 20
# the header: the face, the class and trait, the points free, the class's line; the classes top right
const HEAD_H := Pal.BAND_H                                     # the rooms' one band (10 Oct, Bands-U A): 96 → 180
const FACE := Pal.BAND_FACE
const CLASS_W := 164
const CLASS_H := 40
const CLASS_GAP := 8
# the class's line and the notice over the classes, each on a glass pill so the art doesn't eat them (12 Oct); a lone
# line drops to the notice's place, just over the classes, rather than leaving a gap under it
const NOTICE_Y := HEAD_H - 16 - CLASS_H - 34
const LINE_TOP_Y := HEAD_H - 16 - CLASS_H - 62
const PILL_H := 28                 # a hairline between two pills, 4 px over the classes
const PILL_PAD := 12
const PILL_GLASS := Color(0.06, 0.07, 0.08, 0.62)
# the lanes: five, a link strip between a class lane and its element, a gap between the pairs
const LANES_Y := HEAD_H + 6
const LANE_H := 100                                            # 104 → 100 (Bands-U A): the tiles keep 44, the pad 4
const LINK_H := 20
const PAIR_GAP := 6
const TILE_TOP := 4                                            # a tile's row 0 from the lane's top
const LANES := 5
const LABEL_W := 170                                           # the lane's label block: name, whose, points in, the next gate
const TILES_X := LABEL_W + 12
const COLS := 6
const TILE_GAP := 6
const ROW_GAP := 4
const TILE_W := (Pal.GRID_W - TILES_X - 8 - (COLS - 1) * TILE_GAP) / COLS     # 219
const TILE_H := (LANE_H - 2 * TILE_TOP - ROW_GAP) / 2                          # 44
const LANE_NODES := 12                                         # tiles a lane holds (a tree has eleven)
## A node as a glyph (9 Oct, Tree-G A): a square tile, a notable round, a keystone a diamond, the capstone a bigger
## diamond alone in its column; centred in its column's cell; the cost a chip on its corner, a tick once trained.
const NODE := 44
const DIAMOND := 32                                            # turned 45°: 45 across, a row's height
const DIAMOND_BIG := 40                                        # the capstone, the lane's height to itself
const GLYPH := 26
const COST_W := 26
const YARD_TONE := Color("8fb3d9")                             # the Yard's tree: its glyphs' tone (its lane's line is the card's)
const LANES_H := LANES * LANE_H + 2 * LINK_H + 2 * PAIR_GAP    # 552
const ALSO_Y := LANES_Y + LANES_H + 6
const ALSO_H := 40
const ALSO_HEAD_W := 150
const ALSO_MAX := 10
# the sum ("Add up to") in the band, under the class's line (Bands-U A: the strip's 54 px pay for the band)
const SUM_Y := 76                                              # under the points; the class's line goes right, over the classes
const SUM_H := 3 * Chips.CHIP_H + 2 * Chips.ROW_GAP
const SUM_HEAD_W := 96
const SUM_ROWS := 3
const PANEL_Y := ALSO_Y + ALSO_H + 6
const PANEL_H := Pal.ROOM_H - PANEL_Y
const WORDS_UNDER_Y := 50          # a node's sentence, under its title
# the drawer and the shelf take the lanes' whole area: three columns of cards
const PAGE_COLS := 3
const PAGE_GAP := 6
const PAGE_W := (Pal.GRID_W - (PAGE_COLS - 1) * PAGE_GAP) / PAGE_COLS
const PAGE_CELLS := 24
const NAME_H := 36
const WORD_H := 26                                             # a line of a paper's or a unique's words

var sim
var selected := ""                 # a node id, or ""
var alt := ""                      # the Also chip in the Yard's place: a tree's name, "The drawer", "The shelf", or "" for the Yard
var drawer_page := 0               # the drawer's (or the shelf's) page
var _armed := ""                   # a class pressed once: the second press changes to it (the change costs, 9 Oct)
var _armed_cls := ""               # the class it was armed from: a death, a move or a change elsewhere disarms it
var _shown := ""

var _face: TextureRect
var head_band := {}                # the heading's painted place (10 Oct, Rooms-B)
var _kicker: Label
var _points: Label
var _unit: Label
var _class_line: Label
var _notice: Label                 # under the classes: the trait's line, or the armed change's price
var _line_pills: Array = []        # a glass pill a line, behind the class's line and the notice (12 Oct, Matt: option B, the text brighter)
var _class_buttons: Array = []
var _lanes: Array = []             # a slot each: {panel, bar, name, tag, gates, count, tiles: [{button, name, more, effect, id}], tree}
var _links: Array = []             # two: {bar, chip, label}, under lanes 0 and 2
var _also_panel: Panel
var _also_head: Label
var _also: Array = []              # {button, name}
var _cells: Array = []             # the drawer's and the shelf's cards: {button, name, lines[3]}
var _sum: Panel
var _sum_head: Label
var _sum_chips: Chips
var _panel: Panel
var _title: Label
var _chips: Chips
var _words: Label
var _words2: Label                  # a node's sentence, its second line (the review: four buttons leave ~450 px)
var _node_forms: Array = []          # a node's sentence in its forms, fitted once the buttons have their places
var _past: Label
var _train: Button
var _respec: Button
var _ascend: Button
var _retire: Button


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_head()
	_build_lanes()
	_build_also()
	_build_pages()
	_sum = Panel.new()                  # a frame in the band: the head's words column, two chip rows
	_sum.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_sum.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sum.position = Vector2(_words_x(), SUM_Y)
	_sum.size = Vector2(_words_w(), SUM_H)
	head_band["art"].get_parent().add_child(_sum)
	_sum_head = UI.head(_sum, Rect2(0, 0, SUM_HEAD_W, Chips.CHIP_H), "Add up to")
	_sum_head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI.shadow(_sum_head)
	_sum_chips = Chips.new(_words_w() - SUM_HEAD_W - 8, 16)
	_sum_chips.position = Vector2(SUM_HEAD_W + 8, 0)
	_sum.add_child(_sum_chips)
	_build_panel()


func _build_head() -> void:
	var head := UI.panel(self, Rect2(0, 0, Pal.GRID_W, HEAD_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	head_band = UI.head_art(head, "The caravan")     # art/places/the_caravan.png (Rooms-B)
	# the band as the Yard's (Bands-U A): the face at the left, the words down the shade, the classes at the foot, right
	_face = People.rect(head, Vector2(16, (HEAD_H - FACE) / 2.0), FACE / 128.0)
	var cx0: float = _classes_x()
	var x0: float = _words_x()
	var left_w: float = _words_w()
	_kicker = UI.label(head, Rect2(x0, 8, left_w, 24), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_points = UI.label(head, Rect2(x0, 30, left_w, 40), "", "SemiBold", Pal.HEADLINE - 6, Pal.ACCENT)
	_unit = UI.label(head, Rect2(x0, 34, left_w, 34), "", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(2):
		var pill := UI.panel(head, Rect2(0, 0, 10, PILL_H), UI.box(PILL_GLASS, 10))
		pill.visible = false
		_line_pills.append(pill)                  # made first, so the words sit on them
	_class_line = UI.label(head, Rect2(cx0, LINE_TOP_Y, Pal.GRID_W - PAD - cx0, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)     # over the classes, right
	for k in range(Data.CLASSES.size()):
		var cb := UI.button(head, Rect2(cx0 + k * (CLASS_W + CLASS_GAP), HEAD_H - 16 - CLASS_H, CLASS_W, CLASS_H), false)
		cb.text = Data.CLASSES[k]["name"]
		cb.add_theme_font_size_override("font_size", 20)
		cb.pressed.connect(_pick_class.bind(Data.CLASSES[k]["name"]))
		_class_buttons.append(cb)
	_notice = UI.label(head, Rect2(cx0, NOTICE_Y, Pal.GRID_W - PAD - cx0, 30), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)


static func _classes_x() -> float:
	return Pal.GRID_W - PAD - Data.CLASSES.size() * CLASS_W - CLASS_GAP * (Data.CLASSES.size() - 1)


## The band's words column: past the face, up to the classes.
static func _words_x() -> float:
	return 16 + FACE + 14


static func _words_w() -> float:
	return _classes_x() - 24 - _words_x()


## Where lane `k` starts: two pairs, each a lane, its link and its element's lane, then the Yard's.
static func lane_y(k: int) -> float:
	var y: float = LANES_Y
	for i in range(k):
		y += LANE_H
		if i == 0 or i == 2:
			y += LINK_H
		elif i == 1 or i == 3:
			y += PAIR_GAP
	return y


## A tile's rect in its lane: column `c`, row `r`; `span` a node alone in its column, the two rows' height.
static func tile_rect(c: int, r: int, span := false) -> Rect2:
	return Rect2(TILES_X + c * (TILE_W + TILE_GAP), TILE_TOP + (0 if span else r * (TILE_H + ROW_GAP)), TILE_W, (2 * TILE_H + ROW_GAP) if span else TILE_H)


## A node's tile in its lane: centred in its column's cell (tile_rect), square; a keystone's diamond smaller (it
## turns), the capstone's bigger and centred on the lane when it's alone in its column.
static func node_rect(c: int, r: int, span: bool, kind: String) -> Rect2:
	var cell := tile_rect(c, r, span)
	var n: float = DIAMOND_BIG if (kind == "capstone" and span) else (DIAMOND if kind in ["keystone", "capstone"] else NODE)
	return Rect2(cell.position + (cell.size - Vector2(n, n)) / 2.0, Vector2(n, n))


## A gate's place: the boundary between column c-1 and c, at the lane's middle.
static func gate_pos(c: int) -> Vector2:
	return Vector2(TILES_X + c * (TILE_W + TILE_GAP) - TILE_GAP / 2.0, TILE_TOP + TILE_H + ROW_GAP / 2.0)


const GATE_R := 13.0


## A lane's gates as they stand: [{c, n, lit, x, y}] and each column's rows' y (one: the lane's middle). Laid with
## the lane (the tests read it), drawn by _draw_gates.
func _lay_gates(k: int) -> void:
	var lane: Dictionary = _lanes[k]
	lane["gate_at"] = []
	lane["rows_at"] = {}
	var t = lane["tree"]
	if t == null or sim == null:
		return
	var mine: Array = sim.my_classes()
	var pts: int = sim.points_in(t["name"])
	var per_col := {}
	for nd in t["nodes"]:
		per_col[int(nd.get("col", 0))] = int(per_col.get(int(nd.get("col", 0)), 0)) + 1
	for c in per_col.keys():
		lane["rows_at"][c] = [gate_pos(0).y] if int(per_col[c]) == 1 else [TILE_TOP + TILE_H / 2.0, TILE_TOP + TILE_H + ROW_GAP + TILE_H / 2.0]
	for c in range(1, COLS):
		if not per_col.has(c) or not per_col.has(c - 1):
			continue
		var g: int = Data.gate(t, c, mine)
		var gp := gate_pos(c)
		lane["gate_at"].append({"c": c, "n": g, "lit": pts >= g, "x": gp.x, "y": gp.y})


## Each column's rows into the gate before the next, and out of it: curves, and the gate a numbered disc.
func _draw_gates(k: int) -> void:
	var lane: Dictionary = _lanes[k]
	var conn: Control = lane["conn"]
	var t = lane["tree"]
	if t == null or not lane.has("gate_at"):
		return
	var colour := lane_colour(t)
	var tone: Color = colour if colour != Pal.CARD_LINE else YARD_TONE
	var font: Font = UI.font("SemiBold", true)
	for gd in lane["gate_at"]:
		var c: int = int(gd["c"])
		var lit: bool = gd["lit"]
		var line: Color = Color(tone, 0.85) if lit else Pal.CARD_LINE
		var gp := Vector2(gd["x"], gd["y"])
		var x_from: float = TILES_X + (c - 1) * (TILE_W + TILE_GAP) + TILE_W / 2.0 + NODE / 2.0 + 2.0
		for y0 in lane["rows_at"][c - 1]:
			_curve(conn, Vector2(x_from, y0), gp - Vector2(GATE_R, 0), line)
		for y1 in lane["rows_at"][c]:
			_curve(conn, gp + Vector2(GATE_R, 0), Vector2(rail_in_x(k, c, y1), y1), line)
		conn.draw_circle(gp, GATE_R, Pal.SELECT if lit else Pal.BG)
		conn.draw_arc(gp, GATE_R, 0.0, TAU, 32, tone if lit else Pal.CARD_LINE, 1.5, true)
		var s := str(gd["n"])
		var sw: float = font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		conn.draw_string(font, gp + Vector2(-sw / 2.0, 5.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tone if lit else Pal.TEXT_2)


## Where a rail into column `c`'s row at lane-local `y` ends: just short of the tile, or of a joint half's mark at
## its left (the reviewer, 10 Oct: the rail ran through the ⇄).
func rail_in_x(k: int, c: int, y: float) -> float:
	var x: float = TILES_X + c * (TILE_W + TILE_GAP) + TILE_W / 2.0 - NODE / 2.0 - 2.0
	if _lanes[k].get("marked", {}).has("%d:%d" % [c, int(round(y))]):
		x -= 26.0
	return x


## A rail: flat out of `a`, a bend, flat into `b`.
static func _curve(c: Control, a: Vector2, b: Vector2, colour: Color) -> void:
	var pts := PackedVector2Array()
	var mx: float = (a.x + b.x) / 2.0
	for i in range(17):
		var u: float = float(i) / 16.0
		var p := a.bezier_interpolate(Vector2(mx, a.y), Vector2(mx, b.y), b, u)
		pts.append(p)
	c.draw_polyline(pts, colour, 1.5, true)


## The joint's link's x: the fourth column's middle.
static func link_x() -> float:
	return TILES_X + Data.JOINT_COL * (TILE_W + TILE_GAP) + TILE_W / 2.0


func _build_lanes() -> void:
	for k in range(LANES):
		var y := lane_y(k)
		var p := UI.panel(self, Rect2(0, y, Pal.GRID_W, LANE_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
		var lane := {"panel": p, "tree": null, "tiles": []}
		lane["bar"] = UI.panel(p, Rect2(0, 0, 4, LANE_H), UI.box(Pal.CARD_LINE, 2))
		lane["name"] = UI.label(p, Rect2(14, 6, LABEL_W - 14, 26), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		lane["tag"] = UI.label(p, Rect2(14, 32, LABEL_W - 14, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		lane["gates"] = UI.label(p, Rect2(14, 54, LABEL_W - 14, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		lane["count"] = UI.label(p, Rect2(14, 76, LABEL_W - 14, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		# the rails meet at a gate between columns (10 Oct, Tree-J B; Matt: the rails read node to node, but a column
		# opens on the points in its tree): each column's rows run into a numbered gate - the points that open the
		# next - and out of it to the next column's, lit in the tree's tone once reached
		lane["rails"] = []
		var conn := Control.new()
		conn.size = Vector2(Pal.GRID_W, LANE_H)
		conn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		conn.draw.connect(_draw_gates.bind(k))
		p.add_child(conn)
		lane["conn"] = conn
		lane["gate_at"] = []                # [{x, y, n, lit}] as drawn, for the tests
		for i in range(LANE_NODES):
			var btn := Button.new()
			btn.text = ""
			btn.focus_mode = Control.FOCUS_ALL
			btn.position = Vector2(TILES_X, y + 6)
			btn.size = Vector2(NODE, NODE)
			btn.pressed.connect(_pick_at.bind(k, i))
			add_child(btn)
			var t := {"button": btn, "id": "", "kind": ""}
			var g := TextureRect.new()
			g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			g.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			g.mouse_filter = Control.MOUSE_FILTER_IGNORE
			g.size = Vector2(GLYPH, GLYPH)
			g.pivot_offset = g.size / 2.0
			btn.add_child(g)
			t["glyph"] = g
			# the cost on the tile's corner and a joint's half mark under it: beside the tile, not on it (a diamond turns)
			t["more"] = UI.label(self, Rect2(0, 0, COST_W, 23), "", "SemiBold", 13, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, false)
			t["more"].add_theme_stylebox_override("normal", UI.box(Pal.BG, 9, 1, Pal.CARD_LINE))
			t["more"].mouse_filter = Control.MOUSE_FILTER_IGNORE
			t["joint"] = UI.label(self, Rect2(0, 0, 22, 23), "⇄", "SemiBold", 15, Pal.BAD, HORIZONTAL_ALIGNMENT_CENTER, false)
			t["joint"].mouse_filter = Control.MOUSE_FILTER_IGNORE
			t["joint"].visible = false
			# the old tile's words, kept empty: the node's words are the panel's (9 Oct)
			t["name"] = UI.label(btn, Rect2(0, 0, 1, 23), "", "Regular", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			t["effect"] = UI.label(btn, Rect2(0, 0, 1, 23), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			t["name"].visible = false
			t["effect"].visible = false
			lane["tiles"].append(t)
		_lanes.append(lane)
	for k in [0, 2]:
		var y: float = lane_y(k) + LANE_H
		var bar := UI.panel(self, Rect2(link_x() - 1.5, y - 2, 3, LINK_H + 4), UI.box(Pal.CARD_LINE, 1))
		var chip := UI.panel(self, Rect2(TILES_X, y + 1, 10, LINK_H - 2), UI.box(Pal.PANEL, 9, 1, Pal.CARD_LINE))
		var l := UI.label(chip, Rect2(10, 0, 10, LINK_H - 2), "", "SemiBold", 14, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		_links.append({"bar": bar, "chip": chip, "label": l})


func _build_also() -> void:
	_also_panel = UI.panel(self, Rect2(0, ALSO_Y, Pal.GRID_W, ALSO_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_also_head = UI.head(_also_panel, Rect2(PAD, 0, ALSO_HEAD_W, ALSO_H), "Also")
	for k in range(ALSO_MAX):
		var b := UI.button(_also_panel, Rect2(PAD + ALSO_HEAD_W, 5, 100, ALSO_H - 10), false)
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT)
		b.pressed.connect(_pick_also_at.bind(k))
		b.visible = false
		_also.append({"button": b, "name": ""})


func _build_pages() -> void:
	for k in range(PAGE_CELLS):
		var b := Button.new()
		b.text = ""
		b.focus_mode = Control.FOCUS_ALL
		b.visible = false
		b.pressed.connect(_turn_page)
		add_child(b)
		var c := {"button": b, "lines": []}
		c["name"] = UI.label(b, Rect2(PAD, 2, PAGE_W - 2 * PAD, NAME_H - 2), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		for j in range(3):
			c["lines"].append(UI.label(b, Rect2(PAD, NAME_H - 4 + j * WORD_H, PAGE_W - 2 * PAD, WORD_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		_cells.append(c)


func _build_panel() -> void:
	_panel = UI.panel(self, Rect2(0, PANEL_Y, Pal.GRID_W, PANEL_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	# the detail as a strip: the title, its chip and its sentence on one line, the buttons and the runners before on the second
	_title = UI.label(_panel, Rect2(PAD, 10, Pal.GRID_W - 2 * PAD, 34), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_chips = Chips.new(600)
	_chips.position = Vector2(PAD, 14)
	_panel.add_child(_chips)
	_words = UI.label(_panel, Rect2(PAD, 13, Pal.GRID_W - 2 * PAD, 28), "", "Regular", Pal.FLOOR - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_words2 = UI.label(_panel, Rect2(PAD, WORDS_UNDER_Y + 28, Pal.GRID_W - 2 * PAD, 28), "", "Regular", Pal.FLOOR - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var by: float = PANEL_H - 12 - Pal.BUTTON_H
	_past = UI.label(_panel, Rect2(PAD, by, Pal.GRID_W - 2 * PAD - 520, Pal.BUTTON_H), "", "Regular", Pal.FLOOR - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_train = UI.button(_panel, Rect2(0, by, 200, Pal.BUTTON_H), true)
	_train.pressed.connect(_on_train)
	_respec = UI.button(_panel, Rect2(0, by, 240, Pal.BUTTON_H), false)
	_respec.pressed.connect(_on_respec)
	_ascend = UI.button(_panel, Rect2(0, by, 240, Pal.BUTTON_H), false)
	_ascend.pressed.connect(func(): ascend.emit())
	_ascend.visible = false
	_retire = UI.button(_panel, Rect2(0, by, 240, Pal.BUTTON_H), false)
	_retire.pressed.connect(func(): retire.emit())
	_retire.visible = false


const EFFECT_WORDS := {
	"damage_pct": "+%d%% damage", "hp": "+%d max HP", "loot_pct": "+%d%% quantity", "search_pct": "Search %d%% faster",
	"first_pct": "First shot +%d%%", "patrol_pct": "Gangs %d%% later", "armour_pct": "Armour +%d%%", "heal_pct": "Meds +%d%%",
	"med_speed_pct": "Meds %d%% quicker", "med_cap": "+%d med carried", "rest_pct": "Rest +%d%%", "treat_pct": "Treatment −%d%%",
	"att_share": "+%d%% attachments", "sell_pct": "Fence pays +%d%%", "cash_pct": "Tins +%d%%", "rarity": "+%d%% quality",
	"pace_pct": "+%d%% pace", "damage_low_pct": "+%d%% dmg under ½ HP",
	"conv_fire_pct": "%d%% as fire", "conv_frost_pct": "%d%% as frost", "conv_poison_pct": "%d%% as poison", "conv_shock_pct": "%d%% as shock", "conv_bleed_pct": "%d%% as bleed",
	"fire_pct": "+%d%% fire", "frost_pct": "+%d%% frost", "poison_pct": "+%d%% poison", "shock_pct": "+%d%% shock", "bleed_pct": "+%d%% bleed", "physical_pct": "+%d%% physical",
	"dot_pct": "+%d%% dots", "phys_pen": "Ignores %d%% resist",
}
const TYPE_WORDS := {"rifle": "rifles", "shotgun": "shotguns", "smg": "SMGs", "improvised": "improvised", "pistol": "pistols", "melee": "melee"}
## The panel's sentence for a plain node: what happens, in words; the figure is the chip's (Caravan-E, 7 Oct).
const PANEL_WORDS := {
	"damage_pct": "Every shot hits harder, whatever is in hand.", "hp": "More to lose before a bail-out.", "loot_pct": "Every search turns up a little more.",
	"search_pct": "The picking-over goes quicker.", "first_pct": "The opening shot on every gang hits harder.", "patrol_pct": "The next gang takes longer to arrive.",
	"armour_pct": "Less of every hit gets through.", "heal_pct": "Every med heals more.", "med_speed_pct": "Every med works quicker.", "med_cap": "One more pouch on the rig.",
	"rest_pct": "Resting at the Yard heals faster.", "treat_pct": "The Clinic charges less.", "att_share": "Gun parts count for more.",
	"sell_pct": "The Fence pays more for what you sell.", "cash_pct": "Every run's take is bigger.", "rarity": "Rarer things turn up.",
	"pace_pct": "The fight and the search go quicker.", "damage_low_pct": "Under half HP, every shot hits harder.",
	"conv_fire_pct": "A share of every hit lands as fire and keeps burning.", "conv_frost_pct": "A share of every hit lands as frost and slows them.", "conv_poison_pct": "A share of every hit lands as poison and keeps working.",
	"conv_shock_pct": "A share of every hit lands as shock.", "conv_bleed_pct": "A share of every hit lands as bleed and keeps bleeding.",
	"fire_pct": "Fire hits harder.", "frost_pct": "Frost hits harder.", "poison_pct": "Poison hits harder.", "shock_pct": "Shock hits harder.",
	"bleed_pct": "Bleed hits harder.", "physical_pct": "The plain share of every hit, the part not converted, hits harder.", "dot_pct": "Burns, poison and bleeds all do more.",
}


## A node's type as words: "rifles", "shotguns and melee".
static func type_words(nd: Dictionary) -> String:
	if not nd.has("type"):
		return ""
	var ty = nd["type"]
	var list: Array = ty if ty is Array else [ty]
	var out: Array = []
	for t in list:
		out.append(TYPE_WORDS.get(t, str(t)))
	return " and ".join(out)


## The chip's tone for a node's figure: an element's colour for its damage or conversion, the accent for a
## notable, keystone or capstone, green for a plain bonus.
static func _effect_tone(nd: Dictionary) -> Color:
	if nd.get("capstone", false) or nd.get("keystone", false) or nd.get("notable", false):
		return Pal.ACCENT
	var e: String = str(nd.get("effect", ""))
	for el in Pal.ELEMENT_COLOURS:
		if e.begins_with("conv_" + el) or e.begins_with(el + "_pct"):
			return Pal.ELEMENT_COLOURS[el]
	return Pal.GOOD


## The sentence under a node: its own words for a notable, keystone or capstone; the effect's for a plain one.
static func _sentence(nd: Dictionary) -> String:
	if nd.has("words"):
		var w: String = str(nd["words"])
		return w if w.ends_with(".") or w.ends_with("!") else w + "."
	return str(PANEL_WORDS.get(nd["effect"], ""))


## The panel's chip: a notable with a figure shows the figure; a keystone or capstone its kind; a plain node its figure.
static func _chip_words(nd: Dictionary) -> String:
	if nd.get("capstone", false):
		return "Capstone"
	if nd.get("keystone", false):
		return "Keystone"
	if EFFECT_WORDS.has(nd.get("effect", "")) and nd.has("value"):
		return EFFECT_WORDS[nd["effect"]] % nd.get("value", 0)
	return "Notable"


## A plain node's figure, with its type: "+10% fire, SMGs".
static func _effect_words(nd: Dictionary) -> String:
	if nd.get("capstone", false):
		return "Capstone"
	if nd.get("keystone", false):
		return "Keystone"
	var w: String = EFFECT_WORDS[nd["effect"]] % nd.get("value", 0) if EFFECT_WORDS.has(nd.get("effect", "")) else "Notable"
	if nd.has("type"):
		w += ", " + type_words(nd)
	return w


## The colour of a tree's lane: its element's, the accent for a class's, the line for the Yard's.
static func lane_colour(t: Dictionary) -> Color:
	if t.has("element"):
		return Pal.ELEMENT_COLOURS.get(t["element"], Pal.TEXT)
	if t.get("class", "") != "":
		return Pal.ACCENT
	return Pal.CARD_LINE


## A joint's colour: its element tree's.
static func joint_colour(j: Dictionary) -> Color:
	return lane_colour(Data.tree_named(j["element_tree"]))


## The drawer's and the shelf's cards: as the tiles were before the glyphs (a found one lit with the accent's bar).
func _style_card(b: Button, look: String) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var sb: StyleBoxFlat
		if look == "taken":
			sb = UI.box(Pal.SELECT, 6)
			sb.border_width_left = 5
			sb.border_color = Pal.ACCENT
		else:
			sb = UI.box(Pal.BG, 6)
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 6, 2, Pal.TEXT))


func _style(b: Button, look: String, edge := Color.TRANSPARENT, kind := "node", tone := Pal.ACCENT, picked := false) -> void:
	# "taken": filled in the tree's tone, edged with it; "idle": taken, not working, edged grey; "open": trainable,
	# a light edge; "locked": dim. A notable is round, a keystone or capstone a diamond (the button turned), a
	# plain node square; a notable or keystone carries its tree's tone on its edge; a joint's half its joint's;
	# the picked one is ringed white (9 Oct, Tree-G A)
	var radius: int = int(b.size.x / 2.0) if kind == "notable" else (5 if kind in ["keystone", "capstone"] else 8)
	var big: bool = kind != "node"
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var bg: Color
		var line: Color
		var w := 1
		match look:
			"taken":
				bg = Pal.CARD.lerp(tone, 0.22)
				line = tone
				w = 2
			"idle":
				bg = Pal.CARD
				line = Pal.TEXT_3
				w = 2
			"open":
				bg = Pal.BUTTON if state in ["hover", "hover_pressed"] else Pal.CARD
				line = tone if big else Pal.TEXT_2
				w = 2 if big else 1
			_:
				bg = Pal.BG
				line = Color(tone, 0.45) if big else Pal.CARD_LINE
		if edge != Color.TRANSPARENT and look != "taken":
			line = edge
			w = 2
		if picked:
			line = Pal.TEXT
			w = 3
		b.add_theme_stylebox_override(state, UI.box(bg, radius, w, line))
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, radius, 2, Pal.TEXT))


# ------------------------------------------------------------------ the trees on show

## The five lanes' trees, top to bottom (nulls where there's none): the class's first tree, the element its
## joint is in, the class's second, its element, then the Yard's or the Also chip in its place. No class
## yet: the Yard's alone, in the first lane.
func lane_trees() -> Array:
	var out: Array = [null, null, null, null, null]
	var on_show: Array = sim.trees()
	var yard: Dictionary = Data.tree_named(Data.COMMON_TREE)
	var fifth = yard
	if alt != "" and not _is_pages(alt):
		for t in on_show:
			if t["name"] == alt:
				fifth = t
	if sim.cls == "":
		out[0] = fifth
		return out
	var mine: Array = []
	for t in Data.TREES:
		if t.get("class", "") == sim.cls:
			mine.append(t)
	for k in range(mini(2, mine.size())):
		out[2 * k] = mine[k]
		var j: Dictionary = Data.joint_in(sim.cls, mine[k]["name"])
		if not j.is_empty():
			out[2 * k + 1] = Data.tree_named(j["element_tree"])
	out[4] = fifth
	return out


## The Also row's chips: every tree on show that isn't in a lane, then the drawer and the shelf.
func also_names() -> Array:
	var lanes_now: Array = []
	var saved := alt
	alt = ""
	for t in lane_trees():
		if t != null:
			lanes_now.append(t["name"])
	alt = saved
	var out: Array = []
	for t in sim.trees():
		if not (t["name"] in lanes_now) and not (t["name"] in out):
			out.append(t["name"])
	out.append("The drawer")
	out.append("The shelf")
	out.append("The radio")
	return out


static func _is_pages(name: String) -> bool:
	return name == "The drawer" or name == "The shelf" or name == "The radio"


## The pages over the lanes, by the Also chip's name.
func _branch_for(name: String) -> Dictionary:
	if name == "The drawer":
		return _drawer_branch()
	if name == "The radio":
		return _radio_branch()
	return _shelf_branch()


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	if _armed != "" and (sim.cls != _armed_cls or sim.on_mission()):
		_armed = ""
	var sig := "%s|%s|%d|%d|%s|%s|%s|%s|%d|%d|%d|%s|%d|%s|%s|%d|%s|%d|%s" % [selected, str(sim.tree), sim.training_points, int(sim.cash), sim.cls, str(sim.on_mission()), alt, sim.cls2, sim.book.size() * 1000 + sim.heard.size(), drawer_page, sim.shelf.size(),
		sim.gun_type(), sim.level(), str(sim.trades), _armed, int(sim.elapsed / 60.0), sim.has_rule("qm_manual"), sim.past.size(), str(sim.shelf_tier)]   # the gun in hand idles typed nodes; the level opens the second past; a trade opens a top; prices inflate by the minute
	if sig == _shown:
		return
	_shown = sig
	if alt != "" and not (alt in also_names()):
		alt = ""                           # the chip went (a class change took that tree into a lane)
	_show_head()
	var pages: bool = _is_pages(alt)
	var lanes: Array = lane_trees()
	for k in range(LANES):
		_show_lane(k, null if pages else lanes[k])
	_show_links(lanes, pages)
	_show_pages(pages)
	_show_also()
	_show_sum(lanes if not pages else [])
	_show_panel()


func _show_head() -> void:
	var cd: Dictionary = sim.class_data()
	var td: Dictionary = sim.trait_data()
	var faced := People.show(_face, sim.cls)
	_face.visible = faced
	var who: String = str(cd.get("name", "No past yet"))
	UI.fit(_kicker, [("%s · %s · The Caravan" % [who, td["name"]]) if not td.is_empty() else "%s · The Caravan" % who, ("%s · %s" % [who, td["name"]]) if not td.is_empty() else who, who])
	var free: int = sim.points_free()
	_points.text = "%d of %d" % [free, sim.training_points]
	_points.add_theme_color_override("font_color", Pal.ACCENT if free > 0 else Pal.TEXT_2)
	_unit.position.x = _points.position.x + ceilf(UI.text_width(_points, _points.text)) + 10
	_unit.size.x = _kicker.position.x + _kicker.size.x - _unit.position.x
	UI.fit(_unit, ["point%s free" % ("" if sim.training_points == 1 else "s"), "free", ""])
	UI.fit(_class_line, [str(cd.get("words", "")), ""] if not cd.is_empty() else ["Pick a past: what the runner was, and how they fight now", "Pick a past", ""])
	for k in range(Data.CLASSES.size()):
		var cb: Button = _class_buttons[k]
		var name: String = Data.CLASSES[k]["name"]
		cb.text = ("%s ✓" % name) if sim.cls == name else (("%s ?" % name) if _armed == name else name)
		cb.disabled = sim.on_mission() or name == sim.cls2     # the second past's class is taken already
		UI.style_button(cb, sim.cls == name or _armed == name)
	_notice.add_theme_color_override("font_color", Pal.TEXT)
	if _armed != "":
		var cost: int = sim.class_change_cost(_armed)
		_notice.add_theme_color_override("font_color", Pal.ACCENT if sim.cash >= cost else Pal.BAD)
		if sim.cash >= cost:
			UI.fit(_notice, ["Change to %s: %s, the respec of what it gives back — press again" % [_armed, Fmt.money(cost)], "Change to %s: %s — press again" % [_armed, Fmt.money(cost)], "%s — press again" % Fmt.money(cost)])
		else:
			UI.fit(_notice, ["Change to %s: %s — %s short" % [_armed, Fmt.money(cost), Fmt.money(cost - int(sim.cash))], "%s: %s short" % [_armed, Fmt.money(cost - int(sim.cash))]])
	elif sim.cls == "":
		UI.fit(_notice, ["Free to pick for a new runner; a change after costs the respec of the class's trees", "Free to pick for a new runner", ""])
	elif not td.is_empty():
		UI.fit(_notice, ["%s: %s · one a runner" % [td["name"], td["words"]], "%s: %s" % [td["name"], td["words"]], td["name"]])
	else:
		_notice.text = ""
	_lay_lines()


## The class's line and the notice, bottom up: a lone line sits just over the classes, where the notice would; each
## line that has words gets its pill, fitted to them.
func _lay_lines() -> void:
	_class_line.position.y = LINE_TOP_Y if _notice.text != "" else NOTICE_Y + (_notice.size.y - _class_line.size.y) / 2.0
	var lines: Array[Label] = [_class_line, _notice]
	for k in range(2):
		var l: Label = lines[k]
		var pill: Panel = _line_pills[k]
		pill.visible = l.visible and l.text != ""
		if not pill.visible:
			continue
		var w: float = ceilf(UI.text_width(l, l.text)) + 2 * PILL_PAD
		var right: float = l.position.x + l.size.x + PILL_PAD
		pill.position = Vector2(right - w, l.position.y + (l.size.y - PILL_H) / 2.0)
		pill.size = Vector2(w, PILL_H)


func _show_lane(k: int, t) -> void:
	var lane: Dictionary = _lanes[k]
	lane["tree"] = t
	lane["panel"].visible = t != null
	for tile in lane["tiles"]:
		tile["button"].visible = false
		tile["more"].visible = false
		tile["joint"].visible = false
		tile["id"] = ""
	if t == null:
		return
	var y := lane_y(k)
	var colour := lane_colour(t)
	(lane["bar"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = colour
	UI.fit(lane["name"], [t["name"]])
	var mine: Array = sim.my_classes()
	if t.has("element"):
		var j: Dictionary = {}
		for c in mine:
			if j.is_empty():
				j = Data.joint_in(c, t["name"])
		if not j.is_empty():
			UI.fit(lane["tag"], ["%s · joins %s" % [t["element"], j["tree"]], "%s · %s" % [t["element"], j["tree"]], t["element"]])
		else:
			UI.fit(lane["tag"], ["%s · double" % t["element"] if not sim.affinity(t["element"]) else t["element"], t["element"]])
	elif t.get("class", "") != "":
		UI.fit(lane["tag"], ["the %s's" % t["class"].to_lower(), t["class"]])
	else:
		UI.fit(lane["tag"], ["the Yard's · kept", "the Yard's"])
	lane["tag"].add_theme_color_override("font_color", colour if colour != Pal.CARD_LINE else Pal.TEXT_2)
	var pts: int = sim.points_in(t["name"])
	var next_gate := -1
	for c in range(COLS):
		var g: int = Data.gate(t, c, mine)
		if g > pts:
			next_gate = g
			break
	UI.fit(lane["gates"], ["%d point%s in" % [pts, "" if pts == 1 else "s"], "%d in" % pts])     # the gates say what opens next (Tree-J B)
	_lay_gates(k)
	lane["conn"].queue_redraw()
	var taken := 0
	var per_col := {}
	for nd in t["nodes"]:
		per_col[int(nd.get("col", 0))] = int(per_col.get(int(nd.get("col", 0)), 0)) + 1
	# a joint's halves meet at the line that joins them (Matt, 10 Oct): the upper lane's on its bottom row, the lower
	# lane's on its top row - the column's other node takes the row it leaves
	var rows := {}
	for i in range(t["nodes"].size()):
		rows[i] = int(t["nodes"][i].get("row", 0))
	if k < 4:
		var want: int = 1 if k % 2 == 0 else 0
		# only this pair's joint: a second past's half in the same column stays off the line (the reviewer, 10 Oct)
		var pair: Dictionary = Data.joint_in(sim.cls, t["name"])
		for i in range(t["nodes"].size()):
			var nj: Dictionary = t["nodes"][i]
			if not pair.is_empty() and str(nj.get("joint", "")) == str(pair["key"]) and rows[i] != want:
				for o in range(t["nodes"].size()):
					if o != i and int(t["nodes"][o].get("col", 0)) == int(nj.get("col", 0)):
						rows[o] = rows[i]
				rows[i] = want
	lane["rows"] = rows
	lane["marked"] = {}     # "col:y" of each shown joint mark, so its rail stops at the mark
	for i in range(mini(t["nodes"].size(), LANE_NODES)):
		var nd: Dictionary = t["nodes"][i]
		var id := "%s/%d" % [t["name"], i]
		var tile: Dictionary = lane["tiles"][i]
		var b: Button = tile["button"]
		var c: int = int(nd.get("col", 0))
		var span: bool = int(per_col.get(c, 0)) == 1
		var kind: String = "capstone" if nd.get("capstone", false) else ("keystone" if nd.get("keystone", false) else ("notable" if nd.get("notable", false) else "node"))
		var rc := node_rect(c, int(rows[i]), span, kind)
		b.position = Vector2(rc.position.x, y + rc.position.y)
		b.size = rc.size
		b.pivot_offset = rc.size / 2.0
		b.rotation_degrees = 45.0 if kind in ["keystone", "capstone"] else 0.0
		b.visible = true
		tile["id"] = id
		tile["kind"] = kind
		var g: TextureRect = tile["glyph"]
		g.texture = NodeGlyphs.texture(NodeGlyphs.of(nd))
		g.position = (rc.size - g.size) / 2.0
		g.rotation_degrees = -b.rotation_degrees
		var is_taken: bool = sim.tree.has(id)
		if is_taken:
			taken += 1
		var theirs: bool = not Data.for_classes(nd, mine)
		var block: String = sim.train_block(id, true)
		var reach: bool = not is_taken and block == ""
		var look := ("taken" if sim.node_active(id) else "idle") if is_taken else ("open" if reach else "locked")
		var j_key: String = str(nd.get("joint", ""))
		var edge := Color.TRANSPARENT
		if j_key != "" and not theirs:
			edge = joint_colour(Data.joint(j_key))
		var tone: Color = colour if colour != Pal.CARD_LINE else YARD_TONE
		_style(b, look, edge, kind, tone, id == selected)
		g.modulate = tone if look == "taken" else (Pal.TEXT if look == "open" else Pal.TEXT_3)
		# the cost on the corner (a tick once trained); another class's half says nothing - the panel names it
		var cost: int = sim.node_cost(id)
		var more: Label = tile["more"]
		more.text = "✓" if is_taken else str(cost)
		more.add_theme_color_override("font_color", Pal.GOOD if is_taken else (Pal.ACCENT if reach else Pal.TEXT_3))
		var half: float = rc.size.x * (0.71 if kind in ["keystone", "capstone"] else 0.5)     # a diamond's half-width is its half-diagonal
		more.position = Vector2(b.position.x + rc.size.x / 2.0 + half + 3.0, b.position.y + rc.size.y / 2.0 - half - 2.0)     # beside the tile's top right, never on a tile
		more.visible = true
		tile["joint"].visible = edge != Color.TRANSPARENT
		if tile["joint"].visible:
			lane["marked"]["%d:%d" % [c, int(round(rc.position.y + rc.size.y / 2.0))]] = true     # lane-local, as rows_at
		tile["joint"].position = Vector2(b.position.x + rc.size.x / 2.0 - half - 24.0, b.position.y + rc.size.y / 2.0 - 11.5)     # at its left, clear of the tile
		tile["joint"].add_theme_color_override("font_color", edge if edge != Color.TRANSPARENT else Pal.BAD)
		tile["name"].text = ""
		tile["effect"].text = ""
	UI.fit(lane["count"], ["%d of %d trained" % [taken, t["nodes"].size()], "%d of %d" % [taken, t["nodes"].size()]])


## A node's name cut to its first word when the tile won't take it.
static func _short_name(name: String) -> String:
	var words: PackedStringArray = name.split(" ", false)
	if words.size() > 2 and words[0].length() <= 3:
		return "%s %s" % [words[0], words[1]]      # "The long ..." keeps its noun: "The long", never "The"
	return words[0] if words.size() > 1 else name


## The two links: under a class lane, to its element's lane, in the fourth column. Solid and filled when the
## joint's closed; dim when it's open, with whose halves they are.
func _show_links(lanes: Array, pages: bool) -> void:
	for n in range(2):
		var link: Dictionary = _links[n]
		var a = lanes[2 * n]
		var b = lanes[2 * n + 1]
		var j: Dictionary = {} if (pages or a == null or b == null) else Data.joint_in(sim.cls, a["name"])
		var on: bool = not j.is_empty() and j["element_tree"] == b["name"]
		for key in ["bar", "chip"]:
			link[key].visible = on
		if not on:
			continue
		var closed: bool = sim.has_joint(j["key"])
		var colour := joint_colour(j)
		(link["bar"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = colour if closed else Color(colour, 0.4)
		var halves := _halves(j)
		var room: float = link_x() - 10.0 - TILES_X - 20.0
		var l: Label = link["label"]
		l.size.x = room
		if closed:
			UI.fit(l, ["⇄ JOINED · " + str(j["words"]), "⇄ JOINED · " + str(j["words"]).get_slice(":", 0).get_slice(";", 0), "⇄ JOINED"])
		else:
			UI.fit(l, ["⇄ OPEN · %s and %s, one half each: %s" % [halves[0], halves[1], str(j["words"]).to_lower()], "⇄ OPEN · %s and %s, one half each" % halves, "⇄ OPEN · one half each", "⇄ OPEN"])
		l.add_theme_color_override("font_color", Pal.ACCENT_TEXT if closed else colour)
		var w: float = ceilf(UI.text_width(l, l.text)) + 20.0
		var chip: Panel = link["chip"]
		chip.size.x = w
		chip.position.x = link_x() - 10.0 - w
		l.size.x = w - 20.0
		var sb: StyleBoxFlat = chip.get_theme_stylebox("panel")
		sb.bg_color = colour if closed else Pal.PANEL
		sb.border_color = colour


## A joint's two halves' names: the class tree's, the element tree's.
static func _halves(j: Dictionary) -> Array:
	var out: Array = ["", ""]
	var k := 0
	for tn in [j["tree"], j["element_tree"]]:
		var t := Data.tree_named(tn)
		for nd in t.get("nodes", []):
			if str(nd.get("joint", "")) == j["key"]:
				out[k] = nd["name"]
		k += 1
	return out


func _show_also() -> void:
	var names: Array = also_names()
	var x: float = PAD + ALSO_HEAD_W
	var right: float = Pal.GRID_W - PAD
	for k in range(ALSO_MAX):
		var a: Dictionary = _also[k]
		var b: Button = a["button"]
		if k >= names.size():
			b.visible = false
			a["name"] = ""
			continue
		var name: String = names[k]
		a["name"] = name
		var t := Data.tree_named(name)
		var words := name
		var short := name
		if t.has("element"):
			words = "%s · %s" % [name, t["element"]]
		elif t.get("class", "") != "":
			words = "%s · %s" % [name, t["class"].to_lower()]
		elif _is_pages(name):
			# the drawer and the shelf carry their counts, and the page when one's open over the lanes
			var br0: Dictionary = _branch_for(name)
			var found: int = int(br0["found"])
			var total: int = int(br0["total"])
			words = "%s · %d of %d" % [name, found, total]
			if alt == name:
				var br: Dictionary = br0
				if int(br["pages"]) > 1:
					words += " · page %d of %d" % [int(br["page"]) + 1, int(br["pages"])]
			short = "%s %d/%d" % [name.get_slice(" ", 1).capitalize(), found, total]
		var w: float = ceilf(UI.text_width(b, words)) + 36.0
		if x + w > right:
			words = short
			w = ceilf(UI.text_width(b, words)) + 36.0
		b.visible = x + w <= right
		b.text = words
		b.position.x = x
		b.size.x = w
		UI.style_button(b, alt == name)
		x += w + 8.0


## The drawer or the shelf over the lanes' area: three columns of cards, a page at a time; a click turns it.
func _show_pages(on: bool) -> void:
	if not on:
		for c in _cells:
			c["button"].visible = false
		return
	var branch: Dictionary = _branch_for(alt)
	var row_h: int = branch["row_h"]
	var lines: int = branch["lines"]
	var rows: int = branch["rows"]
	for k in range(PAGE_CELLS):
		var c: Dictionary = _cells[k]
		var b: Button = c["button"]
		if k >= branch["nodes"].size():
			b.visible = false
			continue
		var nd: Dictionary = branch["nodes"][k]
		b.visible = true
		b.position = Vector2((k / rows) * (PAGE_W + PAGE_GAP), LANES_Y + (k % rows) * (row_h + PAGE_GAP))
		b.size = Vector2(PAGE_W, row_h)
		c["name"].add_theme_font_override("font", UI.font("SemiBold" if nd["words"] != "" and not nd.get("gap", false) else "Regular", false))
		for j in range(3):
			c["lines"][j].visible = j < lines
			c["lines"][j].text = ""
		if nd["words"] == "":
			UI.wrap([c["name"]] + c["lines"].slice(0, lines), nd["name"])
		else:
			UI.fit(c["name"], [nd["name"]])
			UI.wrap(c["lines"].slice(0, lines), nd["words"])
		_style_card(b, "taken" if nd["words"] != "" and not nd.get("gap", false) else "locked")
		c["name"].add_theme_color_override("font_color", Pal.TEXT_3 if nd.get("gap", false) else Pal.TEXT)


## The drawer: every paper in the story's order (12 Oct, the lore pass: read like a book), the found ones with their
## words, the rest a gap that says where it's found; a page at a time.
func _drawer_branch() -> Dictionary:
	var pages: Array = sim.book_pages()
	var branch := _pages_branch("The drawer", pages, pages.size(), Words.BOOK["empty"], func(name): return Words.item_words(name) if name in sim.book else _paper_gap(name), 2)
	for nd in branch["nodes"]:
		nd["gap"] = not (str(nd["name"]).substr(str(nd["name"]).find(" ") + 1) in sim.book)
	branch["found"] = sim.book.size()
	return branch


## Where an unfound paper turns up: its one site, or the depth it's found from.
func _paper_gap(name: String) -> String:
	var site: String = Items.exclusive_to(name)
	if site != "":
		return Words.BOOK["gap_site"] % Words.mid(site)
	var d: int = int(Items.base_named(Data.PAPER, name).get("depth", 0))
	return Words.BOOK["gap_deep"] % d if d > 0 else Words.BOOK["gap"]


## The radio (12 Oct, the lore pass): every line heard, in the order heard, under its voice.
func _radio_branch() -> Dictionary:
	return _pages_branch("The radio", sim.heard, Words.RADIO.size(), Words.HEARD["empty"],
		func(key): return str(sim.radio_line(key).get("text", "")), 3,
		func(key): return str(Words.RADIO_VOICES.get(sim.radio_line(key).get("voice", ""), "")))


## The shelf: the chase first (endgame part 3) - the nine sites' own, the heads' charms, the Lorry's Load, a
## gap each until found, with where it is under the gap - then the rest found, in the order found.
func _shelf_branch() -> Dictionary:
	var chase: Array = sim.shelf_chase()
	var names: Array = []
	var gaps := {}
	for c in chase:
		names.append(c["name"])
		if not c["found"]:
			gaps[c["name"]] = c["where"]
	for name in sim.shelf:
		if not (name in names):
			names.append(name)
	var branch := _pages_branch("The shelf", names, Data.UNIQUES.size(), Words.SHELF["empty"],
		func(name): return gaps[name] if gaps.has(name) else _shelf_words(name), 3)
	for nd in branch["nodes"]:
		nd["gap"] = gaps.has(str(nd["name"]).substr(str(nd["name"]).find(" ") + 1))
	branch["found"] = sim.shelf.size()
	return branch


## A found unique's words on the shelf: the best tier of it found first (12 Oct, uniques by tier), then who it was.
func _shelf_words(name: String) -> String:
	var t: int = int(sim.shelf_tier.get(name, 0))
	return ("Best T%d. " % t if t > 0 else "") + str(Words.UNIQUES.get(name, ""))


## A page of a list: a card a name with `lines` of words under it, as many as the lanes' area takes.
func _pages_branch(title: String, list: Array, total: int, empty: String, words: Callable, lines: int, label := Callable()) -> Dictionary:
	var row_h: int = NAME_H + lines * WORD_H + 4
	var rows: int = maxi(1, (LANES_H + PAGE_GAP) / (row_h + PAGE_GAP))
	var per: int = mini(PAGE_CELLS, rows * PAGE_COLS)
	var pages: int = maxi(1, ceili(float(list.size()) / per))
	var page: int = drawer_page % pages
	var nodes: Array = []
	var start: int = page * per
	for k in range(start, mini(list.size(), start + per)):
		nodes.append({"name": "%d. %s" % [k + 1, (str(label.call(list[k])) if label.is_valid() else str(list[k]))], "words": str(words.call(list[k]))})
	if nodes.is_empty():
		nodes.append({"name": empty, "words": ""})
	return {"name": title, "drawer": true, "nodes": nodes, "pages": pages, "page": page, "found": list.size(), "total": total, "lines": lines, "row_h": row_h, "rows": rows}


## What the trees add up to (9 Oct, option A): every trained tree's figures, as the fight reads them; the elements in play -
## each the share of the hit the trees convert to it and the increase they give it, notables included, in its
## colour; the dots; the joints closed of the runner's. A plain figure at nothing is left off; when the row is
## still too long the plain figures go from the least telling up (SUM_DROP), never an element's or the joints'.
const SUM_DROP := ["Search", "Quantity", "First shot", "Quality", "Gangs", "Max HP", "Damage"]
func _show_sum(lanes: Array) -> void:
	_sum_chips.show_chips(sum_items(lanes), SUM_ROWS)


## The strip's items at their long forms, nothing cut to fit (for the tests).
func sum_items_raw() -> Array:
	return sum_items([], false)


func sum_items(_lanes: Array, fit := true) -> Array:
	# every figure from every trained tree, notables and "also" figures included, typed ones only with their gun in
	# hand (9 Oct, Matt: "may as well be consistent" - Spray's +25% was left out while it counted in the fight)
	var sums := {}
	for e in ["damage_pct", "hp", "first_pct", "search_pct", "patrol_pct", "rarity", "loot_pct"]:
		sums[e] = sim.tree_sum(e)
	var items := []
	var plain := func(tag: String, value: float, words: String) -> void:
		if value > 0.0:
			items.append({"tag": tag, "forms": [words % value], "colour": Pal.GOOD})
	plain.call("Damage", sums.get("damage_pct", 0.0), "+%.0f%%")
	# the elements, in the order the trees list them, then the physical
	var converted := 0.0
	for el in Data.ELEMENTS:
		converted += sim.tree_sum("conv_%s_pct" % el)
	var scale: float = 100.0 / converted if converted > 100.0 else 1.0     # past the whole hit the shares are cut back together, as the fight does
	for el in Data.ELEMENTS:
		var conv: float = sim.tree_sum("conv_%s_pct" % el) * scale
		var inc: float = sim.tree_sum("%s_pct" % el)
		if conv <= 0.0 and inc <= 0.0:
			continue
		var forms: Array = []
		if conv > 0.0 and inc > 0.0:
			forms = ["%.0f%% of hits · +%.0f%%" % [conv, inc], "%.0f%% · +%.0f%%" % [conv, inc], "+%.0f%%" % inc]
		elif conv > 0.0:
			forms = ["%.0f%% of hits" % conv, "%.0f%%" % conv]
		else:
			forms = ["+%.0f%%" % inc]
		items.append({"tag": el.capitalize(), "forms": forms, "colour": Pal.ELEMENT_COLOURS.get(el, Pal.TEXT)})
	var phys_inc: float = sim.tree_sum("physical_pct")
	var pen: float = sim.tree_sum("phys_pen")
	var bust: bool = sim.has_node("bust_them_up")
	if phys_inc > 0.0 or pen > 0.0 or bust:
		var share: float = 100.0 if bust else maxf(0.0, 100.0 - converted * scale)
		var ignores: String = "ignores their armour" if bust else ("ignores %.0f%%" % pen if pen > 0.0 else "")
		# only the parts that are something (the reviewer's catch: a pen-only build read "+0%")
		var long: Array = []
		var mid: Array = []
		if share > 0.0:
			long.append("%.0f%% of hits" % share)
			mid.append("%.0f%%" % share)
		if phys_inc > 0.0:
			long.append("+%.0f%%" % phys_inc)
			mid.append("+%.0f%%" % phys_inc)
		if ignores != "":
			long.append(ignores)
		var short: String = ("+%.0f%%" % phys_inc) if phys_inc > 0.0 else (ignores if ignores != "" else str(mid[0]) if not mid.is_empty() else "")
		if short != "":
			if phys_inc <= 0.0 and ignores != "":
				mid = ([mid[0]] if not mid.is_empty() else []) + [ignores]     # no increase: what it ignores is the telling part
			items.append({"tag": "Physical", "forms": [" · ".join(long), " · ".join(mid) if not mid.is_empty() else short, short],
				"colour": Pal.ELEMENT_COLOURS.get("physical", Pal.TEXT)})
	# the dots: their increase, and what the notables do to them
	var dot_inc: float = sim.tree_sum("dot_pct")
	var extras: Array = []
	for pair in [["Petrol/3", "burns"], ["The rat man/3", "poison"], ["Blades/3", "bleeds"]]:
		if sim.tree.has(pair[0]):
			extras.append("%s ×2 long" % pair[1])          # Lit, Dosed, Opened up: the trees' own, not the kit's (dot_seconds reads both)
	if sim.has_node("poison_stacks"):
		extras.append("poison to 15")
	if sim.has_node("bleed_forever"):
		extras.append("bleeds don't fade")
	if dot_inc > 0.0 or not extras.is_empty():
		var head: String = ("+%.0f%%" % dot_inc) if dot_inc > 0.0 else ""
		var long: Array = ([head] if head != "" else []) + extras
		items.append({"tag": "Dots", "forms": [" · ".join(long), " · ".join(long.slice(0, 2)), long[0]], "colour": Pal.TEXT})
	plain.call("Max HP", sums.get("hp", 0.0), "+%.0f")
	plain.call("First shot", sums.get("first_pct", 0.0), "+%.0f%%")
	plain.call("Search", sums.get("search_pct", 0.0), "%.0f%% faster")
	plain.call("Gangs", sums.get("patrol_pct", 0.0), "%.0f%% later")
	plain.call("Quality", sums.get("rarity", 0.0), "+%.0f%%")
	plain.call("Quantity", sums.get("loot_pct", 0.0), "+%.0f%%")
	var joints := 0
	var closed := 0
	var on_show: Array = sim.trees().map(func(x): return x["name"])
	for j in Data.JOINTS:
		if j["class"] in sim.my_classes() and j["tree"] in on_show:     # a second past's joint in its second tree can't close
			joints += 1
			if sim.has_joint(j["key"]):
				closed += 1
	if joints > 0:
		items.append({"tag": "Joints", "forms": ["%d of %d" % [closed, joints]], "colour": Pal.ACCENT})
	if items.is_empty():
		items.append({"forms": ["Nothing trained yet"], "colour": Pal.TEXT_2})
	if not fit:
		return items
	# too long for the row: the middle forms ("80% · +52%"), then the plain figures but Damage and Max HP go to
	# keep them - the elements are what the strip is for; then the shortest forms, the plain going least telling first
	var tries: Array = [[0, 0]]
	for dropped in range(6):
		tries.append([1, dropped])
	for dropped in range(SUM_DROP.size() + 1):
		tries.append([2, dropped])
	var last_cut: Array = items
	for tr in tries:
		var level: int = tr[0]
		var gone: Array = SUM_DROP.slice(0, tr[1])
		var cut: Array = []
		for it in items:
			if str(it.get("tag", "")) in gone:
				continue
			var d: Dictionary = it.duplicate()
			var forms: Array = d["forms"]
			d["forms"] = forms.slice(mini(level, forms.size() - 1))
			cut.append(d)
		if _fits(cut):
			return cut
		last_cut = cut
	return last_cut                           # nothing fits: the shortest, plain figures gone - the elements and Joints go last


## Whether the items fit the strip's one row (the chips laid, then read back).
func _fits(items: Array) -> bool:
	_sum_chips.show_chips(items, SUM_ROWS)
	return _sum_chips.shown() == items.size()


func _show_panel() -> void:
	_train.visible = false
	_chips.visible = false
	_words.position = Vector2(PAD, 13)
	_words2.text = ""
	_words.size.x = Pal.GRID_W - 2 * PAD
	var after_title := func() -> void:
		_words.position.x = PAD + ceilf(UI.text_width(_title, _title.text)) + 14
		_words.size.x = Pal.GRID_W - PAD - _words.position.x
	if selected == "":
		var cd: Dictionary = sim.class_data()
		if cd.is_empty():
			_title.text = "No past yet"
			after_title.call()
			UI.fit(_words, ["Pick one above: what the runner was, and how they fight now. Free for a new runner", "Pick one above", ""])
		else:
			var td: Dictionary = sim.trait_data()
			_title.text = ("%s · %s" % [cd["name"], td["name"]]) if not td.is_empty() else "%s" % cd["name"]
			after_title.call()
			if not td.is_empty():
				UI.fit(_words, ["%s: %s · the runner's trait, one each, goes with them" % [td["name"], td["words"]], "%s: %s" % [td["name"], td["words"]], ""])
			else:
				_words.text = ""
	else:
		var nd: Dictionary = sim.node(selected)
		if nd.is_empty():
			selected = ""
			_show_panel()
			return
		_title.text = nd["name"] + (" · capstone" if nd.get("capstone", false) else (" · keystone" if nd.get("keystone", false) else (" · notable" if nd.get("notable", false) else "")))
		var is_taken: bool = sim.tree.has(selected)
		if is_taken:
			_title.text += " · trained" if sim.node_active(selected) else " · trained, idle"
		var items := [{"forms": [_chip_words(nd)], "colour": _effect_tone(nd)}]
		if nd.has("type"):
			items.append({"forms": [type_words(nd)], "colour": Pal.TEXT_2})
		_chips.visible = true
		_chips.show_chips(items)
		_chips.position.x = PAD + ceilf(UI.text_width(_title, _title.text)) + 14
		# the sentence under the title (10 Oct, Matt: the dead space there), the width the buttons leave (set below)
		_words.position = Vector2(PAD, WORDS_UNDER_Y)
		var sentence: String = _sentence(nd)
		var forms: Array = []
		var tail := ""
		var j_key: String = str(nd.get("joint", ""))
		if j_key != "" and Data.for_classes(nd, sim.my_classes()):
			var j := Data.joint(j_key)
			var halves := _halves(j)
			var other: String = halves[1] if nd["name"] == halves[0] else halves[0]
			var other_tree: String = j["element_tree"] if nd["name"] == halves[0] else j["tree"]
			tail = ("joined: %s" % str(j["words"]).to_lower()) if sim.has_joint(j_key) else ("with %s in %s: %s" % [other, other_tree, str(j["words"]).to_lower()])
		if is_taken and not sim.node_active(selected) and not sim._active(nd):
			tail = "idle without %s in hand" % type_words(nd)
		elif is_taken and not sim.node_active(selected):
			tail = "idle until a joint in %s closes again" % str(selected).get_slice("/", 0)
		var block: String = "" if is_taken else sim.train_block(selected, true)     # the points are the tree's and the button's to say (Matt, 10 Oct)
		var t2 := _as_sentence(tail)
		var b2 := _as_sentence(block)
		if tail != "" and block != "":
			forms = ["%s %s %s" % [sentence, t2, b2], "%s %s" % [sentence, b2], "%s %s" % [sentence, t2]]
		elif tail != "":
			forms = ["%s %s" % [sentence, t2]]
		elif block != "":
			forms = ["%s %s" % [sentence, b2]]
		forms.append_array([sentence, b2, ""])
		_node_forms = forms
		if not is_taken:
			_train.visible = true
			var cost: int = sim.node_cost(selected)
			_train.text = "Train (%d point%s)" % [cost, "" if cost == 1 else "s"]
			_train.disabled = not sim.can_train(selected)
			_train.size.x = ceilf(UI.text_width(_train, _train.text)) + 48
	_respec.text = "Respec for %s" % Fmt.money(sim.respec_cost())
	_respec.disabled = sim.tree.is_empty() or sim.cash < sim.respec_cost()
	_respec.size.x = ceilf(UI.text_width(_respec, _respec.text)) + 48
	var x := Pal.GRID_W - PAD
	x -= _respec.size.x
	_respec.position.x = x
	_ascend.visible = sim.cls != "" and (sim.can_ascend() or sim.cls2 != "")
	if _ascend.visible:
		_ascend.text = ("Second past: %s" % sim.cls2) if sim.cls2 != "" else "Take a second past"
		_ascend.disabled = not sim.can_ascend()
		_ascend.size.x = ceilf(UI.text_width(_ascend, _ascend.text)) + 48
		x -= 12 + _ascend.size.x
		_ascend.position.x = x
	_retire.visible = sim.cls != "" and sim.level() >= Data.RETIRE_LEVEL
	if _retire.visible:
		_retire.text = "Retire to the wall"
		_retire.disabled = not sim.can_retire()
		_retire.size.x = ceilf(UI.text_width(_retire, _retire.text)) + 48
		x -= 12 + _retire.size.x
		_retire.position.x = x
	if _train.visible:
		x -= 12 + _train.size.x
		_train.position.x = x
	if selected != "" and not _node_forms.is_empty():
		fit_two(_node_forms, x - 16 - PAD)            # under the title, clear of the buttons, over two lines
	_node_forms = []
	# the runners before, in what's left beside the buttons: on the class's panel, not under a node
	_past.size.x = x - 12 - _past.position.x
	_past.visible = selected == ""
	if selected == "":
		_show_past()


## A node's sentence under its title over two lines `w` wide: the longest form that wraps into them whole.
func fit_two(forms: Array, w: float) -> void:
	_words.size.x = w
	_words2.position.x = PAD
	_words2.size.x = w
	for f in forms:
		if str(f) == "":
			continue
		UI.wrap([_words, _words2], str(f))
		if UI.text_width(_words2, _words2.text) <= w:
			return
	UI.wrap([_words, _words2], str(forms[0]))       # nothing wraps whole: the fit checks will say so


## A clause as a sentence of its own: a capital, a full stop.
static func _as_sentence(x: String) -> String:
	if x == "":
		return ""
	var out := x.substr(0, 1).to_upper() + x.substr(1)
	return out if out.ends_with(".") else out + "."


## The runners before this one, newest first: who, how long, how it ended.
func _show_past() -> void:
	if sim.past.is_empty():
		UI.fit(_past, [Words.PASTS[sim.cls]["was"] if Words.PASTS.has(sim.cls) else "", ""])
		return
	var long := []
	var short := []
	for k in range(sim.past.size() - 1, -1, -1):
		var r: Dictionary = sim.past[k]
		var held: String = (", %s at depth %d" % [Words.mid(str(r["site"])), int(r["depth"])]) if int(r.get("depth", 0)) > 0 else ""
		long.append("a %s, %d run%s%s, %s" % [str(r["class"]), int(r["runs"]), "" if int(r["runs"]) == 1 else "s", held, r["end"]])
		short.append("%s %d" % [str(r["class"]), int(r["runs"])])
	UI.fit(_past, ["Before: " + "; ".join(long), "Before: " + "; ".join(long.slice(0, 2)), "Before: " + ", ".join(short), long[0], "%d runner%s before this one" % [sim.past.size(), "" if sim.past.size() == 1 else "s"]])


# ------------------------------------------------------------------ acting

func _pick(id: String) -> void:
	_armed = ""
	selected = id
	show_state(sim)


func _pick_at(lane: int, i: int) -> void:
	var id: String = _lanes[lane]["tiles"][i]["id"]
	if id != "":
		_pick(id)


## A tile's button by node id, or null when it's not on show (for the tests).
func tile_for(id: String) -> Button:
	for lane in _lanes:
		for t in lane["tiles"]:
			if t["id"] == id and t["button"].visible:
				return t["button"]
	return null


## An Also chip's button by name, or null (for the tests).
func also_button(name: String) -> Button:
	for a in _also:
		if a["name"] == name and a["button"].visible:
			return a["button"]
	return null


func _pick_also_at(k: int) -> void:
	pick_also(str(_also[k]["name"]))


## An Also chip: its tree in the Yard's lane (the drawer and the shelf over the lanes); pressed again, the Yard back.
func pick_also(name: String) -> void:
	_armed = ""
	alt = "" if alt == name else name
	drawer_page = 0
	_shown = ""
	show_state(sim)


func _turn_page() -> void:
	drawer_page += 1
	_shown = ""
	show_state(sim)


## A class button: free for a runner with no class (or nothing in the class trees); otherwise the first press
## arms it and the header names the price, the second changes (9 Oct: a click was a free respec).
func _pick_class(name: String) -> void:
	if sim.on_mission() or name == sim.cls or name == sim.cls2:
		_armed = ""
		show_state(sim)
		return
	if sim.class_change_cost(name) > 0 and _armed != name:
		_armed = name
		_armed_cls = sim.cls
		show_state(sim)
		return
	_armed = ""
	if sim.set_class(name):
		selected = ""
		alt = ""
		acted.emit()
	show_state(sim)


func _on_train() -> void:
	_armed = ""
	if selected != "" and sim.train_node(selected):
		acted.emit()
	show_state(sim)


func _on_respec() -> void:
	_armed = ""
	if sim.respec():
		acted.emit()
	show_state(sim)


## For the tests: the labels that share a line and must not run into each other - a tile's name and its cost,
## and the points and their unit.
func line_pairs() -> Array:
	return [[_points, _unit]]


## For the tests: every label with text on show.
func text_nodes() -> Array:
	var out: Array = [_title, _words, _words2, _past, _respec, _sum_head, _kicker, _points, _unit, _class_line, _notice, _also_head]
	if _chips.visible:
		out.append_array(_chips.text_nodes())
	out.append_array(_sum_chips.text_nodes())
	for b in [_ascend, _retire, _train]:
		if b.visible:
			out.append(b)
	out.append_array(_class_buttons)
	for lane in _lanes:
		if lane["panel"].visible:
			out.append_array([lane["name"], lane["tag"], lane["gates"], lane["count"]])
		for t in lane["tiles"]:
			if t["button"].visible and t["more"].visible:
				out.append(t["more"])
			if t["button"].visible and t["joint"].visible:
				out.append(t["joint"])
	for l in _links:
		if l["chip"].visible:
			out.append(l["label"])
	for a in _also:
		if a["button"].visible:
			out.append(a["button"])
	for c in _cells:
		if c["button"].visible:
			out.append(c["name"])
			for l in c["lines"]:
				if l.visible:
					out.append(l)
	return out
