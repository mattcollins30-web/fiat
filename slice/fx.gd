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


func tracer(a: Vector2, b: Vector2) -> void:
	marks.append({"kind": "tracer", "a": a, "b": b, "t": T.TRACER_S, "life": T.TRACER_S})
	marks.append({"kind": "flash", "a": a, "t": T.FLASH_S, "life": T.FLASH_S})
	queue_redraw()


func hit_flash(man: Node2D) -> void:
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
				draw_line(m["a"], m["b"], Color(C_TRACER, 0.85 * k), 3.0)
			"flash":
				draw_circle(m["a"], 16.0 * k + 6.0, Color(C_FLASH, k))
			"hit":
				var n = m["node"]
				var p: Vector2 = n.position if is_instance_valid(n) else m["a"]
				var r: float = float(n.get("radius")) if is_instance_valid(n) and n.get("radius") != null else T.MAN_R
				draw_circle(p, r, Color(1, 1, 1, 0.75 * k))
			"spark":
				for i in range(5):
					var d := Vector2.RIGHT.rotated(i * TAU / 5.0) * (1.0 - k) * 26.0
					draw_circle(m["a"] + d, 3.5, Color(C_SPARK, k))
	if reticle != Vector2.INF:
		var rc := C_TRACER if reticle_locked else Color(C_TRACER, 0.6)
		draw_arc(reticle, 22.0 if reticle_locked else 14.0, 0, TAU, 32, rc, 3.0)
		draw_circle(reticle, 3.0, rc)
	if exit_prompt != "":
		var f: Font = (get_parent() as SliceWorld).font()
		var w := f.get_string_size(exit_prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		draw_string(f, exit_at - Vector2(w * 0.5, 0), exit_prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, C_EXIT)
