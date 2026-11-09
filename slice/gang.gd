extends Node2D
## The gang director (build 72, builder G): three gangs on the gang clock at the park's edges, their men (SliceMan), the
## hard man and his traits, the clear. W makes it (SliceGang.new(), child "Gang") and calls setup(world); it runs the
## bridge's frame (SliceBridge.tick) itself. H reads the clock: gang_i, gangs, next_in, alive, hard_man.
const SliceMan := preload("res://slice/man.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const SliceBridge := preload("res://slice/bridge.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)

const T := preload("res://slice/tuning.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")

signal gang_arrived(i: int, size: int)
signal gang_down(i: int)
signal hard_man_in(man: Node)

var world = null
var gangs := T.G_GANGS
var gang_i := -1                     # the last gang in (0..2); -1 before the first
var next_in := T.G_FIRST_GANG_S      # seconds to the next gang; -1 when all three are in
var alive := 0                       # men standing in the park
var hard_man: Node = null            # the hard man while he lives
var hard_seen := false
var cleared := false
var men_by_gang := {}                # gang i -> men left
var last_seen := Vector2.ZERO        # the runner where they last saw him
var _on_you := 0
var _men: Array = []
var _all: Array = []                 # every man still drawn (the dead fade out)


func setup(world_v) -> void:
	world = world_v
	gangs = int(world.ctx["site"].get("gangs", T.G_GANGS))
	next_in = float(world.ctx["site"].get("first_gang_s", T.G_FIRST_GANG_S))
	world.ctx["world"] = world


## The gang in the park now as H shows it: "Gang 2 of 3".
func gang_shown() -> int:
	return clampi(gang_i + 1, 0, gangs)


func live_men() -> Array:
	return _men


## The men who may fire this frame (the review: the sim's contact(t), so many on you at once): the nearest of those who
## saw you last frame.
var _firing: Array = []


func _pick_firing() -> void:
	var rp: Vector2 = world.runner.global_position if world.runner != null else Vector2.ZERO
	var seeing: Array = _men.filter(func(mn): return is_instance_valid(mn) and not mn.is_dead() and mn.sees)
	seeing.sort_custom(func(a, b): return a.global_position.distance_to(rp) < b.global_position.distance_to(rp))
	_firing = seeing.slice(0, maxi(1, int(world.ctx.get("contact", 3))))


func may_fire(mn: Node) -> bool:
	return mn in _firing


## How many have you in their sights (the crowd rules).
func on_you() -> int:
	return maxi(1, _on_you)


## A Spotter (the hard man's trait) standing in gang `i`: its fire on you more.
func spotter_on(i: int) -> bool:
	return hard_man != null and is_instance_valid(hard_man) and not hard_man.is_dead() and "spotter" in hard_man.traits and int(hard_man.ms.get("gang", -1)) == i


func note_runner(p: Vector2) -> void:
	last_seen = p


## In the tree with nobody driving it, the director steps itself; once the world calls tick(), the world drives.
var driven := false


func _physics_process(dt: float) -> void:
	if not driven:
		_step(dt)


## The world's frame (W's slice.gd, or H's headless smoke): the bridge's frame, every man, the gang clock, the clear.
func tick(dt: float) -> void:
	driven = true
	_step(dt)


func _step(dt: float) -> void:
	if world == null or world.get("ended") == true:
		return
	SliceBridge.tick(world, dt)
	_pick_firing()
	for mn in _all.duplicate():
		if is_instance_valid(mn) and not mn.gone:
			mn.step(dt)
	_all = _all.filter(func(mn): return is_instance_valid(mn) and not mn.gone)
	_men = _men.filter(func(mn): return is_instance_valid(mn) and not mn.is_dead())
	alive = _men.size()
	_on_you = 0
	for mn in _men:
		if mn.sees:
			_on_you += 1
	if gang_i + 1 < gangs:
		var rate := 1.0
		if hard_man != null and is_instance_valid(hard_man) and not hard_man.is_dead() and "runner" in hard_man.traits:
			rate += Data.RUNNER66_RATE                 # a Messenger: the next gang sooner while he lives
		next_in -= dt * rate
		var push: float = float(world.ctx.get("leg_push", 0.0))
		if push > 0.0:
			next_in += minf(push, Data.LEG66_CAP_S)    # leg shots: the next gang later (the sim's cap)
			world.ctx["leg_push"] = 0.0
		if alive == 0 and gang_i >= 0 and next_in > T.G_QUIET_MAX_S:
			next_in = T.G_QUIET_MAX_S                  # every man down: the next isn't long
		if next_in <= 0.0:
			_arrive(gang_i + 1)
	elif not cleared and alive == 0 and gang_i == gangs - 1:
		cleared = true
		next_in = -1.0
		if world.has_method("on_cleared"):
			world.on_cleared()


## Gang `i` comes in at the edges furthest from the runner: the site's gang size, a hard man on the sim's odds.
func _arrive(i: int) -> void:
	gang_i = i
	var ctx: Dictionary = world.ctx
	var size: int = int(ctx["site"]["gang_sizes"][i])
	next_in = float(ctx["site"]["next_gang_s"]) if i + 1 < gangs else -1.0
	SliceBridge.gang_arrives(world, i)
	var spawns: Array = world.spawn_points()
	var rp: Vector2 = world.runner.global_position if world.runner != null else Vector2.ZERO
	spawns.sort_custom(func(a, b): return a.distance_to(rp) > b.distance_to(rp))
	var ways: Array = spawns.slice(0, mini(2, spawns.size()))
	var r: RandomNumberGenerator = ctx["sim"].fight_rng
	var hard_at := -1
	if int(ctx["site"]["level"]) >= Data.HARD66_LEVEL and (r.randf() < Data.HARD66_ODDS or (T.G_HARD_SURE and not hard_seen and i == gangs - 1)):
		hard_at = size - 1                             # the sim's: he's the gang's last man
	men_by_gang[i] = size
	for k in range(size):
		var hname := ""
		var traits_v: Array = []
		if k == hard_at:
			hname = Words.HARD66_NAMES[r.randi_range(0, Words.HARD66_NAMES.size() - 1)]
			var pool: Array = Data.HARD66_TRAITS.duplicate()
			traits_v.append(pool.pop_at(r.randi_range(0, pool.size() - 1)))
			if r.randf() < Data.HARD66_TWO:
				traits_v.append(pool[r.randi_range(0, pool.size() - 1)])
		var ms: Dictionary = SliceBridge.man_state(ctx, i, hname, traits_v)
		var mn := SliceMan.new()
		var at: Vector2 = ways[k % ways.size()] + Vector2(world.rng.randf_range(-90.0, 90.0), world.rng.randf_range(-90.0, 90.0)) if not ways.is_empty() else rp + Vector2(1200, 0)
		var root: Node = world.men_root if world.get("men_root") != null else self
		root.add_child(mn)
		mn.setup(world, self, ms, at, world.rng.randf() < T.G_FLANK_SHARE)
		_men.append(mn)
		_all.append(mn)
		if hname != "":
			hard_man = mn
			hard_seen = true
			SliceBridge._event(ctx, "hard_man", {"name": hname, "traits": traits_v.duplicate(), "trait_words": traits_v.map(func(x): return str(Words.HARD66_TRAITS.get(x, x)))})
			hard_man_in.emit(mn)
	alive = _men.size()
	gang_arrived.emit(i, size)


## A man down (SliceMan calls it): the gang's count, the hard man gone.
func man_down(mn: Node, _res: Dictionary) -> void:
	var gi: int = int(mn.ms.get("gang", 0))
	men_by_gang[gi] = maxi(0, int(men_by_gang.get(gi, 0)) - 1)
	if mn == hard_man:
		hard_man = null
	if int(men_by_gang[gi]) == 0:
		gang_down.emit(gi)
