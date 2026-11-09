extends Node
## The slice's sounds (round 6, board E part 2): the game's own, no new files - scripts/ui/sound.gd's one-shots, cued
## off the world's signals. The shell's sound when the slice was opened from the title (its volumes, its files already
## warm), else one of its own.
const Sound := preload("res://scripts/ui/sound.gd")
const T := preload("res://slice/tuning.gd")

var sound: Node = null                # the game's sound (sound.gd)
var world = null
var _own := false                     # the sound is the slice's own: it goes with the slice
var _guard := 0                       # the runner's Guard at the last look: gone to nothing is its break
var _using := false                   # a med in hand at the last look
var _kill_at := -10.0
var _streak := 0
var _hooked: Array = []               # the men whose fire is heard


func bind(world_v, shell_sound = null) -> void:
	world = world_v
	sound = shell_sound
	if sound == null or not is_instance_valid(sound):
		Sound.ensure_buses()
		sound = Sound.new()
		add_child(sound)
		_own = true
	world.fired.connect(_on_fired)
	world.dry.connect(func(_g): sound.cue("dry_click"))
	world.jammed.connect(func(_g): sound.cue("dry_click"))
	world.reload_started.connect(func(_g, _s): sound.cue("reload"))
	world.runner_hurt.connect(_on_hurt)
	world.man_down.connect(_on_kill)
	world.cleared_park.connect(func(): sound.cue("way_out"))
	if world.gang != null:
		world.gang.gang_arrived.connect(func(_i, _n): sound.cue("gang_arrives"))
	_guard = int(world.runner.guard)


## Your round: the gun's own sound by its type, as the game's fight plays it.
func _on_fired(g: Dictionary) -> void:
	var it = g.get("item", null)
	if it is Dictionary and it.has("base"):
		sound.cue(sound._gun_sound(it))
		return
	var id := "shot_" + str(g.get("type", "improvised"))
	sound.cue(id if Sound.SOUNDS.has(id) else "shot_improvised")


## Theirs: the game's incoming round, from where the man stands across the screen and how near.
func _on_their_shot(man: Node, _hit: bool, _to: Vector2) -> void:
	var off: Vector2 = man.position - world.runner.position
	sound.cue("incoming", 0.08, 1.0, {"pan": clampf(off.x / T.SOUND_PAN_PX, -1.0, 1.0), "near": clampf(1.0 - off.length() / T.SOUND_FAR_PX, 0.0, 1.0)})


func _on_hurt(res: Dictionary) -> void:
	if int(res.get("hp_loss", 0)) <= 0 and int(res.get("guard_loss", 0)) <= 0:
		return
	var broke: bool = _guard > 0 and int(world.runner.guard) <= 0
	_guard = int(world.runner.guard)
	sound.cue("guard_break" if broke else "hit_taken")


## A kill; kills close together climb in pitch, as the game's do.
func _on_kill(_man: Node) -> void:
	var now: float = float(world.time_s)
	_streak = mini(_streak + 1, Sound.STREAK_MAX) if now - _kill_at <= Sound.STREAK_S else 0
	_kill_at = now
	sound.cue("kill", 0.02, 1.0 + Sound.STREAK_STEP * _streak)


func _process(_dt: float) -> void:
	if world == null or not is_instance_valid(world) or sound == null or not is_instance_valid(sound):
		return
	for mn in world.men():
		if not (mn in _hooked) and mn.has_signal("fired_at"):
			_hooked.append(mn)
			mn.fired_at.connect(_on_their_shot)
	var r = world.runner
	_guard = int(r.guard)
	var using: bool = not Dictionary(world.ctx.get("using", {})).is_empty()
	if using and not _using:
		sound.cue("med_use")
	_using = using
	var low: bool = not world.ended and not r.dead and float(r.hp) < float(r.hp_max) * T.SOUND_LOW_HP
	sound.set_loop("low_hp", "low_hp" if low and sound.enabled else "")


func _exit_tree() -> void:
	if sound != null and is_instance_valid(sound) and not _own:
		sound.set_loop("low_hp", "")
