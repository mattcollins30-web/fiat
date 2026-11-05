extends RefCounted
## A map's pan (BUILD51-U, item 2; Matt: "lets redraw the map at a larger resolution and make it scrollable"): the land
## (a Control twice today's map each way) inside its frame (the clipping Control it's a child of), moved by a drag with
## the left button or by the wheel (shift for across), clamped to the land's edges, no zoom. The Map (map_view.gd) and
## the County (county.gd) each keep one. `moved` is called after every move (the layers that stay on screen follow).

const DRAG_PX := 6.0                   # a press that moves this far is a pan, not a click
const WHEEL_PX := 90.0                 # a wheel notch

var land: Control
var view := Vector2.ZERO               # the frame's size: what shows of the land
var moved := Callable()
var _down := false
var _dragged := false
var _from := Vector2.ZERO              # the press, in the frame's space
var _off_from := Vector2.ZERO


func _init(l: Control, v: Vector2) -> void:
	land = l
	view = v


## Where the view's top left sits on the land.
func offset() -> Vector2:
	return -land.position


func max_offset() -> Vector2:
	return Vector2(maxf(0.0, land.size.x - view.x), maxf(0.0, land.size.y - view.y))


func pan_to(off: Vector2) -> void:
	var mo: Vector2 = max_offset()
	land.position = -Vector2(clampf(off.x, 0.0, mo.x), clampf(off.y, 0.0, mo.y))
	if moved.is_valid():
		moved.call()


## A point of the land at the view's middle, as near as the edges allow.
func centre_on(p: Vector2) -> void:
	pan_to(p - view / 2.0)


## The frame's size changed (the side panel on or off): the view clamped to it again.
func set_view(v: Vector2) -> void:
	view = v
	pan_to(offset())


## A land point is in the view (with `margin` of room).
func shows(p: Vector2, margin := 0.0) -> bool:
	return Rect2(offset(), view).grow(-margin).has_point(p)


## The land's input: "press" (the left button down - the caller picks under it), "click" (let go without a drag),
## "pan" (a drag or the wheel moved it), or "".
func input(ev: InputEvent) -> String:
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev
		if mb.pressed and mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
			var d := WHEEL_PX * maxf(1.0, mb.factor if mb.factor > 0.0 else 1.0)
			var across: bool = mb.shift_pressed or mb.button_index in [MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]
			var sgn: float = -1.0 if mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT] else 1.0
			pan_to(offset() + (Vector2(sgn * d, 0.0) if across else Vector2(0.0, sgn * d)))
			return "pan"
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return ""
		if mb.pressed:
			_down = true
			_dragged = false
			_from = mb.position + land.position
			_off_from = offset()
			return "press"
		var was: bool = _down and not _dragged
		_down = false
		return "click" if was else ""
	if ev is InputEventMouseMotion and _down:
		var mm: InputEventMouseMotion = ev
		if (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_down = false                  # let go off the land
			return ""
		var now: Vector2 = mm.position + land.position
		if not _dragged and now.distance_to(_from) < DRAG_PX:
			return ""
		_dragged = true
		pan_to(_off_from - (now - _from))
		return "pan"
	return ""
