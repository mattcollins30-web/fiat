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
	if r == "run":
		if not main.sim.on_mission():
			main.sim.deploy(0)
		for i in range(12):
			main.sim.advance(1.0)
		main.show_room(main.MISSIONS)
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
