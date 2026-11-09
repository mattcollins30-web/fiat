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
const KIND_COLOUR := {"car_burnt": Color("3b2c27"), "car_grey": Color("4a4d55"), "van": Color("5a5f52"), "wall": Color("6b5a4c"),
	"low_wall": Color("7a6a58"), "bin": Color("2e4a35"), "shelter": Color("56646e"), "kiosk": Color("3a2e2a")}
const KIND_LINE := {"car_burnt": Color("1e1613"), "car_grey": Color("2a2c31"), "van": Color("33362e"), "wall": Color("4a3e34"),
	"low_wall": Color("564a3c"), "bin": Color("1b2d20"), "shelter": Color("343d44"), "kiosk": Color("1e1714")}

## The cover, in TILES (x, y, w, h; halves allowed) so the geometry can take a tile set later: {kind, tiles}.
## Round 2 (Matt: "a tad bigger to allow more hiding"): the park 90 x 50 tiles; more cars and bins, a low wall run, a
## bus shelter, a parked van and a burnt-out kiosk with a doorway gap you can step into. The open bands at rows
## 13-21 and 27-38 are the men's flanking lanes; the bottom left (the way in and out) stays clear.
## COVER[2] stays a wall with open ground either side (the world's check stands above and below it).
const COVER := [
	{"kind": "car_burnt", "tiles": Rect2(30.75, 7.5, 2, 4)},       # the top row of bays
	{"kind": "car_grey", "tiles": Rect2(40.75, 7.5, 2, 4)},
	{"kind": "wall", "tiles": Rect2(16, 23.5, 11, 0.75)},          # the long wall
	{"kind": "wall", "tiles": Rect2(47, 26, 0.75, 9)},
	{"kind": "wall", "tiles": Rect2(56, 15, 10, 0.75)},
	{"kind": "car_grey", "tiles": Rect2(45.75, 7.5, 2, 4)},
	{"kind": "car_burnt", "tiles": Rect2(33.25, 39.5, 2, 4)},      # the bottom rows of bays
	{"kind": "car_grey", "tiles": Rect2(57.25, 39.5, 2, 4)},
	{"kind": "car_burnt", "tiles": Rect2(82, 40, 2, 4)},
	{"kind": "van", "tiles": Rect2(72, 12, 2.5, 5)},               # a parked van
	{"kind": "low_wall", "tiles": Rect2(66, 30, 12, 0.5)},         # a low wall run
	{"kind": "shelter", "tiles": Rect2(12, 5, 6, 0.5)},            # the bus shelter: its back and two ends, open to the south
	{"kind": "shelter", "tiles": Rect2(12, 5.5, 0.5, 1.5)},
	{"kind": "shelter", "tiles": Rect2(17.5, 5.5, 0.5, 1.5)},
	{"kind": "kiosk", "tiles": Rect2(36, 22, 5, 0.5)},             # the burnt-out kiosk: four walls, a doorway on the south
	{"kind": "kiosk", "tiles": Rect2(36, 22.5, 0.5, 3.5)},
	{"kind": "kiosk", "tiles": Rect2(40.5, 22.5, 0.5, 3.5)},
	{"kind": "kiosk", "tiles": Rect2(36.5, 25.5, 1, 0.5)},         # the doorway: two tiles, x 37.5-39.5
	{"kind": "kiosk", "tiles": Rect2(39.5, 25.5, 1, 0.5)},
	{"kind": "bin", "tiles": Rect2(13, 11, 1, 1)},
	{"kind": "bin", "tiles": Rect2(14, 11, 1, 1)},
	{"kind": "bin", "tiles": Rect2(60, 23, 1, 1)},
	{"kind": "bin", "tiles": Rect2(61, 23, 1, 1)},
	{"kind": "bin", "tiles": Rect2(69, 35, 1, 1)},
	{"kind": "bin", "tiles": Rect2(70, 35, 1, 1)},
	{"kind": "bin", "tiles": Rect2(31, 33, 1, 1)},
	{"kind": "bin", "tiles": Rect2(32, 33, 1, 1)},
	{"kind": "bin", "tiles": Rect2(78, 24, 1, 1)},
	{"kind": "bin", "tiles": Rect2(78, 25, 1, 1)},
	{"kind": "bin", "tiles": Rect2(50, 18, 1, 1)},
	{"kind": "bin", "tiles": Rect2(51, 18, 1, 1)},
	{"kind": "bin", "tiles": Rect2(24, 42, 1, 1)},
	{"kind": "bin", "tiles": Rect2(25, 42, 1, 1)},
	{"kind": "car_burnt", "tiles": Rect2(50.75, 7.5, 2, 4)},
	{"kind": "car_burnt", "tiles": Rect2(62.25, 39.5, 2, 4)},
	{"kind": "car_grey", "tiles": Rect2(23, 13, 4, 2)},            # left across the lane
	{"kind": "low_wall", "tiles": Rect2(20, 33, 0.5, 5)},
	{"kind": "bin", "tiles": Rect2(54, 30, 1, 1)},
	{"kind": "bin", "tiles": Rect2(55, 30, 1, 1)},
	{"kind": "bin", "tiles": Rect2(8, 26, 1, 1)},
	{"kind": "bin", "tiles": Rect2(8, 27, 1, 1)},
]
const KIOSK_INSIDE := Rect2(36.5, 22.5, 4, 3)    # tiles: the kiosk's floor (the reach check walks into it)
## Painted bays, in tiles: rows of {x0, y, count}; a bay is BAY_W x BAY_H.
const BAYS := [
	{"x0": 28, "y": 7, "count": 10},
	{"x0": 28, "y": 39, "count": 6},
	{"x0": 52, "y": 39, "count": 6},
]
## In pixels (points, not tiles). CRATES[0] and [1] keep open ground below them (the checks stand there); [4] is in the kiosk.
const CRATES := [Vector2(760, 1240), Vector2(2950, 1500), Vector2(4400, 680), Vector2(5240, 2180), Vector2(2464, 1536)]
const SPAWNS := [Vector2(2880, 140), Vector2(4800, 140), Vector2(5620, 960), Vector2(5620, 2280), Vector2(1440, 140), Vector2(3840, 3060)]
const ENTRY := Vector2(600, 2400)    # where the runner comes in, above the way out (h72_slice's walk from here beats the first gang)


static func tiles_px(t: Rect2) -> Rect2:
	return Rect2(t.position * T.TILE, t.size * T.TILE)


## The cover as pixel rectangles with their kinds.
static func cover_px() -> Array:
	return COVER.map(func(c): return {"kind": c["kind"], "rect": tiles_px(c["tiles"])})


var park_rect := Rect2(0, 0, T.PARK_W, T.PARK_H)
var exit_rect := Rect2(T.EDGE + 40.0, T.PARK_H - T.EDGE - 40.0 - T.EXIT_H, T.EXIT_W, T.EXIT_H)
var exit_lit := false                # the clear lights the way out up
var cover: Array = []                # Rect2s, the cover only
var blocks: Array = []               # Rect2s, the cover and the park's edge walls (moving and sight)


func build() -> void:
	cover.clear()
	for c in COVER:
		cover.append(tiles_px(c["tiles"]))
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
	var step := T.TILE * 4.0
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
		var x0: float = float(row["x0"]) * T.TILE
		var y0: float = float(row["y"]) * T.TILE
		for i in range(n + 1):
			var bx: float = x0 + i * T.BAY_W
			draw_line(Vector2(bx, y0), Vector2(bx, y0 + T.BAY_H), C_BAY, 4.0)
		draw_line(Vector2(x0, y0), Vector2(x0 + n * T.BAY_W, y0), C_BAY, 4.0)
	draw_rect(tiles_px(KIOSK_INSIDE), Color("26221f"))     # the kiosk's burnt floor
	# the way out
	var ec := C_EXIT if exit_lit else Color(C_EXIT, 0.55)
	draw_rect(exit_rect, Color(ec, 0.10 if not exit_lit else 0.22))
	draw_rect(exit_rect, ec, false, 4.0)
	var mid := exit_rect.get_center()
	draw_line(mid + Vector2(-50, 50), mid + Vector2(50, -50), ec, 6.0)
	draw_line(mid + Vector2(50, -50), mid + Vector2(10, -50), ec, 6.0)
	draw_line(mid + Vector2(50, -50), mid + Vector2(50, -10), ec, 6.0)
	# the cover, a shadow under each
	for c in cover_px():
		var r: Rect2 = c["rect"]
		draw_rect(Rect2(r.position + Vector2(8, 10), r.size), C_SHADOW)
		draw_rect(r, KIND_COLOUR[c["kind"]])
		draw_rect(r, KIND_LINE[c["kind"]], false, 3.0)
		if str(c["kind"]).begins_with("car") or c["kind"] == "van":      # a windscreen's gap
			draw_rect(Rect2(r.position + Vector2(16, 44), Vector2(r.size.x - 32, 40)), Color(KIND_LINE[c["kind"]], 0.8))
	# the edge walls
	var e := T.EDGE
	for r in [Rect2(0, 0, T.PARK_W, e), Rect2(0, T.PARK_H - e, T.PARK_W, e), Rect2(0, 0, e, T.PARK_H), Rect2(T.PARK_W - e, 0, e, T.PARK_H)]:
		draw_rect(r, C_EDGE)


## (round 2) The cells a circle of radius r can stand on and walk to from `from`, on a REACH_CELL grid (4-way).
## Returns {"cell": float, "seen": {Vector2i: true}}; on(p) below asks it. Sight isn't asked: only that the way is open.
func reach(from: Vector2, r: float) -> Dictionary:
	var c := T.REACH_CELL
	var nx := int(T.PARK_W / c)
	var ny := int(T.PARK_H / c)
	var free := func(i: int, j: int) -> bool:
		var p := Vector2((i + 0.5) * c, (j + 0.5) * c)
		for b in blocks:
			var rect: Rect2 = b
			var q := Vector2(clampf(p.x, rect.position.x, rect.end.x), clampf(p.y, rect.position.y, rect.end.y))
			if q.distance_to(p) < r:
				return false
		return true
	var start := Vector2i(int(from.x / c), int(from.y / c))
	var seen := {}
	if not free.call(start.x, start.y):
		return {"cell": c, "seen": seen}
	var todo: Array[Vector2i] = [start]
	seen[start] = true
	while not todo.is_empty():
		var k: Vector2i = todo.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = k + d
			if n.x < 0 or n.y < 0 or n.x >= nx or n.y >= ny or seen.has(n):
				continue
			if free.call(n.x, n.y):
				seen[n] = true
				todo.append(n)
	return {"cell": c, "seen": seen}


## Is there a reached cell within `within` px of p?
static func reached_near(rc: Dictionary, p: Vector2, within: float) -> bool:
	var c: float = rc["cell"]
	var k := int(ceil(within / c))
	var at := Vector2i(int(p.x / c), int(p.y / c))
	for i in range(-k, k + 1):
		for j in range(-k, k + 1):
			var n := at + Vector2i(i, j)
			if rc["seen"].has(n) and Vector2((n.x + 0.5) * c, (n.y + 0.5) * c).distance_to(p) <= within:
				return true
	return false
