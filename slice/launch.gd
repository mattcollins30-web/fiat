extends Node
## The slice opened from the title (BUILD72): "Try the ARPG slice". It loads the camp's runner (the autosave's, read
## into a Sim of its own - the save file is only read) or, with no runner or one too far under the level picked, the
## bridge's test Poacher (10 Nov: two levels over the car park, in kit rolled for his level);
## starts the world beside the title's shell (hidden meanwhile); puts the HUD on the world's HUD layer and the pause
## and the end screen over it; and on Back to the title frees it all and shows the title again. Nothing goes back to
## the camp: the slice is a sandbox.
const SliceBridge := preload("res://slice/bridge.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const SliceTuning := preload("res://slice/tuning.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)

const HudScript := preload("res://slice/hud.gd")
const PauseScript := preload("res://slice/pause.gd")
const EndScript := preload("res://slice/end_screen.gd")
const KitScript := preload("res://slice/kit_room.gd")     # (round 4) the game's own Kit room, on the slice's Sim
const SoundsScript := preload("res://slice/sounds.gd") # (round 6) the game's own sounds off the world's signals
const PickScript := preload("res://slice/level_pick.gd")  # (build 76) the level picker before the fight
const RunLog := preload("res://slice/run_log.gd")        # (10 Nov) a line a run ended, for the read after a play
const Sim := preload("res://scripts/sim/sim.gd")
const Items := preload("res://scripts/sim/items.gd")

const OVER_LAYER := 20                # the pause and the end over the HUD's layer (10)

var main = null                       # the title's shell (main.gd), hidden while the slice runs
var world = null                      # the slice's world (slice.gd)
var hud = null
var pause = null
var end = null
var sounds = null                     # (round 6) the fight's sounds
var kit = null                        # the Kit room (round 4): Tab or Back
var over: CanvasLayer
var ended := false
var _next_id := 0                     # Items' id counter when the slice opened: put back on the way out (the review)
var _world_mode := Node.PROCESS_MODE_INHERIT     # the world's own, put back on resume
var picker = null                     # (build 76) the level picker, up from the title until a level's picked
var site_level := 0                   # the car park's level, as picked (or the default)
var _camp: Camp = null
var _dice := 0


## A holder for the bridge's runner_ctx: anything with a `sim` (the bridge reads main.sim; at the title the camp
## isn't loaded, so the autosave is read into one of these).
class Camp extends RefCounted:
	var sim = null


## The camp's runner as a Sim of the slice's own: the shell's live one copied, else the autosave read, else null (the
## bridge's fixture then). Never the shell's own object, never written back.
static func camp_for(main_v) -> Camp:
	var c := Camp.new()
	if main_v == null:
		return c
	var d := {}
	if main_v.sim != null:
		d = {"sim": main_v.sim.to_dict()}
	elif main_v.has_method("_read_save") and FileAccess.file_exists(main_v.save_file):
		d = main_v._read_save(main_v.save_file)
		if not main_v._save_ok(d):
			d = {}
	if d.is_empty():
		return c
	var s = Sim.new()
	s.load_dict(JSON.parse_string(JSON.stringify(d["sim"])))     # a deep copy through text, as a save is
	if str(s.cls) == "" or s.camp_lost:
		return c
	c.sim = s
	return c


## Opens the slice over `main`'s title. `seed_v` fixes the dice (the smoke's); 0 picks one. `pick` (build 76): 0 - the
## title's (no seed) shows the level picker, a fixed seed starts at the default level; above 0 starts at that level;
## -1 shows the picker whatever the seed.
static func open(main_v, seed_v := 0, use_camp := true, pick := 0) -> Node:
	var run = load("res://slice/launch.gd").new()
	run.name = "Slice"
	run.main = main_v
	var host: Node = main_v.get_parent() if main_v != null and main_v.get_parent() != null else main_v
	host.add_child(run)
	run.begin(seed_v, use_camp, pick)
	return run


func begin(seed_v: int, use_camp := true, pick := 0) -> void:
	_next_id = Items._next_id
	_camp = camp_for(main) if use_camp else Camp.new()
	_dice = seed_v if seed_v != 0 else 1 + int(Time.get_ticks_usec() % 1000003)
	var def: int = PickScript.default_for(_camp.sim)
	if pick < 0 or (pick == 0 and seed_v == 0):
		show_picker(def)
		return
	start(pick if pick > 0 else def)


## The level picker over the title (build 76): a level's button starts the fight there.
func show_picker(def: int) -> void:
	over = CanvasLayer.new()
	over.layer = OVER_LAYER
	over.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(over)
	picker = PickScript.new()
	var fresh: bool = PickScript.is_fresh(_camp.sim)
	picker.setup(def, "Poacher" if _camp.sim == null else str(_camp.sim.cls), SliceBridge.FIXTURE_LEVEL if _camp.sim == null else int(_camp.sim.level()), fresh, _camp.sim != null)
	over.add_child(picker)
	picker.picked.connect(start)
	picker.to_title.connect(back_to_title)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## The fight at the car park's level `lv`: the world, the HUD, the pause, the Kit room and the end over it.
func start(lv: int) -> void:
	site_level = lv
	if picker != null:
		picker.queue_free()
		picker = null
	var camp := _camp
	var dice := _dice
	var ctx: Dictionary = SliceBridge.runner_ctx(camp if camp.sim != null else null, dice, lv)
	ctx["their_dmg_x"] = SliceTuning.THEIR_DMG_X
	if main != null:
		if main.get("_menu") != null:
			main._menu.close()
		main.visible = false
	world = load("res://slice/slice.tscn").instantiate()
	add_child(world)
	world.start(ctx, dice)
	hud = HudScript.new()
	world.hud_layer.add_child(hud)
	hud.bind(world)
	sounds = SoundsScript.new()
	add_child(sounds)
	sounds.bind(world, main._sound if main != null and main.get("_sound") != null else null)
	if over == null:
		over = CanvasLayer.new()
		over.layer = OVER_LAYER
		over.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(over)
	pause = PauseScript.new()
	over.add_child(pause)
	pause.resumed.connect(_resume)
	pause.to_title.connect(back_to_title)
	pause.show_hp_x(float(ctx.get("man_hp_x", SliceTuning.MAN_HP_X)))
	pause.hp_x_changed.connect(set_hp_x)
	pause.show_dmg_x(float(ctx.get("their_dmg_x", SliceTuning.THEIR_DMG_X)))
	pause.dmg_x_changed.connect(set_dmg_x)
	kit = KitScript.new()
	over.add_child(kit)
	kit.closed.connect(close_kit)
	end = EndScript.new()
	over.add_child(end)
	end.to_title.connect(back_to_title)
	world.run_ended.connect(_on_ended)


## Tab or Back: the Kit room, on and off (in _input, ahead of the GUI's own Tab, which moves the focus).
func _input(event: InputEvent) -> void:
	if ended or pause == null or kit == null or pause.visible or not event.is_action_pressed("slice_kit"):
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()
	if kit.visible:
		close_kit()
	else:
		open_kit()


## (round 6) The mouse's arrow gives way to the crosshair while the fight runs; held, in the Kit room or ended it's back.
func _process(_dt: float) -> void:
	if world == null or ended or not is_instance_valid(world):
		return
	var live: bool = world.process_mode != Node.PROCESS_MODE_DISABLED and world.runner.aim_mode != "pad"
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if live else Input.MOUSE_MODE_VISIBLE


## The fight held still under the Kit room (a sandbox: the clock stops too).
func open_kit() -> void:
	_world_mode = world.process_mode
	world.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	kit.open(world)


func close_kit() -> void:
	kit.close()
	SliceBridge.kit_changed(world.ctx)        # (round 4) whatever was worn, taken or left: the guns, meds, maxima, pace read again
	world.runner.kit_changed(world.ctx)
	world.process_mode = _world_mode


func _unhandled_input(event: InputEvent) -> void:
	var press: bool = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE) \
			or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
	if not press or ended or pause == null or (kit != null and kit.visible):
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()
	if pause.visible:
		_resume()
	else:
		hold()


## The world held still under the pause.
func hold() -> void:
	_world_mode = world.process_mode
	world.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pause.open()


func _resume() -> void:
	pause.close()
	world.process_mode = _world_mode


func _on_ended(outcome: String, stats: Dictionary) -> void:
	ended = true
	world.process_mode = Node.PROCESS_MODE_DISABLED
	pause.close()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var site: Dictionary = world.ctx.get("site", {}) if world.ctx.get("site") is Dictionary else {}
	var game: Dictionary = SliceBridge.game_fight(world.ctx)
	end.open(outcome, stats, str(site.get("name", "The car park")), game)
	RunLog.write(RunLog.entry(world, outcome, stats, game))


## The pause's other test setting (build 76, the magazine's gone): their damage a round times x, live - the bridge
## reads ctx["their_dmg_x"] each round they fire.
func set_dmg_x(x: float) -> void:
	world.ctx["their_dmg_x"] = x


## The pause's test setting: the men's HP times x from now - the men standing scaled to it, their share of HP kept.
func set_hp_x(x: float) -> void:
	var was: float = float(world.ctx.get("man_hp_x", SliceTuning.MAN_HP_X))
	world.ctx["man_hp_x"] = x
	if was <= 0.0:
		return
	var men: Array = world.gang.live_men() if world.gang != null and world.gang.has_method("live_men") else world.men()
	for m in men:
		var ms: Dictionary = m.state_data()
		ms["hp"] = float(ms["hp"]) * x / was
		ms["hp_max"] = float(ms["hp_max"]) * x / was


## Everything the slice made goes; the title comes back as it was.
func back_to_title() -> void:
	Items._next_id = _next_id               # the slice's rolls leave the camp's item numbers where they were
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if main != null and is_instance_valid(main):
		main.visible = true
		main.show_title()
	queue_free()
