extends CharacterBody2D
## One gang man (build 72, builder G): a token drawn in code (board A), moving between cover, flanking, firing with a
## reaction delay and spread, falling back when hurt. His numbers are the bridge's (the sim's man at the car park);
## his feet and timings SliceTuning's G block. The hard man is one of these with a name and traits.
const SliceBridge := preload("res://slice/bridge.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const SliceRound := preload("res://slice/round.gd")     # (build 76) his rounds travel too

const T := preload("res://slice/tuning.gd")
const Art := preload("res://slice/art.gd")
const Data := preload("res://scripts/sim/data.gd")

signal fired_at(man: Node, hit: bool, to: Vector2)

const C_MAN := Color("8c3b33")
const C_LINE := Color("1a1a1a")
const C_HARD := Color("5e1f1a")
const C_HARD_LINE := Color("d9a441")
const C_HURT := Color("e6e1d3")
const C_STUN := Color("7fb4d9")
const NAME_PX := 22                   # the hard man's name over his token, on screen (drawn at NAME_PX / CAM_ZOOM in the world)
const BAR_H := 6.0                    # (round 5's review) his HP bar's height on screen, px (BAR_H / CAM_ZOOM in the world)

var world = null
var gang = null
var ms: Dictionary = {}               # the bridge's state for him: hp, dots, timers
var radius := 34.0
var hard := false
var name_text := ""
var traits: Array = []
var flanker := false
var dead_face := INF                 # (round 3) his facing, frozen when he falls
var look := ""                       # (round 3) his picture: Hitman 1, Man Brown or Man Blue; Man Old for the hard man
var state := "enter"                  # enter, move, cover, retreat, held (round 4: waiting his turn at the back), dead;
                                      # (round 6) lean (out of cover to fire), duck (back behind it), search, look
var home := Vector2.ZERO              # (round 6) his spot behind cover: he leans out from it and ducks back to it
var lean_wait := 0.0                  # ...behind it this long before he leans out again
var lean_left := 0.0                  # ...and out this long before he ducks back
var leans_left := 0                   # ...and this many more times from this spot before he moves on
var hurt_back := false                # (round 6's review) hurt, he has fallen back once of his own accord: after that only a hit sends him
var duck_left := 0.0                  # (round 6's review) ducking back: this long at most, then he is in cover where he stands
var look_a := 0.0                     # (round 6) searching: where he's looking
var look_left := 0.0
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
var fired := 0                        # (build 76) his rounds sent, and those that reached the runner (round.gd counts)
var landed := 0
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
	if state == "held" and gang != null and gang.has_method("held_shot"):
		gang.held_shot(self)                      # (round 4) found at the back and shot: he's in it now, one of the front goes back
	var res: Dictionary = SliceBridge.shot_damage(world.ctx, shot.get("gun", {}), ms, rng, bool(shot.get("head", false)), float(shot.get("share", 1.0)))
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


## (round 4, Matt: "3 on you - 3 next") The director holds him back: to `at` (the park's edge, out of sight), not firing.
func hold(at: Vector2) -> void:
	state = "held"
	target = at
	sees = false
	burst_left = 0


## His turn: he steps up and engages (cover, flanking, fire), with his reaction beat.
func engage() -> void:
	if dead or state != "held":
		return
	_pick_spot()


func is_held() -> bool:
	return state == "held"


## (round 6, board E) The gang has lost him: this man walks to where they last saw him and looks about.
func search(at: Vector2) -> void:
	if dead or state == "held" or state == "retreat":
		return
	state = "search"
	target = world.resolve_circle(_in_park(at), radius)
	move_left = T.G_SEARCH_WALK_S
	burst_left = 0


func is_searching() -> bool:
	return state == "search" or state == "look"


## Where the gang thinks he is: where one of them last saw him (the runner himself with no gang to say).
func _known() -> Vector2:
	if gang != null and gang.get("last_seen") != null:
		return gang.last_seen
	return world.runner.global_position if world.runner != null else global_position


## Flush them out: out of cover, toward you.
func flush(toward: Vector2) -> void:
	if state == "held":
		return                                    # (round 4) at the back he isn't in it: the director brings him up
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
	if state == "held":
		sees = false                              # (round 4) waiting his turn: out of it, at the back, not firing
		_move(dt)
		queue_redraw()
		return
	var rp: Vector2 = runner.global_position
	var stunned: bool = float(ms.get("stun_t", 0.0)) > 0.0
	var dist: float = global_position.distance_to(rp)
	var saw := sees
	sees = dist <= T.G_MAN_RANGE and world.has_los(global_position, rp) and not runner.is_dead()
	if sees and not saw:
		# (round 6) leaning out he knew where to look: a shorter beat than a man surprised
		react_left = rng.randf_range(T.G_REACT_S[0], T.G_REACT_S[1]) * (T.G_LEAN_REACT_X if state == "lean" else 1.0)
		if is_searching():
			_pick_spot()                              # found him: back in the fight
	if sees and gang != null:
		gang.note_runner(rp)                          # (round 6) only a man who sees him says where he is
	pause_left = maxf(0.0, pause_left - dt)           # (round 6) the pause between bursts runs behind cover too
	_think(dt, rp)
	if not stunned:
		_move(dt)
		_fire(dt, rp, dist)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, T.G_MAN_ACCEL * dt)
	queue_redraw()


func _think(dt: float, _rp: Vector2) -> void:
	move_left -= dt
	var pinned: bool = float(ms.get("supp", 0.0)) >= 1.0
	match state:
		"enter", "move", "retreat":
			if global_position.distance_to(target) <= T.G_ARRIVE_PX:
				_in_cover()
		"cover":
			if sees:
				if move_left <= 0.0 and not pinned:
					_pick_spot()                          # a spot with a line of its own: he fires from it a while, then moves
			else:
				_think_lean(dt, pinned)
		"lean":
			# out of cover: he fires while he has him, then back - sooner pinned, or with nothing there to shoot at
			lean_left -= dt * (1.0 if sees else T.G_LEAN_BLIND_X)
			if lean_left <= 0.0 or pinned:
				state = "duck"
				target = home
				# the walk home at a hit leg's pace, and G_DUCK_MAX_S over
				duck_left = T.G_DUCK_MAX_S + global_position.distance_to(home) / (T.G_MAN_SPEED * T.G_LEG_SLOW_X)
		"duck":
			if float(ms.get("stun_t", 0.0)) <= 0.0:
				duck_left -= dt                           # stunned he isn't walking: the time isn't counted
			if global_position.distance_to(target) <= T.G_ARRIVE_PX or duck_left <= 0.0:
				state = "cover"
				lean_wait = rng.randf_range(T.G_LEAN_BACK_S[0], T.G_LEAN_BACK_S[1])
		"search":
			if global_position.distance_to(target) <= T.G_SEARCH_NEAR_PX or move_left <= 0.0:
				state = "look"
				look_left = T.G_LOOK_S
				look_a = velocity.angle() if velocity.length() > 1.0 else look_a
		"look":
			look_left -= dt
			look_a += sin(look_left * T.G_LOOK_SWEEP) * T.G_LOOK_TURN * dt
			if look_left <= 0.0:
				_spread()
	# (round 6's review) a hurt man falls back from the open once (hurt by a bleed or a burn, no hit to send him), not
	# from behind cover, out of a lean or off a search: after that he leans out, moves up and goes to look like the
	# rest (a hit while he's hurt sends him back all the same, take_shot)
	if not hurt_back and hp < hp_max * T.G_RETREAT_HP and state not in ["retreat", "cover", "duck", "lean", "search", "look"]:
		_retreat()


## At his spot: behind it, a beat, then he leans out.
func _in_cover() -> void:
	state = "cover"
	home = global_position
	leans_left = rng.randi_range(T.G_LEANS[0], T.G_LEANS[1])
	lean_wait = rng.randf_range(T.G_LEAN_FIRST_S[0], T.G_LEAN_FIRST_S[1])
	move_left = rng.randf_range(T.G_REPOSITION_S[0], T.G_REPOSITION_S[1])


## (round 6, board E) Behind cover with no line to him: he leans out to fire - the nearest step sideways with a line to
## where the gang knows him to be - unless the gang has lost him (then they search, gang.gd).
func _think_lean(dt: float, pinned: bool) -> void:
	lean_wait -= dt * (1.0 / T.G_PINNED_SLOW if pinned else 1.0)
	if lean_wait > 0.0 or pinned:
		return
	if gang != null and gang.has_method("lost_him") and gang.lost_him():
		return
	if leans_left <= 0:
		_pick_spot()                                  # he has leaned out from here enough: other cover, nearer
		return
	home = global_position
	var found: Dictionary = lean_point(_known())
	if found.is_empty():
		# nowhere to lean out from here: on to cover further in, or (the same cover again) out to where he has a line
		_pick_spot(T.G_NO_LEAN_STEP)
		if target.distance_to(global_position) <= T.G_ARRIVE_PX * 2.0:
			target = world.resolve_circle(_in_park(global_position.lerp(_known(), T.G_NO_LEAN_STEP)), radius)
		return
	leans_left -= 1
	home = found["back"]                              # he ducks back just behind the corner, not to the middle of his cover
	target = found["at"]
	state = "lean"
	lean_left = rng.randf_range(T.G_LEAN_OUT_S[0], T.G_LEAN_OUT_S[1])


## The nearest spot sideways of him with a line to `known`, free of cover and in the park: {at: where he stands to
## fire, back: the last step short of it, out of sight}; empty with none in reach.
func lean_point(known: Vector2) -> Dictionary:
	var to: Vector2 = known - global_position
	if to.length() < 1.0 or to.length() > T.G_MAN_RANGE:
		return {}
	var side: Vector2 = Vector2(-to.y, to.x).normalized()
	for k in range(1, T.G_LEAN_STEPS + 1):
		for sgn in [1.0, -1.0]:
			var hop: Vector2 = side * sgn * T.G_LEAN_STEP_PX
			var c: Vector2 = global_position + hop * k
			if not world.park_rect.has_point(c) or not _free(c):
				continue
			if not (world.has_los(c, known) and world.has_los(global_position, c)):
				continue
			var past: Vector2 = c + side * sgn * T.G_LEAN_CLEAR_PX
			var back: Vector2 = c - hop
			if not _free(back) or world.has_los(back, known):
				back = global_position
			return {"at": past if _free(past) else c, "back": back}
	return {}


func _free(p: Vector2) -> bool:
	return world.resolve_circle(p, radius).distance_to(p) <= 1.0


## The search over: he spreads to cover off to one side of where they last saw him.
func _spread() -> void:
	var known: Vector2 = _known()
	var out: Vector2 = Vector2.RIGHT.rotated(look_a + (PI / 2.0 if (get_instance_id() % 2) == 0 else -PI / 2.0))
	var near: Vector2 = _in_park(known + out * T.G_SPREAD_PX)
	target = world.cover_spot(near, known) if world.has_method("cover_spot") else near
	state = "move"
	move_left = rng.randf_range(T.G_REPOSITION_S[0], T.G_REPOSITION_S[1])


## Where to next: cover near him, or round the side (a flanker), facing the runner.
func _pick_spot(frac := 0.35) -> void:
	var rp: Vector2 = _known()                     # (round 6) where the gang knows him to be, not where he is
	var near: Vector2 = global_position.lerp(rp, frac)
	if flanker:
		var line: Vector2 = (global_position - rp).normalized()
		var side := Vector2(-line.y, line.x) * (1.0 if (get_instance_id() % 2) == 0 else -1.0)
		near = rp + line * T.G_FLANK_DIST * 0.6 + side * T.G_FLANK_DIST
	near = _in_park(near)
	target = world.cover_spot(near, rp) if world.has_method("cover_spot") else near
	state = "move"
	move_left = rng.randf_range(T.G_REPOSITION_S[0], T.G_REPOSITION_S[1])


func _retreat() -> void:
	var rp: Vector2 = _known()                        # (round 6's review) away from where the gang knows him to be
	var away: Vector2 = (global_position - rp).normalized()
	var near: Vector2 = _in_park(global_position + away * 600.0)
	target = world.cover_spot(near, rp) if world.has_method("cover_spot") else near
	state = "retreat"
	hurt_back = true
	move_left = 6.0


func _in_park(p: Vector2) -> Vector2:
	var r: Rect2 = world.park_rect.grow(-120.0)
	return Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))


func _move(dt: float) -> void:
	var want := Vector2.ZERO
	if state != "cover" and state != "look":
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
	# (build 76) a round that travels (round.gd), aimed where the runner will be when it gets there, its error spread across
	# so G_HIT_OPEN of them cross his token in the open (less on the move); cover in its path stops it
	var p_hit: float = T.G_HIT_OPEN * (T.G_MOVING_X if velocity.length() > 40.0 else 1.0)
	var lead: Vector2 = Vector2(runner.velocity) * (dist / T.G_THEIR_ROUND_PX_S) * T.G_LEAD
	var aim_at: Vector2 = rp + lead
	var to: Vector2 = aim_at - global_position
	var side: Vector2 = Vector2(-to.y, to.x).normalized() if to.length() > 1.0 else Vector2.UP
	var off: float = rng.randf_range(-1.0, 1.0) * T.RUNNER_R / maxf(0.05, p_hit)
	tracer_to = aim_at + side * off
	tracer_t = 0.06
	SliceRound.layer(world).fire_man(self, tracer_to)
	fired += 1
	fired_at.emit(self, absf(off) <= T.RUNNER_R, tracer_to)


## (round 3) Where he faces: the runner while he lives; a dead man keeps the facing he fell with while he fades.
func facing() -> float:
	if dead and dead_face != INF:
		return dead_face
	var a := 0.0
	if is_searching():
		a = velocity.angle() if state == "search" and velocity.length() > 1.0 else look_a     # (round 6) he doesn't know where the runner is
	elif world != null and world.runner != null:
		a = (_known() - global_position).angle()      # (round 6's review) where the gang knows him to be: not through a wall once he's gone
	if dead:
		dead_face = a
	return a


## (round 5's review) The hard man's name and the HP bar at the camera's zoom: world sizes that show NAME_PX and BAR_H.
static func name_px() -> int:
	return roundi(NAME_PX / T.CAM_ZOOM)


static func bar_h() -> float:
	return BAR_H / T.CAM_ZOOM


func _draw() -> void:
	var body: Color = C_HURT if flash_t > 0.0 else (C_HARD if hard else C_MAN)
	draw_circle(Vector2(4, 6), radius, Color(0, 0, 0, 0.35))
	var face := facing()
	if look == "":
		look = Art.HARD if hard else Art.next_look()
	if hard:
		draw_circle(Vector2.ZERO, radius + 10.0, Color(C_HARD_LINE, 0.22))     # his glow
	var pose_v: String = Art.man_set_pose(dead, tracer_t > 0.0, sees)     # (round 5's review) the set's names, Kenney's mapped
	if Art.draw_char(self, look, pose_v, face, radius * 0.95):
		if flash_t > 0.0:
			draw_circle(Vector2.ZERO, radius, Color(C_HURT, 0.65))     # hit: he flashes
		if hard:
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, C_HARD_LINE, 4.0)     # his gold ring
	else:
		draw_circle(Vector2.ZERO, radius, body)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, C_HARD_LINE if hard else C_LINE, 4.0 if hard else 3.0)
		var f: Vector2 = Vector2.RIGHT.rotated(face) * radius
		draw_line(f * 0.4, f * 1.15, C_LINE, 5.0)
	if float(ms.get("stun_t", 0.0)) > 0.0:
		draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 40, C_STUN, 3.0)
	if hard and name_text != "" and not dead and world != null:
		var f: Font = world.font() if world.has_method("font") else ThemeDB.fallback_font
		var np: int = name_px()
		var nw: float = f.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, np).x
		draw_string(f, Vector2(-nw * 0.5, -radius - bar_h() - 14.0 / T.CAM_ZOOM), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, np, C_HARD_LINE)     # his name over him (board A)
	if hp < hp_max and not dead:
		var w: float = radius * 2.0
		var bh: float = bar_h()
		draw_rect(Rect2(-radius, -radius - 10.0 - bh, w, bh), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-radius, -radius - 10.0 - bh, w * clampf(hp / hp_max, 0.0, 1.0), bh), Color("d0453a"))
