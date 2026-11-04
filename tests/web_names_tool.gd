extends SceneTree
## The skill web's names (BUILD49 V): their places on the version-two web searched (web_view._place_names: seconds) and printed
## as web_view.gd's NAME_AT, to paste in when the layout or the canvas changes. Run: godot --path . -s res://tests/web_names_tool.gd
func _init() -> void:
	var main = load("res://scripts/ui/main.gd").new()
	main.intro = false
	main.save_file = "user://probe.save"
	main.slot_file = "user://probe_slot.save"
	root.add_child(main)
	main.new_game()
	var wv = main._barracks.web()
	var t0 := Time.get_ticks_usec()
	wv._names_cache = {}
	wv.size = wv.size + Vector2(0, -0.0001)          # not the stored canvas: the search runs
	wv.lay_out()
	print("NAMES lay_out %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	var parts: Array = []
	for k in wv._axis:
		var ax: Dictionary = wv._axis[k]
		parts.append('"%s": [%.1f, %.1f, %.2f, %d]' % [k, ax["label_at"].x, ax["label_at"].y, ax["k"], (2 if ax.get("inline", false) else 1) if ax["emblems"].size() > 0 else 0])
		print("NAMES %s r %.0f k %.2f emblems %d/%d" % [k, Vector2(ax["label_at"]).length(), ax["k"], ax["emblems"].size(), ax["emblems_all"].size()])
	print("NAME_AT := {" + ", ".join(parts) + "}")
	quit()
