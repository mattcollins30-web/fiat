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


func rect() -> Rect2:
	return Rect2(position - Vector2.ONE * T.CRATE_SIZE * 0.5, Vector2.ONE * T.CRATE_SIZE)


func in_reach(p: Vector2) -> bool:
	if opened:
		return false
	var r := rect()
	var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	return q.distance_to(p) <= T.SEARCH_RANGE


func _draw() -> void:
	var h := T.CRATE_SIZE * 0.5
	var r := Rect2(-Vector2.ONE * h, Vector2.ONE * T.CRATE_SIZE)
	draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.3))
	var box := Art.used(Art.CRATE)     # (round 3) the pack's crate, the amber line kept
	if box["tex"] != null:
		draw_texture_rect_region(box["tex"], r, box["src"], Color(0.45, 0.42, 0.4) if opened else Color.WHITE)
	else:
		draw_rect(r, C_OPEN if opened else C_BOX)
	draw_rect(r, Color(C_LINE, 0.4) if opened else C_LINE, false, 4.0)
	if opened:
		draw_line(r.position, r.end, Color(C_LINE, 0.3), 3.0)
		draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), Color(C_LINE, 0.3), 3.0)
		return
	if progress > 0.0:
		draw_arc(Vector2.ZERO, h + 18.0, -PI / 2.0, -PI / 2.0 + TAU * progress, 48, C_RING, 7.0)
	if near:
		var f: Font = (get_parent().get_parent() as SliceWorld).font()
		var fs := 26
		var w := f.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(-w * 0.5, -h - 40.0), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, C_LINE)
