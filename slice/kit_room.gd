extends Control
## The game's own Kit room in the slice (round 4, 9 Nov; Matt: "why reinvent the wheel here - i thought we'd just use the
## existing inventory and gear interface from the current runner room during the fight"). Tab, or Back on the pad, holds
## the fight and shows scripts/ui/armoury.gd as the game builds it - the worn slots, the stash grid (the whole camp's
## gear, the slice's copy of it, with this run's finds), the rig, the pick panel, drag and drop, the runner strip - bound
## to the slice's own Sim, never main.sim. While it's open the Sim's run is put by (mission null), so the room's own
## "the runner is out" rule doesn't lock the kit; on close it comes back and the bridge reads the kit again.
##
## Hidden here as making no sense mid-fight: the Kit's "Test on the dummy" (the Runner room's), the loot filter's button,
## and the Workshop's buttons (greyed: the Workshop isn't open while the Kit's up in the slice).

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Armoury := preload("res://scripts/ui/armoury.gd")

signal closed

const HEAD_H := 64.0                   # the room's title over it

var world = null
var room                               # armoury.gd
var _title: Label
var _sub: Label
var back_button: Button
var _held_mission = null               # the slice's run, put by while the room's open
var _held_workshop := false


func _init() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(Pal.BG, 0.96)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_title = UI.label(self, Rect2(0, 0, 400, 40), "The Kit", "Bold", 30, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(self, Rect2(0, 0, 900, 24), "The fight is held · Tab or Back to go back", "Regular", 16, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	back_button = UI.button(self, Rect2(0, 0, 260, 48), true)
	back_button.text = "Back to the fight"
	back_button.pressed.connect(func() -> void: closed.emit())
	room = Armoury.new()
	room.acted.connect(_refresh)
	add_child(room)
	room.test_dummy.visible = false
	visible = false


## The room as the game lays it (1536 x 916) in the middle, its title over it, at any screen size.
func layout(s: Vector2) -> void:
	size = s
	var x: float = roundf((s.x - room.size.x) / 2.0)
	var y: float = maxf(HEAD_H + 8.0, roundf((s.y - room.size.y + HEAD_H) / 2.0))
	room.position = Vector2(x, y)
	_title.position = Vector2(x, y - HEAD_H)
	_sub.position = Vector2(x + 180.0, y - HEAD_H + 10.0)
	back_button.position = Vector2(x + room.size.x - back_button.size.x, y - HEAD_H - 4.0)


func open(w) -> void:
	world = w
	var s = sim()
	_held_mission = s.mission
	s.mission = null                          # the run put by: the room's kit isn't locked "out on a run"
	_held_workshop = s.unlocked.has("workshop")
	s.unlocked.erase("workshop")              # the Workshop's buttons greyed: no bench mid-fight
	s.hp = float(world.runner.hp)
	visible = true
	layout(get_viewport_rect().size if is_inside_tree() else size)
	_refresh()


## Closed: the run back on the Sim, the Workshop as it was; the caller has the bridge read the kit again.
func close() -> void:
	if not visible:
		return
	var s = sim()
	s.mission = _held_mission
	if _held_workshop and not s.unlocked.has("workshop"):
		s.unlocked.append("workshop")
	visible = false


func sim():
	return world.ctx["sim"]


func _refresh() -> void:
	if world == null:
		return
	room.show_state(sim())
	room.test_dummy.visible = false
	room.rules_button.visible = false


func _process(_dt: float) -> void:
	if visible and world != null:
		_refresh()                            # as main.gd's refresh feeds it: a drag's end, a pick


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		closed.emit()


func text_nodes() -> Array:
	return [_title, _sub, back_button] + room.text_nodes()


func line_pairs() -> Array:
	return room.line_pairs()


func room_rect() -> Rect2:
	return Rect2(room.position, room.size)
