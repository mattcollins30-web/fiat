extends Control
## The body: the runner's six slots as boxes you drag gear onto, laid out as
## a figure - helmet and the secondary down the left, armour in the middle,
## the rig and the backpack down the right, the primary along the bottom.
## Each box is the slot's largest footprint and takes a drop only of its own
## slot: armour onto Armour fits, armour onto Primary is refused. What's
## fitted fills its box whatever its own footprint (a short gun fills the
## long gun's box; the picture keeps its aspect inside); drag it off and it
## goes back to the stash; press it to select it. Signals:
## `picked(slot)`, `equip(id)` for a drop, `unequip(slot)` is the owner's
## from a drop on the stash.

signal picked(slot: String)
signal equip(id: int)

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")
const Inventory := preload("res://scripts/ui/inventory.gd")

## Where each slot's box sits and how many cells it spans - the biggest
## footprint any base of the slot has, so every item of the slot fits in it.
## A paper doll: the figure stands in the middle, the boxes either side of it
## - helmet, secondary and backpack down the left, armour and rig down the
## right, the primary along the bottom under all three.
const BOXES := {
	"Helmet": {"at": Vector2i(0, 0), "cells": Vector2i(2, 2)},
	"Secondary": {"at": Vector2i(0, 142), "cells": Vector2i(2, 1)},
	"Backpack": {"at": Vector2i(0, 214), "cells": Vector2i(3, 4)},
	"Armour": {"at": Vector2i(400, 0), "cells": Vector2i(3, 4)},
	"Rig": {"at": Vector2i(400, 282), "cells": Vector2i(3, 2)},
	"Primary": {"at": Vector2i(0, 496), "cells": Vector2i(5, 1)},
	"Charm": {"at": Vector2i(356, 496), "cells": Vector2i(1, 1)},    # the one cell kept for luck, beside the primary
}
const WIDTH := Inventory.SIDE_W    # 608; the boxes span 604
const HEIGHT := 560
const GLASS := Pal.PANEL
const FIGURE := Color(Pal.CARD_LINE, 0.7)      # the runner, flat, until art/body.png is made
const FIGURE_X := 302                          # between the columns: 212..392
const FIGURE_W := 180
const FIGURE_H := 488                          # down to the primary's box
const BODY_ART := "res://art/body.png"         # a drawn figure, 180 x 488, drawn at its own pixels like the items, takes the flat one's place
## The backdrop (10 Oct, Kit-B; Matt: "a semi transparent backdrop ... behind the character model / gear slot
## selection"): A, a painted lock-up wall at about 40%, dark at the edges, the slots as glass; B, while the art is
## missing, a cone of cold light from above and a shadow at the feet, drawn here.
const BACKDROP_PLACE := "The kit room"         # art/places/the_kit_room.png (the rooms manifest)
const BACKDROP_ALPHA := 0.4
const GLASS_ALPHA := 0.8
var _figure: TextureRect
var backdrop: Control                          # under everything: the art, or the light
var _backdrop_art: TextureRect
var _vignette: TextureRect
var _frame: Panel
var _flat: Control                             # the flat figure's layer, over the backdrop, when art/body.png is missing

var sim
var selected := ""                 # the slot picked, or ""
var _boxes := {}                   # slot -> {zone, outline, name, cell}
var _press_at := Vector2.ZERO
var _press_slot := ""
var _shown := ""


func _init() -> void:
	size = Vector2(WIDTH, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	backdrop = Control.new()
	backdrop.size = size
	backdrop.clip_contents = true
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.draw.connect(_draw_backdrop)
	add_child(backdrop)
	_backdrop_art = TextureRect.new()
	_backdrop_art.size = size
	_backdrop_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_backdrop_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop_art.texture = UI.place_texture(BACKDROP_PLACE)
	_backdrop_art.visible = _backdrop_art.texture != null
	_backdrop_art.modulate = Color(1, 1, 1, BACKDROP_ALPHA)
	backdrop.add_child(_backdrop_art)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(Pal.BG, 0.0), Color(Pal.BG, 0.25), Color(Pal.BG, 0.95)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.45)
	gt.fill_to = Vector2(1.05, 1.05)
	gt.width = 64
	gt.height = 64
	_vignette = TextureRect.new()
	_vignette.texture = gt
	_vignette.size = size
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.visible = _backdrop_art.visible
	backdrop.add_child(_vignette)
	_frame = UI.panel(self, Rect2(Vector2.ZERO, size), UI.box(Color.TRANSPARENT, 8, 1, Pal.CARD_LINE))
	_flat = Control.new()
	_flat.size = size
	_flat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flat.draw.connect(func(): _draw_flat(_flat))
	add_child(_flat)
	if ResourceLoader.exists(BODY_ART) or FileAccess.file_exists(BODY_ART):
		_figure = TextureRect.new()
		_figure.texture = load(BODY_ART) if ResourceLoader.exists(BODY_ART) else ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(BODY_ART)))
		_figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_figure.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_figure.position = Vector2(FIGURE_X - FIGURE_W / 2, 0)
		_figure.size = Vector2(FIGURE_W, FIGURE_H)
		add_child(_figure)
	for slot in Data.SLOTS:
		var b: Dictionary = BOXES[slot]
		var w := ItemCell.px(b["cells"].x)
		var h := ItemCell.px(b["cells"].y)
		var zone := Control.new()
		zone.position = Vector2(b["at"])
		zone.size = Vector2(w, h)
		zone.mouse_filter = Control.MOUSE_FILTER_PASS
		zone.set_drag_forwarding(Callable(), _can_drop.bind(slot), _drop.bind(slot))
		add_child(zone)
		var outline := UI.panel(zone, Rect2(0, 0, w, h), UI.box(_glass(), 6, 1, Pal.CARD_LINE))
		var inset := 8 if b["cells"].x > 1 else 5          # the charm's one cell: "Charm" is 52 px of 64
		var name := UI.label(zone, Rect2(inset, 0, w - 2 * inset, h), slot, "SemiBold", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		name.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		name.position.y = 4
		name.size.y = 20
		var cell := ItemCell.new()
		cell.glass = true
		cell.visible = false
		cell.pressed.connect(_pick.bind(slot))
		cell.gui_input.connect(_cell_input.bind(slot))
		cell.set_drag_forwarding(Callable(), _can_drop.bind(slot), _drop.bind(slot))
		zone.add_child(cell)
		_boxes[slot] = {"zone": zone, "outline": outline, "name": name, "cell": cell}


## The slots' fill: glass over the backdrop.
static func _glass() -> Color:
	return Color(GLASS, GLASS_ALPHA)


## Whether the painted backdrop shows (A); else the drawn light (B).
func has_backdrop_art() -> bool:
	return _backdrop_art.visible


## B, the drawn light: a cone of cold light from above onto the figure, and a shadow at its feet - only while the
## art (A) is missing.
func _draw_backdrop() -> void:
	if _backdrop_art.visible:
		return
	var x := float(FIGURE_X)
	var top := 0.0
	var foot := float(FIGURE_H) - 6.0
	var light := Color(0.42, 0.5, 0.62)
	var steps := 14
	for k in range(steps):
		var t: float = float(k) / float(steps)
		var a: float = 0.11 * (1.0 - t)
		var half_top: float = 30.0 + 24.0 * t
		var half_foot: float = 120.0 + 40.0 * t
		backdrop.draw_colored_polygon(PackedVector2Array([Vector2(x - half_top, top), Vector2(x + half_top, top), Vector2(x + half_foot, foot), Vector2(x - half_foot, foot)]), Color(light, a / 2.0))
	backdrop.draw_set_transform(Vector2(x, foot), 0.0, Vector2(1.0, 0.22))
	for k in range(6):
		backdrop.draw_circle(Vector2.ZERO, 120.0 - k * 14.0, Color(light, 0.035))
	for k in range(5):
		backdrop.draw_circle(Vector2.ZERO, 74.0 - k * 10.0, Color(0, 0, 0, 0.09))
	backdrop.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The runner as a flat silhouette between the columns - head, shoulders,
## arms, legs - so the column reads as a body and the boxes as what's on it.
## Drawn on its own layer over the backdrop (the light or the wall under it); art/body.png replaces it.
func _draw_flat(c: Control) -> void:
	if _figure != null:
		return
	var x := float(FIGURE_X)
	c.draw_circle(Vector2(x, 40), 34.0, FIGURE)
	c.draw_rect(Rect2(x - 12, 70, 24, 20), FIGURE)                       # neck
	c.draw_rect(Rect2(x - 62, 90, 124, 160), FIGURE)                     # torso
	c.draw_circle(Vector2(x - 62, 104), 14.0, FIGURE)                    # shoulders, rounded
	c.draw_circle(Vector2(x + 62, 104), 14.0, FIGURE)
	c.draw_rect(Rect2(x - 88, 106, 22, 170), FIGURE)                     # arms
	c.draw_rect(Rect2(x + 66, 106, 22, 170), FIGURE)
	c.draw_rect(Rect2(x - 56, 250, 50, 238), FIGURE)                     # legs
	c.draw_rect(Rect2(x + 6, 250, 50, 238), FIGURE)


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	var sig := selected
	for slot in Data.SLOTS:
		sig += "|" + (str(sim.equipped[slot]["id"]) if sim.equipped[slot] != null else "-")
	if sig == _shown:
		return
	_shown = sig
	for slot in Data.SLOTS:
		var b: Dictionary = _boxes[slot]
		var it = sim.equipped[slot]
		var on: bool = selected == slot
		if it == null:
			b["cell"].visible = false
			b["cell"].id = -1
			b["name"].visible = true
			b["name"].text = slot
			b["outline"].add_theme_stylebox_override("panel", UI.box(Pal.SELECT if on else _glass(), 6, 2 if on else 1,
				Pal.ACCENT if on else (Pal.BAD if slot == "Primary" else Pal.CARD_LINE)))
		else:
			b["name"].visible = false
			b["outline"].add_theme_stylebox_override("panel", UI.box(Color.TRANSPARENT, 6, 1, Pal.CARD_LINE))     # the cell is the glass: two layers let nothing through (the review)
			b["cell"].visible = true
			b["cell"].show_item(it, on, b["zone"].size)   # fills the box
			b["cell"].position = Vector2.ZERO


# ------------------------------------------------------------------ dragging and dropping

## A stash item dropped on a slot's box: only its own slot takes it.
func _can_drop(_at: Vector2, data: Variant, slot: String) -> bool:
	if not (data is Dictionary) or data.get("src", "") != "stash" or sim == null or sim.on_mission():
		return false
	for it in sim.stash:
		if it["id"] == data["id"]:
			return it["slot"] == slot and sim.can_equip_item(int(data["id"]))
	return false


func _drop(_at: Vector2, data: Variant, _slot: String) -> void:
	equip.emit(int(data["id"]))


## What's fitted, dragged off: it goes wherever takes a "body" drop - the stash.
func _cell_input(event: InputEvent, slot: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_at = event.position
			_press_slot = slot
		else:
			_press_slot = ""
	elif event is InputEventMouseMotion and _press_slot == slot and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) and event.position.distance_to(_press_at) > 10.0:
		_press_slot = ""
		var it = sim.equipped[slot]
		if it != null:
			_boxes[slot]["cell"].force_drag({"id": it["id"], "src": "body", "slot": slot}, Inventory.drag_preview(it))


func _pick(slot: String) -> void:
	selected = slot
	picked.emit(slot)


## For the tests: the labels showing.
func text_nodes() -> Array:
	var out: Array = []
	for slot in Data.SLOTS:
		var b: Dictionary = _boxes[slot]
		if b["name"].visible:
			out.append(b["name"])
		out.append_array(b["cell"].text_nodes())
	return out


## For the tests: the slot box's rect, in this panel.
func box_rect(slot: String) -> Rect2:
	var z: Control = _boxes[slot]["zone"]
	return Rect2(z.position, z.size)
