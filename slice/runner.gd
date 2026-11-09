extends CharacterBody2D
## The runner in the slice (build 72): a token that moves 8 ways at the class's pace (tight - a tenth of a second up
## to speed, no slide), aims at the mouse or the right stick (a soft lock-on on the pad), fires the gun's stream at its
## rate, counts the magazine down, reloads in the gun's time, jams when the bridge says, swaps to the spare, searches
## crates, and holds X/B in the way out to leave. The world steps him (world.tick) so a headless check can too.
const SliceWorld := preload("res://slice/slice.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const SliceBridge := preload("res://slice/bridge.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)

const T := preload("res://slice/tuning.gd")
const C_BODY := Color("4e6b3a")
const C_LINE := Color("e0a030")
const C_HURT := Color("f4e6d0")
const C_BARREL := Color("1c1d20")

var world: Node = null               # SliceWorld (untyped: the two scripts name each other)
var ctx: Dictionary = {}
var hp := 1
var hp_max := 1
var guard := 0
var guard_max := 0
var energy := 0.0
var energy_max := 0.0
var guns: Array = []
var gun_i := 0
var rounds: Array[int] = []          # in the magazine, per gun
var mags: Array[int] = []            # spare magazines, per gun
var reloading := false
var reload_left := 0.0
var reload_total := 0.0
var refilling := false               # this reload fills the magazine from the pack's box, by hand
var jammed := false
var jam_left := 0.0
var swap_left := 0.0
var shot_cd := 0.0
var aim := Vector2.ZERO              # the world point aimed at
var aim_dir := Vector2.RIGHT
var aim_mode := "mouse"              # "mouse", "pad", or "fixed" (a check's debug_aim_at)
var locked: Node = null              # the man the pad's soft lock-on holds
var searching: Node = null
var leaving_frac := 0.0
var last_legs_used := false
var last_legs_left := 0.0           # Last legs holding: seconds left on the hold
var last_legs_back := 0              # the HP he stands on while it holds
var skill_state: Dictionary = {}     # G: cooldowns {i: {cd_left, cd}}
var meds: Array = []
var pace_px := T.PACE_PX
var hurt_left := 0.0
var last_hurt_t := -100.0
var dead := false
var trigger_was := false            # the trigger held last step (a fresh pull)
var auto_move := Vector2.ZERO        # a check's walk (debug_move_dir); zero means the controls


func setup(w: Node, c: Dictionary) -> void:
	world = w
	ctx = c
	hp_max = maxi(1, int(c.get("hp_max", 100)))
	hp = hp_max
	guard_max = int(c.get("guard_max", 0))
	guard = guard_max
	energy_max = float(c.get("energy_max", 100.0))
	energy = energy_max
	guns = c.get("guns", []).duplicate(true)
	rounds.clear()
	mags.clear()
	for g in guns:
		rounds.append(int(g.get("mag", 1)))
		mags.append(int(g.get("mags", 0)))
	gun_i = 0
	meds = c.get("meds", [])                # the ctx's own list: the bridge counts a med down there, the HUD reads it here (the review)
	pace_px = T.PACE_PX * maxf(T.PACE_MIN, 1.0 + float(c.get("pace_pct", 0.0)) / 100.0)
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = T.RUNNER_R
	shape.shape = cs
	add_child(shape)
	aim = position + Vector2.RIGHT * 200.0


func gun() -> Dictionary:
	return guns[gun_i] if gun_i < guns.size() else {}


func is_dead() -> bool:
	return dead


func under_fire() -> bool:
	return world != null and world.time_s - last_hurt_t < T.UNDER_FIRE_S


# ---------------------------------------------------------------- the step
func tick(dt: float) -> void:
	if dead or world == null or world.ended:
		velocity = Vector2.ZERO
		return
	hurt_left = maxf(0.0, hurt_left - dt)
	_last_legs_step(dt)
	if dead:
		return
	_move(dt)
	_aim()
	_gun_timers(dt)
	var pulled := Input.is_action_pressed("slice_fire")
	if pulled:
		_trigger(not trigger_was)
	trigger_was = pulled
	if Input.is_action_just_pressed("slice_reload"):
		start_reload()
	if Input.is_action_just_pressed("slice_swap"):
		swap()
	for i in range(3):
		if Input.is_action_just_pressed("slice_skill_%d" % (i + 1)):
			world.use_skill(i)
	for i in range(4):
		if Input.is_action_just_pressed("slice_med_%d" % (i + 1)):
			world.use_med(i)
	world.search_step(self, Input.is_action_pressed("slice_use"), dt)
	_leave_step(Input.is_action_pressed("slice_out"), dt)
	queue_redraw()


func _move(dt: float) -> void:
	var want := auto_move
	if want == Vector2.ZERO:
		want = Input.get_vector("slice_move_left", "slice_move_right", "slice_move_up", "slice_move_down", T.MOVE_DEADZONE)
	if want.length() > 1.0:
		want = want.normalized()
	var target := want * pace_px
	var rate := T.ACCEL if target.length() > 1.0 and target.dot(velocity) >= 0.0 else T.DECEL
	velocity = velocity.move_toward(target, rate * dt)
	var before := position
	position = world.resolve_circle(position + velocity * dt, T.RUNNER_R)
	if dt > 0.0:
		var got := (position - before) / dt
		if got.length() < velocity.length() - 1.0:
			velocity = got                # a wall stops him dead, no build-up against it


func _aim() -> void:
	var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if aim_mode != "fixed" and stick.length() > T.AIM_DEADZONE:
		aim_mode = "pad"
		var dir := stick.normalized()
		locked = world.lock_target(position, dir)
		aim = locked.position if locked != null else position + dir * T.AIM_STICK_PX
	elif aim_mode == "mouse" and is_inside_tree():
		aim = world.get_global_mouse_position()
		locked = null
	elif aim_mode == "pad" and locked != null and is_instance_valid(locked) and not locked.is_dead():
		aim = locked.position
	elif aim_mode == "pad":
		aim = position + aim_dir * T.AIM_STICK_PX     # the stick let go: the aim stays out ahead as he moves, never behind him (the Deck)
	if aim.distance_to(position) > 1.0:
		aim_dir = (aim - position).normalized()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and aim_mode == "pad":
		aim_mode = "mouse"


# ---------------------------------------------------------------- the gun
func _gun_timers(dt: float) -> void:
	shot_cd -= dt                            # held, the debt carries: the stream keeps the gun's exact rate
	if not Input.is_action_pressed("slice_fire") or reloading or jammed or swap_left > 0.0:     # no burst saved up
		shot_cd = maxf(0.0, shot_cd)
	swap_left = maxf(0.0, swap_left - dt)
	if jammed:
		jam_left -= dt
		if jam_left <= 0.0:
			jammed = false
	if reloading:
		reload_left -= dt
		if reload_left <= 0.0:
			reloading = false
			if refilling:
				refilling = false
				var n: int = mini(int(guns[gun_i].get("mag", 1)) - rounds[gun_i], box_rounds())
				rounds[gun_i] += n
				add_box_rounds(-n)
				world.runner_event("reloaded", gun())
			elif gun_i < guns.size() and mags[gun_i] > 0:
				mags[gun_i] -= 1
				rounds[gun_i] = int(guns[gun_i].get("mag", 1))
				world.runner_event("reloaded", gun())


func can_fire() -> bool:
	return not dead and not reloading and not jammed and swap_left <= 0.0 and shot_cd <= 0.0 and gun_i < guns.size() and rounds[gun_i] > 0


func _trigger(fresh: bool = false) -> void:
	if gun_i >= guns.size() or reloading or jammed or swap_left > 0.0:
		return
	if rounds[gun_i] <= 0:
		if not start_reload() and fresh:
			var other := (gun_i + 1) % guns.size()
			if other != gun_i and (rounds[other] > 0 or mags[other] > 0 or box_rounds(other) > 0):
				swap()                       # dry and no magazines left: a fresh pull goes to the spare
		return
	while shot_cd <= 0.0 and can_fire():     # a stream: at a high rate several rounds can fall in one frame
		fire_once()


## One round: a jam (the beat lost) or a shot down the aim. Returns what the world made of it ({} when it couldn't).
func fire_once() -> Dictionary:
	if not can_fire():
		return {}
	var g := gun()
	shot_cd += 1.0 / maxf(0.05, float(g.get("rof", 1.0)))
	if world.roll_jam(g):
		jammed = true
		jam_left = world.jam_s()
		world.runner_event("jammed", g)
		return {"jammed": true}
	rounds[gun_i] -= 1
	var res: Dictionary = world.shoot(self, g)
	if rounds[gun_i] <= 0 and (mags[gun_i] > 0 or box_rounds() > 0):
		start_reload()
	return res


## A gun put on from the kit sheet (round 2): the bridge's entry for its slot. Its rounds and spares are its own, kept
## by the item while it's off (the review: a swap refilled for free); a gun not worn yet this run starts full.
var kept := {}                       # item id -> [rounds in, spare magazines]


func wear(e: Dictionary) -> void:
	var k := -1
	for i in range(guns.size()):
		if str(guns[i].get("slot", "")) == str(e.get("slot", "")):
			k = i
	var id: int = int(Dictionary(e.get("item", {})).get("id", -1))
	var mine: Array = kept.get(id, [int(e.get("mag", 1)), int(e.get("mags", 0))])
	kept.erase(id)
	if k < 0:
		guns.append(e.duplicate(true))
		rounds.append(mini(int(mine[0]), int(e.get("mag", 1))))
		mags.append(int(mine[1]))
		return
	var off_id: int = int(Dictionary(guns[k].get("item", {})).get("id", -1))
	if off_id >= 0:
		kept[off_id] = [rounds[k], mags[k]]
	guns[k] = e.duplicate(true)
	rounds[k] = mini(int(mine[0]), int(e.get("mag", 1)))
	mags[k] = int(mine[1])
	if k == gun_i:
		reloading = false
		refilling = false
		jammed = false


## A change of kit read again (the bridge's reread): each gun's figures, its rounds kept to its magazine; the HP, Guard
## and energy maxima and the pace. What's in hand stays (HP over a lower max comes down to it).
func reread(c: Dictionary) -> void:
	for e in c.get("guns", []):
		for i in range(guns.size()):
			if str(guns[i].get("slot", "")) == str(e.get("slot", "")) and int(Dictionary(guns[i].get("item", {})).get("id", -2)) == int(Dictionary(e.get("item", {})).get("id", -3)):
				guns[i] = e.duplicate(true)
				rounds[i] = mini(rounds[i], int(e.get("mag", 1)))
	hp_max = maxi(1, int(c.get("hp_max", hp_max)))
	hp = mini(hp, hp_max)
	guard_max = int(c.get("guard_max", guard_max))
	guard = mini(guard, guard_max)
	energy_max = float(c.get("energy_max", energy_max))
	energy = minf(energy, energy_max)
	pace_px = T.PACE_PX * maxf(T.PACE_MIN, 1.0 + float(c.get("pace_pct", 0.0)) / 100.0)


## The magazine's size at the pause's test setting (round 2, MAG_X): each gun's game figure times x; what's in a
## magazine kept, down to the new size.
func set_mag_x(x: float) -> void:
	for i in range(guns.size()):
		SliceBridge.scaled_gun(guns[i], x)
		rounds[i] = mini(rounds[i], int(guns[i]["mag"]))


## The rounds in the pack's boxes for gun i's type (the ctx's count, shared with the bridge).
func box_rounds(i := -1) -> int:
	var k: int = gun_i if i < 0 else i
	if k >= guns.size():
		return 0
	return int(ctx.get("boxes", {}).get(str(guns[k].get("ammo", "")), 0))


func add_box_rounds(n: int) -> void:
	var ty: String = str(gun().get("ammo", ""))
	if ctx.get("boxes", {}).has(ty):
		ctx["boxes"][ty] = maxi(0, int(ctx["boxes"][ty]) + n)


## A reload: a spare magazine in, or with none left and a box of its rounds in the pack, one filled by hand at the sim's
## REFILL_MULT times the reload (the sim's _refill_start; the review: 87 rounds carried against ~175 needed).
func start_reload() -> bool:
	if reloading or gun_i >= guns.size() or rounds[gun_i] >= int(guns[gun_i].get("mag", 1)):
		return false
	if mags[gun_i] <= 0:
		if box_rounds() <= 0:
			return false
		reloading = true
		refilling = true
		reload_total = SliceBridge.refill_s(guns[gun_i], mini(int(guns[gun_i].get("mag", 1)) - rounds[gun_i], box_rounds()))
		reload_left = reload_total
		world.runner_event("reload_started", gun(), reload_total)
		return true
	reloading = true
	refilling = false
	reload_total = float(guns[gun_i].get("reload_s", 2.0))
	reload_left = reload_total
	world.runner_event("reload_started", gun(), reload_total)
	return true


func swap() -> bool:
	if guns.size() < 2:
		return false
	reloading = false                      # a swap drops the reload; the magazine stays as it was
	refilling = false
	gun_i = (gun_i + 1) % guns.size()
	swap_left = T.SWAP_S
	shot_cd = 0.0
	world.runner_event("swapped", gun_i)
	return true


# ---------------------------------------------------------------- hurt, heal, leave
## A hit on the runner as the bridge computed it: {hp_loss: int, guard_loss: int}.
func apply_hit(res: Dictionary) -> void:
	if dead or res.get("missed", false):
		return
	guard = maxi(0, guard - int(res.get("guard_loss", 0)))
	hp -= int(res.get("hp_loss", 0))
	hurt_left = T.HURT_FLASH_S
	last_hurt_t = world.time_s
	world.on_runner_hurt(res)
	if hp <= 0:
		if last_legs_left > 0.0:
			hp = last_legs_back              # (the sim's Last Stand) on the hold till its seconds run out
			return
		var back: int = world.last_legs_hp() if not last_legs_used else 0
		var secs := float(ctx.get("last_legs_s", 0.0))
		if back > 0 and secs > 0.0:
			last_legs_used = true
			last_legs_back = back
			last_legs_left = secs
			hp = back
			world.runner_event("last_legs")
		else:
			_die()


func _die() -> void:
	hp = 0
	dead = true
	last_legs_left = 0.0
	world.on_runner_died()


## The sim's Last Stand: out of seconds still on the hold, he's dead; healed meanwhile, or the clear, he's through.
func _last_legs_step(dt: float) -> void:
	if last_legs_left <= 0.0:
		return
	last_legs_left -= dt
	if last_legs_left <= 0.0:
		last_legs_left = 0.0
		if hp <= last_legs_back:
			_die()


func last_legs_saved() -> void:
	last_legs_left = 0.0


func heal(n: int) -> void:
	hp = mini(hp_max, hp + maxi(0, n))


func _leave_step(held: bool, dt: float) -> void:
	if held and world.exit_rect.has_point(position):
		leaving_frac = minf(1.0, leaving_frac + dt / T.LEAVE_HOLD_S)
		if leaving_frac >= 1.0:
			world.leave()
	else:
		leaving_frac = 0.0


# ---------------------------------------------------------------- check hooks
func debug_move_to(p: Vector2) -> void:
	position = world.resolve_circle(p, T.RUNNER_R)
	velocity = Vector2.ZERO


func debug_aim_at(p: Vector2) -> void:
	aim_mode = "fixed"
	aim = p
	if aim.distance_to(position) > 1.0:
		aim_dir = (aim - position).normalized()


# ---------------------------------------------------------------- the look
func _draw() -> void:
	var r := T.RUNNER_R
	draw_circle(Vector2(6, 8), r, Color(0, 0, 0, 0.3))
	var tip := aim_dir * (T.BARREL + 18.0)
	draw_line(aim_dir * (r - 6.0), tip, C_BARREL, 12.0)
	draw_circle(Vector2.ZERO, r, C_HURT if hurt_left > 0.0 else C_BODY)
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, C_LINE, 5.0)
	if reloading and reload_total > 0.0:
		draw_arc(Vector2.ZERO, r + 12.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - reload_left / reload_total), 40, Color(C_LINE, 0.8), 4.0)
	if leaving_frac > 0.0:
		draw_arc(Vector2.ZERO, r + 22.0, -PI / 2.0, -PI / 2.0 + TAU * leaving_frac, 40, Color("3fae7a"), 6.0)
	var f: Font = world.font() if world != null else ThemeDB.fallback_font
	var you: String = SliceWorld.WORDS["you"]
	var w := f.get_string_size(you, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	draw_string(f, Vector2(-w * 0.5, r + 40.0), you, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, C_LINE)
