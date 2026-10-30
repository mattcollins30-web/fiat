extends Control
## The Dial (28 Oct, the mockup RadioDial; Matt: "the Radio looks crap"; the web of 22 Oct before it, the lanes of
## 9 Oct before that). The band as the Radio's: the points free and what earns one, the zones' levels as chips, and
## under the Radio's tab bar what a point is; the three regions side by side as columns of named tiles (map_web.gd),
## each a spine to its keystone with two branches, pathed from the region's entry, a ranked node its rank; the sum
## strip as the taken nodes' figures; and the panel under: the pick's name and rank (and why it's shut), its picture
## when painted, its figure as a chip with the next rank's beside, one sentence, Take a rank and Start the Dial again.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Band := preload("res://scripts/ui/band.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Words := preload("res://scripts/sim/words.gd")
const MapWeb := preload("res://scripts/ui/map_web.gd")
const WebView := preload("res://scripts/ui/web_view.gd")
const Items := preload("res://scripts/sim/items.gd")

const W := Pal.GRID_W
const PAD := 20
const BAND_H := Pal.BAND_H         # the Radio's band height, so its tab bar sits on this one as on the air (28 Oct)
const GAP := 12
const LANES_Y := BAND_H + GAP
const PANEL_H := 112               # the pick's strip: its name, its chips and its sentence beside the buttons
const PANEL_Y := Pal.ROOM_H - PANEL_H
const SUM_H := 10 + Chips.CHIP_H + 10
const SUM_Y := PANEL_Y - GAP - SUM_H
const WEB_H := SUM_Y - GAP - LANES_Y     # the columns, in the room between
const SUM_HEAD_W := 150
const SUM_CHIPS := 7               # the taken nodes' figures, so many and a count
const PIC := 88                    # the pick's picture, when it's painted (art/nodes/map_<key>.png)
const RIGHT_W := 660               # the band's words under the Radio's tab bar

var sim
var selected := ""                 # a passive's key, or ""
var _band: Band
var _right: Label                  # what a point is, under the tab bar (the band's right-hand lines before, 28 Oct)
var _web: MapWeb
var _sum_head: Label
var _sum_chips: Chips
var _panel: Panel
var _pic: TextureRect
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
	_band.room_band(true)                     # laid as the Radio's own band (28 Oct): kicker, headline and unit, chips down the left
	_band.chips.size.x = W - 2 * PAD - RIGHT_W - 20     # the zones' four chips in one row, short of the tab bar
	top.add_child(_band)
	_right = UI.label(top, Rect2(W - PAD - RIGHT_W, 92, RIGHT_W, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	UI.shadow(_right)
	_web = MapWeb.new(Vector2(W, WEB_H))
	_web.position = Vector2(0, LANES_Y)
	_web.picked.connect(_pick_web)
	add_child(_web)
	var sum := UI.panel(self, Rect2(0, SUM_Y, W, SUM_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_sum_head = UI.head(sum, Rect2(PAD, 10, SUM_HEAD_W, Chips.CHIP_H), "In total")
	_sum_head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sum_chips = Chips.new(W - 2 * PAD - SUM_HEAD_W - 10, 6)
	_sum_chips.position = Vector2(PAD + SUM_HEAD_W + 10, 10)
	sum.add_child(_sum_chips)
	_panel = UI.panel(self, Rect2(0, PANEL_Y, W, PANEL_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_pic = TextureRect.new()
	_pic.position = Vector2(PAD, (PANEL_H - PIC) / 2.0)
	_pic.size = Vector2(PIC, PIC)
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pic.visible = false
	_panel.add_child(_pic)
	_title = UI.label(_panel, Rect2(PAD, 8, W - 2 * PAD, 36), "", "SemiBold", Pal.TITLE - 4, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_chips = Chips.new(600)
	_chips.position = Vector2(PAD, 46)
	_panel.add_child(_chips)
	_words = UI.label(_panel, Rect2(PAD, 46, W - 2 * PAD, 28), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var by: float = PANEL_H - 6 - Pal.BUTTON_H     # under the title's row: the title has the strip's width for why a node's shut
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
	var pts: String = "point%s" % ("" if sim.atlas_points == 1 else "s")
	_band.set_words("The endgame's tree · The Dial", "", "%d" % free, ["of %d %s free · a point for each signal at or past your reach" % [sim.atlas_points, pts], "of %d %s free" % [sim.atlas_points, pts], "of %d free" % sim.atlas_points, "free"])
	_band.set_right([])
	UI.fit(_right, ["A point for each signal at or past your reach · ranks hold on every site", "Ranks hold on every site", ""])
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


## The pick's strip (28 Oct, RadioDial): its picture when painted, its name and rank and why it's shut across the top,
## its figure and the next rank's as chips, its sentence under them; Take a rank and Start the Dial again at the right.
func _show_panel() -> void:
	var a: Dictionary = _passive(selected)
	_take.visible = not a.is_empty()
	_chips.visible = not a.is_empty()
	_take.text = ""
	if not a.is_empty():
		var rank0: int = sim.atlas_rank(selected)
		_take.text = "Take a rank (1 point)" if rank0 < int(a["max"]) else "Top rank"
		_take.disabled = not sim.can_rank_atlas(selected)
		_take.size.x = ceilf(UI.text_width(_take, _take.text)) + 48
	_reset.disabled = sim.atlas_spent() == 0 or sim.on_mission()
	_reset.size.x = ceilf(UI.text_width(_reset, _reset.text)) + 48
	var x: float = W - PAD - _reset.size.x
	_reset.position.x = x
	if _take.visible:
		x -= 12 + _take.size.x
		_take.position.x = x
	# the words from the picture (or the edge) to the buttons
	var tex: Texture2D = null
	if not a.is_empty():
		tex = WebView.picture(("map_f_" + Items.slug(str(a.get("name", "")))) if a.get("filler", false) else ("map_" + selected))
	_pic.texture = tex
	_pic.visible = tex != null
	var left: float = PAD + (PIC + 16 if tex != null else 0)
	_title.position.x = left
	_title.size.x = W - PAD - left
	_words.position.x = left
	_words.size.x = x - 24 - left
	_chips.position.x = left
	if a.is_empty():
		_title.text = "The Dial"
		_words.position.y = 46
		UI.fit(_words, [Words.MAP["empty"], Words.MAP["empty_short"], "Pick a node above."])
		return
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
	_words.position.y = 46 + Chips.CHIP_H + 6     # under the chips (22 Oct: beside them a long sentence fit nowhere and went blank)
	UI.fit(_words, [str(a["sentence"]), str(a["words"]), ""])


# ------------------------------------------------------------------ acting

func _pick(key: String) -> void:
	selected = key
	_shown = ""
	show_state(sim)


## A tile picked: its key is the panel's; the same tile again puts the panel back to the Dial's words.
func _pick_web(id: String) -> void:
	var key: String = str(Data.map_node(id).get("key", "")) if id != "" else ""
	_pick("" if key == selected else key)


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
	var out: Array = [_title, _words, _sum_head, _reset, _right]
	out.append_array(_band.text_nodes())
	out.append_array(_sum_chips.text_nodes())
	if _chips.visible:
		out.append_array(_chips.text_nodes())
	if _take.visible:
		out.append(_take)
	out.append_array(_web.text_nodes())
	return out


func line_pairs() -> Array:
	return []
