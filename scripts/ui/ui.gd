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
