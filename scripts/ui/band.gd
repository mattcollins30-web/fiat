extends Control
## The art band: the strip across the top of a card or a column that carries
## a place's name and its one headline figure over a backdrop. The backdrop
## is a placeholder for the painted art, one a site: a sky in the zone's
## tone, a skyline of blocks seeded from the site's name, and a fade into
## the card's own colour so the words at the foot read. The painted piece
## drops into `_draw` later; the words and their geometry stay.
##
## Words: a kicker (muted, small), a title (semibold), a headline figure in
## a tone with its unit beside it, up to three right-aligned lines top
## right, and a chip row along the foot. Every label is placed at an exact
## rect, like the rest of the shell, so the fit checks can prove it.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Chips := preload("res://scripts/ui/chips.gd")

const PAD := 20
const RIGHT_W := 240                 # the right-hand lines' box
const RIGHT_LINES := 3
const SKY := [Color("2a3340"), Color("3a2f2a"), Color("2b3a33"), Color("33303a")]   # a tone a zone (the last for rooms)
const GROUND := [Color("141a22"), Color("1d1614"), Color("131c18"), Color("17151b")]

var kicker: Label
var title: Label
var headline: Label
var unit: Label
var right: Array[Label] = []
var chips: Chips
var bar: Panel                        # an optional progress bar along the foot (the run's)
var _bar_fill: Panel
var _bar_label: Label
var _tone := 0
var _seed := 0
var _fade_to := Pal.CARD
var _left := PAD                      # where the words start: past a portrait when one sits at the left
var _under := false                   # the headline under the title, the unit beside it
var _right_any := false               # right-hand lines showing: the unit keeps clear of them
var _art: TextureRect                 # the site's painted art (9 Oct), over the skyline when there is one
var _art_fade: TextureRect            # its shade: a touch at the top for the title, the fade into the card at the foot


## `w` × `h` at the parent's top left; `tone` picks the sky; `fade_to` is the panel colour under it.
func _init(w: float, h: float, tone := 0, fade_to := Pal.CARD) -> void:
	size = Vector2(w, h)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_tone = clampi(tone, 0, SKY.size() - 1)
	_fade_to = fade_to
	_art = TextureRect.new()
	_art.size = size
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST      # pixel art, scaled whole
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.visible = false
	add_child(_art)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.5, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.15), Color(fade_to, 0.25), Color(fade_to, 0.97)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	_art_fade = TextureRect.new()
	_art_fade.texture = gt
	_art_fade.size = size
	_art_fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_fade.stretch_mode = TextureRect.STRETCH_SCALE
	_art_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_fade.visible = false
	add_child(_art_fade)
	kicker = UI.label(self, Rect2(PAD, 12, w - 2 * PAD, 24), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	title = UI.label(self, Rect2(PAD, 36, w - 2 * PAD, 40), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	headline = UI.label(self, Rect2(PAD, h - 60, w - 2 * PAD, 48), "", "SemiBold", Pal.HEADLINE, Pal.ACCENT)
	unit = UI.label(self, Rect2(PAD, h - 54, w - 2 * PAD, 36), "", "Medium", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
	for k in range(RIGHT_LINES):
		right.append(UI.label(self, Rect2(w - PAD - RIGHT_W, 12 + k * 24, RIGHT_W, 24), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false))
	for l in [kicker, title, headline, unit]:
		UI.shadow(l)
	for l in right:
		UI.shadow(l)
	chips = Chips.new(w - 2 * PAD)
	chips.position = Vector2(PAD, h - 14 - Chips.CHIP_H)
	chips.visible = false
	add_child(chips)
	bar = UI.panel(self, Rect2(PAD, h - 14 - 24, w - 2 * PAD, 24), UI.box(Color(Pal.BG, 0.85), 6))
	_bar_fill = UI.panel(bar, Rect2(0, 0, 0, 24), UI.box(Pal.ACCENT, 6))
	_bar_label = UI.label(bar, Rect2(0, 0, w - 2 * PAD, 24), "", "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	bar.visible = false


## The words. `u` is the unit, a string or its forms long to short; `headline_colour` is the odds' tone, the accent by default.
var _unit_forms: Array = []
func set_words(k: String, t: String, h: String, u, headline_colour := Pal.ACCENT) -> void:
	kicker.text = k
	title.text = t
	headline.text = h
	_unit_forms = u if u is Array else [str(u)]
	unit.text = str(_unit_forms[0])
	headline.add_theme_color_override("font_color", headline_colour)
	_fit_unit()


## The unit's first form that fits its box - and, beside the headline, the first that fits the line
## the two make (the headline, a gap of 16, the unit) in the wider of their boxes: the rule the tests read.
func _fit_unit() -> void:
	if _unit_forms.is_empty():
		return
	if not _under:
		UI.fit(unit, _unit_forms)
		return
	var room: float = maxf(headline.size.x, unit.size.x)
	var hw: float = UI.text_width(headline, headline.text)
	for o in _unit_forms:
		if hw + 16.0 + UI.text_width(unit, str(o)) <= room and UI.text_width(unit, str(o)) <= unit.size.x:
			unit.text = str(o)
			return
	unit.text = str(_unit_forms.back())


## Where the headline sits: at the foot (the default) or under the title, with the unit beside it.
func headline_under_title(on: bool) -> void:
	_under = on
	if on:
		headline.position.y = 78
		headline.size.y = 44
		unit.position.y = 84
		unit.size.y = 36
		unit.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		unit.position.x = _left + ceilf(UI.text_width(headline, headline.text)) + 10
		unit.size.x = size.x - unit.position.x - PAD - (RIGHT_W + 12 if _right_any else 0)
		_fit_unit()
	else:
		headline.position.y = size.y - 60
		headline.size.y = 48
		unit.position.y = size.y - 54
		unit.size.y = 36
		unit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		unit.position.x = _left
		unit.size.x = size.x - _left - PAD
		_fit_unit()


## A portrait `w` wide sits at the band's left: the words start past it.
func portrait_width(w: float) -> void:
	_left = PAD + w + 14
	for l in [kicker, title, headline, unit]:
		l.position.x = _left
	set_right([right[0].text, right[1].text, right[2].text])
	headline_under_title(_under)


## Where the right-hand lines start: lower when something sits over them (the Bench's upgrade button).
func right_from(y: float) -> void:
	for k in range(RIGHT_LINES):
		right[k].position.y = y + k * 24


## The right-hand lines, top right; up to three, the rest dropped.
func set_right(lines: Array) -> void:
	var any := false
	for k in range(RIGHT_LINES):
		right[k].text = str(lines[k]) if k < lines.size() else ""
		any = any or right[k].text != ""
	# with no right-hand lines the kicker and the title take the width
	_right_any = any
	kicker.size.x = size.x - _left - PAD - (RIGHT_W if any else 0)
	title.size.x = kicker.size.x
	if _under:
		headline_under_title(true)


## A progress bar along the foot, in place of the chips.
func set_bar(fraction: float, words: String) -> void:
	bar.visible = true
	chips.visible = false
	_bar_fill.size.x = bar.size.x * clampf(fraction, 0.0, 1.0)
	_bar_label.text = words


## The chip row along the foot. See Chips.show_chips for the items.
func set_chips(items: Array) -> void:
	chips.visible = not items.is_empty()
	bar.visible = false
	chips.show_chips(items)
	if chips.visible:
		headline_under_title(true)      # the foot is the chips' now


## The site the skyline is drawn for: the same name draws the same skyline every time.
func set_site(site: String) -> void:
	var s := hash(site)
	if s != _seed:
		_seed = s
		var tex := UI.place_texture(site)
		_art.texture = tex
		if tex != null:                       # pixel art scaled up stays crisp; scaled down (688 into 608 or 501), smoothed
			_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if tex.get_width() <= size.x else CanvasItem.TEXTURE_FILTER_LINEAR
		_art.visible = tex != null
		_art_fade.visible = tex != null
		queue_redraw()


## The painted art and its shade: the band's backdrop, under everything (a face, the words) - not something on it.
func is_backdrop(c: Node) -> bool:
	return c == _art or c == _art_fade


## For the tests: the painted art showing, or the skyline.
func has_art() -> bool:
	return _art.visible


## The sky's tone: a zone's number, or the rooms' own past the zones.
func set_tone(tone: int) -> void:
	var t := clampi(tone, 0, SKY.size() - 1)
	if t != _tone:
		_tone = t
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if _art.visible:
		return                                # the painted art and its shade are children: nothing under them
	var sky: Color = SKY[_tone]
	var ground: Color = GROUND[_tone]
	# the sky, as strips from the zone's tone down to its ground; the top corners rounded like the card's
	var top := UI.box(sky, 8)
	top.corner_radius_bottom_left = 0
	top.corner_radius_bottom_right = 0
	draw_style_box(top, Rect2(0, 0, w, h * 0.2))
	var strips := 16
	for k in range(strips):
		var f := float(k) / strips
		if h * f < h * 0.15:
			continue
		draw_rect(Rect2(0, h * f, w, h / strips + 1), sky.lerp(ground, f))
	# the skyline: blocks of a few greys, widths and heights from the site's seed
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var x := 0.0
	# the blocks sit a little lighter or darker than the ground they stand on
	var greys := [ground.lightened(0.10), ground.darkened(0.35), ground.lightened(0.18), ground.darkened(0.2), ground.lightened(0.05)]
	while x < w:
		var bw := rng.randf_range(24.0, 72.0)
		var bh := rng.randf_range(h * 0.16, h * 0.52)
		var g: Color = greys[rng.randi_range(0, greys.size() - 1)]
		draw_rect(Rect2(x, h - bh, bw, bh), g)
		# a window or two, lit
		if rng.randf() < 0.35:
			draw_rect(Rect2(x + rng.randf_range(4.0, bw - 10.0), h - bh + rng.randf_range(6.0, bh * 0.5), 5, 4), Color("d9a24a", 0.55))
		x += bw + rng.randf_range(0.0, 10.0)
	# the fade into the card, so the headline and the chips read
	var fade_from := h * 0.5
	var steps := 12
	for k in range(steps):
		var f := float(k) / steps
		var c := Color(_fade_to, lerpf(0.0, 0.97, f * f))
		draw_rect(Rect2(0, fade_from + (h - fade_from) * f, w, (h - fade_from) / steps + 1), c)


## For the tests: every label with text.
func text_nodes() -> Array:
	var out: Array = [kicker, title, headline, unit]
	out.append_array(right)
	if chips.visible:
		out.append_array(chips.text_nodes())
	if bar.visible:
		out.append(_bar_label)
	return out
