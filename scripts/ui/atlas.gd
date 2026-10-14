extends Control
## The map as lanes (Map-L, 9 Oct; Matt: "the map screen also needs to be updated to follow the changes we've
## made to the skill tree and yard"). The band (the points free, what earns one, the zones' depths as chips);
## three lanes - the sites, the crews, the air - in the Training screen's layout: a label block (the points in
## the lane, the next column's gate), six columns of two nodes, the lane's keystone last (alone in its column,
## the lane's height). A column opens on the points spent in its lane (Data.ATLAS_GATES); the ranks as pips, a
## taken tile lined in the accent; the sum strip as the taken nodes' figures; and the panel under: the pick's
## name and rank (and the gate when shut), its figure as a chip with the next rank's beside, one sentence, Take
## a rank and Start the map again.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Band := preload("res://scripts/ui/band.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Words := preload("res://scripts/sim/words.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")

const W := Pal.GRID_W
const PAD := 20
const BAND_H := 170                # the band's chips sit under the headline at this height (150 puts them over it)
const LANES_Y := BAND_H + 12
const LANE_H := 140
const LANE_GAP := 6
const LABEL_W := 180
const TILES_X := LABEL_W + 10
const COLS := 6
const TILE_GAP := 6
const ROW_GAP := 4
@warning_ignore("integer_division")
const TILE_W := (W - TILES_X - 8 - (COLS - 1) * TILE_GAP) / COLS
@warning_ignore("integer_division")
const TILE_H := (LANE_H - 14 - ROW_GAP) / 2
const SUM_Y := LANES_Y + 3 * LANE_H + 2 * LANE_GAP + 12
const SUM_H := 10 + Chips.CHIP_H + 10
const SUM_HEAD_W := 150
const SUM_CHIPS := 7               # the taken nodes' figures, so many and a count
const PANEL_Y := SUM_Y + SUM_H + 12
const PIP := 10
const PIP_GAP := 4
# the nodes as glyph tiles (10 Oct, Lanes-G; Matt: the map "looks really bad now" beside Training): a 52 px tile in
# its column, the ranks as pips under it, a one-rank node round, the lane's keystone bigger and alone; the words are
# the panel's and the tooltip's
const NODE := 52
const NODE_BIG := 64
const KEY_SIDE := 46                # a keystone's diamond: a 46 px square turned 45° (65 across), the Training tree's mark
const ROW_Y := [2, 72]              # the two rows' tops in a 140 px lane: a tile and its pips, each row inside the lane
const GLYPH := 30

var sim
var selected := ""                 # a passive's key, or ""
var _band: Band
var _heads: Array = []             # per lane: {name, count, gate, bar}
var _tiles := {}                   # key -> {button, name, words, pips: [Panel]}
var _sum_head: Label
var _sum_chips: Chips
var _panel: Panel
var _title: Label
var _chips: Chips
var _words: Label
var _take: Button
var _reset: Button
var _shown := ""


func _init(h: float) -> void:
	size = Vector2(W, h)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var top := UI.panel(self, Rect2(0, 0, W, BAND_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	top.clip_contents = true
	_band = Band.new(W, BAND_H, 4)
	_band.set_site("the map")                 # the band's art (art/places/the_map.png): the Dial (13 Oct) keeps the map's picture
	top.add_child(_band)
	for c in range(Data.ATLAS_COLUMNS.size()):
		var y: float = LANES_Y + c * (LANE_H + LANE_GAP)
		var lane := UI.panel(self, Rect2(0, y, W, LANE_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
		var head := {}
		head["bar"] = UI.panel(lane, Rect2(0, 0, 4, LANE_H), UI.box(Pal.CARD_LINE, 2))
		head["name"] = UI.label(lane, Rect2(16, 8, LABEL_W - 20, 30), Data.ATLAS_COLUMNS[c], "SemiBold", Pal.LINE - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		head["count"] = UI.label(lane, Rect2(16, 42, LABEL_W - 20, 23), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		head["gate"] = UI.label(lane, Rect2(16, 66, LABEL_W - 20, 23), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		_heads.append(head)
		var nodes: Array = Data.ATLAS.filter(func(a): return int(a["column"]) == c)
		for k in range(nodes.size()):
			var a: Dictionary = nodes[k]
			var key: String = a["key"]
			@warning_ignore("integer_division")
			var col: int = k / 2
			var row: int = k % 2
			var alone: bool = k == nodes.size() - 1 and row == 0
			var keystone: bool = a.get("keystone", false)
			var side: float = KEY_SIDE if keystone else NODE
			var slot_x: float = TILES_X + col * (TILE_W + TILE_GAP)
			var mid_y: float = (y + LANE_H / 2.0) if alone else (y + ROW_Y[row] + NODE / 2.0)
			var rc := Rect2(slot_x + (TILE_W - side) / 2.0, mid_y - side / 2.0, side, side)
			# the shapes say what a node is, as on Training: a notable round, a keystone a diamond, the rest square
			var t := {"max": int(a["max"]), "round": a.get("notable", false) and not keystone, "keystone": keystone}
			var b := Button.new()
			b.position = rc.position
			b.size = rc.size
			b.tooltip_text = "%s: %s" % [a["name"], a["words"]]
			b.pressed.connect(_pick.bind(key))
			add_child(b)
			t["button"] = b
			t["glyph"] = TextureRect.new()
			t["glyph"].position = (rc.size - Vector2(GLYPH, GLYPH)) / 2.0
			t["glyph"].size = Vector2(GLYPH, GLYPH)
			t["glyph"].expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t["glyph"].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			t["glyph"].texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			t["glyph"].texture = NodeGlyphs.texture(NodeGlyphs.of_atlas(key))
			t["glyph"].mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(t["glyph"])
			if keystone:
				b.pivot_offset = rc.size / 2.0
				b.rotation_degrees = 45.0
				t["glyph"].pivot_offset = t["glyph"].size / 2.0
				t["glyph"].rotation_degrees = -45.0              # upright inside the turned tile
			# the words live in the panel: the labels stay, empty, for the tests' sake of a tile's shape
			t["name"] = UI.label(b, Rect2(0, 0, 0, 0), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			t["words"] = UI.label(b, Rect2(0, 0, 0, 0), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			t["name"].visible = false
			t["words"].visible = false
			# the ranks as pips under it, for a node of two ranks or more (one rank: its fill says it)
			var pips: Array = []
			var n: int = int(a["max"]) if int(a["max"]) > 1 else 0
			var px0: float = rc.position.x + (side - (n * PIP + (n - 1) * PIP_GAP)) / 2.0
			for j in range(n):
				@warning_ignore("integer_division")
				pips.append(UI.panel(self, Rect2(px0 + j * (PIP + PIP_GAP), rc.position.y + side + 4, PIP, PIP), UI.box(Color.TRANSPARENT, PIP / 2, 1, Pal.CARD_LINE)))
			t["pips"] = pips
			_tiles[key] = t
			_style(b, "open")
	var sum := UI.panel(self, Rect2(0, SUM_Y, W, SUM_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_sum_head = UI.head(sum, Rect2(PAD, 10, SUM_HEAD_W, Chips.CHIP_H), "Add up to")
	_sum_head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sum_chips = Chips.new(W - 2 * PAD - SUM_HEAD_W - 10, 6)
	_sum_chips.position = Vector2(PAD + SUM_HEAD_W + 10, 10)
	sum.add_child(_sum_chips)
	_panel = UI.panel(self, Rect2(0, PANEL_Y, W, h - PANEL_Y), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_title = UI.label(_panel, Rect2(PAD, 10, W - 2 * PAD, 34), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_chips = Chips.new(600)
	_chips.position = Vector2(PAD, 52)
	_panel.add_child(_chips)
	_words = UI.label(_panel, Rect2(PAD, 52, W - 2 * PAD, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var by: float = _panel.size.y - PAD - Pal.BUTTON_H
	_take = UI.button(_panel, Rect2(0, by, 240, Pal.BUTTON_H), true)
	_take.pressed.connect(_on_take)
	_reset = UI.button(_panel, Rect2(0, by, 240, Pal.BUTTON_H), false)
	_reset.text = "Start the Dial again"
	_reset.pressed.connect(_on_reset)


static func _passive(key: String) -> Dictionary:
	return Data.atlas_of(key)


## A node's look, the tree's (Tree-G): taken filled and gold-edged, its glyph gold; open white; locked dim; the
## picked one ringed white. A one-rank node is round.
func _style(b: Button, look: String, rnd := false, picked := false) -> void:
	var r: int = int(b.size.x / 2.0) if rnd else 8
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var sb: StyleBoxFlat
		match look:
			"taken":
				sb = UI.box(Pal.SELECT, r, 2, Pal.ACCENT)
			"locked":
				sb = UI.box(Color.TRANSPARENT, r, 1, Pal.CARD_LINE)
			_:
				sb = UI.box(Pal.CARD if state == "hover" else Pal.PANEL, r, 1, Pal.TEXT_2)
		if picked:
			sb.set_border_width_all(3)
			sb.border_color = Pal.TEXT
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, r, 2, Pal.TEXT))


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	var sig := "%s|%d|%s|%s|%s" % [str(sim.atlas), sim.atlas_points, selected, str(sim.best_depth), str(sim.on_mission())]
	if sig == _shown:
		return
	_shown = sig
	var free: int = sim.atlas_free()
	_band.set_words("The Dial · the endgame's tree", "The Dial", "%d" % free, ["of %d point%s free" % [sim.atlas_points, "" if sim.atlas_points == 1 else "s"], "of %d free" % sim.atlas_points, "free"])
	_band.set_right(["A point a new depth,", "past the first, any site.", "Holds on every site."])
	var zones := []
	for z in range(Data.ZONES.size()):
		var deepest := 0
		for i in Data.ZONES[z]["tiers"]:
			deepest = maxi(deepest, sim.best_depth[i])
		zones.append({"forms": ["%s · depth %d" % [Data.ZONES[z]["name"], deepest], "depth %d" % deepest], "colour": Pal.TEXT_2})
	_band.set_chips(zones)
	var taken_of: Array = [[0, 0], [0, 0], [0, 0]]
	var items := []
	var more := 0
	for a in Data.ATLAS:
		var key: String = a["key"]
		var c: int = int(a["column"])
		var rank: int = sim.atlas_rank(key)
		taken_of[c][0] += rank
		taken_of[c][1] += int(a["max"])
		var t: Dictionary = _tiles[key]
		var open: bool = sim.atlas_open(key)
		var figs: Array = a["figures"]
		for k in range(t["pips"].size()):
			@warning_ignore("integer_division")
			t["pips"][k].add_theme_stylebox_override("panel", UI.box(Pal.ACCENT if k < rank else Color.TRANSPARENT, PIP / 2, 1, Pal.ACCENT if k < rank else Pal.CARD_LINE))
		var look: String = "taken" if rank > 0 else ("open" if open else "locked")
		t["look"] = look
		_style(t["button"], look, t["round"], key == selected)
		t["glyph"].modulate = {"taken": Pal.ACCENT, "open": Pal.TEXT, "locked": Color(Pal.TEXT_3, 0.6)}[look]
		t["button"].tooltip_text = "%s · rank %d of %d: %s" % [a["name"], rank, int(a["max"]), str(figs[rank]) if rank > 0 else str(a["words"])]
		if rank > 0:
			if items.size() < SUM_CHIPS:
				items.append({"tag": str(a["sum"]), "forms": [str(figs[rank])], "colour": Pal.GOOD})
			else:
				more += 1
	for c in range(Data.ATLAS_COLUMNS.size()):
		var pts: int = sim.atlas_in_lane(c)
		UI.fit(_heads[c]["count"], ["%d point%s in · %d of %d ranks" % [pts, "" if pts == 1 else "s", taken_of[c][0], taken_of[c][1]], "%d points in" % pts, "%d in" % pts])
		var nxt := -1
		for g in Data.ATLAS_GATES:
			if int(g) > pts:
				nxt = int(g)
				break
		UI.fit(_heads[c]["gate"], ["next column at %d" % nxt if nxt >= 0 else "every column open", "next at %d" % nxt if nxt >= 0 else "all open"])
		(_heads[c]["bar"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.ACCENT if pts > 0 else Pal.CARD_LINE
	# the sum strip: the taken nodes' figures, so many and a count; nothing taken, the point's worth
	if more > 0:
		items.append({"tag": "and", "forms": ["%d more" % more], "colour": Pal.TEXT_2})
	if items.is_empty():
		items.append({"forms": ["Nothing taken yet: a point a new depth, spent here"], "colour": Pal.TEXT_2})
	_sum_chips.show_chips(items)
	_show_panel()


func _show_panel() -> void:
	var a: Dictionary = _passive(selected)
	_take.visible = not a.is_empty()
	_chips.visible = not a.is_empty()
	if a.is_empty():
		_title.text = "The Dial"
		_words.position.x = PAD
		_words.size.x = W - 2 * PAD
		UI.fit(_words, [Words.MAP["empty"] % [sim.convoy_depth(), sim.pinnacle_depth(2), sim.pinnacle_depth(5), sim.pinnacle_depth(8)], Words.MAP["empty_short"] % sim.convoy_depth(), "Pick a node above."])
	else:
		var rank: int = sim.atlas_rank(selected)
		var figs: Array = a["figures"]
		var needs: String = ""
		if not sim.atlas_open(selected):
			needs = "opens at %d points in %s" % [int(Data.ATLAS_GATES[sim.atlas_col(selected)]), str(Data.ATLAS_COLUMNS[int(a["column"])]).to_lower()]
		UI.fit(_title, ["%s · rank %d of %d%s" % [a["name"], rank, int(a["max"]), (" · " + needs) if needs != "" else ""], "%s · rank %d of %d" % [a["name"], rank, int(a["max"])], str(a["name"])])
		var items := []
		if rank > 0:
			items.append({"forms": [str(figs[rank])], "colour": Pal.GOOD})
		if rank < int(a["max"]):
			items.append({"forms": [("next: " if rank > 0 else "") + str(figs[rank + 1])], "colour": Pal.TEXT_2 if rank > 0 else Pal.ACCENT})
		_chips.show_chips(items)
		_words.position.x = PAD + _chips.used_width() + 10
		_words.size.x = W - PAD - _words.position.x
		UI.fit(_words, [str(a["sentence"]), str(a["words"]), ""])
		_take.text = "Take a rank (1 point)" if rank < int(a["max"]) else "At its top"
		_take.disabled = not sim.can_rank_atlas(selected)
		_take.size.x = ceilf(UI.text_width(_take, _take.text)) + 48
	_reset.disabled = sim.atlas_spent() == 0 or sim.on_mission()
	_reset.size.x = ceilf(UI.text_width(_reset, _reset.text)) + 48
	var x: float = W - PAD - _reset.size.x
	_reset.position.x = x
	if _take.visible:
		x -= 12 + _take.size.x
		_take.position.x = x
	# the sentence stops short of the buttons (the panel is one line shorter under the lanes)
	var room: float = x - 16 - _words.position.x
	if _words.size.x > room:
		_words.size.x = room
		var a2: Dictionary = _passive(selected)
		if a2.is_empty():
			UI.fit(_words, [Words.MAP["empty_short"] % sim.convoy_depth(), "Pick a node above."])
		else:
			UI.fit(_words, [str(a2["sentence"]), str(a2["words"]), ""])


# ------------------------------------------------------------------ acting

func _pick(key: String) -> void:
	selected = key
	_shown = ""
	show_state(sim)


func _on_take() -> void:
	if sim.rank_atlas(selected):
		acted.emit()
	_shown = ""
	show_state(sim)


func _on_reset() -> void:
	sim.reset_atlas()
	acted.emit()
	_shown = ""
	show_state(sim)


func text_nodes() -> Array:
	var out: Array = [_title, _words, _sum_head, _reset]
	out.append_array(_band.text_nodes())
	out.append_array(_sum_chips.text_nodes())
	if _chips.visible:
		out.append_array(_chips.text_nodes())
	if _take.visible:
		out.append(_take)
	for h in _heads:
		out.append_array([h["name"], h["count"], h["gate"]])
	return out


func line_pairs() -> Array:
	var out: Array = []
	for h in _heads:
		out.append([h["name"], h["count"]])
	return out
