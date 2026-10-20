extends Control
## The Radio as the endgame (15 Oct, docs/design/endgame_radio.md, mockup signals_radio.png; Matt: "the endgame is
## the wrong way round"). Three papers in, a signal out: one mission on a campaign site at random, a crew from any
## zone, a depth rolled round your reach, each paper's code on it. Down the left the papers held, each with its code;
## in the middle the decoder, three in and what they'll make; on the right the signals held, the picked one as a card
## (its figures, its codes, Kev's line, the crafts, Set off) and the rest under it. The Dial, the endgame's tree, in
## the band's other view. Before the Quartermaster: nothing on the air.
##
## Signals: `acted` after anything changes; `choose_book(kind)` for "standing0", "standing1", "filter" - main opens
## its menu for those.

signal acted
signal choose_book(kind: String)

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const Data := preload("res://scripts/sim/data.gd")
const Atlas := preload("res://scripts/ui/atlas.gd")
const Words := preload("res://scripts/sim/words.gd")
const RadioLine := preload("res://scripts/ui/radio_line.gd")
const Town := preload("res://scripts/ui/town.gd")
const KevStory := preload("res://scripts/ui/kev_story.gd")

const PAD := 20
const HEAD_H := Pal.BAND_H
const BODY_Y := HEAD_H + 8
const BODY_H := Pal.ROOM_H - BODY_Y
const COL_GAP := 12
const PAPERS_W := 404
const DECODER_W := 420
const DECODER_X := PAPERS_W + COL_GAP
const SIGNALS_X := DECODER_X + DECODER_W + COL_GAP
const SIGNALS_W := Pal.GRID_W - SIGNALS_X
const HEAD_ROW_H := 62              # a column's head: its title and a line under
const PAPER_H := 66
const PAPER_GAP := 8
const PAPERS_MAX := 7               # a page of them; ‹ › past that
const SLOT_H := 104
const SLOT_GAP := 12
const MAKE_H := 112
const CARD_H := 470                 # the picked signal
const CRAFT_H := 50
const OTHER_H := 70
const OTHERS_MAX := 2
const VIEW_W := 170
const VIEW_H := 28
const VIEW_Y := 88
const HEARD_X := 470
const HEARD_Y := HEAD_H - 44
const BITE := Color("ee7663")
const SPARE_NAME := ["", "A second paper", "A third paper"]     # an empty slot past the first paper (20 Oct)
const KEV_H := 96                  # Kev's pile, under the decoder
const KEV := Color("f0a868")        # Kev's voice's colour (the radio line's mockup, approved 16 Oct)
const STORY := Color("8fb3d9")      # Kev's story's papers and signals (the mockup's blue)
const PAY := Color("62bd8f")

var head_band := {}
var sim
var selected := 0                   # the signal picked, by its place on the Radio
var chosen: Array = []              # the papers in the decoder, by id, in order
var paper_page := 0
var view := "air"                   # "air": papers and signals; "map": the Dial; "town": the rebuild (18 Oct)
const VIEWS := ["air", "map", "town", "story"]     # Kev's story its own (20 Oct, Matt: no payoff on screen)
var _kicker: Label
var _headline: Label
var _unit: Label
var _sub: Label
var _chips: Chips
var _heard: Label
var _heard_pill: Panel
var _air: Control
var _atlas
var _town
var _story                         # Kev's story, the fourth view (20 Oct)
var _views: Array = []
var _quiet: Array = []              # nothing on the air: the lines before the Quartermaster
# the papers
var _papers_box: Panel
var _papers_title: Label
var _papers_sub: Label
var _paper_rows: Array = []         # {button, name, code, badge, id}
var _paper_prev: Button
var _paper_next: Button
var _paper_page: Label
var _stand: Array = []
var _filter: Button
# the decoder
var _decoder_box: Panel
var _decoder_title: Label
var _slots: Array = []              # {panel, n, name, code}
var _make_box: Panel
var _make_head: Label
var _make: Label
var _make_sub: Label
var _make_sub2: Label
var _decrypt: Button
var _decrypt_note: Label
var _kev_box: Panel                 # Kev's pile (16 Oct): a plain paper for notes
var _kev_head: Label
var _kev_line: Label
var _kev: Button
# the signals
var _signals_box: Panel
var _signals_title: Label
var _card: Panel
var _card_kicker: Label
var _card_title: Label
var _card_line: Label
var _card_odds: Label
var _card_odds_sub: Label
var _card_tiles: Array = []
var _card_codes: Chips
var _card_kev: Label
var _card_kev2: Label
var _crafts: Array = []             # {button, name, words, key}
var _set_off: Button
var _bin: Button
var _empty: Label
var _empty2: Label
var _others: Array = []             # {button, name, line, odds}
var _shown := ""
# the decrypt (16 Oct, item 20; the UI pass canvas): the new signal's card coming through, about 2.5 s; the sim's
# signal is made at the press, this is only the look of it, and a tap (the button, or the card) skips to the end
const DEC_S := 2.5
const DEC_BARS := 16
var _dec: Panel
var _dec_dot: Panel
var _dec_freq: Label
var _dec_bars: Array = []
var _dec_lines: Array = []          # [Label, text, from s, to s, colour]
var _dec_scan: Panel
var _dec_t := -1.0                  # seconds in; below 0, not running
var sound = null                    # the shell's (17 Oct): the decrypt's ticks; null in a bare test
var _dec_heard := 0                 # glyphs locked so far, for the ticks
var _dec_done := 0                  # lines done so far
var _dec_tick_t := 0.0


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var head := UI.panel(self, Rect2(0, 0, Pal.GRID_W, HEAD_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	head_band = UI.head_art(head, "The radio")
	_kicker = UI.label(head, Rect2(PAD, 8, 420, 24), "Radio", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_headline = UI.label(head, Rect2(PAD, 32, 330, 44), "", "SemiBold", Pal.HEADLINE - 4, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_unit = UI.label(head, Rect2(PAD, 38, 240, 36), "", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(head, Rect2(PAD, 78, 440, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_chips = Chips.new(560, 6)
	_chips.position = Vector2(PAD, 112)
	head.add_child(_chips)
	_heard_pill = UI.panel(head, Rect2(0, HEARD_Y, 10, 28), UI.box(Color(0.06, 0.07, 0.08, 0.62), 10))
	_heard_pill.visible = false
	_heard = UI.label(head, Rect2(HEARD_X + 140, HEARD_Y, Pal.GRID_W - PAD - HEARD_X - 140, 28), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_build_papers()
	_build_decoder()
	_build_signals()
	for k in range(3):
		_quiet.append(UI.label(self, Rect2(PAD, BODY_Y + 30 + k * 40, Pal.GRID_W - 2 * PAD, 30), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_air = Control.new()
	_air.size = size
	_air.mouse_filter = Control.MOUSE_FILTER_PASS
	for ch in get_children():
		remove_child(ch)
		_air.add_child(ch)
	add_child(_air)
	_atlas = Atlas.new(Pal.ROOM_H)
	_atlas.visible = false
	_atlas.acted.connect(func(): acted.emit())
	add_child(_atlas)
	_town = Town.new()
	_town.visible = false
	_town.acted.connect(func(): acted.emit())
	add_child(_town)
	_story = KevStory.new()
	_story.visible = false
	add_child(_story)
	for k in range(VIEWS.size()):
		var vb := UI.button(self, Rect2(Pal.GRID_W - PAD - (VIEWS.size() - k) * (VIEW_W + 6) + 6, VIEW_Y, VIEW_W, VIEW_H), false)
		vb.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 1)
		vb.pressed.connect(_pick_view.bind(VIEWS[k]))
		_views.append(vb)


func _build_papers() -> void:
	_papers_box = UI.panel(self, Rect2(0, BODY_Y, PAPERS_W, BODY_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var iw: float = PAPERS_W - 2 * 14
	_papers_title = UI.label(_papers_box, Rect2(14, 10, iw, 26), "", "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_papers_sub = UI.label(_papers_box, Rect2(14, 34, iw, 24), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(PAPERS_MAX):
		var b := Button.new()
		b.position = Vector2(14, HEAD_ROW_H + k * (PAPER_H + PAPER_GAP))
		b.size = Vector2(iw, PAPER_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_toggle_paper.bind(k))
		_papers_box.add_child(b)
		var r := {"button": b, "id": -1}
		r["name"] = UI.label(b, Rect2(12, 6, iw - 80, 28), "", "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["code"] = UI.label(b, Rect2(12, 34, iw - 24, 24), "", "Regular", Pal.CELL_TEXT - 1, PAY, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["badge"] = UI.label(b, Rect2(iw - 46, 8, 34, 22), "IN", "SemiBold", Pal.CELL_TEXT - 4, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, false)
		r["badge"].add_theme_stylebox_override("normal", UI.box(Pal.BG, 4, 1, Pal.ACCENT))
		_paper_rows.append(r)
	var py: float = HEAD_ROW_H + PAPERS_MAX * (PAPER_H + PAPER_GAP)
	_paper_prev = UI.button(_papers_box, Rect2(14, py, 44, 32), false)     # 44: the arrow needs 42 (16 Oct, the smoke with a page of 30)
	_paper_prev.text = "‹"
	_paper_prev.pressed.connect(func(): _turn(-1))
	_paper_next = UI.button(_papers_box, Rect2(14 + 104, py, 44, 32), false)
	_paper_next.text = "›"
	_paper_next.pressed.connect(func(): _turn(1))
	_paper_page = UI.label(_papers_box, Rect2(14 + 46, py, 56, 32), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER, false)
	# the Dial's standing codes and Clear air's filter (9 Oct), a row at the column's foot
	var sx: float = 14
	var sw: float = (iw - 2 * 6) / 3.0
	py += 40
	for k in range(2):
		var sb := UI.button(_papers_box, Rect2(sx + k * (sw + 6), py, sw, 32), false)
		sb.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 4)
		sb.pressed.connect(func(): choose_book.emit("standing%d" % k))
		_stand.append(sb)
	_filter = UI.button(_papers_box, Rect2(sx + 2 * (sw + 6), py, sw, 32), false)
	_filter.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 4)
	_filter.pressed.connect(func(): choose_book.emit("filter"))


func _build_decoder() -> void:
	_decoder_box = UI.panel(self, Rect2(DECODER_X, BODY_Y, DECODER_W, BODY_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var iw: float = DECODER_W - 2 * 14
	_decoder_title = UI.label(_decoder_box, Rect2(14, 10, iw, 26), "THE DECODER · ONE TO THREE PAPERS", "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(Data.SIGNAL_PAPERS):
		var p := UI.panel(_decoder_box, Rect2(14, 46 + k * (SLOT_H + SLOT_GAP), iw, SLOT_H), UI.box(Pal.BG, 7, 1, Pal.CARD_LINE))
		var sl := {"panel": p}
		sl["n"] = UI.label(p, Rect2(14, 8, iw - 28, 20), "%d" % (k + 1), "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		sl["name"] = UI.label(p, Rect2(14, 30, iw - 28, 30), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		sl["code"] = UI.label(p, Rect2(14, 62, iw - 28, 26), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		_slots.append(sl)
	var my: float = 46 + Data.SIGNAL_PAPERS * (SLOT_H + SLOT_GAP)
	_make_box = UI.panel(_decoder_box, Rect2(14, my, iw, MAKE_H), UI.box(Pal.CARD, 7, 1, Pal.CARD_LINE))
	_make_head = UI.label(_make_box, Rect2(14, 8, iw - 28, 22), "WHAT THEY'LL MAKE", "Medium", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_make = UI.label(_make_box, Rect2(14, 32, iw - 28, 30), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_make_sub = UI.label(_make_box, Rect2(14, 62, iw - 28, 22), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_make_sub2 = UI.label(_make_box, Rect2(14, 84, iw - 28, 22), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_decrypt = UI.button(_decoder_box, Rect2(14, my + MAKE_H + 14, iw, 56), true)
	_decrypt.text = "Decrypt"
	_decrypt.pressed.connect(_on_decrypt)
	_decrypt_note = UI.label(_decoder_box, Rect2(14, my + MAKE_H + 14 + 62, iw, 26), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, false)
	# Kev's pile (16 Oct, Matt's playtest: two plain papers and a story piece, and no signal from either)
	var ky: float = my + MAKE_H + 14 + 62 + 30
	_kev_box = UI.panel(_decoder_box, Rect2(14, ky, iw, KEV_H), UI.box(Pal.CARD, 7, 1, Pal.CARD_LINE))
	_kev_head = UI.label(_kev_box, Rect2(12, 6, iw - 24, 20), "KEV'S PILE · PLAIN PAPERS ONLY", "Medium", Pal.CELL_TEXT - 3, KEV, HORIZONTAL_ALIGNMENT_LEFT, false)
	_kev_line = UI.label(_kev_box, Rect2(12, 26, iw - 24, 22), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_kev = UI.button(_kev_box, Rect2(12, 52, iw - 24, 36), false)
	_kev.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 1)
	_kev.pressed.connect(_on_kev)


func _build_signals() -> void:
	_signals_box = UI.panel(self, Rect2(SIGNALS_X, BODY_Y, SIGNALS_W, BODY_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var iw: float = SIGNALS_W - 2 * 14
	_signals_title = UI.label(_signals_box, Rect2(14, 10, iw, 26), "", "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_card = UI.panel(_signals_box, Rect2(14, 46, iw, CARD_H), UI.box(Pal.CARD, 8, 2, Pal.ACCENT))
	var cw: float = iw - 2 * 16
	_card_kicker = UI.label(_card, Rect2(16, 10, cw - 150, 22), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_card_title = UI.label(_card, Rect2(16, 32, cw - 150, 40), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_card_line = UI.label(_card, Rect2(16, 74, cw, 26), "", "Regular", Pal.CELL_TEXT, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_card_odds = UI.label(_card, Rect2(16 + cw - 150, 26, 150, 40), "", "SemiBold", Pal.TITLE, Pal.GOOD, HORIZONTAL_ALIGNMENT_RIGHT)
	_card_odds_sub = UI.label(_card, Rect2(16 + cw - 150, 62, 150, 20), "", "Regular", Pal.CELL_TEXT - 4, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_card_tiles = UI.tile_row(_card, 16, 108, cw, 3)
	_card_codes = Chips.new(cw, 8)
	_card_codes.position = Vector2(16, 180)
	_card.add_child(_card_codes)
	_card_kev = UI.label(_card, Rect2(16, 258, cw, 24), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_card_kev2 = UI.label(_card, Rect2(16, 282, cw, 24), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var n: int = SIM_CRAFTS.size()
	var crw: float = (cw - (n - 1) * 8) / n
	for k in range(n):
		var b := Button.new()
		b.position = Vector2(16 + k * (crw + 8), 318)
		b.size = Vector2(crw, CRAFT_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_craft.bind(SIM_CRAFTS[k]))
		_card.add_child(b)
		UI.style_button(b, false)
		var t := {"button": b, "key": SIM_CRAFTS[k]}
		t["name"] = UI.label(b, Rect2(10, 2, crw - 20, 24), "", "SemiBold", Pal.CELL_TEXT - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		t["words"] = UI.label(b, Rect2(10, 24, crw - 20, 22), "", "Regular", Pal.CELL_TEXT - 4, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		_crafts.append(t)
	var bw: float = (cw - 8) / 3.0
	_set_off = UI.button(_card, Rect2(16, 380, bw * 2, 56), true)
	_set_off.text = "Set off"
	_set_off.pressed.connect(_on_set_off)
	_bin = UI.button(_card, Rect2(16 + bw * 2 + 8, 380, bw, 56), false)
	_bin.text = "Bin it"
	_bin.pressed.connect(_on_bin)
	_build_dec(cw)
	_empty = UI.label(_signals_box, Rect2(28, 60, iw - 28, 28), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_empty2 = UI.label(_signals_box, Rect2(28, 88, iw - 28, 28), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(OTHERS_MAX):
		var b := Button.new()
		b.position = Vector2(14, 46 + CARD_H + 12 + k * (OTHER_H + 8))
		b.size = Vector2(iw, OTHER_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick_other.bind(k))
		_signals_box.add_child(b)
		var o := {"button": b, "k": -1}
		o["name"] = UI.label(b, Rect2(14, 6, iw - 150, 28), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		o["line"] = UI.label(b, Rect2(14, 36, iw - 150, 24), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		o["odds"] = UI.label(b, Rect2(iw - 130, 18, 116, 32), "", "SemiBold", Pal.CELL_TEXT_BIG + 4, Pal.GOOD, HORIZONTAL_ALIGNMENT_RIGHT)
		_others.append(o)


const SIM_CRAFTS := ["tune", "retune", "twist"]


## The decrypt's panel over the card: the frequency tuning, a meter, the card's lines resolving left to right out of
## the radio line's glyphs, a scan line down it.
func _build_dec(cw: float) -> void:
	_dec = UI.panel(_card, Rect2(0, 0, _card.size.x, _card.size.y), UI.box(Pal.CARD, 8, 2, Pal.ACCENT))
	_dec.mouse_filter = Control.MOUSE_FILTER_STOP
	_dec.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			end_decrypt())
	_dec.clip_contents = true
	_dec_dot = UI.panel(_dec, Rect2(16, 19, 10, 10), UI.box(BITE, 5))
	_dec_freq = UI.label(_dec, Rect2(36, 10, cw - 160, 28), "", "Medium", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT)
	for k in range(DEC_BARS):
		_dec_bars.append(UI.panel(_dec, Rect2(16 + cw - DEC_BARS * 7 + k * 7, 14, 4, 4), UI.box(Pal.CARD_LINE, 1)))
	UI.panel(_dec, Rect2(16, 46, cw, 1), UI.box(Pal.CARD_LINE, 0))
	var rows := [[62, 22, "Medium", Pal.CELL_TEXT - 2], [88, 40, "SemiBold", Pal.TITLE], [140, 28, "Medium", Pal.CELL_TEXT], [176, 28, "Medium", Pal.CELL_TEXT], [222, 26, "Regular", Pal.CELL_TEXT - 1]]
	for r in rows:
		_dec_lines.append([UI.label(_dec, Rect2(16, r[0], cw, r[1]), "", r[2], r[3], Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false), "", 0.0, 1.0, Pal.TEXT])
	_dec_scan = UI.panel(_dec, Rect2(0, 0, _card.size.x, 2), UI.box(Color(Pal.ACCENT, 0.35), 0))
	_dec.visible = false
	set_process(false)


## Starts the decrypt on the signal just made: what its card will say, each line given its moment to come through.
func start_decrypt(sg: Dictionary) -> void:
	var site: String = str(Data.TIERS[int(sg["site"])]["name"])
	var lv: int = sim.signal_level(sg)
	var crew: String = "The %s crew" % str(Data.ZONES[int(sg["zone"])]["name"]).replace("The ", "")
	if bool(sg.get("head", false)):
		crew += ", and their head at full strength"
	var names: Array = sim.signal_words(sg).map(func(x): return str(x["w"]))
	var beat: int = int(sg.get("story", -1))
	var texts := ["KEV'S STORY · A FIX ON" if beat >= 0 else "A FIX ON", site, "Level %d" % lv, crew,
		("Codes: " + ", ".join(names)) if not names.is_empty() else "No codes: a plain fix"]
	var times := [[0.3, 0.7], [0.6, 1.2], [1.0, 1.7], [1.5, 2.1], [1.8, 2.45]]
	var colours := [STORY if beat >= 0 else Pal.TEXT_2, Pal.TEXT, Pal.ACCENT, BITE if bool(sg.get("head", false)) else Pal.TEXT_2, PAY if not names.is_empty() else Pal.TEXT_3]
	for k in range(_dec_lines.size()):
		var row: Array = _dec_lines[k]
		var l: Label = row[0]
		UI.fit(l, [texts[k], texts[k].get_slice(",", 0)])
		row[1] = l.text
		row[2] = float(times[k][0])
		row[3] = float(times[k][1])
		row[4] = colours[k]
	_dec_t = 0.0
	_dec_heard = 0
	_dec_done = 0
	_dec_tick_t = 0.0
	_dec.visible = true
	set_process(true)
	_paint_dec()


## The decrypt's frame at `_dec_t`: a line before its moment flickers grey glyphs, then resolves left to right in its
## colour; the meter jumps, the frequency hunts, the dot blinks, the scan goes down the card.
func _paint_dec() -> void:
	var tick: int = int(_dec_t / 0.045)
	var g: String = RadioLine.GARBLE_GLYPHS
	for k in range(_dec_lines.size()):
		var row: Array = _dec_lines[k]
		var text: String = row[1]
		var p: float = clampf((_dec_t - float(row[2])) / maxf(0.01, float(row[3]) - float(row[2])), 0.0, 1.0)
		var n: int = int(text.length() * p)
		var out := ""
		for i in range(text.length()):
			var ch := text[i]
			out += ch if (ch == " " or i < n) else g[(i * 11 + tick * 7 + k * 5) % g.length()]
		row[0].text = out
		row[0].add_theme_color_override("font_color", row[4] if _dec_t >= float(row[3]) else Pal.TEXT_3)
	for k in range(_dec_bars.size()):
		var h: float = 4.0 + float((k * 37 + tick * 13) % 18)
		_dec_bars[k].position.y = 36.0 - h
		_dec_bars[k].size.y = h
	_dec_freq.text = "TUNING %.2f MHz" % (27.2 + float((tick * 17) % 90) / 100.0)
	_dec_dot.visible = tick % 6 < 3
	_dec_scan.position.y = _dec_t / DEC_S * _card.size.y
	_dec_sound()


## The decrypt's ticks (17 Oct, Matt: sound in engine): a glyph locking in, at most one a 0.06 s; a line done, its code.
func _dec_sound() -> void:
	var locked := 0
	var done := 0
	for row in _dec_lines:
		var p: float = clampf((_dec_t - float(row[2])) / maxf(0.01, float(row[3]) - float(row[2])), 0.0, 1.0)
		locked += int(str(row[1]).length() * p)
		if _dec_t >= float(row[3]):
			done += 1
	if done > _dec_done:
		if sound != null:
			sound.decrypt_tick(true)
		_dec_heard = locked
		_dec_tick_t = _dec_t
	elif locked > _dec_heard and _dec_t - _dec_tick_t >= 0.06:
		if sound != null:
			sound.decrypt_tick(false)
		_dec_heard = locked
		_dec_tick_t = _dec_t
	_dec_done = done


## Done, or skipped: the card is the signal's, as it always was.
func end_decrypt() -> void:
	if _dec_t < 0.0:
		return
	_dec_t = -1.0
	_dec.visible = false
	set_process(false)
	_shown = ""
	if sim != null:
		show_state(sim)


func decrypting() -> bool:
	return _dec_t >= 0.0


func _process(delta: float) -> void:
	if _dec_t < 0.0:
		return
	if not (visible and _air.visible):
		end_decrypt()                 # the room left, or the Dial opened: the card is the signal's
		return
	_dec_t += delta
	if _dec_t >= DEC_S:
		end_decrypt()
		return
	_paint_dec()


func show_state(s) -> void:
	sim = s
	if view != "air" and not sim.campaign_done():
		view = "air"
	_views[0].text = "The air"
	_views[1].text = "The Dial" if sim.campaign_done() else "The Dial · locked"
	_views[1].disabled = not sim.campaign_done()
	_views[2].text = "The town" if sim.campaign_done() else "The town · locked"     # the rebuild (18 Oct): its cards read shut till Kev's story is done
	_views[2].disabled = not sim.campaign_done()
	_views[3].text = "The story" if sim.campaign_done() else "The story · locked"
	_views[3].disabled = not sim.campaign_done()
	for k in range(VIEWS.size()):
		UI.style_button(_views[k], view == VIEWS[k])
	_air.visible = view == "air"
	_atlas.visible = view == "map"
	_town.visible = view == "town"
	_story.visible = view == "story"
	if view == "story":
		_shown = ""
		_story.show_state(sim)
		return
	if view == "map":
		_shown = ""
		_atlas.show_state(sim)
		return
	if view == "town":
		_shown = ""
		_town.show_state(sim)
		return
	var have: Array = sim.signal_papers().map(func(x): return int(x["id"]))
	chosen = chosen.filter(func(id): return int(id) in have)
	selected = clampi(selected, 0, maxi(0, sim.signals.size() - 1))
	var od: Array = sim.signal_odds_now(selected) if not sim.signals.is_empty() else [0.0, true]     # read in main's frame budget
	var sig := "%s|%s|%d|%d|%d|%d|%s|%s|%d|%s|%s|%s|%d|%s|%s" % [str(chosen), str(have), paper_page, selected, sim.notes, sim.reach, str(sim.signals), str(sim.on_mission()), int(float(od[0]) * 100.0), str(od[1]),
		str(sim.standing), sim.filtered, sim.heard.size(), str(sim.campaign_done()), str(sim.atlas)]
	if sig == _shown:
		return
	_shown = sig
	var on_air: bool = sim.campaign_done()
	UI.fit(_kicker, ["Radio · on the air" if on_air else "Radio · nothing on the air", "Radio"])     # the rail's name (18 Oct, Q10)
	_headline.text = ("Level %d" % sim.reach) if on_air else "Quiet"
	_unit.position.x = PAD + ceilf(UI.text_width(_headline, _headline.text)) + 10
	_unit.size.x = 440 - _unit.position.x
	UI.fit(_unit, ["your reach", ""] if on_air else ["till the Quartermaster", ""])
	UI.fit(_sub, ["Beat a signal at your reach to raise it by 1", "Beat one at it: +1", ""] if on_air else ["", ""])
	_chips.show_chips([{"tag": "Kev's story", "forms": ["%d of %d" % [mini(sim.story_beat, Data.STORY_BEATS.size()), Data.STORY_BEATS.size()]], "colour": STORY}], 1)
	_chips.visible = on_air
	_show_heard()
	for b in [_papers_box, _decoder_box, _signals_box]:
		b.visible = on_air
	var quiet: Array = Words.RADIO_QUIET if not on_air else []
	for k in range(_quiet.size()):
		_quiet[k].visible = k < quiet.size()
		if _quiet[k].visible:
			UI.fit(_quiet[k], [str(quiet[k]), ""])
	if not on_air:
		return
	_show_papers()
	_show_decoder()
	_show_signals(od)


## The last line the radio said, on its pill; nothing before the first.
func _show_heard() -> void:
	var line := ""
	if not sim.heard.is_empty():
		var r: Dictionary = sim.radio_line(str(sim.heard.back()))
		line = str(r.get("text", ""))
	UI.fit(_heard, [line, line.get_slice(". ", 0) + ("." if line.contains(". ") else ""), ""] if line != "" else [""])
	_heard_pill.visible = _heard.text != ""
	if _heard_pill.visible:
		var w: float = ceilf(UI.text_width(_heard, _heard.text)) + 24.0
		_heard_pill.position.x = _heard.position.x + _heard.size.x + 12.0 - w
		_heard_pill.size.x = w


## A paper's code in a line, its forms long to short: its bite and its pay at the reach's tier, or why it has none.
func code_words(base: String) -> Array:
	var code: String = sim.word_taught_by(base)
	if code == "":
		return [["No code: a line of the before", "No code"], Pal.TEXT_3]
	var w: Array = sim.word_words(code, maxi(1, sim.word_tier_cap(sim.tier_depth(sim.reach))))     # [the bite, the pay] (D3: the reach is a level)
	var bite: String = str(w[0])
	var pay: String = str(w[1])
	var forms: Array = []
	if bite != "" and pay != "":
		forms.append("%s · %s · %s" % [code, bite, pay])
		forms.append("%s · %s · %s" % [code, bite, pay.get_slice(", ", 0)])
	if bite != "":
		forms.append("%s · %s" % [code, bite])
	if pay != "":
		forms.append("%s · %s" % [code, pay.get_slice(", ", 0)])
	forms.append(code)
	return [forms, Pal.TEXT_2]


func _show_papers() -> void:
	var papers: Array = sim.signal_papers()
	var pages: int = maxi(1, ceili(float(papers.size()) / PAPERS_MAX))
	paper_page = clampi(paper_page, 0, pages - 1)
	UI.fit(_papers_title, ["THE PAPERS · %d" % papers.size()])
	# the two kinds, each with its count of the three (16 Oct): a story piece never hides that the plain ones are short
	var plain: int = papers.filter(func(x): return sim.story_of(x) < 0).size()
	var story: int = sim.story_held().size()
	var kinds: String = "Plain %d%s" % [plain, (" · Kev's story %d of 3" % story) if story > 0 else ""]
	UI.fit(_papers_sub, [kinds + " · pick one to three", kinds, "Plain %d" % plain] if not papers.is_empty() else ["None held: they're found searching, or off Kev's pile", "None held", ""])
	for k in range(PAPERS_MAX):
		var r: Dictionary = _paper_rows[k]
		var n: int = paper_page * PAPERS_MAX + k
		r["button"].visible = n < papers.size()
		if not r["button"].visible:
			r["id"] = -1
			continue
		var it: Dictionary = papers[n]
		r["id"] = int(it["id"])
		var rare: bool = int(it.get("rarity", 0)) >= Data.PAPER_DEEPER_AT
		UI.fit(r["name"], [str(it["base"]) + (" · rare" if rare else "")])
		r["name"].add_theme_color_override("font_color", Pal.tone_color(Pal.item_tone(it)) if int(it.get("rarity", 0)) > 0 else Pal.TEXT)
		var beat: int = sim.story_of(it)
		if beat >= 0:
			var bn: String = str(Data.STORY_BEATS[beat]["name"]).to_lower()
			UI.fit(r["code"], ["Kev's story · %s · %d of 3 found" % [bn, sim.story_held().size()] if beat == sim.story_now() else "Kev's story · %s" % bn, "Kev's story"])
			r["code"].add_theme_color_override("font_color", STORY)
		else:
			var cw: Array = code_words(str(it["base"]))
			UI.fit(r["code"], ([str(cw[0][0]) + " · one deeper"] if rare else []) + cw[0])
			r["code"].add_theme_color_override("font_color", cw[1])
		var on: bool = int(it["id"]) in chosen
		r["badge"].visible = on or beat >= 0
		r["badge"].text = "IN" if on else "STORY"
		r["badge"].size.x = 34 if on else 62
		r["badge"].position.x = r["button"].size.x - 12 - r["badge"].size.x
		r["badge"].add_theme_color_override("font_color", Pal.ACCENT if on else STORY)
		r["badge"].add_theme_stylebox_override("normal", UI.box(Pal.BG, 4, 1, Pal.ACCENT if on else STORY))
		var edge: Color = Pal.ACCENT if on else (STORY if beat >= 0 else Pal.CARD_LINE)
		r["button"].add_theme_stylebox_override("normal", UI.box(Pal.CARD, 7, 2 if on else 1, edge))
		r["button"].add_theme_stylebox_override("hover", UI.box(Pal.BUTTON, 7, 2 if on else 1, edge))
	_paper_prev.visible = pages > 1
	_paper_next.visible = pages > 1
	_paper_page.visible = pages > 1
	_paper_page.text = "%d/%d" % [paper_page + 1, pages]
	_paper_prev.disabled = paper_page == 0
	_paper_next.disabled = paper_page >= pages - 1
	for k in range(2):
		var b: Button = _stand[k]
		b.visible = sim.standing_open(k)
		var sw: String = str(sim.standing[k]) if k < sim.standing.size() else ""
		if b.visible:
			UI.fit_button(b, ["Standing: %s" % (sw if sw != "" else "none"), sw if sw != "" else "Standing"])
	_filter.visible = sim.atlas_rank("clear_air") > 0
	if _filter.visible:
		UI.fit_button(_filter, ["Filter: %s" % sim.filtered, "✕ %s" % sim.filtered, "✕ " + sim.filtered.get_slice(" ", 0)] if sim.filtered != "" else ["Filter: none", "Filter"])


func _show_decoder() -> void:
	for k in range(_slots.size()):
		var sl: Dictionary = _slots[k]
		var it: Dictionary = _paper(chosen[k]) if k < chosen.size() else {}
		var on: bool = not it.is_empty()
		(sl["panel"] as Panel).add_theme_stylebox_override("panel", UI.box(Pal.BG, 7, 2 if on else 1, Pal.ACCENT if on else Pal.CARD_LINE))
		var spare: bool = not on and k > 0 and k >= chosen.size() and not chosen.is_empty() and sim.story_of(_paper(chosen[0])) < 0     # 20 Oct: one paper makes a signal, more make it stronger
		sl["n"].text = "%d · optional" % (k + 1) if spare else "%d" % (k + 1)
		UI.fit(sl["name"], [str(it["base"]) + (" · rare" if int(it.get("rarity", 0)) >= Data.PAPER_DEEPER_AT else "")] if on else ([SPARE_NAME[k]] if spare else ["A paper from the left"]))
		sl["name"].add_theme_color_override("font_color", Pal.TEXT if on else Pal.TEXT_3)
		var more: Dictionary = sim.signal_grade(k + 1)
		var cw: Array = code_words(str(it["base"])) if on else ([["%s signal, room for %d codes" % [more["name"], int(more["codes"])], "Room for %d codes" % int(more["codes"])], Pal.TEXT_3] if spare else [[""], Pal.TEXT_3])
		if on and sim.story_of(it) >= 0:
			cw = [["Kev's story · %s" % str(Data.STORY_BEATS[sim.story_of(it)]["name"]).to_lower(), "Kev's story"], STORY]
		UI.fit(sl["code"], cw[0])
	var band: Array = sim.signal_band(chosen)
	var gr: Dictionary = sim.signal_grade(chosen.size())
	UI.fit(_make_head, ["%s · %s" % ["WHAT IT'LL MAKE" if chosen.size() == 1 else "WHAT THEY'LL MAKE", str(gr["name"]).to_upper()], str(gr["name"]).to_upper()] if not chosen.is_empty() else ["WHAT THEY'LL MAKE"])
	UI.fit(_make, ["A signal at level %d–%d" % [band[0], band[1]], "Level %d–%d" % [band[0], band[1]]])
	if chosen.is_empty():
		UI.wrap([_make_sub, _make_sub2], "One to three papers make a signal: more make it stronger, a rare one rolls it higher")
	else:
		var most: int = sim.signal_codes_most(chosen)
		var ex: float = float(gr["extras"])
		var extras: String = "no head, no convoy" if ex <= 0.0 else ("head or convoy as before" if ex >= 1.0 else "head or convoy, half as often")
		UI.fit(_make_sub, ["Up to %d code%s · %s" % [most, "" if most == 1 else "s", extras], "Up to %d code%s" % [most, "" if most == 1 else "s"]])
		var r: int = sim.reach
		var never: bool = int(gr["papers"]) == 1 or int(band[1]) < r     # a faint win never moves the reach (20 Oct)
		UI.fit(_make_sub2, ["Never moves your reach (%d)" % r if never else "A win at your reach (%d) or past moves it" % r, "Reach %d" % r])
	var why: String = sim.decrypt_block(chosen)
	_decrypt.disabled = why != "" and not decrypting()
	_decrypt.text = "Skip" if decrypting() else ("Decrypt · %d paper%s" % [chosen.size(), "" if chosen.size() == 1 else "s"] if not chosen.is_empty() else "Decrypt")     # a tap mid-decrypt goes to the end (item 20)
	var room: int = Data.SIGNALS_HELD - sim.signals.size()
	var note: String = ("Decrypting spends the paper%s · %d more signal%s can be held" % ["" if chosen.size() == 1 else "s", room, "" if room == 1 else "s"]) if why == "" or why == sim.DECRYPT_NEEDS_PAPERS else why.substr(0, 1).to_upper() + why.substr(1)
	UI.fit(_decrypt_note, [note, ""])
	var kb: String = sim.kev_block()
	UI.fit(_kev_line, [Words.KEV_PILE, "\"Bring me notes and I'll see what's in the pile.\"", ""])
	_kev.disabled = kb != ""
	var price: int = sim.kev_price()
	if kb == "" or kb == "%d notes" % price:
		UI.fit_button(_kev, ["Ask Kev · %d notes" % price, "Ask Kev"])
	else:
		UI.fit_button(_kev, ["Ask Kev · %s" % kb, "Ask Kev"])


func _show_signals(od: Array) -> void:
	var n: int = sim.signals.size()
	UI.fit(_signals_title, ["SIGNALS · %d OF %d HELD" % [n, Data.SIGNALS_HELD]])
	_card.visible = n > 0
	_empty.visible = n == 0
	_empty2.visible = n == 0
	if n == 0:
		UI.wrap([_empty, _empty2], "No signals held. One to three papers in the decoder make one: a fix on a site, a crew from anywhere, run once.")     # 20 Oct: one to three; "campaign" a banned word on screen
		for o in _others:
			o["button"].visible = false
		return
	var sg: Dictionary = sim.signal_at(selected)
	var e: Dictionary = sim.signal_read(selected)
	var site: String = str(Data.TIERS[int(sg["site"])]["name"])
	var beat: int = int(sg.get("story", -1))
	if beat >= 0:
		UI.fit(_card_kicker, ["Kev's story · %s · a fix on %s" % [Data.STORY_BEATS[beat]["name"], Words.mid(site)], "Kev's story · %s" % Data.STORY_BEATS[beat]["name"]])
	else:
		UI.fit(_card_kicker, ["Signal %02d · a fix on %s" % [int(sg["id"]), Words.mid(site)], "Signal %02d" % int(sg["id"])])
	UI.fit(_card_title, [site])
	var lv: int = sim.signal_level(sg)
	var rel: String = "at your reach" if lv == sim.reach else (("%d over your reach" % (lv - sim.reach)) if lv > sim.reach else ("%d under your reach" % (sim.reach - lv)))
	var crew: String = "the %s crew" % str(Data.ZONES[int(sg["zone"])]["name"]).replace("The ", "")
	UI.fit(_card_line, ["Level %d · %s · %s" % [lv, rel, crew], "Level %d · %s" % [lv, crew], "Level %d" % lv])
	_card_odds.text = Fmt.pct(float(od[0]))
	var tone: String = "good" if float(od[0]) >= 0.9 else ("warn" if float(od[0]) >= 0.6 else "bad")
	_card_odds.add_theme_color_override("font_color", Pal.tone_color(tone) if od[1] else Pal.TEXT_3)
	UI.fit(_card_odds_sub, ["to clear, events counted" if od[1] else "reading the odds", "to clear"])
	UI.set_tile(_card_tiles[0], "Gang", ["%d × %s HP" % [int(e["pool"]), Fmt.num(float(e["hp"]))], "%d × %s" % [int(e["pool"]), Fmt.num(float(e["hp"]))]])
	UI.set_tile(_card_tiles[1], "Their fire", ["%.1f dmg/s each" % float(e["dps"]), "%.1f/s" % float(e["dps"])])
	UI.set_tile(_card_tiles[2], "Gear level", sim.finds_words(int(e["level"])))
	var chips: Array = []
	for wd in sim.signal_words(sg):
		var parts: Array = sim.word_words(str(wd["w"]), int(wd["t"]))     # [the bite, the pay]
		chips.append({"forms": ["%s: %s" % [wd["w"], parts[0]] if str(parts[0]) != "" else str(wd["w"]), str(wd["w"])], "colour": BITE})
		if str(parts[1]) != "":
			chips.append({"forms": [str(parts[1]), str(parts[1]).get_slice(", ", 0)], "colour": PAY})
	if bool(sg.get("head", false)):
		chips.append({"forms": ["Extra: %s at full strength" % sim.zone_boss(int(sg["zone"])).get("name", "their head"), "Extra: a head"], "colour": Pal.WARN})
	if bool(sg.get("convoy_fight", false)):
		chips.append({"forms": ["The convoy: three heads, one after another, and the load", "The convoy"], "colour": Pal.WARN})
	if bool(sg.get("convoy", false)):
		chips.append({"forms": ["Extra: a convoy may come", "Extra: a convoy"], "colour": Pal.WARN})
	if bool(sg.get("sealed", false)):
		chips.append({"forms": ["Sealed", "Sealed"], "colour": Pal.TEXT_3})
	if chips.is_empty():
		chips.append({"forms": ["No codes: a plain fix", "No codes"], "colour": Pal.TEXT_3})
	if beat >= 0:
		chips.push_front({"forms": ["Kev's story: %s" % Data.STORY_BEATS[beat]["name"], "Kev's story"], "colour": STORY})
	_card_codes.show_chips(chips, 3, true)
	if beat >= 0:
		UI.wrap([_card_kev, _card_kev2], str(Words.STORY[beat]["made"]).replace("Kev: ", "KEV ·"))
	else:
		UI.wrap([_card_kev, _card_kev2], "KEV · \"%s\"" % str(Words.SIGNAL_LINES[int(sg["line"]) % Words.SIGNAL_LINES.size()]))
	for c in _crafts:
		var cd: Dictionary = Data.craft_of(c["key"])
		var why: String = sim.signal_craft_block(selected, c["key"])
		c["button"].disabled = why != ""
		UI.fit(c["name"], ["%s · %d notes" % [cd["name"], sim.signal_craft_cost(selected, c["key"])], str(cd["name"])])
		UI.fit(c["words"], [str(cd["words"]).replace("the site", "it"), ""] if why == "" else [why, ""])
	_set_off.disabled = not sim.can_deploy() or sim.on_mission()
	var k := 0
	for j in range(n):
		if j == selected or k >= OTHERS_MAX:
			continue
		var o: Dictionary = _others[k]
		var og: Dictionary = sim.signal_at(j)
		o["k"] = j
		o["button"].visible = true
		UI.fit(o["name"], ["%s · level %d · the %s crew" % [Data.TIERS[int(og["site"])]["name"], sim.signal_level(og), str(Data.ZONES[int(og["zone"])]["name"]).replace("The ", "")], "%s · level %d" % [Data.TIERS[int(og["site"])]["name"], sim.signal_level(og)]])
		var names: Array = sim.signal_words(og).map(func(x): return str(x["w"]))
		var extra: String = (" · a head at full strength" if bool(og.get("head", false)) else "") + (" · a convoy may come" if bool(og.get("convoy", false)) else "")
		UI.fit(o["line"], [(", ".join(names) if not names.is_empty() else "no codes") + extra, ", ".join(names) if not names.is_empty() else "no codes"])
		o["odds"].text = ""
		k += 1
	while k < OTHERS_MAX:
		_others[k]["button"].visible = false
		_others[k]["k"] = -1
		k += 1


func _paper(id: int) -> Dictionary:
	for it in sim.signal_papers():
		if int(it["id"]) == id:
			return it
	return {}


# ------------------------------------------------------------------ acting

func _toggle_paper(k: int) -> void:
	var id: int = int(_paper_rows[k]["id"])
	if id < 0:
		return
	if id in chosen:
		chosen.erase(id)
	elif chosen.size() < Data.SIGNAL_PAPERS:
		chosen.append(id)
	_shown = ""
	acted.emit()


func _turn(by: int) -> void:
	paper_page += by
	_shown = ""
	acted.emit()


func _on_decrypt() -> void:
	if decrypting():
		end_decrypt()
		acted.emit()
		return
	var sg: Dictionary = sim.decrypt(chosen)
	if not sg.is_empty():
		chosen = []
		selected = sim.signals.size() - 1
		start_decrypt(sim.signal_at(selected))
	_shown = ""
	acted.emit()


func _on_kev() -> void:
	sim.ask_kev()
	_shown = ""
	acted.emit()


func _on_set_off() -> void:
	if sim.deploy_signal(selected):
		selected = 0
	_shown = ""
	acted.emit()


func _on_bin() -> void:
	sim.bin_signal(selected)
	_shown = ""
	acted.emit()


func _craft(key: String) -> void:
	sim.signal_craft(selected, key)
	_shown = ""
	acted.emit()


func _pick_other(k: int) -> void:
	end_decrypt()                         # another signal picked mid-decrypt: the decrypt's done (the review)
	if int(_others[k]["k"]) >= 0:
		selected = int(_others[k]["k"])
	_shown = ""
	acted.emit()


## For the smoke: a paper's row, the decoder's button, the card's buttons.
func paper_row(k: int) -> Dictionary:
	return _paper_rows[k]


func craft_button(key: String) -> Button:
	for c in _crafts:
		if c["key"] == key:
			return c["button"]
	return null


## The air or the map (12 Oct): the map once the campaign's done.
func _pick_view(v: String) -> void:
	if v != "air" and not sim.campaign_done():
		return
	view = v
	_shown = ""
	show_state(sim)
	acted.emit()


func _reset_map() -> void:
	_atlas._on_reset()


func text_nodes() -> Array:
	if view == "map":
		return _views + _atlas.text_nodes()
	if view == "town":
		return _views + _town.text_nodes()
	if view == "story":
		return _views + _story.text_nodes()
	var out: Array = [_kicker, _headline, _unit, _sub, _heard] + _views
	out.append_array(_chips.text_nodes())
	for l in _quiet:
		if l.visible:
			out.append(l)
	if not _papers_box.visible:
		return out
	out.append_array([_papers_title, _papers_sub, _decoder_title, _make_head, _make, _make_sub, _make_sub2, _decrypt_note, _signals_title, _kev_head, _kev_line, _kev])
	for r in _paper_rows:
		if r["button"].visible:
			out.append_array([r["name"], r["code"]])
	for sl in _slots:
		out.append_array([sl["name"], sl["code"]])
	if _paper_page.visible:
		out.append(_paper_page)
	for b in _stand + [_filter]:
		if b.visible:
			out.append(b)
	if _card.visible:
		out.append_array([_card_kicker, _card_title, _card_line, _card_odds, _card_odds_sub, _card_kev, _card_kev2])
		for t in _card_tiles:
			out.append_array([t["key"], t["value"]])
		out.append_array(_card_codes.text_nodes())
		for c in _crafts:
			out.append_array([c["name"], c["words"]])
	for o in _others:
		if o["button"].visible:
			out.append_array([o["name"], o["line"]])
	if _empty.visible:
		out.append_array([_empty, _empty2])
	return out


func line_pairs() -> Array:
	if view == "map":
		return []
	if view == "town":
		return _town.line_pairs()
	if view == "story":
		return _story.line_pairs()
	return [[_headline, _unit]]
