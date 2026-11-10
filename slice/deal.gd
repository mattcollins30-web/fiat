extends RefCounted
## A level dealt from pieces (board L, 10 Nov): a 4 x 3 grid of pieces, each a walled room or open ground, picked and
## joined by the seed. The way in (and out) is the bottom-left piece; the prize is in the piece furthest from it by the
## ways through; the gangs' gates are on the outer edge of far pieces. Open pieces run into each other; a walled piece
## has a doorway to each piece it's joined to, two at least, so no room is a dead end with one door (bar the grid's
## corners, which have two neighbours and a door to both). Every piece keeps a clear cross through its middle, so each
## doorway, the prize and the gates are on walkable ground: slice/level.gd's reach check walks it in the smoke.
## The layout is data ({size, floors, walls, cover, spawns, gates, entry, exit_rect, prize, cells, doors}):
## slice/level.gd builds and draws it.

const T := preload("res://slice/tuning.gd")

const COLS := 4
const ROWS := 3
const CW := 1408.0                    # a piece: 22 x 16 tiles
const CH := 1024.0
const WALL := 32.0                    # a wall's thickness, half a tile
const DOOR := 192.0                   # a doorway, three tiles
const MARGIN := 124.0                 # a piece's things keep this far in from its edge (a man walks the wall's foot)
const LANE := 104.0                   # ...and this far either side of its middle lines (the clear cross)
const WALLED := ["room", "aisles", "store", "hall", "office", "tills"]


static func cell_rect(c: Vector2i) -> Rect2:
	return Rect2(c.x * CW, c.y * CH, CW, CH)


static func _cells() -> Array:
	var out: Array = []
	for y in range(ROWS):
		for x in range(COLS):
			out.append(Vector2i(x, y))
	return out


static func _near(c: Vector2i) -> Array:
	var out: Array = []
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = c + d
		if n.x >= 0 and n.y >= 0 and n.x < COLS and n.y < ROWS:
			out.append(n)
	return out


static func _key(a: Vector2i, b: Vector2i) -> String:
	var lo: Vector2i = a if (a.y < b.y or (a.y == b.y and a.x < b.x)) else b
	var hi: Vector2i = b if lo == a else a
	return "%d,%d-%d,%d" % [lo.x, lo.y, hi.x, hi.y]


## The level for `place` (SliceTuning.PLACES' entry) on `seed_v`: the same seed, the same level.
static func deal(place: Dictionary, seed_v: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v * 7919 + 17
	var size := Vector2(COLS * CW, ROWS * CH)
	var entry_c := Vector2i(0, ROWS - 1)
	# which pieces are walled: the place's count, never the way in
	var others: Array = _cells().filter(func(c): return c != entry_c)
	_shuffle(others, rng)
	var walled := {}
	for i in range(mini(int(place.get("walled", 0)), others.size())):
		walled[others[i]] = true
	var pieces := {}
	var open_pool: Array = place.get("open", ["path"])
	var shut_pool: Array = place.get("shut", ["room"])
	for c in _cells():
		var pool: Array = shut_pool if walled.has(c) else open_pool
		pieces[c] = str(pool[rng.randi_range(0, pool.size() - 1)])
	pieces[entry_c] = "path"
	# the ways through: open to open runs free; a wall between any other pair, a doorway where the seed joins them
	var doors := {}
	var seen := {entry_c: true}
	var stack: Array = [entry_c]
	while not stack.is_empty():                 # a walk over every piece: each is reached
		var at: Vector2i = stack.back()
		var next: Array = _near(at).filter(func(n): return not seen.has(n))
		if next.is_empty():
			stack.pop_back()
			continue
		var to: Vector2i = next[rng.randi_range(0, next.size() - 1)]
		seen[to] = true
		stack.append(to)
		if walled.has(at) or walled.has(to):
			doors[_key(at, to)] = true
	for c in _cells():                          # no walled piece with one door
		if not walled.has(c):
			continue
		var shut: Array = _near(c).filter(func(n): return not doors.has(_key(c, n)))
		_shuffle(shut, rng)
		while _near(c).size() - shut.size() < 2 and not shut.is_empty():
			doors[_key(c, shut.pop_back())] = true
	# the walls
	var walls: Array = []
	for c in _cells():
		for d in [Vector2i(1, 0), Vector2i(0, 1)]:
			var n: Vector2i = c + d
			if n.x >= COLS or n.y >= ROWS or not (walled.has(c) or walled.has(n)):
				continue
			var r := cell_rect(n)
			var door: bool = doors.has(_key(c, n))
			if d.x == 1:
				_wall(walls, Rect2(r.position.x - WALL * 0.5, r.position.y, WALL, CH), door, false)
			else:
				_wall(walls, Rect2(r.position.x, r.position.y - WALL * 0.5, CW, WALL), door, true)
	# how far each piece is from the way in, by the ways through
	var dist := {entry_c: 0}
	var todo: Array = [entry_c]
	while not todo.is_empty():
		var at: Vector2i = todo.pop_front()
		for n in _near(at):
			if dist.has(n) or not (doors.has(_key(at, n)) or (not walled.has(at) and not walled.has(n))):
				continue
			dist[n] = int(dist[at]) + 1
			todo.append(n)
	var far: Array = _cells()
	_shuffle(far, rng)
	far.sort_custom(func(a, b): return int(dist.get(a, 0)) > int(dist.get(b, 0)))
	var prize_c: Vector2i = far[0]
	var prize: Vector2 = cell_rect(prize_c).get_center()
	# the gangs' gates: on the outer edge of pieces two or more from the way in, never the prize's
	var gates: Array = []
	var spawns: Array = []
	for c in far:
		if spawns.size() >= int(place.get("gates", 3)):
			break
		if c == prize_c or int(dist.get(c, 0)) < 2:
			continue
		var mid: Vector2 = cell_rect(c).get_center()
		var sides: Array = []
		if c.y == 0:
			sides.append([Vector2(mid.x, T.EDGE + 110.0), Rect2(mid.x - 130.0, 0.0, 260.0, T.EDGE)])
		if c.x == COLS - 1:
			sides.append([Vector2(size.x - T.EDGE - 110.0, mid.y), Rect2(size.x - T.EDGE, mid.y - 130.0, T.EDGE, 260.0)])
		if c.y == ROWS - 1:
			sides.append([Vector2(mid.x, size.y - T.EDGE - 110.0), Rect2(mid.x - 130.0, size.y - T.EDGE, 260.0, T.EDGE)])
		if c.x == 0:
			sides.append([Vector2(T.EDGE + 110.0, mid.y), Rect2(0.0, mid.y - 130.0, T.EDGE, 260.0)])
		if sides.is_empty():
			continue
		var side: Array = sides[rng.randi_range(0, sides.size() - 1)]
		spawns.append(side[0])
		gates.append(side[1])
	var exit_rect := Rect2(T.EDGE + 40.0, size.y - T.EDGE - 40.0 - T.EXIT_H, T.EXIT_W, T.EXIT_H)
	var entry := Vector2(600.0, size.y - CH * 0.5)
	# what stands in each piece, clear of the way in and out
	var cover: Array = []
	var floors: Array = []
	for c in _cells():
		var r := cell_rect(c)
		floors.append({"rect": r, "kind": str(pieces[c]), "walled": walled.has(c)})
		for it in _piece(str(pieces[c]), rng):
			var rect: Rect2 = it["rect"]
			rect.position += r.position
			if rect.intersects(exit_rect.grow(220.0)) or rect.grow(170.0).has_point(entry):
				continue
			cover.append({"kind": it["kind"], "rect": rect})
	return {"size": size, "floors": floors, "walls": walls, "cover": cover, "spawns": spawns, "gates": gates, "entry": entry,
		"exit_rect": exit_rect, "prize": prize, "prize_cell": prize_c, "cells": pieces, "walled": walled, "doors": doors,
		"dist": dist, "seed": seed_v, "place": str(place.get("id", ""))}


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


## A wall along `r` (the long way: `across`), whole, or in two with a doorway in its middle.
static func _wall(walls: Array, r: Rect2, door: bool, across: bool) -> void:
	if not door:
		walls.append(r)
		return
	if across:
		var half: float = (r.size.x - DOOR) * 0.5
		walls.append(Rect2(r.position, Vector2(half, r.size.y)))
		walls.append(Rect2(r.position + Vector2(half + DOOR, 0.0), Vector2(half, r.size.y)))
	else:
		var half_v: float = (r.size.y - DOOR) * 0.5
		walls.append(Rect2(r.position, Vector2(r.size.x, half_v)))
		walls.append(Rect2(r.position + Vector2(0.0, half_v + DOOR), Vector2(r.size.x, half_v)))


## A piece's things, in its own pixels: each quarter filled by the piece's kind, the cross through the middle left clear.
static func _piece(kind: String, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	var qw: float = CW * 0.5 - MARGIN - LANE
	var qh: float = CH * 0.5 - MARGIN - LANE
	var k := 0
	for o in [Vector2(MARGIN, MARGIN), Vector2(CW * 0.5 + LANE, MARGIN), Vector2(MARGIN, CH * 0.5 + LANE), Vector2(CW * 0.5 + LANE, CH * 0.5 + LANE)]:
		for it in _quarter(kind, k, qw, qh, rng):
			var rect: Rect2 = it["rect"]
			out.append({"kind": it["kind"], "rect": Rect2(rect.position + o, rect.size)})
		k += 1
	return out


## One quarter (w x h px) of a piece of `kind`; `k`: which quarter (0 to 3).
static func _quarter(kind: String, k: int, w: float, h: float, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	var jx: float = rng.randf_range(0.0, 60.0)
	var jy: float = rng.randf_range(0.0, 40.0)
	match kind:
		"plots":                                        # raised beds in rows, across or down
			if rng.randf() < 0.5:
				out.append({"kind": "bed", "rect": Rect2(jx, 20.0, w - 80.0, 64.0)})
				out.append({"kind": "bed", "rect": Rect2(60.0 - jx, 190.0, w - 80.0, 64.0)})
			else:
				for i in range(3):
					out.append({"kind": "bed", "rect": Rect2(30.0 + i * 160.0 + jx * 0.5, jy, 64.0, h - 60.0)})
		"shed":
			if k % 2 == rng.randi_range(0, 1):
				out.append({"kind": "shed", "rect": Rect2(40.0 + jx, 30.0 + jy, 230.0, 180.0)})
				out.append({"kind": "butt", "rect": Rect2(290.0 + jx, 40.0 + jy, 56.0, 56.0)})
			else:
				out.append({"kind": "bed", "rect": Rect2(jx, 60.0 + jy, w - 100.0, 64.0)})
				out.append({"kind": "compost", "rect": Rect2(w - 150.0, 170.0, 96.0, 96.0)})
		"greenhouse":                                   # a glass frame, its door to the south: you can step inside
			if k % 2 == 0:
				out.append({"kind": "glass", "rect": Rect2(20.0, 10.0, 420.0, 20.0)})
				out.append({"kind": "glass", "rect": Rect2(20.0, 30.0, 20.0, 220.0)})
				out.append({"kind": "glass", "rect": Rect2(420.0, 30.0, 20.0, 220.0)})
				out.append({"kind": "glass", "rect": Rect2(20.0, 250.0, 130.0, 20.0)})
				out.append({"kind": "glass", "rect": Rect2(310.0, 250.0, 130.0, 20.0)})
			else:
				out.append({"kind": "bed", "rect": Rect2(jx, 30.0 + jy, w - 90.0, 64.0)})
				out.append({"kind": "butt", "rect": Rect2(120.0 + jx, 180.0, 56.0, 56.0)})
		"path":                                         # near bare: a compost bin, a water butt
			if rng.randf() < 0.7:
				out.append({"kind": "compost", "rect": Rect2(80.0 + jx * 3.0, 60.0 + jy * 2.0, 96.0, 96.0)})
			if rng.randf() < 0.5:
				out.append({"kind": "butt", "rect": Rect2(300.0 + jx, 180.0 + jy, 56.0, 56.0)})
		"yard":                                         # pallets and something parked
			out.append({"kind": "pallet", "rect": Rect2(20.0 + jx, 20.0 + jy, 112.0, 112.0)})
			if k % 2 == 0:
				out.append({"kind": "tractor" if rng.randf() < 0.5 else "van", "rect": Rect2(250.0 + jx, 20.0, 140.0, 250.0)})
			else:
				out.append({"kind": "pallet", "rect": Rect2(220.0 + jx, 130.0 + jy, 112.0, 112.0)})
		"aisles":                                       # shelving in runs
			if k < 2:
				for i in range(3):
					out.append({"kind": "shelf", "rect": Rect2(40.0 + i * 160.0, 0.0, 44.0, h - 20.0)})
			else:
				out.append({"kind": "shelf", "rect": Rect2(0.0, 40.0, w - 40.0, 44.0)})
				out.append({"kind": "shelf", "rect": Rect2(40.0, 200.0, w - 40.0, 44.0)})
		"tills":
			for i in range(3):
				out.append({"kind": "counter", "rect": Rect2(20.0 + i * 160.0, 40.0 + (i % 2) * 130.0 + jy, 120.0, 52.0)})
		"store":                                        # pallets stacked, gaps between
			for i in range(2):
				for j in range(2):
					if rng.randf() < 0.8:
						out.append({"kind": "pallet", "rect": Rect2(30.0 + i * 220.0 + jx * 0.5, 10.0 + j * 160.0, 112.0, 112.0)})
		"hall":                                         # a barn's posts and bales
			out.append({"kind": "post", "rect": Rect2(w * 0.5 - 30.0, h * 0.5 - 30.0, 60.0, 60.0)})
			if rng.randf() < 0.6:
				out.append({"kind": "bale", "rect": Rect2(20.0 + jx, 20.0 + jy, 160.0, 96.0)})
		"office":
			out.append({"kind": "desk", "rect": Rect2(30.0 + jx, 30.0, 150.0, 72.0)})
			out.append({"kind": "desk", "rect": Rect2(250.0, 170.0 + jy, 150.0, 72.0)})
			if k % 2 == 1:
				out.append({"kind": "screen", "rect": Rect2(210.0, 0.0, 22.0, 150.0)})
		_:                                              # "room": a shelf and a crate of nothing
			out.append({"kind": "shelf", "rect": Rect2(40.0 + jx * 2.0, 30.0 + jy, 44.0, 200.0)})
			if rng.randf() < 0.5:
				out.append({"kind": "pallet", "rect": Rect2(250.0, 150.0, 112.0, 112.0)})
	# nothing past the quarter's own ground (the cross and the wall's foot stay clear)
	return out.filter(func(it): return Rect2(0.0, 0.0, w, h).encloses(it["rect"]))
