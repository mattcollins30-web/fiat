extends SceneTree
## Screenshots of the rooms with a save loaded: `-- <save> <room,room,...> <out dir>`.
## Needs a display (xvfb-run). The rooms by name from main.ROOMS; "run" for a live run.

var main
var _rooms: Array = []
var _out := "res://shots"
var _k := 0
var _wait := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var path := "res://tests/matt.save" if args.is_empty() else args[0]
	_rooms = args[1].split(",") if args.size() > 1 else ["missions"]
	_out = args[2] if args.size() > 2 else "res://shots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	main = load("res://scripts/ui/main.gd").new()
	main.intro = false
	root.add_child(main)
	main.new_game()
	var f := FileAccess.open(path, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	main.sim.load_dict(d["sim"])
	main.refresh()
	_wait = -1


func _next() -> void:
	if _k >= _rooms.size():
		quit()
		return
	var r: String = _rooms[_k]
	if r == "benchpick":
		# the bench with a part in the stash picked against the one on the mount
		if main.sim.on_mission():
			main.sim.extract_now()
		var dot: Dictionary = main.sim._plain("Attachment", "Red dot")
		dot["affixes"] = [{"stat": "damage_pct", "value": 4, "tier": 2}]
		main.sim.stash.append(dot)
		main.show_room(main.WORKSHOP)
		main._workshop._set_view("guns")
		main._workshop.sel_slot = ""
		main._workshop.sel_mount = ""
		main._workshop.sel_id = -1
		main.refresh()
		main._workshop._pick_cell(main._workshop._inv.cell_of(dot["id"]))
	elif r == "runpick":
		# a live run with an armour in the pack picked, against the one worn
		if not main.sim.on_mission():
			main.sim.deploy(0)
		var found: Dictionary = main.sim._plain("Armour", "Motorbike leathers")
		found["rarity"] = 2
		found["affixes"] = [{"stat": "poison_res", "value": 7, "tier": 1}, {"stat": "armour", "value": 3, "tier": 1}]
		main.sim.mission["found"].append(found)
		main.show_room(main.MISSIONS)
		main.refresh()
		main._run._inv._pick(main._run._inv.cell_of(found["id"]))
	elif r == "run" or r == "dots":
		if not main.sim.on_mission():
			main.sim.deploy(0)
		for i in range(12):
			main.sim.advance(1.0)
		if r == "dots":
			var m: Dictionary = main.sim.mission
			m["remaining"] = maxi(m["remaining"], 3)
			m["target_hp"] = maxf(m["target_hp"], 400.0)
			m["dots"] = {"fire": 20.0, "poison": 20.0}
			m["chill_t"] = 1.0
			m["my_dots"] = {"poison": 20.0, "bleed": 20.0}
			m["target_hp"] = float(m["t"]["hp"]) * 0.7
			m["dots"] = {"fire": float(m["t"]["hp"]) * 0.15, "poison": float(m["t"]["hp"]) * 0.2}
			m["my_dots"] = {"poison": main.sim.max_hp() * 0.08, "bleed": main.sim.max_hp() * 0.12}
			main.sim.hp = main.sim.max_hp() * 0.6
		main.show_room(main.MISSIONS)
	elif r == "pick":
		# the Lock-up with the stash's best-affixed piece picked
		main.show_room(main.ARMOURY)
		main.refresh()
		var best = null
		for it in main.sim.stash:
			if best == null or it.get("affixes", []).size() > best.get("affixes", []).size():
				best = it
		if best != null:
			main._armoury._pick_cell(main._armoury._inv.cell_of(best["id"]))
	else:
		if main.sim.on_mission():
			main.sim.extract_now()
		main.show_room(r)
	main.refresh()
	_wait = 3


func _process(_dt: float) -> bool:
	if _wait == -1:
		# a frame in: the title menu the shell opened on entering the tree is closed here
		main._menu.close()
		_next()
		return false
	if _wait > 0:
		_wait -= 1
		if _wait == 0:
			var img: Image = root.get_viewport().get_texture().get_image()
			img.save_png(ProjectSettings.globalize_path("%s/%s.png" % [_out, _rooms[_k]]))
			_k += 1
			_next()
	return false
