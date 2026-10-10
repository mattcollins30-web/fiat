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
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")
const Inventory := preload("res://scripts/ui/inventory.gd")

## The loadout (10 Oct, Runner-R A; Matt: the Runner "hasn't changed since the first version"): the figure in its
## light in the middle, each slot a card of one size down either side - the weapons, the charm and what's worn on
## the left, the helmet over the armour, the rig and the pack on the right (Matt's order) - each card saying its
## slot, the item's name and its one figure, edged in its rarity. A card takes a drop of its own slot only; press
## it to pick it; drag the item off to the stash.
const CARD_W := 198
const CARD_H := 119
const CARD_GAP := 8
const PAD := 8
const ART_INSET := 3                           # the art over the whole card, inside its line
const LEFT := ["Primary", "Secondary", "Charm"]               # the fourth place down the left is what's worn
const RIGHT := ["Helmet", "Armour", "Rig", "Backpack"]
const WIDTH := Inventory.SIDE_W    # 608
const HEIGHT := 648                            # the column (the pack's map went, 10 Oct: 516 → 648); each card its own height, below
const GLASS := Pal.PANEL
const FIGURE := Color(Pal.CARD_LINE, 0.7)      # the runner, flat, until art/body.png is made
const FIGURE_X := PAD + LEFT_W + (WIDTH - 2 * PAD - LEFT_W - RIGHT_W) / 2     # between the columns: 262..442
const FIGURE_W := 180
const FIGURE_H := 488
const FIGURE_Y := (HEIGHT - FIGURE_H) / 2
const BODY_ART := "res://art/body.png"         # a drawn figure, 180 x 488, drawn at its own pixels like the items, takes the flat one's place
## The backdrop (10 Oct, Kit-B): the painted kit room at 40%, dark at the edges, the cards as glass over it (Matt,
## 10 Oct: "add the art we have for that screen back in"); the drawn cone of light while the file is missing.
const BACKDROP_PLACE := "The kit room"         # art/places/the_kit_room.png
const BACKDROP_ALPHA := 0.4
const GLASS_ALPHA := 0.8
var _figure: TextureRect
var backdrop: Control                          # under everything: the art, or the light
var _backdrop_art: TextureRect
var _vignette: TextureRect
var _frame: Panel
var _flat: Control                             # the flat figure's layer, over the backdrop, when art/body.png is missing
var _worn: Panel                               # the fourth place down the left: what's worn, its worth
var _worn_head: Label
var _worn_value: Label
var _worn_line: Label

var sim
var selected := ""                 # the slot picked, or ""
var _boxes := {}                   # slot -> {zone, outline, name, cell, item: [Label, Label], fig}
var _press_at := Vector2.ZERO
var _press_slot := ""
var _shown := ""


## A slot's card: its column, its place down it.
## Each card sized for its gear (Matt, 10 Oct: "make the boxes fit for the gear type ... show off the great art"):
## the weapons' column wide for a gun's length, the worn column narrow for a jacket's height; each card's height by
## its gear's shape - an armour or a pack tall, a rig short, a helmet near square.
const LEFT_W := 246
const RIGHT_W := 150
const HEIGHTS := {"Primary": 150, "Secondary": 140, "Charm": 170, "Helmet": 140, "Armour": 204, "Rig": 118, "Backpack": 146}
const WORN_H := HEIGHT - 2 * PAD - 3 * CARD_GAP - 150 - 140 - 170     # what the left column leaves: 148


static func card_rect(slot: String) -> Rect2:
	var right: bool = slot in RIGHT
	var col: Array = RIGHT if right else LEFT
	var y: float = PAD
	for s in col:
		if s == slot:
			break
		y += HEIGHTS[s] + CARD_GAP
	return Rect2(WIDTH - PAD - RIGHT_W if right else PAD, y, RIGHT_W if right else LEFT_W, HEIGHTS[slot])


static func worn_rect() -> Rect2:
	return Rect2(PAD, HEIGHT - PAD - WORN_H, LEFT_W, WORN_H)


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
		_figure.position = Vector2(FIGURE_X - FIGURE_W / 2, FIGURE_Y)
		_figure.size = Vector2(FIGURE_W, FIGURE_H)
		add_child(_figure)
	for slot in Data.SLOTS:
		var r := card_rect(slot)
		var zone := Control.new()
		zone.position = r.position
		zone.size = r.size
		zone.mouse_filter = Control.MOUSE_FILTER_STOP
		zone.set_drag_forwarding(Callable(), _can_drop.bind(slot), _drop.bind(slot))
		zone.gui_input.connect(_zone_input.bind(slot))
		add_child(zone)
		var outline := UI.panel(zone, Rect2(Vector2.ZERO, r.size), UI.box(_glass(), 6, 1, Pal.CARD_LINE))
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# the item's art fills the card, loud (Matt, 10 Oct: as Runner-R B - "the art showing loud and proud"); the
		# slot's name and the item's figure sit over it, top left and bottom right, with a shadow
		var cell := ItemCell.new()
		cell.glass = true
		cell.visible = false
		cell.position = Vector2(ART_INSET, ART_INSET)
		cell.pressed.connect(_pick.bind(slot))
		cell.gui_input.connect(_cell_input.bind(slot))
		cell.set_drag_forwarding(Callable(), _can_drop.bind(slot), _drop.bind(slot))
		zone.add_child(cell)
		var name := UI.label(zone, Rect2(10, 4, r.size.x - 20, 20), slot.to_upper(), "SemiBold", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		var item: Array = []                     # "Empty" on an empty card; a full one's name is the art's (and its tooltip)
		for i in range(3):
			item.append(UI.label(zone, Rect2(10, r.size.y / 2.0 - 20 + i * 20, r.size.x - 20, 20), "", "SemiBold", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, false))
		var fig := UI.label(zone, Rect2(10, r.size.y - 28, r.size.x - 20, 24), "", "SemiBold", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
		for l in [name, item[0], item[1], item[2], fig]:
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			l.set_meta("over_art", true)          # a caption over the card's art, drawn above it: the button-clear check lets it be
			UI.shadow(l)
		_boxes[slot] = {"zone": zone, "outline": outline, "name": name, "cell": cell, "item": item, "fig": fig}
	var wr := worn_rect()
	_worn = UI.panel(self, wr, UI.box(Color(Pal.BG, GLASS_ALPHA), 6, 1, Pal.CARD_LINE))
	_worn_head = UI.label(_worn, Rect2(10, 4, wr.size.x - 20, 20), "WORN", "SemiBold", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_worn_value = UI.label(_worn, Rect2(10, 28, wr.size.x - 20, 36), "", "SemiBold", Pal.LINE, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_worn_line = UI.label(_worn, Rect2(10, wr.size.y - 34, wr.size.x - 20, 24), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)


## The cards' fill: glass over the backdrop.
static func _glass() -> Color:
	return Color(GLASS, GLASS_ALPHA)


## Whether the painted kit room shows; else the drawn light.
func has_backdrop_art() -> bool:
	return _backdrop_art.visible


## The drawn light, while the kit room's art is missing: a cone of cold light from above onto the figure, a shadow
## at its feet.
func _draw_backdrop() -> void:
	if _backdrop_art.visible:
		return
	var x := float(FIGURE_X)
	var top := 0.0
	var foot := float(FIGURE_Y + FIGURE_H) - 6.0
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


## The runner as a flat silhouette between the columns, until art/body.png is made.
func _draw_flat(c: Control) -> void:
	if _figure != null:
		return
	var x := float(FIGURE_X)
	var y0 := float(FIGURE_Y)
	c.draw_circle(Vector2(x, y0 + 40), 34.0, FIGURE)
	c.draw_rect(Rect2(x - 12, y0 + 70, 24, 20), FIGURE)
	c.draw_rect(Rect2(x - 62, y0 + 90, 124, 160), FIGURE)
	c.draw_circle(Vector2(x - 62, y0 + 104), 14.0, FIGURE)
	c.draw_circle(Vector2(x + 62, y0 + 104), 14.0, FIGURE)
	c.draw_rect(Rect2(x - 88, y0 + 106, 22, 170), FIGURE)
	c.draw_rect(Rect2(x + 66, y0 + 106, 22, 170), FIGURE)
	c.draw_rect(Rect2(x - 56, y0 + 250, 50, 238), FIGURE)
	c.draw_rect(Rect2(x + 6, y0 + 250, 50, 238), FIGURE)


# ------------------------------------------------------------------ showing

## A long item (a gun, a bar: twice as wide as tall or more) lies across the card under the slot's name, the name and
## the figure under it; anything else stands at the card's left (the reviewer, 10 Oct: a rifle in 56 px was a sliver).
static func wide(it: Dictionary) -> bool:
	var f: Vector2i = Items.footprint(it)
	return f.x >= f.y * 2




func _lay_card(b: Dictionary, _across: bool) -> void:
	b["cell"].position = Vector2(ART_INSET, ART_INSET)
	b["cell"].size = b["zone"].size - Vector2(2 * ART_INSET, 2 * ART_INSET)


## A slot's one figure, long to short: what the pick panel compares it by.
static func figure_forms(it: Dictionary) -> Array:
	var slot: String = it["slot"]
	if slot in ["Primary", "Secondary"]:
		var d: float = Items.dps(it)
		var rounds: String = Items.ammo_words(it).trim_prefix("Takes ").to_lower()
		return ["%.0f dmg/s · %s" % [d, rounds], "%.0f dmg/s" % d]
	if slot in ["Helmet", "Armour"]:
		return ["%.0f armour" % Items.armour(it)]
	if slot == "Backpack":
		return ["%d cells" % Items.capacity(it)]
	if slot == "Rig":
		var n: int = Items.capacity(it)
		return ["%d pouch%s" % [n, "" if n == 1 else "es"]]
	return [Items.rarity_name(it)]


func show_state(s) -> void:
	sim = s
	var sig := selected
	for slot in Data.SLOTS:
		var w = sim.equipped[slot]
		# what's worn can change in place (a Workshop job, a part fitted, the Fence's prices): its figure, its rarity
		# and its worth are in the signature, not just its id (the reviewer, 10 Oct)
		sig += "|" + ("%d:%d:%d:%s:%d:%s" % [w["id"], int(w["rarity"]), w["affixes"].size(), figure_forms(w)[0], int(sim.sell_price(w)), str(w.get("attachments", {}).keys())] if w != null else "-")
	if sig == _shown:
		return
	_shown = sig
	var worth := 0
	var filled := 0
	for slot in Data.SLOTS:
		var b: Dictionary = _boxes[slot]
		var it = sim.equipped[slot]
		var on: bool = selected == slot
		var edge: Color = Pal.ACCENT if on else (Pal.CARD_LINE if it == null else Pal.tone_color(Pal.item_tone(it)).darkened(0.15))
		if it == null and slot == "Primary" and not on:
			edge = Pal.BAD                                   # nothing to fight with
		b["outline"].add_theme_stylebox_override("panel", UI.box(_glass(), 6, 2 if on else 1, edge))
		if it == null:
			_lay_card(b, false)
			b["cell"].visible = false
			b["cell"].id = -1
			b["item"][0].text = "Empty"
			b["item"][0].add_theme_color_override("font_color", Pal.TEXT_3)
			b["item"][1].text = ""
			b["item"][2].text = ""
			UI.fit(b["fig"], ["drop one here", "empty"] if slot != "Primary" else ["nothing to fight with", "no gun", ""])
			b["fig"].add_theme_color_override("font_color", Pal.BAD if slot == "Primary" else Pal.TEXT_3)
		else:
			filled += 1
			worth += int(sim.sell_price(it))
			b["cell"].visible = true
			_lay_card(b, wide(it))
			b["cell"].show_item(it, on, b["cell"].size)
			for l in b["item"]:
				l.text = ""
			b["cell"].tooltip_text = "%s · %s" % [Items.full_name(it), figure_forms(it)[0]]
			UI.fit(b["fig"], figure_forms(it))
			b["fig"].add_theme_color_override("font_color", Pal.ACCENT if slot in ["Primary", "Secondary"] else Pal.TEXT)
	_worn_value.text = Fmt.money(worth)
	UI.fit(_worn_line, ["%d of %d slots filled · at the Fence" % [filled, Data.SLOTS.size()], "%d of %d filled" % [filled, Data.SLOTS.size()]])


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
		out.append(b["name"])
		for l in b["item"] + [b["fig"]]:
			if l.text != "":
				out.append(l)
		out.append_array(b["cell"].text_nodes())
	out.append_array([_worn_head, _worn_value, _worn_line])
	return out


## A press on the card, not on its picture: the card picks its slot.
func _zone_input(event: InputEvent, slot: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_pick(slot)


## For the tests: the slot box's rect, in this panel.
func box_rect(slot: String) -> Rect2:
	var z: Control = _boxes[slot]["zone"]
	return Rect2(z.position, z.size)
