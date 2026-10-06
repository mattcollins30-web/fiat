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
## Signals: `picked(id)` on a single selection, `acted` after a sell,
## `dropped(data)` for something dragged onto the grid from elsewhere.

signal picked(id: int)
signal acted
signal dropped(data: Dictionary)   # {"id", "src"}

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
const KINDS := [["All", []], ["Guns", ["Primary", "Secondary"]], ["Body", ["Helmet", "Armour", "Charm"]], ["Bags", ["Rig", "Backpack"]],
	["Meds", ["Medical", "Ammo", "Grenade"]], ["Parts", ["Attachment"]], ["Paper", ["Paper"]]]
# the bars' widths, measured: a button needs its text and 32 px of margin;
# bar one is 122 + 6 + 7 × 90 + 6 × 3 + 124 = 900, inside the grid's 904
const FILL_W := 122
const KIND_W := 90
const SORT_W := 124
const RARITY_W := 72                 # six buttons with five rarities, at 17 px (the pass, 6 Oct): the row ends before the pages
const MANY_W := 100
const SELL_W := 180
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
var can_many := true               # a vendor's shelf has no Select-many
var page_rows := ROWS              # rows a page; set_rows() for fewer
var drag_src := ""                 # set by the owner: cells can be dragged out, carrying this name
var accepts := []                  # drag sources this grid takes drops from, e.g. ["rig"]
var _press_at := Vector2.ZERO      # where a cell press began, for the drag threshold
var _press_cell := -1
var _fill: Label
var _kind_buttons: Array = []
var _rarity_buttons: Array = []
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


func _init() -> void:
	size = Vector2(WIDTH, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	# bar one: the fill, the kinds, the sort
	_fill = UI.label(self, Rect2(0, 0, FILL_W, BAR_H), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	var x := FILL_W + 6
	for k in range(KINDS.size()):
		var b := UI.button(self, Rect2(x, 0, KIND_W, BAR_H), false)
		b.text = KINDS[k][0]
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_set_kind.bind(k))
		_kind_buttons.append(b)
		x += KIND_W + 3
	_sort_button = UI.button(self, Rect2(WIDTH - SORT_W, 0, SORT_W, BAR_H), false)
	_sort_button.add_theme_font_size_override("font_size", 20)
	_sort_button.pressed.connect(_cycle_sort)
	# bar two: rarities, select many, sell, pages
	var y := BAR_H + BAR_GAP
	x = 0
	for r in range(Data.RARITIES.size() + 1):
		var b := UI.button(self, Rect2(x, y, RARITY_W, BAR_H), false)
		b.text = "Any" if r == 0 else Data.RARITY_SHORT[r - 1]
		b.add_theme_font_size_override("font_size", 17)
		b.pressed.connect(_set_rarity.bind(r - 1))
		_rarity_buttons.append(b)
		x += RARITY_W + 6
	_many_button = UI.button(self, Rect2(x, y, MANY_W, BAR_H), false)
	_many_button.add_theme_font_size_override("font_size", 20)
	_many_button.pressed.connect(_toggle_many)
	_sell_button = UI.button(self, Rect2(x + MANY_W + 6, y, SELL_W, BAR_H), true)
	_sell_button.add_theme_font_size_override("font_size", 20)
	_sell_button.pressed.connect(_sell_chosen)
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
		var o := UI.panel(self, Rect2((k % COLS) * (CELL + GAP), GRID_Y + (k / COLS) * (CELL + GAP), CELL, CELL), UI.box(Color.TRANSPARENT, 6, 1, Pal.CARD_LINE))
		o.visible = false
		o.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_outlines.append(o)


## Another cell for the pool: the k-th, made when first needed.
func _cell(k: int) -> Button:
	while _cells.size() <= k:
		var c := ItemCell.new()
		var i := _cells.size()
		c.pressed.connect(_pick.bind(i))
		c.gui_input.connect(_cell_input.bind(i))
		c.visible = false
		add_child(c)
		_cells.append(c)
	return _cells[k]


# ------------------------------------------------------------------ showing

## The container's items (the stash, usually), filtered and sorted here.
func show_items(s, source: Array, used: int, cap: int, what: String) -> void:
	sim = s
	items = []
	var kinds: Array = KINDS[kind][1]
	for it in source:
		if fixed_kind != "" and it["slot"] != fixed_kind:
			continue
		if fixed_kind == "" and not kinds.is_empty() and not (it["slot"] in kinds):
			continue
		if rarity >= 0 and it["rarity"] != rarity:
			continue
		items.append(it)
	match SORTS[sort]:
		"Value":
			items.sort_custom(func(a, b): return a["value"] > b["value"])
		"New":
			items.sort_custom(func(a, b): return a["id"] > b["id"])
		"Slot":
			items.sort_custom(func(a, b): return a["slot"] < b["slot"] if a["slot"] != b["slot"] else a["value"] > b["value"])
	# keep selections that still exist
	chosen = chosen.filter(func(id): return _has(id))
	if selected >= 0 and not _has(selected):
		selected = -1
	var sig := "%s|%d|%d|%d|%d|%s|%d|%s|%d|%d" % [what, used, cap, kind, rarity, str(many), sort, str(chosen), selected, page]
	for it in items:
		sig += ",%d:%d" % [it["id"], Items.stack_size(it)]     # a stack redraws as it fills
	if sig == _shown:
		return
	_shown = sig
	_fill.text = "%s %d / %d" % [what, used, cap]
	if UI.text_width(_fill, _fill.text) > _fill.size.x:
		_fill.text = "%d / %d" % [used, cap]
	var bars: bool = fixed_kind == ""
	for k in range(_kind_buttons.size()):
		_kind_buttons[k].visible = bars
		UI.style_button(_kind_buttons[k], k == kind)
	for r in range(_rarity_buttons.size()):
		UI.style_button(_rarity_buttons[r], r - 1 == rarity)
	_sort_button.text = "↕ %s" % SORTS[sort]
	_many_button.visible = can_many
	_many_button.text = "Select" if not many else "Single"
	UI.style_button(_many_button, false, "good" if many else "")
	var worth := 0
	var cells := 0
	for id in chosen:
		worth += sim.sell_price(_item(id))
		cells += Items.size(_item(id))
	_sell_button.visible = many
	_sell_button.text = ("Ditch %d: %d cell%s" % [chosen.size(), cells, "" if cells == 1 else "s"]) if ditching else ("Sell %d: %s" % [chosen.size(), Fmt.money(worth)])
	_sell_button.disabled = chosen.is_empty()
	# pack the items first-fit into the columns, never across a page's edge
	_placed = _pack(items, page_rows)
	var reach := 0
	for id in _placed:
		var r: Rect2i = _placed[id]
		reach = maxi(reach, (r.position.y + r.size.y - 1) * COLS + r.position.x + r.size.x)
	# the outlines are the container: exactly `cap` cells, or as far as the
	# packing reached when it had to go further, so every item sits on an outline
	var shown_cells := maxi(cap, reach)
	var pages := maxi(1, ceili(float(ceili(float(shown_cells) / COLS)) / page_rows))
	page = clampi(page, 0, pages - 1)
	for k in range(_outlines.size()):
		var cell_index := page * page_rows * COLS + k
		_outlines[k].visible = cell_index < shown_cells and k < page_rows * COLS
	_page_label.text = "%d/%d" % [page + 1, pages]
	_page_prev.disabled = page == 0
	_page_next.disabled = page >= pages - 1
	var k := 0
	var top := page * page_rows
	for it in items:
		var r: Rect2i = _placed[it["id"]]
		if r.position.y < top or r.position.y >= top + page_rows:
			continue
		var c := _cell(k)
		c.visible = true
		c.position = Vector2(r.position.x * (CELL + GAP), GRID_Y + (r.position.y - top) * (CELL + GAP))
		c.show_item(it, (it["id"] in chosen) if many else it["id"] == selected)
		k += 1
	while k < _cells.size():
		_cells[k].visible = false
		_cells[k].id = -1
		k += 1


## First-fit: each item in order takes the first free place, scanning rows
## then columns, that holds its footprint without crossing a page edge.
## Returns id -> Rect2i in cells.
static func _pack(list: Array, rows_a_page: int) -> Dictionary:
	var taken := {}        # Vector2i -> true
	var out := {}
	for it in list:
		var f := Items.footprint(it)
		var w := mini(f.x, COLS)
		var h := f.y
		var y := 0
		var placed := false
		while not placed:
			if h <= rows_a_page and (y / rows_a_page) != ((y + h - 1) / rows_a_page):
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
					placed = true
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
			_cells[k].force_drag({"id": id, "src": drag_src}, drag_preview(_item(id)))


## What rides under the mouse during a drag: the item's picture if it has
## one, its name if not.
static func drag_preview(it: Dictionary) -> Control:
	var tex := Items.art(it)
	if tex != null and not it.is_empty():
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var f := Items.footprint(it)
		t.size = Vector2(ItemCell.px(f.x), ItemCell.px(f.y))
		t.modulate = Color(1, 1, 1, 0.85)
		return t
	var preview := Label.new()
	preview.text = it.get("base", "")
	preview.add_theme_font_override("font", UI.font("SemiBold"))
	preview.add_theme_font_size_override("font_size", Pal.FLOOR)
	preview.add_theme_color_override("font_color", Pal.TEXT)
	return preview


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("src", "") in accepts


func _drop_data(_at: Vector2, data: Variant) -> void:
	dropped.emit(data)


# ------------------------------------------------------------------ acting

func _pick(k: int) -> void:
	var id: int = _cells[k].id
	if id < 0:
		return
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


func _sell_chosen() -> void:
	for id in chosen.duplicate():
		var it := _item(id)
		if not it.is_empty():
			if ditching:
				sim.ditch(id)
			else:
				sim.sell(it)
	chosen = []
	acted.emit()


## For the tests: every label and visible button with text.
func text_nodes() -> Array:
	var out: Array = [_fill, _sort_button, _many_button, _page_label]
	if _sell_button.visible:
		out.append(_sell_button)
	for b in _kind_buttons:
		if b.visible:
			out.append(b)
	out.append_array(_rarity_buttons)
	for c in _cells:
		if c.visible:
			out.append_array(c.text_nodes())
	return out
