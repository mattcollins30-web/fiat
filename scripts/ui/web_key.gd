extends Control
## The web's key (3 Nov, docs/design/skill_web.md "The screen"; was the points key of 23 Oct, every pool and the
## elements' meters - one counter now, in the band): in the canvas's foot, what the three states look like (yours, can
## take, not yet), the big nodes' gates, and the paragon points free (they buy only the ring).

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Words := preload("res://scripts/sim/words.gd")

const KEY_W := 330.0
const PAD := 12.0
const ROW_H := 23.0
const MARK := 12.0                 # a row's mark: a lit disc, an amber ring, a dark ring, a diamond
const TEXT_X := PAD + MARK + 10.0
const SIZE := 14
const Data := preload("res://scripts/sim/data.gd")
const KEYSTONE_AT := Data.KEYSTONE_SPENT     # the big nodes' gates: points spent first
const CAPSTONE_AT := Data.CAPSTONE_SPENT

var sim
var _font: Font
var _font_bold: Font
var _rows: Array = []              # [mark, words, tone]; the paragon row's mark is "paragon", its words its count
var _sig := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = UI.font("Regular", false)
	_font_bold = UI.font("SemiBold", false)
	size = Vector2(KEY_W, height_for(5))


static func height_for(rows: int) -> float:
	return 2.0 * PAD + rows * ROW_H - 4.0


func show_state(s) -> void:
	sim = s
	var WS: Dictionary = Words.WEB_SCREEN
	var rows: Array = [["lit", WS["key_yours"], Pal.GOOD], ["ring", WS["key_take"], Pal.ACCENT], ["dark", WS["key_dark"], Pal.CARD_LINE],
		["diamond", WS["key_big"] % [KEYSTONE_AT, CAPSTONE_AT], Pal.TEXT_2], ["paragon", WS["key_paragon_free"] % int(sim.paragon_free()), Pal.ACCENT]]
	var sig := str(rows)
	if sig == _sig:
		return
	_sig = sig
	_rows = rows
	queue_redraw()


## The words drawn that don't fit their room, for the smoke (the key is drawn, not Labels): [] when all fit.
func fit_fails() -> Array:
	var out: Array = []
	for r in _rows:
		var w: float = _row_width(r)
		if TEXT_X + w > KEY_W - PAD:
			out.append(str(r[1]))
	return out


func _row_width(r: Array) -> float:
	if str(r[0]) == "paragon":
		return _font.get_string_size(Words.WEB_SCREEN["key_paragon"], HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x + 8.0 + _font_bold.get_string_size(str(r[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
	return _font.get_string_size(str(r[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x


func _draw() -> void:
	draw_style_box(UI.box(Color(Pal.CARD, 0.92), 8, 1, Pal.CARD_LINE), Rect2(Vector2.ZERO, size))
	var y := PAD
	for r in _rows:
		var c := Vector2(PAD + MARK / 2.0, y + ROW_H / 2.0 - 2.0)
		var tone: Color = r[2]
		match str(r[0]):
			"lit":
				draw_circle(c, MARK / 2.0 + 3.0, Color(tone, 0.2))
				draw_circle(c, MARK / 2.0, tone)
			"ring":
				draw_circle(c, MARK / 2.0, Pal.CARD)
				draw_arc(c, MARK / 2.0 - 1.0, 0.0, TAU, 24, tone, 2.0, true)
			"dark":
				draw_circle(c, MARK / 2.0, Pal.BG)
				draw_arc(c, MARK / 2.0 - 0.5, 0.0, TAU, 24, Pal.TEXT_3, 1.0, true)
			"diamond":
				var h: float = MARK / 2.0 + 1.0
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -h), c + Vector2(h, 0), c + Vector2(0, h), c + Vector2(-h, 0)]), Pal.TEXT_3)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -h + 2), c + Vector2(h - 2, 0), c + Vector2(0, h - 2), c + Vector2(-h + 2, 0)]), Pal.BG)
			"paragon":
				draw_arc(c, MARK / 2.0 - 1.0, 0.0, TAU, 12, tone, 1.5, true)
		var base := Vector2(TEXT_X, y + ROW_H / 2.0 + 3.0)
		if str(r[0]) == "paragon":
			var lw: float = _font.get_string_size(Words.WEB_SCREEN["key_paragon"], HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
			draw_string(_font, base, Words.WEB_SCREEN["key_paragon"], HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Pal.TEXT_2)
			draw_string(_font_bold, base + Vector2(lw + 8.0, 0), str(r[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Pal.GOOD if not str(r[1]).begins_with("0") else Pal.TEXT_3)
		else:
			draw_string(_font, base, str(r[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Pal.TEXT_2)
		y += ROW_H
