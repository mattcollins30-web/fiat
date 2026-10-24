extends Control
## The Pitch as a web (22 Oct, docs/design/web_map_pitch.md §2; the lanes of 9 Oct, docs/design/yard.md, before
## it). Eight buildings as eight regions off the centre on the canvas (yard_web.gd): a building's five columns as
## forks along its spine - the two picks of a column, either first, the other later at 2.5 times (24 Oct, option B) -
## and its ranks a chain past them, bought again and again. A column opens on the campaign and the depth, for
## good, as before. The header: the picks built, the purse (cash, notes, scrap and the three salvages) and Move the
## Yard. The strip at the foot: the picked node's sentence, its other half, its price and its button; with nothing
## picked, the town's note and the clock.
##
## `show_state(sim, purse)`: purse from main._town_purse() (its `left.note`, `status` and `button`).

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Data := preload("res://scripts/sim/data.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")
const YardWeb := preload("res://scripts/ui/yard_web.gd")

const PAD := 20
## The heading takes the room the glyph lanes left (10 Oct, Matt: "moving everything down and making the header fit
## the space"): the lanes and the strip sit at the foot, the Yard's painted place above them.
const HEAD_H := Pal.ROOM_H - 8 - WEB_H - 6 - STRIP_H     # the canvas in the eight lanes' room
const CHIPS_Y := 88                  # the purse under the headline (it ends at 76), down the left
const CHIPS_W := 330                 # the title's width
const CHIPS_ROWS := 3
const LANES_Y := HEAD_H + 8
# the lanes in the tree's glyphs (10 Oct, Lanes-G; Matt: "yard and map look really bad now" beside Training): a
# column's two picks as glyph tiles side by side, its price beside them; the rank's tile, figure and pips at the end
const COLS := 6
const WEB_H := 8 * 64 + 7 * 4          # the eight lanes' height (the heading above keeps its room)
const STRIP_Y := LANES_Y + WEB_H + 6
const STRIP_H := 92                                         # under the lanes, its own height (the review: the rest of the room left it half empty)
const BUILD_W := 260

var head_band := {}                # the heading's painted place (10 Oct, Rooms-B)
var sim
var selected := {}                  # {key, col, side} a pick, {key, rank: true} a rank, {} nothing
var _kicker: Label
var _headline: Label
var _unit: Label
var _chips: Chips
var _web: YardWeb
var _web_buttons: Array = []       # over the canvas's corner: the whole Pitch, each building
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
	_web = YardWeb.new(Vector2(Pal.GRID_W, STRIP_Y - 6 - LANES_Y))
	_web.position = Vector2(0, LANES_Y)
	_web.picked.connect(_pick_web)
	add_child(_web)
	var x: float = 12.0
	for words in ["The whole Pitch"] + Data.YARD.map(func(b): return str(b["name"])):
		var btn := UI.button(self, Rect2(x, LANES_Y + 10, 120, 30), false)
		btn.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 2)
		btn.text = words
		btn.pressed.connect(_web.focus_named.bind(words))
		var w: float = ceilf(UI.text_width(btn, words)) + 40.0
		btn.size.x = w
		_web_buttons.append(btn)
		x += w + 6.0
	var strip := UI.panel(self, Rect2(0, STRIP_Y, Pal.GRID_W, STRIP_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	var tw: float = Pal.GRID_W - 2 * PAD - BUILD_W - 16
	_title = UI.label(strip, Rect2(PAD, 2, tw, 32), "", "SemiBold", Pal.TITLE - 4, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_words = UI.label(strip, Rect2(PAD, 32, tw, 24), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_other = UI.label(strip, Rect2(PAD, 54, tw, 23), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_foot = UI.label(strip, Rect2(PAD, 8, tw, 30), "", "Regular", Pal.FLOOR - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_foot_right = UI.label(strip, Rect2(PAD, 42, tw, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_build = UI.button(strip, Rect2(Pal.GRID_W - PAD - BUILD_W, 12, BUILD_W, Pal.BUTTON_H), true)     # level with the title
	_build.pressed.connect(_on_build)


func show_state(s, purse: Dictionary) -> void:
	sim = s
	var sig := "%s|%s|%s|%d|%d|%s|%s|%d|%d|%s|%s|%.3f|%d" % [str(selected), str(sim.yard_picks), str(sim.yard_ranks), int(sim.cash), sim.yard_cols(), str(sim.salvage), str(sim.on_mission()),
		sim.notes, sim.scrap, str(purse.get("left", {}).get("note", "")), str(purse.has("button")), sim.inflation(), sim.stash_used()]
	if sig == _shown:
		if _foot_right.visible:
			var st = purse.get("status", "")
			UI.fit(_foot_right, st if st is Array else [str(st)])     # the clock moves
		return
	_shown = sig
	var built: int = sim.yard_built()
	var of: int = Data.YARD.size() * (COLS - 1) * 2     # both sides of every column (24 Oct, option B)
	UI.fit(_kicker, ["The Pitch"])
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
	_web.selected = _selected_id()
	_web.show_state(sim)
	_show_strip(purse)


## The picked node's id on the canvas, or "".
func _selected_id() -> String:
	if selected.is_empty():
		return ""
	for t in Data.YARD_WEB:
		if t["yard"] != selected["key"]:
			continue
		for i in range(t["nodes"].size()):
			var nd: Dictionary = t["nodes"][i]
			if selected.get("rank", false) and int(nd.get("rank", 0)) == mini(5, sim.yard_rank(str(selected["key"])) + 1):
				return "%s/%d" % [t["name"], i]
			if not selected.get("rank", false) and int(nd.get("col", -1)) == int(selected.get("col", -2)) and str(nd.get("side", "")) == str(selected.get("side", "")):
				return "%s/%d" % [t["name"], i]
	return ""


## A node picked on the canvas: a pick or a rank in the strip.
func _pick_web(id: String) -> void:
	if id == "":
		selected = {}
	else:
		var nd: Dictionary = Data.yard_node(id)
		if nd.has("rank"):
			selected = {"key": str(nd["yard"]), "rank": true}
		else:
			selected = {"key": str(nd["yard"]), "col": int(nd["col"]), "side": str(nd["side"])}
	_shown = ""
	acted.emit()


static func salvage_colour(kind: String) -> Color:
	return {"copper": Color("d08a5a"), "steel": Color("9fb3c8"), "army": Color("a3b06a")}.get(kind, Pal.TEXT_2)


## A building whose room isn't open yet reads scrambled, its name and its upgrades' words (20 Oct, Matt: "the trees here
## for radio and the bench should be encrypted until they unlock"); its prices and its glyphs stay.
func _en_for(key: String) -> Callable:
	var known: bool = sim.room_open(sim.building_room(key))
	return func(t: String) -> String: return t if known else Fmt.scramble(t)


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
	var en := _en_for(key)
	if selected.get("rank", false):
		UI.fit(_title, ["%s · rank %d" % [en.call(str(b["name"])), sim.yard_rank(key)], en.call(str(b["name"]))])
		UI.fit(_words, ["%s. Bought again and again; each rank dearer than the last." % en.call(str(b["rank"]["words"])), en.call(str(b["rank"]["words"])) + "."])
		var why_in: String = sim.yard_rank_block(key)
		var price_in: String = "Rank %d: %s and %d %s" % [sim.yard_rank(key) + 1, Fmt.money(sim.yard_rank_cost(key)), sim.yard_rank_salvage(key), kind]
		UI.fit(_other, [price_in + ("" if why_in == "" else " · " + why_in), price_in, "%s · %d %s" % [Fmt.money(sim.yard_rank_cost(key)), sim.yard_rank_salvage(key), kind]])
		# the price on the button itself (24 Oct, Matt: "the buy button doesn't list the cost"), as Train shows its points
		var rank_money: String = Fmt.money(sim.yard_rank_cost(key))
		# just the price (24 Oct, Matt: "should just be 'buy N tins'"): the rank's in the title and the copper's on the line above
		UI.fit_button(_build, ["Buy (%s)" % rank_money, "Buy (%s)" % Fmt.money_k(sim.yard_rank_cost(key))])
		_build.disabled = why_in != ""
		return
	var c: int = int(selected["col"])
	var side: String = selected["side"]
	var pk: Dictionary = b["picks"][c][0 if side == "a" else 1]
	var ot: Dictionary = b["picks"][c][1 if side == "a" else 0]
	var built: String = sim.yard_side(key, c)
	UI.fit(_title, ["%s · %s, column %d" % [en.call(str(pk["name"])), en.call(str(b["name"])), c + 1], en.call(str(pk["name"]))])
	UI.fit(_words, [en.call(str(pk["words"])) + ".", en.call(str(pk["short"]))])
	var or_line: String = "Or %s: %s" % [en.call(str(ot["name"])), en.call(str(ot["words"]).to_lower())]
	if built.contains(side):
		UI.fit(_other, ["Built"] if built.length() > 1 else ["Built · %s" % or_line, "Built"])
		_build.text = "Built"
		_build.disabled = true
		return
	var why: String = sim.yard_pick_block(key, c, side)
	var price: String = Fmt.money(sim.yard_pick_cost(key, c)) + ("" if sim.yard_pick_salvage(key, c) == 0 else " and %d %s" % [sim.yard_pick_salvage(key, c), kind])
	var tail: String = "" if why == "" else " · " + why
	if built != "":
		# the column's other side built (24 Oct, option B: nothing locks): this one at its dearer price
		var second: String = "%s is built · this one costs ×%s" % [en.call(str(ot["name"])), str(Data.YARD_SECOND)]
		UI.fit(_other, ["%s · %s%s" % [second, price, tail], "%s%s" % [second, tail], second])
	else:
		UI.fit(_other, ["%s · %s%s" % [price, or_line, tail], "%s%s" % [price, tail], price])
	var pick_money: String = Fmt.money(sim.yard_pick_cost(key, c))
	var pick_salv: int = sim.yard_pick_salvage(key, c)
	UI.fit_button(_build, (["Build (%s, %d %s)" % [pick_money, pick_salv, kind]] if pick_salv > 0 else []) + ["Build (%s)" % pick_money, "Build (%s)" % Fmt.money_k(sim.yard_pick_cost(key, c))])
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


## For the smoke: a pick's look by building key, column and side ("rank" for the rank) - "built", "open", "other"
## (the column's other side built, this one at the dearer price) or "shut" (its column shut), as the lanes' tiles read.
func tile(key: String, col: int, side: String) -> Dictionary:
	if side == "rank":
		return {"look": "built" if sim.yard_rank(key) > 0 else ("open" if sim.yard_cols() >= COLS else "shut")}
	var built: String = sim.yard_side(key, col)
	var look := "shut"
	if built.contains(side):
		look = "built"
	elif built != "":
		look = "other"                        # its other side built: open, at the dearer price (option B)
	elif col < sim.yard_cols():
		look = "open"
	return {"look": look}


func web():
	return _web


func text_nodes() -> Array:
	var out: Array = [_kicker, _headline, _unit]
	out.append_array(_chips.text_nodes())
	for l in [_title, _words, _other, _foot, _foot_right]:
		if l.visible:
			out.append(l)
	if _build.visible:
		out.append(_build)
	out.append_array(_web_buttons)
	return out


func line_pairs() -> Array:
	return [[_headline, _unit]]
