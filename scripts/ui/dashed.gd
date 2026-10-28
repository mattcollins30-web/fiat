extends Control
## A dashed outline (28 Oct, the Radio's mockups RadioAir and RadioDial; Matt: "the Radio looks crap"): a place that's
## empty and says what goes in it - a decoder slot, a signal slot, a paper still wanted. Draws nothing but the dashes
## (and a fill when given); its words are the parent's labels.

const LINE := Color("4a5059")       # the web's dim link: reads on the panel where CARD_LINE is lost

var colour := LINE
var fill := Color(0, 0, 0, 0)
var dash := 6.0


func _init(sz := Vector2.ZERO, c := LINE) -> void:
	size = sz
	colour = c
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_colour(c: Color) -> void:
	if c != colour:
		colour = c
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2(0.5, 0.5), size - Vector2(1, 1))
	if fill.a > 0.0:
		draw_rect(r, fill)
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in range(4):
		draw_dashed_line(pts[k], pts[(k + 1) % 4], colour, 1.0, dash)
