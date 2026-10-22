extends Control
## The Dial as a web (22 Oct, docs/design/web_map_pitch.md §1; the lanes of 9 Oct before it). The band (the points
## free, what earns one, the zones' levels as chips); the Map's web on the canvas (map_web.gd): three regions off a
## centre - the sites, the crews, the codes - each a spine to its keystone with two branches, pathed from the
## region's entry, a ranked node a stack; the sum strip as the taken nodes' figures; and the panel under: the pick's
## name and rank (and why it's shut), its figure as a chip with the next rank's beside, one sentence, Take a rank
## and Start the Dial again.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Band := preload("res://scripts/ui/band.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Words := preload("res://scripts/sim/words.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")
const MapWeb := preload("res://scripts/ui/map_web.gd")

const W := Pal.GRID_W
const PAD := 20
const BAND_H := 170                # the band's chips sit under the headline at this height (150 puts them over it)
const LANES_Y := BAND_H + 12
const WEB_H := 432                 # the canvas, in the three lanes' room
const SUM_Y := LANES_Y + WEB_H + 12
const SUM_H := 10 + Chips.CHIP_H + 10
const SUM_HEAD_W := 150
const SUM_CHIPS := 7               # the taken nodes' figures, so many and a count
const PANEL_Y := SUM_Y + SUM_H + 12

var sim
var selected := ""                 # a passive's key, or ""
var _band: Band
var _web: MapWeb
var _web_buttons: Array = []       # over the canvas's corner: the whole Dial, each region
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
	_web = MapWeb.new(Vector2(W, WEB_H))
	_web.position = Vector2(0, LANES_Y)
	_web.picked.connect(_pick_web)
	add_child(_web)
	var x: float = 12.0
	for words in ["The whole Dial", "The sites", "The crews", "The codes"]:
		var b := UI.button(self, Rect2(x, LANES_Y + 10, 120, 30), false)
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 2)
		b.text = words
		b.pressed.connect(_web.focus_named.bind(words))
		var w: float = ceilf(UI.text_width(b, words)) + 40.0
		b.size.x = w
		_web_buttons.append(b)
		x += w + 6.0
	var sum := UI.panel(self, Rect2(0, SUM_Y, W, SUM_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_sum_head = UI.head(sum, Rect2(PAD, 10, SUM_HEAD_W, Chips.CHIP_H), "In total")
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


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	var sig := "%s|%d|%s|%s|%s" % [str(sim.atlas), sim.atlas_points, selected, str(sim.best_depth), str(sim.on_mission())]
	if sig == _shown:
		return
	_shown = sig
	var free: int = sim.atlas_free()
	_band.set_words("The endgame's tree", "The Dial", "%d" % free, ["of %d point%s free" % [sim.atlas_points, "" if sim.atlas_points == 1 else "s"], "of %d free" % sim.atlas_points, "free"])
	_band.set_right(["A point for each signal", "at or past your reach.", "Ranks hold on every site."])
	var zones := []
	for z in range(Data.ZONES.size()):
		var best_lv := 0                    # the best level cleared there (18 Oct: levels, not depths, on screen)
		for i in Data.ZONES[z]["tiers"]:
			if sim.best_depth[i] > 0:
				best_lv = maxi(best_lv, sim.lv_at(i, sim.best_depth[i]))
		zones.append({"forms": ["%s · level %d" % [Data.ZONES[z]["name"], best_lv], "level %d" % best_lv], "colour": Pal.TEXT_2})
	_band.set_chips(zones)
	var items := []
	var more := 0
	for a in Data.ATLAS:                   # the ranked nodes' figures; the fillers' are the ranked nodes' shares (atlas_level)
		var key: String = a["key"]
		var rank: int = sim.atlas_rank(key)
		if rank > 0:
			if items.size() < SUM_CHIPS:
				items.append({"tag": str(a["sum"]), "forms": [str(a["figures"][rank])], "colour": Pal.GOOD})
			else:
				more += 1
	_web.selected = Data.map_id(selected)
	_web.show_state(sim)
	# the sum strip: the taken nodes' figures, so many and a count; nothing taken, the point's worth
	if more > 0:
		items.append({"tag": "and", "forms": ["%d more" % more], "colour": Pal.TEXT_2})
	if items.is_empty():
		items.append({"forms": ["Nothing taken yet: a point for each signal won at your reach"], "colour": Pal.TEXT_2})
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
		UI.fit(_words, [Words.MAP["empty"], Words.MAP["empty_short"], "Pick a node above."])
	else:
		var rank: int = sim.atlas_rank(selected)
		var figs: Array = a["figures"]
		var needs: String = sim.atlas_block(selected, true) if rank < int(a["max"]) else ""     # the path's want, or nothing
		if needs == "the runner is out":
			needs = ""
		UI.fit(_title, ["%s · rank %d of %d%s" % [a["name"], rank, int(a["max"]), (" · " + needs) if needs != "" else ""], "%s · rank %d of %d" % [a["name"], rank, int(a["max"])], str(a["name"])])
		var items := []
		if rank > 0:
			items.append({"forms": [str(figs[rank])], "colour": Pal.GOOD})
		if rank < int(a["max"]):
			items.append({"forms": [("next: " if rank > 0 else "") + str(figs[rank + 1])], "colour": Pal.TEXT_2 if rank > 0 else Pal.ACCENT})
		_chips.show_chips(items)
		_words.position = Vector2(PAD, 52 + Chips.CHIP_H + 10)     # under the chips, the panel's width (22 Oct: beside them a long sentence fit nowhere and went blank)
		_words.size.x = W - 2 * PAD
		UI.fit(_words, [str(a["sentence"]), str(a["words"]), ""])
		_take.text = "Take a rank (1 point)" if rank < int(a["max"]) else "Top rank"
		_take.disabled = not sim.can_rank_atlas(selected)
		_take.size.x = ceilf(UI.text_width(_take, _take.text)) + 48
	_reset.disabled = sim.atlas_spent() == 0 or sim.on_mission()
	_reset.size.x = ceilf(UI.text_width(_reset, _reset.text)) + 48
	var x: float = W - PAD - _reset.size.x
	_reset.position.x = x
	if _take.visible:
		x -= 12 + _take.size.x
		_take.position.x = x
	if _passive(selected).is_empty():
		_words.position = Vector2(PAD, 52)


# ------------------------------------------------------------------ acting

func _pick(key: String) -> void:
	selected = key
	_shown = ""
	show_state(sim)


## A node picked on the canvas: its key is the panel's.
func _pick_web(id: String) -> void:
	_pick(str(Data.map_node(id).get("key", "")) if id != "" else "")


## Focus the canvas on a region by its column (the Radio's Juice chip: the codes).
func focus_column(c: int) -> void:
	for t in Data.MAP_WEB:
		if int(t["column"]) == c:
			_web.focus_tree(t["name"])


func web():
	return _web


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
	out.append_array(_web_buttons)
	return out


func line_pairs() -> Array:
	return []
