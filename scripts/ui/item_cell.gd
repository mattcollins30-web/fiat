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
	"Medical": "MED", "Attachment": "ATT", "Ammo": "AMO", "Paper": "PPR", "Charm": "CHM"}
const INSET := 3                   # the picture sits inside the border

var id := -1
var _art: TextureRect
var _lines: Array[Label] = []      # up to three, laid out by the footprint
var _corner: Label                 # over the picture: an ammo stack's rounds


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


## Pixels a footprint of so many cells spans, gaps included.
static func px(cells: int) -> int:
	return cells * Pal.CELL + (cells - 1) * Pal.CELL_GAP


static func rarity_tone(it: Dictionary) -> String:
	if it.has("set"):
		return "set"
	return ["", "good", "warn", "bad"][it["rarity"]]


## The item, drawn: the cell takes the footprint's size, or `box` when given
## (a body slot fills its box whatever is in it; a rig pouch is one cell).
func show_item(it: Dictionary, on: bool, box := Vector2.ZERO) -> void:
	id = it["id"]
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
		if Items.is_ammo(it):
			_corner.text = "%d" % int(it["rounds"])
			_corner.position = Vector2(0, size.y - 20)
			_corner.size = Vector2(size.x - 4, 18)
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
		words = [SHORT[it["slot"]], ("%d" % int(it["rounds"])) if Items.is_ammo(it) else h[0]]
	else:
		words = [Items.full_name(it) if it.has("piece") else it["base"], ("%d rounds" % int(it["rounds"])) if Items.is_ammo(it) else "%s %s" % [h[0], h[1]]]
		if big:
			words.append("T%d · %s" % [it["tier"], Items.rarity_name(it)])
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
		var sb := UI.box(Pal.SELECT if on else (Pal.CARD if state == "hover" else Pal.PANEL), 6)
		if on:
			sb.set_border_width_all(2)
			sb.border_color = Pal.ACCENT
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
	return out
