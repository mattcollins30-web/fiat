extends Control
## The Yard as lanes (9 Oct, docs/design/yard.md, Yard-L A on the canvas; Matt: the Yard's upgrades were done
## before the City, "I still need yard upgrades even when I'm 9 depths deep", "the choices need to be more
## memorable and scale more"). Eight buildings, a lane each, the Training screen's layout: a label block, five
## columns of two picks - take one, the other stays on show, dim, and can be refitted for half - and the rank
## alone in the sixth, bought again and again. A column opens on the campaign and the depth, for good. The
## header: the picks built, the purse (cash, notes, scrap and the three salvages) and Move the Yard. The strip
## at the foot: the picked tile's sentence, its other half, its price and its button; with nothing picked, the
## town's note and the clock.
##
## `show_state(sim, purse)`: purse from main._town_purse() (its `left.note`, `status` and `button`).

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Data := preload("res://scripts/sim/data.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")

const PAD := 20
## The heading takes the room the glyph lanes left (10 Oct, Matt: "moving everything down and making the header fit
## the space"): the lanes and the strip sit at the foot, the Yard's painted place above them.
const HEAD_H := Pal.ROOM_H - 8 - (8 * LANE_H + 7 * LANE_GAP) - 6 - STRIP_H     # eight buildings, as STRIP_Y
const MOVE_W := 220
const CHIPS_Y := 88                  # the purse under the headline (it ends at 76), down the left
const CHIPS_W := 330                 # the title's width
const CHIPS_ROWS := 3
const LANES_Y := HEAD_H + 8
# the lanes in the tree's glyphs (10 Oct, Lanes-G; Matt: "yard and map look really bad now" beside Training): a
# column's two picks as glyph tiles side by side, its price beside them; the rank's tile, figure and pips at the end
const LANE_H := 64
const LANE_GAP := 4
const LABEL_W := 150
const TILES_X := LABEL_W + 12
const COLS := 6
const TILE := 48
const PAIR_GAP := 8
const RANK_W := 210
const COL_W := (Pal.GRID_W - TILES_X - 8 - RANK_W) / (COLS - 1)
const GLYPH := 28
const PIP := 8
const PIP_GAP := 4
const STRIP_Y := LANES_Y + 8 * LANE_H + 7 * LANE_GAP + 6
const STRIP_H := 92                                         # under the lanes, its own height (the review: the rest of the room left it half empty)
const BUILD_W := 260

var head_band := {}                # the heading's painted place (10 Oct, Rooms-B)
var sim
var selected := {}                  # {key, col, side} a pick, {key, rank: true} a rank, {} nothing
var _kicker: Label
var _headline: Label
var _unit: Label
var _chips: Chips
var _move: Button
var _move_action: Callable
var _lanes: Array = []              # {key, panel, bar, name, count, gate, kind, tiles: [[a, b] x5], rank}
var _title: Label
var _words: Label
var _other: Label
var _foot: Label                    # the town's note, with nothing picked
var _foot_right: Label              # the clock and the autosave
var _build: Button
var _shown := ""


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var head := UI.panel(self, Rect2(0, 0, Pal.GRID_W, HEAD_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	head_band = UI.head_art(head, "The yard")        # art/places/the_yard.png (Rooms-B)
	_kicker = UI.label(head, Rect2(PAD, 8, 330, 24), "The Yard", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_headline = UI.label(head, Rect2(PAD, 32, 330, 44), "", "SemiBold", Pal.HEADLINE - 4, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_unit = UI.label(head, Rect2(PAD, 38, 200, 36), "", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	# the purse down the left under the title, on the band's shaded side, so the painting across the top is clear
	# (Matt, 10 Oct): up to three rows in the title's width
	_chips = Chips.new(CHIPS_W, 9)
	_chips.position = Vector2(PAD, CHIPS_Y)
	head.add_child(_chips)
	_move = UI.button(head, Rect2(Pal.GRID_W - PAD - MOVE_W, HEAD_H - 16 - Pal.BUTTON_H, MOVE_W, Pal.BUTTON_H), true)     # at the band's foot, right
	_move.text = "Move the Yard"
	_move.visible = false
	_move.pressed.connect(func(): if _move_action.is_valid(): _move_action.call())
	for k in range(Data.YARD.size()):
		var b: Dictionary = Data.YARD[k]
		var y: float = LANES_Y + k * (LANE_H + LANE_GAP)
		var lane := {"key": b["key"], "tiles": []}
		lane["panel"] = UI.panel(self, Rect2(0, y, Pal.GRID_W, LANE_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
		lane["bar"] = UI.panel(lane["panel"], Rect2(0, 0, 4, LANE_H), UI.box(Pal.CARD_LINE, 2))
		lane["name"] = UI.label(lane["panel"], Rect2(14, 2, LABEL_W - 14, 22), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		lane["count"] = UI.label(lane["panel"], Rect2(14, 24, LABEL_W - 14, 19), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		lane["gate"] = UI.label(lane["panel"], Rect2(14, 24, LABEL_W - 14, 19), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		lane["gate"].visible = false                 # the gate is the first shut column's, beside its tiles
		lane["kind"] = UI.label(lane["panel"], Rect2(14, 43, LABEL_W - 14, 19), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		var ty: float = y + (LANE_H - TILE) / 2.0
		for c in range(COLS - 1):
			var x0: float = TILES_X + c * COL_W + 10
			var cost := UI.label(self, Rect2(x0 + 2 * TILE + PAIR_GAP + 8, ty, COL_W - 2 * TILE - PAIR_GAP - 22, TILE), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT)
			var pair := []
			for side in range(2):
				var tl := _tile(Rect2(x0 + side * (TILE + PAIR_GAP), ty, TILE, TILE), _press.bind(b["key"], c, "a" if side == 0 else "b"))
				tl["cost"] = cost                         # the pair's price, beside it: one, as a column is bought once
				pair.append(tl)
			lane["tiles"].append(pair)
		var rx: float = TILES_X + (COLS - 1) * COL_W + 10
		lane["rank"] = _tile(Rect2(rx, ty, TILE, TILE), _press_rank.bind(b["key"]))
		var r: Dictionary = lane["rank"]
		r["name"] = UI.label(self, Rect2(rx + TILE + 10, y + 4, RANK_W - TILE - 24, 22), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["cost"] = UI.label(self, Rect2(rx + TILE + 10, y + 25, RANK_W - TILE - 24, 20), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT)
		r["pips"] = []
		for pi in range(5):
			r["pips"].append(UI.panel(self, Rect2(rx + TILE + 10 + pi * (PIP + PIP_GAP), y + 48, PIP, PIP), UI.box(Pal.CARD_LINE, PIP / 2)))
		_lanes.append(lane)
	var strip := UI.panel(self, Rect2(0, STRIP_Y, Pal.GRID_W, STRIP_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	var tw: float = Pal.GRID_W - 2 * PAD - BUILD_W - 16
	_title = UI.label(strip, Rect2(PAD, 2, tw, 32), "", "SemiBold", Pal.TITLE - 4, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_words = UI.label(strip, Rect2(PAD, 32, tw, 24), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_other = UI.label(strip, Rect2(PAD, 54, tw, 23), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_foot = UI.label(strip, Rect2(PAD, 8, tw, 30), "", "Regular", Pal.FLOOR - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_foot_right = UI.label(strip, Rect2(PAD, 42, tw, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_build = UI.button(strip, Rect2(Pal.GRID_W - PAD - BUILD_W, 12, BUILD_W, Pal.BUTTON_H), true)     # level with the title
	_build.pressed.connect(_on_build)


## A tile: a button with its pick's glyph; its words are the strip's and its tooltip's. "name" and "words" stay as
## empty labels (a tile reads by its glyph); "cost" is the pair's price beside it.
func _tile(r: Rect2, action: Callable) -> Dictionary:
	var b := Button.new()
	b.position = r.position
	b.size = r.size
	b.text = ""
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(action)
	add_child(b)
	var t := {"button": b}
	t["edge"] = UI.panel(b, Rect2(0, 0, 0, 0), UI.box(Pal.ACCENT, 2))
	t["edge"].visible = false
	t["glyph"] = TextureRect.new()
	t["glyph"].position = (r.size - Vector2(GLYPH, GLYPH)) / 2.0
	t["glyph"].size = Vector2(GLYPH, GLYPH)
	t["glyph"].expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t["glyph"].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t["glyph"].texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t["glyph"].mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(t["glyph"])
	t["name"] = UI.label(b, Rect2(0, 0, 0, 0), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	t["words"] = UI.label(b, Rect2(0, 0, 0, 0), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	t["name"].visible = false
	t["words"].visible = false
	return t


## A tile's look, the tree's (Tree-G): "built" filled gold-edged, its glyph gold; "open" buyable, white; "other" the
## pick not taken, dim; "shut" its column shut, dimmer. The picked one ringed in the accent.
func _style(t: Dictionary, look: String, on: bool) -> void:
	var b: Button = t["button"]
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var sb: StyleBoxFlat
		match look:
			"built":
				sb = UI.box(Pal.SELECT, 8, 2, Pal.ACCENT)
			"open":
				sb = UI.box(Pal.BUTTON if st == "hover" else Pal.CARD, 8, 1, Pal.TEXT_2)
			"other":
				sb = UI.box(Pal.BG if st != "hover" else Pal.PANEL, 8, 1, Pal.RAIL_RULE)
			_:
				sb = UI.box(Color.TRANSPARENT, 8, 1, Pal.RAIL_RULE)
		if on:
			sb.set_border_width_all(3)
			sb.border_color = Pal.TEXT
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 8, 2, Pal.TEXT))
	t["look"] = look
	t["glyph"].modulate = {"built": Pal.ACCENT, "open": Pal.TEXT, "other": Color(Pal.TEXT_3, 0.6), "shut": Color(Pal.TEXT_3, 0.35)}.get(look, Pal.TEXT_3)


func show_state(s, purse: Dictionary) -> void:
	sim = s
	var sig := "%s|%s|%s|%d|%d|%s|%s|%d|%d|%s|%s|%d|%.3f|%d" % [str(selected), str(sim.yard_picks), str(sim.yard_ranks), int(sim.cash), sim.yard_cols(), str(sim.salvage), str(sim.on_mission()),
		sim.notes, sim.scrap, str(purse.get("left", {}).get("note", "")), str(purse.has("button")), sim.yard_moves, sim.inflation(), sim.stash_used()]
	if sig == _shown:
		if _foot_right.visible:
			var st = purse.get("status", "")
			UI.fit(_foot_right, st if st is Array else [str(st)])     # the clock moves
		return
	_shown = sig
	var built: int = sim.yard_built()
	var of: int = Data.YARD.size() * (COLS - 1)
	UI.fit(_kicker, ["The Yard · yard %d" % (sim.yard_moves + 1) if sim.yard_moves > 0 else "The Yard", "The Yard"])
	_headline.text = "%d of %d" % [built, of]
	_unit.position.x = PAD + ceilf(UI.text_width(_headline, _headline.text)) + 10
	_unit.size.x = 350 - _unit.position.x
	UI.fit(_unit, ["upgrades built", "built"])
	# the purse: cash in gold, notes and scrap, the salvage in their colours
	var items := [{"forms": [Fmt.money(sim.cash) + " in hand", Fmt.money(sim.cash)], "colour": Pal.ACCENT},
		{"tag": "Notes", "forms": ["%d" % sim.notes], "colour": Pal.TEXT_2}, {"tag": "Scrap", "forms": ["%d" % sim.scrap], "colour": Pal.TEXT_2}]
	for kind in Data.SALVAGE:
		items.append({"tag": Data.SALVAGE_NAMES[kind], "forms": ["%d" % int(sim.salvage.get(kind, 0))], "colour": salvage_colour(kind)})
	_chips.show_chips(items, CHIPS_ROWS)
	_move.visible = purse.has("button")
	if _move.visible:
		UI.style_button(_move, bool(purse["button"].get("primary", false)))
		_move_action = purse["button"]["action"]
	var cols: int = sim.yard_cols()
	for lane in _lanes:
		_show_lane(lane, cols)
	_show_strip(purse)


static func salvage_colour(kind: String) -> Color:
	return {"copper": Color("d08a5a"), "steel": Color("9fb3c8"), "army": Color("a3b06a")}.get(kind, Pal.TEXT_2)


func _show_lane(lane: Dictionary, cols: int) -> void:
	var key: String = lane["key"]
	var b := Data.yard_building(key)
	var picked := 0
	for c in range(COLS - 1):
		if sim.yard_side(key, c) != "":
			picked += 1
	UI.fit(lane["name"], [b["name"], str(b["name"]).trim_prefix("The ")])
	UI.fit(lane["count"], ["%d of 5 · rank %d" % [picked, sim.yard_rank(key)], "%d/5 · %d" % [picked, sim.yard_rank(key)]])
	if cols < COLS:
		UI.fit(lane["gate"], ["column %d: %s" % [cols + 1, str(Data.YARD_GATE_SHORT[cols])], "next: %s" % str(Data.YARD_GATE_SHORT[cols]), ""])
	else:
		UI.fit(lane["gate"], ["every column open", "all open"])
	UI.fit(lane["kind"], ["%s %d" % [Data.SALVAGE_NAMES[b["salvage"]], int(sim.salvage.get(b["salvage"], 0))], str(Data.SALVAGE_NAMES[b["salvage"]])])
	lane["kind"].add_theme_color_override("font_color", salvage_colour(b["salvage"]))
	var sel_here: bool = selected.get("key", "") == key
	(lane["bar"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.ACCENT if picked > 0 else Pal.CARD_LINE
	var gate_said := false
	for c in range(COLS - 1):
		var side_built: String = sim.yard_side(key, c)
		var cost := ""
		for s in range(2):
			var side: String = "a" if s == 0 else "b"
			var pk: Dictionary = b["picks"][c][s]
			var t: Dictionary = lane["tiles"][c][s]
			var look := "shut"
			if side_built == side:
				look = "built"
			elif side_built != "":
				look = "other"
			elif c < cols:
				look = "open"
			_style(t, look, sel_here and int(selected.get("col", -1)) == c and selected.get("side", "") == side)
			t["glyph"].texture = NodeGlyphs.texture(NodeGlyphs.of_pick(pk, key))
			t["button"].tooltip_text = "%s: %s" % [pk["name"], pk["short"]]
			if look == "open":
				cost = _short_money(sim.yard_pick_cost(key, c))
			elif look == "shut" and not gate_said:
				cost = str(Data.YARD_GATE_SHORT[c])     # the first shut column says what opens it
		if side_built == "" and c >= cols:
			gate_said = true
		var cl: Label = lane["tiles"][c][0]["cost"]
		UI.fit(cl, [cost, cost.get_slice(" ", cost.count(" "))] if cost != "" else [""])
		cl.add_theme_color_override("font_color", Pal.TEXT_2 if c < cols else Pal.TEXT_3)
	var r: Dictionary = lane["rank"]
	var rank_open: bool = cols >= COLS
	var rank: int = sim.yard_rank(key)
	_style(r, "built" if rank > 0 else ("open" if rank_open else "shut"), sel_here and selected.get("rank", false))
	r["glyph"].texture = NodeGlyphs.texture("star")
	r["button"].tooltip_text = "Rank %d: %s a rank" % [rank, b["rank"]["short"]]
	UI.fit(r["name"], ["◆ Rank %d · %s" % [rank, b["rank"]["short"]], "◆ Rank %d" % rank])
	UI.fit(r["cost"], [_short_money(sim.yard_rank_cost(key)) if rank_open else "opens %s" % str(Data.YARD_GATE_SHORT[COLS - 1]), str(Data.YARD_GATE_SHORT[COLS - 1])])
	# five pips: the ranks in this five, all five lit past each fifth
	var lit: int = 0 if rank == 0 else ((rank - 1) % 5) + 1
	for k in range(5):
		(r["pips"][k].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.ACCENT if k < lit else Pal.CARD_LINE


## "£16,000", "£160k": a tile's price, short.
static func _short_money(x: int) -> String:
	if x >= 100000:
		return "£%dk" % int(round(x / 1000.0))
	return Fmt.money(x)


func _show_strip(purse: Dictionary) -> void:
	var on_pick: bool = not selected.is_empty()
	_other.add_theme_color_override("font_color", Pal.TEXT_3)
	for l in [_title, _words, _other]:
		l.visible = on_pick
	for l in [_foot, _foot_right]:
		l.visible = not on_pick
	_build.visible = on_pick
	if not on_pick:
		var note = purse.get("left", {}).get("note", "")
		UI.fit(_foot, note if note is Array else [str(note)])
		var st = purse.get("status", "")
		UI.fit(_foot_right, st if st is Array else [str(st)])
		return
	var key: String = selected["key"]
	var b := Data.yard_building(key)
	var kind: String = str(Data.SALVAGE_NAMES[b["salvage"]]).to_lower()
	if selected.get("rank", false):
		UI.fit(_title, ["%s · rank %d" % [b["name"], sim.yard_rank(key)], str(b["name"])])
		UI.fit(_words, ["%s. Bought again and again; each rank dearer than the last." % b["rank"]["words"], str(b["rank"]["words"]) + "."])
		var why: String = sim.yard_rank_block(key)
		var price: String = "Rank %d: %s and %d %s" % [sim.yard_rank(key) + 1, Fmt.money(sim.yard_rank_cost(key)), sim.yard_rank_salvage(key), kind]
		UI.fit(_other, [price + ("" if why == "" else " · " + why), price, "%s · %d %s" % [Fmt.money(sim.yard_rank_cost(key)), sim.yard_rank_salvage(key), kind]])
		_build.text = "Buy rank %d" % (sim.yard_rank(key) + 1)
		_build.disabled = why != ""
		return
	var c: int = int(selected["col"])
	var side: String = selected["side"]
	var pk: Dictionary = b["picks"][c][0 if side == "a" else 1]
	var ot: Dictionary = b["picks"][c][1 if side == "a" else 0]
	var built: String = sim.yard_side(key, c)
	UI.fit(_title, ["%s · %s, column %d" % [pk["name"], b["name"], c + 1], str(pk["name"])])
	UI.fit(_words, [str(pk["words"]) + ".", str(pk["short"])])
	var or_line: String = "Or %s: %s" % [ot["name"], str(ot["words"]).to_lower()]
	if built == side:
		UI.fit(_other, ["Built · %s; a refit to it costs half the column" % or_line, "Built · %s" % or_line, "Built"])
		_build.text = "Built"
		_build.disabled = true
		return
	var why: String = sim.yard_pick_block(key, c, side)
	var price: String = Fmt.money(sim.yard_pick_cost(key, c)) + ("" if sim.yard_pick_salvage(key, c) == 0 else " and %d %s" % [sim.yard_pick_salvage(key, c), kind])
	var head: String = ("Refit from %s: %s" % [ot["name"], price]) if built != "" else price
	var tail: String = "" if why == "" else " · " + why
	var over: int = sim.yard_refit_over(key, c, side) if built != "" else 0
	if over > 0:
		# a refit off cells (Matt, 9 Oct): allowed, but said first - an over-full stash takes nothing until it's under
		var warn: String = "the stash goes %d cell%s over: nothing goes in until it's under" % [over, "" if over == 1 else "s"]
		UI.fit(_other, ["%s · %s%s" % [head, warn, tail], "%s · %d over cap%s" % [head, over, tail], "%d over cap%s" % [over, tail], "%d over cap" % over])
		_other.add_theme_color_override("font_color", Pal.WARN)
	else:
		UI.fit(_other, ["%s · %s%s" % [head, or_line, tail], "%s%s" % [head, tail], head])
	_build.text = "Refit" if built != "" else "Build"
	_build.disabled = why != ""


func _press(key: String, col: int, side: String) -> void:
	selected = {"key": key, "col": col, "side": side}
	_shown = ""
	acted.emit()


func _press_rank(key: String) -> void:
	selected = {"key": key, "rank": true}
	_shown = ""
	acted.emit()


func _on_build() -> void:
	if selected.is_empty():
		return
	var ok: bool = sim.buy_yard_rank(selected["key"]) if selected.get("rank", false) else sim.yard_pick(selected["key"], int(selected["col"]), selected["side"])
	if ok:
		_shown = ""
		acted.emit()


## For the smoke: a tile by building key, column and side ("rank" for the rank).
func tile(key: String, col: int, side: String) -> Dictionary:
	for lane in _lanes:
		if lane["key"] == key:
			return lane["rank"] if side == "rank" else lane["tiles"][col][0 if side == "a" else 1]
	return {}


func text_nodes() -> Array:
	var out: Array = [_kicker, _headline, _unit]
	out.append_array(_chips.text_nodes())
	for l in [_title, _words, _other, _foot, _foot_right]:
		if l.visible:
			out.append(l)
	if _build.visible:
		out.append(_build)
	if _move.visible:
		out.append(_move)
	for lane in _lanes:
		out.append_array([lane["name"], lane["count"], lane["kind"]])
		for pair in lane["tiles"]:
			out.append(pair[0]["cost"])
		out.append_array([lane["rank"]["name"], lane["rank"]["cost"]])
	return out


func line_pairs() -> Array:
	return [[_headline, _unit]]
