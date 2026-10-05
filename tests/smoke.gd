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
	root.add_child(main)
	main.new_game()
	var sim = main.sim
	sim.set_class("Doorman")
	_check(sim.cls == "Doorman", "sim.cls == 'Doorman'")
	_check(sim.cash == float(Data.STARTING_CASH), "sim.cash == float(Data.STARTING_CASH)")
	_check(sim.equipped["Primary"] != null, "sim.equipped['Primary'] != null")
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
	while not sim.rig_room(1) and sim.rig.size() > 0 and sim.stash_room(1):
		sim.leave(sim.rig.back()["id"])     # room for the drop
	var dropped := false
	var any_med := false
	for it in sim.stash:
		any_med = any_med or Items.is_medical(it) or Items.is_ammo(it)
	if not any_med:
		sim.stash.append(sim._plain("Medical", "Bandage"))      # the run may have used them all
	for k in range(sim.stash.size()):
		var it: Dictionary = sim.stash[k]
		if (Items.is_medical(it) or Items.is_ammo(it)) and sim.rig_room(Items.size(it)):
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
	if sim.equipped["Primary"] != null and sim.workshop > 0:
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
	var slot: String = main.SLOT_FILE % 1
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
	for r in range(4):
		sim.sell_rarity(r)            # room in the stash, or auto-run stops at once
	sim.set_auto(0)
	var before: Dictionary = sim.snapshot()
	main._settle_away(3.0 * 3600.0)
	var after: Dictionary = sim.snapshot()
	_check(is_equal_approx(after["elapsed"] - before["elapsed"], 3.0 * 3600.0), "three hours away did not pass three hours")
	_check(after["cash"] != before["cash"] or after["stash"] != before["stash"] or after["lost"] != before["lost"],
			"three hours away with auto-run on changed nothing")
	_check(sim.auto_tier == 0 or sim.auto_tier == -1, "auto_tier after the time away")
	_check(main._menu.visible and main._menu._title.text == Words.AWAY["title"] and main._menu._sub.text.begins_with("Gone ") and main._menu._sub.text.contains(" run"), "the away report is not in the voice: '%s' / '%s'" % [main._menu._title.text, main._menu._sub.text])
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
	_check(main._menu._sub.text.begins_with("Gone ") and main._menu._sub.text.contains("slept") and main._menu._sub.text.contains("kept going for"), "the rested report is not in the voice: '%s'" % main._menu._sub.text)
	_check_fit(main, "Back, then (rested)")
	main._menu.close()
	# a saved stamp two hours old goes through the away screen on load
	var f := FileAccess.open(main.SAVE_FILE, FileAccess.WRITE)
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
	var stamp_before: Dictionary = main._read_save(main.SAVE_FILE)
	main.save_game()
	_check(main._read_save(main.SAVE_FILE).get("saved", 0.0) == stamp_before.get("saved", 0.0), "a lost camp still saved")
	main.refresh()
	_check_fit(main, "Camp (lost)")
	main.show_camp_lost()
	_check(not FileAccess.file_exists(main.SAVE_FILE), "the lost camp's autosave was not removed")
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
	it["rarity"] = 3
	it["value"] = int(round(base["value"] * Data.RARITIES[3]["value"]))
	it["affixes"] = []
	for a in Data.AFFIXES:
		if slot in a["slots"] and it["affixes"].size() < 3:
			it["affixes"].append({"stat": a["stat"], "value": int(a["max"])})
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
	if k >= 0 and sim.rig_room(1):
		main._clinic._stash._pick(k)
		main.refresh()
		_check_fit(main, "Clinic (med pick)")
		var rig_before: int = sim.rig.size()
		main._clinic._press(0)          # Take
		_check(sim.rig.size() == rig_before + 1, "Take through the clinic did not take")
		main.refresh()
		_check_fit(main, "Clinic (rig)")
		main._clinic._press(0)          # Leave the last taken
		_check(sim.rig.size() == rig_before, "Leave through the clinic did not leave")
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
	# the endgame: campaign done, depth 2 everywhere, every site in a band
	_finish_campaign(sim)
	var band_lo := 1e9
	var band_hi := 0.0
	for i in range(Data.TIERS.size()):
		sim.set_depth(i, 2)
		_check(sim.depth[i] == 2, "depth 2 did not open at %s after the campaign" % Data.TIERS[i]["name"])
		sim.intel[i] = []                       # the shape alone, without the word on it
		var e: Dictionary = sim.effective(i)
		var work: float = e["hp"] * e["pool"] * e["dps"]        # how hard the fight is, roughly
		band_lo = minf(band_lo, work)
		band_hi = maxf(band_hi, work)
	_check(band_hi / band_lo < 3.0, "at depth 2 the sites' fights differ by ×%.1f; the endgame is a ladder again" % (band_hi / band_lo))
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
	main.show_room(main.BARRACKS)
	main.refresh()
	_check(main._barracks._past.text != "", "the Caravan does not show the runners before")
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
	main.show_room(main.MEDIC)
	main.refresh()
	_check(main._clinic._line != "", "the medic said nothing")
	_check_fit(main, "Clinic (said)")
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
	var m: Dictionary = sim.mission
	# the grid is the container: a pack of N cells shows N outlines, no more,
	# unless the packing reaches past them - and then exactly as far as it reached
	_check_grid(main._run._inv, sim.capacity(), "the pack")
	var first: Dictionary = m["found"][0]
	var n_before: int = m["found"].size()
	main._run._inv._pick(main._run._inv.cell_of(first["id"]))
	main.refresh()
	_check(main._run._ditch.visible, "picking a find did not offer Ditch")
	_check_fit(main, "Run (pick)")
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
	_check(Items.headline(charm)[0] == "+28%" and Items.headline(charm)[1] == "magic find", "a charm's headline is not its magic find: %s" % str(Items.headline(charm)))
	var worn_find: float = sim._affix_sum("rarity_pct") - 10.0     # the helmet's, if any
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
	_check(sim.strip("Primary", "socket 2") and sim.stash.has(salt), "strip() did not take the salt back")
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
	_check(main._workshop._craft_title.text == "Pick a piece", "the Craft view does not ask for a piece first: %s" % main._workshop._craft_title.text)
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
	var dealt: float = sim._dot_tick(m["dots"], 1.0)
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
	sim.load_dict(saved)
	print("the elements ok: affinities, double cost, the locked keystone and the second past, Spreads, Frozen solid, Builds, Won't stop, the class notables, the Caravan")
	_melee_checks(main)


## Melee: no rounds, bleed built in, grip and head mounts, in among them.
func _melee_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	var bat: Dictionary = sim._plain("Primary", "Spiked bat")
	_check(Items.is_melee(bat) and Items.ammo_words(bat) == "Takes nothing" and bat["attachments"].has("grip") and bat["attachments"].has("head"), "a spiked bat is not a melee weapon with a grip and a head")
	var old = sim.equipped["Primary"]
	sim.equipped["Primary"] = sim._plain("Primary", "Nail gun")
	var bleed0: float = sim.conversion()["bleed"]          # whatever the rest of the kit and the web add already
	sim.equipped["Primary"] = bat
	sim.rig = []
	_check(sim.has_rounds(bat) and sim.dps() > 0.0, "a bat ran dry")
	_check(is_equal_approx(sim.conversion()["bleed"], bleed0 + 0.2) or sim.conversion()["physical"] <= 0.001, "the bat's nails are not 20%% bleed on top of %.2f: %s" % [bleed0, str(sim.conversion())])
	var head: Dictionary = sim._plain("Attachment", "Nails through it")
	bat["attachments"]["head"] = head
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
	_check(labels[0] == "Grip" and labels[1] == "Head" and labels[2] == "—", "the bat's rows are %s" % str(labels))
	_check_fit(main, "Workshop (a bat)")
	main._workshop._pick_row("Primary", 0)
	_check(main._workshop.sel_mount == "grip", "picking the first row did not pick the grip")
	main._workshop._pick_cell(0)
	main._workshop._press(0)
	_check(bat["attachments"]["grip"] != null and bat["attachments"]["grip"]["mount"] == "grip", "a grip part did not fit the grip")
	_check_fit(main, "Workshop (a bat, taped)")
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
	_check(main._armoury._left_lines[4].text.begins_with("The council's · 4 of 4"), "the panel's set line is '%s'" % main._armoury._left_lines[4].text)
	_check_fit(main, "Armoury (a set)")
	# the army's: contact down one, more ×1.3 at four
	for s in Data.SLOTS:
		sim.equipped[s] = null
	var army: Dictionary = Items.set_named("The army's")
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
	_check(sim.set_pieces_at(1).is_empty() and sim.set_pieces_at(5).size() == 6 and sim.set_pieces_at(12).size() == 12 and sim.set_pieces_at(15).size() == 16, "the sets' depth gates are off: %d / %d / %d / %d" % [sim.set_pieces_at(1).size(), sim.set_pieces_at(5).size(), sim.set_pieces_at(12).size(), sim.set_pieces_at(15).size()])
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
	_check(sim.rank_atlas("word_travels") and sim.juice_cost(0) == cost0 / 2, "Word travels did not halve the call-in")
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
	sim.extract_now()
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
	_check(sim.notes == n0 + sim.capacity() * 3, "the lorry's load did not fill the empty pack with notes: +%d of %d" % [sim.notes - n0, sim.capacity() * 3])
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
	var low := 0
	var best := 0
	for i in range(300):
		var g: Dictionary = Items.roll("Primary", 1, sim.rng, 2.0, true, false, "", "", 0.33, 0)
		for a in g["affixes"]:
			_check(a.has("tier") and a["tier"] == 1, "a tier-1 base at depth 0 rolled T%d" % a.get("tier", 0))
		var deep: Dictionary = Items.roll("Primary", 6, sim.rng, 2.0, true, false, "", "", 0.33, 20)
		_check(deep["ilvl"] == deep["tier"] + 20, "the item level is not the base's tier plus the depth")
		for a in deep["affixes"]:
			low += 1 if a["tier"] == 1 else 0
			best += 1 if a["tier"] == 5 else 0
	_check(best > 5 and low > best, "deep drops rolled %d T5 and %d T1; some T5, more T1 was the aim" % [best, low])
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
	_check(it["rarity"] == 3 and it["affixes"].size() == 3, "adding to the top did not make an elite with three: %d, %d" % [it["rarity"], it["affixes"].size()])
	var stats := []
	for a in it["affixes"]:
		_check(not (a["stat"] in stats), "an affix doubled: %s" % a["stat"])
		stats.append(a["stat"])
	# lock one: it stays, the others may change
	var keep: Dictionary = it["affixes"][0].duplicate()
	var lock_cost: int = sim.craft_cost(it, "lock", keep["stat"])
	_check(lock_cost == sim._inf(Data.CRAFT["lock"]["cash"] * 16 * 4), "lock on a level-16 elite costs %d, not %d" % [lock_cost, sim._inf(Data.CRAFT["lock"]["cash"] * 16 * 4)])
	_check(sim.craft(it["id"], "lock", keep["stat"]) and it["affixes"].size() == 3 and it["affixes"][0] == keep, "locking one did not keep it: %s vs %s" % [str(it["affixes"][0]), str(keep)])
	# re-roll one: the stat stays, the tier moves sometimes, dearer the better the tier
	var one_stat: String = it["affixes"][1]["stat"]
	var tiers_seen := {}
	for k in range(60):
		sim.craft(it["id"], "one", one_stat)
		_check(it["affixes"][1]["stat"] == one_stat, "re-rolling one changed its stat")
		tiers_seen[int(it["affixes"][1]["tier"])] = true
	_check(tiers_seen.size() >= 2, "sixty re-rolls of one never moved its tier: %s" % str(tiers_seen.keys()))
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
	_check(sim.craft_cost(ch, "add") < 0 and sim.craft_cost(ch, "socket") < 0, "a charm takes an affix or a socket at the bench")
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
	main._open_bench_picks(it["id"])
	_check(main._menu.visible, "the picks page did not open")
	_check_fit(main, "Armoury (bench picks)")
	main._open_bench_one(it["id"], it["affixes"][0]["stat"])
	_check_fit(main, "Armoury (bench one)")
	main._menu.close()
	# the affix list on the panel, with tiers
	main._armoury.selected = {"kind": "stash", "id": it["id"]}
	main.refresh()
	_check(main._armoury._left_lines[2].text.contains("· T"), "the panel's affix line has no tier: '%s'" % main._armoury._left_lines[2].text)
	_check_fit(main, "Armoury (affix list)")
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
	_check(str(sim.events.back()[1]).begins_with("The yard's trade came too: the rat man"), "the trade had no line: %s" % str(sim.events.back()))
	_check(str(sim.events[-2][1]).begins_with("The yard moves"), "the move had no line")
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
		if mids[i].get("drawer", false):
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
	_check(main._barracks._heads[1]["name"].text.contains("page 1 of 4") or main._barracks._heads[1]["name"].text.contains("p1/4"), "a full drawer has no pages: %s" % main._barracks._heads[1]["name"].text)
	_check_fit(main, "Caravan (the drawer, full)")
	main._barracks._pick("drawer/0")
	_check(main._barracks.drawer_page == 1 and main._barracks._rows[1][0]["name"].text == "7. A mortgage offer", "a click did not turn the page: %d, %s" % [main._barracks.drawer_page, main._barracks._rows[1][0]["name"].text])
	_check_fit(main, "Caravan (the drawer, page 2)")
	main._barracks.mid = 0
	main._barracks.drawer_page = 0
	main._barracks._shown = ""
	main.refresh()
	_check_fit(main, "Caravan (back from the drawer)")
	var d: Dictionary = sim.to_dict()
	sim.load_dict(d)
	_check(sim.book.size() == 20, "the book did not save")
	sim.load_dict(saved)
	print("the book ok: twenty pages, the deep ones gated, read once in order, the drawer, its pages, saved")


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
	for r in c["intel"]:
		names.append(r[0].text)
	_check("Rain" in names and "Night" in names, "the card does not show the sky's words: %s" % str(names))
	_check(c["intel_note"].text.begins_with("23:00, night, raining"), "the card's clock line is off: %s" % c["intel_note"].text)
	_check(c["lines"][4][0].text == "The site" and c["lines"][4][1].text.begins_with("Picked over"), "the card does not say the site is picked over: %s %s" % [c["lines"][4][0].text, c["lines"][4][1].text])
	_check_fit(main, "Runs (night, rain, picked over)")
	var d: Dictionary = sim.to_dict()
	sim.load_dict(d)
	_check(sim.weather[0] == "Rain" and sim.wear(0) > 0.9, "the sky and the wear did not save")
	sim.load_dict(saved)
	print("the places changing ok: picked over and back, the clock's night, rain and fog by zone, never on the radio, the card")


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
	var c1: int = sim.juice_cost(0)
	sim.best_depth[0] = 5
	sim.set_depth(0, 4)
	_check(sim.juice_cost(0) == c1 * 4, "a call-in at depth 4 is not four times depth 1: %d vs %d" % [sim.juice_cost(0), c1])
	sim.intel[0] = ["Numbers", "Night"]
	_check(sim.juice_cost(0) == c1 * 4 * 3, "two words on the site did not treble the call-in: %d" % sim.juice_cost(0))
	sim.atlas_points = 1
	sim.rank_atlas("word_travels")
	_check(sim.juice_cost(0) == c1 * 4 * 3 / 2, "Word travels did not halve it: %d" % sim.juice_cost(0))
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
	var ticked: float = sim._dot_tick(dots, 1.0)
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
	_check(main._armoury._left_lines[1].text.begins_with("Takes shells"), "the Lock-up's panel does not say the shotgun takes shells: '%s'" % main._armoury._left_lines[1].text)
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
	sim.deploy(0)
	for k in range(20):
		sim.advance(1.0)
	_check(sim.on_mission() and sim.rounds_for(sim.equipped["Primary"]) < before, "the nail gun fired twenty seconds and spent no rounds")
	sim.extract_now()
	sim.rig = []
	_check(sim.dps() < with_rounds * 0.5, "a gun with no rounds still fires: %.1f against %.1f" % [sim.dps(), with_rounds])
	sim.rig.append(sim._plain(Data.AMMO, "Hardened bolts"))
	_check(sim.dps() > with_rounds, "the better grade did not add damage")
	sim.cash += 1000.0
	while not sim.stash_room(1) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])                 # room for the box
	var n_before: int = sim.stash.size()
	_check(sim.buy_ammo("shotgun") and sim.stash.size() == n_before + 1 and Items.is_ammo(sim.stash.back()), "a box from the fence did not land in the stash")
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
			var best: Array = sim.attachments_for(mount)
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
		if Items.is_attachment(it) or Items.is_medical(it) or Items.is_ammo(it):
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
		if Items.is_attachment(it) or Items.is_medical(it) or Items.is_ammo(it):
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
				if n["button"].visible and n["name"].position.y == n["effect"].position.y:   # stacked branch nodes aren't a pair
					pairs.append([n["name"], n["effect"]])
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
	var rail_nodes := []
	for name in main.ROOMS:
		var b = main._rail_buttons[name]
		rail_nodes.append_array(b.text_nodes())
		if b.badge_gap() < 8.0:
			push_error("rail %s: badge overlaps the name" % name)
			bad += 1
	bad += _check_nodes(rail_nodes, [], where + " rail")
	bad += _check_nodes(main._top_labels.values(), [], where + " top bar")
	_misfits += bad


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
