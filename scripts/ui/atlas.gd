extends Control
## The map (Map-A, 7 Oct): the endgame's tree in the caravan's shape, in the
## Runs room where the columns stand. A band (the points free, what earns one,
## the zones' depths as chips); the six passives as tiles in three columns by
## what they touch - the sites, the crews, the air - each with its ranks as
## pips and lined in the accent once one is taken; the sum strip as chips; and
## the panel under: the pick's name and rank, its figure as a chip with the next
## rank's beside, one sentence, Take a rank and Start the map again. Picking a
## tile fills the panel, as the caravan does.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Band := preload("res://scripts/ui/band.gd")
const Chips := preload("res://scripts/ui/chips.gd")

const W := Pal.GRID_W
const PAD := 20
const BAND_H := 170                # the band's chips sit under the headline at this height (150 puts them over it)
const COL_GAP := 16
const COL_W := (W - 2 * COL_GAP) / 3                           # 501
const COLS_Y := BAND_H + 14
const HEAD_H := 34
const TILE_H := 64
const TILE_GAP := 8
const TILES_Y := COLS_Y + HEAD_H + 6
const TILE_ROWS := 3
const SUM_Y := TILES_Y + TILE_ROWS * (TILE_H + TILE_GAP) - TILE_GAP + 12
const SUM_H := 10 + Chips.CHIP_H + 10
const SUM_HEAD_W := 150
const PANEL_Y := SUM_Y + SUM_H + 12
const PIP := 10
const PIP_GAP := 4

## The columns: what each passive touches.
const GROUPS := [
	{"name": "The sites", "keys": ["picked_over", "deeper_pockets", "quiet_roads"]},
	{"name": "The crews", "keys": ["paid_in_notes", "two_of_everything"]},
	{"name": "The air", "keys": ["word_travels"]},
]
## A passive's figure at a rank (0: nothing yet), its sentence, and the sum strip's key for it.
const FIGURES := {
	"picked_over": {"ranks": ["", "a third of finds", "half of finds", "two-thirds of finds"], "sum": "Own finds", "sum_ranks": ["as they come", "a third", "half", "two-thirds"],
		"sentence": "A site's own things turn up more of the time."},
	"paid_in_notes": {"ranks": ["", "+1 note a kill", "+2 notes a kill", "+3 notes a kill"], "sum": "Notes", "sum_ranks": ["as they come", "+1 a kill", "+2 a kill", "+3 a kill"],
		"sentence": "Every kill carries a note more."},
	"two_of_everything": {"ranks": ["", "two of theirs"], "sum": "Heads", "sum_ranks": ["drop one", "drop two"],
		"sentence": "A crew's head drops two of theirs."},
	"deeper_pockets": {"ranks": ["", "searches 10% quicker", "searches 20% quicker", "searches 30% quicker"], "sum": "Searches", "sum_ranks": ["as they come", "10% quicker", "20% quicker", "30% quicker"],
		"sentence": "The picking-over goes quicker, on every site."},
	"word_travels": {"ranks": ["", "the word at half price"], "sum": "The word", "sum_ranks": ["full price", "half price"],
		"sentence": "Calling in a word on the radio costs half."},
	"quiet_roads": {"ranks": ["", "gangs 10% later", "gangs 20% later", "gangs 30% later"], "sum": "Gangs", "sum_ranks": ["as they come", "10% later", "20% later", "30% later"],
		"sentence": "The next gang takes longer to arrive, on every site."},
}

var sim
var selected := ""                 # a passive's key, or ""
var _band: Band
var _heads: Array = []             # per column: {name, count}
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
	_band = Band.new(W, BAND_H, 3)
	_band.set_site("the map")
	top.add_child(_band)
	for c in range(GROUPS.size()):
		var x: int = c * (COL_W + COL_GAP)
		var g: Dictionary = GROUPS[c]
		var head := {}
		head["name"] = UI.label(self, Rect2(x + 4, COLS_Y, COL_W - 8, HEAD_H), g["name"], "SemiBold", Pal.LINE - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		head["count"] = UI.label(self, Rect2(x + 4, COLS_Y, COL_W - 8, HEAD_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
		_heads.append(head)
		for r in range(g["keys"].size()):
			var key: String = g["keys"][r]
			var a: Dictionary = _passive(key)
			var t := {}
			var b := Button.new()
			b.position = Vector2(x, TILES_Y + r * (TILE_H + TILE_GAP))
			b.size = Vector2(COL_W, TILE_H)
			b.pressed.connect(_pick.bind(key))
			add_child(b)
			t["button"] = b
			t["name"] = UI.label(b, Rect2(12, 8, COL_W - 24, 26), a["name"], "SemiBold", Pal.LINE - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			t["words"] = UI.label(b, Rect2(12, 34, COL_W - 24, 24), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			var pips: Array = []
			for k in range(int(a["max"])):
				var p := UI.panel(b, Rect2(COL_W - 12 - (int(a["max"]) - k) * (PIP + PIP_GAP) + PIP_GAP, 16, PIP, PIP), UI.box(Color.TRANSPARENT, PIP / 2, 1, Pal.CARD_LINE))
				pips.append(p)
			t["pips"] = pips
			t["name"].size.x = COL_W - 24 - int(a["max"]) * (PIP + PIP_GAP) - 8
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
	_chips.position = Vector2(PAD, 47)
	_panel.add_child(_chips)
	_words = UI.label(_panel, Rect2(PAD, 46, W - 2 * PAD, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var by: float = _panel.size.y - PAD - Pal.BUTTON_H
	_take = UI.button(_panel, Rect2(0, by, 240, Pal.BUTTON_H), true)
	_take.pressed.connect(_on_take)
	_reset = UI.button(_panel, Rect2(0, by, 240, Pal.BUTTON_H), false)
	_reset.text = "Start the map again"
	_reset.pressed.connect(_on_reset)


static func _passive(key: String) -> Dictionary:
	for a in Data.ATLAS:
		if a["key"] == key:
			return a
	return {}


func _style(b: Button, look: String) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var sb: StyleBoxFlat
		match look:
			"taken":
				sb = UI.box(Pal.SELECT, 8)
				sb.border_width_left = 6
				sb.border_color = Pal.ACCENT
			_:
				sb = UI.box(Pal.CARD if state == "hover" else Pal.PANEL, 8)
		if look == "selected":
			sb = UI.box(Pal.SELECT, 8)
			sb.set_border_width_all(2)
			sb.border_color = Pal.ACCENT
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 8, 2, Pal.TEXT))


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	var sig := "%s|%d|%s|%s|%s" % [str(sim.atlas), sim.atlas_points, selected, str(sim.best_depth), str(sim.on_mission())]
	if sig == _shown:
		return
	_shown = sig
	var free: int = sim.atlas_free()
	_band.set_words("The map · the endgame's tree", "The map", "%d" % free, ["of %d point%s free" % [sim.atlas_points, "" if sim.atlas_points == 1 else "s"], "of %d free" % sim.atlas_points, "free"])
	_band.set_right(["A point a new depth,", "past the first, any site.", "Holds on every site."])
	var zones := []
	for z in range(Data.ZONES.size()):
		var deepest := 0
		for i in Data.ZONES[z]["tiers"]:
			deepest = maxi(deepest, sim.best_depth[i])
		zones.append({"forms": ["%s · depth %d" % [Data.ZONES[z]["name"], deepest], "depth %d" % deepest], "colour": Pal.TEXT_2})
	_band.set_chips(zones)
	for c in range(GROUPS.size()):
		var g: Dictionary = GROUPS[c]
		var taken := 0
		var of := 0
		for key in g["keys"]:
			var a: Dictionary = _passive(key)
			var rank: int = sim.atlas_rank(key)
			taken += rank
			of += int(a["max"])
			var t: Dictionary = _tiles[key]
			var f: Dictionary = FIGURES[key]
			UI.fit(t["words"], [f["ranks"][rank] if rank > 0 else str(a["words"]), str(a["words"]).get_slice(":", 0)])
			for k in range(t["pips"].size()):
				t["pips"][k].add_theme_stylebox_override("panel", UI.box(Pal.ACCENT if k < rank else Color.TRANSPARENT, PIP / 2, 1, Pal.ACCENT if k < rank else Pal.CARD_LINE))
			_style(t["button"], "selected" if key == selected else ("taken" if rank > 0 else "open"))
		_heads[c]["count"].text = "%d of %d rank%s" % [taken, of, "" if of == 1 else "s"]
	# the sum strip
	var items := []
	for key in FIGURES:
		var f: Dictionary = FIGURES[key]
		var rank: int = sim.atlas_rank(key)
		items.append({"tag": f["sum"], "forms": [f["sum_ranks"][rank]], "colour": Pal.GOOD if rank > 0 else Pal.TEXT_2})
	_sum_chips.show_chips(items)
	_show_panel()


func _show_panel() -> void:
	var a: Dictionary = _passive(selected)
	_take.visible = not a.is_empty()
	_chips.visible = not a.is_empty()
	if a.is_empty():
		_title.text = "The map"
		_words.position.x = PAD
		_words.size.x = W - 2 * PAD
		UI.fit(_words, ["Pick a passive above. A point for every new depth cleared past the first; what is taken here holds on every site.", "Pick a passive above."])
	else:
		var rank: int = sim.atlas_rank(selected)
		var f: Dictionary = FIGURES[selected]
		_title.text = "%s · rank %d of %d" % [a["name"], rank, int(a["max"])]
		var items := []
		if rank > 0:
			items.append({"forms": [f["ranks"][rank]], "colour": Pal.GOOD})
		if rank < int(a["max"]):
			items.append({"forms": [("next: " if rank > 0 else "") + str(f["ranks"][rank + 1])], "colour": Pal.TEXT_2 if rank > 0 else Pal.ACCENT})
		_chips.show_chips(items)
		_words.position.x = PAD + _chips.used_width() + 10
		_words.size.x = W - PAD - _words.position.x
		UI.fit(_words, [f["sentence"], ""])
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
		out.append_array([h["name"], h["count"]])
	for key in _tiles:
		out.append_array([_tiles[key]["name"], _tiles[key]["words"]])
	return out


func line_pairs() -> Array:
	var out: Array = []
	for h in _heads:
		out.append([h["name"], h["count"]])
	return out
