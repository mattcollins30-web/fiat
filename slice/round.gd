extends Node2D
## The slice's rounds in flight (build 76, builder G; board D, Matt: "look at zero sievert for inspo"): every round fired,
## the runner's and the gang's, travels at its speed with a tracer behind it and stops on the first thing in its path -
## cover (a spark), a man (the runner's: the bridge's damage) or the runner (theirs: the bridge's hit on you). One node,
## "Rounds", under the world, made on first use; the gang director steps it from its tick, so the world needs no change.
## A melee weapon's swing lands at once (no round). The world's signals (fired, hit_landed, missed) come from here.

const T := preload("res://slice/tuning.gd")
const SliceBridge := preload("res://slice/bridge.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)

const C_MINE := Color("f0c060")
const C_THEIRS := Color("ff7a4a")
const C_FLASH := Color("fff2c0")
const C_SWING := Color("e6e1d3")
const FLASH_S := 0.05
const SWING_S := 0.12

var world = null
var flying: Array = []               # {mine, pos, dir, speed, left, gun, share, head, man, ms, done, out}
var flashes: Array = []              # {at, t}
var swings: Array = []               # {at, dir, t}


## The world's "Rounds" node, made on first use.
static func layer(w) -> Node:
	var n: Node = w.get_node_or_null("Rounds")
	if n == null:
		n = (load("res://slice/round.gd") as GDScript).new()
		n.name = "Rounds"
		n.set("world", w)
		w.add_child(n)
	return n


## The rounds in flight now.
static func live(w) -> Array:
	var n: Node = w.get_node_or_null("Rounds")
	return n.get("flying").filter(func(r): return not bool(r["done"])) if n != null else []


## Every round in flight flown out (a check's helper): at most max_s of flight, a frame at a time.
static func settle(w, max_s := 2.0) -> void:
	var n: Node = layer(w)
	var t := 0.0
	while t < max_s and not live(w).is_empty():
		n.call("step", 1.0 / 60.0)
		t += 1.0 / 60.0


# ---------------------------------------------------------------- firing

## A press's rounds from the runner down his aim: one, or a shotgun's pellets, each with the gun's spread. Returns them.
func fire_runner(r, g: Dictionary) -> Array:
	var out: Array = []
	world.stats["shots"] += 1
	var n: int = maxi(1, int(g.get("pellets", 1)))
	var spread: float = deg_to_rad(r.spread_deg() if r.has_method("spread_deg") else float(g.get("spread_deg", T.SPREAD_DEG)))     # (round 6) the kick in it
	var press := {"hit": false}              # a shell's pellets: one press, one hit in the run's figures however many land
	for _k in range(n):
		var dir: Vector2 = r.aim_dir.rotated(world.rng.randf_range(-spread, spread))
		var rd := {"mine": true, "pos": r.position, "from": r.position, "dir": dir, "speed": T.G_ROUND_PX_S, "left": T.G_ROUND_RANGE,
			"gun": g, "share": 1.0 / float(n), "head": false, "man": null, "ms": {}, "done": false, "out": {}, "age": 0.0, "press": press}
		flying.append(rd)
		out.append(rd)
	flashes.append({"at": r.position + r.aim_dir * T.BARREL, "t": FLASH_S})
	world.fired.emit(g)
	if world.has_method("shake"):
		world.shake(T.SHAKE_FIRE)
	queue_redraw()
	return out


## One of their rounds from man `mn` toward `at` (his aim, its error already in it).
func fire_man(mn, at: Vector2) -> Dictionary:
	var from: Vector2 = mn.global_position
	var dir: Vector2 = (at - from).normalized() if at.distance_to(from) > 1.0 else Vector2.RIGHT
	var rd := {"mine": false, "pos": from, "from": from, "dir": dir, "speed": T.G_THEIR_ROUND_PX_S, "left": T.G_THEIR_RANGE,
		"gun": {}, "share": 1.0, "head": false, "man": mn, "ms": mn.ms, "done": false, "out": {}, "age": 0.0}
	flying.append(rd)
	flashes.append({"at": from + dir * (float(mn.radius) + 8.0), "t": FLASH_S})
	queue_redraw()
	return rd


## A melee weapon's blow: the nearest man in reach and in the arc before him, in sight. Returns {man, point, result}.
func swing(r, g: Dictionary) -> Dictionary:
	world.stats["shots"] += 1
	world.fired.emit(g)
	swings.append({"at": r.position, "dir": r.aim_dir, "t": SWING_S})
	queue_redraw()
	var best = null
	var bd := INF
	var reach: float = T.RUNNER_R + T.G_MELEE_REACH
	for mn in world.men():
		var to: Vector2 = mn.position - r.position
		var d: float = to.length() - float(mn.get("radius") if mn.get("radius") != null else T.MAN_R)
		if d > reach or d >= bd:
			continue
		if to.length() > 1.0 and absf(r.aim_dir.angle_to(to)) > deg_to_rad(T.G_MELEE_ARC_DEG):
			continue
		if not world.has_los(r.position, mn.position):
			continue
		bd = d
		best = mn
	if best == null:
		return {"man": null, "point": r.position + r.aim_dir * reach, "result": {}}
	var rd := {"mine": true, "pos": best.position, "from": r.position, "dir": r.aim_dir, "gun": g, "share": 1.0, "head": false}
	return _hit_man(rd, best, best.position)


# ---------------------------------------------------------------- flight

func step(dt: float) -> void:
	if world == null:
		return
	for rd in flying:
		if bool(rd["done"]):
			continue
		_fly(rd, dt)
	flying = flying.filter(func(rd): return not bool(rd["done"]) or float(rd.get("fade", 0.0)) > 0.0)
	for rd in flying:
		if bool(rd["done"]):
			rd["fade"] = float(rd.get("fade", 0.0)) - dt
	for f in flashes:
		f["t"] = float(f["t"]) - dt
	flashes = flashes.filter(func(f): return float(f["t"]) > 0.0)
	for s in swings:
		s["t"] = float(s["t"]) - dt
	swings = swings.filter(func(s): return float(s["t"]) > 0.0)
	queue_redraw()


func _fly(rd: Dictionary, dt: float) -> void:
	var a: Vector2 = rd["pos"]
	var go: float = minf(float(rd["speed"]) * dt, float(rd["left"]))
	var b: Vector2 = a + Vector2(rd["dir"]) * go
	rd["age"] = float(rd["age"]) + dt
	var best_t := 2.0
	for rect in world.level.blocks:
		var t := seg_rect(a, b, rect)
		if t >= 0.0 and t < best_t and not (t == 0.0 and (rect as Rect2).has_point(Vector2(rd["from"]))):
			best_t = t
	var who = null
	if bool(rd["mine"]):
		for mn in world.men():
			var t := seg_circle(a, b, mn.position, float(mn.get("radius") if mn.get("radius") != null else T.MAN_R))
			if t >= 0.0 and t < best_t:
				best_t = t
				who = mn
	else:
		var r = world.runner
		if r != null and is_instance_valid(r) and not r.is_dead():
			var t := seg_circle(a, b, r.position, T.RUNNER_R)
			if t >= 0.0 and t < best_t:
				best_t = t
				who = r
	if best_t > 1.0:
		rd["pos"] = b
		rd["left"] = float(rd["left"]) - go
		if float(rd["left"]) <= 0.0 or not world.park_rect.has_point(b):
			_end(rd, b, "spent")
		return
	var p: Vector2 = a + (b - a) * best_t
	rd["pos"] = p
	if who == null:
		_end(rd, p, "cover")
	elif bool(rd["mine"]):
		_end(rd, p, "hit")
		rd["out"] = _hit_man(rd, who, p)
	else:
		_end(rd, p, "hit")
		rd["out"] = _hit_runner(rd, who)


## A round's end: "cover" (a spark), "spent" (its range, or out of the park), "hit" (the caller lands it).
func _end(rd: Dictionary, p: Vector2, how: String) -> void:
	rd["done"] = true
	rd["fade"] = T.G_TRACER_PX / maxf(1.0, float(rd["speed"]))     # the tracer's tail runs into the point
	rd["pos"] = p
	rd["out"] = {"man": null, "point": p, "result": {}}
	rd["how"] = how
	if how == "cover" and world.get("fx") != null and world.fx.has_method("spark"):
		world.fx.spark(p)
	if bool(rd["mine"]) and how != "hit":
		world.missed.emit(p)


## The runner's round on a man, as the world's shoot() had it: the bridge's damage, the stats, the flash and knock.
func _hit_man(rd: Dictionary, mn, p: Vector2) -> Dictionary:
	var g: Dictionary = rd["gun"]
	var dir: Vector2 = rd["dir"]
	var shot := {"gun": g, "from": rd["from"], "point": p, "dir": dir, "dist": Vector2(rd["from"]).distance_to(p), "runner": world.runner,
		"world": world, "share": float(rd["share"])}
	var res: Dictionary = mn.take_shot(shot)
	if res.get("missed", false):
		world.missed.emit(p)
		return {"man": mn, "point": p, "result": res}
	var press: Dictionary = rd.get("press", {})
	if not bool(press.get("hit", false)):
		world.stats["hits"] += 1             # (a shell: once, however many pellets land)
		press["hit"] = true
	world.stats["damage_done"] += int(res.get("damage", 0))
	if res.get("headshot", false):
		world.stats["headshots"] += 1
	if world.get("fx") != null and world.fx.has_method("hit_flash"):
		world.fx.hit_flash(mn)
	if mn.has_method("knock"):
		mn.knock(dir, T.KNOCK_PX * float(rd["share"]) / maxf(1.0, float(g.get("rof", 1.0))))
	if world.has_method("shake"):
		world.shake(T.SHAKE_HIT)
	world.hit_landed.emit(mn, res, p)
	return {"man": mn, "point": p, "result": res}


## Their round on the runner: the bridge's hit (types, armour, the crowd, Guard first).
func _hit_runner(rd: Dictionary, r) -> Dictionary:
	var mn = rd["man"]
	var gang = world.get("gang")
	var on_you: int = gang.on_you() if gang != null else 1
	var spot: bool = gang != null and gang.spotter_on(int(Dictionary(rd["ms"]).get("gang", 0)))
	var res: Dictionary = SliceBridge.hit_on_runner(world.ctx, r, rd["ms"], world.rng, on_you, spot)
	if not bool(res["missed"]) and (int(res["hp_loss"]) > 0 or int(res["guard_loss"]) > 0):
		r.apply_hit(res)
	if mn != null and is_instance_valid(mn):
		mn.set("landed", int(mn.get("landed")) + 1)
	return {"man": r, "point": rd["pos"], "result": res}


# ---------------------------------------------------------------- the geometry (the world's, kept here: no static call on an instance)

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


static func seg_circle(a: Vector2, b: Vector2, c: Vector2, r: float) -> float:
	var d := b - a
	var f := a - c
	var qa := d.dot(d)
	if qa < 0.000001:
		return 0.0 if f.length() <= r else -1.0
	var qb := 2.0 * f.dot(d)
	var qc := f.dot(f) - r * r
	var disc := qb * qb - 4.0 * qa * qc
	if disc < 0.0:
		return -1.0
	if qc <= 0.0:
		return 0.0
	var t := (-qb - sqrt(disc)) / (2.0 * qa)
	return t if t >= 0.0 and t <= 1.0 else -1.0


# ---------------------------------------------------------------- the look

func _draw() -> void:
	for rd in flying:
		var p: Vector2 = rd["pos"]
		var tail: float = minf(T.G_TRACER_PX, Vector2(rd["from"]).distance_to(p))
		var c: Color = C_MINE if bool(rd["mine"]) else C_THEIRS
		var k := 1.0
		if bool(rd["done"]):
			k = clampf(float(rd.get("fade", 0.0)) * float(rd["speed"]) / T.G_TRACER_PX, 0.0, 1.0)
			tail *= k
		if tail > 0.5:
			draw_line(p - Vector2(rd["dir"]) * tail, p, Color(c, 0.9 * k), 3.0 if bool(rd["mine"]) else 3.5)
	for f in flashes:
		var k: float = clampf(float(f["t"]) / FLASH_S, 0.0, 1.0)
		draw_circle(f["at"], 14.0 * k + 5.0, Color(C_FLASH, k))
	for s in swings:
		var k: float = clampf(float(s["t"]) / SWING_S, 0.0, 1.0)
		var a: float = Vector2(s["dir"]).angle()
		var arc: float = deg_to_rad(T.G_MELEE_ARC_DEG)
		draw_arc(s["at"], T.RUNNER_R + T.G_MELEE_REACH * 0.8, a - arc, a + arc, 16, Color(C_SWING, 0.8 * k), 6.0)
