extends Control
## The Pitch (28 Oct, Matt: "it looks exactly the same"; the canvas's "The Pitch, B"): eight buildings as cards, each
## two lines of five steps climbed in order - a line's step wants the one above it, its twin on the other line costs
## YARD_SECOND times as much - and ranks once either line is done. The picked building's two lines as rows of tiles at
## the right; under the cards, what the Pitch gives now, building by building. A step opens on the campaign and the
## depth, for good, as before. The heading: the steps built, the purse.
##
## `show_state(sim, purse)`: purse from main._town_purse() (its `status`).

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")

const PAD := 20
const HEAD_H := Pal.BAND_H                 # every room's band, one height (10 Oct, Bands-U A)
const CHIPS_Y := 82                        # the purse under the headline, down the left, inside the band
const CHIPS_W := 330
const CHIPS_ROWS := 3
const BODY_Y := HEAD_H + 8
const LEFT_W := 900                        # the cards and what the Pitch gives
const ACROSS := 5                          # the buildings five across (29 Oct, the Bunkhouse the ninth: the designer's layout)
const CARD_W := 170
const CARD_H := 140
const CARD_GAP := 12
const GIVES_Y := BODY_Y + 2 * CARD_H + CARD_GAP + 12
const RIGHT_X := LEFT_W + 16
const RIGHT_W := Pal.GRID_W - RIGHT_X
const TILE_W := (RIGHT_W - 2 * PAD - 16) / 2.0
const TILE_H := 66
const TILE_GAP := 8
const TILES_Y := 114
const RANK_Y := TILES_Y + 5 * (TILE_H + TILE_GAP) + 4
const BUILD_W := 250
const PIP := 10
const PIP_GAP := 3
const CARD_PAD := 10
const STEPS := 5

var head_band := {}                # the heading's painted place (10 Oct, Rooms-B)
var sim
var building := "bench"            # the card picked: its lines at the right
var selected := {}                 # {key, col, side} a step, {key, rank: true} the rank, {} nothing
var _kicker: Label
var _headline: Label
var _unit: Label
var _chips: Chips
var cards: Array = []              # {button, name, built, lines: [{label, pips}], salvage}, one a building in Data.YARD's order
var _gives_rows: Array = []        # [name, words] a building
var _status: Label
var _detail: Panel
var _b_title: Label
var _b_sub: Label
var _line_heads: Array = []        # two
var _tiles: Array = []             # [side 0 or 1][step]: {button, name, short, state}
var _rank: Button
var _rank_name: Label
var _rank_short: Label
var _rank_state: Label
var _title: Label
var _words: Label
var _other: Label
var _build: Button
var _shown := ""


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var head := UI.panel(self, Rect2(0, 0, Pal.GRID_W, HEAD_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	head_band = UI.head_art(head, "The yard")        # art/places/the_yard.png (Rooms-B)
	_kicker = UI.label(head, Rect2(PAD, 8, 330, 24), "The Pitch", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_headline = UI.label(head, Rect2(PAD, 32, 330, 44), "", "SemiBold", Pal.HEADLINE - 4, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_unit = UI.label(head, Rect2(PAD, 38, 200, 36), "", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_chips = Chips.new(CHIPS_W, 9)
	_chips.position = Vector2(PAD, CHIPS_Y)
	head.add_child(_chips)
	# the cards: five across, two down (29 Oct: nine buildings)
	for i in range(Data.YARD.size()):
		@warning_ignore("integer_division")
		var at := Vector2((i % ACROSS) * (CARD_W + CARD_GAP), BODY_Y + (i / ACROSS) * (CARD_H + CARD_GAP))
		var b := Button.new()
		b.position = at
		b.size = Vector2(CARD_W, CARD_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick_building.bind(str(Data.YARD[i]["key"])))
		add_child(b)
		var c := {"button": b, "key": str(Data.YARD[i]["key"])}
		c["name"] = UI.label(b, Rect2(CARD_PAD, 8, CARD_W - 2 * CARD_PAD, 28), "", "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["built"] = UI.label(b, Rect2(CARD_PAD, 36, CARD_W - 2 * CARD_PAD, 22), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["lines"] = []
		for k in range(2):
			var ly: float = 66 + k * 24
			var l := UI.label(b, Rect2(CARD_PAD, ly - 3, CARD_W - 2 * CARD_PAD - STEPS * (PIP + PIP_GAP), 22), "", "Medium", Pal.CELL_TEXT - 3, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			var pips: Array = []
			for s in range(STEPS):
				var p := UI.panel(b, Rect2(CARD_W - CARD_PAD - (STEPS - s) * (PIP + PIP_GAP) + PIP_GAP, ly + 2, PIP, PIP), UI.box(Color.TRANSPARENT, 3, 1, Pal.TEXT_3))
				p.mouse_filter = Control.MOUSE_FILTER_IGNORE
				pips.append(p)
			c["lines"].append({"label": l, "pips": pips})
		c["salvage"] = UI.label(b, Rect2(CARD_PAD, CARD_H - 30, CARD_W - 2 * CARD_PAD, 22), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		for l in [c["name"], c["built"], c["salvage"]] + c["lines"].map(func(x): return x["label"]):
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cards.append(c)
	# what the Pitch gives now, a building a row (it was "Deepest clear on each", an empty box)
	var gives := UI.panel(self, Rect2(0, GIVES_Y, LEFT_W, Pal.ROOM_H - GIVES_Y), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	UI.head(gives, Rect2(PAD, 12, LEFT_W - 2 * PAD, UI.HEAD_H), "WHAT THE PITCH GIVES NOW")
	for i in range(Data.YARD.size()):
		var gy: float = 12 + UI.HEAD_H + 8 + i * 34
		var n := UI.label(gives, Rect2(PAD, gy, 140, 30), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var w := UI.label(gives, Rect2(PAD + 150, gy, LEFT_W - 2 * PAD - 150, 30), "", "Regular", Pal.CELL_TEXT, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false)
		_gives_rows.append([n, w])
	_status = UI.label(gives, Rect2(PAD, Pal.ROOM_H - GIVES_Y - 36, LEFT_W - 2 * PAD, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	# the picked building: its two lines, its rank, the step picked and Build
	_detail = UI.panel(self, Rect2(RIGHT_X, BODY_Y, RIGHT_W, Pal.ROOM_H - BODY_Y), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_b_title = UI.label(_detail, Rect2(PAD, 12, RIGHT_W - 2 * PAD, 36), "", "SemiBold", Pal.TITLE - 4, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_b_sub = UI.label(_detail, Rect2(PAD, 48, RIGHT_W - 2 * PAD, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(2):
		var x: float = PAD + k * (TILE_W + 16)
		_line_heads.append(UI.label(_detail, Rect2(x, 84, TILE_W, 24), "", "SemiBold", Pal.CELL_TEXT - 2, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false))
		var col: Array = []
		for s in range(STEPS):
			var t := Button.new()
			t.position = Vector2(x, TILES_Y + s * (TILE_H + TILE_GAP))
			t.size = Vector2(TILE_W, TILE_H)
			t.focus_mode = Control.FOCUS_ALL
			t.pressed.connect(_press_step.bind(s, "a" if k == 0 else "b"))
			_detail.add_child(t)
			var d := {"button": t}
			d["name"] = UI.label(t, Rect2(12, 4, TILE_W - 24, 24), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			d["short"] = UI.label(t, Rect2(12, 25, TILE_W - 24, 20), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			d["state"] = UI.label(t, Rect2(12, 43, TILE_W - 24, 20), "", "Medium", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
			for l in [d["name"], d["short"], d["state"]]:
				l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			col.append(d)
		_tiles.append(col)
	_rank = Button.new()
	_rank.position = Vector2(PAD, RANK_Y)
	_rank.size = Vector2(RIGHT_W - 2 * PAD, 56)
	_rank.focus_mode = Control.FOCUS_ALL
	_rank.pressed.connect(_press_rank)
	_detail.add_child(_rank)
	_rank_name = UI.label(_rank, Rect2(12, 4, 200, 26), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_rank_short = UI.label(_rank, Rect2(12, 28, RIGHT_W - 2 * PAD - 24, 22), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_rank_state = UI.label(_rank, Rect2(220, 4, RIGHT_W - 2 * PAD - 232, 26), "", "Medium", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
	for l in [_rank_name, _rank_short, _rank_state]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var by: float = RANK_Y + 56 + 14
	_title = UI.label(_detail, Rect2(PAD, by, RIGHT_W - 2 * PAD, 30), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_words = UI.label(_detail, Rect2(PAD, by + 30, RIGHT_W - 2 * PAD, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_other = UI.label(_detail, Rect2(PAD, by + 54, RIGHT_W - 2 * PAD, 22), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_build = UI.button(_detail, Rect2(RIGHT_W - PAD - BUILD_W, Pal.ROOM_H - BODY_Y - PAD - 48, BUILD_W, 48), true)
	_build.pressed.connect(_on_build)


func show_state(s, purse: Dictionary) -> void:
	sim = s
	var sig := "%s|%s|%s|%s|%d|%d|%s|%s|%d|%d|%.3f|%s" % [building, str(selected), str(sim.yard_picks), str(sim.yard_ranks), int(sim.cash), sim.yard_cols(), str(sim.salvage), str(sim.on_mission()),
		sim.notes, sim.scrap, sim.inflation(), str(sim.unlocked)]
	if sig == _shown:
		var st = purse.get("status", "")
		UI.fit(_status, st if st is Array else [str(st)])     # the clock moves
		return
	_shown = sig
	var built: int = sim.yard_built()
	var of: int = Data.yard_step_count()     # the buildable steps (29 Oct: not the expeditions' stubs)
	_headline.text = "%d of %d" % [built, of]
	_unit.position.x = PAD + ceilf(UI.text_width(_headline, _headline.text)) + 10
	_unit.size.x = 350 - _unit.position.x
	UI.fit(_unit, ["upgrades built", "built"])
	var items := [{"forms": [Fmt.money(sim.cash) + " in hand", Fmt.money(sim.cash)], "colour": Pal.ACCENT},
		{"tag": "Scrap", "forms": ["%d" % sim.scrap], "colour": Pal.TEXT_2}]
	if not sim.issued:
		items.insert(1, {"tag": "Notes", "forms": ["%d" % sim.notes], "colour": Pal.TEXT_2})     # no notes after the Issue (25 Oct)
	for kind in Data.SALVAGE:
		items.append({"tag": Data.SALVAGE_NAMES[kind], "forms": ["%d" % int(sim.salvage.get(kind, 0))], "colour": salvage_colour(kind)})
	_chips.show_chips(items, CHIPS_ROWS)
	_show_cards()
	_show_gives()
	var st2 = purse.get("status", "")
	UI.fit(_status, st2 if st2 is Array else [str(st2)])
	_show_detail()


static func salvage_colour(kind: String) -> Color:
	return {"copper": Color("d08a5a"), "steel": Color("9fb3c8"), "army": Color("a3b06a")}.get(kind, Pal.TEXT_2)


## A building whose room isn't open yet reads scrambled, its name and its upgrades' words (20 Oct, Matt: "the trees here
## for radio and the bench should be encrypted until they unlock"); its prices stay.
func _en_for(key: String) -> Callable:
	var known: bool = sim.room_open(sim.building_room(key))
	return func(t: String) -> String: return t if known else Fmt.scramble(t)


## Steps built on a line: the count from its first, in order.
func _line_built(key: String, side: String) -> int:
	var n := 0
	for c in range(STEPS):
		if sim.yard_built_side(key, c, side):
			n += 1
	return n


func _show_cards() -> void:
	for c in cards:
		var key: String = c["key"]
		var b := Data.yard_building(key)
		var en := _en_for(key)
		var picked_now: bool = key == building
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			c["button"].add_theme_stylebox_override(st, UI.box(Pal.SELECT if st == "hover" else Pal.CARD, 8, 2 if picked_now else 1, Pal.ACCENT if picked_now else Pal.CARD_LINE))
		UI.fit(c["name"], [en.call(str(b["name"])), en.call(str(b["name"]).trim_prefix("The "))])
		var n: int = _line_built(key, "a") + _line_built(key, "b")
		UI.fit(c["built"], ["%d of %d built · rank %d" % [n, Data.yard_step_count(key), sim.yard_rank(key)], "%d of %d · r%d" % [n, Data.yard_step_count(key), sim.yard_rank(key)]])
		c["built"].add_theme_color_override("font_color", Pal.ACCENT if n > 0 else Pal.TEXT_2)
		for k in range(2):
			var side: String = "a" if k == 0 else "b"
			UI.fit(c["lines"][k]["label"], [en.call(str(b["lines"][k]))])
			for sx in range(STEPS):
				var on: bool = sim.yard_built_side(key, sx, side)
				var shut: bool = sx >= sim.yard_cols()
				c["lines"][k]["pips"][sx].add_theme_stylebox_override("panel", UI.box(Pal.ACCENT if on else Color.TRANSPARENT, 3, 1, Pal.ACCENT if on else (Pal.CARD_LINE if shut else Pal.TEXT_3)))
		UI.fit(c["salvage"], ["Salvage: %s" % str(Data.SALVAGE_NAMES[b["salvage"]]).to_lower(), str(Data.SALVAGE_NAMES[b["salvage"]])])


func _show_gives() -> void:
	for i in range(Data.YARD.size()):
		var b: Dictionary = Data.YARD[i]
		var en := _en_for(str(b["key"]))
		var got: Array = []
		for c in range(b["picks"].size()):
			for k in range(2):
				if sim.yard_built_side(str(b["key"]), c, "a" if k == 0 else "b"):
					got.append(en.call(str(b["picks"][c][k]["short"])))
		if str(b["key"]) == "bunkhouse" and not got.is_empty():
			got = [sim.repeat_gives()]           # the share now, once (the review: every step's share listed)
		if sim.yard_rank(str(b["key"])) > 0:
			got.append("rank %d" % sim.yard_rank(str(b["key"])))
		UI.fit(_gives_rows[i][0], [en.call(str(b["name"]))])
		_gives_rows[i][0].add_theme_color_override("font_color", Pal.TEXT if not got.is_empty() else Pal.TEXT_3)
		if got.is_empty():
			_gives_rows[i][1].text = "Nothing built"
			_gives_rows[i][1].add_theme_color_override("font_color", Pal.TEXT_3)
		else:
			UI.fit(_gives_rows[i][1], [" · ".join(got), " · ".join(got.slice(0, 3)) + (" · %d more" % (got.size() - 3) if got.size() > 3 else ""), "%d built" % got.size()])
			_gives_rows[i][1].add_theme_color_override("font_color", Pal.GOOD)


## A step's look - "built", "next" (its line's next, buildable now), "twin" (its other line's step built: ×YARD_SECOND),
## "waits" (after the step above it) or "shut" (its column not open yet) - as its tile reads.
func step_look(key: String, col: int, side: String) -> String:
	if sim.yard_built_side(key, col, side):
		return "built"
	if bool(Data.yard_building(key)["picks"][col][0 if side == "a" else 1].get("stub", false)):
		return "stub"                         # the Bunkhouse's line B (29 Oct): comes with the trips
	if col >= sim.yard_cols():
		return "shut"
	if col > 0 and not sim.yard_built_side(key, col - 1, side):
		return "waits"
	return "twin" if sim.yard_side(key, col) != "" else "next"


func _show_detail() -> void:
	var key := building
	var b := Data.yard_building(key)
	var en := _en_for(key)
	UI.fit(_b_title, [en.call(str(b["name"]))])
	var subs := ["%s %d of %d · %s %d of %d · rank %d" % [en.call(str(b["lines"][0])), _line_built(key, "a"), STEPS, en.call(str(b["lines"][1])), _line_built(key, "b"), STEPS, sim.yard_rank(key)],
		"%d and %d of %d · rank %d" % [_line_built(key, "a"), _line_built(key, "b"), STEPS, sim.yard_rank(key)]]
	UI.fit(_b_sub, subs)
	var kind: String = str(Data.SALVAGE_NAMES[b["salvage"]]).to_lower()
	for k in range(2):
		var side: String = "a" if k == 0 else "b"
		UI.fit(_line_heads[k], [en.call(str(b["lines"][k])).to_upper()])
		for sx in range(STEPS):
			var d: Dictionary = _tiles[k][sx]
			var pk: Dictionary = b["picks"][sx][k]
			var look := step_look(key, sx, side)
			var picked_now: bool = not selected.get("rank", false) and str(selected.get("key", "")) == key and int(selected.get("col", -1)) == sx and str(selected.get("side", "")) == side
			UI.fit(d["name"], ["%d · %s" % [sx + 1, en.call(str(pk["name"]))], en.call(str(pk["name"]))])
			UI.fit(d["short"], [en.call(str(pk["short"]))])
			var price: String = Fmt.money(sim.yard_pick_cost(key, sx)) + ("" if sim.yard_pick_salvage(key, sx) == 0 else ", %d %s" % [sim.yard_pick_salvage(key, sx), kind])
			var colour: Color = Pal.TEXT_3
			var edge: Color = Pal.CARD_LINE
			match look:
				"built":
					d["state"].text = "Built"
					colour = Pal.GOOD
					edge = Pal.GOOD
				"next":
					UI.fit(d["state"], [price, Fmt.money_k(sim.yard_pick_cost(key, sx))])
					colour = Pal.ACCENT
					edge = Pal.ACCENT
				"twin":
					UI.fit(d["state"], ["×%s · %s" % [str(Data.YARD_SECOND), price], "×%s · %s" % [str(Data.YARD_SECOND), Fmt.money_k(sim.yard_pick_cost(key, sx))], Fmt.money_k(sim.yard_pick_cost(key, sx))])
					colour = Pal.TEXT_2
				"waits":
					UI.fit(d["state"], ["After the step above"])
				"stub":
					UI.fit(d["state"], [Words.REPEAT["stub"]])
				_:
					UI.fit(d["state"], [Data.yard_gate(sx), "Not open yet"])
			d["state"].add_theme_color_override("font_color", colour)
			for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
				d["button"].add_theme_stylebox_override(st, UI.box(Pal.SELECT if st == "hover" else Pal.PANEL, 6, 2 if picked_now else 1, Pal.ACCENT if picked_now else edge))
	# the rank
	var rank_on: bool = selected.get("rank", false) and str(selected.get("key", "")) == key
	UI.fit(_rank_name, ["Rank %d" % (sim.yard_rank(key) + 1)])
	UI.fit(_rank_short, [en.call(str(b["rank"]["words"])) + ", once either line is done", en.call(str(b["rank"]["short"]))])
	var rb: String = sim.yard_rank_block(key)
	var rprice: String = Fmt.money(sim.yard_rank_cost(key)) + ("" if sim.yard_rank_salvage(key) == 0 else ", %d %s" % [sim.yard_rank_salvage(key), kind])
	UI.fit(_rank_state, [rprice if rb == "" or rb.begins_with("Short") or rb.begins_with("Wants") else rb, Fmt.money_k(sim.yard_rank_cost(key))])
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		_rank.add_theme_stylebox_override(st, UI.box(Pal.SELECT if st == "hover" else Pal.PANEL, 6, 2 if rank_on else 1, Pal.ACCENT if rank_on else Pal.CARD_LINE))
	_show_picked(key, b, en, kind)


func _show_picked(key: String, b: Dictionary, en: Callable, kind: String) -> void:
	var on_pick: bool = not selected.is_empty() and str(selected.get("key", "")) == key
	for l in [_title, _words, _other]:
		l.visible = on_pick
	_build.visible = on_pick
	if not on_pick:
		return
	if selected.get("rank", false):
		UI.fit(_title, ["%s · rank %d" % [en.call(str(b["name"])), sim.yard_rank(key)], en.call(str(b["name"]))])
		UI.fit(_words, ["%s. Bought again and again; each rank dearer than the last." % en.call(str(b["rank"]["words"])), en.call(str(b["rank"]["words"])) + "."])
		var why_in: String = sim.yard_rank_block(key)
		var rank_salv: int = sim.yard_rank_salvage(key)
		var price_in: String = ("Rank %d: %s and %d %s" % [sim.yard_rank(key) + 1, Fmt.money(sim.yard_rank_cost(key)), rank_salv, kind]) if rank_salv > 0 else ("Rank %d: %s" % [sim.yard_rank(key) + 1, Fmt.money(sim.yard_rank_cost(key))])     # past the fifth, tins alone
		UI.fit(_other, [price_in + ("" if why_in == "" else " · " + why_in), price_in])
		UI.fit_button(_build, ["Buy (%s)" % Fmt.money(sim.yard_rank_cost(key)), "Buy (%s)" % Fmt.money_k(sim.yard_rank_cost(key))])
		_build.disabled = why_in != ""
		return
	var c: int = int(selected["col"])
	var side: String = selected["side"]
	var k: int = 0 if side == "a" else 1
	var pk: Dictionary = b["picks"][c][k]
	var ot: Dictionary = b["picks"][c][1 - k]
	UI.fit(_title, ["%s · %s, step %d" % [en.call(str(pk["name"])), en.call(str(b["lines"][k])), c + 1], en.call(str(pk["name"]))])
	UI.fit(_words, [en.call(str(pk["words"])) + ".", en.call(str(pk["short"]))])
	if sim.yard_built_side(key, c, side):
		_other.text = "Built"
		_build.text = "Built"
		_build.disabled = true
		return
	if bool(pk.get("stub", false)):
		UI.fit(_other, [Words.REPEAT["stub"]])     # the Bunkhouse's line B (29 Oct): nothing to buy until the trips are in
		UI.fit_button(_build, [Words.REPEAT["stub"], "Not yet"])
		_build.disabled = true
		return
	var why: String = sim.yard_pick_block(key, c, side)
	var tail: String = "" if why == "" else " · " + why
	if sim.yard_side(key, c) != "":
		var second: String = "%s is built · this one costs ×%s" % [en.call(str(ot["name"])), str(Data.YARD_SECOND)]
		UI.fit(_other, ["%s%s" % [second, tail], second])
	else:
		UI.fit(_other, [why if why != "" else "Its twin on %s costs ×%s once this is built" % [en.call(str(b["lines"][1 - k])), str(Data.YARD_SECOND)], why])
	var pick_money: String = Fmt.money(sim.yard_pick_cost(key, c))
	var pick_salv: int = sim.yard_pick_salvage(key, c)
	UI.fit_button(_build, (["Build (%s, %d %s)" % [pick_money, pick_salv, kind]] if pick_salv > 0 else []) + ["Build (%s)" % pick_money, "Build (%s)" % Fmt.money_k(sim.yard_pick_cost(key, c))])
	_build.disabled = why != ""


func _pick_building(key: String) -> void:
	building = key
	selected = {}
	_shown = ""
	acted.emit()


func _press_step(col: int, side: String) -> void:
	_press(building, col, side)


func _press(key: String, col: int, side: String) -> void:
	building = key
	selected = {"key": key, "col": col, "side": side}
	_shown = ""
	acted.emit()


func _press_rank(key := "") -> void:
	building = key if key != "" else building
	selected = {"key": building, "rank": true}
	_shown = ""
	acted.emit()


func _on_build() -> void:
	if selected.is_empty():
		return
	var ok: bool = sim.buy_yard_rank(selected["key"]) if selected.get("rank", false) else sim.yard_pick(selected["key"], int(selected["col"]), selected["side"])
	if ok:
		_shown = ""
		acted.emit()


## For the smoke: a step's look by building key, column and side ("rank" for the rank): "built", "open" (buildable
## now: its line's next, or its twin at the dearer price), "other" (the twin's), "waits" or "shut".
func tile(key: String, col: int, side: String) -> Dictionary:
	if side == "rank":
		return {"look": "built" if sim.yard_rank(key) > 0 else ("open" if sim.yard_rank_block(key) == "" or sim.yard_rank_block(key).begins_with("Short") else "shut")}
	var look := step_look(key, col, side)
	return {"look": {"next": "open", "twin": "other", "stub": "shut"}.get(look, look), "stub": look == "stub"}


func text_nodes() -> Array:
	var out: Array = [_kicker, _headline, _unit, _status, _b_title, _b_sub, _rank_name, _rank_short, _rank_state]
	out.append_array(_chips.text_nodes())
	for c in cards:
		out.append_array([c["name"], c["built"], c["salvage"]] + c["lines"].map(func(x): return x["label"]))
	for r in _gives_rows:
		out.append_array(r)
	out.append_array(_line_heads)
	for col in _tiles:
		for d in col:
			out.append_array([d["name"], d["short"], d["state"]])
	for l in [_title, _words, _other]:
		if l.visible:
			out.append(l)
	if _build.visible:
		out.append(_build)
	return out


func line_pairs() -> Array:
	return [[_headline, _unit]]
