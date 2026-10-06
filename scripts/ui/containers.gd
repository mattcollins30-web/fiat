extends Control
## The rig and the pack under the body in the Lock-up. The rig is its
## pouches, a 64 px cell each (meds and rounds, a slot a pouch whatever
## the item's own footprint), drawn through item_cell.gd like everything
## else; it takes drops from the stash and gives drags back to it, and a
## press on a pouch selects what's in it. The pack is its cells drawn empty
## at half size: a map of the capacity a run packs into (the run screen's
## grid is where that packing shows), nothing goes out in it here.
## Signals: `picked(id)` for a pouch, `take(id)` and `leave(id)` for drops.

signal picked(id: int)
signal take(id: int)
signal leave(id: int)

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
const PACK_MAX := 80               # the biggest pack (72) with Pack horse (+6) is 78
const PACK_SIZES := [64, 48, 40, 32, 24, 16]   # the biggest of these that fits the room
const BLOCK_GAP := 8
const HEIGHT := 296                # what the Lock-up has under the body

var sim
var selected := -1
var _rig_label: Label
var _pack_label: Label
var _rig_outlines: Array = []
var _rig_cells: Array = []         # ItemCells, one a pouch
var _pack_outlines: Array = []
var _rig_zone: Control             # the drop target over the rig's rows
var _press_at := Vector2.ZERO
var _press_cell := -1
var _shown := ""


static func _rig_at(k: int) -> Vector2:
	return Vector2((k % RIG_COLS) * (Pal.CELL + Pal.CELL_GAP), (k / RIG_COLS) * (Pal.CELL + Pal.CELL_GAP))


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
	_pack_label = UI.label(self, Rect2(0, 0, WIDTH, LABEL_H), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(PACK_MAX):
		var o := UI.panel(self, Rect2(0, 0, Pal.CELL, Pal.CELL), UI.box(Color.TRANSPARENT, 6, 1, Pal.CARD_LINE))
		o.visible = false
		o.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pack_outlines.append(o)


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
	for k in range(RIG_MAX):
		_rig_outlines[k].visible = k < cap
	# a pouch a cell: an item spans as many as its cells, along the row, never across a row's end
	var pos := 0
	var last := 0
	for k in range(RIG_MAX):
		var c = _rig_cells[k]
		if k < sim.rig.size():
			var it: Dictionary = sim.rig[k]
			var w: int = mini(Items.size(it), RIG_COLS)
			if pos % RIG_COLS + w > RIG_COLS:
				pos += RIG_COLS - pos % RIG_COLS
			c.visible = true
			c.position = _rig_at(pos)
			c.show_item(it, it["id"] == selected, Vector2(w * Pal.CELL + (w - 1) * Pal.CELL_GAP, Pal.CELL))
			pos += w
			last = pos
		else:
			c.id = -1
			c.visible = false
	# the rig takes a row, or two for the biggest; the pack gets the rest at
	# the biggest cell that fits its capacity in it
	var rig_rows := maxi(1, ceili(float(maxi(cap, last)) / RIG_COLS))   # a smaller rig fitted keeps what's carried showing
	_rig_zone.size.y = rig_rows * (Pal.CELL + Pal.CELL_GAP) - Pal.CELL_GAP
	var pack_label_y: float = RIG_Y + _rig_zone.size.y + BLOCK_GAP
	_pack_label.position.y = pack_label_y
	var pack_y: float = pack_label_y + LABEL_H + 2
	var avail: float = HEIGHT - pack_y
	var pcap: int = mini(sim.capacity(), PACK_MAX)
	var cell := PACK_SIZES.back() as int
	var gap := 2
	var cols := 1
	for c in PACK_SIZES:
		var g: int = 6 if c >= 48 else (4 if c >= 32 else 2)
		var n: int = (ROW_W + g) / (c + g)
		var rows := ceili(float(pcap) / n)
		if rows * (c + g) - g <= avail:
			cell = c
			gap = g
			cols = n
			break
		cols = (ROW_W + g) / (c + g)
	_pack_label.text = "Pack %d cells" % pcap
	for k in range(_pack_outlines.size()):
		var o: Panel = _pack_outlines[k]
		o.visible = k < pcap
		o.position = Vector2((k % cols) * (cell + gap), pack_y + (k / cols) * (cell + gap))
		o.size = Vector2(cell, cell)
		o.add_theme_stylebox_override("panel", UI.box(Color.TRANSPARENT, 6 if cell >= 32 else 3, 1, Pal.CARD_LINE))


# ------------------------------------------------------------------ dragging and dropping

func _can_drop(_at: Vector2, data: Variant) -> bool:
	if not (data is Dictionary) or data.get("src", "") != "stash" or sim == null:
		return false
	for it in sim.stash:
		if it["id"] == data["id"]:
			# a pouch free, or rounds that top up a stack already in the rig
			return (Items.is_medical(it) or Items.is_ammo(it)) and (sim.rig_room(Items.size(it)) or sim.rig_tops_up(it))
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


## For the tests: the pack's cell size and whether every outline sits inside this control.
func pack_cell() -> float:
	return _pack_outlines[0].size.x


func pack_inside() -> bool:
	var me := Rect2(Vector2.ZERO, size)
	for o in _pack_outlines:
		if o.visible and not me.encloses(Rect2(o.position, o.size)):
			return false
	return true


## For the tests: the labels with text.
func text_nodes() -> Array:
	var out: Array = [_rig_label, _pack_label]
	for c in _rig_cells:
		if c.visible:
			out.append_array(c.text_nodes())
	return out
