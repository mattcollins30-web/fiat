extends Control
## The Map's placement tool (5 Nov, BUILD52; Matt: "can you do an f3/f5 piece for the places? some of the ones you've
## selected I'd want to move" - the fight's F3/F5, fight_placement.gd, on the Map). Debug builds only; an export never
## has it.
##
## F3 on the Map: every place shows, each outlined with its name - the twelve sites, the order's three, the town's six
## (shut or not, built or not) and the four zones' names. Drag one with the left button to move it; the right button
## drags the land (the left one's the tool's while placing), the wheel scrolls it. The line at the top names what's
## under the mouse, or what's being dragged, and where in the painting's pixels. F5 saves every place to
## data/map_places.tres (the zones' shapes and anything else there kept) and the Map reads it from then on; F4 prints
## them; F3 again ends it. Nothing here changes a number or the save.

const LINE := Color(1.0, 1.0, 0.2, 0.9)
const DRAGGED := Color(0.3, 1.0, 0.4, 0.95)
const TEXT := Color(1, 1, 1, 1)
const GRAB_R := 16.0                      # a pin's grab, on the land
const NAME_BOX := Vector2(170, 32)        # a zone's name's grab, from its top left
const TOP_H := 40.0
const TOP_LINE := "PLACING · drag a place to move it · F5 save · F4 print · F3 done"

var view                                  # the Map (map_view.gd) this sits on, or the County (county.gd; BUILD61-U)
var save_path: String = "res://data/map_places.tres"     # the tests point it elsewhere; the County's data/county_places.tres
var _drag := -1                           # an index into view.all_places()
var _hover := -1
var _start_mouse := Vector2.ZERO
var _start_at := Vector2.ZERO             # the dragged place's point, painting pixels
var _panning := false
var _pan_from := Vector2.ZERO             # the right button's press, in the frame's space
var _pan_off := Vector2.ZERO
var _note := ""                           # the last thing F5 or F4 said, shown till the next
static var in_debug: bool = OS.is_debug_build()     # the gate: an export never has the tool (the tests turn it off to see)


func _init() -> void:                     # in _init, not _ready: the smoke's Map is never in the tree
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	z_as_relative = false
	z_index = 100                          # over the Map's names, the key and the cloud
	set_process(false)
	if not in_debug:
		set_process_unhandled_input(false)


func _unhandled_input(event: InputEvent) -> void:
	if not in_debug or not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_F3 and (view.placing or view.can_place()):
		toggle()
		_handled()
	elif view.placing and event.keycode == KEY_F5:
		save()
		_handled()
	elif view.placing and event.keycode == KEY_F4:
		_note = dump()
		print(_note)
		_handled()


func _handled() -> void:
	if get_viewport() != null:             # the tests send the keys to a Map that isn't in the tree
		get_viewport().set_input_as_handled()


## The Map put away (another room, the County) while placing: the tool lets go, as the fight's does.
func _process(_dt: float) -> void:
	if view != null and view.placing and not view.on_screen():
		toggle()


## (BUILD61-U) The land the places sit on: the Map is its own land; the County hands its painting's layer (land()).
func _land() -> Control:
	return view.land() if view.has_method("land") else view


func toggle() -> void:
	view.set_placing(not view.placing)
	visible = view.placing
	mouse_filter = Control.MOUSE_FILTER_STOP if view.placing else Control.MOUSE_FILTER_IGNORE
	size = _land().size
	_drag = -1
	_hover = -1
	_panning = false
	_note = ""
	set_process(view.placing)
	if visible:
		move_to_front()
	queue_redraw()


## A place's point on the land, and what grabs it.
func at_of(k: int) -> Vector2:
	var e: Array = view.all_places()[k]
	return view._px(view.place_of(e[0], e[1]))


func grab_of(k: int) -> Rect2:
	var p := at_of(k)
	if view.all_places()[k][0] == "zone_names":
		return Rect2(p, NAME_BOX)
	return Rect2(p - Vector2(GRAB_R, GRAB_R), Vector2(2 * GRAB_R, 2 * GRAB_R))


## The place under a land point: the nearest pin within its grab, else a zone's name.
func hit(p: Vector2) -> int:
	var best := -1
	var best_d := INF
	var all: Array = view.all_places()
	for k in range(all.size()):
		if all[k][0] == "zone_names":
			continue
		var d: float = p.distance_to(at_of(k))
		if d <= GRAB_R and d < best_d:
			best = k
			best_d = d
	if best >= 0:
		return best
	for k in range(all.size()):
		if all[k][0] == "zone_names" and grab_of(k).has_point(p):
			return k
	return -1


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
			view.pan.input(mb)                 # the wheel scrolls the land as ever
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_panning = mb.pressed
			_pan_from = mb.position + _land().position
			_pan_off = view.pan.offset()
			accept_event()
			return
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			press(mb.position)
		else:
			release()
		accept_event()
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if _panning and (mm.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
			view.pan.pan_to(_pan_off - (mm.position + _land().position - _pan_from))
		elif _drag >= 0:
			move(mm.position)
		else:
			_hover = hit(mm.position)
		accept_event()
		queue_redraw()


## The mouse down on the land: grab the place under it.
func press(p: Vector2) -> void:
	_drag = hit(p)
	if _drag < 0:
		return
	var e: Array = view.all_places()[_drag]
	_start_mouse = p
	_start_at = view.place_of(e[0], e[1])


## A drag: the place follows the mouse, in whole painting pixels.
func move(p: Vector2) -> void:
	if _drag < 0:
		return
	var e: Array = view.all_places()[_drag]
	view.set_place(e[0], e[1], (_start_at + (p - _start_mouse) / view.PX).round())
	queue_redraw()


func release() -> void:
	if _drag >= 0:
		print(_where(_drag))
	_drag = -1
	queue_redraw()


func _where(k: int) -> String:
	var e: Array = view.all_places()[k]
	var p: Vector2 = view.place_of(e[0], e[1])
	return "%s (%s %s): (%d, %d)" % [e[2], e[0], e[1], p.x, p.y]


## F5: every place into the file (its zones' shapes and anything else there kept, in the file's own painting size), and
## the Map reading it from now on.
func save() -> int:
	var res: Resource = null
	if ResourceLoader.exists(save_path):
		res = ResourceLoader.load(save_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res != null and not (res.get("zones") is Dictionary):
		res = null                             # not a places file: a fresh one in its place
	if res == null:
		res = load("res://scripts/ui/map_places.gd").new()
		res.paint_size = view.paint_size()
	if res.paint_size.x <= 0.0 or res.paint_size.y <= 0.0:
		res.paint_size = view.paint_size()
	var k: Vector2 = res.paint_size / view.paint_size()
	var rows: Dictionary = {}
	for e in view.all_places():
		if not rows.has(e[0]):
			var had = res.get(e[0])
			rows[e[0]] = Dictionary(had if had is Dictionary else {}).duplicate()     # a field missing: started empty
		rows[e[0]][e[1]] = (view.place_of(e[0], e[1]) * k).round()
	for kind in rows:
		res.set(kind, rows[kind])
	if not DirAccess.dir_exists_absolute(save_path.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	var err := ResourceSaver.save(res, save_path)
	if err == OK:
		view.use_places(res)
		view.relay()
	_note = ("Saved %d places to %s" % [view.all_places().size(), save_path]) if err == OK else ("Couldn't save (%d)" % err)
	print(_note)
	queue_redraw()
	return err


## F4: every place, in the painting's pixels.
func dump() -> String:
	var out: Array = ["The Map's places (painting px):"]
	for k in range(view.all_places().size()):
		out.append("  " + _where(k))
	return "\n".join(out)


## The tool's line's top left on the land: the view's top, below what the room lays over it (the town's goal line).
func line_at() -> Vector2:
	var clear: float = float(view.top_clear.call()) if view.top_clear.is_valid() else 0.0
	return view.pan.offset() + Vector2(0, clear)


func _draw() -> void:
	if not visible:
		return
	var f := ThemeDB.fallback_font
	var all: Array = view.all_places()
	for k in range(all.size()):
		var c: Color = DRAGGED if k == _drag else LINE
		var g := grab_of(k)
		if all[k][0] == "zone_names":
			draw_rect(g, c, false, 2.0)
			draw_string(f, g.position + Vector2(3, -4), "zone", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, c)
		else:
			draw_rect(g, c, false, 2.0)
			draw_circle(at_of(k), 2.5, c)
			draw_string(f, g.position + Vector2(0, -4), str(all[k][2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, c)
	var o: Vector2 = line_at()               # the line on the view's top, clear of the goal line, wherever the land's panned
	draw_rect(Rect2(o, Vector2(view.pan.view.x, TOP_H)), Color(0, 0, 0, 0.78))
	draw_string(f, o + Vector2(8, 16), TOP_LINE, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TEXT)
	var k2: int = _drag if _drag >= 0 else _hover
	var under: String = _where(k2) if k2 >= 0 else _note
	draw_string(f, o + Vector2(8, 33), under, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.95, 0.5))
