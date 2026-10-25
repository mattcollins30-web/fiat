extends Control
## The points key (23 Oct, Matt's playtest: a free Knuckles point showed only as "1 free" in that region's label;
## "something somewhere needs to tell you all points that are available - a key on the map tree itself would be
## easiest"). A panel in the canvas's corner: every pool with its points free - the class's, the Pitch's, the ring's -
## then the six elements, each as a meter in its colour (a point when it fills) with its free points beside. The
## words came off the regions' labels: this is where the pools and the meters live.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")

const KEY_W := 300.0
const PAD := 14.0
const ROW_H := 24.0
const HEAD_H := 22.0
const BAR_H := 8.0
const NAME_W := 96.0
const FREE_W := 52.0

var sim
var _font: Font
var _font_bold: Font
var _rows: Array = []              # [name, sub, free words, tone, meter (-1 for none)]
var _sig := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = UI.font("Regular", false)
	_font_bold = UI.font("SemiBold", false)
	size = Vector2(KEY_W, height_for(3 + Data.TYPES.size()))


static func height_for(rows: int) -> float:
	return PAD + HEAD_H + 3 * ROW_H + 10.0 + HEAD_H + (rows - 3) * ROW_H + PAD - 6.0


func show_state(s) -> void:
	sim = s
	var rows: Array = []
	var pf: int = sim.points_free()
	rows.append([str(sim.cls) if sim.cls != "" else "The class", "class", "%d of %d free" % [pf, sim.training_points], Pal.TEXT_2, -1.0])
	rows.append(["The Pitch", "the Yard", "%d free" % sim.pitch_free(), Pal.TEXT_2, -1.0])     # the glossary: the Pitch's tree is the Yard, never "camp" (the language pass)
	rows.append(["The ring", "paragon", "%d free" % sim.paragon_free(), Pal.TEXT_2, -1.0])
	for et in Data.ELEMENT_TREES:
		var el: String = str(et["element"])
		var free_v: int = maxi(0, sim.element_free(el))
		var meter: float = clampf(float(sim.element_xp.get(el, 0.0)) / Data.ELEMENT_METER, 0.0, 1.0)
		var free_s: String = (("%d free" % free_v) if free_v < 100 else "99+ free") if free_v > 0 else ""
		if not sim.element_opened(el):
			free_s = Words.ELEMENT_SHUT                # the Pitch circle (24 Oct): a Pitch point on its starter opens it
		rows.append([str(et["name"]), el, free_s, Pal.ELEMENT_COLOURS.get(el, Pal.TEXT), meter])     # an element pool has no top (the review): the figure's room is FREE_W
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
		if r[4] < 0.0:
			var free_w: float = _font_bold.get_string_size(str(r[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			var nw: float = _font.get_string_size(str(r[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 6.0 + _font.get_string_size(str(r[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			if nw + 8.0 + free_w > KEY_W - 2 * PAD:
				out.append("%s %s · %s" % [r[0], r[1], r[2]])
		else:
			if _font.get_string_size(str(r[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x > NAME_W - 6.0:
				out.append(str(r[0]))
			if _font.get_string_size(str(r[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > FREE_W:
				out.append(str(r[2]))
	return out


func _draw() -> void:
	draw_style_box(UI.box(Color(Pal.CARD, 0.92), 8, 1, Pal.CARD_LINE), Rect2(Vector2.ZERO, size))
	if _rows.is_empty():
		return
	var x := PAD
	var y := PAD + 12.0
	draw_string(_font_bold, Vector2(x, y), "POINTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.TEXT_3)
	y += HEAD_H - 6.0
	for r in _rows.slice(0, 3):
		y += ROW_H
		var free_s: String = str(r[2])
		var lit: bool = not free_s.begins_with("0")
		draw_string(_font, Vector2(x, y - 7.0), str(r[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Pal.TEXT_2)
		var nw: float = _font.get_string_size(str(r[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(_font, Vector2(x + nw + 6.0, y - 7.0), str(r[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.TEXT_3)
		var fw: float = _font_bold.get_string_size(free_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(_font_bold, Vector2(size.x - PAD - fw, y - 7.0), free_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Pal.GOOD if lit else Pal.TEXT_3)
	y += 10.0
	draw_line(Vector2(x, y), Vector2(size.x - PAD, y), Pal.CARD_LINE, 1.0)
	y += HEAD_H - 4.0
	draw_string(_font_bold, Vector2(x, y), "THE ELEMENTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.TEXT_3)     # the label in caps, the note after it in sentence case (the language pass: one role a string)
	var hw: float = _font_bold.get_string_size("THE ELEMENTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(_font, Vector2(x + hw + 10.0, y), Words.ELEMENTS_NOTE, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.TEXT_3)
	y += 4.0
	for r in _rows.slice(3):
		y += ROW_H
		var tone: Color = r[3]
		draw_string(_font, Vector2(x, y - 7.0), str(r[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tone)
		var bx: float = x + NAME_W
		var bw: float = size.x - PAD - FREE_W - 8.0 - bx
		draw_rect(Rect2(bx, y - 12.0 - BAR_H / 2.0, bw, BAR_H), Color("2a2f35"))
		if float(r[4]) > 0.0:
			draw_rect(Rect2(bx, y - 12.0 - BAR_H / 2.0, bw * float(r[4]), BAR_H), tone)
		var free_s: String = str(r[2]) if str(r[2]) != "" else "—"
		var fw: float = _font.get_string_size(free_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(_font, Vector2(size.x - PAD - fw, y - 7.0), free_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Pal.GOOD if (str(r[2]) != "" and str(r[2]) != Words.ELEMENT_SHUT) else Pal.TEXT_3)
