extends Node2D
## The runner's line of sight (build 76, board D: "zoomed out, line of sight"; Matt: "look at zero sievert for inspo").
## What the cover hides from the runner goes dark under a fog; men out of sight aren't drawn, and a man you lose leaves
## a fading "Last seen" mark where you last saw him; crates and the way out show once seen and stay (dimmed in the fog).
##
## The lit shape is one polygon a step: the ground round the camera, less the shadow behind each piece of cover the
## runner can see past (Geometry2D's clipping, in the engine, so it's cheap: about 40 clips a step). The cover itself
## stays lit - you see the car, not what's behind it. The fog is drawn as the quads between the lit shape's edges and
## a ring far out (the shape is star-shaped round the runner, so they tile without overlapping: one even darkness).
## The world steps it (world.tick) after the gang, so a headless check reads the same verdicts the screen shows.

const T := preload("res://slice/tuning.gd")

## Every word the fog puts on screen (for the language pass).
const WORDS := {"last_seen": "Last seen"}

const C_FOG := Color(0.043, 0.047, 0.051)     # board D's #0b0c0d
const C_MARK := Color("f08a74")               # board D's last-seen ring and words

var world: Node = null                # SliceWorld (untyped: the two scripts name each other)
var lit := PackedVector2Array()       # the lit polygon, world px
var marks: Array = []                 # {pos, t, life, node}: a man lost from sight
var _seen := {}                       # man (instance id) -> seen last step
var _seen_at := {}                    # man (instance id) -> where he was when last seen
var _from := Vector2.INF              # where the lit shape was last built from (the runner)
var _cam := Vector2.INF               # ...and the camera then
var builds := 0                       # lit shapes built (a check reads that a still runner doesn't rebuild)
var clipped := 0                      # (round 5's review) the cover clipped in the last build: only what can shade the view
const REBUILD_PX := 4.0               # (round 5's review) the runner moves this far before the lit shape's built again
var build_us := 0                     # the last build's time, microseconds


func setup(w: Node) -> void:
	world = w
	z_as_relative = true


## One step: the lit shape (when the runner or the camera moved), then who and what he sees.
func step(dt: float) -> void:
	if world == null or world.runner == null:
		return
	var o: Vector2 = world.runner.position
	var cam: Vector2 = world.cam_center
	if lit.is_empty() or o.distance_squared_to(_from) > REBUILD_PX * REBUILD_PX or cam.distance_squared_to(_cam) > 64.0:
		_build(o, cam)
	_judge_men()
	_judge_things()
	for m in marks:
		m["t"] = float(m["t"]) - dt
	marks = marks.filter(func(m): return float(m["t"]) > 0.0)
	queue_redraw()


## The ground the fog has to cover: the camera's view and a margin (the lead and the shake can't show past it).
func bound() -> Rect2:
	var vw: Vector2 = world.view_world() if world.has_method("view_world") else Vector2(T.PARK_W, T.PARK_H)
	var c: Vector2 = world.cam_center
	var b := Rect2(c - vw * 0.5, vw).grow(T.FOG_MARGIN)
	return b.merge(Rect2(world.runner.position, Vector2.ZERO).grow(T.FOG_MARGIN))


func _far() -> float:
	var b := bound()
	return b.size.length() * 2.0


func _build(o: Vector2, cam: Vector2) -> void:
	var t0 := Time.get_ticks_usec()
	_from = o
	_cam = cam
	builds += 1
	var b := bound()
	var shape := PackedVector2Array([b.position, Vector2(b.end.x, b.position.y), b.end, Vector2(b.position.x, b.end.y)])
	var far := _far()
	clipped = 0
	for c in world.level.cover:
		var r: Rect2 = c
		if not r.intersects(b):
			continue                  # (round 5's review) the runner's inside the bound, a convex box: a ray from him leaves it
			                          # once, so the shadow behind cover wholly outside it never comes back in
		clipped += 1
		var behind := shadow_behind(r, o, far)
		if behind.is_empty():
			continue
		var out := Geometry2D.clip_polygons(shape, behind)
		var keep := PackedVector2Array()
		for poly in out:                  # the piece round the runner (the rest is cut off from him: unseen)
			if Geometry2D.is_point_in_polygon(o, poly):
				keep = poly
				break
		if not keep.is_empty():
			shape = keep
	lit = shape
	build_us = Time.get_ticks_usec() - t0


## The region behind a piece of cover as seen from o, out to `far`: the hull of its corners and their projections, less
## the cover itself (so the cover stays lit). Empty when o is inside it.
static func shadow_behind(r: Rect2, o: Vector2, far: float) -> PackedVector2Array:
	if r.has_point(o):
		return PackedVector2Array()
	var pts := PackedVector2Array()
	for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var cv: Vector2 = c
		pts.append(cv)
		pts.append(cv + (cv - o).normalized() * far)
	var hull := Geometry2D.convex_hull(pts)
	var rect_poly := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var out := Geometry2D.clip_polygons(hull, rect_poly)
	var best := PackedVector2Array()
	var best_a := -1.0
	for p in out:                     # one piece (the cover sits on the hull's near side); the biggest if Clipper splits it
		var a := absf(_area(p))
		if a > best_a:
			best_a = a
			best = p
	return best


static func _area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in range(p.size()):
		a += p[i].cross(p[(i + 1) % p.size()])
	return a * 0.5


## Does the runner see p? Its centre or a point r to either side across the line of sight (a man half round a car is
## seen). Cover blocks sight; men don't (the world's has_los).
func can_see(p: Vector2, r := 0.0) -> bool:
	if world == null or world.runner == null:
		return false
	var o: Vector2 = world.runner.position
	if world.has_los(o, p):
		return true
	if r <= 0.0 or p.distance_to(o) < 1.0:
		return false
	var side: Vector2 = (p - o).normalized().orthogonal() * r
	return world.has_los(o, p + side) or world.has_los(o, p - side)


func is_seen(man: Node) -> bool:
	return bool(_seen.get(man.get_instance_id(), false))


func _judge_men() -> void:
	if world.men_root == null:
		return
	var now := {}
	var at := {}
	for n in world.men_root.get_children():
		if not n.is_in_group("slice_man"):
			continue
		var man: Node2D = n
		var id := man.get_instance_id()
		var dead: bool = man.has_method("is_dead") and man.is_dead()
		if dead:                             # a body stays as it fell: seen if he died in sight, hidden if not; (round 5's
			now[id] = man.visible            # review) his last-seen mark fades on its own - its going would tell you he died
			continue
		var r = man.get("radius")
		var seen := can_see(man.position, (float(r) if r != null else T.MAN_R) * T.SIGHT_SIDE)
		if seen:
			marks = marks.filter(func(m): return m["node"] != man)
			at[id] = man.position
		else:
			if bool(_seen.get(id, false)):    # lost him: a mark where he was last seen (last step's place, not where he went)
				marks.append({"pos": _seen_at.get(id, man.position), "t": T.LAST_SEEN_S, "life": T.LAST_SEEN_S, "node": man})
			if _seen_at.has(id):
				at[id] = _seen_at[id]
		man.visible = seen
		now[id] = seen
	_seen = now
	_seen_at = at


## Crates and the way out: hidden until first seen, then kept.
func _judge_things() -> void:
	for c in world.crates():
		if not bool(c.get("seen")):
			if can_see(c.position, T.CRATE_SIZE * 0.45):
				c.seen = true
			c.visible = bool(c.get("seen"))
	var lv = world.level
	if not lv.exit_seen:
		var e: Rect2 = lv.exit_rect
		for p in [e.get_center(), e.position, Vector2(e.end.x, e.position.y), e.end, Vector2(e.position.x, e.end.y)]:
			if can_see(p):
				lv.exit_seen = true
				lv.queue_redraw()
				break


func _draw() -> void:
	if world == null or lit.size() < 3:
		return
	var pts := PackedVector2Array()
	var idx := PackedInt32Array()
	for q in fog_quads():
		var k := pts.size()
		pts.append_array(q)
		idx.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
	var cols := PackedColorArray()
	cols.resize(pts.size())
	cols.fill(Color(C_FOG, T.FOG_ALPHA))
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts, cols)
	var f: Font = world.font() if world.has_method("font") else ThemeDB.fallback_font
	var fs := int(round(T.MARK_FONT / T.CAM_ZOOM))
	for m in marks:
		var k2: float = clampf(float(m["t"]) / float(m["life"]), 0.0, 1.0)
		var p: Vector2 = m["pos"]
		var col := Color(C_MARK, 0.8 * k2)
		var rr: float = T.MAN_R
		for i in range(12):                  # a dashed ring
			var a0 := TAU * i / 12.0
			draw_arc(p, rr, a0, a0 + TAU / 24.0, 4, col, 2.0 / T.CAM_ZOOM)
		var w := f.get_string_size(WORDS["last_seen"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, p + Vector2(-w * 0.5, rr + fs + 4.0), WORDS["last_seen"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## The fog: a quad from each edge of the lit shape out to the far ring, along the runner's lines of sight. The lit
## shape is star-shaped round him, so the quads meet edge to edge and never overlap (the check samples it).
func fog_quads() -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var o: Vector2 = _from
	var far := _far()
	var n := lit.size()
	for i in range(n):
		var a: Vector2 = lit[i]
		var b: Vector2 = lit[(i + 1) % n]
		out.append(PackedVector2Array([a, b, o + (b - o).normalized() * far, o + (a - o).normalized() * far]))
	return out


## (for G's round.gd, if wanted) How much of a figure at `to` (radius r) the cover hides from `from`: 0 all in the open,
## 1 all hidden - n sample points across his width.
static func hidden_share(w: Node, from: Vector2, to: Vector2, r: float, n := 5) -> float:
	if n < 1 or from.distance_to(to) < 1.0:
		return 0.0
	var side := (to - from).normalized().orthogonal() * r
	var hid := 0
	for i in range(n):
		var s := -1.0 + 2.0 * float(i) / float(maxi(1, n - 1)) if n > 1 else 0.0
		if not w.has_los(from, to + side * s):
			hid += 1
	return float(hid) / float(n)
