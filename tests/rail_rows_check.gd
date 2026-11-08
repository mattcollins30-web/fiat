extends SceneTree
## The rail's rows as the game lays them, in a tree that runs its frames (BUILD48 item 8, Matt: "you never fixed the rail
## clipping here when a runner is away"): the smoke's own runs in _init, outside one, and a Control's minimum size only
## settles on a frame - so the smoke can't see a row that kept its old height when the away card shrank the rows. This
## lays them with the away card off, a frame, then on (the rows shrink), a frame, the Map's Away badge up, and measures
## every row as drawn: its height its slot's, its hairline at the foot, the name's text inside the row and clear of the
## badge. At 1920 x 1080 and the Deck's canvas. The smoke starts it (Linux, its own XDG home, the dummy audio);
## `-- out <file>` is where it writes what it found: {"tried": n, "bad": [...]}.

const Words := preload("res://scripts/sim/words.gd")

var out := {"tried": 0, "bad": []}


func _initialize() -> void:
	_run.call_deferred()


func _row_said(b, slot: float, where: String) -> void:
	out["tried"] = int(out["tried"]) + 1
	var bad: Array = out["bad"]
	if not is_equal_approx(b.size.y, slot) or not is_equal_approx(b._rule.position.y, slot - 1.0):
		bad.append("%s %s: the row %.0f tall in a %.0f slot, its hairline at %.0f" % [b.room, where, b.size.y, slot, b._rule.position.y])
	var n: Label = b._name
	var fh: float = n.get_theme_font("font").get_height(n.get_theme_font_size("font_size"))
	var top: float = n.position.y + (maxf(n.size.y, fh) - fh) / 2.0
	var bottom: float = top + fh
	# (BUILD69-R) the chip at the row's top right: the name's words clear of it, both inside the row
	var UIv = load("res://scripts/ui/ui.gd")
	var name_drawn := Rect2(n.position.x, top, UIv.text_width(n, n.text), fh)
	var chip_meets: bool = b._badge.visible and name_drawn.intersects(Rect2(b._badge.position, b._badge.size))
	if top < 0.0 or bottom > slot - 0.5 or chip_meets or (b._badge.visible and b._badge.position.y + b._badge.size.y > slot - 1.0):
		bad.append("%s %s: the name drawn %.0f-%.0f, the badge %s, the row %.0f" % [b.room, where, top, bottom, str([b._badge.position.y, b._badge.position.y + b._badge.size.y]) if b._badge.visible else "-", slot])


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var path: String = str(args[args.find("out") + 1]) if args.has("out") else "user://rail_rows_check.json"
	var main = load("res://scripts/ui/main.gd").new()
	main.intro = false
	main.save_file = "user://rail_rows_check.save"
	main.slot_file = "user://rail_rows_check%d.save"
	root.add_child(main)
	main.new_game()
	for k in range(3):
		await process_frame
	if main._menu.visible:
		main._menu.close()
	main.show_room(main.OVERVIEW)
	main.set_process(false)                    # the shell's refresh would lay the card and the badges as the camp has them
	for sz in [Vector2(1920, 1080), Vector2(1920, 1200)]:
		main.layout(sz)
		for away in [false, true, false]:
			main._away.visible = away
			main._lay_rail_rows()
			var map_b = main._rail_buttons[main.MISSIONS]
			map_b.show_status({"badge": Words.REPEAT["badge_away"] if away else "", "badge_tone": "warn"})
			await process_frame
			await process_frame
			var slot: float = main._rail_buttons[main.ROOMS[1]].position.y - main._rail_buttons[main.ROOMS[0]].position.y
			for nm in main.ROOMS:
				_row_said(main._rail_buttons[nm], slot, "%dx%d, the away card %s" % [int(sz.x), int(sz.y), "on" if away else "off"])
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	for p in ["user://rail_rows_check.save"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	quit()
