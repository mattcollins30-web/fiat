extends Control
## The Caravan's screen: what the runner was, and training. Since 3 Nov (docs/design/skill_web.md "The screen") the
## skill web: the band - the face, the points free, what the web adds up to, the six runners; the web on the left with
## its tabs, the find box and the key, the Also row under it (the drawer, the mantelpiece, the wireless); on the right
## the node card (its picture, name, where it sits, its words and "Take it"), the runner's pairs, the big nodes' gates,
## Copy, Paste and the reset. Fixed geometry inside the card grid's 1536 x 916.

signal acted

const Arm := preload("res://scripts/ui/arm.gd")
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
const WebKey := preload("res://scripts/ui/web_key.gd")

const PAD := 20
# the header: the face, the class and trait, the points free, the class's line; the classes top right
const HEAD_H := Pal.BAND_H                                     # the rooms' one band (10 Oct, Bands-U A): 96 → 180
const FACE := Pal.BAND_FACE
# the pasts as cards (14 Oct, Matt; docs/design/mockups/class_cards_mockup.png): a face, the name, the short lines in
# their tones (a cost red); the picked one lit, the rest dimmed; the whole sentence a tooltip
const CLASS_W := 200                # two rows of three (24 Oct, Matt: option B on the canvas's Band board): six full cards
const CLASS_H := 58                 # left the words column 310 px and the sum strip lost four chips; the perks went to the tooltip
const CLASS_GAP := 8
const CLASS_ROW_GAP := 6
const CLASS_COLS := 3
const CLASS_FACE := 40
const CLASSES_H := 2 * CLASS_H + CLASS_ROW_GAP     # the two rows, the old one row's height
# the line over the cards (the trait, the change's price, or the prompt) on a glass pill so the art doesn't eat it
# (12 Oct); the class's own sentence went to the cards' tooltips (14 Oct)
const NOTICE_Y := HEAD_H - 14 - CLASSES_H - 34
const LINE_TOP_Y := NOTICE_Y
const PILL_H := 28                 # a hairline between two pills, 4 px over the classes
const PILL_PAD := 12
const PILL_GLASS := Color(0.06, 0.07, 0.08, 0.62)
## The skill web's screen (3 Nov, docs/design/skill_web.md "The screen"; the canvas's sw_final6): the web on the left
## under the band, the Also row under it; the node card, the pairs, the big nodes and the build's buttons on the right.
const LANES_Y := HEAD_H + 6                                    # the web's top
const SIDE_W := 488                                            # the right column: the node card and what's under it
const COL_GAP := 8
const WEB_W := Pal.GRID_W - SIDE_W - COL_GAP                   # 1040
const SIDE_X := WEB_W + COL_GAP
const ALSO_H := 40
const LANES_H := Pal.ROOM_H - LANES_Y - ALSO_H - 6             # 684: the web's height
const ALSO_Y := LANES_Y + LANES_H + 6
const ALSO_HEAD_W := 110
const ALSO_MAX := 10
const BTN_H := 46                                              # the right column's buttons: Copy, Paste, Reset
const RESET_Y := Pal.ROOM_H - BTN_H
const CODE_Y := RESET_Y - 8 - BTN_H
const CP := 16                                                 # a card's padding
const CARD_H := 318                                            # the node card
const PAIRS_H := 168
const BIG_H := 112
const PAIRS_Y := LANES_Y + CARD_H + 8
const BIG_Y := PAIRS_Y + PAIRS_H + 8
const ICON := 76                                               # the node's picture in the card
const HALF_ICON := 38
const CARD_TEXT := 17                                          # the card's sentence, three lines
const LINE_H := 25
const PAIR_TEXT := 15
const PAIR_LINE := 20
const KEY_TABS := 6                                            # (the web's tabs' gap)
# the sum ("Add up to") in the band, under the class's line (Bands-U A: the strip's 54 px pay for the band)
const SUM_Y := 76                                              # under the points; the class's line goes right, over the classes
const SUM_H := 3 * Chips.CHIP_H + 2 * Chips.ROW_GAP
const SUM_HEAD_W := 96
const SUM_ROWS := 3
const PANEL_Y := LANES_Y                                       # the node card (the old strip's names: the tests read them)
const PANEL_H := CARD_H
# the drawer and the shelf take the web's and the card's place: three columns of cards
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
var _armed_ms := 0                 # when, for the arm's window (arm.gd's WINDOW_S)
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
var _web                            # the skill web (3 Nov): the canvas, left under the band
var _web_buttons: Array = []       # over the web's corner: the whole web, the runner's corner
var _key: WebKey                   # the key in the web's foot (3 Nov): the three states, the big nodes' gates, the paragon points
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
var _words2: Label                  # a node's sentence, its second line
var _words3: Label                  # and its third (the card's 456 px)
var _no_use: Label                   # under them: another class's start or skill, "<Class> only: no use to a <class>"
var _where: Label                   # where a node sits and what it is: "The cold · the tip · a notable"
var _icon: TextureRect              # the node's picture in the card, in its ring
var _icon_ring: Panel
var _pairs_panel: Panel             # the runner's two pairs
var _pairs_head: Label
var _pair_rows: Array = []          # {dot, lines[3]}
var _big_panel: Panel               # the big nodes' gates
var _big_head: Label
var _big_lines: Array = []
var _big_bar: Panel
var _big_fill: Panel
var _big_tick: Panel
var _node_forms: Array = []          # a node's sentence in its forms, fitted once the buttons have their places
var _past: Label
var _train: Button
var _respec: Button
var code_copy: Button               # the build code (24 Oct, the endgame chase): at the right column's foot
var code_paste: Button
var code_panel: Panel               # a pasted code's plan over the detail strip, till it's taken or cancelled
var _code_title: Label
var _code_plan: Label
var _code_plan2: Label
var _code_plan3: Label
var _code_go: Button
var _code_cancel: Button
var pending_build := {}             # the code read, waiting on Retrain
var _code_str := ""                # the code shown, planned again whenever the screen changes under it
var paste_text := ""                # the tests' clipboard: when set, Paste reads it instead of the system's
static var clip_off := false       # the tests (the fix round, 30 Oct): a copy lands in `copied`, never the system's clipboard
var copied := ""                   # what the last copy would have put on the clipboard, while clip_off


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
		@warning_ignore("integer_division")
		cb.position = Vector2(cx0 + (k % CLASS_COLS) * (CLASS_W + CLASS_GAP), HEAD_H - 14 - CLASSES_H + (k / CLASS_COLS) * (CLASS_H + CLASS_ROW_GAP))
		cb.size = Vector2(CLASS_W, CLASS_H)
		cb.focus_mode = Control.FOCUS_ALL
		cb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		cb.tooltip_text = "%s: %s" % [cd["name"], cd["words"]]
		cb.pressed.connect(_pick_class.bind(cd["name"]))
		head.add_child(cb)
		_class_buttons.append(cb)
		var face := People.rect(cb, Vector2(8, (CLASS_H - CLASS_FACE) / 2.0), CLASS_FACE / 128.0)
		People.show(face, str(cd["name"]))
		var tx: float = CLASS_FACE + 12
		var nm := UI.label(cb, Rect2(tx, 6, CLASS_W - tx - 6, 24), str(cd["name"]), "SemiBold", 19, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var tag := UI.label(cb, Rect2(tx, 31, CLASS_W - tx - 6, 18), "", "Medium", 14, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var lock := TextureRect.new()      # a locked class: a lock before the head that opens it
		lock.texture = NodeGlyphs.texture("lock")
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.position = Vector2(tx, 33)
		lock.size = Vector2(14, 14)
		lock.modulate = Pal.TEXT_3
		cb.add_child(lock)
		for n in [nm, tag, lock]:
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_class_cards.append({"face": face, "name": nm, "tag": tag, "lock": lock, "tag_x": tx})
	_notice = UI.label(head, Rect2(cx0, NOTICE_Y, Pal.GRID_W - PAD - cx0, 30), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)


static func _classes_x() -> float:
	return Pal.GRID_W - PAD - CLASS_COLS * CLASS_W - CLASS_GAP * (CLASS_COLS - 1)


## The band's words column: past the face, up to the classes.
static func _words_x() -> float:
	return 16 + FACE + 14


static func _words_w() -> float:
	return _classes_x() - 24 - _words_x()


## The web's left: the canvas, its two tabs and the find box over its corner, the key in its foot (3 Nov).
func _build_web() -> void:
	_web = WebView.new(Vector2(WEB_W, LANES_H))
	_web.position = Vector2(0, LANES_Y)
	_web.picked.connect(_pick_web)
	add_child(_web)
	var x: float = 12.0
	for k in range(2):
		var b := UI.button(self, Rect2(x, LANES_Y + 10, 120, 32), false)
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 1)
		b.pressed.connect(_web_jump.bind(k))
		_web_buttons.append(b)
	_key = WebKey.new()
	_key.position = Vector2(12.0, LANES_Y + LANES_H - _key.size.y - 12.0)
	add_child(_key)
	_find = LineEdit.new()
	_find.size = Vector2(200, 32)
	_find.placeholder_text = "Find a perk"
	_find.add_theme_font_override("font", UI.font("Regular", false))
	_find.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 1)
	_find.add_theme_stylebox_override("normal", UI.box(Pal.CARD, 6, 1, Pal.CARD_LINE))
	_find.add_theme_stylebox_override("focus", UI.box(Pal.CARD, 6, 1, Pal.ACCENT))
	_find.add_theme_color_override("font_color", Pal.TEXT)
	_find.add_theme_color_override("font_placeholder_color", Pal.TEXT_3)
	_find.text_changed.connect(_find_perk)
	add_child(_find)
	_lay_tabs()


## The tabs' words and places: "Whole web", "The <Class>'s corner", then the find box after them.
func _lay_tabs() -> void:
	var cls: String = str(sim.cls) if sim != null else ""
	var x: float = 12.0
	for k in range(_web_buttons.size()):
		var b: Button = _web_buttons[k]
		var words: String = Words.WEB_SCREEN["whole"] if k == 0 else (Words.WEB_SCREEN["corner"] % cls if cls != "" else Words.WEB_SCREEN["corner_short"])
		b.text = words
		b.size.x = ceilf(UI.text_width(b, words)) + 40.0
		b.position.x = x
		x += b.size.x + KEY_TABS
	_find.position = Vector2(x + KEY_TABS, LANES_Y + 10)


## The first perk whose name fits the words, centred and picked; nothing found, nothing moves.
func _find_perk(words: String) -> void:
	if sim == null:
		return
	var id: String = _web.find_named(words)
	if id == "":
		return
	_web.centre_on(id)
	_web.pick(id)


## A tab: the whole web, or the runner's corner (its class's four flowers and its two elements).
func _web_jump(k: int) -> void:
	if k == 1 and sim != null and sim.cls != "":
		_web.focus_class(sim.cls)
	else:
		_web.focus_all()


func _pick_web(id: String) -> void:
	_armed = ""
	selected = id
	show_state(sim)


## The Also row under the web: the drawer, the mantelpiece and the wireless, each over the web and the card.
func _build_also() -> void:
	_also_panel = UI.panel(self, Rect2(0, ALSO_Y, WEB_W, ALSO_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_also_head = UI.head(_also_panel, Rect2(PAD, 0, ALSO_HEAD_W, ALSO_H), "Also")
	for k in range(ALSO_MAX):
		var b := UI.button(_also_panel, Rect2(PAD + ALSO_HEAD_W, 5, 100, ALSO_H - 10), false)
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT)
		b.pressed.connect(_pick_also_at.bind(k))
		b.visible = false
		_also.append({"button": b, "name": ""})
	@warning_ignore("integer_division")
	var half: int = (SIDE_W - 8) / 2
	code_copy = UI.button(self, Rect2(SIDE_X, CODE_Y, half, BTN_H), false)
	code_copy.text = Words.BUILD["copy"]
	code_copy.add_theme_font_size_override("font_size", Pal.CELL_TEXT + 1)
	code_copy.pressed.connect(_copy_code)
	code_paste = UI.button(self, Rect2(SIDE_X + half + 8, CODE_Y, SIDE_W - half - 8, BTN_H), false)
	code_paste.text = Words.BUILD["paste"]
	code_paste.add_theme_font_size_override("font_size", Pal.CELL_TEXT + 1)
	code_paste.pressed.connect(_paste_code)


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


## The right column (3 Nov): the node card - its picture, name, where it sits and what it is, its figures, its words,
## the button - then the runner's two pairs, the big nodes' gates and a bar, the build's three buttons at the foot.
func _build_panel() -> void:
	var iw: float = SIDE_W - 2 * CP
	_panel = UI.panel(self, Rect2(SIDE_X, LANES_Y, SIDE_W, CARD_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_icon_ring = UI.panel(_panel, Rect2(CP, CP, ICON, ICON), UI.box(Pal.BG, HALF_ICON, 2, Pal.CARD_LINE))
	_icon = TextureRect.new()
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.position = Vector2(CP + 8, CP + 8)
	_icon.size = Vector2(ICON - 16, ICON - 16)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_icon)
	var tx: float = CP + ICON + 14
	_title = UI.label(_panel, Rect2(tx, CP + 2, SIDE_W - tx - CP, 38), "", "SemiBold", Pal.TITLE - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_where = UI.label(_panel, Rect2(tx, CP + 44, SIDE_W - tx - CP, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_chips = Chips.new(int(iw))
	_chips.position = Vector2(CP, CP + ICON + 12)
	_panel.add_child(_chips)
	var wy: float = CP + ICON + 12 + Chips.CHIP_H + 10
	_words = UI.label(_panel, Rect2(CP, wy, iw, LINE_H), "", "Regular", CARD_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_words2 = UI.label(_panel, Rect2(CP, wy + LINE_H, iw, LINE_H), "", "Regular", CARD_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_words3 = UI.label(_panel, Rect2(CP, wy + 2 * LINE_H, iw, LINE_H), "", "Regular", CARD_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_past = UI.label(_panel, Rect2(CP, wy + 3 * LINE_H + 2, iw, LINE_H), "", "Regular", CARD_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_no_use = UI.label(_panel, Rect2(CP, wy + 3 * LINE_H + 2, iw, LINE_H), "", "Regular", CARD_TEXT - 1, Pal.WARN, HORIZONTAL_ALIGNMENT_LEFT, false)
	_no_use.visible = false
	_train = UI.button(_panel, Rect2(CP, CARD_H - CP - 52, iw, 52), true)
	_train.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG + 2)
	_train.pressed.connect(_on_train)
	# the pairs: two rows, a dot (lit when done) and three lines each
	_pairs_panel = UI.panel(self, Rect2(SIDE_X, PAIRS_Y, SIDE_W, PAIRS_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_pairs_head = UI.head(_pairs_panel, Rect2(CP, 6, iw, 26), Words.WEB_SCREEN["pairs"])
	for k in range(2):
		var y0: float = 36.0 + k * (3 * PAIR_LINE + 6)
		var dot := UI.panel(_pairs_panel, Rect2(CP, y0 + 4, 12, 12), UI.box(Pal.CARD_LINE, 6))
		var lines: Array = []
		for j in range(3):
			lines.append(UI.label(_pairs_panel, Rect2(CP + 22, y0 + j * PAIR_LINE, iw - 22, PAIR_LINE), "", "Regular", PAIR_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		_pair_rows.append({"dot": dot, "lines": lines})
	# the big nodes: the two gates, a bar to 40 with a tick at 15
	_big_panel = UI.panel(self, Rect2(SIDE_X, BIG_Y, SIDE_W, BIG_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_big_head = UI.head(_big_panel, Rect2(CP, 6, iw, 26), Words.WEB_SCREEN["big"])
	for j in range(2):
		_big_lines.append(UI.label(_big_panel, Rect2(CP, 34 + j * 24, iw, 24), "", "Regular", PAIR_TEXT + 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_big_bar = UI.panel(_big_panel, Rect2(CP, BIG_H - 20, iw, 8), UI.box(Pal.CARD_LINE, 4))
	_big_fill = UI.panel(_big_bar, Rect2(0, 0, 0, 8), UI.box(Pal.ACCENT, 4))
	_big_tick = UI.panel(_big_bar, Rect2(0, -3, 2, 14), UI.box(Pal.TEXT_2, 1))
	_respec = UI.button(self, Rect2(SIDE_X, RESET_Y, SIDE_W, BTN_H), false)
	_respec.add_theme_font_size_override("font_size", Pal.CELL_TEXT + 1)
	_respec.pressed.connect(_on_respec)


const EFFECT_WORDS := {
	"damage_pct": "+%d%% damage", "hp": "+%d max HP", "loot_pct": "+%d%% loot quantity", "search_pct": "Search %d%% quicker",
	"first_pct": "+%d%% damage to each gang's first", "patrol_pct": "Gangs %d%% later", "armour_pct": "Armour +%d%%", "heal_pct": "Meds +%d%%",
	"med_speed_pct": "Meds %d%% quicker", "med_cap": "+%d in the rig", "rest_pct": "Rest +%d%%", "treat_pct": "Clinic prices −%d%%",
	"att_share": "+%d%% from gun parts", "sell_pct": "Fence pays +%d%%", "cash_pct": "Pay +%d%%", "rarity": "+%d%% loot quality",
	"pace_pct": "+%d%% pace", "damage_low_pct": "+%d%% dmg under ½ HP",
	"conv_fire_pct": "%d%% as fire", "conv_frost_pct": "%d%% as frost", "conv_poison_pct": "%d%% as poison", "conv_shock_pct": "%d%% as shock", "conv_bleed_pct": "%d%% as bleed",
	"fire_pct": "+%d%% fire", "frost_pct": "+%d%% frost", "poison_pct": "+%d%% poison", "shock_pct": "+%d%% shock", "bleed_pct": "+%d%% bleed", "physical_pct": "+%d%% physical",
	"dot_pct": "+%d%% damage over time", "phys_pen": "Ignores %d%% resist",
	# the web's fillers and hung notables (22 Oct)
	"regen": "+%.1f HP a second", "paragon": "+%d%% a point", "fire_res": "+%d%% fire resist", "frost_res": "+%d%% frost resist", "poison_res": "+%d%% poison resist",
	"shock_res": "+%d%% shock resist", "bleed_res": "+%d%% bleed resist", "buy_pct": "Fence sells −%d%%", "cells": "+%d cells",
	"fire_last_pct": "Burns last %d%% longer", "bleed_last_pct": "Bleeds last %d%% longer", "frost_last_pct": "Chills last %d%% longer", "poison_last_pct": "Poison lasts %d%% longer",
	# the skills' fillers (24 Oct, milestone 8: the affixes' words, skills.md §11)
	"grenade_pct": "+%d%% grenade damage", "energy_regen_pct": "+%d%% energy gain", "cdr_pct": "%d%% shorter cooldowns", "energy_max": "+%d max energy",
	"guard_pct": "+%d%% Guard cap",     # the centre's Guard ring (3 Nov, the skill web)
}
const TYPE_WORDS := {"rifle": "rifles", "shotgun": "shotguns", "smg": "SMGs", "improvised": "improvised", "pistol": "pistols", "melee": "melee"}
## The panel's sentence for a plain node: what happens, in words; the figure is the chip's (Caravan-E, 7 Oct).
const PANEL_WORDS := {
	"damage_pct": "Every shot hits harder, whatever is in hand.", "hp": "More HP to lose before the runner goes down.", "loot_pct": "Every search turns up a little more.",
	"search_pct": "Searching goes quicker.", "first_pct": "The opening shot on every gang hits harder.", "patrol_pct": "The next gang takes longer to arrive.",
	"armour_pct": "Less of every hit gets through.", "heal_pct": "Every med heals more.", "med_speed_pct": "Every med works quicker.", "med_cap": "One more pouch on the rig.",
	"rest_pct": "Resting on the Pitch heals faster.", "treat_pct": "The Clinic charges less.", "att_share": "Gun parts count for more.",
	"sell_pct": "The Fence pays more for what you sell.", "cash_pct": "Every run brings home more money.", "rarity": "Rarer things turn up.",
	"pace_pct": "The fight and the search go quicker.", "damage_low_pct": "Under half HP, every shot hits harder.",
	"conv_fire_pct": "A share of every hit lands as fire and keeps burning.", "conv_frost_pct": "A share of every hit lands as frost and slows them.", "conv_poison_pct": "A share of every hit lands as poison and keeps working.",
	"conv_shock_pct": "A share of every hit lands as shock, and they take more damage.", "conv_bleed_pct": "A share of every hit lands as bleed and keeps bleeding.",
	"fire_pct": "Fire hits harder.", "frost_pct": "Frost hits harder.", "poison_pct": "Poison hits harder.", "shock_pct": "Shock hits harder.",
	"bleed_pct": "Bleed hits harder.", "physical_pct": "The plain share of every hit, the part not converted, hits harder.", "dot_pct": "Burns, poison and bleeds all do more.",
	"regen": "A little HP comes back every second, in a fight or out of one.", "fire_res": "Less of their fire gets through.", "frost_res": "Less of their frost gets through.",
	"poison_res": "Less of their poison gets through.", "shock_res": "Less of their shock gets through.", "bleed_res": "Less of their bleed gets through.",
	"grenade_pct": "Every grenade hits harder.", "energy_regen_pct": "Energy refills quicker.", "cdr_pct": "Skills come round again sooner.", "energy_max": "More energy to spend on skills.",
	"guard_pct": "Your Guard can hold more before it breaks.",
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
	if _armed != "" and (sim.cls != _armed_cls or sim.runner_busy() or Time.get_ticks_msec() - _armed_ms > int(Arm.WINDOW_S * 1000.0)):
		_armed = ""                            # a swap's arm runs out like every ask-twice (Matt, 26 Oct)
	var sig := "%s|%s|%d|%d|%s|%s|%s|%d|%d|%d|%s|%d|%s|%s|%d|%d|%d|%s" % [selected, str(sim.tree), sim.web_points(), int(sim.cash), sim.cls, str(sim.runner_busy()), alt, sim.book.size() * 1000 + sim.heard.size(), drawer_page, sim.shelf.size(),
		sim.gun_type(), sim.level(), _respec_arm.sig(), _armed, int(sim.elapsed / 60.0), sim.past_count(), sim.web_spent(), str(sim.shelf_tier) + str(sim.keepsakes.size()) + str(sim.ring) + str(int(sim.paragon_xp))]   # the gun in hand idles typed nodes; prices inflate by the minute
	if sig == _shown:
		return
	_shown = sig
	if code_panel != null and code_panel.visible and not pending_build.is_empty():
		read_code(_code_str)                 # the tree, the tins or the class moved: the plan is read again (the review)
	if alt != "" and not (alt in also_names()):
		alt = ""                           # the chip went (a class change took that tree into a lane)
	_show_head()
	_lay_tabs()
	var pages: bool = _is_pages(alt)
	_web.visible = not pages
	for b in _web_buttons:
		b.visible = not pages
	_find.visible = not pages
	for n in [_panel, _pairs_panel, _big_panel, code_copy, code_paste, _respec]:
		n.visible = not pages                  # the pages take the web's and the card's place
	_web.selected = selected
	_key.visible = not pages
	if not pages:
		_web.show_state(sim)
		_key.show_state(sim)
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
	# one counter (3 Nov, the skill web): the runner's points free, then spent of all, and where they come from
	var WS: Dictionary = Words.WEB_SCREEN
	var free: int = sim.web_free()
	_points.text = (WS["free_one"] if free == 1 else WS["free"]) % free
	_points.add_theme_color_override("font_color", Pal.ACCENT if free > 0 else Pal.TEXT_2)
	_unit.position.x = _points.position.x + ceilf(UI.text_width(_points, _points.text)) + 14
	_unit.size.x = _kicker.position.x + _kicker.size.x - _unit.position.x
	var cls_n: String = str(sim.cls) if sim.cls != "" else "class"
	UI.fit(_unit, [WS["spent"] % [sim.web_spent(), sim.web_points(), cls_n], WS["spent_mid"] % [sim.web_spent(), sim.web_points()], WS["spent_short"] % [sim.web_spent(), sim.web_points()], ""])
	_class_line.text = ""                  # the class's sentence is its card's tooltip now (14 Oct); the notice is the line
	_class_line.visible = false
	for k in range(Data.CLASSES.size()):
		_show_card(k)
	_notice.add_theme_color_override("font_color", Pal.TEXT)
	if _armed != "":
		_notice.add_theme_color_override("font_color", Pal.ACCENT)
		var lv: int = sim.crew_level(_armed)
		var jl: int = sim.join_level(_armed)     # the crew's floor (30 Oct): the level they'd join at, when it lifts them
		var C: Dictionary = Words.CREW
		if jl > maxi(1, lv):
			if lv > 0:
				UI.fit(_notice, [C["join_long"] % [_armed, jl, lv], C["join_mid"] % [_armed, jl], C["join_new_mid"] % [_armed, jl]])
			else:
				UI.fit(_notice, [C["join_new"] % [_armed, jl], C["join_mid"] % [_armed, jl], C["join_new_mid"] % [_armed, jl]])
		elif lv > 0:
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
	var open: bool = mine or sim.class_open(nm)     # each class after its head (milestone 8; skills.md §6)
	var lit: bool = (mine or armed or sim.cls == "") and open
	cb.disabled = sim.runner_busy() or not open
	var edge: Color = Pal.ACCENT if (mine or armed) else Pal.CARD_LINE
	var w: int = 2 if (mine or armed) else 1
	for pair in [["normal", 0.0], ["hover", 0.08], ["pressed", 0.12], ["hover_pressed", 0.12], ["disabled", 0.0]]:
		var sb := UI.box(Color(PILL_GLASS, 0.72).lightened(float(pair[1])), 8, w, edge)
		cb.add_theme_stylebox_override(pair[0], sb)
	cb.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 8, 2, Pal.TEXT))
	cb.modulate.a = 0.5 if (cb.disabled and not mine) else 1.0
	c["face"].modulate = Color(1, 1, 1, 1.0 if lit else 0.75)
	c["name"].add_theme_color_override("font_color", Pal.TEXT if lit else Pal.TEXT_2)
	var who: String = str(Words.CLASS_UNLOCK.get(nm, {}).get("who", ""))
	UI.fit(c["tag"], [Words.CLASS_SELECTED] if mine else (["press again"] if armed else (_crew_tag(nm) if open else [who])))
	c["lock"].visible = not open                # a locked class: the lock and the head that opens it (24 Oct, option B)
	c["tag"].position.x = float(c["tag_x"]) + (16.0 if not open else 0.0)
	c["tag"].size.x = CLASS_W - float(c["tag_x"]) - 6.0 - (16.0 if not open else 0.0)
	c["tag"].add_theme_color_override("font_color", Pal.ACCENT if open else Pal.TEXT_3)
	cb.tooltip_text = "%s: %s" % [nm, cd["words"]] + ("" if open else "\n%s %s" % [Words.OPENS_AFTER, who])     # the perks in the sentence (the card's lines went, option B)


## A class's card when it isn't out (21 Oct, the crew): its level and element, wounded, or new - long to short ("Level N",
## 27 Oct, Matt: not "L4").
func _crew_tag(nm: String) -> Array:
	if sim.cls == "":
		return [""]
	var lv: int = sim.crew_level(nm)
	if lv <= 0:
		return ["new"]
	var r: Dictionary = sim.crew_runner(nm)
	var el: String = sim.crew_element(nm)
	var bit: String = "wounded" if not Dictionary(r.get("wounds", {})).is_empty() else el
	return (["Level %d · %s" % [lv, bit]] if bit != "" else []) + ["Level %d" % lv]


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


func _show_also() -> void:
	var names: Array = also_names()
	var x: float = PAD + ALSO_HEAD_W
	var right: float = WEB_W - PAD
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
			words = WebView.plain_name(nm)            # the name alone (28 Oct, Matt)
		elif t.get("class", "") != "":
			words = nm
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
		words = UI.dots(words)                    # the caps pass (27 Oct)
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
	var shelf_of: Array = Data.UNIQUES.filter(func(u): return not u.get("mythic", false)).map(func(u): return str(u["name"]))
	branch["found"] = sim.shelf.filter(func(nm): return str(nm) in shelf_of).size()     # of the shelf's own, never past its "of N" (the third review)
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
	var top: float = 100.0 * Data.CONV_CAP
	var sc: float = top / converted if converted > top else 1.0     # past the cap (CONV_CAP, 31 Oct: a tenth stays physical) the shares are cut back together, as the fight does
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
		if sim.web_owned(pair[0]):
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
	var pairs: Array = sim.web_pairs() if sim.cls != "" else []     # the runner's two (3 Nov: pairs, the web's word)
	if not pairs.is_empty():
		items.append({"tag": "Pairs", "forms": ["%d of %d" % [pairs.filter(func(p): return p["done"]).size(), pairs.size()]], "colour": Pal.ACCENT})
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


## The big nodes' gates (docs/design/skill_web.md, the one rule's 4): a keystone wants 15 points spent first, a capstone 40.
const KEYSTONE_AT := Data.KEYSTONE_SPENT
const CAPSTONE_AT := Data.CAPSTONE_SPENT


## The node card, the pairs, the big nodes and the reset (3 Nov): what's picked - a node, the class (nothing picked) or
## a swap armed - in the card; the runner's two pairs; the gates; the reset's price.
func _show_panel() -> void:
	var WS: Dictionary = Words.WEB_SCREEN
	_train.visible = false
	_chips.visible = false
	_past.visible = false
	_past.text = ""
	_no_use.visible = false
	_no_use.text = ""
	_where.text = ""
	_icon.texture = null
	_node_forms = []
	var ring_tone: Color = Pal.CARD_LINE
	_where.add_theme_color_override("font_color", Pal.TEXT_2)
	if selected != "" and not _web.layout.has(selected):
		selected = ""
	if selected == "" and _armed != "":
		var lv: int = sim.crew_level(_armed)
		var el: String = sim.crew_element(_armed)
		var r: Dictionary = sim.crew_runner(_armed)
		UI.fit(_title, [UI.dots(("%s · level %d" % [_armed, lv]) if lv > 0 else "%s · new" % _armed), _armed])
		if el != "":
			UI.fit(_where, [el])
		var kit: Array = []
		for sl in ["Primary", "Armour", "Helmet"]:
			var it = r.get("equipped", {}).get(sl, null)
			if it != null:
				kit.append(Items.full_name(it))
		var trt: String = str(r.get("trait", ""))
		var state: String = "wounded: send them out to see the Clinic" if not Dictionary(r.get("wounds", {})).is_empty() else ""
		if lv <= 0:
			_node_forms = ["A new runner: level 1, the arrival's kit, their own points from here.", "A new runner at level 1."]
		else:
			_node_forms = ["%s%s%s." % [", ".join(kit), (" · " + trt) if trt != "" else "", (" · " + state) if state != "" else ""], ", ".join(kit) + "."]
		_icon.texture = People.portrait(_armed)
		_train.visible = true
		_train.text = "Swap to the %s" % _armed
		_train.disabled = sim.runner_busy()
		ring_tone = Pal.ACCENT
	elif selected == "":
		var cd: Dictionary = sim.class_data()
		if cd.is_empty():
			UI.fit(_title, [WS["no_past"]])
			_node_forms = [WS["pick_past"] + ".", "Pick one above."]
		else:
			var td: Dictionary = sim.trait_data()
			UI.fit(_title, [("%s · %s" % [cd["name"], td["name"]]) if not td.is_empty() else str(cd["name"]), str(cd["name"])])
			UI.fit(_where, [WS["level"] % sim.level()])
			if not td.is_empty():
				_node_forms = ["%s: %s · the runner's trait, one each, goes with them." % [td["name"], td["words"]], "%s: %s." % [td["name"], td["words"]]]
			var sid: String = Data.web_start(str(sim.cls))
			if sid != "":
				_icon.texture = _picture_of(sid)
			ring_tone = Pal.TEXT
			_past.visible = true
			_show_past()
	else:
		var nd: Dictionary = _web.node_of(selected)
		var on_ring: bool = _web._region.get(selected, "") == "ring"
		var kind: String = str(_web._kind.get(selected, "small"))
		var nm: String = str(nd.get("name", ""))
		UI.fit(_title, [nm if nm != "" else _cap1(str(WS.get(kind, WS["small"])))])
		UI.fit(_where, [where_words(selected), where_words(selected, true)])
		_where.add_theme_color_override("font_color", _web.tone_of(selected) if not _web._region.get(selected, "").begins_with("class:") else Pal.TEXT_2)
		_icon.texture = _picture_of(selected)
		var st: Dictionary = _web.state_of(selected)
		ring_tone = _web.tone_of(selected) if st.get("taken", false) else (WebView.FRONTIER if st.get("reach", false) else Pal.CARD_LINE)
		var items: Array = []
		if nd.has("effect") or nd.get("keystone", false) or nd.get("capstone", false) or nd.get("notable", false):
			items.append({"forms": [_chip_words(nd)], "colour": _effect_tone(nd)})
		if nd.has("type"):
			items.append({"forms": [type_words(nd)], "colour": Pal.TEXT_2})
		if not on_ring and sim.has_method("node_damage_gain") and nd.has("effect"):
			var gain: Array = sim.node_damage_gain(selected)     # what it adds to the one figure, tried on (16 Oct, item 14)
			if float(gain[0]) >= 0.5:
				items.append({"forms": ["%s +%.0f a second (+%.0f%%)" % ["Adds" if st.get("taken", false) else "For you:", float(gain[0]), float(gain[1]) * 100.0], "+%.0f/s (+%.0f%%)" % [float(gain[0]), float(gain[1]) * 100.0], "+%.0f/s" % float(gain[0])], "colour": Pal.GOOD})
		_chips.visible = not items.is_empty()
		if _chips.visible:
			_chips.show_chips(items)
		var only: String = sim.web_class_only(selected) if not on_ring and sim.has_method("web_class_only") else ""
		if only != "":
			UI.fit(_no_use, [WS["no_use"] % [only, str(sim.cls)], WS["no_use_short"] % only])
			_no_use.visible = true
		var sentence: String = _sentence(nd)
		var tail: String = _pair_tail(selected)
		_node_forms = ["%s %s" % [sentence, tail], sentence, tail] if tail != "" else [sentence]
		_train.visible = true
		if on_ring:
			var on: int = int(sim.ring.get(selected, 0))
			var full: bool = on >= int(nd.get("stack", 1))
			UI.fit_button(_train, [WS["ring_full"]] if full else [WS["ring_take"]])
			_train.disabled = full or not sim.can_train(selected)
		elif sim.web_owned(selected):
			_train.text = WS["yours"]
			_train.disabled = true
		else:
			var why: String = sim.web_can_take(selected)
			UI.fit_button(_train, [WS["take"]] if why == "" else [why])
			_train.disabled = why != ""
	_icon_ring.add_theme_stylebox_override("panel", UI.box(Pal.BG, HALF_ICON, 2, ring_tone))
	UI.style_button(_train, true)
	fit_lines(_node_forms)
	_node_forms = []
	_show_pairs()
	_show_big()
	_show_reset()


## A node's picture for the card: its painting (or its skill's), else its glyph.
func _picture_of(id: String) -> Texture2D:
	var nd: Dictionary = _web.node_of(id)
	var pic: Texture2D = WebView.picture(_web.picture_slug(nd))
	if pic == null and _web.glyph_of(nd) != "":
		pic = NodeGlyphs.texture(_web.glyph_of(nd))
	return pic


## Where a node sits, in words: "The cold · the tip · a notable", "The Poacher · Stalking · a notable", "The centre · a
## small node", "Between the Poacher and the cold · a small node"; `short` leaves the kind off.
func where_words(id: String, short := false) -> String:
	var WS: Dictionary = Words.WEB_SCREEN
	var rg: String = str(_web._region.get(id, ""))
	var kind: String = str(_web._kind.get(id, "small"))
	var parts: Array = []
	if rg == "centre":
		parts.append(WS["centre"])
	elif rg.begins_with("el:"):
		parts.append(rg.substr(3))
		var sn: String = Data.web_slot(id)
		var tail: String = sn.get_slice("_", 1)
		parts.append(WS["tip"] if tail == "4" else (WS["run"] if tail.begins_with("r") or tail in ["ks", "cap"] else WS["flower"]))
	elif rg.begins_with("class:"):
		parts.append(WS["the_class"] % rg.substr(6))
		parts.append(id.get_slice("/", 0))
	elif rg == "join":
		var el: String = _web.join_element(id)
		parts.append(WS["between"] % [_join_class(id), Words.mid(el)])
	elif rg == "ring":
		parts.append(_cap1(WS["ring"]))
		parts.append("%d of %d" % [int(sim.ring.get(id, 0)), int(_web.node_of(id).get("stack", 1))])     # its paragon points on it
	if not short and rg != "ring":
		parts.append(str(WS.get(kind, WS["small"])))
	return " · ".join(parts)


## The class a join runs to: along the join's own nodes to the one next to a class's start.
func _join_class(id: String) -> String:
	var seen := {id: true}
	var q: Array = [id]
	while not q.is_empty():
		var a: String = q.pop_front()
		for o in _web._links.get(a, []):
			var rg: String = str(_web._region.get(o, ""))
			if rg.begins_with("class:"):
				return rg.substr(6)
			if rg == "join" and not seen.has(o):
				seen[o] = true
				q.append(o)
	return ""


## A pair's half (the runner's): what its other half is and how far.
func _pair_tail(id: String) -> String:
	if sim.cls == "":
		return ""
	for p in sim.web_pairs():
		var h: Array = p["halves"]
		if not (id in h):
			continue
		var other: String = str(h[1]) if str(h[0]) == id else str(h[0])
		var on: String = str(_web.node_of(other).get("name", ""))
		if p["done"]:
			return "Its pair is done with %s: %s." % [on, _first_lower(str(p["words"]))]
		var s: int = sim.web_steps(other)
		return "Its pair is %s, %s: %s." % [on, Words.WEB_SCREEN["yours"].to_lower() if s == 0 else _steps_words(s) + " away", _first_lower(str(p["words"]))]
	return ""


static func _steps_words(n: int) -> String:
	return Words.WEB_SCREEN["step"] if n == 1 else Words.WEB_SCREEN["steps"] % n


static func _cap1(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1) if t != "" else t


static func _first_lower(t: String) -> String:
	return t.substr(0, 1).to_lower() + t.substr(1) if t != "" else t


## The runner's two pairs: done, or what's had and how far the rest is (Sim.web_steps), each over three lines.
func _show_pairs() -> void:
	var WS: Dictionary = Words.WEB_SCREEN
	var pairs: Array = sim.web_pairs() if sim.cls != "" else []
	for k in range(_pair_rows.size()):
		var row: Dictionary = _pair_rows[k]
		var lines: Array = row["lines"]
		if k >= pairs.size():
			row["dot"].visible = false
			UI.wrap(lines, WS["no_pairs"] if k == 0 and pairs.is_empty() else "")
			continue
		var p: Dictionary = pairs[k]
		var h: Array = p["halves"]
		var a: String = str(_web.node_of(str(h[0])).get("name", h[0]))
		var b: String = str(_web.node_of(str(h[1])).get("name", h[1]))
		var words: String = str(p["words"])
		var forms: Array = []
		if p["done"]:
			forms = [WS["pair_done"] % [a, b, _first_lower(words)]]
		else:
			var own_a: bool = sim.web_owned(str(h[0]))
			var own_b: bool = sim.web_owned(str(h[1]))
			if own_a or own_b:
				var have: String = a if own_a else b
				var other: String = b if own_a else a
				var s: String = _steps_words(sim.web_steps(str(h[1]) if own_a else str(h[0])))
				forms = [WS["pair_half"] % [a, b, have, other, s, words], WS["pair_half_short"] % [a, b, other, s]]
			else:
				var sa: String = _steps_words(sim.web_steps(str(h[0])))
				var sb: String = _steps_words(sim.web_steps(str(h[1])))
				forms = [WS["pair_none"] % [a, b, sa, sb, words], WS["pair_none_short"] % [a, b, sa, sb]]
		row["dot"].visible = true
		row["dot"].add_theme_stylebox_override("panel", UI.box(Pal.GOOD if p["done"] else Pal.CARD_LINE, 6))
		_wrap_forms(lines, forms)
		for l in lines:
			l.add_theme_color_override("font_color", Pal.TEXT if p["done"] else Pal.TEXT_2)


## The longest form that wraps into the labels whole (the last label's line inside its width).
func _wrap_forms(lines: Array, forms: Array) -> void:
	for f in forms:
		UI.wrap(lines, str(f))
		var last: Label = lines[lines.size() - 1]
		if UI.text_width(last, last.text) <= last.size.x:
			return
	UI.wrap(lines, str(forms[forms.size() - 1]))


## The big nodes: keystones at 15 points spent, capstones at 40, how far off, and the bar to 40 with the 15 marked.
func _show_big() -> void:
	var WS: Dictionary = Words.WEB_SCREEN
	var spent: int = sim.web_spent()
	UI.fit(_big_lines[0], [WS["keys_open"] % KEYSTONE_AT if spent >= KEYSTONE_AT else WS["keys_to_go"] % [KEYSTONE_AT, KEYSTONE_AT - spent]])
	UI.fit(_big_lines[1], [WS["caps_open"] % CAPSTONE_AT if spent >= CAPSTONE_AT else WS["caps_to_go"] % [CAPSTONE_AT, CAPSTONE_AT - spent]])
	var w: float = _big_bar.size.x
	_big_fill.size.x = w * clampf(float(spent) / CAPSTONE_AT, 0.0, 1.0)
	_big_tick.position.x = w * float(KEYSTONE_AT) / CAPSTONE_AT - 1.0


## The reset: the web's (every point back, today's price), or the ring's with a ring node picked; it asks twice.
func _show_reset() -> void:
	var armed: bool = respec_armed()
	if _respec_key() == "ring":
		_respec.text = (Words.ASK["again"] % Words.BUILD["ring_sure"] if armed else Words.BUILD["ring_sure"]) % Fmt.money(sim.paragon_reset_cost())
		_respec.disabled = sim.paragon_spent() == 0 or sim.cash < sim.paragon_reset_cost()
	else:
		var price: int = sim.respec_cost()
		_respec.text = (Words.ASK["again"] % Words.WEB_SCREEN["reset"] if armed else Words.WEB_SCREEN["reset"]) % Fmt.money(price)
		_respec.disabled = sim.runner_busy() or sim.web_spent() == 0 or sim.cash < price
	UI.style_button(_respec, false, "bad" if armed else "")


## A sentence over the card's three lines: the longest form that wraps into them whole.
func fit_lines(forms: Array) -> void:
	var lines: Array = [_words, _words2, _words3]
	var live: Array = forms.filter(func(f): return str(f) != "")
	if live.is_empty():
		UI.wrap(lines, "")
		return
	_wrap_forms(lines, live)


## (The old strip's two lines: the tests fit a sentence `w` wide.)
func fit_two(forms: Array, w: float) -> void:
	for l in [_words, _words2, _words3]:
		l.size.x = w
	fit_lines(forms)
	for l in [_words, _words2, _words3]:
		l.size.x = SIDE_W - 2 * CP


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
	# BUILD45 (perf44: a late camp's thousand past runners joined and measured, 50-90 ms an open): the lists stop once
	# they're longer than the line could hold at its narrowest letters - a form past that can't fit, as it couldn't before
	var cap: int = _past_cap()
	var n_long := 0
	var n_short := 0
	for k in range(sim.past.size() - 1, -1, -1):
		if n_long > cap and n_short > cap and long.size() >= 2:
			break
		var r: Dictionary = sim.past[k]
		var held: String = (", %s at level %d" % [Words.mid(str(r["site"])), int(r.get("held_lv", 0))]) if int(r.get("held_lv", 0)) > 0 else ""
		long.append("a %s, %d run%s%s, %s" % [str(r["class"]), int(r["runs"]), "" if int(r["runs"]) == 1 else "s", held, r["end"]])
		short.append("%s %d" % [str(r["class"]), int(r["runs"])])
		n_long += str(long.back()).length() + 2
		n_short += str(short.back()).length() + 2
	UI.fit(_past, ["Before: " + "; ".join(long), "Before: " + "; ".join(long.slice(0, 2)), "Before: " + ", ".join(short), long[0], "%d runner%s before this one" % [sim.past_count(), "" if sim.past_count() == 1 else "s"]])


## The most letters the past's line could hold: its width over the narrowest of the letters its words use (BUILD45).
func _past_cap() -> int:
	var narrow: float = INF
	for ch in [" ", ".", ",", ";", ":", "i", "l", "I", "1", "'"]:
		narrow = minf(narrow, UI.text_width(_past, ch))
	return ceili(_past.size.x / maxf(1.0, narrow)) + 8


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
	if sim.runner_busy() or nm == sim.cls:
		_armed = ""
		show_state(sim)
		return
	if sim.cls != "" and (_armed != nm or Time.get_ticks_msec() - _armed_ms > int(Arm.WINDOW_S * 1000.0)):     # a late second press arms again
		_armed = nm                            # a swap (21 Oct, the crew): the first press shows them, the second sends them out
		_armed_cls = sim.cls
		_armed_ms = Time.get_ticks_msec()
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
		_pick_class(_armed)                    # the card's Swap button: the second press (21 Oct, the crew)
		return
	_armed = ""
	if selected != "":
		var ok: bool = sim.train_node(selected) if _web._region.get(selected, "") == "ring" else sim.web_take(selected)     # the ring's paragon points; the web's one point a node (3 Nov)
		if ok:
			acted.emit()
	show_state(sim)


## The reset asks twice (25 Oct, the review: one press threw a whole build away): the first arms it; the second resets,
## with the build's code copied first so it can be pasted back. Armed on what it resets - the trees, or the ring - and
## on what's picked and trained: picking or training anything disarms it (the second review: armed on the trees, a ring
## node picked, the second press reset the ring).
var _respec_arm := Arm.new()


## What the reset resets, by the node picked: the ring with a ring node, else the web (3 Nov: one reset, every point back).
func _respec_key() -> String:
	if selected != "" and _web._region.get(selected, "") == "ring":
		return "ring"
	return "web"


func _respec_fp() -> String:
	return "%s|%d|%d|%d" % [selected, sim.tree.size(), sim.web_spent(), sim.paragon_spent()]


func respec_armed() -> bool:
	return sim != null and _respec_arm.holds(_respec_key(), _respec_fp())


func _on_respec() -> void:
	_armed = ""
	if not _respec_arm.press(_respec_key(), _respec_fp()):
		_shown = ""
		show_state(sim)
		return
	var done: bool = false
	if _respec_key() == "ring":
		done = sim.paragon_reset()
	else:
		var code: String = sim.build_code()     # read before the reset clears it; copied only once it's done (the review)
		done = sim.web_reset()
		if done:
			_clip(code)
			sim.log_event(Words.WEB_SCREEN["reset_copied"])
	if done:
		acted.emit()
	_shown = ""
	show_state(sim)


## For the tests: the labels that share a line and must not run into each other - a tile's name and its cost,
## and the points and their unit.
func line_pairs() -> Array:
	return [[_points, _unit]]


## For the tests: every label with text on show.
func text_nodes() -> Array:
	var out: Array = [_title, _where, _words, _words2, _words3, _past, _no_use, _respec, _sum_head, _kicker, _points, _unit, _class_line, _notice, _also_head, _pairs_head, _big_head]
	out.append_array(_big_lines)
	for r in _pair_rows:
		out.append_array(r["lines"])
	if _chips.visible:
		out.append_array(_chips.text_nodes())
	out.append_array(_sum_chips.text_nodes())
	for b in [_train, code_copy, code_paste]:
		if b.visible:
			out.append(b)
	for c in _class_cards:
		out.append_array([c["name"], c["tag"]])
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


# ------------------------------------------------------------------ the build code (24 Oct, the endgame chase, phase 7)

func _build_code_panel() -> void:
	var h: float = CODE_Y - 8 - LANES_Y
	var iw: float = SIDE_W - 2 * CP
	code_panel = UI.panel(self, Rect2(SIDE_X, LANES_Y, SIDE_W, h), UI.box(Pal.CARD, 8, 1, Pal.ACCENT))
	code_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_code_title = UI.label(code_panel, Rect2(CP, CP, iw, 34), "", "SemiBold", Pal.TITLE - 6, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_code_plan = UI.label(code_panel, Rect2(CP, CP + 46, iw, LINE_H), "", "Regular", CARD_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_code_plan2 = UI.label(code_panel, Rect2(CP, CP + 46 + LINE_H, iw, LINE_H), "", "Regular", CARD_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_code_plan3 = UI.label(code_panel, Rect2(CP, CP + 46 + 2 * LINE_H, iw, LINE_H), "", "Regular", CARD_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	@warning_ignore("integer_division")
	var half: int = int(iw - 8) / 2
	_code_go = UI.button(code_panel, Rect2(CP, h - CP - BTN_H, half, BTN_H), true)
	_code_go.text = Words.BUILD["go"]
	_code_go.pressed.connect(_retrain_build)
	_code_cancel = UI.button(code_panel, Rect2(CP + half + 8, h - CP - BTN_H, iw - half - 8, BTN_H), false)
	_code_cancel.text = Words.BUILD["cancel"]
	_code_cancel.pressed.connect(cancel_build)
	code_panel.visible = false


func _copy_code() -> void:
	var code: String = sim.build_code()
	_clip(code)
	sim.log_event(Words.BUILD["copied"])
	acted.emit()


## A code to the clipboard; to `copied` instead while the smoke runs (it ran beside Matt's work and wrote his clipboard).
func _clip(code: String) -> void:
	if clip_off:
		copied = code
	else:
		DisplayServer.clipboard_set(code)


func _paste_code() -> void:
	read_code(paste_text if paste_text != "" else DisplayServer.clipboard_get())


## A code read and its plan shown: what it takes, the reset's price, the nodes that'll train. Nothing changes yet.
func read_code(code: String) -> void:
	if code_panel == null:
		_build_code_panel()
	_code_str = code
	pending_build = sim.build_read(code)
	var plan: Dictionary = sim.build_plan(pending_build)
	if pending_build.is_empty() or pending_build.has("old"):
		UI.fit(_code_title, [Words.BUILD["old"] if pending_build.has("old") else Words.BUILD["bad"]])
	else:
		UI.fit(_code_title, [Words.BUILD["title"] % [str(pending_build["cls"]), pending_build["nodes"].size(), pending_build["skills"].size()], str(pending_build["cls"])])
	var words: String = str(plan["block"])
	if words == "":
		words = Words.BUILD["plan"] % [Fmt.money(int(plan["cost"])), int(plan["trained"]), int(plan["of"])] if int(plan["cost"]) > 0 else Words.BUILD["plan_free"] % [int(plan["trained"]), int(plan["of"])]
		if not plan["missed"].is_empty():
			words += " · " + Words.BUILD["missed"] % plan["missed"].size()
	_wrap_forms([_code_plan, _code_plan2, _code_plan3], [words])
	_code_go.disabled = str(plan["block"]) != ""
	code_panel.visible = true
	move_child(code_panel, -1)


func _retrain_build() -> void:
	var r: Dictionary = sim.build_apply(pending_build)
	if str(r["block"]) == "":
		sim.log_event(Words.BUILD["done"] % [int(r["trained"]), int(r["of"])])
		cancel_build()
		acted.emit()
	else:
		_wrap_forms([_code_plan, _code_plan2, _code_plan3], [str(r["block"])])


## Leaving the room drops a pasted code's plan.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		_respec_arm.clear()                  # out of the room, the reset's arm goes
		_shown = ""                          # and its button is drawn again on the way back (the second review)
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible and code_panel != null and code_panel.visible:
		pending_build = {}
		code_panel.visible = false


func cancel_build() -> void:
	pending_build = {}
	if code_panel != null:
		code_panel.visible = false
	_shown = ""
	show_state(sim)


## For the tests: the code panel's words.
func code_text_nodes() -> Array:
	return [_code_title, _code_plan, _code_plan2, _code_plan3, _code_go, _code_cancel, code_copy, code_paste].filter(func(n): return n != null and n.visible)
