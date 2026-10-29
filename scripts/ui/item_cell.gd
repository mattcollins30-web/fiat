extends Button
## One item as a cell: a button the size of the item's footprint (64 px a
## cell, 6 px gaps), its rarity the border's colour, carrying the item's
## picture if art/items/<slug>.png has been made and short words if not. The
## grids, the body's slots and the rig's pouches all draw items through this,
## so an item looks the same wherever it is. The owner wires the press and
## the drag.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")
const Items := preload("res://scripts/sim/items.gd")

const SHORT := {"Primary": "PRI", "Secondary": "SEC", "Helmet": "HLM", "Armour": "ARM", "Gloves": "GLV", "Rig": "RIG", "Backpack": "PCK",
	"Medical": "MED", "Attachment": "ATT", "Ammo": "AMO", "Paper": "PPR", "Charm": "CHM", "Grenade": "GRN", "Supplies": "SUP"}
const INSET := 3                   # the picture sits inside the border
const NAME_MIN := 9                # the smallest type a name steps down to in a cell of two or more across (29 Oct)
## The tone made to read at a glance (17 Oct, Matt: the item-colours canvas): a wash of the tone up from the cell's
## foot, a glow round the picture from epic up, a sheen across a unique (a faster ember one on a mythic) and a mythic's
## border pulsing. Common has none of it.
const WASH := 0.24                 # the wash's strength at the foot; a fifth of it at three quarters up
const GLOW_FROM := 3               # epic
const PULSE_S := 1.8
const GLOW_SHADER := """
shader_type canvas_item;
uniform vec4 glow : source_color = vec4(1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float near = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			near = max(near, texture(TEXTURE, UV + vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE).a * (1.0 - 0.3 * length(vec2(float(x), float(y)))));
		}
	}
	vec4 g = vec4(glow.rgb, glow.a * near * (1.0 - c.a));
	COLOR = mix(g, c, c.a);
}
"""
const SHEEN_SHADER := """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.22);
uniform float period = 3.2;
void fragment() {
	float t = mod(TIME, period) / period;
	float x = -0.4 + t / 0.55 * 1.6;
	float d = (UV.x + (1.0 - UV.y) * 0.2) - x;
	float band = clamp(1.0 - abs(d) / 0.14, 0.0, 1.0);
	COLOR = vec4(tint.rgb, tint.a * band * band);
}
"""
static var _glow_shader: Shader
static var _sheen_shader: Shader
static var _wash_tex: GradientTexture2D
var _wash: TextureRect
var _sheen: ColorRect
var _pulse := false
var _tone_now := ""

var id := -1
var glass := false                 # over a backdrop (10 Oct, Kit-B): the fill lets a fifth of it through
var _art: TextureRect
var _lines: Array[Label] = []      # up to three, laid out by the footprint
var _corner: Label                 # over the picture: an ammo stack's rounds
var _up: Label                     # the upgrade's arrow (11 Oct): top right, on a dark disc so it reads over any art
const UP := 18                     # the arrow's disc
const UP_NUDGE := 6                # a one-row cell's words, moved down out of the arrow's corner
var _nudged := false
var _lock: Label                   # gear over the runner's level (15 Oct, signals_kit.png): a padlock and its level, red, top right
var _lock_icon: TextureRect
const LOCK_H := 18
const LOCK_ICON := 12
const LOCKED_FADE := 0.4           # the piece greyed under its padlock


func _init() -> void:
	text = ""
	focus_mode = Control.FOCUS_ALL
	_wash = TextureRect.new()
	_wash.texture = _wash_texture()
	_wash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_wash.stretch_mode = TextureRect.STRETCH_SCALE
	_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wash.visible = false
	add_child(_wash)
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
	@warning_ignore("integer_division")
	_up.add_theme_stylebox_override("normal", UI.box(Color(Pal.BG, 0.85), UP / 2, 1, Pal.GOOD))
	_up.visible = false
	_lock = UI.label(self, Rect2(0, 0, 40, LOCK_H), "", "SemiBold", 11, Pal.BAD, HORIZONTAL_ALIGNMENT_RIGHT)
	var sb := UI.box(Color(Pal.BG, 0.9), 4, 1, Pal.BAD)
	sb.content_margin_left = LOCK_ICON + 5
	sb.content_margin_right = 4
	_lock.add_theme_stylebox_override("normal", sb)
	_lock.visible = false
	_lock_icon = TextureRect.new()
	_lock_icon.texture = NodeGlyphs.texture("lock")
	_lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_lock_icon.modulate = Pal.BAD
	_lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_icon.position = Vector2(3, (LOCK_H - LOCK_ICON) / 2.0)
	_lock_icon.size = Vector2(LOCK_ICON, LOCK_ICON)
	_lock.add_child(_lock_icon)
	_sheen = ColorRect.new()
	_sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheen.visible = false
	add_child(_sheen)
	_mags = Control.new()                  # a rig pouch's magazines (28 Oct): a pip each along its foot, filled as loaded
	_mags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mags.visible = false
	_mags.draw.connect(_draw_mags)
	add_child(_mags)
	_mark = Control.new()                  # over everything: the Fence's contract marks (19 Oct)
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.draw.connect(_draw_mark)
	add_child(_mark)
	set_process(false)


## A rig pouch's magazines (28 Oct, magazines): `fills` one a magazine, 0 to 1 (empty to loaded), drawn as pips
## along the cell's foot; [] takes them off. The rounds stay in the corner, lifted clear of the pips.
var _mags: Control
var _mag_fill: Array = []
const MAG_PIP_H := 6
const MAG_PIP_SMALL := 4


func set_mags(fills: Array, it := {}) -> void:
	_mag_fill = fills
	var mag_tex: Texture2D = Items.mag_art(it) if not fills.is_empty() else null
	if mag_tex != null:
		_art.visible = true                   # the pouch drawn as its magazines once their pictures are in (28 Oct)
		_art.texture = mag_tex
		var fits: bool = mag_tex.get_width() <= _art.size.x and mag_tex.get_height() <= _art.size.y
		_art.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED if fits else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mags.visible = not fills.is_empty() and size.x >= 26.0
	_mags.position = Vector2.ZERO
	_mags.size = size
	if _mags.visible:
		# what's written on the pouch kept clear of the pips: the count's corner above them, the words lifted
		var pip_top: float = size.y - INSET - 2.0 - float(mag_pip_h())
		if _corner.visible:
			if size.y < 48.0:
				_corner.size.y = maxf(8.0, pip_top - 1.0 - _corner.position.y)
			_corner.position.y = pip_top - 1.0 - _corner.size.y     # a label won't shrink under its font's height (Godot 4.7: 23 px at 11): its foot on the pips' top, its words at the foot
		var low := 0.0
		for l in _lines:
			if l.visible:
				low = maxf(low, l.position.y + l.size.y - (pip_top - 1.0))
		if low > 0.0:
			for l in _lines:
				if l.visible:
					l.position.y -= low
	_mags.queue_redraw()


## A pip's height at this cell's size.
func mag_pip_h() -> int:
	return MAG_PIP_SMALL if size.y < 48.0 else MAG_PIP_H


## The pips as drawn, for the tests: one Rect2 a magazine, inside the cell.
func mag_pips() -> Array:
	var out: Array = []
	if not _mags.visible:
		return out
	var n: int = _mag_fill.size()
	var gap := 2.0
	var x0 := float(INSET) + 3.0
	var w: float = (size.x - 2.0 * x0 - gap * (n - 1)) / float(n)
	var h: float = float(mag_pip_h())
	for k in range(n):
		out.append(Rect2(x0 + k * (w + gap), size.y - INSET - 2.0 - h, w, h))
	return out


func _draw_mags() -> void:
	var pips: Array = mag_pips()
	for k in range(pips.size()):
		var r: Rect2 = pips[k]
		var f: float = clampf(float(_mag_fill[k]), 0.0, 1.0)
		_mags.draw_rect(r, Color(Pal.BG, 0.9))
		if f > 0.0:
			_mags.draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), Pal.GOOD if f >= 0.999 else Pal.WARN)
		_mags.draw_rect(r, Color(Pal.TEXT_2, 0.8), false, 1.0)


## A contract's mark on the cell (19 Oct, Matt's Fence B): "go" - it goes on Hand in, a green ring; "could" - it
## would do, kept back, a dashed ring; "dim" - not asked for, under a shade; "" none.
var mark := ""
var _mark: Control


func set_mark(kind: String) -> void:
	mark = kind
	_mark.position = Vector2.ZERO
	_mark.size = size
	_mark.queue_redraw()


func _draw_mark() -> void:
	var r := Rect2(Vector2(1, 1), size - Vector2(2, 2))
	match mark:
		"go":
			_mark.draw_rect(r, Pal.GOOD, false, 3.0)
		"could":
			var d := 6.0
			for side in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.end.x, r.position.y), r.end], [r.end, Vector2(r.position.x, r.end.y)], [Vector2(r.position.x, r.end.y), r.position]]:
				var a: Vector2 = side[0]
				var b: Vector2 = side[1]
				var n: int = int(a.distance_to(b) / d)
				for k in range(0, n, 2):
					_mark.draw_line(a.lerp(b, float(k) / n), a.lerp(b, float(mini(k + 1, n)) / n), Pal.TEXT, 2.0)
		"dim":
			_mark.draw_rect(Rect2(Vector2.ZERO, size), Color(Pal.BG, 0.65))
		"hl":
			_mark.draw_rect(r, Pal.ACCENT, false, 3.0)      # the loot filter's highlight (24 Oct)


## The wash's gradient, once: the tone's own colour comes from the rect's modulate.
static func _wash_texture() -> GradientTexture2D:
	if _wash_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.2), Color(1, 1, 1, 1.0)])
		_wash_tex = GradientTexture2D.new()
		_wash_tex.gradient = g
		_wash_tex.fill_from = Vector2(0, 0)
		_wash_tex.fill_to = Vector2(0, 1)
		_wash_tex.width = 4
		_wash_tex.height = 64
	return _wash_tex


## How high an item ranks for the tone's dressing: its rarity, a set's and a legendary's 4, a unique 5, a mythic 6.
static func tone_rank(it: Dictionary) -> int:
	if it.get("mythic", false):
		return 6
	if it.has("unique"):
		return 5
	if it.has("set"):
		return 4
	return int(it.get("rarity", 0))


## The wash, the glow, the sheen and the pulse for this item's tone (17 Oct).
func _dress(it: Dictionary, tone: String) -> void:
	var rank: int = tone_rank(it)
	var col: Color = Pal.tone_color(tone) if tone != "" else Color.TRANSPARENT
	_tone_now = tone
	_wash.visible = tone != "" and rank > 0
	_wash.position = Vector2(INSET, INSET)
	_wash.size = size - Vector2(2 * INSET, 2 * INSET)
	_wash.modulate = Color(col, WASH)
	if rank >= GLOW_FROM and tone != "":
		if _glow_shader == null:
			_glow_shader = Shader.new()
			_glow_shader.code = GLOW_SHADER
		var mat := ShaderMaterial.new()
		mat.shader = _glow_shader
		mat.set_shader_parameter("glow", Color(col, 0.85))
		_art.material = mat
	else:
		_art.material = null
	_sheen.visible = rank >= 5
	if _sheen.visible:
		if _sheen_shader == null:
			_sheen_shader = Shader.new()
			_sheen_shader.code = SHEEN_SHADER
		var sm := ShaderMaterial.new()
		sm.shader = _sheen_shader
		sm.set_shader_parameter("tint", Color(1.0, 0.78, 0.6, 0.32) if rank == 6 else Color(1, 1, 1, 0.22))
		sm.set_shader_parameter("period", 2.2 if rank == 6 else 3.2)
		_sheen.material = sm
		_sheen.position = Vector2(INSET, INSET)
		_sheen.size = size - Vector2(2 * INSET, 2 * INSET)
		_sheen.move_to_front()
	_pulse = rank == 6
	set_process(_pulse)
	if not _pulse:
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var sb := get_theme_stylebox(state) as StyleBoxFlat
			if sb != null:
				sb.shadow_size = 0


func _process(_dt: float) -> void:
	if not _pulse:
		return
	var k: float = 0.5 - 0.5 * cos(Time.get_ticks_msec() / 1000.0 * TAU / PULSE_S)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var sb := get_theme_stylebox(state) as StyleBoxFlat
		if sb != null:
			sb.shadow_color = Color(Pal.MYTHIC, 0.55 * k)
			sb.shadow_size = int(round(2.0 + 8.0 * k))


## For the tests: the dressing as shown.
func dress() -> Dictionary:
	return {"wash": _wash.visible, "wash_colour": _wash.modulate, "glow": _art.material != null, "sheen": _sheen.visible, "pulse": _pulse}


## Gear too high to wear (15 Oct, gear gated by level; mockup signals_kit.png): greyed, and a padlock with the level
## it waits for, top right where an upgrade's arrow would go (a locked piece never shows one). 0 takes it off.
func set_locked(lv: int) -> void:
	var on := lv > 0
	_lock.visible = on
	var fade := Color(1, 1, 1, LOCKED_FADE if on else 1.0)
	_art.modulate = fade
	for l in _lines:
		l.modulate = fade
	_corner.modulate = fade
	if not on:
		return
	_art.material = null                     # greyed under its padlock: no glow (the shader would drop the fade)
	_up.visible = false
	_lock.text = "%d" % lv
	_lock.size = Vector2(ceilf(UI.text_width(_lock, _lock.text)) + LOCK_ICON + 9, LOCK_H)
	_lock.position = Vector2(size.x - _lock.size.x - 2, 2)
	_lock.move_to_front()
	if not _nudged and not _art.visible and size.y < 100.0:
		_nudged = true
		for l in _lines:
			if l.visible:
				l.position.y += UP_NUDGE


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
	_mags.visible = false
	_mag_fill = []
	set_locked(0)
	_nudged = false
	var f := Items.footprint(it)
	size = box if box != Vector2.ZERO else Vector2(px(f.x), px(f.y))
	# the words are laid out by the room there is, in cells
	f = Vector2i(maxi(1, roundi((size.x + Pal.CELL_GAP) / (Pal.CELL + Pal.CELL_GAP))), maxi(1, roundi((size.y + Pal.CELL_GAP) / (Pal.CELL + Pal.CELL_GAP))))
	_style(on, rarity_tone(it))
	_dress(it, rarity_tone(it))
	var tex := Items.art(it)
	for l in _lines:
		l.visible = false
	_corner.visible = false
	if tex != null:
		_art.visible = true
		_art.texture = tex
		_art.rotation = 0.0
		_art.position = Vector2(INSET, INSET)
		_art.size = size - Vector2(2 * INSET, 2 * INSET)
		# pixel art at its own pixels when it fits (a footprint's picture always
		# does: 64 a cell, the cell 64 plus the gaps); only a bigger one is scaled
		var fits: bool = tex.get_width() <= _art.size.x and tex.get_height() <= _art.size.y
		_art.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED if fits else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if Items.is_ammo(it) or ((Items.is_socketable(it) or Items.is_supplies(it)) and int(it.get("count", 1)) > 1):
			_corner.text = ("%d" % int(it["rounds"])) if Items.is_ammo(it) else ("×%d" % int(it["count"]))
			var small: bool = size.y < 48.0               # a shrunk pouch (a full rig, 44 px and under): the count smaller, "1.2k" past 999
			var tiny: bool = size.x < 34.0                # the smallest pouches: 9 px, whole thousands
			_corner.add_theme_font_size_override("font_size", (9 if tiny else 11) if small else Pal.CELL_TEXT)
			var n: int = int(it["rounds"]) if Items.is_ammo(it) else int(it["count"])
			if small and n >= 1000:
				@warning_ignore("integer_division")
				_corner.text = "%.1fk" % (n / 1000.0) if (n < 10000 and not tiny) else "%dk" % (n / 1000)
			# a small pouch: the count laid over the whole cell, bottom right (a label won't go under its font's line height)
			_corner.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM if small else VERTICAL_ALIGNMENT_CENTER
			_corner.position = Vector2(0, 0.0 if small else size.y - 20)
			_corner.size = Vector2(size.x - 2, size.y if small else 18.0)
			_corner.visible = true
		return
	_art.visible = false
	_words(it, f)


## A piece lying turned in the pack (27 Oct): its picture a quarter round, filling the cell show_item sized to the
## turned footprint. Off, as it was.
func set_turned(on: bool) -> void:
	if not _art.visible:
		return
	_art.rotation_degrees = 90.0 if on else 0.0
	_art.size = Vector2(size.y, size.x) - Vector2(2 * INSET, 2 * INSET) if on else size - Vector2(2 * INSET, 2 * INSET)
	_art.position = Vector2(size.x - INSET, INSET) if on else Vector2(INSET, INSET)
	if on:
		var tex: Texture2D = _art.texture
		var fits: bool = tex != null and tex.get_width() <= _art.size.x and tex.get_height() <= _art.size.y
		_art.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED if fits else TextureRect.STRETCH_KEEP_ASPECT_CENTERED


## No picture: the words that stand in for it, by how much room there is.
## One cell: two short lines. A row: a name line and a figure line. Taller:
## name, figure, tier and rarity.
func _words(it: Dictionary, f: Vector2i) -> void:
	var h := Items.headline(it)
	var big: bool = f.y >= 2
	var fs := Pal.CELL_TEXT_BIG if big else Pal.CELL_TEXT
	var line_h := 22 if big else 20
	var words: Array = []
	var cure: String = Items.cure_of(it)     # a cure's one cell names its element, in its tone (28 Oct, the review: "MED Stops")
	if f.x == 1 and f.y == 1:
		words = [SHORT[it["slot"]], ("%d" % int(it["rounds"])) if Items.is_ammo(it) else (("×%d" % int(it["count"])) if (Items.is_socketable(it) or Items.is_supplies(it)) and int(it.get("count", 1)) > 1 else (cure.capitalize() if cure != "" else h[0]))]
	else:
		words = [Items.full_name(it) if it.has("piece") else it["base"], ("%d rounds" % int(it["rounds"])) if Items.is_ammo(it) else "%s %s" % [h[0], h[1]]]
		if big:
			words.append("T%d · %s" % [it["tier"], Items.rarity_name(it)])
	if size.x < 48.0 or size.y < 48.0:     # a small pouch either way, 44 px included (12 Oct: a packed rig at 44 spilled a kit's lines) (10 Oct: a two-pouch kit at 28 px tall spilled its two lines)
		# a small pouch (the run's rig two rows deep): the slot's short word alone, small
		words = [words[0] if f.x > 1 else SHORT[it["slot"]]]
		fs = 11 if size.x >= 34.0 else (9 if size.x >= 26.0 else 8)     # the smallest pouch (22 px): the short word at 8; a half cell (29 px, the run's rig of thirteen and more since 27 Oct) at 9
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
			if str(it.get("slot", "")) == "Gloves":
				options.append("%s %s" % [h[0], Items.glove_unit_short(it)])     # a pair's unit short before none (the fix round, 29 Oct)
			options.append((cure.capitalize().left(4) if cure != "" and f.x == 1 and f.y == 1 else h[0]) if not Items.is_ammo(it) else "%d" % int(it["rounds"]))
		else:
			options.append("T%d" % it["tier"])
		var cure_word: bool = cure != "" and i == 1 and f.x == 1 and f.y == 1 and words.size() > 1
		l.add_theme_color_override("font_color", Pal.ELEMENT_COLOURS.get(cure, Pal.TEXT) if cure_word else (Pal.TEXT if i < 2 else Pal.TEXT_3))
		if i == 0 and f.x > 1 and str(words[0]) != str(SHORT[it["slot"]]):
			# a long name in a cell with room for one (29 Oct, the itemisation's bases): the type steps down before the name
			# gives way to the slot's code
			var nfs: int = fs
			while nfs > NAME_MIN and UI.text_width(l, str(words[0])) > l.size.x:
				nfs -= 1
				l.add_theme_font_size_override("font_size", nfs)
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
	if _lock.visible:
		out.append(_lock)
	return out
