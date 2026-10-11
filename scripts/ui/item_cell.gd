extends Button
## One item as a cell: a button the size of the item's footprint (64 px a
## cell, 6 px gaps), its rarity the border's colour, carrying the item's
## picture if art/items/<slug>.png has been made and short words if not. The
## grids, the body's slots and the rig's pouches all draw items through this,
## so an item looks the same wherever it is. The owner wires the press and
## the drag.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Items := preload("res://scripts/sim/items.gd")

const SHORT := {"Primary": "PRI", "Secondary": "SEC", "Helmet": "HLM", "Armour": "ARM", "Rig": "RIG", "Backpack": "PCK",
	"Medical": "MED", "Attachment": "ATT", "Ammo": "AMO", "Paper": "PPR", "Charm": "CHM", "Grenade": "GRN"}
const INSET := 3                   # the picture sits inside the border

var id := -1
var glass := false                 # over a backdrop (10 Oct, Kit-B): the fill lets a fifth of it through
var _art: TextureRect
var _lines: Array[Label] = []      # up to three, laid out by the footprint
var _corner: Label                 # over the picture: an ammo stack's rounds
var _up: Label                     # the upgrade's arrow (11 Oct): top right, on a dark disc so it reads over any art
const UP := 18                     # the arrow's disc
const UP_NUDGE := 6                # a one-row cell's words, moved down out of the arrow's corner
var _nudged := false


func _init() -> void:
	text = ""
	focus_mode = Control.FOCUS_ALL
	_art = TextureRect.new()
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_art.visible = false
	add_child(_art)
	for i in range(3):
		var l := UI.label(self, Rect2(0, 0, Pal.CELL, 20), "", "SemiBold" if i == 0 else "Medium", Pal.CELL_TEXT,
			Pal.TEXT if i < 2 else Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, i != 0)
		l.visible = false
		_lines.append(l)
	_corner = UI.label(self, Rect2(0, 0, Pal.CELL, 18), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	_corner.visible = false
	_up = UI.label(self, Rect2(0, 0, UP, UP), "▲", "SemiBold", 11, Pal.GOOD, HORIZONTAL_ALIGNMENT_CENTER)
	_up.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_up.add_theme_stylebox_override("normal", UI.box(Color(Pal.BG, 0.85), UP / 2, 1, Pal.GOOD))
	_up.visible = false


## The upgrade's arrow on or off: better than what's worn in its slot (sim.is_upgrade). Off by default, so the
## body's slots and the rig never show one; the grids that hold spares set it.
func set_upgrade(on: bool) -> void:
	_up.visible = on
	_up.position = Vector2(size.x - UP - 2, 2)
	_up.move_to_front()
	# no picture and one row: the words sit high enough to meet the arrow, so they drop a little (once a show)
	if on and not _nudged and not _art.visible and size.y < 100.0:
		_nudged = true
		for l in _lines:
			if l.visible:
				l.position.y += UP_NUDGE


## Pixels a footprint of so many cells spans, gaps included.
static func px(cells: int) -> int:
	return cells * Pal.CELL + (cells - 1) * Pal.CELL_GAP


static func rarity_tone(it: Dictionary) -> String:
	return Pal.item_tone(it)


## The item, drawn: the cell takes the footprint's size, or `box` when given
## (a body slot fills its box whatever is in it; a rig pouch is one cell).
func show_item(it: Dictionary, on: bool, box := Vector2.ZERO) -> void:
	id = it["id"]
	_up.visible = false
	_nudged = false
	var f := Items.footprint(it)
	size = box if box != Vector2.ZERO else Vector2(px(f.x), px(f.y))
	# the words are laid out by the room there is, in cells
	f = Vector2i(maxi(1, roundi((size.x + Pal.CELL_GAP) / (Pal.CELL + Pal.CELL_GAP))), maxi(1, roundi((size.y + Pal.CELL_GAP) / (Pal.CELL + Pal.CELL_GAP))))
	_style(on, rarity_tone(it))
	var tex := Items.art(it)
	for l in _lines:
		l.visible = false
	_corner.visible = false
	if tex != null:
		_art.visible = true
		_art.texture = tex
		_art.position = Vector2(INSET, INSET)
		_art.size = size - Vector2(2 * INSET, 2 * INSET)
		# pixel art at its own pixels when it fits (a footprint's picture always
		# does: 64 a cell, the cell 64 plus the gaps); only a bigger one is scaled
		var fits: bool = tex.get_width() <= _art.size.x and tex.get_height() <= _art.size.y
		_art.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED if fits else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if Items.is_ammo(it) or (Items.is_socketable(it) and int(it.get("count", 1)) > 1):
			_corner.text = ("%d" % int(it["rounds"])) if Items.is_ammo(it) else ("×%d" % int(it["count"]))
			var small: bool = size.y < 44.0               # a shrunk pouch (a full rig): the count smaller, "1.2k" past 999
			var tiny: bool = size.x < 34.0                # the smallest pouches: 9 px, whole thousands
			_corner.add_theme_font_size_override("font_size", (9 if tiny else 11) if small else Pal.CELL_TEXT)
			var n: int = int(it["rounds"]) if Items.is_ammo(it) else int(it["count"])
			if small and n >= 1000:
				_corner.text = "%.1fk" % (n / 1000.0) if (n < 10000 and not tiny) else "%dk" % (n / 1000)
			# a small pouch: the count laid over the whole cell, bottom right (a label won't go under its font's line height)
			_corner.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM if small else VERTICAL_ALIGNMENT_CENTER
			_corner.position = Vector2(0, 0 if small else size.y - 20)
			_corner.size = Vector2(size.x - 2, size.y if small else 18)
			_corner.visible = true
		return
	_art.visible = false
	_words(it, f)


## No picture: the words that stand in for it, by how much room there is.
## One cell: two short lines. A row: a name line and a figure line. Taller:
## name, figure, tier and rarity.
func _words(it: Dictionary, f: Vector2i) -> void:
	var h := Items.headline(it)
	var big: bool = f.y >= 2
	var fs := Pal.CELL_TEXT_BIG if big else Pal.CELL_TEXT
	var line_h := 22 if big else 20
	var words: Array = []
	if f.x == 1 and f.y == 1:
		words = [SHORT[it["slot"]], ("%d" % int(it["rounds"])) if Items.is_ammo(it) else (("×%d" % int(it["count"])) if Items.is_socketable(it) and int(it.get("count", 1)) > 1 else h[0])]
	else:
		words = [Items.full_name(it) if it.has("piece") else it["base"], ("%d rounds" % int(it["rounds"])) if Items.is_ammo(it) else "%s %s" % [h[0], h[1]]]
		if big:
			words.append("T%d · %s" % [it["tier"], Items.rarity_name(it)])
	if size.x < 44.0 or size.y < 44.0:     # a small pouch either way (10 Oct: a two-pouch kit at 28 px tall spilled its two lines)
		# a small pouch (the run's rig two rows deep): the slot's short word alone, small
		words = [words[0] if f.x > 1 else SHORT[it["slot"]]]
		fs = 11 if size.x >= 26.0 else 8          # the smallest pouch (22 px): the short word at 8
		line_h = 14 if size.x >= 26.0 else 10
	var y := (size.y - words.size() * line_h) / 2.0
	for i in range(words.size()):
		var l := _lines[i]
		l.add_theme_font_size_override("font_size", fs)
		l.position = Vector2(2, y + i * line_h)
		l.size = Vector2(size.x - 4, line_h)
		l.visible = true
		var options: Array = [words[i]]
		if i == 0:
			options.append(SHORT[it["slot"]])
		elif i == 1:
			options.append(h[0] if not Items.is_ammo(it) else "%d" % int(it["rounds"]))
		else:
			options.append("T%d" % it["tier"])
		# fit() takes the last option even when it doesn't fit; the tests then
		# say so, which is the point - a cell that can't carry its words needs
		# shorter words, not an ellipsis
		UI.fit(l, options)


func _style(on: bool, tone: String) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var fill: Color = Pal.SELECT if on else (Pal.CARD if state == "hover" else Pal.PANEL)
		var sb := UI.box(Color(fill, 0.8) if glass and not on else fill, 6)
		if on:
			sb.set_border_width_all(2)
			sb.border_color = Pal.PICK
		elif tone != "":
			sb.set_border_width_all(2)
			sb.border_color = Pal.tone_color(tone)
		add_theme_stylebox_override(state, sb)
	add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 6, 2, Pal.TEXT))


## For the tests: the labels showing.
func text_nodes() -> Array:
	var out: Array = []
	if not visible:
		return out
	for l in _lines:
		if l.visible and l.text != "":
			out.append(l)
	if _corner.visible:
		out.append(_corner)
	if _up.visible:
		out.append(_up)
	return out
