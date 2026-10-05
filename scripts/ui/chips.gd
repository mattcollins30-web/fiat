extends Control
## A row of chips: small rounded tags in a tone, laid left to right across
## a width. Each item offers its words long and short; a chip takes the
## first form that fits what's left of the row, and chips past the row's
## end are dropped from the right. Shared by the band, the Runs cards and
## the rest of the A-style screens, so every chip reads the same.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")

const MAX := 6
const CHIP_H := 26
const CHIP_PAD := 8
const CHIP_GAP := 6

var _panels: Array[Panel] = []
var _labels: Array[Label] = []
var _shown := 0


func _init(w: float) -> void:
	size = Vector2(w, CHIP_H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in range(MAX):
		var p := UI.panel(self, Rect2(0, 0, 10, CHIP_H), UI.box(Pal.BUTTON, 6))
		p.visible = false
		_panels.append(p)
		_labels.append(UI.label(p, Rect2(CHIP_PAD, 0, 10, CHIP_H), "", "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))


## `items`: [[words, colour], ...] or [[long, short, colour], ...]; `colour`
## a Color, or a tone name for Pal.tone_color. A chip whose words are a
## tone colour is drawn on that colour darkened; a plain chip on the button grey.
func show_chips(items: Array) -> void:
	var x := 0.0
	_shown = 0
	for k in range(MAX):
		var on: bool = k < items.size()
		_panels[k].visible = on
		if not on:
			continue
		var it: Array = items[k]
		var forms: Array = [it[0], it[1]] if it.size() > 2 else [it[0]]
		var colour: Color = it.back() if it.back() is Color else Pal.tone_color(str(it.back()))
		var l: Label = _labels[k]
		l.add_theme_color_override("font_color", colour)
		var bg: Color = colour.darkened(0.72) if colour != Pal.TEXT_2 else Pal.BUTTON
		_panels[k].add_theme_stylebox_override("panel", UI.box(bg, 6))
		var w := 0.0
		for words in forms:
			w = ceilf(UI.text_width(l, words)) + 2 * CHIP_PAD
			l.text = words
			if x + w <= size.x:
				break
		if x + w > size.x:
			for j in range(k, MAX):
				_panels[j].visible = false
			break
		_panels[k].position.x = x
		_panels[k].size.x = w
		l.size.x = w - 2 * CHIP_PAD
		x += w + CHIP_GAP
		_shown = k + 1


## How many chips the row shows.
func shown() -> int:
	return _shown


## The chip labels showing, for the tests.
func text_nodes() -> Array:
	var out: Array = []
	for k in range(_shown):
		out.append(_labels[k])
	return out


## The words on chip k, for the tests.
func words(k: int) -> String:
	return _labels[k].text if k < _shown else ""
