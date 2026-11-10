extends Node2D
## A crate in the car park (build 72): F (or A) held beside it searches it - a ring fills, slower under fire - and
## its finds (the sim's find roll, through the bridge) go into the run's haul.
const SliceWorld := preload("res://slice/slice.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)

const T := preload("res://slice/tuning.gd")
const Art := preload("res://slice/art.gd")
const C_BOX := Color("8a6a3a")
const C_LINE := Color("e0a030")
const C_OPEN := Color("4a4036")
const C_RING := Color("f0c060")

var progress := 0.0                  # 0..1
var opened := false
var near := false                    # the runner is in reach (the prompt shows)
var prompt := ""                     # the world sets it (the keyboard's or the pad's word)
var finds: Array = []
var prize := false                   # (the loop, board I) the place's prize: the far crate, on the map, longer to open, worth more
var body := false                    # (board M) a man put down: searched as a crate is, quicker; he holds what he dropped
var rolled := false                  # ...what's in it has been rolled (finds), once
var found_n := 0                     # ...how many of its finds the search has turned up
var left: Array = []                 # ...and those turned up and not yet taken
var search_t := 0.0
var seen := false                    # (build 76) the runner has seen it: drawn from then on (slice/sight.gd)


## (build 76) The search prompt: 26 px on screen at the camera's zoom.
static func prompt_px() -> int:
	return int(round(26.0 / T.CAM_ZOOM))


func rect() -> Rect2:
	return Rect2(position - Vector2.ONE * T.CRATE_SIZE * 0.5, Vector2.ONE * T.CRATE_SIZE)


## Searched through and nothing left in it.
func done() -> bool:
	return opened and left.is_empty()


func in_reach(p: Vector2) -> bool:
	if done():
		return false
	var r := rect()
	var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	return q.distance_to(p) <= T.SEARCH_RANGE


func _draw() -> void:
	if body:
		_draw_body()
		return
	var h := T.CRATE_SIZE * 0.5
	var r := Rect2(-Vector2.ONE * h, Vector2.ONE * T.CRATE_SIZE)
	draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.3))
	var box := Art.used(Art.CRATE)     # (round 3) the pack's crate, the amber line kept
	if box["tex"] != null:
		draw_texture_rect_region(box["tex"], r, box["src"], Color(0.45, 0.42, 0.4) if opened else Color.WHITE)
	else:
		draw_rect(r, C_OPEN if opened else C_BOX)
	draw_rect(r, Color(C_LINE, 0.4) if opened else C_LINE, false, 4.0)
	if prize and not opened:
		draw_rect(r.grow(10.0), C_RING, false, 5.0)     # the prize: a second, wider line
	if opened:
		draw_line(r.position, r.end, Color(C_LINE, 0.3), 3.0)
		draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), Color(C_LINE, 0.3), 3.0)
		return
	if progress > 0.0:
		draw_arc(Vector2.ZERO, h + 18.0, -PI / 2.0, -PI / 2.0 + TAU * progress, 48, C_RING, 7.0)
	if near:
		var f: Font = (get_parent().get_parent() as SliceWorld).font()
		var fs := prompt_px()
		var w := f.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(-w * 0.5, -h - 40.0), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, C_LINE)


## (board M) A man put down: a dark shape where he fell, an amber line till he's been searched and emptied.
func _draw_body() -> void:
	var gone: bool = done()
	draw_set_transform(Vector2.ZERO, 0.5, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, 38.0, Color(0.09, 0.07, 0.06, 0.55 if gone else 0.85))
	draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 32, Color(C_LINE, 0.15 if gone else 0.75), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if near and not gone:
		var f: Font = (get_parent().get_parent() as SliceWorld).font()
		var fs := prompt_px()
		var w := f.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(-w * 0.5, -56.0), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, C_LINE)
