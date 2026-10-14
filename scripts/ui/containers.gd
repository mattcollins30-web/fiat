extends Control
## The rig and the pack under the body in the Lock-up. The rig is its
## pouches, a 64 px cell each (meds and rounds, a slot a pouch whatever
## the item's own footprint), drawn through item_cell.gd like everything
## else; it takes drops from the stash and gives drags back to it, and a
## press on a pouch selects what's in it. The pack's empty map went (Matt, 10 Oct: never usable, never full - what
## a run brings goes to the stash; the Backpack card and the strip say its cells).
## Signals: `picked(id)` for a pouch, `take(id)` for drops.

signal picked(id: int)
signal take(id: int)

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")
const Inventory := preload("res://scripts/ui/inventory.gd")

const WIDTH := Inventory.SIDE_W    # 608
const LABEL_H := 22
const RIG_COLS := 8                # 8 × 64 + 7 × 6 = 554
const RIG_MAX := Data.RIG_CAP      # the sim's cap, 24: three full rows
const RIG_Y := LABEL_H + 2
const ROW_W := RIG_COLS * (Pal.CELL + Pal.CELL_GAP) - Pal.CELL_GAP   # 554
## Two rows of full-size pouches fit; a bigger rig, or a full one of wide kits that wraps, takes smaller pouches a
## step at a time until its rows fit (10 Oct: the loadout took the pack's room).
const RIG_SIZES := [[64, 6], [52, 5], [44, 4], [36, 4], [28, 3], [22, 2]]
const HEIGHT := LABEL_H + 2 + 3 * 44 + 2 * 4                  # 164: the label and two rows of full pouches, or three at 44 (a 24-pouch rig)

var sim
var selected := -1
var _rig_label: Label
var _rig_outlines: Array = []
var _rig_cells: Array = []         # ItemCells, one a pouch
var _rig_zone: Control             # the drop target over the rig's rows
var _press_at := Vector2.ZERO
var _press_cell := -1
var _shown := ""
var _rc := Pal.CELL                 # a pouch's size now, and the gap between
var _rg := Pal.CELL_GAP


func _rig_at(k: int) -> Vector2:
	@warning_ignore("integer_division")
	return Vector2((k % RIG_COLS) * (_rc + _rg), (k / RIG_COLS) * (_rc + _rg))


func _init() -> void:
	size = Vector2(WIDTH, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_rig_label = UI.label(self, Rect2(0, 0, WIDTH, LABEL_H), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_rig_zone = Control.new()
	_rig_zone.position = Vector2(0, RIG_Y)
	_rig_zone.size = Vector2(ROW_W, Pal.CELL)
	_rig_zone.mouse_filter = Control.MOUSE_FILTER_PASS
	_rig_zone.set_drag_forwarding(Callable(), _can_drop, _drop)
	add_child(_rig_zone)
	for k in range(RIG_MAX):
		var o := UI.panel(_rig_zone, Rect2(_rig_at(k), Vector2(Pal.CELL, Pal.CELL)), UI.box(Color.TRANSPARENT, 6, 1, Pal.CARD_LINE))
		o.visible = false
		o.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rig_outlines.append(o)
		var c := ItemCell.new()
		c.position = _rig_at(k)
		c.visible = false
		c.pressed.connect(_pick.bind(k))
		c.gui_input.connect(_cell_input.bind(k))
		c.set_drag_forwarding(Callable(), _can_drop, _drop)
		_rig_zone.add_child(c)
		_rig_cells.append(c)


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	var cap: int = sim.med_capacity()
	var sig := "%d|%d|%d|%d" % [cap, sim.capacity(), selected, sim.rig_used()]
	for it in sim.rig:
		sig += ",%d:%d" % [it["id"], Items.stack_size(it)]
	if sig == _shown:
		return
	_shown = sig
	_rig_label.text = ("Rig %d / %d pouches" % [sim.rig_used(), cap]) if cap > 0 else "No rig"
	# a pouch a cell: an item spans as many as its cells, along the row, never across a row's end - laid first in
	# pouch places, so the rows it takes are known before the size is picked
	# first fit (12 Oct, Matt's playtest: a full rig showed an empty pouch where a two-pouch kit wrapped): each item at
	# the first run of free pouches on one row, so a single fills the gap a wide kit left
	var places: Array = []
	var taken := {}
	var last := 0
	for it in sim.rig:
		var w: int = mini(Items.size(it), RIG_COLS)
		var pos := 0
		while true:
			var fits: bool = pos % RIG_COLS + w <= RIG_COLS
			for j in range(w):
				if taken.has(pos + j):
					fits = false
			if fits:
				break
			pos += 1
		for j in range(w):
			taken[pos + j] = true
		places.append([pos, w])
		last = maxi(last, pos + w)
	var rig_rows := maxi(1, ceili(float(maxi(cap, last)) / RIG_COLS))   # a smaller rig fitted keeps what's carried showing
	_rc = RIG_SIZES.back()[0]
	_rg = RIG_SIZES.back()[1]
	for rs in RIG_SIZES:
		if RIG_Y + rig_rows * (rs[0] + rs[1]) - rs[1] <= HEIGHT:
			_rc = rs[0]
			_rg = rs[1]
			break
	# the free pouches' outlines: as many as the rig has free, in the first places nothing sits in
	var free_left: int = maxi(0, cap - sim.rig_used())
	for k in range(RIG_MAX):
		var showing2: bool = taken.has(k)
		if not showing2 and free_left > 0:
			showing2 = true
			free_left -= 1
		_rig_outlines[k].visible = showing2 and k < RIG_MAX
		_rig_outlines[k].position = _rig_at(k)
		_rig_outlines[k].size = Vector2(_rc, _rc)
	for k in range(RIG_MAX):
		var c = _rig_cells[k]
		if k < sim.rig.size():
			var it: Dictionary = sim.rig[k]
			var w: int = places[k][1]
			c.visible = true
			c.position = _rig_at(places[k][0])
			c.show_item(it, it["id"] == selected, Vector2(w * _rc + (w - 1) * _rg, _rc))
		else:
			c.id = -1
			c.visible = false
	_rig_zone.size = Vector2(RIG_COLS * (_rc + _rg) - _rg, rig_rows * (_rc + _rg) - _rg)


## For the tests: the rig's pouch size now.
func rig_cell() -> float:
	return float(_rc)


# ------------------------------------------------------------------ dragging and dropping

func _can_drop(_at: Vector2, data: Variant) -> bool:
	if not (data is Dictionary) or data.get("src", "") != "stash" or sim == null:
		return false
	for it in sim.stash:
		if it["id"] == data["id"]:
			# a pouch free, or rounds that top up a stack already in the rig
			return Items.rig_item(it) and (sim.rig_room(Items.size(it)) or sim.rig_tops_up(it))
	return false


func _drop(_at: Vector2, data: Variant) -> void:
	take.emit(int(data["id"]))


## A pouch dragged away goes back to the stash.
func _cell_input(event: InputEvent, k: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_at = event.position
			_press_cell = k
		else:
			_press_cell = -1
	elif event is InputEventMouseMotion and _press_cell == k and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) and event.position.distance_to(_press_at) > 10.0:
		var id: int = _rig_cells[k].id
		_press_cell = -1
		if id >= 0:
			_rig_cells[k].force_drag({"id": id, "src": "rig"}, Inventory.drag_preview(_item(id)))


func _item(id: int) -> Dictionary:
	for it in sim.rig:
		if it["id"] == id:
			return it
	return {}


func _pick(k: int) -> void:
	var id: int = _rig_cells[k].id
	if id >= 0:
		selected = id
		picked.emit(id)


## For the tests: every pouch inside this control.
func rig_inside() -> bool:
	var me := Rect2(Vector2.ZERO, size)
	for c in _rig_cells:
		if c.visible and not me.encloses(Rect2(_rig_zone.position + c.position, c.size)):
			return false
	return me.encloses(Rect2(_rig_zone.position, _rig_zone.size))


## For the tests: the labels with text.
func text_nodes() -> Array:
	var out: Array = [_rig_label]
	for c in _rig_cells:
		if c.visible:
			out.append_array(c.text_nodes())
	return out
