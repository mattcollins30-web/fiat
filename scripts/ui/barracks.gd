extends Control
## The Caravan's screen: what the runner was, and training (9 Oct, docs/design/trees.md). Every tree a lane
## on one screen, read left to right in six columns: the class's first tree, the element it joins, the
## class's second, the element that one joins, the Yard's. A joint is the link between a class lane and the
## element lane under it, in the fourth column. Under the lanes the "Also" row - the elements off the pair,
## the second past's tree, the drawer, the shelf - each a chip that swaps the Yard's lane for it. Then what
## the trees add up to, and the strip for the selected node with Train and Respec. Fixed geometry inside the
## card grid's 1536 x 916.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const People := preload("res://scripts/ui/people.gd")
const Words := preload("res://scripts/sim/words.gd")
const Items := preload("res://scripts/sim/items.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")
const WebView := preload("res://scripts/ui/web_view.gd")

const PAD := 20
# the header: the face, the class and trait, the points free, the class's line; the classes top right
const HEAD_H := Pal.BAND_H                                     # the rooms' one band (10 Oct, Bands-U A): 96 → 180
const FACE := Pal.BAND_FACE
# the pasts as cards (14 Oct, Matt; docs/design/mockups/class_cards_mockup.png): a face, the name, the short lines in
# their tones (a cost red); the picked one lit, the rest dimmed; the whole sentence a tooltip
const CLASS_W := 164                # the words column keeps the width the sum strip needs
const CLASS_H := 122
const CLASS_GAP := 8
const CLASS_FACE := 48
const CLASS_SHORT := 3             # short lines a card holds
# the line over the cards (the trait, the change's price, or the prompt) on a glass pill so the art doesn't eat it
# (12 Oct); the class's own sentence went to the cards' tooltips (14 Oct)
const NOTICE_Y := HEAD_H - 14 - CLASS_H - 34
const LINE_TOP_Y := NOTICE_Y
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
@warning_ignore("integer_division")
const TILE_W := (Pal.GRID_W - TILES_X - 8 - (COLS - 1) * TILE_GAP) / COLS     # 219
@warning_ignore("integer_division")
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
@warning_ignore("integer_division")
const PAGE_W := (Pal.GRID_W - (PAGE_COLS - 1) * PAGE_GAP) / PAGE_COLS
const PAGE_CELLS := 24
const NAME_H := 36
const WORD_H := 26                                             # a line of a paper's or a unique's words

var sim
var selected := ""                 # a node id, or ""
var alt := ""                      # the Also chip in the Yard's place: a tree's name, "The drawer", "The mantelpiece", or "" for the Yard
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
var _class_cards: Array = []       # a card a past: {face, name, tag, lines[]}
var _face_q: Panel                 # no past yet: a ? in the face's place
var _web                            # the web (22 Oct): every tree as a region of one canvas, in the lanes' place
var _web_buttons: Array = []       # over the web's corner: the whole web, the class's region, the Pitch
var _find: LineEdit                # "Find a perk" (22 Oct, slice 2): typing centres the web on the first name that fits
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
var _past_bar: Panel                # the second past's points, under way (15 Oct)
var _past_fill: Panel
var _train: Button
var _respec: Button


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_head()
	_build_web()
	_build_also()
	_build_pages()
	_sum = Panel.new()                  # a frame in the band: the head's words column, two chip rows
	_sum.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_sum.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sum.position = Vector2(_words_x(), SUM_Y)
	_sum.size = Vector2(_words_w(), SUM_H)
	head_band["art"].get_parent().add_child(_sum)
	_sum_head = UI.head(_sum, Rect2(0, 0, SUM_HEAD_W, Chips.CHIP_H), "In total")
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
	_face_q = UI.panel(head, Rect2(16, (HEAD_H - FACE) / 2.0, FACE, FACE), UI.box(PILL_GLASS, 10, 1, Pal.CARD_LINE))
	UI.label(_face_q, Rect2(0, 0, FACE, FACE), "?", "SemiBold", 64, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER)
	_face_q.visible = false
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
		var cd: Dictionary = Data.CLASSES[k]
		var cb := Button.new()
		cb.position = Vector2(cx0 + k * (CLASS_W + CLASS_GAP), HEAD_H - 14 - CLASS_H)
		cb.size = Vector2(CLASS_W, CLASS_H)
		cb.focus_mode = Control.FOCUS_ALL
		cb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		cb.tooltip_text = "%s: %s" % [cd["name"], cd["words"]]
		cb.pressed.connect(_pick_class.bind(cd["name"]))
		head.add_child(cb)
		_class_buttons.append(cb)
		var face := People.rect(cb, Vector2(8, 8), CLASS_FACE / 128.0)
		People.show(face, str(cd["name"]))
		var nm := UI.label(cb, Rect2(CLASS_FACE + 12, 10, CLASS_W - CLASS_FACE - 16, 26), str(cd["name"]), "SemiBold", 19, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var tag := UI.label(cb, Rect2(CLASS_FACE + 12, 37, CLASS_W - CLASS_FACE - 16, 20), "", "Medium", 14, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var lines: Array = []
		for r in range(CLASS_SHORT):
			lines.append(UI.label(cb, Rect2(9, CLASS_FACE + 13 + r * 17, CLASS_W - 14, 18), "", "Medium", 14, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		for n in [nm, tag] + lines:
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_class_cards.append({"face": face, "name": nm, "tag": tag, "lines": lines})
	_notice = UI.label(head, Rect2(cx0, NOTICE_Y, Pal.GRID_W - PAD - cx0, 30), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)


static func _classes_x() -> float:
	return Pal.GRID_W - PAD - Data.CLASSES.size() * CLASS_W - CLASS_GAP * (Data.CLASSES.size() - 1)


## The band's words column: past the face, up to the classes.
static func _words_x() -> float:
	return 16 + FACE + 14


static func _words_w() -> float:
	return _classes_x() - 24 - _words_x()


## The web in the lanes' place (22 Oct): the canvas, and three buttons over its corner to jump the zoom.
func _build_web() -> void:
	_web = WebView.new(Vector2(Pal.GRID_W, LANES_H))
	_web.position = Vector2(0, LANES_Y)
	_web.picked.connect(_pick_web)
	add_child(_web)
	var x: float = 12.0
	for words in ["Whole web", "The class's", "The Pitch"]:
		var b := UI.button(self, Rect2(x, LANES_Y + 10, 120, 30), false)
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 2)
		b.text = words
		b.pressed.connect(_web_jump.bind(words))
		var w: float = ceilf(UI.text_width(b, words)) + 40.0
		b.size.x = w
		_web_buttons.append(b)
		x += w + 6.0
	_find = LineEdit.new()
	_find.position = Vector2(x + 6.0, LANES_Y + 10)
	_find.size = Vector2(200, 30)
	_find.placeholder_text = "Find a perk"
	_find.add_theme_font_override("font", UI.font("Regular", false))
	_find.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 2)
	_find.add_theme_stylebox_override("normal", UI.box(Pal.CARD, 6, 1, Pal.CARD_LINE))
	_find.add_theme_stylebox_override("focus", UI.box(Pal.CARD, 6, 1, Pal.ACCENT))
	_find.add_theme_color_override("font_color", Pal.TEXT)
	_find.add_theme_color_override("font_placeholder_color", Pal.TEXT_3)
	_find.text_changed.connect(_find_perk)
	add_child(_find)


## The first perk whose name fits the words, centred and picked; nothing found, nothing moves.
func _find_perk(words: String) -> void:
	if sim == null:
		return
	var id: String = _web.find_named(words)
	if id == "":
		return
	_web.centre_on(id)
	_web.pick(id)


func _web_jump(words: String) -> void:
	match words:
		"Whole web":
			_web.focus_all()
		"The Pitch":
			_web.focus_tree(Data.COMMON_TREE)
		_:
			if sim != null and sim.cls != "":
				_web.focus_class(sim.cls)
			else:
				_web.focus_all()


func _pick_web(id: String) -> void:
	_armed = ""
	selected = id
	show_state(sim)


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
		b.pressed.connect(_on_cell.bind(k))
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
	_past_bar = UI.panel(_panel, Rect2(0, 0, 10, 6), UI.box(Pal.CARD_LINE, 3))
	_past_fill = UI.panel(_past_bar, Rect2(0, 0, 0, 6), UI.box(Pal.ACCENT, 3))
	_past_bar.visible = false
	_train = UI.button(_panel, Rect2(0, by, 200, Pal.BUTTON_H), true)
	_train.pressed.connect(_on_train)
	_respec = UI.button(_panel, Rect2(0, by, 240, Pal.BUTTON_H), false)
	_respec.pressed.connect(_on_respec)


const EFFECT_WORDS := {
	"damage_pct": "+%d%% damage", "hp": "+%d max HP", "loot_pct": "+%d%% loot quantity", "search_pct": "Search %d%% faster",
	"first_pct": "+%d%% damage to each gang's first", "patrol_pct": "Gangs %d%% later", "armour_pct": "Armour +%d%%", "heal_pct": "Meds +%d%%",
	"med_speed_pct": "Meds %d%% quicker", "med_cap": "+%d in the rig", "rest_pct": "Rest +%d%%", "treat_pct": "Clinic prices −%d%%",
	"att_share": "+%d%% from gun parts", "sell_pct": "Fence pays +%d%%", "cash_pct": "Tins +%d%%", "rarity": "+%d%% loot quality",
	"pace_pct": "+%d%% pace", "damage_low_pct": "+%d%% dmg under ½ HP",
	"conv_fire_pct": "%d%% as fire", "conv_frost_pct": "%d%% as frost", "conv_poison_pct": "%d%% as poison", "conv_shock_pct": "%d%% as shock", "conv_bleed_pct": "%d%% as bleed",
	"fire_pct": "+%d%% fire", "frost_pct": "+%d%% frost", "poison_pct": "+%d%% poison", "shock_pct": "+%d%% shock", "bleed_pct": "+%d%% bleed", "physical_pct": "+%d%% physical",
	"dot_pct": "+%d%% damage over time", "phys_pen": "Ignores %d%% resist",
	# the web's fillers and hung notables (22 Oct)
	"regen": "+%.1f HP a second", "paragon": "+%d%% a point", "fire_res": "+%d%% fire resist", "frost_res": "+%d%% frost resist", "poison_res": "+%d%% poison resist",
	"shock_res": "+%d%% shock resist", "bleed_res": "+%d%% bleed resist", "buy_pct": "Fence sells −%d%%", "cells": "+%d cells",
	"fire_last_pct": "Burns last %d%% longer", "bleed_last_pct": "Bleeds last %d%% longer", "frost_last_pct": "Chills last %d%% longer", "poison_last_pct": "Poison lasts %d%% longer",
}
const TYPE_WORDS := {"rifle": "rifles", "shotgun": "shotguns", "smg": "SMGs", "improvised": "improvised", "pistol": "pistols", "melee": "melee"}
## The panel's sentence for a plain node: what happens, in words; the figure is the chip's (Caravan-E, 7 Oct).
const PANEL_WORDS := {
	"damage_pct": "Every shot hits harder, whatever is in hand.", "hp": "More HP to lose before the runner goes down.", "loot_pct": "Every search turns up a little more.",
	"search_pct": "Searching goes quicker.", "first_pct": "The opening shot on every gang hits harder.", "patrol_pct": "The next gang takes longer to arrive.",
	"armour_pct": "Less of every hit gets through.", "heal_pct": "Every med heals more.", "med_speed_pct": "Every med works quicker.", "med_cap": "One more pouch on the rig.",
	"rest_pct": "Resting on the Pitch heals faster.", "treat_pct": "The Clinic charges less.", "att_share": "Gun parts count for more.",
	"sell_pct": "The Fence pays more for what you sell.", "cash_pct": "Every run brings home more tins.", "rarity": "Rarer things turn up.",
	"pace_pct": "The fight and the search go quicker.", "damage_low_pct": "Under half HP, every shot hits harder.",
	"conv_fire_pct": "A share of every hit lands as fire and keeps burning.", "conv_frost_pct": "A share of every hit lands as frost and slows them.", "conv_poison_pct": "A share of every hit lands as poison and keeps working.",
	"conv_shock_pct": "A share of every hit lands as shock, and they take more damage.", "conv_bleed_pct": "A share of every hit lands as bleed and keeps bleeding.",
	"fire_pct": "Fire hits harder.", "frost_pct": "Frost hits harder.", "poison_pct": "Poison hits harder.", "shock_pct": "Shock hits harder.",
	"bleed_pct": "Bleed hits harder.", "physical_pct": "The plain share of every hit, the part not converted, hits harder.", "dot_pct": "Burns, poison and bleeds all do more.",
	"regen": "A little HP comes back every second, in a fight or out of one.", "fire_res": "Less of their fire gets through.", "frost_res": "Less of their frost gets through.",
	"poison_res": "Less of their poison gets through.", "shock_res": "Less of their shock gets through.", "bleed_res": "Less of their bleed gets through.",
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


# ------------------------------------------------------------------ the trees on show

## The Also row's chips: the pages over the web - the drawer, the shelf and the wireless (the trees are all on the
## web now, 22 Oct; the paragon board is the web's outer ring, slice 4).
func also_names() -> Array:
	var out: Array = []
	out.append("The drawer")
	out.append("The mantelpiece")
	out.append("The wireless")
	return out


static func _is_pages(nm: String) -> bool:
	return nm == "The drawer" or nm == "The mantelpiece" or nm == "The wireless"


## The pages over the lanes, by the Also chip's name.
func _branch_for(nm: String) -> Dictionary:
	if nm == "The drawer":
		return _drawer_branch()
	if nm == "The wireless":
		return _radio_branch()
	return _shelf_branch()


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	if _armed != "" and (sim.cls != _armed_cls or sim.on_mission()):
		_armed = ""
	var sig := "%s|%s|%d|%d|%s|%s|%s|%s|%d|%d|%d|%s|%d|%s|%s|%d|%s|%d|%s" % [selected, str(sim.tree), sim.training_points, int(sim.cash), sim.cls, str(sim.on_mission()), alt, "", sim.book.size() * 1000 + sim.heard.size(), drawer_page, sim.shelf.size(),
		sim.gun_type(), sim.level(), "", _armed, int(sim.elapsed / 60.0), sim.has_rule("qm_manual"), sim.past.size(), str(sim.shelf_tier) + str(sim.keepsakes.size()) + str(sim.ring) + str(int(sim.paragon_xp))]   # the gun in hand idles typed nodes; the level opens the second past; a trade opens a top; prices inflate by the minute
	if sig == _shown:
		return
	_shown = sig
	if alt != "" and not (alt in also_names()):
		alt = ""                           # the chip went (a class change took that tree into a lane)
	_show_head()
	var pages: bool = _is_pages(alt)
	_web.visible = not pages
	for b in _web_buttons:
		b.visible = not pages
	_web.selected = selected
	if not pages:
		_web.show_state(sim)
	_show_pages(pages)
	_show_also()
	_show_sum([])
	_show_panel()


func _show_head() -> void:
	var td: Dictionary = sim.trait_data()
	var faced := People.show(_face, sim.cls)
	_face.visible = faced
	_face_q.visible = not faced
	UI.fit(_kicker, [("Training · %s" % td["name"]) if not td.is_empty() else "Training", "Training"])     # the class is the card's and the panel's (18 Oct, said once)
	var free: int = sim.points_free()
	_points.text = "%d of %d" % [free, sim.training_points]
	_points.add_theme_color_override("font_color", Pal.ACCENT if free > 0 else Pal.TEXT_2)
	_unit.position.x = _points.position.x + ceilf(UI.text_width(_points, _points.text)) + 10
	_unit.size.x = _kicker.position.x + _kicker.size.x - _unit.position.x
	UI.fit(_unit, ["point%s free" % ("" if sim.training_points == 1 else "s"), "free", ""])
	_class_line.text = ""                  # the class's sentence is its card's tooltip now (14 Oct); the notice is the line
	_class_line.visible = false
	for k in range(Data.CLASSES.size()):
		_show_card(k)
	_notice.add_theme_color_override("font_color", Pal.TEXT)
	if _armed != "":
		_notice.add_theme_color_override("font_color", Pal.ACCENT)
		var lv: int = sim.crew_level(_armed)
		if lv > 0:
			UI.fit(_notice, ["Swap to the %s: level %d, their own tree and kit – press again" % [_armed, lv], "Swap to the %s, level %d – press again" % [_armed, lv], "%s – press again" % _armed])
		else:
			UI.fit(_notice, ["Swap to the %s: a new runner at level 1 – press again" % _armed, "Swap to the %s – press again" % _armed, "%s – press again" % _armed])
	elif sim.cls == "":
		UI.fit(_notice, ["Pick a past: what the runner was, and how they fight now · free for a new runner", "Pick a past · free for a new runner", "Pick a past"])
	elif not td.is_empty():
		UI.fit(_notice, ["%s: %s · one a runner" % [td["name"], td["words"]], "%s: %s" % [td["name"], td["words"]], td["name"]])
	else:
		_notice.text = ""
	_lay_lines()


## A past's card: lit and ticked when it's the runner's, "press again" when armed, dimmed beside a picked one,
## greyed when it can't be picked (on a run, or the second past's class).
func _show_card(k: int) -> void:
	var cb: Button = _class_buttons[k]
	var c: Dictionary = _class_cards[k]
	var cd: Dictionary = Data.CLASSES[k]
	var nm: String = cd["name"]
	var mine: bool = sim.cls == nm
	var armed: bool = _armed == nm
	var lit: bool = mine or armed or sim.cls == ""
	cb.disabled = sim.on_mission()
	var edge: Color = Pal.ACCENT if (mine or armed) else Pal.CARD_LINE
	var w: int = 2 if (mine or armed) else 1
	for pair in [["normal", 0.0], ["hover", 0.08], ["pressed", 0.12], ["hover_pressed", 0.12], ["disabled", 0.0]]:
		var sb := UI.box(Color(PILL_GLASS, 0.72).lightened(float(pair[1])), 8, w, edge)
		cb.add_theme_stylebox_override(pair[0], sb)
	cb.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 8, 2, Pal.TEXT))
	cb.modulate.a = 0.5 if (cb.disabled and not mine) else 1.0
	c["face"].modulate = Color(1, 1, 1, 1.0 if lit else 0.75)
	c["name"].add_theme_color_override("font_color", Pal.TEXT if lit else Pal.TEXT_2)
	c["tag"].text = "✓ your past" if mine else ("press again" if armed else _crew_tag(nm))
	var short: Array = cd.get("short", [])
	for r in range(CLASS_SHORT):
		var l: Label = c["lines"][r]
		l.text = str(short[r][0]) if r < short.size() else ""
		var tone: Color = Pal.GOOD if (r < short.size() and short[r][1]) else Pal.BAD
		l.add_theme_color_override("font_color", tone if lit else Pal.TEXT_3)


## A class's card when it isn't out (21 Oct, the crew): its level and element, wounded, or new.
func _crew_tag(nm: String) -> String:
	if sim.cls == "":
		return ""
	var lv: int = sim.crew_level(nm)
	if lv <= 0:
		return "new"
	var r: Dictionary = sim.crew_runner(nm)
	var el: String = sim.crew_element(nm)
	var bit: String = "wounded" if not Dictionary(r.get("wounds", {})).is_empty() else el
	return ("L%d · %s" % [lv, bit]) if bit != "" else "L%d" % lv


## The class's line and the notice, bottom up: a lone line sits just over the classes, where the notice would; each
## line that has words gets its pill, fitted to them.
func _lay_lines() -> void:
	_class_line.position.y = float(LINE_TOP_Y) if _notice.text != "" else NOTICE_Y + (_notice.size.y - _class_line.size.y) / 2.0
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
		var nm: String = names[k]
		a["name"] = nm
		var t := Data.tree_named(nm)
		var words := nm
		var short := nm
		if t.has("element"):
			words = "%s · %s" % [nm, t["element"]]
		elif t.get("class", "") != "":
			words = "%s · %s" % [nm, t["class"].to_lower()]
		elif _is_pages(nm):
			# the drawer and the shelf carry their counts, and the page when one's open over the lanes
			var br0: Dictionary = _branch_for(nm)
			var found: int = int(br0["found"])
			var total: int = int(br0["total"])
			words = "%s · %d of %d" % [nm, found, total]
			if alt == nm:
				var br: Dictionary = br0
				if int(br["pages"]) > 1:
					words += " · page %d of %d" % [int(br["page"]) + 1, int(br["pages"])]
			short = "%s %d/%d" % [nm.get_slice(" ", 1).capitalize(), found, total]
		var w: float = ceilf(UI.text_width(b, words)) + 36.0
		if x + w > right:
			words = short
			w = ceilf(UI.text_width(b, words)) + 36.0
		b.visible = x + w <= right
		b.text = words
		b.position.x = x
		b.size.x = w
		UI.style_button(b, alt == nm)
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
		@warning_ignore("integer_division")
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
	var pages: Array = sim.keepsakes + sim.book_pages()     # the heads' keepsakes first (15 Oct), then the papers
	var branch := _pages_branch("The drawer", pages, pages.size(), Words.BOOK["empty"], func(nm): return _keepsake_words(nm) if nm in sim.keepsakes else (Words.item_words(nm, false) if nm in sim.book else _paper_gap(nm)), 2)
	for nd in branch["nodes"]:
		var nm: String = str(nd["name"]).substr(str(nd["name"]).find(" ") + 1)
		nd["gap"] = not (nm in sim.book or nm in sim.keepsakes)
	branch["found"] = sim.book.size() + sim.keepsakes.size()
	branch["total"] = sim.book_pages().size() + Words.GATE_ITEMS.size()
	return branch


## A keepsake's words: what it is, and the room it opened.
func _keepsake_words(nm: String) -> String:
	var room: String = Items.opens({"slot": Data.PAPER, "base": nm})
	return "%s. %s." % [str(Words.GATE_ITEMS.get(nm, "")).get_slice(". ", 0).trim_suffix("."), Words.KEEPSAKE % ("the " + room.capitalize())]     # its first sentence: a drawer's two lines


## Where an unfound paper turns up: its one site, or the depth it's found from.
func _paper_gap(nm: String) -> String:
	var site: String = Items.exclusive_to(nm)
	if site != "":
		return Words.BOOK["gap_site"] % Words.mid(site)
	var d: int = int(Items.base_named(Data.PAPER, nm).get("depth", 0))
	return Words.BOOK["gap_deep"] % sim.tier_level(d) if d > 0 else Words.BOOK["gap"]     # a paper's gate is a Barracks-equivalent depth: its level (18 Oct: levels on screen)


## The radio (12 Oct, the lore pass): every line heard, in the order heard, under its voice.
func _radio_branch() -> Dictionary:
	return _pages_branch("The wireless", sim.heard, Words.RADIO.size(), Words.HEARD["empty"],
		func(key): return str(sim.radio_line(key).get("text", "")), 3,
		func(key): return str(Words.RADIO_VOICES.get(sim.radio_line(key).get("voice", ""), "")))


## The shelf: the chase first (endgame part 3) - the nine sites' own, the heads' charms, the Lorry's Load, a
## gap each until found, with where it is under the gap - then the rest found, in the order found.
func _shelf_branch() -> Dictionary:
	var chase: Array = sim.shelf_chase()
	var names: Array = []
	var gaps := {}
	for c in chase:
		var unknown: bool = not c["found"] and not c.get("known", true)     # a gap from a place not yet known: scrambled (20 Oct, Matt)
		var nm_c: String = Fmt.scramble(str(c["name"])) if unknown else str(c["name"])
		names.append(nm_c)
		if not c["found"]:
			gaps[nm_c] = Fmt.scramble(str(c["where"])) if unknown else c["where"]
	for nm in sim.shelf:
		if not (nm in names):
			names.append(nm)
	var branch := _pages_branch("The mantelpiece", names, Data.UNIQUES.filter(func(u): return not u.get("mythic", false)).size(), Words.SHELF["empty"],
		func(nm): return gaps[nm] if gaps.has(nm) else _shelf_words(nm), 3)
	for nd in branch["nodes"]:
		nd["gap"] = gaps.has(str(nd["name"]).substr(str(nd["name"]).find(" ") + 1))
	branch["found"] = sim.shelf.size()
	return branch


## A found unique's words on the shelf: the best tier of it found first (12 Oct, uniques by tier), then who it was.
func _shelf_words(nm: String) -> String:
	var t: int = int(sim.shelf_tier.get(nm, 0))
	return ("Best T%d. " % t if t > 0 else "") + str(Words.UNIQUES.get(nm, ""))


## A page of a list: a card a name with `lines` of words under it, as many as the lanes' area takes.
func _pages_branch(title: String, list: Array, total: int, empty: String, words: Callable, lines: int, label := Callable()) -> Dictionary:
	var row_h: int = NAME_H + lines * WORD_H + 4
	@warning_ignore("integer_division")
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
const SUM_DROP := ["Search", "Quantity", "First of each gang", "Quality", "Gangs", "Max HP", "Damage", "Lasting"]     # Lasting last (22 Oct: the web's figures run to three digits)
func _show_sum(lanes: Array) -> void:
	_sum_chips.show_chips(sum_items(lanes), SUM_ROWS)


## The strip's items at their long forms, nothing cut to fit (for the tests).
func sum_items_raw() -> Array:
	return sum_items([], false)


func sum_items(_lanes_v: Array, fit := true) -> Array:
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
	var sc: float = 100.0 / converted if converted > 100.0 else 1.0     # past the whole hit the shares are cut back together, as the fight does
	for el in Data.ELEMENTS:
		var conv: float = sim.tree_sum("conv_%s_pct" % el) * sc
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
		var share: float = 100.0 if bust else maxf(0.0, 100.0 - converted * sc)
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
	for pair in [["Petrol/3", "burns"], ["The Rat Man/3", "poison"], ["Blades/3", "bleeds"]]:
		if sim.tree.has(pair[0]):
			extras.append("%s lasts twice as long" % pair[1])          # Lit, Dosed, Opened up: the trees' own, not the kit's (dot_seconds reads both)
	if sim.has_node("poison_stacks"):
		extras.append("poison stacks to 15")
	if sim.has_node("bleed_forever"):
		extras.append("bleeds don't fade")
	if dot_inc > 0.0 or not extras.is_empty():
		var head: String = ("+%.0f%%" % dot_inc) if dot_inc > 0.0 else ""
		var long: Array = ([head] if head != "" else []) + extras
		items.append({"tag": "Lasting", "forms": [" · ".join(long), " · ".join(long.slice(0, 2)), long[0]], "colour": Pal.TEXT})     # "Lasting": damage over time (the glossary), short enough for the crowded strip (18 Oct)
	plain.call("Max HP", sums.get("hp", 0.0), "+%.0f")
	plain.call("First of each gang", sums.get("first_pct", 0.0), "+%.0f%%")
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
	for row2 in tries:
		var level: int = row2[0]
		var gone: Array = SUM_DROP.slice(0, row2[1])
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
	if selected == "" and _armed != "":
		var lv: int = sim.crew_level(_armed)
		var el: String = sim.crew_element(_armed)
		var r: Dictionary = sim.crew_runner(_armed)
		_title.text = ("%s · level %d" % [_armed, lv]) if lv > 0 else "%s · new" % _armed
		if el != "":
			_title.text += " · " + el
		after_title.call()
		var kit: Array = []
		for sl in ["Primary", "Armour", "Helmet"]:
			var it = r.get("equipped", {}).get(sl, null)
			if it != null:
				kit.append(Items.full_name(it))
		var trt: String = str(r.get("trait", ""))
		var state: String = "wounded: send them out to see the Clinic" if not Dictionary(r.get("wounds", {})).is_empty() else ""
		if lv <= 0:
			UI.fit(_words, ["A new runner: level 1, the arrival's kit, their own points from here", "A new runner at level 1", ""])
		else:
			UI.fit(_words, ["%s%s%s" % [", ".join(kit), (" · " + trt) if trt != "" else "", (" · " + state) if state != "" else ""], ", ".join(kit), ""])
		_train.visible = true
		_train.text = "Swap to the %s" % _armed
		_train.disabled = sim.on_mission()
		_train.size.x = ceilf(UI.text_width(_train, _train.text)) + 48
	elif selected == "":
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
		if nd.has("ring"):
			# the ring (slice 4): the paragon's node, its points on it of its stack; "trained" is a full one
			_title.text = "%s · the ring · %d of %d" % [nd["name"], int(sim.ring.get(selected, 0)), int(nd["stack"])]
			is_taken = int(sim.ring.get(selected, 0)) >= int(nd["stack"])
		elif is_taken:
			_title.text += " · trained" if sim.node_active(selected) else " · trained, idle"
		var items := [{"forms": [_chip_words(nd)], "colour": _effect_tone(nd)}]
		if nd.has("type"):
			items.append({"forms": [type_words(nd)], "colour": Pal.TEXT_2})
		var gain: Array = sim.node_damage_gain(selected)     # what it adds to the one figure, tried on (16 Oct, item 14)
		if float(gain[0]) >= 0.5:
			items.append({"forms": ["%s +%.0f a second (+%.0f%%)" % ["Adds" if is_taken else "For you:", float(gain[0]), float(gain[1]) * 100.0], "+%.0f/s (+%.0f%%)" % [float(gain[0]), float(gain[1]) * 100.0], "+%.0f/s" % float(gain[0])], "colour": Pal.GOOD})
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
			var jw: String = str(j["words"])
			jw = jw.substr(0, 1).to_lower() + jw.substr(1)     # mid-line: only its first letter drops (18 Oct: "smgs")
			tail = ("joined: %s" % jw) if sim.has_joint(j_key) else ("with %s in %s: %s" % [other, other_tree, jw])
		if is_taken and not sim.node_active(selected) and not sim._active(nd):
			tail = "idle without %s in hand" % type_words(nd)
		elif is_taken and not sim.node_active(selected):
			tail = "idle until a joint in %s is joined again" % str(selected).get_slice("/", 0)
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
			_train.text = ("Train (%d paragon point%s)" if nd.has("ring") else "Train (%d point%s)") % [cost, "" if cost == 1 else "s"]
			_train.disabled = not sim.can_train(selected)
			_train.size.x = ceilf(UI.text_width(_train, _train.text)) + 48
	if selected != "" and sim.is_ring(selected):
		_respec.text = "Reset the ring for %s" % Fmt.money(sim.paragon_reset_cost())
		_respec.disabled = sim.paragon_spent() == 0 or sim.cash < sim.paragon_reset_cost()
	else:
		_respec.text = "Reset trees for %s" % Fmt.money(sim.respec_cost())
		_respec.disabled = sim.tree.is_empty() or sim.cash < sim.respec_cost()
	_respec.size.x = ceilf(UI.text_width(_respec, _respec.text)) + 48
	var x: float = Pal.GRID_W - PAD
	x -= _respec.size.x
	_respec.position.x = x
	if _train.visible:
		x -= 12 + _train.size.x
		_train.position.x = x
	if selected != "" and not _node_forms.is_empty():
		fit_two(_node_forms, x - 16 - PAD)            # under the title, clear of the buttons, over two lines
	_node_forms = []
	# the runners before, in what's left beside the buttons: on the class's panel, not under a node
	_past.size.x = x - 12 - _past.position.x
	_past.visible = selected == ""
	_past_bar.visible = false
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
		var held: String = (", %s at level %d" % [Words.mid(str(r["site"])), int(r.get("held_lv", 0))]) if int(r.get("held_lv", 0)) > 0 else ""
		long.append("a %s, %d run%s%s, %s" % [str(r["class"]), int(r["runs"]), "" if int(r["runs"]) == 1 else "s", held, r["end"]])
		short.append("%s %d" % [str(r["class"]), int(r["runs"])])
	UI.fit(_past, ["Before: " + "; ".join(long), "Before: " + "; ".join(long.slice(0, 2)), "Before: " + ", ".join(short), long[0], "%d runner%s before this one" % [sim.past.size(), "" if sim.past.size() == 1 else "s"]])


# ------------------------------------------------------------------ acting

func _pick(id: String) -> void:
	_armed = ""
	selected = id
	show_state(sim)


## The web, for the tests.
func web():
	return _web


## An Also chip's button by name, or null (for the tests).
func also_button(nm: String) -> Button:
	for a in _also:
		if a["name"] == nm and a["button"].visible:
			return a["button"]
	return null


func _pick_also_at(k: int) -> void:
	pick_also(str(_also[k]["name"]))


## An Also chip: its tree in the Yard's lane (the drawer and the shelf over the lanes); pressed again, the Yard back.
func pick_also(nm: String) -> void:
	_armed = ""
	alt = "" if alt == nm else nm
	drawer_page = 0
	_shown = ""
	show_state(sim)


## A card over the lanes: on the pages the next page.
func _on_cell(_k: int) -> void:
	_turn_page()


func _turn_page() -> void:
	drawer_page += 1
	_shown = ""
	show_state(sim)


## A class button: a runner with no class takes the first pick as theirs; after that the first press arms a swap
## (the panel shows that class's runner), the second sends them out. Free.
func _pick_class(nm: String) -> void:
	if sim.on_mission() or nm == sim.cls:
		_armed = ""
		show_state(sim)
		return
	if sim.cls != "" and _armed != nm:
		_armed = nm                            # a swap (21 Oct, the crew): the first press shows them, the second sends them out
		_armed_cls = sim.cls
		selected = ""
		show_state(sim)
		return
	_armed = ""
	if sim.set_class(nm):
		selected = ""
		alt = ""
		acted.emit()
	show_state(sim)


func _on_train() -> void:
	if _armed != "" and selected == "":
		_pick_class(_armed)                    # the panel's Swap button: the second press (21 Oct, the crew)
		return
	_armed = ""
	if selected != "" and sim.train_node(selected):
		acted.emit()
	show_state(sim)


func _on_respec() -> void:
	_armed = ""
	if (sim.paragon_reset() if selected != "" and sim.is_ring(selected) else sim.respec()):
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
	for b in [_train]:
		if b.visible:
			out.append(b)
	for c in _class_cards:
		out.append_array([c["name"], c["tag"]] + c["lines"])
	for b in _web_buttons:
		if b.visible:
			out.append(b)
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
