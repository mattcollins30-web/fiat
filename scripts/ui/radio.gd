extends Control
## The Radio as the endgame (15 Oct, docs/design/endgame_radio.md, mockup signals_radio.png; Matt: "the endgame is
## the wrong way round"). Three papers in, a signal out: one mission on a campaign site at random, a crew from any
## zone, a depth rolled round your reach, each paper's code on it. The Dial, the endgame's tree, in the band's other
## view. Before the Quartermaster: nothing on the air.
##
## Laid out as the mockup RadioAir (28 Oct, Matt: "the Radio looks crap"): a tab bar at the band's right; two columns.
## Down the left (about two thirds) the papers as a shelf of cards, four across and paged, Kev's pile under them; the
## decoder as one row, three slots, an arrow and what they'll make, the crew and Decrypt under it; the standing codes
## and the filter at the foot. On the right the signals: the picked one as the full card, the others held as rows
## that pick, and the empty ones as fixed dashed slots - three places, always.
##
## The code book (21 Oct, canvas "The code book and the death pick" 1): pressing a standing code or the filter opens
## the book over the shelf, the decoder and the signals, every known code a card with its cost and its pay, the rest
## scrambled, and what's still to learn. Done, or a code picked, or the slot again, puts them back.
##
## Signals: `acted` after anything changes.

signal acted

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
const Dashed := preload("res://scripts/ui/dashed.gd")
const WagersPanel := preload("res://scripts/ui/wagers_panel.gd")

const PAD := 20
const HEAD_H := Pal.BAND_H
const BODY_Y := HEAD_H + 8
const BODY_H := Pal.ROOM_H - BODY_Y
const COL_GAP := 12
const BP := 14                      # a box's padding
# the two columns (28 Oct, RadioAir): the papers, the decoder and the codes down the left; the signals on the right
const SIGNALS_W := 512
const LEFT_W := Pal.GRID_W - SIGNALS_W - COL_GAP
const SIGNALS_X := LEFT_W + COL_GAP
const LEFT_IW := LEFT_W - 2 * BP
# down the left: the shelf, the decoder, the standing codes, each a box under the one before
const PAPERS_Y := BODY_Y
const SHELF_COLS := 4
const SHELF_ROWS := 2
const PAPERS_MAX := SHELF_COLS * SHELF_ROWS     # a page of them; ‹ › past that
const PAPER_H := 74
const PAPER_GAP := 10
const SHELF_TOP := 44
const KEV_Y := SHELF_TOP + SHELF_ROWS * (PAPER_H + PAPER_GAP) + 2     # Kev's pile, a row under the shelf
const KEV_H := 44
const PAPERS_H := KEV_Y + KEV_H + 12
const DECODER_Y := PAPERS_Y + PAPERS_H + COL_GAP
const SLOT_TOP := 44
const SLOT_H := 112
const SLOT_GAP := 8
const SLOT_W := 200
const ARROW_W := 40
const MAKE_X := BP + 3 * SLOT_W + 2 * SLOT_GAP + ARROW_W
const MAKE_W := LEFT_W - BP - MAKE_X
const CREW_Y := SLOT_TOP + SLOT_H + 14
const CREW_H := 48                  # the crew to call: any, or an area's for Kev's notes (20 Oct)
const CREW_W := 118
const NOTE_Y := CREW_Y + CREW_H + 4
const DECODER_H := NOTE_Y + 22 + 10
const STAND_Y := DECODER_Y + DECODER_H + COL_GAP
const STAND_H := Pal.ROOM_H - STAND_Y
const STAND_TOP := 46
const STAND_SLOT_H := 72            # a standing code's slot: what it is, the code
const STAND_GAP := 10
const BOOK_KINDS := ["standing0", "standing1", "filter"]
# the code book over the shelf, the decoder and the signals; the standing codes stay under it to shut it again
const BOOK_H := STAND_Y - COL_GAP - BODY_Y
const BOOK_COLS := 5
const BOOK_ROWS := 3
const BOOK_CARD_H := 110
const BOOK_GAP := 8
const BOOK_TOP := 92                # the cards under the title and the line
const LEARN_FROM := {"paper": "off papers", "zone": "in the zones", "deep": "deep"}
const LEARNT := {"paper": "Learnt off a paper", "zone": "Learnt in a zone", "deep": "Learnt off a deep paper"}
# the signals' column: the picked card, then the other two places - a held signal's row, or an empty dashed slot
const SIG_IW := SIGNALS_W - 2 * BP
const CARD_TOP := 42
const CREW_ROW_Y := 408              # the crew's odds (21 Oct): a button a class played, the one out first
const CREW_MAX := 6                 # every class played (24 Oct: the sixth, the Recruit, had no button); Data.CLASSES.size(), held by the smoke
const CREW_COLS := 3                # the card's narrower now: three a row, a second row for the rest (28 Oct)
const CREW_BH := 50
const CARD_H := CREW_ROW_Y + 2 * (CREW_BH + 6) + 4     # the picked signal at its tallest: every class in two rows
const CRAFT_H := 48
const OTHER_H := 56
const OTHER_GAP := 8
const OTHERS_MAX := 2
const PLACES := 3                   # Data.SIGNALS_HELD: the column's three places, held or empty (the smoke holds them equal)
# the tab bar (28 Oct, RadioAir): bigger, at the band's right, on its own dark strip so the painting can't swallow it
const VIEW_W := 152
const VIEW_H := 44
const VIEW_GAP := 8
const VIEW_Y := 30
const VIEWS_X := Pal.GRID_W - PAD - 4 * VIEW_W - 3 * VIEW_GAP
const HEARD_X := 470
const HEARD_Y := HEAD_H - 44
const BITE := Color("ee7663")
const SPARE_NAME := ["", "A second paper", "A third paper"]     # an empty slot past the first paper (20 Oct)
const KEV := Color("f0a868")        # Kev's voice's colour (the radio line's mockup, approved 16 Oct)
const STORY := Color("8fb3d9")      # Kev's story's papers and signals (the mockup's blue)
const PAY := Color("62bd8f")
const MATERIAL := Color("d6c27a")   # the materials' sand (20 Oct)

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
var _view_bar: Panel                # the tab bar's strip (28 Oct)
var _view_note: Label               # under it while the views are shut: what opens them
var _quiet: Array = []              # nothing on the air: the lines before the Quartermaster
# the papers
var _papers_box: Panel
var _papers_title: Label
var _papers_sub: Label
var _paper_rows: Array = []         # {button, name, code, id}
var _paper_more: Control            # the shelf's next place, dashed: where papers come from
var _paper_more_line: Label
var _paper_prev: Button
var _paper_next: Button
var _paper_page: Label
var _stand_box: Panel
var _stand_head: Label
var _stand_sub: Label
var _stand: Array = []              # the three slots, standing 1 and 2 and the filter: {button, top, name, kind}
# the code book, over the shelf, the decoder and the signals
var book_kind := ""                 # "" shut, else the slot it's open for (BOOK_KINDS)
var book_page := 0
var _book: Panel
var _book_title: Label
var _book_sub: Label
var _book_done: Button
var _book_cards: Array = []         # {button, name, on, chips, line, code}
var _book_left_head: Label
var _book_left: Chips
var _book_prev: Button
var _book_next: Button
var _book_pages: Label
# the decoder
var _decoder_box: Panel
var _decoder_title: Label
var _slots: Array = []              # {panel, dash, n, name, code}
var _arrow: Label
var _make_box: Panel
var _make_head: Label
var _make: Label
var _make_sub: Label
var _make_sub2: Label
var _crew_head: Label
var _decrypt: Button
var _crew_buttons: Array = []       # any crew, the Estate's, the Town's, the City's
var crew_pick := -1                 # the crew to call, -1 any
var _decrypt_note: Label
var _kev_box: Panel                 # Kev's pile (16 Oct): a plain paper for notes; a row under the shelf (28 Oct)
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
var _crew_btns: Array = []           # [{button, name, odds, cls}]
var _bin: Button
var _wager_btn: Button              # Kev's wagers on the signal's run (29 Oct), between Set off and Bin it
var _wagers_ov                      # their panel (wagers_panel.gd), over the papers and the decoder while open
var _empty: Label
var _empty2: Label
var _others: Array = []             # {button, name, line, odds}
var _places: Array = []             # the empty places, dashed: {box, name, line}
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
	_build_stand()
	_build_signals()
	_build_book()
	visibility_changed.connect(func():
		if not visible:
			book_kind = "")     # the room left with the book open: back to the decoder (the review)
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
	_wagers_ov = WagersPanel.new()
	_wagers_ov.position = Vector2(0, BODY_Y)
	_wagers_ov.acted.connect(func():
		_shown = ""
		acted.emit())
	_air.add_child(_wagers_ov)
	# the tab bar over every view's band (28 Oct, RadioAir: "not small buttons lost in the painting")
	_view_bar = UI.panel(self, Rect2(VIEWS_X - 6, VIEW_Y - 6, Pal.GRID_W - PAD - VIEWS_X + 12, VIEW_H + 12), UI.box(Color(Pal.BG, 0.86), 10, 1, Pal.CARD_LINE))
	for k in range(VIEWS.size()):
		var vb := UI.button(self, Rect2(VIEWS_X + k * (VIEW_W + VIEW_GAP), VIEW_Y, VIEW_W, VIEW_H), false)
		vb.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
		vb.pressed.connect(_pick_view.bind(VIEWS[k]))
		_views.append(vb)
	_view_note = UI.label(self, Rect2(VIEWS_X - 6, VIEW_Y + VIEW_H + 12, Pal.GRID_W - PAD - VIEWS_X + 12, 24), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	UI.shadow(_view_note)


## The papers as a shelf (28 Oct, Matt: "the Radio looks crap"; RadioAir): four across, two rows a page, each card a
## paper's name and its code under it; Kev's story's in the story blue, the picked ones edged; Kev's pile a row under.
func _build_papers() -> void:
	_papers_box = UI.panel(self, Rect2(0, PAPERS_Y, LEFT_W, PAPERS_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_papers_title = UI.label(_papers_box, Rect2(BP, 10, 260, 26), "", "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_papers_sub = UI.label(_papers_box, Rect2(BP + 270, 10, LEFT_IW - 270 - 170, 26), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	var cw: float = (LEFT_IW - (SHELF_COLS - 1) * PAPER_GAP) / float(SHELF_COLS)
	for k in range(PAPERS_MAX):
		var b := Button.new()
		@warning_ignore("integer_division")
		b.position = Vector2(BP + (k % SHELF_COLS) * (cw + PAPER_GAP), SHELF_TOP + (k / SHELF_COLS) * (PAPER_H + PAPER_GAP))
		b.size = Vector2(cw, PAPER_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_toggle_paper.bind(k))
		_papers_box.add_child(b)
		var r := {"button": b, "id": -1}
		r["name"] = UI.label(b, Rect2(12, 10, cw - 24, 28), "", "SemiBold", Pal.CELL_TEXT + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["code"] = UI.label(b, Rect2(12, 40, cw - 24, 24), "", "Regular", Pal.CELL_TEXT - 2, PAY, HORIZONTAL_ALIGNMENT_LEFT, false)
		_paper_rows.append(r)
	_paper_more = Dashed.new(Vector2(cw, PAPER_H))
	_papers_box.add_child(_paper_more)
	_paper_more_line = UI.label(_paper_more, Rect2(14, 0, cw - 28, PAPER_H), "Papers come off signals", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	# the pages at the title row's right
	var px: float = LEFT_W - BP - 44 - 56 - 44 - 8
	_paper_prev = UI.button(_papers_box, Rect2(px, 6, 44, 32), false)     # 44: the arrow needs 42 (16 Oct, the smoke with a page of 30)
	_paper_prev.text = "‹"
	_paper_prev.pressed.connect(func(): _turn(-1))
	_paper_page = UI.label(_papers_box, Rect2(px + 48, 6, 56, 32), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER, false)
	_paper_next = UI.button(_papers_box, Rect2(px + 108, 6, 44, 32), false)
	_paper_next.text = "›"
	_paper_next.pressed.connect(func(): _turn(1))
	# Kev's pile (16 Oct, Matt's playtest: two plain papers and a story piece, and no signal from either): a row under
	# the shelf, his words and his button (28 Oct, RadioAir)
	_kev_box = UI.panel(_papers_box, Rect2(BP, KEV_Y, LEFT_IW, KEV_H), UI.box(Pal.CARD, 7, 1, Pal.CARD_LINE))
	_kev_head = UI.label(_kev_box, Rect2(12, 0, 236, KEV_H), "KEV'S PILE · PLAIN PAPERS ONLY", "Medium", Pal.CELL_TEXT - 3, KEV, HORIZONTAL_ALIGNMENT_LEFT, false)
	_kev = UI.button(_kev_box, Rect2(LEFT_IW - 6 - 230, 5, 230, KEV_H - 10), false)
	_kev.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 1)
	_kev.pressed.connect(_on_kev)
	_kev_line = UI.label(_kev_box, Rect2(256, 0, LEFT_IW - 256 - 248, KEV_H), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)


## The Dial's standing codes and Clear air's filter (9 Oct): a box at the left column's foot (21 Oct, the canvas; 28 Oct,
## RadioAir: three side by side), each slot opening the code book.
func _build_stand() -> void:
	_stand_box = UI.panel(self, Rect2(0, STAND_Y, LEFT_W, STAND_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_stand_head = UI.label(_stand_box, Rect2(BP, 10, 340, 26), "THE STANDING CODES AND THE FILTER", "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_stand_sub = UI.label(_stand_box, Rect2(BP + 350, 10, LEFT_IW - 350, 26), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	var sw: float = (LEFT_IW - (BOOK_KINDS.size() - 1) * STAND_GAP) / float(BOOK_KINDS.size())
	for k in range(BOOK_KINDS.size()):
		var sb := Button.new()
		sb.position = Vector2(BP + k * (sw + STAND_GAP), STAND_TOP)
		sb.size = Vector2(sw, STAND_SLOT_H)
		sb.focus_mode = Control.FOCUS_ALL
		sb.pressed.connect(open_book.bind(str(BOOK_KINDS[k])))
		_stand_box.add_child(sb)
		var t := {"button": sb, "kind": BOOK_KINDS[k]}
		t["top"] = UI.label(sb, Rect2(14, 10, sw - 28, 22), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		t["name"] = UI.label(sb, Rect2(14, 34, sw - 28, 28), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		_stand.append(t)


func _build_book() -> void:
	var bw: float = Pal.GRID_W
	_book = UI.panel(self, Rect2(0, BODY_Y, bw, BOOK_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_book.mouse_filter = Control.MOUSE_FILTER_STOP     # over the shelf: a press on the book isn't a paper's under it
	_book.visible = false
	_book_title = UI.label(_book, Rect2(16, 12, bw - 32 - 140, 36), "", "SemiBold", Pal.TITLE - 4, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_book_sub = UI.label(_book, Rect2(16, 52, bw - 32 - 140, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_book_done = UI.button(_book, Rect2(bw - 16 - 120, 18, 120, 42), false)
	_book_done.text = "Done"
	_book_done.pressed.connect(close_book)
	var cw: float = (bw - 32 - (BOOK_COLS - 1) * BOOK_GAP) / BOOK_COLS
	for k in range(BOOK_COLS * BOOK_ROWS):
		var b := Button.new()
		@warning_ignore("integer_division")
		b.position = Vector2(16 + (k % BOOK_COLS) * (cw + BOOK_GAP), BOOK_TOP + (k / BOOK_COLS) * (BOOK_CARD_H + BOOK_GAP))
		b.size = Vector2(cw, BOOK_CARD_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick_book.bind(k))
		_book.add_child(b)
		var c := {"button": b, "code": ""}
		c["name"] = UI.label(b, Rect2(12, 10, cw - 24 - 76, 28), "", "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["on"] = UI.label(b, Rect2(cw - 12 - 76, 14, 76, 22), "on now", "Regular", Pal.CELL_TEXT - 3, Pal.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT, false)
		c["line"] = UI.label(b, Rect2(12, 46, cw - 24, 24), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		var ch := Chips.new(cw - 24, 4)
		ch.position = Vector2(12, 46)
		b.add_child(ch)
		c["chips"] = ch
		for n2 in [c["name"], c["on"], c["line"]]:
			n2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_book_cards.append(c)
	var fy: float = BOOK_TOP + BOOK_ROWS * (BOOK_CARD_H + BOOK_GAP) + 8
	_book_left_head = UI.label(_book, Rect2(16, fy, 140, Chips.CHIP_H), "Still to learn:", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_book_left = Chips.new(bw - 32 - 150 - 160, 4)
	_book_left.position = Vector2(16 + 150, fy)
	_book.add_child(_book_left)
	_book_prev = UI.button(_book, Rect2(bw - 16 - 140, fy - 4, 40, 34), false)
	_book_prev.text = "‹"
	_book_prev.pressed.connect(_turn_book.bind(-1))
	_book_pages = UI.label(_book, Rect2(bw - 16 - 100, fy, 60, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
	_book_next = UI.button(_book, Rect2(bw - 16 - 40, fy - 4, 40, 34), false)
	_book_next.text = "›"
	_book_next.pressed.connect(_turn_book.bind(1))


## The book's slot is open: standing 1 by the Dial's Relay, 2 by the whole band, the filter by Clear air.
func book_open(kind: String) -> bool:
	if kind == "filter":
		return sim.atlas_rank("clear_air") > 0
	return sim.standing_open(int(kind.trim_prefix("standing")))


func _book_now(kind: String) -> String:
	if kind == "filter":
		return sim.filtered
	var k: int = int(kind.trim_prefix("standing"))
	return str(sim.standing[k]) if k < sim.standing.size() else ""


func open_book(kind: String) -> void:
	if not book_open(kind):
		return
	book_kind = "" if book_kind == kind else kind     # the slot again shuts it
	book_page = 0
	_shown = ""
	show_state(sim)


func close_book() -> void:
	book_kind = ""
	_shown = ""
	show_state(sim)


func _turn_book(d: int) -> void:
	book_page += d
	_shown = ""
	show_state(sim)


## The book's cards in order: None, then the known codes; the codes still to learn, scrambled, fill the last page.
func book_entries() -> Array:
	var out: Array = [{"code": "", "known": true}]
	for nm in sim.words_known():
		out.append({"code": str(nm), "known": true})
	var per: int = _book_cards.size()
	var room: int = (per - out.size() % per) % per
	for w in Data.WORDS:
		if room <= 0:
			break
		if not sim.knows_word(str(w["name"])):
			out.append({"code": str(w["name"]), "known": false, "learn": str(w["learn"])})
			room -= 1
	return out


func _pick_book(k: int) -> void:
	var nm: String = str(_book_cards[k]["code"])
	if book_kind == "" or not bool(_book_cards[k].get("known", false)):
		return
	if book_kind == "filter":
		sim.set_filtered(nm)
	else:
		sim.set_standing(int(book_kind.trim_prefix("standing")), nm)
	book_kind = ""
	_shown = ""
	show_state(sim)
	acted.emit()


## The decoder as one row (28 Oct, RadioAir): three slots side by side - an empty one dashed, saying what it does - an
## arrow, and what they'll make; the crew to call and Decrypt under it, its note under that.
func _build_decoder() -> void:
	_decoder_box = UI.panel(self, Rect2(0, DECODER_Y, LEFT_W, DECODER_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_decoder_title = UI.label(_decoder_box, Rect2(BP, 10, LEFT_IW, 26), "THE DECODER · ONE TO THREE PAPERS", "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(Data.SIGNAL_PAPERS):
		var p := UI.panel(_decoder_box, Rect2(BP + k * (SLOT_W + SLOT_GAP), SLOT_TOP, SLOT_W, SLOT_H), UI.box(Pal.BG, 7, 1, Pal.CARD_LINE))
		var sl := {"panel": p}
		sl["dash"] = Dashed.new(p.size)
		p.add_child(sl["dash"])
		sl["n"] = UI.label(p, Rect2(14, 10, SLOT_W - 28, 20), "%d" % (k + 1), "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		sl["name"] = UI.label(p, Rect2(14, 36, SLOT_W - 28, 30), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		sl["code"] = UI.label(p, Rect2(14, 70, SLOT_W - 28, 26), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		_slots.append(sl)
	_arrow = UI.label(_decoder_box, Rect2(BP + 3 * SLOT_W + 2 * SLOT_GAP, SLOT_TOP, ARROW_W, SLOT_H), "→", "SemiBold", Pal.TITLE - 4, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, false)
	_make_box = UI.panel(_decoder_box, Rect2(MAKE_X, SLOT_TOP, MAKE_W, SLOT_H), UI.box(Pal.CARD, 7, 1, Pal.CARD_LINE))
	var mw: float = MAKE_W - 28
	_make_head = UI.label(_make_box, Rect2(14, 8, mw, 22), "WHAT THEY'LL MAKE", "Medium", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_make = UI.label(_make_box, Rect2(14, 30, mw, 32), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_make_sub = UI.label(_make_box, Rect2(14, 62, mw, 22), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_make_sub2 = UI.label(_make_box, Rect2(14, 84, mw, 22), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	# the crew to call (20 Oct, Matt: "you can't really target farm what you are short of"): any, or an area's for notes
	_crew_head = UI.label(_decoder_box, Rect2(BP, CREW_Y, 52, CREW_H), "Crew", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(4):
		var cb := UI.button(_decoder_box, Rect2(BP + 56 + k * (CREW_W + 6), CREW_Y, CREW_W, CREW_H), false)
		cb.add_theme_font_size_override("font_size", Pal.CELL_TEXT - 1)
		cb.pressed.connect(_pick_crew.bind(k if k > 0 else -1))
		_crew_buttons.append(cb)
	_decrypt = UI.button(_decoder_box, Rect2(MAKE_X, CREW_Y, MAKE_W, CREW_H), true)
	_decrypt.text = "Decrypt"
	_decrypt.pressed.connect(_on_decrypt)
	var nx: float = BP + 56 + 4 * (CREW_W + 6)                # the note under Decrypt, from the crew row's end: its longer reasons fit
	_decrypt_note = UI.label(_decoder_box, Rect2(nx, NOTE_Y, LEFT_W - BP - nx, 22), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)


## The signals (28 Oct, RadioAir): "SIGNALS · n OF 3 HELD", the picked one as its full card, then the column's other
## places - a held signal as a row that picks, an empty one dashed, saying how one's made.
func _build_signals() -> void:
	_signals_box = UI.panel(self, Rect2(SIGNALS_X, BODY_Y, SIGNALS_W, BODY_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	var iw: float = SIG_IW
	_signals_title = UI.label(_signals_box, Rect2(BP, 10, iw, 26), "", "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_card = UI.panel(_signals_box, Rect2(BP, CARD_TOP, iw, CARD_H), UI.box(Pal.CARD, 8, 2, Pal.ACCENT))
	var cw: float = iw - 2 * 16
	_card_kicker = UI.label(_card, Rect2(16, 8, cw - 130, 22), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_card_title = UI.label(_card, Rect2(16, 28, cw - 130, 38), "", "SemiBold", Pal.TITLE - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_card_line = UI.label(_card, Rect2(16, 66, cw, 24), "", "Regular", Pal.CELL_TEXT, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_card_odds = UI.label(_card, Rect2(16 + cw - 130, 22, 130, 40), "", "SemiBold", Pal.TITLE, Pal.GOOD, HORIZONTAL_ALIGNMENT_RIGHT)
	_card_odds_sub = UI.label(_card, Rect2(16 + cw - 130, 8, 130, 18), "", "Regular", Pal.CELL_TEXT - 4, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_card_tiles = UI.tile_row(_card, 16, 94, cw, 3)
	_card_codes = Chips.new(cw, 8)
	_card_codes.position = Vector2(16, 162)
	_card.add_child(_card_codes)
	_card_kev = UI.label(_card, Rect2(16, 250, cw, 24), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_card_kev2 = UI.label(_card, Rect2(16, 272, cw, 24), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var n: int = SIM_CRAFTS.size()
	var crw: float = (cw - (n - 1) * 8) / n
	for k in range(n):
		var b := Button.new()
		b.position = Vector2(16 + k * (crw + 8), 302)
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
	_set_off = UI.button(_card, Rect2(16, 356, bw * 2, 46), true)
	_set_off.text = "Set off"
	_set_off.pressed.connect(_on_set_off)
	_bin = UI.button(_card, Rect2(16 + bw * 2 + 8, 356, bw, 46), false)
	_bin.text = "Bin it"
	_bin.pressed.connect(_on_bin)
	_wager_btn = UI.button(_card, Rect2(16 + bw + 8, 356, bw - 8, 46), false)
	_wager_btn.pressed.connect(_on_wagers)
	_wager_btn.visible = false
	var cbw: float = (cw - (CREW_COLS - 1) * 6) / CREW_COLS
	for k in range(CREW_MAX):
		var cb := Button.new()
		@warning_ignore("integer_division")
		cb.position = Vector2(16 + (k % CREW_COLS) * (cbw + 6), CREW_ROW_Y + (k / CREW_COLS) * (CREW_BH + 6))
		cb.size = Vector2(cbw, CREW_BH)
		cb.focus_mode = Control.FOCUS_ALL
		cb.pressed.connect(_on_crew.bind(k))
		_card.add_child(cb)
		UI.style_button(cb, false)
		var t := {"button": cb, "cls": ""}
		t["name"] = UI.label(cb, Rect2(10, 2, cbw - 20, 24), "", "SemiBold", Pal.CELL_TEXT - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		t["odds"] = UI.label(cb, Rect2(10, 24, cbw - 20, 22), "", "Medium", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		for n2 in [t["name"], t["odds"]]:
			n2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cb.visible = false
		_crew_btns.append(t)
	_build_dec(cw)
	for k in range(OTHERS_MAX):
		var b := Button.new()
		b.size = Vector2(iw, OTHER_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick_other.bind(k))
		_signals_box.add_child(b)
		var o := {"button": b, "k": -1}
		o["name"] = UI.label(b, Rect2(14, 4, iw - 28, 26), "", "SemiBold", Pal.CELL_TEXT + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		o["line"] = UI.label(b, Rect2(14, 28, iw - 28, 22), "", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		o["odds"] = UI.label(b, Rect2(iw - 130, 12, 116, 32), "", "SemiBold", Pal.CELL_TEXT_BIG + 4, Pal.GOOD, HORIZONTAL_ALIGNMENT_RIGHT)
		_others.append(o)
	for k in range(PLACES):
		var d := Dashed.new(Vector2(iw, OTHER_H))
		_signals_box.add_child(d)
		var e := {"box": d}
		e["name"] = UI.label(d, Rect2(16, 4, iw - 32, 26), "An empty slot", "SemiBold", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		e["line"] = UI.label(d, Rect2(16, 28, iw - 32, 22), "Decrypt papers on the left to make a signal", "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		_places.append(e)
	_empty = UI.label(_signals_box, Rect2(BP + 2, 0, iw - 4, 26), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_empty2 = UI.label(_signals_box, Rect2(BP + 2, 0, iw - 4, 26), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)


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
	var site: String = sim.signal_place(sg)
	var lv: int = sim.signal_level(sg)
	var crew: String = "The %s crew" % str(Data.ZONES[int(sg["zone"])]["name"]).replace("The ", "")
	if bool(sg.get("head", false)):
		crew += (", and %s, away from home" % Words.mid(sim.signal_head_name(sg))) if sg.has("county_head") else ", and their head at full strength"
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
	# the tabs (28 Oct): a shut one says so when it fits, and the note under the bar says what opens them
	var open: bool = sim.campaign_done()
	UI.fit_button(_views[0], ["The air"])
	UI.fit_button(_views[1], ["The Dial"] if open else ["The Dial · locked", "The Dial"])
	UI.fit_button(_views[2], ["The town"] if open else ["The town · locked", "The town"])     # the rebuild (18 Oct): its cards read shut till Kev's story is done
	UI.fit_button(_views[3], ["The story"] if open else ["The story · locked", "The story"])
	for k in range(1, VIEWS.size()):
		_views[k].disabled = not open
	UI.fit(_view_note, ["" if open else "The Dial, the town and the story open after the Quartermaster", "" if open else "Locked till the Quartermaster"])
	_view_note.visible = not open
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
		str(sim.standing), sim.filtered, sim.heard.size(), str(sim.campaign_done()), str(sim.atlas) + book_kind + str(book_page) + str(sim.words_known().size()) + str(sim.candidates.size())]
	if _wagers_ov.visible:
		_wagers_ov.show_state(sim)
	sig += "|%s|%s" % [str(sim.wagers), str(_wagers_ov.visible)]     # Kev's wagers (29 Oct)
	sig += "|%d|%s|%s|%s" % [crew_pick, str(sim.materials), sim.cls, str(sim.crew_played().map(func(c): return sim.signal_odds_class(selected, str(c), true)) if not sim.signals.is_empty() else [])]     # the crew row; a signal's materials lean on what's held (20 Oct)
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
	if book_kind != "" and not (on_air and book_open(book_kind)):
		book_kind = ""
	_papers_box.visible = on_air and book_kind == ""     # the book over the shelf too (28 Oct): the standing codes under it shut it
	_decoder_box.visible = on_air and book_kind == ""
	_signals_box.visible = on_air and book_kind == ""
	_stand_box.visible = on_air
	_book.visible = on_air and book_kind != ""
	var quiet: Array = Words.RADIO_QUIET if not on_air else []
	for k in range(_quiet.size()):
		_quiet[k].visible = k < quiet.size()
		if _quiet[k].visible:
			UI.fit(_quiet[k], [str(quiet[k]), ""])
	if not on_air:
		return
	_show_stand()
	if book_kind != "":
		_show_book()
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
	UI.fit(_papers_title, ["THE PAPERS · %d OF %d" % [papers.size(), Data.PILE_CAP], "THE PAPERS · %d" % papers.size()])     # the pile's cap (23 Oct)
	# the line beside the title, from its end to the pages (28 Oct)
	_papers_sub.position.x = BP + ceilf(UI.text_width(_papers_title, _papers_title.text)) + 16
	var sub_end: float = (_paper_prev.position.x - 12.0) if pages > 1 else float(LEFT_W - BP)
	_papers_sub.size.x = sub_end - _papers_sub.position.x
	# the two kinds, each with its count of the three (16 Oct): a story piece never hides that the plain ones are short
	var plain: int = papers.filter(func(x): return sim.story_of(x) < 0).size()
	var story: int = sim.story_held().size()
	var kinds: String = "Plain %d%s" % [plain, (" · Kev's story %d of 3" % story) if story > 0 else ""]
	UI.fit(_papers_sub, [kinds + " · pick one to three into the decoder", kinds + " · pick one to three", kinds, "Plain %d" % plain] if not papers.is_empty() else ["None held: they're found searching, or off Kev's pile", "None held", ""])
	var shown := 0
	for k in range(PAPERS_MAX):
		var r: Dictionary = _paper_rows[k]
		var n: int = paper_page * PAPERS_MAX + k
		r["button"].visible = n < papers.size()
		if not r["button"].visible:
			r["id"] = -1
			continue
		shown += 1
		var it: Dictionary = papers[n]
		r["id"] = int(it["id"])
		var rare: bool = int(it.get("rarity", 0)) >= Data.PAPER_DEEPER_AT
		UI.fit(r["name"], [str(it["base"]) + (" · rare" if rare else ""), str(it["base"])])
		r["name"].add_theme_color_override("font_color", Pal.tone_color(Pal.item_tone(it)) if int(it.get("rarity", 0)) > 0 else Pal.TEXT)
		var beat: int = sim.story_of(it)
		if beat >= 0:
			var bn: String = str(Data.STORY_BEATS[beat]["name"]).to_lower()
			UI.fit(r["code"], ["Kev's story · %s · %d of 3 found" % [bn, sim.story_held().size()] if beat == sim.story_now() else "Kev's story · %s" % bn, "Kev's story · %s" % bn, "Kev's story"])
			r["code"].add_theme_color_override("font_color", STORY)
		else:
			var cw: Array = code_words(str(it["base"]))
			UI.fit(r["code"], ([str(cw[0][0]) + " · one deeper"] if rare else []) + cw[0])
			r["code"].add_theme_color_override("font_color", cw[1])
		# picked: edged in the accent, thicker; Kev's story's in its blue (28 Oct, RadioAir: the badges went for the edges)
		var on: bool = int(it["id"]) in chosen
		var edge: Color = Pal.ACCENT if on else (STORY if beat >= 0 else Pal.CARD_LINE)
		var ground: Color = Pal.CARD.blend(Color(STORY, 0.08)) if beat >= 0 and not on else Pal.CARD
		r["button"].add_theme_stylebox_override("normal", UI.box(ground, 7, 2 if on else 1, edge))
		r["button"].add_theme_stylebox_override("hover", UI.box(Pal.BUTTON, 7, 2 if on else 1, edge))
		r["button"].add_theme_stylebox_override("pressed", UI.box(Pal.BUTTON_PRESS, 7, 2 if on else 1, edge))
		r["button"].add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 7, 2, Pal.TEXT))
	# the shelf's next place on the last page, dashed: where more come from
	_paper_more.visible = shown < PAPERS_MAX
	if _paper_more.visible:
		_paper_more.position = _paper_rows[shown]["button"].position
		UI.fit(_paper_more_line, ["Papers come off signals and searches", "Papers come off signals", "More papers"])
	_paper_prev.visible = pages > 1
	_paper_next.visible = pages > 1
	_paper_page.visible = pages > 1
	_paper_page.text = "%d/%d" % [paper_page + 1, pages]
	_paper_prev.disabled = paper_page == 0
	_paper_next.disabled = paper_page >= pages - 1


## The standing codes' three slots (28 Oct): side by side at the left column's foot, shut ones saying so.
func _show_stand() -> void:
	UI.fit(_stand_sub, ["Pressing one opens the code book" + (": press it again to put it back" if book_kind != "" else ""), "Pressing one opens the code book", ""])
	for t in _stand:
		var b: Button = t["button"]
		var kind: String = str(t["kind"])
		var open: bool = book_open(kind)
		var what: String = "Filter" if kind == "filter" else "Standing %d" % (int(kind.trim_prefix("standing")) + 1)
		var state: String = "picking" if book_kind == kind else ("never heard" if kind == "filter" else "every site")
		var opener: String = "Clear air" if kind == "filter" else ("the Relay" if kind == "standing0" else "the whole band")
		UI.fit(t["top"], ["%s · %s" % [what, state] if open else "%s · not open yet · %s on the Dial" % [what, opener], "%s · %s" % [what, state if open else "not open yet"], what])
		var now: String = _book_now(kind) if open else ""
		# shut: where it opens on the big line, free while shut (28 Oct, the review: the standings' top line fell back to
		# "not open yet" and never said where)
		UI.fit(t["name"], [now if now != "" else "None"] if open else ["Shut · %s on the Dial" % opener, "Shut · %s" % opener, "Shut"])
		t["name"].add_theme_color_override("font_color", Pal.TEXT if open else Pal.TEXT_3)
		t["top"].add_theme_color_override("font_color", Pal.ACCENT if book_kind == kind else Pal.TEXT_2)
		b.disabled = not open
		var on: bool = book_kind == kind
		var edge: Color = Pal.ACCENT if on else Pal.CARD_LINE
		for st in ["normal", "hover", "pressed", "disabled", "focus"]:
			b.add_theme_stylebox_override(st, UI.box(Pal.BG if not open else (Pal.BUTTON if st == "hover" else Pal.CARD), 7, 2 if on else 1, edge))


func _show_book() -> void:
	var standing: bool = book_kind != "filter"
	UI.fit(_book_title, ["The code book · %s" % ("standing %d" % (int(book_kind.trim_prefix("standing")) + 1) if standing else "the filter"), "The code book"])
	UI.fit(_book_sub, (["On every site you run until you change it · free to change", "On every site you run · free to change"] if standing
		else ["Never on the air while it's here · free to change", "Never on the air while it's here"]))
	var entries: Array = book_entries()
	var per: int = _book_cards.size()
	var pages: int = maxi(1, ceili(float(entries.size()) / per))
	book_page = posmod(book_page, pages)
	var now: String = _book_now(book_kind)
	for k in range(per):
		var c: Dictionary = _book_cards[k]
		var n: int = book_page * per + k
		var b: Button = c["button"]
		b.visible = n < entries.size()
		if not b.visible:
			c["code"] = ""
			c["known"] = false
			continue
		var e: Dictionary = entries[n]
		var nm: String = str(e["code"])
		var known: bool = bool(e["known"])
		c["code"] = nm
		c["known"] = known
		var on: bool = known and nm == now
		c["on"].visible = on
		if not known:
			UI.fit(c["name"], [Words.scramble(nm)])
			UI.fit(c["line"], [str(LEARNT.get(str(e["learn"]), "Not learnt yet")), "Not learnt yet"])
			c["line"].visible = true
			c["chips"].visible = false
		elif nm == "":
			UI.fit(c["name"], ["None"])
			UI.fit(c["line"], ["The sites as they are" if standing else "Every code can come on the air", "As they are"])
			c["line"].visible = true
			c["chips"].visible = false
		else:
			UI.fit(c["name"], [nm])
			var ww: Array = sim.word_words(nm, 1)
			var chips: Array = []
			if str(ww[0]) != "":
				chips.append({"forms": [str(ww[0]), str(ww[0]).get_slice(", ", 0)], "colour": BITE})
			if str(ww[1]) != "":
				chips.append({"forms": [str(ww[1]), str(ww[1]).get_slice(", ", 0)], "colour": PAY})
			c["chips"].show_chips(chips, 2, true)
			c["chips"].visible = true
			c["line"].visible = false
		c["name"].add_theme_color_override("font_color", Pal.TEXT if known else Pal.TEXT_3)
		b.disabled = not known
		var edge: Color = Pal.ACCENT if on else Pal.CARD_LINE
		for st in ["normal", "hover", "pressed", "disabled", "focus"]:
			b.add_theme_stylebox_override(st, UI.box(Pal.BG if not known else (Pal.BUTTON if st == "hover" else Pal.CARD), 7, 2 if on else 1, edge))
	var left := {}
	for w in Data.WORDS:
		if not sim.knows_word(str(w["name"])):
			left[str(w["learn"])] = int(left.get(str(w["learn"]), 0)) + 1
	var chips_l: Array = []
	for lk in ["paper", "zone", "deep"]:
		if int(left.get(lk, 0)) > 0:
			chips_l.append({"forms": ["%d %s" % [int(left[lk]), LEARN_FROM[lk]]], "colour": Pal.TEXT_2})
	_book_left_head.visible = not chips_l.is_empty()
	_book_left.visible = not chips_l.is_empty()
	_book_left.show_chips(chips_l, 1, true)
	_book_prev.visible = pages > 1
	_book_next.visible = pages > 1
	_book_pages.visible = pages > 1
	_book_pages.text = "%d/%d" % [book_page + 1, pages]


func _show_decoder() -> void:
	for k in range(_slots.size()):
		var sl: Dictionary = _slots[k]
		var it: Dictionary = _paper(chosen[k]) if k < chosen.size() else {}
		var on: bool = not it.is_empty()
		# an empty slot dashed, saying what it does (28 Oct, RadioAir); a full one edged in the accent
		(sl["panel"] as Panel).add_theme_stylebox_override("panel", UI.box(Pal.BG, 7, 2, Pal.ACCENT) if on else UI.box(Color(0, 0, 0, 0), 7))
		sl["dash"].visible = not on
		var spare: bool = not on and k > 0 and k >= chosen.size() and not chosen.is_empty() and sim.story_of(_paper(chosen[0])) < 0     # 20 Oct: one paper makes a signal, more make it stronger
		sl["n"].text = "%d · optional" % (k + 1) if spare else "%d" % (k + 1)
		var base: String = str(it.get("base", ""))
		UI.fit(sl["name"], [base + (" · rare" if int(it.get("rarity", 0)) >= Data.PAPER_DEEPER_AT else ""), base] if on else ([SPARE_NAME[k]] if spare else ["A paper from the left", "A paper here"]))
		sl["name"].add_theme_color_override("font_color", Pal.TEXT if on else Pal.TEXT_3)
		var more: Dictionary = sim.signal_grade(k + 1)
		var idle: Array = ["Click one on the shelf", "From the shelf"] if k == 0 else ["More make it stronger", ""]
		var cw: Array = code_words(base) if on else ([["%s signal, room for %d codes" % [more["name"], int(more["codes"])], "Room for %d codes" % int(more["codes"])], Pal.TEXT_3] if spare else [idle, Pal.TEXT_3])
		if on and sim.story_of(it) >= 0:
			cw = [["Kev's story · %s" % str(Data.STORY_BEATS[sim.story_of(it)]["name"]).to_lower(), "Kev's story"], STORY]
		UI.fit(sl["code"], cw[0])
		sl["code"].add_theme_color_override("font_color", cw[1])
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
	# the crew row: lit on the pick; an area's for Kev's notes; a story beat's crew is its own
	var story_in: bool = chosen.any(func(id): return not _paper(id).is_empty() and sim.story_of(_paper(id)) >= 0)
	if story_in:
		crew_pick = -1
	for k in range(_crew_buttons.size()):
		var b: Button = _crew_buttons[k]
		var z: int = k if k > 0 else -1
		var nm: String = "Any crew" if z < 0 else "%s · %s" % [str(Data.ZONES[z]["name"]).trim_prefix("The "), Fmt.notes(Data.AIM_NOTES).trim_suffix(" notes")]
		UI.fit_button(b, [nm, nm.get_slice(" ·", 0)] if z > 0 else [nm, "Any"])
		b.tooltip_text = "A crew from anywhere" if z < 0 else "Kev tunes it to the %s's crew: %s, their area's materials, and their head if one comes" % [str(Data.ZONES[z]["name"]).trim_prefix("The ").to_lower(), Fmt.notes(Data.AIM_NOTES)]
		b.disabled = story_in or (z > 0 and sim.notes < Data.AIM_NOTES)
		UI.style_button(b, z == crew_pick)
	var why: String = sim.decrypt_block(chosen, crew_pick)
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
		UI.fit_button(_kev, ["Ask Kev · %s" % Fmt.notes(price), "Ask Kev"])
	else:
		UI.fit_button(_kev, ["Ask Kev · %s" % kb, "Ask Kev"])


func _show_signals(od: Array) -> void:
	var n: int = sim.signals.size()
	UI.fit(_signals_title, ["SIGNALS · %d OF %d HELD" % [n, Data.SIGNALS_HELD]])
	_card.visible = n > 0
	_empty.visible = n == 0
	_empty2.visible = n == 0
	if n == 0:
		for o in _others:
			o["button"].visible = false
			o["k"] = -1
		var y_end: float = _lay_places(CARD_TOP, 0)
		_empty.position.y = y_end + 8
		_empty2.position.y = y_end + 34
		UI.wrap([_empty, _empty2], "No signals held. One to three papers in the decoder make one: a fix on a site, a crew from anywhere, run once.")     # 20 Oct: one to three; "campaign" a banned word on screen
		return
	var sg: Dictionary = sim.signal_at(selected)
	var e: Dictionary = sim.signal_read(selected)
	var site: String = sim.signal_place(sg)
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
	UI.set_tile(_card_tiles[2], "Item level", sim.finds_words(int(e["level"])))
	var chips: Array = []
	for wd in sim.signal_words(sg):
		var parts: Array = sim.word_words(str(wd["w"]), int(wd["t"]))     # [the bite, the pay]
		chips.append({"forms": ["%s: %s" % [wd["w"], parts[0]] if str(parts[0]) != "" else str(wd["w"]), str(wd["w"])], "colour": BITE})
		if str(parts[1]) != "":
			chips.append({"forms": [str(parts[1]), str(parts[1]).get_slice(", ", 0)], "colour": PAY})
	if bool(sg.get("head", false)):
		chips.append({"forms": ["Extra: %s at full strength" % sim.signal_head_name(sg), "Extra: a head"], "colour": Pal.WARN})
	if bool(sg.get("convoy_fight", false)):
		chips.append({"forms": ["The convoy: three heads, one after another, and the load", "The convoy"], "colour": Pal.WARN})
	if bool(sg.get("convoy", false)):
		chips.append({"forms": ["Extra: a convoy may come", "Extra: a convoy"], "colour": Pal.WARN})
	if bool(sg.get("sealed", false)):
		chips.append({"forms": ["Sealed", "Sealed"], "colour": Pal.TEXT_3})
	# what it brings for the rebuild (20 Oct, Matt: "never clear when said material drops"): its crew's area's two, the
	# one held fewer of the likelier, and the chance a run brings any
	var mats: Array = sim.signal_materials(selected)
	if not (mats[0] as Dictionary).is_empty():
		var parts_m: Array = []
		for mk in mats[0]:
			parts_m.append("%s %d%%" % [sim.thing_name(str(mk)).to_lower(), int(round(float(mats[0][mk]) * 100.0))])
		chips.append({"forms": ["Brings %s · %d%% a run" % [" · ".join(parts_m), int(round(float(mats[1]) * 100.0))], "Brings %s" % " · ".join(parts_m), "%d%% a run" % int(round(float(mats[1]) * 100.0))], "colour": MATERIAL})
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
		UI.fit(c["name"], ["%s · %s" % [cd["name"], Fmt.notes(sim.signal_craft_cost(selected, c["key"]))], str(cd["name"])])
		UI.fit(c["words"], [str(cd["words"]).replace("the site", "it"), ""] if why == "" else [why, ""])
	var picking: bool = sim.candidates.size() == 2     # back at level 1: the trait's picked on the Map first (21 Oct, the review)
	_set_off.disabled = not sim.can_deploy() or sim.on_mission() or picking
	var wager_on: bool = sim.wager_signal_open(selected) and not picking     # Kev's wagers on the signal's run (29 Oct)
	_wager_btn.visible = wager_on
	_set_off.size.x = (_bin.position.x - 8 - 16) / 2.0 if wager_on else _bin.position.x - 8 - 16
	if wager_on:
		var on_n: int = sim.wagers.get(sim.wager_signal_key(selected), {}).get("taken", []).size()
		UI.fit_button(_wager_btn, [Words.WAGERS["button_on"] % on_n, Words.WAGERS["button_n"] % on_n, "%d" % on_n] if on_n > 0 else [Words.WAGERS["button"]])
	if sim.away() and not picking:
		UI.fit_button(_set_off, ["Set off · " + Words.REPEAT["shut_away"].to_lower(), Words.REPEAT["shut_away"]])     # why it's shut (29 Oct)
	else:
		UI.fit_button(_set_off, ["Set off · pick a trait on the Map", "Pick a trait first"] if picking else ["Set off"])
	_show_crew()
	# the column's other places under the card (28 Oct, RadioAir): the signals held as rows that pick, then the empty
	var y: float = CARD_TOP + _card.size.y + OTHER_GAP
	var k := 0
	for j in range(n):
		if j == selected or k >= OTHERS_MAX:
			continue
		var o: Dictionary = _others[k]
		var og: Dictionary = sim.signal_at(j)
		o["k"] = j
		o["button"].visible = true
		o["button"].position = Vector2(BP, y)
		y += OTHER_H + OTHER_GAP
		UI.fit(o["name"], ["%s · level %d · the %s crew" % [sim.signal_place(og), sim.signal_level(og), str(Data.ZONES[int(og["zone"])]["name"]).replace("The ", "")], "%s · level %d" % [sim.signal_place(og), sim.signal_level(og)]])
		var names: Array = sim.signal_words(og).map(func(x): return str(x["w"]))
		var extra: String = ((" · %s at full strength" % Words.mid(sim.signal_head_name(og))) if bool(og.get("head", false)) else "") + (" · a convoy may come" if bool(og.get("convoy", false)) else "")
		UI.fit(o["line"], [(", ".join(names) if not names.is_empty() else "no codes") + extra, ", ".join(names) if not names.is_empty() else "no codes"])
		o["odds"].text = ""
		k += 1
	while k < OTHERS_MAX:
		_others[k]["button"].visible = false
		_others[k]["k"] = -1
		k += 1
	_lay_places(y, n)


## The empty places from `y` down, dashed: as many as the column has left after `held`. Returns the y under them.
func _lay_places(y: float, held: int) -> float:
	for k in range(_places.size()):
		var e: Dictionary = _places[k]
		e["box"].visible = k < PLACES - held
		if e["box"].visible:
			e["box"].position = Vector2(BP, y)
			y += OTHER_H + OTHER_GAP
	return y


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


func _pick_crew(z: int) -> void:
	crew_pick = z
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
	var sg: Dictionary = sim.decrypt(chosen, crew_pick)
	if not sg.is_empty():
		chosen = []
		crew_pick = -1
		selected = sim.signals.size() - 1
		start_decrypt(sim.signal_at(selected))
	_shown = ""
	acted.emit()


func _on_kev() -> void:
	sim.ask_kev()
	_shown = ""
	acted.emit()


## The crew's row (21 Oct): each class played, its odds on this signal as read for its own runner, the best lit; a press
## swaps that class out (at camp), so the card's odds and Set off are theirs.
func _show_crew() -> void:
	var played: Array = sim.crew_played()
	var on_show: bool = played.size() > 1
	var reads: Array = []
	for nm in played:
		reads.append(sim.signal_odds_class(selected, str(nm), true))
	var best := -1
	for k in range(reads.size()):
		if bool(reads[k][1]) and (best < 0 or float(reads[k][0]) > float(reads[best][0])):
			best = k
	for k in range(CREW_MAX):
		var t: Dictionary = _crew_btns[k]
		t["button"].visible = on_show and k < played.size()
		if not t["button"].visible:
			continue
		var nm: String = str(played[k])
		t["cls"] = nm
		var lv: int = sim.crew_level(nm)
		var jl: int = sim.join_level(nm)         # the crew's floor (30 Oct): a press would bring them out at this
		if jl > lv:
			UI.fit(t["name"], ["%s · L%d, joins at %d" % [nm, lv, jl], "%s · joins at %d" % [nm, jl], "%s · L%d" % [nm, jl]])
		else:
			UI.fit(t["name"], ["%s · L%d" % [nm, lv], nm])
		var o: Array = reads[k]
		var out_now: bool = nm == sim.cls
		if sim.on_mission() and not out_now:
			UI.fit(t["odds"], ["—"])               # read at camp, not while a run's out
		else:
			UI.fit(t["odds"], [("%s%s" % [Fmt.pct(float(o[0])), " · out" if out_now else ""]) if bool(o[1]) else "reading…", Fmt.pct(float(o[0])) if bool(o[1]) else "…"])
		var tone: String = "good" if float(o[0]) >= 0.9 else ("warn" if float(o[0]) >= 0.6 else "bad")
		t["odds"].add_theme_color_override("font_color", Pal.tone_color(tone) if bool(o[1]) else Pal.TEXT_3)
		UI.style_button(t["button"], k == best and not out_now)
		t["button"].disabled = out_now or sim.on_mission()
	# the card as tall as its crew rows (28 Oct: three a row on the narrower card), the decrypt's panel with it
	var rows: int = ceili(float(mini(played.size(), CREW_MAX)) / CREW_COLS) if on_show else 0
	var h: float = CREW_ROW_Y + rows * (CREW_BH + 6) + 4 if rows > 0 else CREW_ROW_Y + 2
	if not is_equal_approx(_card.size.y, h):
		_card.size.y = h
		_dec.size.y = h


func _on_crew(k: int) -> void:
	var nm: String = str(_crew_btns[k]["cls"])
	if nm != "" and sim.set_class(nm):
		_shown = ""
		acted.emit()


func _on_set_off() -> void:
	if sim.deploy_signal(selected):
		selected = 0
	_shown = ""
	acted.emit()


func _on_wagers() -> void:
	var sg: Dictionary = sim.signal_at(selected)
	if sg.is_empty():
		return
	_wagers_ov.open(sim, sim.wager_signal_key(selected), sim.signal_place(sg))
	_wagers_ov.move_to_front()
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
	var out: Array = _text_nodes_base()
	if _wagers_ov.visible and _air.visible:          # Kev's wagers over the air (29 Oct): what's under them isn't the screen's
		var r: Rect2 = _wagers_ov.get_global_rect()
		out = out.filter(func(n): return not r.intersects(n.get_global_rect())) + _wagers_ov.text_nodes()
	return out


func _text_nodes_base() -> Array:
	var out: Array = _views.duplicate()
	out.append(_view_note)
	if view == "map":
		return out + _atlas.text_nodes()
	if view == "town":
		return out + _town.text_nodes()
	if view == "story":
		return out + _story.text_nodes()
	out.append_array([_kicker, _headline, _unit, _sub, _heard])
	out.append_array(_chips.text_nodes())
	for l in _quiet:
		if l.visible:
			out.append(l)
	if not _stand_box.visible:
		return out
	out.append_array([_stand_head, _stand_sub])
	for t in _stand:
		out.append_array([t["top"], t["name"]])
	if _book.visible:
		out.append_array([_book_title, _book_sub, _book_done])
		for c in _book_cards:
			if c["button"].visible:
				out.append(c["name"])
				if c["on"].visible:
					out.append(c["on"])
				if c["line"].visible:
					out.append(c["line"])
				if c["chips"].visible:
					out.append_array(c["chips"].text_nodes())
		if _book_left.visible:
			out.append(_book_left_head)
			out.append_array(_book_left.text_nodes())
		if _book_pages.visible:
			out.append(_book_pages)
		return out
	out.append_array([_papers_title, _papers_sub, _kev_head, _kev_line, _kev, _paper_more_line])
	for r in _paper_rows:
		if r["button"].visible:
			out.append_array([r["name"], r["code"]])
	if _paper_page.visible:
		out.append(_paper_page)
	out.append_array([_decoder_title, _make_head, _make, _make_sub, _make_sub2, _decrypt_note, _crew_head, _decrypt])
	out.append_array(_crew_buttons)
	for sl in _slots:
		out.append_array([sl["n"], sl["name"], sl["code"]])
	out.append(_signals_title)
	if _card.visible:
		out.append_array([_card_kicker, _card_title, _card_line, _card_odds, _card_odds_sub, _card_kev, _card_kev2, _set_off, _bin])
		if _wager_btn.visible:
			out.append(_wager_btn)
		for t in _card_tiles:
			out.append_array([t["key"], t["value"]])
		out.append_array(_card_codes.text_nodes())
		for c in _crafts:
			out.append_array([c["name"], c["words"]])
		for t in _crew_btns:
			if t["button"].visible:
				out.append_array([t["name"], t["odds"]])
	for o in _others:
		if o["button"].visible:
			out.append_array([o["name"], o["line"]])
	for e in _places:
		if e["box"].visible:
			out.append_array([e["name"], e["line"]])
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

