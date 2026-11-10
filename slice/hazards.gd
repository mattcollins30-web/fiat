extends Node2D
## The slice's ground hazards (round 7, board G): a thrower's bottle. Thrown at where the runner stands, it lands
## G_THROW_FLY_S later - the circle on the ground from the moment it leaves his hand is the warning - and burns there
## G_THROW_BURN_S: a runner stood in it takes a man's fire for G_THROW_FIRE_S over the whole burn, a tick at a time.
## One node, "Hazards", under the world, made on first use; the gang director steps it from its tick, as it does the
## rounds, so the world needs no change.

const T := preload("res://slice/tuning.gd")
const SliceBridge := preload("res://slice/bridge.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)

const C_WARN := Color("e0705a")
const C_BURN := Color("f08a3c")

var world = null
var items: Array = []                 # {at, fly, burn, acc, ms, landed}
var landed := 0                       # bottles that have landed (a check's)
var burnt := 0                        # ticks that reached the runner


static func layer(w) -> Node:
	var n: Node = w.get_node_or_null("Hazards")
	if n == null:
		n = (load("res://slice/hazards.gd") as GDScript).new()
		n.name = "Hazards"
		n.set("world", w)
		w.add_child(n)
		var men = w.get("men_root")
		if men != null and men.get_parent() == w:
			w.move_child(n, men.get_index())     # (the review) on the ground: over the level and the crates, under the men, the runner and the fog
	return n


## A bottle from `mn` at the ground point `at`.
func throw(mn, at: Vector2) -> Dictionary:
	var it := {"at": at, "fly": T.G_THROW_FLY_S, "burn": T.G_THROW_BURN_S, "acc": 0.0, "ms": Dictionary(mn.ms).duplicate(), "landed": false}
	it["ms"]["arm_t"] = 0.0                  # (the review) the fire isn't his arm: a shot arm at the throw doesn't make its ticks miss
	# a tick's damage: the burn's whole share of a man's fire over its ticks, as rounds of his (their_round's scale)
	it["ms"]["round_x"] = T.G_THROW_FIRE_S * (T.G_THROW_TICK_S / T.G_THROW_BURN_S) * SliceBridge.their_rps() * T.G_HIT_OPEN
	items.append(it)
	queue_redraw()
	return it


func step(dt: float) -> void:
	if items.is_empty():
		return
	var r = world.runner if world != null else null
	for it in items:
		if float(it["fly"]) > 0.0:
			it["fly"] = float(it["fly"]) - dt
			if float(it["fly"]) <= 0.0:
				it["landed"] = true
				landed += 1
			continue
		it["burn"] = float(it["burn"]) - dt
		if r == null or not is_instance_valid(r) or r.is_dead():
			continue
		if Vector2(it["at"]).distance_to(r.global_position) <= T.G_THROW_R_PX:
			it["acc"] = float(it["acc"]) + dt
			while float(it["acc"]) >= T.G_THROW_TICK_S - 0.0001:     # (the review) the last tick isn't lost to the sum's rounding
				it["acc"] = float(it["acc"]) - T.G_THROW_TICK_S
				var res: Dictionary = SliceBridge.hit_on_runner(world.ctx, r, it["ms"], world.rng, 1, false)
				if not bool(res["missed"]) and (int(res["hp_loss"]) > 0 or int(res["guard_loss"]) > 0):
					r.apply_hit(res)
					burnt += 1
	items = items.filter(func(it): return float(it["fly"]) > 0.0 or float(it["burn"]) > 0.0)
	queue_redraw()


func _draw() -> void:
	for it in items:
		var at: Vector2 = it["at"]
		if float(it["fly"]) > 0.0:
			var k: float = clampf(1.0 - float(it["fly"]) / T.G_THROW_FLY_S, 0.0, 1.0)
			draw_circle(at, T.G_THROW_R_PX, Color(C_WARN, 0.10))
			for i in range(24):                 # the warning: a dashed ring, and one closing in on it as the bottle comes
				if i % 2 == 0:
					draw_arc(at, T.G_THROW_R_PX, i * TAU / 24.0, (i + 1) * TAU / 24.0, 6, C_WARN, 4.0 / T.CAM_ZOOM)
			draw_arc(at, T.G_THROW_R_PX * (2.0 - k), 0.0, TAU, 48, Color(C_WARN, 0.3 + 0.5 * k), 2.0 / T.CAM_ZOOM)
		else:
			var a: float = clampf(float(it["burn"]) / T.G_THROW_BURN_S, 0.0, 1.0)
			draw_circle(at, T.G_THROW_R_PX, Color(C_BURN, 0.18 + 0.22 * a))
			draw_arc(at, T.G_THROW_R_PX, 0.0, TAU, 48, Color(C_BURN, 0.5 + 0.4 * a), 4.0 / T.CAM_ZOOM)
