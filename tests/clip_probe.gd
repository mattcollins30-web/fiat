extends SceneTree
## A player's save through every screen, every pick, and every label measured:
## what trails off for them. `-- <path>` names the save (default tests/matt.save).

const Data := preload("res://scripts/sim/data.gd")

var _bad := 0
var _seen := {}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var path := "res://tests/matt.save" if args.is_empty() else args[0]
	var main = load("res://scripts/ui/main.gd").new()
	main.intro = false
	root.add_child(main)
	main.new_game()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		print("no save at " + path)
		quit(1)
		return
	var d = JSON.parse_string(f.get_as_text())
	main.sim.load_dict(d["sim"])
	var sim = main.sim
	main.refresh()
	for r in main.ROOMS:
		main.show_room(r)
		_sweep(main, r)
	# the Lock-up: every slot, every cell
	main.show_room(main.ARMOURY)
	for slot in Data.SLOTS:
		main._armoury._pick_slot(slot)
		main.refresh()
		_sweep(main, "Lock-up " + slot)
	for k in range(main._armoury._inv.KINDS.size()):
		main._armoury._inv._set_kind(k)
		main.refresh()
		for it in main._armoury._inv.items:
			var c: int = main._armoury._inv.cell_of(it["id"])
			if c >= 0:
				main._armoury._pick_cell(c)
				main.refresh()
				_sweep(main, "Lock-up %s" % it["base"])
	main._armoury._inv._set_kind(0)
	# the Bench
	main.show_room(main.WORKSHOP)
	for slot in ["Primary", "Secondary"]:
		if sim.equipped[slot] == null:
			continue
		for mount in sim.equipped[slot]["attachments"]:
			main._workshop._pick_mount(slot, mount)
			main.refresh()
			_sweep(main, "Bench %s %s" % [slot, mount])
	# the Fence and the Clinic
	for pair in [[main.MARKET, main._fence], [main.MEDIC, main._clinic]]:
		main.show_room(pair[0])
		var v = pair[1]
		v._show("shelf")
		main.refresh()
		for it in v._stock():
			var k: int = v._shelf.cell_of(it["id"])
			if k >= 0:
				v._shelf._pick(k)
				main.refresh()
				_sweep(main, "%s shelf %s" % [pair[0], it["base"]])
		v._show("stash")
		main.refresh()
		for it in v._stash.items:
			var k: int = v._stash.cell_of(it["id"])
			if k >= 0:
				v._stash._pick(k)
				main.refresh()
				_sweep(main, "%s stash %s" % [pair[0], it["base"]])
	# the menus
	main.show_pause()
	_sweep(main, "pause")
	main._menu.close()
	main.show_slots(true, main.show_pause)
	_sweep(main, "slots")
	main._menu.close()
	# a run, live
	if not sim.on_mission():
		sim.deploy(sim.auto_tier if sim.auto_tier >= 0 else 0)
	main.show_room(main.MISSIONS)
	for k in range(20):
		sim.advance(1.0)
		main.refresh()
		_sweep(main, "run %d s" % k)
	print("%d label%s clipped" % [_bad, "" if _bad == 1 else "s"])
	quit(0 if _bad == 0 else 1)


func _sweep(main, where: String) -> void:
	var UI = load("res://scripts/ui/ui.gd")
	var out := []
	_labels_under(main, out)
	for n in out:
		var w: float = UI.text_width(n, n.text) + (32.0 if n is Button else 0.0)
		if w > n.size.x + 0.5 and not _seen.has(n.text):
			_seen[n.text] = true
			print("%s: '%s' needs %.0f px, has %.0f" % [where, n.text, w, n.size.x])
			_bad += 1


static func _labels_under(n: Node, out: Array) -> void:
	if n is CanvasItem and not n.visible:
		return
	if n is Label and n.text != "" and n.autowrap_mode == TextServer.AUTOWRAP_OFF:
		out.append(n)
	elif n is Button and n.text != "" and n.icon == null:
		out.append(n)
	for c in n.get_children():
		_labels_under(c, out)
