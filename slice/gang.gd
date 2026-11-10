extends Node2D
## The gang director (build 72, builder G): three gangs on the gang clock at the park's edges, their men (SliceMan), the
## hard man and his traits, the clear. W makes it (SliceGang.new(), child "Gang") and calls setup(world); it runs the
## bridge's frame (SliceBridge.tick) itself. H reads the clock: gang_i, gangs, next_in, alive, hard_man.
const SliceMan := preload("res://slice/man.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const SliceBridge := preload("res://slice/bridge.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const Hazards := preload("res://slice/hazards.gd")
const SliceRound := preload("res://slice/round.gd")     # (build 76) the rounds in flight, stepped here

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
var seen_ago := 0.0                  # (round 6) seconds since one of the front saw him
var searches := 0                    # ...and the searches sent since
var _search_in := 0.0
var _hold_check := 0.0
var _on_you := 0
var _men: Array = []
var _all: Array = []                 # every man still drawn (the dead fade out)
## (round 4, Matt: "the gangs should come in waves similar to how the fight works at the moment - 3 on you - 3 next etc")
## The sim's fight: a gang's men are a pool, contact(t) of them on you at once, the next stepping up as one falls, the
## hard man the gang's last. Here: `_front` the men engaged (never more than contact), `_queue` the rest in order, held
## at the edge they came in by; a front man down, the next steps up after G_STEP_UP_S.
var _front: Array = []
var _queue: Array = []
var _step_up_ts: Array = []          # (the review) a beat for each gap in the front, counting down to its man stepping up


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


## How many may be on you at once: the sim's contact(t) for the runner and the site.
func contact() -> int:
	return maxi(1, int(world.ctx.get("contact", 3))) if world != null else 3


## (round 4) The men engaged now, "3 on you" (H's line), and those waiting their turn, "4 waiting".
func on_you_count() -> int:
	return _front.filter(func(mn): return is_instance_valid(mn) and not mn.is_dead()).size()     # (the review) not one who fell this frame


func waiting_count() -> int:
	return _queue.size()


func front_men() -> Array:
	return _front.duplicate()


func waiting_men() -> Array:
	return _queue.duplicate()


## Seconds until the next man steps up (-1 none due).
func step_up_in() -> float:
	return _step_up_ts.min() if not _step_up_ts.is_empty() else -1.0


## Fills the front from the queue: `now` all at once (a gang's arrival), else one after the beat.
func _fill_front(dt: float, now := false) -> void:
	_front = _front.filter(func(mn): return is_instance_valid(mn) and not mn.is_dead())
	_queue = _queue.filter(func(mn): return is_instance_valid(mn) and not mn.is_dead())
	while now and _front.size() < contact() and not _queue.is_empty():
		_step_up()
	# (the review) each fallen man his own beat: two down together, two step up together after G_STEP_UP_S
	var due: int = mini(contact() - _front.size(), _queue.size())
	while _step_up_ts.size() < due:
		_step_up_ts.append(T.G_STEP_UP_S)
	_step_up_ts = _step_up_ts.slice(0, maxi(0, due))
	for k in range(_step_up_ts.size()):
		_step_up_ts[k] = float(_step_up_ts[k]) - dt
	while not _step_up_ts.is_empty() and float(_step_up_ts[0]) <= 0.0 and not _queue.is_empty():
		_step_up_ts.pop_front()
		_step_up()


func _step_up() -> void:
	var mn = _queue.pop_front()
	_front.append(mn)
	mn.engage()


## A man at the back found and shot: he's in it; the front man furthest from the runner goes back to wait.
func held_shot(mn: Node) -> void:
	if not (mn in _queue):
		return
	_queue.erase(mn)
	_front = _front.filter(func(f): return is_instance_valid(f) and not f.is_dead())     # (the review) a dead front man is no reason to send a live one back
	if _front.size() >= contact() and not _front.is_empty():
		var rp: Vector2 = world.runner.global_position if world.runner != null else Vector2.ZERO
		var back = _front[0]
		for f in _front:
			if f.global_position.distance_to(rp) > back.global_position.distance_to(rp):
				back = f
		_front.erase(back)
		_queue.push_front(back)
		back.hold(_hold_spot(back))
	_front.append(mn)
	mn.engage()


## Where a waiting man stands: the edge he came in by, held back out of the runner's sight.
func _hold_spot(mn: Node) -> Vector2:
	var way: Vector2 = mn.get_meta("way", mn.global_position)
	var rp: Vector2 = world.runner.global_position if world.runner != null else way
	if world.has_los(way, rp):
		return world.cover_spot(way, rp)              # (round 6) the runner can see the edge he came in by: behind the cover nearest it
	return way


## (round 6) The waiting men stay out of his sight: one he could see moves behind cover.
func _hold_out_of_sight(dt: float) -> void:
	_hold_check -= dt
	if _hold_check > 0.0 or world.runner == null:
		return
	_hold_check = T.G_HOLD_CHECK_S
	var rp: Vector2 = world.runner.global_position
	var taken: Array = []
	for mn in _queue:
		if not is_instance_valid(mn) or mn.is_dead():
			continue
		# his spot is in sight, or another man has it: a place of his own in the cover's shadow
		if world.has_los(mn.target, rp) or taken.any(func(p): return p.distance_to(mn.target) < T.G_HOLD_FILE_PX * 0.8):
			mn.hold(_shadow_spot(_hold_spot(mn), rp, taken))
		taken.append(mn.target)


## A free place out of his sight behind `spot`, in file away from him, that none of `taken` has.
func _shadow_spot(spot: Vector2, rp: Vector2, taken: Array) -> Vector2:
	var dir: Vector2 = (spot - rp).normalized()
	for row in range(T.G_HOLD_FILE):
		for side in [0.0, 1.0, -1.0]:
			var p: Vector2 = spot + dir * T.G_HOLD_FILE_PX * row + dir.orthogonal() * T.G_HOLD_FILE_PX * side * row * 0.5
			if not world.park_rect.grow(-T.MAN_R).has_point(p) or world.resolve_circle(p, T.MAN_R).distance_to(p) > 1.0:
				continue
			if world.has_los(p, rp) or taken.any(func(q): return q.distance_to(p) < T.G_HOLD_FILE_PX * 0.8):
				continue
			return p
	return spot


const SETTLED := ["cover", "lean", "duck"]

## (round 6, board E) Nobody of the front has seen him for a while: the gang has lost him.
func lost_him() -> bool:
	return seen_ago >= T.G_SEARCH_AFTER_S


## The search: the two of the front nearest where they last saw him go and look; the rest hold their cover. Still lost
## after it, the next goes nearer where he is.
func _search(dt: float) -> void:
	var live: Array = _front.filter(func(mn): return is_instance_valid(mn) and not mn.is_dead())
	if live.is_empty():
		return
	if live.any(func(mn): return mn.sees):
		seen_ago = 0.0
		searches = 0
		_search_in = 0.0
		return
	# the clock runs once they are at their cover with nothing to shoot at: men still on their way in haven't lost him
	if live.all(func(mn): return mn.state in SETTLED or str(mn.get("kind")) == "rusher"):     # (round 7's review) a rusher is never at cover: he doesn't hold the clock
		seen_ago += dt
	if not lost_him():
		return
	_search_in -= dt
	if _search_in > 0.0 or live.any(func(mn): return mn.is_searching()):
		return
	if searches > 0 and world.runner != null:
		last_seen = last_seen.move_toward(world.runner.global_position, T.G_SEARCH_CLOSER_PX)
	searches += 1
	_search_in = T.G_SEARCH_AGAIN_S
	var lookers: Array = live.filter(func(mn): return str(mn.get("kind")) != "rusher")     # (round 7's review) a rusher goes himself
	lookers.sort_custom(func(a, b): return a.global_position.distance_to(last_seen) < b.global_position.distance_to(last_seen))
	for k in range(mini(T.G_SEARCHERS, lookers.size())):
		lookers[k].search(last_seen + Vector2(70.0, 0.0).rotated(PI * k))


## The men who may fire this frame (the review: the sim's contact(t), so many on you at once): the nearest of those who
## saw you last frame.
var _firing: Array = []


func _pick_firing() -> void:
	var rp: Vector2 = world.runner.global_position if world.runner != null else Vector2.ZERO
	var seeing: Array = _front.filter(func(mn): return is_instance_valid(mn) and not mn.is_dead() and mn.sees)     # (round 4) only the front fires
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
	_fill_front(dt)
	_search(dt)
	_hold_out_of_sight(dt)
	_pick_firing()
	for mn in _all.duplicate():
		if is_instance_valid(mn) and not mn.gone:
			mn.step(dt)
	SliceRound.layer(world).step(dt)                   # (build 76) the rounds in flight, the runner's and theirs
	Hazards.layer(world).step(dt)                      # (round 7) the bottles on the ground
	_all = _all.filter(func(mn): return is_instance_valid(mn) and not mn.gone)
	_men = _men.filter(func(mn): return is_instance_valid(mn) and not mn.is_dead())
	alive = _men.size()
	_on_you = 0
	for mn in _front:
		if is_instance_valid(mn) and not mn.is_dead() and mn.sees:
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
	if alive == 0:
		last_seen = rp                             # (round 6) a gang into an empty park comes in knowing where he is
		seen_ago = 0.0
		searches = 0
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
		var kd: String = kind_for(i, k, size, hard_at >= 0, bool(ctx.get("kinds_off", false)))
		if kd != "":
			SliceBridge.make_kind(ms, kd)
		var mn := SliceMan.new()
		var at: Vector2 = ways[k % ways.size()] + Vector2(world.rng.randf_range(-90.0, 90.0), world.rng.randf_range(-90.0, 90.0)) if not ways.is_empty() else rp + Vector2(1200, 0)
		var root: Node = world.men_root if world.get("men_root") != null else self
		root.add_child(mn)
		mn.setup(world, self, ms, at, world.rng.randf() < T.G_FLANK_SHARE)
		mn.set_meta("way", at)
		mn.hold(at)                                    # (round 4) every man waits his turn; the front fills below
		_queue.append(mn)
		_men.append(mn)
		_all.append(mn)
		if hname != "":
			hard_man = mn
			hard_seen = true
			SliceBridge._event(ctx, "hard_man", {"name": hname, "traits": traits_v.duplicate(), "trait_words": traits_v.map(func(x): return str(Words.HARD66_TRAITS.get(x, x)))})
			hard_man_in.emit(mn)
	alive = _men.size()
	_fill_front(0.0, true)                             # the gang in: the first `contact` (an older gang's waiting first) step up
	gang_arrived.emit(i, size)


## (round 7, board G) The kind of gang i's man k of `size`: its first men are the gang's kinds (the first to step up:
## the review - as its last they waited at the back till the front fell)
## (SliceTuning.G_MEN_BY_GANG), one plain man kept at least; the hard man (the gang's last) is none of them. `off`: a
## check's plain gang.
static func kind_for(i: int, k: int, size: int, has_hard: bool, off := false) -> String:
	if off or T.G_MEN_BY_GANG.is_empty():
		return ""
	var kinds: Array = T.G_MEN_BY_GANG[clampi(i, 0, T.G_MEN_BY_GANG.size() - 1)]
	var plain: int = size - (1 if has_hard else 0)
	var n: int = mini(kinds.size(), maxi(0, plain - 1))
	if k >= n:
		return ""
	return str(kinds[k])


## A man down (SliceMan calls it): the gang's count, the hard man gone.
func man_down(mn: Node, _res: Dictionary) -> void:
	var gi: int = int(mn.ms.get("gang", 0))
	men_by_gang[gi] = maxi(0, int(men_by_gang.get(gi, 0)) - 1)
	if mn == hard_man:
		hard_man = null
	if int(men_by_gang[gi]) == 0:
		gang_down.emit(gi)
