extends Control
## A vendor's screen - the Fence and the Clinic share it. The grid on the
## right is either the vendor's shelf (what they have, so many, and no more
## until a run restocks it) or your stash, switched by two buttons at the top
## of the left column. Pick a cell on the shelf for its figures and Buy; pick
## one in the stash to Sell (or, at the Clinic, Take into the rig). Under the
## grid the panel for the pick; with nothing picked, the vendor's own
## business: the Fence's sell-by-rarity and its bigger shelf, the Clinic's
## treatment and level. Fixed geometry inside the card grid's 1536 x 864.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const Inventory := preload("res://scripts/ui/inventory.gd")
const ItemHead := preload("res://scripts/ui/item_head.gd")
const PickPanel := preload("res://scripts/ui/pick_panel.gd")
const People := preload("res://scripts/ui/people.gd")
const Band := preload("res://scripts/ui/band.gd")
const ClinicBody := preload("res://scripts/ui/clinic_body.gd")
const MedCards := preload("res://scripts/ui/med_cards.gd")
const FenceSell := preload("res://scripts/ui/fence_sell.gd")
const FenceList := preload("res://scripts/ui/fence_list.gd")
const FenceExchange := preload("res://scripts/ui/fence_exchange.gd")
const IssuerCounter := preload("res://scripts/ui/issuer_counter.gd")

const BODY_W := Inventory.SIDE_W                              # 608
const GAP := 24
const GRID_X := BODY_W + GAP
const GRID_W := Inventory.WIDTH
# the rooms' one band across the top (10 Oct, Bands-U A; Matt: "uniform with everywhere else"): the vendor's face, name
# and figure in it, the tabs at its foot, right; the side column and the grid under it
const BAND_H := Pal.BAND_H
const BODY_Y := BAND_H + 10
const BODY_H := Pal.ROOM_H - BODY_Y
const GRID_ROWS := 4                                          # seven before the band; the grid pages
const GRID_H := Inventory.GRID_Y + GRID_ROWS * Pal.CELL + (GRID_ROWS - 1) * Pal.CELL_GAP
const PANEL_Y := BODY_Y + GRID_H + GAP
const PANEL_H := Pal.ROOM_H - PANEL_Y
const PAD := 20
const INNER := BODY_W - 2 * PAD
const LINE_H := 30
const PANEL_LINES := 4
@warning_ignore("integer_division")
const COL_W := (GRID_W - 3 * PAD) / 2
const VERDICT_Y := 228               # the Kit's compare on the shelf (20 Oct): the verdict row, level with the pick's words
const TAB_H := 40                                             # the tabs, along the band's foot, right
const TAB_W := 160
const ISSUE_TAB_W := 140                                      # five across once the Issuer's counter opens
const FACE := Pal.BAND_FACE                                   # the portrait in the band
const TOP := 44                                               # the side column's sections, under the vendor's line
const TILE_GAP := 8
const SIDE_TILES := 11            # five rarities, five boxes, the shelf (the pass, 6 Oct)
const WORD_Y := PAD + 38 + 28 + 12 + UI.HEAD_H + 4                # the offer row's top, under the title, the line and its head
@warning_ignore("integer_division")
const OFFER_W := (GRID_W - 2 * PAD - 4 * TILE_GAP) / 5
const OFFER_H := 180
const LAST_Y := WORD_Y + OFFER_H + 16 + UI.HEAD_H + 4             # the last word's item head

var kind := "fence"                # "fence" or "clinic"
var sim
var showing := "shelf"             # which grid: "shelf" or "stash"
var selected := {}                 # {"kind": "shelf"|"stash", "id": n}, or {}
var _tabs: Array[Button] = []
var _word: Panel                   # the Fence's word: the gamble
var _word_title: Label
var _word_line: Label
var _word_head: Label
var _word_note: Label
var _offers: Array = []            # {panel, art, kind, sub, pay} a kind on offer
var _last_head: Label
var _last                          # the last thing the word got you (item_head.gd)
var _last_none: Label
var _shelf                         # the vendor's grid
var _stash                         # your grid
var _side: Panel
var _band: Band
var _side_title: Label             # the first section's head
var _face: TextureRect             # the vendor, in the band
var _said: Array[Label] = []       # what they said: one line under the band
var _heads: Array[Label] = []      # the section heads under the band
var _side_tiles: Array = []        # the Fence's tile buttons: {button, key, value}
var _med_tiles: Array = []         # the Clinic's: your meds by kind
var _side_tiles_c: Array = []      # the Clinic's figures: resting, the Clinic's level (18 Oct: the heal and wound prices are on their buttons only)
var _visits := 0
var _said_n := 0
var _line := ""
var _lost_seen := -1               # the medic notices a new runner
var _town_said := false            # the Fence, once, when the town opens
var _side_track: Panel
var _side_fill: Panel
var _side_bar_text: Label
var _side_buttons: Array[Button] = []
var _side_actions: Array = []
var _panel: Panel
var _left_title: Label             # the Fence's or the rig's line with nothing picked; a pick shows the head
var _head                          # the pick's name, chips, headline and affix rows (item_head.gd)
var _left_lines: Array[Label] = []
var _right_title: Label
var _right_lines: Array[Label] = []
var _hint: Label
var _words: Array[Label] = []      # the item's own line, two rows under the figures
var _buttons: Array[Button] = []
var _pending_deltas: Array = []    # the pick's deltas, laid along the foot with the buttons
var _fit_head                      # the piece worn in its slot, beside the pick, as the Kit has it (20 Oct, Matt)
var _verdict: Label                # Upgrade / Sidegrade / Downgrade, the foot's left
var _deltas: Array[Label] = []     # what changes, ▲ or ▼, after it
var _actions: Array = []
var _shown := ""
var _body                          # the Clinic's runner: the outline, the wounds, the HP (clinic_body.gd, 19 Oct)
var _meds                          # the Clinic's meds as cards, in the grid's place (med_cards.gd, 19 Oct)
var _sell                          # the Fence's side on the shelf and the stash: by rarity, the boxes (fence_sell.gd, 19 Oct)
var _list                          # the Fence's side on the exchange: today's rates and his mate (fence_list.gd; the contracts' till 28 Oct)
var _issuer                        # the Issuer's counter, the fifth tab after the Issue (issuer_counter.gd, 25 Oct)
var _exchange                      # the exchange, the third tab in the grid's place (fence_exchange.gd, 28 Oct: the contracts' tab was)


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	# the band across the top (Bands-U A), the tabs at its foot, right; the left column under it: the vendor's line, their business
	_band = Band.new(Pal.GRID_W, BAND_H, 4)
	add_child(_band)
	_face = People.rect(_band, Vector2(PAD, (BAND_H - FACE) / 2.0), FACE / 128.0)
	_band.portrait_width(FACE)
	_band.room_band()
	_side = UI.panel(self, Rect2(0, BODY_Y, BODY_W, BODY_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_said.append(UI.label(_side, Rect2(PAD, 10, INNER, 26), "", "Regular", Pal.CELL_TEXT_BIG + 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false))
	for k in range(5):
		var b := UI.button(self, Rect2(_tab_x(k, 2), BAND_H - 16 - TAB_H, TAB_W, TAB_H), k == 0)
		b.pressed.connect(_show.bind(["shelf", "stash", "exchange", "word", "issuer"][k]))
		b.visible = k < 2
		_tabs.append(b)
	# the Fence's word (the gamble, Matt, 6 Oct): five kinds on offer where the grid would be, the last thing it got you under them
	_word = UI.panel(self, Rect2(GRID_X, BODY_Y, GRID_W, BODY_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))     # the grid's and the panel's place
	_word.visible = false
	_word_title = UI.label(_word, Rect2(PAD, PAD, GRID_W - 2 * PAD, 36), "A word in the right ear", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_word_line = UI.label(_word, Rect2(PAD, PAD + 38, GRID_W - 2 * PAD, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_word_head = UI.head(_word, Rect2(PAD, WORD_Y - UI.HEAD_H - 4, GRID_W - 2 * PAD, UI.HEAD_H), "On offer · 5 kinds · new ones after every run")
	for k in range(Data.GAMBLE_SHOWN):
		var x := PAD + k * (OFFER_W + TILE_GAP)
		var o := {}
		o["panel"] = UI.panel(_word, Rect2(x, WORD_Y, OFFER_W, OFFER_H), UI.box(Pal.BG, 6))
		o["art"] = TextureRect.new()
		o["art"].position = Vector2(8, 8)
		o["art"].size = Vector2(OFFER_W - 16, 64)
		o["art"].expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		o["art"].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		o["art"].texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		o["art"].mouse_filter = Control.MOUSE_FILTER_IGNORE
		o["panel"].add_child(o["art"])
		o["kind"] = UI.label(o["panel"], Rect2(8, 76, OFFER_W - 16, 26), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		o["sub"] = UI.label(o["panel"], Rect2(8, 102, OFFER_W - 16, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		o["pay"] = UI.button(o["panel"], Rect2(8, OFFER_H - 8 - 40, OFFER_W - 16, 40), true)
		o["pay"].add_theme_font_size_override("font_size", 18)
		o["pay"].pressed.connect(_gamble.bind(k))
		_offers.append(o)
	_last_head = UI.head(_word, Rect2(PAD, LAST_Y - UI.HEAD_H - 4, GRID_W - 2 * PAD, UI.HEAD_H), "The last word")
	_last = ItemHead.new(GRID_W - 2 * PAD, true)
	_last.position = Vector2(PAD, LAST_Y)
	_last.visible = false
	_word.add_child(_last)
	_last_none = UI.label(_word, Rect2(PAD, LAST_Y, GRID_W - 2 * PAD, 28), "Nothing yet. Pay, and whatever he gets you lands in the stash.", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_word_note = UI.label(_word, Rect2(PAD, BODY_H - PAD - 28, GRID_W - 2 * PAD, 28), "At your best site's level, up to what you can wear. Never Common; 1 in 50 is a unique.", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_shelf = Inventory.new()
	_shelf.position = Vector2(GRID_X, BODY_Y)
	_shelf.set_rows(GRID_ROWS)
	_shelf.can_many = true                 # Select-many buys (23 Oct, parked item 10)
	_shelf.picked.connect(_on_pick.bind("shelf"))
	_shelf.acted.connect(_on_acted)             # the lot bought (23 Oct)
	add_child(_shelf)
	_stash = Inventory.new()
	_stash.position = Vector2(GRID_X, BODY_Y)
	_stash.set_rows(GRID_ROWS)
	_stash.stash_tabs = true               # the shared tab and the class's own (21 Oct, the crew)
	_stash.visible = false
	_stash.picked.connect(_on_pick.bind("stash"))
	_stash.acted.connect(_on_acted)
	add_child(_stash)
	# the vendor's own business, as sections under the band
	for i in range(4):
		var h := UI.head(_side, Rect2(PAD, TOP + i * 100, INNER, UI.HEAD_H), "")
		h.visible = false
		_heads.append(h)
	_side_title = _heads[0]
	# the Clinic: the HP bar, three figures, your meds by kind
	_side_track = UI.panel(_side, Rect2(PAD, TOP + UI.HEAD_H + 2, INNER, 24), UI.box(Pal.BG, 6))
	_side_fill = UI.panel(_side_track, Rect2(0, 0, 0, 24), UI.box(Pal.GOOD, 6))
	_side_bar_text = UI.label(_side_track, Rect2(0, 0, INNER, 24), "", "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_side_tiles_c = UI.tile_row(_side, PAD, TOP + UI.HEAD_H + 2 + 24 + 6, INNER, 2)
	_med_tiles = UI.tile_row(_side, PAD, 0, INNER, 2) + UI.tile_row(_side, PAD, 0, INNER, 2)
	for t in _side_tiles_c + _med_tiles:
		t["panel"].visible = false
	for i in range(3):
		var b := UI.button(_side, Rect2(PAD, 0, INNER, 48), false)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_side_press.bind(i))
		b.visible = false
		_side_buttons.append(b)
	for i in range(SIDE_TILES + 3):
		_side_actions.append(Callable())
	# the Fence: tile-shaped buttons, five rarities then the boxes and the bigger shelf
	for i in range(SIDE_TILES):
		var b := Button.new()
		b.position = Vector2(PAD, 0)
		b.size = Vector2(100, UI.TILE_H)
		b.text = ""
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_side_press.bind(i))
		b.visible = false
		_side.add_child(b)
		var t := {"button": b}
		t["key"] = UI.label(b, Rect2(10, 4, 80, 22), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		t["value"] = UI.label(b, Rect2(10, 26, 80, 30), "", "SemiBold", UI.TILE_TEXT, Pal.TEXT)
		_side_tiles.append(t)
	# the panel under the grid: the pick
	_panel = UI.panel(self, Rect2(GRID_X, PANEL_Y, GRID_W, PANEL_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_left_title = UI.label(_panel, Rect2(PAD, 10, COL_W, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_right_title = UI.label(_panel, Rect2(PAD * 2 + COL_W, 14, COL_W, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(PANEL_LINES):
		_left_lines.append(UI.label(_panel, Rect2(PAD, 48 + i * 28, COL_W, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		_right_lines.append(UI.label(_panel, Rect2(PAD * 2 + COL_W, 48 + i * 28, COL_W, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	_head = ItemHead.new(COL_W, true)
	_head.position = Vector2(PAD, 10)
	_head.visible = false
	_panel.add_child(_head)
	_fit_head = ItemHead.new(COL_W, true)
	_fit_head.position = Vector2(PAD * 2 + COL_W, 10)
	_fit_head.visible = false
	_panel.add_child(_fit_head)
	# the verdict and its deltas: the right column's foot, under the worn card, level with the pick's words
	_verdict = UI.label(_panel, Rect2(PAD * 2 + COL_W, VERDICT_Y, 200, 30), "", "SemiBold", Pal.FLOOR, Pal.WARN, HORIZONTAL_ALIGNMENT_LEFT, false)
	_verdict.visible = false
	for i in range(PickPanel.DELTAS):
		var dl := UI.label(_panel, Rect2(PAD * 2 + COL_W, VERDICT_Y, 120, 30), "", "Regular", Pal.FLOOR, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false)
		dl.visible = false
		_deltas.append(dl)
	_hint = UI.label(_panel, Rect2(PAD, PANEL_H - 6 - 44, GRID_W - 2 * PAD, 44), "", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(2):
		_words.append(UI.label(_panel, Rect2(PAD, 228 + i * 20, COL_W, 20), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	for i in range(3):
		var b := UI.button(_panel, Rect2(0, PANEL_H - 6 - 44, 200, 44), i == 0)
		b.pressed.connect(_press.bind(i))
		b.visible = false
		_buttons.append(b)
		_actions.append(Callable())


func setup(k: String) -> void:
	kind = k
	_shelf.buying = kind                        # Select-many on the shelf buys the lot (23 Oct)
	_stash.binning = kind != "fence"            # the Clinic's stash: Select-many bins; only the Fence buys (28 Oct, Matt)
	if kind == "fence":
		for i in range(4):                          # four at the band's foot, right
			_tabs[i].position.x = _tab_x(i, 4)
			_tabs[i].visible = true
			_tabs[i].add_theme_font_size_override("font_size", 16)     # four across
		_tabs[4].add_theme_font_size_override("font_size", 16)
		_tabs[4].visible = false
		# Fence A (19 Oct): the side by rarity and the boxes; on the exchange (28 Oct), today's rates and his mate
		_sell = FenceSell.new(INNER)
		_sell.position = Vector2(PAD, TOP)
		_sell.acted.connect(_on_sold)
		_side.add_child(_sell)
		_list = FenceList.new(INNER, BODY_H - TOP - PAD)
		_list.position = Vector2(PAD, TOP)
		_list.visible = false
		_list.mate.connect(_buy_mate)
		_side.add_child(_list)
		_exchange = FenceExchange.new(GRID_W, BODY_H)
		_exchange.position = Vector2(GRID_X, BODY_Y)
		_exchange.visible = false
		_exchange.acted.connect(_on_traded)
		add_child(_exchange)
		_issuer = IssuerCounter.new(GRID_W, BODY_H)
		_issuer.position = Vector2(GRID_X, BODY_Y)
		_issuer.visible = false
		_issuer.acted.connect(_on_acted)
		add_child(_issuer)
	if kind == "clinic":
		_shelf.fixed_kind = Data.MEDICAL
		_stash.fixed_kind = Data.MEDICAL
		# Clinic A and B (19 Oct): the runner's body and wounds down the left, the meds as cards on their tab
		_body = ClinicBody.new(INNER, BODY_H - TOP - PAD)
		_body.position = Vector2(PAD, TOP)
		_body.acted.connect(_on_treated)
		_body.handed.connect(_on_handed)
		_side.add_child(_body)
		_meds = MedCards.new(GRID_W, BODY_H)
		_meds.position = Vector2(GRID_X, BODY_Y)
		_meds.visible = false
		_meds.acted.connect(_on_acted)
		add_child(_meds)
	_band.set_site("The Clinic" if kind == "clinic" else "The Fence")     # art/places/the_clinic.png, the_fence.png when painted (9 Oct); the skyline till then
	if not People.show(_face, "medic" if kind == "clinic" else "fence"):
		_band.portrait_width(0)           # no art yet: the words take the band


# ------------------------------------------------------------------ showing

func _stock() -> Array:
	return sim.clinic if kind == "clinic" else sim.market


func _price(it: Dictionary) -> int:
	return sim.clinic_price(it) if kind == "clinic" else sim.price(it)


func show_state(s) -> void:
	sim = s
	if _line == "" and visible:
		_visits += 1                      # shown before the sim arrived: the first visit's line now
		_on_visit()
	var stock := _stock()
	var cells := 0
	for it in stock:
		cells += Items.size(it)
	var shelf_cap: int = sim.clinic_stock() if kind == "clinic" else cells
	_shelf.show_items(sim, stock, cells, maxi(shelf_cap, cells), "Shelf")
	_stash.show_items(sim, sim.stash, sim.stash_used(), sim.stash_cap(), "Stash")
	_shelf.visible = showing == "shelf"
	_stash.visible = showing == "stash" and kind != "clinic"
	if showing == "issuer" and (kind != "fence" or not sim.issued):
		showing = "shelf"                     # no counter before the Issue
	_word.visible = showing == "word"
	if _exchange != null:
		_exchange.visible = showing == "exchange"
		if _exchange.visible:
			_exchange.show_state(sim)
	if _issuer != null:
		_issuer.visible = showing == "issuer"
		if _issuer.visible:
			_issuer.show_state(sim)
	if _meds != null:
		_meds.visible = showing == "stash"
		if _meds.visible:
			_meds.show_state(sim)
	_panel.visible = not (_word.visible or (_meds != null and _meds.visible) or (_issuer != null and _issuer.visible) or (_exchange != null and _exchange.visible))     # the exchange, the word and the meds take the grid's and the panel's place (Bands-U A)
	if kind == "clinic":
		_show_treatment()                 # HP moves while resting: every refresh
	var sig := _signature()
	if sig == _shown:
		return
	_shown = sig
	_tabs[0].text = "Shelf"                 # its count is the grid's header (18 Oct, said once)
	_tab_text(_tabs[1], [("Stash (%d)" % sim.stash.size()) if kind == "fence" else "Meds", "Stash" if kind == "fence" else "Meds"])
	UI.style_button(_tabs[0], showing == "shelf")
	UI.style_button(_tabs[1], showing == "stash")
	if kind == "fence":
		_tabs[2].text = "Exchange"
		UI.style_button(_tabs[2], showing == "exchange")
		_tab_text(_tabs[3], ["The word (%d)" % sim.gamble.size(), "The word"])
		UI.style_button(_tabs[3], showing == "word")
		var n_tabs: int = 5 if sim.issued else 4     # the Issuer's tab once the town's on fiat (25 Oct)
		var tw: float = TAB_W if n_tabs == 4 else ISSUE_TAB_W
		for i in range(n_tabs):
			_tabs[i].size.x = tw
			_tabs[i].position.x = Pal.GRID_W - PAD - n_tabs * tw - (n_tabs - 1) * 8 + i * (tw + 8)
		_tabs[4].visible = sim.issued
		if sim.issued:
			_tab_text(_tabs[4], [Words.ISSUED["tab"], "Issuer"])
			UI.style_button(_tabs[4], showing == "issuer")
		_show_word()
	_show_side()
	_show_panel()


## A tab's text: the first form that fits its width.
func _tab_text(b: Button, forms: Array) -> void:
	for f in forms:
		if UI.text_width(b, str(f)) + 32.0 <= b.size.x:
			b.text = str(f)
			return
	b.text = str(forms.back())


## The Fence's word: the kinds on offer, each with a picture of one of its bases, the kind's
## words and Pay with the price; a kind bought is gone until the next run; the last thing it got you.
func _show_word() -> void:
	var price: int = sim.gamble_price(sim.gamble[0]) if not sim.gamble.is_empty() else sim._inf(Data.GAMBLE_FLOOR)
	UI.fit(_word_line, ["He knows a man. %s a word, whatever it turns out to be." % Fmt.money(price), "%s a word; the kinds change after every run." % Fmt.money(price), "%s a word." % Fmt.money(price)])
	var kinds: Array = sim.gamble.duplicate()
	for k in range(Data.GAMBLE_SHOWN):
		var o: Dictionary = _offers[k]
		var on: bool = k < kinds.size()
		o["panel"].visible = true
		if on:
			var kd: Dictionary = sim.gamble_kind(kinds[k])
			o["art"].texture = _kind_art(kd)
			o["art"].visible = o["art"].texture != null
			UI.fit(o["kind"], [kd["words"], kd.get("short", kd["words"])])
			o["sub"].text = "Uncommon+"
			o["pay"].visible = true
			var pay_words: String = Fmt.money(sim.gamble_price(kinds[k]))
			o["pay"].text = "Pay %s" % pay_words
			if UI.text_width(o["pay"], o["pay"].text) + 32.0 > o["pay"].size.x:
				o["pay"].text = pay_words            # "Pay 1,132 tins" ran past its button (13 Oct, tins): the price alone
			o["pay"].disabled = not sim.can_gamble(kinds[k])
			o["kind"].add_theme_color_override("font_color", Pal.TEXT)
		else:
			o["art"].visible = false
			o["kind"].text = "Taken"
			o["sub"].text = "back after a run"
			o["pay"].visible = false
			o["kind"].add_theme_color_override("font_color", Pal.TEXT_3)
	var last: Dictionary = {}
	if sim.last_craft.get("kind", "") == "gamble":
		last = sim.item_by_id(int(sim.last_craft.get("id", -1)))
	_last.visible = not last.is_empty()
	_last_none.visible = last.is_empty()
	if not last.is_empty():
		_last.show_item(last, sim, "", "", true)


## A picture for a kind: the first base of it the Fence can source that has art; null for the words alone.
func _kind_art(kd: Dictionary) -> Texture2D:
	for b in Data.BASES[kd["slot"]]:
		if b.get("start", false) or (kd["type"] != "" and b.get("type", "") != kd["type"]):
			continue
		var tex := Items.art({"base": b["name"], "slot": kd["slot"]})
		if tex != null:
			return tex
	return null


func _gamble(k: int) -> void:
	if k >= sim.gamble.size():
		return
	var it: Dictionary = sim.gamble_buy(sim.gamble[k])
	if not it.is_empty():
		_says("gamble")
		acted.emit()
	show_state(sim)


func _buy_mate() -> void:
	if sim.buy_mate():
		_says("mate")
		acted.emit()
	_shown = ""
	show_state(sim)


func _stash_meds() -> int:
	var n := 0
	for it in sim.stash:
		if Items.is_medical(it):
			n += 1
	return n


func _signature() -> String:
	var parts := [kind, showing, str(selected), str(sim.on_mission()), str(int(sim.cash)), str(_stash.many), str(_shelf.many) + str(_shelf.chosen), str(sim.yard_picks.get("fence", [])) + str(sim.yard_picks.get("clinic", [])) + str(sim.yard_ranks), str(sim.gamble), str(sim.last_craft),
		str(sim.hp >= sim.max_hp() - 0.5), str(int(sim.treat_cost() / 10)), str(sim.exchange_day), str(sim.mate), str(sim.notes), str(sim.scrap), str(sim.salvage), str(sim.materials), str(sim.wounds.keys()),
		str(hash(sim.tree)), sim.cls]          # the tree and the class move the heal and rest figures
	for it in _stock():
		parts.append("m" + str(it["id"]))
	for it in sim.stash:
		parts.append(str(it["id"]))
	for it in sim.rig:
		parts.append("r" + str(it["id"]))
	for s in Data.SLOTS:
		parts.append(str(sim.equipped[s]["id"]) if sim.equipped[s] != null else "-")
	return "|".join(parts)


## The Clinic's band (19 Oct, Clinic A): the HP, the wounds' count, a chip a wound's cut; the body below, every refresh
## (HP moves while resting).
func _show_treatment() -> void:
	var full: bool = sim.hp >= sim.max_hp() - 0.5
	var n: int = sim.wounds.size()
	var state: String = ("%d wound%s" % [n, "" if n == 1 else "s"]) if n > 0 else ("fit for duty" if full else ("out on a run" if sim.on_mission() else "resting"))
	_band.set_words("The Clinic · the medic", "", "%d" % sim.hp_shown(),
		["of %d HP · %s" % [sim.max_hp_shown(), state], "of %d HP" % sim.max_hp_shown()], Pal.BAD if n > 0 else (Pal.GOOD if full else Pal.ACCENT))
	var cuts: Array = []
	for a in Data.WOUND_AREAS:
		if sim.wounds.has(a):
			var nm: String = sim.wound_stat_name(str(sim.wounds[a]["stat"]))
			cuts.append({"forms": ["−%d%% %s" % [sim.wound_pct(), nm], "−%d%% %s" % [sim.wound_pct(), nm.replace("max HP", "HP")]], "colour": "bad"})
	_band.headline_under_title(true)
	_band.chips.visible = not cuts.is_empty()
	if not cuts.is_empty():
		_band.chips.size.x = Pal.BAND_TEXT_W + 120     # three cuts across (the band's words run as far)
		_band.chips.show_chips(cuts, 1, true)
	if _body != null:
		_body.show_state(sim)


func _side_button(i: int, y: float, text: String, action: Callable, enabled: bool, tone := "", primary := false, x := float(PAD), w := float(INNER)) -> void:
	var b := _side_buttons[i]
	b.visible = true
	b.position = Vector2(x, y)
	b.size.x = w
	b.text = text
	b.disabled = not enabled
	UI.style_button(b, primary, tone)
	_side_actions[i] = action


## A tile-shaped button: its key over its figure, the figure in a tone; `w` wide at (x, y).
func _side_tile(i: int, x: float, y: float, w: float, key: String, options: Array, tone: Color, action: Callable, enabled: bool) -> void:
	var t: Dictionary = _side_tiles[i]
	var b: Button = t["button"]
	b.visible = true
	b.position = Vector2(x, y)
	b.size = Vector2(w, UI.TILE_H)
	b.disabled = not enabled
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(state, UI.box(Pal.BG if state != "hover" else Pal.SELECT, 6))
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 6, 2, Pal.TEXT))
	t["key"].size.x = w - 20
	t["value"].size.x = w - 20
	t["key"].text = key
	UI.fit(t["value"], options)
	t["value"].add_theme_color_override("font_color", tone if enabled else Pal.TEXT_3)
	t["key"].add_theme_color_override("font_color", Pal.TEXT_2 if enabled else Pal.TEXT_3)
	_side_actions[i] = action


## The vendor's own business, down the left, under the band.
func _show_side() -> void:
	for b in _side_buttons:
		b.visible = false
	for t in _side_tiles:
		t["button"].visible = false
	for t in _side_tiles_c + _med_tiles:
		t["panel"].visible = false
	for h in _heads:
		h.visible = false
	_side_track.visible = false
	if kind == "clinic":
		_show_treatment()                 # the band and the body (clinic_body.gd): the old side's tiles and buttons are the Fence's
		return
	# the Fence (19 Oct, Fence A): the band, then by rarity and the boxes, or today's rates on the exchange (28 Oct)
	var worth_all := 0
	for it in sim.stash:
		worth_all += sim.sell_price(it)
	var chips: Array = []
	if showing == "exchange":
		_band.set_words("The Fence · the exchange", "", Fmt.group(int(sim.cash)), ["%s in hand" % Fmt.unit(), Fmt.unit()], Pal.ACCENT)
		var spread: int = int(round(sim.exchange_spread() * 100.0))
		chips.append({"forms": ["He keeps %d%% either way" % spread, "%d%% spread" % spread], "colour": Pal.TEXT_2})
		if not sim.issued:
			chips.append({"forms": ["%s notes" % Fmt.group(sim.notes)], "colour": Pal.TEXT_2})     # no notes held after the Issue
		chips.append({"forms": ["%s scrap" % Fmt.group(sim.scrap)], "colour": Pal.TEXT_2})
	else:
		if sim.issued:
			_band.set_words("The Fence · buys at his rate, charges three times", "", Fmt.group(int(sim.cash)), ["fiat in hand", "fiat"], Pal.ACCENT)     # the third review: tins after the Issue
		else:
			_band.set_words("The Fence · pays full value, charges three times", "", Fmt.group(int(sim.cash)), ["tins in hand", "tins"], Pal.ACCENT)
		if sim.inflation_pct() > 0:
			chips.append({"forms": ["Prices up %d%%" % sim.inflation_pct()], "colour": Pal.TEXT_2})
		chips.append({"forms": ["Your stash sells for %s" % Fmt.group(worth_all), "Stash: %s" % Fmt.short_num(worth_all)], "colour": Pal.TEXT_2})
	_band.headline_under_title(true)
	_band.chips.visible = true
	_band.chips.size.x = Pal.BAND_TEXT_W + 260
	_band.chips.show_chips(chips, 1, true)
	_sell.visible = showing != "exchange"
	_list.visible = showing == "exchange"
	if _list.visible:
		_list.show_state(sim)
	else:
		_sell.show_state(sim)


## A trade at the exchange (28 Oct): his word, the room again.
func _on_traded() -> void:
	_says("exchange")
	_shown = ""
	acted.emit()


func _on_sold() -> void:
	_says("sold")
	acted.emit()


func _show_panel() -> void:
	for b in _buttons:
		b.visible = false
	for l in _left_lines:
		l.text = ""
	for l in _right_lines:
		l.text = ""
		l.add_theme_color_override("font_color", Pal.TEXT_2)     # the colours a pick set go back (the parts' and the pay's)
	_right_title.add_theme_color_override("font_color", Pal.TEXT_2)
	var it := _selected_item()
	_say(it)
	_fit_head.visible = false
	_pending_deltas = []
	_verdict.visible = false
	for dl in _deltas:
		dl.visible = false
	_right_title.visible = true
	for rl in _right_lines:
		rl.visible = true
	_head.visible = not it.is_empty()
	_left_title.visible = it.is_empty()
	if it.is_empty():
		if kind == "clinic":
			_left_title.text = "The rig: %d of %d" % [sim.rig_used(), sim.med_capacity()]
			if sim.med_capacity() == 0:
				UI.fit(_left_lines[0], ["No rig fitted: fit one in the Kit to carry meds", "No rig fitted: fit one in the Kit", "No rig fitted"])
			elif sim.rig.is_empty():
				UI.fit(_left_lines[0], ["Nothing carried: take from Your meds", "Nothing carried: take from the grid", "Nothing carried"])
			else:
				var counts := {}
				var order := []
				for m in sim.rig:
					if not counts.has(m["base"]):
						counts[m["base"]] = 0
						order.append(m["base"])
					counts[m["base"]] += 1
				var words := []
				for nm in order:
					words.append(nm if counts[nm] == 1 else "%s ×%d" % [nm, counts[nm]])
				UI.fit(_left_lines[0], [", ".join(words), "%d meds" % sim.rig.size()])
				UI.fit(_left_lines[1], ["Used under fire; first taken, first used", "Used under fire, in the order taken"])
				UI.fit(_left_lines[2], ["Taken out again in the Kit, from the rig", "Taken out in the Kit"])
			_right_title.text = "The shelf: %d of %d" % [sim.clinic.size(), sim.clinic_stock()]
			_right_lines[0].text = "No more until the next run"
		else:
			_left_title.text = "The Fence"
			if sim.inflation_pct() > 0:
				if sim.issued:
					UI.fit(_left_lines[0], ["Prices up %d%% with the fiat about; the rate %.2f" % [sim.inflation_pct(), sim.fiat_rate], "Prices up %d%%" % sim.inflation_pct()])
				else:
					UI.fit(_left_lines[0], ["Prices up %d%% since the Pitch opened; notes keep their value" % sim.inflation_pct(), "Prices up %d%%; notes don't" % sim.inflation_pct()])
			else:
				UI.fit(_left_lines[0], ["Pays the Issuer's rate on what a thing is worth; asks three times that", "Buys at his rate; charges three times"] if sim.issued else ["Pays what a thing is worth; asks three times that", "Pays full value; charges three times"])
			_right_title.text = "Their shelf"
			_right_lines[0].text = "No more until the next run"
		_hint.text = "Pick an item on the shelf or in the stash"
		if _shelf.visible and _shelf.many:
			# the shelf's lot (23 Oct): what's picked, by name, and what it comes to
			var counts := {}
			var order: Array = []
			var cost := 0
			for id in _shelf.chosen:
				var ch: Dictionary = _shelf._item(id)
				if ch.is_empty():
					continue
				if not counts.has(ch["base"]):
					counts[ch["base"]] = 0
					order.append(ch["base"])
				counts[ch["base"]] += 1
				cost += _price(ch)
			if order.is_empty():
				_hint.text = "Pick several cells on the shelf; Buy takes the lot"     # no input verb (the language pass: tap/click, and the Deck)
			else:
				var words: Array = order.map(func(nm): return nm if counts[nm] == 1 else "%s ×%d" % [nm, counts[nm]])
				UI.fit(_hint, ["%d picked: %s · %s" % [_shelf.chosen.size(), ", ".join(words), Fmt.money(cost)], "%d picked · %s" % [_shelf.chosen.size(), Fmt.money(cost)]])
		_lay_buttons()
		return
	_hint.text = ""
	# the left column is the head; the tail says what the runner would get out of it
	var tail = ""
	if Items.is_medical(it):
		tail = "heals %.0f for you, over %.0f s" % [Items.heal(it) * sim.cm("heal") * (1.0 + sim.tree_sum("heal_pct") / 100.0), sim.use_time(it)]
	elif Items.is_gun(it):
		tail = [Items.fitted_words(it), Items.ammo_words(it).to_lower().replace("smg", "SMG")]
	elif Items.is_attachment(it) and not Items.is_socketable(it):
		tail = Items.att_words(it, true, true)
	_head.show_item(it, sim, tail)
	var fitted = sim.equipped.get(it["slot"], null) if it["slot"] in Data.SLOTS else null
	if fitted != null:
		# the Kit's compare (20 Oct, Matt: "the standard gear comparison display when viewing the fence's stashed items"):
		# the worn piece as its own card beside the pick, the verdict and what changes along the foot
		_right_title.visible = false
		for rl in _right_lines:
			rl.visible = false
		var ftail: Variant = ""
		if Items.is_gun(fitted):
			ftail = [Items.fitted_words(fitted), Items.ammo_words(fitted).to_lower().replace("smg", "SMG")]
		_fit_head.show_item(fitted, sim, ftail)
		_fit_head.visible = true
		var v: Array = PickPanel.verdict_for(sim, it)
		_verdict.text = str(v[0])
		_verdict.add_theme_color_override("font_color", Pal.tone_color(str(v[1])))
		_verdict.size.x = ceilf(UI.text_width(_verdict, _verdict.text)) + 2
		_verdict.visible = true
		_pending_deltas = PickPanel.deltas_for(sim, it, fitted)
	elif it["slot"] in Data.SLOTS:
		_right_title.text = "Nothing fitted as %s" % it["slot"].to_lower()
	elif Items.rig_item(it):
		_right_title.text = "The rig: %d of %d" % [sim.rig_used(), sim.med_capacity()]
	elif Items.is_socketable(it):
		UI.fit(_right_title, ["Fitted in the Workshop, Sockets view", "Fitted in the Workshop"])
		UI.wrap([_right_lines[0], _right_lines[1]], Items.socket_words(it))
	elif Items.is_paper(it):
		var pl: Array = sim.paper_lines(it)     # the Radio's, not the drawer's (15 Oct)
		_right_title.text = pl[0]
		UI.fit(_right_lines[0], [pl[1], pl[1].get_slice(":", 0)])
		UI.fit(_right_lines[1], [pl[2], pl[2].get_slice(":", 0)])
	elif it.has("mount"):
		# on your guns (19 Oct, Matt's Fence A): which of the two worn takes it, a line a gun
		var fits: Array = []
		var n_line := 0
		for slot in ["Primary", "Secondary"]:
			var g = sim.equipped.get(slot, null)
			if g == null:
				continue
			var gty: String = str(Items.base_of(g).get("type", ""))
			var ok: bool = g.get("attachments", {}).has(str(it["mount"])) and Items.att_fits(it, gty)
			if ok:
				fits.append(slot)
			if n_line < _right_lines.size():
				UI.fit(_right_lines[n_line], ["%s: %s%s" % [g["base"], gty if gty != "" else "melee", "" if ok else " · no"], str(g["base"])])
				_right_lines[n_line].add_theme_color_override("font_color", Pal.GOOD if ok else Pal.TEXT_2)
				n_line += 1
		_right_title.text = "Fits neither" if fits.is_empty() else ("Fits both" if fits.size() == 2 else "Fits your %s" % str(fits[0]).to_lower())
		_right_title.add_theme_color_override("font_color", Pal.TEXT_2 if fits.is_empty() else Pal.GOOD)
		if n_line < _right_lines.size():
			_right_lines[n_line].text = "Fitted in the Workshop"
			_right_lines[n_line].add_theme_color_override("font_color", Pal.TEXT_3)
	else:
		_right_title.text = ""
	if selected["kind"] == "shelf":
		var room: bool = sim.stash_fits(it) or sim._stack_room(it)
		if not room:
			_hint.text = "No room in your stash"
		elif sim.cash < _price(it):
			_hint.text = "Short by %s" % Fmt.money(_price(it) - sim.cash)
		var action: Callable = sim.buy_clinic.bind(it["id"]) if kind == "clinic" else sim.buy_id.bind(it["id"])
		_button(0, "Buy for %s" % Fmt.money(_price(it)), action, sim.cash >= _price(it) and room)
	else:
		if (kind == "clinic" and Items.is_medical(it)) or Items.is_ammo(it) or Items.is_grenade(it):
			var room: bool = sim.rig_room(Items.size(it))
			_right_lines[0].text = "" if room else ("No rig fitted" if sim.med_capacity() == 0 else ("The rig is full" if Items.size(it) == 1 else "No room: it takes %d pouches" % Items.size(it)))
			_button(0, "Take", sim.take.bind(it["id"]), not sim.on_mission() and room)
			_button(1, "Sell for %s" % Fmt.money(sim.sell_price(it)), sim.sell.bind(it), true)
		else:
			_button(0, "Sell for %s" % Fmt.money(sim.sell_price(it)), sim.sell.bind(it), true)
	_lay_buttons()


func _button(i: int, text: String, action: Callable, enabled: bool) -> void:
	var b := _buttons[i]
	b.visible = true
	b.text = text
	b.disabled = not enabled
	b.size.x = ceilf(UI.text_width(b, text)) + 48
	_actions[i] = action


## The item's own line, under the figures: who it was, where it came from.
func _say(it: Dictionary) -> void:
	UI.fit_sentences(_words[0], "" if it.is_empty() else (Words.UNIQUES.get(it["unique"], Words.item_words(it["base"])) if it.has("unique") else (Words.paper_words(it["base"], sim.room_open("radio")) if Items.is_paper(it) else Words.item_words(it["base"]))))
	_words[1].text = ""


func _lay_buttons() -> void:
	var x: float = GRID_W - PAD
	for i in range(_buttons.size() - 1, -1, -1):
		if _buttons[i].visible:
			x -= _buttons[i].size.x
			_buttons[i].position.x = x
			x -= 12
	_hint.size.x = maxf(100.0, x - PAD - 12)
	# the verdict's deltas after it, as many as the right column holds
	var dx: float = PAD * 2 + COL_W + (_verdict.size.x + 18 if _verdict.visible else 0.0)
	var dx_end: float = PAD * 2 + 2 * COL_W
	for i in range(_deltas.size()):
		var dl: Label = _deltas[i]
		dl.visible = false
		if not _verdict.visible or i >= _pending_deltas.size():
			continue
		var up: bool = float(_pending_deltas[i][0]) > 0.0
		dl.text = "%s %s" % ["▲" if up else "▼", _pending_deltas[i][1]]
		dl.add_theme_color_override("font_color", Pal.GOOD if up else Pal.BAD)
		dl.size.x = ceilf(UI.text_width(dl, dl.text)) + 2
		if dx + dl.size.x > dx_end:
			break
		dl.position.x = dx
		dl.visible = true
		dx += dl.size.x + 16
	if x - PAD - 12 < ceilf(UI.text_width(_hint, _hint.text)):
		_hint.text = ""


func _selected_item() -> Dictionary:
	if selected.is_empty() or sim == null:
		return {}
	for it in (_stock() if selected["kind"] == "shelf" else sim.stash):
		if it["id"] == selected["id"]:
			return it
	return {}


# ------------------------------------------------------------------ acting

func _show(which: String) -> void:
	showing = which
	selected = {}
	_shelf.selected = -1
	_stash.selected = -1
	show_state(sim)


func _on_pick(id: int, which: String) -> void:
	if id >= 0:
		selected = {"kind": which, "id": id}
	elif _stash.many or _shelf.many or _selected_item().is_empty():
		selected = {}
	show_state(sim)


func _on_acted() -> void:
	if _selected_item().is_empty():
		selected = {}
	acted.emit()


## What the Fence or the medic says: a visit line when the screen opens,
## a word on a buy, a sell, a treatment, the town opening, a new runner.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible and _sell != null:
		_sell._arm.clear()                    # out of the room, a rarity row's Sell arm goes (the second review)
		_sell._shown = ""
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible and sim != null:
		_visits += 1
		_on_visit()


func _on_visit() -> void:
	if kind == "clinic":
		if _lost_seen >= 0 and sim.operators_lost > _lost_seen:
			_line = Words.MEDIC["new_runner"]
		elif not sim.wounds.is_empty():
			_line = Words.MEDIC["wounds"][mini(sim.wounds.size(), 3) - 1] if sim.wounds.size() > 1 else str(Words.MEDIC["wound"][sim.wounds.keys()[0]])
		elif sim.hp < sim.max_hp() * 0.5:
			_line = Words.MEDIC["hurt"]
		else:
			_line = Words.rotate(Words.MEDIC["visit"], _visits - 1)
		_lost_seen = sim.operators_lost
	else:
		if sim.depot_cleared and not _town_said:
			_town_said = true
			_line = Words.FENCE["town"]
		else:
			_line = Words.rotate(Words.FENCE["visit"], _visits)     # from the second line: the room card says the first (18 Oct)
	_show_said()


func _says(key: String) -> void:
	var book: Dictionary = Words.MEDIC if kind == "clinic" else Words.FENCE
	var v = book.get(key, "")
	_said_n += 1
	_line = Words.rotate(v, _said_n) if v is Array else str(v)
	_show_said()


func _show_said() -> void:
	UI.fit_sentences(_said[0], _line)


func _side_press(i: int) -> void:
	var was_hp: float = sim.hp
	var was_wounds: int = sim.wounds.size()
	var was_level: int = sim.clinic_stock() + sim.market_stock()
	var was_n: int = sim.stash.size()
	if _side_actions[i].is_valid():
		_side_actions[i].call()
	if kind == "clinic" and (sim.hp > was_hp or sim.wounds.size() < was_wounds):
		_says("fit" if sim.hp >= sim.max_hp() and sim.wounds.is_empty() else "treated")
	elif sim.clinic_stock() + sim.market_stock() > was_level:
		_says("shelf")
	elif sim.stash.size() < was_n:
		_says("sold")
	elif sim.stash.size() > was_n:
		_says("bought")
	if _selected_item().is_empty():
		selected = {}
	acted.emit()


## The body's Treat (clinic_body.gd): the medic's word, then the room again.
func _on_treated() -> void:
	_says("fit" if sim.hp >= sim.max_hp() - 0.5 and sim.wounds.is_empty() else "treated")
	_shown = ""
	acted.emit()


## Her supplies handed in (28 Oct): her word, then the room again (the shelf may have moved a step).
func _on_handed() -> void:
	_says("supplies")
	_shown = ""
	acted.emit()


func _press(i: int) -> void:
	var it := _selected_item()
	var was_cash: float = sim.cash
	if _actions[i].is_valid():
		_actions[i].call()
	if sim.cash > was_cash:
		_says("deeds" if not it.is_empty() and Items.is_deeds(it) else ("papers" if not it.is_empty() and Items.is_paper(it) else "sold"))
	elif sim.cash < was_cash:
		_says("bought")
	if _selected_item().is_empty():
		selected = {}
		_shelf.selected = -1
		_stash.selected = -1
	acted.emit()


## Tab k's x at the band's foot, right, of n showing.
static func _tab_x(k: int, n: int) -> float:
	return Pal.GRID_W - PAD - n * TAB_W - (n - 1) * 8 + k * (TAB_W + 8)


## For the tests: the vendor's face sits clear of everything else showing in
## the side panel (the Fence's ammo buttons reach down towards it).
func face_clear() -> bool:
	if not _face.visible:
		return true
	var mine := Rect2(_face.position, _face.size)
	for c in _band.get_children():
		if c == _face or not (c is Control) or not c.visible or (c is Label and c.text == "") or _band.is_backdrop(c):
			continue
		if mine.intersects(Rect2(c.position, c.size)):
			return false
	for b in _tabs:
		if b.visible and mine.intersects(Rect2(b.position, b.size)):
			return false
	return true


## For the tests: every label and visible button with text.
func text_nodes() -> Array:
	var out: Array = [_left_title, _right_title, _hint]
	out.append_array(_words)
	if _head.visible:
		out.append_array(_head.text_nodes())
	if _fit_head.visible:
		out.append_array(_fit_head.text_nodes())
	if _verdict.visible:
		out.append(_verdict)
		out.append_array(_deltas.filter(func(dl): return dl.visible))
	out.append_array(_band.text_nodes())
	out.append_array(_said)
	if _body != null:
		out.append_array(_body.text_nodes())
	if _sell != null and _sell.visible:
		out.append_array(_sell.text_nodes())
	if _list != null and _list.visible:
		out.append_array(_list.text_nodes())
	if _exchange != null and _exchange.visible:
		out.append_array(_exchange.text_nodes())
	if _meds != null and _meds.visible:
		out.append_array(_meds.text_nodes())
	for h in _heads:
		if h.visible:
			out.append(h)
	if _side_track.visible:
		out.append(_side_bar_text)
	for t in _side_tiles_c + _med_tiles:
		if t["panel"].visible:
			out.append_array([t["key"], t["value"]])
	for t in _side_tiles:
		if t["button"].visible:
			out.append_array([t["key"], t["value"]])
	for b in _side_buttons:
		if b.visible:
			out.append(b)
	for t in _tabs:
		if t.visible:
			out.append(t)
	if showing == "word":
		out.append_array([_word_title, _word_line, _word_head, _last_head, _word_note])
		for o in _offers:
			if o["panel"].visible:
				out.append_array([o["kind"], o["sub"]])
				if o["pay"].visible:
					out.append(o["pay"])
		if _last.visible:
			out.append_array(_last.text_nodes())
		else:
			out.append(_last_none)
	out.append_array(_left_lines)
	out.append_array(_right_lines)
	for b in _buttons:
		if b.visible:
			out.append(b)
	if showing == "shelf" or (showing == "stash" and kind != "clinic"):
		out.append_array((_shelf if showing == "shelf" else _stash).text_nodes())
	return out


func line_pairs() -> Array:
	var out := []
	if _head.visible:
		out.append_array(_head.line_pairs())
	if _fit_head.visible:
		out.append_array(_fit_head.line_pairs())
	out.append([_band.headline, _band.unit])
	return out
