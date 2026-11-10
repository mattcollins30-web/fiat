extends Node2D
## The ARPG slice's world (build 72, option A: top-down, close): the Estate's car park, the runner, firing, crates,
## the way out, the camera. A sandbox - nothing here is saved to the camp. The game's maths come through
## slice/bridge.gd (G); the gang is slice/gang.gd (G); the HUD and the end screen are slice/hud.gd (H), under hud_layer.
## Everything moves in tick(dt), which _physics_process calls, so a headless check can step it frame by frame.
## The API for G and H: the build's w72_notes.md.
const SliceRunner := preload("res://slice/runner.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const SliceLevel := preload("res://slice/level.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const SliceCrate := preload("res://slice/crate.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const SliceFx := preload("res://slice/fx.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const SliceBridge := preload("res://slice/bridge.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)

const T := preload("res://slice/tuning.gd")
const UI := preload("res://scripts/ui/ui.gd")
const LevelScript := preload("res://slice/level.gd")
const RunnerScript := preload("res://slice/runner.gd")
const CrateScript := preload("res://slice/crate.gd")
const FxScript := preload("res://slice/fx.gd")
const GangScript := preload("res://slice/gang.gd")
const SightScript := preload("res://slice/sight.gd")

## Every word the world puts on screen (for the language pass).
const WORDS := {
	"you": "You",
	"search_key": "Hold F · Search",
	"open_key": "F · Search",
	"open_pad": "A · Search",
	"search_pad": "Hold A · Search",
	"out_key": "Hold X · Get out",
	"out_pad": "Hold B · Get out",
}

signal fired(gun: Dictionary)
signal hit_landed(man: Node, result: Dictionary, point: Vector2)
signal missed(point: Vector2)
signal reload_started(gun: Dictionary, secs: float)
signal reloaded(gun: Dictionary)
signal jammed(gun: Dictionary)
signal dry(gun: Dictionary)                     # (round 6) a fresh pull on an empty gun with nothing to reload
signal man_down(man: Node)                      # (round 6) every man's death, whatever killed him
signal swapped(gun_index: int)
signal search_progress(crate: Node, frac: float)
signal crate_opened(crate: Node, finds: Array)
signal search_asked(thing: Node)                # (board M) F at a crate or a body: the search screen opens on it
signal runner_hurt(res: Dictionary)
signal last_legs()
signal died()
signal cleared_park()
signal left()
signal run_ended(outcome: String, stats: Dictionary)

var ctx: Dictionary = {}
var rng := RandomNumberGenerator.new()
var level: SliceLevel
var runner: SliceRunner
var crates_root: Node2D
var men_root: Node2D
var fx: SliceFx
var sight: Node2D                    # (build 76) slice/sight.gd: the fog over what the cover hides, the last-seen marks
var camera: Camera2D
var hud_layer: CanvasLayer
var gang: Node = null
var search_ui := false               # (board M) the search is a screen (launch.gd sets it): F opens it, a man down leaves a body
var search_thing: SliceCrate = null  # ...the crate or body being searched while it's open
var _use_was := false
var nav: AStarGrid2D = null          # (board L) a dealt level's ways round its walls, for the men; null in the car park
var park_rect := Rect2(0, 0, T.PARK_W, T.PARK_H)
var exit_rect := Rect2()
var time_s := 0.0
var cleared := false
var loop := false                    # (board I) the run's loop: gangs till he leaves, crates after each, no clear (ctx["loop"])
var ended := false
var outcome := ""                    # "", "cleared", "out", "died"
var stats: Dictionary = {}
var pad := false                     # the last control touched was the pad (the prompts' words)
var cam_center := Vector2.ZERO
var screen_override := Vector2.ZERO  # (build 76) a check's screen size (1920 x 1200) for view_size(); zero: the viewport's
var shake_px := 0.0
var started := false
var _dmg_frac := 0.0                 # a dot's damage under one, carried
var _heal_frac := 0.0                # a kill's heal under one, carried
var _font: Font = null


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


## H's entry: ctx from SliceBridge.runner_ctx, a seed (fixed in the smoke).
func start(c: Dictionary, seed_n: int = 72) -> void:
	ctx = c
	rng.seed = seed_n
	stats = {"kills": 0, "headshots": 0, "damage_done": 0, "damage_taken": 0, "shots": 0, "hits": 0, "time_s": 0.0, "haul": []}
	level = LevelScript.new()
	level.name = "Level"
	if ctx.get("layout") is Dictionary and not (ctx["layout"] as Dictionary).is_empty():
		level.layout = ctx["layout"]           # (board L) a level dealt from pieces
	add_child(level)
	level.build()
	park_rect = level.park_rect
	exit_rect = level.exit_rect
	if level.dealt():
		_build_nav()
	crates_root = Node2D.new()
	crates_root.name = "Crates"
	add_child(crates_root)
	loop = bool(ctx.get("loop", false))
	if loop:
		# (board I) no crates stand out at the start: only the prize, the place's crate furthest from the way out
		add_crate(level.prize_spot(), true)
		stats["gangs_beaten"] = 0
		stats["crates_opened"] = 0
		stats["prize"] = false
	else:
		for p in level.crate_spots():
			add_crate(p)
	men_root = Node2D.new()
	men_root.name = "Men"
	add_child(men_root)
	sight = SightScript.new()            # (build 76) over the level, the crates and the men; under the runner, the marks, the rounds
	sight.name = "Sight"
	add_child(sight)
	runner = RunnerScript.new()
	runner.name = "Runner"
	runner.position = level.entry()
	add_child(runner)
	runner.setup(self, ctx)
	fx = FxScript.new()
	fx.name = "Fx"
	add_child(fx)
	camera = Camera2D.new()
	camera.name = "Camera"
	camera.zoom = Vector2(T.CAM_ZOOM, T.CAM_ZOOM)     # (build 76) half the old zoom: twice the ground
	add_child(camera)
	if camera.is_inside_tree():
		camera.make_current()            # (outside the tree - a headless check - there's no viewport to own)
	cam_center = _cam_goal()
	camera.position = _cam_pos()
	hit_landed.connect(func(m, res, _p): _mark_for(m, "head" if bool(res.get("headshot", false)) else "hit"))     # (round 7) the crosshair's marks
	man_down.connect(func(m): _mark_for(m, "kill"))
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HudLayer"
	hud_layer.layer = 10
	add_child(hud_layer)
	gang = GangScript.new()
	gang.name = "Gang"
	add_child(gang)
	gang.setup(self)
	sight.setup(self)
	sight.step(0.0)
	started = true


func _ready() -> void:
	if camera != null:
		camera.make_current()


func font() -> Font:
	if _font == null:
		_font = UI.font("SemiBold")
	return _font


func _physics_process(delta: float) -> void:
	if started:
		tick(delta)


## One step of everything: the runner, the gang (G's tick), the marks, the camera, the clock.
func tick(dt: float) -> void:
	if ended:
		return
	time_s += dt
	runner.tick(dt)
	if gang != null and gang.has_method("tick"):
		gang.tick(dt)
	if search_thing != null and is_instance_valid(search_thing):
		search_tick(search_thing, dt)
	fx.exit_prompt = ""
	if exit_rect.has_point(runner.position) and not ended:
		fx.exit_prompt = WORDS["out_pad"] if pad else WORDS["out_key"]
		fx.exit_at = Vector2(exit_rect.get_center().x, exit_rect.position.y - 24.0)
	fx.reticle = runner.aim if runner.aim_mode == "pad" else Vector2.INF
	fx.reticle_locked = runner.locked != null
	fx.cross = runner.aim if not runner.dead else Vector2.INF
	fx.cross_r = runner.cross_r()
	fx.step(dt)
	_camera_step(dt)
	sight.step(dt)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.4):
		pad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		pad = false


# ---------------------------------------------------------------- the camera
## How far the camera leans from the runner toward his aim: further down the sights (10 Nov).
func cam_lead() -> Vector2:
	var down: bool = bool(runner.get("sights"))
	var lead: Vector2 = (runner.aim - runner.position) * (T.G_SIGHTS_LEAD if down else T.CAM_LEAD)
	return lead.limit_length(T.G_SIGHTS_LEAD_MAX if down else T.CAM_LEAD_MAX)


func _cam_goal() -> Vector2:
	var lead := cam_lead()
	var half := view_world() * 0.5
	var g := runner.position + lead
	return Vector2(clampf(g.x, half.x, park_rect.size.x - half.x), clampf(g.y, half.y, park_rect.size.y - half.y))


func _camera_step(dt: float) -> void:
	cam_center = cam_center.lerp(_cam_goal(), clampf(T.CAM_FOLLOW * dt, 0.0, 1.0))
	camera.position = _cam_pos()
	shake_px = maxf(0.0, shake_px - T.SHAKE_DECAY * dt)
	camera.offset = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * shake_px if shake_px > 0.0 else Vector2.ZERO


## The screen in canvas pixels (1920 x 1080, or 1920 x 1200 on a 16:10 screen); the project's size headless.
func view_size() -> Vector2:
	if screen_override != Vector2.ZERO:
		return screen_override
	var v := get_viewport_rect().size if is_inside_tree() else Vector2.ZERO
	if v.x < 1.0 or v.y < 1.0:
		v = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width", 1920), ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	return v


## The crosshair's mark for a round landed on `m` or his death - not for a man the fog hides (round 5's rule: no flash,
## no number, nothing that gives him away).
func _mark_for(m, kind: String) -> void:
	if m != null and is_instance_valid(m) and m is CanvasItem and not m.visible:
		return
	fx.hit_mark(kind)


## The world's y at the play's foot, a little in from the band's top: the lowest the mouse's aim goes.
func play_foot_y() -> float:
	return screen_to_world(Vector2(0.0, play_size().y - 14.0)).y


## (round 7, board H) The play's part of the screen: all of it above the HUD's band.
func play_size() -> Vector2:
	var v := view_size()
	return Vector2(v.x, maxf(1.0, v.y - T.HUD_BAND_H))


## The camera's own position for cam_center to sit at the play's middle, not the screen's (the band is under it).
func _cam_pos() -> Vector2:
	return cam_center + Vector2(0.0, T.HUD_BAND_H * 0.5 / T.CAM_ZOOM)


## (build 76) The ground the camera shows, in world px: the play over the zoom (3840 x 1848 at 1920 x 1080; round 7: the
## band's strip is the HUD's, so the car park's edge meets the band's top and nothing of it is under a panel).
func view_world() -> Vector2:
	return play_size() / T.CAM_ZOOM


func shake(strength: float) -> void:
	shake_px = minf(T.SHAKE_MAX, maxf(shake_px, strength))


func world_to_screen(p: Vector2) -> Vector2:
	return (p - cam_center) * T.CAM_ZOOM + play_size() * 0.5


func screen_to_world(s: Vector2) -> Vector2:
	return (s - play_size() * 0.5) / T.CAM_ZOOM + cam_center


# ---------------------------------------------------------------- the geometry
## Where a circle of radius r at p ends up out of the cover and inside the park.
func resolve_circle(p: Vector2, r: float) -> Vector2:
	var q := p
	for _pass in range(3):
		for b in level.blocks:
			var rect: Rect2 = b
			var c := Vector2(clampf(q.x, rect.position.x, rect.end.x), clampf(q.y, rect.position.y, rect.end.y))
			var d := q.distance_to(c)
			if d >= r:
				continue
			if d > 0.001:
				q = c + (q - c) / d * r
			else:                            # the centre inside the rectangle: out by the nearest side
				var outs := [q.x - rect.position.x + r, rect.end.x - q.x + r, q.y - rect.position.y + r, rect.end.y - q.y + r]
				var m: int = outs.find(outs.min())
				q += [Vector2(-outs[0], 0), Vector2(outs[1], 0), Vector2(0, -outs[2]), Vector2(0, outs[3])][m]
	q.x = clampf(q.x, T.EDGE + r, park_rect.size.x - T.EDGE - r)
	q.y = clampf(q.y, T.EDGE + r, park_rect.size.y - T.EDGE - r)
	return q


## The first t in [0, 1] where a->b enters the rectangle, or -1.
static func seg_rect(a: Vector2, b: Vector2, rect: Rect2) -> float:
	var d := b - a
	var t0 := 0.0
	var t1 := 1.0
	for axis in range(2):
		var lo: float = rect.position[axis]
		var hi: float = rect.end[axis]
		if absf(d[axis]) < 0.000001:
			if a[axis] < lo or a[axis] > hi:
				return -1.0
			continue
		var ta: float = (lo - a[axis]) / d[axis]
		var tb: float = (hi - a[axis]) / d[axis]
		t0 = maxf(t0, minf(ta, tb))
		t1 = minf(t1, maxf(ta, tb))
		if t0 > t1:
			return -1.0
	return t0


## The first t in [0, 1] where a->b meets the circle, or -1.
static func seg_circle(a: Vector2, b: Vector2, c: Vector2, r: float) -> float:
	var d := b - a
	var f := a - c
	var qa := d.dot(d)
	if qa < 0.000001:
		return -1.0
	var qb := 2.0 * f.dot(d)
	var qc := f.dot(f) - r * r
	var disc := qb * qb - 4.0 * qa * qc
	if disc < 0.0:
		return -1.0
	if qc <= 0.0:
		return 0.0                           # starts inside him
	var t := (-qb - sqrt(disc)) / (2.0 * qa)
	return t if t >= 0.0 and t <= 1.0 else -1.0


# ---------------------------------------------------------------- the ways round the walls (board L)
const NAV_CELL := 64.0


## The grid the men find their way on: a cell is shut when a man standing at its middle would touch cover or a wall.
func _build_nav() -> void:
	nav = nav_grid(park_rect.size, level.blocks)


static func nav_grid(size_v: Vector2, blocks: Array) -> AStarGrid2D:
	var g := AStarGrid2D.new()
	g.region = Rect2i(0, 0, int(ceil(size_v.x / NAV_CELL)), int(ceil(size_v.y / NAV_CELL)))
	g.cell_size = Vector2(NAV_CELL, NAV_CELL)
	g.offset = Vector2(NAV_CELL, NAV_CELL) * 0.5
	g.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	g.update()
	for b in blocks:
		var r: Rect2 = (b as Rect2).grow(T.MAN_R + 2.0)
		for i in range(maxi(0, int(floor((r.position.x - NAV_CELL * 0.5) / NAV_CELL))), mini(g.region.size.x, int(ceil(r.end.x / NAV_CELL)) + 1)):
			for j in range(maxi(0, int(floor((r.position.y - NAV_CELL * 0.5) / NAV_CELL))), mini(g.region.size.y, int(ceil(r.end.y / NAV_CELL)) + 1)):
				if r.has_point(Vector2((i + 0.5) * NAV_CELL, (j + 0.5) * NAV_CELL)):
					g.set_point_solid(Vector2i(i, j), true)
	return g


## The open cell at p, or the nearest to it.
func _nav_cell(p: Vector2) -> Vector2i:
	var c := Vector2i(clampi(int(p.x / NAV_CELL), 0, nav.region.size.x - 1), clampi(int(p.y / NAV_CELL), 0, nav.region.size.y - 1))
	if not nav.is_point_solid(c):
		return c
	var best := c
	var bd := INF
	for i in range(-3, 4):
		for j in range(-3, 4):
			var n := c + Vector2i(i, j)
			if n.x < 0 or n.y < 0 or n.x >= nav.region.size.x or n.y >= nav.region.size.y or nav.is_point_solid(n):
				continue
			var d: float = Vector2((n.x + 0.5) * NAV_CELL, (n.y + 0.5) * NAV_CELL).distance_to(p)
			if d < bd:
				bd = d
				best = n
	return best


## Can a man walk a->b in a straight line (nothing within `r` of it)?
func walk_clear(a: Vector2, b: Vector2, r: float) -> bool:
	for rect in level.blocks:
		if seg_rect(a, b, (rect as Rect2).grow(r)) >= 0.0:
			return false
	return true


## Where a man at `from` heads to get to `to`: `to` itself with a clear walk (or in the car park); else the furthest
## point of the way round that he can walk straight at.
func way_to(from: Vector2, to: Vector2) -> Vector2:
	if nav == null or walk_clear(from, to, T.MAN_R * 0.9):
		return to
	var path: PackedVector2Array = nav.get_point_path(_nav_cell(from), _nav_cell(to), true)
	if path.size() < 2:
		return to
	for i in range(mini(path.size() - 1, 10), 1, -1):
		if walk_clear(from, path[i], T.MAN_R * 0.9):
			return path[i]
	return path[1]


## Cover blocks sight; men don't.
func has_los(a: Vector2, b: Vector2) -> bool:
	for rect in level.blocks:
		var t := seg_rect(a, b, rect)
		if t > 0.0 and t < 1.0:
			return false
		if t == 0.0 and not (rect as Rect2).has_point(a):
			return false
	return true


func cover_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r in level.cover:
		out.append(r)
	return out


## A free spot behind the cover nearest `near`, on the far side from `threat`.
func cover_spot(near: Vector2, threat: Vector2) -> Vector2:
	var best: Rect2 = level.cover[0]
	var bd := INF
	for r in level.cover:
		var rect: Rect2 = r
		var c := Vector2(clampf(near.x, rect.position.x, rect.end.x), clampf(near.y, rect.position.y, rect.end.y))
		var d := near.distance_to(c)
		if d < bd:
			bd = d
			best = rect
	var mid := best.get_center()
	var dir := (mid - threat).normalized() if mid.distance_to(threat) > 1.0 else Vector2.UP
	var reach := absf(dir.x) * best.size.x * 0.5 + absf(dir.y) * best.size.y * 0.5 + T.MAN_R + 12.0
	var spot: Vector2 = resolve_circle(mid + dir * reach, T.MAN_R)
	if not in_pocket(spot):
		return spot
	# (the review) behind a wall into the kiosk or the shelter's pocket: a man there sticks on the wall - round the cover's
	# other sides, nearest to behind it first
	for turn in [PI / 2.0, -PI / 2.0, PI]:
		var d2: Vector2 = dir.rotated(turn)
		var reach2: float = absf(d2.x) * best.size.x * 0.5 + absf(d2.y) * best.size.y * 0.5 + T.MAN_R + 12.0
		var p2: Vector2 = resolve_circle(mid + d2 * reach2, T.MAN_R)
		if not in_pocket(p2):
			return p2
	return resolve_circle(near, T.MAN_R)


## The pockets a man mustn't be sent into (the review: 1 pick in 100 put him inside the kiosk, behind its wall): the
## kiosk's floor and the bus shelter's three-sided pocket, a man's radius out round each.
const SHELTER_POCKET := Rect2(12.5, 5.5, 5, 1.5)     # tiles: inside the shelter's back and ends (level.gd's shelter pieces)


func in_pocket(p: Vector2) -> bool:
	if level.dealt():
		return false
	for t in [SliceLevel.KIOSK_INSIDE, SHELTER_POCKET]:
		if SliceLevel.tiles_px(t).grow(T.MAN_R).has_point(p):
			return true
	return false


func spawn_points() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p in level.spawns():
		out.append(p)
	return out


func men() -> Array:
	if men_root == null:
		return []
	return men_root.get_children().filter(func(m): return m.is_in_group("slice_man") and not m.is_dead())


## A crate at `p`; `prize`: the place's prize.
func add_crate(p: Vector2, prize := false) -> SliceCrate:
	var cr: SliceCrate = CrateScript.new()
	cr.position = p
	cr.prize = prize
	crates_root.add_child(cr)
	return cr


## (the loop, board I) A gang's last man is down: its crates appear near where its men fell (`fell`: their places), on
## clear ground, found by eye - sight shows them once seen, the map never does. Returns the crates.
func drop_crates(fell: Array) -> Array:
	var out: Array = []
	if not loop or fell.is_empty():
		return out
	stats["gangs_beaten"] = int(stats.get("gangs_beaten", 0)) + 1
	for k in range(T.G_CRATES_A_GANG):
		var from: Vector2 = fell[rng.randi_range(0, fell.size() - 1)]
		# a man who fell at the park's edge or in a crowd: wider as the tries go, then the nearest clear ground to him
		var at: Vector2 = resolve_circle(Vector2(clampf(from.x + 170.0 * k, T.EDGE + 80.0, park_rect.size.x - T.EDGE - 80.0), clampf(from.y, T.EDGE + 80.0, park_rect.size.y - T.EDGE - 80.0)), T.CRATE_SIZE)
		for i_try in range(30):
			var p: Vector2 = from + Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * rng.randf_range(T.G_CRATE_NEAR_PX[0], T.G_CRATE_NEAR_PX[1] * (1.0 + i_try / 30.0))
			p = Vector2(clampf(p.x, T.EDGE + 80.0, park_rect.size.x - T.EDGE - 80.0), clampf(p.y, T.EDGE + 80.0, park_rect.size.y - T.EDGE - 80.0))
			if resolve_circle(p, T.CRATE_SIZE).distance_to(p) < 1.0 and not exit_rect.grow(120.0).has_point(p) and not crates().any(func(c): return not c.body and c.position.distance_to(p) < T.CRATE_SIZE * 2.5):
				at = p
				break
		if exit_rect.grow(120.0).has_point(at):       # (the review) the last resort landed on the way out: off it
			at = resolve_circle(at + (park_rect.size * 0.5 - at).normalized() * 320.0, T.CRATE_SIZE)
		out.append(add_crate(at))
	return out


func crates() -> Array:
	return crates_root.get_children() if crates_root != null else []


func _radius(man: Node) -> float:
	var r = man.get("radius")
	return float(r) if r != null else T.MAN_R


## The pad's soft lock-on: the man nearest the stick's line, within LOCK_DEG and LOCK_RANGE, in sight.
func lock_target(from: Vector2, dir: Vector2) -> Node:
	var best: Node = null
	var ba := deg_to_rad(T.LOCK_DEG)
	for m in men():
		var to: Vector2 = m.position - from
		if to.length() > T.LOCK_RANGE or to.length() < 1.0:
			continue
		var a := absf(dir.angle_to(to))
		if a < ba and has_los(from, m.position):
			ba = a
			best = m
	return best


# ---------------------------------------------------------------- firing
## The runner's gun and Last legs, out as the world's signals (H's HUD listens on the world).
func runner_event(kind: String, a: Variant = null, b: Variant = null) -> void:
	match kind:
		"reload_started":
			reload_started.emit(a, b)
		"reloaded":
			reloaded.emit(a)
		"jammed":
			jammed.emit(a)
		"dry":
			dry.emit(a)
		"swapped":
			swapped.emit(a)
		"last_legs":
			last_legs.emit()


func roll_jam(g: Dictionary) -> bool:
	return SliceBridge.jams(ctx, g, rng)


func jam_s() -> float:
	return SliceBridge.jam_s(ctx)


## A round down the runner's aim: the first man or cover on its line. Returns {man, point, result}.
func shoot(r: SliceRunner, g: Dictionary) -> Dictionary:
	stats["shots"] += 1
	var spread := deg_to_rad(float(g.get("spread_deg", T.SPREAD_DEG)))
	var dir := r.aim_dir.rotated(rng.randf_range(-spread, spread))
	var from := r.position
	var to := from + dir * T.SHOT_RANGE
	var best_t := 1.0
	for rect in level.blocks:
		var t := seg_rect(from, to, rect)
		if t > 0.0 and t < best_t:
			best_t = t
	var hit_man: Node = null
	for m in men():
		var t := seg_circle(from, to, m.position, _radius(m))
		if t >= 0.0 and t < best_t:
			best_t = t
			hit_man = m
	var point := from + (to - from) * best_t
	fx.tracer(from + dir * T.BARREL, point)
	fired.emit(g)
	shake(T.SHAKE_FIRE)
	if hit_man == null:
		fx.spark(point)
		missed.emit(point)
		return {"man": null, "point": point, "result": {}}
	var shot := {"gun": g, "from": from, "point": point, "dir": dir, "dist": from.distance_to(point), "runner": r, "world": self}
	var res: Dictionary = hit_man.take_shot(shot)
	if res.get("missed", false):
		missed.emit(point)
		return {"man": hit_man, "point": point, "result": res}
	stats["hits"] += 1
	stats["damage_done"] += int(res.get("damage", 0))
	if res.get("headshot", false):
		stats["headshots"] += 1
	fx.hit_flash(hit_man)
	if hit_man.has_method("knock"):
		hit_man.knock(dir, T.KNOCK_PX / maxf(1.0, float(g.get("rof", 1.0))))
	shake(T.SHAKE_HIT)
	hit_landed.emit(hit_man, res, point)
	return {"man": hit_man, "point": point, "result": res}


## G: damage from dots (bleeds, burns) and skills, for the end screen.
## A dot's share comes a frame at a time: its fractions are carried, so a burn's whole damage is counted (the review).
func add_damage_done(n: float) -> void:
	_dmg_frac += maxf(0.0, n)
	var whole: int = int(floor(_dmg_frac))
	_dmg_frac -= float(whole)
	stats["damage_done"] += whole


## G: every man's death, from a shot, a dot or a skill. result.drops (an Array of finds) goes into the haul; the kill's
## life (res.heal, the sim's _kill_heal) to the runner, and scavenger's round (res.scav) back in the magazine (the review).
func on_man_killed(_man: Node, result: Dictionary) -> void:
	stats["kills"] += 1
	if ctx.get("place") is Dictionary:           # (board K) a run: a kill's XP, his when he gets out
		stats["xp"] = float(stats.get("xp", 0.0)) + float(ctx["t"].get("xp", 0.0)) * T.G_RUN_XP_X
	man_down.emit(_man)
	if search_ui:
		add_body(_man.global_position, result.get("drops", []))     # (board M) what he dropped is on him, to be searched for
	else:
		add_haul(result.get("drops", []))
	if runner != null:
		_heal_frac += maxf(0.0, float(result.get("heal", 0.0)))
		var whole: int = int(floor(_heal_frac))
		_heal_frac -= float(whole)
		if whole > 0:
			runner.heal(whole)
		if bool(result.get("scav", false)) and runner.gun_i < runner.rounds.size():
			if runner.rounds[runner.gun_i] < int(runner.gun().get("mag", 1)):
				runner.rounds[runner.gun_i] += 1
			else:
				runner.add_box_rounds(1)          # a full magazine: the round goes in the box


## Finds into the haul; boxes of a gun's rounds into the pack's count too (the bridge's take_rounds).
func add_haul(items: Array) -> void:
	stats["haul"].append_array(items)
	SliceBridge.stow(ctx, items)          # (round 4) into the slice's stash, the Kit room's grid; boxes of rounds to the pack's count


func use_skill(i: int) -> bool:
	return SliceBridge.use_skill(self, i, runner.aim)


func use_med(i: int) -> bool:
	return SliceBridge.use_med(self, i)


func last_legs_hp() -> int:
	return SliceBridge.last_legs_hp(ctx)


# ---------------------------------------------------------------- crates
func search_step(r: SliceRunner, held: bool, dt: float) -> void:
	var near_c: SliceCrate = null
	var nd := INF
	for c in crates():
		var cr: SliceCrate = c
		cr.near = false
		if cr.in_reach(r.position):
			var d := cr.position.distance_to(r.position) + (10000.0 if search_ui and cr.opened else 0.0)     # (the review) one not yet searched before one left with things in it
			if d < nd:
				nd = d
				near_c = cr
	r.searching = null
	var fresh: bool = held and not _use_was
	_use_was = held
	if near_c == null:
		return
	near_c.near = true
	if search_ui:
		near_c.prompt = WORDS["open_pad"] if pad else WORDS["open_key"]
		near_c.queue_redraw()
		if fresh and search_thing == null:
			search_asked.emit(near_c)
		return
	near_c.prompt = WORDS["search_pad"] if pad else WORDS["search_key"]
	if held:
		r.searching = near_c
		var rate := (1.0 / maxf(0.1, SliceBridge.search_s(ctx) * (T.G_PRIZE_SEARCH_X if near_c.prize else 1.0))) * (T.SEARCH_UNDER_FIRE if r.under_fire() else 1.0)
		near_c.progress = minf(1.0, near_c.progress + rate * dt)
		search_progress.emit(near_c, near_c.progress)
		if near_c.progress >= 1.0:
			open_crate(near_c)
	near_c.queue_redraw()


## What's in a crate, rolled once: the sim's finds; the prize's three crates' worth and the place's gun.
func roll_crate(cr: SliceCrate) -> void:
	if cr.rolled:
		return
	cr.rolled = true
	cr.finds = SliceBridge.crate_finds(ctx, rng)
	if cr.prize:
		for _k in range(T.G_PRIZE_FINDS - 1):
			cr.finds.append_array(SliceBridge.crate_finds(ctx, rng))     # (board I) the prize: so many crates' worth
		var pg: Array = ctx["place"].get("prize_gun", []) if ctx.get("place") is Dictionary else []
		if pg.size() == 2:
			cr.finds.append_array(SliceBridge.place_gun(ctx, str(pg[0]), str(pg[1]), rng))     # (board K) the place's gun, found


## Searched through: the crate's count and the prize's mark (a body counts for neither).
func _searched(cr: SliceCrate) -> void:
	if cr.opened:
		return
	cr.opened = true
	cr.progress = 1.0
	if cr.prize:
		stats["prize"] = true
	if loop and not cr.body:
		stats["crates_opened"] = int(stats.get("crates_opened", 0)) + 1
	cr.queue_redraw()
	crate_opened.emit(cr, cr.finds)


## The whole crate at once, all of it taken (the hold-F search's end, and a check's hand).
func open_crate(cr: SliceCrate) -> Array:
	if cr.opened:
		return []
	roll_crate(cr)
	cr.near = false
	cr.found_n = cr.finds.size()
	cr.left = []
	_searched(cr)
	add_haul(cr.finds)
	return cr.finds


## (board M) A man put down: a body where he fell, holding what he dropped.
func add_body(p: Vector2, drops: Array) -> SliceCrate:
	var b: SliceCrate = add_crate(p)
	b.body = true
	b.rolled = true
	b.finds = drops.duplicate()
	for it in b.finds:
		SliceBridge.take_out(ctx["sim"].mission, it)     # on him, not in the pack the sim's find put it in
	return b


## How long a crate or a body takes to search through, undisturbed.
func search_secs(cr: SliceCrate) -> float:
	if cr.body:
		return T.G_BODY_SEARCH_S
	return maxf(0.1, SliceBridge.search_s(ctx) * (T.G_PRIZE_SEARCH_X if cr.prize else 1.0))


## (board M) The search going on while its screen is open: one find turned up at a time over the crate's seconds
## (slower under fire, as the ring was); the last one found, it's searched.
func search_tick(cr: SliceCrate, dt: float) -> void:
	roll_crate(cr)
	if cr.opened:
		return
	var each: float = search_secs(cr) / maxf(1.0, float(cr.finds.size()))
	cr.search_t += dt * (T.SEARCH_UNDER_FIRE if runner.under_fire() else 1.0)
	while cr.search_t >= each and cr.found_n < cr.finds.size():
		cr.search_t -= each
		cr.left.append(cr.finds[cr.found_n])
		cr.found_n += 1
	cr.progress = (float(cr.found_n) + clampf(cr.search_t / each, 0.0, 1.0)) / maxf(1.0, float(cr.finds.size()))
	if cr.found_n >= cr.finds.size() and (not cr.finds.is_empty() or cr.search_t >= each):
		_searched(cr)
	cr.queue_redraw()


## A find out of the crate into the pack: false with no room for it.
func take_find(cr: SliceCrate, it: Dictionary) -> bool:
	if not cr.left.has(it) or not SliceBridge.pack_room(ctx, it):
		return false
	if not SliceBridge.pack_take(ctx, it):
		return false
	cr.left.erase(it)
	if not stats["haul"].has(it):
		stats["haul"].append(it)                  # (the review) a piece taken, put back and taken again is in the haul once
	cr.queue_redraw()
	return true


## Every find turned up so far that the pack has room for. Returns how many were left behind for want of room.
func take_all(cr: SliceCrate) -> int:
	var no_room := 0
	for it in cr.left.duplicate():
		if not take_find(cr, it):
			no_room += 1
	return no_room


## A find worn straight from the crate (no pack room needed): what he had on goes into the crate.
func wear_find(cr: SliceCrate, it: Dictionary) -> bool:
	if not cr.left.has(it):
		return false
	var got: Dictionary = SliceBridge.wear_from(ctx, it)
	if not bool(got["ok"]):
		return false
	cr.left.erase(it)
	cr.left.append_array(got["off"])
	for x in got["off"]:
		stats["haul"].erase(x)                    # (the review) what came off and went back in the crate isn't hauled
	if not stats["haul"].has(it):
		stats["haul"].append(it)
	runner.kit_changed(ctx)
	cr.queue_redraw()
	return true


## A piece out of the pack back into the crate.
func leave_find(cr: SliceCrate, it: Dictionary) -> bool:
	if not SliceBridge.pack_drop(ctx, it):
		return false
	cr.left.append(it)
	stats["haul"].erase(it)
	cr.queue_redraw()
	return true


func debug_open_crate(cr: SliceCrate) -> Array:
	return open_crate(cr)


# ---------------------------------------------------------------- the runner hurt, the clear, the end
func on_runner_hurt(res: Dictionary) -> void:
	stats["damage_taken"] += int(res.get("hp_loss", 0))
	shake(T.SHAKE_HURT)
	runner_hurt.emit(res)


func on_runner_died() -> void:
	died.emit()
	end_run("died")


## G: the third gang down. The way out lights; the run ends "cleared" when he leaves.
func on_cleared() -> void:
	if cleared:
		return
	cleared = true
	runner.last_legs_saved()
	level.exit_lit = true
	level.queue_redraw()
	cleared_park.emit()


func leave() -> void:
	if ended:
		return
	left.emit()
	end_run("cleared" if cleared else "out")


func end_run(why: String) -> void:
	if ended:
		return
	ended = true
	outcome = why
	stats["time_s"] = time_s
	run_ended.emit(why, stats)
