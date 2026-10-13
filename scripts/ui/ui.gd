extends RefCounted
## Building blocks: fonts, labels, panels and buttons, all drawn from the palette.
## Every label is placed at an exact rect with no wrapping, so geometry is
## predictable and tests/ui_check.gd can prove nothing overflows.

const Pal := preload("res://scripts/ui/palette.gd")

static var _fonts := {}


## Inter. Figures get tabular digits so columns of numbers line up; prose doesn't,
## because Inter's tabular set widens the hyphen too ("Shut-in" reads "Shut - in").
static func font(weight: String, tabular := true) -> Font:
	var key := weight + ("/tnum" if tabular else "")
	if _fonts.has(key):
		return _fonts[key]
	var base: Font = load("res://fonts/Inter-%s.ttf" % weight)
	var fv := FontVariation.new()
	fv.base_font = base
	if tabular:
		var ts := TextServerManager.get_primary_interface()
		fv.opentype_features = {ts.name_to_tag("tnum"): 1}
	_fonts[key] = fv
	return fv


static func label(parent: Node, rect: Rect2, text: String, weight: String, size: int,
		color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, tabular := true) -> Label:
	var l := Label.new()
	l.position = rect.position
	l.size = rect.size
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.clip_text = false
	# a safety net only: ui_check.gd fails if any sampled state ever needs it
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", font(weight, tabular))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


static func box(color: Color, radius := 6, border := 0, border_color := Color.TRANSPARENT) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	if border > 0:
		sb.set_border_width_all(border)
		sb.border_color = border_color
	return sb


## The UI glyphs (8 Oct): res://art/ui/<name>.png, line drawings white on
## transparent at 64 px, tinted by `color`, one set for the rail and the top bar
## (yard, runs, lockup, bench, caravan, clinic, fence, radio, cash, notes, hp,
## xp, dps, where). Loaded like the portraits: imported if Godot has, from the
## file if not, so a headless run without the import step still draws them.
## A white line drawing is tinted by the shell; a painted one (the house style,
## from the pixellab manifest tools/pixellab_ui_manifest.json) is shown as it
## is - `glyph_mono` tells them apart by the picture's colour.
static var _glyphs := {}
static var _glyph_mono := {}
## A place's painted art (9 Oct): art/places/<slug>.png - a zone for its tab, a site for its band (the Runs card
## and behind the run's clock). Any size; shown to cover its box from the centre. Null when not painted yet:
## the band draws its skyline instead. Loaded like the glyphs: imported, or from the file when not yet.
static var _places := {}
static func place_slug(name: String) -> String:
	var out := ""
	var gap := false
	for ch in name.to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			if gap and out != "":
				out += "_"
			out += ch
			gap = false
		else:
			gap = true
	return out


static func place_texture(name: String) -> Texture2D:
	var s := place_slug(name)
	if _places.has(s):
		return _places[s]
	var path := "res://art/places/%s.png" % s
	var tex: Texture2D = null
	if s != "" and ResourceLoader.exists(path):
		tex = load(path)
	elif s != "" and FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			tex = ImageTexture.create_from_image(img)
	_places[s] = tex
	return tex


## A room's heading as a band (10 Oct, Rooms-B; Matt: replicate the Clinic's and the Fence's art for every other
## room): its painted place under the heading's words, covering it from the centre, shaded from the left so the words
## read; nothing until the place is painted (art/places/<slug>.png, the rooms manifest). Returns {art, shade, place}.
static func head_art(head: Panel, place: String) -> Dictionary:
	head.clip_contents = true
	var d := {"place": place}
	var art := TextureRect.new()
	art.position = Vector2(1, 1)
	art.size = head.size - Vector2(2, 2)                         # inside the heading's line, which the other cards keep
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(art)
	head.move_child(art, 0)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(Pal.CARD, 0.94), Color(Pal.CARD, 0.6), Color(Pal.CARD, 0.15)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	gt.width = 64
	gt.height = 4
	var shade := TextureRect.new()
	shade.texture = gt
	shade.position = Vector2(1, 1)
	shade.size = head.size - Vector2(2, 2)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(shade)
	head.move_child(shade, 1)
	d["art"] = art
	d["shade"] = shade
	head.child_entered_tree.connect(func(n): if n is Label and art.visible: shadow(n))     # the heading's words come after
	set_head_art(d, place_texture(place))
	return d


## Point a heading's band at a texture (null: the plain card); its words take a shadow over art.
static func set_head_art(d: Dictionary, tex: Texture2D) -> void:
	var art: TextureRect = d["art"]
	art.texture = tex
	art.visible = tex != null
	d["shade"].visible = tex != null
	if tex != null:
		# whole-number scales stay crisp; any other is smoothed (nearest at 2.23x doubles some pixels and triples others)
		var s: float = maxf(art.size.x / tex.get_width(), art.size.y / tex.get_height())
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if (s >= 1.0 and is_equal_approx(s, roundf(s))) else CanvasItem.TEXTURE_FILTER_LINEAR
	for c in art.get_parent().get_children():
		if c is Label:
			if tex != null:
				shadow(c)
			else:
				c.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))     # the plain card: no shadow


static func glyph_texture(name: String) -> Texture2D:
	if _glyphs.has(name):
		return _glyphs[name]
	var path := "res://art/ui/%s.png" % name
	var tex: Texture2D = null
	var img: Image = null
	if ResourceLoader.exists(path):
		tex = load(path)
		img = tex.get_image() if tex != null else null
	elif FileAccess.file_exists(path):
		img = Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			img.generate_mipmaps()
			tex = ImageTexture.create_from_image(img)
	_glyphs[name] = tex
	_glyph_mono[name] = img != null and _is_mono(img)
	return tex


## White wherever it isn't clear: a line drawing to tint, not a painting.
static func _is_mono(img: Image) -> bool:
	if img.is_compressed():
		img = img.duplicate()
		img.decompress()
	var step: int = maxi(1, img.get_width() / 16)
	for y in range(0, img.get_height(), step):
		for x in range(0, img.get_width(), step):
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and (c.r < 0.85 or c.g < 0.85 or c.b < 0.85):
				return false
	return true


static func glyph_mono(name: String) -> bool:
	glyph_texture(name)
	return bool(_glyph_mono.get(name, true))


static func glyph(parent: Node, rect: Rect2, name: String, color: Color) -> TextureRect:
	var t := TextureRect.new()
	t.position = rect.position
	t.size = rect.size
	t.texture = glyph_texture(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	t.modulate = color if glyph_mono(name) else Color.WHITE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


static func panel(parent: Node, rect: Rect2, style: StyleBox) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", style)
	parent.add_child(p)
	return p


## A button whose geometry never changes between states - only colour does.
static func button(parent: Node, rect: Rect2, primary: bool) -> Button:
	var b := Button.new()
	b.position = rect.position
	b.size = rect.size
	b.focus_mode = Control.FOCUS_ALL
	b.clip_text = false
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.add_theme_font_override("font", font("SemiBold"))
	b.add_theme_font_size_override("font_size", Pal.FLOOR)
	style_button(b, primary)
	parent.add_child(b)
	return b


## `tone` ("good", "warn", "bad") colours the button that colour instead - a
## button that means something, like selling a rarity (Fiat's Black Market).
static func style_button(b: Button, primary: bool, tone := "") -> void:
	var bg := Pal.ACCENT if primary else Pal.BUTTON
	var hover := Pal.ACCENT_HOVER if primary else Pal.BUTTON_HOVER
	var press := Pal.ACCENT_PRESS if primary else Pal.BUTTON_PRESS
	var text := Pal.ACCENT_TEXT if primary else Pal.TEXT
	if tone != "":
		bg = Pal.tone_color(tone)
		hover = bg.lightened(0.12)
		press = bg.darkened(0.12)
		text = Pal.ACCENT_TEXT
	for pair in [["normal", bg], ["hover", hover], ["pressed", press], ["disabled", Pal.BUTTON_OFF],
			["hover_pressed", press]]:
		var sb := box(pair[1])
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		b.add_theme_stylebox_override(pair[0], sb)
	var focus := box(Color.TRANSPARENT, 6, 2, Pal.TEXT)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_color_override("font_color", text)
	b.add_theme_color_override("font_hover_color", text)
	b.add_theme_color_override("font_pressed_color", text)
	b.add_theme_color_override("font_focus_color", text)
	b.add_theme_color_override("font_hover_pressed_color", text)
	b.add_theme_color_override("font_disabled_color", Pal.TEXT_3)


## The first of `options` that fits the label's box becomes its text; the last
## is the fallback. Lines that carry item words are built this way - long form,
## short form, a count - so nothing ever trails off into an ellipsis.
## A button's text: the first option that fits with its padding (the smoke's 32 px), else the last.
static func fit_button(b: Button, options: Array) -> void:
	for o in options:
		if text_width(b, o) + 32.0 <= b.size.x:
			b.text = o
			return
	b.text = options.back() if not options.is_empty() else ""


static func fit(l: Label, options: Array) -> void:
	for o in options:
		if text_width(l, o) <= l.size.x:
			l.text = o
			return
	l.text = options.back() if not options.is_empty() else ""


## A sentence over several labels, a line each: words go on the first label
## until the next one wouldn't fit its box, then the second, and so on. Words
## left over when the labels run out go on the last one anyway, where the
## tests will say so - a sentence that needs more lines than it has needs
## shorter words, not an ellipsis. Labels not needed are cleared.
static func wrap(labels: Array, text: String) -> void:
	var words := text.split(" ", false)
	var k := 0
	var line := ""
	for w in words:
		var l: Label = labels[k]
		var trial := w if line == "" else line + " " + w
		if line != "" and text_width(l, trial) > l.size.x and k < labels.size() - 1:
			l.text = line
			k += 1
			line = w
		else:
			line = trial
	labels[k].text = line
	for i in range(k + 1, labels.size()):
		labels[i].text = ""


## A sentence or two on one label: the whole when it fits, else fewer sentences from the front.
static func fit_sentences(l: Label, text: String) -> void:
	var sentences: Array = text.split(". ", false)
	var options := [text]
	for n in range(sentences.size() - 1, 0, -1):
		options.append(". ".join(sentences.slice(0, n)) + ".")
	# then the first sentence's first clause, then its first few words
	var first: String = str(sentences[0]) if not sentences.is_empty() else text
	for sep in [", ", "; ", ": "]:
		if first.contains(sep):
			options.append(first.get_slice(sep, 0) + "…")
	var words: PackedStringArray = first.split(" ", false)
	for n in range(mini(6, words.size() - 1), 2, -1):
		options.append(" ".join(words.slice(0, n)) + "…")
	fit(l, options)


## Width the text needs at its font and size - what the tests compare with the box.
static func text_width(c: Control, text: String) -> float:
	var f: Font = c.get_theme_font("font")
	var s: int = c.get_theme_font_size("font_size")
	return f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x


# ------------------------------------------------------------------ the A style's pieces

const TILE_H := 60                    # a tile: its key over its figure, on the dark ground
const HEAD_H := 24                    # a section head: small capitals in the muted tone
const TILE_TEXT := 22                 # the figure on a tile


## A tile: a small dark box with a muted key on the first line and the
## figure, semibold, on the second. Returns {panel, key, value}.
static func tile(parent: Node, rect: Rect2, key := "", value := "") -> Dictionary:
	var p := panel(parent, rect, box(Pal.BG, 6))
	var t := {"panel": p}
	t["key"] = label(p, Rect2(10, 4, rect.size.x - 20, 22), key, "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	t["value"] = label(p, Rect2(10, 26, rect.size.x - 20, 30), value, "SemiBold", TILE_TEXT, Pal.TEXT)
	return t


## The tile's words and the figure's tone. `options` offers the figure's
## forms long to short; the first that fits is shown.
static func set_tile(t: Dictionary, key: String, options: Array, tone := Pal.TEXT) -> void:
	t["key"].text = key
	fit(t["value"], options)
	t["value"].add_theme_color_override("font_color", tone)


## A row of `n` tiles across `w` at `y`, `gap` apart. Returns the tiles.
static func tile_row(parent: Node, x: float, y: float, w: float, n: int, gap := 8) -> Array:
	var out := []
	var tw := (w - gap * (n - 1)) / n
	for k in range(n):
		out.append(tile(parent, Rect2(x + k * (tw + gap), y, tw, TILE_H)))
	return out


## A section head: "THE FIGHT", small, muted; the text given is uppercased.
static func head(parent: Node, rect: Rect2, text: String) -> Label:
	var l := label(parent, rect, text.to_upper(), "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	return l


## A shadow under a label's glyphs, for words drawn over art.
static func shadow(l: Label) -> void:
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.add_theme_constant_override("shadow_outline_size", 2)
