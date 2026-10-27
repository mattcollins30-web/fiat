extends Control
## The inventory grid, shared by the Lock-up, the Workshop, the vendors and
## the run: a container's items as cells the size of their footprint (a rifle
## four cells by one, armour three by three, a bandage one), packed first-fit
## into thirteen columns, seven rows a page; the screen's left column takes
## the rest of the width (SIDE_W). Above it a bar: the container's
## fill, filters by kind and rarity, a sort, and a Select-many mode with Sell
## (or Ditch) selected. Rarity is the cell's border; the cell is the item's
## picture when one exists and short words when it doesn't (item_cell.gd).
##
## The packing is the grid's, not the sim's: the sim counts cells (areas),
## the grid places them. When first-fit can't place everything inside the
## capacity's outlines, the outlines extend to where it reached, so every
## item is always on a drawn cell - and the player can see the bag is
## awkward, not just full.
##
## The run's pack is the exception (27 Oct, Matt: "true tetris"): `pack_mode` draws the bag's own shape - the sim's
## pack_w() columns, capacity() cells - and every piece where the sim says it lies ("pos", turned by "rot"). Pieces
## drag about inside it (R or the right button turns the one in hand), green where it lies, red where it won't;
## a piece strapped on (no place, but coming home) sits past the pack's rows with no outline under it.
##
## Signals: `picked(id)` on a single selection, `acted` after a sell,
## `dropped(data)` for something dragged onto the grid from elsewhere.

signal picked(id: int)
signal acted
signal dropped(data: Dictionary)   # {"id", "src"}
signal turn_asked(id: int)         # pack mode: the selected piece turned where it lies (R or right-click, 27 Oct)

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")

const CELL := Pal.CELL
const GAP := Pal.CELL_GAP
const COLS := 13
const ROWS := 7                    # the default; `set_rows` for fewer
const BAR_H := 44
const BAR_GAP := 8
const GRID_Y := 2 * BAR_H + 2 * BAR_GAP                        # two bars above the grid: 104
const WIDTH := COLS * CELL + (COLS - 1) * GAP                  # 904
const SIDE_W := Pal.GRID_W - WIDTH - 24                         # 608: what a screen's left column gets beside the grid
const HEIGHT := GRID_Y + ROWS * CELL + (ROWS - 1) * GAP         # 588


## The height a grid of so many rows takes.
static func height_for(n: int) -> int:
	return GRID_Y + n * CELL + (n - 1) * GAP
## The tabs (20 Oct, Matt: "stash tabs for uniques and set items ... paper has a tab that isn't used any more and the
## meds tab displays both meds and ammo"): slots, or "unique" / "set" for what the piece is. The deeds and a head's
## papers sit in All. Each tab is as wide as its words; the sort an icon at the end.
const KINDS := [["All", []], ["Guns", ["Primary", "Secondary"]], ["Body", ["Helmet", "Armour", "Charm"]], ["Bags", ["Rig", "Backpack"]],
	["Meds", ["Medical", "Grenade"]], ["Rounds", ["Ammo"]], ["Parts", ["Attachment"]], ["Uniques", "unique"], ["Sets", "set"]]
const FILL_W := 100
const KIND_PAD := 32                 # a button's margin round its words (the fit rule)
const KIND_GAP := 3
const KIND_FONT := 18
const SORT_W := 52
const RARITY_W := 96                 # one button that steps through Any and the five (21 Oct: was six, the stash's tabs took the room)
const TAB_PAD := 34                  # a stash tab's margin round its words
const MANY_W := 100
const SELL_W := 180
const ALL_W := 200                 # the shelf's "All n · price" (23 Oct)
const PAGE_BTN := 44
const PAGE_LBL := 56
const SORTS := ["Value", "New", "Slot"]

var sim
var items: Array = []              # what the grid shows, after filter and sort
var selected := -1                 # one id, in single mode
var chosen: Array = []             # ids, in Select-many mode
var many := false
var kind := 0
var rarity := -1                   # -1 all, else the rarity index
var sort := 0
var page := 0
var fixed_kind := ""               # set by the Workshop: only this kind, bar hidden
var ditching := false              # set by the Run screen: Select-many ditches instead of selling
var binning := false               # the Kit room with the Fence shut (13 Oct): Select-many bins instead, for nothing (27 Oct)
var buying := ""                   # a vendor's shelf (23 Oct, parked item 10, Matt: "single buying at a time is a chore"): Select-many buys - "clinic" or "fence"
var can_many := true               # a shelf without the many: the Kit's compare shelf
var _all_button: Button            # the shelf's "All n · price" beside Buy (23 Oct)
var page_rows := ROWS              # rows a page; set_rows() for fewer
var drag_src := ""                 # set by the owner: cells can be dragged out, carrying this name
var accepts := []                  # drag sources this grid takes drops from, e.g. ["rig"]
var marks := {}                    # id -> "go", "could" or "dim": the Fence's contract marks (19 Oct); {} none
var _press_at := Vector2.ZERO      # where a cell press began, for the drag threshold
var _press_cell := -1
var _fill: Label
var _kind_buttons: Array = []
var _rarity_button: Button
var _tab_buttons: Array = []        # the stash's tabs (21 Oct, the crew): shared, the class's own, its second
var stash_tabs := false             # set by an owner showing the stash: the tabs show and the grid is the tab's
var tab := ""                       # the tab shown: "" shared, "own", "own2"
var _sort_button: Button
var _many_button: Button
var _sell_button: Button
var _page_label: Label
var _page_prev: Button
var _page_next: Button
var _cells: Array = []             # ItemCells, pooled; the first N are showing
var _outlines: Array = []          # one empty cell drawn per cell of capacity, under the items
var _placed := {}                  # id -> Rect2i in cells, after the last show
var _shown := ""
var pack_mode := false             # the run's pack (27 Oct): the bag's own shape, pieces where they lie
var _pack_cols := COLS             # the bag's width in pack mode
var _ghost: Panel                  # where the piece in hand would land: green, or red
static var drag_rot := false       # the piece in hand turned (R, or the right button, while dragging)
static var _live: Control          # the drag's picture, to turn
static var _live_fp := Vector2i.ONE     # its footprint as it lies


func _init() -> void:
	size = Vector2(WIDTH, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	# bar one: the fill, the kinds, the sort
	_fill = UI.label(self, Rect2(0, 0, FILL_W, BAR_H), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	var x := FILL_W + 6
	for k in range(KINDS.size()):
		var b := UI.button(self, Rect2(x, 0, 60, BAR_H), false)
		b.text = KINDS[k][0]
		b.add_theme_font_size_override("font_size", KIND_FONT)
		b.pressed.connect(_set_kind.bind(k))
		_kind_buttons.append(b)
	_lay_kinds()
	_sort_button = UI.button(self, Rect2(WIDTH - SORT_W, 0, SORT_W, BAR_H), false)
	_sort_button.add_theme_font_size_override("font_size", 20)
	_sort_button.pressed.connect(_cycle_sort)
	# bar two: rarities, select many, sell, pages
	var y := BAR_H + BAR_GAP
	x = 0
	_rarity_button = UI.button(self, Rect2(x, y, RARITY_W, BAR_H), false)
	_rarity_button.add_theme_font_size_override("font_size", 17)
	_rarity_button.pressed.connect(func(): _set_rarity(rarity + 1 if rarity + 1 < Data.RARITIES.size() else -1))
	x += RARITY_W + 6
	for k in range(3):
		var tb := UI.button(self, Rect2(x, y, 100, BAR_H), false)
		tb.add_theme_font_size_override("font_size", 17)
		tb.pressed.connect(_set_tab.bind(k))
		tb.set_drag_forwarding(Callable(), _can_drop_tab.bind(k), _drop_tab.bind(k))     # a piece dragged onto a tab moves to it
		tb.visible = false
		_tab_buttons.append(tb)
	x = RARITY_W + 6 + 3 * 106 + 4
	_many_button = UI.button(self, Rect2(x, y, MANY_W, BAR_H), false)
	_many_button.add_theme_font_size_override("font_size", 20)
	_many_button.pressed.connect(_toggle_many)
	_sell_button = UI.button(self, Rect2(x + MANY_W + 6, y, SELL_W, BAR_H), true)
	_sell_button.add_theme_font_size_override("font_size", 20)
	_sell_button.pressed.connect(_sell_chosen)
	_all_button = UI.button(self, Rect2(x + MANY_W + 6 + SELL_W + 6, y, ALL_W, BAR_H), false)
	_all_button.add_theme_font_size_override("font_size", 20)
	_all_button.pressed.connect(_choose_all)
	_all_button.visible = false
	var px := WIDTH - PAGE_BTN - 4 - PAGE_LBL - 4 - PAGE_BTN
	_page_prev = UI.button(self, Rect2(px, y, PAGE_BTN, BAR_H), false)
	_page_prev.text = "‹"
	_page_prev.pressed.connect(_turn.bind(-1))
	_page_label = UI.label(self, Rect2(px + PAGE_BTN + 4, y, PAGE_LBL, BAR_H), "", "Medium", 20, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER)
	_page_next = UI.button(self, Rect2(WIDTH - PAGE_BTN, y, PAGE_BTN, BAR_H), false)
	_page_next.text = "›"
	_page_next.pressed.connect(_turn.bind(1))
	# the container itself: an outline per cell, in rows of COLS
	for k in range(COLS * ROWS):
		@warning_ignore("integer_division")
		var o := UI.panel(self, Rect2((k % COLS) * (CELL + GAP), GRID_Y + (k / COLS) * (CELL + GAP), CELL, CELL), UI.box(Color.TRANSPARENT, 6, 1, Pal.CARD_LINE))
		o.visible = false
		o.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_outlines.append(o)
	_ghost = UI.panel(self, Rect2(0, 0, CELL, CELL), UI.box(Color(Pal.GOOD, 0.25), 6, 2, Pal.GOOD))
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.visible = false
	_ghost.z_index = 2


## Another cell for the pool: the k-th, made when first needed.
func _cell(k: int) -> Button:
	while _cells.size() <= k:
		var c := ItemCell.new()
		var i := _cells.size()
		c.pressed.connect(_pick.bind(i))
		c.gui_input.connect(_cell_input.bind(i))
		c.set_drag_forwarding(Callable(), func(at, data): return _can_drop_data(at + c.position, data), func(at, data): _drop_data(at + c.position, data))     # a drop over a piece is the grid's
		c.visible = false
		add_child(c)
		_cells.append(c)
	return _cells[k]


## The tabs along bar one, each as wide as its words, from after the fill.
func _lay_kinds() -> void:
	var x: float = FILL_W + 6
	for b in _kind_buttons:
		b.size.x = maxf(48.0, ceilf(UI.text_width(b, b.text)) + KIND_PAD)
		b.position.x = x
		x += b.size.x + KIND_GAP


## Whether a piece is on a tab: its slot in the tab's, or what it is ("unique", "set"); All takes everything.
static func _of_kind(it: Dictionary, kinds) -> bool:
	if kinds is String:
		return it.has(kinds)
	return kinds.is_empty() or it["slot"] in kinds


# ------------------------------------------------------------------ showing

## The container's items (the stash, usually), filtered and sorted here.
func show_items(s, source: Array, used: int, cap: int, what: String) -> void:
	sim = s
	items = []
	var kinds = KINDS[kind][1]
	var tabbed: bool = stash_tabs and sim != null
	if tabbed:
		if not sim.stash_tabs().any(func(t): return t[0] == tab):
			tab = ""
		used = sim.tab_used(tab)
		cap = sim.tab_cap(tab)
		what = str(sim.stash_tabs().filter(func(t): return t[0] == tab)[0][1])
	for it in source:
		if tabbed and sim.tab_of(it) != tab:
			continue
		if fixed_kind != "" and it["slot"] != fixed_kind:
			continue
		if fixed_kind == "" and not _of_kind(it, kinds):
			continue
		if rarity >= 0 and it["rarity"] != rarity:
			continue
		items.append(it)
	match "Pack" if pack_mode else SORTS[sort]:
		"Pack":
			pass                               # the pack's pieces lie where they lie: no order to show them in
		"Value":
			items.sort_custom(func(a, b): return a["value"] > b["value"])
		"New":
			items.sort_custom(func(a, b): return a["id"] > b["id"])
		"Slot":
			items.sort_custom(func(a, b): return a["slot"] < b["slot"] if a["slot"] != b["slot"] else a["value"] > b["value"])
	# a contract's marks (Fence B): what goes, then what would do, ahead of the rest - never a page away
	if not marks.is_empty():
		var by_mark := {"go": 0, "could": 1}
		var ranked: Array = []
		for k in range(items.size()):
			ranked.append([int(by_mark.get(str(marks.get(items[k]["id"], "")), 2)), k, items[k]])
		ranked.sort_custom(func(a, b): return a[0] < b[0] if a[0] != b[0] else a[1] < b[1])
		items = ranked.map(func(x): return x[2])
	# keep selections that still exist
	chosen = chosen.filter(func(id): return _has(id))
	if selected >= 0 and not _has(selected):
		selected = -1
	var sig := "%s|%d|%d|%d|%d|%s|%d|%s|%d|%d|%s|%s|%s|%s|%s" % [what, used, cap, kind, rarity, str(many), sort, str(chosen), selected, page, str(binning), str(marks), tab, str(sim.stash_tabs()) + str(sim.tab_used("own")) + str(sim.tab_used("own2")) if tabbed else "",
		("%d|%d" % [int(sim.cash), sim.stash_used()]) if buying != "" and sim != null else ""]     # the lot's button reads the cash and the room (23 Oct)
	var ups := {}                     # the arrows, worked out once a show (the review: twice a cell, ten times a second)
	var locks := {}                   # the padlocks (15 Oct): the level a piece waits for, 0 when it can be worn
	for it in items:
		ups[it["id"]] = _upgrade(it)
		locks[it["id"]] = sim.wear_lock(it) if sim != null else 0
		sig += ",%d:%d%s%d%s" % [it["id"], Items.stack_size(it), "^" if ups[it["id"]] else "", locks[it["id"]], str(it.get("pos", "")) + str(it.get("rot", false)) if pack_mode else ""]     # a stack redraws as it fills; an arrow as the kit changes; a lock as the level comes; a piece as it moves
	if sig == _shown:
		return
	_shown = sig
	_fill.text = "%s %d / %d" % [what, used, cap]
	if UI.text_width(_fill, _fill.text) > _fill.size.x:
		_fill.text = "%d / %d" % [used, cap]
	if UI.text_width(_fill, _fill.text) > _fill.size.x:
		_fill.text = "%d/%d" % [used, cap]     # a big stash, the tabs beside it (20 Oct)
	var bars: bool = fixed_kind == ""
	for k in range(_kind_buttons.size()):
		_kind_buttons[k].visible = bars
		var flag = KINDS[k][1]
		UI.style_button(_kind_buttons[k], k == kind and not (flag is String), (str(flag) if k == kind else "") if flag is String else "")
	_lay_kinds()
	_rarity_button.text = "Any" if rarity < 0 else Data.RARITY_SHORT[rarity]
	_rarity_button.tooltip_text = "Rarity: click for the next"
	UI.style_button(_rarity_button, rarity >= 0)
	_lay_tabs(tabbed)
	_sort_button.visible = not pack_mode
	_sort_button.text = "↕"
	_sort_button.tooltip_text = "Sorted by %s: click for %s" % [SORTS[sort].to_lower(), SORTS[(sort + 1) % SORTS.size()].to_lower()]
	_many_button.visible = can_many
	_many_button.text = "Select" if not many else "Single"
	UI.style_button(_many_button, false, "good" if many else "")
	var worth := 0
	var cells := 0
	for id in chosen:
		worth += sim.sell_price(_item(id))
		cells += Items.size(_item(id))
	_sell_button.visible = many
	_all_button.visible = many and buying != ""
	if buying != "":
		# the shelf's lot (23 Oct): what the chosen cost together, and the whole shelf's
		var cost := 0
		var cells_in := 0                      # the cells the lot wants: a stack that merges whole wants none (the review: the check mirrors the buys)
		for id in chosen:
			cost += _buy_price(_item(id))
			if not sim._stack_room(_item(id)):
				cells_in += Items.size(_item(id))
		var all_cost := 0
		for it in items:
			all_cost += _buy_price(it)
		UI.fit_button(_sell_button, Fmt.money_forms(cost).map(func(m): return "Buy %d · %s" % [chosen.size(), m]) + ["Buy %d" % chosen.size()])     # the price after the separator, as the All button's (the language pass)
		UI.fit_button(_all_button, Fmt.money_forms(all_cost).map(func(m): return "Buy all %d · %s" % [items.size(), m]) + ["All %d" % items.size()])
		var room: bool = sim.stash_room(cells_in)
		_sell_button.disabled = chosen.is_empty() or sim.cash < cost or not room
		_sell_button.tooltip_text = "" if chosen.is_empty() or not _sell_button.disabled else ("No room in the stash" if not room else "Short by %s" % Fmt.money(cost - sim.cash))
		_all_button.disabled = items.is_empty() or chosen.size() == items.size()
	elif ditching:
		_sell_button.text = "Ditch %d: %d cell%s" % [chosen.size(), cells, "" if cells == 1 else "s"]
	elif binning:
		var n := 0
		for id in chosen:
			if _many_bins(_item(id)):
				n += 1
		_sell_button.text = "Bin %d" % n           # gone for nothing (27 Oct): scrapping's the Workshop's
	else:
		UI.fit_button(_sell_button, Fmt.money_forms(worth).map(func(m): return "Sell %d: %s" % [chosen.size(), m]))
	if buying == "":
		_sell_button.disabled = chosen.is_empty() or (not ditching and not binning and not sim.room_open("fence")) or (binning and not chosen.any(func(id): return _many_bins(_item(id))))     # the Fence buys; shut till the Carpet Man (13 Oct)
	if pack_mode:
		_lay_pack(cap)
	else:
		_lay_grid(cap)
	var k := 0
	var top := page * page_rows
	for it in items:
		var r: Rect2i = _placed[it["id"]]
		if r.position.y < top or r.position.y >= top + page_rows:
			continue
		var c := _cell(k)
		c.visible = true
		c.position = Vector2(r.position.x * (CELL + GAP), GRID_Y + (r.position.y - top) * (CELL + GAP))
		var turned: bool = pack_mode and bool(it.get("rot", false)) and it.has("pos")
		c.show_item(it, (it["id"] in chosen) if many else it["id"] == selected, Vector2(ItemCell.px(r.size.x), ItemCell.px(r.size.y)) if turned else Vector2.ZERO)
		c.set_turned(turned)
		c.set_upgrade(ups[it["id"]])
		c.set_locked(locks[it["id"]])
		c.set_mark(str(marks.get(it["id"], "hl" if it.get("hl", false) else "")))     # a rule's highlight where no contract marks it
		k += 1
	while k < _cells.size():
		_cells[k].visible = false
		_cells[k].id = -1
		k += 1


## The stash's grid and the shelves': first-fit into the columns, never across a page's edge; the outlines exactly
## `cap` cells, or as far as the packing reached when it had to go further, so every item sits on an outline.
func _lay_grid(cap: int) -> void:
	_pack_cols = COLS
	_placed = _pack(items, page_rows)
	var reach := 0
	for id in _placed:
		var r: Rect2i = _placed[id]
		reach = maxi(reach, (r.position.y + r.size.y - 1) * COLS + r.position.x + r.size.x)
	var shown_cells := maxi(cap, reach)
	var pages := maxi(1, ceili(float(ceili(float(shown_cells) / COLS)) / page_rows))
	page = clampi(page, 0, pages - 1)
	for k in range(_outlines.size()):
		var cell_index := page * page_rows * COLS + k
		_outlines[k].visible = cell_index < shown_cells and k < page_rows * COLS
	_paged(pages)


## The pack (27 Oct): the bag's own columns and cells, each piece where it lies; one strapped on (or not yet placed)
## first-fit past the pack's last row, no outline under it.
func _lay_pack(cap: int) -> void:
	_pack_cols = sim.pack_w()
	var rows: int = sim.pack_rows()
	_placed = {}
	var loose: Array = []
	for it in items:
		if it.has("pos"):
			_placed[it["id"]] = Rect2i(int(it["pos"][0]), int(it["pos"][1]), lies(it).x, lies(it).y)
		else:
			loose.append(it)
	var reach_rows := rows
	if not loose.is_empty():
		var extra := _pack(loose, page_rows, rows)
		for id in extra:
			_placed[id] = extra[id]
			reach_rows = maxi(reach_rows, extra[id].end.y)
	var pages := maxi(1, ceili(float(reach_rows) / page_rows))
	page = clampi(page, 0, pages - 1)
	var top := page * page_rows
	for k in range(_outlines.size()):
		@warning_ignore("integer_division")
		var row: int = k / COLS
		var col: int = k % COLS
		_outlines[k].visible = col < _pack_cols and row < page_rows and (top + row) * _pack_cols + col < cap
	_paged(pages)


func _paged(pages: int) -> void:
	_page_label.text = "%d/%d" % [page + 1, pages]
	_page_prev.disabled = page == 0
	_page_next.disabled = page >= pages - 1


## A piece's footprint as it lies in the pack: turned, its sides swapped.
static func lies(it: Dictionary, rot = null) -> Vector2i:
	var f := Items.footprint(it)
	return Vector2i(f.y, f.x) if (bool(it.get("rot", false)) if rot == null else bool(rot)) else f


## The upgrade's arrow (11 Oct, Matt's list): better than what's worn in its slot, wherever spares are shown - the
## stash, the pack, the Fence's shelf, the Workshop's. `upgrades` off hides it.
var upgrades := true


func _upgrade(it: Dictionary) -> bool:
	return upgrades and sim != null and sim.is_upgrade(it)


## First-fit: each item in order takes the first free place, scanning rows
## then columns, that holds its footprint without crossing a page edge.
## Returns id -> Rect2i in cells.
static func _pack(list: Array, rows_a_page: int, y0 := 0) -> Dictionary:
	var taken := {}        # Vector2i -> true
	var out := {}
	for it in list:
		var f := Items.footprint(it)
		var w := mini(f.x, COLS)
		var h := f.y
		var y := y0
		var placed_v := false
		while not placed_v:
			@warning_ignore("integer_division")
			if h <= rows_a_page and (y / rows_a_page) != ((y + h - 1) / rows_a_page):
				@warning_ignore("integer_division")
				y = ((y / rows_a_page) + 1) * rows_a_page      # over the page edge: start the next page
			for x in range(COLS - w + 1):
				var free := true
				for dy in range(h):
					for dx in range(w):
						if taken.has(Vector2i(x + dx, y + dy)):
							free = false
							break
					if not free:
						break
				if free:
					for dy in range(h):
						for dx in range(w):
							taken[Vector2i(x + dx, y + dy)] = true
					out[it["id"]] = Rect2i(x, y, w, h)
					placed_v = true
					break
			y += 1
	return out


## How many outlines are showing (for the tests).
func outlines_shown() -> int:
	var n := 0
	for o in _outlines:
		if o.visible:
			n += 1
	return n


## Where each item sits, in cells, after the last show (for the tests).
func placed() -> Dictionary:
	return _placed


## The cell index showing this id on the current page, or -1 (for the tests).
## The cell button at k, for a flash.
func cell_node(k: int) -> Control:
	return _cells[k] if k >= 0 and k < _cells.size() else null


func cell_of(id: int) -> int:
	for k in range(_cells.size()):
		if _cells[k].id == id and _cells[k].visible:
			return k
	return -1


func _has(id: int) -> bool:
	for it in items:
		if it["id"] == id:
			return true
	return false


func _item(id: int) -> Dictionary:
	for it in items:
		if it["id"] == id:
			return it
	return {}


## Fewer rows a page: the grid shrinks to fit them.
func set_rows(n: int) -> void:
	page_rows = n
	size = Vector2(WIDTH, height_for(n))


# ------------------------------------------------------------------ dragging

## A press that moves far enough becomes a drag of the cell's item, if this
## grid lets its items out. The drop goes to whichever control accepts it.
func _cell_input(event: InputEvent, k: int) -> void:
	if pack_mode and not many and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and not _dragging():
		var rid: int = _cells[k].id
		if rid >= 0:
			if selected != rid:
				_pick(k)                       # a right-click picks the piece and turns it
			turn_asked.emit(rid)
			if is_inside_tree():
				accept_event()
		return
	if drag_src == "" or many:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_at = event.position
			_press_cell = k
		else:
			_press_cell = -1
	elif event is InputEventMouseMotion and _press_cell == k and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) and event.position.distance_to(_press_at) > 10.0:
		var id: int = _cells[k].id
		_press_cell = -1
		if id >= 0:
			_cells[k].force_drag({"id": id, "src": drag_src}, drag_preview(_item(id), bool(_item(id).get("rot", false)) and pack_mode))


## What rides under the mouse during a drag: the item's picture if it has
## one, its name if not; turned when `rot` (a piece lying turned in the pack). R or the right button turns it.
static func drag_preview(it: Dictionary, rot := false) -> Control:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := Items.art(it)
	var inner: Control
	if tex != null and not it.is_empty():
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var f := Items.footprint(it)
		t.size = Vector2(ItemCell.px(f.x), ItemCell.px(f.y))
		t.modulate = Color(1, 1, 1, 0.85)
		inner = t
	else:
		var preview := Label.new()
		preview.text = it.get("base", "")
		preview.add_theme_font_override("font", UI.font("SemiBold"))
		preview.add_theme_font_size_override("font_size", Pal.FLOOR)
		preview.add_theme_color_override("font_color", Pal.TEXT)
		inner = preview
	holder.add_child(inner)
	_live = holder
	_live_fp = Items.footprint(it) if not it.is_empty() else Vector2i.ONE
	drag_rot = false
	if rot:
		turn_live()
	return holder


## The piece in hand turned a quarter (R, or the right button, mid-drag).
static func turn_live() -> void:
	drag_rot = not drag_rot
	if _live == null or not is_instance_valid(_live) or _live.get_child_count() == 0:
		return
	var inner: Control = _live.get_child(0)
	inner.rotation_degrees = 90.0 if drag_rot else 0.0
	inner.position = Vector2(float(ItemCell.px(_live_fp.y)) if drag_rot else 0.0, 0.0)


func _input(event: InputEvent) -> void:
	if not pack_mode or (is_inside_tree() and not is_visible_in_tree()):     # out of the tree: the smoke's own calls
		return
	var key_r: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R
	if _dragging() and (key_r or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT)):
		turn_live()
		get_viewport().set_input_as_handled()


## R with a piece picked and nothing in hand: after the GUI, so a menu or card over the run takes it first (the review).
func _unhandled_key_input(event: InputEvent) -> void:
	if not pack_mode or (is_inside_tree() and not is_visible_in_tree()) or _dragging():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R and selected >= 0 and not many:
		turn_asked.emit(selected)              # the piece picked turns where it lies (27 Oct, Matt: "selected fullstop")
		if is_inside_tree():
			get_viewport().set_input_as_handled()


func _dragging() -> bool:
	return is_inside_tree() and get_viewport().gui_is_dragging()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _ghost != null:
		_ghost.visible = false


## The pack's cell under a point, and the page's: [x, y] in the pack's cells.
func cell_at(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / (CELL + GAP)), page * page_rows + floori((at.y - GRID_Y) / (CELL + GAP)))


func _can_drop_data(at: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.get("src", "") in accepts):
		return false
	if pack_mode and sim != null and sim.mission != null:
		var it: Dictionary = _drag_item(data)
		if not it.is_empty():
			var c := cell_at(at)
			var fp := lies(it, drag_rot)
			var ok: bool = sim.pack_free_at(sim.mission, it, c.x, c.y, drag_rot)
			_ghost.position = Vector2(c.x * (CELL + GAP), GRID_Y + (c.y - page * page_rows) * (CELL + GAP))
			_ghost.size = Vector2(ItemCell.px(fp.x), ItemCell.px(fp.y))
			_ghost.add_theme_stylebox_override("panel", UI.box(Color(Pal.GOOD if ok else Pal.BAD, 0.25), 6, 2, Pal.GOOD if ok else Pal.BAD))
			_ghost.visible = true
	return true


func _drop_data(at: Vector2, data: Variant) -> void:
	_ghost.visible = false
	var d: Dictionary = data.duplicate()
	if pack_mode:
		var c := cell_at(at)
		d["at"] = [c.x, c.y, drag_rot]
	dropped.emit(d)


## The thing a drag carries: the pack's own piece, or one off the floor.
func _drag_item(data: Dictionary) -> Dictionary:
	var src: Array = sim.mission.get("floor", []) if str(data.get("src", "")) == "floor" else sim.mission["found"]
	for it in src:
		if int(it["id"]) == int(data.get("id", -1)):
			return it
	return {}


# ------------------------------------------------------------------ acting

func _pick(k: int) -> void:
	var id: int = _cells[k].id
	if id < 0:
		return
	if _item(id).erase("hl"):
		_cells[k].set_mark(str(marks.get(id, "")))     # a rule's highlight goes once the piece is looked at, in any room (the review)
	if many:
		if id in chosen:
			chosen.erase(id)
		else:
			chosen.append(id)
		_shown = ""
		picked.emit(-1)
	else:
		selected = id
		picked.emit(id)


func _set_kind(k: int) -> void:
	kind = k
	page = 0
	picked.emit(-1)


## The stash's tabs along bar two after the rarity, each as wide as its words and what's in it.
func _lay_tabs(tabbed: bool) -> void:
	var tabs: Array = sim.stash_tabs() if tabbed else []
	var x: float = RARITY_W + 6
	for k in range(_tab_buttons.size()):
		var tb: Button = _tab_buttons[k]
		tb.visible = k < tabs.size()
		if not tb.visible:
			continue
		var key: String = str(tabs[k][0])
		tb.text = str(tabs[k][1])             # the fill at bar one's start says what's in the one shown
		tb.tooltip_text = "%s: %d of %d cells" % [tabs[k][1], sim.tab_used(key), sim.tab_cap(key)]
		tb.size.x = ceilf(UI.text_width(tb, tb.text)) + TAB_PAD
		tb.position.x = x
		x += tb.size.x + 6
		UI.style_button(tb, key == tab)
	_many_button.position.x = x if tabbed else float(RARITY_W + 6)
	_sell_button.position.x = _many_button.position.x + MANY_W + 6
	_all_button.position.x = _sell_button.position.x + SELL_W + 6


func _set_tab(k: int) -> void:
	var tabs: Array = sim.stash_tabs() if sim != null else []
	if k >= tabs.size():
		return
	tab = str(tabs[k][0])
	page = 0
	selected = -1
	picked.emit(-1)


func _can_drop_tab(_at: Vector2, data: Variant, k: int) -> bool:
	var tabs: Array = sim.stash_tabs() if sim != null else []
	return stash_tabs and k < tabs.size() and data is Dictionary and str(data.get("src", "")) == drag_src and drag_src != "" and str(tabs[k][0]) != tab


func _drop_tab(_at: Vector2, data: Variant, k: int) -> void:
	var tabs: Array = sim.stash_tabs()
	if sim.move_to_tab(int(data["id"]), str(tabs[k][0])):
		_shown = ""
		acted.emit()


func _set_rarity(r: int) -> void:
	rarity = r
	page = 0
	picked.emit(-1)


func _cycle_sort() -> void:
	sort = (sort + 1) % SORTS.size()
	picked.emit(-1)


func _toggle_many() -> void:
	many = not many
	chosen = []
	selected = -1
	picked.emit(-1)


func _turn(by: int) -> void:
	page += by
	picked.emit(-1)


## The shelf's price for a thing (23 Oct): the Clinic's or the Fence's.
func _buy_price(it: Dictionary) -> int:
	if it.is_empty():
		return 0
	return sim.clinic_price(it) if buying == "clinic" else sim.price(it)


## Every cell shown, chosen (the shelf's All).
func _choose_all() -> void:
	chosen = items.map(func(it): return int(it["id"]))
	_shown = ""
	picked.emit(-1)


func _sell_chosen() -> void:
	var left: Array = []
	for id in chosen.duplicate():
		var it := _item(id)
		if not it.is_empty():
			if buying != "":
				var bought: bool = sim.buy_clinic(id) if buying == "clinic" else sim.buy_id(id)
				if not bought:
					left.append(id)             # no room or no cash for this one: it stays picked, so the player sees what didn't go
			elif ditching:
				sim.ditch(id)
			elif binning:
				if _many_bins(it):
					sim.bin(id)
			else:
				sim.sell(it)
	chosen = left
	acted.emit()


## Select-many's bin takes the plain things: a unique or a set piece is binned one at a time, from the pick, on purpose.
func _many_bins(it: Dictionary) -> bool:
	return sim.can_bin(it) and not it.has("unique") and not it.has("set")


## For the tests: every label and visible button with text.
func text_nodes() -> Array:
	var out: Array = [_fill, _sort_button, _many_button, _page_label]
	if _sell_button.visible:
		out.append(_sell_button)
	if _all_button.visible:
		out.append(_all_button)
	for b in _kind_buttons:
		if b.visible:
			out.append(b)
	out.append(_rarity_button)
	for tb in _tab_buttons:
		if tb.visible:
			out.append(tb)
	for c in _cells:
		if c.visible:
			out.append_array(c.text_nodes())
	return out
