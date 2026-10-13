extends Control
## The fight's placement tool (13 Oct, Matt: "each enemy a zone I can drag and drop into position and then F5 to save" -
## Greenhorn's hotspot_placement_overlay.gd, cut to what the run view needs). Debug builds only; an export never has it.
##
## F3 on the run screen, on a site with its own art: the fight holds still (the sim stops), all three of the gang stand
## where their slots are, each outlined with its name - middle, near, far. Drag one to move its feet; drag its
## bottom-right corner, or turn the mouse wheel over it, to size it (its feet stay put). The corner of the screen names
## what's under the mouse, or what's being dragged and where. F5 saves this site's three to data/fight_slots.tres;
## F4 prints them; F3 again lets the fight go on. Nothing here changes a number.

const NAMES := ["middle", "near", "far"]
const HANDLE := 12.0
const LINE := Color(1.0, 1.0, 0.2, 0.9)
const DRAGGED := Color(0.3, 1.0, 0.4, 0.95)
const TEXT := Color(1, 1, 1, 1)

var view                                  # the run view this sits on
var save_path: String = "res://data/fight_slots.tres"     # the tests point it elsewhere
var _drag := -1
var _mode := ""                           # "move" / "size"
var _start_mouse := Vector2.ZERO
var _start_foot := Vector2.ZERO
var _start_scale := 1.0
var _start_h := 1.0
var _note := ""                           # the last thing F5 or F4 said, shown till the next
var _hover := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	z_as_relative = false
	z_index = 100                          # over the run screen's bars and chips laid on the frame
	if not OS.is_debug_build():
		set_process_unhandled_input(false)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_F3 and (view.placing or view.can_place()):
		toggle()
		get_viewport().set_input_as_handled()
	elif view.placing and event.keycode == KEY_F5:
		save()
		get_viewport().set_input_as_handled()
	elif view.placing and event.keycode == KEY_F4:
		_note = dump()
		print(_note)
		get_viewport().set_input_as_handled()


func toggle() -> void:
	view.set_placing(not view.placing)
	visible = view.placing
	mouse_filter = Control.MOUSE_FILTER_STOP if view.placing else Control.MOUSE_FILTER_IGNORE
	size = view.size
	_drag = -1
	_note = ""
	if visible:
		move_to_front()
	queue_redraw()


## A figure's drawn rect in the frame's space (what the mouse grabs), from its slot as it's being edited.
func rect_of(k: int) -> Rect2:
	var r: TextureRect = view._figs[k]["rect"]
	var u: Rect2 = view.used_of(r.texture)
	if u.size.y <= 0.0:
		u = Rect2(Vector2.ZERO, Vector2(128, 192))
	var s: Dictionary = view.slot_of(k)
	var top_left: Vector2 = s["foot"] - Vector2(u.get_center().x, u.end.y) * s["scale"]
	return Rect2(top_left + u.position * s["scale"], u.size * s["scale"])


func _hit(p: Vector2) -> int:
	for k in [1, 0, 2]:                    # the near one's in front, the far one behind
		if rect_of(k).grow(2.0).has_point(p):
			return k
	return -1


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and mb.pressed:
			var k := _hit(mb.position)
			if k >= 0:
				var s: Dictionary = view.slot_of(k)
				view.set_slot(k, s["foot"], s["scale"] * (1.02 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.02))
			accept_event()
			queue_redraw()
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
		if _drag >= 0:
			move(mm.position)
		else:
			_hover = _hit(mm.position)
		queue_redraw()


## The mouse down: grab the one under it, by its corner to size it, anywhere else to move it.
func press(p: Vector2) -> void:
	_drag = _hit(p)
	if _drag < 0:
		return
	var r := rect_of(_drag)
	var s: Dictionary = view.slot_of(_drag)
	_mode = "size" if p.distance_to(r.end) <= HANDLE else "move"
	_start_mouse = p
	_start_foot = s["foot"]
	_start_scale = s["scale"]
	_start_h = maxf(1.0, r.size.y)


func move(p: Vector2) -> void:
	if _drag < 0:
		return
	var d: Vector2 = p - _start_mouse
	if _mode == "move":
		view.set_slot(_drag, (_start_foot + d).round(), _start_scale)
	else:
		view.set_slot(_drag, _start_foot, clampf(_start_scale * (_start_h + d.y) / _start_h, 0.08, 1.6))     # taller from the corner, the feet kept


func release() -> void:
	if _drag >= 0:
		var s: Dictionary = view.slot_of(_drag)
		print("%s, %s: foot (%d, %d), scale %.3f" % [view._site_key, NAMES[_drag], s["foot"].x, s["foot"].y, s["scale"]])
	_drag = -1


## F5: this site's three into the file (the others there kept), and the view reading from it from now on.
func save() -> int:
	var res: Resource = load(save_path) if ResourceLoader.exists(save_path) else null
	if res == null:
		res = load("res://scripts/ui/fight_slots.gd").new()
	var rows: Array = []
	for k in range(3):
		var s: Dictionary = view.slot_of(k)
		rows.append([s["foot"].x, s["foot"].y, snappedf(s["scale"], 0.001)])
	var all: Dictionary = res.sites.duplicate(true)
	all[view._site_key] = rows
	res.sites = all
	if not DirAccess.dir_exists_absolute(save_path.get_base_dir()):
		DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	var err := ResourceSaver.save(res, save_path)
	view.use_saved(res.sites)
	_note = ("Saved %s's three to %s" % [view._site_key, save_path]) if err == OK else ("Couldn't save (%d)" % err)
	print(_note)
	queue_redraw()
	return err


func dump() -> String:
	var out := "%s:" % view._site_key
	for k in range(3):
		var s: Dictionary = view.slot_of(k)
		out += "  %s (%d, %d) %.3f" % [NAMES[k], s["foot"].x, s["foot"].y, s["scale"]]
	return out


func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.0))
	for k in range(3):
		var r := rect_of(k)
		var c: Color = DRAGGED if k == _drag else LINE
		draw_rect(r, c, false, 2.0)
		draw_rect(Rect2(r.end - Vector2(HANDLE, HANDLE), Vector2(HANDLE, HANDLE)), c, true)
		draw_string(ThemeDB.fallback_font, r.position + Vector2(3, 13), NAMES[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, c)
		var s: Dictionary = view.slot_of(k)
		draw_circle(s["foot"], 3.0, c)        # the feet: what the slot is
	var line := "PLACING · %s · drag to move, corner or wheel to size · F5 save · F4 print · F3 done" % view._site_key
	draw_rect(Rect2(0, 0, size.x, 40), Color(0, 0, 0, 0.78))     # its words at the frame's top, over the bars
	draw_string(ThemeDB.fallback_font, Vector2(8, 16), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TEXT)
	var k2: int = _drag if _drag >= 0 else _hover
	var under := ""
	if k2 >= 0:
		var s2: Dictionary = view.slot_of(k2)
		under = "%s: foot (%d, %d), scale %.3f" % [NAMES[k2], s2["foot"].x, s2["foot"].y, s2["scale"]]
	draw_string(ThemeDB.fallback_font, Vector2(8, 33), _note if _note != "" and k2 < 0 else under, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.95, 0.5))
