extends Node2D
## The slice's quick marks (build 72): tracers, the muzzle flash, a man's white flash when hit, a spark on cover,
## and the way out's prompt. Everything fades in a tenth of a second or so; the world steps it.
const SliceWorld := preload("res://slice/slice.gd")     # (no class_name: Matt's headless smoke has no editor scan to know one)

const T := preload("res://slice/tuning.gd")
const C_TRACER := Color("f0c060")
const C_FLASH := Color("fff2c0")
const C_SPARK := Color("c9b48a")
const C_EXIT := Color("3fae7a")

var marks: Array = []                # {kind, a, b, node, t, life}
var exit_prompt := ""                # the world sets it while the runner stands in the way out
var exit_at := Vector2.ZERO
var reticle := Vector2.INF          # the pad's aim point (the mouse has its own cursor); INF hides it
var reticle_locked := false
var cross := Vector2.INF            # (round 6) the crosshair at the aim, mouse or pad: four ticks, their gap the spread there
var cross_r := 0.0


func tracer(a: Vector2, b: Vector2) -> void:
	marks.append({"kind": "tracer", "a": a, "b": b, "t": T.TRACER_S, "life": T.TRACER_S})
	marks.append({"kind": "flash", "a": a, "t": T.FLASH_S, "life": T.FLASH_S})
	queue_redraw()


func hit_flash(man: Node2D) -> void:
	if not man.visible:                # (round 5's review) a man the fog hides: no flash to give him away
		return
	marks.append({"kind": "hit", "node": man, "a": man.position, "t": T.HIT_FLASH_S, "life": T.HIT_FLASH_S})
	queue_redraw()


func spark(p: Vector2) -> void:
	marks.append({"kind": "spark", "a": p, "t": T.SPARK_S, "life": T.SPARK_S})
	queue_redraw()


func step(dt: float) -> void:
	for m in marks:
		m["t"] -= dt
	marks = marks.filter(func(m): return m["t"] > 0.0)
	queue_redraw()


func _draw() -> void:
	for m in marks:
		var k: float = clampf(float(m["t"]) / float(m["life"]), 0.0, 1.0)
		match str(m["kind"]):
			"tracer":
				draw_line(m["a"], m["b"], Color(C_TRACER, 0.85 * k), 3.0 / T.CAM_ZOOM)
			"flash":
				draw_circle(m["a"], 16.0 * k + 6.0, Color(C_FLASH, k))
			"hit":
				var n = m["node"]
				if is_instance_valid(n) and not n.visible:
					continue                         # (build 76) a man the fog hides doesn't flash
				var p: Vector2 = n.position if is_instance_valid(n) else m["a"]
				var r: float = float(n.get("radius")) if is_instance_valid(n) and n.get("radius") != null else T.MAN_R
				draw_circle(p, r, Color(1, 1, 1, 0.75 * k))
			"spark":
				for i in range(5):
					var d := Vector2.RIGHT.rotated(i * TAU / 5.0) * (1.0 - k) * 26.0
					draw_circle(m["a"] + d, 3.5, Color(C_SPARK, k))
	if reticle != Vector2.INF and reticle_locked:     # (round 6) the crosshair marks the aim; the ring is the pad's lock
		draw_arc(reticle, 22.0 / T.CAM_ZOOM, 0, TAU, 32, C_TRACER, 3.0 / T.CAM_ZOOM)     # (build 76) its screen size kept
	if cross != Vector2.INF:
		var tick: float = T.G_CROSS_TICK_PX / T.CAM_ZOOM
		for i in range(4):
			var d := Vector2.RIGHT.rotated(i * PI / 2.0)
			draw_line(cross + d * cross_r, cross + d * (cross_r + tick), Color(0, 0, 0, 0.55), 5.0 / T.CAM_ZOOM)
			draw_line(cross + d * cross_r, cross + d * (cross_r + tick), C_TRACER, 2.5 / T.CAM_ZOOM)
		draw_circle(cross, 2.0 / T.CAM_ZOOM, C_TRACER)
	if exit_prompt != "":
		var f: Font = (get_parent() as SliceWorld).font()
		var fs := prompt_px()
		var w := f.get_string_size(exit_prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, exit_at - Vector2(w * 0.5, 0), exit_prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, C_EXIT)


## (build 76) The way out's prompt: 28 px on screen at any zoom (the world's font size over the camera's zoom).
static func prompt_px() -> int:
	return int(round(28.0 / T.CAM_ZOOM))
