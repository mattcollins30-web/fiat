extends Node
## The slice opened from the title (BUILD72): "Try the ARPG slice". It loads the camp's runner (the autosave's, read
## into a Sim of its own - the save file is only read) or, on a fresh camp, the bridge's level-14 Poacher fixture;
## starts the world beside the title's shell (hidden meanwhile); puts the HUD on the world's HUD layer and the pause
## and the end screen over it; and on Back to the title frees it all and shows the title again. Nothing goes back to
## the camp: the slice is a sandbox.
const SliceBridge := preload("res://slice/bridge.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)
const SliceTuning := preload("res://slice/tuning.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)

const HudScript := preload("res://slice/hud.gd")
const PauseScript := preload("res://slice/pause.gd")
const EndScript := preload("res://slice/end_screen.gd")
const KitScript := preload("res://slice/kit_sheet.gd")
const Sim := preload("res://scripts/sim/sim.gd")
const Items := preload("res://scripts/sim/items.gd")

const OVER_LAYER := 20                # the pause and the end over the HUD's layer (10)

var main = null                       # the title's shell (main.gd), hidden while the slice runs
var world = null                      # the slice's world (slice.gd)
var hud = null
var pause = null
var end = null
var kit = null                        # the kit and runner sheet (round 2): Tab or Back
var over: CanvasLayer
var ended := false
var _next_id := 0                     # Items' id counter when the slice opened: put back on the way out (the review)
var _world_mode := Node.PROCESS_MODE_INHERIT     # the world's own, put back on resume


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


## Opens the slice over `main`'s title. `seed_v` fixes the dice (the smoke's); 0 picks one.
static func open(main_v, seed_v := 0, use_camp := true) -> Node:
	var run = load("res://slice/launch.gd").new()
	run.name = "Slice"
	run.main = main_v
	var host: Node = main_v.get_parent() if main_v != null and main_v.get_parent() != null else main_v
	host.add_child(run)
	run.begin(seed_v, use_camp)
	return run


func begin(seed_v: int, use_camp := true) -> void:
	_next_id = Items._next_id
	var camp := camp_for(main) if use_camp else Camp.new()
	var dice: int = seed_v if seed_v != 0 else 1 + int(Time.get_ticks_usec() % 1000003)
	var ctx: Dictionary = SliceBridge.runner_ctx(camp if camp.sim != null else null, dice)
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
	pause.show_mag_x(float(ctx.get("mag_x", SliceTuning.MAG_X)))
	pause.mag_x_changed.connect(set_mag_x)
	kit = KitScript.new()
	over.add_child(kit)
	kit.closed.connect(close_kit)
	end = EndScript.new()
	over.add_child(end)
	end.to_title.connect(back_to_title)
	world.run_ended.connect(_on_ended)


## Tab or Back: the kit sheet, on and off (in _input, ahead of the GUI's own Tab, which moves the focus).
func _input(event: InputEvent) -> void:
	if ended or pause == null or pause.visible or not event.is_action_pressed("slice_kit"):
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()
	if kit.visible:
		close_kit()
	else:
		open_kit()


## The fight held still under the kit sheet (a sandbox: the clock stops too).
func open_kit() -> void:
	_world_mode = world.process_mode
	world.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	kit.open(world)


func close_kit() -> void:
	kit.close()
	world.process_mode = _world_mode


func _unhandled_input(event: InputEvent) -> void:
	var press: bool = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE) \
			or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
	if not press or ended or (kit != null and kit.visible):
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
	end.open(outcome, stats, str(site.get("name", "The car park")))


## The pause's other test setting (round 2): a magazine's size times x, live - the ctx's guns and the runner's.
func set_mag_x(x: float) -> void:
	world.ctx["mag_x"] = x
	for e in world.ctx["guns"]:
		SliceBridge.scaled_gun(e, x)
	world.runner.set_mag_x(x)


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
