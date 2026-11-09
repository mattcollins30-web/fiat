extends Node2D
## The Estate's car park (build 72, board A): the floor, the painted bays, the cover - two burnt-out cars, the
## walls, the bins - the crates' places, the gang's ways in, and the way out. Drawn in code (tokens, no art).
## The layout is data here so the world's sight and collision read the same rectangles the eye does.

const T := preload("res://slice/tuning.gd")

const C_FLOOR := Color("30333a")
const C_GRID := Color("383b42")
const C_BAY := Color("8a8466")
const C_SHADOW := Color(0, 0, 0, 0.35)
const C_EDGE := Color("23252a")
const C_EXIT := Color("3fae7a")
const KIND_COLOUR := {"car_burnt": Color("3b2c27"), "car_grey": Color("4a4d55"), "wall": Color("6b5a4c"), "bin": Color("2e4a35")}
const KIND_LINE := {"car_burnt": Color("1e1613"), "car_grey": Color("2a2c31"), "wall": Color("4a3e34"), "bin": Color("1b2d20")}

## The cover: {kind, rect}. The cars sit in the top row of bays; the walls cut the park into lanes; the bins pair up.
const COVER := [
	{"kind": "car_burnt", "rect": Rect2(2085, 470, 150, 260)},
	{"kind": "car_grey", "rect": Rect2(2685, 470, 150, 260)},
	{"kind": "wall", "rect": Rect2(1050, 1500, 700, 40)},
	{"kind": "wall", "rect": Rect2(3000, 1650, 40, 520)},
	{"kind": "wall", "rect": Rect2(3550, 980, 620, 40)},
	{"kind": "bin", "rect": Rect2(3700, 1440, 70, 70)},
	{"kind": "bin", "rect": Rect2(3775, 1440, 70, 70)},
	{"kind": "bin", "rect": Rect2(880, 700, 70, 70)},
	{"kind": "bin", "rect": Rect2(955, 700, 70, 70)},
	{"kind": "bin", "rect": Rect2(4150, 2150, 70, 70)},
	{"kind": "bin", "rect": Rect2(4225, 2150, 70, 70)},
	{"kind": "bin", "rect": Rect2(1900, 2050, 70, 70)},
	{"kind": "bin", "rect": Rect2(1975, 2050, 70, 70)},
]
## Painted bays: rows of {x0, y, count, up}; a bay's open end faces the lane.
const BAYS := [
	{"x0": 1785, "y": 450, "count": 10},
	{"x0": 1785, "y": 2330, "count": 6},
	{"x0": 3300, "y": 2330, "count": 6},
]
const CRATES := [Vector2(640, 1050), Vector2(2460, 1240), Vector2(3880, 620), Vector2(4380, 1820)]
const SPAWNS := [Vector2(2400, 140), Vector2(4000, 140), Vector2(4660, 800), Vector2(4660, 1900), Vector2(1200, 140), Vector2(3200, 2560)]
const ENTRY := Vector2(420, 2240)    # where the runner comes in, beside the way out

var park_rect := Rect2(0, 0, T.PARK_W, T.PARK_H)
var exit_rect := Rect2(T.EDGE + 40.0, T.PARK_H - T.EDGE - 40.0 - T.EXIT_H, T.EXIT_W, T.EXIT_H)
var exit_lit := false                # the clear lights the way out up
var cover: Array = []                # Rect2s, the cover only
var blocks: Array = []               # Rect2s, the cover and the park's edge walls (moving and sight)


func build() -> void:
	cover.clear()
	for c in COVER:
		cover.append(c["rect"])
	blocks = cover.duplicate()
	var e := T.EDGE
	blocks.append(Rect2(0, 0, T.PARK_W, e))
	blocks.append(Rect2(0, T.PARK_H - e, T.PARK_W, e))
	blocks.append(Rect2(0, 0, e, T.PARK_H))
	blocks.append(Rect2(T.PARK_W - e, 0, e, T.PARK_H))
	for r in blocks:                    # the physics bodies, for G's men if they move with move_and_slide
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = (r as Rect2).size
		shape.shape = rs
		body.position = (r as Rect2).get_center()
		body.add_child(shape)
		add_child(body)
	queue_redraw()


func _draw() -> void:
	draw_rect(park_rect, C_FLOOR)
	var step := 256.0
	var x := 0.0
	while x <= T.PARK_W:
		draw_line(Vector2(x, 0), Vector2(x, T.PARK_H), C_GRID, 2.0)
		x += step
	var y := 0.0
	while y <= T.PARK_H:
		draw_line(Vector2(0, y), Vector2(T.PARK_W, y), C_GRID, 2.0)
		y += step
	for row in BAYS:
		var n: int = int(row["count"])
		for i in range(n + 1):
			var bx: float = float(row["x0"]) + i * T.BAY_W
			draw_line(Vector2(bx, row["y"]), Vector2(bx, float(row["y"]) + T.BAY_H), C_BAY, 4.0)
		draw_line(Vector2(row["x0"], row["y"]), Vector2(float(row["x0"]) + n * T.BAY_W, row["y"]), C_BAY, 4.0)
	# the way out
	var ec := C_EXIT if exit_lit else Color(C_EXIT, 0.55)
	draw_rect(exit_rect, Color(ec, 0.10 if not exit_lit else 0.22))
	draw_rect(exit_rect, ec, false, 4.0)
	var mid := exit_rect.get_center()
	draw_line(mid + Vector2(-50, 50), mid + Vector2(50, -50), ec, 6.0)
	draw_line(mid + Vector2(50, -50), mid + Vector2(10, -50), ec, 6.0)
	draw_line(mid + Vector2(50, -50), mid + Vector2(50, -10), ec, 6.0)
	# the cover, a shadow under each
	for c in COVER:
		var r: Rect2 = c["rect"]
		draw_rect(Rect2(r.position + Vector2(8, 10), r.size), C_SHADOW)
		draw_rect(r, KIND_COLOUR[c["kind"]])
		draw_rect(r, KIND_LINE[c["kind"]], false, 3.0)
		if str(c["kind"]).begins_with("car"):      # a burnt-out car: a windscreen's gap
			draw_rect(Rect2(r.position + Vector2(18, 50), Vector2(r.size.x - 36, 46)), Color(KIND_LINE[c["kind"]], 0.8))
	# the edge walls
	var e := T.EDGE
	for r in [Rect2(0, 0, T.PARK_W, e), Rect2(0, T.PARK_H - e, T.PARK_W, e), Rect2(0, 0, e, T.PARK_H), Rect2(T.PARK_W - e, 0, e, T.PARK_H)]:
		draw_rect(r, C_EDGE)
