extends Control
## Chips: small rounded tags in a tone, laid left to right across a width,
## wrapping to a second row when asked. Each item offers its words long and
## short; a chip takes the first form that fits what's left of its row, and
## chips past the room are dropped from the right. A chip can carry a small
## tag before its words (an affix's tier) and a muted tail after them (a
## word's effect). `show_rows` lays one chip a row, the width of the row:
## the shape the Runs card and the radio use for the word, so a label and
## its words read as one toned thing. Shared by the band, the Runs cards,
## the item head and the rest of the A-style screens, so every chip reads
## the same.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")

const MAX := 6
const CHIP_H := 26
const CHIP_PAD := 8
const CHIP_GAP := 6
const ROW_GAP := 4
const TAG_SIZE := 13

var _panels: Array[Panel] = []
var _labels: Array[Label] = []
var _tags: Array[Label] = []
var _tails: Array[Label] = []
var _shown := 0
var _rows_used := 1


func _init(w: float) -> void:
	size = Vector2(w, CHIP_H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in range(MAX):
		var p := UI.panel(self, Rect2(0, 0, 10, CHIP_H), UI.box(Pal.BUTTON, 6))
		p.visible = false
		_panels.append(p)
		_tags.append(UI.label(p, Rect2(CHIP_PAD, 0, 10, CHIP_H), "", "SemiBold", TAG_SIZE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT))
		_labels.append(UI.label(p, Rect2(CHIP_PAD, 0, 10, CHIP_H), "", "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		_tails.append(UI.label(p, Rect2(CHIP_PAD, 0, 10, CHIP_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))


## An item as a dictionary: {"forms": [long, shorter...], "colour": Color or tone,
## "tag": "T3", "tail": "" or [long, shorter...]}. The array shapes still work:
## [words, colour] or [long, short, colour].
static func _item(it) -> Dictionary:
	if it is Dictionary:
		var d: Dictionary = it.duplicate()
		if not (d.get("forms") is Array):
			d["forms"] = [str(d.get("forms", d.get("text", "")))]
		if not (d.get("tail", "") is Array):
			d["tail"] = [str(d.get("tail", ""))]
		return d
	var a: Array = it
	return {"forms": [a[0], a[1]] if a.size() > 2 else [a[0]], "colour": a.back(), "tag": "", "tail": [""]}


static func _colour_of(c) -> Color:
	return c if c is Color else Pal.tone_color(str(c))


## The chips across the row, wrapping to `rows` rows; the rest dropped from the right.
func show_chips(items: Array, rows := 1) -> void:
	var x := 0.0
	var row := 0
	_shown = 0
	_rows_used = 1
	for k in range(MAX):
		var on: bool = k < items.size()
		_panels[k].visible = on
		if not on:
			continue
		var d := _item(items[k])
		var w := _lay(k, d, size.x - x)
		if w > size.x - x and x > 0.0 and row + 1 < rows:
			row += 1
			x = 0.0
			w = _lay(k, d, size.x)
		if w > size.x - x:
			for j in range(k, MAX):
				_panels[j].visible = false
			break
		_panels[k].position = Vector2(x, row * (CHIP_H + ROW_GAP))
		x += w + CHIP_GAP
		_shown = k + 1
		_rows_used = row + 1
	size.y = _rows_used * (CHIP_H + ROW_GAP) - ROW_GAP


## One chip a row, each the row's width: the name in its tone, the words muted
## beside it; `rows` at most, the rest dropped from the end.
func show_rows(items: Array, rows := MAX) -> void:
	_shown = 0
	for k in range(MAX):
		var on: bool = k < items.size() and k < rows
		_panels[k].visible = on
		if not on:
			continue
		var d := _item(items[k])
		_lay(k, d, size.x)
		_panels[k].position = Vector2(0, k * (CHIP_H + ROW_GAP))
		_panels[k].size.x = size.x
		_shown = k + 1
	_rows_used = maxi(1, _shown)
	size.y = _rows_used * (CHIP_H + ROW_GAP) - ROW_GAP


## Lays chip k's tag, words and tail in `room`, taking each one's first form
## that fits; returns the chip's width (which may exceed the room when
## nothing short enough exists: the caller drops it).
func _lay(k: int, d: Dictionary, room: float) -> float:
	var colour := _colour_of(d.get("colour", Pal.TEXT_2))
	var l: Label = _labels[k]
	var tg: Label = _tags[k]
	var tl: Label = _tails[k]
	l.add_theme_color_override("font_color", colour)
	tg.add_theme_color_override("font_color", colour)
	tg.text = str(d.get("tag", ""))
	tg.visible = tg.text != ""
	var bg: Color = colour.darkened(0.72) if colour != Pal.TEXT_2 else Pal.BUTTON
	_panels[k].add_theme_stylebox_override("panel", UI.box(bg, 6))
	var tag_w: float = (ceilf(UI.text_width(tg, tg.text)) + 6.0) if tg.visible else 0.0
	tg.size.x = tag_w
	var w := 0.0
	var tails: Array = d.get("tail", [""])
	for words in d["forms"]:
		l.text = str(words)
		var lw := ceilf(UI.text_width(l, l.text))
		# the tail: its first form that fits beside the words; none when none does
		tl.text = ""
		for t in tails:
			if str(t) == "":
				continue
			var tw := ceilf(UI.text_width(tl, str(t))) + 8.0
			if 2 * CHIP_PAD + tag_w + lw + tw <= room:
				tl.text = str(t)
				break
		var tail_w: float = (ceilf(UI.text_width(tl, tl.text)) + 8.0) if tl.text != "" else 0.0
		w = 2 * CHIP_PAD + tag_w + lw + tail_w
		if w <= room:
			break
	tl.visible = tl.text != ""
	l.position.x = CHIP_PAD + tag_w
	l.size.x = ceilf(UI.text_width(l, l.text))
	tl.position.x = l.position.x + l.size.x + 8.0
	tl.size.x = maxf(1.0, ceilf(UI.text_width(tl, tl.text)))
	_panels[k].size = Vector2(w, CHIP_H)
	return w


## How many chips are showing.
func shown() -> int:
	return _shown


## How many rows the chips took.
func rows_used() -> int:
	return _rows_used


## The labels showing, for the tests.
func text_nodes() -> Array:
	var out: Array = []
	for k in range(_shown):
		out.append(_labels[k])
		if _tags[k].visible:
			out.append(_tags[k])
		if _tails[k].visible:
			out.append(_tails[k])
	return out


## The words on chip k, for the tests; `tail` for its tail.
func words(k: int) -> String:
	return _labels[k].text if k < _shown else ""


func tail(k: int) -> String:
	return _tails[k].text if k < _shown and _tails[k].visible else ""
