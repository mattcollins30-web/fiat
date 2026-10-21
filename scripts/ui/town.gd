extends Control
## The Radio's third view, the town (18 Oct, docs/design/rebuild.md §6; the canvas "Fiat – The rebuild", Main): the
## places that made it a town as six cards - rank, what they do, what the next rank wants, Rebuild - and the materials
## and the order's things held down the right. Shut until Kev's story is done; the counts show from the first material.
##
## Signals: `acted` after a rebuild.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")

const PAD := 20
const HEAD_H := Pal.BAND_H
const BODY_Y := HEAD_H + 8
const BODY_H := Pal.ROOM_H - BODY_Y
const GAP := 12
const SIDE_W := 320                 # the materials column
const GRID_W := Pal.GRID_W - SIDE_W - GAP
@warning_ignore("integer_division")
const CARD_W := (GRID_W - 2 * GAP) / 3
@warning_ignore("integer_division")
const CARD_H := (BODY_H - GAP) / 2
const CP := 16                      # a card's padding
const ROW_H := 30                   # the materials column's rows
const WANT_ROWS := 2
const RANK_W := 110                 # the rank's room at a card's top right
const COUNT_W := 70                 # a count's room at a row's right

var sim
var _kicker: Label
var _headline: Label
var _unit: Label
var _sub: Label
var _cards: Array = []              # {panel, name, rank, fx: [Label, Label], want_head, chips, button, note, key}
var _side: Panel
var _mat_head: Label
var _mat_rows: Array = []           # [name Label, count Label]
var _key_head: Label
var _key_rows: Array = []
var _side_notes: Array = []        # the column's foot, a sentence over three lines
var _shown := ""


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var head := UI.panel(self, Rect2(0, 0, Pal.GRID_W, HEAD_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	UI.head_art(head, "The radio")
	_kicker = UI.label(head, Rect2(PAD, 8, 420, 24), "Radio · the town", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_headline = UI.label(head, Rect2(PAD, 32, 200, 44), "", "SemiBold", Pal.HEADLINE - 4, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_unit = UI.label(head, Rect2(PAD, 38, 400, 36), "", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(head, Rect2(PAD, 78, 820, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(Data.REBUILDS.size()):
		@warning_ignore("integer_division")
		var x: float = (k % 3) * (CARD_W + GAP)
		@warning_ignore("integer_division")
		var y: float = BODY_Y + (k / 3) * (CARD_H + GAP)
		var p := UI.panel(self, Rect2(x, y, CARD_W, CARD_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
		var iw: float = CARD_W - 2 * CP
		var c := {"panel": p, "key": Data.REBUILDS[k]["key"]}
		c["name"] = UI.label(p, Rect2(CP, 12, iw - RANK_W - 16, 34), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["rank"] = UI.label(p, Rect2(CP, 12, iw, 34), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)     # the row's width, right-aligned: the name fits short of it
		UI.track(c["rank"], 1)              # once: a track on a tracked font nests (the review)
		c["fx"] = [UI.label(p, Rect2(CP, 52, iw, 26), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false),
			UI.label(p, Rect2(CP, 80, iw, 26), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)]
		c["want_head"] = UI.head(p, Rect2(CP, 120, iw, UI.HEAD_H), "")
		c["chips"] = Chips.new(iw, 4)
		c["chips"].position = Vector2(CP, 150)
		p.add_child(c["chips"])
		c["opens"] = UI.label(p, Rect2(CP, CARD_H - CP - Pal.BUTTON_H - 36, iw, 28), "", "Regular", Pal.CELL_TEXT_BIG, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["button"] = UI.button(p, Rect2(CP, CARD_H - CP - Pal.BUTTON_H, iw, Pal.BUTTON_H), true)
		c["button"].pressed.connect(_build.bind(c["key"]))
		c["note"] = UI.label(p, Rect2(CP, CARD_H - CP - Pal.BUTTON_H, iw, Pal.BUTTON_H), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		_cards.append(c)
	_side = UI.panel(self, Rect2(GRID_W + GAP, BODY_Y, SIDE_W, BODY_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var sw: float = SIDE_W - 2 * CP
	_mat_head = UI.head(_side, Rect2(CP, 14, sw, UI.HEAD_H), "Materials")
	var y2 := 14.0 + UI.HEAD_H + 6
	for k in range(Data.MATERIAL_ORDER.size()):
		_mat_rows.append([UI.label(_side, Rect2(CP, y2, sw - COUNT_W - 16, ROW_H), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false),
			UI.label(_side, Rect2(CP, y2, sw, ROW_H), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, true)])
		y2 += ROW_H
	y2 += 14
	_key_head = UI.head(_side, Rect2(CP, y2, sw, UI.HEAD_H), "The order's things")
	y2 += UI.HEAD_H + 6
	for k in range(Data.KEY_ORDER.size()):
		_key_rows.append([UI.label(_side, Rect2(CP, y2, sw - COUNT_W - 16, ROW_H), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false),
			UI.label(_side, Rect2(CP, y2, sw, ROW_H), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, true)])
		y2 += ROW_H
	for k in range(3):
		_side_notes.append(UI.label(_side, Rect2(CP, BODY_H - CP - (3 - k) * 26, sw, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false))


func show_state(s) -> void:
	sim = s
	var sig := "%s|%s|%s|%s|%d|%d" % [str(sim.materials), str(sim.key_items), str(sim.rebuilt), str(sim.rebuild_open()), int(sim.on_mission()), sim.reach]
	sig += "|" + str(Data.PINNACLES.map(func(pn): return sim.order_known(str(pn["key"]))))     # the names scramble with it (20 Oct)
	if sig == _shown:
		return
	_shown = sig
	var open: bool = sim.rebuild_open()
	_headline.text = str(sim.town_worth())
	_unit.position.x = PAD + ceilf(UI.text_width(_headline, _headline.text)) + 10
	_unit.size.x = 820 - _unit.position.x
	UI.fit(_unit, ["the town's worth", "worth"])
	UI.fit(_sub, ["Put back the places that made it a town, one by one.", "Put the town back.", "Rebuild it."] if open
		else ["Kev's story first: the town opens on his last line.", "After Kev's story."])
	for c in _cards:
		_show_card(c, open)
	for k in range(Data.MATERIAL_ORDER.size()):
		var m: String = Data.MATERIAL_ORDER[k]
		var area: int = int(Data.MATERIALS[m]["area"])
		var where: String = "signals" if area < 0 else str(Data.ZONES[area]["name"]).trim_prefix("The ")
		UI.fit(_mat_rows[k][0], ["%s · %s" % [Data.MATERIALS[m]["name"], where], str(Data.MATERIALS[m]["name"])])
		_mat_rows[k][1].text = str(sim.held_of(m))
		var tone: Color = Pal.TEXT if sim.held_of(m) > 0 else Pal.TEXT_3
		_mat_rows[k][0].add_theme_color_override("font_color", tone)
		_mat_rows[k][1].add_theme_color_override("font_color", tone)
	for k in range(Data.KEY_ORDER.size()):
		var ki: String = Data.KEY_ORDER[k]
		UI.fit(_key_rows[k][0], [sim.thing_label(ki)])     # scrambled till known (20 Oct)
		_key_rows[k][1].text = str(sim.held_of(ki))
		var kt: Color = Pal.ACCENT if sim.held_of(ki) > 0 else Pal.TEXT_3
		_key_rows[k][0].add_theme_color_override("font_color", kt)
		_key_rows[k][1].add_theme_color_override("font_color", kt)
	UI.wrap(_side_notes, "From runs only: each area its own, signals more and fuses too. A death never costs them.")


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


func _show_card(c: Dictionary, open: bool) -> void:
	var key: String = c["key"]
	var r: Dictionary = Data.rebuild(key)
	var rank: int = sim.rebuild_rank(key)
	# the caps pass (19 Oct, Matt): the rank in sentence case, the name given the room the rank leaves, and a name
	# short of its "The" still capitalised
	c["rank"].text = ("Rank %d" % rank) if rank > 0 else "Not built"
	c["name"].size.x = c["rank"].size.x - ceilf(UI.text_width(c["rank"], c["rank"].text)) - 16
	UI.fit(c["name"], [str(r["name"]), _cap(str(r["name"]).trim_prefix("The "))])
	c["rank"].add_theme_color_override("font_color", Pal.GOOD if rank > 0 else Pal.TEXT_3)
	var fx: Array = sim.rebuild_words(key, maxi(1, rank))
	for k in range(2):
		UI.fit(c["fx"][k], [str(fx[k]) if k < fx.size() else ""])
		c["fx"][k].add_theme_color_override("font_color", Pal.TEXT_2 if rank > 0 else Pal.TEXT_3)
	c["want_head"].text = ("RANK %d WANTS" % (rank + 1)) if rank > 0 else "FIRST BUILD WANTS"
	var cost: Dictionary = sim.rebuild_cost(key)
	var items: Array = []
	for k in Data.MATERIAL_ORDER + Data.KEY_ORDER:
		if cost.has(k):
			var have: int = sim.held_of(k)
			var nm: String = sim.thing_label(k)
			items.append({"forms": ["%s %d/%d" % [nm, have, int(cost[k])], "%s %d/%d" % [_cap(nm.trim_prefix("The ").get_slice(" ", 0)), have, int(cost[k])]],
				"colour": "good" if have >= int(cost[k]) else "bad"})
	c["chips"].show_chips(items, WANT_ROWS, true)
	c["items"] = items.size()
	var opens: String = str(r.get("opens", ""))
	if opens != "":
		var p: Dictionary = Data.pinnacle(opens)
		var kn: bool = sim.order_known(opens)     # 20 Oct: the place and its head scrambled till found
		var pl: String = Words.mid(p["place"]) if kn else Fmt.scramble(str(p["place"]))
		var wh: String = str(p["who"]) if kn else Fmt.scramble(str(p["who"]))
		UI.fit(c["opens"], [("Opened %s · %s" if rank > 0 else "Opens %s · %s") % [pl, wh], ("Opened %s" if rank > 0 else "Opens %s") % pl])     # after the dot a name starts its own words: The Lineman
	else:
		c["opens"].text = ""
	var why: String = sim.rebuild_block(key)
	c["button"].visible = open and why == ""
	c["note"].visible = not c["button"].visible
	UI.fit_button(c["button"], ["Rebuild · rank %d" % (rank + 1) if rank > 0 else "Rebuild", "Rebuild"])
	UI.fit(c["note"], [why, ""])
	var sb := UI.box(Pal.PANEL, 8, 2 if rank > 0 else 1, Pal.GOOD if rank > 0 else Pal.CARD_LINE)
	c["panel"].add_theme_stylebox_override("panel", sb)


func _build(key: String) -> void:
	if sim != null and sim.rebuild_place(key):
		_shown = ""
		show_state(sim)
		acted.emit()


## For the tests: a card by its place's key.
func card(key: String) -> Dictionary:
	for c in _cards:
		if c["key"] == key:
			return c
	return {}


func text_nodes() -> Array:
	var out: Array = [_kicker, _headline, _unit, _sub, _mat_head, _key_head] + _side_notes
	for c in _cards:
		out.append_array([c["name"], c["rank"], c["want_head"], c["opens"]] + c["fx"])
		out.append_array(c["chips"].text_nodes())
		if c["button"].visible:
			out.append(c["button"])
		if c["note"].visible:
			out.append(c["note"])
	for row in _mat_rows + _key_rows:
		out.append_array(row)
	return out


func line_pairs() -> Array:
	var out: Array = [[_headline, _unit]]
	for c in _cards:
		out.append([c["name"], c["rank"]])
	for row in _mat_rows + _key_rows:
		out.append(row)
	return out
