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
signal swapped(gun_index: int)
signal search_progress(crate: Node, frac: float)
signal crate_opened(crate: Node, finds: Array)
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
var park_rect := Rect2(0, 0, T.PARK_W, T.PARK_H)
var exit_rect := Rect2()
var time_s := 0.0
var cleared := false
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
	add_child(level)
	level.build()
	exit_rect = level.exit_rect
	crates_root = Node2D.new()
	crates_root.name = "Crates"
	add_child(crates_root)
	for p in SliceLevel.CRATES:
		var cr: SliceCrate = CrateScript.new()
		cr.position = p
		crates_root.add_child(cr)
	men_root = Node2D.new()
	men_root.name = "Men"
	add_child(men_root)
	sight = SightScript.new()            # (build 76) over the level, the crates and the men; under the runner, the marks, the rounds
	sight.name = "Sight"
	add_child(sight)
	runner = RunnerScript.new()
	runner.name = "Runner"
	runner.position = SliceLevel.ENTRY
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
	camera.position = cam_center
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
	fx.exit_prompt = ""
	if exit_rect.has_point(runner.position) and not ended:
		fx.exit_prompt = WORDS["out_pad"] if pad else WORDS["out_key"]
		fx.exit_at = Vector2(exit_rect.get_center().x, exit_rect.position.y - 24.0)
	fx.reticle = runner.aim if runner.aim_mode == "pad" else Vector2.INF
	fx.reticle_locked = runner.locked != null
	fx.step(dt)
	_camera_step(dt)
	sight.step(dt)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.4):
		pad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		pad = false


# ---------------------------------------------------------------- the camera
func _cam_goal() -> Vector2:
	var lead := (runner.aim - runner.position) * T.CAM_LEAD
	if lead.length() > T.CAM_LEAD_MAX:
		lead = lead.normalized() * T.CAM_LEAD_MAX
	var half := view_world() * 0.5
	var g := runner.position + lead
	return Vector2(clampf(g.x, half.x, T.PARK_W - half.x), clampf(g.y, half.y, T.PARK_H - half.y))


func _camera_step(dt: float) -> void:
	cam_center = cam_center.lerp(_cam_goal(), clampf(T.CAM_FOLLOW * dt, 0.0, 1.0))
	camera.position = cam_center
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


## (build 76) The ground the camera shows, in world px: the screen over the zoom (3840 x 2160 at 1920 x 1080).
func view_world() -> Vector2:
	return view_size() / T.CAM_ZOOM


func shake(strength: float) -> void:
	shake_px = minf(T.SHAKE_MAX, maxf(shake_px, strength))


func world_to_screen(p: Vector2) -> Vector2:
	return (p - cam_center) * T.CAM_ZOOM + view_size() * 0.5


func screen_to_world(s: Vector2) -> Vector2:
	return (s - view_size() * 0.5) / T.CAM_ZOOM + cam_center


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
	q.x = clampf(q.x, T.EDGE + r, T.PARK_W - T.EDGE - r)
	q.y = clampf(q.y, T.EDGE + r, T.PARK_H - T.EDGE - r)
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
	for t in [SliceLevel.KIOSK_INSIDE, SHELTER_POCKET]:
		if SliceLevel.tiles_px(t).grow(T.MAN_R).has_point(p):
			return true
	return false


func spawn_points() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p in SliceLevel.SPAWNS:
		out.append(p)
	return out


func men() -> Array:
	if men_root == null:
		return []
	return men_root.get_children().filter(func(m): return m.is_in_group("slice_man") and not m.is_dead())


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
		hit_man.knock(dir, T.KNOCK_PX)
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
			var d := cr.position.distance_to(r.position)
			if d < nd:
				nd = d
				near_c = cr
	r.searching = null
	if near_c == null:
		return
	near_c.near = true
	near_c.prompt = WORDS["search_pad"] if pad else WORDS["search_key"]
	if held:
		r.searching = near_c
		var rate := (1.0 / maxf(0.1, SliceBridge.search_s(ctx))) * (T.SEARCH_UNDER_FIRE if r.under_fire() else 1.0)
		near_c.progress = minf(1.0, near_c.progress + rate * dt)
		search_progress.emit(near_c, near_c.progress)
		if near_c.progress >= 1.0:
			open_crate(near_c)
	near_c.queue_redraw()


func open_crate(cr: SliceCrate) -> Array:
	if cr.opened:
		return []
	cr.opened = true
	cr.progress = 1.0
	cr.near = false
	cr.finds = SliceBridge.crate_finds(ctx, rng)
	add_haul(cr.finds)
	cr.queue_redraw()
	crate_opened.emit(cr, cr.finds)
	return cr.finds


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
