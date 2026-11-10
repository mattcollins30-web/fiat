extends CharacterBody2D
## The runner in the slice (build 72): a token that moves 8 ways at the class's pace (tight - a tenth of a second up
## to speed, no slide), aims at the mouse or the right stick (a soft lock-on on the pad), fires the gun's stream at its
## rate, counts the magazine down, reloads in the gun's time, jams when the bridge says, swaps to the spare, searches
## crates, and holds X/B in the way out to leave. The world steps him (world.tick) so a headless check can too.
const SliceWorld := preload("res://slice/slice.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const SliceBridge := preload("res://slice/bridge.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const SliceRound := preload("res://slice/round.gd")     # (build 76) rounds that travel

const T := preload("res://slice/tuning.gd")
const Art := preload("res://slice/art.gd")
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
var steady_left := 0.0               # (round 7, board F) Clean shot: steadying, seconds to go (no fire meanwhile)
var clean_armed := false             # ...steadied: the next round can't miss the head it's aimed at and goes through one man
var dodge_t := 0.0                   # (round 7, board G) in a dodge: seconds of it left (nothing lands on him meanwhile)
var dodge_cd := 0.0                  # ...and seconds till the next
var dodge_dir := Vector2.RIGHT
var dodges := 0
var debug_dodge := false             # a check's press of Space
var swap_asked := false              # (10 Nov) the wheel turned since the last tick
var sights := false                  # (10 Nov) down the sights this tick: the right button held, the main gun ready
var debug_sights := false            # a check's hold of the right button
var shot_cd := 0.0
var kick := 0.0                      # (round 6) degrees the fire so far adds to the spread; it settles when he eases off
var kick_t := 0.0                    # seconds since the last round
var fire_t := 0.0                     # (round 5's review) just fired: the art's "fire" pose this long
const YOU_PX := 26                    # "You" on screen, px (board A's size; drawn at YOU_PX / CAM_ZOOM in the world)
const SHOT_EPS := 1e-6                # (round 5's review) the beat's leftover after frames of dt: a float's crumb isn't a wait
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
var heavy_t := 0.0                  # (board K) a melee weapon's button held this long since his last swing
var heavy_next := false             # ...the swing about to land is a heavy one
var debug_hold := false             # a check's held button
var press_kept := 0.0               # (build 76) a press on a semi gun inside its cap: kept this long, fires when it can
var auto_move := Vector2.ZERO        # a check's walk (debug_move_dir); zero means the controls


## The slice's controls that aren't the project's own (10 Nov; project.godot is left alone): sights on the right
## button, held; the swap off it, onto V (the wheel is _input's; the pad's Y stays).
static func ensure_actions() -> void:
	if not InputMap.has_action("slice_sights"):
		InputMap.add_action("slice_sights", 0.5)
		var rb := InputEventMouseButton.new()
		rb.button_index = MOUSE_BUTTON_RIGHT
		rb.device = -1
		InputMap.action_add_event("slice_sights", rb)
	if not InputMap.has_action("slice_dodge"):         # (round 7) the dodge on Space; the reload on R alone
		InputMap.add_action("slice_dodge", 0.5)
		var sp := InputEventKey.new()
		sp.physical_keycode = KEY_SPACE
		sp.device = -1
		InputMap.action_add_event("slice_dodge", sp)
	if InputMap.has_action("slice_reload"):
		for ev in InputMap.action_get_events("slice_reload"):
			if ev is InputEventKey and (ev.physical_keycode == KEY_SPACE or ev.keycode == KEY_SPACE):
				InputMap.action_erase_event("slice_reload", ev)
	if InputMap.has_action("slice_swap"):
		var has_v := false
		for ev in InputMap.action_get_events("slice_swap"):
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT:
				InputMap.action_erase_event("slice_swap", ev)
			elif ev is InputEventKey and ev.physical_keycode == KEY_V:
				has_v = true
		if not has_v:
			var kv := InputEventKey.new()
			kv.physical_keycode = KEY_V
			kv.device = -1
			InputMap.action_add_event("slice_swap", kv)


func setup(w: Node, c: Dictionary) -> void:
	ensure_actions()
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
	dodge_cd = maxf(0.0, dodge_cd - dt)
	if debug_dodge or (InputMap.has_action("slice_dodge") and Input.is_action_just_pressed("slice_dodge")):
		dodge()
	debug_dodge = false
	_sights_step()
	_move(dt)
	_aim()
	_gun_timers(dt)
	var pulled := Input.is_action_pressed("slice_fire")
	if pulled and not trigger_was:
		press_kept = T.G_PRESS_KEEP_S
	if pulled or press_kept > 0.0:
		_trigger(pulled and not trigger_was)
	_heavy_step(dt, pulled or debug_hold)
	press_kept = maxf(0.0, press_kept - dt)
	trigger_was = pulled
	if Input.is_action_just_pressed("slice_reload"):
		start_reload()
	if Input.is_action_just_pressed("slice_swap") or (swap_asked and swap_left <= 0.0):     # a spin of the wheel is one swap
		swap()
	swap_asked = false
	for i in range(3):
		if Input.is_action_just_pressed("slice_skill_%d" % (i + 1)):
			world.use_skill(i)
	for i in range(4):
		if Input.is_action_just_pressed("slice_med_%d" % (i + 1)):
			world.use_med(i)
	world.search_step(self, Input.is_action_pressed("slice_use"), dt)
	_leave_step(Input.is_action_pressed("slice_out"), dt)
	queue_redraw()


## (round 7, board G) The dodge: a short dive the way he's walking (the way he's aiming, stood still). It drops a reload
## and the sights; nothing lands on him while it lasts (dodging()). False when it isn't ready.
func dodge() -> bool:
	if dead or dodge_cd > 0.0 or dodge_t > 0.0 or leaving_frac > 0.0:
		return false
	var want := auto_move
	if want == Vector2.ZERO:
		want = Input.get_vector("slice_move_left", "slice_move_right", "slice_move_up", "slice_move_down", T.MOVE_DEADZONE)
	dodge_dir = want.normalized() if want.length() > 0.1 else (velocity.normalized() if velocity.length() > 40.0 else aim_dir)
	dodge_t = T.DODGE_S
	dodge_cd = T.DODGE_EVERY_S
	steady_left = 0.0                        # a dive breaks the steadying (a round already steadied is kept)
	dodges += 1
	reloading = false
	refilling = false
	sights = false
	return true


## Clean shot can be started: a gun in hand, and no round steadied or steadying already.
func can_steady() -> bool:
	return gun_i < guns.size() and not is_melee() and not clean_armed and steady_left <= 0.0 and not dead


## (round 7, board F) Clean shot: `secs` steadying, then the next round is the clean one. A dodge breaks it.
func steady(secs: float) -> void:
	steady_left = maxf(0.01, secs)
	clean_armed = false


## (round 7, board F) One for the pot: the magazine in the gun filled where he stands, a reload under way dropped.
func fill_magazine() -> void:
	if gun_i >= guns.size() or is_melee():
		return
	rounds[gun_i] = int(gun().get("mag", rounds[gun_i]))
	reloading = false
	refilling = false


func dodging() -> bool:
	return dodge_t > 0.0


func _move(dt: float) -> void:
	if dodge_t > 0.0:
		var step_s: float = minf(dt, dodge_t)
		dodge_t -= dt
		velocity = dodge_dir * (T.DODGE_PX / T.DODGE_S)
		position = world.resolve_circle(position + velocity * step_s, T.RUNNER_R)
		if dodge_t <= 0.0:
			velocity = dodge_dir * pace_px       # out of it at his walk, not at the dive's speed
		return
	var want := auto_move
	if want == Vector2.ZERO:
		want = Input.get_vector("slice_move_left", "slice_move_right", "slice_move_up", "slice_move_down", T.MOVE_DEADZONE)
	if want.length() > 1.0:
		want = want.normalized()
	var target := want * pace_px * (T.G_SIGHTS_PACE_X if sights else 1.0)
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
		if world.has_method("play_foot_y"):
			aim.y = minf(aim.y, world.play_foot_y())     # (round 7, the review) the mouse over the HUD's band: the aim stops at the play's foot, the crosshair in view
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
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		swap_asked = true                    # the wheel's notch is gone within the frame: kept for the next tick


## (10 Nov) Down the sights: the right button held (or a check's debug_sights) with the main gun up and ready - not the
## spare, not a melee weapon, not mid-reload, swap or search.
func sights_wanted() -> bool:
	return debug_sights or (InputMap.has_action("slice_sights") and Input.is_action_pressed("slice_sights"))


func _sights_step() -> void:
	sights = sights_wanted() and dodge_t <= 0.0 and gun_i == 0 and gun_i < guns.size() and not is_melee() and not reloading and not refilling and swap_left <= 0.0 and searching == null and not dead


# ---------------------------------------------------------------- the gun
func _gun_timers(dt: float) -> void:
	fire_t = maxf(0.0, fire_t - dt)
	if shot_cd > 0.0:                        # held, the debt carries: the stream keeps the gun's exact rate; (round 5's
		shot_cd -= dt                        # review) a ready gun doesn't run up credit before the press
	if not Input.is_action_pressed("slice_fire") or reloading or jammed or swap_left > 0.0:     # no burst saved up
		shot_cd = maxf(0.0, shot_cd)
	swap_left = maxf(0.0, swap_left - dt)
	if steady_left > 0.0:
		steady_left -= dt
		if steady_left <= 0.0:
			steady_left = 0.0
			clean_armed = true
	kick_t += dt
	var kmax: float = float(gun().get("kick_max", 0.0)) if gun_i < guns.size() else 0.0
	kick = minf(kick, kmax)                  # a swap: the gun in hand's own most
	if kick_t > T.G_KICK_HOLD_S:
		kick = move_toward(kick, 0.0, kmax / T.G_KICK_SETTLE_S * dt)
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
	return not dead and dodge_t <= 0.0 and steady_left <= 0.0 and not reloading and not jammed and swap_left <= 0.0 and shot_cd <= SHOT_EPS and gun_i < guns.size() and (rounds[gun_i] > 0 or is_melee())


## (board K) A melee weapon's button held: G_HEAVY_HOLD_S on from his last swing (and the weapon ready), a heavy one -
## and another as long as it's held. A tap is the light swing, at once, as before.
func _heavy_step(dt: float, held: bool) -> void:
	if not held or not is_melee() or dead or gun_i >= guns.size():
		heavy_t = 0.0
		return
	heavy_t += dt
	if heavy_t >= T.G_HEAVY_HOLD_S and can_fire():
		swing_heavy()


## The heavy swing itself (a check calls it straight).
func swing_heavy() -> Dictionary:
	heavy_next = true
	var out := fire_once()
	heavy_next = false
	heavy_t = 0.0
	return out


## (build 76) A melee weapon in hand: it swings, no rounds.
func is_melee() -> bool:
	return bool(gun().get("melee", false))


## (build 76) The trigger by the gun's fire (bridge's kind): an auto gun streams while it's held at its rate; a semi gun,
## a pump shotgun or a melee weapon gives one round (a shell, a blow) a press, no faster than its cap - a press inside
## the cap is kept G_PRESS_KEEP_S and fires when the gun's ready.
func _trigger(fresh: bool = false) -> void:
	if gun_i >= guns.size() or reloading or jammed or swap_left > 0.0:
		return
	if is_melee():
		if press_kept > 0.0 and can_fire():
			press_kept = 0.0
			fire_once()
		return
	if rounds[gun_i] <= 0:
		if not start_reload() and fresh:
			world.runner_event("dry", gun())     # (round 6) the click of an empty gun
			var other := (gun_i + 1) % guns.size()
			if other != gun_i and (rounds[other] > 0 or mags[other] > 0 or box_rounds(other) > 0 or bool(guns[other].get("melee", false))):
				swap()                       # dry and no magazines left: a fresh pull goes to the spare
		return
	if not bool(gun().get("auto", true)):
		if press_kept > 0.0 and can_fire():
			press_kept = 0.0                 # one a press
			fire_once()
		return
	while shot_cd <= SHOT_EPS and can_fire():     # a stream: at a high rate several rounds can fall in one frame
		fire_once()


## (round 6) Degrees either side of the aim the next round can go: the gun's own spread and the kick held fire has built.
func spread_deg() -> float:
	if gun_i >= guns.size():
		return T.SPREAD_DEG
	if clean_armed:
		return 0.0                           # (round 7) the clean round: where it's aimed
	var own: float = float(gun().get("spread_deg", T.SPREAD_DEG))
	return own * T.G_SIGHTS_SPREAD_X + kick * T.G_SIGHTS_KICK_X if sights and gun_i == 0 else own + kick


## The crosshair's gap in the world's px: the spread's width at the aim point, never under its least on screen.
func cross_r() -> float:
	if is_melee():
		return T.G_CROSS_MIN_PX / T.CAM_ZOOM
	return maxf(T.G_CROSS_MIN_PX / T.CAM_ZOOM, aim.distance_to(position) * tan(deg_to_rad(spread_deg())))


## One press's worth: a jam (the beat lost), a blow (melee: {man, point, result} at once), or the round(s) sent down the
## aim, travelling (build 76): {"rounds": [the round's state, SliceRound's]} - what each hit lands as it gets there.
func fire_once() -> Dictionary:
	if not can_fire():
		return {}
	var g := gun()
	var beat: float = 1.0 / maxf(0.05, float(g.get("rof", 1.0)))
	fire_t = T.TRACER_S
	shot_cd = shot_cd + beat if bool(g.get("auto", true)) else beat     # held, an auto gun's debt carries (its exact rate); a press: the cap
	var rl: Node = SliceRound.layer(world)
	if is_melee():
		if heavy_next:
			shot_cd = beat * T.G_HEAVY_BEAT_X
		heavy_t = 0.0
		return rl.swing(self, g, heavy_next)
	if world.roll_jam(g):
		jammed = true
		jam_left = world.jam_s()
		world.runner_event("jammed", g)
		return {"jammed": true}
	rounds[gun_i] -= 1
	if sights and world.get("stats") is Dictionary:
		world.stats["sight_shots"] = int(world.stats.get("sight_shots", 0)) + 1     # the run log's: presses down the sights
	var sent: Array = rl.fire_runner(self, g)
	if clean_armed:
		for rd in sent:
			rd["head"] = true
			rd["pierce"] = 1
			rd["clean"] = true               # the game's own bonus rides on the round (the review: not a flag any hit could take)
		clean_armed = false
	kick = minf(float(g.get("kick_max", 0.0)), kick + float(g.get("kick_deg", 0.0)))     # the round gone, the next is wider
	kick_t = 0.0
	if rounds[gun_i] <= 0 and (mags[gun_i] > 0 or box_rounds() > 0):
		start_reload()
	return {"rounds": sent}


## fire_once, and its round flown to its end (a check's helper, at most max_s): the old shape {man, point, result}, the
## first pellet that found a man for a shotgun, or {"jammed": true}, or {} when it couldn't fire.
func fire_once_landed(max_s := 2.0) -> Dictionary:
	var out := fire_once()
	if not out.has("rounds"):
		return out
	var rl: Node = SliceRound.layer(world)
	var t := 0.0
	while t < max_s and Array(out["rounds"]).any(func(rd): return not bool(rd["done"])):
		rl.step(1.0 / 60.0)
		t += 1.0 / 60.0
	var first: Dictionary = {}
	for rd in out["rounds"]:
		var o: Dictionary = rd.get("out", {})
		if first.is_empty() or (first.get("man") == null and o.get("man") != null):
			first = o
	return first


## The kit changed in the Kit room (round 4, any slot): the guns as the bridge now has them, in its order. Each gun's
## rounds and spares are its own, by the item: a gun worn before keeps what it had (in hand or put by while off - the
## review: a swap refilled for free); one new to the run starts full. The HP, Guard and energy maxima and the pace
## follow; what's in hand stays, down to a lower max.
var kept := {}                       # item id -> [rounds in, spare magazines spent], for every gun the runner has held


func kit_changed(c: Dictionary) -> void:
	for k in range(guns.size()):
		var id_k: int = int(Dictionary(guns[k].get("item", {})).get("id", -1))
		if id_k >= 0:
			kept[id_k] = [rounds[k], maxi(0, int(guns[k].get("mags", 0)) - mags[k])]     # the spares spent, not left
	var held_id: int = int(Dictionary(gun().get("item", {})).get("id", -1)) if gun_i < guns.size() else -1
	var new_guns: Array = []
	var new_rounds: Array[int] = []
	var new_mags: Array[int] = []
	for e in c.get("guns", []):
		var id: int = int(Dictionary(e.get("item", {})).get("id", -1))
		var mine: Array = kept.get(id, [int(e.get("mag", 1)), 0])
		new_guns.append(Dictionary(e).duplicate(true))
		new_rounds.append(mini(int(mine[0]), int(e.get("mag", 1))))
		new_mags.append(maxi(0, int(e.get("mags", 0)) - int(mine[1])))     # (the review) the spares as the rig has them now, less those spent
	guns = new_guns
	rounds = new_rounds
	mags = new_mags
	gun_i = 0
	for k in range(guns.size()):
		if int(Dictionary(guns[k].get("item", {})).get("id", -1)) == held_id:
			gun_i = k                          # the gun in hand stays in hand while it's still worn
	if held_id < 0 or gun_i >= guns.size() or int(Dictionary(guns[gun_i].get("item", {})).get("id", -1)) != held_id:
		reloading = false
		refilling = false
		jammed = false
	hp_max = maxi(1, int(c.get("hp_max", hp_max)))
	hp = mini(hp, hp_max)
	guard_max = int(c.get("guard_max", guard_max))
	guard = mini(guard, guard_max)
	energy_max = float(c.get("energy_max", energy_max))
	energy = minf(energy, energy_max)
	pace_px = T.PACE_PX * maxf(T.PACE_MIN, 1.0 + float(c.get("pace_pct", 0.0)) / 100.0)


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
## The runner's picture, in the art set's poses (round 5's review: art.gd maps them to Kenney's while the set isn't in
## slice/art/pl/): down when dead, reload while reloading, the gun down ("stand") while searching, leaving or swapping,
## fire just after a shot, else aim. kenney_up() is Kenney's gun-up picture for it: "gun" for a pistol, else "machine".
func pose() -> String:
	if dead:
		return "down"
	if reloading:
		return "reload"
	if searching != null or leaving_frac > 0.0 or swap_left > 0.0:
		return "stand"
	return "fire" if fire_t > 0.0 else "aim"


func kenney_up() -> String:
	return "gun" if str(gun().get("type", "")) == "pistol" else "machine"


## (round 5's review) "You" under him at the camera's zoom: its font in world px, so on screen it's YOU_PX.
static func you_px() -> int:
	return roundi(YOU_PX / T.CAM_ZOOM)


func _draw() -> void:
	var r := T.RUNNER_R
	draw_circle(Vector2(6, 8), r, Color(0, 0, 0, 0.3))
	draw_circle(Vector2.ZERO, r, Color(C_BODY, 0.55))     # his disc and amber ring: he reads apart from the men
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, C_LINE, 5.0)
	if not Art.draw_char(self, Art.RUNNER, pose(), aim_dir.angle(), r * 0.95, Color.WHITE, kenney_up()):
		draw_line(aim_dir * (r - 6.0), aim_dir * (T.BARREL + 18.0), C_BARREL, 12.0)     # no picture: the token, as before
		draw_circle(Vector2.ZERO, r - 3.0, C_BODY)
	if hurt_left > 0.0:
		draw_circle(Vector2.ZERO, r, Color(C_HURT, 0.65))     # hit: he flashes
	if reloading and reload_total > 0.0:
		draw_arc(Vector2.ZERO, r + 12.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - reload_left / reload_total), 40, Color(C_LINE, 0.8), 4.0)
	if leaving_frac > 0.0:
		draw_arc(Vector2.ZERO, r + 22.0, -PI / 2.0, -PI / 2.0 + TAU * leaving_frac, 40, Color("3fae7a"), 6.0)
	var f: Font = world.font() if world != null else ThemeDB.fallback_font
	var you: String = SliceWorld.WORDS["you"]
	var fs: int = you_px()
	var w := f.get_string_size(you, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(f, Vector2(-w * 0.5, r + 14.0 + fs), you, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, C_LINE)
