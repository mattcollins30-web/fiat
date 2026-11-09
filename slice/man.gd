extends CharacterBody2D
## One gang man (build 72, builder G): a token drawn in code (board A), moving between cover, flanking, firing with a
## reaction delay and spread, falling back when hurt. His numbers are the bridge's (the sim's man at the car park);
## his feet and timings SliceTuning's G block. The hard man is one of these with a name and traits.
const SliceBridge := preload("res://slice/bridge.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)

const T := preload("res://slice/tuning.gd")
const Data := preload("res://scripts/sim/data.gd")

signal fired_at(man: Node, hit: bool, to: Vector2)

const C_MAN := Color("8c3b33")
const C_LINE := Color("1a1a1a")
const C_HARD := Color("5e1f1a")
const C_HARD_LINE := Color("d9a441")
const C_HURT := Color("e6e1d3")
const C_STUN := Color("7fb4d9")
const NAME_PX := 22                   # the hard man's name over his token
const C_TRACER := Color(1.0, 0.85, 0.55, 0.9)

var world = null
var gang = null
var ms: Dictionary = {}               # the bridge's state for him: hp, dots, timers
var radius := 34.0
var hard := false
var name_text := ""
var traits: Array = []
var flanker := false
var state := "enter"                  # enter, move, cover, retreat, dead
var target := Vector2.ZERO
var sees := false
var react_left := 0.0
var burst_left := 0
var pause_left := 0.0
var move_left := 0.0
var stuck_t := 0.0
var detour := Vector2.ZERO
var detour_t := 0.0
var flash_t := 0.0
var knock_v := Vector2.ZERO
var tracer_to := Vector2.ZERO
var tracer_t := 0.0
var dead := false
var gone := false                     # faded out: the director drops him
var fade_t := 0.0
var rng: RandomNumberGenerator


func setup(world_v, gang_v, state_v: Dictionary, at: Vector2, flank: bool) -> void:
	world = world_v
	gang = gang_v
	ms = state_v
	hard = bool(ms.get("hard", false))
	name_text = str(ms.get("name", ""))
	traits = ms.get("traits", [])
	flanker = flank
	rng = world.rng
	radius = T.G_HARD_R if hard else T.G_MAN_R
	position = at
	add_to_group("slice_man")
	collision_layer = 4
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	shape.shape = c
	add_child(shape)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_pick_spot()


# ------------------------------------------------------------------ what W and H call

func state_data() -> Dictionary:
	return ms


func is_dead() -> bool:
	return dead


var hp: float:
	get:
		return float(ms.get("hp", 0.0))
var hp_max: float:
	get:
		return float(ms.get("hp_max", 1.0))


## A round from the runner (W's ray hit him): the bridge's damage; dead, he's counted and his drops go to the haul.
func take_shot(shot: Dictionary) -> Dictionary:
	if dead:
		return {"damage": 0, "headshot": false, "killed": false}
	var res: Dictionary = SliceBridge.shot_damage(world.ctx, shot.get("gun", {}), ms, rng, bool(shot.get("head", false)))
	flash_t = T.G_FLASH_S
	if state == "cover" or state == "enter":
		move_left = minf(move_left, 0.6)          # shot at: he thinks about moving
	if not res["killed"] and hp < hp_max * T.G_RETREAT_HP and state != "retreat":
		_retreat()
	if res["killed"]:
		_die(res)
	return res


## W's knock on a hit: a shove and the flash.
func knock(dir: Vector2, strength: float) -> void:
	knock_v += dir.normalized() * strength * 10.0
	flash_t = T.G_FLASH_S


## Killed by a skill (One for the pot): the bridge has counted him.
func die_by(res: Dictionary) -> void:
	if not dead:
		_die(res)


## Flush them out: out of cover, toward you.
func flush(toward: Vector2) -> void:
	state = "move"
	target = global_position.lerp(toward, 0.5)
	move_left = 4.0


func _die(res: Dictionary) -> void:
	dead = true
	state = "dead"
	remove_from_group("slice_man")
	collision_layer = 0
	fade_t = 0.6
	if world != null and world.has_method("on_man_killed"):
		world.on_man_killed(self, res)
	if gang != null:
		gang.man_down(self, res)


# ------------------------------------------------------------------ the frame

## His frame: the gang director steps every man from its tick (the slice runs headless in the smoke, out of the tree).
func step(dt: float) -> void:
	if world == null:
		return
	flash_t = maxf(0.0, flash_t - dt)
	tracer_t = maxf(0.0, tracer_t - dt)
	if dead:
		fade_t -= dt
		modulate.a = clampf(fade_t / 0.6, 0.0, 1.0)
		queue_redraw()
		if fade_t <= 0.0:
			gone = true
			queue_free()
		return
	var tick: Dictionary = SliceBridge.man_dots_tick(world.ctx, ms, dt)
	if float(tick["amount"]) > 0.0 and world.has_method("add_damage_done"):
		world.add_damage_done(float(tick["amount"]))     # bleeds and burns count as damage done, a kill by one too (the review)
	if tick["killed"]:
		var res := {"damage": int(round(float(tick["amount"]))), "amount": float(tick["amount"]), "headshot": false, "killed": true, "dot": true, "by_type": tick["by"]}
		res.merge(SliceBridge.on_kill(world.ctx, ms, rng), true)
		_die(res)
		return
	var runner = world.runner
	if runner == null or not is_instance_valid(runner):
		return
	var rp: Vector2 = runner.global_position
	var stunned: bool = float(ms.get("stun_t", 0.0)) > 0.0
	var dist: float = global_position.distance_to(rp)
	var saw := sees
	sees = dist <= T.G_MAN_RANGE and world.has_los(global_position, rp) and not runner.is_dead()
	if sees and not saw:
		react_left = rng.randf_range(T.G_REACT_S[0], T.G_REACT_S[1])
	_think(dt, rp)
	if not stunned:
		_move(dt)
		_fire(dt, rp, dist)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, T.G_MAN_ACCEL * dt)
	queue_redraw()


func _think(dt: float, rp: Vector2) -> void:
	move_left -= dt
	match state:
		"enter", "move", "retreat":
			if global_position.distance_to(target) <= T.G_ARRIVE_PX:
				state = "cover"
				move_left = rng.randf_range(T.G_REPOSITION_S[0], T.G_REPOSITION_S[1])
		"cover":
			var pinned: bool = float(ms.get("supp", 0.0)) >= 1.0
			if move_left <= 0.0 and not pinned:
				_pick_spot()
			elif not sees and move_left <= 0.0:
				_pick_spot()
	if state == "cover" and not sees and move_left > 1.5 and float(ms.get("supp", 0.0)) < 1.0:
		move_left = 1.5                           # in cover with nothing to shoot at: he moves on sooner
	if hp < hp_max * T.G_RETREAT_HP and state != "retreat" and state != "cover":
		_retreat()
	if gang != null:
		gang.note_runner(rp)


## Where to next: cover near him, or round the side (a flanker), facing the runner.
func _pick_spot() -> void:
	var rp: Vector2 = world.runner.global_position if world.runner != null else global_position
	var near: Vector2 = global_position.lerp(rp, 0.35)
	if flanker:
		var line: Vector2 = (global_position - rp).normalized()
		var side := Vector2(-line.y, line.x) * (1.0 if (get_instance_id() % 2) == 0 else -1.0)
		near = rp + line * T.G_FLANK_DIST * 0.6 + side * T.G_FLANK_DIST
	near = _in_park(near)
	target = world.cover_spot(near, rp) if world.has_method("cover_spot") else near
	state = "move"
	move_left = rng.randf_range(T.G_REPOSITION_S[0], T.G_REPOSITION_S[1])


func _retreat() -> void:
	var rp: Vector2 = world.runner.global_position
	var away: Vector2 = (global_position - rp).normalized()
	var near: Vector2 = _in_park(global_position + away * 600.0)
	target = world.cover_spot(near, rp) if world.has_method("cover_spot") else near
	state = "retreat"
	move_left = 6.0


func _in_park(p: Vector2) -> Vector2:
	var r: Rect2 = world.park_rect.grow(-120.0)
	return Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))


func _move(dt: float) -> void:
	var want := Vector2.ZERO
	if state != "cover":
		want = (target - global_position)
		if want.length() > T.G_ARRIVE_PX:
			want = want.normalized()
		else:
			want = Vector2.ZERO
	# keep apart
	if gang != null:
		for o in gang.live_men():
			if o != self and global_position.distance_to(o.global_position) < T.G_SEPARATE_PX:
				want += (global_position - o.global_position).normalized() * 0.6
	if detour_t > 0.0:
		detour_t -= dt
		want = (want + detour * 1.2).normalized()
	var speed: float = T.G_MAN_SPEED * (T.G_LEG_SLOW_X if float(ms.get("leg_t", 0.0)) > 0.0 else 1.0) * (1.0 - (ctx_chill() if float(ms.get("chill_t", 0.0)) > 0.0 else 0.0))
	var goal: Vector2 = want.limit_length(1.0) * speed
	velocity = velocity.move_toward(goal, T.G_MAN_ACCEL * dt) + knock_v
	knock_v = knock_v.move_toward(Vector2.ZERO, 2000.0 * dt)
	var before := global_position
	if is_inside_tree():
		move_and_slide()
	else:
		position += velocity * dt                 # out of the tree (the headless smoke): no physics space to slide in
	if want.length() > 0.1 and global_position.distance_to(before) < speed * dt * 0.2:
		stuck_t += dt
		if stuck_t >= T.G_STUCK_S:
			stuck_t = 0.0
			detour = Vector2(-want.y, want.x) * (1.0 if rng.randf() < 0.5 else -1.0)
			detour_t = 0.7
	else:
		stuck_t = 0.0


func ctx_chill() -> float:
	return float(world.ctx["sim"].chill_amount())


func _fire(dt: float, rp: Vector2, dist: float) -> void:
	if not sees:
		return
	if gang != null and gang.has_method("may_fire") and not gang.may_fire(self):
		return                                  # the sim's contact: only so many of them on you at once
	if react_left > 0.0:
		react_left -= dt
		return
	if pause_left > 0.0:
		pause_left -= dt
		return
	var runner = world.runner
	var slow: float = 1.0
	if float(ms.get("supp", 0.0)) >= 1.0:
		slow *= 1.0 / (1.0 - (Data.RATTLE67_SLOW if world.ctx["sim"].has_rule("football_rattle") else Data.SUPP66_SLOW))     # pinned: the sim's slower fire
	if float(ms.get("chill_t", 0.0)) > 0.0:
		slow *= 1.0 / maxf(0.2, 1.0 - ctx_chill())
	if burst_left <= 0:
		burst_left = rng.randi_range(T.G_BURST[0], T.G_BURST[1])
	burst_left -= 1
	pause_left = slow / T.G_MAN_ROF
	if burst_left <= 0:
		pause_left += rng.randf_range(T.G_BURST_PAUSE[0], T.G_BURST_PAUSE[1]) * (T.G_PINNED_SLOW if float(ms.get("supp", 0.0)) >= 1.0 else 1.0)
	# the round: spread either side; it lands if it passes within the runner's token
	var spread: float = deg_to_rad(T.G_SPREAD_DEG) * (T.G_SPREAD_MOVING if velocity.length() > 40.0 else 1.0)
	var err: float = rng.randf_range(-spread, spread)
	var off: float = absf(sin(err)) * dist
	var r_r: float = T.G_RUNNER_R
	var hit: bool = off <= r_r
	var dir: Vector2 = (rp - global_position).normalized().rotated(err)
	tracer_to = global_position + dir * dist
	tracer_t = 0.06
	if hit:
		var on_you: int = gang.on_you() if gang != null else 1
		var res: Dictionary = SliceBridge.hit_on_runner(world.ctx, runner, ms, rng, on_you, gang != null and gang.spotter_on(int(ms.get("gang", 0))))
		if not bool(res["missed"]) and (int(res["hp_loss"]) > 0 or int(res["guard_loss"]) > 0):
			runner.apply_hit(res)
		else:
			hit = false
	fired_at.emit(self, hit, tracer_to)


func _draw() -> void:
	if tracer_t > 0.0:
		draw_line(Vector2.ZERO, to_local(tracer_to), C_TRACER, 2.0)
	var body: Color = C_HURT if flash_t > 0.0 else (C_HARD if hard else C_MAN)
	draw_circle(Vector2(4, 6), radius, Color(0, 0, 0, 0.35))
	draw_circle(Vector2.ZERO, radius, body)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, C_HARD_LINE if hard else C_LINE, 4.0 if hard else 3.0)
	if world != null and world.runner != null:
		var f: Vector2 = (world.runner.global_position - global_position).normalized() * radius
		draw_line(f * 0.4, f * 1.15, C_LINE, 5.0)
	if float(ms.get("stun_t", 0.0)) > 0.0:
		draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 40, C_STUN, 3.0)
	if hard and name_text != "" and not dead and world != null:
		var f: Font = world.font() if world.has_method("font") else ThemeDB.fallback_font
		var nw: float = f.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_PX).x
		draw_string(f, Vector2(-nw * 0.5, -radius - 26.0), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_PX, C_HARD_LINE)     # his name over him (board A)
	if hp < hp_max and not dead:
		var w: float = radius * 2.0
		draw_rect(Rect2(-radius, -radius - 16.0, w, 6.0), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-radius, -radius - 16.0, w * clampf(hp / hp_max, 0.0, 1.0), 6.0), Color("d0453a"))
