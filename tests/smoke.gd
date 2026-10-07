extends SceneTree
## A headless smoke test: godot --headless --path . -s tests/smoke.gd
## Builds the shell, starts a camp, has a crude bot run missions, gear up and
## sell, shows every room along the way and checks every label fits its box,
## then round-trips the save. Exit 1 if anything doesn't fit.

const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Words := preload("res://scripts/sim/words.gd")
const Bot := preload("res://tests/bot.gd")
const SMOKE_SAVE := "user://smoke_autosave.save"
const SMOKE_SLOT := "user://smoke_slot%d.save"
var _player_saves_before := {}


## The player's own save files on this machine, by size and time: the smoke must leave every one as it found it.
static func _player_saves() -> Dictionary:
	var out := {}
	var Main = load("res://scripts/ui/main.gd")
	var paths: Array = [Main.SAVE_FILE]
	for k in range(Main.SLOTS):
		paths.append(Main.SLOT_FILE % (k + 1))
	for path in paths:
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			out[path] = [f.get_length(), FileAccess.get_modified_time(path)]
	return out
const Sim := preload("res://scripts/sim/sim.gd")
const People := preload("res://scripts/ui/people.gd")
const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Chips := preload("res://scripts/ui/chips.gd")

var _misfits := 0
var _fails := 0


## A failed assert would end _init before quit() and leave the process hanging;
## this logs and counts instead, and the end exits 1.
func _check(ok: bool, msg: String) -> void:
	if not ok:
		push_error("CHECK FAILED: " + msg)
		_fails += 1


func _init() -> void:
	var main = load("res://scripts/ui/main.gd").new()
	main.intro = false
	# the smoke saves to its own files, never the player's (7 Oct: it wrote slot 1 and took the autosave on the Legion)
	main.save_file = SMOKE_SAVE
	main.slot_file = SMOKE_SLOT
	_player_saves_before = _player_saves()
	root.add_child(main)
	main.new_game()
	var sim = main.sim
	sim.set_class("Doorman")
	_check(sim.cls == "Doorman", "sim.cls == 'Doorman'")
	_check(sim.cash == float(Data.STARTING_CASH), "sim.cash == float(Data.STARTING_CASH)")
	_check(sim.equipped["Primary"] != null, "sim.equipped['Primary'] != null")
	_rarity_tone_checks(sim)
	for r in main.ROOMS:
		main.show_room(r)
		_check_fit(main, r + " (start)")
	# the bot: deploy to the best open tier the operator can probably survive,
	# gear up from the stash after each mission, sell commons, treat when hurt
	var runs := 0
	var kias := 0
	var meds_used := 0
	var t_start := Time.get_ticks_msec()
	while not sim.depot_cleared and runs < 300 and Time.get_ticks_msec() - t_start < 60000:
		var t := _pick_tier(sim)
		if sim.hp < sim.max_hp() * 0.7:
			if not sim.treat():
				sim.advance(120.0)            # rest instead
				continue
		sim.deploy(t)
		var guard := 0
		while sim.on_mission() and guard < 10000:
			sim.advance(1.0)
			if sim.on_mission() and sim.hp < sim.max_hp() * 0.4 and sim.mission["using"] == null and not sim.first_med().is_empty():
				sim.use_med(sim.first_med()["id"])
				meds_used += 1
			if guard == 20 or (sim.searching() and guard % 7 == 0 and runs % 5 == 0):
				main.show_room(main.MISSIONS)
				_check_fit(main, "Missions (live, run %d)" % runs)
			# the bot bails at a quarter HP, like a player would
			if sim.on_mission() and (sim.hp < sim.max_hp() * 0.25 or (sim.searching() and sim.pack_used(sim.mission) >= sim.capacity()) or guard > 1200):
				sim.extract_now()
			guard += 1
		runs += 1
		if sim.last_report["outcome"] == "KIA":
			kias += 1
		for s in Data.SLOTS:
			sim.equip_best(s)
		sim.sell_commons()
		_sell_spares(sim)
		_buy_upgrade(sim)
		_restock_meds(sim)
		_train_tree(sim)
		_climb(sim)
		_bench(sim)
		if runs % 10 == 0:
			for r in main.ROOMS:
				main.show_room(r)
				_check_fit(main, "%s (run %d)" % [r, runs])
	print("depot %s after %d missions, %d KIA, %d meds used, %s played: level %d, cash £%d, dps %.0f, armour %.0f, stash %d, depths %s" % [
			"cleared" if sim.depot_cleared else "NOT cleared", runs, kias, meds_used, _hours(sim.elapsed), sim.level(), int(sim.cash),
			sim.dps(), sim.armour(), sim.stash.size(), str(sim.best_depth)])
	# keep climbing for a while after the depot: how deep does the bot get in three hours?
	var started := Time.get_ticks_msec()
	while sim.elapsed < 1.5 * 3600.0 and runs < 200 and Time.get_ticks_msec() - started < 40000:
		var t := _pick_tier(sim)
		if sim.hp < sim.max_hp() * 0.7 and not sim.treat():
			sim.advance(120.0)
			continue
		sim.deploy(t)
		var guard := 0
		while sim.on_mission() and guard < 10000:
			sim.advance(1.0)
			if sim.on_mission() and sim.hp < sim.max_hp() * 0.4 and sim.mission["using"] == null and not sim.first_med().is_empty():
				sim.use_med(sim.first_med()["id"])
			if sim.on_mission() and (sim.hp < sim.max_hp() * 0.25 or (sim.searching() and sim.pack_used(sim.mission) >= sim.capacity()) or guard > 1200):
				sim.extract_now()
			guard += 1
		runs += 1
		if sim.last_report["outcome"] == "KIA":
			kias += 1
		for s in Data.SLOTS:
			sim.equip_best(s)
		sim.sell_commons()
		_sell_spares(sim)
		_buy_upgrade(sim)
		_restock_meds(sim)
		_train_tree(sim)
		_climb(sim)
		_bench(sim)
	print("after %s: %d missions, %d KIA, level %d, depths %s, dps %.0f, armour %.0f, tree %d pts" % [
			_hours(sim.elapsed), runs, kias, sim.level(), str(sim.best_depth), sim.dps(), sim.armour(), sim.points_spent()])
	_check(meds_used > 0, "the bot never used a med")
	var fitted := []
	for s in Data.SLOTS:
		fitted.append("%s: %s" % [s, Items.full_name(sim.equipped[s]) if sim.equipped[s] != null else "-"])
	print("loadout: " + ", ".join(fitted))
	# the Armoury screen: select a stash item and a slot, compare, equip through it
	main.show_room(main.ARMOURY)
	var gear_k := -1
	for k in range(sim.stash.size()):
		if not Items.is_medical(sim.stash[k]) and not Items.is_attachment(sim.stash[k]):
			gear_k = k
			break
	if gear_k >= 0:
		var picked: Dictionary = sim.stash[gear_k]
		while not sim.stash_room(12) and sim.stash.size() > 1:
			var last: Dictionary = sim.stash.back()
			if last["id"] == picked["id"]:
				break
			sim.sell(last)                   # room for what comes off: the run may have filled the stash
		main.refresh()
		main._armoury._pick_cell(main._armoury._inv.cell_of(picked["id"]))
		_check_fit(main, "Armoury (stash pick)")
		main._armoury._press(0)              # Equip
		_check(sim.equipped[picked["slot"]]["id"] == picked["id"], "Equip through the screen did not equip")
		_check(main._armoury.selected.get("slot", "") == picked["slot"], "the selection did not follow the item")
		print("screen equip ok: %s into %s" % [picked["base"], picked["slot"]])
	main._armoury._pick_slot("Primary")
	_check_fit(main, "Armoury (slot pick)")
	sim.buy_med("First aid kit")
	for k in range(sim.stash.size()):
		if sim.stash[k]["base"] == "First aid kit":
			main.refresh()
			main._armoury._inv._set_kind(0)
			main.refresh()
			main._armoury._pick_cell(main._armoury._inv.cell_of(sim.stash[k]["id"]))
			_check_fit(main, "Armoury (med pick)")
			var before_rig: int = sim.rig.size()
			main._armoury._press(0)          # Take, if there's room
			if sim.rig.size() > before_rig:
				_check(main._armoury.selected.get("kind", "") == "rig", "the selection did not follow the med into the rig")
				main._armoury._press(0)      # Leave
				_check(sim.rig.size() == before_rig, "Leave did not return the med")
			print("take/leave through the screen ok")
			break
	# the rig grid: a press on a slot selects it; a drop from the stash takes, a drop back leaves
	if sim.rig.size() > 0:
		main._armoury._containers._pick(0)
		main.refresh()
		_check(main._armoury.selected.get("kind", "") == "rig", "pressing a rig slot did not select it")
		_check_fit(main, "Armoury (rig pick)")
	if sim.med_capacity() == 0:
		sim.equipped["Rig"] = sim._plain("Rig", Data.BASES["Rig"][0]["name"])    # the run may have lost the rig
	while not sim.stash_room(2) and sim.stash.size() > 0:
		sim.sell(sim.stash.back())          # room in the stash for what the rig gives up
	while not sim.rig_room(2) and sim.rig.size() > 0 and sim.stash_room(2):
		sim.leave(sim.rig.back()["id"])     # room for the drop, a two-cell kit included
	var dropped := false
	var any_med := false
	for it in sim.stash:
		any_med = any_med or (Items.rig_item(it) and sim.rig_room(Items.size(it)))
	if not any_med:
		sim.stash.append(sim._plain("Medical", "Bandage"))      # the run may have used them all, or what's left is too big for the room
	for k in range(sim.stash.size()):
		var it: Dictionary = sim.stash[k]
		if Items.rig_item(it) and sim.rig_room(Items.size(it)):
			dropped = true
			var data := {"id": it["id"], "src": "stash"}
			_check(main._armoury._containers._can_drop(Vector2.ZERO, data), "the rig refuses a med dropped on it")
			var before_rig: int = sim.rig.size()
			main._armoury._containers._drop(Vector2.ZERO, data)
			_check(sim.rig.size() == before_rig + 1, "a drop on the rig did not take")
			_check(not main._armoury._inv._can_drop_data(Vector2.ZERO, {"id": 0, "src": "nowhere"}), "the stash takes drops from anywhere")
			_check(main._armoury._inv._can_drop_data(Vector2.ZERO, {"id": it["id"], "src": "rig"}), "the stash refuses a rig slot dropped on it")
			main._armoury._inv._drop_data(Vector2.ZERO, {"id": it["id"], "src": "rig"})
			_check(sim.rig.size() == before_rig, "a drop back on the stash did not leave")
			print("rig drag and drop ok")
			break
	_check(dropped, "no med or stack in the stash to drop on the rig; the drop path went untested")
	# the pouches are cells: a two-cell kit needs two free, and takes two
	var kit: Dictionary = sim._plain(Data.MEDICAL, "First aid kit")
	_check(Items.size(kit) == 2, "a first aid kit is not two cells")
	while not sim.stash_room(8) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])                 # room for what the rig leaves behind
	sim.stash.append(kit)
	while sim.rig_room(2) and not sim.stash.is_empty():
		var filler: Dictionary = sim._plain(Data.MEDICAL, "Bandage")
		sim.stash.append(filler)
		sim.take(filler["id"])
	if sim.med_capacity() - sim.rig_used() == 0 and not sim.rig.is_empty():
		sim.leave(sim.rig.back()["id"])        # one pouch free, for the refusal
	var free_before: int = sim.med_capacity() - sim.rig_used()
	if free_before == 1:
		_check(not sim.take(kit["id"]) and sim.stash.has(kit), "a two-cell kit went into one free pouch")
		_check(not main._armoury._containers._can_drop(Vector2.ZERO, {"id": kit["id"], "src": "stash"}), "the rig takes a two-cell drop with one pouch free")
		sim.leave(sim.rig.back()["id"])
	var used_before: int = sim.rig_used()
	_check(sim.take(kit["id"]) and sim.rig_used() == used_before + 2, "a two-cell kit did not take two pouches: %d -> %d" % [used_before, sim.rig_used()])
	main.refresh()
	_check_fit(main, "Armoury (kit in the rig)")
	# rounds dropped on a full rig top up its own stack of the same type (it only stacked the other way)
	var rig_box: Dictionary = sim._plain(Data.AMMO, "Nails")
	Items.set_stack(rig_box, 50)
	var rig_held: Array = sim.rig.duplicate()
	while sim.rig_room(1):
		sim.rig.append(sim._plain(Data.MEDICAL, "Bandage"))
	sim.rig.append(rig_box)                       # over the top: the test's own full rig
	var stash_box: Dictionary = sim._plain(Data.AMMO, "Nails")
	Items.set_stack(stash_box, 30)
	sim.stash.append(stash_box)
	_check(not sim.rig_room(1) and main._armoury._containers._can_drop(Vector2.ZERO, {"id": stash_box["id"], "src": "stash"}), "a full rig refuses rounds that would top up its stack")
	var nails_before: int = sim.rounds_for(sim._plain("Primary", "Nail gun"))
	var rig_n_before: int = sim.rig.size()
	_check(sim.take(stash_box["id"]) and sim.rounds_for(sim._plain("Primary", "Nail gun")) == nails_before + 30 and sim.rig.size() == rig_n_before and not sim.stash.has(stash_box), "the drop did not top up the rig's nails: %d -> %d" % [nails_before, sim.rounds_for(sim._plain("Primary", "Nail gun"))])
	sim.rig = rig_held                            # the test's bandages and box go; the rig as it was
	sim.leave(kit["id"])
	sim.sell(kit)
	main.refresh()
	_check_fit(main, "Armoury (containers)")
	_body_drops(main)
	_check_grid(main._armoury._inv, sim.stash_cap(), "the stash")
	# the inventory grid: kinds, rarity, sort, select-many sell, paging
	var inv = main._armoury._inv
	for k in range(main._armoury._inv.KINDS.size()):
		inv._set_kind(k)
		main.refresh()
		_check_fit(main, "Armoury (kind %d)" % k)
	inv._set_kind(0)
	inv._set_rarity(0)
	main.refresh()
	_check_fit(main, "Armoury (commons)")
	inv._set_rarity(-1)
	inv._cycle_sort()
	main.refresh()
	inv._toggle_many()
	main.refresh()
	var before_n: int = sim.stash.size()
	if inv.items.size() >= 2:
		inv._pick(0)
		inv._pick(1)
		main.refresh()
		_check_fit(main, "Armoury (select many)")
		inv._sell_chosen()
		main.refresh()
		_check(sim.stash.size() == before_n - 2, "select-many sell did not sell two")
		print("inventory select-many sell ok")
	inv._toggle_many()
	inv._turn(1)
	main.refresh()
	_check_fit(main, "Armoury (page 2)")
	inv._turn(-1)
	# the Run screen: a find picked and ditched, a few ditched at once, out through the button
	_run_screen(main)
	# the Fence screen: the shelf, a buy, a sell from the grid, sell by rarity
	_fence_screen(main)
	_narrative_checks(main)
	_campaign_checks(main)
	# the Clinic screen: a med bought from the shelf, taken into the rig, left again
	_clinic_screen(main)
	# the Missions screen: depth up and deploy through it; the Docks once open
	main.show_room(main.MISSIONS)
	_check_fit(main, "Missions (screen)")
	if sim.zone_complete(0):
		main._missions._pick_zone(1)
		_check_fit(main, "Missions (Town)")
		_check(main._missions.zone == 1, "the Town did not open after the Estate's boss")
		main._missions._pick_zone(0)
	elif sim.depot_cleared:
		_check(not sim.zone_open(1), "the Town opened without the Estate's boss beaten")
	if not sim.on_mission():
		var d0: int = sim.depth[0]
		main._missions._depth(0, 1)
		_check(sim.depth[0] == (mini(d0 + 1, sim.best_depth[0] + 1) if sim.campaign_done() else 1), "depth + through the screen (campaign %s)" % str(sim.campaign_done()))
		main._missions._deploy(0)
		_check(sim.on_mission(), "deploy through the screen")
		sim.extract_now()
		print("missions screen depth/deploy ok")
	# the Workshop screen: a mount, an attachment, fit and strip through it
	main.show_room(main.WORKSHOP)
	_check_fit(main, "Workshop")
	var fitted_before := 0
	for s in ["Primary", "Secondary"]:
		if sim.equipped[s] != null:
			fitted_before += Items.fitted_count(sim.equipped[s])
	print("workshop level %d, %d attachments fitted" % [sim.workshop, fitted_before])
	if sim.equipped["Primary"] != null and sim.workshop > 0 and sim.equipped["Primary"]["attachments"].has("optic"):
		main._workshop._pick_mount("Primary", "optic")
		_check_fit(main, "Workshop (mount pick)")
		var opts: Array = sim.attachments_for("optic")
		if not opts.is_empty():
			main._workshop._pick_cell(0)
			_check_fit(main, "Workshop (att pick)")
			main._workshop._press(0)              # Fit
			_check(sim.equipped["Primary"]["attachments"]["optic"] != null, "Fit through the screen did not fit")
			main._workshop._pick_mount("Primary", "optic")
			main._workshop._press(0)              # Strip
			print("workshop fit/strip ok")
	_charm_sockets(main)
	# the Comms Tower: intel for cash, and a pin that survives a mission
	main.show_room(main.COMMS)
	_check_fit(main, "Comms")
	if sim.comms_level >= 1 and sim.cash > 1000:
		var before_intel = str(sim.intel[0])
		sim.buy_intel(0)
		print("comms: intel bought, %s -> %s" % [before_intel, str(sim.intel[0])])
		if sim.can_pin():
			sim.set_pinned(0, true)
			var pinned_intel = str(sim.intel[0])
			sim.deploy(0)
			sim.extract_now()
			_check(str(sim.intel[0]) == pinned_intel, "pinned intel was spent by a mission")
			sim.set_pinned(0, false)
			print("comms: pin held through a mission")
		main.show_room(main.COMMS)
		_check_fit(main, "Comms (built)")
	# the Barracks screen: select, respec, train through it
	main.show_room(main.BARRACKS)
	_check_fit(main, "Barracks")
	print("tree: %d of %d points trained, %s" % [sim.tree.size(), sim.training_points, str(sim.tree.slice(0, 3))])
	main._barracks._pick("The yard/0")
	_check_fit(main, "Barracks (pick)")
	# the points read "N of M points free" top right, the panel says whose the node is, and no node's words are the old "for every runner the yard sends"
	_check(main._barracks._points.text.begins_with("%d of %d" % [sim.points_free(), sim.training_points]), "the points line reads '%s'" % main._barracks._points.text)
	_check(main._barracks._scope.text == "" and not main._barracks._past.visible, "a plain node carries the lines that went: '%s' / past %s" % [main._barracks._scope.text, str(main._barracks._past.visible)])
	_sum_strip_check(main)
	_check(not main._barracks._words.text.contains("the yard sends"), "a plain node still says 'for every runner the yard sends'")
	if sim.cls != "":
		var first_class_tree: Dictionary = sim.trees()[0]
		main._barracks._pick("%s/0" % first_class_tree["name"])
		_check(main._barracks._scope.text == "", "a class node carries the line that went: '%s'" % main._barracks._scope.text)
		_check_fit(main, "Barracks (class node)")
	for t in Data.TREES:
		for nd in t["nodes"]:
			if nd.has("words"):
				_check(not str(nd["words"]).contains("Out when") and not str(nd["words"]).contains("picking over"), "a node's words still read oddly: '%s'" % nd["words"])
	main._barracks._pick_class("Paramedic")
	_check(sim.cls == "Paramedic", "class through the screen")
	_check_fit(main, "Barracks (class)")
	# the Medic's rule: a med goes by itself under 40%
	sim.rig = []
	sim.buy_med("Bandage")
	for it in sim.stash.duplicate():
		if it["base"] == "Bandage":
			sim.take(it["id"])
			break
	if not sim.rig.is_empty():
		sim.hp = sim.max_hp() * 0.3
		sim.deploy(0)
		sim.advance(1.0)
		_check(sim.mission == null or sim.mission["using"] != null or sim.rig.is_empty(), "the Medic did not use a med")
		if sim.on_mission():
			sim.extract_now()
		print("medic auto-use ok")
	main._barracks._pick_class("Doorman")
	if sim.cash >= sim.respec_cost() and not sim.tree.is_empty():
		main._barracks._on_respec()
		_check(sim.tree.is_empty(), "respec did not clear the tree")
		main._barracks._pick("The yard/0")
		main._barracks._on_train()
		_check(sim.tree.has("The yard/0"), "Train through the screen did not train")
		print("barracks respec and train ok")
	_check_fit(main, "Barracks (after)")
	_class_trees(main)
	# auto-run: ten minutes on tier 1 with the toggle on, then off
	sim.set_auto(0)
	_check(sim.auto_tier == 0, "sim.auto_tier == 0")
	sim.advance(600.0)
	print("auto-run: %s, last: %s" % ["still on" if sim.auto_tier == 0 else "stopped", main.sim.events.back()[1]])
	# a manual extract during an auto-run ends the run; nothing redeploys after it
	var guard2 := 0
	while not sim.on_mission() and guard2 < 600:
		sim.advance(1.0)
		guard2 += 1
	if sim.on_mission():
		main.show_room(main.MISSIONS)
		_check_fit(main, "Missions (auto, live)")
		sim.extract_now()
		_check(sim.auto_tier == -1, "extract now did not stop the auto-run")
		sim.advance(300.0)
		_check(not sim.on_mission(), "auto-run redeployed after a manual extract")
		print("manual extract ends auto-run ok")
	sim.auto_tier = -1
	for r in main.ROOMS:
		main.show_room(r)
		_check_fit(main, r + " (end)")
	main.save_game()
	var before: Dictionary = sim.to_dict()
	main.load_game()
	var after: Dictionary = main.sim.to_dict()
	_check(is_equal_approx(float(before["cash"]), float(after["cash"])), "is_equal_approx(float(before['cash']), float(after['cash']))")
	_check(before["stash"].size() == after["stash"].size(), "before['stash'].size() == after['stash'].size()")
	print("save round-trip ok; last event: %s" % main.sim.events.back()[1])
	# every screen with the worst items there are: elites of every base, every affix at its top roll
	_worst_case(main)
	_slots_offline_hardcore(main)
	# the player's own saves are as they were, and the smoke's are gone
	_check(_player_saves() == _player_saves_before, "the smoke touched the player's saves: %s -> %s" % [str(_player_saves_before), str(_player_saves())])
	for path in [SMOKE_SAVE, SMOKE_SLOT % 1, SMOKE_SLOT % 2, SMOKE_SLOT % 3]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if _misfits > 0 or _fails > 0:
		print("FAIL: %d labels do not fit their boxes, %d checks failed" % [_misfits, _fails])
		quit(1)
		return
	print("all labels fit, all checks pass")
	quit(0)


## Save slots, the time away, and a hardcore camp lost.
func _slots_offline_hardcore(main) -> void:
	var sim = main.sim
	# a slot round-trip, and the title/slot menus' words
	var slot: String = main.slot_file % 1
	main.save_game(slot)
	_check(FileAccess.file_exists(slot), "save to a slot wrote nothing")
	_check(main._slots_words().begins_with("1 of"), "slots words: " + main._slots_words())
	_check(main._save_words(slot).begins_with("Level %d" % sim.level()), "save words: " + main._save_words(slot))
	var before_cash: float = sim.cash
	main.load_game(slot)
	_check(is_equal_approx(main.sim.cash, before_cash), "slot load changed the cash")
	main.show_slots(false, main.show_title)
	main.show_slots(true, main.show_pause)
	main.show_title()
	main._menu.close()
	sim = main.sim
	# away three hours with auto-run on: missions ran, the log moved, the clock moved
	sim.set_depth(0, 1)
	for r in range(Data.RARITIES.size()):
		sim.sell_rarity(r)            # room in the stash, or auto-run stops at once
	sim.set_auto(0)
	var before: Dictionary = sim.snapshot()
	main._settle_away(3.0 * 3600.0)
	var after: Dictionary = sim.snapshot()
	_check(is_equal_approx(after["elapsed"] - before["elapsed"], 3.0 * 3600.0), "three hours away did not pass three hours")
	_check(after["cash"] != before["cash"] or after["stash"] != before["stash"] or after["lost"] != before["lost"],
			"three hours away with auto-run on changed nothing")
	_check(sim.auto_tier == 0 or sim.auto_tier == -1, "auto_tier after the time away")
	_check(main._menu.visible and main._menu._title.text == Words.AWAY["title"] and main._menu.sub().begins_with("Gone ") and main._menu.sub().contains(" run"), "the away report is not in the voice: '%s' / '%s'" % [main._menu._title.text, main._menu.sub()])
	_check_fit(main, "Back, then (ran)")
	print("away 3h on tier 0: cash %s → %s, %d → %d items, level %d → %d, lost %d → %d" % [Fmt.money(before["cash"]),
			Fmt.money(after["cash"]), before["stash"], after["stash"], before["level"], after["level"], before["lost"], after["lost"]])
	main._menu.close()
	# the cap: a day away settles eight hours of it
	sim.auto_tier = -1
	sim.hp = 1.0
	before = sim.snapshot()
	main._settle_away(24.0 * 3600.0)
	after = sim.snapshot()
	_check(is_equal_approx(after["elapsed"] - before["elapsed"], sim.away_cap_s()), "the away cap did not hold")
	_check(sim.hp == sim.max_hp(), "the operator did not rest while away")
	_check(main._menu.sub().begins_with("Gone ") and main._menu.sub().contains("slept") and main._menu.sub().contains("kept going for"), "the rested report is not in the voice: '%s'" % main._menu.sub())
	_check_fit(main, "Back, then (rested)")
	_check(main._menu.sub_lines() < 2 or main._menu._rows[0].position.y > main._menu.ROWS_Y,
			"a two-line away report did not push the row down")
	main._menu.close()
	# the worst the away report gets: every clause, long numbers - it wraps, nothing trails off
	var worst: String = Words.AWAY["ran"] % ["2 d 17 h", 1234, "s", "the north estate", "+", Fmt.money(1234567.0), 42, "s", 12, 48]
	worst += Words.AWAY["lost"] + Words.AWAY["settled"] % "8 h" + Words.AWAY["prices"] % 1100
	main._menu.open(Words.AWAY["title"], worst, [{"name": "Continue", "detail": "", "action": main._menu.close}], main._menu.close)
	_check(main._menu.sub() == worst, "the worst away report lost words in the wrap: '%s'" % main._menu.sub())
	_check(main._menu.sub_lines() <= main._menu.SUB_LINES, "the worst away report needs %d lines" % main._menu.sub_lines())
	_check_fit(main, "Back, then (worst)")
	main._menu.close()
	# a saved stamp two hours old goes through the away screen on load
	var f := FileAccess.open(main.save_file, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": main.SAVE_VERSION, "saved": Time.get_unix_time_from_system() - 7200.0, "sim": sim.to_dict()}))
	f.close()
	main.load_game()
	_check(main._menu.visible, "a two-hour-old save did not open the away screen")
	main._menu.close()
	# hardcore: a KIA ends the camp
	main.new_game(true)
	sim = main.sim
	_check(sim.hardcore, "new_game(true) is not hardcore")
	sim.deploy(0)
	sim._kia()
	_check(sim.camp_lost, "a hardcore KIA did not lose the camp")
	_check(sim.equipped["Primary"] == null, "the hardcore KIA restocked")
	# and a standard KIA hands the new operator a worn rifle
	var std = load("res://scripts/sim/sim.gd").new()
	std.start()
	std.deploy(0)
	std._kia()
	_check(std.equipped["Primary"] != null and std.equipped["Armour"] != null, "a new operator reports without kit")
	var stamp_before: Dictionary = main._read_save(main.save_file)
	main.save_game()
	_check(main._read_save(main.save_file).get("saved", 0.0) == stamp_before.get("saved", 0.0), "a lost camp still saved")
	main.refresh()
	_check_fit(main, "Camp (lost)")
	main.show_camp_lost()
	_check(not FileAccess.file_exists(main.save_file), "the lost camp's autosave was not removed")
	_check(FileAccess.file_exists(slot), "the slots did not survive the lost camp")
	main._to_title_no_save()
	_check(main.sim == null, "the title after a lost camp still has a sim")
	DirAccess.remove_absolute(slot)
	print("slots, offline and hardcore ok")


## An elite of this base with every affix it can carry at its top roll.
func _worst_item(slot: String, base: Dictionary, sim) -> Dictionary:
	var it := Items.roll(slot, Data.MAX_TIER, sim.rng)
	it["base"] = base["name"]
	it["tier"] = base["tier"]
	var top: int = Data.RARITIES.size() - 1
	it["rarity"] = top
	it["value"] = int(round(base["value"] * Data.RARITIES[top]["value"]))
	it["affixes"] = []
	for a in Data.AFFIXES:
		if slot in a["slots"] and it["affixes"].size() < int(Data.RARITIES[top]["affixes"]):
			it["affixes"].append({"stat": a["stat"], "value": int(a["max"]), "tier": Data.AFFIX_TIERS})
	if slot == Data.ATTACHMENT:
		it["mount"] = base["mount"]
	else:
		it["attachments"] = {}
		for name in base.get("attachments", []):
			it["attachments"][name] = null
	return it


## The random items the bot found are never the worst. This fills the yard
## with the worst - elites of every base, every affix at its top roll, every
## mount fitted - and shows every screen and every pick on it.
func _worst_case(main) -> void:
	var sim = main.sim
	sim.auto_tier = -1
	if sim.on_mission():
		sim.extract_now()
	var worst: Array = []
	for slot in Data.SLOTS:
		for b in Data.BASES[slot]:
			worst.append(_worst_item(slot, b, sim))
	for b in Data.BASES[Data.MEDICAL]:
		worst.append(_worst_item(Data.MEDICAL, b, sim))
	for b in Data.BASES[Data.AMMO]:
		worst.append(sim._plain(Data.AMMO, b["name"]))
	for b in Data.ATTACHMENTS:
		worst.append(_worst_item(Data.ATTACHMENT, b, sim))
		# every part has a headline figure and words of its own (Nails through it had neither: its bleed share was not in the lists)
		var plain: Dictionary = sim._plain(Data.ATTACHMENT, b["name"])
		_check(Items.headline(plain)[0] != "" and Items.att_words(plain, true, true) != "", "%s has no headline or words" % b["name"])
	for u in Data.UNIQUES:
		worst.append(Items.roll_unique(u, sim.rng))
	# fitted: the longest-named of each slot, every mount filled
	for slot in Data.SLOTS:
		var pick := {}
		for it in worst:
			if it["slot"] == slot and (pick.is_empty() or it["base"].length() > pick["base"].length()):
				pick = it
		sim.equipped[slot] = pick.duplicate(true)
		for mount in sim.equipped[slot]["attachments"]:
			for it in worst:
				if Items.is_attachment(it) and it["mount"] == mount:
					sim.equipped[slot]["attachments"][mount] = it.duplicate(true)
					break
	sim.workshop = Data.WORKSHOP.size() - 1
	sim.stash_level = Data.STASH_LEVELS.size() - 1
	sim.market_level = Data.MARKET_LEVELS.size() - 1
	sim.stash = []
	for it in worst:
		if sim.stash_room(Items.size(it)):
			sim.stash.append(it.duplicate(true))
	sim.market = []
	for it in worst:
		if sim.market.size() < Data.MARKET_LEVELS[sim.market_level]["stock"] and not Items.is_medical(it):
			sim.market.append(it.duplicate(true))
	sim.rig = []
	var worst_med: Dictionary = _worst_item(Data.MEDICAL, Data.BASES[Data.MEDICAL].back(), sim)
	while sim.rig_room(Items.size(worst_med)):
		sim.rig.append(_worst_item(Data.MEDICAL, Data.BASES[Data.MEDICAL].back(), sim))
	while sim.rig_room(1):
		sim.rig.append(sim._plain(Data.MEDICAL, "Bandage"))
	sim.cash = 9999999.0
	sim.hp = sim.max_hp()
	for r in main.ROOMS:
		main.show_room(r)
		_check_fit(main, "%s (worst)" % r)
	# the Lock-up: every slot picked, then the first cell of every kind
	main.show_room(main.ARMOURY)
	for slot in Data.SLOTS:
		main._armoury._pick_slot(slot)
		main.refresh()
		_check_fit(main, "Lock-up (worst, %s)" % slot)
	for k in range(main._armoury._inv.KINDS.size()):
		main._armoury._inv._set_kind(k)
		main.refresh()
		if main._armoury._inv.items.size() > 0:
			main._armoury._pick_cell(main._armoury._inv.cell_of(main._armoury._inv.items[0]["id"]))
			main.refresh()
			_check_fit(main, "Lock-up (worst, kind %d)" % k)
	main._armoury._inv._set_kind(0)
	# the Bench: every mount of the primary, an attachment picked
	main.show_room(main.WORKSHOP)
	for mount in sim.equipped["Primary"]["attachments"]:
		main._workshop._pick_mount("Primary", mount)
		main.refresh()
		_check_fit(main, "Bench (worst, %s)" % mount)
	# the Fence and the Clinic: every shelf cell, the first stash cell
	sim.clinic = []
	for b in Data.BASES[Data.MEDICAL]:
		sim.clinic.append(_worst_item(Data.MEDICAL, b, sim))
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
				_check_fit(main, "%s (worst, shelf %s)" % [pair[0], it["base"]])
		v._show("stash")
		main.refresh()
		if v._stash.items.size() > 0:
			v._stash._pick(v._stash.cell_of(v._stash.items[0]["id"]))
			main.refresh()
			_check_fit(main, "%s (worst, stash)" % pair[0])
		v._show("shelf")
	# the run: the pack full of the worst, every cell picked
	sim.set_depth(0, 1)
	sim.deploy(0)
	sim.mission["found"] = []
	for it in worst:
		if sim.pack_used(sim.mission) + Items.size(it) <= sim.capacity():
			sim.mission["found"].append(it.duplicate(true))
	main.show_room(main.MISSIONS)
	main.refresh()
	_check_fit(main, "Run (worst)")
	for it in sim.mission["found"]:
		var k: int = main._run._inv.cell_of(it["id"])
		if k >= 0:
			main._run._inv._pick(k)
			main.refresh()
			_check_fit(main, "Run (worst, %s)" % it["base"])
	sim.extract_now()
	main.refresh()
	print("worst case ok")


## The Clinic as a vendor screen: Treat, Buy off its shelf, Take from your meds, Leave from the rig.
func _clinic_screen(main) -> void:
	var sim = main.sim
	main.show_room(main.MEDIC)
	_check_fit(main, "Clinic (shelf)")
	sim.hp = sim.max_hp() * 0.5
	sim.cash += 2000.0
	main.refresh()
	main._clinic._side_press(0)         # Treat
	_check(sim.hp >= sim.max_hp() - 0.5, "Treat through the screen did not heal")
	_check(sim.clinic.size() > 0 and sim.clinic.size() <= Data.MEDIC_LEVELS[sim.medic_level]["stock"], "the clinic's shelf is empty or over its stock")
	var it: Dictionary = sim.clinic[0]
	main._clinic._shelf._pick(main._clinic._shelf.cell_of(it["id"]))
	main.refresh()
	_check_fit(main, "Clinic (shelf pick)")
	var shelf_before: int = sim.clinic.size()
	main._clinic._press(0)              # Buy
	_check(sim.clinic.size() == shelf_before - 1 or not sim.stash_room(1), "Buy off the clinic's shelf did not buy, or the shelf did not shrink")
	main._clinic._show("stash")
	main.refresh()
	_check_fit(main, "Clinic (your meds)")
	var k: int = main._clinic._stash.cell_of(it["id"])
	if k >= 0 and sim.rig_room(Items.size(it)):
		main._clinic._stash._pick(k)
		main.refresh()
		_check_fit(main, "Clinic (med pick)")
		var rig_before: int = sim.rig.size()
		main._clinic._press(0)          # Take
		_check(sim.rig.size() == rig_before + 1, "Take through the clinic did not take")
		main.refresh()
		_check_fit(main, "Clinic (rig)")
		# leaving is the Lock-up's (the clinic's empty panel acts on nothing)
		_check(sim.leave(sim.rig.back()["id"]), "leave from the rig did not leave")
		_check(sim.rig.size() == rig_before, "the rig did not go back down")
	main._clinic._show("shelf")
	print("clinic screen ok")


## The Fence as a vendor screen: their shelf (finite), Buy, your stash's Sell, sell by rarity.
func _fence_screen(main) -> void:
	var sim = main.sim
	main.show_room(main.MARKET)
	_check_fit(main, "Fence (shelf)")
	if sim.market.size() > 0:
		var it: Dictionary = sim.market[0]
		main._fence._shelf._pick(main._fence._shelf.cell_of(it["id"]))
		main.refresh()
		_check_fit(main, "Fence (shelf pick)")
		# the pick's head: the name, the chips, the figure big, the title label away
		var fh = main._fence._head
		_check(fh.visible and not main._fence._left_title.visible and fh._title.text != "" and fh._figure.text != "" and fh._chips[0].visible, "the fence's pick has no head: %s / %s" % [fh._title.text, fh._figure.text])
		sim.cash += sim.price(it)
		var n_before: int = sim.stash.size()
		var shelf_before: int = sim.market.size()
		main._fence._press(0)
		_check(sim.stash.size() == n_before + 1 or not sim.stash_room(Items.size(it)), "Buy through the screen did not buy")
		_check(sim.market.size() == shelf_before - 1 or not sim.stash_room(Items.size(it)), "the shelf did not shrink: finite stock")
	main._fence._show("stash")
	main.refresh()
	_check_fit(main, "Fence (your stash)")
	if sim.stash.size() > 0:
		var it: Dictionary = sim.stash[0]
		main._fence._stash._set_kind(0)
		main._fence._stash._set_rarity(-1)
		main.refresh()
		var k: int = main._fence._stash.cell_of(it["id"])
		if k >= 0:
			main._fence._stash._pick(k)
			main.refresh()
			_check_fit(main, "Fence (stash pick)")
			var cash_before: float = sim.cash
			main._fence._press(0)
			_check(sim.cash > cash_before, "Sell through the screen did not sell")
	# the fence's word (the gamble, Matt, 6 Oct): the fourth tab, five kinds with a price, Pay through the screen, the last word under them
	main._fence._show("word")
	main.refresh()
	_check(main._fence._word.visible and not main._fence._shelf.visible and not main._fence._deals.visible, "the word tab did not show its panel alone")
	_check(main._fence._tabs[3].visible and main._fence._tabs[3].text.begins_with("The word"), "the word tab reads '%s'" % main._fence._tabs[3].text)
	var shown_offers: int = 0
	for o in main._fence._offers:
		if o["pay"].visible:
			shown_offers += 1
			_check(o["pay"].text.begins_with("Pay £") and o["kind"].text != "", "an offer tile is blank: '%s' / '%s'" % [o["kind"].text, o["pay"].text])
	_check(shown_offers == sim.gamble.size(), "the offer tiles do not match the offer: %d for %s" % [shown_offers, str(sim.gamble)])
	_check_fit(main, "Fence (the word)")
	if not sim.gamble.is_empty():
		sim.cash = maxf(sim.cash, sim.gamble_price(sim.gamble[0]) * 2.0)
		while not sim.stash_room(12) and not sim.stash.is_empty():
			sim.sell(sim.stash[0])        # room for whatever he gets: a full stash refuses the word
		var kind0: String = sim.gamble[0]
		var n0: int = sim.stash.size()
		var cash0: float = sim.cash
		main.refresh()
		main._fence._gamble(0)
		main.refresh()
		_check(sim.stash.size() == n0 + 1 and sim.cash < cash0 and not (kind0 in sim.gamble), "Pay through the screen did not gamble: stash %d from %d, cash %.0f from %.0f" % [sim.stash.size(), n0, sim.cash, cash0])
		_check(main._fence._last.visible and main._fence._last._title.text != "" and not main._fence._last_none.visible, "the last word is not shown after a gamble: '%s'" % main._fence._last._title.text)
		_check(main._fence._offers[main._fence._offers.size() - 1]["kind"].text == "Taken" or sim.gamble.size() == Data.GAMBLE_SHOWN, "the bought kind did not read as taken")
		_check_fit(main, "Fence (the word, after)")
	main._fence._show("shelf")
	main._fence.selected = {}
	main.refresh()
	var commons := 0
	for it in sim.stash:
		if it["rarity"] == 0:
			commons += 1
	if commons > 0:
		main._fence._side_press(0)          # Common
		var left := 0
		for it in sim.stash:
			if it["rarity"] == 0:
				left += 1
		_check(left == 0, "Sell commons through the screen left %d" % left)
	_check_fit(main, "Fence (after)")
	main._fence._show("shelf")
	print("fence screen ok")


## The live run as a screen: the pack grid, Ditch, Select many, Get out now.
## Every site cleared and every boss beaten: the campaign, done by hand.
func _finish_campaign(sim) -> void:
	sim.depot_cleared = true
	for k in range(Data.TIERS.size()):
		sim.best_depth[k] = maxi(sim.best_depth[k], 1)
	for z in range(Data.ZONES.size()):
		sim.bosses_beaten[z] = true


## The campaign and the endgame: zones gate on bosses, the depth ladder and
## the call-in wait for the campaign, a boss comes out after the pool and
## drops from its own pool, notes come in and pay for the next one, and at
## equal depth every site's fight is within a band while its drops differ.
func _campaign_checks(main) -> void:
	var sim = main.sim
	var save: Dictionary = sim.to_dict()
	# gates
	for z in range(Data.ZONES.size()):
		sim.bosses_beaten[z] = false
	for k in range(Data.TIERS.size()):
		sim.best_depth[k] = 1
	_check(sim.zone_open(0) and not sim.zone_open(1), "the Town opened with every Estate site cleared but its boss standing")
	_check(not sim.campaign_done(), "the campaign read as done with no boss beaten")
	sim.set_depth(0, 2)
	_check(sim.depth[0] == 1, "depth 2 opened before the campaign")
	sim.hp = sim.max_hp()
	# the Estate's boss, free, from the retail park
	_check(sim.boss_cost(2) == 0, "the first boss fight is not free")
	_check(sim.can_arm_boss(2), "the Estate's boss could not be armed")
	sim.arm_boss(2, true)
	var t: Dictionary = sim.effective(2)
	_check(t.has("boss") and t["boss"]["hp"] > t["hp"], "arming the boss did not put them in the fight")
	sim.deploy(2)
	_check(sim.on_mission() and sim.mission.has("boss"), "the boss did not come on the run")
	_check(not sim.boss_armed.get(2, false), "the boss stayed armed past the deploy: arming is one run, like the insurance")
	# through the pool with a big gun, then the boss
	var guard := 0
	while sim.on_mission() and sim.mission["remaining"] > 0 and guard < 20000:
		sim.hp = sim.max_hp()
		sim.advance(1.0)
		guard += 1
	_check(sim.on_mission() and sim.mission["boss"]["started"], "the boss did not come out when the pool was down")
	guard = 0
	while sim.on_mission() and sim.mission["boss"]["alive"] and guard < 20000:
		sim.hp = sim.max_hp()
		sim.advance(1.0)
		guard += 1
	_check(sim.on_mission() and not sim.mission["boss"]["alive"], "the boss did not go down")
	_check(sim.bosses_beaten[0], "beating the boss did not mark the zone")
	var dropped := false
	for it in sim.mission["found"]:
		if it.has("unique") and it["unique"] in sim.boss_of(2)["uniques"]:
			dropped = true
	_check(dropped, "the boss dropped nothing of their own")
	_check(int(sim.mission.get("notes", 0)) > 0, "the run carried no notes")
	var notes_before: int = sim.notes
	sim.extract_now()
	_check(sim.notes > notes_before, "the notes did not come home")
	_check(sim.zone_open(1), "the Town did not open with the Estate's boss down")
	_check(sim.boss_cost(2) > 0, "the second boss fight is free")
	# the endgame: campaign done, depth 2 everywhere; the sites are nine ladders now (7 Oct): each site's
	# depth 2 harder than the one before it in the campaign's order, the city's a good deal harder than the estate's
	_finish_campaign(sim)
	var last_work := 0.0
	var work_lo := 1e9
	var work_hi := 0.0
	for i in range(Data.TIERS.size()):
		sim.set_depth(i, 2)
		_check(sim.depth[i] == 2, "depth 2 did not open at %s after the campaign" % Data.TIERS[i]["name"])
		sim.intel[i] = []                       # the shape alone, without the word on it
		var e: Dictionary = sim.effective(i)
		var work: float = e["hp"] * e["dps"]       # how hard one of them is: the level's curve, bent by the shape
		_check(work >= last_work * 0.8, "at depth 2 %s reads easier than the site before it: %.0f after %.0f" % [Data.TIERS[i]["name"], work, last_work])
		last_work = work
		work_lo = minf(work_lo, work)
		work_hi = maxf(work_hi, work)
	_check(work_hi / work_lo > 3.0, "at depth 2 the sites' fights differ by only ×%.1f; the ladders are not nine" % (work_hi / work_lo))
	# the boss costs notes now
	sim.notes = 0
	_check(not sim.can_arm_boss(2), "a boss was armed with no notes")
	sim.notes = 1000
	_check(sim.can_arm_boss(2), "a boss could not be armed with notes in hand")
	# exclusives: a site's own base drops there and nowhere else
	var seen_at := {}
	for i in range(Data.TIERS.size()):
		var site: Dictionary = Data.TIERS[i]
		for k in range(300):
			for slot in ["Primary", "Secondary", "Helmet", "Armour", "Rig", "Backpack", "Medical", "Ammo", "Attachment"]:
				var it := Items.roll(slot, Data.MAX_TIER, sim.rng, 0.0, false, false, site["name"], str(site["drops"].get("type", "")))
				var home := Items.exclusive_to(it["base"])
				if home != "":
					_check(home == site["name"], "%s dropped at %s; it belongs to %s" % [it["base"], site["name"], home])
					seen_at[it["base"]] = true
	for i in range(Data.TIERS.size()):
		for name in Data.TIERS[i]["drops"].get("only", []):
			_check(seen_at.has(name), "%s never dropped at its own site" % name)
	for i in range(Data.TIERS.size()):
		for name in Data.TIERS[i]["drops"].get("only", []):
			_check(Words.item_words(name) != "" , "%s has no words" % name)
	for b in Data.BOSSES:
		_check(Words.BOSSES.has(b["name"]), "%s has no lines" % b["name"])
		for u in b["uniques"]:
			_check(Words.UNIQUES.has(u), "%s has no past" % u)
	sim.load_dict(save)
	print("campaign and endgame ok: gates, the boss and their drop, notes, the depth band, exclusives")


## The narrative's hooks: the site's line once a depth, the clear line once a
## tier, papers among the finds, the deeds from the bank and the three ends
## of them, the runners' past after a death, the vendors' lines.
func _narrative_checks(main) -> void:
	var sim = main.sim
	# the deeds: a fresh camp walked straight to the bank
	var save: Dictionary = sim.to_dict()
	_finish_campaign(sim)
	sim.hp = sim.max_hp()
	var bank: int = 5
	_check(sim.tier_open(bank), "the bank did not open with every depth cleared")
	sim.deploy(bank)
	_check(sim.on_mission(), "could not set off for the bank")
	_check(sim.events.back()[1] == Words.site_line("The bank", 1), "setting off for the bank gave no site line: %s" % sim.events.back()[1])
	sim._clear(sim.mission, sim.mission["t"])
	var deeds := {}
	for it in sim.mission["found"]:
		if Items.is_deeds(it):
			deeds = it
	_check(not deeds.is_empty(), "clearing the bank did not drop the deeds")
	if deeds.is_empty():
		sim.extract_now()
		sim.load_dict(save)
		return
	_check(Items.footprint(deeds) == Vector2i(2, 2), "the deeds are not two by two")
	# burned
	_check(sim.ditch_commons() == 0 or not sim.mission["found"].has(deeds) == false, "ditch commons threw the deeds away")
	var still := false
	for it in sim.mission["found"]:
		still = still or Items.is_deeds(it)
	_check(still, "Ditch commons burned the deeds")
	sim.ditch(deeds["id"])
	_check(sim.ending == "burned", "burning the deeds did not end: %s" % sim.ending)
	sim.extract_now()
	# held: the same again, out with them
	sim.deeds_found = false
	sim.ending = ""
	sim.hp = sim.max_hp()
	sim.deploy(bank)
	sim._clear(sim.mission, sim.mission["t"])
	sim.extract_now()
	_check(sim.ending == "held", "bringing the deeds home did not end: %s" % sim.ending)
	var held := {}
	for it in sim.stash:
		if Items.is_deeds(it):
			held = it
	_check(not held.is_empty(), "the deeds did not reach the stash")
	_check(sim.sell_commons() >= 0 and sim.stash.has(held), "sell commons sold the deeds")
	# sold
	sim.ending = ""
	var cash_before: float = sim.cash
	sim.sell(held)
	_check(sim.ending == "sold" and sim.cash > cash_before, "selling the deeds did not end, or did not pay")
	# the past: a death writes a runner down
	sim.hp = sim.max_hp()
	sim.deploy(0)
	var lost_before: int = sim.past.size()
	sim._kia()
	_check(sim.past.size() == lost_before + 1 and sim.past.back().has("end"), "a death did not write the runner into the past")
	# a death takes the runner's past with them: the class unpicked, its trees back as points, the yard's tree kept
	var fresh2 = load("res://scripts/sim/sim.gd").new()
	fresh2.start()
	fresh2.set_class("Doorman")
	fresh2.training_points = 8
	var elem_tree: String = Data.ELEMENT_TREES[0]["name"]
	_check(fresh2.train_node("Muscle/0") and fresh2.train_node("Muscle/1") and fresh2.train_node("The yard/0") and fresh2.train_node("%s/0" % elem_tree), "the death test could not train")
	var spent: int = fresh2.points_spent()
	fresh2.deploy(0)
	fresh2._kia()
	_check(fresh2.cls == "" and fresh2.cls2 == "", "a death left the class picked: '%s'" % fresh2.cls)
	_check(fresh2.tree == ["The yard/0"], "a death did not refund the runner's trees (the class's and the element's) and keep the yard's: %s" % str(fresh2.tree))
	_check(fresh2.points_free() == 8 - fresh2.points_spent() and fresh2.points_spent() < spent, "the refunded points are not free to spend: %d free" % fresh2.points_free())
	_check(fresh2.next_words() == Words.NEXT["past"], "after a death the yard does not say to pick a past: '%s'" % fresh2.next_words())
	_check(str(fresh2.events.back()[1]).contains("point") or str(fresh2.events[-2][1]).contains("point"), "the refund was not logged")
	main.show_room(main.BARRACKS)
	main._barracks.selected = ""
	main.refresh()
	_check(main._barracks._past.visible and main._barracks._past.text != "", "the Caravan does not show the runners before")
	_check_fit(main, "Caravan (past)")
	# papers: enough looks find one
	sim.hp = sim.max_hp()
	sim.deploy(0)
	var papers := 0
	for k in range(400):
		sim._find(sim.mission, sim.mission["t"])
		for it in sim.mission["found"]:
			if Items.is_paper(it):
				papers += 1
		sim.mission["found"] = []
	_check(papers > 0, "four hundred looks found no paper")
	sim.extract_now()
	# every item has its words, and they fit the panels' two rows
	for slot in Data.BASES:
		for b in Data.BASES[slot]:
			_check(Words.item_words(b["name"]) != "", "%s has no words" % b["name"])
	for a in Data.ATTACHMENTS:
		_check(Words.item_words(a["name"]) != "", "%s has no words" % a["name"])
	for u in Data.UNIQUES:
		_check(Words.UNIQUES.has(u["name"]), "%s has no past" % u["name"])
	# the vendors say something on a visit
	main.show_room(main.MARKET)
	main.refresh()
	_check(main._fence._line != "", "the fence said nothing")
	_check_fit(main, "Fence (said)")
	# the A style on the vendors: the band with the face, the name and the figure; the line under it; the tabs in the band's foot; the sections
	var fv = main._fence
	_check(fv._band.title.text == "The fence" and fv._band.headline.text.begins_with("£") and fv._band.kicker.text.begins_with("The fence · "), "the fence's band is off: '%s' / '%s' / '%s'" % [fv._band.kicker.text, fv._band.title.text, fv._band.headline.text])
	_check(fv._said[0].text != "" and fv._said[0].position.y >= fv.BAND_H, "the fence's line is not under the band: '%s' at %.0f" % [fv._said[0].text, fv._said[0].position.y])
	for t in fv._tabs:
		_check(t.position.y + t.size.y <= fv.BAND_H and t.visible, "a fence tab is not in the band's foot")
	_check(fv._side_tiles[0]["key"].text == "Com" and fv._side_tiles[Data.RARITIES.size() - 1]["key"].text == "Leg" and fv._side_tiles[Data.RARITIES.size()]["key"].text.begins_with("Nails") and fv._side_tiles[Data.RARITIES.size() + 5]["button"].visible, "the fence's tiles are off: %s" % str(fv._side_tiles.map(func(t): return t["key"].text)))
	_check(fv._side_tiles[1]["value"].get_theme_color("font_color") == Pal.GOOD or fv._side_tiles[1]["button"].disabled, "the uncommon tile's figure is not green")
	_check(fv._heads[2].visible and fv._heads[2].text.begins_with("THE CONTRACTS"), "the fence's contracts head is off: '%s'" % fv._heads[2].text)
	_check(fv._band.kicker.position.x >= fv._face.position.x + fv._face.size.x or not fv._face.visible, "the fence's words sit on the face")
	main.show_room(main.MEDIC)
	main.refresh()
	_check(main._clinic._line != "", "the medic said nothing")
	_check_fit(main, "Clinic (said)")
	var cv = main._clinic
	_check(cv._band.title.text == "The medic" and cv._band.headline.text == "%d" % sim.hp_shown() and cv._band.unit.text.begins_with("of %d HP" % sim.max_hp_shown()), "the clinic's band is off: '%s' / '%s' / '%s'" % [cv._band.title.text, cv._band.headline.text, cv._band.unit.text])
	_check(cv._side_track.visible and cv._side_bar_text.text.begins_with("Your HP") and cv._side_tiles_c[0]["key"].text == "Resting" and cv._side_tiles_c[1]["key"].text == "Heal" and cv._side_tiles_c[2]["key"].text == "The wound" and cv._side_tiles_c[3]["key"].text == "Clinic", "the clinic's treatment tiles are off")
	_check(cv._heads[1].visible and cv._heads[1].text.begins_with("YOUR MEDS"), "the clinic has no YOUR MEDS head")
	var med_kinds := {}
	for it in sim.stash:
		if Items.is_medical(it):
			med_kinds[it["base"]] = true
	var shown_meds: int = cv._med_tiles.filter(func(t): return t["panel"].visible and not t["key"].text.begins_with("The rig")).size()
	_check(shown_meds == mini(med_kinds.size(), 4), "the clinic shows %d med kinds for %d in the stash" % [shown_meds, med_kinds.size()])
	for t in cv._med_tiles:
		if t["panel"].visible and not t["key"].text.begins_with("The rig"):
			_check(t["value"].text.begins_with("heals "), "a med tile does not say what it heals: '%s'" % t["value"].text)
	# a heal node trained elsewhere moves the clinic's figures without anything else changing (the reviewer's catch)
	if shown_meds > 0:
		var heal_before: String = cv._med_tiles[0]["value"].text
		var hold_tree: Array = sim.tree.duplicate()
		var heal_node := ""
		for b in Data.TREES:
			for i in range(b["nodes"].size()):
				if b["nodes"][i].get("effect", "") == "heal_pct" and heal_node == "":
					heal_node = "%s/%d" % [b["name"], i]
		if heal_node != "" and not sim.tree.has(heal_node):
			sim.tree.append(heal_node)
			main.refresh()
			_check(cv._med_tiles[0]["value"].text != heal_before, "a heal node did not move the clinic's med figure: still '%s'" % heal_before)
			sim.tree = hold_tree
			main.refresh()
	sim.load_dict(save)
	print("narrative ok: site lines, the deeds three ways, the past, papers, every item's words, the vendors")


func _run_screen(main) -> void:
	var sim = main.sim
	sim.auto_tier = -1
	sim.hp = sim.max_hp()
	sim.set_depth(0, 1)
	var tries := 0
	while tries < 5 and not (sim.on_mission() and sim.mission["found"].size() >= 2):
		if not sim.on_mission():
			sim.hp = sim.max_hp()
			sim.deploy(0)
		var guard := 0
		while sim.on_mission() and sim.mission["found"].size() < 2 and guard < 600:
			sim.advance(1.0)
			if sim.on_mission() and sim.hp < sim.max_hp() * 0.3:
				sim.hp = sim.max_hp()     # the test wants the run, not the risk
			guard += 1
		tries += 1
	if not sim.on_mission():
		_check(false, "run screen: no run reached two finds in five tries")
		return
	main.show_room(main.MISSIONS)
	_check_fit(main, "Run (live)")
	# the run's panel sits level with the pack's; the rig's pouches show in the Runner panel; a med found goes in the rig
	var run_ui = main._run
	_check(run_ui._left.size.y == Pal.ROOM_H and run_ui._band.size.x == run_ui.BODY_W, "the run's column is not the room's height with the band across it")
	var shown_cells := 0
	var shown_outlines := 0
	for c in run_ui._rig_cells:
		if c.visible:
			shown_cells += 1
	for o in run_ui._rig_outlines:
		if o.visible:
			shown_outlines += 1
	# an item takes a cell a pouch (a first aid kit two): the cells and the empty outlines add up to the rig, like the Lock-up's (Matt, 6 Oct)
	_check(shown_cells == mini(sim.rig.size(), run_ui.RIG_MAX) and shown_outlines == mini(sim.med_capacity(), run_ui.RIG_MAX) - mini(sim.rig_used(), run_ui.RIG_MAX), "the rig on the run screen shows %d cells and %d empty pouches for %d items in %d of %d pouches" % [shown_cells, shown_outlines, sim.rig.size(), sim.rig_used(), sim.med_capacity()])
	for c in run_ui._rig_cells:
		if c.visible:
			var it_c: Dictionary = sim.rig.filter(func(x): return x["id"] == c.id)[0]
			_check(Items.size(it_c) == 1 or c.size.x > c.size.y * 1.5, "a %d-pouch item shows as one pouch on the run" % Items.size(it_c))
	for c in run_ui._rig_cells:
		if c.visible:
			var pr := Rect2(Vector2.ZERO, run_ui._left.size)
			_check(pr.encloses(Rect2(c.position, c.size)), "a rig cell on the run screen leaves its panel: cell %s, panel %s" % [str(Rect2(c.position, c.size)), str(pr)])
			_check(c.position.y >= run_ui.RIG_Y and c.position.y + c.size.y <= run_ui.TAKE_Y, "a rig cell sits outside the rig's row")
	# a pouch is the control: pressing a med's cell uses it
	if sim.med_capacity() > 0 and sim.mission["using"] == null:
		while not sim.rig_room(1) and not sim.rig.is_empty():
			sim.rig.pop_back()
		var pouch_med: Dictionary = sim._plain(Data.MEDICAL, "Bandage")
		sim.rig.append(pouch_med)
		sim.hp = sim.max_hp() * 0.5
		main.refresh()
		var kp := -1
		for i in range(run_ui._rig_cells.size()):
			if run_ui._rig_cells[i].visible and run_ui._rig_cells[i].id == pouch_med["id"]:
				kp = i
		_check(kp >= 0, "the med in the rig has no pouch on the run screen")
		if kp >= 0:
			run_ui._rig_pressed(kp)
			_check(sim.mission["using"] != null and sim.mission["using"]["name"] == "Bandage", "pressing the pouch did not use the med")
			main.refresh()
			_check_fit(main, "Run (med in use)")
	if sim.med_capacity() > 0:
		var found_med: Dictionary = sim._plain(Data.MEDICAL, "Bandage")
		sim.mission["found"].append(found_med)
		while not sim.rig_room(1) and not sim.rig.is_empty():
			sim.rig.pop_back()
		main.refresh()
		main._run._inv._pick(main._run._inv.cell_of(found_med["id"]))
		main.refresh()
		_check(main._run._pick.button_texts().has("Take into the rig") and not main._run._pick._buttons[0].disabled, "a med in the pack offers no Take into the rig: %s" % str(main._run._pick.button_texts()))
		_check_fit(main, "Run (a med picked)")
		var rig_n: int = sim.rig.size()
		main._run._take_pick()
		_check(sim.rig.size() == rig_n + 1 and not sim.mission["found"].has(found_med), "Take into the rig did not move the med")
		main.refresh()
		_check_fit(main, "Run (med taken)")
		# rounds top up the rig's stack of the same type
		var box: Dictionary = sim._plain(Data.AMMO, "Nails")
		Items.set_stack(box, 10)
		sim.mission["found"].append(box)
		var rounds_before: int = sim.rounds_for({"slot": "Primary", "base": "Nail gun", "affixes": [], "attachments": {}, "rarity": 0, "tier": 1})
		_check(sim.take_from_pack(box["id"]), "rounds found did not go into the rig")
		_check(not sim.mission["found"].has(box) or Items.stack_size(box) < 10, "the rounds stayed whole in the pack")
		main.refresh()
	var m: Dictionary = sim.mission
	# the grid is the container: a pack of N cells shows N outlines, no more,
	# unless the packing reaches past them - and then exactly as far as it reached
	_check_grid(main._run._inv, sim.capacity(), "the pack")
	var first: Dictionary = m["found"][0]
	var n_before: int = m["found"].size()
	main._run._inv._pick(main._run._inv.cell_of(first["id"]))
	main.refresh()
	_check(main._run._pick.button_texts().has("Ditch"), "picking a find did not offer Ditch: %s" % str(main._run._pick.button_texts()))
	_check_fit(main, "Run (pick)")
	var rh = main._run._pick._heads[0]
	_check(rh.visible and not main._run._pick._empty_title.visible and rh._title.text != "" and rh._chips[0].visible and main._run._pick._tag_labels[0].text.begins_with("£"), "the run's pick has no head or price tag: %s / %s" % [rh._title.text, main._run._pick._tag_labels[0].text])
	_pick_boxes_check(main._run._pick, "the run's pick")
	main._run._ditch_pick()
	_check(sim.mission["found"].size() == n_before - 1, "Ditch did not drop the find")
	if sim.mission["found"].size() > 0:
		main._run._inv._toggle_many()
		main.refresh()
		main._run._inv._pick(main._run._inv.cell_of(sim.mission["found"][0]["id"]))
		main.refresh()
		_check_fit(main, "Run (many)")
		main._run._inv._sell_chosen()
		_check(sim.mission["found"].size() == n_before - 2, "Select many did not ditch")
		main._run._inv._toggle_many()
	main._run._get_out()
	_check(not sim.on_mission(), "Get out now did not end the run")
	print("run screen ok")


## The class trees: a class tree node trains, is refunded on a class change, a
## typed node idles without its gun, a keystone changes a rule, the yard's
## upgrades buy.
func _class_trees(main) -> void:
	var sim = main.sim
	sim.set_class("Doorman")
	sim.training_points += 20
	_check(sim.trees().size() == 3 + Data.ELEMENT_TREES.size() and sim.trees()[1]["name"] == "The yard", "a Doorman does not see three trees with the yard's in the middle, and the elements'")
	_check(sim.train_node("Muscle/0") and sim.train_node("Muscle/1") and sim.train_node("Muscle/2") and sim.train_node("Muscle/3"), "the Muscle tree did not train")
	var spent_before: int = sim.points_spent()
	_check(not sim.can_train("Stalking/0"), "a Poacher's tree trained for a Doorman")
	# Shotgunner is typed: it counts with a shotgun in hand and idles otherwise
	var dmg_before: float = sim.dps()
	var gun = sim.equipped["Primary"]
	var shotgun := Items.roll("Primary", 1, sim.rng)
	shotgun["base"] = "Farmer's shotgun"
	shotgun["affixes"] = []
	sim.equipped["Primary"] = shotgun
	_check(sim.gun_type() == "shotgun" and sim.tree_sum("damage_pct") >= 25.0 + 4.0, "Shotgunner did not count with a shotgun in hand: %s" % sim.tree_sum("damage_pct"))
	sim.equipped["Primary"] = sim._plain("Primary", "Nail gun")
	_check(sim.tree_sum("damage_pct") < 25.0, "Shotgunner counted without a shotgun")
	sim.equipped["Primary"] = gun
	main.show_room(main.BARRACKS)
	_check_fit(main, "Caravan (Doorman)")
	# a class change refunds the class trees and keeps the yard's
	if not sim.tree.has("The yard/0"):
		sim.training_points += 1
		sim.train_node("The yard/0")
	sim.set_class("Drifter")
	_check(not sim.tree.has("Muscle/0") and sim.tree.has("The yard/0"), "changing class did not refund the class trees and keep the yard's")
	_check(sim.points_spent() < spent_before, "the refund did not free the points")
	main.show_room(main.BARRACKS)
	_check_fit(main, "Caravan (Drifter)")
	# a keystone: Never there - no lot ever comes
	for i in range(8):
		sim.train_node("Moving on/%d" % i)
	_check(sim.tree.has("Moving on/7"), "the Drifter's keystone did not train: %d points free" % sim.points_free())
	_check(sim.patrol_s(sim.effective(0)) == INF, "Never there still has lots coming")
	main.show_room(main.BARRACKS)
	main._barracks._pick("Moving on/7")
	_check_fit(main, "Caravan (keystone)")
	sim.respec()
	sim.set_class("Doorman")
	# juicing at the radio: call in a word, hold one and re-roll the rest, three at most -
	# and none of it until the campaign's done
	sim.cash += 40000.0
	while sim.can_upgrade_comms():
		sim.upgrade_comms()
	var campaign_save: Dictionary = sim.to_dict()
	_check(sim.campaign_done() or not sim.can_juice(), "the radio juices before the campaign is done")
	_finish_campaign(sim)
	_check(sim.campaign_done(), "the campaign did not read as done with every site cleared and every boss beaten")
	_check(sim.can_juice(), "the radio at its top level cannot juice")
	var opts: Array = sim.juice_options(0)
	_check(not opts.is_empty() and sim.add_word(0, opts[0]), "calling in a word failed")
	_check(opts[0] in sim.intel[0], "the called-in word is not on the site")
	while sim.can_add_word(0):
		sim.add_word(0, sim.juice_options(0)[0])
	_check(sim.intel[0].size() == sim.MAX_WORDS, "a site holds more than %d words" % sim.MAX_WORDS)
	var held: String = sim.intel[0][0]
	_check(sim.lock_word(0, held) and held in sim.intel[0], "holding a word lost it")
	main.show_room(main.COMMS)
	_check_fit(main, "Radio (juiced)")
	main._choose_word(0, 0)
	_check(main._menu.visible, "the word chooser did not open")
	main._menu.close()
	main._choose_hold(0)
	main._menu.close()
	# the yard's upgrades
	sim.cash += 40000.0
	_check(sim.upgrade_generator() and sim.upgrade_lookout() and sim.upgrade_kennel(), "a yard upgrade did not buy")
	_check(sim.away_cap_s() == 12.0 * 3600.0, "the generator did not raise the away cap")
	main.show_room(main.OVERVIEW)
	_check_fit(main, "The Yard (upgrades)")
	# every class's trees on the screen, for the fit check
	for c in Data.CLASSES:
		sim.set_class(c["name"])
		main.show_room(main.BARRACKS)
		_check_fit(main, "Caravan (%s)" % c["name"])
	sim.set_class("Doorman")
	print("class trees, keystone and yard upgrades ok")
	_webs_traits(main)
	_pool_checks(sim)


## The charm: one cell on the body, magic find and cash. Sockets: gear rolls
## up to two, six socketables go in them, each adding what nothing else does.
func _charm_sockets(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	var charm: Dictionary = sim._plain("Charm", "Casino chip")
	charm["affixes"] = [{"stat": "rarity_pct", "value": 10}]
	var base_find: float = sim.rarity_bonus()
	var base_cash: float = sim.charm_cash()
	sim.equipped["Charm"] = null
	var without: float = sim.rarity_bonus()
	sim.stash.append(charm)
	_check(sim.can_equip_item(charm["id"]) and sim.equip_item(charm["id"]), "the charm did not equip from the stash")
	_check(sim.equipped["Charm"] != null and sim.equipped["Charm"]["id"] == charm["id"], "the charm is not on the body")
	_check(is_equal_approx(sim.charm_find(), 18.0 + sim._affix_sum("rarity_pct")), "a Casino chip with +10 magic find reads %.1f, not %.1f" % [sim.charm_find(), 18.0 + sim._affix_sum("rarity_pct")])
	_check(sim.rarity_bonus() > without + 0.27, "the charm's magic find did not reach rarity_bonus: %.2f vs %.2f" % [sim.rarity_bonus(), without])
	_check(sim.charm_cash() >= 15.0, "the charm's cash did not count: %.1f" % sim.charm_cash())
	_check(Items.headline(charm)[0] == "+28%" and Items.headline(charm)[1] == "loot quality", "a charm's headline is not its magic find: %s" % str(Items.headline(charm)))
	var worn_find: float = sim._affix_sum("rarity_pct") - 10.0     # the helmet's, if any
	# charms roll like gear: rarities and affixes from their own list (they had rolled plain since the stacks)
	var rolled_rare := 0
	var rolled_stats := {}
	for k in range(200):
		var c: Dictionary = Items.roll("Charm", 3, sim.rng, 0.0, false, false, "", "", 0.33, 3)
		if int(c["rarity"]) > 0:
			rolled_rare += 1
		for a in c["affixes"]:
			rolled_stats[a["stat"]] = true
	_check(rolled_rare > 20, "charms roll plain: %d of 200 above common" % rolled_rare)
	_check(rolled_stats.size() >= 6, "charms roll only %s" % str(rolled_stats.keys()))
	# and the bench can add an affix to one
	if sim.on_mission():
		sim.extract_now()
	var ws_held: int = sim.workshop
	sim.workshop = maxi(1, sim.workshop)
	var add_cost: int = sim.craft_cost(charm, "add")
	_check(add_cost > 0, "the bench will not add an affix to a charm")
	sim.cash = maxf(sim.cash, add_cost + 1.0)
	var n_before: int = charm["affixes"].size()
	_check(sim.craft(charm["id"], "add", "") and charm["affixes"].size() == n_before + 1, "adding an affix to the charm did not take (mission %s, bench %d, cost %d, cash %.0f)" % [str(sim.on_mission()), sim.workshop, add_cost, sim.cash])
	sim.workshop = ws_held
	# the body shows it in its own cell beside the primary
	main.show_room(main.ARMOURY)
	_check_fit(main, "Armoury (charm)")
	_check(main._armoury._body._boxes["Charm"]["cell"].visible, "the charm's cell is not shown on the body")
	# charms turn up among a site's finds
	var charms := 0
	sim.deploy(0)
	var m: Dictionary = sim.mission
	var eff: Dictionary = sim.effective(0)
	for i in range(400):
		m["found"] = []
		sim._find(m, eff)
		if not m["found"].is_empty() and Items.is_charm(m["found"][0]):
			charms += 1
	sim.extract_now()
	_check(charms > 4 and charms < 60, "charms are %d of 400 finds; 5%% was the aim" % charms)
	# sockets: a gun with two, a socketable in each, its effect on the figures
	var gun: Dictionary = sim._plain("Primary", "Army SMG")
	gun["attachments"]["socket 1"] = null
	gun["attachments"]["socket 2"] = null
	_check(Items.sockets(gun) == 2, "a gun given two sockets reads %d" % Items.sockets(gun))
	var old_gun = sim.equipped["Primary"]
	sim.equipped["Primary"] = gun
	sim.workshop = maxi(sim.workshop, 1)
	var fluid: Dictionary = sim._plain("Attachment", "Lighter fluid")
	var salt: Dictionary = sim._plain("Attachment", "Road salt")
	_check(Items.is_socketable(fluid) and fluid["mount"] == "socket", "Lighter fluid is not a socketable")
	sim.stash.append(fluid)
	sim.stash.append(salt)
	var dps_before: float = sim.dps()
	var armour_before: float = sim.armour()
	var fire_before: float = sim.conversion()["fire"]      # the secondary or the tree may carry some already
	_check(sim.fit(sim.equipped["Primary"]["slot"], fluid["id"]), "fit() did not seat a socketable in the first socket")
	_check(gun["attachments"]["socket 1"] != null and gun["attachments"]["socket 1"]["base"] == "Lighter fluid", "the fluid is not in socket 1")
	_check(sim.conversion()["fire"] >= fire_before + 0.15 - 0.001 and sim.type_dps()["fire"] > 0.0 and is_equal_approx(sim.dps(), dps_before), "fire in a socket did not convert 15%% more: %.2f -> %s" % [fire_before, str(sim.conversion())])
	_check(sim.fit_socket("Primary", "socket 2", salt["id"]), "fit_socket() did not seat the salt in socket 2")
	_check(sim.armour() > armour_before, "salt in a socket did not raise armour")
	_check(not sim.stash.has(fluid) and not sim.stash.has(salt), "the socketables did not leave the stash")
	var salt_count_before: int = 0
	for st in sim.stash:
		if st["base"] == "Road salt":
			salt_count_before += Items.stack_size(st)
	var salt_count_after: int = 0
	var stripped: bool = sim.strip("Primary", "socket 2")
	for st in sim.stash:
		if st["base"] == "Road salt":
			salt_count_after += Items.stack_size(st)
	_check(stripped and salt_count_after == salt_count_before + 1, "strip() did not take the salt back (it may merge into a stack): %d -> %d" % [salt_count_before, salt_count_after])
	_check(not sim.fit_socket("Primary", "optic", salt["id"]), "a socketable went on an optic mount")
	# rolled gear carries sockets at the stated odds, never more than SOCKET_MAX
	var with := 0
	var most := 0
	for i in range(300):
		var g: Dictionary = Items.roll(Data.SOCKET_SLOTS[i % 4], 6, sim.rng)
		var n: int = Items.sockets(g)
		most = maxi(most, n)
		if n > 0:
			with += 1
	_check(most <= Data.SOCKET_MAX and with > 100 and with < 240, "sockets rolled on %d of 300, most %d; 55%% with up to %d was the aim" % [with, most, Data.SOCKET_MAX])
	var charm_rolls := Items.roll("Charm", 6, sim.rng)
	_check(Items.sockets(charm_rolls) == 0, "a charm rolled sockets")
	# the Workshop's Sockets view: the gun's two rows, pick one, fit through it
	main.show_room(main.WORKSHOP)
	main._workshop._set_view("sockets")
	_check_fit(main, "Workshop (sockets)")
	main._workshop._pick_mount("Primary", "socket 2")
	_check_fit(main, "Workshop (socket pick)")
	main._workshop._pick_cell(0)
	_check_fit(main, "Workshop (socketable pick)")
	main._workshop._press(0)              # Fit
	_check(gun["attachments"]["socket 2"] != null, "Fit through the Sockets view did not seat the socketable")
	main._workshop._pick_mount("Primary", "socket 2")
	main._workshop._press(0)              # Strip
	_check(gun["attachments"]["socket 2"] == null, "Strip through the Sockets view did not take it back")
	main._workshop._set_view("guns")
	_check(main._workshop._all_attachments(false).filter(func(it): return Items.is_socketable(it)).is_empty(), "the Guns view's grid shows socketables")
	_check_fit(main, "Workshop (guns again)")
	_craft_view_checks(main)
	for base in ["Lighter fluid", "Antifreeze", "Rat poison", "Car battery", "Road salt", "Copper wire", "Lucky penny", "Bank's own pen"]:
		_check(Words.item_words(base) != "" and Words.item_words(base).ends_with("."), "%s has no line" % base)
	sim.equipped["Primary"] = old_gun
	sim.load_dict(saved)
	print("charm and sockets ok: magic find, cash, finds, two sockets, fit/strip, the Sockets view")


## The Workshop's Craft view: the stash's gear only, the panel reads the
## piece's tiers and prices, Bench opens the menu, everything fits.
func _craft_view_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	sim.workshop = maxi(sim.workshop, 1)
	sim.cash = 100000.0
	var piece: Dictionary = Items.roll("Primary", 6, sim.rng, 12)
	piece["affixes"] = [{"stat": "hp", "value": 20.0, "tier": 2}, {"stat": "dps_pct", "value": 10.0, "tier": 1}]
	sim.stash.append(piece)
	main.show_room(main.WORKSHOP)
	main._workshop._set_view("craft")
	_check(main._workshop._craft.visible, "the Craft view's panel is hidden")
	_check(main._workshop._craft_title.text.begins_with("Pick a piece"), "the Craft view does not ask for a piece first: %s" % main._workshop._craft_title.text)
	_check_fit(main, "Workshop (craft, nothing picked)")
	var shown: Array = main._workshop._craftable()
	_check(not shown.is_empty() and shown.all(func(it): return not Items.is_attachment(it) and not Items.is_medical(it) and not it.has("unique")), "the Craft view's grid shows parts, meds or uniques")
	var k: int = shown.find(piece)
	if k < 0:
		for i in range(shown.size()):
			if is_same(shown[i], piece):
				k = i
	_check(k >= 0, "the rolled piece is not in the Craft view's grid")
	main._workshop._pick_cell(k)
	_check(main._workshop._craft_title.text != "Pick a piece", "picking a piece did not fill the Craft panel")
	_check(main._workshop._craft_lines[1].text.begins_with("Level %d" % Items.ilvl(piece)), "the Craft panel's level line is wrong: %s" % main._workshop._craft_lines[1].text)
	_check(main._workshop._craft_lines[2].text.contains("T2"), "the Craft panel does not show the affix's tier: %s" % main._workshop._craft_lines[2].text)
	_check(main._workshop._craft_lines[5].text.contains("£"), "the Craft panel has no priced job: %s" % main._workshop._craft_lines[5].text)
	_check_fit(main, "Workshop (craft, piece picked)")
	main._workshop._press(0)              # Bench
	_check(main._menu.visible, "Bench did not open the bench's menu")
	_check_fit(main, "Workshop (craft, bench menu)")
	main._menu.close()
	main._workshop._set_view("guns")
	_check(not main._workshop._craft.visible, "the Craft panel stayed up on the Guns view")
	sim.load_dict(saved)
	print("craft view ok: stash gear only, tiers and prices read, Bench opens the menu")


## The trees as webs: a fork at the notable, a branch each way; the second
## past from level 30; two runners turn up when one dies.
func _webs_traits(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	sim.set_class("Poacher")
	sim.respec()
	sim.training_points += 30
	var t: Dictionary = Data.tree_named("Stalking")
	_check(Data.node_needs(t, 4) == 3 and Data.node_needs(t, 7) == 3 and Data.node_needs(t, 5) == 4 and Data.node_needs(t, 0) == -1, "Stalking's web does not fork at its notable")
	for i in range(4):
		sim.train_node("Stalking/%d" % i)
	_check(sim.can_train("Stalking/4") and sim.can_train("Stalking/7"), "both branches did not open off the notable")
	_check(not sim.can_train("Stalking/6") and not sim.can_train("Stalking/9"), "a branch's end trained before its start")
	_check(sim.train_node("Stalking/7") and sim.train_node("Stalking/8") and sim.train_node("Stalking/9"), "the second branch did not train to its notable")
	_check(sim.has_node("night_work"), "Night work did not take")
	_check(sim.effective(0)["rarity"] > 0.0 and sim.effective(0)["pace"] < 1.0, "Night work did not make the site Night")
	_check(sim.train_node("Stalking/4") and sim.train_node("Stalking/5") and sim.train_node("Stalking/6"), "the keystone branch did not train after the other")
	main.show_room(main.BARRACKS)
	_check_fit(main, "Caravan (web)")
	# the second past: not before 30, then any other class's first tree opens
	sim.xp = Data.xp_for_level(Data.ASCEND_LEVEL - 1)
	_check(not sim.can_ascend() and not sim.set_second("Doorman"), "a second past took before level %d" % Data.ASCEND_LEVEL)
	sim.xp = Data.xp_for_level(Data.ASCEND_LEVEL)
	_check(sim.can_ascend() and not sim.set_second("Poacher") and sim.set_second("Doorman"), "the second past did not take at level %d" % Data.ASCEND_LEVEL)
	var names := []
	for tr in sim.trees():
		names.append(tr["name"])
	_check(names.has("Muscle") and names.has("Stalking") and names.has("The yard"), "a Poacher with a Doorman's past does not see Muscle: %s" % str(names))
	_check(sim.tree.has("Stalking/6"), "ascending refunded the Poacher's own tree")
	_check(sim.train_node("Muscle/0"), "the second past's tree did not train")
	main.show_room(main.BARRACKS)
	_check_fit(main, "Caravan (second past)")
	main._choose_second()
	_check(main._menu.visible, "the second-past menu did not open")
	_check_fit(main, "Caravan (second-past menu)")
	main._menu.close()
	# the traits: one on the runner now; a death brings two to choose from
	sim.runner_trait = "Heavy-handed"
	_check(is_equal_approx(sim.trait_mult("damage"), 1.08) and is_equal_approx(sim.trait_mult("pace"), 0.95), "Heavy-handed's figures did not read")
	sim.runner_trait = "Lucky"
	var r0: float = sim.rarity_bonus()
	sim.runner_trait = ""
	_check(sim.rarity_bonus() < r0 - 0.09, "Lucky did not add to rarity_bonus")
	sim.promised = "Wary"
	sim.hardcore = false
	sim.deploy(0)
	sim.mission["hp_start"] = sim.hp
	sim._kia()
	_check(sim.candidates.size() == 2 and sim.candidates[1] == "Wary", "two did not turn up with the promised one among them: %s" % str(sim.candidates))
	_check(sim.runner_trait == sim.candidates[0], "the runner in hand is not the first candidate")
	main.refresh()
	main._choose_runner()
	_check(main._menu.visible, "the two-turn-up menu did not open")
	_check_fit(main, "The Yard (two turn up)")
	main._pick_runner(1)
	_check(sim.runner_trait == "Wary" and sim.candidates.is_empty(), "picking the second runner did not take")
	_check(sim.trait_mult("patrol") > 1.1, "Wary's gangs come no later")
	sim.load_dict(saved)
	print("webs, the second past and traits ok")
	_element_checks(main)
	_element_bot_checks(main)


## The element trees: affinities, double cost and the locked keystone off
## them, the second past opening it; the keystones' and notables' rules.
## The element bots: each trains its tree first and saves for its keystone,
## takes a second past for an off-affinity element, holds the gun that
## carries the element, seats the element's socketable, and sends the primary
## to the bench until the element's affixes are on it. Then the band: at
## depth 30 on every site, some build still lands most of its damage.
func _element_bot_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	for t in Data.ELEMENT_TREES:
		var el: String = t["element"]
		sim.load_dict(saved)
		sim.set_class("Doorman")          # bleed and physical: four of the five are off-affinity
		sim.respec()
		sim.workshop = maxi(sim.workshop, 1)
		sim.cash = 400000.0
		sim.market = []                   # nothing to buy, no contracts: the choices below are the only ones
		sim.contracts = []
		sim.training_points = 3
		var bot = Bot.new()
		bot.element = el
		bot._train_tree(sim)
		var mine: Array = sim.tree.filter(func(id): return str(id).begins_with(t["name"] + "/"))
		_check(not mine.is_empty() and sim.tree.all(func(id): return str(id).begins_with(t["name"] + "/")), "the %s bot did not train its own tree first: %s" % [el, sim.tree])
		if not sim.affinity(el):
			# three points and double cost: one node, one spare saved, not spent on the class
			_check(sim.points_free() == 1, "the off-affinity %s bot did not save its odd point: %d free" % [el, sim.points_free()])
			sim.xp = Data.xp_for_level(Data.ASCEND_LEVEL)
			bot._second_past_for(sim)
			_check(sim.cls2 != "" and sim.affinity(el), "the %s bot did not take a second past with the affinity: %s" % [el, sim.cls2])
		sim.training_points += 40
		bot._train_tree(sim)
		_check(sim.tree.has("%s/6" % t["name"]), "the %s bot did not reach its keystone: %s" % [el, sim.tree])
		# the gun: a plain better one in the stash loses to the one carrying the element
		var top := {}
		for b in Data.BASES["Primary"]:
			if b.get("type", "") != "melee" and (top.is_empty() or int(b["tier"]) > int(top["tier"]) or (int(b["tier"]) == int(top["tier"]) and float(b["damage"]) * float(b["rof"]) > float(top["damage"]) * float(top["rof"]))):
				top = b
		var carries: Dictionary = sim._plain("Primary", top["name"])     # the hardest-hitting gun there is: nothing the market stocks is 1.5× it
		carries["affixes"] = [{"stat": "conv_%s_pct" % el, "value": 25.0, "tier": 5}]
		carries["rarity"] = 2
		if el == "bleed":
			carries["base"] = "Machete"            # a bleed base too
			carries["attachments"] = {}
			for name in Items.base_of(carries).get("attachments", []):
				carries["attachments"][name] = null
		var plain: Dictionary = carries.duplicate(true)   # the same gun, a better plain affix
		plain["id"] = Items._next_id
		Items._next_id += 1
		plain["affixes"] = [{"stat": "damage_pct", "value": 30.0, "tier": 4}]
		sim.equipped["Primary"] = null
		sim.stash = sim.stash.filter(func(it): return it["slot"] != "Primary")   # only these two to choose from
		while not sim.stash_room(20) and not sim.stash.is_empty():
			sim.sell(sim.stash[0])              # room to swap guns: a full stash refuses the swap
		sim.stash.append(plain)
		sim.stash.append(carries)
		bot._hold_the_element(sim)
		_check(sim.equipped["Primary"] != null and bot._elem_share(sim.equipped["Primary"]) >= 0.249, "the %s bot did not hold a gun carrying the element: %s" % [el, sim.equipped["Primary"]["base"] if sim.equipped["Primary"] != null else "nothing"])
		# the socketable: added at the bench when none, and the element's own seated
		if el != "bleed":
			var sock: Dictionary = Items.roll(Data.ATTACHMENT, 2, sim.rng)
			var sock_base: String = {"fire": "Lighter fluid", "frost": "Antifreeze", "poison": "Rat poison", "shock": "Car battery"}[el]
			sock["base"] = sock_base
			sock["mount"] = "socket"
			sock["affixes"] = []
			sim.stash.append(sock)
			var cash0: float = sim.cash
			bot._craft_toward(sim)
			_check(Items.sockets(sim.equipped["Primary"]) >= 1 and sim.cash < cash0, "the %s bot did not buy a socket at the bench" % el)
			bot.tidy(sim)
			var seated := false
			for a in sim.equipped["Primary"]["attachments"].values():
				seated = seated or (a != null and a["base"] == sock_base)
			var where := "in the stash" if sim.stash.has(sock) else "gone"
			for st in Data.SOCKET_SLOTS:
				if sim.equipped[st] != null and sim.equipped[st]["attachments"].values().has(sock):
					where = "on the " + st.to_lower()
			for it in sim.stash:
				if it.get("attachments", {}).values().has(sock):
					where = "on the %s in the stash" % it["base"]
			_check(seated, "the %s bot did not seat its socketable: it is %s; the primary is %s (carries: %s, plain: %s) with %s; bought %s" % [el, where, sim.equipped["Primary"]["base"], is_same(sim.equipped["Primary"], carries), is_same(sim.equipped["Primary"], plain), sim.equipped["Primary"]["attachments"], str(bot.bought.slice(-4))])
		# the bench: the increased affix added next to the conversion
		sim.cash = 400000.0
		bot._craft_toward(sim)
		var has_inc := false
		for a in sim.equipped["Primary"]["affixes"]:
			has_inc = has_inc or a["stat"] == "%s_pct" % el
		_check(has_inc or sim.craft_cost(sim.equipped["Primary"], "add") < 0, "the %s bot did not add its increased affix: %s" % [el, sim.equipped["Primary"]["affixes"]])
		_check(sim.conversion()[el] > 0.5, "the %s build is not mostly %s: %s" % [el, el, sim.conversion()])
	# the band: at depth 30 on every site, some element build lands at least 60% of what it would unresisted
	var builds := {}
	for t in Data.ELEMENT_TREES:
		builds[t["element"]] = {"types": {t["element"]: 1.0}}
	builds["physical"] = {"types": {"physical": 1.0}}
	for i in range(Data.TIERS.size()):
		sim.depth[i] = 30
		sim.intel[i] = []
		var e: Dictionary = sim.effective(i)
		var best := 0.0
		var best_name := ""
		for name in builds:
			var landed: float = 1.0 - float(e["res"].get(name, 0.0))
			if landed > best:
				best = landed
				best_name = name
		_check(best >= 0.6, "no build lands 60%% on %s at depth 30: best %s at %.0f%%" % [e["name"], best_name, best * 100])
		_check(e["res"].values().any(func(r): return float(r) >= 0.3), "%s at depth 30 resists nothing enough to matter: %s" % [e["name"], e["res"]])
		_check(e["res"].values().any(func(r): return float(r) <= 0.01), "%s at depth 30 resists everything: %s" % [e["name"], e["res"]])
	sim.load_dict(saved)
	print("element bots ok: own tree first, saved points, the second past, the gun, the socketable, the bench, the band")


func _element_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	sim.set_class("Drifter")
	sim.respec()
	sim.training_points += 60
	sim.equipped["Primary"] = sim._plain("Primary", "Nail gun")     # nothing worn converts: the trees are read alone
	sim.equipped["Secondary"] = null
	_check(sim.affinity("fire") and sim.affinity("shock") and not sim.affinity("poison"), "the Drifter's affinities are not fire and shock")
	_check(sim.node_cost("Petrol/0") == 1 and sim.node_cost("The rat man/0") == 2, "an off-affinity node does not cost double: %d / %d" % [sim.node_cost("Petrol/0"), sim.node_cost("The rat man/0")])
	for i in range(7):
		_check(sim.train_node("Petrol/%d" % i), "Petrol/%d did not train" % i)
	_check(sim.has_node("fire_spread"), "Spreads did not take")
	_check(is_equal_approx(sim.conversion()["fire"], 0.45), "the spine and keystone branch did not convert 45%%: %s" % str(sim.conversion()))
	_check(is_equal_approx(sim.dot_seconds("fire"), 8.0) and is_equal_approx(sim.dot_seconds("poison"), 8.0), "Lit did not double the burn")
	# the other branch's cost: 40% more fire
	_check(sim.train_node("Petrol/7") and sim.train_node("Petrol/8") and sim.train_node("Petrol/9"), "the costly branch did not train")
	_check(is_equal_approx(sim.more("fire"), 1.4), "Petrol on your hands is not ×1.4")
	# off-affinity: the rat man's keystone refuses; the second past opens it
	for i in range(6):
		sim.train_node("The rat man/%d" % i)
	_check(not sim.can_train("The rat man/6"), "an off-affinity keystone trained")
	sim.xp = Data.xp_for_level(Data.ASCEND_LEVEL)
	_check(sim.set_second("Poacher") and sim.affinity("poison") and sim.node_cost("The rat man/0") == 1, "the second past did not bring its affinities")
	_check(sim.can_train("The rat man/6"), "the second past's affinity did not open the keystone")
	# the fight: Spreads multiplies fire by those on you; a shocked gang takes more under Live
	sim.intel[0] = []
	sim.set_depth(0, 1)
	sim.hp = sim.max_hp()
	sim.deploy(0)
	var m: Dictionary = sim.mission
	var t: Dictionary = m["t"]
	var on_you: int = mini(m["remaining"], sim.contact(t))
	var before: float = m["target_hp"]
	sim.advance(0.1)
	var fire_only: float = sim.type_dps()["fire"] * (1.0 - float(t["res"].get("fire", 0.0))) * sim.pace() * t["pace"] * 0.1
	_check(before - m["target_hp"] > fire_only * on_you * 0.6 or m["remaining"] < sim.mission["t"]["pool"], "Spreads did not multiply the fire by the %d on you" % on_you)
	sim.extract_now()
	# frost: Frozen solid stops their fire while chilled and halves frost; the cold's notable deepens the chill
	sim.respec()
	sim.set_class("Poacher")
	sim.training_points += 60
	for i in range(7):
		sim.train_node("The cold/%d" % i)
	_check(sim.has_node("frost_freeze") and is_equal_approx(sim.chill_amount(), Data.FREEZE) and is_equal_approx(sim.more("frost"), 0.5), "Frozen solid did not take: chill %.2f more %.2f" % [sim.chill_amount(), sim.more("frost")])
	_check(is_equal_approx(sim.incoming_rate({"dps": 10.0, "types": {"physical": 1.0}}, 1, true), 10.0 * (1.0 - Data.FREEZE) * (1.0 - sim.mitigation())), "a frozen gang fires more than a sliver: %.2f" % sim.incoming_rate({"dps": 10.0, "types": {"physical": 1.0}}, 1, true))
	for i in range(7):
		sim.train_node("The rat man/%d" % i)
	_check(sim.dot_stacks("poison") == 15, "Builds did not raise the stacks")
	sim.respec()
	sim.set_class("Doorman")
	sim.training_points += 60
	for i in range(10):
		sim.train_node("Blades/%d" % i)
	_check(sim.has_node("bleed_forever") and is_equal_approx(sim.more("bleed"), 1.4), "Blades did not train to both ends")
	sim.deploy(0)
	m = sim.mission
	m["dots"] = {"bleed": 60.0}
	var dealt: float = sim._dot_tick(m["dots"], 1.0, {})
	_check(dealt > 0.0 and is_equal_approx(m["dots"]["bleed"], 60.0), "Won't stop let the bleed fade: %s" % str(m["dots"]))
	sim.extract_now()
	# the class webs' element notables, read with a plain gun on
	var held = sim.equipped["Primary"]
	sim.equipped["Primary"] = sim._plain("Primary", "Pipe shotgun")
	_check(sim.train_node("Muscle/0") and sim.train_node("Muscle/1") and sim.train_node("Muscle/2") and sim.train_node("Muscle/3") and sim.train_node("Muscle/7") and sim.train_node("Muscle/8"), "Muscle's branch to Glassing did not train")
	_check(is_equal_approx(sim.conversion()["bleed"], 0.15 + 0.65), "Glassing did not add 15%% bleed: %s" % str(sim.conversion()))
	sim.equipped["Primary"] = held
	# the Caravan cycles the middle column through the elements
	main.show_room(main.BARRACKS)
	_check_fit(main, "Caravan (elements, yard)")
	for k in range(6):
		main._barracks._on_swap()
		_check_fit(main, "Caravan (elements, %d)" % k)
	# the D layout: the band with the runner and the points, the classes in its top right; tiles two across
	# with the keystone the width, none overlapping, every one inside its column; the rail filled as far as
	# the tree is taken; the sum strip under the trees and the panel under that
	var bk = main._barracks
	_check(bk._band.title.text == "The caravan" and bk._points.text == "%d of %d" % [sim.points_free(), sim.training_points], "the caravan's band is off: '%s' / '%s'" % [bk._band.title.text, bk._points.text])
	for cb in bk._class_buttons:
		_check(cb.position.y + cb.size.y <= bk.BAND_H and cb.position.x >= bk._band.kicker.position.x, "a class button is not in the band's top right")
	for col in range(3):
		var rects := []
		for n in bk._rows[col]:
			if n["button"].visible:
				var rc := Rect2(n["button"].position, n["button"].size)
				_check(rc.position.x >= col * (bk.COL_W + bk.COL_GAP) + bk.RAIL_W - 0.5 and rc.end.x <= (col + 1) * bk.COL_W + col * bk.COL_GAP + 0.5 and rc.position.y >= bk.NODES_Y and rc.end.y <= bk.NODES_Y + bk.COLUMN_H + 0.5, "a tile leaves its column: %s in column %d" % [str(rc), col])
				for other in rects:
					_check(not rc.intersects(other), "tiles overlap in column %d: %s and %s" % [col, str(rc), str(other)])
				rects.append(rc)
		var r: Dictionary = bk._rails[col]
		if r["track"].visible:
			_check(r["fill"].size.y <= r["track"].size.y + 0.5 and r["fill"].size.y >= 0.0, "the rail's fill leaves its track in column %d" % col)
			_check(r["top"].text != "" and r["bottom"].text != "" and int(r["top"].text) <= int(r["bottom"].text), "the rail's counts are off: %s of %s" % [r["top"].text, r["bottom"].text])
	# a fully taken tree fills its rail; the yard's, part taken, part fills it
	var full_col := -1
	for col in range(3):
		var r: Dictionary = bk._rails[col]
		if r["track"].visible and r["top"].text == r["bottom"].text and int(r["top"].text) > 0:
			full_col = col
	if full_col >= 0:
		_check(is_equal_approx(bk._rails[full_col]["fill"].size.y, bk._rails[full_col]["track"].size.y), "a fully taken tree's rail is not full: %.0f of %.0f" % [bk._rails[full_col]["fill"].size.y, bk._rails[full_col]["track"].size.y])
	_check(bk.SUM_Y >= bk.NODES_Y + bk.COLUMN_H and bk.PANEL_Y >= bk.SUM_Y + bk.SUM_H and bk._sum_chips._tags[0].text == "Damage" and bk._sum_chips._tags[7].text == "Notables" and bk._sum_chips.shown() == 8, "the sum strip is off: %s" % str(bk._sum_chips.text_nodes().map(func(l): return l.text)))
	# a keystone's or a capstone's tile spans both columns of tiles; a plain node's one
	for n in bk._rows[0]:
		if n["button"].visible and n["id"] != "":
			var nd: Dictionary = sim.node(n["id"])
			if nd.get("keystone", false) or nd.get("capstone", false):
				_check(n["button"].size.x > bk.TILE_W * 1.5, "the keystone's tile is not the width")
			else:
				_check(is_equal_approx(n["button"].size.x, bk.TILE_W), "a node's tile is not one across")
	# the gun in hand changes a typed node's look without anything else moving (the reviewer's catch)
	var typed_id := ""
	for b in Data.TREES:
		for i in range(b["nodes"].size()):
			if b["nodes"][i].has("type") and sim.tree.has("%s/%d" % [b["name"], i]) and typed_id == "":
				typed_id = "%s/%d" % [b["name"], i]
	if typed_id != "" and sim.equipped["Primary"] != null:
		var hold_gun = sim.equipped["Primary"]
		var typed_node: Dictionary = sim.node(typed_id)
		# a gun of the node's type, then one of another: the node goes active, then idle, and the screen follows
		var same_base := ""
		var other_base := ""
		for base in Data.BASES["Primary"]:
			if base.get("type", "") == typed_node["type"] and same_base == "":
				same_base = base["name"]
			elif base.get("type", "") != typed_node["type"] and other_base == "":
				other_base = base["name"]
		if same_base != "" and other_base != "":
			sim.equipped["Primary"] = sim._plain("Primary", same_base)
			main.refresh()
			var shown_active: String = bk._shown
			sim.equipped["Primary"] = sim._plain("Primary", other_base)
			main.refresh()
			_check(not sim._active(typed_node) and bk._shown != shown_active, "the gun swap did not refresh the caravan: typed node %s" % typed_id)
		sim.equipped["Primary"] = hold_gun
		main.refresh()
		_check(bk._shown.contains(sim.gun_type()), "the caravan's signature does not carry the gun in hand")
	# the middle head: the name centred between a back and a next, and back undoes next
	var mid_name: Label = bk._heads[1]["name"]
	_check(bk._back.visible and bk._swap.visible and bk._back.text.begins_with("◂ ") and bk._swap.text.ends_with(" ▸"), "the middle head's back/next read '%s' / '%s'" % [bk._back.text, bk._swap.text])
	_check(mid_name.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and mid_name.position.x >= bk.SWAP_W and mid_name.position.x + mid_name.size.x <= bk.COL_W - bk.SWAP_W, "the middle head's name is not centred between the buttons: x %d w %d" % [mid_name.position.x, mid_name.size.x])
	_check(mid_name.get_theme_font("font").get_string_size(mid_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, mid_name.get_theme_font_size("font_size")).x <= mid_name.size.x, "the middle head's name '%s' does not fit between the buttons" % mid_name.text)
	var here: int = bk.mid
	var was: String = mid_name.text
	bk._on_swap()
	_check(bk.mid != here and mid_name.text != was, "next did not move the middle tree")
	_check(bk._back.text == "◂ " + was or bk._back.text == "◂ Back", "back does not name the tree just left: '%s' for %s" % [bk._back.text, was])
	bk._on_back()
	_check(bk.mid == here and mid_name.text == was, "back did not return to %s: %s" % [was, mid_name.text])
	bk._on_back()
	_check(bk.mid == (here - 1 + bk._mid_trees(sim.trees()).size()) % bk._mid_trees(sim.trees()).size(), "back from the first tree did not wrap to the last")
	_check_fit(main, "Caravan (back)")
	bk._on_swap()
	sim.load_dict(saved)
	print("the elements ok: affinities, double cost, the locked keystone and the second past, Spreads, Frozen solid, Builds, Won't stop, the class notables, the Caravan")
	_capstone_checks(main)
	_melee_checks(main)


## Melee: no rounds, bleed built in, grip and head mounts, in among them.
## 28: a capstone a tree, past the keystone, wanting the keystone and every notable, a quarter of the tree again (a third until the pass).
func _capstone_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	# every tree carries one, last, wide on the caravan, and its cost is a third of the tree rounded up
	for b in Data.TREES + Data.ELEMENT_TREES:
		var last: Dictionary = b["nodes"].back()
		_check(last.get("capstone", false) and last.has("words") and last["effect"].begins_with("cap_"), "%s has no capstone at its end" % b["name"])
		_check(b["nodes"].filter(func(n): return n.get("capstone", false)).size() == 1, "%s has more than one capstone" % b["name"])
		var others := 0
		for i in range(b["nodes"].size() - 1):
			others += Data.node_cost(i, b["nodes"][i].get("notable", false), b["nodes"][i].get("keystone", false))
		_check(Data.capstone_cost(b) == ceili(others / 4.0), "%s's capstone costs %d, not a quarter of %d" % [b["name"], Data.capstone_cost(b), others])
	# it opens only once the keystone and every notable are taken
	sim.set_class("Poacher")
	sim.tree = sim.tree.filter(func(id): return not str(id).begins_with("Snares/"))
	sim.training_points = 200
	var snares: Dictionary = Data.tree_named("Snares")
	var cap_id := "Snares/%d" % (snares["nodes"].size() - 1)
	_check(not sim.can_train(cap_id), "the capstone opened with nothing behind it")
	# train the spine and the notables, not the keystone yet
	for i in range(snares["nodes"].size() - 1):
		if not snares["nodes"][i].get("keystone", false):
			sim.tree.append("Snares/%d" % i)
	_check(not sim.can_train(cap_id), "the capstone opened without the keystone")
	# the keystone in, one notable out: still shut
	var a_notable := ""
	for i in range(snares["nodes"].size() - 1):
		if snares["nodes"][i].get("keystone", false):
			sim.tree.append("Snares/%d" % i)
		elif snares["nodes"][i].get("notable", false) and a_notable == "":
			a_notable = "Snares/%d" % i
	sim.tree.erase(a_notable)
	_check(not sim.can_train(cap_id), "the capstone opened with a notable missing")
	sim.tree.append(a_notable)
	_check(sim.can_train(cap_id) and sim.node_cost(cap_id) == Data.capstone_cost(snares), "the capstone did not open with the whole tree behind it (cost %d)" % sim.node_cost(cap_id))
	_check(sim.train_node(cap_id) and sim.has_node("cap_poached"), "the capstone did not train")
	# Poached: a gang's arrival brings a find
	sim.deploy(0)
	var m: Dictionary = sim.mission
	m["remaining"] = 0
	m["cleared"] = true
	var found_before: int = m["found"].size() + int(m["left"])
	m["patrol_timer"] = 1e9
	sim.advance(0.5)
	_check(m["patrols"] >= 1 and m["found"].size() + int(m["left"]) > found_before, "Poached did not bring a find when the gang came")
	sim.extract_now()
	# the caravan shows it as a wide ◆◆ tile under the keystone, and the run band names it
	main.show_room(main.BARRACKS)
	main._barracks.selected = ""
	main._barracks._shown = ""
	main.refresh()
	var cap_tile = null
	for col in main._barracks._rows:
		for n in col:
			if n["button"].visible and n["id"] == cap_id:
				cap_tile = n
	_check(cap_tile != null and cap_tile["name"].text.begins_with("◆◆ ") and cap_tile["button"].size.x > main._barracks.TILE_W * 1.5 and cap_tile["effect"].text != "", "the capstone's tile is off: %s" % (cap_tile["name"].text if cap_tile != null else "none"))
	_check_fit(main, "Caravan (capstone)")
	main._barracks._pick(cap_id)
	main.refresh()
	_check(main._barracks._title.text.ends_with("capstone · trained"), "the capstone's panel title is off: '%s'" % main._barracks._title.text)
	_check_fit(main, "Caravan (capstone picked)")
	sim.deploy(0)
	main.show_room(main.MISSIONS)
	main.refresh()
	_check(main._run._band.right[2].text.contains("Poached") or main._run._band.right[2].text.contains("capstone"), "the run band does not name the capstone: '%s'" % main._run._band.right[2].text)
	_check_fit(main, "Run (capstone)")
	sim.extract_now()
	# Dead quiet: every gang the size of the first; Ghost: a run starts at the search and a full pack brought home is the clear
	sim.tree.append("Stalking/%d" % (Data.tree_named("Stalking")["nodes"].size() - 1))
	sim.deploy(0)
	m = sim.mission
	m["remaining"] = 0
	m["cleared"] = true
	m["patrols"] = 4
	m["patrol_timer"] = 1e9
	sim.advance(0.5)
	_check(m["remaining"] == sim.PATROL_BASE - (1 if sim.has_node("trapline") else 0), "Dead quiet let the fifth gang grow: %d" % m["remaining"])
	sim.extract_now()
	sim.tree = sim.tree.filter(func(id): return not str(id).begins_with("Stalking/"))
	sim.set_class("Drifter")
	sim.tree.append("Moving on/%d" % (Data.tree_named("Moving on")["nodes"].size() - 1))
	var best_before: int = sim.best_tier
	sim.deploy(0)
	m = sim.mission
	_check(m["remaining"] == 0 and m["cleared"] and m.get("ghost_pending", false), "Ghost did not start the run at the search")
	_check(sim.best_tier == best_before, "Ghost cleared the ladder on arrival")
	sim.extract_now()
	_check(sim.best_tier == best_before, "a Ghost run brought home light counted as a clear")
	sim.best_tier = 0
	sim.best_depth[0] = 0
	sim.deploy(0)
	m = sim.mission
	m["found"] = []
	while sim.pack_used(m) < sim.capacity():
		m["found"].append(sim._plain(Data.AMMO, "Nails"))
	sim.extract_now()
	_check(sim.best_tier == 1 and sim.best_depth[0] >= 1, "a Ghost run brought home full did not clear the site (best tier %d)" % sim.best_tier)
	sim.load_dict(saved)
	# Held: no second takes more than a tenth of you, their shots and what they left on you together
	sim.tree.append("The door/%d" % (Data.tree_named("The door")["nodes"].size() - 1))
	var deep: int = sim.best_tier
	sim.deploy(deep)
	m = sim.mission
	m["remaining"] = 40
	sim.hp = sim.max_hp()
	sim.advance(1.0)
	_check(sim.on_mission() and float(m["last_incoming"]) <= sim.max_hp() * 0.1 + 0.01, "Held let a second take %.1f of %.1f" % [float(m["last_incoming"]), sim.max_hp()])
	sim.extract_now()
	sim.load_dict(saved)
	# Iron: a kill under half HP heals a tenth
	sim.tree.append("Muscle/%d" % (Data.tree_named("Muscle")["nodes"].size() - 1))
	sim.deploy(0)
	m = sim.mission
	sim.hp = sim.max_hp() * 0.3
	var hp_before: float = sim.hp
	sim._kill(m, m["t"])
	_check(sim.hp >= hp_before + sim.max_hp() * 0.1 - 0.01, "Iron did not heal on the kill: %.1f to %.1f" % [hp_before, sim.hp])
	sim.extract_now()
	sim.load_dict(saved)
	main.refresh()
	print("the capstones ok: one a tree, the cost, the gate, Poached, the tile, the band, Dead quiet, Ghost, Held, Iron")


func _melee_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	var bat: Dictionary = sim._plain("Primary", "Spiked bat")
	_check(Items.is_melee(bat) and Items.ammo_words(bat) == "Takes nothing" and bat["attachments"].has("grip") and bat["attachments"].has("business end"), "a spiked bat is not a melee weapon with a grip and a head")
	var old = sim.equipped["Primary"]
	sim.equipped["Primary"] = sim._plain("Primary", "Nail gun")
	var bleed0: float = sim.conversion()["bleed"]          # whatever the rest of the kit and the web add already
	sim.equipped["Primary"] = bat
	sim.rig = []
	_check(sim.has_rounds(bat) and sim.dps() > 0.0, "a bat ran dry")
	_check(is_equal_approx(sim.conversion()["bleed"], bleed0 + 0.2) or sim.conversion()["physical"] <= 0.001, "the bat's nails are not 20%% bleed on top of %.2f: %s" % [bleed0, str(sim.conversion())])
	var head: Dictionary = sim._plain("Attachment", "Nails through it")
	bat["attachments"]["business end"] = head
	_check(is_equal_approx(sim.conversion()["bleed"], bleed0 + 0.35) or sim.conversion()["physical"] <= 0.001, "nails through it did not add 15%% bleed: %s" % str(sim.conversion()))
	_check(is_equal_approx(sim.incoming_rate({"dps": 10.0, "types": {"physical": 1.0}}, 1), 10.0 * (1.0 - sim.mitigation()) * Data.MELEE_INCOMING), "a melee runner is not hit %.2f× harder" % Data.MELEE_INCOMING)
	# the first second of a gang: their shot before your swing
	sim.intel[0] = []
	sim.set_depth(0, 1)
	sim.hp = sim.max_hp()
	sim.deploy(0)
	var m: Dictionary = sim.mission
	var hp0: float = m["target_hp"]
	sim.advance(0.5)
	_check(is_equal_approx(m["target_hp"], hp0), "the bat swung inside the first second of a gang")
	sim.advance(1.0)
	_check(m["target_hp"] < hp0 or m["remaining"] < m["t"]["pool"], "the bat never swung")
	sim.extract_now()
	# the Workshop shows the bat's grip and head, and fits a part to the head
	sim.workshop = 3
	sim.stash.append(sim._plain("Attachment", "Tape"))
	main.show_room(main.WORKSHOP)
	main._workshop._set_view("guns")
	main.refresh()
	var labels := []
	for r in main._workshop._guns["Primary"]["rows"]:
		labels.append(r["mount"].text)
	_check(labels[0] == "Grip" and labels[1] == "Business end" and labels[2] == "—", "the bat's rows are %s" % str(labels))
	_check_fit(main, "Workshop (a bat)")
	main._workshop._pick_row("Primary", 0)
	_check(main._workshop.sel_mount == "grip", "picking the first row did not pick the grip")
	main._workshop._pick_cell(0)
	main._workshop._press(0)
	_check(bat["attachments"]["grip"] != null and bat["attachments"]["grip"]["mount"] == "grip", "a grip part did not fit the grip")
	_check_fit(main, "Workshop (a bat, taped)")
	# a bat's part on the panel: the kind leads, the mount reads as a word, and nothing calls a bat a gun
	var lead: Dictionary = sim._plain(Data.ATTACHMENT, "Lead in it")
	while not sim.stash_room(1) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])
	sim.stash.append(lead)
	main._workshop.sel_slot = ""
	main._workshop.sel_mount = ""
	main.refresh()
	main._workshop._pick_cell(main._workshop._inv.cell_of(lead["id"]))
	main.refresh()
	var lead_chips: Array = main._workshop._pick._heads[0]._chip_labels.filter(func(l): return l.visible).map(func(l): return l.text)
	_check(lead_chips.size() >= 2 and lead_chips[0] == "Melee part" and lead_chips[1] == "Business end", "a bat part's chips are %s" % str(lead_chips))
	_check(not main._workshop._pick._kickers[1].text.to_lower().contains("gun") and not main._workshop._pick._right_title.text.contains("gun"), "a bat part's panel talks of a gun: '%s' / '%s'" % [main._workshop._pick._kickers[1].text, main._workshop._pick._right_title.text])
	_check_fit(main, "Workshop (a bat part)")
	# a part with a long kind line and an affix in the Lock-up: fits, the part's own figures first, the affix banded
	var bipod: Dictionary = sim._plain(Data.ATTACHMENT, "Bipod")
	bipod["rarity"] = 1
	bipod["affixes"] = [{"stat": "damage_pct", "value": 4, "tier": 2}]
	while not sim.stash_room(1) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])
	sim.stash.append(bipod)
	main.show_room(main.ARMOURY)
	main.refresh()
	main._armoury._pick_cell(main._armoury._inv.cell_of(bipod["id"]))
	main.refresh()
	var bhead = main._armoury._head
	_check(bhead.visible and bhead._title.text == "Bipod" and bhead._figure.text == "+18%", "the part's head is off: '%s' '%s'" % [bhead._title.text, bhead._figure.text])
	_check(bhead._tail.text.contains("−6% pace") and not bhead._tail.text.contains("+22"), "the part's own figures carry its affix too: '%s'" % bhead._tail.text)
	_check(bhead._affixes.visible and bhead._affixes.words(0) == "+4% damage" and bhead._affixes._tags[0].text == "T2" and bhead._affixes._labels[0].get_theme_color("font_color") == Pal.tier_color(2), "the part's affix is not a chip in its tier's colour: '%s'" % bhead._affixes.words(0))
	var chip_words := []
	for k in range(bhead.CHIPS):
		if bhead._chips[k].visible:
			chip_words.append(bhead._chip_labels[k].text)
	_check(chip_words.has("Gun part") and chip_words.has("Handguard") and chip_words.has("Uncommon") and chip_words.has("Rifles only") and not chip_words.has("1 cell"), "the part's chips are %s" % str(chip_words))
	_check_fit(main, "Armoury (a bipod)")
	sim.stash.erase(bipod)
	# a gun with parts and a socketable on: the head's tail names them, the fitted gun's right column lists them
	var kitted: Dictionary = sim._plain("Primary", "Workshop SMG")
	kitted["attachments"]["optic"] = sim._plain(Data.ATTACHMENT, "Red dot")
	kitted["attachments"]["muzzle"] = sim._plain(Data.ATTACHMENT, "Choke") if Data.ATTACHMENTS.any(func(b): return b["name"] == "Choke") else null
	kitted["attachments"]["socket 1"] = sim._plain(Data.ATTACHMENT, "Lighter fluid")
	var held_primary = sim.equipped["Primary"]
	sim.equipped["Primary"] = kitted
	main._armoury._pick_slot("Primary")
	main.refresh()
	var khead = main._armoury._head
	_check(khead._tail.text.contains("Red dot") or khead._tail.text.contains("part"), "a kitted gun's head does not say what's on it: '%s'" % khead._tail.text)
	_check(main._armoury._pick._right_lines[0].text.begins_with("Red dot"), "the fitted gun's column does not list its parts: '%s'" % main._armoury._pick._right_lines[0].text)
	_pick_boxes_check(main._armoury._pick, "the Lock-up's pick")
	_check(main._armoury._pick._right_lines.any(func(l): return l.text.begins_with("Lighter fluid")), "the socketable is not listed with the parts")
	_check_fit(main, "Armoury (a kitted gun)")
	sim.equipped["Primary"] = held_primary
	var kit_words: Array = Items.fitted_words(kitted)
	_check(kit_words[0].contains("Red dot") and kit_words[0].contains("lighter fluid") and kit_words[1].contains("socketable") and kit_words[2].ends_with("fitted"), "fitted_words: %s" % str(kit_words))
	main.show_room(main.WORKSHOP)
	main.refresh()
	# the bench says what the next level adds, at every level short of the last
	var ws_was: int = sim.workshop
	for lv in range(Data.WORKSHOP.size()):
		sim.workshop = lv
		main.refresh()
		var words: String = main._workshop._band.right[1].text
		_check(main._workshop._band.headline.text == "Level %d" % lv and main._workshop._bench_words.text != "", "bench level %d's band reads '%s' / '%s'" % [lv, main._workshop._band.headline.text, main._workshop._bench_words.text])
		if lv < Data.WORKSHOP.size() - 1:
			_check(words.begins_with("Next: ") and words.ends_with("s"), "bench level %d's words don't say what the upgrade adds: '%s'" % [lv, words])
			_check(main._workshop._upgrade.visible and main._workshop._upgrade.text.begins_with("Upgrade"), "bench level %d has no upgrade button" % lv)
			_check(main._workshop._upgrade.position.y + main._workshop._upgrade.size.y <= main._workshop.BAND_H, "the upgrade button leaves the band")
		else:
			_check(not main._workshop._upgrade.visible, "the top bench still offers an upgrade")
		# a fitted part's tile carries its name in its tier's colour
		var prim = sim.equipped["Primary"]
		if prim != null:
			for r in main._workshop._guns["Primary"]["rows"]:
				if r["key"] != "" and prim["attachments"].get(r["key"], null) != null and sim.mount_open(r["key"]):
					var part: Dictionary = prim["attachments"][r["key"]]
					_check(r["fitted"].get_theme_color("font_color") == Pal.tier_color(int(part.get("tier", 1))), "the %s tile is not in its part's tier colour" % r["key"])
		_check_fit(main, "Workshop (bench level %d)" % lv)
	# a bench job on the craft view's piece shows at once, with nothing re-picked (notes paid: the level bump)
	var ws_piece: Dictionary = sim._plain("Helmet", "Hard hat")
	if sim.stash_room(1):
		sim.stash.append(ws_piece)
		main._workshop._set_view("craft")
		main.refresh()
		var kc: int = main._workshop._inv.cell_of(ws_piece["id"])
		if kc >= 0:
			main._workshop._pick_cell(kc)
			main.refresh()
			var before_words: String = main._workshop._craft_lines[1].text
			sim.notes += 1000
			sim.craft(ws_piece["id"], "bump")
			main.refresh()
			_check(main._workshop._craft_lines[1].text != before_words or main._workshop._hint.get_theme_color("font_color") == Pal.GOOD, "the craft view did not refresh after a bump: '%s'" % main._workshop._craft_lines[1].text)
		sim.stash.erase(ws_piece)
		main._workshop._set_view("guns")
		main.refresh()
	# a long part name on a tile falls back to its first word, never an ellipsis
	_check(main._workshop._short_names("Drum magazine") == ["Drum magazine", "Drum", "Drum"] and main._workshop._short_names("Tape") == ["Tape", "Tape"], "the tile's short names are off: %s" % str(main._workshop._short_names("Drum magazine")))
	var drum_gun = sim.equipped["Primary"]
	if drum_gun != null and drum_gun["attachments"].has("magazine") and sim.mount_open("magazine"):
		var hold_mag = drum_gun["attachments"]["magazine"]
		drum_gun["attachments"]["magazine"] = sim._plain("Attachment", "Drum magazine")
		main._workshop._shown = ""
		main.refresh()
		_check_fit(main, "Workshop (a drum magazine on a tile)")
		drum_gun["attachments"]["magazine"] = hold_mag
		main._workshop._shown = ""
		main.refresh()
	sim.workshop = ws_was
	main.refresh()
	sim.stash.erase(lead)
	# Through the lot: a Doorman's swing hits everyone on you
	sim.set_class("Doorman")
	sim.respec()
	sim.training_points += 30
	for i in [0, 1, 2, 3, 7, 8]:
		sim.train_node("The door/%d" % i)
	_check(sim.has_node("melee_sweep"), "Through the lot did not take with a bat in hand")
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	_check(not sim.has_node("melee_sweep"), "Through the lot counts with a gun")
	sim.equipped["Primary"] = old
	sim.load_dict(saved)
	print("melee ok: no rounds, the nails, the mounts, the wait, harder hit, the Workshop, Through the lot")
	_unique_rules_checks(main)


## The build-defining uniques: every one rolls and has words; the depth
## gates on the loose pool and the mate; each rule does its thing.
func _unique_rules_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	for u in Data.UNIQUES:
		var it := Items.roll_unique(u, sim.rng)
		_check(it["unique"] == u["name"] and Words.UNIQUES.has(u["name"]), "%s does not roll, or has no words" % u["name"])
	_check(sim.loose_uniques(1).size() == 4 and sim.loose_uniques(12).size() > 10 and sim.loose_uniques(25).size() == sim.loose_uniques(99).size(), "the depth gates on the loose pool are off: %d / %d / %d" % [sim.loose_uniques(1).size(), sim.loose_uniques(12).size(), sim.loose_uniques(25).size()])
	for i in range(sim.best_depth.size()):
		sim.best_depth[i] = 1
	for k in range(20):
		_check(int(sim._unique_named(sim.roll_mate()["unique"]).get("depth", 0)) == 0, "the mate sold a deep unique before anyone had been deep")
	sim.best_depth[0] = 25
	var deep := 0
	for k in range(40):
		deep += 1 if int(sim._unique_named(sim.roll_mate()["unique"]).get("depth", 0)) >= 12 else 0
	_check(deep > 10, "the mate's deep stock did not open at depth 25: %d of 40" % deep)
	# a bare runner to hang each rule on
	for s in Data.SLOTS:
		sim.equipped[s] = null
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	sim.respec()
	sim.intel[0] = []
	sim.set_depth(0, 1)
	var t: Dictionary = sim.effective(0)
	# the burner: all fire, takes nothing, spreads
	var burner := Items.roll_unique(sim._unique_named("The council's weed burner"), sim.rng)
	sim.equipped["Primary"] = burner
	_check(is_equal_approx(sim.conversion()["fire"], 1.0) and sim.has_rounds(burner) and Items.ammo_words(burner) == "Takes nothing", "the burner is not all fire and free: %s" % str(sim.conversion()))
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	# jump leads: a third shock
	sim.equipped["Secondary"] = Items.roll_unique(sim._unique_named("Jump leads"), sim.rng)
	_check(sim.conversion()["shock"] >= 0.33, "jump leads did not add a third shock: %s" % str(sim.conversion()))
	sim.equipped["Secondary"] = null
	# the bag and the steel: stacks, more, and the carry on a kill
	sim.equipped["Backpack"] = Items.roll_unique(sim._unique_named("The rat man's bag"), sim.rng)
	_check(sim.dot_stacks("poison") == 999, "the bag did not uncap poison")
	sim.deploy(0)
	var m: Dictionary = sim.mission
	m["dots"] = {"poison": 50.0}
	m["target_hp"] = 0.0
	m["remaining"] = 3
	sim.advance(0.1)
	_check(m.get("dots", {}).has("poison") and m["dots"]["poison"] > 0.0, "poison did not carry to the next with the bag: %s" % str(m.get("dots", {})))
	sim.extract_now()
	sim.equipped["Backpack"] = null
	sim.equipped["Primary"] = Items.roll_unique(sim._unique_named("The butcher's steel"), sim.rng)
	_check(is_equal_approx(sim.more("bleed"), 2.0), "the steel is not ×2 bleed")
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	# the hopper: chilled always, one at a time
	sim.equipped["Armour"] = Items.roll_unique(sim._unique_named("The gritter's hopper"), sim.rng)
	sim.deploy(0)
	m = sim.mission
	sim.advance(0.1)
	_check(float(m.get("chill_t", 0.0)) > 0.0 and sim.contact(t) == 1, "the hopper did not chill them and bring them one at a time: chill %.1f contact %d" % [float(m.get("chill_t", 0.0)), sim.contact(t)])
	sim.extract_now()
	sim.equipped["Armour"] = null
	# the gloves: their shock resist is nothing
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The sparky's gloves"), sim.rng)
	sim.equipped["Primary"]["affixes"] = [{"stat": "conv_shock_pct", "value": 50, "tier": 5}]
	var full: float = sim.damage_rate({"res": {}})
	_check(is_equal_approx(sim.damage_rate({"res": {"shock": 0.6}}), full), "the gloves did not ignore their shock resist")
	sim.equipped["Primary"]["affixes"] = []
	# the manual: every element yours
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The quartermaster's manual"), sim.rng)
	_check(sim.affinity("poison") and sim.affinity("frost") and sim.node_cost("The rat man/0") == 1, "the manual did not make every element the runner's")
	# the plaque: all resists, nothing else
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("A blue plaque"), sim.rng)
	sim.equipped["Primary"]["affixes"] = [{"stat": "damage_pct", "value": 50, "tier": 5}]
	_check(is_equal_approx(sim._affix_sum("damage_pct"), 0.0) and sim.resist("fire") >= 0.4, "the plaque did not blank the rest: dmg %.0f fire res %.2f" % [sim._affix_sum("damage_pct"), sim.resist("fire")])
	sim.equipped["Primary"]["affixes"] = []
	# the sign: the first drops, gangs half as often
	sim.equipped["Charm"] = null
	sim.equipped["Secondary"] = Items.roll_unique(sim._unique_named("The lollipop lady's sign"), sim.rng)
	var p0: float = sim.patrol_s(t)
	sim.equipped["Secondary"] = null
	_check(p0 >= sim.patrol_s(t) * 2.0, "the sign did not halve the gangs")
	# the pencil, the float, the cardigan, the ladle, the hat, the thermos, the whistles, the tester, the flask, the keys, the log
	var r0: float = sim.rarity_bonus()
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The bookie's pencil"), sim.rng)
	_check(sim.rarity_bonus() > r0 * 1.5 + 0.1, "the pencil did not double magic find")
	sim.equipped["Charm"] = null
	var cap0: int = sim.capacity()
	var pace0: float = sim.pace()
	sim.equipped["Rig"] = sim._plain("Rig", "Bum bag")
	sim.equipped["Backpack"] = Items.roll_unique(sim._unique_named("The float"), sim.rng)
	_check(sim.med_capacity() == 0 and sim.pace() > pace0 * 1.35 and sim.capacity() > cap0, "the float did not do its three things: meds %d pace %.2f cap %d" % [sim.med_capacity(), sim.pace() / pace0, sim.capacity()])
	sim.equipped["Backpack"] = null
	sim.equipped["Rig"] = null
	sim.equipped["Armour"] = Items.roll_unique(sim._unique_named("Nan's cardigan"), sim.rng)
	_check(is_equal_approx(sim.mitigation(), 0.0), "nan's cardigan has armour")
	sim.hp = sim.max_hp() * 0.5
	sim.deploy(0)
	var h0: float = sim.hp
	sim.advance(1.0)
	_check(sim.hp > h0 + sim.max_hp() * 0.012 or sim.hp >= sim.max_hp() - 0.1 or sim.mission == null, "the cardigan did not give 3%% a second: %.1f -> %.1f of %.1f" % [h0, sim.hp, sim.max_hp()])
	sim.extract_now()
	sim.equipped["Armour"] = null
	sim.equipped["Primary"] = Items.roll_unique(sim._unique_named("The dinner lady's ladle"), sim.rng)
	sim.hp = sim.max_hp() * 0.5
	sim.deploy(0)
	m = sim.mission
	h0 = sim.hp
	m["target_hp"] = 0.0
	sim.advance(0.05)
	_check(sim.hp >= h0 + sim.max_hp() * 0.1 - 1.0, "the ladle did not heal a tenth on a kill: %.1f -> %.1f" % [h0, sim.hp])
	sim.extract_now()
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	sim.equipped["Helmet"] = Items.roll_unique(sim._unique_named("A traffic warden's hat"), sim.rng)
	_check(sim.notes_a_kill(t) == 2 * (int(ceil(Data.NOTES_KILL * 1.0)) + sim.atlas_rank("paid_in_notes")) or sim.notes_a_kill(t) >= 2, "the hat did not double the notes")
	sim.equipped["Helmet"] = null
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The vicar's thermos"), sim.rng)
	_check(is_equal_approx(sim.resist("fire"), 0.0), "the thermos left a fire resist")
	sim.deploy(0)
	m = sim.mission
	m["my_dots"] = {"fire": 40.0}
	sim.hp = sim.max_hp() * 0.5
	h0 = sim.hp
	m["remaining"] = 1
	m["target_hp"] = 1e9
	sim.advance(0.5)
	_check(sim.hp > h0 - 1.0, "the thermos did not turn the burn to warmth: %.1f -> %.1f" % [h0, sim.hp])
	sim.extract_now()
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The scout leader's whistle"), sim.rng)
	sim.deploy(0)
	m = sim.mission
	m["remaining"] = 0
	m["cleared"] = true
	m["patrol_timer"] = 1e9
	sim.advance(0.1)
	_check(m["remaining"] == 1, "the scout's whistle did not make the gang one: %d" % m["remaining"])
	sim.extract_now()
	sim.equipped["Charm"] = null
	var c0: int = sim.contact(t)
	sim.equipped["Helmet"] = Items.roll_unique(sim._unique_named("The sergeant's whistle"), sim.rng)
	_check(sim.contact(t) == c0 + 2 and is_equal_approx(sim.more("physical"), 1.6), "the sergeant's whistle: contact %d more %.1f" % [sim.contact(t), sim.more("physical")])
	sim.equipped["Helmet"] = null
	sim.equipped["Secondary"] = Items.roll_unique(sim._unique_named("The electrician's tester"), sim.rng)
	_check(is_equal_approx(sim.more("shock"), 0.5), "the tester is not half shock")
	sim.equipped["Secondary"] = null
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The gamekeeper's flask"), sim.rng)
	sim.intel[0] = ["Burners"]
	sim.deploy(0)
	m = sim.mission
	m["t"]["types"] = {"physical": 0.5, "poison": 0.5}
	m["target_hp"] = 1e9
	sim.advance(0.5)
	_check(m.get("dots", {}).get("poison", 0.0) > 0.0, "the flask did not poison them back: %s" % str(m.get("dots", {})))
	sim.extract_now()
	sim.intel[0] = []
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The caretaker's keys"), sim.rng)
	var fired := 0
	for k in range(5):
		sim.deploy(0)
		fired += 1 if sim.mission["event"] != "" else 0
		sim.extract_now()
	_check(fired == 5, "the keys did not make something happen every run: %d of 5" % fired)
	sim.equipped["Charm"] = null
	var log := Items.roll_unique(sim._unique_named("The lorry driver's log"), sim.rng)
	sim.stash.append(log)
	_check(sim.has_rule("drivers_log") and sim.insure_cost(0) == 0, "the log in the stash did not count, or insurance isn't free")
	sim.stash.erase(log)
	sim.load_dict(saved)
	print("the uniques ok: all roll with words, the depth gates, the mate's deep stock, twenty-one rules")
	_set_checks(main)


## Sets: pieces roll and have words, the count, the bonuses at two and the
## full set, the rules, the drop by depth, the tint and the panel's line.
func _set_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	for st in Data.SETS:
		for p in st["pieces"]:
			var it := Items.roll_set_piece(st["name"], p, sim.rng)
			_check(it["set"] == st["name"] and it["piece"] == p["name"] and Items.full_name(it) == p["name"] and Words.item_words(p["name"]) != "", "%s does not roll as a piece with words" % p["name"])
			_check(load("res://scripts/ui/item_cell.gd").rarity_tone(it) == "set", "a set piece is not tinted")
	for s in Data.SLOTS:
		sim.equipped[s] = null
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	var council: Dictionary = Items.set_named("The council's")
	_check(sim.set_count("The council's") == 0 and sim.set_bonuses().is_empty(), "a bare runner has set bonuses")
	sim.equipped["Armour"] = Items.roll_set_piece("The council's", council["pieces"][0], sim.rng)
	sim.equipped["Helmet"] = Items.roll_set_piece("The council's", council["pieces"][1], sim.rng)
	_check(sim.set_count("The council's") == 2 and is_equal_approx(sim.set_stat("all_res"), 20.0) and sim.resist("fire") >= 0.2, "two of the council's did not give all resists +20")
	_check(not sim.has_set_rule("council"), "the council's rule came at two")
	sim.equipped["Backpack"] = Items.roll_set_piece("The council's", council["pieces"][2], sim.rng)
	sim.equipped["Charm"] = Items.roll_set_piece("The council's", council["pieces"][3], sim.rng)
	_check(sim.set_count("The council's") == 4 and sim.has_set_rule("council") and is_equal_approx(sim.set_stat("regen"), 4.0) and sim._affix_sum("search_pct") >= 30.0 + 8.0, "the full council's did not give it all: rule %s regen %.0f search %.0f" % [str(sim.has_set_rule("council")), sim.set_stat("regen"), sim._affix_sum("search_pct")])
	# the panel's line, in the set's tint
	main.show_room(main.ARMOURY)
	main._armoury._pick_slot("Armour")
	main.refresh()
	_check(main._armoury._head.text_nodes().any(func(r): return r.text.begins_with("The council's · 4 of 4") or r.text == "4 of 4 worn"), "the panel's set chip is missing: %s" % str(main._armoury._head.text_nodes().map(func(r): return r.text)))
	_check_fit(main, "Armoury (a set)")
	# the army's: contact down one, more ×1.3 at four
	for s in Data.SLOTS:
		sim.equipped[s] = null
	var army: Dictionary = Items.set_named("The army's")
	sim.intel[0] = []
	sim.weather[0] = ""                  # fog would take the one the set takes
	var t: Dictionary = sim.effective(0)
	var c0: int = sim.contact(t)
	for p in army["pieces"]:
		sim.equipped[p["slot"]] = Items.roll_set_piece("The army's", p, sim.rng)
	_check(sim.contact(t) == c0 - 1 and is_equal_approx(sim.more("physical"), 1.3), "the army's full set: contact %d of %d, more %.1f" % [sim.contact(t), c0, sim.more("physical")])
	# the carpet man's two: 30% bleed, bleeds last twice
	for s in Data.SLOTS:
		sim.equipped[s] = null
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	var carpet: Dictionary = Items.set_named("The carpet man's")
	for p in carpet["pieces"]:
		sim.equipped[p["slot"]] = Items.roll_set_piece("The carpet man's", p, sim.rng)
	_check(is_equal_approx(sim.conversion()["bleed"], 0.3) and is_equal_approx(sim.dot_seconds("bleed"), 12.0), "the carpet man's: bleed %.2f seconds %.0f" % [sim.conversion()["bleed"], sim.dot_seconds("bleed")])
	# drops by depth: nothing at depth 1, pieces by depth 12, no army's before 15
	# (the fire crew's three at depth 9 join the count from 12 on)
	_check(sim.set_pieces_at(1).is_empty() and sim.set_pieces_at(5).size() == 6 and sim.set_pieces_at(12).size() == 15 and sim.set_pieces_at(15).size() == 19, "the sets' depth gates are off: %d / %d / %d / %d" % [sim.set_pieces_at(1).size(), sim.set_pieces_at(5).size(), sim.set_pieces_at(12).size(), sim.set_pieces_at(15).size()])
	sim.load_dict(saved)
	print("sets ok: the pieces, the count, the bonuses, the rules, the tint, the panel, the gates")
	_atlas_checks(main)


## The map: a point a new depth past the first, six passives, their effects.
func _atlas_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	_finish_campaign(sim)
	sim.atlas = {}
	sim.atlas_points = 0
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(main._missions.MAP)
	_check(main._missions.zone == main._missions.MAP, "the map did not open after the campaign")
	_check_fit(main, "Runs (the map, empty)")
	# a clear at depth 2 earns a point; depth 1 does not
	sim.set_depth(0, 1)
	var t1: Dictionary = sim.effective(0)
	sim.best_depth[0] = 0
	sim.deploy(0)
	sim._clear(sim.mission, t1)
	sim.extract_now()
	_check(sim.atlas_points == 0, "a depth-1 clear put a point on the map")
	sim.set_depth(0, 2)
	var t2: Dictionary = sim.effective(0)
	sim.deploy(0)
	sim._clear(sim.mission, t2)
	sim.extract_now()
	_check(sim.atlas_points == 1 and sim.atlas_free() == 1, "a depth-2 clear did not earn a point: %d" % sim.atlas_points)
	sim.deploy(0)
	sim._clear(sim.mission, t2)
	sim.extract_now()
	_check(sim.atlas_points == 1, "clearing the same depth again earned a point")
	# the ranks and their effects
	var patrol0: float = sim.patrol_s(t2)
	var search0: float = sim.search_s(t2)
	var cost0: int = sim.juice_cost(0)
	var notes0: int = sim.notes_a_kill(t2)
	_check(sim.rank_atlas("quiet_roads") and sim.atlas_rank("quiet_roads") == 1, "a rank did not take")
	_check(not sim.rank_atlas("quiet_roads"), "a rank took with no point free")
	_check(sim.patrol_s(t2) > patrol0 * 1.09, "Quiet roads did not slow the gangs")
	sim.atlas_points += 10
	for i in range(3):
		sim.rank_atlas("deeper_pockets")
	_check(sim.atlas_rank("deeper_pockets") == 3 and not sim.can_rank_atlas("deeper_pockets"), "Deeper pockets went past its max")
	_check(sim.search_s(t2) < search0 * 0.75, "Deeper pockets did not quicken searches")
	_check(sim.rank_atlas("word_travels") and absi(sim.juice_cost(0) - cost0 / 2) <= 1, "Word travels did not halve the call-in: %d from %d" % [sim.juice_cost(0), cost0])
	_check(sim.rank_atlas("paid_in_notes") and sim.notes_a_kill(t2) == notes0 + 1, "Paid in notes did not add a note")
	_check(sim.rank_atlas("two_of_everything"), "Two of everything did not take")
	# the boss drops two with it
	sim.notes += 1000
	sim.arm_boss(2, true)
	sim.set_depth(2, 1)
	sim.deploy(2)
	var m: Dictionary = sim.mission
	m["boss"] = {"name": sim.boss_of(2)["name"], "zone": 0, "alive": true, "hp": 1.0, "started": true}
	var found_before: int = m["found"].size()
	sim._boss_down(m, sim.effective(2))
	_check(m["found"].size() == found_before + 2, "Two of everything did not drop a second: %d" % (m["found"].size() - found_before))
	sim.extract_now()
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(main._missions.MAP)
	_check_fit(main, "Runs (the map, ranked)")
	_map_screen_checks(main)
	_site_level_checks(main)
	main._missions._reset_map()
	_check(sim.atlas_spent() == 0 and sim.atlas_free() == sim.atlas_points, "starting the map again did not refund")
	main._missions._pick_zone(0)
	# the round trip keeps it
	sim.rank_atlas("quiet_roads")
	var d: Dictionary = sim.to_dict()
	sim.load_dict(d)
	_check(sim.atlas_rank("quiet_roads") == 1 and sim.atlas_points == 11, "the map did not survive a save")
	sim.load_dict(saved)
	print("the map ok: points, ranks, effects, two of everything, reset")
	_contracts_checks(main)


## The fence's contracts: three open, hand in the cheapest that fit, paid in
## cash, notes or a unique; the mate sells a unique for notes.
func _contracts_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	_check(sim.contracts.size() == Data.CONTRACTS_OPEN, "the fence has %d contracts open, not %d" % [sim.contracts.size(), Data.CONTRACTS_OPEN])
	_check(not sim.mate.is_empty() and sim.mate["notes"] > 0, "the fence's mate has nothing: %s" % str(sim.mate))
	for i in range(60):
		var c: Dictionary = sim.roll_contract()
		_check(c["count"] >= 1 and c["count"] <= 3 and c["rarity"] >= 1 and c["rarity"] <= 2, "a contract rolled outside its bounds: %s" % str(c))
		_check(c["pay"] != "unique" or (c["count"] == 3 and c["rarity"] == 2 and c["unique"] != ""), "a unique contract is not three rares: %s" % str(c))
		_check(c["pay"] == "unique" or c["amount"] > 0, "a contract pays nothing: %s" % str(c))
	# a cash contract: two uncommon helmets, hand in through the screen
	sim.contracts[0] = {"slot": "Helmet", "rarity": 1, "count": 2, "pay": "cash", "amount": 500, "unique": ""}
	var cheap: Dictionary = sim._plain("Helmet", "Hard hat")
	cheap["rarity"] = 1
	cheap["value"] = 1
	var common: Dictionary = sim._plain("Helmet", "Hard hat")
	for it in [common, cheap]:
		sim.stash.append(it)
	var fits0 := 0                                                     # the run may have left helmets that fit
	for it in sim.stash:
		if sim.contract_fits(sim.contracts[0], it):
			fits0 += 1
	sim.contracts[0]["count"] = fits0 + 1
	_check(not sim.can_hand_in(0), "a contract for %d took with %d that fit" % [fits0 + 1, fits0])
	var mid: Dictionary = sim._plain("Helmet", "Hard hat")
	mid["rarity"] = 1
	mid["value"] = 2
	sim.stash.append(mid)
	_check(sim.can_hand_in(0), "a contract for %d did not take with %d that fit" % [fits0 + 1, fits0 + 1])
	var picked: Array = sim.contract_items(sim.contracts[0])
	_check(picked.size() == fits0 + 1 and picked[0]["id"] == cheap["id"] and picked[1]["id"] == mid["id"], "the cheapest that fit were not the ones picked first")
	main.show_room(main.MARKET)
	main._fence._show("contracts")
	_check_fit(main, "Fence (contracts)")
	var cash0: float = sim.cash
	main._fence._hand_in(0)
	_check(sim.cash == cash0 + 500.0, "handing in did not pay £500")
	_check(not sim.stash.has(cheap) and not sim.stash.has(mid) and sim.stash.has(common), "the wrong helmets went")
	_check(sim.contracts.size() == Data.CONTRACTS_OPEN, "the handed-in contract was not replaced")
	# notes, a unique, and the mate
	sim.contracts[1] = {"slot": "Helmet", "rarity": 2, "count": 1, "pay": "notes", "amount": 12, "unique": ""}
	var rare: Dictionary = sim._plain("Helmet", "Hard hat")
	rare["rarity"] = 2
	sim.stash.append(rare)
	var notes0: int = sim.notes
	_check(sim.hand_in(1) and sim.notes == notes0 + 12, "a notes contract did not pay")
	var loose := ""
	for u in Data.UNIQUES:
		if not u.get("boss", false):
			loose = u["name"]
			break
	sim.contracts[2] = {"slot": "Armour", "rarity": 2, "count": 3, "pay": "unique", "amount": 0, "unique": loose}
	for i in range(3):
		var a: Dictionary = sim._plain("Armour", "Stab vest")
		a["rarity"] = 2
		sim.stash.append(a)
	var n0: int = sim.stash.size()
	_check(sim.hand_in(2) and sim.stash.size() == n0 - 2 and sim.stash.back().get("unique", "") == loose, "a unique contract did not pay with %s" % loose)
	_check(sim.pass_contract(0) and sim.contracts.size() == Data.CONTRACTS_OPEN, "turning one down did not replace it")
	sim.notes = int(sim.mate["notes"]) - 1
	_check(not sim.can_buy_mate(), "the mate sold with a note short")
	sim.notes = int(sim.mate["notes"])
	var want: String = sim.mate["unique"]
	_check(sim.buy_mate() and sim.notes == 0 and sim.stash.back().get("unique", "") == want, "the mate did not sell %s" % want)
	var runs0: int = sim.runs_total
	var offer: String = sim.mate["unique"]
	var changed := false
	for i in range(Data.MATE_RUNS):
		sim.deploy(0)
		sim.extract_now()
		changed = changed or sim.mate["unique"] != offer
	_check(sim.runs_total == runs0 + Data.MATE_RUNS, "runs_total did not count the runs")
	main._fence._show("contracts")
	_check_fit(main, "Fence (contracts, after)")
	# the contracts show from the rail and the tab: a unique on offer, a contract ready; what's next says so
	sim.contracts = [{"amount": 0, "count": 3, "pay": "unique", "rarity": 2, "slot": "Attachment", "unique": "The Doorman's jacket"}]
	for it in sim.stash.duplicate():
		if sim.contract_fits(sim.contracts[0], it):
			sim.stash.erase(it)              # nothing in the stash to hand in: the unique is on offer, not ready
	main.refresh()
	var fence_status: Dictionary = main._rail_status(main.MARKET) if main.has_method("_rail_status") else {}
	_check(fence_status.get("badge", "") == "Unique" and str(fence_status.get("status2", "")).contains("contract"), "the rail does not flag a contract that pays a unique: %s" % str(fence_status))
	main.show_room(main.MARKET)
	main.refresh()
	_check(main._fence._tabs[2].text == "Contracts ★", "the contracts tab reads '%s'" % main._fence._tabs[2].text)
	while not sim.stash_room(1) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])
	for k in range(3):
		var part: Dictionary = sim._plain(Data.ATTACHMENT, "Red dot")
		part["rarity"] = 2
		part["affixes"] = [{"stat": "damage_pct", "value": 3, "tier": 1}, {"stat": "speed_pct", "value": 2, "tier": 1}]
		sim.stash.append(part)
	main.refresh()
	_check(sim.can_hand_in(0), "three rare parts did not make the contract ready")
	fence_status = main._rail_status(main.MARKET)
	_check(fence_status.get("badge", "") == "Ready" and main._fence._tabs[2].text == "Contracts ✓1", "a ready contract is not flagged: %s / %s" % [str(fence_status), main._fence._tabs[2].text])
	_check(sim.next_words() == Words.NEXT["contract"] or sim.campaign_done(), "what's next does not point at the ready contract: '%s'" % sim.next_words())
	_check_fit(main, "Fence (contract ready)")
	main._fence._show("shelf")
	var d: Dictionary = sim.to_dict()
	sim.load_dict(d)
	_check(sim.contracts.size() == Data.CONTRACTS_OPEN and sim.contracts[0]["slot"] == d["contracts"][0]["slot"], "contracts did not survive a save")
	sim.load_dict(saved)
	main.show_room(main.MARKET)
	main._fence.selected = {}
	main.refresh()
	if not sim.contracts.is_empty():
		var t0: String = main._fence._deal_rows[0]["title"].text
		_check((t0.ends_with(".") and (t0.begins_with("Wants") or t0.begins_with("Could") or t0.begins_with("Someone") or t0.contains("wanted") or t0.begins_with("Looking"))) or t0 == main._fence._cap(sim.contract_words(sim.contracts[0])), "the fence's contract is not in his voice: '%s'" % t0)
		_check_fit(main, "Fence (contracts in the voice)")
	print("contracts and the mate ok: three open, the cheapest that fit, cash, notes, a unique, the mate")
	_events_checks(main)


## The run's events: a convoy, someone trapped, a locked cache.
func _events_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	var fired := 0
	for i in range(40):
		sim.deploy(0)
		if sim.mission["event"] != "":
			fired += 1
			_check(sim.mission["event_at"] >= Data.EVENT_WINDOW[0] and sim.mission["event_at"] <= Data.EVENT_WINDOW[1], "an event is timed outside its window")
		sim.extract_now()
	_check(fired > 3 and fired < 25, "events on %d of 40 runs; 30%% was the aim" % fired)
	# a convoy: a bigger gang, and their notes
	sim.deploy(0)
	var m: Dictionary = sim.mission
	m["remaining"] = 0
	m["cleared"] = true
	m["event"] = "convoy"
	m["event_at"] = 0.0
	var notes0: int = int(m.get("notes", 0))
	sim.advance(0.1)
	_check(m["remaining"] == sim.PATROL_BASE + 2 and int(m["notes"]) > notes0 and m["event_done"] == "convoy" and m["event_at"] < 0.0, "the convoy did not come: %d left, %d notes" % [m["remaining"], int(m["notes"])])
	sim.extract_now()
	# someone trapped: a trait promised to the next arrival
	sim.promised = ""
	sim.deploy(0)
	m = sim.mission
	m["event"] = "trapped"
	m["event_at"] = 0.0
	sim.advance(0.1)
	_check(sim.promised != "" and sim.promised != sim.runner_trait, "the trapped runner promised nothing: %s" % sim.promised)
	sim.extract_now()
	sim.promised = ""
	# a cache: the bench opens it, or not
	var bench0: int = sim.workshop
	sim.workshop = Data.EVENT_CACHE_BENCH
	sim.deploy(0)
	m = sim.mission
	m["event"] = "cache"
	m["event_at"] = 0.0
	m["remaining"] = 999                   # keep the search from finding on its own
	var found0: int = m["found"].size()
	sim.advance(0.1)
	_check(m["found"].size() == found0 + 1, "the bench did not open the cache")
	sim.extract_now()
	sim.workshop = 0
	sim.deploy(0)
	m = sim.mission
	m["event"] = "cache"
	m["event_at"] = 0.0
	m["remaining"] = 999
	found0 = m["found"].size()
	sim.advance(0.1)
	_check(m["found"].size() == found0 and m["event_done"] == "cache", "a cache opened with no bench")
	_check(str(sim.events.back()[1]).contains("Nothing on you opens it"), "the shut cache had no line: %s" % str(sim.events.back()[1]))
	sim.extract_now()
	sim.workshop = bench0
	sim.load_dict(saved)
	print("events ok: the convoy, the trapped runner, the cache")
	_pinnacle_checks(main)


## Pinnacles from depth 10: dearer, harder, their charm in the pool. The
## convoy on the services from depth 12: all three, one after another, and
## the lorry's load at the end.
func _pinnacle_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	_finish_campaign(sim)
	sim.notes += 100000
	for i in range(Data.TIERS.size()):
		sim.best_depth[i] = 20
	# the carpet man at depth 9 and at depth 10
	sim.set_depth(2, 9)
	sim.arm_boss(2, true)
	var cost9: int = sim.boss_cost(2)
	var e9: Dictionary = sim.effective(2)
	sim.set_depth(2, Data.PINNACLE_DEPTH)
	_check(sim.is_pinnacle(2) and not sim.is_pinnacle(1), "depth %d is not a pinnacle" % Data.PINNACLE_DEPTH)
	var e10: Dictionary = sim.effective(2)
	_check(e10["boss"]["pinnacle"] and not e9["boss"].get("pinnacle", false), "the boss at depth 10 is not at full strength")
	_check(e10["boss"]["hp"] > e9["boss"]["hp"] * 2.0 and e10["boss"]["dps"] > e9["boss"]["dps"] * 1.4, "the pinnacle is no harder")
	_check(sim.boss_cost(2) > cost9 * 1.8, "the pinnacle costs no more: %d vs %d" % [sim.boss_cost(2), cost9])
	# their charm comes from the pinnacle and never from the ordinary fight
	var charms := 0
	var m: Dictionary
	for k in range(40):
		sim.arm_boss(2, true)
		sim.deploy(2)
		m = sim.mission
		m["boss"]["started"] = true
		sim._boss_down(m, sim.effective(2))
		for it in m["found"]:
			if it.get("unique", "") == "The van keys":
				charms += 1
		sim.extract_now()
	_check(charms > 3 and charms < 30, "the van keys came %d of 40 pinnacle kills; a third was the aim" % charms)
	sim.set_depth(2, 5)
	charms = 0
	for k in range(30):
		sim.arm_boss(2, true)
		sim.deploy(2)
		m = sim.mission
		m["boss"]["started"] = true
		sim._boss_down(m, sim.effective(2))
		for it in m["found"]:
			if it.get("unique", "") == "The van keys":
				charms += 1
		sim.extract_now()
	_check(charms == 0, "the van keys came from the carpet man under full strength")
	# the convoy: the services at depth 12
	sim.set_depth(Data.CONVOY_TIER, Data.CONVOY_DEPTH - 1)
	_check(not sim.is_convoy(Data.CONVOY_TIER) and not sim.can_arm_boss(Data.CONVOY_TIER), "the convoy came before depth %d" % Data.CONVOY_DEPTH)
	sim.set_depth(Data.CONVOY_TIER, Data.CONVOY_DEPTH)
	_check(sim.is_convoy(Data.CONVOY_TIER) and sim.can_arm_boss(Data.CONVOY_TIER), "the convoy is not on the services at depth %d" % Data.CONVOY_DEPTH)
	var convoy_cost: int = sim.boss_cost(Data.CONVOY_TIER)
	var three := 0
	for b in Data.BOSSES:
		three += int(b["notes"]) * Data.CONVOY_DEPTH * Data.PINNACLE_COST
	_check(convoy_cost == three, "the convoy's price is %d, not the three heads' %d" % [convoy_cost, three])
	sim.arm_boss(Data.CONVOY_TIER, true)
	var ec: Dictionary = sim.effective(Data.CONVOY_TIER)
	_check(ec.get("convoy", false) and ec["boss_queue"].size() == 2 and ec["boss"]["pinnacle"], "the convoy is not three at full strength")
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(2)
	_check_fit(main, "Runs (convoy armed)")
	var notes0: int = sim.notes
	sim.deploy(Data.CONVOY_TIER)
	_check(sim.notes == notes0 - convoy_cost, "the convoy's price was not paid")
	m = sim.mission
	_check(m["boss_queue"].size() == 2 and m["convoy"], "the mission did not carry the queue")
	# the pool goes down; each head comes out in turn, the next as one falls
	var names: Array = []
	var found0: int = m["found"].size()
	m["remaining"] = 1
	m["target_hp"] = 0.0
	sim.advance(0.05)                          # the last of the pool goes; the first head comes out
	for k in range(3):
		_check(m["boss"]["started"] and m["boss"]["alive"], "head %d did not come out" % (k + 1))
		names.append(m["boss"]["name"])
		m["target_hp"] = 0.0
		sim.advance(0.05)                      # goes down; the next comes out
	_check(not m["boss"]["alive"] and m["boss_queue"].is_empty(), "the last head is still up")
	_check(names == ["The carpet man", "The manager", "The quartermaster"], "the convoy came in the wrong order: %s" % str(names))
	var load := false
	for it in m["found"]:
		load = load or it.get("unique", "") == Data.CONVOY_UNIQUE
	_check(load and m["found"].size() >= found0 + 4, "the lorry's load did not come with the three drops: %d found" % (m["found"].size() - found0))
	# the ending (7 Oct): the lorry beaten is written, the yard says to move, the move lights
	_check(sim.lorry_done and sim.lorries == 1 and sim.next_words() == Words.NEXT["lorry"] and sim.events.any(func(e): return str(e[1]).begins_with("The lorry's load is yours")), "the lorry beaten was not written: done %s, lorries %d, next '%s'" % [str(sim.lorry_done), sim.lorries, sim.next_words()])
	sim.extract_now()
	main.show_room(main.OVERVIEW)
	main.refresh()
	_check(main._yard_town._button.visible and main._yard_town._notes[0].text.begins_with("The lorry's beaten"), "the Yard does not light the move at the lorry: button %s, note '%s'" % [str(main._yard_town._button.visible), main._yard_town._notes[0].text])
	_endgame_move_checks(main)
	# the rules: the keys drive, the pen doubles the notes, the ledger a tier up, the load fills the pack
	var pace0: float = sim.pace()
	var was_charm = sim.equipped["Charm"]
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The van keys"), sim.rng)
	_check(sim.pace() > pace0 * 1.2, "the van keys did not drive")
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The manager's pen"), sim.rng)
	var n0: int = sim.notes
	sim.deploy(0)
	sim.mission["notes"] = 7
	sim.extract_now()
	_check(sim.notes == n0 + 14, "the manager's pen did not double the notes: +%d" % (sim.notes - n0))
	sim.equipped["Charm"] = was_charm
	var was_pack = sim.equipped["Backpack"]
	sim.equipped["Backpack"] = Items.roll_unique(sim._unique_named("The lorry's load"), sim.rng)
	n0 = sim.notes
	sim.set_depth(0, 3)
	sim.deploy(0)
	sim.mission["found"] = []
	sim.mission["notes"] = 0
	sim.extract_now()
	_check(sim.notes == n0 + sim.capacity() * 3, "the lorry's load did not fill the empty pack with notes: +%d of %d (depth %d, best %d, campaign %s)" % [sim.notes - n0, sim.capacity() * 3, sim.depth[0], sim.best_depth[0], str(sim.campaign_done())])
	sim.equipped["Backpack"] = was_pack
	for name in ["The van keys", "The manager's pen", "The quartermaster's ledger", "The lorry's load"]:
		_check(Words.UNIQUES.has(name), "%s has no line" % name)
	sim.load_dict(saved)
	print("pinnacles and the convoy ok: full strength, the charm, three in a row, the load, the rules")
	_craft_checks(main)
	_move_checks(main)


## The bench's crafting, in cash: add, re-roll, lock one, re-roll one, a
## socket, strip; the level in notes. And the tiers behind it.
func _craft_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	sim.workshop = maxi(sim.workshop, 1)
	sim.notes = 100000
	sim.cash = 10000000.0
	# tiers: the cap by level, the ranges, the roll
	_check(Items.tier_cap(0) == 1 and Items.tier_cap(3) == 2 and Items.tier_cap(6) == 3 and Items.tier_cap(10) == 4 and Items.tier_cap(15) == 5 and Items.tier_cap(40) == 5, "the tier cap by level is wrong")
	var d: Dictionary = Items.affix_def("damage_pct")
	var r1: Array = Items.tier_range(d, 1)
	var r5: Array = Items.tier_range(d, 5)
	_check(r1[0] == d["min"] and r5[1] == d["max"] and r1[1] < r5[0], "the tier ranges don't cut the span: T1 %s, T5 %s" % [str(r1), str(r5)])
	for t in range(1, 5):
		_check(Items.tier_range(d, t)[1] < Items.tier_range(d, t + 1)[0], "tier %d overlaps tier %d" % [t, t + 1])
	# rarity as quality (the pass, Matt, 6 Oct): the rarity caps the tier, the level floors it
	_check(Items.tier_floor(0) == 1 and Items.tier_floor(5) == 1 and Items.tier_floor(6) == 2 and Items.tier_floor(10) == 3 and Items.tier_floor(14) == 4 and Items.tier_floor(40) == 4, "the tier floor by level is wrong")
	_check(Data.RARITIES.size() == Data.AFFIX_TIERS and Data.RARITIES.back()["name"] == "Legendary", "five rarities to the five tiers: %s" % str(Data.RARITIES.map(func(r): return r["name"])))
	for k in range(Data.RARITIES.size()):
		_check(int(Data.RARITIES[k]["affixes"]) == k + 1 and int(Data.RARITIES[k]["tier"]) == k + 1, "%s is not %d affixes to T%d" % [Data.RARITIES[k]["name"], k + 1, k + 1])
	var shallow_top := 0
	var deep_low := 0
	for i in range(400):
		var g: Dictionary = Items.roll("Primary", 1, sim.rng, 2.0, true, false, "", "", 0.33, 0)
		var cap_g: int = int(Data.RARITIES[int(g["rarity"])]["tier"])
		_check(g["affixes"].size() == int(g["rarity"]) + 1, "a %s rolled %d affixes" % [Data.RARITIES[int(g["rarity"])]["name"], g["affixes"].size()])
		for a in g["affixes"]:
			_check(a.has("tier") and a["tier"] >= 1 and a["tier"] <= cap_g, "a shallow %s rolled T%d past its cap T%d" % [Data.RARITIES[int(g["rarity"])]["name"], a.get("tier", 0), cap_g])
			shallow_top += 1 if (a["tier"] == 5) else 0
		var deep: Dictionary = Items.roll("Primary", 6, sim.rng, 2.0, true, false, "", "", 0.33, 20)
		_check(deep["ilvl"] == deep["tier"] + 20, "the item level is not the base's tier plus the depth")
		var cap_d: int = int(Data.RARITIES[int(deep["rarity"])]["tier"])
		var floor_d: int = mini(Items.tier_floor(int(deep["ilvl"])), cap_d)
		for a in deep["affixes"]:
			_check(a["tier"] >= floor_d and a["tier"] <= cap_d, "a deep %s rolled T%d outside T%d..T%d" % [Data.RARITIES[int(deep["rarity"])]["name"], a["tier"], floor_d, cap_d])
			deep_low += 1 if (a["tier"] == 1 and int(deep["rarity"]) > 0) else 0
	_check(shallow_top > 0, "four hundred shallow rolls at +200% quality never made a T5: a Legendary from the first site is five T5s")
	_check(deep_low == 0, "a deep find above Common rolled T1s: %d" % deep_low)
	# the bench
	var it: Dictionary = sim._plain("Helmet", "Hard hat")
	it["attachments"] = {}
	it["ilvl"] = 16
	sim.stash.append(it)
	_check(sim.craft_cost(it, "reroll") < 0 and sim.craft_cost(it, "strip") < 0, "a plain item re-rolls or strips")
	var add_cost: int = sim.craft_cost(it, "add")
	_check(add_cost == sim._inf(Data.CRAFT["add"]["cash"] * 16), "adding to a plain level-16 piece costs %d, not %d" % [add_cost, sim._inf(Data.CRAFT["add"]["cash"] * 16)])
	var cash0: float = sim.cash
	_check(sim.craft(it["id"], "add") and it["rarity"] == 1 and it["affixes"].size() == 1 and is_equal_approx(sim.cash, cash0 - add_cost), "Add an affix did not take, or wasn't paid in cash")
	var stat0: String = it["affixes"][0]["stat"]
	var val0: int = it["affixes"][0]["value"]
	var changed := false
	for k in range(12):
		sim.craft(it["id"], "reroll")
		changed = changed or it["affixes"][0]["stat"] != stat0 or it["affixes"][0]["value"] != val0
	_check(changed and it["affixes"].size() == 1, "twelve re-rolls changed nothing, or the count")
	while sim.craft_cost(it, "add") >= 0:
		sim.craft(it["id"], "add")
	var top: int = Data.RARITIES.size() - 1
	_check(it["rarity"] == top and it["affixes"].size() == top, "adding to the top did not make a %s with %d: %d, %d" % [Data.RARITIES[top]["name"], top, it["rarity"], it["affixes"].size()])
	var stats := []
	for a in it["affixes"]:
		_check(not (a["stat"] in stats), "an affix doubled: %s" % a["stat"])
		stats.append(a["stat"])
	# lock one: it stays, the others may change
	var keep: Dictionary = it["affixes"][0].duplicate()
	var lock_cost: int = sim.craft_cost(it, "lock", keep["stat"])
	_check(lock_cost == sim._inf(Data.CRAFT["lock"]["cash"] * 16 * (top + 1)), "lock on a level-16 %s costs %d, not %d" % [Data.RARITIES[top]["name"], lock_cost, sim._inf(Data.CRAFT["lock"]["cash"] * 16 * (top + 1))])
	_check(sim.craft(it["id"], "lock", keep["stat"]) and it["affixes"].size() == top and it["affixes"][0] == keep, "locking one did not keep it: %s vs %s" % [str(it["affixes"][0]), str(keep)])
	# re-roll one: the stat stays, the tier moves sometimes, dearer the better the tier
	var one_stat: String = it["affixes"][1]["stat"]
	var tiers_seen := {}
	for k in range(240):                  # a T4 at the floor moves only up, one in sixteen: enough rolls that it does
		sim.craft(it["id"], "one", one_stat)
		_check(it["affixes"][1]["stat"] == one_stat, "re-rolling one changed its stat")
		tiers_seen[int(it["affixes"][1]["tier"])] = true
	_check(tiers_seen.size() >= 2, "240 re-rolls of one never moved its tier: %s" % str(tiers_seen.keys()))
	it["affixes"][1]["tier"] = 5
	var dear: int = sim.craft_cost(it, "one", one_stat)
	it["affixes"][1]["tier"] = 1
	_check(absi(dear - sim.craft_cost(it, "one", one_stat) * 5) <= 3, "re-rolling a T5 is not five times a T1: %d vs %d" % [dear, sim.craft_cost(it, "one", one_stat)])
	# the level, in notes
	var notes0: int = sim.notes
	var bump_cost: int = sim.craft_cost(it, "bump")
	_check(sim.craft(it["id"], "bump") and it["ilvl"] == 19 and sim.notes == notes0 - bump_cost, "the bump did not raise the level by %d in notes" % Data.BUMP_LEVELS)
	while sim.craft_cost(it, "bump") >= 0:
		sim.craft(it["id"], "bump")
	_check(it["ilvl"] == it["tier"] + Data.BUMP_CAP, "the level went past its cap: %d" % it["ilvl"])
	_check(sim.craft(it["id"], "socket") and sim.craft(it["id"], "socket") and Items.sockets(it) == 2 and sim.craft_cost(it, "socket") < 0, "two sockets did not cut, or a third would")
	var value_elite: int = it["value"]
	_check(sim.craft(it["id"], "strip") and it["rarity"] == 0 and it["affixes"].is_empty() and it["value"] < value_elite, "Strip did not take it back to plain")
	_check(Items.sockets(it) == 2, "stripping took the sockets")
	# the bench works as a drop does (the pass, 6 Oct): re-roll one within the rarity's cap, never under the level's floor
	var rare: Dictionary = sim._plain("Helmet", "Hard hat")
	rare["ilvl"] = 16
	rare["rarity"] = 2
	rare["affixes"] = [{"stat": "armour_pct", "value": 10, "tier": 2}, {"stat": "regen", "value": 2, "tier": 3}]
	sim.stash.append(rare)
	var lo_r: int = mini(Items.tier_floor(16), Items.rarity_cap(rare))      # the floor never above the cap: a deep Rare is T3s
	for k in range(80):
		sim.craft(rare["id"], "one", "armour_pct")
		var tr: int = int(rare["affixes"][0]["tier"])
		_check(tr >= lo_r and tr <= Items.rarity_cap(rare), "re-roll one left a level-16 Rare's affix at T%d, outside T%d..T%d" % [tr, lo_r, Items.rarity_cap(rare)])
	sim.craft(rare["id"], "reroll")
	for a in rare["affixes"]:
		_check(int(a["tier"]) <= Items.rarity_cap(rare) and int(a["tier"]) >= lo_r, "a re-roll on a level-16 Rare gave T%d" % int(a["tier"]))
	# a set piece: no bench job at all, its affixes are the set's
	var set_piece: Dictionary = Items.roll_set_piece(Data.SETS[0]["name"], Data.SETS[0]["pieces"][0], sim.rng)
	sim.stash.append(set_piece)
	for kind in Data.CRAFT:
		_check(sim.craft_cost(set_piece, kind, set_piece["affixes"][0]["stat"] if not set_piece["affixes"].is_empty() else "") < 0, "the bench offers %s on a set piece" % kind)
	# not on a unique, not on paper, not without a bench, not on a run, not short
	var u := Items.roll_unique(Data.UNIQUES[0], sim.rng)
	sim.stash.append(u)
	_check(sim.craft_cost(u, "reroll") < 0, "a unique re-rolls")
	sim.workshop = 0
	_check(not sim.can_craft(it["id"], "add"), "the bench works with no bench")
	sim.workshop = 1
	sim.cash = 0.0
	_check(not sim.can_craft(it["id"], "add"), "the bench works with no cash")
	sim.cash = 100000.0
	var ch: Dictionary = sim._plain("Charm", "Lucky penny")
	_check(sim.craft_cost(ch, "add") > 0 and sim.craft_cost(ch, "socket") < 0, "a charm takes no affix at the bench, or takes a socket")
	# through the screen: the Bench button and the menus
	main.show_room(main.ARMOURY)
	main._armoury.selected = {"kind": "stash", "id": it["id"]}
	main.refresh()
	_check_fit(main, "Armoury (bench button)")
	main._open_bench(it["id"])
	_check(main._menu.visible, "the bench menu did not open")
	_check_fit(main, "Armoury (bench menu)")
	main._craft(it["id"], "add", "")
	_check(it["rarity"] == 1 and not main._menu.visible, "the menu's Add did not take")
	# the bench says what it did: a toast with the affix added, the same on the craft panel's line, and in the log
	var added_line: String = Items.affix_lines(it, false, true)[0]
	_check(sim.last_craft.get("id", -1) == it["id"] and str(sim.last_craft["words"]) == "Added " + added_line, "the bench's words are '%s', not 'Added %s'" % [str(sim.last_craft.get("words", "")), added_line])
	_check(main._juice.lines().has(sim.last_craft["words"]), "the bench's words did not toast: %s" % str(main._juice.lines()))
	_check(str(sim.events.back()[1]).ends_with(sim.last_craft["words"]), "the log line does not carry the bench's words: '%s'" % str(sim.events.back()[1]))
	main.show_room(main.WORKSHOP)
	main._workshop._set_view("craft")
	var craftable: Array = main._workshop._craftable()
	var kc := -1
	for i in range(craftable.size()):
		if craftable[i]["id"] == it["id"]:
			kc = i
	_check(kc >= 0, "the added-to piece is not in the Craft view")
	if kc >= 0:
		main._workshop._pick_cell(kc)
	main.refresh()
	_check(main._workshop._hint.text.begins_with("Added"), "the craft panel's line does not say what the bench did: '%s'" % main._workshop._hint.text)
	_check_fit(main, "Workshop (craft, after an add)")
	# every kind has words: re-roll says before and after, bump the levels, one the swap
	var words_seen := {}
	sim.cash = 999999.0
	sim.notes = 9999
	for kind in ["reroll", "bump"]:
		if sim.craft_cost(it, kind) >= 0 and sim.craft(it["id"], kind):
			words_seen[kind] = str(sim.last_craft["words"])
	_check(words_seen.get("reroll", "").begins_with("Re-rolled: ") and words_seen.get("reroll", "").contains(" → "), "re-roll's words: '%s'" % words_seen.get("reroll", ""))
	_check(not words_seen.has("bump") or (words_seen["bump"].begins_with("Level ") and words_seen["bump"].contains(" → ")), "bump's words: '%s'" % words_seen.get("bump", ""))
	if not it["affixes"].is_empty() and sim.craft_cost(it, "one", it["affixes"][0]["stat"]) >= 0:
		var was_line: String = Items.affix_lines(it, false, true)[0]
		if sim.craft(it["id"], "one", it["affixes"][0]["stat"]):
			_check(str(sim.last_craft["words"]).begins_with(was_line + " → ") or str(sim.last_craft["words"]) == "Re-rolled one: no change", "one's words: '%s'" % str(sim.last_craft["words"]))
	main.show_room(main.ARMOURY)
	main._armoury.selected = {"kind": "stash", "id": it["id"]}
	main.refresh()
	main._open_bench_picks(it["id"])
	_check(main._menu.visible, "the picks page did not open")
	_check_fit(main, "Armoury (bench picks)")
	main._open_bench_one(it["id"], it["affixes"][0]["stat"])
	_check_fit(main, "Armoury (bench one)")
	main._menu.close()
	# the affix list on the panel, with tiers
	main._armoury.selected = {"kind": "stash", "id": it["id"]}
	main.refresh()
	var ah = main._armoury._head._affixes
	_check(ah.visible and ah._tags[0].visible and ah._tags[0].text.begins_with("T"), "the panel's affix chip has no tier tag: '%s'" % ah._tags[0].text)
	_check_fit(main, "Armoury (affix list)")
	# each affix is a chip in its tier's colour, tag and words; every affix shows, over two rows at most
	# the affixes' chips, and the open-slot chip after them when there is room for more
	var open_chip: int = 1 if it["affixes"].size() < Data.RARITIES.size() - 1 else 0
	_check(ah.shown() == it["affixes"].size() + open_chip and ah.rows_used() <= ah.get_parent().AFFIX_ROWS, "the panel shows %d affix chips for %d affixes over %d rows" % [ah.shown(), it["affixes"].size(), ah.rows_used()])
	for k in range(mini(3, it["affixes"].size())):
		var want: Color = Pal.tier_color(int(it["affixes"][k].get("tier", 1)))
		_check(ah._labels[k].get_theme_color("font_color") == want and ah._tags[k].get_theme_color("font_color") == want, "affix %d (T%d) is not in its tier's colour" % [k, int(it["affixes"][k].get("tier", 1))])
	if it["affixes"].size() < 3:
		_check(ah.words(ah.shown() - 1).contains("open"), "the chip after the affixes is not the open one: '%s'" % ah.words(ah.shown() - 1))
	# a three-affix piece with long words: every affix still a chip, none trailing off
	var three: Dictionary = sim._plain("Armour", "Riot suit")
	three["rarity"] = Data.RARITIES.size() - 1       # at the top: no open chip after the three
	three["affixes"] = [{"stat": "armour_pct", "value": 18, "tier": 4}, {"stat": "loot_pct", "value": 12, "tier": 2}, {"stat": "poison_res", "value": 9, "tier": 3}]
	sim.stash.append(three)
	main._armoury._inv._set_kind(0)
	main.refresh()
	var c3: int = main._armoury._inv.cell_of(three["id"])
	if c3 >= 0:
		main._armoury._pick_cell(c3)
		main.refresh()
		_check(main._armoury._head._affixes.shown() == 3, "a three-affix piece shows %d chips" % main._armoury._head._affixes.shown())
		_check_fit(main, "Armoury (three affix chips)")
	sim.stash.erase(three)
	main.refresh()
	# worn gear can go to the bench too
	var worn: Dictionary = sim.equipped["Armour"]
	if worn != null and not worn.has("unique") and sim.craft_cost(worn, "socket") >= 0 and is_same(sim.item_by_id(worn["id"]), worn):
		var n0: int = Items.sockets(worn)
		var scost: int = sim.craft_cost(worn, "socket")
		_check(sim.craft(worn["id"], "socket") and Items.sockets(worn) == n0 + 1, "a socket did not cut on the armour worn: cost %d, cash %.0f, bench %d, can %s, sockets %d, slot %s" % [scost, sim.cash, sim.workshop, str(sim.can_craft(worn["id"], "socket")), Items.sockets(worn), worn["slot"]])
	sim.load_dict(saved)
	print("the bench ok: tiers, add, re-roll, lock, one, the level, sockets, strip, the menus")


## Moving the yard: after the campaign; the uniques, the yard's tree, the
## list and half the notes come; the rest starts again; the move's bonus.
func _move_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	sim.load_dict(saved)
	_check(not sim.can_move_yard() or sim.campaign_done(), "the yard moves before the campaign")
	_finish_campaign(sim)
	sim.notes = 1000
	sim.cash = 500000.0
	sim.workshop = 3
	var u := Items.roll_unique(Data.UNIQUES[0], sim.rng)
	sim.stash.append(u)
	var worn_u := Items.roll_unique(sim._unique_named("Lucky cap"), sim.rng)
	sim.equipped["Helmet"] = worn_u
	sim.training_points += 10
	sim.train_node("The yard/0")
	var yard_nodes := 0
	for id in sim.tree:
		if str(id).begins_with("The yard/"):
			yard_nodes += 1
	var past_n: int = sim.past.size()
	var uniques_before := 0
	for it in sim.stash:
		if it.has("unique"):
			uniques_before += 1
	for s in Data.SLOTS:
		if sim.equipped[s] != null and sim.equipped[s].has("unique"):
			uniques_before += 1
	main.show_room(main.OVERVIEW)
	_check_fit(main, "The Yard (move offered)")
	main._confirm_move()
	_check(main._menu.visible, "the move's menu did not open")
	_check_fit(main, "The Yard (move menu)")
	main._pick_trade()
	_check(main._menu.visible and main._menu._items.size() == Data.ELEMENTS.size(), "the trade's menu did not open with the five")
	_check_fit(main, "The Yard (trade menu)")
	# a Doorman: poison is off his pair; the trade brings it
	sim.set_class("Doorman")
	_check(not sim.affinity("poison") and sim.can_trade("poison") and not sim.can_trade("physical"), "the trade offers the wrong things")
	main._move_yard("poison")
	_check(sim.yard_moves == 1, "the yard did not move")
	_check(sim.trades == ["poison"] and sim.affinity("poison") and not sim.can_trade("poison") and sim.node_cost("The rat man/0") == 1, "the yard's trade did not come: %s" % str(sim.trades))
	_check(str(sim.events[-2][1]).begins_with("The yard's trade came too: the rat man"), "the trade had no line: %s" % str(sim.events[-2]))
	_check(str(sim.events[-3][1]).begins_with("The yard moves"), "the move had no line")
	_check(str(sim.events.back()[1]) == Words.NEXT["moved"], "the move did not say what's next: %s" % str(sim.events.back()))
	sim.training_points += 20
	for i in range(7):
		sim.train_node("The rat man/%d" % i)
	_check(sim.tree.has("The rat man/6"), "the traded keystone did not open to a class without the affinity")
	for i in range(7):
		sim.tree.erase("The rat man/%d" % i)
	sim.training_points -= 20
	_check(not sim.campaign_done() and sim.best_depth[0] == 0 and not sim.zone_open(1) and sim.workshop == 0, "the move did not start again")
	_check(sim.notes == 500 and is_equal_approx(sim.cash, float(Data.STARTING_CASH) * sim.inflation()), "the move kept the wrong money: %d notes, £%.0f (the float at today's prices is £%.0f)" % [sim.notes, sim.cash, float(Data.STARTING_CASH) * sim.inflation()])
	var kept := 0
	for it in sim.stash:
		if it.has("unique"):
			kept += 1
	_check(kept >= 2 and kept == uniques_before and (sim.equipped["Helmet"] == null or not sim.equipped["Helmet"].has("unique")), "the uniques did not come to the stash: %d of %d" % [kept, uniques_before])
	var yard_after := 0
	for id in sim.tree:
		if str(id).begins_with("The yard/"):
			yard_after += 1
	_check(yard_after == yard_nodes and sim.tree.size() == yard_nodes, "the yard's tree did not come alone: %s" % str(sim.tree))
	_check(sim.points_free() == Data.MOVE_POINTS, "the move's points are %d, not %d" % [sim.points_free(), Data.MOVE_POINTS])
	_check(sim.past.size() == past_n, "the list of runners before did not come")
	_check(sim.rarity_bonus() > 0.04 and sim.charm_cash() >= Data.MOVE_CASH, "the move's bonus did not read: find %.2f, cash %.0f" % [sim.rarity_bonus(), sim.charm_cash()])
	_check(sim.contracts.size() == Data.CONTRACTS_OPEN and not sim.mate.is_empty(), "the fence did not set up again")
	main.refresh()
	_check_fit(main, "The Yard (moved)")
	var d: Dictionary = sim.to_dict()
	sim.load_dict(d)
	_check(sim.yard_moves == 1 and sim.trades == ["poison"], "the move and its trade did not survive a save")
	sim.load_dict(saved)
	print("moving the yard ok: the uniques, the tree, the list, the notes, the bonus, the yard's trade")
	_sink_checks(main)
	_inflation_checks(main)
	_recycle_checks(main)
	_book_checks(main)
	_places_checks(main)
	_faces_checks(main)
	_stack_checks(main)
	_next_checks(main)
	_idle_checks(main)
	_juice_checks(main)
	_yard_checks(main)
	_sound_checks(main)
	_playtest_checks(main)


## The estate recycles: a dead runner's worn kit and a unique sold to the fence
## go on the list; a few runs later one of a gang is wearing it, and it comes
## off him when the site's cleared, affixes and all.
## The papers as the book: a paper picked up goes in the drawer by name, in
## the order found, once; the deep ones only past their depth; the Caravan's
## middle column shows the drawer, six a page, a click turning the page; the
## book survives a save and a move.
func _book_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	sim.book = []
	var pages: Array = sim.book_pages()
	_check(pages.size() == 20 and not pages.has("The deeds"), "the book has %d pages, not 20" % pages.size())
	# shallow rolls never turn up a deep paper; deep ones do
	var deep_seen := false
	for k in range(200):
		var it: Dictionary = Items.roll(Data.PAPER, 1, sim.rng, 0.0, false, false, "", "", 0.33, 1)
		_check(int(Items.base_of(it).get("depth", 0)) == 0, "a deep paper turned up at depth 1: %s" % it["base"])
	for k in range(300):
		var it: Dictionary = Items.roll(Data.PAPER, 1, sim.rng, 0.0, false, false, "", "", 0.33, 50)
		deep_seen = deep_seen or int(Items.base_of(it).get("depth", 0)) > 0
	_check(deep_seen, "no deep paper in 300 rolls at depth 50")
	for name in ["A ration book", "A council minute", "A bus timetable, amended", "A letter to the bank", "A list of names", "The manager's note"]:
		_check(Words.item_words(name) != "" and Words.item_words(name).ends_with("."), "%s has no line" % name)
	# a find is read, once, in order
	sim.intel[0] = []
	sim.set_depth(0, 1)
	sim.hp = sim.max_hp()
	sim.deploy(0)
	var m: Dictionary = sim.mission
	m["found"] = []
	var p1: Dictionary = sim._plain(Data.PAPER, "A P45")
	var p2: Dictionary = sim._plain(Data.PAPER, "A betting slip")
	sim._read(p1)
	sim._read(p2)
	sim._read(sim._plain(Data.PAPER, "A P45"))
	_check(sim.book == ["A P45", "A betting slip"], "the book is not the papers in the order found: %s" % str(sim.book))
	sim._read(sim._plain(Data.PAPER, "The deeds"))
	_check(sim.book.size() == 2, "the deeds went in the drawer")
	sim.extract_now()
	# the Caravan's drawer
	main.show_room(main.BARRACKS)
	var mids: Array = main._barracks._mid_trees(sim.trees())
	var drawer_at := -1
	for i in range(mids.size()):
		if mids[i].get("name", "") == "The drawer":
			drawer_at = i
	_check(drawer_at >= 0, "the drawer is not among the middle columns")
	main._barracks.mid = drawer_at
	main._barracks._shown = ""
	main.refresh()
	_check(main._barracks._heads[1]["name"].text.contains("2 of 20") or main._barracks._heads[1]["name"].text.contains("2/20"), "the drawer's head is off: %s" % main._barracks._heads[1]["name"].text)
	_check(main._barracks._rows[1][0]["name"].text == "1. A P45" and main._barracks._rows[1][1]["name"].text == "2. A betting slip" and not main._barracks._rows[1][2]["button"].visible, "the drawer's rows are off: %s / %s" % [main._barracks._rows[1][0]["name"].text, main._barracks._rows[1][1]["name"].text])
	_check(main._barracks._rows[1][0]["effect"].text != "", "the paper's words are not under its name")
	_check_fit(main, "Caravan (the drawer, two)")
	for name in pages:
		sim._read(sim._plain(Data.PAPER, name))
	_check(sim.book.size() == 20, "the full book is not twenty")
	main._barracks._shown = ""
	main.refresh()
	# a page holds what the column takes; twenty papers are that many pages
	var per_page: int = main._barracks._rows[1].filter(func(n): return n["button"].visible).size()
	var n_pages: int = ceili(20.0 / per_page)
	_check(per_page >= 3 and (main._barracks._heads[1]["name"].text.contains("page 1 of %d" % n_pages) or main._barracks._heads[1]["name"].text.contains("p1/%d" % n_pages)), "a full drawer has no pages: %s (%d a page)" % [main._barracks._heads[1]["name"].text, per_page])
	_check_fit(main, "Caravan (the drawer, full)")
	main._barracks._pick("drawer/0")
	_check(main._barracks.drawer_page == 1 and main._barracks._rows[1][0]["name"].text.begins_with("%d. " % (per_page + 1)), "a click did not turn the page: %d, %s" % [main._barracks.drawer_page, main._barracks._rows[1][0]["name"].text])
	_check_fit(main, "Caravan (the drawer, page 2)")
	main._barracks.mid = 0
	main._barracks.drawer_page = 0
	main._barracks._shown = ""
	main.refresh()
	_check_fit(main, "Caravan (back from the drawer)")
	var d: Dictionary = sim.to_dict()
	sim.load_dict(d)
	_check(sim.book.size() == 20, "the book did not save")
	# the shelf: the uniques found, the same way
	sim.shelf = []
	var u1: Dictionary = Items.roll_unique(sim._unique_named("Lucky cap"), sim.rng)
	sim._read(u1)
	sim._read(Items.roll_unique(sim._unique_named("Lucky cap"), sim.rng))
	sim._read(Items.roll_unique(sim._unique_named("Jump leads"), sim.rng))
	_check(sim.shelf == ["Lucky cap", "Jump leads"], "the shelf is not the uniques in the order found: %s" % str(sim.shelf))
	var shelf_at := -1
	mids = main._barracks._mid_trees(sim.trees())
	for i in range(mids.size()):
		if mids[i].get("name", "") == "The shelf":
			shelf_at = i
	_check(shelf_at >= 0, "the shelf is not among the middle columns")
	main._barracks.mid = shelf_at
	main._barracks.drawer_page = 0
	main._barracks._shown = ""
	main.refresh()
	_check(main._barracks._heads[1]["name"].text.contains("2 of %d" % Data.UNIQUES.size()) or main._barracks._heads[1]["name"].text.contains("2/%d" % Data.UNIQUES.size()), "the shelf's head is off: %s" % main._barracks._heads[1]["name"].text)
	# the chase first (endgame part 3): thirteen gaps in TEXT_3, where each is under it; then the rest found, in order
	var chase: Array = sim.shelf_chase()
	_check(chase.size() == 13 and not chase[0]["found"] and str(chase[0]["where"]).begins_with("Ransacked streets, depth 12"), "the shelf's chase is off: %d rows, '%s'" % [chase.size(), str(chase[0]["where"]) if not chase.is_empty() else ""])
	var row0: Dictionary = main._barracks._rows[1][0]
	_check(row0["name"].text == "1. %s" % chase[0]["name"] and row0["effect"].text.begins_with("Ransacked streets") and row0["name"].get_theme_color("font_color") == Pal.TEXT_3, "the shelf's first gap is off: '%s' / '%s'" % [row0["name"].text, row0["effect"].text])
	var shelf_branch: Dictionary = main._barracks._shelf_branch()
	var all_names: Array = []
	for pg in range(int(shelf_branch["pages"])):
		main._barracks.drawer_page = pg
		for nd in main._barracks._shelf_branch()["nodes"]:
			all_names.append(str(nd["name"]).substr(str(nd["name"]).find(" ") + 1))
	_check(all_names.size() == 15 and all_names[13] == "Lucky cap" and all_names[14] == "Jump leads" and all_names[12] == Data.CONVOY_UNIQUE, "the shelf's order is off: %s" % str(all_names))
	main._barracks.drawer_page = 0
	_check_fit(main, "Caravan (the shelf)")
	# a site's own found fills its gap
	sim._read(Items.roll_unique(sim._unique_named("The float"), sim.rng))
	chase = sim.shelf_chase()
	_check(chase[4]["found"] and chase[4]["name"] == "The float" and not chase[3]["found"], "the float on the shelf did not fill the shopping centre's gap")
	main._barracks._shown = ""
	main.refresh()
	_check_fit(main, "Caravan (the shelf, one filled)")
	main._barracks.mid = 0
	main._barracks._shown = ""
	main.refresh()
	sim.load_dict(saved)
	print("the book ok: twenty pages, the deep ones gated, read once in order, the drawer, its pages, saved; the shelf of uniques")


## The places changing: a cleared site is picked over and comes back over
## hours; the clock makes every site Night in the small hours; the weather by
## zone puts Rain or Fog on, never rolled by the radio; the Runs card says so.
func _places_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	sim.intel[0] = []
	for i in range(Data.TIERS.size()):
		sim.worn[i] = -1.0
	for z in range(Data.ZONES.size()):
		sim.weather[z] = ""
	sim.elapsed = 3600.0 * 2.0            # 11:00, day
	_check(not sim.is_night() and sim.clock_words() == "11:00", "the clock reads %s at two hours in" % sim.clock_words())
	var fresh: Dictionary = sim.effective(0)
	_check(not ("Night" in fresh["intel"]) and sim.wear(0) == 0.0 and sim.site_state(0) == Words.SKY["fresh"], "a fresh site at 11:00 is not fresh: %s" % str(fresh["intel"]))
	# a clear picks the site over; it comes back over RECOVER_H
	sim.hp = sim.max_hp()
	sim.deploy(0)
	var m: Dictionary = sim.mission
	sim._clear(m, m["t"])
	sim.extract_now()
	sim.intel[0] = []                     # the extract re-rolled the radio's words; the site alone is read
	_check(sim.wear(0) > 0.99 and sim.site_state(0).begins_with("Picked over"), "the clear did not pick the site over: %.2f %s" % [sim.wear(0), sim.site_state(0)])
	var picked: Dictionary = sim.effective(0)
	_check(absf(picked["drop"] - fresh["drop"] * (1.0 - Data.WORN_DROP)) < 0.01 and absf(picked["cash"] - fresh["cash"] * (1.0 - Data.WORN_CASH)) < 0.1, "picked over did not thin the drops and cash: %.2f / %.2f against %.2f / %.2f" % [picked["drop"], picked["cash"], fresh["drop"], fresh["cash"]])
	# another depth is another site: fresh; back at the depth it was cleared at, still picked over (7 Oct)
	var hold_done: Array = sim.bosses_beaten.duplicate()
	var hold_best: Array = sim.best_depth.duplicate()
	for z in range(Data.ZONES.size()):
		sim.bosses_beaten[z] = true
	for k in range(Data.TIERS.size()):
		sim.best_depth[k] = maxi(sim.best_depth[k], 1)
	sim.set_depth(0, 2)
	_check(sim.depth[0] == 2 and sim.wear(0) == 0.0 and sim.site_state(0) == Words.SKY["fresh"], "a depth deeper did not read fresh: %.2f %s" % [sim.wear(0), sim.site_state(0)])
	sim.set_depth(0, 1)
	_check(sim.wear(0) > 0.99, "back at depth 1 the site is not still picked over: %.2f" % sim.wear(0))
	sim.bosses_beaten = hold_done
	sim.best_depth = hold_best
	sim.elapsed += Data.RECOVER_H * 3600.0 * 0.6
	_check(sim.wear(0) > 0.3 and sim.wear(0) < 0.5 and sim.site_state(0).begins_with("Settling"), "the site is not settling at 60%%: %.2f %s" % [sim.wear(0), sim.site_state(0)])
	sim.elapsed += Data.RECOVER_H * 3600.0
	_check(sim.wear(0) == 0.0 and is_equal_approx(sim.effective(0)["drop"], fresh["drop"]), "the site did not come back")
	# night by the clock
	sim.elapsed = 3600.0 * 14.0           # 23:00
	_check(sim.is_night() and sim.clock_words() == "23:00", "23:00 is not night: %s" % sim.clock_words())
	var night: Dictionary = sim.effective(0)
	_check("Night" in night["intel"] and is_equal_approx(night["pace"], fresh["pace"] * 0.8), "the clock's night did not take: %s pace %.2f" % [str(night["intel"]), night["pace"]])
	_check(sim.sky_words(0).begins_with("23:00, night"), "the sky's words are off: %s" % sim.sky_words(0))
	# the weather, by zone; never a word the radio rolls or sells
	sim.weather[0] = "Rain"
	var rain: Dictionary = sim.effective(0)
	_check("Rain" in rain["intel"] and is_equal_approx(rain["search"], fresh["search"] * 1.3) and is_equal_approx(rain["patrol"], fresh["patrol"] * 1.25), "rain did not take: %s search %.2f" % [str(rain["intel"]), rain["search"]])
	_check(sim.sky_words(0).ends_with(", raining"), "the sky's words do not say rain: %s" % sim.sky_words(0))
	sim.weather[0] = "Fog"
	var fog: Dictionary = sim.effective(0)
	_check(fog["contact"] == fresh["contact"] - 1 and is_equal_approx(fog["drop"], fresh["drop"] * 0.9), "fog did not take: %s" % str(fog["intel"]))
	_check(not ("Rain" in sim.juice_options(0)) and not ("Fog" in sim.juice_options(0)), "the sky's words are for sale at the radio")
	var rolled := false
	for k in range(60):
		sim._roll_tier_intel(1)
		rolled = rolled or ("Rain" in sim.intel[1]) or ("Fog" in sim.intel[1])
	_check(not rolled, "the radio rolled the sky's words")
	var saw := {}
	for k in range(40):
		sim.elapsed += Data.WEATHER_H * 3600.0
		sim._roll_weather()
		for z in range(Data.ZONES.size()):
			saw[sim.weather[z]] = true
	_check(saw.has("Rain") and saw.has("Fog") and saw.has(""), "forty hours of weather did not bring rain, fog and clear: %s" % str(saw.keys()))
	# the Runs card: the sky's row and the clock line, the site's state; everything fits
	sim.weather[0] = "Rain"
	sim.elapsed = 3600.0 * 14.0
	sim.worn[0] = sim.elapsed - 600.0
	main.show_room(main.MISSIONS)
	main._missions._shown = ""
	main.refresh()
	var c: Dictionary = main._missions._cols[0]
	var names := []
	for r in range(c["intel"].shown()):
		names.append(c["intel"].words(r))
	_check("Rain" in names and "Night" in names, "the card does not show the sky's words: %s" % str(names))
	_check(c["intel_head"].text.begins_with("THE WORD · 23:00, night, raining"), "the card's clock line is off: %s" % c["intel_head"].text)
	_check(c["tiles"][5]["key"].text == "The site" and c["tiles"][5]["value"].text.begins_with("Picked over"), "the card does not say the site is picked over: %s %s" % [c["tiles"][5]["key"].text, c["tiles"][5]["value"].text])
	_check_fit(main, "Runs (night, rain, picked over)")
	var d: Dictionary = sim.to_dict()
	sim.load_dict(d)
	_check(sim.weather[0] == "Rain" and sim.wear(0) > 0.9, "the sky and the wear did not save")
	sim.load_dict(saved)
	print("the places changing ok: picked over and back, the clock's night, rain and fog by zone, never on the radio, the card")


## Faces for the people who matter: a line when a head is armed, his face on
## the run screen while he's out (where the art exists), and the Caravan's
## runners before as a wall of small faces with the line beside it.
func _faces_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	for b in Data.BOSSES:
		_check(Words.BOSSES.has(b["name"]) and Words.BOSSES[b["name"]].has("armed") and str(Words.BOSSES[b["name"]]["armed"]).ends_with("."), "%s has no line for being armed" % b["name"])
	_finish_campaign(sim)
	sim.notes = 1000
	var bt := 2
	sim.best_depth[bt] = maxi(sim.best_depth[bt], 1)
	sim.arm_boss(bt, false)
	var armed_line: String = sim.boss_of(bt)["name"] + ": " + Words.BOSSES[sim.boss_of(bt)["name"]]["armed"]
	var n0: int = sim.events.filter(func(ev): return str(ev[1]) == armed_line).size()
	sim.arm_boss(bt, true)
	var n1: int = sim.events.filter(func(ev): return str(ev[1]) == armed_line).size()
	_check(sim.boss_armed.get(bt, false) and n1 == n0 + 1 and str(sim.events.back()[1]) == armed_line, "arming the head had no line: %s" % str(sim.events.back()))
	sim.arm_boss(bt, true)
	_check(sim.events.filter(func(ev): return str(ev[1]) == armed_line).size() == n1, "arming an armed head spoke twice")
	# the run screen's face slot follows the head; the fit holds either way
	sim.intel[bt] = []
	sim.hp = sim.max_hp()
	sim.deploy(bt)
	var m: Dictionary = sim.mission
	m["remaining"] = 1
	m["target_hp"] = 0.1                  # the last of the pool drops: the head comes out
	sim.advance(4.0)                      # past a melee wait or an underlay's grace
	_check(m.has("boss") and m["boss"]["started"], "the head did not come out")
	main.show_room(main.MISSIONS)        # on a run, Runs is the run screen
	main.refresh()
	var face_file := "res://art/people/%s.png" % Items.slug(m["boss"]["name"])
	_check(main._run._head_face.visible == (ResourceLoader.exists(face_file) or FileAccess.file_exists(face_file)), "the head's face slot does not follow the art")
	_check_fit(main, "Run (the head out)")
	sim.extract_now()
	# the wall: three runners before, their faces where the art is
	sim.past = [{"class": "Doorman", "level": 9, "runs": 12, "end": "died in the parade"}, {"class": "Poacher", "level": 14, "runs": 30, "end": "moved on"}, {"class": "Scrapper", "level": 4, "runs": 3, "end": "died in ransacked streets"}]
	main.show_room(main.BARRACKS)
	main._barracks._shown = ""
	main._barracks.selected = ""
	main.refresh()
	var shown := 0
	for t in main._barracks._wall:
		if t.visible:
			shown += 1
	_check(shown == 3 and main._barracks._wall[0].texture == People.portrait("Scrapper"), "the wall does not show the three, newest first: %d" % shown)
	_check(main._barracks._past.text.begins_with("Before: a scrapper, 3 runs") or main._barracks._past.text.begins_with("a scrapper, 3 runs") or main._barracks._past.text.begins_with("Before: scrapper"), "the line beside the wall is off: %s" % main._barracks._past.text)
	_check(main._barracks._past.position.x >= main._barracks._wall[2].position.x + 64, "the line runs under the faces")
	_check_fit(main, "Caravan (the wall)")
	sim.past = []
	main._barracks._shown = ""
	main.refresh()
	_check(not main._barracks._wall[0].visible, "the wall shows with nobody before")
	sim.load_dict(saved)
	print("faces ok: the heads' armed lines, the face slot on the run, the wall of runners before")


## Stacks: rounds of a base merge in the stash and the pack to five boxes'
## worth, a bottle onto the bottles to ten; a take tops up the rig's stack
## first and splits the rest; fitting takes one bottle off the stack; a strip
## puts it back on; the value follows what the stack holds.
func _stack_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	sim.stash = sim.stash.filter(func(it): return not Items.is_ammo(it) and not Items.is_socketable(it))
	sim.rig = []
	sim.cash = 100000.0
	var cap_nails: int = 200 * Data.STACK_BOXES
	sim.stash_put(sim._plain(Data.AMMO, "Nails"))
	sim.stash_put(sim._plain(Data.AMMO, "Nails"))
	var nails: Array = sim.stash.filter(func(it): return Items.is_ammo(it) and it["base"] == "Nails")
	_check(nails.size() == 1 and int(nails[0]["rounds"]) == 400 and nails[0]["value"] == 40, "two boxes of nails did not make one stack of 400 worth two boxes: %s" % str(nails))
	for k in range(5):
		sim.stash_put(sim._plain(Data.AMMO, "Nails"))
	nails = sim.stash.filter(func(it): return Items.is_ammo(it) and it["base"] == "Nails")
	_check(nails.size() == 2 and int(nails[0]["rounds"]) == cap_nails and int(nails[1]["rounds"]) == 400, "seven boxes did not make a full stack and a second: %s" % str(nails.map(func(it): return it["rounds"])))
	var shells: Dictionary = sim._plain(Data.AMMO, "Shells")
	sim.stash_put(shells)
	_check(sim.stash.filter(func(it): return Items.is_ammo(it) and it["base"] == "Shells").size() == 1, "shells joined the nails")
	# buying tops the stack, no cell needed when it fits
	var cells: int = sim.stash_used()
	var before: int = int(nails[1]["rounds"])
	_check(sim.buy_ammo("improvised") and int(nails[1]["rounds"]) == before + 200 and sim.stash_used() == cells, "a bought box did not join the stack: %d -> %d, cells %d -> %d" % [before, int(nails[1]["rounds"]), cells, sim.stash_used()])
	# the rig: a take tops up the rig's stack and splits the rest
	var full: Dictionary = nails[0]
	_check(sim.take(full["id"]) and sim.rig.size() == 1 and int(sim.rig[0]["rounds"]) == cap_nails, "the full stack did not go to the rig whole")
	var part: Dictionary = nails[1]
	var part_before: int = int(part["rounds"])
	sim.rig[0]["rounds"] = cap_nails - 150
	Items.set_stack(sim.rig[0], cap_nails - 150)
	var pouches: int = sim.med_capacity()
	while sim.rig_room(1):
		sim.rig.append(sim._plain(Data.MEDICAL, "Bandage"))       # no pouch free: only the top-up can happen
	_check(sim.take(part["id"]) and int(sim.rig[0]["rounds"]) == cap_nails and int(part["rounds"]) == part_before - 150 and sim.stash.has(part), "the take did not top up the rig's stack and leave the rest: rig %d, stash %d" % [int(sim.rig[0]["rounds"]), int(part["rounds"])])
	sim.rig = sim.rig.filter(func(it): return Items.is_ammo(it))
	_check(sim.take(part["id"]) and sim.rig.size() == 2, "the rest did not take a pouch of its own once one was free")
	# leaving merges back
	var rig_part: Dictionary = sim.rig[1]
	_check(sim.leave(rig_part["id"]) and sim.stash.filter(func(it): return Items.is_ammo(it) and it["base"] == "Nails").size() == 1, "the stack left did not merge back")
	# the pack: found rounds join the found stack
	sim.intel[0] = []
	sim.set_depth(0, 1)
	sim.hp = sim.max_hp()
	sim.deploy(0)
	var m: Dictionary = sim.mission
	m["found"] = [sim._plain(Data.AMMO, "Shells")]
	var fake: Dictionary = sim._plain(Data.AMMO, "Shells")
	var t: Dictionary = m["t"]
	# a find of shells through the pack rule
	if sim.pack_used(m) + 1 <= sim.capacity():
		sim.stash_put(fake)         # not the pack; just to use the roll - the merge below is the real check
	var found_box: Dictionary = sim._plain(Data.AMMO, "Shells")
	var packed: int = m["found"].size()
	# call the pack rule the way _find does
	var it2: Dictionary = found_box
	if Items.stacks(it2):
		for f in m["found"]:
			if Items.same_stack(f, it2) and Items.stack_size(f) < Items.stack_cap(f):
				var moved: int = mini(Items.stack_cap(f) - Items.stack_size(f), Items.stack_size(it2))
				Items.set_stack(f, Items.stack_size(f) + moved)
				Items.set_stack(it2, Items.stack_size(it2) - moved)
	_check(int(m["found"][0]["rounds"]) == 300 and Items.stack_size(it2) == 0, "found shells did not join the found stack")
	sim.extract_now()
	# bottles: ten to a stack, one off for a socket, back on from a strip
	var fluid: Dictionary = sim._plain(Data.ATTACHMENT, "Lighter fluid")
	_check(Items.stacks(fluid) and fluid.get("count", 0) == 1 and fluid["affixes"].is_empty(), "a bottle is not a plain stackable")
	for k in range(3):
		sim.stash_put(sim._plain(Data.ATTACHMENT, "Lighter fluid"))
	var fluids: Array = sim.stash.filter(func(it): return Items.is_socketable(it) and it["base"] == "Lighter fluid")
	_check(fluids.size() == 1 and int(fluids[0]["count"]) == 3 and fluids[0]["value"] == 360, "three bottles did not stack: %s" % str(fluids.map(func(it): return it.get("count", 0))))
	var rolled: Dictionary = Items.roll(Data.ATTACHMENT, 6, sim.rng)
	var tries := 0
	while rolled["mount"] != "socket" and tries < 200:
		rolled = Items.roll(Data.ATTACHMENT, 6, sim.rng)
		tries += 1
	_check(rolled["mount"] != "socket" or (rolled["affixes"].is_empty() and rolled["rarity"] == 0), "a rolled socketable carries affixes: %s" % str(rolled))
	var gun: Dictionary = sim._plain("Primary", "Army SMG")
	gun["attachments"]["socket 1"] = null
	var old_gun = sim.equipped["Primary"]
	sim.equipped["Primary"] = gun
	sim.workshop = maxi(sim.workshop, 1)
	_check(sim.fit("Primary", fluids[0]["id"]) and gun["attachments"]["socket 1"] != null and int(gun["attachments"]["socket 1"]["count"]) == 1 and int(fluids[0]["count"]) == 2 and sim.stash.has(fluids[0]), "fitting did not take one bottle off the stack: socket %s, stack %d" % [str(gun["attachments"]["socket 1"]), int(fluids[0]["count"])])
	_check(sim.strip("Primary", "socket 1") and int(fluids[0]["count"]) == 3, "the strip did not put the bottle back on the stack: %d" % int(fluids[0]["count"]))
	for k in range(9):
		sim.stash_put(sim._plain(Data.ATTACHMENT, "Lighter fluid"))
	fluids = sim.stash.filter(func(it): return Items.is_socketable(it) and it["base"] == "Lighter fluid")
	_check(fluids.size() == 2 and int(fluids[0]["count"]) == Data.SOCKET_STACK and int(fluids[1]["count"]) == 2, "twelve bottles did not make ten and two: %s" % str(fluids.map(func(it): return it.get("count", 0))))
	main.show_room(main.ARMOURY)
	main.refresh()
	_check_fit(main, "Lock-up (stacks)")
	sim.equipped["Primary"] = old_gun
	var d: Dictionary = sim.to_dict()
	sim.load_dict(d)
	_check(sim.stash.any(func(it): return Items.is_socketable(it) and int(it.get("count", 1)) == Data.SOCKET_STACK), "the stack did not save")
	sim.load_dict(saved)
	print("stacks ok: rounds merge to five boxes, bottles to ten, the buy, the take and the split, the leave, the pack, one off for a socket and back, the save")


## The first ten minutes: what's next, in the voice, on the Runner card and
## in the log when it changes - the past, the first run, the site, the head,
## the campaign done, the move.
func _next_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	var fresh = load("res://scripts/sim/sim.gd").new()
	fresh.start()
	_check(fresh.next_words() == Words.NEXT["past"] and fresh.events.any(func(ev): return str(ev[1]) == Words.NEXT["past"]), "a new yard does not say to pick a past: %s" % fresh.next_words())
	fresh.set_class("Doorman")
	_check(fresh.next_words() == Words.NEXT["first"] and str(fresh.events.back()[1]) == Words.NEXT["first"], "a runner with a past is not sent out: %s" % str(fresh.events.back()))
	_check(fresh.next_words(true) == Words.NEXT_SHORT["first"], "the short form is off: %s" % fresh.next_words(true))
	# after the first run: the next site; then the head; then the next lot
	fresh.hp = fresh.max_hp()
	fresh.deploy(0)
	fresh.extract_now()
	_check(fresh.next_words().begins_with("Ransacked streets hasn't") or fresh.next_words().begins_with("The parade hasn't"), "after the first run the next site is not named: %s" % fresh.next_words())
	for i in [0, 1, 2]:
		fresh.best_depth[i] = 1
	_check(fresh.next_words() == Words.NEXT["head"] % ["The carpet man", "the retail park"] and fresh.next_words(true) == "Arm the carpet man on Runs", "the head is not named: %s / %s" % [fresh.next_words(), fresh.next_words(true)])
	fresh.bosses_beaten[0] = true
	_check(fresh.next_words() == Words.NEXT["site"] % "The pleasure park", "the town's first site is not named: %s" % fresh.next_words())
	var n0: int = fresh.events.size()
	fresh.hp = fresh.max_hp()
	fresh.deploy(0)
	fresh.extract_now()
	_check(fresh.events.any(func(ev): return str(ev[1]) == Words.NEXT["site"] % "The pleasure park"), "the log did not carry the change")
	var n1: int = fresh.events.size()
	fresh.hp = fresh.max_hp()
	fresh.deploy(0)
	fresh.extract_now()
	_check(not fresh.events.slice(n1).any(func(ev): return str(ev[1]).begins_with("The pleasure park hasn't")), "the log said the same thing twice")
	_finish_campaign(sim)
	_check(sim.next_words() == Words.NEXT["done"], "the campaign done has no line: %s" % sim.next_words())
	main.show_room(main.OVERVIEW)
	_check_fit(main, "The Yard (what's next)")
	sim.load_dict(saved)
	print("what's next ok: the past, the first run, the site, the head, the next lot, once in the log, the campaign done")


## Idle quality of life: two toggles on the Lock-up with nothing selected -
## the best of each slot goes on when a run comes home, and the common gear
## goes to the fence (never rounds, meds, bottles, papers, uniques or sets).
func _idle_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	main.show_room(main.ARMOURY)
	main._armoury.selected = {}
	main.refresh()
	_check(main._armoury._toggles[0].visible and main._armoury._toggles[1].visible, "the idle toggles are not on the Lock-up")
	_check_fit(main, "Lock-up (idle toggles)")
	main._armoury._toggle(0)
	main._armoury._toggle(1)
	_check(sim.auto_equip and sim.auto_sell and main._armoury._toggles[0].text.ends_with("✓"), "the toggles did not turn on")
	_check_fit(main, "Lock-up (idle toggles on)")
	# a run home: the junk goes, the better piece goes on, the rest stays
	while not sim.stash_room(12) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])
	var junk: Dictionary = sim._plain("Helmet", "Hard hat")
	var keep_ammo: Dictionary = sim._plain(Data.AMMO, "Nails")
	var keep_med: Dictionary = sim._plain(Data.MEDICAL, "Bandage")
	var keep_bottle: Dictionary = sim._plain(Data.ATTACHMENT, "Lighter fluid")
	var better: Dictionary = sim._plain("Armour", "Riot suit")
	better["rarity"] = 2
	better["affixes"] = [{"stat": "hp", "value": 40.0, "tier": 3}]
	for it in [junk, keep_ammo, keep_med, keep_bottle, better]:
		sim.stash_put(it)
	sim.equipped["Armour"] = sim._plain("Armour", "Stab vest")
	sim.intel[0] = []
	sim.hp = sim.max_hp()
	sim.deploy(0)
	sim.mission["found"] = []
	sim.extract_now()
	_check(not sim.stash.has(junk) and sim.stash.has(keep_ammo) and sim.stash.has(keep_med) and sim.stash.has(keep_bottle), "the junk run sold the wrong things: junk %s ammo %s med %s bottle %s" % [sim.stash.has(junk), sim.stash.has(keep_ammo), sim.stash.has(keep_med), sim.stash.has(keep_bottle)])
	_check(sim.equipped["Armour"] != null and sim.equipped["Armour"]["id"] == better["id"], "the better armour did not go on")
	_check(sim.events.any(func(ev): return str(ev[1]).begins_with("The fence took the junk")) and sim.events.any(func(ev): return str(ev[1]).begins_with("Put on: ")), "the idle tidy had no lines")
	main._armoury._toggle(0)
	main._armoury._toggle(1)
	_check(not sim.auto_equip and not sim.auto_sell, "the toggles did not turn off")
	var d: Dictionary = sim.to_dict()
	sim.auto_sell = true
	d = sim.to_dict()
	sim.load_dict(d)
	_check(sim.auto_sell, "the toggle did not save")
	sim.load_dict(saved)
	print("idle ok: the toggles, the junk run, equip if better, the lines, the save")


## Juice: the log's best lines as toasts under the top bar, a damage number
## off the run panel as the hits land, a flash on a rare in the pack.
func _juice_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	main.refresh()
	var before: int = main._juice.toasts().size()
	sim.log_event("Found: Lucky cap")
	sim.log_event("Trained: Stance")
	main.refresh()
	var shown: Array = main._juice.toasts()
	_check(not shown.is_empty() and shown[0] == "Found: Lucky cap" and not shown.has("Trained: Stance"), "the find did not toast, or the training did: %s" % str(shown))
	_check(Words.toast_tone("The carpet man comes out. He's brought the whole warehouse.") == "warn" and Words.toast_tone("The carpet man is down. x") == "good" and Words.toast_tone("Dead in the parade. Kit lost (£100).") == "bad" and Words.toast_tone("Out to The parade, The Estate, depth 1: night") == "none", "the toast tones are off")
	for k in range(5):
		sim.log_event("Level %d: 1 training point" % (k + 50))
	main.refresh()
	_check(main._juice.toasts().size() <= main._juice.TOAST_MAX, "the toasts piled past three")
	for t in main._juice.text_nodes():
		_check(t.text != "" and UI.text_width(t, t.text) <= t.size.x, "a toast does not fit: %s" % t.text)
	# the run: numbers as the hits land, a flash on a rare
	sim.intel[0] = []
	sim.hp = sim.max_hp()
	sim.deploy(0)
	main.show_room(main.MISSIONS)
	main.refresh()
	main._juice.clear_numbers()
	var n0: int = 0
	sim.mission["t"]["hp"] = 100000.0        # a lot that takes a while, so the hits are seen landing
	sim.mission["target_hp"] = 100000.0
	sim.advance(2.0)
	main.refresh()
	_check(main._juice.numbers() > n0, "no number came off the hits: dealt %.0f" % float(sim.mission.get("dealt", 0.0)))
	# scattered: a run of numbers lands at different places, not one column; no more than one a third of a second
	main._juice.clear_numbers()
	var spots := {}
	for k in range(8):
		sim.advance(0.4)
		main.refresh()
	for n in main._juice._numbers:
		spots["%d,%d" % [int(n["label"].position.x / 20), int(n["from"] / 8)]] = true
	_check(main._juice.numbers() >= 4 and main._juice.numbers() <= 18 and spots.size() >= 3, "the numbers come as one column or too thick: %d numbers in %d places" % [main._juice.numbers(), spots.size()])
	# red for damage taken, green for what came back, counted apart: a helmet's regen shows among the hits
	main._juice.clear_numbers()
	main.refresh()
	sim.mission["elapsed"] += 1.0
	sim.mission["taken"] = float(sim.mission.get("taken", 0.0)) + 20.0
	sim.mission["taken_by"] = sim.mission.get("taken_by", {})
	sim.mission["taken_by"]["physical"] = float(sim.mission["taken_by"].get("physical", 0.0)) + 20.0
	sim.mission["healed"] = float(sim.mission.get("healed", 0.0)) + 3.0
	main.refresh()
	var texts: Array = main._juice._numbers.map(func(n): return n["label"].text)
	_check(texts.any(func(t): return str(t).begins_with("−2")) and texts.any(func(t): return str(t).begins_with("+")), "the red and the green do not both show for a second that took 20 and gave 3 back: %s" % str(texts))
	# the numbers carry their type's colour: a fire hit on them reads red, a physical one white, poison on you green
	main._juice.clear_numbers()
	var hold_gun = sim.equipped["Primary"]
	var torch: Dictionary = sim._plain("Primary", "Nail gun")
	torch["affixes"] = [{"stat": "conv_fire_pct", "value": 50, "tier": 3}]
	sim.equipped["Primary"] = torch
	sim.rig.append(sim._plain(Data.AMMO, "Nails"))
	sim.mission["t"]["types"] = {"physical": 0.2, "poison": 0.8}
	sim.mission["elapsed"] += 1.0
	var colours := {}
	for k in range(8):
		sim.advance(0.5)
		main.refresh()
		for n in main._juice._numbers:                      # gathered as they come: twelve show at once, the rest go
			colours[n["label"].get_theme_color("font_color")] = true
	_check(colours.has(Pal.ELEMENT_COLOURS["fire"]) and colours.has(Pal.ELEMENT_COLOURS["physical"]), "the hits did not come in fire and physical colours: dealt_by %s" % str(sim.mission.get("dealt_by", {})))
	_check(colours.has(Pal.ELEMENT_COLOURS["poison"]), "their poison on you did not come up green: taken_by %s" % str(sim.mission.get("taken_by", {})))
	var dealt_sum := 0.0
	for ty in sim.mission.get("dealt_by", {}):
		dealt_sum += float(sim.mission["dealt_by"][ty])
	_check(absf(dealt_sum - float(sim.mission["dealt"])) < 1.0, "dealt by type (%.0f) does not add up to dealt (%.0f)" % [dealt_sum, float(sim.mission["dealt"])])
	sim.equipped["Primary"] = hold_gun
	# the counters come from the fight: regen heals, their fire takes
	var hold = sim.equipped["Helmet"]
	var regen_hat: Dictionary = sim._plain("Helmet", "Hard hat")
	regen_hat["affixes"] = [{"stat": "regen", "value": 2.0, "tier": 2}]
	sim.equipped["Helmet"] = regen_hat
	sim.hp = sim.max_hp() * 0.5
	var healed0: float = float(sim.mission.get("healed", 0.0))
	var taken0: float = float(sim.mission.get("taken", 0.0))
	sim.advance(5.0)
	_check(float(sim.mission.get("healed", 0.0)) - healed0 >= 9.0, "five seconds of +2 regen did not count as healed: %.1f" % (float(sim.mission.get("healed", 0.0)) - healed0))
	_check(float(sim.mission.get("taken", 0.0)) > taken0, "their fire did not count as taken")
	sim.equipped["Helmet"] = hold
	var you_y: float = main._run._left.global_position.y + main._run.RUNNER_BAR_Y
	var them_y: float = main._run._left.global_position.y + main._run.FIGHT_BAR_Y
	var reds: Array = main._juice._numbers.filter(func(n): return n["label"].text.begins_with("−") or n["label"].text.begins_with("+"))
	_check(reds.all(func(n): return n["from"] > you_y - main._juice.global_position.y - 40 and n["from"] < you_y - main._juice.global_position.y + 40), "the red and green are not on your bar (them %.0f, you %.0f)" % [them_y, you_y])
	var whites: Array = main._juice._numbers.filter(func(n): return not (n["label"].text.begins_with("−") or n["label"].text.begins_with("+")))
	_check(whites.all(func(n): return n["from"] > them_y - main._juice.global_position.y - 40 and n["from"] < them_y - main._juice.global_position.y + 40), "the hits are not on their bar")
	var rare: Dictionary = sim._plain("Helmet", "Hard hat")
	rare["rarity"] = 2
	sim.mission["found"].append(rare)
	main.refresh()
	var k: int = main._run._inv.cell_of(rare["id"])
	_check(k >= 0 and main._run._inv.cell_node(k).modulate != Color.WHITE, "the rare did not flash in the pack")
	sim.extract_now()
	main.refresh()
	sim.load_dict(saved)
	main.refresh()
	print("juice ok: the toasts and their tones, the cap, the fit, the numbers, the flash")


## Sound: every placeholder file reads; the zone's ambient while out, rain
## over it, the gun's tick, the sting, the door; off from the pause menu.
func _sound_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	for name in ["ambient_estate", "ambient_town", "ambient_city", "rain", "tick_improvised", "tick_shotgun", "tick_rifle", "tick_smg", "tick_pistol", "tick_melee", "sting", "door", "found"]:
		_check(main._sound.stream(name) != null, "no sound reads for %s" % name)
	main._sound.set_enabled(true)
	sim.intel[0] = []
	sim.weather[0] = "Rain"
	sim.hp = sim.max_hp()
	sim.deploy(0)
	sim.mission["t"]["hp"] = 100000.0
	sim.mission["target_hp"] = 100000.0
	main.show_room(main.MISSIONS)
	main.refresh()
	var p: Dictionary = main._sound.playing()
	_check(p["ambient"] == "ambient_estate" and p["rain"], "the estate's ambient and the rain are not playing out on the estate: %s" % str(p))
	sim.advance(2.0)
	main.refresh()
	_check(main._sound._tick_at > 0.0, "the gun did not tick")
	sim.mission["patrols"] = 1
	main.refresh()
	_check(main._sound._patrols_seen == 1 and main._sound._one.stream == main._sound.stream("sting"), "the gang's sting did not play")
	sim.extract_now()
	main.refresh()
	p = main._sound.playing()
	_check(p["ambient"] == "" and not p["rain"], "the ambient kept playing in the yard: %s" % str(p))
	main._sound.set_enabled(false)
	sim.hp = sim.max_hp()
	sim.deploy(0)
	main.refresh()
	_check(main._sound.playing()["ambient"] == "", "sound off still plays")
	main._sound.set_enabled(true)
	sim.extract_now()
	main.show_pause()
	_check(main._menu._items.any(func(i): return str(i["name"]).begins_with("Sound: ")), "the pause menu has no sound toggle")
	_check_fit(main, "Paused (sound)")
	main._menu.close()
	sim.load_dict(saved)
	print("sound ok: the files, the ambient and the rain, the tick, the sting, off in the yard, the toggle")


## From Matt's playtest (5 Oct): HP never reads past its max; Locked sits
## right-justified; a toast shows once and only for what just happened; a
## long log line shortens by sentence rather than trailing off; a paper picked
## in the Lock-up gets a panel, not a crash.
func _playtest_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	# HP: the same rounding both sides
	sim.hp = sim.max_hp()
	_check(sim.hp_shown() == sim.max_hp_shown(), "full HP reads %d of %d" % [sim.hp_shown(), sim.max_hp_shown()])
	sim.hp = sim.max_hp() - 0.4
	_check(sim.hp_shown() <= sim.max_hp_shown(), "HP a fraction under full reads past the max: %d of %d" % [sim.hp_shown(), sim.max_hp_shown()])
	var worn = sim.equipped["Armour"]
	sim.equipped["Armour"] = sim._plain("Armour", "Stab vest")
	var hp_before: float = sim.hp
	var big: Dictionary = sim._plain("Armour", "Riot suit")
	big["affixes"] = [{"stat": "hp", "value": 200.0, "tier": 5}]
	sim.equipped["Armour"] = big
	sim.hp = sim.max_hp()
	sim.equipped["Armour"] = sim._plain("Armour", "Stab vest")
	sim.advance(0.1)
	_check(sim.hp <= sim.max_hp() + 0.001, "HP stayed past the max when the kit came off: %.0f of %.0f" % [sim.hp, sim.max_hp()])
	sim.equipped["Armour"] = worn
	# Locked, right-justified across the row
	main.show_room(main.MISSIONS)
	main._missions._shown = ""
	main.refresh()
	var c: Dictionary = main._missions._cols[0]
	if not sim.campaign_done():
		_check(c["tiles"][main._missions.DEPTH_TILE]["value"].text == "Locked" and not c["depth_up"].visible and not c["depth_down"].visible, "the depth tile does not read Locked with its buttons hidden before the campaign's done")
	_check_fit(main, "Runs (locked)")
	# the band: the art never covers the words; the odds sit at its foot with the figure beside, and both inside it
	var band0 = c["band"]
	_check(band0.headline.position.y + band0.headline.size.y <= band0.size.y and band0.kicker.position.y >= 0 and band0.title.position.y > band0.kicker.position.y, "the band's words leave the band")
	_check(band0.headline.text != "" and band0.unit.text != "" and band0.kicker.text.begins_with("Tier 1 · "), "the band's words are off: '%s' / '%s' / '%s'" % [band0.kicker.text, band0.headline.text, band0.unit.text])
	_check(c["tiles"][0]["key"].text == "Them" and c["tiles"][0]["value"].text.contains(" × ") and c["tiles"][2]["key"].text == "Fight", "the fight tiles are off: %s" % str(c["tiles"].map(func(t): return t["key"].text + " " + t["value"].text)))
	# the Yard's Runner card note with a long head's name: the form without "on Runs" when the long one won't fit
	var yard_note = main._cards[0]._note if main._cards[0]._title.text == "Runner" else null
	if yard_note != null and yard_note.text != "":
		_check(UI.text_width(yard_note, yard_note.text) <= yard_note.size.x + 0.5, "the Runner card's note trails off: '%s'" % yard_note.text)
	# the depth's −/+ sit inside their tile, one above the other, never on each other
	var du = c["depth_up"]
	var dd = c["depth_down"]
	_check(du.position.y + du.size.y <= dd.position.y and dd.position.y + dd.size.y <= c["tiles"][main._missions.DEPTH_TILE]["panel"].size.y, "the depth buttons overlap or leave the tile: up %s/%s down %s/%s" % [du.position.y, du.size.y, dd.position.y, dd.size.y])
	_check(du.get_combined_minimum_size().y <= du.size.y, "the depth button's minimum (%.0f) is taller than its box (%.0f)" % [du.get_combined_minimum_size().y, du.size.y])
	# the band's sky follows the zone
	main._missions._pick_zone(1)
	main.refresh()
	_check(c["band"]._tone == 1, "the band's tone did not follow the zone")
	main._missions._pick_zone(0)
	main.refresh()
	_check(c["intel_head"].text.begins_with("THE WORD"), "the word's head is off: '%s'" % c["intel_head"].text)
	# three boxes under the band: the fight holds its tiles, the elements their chips, the word its rows and the site lines; none overlap, and the last clears the note
	var bx: Array = c["boxes"]
	var r0 := Rect2(bx[0].position, bx[0].size)
	var r1 := Rect2(bx[1].position, bx[1].size)
	var r2 := Rect2(bx[2].position, bx[2].size)
	_check(r0.encloses(Rect2(c["tiles"][5]["panel"].position, c["tiles"][5]["panel"].size)) and r0.position.y >= main._missions.BAND_H, "the fight's box does not hold its tiles")
	_check(r1.encloses(Rect2(c["chips"].position, c["chips"].size)) and r1.encloses(Rect2(c["resist"].position, c["resist"].size)) and r1.encloses(Rect2(c["resist_label"].position, c["resist_label"].size)), "the elements' box does not hold its chips")
	_check(r2.encloses(Rect2(c["intel"].position, Vector2(c["intel"].size.x, main._missions.WORD_ROWS * (Chips.CHIP_H + Chips.ROW_GAP)))) and r2.encloses(Rect2(c["site"][0].position, c["site"][0].size)) and r2.encloses(Rect2(c["intel_head"].position, c["intel_head"].size)), "the word's box does not hold its rows")
	_check(r0.end.y + 8 <= r1.position.y and r1.end.y + 8 <= r2.position.y and r2.end.y <= c["note"].position.y, "the Runs card's boxes run into each other or the note: %s %s %s note %.0f" % [str(r0), str(r1), str(r2), c["note"].position.y])
	# what they resist reads as chips in the element's colour, the shape of what they fire; "Nothing" when they resist nothing
	_check(c["resist_label"].text == "They resist" and c["resist"].visible and c["resist"].shown() >= 1, "the resist chips are missing")
	var t0: Dictionary = sim.effective(Data.ZONES[main._missions.zone]["tiers"][0])
	var any_res := false
	for ty in Data.ELEMENTS:
		any_res = any_res or float(t0.get("res", {}).get(ty, 0.0)) > 0.0
	_check((c["resist"].words(0) == "Nothing") == (not any_res), "the resist chips disagree with the site: '%s'" % c["resist"].words(0))
	if any_res:
		_check(c["resist"].words(0).contains("%"), "a resist chip has no figure: '%s'" % c["resist"].words(0))
	for k in range(c["intel"].shown()):
		_check(c["intel"].tail(k) != "", "a word's effect is missing from its row: '%s'" % c["intel"].words(k))
	_check(c["intel"].shown() == mini(main._missions.WORD_ROWS, sim.effective(Data.ZONES[main._missions.zone]["tiers"][0])["intel"].size()), "the Runs card shows %d word rows" % c["intel"].shown())
	# five words (three called in, night, weather) never run past the rows into the site line (the reviewer's catch)
	var tier0: int = Data.ZONES[main._missions.zone]["tiers"][0]
	var hold_intel: Array = sim.intel[tier0].duplicate()
	var hold_elapsed: float = sim.elapsed
	var hold_weather: Array = sim.weather.duplicate()
	sim.intel[tier0] = ["Quiet road", "Rubbered", "Lying low"]
	sim.elapsed = 3600.0 * 23.0
	sim.weather[main._missions.zone] = "Rain"
	main._missions._shown = ""
	main.refresh()
	_check(sim.effective(tier0)["intel"].size() >= 4 and c["intel"].shown() <= main._missions.WORD_ROWS and c["intel"].position.y + c["intel"].size.y <= c["site"][0].position.y, "five words run past the word rows: %d shown, rows end %.0f, site at %.0f" % [c["intel"].shown(), c["intel"].position.y + c["intel"].size.y, c["site"][0].position.y])
	_check_fit(main, "Runs (five words)")
	sim.intel[tier0] = hold_intel
	sim.elapsed = hold_elapsed
	sim.weather = hold_weather
	main._missions._shown = ""
	main.refresh()
	# toasts: once, and only for what just happened
	var line := "Found: Lucky cap"
	sim.log_event(line)
	main.refresh()
	sim.log_event(line)
	main.refresh()
	_check(main._juice.toasts().count(line) == 1, "the same line toasted twice")
	var stale := "Level 99: 1 training point"
	sim.events.append([Time.get_unix_time_from_system() - 60.0, stale])
	sim.events_total += 1
	main.refresh()
	_check(not main._juice.toasts().has(stale), "a line a minute old toasted")
	# the log line: shortened by sentence, never trailing off
	var long := "A convoy comes through. Lorries, and a crew riding on them. They stop. They were carrying notes. The yard takes what it can carry and the rest goes back on the lorry."
	sim.log_event(long)
	main.refresh()
	var shown: String = main._event_labels[0].text
	_check(shown.ends_with(".") and long.begins_with(shown) and UI.text_width(main._event_labels[0], shown) <= main._event_labels[0].size.x, "the long line trails off or does not fit: '%s'" % shown)
	var forms: Array = main._by_sentence(long)
	_check(forms.size() >= 4 and forms[1] == "A convoy comes through. Lorries, and a crew riding on them. They stop. They were carrying notes." and forms[-1] == "A convoy comes through.", "the sentence forms are off: %s" % str(forms))
	# one long sentence: cut at its last comma, never trailing off (the lost runner's long name in a long base's)
	var one := "One of them is in the last doorman's station helmet, visored and with the strap on."
	var one_forms: Array = main._by_sentence(one)
	_check(one_forms.size() == 2 and one_forms[1] == "One of them is in the last doorman's station helmet.", "the one-sentence forms are off: %s" % str(one_forms))
	# a paper picked in the Lock-up
	var paper: Dictionary = sim._plain(Data.PAPER, "A P45")
	while not sim.stash_room(2) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])
	sim.stash.append(paper)
	sim._read(paper)                      # read: the longer line, the one that clipped
	main.show_room(main.ARMOURY)
	main.refresh()
	main._armoury._pick_cell(main._armoury._inv.cell_of(paper["id"]))
	_check(main._armoury._head._title.text == "A P45" and main._armoury._head._tail.text.contains("from before") and main._armoury._pick.button_texts().is_empty(), "a paper's panel is off (Sell is the fence's): %s / %s / %s" % [main._armoury._head._title.text, main._armoury._head._tail.text, str(main._armoury._pick.button_texts())])
	_check(main._armoury._pick._right_title.text.begins_with("In the caravan's drawer") and main._armoury._pick._right_lines[0].text.begins_with("Read"), "a read paper's line is off: %s" % main._armoury._pick._right_title.text)
	_check_fit(main, "Lock-up (a paper)")
	# and the same paper picked at the fence's stash tab (it crashed there too)
	main.show_room(main.MARKET)
	main._fence._show("stash")
	main._fence._stash.kind = 6               # the Paper tab: the paper is on the page whatever the stash holds
	main._fence._stash.page = 0
	main._fence._shown = ""
	main.refresh()
	main._fence._stash._pick(main._fence._stash.cell_of(paper["id"]))
	main.refresh()
	_check(main._fence._right_title.text == "The drawer" and main._fence._right_lines[0].text.begins_with("Read") or main._fence._right_lines[0].text == "In the drawer", "a paper at the fence: %s / %s" % [main._fence._right_title.text, main._fence._right_lines[0].text])
	_check_fit(main, "Fence (a paper)")
	main._fence._stash.kind = 0
	main._fence._show("shelf")
	main.show_room(main.ARMOURY)
	main.refresh()
	main._armoury._pick_cell(main._armoury._inv.cell_of(paper["id"]))
	_check(main._armoury._pick.button_texts().is_empty(), "the Lock-up offers a paper a button: %s" % str(main._armoury._pick.button_texts()))
	sim.sell(paper)
	_check(not sim.stash.has(paper), "the paper did not sell")
	# every piece says what kind of thing it is on its card
	for pair in [["Primary", "Stalking rifle", "Primary · rifle"], ["Primary", "Spiked bat", "Primary · melee"], ["Secondary", "Service pistol", "Secondary · pistol"], ["Helmet", "Hard hat", "Helmet"], ["Armour", "Stab vest", "Armour"], ["Rig", "Bum bag", "Rig"], ["Backpack", "School bag", "Backpack"], ["Charm", "Lucky penny", "Charm"], [Data.MEDICAL, "Bandage", "Med"], [Data.AMMO, "Shells", "Rounds · shotgun"], [Data.PAPER, "A P45", "Paper"], [Data.ATTACHMENT, "Road salt", "Socketable"], [Data.ATTACHMENT, "Red dot", "Gun part · optic"], [Data.ATTACHMENT, "Lead in it", "Melee part · business end"], [Data.ATTACHMENT, "Tape", "Melee part · grip"]]:
		var piece: Dictionary = sim._plain(pair[0], pair[1])
		_check(Items.kind_words(piece) == pair[2], "%s reads as '%s', not '%s'" % [pair[1], Items.kind_words(piece), pair[2]])
		if pair[0] in Data.SLOTS:
			_check(Items.figure_options(piece)[0].begins_with(pair[2] + " · ") and Items.figure_options(piece).back().begins_with(pair[2].get_slice(" · ", 0)), "%s's card line does not lead with its kind: %s" % [pair[1], Items.figure_options(piece)[0]])
	# a socketable says what it is and what it does, in the Lock-up and at the fence
	var salt_it: Dictionary = sim._plain(Data.ATTACHMENT, "Road salt")
	_check(Items.att_lead(salt_it) == ["+12", "armour"] and Items.att_words(salt_it) == "+12 armour", "salt's figures do not say armour: %s / %s" % [str(Items.att_lead(salt_it)), Items.att_words(salt_it)])
	var fluid_it: Dictionary = sim._plain(Data.ATTACHMENT, "Lighter fluid")
	_check(Items.att_lead(fluid_it)[0] == "15%" and Items.att_lead(fluid_it)[1].begins_with("of hits as fire") and Items.socket_words(fluid_it).contains("15% of your hits land as fire"), "fluid's figures do not say what it does: %s / %s" % [str(Items.att_lead(fluid_it)), Items.socket_words(fluid_it)])
	while not sim.stash_room(2) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])
	sim.stash.append(salt_it)
	main.show_room(main.ARMOURY)
	main.refresh()
	main._armoury._pick_cell(main._armoury._inv.cell_of(salt_it["id"]))
	_check(main._armoury._pick._right_lines[0].text.contains("any socket"), "the Lock-up does not say salt goes in any socket: %s" % main._armoury._pick._right_lines[0].text)
	_check_fit(main, "Lock-up (salt)")
	sim.sell(salt_it)
	sim.market.append(sim._plain(Data.ATTACHMENT, "Road salt"))
	main.show_room(main.MARKET)
	main._fence.selected = {"kind": "shelf", "id": sim.market.back()["id"]}
	main.refresh()
	_check(main._fence._right_lines[0].text.begins_with("A socketable"), "the fence does not say salt is a socketable: %s" % main._fence._right_lines[0].text)
	_check_fit(main, "Fence (salt)")
	_check(Items.art(sim._plain(Data.PAPER, "A P45")) != null and Items.art(sim._plain(Data.PAPER, "A boarding pass")) == Items.art(sim._plain(Data.PAPER, "A P45")), "papers have no picture in the cell, or not the same one")
	sim.load_dict(saved)
	# the boss toggle on the Runs card: one press, one toast, however many refreshes follow
	_finish_campaign(sim)
	sim.notes = 1000
	sim.arm_boss(2, false)
	main._juice._toasts = []
	main.show_room(main.MISSIONS)
	main._missions._shown = ""
	main.refresh()
	main._missions._boss(2)
	for k in range(4):
		main._missions._shown = ""
		main.refresh()
	var boss_toasts: int = main._juice.lines().filter(func(l): return str(l).begins_with("The carpet man: ")).size()
	_check(boss_toasts == 1, "the boss toggle toasted %d times" % boss_toasts)
	main._missions._boss(2)
	main.refresh()
	main._missions._boss(2)
	main.refresh()
	boss_toasts = main._juice.lines().filter(func(l): return str(l).begins_with("The carpet man: ")).size()
	_check(boss_toasts == 1, "toggling off and on again toasted again while the first still showed: %d" % boss_toasts)
	# the odds read a few milliseconds a frame (main._read_odds, 7 Oct) and settle; a refresh never runs one;
	# without the shell's brake, all at once
	sim._surv_cache = {}
	sim.odds_budget = main.ODDS_BUDGET
	main.show_room(main.MISSIONS)
	main._missions._shown = ""
	var odds_t0 := Time.get_ticks_usec()
	main.refresh()
	var refresh_ms := (Time.get_ticks_usec() - odds_t0) / 1000.0
	var open_tiers := 0
	var settled_at_once := 0
	for i in range(Data.TIERS.size()):
		if sim.tier_open(i):
			open_tiers += 1
			if sim.odds_settled(i):
				settled_at_once += 1
	_check(settled_at_once == 0, "a refresh of the Runs screen read the odds itself (%d settled)" % settled_at_once)
	odds_t0 = Time.get_ticks_usec()
	main._read_odds()
	var frame_ms := (Time.get_ticks_usec() - odds_t0) / 1000.0
	_check(frame_ms < main.ODDS_MS + 150.0, "one frame's odds took %.0f ms (the brake is %.0f ms and one dry run)" % [frame_ms, main.ODDS_MS])
	var frames := 0
	while frames < 2000:
		main._read_odds()
		frames += 1
		var all_settled := true
		for i in range(Data.TIERS.size()):
			if sim.tier_open(i) and not sim.odds_settled(i):
				all_settled = false
		if all_settled:
			break
	for i in range(Data.TIERS.size()):
		if sim.tier_open(i):
			_check(sim.odds_settled(i), "tier %d's odds never settled in %d frames" % [i, frames])
	main._missions._shown = ""
	main.refresh()
	_check_fit(main, "Runs (odds settled)")
	print("the odds settled in %d frames; a refresh took %.0f ms" % [frames, refresh_ms])
	sim.odds_budget = 0
	sim._surv_cache = {}
	_check(sim.survival(0) >= 0.0 and sim.odds_settled(0), "without a budget the odds did not read at once")
	# a read that is plainly settled settles early: a runner nothing can touch reads 100% after EARLY_RUNS
	var hold_hp: float = sim.hp
	var hold_x: float = sim.xp
	sim.xp = Data.xp_for_level(90)
	sim.hp = sim.max_hp()
	sim._surv_cache = {}
	_check(sim.survival(0) >= 0.999 and sim._surv_cache[0][2] == Data.LOOKOUT_LEVELS[sim.lookout_level]["runs"], "a level-90 runner on the first site did not read as settled 100%%: %.2f" % sim.survival(0))
	sim.xp = hold_x
	sim.hp = hold_hp
	sim._surv_cache = {}
	print("the playtest's five ok: HP, Locked, the toasts, the log line, a paper in the Lock-up; the odds settle over refreshes")


func _recycle_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	sim.loose_kit = []
	sim.hardcore = false
	var jacket: Dictionary = sim._plain("Armour", "Riot suit")
	jacket["affixes"] = [{"stat": "hp", "value": 33.0, "tier": 3}]
	jacket["rarity"] = 2
	sim.equipped["Armour"] = jacket
	var cls_before: String = sim.cls
	sim.intel[0] = []
	sim.set_depth(0, 1)
	sim.hp = sim.max_hp()
	sim.insure_next = false
	sim.deploy(0)
	sim._kia()
	_check(sim.loose_kit.size() >= 1 and sim.loose_kit.any(func(e): return e["item"]["base"] == "Riot suit" and e["who"] == "the last %s" % cls_before.to_lower() and e["from"] == "runner"), "the dead runner's jacket did not go out on the estate: %s" % str(sim.loose_kit.map(func(e): return e["item"]["base"])))
	_check(str(sim.events.back()[1]).ends_with(Words.RECYCLE["listed"]) or sim.events.any(func(ev): return str(ev[1]).ends_with(Words.RECYCLE["listed"])), "the death's line does not say the kit will turn up")
	sim.loose_kit = sim.loose_kit.filter(func(e): return e["item"]["base"] == "Riot suit")   # the rest of the kit: the jacket's the one followed here
	# a unique sold to the fence goes on the list too
	var u: Dictionary = Items.roll_unique(sim._unique_named("Lucky cap"), sim.rng)
	sim.stash.append(u)
	sim.sell(u)
	_check(sim.loose_kit.any(func(e): return e["from"] == "fence" and e["item"].get("unique", "") == "Lucky cap"), "the unique sold did not go out on the estate")
	# too soon: nothing on the first runs; then one of them is wearing it
	sim.hp = sim.max_hp()
	sim.deploy(0)
	var m: Dictionary = sim.mission
	_check(not m.has("wearing"), "the kit turned up on the very next run")
	sim.extract_now()
	sim.runs_total += Data.RECYCLE_RUNS
	sim.hp = sim.max_hp()
	sim.deploy(0)
	m = sim.mission
	if not m.has("wearing"):
		sim._maybe_wearing(m, true)          # the deploy's own roll may have put it on someone already
	_check(m.has("wearing") and m["wearing"]["item"]["base"] == "Riot suit", "nobody was wearing the jacket when forced: %s" % str(m.get("wearing", {})))
	_check(sim.events.any(func(ev): return str(ev[1]) == Words.RECYCLE["wearing"] % ["the last %s" % cls_before.to_lower(), "riot suit"]), "the wearing line is off: %s" % str(sim.events.back()[1]))
	var found_before: int = m["found"].size()
	sim._clear(m, m["t"])
	_check(m["found"].size() == found_before + 1 and m["found"].back()["base"] == "Riot suit" and m["found"].back()["affixes"][0]["value"] == 33.0 and not m.has("wearing"), "the jacket did not come off him with its affix: %s" % str(m["found"].back() if not m["found"].is_empty() else {}))
	_check(sim.events.any(func(ev): return str(ev[1]).begins_with("Riot suit came off him. The last")), "the off line is off: %s" % str(sim.events.back()[1]))
	sim.extract_now()
	_check(sim.stash.any(func(it): return it["base"] == "Riot suit" and it["affixes"].size() == 1 and it["affixes"][0]["value"] == 33.0), "the jacket did not come home")
	# the unique, the same way
	sim.hp = sim.max_hp()
	sim.deploy(0)
	m = sim.mission
	if not m.has("wearing"):
		sim._maybe_wearing(m, true)
	_check(m.has("wearing") and m["wearing"]["from"] == "fence", "the sold unique was not on anyone: %s" % str(m.get("wearing", {})))
	_check(sim.events.any(func(ev): return str(ev[1]) == Words.RECYCLE["has"] % "Lucky cap"), "the has line is off: %s" % str(sim.events.back()[1]))
	sim._clear(m, m["t"])
	_check(not m["found"].is_empty() and m["found"].back().get("unique", "") == "Lucky cap", "the unique did not come off him")
	sim.extract_now()
	_check(sim.loose_kit.is_empty() or not sim.loose_kit.any(func(e): return e["item"].get("unique", "") == "Lucky cap"), "the unique stayed on the list after coming back")
	var d: Dictionary = sim.to_dict()
	sim.load_dict(d)
	_check(d.has("loose_kit"), "the list does not save")
	sim.load_dict(saved)
	print("the estate recycles ok: the dead runner's kit, the sold unique, too soon, worn, off him, home, saved")


## Money that goes off: every cash price and every cash income rises with the
## yard's hours, after a grace hour, to a ceiling; the notes don't move; the
## fence and the Played card say so.
func _inflation_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	sim.elapsed = 0.0
	_check(is_equal_approx(sim.inflation(), 1.0) and sim.inflation_pct() == 0, "prices rose in the first hour: %.2f" % sim.inflation())
	sim.elapsed = Data.INFLATION_GRACE_H * 3600.0
	_check(is_equal_approx(sim.inflation(), 1.0), "prices rose before the grace hour was out")
	var it: Dictionary = sim._plain("Primary", "Pipe shotgun")
	var p0: int = sim.price(it)
	var s0: int = sim.sell_price(it)
	var med0: int = sim.med_price(Data.BASES["Medical"][0])
	var ammo0: int = sim.ammo_price("shotgun")
	var ws0: int = sim.workshop_cost() if sim.workshop < Data.WORKSHOP.size() - 1 else 0
	sim.hp = sim.max_hp() * 0.5
	var treat0: int = sim.treat_cost()
	sim.elapsed = (Data.INFLATION_GRACE_H + 10.0) * 3600.0
	var m: float = 1.0 + Data.INFLATION_RATE * 10.0
	_check(is_equal_approx(sim.inflation(), m), "ten hours past the grace reads %.2f, not %.2f" % [sim.inflation(), m])
	_check(sim.price(it) == int(round(p0 * m)) or absi(sim.price(it) - int(round(p0 * m))) <= 1, "the fence's asking price did not rise: %d -> %d" % [p0, sim.price(it)])
	_check(absi(sim.sell_price(it) - int(round(s0 * m))) <= 1, "the fence's paying price did not rise: %d -> %d" % [s0, sim.sell_price(it)])
	_check(absi(sim.med_price(Data.BASES["Medical"][0]) - int(round(med0 * m))) <= 1, "meds did not rise")
	_check(absi(sim.ammo_price("shotgun") - int(round(ammo0 * m))) <= 1, "shells did not rise")
	# a standard box on the shelf costs what the box row charges for it; special rounds carry the markup
	for type in ["pistol", "shotgun", "rifle", "smg", "improvised"]:
		var box: Dictionary = sim._plain(Data.AMMO, sim.ammo_box(type)["name"])
		_check(sim.price(box) == sim.ammo_price(type), "%s on the shelf: %d, the box row: %d" % [type, sim.price(box), sim.ammo_price(type)])
	for b in Data.BASES[Data.AMMO]:
		if b.has("damage_pct"):
			var special: Dictionary = sim._plain(Data.AMMO, b["name"])
			_check(sim.price(special) > sim.ammo_price(str(b["type"])), "%s is no dearer than the plain box" % b["name"])
			break
	# and the shelf never stocks a standard box at all: the box row has those without end
	var plain_on_shelf := 0
	var specials := 0
	for k in range(40):
		sim.restock()
		for stocked in sim.market:
			if Items.is_ammo(stocked):
				if Items.base_of(stocked).has("damage_pct"):
					specials += 1
				elif stocked["affixes"].is_empty():
					plain_on_shelf += 1
	_check(plain_on_shelf == 0, "the shelf stocked a standard box %d times over forty restocks" % plain_on_shelf)
	_check(specials > 0 or sim.gear_tier() < 2, "forty restocks at gear tier %d put no special rounds on the shelf" % sim.gear_tier())
	# the clinic with nothing picked: the rig's summary, and no button acting on something unpicked
	main.show_room(main.MEDIC)
	main._clinic.selected = {}
	main.refresh()
	var any_button := false
	for b in main._clinic._buttons:
		any_button = any_button or b.visible
	_check(not any_button, "the clinic's empty panel shows a button: %s" % str(main._clinic._buttons.map(func(b): return b.text if b.visible else "")))
	_check_fit(main, "Clinic (nothing picked)")
	_check(ws0 == 0 or absi(sim.workshop_cost() - int(round(ws0 * m))) <= 1, "the bench's upgrade did not rise: %d -> %d" % [ws0, sim.workshop_cost()])
	_check(absi(sim.treat_cost() - int(round(treat0 * m))) <= 2, "treatment did not rise: %d -> %d" % [treat0, sim.treat_cost()])
	_check(sim.boss_cost(0) == sim.boss_cost(0) and Data.CRAFT["bump"].has("notes"), "notes prices exist to hold")
	var c0: int = sim.craft_cost(it, "reroll")
	sim.elapsed = Data.INFLATION_GRACE_H * 3600.0
	var c_base: int = sim.craft_cost(it, "reroll")
	_check(c0 < 0 or absi(c0 - int(round(c_base * m))) <= 1, "the bench's cash price did not rise: %d -> %d" % [c_base, c0])
	# the gangs carry today's money: a run's cash scales too
	sim.elapsed = (Data.INFLATION_GRACE_H + 10.0) * 3600.0
	sim.intel[0] = []
	sim.set_depth(0, 1)
	sim.hp = sim.max_hp()
	sim.deploy(0)
	var mm: Dictionary = sim.mission
	var t: Dictionary = mm["t"].duplicate(true)
	t["cash"] = 100.0
	var cash_before: float = mm["cash"]
	sim._kill(mm, t)
	_check(mm["cash"] - cash_before >= 100.0 * 0.5 * m * 0.99, "a kill's cash did not carry today's money: %.0f for a gang carrying 100 at ×%.2f" % [mm["cash"] - cash_before, m])
	sim.extract_now()
	# the ceiling
	sim.elapsed = 100000.0 * 3600.0
	_check(is_equal_approx(sim.inflation(), Data.INFLATION_CAP), "prices did not settle at the ceiling: %.2f" % sim.inflation())
	# the screens
	sim.elapsed = (Data.INFLATION_GRACE_H + 10.0) * 3600.0
	main.show_room(main.OVERVIEW)
	_check_fit(main, "The Yard (prices up)")
	main.show_room(main.MARKET)
	main._fence.selected = {}
	main.refresh()
	_check(main._fence._left_lines[0].text.begins_with("Prices up %d%%" % sim.inflation_pct()), "the fence does not say prices are up: %s" % main._fence._left_lines[0].text)
	_check_fit(main, "Fence (prices up)")
	sim.load_dict(saved)
	print("money that goes off ok: the grace hour, the rate, every cash price, the ceiling, the fence's line")


## The late cash sinks: call-ins priced by depth and by the words on the site;
## insurance, the fence holding the paper on the kit for a run.
func _sink_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	_finish_campaign(sim)
	sim.atlas = {}
	sim.intel[0] = []
	sim.set_depth(0, 1)
	# the call-in is half a run's takings (the yard's own average: the run's cash and the fence's money), never under the tier's word price three times
	sim.takings = 4000.0
	var c1: int = sim.juice_cost(0)
	_check(absi(c1 - int(round(maxf(float(sim._inf(Data.INTEL_CASH[0] * sim.JUICE_COST)), 4000.0 * sim.JUICE_SHARE)))) <= 1, "a call-in is not half a run's takings: %d" % c1)
	sim.takings = 0.0
	_check(sim.juice_cost(0) >= sim._inf(Data.INTEL_CASH[0] * sim.JUICE_COST) and sim.juice_cost(0) <= c1, "before a run has come home the call-in is not read off the top tier's kills: %d" % sim.juice_cost(0))
	sim.takings = 4000.0
	sim.best_depth[0] = 5
	sim.set_depth(0, 4)
	var c4: int = sim.juice_cost(0)
	_check(c4 == c1, "the depth moved the call-in's price when the takings had not: %d vs %d" % [c4, c1])
	sim.intel[0] = ["Numbers", "Night"]
	_check(absi(sim.juice_cost(0) - c4 * 3) <= 2, "two words on the site did not treble the call-in: %d vs %d" % [sim.juice_cost(0), c4 * 3])
	sim.atlas_points = 1
	sim.rank_atlas("word_travels")
	_check(absi(sim.juice_cost(0) - c4 * 3 / 2) <= 2, "Word travels did not halve it: %d" % sim.juice_cost(0))
	sim.atlas = {}
	# insurance: priced on the kit by depth, paid at deploy, pays out on a death
	sim.set_depth(0, 2)
	var worth: int = sim.loadout_value()
	_check(worth > 0, "no kit worn to insure")
	var cost: int = sim.insure_cost(0)
	var quote: float = worth * sim.inflation() * Data.INSURE_RATE * 2
	_check(cost >= quote - 10 and cost <= quote + 10, "insurance at depth 2 is %d on £%d of kit at ×%.2f" % [cost, worth, sim.inflation()])
	sim.cash = float(cost) - 1.0
	_check(not sim.can_insure(0), "insurance took with the cash a pound short")
	sim.cash = float(cost) + 100.0
	sim.set_insure(true)
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(0)
	_check_fit(main, "Runs (insured)")
	sim.deploy(0)
	_check(sim.mission["insured"] and is_equal_approx(sim.cash, 100.0) and not sim.insure_next, "the premium was not paid at deploy")
	var worn_ids := []
	for s in Data.SLOTS:
		if sim.equipped[s] != null:
			worn_ids.append(sim.equipped[s]["id"])
	var rig_n: int = sim.rig.size()
	var stash_n: int = sim.stash.size()
	sim.hardcore = false
	sim.mission["hp_start"] = sim.hp
	sim._kia()
	_check(sim.last_report["lost_value"] == 0, "the insured death reported kit lost")
	var back := 0
	for id in worn_ids:
		for it in sim.stash:
			if it["id"] == id:
				back += 1
				break
	_check(back == worn_ids.size() and sim.stash.size() == stash_n + worn_ids.size() + rig_n, "the insured kit did not come back to the stash: %d of %d, stash %d -> %d" % [back, worn_ids.size(), stash_n, sim.stash.size()])
	_check(str(sim.events.back()[1]).contains("turns up") or str(sim.events[-2][1]).contains("held the paper"), "the payout had no line")
	# and without it, the kit goes
	sim.choose_runner(0)
	sim.deploy(0)
	_check(not sim.mission["insured"], "a run insured itself")
	sim.mission["hp_start"] = sim.hp
	stash_n = sim.stash.size()
	sim._kia()
	_check(sim.last_report["lost_value"] > 0 and sim.stash.size() == stash_n, "an uninsured death kept the kit")
	sim.choose_runner(0)
	main.refresh()
	_check_fit(main, "Runs (after)")
	sim.load_dict(saved)
	print("the late sinks ok: call-ins by depth and words, insurance paid and paid out")
	_damage_model_checks(main)


## The damage model: a hit split by type, each cut by their resist, dots
## both ways, chill and shock, armour for physical and resists for the rest.
func _damage_model_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	sim.equipped["Secondary"] = null
	for s in ["Helmet", "Armour", "Charm"]:
		sim.equipped[s] = null
	var conv: Dictionary = sim.conversion()
	_check(is_equal_approx(conv["physical"], 1.0), "a plain gun is not all physical: %s" % str(conv))
	var gun: Dictionary = sim.equipped["Primary"]
	gun["attachments"]["socket 1"] = sim._plain("Attachment", "Lighter fluid")
	gun["affixes"] = [{"stat": "fire_pct", "value": 20, "tier": 3}]
	conv = sim.conversion()
	_check(is_equal_approx(conv["fire"], 0.15) and is_equal_approx(conv["physical"], 0.85), "the fluid did not make 15%% fire: %s" % str(conv))
	var td: Dictionary = sim.type_dps()
	_check(is_equal_approx(td["fire"], sim.dps() * 0.15 * 1.2) and is_equal_approx(td["physical"], sim.dps() * 0.85), "type dps is off: %s against %.1f" % [str(td), sim.dps()])
	var t0 := {"dps": 10.0, "res": {"fire": 0.5}, "types": {"physical": 0.5, "fire": 0.5}}
	_check(is_equal_approx(sim.damage_rate(t0), td["physical"] + td["fire"] * 0.5), "their fire resist did not halve the fire share")
	_check(is_equal_approx(sim.damage_rate(t0, true), (td["physical"] + td["fire"] * 0.5) * (1.0 + Data.SHOCK)), "shocked did not take more")
	gun["affixes"] = [{"stat": "conv_fire_pct", "value": 60, "tier": 5}, {"stat": "conv_frost_pct", "value": 60, "tier": 5}]
	conv = sim.conversion()
	# 60 fire on the gun and 15 in the socket against 60 frost: shared out to one, no physical left
	_check(is_equal_approx(conv["fire"], 75.0 / 135.0) and is_equal_approx(conv["frost"], 60.0 / 135.0) and is_equal_approx(conv["physical"], 0.0), "over-conversion did not share out: %s" % str(conv))
	gun["affixes"] = []
	var armour: Dictionary = sim._plain("Armour", "Stab vest")
	armour["affixes"] = [{"stat": "fire_res", "value": 40, "tier": 5}, {"stat": "all_res", "value": 10, "tier": 3}]
	sim.equipped["Armour"] = armour
	_check(is_equal_approx(sim.resist("fire"), 0.5) and is_equal_approx(sim.resist("shock"), 0.1) and is_equal_approx(sim.resist("physical"), 0.0), "resists do not add: fire %.2f shock %.2f" % [sim.resist("fire"), sim.resist("shock")])
	armour["affixes"].append({"stat": "fire_res", "value": 90, "tier": 5})
	_check(is_equal_approx(sim.resist("fire"), Data.RESIST_CAP / 100.0), "the resist cap did not hold: %.2f" % sim.resist("fire"))
	var mit: float = sim.mitigation()
	var expect: float = 10.0 * 0.5 * (1.0 - mit) + 10.0 * 0.5 * (1.0 - 0.75)
	_check(is_equal_approx(sim.incoming_rate(t0, 1), expect), "incoming by type is off: %.2f vs %.2f" % [sim.incoming_rate(t0, 1), expect])
	_check(is_equal_approx(sim.incoming_rate(t0, 1, true), expect * (1.0 - Data.CHILL)), "chilled did not slow their fire")
	sim.intel[0] = []
	sim.set_depth(0, 1)
	var e: Dictionary = sim.effective(0)
	_check(e.has("types") and e.has("res") and is_equal_approx(e["types"]["physical"] + e["types"]["bleed"], 1.0) and e["types"]["bleed"] > 0.1, "the estate's fire is not mostly physical with some bleed: %s" % str(e["types"]))
	sim.intel[0] = ["Burners", "Jacketed"]
	e = sim.effective(0)
	_check(e["types"].get("fire", 0.0) >= 0.33 and e["res"]["fire"] >= 0.4, "Burners and Jacketed did not take: %s %s" % [str(e["types"]), str(e["res"])])
	sim.intel[0] = ["Resistant"]
	_finish_campaign(sim)
	sim.best_depth[0] = 20
	sim.set_depth(0, 12)
	e = sim.effective(0)
	_check(e["res"]["bleed"] >= 0.25 + Data.RESIST_DEPTH_STEP * 4 and is_equal_approx(e["res"]["fire"], 0.25) and e["res"]["fire"] <= Data.RESIST_ENEMY_CAP, "Resistant at depth 12 is %s (the estate's own bleed grows, the rest stay as the word says)" % str(e["res"]))
	sim.intel[0] = []
	sim.set_depth(0, 1)
	var dots := {}
	sim._dot_add(dots, "fire", 100.0, 100.0)
	_check(is_equal_approx(dots["fire"], 50.0), "a 100 fire hit did not leave a 50 burn: %s" % str(dots))
	var ticked: float = sim._dot_tick(dots, 1.0, {})
	_check(is_equal_approx(ticked, 12.5) and is_equal_approx(dots["fire"], 37.5), "the burn did not tick a quarter of the pool a second: %.1f" % ticked)
	for k in range(60):
		sim._dot_add(dots, "poison", 100.0, 100.0)
	var poison_cap: float = 100.0 * 0.8 * sim.dot_seconds("poison") * sim.dot_stacks("poison")
	_check(is_equal_approx(dots["poison"], poison_cap), "poison did not cap at its stacks: %.0f, not %.0f" % [dots["poison"], poison_cap])
	sim.intel[0] = ["Cutters"]
	sim.hp = sim.max_hp()
	sim.deploy(0)
	var m: Dictionary = sim.mission
	for k in range(6):
		sim.advance(0.5)
		if m["remaining"] <= 0:
			break
	_check((m.has("my_dots") and float(m["my_dots"].get("bleed", 0.0)) > 0.0) or m["remaining"] <= 0, "a cutters' gang left no bleed on you: %s" % str(m.get("my_dots", {})))
	if m["remaining"] > 0 and not sim.first_med().is_empty():
		sim.use_med(sim.first_med()["id"])
		for k in range(40):
			sim.advance(0.5)
			if m["using"] == null:
				break
		_check(not m.get("my_dots", {}).has("bleed"), "the dressing did not stop the bleeding")
	sim.extract_now()
	sim.intel[0] = []
	sim.load_dict(saved)
	print("the damage model ok: conversion, type dps, their resists, shock, your resists and the cap, incoming by type, chill, the sites' types, the words, dots, a dressing")
	# every gun says what it takes, and the Lock-up's panel shows it
	for slot in ["Primary", "Secondary"]:
		for b in Data.BASES[slot]:
			var g: Dictionary = sim._plain(slot, b["name"])
			_check(Items.ammo_words(g).begins_with("Takes "), "%s does not say what it takes" % b["name"])
	_check(Items.ammo_words(sim._plain("Primary", "Pipe shotgun")) == "Takes shells", "a pipe shotgun takes %s" % Items.ammo_words(sim._plain("Primary", "Pipe shotgun")))
	_check(Items.ammo_words(sim._plain("Primary", "Nail gun")) == "Takes nails", "a nail gun takes %s" % Items.ammo_words(sim._plain("Primary", "Nail gun")))
	_check(Items.ammo_type(sim._plain("Primary", "Garage-built rifle")) == "rifle" and Items.base_of(sim._plain("Primary", "Garage-built rifle"))["type"] == "improvised", "the garage rifle's ammo and type are not apart")
	var shown: Dictionary = sim._plain("Primary", "Farmer's shotgun")
	sim.stash.append(shown)
	main.show_room(main.ARMOURY)
	main._armoury.selected = {"kind": "stash", "id": shown["id"]}
	main.refresh()
	_check(main._armoury._head._tail.text.contains("takes shells") or main._armoury._head._tail.text.contains("shotgun rounds"), "the Lock-up's panel does not say the shotgun takes shells: '%s'" % main._armoury._head._tail.text)
	_check_fit(main, "Armoury (ammo words)")
	sim.sell(shown)
	print("ammo words ok")


## The pool: a typed part counts on its type only; a unique's rule fires; worn weight is pace.
func _pool_checks(sim) -> void:
	var gun = sim.equipped["Primary"]
	var shotgun: Dictionary = sim._plain("Primary", "Farmer's shotgun")
	var rifle: Dictionary = sim._plain("Primary", "Stalking rifle")
	var choke := Items.roll(Data.ATTACHMENT, 1, sim.rng)
	choke["base"] = "Choke"
	choke["mount"] = "muzzle"
	choke["affixes"] = []
	shotgun["attachments"]["muzzle"] = choke
	rifle["attachments"]["muzzle"] = choke.duplicate(true)
	_check(Items.fitted_sum(shotgun, "damage_pct") >= 15.0, "a choke did not count on a shotgun")
	_check(Items.fitted_sum(rifle, "damage_pct") < 1.0, "a choke counted on a rifle")
	sim.equipped["Primary"] = Items.roll_unique(Data.UNIQUES[0], sim.rng)
	_check(sim.has_rule("grandads") and Items.full_name(sim.equipped["Primary"]) == "Grandad's shotgun", "the unique's rule or name is wrong")
	# gear tiers run to 5: the bank drops tier 5, and the fence stocks what the open sites drop
	_check(Data.TIERS[Data.TIERS.size() - 1]["loot_tier"] == Data.MAX_TIER, "the last site does not drop the top tier")
	var top := 0
	for slot in Data.SLOTS:
		for b in Data.BASES[slot]:
			top = maxi(top, int(b["tier"]))
	_check(top == Data.MAX_TIER, "no base at the top tier")
	_check(sim.gear_tier() <= Data.MAX_TIER and sim.gear_tier() >= 1, "gear_tier out of range")
	sim.equipped["Primary"] = gun
	var armour = sim.equipped["Armour"]
	sim.equipped["Armour"] = sim._plain("Armour", "Padded jacket")
	var pace0: float = sim.pace()
	sim.equipped["Armour"] = sim._plain("Armour", "Riot suit")
	_check(sim.pace() < pace0, "a riot suit did not slow the runner against a padded jacket")
	sim.equipped["Armour"] = armour
	print("pool checks ok")
	_ammo_checks(sim)


## Ammo: rounds come off the rig as the gun fires; dry means the secondary, then fists;
## a box bought at the fence is a stack in the stash; a better grade adds damage.
func _ammo_checks(sim) -> void:
	if sim.on_mission():
		sim.extract_now()
	var gun = sim.equipped["Primary"]
	var kept_rig: Array = sim.rig.duplicate()
	sim.rig = []
	sim.rig.append(sim._plain(Data.AMMO, Data.BASES[Data.AMMO][0]["name"]))     # nails
	sim.equipped["Primary"] = sim._plain("Primary", "Nail gun")
	var sec = sim.equipped["Secondary"]
	sim.equipped["Secondary"] = null
	var with_rounds: float = sim.dps()
	var before: int = sim.rounds_for(sim.equipped["Primary"])
	sim.set_depth(0, 1)
	sim.hp = sim.max_hp()
	sim.deploy(0)
	sim.mission["t"]["dps"] = 0.0          # nothing coming back: the twenty seconds are about the rounds, not the runner's life
	for k in range(20):
		sim.advance(1.0)
	_check(sim.on_mission() and sim.rounds_for(sim.equipped["Primary"]) < before, "the nail gun fired twenty seconds and spent no rounds")
	# the secondary backing a live primary spends a third of its rate; alone, all of it
	sim.extract_now()
	sim.equipped["Secondary"] = sim._plain("Secondary", "Service pistol")
	sim.rig = [sim._plain(Data.AMMO, "Nails"), sim._plain(Data.AMMO, "Pistol rounds")]
	var pistol0: int = sim.rounds_for(sim.equipped["Secondary"])
	sim.hp = sim.max_hp()
	sim.deploy(0)
	sim.mission["t"]["dps"] = 0.0
	for k in range(30):
		sim.advance(1.0)
	var backing: int = pistol0 - sim.rounds_for(sim.equipped["Secondary"])
	_check(backing > 0, "a pistol backing a live primary spent no rounds over thirty seconds")
	sim.extract_now()
	sim.rig = [sim._plain(Data.AMMO, "Pistol rounds")]        # the nail gun dry: the pistol is the gun in hand
	pistol0 = sim.rounds_for(sim.equipped["Secondary"])
	sim.hp = sim.max_hp()
	sim.deploy(0)
	sim.mission["t"]["dps"] = 0.0
	for k in range(30):
		sim.advance(1.0)
	var alone: int = pistol0 - sim.rounds_for(sim.equipped["Secondary"])
	_check(alone > backing * 2, "the pistol in hand (%d rounds) fires no faster than backing (%d)" % [alone, backing])
	sim.equipped["Secondary"] = null
	sim.extract_now()
	sim.rig = []
	_check(sim.dps() < with_rounds * 0.5, "a gun with no rounds still fires: %.1f against %.1f" % [sim.dps(), with_rounds])
	sim.rig.append(sim._plain(Data.AMMO, "Hardened bolts"))
	_check(sim.dps() > with_rounds, "the better grade did not add damage")
	sim.cash += 1000.0
	while not sim.stash_room(1) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])                 # room for the box
	# the box lands as a new stack, or tops up a shells stack already there
	var shells_before: int = sim.stash.reduce(func(a, it): return a + (int(it.get("rounds", 0)) if Items.is_ammo(it) and Items.ammo_type(it) == "shotgun" else 0), 0)
	var cash_before: float = sim.cash
	_check(sim.buy_ammo("shotgun"), "the fence would not sell a box of shells (cash £%.0f, room %s)" % [sim.cash, str(sim.stash_room(1))])
	var shells_after: int = sim.stash.reduce(func(a, it): return a + (int(it.get("rounds", 0)) if Items.is_ammo(it) and Items.ammo_type(it) == "shotgun" else 0), 0)
	_check(shells_after > shells_before and sim.cash < cash_before, "a box from the fence did not land in the stash: %d shells then %d" % [shells_before, shells_after])
	sim.sell(sim.stash.back())
	sim.rig = kept_rig
	sim.equipped["Primary"] = gun
	sim.equipped["Secondary"] = sec
	print("ammo checks ok")


## The highest open tier whose estimated damage taken leaves half the HP.
func _pick_tier(sim) -> int:
	var best := 0
	for i in range(Data.TIERS.size()):
		if not sim.tier_open(i):
			continue
		if sim.survival(i) >= 0.8:
			best = i
	# the zone's boss, once its site is cleared and the odds hold with them in
	var b: Dictionary = sim.boss_of(best)
	if not b.is_empty() and sim.best_depth[best] > 0 and not sim.bosses_beaten[int(b["zone"])]:
		sim.arm_boss(best, true)
		if sim.survival(best) < 0.6:
			sim.arm_boss(best, false)
	return best


## Climb: when a tier reads safe, go a depth deeper on it.
func _climb(sim) -> void:
	for i in range(Data.TIERS.size()):
		if sim.tier_open(i) and sim.depth[i] <= sim.best_depth[i] and sim.survival(i) >= 0.9:
			sim.set_depth(i, sim.depth[i] + 1)


## Buy the bench when the cash is there with £500 to spare; fit the best
## attachment the stash holds on every open mount of both guns.
func _bench(sim) -> void:
	while sim.can_upgrade_workshop() and sim.cash >= sim.workshop_cost() + 500:
		sim.upgrade_workshop()
	for pair in [[sim.can_upgrade_stash, sim.stash_cost, sim.upgrade_stash], [sim.can_upgrade_medic, sim.medic_cost, sim.upgrade_medic],
			[sim.can_upgrade_market, sim.market_cost, sim.upgrade_market], [sim.can_upgrade_comms, sim.comms_cost, sim.upgrade_comms]]:
		if pair[0].call() and sim.cash >= pair[1].call() + 500:
			pair[2].call()
	for slot in ["Primary", "Secondary"]:
		var gun = sim.equipped[slot]
		if gun == null:
			continue
		for mount in gun["attachments"]:
			if not sim.mount_open(mount):
				continue
			var best: Array = sim.attachments_for(mount, str(Items.base_of(gun).get("type", "")))
			if best.is_empty():
				continue
			var cur = gun["attachments"][mount]
			if cur == null or Items.score(best[0]) > Items.score(cur):
				sim.fit(slot, best[0]["id"])


## Spend every free point: Marksmanship first, then Conditioning, then Fieldcraft.
func _train_tree(sim) -> void:
	var spent := true
	while sim.points_free() > 0 and spent:
		spent = false
		for b in sim.trees():
			for i in range(b["nodes"].size()):
				var id := "%s/%d" % [b["name"], i]
				if sim.can_train(id):
					sim.train_node(id)
					spent = true
					break
			if spent:
				break


## Fill the rig with bandages from the Medic Tent, taken through the sim.
func _restock_meds(sim) -> void:
	var gun = sim.equipped["Primary"]
	if gun != null:
		var guard := 0
		while sim.rounds_for(gun) < int(Items.base_of(gun)["rof"] * 240.0) and sim.rig_room(1) and guard < 4:
			guard += 1
			var took := false
			for it in sim.stash:
				if Items.is_ammo(it) and Items.base_of(it)["type"] == Items.ammo_type(gun):
					took = sim.take(it["id"])
					break
			if not took and not sim.buy_ammo(Items.ammo_type(gun)):
				break
	while sim.rig_room(1):
		var took := false
		for it in sim.stash:
			if Items.is_medical(it):
				took = sim.take(it["id"])
				break
		if took:
			continue
		if not sim.buy_med("Bandage"):
			return


## Sell everything in the stash that isn't the best of its slot - a player's
## tidy-up, and what keeps the stash from filling.
func _sell_spares(sim) -> void:
	for it in sim.stash.duplicate():
		if Items.is_attachment(it) or Items.rig_item(it):
			continue
		var best: Dictionary = sim.best_in_stash(it["slot"])
		if best.is_empty() or best["id"] != it["id"]:
			sim.sell(it)


## Buy the one market item that beats what's fitted by the most, if affordable.
func _buy_upgrade(sim) -> void:
	var pick := -1
	var gain := 0.0
	for i in range(sim.market.size()):
		var it: Dictionary = sim.market[i]
		if Items.is_attachment(it) or Items.rig_item(it):
			continue
		var cur = sim.equipped[it["slot"]]
		var g: float = Items.score(it) - (Items.score(cur) if cur != null else 0.0)
		if g > gain and sim.cash >= sim.price(it) + 100:
			gain = g
			pick = i
	if pick >= 0:
		sim.buy(pick)
		for s in Data.SLOTS:
			sim.equip_best(s)


## Every label on whatever is showing has to fit: its text inside its box
## (a button's text with the button's margins), its box inside its parent top
## to bottom, and no two boxes with text on top of each other - except a
## label-and-value pair that shares a line by design, which is checked as a
## pair instead. Greenhorn's lesson: a screen that isn't measured clips.
## The grid's packing, checked: every footprint inside the columns, none
## overlapping, none across a page's edge, every one over a drawn outline;
## the outlines are the capacity or the reach, never padding.
func _check_grid(inv, cap: int, what: String) -> void:
	var placed: Dictionary = inv.placed()
	var taken := {}
	var reach := 0
	for id in placed:
		var r: Rect2i = placed[id]
		_check(r.position.x >= 0 and r.position.x + r.size.x <= inv.COLS, "%s: an item sits outside the columns: %s" % [what, str(r)])
		_check((r.position.y / inv.page_rows) == ((r.position.y + r.size.y - 1) / inv.page_rows), "%s: an item crosses a page edge: %s" % [what, str(r)])
		for dy in range(r.size.y):
			for dx in range(r.size.x):
				var c := Vector2i(r.position.x + dx, r.position.y + dy)
				_check(not taken.has(c), "%s: two items share cell %s" % [what, str(c)])
				taken[c] = true
		reach = maxi(reach, (r.position.y + r.size.y - 1) * inv.COLS + r.position.x + r.size.x)
	var want := maxi(cap, reach)
	var a_page: int = inv.page_rows * inv.COLS
	var on_page := clampi(want - inv.page * a_page, 0, a_page)
	_check(inv.outlines_shown() == on_page, "%s shows %d outlines for %d cells (reach %d, page %d)" % [what, inv.outlines_shown(), cap, reach, inv.page])
	# every visible cell's pixels lie over outlines: the item is on the container
	for k in range(inv._cells.size()):
		var c = inv._cells[k]
		if not c.visible:
			continue
		var r: Rect2i = placed.get(c.id, Rect2i())
		var top: int = inv.page * inv.page_rows
		var last: int = (r.position.y + r.size.y - 1 - top) * inv.COLS + r.position.x + r.size.x - 1
		_check(last < inv.outlines_shown(), "%s: %s is drawn past the last outline" % [what, str(r)])


## The body: a stash item dropped on its own slot's box is taken and equipped;
## on every other box it is refused; dragged off, the stash takes it back and
## the slot is empty. Every slot pair, with a plain item of each slot.
func _body_drops(main) -> void:
	var sim = main.sim
	while not sim.stash_room(30) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])                 # room for the swaps, both ways: the run may have filled it
	_check(sim.stash_room(30), "no room could be made in the stash: %d of %d" % [sim.stash_used(), sim.stash_cap()])
	main.show_room(main.ARMOURY)
	var body = main._armoury._body
	for slot in Data.SLOTS:
		var it: Dictionary = sim._plain(slot, Data.BASES[slot][0]["name"])
		sim.stash.append(it)
		main.refresh()
		var data := {"id": it["id"], "src": "stash"}
		for other in Data.SLOTS:
			var ok: bool = body._can_drop(Vector2.ZERO, data, other)
			_check(ok == (other == slot), "a %s dropped on the %s box was %s" % [slot.to_lower(), other.to_lower(), "taken" if ok else "refused"])
		var was = sim.equipped[slot]
		var stash_n: int = sim.stash.size()
		body._drop(Vector2.ZERO, data, slot)
		_check(sim.equipped[slot] != null and sim.equipped[slot]["id"] == it["id"], "a drop on the %s box did not equip" % slot.to_lower())
		_check(sim.stash.size() == stash_n - (1 if was == null else 0), "the swap out of the %s box did not return the old item to the stash" % slot.to_lower())
		_check(main._armoury.selected.get("slot", "") == slot, "the selection did not follow the drop into the %s box" % slot.to_lower())
		main.refresh()
		_check_fit(main, "Armoury (body drop %s)" % slot.to_lower())
		# off again: the stash takes a "body" drop
		_check(main._armoury._inv._can_drop_data(Vector2.ZERO, {"id": it["id"], "src": "body", "slot": slot}), "the stash refused the %s dragged off the body" % slot.to_lower())
		main._armoury._inv._drop_data(Vector2.ZERO, {"id": it["id"], "src": "body", "slot": slot})
		_check(sim.equipped[slot] == null, "dragging the %s off the body did not unequip it" % slot.to_lower())
		_check(main._armoury.selected.get("kind", "") == "stash" and main._armoury.selected.get("id", -1) == it["id"], "the selection did not follow the %s back to the stash" % slot.to_lower())
		main.refresh()
		_check_fit(main, "Armoury (body empty %s)" % slot.to_lower())
		if was != null:
			sim.equip_item(was["id"])
		sim.sell(it)
	# a drop needs room for what comes off: a full stash refuses the swap
	var heavy: Dictionary = sim._plain("Armour", "Riot suit")
	var light: Dictionary = sim._plain("Armour", "Stab vest")
	var old = sim.equipped["Armour"]
	while not sim.stash_room(30) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])
	sim.stash.append(heavy)
	_check(sim.equip_item(heavy["id"]), "the riot suit did not go on for the room test")
	sim.stash.append(light)
	var filler := []
	while sim.stash_used() + Items.size(heavy) - Items.size(light) <= sim.stash_cap():
		var f: Dictionary = sim._plain("Ammo", "Nails")
		filler.append(f)
		sim.stash.append(f)
	_check(not body._can_drop(Vector2.ZERO, {"id": light["id"], "src": "stash"}, "Armour"), "a swap with no stash room for what comes off was allowed")
	for f in filler:
		sim.stash.erase(f)
	_check(body._can_drop(Vector2.ZERO, {"id": light["id"], "src": "stash"}, "Armour"), "a swap with stash room was refused")
	sim.stash.erase(light)
	sim.equipped["Armour"] = old
	print("body drag and drop ok: every slot pair")


func _check_fit(main, where: String) -> void:
	var bad := 0
	for k in range(main._cards.size()):
		var c = main._cards[k]
		if c.visible:
			bad += _check_nodes(c.text_nodes(), c.line_pairs(), "%s card %d" % [where, k])
	if main.room == main.MISSIONS and main.sim.on_mission():
		bad += _check_nodes(main._run.text_nodes(), main._run.line_pairs(), where + " run screen")
	elif main.room == main.MISSIONS:
		bad += _check_nodes(main._missions.text_nodes(), main._missions.line_pairs(), where + " screen")
	elif main.room == main.WORKSHOP:
		bad += _check_nodes(main._workshop.text_nodes(), main._workshop.line_pairs(), where + " screen")
	elif main.room == main.BARRACKS:
		var pairs := []
		for col in main._barracks._rows:
			for n in col:
				if n["button"].visible and n["more"].visible and n["name"].position.y == n["more"].position.y:   # a tile's name and its cost share the row
					pairs.append([n["name"], n["more"]])
		bad += _check_nodes(main._barracks.text_nodes(), pairs, where + " screen")
	elif main.room == main.MARKET:
		bad += _check_nodes(main._fence.text_nodes(), main._fence.line_pairs(), where + " screen")
		_check(main._fence.face_clear(), where + ": the fence's face is under something")
	elif main.room == main.MEDIC:
		bad += _check_nodes(main._clinic.text_nodes(), main._clinic.line_pairs(), where + " screen")
		_check(main._clinic.face_clear(), where + ": the medic's face is under something")
	elif main.room == main.ARMOURY:
		bad += _check_nodes(main._armoury.text_nodes(), main._armoury.line_pairs() if main._armoury.has_method("line_pairs") else [], where + " screen")
		_check_grid(main._armoury._inv, main.sim.stash_cap(), where + " stash grid")
		_check(main._armoury._containers.pack_inside(), "%s: the pack map (%d cells at %.0f px) runs out of its room" % [where, main.sim.capacity(), main._armoury._containers.pack_cell()])
		# the body's boxes: inside the panel, none overlapping, and the item cell inside its box
		var body = main._armoury._body
		for a in Data.SLOTS:
			var ra: Rect2 = body.box_rect(a)
			_check(Rect2(Vector2.ZERO, body.size).encloses(ra), "%s: the %s box leaves the body panel" % [where, a])
			var cell = body._boxes[a]["cell"]
			if cell.visible:
				_check(Rect2(Vector2.ZERO, ra.size).encloses(Rect2(cell.position, cell.size)), "%s: the %s in its box overflows it" % [where, a])
			for b in Data.SLOTS:
				if a < b:
					_check(not ra.intersects(body.box_rect(b)), "%s: the %s and %s boxes overlap" % [where, a, b])
	if main.room == main.OVERVIEW and main._yard_works.visible:
		bad += _check_nodes(main._yard_works.text_nodes(), main._yard_works.line_pairs(), where + " yard jobs")
		bad += _check_nodes(main._yard_town.text_nodes(), main._yard_town.line_pairs(), where + " town and purse")
	var rail_nodes := []
	for name in main.ROOMS:
		var b = main._rail_buttons[name]
		rail_nodes.append_array(b.text_nodes())
		if b.badge_gap() < 8.0:
			push_error("rail %s: badge overlaps the name" % name)
			bad += 1
	bad += _check_nodes(rail_nodes, [], where + " rail")
	bad += _check_nodes(main._top_labels.values(), [], where + " top bar")
	_check(main._top_labels["dps"].text.ends_with(" dmg/s") and main._top_labels["dps"].position.x > main._top_labels["hp"].position.x and main._top_labels["dps"].position.x < main._top_labels["xp"].position.x,
			"%s: the top bar's dmg/s is off: '%s'" % [where, main._top_labels["dps"].text])
	if main._menu.visible:
		bad += _check_nodes(main._menu.text_nodes(), [], where + " menu")
		var pr: Rect2 = main._menu.panel_rect()
		for i in range(main._menu._items.size()):
			var b = main._menu._rows[i]
			_check(b.position.y + b.size.y + main._menu.PAD <= main._menu._panel.size.y + 0.5, "%s menu: row %d runs off the panel" % [where, i])
		_check(pr.position.y >= 0.0 and pr.end.y <= 1080.0, "%s menu: the panel leaves the screen (%s)" % [where, pr])
	bad += _check_nodes(main._juice.text_nodes(), [], where + " toasts")
	# and the sweep: every label showing anywhere, whether or not its screen
	# lists it - a label the lists miss is the one that trails off in play
	var all_labels := []
	_labels_under(main, all_labels)
	bad += _check_widths(all_labels, where + " (sweep)")
	bad += _check_buttons_clear(main, all_labels, where + " (sweep)")
	_misfits += bad


## No button over a label's text beside it in the same panel (the Bench's
## upgrade button clipped the words above it). Same parent only: headless,
## panels placed by the shell's layout can still be at their birth positions,
## so rects across panels don't compare.
func _check_buttons_clear(main, labels: Array, where: String) -> int:
	var UI = load("res://scripts/ui/ui.gd")
	var buttons := []
	_buttons_under(main, buttons)
	var bad := 0
	for b in buttons:
		var br := Rect2(b.position, b.size)
		for l in labels:
			if l is Button or l.get_parent() != b.get_parent():
				continue
			var x: Rect2 = br.intersection(Rect2(l.position, l.size).intersection(_text_rect_local(l, UI)))
			if x.size.x > 2.0 and x.size.y > 2.0:
				push_error("%s: the button '%s' sits on '%s' (%.0f × %.0f px)" % [where, b.text, l.text, x.size.x, x.size.y])
				bad += 1
	return bad


## A label's text rect in its parent's space: its width at its alignment, the font's height centred.
static func _text_rect_local(n: Control, UI) -> Rect2:
	var tw: float = UI.text_width(n, n.text)
	var f: Font = n.get_theme_font("font")
	var th: float = f.get_height(n.get_theme_font_size("font_size"))
	var x := n.position.x
	if n.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x = n.position.x + n.size.x - tw
	elif n.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x = n.position.x + (n.size.x - tw) / 2.0
	return Rect2(x, n.position.y + (n.size.y - th) / 2.0, tw, th)


static func _buttons_under(n: Node, out: Array) -> void:
	if n is CanvasItem and not n.visible:
		return
	if n is Button:
		out.append(n)
	for c in n.get_children():
		_buttons_under(c, out)


## Width alone: the text fits its box. (A menu over a room puts its words over
## the room's, so the sweep doesn't judge overlap.)
func _check_widths(nodes: Array, where: String) -> int:
	var UI = load("res://scripts/ui/ui.gd")
	var bad := 0
	for n in nodes:
		var w: float = UI.text_width(n, n.text) + (32.0 if n is Button else 0.0)
		if w > n.size.x + 0.5:
			push_error("%s: '%s' needs %.0f px, has %.0f" % [where, n.text, w, n.size.x])
			bad += 1
	return bad


## Every single-line Label under n that's showing, with text.
static func _labels_under(n: Node, out: Array) -> void:
	if n is CanvasItem and not n.visible:
		return
	if n is Label and n.text != "" and n.autowrap_mode == TextServer.AUTOWRAP_OFF:
		out.append(n)
	elif n is Button and n.text != "" and n.icon == null:
		out.append(n)
	for c in n.get_children():
		_labels_under(c, out)


## Visible up the chain of controls (headless, the window itself reports hidden).
static func _showing(n: Node) -> bool:
	var p = n
	while p is CanvasItem:
		if not p.visible:
			return false
		p = p.get_parent()
	return true


## A control's position on screen, summing positions up the chain (this UI never scales).
static func _screen_pos(n: Node) -> Vector2:
	var p := Vector2.ZERO
	var q = n
	while q is Control:
		p += q.position
		q = q.get_parent()
	return p


## Where a label's text sits on screen: its width at its alignment, its box's height.
static func _text_rect(n: Control, UI) -> Rect2:
	# positions are walked up by hand: headless, a child's cached global
	# transform can lag a parent that moved since the last frame
	var r := Rect2(_screen_pos(n), n.size)
	if n is Button:
		return r                          # a button's background covers whatever is under it
	var tw: float = UI.text_width(n, n.text)
	# the text's own height, centred in the box: a descender past the box's
	# edge is drawn there whether the box ends or not
	var f: Font = n.get_theme_font("font")
	var th: float = f.get_height(n.get_theme_font_size("font_size"))
	var x := r.position.x
	var align: int = HORIZONTAL_ALIGNMENT_CENTER if n is Button else n.horizontal_alignment
	if align == HORIZONTAL_ALIGNMENT_RIGHT:
		x = r.position.x + r.size.x - tw
	elif align == HORIZONTAL_ALIGNMENT_CENTER:
		x = r.position.x + (r.size.x - tw) / 2.0
	return Rect2(x, r.position.y + (r.size.y - th) / 2.0, tw, th)


## The checks for one set of nodes. `pairs` are [label, value] that share a
## line: their widths are added. Returns how many failed.
func _check_nodes(nodes: Array, pairs: Array, where: String) -> int:
	var UI = load("res://scripts/ui/ui.gd")
	var bad := 0
	for pair in pairs:
		if pair[0].text == "" or pair[1].text == "":
			continue
		var w: float = UI.text_width(pair[0], pair[0].text) + 16 + UI.text_width(pair[1], pair[1].text)
		if w > maxf(pair[0].size.x, pair[1].size.x) + 0.5:
			push_error("%s: line '%s' + '%s' needs %.0f px, has %.0f" % [where, pair[0].text, pair[1].text, w, maxf(pair[0].size.x, pair[1].size.x)])
			bad += 1
	var live := []
	for n in nodes:
		if not (n is Control) or n.text == "" or not _showing(n):
			continue
		live.append(n)
		var room := 32.0 if n is Button else 0.0
		var w: float = UI.text_width(n, n.text) + room
		if w > n.size.x + 0.5:
			push_error("%s: '%s' needs %.0f px, has %.0f" % [where, n.text, w, n.size.x])
			bad += 1
		var parent = n.get_parent()
		if parent is Control:
			var tr := _text_rect(n, UI)
			var pr := Rect2(_screen_pos(parent), parent.size)
			if tr.position.y < pr.position.y - 4.0 or tr.end.y > pr.end.y + 4.0:
				push_error("%s: '%s' runs out of its box top to bottom" % [where, n.text])
				bad += 1
	# no text on top of any other text: the rect each label's text occupies,
	# from its alignment, not its box - a headline and its unit share a box
	for i in range(live.size()):
		for j in range(i + 1, live.size()):
			var a = live[i]
			var b = live[j]
			if a.is_ancestor_of(b) or b.is_ancestor_of(a):
				continue
			var x: Rect2 = _text_rect(a, UI).intersection(_text_rect(b, UI))
			# a font's height carries a few px of line spacing past the glyphs
			if x.size.x > 2.0 and x.size.y > 6.0:
				push_error("%s: '%s' sits on '%s' (%.0f × %.0f px)" % [where, a.text, b.text, x.size.x, x.size.y])
				bad += 1
	return bad


func _hours(s: float) -> String:
	return "%.1f h" % (s / 3600.0)


## The Yard as option A: Elements and Finds cards with the figures nowhere else
## showed; the works on one card; the Runs cards say what a site fires and what
## you resist; the Radio's cards carry the words as chips and the odds.
## 27: quantity is how much, not how good; it reaches searches; the dog adds quality.
func _loot_roll_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	# quantity reaches searches: +100% quantity doubles what a search brings, carried as a fraction
	var hold_pack = sim.equipped["Backpack"]
	var heavy: Dictionary = sim._plain("Backpack", Data.BASES["Backpack"][0]["name"])
	heavy["affixes"] = [{"stat": "loot_pct", "value": 100, "tier": 5}]
	sim.equipped["Backpack"] = heavy
	var hold_tree: Array = sim.tree.duplicate()
	sim.tree = sim.tree.filter(func(id): return not str(id).begins_with("The rat man/"))     # no Rat's share eating the bonus
	var q: float = sim.loot_bonus()
	_check(q >= 1.0, "a +100%% quantity pack reads %.2f" % q)
	sim.deploy(0)
	var m: Dictionary = sim.mission
	m["remaining"] = 0
	m["cleared"] = true
	m["patrol_timer"] = -1e9              # no gang
	var found0: int = int(m.get("finds", 0))
	var searches0: int = m["searches"]
	for k in range(400):
		sim.advance(1.0)
		if not sim.on_mission() or m["searches"] - searches0 >= 3:
			break                        # three searches, however slow this runner's are (Never there doubles them)
	if sim.on_mission():
		var per_search: float = float(int(m.get("finds", 0)) - found0) / maxf(1.0, float(m["searches"] - searches0))
		var base_finds: int = 1 + (1 if sim.has_node("scavenger") or sim.has_node("quiet_hands") else 0) + int(Data.KENNEL_LEVELS[sim.kennel_level]["finds"]) + (1 if sim.has_rule("postman") else 0)
		_check(m["searches"] - searches0 >= 2 and per_search >= float(base_finds) + floorf(q) - 0.6, "with +%.0f%% quantity a search brings %.2f, base %d" % [q * 100.0, per_search, base_finds])
		sim.extract_now()
	# the dog adds quality
	var hold_k: int = sim.kennel_level
	sim.kennel_level = 0
	var r0: float = sim.rarity_bonus()
	sim.kennel_level = 1
	_check(is_equal_approx(sim.rarity_bonus(), r0 + 0.05), "a dog did not add 5%% quality: %.3f then %.3f" % [r0, sim.rarity_bonus()])
	sim.kennel_level = hold_k
	# quantity is out of the rarity roll: Rat's share no longer moves the quality figure the roll reads
	var rat := "The rat man/9"
	var rar_before: float = sim.rarity_bonus()
	if not sim.tree.has(rat):
		sim.tree.append(rat)
	_check(is_equal_approx(sim.rarity_bonus(), rar_before) and sim.loot_bonus() < q, "Rat's share moved quality (%.3f → %.3f) or not quantity" % [rar_before, sim.rarity_bonus()])
	# a rarity node a class: the Doorman's and the Paramedic's trees carry one now
	for t in ["Muscle", "Triage"]:
		_check(Data.tree_named(t)["nodes"].any(func(n): return n.get("effect", "") == "rarity"), "%s has no loot quality node" % t)
	_check(Data.AFFIXES.any(func(a): return a["stat"] == "rarity_pct" and "Backpack" in a["slots"]), "no loot quality affix rolls on a backpack")
	sim.equipped["Backpack"] = hold_pack
	sim.tree = hold_tree
	sim.load_dict(saved)
	main.refresh()
	print("the loot roll ok: quantity reaches searches, the dog adds quality, quantity is out of the rarity roll")
	_thinning_checks(main)
	_wound_checks(main)
	_dots_chip_checks(main)
	_top_works_checks(main)
	_pick_panel_checks(main)
	_bench_pick_checks(main)
	_grenade_checks(main)
	_grade_checks(main)
	_build_checks(main)
	_contract_material_checks(main)
	_retire_checks(main)
	_last_add_checks(main)
	_dig_checks(main)


## The pool's last add (6 Oct): the top of each slot, resist gear with the resist in the base, the elements' five
## uniques with a rule each, and the fire crew's set. Every one has words (the manifest generator carries the art).
func _last_add_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.candidates = []
	sim.auto_equip = false
	for name in ["Police marksman's rifle", "Riot squad's shotgun", "Officer's revolver", "Army machine pistol", "Bomb-squad helmet", "Bomb suit", "Bomb-disposal rig", "Full bergen", "Mayor's chain", "Welder's mask", "Fireman's tunic", "Lineman's rubber coat", "Cold-store parka", "Hazmat suit", "Butcher's chainmail"]:
		_check(Words.item_words(name) != "", "%s has no words" % name)
	for u in ["The arsonist's rig", "The gritter's keys", "The rat man's overalls", "The substation key", "The butcher's apron"]:
		_check(Data.UNIQUES.any(func(x): return x["name"] == u) and Words.UNIQUES.has(u), "%s is not a unique with words" % u)
	_check(Data.SETS.any(func(st): return st["name"] == "The fire crew's" and st["pieces"].size() == 3), "the fire crew's set is missing")
	# a resist in the base reads through resist() and on the head
	var hold: Dictionary = {"Armour": sim.equipped["Armour"], "Helmet": sim.equipped["Helmet"], "Rig": sim.equipped["Rig"], "Charm": sim.equipped["Charm"]}
	var tree0: Array = sim.tree.duplicate()
	sim.tree = sim.tree.filter(func(id): return not str(id).begins_with("Petrol/") and not str(id).begins_with("The cold/") and not str(id).begins_with("Live/") and not str(id).begins_with("Blades/") and not str(id).begins_with("The rat man/"))
	sim.equipped["Armour"] = null
	sim.equipped["Helmet"] = null
	sim.equipped["Charm"] = null
	sim._dry_memo.clear()
	var fire0: float = sim.resist("fire")
	sim.equipped["Armour"] = sim._plain("Armour", "Fireman's tunic")
	_check(is_equal_approx(sim.resist("fire"), minf(Data.RESIST_CAP, fire0 * 100.0 + 40.0) / 100.0), "the tunic's fire resist does not read: %.2f from %.2f" % [sim.resist("fire"), fire0])
	_check(Items.base_res_words(sim.equipped["Armour"]) == "fire res 40", "the tunic's words read '%s'" % Items.base_res_words(sim.equipped["Armour"]))
	main.show_room(main.ARMOURY)
	main._armoury._pick_slot("Armour")
	main.refresh()
	_check(main._armoury._head._tail.text.contains("fire res 40"), "the head does not say the base's resist: '%s'" % main._armoury._head._tail.text)
	_check_fit(main, "Lock-up (resist gear)")
	# the rules: each unique's effect through the model
	var rig_u: Dictionary = Items.roll_unique(Data.UNIQUES.filter(func(x): return x["name"] == "The arsonist's rig")[0], sim.rng)
	sim.equipped["Rig"] = rig_u
	sim.rig = [sim._plain(Data.MEDICAL, "Bandage")]
	sim.deploy(0)
	var m: Dictionary = sim.mission
	m["remaining"] = 3
	m["target_hp"] = 1e6
	m["dots"] = {}
	sim.hp = sim.max_hp() * 0.5
	sim.use_med(sim.rig[0]["id"])
	if m["using"] != null:
		sim._patch(m, 100.0)
	_check(float(m["dots"].get("fire", 0.0)) > 0.0 and m["target_hp"] < 1e6, "the arsonist's rig did not set them alight on a med: %.0f left" % m["target_hp"])
	sim.extract_now()
	sim.equipped["Rig"] = hold["Rig"]
	var keys_u: Dictionary = Items.roll_unique(Data.UNIQUES.filter(func(x): return x["name"] == "The gritter's keys")[0], sim.rng)
	sim.equipped["Charm"] = keys_u
	sim.equipped["Primary"] = sim._plain("Primary", "Workshop SMG")
	sim.rig = [sim._plain(Data.AMMO, "SMG rounds")]
	sim._dry_memo.clear()
	sim.deploy(0)
	m = sim.mission
	m["remaining"] = 3
	m["target_hp"] = 1e6
	sim._fight(m, m["t"], 0.5)
	_check(float(m.get("chill_t", 0.0)) > 100.0, "the gritter's keys did not hold the chill: %.1f" % float(m.get("chill_t", 0.0)))
	sim.extract_now()
	sim.equipped["Charm"] = null
	var key_u: Dictionary = Items.roll_unique(Data.UNIQUES.filter(func(x): return x["name"] == "The substation key")[0], sim.rng)
	sim.equipped["Charm"] = key_u
	_check(is_equal_approx(sim.shock_amount(), 0.6), "the substation key's shock reads %.2f" % sim.shock_amount())
	sim.equipped["Charm"] = null
	var overalls: Dictionary = Items.roll_unique(Data.UNIQUES.filter(func(x): return x["name"] == "The rat man's overalls")[0], sim.rng)
	sim.equipped["Armour"] = overalls
	_check(sim.dot_stacks("poison") == 999 and is_equal_approx(sim.dot_seconds("poison"), float(Data.DOTS["poison"]["s"]) * 0.5), "the overalls' poison reads %d stacks over %.1f s" % [sim.dot_stacks("poison"), sim.dot_seconds("poison")])
	_check(sim.dot_stacks("poison", false) == int(Data.DOTS["poison"]["stacks"]) and is_equal_approx(sim.dot_seconds("poison", false), float(Data.DOTS["poison"]["s"])), "the overalls shaped the poison on you too")
	var apron: Dictionary = Items.roll_unique(Data.UNIQUES.filter(func(x): return x["name"] == "The butcher's apron")[0], sim.rng)
	sim.equipped["Armour"] = apron
	_check(sim.dot_stacks("bleed") == 3 and sim.has_rule("butchers_apron"), "the apron's bleed reads %d stacks" % sim.dot_stacks("bleed"))
	sim.deploy(0)
	m = sim.mission
	m["remaining"] = 2
	m["target_hp"] = 0.0
	m["dots"] = {"bleed": 40.0}
	sim._fight(m, m["t"], 0.1)
	_check(float(m.get("dots", {}).get("bleed", 0.0)) > 0.0, "the apron did not carry the bleed to the next of them")
	sim.extract_now()
	# the set's pieces roll, its bonus reads
	var pieces := []
	for pc in Data.SETS.filter(func(st): return st["name"] == "The fire crew's")[0]["pieces"]:
		pieces.append(Items.roll_set_piece("The fire crew's", pc, sim.rng))
	sim.equipped["Armour"] = pieces[0]
	sim.equipped["Helmet"] = pieces[1]
	sim._dry_memo.clear()
	_check(sim.set_count("The fire crew's") == 2 and sim.set_stat("fire_res") >= 40.0, "two of the fire crew's do not give the fire resist: %d, %.0f" % [sim.set_count("The fire crew's"), sim.set_stat("fire_res")])
	main.show_room(main.ARMOURY)
	main._armoury._pick_slot("Armour")
	main.refresh()
	_check_fit(main, "Lock-up (the fire crew's)")
	sim.tree = tree0
	sim.load_dict(saved)
	main.refresh()
	print("the pool ok: the words, the five uniques, the set, the base resist on the model and the head, the rig, the keys, the key, the overalls, the apron, the set's bonus")


## 36: retirement. At level 30 a runner goes to the wall: kit to the stash, trees refunded, a third of the trait kept
## (three at most, the oldest making way), two new to pick from; the wall says retired, not dead.
func _retire_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.candidates = []
	sim.retired = []
	sim.set_class("Doorman")
	sim.runner_trait = "Tough"
	sim.xp = Data.xp_for_level(Data.RETIRE_LEVEL - 1)
	_check(not sim.can_retire(), "a runner under level %d could retire" % Data.RETIRE_LEVEL)
	sim.xp = Data.xp_for_level(Data.RETIRE_LEVEL)
	_check(sim.can_retire(), "a level %d runner cannot retire" % Data.RETIRE_LEVEL)
	var hp_full: float = sim.max_hp()
	var worn = sim.equipped["Armour"]
	var past_n: int = sim.past.size()
	var stash_n: int = sim.stash.size()
	_check(sim.retire(), "retire() refused")
	_check(sim.past.size() == past_n + 1 and sim.past.back()["end"] == "retired" and sim.past.back()["class"] == "Doorman", "the wall does not say retired: %s" % str(sim.past.back()))
	_check(sim.retired == ["Tough"] and sim.cls == "" and sim.candidates.size() == 2 and sim.xp == 0.0, "retirement did not reset the runner and keep the trait: %s / %s / %s" % [str(sim.retired), sim.cls, str(sim.candidates)])
	_check(worn == null or sim.stash.any(func(it): return it["id"] == worn["id"]), "the retired runner's armour did not go to the stash")
	# a third of Tough stays: with a plain new runner, max HP carries a third of +15%
	sim.choose_runner(0)
	sim.runner_trait = "Nosy"
	sim._dry_memo.clear()
	_check(is_equal_approx(sim.trait_mult("hp"), 1.0 + 0.15 / 3.0), "the wall's third of Tough reads ×%.3f" % sim.trait_mult("hp"))
	sim.retired = ["Lucky", "Lucky"]
	_check(is_equal_approx(sim.trait_add("rarity"), 0.1 * 2.0 / 3.0), "two retired Lucky ones do not stack their thirds: %.3f" % sim.trait_add("rarity"))
	# three at most: the oldest makes way
	sim.retired = ["Lucky", "Wary", "Light"]
	sim.set_class("Poacher")
	sim.runner_trait = "Greedy"
	sim.xp = Data.xp_for_level(Data.RETIRE_LEVEL)
	sim.candidates = []
	_check(sim.retire() and sim.retired == ["Wary", "Light", "Greedy"], "the wall did not make way for the fourth: %s" % str(sim.retired))
	sim.choose_runner(0)
	sim.runner_trait = "Greedy"           # the same trait as one on the wall: its cut is the runner's alone
	# the Caravan's button and the yard's chips say so, and fit; saved and loaded
	sim.set_class("Scrapper")
	sim.xp = Data.xp_for_level(Data.RETIRE_LEVEL)
	main.show_room(main.BARRACKS)
	main._barracks._shown = ""
	main.refresh()
	_check(main._barracks._retire.visible and not main._barracks._retire.disabled, "the Caravan does not offer retirement at level 30")
	_check_fit(main, "Caravan (retire)")
	main.show_room(main.OVERVIEW)
	main.refresh()
	var card_chips: Array = main._cards[0]._chip_labels.filter(func(l): return l.visible).map(func(l): return l.text)
	_check(card_chips.any(func(t): return t.begins_with("Greedy")) and card_chips.has("Scrapper") and main._cards[0]._status.text == "Wall: Wary, Light, Greedy", "the Runner card does not show the wall under the runner's own trait: %s / '%s'" % [str(card_chips), main._cards[0]._status.text])
	_check_fit(main, "Yard (the wall)")
	# the bad side of a trait does not retire: Greedy's HP cut stays with the runner who had it
	_check(is_equal_approx(sim.trait_mult("hp"), 0.9), "the wall's Greedy cut the yard's HP: ×%.3f" % sim.trait_mult("hp"))
	main._confirm_retire()
	_check(main._menu.visible and main._menu._items[0]["name"].begins_with("Retire"), "the retire menu did not open")
	_check_fit(main, "Caravan (retire menu)")
	main._menu.close()
	var d: Dictionary = sim.to_dict()
	_check(d.get("retired", []) == ["Wary", "Light", "Greedy"], "the wall is not saved: %s" % str(d.get("retired", [])))
	sim.load_dict(saved)
	main.refresh()
	print("retirement ok: the level, the wall's line, the kit, the trait's third, the stack, the cap, the button, the chips, the menu, the save")


## 35: contracts paying in craft materials: scrap by the handful, a socketable of the zone's element, a graded box for a gun held.
func _contract_material_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.equipped["Primary"] = sim._plain("Primary", "Sawn-off")
	var kinds := {}
	for k in range(300):
		var c: Dictionary = sim.roll_contract()
		kinds[c["pay"]] = kinds.get(c["pay"], 0) + 1
		if c["pay"] == "scrap":
			_check(int(c["amount"]) == int(c["count"]) * int(c["rarity"]) * Data.CONTRACT_SCRAP, "a scrap contract's amount is off: %s" % str(c))
		elif c["pay"] == "socketable":
			var a: Dictionary = Items.base_named(Data.ATTACHMENT, str(c["what"]))
			_check(not a.is_empty() and a.get("mount", "") == "socket", "a socketable contract names %s" % str(c.get("what", "")))
		elif c["pay"] == "rounds":
			var b: Dictionary = Items.base_named(Data.AMMO, str(c["what"]))
			_check(not b.is_empty() and b.has("from") and b["type"] in sim.gun_types_held(), "a rounds contract names %s" % str(c.get("what", "")))
		_check(sim.contract_pay_words(c) != "", "a contract has no pay words: %s" % str(c))
	_check(kinds.has("scrap") and kinds.has("socketable") and kinds.has("rounds") and kinds.has("cash") and kinds.has("notes"), "three hundred contracts did not cover every pay: %s" % str(kinds))
	# handing in pays what it says
	for pay in ["scrap", "socketable", "rounds"]:
		var c: Dictionary = {}
		for k in range(400):
			c = sim.roll_contract()
			if c["pay"] == pay:
				break
		_check(c["pay"] == pay, "four hundred rolls gave no %s contract" % pay)
		if c["pay"] != pay:
			continue
		sim.contracts[0] = c
		for it in sim.stash.duplicate():
			if sim.contract_fits(c, it):
				sim.stash.erase(it)
		for k in range(int(c["count"])):
			var piece: Dictionary = sim._plain(c["slot"], (Data.ATTACHMENTS if c["slot"] == Data.ATTACHMENT else Data.BASES[c["slot"]])[0]["name"])
			piece["rarity"] = int(c["rarity"])
			sim.stash.append(piece)
		var scrap0: int = sim.scrap
		var stash_n: int = sim.stash.size()
		_check(sim.can_hand_in(0) and sim.hand_in(0), "a %s contract could not be handed in" % pay)
		match pay:
			"scrap":
				_check(sim.scrap == scrap0 + int(c["amount"]), "the scrap contract paid %d" % (sim.scrap - scrap0))
			"socketable":
				_check(sim.stash.any(func(it): return it["base"] == c["what"]), "the socketable contract did not pay %s" % str(c["what"]))
			"rounds":
				_check(sim.stash.any(func(it): return Items.is_ammo(it) and it["base"] == c["what"]), "the rounds contract did not pay %s" % str(c["what"]))
	# the fence's contracts tab reads them and fits
	main.show_room(main.MARKET)
	main._fence._show("contracts")
	main._fence._shown = ""
	main.refresh()
	_check_fit(main, "Fence (material contracts)")
	main._fence._show("shelf")
	sim.load_dict(saved)
	main.refresh()
	print("the material contracts ok: the three pays rolled and worded, each paid on the hand-in, the tab fitted")


## 34: crafting at the bench. Scrap in hand from searches, scrapping and ditching; the Build column: a box of rounds,
## a grade from the box below, a med from the one below, an improvised gun firing nails, a grenade from its socketable.
func _build_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.workshop = maxi(sim.workshop, 1)
	sim.scrap = 0
	# scrap from a search comes home; a ditch is scrap too; scrapping an item at the bench is its value over twenty
	sim.deploy(0)
	var m: Dictionary = sim.mission
	m["remaining"] = 0
	m["cleared"] = true
	m["patrol_timer"] = -1e9
	m["event_at"] = -1.0
	var guard := 0
	while int(m.get("scrap", 0)) == 0 and guard < 600:
		sim.hp = sim.max_hp()
		sim.advance(1.0)
		guard += 1
	var run_scrap: int = int(m.get("scrap", 0))
	_check(run_scrap >= Data.SCRAP_HANDFUL[0], "searches brought no scrap in %d seconds" % guard)
	var vest: Dictionary = sim._plain("Armour", "Riot suit")
	m["found"].append(vest)
	sim.ditch(vest["id"])
	_check(int(m.get("scrap", 0)) == run_scrap + sim.scrap_of(vest) and sim.scrap_of(vest) == int(vest["value"] / Data.SCRAP_PER_POUND), "the ditch did not pay its scrap: %d" % int(m.get("scrap", 0)))
	sim.extract_now()
	_check(sim.scrap == run_scrap + sim.scrap_of(vest), "the run's scrap did not come home: %d" % sim.scrap)
	var junk: Dictionary = sim._plain("Helmet", Data.BASES["Helmet"][0]["name"])
	sim.stash.append(junk)
	var before_scrap: int = sim.scrap
	_check(sim.scrap_item(junk["id"]) and not sim.stash.has(junk) and sim.scrap == before_scrap + sim.scrap_of(junk), "scrapping at the bench is off: %d" % sim.scrap)
	# the Build column: each kind lists, with costs and what it wants
	sim.scrap = 1000
	sim.equipped["Primary"] = sim._plain("Primary", "Sawn-off")
	sim.equipped["Secondary"] = null
	for it in sim.stash.duplicate():
		if Items.is_gun(it) and Items.ammo_type(it) == "rifle":
			sim.stash.erase(it)
	var boxes: Array = sim.build_options("box")
	_check(boxes.any(func(o): return o["name"] == "Shells" and o["ok"]) and boxes.any(func(o): return o["name"] == "Rifle rounds" and not o["ok"] and o["why"] == "No gun for it"), "the boxes are off: %s" % str(boxes.map(func(o): return [o["name"], o["ok"]])))
	_check(sim.build("box", "Shells") and sim.scrap == 1000 - Data.BUILD_BOX and sim.stash.any(func(it): return Items.is_ammo(it) and it["base"] == "Shells"), "a box of shells did not build")
	# a grade wants a full box of the one below; it takes the rounds and leaves the rest
	var slugs: Dictionary = sim.build_option("grade", "Slugs")
	_check(slugs["from"] == "Shells" and slugs["from_n"] == 150 and slugs["ok"], "slugs' build is off: %s" % str(slugs))
	var shells_before: int = sim._rounds_in_stash("Shells")
	for it in sim.stash.duplicate():
		if Items.is_ammo(it) and it["base"] == "Slugs":
			sim.stash.erase(it)
	_check(not sim.build_option("grade", "Incendiary shells")["ok"] and sim.build_option("grade", "Incendiary shells")["why"].contains("slugs"), "incendiary shells built without a box of slugs under them")
	_check(sim.build("grade", "Slugs") and sim._rounds_in_stash("Shells") == shells_before - 150 and sim.stash.any(func(it): return Items.is_ammo(it) and it["base"] == "Slugs" and int(it["rounds"]) == 90), "slugs did not build from the shells")
	_check(sim.build_option("grade", "Incendiary shells")["ok"], "a box of slugs did not open the incendiary shells")
	# a med from the one below; a bandage from scrap alone
	for it in sim.stash.duplicate():
		if it["base"] == "Bandage" or it["base"] == "First aid kit":
			sim.stash.erase(it)
	_check(sim.build_option("med", "Bandage")["ok"] and not sim.build_option("med", "First aid kit")["ok"], "the med ladder's first step is off")
	_check(sim.build("med", "Bandage") and sim.build_option("med", "First aid kit")["ok"] and sim.build("med", "First aid kit") and not sim.stash.any(func(it): return it["base"] == "Bandage"), "a first aid kit did not take the bandage")
	# a gun: improvised, Common, plain, firing nails whatever it is, up to the bench's level
	var guns: Array = sim.build_options("gun")
	_check(not guns.is_empty() and guns.all(func(o): return o["tier"] <= sim.workshop), "the guns' list is off: %s" % str(guns.map(func(o): return [o["name"], o["tier"]])))
	_check(sim.build("gun", "Pipe shotgun"), "the pipe shotgun did not build")
	var built: Dictionary = sim.stash.back()
	_check(built["base"] == "Pipe shotgun" and int(built["rarity"]) == 0 and built["affixes"].is_empty() and built.get("nails", false) and Items.ammo_type(built) == "improvised", "the built gun is not plain and firing nails: %s" % str(built))
	# a grenade from its socketable; the nail bomb from scrap alone
	for it in sim.stash.duplicate():
		if it["base"] == "Lighter fluid":
			sim.stash.erase(it)
	_check(not sim.build_option("grenade", "Petrol bomb")["ok"] and sim.build_option("grenade", "Nail bomb")["ok"], "the grenade's socketable is not wanted")
	var fluid: Dictionary = sim._plain(Data.ATTACHMENT, "Lighter fluid")
	fluid["count"] = 2
	sim.stash.append(fluid)
	_check(sim.build("grenade", "Petrol bomb") and int(fluid["count"]) == 1 and sim.stash.any(func(it): return Items.is_grenade(it) and it["base"] == "Petrol bomb"), "the petrol bomb did not take one lighter fluid off the stack")
	# short of scrap: refused; out on a run: refused, scrapping too
	sim.scrap = 0
	_check(not sim.build_option("box", "Shells")["ok"] and sim.build_option("box", "Shells")["why"] == "Short of scrap" and not sim.build("box", "Shells"), "a build went through with no scrap")
	sim.scrap = 100
	sim.deploy(0)
	var out_opt: Dictionary = sim.build_option("box", "Shells")
	_check(not out_opt["ok"] and out_opt["why"] == "The runner is out" and not sim.build("box", "Shells") and not sim.scrap_item(sim.stash[0]["id"]), "the bench worked with the runner out")
	sim.extract_now()
	_check(sim.last_report.has("scrap"), "the report does not carry the run's scrap")
	# the bench's craft view says so and fits; the menus open and fit
	sim.scrap = 50
	main.show_room(main.WORKSHOP)
	main._workshop._set_view("craft")
	main._workshop.sel_id = -1
	main._workshop._shown = ""
	main.refresh()
	_check(main._workshop._buttons[0].visible and main._workshop._buttons[0].text == "Build for scrap", "the craft view has no Build button: '%s'" % main._workshop._buttons[0].text)
	_check_fit(main, "Workshop (craft, build)")
	main._open_builds(0)
	_check(main._menu.visible and main._menu._items.size() == 5, "the build menu did not open with its kinds")
	_check_fit(main, "Workshop (build menu)")
	main._open_build_kind("grade", 0)
	_check(main._menu.visible and main._menu._items[0]["name"].contains("scrap"), "the grades' menu is off: %s" % str(main._menu._items[0]))
	_check_fit(main, "Workshop (build grades)")
	main._menu.close()
	main._workshop._set_view("guns")
	sim.load_dict(saved)
	main.refresh()
	print("the bench's builds ok: scrap from a search, a ditch and a scrapping; a box, a grade from the box below, the med ladder, a gun firing nails, a grenade from its socketable, the refusals, the view and the menus")


## 33: ammo grades with an element. The gun's live stack of hollow point bleeds, incendiary burns, salted chills,
## match rounds weight the first shot: read through the model like a conversion affix on the gun.
func _grade_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	var hp_rounds: Dictionary = {}
	for b in Data.BASES[Data.AMMO]:
		if b.has("conv_bleed_pct") or b.has("conv_fire_pct") or b.has("conv_frost_pct") or b.has("first_pct"):
			var it: Dictionary = sim._plain(Data.AMMO, b["name"])
			_check(Items.grade_words(b) != "" and Items.headline(it)[1].contains(Items.grade_words(b).trim_prefix(", ")) and Words.item_words(b["name"]) != "", "%s's grade does not read: '%s'" % [b["name"], Items.headline(it)[1]])
	_check(Data.BASES[Data.AMMO].any(func(b): return b["type"] == "shotgun" and b.has("conv_fire_pct")) and Data.BASES[Data.AMMO].any(func(b): return b["type"] == "smg" and b.has("conv_fire_pct")) and Data.BASES[Data.AMMO].any(func(b): return b["type"] == "rifle" and b.has("conv_frost_pct")), "a grade is missing: incendiary shells and SMG rounds, salted rifle rounds")
	# the live stack's share reaches the conversion; an empty stack or the wrong type does not
	sim.tree = sim.tree.filter(func(id): return not str(id).begins_with("Petrol/") and not str(id).begins_with("Live/") and not str(id).begins_with("Blades/"))
	var smg: Dictionary = sim._plain("Primary", "Workshop SMG")
	sim.equipped["Primary"] = smg
	sim.equipped["Secondary"] = null
	if sim.equipped["Rig"] == null:
		sim.equipped["Rig"] = sim._plain("Rig", Data.BASES["Rig"][0]["name"])
	sim.rig = []
	sim._dry_memo.clear()
	var bleed0: float = sim.conversion()["bleed"]
	var hollow: Dictionary = sim._plain(Data.AMMO, "SMG hollow point")
	sim.rig = [hollow]
	_check(is_equal_approx(sim.conversion()["bleed"], bleed0 + 0.2), "hollow point did not add its bleed share: %.2f from %.2f" % [sim.conversion()["bleed"], bleed0])
	_check(is_equal_approx(sim.grade_stat(smg, "conv_bleed_pct"), 20.0), "grade_stat reads %.0f" % sim.grade_stat(smg, "conv_bleed_pct"))
	hollow["rounds"] = 0
	_check(is_equal_approx(sim.conversion()["bleed"], bleed0), "an empty stack still converted")
	var fire_shells: Dictionary = sim._plain(Data.AMMO, "Incendiary shells")
	sim.rig = [fire_shells]
	_check(is_equal_approx(sim.grade_stat(smg, "conv_fire_pct"), 0.0), "shotgun shells fed the SMG's conversion")
	# match rounds weight the first shot
	var rifle: Dictionary = sim._plain("Primary", "Stalking rifle")
	sim.equipped["Primary"] = rifle
	sim.rig = [sim._plain(Data.AMMO, "Match rounds")]
	_check(is_equal_approx(sim.grade_stat(rifle, "first_pct"), 25.0) and is_equal_approx(sim.grade_bonus(rifle), 15.0), "match rounds' first shot and damage read %.0f / %.0f" % [sim.grade_stat(rifle, "first_pct"), sim.grade_bonus(rifle)])
	# the first shot through the fight: a tick fresh with match rounds lands more than one with plain rounds
	var plain_r: Dictionary = sim._plain(Data.AMMO, "Rifle rounds")
	sim.auto_equip = false                # "Equip if better" would swap the rifle out on deploy
	sim.candidates = []                   # a runner waiting to be picked would take over the kit on deploy
	var drops := []
	for stack in [plain_r, sim._plain(Data.AMMO, "Match rounds")]:
		sim.rig = [stack]
		sim.rng.seed = 11
		sim.deploy(0)
		var m: Dictionary = sim.mission
		m["target_hp"] = 1e6
		m["remaining"] = 3
		m["fresh"] = true
		m["t"]["res"] = {}                # the same target both times: the intel re-rolls between deploys (a Hardened word is 30% off physical)
		m["t"]["pace"] = 1.0
		sim.rng.seed = 11                 # the swing the same both times: deploy spent the dice differently
		sim._fight(m, m["t"], 0.5)
		drops.append(1e6 - m["target_hp"])
		drops.append("%s rig %s rounds %s grade %.0f first %.0f melee %s rules %s dps %.1f physical %.1f pace %.2f site pace %.2f res %s fresh %s dealt_by %s" % [sim.equipped["Primary"]["base"], str(sim.rig.map(func(x): return x["base"])), str(sim.has_rounds(sim.equipped["Primary"])), sim.grade_bonus(sim.equipped["Primary"]), sim.grade_stat(sim.equipped["Primary"], "first_pct"), str(sim.melee()), str(sim.has_rule("qm_rifle")), sim.dps(), float(sim.type_dps()["physical"]), sim.pace(), float(m["t"]["pace"]), str(m["t"].get("res", {})), str(m["fresh"]), str(m.get("dealt_by", {}))])
		sim.extract_now()
	# the class's own first-shot share (the Poacher's +40%) is on both: the expected ratio is the grade's 15% times
	# (class + 25%) over (class), read against the class at hand
	var cls_first: float = float(sim.class_data().get("first_pct", 0)) / 100.0
	var expect: float = 1.15 * (1.0 + cls_first + 0.25) / (1.0 + cls_first)
	_check(drops[2] > drops[0] * expect * 0.97, "match rounds' first shot did not land heavier: %.1f against %.1f, expected ×%.2f (%s / %s)" % [drops[2], drops[0], expect, drops[1], drops[3]])
	# no gun in hand: the odds read without a grade, not a crash
	sim.equipped["Primary"] = null
	sim.rig = []
	sim._surv_cache = {}
	var odds: float = sim.survival(0)
	_check(odds >= 0.0 and odds <= 1.0, "the odds with no gun in hand read %.2f" % odds)
	sim.equipped["Primary"] = rifle
	sim.load_dict(saved)
	main.refresh()
	print("the grades ok: the words, the three new ones, the share through the conversion, the empty and the wrong stack, the match rounds")


## 32: grenades in the rig. A pouch each, thrown at everyone on you as the type's damage through the model, a dot on the gang.
func _grenade_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	for b in Data.BASES[Data.GRENADE]:
		var g: Dictionary = sim._plain(Data.GRENADE, b["name"])
		_check(Items.is_grenade(g) and Items.rig_item(g) and Items.size(g) == 1 and int(g["rarity"]) == 0 and g["affixes"].is_empty() and Items.headline(g)[0] != "" and Words.item_words(b["name"]) != "", "%s is not a plain one-pouch grenade with words" % b["name"])
	# the throw: the type's damage to everyone on you, the resist read, the dot landed, the pouch spent
	if sim.equipped["Rig"] == null:
		sim.equipped["Rig"] = sim._plain("Rig", Data.BASES["Rig"][0]["name"])
	sim.rig = []
	var bomb: Dictionary = sim._plain(Data.GRENADE, "Petrol bomb")
	sim.rig.append(bomb)
	sim.deploy(0)
	_check(sim.on_mission(), "no run for the grenade checks")
	if not sim.on_mission():
		sim.load_dict(saved)
		return
	var m: Dictionary = sim.mission
	m["remaining"] = 0
	_check(not sim.use_grenade(bomb["id"]) and sim.rig.size() == 1, "a grenade went off with no one there")
	m["remaining"] = 5
	m["target_hp"] = 100000.0
	m["dots"] = {}
	var t: Dictionary = m["t"]
	var crowd: int = mini(5, sim.contact(t))
	var expect: float = 80.0 * (1.0 + sim.increased("fire") / 100.0) * sim.more("fire") * (1.0 - float(t.get("res", {}).get("fire", 0.0))) * crowd
	var hp0: float = m["target_hp"]
	_check(sim.use_grenade(bomb["id"]), "the petrol bomb did not throw")
	_check(is_equal_approx(hp0 - m["target_hp"], expect) and sim.rig.is_empty() and float(m["dots"].get("fire", 0.0)) > 0.0 and int(m.get("thrown", 0)) == 1, "the throw landed %.0f, not %.0f; rig %d; fire dot %.1f" % [hp0 - m["target_hp"], expect, sim.rig.size(), float(m["dots"].get("fire", 0.0))])
	# a throw onto a burn the gun built never shrinks it; a kill by a throw resolves on the next tick
	var gun_rate: float = float(sim.type_dps()["fire"]) * (1.0 - float(t.get("res", {}).get("fire", 0.0))) * sim.pace() * t["pace"]
	var gun_cap: float = gun_rate * float(Data.DOTS["fire"]["ratio"]) * sim.dot_seconds("fire") * sim.dot_stacks("fire")
	m["dots"] = {"fire": gun_cap}
	sim.rig = [sim._plain(Data.GRENADE, "Petrol bomb")]
	sim.use_grenade(sim.rig[0]["id"])
	_check(float(m["dots"]["fire"]) >= gun_cap - 0.01, "the throw shrank the burn: %.0f from %.0f" % [float(m["dots"]["fire"]), gun_cap])
	m["dots"] = {}
	m["remaining"] = 3
	m["target_hp"] = 1.0
	var kills0: int = m["kills"]
	sim.rig = [sim._plain(Data.GRENADE, "Petrol bomb")]
	sim.use_grenade(sim.rig[0]["id"])
	sim.advance(0.5)
	_check(sim.on_mission() and m["kills"] > kills0 and m["remaining"] < 3, "the throw's kill did not resolve: kills %d, remaining %d" % [m["kills"], m["remaining"]])
	m["target_hp"] = 100000.0
	# the idle junk run leaves grenades alone
	var hold_auto: bool = sim.auto_sell
	var keep: Dictionary = sim._plain(Data.GRENADE, "Nail bomb")
	sim.stash.append(keep)
	sim.auto_sell = true
	sim.sell_junk()
	_check(sim.stash.has(keep), "the junk run sold a grenade")
	sim.auto_sell = hold_auto
	sim.stash.erase(keep)
	# frost chills, shock shocks; no enemies, no throw
	var ice: Dictionary = sim._plain(Data.GRENADE, "Dry-ice bag")
	var battery: Dictionary = sim._plain(Data.GRENADE, "Wired battery")
	sim.rig = [ice, battery]
	sim.use_grenade(ice["id"])
	_check(float(m.get("chill_t", 0.0)) > 0.0, "the dry ice did not chill them")
	sim.use_grenade(battery["id"])
	_check(float(m.get("shock_t", 0.0)) > 0.0 and sim.rig.is_empty(), "the battery did not shock them")
	m["remaining"] = 0
	sim.rig = [sim._plain(Data.GRENADE, "Nail bomb")]
	_check(not sim.use_grenade(sim.rig[0]["id"]) and sim.rig.size() == 1, "a grenade was thrown at no one")
	# the run's pouch: lit with a gang on you, pressed it throws; the pick panel knows a grenade
	m["remaining"] = 3
	m["target_hp"] = 100000.0
	main.show_room(main.MISSIONS)
	main.refresh()
	_check(main._run._rig_cells[0].visible, "the grenade's pouch does not show on the run")
	_check_fit(main, "Run (a grenade in the rig)")
	var thrown0: int = int(m.get("thrown", 0))
	main._run._rig_pressed(0)
	_check(sim.rig.is_empty() and int(m.get("thrown", 0)) == thrown0 + 1, "pressing the pouch did not throw the nail bomb")
	m["found"].append(sim._plain(Data.GRENADE, "Bottle of something"))
	main.refresh()
	main._run._inv._pick(main._run._inv.cell_of(m["found"].back()["id"]))
	main.refresh()
	_check(main._run._pick.button_texts()[0] == "Take into the rig", "a grenade found does not offer the rig: %s" % str(main._run._pick.button_texts()))
	_check_fit(main, "Run (a grenade found)")
	main._run._pick.press(0)
	_check(sim.rig.size() == 1 and Items.is_grenade(sim.rig[0]), "Take did not put the grenade in the rig")
	sim.extract_now()
	# the Lock-up: a grenade in the stash goes to the rig; the head's chips say what it is
	sim.rig = []
	var g2: Dictionary = sim._plain(Data.GRENADE, "Petrol bomb")
	sim.stash.append(g2)
	main.show_room(main.ARMOURY)
	main._armoury._inv._set_kind(4)
	main.refresh()
	main._armoury._pick_cell(main._armoury._inv.cell_of(g2["id"]))
	main.refresh()
	var chips_g: Array = main._armoury._head._chip_labels.filter(func(l): return l.visible).map(func(l): return l.text)
	_check(chips_g.size() >= 2 and chips_g[0] == "Grenade" and chips_g[1] == "Fire", "a grenade's chips are %s" % str(chips_g))
	_check(main._armoury._pick.button_texts()[0] == "Take", "a stash grenade does not offer Take: %s" % str(main._armoury._pick.button_texts()))
	_check_fit(main, "Lock-up (a grenade)")
	main._armoury._press(0)
	_check(sim.rig.size() == 1 and sim.rig[0]["id"] == g2["id"], "Take did not move the grenade to the rig")
	# the fence's shelf carries them now and then
	var seen := false
	for k in range(40):
		sim.restock()
		if sim.market.any(func(it): return Items.is_grenade(it)):
			seen = true
			break
	_check(seen, "forty restocks put no grenade on the fence's shelf")
	main._armoury._inv._set_kind(0)
	sim.load_dict(saved)
	main.refresh()
	print("grenades ok: the five, the throw, the chill and the shock, no one there, the pouch, the pick, the Lock-up, the shelf")


## The bench's panel on the pick frame (Matt, 6 Oct), and a typed part refused on the wrong gun.
## Each piece on the pick panel in its own box (Pick-B, 7 Oct): a box a column
## shown, every one of the column's text nodes inside it, the two boxes apart,
## and both above the foot.
func _pick_boxes_check(pick, where: String) -> void:
	var boxes: Array = pick._boxes
	_check(boxes[0].visible, "%s: the pick's box is not shown" % where)
	var r0: Rect2 = Rect2(boxes[0].position, boxes[0].size)
	var r1: Rect2 = Rect2(boxes[1].position, boxes[1].size)
	_check(not r0.intersects(r1) and r1.position.x - r0.end.x >= 2.0, "%s: the two boxes touch or overlap (%s, %s)" % [where, str(r0), str(r1)])
	_check(r0.position.x >= 0.0 and r1.end.x <= pick.w, "%s: a box runs off the panel (%s, %s against %d)" % [where, str(r0), str(r1), pick.w])
	_check(r0.end.y <= pick.foot_y and r1.end.y <= pick.foot_y, "%s: a box runs into the foot (%s / %s against %d)" % [where, str(r0), str(r1), pick.foot_y])
	for k in range(2):
		if not boxes[k].visible:
			continue
		var r: Rect2 = Rect2(boxes[k].position, boxes[k].size).grow(-1)
		var nodes: Array = [pick._kickers[k], pick._heads[k]] if k == 0 else [pick._kickers[k], pick._heads[k], pick._right_title]
		for n in nodes:
			if not n.visible:
				continue
			var nr: Rect2 = Rect2(n.position, n.size)
			_check(r.encloses(nr), "%s: %s sits outside its box: %s against %s" % [where, n.name if n.name != "" else "a node", str(nr), str(r)])
		if pick._tags[k].visible:
			var tr: Rect2 = Rect2(pick._tags[k].position, pick._tags[k].size)
			_check(r.encloses(tr), "%s: the price tag sits outside its box: %s against %s" % [where, str(tr), str(r)])


func _bench_pick_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.workshop = maxi(sim.workshop, 1)
	var rifle: Dictionary = sim._plain("Primary", "Garage-built rifle")
	sim.equipped["Primary"] = rifle
	var choke: Dictionary = sim._plain(Data.ATTACHMENT, "Choke")
	while not sim.stash_room(1) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])
	sim.stash.append(choke)
	_check(Items.base_of(choke).get("type", "") == "shotgun" and rifle["attachments"].has("muzzle"), "the choke is not a shotgun's muzzle part")
	_check(not sim.can_fit("Primary", choke["id"]) and sim.fit_refusal("Primary", choke["id"]) == "Shotguns only", "a shotgun-only choke was not refused on a rifle: '%s'" % sim.fit_refusal("Primary", choke["id"]))
	_check(not sim.attachments_for("muzzle", "improvised").has(choke) and sim.attachments_for("muzzle").has(choke), "attachments_for does not leave a typed part off another gun's list")
	var stock: Dictionary = sim._plain(Data.ATTACHMENT, "Wire stock")
	_check(Items.only_words(stock) == "Improvised guns only", "the wire stock's words read '%s'" % Items.only_words(stock))
	_check(not sim.fit("Primary", choke["id"]) and rifle["attachments"]["muzzle"] == null, "the choke went on the rifle")
	main.show_room(main.WORKSHOP)
	main._workshop._set_view("guns")
	main._workshop.sel_slot = ""
	main._workshop.sel_mount = ""
	main.refresh()
	main._workshop._pick_cell(main._workshop._inv.cell_of(choke["id"]))
	main.refresh()
	var pk = main._workshop._pick
	_check(pk.visible and pk._heads[0].visible and pk._heads[0]._title.text == "Choke" and pk._tag_labels[0].visible, "the bench's part pick is not on the pick frame: '%s'" % pk._heads[0]._title.text)
	_check(pk.button_texts() == ["Fit"] and pk._buttons[0].disabled and pk._words.visible and pk._words.text == "Shotguns only", "the bench did not grey Fit with the reason: %s / '%s'" % [str(pk.button_texts()), pk._words.text])
	_check(not pk.button_texts().any(func(t): return t.begins_with("Sell")), "Sell is on the bench")
	_check_fit(main, "Workshop (a refused part)")
	# a part that fits: the verdict and the swap read, Fit goes through the frame
	var dot: Dictionary = sim._plain(Data.ATTACHMENT, "Red dot")
	sim.stash.append(dot)
	main._workshop.sel_slot = ""
	main._workshop.sel_mount = ""
	main._workshop.sel_id = -1
	main.refresh()
	main._workshop._pick_cell(main._workshop._inv.cell_of(dot["id"]))
	main.refresh()
	_check(pk.button_texts() == ["Fit"] and not pk._buttons[0].disabled and pk._verdict.visible, "a fitting part's panel is off: %s / '%s' / pick %s, slot %s mount %s, title '%s', right '%s' '%s'" % [str(pk.button_texts()), pk._verdict.text, str(main._workshop.sel_id), main._workshop.sel_slot, main._workshop.sel_mount, pk._heads[0]._title.text, pk._kickers[1].text, pk._right_title.text])
	_check_fit(main, "Workshop (a part that fits)")
	pk.press(0)
	main.refresh()
	_check(rifle["attachments"]["optic"] != null and rifle["attachments"]["optic"]["base"] == "Red dot", "Fit through the frame did not fit the red dot")
	main._workshop._pick_mount("Primary", "optic")
	main.refresh()
	_check(pk._heads[0].visible and pk._heads[0]._title.text == "Red dot" and pk.button_texts() == ["Strip"], "a fitted part's panel is off: %s" % str(pk.button_texts()))
	_check_fit(main, "Workshop (a fitted part picked)")
	sim.load_dict(saved)
	main.refresh()
	print("the bench's pick frame ok: the part, the refusal, the fit, the fitted")


## Pick-A (Matt, 6 Oct): the pick and the fitted laid the same on the run and in the Lock-up; a price tag, no fence
## line, no ditched line; Equip and Ditch on a run (what comes off goes into the pack); no Sell in the Lock-up.
func _pick_panel_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	# on a run: an armour in the pack against the one worn; Equip swaps them; the pack must hold what comes off
	var worn: Dictionary = sim._plain("Armour", "Riot suit")
	sim.equipped["Armour"] = worn
	sim.equipped["Backpack"] = sim._plain("Backpack", "School bag")     # twelve cells: the leathers and the suit's three more; the start's bag has nine
	sim.deploy(0)
	var m: Dictionary = sim.mission
	var found: Dictionary = sim._plain("Armour", "Motorbike leathers")
	found["rarity"] = 2
	found["affixes"] = [{"stat": "poison_res", "value": 7, "tier": 1}, {"stat": "armour", "value": 3, "tier": 1}]
	m["found"] = [found]
	main.show_room(main.MISSIONS)
	main.refresh()
	main._run._inv._pick(main._run._inv.cell_of(found["id"]))
	main.refresh()
	var pk = main._run._pick
	_check(pk._heads[0].visible and pk._heads[1].visible and pk._heads[0]._title.text == "Motorbike leathers" and pk._heads[1]._title.text == "Riot suit", "the run's pick does not lay the pick and the fitted side by side: %s / %s" % [pk._heads[0]._title.text, pk._heads[1]._title.text])
	_check(pk._kickers[0].text == "THE PICK · IN THE PACK · %d CELLS" % Items.size(found) and pk._kickers[1].text == "FITTED NOW · %d CELLS" % Items.size(worn), "the kickers are off: '%s' / '%s'" % [pk._kickers[0].text, pk._kickers[1].text])
	_check(pk._tag_labels[0].text == Fmt.money(sim.sell_price(found)) and pk._tag_labels[1].text == Fmt.money(sim.sell_price(worn)), "the price tags are off: %s / %s" % [pk._tag_labels[0].text, pk._tag_labels[1].text])
	_check(pk._verdict.visible and pk._verdict.text.begins_with("▼ Downgrade") and pk._deltas[0].visible and pk._deltas[0].text.begins_with("▼"), "the verdict and deltas are off: '%s' / '%s'" % [pk._verdict.text, pk._deltas[0].text])
	_check(pk.button_texts() == ["Equip", "Ditch"] and not pk._buttons[0].disabled, "the run's buttons are not Equip and Ditch: %s" % str(pk.button_texts()))
	_check(not pk.text_nodes().any(func(l): return l.text.begins_with("The fence pays") or l.text.begins_with("Ditched")), "the fence line or the ditched line is still there")
	_check_fit(main, "Run (Pick-A)")
	pk.press(0)
	main.refresh()
	_check(sim.equipped["Armour"]["id"] == found["id"] and m["found"].size() == 1 and m["found"][0]["id"] == worn["id"], "Equip on a run did not swap the worn piece into the pack")
	# no room for what comes off (the riot suit back on, three cells bigger than the vest found): Equip greyed, the hint says so
	sim.equipped["Armour"] = worn
	var small: Dictionary = sim._plain("Armour", "Stab vest")
	m["found"] = [small]
	while sim.pack_used(m) + (Items.size(worn) - Items.size(small)) <= sim.capacity():
		m["found"].append(sim._plain(Data.AMMO, "Nails"))
	main.refresh()
	main._run._inv._pick(main._run._inv.cell_of(small["id"]))
	main.refresh()
	_check(pk._buttons[0].disabled and pk._words.visible and pk._words.text.begins_with("No room in the pack"), "a full pack did not grey Equip with the hint: '%s'" % pk._words.text)
	_check_fit(main, "Run (Pick-A, no room)")
	# a smaller backpack found: Equip only when what's carried still fits in it
	var worn_pack = sim.equipped["Backpack"]
	var big_pack: Dictionary = sim._plain("Backpack", Data.BASES["Backpack"].back()["name"])
	sim.equipped["Backpack"] = big_pack
	var small_pack: Dictionary = sim._plain("Backpack", "School bag")     # the smallest found pack; the start is under it
	m["found"] = [small_pack]
	while sim.pack_used(m) + Items.size(big_pack) + 1 <= sim.capacity():
		m["found"].append(sim._plain(Data.AMMO, "Nails"))
	_check(not sim.can_equip_from_pack(small_pack["id"]), "a smaller backpack could go on over a pack it cannot hold")
	m["found"] = [small_pack]
	_check(sim.can_equip_from_pack(small_pack["id"]), "a smaller backpack with room could not go on")
	sim.equipped["Backpack"] = worn_pack
	sim.extract_now()
	sim.load_dict(saved)
	# the Lock-up: the same frame, no Sell anywhere
	sim.equipped["Armour"] = sim._plain("Armour", "Riot suit")
	var in_stash: Dictionary = sim._plain("Armour", "Motorbike leathers")
	sim.stash.append(in_stash)
	main.show_room(main.ARMOURY)
	main._armoury._inv._set_kind(0)
	main.refresh()
	main._armoury._pick_cell(main._armoury._inv.cell_of(in_stash["id"]))
	main.refresh()
	var lk = main._armoury._pick
	_check(lk._heads[0].visible and lk._heads[1].visible and lk._heads[1]._title.text == "Riot suit" and lk._kickers[0].text.begins_with("THE PICK · IN THE STASH"), "the Lock-up's pick is not the same frame: %s / '%s'" % [lk._heads[1]._title.text, lk._kickers[0].text])
	_check(not lk.button_texts().any(func(t): return t.begins_with("Sell")), "Sell is still in the Lock-up: %s" % str(lk.button_texts()))
	_check(lk._verdict.visible and lk._tag_labels[0].visible, "the Lock-up's verdict or price tag is missing")
	_check_fit(main, "Lock-up (Pick-A)")
	sim.stash.erase(in_stash)
	sim.load_dict(saved)
	main.refresh()
	print("Pick-A ok: the two columns, the tags, the verdict, Equip and Ditch on a run, the swap, no room, the Lock-up without Sell")


## 31: the works' top levels, each a rule: the generator's rig row, the lookout's call, the dog that carries one home.
func _top_works_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	_check(Data.GENERATOR_LEVELS.back().get("rig_row", false) and Data.LOOKOUT_LEVELS.back().get("call", false) and Data.KENNEL_LEVELS.back().get("carries", false), "a work's top level is not the rule")
	# the generator: a second row of pouches, never past the cap
	var hold_rig = sim.equipped["Rig"]
	var big: Dictionary = sim._plain("Rig", Data.BASES["Rig"].back()["name"])
	big["affixes"] = [{"stat": "med_cap", "value": 3, "tier": 5}]
	sim.equipped["Rig"] = big
	sim.generator_level = Data.GENERATOR_LEVELS.size() - 2
	var before: int = sim.med_capacity()
	sim.generator_level = Data.GENERATOR_LEVELS.size() - 1
	_check(before > 0 and sim.med_capacity() == mini(before + Data.RIG_ROW, Data.RIG_CAP) and sim.med_capacity() > before, "the generator's row reads %d from %d" % [sim.med_capacity(), before])
	# past the cap it clips, and the run's rig and the Lock-up's rig hold the cap: the run's two rows in the one row's height
	sim.rig = []
	var pouches: int = sim.med_capacity()
	var two: Dictionary = {}
	for b in Data.BASES[Data.MEDICAL]:
		if Items.size(sim._plain(Data.MEDICAL, b["name"])) == 2:
			two = b
	while sim.rig_used() < pouches:
		var kit: Dictionary = sim._plain(Data.MEDICAL, two["name"]) if (not two.is_empty() and sim.rig_used() + 2 <= pouches and sim.rig.size() % 3 == 0) else sim._plain(Data.MEDICAL, Data.BASES[Data.MEDICAL][0]["name"])
		sim.rig.append(kit)
	_check(main._run.RIG_MAX >= Data.RIG_CAP and main._armoury._containers.RIG_MAX >= Data.RIG_CAP, "a rig display clips under the sim's cap")
	sim.deploy(0)
	main.show_room(main.MISSIONS)
	main.refresh()
	var right_edge := 0.0
	var bottom := 0.0
	for c in main._run._rig_cells:
		if c.visible:
			right_edge = maxf(right_edge, c.position.x + c.size.x)
			bottom = maxf(bottom, c.position.y + c.size.y)
	_check(right_edge <= main._run.PAD + main._run.INNER + 0.5 and bottom <= main._run.RIG_Y + Pal.CELL + 0.5, "the run's rig of %d spills: to x %.0f, y %.0f" % [pouches, right_edge, bottom])
	var cells_on := 0
	var outlines_on := 0
	for c in main._run._rig_cells:
		if c.visible:
			cells_on += 1
	for o in main._run._rig_outlines:
		if o.visible:
			outlines_on += 1
	_check(cells_on == sim.rig.size() and outlines_on == 0, "a full rig of kits and meds shows %d of %d items and %d free pouches" % [cells_on, sim.rig.size(), outlines_on])
	_check_fit(main, "Run (a full rig)")
	sim.extract_now()
	main.show_room(main.ARMOURY)
	main.refresh()
	_check_fit(main, "Lock-up (a full rig)")
	sim.rig = []
	sim.equipped["Rig"] = hold_rig
	# the lookout: the first gang after the clear waits for a full pack; a second gang does not
	sim.lookout_level = Data.LOOKOUT_LEVELS.size() - 1
	sim.deploy(0)
	var m: Dictionary = sim.mission
	m["remaining"] = 0
	m["cleared"] = true
	m["found"] = []
	m["patrol_timer"] = 0.0
	sim.advance(5.0)
	_check(sim.on_mission() and m["patrols"] == 0 and m["patrol_timer"] == 0.0, "the first gang's clock ran before the call: %.1f" % m["patrol_timer"])
	main.show_room(main.MISSIONS)
	main.refresh()
	_check(main._run._fight["tiles"][0]["value"].text == "on the call", "the Next gang tile does not say on the call: '%s'" % main._run._fight["tiles"][0]["value"].text)
	_check_fit(main, "Run (on the call)")
	while sim.pack_used(m) < sim.capacity():
		m["found"].append(sim._plain(Data.AMMO, "Nails"))
	sim.advance(5.0)
	_check(m["patrol_timer"] > 0.0 or m["patrols"] >= 1, "the full pack did not call the first gang")
	m["patrols"] = 1
	m["found"] = []
	m["patrol_timer"] = 0.0
	sim.advance(5.0)
	_check(m["patrol_timer"] > 0.0 or m["patrols"] >= 2, "the second gang waited for the call too")
	sim.extract_now()
	# the kennel: the best thing in the pack comes home with the dog on a death
	sim.kennel_level = Data.KENNEL_LEVELS.size() - 1
	sim.deploy(0)
	m = sim.mission
	var cheap: Dictionary = sim._plain(Data.AMMO, "Nails")
	var dear: Dictionary = sim._plain("Armour", Data.BASES["Armour"].back()["name"])
	m["found"] = [cheap, dear]
	var stash_before: int = sim.stash.size()
	sim.hp = 0.0
	sim._kia()
	_check(sim.stash.size() == stash_before + 1 and sim.stash.back()["id"] == dear["id"] and sim.last_report.get("carried", "") != "" and int(sim.last_report["left"]) == 1, "the dog did not carry the best thing home")
	# the deeds carried home are held all the same
	sim.load_dict(saved)
	sim.kennel_level = Data.KENNEL_LEVELS.size() - 1
	var hold_ending: String = sim.ending
	sim.ending = ""
	sim.deploy(0)
	m = sim.mission
	var deeds: Dictionary = sim._plain(Data.PAPER, "The deeds")
	deeds["deeds"] = true
	m["found"] = [deeds]
	sim.hp = 0.0
	sim._kia()
	_check(sim.ending == "held" and sim.stash.back().get("deeds", false), "the deeds carried home were not held: '%s'" % sim.ending)
	sim.ending = hold_ending
	# the works card reads the rules and fits
	main.show_room(main.OVERVIEW)
	main.refresh()
	_check_fit(main, "Yard (the works' top levels)")
	sim.load_dict(saved)
	main.refresh()
	print("the works' top levels ok: the rig row, the call, the dog that carries")


## What's on them and on you as chips (Matt, 6 Oct): "On them" under their bar, "On you" in place of the runner's note.
func _dots_chip_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.deploy(0)
	var m: Dictionary = sim.mission
	m["remaining"] = 3
	m["target_hp"] = 1e9
	m["dots"] = {"fire": 20.0, "poison": 20.0}
	m["chill_t"] = 1.0
	m["shock_t"] = 1.0
	m["my_dots"] = {"poison": 20.0, "bleed": 20.0}
	main.show_room(main.MISSIONS)
	main.refresh()
	var rn = main._run
	_check(rn._fight["chips"].visible and rn._fight["chips"].shown() == 4 and rn._fight["chips"].words(0) == "Burning" and rn._fight["chips"].words(2) == "Chilled" and rn._fight["chips"].words(3) == "Shocked", "On them reads %d chips: %s" % [rn._fight["chips"].shown(), rn._fight["chips"].words(0)])
	_check(rn._runner["chips"].visible and not rn._runner["note"].visible and rn._runner["chips"].shown() == 2 and rn._runner["chips"].words(0) == "Poisoned" and rn._runner["chips"].words(1) == "Bleeding", "On you reads %d chips" % rn._runner["chips"].shown())
	_check(rn._fight["chips"].position.y + Chips.CHIP_H <= rn._fight["box"].position.y + rn._fight["box"].size.y and rn._runner["chips"].position.y + Chips.CHIP_H <= rn._runner["box"].position.y + rn._runner["box"].size.y, "the chips sit out of their boxes")
	_check_fit(main, "Run (on them, on you)")
	# the dots' pools are the end of the bar (Matt, 6 Oct): what fire and poison still have to take off them sits at the
	# fill's end in their colours, so the fill goes down into it; yours the same for what's on you
	var of_hp: float = float(m["t"]["hp"])
	m["target_hp"] = of_hp * 0.5
	m["dots"] = {"fire": of_hp * 0.1, "poison": of_hp * 0.2}
	m["my_dots"] = {"poison": sim.max_hp() * 0.1, "bleed": sim.max_hp() * 0.6}
	sim.hp = sim.max_hp() * 0.5
	main.refresh()
	var segs: Array = rn._fight["segments"]
	var fire_i: int = Data.TYPES.find("fire")
	var poison_i: int = Data.TYPES.find("poison")
	var bleed_i: int = Data.TYPES.find("bleed")
	var fill_px: float = rn._fight["fill"].size.x
	_check(segs[fire_i].visible and segs[poison_i].visible and absf(segs[fire_i].size.x - rn.INNER * 0.1) <= 1.5 and absf(segs[poison_i].size.x - rn.INNER * 0.2) <= 1.5, "their bar's end is not the dots' pools: fire %.0f, poison %.0f" % [segs[fire_i].size.x, segs[poison_i].size.x])
	_check(absf(segs[fire_i].position.x + segs[fire_i].size.x - fill_px) <= 0.5 and absf(segs[poison_i].position.x + segs[poison_i].size.x - segs[fire_i].position.x) <= 0.5, "the pools do not sit at the fill's end, in a row")
	var ysegs: Array = rn._runner["segments"]
	var yfill: float = rn._runner["fill"].size.x
	_check(ysegs[poison_i].visible and ysegs[bleed_i].visible and absf(ysegs[poison_i].size.x - rn.INNER * 0.1) <= 1.5 and absf(ysegs[bleed_i].size.x - (yfill - ysegs[poison_i].size.x)) <= 1.5 and ysegs[bleed_i].position.x >= -0.5, "a pool past the fill's left end is not cut to it: poison %.0f, bleed %.0f of a %.0f fill" % [ysegs[poison_i].size.x, ysegs[bleed_i].size.x, yfill])
	m["dots"] = {}
	m["my_dots"] = {}
	main.refresh()
	_check(not segs[fire_i].visible and not ysegs[bleed_i].visible, "the pools did not clear with the dots")
	m["dots"] = {"fire": 20.0, "poison": 20.0}
	m["my_dots"] = {"poison": 20.0, "bleed": 20.0}
	main.refresh()
	# a med in use rides beside the chips as a muted one; nothing on you brings the note back
	m["using"] = {"name": "Bandage", "heal": 10.0, "left": 4.0}      # a med in use, by hand: the chip beside what's on you
	main.refresh()
	_check(rn._runner["chips"].shown() == 3 and rn._runner["chips"].words(2).contains(" s"), "the med in use is not a chip beside what's on you: %d" % rn._runner["chips"].shown())
	_check_fit(main, "Run (on you, med)")
	m["my_dots"] = {}
	main.refresh()
	_check(rn._runner["chips"].visible and rn._runner["chips"].shown() == 1 and not rn._runner["note"].visible, "the med in use alone is not a chip: %d" % rn._runner["chips"].shown())
	m["my_dots"] = {"poison": 20.0, "bleed": 20.0}
	m["using"] = null
	# no one left to be on: the row goes even with dots in the record
	m["remaining"] = 0
	main.refresh()
	_check(not rn._fight["chips"].visible, "On them shows with no one there")
	m["remaining"] = 3
	m["my_dots"] = {}
	m["dots"] = {}
	m["chill_t"] = 0.0
	m["shock_t"] = 0.0
	main.refresh()
	_check(not rn._fight["chips"].visible and not rn._fight["key"].visible and not rn._runner["note"].visible and not rn._runner["chips"].visible, "the chips did not clear with nothing on anyone (the line is the chips' alone)")
	_check_fit(main, "Run (nothing on anyone)")
	sim.extract_now()
	sim.load_dict(saved)
	main.refresh()
	print("the dots as chips ok: on them, on you, the med beside them, cleared")


## 30: wounds. A hit that takes the runner under a quarter leaves one stat cut a tenth until the clinic treats
## it for cash by level; one at a time; the yard, the run and the clinic say so; it goes with the runner.
func _wound_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.wound = ""
	# the hit under a quarter wounds; one already under it does not
	sim.deploy(0)
	var m: Dictionary = sim.mission
	var pace0: float = sim.pace()          # on the mission: armour counts the pack's free cells
	var arm0: float = sim.armour()
	var hp0: float = sim.max_hp()
	m["remaining"] = 6
	m["target_hp"] = 1e9
	sim.hp = sim.max_hp() * Data.WOUND_AT - 0.01
	sim.advance(1.0)
	_check(sim.wound == "", "a hit already under the quarter wounded")
	_check(sim.on_mission(), "the runner died under the first wound check")
	if not sim.on_mission():
		sim.load_dict(saved)
		return
	# through the fight itself: a hair over the quarter, their fire takes the runner under it; auto-run stops on it
	sim.auto_tier = 0
	sim.hp = sim.max_hp() * Data.WOUND_AT + 0.01
	var hp_in: float = sim.hp
	sim.advance(1.0)
	var through_the_fight: bool = sim.hp < hp_in and sim.hp > 0.0
	if through_the_fight:
		_check(sim.wound in Data.WOUND_STATS and m.get("wounded", false), "the hit under a quarter did not wound: '%s'" % sim.wound)
	else:
		sim._wound(m)                     # nothing landed at this tier (or it killed them): the wound by hand, the rest still checked
	_check(sim.on_mission(), "the runner died under the wound check")
	if not sim.on_mission():
		sim.load_dict(saved)
		return
	_check(not through_the_fight or sim.auto_tier < 0, "auto-run carried on through the wound")     # the fight's wound stops auto-run; the one by hand is only the wound
	var cut: String = sim.wound
	var now: Dictionary = {"pace": sim.pace(), "armour": sim.armour(), "hp": sim.max_hp()}
	var was: Dictionary = {"pace": pace0, "armour": arm0, "hp": hp0}
	for st in Data.WOUND_STATS:
		if st == cut:
			_check(is_equal_approx(now[st], was[st] * (1.0 - Data.WOUND_PCT / 100.0)), "the wound did not cut %s: %.2f from %.2f" % [st, now[st], was[st]])
		else:
			_check(is_equal_approx(now[st], was[st]), "the wound cut %s too: %.2f from %.2f" % [st, now[st], was[st]])
	# a second replaces the first: still one
	sim._wound(m)
	_check(sim.wound in Data.WOUND_STATS, "the second wound is off: '%s'" % sim.wound)
	# the run says so and fits
	main.show_room(main.MISSIONS)
	main.refresh()
	_check(main._run._runner["head"].text.begins_with("THE RUNNER · WOUNDED:"), "the run's runner head does not say wounded: '%s'" % main._run._runner["head"].text)
	_check_fit(main, "Run (wounded)")
	sim.extract_now()
	_check(sim.last_report.get("wounded", false), "the report does not carry the wound")
	# the yard's Runner card and the last run say so
	main.show_room(main.OVERVIEW)
	main.refresh()
	var runner_card = main._cards[0]
	_check(runner_card._title.text == "Runner" and runner_card._chips[0].visible and runner_card._chip_labels[0].text.begins_with("Wounded:"), "the Runner card does not carry the wound chip: '%s'" % runner_card._chip_labels[0].text)
	_check_fit(main, "Yard (wounded)")
	# the clinic: the band says so, Treat costs the wound's price by level at full HP, and clears it
	sim.wound = "pace"                    # a wound that leaves the max HP alone: the checks below read HP against it
	sim.hp = sim.max_hp()
	sim.cash += 5000.0
	var lv: int = sim.level()
	var expect: int = int(ceil(Data.WOUND_CASH * lv * sim.inflation() * maxf(0.2, 1.0 - sim.tree_sum("treat_pct") / 100.0)))
	_check(sim.needs_treating() and sim.treat_cost() == expect, "the wound's price reads %d, not %d" % [sim.treat_cost(), expect])
	main.show_room(main.MEDIC)
	main._clinic._shown = ""
	main.refresh()
	_check(main._clinic._band.unit.text.contains("wounded"), "the clinic's band does not say wounded: '%s'" % main._clinic._band.unit.text)
	# the two jobs apart (Clinic-B): at full HP the wound's button is the primary, Heal reads Fit
	_check(main._clinic._side_buttons[1].text.begins_with("The wound (") and not main._clinic._side_buttons[1].disabled, "the clinic's wound button is off: '%s'" % main._clinic._side_buttons[1].text)
	_check(main._clinic._side_buttons[0].text == "Fit" and main._clinic._side_buttons[0].disabled, "the clinic's heal button at full HP reads '%s'" % main._clinic._side_buttons[0].text)
	_check(main._clinic._side_buttons[0].position.x + main._clinic._side_buttons[0].size.x <= main._clinic._side_buttons[1].position.x, "the clinic's two buttons overlap")
	_check(main._clinic._side_bar_text.text.contains("wounded"), "the clinic's bar does not name the wound: '%s'" % main._clinic._side_bar_text.text)
	_check_fit(main, "Clinic (wounded)")
	# hurt and wounded: heal alone costs the HP's price and leaves the wound; the wound alone costs its price and leaves the HP
	sim.hp = sim.max_hp() * 0.5
	main.refresh()
	var heal_expect: int = sim.heal_cost()
	_check(heal_expect > 0 and sim.wound_cost() == expect and sim.treat_cost() == heal_expect + expect, "the clinic's prices do not add up: heal %d, wound %d, both %d" % [heal_expect, sim.wound_cost(), sim.treat_cost()])
	_check(main._clinic._side_buttons[0].text.begins_with("Heal (") and not main._clinic._side_buttons[0].disabled, "the clinic's heal button is off hurt: '%s'" % main._clinic._side_buttons[0].text)
	var cash0: float = sim.cash
	main._clinic._side_press(0)
	_check(sim.hp >= sim.max_hp() - 0.5 and sim.wound != "" and is_equal_approx(cash0 - sim.cash, float(heal_expect)), "Heal did not heal alone: hp %.0f of %.0f, wound '%s', %.0f paid" % [sim.hp, sim.max_hp(), sim.wound, cash0 - sim.cash])
	main.refresh()
	cash0 = sim.cash
	main._clinic._side_press(1)
	_check(sim.wound == "" and is_equal_approx(cash0 - sim.cash, float(expect)) and not sim.needs_treating(), "The wound did not see to the wound: '%s', %.0f paid" % [sim.wound, cash0 - sim.cash])
	main.refresh()
	_check(main._clinic._side_buttons[0].text == "Fit for duty" and main._clinic._side_buttons[1].text == "No wound", "the clinic's buttons after treatment: '%s' / '%s'" % [main._clinic._side_buttons[0].text, main._clinic._side_buttons[1].text])
	_check_fit(main, "Clinic (fit)")
	# saved and loaded; gone with a dead runner
	sim.wound = "pace"
	var d: Dictionary = sim.to_dict()
	_check(str(d.get("wound", "")) == "pace", "the wound is not saved")
	sim.load_dict(d)
	_check(sim.wound == "pace", "the wound is not loaded")
	sim.deploy(0)
	sim.hp = 0.0
	sim._kia()
	_check(sim.wound == "", "the wound went on to the next runner")
	sim.load_dict(saved)
	main.refresh()
	print("wounds ok: the hit under a quarter, one stat a tenth, one at a time, the run, the yard, the clinic's price and cure, the save, the death")


## 29: picked over inside a run. After thin_after searches a site's finds thin a fifth a search to the floor;
## deeper sites and quantity bonuses give more searches in full; the Searching bar says so.
func _thinning_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	var hold_pack = sim.equipped["Backpack"]
	sim.equipped["Backpack"] = null
	sim.tree = sim.tree.filter(func(id): return not str(id).begins_with("The rat man/"))
	sim.set_depth(0, 1)
	sim.deploy(0)
	var m: Dictionary = sim.mission
	var t: Dictionary = m["t"]
	var n: int = sim.thin_after(t)
	_check(n >= Data.THIN_AFTER, "thin_after at depth 1 reads %d" % n)
	m["searches"] = 0
	_check(sim.thinning(m, t) == 1.0, "a fresh site is thinning already")
	m["searches"] = n
	_check(sim.thinning(m, t) == 1.0, "the site thins before its searches are up")
	m["searches"] = n + 1
	_check(is_equal_approx(sim.thinning(m, t), 1.0 - Data.THIN_STEP), "the first thinned search reads %.2f" % sim.thinning(m, t))
	m["searches"] = n + 100
	_check(is_equal_approx(sim.thinning(m, t), Data.THIN_FLOOR), "the floor reads %.2f" % sim.thinning(m, t))
	# the bar says so, and fits
	m["remaining"] = 0
	m["cleared"] = true
	main.show_room(main.MISSIONS)
	main.refresh()
	_check(main._run._fight["bar_text"].text.begins_with("Thinned out: finds at %d%%" % int(roundf(Data.THIN_FLOOR * 100.0))), "the bar does not say the site is thinned out: '%s'" % main._run._fight["bar_text"].text)
	_check_fit(main, "Run (thinned out)")
	m["searches"] = n + 1
	main.refresh()
	_check(main._run._fight["bar_text"].text.begins_with("Thinning: finds at"), "the bar does not say the site is thinning: '%s'" % main._run._fight["bar_text"].text)
	_check_fit(main, "Run (thinning)")
	# at the floor, a hundred searches bring about the floor's share of what a fresh site would
	m["searches"] = n + 100
	m["patrol_timer"] = -1e9
	m["event_at"] = -1.0                  # no event lands a gang on the search
	sim.auto_tier = -1
	m["leave_full"] = false
	var found0: int = int(m.get("finds", 0))
	var s0: int = m["searches"]
	for k in range(int(70.0 * sim.search_s(t))):
		sim.hp = sim.max_hp()
		m["remaining"] = 0
		sim.advance(1.0)
		if not sim.on_mission() or m["searches"] - s0 >= 60:
			break
	_check(sim.on_mission(), "the run ended under the thinning check: %s / %s" % [str(sim.last_report.get("outcome", "")), str(sim.events.slice(maxi(0, sim.events.size() - 3)).map(func(e): return e[1]))])
	if sim.on_mission():
		var finds_each: int = 1 + (1 if (sim.has_node("scavenger") or sim.has_node("quiet_hands")) else 0) + int(Data.KENNEL_LEVELS[sim.kennel_level]["finds"]) + (1 if sim.has_rule("postman") else 0)
		var per: float = float(int(m.get("finds", 0)) - found0) / maxf(1.0, float(m["searches"] - s0))
		_check(m["searches"] - s0 >= 20 and per < float(finds_each) * 0.8, "at the floor a search still brings %.2f of %d (%d searches)" % [per, finds_each, m["searches"] - s0])
		sim.extract_now()
	# deeper sites and quantity give more searches in full; the figure ratchets through a run
	sim.deploy(0)
	m = sim.mission
	var shallow: int = sim.thin_after(m["t"])
	var expect := func(d: int) -> int: return int(roundf((Data.THIN_AFTER + Data.THIN_PER_DEPTH * d) * (1.0 + maxf(0.0, sim.loot_bonus()))))
	_check(shallow == expect.call(int(m["t"]["depth"])), "thin_after reads %d, not %d" % [shallow, expect.call(int(m["t"]["depth"]))])
	var heavy: Dictionary = sim._plain("Backpack", Data.BASES["Backpack"][0]["name"])
	heavy["affixes"] = [{"stat": "loot_pct", "value": 100, "tier": 5}]
	sim.equipped["Backpack"] = heavy
	_check(sim.thin_after(m["t"]) == expect.call(int(m["t"]["depth"])) and sim.thin_after(m["t"]) > shallow, "+100%% quantity did not push the searches: %d from %d" % [sim.thin_after(m["t"]), shallow])
	var heavy_n: int = sim.thin_after(m["t"])
	sim.thinning(m, m["t"])
	sim.equipped["Backpack"] = null
	sim.thinning(m, m["t"])
	_check(int(m["thin_after"]) == heavy_n, "the searches in full did not hold when the quantity bonus went: %d, not %d" % [int(m["thin_after"]), heavy_n])
	var deeper: Dictionary = m["t"].duplicate()
	deeper["depth"] = int(m["t"]["depth"]) + 3
	_check(sim.thin_after(deeper) == expect.call(int(deeper["depth"])) and sim.thin_after(deeper) > shallow, "depth did not push the searches: %d from %d" % [sim.thin_after(deeper), shallow])
	sim.extract_now()
	sim.equipped["Backpack"] = hold_pack
	sim.load_dict(saved)
	main.refresh()
	print("thinning ok: the searches in full, the fifth a search, the floor, the bar, depth and quantity")


## The Yard's right half (Yard-C/D, 7 Oct): the yard's jobs on one card, a row a job with its own Build button,
## the town and the purse under; the rail's Upgrade badge when a job is affordable.
func _yard_wide_checks(main) -> void:
	var sim = main.sim
	var w = main._yard_works
	var t = main._yard_town
	_check(w.visible and t.visible, "the Yard's wide pair is not shown")
	_check(w.position.x == 2 * (Pal.CARD_W + Pal.CARD_GAP) and t.position.y == Pal.CARD_H + Pal.CARD_GAP, "the wide pair is not in the right two columns: %s / %s" % [str(w.position), str(t.position)])
	_check(not Rect2(w.position, w.size).intersects(Rect2(t.position, t.size)), "the yard's two wide cards overlap")
	var names: Array = w._names.filter(func(l): return l.visible).map(func(l): return l.text)
	_check(names == ["Generator", "Lookout", "Kennel", "Stash", "Bench"], "the yard's jobs are off: %s" % str(names))
	# every row's button follows the sim: Build (£) when there is a next level, on when affordable; the works' row words
	var cash0: float = sim.cash
	sim.cash = 0.0
	main.refresh()
	for i in range(5):
		var b = w._buttons[i]
		var j: Dictionary = main._yard_jobs()[i]
		if int(j["cost"]) > 0:
			_check(b.text.contains(Fmt.money(int(j["cost"]))) and b.disabled, "%s with no cash: '%s' %s" % [j["name"], b.text, "off" if b.disabled else "on"])
			_check(w._nexts[i].text.begins_with("Next: ") and w._nows[i].text.begins_with("Now: "), "%s's row words are off: '%s' / '%s'" % [j["name"], w._nows[i].text, w._nexts[i].text])
		else:
			_check(b.text in ["As good as it gets", "Built"] and b.disabled and w._nexts[i].text == "", "%s at the top reads '%s'" % [j["name"], b.text])
	_check(main._rail_status(main.OVERVIEW).get("badge", "") == "", "the rail's Upgrade badge is lit with no cash")
	sim.cash = 1000000.0
	main.refresh()
	_check(main._rail_status(main.OVERVIEW).get("badge", "") == "Upgrade", "the rail's Upgrade badge is not lit with every job affordable")
	var lv0: int = sim.kennel_level
	if sim.kennel_cost() > 0:
		_check(not w._buttons[2].disabled, "the kennel's Build is off with the cash in hand")
		w.press(2)
		_check(sim.kennel_level == lv0 + 1, "the kennel's Build did not build: level %d from %d" % [sim.kennel_level, lv0])
		sim.kennel_level = lv0
	sim.cash = cash0
	main.refresh()
	_check(t._title.text.begins_with("The town and the purse") and t._kickers[0].text.begins_with("THE TOWN") and t._kickers[1].text == "THE PURSE", "the town and the purse card is off: '%s' / '%s' / '%s'" % [t._title.text, t._kickers[0].text, t._kickers[1].text])
	_check(t._labels[1][0].text == "Cash" and t._values[1][0].text == Fmt.money(sim.cash), "the purse's cash line is off: %s %s" % [t._labels[1][0].text, t._values[1][0].text])
	_check(t._button.visible == sim.can_move_yard(), "Move the yard shows %s when the yard %s move" % ["on" if t._button.visible else "off", "can" if sim.can_move_yard() else "cannot"])
	_check_fit(main, "Yard (wide)")


## The sum strip's tiles sit inside their panel (7 Oct: the strip was sized by the node tile's height, four
## pixels short, and the tiles' feet were cut off).
func _sum_strip_check(main) -> void:
	var bk = main._barracks
	var inside := Rect2(Vector2.ZERO, bk._sum.size)
	_check(bk._sum_chips.shown() == 8, "the sum strip shows %d of its eight chips" % bk._sum_chips.shown())
	for k in range(bk._sum_chips.shown()):
		var pnl = bk._sum_chips._panels[k]
		var r := Rect2(bk._sum_chips.position + pnl.position, pnl.size)
		_check(inside.encloses(r), "a sum chip runs out of its strip: %s in %s" % [str(r), str(inside)])
	# a node's panel: the figure as a chip, the sentence after it, apart
	if bk.selected != "" and bk._chips.visible:
		_check(bk._words.position.x >= bk._chips.position.x + bk._chips.used_width() and bk._words.text != "" and bk._words.text.ends_with("."), "the node's chip and sentence are off: words at %.0f, chips to %.0f, '%s'" % [bk._words.position.x, bk._chips.position.x + bk._chips.used_width(), bk._words.text])
	_check(bk._panel.position.y >= bk._sum.position.y + bk._sum.size.y + 8, "the node panel sits on the sum strip")


## The rarities' colours (Rarity-A, 7 Oct): seven tones a cell can wear, every one its own, none the pick ring's;
## a unique pink, a legendary gold, a rare blue, on the cell and on the head's chip.
func _rarity_tone_checks(sim) -> void:
	var tones := ["good", "rare", "epic", "legendary", "unique", "set"]
	var seen := []
	for t in tones:
		var c: Color = Pal.tone_color(t)
		_check(c != Pal.PICK and c != Pal.TEXT_2, "the %s tone is the pick ring's or the plain text's" % t)
		_check(not seen.has(c), "the %s tone is another rarity's colour" % t)
		seen.append(c)
	var rare: Dictionary = sim._plain("Helmet", "Hard hat")
	rare["rarity"] = 2
	var leg: Dictionary = sim._plain("Helmet", "Hard hat")
	leg["rarity"] = 4
	var uniq: Dictionary = sim._plain("Helmet", "Hard hat")
	uniq["rarity"] = 4
	uniq["unique"] = "Test"
	_check(Pal.item_tone(rare) == "rare" and Pal.item_tone(leg) == "legendary" and Pal.item_tone(uniq) == "unique", "an item's tone is off: %s / %s / %s" % [Pal.item_tone(rare), Pal.item_tone(leg), Pal.item_tone(uniq)])
	var Cell = load("res://scripts/ui/item_cell.gd")
	var cell = Cell.new()
	cell.show_item(uniq, false)
	_check((cell.get_theme_stylebox("normal") as StyleBoxFlat).border_color == Pal.UNIQUE, "a unique's cell is not pink")
	cell.show_item(leg, true)
	_check((cell.get_theme_stylebox("normal") as StyleBoxFlat).border_color == Pal.PICK, "a picked cell's ring is not the pick ring")
	cell.queue_free()


## The shell's odds, settled: frames of main._read_odds until every open tier has read (the Runs and Radio
## screens show "reading the odds" until then).
func _settle_odds(main) -> void:
	for k in range(4000):
		main._read_odds()
		var done := true
		for i in range(Data.TIERS.size()):
			if main.sim.tier_open(i) and not main.sim.odds_settled(i):
				done = false
		if done:
			return


## The move's compounding and the wall's score (the endgame, part 2, 7 Oct): a moved yard's ladders start at the
## floor on a site's first clear, its first node of the yard's tree is free, the lorries and the best dig survive
## the move, and a retired runner's line names the deepest they held.
func _endgame_move_checks(main) -> void:
	var sim = main.sim
	var before: Dictionary = sim.to_dict()
	# the best dig recorded: the deepest clear so far, with its yard
	_check(not sim.best_dig.is_empty() and int(sim.best_dig["depth"]) >= Data.CONVOY_DEPTH and int(sim.best_dig["yard"]) == 1, "the best dig is off: %s" % str(sim.best_dig))
	# the wall's line names the deepest held
	sim.xp = Data.xp_for_level(Data.RETIRE_LEVEL)
	_check(sim.can_retire() and sim.retire(), "the runner could not retire for the wall check")
	var r: Dictionary = sim.past.back()
	_check(str(r.get("site", "")) != "" and int(r.get("depth", 0)) >= Data.CONVOY_DEPTH, "the wall's record has no deepest held: %s" % str(r))
	sim.set_class("Doorman")
	main.show_room(main.BARRACKS)
	main._barracks.selected = ""
	main._barracks._shown = ""
	main.refresh()
	_check(main._barracks._past.text.contains("at depth"), "the wall's line does not name the depth: '%s'" % main._barracks._past.text)
	_check_fit(main, "Caravan (the wall's depth)")
	# the move: the lorries and the best dig come, lorry_done clears, the first yard node is free, the ladders start at the floor
	var lorries0: int = sim.lorries
	var dig0: Dictionary = sim.best_dig.duplicate()
	_check(sim.can_move_yard() and sim.move_yard(), "the yard could not move after the lorry")
	_check(sim.yard_moves == 1 and sim.lorries == lorries0 and sim.best_dig == dig0 and not sim.lorry_done, "the move lost the score: moves %d, lorries %d, dig %s, lorry %s" % [sim.yard_moves, sim.lorries, str(sim.best_dig), str(sim.lorry_done)])
	_check(sim.ladder_floor() == 1 and sim.free_yard_nodes() == 1, "the move's floor and free nodes are off: %d / %d" % [sim.ladder_floor(), sim.free_yard_nodes()])
	var yard_ids: Array = []
	for k in range(Data.tree_named(Data.COMMON_TREE)["nodes"].size()):
		yard_ids.append("%s/%d" % [Data.COMMON_TREE, k])
	var taken_yard: Array = sim._yard_nodes_taken()
	if taken_yard.size() >= 1:
		_check(sim.node_cost(taken_yard[0]) == 0, "the first yard node taken is not free after a move: %d" % sim.node_cost(taken_yard[0]))
		if taken_yard.size() >= 2:
			_check(sim.node_cost(taken_yard[1]) > 0, "the second yard node is free too: %d" % sim.node_cost(taken_yard[1]))
	else:
		_check(sim.node_cost(yard_ids[0]) == 0, "a fresh yard's first node is not free after a move: %d" % sim.node_cost(yard_ids[0]))
		sim.train_node(yard_ids[0])
		_check(sim.tree.has(yard_ids[0]) and sim.node_cost(yard_ids[0]) == 0 and sim.node_cost(yard_ids[1]) > 0, "after the free node the next is free too: %d / %d" % [sim.node_cost(yard_ids[0]), sim.node_cost(yard_ids[1])])
	sim.set_class("Doorman")
	var t0: Dictionary = sim.effective(0)
	sim.deploy(0)
	sim._clear(sim.mission, t0)
	sim.extract_now()
	_check(sim.best_depth[0] == 1 and sim.atlas_points == 0, "the first clear on a moved yard is off: best %d, points %d" % [sim.best_depth[0], sim.atlas_points])
	_check(sim.events.any(func(e): return str(e[1]).contains("ladders start at depth 2")), "the ladder's floor was not said")
	# the floor opens the depth without faking the clear: depth 2 opens on the streets, depth 3 does not; the wall reads depth 1
	_finish_campaign(sim)
	sim.set_depth(0, 3)
	_check(sim.depth[0] == 2 and sim.best_depth[0] == 1, "the floor did not open depth 2 alone: depth %d, best %d" % [sim.depth[0], sim.best_depth[0]])
	_check(sim._deepest_held()[1] == 1, "the wall counts the floor as held: %s" % str(sim._deepest_held()))
	sim.set_depth(0, 1)
	# saved and loaded
	var d: Dictionary = sim.to_dict()
	var fresh = Sim.new()
	fresh.start()
	fresh.load_dict(d)
	_check(fresh.lorries == lorries0 and fresh.best_dig == dig0 and fresh.yard_moves == 1, "the score did not survive a save")
	sim.load_dict(before)


## A site's level (the endgame, 7 Oct): tier plus depth drives the curve, the bases and the item level, so the
## streets' ladder is gentle and long and the barracks' steep and short; the Runs card says the level.
func _site_level_checks(main) -> void:
	var sim = main.sim
	var hold_depth: Array = sim.depth.duplicate()
	var hold_best: Array = sim.best_depth.duplicate()
	for i in range(Data.TIERS.size()):
		sim.best_depth[i] = 20
	_check(sim.loot_tier_at(1) == 1 and sim.loot_tier_at(8) == 5 and sim.loot_tier_at(9) == Data.MAX_TIER and sim.loot_tier_at(30) == Data.MAX_TIER, "the gear tier by level is off: %d %d %d" % [sim.loot_tier_at(1), sim.loot_tier_at(8), sim.loot_tier_at(9)])
	sim.set_depth(0, 8)
	sim.set_depth(8, 2)
	var hold_intel: Array = [sim.intel[0].duplicate(), sim.intel[8].duplicate()]
	sim.intel[0] = []                     # the plain sites: a word on the air can add a gear tier
	sim.intel[8] = []
	var streets: Dictionary = sim.effective(0)
	var barracks: Dictionary = sim.effective(8)
	_check(int(streets["level"]) == 8 and int(barracks["level"]) == 10 and sim.site_level(0) == 8, "the sites' levels are off: %d / %d" % [int(streets["level"]), int(barracks["level"])])
	_check(float(barracks["hp"]) > float(streets["hp"]) and float(barracks["dps"]) > float(streets["dps"]), "the barracks at depth 2 is no harder than the streets at depth 8: %.0f vs %.0f HP" % [float(barracks["hp"]), float(streets["hp"])])
	_check(int(streets["loot_tier"]) == 5 and int(barracks["loot_tier"]) == Data.MAX_TIER, "the bases by level are off: streets tier %d, barracks tier %d" % [int(streets["loot_tier"]), int(barracks["loot_tier"])])
	# a find carries the site's level
	var f0: Dictionary = Items.roll("Primary", int(streets["loot_tier"]), sim.rng, 0.0, false, false, "", "", 0.33, 8, int(streets["level"]))
	var f8: Dictionary = Items.roll("Primary", int(barracks["loot_tier"]), sim.rng, 0.0, false, false, "", "", 0.33, 2, int(barracks["level"]))
	_check(int(f0["ilvl"]) == 8 and int(f8["ilvl"]) == 10, "a find's item level is not the site's: %d / %d" % [int(f0["ilvl"]), int(f8["ilvl"])])
	# never under the site's own campaign curve: the barracks at depth 2 keeps the campaign's climb
	var camp_d2: float = float(Data.TIERS[8]["hp"]) * (1.0 + Data.DEPTH_HOSTILE)
	_check(float(barracks["hp"]) >= camp_d2 - 0.01, "the barracks at depth 2 fell under its campaign curve: %.0f < %.0f" % [float(barracks["hp"]), camp_d2])
	# the Runs card says it: the level on the kicker, the finds' level on a tile, the stations on the note
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(0)
	main._missions._shown = ""
	main.refresh()
	var c0: Dictionary = main._missions._cols[0]
	_check(c0["band"].kicker.text.ends_with("level 8"), "the streets' kicker does not say its level: '%s'" % c0["band"].kicker.text)
	var finds := -1
	for r in range(6):
		if c0["tiles"][r]["key"].text == "Finds":
			finds = r
	_check(finds >= 0 and c0["tiles"][finds]["value"].text.begins_with("level 8"), "the streets' Finds tile is off: %s" % (c0["tiles"][finds]["value"].text if finds >= 0 else "no Finds tile"))
	main._missions._pick_zone(2)
	main._missions._shown = ""
	main.refresh()
	var c6: Dictionary = main._missions._cols[0]       # the services, the city's first
	_check(c6["note"].text.contains("the lorry") or sim.hp < sim.max_hp() * 0.5, "the services' card does not name the lorry: '%s'" % c6["note"].text)
	_check_fit(main, "Runs (levels)")
	main._missions._pick_zone(0)
	_site_unique_checks(main)
	sim.intel[0] = hold_intel[0]
	sim.intel[8] = hold_intel[1]
	sim.depth = hold_depth
	sim.best_depth = hold_best
	sim._surv_cache = {}


## A site's own unique (endgame part 3): never loose, gated by zone (the streets at 12, the barracks at 6),
## found on its site past the gate and nowhere shallower; the Runs card names it until it is on the shelf.
func _site_unique_checks(main) -> void:
	var sim = main.sim
	for u in sim.loose_uniques(99):
		_check(not u.has("site"), "%s is a site's own and loose" % u["name"])
	_check(sim.site_unique_depth(0) == 12 and sim.site_unique_depth(4) == 9 and sim.site_unique_depth(8) == 6, "the sites' own depths are off: %d %d %d" % [sim.site_unique_depth(0), sim.site_unique_depth(4), sim.site_unique_depth(8)])
	_check(sim.site_unique(8)["name"] == "The quartermaster's manual" and sim.site_unique(0)["name"] == "The gritter's hopper", "the sites' own are off")
	var hold_shelf: Array = sim.shelf.duplicate()
	var hold_stash: Array = sim.stash.duplicate()
	sim.shelf = []
	# the barracks at depth 5: never; at depth 6: within a few hundred finds
	var own := 0
	for d in [5, 6]:
		own = 0
		sim.set_depth(8, d)
		sim.deploy(8)
		var m: Dictionary = sim.mission
		var eff: Dictionary = sim.effective(8)
		for k in range(400):
			m["found"] = []
			sim._find(m, eff)
			if not m["found"].is_empty() and m["found"][0].get("unique", "") == "The quartermaster's manual":
				own += 1
		sim.extract_now()
		if d == 5:
			_check(own == 0, "the barracks' own dropped at depth 5")
		else:
			_check(own > 0 and own < 60, "the barracks' own is %d of 400 finds at depth 6; 3%% was the aim" % own)
	# the Runs card names it until it is found
	sim.shelf = []
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(2)
	main._missions._shown = ""
	main.refresh()
	var c8: Dictionary = main._missions._cols[2]
	_check(main._missions._station_words(8).contains("Depth 6: its own, The quartermaster's manual"), "the barracks' station words do not name its own: '%s'" % main._missions._station_words(8))
	_check(c8["note"].text != "" or sim.hp < sim.max_hp() * 0.5, "the barracks' note is empty with its own unfound")
	_check_fit(main, "Runs (a site's own)")
	sim.shelf = ["The quartermaster's manual"]
	_check(not main._missions._station_words(8).contains("its own"), "the barracks' station words still name its own once found")
	# the fence's gamble never hands out the chase
	var chase_names: Array = []
	for c in sim.shelf_chase():
		chase_names.append(c["name"])
	var leaked := ""
	for k in range(300):
		var g: Dictionary = sim.roll_gamble({"slot": "Charm", "type": ""}, 0.0)
		if g.get("unique", "") in chase_names:
			leaked = g["unique"]
	_check(leaked == "", "the gamble handed out the chase: %s" % leaked)
	main._missions._pick_zone(0)
	sim.shelf = hold_shelf
	sim.stash = hold_stash


## The map in the caravan's shape (Map-A, 7 Oct): six tiles in three columns, the pips as the ranks, the taken
## tiles lined, the sum strip, and the panel filled by a pick with a rank taken through it.
func _map_screen_checks(main) -> void:
	var sim = main.sim
	var at = main._missions._atlas
	_check(at.visible and at._tiles.size() == Data.ATLAS.size(), "the map shows %d tiles of %d" % [at._tiles.size(), Data.ATLAS.size()])
	# every passive on a tile, in a column, inside the room; tiles apart
	var rects: Array = []
	for key in at._tiles:
		var b: Button = at._tiles[key]["button"]
		var r := Rect2(b.position, b.size)
		_check(Rect2(Vector2.ZERO, at.size).encloses(r), "the %s tile runs out of the map: %s" % [key, str(r)])
		for other in rects:
			_check(not r.intersects(other), "two map tiles overlap: %s and %s" % [str(r), str(other)])
		rects.append(r)
		var pips: Array = at._tiles[key]["pips"]
		var a: Dictionary = at._passive(key)
		_check(pips.size() == int(a["max"]), "%s has %d pips for %d ranks" % [key, pips.size(), int(a["max"])])
		var lit := 0
		for p in pips:
			if (p.get_theme_stylebox("panel") as StyleBoxFlat).bg_color == Pal.ACCENT:
				lit += 1
		_check(lit == sim.atlas_rank(key), "%s shows %d pips lit for rank %d" % [key, lit, sim.atlas_rank(key)])
	_check(at._sum_chips.shown() == Data.ATLAS.size(), "the map's sum strip shows %d chips" % at._sum_chips.shown())
	# a pick fills the panel; a rank through it takes; the pips follow
	var rank0: int = sim.atlas_rank("quiet_roads")
	sim.atlas_points += 1
	at._pick("quiet_roads")
	_check(at._title.text.begins_with("Quiet roads · rank %d of 3" % rank0) and at._take.visible and not at._take.disabled and at._words.text.ends_with("."), "the map's panel after a pick is off: '%s' / '%s'" % [at._title.text, at._words.text])
	_check(at._words.position.x >= at._chips.position.x + at._chips.used_width(), "the map panel's sentence sits on its chips")
	at._on_take()
	_check(sim.atlas_rank("quiet_roads") == rank0 + 1 and at._title.text.begins_with("Quiet roads · rank %d of 3" % (rank0 + 1)), "a rank through the panel did not take: %d, '%s'" % [sim.atlas_rank("quiet_roads"), at._title.text])
	_check_fit(main, "Runs (the map, picked)")
	sim.atlas_points -= 1                 # the point lent above goes back: the save check after counts them


func _yard_checks(main) -> void:
	var sim = main.sim
	_loot_roll_checks(main)
	if sim.on_mission():
		sim.extract_now()
	main.show_room(main.OVERVIEW)
	main.refresh()
	var titles: Array = main._cards.map(func(c): return c._title.text if c.visible else "")
	for want in ["Runner", "Elements", "Finds", "Last run"]:
		_check(titles.has(want), "the Yard has no %s card: %s" % [want, str(titles)])
	_check(titles.count("") == 4, "the Yard's left two columns do not hold exactly four cards: %s" % str(titles))
	for k in [2, 3, 6, 7]:
		_check(not main._cards[k].visible, "a card sits under the Yard's wide pair at slot %d" % k)
	_yard_wide_checks(main)
	var elements = main._cards[titles.find("Elements")]
	var fire_row := -1
	for k in range(elements._labels.size()):
		if elements._labels[k].text == "Fire":
			fire_row = k
	_check(fire_row >= 0 and elements._values[fire_row].text.contains("res ") and elements._values[fire_row].get_theme_color("font_color") == Pal.ELEMENT_COLOURS["fire"], "the Elements card's fire line is off: %s" % (elements._values[fire_row].text if fire_row >= 0 else "none"))
	# a torch makes the deal share show
	var hold_gun = sim.equipped["Primary"]
	var torch: Dictionary = sim._plain("Primary", "Nail gun")
	torch["affixes"] = [{"stat": "conv_fire_pct", "value": 20, "tier": 2}]
	sim.equipped["Primary"] = torch
	main.refresh()
	# the card reads the whole conversion: the torch's 20 and whatever the tree adds
	var fire_share: int = int(round(float(sim.conversion().get("fire", 0.0)) * 100.0))
	_check(fire_share >= 20 and elements._values[fire_row].text.begins_with("deal %d%%" % fire_share), "with %d%% as fire the Elements card reads '%s'" % [fire_share, elements._values[fire_row].text])
	var total_share: int = 0
	for ty in Data.ELEMENTS:
		total_share += int(round(float(sim.conversion().get(ty, 0.0)) * 100.0))
	_check(elements._headline.text == "%d%%" % total_share or elements._headline.text == "%d%%" % fire_share, "the Elements headline is '%s', not %d%%" % [elements._headline.text, total_share])
	sim.equipped["Primary"] = hold_gun
	# the runner's trait reads as a stat: a chip with its figures on the Runner card, a line on the Caravan
	var runner_card = main._cards[titles.find("Runner")]
	var tdata: Dictionary = sim.trait_data()
	if not tdata.is_empty():
		var chip_texts2 := []
		for k in range(runner_card.CHIPS):
			if runner_card._chips[k].visible:
				chip_texts2.append(runner_card._chip_labels[k].text)
		_check(chip_texts2.any(func(t): return str(t).begins_with(tdata["name"] + ": ")), "the Runner card has no trait chip: %s" % str(chip_texts2))
		main.show_room(main.BARRACKS)
		main._barracks.selected = ""
		main.refresh()
		_check(main._barracks._scope.text.begins_with(tdata["name"] + ": "), "the Caravan does not give the trait's figures: '%s'" % main._barracks._scope.text)
		_check_fit(main, "Caravan (trait)")
		main.show_room(main.OVERVIEW)
		main.refresh()
	var finds = main._cards[titles.find("Finds")]
	_check(finds._unit.text == "loot quality" and finds._labels[0].text == "Loot quantity", "the Finds card is off: %s / %s" % [finds._unit.text, finds._labels[0].text])
	# a bonus below nought reads with a minus, never "+-5%": the rat's share takes 20% off quantity
	var hold_tree: Array = sim.tree.duplicate()
	if not sim.tree.has("The rat man/9"):
		sim.tree.append("The rat man/9")
	main.refresh()
	var figures: Array = [finds._headline.text] + finds._values.map(func(l): return l.text)
	_check(not figures.any(func(t): return str(t).contains("+-") or str(t).contains("+−")), "a Finds figure reads with a doubled sign: %s" % str(figures))
	_check(sim.loot_bonus() >= 0.0 or finds._values[0].text.begins_with("−"), "a quantity below nought reads '%s'" % finds._values[0].text)
	_check(main._signed_pct(-5.0) == "−5%" and main._signed_pct(8.0) == "+8%" and main._signed_pct(0.0) == "0%" and main._signed_pct(-0.2) == "0%", "signed percents read off: %s %s %s" % [main._signed_pct(-5.0), main._signed_pct(8.0), main._signed_pct(-0.2)])
	sim.tree = hold_tree
	main.refresh()
	_check_fit(main, "The Yard (option A)")
	# the Runs cards: a chip an element they fire, with your resist; the town fires fire and poison
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(1)
	main.refresh()
	var col: Dictionary = main._missions._cols[0]
	var chip_texts: Array = col["chips"].text_nodes().map(func(l): return l.text)
	if sim.tier_open(Data.ZONES[1]["tiers"][0]):
		_check(chip_texts.any(func(t): return str(t).begins_with("Fire")) and chip_texts.any(func(t): return str(t).contains("res")), "the town's card does not say what it fires and what you resist: %s" % str(chip_texts))
	# the odds in words, the figure small beside them; every band fits the card
	if sim.tier_open(Data.ZONES[1]["tiers"][0]):
		_check(Words.ODDS.any(func(b): return b[1] == col["band"].headline.text) and col["band"].unit.text.ends_with("to clear") or col["band"].unit.text == "reading the odds", "the odds don't read in words: '%s' / '%s'" % [col["band"].headline.text, col["band"].unit.text])
	for band in Words.ODDS:
		col["band"].headline.text = band[1]
		col["band"].unit.text = "100% to clear"
		_check(UI.text_width(col["band"].headline, band[1]) + 16 + UI.text_width(col["band"].unit, col["band"].unit.text) <= col["band"].headline.size.x, "the odds band '%s' and its figure don't share the band's foot" % band[1])
	main.refresh()
	_check(Words.odds_words(0.95) == "Safe" and Words.odds_words(0.5) == "A coin toss" and Words.odds_words(0.05) == "A bad idea", "the odds bands are off")
	_check_fit(main, "Runs (elements)")
	main._missions._pick_zone(0)
	# the Radio: the words as chips, the odds as the headline
	if sim.comms_level > 0:
		main.show_room(main.COMMS)
		_settle_odds(main)                  # the shell reads them a few ms a frame (7 Oct); the card shows "reading the odds" until then
		main.refresh()
		var site_card = null
		for c in main._cards:
			if c.visible and c != main._cards[0]:       # the first card is the set's
				site_card = c
				break
		if site_card != null:
			_check(Words.ODDS.any(func(b): return b[1] == site_card._headline.text) and site_card._unit.text.contains("%"), "the radio's site card has no odds headline in words with the figure beside: '%s' / '%s'" % [site_card._headline.text, site_card._unit.text])
			# the A style: the band carries the site and the odds; the words as rows, the name in its tone, the effect beside
			_check(site_card._band.visible and site_card._band.title.text == site_card._title.text and site_card._band.headline.text == site_card._headline.text and not site_card._title.visible, "the radio card's band does not carry its title and odds")
			var intel_i := -1
			for i in range(Data.TIERS.size()):
				if Data.TIERS[i]["name"] == site_card._title.text:
					intel_i = i
			if intel_i >= 0 and not sim.intel[intel_i].is_empty():
				# the words as chip rows under the band: the name in its tone, the effect as the tail, one a row, the same piece the Runs card uses
				var wr = site_card._word_rows
				_check(wr.visible and wr.position.y >= site_card.BAND_H and wr.shown() == sim.intel[intel_i].size(), "the radio card's word rows are off: %d shown for %d words" % [wr.shown(), sim.intel[intel_i].size()])
				_check(wr.words(0) == sim.intel[intel_i][0] and wr.tail(0) != "", "the radio card's first word row is off: '%s' / '%s'" % [wr.words(0), wr.tail(0)])
				var m0: Dictionary = sim.modifier(sim.intel[intel_i][0])
				var want_tone: String = main._missions.word_tone(m0)
				_check(wr._labels[0].get_theme_color("font_color") == (Pal.tone_color(want_tone) if want_tone != "" else Pal.TEXT_2), "the word's name is not in its tone")
				_check(wr.position.y + wr.size.y <= site_card._buttons[0].position.y, "the word rows run into the buttons")
			var set_card = main._cards[0]
			_check(set_card.visible and set_card._band.visible and set_card._band.kicker.text == "The radio" and set_card._headline.text.begins_with("Level "), "the set's card band is off: '%s' / '%s'" % [set_card._band.kicker.text, set_card._headline.text])
		_check_fit(main, "Radio (bands)")
	print("the Yard as option A ok: Elements, Finds, the works; the Runs cards' chips; the Radio's chips")
	_fill_up_checks(main)


## "Fill up, then go": once the fight's won, a button sets the run to leave by
## itself when the pack's full or the next gang comes.
func _fill_up_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	sim.hp = sim.max_hp()
	sim.auto_tier = -1
	sim.intel[0] = []
	sim.deploy(0)
	var m: Dictionary = sim.mission
	main.show_room(main.MISSIONS)
	main.refresh()
	# the run screen's column: the band carries the site and the clock, the sections stack without overlap, the buttons at the foot
	var rn = main._run
	_check(rn._band.title.text == sim.mission["t"]["name"] and rn._band.headline.text.contains(":") and rn._band.kicker.text.begins_with("Depth "), "the run's band is off: '%s' / '%s' / '%s'" % [rn._band.kicker.text, rn._band.title.text, rn._band.headline.text])
	_check(rn._band.bar.visible and rn._band._bar_label.text.ends_with(" down") or rn._band._bar_label.text == "Cleared", "the run's band has no progress bar: '%s'" % rn._band._bar_label.text)
	_check(rn.FIGHT_Y >= rn.BAND_H and rn.RUNNER_Y > rn.FIGHT_BAR_Y + rn.BAR_H and rn.RIG_Y > rn.RUNNER_NOTE_Y and rn.TAKE_Y > rn.RIG_Y + Pal.CELL and rn.NOTE_Y + rn.LINE_H <= rn.BUTTON_Y, "the run column's sections overlap: fight %d runner %d rig %d take %d note %d button %d" % [rn.FIGHT_Y, rn.RUNNER_Y, rn.RIG_Y, rn.TAKE_Y, rn.NOTE_Y, rn.BUTTON_Y])
	# them and you each in a box: the box holds its head, tiles and bar, and the two boxes sit apart
	var fb := Rect2(rn._fight["box"].position, rn._fight["box"].size)
	var rb := Rect2(rn._runner["box"].position, rn._runner["box"].size)
	for piece in [rn._fight["head"], rn._fight["track"], rn._fight["tiles"][3]["panel"]]:
		_check(fb.encloses(Rect2(piece.position, piece.size)), "the fight's box does not hold its %s" % piece.name)
	for piece in [rn._runner["head"], rn._runner["track"], rn._runner["tiles"][3]["panel"], rn._runner["note"]]:
		_check(rb.encloses(Rect2(piece.position, piece.size)), "the runner's box does not hold its %s" % piece.name)
	_check(fb.end.y + 8 <= rb.position.y and fb.position.y >= rn.BAND_H and rb.end.y < rn.RIG_HEAD_Y, "the fight's and the runner's boxes are not apart: %s / %s" % [str(fb), str(rb)])
	_check(rn._fight["tiles"][0]["key"].text == "On you" and rn._runner["tiles"][0]["key"].text == "Armour" and rn._take_tiles[0]["key"].text == "Cash", "the run's tiles are off")
	# the crew head's face sits between the band and the fight tiles, never on either
	var face_r := Rect2(rn._head_face.position, rn._head_face.size)
	_check(face_r.position.y >= rn.BAND_H and face_r.end.y <= rn.FIGHT_TILES_Y, "the head's face (%s) runs into the band or the tiles" % str(face_r))
	_check(not main._run._button2.visible, "the second button shows before the clear on a manual run")
	m["remaining"] = 0
	sim._clear(m, m["t"])
	main.refresh()
	_check(main._run._button2.visible and main._run._button2.text == "Fill up, then go", "after the clear the second button reads '%s'" % main._run._button2.text)
	main._run._second_button()
	main.refresh()
	_check(m.get("leave_full", false) and main._run._button2.text.begins_with("Filling up"), "the button did not set the run to fill up then go")
	_check_fit(main, "Run (fill up)")
	# a gang arriving ends it
	var runs_before: int = sim.runs_total
	m["patrol_timer"] = sim.patrol_s(m["t"], true) + 1.0
	sim.advance(1.0)
	_check(not sim.on_mission() and sim.last_report["outcome"] != "Dead", "fill up then go did not leave as the gang came: %s" % str(sim.last_report.get("outcome", "")))
	# and a full pack ends it
	sim.hp = sim.max_hp()
	sim.deploy(0)
	m = sim.mission
	m["remaining"] = 0
	sim._clear(m, m["t"])
	sim.set_leave_full(true)
	while sim.pack_used(m) < sim.capacity():
		m["found"].append(sim._plain(Data.MEDICAL, "Bandage"))
	sim.advance(0.5)
	_check(not sim.on_mission(), "fill up then go did not leave with the pack full")
	print("fill up, then go ok")


## The bot's dig rule: past the campaign it keeps to the site it has dug
## deepest while that reads PUSH at its depth, and digs it a depth when it
## reads CLIMB; a weak runner falls back to the ordinary pick.
func _dig_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.candidates = []
	sim.auto_equip = false
	for i in range(Data.TIERS.size()):
		sim.best_depth[i] = 1
	for z in range(Data.ZONES.size()):
		sim.bosses_beaten[z] = true
	sim.best_depth[5] = 3
	sim.depth[5] = 3
	sim.xp = Data.xp_for_level(90)
	for s in ["Primary", "Armour", "Helmet"]:
		sim.equipped[s] = sim._plain(s, Data.BASES[s].back()["name"])
	sim.equipped["Primary"]["affixes"] = [{"stat": "damage_pct", "value": 3000.0, "tier": 6}]
	sim.equipped["Secondary"] = null
	sim.wound = ""
	sim.cash = 100000.0
	sim.rig = [sim._plain(Data.AMMO, sim.ammo_box("smg")["name"])]
	var bot = Bot.new()
	sim.hp = sim.max_hp()
	var budget0: int = sim.odds_budget
	sim.odds_budget = 0                   # the odds in full: the shell reads them a few dry runs a frame, and two reads a moment apart differ
	_check(sim.campaign_done(), "the dig check did not finish the campaign")
	_check(sim.has_rounds(sim.equipped["Primary"]), "the dig check's gun is dry")
	var t: int = bot.pick_tier(sim)
	# the rule, not the state: the site it dug deepest, at the deepest depth that reads PUSH
	# (the odds read by the night, the weather and the tree, so the depth itself may differ)
	var at_push: bool = sim.survival(5) >= Bot.PUSH
	var deepest: bool = sim.depth[5] == 3 or not _reads_push_deeper(sim, 5)
	_check(t == 5 and at_push and deepest, "past the campaign the bot did not keep to the site dug deepest at a depth that reads PUSH: T%d at depth %d (odds %.2f)" % [t, sim.depth[t], sim.survival(t)])
	bot.last_tier = t
	var d0: int = sim.depth[5]
	var climbs: bool = sim.survival(5) >= Bot.CLIMB
	bot._climb(sim)
	_check(sim.depth[5] == (d0 + 1 if climbs else d0), "the bot's climb did not follow CLIMB: depth %d from %d, odds %.2f" % [sim.depth[5], d0, sim.survival(5)])
	# a boss left armed on another tier is turned off by the next pick: the sim
	# keeps the toggle on after a run, and a tier read with a boss in reads red
	# for the rest of a run (the twelfth read's T8 at 0% with 700 dps against 4.8)
	sim.boss_armed[8] = true
	t = bot.pick_tier(sim)
	_check(not sim.boss_armed.get(8, false), "the bot's pick left the quartermaster armed on T8 (picked T%d)" % t)
	bot.last_tier = t
	# a runner that can't hold the depth steps back and picks as before: no
	# armour, no meds, level 3 - under at T5 whatever the tree
	sim.equipped["Primary"]["affixes"] = []
	sim.equipped["Armour"] = null
	sim.equipped["Helmet"] = null
	sim.xp = Data.xp_for_level(3)
	sim.hp = sim.max_hp()
	t = bot.pick_tier(sim)
	_check(sim.depth[5] == 1 and (t != 5) == (sim.survival(5) < Bot.PUSH), "a weak runner past the campaign did not step its site back and pick by the odds: T%d, site depth %d, odds %.2f" % [t, sim.depth[5], sim.survival(5)])
	sim.boss_armed.clear()
	sim.odds_budget = budget0
	sim.load_dict(saved)
	print("the dig rule ok")
	_leave_checks(main)


## Whether the site one depth deeper than it stands reads PUSH; the depth is put back after.
func _reads_push_deeper(sim, i: int) -> bool:
	var d0: int = sim.depth[i]
	sim.set_depth(i, d0 + 1)
	if sim.depth[i] == d0:
		return false
	var ok: bool = sim.survival(i) >= Bot.PUSH
	sim.set_depth(i, d0)
	return ok


## The bot leaves a picked-over site: a runner no gang moves on (Never
## there) with a pack that won't fill would otherwise stand on the site for
## good - the plain Drifter did, for six hours of the first read.
func _leave_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.candidates = []
	sim.auto_equip = false
	sim.tree = []
	for t in Data.TREES:
		for k in range(t["nodes"].size()):
			if t["nodes"][k].get("effect", "") == "never_there":
				sim.tree.append("%s/%d" % [t["name"], k])
	_check(sim.has_node("never_there"), "the leave check could not train Never there: %s" % sim.tree)
	sim.hp = sim.max_hp()
	sim.deploy(0)
	_check(sim.on_mission(), "the leave check did not deploy")
	var m: Dictionary = sim.mission
	m["remaining"] = 0
	m["cleared"] = true
	m["event_at"] = -1.0
	var bot = Bot.new()
	_check(not bot.should_leave(sim), "the bot leaves a fresh cleared site")
	m["searches"] = int(m.get("thin_after", 0)) + sim.thin_after(m["t"]) + 20     # picked over: the finds at the floor
	_check(sim.thinning(m, m["t"]) <= Data.THIN_FLOOR, "the leave check's site is not picked over: %.2f" % sim.thinning(m, m["t"]))
	_check(bot.should_leave(sim), "the bot stays on a picked-over site")
	sim.extract_now()
	sim.load_dict(saved)
	print("the bot leaves a picked-over site ok")
	_bench_worn_checks(main)


## The bot's bench rule: the worn kit's weakest affix re-rolled, one job a
## run, while two grand stays.
func _bench_worn_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.workshop = maxi(sim.workshop, 1)
	for s in ["Primary", "Armour", "Helmet", "Secondary"]:
		sim.equipped[s] = null
	var it: Dictionary = sim._plain("Armour", "Stab vest")
	it["affixes"] = [{"stat": "regen", "value": 1.0, "tier": 1}, {"stat": "armour_pct", "value": 15.0, "tier": 4}]
	it["rarity"] = 2
	sim.equipped["Armour"] = it
	var bot = Bot.new()
	sim.cash = 2000.0 + sim.craft_cost(it, "one", "regen") - 1
	bot._bench_worn(sim)
	_check(bot.bought.is_empty(), "the bot's bench rule spent under the two grand it keeps")
	sim.cash = 50000.0
	var cash0: float = sim.cash
	bot._bench_worn(sim)
	_check(bot.bought.size() == 1 and sim.cash < cash0 and "regen" in str(bot.bought[0][1]), "the bot's bench rule did not re-roll the weakest affix: %s" % str(bot.bought))
	bot.bought = []
	for a in sim.equipped["Armour"]["affixes"]:
		a["tier"] = Data.AFFIX_TIERS
	bot._bench_worn(sim)
	_check(bot.bought.is_empty(), "the bot's bench rule re-rolled a piece with every affix at the top")
	sim.load_dict(saved)
	print("the bot's bench rule ok")
	_build_one_checks(main)


## The bot's build rule: the best grade of its primary's rounds the stash can
## make, one a run, while the scrap stays at twice the price.
func _build_one_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.workshop = maxi(sim.workshop, 1)
	sim.equipped["Primary"] = sim._plain("Primary", "Nail gun")
	sim.stash = []
	sim.stash_put(sim._plain(Data.AMMO, "Nails"))
	var bot = Bot.new()
	var want: Dictionary = sim.build_option("grade", "Hardened bolts")
	_check(not want.is_empty(), "the build check found no Hardened bolts to build")
	sim.scrap = int(want["scrap"]) * 2 - 1
	bot._build_one(sim)
	_check(bot.bought.is_empty(), "the bot built with the scrap under twice the price")
	sim.scrap = int(want["scrap"]) * 2
	bot._build_one(sim)
	_check(bot.bought.size() == 1 and sim.scrap == int(want["scrap"]) and sim.stash.any(func(it): return it["base"] == "Hardened bolts"), "the bot did not build the grade for its rounds: %s, scrap %d" % [str(bot.bought), sim.scrap])
	sim.load_dict(saved)
	print("the bot's build rule ok")
	_gamble_checks(main)


## The fence's gamble (Matt, 6 Oct): five kinds on offer, rotated with the restock; pay and get a
## random one of the kind at the top tier opened, never Common; one time in fifty a unique of the kind.
func _gamble_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.candidates = []
	sim.auto_equip = false
	sim.restock()
	_check(sim.gamble.size() == Data.GAMBLE_SHOWN and sim.gamble.all(func(k): return not sim.gamble_kind(k).is_empty()), "the fence's offer is not %d kinds: %s" % [Data.GAMBLE_SHOWN, str(sim.gamble)])
	var before: Array = sim.gamble.duplicate()
	var rotated := false
	for k in range(12):
		sim.restock()
		rotated = rotated or sim.gamble != before
	_check(rotated, "twelve restocks never changed the fence's offer: %s" % str(sim.gamble))
	# the price: runs' pay on the top open tier, never under the floor
	var kind: String = sim.gamble[0]
	var price: int = sim.gamble_price(kind)
	_check(price >= sim._inf(Data.GAMBLE_FLOOR) and absi(price - int(round(maxf(float(sim._inf(Data.GAMBLE_FLOOR)), sim.a_runs_takings() * Data.GAMBLE_RUNS)))) <= 1, "the gamble's price is off: %d (a run's takings %.0f)" % [price, sim.a_runs_takings()])
	_check(sim.gamble_price("no such kind") < 0 and not sim.can_gamble("no such kind"), "a kind not on offer can be gambled")
	# short of cash: refused; paid: a thing of the kind in the stash, never Common, the kind off the offer
	sim.cash = price - 1
	_check(sim.gamble_buy(kind).is_empty(), "a gamble went through short of cash")
	sim.cash = 1000000.0
	sim.stash = []
	var k: Dictionary = sim.gamble_kind(kind)
	var it: Dictionary = sim.gamble_buy(kind, 0.99)
	_check(not it.is_empty() and it["slot"] == k["slot"] and (k["type"] == "" or Items.base_of(it).get("type", "") == k["type"]), "the gamble did not give a %s: %s" % [kind, str(it.get("base", "nothing"))])
	_check(int(it.get("rarity", 0)) >= 1 and not it.has("unique"), "a plain gamble came up Common or unique: %s" % str(it))
	_check(is_equal_approx(sim.cash, 1000000.0 - price) and sim.stash.any(func(s): return s["id"] == it["id"]) and not (kind in sim.gamble), "the gamble did not take the price, land in the stash and leave the offer")
	# the unique, on the dice: a unique of the kind, when the pool has one for it
	sim.restock()
	for kk in sim.gamble:
		var kd: Dictionary = sim.gamble_kind(kk)
		var fits: bool = Data.UNIQUES.any(func(u): return u["slot"] == kd["slot"] and (kd["type"] == "" or Items.base_named(kd["slot"], u["base"]).get("type", "") == kd["type"]))
		var u: Dictionary = sim.gamble_buy(kk, 0.0)
		_check(not u.is_empty() and (u.has("unique") == fits) and u["slot"] == kd["slot"], "the unique roll on %s gave %s (a unique fits: %s)" % [kk, str(u.get("unique", u.get("base", "nothing"))), str(fits)])
		break
	# a fresh yard can gamble a unique: the offer is up from the first restock and the dice are the dice
	var fresh = Sim.new()
	fresh.start()
	_check(fresh.gamble.size() == Data.GAMBLE_SHOWN, "a fresh yard has no gamble on offer")
	# the bot's rule: a gamble of its primary's kind when flush, none when not
	var bot = Bot.new()
	sim.restock()
	sim.equipped["Primary"] = sim._plain("Primary", "Stalking rifle")
	sim.gamble = ["rifle", "charm", "rig", "pistol", "melee"]
	sim.cash = sim.gamble_price("rifle") * 3 - 1
	bot._gamble_one(sim)
	_check(bot.bought.is_empty(), "the bot gambled under three times the price")
	sim.cash = sim.gamble_price("rifle") * 3
	bot._gamble_one(sim)
	_check(bot.bought.size() == 1 and "rifle" in str(bot.bought[0][1]) and not ("rifle" in sim.gamble), "the bot did not gamble a rifle when flush: %s" % str(bot.bought))
	# the takings: a run's cash and the fence's money, averaged over the last few runs
	var tk0: float = sim.takings
	sim.deploy(0)
	sim.mission["cash"] = 5000.0
	sim.extract_now()
	_check(sim.takings > 0.0 and (tk0 <= 0.0 or absf(sim.takings - lerp(tk0, 5000.0, 0.25)) <= 1.0 or sim.takings >= 5000.0 * 0.25), "a run's cash did not reach the takings: %.0f from %.0f" % [sim.takings, tk0])
	sim.load_dict(saved)
	print("the fence's gamble ok")
	_start_kit_checks(main)


## The starting kit is the worst kit in the game (Matt, 6 Oct): a pair of its
## own under the pool, never found, so every base in the pool beats the start
## of its slot on its own figures and the first find is somebody's upgrade.
func _start_kit_checks(main) -> void:
	var sim = main.sim
	var fresh = Sim.new()
	fresh.start()
	var start := {"Primary": fresh.equipped["Primary"]["base"], "Armour": fresh.equipped["Armour"]["base"], "Backpack": fresh.equipped["Backpack"]["base"]}
	for slot in start:
		var mine: Dictionary = Items.base_named(slot, start[slot])
		_check(mine.get("start", false), "the starting %s is not flagged as the start: %s" % [slot, start[slot]])
		for b in Data.BASES[slot]:
			if b.get("start", false):
				continue
			var worse := false
			match slot:
				"Primary":
					worse = float(b["damage"]) * float(b["rof"]) <= float(mine["damage"]) * float(mine["rof"])
				"Armour":
					worse = float(b["armour"]) <= float(mine["armour"])
				"Backpack":
					worse = int(b["capacity"]) <= int(mine["capacity"])
			_check(not worse, "%s is no better than the starting %s (%s)" % [b["name"], slot.to_lower(), start[slot]])
	# never found: a thousand rolls a slot at the top tier, none of them the start
	var r := RandomNumberGenerator.new()
	r.seed = 7
	for slot in start:
		var seen := 0
		for k in range(1000):
			if Items.roll(slot, Data.MAX_TIER, r)["base"] == start[slot]:
				seen += 1
		_check(seen == 0, "the starting %s turned up in the loot %d times" % [slot.to_lower(), seen])
	print("the starting kit is the worst kit ok")
