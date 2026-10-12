extends SceneTree
## A headless smoke test: godot --headless --path . -s tests/smoke.gd
## Builds the shell, starts a camp, has a crude bot run missions, gear up and
## sell, shows every room along the way and checks every label fits its box,
## then round-trips the save. Exit 1 if anything doesn't fit.

const Data := preload("res://scripts/sim/data.gd")
const StatsRoom := preload("res://scripts/ui/stats_room.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")
const Items := preload("res://scripts/sim/items.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Words := preload("res://scripts/sim/words.gd")
const Bot := preload("res://tests/bot.gd")
const PickPanel := preload("res://scripts/ui/pick_panel.gd")
const PlaytestRead := preload("res://tools/playtest_summary.gd")
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
	for path in paths.duplicate():
		paths.append(path.get_basename() + ".record.jsonl")     # the playtest records beside them (11 Oct)
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


## A Yard pick set straight in (9 Oct): for the checks that set the Yard up rather than buy it. side "" clears it.
func _yard_set(s, key: String, col: int, side: String) -> void:
	var sides: Array = s.yard_picks.get(key, ["", "", "", "", ""]).duplicate()
	sides[col] = side
	var before: Dictionary = s._yard_before()
	s.yard_picks[key] = sides
	s._yard_changed(key)
	s._yard_grew(before)


## A primary base of a gun type: the first in the list.
func _base_of_type(ty: String) -> String:
	for b in Data.BASES["Primary"]:
		if b.get("type", "") == ty:
			return b["name"]
	return ""


## A class change for a check that isn't about its price (9 Oct: a change costs the respec of the class
## trees): the price handed over first, so the cash after is what it was.
## A tree's capstone by its index, and the nodes behind it (12 Oct: a node beside the capstone comes after it in the list).
func _cap_idx(tree_name: String) -> int:
	var nodes: Array = Data.tree_named(tree_name)["nodes"]
	for k in range(nodes.size()):
		if nodes[k].get("capstone", false):
			return k
	return nodes.size() - 1


func _behind_cap(tree_name: String) -> Array:
	var out: Array = []
	var nodes: Array = Data.tree_named(tree_name)["nodes"]
	for k in range(nodes.size()):
		if not nodes[k].get("capstone", false) and not nodes[k].get("beside", false):
			out.append(k)
	return out


## The Outskirts (12 Oct): a zone before the Estate, three sites, no crew. A new yard starts there and the Streets
## wait on it; it's done with its three cleared; a site's level reads past it; a save from before is moved up three;
## Runs has the four zones and no map, the Radio has the map.
func _outskirts_checks(main) -> void:
	var sim = main.sim
	_check(Data.ZONES.size() == 4 and Data.ZONES[0]["name"] == "The Outskirts" and Data.ZONES[0]["tiers"] == [0, 1, 2] and Data.TIERS[3]["name"] == "Ransacked Streets" and Data.TIERS[2]["name"] == "Top Farm", "the Outskirts are not first")
	for i in range(Data.TIERS.size()):
		_check(Data.ZONES[int(Data.TIERS[i]["zone"])]["tiers"].has(i), "%s is not in its zone's list" % Data.TIERS[i]["name"])
		_check(Words.SITES.has(Data.TIERS[i]["name"]), "%s has no words" % Data.TIERS[i]["name"])
	_check(Data.TIERS[Data.BANK]["name"] == "The Bank" and Data.TIERS[Data.CONVOY_TIER]["name"] == "The Services", "the Bank or the Services moved off its index")
	for b in Data.BOSSES:
		_check(int(Data.TIERS[int(b["tier"])]["zone"]) == int(b["zone"]) and int(b["zone"]) >= 1, "%s is not at his own zone's site" % b["name"])
	var fresh = Sim.new()
	fresh.start()
	_check(fresh.tier_open(0) and not fresh.tier_open(1) and not fresh.tier_open(3) and fresh.zone_open(0) and not fresh.zone_open(1), "a new yard does not start at the Allotments alone")
	fresh.best_depth[0] = 1
	fresh.best_depth[1] = 1
	_check(fresh.tier_open(2) and not fresh.zone_open(1), "the Estate opened before Top Farm was cleared")
	fresh.best_depth[2] = 1
	_check(fresh.zone_complete(0) and fresh.zone_open(1) and fresh.tier_open(3) and fresh.zone_boss(0).is_empty(), "the Outskirts cleared did not open the Estate (it has no crew)")
	_check(Sim.lv_at(3, 1) == 1 and Sim.lv_at(11, 1) == 9 and Sim.lv_at(0, 1) == 1 and Sim.lv_at(0, 6) == 3, "a site's level does not read past the Outskirts")
	_check(fresh.salvage_kinds().is_empty(), "the Outskirts drop salvage")
	# a save from before the Outskirts: nine sites, three zones, the Bank at 5
	var old := {"depth": [2, 1, 1, 1, 1, 1, 1, 1, 3], "best_depth": [2, 1, 1, 1, 1, 1, 0, 0, 0], "words": [[], [], [], [], [], [], [], [], []],
		"sealed": [false, false, false, false, false, false, false, false, true], "worn": [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0],
		"worn_depth": [1, 1, 1, 1, 1, 1, 1, 1, 1], "boss_paid": [[], [], [], [], [], [], [], [], []], "weather": ["Rain", "", ""], "bosses_beaten": [true, false, false],
		"best_tier": 6, "auto_tier": 5, "last_report": {"tier": 5, "outcome": "Extracted"}, "best_dig": {"site": "The Bank", "tier": 5, "depth": 2}}
	Sim._shift_sites(old)
	_check(old["depth"] == [1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3] and old["best_depth"].slice(0, 3) == [1, 1, 1] and old["sealed"][11] and old["weather"] == ["", "Rain", "", ""] and old["bosses_beaten"] == [true, true, false, false], "the old save's lists did not move up: %s" % str(old["depth"]))
	_check(int(old["best_tier"]) == 9 and int(old["auto_tier"]) == 8 and int(old["last_report"]["tier"]) == 8 and int(old["best_dig"]["tier"]) == 8 and int(old["sites_v"]) == Sim.SITES_V, "the old save's site numbers did not move up three")
	var again: Dictionary = old.duplicate(true)
	Sim._shift_sites(again)
	_check(again == old, "a moved save moved twice")
	# Runs: the four zones, the Outskirts first, no map; the Radio has it
	main.show_room(main.MISSIONS)
	_check(main._missions._zone_buttons.size() == 4 and main._missions._zone_buttons[0].text.begins_with("The Outskirts"), "Runs does not show the four zones with the Outskirts first")
	main.show_room(main.COMMS)
	main.refresh()
	_check(main._radio._views.size() == 2 and (main._radio._views[1].disabled == not sim.campaign_done()), "the Radio's map button does not follow the campaign")
	_check_fit(main, "Radio (twelve sites)")
	print("the Outskirts ok: first, three sites, no crew, the Estate after, levels, the old save moved, Runs' four zones, the Radio's map")


## The map, on the Radio (12 Oct: it moved there from Runs as the Outskirts took its tab).
func _open_map(main) -> void:
	main.show_room(main.COMMS)
	main._radio._pick_view("map")
	main.refresh()


func _set_cls(s, name: String) -> void:
	var c: int = s.class_change_cost(name)
	s.cash += c
	if not s.set_class(name):
		s.cash -= c


## A class through the Training screen: two presses when the change costs, one when it's free.
func _press_class(main, name: String) -> void:
	var s = main.sim
	var c: int = s.class_change_cost(name)
	s.cash += c
	main._barracks._pick_class(name)
	if main._barracks._armed == name:
		main._barracks._pick_class(name)
	if s.cls != name:
		s.cash -= c


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
	_set_cls(sim, "Doorman")
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
			if guard == 5 and runs == 0 and sim.on_mission() and not sim.searching():
				# the damage line moves with the fight (8 Oct): what landed this second is on the mission, and the
				# line eased toward it sits somewhere other than the Yard's share
				_check(float(sim.mission.get("landed_rate", 0.0)) > 0.0, "a fight five seconds in has landed nothing a second")
				var at_rest: float = main._dps_share()
				for k in range(30):
					main._move_dps_line(0.1)
				var shown: float = main._top_lines["dps"][1].size.x / main._top_lines["dps"][0].size.x
				# eased to what lands, not left at the Yard's share: the share scaled by landed over the sheet's figure (a
				# fight landing near the sheet's figure barely moves it - the old "moved by 0.01" test flaked there, 10 Oct)
				var want: float = minf(at_rest * clampf(float(sim.mission["landed_rate"]) / maxf(sim.dps(), 1.0), 0.0, 1.6), 1.0)
				_check(absf(shown - want) < 0.005, "the damage line reads %.3f mid-fight, not %.3f (the Yard's share %.2f, %.1f landing a second against %.1f)" % [shown, want, at_rest, float(sim.mission["landed_rate"]), sim.dps()])
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
	# rounds that feed both guns: one short line, not both names (10 Oct: "the hand-me-down nail gun and the flare pistol" ran past)
	var held_guns: Array = [sim.equipped["Primary"], sim.equipped["Secondary"]]
	sim.equipped["Primary"] = sim._plain("Primary", "Hand-me-down nail gun")
	sim.equipped["Secondary"] = sim._plain("Secondary", "Flare pistol")
	if Items.ammo_type(sim.equipped["Primary"]) == Items.ammo_type(sim.equipped["Secondary"]):
		var nails: Dictionary = sim._plain(Data.AMMO, "Nails")
		sim.stash.append(nails)
		main.refresh()
		main._armoury._pick_cell(main._armoury._inv.cell_of(nails["id"]))
		main.refresh()
		_check_fit(main, "Armoury (rounds for both guns)")
		sim.stash.erase(nails)
	sim.equipped["Primary"] = held_guns[0]
	sim.equipped["Secondary"] = held_guns[1]
	main.refresh()
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
	_outskirts_checks(main)
	# the Clinic screen: a med bought from the shelf, taken into the rig, left again
	_clinic_screen(main)
	# the Missions screen: depth up and deploy through it; the Docks once open
	main.show_room(main.MISSIONS)
	_check_fit(main, "Missions (screen)")
	if sim.zone_complete(1):
		main._missions._pick_zone(2)
		_check_fit(main, "Missions (Town)")
		_check(main._missions.zone == 2, "the Town did not open after the Estate's boss")
		main._missions._pick_zone(1)
	elif sim.depot_cleared:
		_check(not sim.zone_open(2), "the Town opened without the Estate's boss beaten")
	if not sim.on_mission():
		var d0: int = sim.depth[3]
		main._missions._depth(0, 1)
		_check(sim.depth[3] == (mini(d0 + 1, sim.best_depth[3] + 1) if sim.campaign_done() else 1), "depth + through the screen (campaign %s)" % str(sim.campaign_done()))
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
	print("%d attachments fitted" % fitted_before)
	if sim.equipped["Primary"] != null and sim.equipped["Primary"]["attachments"].has("optic"):
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
	# the Radio (9 Oct, map juicing): nothing on the air until the depths open
	main.show_room(main.COMMS)
	_check(main._radio.visible and not main._grid.visible, "the Radio is not its own screen")
	_check_fit(main, "Radio")
	_check(sim.campaign_done() or (sim.words_known().is_empty() and not sim.juiceable(3) and not sim.can_word_craft(3, "tune")), "the Radio has words before the depths open")
	# the Barracks screen: select, respec, train through it
	main.show_room(main.BARRACKS)
	_check_fit(main, "Barracks")
	print("tree: %d of %d points trained, %s" % [sim.tree.size(), sim.training_points, str(sim.tree.slice(0, 3))])
	main._barracks._pick("The Yard/0")
	_check_fit(main, "Barracks (pick)")
	# the points read "N of M points free" top right, the panel says whose the node is, and no node's words are the old "for every runner the Yard sends"
	_check(main._barracks._points.text.begins_with("%d of %d" % [sim.points_free(), sim.training_points]), "the points line reads '%s'" % main._barracks._points.text)
	_check(not main._barracks._past.visible, "a node's strip still carries the runners before")
	_sum_strip_check(main)
	_check(not main._barracks._words.text.contains("the Yard sends"), "a plain node still says 'for every runner the Yard sends'")
	if sim.cls != "":
		var first_class_tree: Dictionary = sim.trees()[0]
		main._barracks._pick("%s/0" % first_class_tree["name"])
		_check_fit(main, "Barracks (class node)")
	for t in Data.TREES:
		for nd in t["nodes"]:
			if nd.has("words"):
				_check(not str(nd["words"]).contains("Out when") and not str(nd["words"]).contains("picking over"), "a node's words still read oddly: '%s'" % nd["words"])
	_press_class(main, "Paramedic")
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
		sim.deploy(3)
		sim.advance(1.0)
		_check(sim.mission == null or sim.mission["using"] != null or sim.rig.is_empty(), "the Medic did not use a med")
		if sim.on_mission():
			sim.extract_now()
		print("medic auto-use ok")
	_press_class(main, "Doorman")
	if sim.cash >= sim.respec_cost() and not sim.tree.is_empty():
		main._barracks._on_respec()
		_check(sim.tree.is_empty(), "respec did not clear the tree")
		main._barracks._pick("The Yard/0")
		main._barracks._on_train()
		_check(sim.tree.has("The Yard/0"), "Train through the screen did not train")
		print("barracks respec and train ok")
	_check_fit(main, "Barracks (after)")
	_class_trees(main)
	# auto-run: ten minutes on tier 1 with the toggle on, then off
	sim.set_auto(3)
	_check(sim.auto_tier == 3, "sim.auto_tier == 3")
	sim.advance(600.0)
	print("auto-run: %s, last: %s" % ["still on" if sim.auto_tier == 3 else "stopped", main.sim.events.back()[1]])
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
	_refresh_toggle_checks(main)
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
	_record_file_checks(main)
	# the player's own saves are as they were, and the smoke's are gone
	_check(_player_saves() == _player_saves_before, "the smoke touched the player's saves: %s -> %s" % [str(_player_saves_before), str(_player_saves())])
	for path in [SMOKE_SAVE, SMOKE_SLOT % 1, SMOKE_SLOT % 2, SMOKE_SLOT % 3]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	for f in DirAccess.get_files_at("user://"):
		if f.begins_with("smoke_") and f.contains(".record"):
			DirAccess.remove_absolute("user://" + f)
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
	_check(main._menu.shape() == ("title" if main._menu._picture.texture != null else "card"), "the title's shape is %s" % main._menu.shape())
	_check_fit(main, "Title")
	main._menu.close()
	sim = main.sim
	# away three hours with auto-run on: missions ran, the log moved, the clock moved
	sim.set_depth(3, 1)
	for r in range(Data.RARITIES.size()):
		sim.sell_rarity(r)            # room in the stash, or auto-run stops at once
	sim.set_auto(3)
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
	# the lost camp's screen: the card on the plain ground with its heading and words up (not the title's column, 8 Oct)
	main.show_camp_lost()
	_check(main._menu.visible and main._menu.shape() == "card" and main._menu._title.text == "The Yard is lost" and main._menu.sub().ends_with("gone with the runner."), "the lost camp's words are not up: %s / '%s' / '%s'" % [main._menu.shape(), main._menu._title.text, main._menu.sub()])
	_check(not main._menu._picture.visible and main._menu._backdrop.visible, "the lost camp's card is not on the plain ground")
	_check_fit(main, "Camp (lost, the screen)")
	main._menu.close()
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


## The random items the bot found are never the worst. This fills the Yard
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
	for pk in [["stash", 0], ["stash", 1], ["stash", 3], ["stash", 4], ["fence", 0], ["fence", 1]]:
		_yard_set(sim, pk[0], pk[1], "b" if pk[1] == 4 else "a")       # the worst case: the biggest stash and shelf there are
	sim.stash = []
	for it in worst:
		if sim.stash_room(Items.size(it)):
			sim.stash.append(it.duplicate(true))
	sim.market = []
	for it in worst:
		if sim.market.size() < sim.market_stock() and not Items.is_medical(it):
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
	# a full rig that wraps its rows (seven bandages, then a two-pouch kit that can't cross the row's end): the
	# pouches shrink until its rows fit under the loadout (10 Oct)
	var rig_hold: Array = sim.rig.duplicate(true)
	var pack_hold = sim.equipped["Backpack"]
	var rig_slot_hold = sim.equipped["Rig"]
	sim.equipped["Backpack"] = _worst_item("Backpack", Data.BASES["Backpack"].back(), sim)
	var big_rig: Dictionary = _worst_item("Rig", Data.BASES["Rig"].back(), sim)
	big_rig["affixes"].append({"stat": "capacity", "value": 24.0, "tier": 1})     # the sim's cap: 24 pouches
	sim.equipped["Rig"] = big_rig
	sim.rig = []
	var wraps := true
	while wraps:
		wraps = false
		for i in range(7):
			if sim.rig_room(1):
				sim.rig.append(sim._plain(Data.MEDICAL, "Bandage"))
				wraps = true
		if sim.rig_room(2):
			sim.rig.append(sim._plain(Data.MEDICAL, "First aid kit"))
			wraps = true
	main.show_room(main.ARMOURY)
	main.refresh()
	var ct = main._armoury._containers
	_check(ct.rig_inside() and main._armoury.CONTAINERS_Y + ct.size.y <= Pal.ROOM_H, "a wrapped full rig runs out of its room: pouches %.0f px" % ct.rig_cell())
	_check(ct._rig_zone.size.y >= 3 * ct.rig_cell(), "the wrapped rig is not the crowded case: %.0f px of rows" % ct._rig_zone.size.y)     # three rows or more: the case that ran out
	_check(not ct.has_method("pack_inside") and not ct.has_method("pack_cell"), "the Lock-up still draws the pack's map (Matt, 10 Oct: removed)")
	for rc in ct._rig_cells:
		if rc.visible:
			for l in rc.text_nodes():
				if l.visible and l.text != "":
					_check(Rect2(Vector2.ZERO, rc.size).grow(0.5).encloses(Rect2(l.position, l.size)), "a pouch's words spill out of its %s cell: '%s'" % [str(rc.size), l.text])
	_check_fit(main, "Lock-up (a wrapped rig, the deepest pack)")
	# the worst wrap: four-pouch kits among singles, and rounds in the thousands - the smallest pouches, their words
	# and counts inside them (the reviewer, 10 Oct)
	sim.rig = []
	var more := true
	while more:
		more = false
		for i in range(5):
			if sim.rig_room(1):
				sim.rig.append(sim._plain(Data.MEDICAL, "Bandage"))
				more = true
		var kit: Dictionary = sim._plain(Data.MEDICAL, "Surgeon's kit")
		if sim.rig_room(Items.size(kit)):
			sim.rig.append(kit)
			more = true
	var rounds: Dictionary = sim._plain(Data.AMMO, "Nails")
	rounds["rounds"] = 2500
	if not sim.rig.is_empty():
		sim.rig[0] = rounds
	main.refresh()
	_check(ct.rig_inside(), "the worst wrap runs out of its room at %.0f px pouches" % ct.rig_cell())
	for rc in ct._rig_cells:
		if rc.visible:
			for l in rc.text_nodes():
				if l.visible and l.text != "":
					_check(UI.text_width(l, l.text) <= l.size.x + 0.5 and Rect2(Vector2.ZERO, rc.size).grow(0.5).encloses(Rect2(l.position, l.size)), "a %s pouch's '%s' doesn't fit: %.0f px of text in %s at %s" % [str(rc.size), l.text, UI.text_width(l, l.text), str(l.size), str(l.position)])
	_check_fit(main, "Lock-up (the worst wrap)")
	sim.rig = rig_hold
	sim.equipped["Backpack"] = pack_hold
	sim.equipped["Rig"] = rig_slot_hold
	main.refresh()
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
	sim.set_depth(3, 1)
	sim.deploy(3)
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
	_check(sim.clinic.size() > 0 and sim.clinic.size() <= sim.clinic_stock(), "the Clinic's shelf is empty or over its stock")
	var it: Dictionary = sim.clinic[0]
	main._clinic._shelf._pick(main._clinic._shelf.cell_of(it["id"]))
	main.refresh()
	_check_fit(main, "Clinic (shelf pick)")
	var shelf_before: int = sim.clinic.size()
	main._clinic._press(0)              # Buy
	_check(sim.clinic.size() == shelf_before - 1 or not sim.stash_room(1), "Buy off the Clinic's shelf did not buy, or the shelf did not shrink")
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
		_check(sim.rig.size() == rig_before + 1, "Take through the Clinic did not take")
		main.refresh()
		_check_fit(main, "Clinic (rig)")
		# leaving is the Lock-up's (the Clinic's empty panel acts on nothing)
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
		_check(fh.visible and not main._fence._left_title.visible and fh._title.text != "" and fh._figure.text != "" and fh._chips[0].visible, "the Fence's pick has no head: %s / %s" % [fh._title.text, fh._figure.text])
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
	# the Fence's word (the gamble, Matt, 6 Oct): the fourth tab, five kinds with a price, Pay through the screen, the last word under them
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
		_check(left == 0, "Sell commons through the screen left %d: %s" % [left, str(sim.stash.filter(func(x): return x["rarity"] == 0).map(func(x): return x["base"]))])
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
	_check(sim.zone_open(1) and not sim.zone_open(2), "the Town opened with every Estate site cleared but its boss standing")
	_check(not sim.campaign_done(), "the campaign read as done with no boss beaten")
	sim.set_depth(3, 2)
	_check(sim.depth[3] == 1, "depth 2 opened before the campaign")
	sim.hp = sim.max_hp()
	# the Estate's boss, free, from the Retail Park
	_check(sim.boss_cost(5) == 0, "the first boss fight is not free")
	_check(sim.can_arm_boss(5), "the Estate's boss could not be armed")
	sim.arm_boss(5, true)
	var t: Dictionary = sim.effective(5)
	_check(t.has("boss") and t["boss"]["hp"] > t["hp"], "arming the boss did not put them in the fight")
	sim.deploy(5)
	_check(sim.on_mission() and sim.mission.has("boss"), "the boss did not come on the run")
	_check(not sim.boss_armed.get(2, false), "the boss stayed armed past the deploy: arming is one run, like the insurance")
	# through the pool with a big gun, then the boss
	var guard := 0
	while sim.on_mission() and sim.mission["remaining"] > 0 and guard < 20000:
		sim.hp = sim.max_hp()
		sim.mission["clock"] = 900.0            # the test wants the boss, not the clock
		sim.advance(1.0)
		guard += 1
	_check(sim.on_mission() and sim.mission["boss"]["started"], "the boss did not come out when the pool was down")
	guard = 0
	while sim.on_mission() and sim.mission["boss"]["alive"] and guard < 20000:
		sim.hp = sim.max_hp()
		sim.mission["clock"] = 900.0
		sim.advance(1.0)
		guard += 1
	_check(sim.on_mission() and not sim.mission["boss"]["alive"], "the boss did not go down")
	_check(sim.bosses_beaten[1], "beating the boss did not mark the zone")
	var dropped := false
	for it in sim.mission["found"]:
		if it.has("unique") and it["unique"] in sim.boss_of(5)["uniques"]:
			dropped = true
	_check(dropped, "the boss dropped nothing of their own")
	_check(int(sim.mission.get("notes", 0)) > 0, "the run carried no notes")
	var notes_before: int = sim.notes
	sim.extract_now()
	_check(sim.notes > notes_before, "the notes did not come home")
	_check(sim.zone_open(2), "the Town did not open with the Estate's boss down")
	_check(sim.boss_cost(5) > 0, "the second boss fight is free")
	# the endgame: campaign done, depth 2 everywhere; the sites are nine ladders now (7 Oct): each site's
	# depth 2 harder than the one before it in the campaign's order, the city's a good deal harder than the estate's
	_finish_campaign(sim)
	var last_work := 0.0
	var work_lo := 1e9
	var work_hi := 0.0
	for i in range(Data.TIERS.size()):
		sim.set_depth(i, 2)
		_check(sim.depth[i] == 2, "depth 2 did not open at %s after the campaign" % Data.TIERS[i]["name"])
		sim.words[i] = []                       # the shape alone, without the word on it
		var e: Dictionary = sim.effective(i)
		var work: float = e["hp"] * e["dps"]       # how hard one of them is: the level's curve, bent by the shape
		_check(work >= last_work * 0.8, "at depth 2 %s reads easier than the site before it: %.0f after %.0f" % [Data.TIERS[i]["name"], work, last_work])
		last_work = work
		work_lo = minf(work_lo, work)
		work_hi = maxf(work_hi, work)
	_check(work_hi / work_lo > 3.0, "at depth 2 the sites' fights differ by only ×%.1f; the ladders are not nine" % (work_hi / work_lo))
	# the boss costs notes now
	sim.notes = 0
	_check(not sim.can_arm_boss(5), "a boss was armed with no notes")
	sim.notes = 1000
	_check(sim.can_arm_boss(5), "a boss could not be armed with notes in hand")
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
## tier, papers among the finds, the deeds from the Bank and the three ends
## of them, the runners' past after a death, the vendors' lines.
func _narrative_checks(main) -> void:
	var sim = main.sim
	# the deeds: a fresh camp walked straight to the Bank
	var save: Dictionary = sim.to_dict()
	_finish_campaign(sim)
	sim.hp = sim.max_hp()
	var bank: int = Data.BANK
	_check(sim.tier_open(bank), "the Bank did not open with every depth cleared")
	sim.seen.erase("%d/1" % bank)              # the bot's run may have walked it already
	sim.deploy(bank)
	_check(sim.on_mission(), "could not set off for the Bank")
	_check(sim.events.back()[1] == Words.site_line("The Bank", 1), "setting off for the Bank gave no site line: %s" % sim.events.back()[1])
	sim._clear(sim.mission, sim.mission["t"])
	var deeds := {}
	for it in sim.mission["found"]:
		if Items.is_deeds(it):
			deeds = it
	_check(not deeds.is_empty(), "clearing the Bank did not drop the deeds (found before %s, tier %d, BANK %d, seen %s)" % [str(sim.deeds_found), int(sim.mission["tier"]), Data.BANK, str(sim.seen.keys().filter(func(k): return str(k).begins_with("%d/" % Data.BANK) or str(k).begins_with("cleared/")))])
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
	sim.deploy(3)
	var lost_before: int = sim.past.size()
	sim._kia()
	_check(sim.past.size() == lost_before + 1 and sim.past.back().has("end"), "a death did not write the runner into the past")
	# a death takes the runner's past with them: the class unpicked, its trees back as points, the Yard's tree kept
	var fresh2 = load("res://scripts/sim/sim.gd").new()
	fresh2.start()
	_set_cls(fresh2, "Doorman")
	fresh2.training_points = 8
	var elem_tree: String = Data.ELEMENT_TREES[0]["name"]
	_check(fresh2.train_node("Muscle/0") and fresh2.train_node("Muscle/1") and fresh2.train_node("The Yard/0") and fresh2.train_node("%s/0" % elem_tree), "the death test could not train")
	var spent: int = fresh2.points_spent()
	fresh2.deploy(0)
	fresh2._kia()
	_check(fresh2.cls == "" and fresh2.cls2 == "", "a death left the class picked: '%s'" % fresh2.cls)
	_check(fresh2.tree == ["The Yard/0"], "a death did not refund the runner's trees (the class's and the element's) and keep the Yard's: %s" % str(fresh2.tree))
	_check(fresh2.points_free() == 8 - fresh2.points_spent() and fresh2.points_spent() < spent, "the refunded points are not free to spend: %d free" % fresh2.points_free())
	_check(fresh2.next_words() == Words.NEXT["past"], "after a death the Yard does not say to pick a past: '%s'" % fresh2.next_words())
	_check(str(fresh2.events.back()[1]).contains("point") or str(fresh2.events[-2][1]).contains("point"), "the refund was not logged")
	main.show_room(main.BARRACKS)
	main._barracks.selected = ""
	main.refresh()
	_check(main._barracks._past.visible and main._barracks._past.text != "", "the Caravan does not show the runners before")
	_check_fit(main, "Caravan (past)")
	# papers: enough looks find one
	sim.hp = sim.max_hp()
	sim.deploy(3)
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
	_check(main._fence._line != "", "the Fence said nothing")
	_check_fit(main, "Fence (said)")
	# the A style on the vendors: the band with the face, the name and the figure; the line under it; the tabs in the band's foot; the sections
	var fv = main._fence
	# the rooms' one band across the top (10 Oct, Bands-U A): the kicker names the vendor, the figure in gold, no title line
	_check(fv._band.title.text == "" and fv._band.headline.text.begins_with("£") and fv._band.kicker.text.begins_with("The Fence · ") and fv._band.size == Vector2(Pal.GRID_W, Pal.BAND_H), "the Fence's band is off: '%s' / '%s' / '%s' %s" % [fv._band.kicker.text, fv._band.title.text, fv._band.headline.text, str(fv._band.size)])
	_check(fv._said[0].text != "" and fv._side.position.y + fv._said[0].position.y >= fv.BAND_H, "the Fence's line is not under the band: '%s' at %.0f" % [fv._said[0].text, fv._side.position.y + fv._said[0].position.y])
	var ftab_x := 0.0
	for t in fv._tabs:
		_check(t.position.x >= fv._band.kicker.position.x + Pal.BAND_TEXT_W and t.position.x + t.size.x <= Pal.GRID_W - fv.PAD + 0.5 and t.position.x >= ftab_x, "a fence tab is not at the band's foot, right, in order: %s" % str(Rect2(t.position, t.size)))
		ftab_x = t.position.x + t.size.x
	for t in fv._tabs:
		_check(t.position.y + t.size.y <= fv.BAND_H and t.visible, "a fence tab is not in the band's foot")
	_check(fv._side_tiles[0]["key"].text == "Com" and fv._side_tiles[Data.RARITIES.size() - 1]["key"].text == "Leg" and fv._side_tiles[Data.RARITIES.size()]["key"].text.begins_with("Nails") and fv._side_tiles[Data.RARITIES.size() + 5]["button"].visible, "the Fence's tiles are off: %s" % str(fv._side_tiles.map(func(t): return t["key"].text)))
	_check(fv._side_tiles[1]["value"].get_theme_color("font_color") == Pal.GOOD or fv._side_tiles[1]["button"].disabled, "the uncommon tile's figure is not green")
	_check(fv._heads[2].visible and fv._heads[2].text.begins_with("THE CONTRACTS"), "the Fence's contracts head is off: '%s'" % fv._heads[2].text)
	_check(fv._band.kicker.position.x >= fv._face.position.x + fv._face.size.x or not fv._face.visible, "the Fence's words sit on the face")
	main.show_room(main.MEDIC)
	main.refresh()
	_check(main._clinic._line != "", "the medic said nothing")
	_check_fit(main, "Clinic (said)")
	var cv = main._clinic
	_check(cv._band.title.text == "" and cv._band.kicker.text.begins_with("The Clinic") and cv._band.headline.text == "%d" % sim.hp_shown() and cv._band.unit.text.begins_with("of %d HP" % sim.max_hp_shown()), "the Clinic's band is off: '%s' / '%s' / '%s'" % [cv._band.title.text, cv._band.headline.text, cv._band.unit.text])
	_check(cv._side_track.visible and cv._side_bar_text.text.begins_with("Your HP") and cv._side_tiles_c[0]["key"].text == "Resting" and cv._side_tiles_c[1]["key"].text == "Heal" and cv._side_tiles_c[2]["key"].text == "The wound" and cv._side_tiles_c[3]["key"].text == "Clinic", "the Clinic's treatment tiles are off")
	_check(cv._heads[1].visible and cv._heads[1].text.begins_with("YOUR MEDS"), "the Clinic has no YOUR MEDS head")
	var med_kinds := {}
	for it in sim.stash:
		if Items.is_medical(it):
			med_kinds[it["base"]] = true
	var shown_meds: int = cv._med_tiles.filter(func(t): return t["panel"].visible and not t["key"].text.begins_with("The rig")).size()
	_check(shown_meds == mini(med_kinds.size(), 4), "the Clinic shows %d med kinds for %d in the stash" % [shown_meds, med_kinds.size()])
	for t in cv._med_tiles:
		if t["panel"].visible and not t["key"].text.begins_with("The rig"):
			_check(t["value"].text.begins_with("heals "), "a med tile does not say what it heals: '%s'" % t["value"].text)
	# a heal node trained elsewhere moves the Clinic's figures without anything else changing (the reviewer's catch)
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
			_check(cv._med_tiles[0]["value"].text != heal_before, "a heal node did not move the Clinic's med figure: still '%s'" % heal_before)
			sim.tree = hold_tree
			main.refresh()
	sim.load_dict(save)
	print("narrative ok: site lines, the deeds three ways, the past, papers, every item's words, the vendors")


func _run_screen(main) -> void:
	var sim = main.sim
	sim.auto_tier = -1
	sim.hp = sim.max_hp()
	sim.set_depth(3, 1)
	var tries := 0
	while tries < 5 and not (sim.on_mission() and sim.mission["found"].size() >= 2):
		if not sim.on_mission():
			sim.hp = sim.max_hp()
			sim.deploy(3)
		var guard := 0
		while sim.on_mission() and sim.mission["found"].size() < 2 and guard < 600:
			sim.mission["clock"] = 900.0         # the test wants the run, not the clock
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
	var was_clear: bool = sim.mission["cleared"] and not sim.mission.get("ghost_pending", false)
	main._run._get_out()
	if was_clear:
		_check(not sim.on_mission(), "Get out now did not end the run")
	else:
		_check(sim.on_mission() and sim.mission.get("way_out", false), "Get out now before the clear did not take the way out")
		sim.extract_now()
	print("run screen ok")


## The class trees: a class tree node trains, is refunded on a class change, a
## typed node idles without its gun, a keystone changes a rule, the Yard's
## upgrades buy.
func _class_trees(main) -> void:
	var sim = main.sim
	_set_cls(sim, "Doorman")
	sim.training_points += 20
	_check(sim.trees().size() == 3 + Data.ELEMENT_TREES.size() and sim.trees()[1]["name"] == "The Yard", "a Doorman does not see three trees with the Yard's in the middle, and the elements'")
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
	# a class change refunds the class trees and keeps the Yard's
	if not sim.tree.has("The Yard/0"):
		sim.training_points += 1
		sim.train_node("The Yard/0")
	_set_cls(sim, "Drifter")
	_check(not sim.tree.has("Muscle/0") and sim.tree.has("The Yard/0"), "changing class did not refund the class trees and keep the Yard's")
	_check(sim.points_spent() < spent_before, "the refund did not free the points")
	main.show_room(main.BARRACKS)
	_check_fit(main, "Caravan (Drifter)")
	# a keystone: Never there - no lot ever comes
	for i in range(8):
		sim.train_node("Moving on/%d" % i)
	_check(sim.tree.has("Moving on/6"), "the Drifter's keystone did not train: %d points free" % sim.points_free())
	_check(sim.patrol_s(sim.effective(3)) == INF, "Never there still has lots coming")
	main.show_room(main.BARRACKS)
	main._barracks._pick("Moving on/6")
	_check_fit(main, "Caravan (keystone)")
	sim.respec()
	_set_cls(sim, "Doorman")
	_radio_juice_checks(main)
	_clock_checks(main)
	_way_out_checks(main)
	_purse_checks(main)
	_backdrop_checks(main)
	_room_band_checks(main)
	_panel_words_checks(main)
	_rail_order_checks(main)
	_place_art_checks(main)
	# the Yard's upgrades
	sim.cash += 1000000.0                       # whatever inflation has done by now
	for k in ["generator", "lookout", "kennel"]:
		sim.yard_picks.erase(k)                 # the bot may have built them already
	sim._yard_changed("")
	_check(sim.yard_pick("generator", 0, "a") and sim.yard_pick("lookout", 0, "a") and sim.yard_pick("kennel", 0, "a"), "a yard pick did not buy: %s / %s / %s" % [sim.yard_pick_block("generator", 0, "a"), sim.yard_pick_block("lookout", 0, "a"), sim.yard_pick_block("kennel", 0, "a")])
	_check(sim.away_cap_s() == 12.0 * 3600.0, "Twelve hours did not raise the away cap")
	main.show_room(main.OVERVIEW)
	_check_fit(main, "The Yard (upgrades)")
	# every class's trees on the screen, for the fit check
	for c in Data.CLASSES:
		_set_cls(sim, c["name"])
		main.show_room(main.BARRACKS)
		_check_fit(main, "Caravan (%s)" % c["name"])
	_set_cls(sim, "Doorman")
	print("class trees, keystone and yard upgrades ok")
	_tree_rules_checks(main)
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
	# and the Bench can add an affix to one
	if sim.on_mission():
		sim.extract_now()
	var add_cost: int = sim.craft_cost(charm, "add")
	_check(add_cost > 0, "the Bench will not add an affix to a charm")
	sim.cash = maxf(sim.cash, add_cost + 1.0)
	var n_before: int = charm["affixes"].size()
	_check(sim.craft(charm["id"], "add", "") and charm["affixes"].size() == n_before + 1, "adding an affix to the charm did not take (mission %s, cost %d, cash %.0f)" % [str(sim.on_mission()), add_cost, sim.cash])
	# the body shows it in its own cell beside the primary
	main.show_room(main.ARMOURY)
	_check_fit(main, "Armoury (charm)")
	_check(main._armoury._body._boxes["Charm"]["cell"].visible, "the charm's cell is not shown on the body")
	# charms turn up among a site's finds
	var charms := 0
	sim.deploy(3)
	var m: Dictionary = sim.mission
	var eff: Dictionary = sim.effective(3)
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


## A refresh leaves every showing button showing (9 Oct): the card grid hid all eight cards and showed
## the used ones again ten times a second, and a hidden control drops its hover and any press in
## progress - the Radio's buttons flickered and took a click only now and then. Every room, the Radio
## with a tier open and its buttons up: one refresh, and no showing button - nor any control above it -
## may have lost and regained its visibility. Watched up the chain, not on the button alone: the smoke
## runs before the tree has drawn, where nothing reports visible in the tree and a hidden parent does
## not pass the change on to its buttons; `_showing` walks the flags the same way.
func _refresh_toggle_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	var saved_room: String = main.room
	sim.cash = maxf(sim.cash, 100000.0)
	var items: Array = []
	_all_items_under(main, items)
	var toggled := {}
	var counter := func(n): toggled[n] = true
	for n in items:
		n.visibility_changed.connect(counter.bind(n))
	# the watcher itself: a card hidden and shown must reach the counter here, or every room would pass on nothing
	var probe = main._cards[0]
	var was: bool = probe.visible
	probe.visible = not was
	probe.visible = was
	_check(toggled.has(probe), "the toggle watcher heard nothing from a card hidden and shown: the check would pass on nothing")
	toggled.clear()
	var radio_buttons := 0
	for r in main.ROOMS:
		main.show_room(r)
		main.refresh()
		toggled.clear()
		main.refresh()
		for n in items:
			if not (n is BaseButton) or not _showing(n):
				continue
			var q = n
			while q is CanvasItem and q != main:
				if toggled.has(q):
					_check(false, "%s: a refresh hid and showed '%s'%s (it drops the hover and a press in progress)" % [r, str(n.get("text")) if n.get("text") != null else str(n.name), "" if q == n else " by way of a %s above it" % q.get_class()])
					break
				q = q.get_parent()
		if r == main.COMMS:
			radio_buttons = items.filter(func(n): return n is BaseButton and _showing(n) and main._radio.is_ancestor_of(n)).size()
	for n in items:
		n.visibility_changed.disconnect(counter)
	_check(radio_buttons >= 1, "the Radio showed %d buttons: the check had nothing to look at" % radio_buttons)
	sim.load_dict(saved)
	main.show_room(saved_room)
	print("refresh toggles ok: every room, no showing button (or anything above it) hidden and shown again by a refresh")


## Every CanvasItem under n, shown or not (the toggle check connects them all before it changes room).
static func _all_items_under(n: Node, out: Array) -> void:
	if n is CanvasItem:
		out.append(n)
	for c in n.get_children():
		_all_items_under(c, out)


## The Workshop's Craft view: the stash's gear only, the panel reads the
## piece's tiers and prices, Bench opens the menu, everything fits.
func _craft_view_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	sim.cash = 100000.0
	var piece: Dictionary = Items.roll("Primary", 6, sim.rng, 12)
	piece["affixes"] = [{"stat": "hp", "value": 20.0, "tier": 2}, {"stat": "dps_pct", "value": 10.0, "tier": 1}]
	sim.stash.append(piece)
	main.show_room(main.WORKSHOP)
	main._workshop._set_view("craft")
	var ws = main._workshop
	_check(ws._piece.visible and ws._jobs.visible, "the Craft view's piece card or jobs are hidden")
	# the view buttons read white whichever is on (Guns started as a primary button and kept its dark text, 8 Oct)
	for v in ws._views:
		_check(v.get_theme_color("font_color") == Pal.TEXT, "the %s view button's text is not white" % v.text)
	_check(ws._piece_title.text.begins_with("Pick a piece"), "the Craft view does not ask for a piece first: %s" % ws._piece_title.text)
	_check(ws._job_tiles.all(func(t): return t["price"].text == "" and t["button"].disabled), "the job tiles carry prices with nothing picked")
	_check(ws._build.visible and ws._build.text == "Build for scrap" and not ws._build.disabled, "Build for scrap is not up with nothing picked")
	_check_fit(main, "Workshop (craft, nothing picked)")
	var shown: Array = ws._craftable()
	_check(not shown.is_empty() and shown.all(func(it): return not Items.is_attachment(it) and not Items.is_medical(it) and not it.has("unique")), "the Craft view's grid shows parts, meds or uniques")
	var k: int = shown.find(piece)
	if k < 0:
		for i in range(shown.size()):
			if is_same(shown[i], piece):
				k = i
	_check(k >= 0, "the rolled piece is not in the Craft view's grid")
	ws._pick_cell(k)
	_check(ws._piece_title.text != "Pick a piece", "picking a piece did not fill the piece card")
	_check(ws._piece_chips.words(1) == "Level %d" % Items.ilvl(piece), "the piece card's level chip is wrong: %s" % ws._piece_chips.words(1))
	_check(ws._affix_rows[0]["tag"].text == "T2" and ws._affix_rows[0]["label"].text.begins_with("+20"), "the first affix row does not read the affix and its tier: '%s' %s" % [ws._affix_rows[0]["label"].text, ws._affix_rows[0]["tag"].text])
	_check(ws._affix_rows[2]["label"].text == "No third affix", "the missing third affix's row is off: %s" % ws._affix_rows[2]["label"].text)
	_check(ws._job_tiles[0]["price"].text.begins_with("£") and not ws._job_tiles[0]["button"].disabled, "the re-roll tile is not priced and live: %s" % ws._job_tiles[0]["price"].text)
	_check(ws._job_tiles[4]["price"].text.ends_with("notes"), "the level tile is not priced in notes: %s" % ws._job_tiles[4]["price"].text)
	_check(ws._job_tiles[5]["price"].text.begins_with("+") and ws._job_tiles[5]["price"].text.ends_with("scrap"), "the scrap tile does not say what it gives: %s" % ws._job_tiles[5]["price"].text)
	_check(ws._affix_buttons.all(func(b): return not b.visible), "the affix jobs are up with no affix picked")
	_check_fit(main, "Workshop (craft, piece picked)")
	# an affix picked: its two jobs along the card's foot, inside the card
	ws._pick_affix(0)
	_check(ws.sel_stat == "hp" and ws._affix_buttons[0].visible and ws._affix_buttons[1].visible, "picking the first affix did not show its two jobs")
	_check(ws._affix_buttons[1].position.x + ws._affix_buttons[1].size.x <= ws.BODY_W - ws.PAD + 0.5, "the affix jobs run off the piece card")
	_check(ws._affix_buttons[0].text.contains("£") and ws._affix_buttons[1].text.contains("£"), "the affix jobs carry no price")
	_check_fit(main, "Workshop (craft, affix picked)")
	# the job runs in the room: a re-roll keeps the count, the foot says what was done
	var before_affixes: int = piece["affixes"].size()
	ws._press_job(0)
	var after: Dictionary = sim.item_by_id(piece["id"])
	_check(after.get("affixes", []).size() == before_affixes, "the re-roll in the room changed the affix count")
	_check(ws._foot.text.begins_with("Re-rolled") or ws._foot.get_theme_color("font_color") == Pal.GOOD, "the jobs' foot does not say what the Bench did: %s" % ws._foot.text)
	_check(not main._menu.visible, "a job in the room opened the menu")
	_check_fit(main, "Workshop (craft, after a job)")
	# scrap from the room: the piece goes, the foot says what it gave, nothing stays picked
	var scrap_before: int = sim.scrap
	var gave: int = sim.scrap_of(after)
	ws._press_job(5)
	_check(sim.item_by_id(piece["id"]).is_empty() and sim.scrap == scrap_before + gave, "the scrap tile did not scrap the piece for %d" % gave)
	_check(ws.sel_id == -1 and ws._piece_title.text.begins_with("Pick a piece") and ws._foot.text.begins_with("Scrapped"), "after scrapping: picked %d, title '%s', foot '%s'" % [ws.sel_id, ws._piece_title.text, ws._foot.text])
	_check_fit(main, "Workshop (craft, after scrapping)")
	ws._set_view("guns")
	_check(not ws._piece.visible and not ws._jobs.visible, "the piece card stayed up on the Guns view")
	sim.load_dict(saved)
	print("craft view ok: stash gear only, the piece card, the priced tiles, an affix's jobs, a job in the room")


## The trees' rules (9 Oct, docs/design/trees.md §8): the lanes match the table; every joint's two halves in
## the fourth column, open on one, closed on both, for its class alone; a class change's price and its two
## presses, free for a new runner; the camp's high-water mark; an old save's trees back as points, once.
func _tree_rules_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	var bk = main._barracks
	var table := {"Drifter": ["Moving on", "Petrol", "Luck", "Live", "The Yard"], "Scrapper": ["Stripping", "Live", "Fencing", "Petrol", "The Yard"],
		"Poacher": ["Stalking", "The rat man", "Snares", "The cold", "The Yard"], "Paramedic": ["Triage", "The rat man", "Shifts", "The cold", "The Yard"],
		"Doorman": ["Muscle", "Blades", "The door", "Knuckles", "The Yard"]}
	main.show_room(main.BARRACKS)
	for c in table:
		_set_cls(sim, c)
		bk.alt = ""
		bk._shown = ""
		main.refresh()
		var names: Array = bk.lane_trees().map(func(x): return x["name"] if x != null else "")
		_check(names == table[c], "the %s's lanes are %s, not the table's" % [c, str(names)])
		_check(bk._links[0]["chip"].visible and bk._links[1]["chip"].visible and bk._links[0]["label"].text.begins_with("⇄ OPEN"), "the %s's joints' links are not up and open: '%s'" % [c, bk._links[0]["label"].text])
	# a runner with no class: the Yard's lane alone, and the Also row
	sim.cls = ""
	sim.cls2 = ""
	sim.tree = []
	bk._shown = ""
	main.refresh()
	var bare: Array = bk.lane_trees().map(func(x): return x["name"] if x != null else "")
	_check(bare == ["The Yard", "", "", "", ""] and not bk._links[0]["chip"].visible and bk.also_names().has("Petrol"), "a runner with no past sees %s" % str(bare))
	_check_fit(main, "Caravan (no past)")
	# every joint
	for j in Data.JOINTS:
		var halves := []
		for tn in [j["tree"], j["element_tree"]]:
			var t: Dictionary = Data.tree_named(tn)
			var found := -1
			for i in range(t["nodes"].size()):
				if str(t["nodes"][i].get("joint", "")) == j["key"]:
					_check(found < 0, "%s holds two halves of %s" % [tn, j["key"]])
					found = i
			_check(found >= 0 and int(t["nodes"][found]["col"]) == Data.JOINT_COL and t["nodes"][found].get("notable", false), "%s's half of %s is not a fourth-column notable" % [tn, j["key"]])
			halves.append("%s/%d" % [tn, found])
		_check(Data.tree_named(j["tree"]).get("class", "") == j["class"] and str(sim.node(halves[1]).get("class", "")) == j["class"], "%s's halves are not the %s's" % [j["key"], j["class"]])
		sim.cls2 = ""
		sim.cls = j["class"]
		sim.tree = [halves[0]]
		_check(not sim.has_joint(j["key"]), "%s closed on its class half alone" % j["key"])
		sim.tree = [halves[1]]
		_check(not sim.has_joint(j["key"]), "%s closed on its element half alone" % j["key"])
		sim.tree = [halves[0], halves[1], "%s/6" % j["element_tree"]]
		_check(sim.has_joint(j["key"]) and sim.node_active("%s/6" % j["element_tree"]), "%s did not close with both halves, or its keystone did not work" % j["key"])
		for c in table:
			if c != j["class"]:
				sim.cls = c
				_check(not sim.has_joint(j["key"]) and not sim.node_active("%s/6" % j["element_tree"]), "%s closed for a %s" % [j["key"], c])
				break
	# a class change: free for a new runner; two presses and the class trees' respec for one with them trained
	sim.load_dict(saved)
	sim.cls = ""
	sim.cls2 = ""
	sim.tree = []
	sim.training_points = maxi(sim.training_points, 20)
	var cash0: float = sim.cash
	bk._shown = ""
	main.refresh()
	_check(sim.class_change_cost() == 0, "a new runner's pick has a price")
	# a new runner's pick keeps the Yard's tree and an element in the class's pair (the reviewer's catch: it threw them away)
	sim.tree = ["The Yard/0", "The rat man/0"]
	bk._pick_class("Poacher")
	_check(sim.cls == "Poacher" and is_equal_approx(sim.cash, cash0), "a new runner's pick took two presses or cost: %s, £%.0f" % [sim.cls, cash0 - sim.cash])
	_check(sim.tree.has("The Yard/0") and sim.tree.has("The rat man/0"), "a new runner's pick gave back the Yard's or the pair's nodes: %s" % str(sim.tree))
	sim.tree = []
	_check(sim.train_node("Stalking/0") and sim.train_node("Stalking/1") and sim.train_node("The Yard/0"), "the Poacher's first nodes did not train")
	var price: int = sim.class_change_cost("Doorman")
	_check(price > 0 and price == sim._inf((sim.node_cost("Stalking/0") + sim.node_cost("Stalking/1")) * Data.RESPEC_CASH), "the change's price is not the class trees' respec: £%d" % price)
	sim.cash = float(price + 100)
	bk._pick_class("Doorman")
	_check(sim.cls == "Poacher" and bk._armed == "Doorman" and bk._notice.text.contains("press again") and bk._notice.text.contains(Fmt.money(price)), "the first press changed the class or did not name the price: '%s'" % bk._notice.text)
	_check_fit(main, "Caravan (a change armed)")
	bk._pick_class("Doorman")
	_check(sim.cls == "Doorman" and is_equal_approx(sim.cash, 100.0) and not sim.tree.has("Stalking/0") and sim.tree.has("The Yard/0"), "the second press did not change for the price: %s, £%.0f, %s" % [sim.cls, sim.cash, str(sim.tree)])
	_check(sim.train_node("Muscle/0"), "the Doorman's first node did not train")
	sim.cash = 0.0
	bk._pick_class("Scrapper")
	_check(bk._notice.text.contains("short") and bk._notice.get_theme_color("font_color") == Pal.BAD, "a change the cash won't cover does not say so: '%s'" % bk._notice.text)
	_check_fit(main, "Caravan (a change short)")
	bk._pick_class("Scrapper")
	_check(sim.cls == "Doorman" and sim.tree.has("Muscle/0"), "a change went through without the cash")
	bk._pick(Data.COMMON_TREE + "/0")
	_check(bk._armed == "", "picking a node did not disarm the change")
	bk._pick_class("Scrapper")
	_set_cls(sim, "Paramedic")              # a change made elsewhere (a death, a move, the tests) disarms the screen's
	bk._shown = ""
	main.refresh()
	_check(bk._armed == "" and not bk._notice.text.contains("press again"), "an armed change outlived the class it was armed from: '%s'" % bk._notice.text)
	# what a change gives back: the class's trees, another class's half, an element off the new pair - never a debt
	sim.cash = 1e6
	_set_cls(sim, "Drifter")
	sim.training_points = maxi(sim.training_points, 80)
	for i in [0, 1, 2, 4, 3, 7, 5]:
		sim.train_node("Petrol/%d" % i)
	for i in [0, 1]:
		sim.train_node("Live/%d" % i)
	_check(sim.tree.has("Petrol/5"), "the Drifter's can did not train")
	var drops: Array = sim._change_drops("Poacher")
	_check(drops.has("Petrol/0") and drops.has("Live/0") and sim.class_change_cost("Poacher") > sim.class_change_cost(), "a change to a Poacher does not give back the Drifter's elements: %s" % str(drops))
	_check(sim._change_drops("Scrapper").has("Petrol/5") and not sim._change_drops("Scrapper").has("Petrol/0"), "a change to a Scrapper keeps the Drifter's half, or gives back the pair's element")
	_set_cls(sim, "Scrapper")
	_check(not sim.tree.has("Petrol/5") and sim.tree.has("Petrol/0") and sim.points_free() >= 0, "after the change: %s, %d free" % [str(sim.tree), sim.points_free()])
	_set_cls(sim, "Poacher")
	_check(not sim.tree.has("Petrol/0") and not sim.tree.has("Live/0") and sim.points_free() >= 0, "an element off the new pair stayed at double: %s, %d free" % [str(sim.tree), sim.points_free()])
	sim.xp = Data.xp_for_level(Data.ASCEND_LEVEL)
	_check(sim.set_second("Doorman") and not sim.set_class("Doorman") and sim.cls == "Poacher" and sim.cls2 == "Doorman", "a change to the second past's class went through")
	bk._shown = ""
	main.refresh()
	bk._pick_class("Doorman")
	_check(bk._armed == "" and bk._class_buttons[Data.CLASSES.map(func(c): return c["name"]).find("Doorman")].disabled, "the second past's class is offered as a change")
	# the camp's high-water mark: levels under the best earn nothing; past it, a point a level
	sim.load_dict(saved)
	sim.best_level = 10
	sim.xp = Data.xp_for_level(3)
	var pts0: int = sim.training_points
	var before: int = sim.level()
	sim.xp = Data.xp_for_level(9)
	sim._earn_points(before)
	_check(sim.training_points == pts0 and sim.best_level == 10, "a runner re-levelling under the camp's best earned %d points" % (sim.training_points - pts0))
	before = sim.level()
	sim.xp = Data.xp_for_level(12)
	sim._earn_points(before)
	_check(sim.training_points == pts0 + 2 and sim.best_level == 12, "past the camp's best a level did not earn a point: %d, best %d" % [sim.training_points - pts0, sim.best_level])
	# saves: the layout version and the best level go in; an old save's tree comes back as points, once
	sim.load_dict(saved)
	sim.tree = ["The Yard/0"]
	var d: Dictionary = sim.to_dict()
	_check(int(d.get("tree_v", 0)) == sim.TREE_V and d.has("best_level"), "the save has no layout version or best level")
	d["tree_v"] = 1
	sim.load_dict(d)
	_check(sim.tree.is_empty() and sim.points_free() == sim.training_points, "an old save's tree did not come back as points: %s" % str(sim.tree))
	sim.tree = ["The Yard/0"]
	sim.load_dict(sim.to_dict())
	_check(sim.tree == ["The Yard/0"], "a save from this layout was refunded again")
	d.erase("tree_v")
	d.erase("best_level")
	sim.load_dict(d)
	_check(sim.best_level == sim.level(), "an old save's best level is not its runner's: %d" % sim.best_level)
	sim.load_dict(saved)
	bk.alt = ""
	bk._armed = ""
	bk._shown = ""
	main.refresh()
	print("tree rules ok: the lanes, ten joints, a class change's price and presses, the high-water mark, the old saves")
	_joint_payoff_checks(main)


## Every joint's payoff (trees.md §3), read at the function it lives in, both halves trained straight into the
## tree; with the joint open each reads plain.
func _joint_payoff_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.cls2 = ""
	sim.words[3] = []
	sim.set_depth(3, 1)
	var close := func(key: String) -> void:
		var j: Dictionary = Data.joint(key)
		sim.cls = j["class"]
		sim.tree = []
		for tn in [j["tree"], j["element_tree"]]:
			var t: Dictionary = Data.tree_named(tn)
			for i in range(t["nodes"].size()):
				if str(t["nodes"][i].get("joint", "")) == key:
					sim.tree.append("%s/%d" % [tn, i])
	var fresh_run := func() -> Dictionary:
		if sim.on_mission():
			sim.extract_now()
		sim.hp = sim.max_hp()
		sim.deploy(3)
		sim.mission["dots"] = {}
		return sim.mission
	# the Drifter's fire: an SMG's hit lights them, a burn already there never shrinks, and a burning gang takes a quarter more
	close.call("drifter_fire")
	sim.equipped["Primary"] = sim._plain("Primary", _base_of_type("smg"))
	var m: Dictionary = fresh_run.call()
	_check(is_equal_approx(sim._joint_hit_mult(m, "smg"), 1.0), "the Drifter's joint added to a gang not burning")
	m["dots"]["fire"] = 500.0
	sim._joints_on_hit(m, m["t"], 10.0, "smg", 0.1)
	_check(float(m["dots"]["fire"]) >= 500.0 and is_equal_approx(sim._joint_hit_mult(m, "smg"), 1.25) and is_equal_approx(sim._joint_hit_mult(m, "rifle"), 1.0), "the Drifter's joint shrank the burn or missed the quarter: %.1f" % float(m["dots"]["fire"]))
	# the Drifter's shock: a shocked kill's drop rolls its rarity twice - more rare things over many kills
	close.call("drifter_shock")
	m = fresh_run.call()
	var counts := [0, 0]
	for shocked in [false, true]:
		sim.rng.seed = 4242
		for k in range(400):
			m["found"] = []
			m["kill_shocked"] = shocked
			sim._find(m, m["t"], true)
			for it in m["found"]:
				if it["slot"] in Data.SLOTS and int(it.get("rarity", 0)) >= 1:
					counts[1 if shocked else 0] += 1
	_check(counts[1] > counts[0], "a shocked kill's drops are no rarer: %d against %d" % [counts[1], counts[0]])
	# the Scrapper's shock: every improvised hit shocks
	close.call("scrapper_shock")
	m = fresh_run.call()
	m["shock_t"] = 0.0
	sim._joints_on_hit(m, m["t"], 10.0, "improvised", 0.1)
	_check(float(m["shock_t"]) >= 1.0, "an improvised hit did not shock with the Scrapper's joint")
	# the Scrapper's fire: a kill while it burns drops something, and the Fence pays a fifth more
	var piece: Dictionary = sim._plain("Helmet", "Hard hat")
	sim.tree = []
	var plain_price: int = sim.sell_price(piece)
	close.call("scrapper_fire")
	_check(sim.sell_price(piece) >= int(plain_price * 1.19), "the Scrapper's joint did not lift the Fence's price: %d to %d" % [plain_price, sim.sell_price(piece)])
	m = fresh_run.call()
	var t_dry: Dictionary = m["t"].duplicate()
	t_dry["drop"] = 0.0
	var finds0: int = int(m.get("finds", 0))
	m["kill_burning"] = true
	sim._kill(m, t_dry)
	_check(int(m.get("finds", 0)) == finds0 + 1, "a kill while it burned dropped nothing with the Scrapper's joint")
	# the Poacher's poison: the first shot on a gang lands its poison at full stacks
	close.call("poacher_poison")
	m = fresh_run.call()
	m["fresh"] = true
	m["dots"]["poison"] = 0.01
	sim._joints_on_hit(m, m["t"], 10.0, "rifle", 0.1)
	var full: float = float(m["dots"]["poison"])
	_check(full > 1.0 and m.has("full_dose"), "the first shot's poison is not at full stacks: %.2f" % full)
	m["dots"]["poison"] = 0.01
	sim._joints_on_hit(m, m["t"], 10.0, "rifle", 0.1)
	_check(float(m["dots"]["poison"]) < full, "the full dose landed twice on one gang")
	# the Paramedic's poison: a med is a full stack on them; the Paramedic's frost: chilled, they do 30% less and meds heal a fifth more
	close.call("paramedic_poison")
	m = fresh_run.call()
	m["using"] = {"name": "Bandage", "left": 0.0, "heal": 10.0}
	sim._patch(m, 0.1)
	_check(float(m["dots"].get("poison", 0.0)) > 0.0 and int(m.get("dosed", 0)) == 1, "a med did not dose them with the Paramedic's joint")
	close.call("paramedic_frost")
	m = fresh_run.call()
	_check(is_equal_approx(sim._joints_on_incoming(m, true, 0.1), 0.7) and is_equal_approx(sim._joints_on_incoming(m, false, 0.1), 1.0), "chilled gangs do not do 30%% less with the Paramedic's joint")
	sim.hp = sim.max_hp() * 0.2
	var hp0: float = sim.hp
	m["chill_t"] = 1.0
	m["using"] = {"name": "Bandage", "left": 0.0, "heal": 10.0}
	sim._patch(m, 0.1)
	_check(is_equal_approx(sim.hp - hp0, 12.0), "a med did not heal a fifth more while they were chilled: %.1f" % (sim.hp - hp0))
	# Flattened: a kill with the plain staggers the next of them, half their fire for two seconds
	sim.cls = "Doorman"
	sim.tree = ["Knuckles/10"]
	sim.trades = ["physical"]
	m = fresh_run.call()
	m["target_hp"] = 0.0
	sim._fight(m, m["t"], 0.05)
	_check(float(m.get("flat_t", 0.0)) > 0.0, "a kill with the plain did not flatten the next")
	_check(sim._joints_on_incoming(m, false, 0.1) <= 0.5 + 0.001, "Flattened did not halve their fire")
	if sim.on_mission():
		sim.extract_now()
	# the sum strip's Physical chip, the Doorman's knuckles alone: what it ignores, never a "+0%"
	sim.cls = "Doorman"
	sim.tree = ["Knuckles/5"]
	var phys: Array = main._barracks.sum_items([]).filter(func(it): return str(it.get("tag", "")) == "Physical")
	_check(phys.size() == 1 and phys[0]["forms"].all(func(f): return str(f) != "" and not str(f).contains("+0%")) and phys[0]["forms"].slice(1).all(func(f): return str(f).contains("+") or str(f).contains("ignores")), "the pen-only Physical chip reads a nothing: %s" % str(phys))
	# the plain figures count the notables as the fight does: Spray's quarter with an SMG in hand, none without
	sim.cls = "Drifter"
	sim.tree = ["Moving on/3"]
	sim.equipped["Primary"] = sim._plain("Primary", _base_of_type("smg"))
	var dmg: Array = main._barracks.sum_items([]).filter(func(it): return str(it.get("tag", "")) == "Damage")
	_check(dmg.size() == 1 and str(dmg[0]["forms"][0]) == "+25%", "the strip's Damage leaves out Spray: %s" % str(dmg))
	sim.equipped["Primary"] = sim._plain("Primary", "Nail gun")
	dmg = main._barracks.sum_items([]).filter(func(it): return str(it.get("tag", "")) == "Damage")
	_check(dmg.is_empty(), "the strip counts Spray without an SMG in hand: %s" % str(dmg))
	sim.load_dict(saved)
	main.refresh()
	print("joint payoffs ok: the ten joints and Flattened, each where it lives")


## The trees as webs: a fork at the notable, a branch each way; the second
## past from level 30; two runners turn up when one dies.
func _webs_traits(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	_set_cls(sim, "Poacher")
	sim.respec()
	sim.training_points += 30
	var t: Dictionary = Data.tree_named("Stalking")
	# the gates (9 Oct): a column opens at ⌈0.6 × the cost of every column before it⌉, counted in that tree alone
	for c in range(1, Data.COLUMNS):
		var before := 0
		for nd in t["nodes"]:
			if int(nd.get("col", 0)) < c and Data.for_classes(nd, ["Poacher"]):
				before += Data.base_cost(t, nd)
		_check(Data.gate(t, c, ["Poacher"]) == ceili(Data.GATE_SHARE * before), "Stalking's gate %d is %d, not the share of %d" % [c, Data.gate(t, c, ["Poacher"]), before])
	_check(sim.train_node("Stalking/0"), "Stalking's first node did not train")
	_check(not sim.can_train("Stalking/2") and sim.train_block("Stalking/2").begins_with("opens at"), "the second column opened on one point: '%s'" % sim.train_block("Stalking/2"))
	_check(not sim.can_train("Stalking/6") and not sim.can_train("Stalking/10"), "a deep node trained on a dip")
	# points in another tree open nothing here
	var yard_in: int = sim.points_in("The Yard")
	for i in range(3):
		sim.train_node("The Yard/%d" % i)
	_check(sim.points_in("The Yard") > yard_in and not sim.can_train("Stalking/2"), "the Yard's points opened Stalking's columns")
	sim.train_node("Stalking/1")
	_check(sim.can_train("Stalking/2") and sim.can_train("Stalking/4"), "the second column did not open at its gate")
	for i in [2, 4, 3]:
		sim.train_node("Stalking/%d" % i)
	_check(sim.points_in("Stalking") < Data.gate(t, 4, ["Poacher"]) and not sim.can_train("Stalking/6"), "the keystone trained under its gate: %d in, gate %d" % [sim.points_in("Stalking"), Data.gate(t, 4, ["Poacher"])])
	_check(sim.train_node("Stalking/7") and sim.train_node("Stalking/8"), "the fourth column did not train")
	_check(sim.points_in("Stalking") >= Data.gate(t, 4, ["Poacher"]) and sim.train_node("Stalking/9"), "the fifth column did not open at its gate")
	_check(sim.has_node("night_work"), "Night work did not take")
	_check(sim.effective(3)["rarity"] > 0.0 and sim.effective(3)["pace"] < 1.0, "Night work did not make the site Night")
	_check(not sim.can_train("Stalking/10") and sim.train_block("Stalking/10").begins_with("wants the keystone"), "the capstone trained before the keystone: '%s'" % sim.train_block("Stalking/10"))
	_check(sim.train_node("Stalking/5") and sim.train_node("Stalking/6"), "the keystone did not train once its column opened")
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
	_check(names.has("Muscle") and names.has("Stalking") and names.has("The Yard"), "a Poacher with a Doorman's past does not see Muscle: %s" % str(names))
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
	sim.deploy(3)
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
## to the Bench until the element's affixes are on it. Then the band: at
## depth 30 on every site, some build still lands most of its damage.
func _element_bot_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	for t in Data.ELEMENT_TREES:
		var el: String = t["element"]
		sim.load_dict(saved)
		_set_cls(sim, "Doorman")          # bleed and physical: four of the five are off-affinity
		sim.respec()
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
		# the keystone wants a joint closed there: a class half on show for it (the runner's, or the second past's first tree's)
		var closable := false
		var on_show: Array = sim.trees().map(func(x): return x["name"])
		for c in sim.my_classes():
			var j: Dictionary = Data.joint_in(c, t["name"])
			closable = closable or (not j.is_empty() and j["tree"] in on_show)
		if closable:
			_check(sim.tree.has("%s/6" % t["name"]) and sim.has_joint(Data.joint_in(sim.cls if Data.joint_in(sim.cls, t["name"]).size() > 0 else sim.cls2, t["name"])["key"]), "the %s bot did not close its joint and reach its keystone: %s" % [el, sim.tree])
		else:
			_check(not sim.tree.has("%s/6" % t["name"]) and sim.train_block("%s/6" % t["name"], true).begins_with("wants a joint"), "the %s keystone opened with no joint to close: %s" % [el, sim.tree])
		if el == "physical":
			continue                      # Knuckles scales what isn't converted: no element gun, socketable or affix to chase
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
		# the socketable: added at the Bench when none, and the element's own seated
		if el != "bleed":
			var sock: Dictionary = Items.roll(Data.ATTACHMENT, 2, sim.rng)
			var sock_base: String = {"fire": "Lighter fluid", "frost": "Antifreeze", "poison": "Rat poison", "shock": "Car battery"}[el]
			sock["base"] = sock_base
			sock["mount"] = "socket"
			sock["affixes"] = []
			sim.stash.append(sock)
			var cash0: float = sim.cash
			bot._craft_toward(sim)
			_check(Items.sockets(sim.equipped["Primary"]) >= 1 and sim.cash < cash0, "the %s bot did not buy a socket at the Bench" % el)
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
		# the Bench: the increased affix added next to the conversion
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
		sim.words[i] = []
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
	print("element bots ok: own tree first, saved points, the second past, the gun, the socketable, the Bench, the band")


func _element_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	_set_cls(sim, "Drifter")
	sim.respec()
	sim.training_points += 80
	sim.equipped["Primary"] = sim._plain("Primary", "Nail gun")     # nothing worn converts: the trees are read alone
	sim.equipped["Secondary"] = null
	_check(sim.affinity("fire") and sim.affinity("shock") and not sim.affinity("poison"), "the Drifter's affinities are not fire and shock")
	_check(sim.node_cost("Petrol/0") == 1 and sim.node_cost("The rat man/0") == 2, "an off-affinity node does not cost double: %d / %d" % [sim.node_cost("Petrol/0"), sim.node_cost("The rat man/0")])
	# Petrol to its fourth column: the Drifter's half trains, the Scrapper's doesn't
	for i in [0, 1, 2, 4, 3, 7, 5]:
		_check(sim.train_node("Petrol/%d" % i), "Petrol/%d did not train: %s" % [i, sim.train_block("Petrol/%d" % i)])
	_check(sim.train_block("Petrol/8") == "Scrapper only", "another class's half trained for a Drifter: '%s'" % sim.train_block("Petrol/8"))
	# the joint (9 Oct): one half alone gives its own figure and not the payoff; the element's top waits on it
	_check(not sim.has_joint("drifter_fire") and sim.train_block("Petrol/6").begins_with("wants a joint"), "the keystone opened on one half: '%s'" % sim.train_block("Petrol/6"))
	for i in [0, 1, 2, 4, 3, 5, 8]:
		_check(sim.train_node("Moving on/%d" % i), "Moving on/%d did not train: %s" % [i, sim.train_block("Moving on/%d" % i)])
	_check(sim.has_joint("drifter_fire") and not sim.has_joint("drifter_shock"), "both halves trained and the joint did not close")
	_check(sim.train_node("Petrol/6") and sim.has_node("fire_spread"), "Spreads did not train once the joint closed")
	_check(is_equal_approx(sim.conversion()["fire"], 0.70), "the fire conversions do not add to 70%%: %s" % str(sim.conversion()))     # A can of it 20 (9 Oct), Siphoned 35, Petrol bomb 15
	_check(is_equal_approx(sim.dot_seconds("fire"), 8.0) and is_equal_approx(sim.dot_seconds("poison"), 8.0), "Lit did not double the burn")
	_check(sim.train_node("Petrol/9") and is_equal_approx(sim.more("fire"), 1.4), "Petrol on your hands is not ×1.4")
	# the payoff: an SMG's hit lights them, and a burning gang takes a quarter more from it
	sim.equipped["Primary"] = sim._plain("Primary", _base_of_type("smg"))
	sim.words[3] = []
	sim.set_depth(3, 1)
	sim.hp = sim.max_hp()
	sim.deploy(3)
	var jm: Dictionary = sim.mission
	jm["dots"] = {}
	sim._joints_on_hit(jm, jm["t"], 100.0, "smg", 0.1)
	_check(float(jm["dots"].get("fire", 0.0)) > 0.0, "the Drifter's joined bursts did not ignite")
	sim.extract_now()
	sim.equipped["Primary"] = sim._plain("Primary", "Nail gun")
	# off the pair: the rat man stops at column 4 - no joint of the Drifter's is in it
	for i in [0, 1, 2, 4, 3, 7]:
		sim.train_node("The rat man/%d" % i)
	_check(sim.points_in("The rat man") >= Data.gate(Data.tree_named("The rat man"), 4, ["Drifter"]) and sim.train_block("The rat man/6", true).begins_with("wants a joint"), "an off-pair keystone was not stopped at column 4: '%s'" % sim.train_block("The rat man/6", true))
	# the second past brings its first tree's half: a Poacher's past closes the poison joint and opens the keystone
	sim.xp = Data.xp_for_level(Data.ASCEND_LEVEL)
	_check(sim.set_second("Poacher") and sim.affinity("poison") and sim.node_cost("The rat man/0") == 1, "the second past did not bring its affinities")
	for i in [0, 1, 2, 4, 3, 5, 8]:
		sim.train_node("Stalking/%d" % i)
	_check(sim.train_node("The rat man/5") and sim.has_joint("poacher_poison"), "the second past's halves did not close its joint: %s" % sim.train_block("The rat man/5"))
	_check(sim.can_train("The rat man/6"), "the second past's joint did not open the keystone: '%s'" % sim.train_block("The rat man/6"))
	# the fight: Spreads multiplies fire by those on you; a shocked gang takes more under Live
	sim.words[3] = []
	sim.set_depth(3, 1)
	sim.hp = sim.max_hp()
	sim.deploy(3)
	var m: Dictionary = sim.mission
	var t: Dictionary = m["t"]
	var on_you: int = mini(m["remaining"], sim.contact(t))
	var before: float = m["target_hp"]
	sim.advance(0.1)
	var fire_only: float = sim.type_dps()["fire"] * (1.0 - float(t["res"].get("fire", 0.0))) * sim.pace() * t["pace"] * 0.1
	_check(before - m["target_hp"] > fire_only * on_you * 0.6 or m["remaining"] < sim.mission["t"]["pool"], "Spreads did not multiply the fire by the %d on you" % on_you)
	sim.extract_now()
	# frost: Frozen solid stops their fire while chilled and halves frost; the Poacher's frost joint closes on Snares
	sim.respec()
	sim.cls2 = ""                       # the Poacher's past goes: a class change to the second past's class is refused
	_set_cls(sim, "Poacher")
	sim.training_points += 80
	for i in [0, 1, 2, 4, 3, 7, 5]:
		sim.train_node("The cold/%d" % i)
	for i in [0, 1, 2, 4, 3, 5, 8]:
		sim.train_node("Snares/%d" % i)
	_check(sim.has_joint("poacher_frost") and sim.train_node("The cold/6"), "the Poacher's frost joint did not open Frozen solid: '%s'" % sim.train_block("The cold/6"))
	_check(sim.has_node("frost_freeze") and is_equal_approx(sim.chill_amount(), Data.FREEZE) and is_equal_approx(sim.more("frost"), 0.5), "Frozen solid did not take: chill %.2f more %.2f" % [sim.chill_amount(), sim.more("frost")])
	_check(is_equal_approx(sim.incoming_rate({"dps": 10.0, "types": {"physical": 1.0}}, 1, true), 10.0 * (1.0 - Data.FREEZE) * (1.0 - sim.mitigation())), "a frozen gang fires more than a sliver: %.2f" % sim.incoming_rate({"dps": 10.0, "types": {"physical": 1.0}}, 1, true))
	# the payoff: every gang arrives chilled, and one head short
	sim.hp = sim.max_hp()
	var pool0: int = int(sim.effective(3)["pool"]) - (1 if sim.has_node("trapline") else 0)
	sim.deploy(3)
	_check(float(sim.mission.get("chill_t", 0.0)) > 0.0 and int(sim.mission["remaining"]) == maxi(1, pool0 - 1), "the Poacher's snare, joined, did not chill the first gang and take a head: %d of %d" % [int(sim.mission["remaining"]), pool0])
	sim.extract_now()
	for i in [0, 1, 2, 4, 3, 7, 5]:
		sim.train_node("The rat man/%d" % i)
	for i in [0, 1, 2, 4, 3, 5, 8]:
		sim.train_node("Stalking/%d" % i)
	_check(sim.train_node("The rat man/6") and sim.dot_stacks("poison") == 15, "Builds did not raise the stacks: '%s'" % sim.train_block("The rat man/6"))
	# bleed: Blades to both ends through the Doorman's joint; Glassing's 15% on the conversions
	sim.respec()
	_set_cls(sim, "Doorman")
	sim.training_points += 80
	var held = sim.equipped["Primary"]
	sim.equipped["Primary"] = sim._plain("Primary", _base_of_type("shotgun"))
	for i in [0, 1, 2, 4, 3, 7, 5, 8]:
		sim.train_node("Blades/%d" % i)
	for i in [0, 1, 2, 4, 3, 5, 8]:
		_check(sim.train_node("Muscle/%d" % i), "Muscle/%d did not train: %s" % [i, sim.train_block("Muscle/%d" % i)])
	_check(sim.train_node("Blades/6") and sim.train_node("Blades/9"), "Blades did not train past its joint: '%s' / '%s'" % [sim.train_block("Blades/6"), sim.train_block("Blades/9")])
	_check(sim.has_node("bleed_forever") and is_equal_approx(sim.more("bleed"), 1.4), "Blades did not train to both ends")
	_check(is_equal_approx(sim.conversion()["bleed"], 0.15 + 0.65), "Glassing did not add 15%% bleed: %s" % str(sim.conversion()))
	sim.deploy(3)
	m = sim.mission
	m["dots"] = {"bleed": 60.0}
	var dealt: float = sim._dot_tick(m["dots"], 1.0, {})
	_check(dealt > 0.0 and is_equal_approx(m["dots"]["bleed"], 60.0), "Won't stop let the bleed fade: %s" % str(m["dots"]))
	# the payoff: a bleeding gang does a fifth less to you; the physical joint not closed, nothing more
	_check(sim.has_joint("doorman_bleed") and not sim.has_joint("doorman_physical") and is_equal_approx(sim._joints_on_incoming(m, false, 0.1), 0.8), "the Doorman's bleed joint does not take a fifth off: %.2f" % sim._joints_on_incoming(m, false, 0.1))
	sim.extract_now()
	# Knuckles, the physical: the Doorman's half is the Knuckles' notable; both close the stagger
	for i in [0, 1, 2, 4, 3, 5, 7]:
		sim.train_node("The door/%d" % i)
	_check(sim.tree.has("The door/7") and not sim.has_joint("doorman_physical"), "Hands on alone closed the physical joint, or did not train: '%s'" % sim.train_block("The door/7"))
	for i in [0, 1, 2, 4, 3, 7, 5]:
		_check(sim.train_node("Knuckles/%d" % i), "Knuckles/%d did not train: %s" % [i, sim.train_block("Knuckles/%d" % i)])
	_check(sim.has_joint("doorman_physical") and sim.train_node("Knuckles/6"), "the Doorman's physical joint did not open Bust them up: '%s'" % sim.train_block("Knuckles/6"))
	_check(is_equal_approx(sim.conversion()["physical"], 1.0) and is_equal_approx(sim.phys_resist(0.2), 0.0), "Bust them up did not end the conversions and their armour: %s" % str(sim.conversion()))
	sim.deploy(3)
	_check(is_equal_approx(sim._joints_on_incoming(sim.mission, false, 0.1), 0.75 * 0.9), "the Doorman's physical joint and Stagger do not cut their fire to %.3f: %.3f" % [0.75 * 0.9, sim._joints_on_incoming(sim.mission, false, 0.1)])
	sim.extract_now()
	sim.equipped["Primary"] = held
	# the Caravan: every lane, the joints' links, the Also row's chips each swapping the fifth lane and back
	main.show_room(main.BARRACKS)
	_check_fit(main, "Caravan (elements, yard)")
	var bk = main._barracks
	_check(bk.lane_trees().map(func(x): return x["name"] if x != null else "") == ["Muscle", "Blades", "The door", "Knuckles", "The Yard"], "the Doorman's lanes are not the table's row: %s" % str(bk.lane_trees().map(func(x): return x["name"] if x != null else "")))
	_check(bk._links[0]["chip"].visible and bk._links[0]["label"].text.begins_with("⇄ JOINED") and bk._links[1]["label"].text.begins_with("⇄ JOINED"), "the closed joints' links do not say so: '%s' / '%s'" % [bk._links[0]["label"].text, bk._links[1]["label"].text])
	for name in bk.also_names():
		_check(bk.also_button(name) != null, "the %s chip is not on the Also row" % name)
		bk.also_button(name).pressed.emit()
		_check_fit(main, "Caravan (also: %s)" % name)
		if name == "The drawer" or name == "The shelf":
			_check(not bk._lanes[0]["panel"].visible and bk._cells[0]["button"].visible, "%s did not take the lanes' place" % name)
		else:
			_check(bk.lane_trees()[4]["name"] == name and bk._lanes[0]["panel"].visible, "the %s chip did not take the fifth lane" % name)
		bk.also_button(name).pressed.emit()
		_check(bk.alt == "" and bk.lane_trees()[4]["name"] == "The Yard", "the %s chip pressed again did not put the Yard back" % name)
	# the layout: the header with the points and the classes in its top right; every tile inside its lane, in
	# its column, none overlapping; the Also row, the sum strip and the panel under the lanes
	_check(bk._points.text == "%d of %d" % [sim.points_free(), sim.training_points], "the Caravan's points read '%s'" % bk._points.text)
	for cb in bk._class_buttons:
		_check(cb.position.y + cb.size.y <= bk.HEAD_H and cb.position.x >= bk._kicker.position.x + bk._kicker.size.x, "a class button is not in the band, right")
	for k in range(bk.LANES):
		var lane: Dictionary = bk._lanes[k]
		if not lane["panel"].visible:
			continue
		var box := Rect2(lane["panel"].position, lane["panel"].size)
		var rects := []
		for tile in lane["tiles"]:
			if not tile["button"].visible:
				continue
			var rc := Rect2(tile["button"].position, tile["button"].size)
			if not is_zero_approx(tile["button"].rotation):
				var d: float = tile["button"].size.x * sqrt(2.0)     # a diamond's true extent: its diagonal, about its centre
				rc = Rect2(rc.get_center() - Vector2(d, d) / 2.0, Vector2(d, d))
			var nd: Dictionary = sim.node(tile["id"])
			_check(box.encloses(rc) and rc.position.x >= bk.TILES_X - 0.5, "a tile leaves its lane: %s in %s" % [str(rc), str(box)])
			var cell: Rect2 = bk.tile_rect(int(nd.get("col", 0)), int(nd.get("row", 0)), false)
			_check(absf(rc.position.x + rc.size.x / 2.0 - (cell.position.x + cell.size.x / 2.0)) < 0.5, "%s is not centred in its column" % tile["id"])
			# a glyph, not words (Tree-G A, 9 Oct): the glyph drawn, the cost chip on the lane, no words on the tile
			_check(tile["glyph"].texture != null and tile["name"].text == "" and not tile["name"].visible, "%s shows words, or no glyph" % tile["id"])
			var chip := Rect2(tile["more"].position, tile["more"].size)
			_check(tile["more"].visible and box.grow(10).encloses(chip) and tile["more"].text != "", "%s's cost chip is off its lane: %s" % [tile["id"], str(chip)])
			for other in rects:
				_check(not rc.intersects(other), "tiles overlap in lane %d: %s and %s" % [k, str(rc), str(other)])
			rects.append(rc)
		# the gates (10 Oct, Tree-J B): one between each two columns, its number the tree's gate, lit once reached,
		# in the lane and on no tile, no cost chip and no joint mark
		var lt = lane["tree"]
		var lpts: int = sim.points_in(lt["name"])
		_check(lane["gate_at"].size() == bk.COLS - 1, "lane %d has %d gates" % [k, lane["gate_at"].size()])
		for gd in lane["gate_at"]:
			var gr := Rect2(Vector2(gd["x"], lane["panel"].position.y + gd["y"]) - Vector2(bk.GATE_R, bk.GATE_R), Vector2(2 * bk.GATE_R, 2 * bk.GATE_R))
			_check(int(gd["n"]) == Data.gate(lt, int(gd["c"]), sim.my_classes()) and bool(gd["lit"]) == (lpts >= int(gd["n"])), "lane %d's gate %d reads %d (lit %s)" % [k, int(gd["c"]), int(gd["n"]), str(gd["lit"])])
			_check(box.encloses(gr), "lane %d's gate %d leaves its lane" % [k, int(gd["c"])])
			for o in rects:
				_check(not gr.intersects(o), "lane %d's gate %d sits on a tile" % [k, int(gd["c"])])
			for tile in lane["tiles"]:
				if tile["button"].visible:
					for mark in [tile["more"], tile["joint"]]:
						if mark.visible:
							_check(not gr.intersects(Rect2(mark.position, Vector2(UI.text_width(mark, mark.text), mark.size.y))), "lane %d's gate %d sits on a mark" % [k, int(gd["c"])])
		# a joint's halves meet at the line (Matt, 10 Oct): the upper lane's on its bottom row, the lower's on its top
		if k < 4:
			_check_joint_rows(bk, k)
		# a rail into a joint half stops short of its mark (the reviewer, 10 Oct)
		for i in range(mini(lt["nodes"].size(), lane["tiles"].size())):
			var jt: Dictionary = lane["tiles"][i]
			if jt["button"].visible and jt["joint"].visible:
				var jc: int = int(lt["nodes"][i].get("col", 0))
				var jy: float = jt["button"].position.y + jt["button"].size.y / 2.0 - lane["panel"].position.y
				_check(bk.rail_in_x(k, jc, jy) <= jt["joint"].position.x - lane["panel"].position.x + 0.5, "lane %d's rail runs into %s's joint mark" % [k, lt["name"]])
	# a second past whose halves share the element trees' joint column (the Drifter and the Scrapper share Petrol and
	# Live): only this pair's half goes to the line. Every class with such a sharer, set straight on the sim.
	var snap: Dictionary = sim.to_dict()
	var shared := 0
	for cd in Data.CLASSES:
		var c1: String = cd["name"]
		var elems: Array = []
		for j in Data.JOINTS:
			if j["class"] == c1:
				elems.append(j["element_tree"])
		var other := ""
		for j in Data.JOINTS:
			if j["class"] != c1 and j["element_tree"] in elems:
				other = j["class"]
				break
		if other == "":
			continue
		shared += 1
		sim.cls = c1
		sim.cls2 = other
		bk._shown = ""
		main.refresh()
		for k in range(4):
			if bk._lanes[k]["panel"].visible:
				_check_joint_rows(bk, k)
	_check(shared > 0, "no two classes share an element tree's joint column")
	sim.load_dict(snap)
	bk._shown = ""
	main.refresh()
	_check(bk.ALSO_Y >= bk.lane_y(bk.LANES - 1) + bk.LANE_H and bk.PANEL_Y >= bk.ALSO_Y + bk.ALSO_H and bk.PANEL_Y + bk.PANEL_H <= Pal.ROOM_H and bk.LANES_Y >= bk.HEAD_H, "the Caravan's strips overlap")
	# the band (10 Oct, Bands-U A): the rooms' one height; the sum in it under the class's line, clear of the face, the
	# classes and the notice; the classes at its foot, right
	var sum_r := Rect2(bk._sum.position, bk._sum.size)
	_check(bk.HEAD_H == Pal.BAND_H and Rect2(0, 0, Pal.GRID_W, bk.HEAD_H).encloses(sum_r) and sum_r.position.y >= bk._points.position.y + 40 and sum_r.position.x >= bk._face.position.x + bk._face.size.x and not sum_r.intersects(Rect2(bk._class_line.position, bk._class_line.size)), "the sum is not in the band under the points: %s" % str(sum_r))
	for cb in bk._class_buttons:
		var cr := Rect2(cb.position, cb.size)
		_check(not cr.intersects(sum_r) and cr.end.y <= bk.HEAD_H - 8 and cr.end.y >= bk.HEAD_H - 24, "a class button is off the band's foot or on the sum: %s" % str(cr))
	_check(not Rect2(bk._notice.position, bk._notice.size).intersects(sum_r), "the class notice sits on the sum")
	# the sum strip (option A, 9 Oct): the elements in play in their colours, the dots, the joints last; no zeros
	var sum_tags: Array = []
	for k in range(bk._sum_chips.shown()):
		sum_tags.append(bk._sum_chips._tags[k].text)
	var last: int = maxi(0, bk._sum_chips.shown() - 1)
	_check(not sum_tags.is_empty() and sum_tags.has("Bleed") and sum_tags.has("Physical") and sum_tags.has("Dots") and sum_tags[last] == "Joints" and bk._sum_chips._labels[last].text.begins_with("2 of "), "the sum strip is off: %s" % str(bk._sum_chips.text_nodes().map(func(l): return l.text)))
	_check(bk._sum_chips._tags[sum_tags.find("Bleed")].get_theme_color("font_color") == Pal.ELEMENT_COLOURS["bleed"], "the Bleed chip is not in bleed's colour")
	for k in range(bk._sum_chips.shown()):
		_check(not bk._sum_chips._labels[k].text.begins_with("+0") and not bk._sum_chips._labels[k].text.begins_with("0%"), "the sum strip shows a figure at nothing: %s %s" % [sum_tags[k], bk._sum_chips._labels[k].text])
	# a crowded strip: every plain figure and four elements at once - the short forms, then the plain figures go
	var crowd_tree: Array = sim.tree.duplicate()
	var crowd_trades: Array = sim.trades.duplicate()
	for tn in ["The Yard", "Petrol", "The cold", "Live", "The rat man"]:
		for i in _behind_cap(tn):
			if not sim.tree.has("%s/%d" % [tn, i]):
				sim.tree.append("%s/%d" % [tn, i])
	sim.trades = ["fire", "frost", "shock", "poison"]
	bk._shown = ""
	main.refresh()
	var crowd_tags: Array = []
	for k in range(bk._sum_chips.shown()):
		crowd_tags.append(bk._sum_chips._tags[k].text)
	var crowd_full: Array = bk.sum_items([])     # the row as laid, then the long forms tried alone: they must not fit
	_check(not bk._fits(bk.sum_items_raw()), "the crowded strip fits at its long forms - the check is not crowded")
	_check(crowd_tags.size() == crowd_full.size(), "the crowded strip shows %d of %d" % [crowd_tags.size(), crowd_full.size()])
	bk._shown = ""
	main.refresh()                              # the probe above laid the long forms on the widget: lay the strip again
	_check(["Damage", "Fire", "Frost", "Shock", "Poison", "Dots"].all(func(t): return crowd_tags.has(t)) and crowd_tags.back() == "Joints", "the crowded strip lost an element, Damage or the Joints: %s" % str(crowd_tags))
	_sum_strip_check(main)
	_check_fit(main, "Caravan (a crowded sum strip)")
	# heavier still, in the band's three rows (Bands-U A; the reviewer): every element tree, Knuckles, a second past -
	# every element and the Joints still on show, the plain figures going first
	var cls2_hold: String = sim.cls2
	for tn in ["Blades", "Knuckles"]:
		var tt: Dictionary = Data.tree_named(tn)
		if tt.is_empty():
			continue
		for i in _behind_cap(tn):
			if not sim.tree.has("%s/%d" % [tn, i]):
				sim.tree.append("%s/%d" % [tn, i])
	for cd in Data.CLASSES:
		if cd["name"] != sim.cls:
			sim.cls2 = cd["name"]
			break
	bk._shown = ""
	main.refresh()
	var heavy_tags: Array = []
	for k in range(bk._sum_chips.shown()):
		heavy_tags.append(bk._sum_chips._tags[k].text)
	_check(["Damage", "Fire", "Frost", "Shock", "Poison", "Bleed"].all(func(t): return heavy_tags.has(t)) and heavy_tags.back() == "Joints" and heavy_tags.size() == bk.sum_items([]).size(), "the heaviest sum lost an element or the Joints in the band: %s" % str(heavy_tags))
	bk._shown = ""
	main.refresh()
	_check_fit(main, "Caravan (the heaviest sum)")
	sim.cls2 = cls2_hold
	sim.tree = crowd_tree
	sim.trades = crowd_trades
	bk._shown = ""
	main.refresh()
	# a node alone in its column (the capstone, most trees) spans both rows
	var cap_tile: Button = bk.tile_for("The door/10")
	var lane_mid: float = bk.lane_y(2) + bk.LANE_H / 2.0
	var cap_mid: float = cap_tile.position.y + cap_tile.size.y / 2.0 if cap_tile != null else -1.0
	_check(cap_tile != null and is_equal_approx(cap_tile.rotation_degrees, 45.0) and cap_mid > lane_mid - bk.LANE_H / 2.0 and cap_mid < lane_mid + bk.LANE_H / 2.0, "the capstone's diamond is not on its lane")     # The door has a node beside it now (12 Oct): its own row, not the lane's middle
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
			_check(not sim._active(typed_node) and bk._shown != shown_active, "the gun swap did not refresh the Caravan: typed node %s" % typed_id)
		sim.equipped["Primary"] = hold_gun
		main.refresh()
		_check(bk._shown.contains(sim.gun_type()), "the Caravan's signature does not carry the gun in hand")
	sim.load_dict(saved)
	print("the elements ok: affinities, double cost, the gates, the joints and their payoffs, the second past's joint, Spreads, Frozen solid, Builds, Won't stop, Knuckles, the Caravan's lanes")
	_capstone_checks(main)
	_melee_checks(main)


## Melee: no rounds, bleed built in, grip and head mounts, in among them.
## 28: a capstone a tree, past the keystone, wanting the keystone and every notable, a quarter of the tree again (a third until the pass).
func _capstone_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	# every tree carries one, last, wide on the Caravan, and its cost is a third of the tree rounded up
	for b in Data.TREES + Data.ELEMENT_TREES:
		var behind: Array = b["nodes"].filter(func(n): return not n.get("beside", false))     # a node beside the capstone (12 Oct) comes after it
		var last: Dictionary = behind.back()
		_check(last.get("capstone", false) and last.has("words") and last["effect"].begins_with("cap_"), "%s has no capstone at its end" % b["name"])
		_check(b["nodes"].filter(func(n): return n.get("capstone", false)).size() == 1, "%s has more than one capstone" % b["name"])
		# a quarter of the rest of the tree, rounded up; the two classes' halves in an element tree count once
		var others := 0
		var half := 0
		for i in range(behind.size() - 1):
			var nd: Dictionary = behind[i]
			var c: int = Data.node_cost(int(nd["col"]), nd.get("notable", false), nd.get("keystone", false))
			if nd.has("class"):
				half = maxi(half, c)
			else:
				others += c
		_check(Data.capstone_cost(b) == ceili((others + half) / 4.0), "%s's capstone costs %d, not a quarter of %d" % [b["name"], Data.capstone_cost(b), others + half])
		_check(int(last["col"]) == Data.COLUMNS - 1, "%s's capstone is not in the last column" % b["name"])
	# it opens only once the keystone and every notable are taken
	_set_cls(sim, "Poacher")
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
	sim.deploy(3)
	var m: Dictionary = sim.mission
	m["remaining"] = 0
	m["cleared"] = true
	var found_before: int = m["found"].size() + int(m["left"])
	m["patrol_timer"] = 1e9
	sim.advance(0.5)
	_check(m["patrols"] >= 1 and m["found"].size() + int(m["left"]) > found_before, "Poached did not bring a find when the gang came")
	sim.extract_now()
	# the Caravan shows it as a ◆◆ tile the lane's height at its end, and the run band names it
	main.show_room(main.BARRACKS)
	main._barracks.selected = ""
	main._barracks._shown = ""
	main.refresh()
	var cap_tile = null
	for lane in main._barracks._lanes:
		for n in lane["tiles"]:
			if n["button"].visible and n["id"] == cap_id:
				cap_tile = n
	_check(cap_tile != null and cap_tile["kind"] == "capstone" and is_equal_approx(cap_tile["button"].rotation_degrees, 45.0) and cap_tile["glyph"].texture != null, "the capstone's tile is off: %s" % (cap_tile["kind"] if cap_tile != null else "none"))
	_check_fit(main, "Caravan (capstone)")
	main._barracks._pick(cap_id)
	main.refresh()
	_check(main._barracks._title.text.ends_with("capstone · trained"), "the capstone's panel title is off: '%s'" % main._barracks._title.text)
	_check_fit(main, "Caravan (capstone picked)")
	sim.deploy(3)
	main.show_room(main.MISSIONS)
	main.refresh()
	_check(main._run._band.right[2].text.contains("Poached") or main._run._band.right[2].text.contains("capstone"), "the run band does not name the capstone: '%s'" % main._run._band.right[2].text)
	_check_fit(main, "Run (capstone)")
	sim.extract_now()
	# Dead quiet: every gang the size of the first; Ghost: a run starts at the search and a full pack brought home is the clear
	sim.tree.append("Stalking/%d" % _cap_idx("Stalking"))
	sim.deploy(3)
	m = sim.mission
	m["remaining"] = 0
	m["cleared"] = true
	m["patrols"] = 4
	m["patrol_timer"] = 1e9
	sim.advance(0.5)
	_check(m["remaining"] == sim.PATROL_BASE - (1 if sim.has_node("trapline") else 0), "Dead quiet let the fifth gang grow: %d" % m["remaining"])
	sim.extract_now()
	sim.tree = sim.tree.filter(func(id): return not str(id).begins_with("Stalking/"))
	_set_cls(sim, "Drifter")
	sim.tree.append("Moving on/%d" % _cap_idx("Moving on"))
	var best_before: int = sim.best_tier
	sim.deploy(3)
	m = sim.mission
	_check(m["remaining"] == 0 and m["cleared"] and m.get("ghost_pending", false), "Ghost did not start the run at the search")
	_check(sim.best_tier == best_before, "Ghost cleared the ladder on arrival")
	sim.extract_now()
	_check(sim.best_tier == best_before, "a Ghost run brought home light counted as a clear")
	sim.best_tier = 0
	sim.best_depth[3] = 0
	sim.deploy(3)
	m = sim.mission
	m["found"] = []
	while sim.pack_used(m) < sim.capacity():
		m["found"].append(sim._plain(Data.AMMO, "Nails"))
	sim.extract_now()
	_check(sim.best_tier == 4 and sim.best_depth[3] >= 1, "a Ghost run brought home full did not clear the site (best tier %d)" % sim.best_tier)
	sim.load_dict(saved)
	# Held: no second takes more than a tenth of you, their shots and what they left on you together
	sim.tree.append("The door/%d" % _cap_idx("The door"))
	var deep: int = sim.best_tier if sim.tier_open(sim.best_tier) else 0     # the deepest open (a flake: best_tier can name a tier whose zone isn't open)
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
	sim.deploy(3)
	m = sim.mission
	sim.hp = sim.max_hp() * 0.3
	var hp_before: float = sim.hp
	var max_before: float = sim.max_hp()       # the kill's xp can bring a level, and the level more max HP: the tenth is of the max as it heals
	sim._kill(m, m["t"])
	_check(sim.hp >= hp_before + max_before * 0.1 - 0.01, "Iron did not heal on the kill: %.1f to %.1f" % [hp_before, sim.hp])
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
	sim.words[3] = []
	sim.set_depth(3, 1)
	sim.hp = sim.max_hp()
	sim.deploy(3)
	var m: Dictionary = sim.mission
	var hp0: float = m["target_hp"]
	sim.advance(0.5)
	_check(is_equal_approx(m["target_hp"], hp0), "the bat swung inside the first second of a gang")
	sim.advance(1.0)
	_check(m["target_hp"] < hp0 or m["remaining"] < m["t"]["pool"], "the bat never swung")
	sim.extract_now()
	# the Workshop shows the bat's grip and head, and fits a part to the head
	sim.stash.append(sim._plain("Attachment", "Tape"))
	main.show_room(main.WORKSHOP)
	main._workshop._set_view("guns")
	main.refresh()
	var labels := []
	for r in main._workshop._guns["Primary"]["rows"]:
		labels.append(r["mount"].text)
	_check(labels[0] == "Grip" and labels[1] == "Business end" and labels[2] == "" and main._workshop._guns["Primary"]["rows"][2]["button"].visible and not main._workshop._guns["Primary"]["rows"][3]["button"].visible, "the bat's rows are %s (the third a hollow slot, no second row)" % str(labels))
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
	# the Bench's heading (9 Oct): its picks built in the Yard; every mount open, no upgrade button
	for picks_on in [false, true]:
		_yard_set(sim, "bench", 0, "b" if picks_on else "")
		_yard_set(sim, "bench", 1, "a" if picks_on else "")
		main._workshop._shown = ""
		main.refresh()
		_check(main._workshop._headline.text == ("2 of 5" if picks_on else "0 of 5"), "the Bench's heading reads '%s'" % main._workshop._headline.text)
		_check(main._workshop._next.text.contains("Cheap parts") == picks_on, "the Bench's heading does not name its picks: '%s'" % main._workshop._next.text)
		var chips = main._workshop._chips
		# the band (Bands-U A): the purse down the left under the headline, the views at the foot, right, the line between
		var ws = main._workshop
		var cr := Rect2(chips.position, chips.size)
		_check(ws.HEAD_H == Pal.BAND_H and cr.position.y >= ws._headline.position.y + ws._headline.size.y and cr.end.x <= ws.PAD + Pal.BAND_TEXT_W + 0.5 and cr.end.y <= ws.HEAD_H - 8 and chips.shown() == 3, "the purse chips are off their place in the band: %s, %d shown" % [str(cr), chips.shown()])
		for v in ws._views:
			var vr := Rect2(v.position, v.size)
			_check(vr.end.y <= ws.HEAD_H - 8 and vr.end.x <= ws.size.x - ws.PAD + 0.5 and not vr.intersects(cr) and not vr.intersects(Rect2(ws._next.position, ws._next.size)), "a view's tab is off the band's foot or on the purse or the line: %s" % str(vr))
		var prim = sim.equipped["Primary"]
		if prim != null:
			for r in main._workshop._guns["Primary"]["rows"]:
				if r["key"] != "" and prim["attachments"].get(r["key"], null) != null:
					var part: Dictionary = prim["attachments"][r["key"]]
					_check(r["fitted"].get_theme_color("font_color") == Pal.tier_color(int(part.get("tier", 1))), "the %s tile is not in its part's tier colour" % r["key"])
		_check_fit(main, "Workshop (picks %s)" % str(picks_on))
	_yard_set(sim, "bench", 0, "")
	_yard_set(sim, "bench", 1, "")
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
			var before_words: String = main._workshop._piece_chips.words(1)
			sim.notes += 1000
			sim.craft(ws_piece["id"], "bump")
			main.refresh()
			_check(main._workshop._piece_chips.words(1) != before_words or main._workshop._foot.get_theme_color("font_color") == Pal.GOOD, "the craft view did not refresh after a bump: '%s'" % main._workshop._piece_chips.words(1))
		sim.stash.erase(ws_piece)
		main._workshop._set_view("guns")
		main.refresh()
	# a long part name on a tile falls back to its first word, never an ellipsis
	_check(main._workshop._short_names("Drum magazine") == ["Drum magazine", "Drum", "Drum"] and main._workshop._short_names("Tape") == ["Tape", "Tape"], "the tile's short names are off: %s" % str(main._workshop._short_names("Drum magazine")))
	var drum_gun = sim.equipped["Primary"]
	if drum_gun != null and drum_gun["attachments"].has("magazine"):
		var hold_mag = drum_gun["attachments"]["magazine"]
		drum_gun["attachments"]["magazine"] = sim._plain("Attachment", "Drum magazine")
		main._workshop._shown = ""
		main.refresh()
		_check_fit(main, "Workshop (a drum magazine on a tile)")
		drum_gun["attachments"]["magazine"] = hold_mag
		main._workshop._shown = ""
		main.refresh()
	main.refresh()
	sim.stash.erase(lead)
	# Through the lot: a Doorman's swing hits everyone on you
	_set_cls(sim, "Doorman")
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
	_check(sim.loose_uniques(1).size() == 7 and sim.loose_uniques(12).size() > 10 and sim.loose_uniques(25).size() == sim.loose_uniques(99).size(), "the depth gates on the loose pool are off: %d / %d / %d" % [sim.loose_uniques(1).size(), sim.loose_uniques(12).size(), sim.loose_uniques(25).size()])
	for i in range(sim.best_depth.size()):
		sim.best_depth[i] = 1
	for k in range(20):
		_check(int(sim._unique_named(sim.roll_mate()["unique"]).get("depth", 0)) == 0, "the mate sold a deep unique before anyone had been deep")
	sim.best_depth[3] = 25
	var deep := 0
	for k in range(40):
		deep += 1 if int(sim._unique_named(sim.roll_mate()["unique"]).get("depth", 0)) >= 6 else 0     # the build ones open at 6 now (12 Oct)
	_check(deep > 10, "the mate's deep stock did not open at depth 25: %d of 40" % deep)
	# a bare runner to hang each rule on
	for s in Data.SLOTS:
		sim.equipped[s] = null
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	sim.respec()
	sim.words[3] = []
	sim.set_depth(3, 1)
	var t: Dictionary = sim.effective(3)
	# the burner: all fire, takes nothing, spreads
	var burner := Items.roll_unique(sim._unique_named("The Council's Weed Burner"), sim.rng)
	sim.equipped["Primary"] = burner
	_check(is_equal_approx(sim.conversion()["fire"], 1.0) and sim.has_rounds(burner) and Items.ammo_words(burner) == "Takes nothing", "the burner is not all fire and free: %s" % str(sim.conversion()))
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	# Jump Leads: a third shock
	sim.equipped["Secondary"] = Items.roll_unique(sim._unique_named("Jump Leads"), sim.rng)
	_check(sim.conversion()["shock"] >= 0.33, "Jump Leads did not add a third shock: %s" % str(sim.conversion()))
	sim.equipped["Secondary"] = null
	# the bag and the steel: stacks, more, and the carry on a kill
	sim.equipped["Backpack"] = Items.roll_unique(sim._unique_named("The Rat Man's Bag"), sim.rng)
	_check(sim.dot_stacks("poison") == 999, "the bag did not uncap poison")
	sim.deploy(3)
	var m: Dictionary = sim.mission
	m["dots"] = {"poison": 50.0}
	m["target_hp"] = 0.0
	m["remaining"] = 3
	sim.advance(0.1)
	_check(m.get("dots", {}).has("poison") and m["dots"]["poison"] > 0.0, "poison did not carry to the next with the bag: %s" % str(m.get("dots", {})))
	sim.extract_now()
	sim.equipped["Backpack"] = null
	sim.equipped["Primary"] = Items.roll_unique(sim._unique_named("The Butcher's Steel"), sim.rng)
	_check(is_equal_approx(sim.more("bleed"), 2.0), "the steel is not ×2 bleed")
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	# the hopper: chilled always, one at a time
	sim.equipped["Armour"] = Items.roll_unique(sim._unique_named("The Gritter's Hopper"), sim.rng)
	sim.deploy(3)
	m = sim.mission
	sim.advance(0.1)
	_check(float(m.get("chill_t", 0.0)) > 0.0 and sim.contact(t) == 1, "the hopper did not chill them and bring them one at a time: chill %.1f contact %d" % [float(m.get("chill_t", 0.0)), sim.contact(t)])
	sim.extract_now()
	sim.equipped["Armour"] = null
	# the gloves: their shock resist is nothing
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The Sparky's Gloves"), sim.rng)
	sim.equipped["Primary"]["affixes"] = [{"stat": "conv_shock_pct", "value": 50, "tier": 5}]
	var full: float = sim.damage_rate({"res": {}})
	_check(is_equal_approx(sim.damage_rate({"res": {"shock": 0.6}}), full), "the gloves did not ignore their shock resist")
	sim.equipped["Primary"]["affixes"] = []
	# the manual: every element yours
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The Quartermaster's Manual"), sim.rng)
	_check(sim.affinity("poison") and sim.affinity("frost") and sim.node_cost("The rat man/0") == 1, "the manual did not make every element the runner's")
	# the plaque: all resists, nothing else
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("A Blue Plaque"), sim.rng)
	sim.equipped["Primary"]["affixes"] = [{"stat": "damage_pct", "value": 50, "tier": 5}]
	_check(is_equal_approx(sim._affix_sum("damage_pct"), 0.0) and sim.resist("fire") >= 0.4, "the plaque did not blank the rest: dmg %.0f fire res %.2f" % [sim._affix_sum("damage_pct"), sim.resist("fire")])
	sim.equipped["Primary"]["affixes"] = []
	# the sign: the first drops, gangs half as often
	sim.equipped["Charm"] = null
	sim.equipped["Secondary"] = Items.roll_unique(sim._unique_named("The Lollipop Lady's Sign"), sim.rng)
	var p0: float = sim.patrol_s(t)
	sim.equipped["Secondary"] = null
	_check(p0 >= sim.patrol_s(t) * 2.0, "the sign did not halve the gangs")
	# the pencil, the Float, the cardigan, the ladle, the hat, the thermos, the whistles, the tester, the flask, the keys, the log
	var r0: float = sim.rarity_bonus()
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The Bookie's Pencil"), sim.rng)
	_check(sim.rarity_bonus() > r0 * 1.5 + 0.1, "the pencil did not double magic find")
	sim.equipped["Charm"] = null
	var cap0: int = sim.capacity()
	var pace0: float = sim.pace()
	sim.equipped["Rig"] = sim._plain("Rig", "Bum bag")
	sim.equipped["Backpack"] = Items.roll_unique(sim._unique_named("The Float"), sim.rng)
	_check(sim.med_capacity() == 0 and sim.pace() > pace0 * 1.35 and sim.capacity() > cap0, "the Float did not do its three things: meds %d pace %.2f cap %d" % [sim.med_capacity(), sim.pace() / pace0, sim.capacity()])
	sim.equipped["Backpack"] = null
	sim.equipped["Rig"] = null
	sim.equipped["Armour"] = Items.roll_unique(sim._unique_named("Nan's Cardigan"), sim.rng)
	_check(is_equal_approx(sim.mitigation(), 0.0), "Nan's Cardigan has armour")
	sim.hp = sim.max_hp() * 0.5
	sim.deploy(3)
	var h0: float = sim.hp
	sim.advance(1.0)
	_check(sim.hp > h0 + sim.max_hp() * 0.012 or sim.hp >= sim.max_hp() - 0.1 or sim.mission == null, "the cardigan did not give 3%% a second: %.1f -> %.1f of %.1f" % [h0, sim.hp, sim.max_hp()])
	sim.extract_now()
	sim.equipped["Armour"] = null
	sim.equipped["Primary"] = Items.roll_unique(sim._unique_named("The Dinner Lady's Ladle"), sim.rng)
	sim.hp = sim.max_hp() * 0.5
	sim.deploy(3)
	m = sim.mission
	h0 = sim.hp
	m["target_hp"] = 0.0
	sim.advance(0.05)
	_check(sim.hp >= h0 + sim.max_hp() * 0.1 - 1.0, "the ladle did not heal a tenth on a kill: %.1f -> %.1f" % [h0, sim.hp])
	sim.extract_now()
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	sim.equipped["Helmet"] = Items.roll_unique(sim._unique_named("A Traffic Warden's Hat"), sim.rng)
	_check(sim.notes_a_kill(t) == 2 * (int(ceil(Data.NOTES_KILL * 1.0)) + sim.atlas_rank("paid_in_notes")) or sim.notes_a_kill(t) >= 2, "the hat did not double the notes")
	sim.equipped["Helmet"] = null
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The Vicar's Thermos"), sim.rng)
	_check(is_equal_approx(sim.resist("fire"), 0.0), "the thermos left a fire resist")
	sim.deploy(3)
	m = sim.mission
	m["my_dots"] = {"fire": 40.0}
	sim.hp = sim.max_hp() * 0.5
	h0 = sim.hp
	m["remaining"] = 1
	m["target_hp"] = 1e9
	sim.advance(0.5)
	_check(sim.hp > h0 - 1.0, "the thermos did not turn the burn to warmth: %.1f -> %.1f" % [h0, sim.hp])
	sim.extract_now()
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The Scout Leader's Whistle"), sim.rng)
	sim.deploy(3)
	m = sim.mission
	m["remaining"] = 0
	m["cleared"] = true
	m["patrol_timer"] = 1e9
	sim.advance(0.1)
	_check(m["remaining"] == 1, "the scout's whistle did not make the gang one: %d" % m["remaining"])
	sim.extract_now()
	sim.equipped["Charm"] = null
	var c0: int = sim.contact(t)
	sim.equipped["Helmet"] = Items.roll_unique(sim._unique_named("The Sergeant's Whistle"), sim.rng)
	_check(sim.contact(t) == c0 + 2 and is_equal_approx(sim.more("physical"), 1.6), "the Sergeant's Whistle: contact %d more %.1f" % [sim.contact(t), sim.more("physical")])
	sim.equipped["Helmet"] = null
	sim.equipped["Secondary"] = Items.roll_unique(sim._unique_named("The Electrician's Tester"), sim.rng)
	_check(is_equal_approx(sim.more("shock"), 0.5), "the tester is not half shock")
	sim.equipped["Secondary"] = null
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The Gamekeeper's Flask"), sim.rng)
	sim.deploy(3)
	m = sim.mission
	m["t"]["types"] = {"physical": 0.5, "poison": 0.5}
	m["target_hp"] = 1e9
	sim.advance(0.5)
	_check(m.get("dots", {}).get("poison", 0.0) > 0.0, "the flask did not poison them back: %s" % str(m.get("dots", {})))
	sim.extract_now()
	sim.words[3] = []
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The Caretaker's Keys"), sim.rng)
	var fired := 0
	for k in range(5):
		sim.deploy(3)
		fired += 1 if sim.mission["event"] != "" else 0
		sim.extract_now()
	_check(fired == 5, "the keys did not make something happen every run: %d of 5" % fired)
	sim.equipped["Charm"] = null
	var log := Items.roll_unique(sim._unique_named("The Lorry Driver's Log"), sim.rng)
	sim.stash.append(log)
	_check(sim.has_rule("drivers_log") and sim.insure_cost(3) == 0, "the log in the stash did not count, or insurance isn't free")
	sim.stash.erase(log)
	sim.load_dict(saved)
	print("the uniques ok: all roll with words, the depth gates, the mate's deep stock, twenty-one rules")
	_unique_tier_checks(main)
	_over_cap_checks(main)
	_guard_checks(main)
	_set_checks(main)


## Over the cap (12 Oct, docs/design/over_the_cap.md): a resist past 75 is its element's damage, a point a point, to
## 50; all resists count; physical never; the Water cannon soaks it; the new lines roll where they should.
func _over_cap_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	for s in Data.SLOTS:
		sim.equipped[s] = null
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	var inc0: float = sim.increased("fire")
	var coat: Dictionary = sim._plain("Armour", "Stab vest")
	coat["affixes"] = [{"stat": "fire_res", "value": 60}]
	var hat: Dictionary = sim._plain("Helmet", "Hard hat")
	hat["affixes"] = [{"stat": "fire_res", "value": 50}]
	sim.equipped["Armour"] = coat
	sim.equipped["Helmet"] = hat
	_check(is_equal_approx(sim.resist("fire"), 0.75) and is_equal_approx(sim.resist_raw("fire"), 110.0) and is_equal_approx(sim.over_cap("fire"), 35.0), "110 fire resist is not 75%% and 35 over: %.2f / %.0f" % [sim.resist("fire"), sim.over_cap("fire")])
	_check(is_equal_approx(sim.increased("fire") - inc0, 35.0), "35 over the cap is not +35%% fire: +%.0f" % (sim.increased("fire") - inc0))
	hat["affixes"] = [{"stat": "fire_res", "value": 200}]
	_check(is_equal_approx(sim.over_cap("fire"), Data.OVER_CAP), "over the cap is not held at %d" % int(Data.OVER_CAP))
	hat["affixes"] = [{"stat": "all_res", "value": 80}]
	coat["affixes"] = []
	_check(is_equal_approx(sim.over_cap("frost"), 5.0) and is_equal_approx(sim.over_cap("poison"), 5.0) and sim.over_cap("physical") == 0.0, "all resists did not go over the cap on each, or physical did")
	hat["affixes"] = [{"stat": "fire_proofed", "value": 20}]
	_check(is_equal_approx(sim.resist("fire"), 0.2) and is_equal_approx(sim.increased("fire") - inc0, 20.0), "the -proofed line is not resist and damage")
	# the Water cannon: a run's resists down
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("A Blue Plaque"), sim.rng)
	coat["affixes"] = [{"stat": "fire_res", "value": 100}]
	_check(sim.over_cap("fire") == 0.0, "the Blue Plaque went over the cap")
	sim.equipped["Charm"] = null
	coat["affixes"] = []
	hat["affixes"] = [{"stat": "fire_res", "value": 100}]
	sim.hp = sim.max_hp()
	sim.words[3] = []
	sim.deploy(3)
	_check(sim.mission != null, "the over-the-cap run did not set off")
	if sim.mission == null:
		sim.load_dict(saved)
		return
	sim.mission["t"]["soaked"] = 0.3
	sim._dry_memo.clear()                 # the run's memo read the resists at the gate
	_check(is_equal_approx(sim.resist_raw("fire"), 70.0) and is_equal_approx(sim.resist("fire"), 0.7) and sim.over_cap("fire") == 0.0, "soaked did not take 30 off: %.0f" % sim.resist_raw("fire"))
	sim.extract_now()
	_check(sim.word_words("Water cannon", 1)[0].contains("your resists"), "the Water cannon's bite has no words: %s" % str(sim.word_words("Water cannon", 1)))
	# where the lines roll
	var on := func(slot: String, stat: String) -> bool: return Items.allowed_affixes(slot).any(func(a): return a["stat"] == stat)
	_check(on.call("Rig", "fire_res") and on.call("Rig", "all_res") and on.call("Armour", "fire_proofed") and on.call("Helmet", "bleed_proofed") and not on.call("Charm", "fire_proofed") and not on.call("Primary", "fire_proofed"), "the resists or the -proofed lines roll in the wrong slots")
	# every element tree's notable over the cap, and Knuckles' armour one
	for et in Data.ELEMENT_TREES:
		var want: String = "thick_skinned" if et["element"] == "physical" else "proof_" + str(et["element"])
		_check(et["nodes"].any(func(n): return n["effect"] == want and int(n["col"]) == 5 and int(n["row"]) == 1), "%s has no over-the-cap node" % et["name"])
	sim.load_dict(saved)
	print("over the cap ok: 110 is 75 and +35, held at 50, all resists, never physical, -proofed, soaked, the lines' slots, the six nodes")


## Guard (12 Oct, docs/design/shields.md): their fire comes off Guard first; the cap; the Paramedic's overheal and a
## med's overflow; each class's node at its moment; Transfusion fills it; gone at the extract.
func _guard_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	for s in Data.SLOTS:
		sim.equipped[s] = null
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	_set_cls(sim, "Doorman")
	sim.respec()
	sim.words[3] = []
	sim.hp = sim.max_hp()
	sim.deploy(3)
	var m: Dictionary = sim.mission
	_check(sim.guard() == 0.0 and is_equal_approx(sim.guard_cap(), sim.max_hp() * Data.GUARD_SHARE), "a bare Doorman starts with Guard, or its cap is off: %.0f of %.0f" % [sim.guard(), sim.guard_cap()])
	sim._guard_add(m, 1000000.0)
	_check(is_equal_approx(sim.guard(), sim.guard_cap()), "Guard went past its cap")
	m["guard"] = 50.0
	var hp0: float = sim.hp
	sim._take(m, 10.0)
	_check(is_equal_approx(sim.guard(), 40.0) and is_equal_approx(sim.hp, hp0), "Guard did not take the hit first")
	sim._take(m, 100.0)
	_check(sim.guard() == 0.0 and is_equal_approx(sim.hp, hp0 - 60.0), "what Guard couldn't take did not come off HP: %.0f" % (hp0 - sim.hp))
	sim.hp = sim.max_hp()
	sim._heal(m, 30.0)
	_check(sim.guard() == 0.0, "a Doorman's overflow became Guard")
	sim._heal(m, 30.0, true, 0.5)
	_check(is_equal_approx(sim.guard(), 15.0), "a med's overflow line did not make Guard: %.0f" % sim.guard())
	# the class nodes, at their moments
	var node_id := func(tree_name: String, effect: String) -> String:
		for t in Data.TREES:
			if t["name"] == tree_name:
				for k in range(t["nodes"].size()):
					if t["nodes"][k]["effect"] == effect:
						return "%s/%d" % [tree_name, k]
		return ""
	m["guard"] = 0.0
	sim.tree.append(node_id.call("The door", "squared_up"))
	_check(sim.has_node("squared_up"), "Squared up did not take")
	sim._gang_arrives(m)
	_check(is_equal_approx(sim.guard(), minf(sim.guard_cap(), sim.max_hp() * 0.15)), "Squared up gave %.0f, not 15%% of max HP to the cap" % sim.guard())
	m["guard"] = 0.0
	var coat: Dictionary = sim._plain("Armour", "Stab vest")
	coat["affixes"] = [{"stat": "guard_gang", "value": 8}]
	sim.equipped["Armour"] = coat
	sim._gang_arrives(m)
	_check(is_equal_approx(sim.guard(), minf(sim.guard_cap(), sim.max_hp() * 0.23)), "Squared up and the guard line did not add to the cap: %.0f" % sim.guard())
	sim.extract_now()
	sim.equipped["Armour"] = null
	sim.tree.erase(node_id.call("The door", "squared_up"))
	sim.hp = sim.max_hp()
	sim.deploy(3)
	_check(sim.mission != null and sim.guard() == 0.0, "the next run started with Guard")
	if sim.mission != null:
		sim.extract_now()
	# the other three classes' nodes at their moments, through the run's own code
	for cd in [["Poacher", "Stalking", "in_the_hide"], ["Scrapper", "Stripping", "sheet_metal"], ["Drifter", "Moving on", "breather"]]:
		_set_cls(sim, cd[0])
		sim.tree.append(node_id.call(cd[1], cd[2]))
		_check(sim.has_node(cd[2]), "%s did not take" % cd[2])
		sim.hp = sim.max_hp()
		sim.deploy(3)
		if sim.mission == null:
			_check(false, "the %s run did not set off" % cd[2])
			continue
		m = sim.mission
		m["guard"] = 0.0
		match cd[2]:
			"in_the_hide":
				m["fresh"] = true
				m["remaining"] = 3
				m["target_hp"] = -1.0
			_:
				m["remaining"] = 0
				m["target_hp"] = 0.0
				m["cleared"] = true
				m["search"] = sim.search_s(m["t"])
		sim.advance(0.05)
		_check(sim.guard() > 0.0, "%s gave no Guard at its moment" % cd[2])
		sim.extract_now()
		sim.tree.erase(node_id.call(cd[1], cd[2]))
	sim.load_dict(saved)
	saved = sim.to_dict()
	_set_cls(sim, "Paramedic")
	sim.respec()
	for s_ in Data.SLOTS:
		sim.equipped[s_] = null                 # a bare runner: no Guard line on the kit (they roll now)
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	sim.words[3] = []
	sim.hp = sim.max_hp()
	sim.deploy(3)
	m = sim.mission
	m["guard"] = 0.0
	var half: float = sim.guard_cap() * 0.5
	sim._heal(m, half)
	_check(is_equal_approx(sim.guard(), half), "the Paramedic's overheal did not make Guard: %.0f of %.0f" % [sim.guard(), half])
	sim.tree.append(node_id.call("Shifts", "overtime"))
	_check(is_equal_approx(sim.guard_cap(), sim.max_hp() * Data.GUARD_SHARE * 1.5), "Overtime did not grow Guard's cap by half")
	sim.tree.erase(node_id.call("Shifts", "overtime"))
	sim.tree.append(node_id.call("Shifts", "cap_transfusion"))
	_check(sim.has_node("cap_transfusion") and is_equal_approx(sim.guard_cap(), sim.max_hp() * Data.GUARD_SHARE * 2.0), "Transfusion did not double Guard's cap")
	m["using"] = {"name": "Bandage", "left": 0.0, "heal": 5.0}
	sim._patch(m, 0.1)
	_check(is_equal_approx(sim.guard(), sim.guard_cap()), "Transfusion's med did not fill Guard to the top: %.0f of %.0f" % [sim.guard(), sim.guard_cap()])
	# what Guard takes is Guard's on the run screen, not red: the red figures count only what reached HP
	var taken0: float = float(m.get("taken", 0.0))
	var by0: float = 0.0
	for ty in m.get("taken_by", {}):
		by0 += float(m["taken_by"][ty])
	m["t"]["dps"] = 1.0
	m["remaining"] = maxi(1, int(m["remaining"]))
	sim.advance(1.0)
	var by1: float = 0.0
	for ty in m.get("taken_by", {}):
		by1 += float(m["taken_by"][ty])
	_check(sim.mission == null or (float(m.get("guarded", 0.0)) > 0.0 and absf((by1 - by0) - (float(m.get("taken", 0.0)) - taken0)) < 0.5), "Guard's share went into the red figures: by type +%.1f, to HP +%.1f, guarded %.1f" % [by1 - by0, float(m.get("taken", 0.0)) - taken0, float(m.get("guarded", 0.0))])
	# the Stats sheet says where Guard comes from, in its colour
	main.show_room(main.RUNNER)
	main.refresh()
	var gnote: Label = main._stats.cards["defence"]["note"]
	_check(gnote.text.begins_with("Guard to ") and gnote.text.contains("overheal"), "the Stats sheet's defence does not say where Guard comes from: '%s'" % gnote.text)
	_check_fit(main, "Stats (Guard)")
	if sim.mission != null:
		sim.extract_now()
	sim.load_dict(saved)
	print("Guard ok: first off Guard, the cap, overheal and a med's overflow, Squared up, Transfusion's cap, gone at the extract")


## Uniques by tier (12 Oct, docs/design/uniques.md): every unique but the paper has a band and a range; it rolls held
## inside its range on its slot's best base there, name, rule and art kept; a higher copy beats a lower; the melee
## secondary past the Cosh is lifted; the bands pick by tier; the shelf keeps the best tier; the mate's offer has one;
## the four gap uniques' rules.
func _unique_tier_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	for u in Data.UNIQUES:
		if u["slot"] == Data.PAPER:
			_check(not u.has("range"), "the paper has a range")
			continue
		_check(u.has("range") and Data.UNIQUE_BAND_WEIGHT.has(str(u.get("band", ""))), "%s has no band or range" % u["name"])
		var lo: int = int(u["range"][0])
		var hi: int = int(u["range"][1])
		var low: Dictionary = Items.roll_unique(u, sim.rng, -1, 1)
		var high: Dictionary = Items.roll_unique(u, sim.rng, -1, 99)
		_check(int(low["tier"]) == lo and int(high["tier"]) == hi, "%s did not hold inside %d-%d: T%d / T%d" % [u["name"], lo, hi, int(low["tier"]), int(high["tier"])])
		_check(low["unique"] == u["name"] and high["unique"] == u["name"] and high["rule"] == u["rule"] and Items.full_name(high) == u["name"], "%s lost its name or rule at its top" % u["name"])
		_check(Items.base_of(high).get("type", "") == Items.base_named(u["slot"], u["base"]).get("type", ""), "%s changed its gun type at its top: %s" % [u["name"], high["base"]])
		for k in high["attachments"]:
			_check(str(k).begins_with("socket") or str(k) in Items.base_of(high).get("attachments", []), "%s has a mount its body hasn't: %s on %s" % [u["name"], k, high["base"]])
		if hi > lo:
			_check(Items.score(high) > Items.score(low), "%s at T%d does not beat itself at T%d: %.1f vs %.1f" % [u["name"], hi, lo, Items.score(high), Items.score(low)])
	# the sign past the Cosh: still a Cosh, lifted to the slot's curve
	var sign: Dictionary = sim._unique_named("The Lollipop Lady's Sign")
	var s4: Dictionary = Items.roll_unique(sign, sim.rng, -1, 4)
	var s9: Dictionary = Items.roll_unique(sign, sim.rng, -1, 9)
	_check(s9["base"] == "Cosh" and float(s9.get("lift", 1.0)) > float(s4.get("lift", 1.0)) and float(s4.get("lift", 1.0)) > 1.0 and Items.dps(s9) > Items.dps(s4), "the sign is not a lifted Cosh: %s ×%.2f" % [s9["base"], float(s9.get("lift", 1.0))])
	# a worn copy and a better one: the better reads as an upgrade
	for s in Data.SLOTS:
		sim.equipped[s] = null
	var steel: Dictionary = sim._unique_named("The Butcher's Steel")
	sim.equipped["Primary"] = Items.roll_unique(steel, sim.rng, -1, 4)
	var better: Dictionary = Items.roll_unique(steel, sim.rng, -1, 9)
	_check(sim.compare(better) == 1, "a T9 steel does not read better than the T4 worn")
	# the bands: a levelling one never at T9, a chase one never at T2, the levelling ones most at T3
	var loose: Array = sim.loose_uniques(99)
	var by_band := {"levelling": 0, "core": 0, "chase": 0}
	for k in range(300):
		var at9: Dictionary = sim.pick_unique(loose, 9)
		_check(at9.is_empty() or str(at9["band"]) != "levelling", "a levelling unique came at T9: %s" % at9.get("name", ""))
		var at2: Dictionary = sim.pick_unique(loose, 2)
		_check(not at2.is_empty() and str(at2["band"]) == "levelling", "a %s unique came at T2: %s" % [str(at2.get("band", "")), at2.get("name", "")])
		var at4: Dictionary = sim.pick_unique(loose, 4)
		by_band[str(at4["band"])] += 1
	_check(by_band["levelling"] > by_band["core"] and by_band["chase"] == 0, "the bands' weights did not pick at T4: %s" % str(by_band))
	_check(sim.pick_unique(loose, 0).is_empty() and not sim.pick_unique(loose, 0, true).is_empty(), "a find outside every range dropped one, or a shop came up empty")
	# the shelf keeps the best tier found, through a save
	var hold_shelf: Array = sim.shelf.duplicate()
	sim.shelf = []
	sim.shelf_tier = {}
	sim._read(Items.roll_unique(steel, sim.rng, -1, 7))
	sim._read(Items.roll_unique(steel, sim.rng, -1, 5))
	_check(int(sim.shelf_tier.get(steel["name"], 0)) == 7, "the shelf did not keep the best tier: %s" % str(sim.shelf_tier))
	var round_trip = Sim.new()
	round_trip.start()
	round_trip.load_dict(sim.to_dict())
	_check(int(round_trip.shelf_tier.get(steel["name"], 0)) == 7, "the shelf's tiers did not save")
	# the mate: an offer with a tier, and what he sells is that tier
	sim.mate = sim.roll_mate()
	_check(sim.mate.has("tier") and int(sim.mate["notes"]) == Data.MATE_NOTES * int(sim.mate["tier"]), "the mate's offer has no tier: %s" % str(sim.mate))
	_check(int(sim._mate_item()["tier"]) == int(sim.mate["tier"]), "the mate's unique is not the tier he offered")
	sim.mate = {"unique": "Lucky Cap", "notes": 400}      # a save from before the tiers
	_check(int(sim._mate_item()["tier"]) == 1, "an old mate's offer did not roll at its own base's tier")
	sim.shelf = hold_shelf
	# the four gaps' rules
	var t: Dictionary = sim.effective(3)
	var search0: float = sim.search_s(t)
	sim.equipped["Helmet"] = Items.roll_unique(sim._unique_named("The Miner's Lamp"), sim.rng)
	_check(sim.search_s(t) < search0 * 0.5 + 0.01, "the Miner's Lamp did not halve the search: %.1f vs %.1f" % [sim.search_s(t), search0])
	sim.equipped["Helmet"] = null
	var med: Dictionary = sim._plain(Data.MEDICAL, Data.BASES[Data.MEDICAL][0]["name"])
	var heal0: float = sim.med_heal(med)
	var fire0: float = sim.dot_seconds("fire")
	var depth0: float = sim.dot_depth()
	sim.equipped["Rig"] = Items.roll_unique(sim._unique_named("The Paramedic's Bumbag"), sim.rng)
	_check(is_equal_approx(sim.med_heal(med), heal0 * 1.5), "the Bumbag's meds do not heal half again: %.1f vs %.1f" % [sim.med_heal(med), heal0])
	sim.rig = [med.duplicate()]
	sim.words[3] = []                    # no Rationed on the site: the med is allowed
	sim.deploy(3)
	var m: Dictionary = sim.mission
	sim.hp = sim.max_hp() * 0.3
	sim.advance(0.1)
	_check(m["using"] != null or sim.rig.is_empty(), "the Bumbag did not use a med under 40%")
	sim.extract_now()
	sim.equipped["Rig"] = Items.roll_unique(sim._unique_named("The Plumber's Belt"), sim.rng)
	_check(is_equal_approx(sim.dot_seconds("fire"), fire0) and is_equal_approx(sim.dot_depth(), depth0 * 2.0) and is_equal_approx(sim.dot_depth(false), 1.0) and is_equal_approx(sim.status_s(1.0), 2.0), "the Plumber's Belt did not double a dot's depth and a chill's length, or slowed the dot: %.1f s, ×%.1f" % [sim.dot_seconds("fire"), sim.dot_depth()])
	sim.equipped["Rig"] = null
	sim.equipped["Secondary"] = Items.roll_unique(sim._unique_named("The Starting Pistol"), sim.rng)
	sim.rig = [sim._plain(Data.AMMO, "Pistol rounds")]
	sim.deploy(3)
	m = sim.mission
	m["target_hp"] = 100000.0
	sim._starting_shot(m, m["t"])
	var after: float = float(m["target_hp"])
	var shot: float = 100000.0 - after
	_check(shot > 0.0 and m.get("opened", false), "the Starting Pistol's first shot did not land")
	sim.advance(0.05)
	_check(after - float(m["target_hp"]) < shot, "the Starting Pistol fired its first shot twice: %.0f then %.0f" % [shot, after - float(m["target_hp"])])
	sim.extract_now()
	sim.load_dict(saved)
	print("uniques by tier ok: bands and ranges, held in range, the body's mounts, a higher copy better, the sign lifted, the bands by tier, the shelf's best, the mate's tier, the four new rules")


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
	var council: Dictionary = Items.set_named("The Council's")
	_check(sim.set_count("The Council's") == 0 and sim.set_bonuses().is_empty(), "a bare runner has set bonuses")
	sim.equipped["Armour"] = Items.roll_set_piece("The Council's", council["pieces"][0], sim.rng)
	sim.equipped["Helmet"] = Items.roll_set_piece("The Council's", council["pieces"][1], sim.rng)
	_check(sim.set_count("The Council's") == 2 and is_equal_approx(sim.set_stat("all_res"), 20.0) and sim.resist("fire") >= 0.2, "two of the Council's did not give all resists +20")
	_check(not sim.has_set_rule("council"), "the Council's rule came at two")
	sim.equipped["Backpack"] = Items.roll_set_piece("The Council's", council["pieces"][2], sim.rng)
	sim.equipped["Charm"] = Items.roll_set_piece("The Council's", council["pieces"][3], sim.rng)
	_check(sim.set_count("The Council's") == 4 and sim.has_set_rule("council") and is_equal_approx(sim.set_stat("regen"), 4.0) and sim._affix_sum("search_pct") >= 30.0 + 8.0, "the full council's did not give it all: rule %s regen %.0f search %.0f" % [str(sim.has_set_rule("council")), sim.set_stat("regen"), sim._affix_sum("search_pct")])
	# the panel's line, in the set's tint
	main.show_room(main.ARMOURY)
	main._armoury._pick_slot("Armour")
	main.refresh()
	_check(main._armoury._head.text_nodes().any(func(r): return r.text.begins_with("The Council's · 4 of 4") or r.text == "4 of 4 worn"), "the panel's set chip is missing: %s" % str(main._armoury._head.text_nodes().map(func(r): return r.text)))
	_check_fit(main, "Armoury (a set)")
	# the Army's: contact down one, more ×1.3 at four
	for s in Data.SLOTS:
		sim.equipped[s] = null
	var army: Dictionary = Items.set_named("The Army's")
	sim.words[3] = []
	sim.weather[1] = ""                  # fog would take the one the set takes
	var t: Dictionary = sim.effective(3)
	var c0: int = sim.contact(t)
	for p in army["pieces"]:
		sim.equipped[p["slot"]] = Items.roll_set_piece("The Army's", p, sim.rng)
	_check(sim.contact(t) == c0 - 1 and is_equal_approx(sim.more("physical"), 1.3), "the Army's full set: contact %d of %d, more %.1f" % [sim.contact(t), c0, sim.more("physical")])
	# the Carpet Man's two: 30% bleed, bleeds last twice
	for s in Data.SLOTS:
		sim.equipped[s] = null
	sim.equipped["Primary"] = sim._plain("Primary", "Army SMG")
	var carpet: Dictionary = Items.set_named("The Carpet Man's")
	for p in carpet["pieces"]:
		sim.equipped[p["slot"]] = Items.roll_set_piece("The Carpet Man's", p, sim.rng)
	_check(is_equal_approx(sim.conversion()["bleed"], 0.3) and is_equal_approx(sim.dot_seconds("bleed"), 12.0), "the Carpet Man's: bleed %.2f seconds %.0f" % [sim.conversion()["bleed"], sim.dot_seconds("bleed")])
	# drops by depth: nothing at depth 1, pieces by depth 12, no army's before 15
	# (the Fire Crew's three at depth 9 join the count from 12 on)
	_check(sim.set_pieces_at(1).is_empty() and sim.set_pieces_at(5).size() == 6 and sim.set_pieces_at(12).size() == 15 and sim.set_pieces_at(15).size() == 19, "the sets' depth gates are off: %d / %d / %d / %d" % [sim.set_pieces_at(1).size(), sim.set_pieces_at(5).size(), sim.set_pieces_at(12).size(), sim.set_pieces_at(15).size()])
	sim.load_dict(saved)
	print("sets ok: the pieces, the count, the bonuses, the rules, the tint, the panel, the gates")
	_atlas_checks(main)


## The map: a point a new depth past the first, the passives, their effects.
func _atlas_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	_finish_campaign(sim)
	sim.atlas = {}
	sim.atlas_points = 0
	_open_map(main)
	_check(main._radio.view == "map" and main._radio._atlas.visible, "the map did not open on the Radio after the campaign")
	_check_fit(main, "Radio (the map, empty)")
	# a clear at depth 2 earns a point; depth 1 does not
	sim.set_depth(3, 1)
	var t1: Dictionary = sim.effective(3)
	sim.best_depth[3] = 0
	sim.deploy(3)
	sim._clear(sim.mission, t1)
	sim.extract_now()
	_check(sim.atlas_points == 0, "a depth-1 clear put a point on the map")
	sim.set_depth(3, 2)
	var t2: Dictionary = sim.effective(3)
	sim.deploy(3)
	sim._clear(sim.mission, t2)
	sim.extract_now()
	_check(sim.atlas_points == 1 and sim.atlas_free() == 1, "a depth-2 clear did not earn a point: %d" % sim.atlas_points)
	sim.deploy(3)
	sim._clear(sim.mission, t2)
	sim.extract_now()
	_check(sim.atlas_points == 1, "clearing the same depth again earned a point")
	# the ranks and their effects
	var patrol0: float = sim.patrol_s(t2)
	var search0: float = sim.search_s(t2)
	var cost0: int = sim.word_craft_cost(3, "retune")
	var notes0: int = sim.notes_a_kill(t2)
	# the lanes (9 Oct): a column opens on the points spent in its lane, two nodes to a column
	_check(sim.atlas_open("picked_over") and sim.atlas_open("deeper_pockets") and not sim.atlas_open("quiet_roads") and not sim.can_rank_atlas("quiet_roads"), "the sites' second column is open with nothing spent in the lane")
	_check(sim.rank_atlas("picked_over") and sim.atlas_rank("picked_over") == 1, "a rank did not take")
	_check(not sim.rank_atlas("deeper_pockets"), "a rank took with no point free")
	sim.atlas_points += 10
	_check(not sim.atlas_open("heads_up") and sim.atlas_col("heads_up") == 1, "the crews' lane reads the sites' points")
	_check(sim.rank_atlas("deeper_pockets") and sim.atlas_in_lane(0) == 2 and sim.atlas_open("quiet_roads") and sim.rank_atlas("quiet_roads") and sim.atlas_rank("quiet_roads") == 1, "the second column did not open at two points in the lane")
	_check(not sim.atlas_open("easy_pickings"), "the sites' fourth column opened at three points")
	_check(sim.patrol_s(t2) > patrol0 * 1.09, "Quiet roads did not slow the gangs")
	for i in range(2):
		sim.rank_atlas("deeper_pockets")
	_check(sim.atlas_rank("deeper_pockets") == 3 and not sim.can_rank_atlas("deeper_pockets"), "Deeper pockets went past its max")
	_check(sim.search_s(t2) < search0 * 0.75, "Deeper pockets did not quicken searches")
	_check(sim.rank_atlas("good_reception") and sim.word_craft_cost(3, "retune") <= int(ceil(cost0 * 0.85)) and sim.word_craft_cost(3, "retune") < cost0 + 1, "Good reception did not cheapen the crafts: %d from %d" % [sim.word_craft_cost(3, "retune"), cost0])
	_check(sim.rank_atlas("paid_in_notes") and sim.notes_a_kill(t2) == notes0 + 1, "Paid in notes did not add a note")
	_check(sim.rank_atlas("two_of_everything"), "Two of everything did not take")
	# the boss drops two with it
	sim.notes += 1000
	sim.arm_boss(5, true)
	sim.set_depth(5, 1)
	sim.deploy(5)
	var m: Dictionary = sim.mission
	m["boss"] = {"name": sim.boss_of(5)["name"], "zone": 0, "alive": true, "hp": 1.0, "started": true}
	var found_before: int = m["found"].size()
	sim._boss_down(m, sim.effective(5))
	_check(m["found"].size() == found_before + 2, "Two of everything did not drop a second: %d" % (m["found"].size() - found_before))
	sim.extract_now()
	_open_map(main)
	_check_fit(main, "Radio (the map, ranked)")
	_map_screen_checks(main)
	_site_level_checks(main)
	main._radio._reset_map()
	_check(sim.atlas_spent() == 0 and sim.atlas_free() == sim.atlas_points, "starting the map again did not refund")
	main._radio._pick_view("air")
	# the round trip keeps it
	sim.rank_atlas("picked_over")
	var d: Dictionary = sim.to_dict()
	sim.load_dict(d)
	_check(sim.atlas_rank("picked_over") == 1 and sim.atlas_points == 11, "the map did not survive a save")
	_map_nodes_checks(main)
	sim.load_dict(saved)
	print("the map ok: points, ranks, effects, two of everything, reset")
	_contracts_checks(main)


## The Fence's contracts: three open, hand in the cheapest that fit, paid in
## cash, notes or a unique; the mate sells a unique for notes.
func _contracts_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	_check(sim.contracts.size() == Data.CONTRACTS_OPEN, "the Fence has %d contracts open, not %d" % [sim.contracts.size(), Data.CONTRACTS_OPEN])
	_check(not sim.mate.is_empty() and sim.mate["notes"] > 0, "the Fence's mate has nothing: %s" % str(sim.mate))
	for i in range(60):
		var c: Dictionary = sim.roll_contract()
		_check(c["count"] >= 1 and c["count"] <= 5 and c["rarity"] >= 1 and c["rarity"] <= 2, "a contract rolled outside its bounds: %s" % str(c))
		_check(c["pay"] in Data.CONTRACT_PAYS and c["amount"] > 0, "a contract pays nothing, or not in currency: %s" % str(c))
	# a cash contract: two uncommon helmets, hand in through the screen
	sim.contracts[0] = {"kind": "gear", "slot": "Helmet", "rarity": 1, "count": 2, "level": 0, "stat": "", "pay": "cash", "amount": 500, "salvage": ""}
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
	# notes, and the mate
	sim.contracts[1] = {"kind": "gear", "slot": "Helmet", "rarity": 2, "count": 1, "level": 0, "stat": "", "pay": "notes", "amount": 12, "salvage": ""}
	var rare: Dictionary = sim._plain("Helmet", "Hard hat")
	rare["rarity"] = 2
	sim.stash.append(rare)
	var notes0: int = sim.notes
	_check(sim.hand_in(1) and sim.notes == notes0 + 12 * (2 if sim.yard_has("fixer") else 1), "a notes contract did not pay")
	sim.passes = 0
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
		sim.deploy(3)
		sim.extract_now()
		changed = changed or sim.mate["unique"] != offer
	_check(sim.runs_total == runs0 + Data.MATE_RUNS, "runs_total did not count the runs")
	main._fence._show("contracts")
	_check_fit(main, "Fence (contracts, after)")
	# the contracts show from the rail and the tab when one's ready; what's next says so
	sim.contracts = [{"kind": "gear", "amount": 400, "count": 3, "pay": "cash", "rarity": 2, "slot": "Attachment", "level": 0, "stat": "", "salvage": ""}]
	for it in sim.stash.duplicate():
		if sim.contract_fits(sim.contracts[0], it):
			sim.stash.erase(it)              # nothing in the stash to hand in: open, not ready
	main.refresh()
	var fence_status: Dictionary = main._rail_status(main.MARKET) if main.has_method("_rail_status") else {}
	_check(fence_status.get("badge", "") == "", "the rail flags a contract that isn't ready: %s" % str(fence_status))
	main.show_room(main.MARKET)
	main.refresh()
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
		sim.contracts[0] = {"kind": "gear", "slot": "Helmet", "rarity": 1, "count": 2, "level": 0, "stat": "", "pay": "scrap", "amount": 20, "salvage": ""}
		main._fence._show("contracts")
		main._fence._shown = ""
		main.refresh()
		var t0: String = main._fence._deal_rows[0]["have"].text
		_check(t0.begins_with("Wants") or t0.begins_with("Could") or t0.begins_with("Someone") or t0.contains("wanted") or t0.begins_with("Looking"), "the Fence's line is not in his voice: '%s'" % t0)
		_check(main._fence._deal_rows[0]["title"].text == "Two uncommon helmets", "the ask is not the row's title: '%s'" % main._fence._deal_rows[0]["title"].text)
		# every affix the Fence can ask for is named on the row, whole or short
		for slot in Data.CONTRACT_SLOTS.slice(0, Data.CONTRACT_SLOTS.size() - 1):
			for a in Items.allowed_affixes(slot):
				sim.contracts[0] = {"kind": "affix", "slot": slot, "rarity": 1, "count": 1, "level": 0, "stat": a["stat"], "pay": "notes", "amount": 5, "salvage": ""}
				main._fence._shown = ""
				main.refresh()
				var tt: String = main._fence._deal_rows[0]["title"].text
				_check(tt.contains(sim.contract_affix_phrase(a["stat"])) or tt.ends_with(str(a["short"])), "an affix ask does not name its affix: '%s' for %s on a %s" % [tt, a["stat"], slot])
				_check(main._fence._deal_rows[0]["have"].text != "", "the Fence's line went blank for %s on a %s" % [a["stat"], slot])
		_check(sim.contract_words({"kind": "affix", "slot": "Armour", "stat": "conv_fire_pct", "count": 1}) == "an armour with fire conversion", "the affix ask reads '%s'" % sim.contract_words({"kind": "affix", "slot": "Armour", "stat": "conv_fire_pct", "count": 1}))
		_check_fit(main, "Fence (contracts in the voice)")
	print("contracts and the mate ok: three open, the cheapest that fit, cash, notes, the mate")
	_events_checks(main)


## The run's events: a convoy, someone trapped, a locked cache.
func _events_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	var fired := 0
	for i in range(40):
		sim.deploy(3)
		if sim.mission["event"] != "":
			fired += 1
			_check(sim.mission["event_at"] >= Data.EVENT_WINDOW[0] and sim.mission["event_at"] <= Data.EVENT_WINDOW[1], "an event is timed outside its window")
		sim.extract_now()
	_check(fired > 3 and fired < 25, "events on %d of 40 runs; 30%% was the aim" % fired)
	# a convoy: a bigger gang, and their notes
	sim.deploy(3)
	var m: Dictionary = sim.mission
	m["remaining"] = 0
	m["cleared"] = true
	m["event"] = "convoy"
	m["event_at"] = 0.0
	var notes0: int = int(m.get("notes", 0))
	sim.advance(0.1)
	_check(m["remaining"] == sim.PATROL_BASE + 2 and int(m["notes"]) > notes0 and m["event_done"] == "convoy" and m["event_at"] < 0.0, "the convoy did not come: %d left, %d notes" % [m["remaining"], int(m["notes"])])
	# and the run screen counts them (8 Oct, Matt: "11 of 10 down"): the bar's "of" is the pool as it stands, with the
	# convoy's crew in, and the band says a convoy came
	m["cleared"] = false
	m["kills"] = int(sim.tier(3)["pool"])
	main.show_room(main.MISSIONS)
	main.refresh()
	var bar_words: String = main._run._band._bar_label.text
	_check(bar_words == "%d of %d down" % [m["kills"], m["kills"] + m["remaining"]], "the run's bar reads the site's pool with a convoy's crew in: '%s'" % bar_words)
	_check(main._run._band.right[1].text.contains("convoy"), "the band does not say a convoy came: '%s'" % main._run._band.right[1].text)
	sim.extract_now()
	# someone trapped: a trait promised to the next arrival
	sim.promised = ""
	sim.deploy(3)
	m = sim.mission
	m["event"] = "trapped"
	m["event_at"] = 0.0
	sim.advance(0.1)
	_check(sim.promised != "" and sim.promised != sim.runner_trait, "the trapped runner promised nothing: %s" % sim.promised)
	sim.extract_now()
	sim.promised = ""
	# a cache: opened at any Bench (9 Oct: it wanted Bench 2)
	sim.deploy(3)
	m = sim.mission
	m["event"] = "cache"
	m["event_at"] = 0.0
	m["remaining"] = 999                   # keep the search from finding on its own
	var found0: int = m["found"].size()
	sim.advance(0.1)
	_check(m["found"].size() == found0 + 1, "the cache did not open")
	sim.extract_now()
	sim.load_dict(saved)
	print("events ok: the convoy, the trapped runner, the cache")
	_pinnacle_checks(main)


## Pinnacles from depth 10: dearer, harder, their charm in the pool. The
## convoy on the Services from depth 12: all three, one after another, and
## the Lorry's Load at the end.
func _pinnacle_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	_finish_campaign(sim)
	sim.notes += 100000
	for i in range(Data.TIERS.size()):
		sim.best_depth[i] = 20
	# the Carpet Man a depth short of full strength and at it (the Retail Park's at 12, the Bank's at 9, the Barracks' at 6: level 14 on each)
	var pd: int = sim.pinnacle_depth(5)
	_check(pd == 12 and sim.pinnacle_depth(8) == 9 and sim.pinnacle_depth(11) == 6, "the stations' depths are off: %d %d %d" % [pd, sim.pinnacle_depth(8), sim.pinnacle_depth(11)])
	sim.set_depth(5, pd - 1)
	sim.arm_boss(5, true)
	var cost9: int = sim.boss_cost(5)
	var e9: Dictionary = sim.effective(5)
	sim.set_depth(5, pd)
	_check(sim.is_pinnacle(5) and not sim.is_pinnacle(4), "depth %d is not a pinnacle" % pd)
	var e10: Dictionary = sim.effective(5)
	_check(e10["boss"]["pinnacle"] and not e9["boss"].get("pinnacle", false), "the boss at depth %d is not at full strength" % pd)
	# full strength is twice the crew at the same fire (the sixteenth read: a fire multiplier reads 0.00 whatever the HP)
	var site_step: float = float(e10["dps"]) / float(e9["dps"])        # the depth's own step, the only change in the fire
	_check(e10["boss"]["hp"] > e9["boss"]["hp"] * 1.8 * site_step * 0.95 and is_equal_approx(e10["boss"]["dps"] / e9["boss"]["dps"], site_step), "the pinnacle is not twice the crew at the same fire: hp ×%.2f, dps ×%.2f against the site's ×%.2f" % [e10["boss"]["hp"] / e9["boss"]["hp"], e10["boss"]["dps"] / e9["boss"]["dps"], site_step])
	_check(sim.boss_cost(5) > cost9 * 1.8, "the pinnacle costs no more: %d vs %d" % [sim.boss_cost(5), cost9])
	# their charm comes from the pinnacle and never from the ordinary fight
	var charms := 0
	var m: Dictionary
	for k in range(40):
		sim.arm_boss(5, true)
		sim.deploy(5)
		m = sim.mission
		m["boss"]["started"] = true
		sim._boss_down(m, sim.effective(5))
		for it in m["found"]:
			if it.get("unique", "") == "The Van Keys":
				charms += 1
		sim.extract_now()
	_check(charms > 3 and charms < 30, "the Van Keys came %d of 40 pinnacle kills; a third was the aim" % charms)
	sim.set_depth(5, 5)
	charms = 0
	for k in range(30):
		sim.arm_boss(5, true)
		sim.deploy(5)
		m = sim.mission
		m["boss"]["started"] = true
		sim._boss_down(m, sim.effective(5))
		for it in m["found"]:
			if it.get("unique", "") == "The Van Keys":
				charms += 1
		sim.extract_now()
	_check(charms == 0, "the Van Keys came from the Carpet Man under full strength")
	# the convoy: the Services at convoy_depth() (8 on the first yard, a depth deeper a move)
	sim.set_depth(Data.CONVOY_TIER, Data.CONVOY_DEPTH - 1)
	_check(not sim.is_convoy(Data.CONVOY_TIER) and not sim.can_arm_boss(Data.CONVOY_TIER), "the convoy came before depth %d" % Data.CONVOY_DEPTH)
	sim.set_depth(Data.CONVOY_TIER, Data.CONVOY_DEPTH)
	_check(sim.is_convoy(Data.CONVOY_TIER) and sim.can_arm_boss(Data.CONVOY_TIER), "the convoy is not on the Services at depth %d" % Data.CONVOY_DEPTH)
	var convoy_cost: int = sim.boss_cost(Data.CONVOY_TIER)
	var three := 0
	for b in Data.BOSSES:
		three += int(b["notes"]) * Data.CONVOY_DEPTH                # the plain three (8 Oct)
	_check(convoy_cost == three, "the convoy's price is %d, not the three heads' %d" % [convoy_cost, three])
	sim.arm_boss(Data.CONVOY_TIER, true)
	sim.words[Data.CONVOY_TIER] = []      # the plain site: the heads are formed before the words multiply the site
	var ec: Dictionary = sim.effective(Data.CONVOY_TIER)
	_check(ec.get("convoy", false) and ec["boss_queue"].size() == 2 and not ec["boss"]["pinnacle"], "the convoy is not three in a row, come light")
	var cm_hp: float = float(ec["hp"]) * float(Data.BOSSES[0]["hp"]) * Data.CONVOY_HP
	var cm_dps: float = float(ec["dps"]) * float(Data.BOSSES[0]["dps"]) * Data.CONVOY_DPS
	_check(is_equal_approx(float(ec["boss"]["hp"]), cm_hp) and is_equal_approx(float(ec["boss"]["dps"]), cm_dps), "the convoy's first head is not light and tired: %.0f/%.1f against %.0f/%.1f" % [float(ec["boss"]["hp"]), float(ec["boss"]["dps"]), cm_hp, cm_dps])
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(3)
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
	_check(names == ["The Carpet Man", "The Manager", "The Quartermaster"], "the convoy came in the wrong order: %s" % str(names))
	var load := false
	for it in m["found"]:
		load = load or it.get("unique", "") == Data.CONVOY_UNIQUE
	_check(load and m["found"].size() >= found0 + 4, "the Lorry's Load did not come with the three drops: %d found" % (m["found"].size() - found0))
	# the ending (7 Oct): the lorry beaten is written, the Yard says to move, the move lights
	_check(sim.lorry_done and sim.lorries == 1 and sim.next_words() == Words.NEXT["lorry"] and sim.events.any(func(e): return str(e[1]).begins_with("The Lorry's Load is yours")), "the lorry beaten was not written: done %s, lorries %d, next '%s'" % [str(sim.lorry_done), sim.lorries, sim.next_words()])
	sim.extract_now()
	main.show_room(main.OVERVIEW)
	main.refresh()
	_check(main._yard_tree._move.visible and main._yard_tree._foot.text.begins_with("The lorry's beaten"), "the Yard does not light the move at the lorry: button %s, note '%s'" % [str(main._yard_tree._move.visible), main._yard_tree._foot.text])
	_endgame_move_checks(main)
	# the rules: the keys drive, the pen doubles the notes, the ledger a tier up, the load fills the pack
	var pace0: float = sim.pace()
	var was_charm = sim.equipped["Charm"]
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The Van Keys"), sim.rng)
	_check(sim.pace() > pace0 * 1.2, "the Van Keys did not drive")
	sim.equipped["Charm"] = Items.roll_unique(sim._unique_named("The Manager's Pen"), sim.rng)
	for oi in Data.ZONES[0]["tiers"]:
		sim.best_depth[oi] = maxi(1, int(sim.best_depth[oi]))     # the moved yard's Outskirts walked, so the Streets are open (12 Oct)
	var n0: int = sim.notes
	sim.deploy(3)
	sim.mission["notes"] = 7
	sim.extract_now()
	_check(sim.notes == n0 + 14, "the Manager's Pen did not double the notes: +%d" % (sim.notes - n0))
	sim.equipped["Charm"] = was_charm
	var was_pack = sim.equipped["Backpack"]
	sim.equipped["Backpack"] = Items.roll_unique(sim._unique_named("The Lorry's Load"), sim.rng)
	n0 = sim.notes
	sim.set_depth(3, 3)
	sim.deploy(3)
	sim.mission["found"] = []
	sim.mission["notes"] = 0
	sim.extract_now()
	_check(sim.notes == n0 + sim.capacity() * 3, "the Lorry's Load did not fill the empty pack with notes: +%d of %d (depth %d, best %d, campaign %s)" % [sim.notes - n0, sim.capacity() * 3, sim.depth[3], sim.best_depth[3], str(sim.campaign_done())])
	sim.equipped["Backpack"] = was_pack
	for name in ["The Van Keys", "The Manager's Pen", "The Quartermaster's Ledger", "The Lorry's Load"]:
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
	# the Bench
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
	# the Bench works as a drop does (the pass, 6 Oct): re-roll one within the rarity's cap, never under the level's floor
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
		_check(sim.craft_cost(set_piece, kind, set_piece["affixes"][0]["stat"] if not set_piece["affixes"].is_empty() else "") < 0, "the Bench offers %s on a set piece" % kind)
	# not on a unique, not on paper, not without a bench, not on a run, not short
	var u := Items.roll_unique(Data.UNIQUES[0], sim.rng)
	sim.stash.append(u)
	_check(sim.craft_cost(u, "reroll") < 0, "a unique re-rolls")
	sim.cash = 0.0
	_check(not sim.can_craft(it["id"], "add"), "the Bench works with no cash")
	sim.cash = 100000.0
	var ch: Dictionary = sim._plain("Charm", "Lucky penny")
	_check(sim.craft_cost(ch, "add") > 0 and sim.craft_cost(ch, "socket") < 0, "a charm takes no affix at the Bench, or takes a socket")
	# through the screen: the Bench button and the menus
	main.show_room(main.ARMOURY)
	main._armoury.selected = {"kind": "stash", "id": it["id"]}
	main.refresh()
	_check_fit(main, "Armoury (bench button)")
	# the Workshop button opens the Workshop on the piece (9 Oct): the old menu is gone
	_check(not main.has_method("_open_bench") and not main.has_method("_open_bench_picks"), "the old Bench menu is still in the shell")
	var wb: int = -1
	for k in range(main._armoury._pick._buttons.size()):
		if main._armoury._pick._buttons[k].visible and main._armoury._pick._buttons[k].text == "Workshop":
			wb = k
	_check(wb >= 0, "the Runner room has no Workshop button on a stash piece")
	main._menu.close()                   # a Yard arrival's popup can be up from the run before: not the Workshop's
	if wb >= 0:
		main._armoury._pick.press(wb)
	main.refresh()
	_check(main.room == main.WORKSHOP and main._workshop.view == "craft" and main._workshop._selected_item() == it and not main._menu.visible, "the Workshop button did not open the Workshop's Craft view on the piece (%s, %s, %s, %s)" % [main.room, main._workshop.view, str(main._workshop.sel_id), str(main._menu.visible)])
	_check_fit(main, "Workshop (from the Runner room)")
	main._craft(it["id"], "add", "")
	_check(it["rarity"] == 1 and not main._menu.visible, "the menu's Add did not take")
	# the Bench says what it did: a toast with the affix added, the same on the craft panel's line, and in the log
	var added_line: String = Items.affix_lines(it, false, true)[0]
	_check(sim.last_craft.get("id", -1) == it["id"] and str(sim.last_craft["words"]) == "Added " + added_line, "the Bench's words are '%s', not 'Added %s'" % [str(sim.last_craft.get("words", "")), added_line])
	_check(main._juice.lines().has(sim.last_craft["words"]), "the Bench's words did not toast: %s" % str(main._juice.lines()))
	_check(str(sim.events.back()[1]).ends_with(sim.last_craft["words"]), "the log line does not carry the Bench's words: '%s'" % str(sim.events.back()[1]))
	main.show_room(main.WORKSHOP)
	main._workshop._set_view("craft")
	_check(main._workshop._craftable().any(func(c): return c["id"] == it["id"]), "the added-to piece is not in the Craft view")
	var hold_value = it["value"]
	it["value"] = 9999999                                        # the dearest, so it sorts to the first page whatever the stash holds (a flake: it had landed on page two)
	main._workshop._shown = ""
	main.refresh()
	var kc: int = main._workshop._inv.cell_of(it["id"])        # the grid's own cell (two pieces of one value can sort either way)
	_check(kc >= 0, "the added-to piece has no cell in the Craft view's grid")
	if kc >= 0:
		main._workshop._pick_cell(kc)
	main.refresh()
	_check(main._workshop._foot.text.begins_with("Added"), "the jobs' foot does not say what the Bench did: '%s'" % main._workshop._foot.text)
	_check_fit(main, "Workshop (craft, after an add)")
	it["value"] = hold_value
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
	# a worn piece: the Workshop works on it in place, and won't scrap it off the runner
	var worn_gun = sim.equipped["Primary"]
	if worn_gun != null and not worn_gun.has("unique") and not worn_gun.has("set"):
		main._open_workshop(worn_gun["id"])
		_check(main.room == main.WORKSHOP and main._workshop._selected_item() == worn_gun, "the Workshop did not pick the worn gun")
		var sk: int = main._workshop.JOBS.find("scrap")
		_check(main._workshop._job_tiles[sk]["button"].disabled and main._workshop._job_tiles[sk]["price"].text == "", "the Workshop offers to scrap a worn gun")
		_check_fit(main, "Workshop (a worn piece)")
		var r0: int = int(worn_gun["rarity"])
		sim.cash = 999999.0
		_check(sim.craft_cost(worn_gun, "add") >= 0, "the worn gun can't take an affix: the job checks below would skip")
		if sim.craft_cost(worn_gun, "add") >= 0:
			sim._surv_cache[3] = ["held", 0.5]           # odds read before the job
			main._craft(worn_gun["id"], "add", "")
			_check(not sim._surv_cache.has(0), "a job on a worn gun left the odds as they were read before it")
			_check(sim.equipped["Primary"] == worn_gun and int(worn_gun["rarity"]) >= r0 and sim.last_craft.get("id", -1) == worn_gun["id"], "the Workshop's job on a worn gun did not take")
		main._workshop.sel_id = -1
	# a part: the Workshop button opens the Guns view with its mount picked, not Craft (the review, 9 Oct)
	var part_base: Dictionary = {}
	for a in Data.ATTACHMENTS:
		if not str(a.get("mount", "")).begins_with("socket") and a.get("mount", "") != "":
			part_base = a
			break
	if not part_base.is_empty():
		var part: Dictionary = sim._plain(Data.ATTACHMENT, part_base["name"])
		sim.stash.append(part)
		main._open_workshop(part["id"])
		_check(main.room == main.WORKSHOP and main._workshop.view == "guns" and main._workshop.sel_mount == part["mount"] and main._workshop._selected_item() == part, "the Workshop button on a part did not open the Guns view on its mount (%s, '%s')" % [main._workshop.view, main._workshop.sel_mount])
		_check_fit(main, "Workshop (a part from the Runner room)")
		sim.stash.erase(part)
		main._workshop.sel_id = -1
		main._workshop.sel_mount = ""
		main._workshop.sel_slot = ""
	main.show_room(main.ARMOURY)
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
	# worn gear can go to the Bench too
	var worn: Dictionary = sim.equipped["Armour"]
	if worn != null and not worn.has("unique") and sim.craft_cost(worn, "socket") >= 0 and is_same(sim.item_by_id(worn["id"]), worn):
		var n0: int = Items.sockets(worn)
		var scost: int = sim.craft_cost(worn, "socket")
		_check(sim.craft(worn["id"], "socket") and Items.sockets(worn) == n0 + 1, "a socket did not cut on the armour worn: cost %d, cash %.0f, can %s, sockets %d, slot %s" % [scost, sim.cash, str(sim.can_craft(worn["id"], "socket")), Items.sockets(worn), worn["slot"]])
	sim.load_dict(saved)
	print("the Bench ok: tiers, add, re-roll, lock, one, the level, sockets, strip, the menus")


## Moving the Yard: after the campaign; the uniques, the Yard's tree, the
## list and half the notes come; the rest starts again; the move's bonus.
func _move_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	sim.load_dict(saved)
	_check(not sim.can_move_yard() or sim.campaign_done(), "the Yard moves before the campaign")
	_finish_campaign(sim)
	sim.notes = 1000
	sim.cash = 500000.0
	var u := Items.roll_unique(Data.UNIQUES[0], sim.rng)
	sim.stash.append(u)
	var worn_u := Items.roll_unique(sim._unique_named("Lucky Cap"), sim.rng)
	sim.equipped["Helmet"] = worn_u
	sim.training_points += 10
	sim.train_node("The Yard/0")
	var yard_nodes := 0
	for id in sim.tree:
		if str(id).begins_with("The Yard/"):
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
	_set_cls(sim, "Doorman")
	_check(not sim.affinity("poison") and sim.can_trade("poison") and not sim.can_trade("physical"), "the trade offers the wrong things")
	main._move_yard("poison")
	_check(sim.yard_moves == 1, "the Yard did not move")
	_check(sim.trades == ["poison"] and sim.affinity("poison") and not sim.can_trade("poison") and sim.node_cost("The rat man/0") == 1, "the Yard's trade did not come: %s" % str(sim.trades))
	_check(str(sim.events[-2][1]).begins_with("The Yard's trade came too: the rat man"), "the trade had no line: %s" % str(sim.events[-2]))
	_check(str(sim.events[-3][1]).begins_with("The Yard moves"), "the move had no line")
	_check(str(sim.events.back()[1]) == Words.NEXT["moved"], "the move did not say what's next: %s" % str(sim.events.back()))
	sim.training_points += 20
	for i in range(7):
		sim.train_node("The rat man/%d" % i)
	_check(sim.tree.has("The rat man/6"), "the traded keystone did not open to a class without the affinity")
	for i in range(7):
		sim.tree.erase("The rat man/%d" % i)
	sim.training_points -= 20
	_check(not sim.campaign_done() and sim.best_depth[3] == 0 and not sim.zone_open(2), "the move did not start again")
	_check(sim.notes == 500 and is_equal_approx(sim.cash, float(Data.STARTING_CASH) * sim.inflation()), "the move kept the wrong money: %d notes, £%.0f (the Float at today's prices is £%.0f)" % [sim.notes, sim.cash, float(Data.STARTING_CASH) * sim.inflation()])
	var kept := 0
	for it in sim.stash:
		if it.has("unique"):
			kept += 1
	_check(kept >= 2 and kept == uniques_before and (sim.equipped["Helmet"] == null or not sim.equipped["Helmet"].has("unique")), "the uniques did not come to the stash: %d of %d" % [kept, uniques_before])
	var yard_after := 0
	for id in sim.tree:
		if str(id).begins_with("The Yard/"):
			yard_after += 1
	_check(yard_after == yard_nodes and sim.tree.size() == yard_nodes, "the Yard's tree did not come alone: %s" % str(sim.tree))
	_check(sim.points_free() == Data.MOVE_POINTS, "the move's points are %d, not %d" % [sim.points_free(), Data.MOVE_POINTS])
	_check(sim.past.size() == past_n, "the list of runners before did not come")
	_check(sim.rarity_bonus() > 0.04 and sim.charm_cash() >= Data.MOVE_CASH, "the move's bonus did not read: find %.2f, cash %.0f" % [sim.rarity_bonus(), sim.charm_cash()])
	_check(sim.contracts.size() == Data.CONTRACTS_OPEN and not sim.mate.is_empty(), "the Fence did not set up again")
	main.refresh()
	_check_fit(main, "The Yard (moved)")
	var d: Dictionary = sim.to_dict()
	sim.load_dict(d)
	_check(sim.yard_moves == 1 and sim.trades == ["poison"], "the move and its trade did not survive a save")
	sim.load_dict(saved)
	print("moving the Yard ok: the uniques, the tree, the list, the notes, the bonus, the Yard's trade")
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
	_chronicle_checks()


## The estate recycles: a dead runner's worn kit and a unique sold to the Fence
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
	for name in ["A ration book", "A council minute", "A bus timetable, amended", "A letter to the Bank", "A list of names", "The Manager's note"]:
		_check(Words.item_words(name) != "" and Words.item_words(name).ends_with("."), "%s has no line" % name)
	# a find is read, once, in order
	sim.words[3] = []
	sim.set_depth(3, 1)
	sim.hp = sim.max_hp()
	sim.deploy(3)
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
	# the Caravan's drawer: an Also chip, over the lanes when pressed, three columns of cards
	main.show_room(main.BARRACKS)
	var bk = main._barracks
	_check(bk.also_names().has("The drawer") and bk.also_button("The drawer") != null, "the drawer is not in the Also row")
	bk.pick_also("The drawer")
	main.refresh()
	_check(bk.also_button("The drawer").text.contains("2 of 20"), "the drawer's chip is off: %s" % bk.also_button("The drawer").text)
	_check(bk._cells[0]["name"].text == "1. A P45" and bk._cells[1]["name"].text == "2. A betting slip" and not bk._cells[2]["button"].visible, "the drawer's cards are off: %s / %s" % [bk._cells[0]["name"].text, bk._cells[1]["name"].text])
	_check(bk._cells[0]["lines"][0].text != "", "the paper's words are not under its name")
	_check_fit(main, "Caravan (the drawer, two)")
	for name in pages:
		sim._read(sim._plain(Data.PAPER, name))
	_check(sim.book.size() == 20, "the full book is not twenty")
	bk._shown = ""
	main.refresh()
	# a page holds what the lanes' area takes; twenty papers are that many pages
	var per_page: int = bk._cells.filter(func(n): return n["button"].visible).size()
	var n_pages: int = ceili(20.0 / per_page)
	_check(per_page >= 3 and (n_pages == 1 or bk.also_button("The drawer").text.contains("page 1 of %d" % n_pages)), "a full drawer's pages are off: %s (%d a page)" % [bk.also_button("The drawer").text, per_page])
	_check_fit(main, "Caravan (the drawer, full)")
	bk._turn_page()
	_check(bk.drawer_page == 1 and (n_pages == 1 or bk._cells[0]["name"].text.begins_with("%d. " % (per_page + 1))), "a click did not turn the page: %d, %s" % [bk.drawer_page, bk._cells[0]["name"].text])
	_check_fit(main, "Caravan (the drawer, page 2)")
	bk.pick_also("The drawer")
	main.refresh()
	_check(bk.alt == "" and bk._lanes[0]["panel"].visible and not bk._cells[0]["button"].visible, "the drawer pressed again did not give the lanes back")
	_check_fit(main, "Caravan (back from the drawer)")
	var d: Dictionary = sim.to_dict()
	sim.load_dict(d)
	_check(sim.book.size() == 20, "the book did not save")
	# the shelf: the uniques found, the same way
	sim.shelf = []
	var u1: Dictionary = Items.roll_unique(sim._unique_named("Lucky Cap"), sim.rng)
	sim._read(u1)
	sim._read(Items.roll_unique(sim._unique_named("Lucky Cap"), sim.rng))
	sim._read(Items.roll_unique(sim._unique_named("Jump Leads"), sim.rng))
	_check(sim.shelf == ["Lucky Cap", "Jump Leads"], "the shelf is not the uniques in the order found: %s" % str(sim.shelf))
	bk.pick_also("The shelf")
	main.refresh()
	_check(bk.also_button("The shelf").text.contains("2 of %d" % Data.UNIQUES.size()), "the shelf's chip is off: %s" % bk.also_button("The shelf").text)
	# the chase first (endgame part 3): thirteen gaps in TEXT_3, where each is under it; then the rest found, in order
	var chase: Array = sim.shelf_chase()
	_check(chase.size() == 13 and not chase[0]["found"] and str(chase[0]["where"]).begins_with("Ransacked Streets, depth 12"), "the shelf's chase is off: %d rows, '%s'" % [chase.size(), str(chase[0]["where"]) if not chase.is_empty() else ""])
	var row0: Dictionary = bk._cells[0]
	_check(row0["name"].text == "1. %s" % chase[0]["name"] and row0["lines"][0].text.begins_with("Ransacked Streets") and row0["name"].get_theme_color("font_color") == Pal.TEXT_3, "the shelf's first gap is off: '%s' / '%s'" % [row0["name"].text, row0["lines"][0].text])
	var shelf_branch: Dictionary = main._barracks._shelf_branch()
	var all_names: Array = []
	for pg in range(int(shelf_branch["pages"])):
		main._barracks.drawer_page = pg
		for nd in main._barracks._shelf_branch()["nodes"]:
			all_names.append(str(nd["name"]).substr(str(nd["name"]).find(" ") + 1))
	_check(all_names.size() == 15 and all_names[13] == "Lucky Cap" and all_names[14] == "Jump Leads" and all_names[12] == Data.CONVOY_UNIQUE, "the shelf's order is off: %s" % str(all_names))
	main._barracks.drawer_page = 0
	_check_fit(main, "Caravan (the shelf)")
	# a site's own found fills its gap
	sim._read(Items.roll_unique(sim._unique_named("The Float"), sim.rng))
	chase = sim.shelf_chase()
	_check(chase[4]["found"] and chase[4]["name"] == "The Float" and not chase[3]["found"], "the Float on the shelf did not fill the Shopping Centre's gap")
	main._barracks._shown = ""
	main.refresh()
	_check_fit(main, "Caravan (the shelf, one filled)")
	bk.pick_also("The shelf")
	main.refresh()
	# a paper is read on pickup (Matt, 10 Oct: "where do they actually need to be learned?"): unread it teaches its
	# word; read, the Lock-up says the Radio knows it and it's safe to sell; a rule paper says keep it
	var pw: Dictionary = {}
	for w in Data.WORDS:
		if str(w.get("paper", "")) != "":
			pw = w
			break
	_check(not pw.is_empty(), "no paper with a word to test")
	if not pw.is_empty():
		sim.book.erase(str(pw["paper"]))     # unread for the check; the save comes back after
	if not pw.is_empty():
		var pp: Dictionary = sim._plain(Data.PAPER, str(pw["paper"]))
		sim.stash.append(pp)
		_check(Items.paper_keep(pp, sim.book) == "", "an unread paper says it's spent")
		main.show_room(main.ARMOURY)
		main._armoury.selected = {"kind": "stash", "id": pp["id"]}
		main._armoury._shown = ""
		main.refresh()
		var said := " | ".join(_texts(main._armoury))
		_check(said.contains("teaches %s" % str(pw["name"]).to_lower()) and not said.contains("the Radio knows"), "an unread paper's panel doesn't say what it teaches: %s" % said.left(300))
		sim._read(pp)
		main._armoury._shown = ""
		main.refresh()
		said = " | ".join(_texts(main._armoury))
		_check(said.contains("read · the Radio knows %s" % str(pw["name"]).to_lower()) and said.contains("safe to sell"), "a read paper's panel doesn't say it's known and safe to sell: %s" % said.left(300))
		_check_fit(main, "Lock-up (a read paper)")
		main._armoury.selected = {}
	var log_it: Dictionary = Items.roll_unique(sim._unique_named("The Lorry Driver's Log"), sim.rng)
	sim._read(log_it)
	_check(Items.paper_keep(log_it, sim.book) == "Works from the stash: keep it", "a rule paper doesn't say keep it: '%s'" % Items.paper_keep(log_it, sim.book))
	sim.load_dict(saved)
	print("the book ok: twenty pages, the deep ones gated, read once in order, the drawer, its pages, saved; the shelf of uniques")


## The places changing: a cleared site is picked over and comes back over
## hours; the clock makes every site Night in the small hours; the weather by
## zone puts Rain or Fog on, never rolled by the radio; the Runs card says so.
func _places_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	sim.words[3] = []
	sim.yard_picks.erase("radio")              # the Radio's Weather set and Night set read the sky elsewhere
	sim._yard_changed("")
	for i in range(Data.TIERS.size()):
		sim.worn[i] = -1.0
	for z in range(Data.ZONES.size()):
		sim.weather[z] = ""
	sim.elapsed = 3600.0 * 2.0            # 11:00, day
	_check(not sim.is_night() and sim.clock_words() == "11:00", "the clock reads %s at two hours in" % sim.clock_words())
	var fresh: Dictionary = sim.effective(3)
	_check(not ("Night" in fresh["intel"]) and sim.wear(3) == 0.0 and sim.site_state(3) == Words.SKY["fresh"], "a fresh site at 11:00 is not fresh: %s" % str(fresh["intel"]))
	# a clear picks the site over; it comes back over RECOVER_H
	sim.hp = sim.max_hp()
	sim.deploy(3)
	var m: Dictionary = sim.mission
	sim._clear(m, m["t"])
	sim.extract_now()
	sim.words[3] = []                     # the extract re-rolled the radio's words; the site alone is read
	_check(sim.wear(3) > 0.99 and sim.site_state(3).begins_with("Picked over"), "the clear did not pick the site over: %.2f %s" % [sim.wear(3), sim.site_state(3)])
	var picked: Dictionary = sim.effective(3)
	_check(absf(picked["drop"] - fresh["drop"] * (1.0 - Data.WORN_DROP)) < 0.01 and absf(picked["cash"] - fresh["cash"] * (1.0 - Data.WORN_CASH)) < 0.1, "picked over did not thin the drops and cash: %.2f / %.2f against %.2f / %.2f" % [picked["drop"], picked["cash"], fresh["drop"], fresh["cash"]])
	# another depth is another site: fresh; back at the depth it was cleared at, still picked over (7 Oct)
	var hold_done: Array = sim.bosses_beaten.duplicate()
	var hold_best: Array = sim.best_depth.duplicate()
	for z in range(Data.ZONES.size()):
		sim.bosses_beaten[z] = true
	for k in range(Data.TIERS.size()):
		sim.best_depth[k] = maxi(sim.best_depth[k], 1)
	sim.set_depth(3, 2)
	_check(sim.depth[3] == 2 and sim.wear(3) == 0.0 and sim.site_state(3) == Words.SKY["fresh"], "a depth deeper did not read fresh: %.2f %s" % [sim.wear(3), sim.site_state(3)])
	sim.set_depth(3, 1)
	_check(sim.wear(3) > 0.99, "back at depth 1 the site is not still picked over: %.2f" % sim.wear(3))
	sim.bosses_beaten = hold_done
	sim.best_depth = hold_best
	sim.elapsed += Data.RECOVER_H * 3600.0 * 0.6
	_check(sim.wear(3) > 0.3 and sim.wear(3) < 0.5 and sim.site_state(3).begins_with("Settling"), "the site is not settling at 60%%: %.2f %s" % [sim.wear(3), sim.site_state(3)])
	sim.elapsed += Data.RECOVER_H * 3600.0
	_check(sim.wear(3) == 0.0 and is_equal_approx(sim.effective(3)["drop"], fresh["drop"]), "the site did not come back")
	# night by the clock
	sim.elapsed = 3600.0 * 14.0           # 23:00
	_check(sim.is_night() and sim.clock_words() == "23:00", "23:00 is not night: %s" % sim.clock_words())
	var night: Dictionary = sim.effective(3)
	_check("Night" in night["intel"] and is_equal_approx(night["pace"], fresh["pace"] * 0.8), "the clock's night did not take: %s pace %.2f" % [str(night["intel"]), night["pace"]])
	_check(sim.sky_words(3).begins_with("23:00, night"), "the sky's words are off: %s" % sim.sky_words(3))
	# the weather, by zone; never a word the radio rolls or sells
	sim.weather[1] = "Rain"
	var rain: Dictionary = sim.effective(3)
	_check("Rain" in rain["intel"] and is_equal_approx(rain["search"], fresh["search"] * 1.3) and is_equal_approx(rain["patrol"], fresh["patrol"] * 1.25), "rain did not take: %s search %.2f" % [str(rain["intel"]), rain["search"]])
	_check(sim.sky_words(3).ends_with(", raining"), "the sky's words do not say rain: %s" % sim.sky_words(3))
	sim.weather[1] = "Fog"
	var fog: Dictionary = sim.effective(3)
	_check(fog["contact"] == fresh["contact"] - 1 and is_equal_approx(fog["drop"], fresh["drop"] * 0.9), "fog did not take: %s" % str(fog["intel"]))
	_check(not ("Rain" in sim.call_options(3)) and not ("Fog" in sim.call_options(3)), "the sky's words are for sale at the radio")
	var rolled := false
	for k in range(60):
		var rw: Array = sim._roll_words(4, [], 3)
		rolled = rolled or rw.any(func(wd): return wd["w"] in ["Rain", "Fog", "Night"])
	_check(not rolled, "the radio rolled the sky's words")
	var saw := {}
	for k in range(40):
		sim.elapsed += Data.WEATHER_H * 3600.0
		sim._roll_weather()
		for z in range(Data.ZONES.size()):
			saw[sim.weather[z]] = true
	_check(saw.has("Rain") and saw.has("Fog") and saw.has(""), "forty hours of weather did not bring rain, fog and clear: %s" % str(saw.keys()))
	# the Runs card: the sky's row and the clock line, the site's state; everything fits
	sim.weather[1] = "Rain"
	sim.elapsed = 3600.0 * 14.0
	sim.worn[3] = sim.elapsed - 600.0
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
	_check(sim.weather[1] == "Rain" and sim.wear(3) > 0.9, "the sky and the wear did not save")
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
	var bt := 5                                  # the Retail Park, the Carpet Man's (index 5 since the Outskirts)
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
	sim.words[bt] = []
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
	var has_face: bool = ResourceLoader.exists(face_file) or FileAccess.file_exists(face_file)
	_check(not has_face or main._run._fight_face["art"].texture == People.portrait(m["boss"]["name"]), "the fight's face does not show the head where his art is")
	_check(main._run._fight["head"].text == "THE FIGHT · " + str(m["boss"]["name"]).to_upper(), "the head's name is not in the fight's kicker: '%s'" % main._run._fight["head"].text)
	_check_fit(main, "Run (the head out)")
	sim.extract_now()
	# the wall: three runners before, their faces where the art is
	sim.past = [{"class": "Doorman", "level": 9, "runs": 12, "end": "died in the Parade"}, {"class": "Poacher", "level": 14, "runs": 30, "end": "moved on"}, {"class": "Scrapper", "level": 4, "runs": 3, "end": "died in Ransacked Streets"}]
	main.show_room(main.BARRACKS)
	main._barracks._shown = ""
	main._barracks.selected = ""
	main.refresh()
	# the faces went with the strip (8 Oct): the line alone, newest first; the wall is a card in the Runner room
	_check(main._barracks._past.text.begins_with("Before: a Scrapper, 3 runs") or main._barracks._past.text.begins_with("a Scrapper, 3 runs") or main._barracks._past.text.begins_with("Before: Scrapper"), "the line beside the wall is off: %s" % main._barracks._past.text)
	_check_fit(main, "Caravan (the wall)")
	main.show_room(main.RUNNER)
	main.refresh()
	var plates: Array = main._stats.cards["wall"]["plates"]
	_check(plates[0]["name"].text == "Scrapper · 4" and plates[1]["name"].text == "Poacher · 14" and plates[2]["name"].text == "Doorman · 9" and plates[3]["name"].text == "", "the wall's plates are off: %s / %s / %s" % [plates[0]["name"].text, plates[1]["name"].text, plates[2]["name"].text])
	_check(plates[0]["line"].get_theme_color("font_color") == Pal.BAD and plates[1]["line"].get_theme_color("font_color") == Pal.GOOD, "a lost runner's plate does not read as lost, or one moved on as lost")
	_check_fit(main, "Stats (the wall)")
	sim.past = []
	main.show_room(main.BARRACKS)
	main._barracks._shown = ""
	main.refresh()
	_check(not main._barracks._past.text.begins_with("Before"), "the strip names runners before with nobody before: '%s'" % main._barracks._past.text)
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
	sim.words[3] = []
	sim.set_depth(3, 1)
	sim.hp = sim.max_hp()
	sim.deploy(3)
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
	_set_cls(fresh, "Doorman")
	_check(fresh.next_words() == Words.NEXT["first"] and str(fresh.events.back()[1]) == Words.NEXT["first"], "a runner with a past is not sent out: %s" % str(fresh.events.back()))
	_check(fresh.next_words(true) == Words.NEXT_SHORT["first"], "the short form is off: %s" % fresh.next_words(true))
	# after the first run: the next site; then the head; then the next lot
	fresh.hp = fresh.max_hp()
	fresh.deploy(0)                              # a new yard starts at the Outskirts (12 Oct)
	fresh.extract_now()
	_check(fresh.next_words().begins_with("The Allotments hasn't") or fresh.next_words().begins_with("The Garden Centre hasn't"), "after the first run the next site is not named: %s" % fresh.next_words())
	for i in [0, 1, 2, 3, 4, 5]:
		fresh.best_depth[i] = 1
	_check(fresh.next_words() == Words.NEXT["head"] % ["The Carpet Man", "the Retail Park"] and fresh.next_words(true) == "Arm the Carpet Man on Runs", "the head is not named: %s / %s" % [fresh.next_words(), fresh.next_words(true)])
	fresh.bosses_beaten[1] = true
	_check(fresh.next_words() == Words.NEXT["site"] % "The Pleasure Park", "the town's first site is not named: %s" % fresh.next_words())
	var n0: int = fresh.events.size()
	fresh.hp = fresh.max_hp()
	fresh.deploy(0)
	fresh.extract_now()
	_check(fresh.events.any(func(ev): return str(ev[1]) == Words.NEXT["site"] % "The Pleasure Park"), "the log did not carry the change")
	var n1: int = fresh.events.size()
	fresh.hp = fresh.max_hp()
	fresh.deploy(0)
	fresh.extract_now()
	_check(not fresh.events.slice(n1).any(func(ev): return str(ev[1]).begins_with("The Pleasure Park hasn't")), "the log said the same thing twice")
	_finish_campaign(sim)
	_check(sim.next_words() == Words.NEXT["done"] % sim.convoy_depth() and sim.next_words().contains("depth %d" % Data.CONVOY_DEPTH), "the campaign done has no line, or the lorry's depth is not the figure: %s" % sim.next_words())
	main.show_room(main.OVERVIEW)
	_check_fit(main, "The Yard (what's next)")
	sim.load_dict(saved)
	print("what's next ok: the past, the first run, the site, the head, the next lot, once in the log, the campaign done")


## Idle quality of life: two toggles on the Lock-up with nothing selected -
## the best of each slot goes on when a run comes home, and the common gear
## goes to the Fence (never rounds, meds, bottles, papers, uniques or sets).
func _idle_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	main.show_room(main.ARMOURY)
	main._armoury.selected = {}
	main.refresh()
	_check(main._armoury._toggles[0].visible and main._armoury._toggles[1].visible and main._armoury._toggles[2].visible, "the idle toggles and the junk rules are not on the Lock-up")
	_check_fit(main, "Lock-up (idle toggles)")
	main._armoury._toggle(0)
	main._armoury._toggle(1)
	_check(sim.auto_equip and sim.auto_sell and main._armoury._toggles[0].text.ends_with("✓"), "the toggles did not turn on")
	_check_fit(main, "Lock-up (idle toggles on)")
	# a run home: the junk goes, the better piece goes on, the rest stays
	while not sim.stash_room(12) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])
	sim.stash = sim.stash.filter(func(x): return x.get("slot", "") != "Armour")     # no armour of the run's own better than the one put in (a 1-in-7 flake, 9 Oct)
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
	sim.equipped["Helmet"] = sim._plain("Helmet", "Visored helmet")     # the hard hat junk only when it's no upgrade (the junk rules keep upgrades, 11 Oct)
	sim.words[3] = []
	sim.hp = sim.max_hp()
	sim.deploy(3)
	sim.mission["found"] = []
	sim.extract_now()
	_check(not sim.stash.has(junk) and sim.stash.has(keep_ammo) and sim.stash.has(keep_med) and sim.stash.has(keep_bottle), "the junk run sold the wrong things: junk %s ammo %s med %s bottle %s" % [sim.stash.has(junk), sim.stash.has(keep_ammo), sim.stash.has(keep_med), sim.stash.has(keep_bottle)])
	_check(sim.equipped["Armour"] != null and sim.equipped["Armour"]["id"] == better["id"], "the better armour did not go on")
	_check(sim.events.any(func(ev): return str(ev[1]).begins_with("The Fence took the junk")) and sim.events.any(func(ev): return str(ev[1]).begins_with("Put on: ")), "the idle tidy had no lines")
	main._armoury._toggle(0)
	for k in range(3):
		main._armoury._toggle(1)              # the sell rule goes round: to uncommon, to rare, off
	_check(not sim.auto_equip and not sim.auto_sell and sim.junk_upto == -1, "the toggles did not turn off")
	var d: Dictionary = sim.to_dict()
	sim.auto_sell = true
	d = sim.to_dict()
	sim.load_dict(d)
	_check(sim.auto_sell, "the toggle did not save")
	sim.load_dict(saved)
	print("idle ok: the toggles, the junk run, equip if better, the lines, the save")
	_junk_rule_checks(main)
	_upgrade_arrow_checks(main)
	_came_back_checks(main)
	_rig_checks(main)
	_build_rounds_checks(main)
	_skull_checks(main)
	_card_frame_checks(main)


## Juice: the log's best lines as toasts under the top bar, a damage number
## off the run panel as the hits land, a flash on a rare in the pack.
func _juice_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	main.refresh()
	var before: int = main._juice.toasts().size()
	sim.log_event("Found: Lucky Cap")
	sim.log_event("Trained: Stance")
	main.refresh()
	var shown: Array = main._juice.toasts()
	_check(not shown.is_empty() and shown[0] == "Found: Lucky Cap" and not shown.has("Trained: Stance"), "the find did not toast, or the training did: %s" % str(shown))
	_check(Words.toast_tone("The Carpet Man comes out. He's brought the whole warehouse.") == "warn" and Words.toast_tone("The Carpet Man is down. x") == "good" and Words.toast_tone("Dead in the Parade. Kit lost (£100).") == "bad" and Words.toast_tone("Out to The Parade, The Estate, depth 1: night") == "none", "the toast tones are off")
	for k in range(5):
		sim.log_event("Level %d: 1 training point" % (k + 50))
	main.refresh()
	_check(main._juice.toasts().size() <= main._juice.TOAST_MAX, "the toasts piled past three")
	for t in main._juice.text_nodes():
		_check(t.text != "" and UI.text_width(t, t.text) <= t.size.x, "a toast does not fit: %s" % t.text)
	# the run: numbers as the hits land, a flash on a rare
	sim.words[3] = []
	sim.hp = sim.max_hp()
	sim.deploy(3)
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
	sim.words[3] = []
	sim.weather[1] = "Rain"
	sim.hp = sim.max_hp()
	sim.deploy(3)
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
	_check(p["ambient"] == "" and not p["rain"], "the ambient kept playing in the Yard: %s" % str(p))
	main._sound.set_enabled(false)
	sim.hp = sim.max_hp()
	sim.deploy(3)
	main.refresh()
	_check(main._sound.playing()["ambient"] == "", "sound off still plays")
	main._sound.set_enabled(true)
	sim.extract_now()
	main.show_pause()
	_check(main._menu._items.any(func(i): return str(i["name"]).begins_with("Sound: ")), "the pause menu has no sound toggle")
	_check(main._menu.shape() == "drawer", "the pause is not the drawer: %s" % main._menu.shape())
	_check_fit(main, "Paused (sound)")
	main._menu.close()
	sim.load_dict(saved)
	print("sound ok: the files, the ambient and the rain, the tick, the sting, off in the Yard, the toggle")


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
	_check(c["tiles"][0]["key"].text == "Them" and c["tiles"][0]["value"].text.contains(" × ") and c["tiles"][2]["key"].text == "Fight · clock" and (c["tiles"][2]["value"].text.contains(" of ") or c["tiles"][2]["value"].text.contains("/") or c["tiles"][2]["value"].text.begins_with("over")), "the fight tiles are off: %s" % str(c["tiles"].map(func(t): return t["key"].text + " " + t["value"].text)))
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
	main._missions._pick_zone(2)
	main.refresh()
	_check(c["band"]._tone == 2 or not sim.zone_open(2), "the band's tone did not follow the zone")
	main._missions._pick_zone(1)
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
	var hold_save: Dictionary = sim.to_dict()
	var hold_elapsed: float = sim.elapsed
	var hold_weather: Array = sim.weather.duplicate()
	_finish_campaign(sim)
	sim.best_depth[tier0] = maxi(sim.best_depth[tier0], 5)
	sim.set_depth(tier0, 5)                  # three words at depth 5
	sim.words[tier0] = [{"w": "Bailiffs", "t": 1}, {"w": "Rubbered", "t": 1}, {"w": "Long odds", "t": 1}]
	sim.elapsed = 3600.0 * 23.0
	sim.weather[main._missions.zone] = "Rain"
	main._missions._shown = ""
	main.refresh()
	_check(sim.effective(tier0)["intel"].size() >= 4 and c["intel"].shown() <= main._missions.WORD_ROWS and c["intel"].position.y + c["intel"].size.y <= c["site"][0].position.y, "five words run past the word rows: %d shown, rows end %.0f, site at %.0f" % [c["intel"].shown(), c["intel"].position.y + c["intel"].size.y, c["site"][0].position.y])
	_check_fit(main, "Runs (five words)")
	sim.load_dict(hold_save)
	sim.elapsed = hold_elapsed
	sim.weather = hold_weather
	main._missions._shown = ""
	main.refresh()
	# toasts: once, and only for what just happened
	var line := "Found: Lucky Cap"
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
	var long := "A convoy comes through. Lorries, and a crew riding on them. They stop. They were carrying notes. The Yard takes what it can carry and the rest goes back on the lorry."
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
	_check(main._armoury._head._title.text == "A P45" and main._armoury._head._tail.text.contains("read · the Radio knows laid off") and main._armoury._pick.button_texts().is_empty(), "a paper's panel is off (Sell is the Fence's): %s / %s / %s" % [main._armoury._head._title.text, main._armoury._head._tail.text, str(main._armoury._pick.button_texts())])
	_check(main._armoury._pick._right_title.text.begins_with("In the Caravan's drawer") and main._armoury._pick._right_lines[0].text.begins_with("Read"), "a read paper's line is off: %s" % main._armoury._pick._right_title.text)
	_check_fit(main, "Lock-up (a paper)")
	# and the same paper picked at the Fence's stash tab (it crashed there too)
	main.show_room(main.MARKET)
	main._fence._show("stash")
	main._fence._stash.kind = 6               # the Paper tab: the paper is on the page whatever the stash holds
	main._fence._stash.page = 0
	main._fence._shown = ""
	main.refresh()
	main._fence._stash._pick(main._fence._stash.cell_of(paper["id"]))
	main.refresh()
	_check(main._fence._right_title.text == "The drawer" and main._fence._right_lines[0].text.begins_with("Read") or main._fence._right_lines[0].text == "In the drawer", "a paper at the Fence: %s / %s" % [main._fence._right_title.text, main._fence._right_lines[0].text])
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
	# a socketable says what it is and what it does, in the Lock-up and at the Fence
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
	_check(main._fence._right_lines[0].text.begins_with("A socketable"), "the Fence does not say salt is a socketable: %s" % main._fence._right_lines[0].text)
	_check_fit(main, "Fence (salt)")
	_check(Items.art(sim._plain(Data.PAPER, "A P45")) != null and Items.art(sim._plain(Data.PAPER, "A boarding pass")) == Items.art(sim._plain(Data.PAPER, "A P45")), "papers have no picture in the cell, or not the same one")
	sim.load_dict(saved)
	# the boss toggle on the Runs card: one press, one toast, however many refreshes follow
	_finish_campaign(sim)
	sim.notes = 1000
	sim.arm_boss(5, false)
	main._juice._toasts = []
	main.show_room(main.MISSIONS)
	main._missions._shown = ""
	main.refresh()
	main._missions._boss(2)
	for k in range(4):
		main._missions._shown = ""
		main.refresh()
	var boss_toasts: int = main._juice.lines().filter(func(l): return str(l).begins_with("The Carpet Man: ")).size()
	_check(boss_toasts == 1, "the boss toggle toasted %d times" % boss_toasts)
	main._missions._boss(2)
	main.refresh()
	main._missions._boss(2)
	main.refresh()
	boss_toasts = main._juice.lines().filter(func(l): return str(l).begins_with("The Carpet Man: ")).size()
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
	_check(sim.survival(3) >= 0.0 and sim.odds_settled(3), "without a budget the odds did not read at once")
	# a read that is plainly settled settles early: a runner nothing can touch reads 100% after EARLY_RUNS
	var hold_hp: float = sim.hp
	var hold_x: float = sim.xp
	sim.xp = Data.xp_for_level(90)
	sim.hp = sim.max_hp()
	sim._surv_cache = {}
	_check(sim.survival(3) >= 0.999 and sim._surv_cache[3][2] == sim.odds_runs(), "a level-90 runner on the first site did not read as settled 100%%: %.2f" % sim.survival(3))
	sim.xp = hold_x
	sim.hp = hold_hp
	sim._surv_cache = {}
	# the balance gate's brakes stay off in the shell (8 Oct): the player's read is the lookout's full count, read fresh
	_check(not sim.fast_memo and sim.odds_runs_max == 0, "the shell's sim has the gate's brakes on: fast_memo %s, odds_runs_max %d" % [sim.fast_memo, sim.odds_runs_max])
	# and the odds key rounds the HP tenth: a rest to full that lands a hair under reads as the full one
	sim.hp = sim.max_hp() - 0.01
	var k_near: Array = sim._odds_key(3)
	sim.hp = sim.max_hp()
	_check(k_near == sim._odds_key(3), "a hair under full HP re-reads the odds")
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
	sim.words[3] = []
	sim.set_depth(3, 1)
	sim.hp = sim.max_hp()
	sim.insure_next = false
	sim.deploy(3)
	sim._kia()
	_check(sim.loose_kit.size() >= 1 and sim.loose_kit.any(func(e): return e["item"]["base"] == "Riot suit" and e["who"] == "the last %s" % cls_before and e["from"] == "runner"), "the dead runner's jacket did not go out on the estate: %s" % str(sim.loose_kit.map(func(e): return e["item"]["base"])))
	_check(str(sim.events.back()[1]).ends_with(Words.RECYCLE["listed"]) or sim.events.any(func(ev): return str(ev[1]).ends_with(Words.RECYCLE["listed"])), "the death's line does not say the kit will turn up")
	sim.loose_kit = sim.loose_kit.filter(func(e): return e["item"]["base"] == "Riot suit")   # the rest of the kit: the jacket's the one followed here
	# a unique sold to the Fence goes on the list too
	var u: Dictionary = Items.roll_unique(sim._unique_named("Lucky Cap"), sim.rng)
	sim.stash.append(u)
	sim.sell(u)
	_check(sim.loose_kit.any(func(e): return e["from"] == "fence" and e["item"].get("unique", "") == "Lucky Cap"), "the unique sold did not go out on the estate")
	# too soon: nothing on the first runs; then one of them is wearing it
	sim.hp = sim.max_hp()
	sim.deploy(3)
	var m: Dictionary = sim.mission
	_check(not m.has("wearing"), "the kit turned up on the very next run")
	sim.extract_now()
	sim.runs_total += Data.RECYCLE_RUNS
	sim.hp = sim.max_hp()
	sim.deploy(3)
	m = sim.mission
	if not m.has("wearing"):
		sim._maybe_wearing(m, true)          # the deploy's own roll may have put it on someone already
	_check(m.has("wearing") and m["wearing"]["item"]["base"] == "Riot suit", "nobody was wearing the jacket when forced: %s" % str(m.get("wearing", {})))
	_check(sim.events.any(func(ev): return str(ev[1]) == Words.RECYCLE["wearing"] % ["the last %s" % cls_before, "riot suit"]), "the wearing line is off: %s" % str(sim.events.back()[1]))
	var found_before: int = m["found"].size()
	sim._clear(m, m["t"])
	_check(m["found"].size() == found_before + 1 and m["found"].back()["base"] == "Riot suit" and m["found"].back()["affixes"][0]["value"] == 33.0 and not m.has("wearing"), "the jacket did not come off him with its affix: %s" % str(m["found"].back() if not m["found"].is_empty() else {}))
	_check(sim.events.any(func(ev): return str(ev[1]).begins_with("Riot suit came off him. The last")), "the off line is off: %s" % str(sim.events.back()[1]))
	sim.extract_now()
	_check(sim.stash.any(func(it): return it["base"] == "Riot suit" and it["affixes"].size() == 1 and it["affixes"][0]["value"] == 33.0), "the jacket did not come home")
	# the unique, the same way
	sim.hp = sim.max_hp()
	sim.deploy(3)
	m = sim.mission
	if not m.has("wearing"):
		sim._maybe_wearing(m, true)
	_check(m.has("wearing") and m["wearing"]["from"] == "fence", "the sold unique was not on anyone: %s" % str(m.get("wearing", {})))
	_check(sim.events.any(func(ev): return str(ev[1]) == Words.RECYCLE["has"] % "Lucky Cap"), "the has line is off: %s" % str(sim.events.back()[1]))
	sim._clear(m, m["t"])
	_check(not m["found"].is_empty() and m["found"].back().get("unique", "") == "Lucky Cap", "the unique did not come off him")
	sim.extract_now()
	_check(sim.loose_kit.is_empty() or not sim.loose_kit.any(func(e): return e["item"].get("unique", "") == "Lucky Cap"), "the unique stayed on the list after coming back")
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
	var ws0: int = sim.yard_pick_cost("bench", 4) if sim.yard_side("bench", 4) == "" else 0
	sim.hp = sim.max_hp() * 0.5
	var treat0: int = sim.treat_cost()
	sim.elapsed = (Data.INFLATION_GRACE_H + 10.0) * 3600.0
	var m: float = 1.0 + Data.INFLATION_RATE * 10.0
	_check(is_equal_approx(sim.inflation(), m), "ten hours past the grace reads %.2f, not %.2f" % [sim.inflation(), m])
	_check(sim.price(it) == int(round(p0 * m)) or absi(sim.price(it) - int(round(p0 * m))) <= 1, "the Fence's asking price did not rise: %d -> %d" % [p0, sim.price(it)])
	_check(absi(sim.sell_price(it) - int(round(s0 * m))) <= 1, "the Fence's paying price did not rise: %d -> %d" % [s0, sim.sell_price(it)])
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
	# the Clinic with nothing picked: the rig's summary, and no button acting on something unpicked
	main.show_room(main.MEDIC)
	main._clinic.selected = {}
	main.refresh()
	var any_button := false
	for b in main._clinic._buttons:
		any_button = any_button or b.visible
	_check(not any_button, "the Clinic's empty panel shows a button: %s" % str(main._clinic._buttons.map(func(b): return b.text if b.visible else "")))
	_check_fit(main, "Clinic (nothing picked)")
	_check(ws0 == 0 or absi(sim.yard_pick_cost("bench", 4) - int(round(ws0 * m))) <= 1, "the Yard's prices did not rise: %d -> %d" % [ws0, sim.yard_pick_cost("bench", 4)])
	_check(absi(sim.treat_cost() - int(round(treat0 * m))) <= 2, "treatment did not rise: %d -> %d" % [treat0, sim.treat_cost()])
	_check(sim.boss_cost(3) == sim.boss_cost(3) and Data.CRAFT["bump"].has("notes"), "notes prices exist to hold")
	var c0: int = sim.craft_cost(it, "reroll")
	sim.elapsed = Data.INFLATION_GRACE_H * 3600.0
	var c_base: int = sim.craft_cost(it, "reroll")
	_check(c0 < 0 or absi(c0 - int(round(c_base * m))) <= 1, "the Bench's cash price did not rise: %d -> %d" % [c_base, c0])
	# the gangs carry today's money: a run's cash scales too
	sim.elapsed = (Data.INFLATION_GRACE_H + 10.0) * 3600.0
	sim.words[3] = []
	sim.set_depth(3, 1)
	sim.hp = sim.max_hp()
	sim.deploy(3)
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
	_check(main._fence._left_lines[0].text.begins_with("Prices up %d%%" % sim.inflation_pct()), "the Fence does not say prices are up: %s" % main._fence._left_lines[0].text)
	_check_fit(main, "Fence (prices up)")
	sim.load_dict(saved)
	print("money that goes off ok: the grace hour, the rate, every cash price, the ceiling, the Fence's line")


## The late cash sinks: call-ins priced by depth and by the words on the site;
## insurance, the Fence holding the paper on the kit for a run.
func _sink_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	_finish_campaign(sim)
	sim.atlas = {}
	sim.words[3] = []
	sim.set_depth(3, 1)
	# the Radio's crafts (9 Oct): notes by the site's depth, less the map's Good reception and the Yard's Scanner
	sim.best_depth[3] = 5
	sim.set_depth(3, 4)
	var yf: float = 0.75 if sim.yard_has("scanner") else 1.0
	_check(sim.word_craft_cost(3, "retune") == maxi(1, int(ceil(8.0 * yf))) and sim.word_craft_cost(3, "call") == maxi(1, int(ceil(32.0 * yf))) and sim.word_craft_cost(3, "clear") == maxi(1, int(ceil(2.0 * yf))), "the crafts' prices are off at depth 4: retune %d, call %d, clear %d" % [sim.word_craft_cost(3, "retune"), sim.word_craft_cost(3, "call"), sim.word_craft_cost(3, "clear")])
	sim.atlas_points = 1
	sim.rank_atlas("good_reception")
	_check(sim.word_craft_cost(3, "call") == maxi(1, int(ceil(32.0 * yf * 0.85))), "Good reception did not take 15%% off: %d" % sim.word_craft_cost(3, "call"))
	sim.atlas = {}
	# insurance: priced on the kit by depth, paid at deploy, pays out on a death
	sim.set_depth(3, 2)
	var worth: int = sim.loadout_value()
	_check(worth > 0, "no kit worn to insure")
	var cost: int = sim.insure_cost(3)
	var quote: float = worth * sim.inflation() * Data.INSURE_RATE * 2
	_check(cost >= quote - 10 and cost <= quote + 10, "insurance at depth 2 is %d on £%d of kit at ×%.2f" % [cost, worth, sim.inflation()])
	sim.cash = float(cost) - 1.0
	_check(not sim.can_insure(3), "insurance took with the cash a pound short")
	sim.cash = float(cost) + 100.0
	sim.set_insure(true)
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(1)
	_check_fit(main, "Runs (insured)")
	sim.deploy(3)
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
	_check(sim.events.slice(-3).any(func(ev): return str(ev[1]).contains("turns up") or str(ev[1]).contains("held the paper")), "the payout had no line")
	# and without it, the kit goes
	sim.choose_runner(0)
	sim.deploy(3)
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
	var res_hold := {}
	for s in ["Helmet", "Rig", "Charm"]:
		res_hold[s] = sim.equipped[s]
		sim.equipped[s] = null              # a rig rolls resists too now (12 Oct): only the coat's count here
	_check(is_equal_approx(sim.resist("fire"), 0.5) and is_equal_approx(sim.resist("shock"), 0.1) and is_equal_approx(sim.resist("physical"), 0.0), "resists do not add: fire %.2f shock %.2f" % [sim.resist("fire"), sim.resist("shock")])
	for s in res_hold:
		sim.equipped[s] = res_hold[s]
	armour["affixes"].append({"stat": "fire_res", "value": 90, "tier": 5})
	_check(is_equal_approx(sim.resist("fire"), Data.RESIST_CAP / 100.0), "the resist cap did not hold: %.2f" % sim.resist("fire"))
	var mit: float = sim.mitigation()
	var expect: float = 10.0 * 0.5 * (1.0 - mit) + 10.0 * 0.5 * (1.0 - 0.75)
	_check(is_equal_approx(sim.incoming_rate(t0, 1), expect), "incoming by type is off: %.2f vs %.2f" % [sim.incoming_rate(t0, 1), expect])
	_check(is_equal_approx(sim.incoming_rate(t0, 1, true), expect * (1.0 - Data.CHILL)), "chilled did not slow their fire")
	sim.words[3] = []
	sim.set_depth(3, 1)
	var e: Dictionary = sim.effective(3)
	_check(e.has("types") and e.has("res") and is_equal_approx(e["types"]["physical"] + e["types"]["bleed"], 1.0) and e["types"]["bleed"] > 0.1, "the estate's fire is not mostly physical with some bleed: %s" % str(e["types"]))
	_finish_campaign(sim)
	sim.best_depth[3] = maxi(sim.best_depth[3], 2)
	sim.set_depth(3, 2)
	sim.words[3] = [{"w": "Burners", "t": 1}, {"w": "Jacketed", "t": 1}]
	e = sim.effective(3)
	_check(e["types"].get("fire", 0.0) >= 0.33 and e["res"]["fire"] >= 0.4, "Burners and Jacketed did not take: %s %s" % [str(e["types"]), str(e["res"])])
	sim.words[3] = [{"w": "Kitted out", "t": 1}]
	sim.best_depth[3] = 20
	sim.set_depth(3, 12)
	e = sim.effective(3)
	_check(e["res"]["bleed"] >= 0.25 + Data.RESIST_DEPTH_STEP * 4 and is_equal_approx(e["res"]["fire"], 0.25) and e["res"]["fire"] <= Data.RESIST_ENEMY_CAP, "Kitted out (tier I) at depth 12 is %s (the estate's own bleed grows, the rest stay as the word says)" % str(e["res"]))
	sim.words[3] = []
	sim.set_depth(3, 1)
	var dots := {}
	sim._dot_add(dots, "fire", 100.0, 100.0)
	_check(is_equal_approx(dots["fire"], 50.0), "a 100 fire hit did not leave a 50 burn: %s" % str(dots))
	var ticked: float = sim._dot_tick(dots, 1.0, {})
	_check(is_equal_approx(ticked, 12.5) and is_equal_approx(dots["fire"], 37.5), "the burn did not tick a quarter of the pool a second: %.1f" % ticked)
	for k in range(60):
		sim._dot_add(dots, "poison", 100.0, 100.0)
	var poison_cap: float = 100.0 * 0.8 * sim.dot_seconds("poison") * sim.dot_stacks("poison")
	_check(is_equal_approx(dots["poison"], poison_cap), "poison did not cap at its stacks: %.0f, not %.0f" % [dots["poison"], poison_cap])
	sim.set_depth(3, 2)
	sim.words[3] = [{"w": "Cutters", "t": 1}]
	sim.hp = sim.max_hp()
	sim.deploy(3)
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
	sim.words[3] = []
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
	_check(sim.has_rule("grandads") and Items.full_name(sim.equipped["Primary"]) == "Grandad's Shotgun", "the unique's rule or name is wrong")
	# gear tiers run to 5: the Bank drops tier 5, and the Fence stocks what the open sites drop
	_check(Data.TIERS[Data.TIERS.size() - 1]["loot_tier"] == Data.CAMPAIGN_TIER, "the last site does not drop the campaign's top tier")
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
## a box bought at the Fence is a stack in the stash; a better grade adds damage.
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
	sim.set_depth(3, 1)
	sim.hp = sim.max_hp()
	sim.deploy(3)
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
	sim.deploy(3)
	sim.mission["t"]["dps"] = 0.0
	for k in range(30):
		sim.advance(1.0)
	var backing: int = pistol0 - sim.rounds_for(sim.equipped["Secondary"])
	_check(backing > 0, "a pistol backing a live primary spent no rounds over thirty seconds")
	sim.extract_now()
	sim.rig = [sim._plain(Data.AMMO, "Pistol rounds")]        # the nail gun dry: the pistol is the gun in hand
	pistol0 = sim.rounds_for(sim.equipped["Secondary"])
	sim.hp = sim.max_hp()
	sim.deploy(3)
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
	_check(sim.buy_ammo("shotgun"), "the Fence would not sell a box of shells (cash £%.0f, room %s)" % [sim.cash, str(sim.stash_room(1))])
	var shells_after: int = sim.stash.reduce(func(a, it): return a + (int(it.get("rounds", 0)) if Items.is_ammo(it) and Items.ammo_type(it) == "shotgun" else 0), 0)
	_check(shells_after > shells_before and sim.cash < cash_before, "a box from the Fence did not land in the stash: %d shells then %d" % [shells_before, shells_after])
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


## Buy the Bench when the cash is there with £500 to spare; fit the best
## attachment the stash holds on every open mount of both guns.
func _bench(sim) -> void:
	for b in Data.YARD:
		for c in range(2):
			if sim.yard_side(b["key"], c) == "" and sim.can_yard_pick(b["key"], c, "a") and sim.cash >= sim.yard_pick_cost(b["key"], c) + 500:
				sim.yard_pick(b["key"], c, "a")
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


## A chip row's words, the shown chips only.
func _chip_texts(ch) -> Array:
	var out := []
	for k in range(ch._panels.size()):
		if ch._panels[k].visible:
			out.append(ch._labels[k].text)
	return out


## The Stats sheet's geometry (10 Oct): every part inside the room and apart from the others; each row, bar and tile
## inside its part; the band's words inside the band.
func _stats_layout(main, where: String) -> int:
	var bad := 0
	var st = main._stats
	var room := Rect2(Vector2.ZERO, st.size)
	var rects := {}
	for k in st.cards:
		var p: Panel = st.cards[k]["panel"]
		rects[k] = Rect2(p.position, p.size)
		if not room.encloses(rects[k]):
			push_error("%s: the sheet's %s leaves the room (%s)" % [where, k, str(rects[k])])
			bad += 1
	for a in rects:
		for b in rects:
			if str(a) < str(b) and rects[a].intersects(rects[b]):
				push_error("%s: the sheet's %s and %s overlap" % [where, a, b])
				bad += 1
		var band_r := Rect2(st.band.position, st.band.size)
		if band_r.intersects(rects[a]):
			push_error("%s: the sheet's %s runs into the band" % [where, a])
			bad += 1
	for k in st.cards:
		var c: Dictionary = st.cards[k]
		var inner: Rect2 = rects[k].grow(-1.0)
		var parts: Array = []
		for key in c.keys():
			var v = c[key]
			if v is Control and v != c["panel"] and v.visible and v.get_parent() == st:
				parts.append(v)
			elif v is Array:
				for e in v:
					if e is Dictionary:
						for e2 in e.values():
							if e2 is Control and e2.get_parent() == st and e2.visible:
								parts.append(e2)
		for n in parts:
			var r := Rect2(n.position, n.size)
			if n is Label and (n as Label).text == "":
				continue
			if not inner.encloses(r) and not (n == c.get("edge")):
				push_error("%s: the sheet's %s has a piece outside it: %s %s" % [where, k, n.name, str(r)])
				bad += 1
	for l in [st.band.kicker, st.band.title, st.band.headline, st.band.unit]:
		if l.text != "" and (l.position.y < 0.0 or l.position.y + l.size.y > st.band.size.y + 0.5):
			push_error("%s: the sheet's band word '%s' leaves the band" % [where, l.text])
			bad += 1
	var t_r := Rect2(st.band.title.position, Vector2(UI.text_width(st.band.title, st.band.title.text), st.band.title.size.y))
	var h_r := Rect2(st.band.headline.position, Vector2(UI.text_width(st.band.headline, st.band.headline.text), st.band.headline.size.y))
	if t_r.intersects(h_r):
		push_error("%s: the sheet's band title and headline overlap" % where)
		bad += 1
	return bad


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
	elif main.room == main.COMMS:
		bad += _check_nodes(main._radio.text_nodes(), main._radio.line_pairs(), where + " screen")
	elif main.room == main.WORKSHOP:
		bad += _check_nodes(main._workshop.text_nodes(), main._workshop.line_pairs(), where + " screen")
	elif main.room == main.BARRACKS:
		bad += _check_nodes(main._barracks.text_nodes(), main._barracks.line_pairs(), where + " screen")
	elif main.room == main.MARKET:
		bad += _check_nodes(main._fence.text_nodes(), main._fence.line_pairs(), where + " screen")
		_check(main._fence.face_clear(), where + ": the Fence's face is under something")
	elif main.room == main.MEDIC:
		bad += _check_nodes(main._clinic.text_nodes(), main._clinic.line_pairs(), where + " screen")
		_check(main._clinic.face_clear(), where + ": the medic's face is under something")
	elif main.room == main.RUNNER:
		bad += _check_nodes(main._stats.text_nodes(), [], where + " screen")
		bad += _stats_layout(main, where)
	elif main.room == main.ARMOURY:
		bad += _check_nodes(main._armoury.text_nodes(), main._armoury.line_pairs() if main._armoury.has_method("line_pairs") else [], where + " screen")
		_check_grid(main._armoury._inv, main.sim.stash_cap(), where + " stash grid")
		_check(main._armoury._containers.rig_inside(), "%s: the rig (%.0f px pouches) runs out of its room" % [where, main._armoury._containers.rig_cell()])
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
	if main.room == main.OVERVIEW and main._yard_tree.visible:
		bad += _check_nodes(main._yard_tree.text_nodes(), main._yard_tree.line_pairs(), where + " yard tree")
		# the lanes in glyphs (10 Oct, Lanes-G): every tile a glyph inside its lane, no tile on another, each price and
		# the rank's words inside the lane and on no tile
		var yt = main._yard_tree
		for lane in yt._lanes:
			var lr := Rect2(lane["panel"].position, lane["panel"].size)
			var rects: Array = []
			var tiles: Array = [lane["rank"]]
			for pair in lane["tiles"]:
				tiles.append_array(pair)
			for tl in tiles:
				var br := Rect2(tl["button"].position, tl["button"].size)
				if not lr.encloses(br) or tl["glyph"].texture == null:
					push_error("%s: a yard tile leaves its lane or has no glyph (%s)" % [where, lane["key"]])
					bad += 1
				for o in rects:
					if br.intersects(o):
						push_error("%s: two yard tiles overlap in %s" % [where, lane["key"]])
						bad += 1
				rects.append(br)
			var words: Array = [lane["rank"]["name"], lane["rank"]["cost"]]
			for pair in lane["tiles"]:
				words.append(pair[0]["cost"])
			for l in words:
				if l.text == "":
					continue
				var wr := Rect2(l.position, Vector2(UI.text_width(l, l.text), l.size.y))
				if not lr.encloses(wr):
					push_error("%s: '%s' leaves its lane" % [where, l.text])
					bad += 1
				for o in rects:
					if wr.intersects(o):
						push_error("%s: '%s' runs onto a tile" % [where, l.text])
						bad += 1
	var rail_nodes := []
	for name in main.ROOMS:
		var b = main._rail_buttons[name]
		rail_nodes.append_array(b.text_nodes())
		if b.badge_gap() < 8.0:
			push_error("rail %s: badge overlaps the name" % name)
			bad += 1
		if b._glyph.texture == null:
			var gname: String = b.GLYPH_OF.get(name, "")
			if gname == "" or FileAccess.file_exists("res://art/ui/%s.png" % gname):
				push_error("rail %s: no glyph" % name)
				bad += 1                         # a glyph named and painted but not shown is a bug; one not yet painted is an art gap (stats.png, 9 Oct)
		if b._rule.visible == b.last:
			# the last row has no hairline under it (8 Oct, Matt: a line past the Radio); the rest have one
			push_error("rail %s: the hairline is %s on the %s row" % [name, "on" if b._rule.visible else "off", "last" if b.last else "a middle"])
			bad += 1
	bad += _check_nodes(rail_nodes, [], where + " rail")
	# the rail runs to the log's bottom (8 Oct, Matt: "the rail should span to the bottom of the log bar")
	var rail_end: float = main._rail.position.y + main._rail_panel.size.y
	var log_end: float = main._events.position.y + Pal.EVENTS_H
	if main._events.position.y > 0.0 and absf(rail_end - log_end) > 1.0:      # once laid out (the smoke's shell never is: the log sits at 0)
		push_error("%s: the rail ends at %.0f, the log at %.0f" % [where, rail_end, log_end])
		bad += 1
	bad += _check_nodes(main._top_labels.values(), [], where + " top bar")
	bad += _check_nodes([main._prev_time, main._prev_label], [], where + " log (the line before)")
	var cur: Label = main._event_labels[0]
	if main._prev_label.text != "" and main._prev_time.position.x < cur.position.x + ceilf(UI.text_width(cur, cur.text)) + main.PREV_GAP - 0.5:
		push_error("%s: the line before runs into the latest" % where)
		bad += 1
	# the log line starts just after its time (8 Oct: left-justified)
	var et: Label = main._event_times[0]
	if et.text != "" and absf(main._event_labels[0].position.x - (20 + ceilf(UI.text_width(et, et.text)) + 16)) > 0.5:
		push_error("%s: the log line sits apart from its time" % where)
		bad += 1
	bad += _check_nodes([main._top_caption], [], where + " top bar caption")
	# the purse (10 Oct, Bar-C): left to right the place, notes, scrap, the salvage found, cash, each glyph before its
	# figure, none on the next, and the lot clear of the HP, XP and damage
	var purse_from := 0.0
	for k in ["hp", "xp", "dps"]:
		var lk: Label = main._top_labels[k]
		purse_from = maxf(purse_from, maxf(main._top_lines[k][0].position.x + main._top_lines[k][0].size.x, lk.position.x + UI.text_width(lk, lk.text)))
	for k in ["where", "notes", "scrap", "copper", "steel", "army", "cash"]:
		var g: TextureRect = main._top_glyphs[k]
		if not g.visible:
			continue
		if g.position.x < purse_from + 8.0:
			push_error("%s: the top bar's %s runs into what's before it (%.0f < %.0f)" % [where, k, g.position.x, purse_from + 8.0])
			bad += 1
		var pl: Label = main._top_labels[k]
		purse_from = (pl.position.x + pl.size.x) if pl.visible else g.position.x + g.size.x
		if pl.visible and g.position.x + g.size.x > pl.position.x + pl.size.x - UI.text_width(pl, pl.text) + 0.5:
			push_error("%s: the top bar's %s glyph sits on its figure" % [where, k])
			bad += 1
	for k in main._top_glyphs:
		if main._top_glyphs[k].texture == null:
			push_error("%s: the top bar's %s glyph is missing" % [where, k])
			bad += 1
	# LEVEL before the figure (Matt, 8 Oct: "1 LEVEL" read wrong), the purse's glyphs before their figures
	var lvl: Label = main._top_labels["level"]
	if lvl.position.x < main._top_caption.position.x + UI.text_width(main._top_caption, main._top_caption.text) + 4.0:
		push_error("%s: the level's figure sits on LEVEL" % where)
		bad += 1
	# the three lines under the runner's figures read the same (Matt, 8 Oct): one width, one row
	for k in ["hp", "xp", "dps"]:
		if not main._top_lines.has(k) or main._top_lines[k][0].size.x != main._top_lines["hp"][0].size.x or main._top_lines[k][0].position.y != main._top_lines["hp"][0].position.y:
			push_error("%s: the top bar's %s line is not the HP line's" % [where, k])
			bad += 1
	_check(main._top_labels["dps"].text.ends_with(" dmg/s") and main._top_labels["xp"].position.x > main._top_labels["hp"].position.x and main._top_labels["dps"].position.x > main._top_labels["xp"].position.x,     # HP, XP, then damage (8 Oct)
			"%s: the top bar's dmg/s is off: '%s'" % [where, main._top_labels["dps"].text])
	if main._menu.visible:
		bad += _check_nodes(main._menu.text_nodes(), [], where + " menu")
		var pr: Rect2 = main._menu.panel_rect()
		var mn = main._menu
		var foot: float = mn.PAD if mn.shape() == "card" else 0.0
		for i in range(mn._items.size()):
			var b = mn._rows[i]
			_check(b.position.y + b.size.y + foot <= mn._panel.size.y + 0.5, "%s menu: row %d runs off the panel" % [where, i])
			_check(b.position.x + b.size.x <= mn._panel.size.x + 0.5, "%s menu: row %d runs off the panel's side" % [where, i])
			# a row's stamp carries a glyph that exists when the item brings one (the menus' line drawings, 8 Oct)
			if str(mn._items[i].get("glyph", "")) != "":
				_check(mn._glyphs[i].visible and mn._glyphs[i].texture != null and mn._stamps[i].visible, "%s menu: row %d's glyph %s is missing" % [where, i, mn._items[i]["glyph"]])
				_check(mn._names[i].position.x >= mn.STAMP_X + mn.STAMP, "%s menu: row %d's name sits on its stamp" % [where, i])
		_check(pr.position.y >= 0.0 and pr.end.y <= 1080.0, "%s menu: the panel leaves the screen (%s)" % [where, pr])
		match mn.shape():
			"title":
				# the column: the wordmark at its head, the rows under it, the foot under them, all inside the column
				var vs: Vector2 = mn.get_viewport_rect().size if mn.is_inside_tree() else Vector2(1920, 1080)      # as the menu lays itself out
				var x0: float = floorf((vs.x - 1920.0) / 2.0)
				_check(pr.position.x >= x0 + mn.COLUMN_X - 0.5 and pr.end.x <= x0 + mn.COLUMN_W + 0.5, "%s menu: the title's rows leave the column (%s)" % [where, pr])
				_check(not mn._wordmark.visible or mn._wordmark.position.y + mn._wordmark.size.y <= pr.position.y, "%s menu: the wordmark runs into the rows" % where)
				_check(not mn._wordmark.visible or mn._wordmark.position.x + mn._wordmark.size.x <= x0 + mn.COLUMN_W + 0.5, "%s menu: the wordmark leaves the column" % where)
				_check(mn._foot_left.visible and mn._foot_left.position.y >= pr.end.y, "%s menu: the foot runs into the rows" % where)
				_check(not mn._title.visible and mn._stamps[0].visible, "%s menu: the title shows its heading, or no stamps" % where)
				# the wordmark loads wherever the file is (the editor, a pack): the Deck's builds had none (8 Oct)
				_check(not FileAccess.file_exists(mn.WORDMARK_ART) or (mn._wordmark.visible and mn._wordmark.texture != null and mn._wordmark.texture.get_size() == Vector2(154, 72)), "%s menu: the wordmark did not load from %s (%s)" % [where, mn.WORDMARK_ART, str(mn._wordmark.texture.get_size()) if mn._wordmark.texture != null else "null"])
			"drawer":
				# the drawer is the rail's rect exactly, its kicker up, names only
				var rail := Rect2(main._rail.position, main._rail_panel.size)
				_check(pr.is_equal_approx(rail), "%s menu: the drawer is not the rail's rect (%s vs %s)" % [where, pr, rail])
				_check(mn._kicker.visible and mn._kicker.text.begins_with("PAUSED"), "%s menu: the drawer's kicker is '%s'" % [where, mn._kicker.text])
				_check(mn._items.all(func(it): return true) and mn._details[0].text == "" and mn._details[1].text == "", "%s menu: the drawer's rows carry details" % where)
			_:
				_check(mn._title.visible, "%s menu: the card has no heading" % where)
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
			if l.has_meta("over_art") and l.get_index() > b.get_index():
				continue                         # a caption drawn over an item's art on purpose (the loadout's cards)
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
			push_error("%s: '%s' needs %.0f px, has %.0f (%s)" % [where, n.text, w, n.size.x, _chain(n)])
			bad += 1
	return bad


## A node's parents' scripts and names, for a sweep error to say which label it was.
static func _chain(n: Node) -> String:
	var parts := []
	var q = n
	while q != null and parts.size() < 5:
		var sc = q.get_script()
		parts.append((sc.resource_path.get_file().get_basename() if sc != null else q.get_class()) + ("" if q.name.begins_with("@") else ":" + q.name))
		q = q.get_parent()
	return " < ".join(parts)


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
	sim.deploy(3)
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
		var base_finds: int = 1 + (1 if sim.has_node("scavenger") or sim.has_node("quiet_hands") else 0) + (1 if sim.yard_has("a_dog") else 0) + (1 if sim.yard_has("second_dog") else 0) + (2 if sim.yard_has("pack") else 0) + (1 if sim.has_rule("postman") else 0)
		_check(m["searches"] - searches0 >= 2 and per_search >= float(base_finds) + floorf(q) - 0.6, "with +%.0f%% quantity a search brings %.2f, base %d" % [q * 100.0, per_search, base_finds])
		sim.extract_now()
	# the dog adds quality
	var hold_k: String = sim.yard_side("kennel", 0)
	_yard_set(sim, "kennel", 0, "")
	var r0: float = sim.rarity_bonus()
	_yard_set(sim, "kennel", 0, "b")
	_check(is_equal_approx(sim.rarity_bonus(), r0 + 0.05), "a good nose did not add 5%% quality: %.3f then %.3f" % [r0, sim.rarity_bonus()])
	_yard_set(sim, "kennel", 0, hold_k)
	# quantity is out of the rarity roll: Rat's share no longer moves the quality figure the roll reads
	var rat := "The rat man/9"
	var rar_before: float = sim.rarity_bonus()
	if not sim.tree.has(rat):
		sim.tree.append(rat)
	var trades0: Array = sim.trades.duplicate()
	if not ("poison" in sim.trades):
		sim.trades.append("poison")         # an element's top works with a joint closed there, or the Yard's trade of it (9 Oct)
	_check(is_equal_approx(sim.rarity_bonus(), rar_before) and sim.loot_bonus() < q, "Rat's share moved quality (%.3f → %.3f) or not quantity" % [rar_before, sim.rarity_bonus()])
	sim.trades = trades0
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
## uniques with a rule each, and the Fire Crew's set. Every one has words (the manifest generator carries the art).
func _last_add_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.candidates = []
	sim.auto_equip = false
	for name in ["Police marksman's rifle", "Riot squad's shotgun", "Officer's revolver", "Army machine pistol", "Bomb-squad helmet", "Bomb suit", "Bomb-disposal rig", "Full bergen", "Mayor's chain", "Welder's mask", "Fireman's tunic", "Lineman's rubber coat", "Cold-store parka", "Hazmat suit", "Butcher's chainmail"]:
		_check(Words.item_words(name) != "", "%s has no words" % name)
	for u in ["The Arsonist's Rig", "The Gritter's Keys", "The Rat Man's Overalls", "The Substation Key", "The Butcher's Apron"]:
		_check(Data.UNIQUES.any(func(x): return x["name"] == u) and Words.UNIQUES.has(u), "%s is not a unique with words" % u)
	_check(Data.SETS.any(func(st): return st["name"] == "The Fire Crew's" and st["pieces"].size() == 3), "the Fire Crew's set is missing")
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
	var rig_u: Dictionary = Items.roll_unique(Data.UNIQUES.filter(func(x): return x["name"] == "The Arsonist's Rig")[0], sim.rng)
	sim.equipped["Rig"] = rig_u
	sim.rig = [sim._plain(Data.MEDICAL, "Bandage")]
	sim.deploy(3)
	var m: Dictionary = sim.mission
	m["remaining"] = 3
	m["target_hp"] = 1e6
	m["dots"] = {}
	sim.hp = sim.max_hp() * 0.5
	sim.use_med(sim.rig[0]["id"])
	if m["using"] != null:
		sim._patch(m, 100.0)
	_check(float(m["dots"].get("fire", 0.0)) > 0.0 and m["target_hp"] < 1e6, "the Arsonist's Rig did not set them alight on a med: %.0f left" % m["target_hp"])
	sim.extract_now()
	sim.equipped["Rig"] = hold["Rig"]
	var keys_u: Dictionary = Items.roll_unique(Data.UNIQUES.filter(func(x): return x["name"] == "The Gritter's Keys")[0], sim.rng)
	sim.equipped["Charm"] = keys_u
	sim.equipped["Primary"] = sim._plain("Primary", "Workshop SMG")
	sim.rig = [sim._plain(Data.AMMO, "SMG rounds")]
	sim._dry_memo.clear()
	sim.deploy(3)
	m = sim.mission
	m["remaining"] = 3
	m["target_hp"] = 1e6
	sim._fight(m, m["t"], 0.5)
	_check(float(m.get("chill_t", 0.0)) > 100.0, "the Gritter's Keys did not hold the chill: %.1f" % float(m.get("chill_t", 0.0)))
	sim.extract_now()
	sim.equipped["Charm"] = null
	var key_u: Dictionary = Items.roll_unique(Data.UNIQUES.filter(func(x): return x["name"] == "The Substation Key")[0], sim.rng)
	sim.equipped["Charm"] = key_u
	_check(is_equal_approx(sim.shock_amount(), 0.6), "the Substation Key's shock reads %.2f" % sim.shock_amount())
	sim.equipped["Charm"] = null
	var overalls: Dictionary = Items.roll_unique(Data.UNIQUES.filter(func(x): return x["name"] == "The Rat Man's Overalls")[0], sim.rng)
	sim.equipped["Armour"] = overalls
	_check(sim.dot_stacks("poison") == 999 and is_equal_approx(sim.dot_seconds("poison"), float(Data.DOTS["poison"]["s"]) * 0.5), "the overalls' poison reads %d stacks over %.1f s" % [sim.dot_stacks("poison"), sim.dot_seconds("poison")])
	_check(sim.dot_stacks("poison", false) == int(Data.DOTS["poison"]["stacks"]) and is_equal_approx(sim.dot_seconds("poison", false), float(Data.DOTS["poison"]["s"])), "the overalls shaped the poison on you too")
	var apron: Dictionary = Items.roll_unique(Data.UNIQUES.filter(func(x): return x["name"] == "The Butcher's Apron")[0], sim.rng)
	sim.equipped["Armour"] = apron
	_check(sim.dot_stacks("bleed") == 3 and sim.has_rule("butchers_apron"), "the apron's bleed reads %d stacks" % sim.dot_stacks("bleed"))
	sim.deploy(3)
	m = sim.mission
	m["remaining"] = 2
	m["target_hp"] = 0.0
	m["dots"] = {"bleed": 40.0}
	sim._fight(m, m["t"], 0.1)
	_check(float(m.get("dots", {}).get("bleed", 0.0)) > 0.0, "the apron did not carry the bleed to the next of them")
	sim.extract_now()
	# the set's pieces roll, its bonus reads
	var pieces := []
	for pc in Data.SETS.filter(func(st): return st["name"] == "The Fire Crew's")[0]["pieces"]:
		pieces.append(Items.roll_set_piece("The Fire Crew's", pc, sim.rng))
	sim.equipped["Armour"] = pieces[0]
	sim.equipped["Helmet"] = pieces[1]
	sim._dry_memo.clear()
	_check(sim.set_count("The Fire Crew's") == 2 and sim.set_stat("fire_res") >= 40.0, "two of the Fire Crew's do not give the fire resist: %d, %.0f" % [sim.set_count("The Fire Crew's"), sim.set_stat("fire_res")])
	main.show_room(main.ARMOURY)
	main._armoury._pick_slot("Armour")
	main.refresh()
	_check_fit(main, "Lock-up (the Fire Crew's)")
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
	_set_cls(sim, "Doorman")
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
	_set_cls(sim, "Poacher")
	sim.runner_trait = "Greedy"
	sim.xp = Data.xp_for_level(Data.RETIRE_LEVEL)
	sim.candidates = []
	_check(sim.retire() and sim.retired == ["Wary", "Light", "Greedy"], "the wall did not make way for the fourth: %s" % str(sim.retired))
	sim.choose_runner(0)
	sim.runner_trait = "Greedy"           # the same trait as one on the wall: its cut is the runner's alone
	# the Caravan's button and the Yard's chips say so, and fit; saved and loaded
	_set_cls(sim, "Scrapper")
	sim.xp = Data.xp_for_level(Data.RETIRE_LEVEL)
	main.show_room(main.BARRACKS)
	main._barracks._shown = ""
	main.refresh()
	_check(main._barracks._retire.visible and not main._barracks._retire.disabled, "the Caravan does not offer retirement at level 30")
	_check_fit(main, "Caravan (retire)")
	main.show_room(main.RUNNER)
	main.refresh()
	var card_chips: Array = _chip_texts(main._stats.cards["runner"]["chips"])
	_check(card_chips.any(func(t): return t.begins_with("Greedy")) and card_chips.has("Scrapper") and main._stats.cards["wall"]["retired"].text == "Wall: Wary, Light, Greedy", "the sheet does not show the wall under the runner's own trait: %s / '%s'" % [str(card_chips), main._stats.cards["wall"]["retired"].text])
	_check_fit(main, "Stats (the wall's traits)")
	# the bad side of a trait does not retire: Greedy's HP cut stays with the runner who had it
	_check(is_equal_approx(sim.trait_mult("hp"), 0.9), "the wall's Greedy cut the Yard's HP: ×%.3f" % sim.trait_mult("hp"))
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
	# the contracts (9 Oct, docs/design/contracts.md): five kinds of ask, four currencies, no uniques, no items
	for i in range(Data.TIERS.size()):
		sim.best_depth[i] = mini(sim.best_depth[i], 3)
	var kinds := {}
	var pays := {}
	for k in range(400):
		var c: Dictionary = sim.roll_contract()
		kinds[c["kind"]] = kinds.get(c["kind"], 0) + 1
		pays[c["pay"]] = pays.get(c["pay"], 0) + 1
		_check(c["pay"] in ["cash", "notes", "scrap"] and int(c["amount"]) > 0 and sim.contract_pay_words(c) != "" and sim.contract_words(c) != "", "a contract before any salvage drops is off: %s" % str(c))
		if c["pay"] == "scrap":
			_check(int(c["amount"]) == maxi(1, int(ceil(Data.CONTRACT_SCRAP * sim.contract_weight(c) * (1.0 + sim.deepest() / 5.0)))), "a scrap contract's amount is off: %s" % str(c))
		_check(not (c["kind"] == "meds" and c["pay"] == "cash"), "a meds ask pays cash: %s" % str(c))
		if c["pay"] == "cash":
			_check(absi(int(c["amount"]) - int(round(sim.a_runs_takings() * Data.CONTRACT_CASH * minf(sim.contract_weight(c), Data.CONTRACT_CASH_WEIGHT_MAX)))) <= 10 or int(c["amount"]) == 10, "a cash contract is not half a run's takings by its weight: %s" % str(c))
	_check(kinds.size() == (5 if sim.deepest_site_level() - Data.CONTRACT_DEEP_LESS >= Data.CONTRACT_DEEP_FROM else 4) and pays.size() == 3, "four hundred contracts did not cover every kind and pay: %s / %s" % [str(kinds), str(pays)])
	# every slot pays alike at a rarity: no rare primary worth fishing for
	var takings: float = sim.a_runs_takings()
	var prim := {"kind": "gear", "slot": "Primary", "rarity": 2, "count": 2, "level": 0, "stat": "", "pay": "", "amount": 0, "salvage": ""}
	var helm: Dictionary = prim.duplicate()
	helm["slot"] = "Helmet"
	_check(sim.contract_weight(prim) == sim.contract_weight(helm) and sim.contract_weight(prim) == 4.0, "two rares weigh %.1f / %.1f" % [sim.contract_weight(prim), sim.contract_weight(helm)])
	# salvage once a zone's site is dug to its depth
	sim.best_depth[6] = Data.SALVAGE_DEPTH
	_check(sim.salvage_kinds() == ["steel"], "the salvage on offer is off: %s" % str(sim.salvage_kinds()))
	var sv: Dictionary = {}
	for k in range(400):
		var c: Dictionary = sim.roll_contract()
		if c["pay"] == "salvage":
			sv = c
			break
	_check(not sv.is_empty() and sv["salvage"] == "steel" and int(sv["amount"]) == maxi(1, int(ceil(sim.contract_weight(sv)))), "no salvage contract, or the wrong kind: %s" % str(sv))
	# each kind of ask takes what it says, and pays
	var deep := {"kind": "deep", "slot": "", "rarity": 1, "count": 1, "level": 12, "stat": "", "pay": "salvage", "amount": 3, "salvage": "steel"}
	var helmet: Dictionary = sim._plain("Helmet", "Hard hat")
	helmet["ilvl"] = 11
	_check(not sim.contract_fits(deep, helmet), "a level-11 helmet fits a level-12 ask")
	helmet["ilvl"] = 14
	_check(sim.contract_fits(deep, helmet) and Items.ilvl(helmet) == 14, "a level-14 helmet does not fit a level-12 ask")
	var affix := {"kind": "affix", "slot": "Helmet", "rarity": 1, "count": 1, "level": 0, "stat": "armour_pct", "pay": "notes", "amount": 5, "salvage": ""}
	var plain_h: Dictionary = sim._plain("Helmet", "Hard hat")
	var arm_h: Dictionary = sim._plain("Helmet", "Hard hat")
	arm_h["rarity"] = 1
	arm_h["affixes"] = [{"stat": "armour_pct", "value": 5, "tier": 1}]
	_check(not sim.contract_fits(affix, plain_h) and sim.contract_fits(affix, arm_h) and sim.contract_words(affix).contains("% armour"), "the affix ask is off: '%s'" % sim.contract_words(affix))
	var papers := {"kind": "papers", "slot": "", "rarity": 1, "count": 2, "level": 0, "stat": "", "pay": "scrap", "amount": 9, "salvage": ""}
	var meds := {"kind": "meds", "slot": "", "rarity": 1, "count": 2, "level": 0, "stat": "", "pay": "cash", "amount": 50, "salvage": ""}
	_check(sim.contract_fits(papers, sim._plain(Data.PAPER, "A P45")) and not sim.contract_fits(papers, sim._plain(Data.PAPER, "The deeds")) and sim.contract_fits(meds, sim._plain(Data.MEDICAL, "Bandage")) and not sim.contract_fits(meds, helmet), "papers or meds asks take the wrong things")
	for it in sim.stash.duplicate():
		if sim.contract_fits(deep, it):
			sim.stash.erase(it)
	sim.stash.append(helmet)
	sim.contracts[0] = deep
	var st0: int = int(sim.salvage.get("steel", 0))
	_check(sim.can_hand_in(0) and sim.hand_in(0) and int(sim.salvage["steel"]) == st0 + 3 and not sim.stash.has(helmet), "a deep ask paying safe steel did not pay")
	var u: Dictionary = Items.roll_unique(Data.UNIQUES[0], sim.rng)
	_check(not sim.contract_fits(deep, u), "a unique fits a contract")
	# turning one down: free once a run, then notes doubling, free again after a run
	sim.passes = 0
	sim.notes = 100
	_check(sim.pass_cost() == 0 and sim.pass_contract(1) and sim.notes == 100, "the first turn-down cost notes")
	_check(sim.pass_cost() == Data.CONTRACT_PASS_NOTES and sim.pass_contract(1) and sim.notes == 100 - Data.CONTRACT_PASS_NOTES, "the second turn-down did not cost %d notes" % Data.CONTRACT_PASS_NOTES)
	_check(sim.pass_cost() == Data.CONTRACT_PASS_NOTES * 2, "the third turn-down does not double: %d" % sim.pass_cost())
	sim.notes = sim.pass_cost() - 1
	_check(not sim.can_pass_contract(1) and not sim.pass_contract(1), "a turn-down took without the notes")
	sim.notes = 100
	sim.hp = sim.max_hp()
	sim.deploy(3)
	sim.extract_now()
	if sim.on_mission():
		sim._extract()
	_check(sim.pass_cost() == 0, "a run home did not make the next turn-down free: %d" % sim.pass_cost())
	# a save keeps them; a save from before has its unique, socketable and rounds pays rolled again
	sim.passes = 2
	var rt: Dictionary = sim.to_dict()
	sim.load_dict(rt)
	_check(sim.passes == 2 and sim.contracts[0]["kind"] == rt["contracts"][0]["kind"], "the contracts or the turn-downs did not survive a save")
	var old: Dictionary = sim.to_dict()
	old["contracts"] = [{"slot": "Armour", "rarity": 2, "count": 3, "pay": "unique", "amount": 0, "unique": "x"}, {"slot": "Helmet", "rarity": 1, "count": 1, "pay": "socketable", "amount": 1, "what": "Road salt"}]
	sim.load_dict(old)
	_check(sim.contracts.all(func(c): return c["pay"] in Data.CONTRACT_PAYS and c.has("kind")), "an old save kept a unique or an item pay: %s" % str(sim.contracts))
	# five open with Orders: five rows on the tab
	_yard_set(sim, "fence", 1, "b")
	_check(sim.contracts.size() == Data.CONTRACTS_MAX, "Orders did not open five: %d" % sim.contracts.size())
	main.show_room(main.MARKET)
	main._fence._show("contracts")
	main._fence._shown = ""
	main.refresh()
	_check(main._fence._deal_rows.filter(func(r): return r["panel"].visible).size() == Data.CONTRACTS_MAX, "the tab does not show five rows with Orders")
	_check(main._fence._deal_rows[0]["pass"].text.begins_with("Turn it down ·") and main._fence._deal_rows[0]["tag"].text != "", "a row's turn-down or its tag is off: '%s'" % main._fence._deal_rows[0]["pass"].text)
	_check_fit(main, "Fence (five contracts)")
	# the Fence's contracts tab reads them and fits
	main.show_room(main.MARKET)
	main._fence._show("contracts")
	main._fence._shown = ""
	main.refresh()
	_check_fit(main, "Fence (material contracts)")
	main._fence._show("shelf")
	sim.load_dict(saved)
	main.refresh()
	print("the contracts ok: five kinds of ask, four currencies, salvage from its depth, the turn-down's price, the old saves, five rows")


## 34: crafting at the Bench. Scrap in hand from searches, scrapping and ditching; the Build column: a box of rounds,
## a grade from the box below, a med from the one below, an improvised gun firing nails, a grenade from its socketable.
func _build_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.scrap = 0
	# scrap from a search comes home; a ditch is scrap too; scrapping an item at the Bench is its value over twenty
	sim.deploy(3)
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
	_check(sim.scrap_item(junk["id"]) and not sim.stash.has(junk) and sim.scrap == before_scrap + sim.scrap_of(junk), "scrapping at the Bench is off: %d" % sim.scrap)
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
	# a gun: improvised, Common, plain, firing nails whatever it is, up to the Bench's level
	var guns: Array = sim.build_options("gun")
	_check(guns.size() >= 4 and guns.any(func(o): return o["tier"] >= 4), "the guns' list is not every improvised tier (9 Oct: no Bench level holds them back): %s" % str(guns.map(func(o): return [o["name"], o["tier"]])))
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
	sim.deploy(3)
	var out_opt: Dictionary = sim.build_option("box", "Shells")
	_check(not out_opt["ok"] and out_opt["why"] == "The runner is out" and not sim.build("box", "Shells") and not sim.scrap_item(sim.stash[0]["id"]), "the Bench worked with the runner out")
	sim.extract_now()
	_check(sim.last_report.has("scrap"), "the report does not carry the run's scrap")
	# the Bench's craft view says so and fits; the menus open and fit
	sim.scrap = 50
	main.show_room(main.WORKSHOP)
	main._workshop._set_view("craft")
	main._workshop.sel_id = -1
	main._workshop._shown = ""
	main.refresh()
	_check(main._workshop._build.visible and main._workshop._build.text == "Build for scrap", "the craft view has no Build button: '%s'" % main._workshop._build.text)
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
	print("the Bench's builds ok: scrap from a search, a ditch and a scrapping; a box, a grade from the box below, the med ladder, a gun firing nails, a grenade from its socketable, the refusals, the view and the menus")


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
		sim.deploy(3)
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
	var odds: float = sim.survival(3)
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
	sim.deploy(3)
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
	# the Fence's shelf carries them now and then
	var seen := false
	for k in range(40):
		sim.restock()
		if sim.market.any(func(it): return Items.is_grenade(it)):
			seen = true
			break
	_check(seen, "forty restocks put no grenade on the Fence's shelf")
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
	_check(pk.visible and pk._heads[0].visible and pk._heads[0]._title.text == "Choke" and pk._tag_labels[0].visible, "the Bench's part pick is not on the pick frame: '%s'" % pk._heads[0]._title.text)
	_check(pk.button_texts() == ["Fit"] and pk._buttons[0].disabled and pk._words.visible and pk._words.text == "Shotguns only", "the Bench did not grey Fit with the reason: %s / '%s'" % [str(pk.button_texts()), pk._words.text])
	_check(not pk.button_texts().any(func(t): return t.begins_with("Sell")), "Sell is on the Bench")
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
	print("the Bench's pick frame ok: the part, the refusal, the fit, the fitted")


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
	sim.deploy(3)
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
	_check(not pk.text_nodes().any(func(l): return l.text.begins_with("The Fence pays") or l.text.begins_with("Ditched")), "the Fence line or the ditched line is still there")
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


## 31: the works' rules, now picks (9 Oct): the Generator's Battery, the Lookout's Hold fire, the Kennel's Fetch.
func _top_works_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	_check(not Data.yard_where("battery").is_empty() and not Data.yard_where("hold_fire").is_empty() and not Data.yard_where("fetch").is_empty(), "a work's rule is not a pick")
	# the generator: a second row of pouches, never past the cap
	var hold_rig = sim.equipped["Rig"]
	var big: Dictionary = sim._plain("Rig", Data.BASES["Rig"].back()["name"])
	big["affixes"] = [{"stat": "med_cap", "value": 3, "tier": 5}]
	sim.equipped["Rig"] = big
	_yard_set(sim, "generator", 0, "a")
	_yard_set(sim, "generator", 2, "")
	var before: int = sim.med_capacity()
	_yard_set(sim, "generator", 2, "a")
	_check(before > 0 and sim.med_capacity() == mini(before + Data.RIG_ROW, Data.RIG_CAP) and sim.med_capacity() > before, "the Battery's row reads %d from %d" % [sim.med_capacity(), before])
	_yard_set(sim, "generator", 0, "b")
	_check(sim.med_capacity() == mini(before + Data.RIG_ROW + 4, Data.RIG_CAP), "Rig wiring's pouches are off: %d" % sim.med_capacity())
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
	sim.deploy(3)
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
	_yard_set(sim, "lookout", 2, "a")
	sim.deploy(3)
	var m: Dictionary = sim.mission
	m["remaining"] = 0
	m["cleared"] = true
	m["found"] = []
	m["patrol_timer"] = 0.0
	sim.advance(5.0)
	_check(sim.on_mission() and m["patrols"] == 0 and m["patrol_timer"] == 0.0, "the first gang's clock ran before the call: %.1f" % m["patrol_timer"])
	main.show_room(main.MISSIONS)
	main.refresh()
	_check(main._run._fight["tiles"][0]["value"].text in ["on the call", "held"], "the Next gang tile does not say on the call: '%s'" % main._run._fight["tiles"][0]["value"].text)
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
	_yard_set(sim, "kennel", 2, "a")
	sim.deploy(3)
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
	_yard_set(sim, "kennel", 2, "a")
	var hold_ending: String = sim.ending
	sim.ending = ""
	sim.deploy(3)
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
	print("the works' rules ok: the Battery's row, Hold fire, Fetch")


## What's on them and on you as chips (Matt, 6 Oct): "On them" under their bar, "On you" in place of the runner's note.
func _dots_chip_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.deploy(3)
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
	_check(segs[fire_i].visible and segs[poison_i].visible and absf(segs[fire_i].size.x - rn.BOXED_W * 0.1) <= 1.5 and absf(segs[poison_i].size.x - rn.BOXED_W * 0.2) <= 1.5, "their bar's end is not the dots' pools: fire %.0f, poison %.0f" % [segs[fire_i].size.x, segs[poison_i].size.x])
	_check(absf(segs[fire_i].position.x + segs[fire_i].size.x - fill_px) <= 0.5 and absf(segs[poison_i].position.x + segs[poison_i].size.x - segs[fire_i].position.x) <= 0.5, "the pools do not sit at the fill's end, in a row")
	var ysegs: Array = rn._runner["segments"]
	var yfill: float = rn._runner["fill"].size.x
	_check(ysegs[poison_i].visible and ysegs[bleed_i].visible and absf(ysegs[poison_i].size.x - rn.BOXED_W * 0.1) <= 1.5 and absf(ysegs[bleed_i].size.x - (yfill - ysegs[poison_i].size.x)) <= 1.5 and ysegs[bleed_i].position.x >= -0.5, "a pool past the fill's left end is not cut to it: poison %.0f, bleed %.0f of a %.0f fill" % [ysegs[poison_i].size.x, ysegs[bleed_i].size.x, yfill])
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


## 30: wounds. A hit that takes the runner under a quarter leaves one stat cut a tenth until the Clinic treats
## it for cash by level; one at a time; the Yard, the run and the Clinic say so; it goes with the runner.
func _wound_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.wound = ""
	# the hit under a quarter wounds; one already under it does not
	sim.deploy(3)
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
	# the Runner room's card and the last run say so
	main.show_room(main.RUNNER)
	main.refresh()
	var wound_chips: Array = _chip_texts(main._stats.cards["runner"]["chips"])
	_check(not wound_chips.is_empty() and str(wound_chips[0]).begins_with("Wounded:"), "the sheet does not carry the wound chip: %s" % str(wound_chips))
	_check_fit(main, "Stats (wounded)")
	# the Clinic: the band says so, Treat costs the wound's price by level at full HP, and clears it
	sim.wound = "pace"                    # a wound that leaves the max HP alone: the checks below read HP against it
	sim.hp = sim.max_hp()
	sim.cash += 5000.0
	var lv: int = sim.level()
	var expect: int = int(ceil(Data.WOUND_CASH * lv * sim.inflation() * maxf(0.2, 1.0 - sim.tree_sum("treat_pct") / 100.0)))
	_check(sim.needs_treating() and sim.treat_cost() == expect, "the wound's price reads %d, not %d" % [sim.treat_cost(), expect])
	main.show_room(main.MEDIC)
	main._clinic._shown = ""
	main.refresh()
	_check(main._clinic._band.unit.text.contains("wounded"), "the Clinic's band does not say wounded: '%s'" % main._clinic._band.unit.text)
	# the two jobs apart (Clinic-B): at full HP the wound's button is the primary, Heal reads Fit
	_check(main._clinic._side_buttons[1].text.begins_with("The wound (") and not main._clinic._side_buttons[1].disabled, "the Clinic's wound button is off: '%s'" % main._clinic._side_buttons[1].text)
	_check(main._clinic._side_buttons[0].text == "Fit" and main._clinic._side_buttons[0].disabled, "the Clinic's heal button at full HP reads '%s'" % main._clinic._side_buttons[0].text)
	_check(main._clinic._side_buttons[0].position.x + main._clinic._side_buttons[0].size.x <= main._clinic._side_buttons[1].position.x, "the Clinic's two buttons overlap")
	_check(main._clinic._side_bar_text.text.contains("wounded"), "the Clinic's bar does not name the wound: '%s'" % main._clinic._side_bar_text.text)
	_check_fit(main, "Clinic (wounded)")
	# hurt and wounded: heal alone costs the HP's price and leaves the wound; the wound alone costs its price and leaves the HP
	sim.hp = sim.max_hp() * 0.5
	main.refresh()
	var heal_expect: int = sim.heal_cost()
	_check(heal_expect > 0 and sim.wound_cost() == expect and sim.treat_cost() == heal_expect + expect, "the Clinic's prices do not add up: heal %d, wound %d, both %d" % [heal_expect, sim.wound_cost(), sim.treat_cost()])
	_check(main._clinic._side_buttons[0].text.begins_with("Heal (") and not main._clinic._side_buttons[0].disabled, "the Clinic's heal button is off hurt: '%s'" % main._clinic._side_buttons[0].text)
	var cash0: float = sim.cash
	main._clinic._side_press(0)
	_check(sim.hp >= sim.max_hp() - 0.5 and sim.wound != "" and is_equal_approx(cash0 - sim.cash, float(heal_expect)), "Heal did not heal alone: hp %.0f of %.0f, wound '%s', %.0f paid" % [sim.hp, sim.max_hp(), sim.wound, cash0 - sim.cash])
	main.refresh()
	cash0 = sim.cash
	main._clinic._side_press(1)
	_check(sim.wound == "" and is_equal_approx(cash0 - sim.cash, float(expect)) and not sim.needs_treating(), "The wound did not see to the wound: '%s', %.0f paid" % [sim.wound, cash0 - sim.cash])
	main.refresh()
	_check(main._clinic._side_buttons[0].text == "Fit for duty" and main._clinic._side_buttons[1].text == "No wound", "the Clinic's buttons after treatment: '%s' / '%s'" % [main._clinic._side_buttons[0].text, main._clinic._side_buttons[1].text])
	_check_fit(main, "Clinic (fit)")
	# saved and loaded; gone with a dead runner
	sim.wound = "pace"
	var d: Dictionary = sim.to_dict()
	_check(str(d.get("wound", "")) == "pace", "the wound is not saved")
	sim.load_dict(d)
	_check(sim.wound == "pace", "the wound is not loaded")
	sim.deploy(3)
	sim.hp = 0.0
	sim._kia()
	_check(sim.wound == "", "the wound went on to the next runner")
	sim.load_dict(saved)
	main.refresh()
	print("wounds ok: the hit under a quarter, one stat a tenth, one at a time, the run, the Yard, the Clinic's price and cure, the save, the death")


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
	sim.set_depth(3, 1)
	sim.deploy(3)
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
		var finds_each: int = 1 + (1 if (sim.has_node("scavenger") or sim.has_node("quiet_hands")) else 0) + (1 if sim.yard_has("a_dog") else 0) + (1 if sim.yard_has("second_dog") else 0) + (2 if sim.yard_has("pack") else 0) + (1 if sim.has_rule("postman") else 0)
		var per: float = float(int(m.get("finds", 0)) - found0) / maxf(1.0, float(m["searches"] - s0))
		_check(m["searches"] - s0 >= 20 and per < float(finds_each) * 0.8, "at the floor a search still brings %.2f of %d (%d searches)" % [per, finds_each, m["searches"] - s0])
		sim.extract_now()
	# deeper sites and quantity give more searches in full; the figure ratchets through a run
	sim.deploy(3)
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


## The Yard as lanes (9 Oct, docs/design/yard.md): eight buildings, five columns of two picks and a rank; a tile
## picks, the strip builds; the other side stays on show and refits for half; the columns open on the campaign
## and the depth and stay open; the rank at depth 9; the rail's Upgrade badge; every pick's figure where it lives;
## salvage from the deep sites; the buildings move with the Yard; an old save's levels become picks.
func _yard_wide_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	main.show_room(main.OVERVIEW)
	main.refresh()
	var yt = main._yard_tree
	_check(yt.visible and not main._grid.visible, "the Yard is not the lanes alone")
	# every pick its own glyph, and no column's two the same (Lanes-G, the review)
	for bld in Data.YARD:
		for col in bld["picks"]:
			_check(NodeGlyphs.PICK_GLYPH.has(col[0]["id"]) and NodeGlyphs.PICK_GLYPH.has(col[1]["id"]), "a Yard pick has no glyph of its own: %s / %s" % [col[0]["id"], col[1]["id"]])
			_check(NodeGlyphs.of_pick(col[0], bld["key"]) != NodeGlyphs.of_pick(col[1], bld["key"]), "%s's %s and %s share a glyph" % [bld["name"], col[0]["name"], col[1]["name"]])
			for pk in col:
				_check(NodeGlyphs.SVG.has(NodeGlyphs.of_pick(pk, bld["key"])), "%s's glyph is not drawn: %s" % [pk["name"], NodeGlyphs.of_pick(pk, bld["key"])])
	_check(yt.STRIP_Y + yt.STRIP_H <= yt.size.y and yt._build.position.y + yt._build.size.y <= yt.STRIP_H, "the Yard's strip runs past the room or its button out of it")
	# the heading takes the room the lanes left (Matt, 10 Oct): the strip ends at the room's foot, the heading its band
	_check(is_equal_approx(yt.STRIP_Y + yt.STRIP_H, yt.size.y) and yt.HEAD_H >= 200 and yt.LANES_Y == yt.HEAD_H + 8, "the Yard leaves room unused or its heading short: strip to %d of %d, heading %d" % [yt.STRIP_Y + yt.STRIP_H, int(yt.size.y), yt.HEAD_H])
	var mv: Button = yt._move
	_check(mv.position.y + mv.size.y <= yt.HEAD_H - 8 and mv.position.y >= yt.HEAD_H / 2.0, "Move the Yard is not at the band's foot")
	var names: Array = yt._lanes.map(func(l): return l["name"].text)
	_check(names == Data.YARD.map(func(b): return b["name"]), "the Yard's lanes are off: %s" % str(names))
	# a fresh Yard: column 1 open, the rest shut with their gates; nothing affordable with no cash
	sim.yard_picks = {}
	sim.yard_ranks = {}
	sim.yard_open = 1
	sim.yard_seen = {}
	sim.yard_seen_cols = 1
	sim._yard_changed("")
	var cash0: float = sim.cash
	sim.cash = 0.0
	yt.selected = {}
	yt._shown = ""
	main.refresh()
	_check(sim.yard_cols() >= 1 and yt.tile("bench", 0, "a")["look"] == "open" and (sim.yard_cols() > 1 or yt.tile("bench", 1, "a")["look"] == "shut"), "the fresh Yard's columns are off: %d open, %s / %s" % [sim.yard_cols(), yt.tile("bench", 0, "a")["look"], yt.tile("bench", 1, "a")["look"]])
	_check(main._rail_status(main.OVERVIEW).get("badge", "") == "", "the rail's Upgrade badge is lit with no cash")
	_check(sim.yard_pick_block("bench", 0, "a") == "Short of cash", "a pick with no cash: '%s'" % sim.yard_pick_block("bench", 0, "a"))
	_check(sim.yard_pick_block("bench", 5 - 1, "a") == Data.YARD_GATES[4] or sim.yard_cols() >= 5, "a shut column's block is not its gate: '%s'" % sim.yard_pick_block("bench", 4, "a"))
	# pick, build, the other side dim, a refit for half; the badge is news only (9 Oct): lit for what's newly
	# buyable or a column opened since the Yard was looked at, cleared by looking
	main.show_room(main.MISSIONS)
	sim.cash = 1000000.0
	main.refresh()
	_check(main._rail_status(main.OVERVIEW).get("badge", "") == "Upgrade", "the rail's Upgrade badge is not lit with a pick newly affordable")
	main.show_room(main.OVERVIEW)
	_check(main._rail_status(main.OVERVIEW).get("badge", "") == "" and not main._rail_buttons[main.OVERVIEW]._badge.visible, "looking at the Yard did not clear the badge (as drawn: %s)" % str(main._rail_buttons[main.OVERVIEW]._badge.visible))
	var seen_n: int = sim.yard_seen.size()
	var rt: Dictionary = sim.to_dict()
	sim.yard_seen = {}
	sim.load_dict(rt)
	_check(sim.yard_seen.size() == seen_n and seen_n > 0 and sim.yard_seen_cols == sim.yard_cols(), "what the badge has seen did not survive a save: %d of %d" % [sim.yard_seen.size(), seen_n])
	main.show_room(main.MISSIONS)
	sim.cash = 0.0
	main.refresh()
	sim.cash = 1000000.0
	main.refresh()
	_check(main._rail_status(main.OVERVIEW).get("badge", "") == "", "the badge lit again for picks already seen")
	sim.hp = sim.max_hp()
	sim.deploy(3)
	_check(sim.on_mission() and not sim._yard_buyable_ids().is_empty(), "with the runner out, the Yard reads nothing buyable for the badge")
	if sim.on_mission():
		sim._extract()
	sim.yard_open = sim.yard_cols() + 1
	_check(main._rail_status(main.OVERVIEW).get("badge", "") == "Upgrade", "a column opened did not light the badge")
	sim.yard_open = 1
	sim.yard_seen_cols = 1
	main.show_room(main.OVERVIEW)
	yt._press("kennel", 0, "a")
	main.refresh()
	_check(yt._title.visible and yt._title.text.begins_with("A dog") and yt._build.text == "Build" and not yt._build.disabled, "the strip does not offer A dog: '%s' / '%s'" % [yt._title.text, yt._build.text])
	_check_fit(main, "Yard (a pick picked)")
	var c1: int = sim.yard_pick_cost("kennel", 0)
	var cash1: float = sim.cash
	yt._on_build()
	main.refresh()
	_check(sim.yard_has("a_dog") and is_equal_approx(sim.cash, cash1 - c1) and yt.tile("kennel", 0, "a")["look"] == "built" and yt.tile("kennel", 0, "b")["look"] == "other", "Build did not build A dog: %s, £%.0f" % [str(sim.yard_picks.get("kennel", [])), cash1 - sim.cash])
	_check(yt._build.text == "Built" and yt._build.disabled, "a built pick still offers a build")
	yt._press("kennel", 0, "b")
	main.refresh()
	_check(yt._build.text == "Refit" and sim.yard_pick_cost("kennel", 0) == int(round(c1 * Data.YARD_REFIT)), "the other side does not refit for half: '%s', %d of %d" % [yt._build.text, sim.yard_pick_cost("kennel", 0), c1])
	yt._on_build()
	_check(sim.yard_has("good_nose") and not sim.yard_has("a_dog"), "the refit did not swap the pick")
	_check_fit(main, "Yard (a refit)")
	# the columns open on the campaign and the depth, and stay open
	sim.best_dig = {}
	for i in range(sim.depth.size()):
		sim.depth[i] = 1
		sim.best_depth[i] = 0
	sim.yard_open = 0
	_finish_campaign(sim)
	_check(sim.yard_cols() == 4, "the campaign done opens %d columns, not four" % sim.yard_cols())
	sim.best_dig = {"site": "The Streets", "depth": 9, "yard": 1}
	_check(sim.yard_cols() == Data.YARD_COLS, "depth 9 does not open every column")
	sim.best_dig = {}
	for i in range(sim.depth.size()):
		sim.depth[i] = 1
		sim.best_depth[i] = 0
	_check(sim.yard_cols() == Data.YARD_COLS, "the columns closed again when the depth went")
	# the fifth column and the rank want salvage
	sim.salvage = {"copper": 0, "steel": 0, "army": 0}
	_check(sim.yard_pick_block("stash", 4, "a").begins_with("Wants 10 copper"), "column five without salvage: '%s'" % sim.yard_pick_block("stash", 4, "a"))
	sim.salvage["copper"] = 40
	var r0: int = sim.yard_rank_cost("stash")
	_check(sim.yard_pick("stash", 4, "b") and sim.salvage["copper"] == 30 and sim.buy_yard_rank("stash") and sim.yard_rank("stash") == 1 and sim.salvage["copper"] == 25, "the salvage did not pay: %s" % str(sim.salvage))
	_check(sim.yard_rank_cost("stash") > r0 and sim.yard_rank_salvage("stash") == Data.YARD_RANK_SALVAGE + 1, "the rank's price did not climb")
	yt._press_rank("stash")
	yt._shown = ""
	main.refresh()
	_check(yt._build.text == "Buy rank 2" and yt._title.text.contains("rank 1"), "the rank's strip is off: '%s' / '%s'" % [yt._title.text, yt._build.text])
	_check_fit(main, "Yard (a rank)")
	yt.selected = {}
	sim.cash = cash0
	yt._shown = ""
	main.refresh()
	_check(yt._headline.text.contains(" of 40") and yt._unit.text == "upgrades built", "the Yard's headline is off: '%s' %s" % [yt._headline.text, yt._unit.text])
	_check(yt._chips.shown() == 6 and yt._chips._labels[0].text.begins_with(Fmt.money(sim.cash)), "the Yard's purse chips are off: %d shown, first '%s'" % [yt._chips.shown(), yt._chips._labels[0].text])
	# the purse down the left under the title (Matt, 10 Oct): below the headline, inside the title's width and the band,
	# clear of Move; every chip shown with the most salvage the Yard can hold
	var yc := Rect2(yt._chips.position, yt._chips.size)
	_check(yc.position.y >= yt._headline.position.y + yt._headline.size.y and yc.end.x <= yt.PAD + 350 and yc.end.y <= yt.HEAD_H - 8 and not yc.intersects(Rect2(yt._move.position, yt._move.size)), "the Yard's purse is not down the left under the title: %s" % str(yc))
	var salv_was: Dictionary = sim.salvage.duplicate()
	var cash_was: float = sim.cash
	var notes_was: int = sim.notes
	var scrap_was: int = sim.scrap
	for kind in Data.SALVAGE:
		sim.salvage[kind] = 99999
	sim.cash = 99999999.0
	sim.notes = 999999
	sim.scrap = 999999
	yt._shown = ""
	main.refresh()
	yc = Rect2(yt._chips.position, yt._chips.size)
	_check(yt._chips.shown() == 6 and yc.end.y <= yt.HEAD_H - 8 and yc.end.x <= yt.PAD + 350, "the Yard's purse loses a chip or leaves the band at the most: %d shown, %s" % [yt._chips.shown(), str(yc)])
	sim.salvage = salv_was
	sim.cash = cash_was
	sim.notes = notes_was
	sim.scrap = scrap_was
	yt._shown = ""
	main.refresh()
	_check(yt._move.visible == sim.can_move_yard(), "Move the Yard shows %s when the Yard %s move" % ["on" if yt._move.visible else "off", "can" if sim.can_move_yard() else "cannot"])
	_check_fit(main, "Yard (lanes)")
	sim.load_dict(saved)
	main.refresh()
	_yard_pick_checks(main)


## Every pick's figure where it lives (9 Oct): each set straight in, read, set back.
func _yard_pick_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.yard_picks = {}
	sim.yard_ranks = {}
	sim._yard_changed("")
	var on := func(key: String, col: int, side: String) -> void:
		_yard_set(sim, key, col, side)
	# the Bench
	var it: Dictionary = sim._plain("Helmet", "Hard hat")
	it["affixes"] = [{"stat": "hp", "value": 5, "tier": 1}]
	it["rarity"] = 1
	var reroll0: int = sim.craft_cost(it, "reroll")
	on.call("bench", 0, "b")
	_check(sim.craft_cost(it, "reroll") == int(round(sim._inf(int(Data.CRAFT["reroll"]["cash"]) * Items.ilvl(it) * 2) * 0.75)) or sim.craft_cost(it, "reroll") < reroll0, "Cheap parts did not take a quarter off: %d from %d" % [sim.craft_cost(it, "reroll"), reroll0])
	on.call("bench", 1, "a")
	on.call("bench", 3, "a")
	_check(sim.socket_max() == Data.SOCKET_MAX + 1 and sim.bump_levels() == Data.BUMP_LEVELS * 2, "Third socket or Overbump is off")
	sim.yard_ranks["bench"] = 2
	_check(sim.bump_cap() == Data.BUMP_CAP + 2, "the Bench's rank does not raise the cap")
	sim.yard_ranks = {}
	var scrap0: int = sim.scrap_of(it)
	on.call("bench", 2, "b")
	_check(sim.scrap_of(it) == scrap0 * 2, "Strip for parts did not double the scrap")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var t3: Dictionary = sim._plain("Helmet", "Hard hat")
	t3["rarity"] = 4
	var down := false
	for k in range(300):
		t3["affixes"] = [{"stat": "hp", "value": 20, "tier": 3}]
		Items.reroll_one(t3, "hp", rng, 1.0, true)
		down = down or int(t3["affixes"][0]["tier"]) < 3
	_check(not down, "Fine tuning let a re-roll go down a tier")
	var aff: Dictionary = Items.affix_def("hp")
	var rr: Array = Items.tier_range(aff, 2)
	var low := false
	for k in range(200):
		low = low or Items.roll_affix(aff, 1, rng, 2, 0, true)["value"] < int(ceil((rr[0] + rr[1]) / 2.0))
	_check(not low, "Masterwork rolled in the bottom half")
	var two: Dictionary = sim._plain("Armour", Data.BASES["Armour"][0]["name"])
	two["rarity"] = 3
	two["affixes"] = [{"stat": "hp", "value": 5, "tier": 1}, {"stat": "armour_pct", "value": 30, "tier": 3}, {"stat": "rest_pct", "value": 5, "tier": 1}]
	Items.reroll_affixes(two, rng, "hp", false, true)
	_check(two["affixes"].size() == 3 and two["affixes"].any(func(a): return a["stat"] == "armour_pct" and int(a["value"]) == 30), "Two locks did not keep the best of the rest: %s" % str(two["affixes"]))
	# the Stash
	var cap0: int = sim.stash_cap()
	on.call("stash", 0, "a")
	on.call("stash", 1, "a")
	on.call("stash", 3, "a")
	on.call("stash", 4, "b")
	sim.yard_ranks["stash"] = 1
	_check(sim.stash_cap() == cap0 + 40 + 50 + 60 + 100 + 20, "the Stash's cells are off: %d from %d" % [sim.stash_cap(), cap0])
	sim.yard_ranks = {}
	# a refit off cells is allowed, and the strip says first how far over it leaves the stash (9 Oct)
	var stash_keep: Array = sim.stash.duplicate(true)
	while sim.stash_used() < sim.stash_cap():
		sim.stash.append(sim._plain("Helmet", "Hard hat"))
	var picks_keep: Dictionary = sim.yard_picks.duplicate(true)
	var over_want: int = sim.yard_refit_over("stash", 0, "b")         # Shelving's forty, less what Racks frees, plus a hard hat past the cap
	_check(over_want > 30 and over_want <= sim.stash_used() - sim.stash_cap() + 40 and sim.yard_picks == picks_keep, "the refit off Shelving reads %d over, or the reading changed the picks" % sim.yard_refit_over("stash", 0, "b"))
	_yard_set(sim, "kennel", 0, "a")
	_check(sim.yard_refit_over("kennel", 0, "b") == 0, "a refit that takes no cells reads over")
	var yt = main._yard_tree
	main.show_room(main.OVERVIEW)
	yt._press("stash", 0, "b")
	main.refresh()
	_check(yt._other.text.contains("%d cells over" % over_want) or yt._other.text.contains("%d over" % over_want), "the strip does not warn of the stash going over: '%s'" % yt._other.text)
	_check_fit(main, "Yard (a refit over the stash's cap)")
	yt.selected = {}
	sim.stash = stash_keep
	on.call("stash", 0, "b")
	on.call("stash", 2, "b")
	on.call("stash", 3, "b")
	_check(sim.stash_free(sim._plain(Data.AMMO, "Nails")) and sim.stash_free(Items.roll_unique(Data.UNIQUES[0], sim.rng)) and sim.stash_free(sim._plain(Data.PAPER, "A P45")) and not sim.stash_free(it), "Racks, Wall of fame or Paper rack is off")
	on.call("stash", 1, "b")
	var junk: Dictionary = sim._plain("Helmet", "Army helmet")     # worth a pound of scrap or more (a hard hat's £20 is under 24, 12 Oct)
	junk["rarity"] = 0
	junk["affixes"] = []
	var sc0: int = sim.scrap
	var binned: Array = sim._bin_commons([junk, sim._plain(Data.AMMO, "Nails")])
	_check(binned.size() == 1 and not binned.has(junk) and sim.scrap > sc0, "Bins did not scrap the commons: %d kept" % binned.size())
	var ins0: int = sim.insure_cost(3)
	on.call("stash", 2, "a")
	_check(sim.insure_cost(3) <= int(ceil(ins0 / 2.0 / 10.0)) * 10 + 10, "Strongroom did not halve insurance: %d from %d" % [sim.insure_cost(3), ins0])
	# the Clinic
	var rest0: float = sim.rest_rate()
	on.call("clinic", 0, "a")
	on.call("clinic", 1, "a")
	_check(is_equal_approx(sim.rest_rate(), rest0 * (Data.REST_BASE + 1.5) / Data.REST_BASE), "Beds and Ward are off: %.2f from %.2f" % [sim.rest_rate(), rest0])
	on.call("clinic", 0, "b")
	on.call("clinic", 1, "b")
	_check(sim.clinic_stock() == Data.CLINIC_STOCK + 10, "Shelf and Stockroom are off: %d" % sim.clinic_stock())
	sim.wound = "pace"
	var wc0: int = sim.wound_cost()
	var wm0: float = sim.wound_mult("pace")
	on.call("clinic", 2, "a")
	_check(sim.wound_cost() <= int(ceil(wc0 / 2.0)) + 1, "Surgery did not halve the wound's price")
	on.call("clinic", 2, "b")
	_check(sim.wound_mult("pace") > wm0, "Physio did not lighten the wound")
	sim.wound = ""
	on.call("clinic", 3, "b")
	var bandages := func() -> int: return sim.rig.filter(func(x): return str(x.get("base", "")) == "Bandage").size()
	var room_k: bool = sim.rig_room(1)
	var bn0: int = bandages.call()
	sim.hp = sim.max_hp()
	sim.deploy(3)
	_check(not room_k or bandages.call() == bn0 + 1, "the Field kit did not put a bandage in the rig")
	sim.extract_now()
	var hp0: float = sim.max_hp()
	on.call("clinic", 4, "a")
	sim.yard_ranks["clinic"] = 2
	_check(is_equal_approx(sim.max_hp(), hp0 * 1.16), "Theatre and the Clinic's rank are off: %.1f from %.1f" % [sim.max_hp(), hp0])
	sim.yard_ranks = {}
	# the Fence
	var stock0: int = sim.market_stock()
	var words0: Array = sim.words.duplicate(true)
	var shelf0: Array = sim.market.duplicate(true)
	on.call("fence", 0, "a")
	_check(sim.words == words0 and sim.market.slice(0, shelf0.size()) == shelf0 and sim.market.size() == shelf0.size() + 2, "a Fence pick re-rolled the words or the shelf: %d from %d" % [sim.market.size(), shelf0.size()])
	on.call("fence", 1, "a")
	_check(sim.market_stock() == stock0 + 5 and sim.market.size() >= sim.market_stock(), "Stall and Shopfront are off: %d, %d on the shelf" % [sim.market_stock(), sim.market.size()])
	var sp0: int = sim.sell_price(it)
	on.call("fence", 0, "b")
	on.call("fence", 4, "b")
	sim.yard_ranks["fence"] = 1
	_check(sim.sell_price(it) > sp0 and absi(sim.sell_price(it) - int(round(sp0 * 1.37))) <= 2, "Haggling, Dealer's cut and the rank are off: %d from %d" % [sim.sell_price(it), sp0])
	sim.yard_ranks = {}
	on.call("fence", 1, "b")
	_check(sim.contracts_open() == Data.CONTRACTS_OPEN + 2 and sim.contracts.size() >= sim.contracts_open(), "Orders did not open two more contracts: %d up" % sim.contracts.size())
	# a build never refills a shelf bought from; a refit off Orders takes its two back
	sim.market = sim.market.slice(0, 1)
	on.call("fence", 2, "b")
	_check(sim.market.size() == 1, "a build refilled the Fence's shelf: %d on it" % sim.market.size())
	on.call("fence", 1, "a")
	_check(sim.contracts.size() == Data.CONTRACTS_OPEN, "the refit off Orders left %d contracts" % sim.contracts.size())
	on.call("fence", 2, "a")
	_check(sim.market.any(func(x): return x.has("unique")), "the Back room has no unique on the shelf")
	var g0: int = sim.gamble_price(Data.GAMBLE_KINDS[0]["kind"])
	on.call("fence", 3, "a")
	_check(g0 <= 0 or absi(sim.gamble_price(Data.GAMBLE_KINDS[0]["kind"]) - int(round(g0 * 0.5))) <= 1, "the Gambler's table did not halve the gamble")
	# the Radio (9 Oct, map juicing): the sky's two columns, then the words'
	var hold_elapsed: float = sim.elapsed
	var hold_weather: Array = sim.weather.duplicate()
	sim.elapsed = 3600.0 * 3.0                       # noon
	sim.weather[1] = "Rain"
	var rain0: Dictionary = sim.effective(3)
	on.call("radio", 0, "a")
	var rain1: Dictionary = sim.effective(3)
	_check(is_equal_approx(rain1["search"], rain0["search"] / 1.3 * 1.15), "the Weather set did not halve the rain: %.3f from %.3f" % [rain1["search"], rain0["search"]])
	on.call("radio", 1, "a")
	_check(is_equal_approx(sim.effective(3)["cash"], rain1["cash"] * 1.2), "the forecast did not pay a fifth more under the rain")
	sim.weather[1] = ""
	sim.elapsed = 3600.0 * 14.0                      # 23:00
	var night0: Dictionary = sim.effective(3)
	on.call("radio", 0, "b")
	_check(sim.is_night() and is_equal_approx(sim.effective(3)["pace"], night0["pace"] / 0.8 * 0.9), "the Night set did not halve night's feet: %.3f from %.3f" % [sim.effective(3)["pace"], night0["pace"]])
	var patrol_n: float = sim.effective(3)["patrol"]
	on.call("radio", 1, "b")
	_check(is_equal_approx(sim.effective(3)["patrol"], patrol_n * 1.25), "Dead air did not slow the night's gangs")
	sim.elapsed = hold_elapsed
	sim.weather = hold_weather
	_finish_campaign(sim)
	sim.atlas = {}
	sim.best_depth[3] = maxi(sim.best_depth[3], 9)
	sim.set_depth(3, 9)
	sim.words[3] = []
	sim.sealed[3] = false
	sim.notes = 100000
	var rc0: int = sim.word_craft_cost(3, "retune")
	on.call("radio", 2, "a")
	_check(sim.word_craft_cost(3, "retune") == maxi(1, int(ceil(18.0 * 0.75))) and rc0 == 18, "the Scanner did not take a quarter off: %d from %d" % [sim.word_craft_cost(3, "retune"), rc0])
	on.call("radio", 2, "b")
	_check(sim.word_craft(3, "tune") and sim.words[3].size() == 1, "Tune in with Two channels did not add one word: %s" % str(sim.words[3]))
	var cd0: int = sim.convoy_depth()
	var mw0: int = sim.max_words(3)
	on.call("radio", 3, "a")
	_check(sim.convoy_depth() == cd0 - 2, "Lorry watch did not bring the convoy up two")
	on.call("radio", 3, "b")
	_check(sim.max_words(3) == mw0 + 1 and mw0 == 4, "Long range did not add a word: %d from %d" % [sim.max_words(3), mw0])
	sim.words[3] = []
	_check(sim.word_craft(3, "broadcast") and sim.words[3].size() == 5, "a broadcast with Long range did not fill five: %s" % str(sim.words[3]))
	on.call("radio", 4, "a")
	var jw: Dictionary = sim.word_effect("Numbers", 1)
	_check(is_equal_approx(float(jw["hp"]), sqrt(1.4)) and is_equal_approx(float(jw["drop"]), 1.3), "the Jammer's word is off: %s" % str(jw))
	on.call("radio", 4, "b")
	var mw: Dictionary = sim.word_effect("Numbers", 1)
	_check(is_equal_approx(float(mw["drop"]), 1.45) and is_equal_approx(float(mw["hp"]), 1.4), "the Military band's word is off: %s" % str(mw))
	sim.yard_ranks["radio"] = 2
	_check(is_equal_approx(float(sim.word_effect("Numbers", 1)["drop"]), 1.0 + 0.3 * 1.6), "the Radio's rank did not add to the pay")
	sim.yard_ranks = {}
	sim.words[3] = []
	# the Generator
	for pair in [[0, 12], [1, 24], [3, 48], [4, 72]]:
		on.call("generator", pair[0], "a")
		_check(is_equal_approx(sim.away_cap_s(), float(pair[1]) * 3600.0), "the Generator's hours are off at column %d: %.0f" % [pair[0] + 1, sim.away_cap_s() / 3600.0])
	var c0: float = sim.cash
	sim.away_on = true
	on.call("generator", 2, "b")
	sim._earn(100.0)
	sim.away_on = false
	_check(is_equal_approx(sim.cash - c0, 125.0), "Overtime did not pay a quarter on the time away: %.1f" % (sim.cash - c0))
	var fire0: float = sim.more("fire")
	on.call("generator", 3, "b")
	_check(is_equal_approx(sim.more("fire"), fire0 * 1.1), "Arc lamps did not add a tenth to fire")
	on.call("generator", 4, "b")
	sim.hp = sim.max_hp() * 0.4
	sim.deploy(3)
	_check(is_equal_approx(sim.hp, sim.max_hp()), "the Charger did not send the run out full")
	sim.extract_now()
	# the Lookout
	var first0: float = sim.patrol_s(sim.effective(3), true)
	on.call("lookout", 0, "a")
	on.call("lookout", 1, "a")
	_check(is_equal_approx(sim.patrol_s(sim.effective(3), true), first0 * 2.0), "Spotter and Lookout post are off: %.1f from %.1f" % [sim.patrol_s(sim.effective(3), true), first0])
	on.call("lookout", 0, "b")
	_check(sim.odds_runs() == 60, "Glasses did not read sixty runs")
	var later0: float = sim.patrol_s(sim.effective(3))
	on.call("lookout", 2, "b")
	on.call("lookout", 3, "b")
	on.call("lookout", 4, "a")
	_check(is_equal_approx(sim.patrol_s(sim.effective(3)), later0 * 1.1 * 1.1 * 1.2), "Tripwires, Watch rota and the Crow's nest are off")
	on.call("lookout", 4, "b")
	var pool0: int = int(sim.effective(3)["pool"])
	sim.deploy(3)
	_check(int(sim.mission["remaining"]) <= maxi(1, pool0 - 1), "Flares did not take a head off the first gang")
	sim.extract_now()
	# the Kennel
	var q0: float = sim.rarity_bonus()
	on.call("kennel", 0, "b")
	on.call("kennel", 1, "b")
	on.call("kennel", 4, "b")
	_check(is_equal_approx(sim.rarity_bonus(), q0 + 0.35), "the Kennel's quality is off: %.2f from %.2f" % [sim.rarity_bonus(), q0])
	var poison0: float = sim.more("poison")
	on.call("kennel", 3, "b")
	_check(is_equal_approx(sim.more("poison"), poison0 * 1.1), "the Ratter did not add a tenth to poison")
	# salvage: a deep kill on a zone's site drops its kind, home with the run; the buildings move with the Yard
	sim.load_dict(saved)
	_finish_campaign(sim)
	sim.best_depth[3] = 7
	sim.set_depth(3, 8)
	sim.hp = sim.max_hp()
	sim.deploy(3)
	var mm: Dictionary = sim.mission
	_check(int(mm["t"]["depth"]) == 8, "the salvage run is not at depth 8: %d" % int(mm["t"]["depth"]))
	sim.rng.seed = 11
	for k in range(400):
		sim._kill(mm, mm["t"])
	var got: int = int(mm.get("salvage", {}).get("copper", 0))
	_check(got > 0 and mm.get("salvage", {}).size() == 1, "a deep Estate site gave no copper, or the wrong kind: %s" % str(mm.get("salvage", {})))
	var cu0: int = int(sim.salvage["copper"])
	sim.extract_now()
	_check(int(sim.salvage["copper"]) == cu0 + got, "the run's salvage did not come home: %d from %d" % [int(sim.salvage["copper"]), cu0])
	sim.cash = 1000000.0
	sim.notes = 400
	_yard_set(sim, "kennel", 0, "a")
	_yard_set(sim, "stash", 4, "a")
	sim.yard_ranks["kennel"] = 3
	var open_before: int = sim.yard_cols()
	sim.yard_mark_seen()
	_check(sim.can_move_yard() and sim.move_yard(), "the Yard did not move")
	_check(not sim.yard_news(), "the move lit the Upgrade badge with nothing new: %d of %d columns seen" % [sim.yard_seen_cols, sim.yard_cols()])
	_check(sim.yard_has("a_dog") and sim.yard_has("dry_store") and sim.yard_rank("kennel") == 3 and sim.yard_cols() == open_before and sim.notes == 300, "the buildings did not move with the Yard: %s, ranks %s, %d columns, %d notes" % [str(sim.yard_picks), str(sim.yard_ranks), sim.yard_cols(), sim.notes])
	# an old save's levels become the matching picks, free
	var old: Dictionary = sim.to_dict()
	old.erase("yard_picks")
	old.erase("yard_ranks")
	old["stash_level"] = 3
	old["comms_level"] = 2
	old["kennel_level"] = 3
	sim.load_dict(old)
	_check(sim.yard_has("shelving") and sim.yard_has("another_unit") and sim.yard_has("lock_up") and sim.yard_has("weather_set") and sim.yard_has("forecast") and not sim.yard_has("scanner") and sim.yard_has("fetch"), "an old save's levels did not become picks: %s" % str(sim.yard_picks))
	sim.load_dict(saved)
	main.refresh()
	print("the Yard's lanes ok: the screen, a build and a refit, the gates kept, salvage, ranks, every building's picks, the move, the old saves")


## The sum strip's tiles sit inside their panel (7 Oct: the strip was sized by the node tile's height, four
## pixels short, and the tiles' feet were cut off).
func _sum_strip_check(main) -> void:
	var bk = main._barracks
	var inside := Rect2(Vector2.ZERO, bk._sum.size)
	# every chip the trees call for is on the row, and none the trees convert to or increase was dropped to fit -
	# read off the screen before anything re-lays it
	var shown_tags: Array = []
	for k in range(bk._sum_chips.shown()):
		shown_tags.append(bk._sum_chips._tags[k].text)
	var want: Array = bk.sum_items(bk.lane_trees() if bk.alt == "" or not bk._is_pages(bk.alt) else [])
	_check(shown_tags.size() == want.size(), "the sum strip shows %d of its %d chips" % [shown_tags.size(), want.size()])
	_check(not shown_tags.has("Joints") or shown_tags.back() == "Joints", "the Joints chip is not last: %s" % str(shown_tags))
	for el in Data.ELEMENTS:
		if bk.sim.tree_sum("conv_%s_pct" % el) > 0.0 or bk.sim.tree_sum("%s_pct" % el) > 0.0:
			_check(shown_tags.has(el.capitalize()), "the %s the trees give is not on the sum strip: %s" % [el, str(shown_tags)])
	for k in range(bk._sum_chips.shown()):
		var pnl = bk._sum_chips._panels[k]
		var r := Rect2(bk._sum_chips.position + pnl.position, pnl.size)
		_check(inside.encloses(r), "a sum chip runs out of its strip: %s in %s" % [str(r), str(inside)])
	# a node's panel: the figure as a chip beside the title, the sentence under them (Matt, 10 Oct), apart
	if bk.selected != "" and bk._chips.visible:
		var said: String = (bk._words.text + " " + bk._words2.text).strip_edges()
		_check(bk._words.position.y >= bk._chips.position.y + Chips.CHIP_H and bk._words.text != "" and said.ends_with("."), "the node's chip and sentence are off: words at y %.0f, chips to %.0f, '%s'" % [bk._words.position.y, bk._chips.position.y + Chips.CHIP_H, said])
	_check(bk._panel.position.y >= bk.HEAD_H, "the node panel sits on the band")


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
## floor on a site's first clear, its first node of the Yard's tree is free, the lorries and the best dig survive
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
	_set_cls(sim, "Doorman")
	main.show_room(main.BARRACKS)
	main._barracks.selected = ""
	main._barracks._shown = ""
	main.refresh()
	_check(main._barracks._past.text.contains("at depth"), "the wall's line does not name the depth: '%s'" % main._barracks._past.text)
	_check_fit(main, "Caravan (the wall's depth)")
	# the move: the lorries and the best dig come, lorry_done clears, the first yard node is free, the ladders start at the floor
	var lorries0: int = sim.lorries
	var dig0: Dictionary = sim.best_dig.duplicate()
	var points_kept: int = sim.atlas_points        # the map moves with the Yard (part 4)
	sim.xp = maxf(sim.xp, Data.xp_for_level(Data.MAX_LEVEL + 5))
	var paragon_before: int = sim.paragon()        # the paragon is the Yard's: banked by the move (8 Oct)
	_check(sim.can_move_yard() and sim.move_yard(), "the Yard could not move after the lorry")
	_check(sim.yard_moves == 1 and sim.lorries == lorries0 and sim.best_dig == dig0 and not sim.lorry_done, "the move lost the score: moves %d, lorries %d, dig %s, lorry %s" % [sim.yard_moves, sim.lorries, str(sim.best_dig), str(sim.lorry_done)])
	_check(sim.ladder_floor() == 1 and sim.free_yard_nodes() == 1, "the move's floor and free nodes are off: %d / %d" % [sim.ladder_floor(), sim.free_yard_nodes()])
	_check(sim.convoy_depth() == Data.CONVOY_DEPTH + 1 and sim.pinnacle_depth(11) == int(Data.PINNACLE_DEPTH[3]) + 1, "the ending did not climb a depth with the move: lorry %d, barracks' head %d" % [sim.convoy_depth(), sim.pinnacle_depth(11)])
	_check(is_equal_approx(sim.lorry_mult(), pow(Data.LORRY_MULT, sim.lorries)) and sim.lorries >= 1, "the lorry's multiplier is off: %.2f for %d" % [sim.lorry_mult(), sim.lorries])
	_check(sim.paragon_banked == paragon_before and sim.paragon() == paragon_before and sim.level() == 1, "the move did not bank the paragon: banked %d of %d, runner level %d" % [sim.paragon_banked, paragon_before, sim.level()])
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
	_set_cls(sim, "Doorman")
	var t0: Dictionary = sim.effective(0)
	sim.deploy(0)                                # a moved yard starts at the Outskirts (12 Oct)
	sim._clear(sim.mission, t0)
	sim.extract_now()
	_check(sim.best_depth[0] == 1 and sim.atlas_points == points_kept, "the first clear on a moved yard is off: best %d, points %d of %d kept" % [sim.best_depth[3], sim.atlas_points, points_kept])
	_check(sim.events.any(func(e): return str(e[1]).contains("ladders start at depth 2")), "the ladder's floor was not said")
	# the floor opens the depth without faking the clear: depth 2 opens on the streets, depth 3 does not; the wall reads depth 1
	_finish_campaign(sim)
	sim.set_depth(3, 3)
	_check(sim.depth[3] == 2 and sim.best_depth[3] == 1, "the floor did not open depth 2 alone: depth %d, best %d" % [sim.depth[3], sim.best_depth[3]])
	_check(sim._deepest_held()[1] == 1, "the wall counts the floor as held: %s" % str(sim._deepest_held()))
	sim.set_depth(3, 1)
	# saved and loaded
	var d: Dictionary = sim.to_dict()
	var fresh = Sim.new()
	fresh.start()
	fresh.load_dict(d)
	_check(fresh.lorries == lorries0 and fresh.best_dig == dig0 and fresh.yard_moves == 1, "the score did not survive a save")
	sim.load_dict(before)


## A site's level (the endgame, 7 Oct): tier plus depth drives the curve, the bases and the item level, so the
## streets' ladder is gentle and long and the Barracks' steep and short; the Runs card says the level.
## The deep bases (10 Oct, docs/design/deep_guns.md): tiers 7-9 from level 12, 16 and 20, on every slot a runner
## wears; a campaign site's "a tier up" never reaches them; every deep base has its words and a footprint that fits.
func _deep_tier_checks(main) -> void:
	var sim = main.sim
	_check(sim.loot_tier_at(11) == 6 and sim.loot_tier_at(12) == 7 and sim.loot_tier_at(15) == 7 and sim.loot_tier_at(16) == 8 and sim.loot_tier_at(20) == 9,
		"the deep tiers by level are off: %d %d %d %d" % [sim.loot_tier_at(11), sim.loot_tier_at(12), sim.loot_tier_at(16), sim.loot_tier_at(20)])
	_check(sim.loot_cap(9) == Data.CAMPAIGN_TIER and sim.loot_cap(12) == Data.MAX_TIER, "a campaign site's tier up reaches the deep bases")
	for slot in ["Primary", "Secondary", "Helmet", "Armour", "Rig", "Backpack", "Charm"]:
		for tier in [7, 8, 9]:
			var n := 0
			for b in Data.BASES[slot]:
				if int(b["tier"]) == tier:
					n += 1
					_check(Words.ITEMS.has(b["name"]), "the deep base %s has no words" % b["name"])
					var f: Vector2i = Items.footprint({"slot": slot, "base": b["name"]})
					_check(f.x <= 5 and f.y <= 4, "the deep base %s does not fit a cell grid" % b["name"])
			_check(n > 0, "no %s base at tier %d" % [slot, tier])
		var deep_rng := RandomNumberGenerator.new()
		deep_rng.seed = 7
		var seen_deep := false
		for k in range(400):
			var it: Dictionary = Items.roll(slot, Data.CAMPAIGN_TIER, deep_rng)
			_check(int(it["tier"]) <= Data.CAMPAIGN_TIER, "a campaign roll gave a deep %s" % it["base"])
			var deep: Dictionary = Items.roll(slot, Data.MAX_TIER, deep_rng)
			seen_deep = seen_deep or int(deep["tier"]) > Data.CAMPAIGN_TIER
		_check(seen_deep, "a tier-9 roll never gave a deep %s" % slot)
	for t in Data.TIERS:
		_check(int(t["loot_tier"]) <= Data.CAMPAIGN_TIER, "the campaign's %s drops a deep tier" % t["name"])
	# the Workshop's gun builds: a deep improvised base only once a site drops its tier (the review, 10 Oct)
	var hold_bd: Array = sim.best_depth.duplicate()
	for i in range(sim.best_depth.size()):
		sim.best_depth[i] = 1
	var top_build := 0
	for e in sim.build_options("gun"):
		top_build = maxi(top_build, int(e["tier"]))
	_check(top_build == Data.CAMPAIGN_TIER, "the campaign's gun builds reach T%d" % top_build)
	for i in range(sim.best_depth.size()):
		sim.best_depth[i] = 20
	top_build = 0
	for e in sim.build_options("gun"):
		top_build = maxi(top_build, int(e["tier"]))
	_check(top_build == Data.MAX_TIER, "the deep gun builds stop at T%d at depth 20" % top_build)
	sim.best_depth = hold_bd
	# a shop's unique or set piece carries its own base's level, not a deep throwaway's
	var u_rng := RandomNumberGenerator.new()
	u_rng.seed = 11
	for k in range(60):
		var u: Dictionary = Data.UNIQUES[k % Data.UNIQUES.size()]
		var it: Dictionary = Items.roll_unique(u, u_rng)
		_check(Items.ilvl(it) <= Items.unique_tier(u, int(Items.base_named(u["slot"], u["base"])["tier"])), "%s rolled at level %d over its base's tier, held in its range" % [u["name"], Items.ilvl(it)])
	# each gun line climbs: every deep tier beats the line's best below it
	for slot in ["Primary", "Secondary"]:
		var best := {}
		for b in Data.BASES[slot]:
			if b.has("rof"):
				var k := "%s/%d" % [str(b.get("type", "")), int(b["tier"])]
				best[k] = maxf(float(best.get(k, 0.0)), float(b["damage"]) * float(b["rof"]))
		for k in best.keys():
			var bits: PackedStringArray = k.split("/")
			var tier := int(bits[1])
			if tier >= 7:
				var below := 0.0
				for k2 in best.keys():
					var b2: PackedStringArray = k2.split("/")
					if b2[0] == bits[0] and int(b2[1]) < tier:
						below = maxf(below, float(best[k2]))
				_check(float(best[k]) > below, "the deep %s at T%d (%.0f) doesn't beat its line below (%.0f)" % [bits[0], tier, float(best[k]), below])


func _site_level_checks(main) -> void:
	var sim = main.sim
	var hold_depth: Array = sim.depth.duplicate()
	var hold_best: Array = sim.best_depth.duplicate()
	for i in range(Data.TIERS.size()):
		sim.best_depth[i] = 20
	_check(sim.loot_tier_at(1) == 1 and sim.loot_tier_at(8) == 5 and sim.loot_tier_at(9) == Data.CAMPAIGN_TIER and sim.loot_tier_at(30) == Data.MAX_TIER, "the gear tier by level is off: %d %d %d" % [sim.loot_tier_at(1), sim.loot_tier_at(8), sim.loot_tier_at(9)])
	_deep_tier_checks(main)
	sim.set_depth(3, 8)
	sim.set_depth(11, 2)
	var hold_intel: Array = [sim.words[3].duplicate(true), sim.words[11].duplicate(true)]
	sim.words[3] = []                     # the plain sites: a word on the air can add a gear tier
	sim.words[11] = []
	var streets: Dictionary = sim.effective(3)
	var barracks: Dictionary = sim.effective(11)
	_check(int(streets["level"]) == 8 and int(barracks["level"]) == 10 and sim.site_level(3) == 8, "the sites' levels are off: %d / %d" % [int(streets["level"]), int(barracks["level"])])
	_check(float(barracks["hp"]) > float(streets["hp"]) and float(barracks["dps"]) > float(streets["dps"]), "the Barracks at depth 2 is no harder than the streets at depth 8: %.0f vs %.0f HP" % [float(barracks["hp"]), float(streets["hp"])])
	_check(int(streets["loot_tier"]) == 5 and int(barracks["loot_tier"]) == Data.CAMPAIGN_TIER, "the bases by level are off: streets tier %d, barracks tier %d" % [int(streets["loot_tier"]), int(barracks["loot_tier"])])
	# a find carries the site's level
	var f0: Dictionary = Items.roll("Primary", int(streets["loot_tier"]), sim.rng, 0.0, false, false, "", "", 0.33, 8, int(streets["level"]))
	var f8: Dictionary = Items.roll("Primary", int(barracks["loot_tier"]), sim.rng, 0.0, false, false, "", "", 0.33, 2, int(barracks["level"]))
	_check(int(f0["ilvl"]) == 8 and int(f8["ilvl"]) == 10, "a find's item level is not the site's: %d / %d" % [int(f0["ilvl"]), int(f8["ilvl"])])
	# never under the site's own campaign curve: the Barracks at depth 2 keeps the campaign's climb
	var camp_d2: float = float(Data.TIERS[11]["hp"]) * (1.0 + Data.DEPTH_HOSTILE)
	_check(float(barracks["hp"]) >= camp_d2 - 0.01, "the Barracks at depth 2 fell under its campaign curve: %.0f < %.0f" % [float(barracks["hp"]), camp_d2])
	# the Runs card says it: the level on the kicker, the finds' level on a tile, the stations on the note
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(1)
	main._missions._shown = ""
	main.refresh()
	var c0: Dictionary = main._missions._cols[0]
	_check(c0["band"].kicker.text.ends_with("level 8"), "the streets' kicker does not say its level: '%s'" % c0["band"].kicker.text)
	var finds := -1
	for r in range(6):
		if c0["tiles"][r]["key"].text == "Finds":
			finds = r
	_check(finds >= 0 and c0["tiles"][finds]["value"].text.begins_with("level 8"), "the streets' Finds tile is off: %s" % (c0["tiles"][finds]["value"].text if finds >= 0 else "no Finds tile"))
	main._missions._pick_zone(3)
	main._missions._shown = ""
	main.refresh()
	var c6: Dictionary = main._missions._cols[0]       # the Services, the city's first
	_check(c6["note"].text.contains("the lorry") or sim.hp < sim.max_hp() * 0.5, "the Services' card does not name the lorry: '%s'" % c6["note"].text)
	_check_fit(main, "Runs (levels)")
	main._missions._pick_zone(1)
	_site_unique_checks(main)
	_smg_line_checks(main)
	_growth_checks(main)
	sim.words[3] = hold_intel[0]
	sim.words[11] = hold_intel[1]
	sim.depth = hold_depth
	sim.best_depth = hold_best
	sim._surv_cache = {}


## What grows without end (7 Oct): paragon levels past the cap on the same curve, the lorries' multiplier, and an affix's
## value by item level - so the second leg reaches further than the first and a deep drop beats a shallow one.
func _growth_checks(main) -> void:
	var sim = main.sim
	var hold: Dictionary = sim.to_dict()
	sim.lorries = 0
	sim.hp = 1e12                          # never under half: the under-half damage would ride on the growth (10 Oct)
	sim.xp = Data.xp_for_level(Data.MAX_LEVEL)
	var hp50: float = sim.max_hp()
	var dps50: float = sim.dps()
	_check(sim.level() == Data.MAX_LEVEL and sim.paragon() == 0 and is_equal_approx(sim.growth_mult(), 1.0), "at the cap the growth reads %.2f with %d paragon" % [sim.growth_mult(), sim.paragon()])
	sim.xp = Data.xp_for_level(Data.MAX_LEVEL + 10)
	_check(sim.level() == Data.MAX_LEVEL and sim.paragon() == 10, "ten levels past the cap read level %d, paragon %d" % [sim.level(), sim.paragon()])
	_check(is_equal_approx(sim.max_hp() / hp50, 1.0 + Data.PARAGON_PCT * 10.0 / 100.0) and is_equal_approx(sim.dps() / dps50, 1.0 + Data.PARAGON_PCT * 10.0 / 100.0), "ten paragon levels did not pay: hp ×%.2f dps ×%.2f" % [sim.max_hp() / hp50, sim.dps() / dps50])
	_check(Data.xp_for_level(Data.MAX_LEVEL + 11) > Data.xp_for_level(Data.MAX_LEVEL + 10) and Data.xp_for_level(Data.MAX_LEVEL + 10) > Data.xp_for_level(Data.MAX_LEVEL), "the XP curve stops at the cap")
	main.refresh()
	_check(main._top_labels["level"].text == "%d +10" % Data.MAX_LEVEL and main._top_labels["xp"].text.contains(" / "), "the top bar does not say the paragon: '%s' / '%s'" % [main._top_labels["level"].text, main._top_labels["xp"].text])   # the figure with LEVEL beside it since the sheet (8 Oct)
	_check_fit(main, "Top bar (paragon)")
	sim.xp = Data.xp_for_level(Data.MAX_LEVEL)
	sim.lorries = 3
	_check(is_equal_approx(sim.max_hp() / hp50, pow(Data.LORRY_MULT, 3)) and is_equal_approx(sim.dps() / dps50, pow(Data.LORRY_MULT, 3)), "three lorries did not multiply the Yard: hp ×%.2f" % (sim.max_hp() / hp50))
	# an affix's value by item level: nothing to ILVL_FROM, a fifth more at five past, the same tier
	var a := {"stat": "hp", "min": 10, "max": 50}
	var at15 := Items.roll_affix(a, Data.ILVL_FROM, sim.rng, 5)
	var at25 := Items.roll_affix(a, Data.ILVL_FROM + 10, sim.rng, 5)
	_check(int(at15["value"]) <= 50 and int(at25["value"]) >= int(round(Items.tier_range(a, 5)[0] * Items.ilvl_mult(Data.ILVL_FROM + 10))) and int(at25["tier"]) == 5, "the deep affix did not grow: %d at %d, %d at %d" % [int(at15["value"]), Data.ILVL_FROM, int(at25["value"]), Data.ILVL_FROM + 10])
	_check(is_equal_approx(Items.ilvl_mult(Data.ILVL_FROM + 10), 1.0 + Data.ILVL_SCALE * 10.0) and is_equal_approx(Items.ilvl_mult(5), 1.0), "the item level's multiplier is off")
	var u_shallow: Dictionary = Items.roll_unique(sim._unique_named("Lucky Cap"), sim.rng, 5)
	var u_deep: Dictionary = Items.roll_unique(sim._unique_named("Lucky Cap"), sim.rng, Data.ILVL_FROM + 20)
	_check(Items.ilvl(u_deep) == Data.ILVL_FROM + 20 and int(u_deep["affixes"][0]["value"]) == int(round(20 * Items.ilvl_mult(Data.ILVL_FROM + 20))) and int(u_shallow["affixes"][0]["value"]) == 20, "a unique found deep does not carry the depth: %d / %d" % [int(u_shallow["affixes"][0]["value"]), int(u_deep["affixes"][0]["value"])])
	# the find carries the site's level into a unique
	sim.best_depth[11] = 30
	sim.set_depth(11, 25)
	var t: Dictionary = sim.effective(11)
	var found: Dictionary = Items.roll_unique(sim.site_unique(11), sim.rng, int(t["level"]))
	_check(Items.ilvl(found) == 33, "the Barracks at depth 25 did not give a level-33 unique: %d" % Items.ilvl(found))
	sim.load_dict(hold)
	print("the growth ok: paragon, the lorries, the deep affix")


## The SMG line (7 Oct): a gun a tier from T2 to T6, two at T6, the top over the shotguns'; every SMG primary
## carries walking fire, read in the fight's stream and said on the panel's tail.
func _smg_line_checks(main) -> void:
	var sim = main.sim
	var smgs: Array = []
	for b in Data.BASES["Primary"]:
		if b.get("type", "") == "smg" and int(b["tier"]) <= Data.CAMPAIGN_TIER:     # the campaign's line; the deep bases are their own checks
			smgs.append(b)
	var tiers: Array = smgs.map(func(b): return int(b["tier"]))
	for t in range(2, 7):
		_check(t in tiers, "the SMG line has no T%d" % t)
	_check(tiers.count(6) == 2 and smgs.size() == 9, "the SMG line is %d guns with %d at T6" % [smgs.size(), tiers.count(6)])
	var top_smg := 0.0
	var top_other := 0.0
	for b in Data.BASES["Primary"]:
		if not b.has("rof") or int(b["tier"]) > Data.CAMPAIGN_TIER:
			continue
		var dps: float = float(b["damage"]) * float(b["rof"])
		if b.get("type", "") == "smg":
			top_smg = maxf(top_smg, dps)
		elif int(b["tier"]) == 6:
			top_other = maxf(top_other, dps)
	_check(top_smg > top_other and top_smg < top_other * 1.15, "the SMG top is %.0f against the others' %.0f: a shade over was the aim" % [top_smg, top_other])
	for b in smgs:
		_check(b.has("sustain"), "%s has no walking fire" % b["name"])
		_check(Words.item_words(b["name"]) != "", "%s has no words" % b["name"])
	# walking fire in the stream: nothing at the gang's first tick, the cap after ten seconds, reset by the next gang
	var hold = sim.equipped["Primary"]
	sim.equipped["Primary"] = sim._plain("Primary", "Riot squad's SMG")
	var m := {"sustain_t": 0.0}
	_check(is_equal_approx(sim.sustain_mult(m), 1.0), "walking fire starts above nothing")
	m["sustain_t"] = 5.0
	_check(is_equal_approx(sim.sustain_mult(m), 1.2), "walking fire at five seconds reads %.2f, not 1.20" % sim.sustain_mult(m))
	m["sustain_t"] = 30.0
	_check(is_equal_approx(sim.sustain_mult(m), 1.4), "walking fire did not cap at +40%%: %.2f" % sim.sustain_mult(m))
	sim.equipped["Primary"] = sim._plain("Primary", "Riot squad's shotgun")
	_check(is_equal_approx(sim.sustain_mult(m), 1.0), "a shotgun walks its fire")
	sim.equipped["Primary"] = hold
	# the panel's tail says it
	var gun: Dictionary = sim._plain("Primary", "Courier's SMG")
	_check(Items.base_res_words(gun).contains("walking fire +4%/s to +40%"), "the SMG's tail does not say walking fire: '%s'" % Items.base_res_words(gun))
	print("the SMG line ok: nine guns, walking fire")


## A site's own unique (endgame part 3): never loose, gated by zone (the streets at 12, the Barracks at 6),
## found on its site past the gate and nowhere shallower; the Runs card names it until it is on the shelf.
func _site_unique_checks(main) -> void:
	var sim = main.sim
	for u in sim.loose_uniques(99):
		_check(not u.has("site"), "%s is a site's own and loose" % u["name"])
	_check(sim.site_unique_depth(3) == 12 and sim.site_unique_depth(7) == 9 and sim.site_unique_depth(11) == 6, "the sites' own depths are off: %d %d %d" % [sim.site_unique_depth(3), sim.site_unique_depth(7), sim.site_unique_depth(11)])
	_check(sim.site_unique(11)["name"] == "The Quartermaster's Manual" and sim.site_unique(3)["name"] == "The Gritter's Hopper", "the sites' own are off")
	var hold_shelf: Array = sim.shelf.duplicate()
	var hold_stash: Array = sim.stash.duplicate()
	sim.shelf = []
	# the Barracks at depth 5: never; at depth 6: within a few hundred finds
	var own := 0
	for d in [5, 6]:
		own = 0
		sim.set_depth(11, d)
		sim.deploy(11)
		var m: Dictionary = sim.mission
		var eff: Dictionary = sim.effective(11)
		for k in range(400):
			m["found"] = []
			sim._find(m, eff)
			if not m["found"].is_empty() and m["found"][0].get("unique", "") == "The Quartermaster's Manual":
				own += 1
		sim.extract_now()
		if d == 5:
			_check(own == 0, "the Barracks' own dropped at depth 5")
		else:
			_check(own > 0 and own < 60, "the Barracks' own is %d of 400 finds at depth 6; 3%% was the aim" % own)
	# the Runs card names it until it is found
	sim.shelf = []
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(3)
	main._missions._shown = ""
	main.refresh()
	var c8: Dictionary = main._missions._cols[2]
	_check(main._missions._station_words(11).contains("Depth 6: its own, The Quartermaster's Manual"), "the Barracks' station words do not name its own: '%s'" % main._missions._station_words(11))
	_check(c8["note"].text != "" or sim.hp < sim.max_hp() * 0.5, "the Barracks' note is empty with its own unfound")
	_check_fit(main, "Runs (a site's own)")
	sim.shelf = ["The Quartermaster's Manual"]
	_check(not main._missions._station_words(11).contains("its own"), "the Barracks' station words still name its own once found")
	# the Fence's gamble never hands out the chase
	var chase_names: Array = []
	for c in sim.shelf_chase():
		chase_names.append(c["name"])
	var leaked := ""
	for k in range(300):
		var g: Dictionary = sim.roll_gamble({"slot": "Charm", "type": ""}, 0.0)
		if g.get("unique", "") in chase_names:
			leaked = g["unique"]
	_check(leaked == "", "the gamble handed out the chase: %s" % leaked)
	main._missions._pick_zone(1)
	sim.shelf = hold_shelf
	sim.stash = hold_stash


## The map at thirty-six (endgame part 4, 7 Oct): the new nodes' effects, each read through the sim.
func _map_nodes_checks(main) -> void:
	var sim = main.sim
	var hold: Dictionary = sim.to_dict()
	sim.atlas = {}
	sim.atlas_points = 100
	sim.words[3] = []
	var take := func(keys: Array):
		for k in keys:
			_check(sim.rank_atlas(k), "%s did not take" % k)
	sim.set_depth(3, 2)
	var e0: Dictionary = sim.effective(3)
	# the sites' column, down the chain
	take.call(["picked_over", "deeper_pockets", "quiet_roads", "after_dark"])
	var e1: Dictionary = sim.effective(3)
	_check("Night" in e1["intel"] and float(e1["rarity"]) - float(e0["rarity"]) >= 0.5 * 1.5 - 0.001, "After dark did not make the run a night run with the dark's half again: %.2f" % (float(e1["rarity"]) - float(e0["rarity"])))
	take.call(["second_look", "second_look", "worn_in", "worn_in"])
	_check(is_equal_approx(sim.recover_s(), Data.RECOVER_H * 3600.0 / 2.0), "Worn in did not halve the recovery: %.0f" % sim.recover_s())
	take.call(["easy_pickings", "easy_pickings", "local_knowledge", "short_cuts", "short_cuts", "open_ground", "every_penny", "every_penny"])
	var e2: Dictionary = sim.effective(3)
	_check(is_equal_approx(float(e2["drop"]) / float(e1["drop"]), 1.2), "Easy pickings is off: %.2f" % (float(e2["drop"]) / float(e1["drop"])))
	_check(int(e2["loot_tier"]) == int(e1["loot_tier"]) + 1, "Local knowledge did not add a gear tier")
	_check(is_equal_approx(float(e2["pace"]) / float(e1["pace"]), 1.1), "Short cuts is off")
	_check(int(e2["contact"]) == int(e1["contact"]) - 1, "Open ground did not take one off")
	_check(is_equal_approx(float(e2["cash"]) / float(e1["cash"]), 1.2), "Every penny is off")
	var best0: int = sim.best_depth[3]
	sim.best_depth[3] = 3
	sim.set_depth(3, 6)
	_check(sim.depth[3] == 4, "without the keystone the ladder opened past the deepest plus one: %d" % sim.depth[3])
	take.call(["lie_of_the_land"])
	sim.set_depth(3, 6)
	_check(sim.depth[3] == 5, "The lie of the land did not open one past: %d" % sim.depth[3])
	sim.set_depth(3, 2)
	sim.best_depth[3] = best0
	# the crews' column
	take.call(["paid_in_notes", "two_of_everything", "heads_up", "heads_up"])
	sim.boss_paid[5] = []                 # the runs above paid him: Long memory reads from here
	sim.bosses_beaten[1] = true
	sim.set_depth(5, 3)
	var full: int = int(sim.boss_of(5)["notes"]) * 3
	_check(sim.boss_cost(5) == int(round(full / 3.0)), "Heads up is off: %d of %d" % [sim.boss_cost(5), full])
	_check(sim.pinnacle_depth(11) == int(Data.PINNACLE_DEPTH[3]), "the pinnacle moved before Full strength")
	take.call(["full_strength"])
	_check(sim.pinnacle_depth(11) == int(Data.PINNACLE_DEPTH[3]) - 2, "Full strength did not bring the pinnacle two sooner")
	take.call(["bounties", "bounties", "wages", "wages", "wages", "heavy_crews"])
	var e3: Dictionary = sim.effective(3)
	_check(is_equal_approx(float(e3["xp"]) / float(e2["xp"]), 1.3 * 1.5) and is_equal_approx(float(e3["cash"]) / float(e2["cash"]), 1.5) and int(e3["contact"]) == int(e2["contact"]) + 1, "Wages and Heavy crews are off")
	take.call(["their_own_kit", "their_own_kit", "marked_men", "long_memory"])
	sim.notes += 10000
	sim.arm_boss(5, true)
	sim.deploy(5)
	var paid_at: Array = sim.boss_paid[5].duplicate()
	sim.extract_now()
	_check(paid_at == [3] and sim.boss_cost(5) == 0, "Long memory did not make the next run at that depth free: %d, %s" % [sim.boss_cost(5), str(paid_at)])
	sim.set_depth(5, 2)
	_check(sim.boss_cost(5) > 0, "Long memory made another depth free")
	sim.arm_boss(5, true)
	sim.deploy(5)
	sim.extract_now()
	_check(sim.boss_paid[5] == [3, 2] and sim.boss_cost(5) == 0, "Long memory forgot a depth: %s" % str(sim.boss_paid[5]))
	sim.set_depth(5, 3)
	_check(sim.boss_cost(5) == 0, "Long memory forgot the first depth paid")
	take.call(["head_start"])
	var pts: int = sim.atlas_points
	sim.deploy(5)
	var m: Dictionary = sim.mission
	m["boss"] = {"name": sim.boss_of(5)["name"], "zone": 0, "alive": true, "hp": 1.0, "started": true, "pinnacle": true}
	sim._boss_down(m, sim.effective(5))
	sim.extract_now()
	_check(sim.atlas_points == pts + 1, "Head start did not pay a point for a head at full strength")
	_check(int(m.get("notes", 0)) >= Data.NOTES_BOSS * 3 * 2, "Bounties did not double the head's notes: %d" % int(m.get("notes", 0)))
	_check(sim.convoy_depth() == Data.CONVOY_DEPTH, "the lorry moved before its route")
	take.call(["lorrys_route"])
	_check(sim.convoy_depth() == Data.CONVOY_DEPTH - 2, "The lorry's route did not bring the lorry two sooner")
	# the air (9 Oct): the juicing lane, each read through the sim on the streets at depth 2
	sim.yard_picks.erase("radio")              # the Radio's Scanner and band read alone elsewhere
	sim.yard_ranks = {}
	sim._yard_changed("")
	sim.words[3] = []
	sim.sealed[3] = false
	sim.notes += 100000
	var rc0: int = sim.word_craft_cost(3, "retune")
	take.call(["good_reception", "good_reception"])
	_check(sim.word_craft_cost(3, "retune") == maxi(1, int(ceil(rc0 * 0.7 - 0.0001))), "Good reception is off: %d of %d" % [sim.word_craft_cost(3, "retune"), rc0])
	_check(not sim.atlas_open("long_wave"), "the air's third column opened at two points")
	take.call(["clear_air"])
	_check(sim.set_filtered("Numbers") and sim.filtered == "Numbers", "Clear air did not take a filter")
	var heard := false
	for k in range(40):
		heard = heard or sim._roll_words(3, [], 2).any(func(wd): return wd["w"] == "Numbers")
	_check(not heard, "Clear air's word was still heard")
	take.call(["booster", "booster", "booster"])
	_check(is_equal_approx(float(sim.word_effect("Numbers", 1)["drop"]), 1.0 + 0.3 * 1.3), "Booster is off: %s" % str(sim.word_effect("Numbers", 1)))
	var mw2: int = sim.max_words(3)
	var er0: Dictionary = sim.effective(3)
	take.call(["long_wave", "tip_offs", "tip_offs"])
	_check(sim.max_words(3) == mw2 + 1 and mw2 == 2, "Long wave did not add a word at depth 2: %d from %d" % [sim.max_words(3), mw2])
	_check(is_equal_approx(float(sim.effective(3)["rarity"]) - float(er0["rarity"]), 0.1), "Tip-offs is off")
	take.call(["strong_signal", "strong_signal"])
	var twos := 0
	for k in range(40):
		twos += 1 if sim._roll_tier(3) == 2 else 0
	_check(twos > 10 and sim.word_tier_now(3, 2) == 2, "Strong signal did not land tier II at depth 2: %d of 40" % twos)
	var call0: int = sim.word_craft_cost(3, "call")
	take.call(["early_word", "early_word", "held_frequency"])
	_check(sim.word_craft_cost(3, "call") == maxi(1, int(ceil(float(call0) * 0.5 - 0.6))) or absi(sim.word_craft_cost(3, "call") - int(ceil(call0 * 0.5))) <= 1, "Early word is off: %d of %d" % [sim.word_craft_cost(3, "call"), call0])
	take.call(["relay"])
	_check(sim.set_standing(0, "Tooled up") and "Tooled up" in sim.effective(3)["intel"] and sim.active_words(3).size() == 1, "the Relay's standing word is not on the site: %s" % str(sim.active_words(3)))
	_check(not sim.set_standing(1, "Ex-army"), "a second standing word without the whole band")
	take.call(["bent", "whole_band"])
	_check(sim.set_standing(1, "Ex-army") and sim.active_words(3).size() == 2, "the whole band's second word is not on the site: %s" % str(sim.active_words(3)))
	sim.words[3] = [{"w": "Bailiffs", "t": 1}]
	_check(sim.active_words(3).size() == 3, "a site's own word and the two standing ones do not all work: %s" % str(sim.active_words(3)))
	var ranks := 0
	for a in Data.ATLAS:
		ranks += int(a["max"])
	_check(ranks == 59 and sim.atlas_free() == 100 + 1 - sim.atlas_spent(), "the map's ranks do not add to fifty-nine: %d, %d free" % [ranks, sim.atlas_free()])
	var spent: int = sim.atlas_spent()
	_open_map(main)
	main._radio._atlas._shown = ""
	main.refresh()
	_check_fit(main, "Radio (the map, full)")
	main._radio._pick_view("air")
	# a site's words hold through the move (Held frequency), the standing words and the rest of the map with it
	sim.words[4] = [{"w": "Delivery day", "t": 1}]
	if sim.can_move_yard():
		sim.move_yard()
		_check(sim.words[3] == [{"w": "Bailiffs", "t": 1}] and sim.words[4] == [{"w": "Delivery day", "t": 1}] and sim.standing == ["Tooled up", "Ex-army"] and sim.filtered == "Numbers", "Held frequency did not hold the words through the move: %s / %s" % [str(sim.words[3]), str(sim.standing)])
		_check(sim.atlas_rank("whole_band") == 1 and sim.atlas_spent() == spent, "the map did not move with the Yard: %d spent" % sim.atlas_spent())
	else:
		_check(false, "the map checks could not move the Yard to read Held frequency")
	sim.load_dict(hold)


## The map in the Caravan's shape (Map-A, 7 Oct): the tiles in three columns, the pips as the ranks, the taken
## tiles lined, the sum strip, and the panel filled by a pick with a rank taken through it.
func _map_screen_checks(main) -> void:
	var sim = main.sim
	var at = main._radio._atlas
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
		_check(pips.size() == (int(a["max"]) if int(a["max"]) > 1 else 0), "%s has %d pips for %d ranks" % [key, pips.size(), int(a["max"])])
		# the glyphs (10 Oct, Lanes-G): a glyph on every node, a one-rank node round, its pips under it and on no tile
		_check(at._tiles[key]["glyph"].texture != null and NodeGlyphs.ATLAS_GLYPH.has(key), "the %s node has no glyph of its own" % key)
		var sb0: StyleBoxFlat = b.get_theme_stylebox("normal")
		var notable: bool = a.get("notable", false) and not a.get("keystone", false)
		_check(notable == (sb0.corner_radius_top_left >= int(b.size.x / 2.0) - 1), "the %s node's roundness does not follow its being notable" % key)
		_check(a.get("keystone", false) == is_equal_approx(b.rotation_degrees, 45.0), "the %s node's diamond does not follow its being the keystone" % key)
		var lane_y: float = at.LANES_Y + int(a["column"]) * (at.LANE_H + at.LANE_GAP)
		var reach: float = b.size.x * 0.21 if a.get("keystone", false) else 0.0       # a turned square reaches past its box
		_check(r.position.y - reach >= lane_y and r.end.y + reach <= lane_y + at.LANE_H, "the %s node leaves its lane" % key)
		for p in pips:
			var pr := Rect2(p.position, p.size)
			_check(pr.position.y >= r.end.y and pr.end.y <= lane_y + at.LANE_H and pr.position.x >= r.position.x - 1.0 and pr.end.x <= r.end.x + 1.0, "the %s node's pips are not under it in its lane" % key)
		var lit := 0
		for p in pips:
			if (p.get_theme_stylebox("panel") as StyleBoxFlat).bg_color == Pal.ACCENT:
				lit += 1
		if pips.is_empty():
			_check((sim.atlas_rank(key) > 0) == (at._tiles[key].get("look", "") == "taken"), "%s (one rank) does not read taken by its fill: rank %d, %s" % [key, sim.atlas_rank(key), at._tiles[key].get("look", "")])
		else:
			_check(lit == sim.atlas_rank(key), "%s shows %d pips lit for rank %d" % [key, lit, sim.atlas_rank(key)])
	var taken := 0
	for key in sim.atlas:
		if sim.atlas_rank(key) > 0:
			taken += 1
	_check(at._sum_chips.shown() == mini(taken, at.SUM_CHIPS) + (1 if taken > at.SUM_CHIPS else 0), "the map's sum strip shows %d chips for %d taken" % [at._sum_chips.shown(), taken])
	# the columns: twelve a column, the keystone the width and last, a locked tile dim and its panel saying what it needs
	for c in range(3):
		var n := 0
		var last := {}
		for a in Data.ATLAS:
			if int(a["column"]) == c:
				n += 1
				last = a
		_check((n == 12 or (c == 2 and n == 11)) and last.get("keystone", false), "lane %d is not its nodes ending in a keystone" % c)
		var kb: Button = at._tiles[last["key"]]["button"]
		_check(is_equal_approx(kb.rotation_degrees, 45.0), "the lane's keystone is not a diamond")
		_check(kb.position.x > at.TILES_X + 4 * at.TILE_W, "the keystone is not in the lane's last column")
	at._pick("lie_of_the_land")
	_check((at._title.text.contains("opens at 14 points in the sites") or sim.atlas_open("lie_of_the_land")) and (at._take.disabled or sim.atlas_open("lie_of_the_land")), "a shut node's panel does not say what opens it: '%s'" % at._title.text)
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


## The rail (9 Oct, Matt's order and names): the loadout is Runner, the sheet is Stats, the Bench is the Workshop.
func _rail_order_checks(main) -> void:
	var want := ["The Yard", "Stats", "Runner", "Runs", "Training", "Workshop", "Clinic", "The Fence", "Radio"]
	_check(main.ROOMS == want, "the rail's rooms are %s" % str(main.ROOMS))
	var ys := []
	for name in want:
		var b = main._rail_buttons[name]
		ys.append(b.position.y)
		_check(b._name.text == name, "the rail's %s row reads '%s'" % [name, b._name.text])
	for k in range(1, ys.size()):
		_check(ys[k] > ys[k - 1], "the rail's %s row is not under %s" % [want[k], want[k - 1]])
	main.show_room(main.ARMOURY)
	main.refresh()
	_check(main._armoury.visible and main.ARMOURY == "Runner", "Runner does not open the loadout")
	main.show_room(main.RUNNER)
	main.refresh()
	_check(main.RUNNER == "Stats" and main._stats.visible and not main._grid.visible, "Stats does not open the runner's sheet")
	_check(main._rail_buttons["Workshop"]._glyph.texture != null and main._rail_buttons["Runner"]._glyph.texture != null, "Workshop or Runner lost its glyph")


## Place art (9 Oct): a painted site shows in its band, a painted zone behind its tab; none painted, the skyline.
func _place_art_checks(main) -> void:
	var sim = main.sim
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(1)
	main._missions._shown = ""
	main.refresh()
	var band = main._missions._cols[0]["band"]
	var site: String = Data.TIERS[Data.ZONES[1]["tiers"][0]]["name"]
	_check(band.has_art() == (UI.place_texture(site) != null), "the site band's art does not follow art/places/%s.png" % UI.place_slug(site))
	var img := Image.create(64, 21, false, Image.FORMAT_RGBA8)
	img.fill(Color("8899aa"))
	var tex := ImageTexture.create_from_image(img)
	var had_site = UI._places.get(UI.place_slug(site), null)
	UI._places[UI.place_slug(site)] = tex
	band._seed = 0
	band.set_site(site)
	_check(band.has_art() and band._art.texture == tex and band._art_fade.visible, "a painted site does not show in its band")
	_check(band.get_child(0) == band._art and band._art.get_index() < band.title.get_index(), "the site art sits over the band's words")
	main._missions._shown = ""
	main.refresh()
	_check_fit(main, "Runs (site art)")
	var zart: TextureRect = main._missions._zone_art[0]
	var had_zone = zart.texture
	zart.texture = tex
	zart.visible = true
	main._missions._shown = ""
	main.refresh()
	var zb: Button = main._missions._zone_buttons[0]
	_check(zart.get_index() < zb.get_index() and zb.get_theme_stylebox("normal").bg_color.a < 0.5 and zb.get_theme_color("font_color") == Pal.TEXT, "the zone tab does not show its art under a glass")
	_check_fit(main, "Runs (zone art)")
	zart.texture = had_zone
	zart.visible = had_zone != null
	if had_site == null:
		UI._places.erase(UI.place_slug(site))
	else:
		UI._places[UI.place_slug(site)] = had_site
	band._seed = 0
	band.set_site(site)
	main._missions._shown = ""
	main.refresh()
	_check(zb.get_theme_constant("outline_size") == 0 or zart.visible, "a tab without art keeps the art tab's outline")
	# the Clinic's and the Fence's bands read their own places (art/places/the_clinic.png, the_fence.png), the Map's its own
	_check(main._fence._band._seed == hash("The Fence") and main._clinic._band._seed == hash("The Clinic"), "the Fence's or the Clinic's band does not name its place for its art")
	_check(main._radio._atlas._band._seed == hash("the map"), "the Map's band does not name its place for its art")
	# with the Fence's art painted, its face still reads clear (the backdrop sits under it, 9 Oct: the Legion's first run with the art)
	var had_fence = UI._places.get("the_fence", null)
	UI._places["the_fence"] = tex
	main._fence._band._seed = 0
	main._fence._band.set_site("The Fence")
	main.show_room(main.MARKET)
	main.refresh()
	_check(main._fence._band.has_art() and main._fence.face_clear() and main._fence._band.get_child(0) == main._fence._band._art, "the Fence's painted band sits over its face, or isn't shown")
	if had_fence == null:
		UI._places.erase("the_fence")
	else:
		UI._places["the_fence"] = had_fence
	main._fence._band._seed = 0
	main._fence._band.set_site("The Fence")


func _yard_checks(main) -> void:
	var sim = main.sim
	_loot_roll_checks(main)
	if sim.on_mission():
		sim.extract_now()
	# the Stats room as a sheet (10 Oct, Stats-R A): the seven parts, each with its picture; every figure the cards had
	main.show_room(main.RUNNER)
	main.refresh()
	var st = main._stats
	for want in ["runner", "attack", "defence", "finds", "record", "last", "wall"]:
		_check(st.cards.has(want) and st.cards[want]["panel"].visible, "the sheet has no %s" % want)
	_check_fit(main, "Stats")
	_yard_wide_checks(main)
	main.show_room(main.RUNNER)
	main.refresh()
	var defence: Dictionary = st.cards["defence"]
	var fire_row: Dictionary = defence["res"][Data.ELEMENTS.find("fire")]
	_check(fire_row["key"].text == "Fire" and fire_row["value"].text.begins_with("%.0f%%" % (sim.resist("fire") * 100.0)) and (fire_row["value"].get_theme_color("font_color") == Pal.ELEMENT_COLOURS["fire"] or fire_row["value"].get_theme_color("font_color") == Pal.BAD), "the sheet's fire resist is off: %s" % fire_row["value"].text)
	_check(defence["headline"].text == "%d" % sim.max_hp_shown() and defence["unit"].text == "max HP", "the Defence headline is not the max HP: '%s'" % defence["headline"].text)
	_check(is_equal_approx(fire_row["tick"].position.x + 1.0, fire_row["track"].size.x * Data.RESIST_CAP / 100.0), "the resist bar's tick is not at the cap")
	# a torch makes the deal share show on Attack: a chip and its segment of the split
	var hold_gun = sim.equipped["Primary"]
	var torch: Dictionary = sim._plain("Primary", "Nail gun")
	torch["affixes"] = [{"stat": "conv_fire_pct", "value": 20, "tier": 2}]
	sim.equipped["Primary"] = torch
	main.refresh()
	var attack: Dictionary = st.cards["attack"]
	var fire_share: int = int(round(float(sim.conversion().get("fire", 0.0)) * 100.0))
	var attack_chips: Array = _chip_texts(attack["chips"])
	_check(fire_share >= 20 and attack_chips.has("Fire %d%%" % fire_share) and attack["segs"][Data.TYPES.find("fire")].visible, "with %d%% as fire the Attack chips read %s" % [fire_share, str(attack_chips)])
	_check(attack["headline"].text == "%.0f" % sim.dps() and attack["unit"].text == "dmg/s", "the Attack headline is '%s', not the damage a second" % attack["headline"].text)
	var total_row: Dictionary = attack["chain"][4]
	_check(total_row["value"].text == "%.0f/s" % sim.dps(), "the chain's total is off: %s" % total_row["value"].text)
	for r in attack["chain"]:
		_check(r["fill"].size.x <= r["track"].size.x + 0.5, "a chain bar runs past its track: %s" % r["key"].text)
	var dp: Dictionary = sim.damage_parts()
	var made: float = float(dp["guns"]) * (1.0 + float(dp["level"]) + float(dp["pct"])) * (1.0 + float(dp["attack"])) * float(dp["past"]) * float(dp["trait"]) * float(dp["growth"])
	_check(absf(made - sim.dps()) <= 0.01 * maxf(1.0, sim.dps()), "the damage's parts do not make dps(): %.1f against %.1f" % [made, sim.dps()])
	# a moved Yard's banked paragon is not this runner's XP: the bar's figures never go below nought
	var hold_bank: int = sim.paragon_banked
	sim.paragon_banked = 12
	main.refresh()
	_check(not st.cards["runner"]["xp"].text.begins_with("-") and not st.cards["runner"]["xp"].text.begins_with("−") and st.cards["runner"]["fill"].size.x >= 0.0, "the sheet's XP reads below nought after a move: '%s'" % st.cards["runner"]["xp"].text)
	sim.paragon_banked = hold_bank
	# a time-out is no success on the last run
	var hold_report = sim.last_report
	if hold_report != null:
		var to_report: Dictionary = hold_report.duplicate()
		to_report["outcome"] = "Out of time"
		to_report["timed_out"] = true
		sim.last_report = to_report
		main.refresh()
		_check(st.cards["last"]["headline"].get_theme_color("font_color") == Pal.ACCENT and st.cards["last"]["status"].text.begins_with("Out of time"), "a time-out reads as a success on the last run")
		_check_fit(main, "Stats (out of time)")
		sim.last_report = hold_report
		main.refresh()
	_check_fit(main, "Stats (a torch)")
	sim.equipped["Primary"] = hold_gun
	# the runner's trait reads as a stat: a chip with its figures on the sheet, a line on the Caravan
	var tdata: Dictionary = sim.trait_data()
	if not tdata.is_empty():
		var chip_texts2: Array = _chip_texts(st.cards["runner"]["chips"])
		_check(chip_texts2.any(func(t): return str(t).begins_with(tdata["name"] + ": ")), "the sheet has no trait chip: %s" % str(chip_texts2))
		main.show_room(main.BARRACKS)
		main._barracks.selected = ""
		main.refresh()
		_check(main._barracks._words.text.begins_with(tdata["name"] + ": "), "Training does not give the trait's figures: '%s'" % main._barracks._words.text)
		_check(main._barracks._class_line.text != "" and main._barracks._class_line.visible, "Training does not keep the class's line up")
		_check_fit(main, "Caravan (trait)")
		main.show_room(main.OVERVIEW)
		main.refresh()
	main.show_room(main.RUNNER)
	main.refresh()
	var finds: Dictionary = st.cards["finds"]
	_check(finds["unit"].text == "loot quality" and finds["bars"][0]["key"].text == "Loot quantity", "the Finds part is off: %s / %s" % [finds["unit"].text, finds["bars"][0]["key"].text])
	# a bonus below nought reads with a minus, never "+-5%": the rat's share takes 20% off quantity
	var hold_tree: Array = sim.tree.duplicate()
	if not sim.tree.has("The rat man/9"):
		sim.tree.append("The rat man/9")
	main.refresh()
	var figures: Array = [finds["headline"].text] + finds["bars"].map(func(r): return r["value"].text)
	_check(not figures.any(func(t): return str(t).contains("+-") or str(t).contains("+−")), "a Finds figure reads with a doubled sign: %s" % str(figures))
	_check(sim.loot_bonus() >= 0.0 or finds["bars"][0]["value"].text.begins_with("−"), "a quantity below nought reads '%s'" % finds["bars"][0]["value"].text)
	_check(StatsRoom.signed_pct(-5.0) == "−5%" and StatsRoom.signed_pct(8.0) == "+8%" and StatsRoom.signed_pct(0.0) == "0%" and StatsRoom.signed_pct(-0.2) == "0%", "signed percents read off")
	sim.tree = hold_tree
	main.refresh()
	_check_fit(main, "The Yard (option A)")
	# the Runs cards: a chip an element they fire, with your resist; the town fires fire and poison
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(2)
	main.refresh()
	var col: Dictionary = main._missions._cols[0]
	var chip_texts: Array = col["chips"].text_nodes().map(func(l): return l.text)
	if sim.tier_open(Data.ZONES[2]["tiers"][0]):
		_check(chip_texts.any(func(t): return str(t).begins_with("Fire")) and chip_texts.any(func(t): return str(t).contains("res")), "the town's card does not say what it fires and what you resist: %s" % str(chip_texts))
	# the odds in words, the figure small beside them; every band fits the card
	if sim.tier_open(Data.ZONES[2]["tiers"][0]):
		_check(Words.ODDS.any(func(b): return b[1] == col["band"].headline.text) and col["band"].unit.text.ends_with("to clear") or col["band"].unit.text == "reading the odds", "the odds don't read in words: '%s' / '%s'" % [col["band"].headline.text, col["band"].unit.text])
	for band in Words.ODDS:
		col["band"].headline.text = band[1]
		col["band"].unit.text = "100% to clear"
		_check(UI.text_width(col["band"].headline, band[1]) + 16 + UI.text_width(col["band"].unit, col["band"].unit.text) <= col["band"].headline.size.x, "the odds band '%s' and its figure don't share the band's foot" % band[1])
	main.refresh()
	_check(Words.odds_words(0.95) == "Safe" and Words.odds_words(0.5) == "A coin toss" and Words.odds_words(0.05) == "A bad idea", "the odds bands are off")
	_check_fit(main, "Runs (elements)")
	main._missions._pick_zone(1)
	# the Radio (9 Oct): its own screen; the cards are gone
	main.show_room(main.COMMS)
	_settle_odds(main)
	main.refresh()
	_check(main._radio.visible and not main._cards.any(func(c): return c.visible), "the Radio still shows cards")
	_check_fit(main, "Radio (screen)")
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
	sim.words[3] = []
	sim.deploy(3)
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
	# the faces (10 Oct, Run-P A): each in its box at the left, clear of the head, the tiles, the bar and the chips;
	# a face shows art or the drawn figure, never neither
	for pair in [[rn._fight_face, fb, rn._fight, "fight"], [rn._runner_face, rb, rn._runner, "runner"]]:
		var fr := Rect2(pair[0]["frame"].position, pair[0]["frame"].size)
		var ar := Rect2(pair[0]["art"].position, pair[0]["art"].size)
		_check(pair[1].encloses(fr) and fr.encloses(ar), "the %s's face (%s) is out of its box or its frame (%s)" % [pair[3], str(fr), str(ar)])
		var parts: Array = [pair[2]["head"], pair[2]["track"], pair[2]["key"], pair[2]["chips"]]
		if pair[2].has("note"):
			parts.append(pair[2]["note"])
		for tile in pair[2]["tiles"]:
			parts.append(tile["panel"])
		for piece in parts:
			_check(not fr.intersects(Rect2(piece.position, piece.size)), "the %s's face runs into its %s" % [pair[3], piece.name])
		_check(pair[0]["art"].visible != pair[0]["blank"].visible, "the %s's face shows %s" % [pair[3], "both art and the figure" if pair[0]["art"].visible else "nothing"])
	_check(rn._runner_face["art"].visible == (People.portrait(sim.cls) != null), "the runner's face does not follow the class's art")
	_check(rn.BOXED_X + 30 >= rn.PAD + rn.FACE + 10, "the fight's numbers can land on the faces")
	_check(rn._face_show(rn._fight_face, ["nobody with a face"]) == "" and rn._fight_face["blank"].visible and not rn._fight_face["art"].visible, "a face with no art does not show the drawn figure")
	main._run._shown = ""
	main.refresh()
	var zi := 0
	for z in range(Data.ZONES.size()):
		if int(m["tier"]) in Data.ZONES[z]["tiers"]:
			zi = z
	var head_out: bool = m.has("boss") and m["boss"]["started"] and m["boss"]["alive"]
	_check(head_out or rn._fight_face["art"].visible == (People.portrait(rn.gang_face(zi)) != null), "the fight's face does not show the zone's gang where the art is")
	_check(not main._run._button2.visible, "the second button shows before the clear on a manual run")
	m["remaining"] = 0
	sim._clear(m, m["t"])
	m["found"] = []                      # room in the pack: a full one leaves on the press, and the check reads a run still on (10 Oct)
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
	sim.deploy(3)
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
	sim.best_depth[8] = 3
	sim.depth[8] = 3
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
	# the rule (the endgame, 7 Oct): while the lorry stands the Services come first when they read PUSH;
	# the lorry beaten, the site that reads PUSH at the highest level (the Barracks at depth 1 over the Bank at 3)
	sim.lorry_done = false
	var t: int = bot.pick_tier(sim)
	_check(t == Data.CONVOY_TIER and sim.survival(t) >= Bot.PUSH, "past the campaign the bot did not go for the Services while the lorry stands: T%d (odds %.2f)" % [t, sim.survival(t)])
	sim.lorry_done = true
	t = bot.pick_tier(sim)
	# the rule, not the state: no site that reads PUSH as it stands sits at a higher level (the odds read by the night, the weather and the words)
	var higher := -1
	for i in range(Data.TIERS.size()):
		if sim.tier_open(i) and sim.site_level(i) > sim.site_level(t) and sim.survival(i) >= Bot.PUSH:
			higher = i
	_check(sim.survival(t) >= Bot.PUSH and higher < 0, "with the lorry beaten the bot did not run the highest level that reads PUSH: T%d at depth %d (odds %.2f), T%d reads PUSH higher" % [t, sim.depth[t], sim.survival(t), higher])
	bot.last_tier = t
	var d0: int = sim.depth[t]
	var climbs: bool = sim.survival(t) >= Bot.CLIMB
	bot._climb(sim)
	_check(sim.depth[t] == (d0 + 1 if climbs else d0), "the bot's climb did not follow CLIMB: depth %d from %d, odds %.2f" % [sim.depth[t], d0, sim.survival(t)])
	# at the lorry's depth the climb waits for the lorry
	sim.best_depth[Data.CONVOY_TIER] = Data.CONVOY_DEPTH + 1
	sim.depth[Data.CONVOY_TIER] = Data.CONVOY_DEPTH
	sim.lorry_done = false
	bot.last_tier = Data.CONVOY_TIER
	bot._climb(sim)
	_check(sim.depth[Data.CONVOY_TIER] == Data.CONVOY_DEPTH, "the bot dug past the lorry it had not beaten")
	sim.best_depth[Data.CONVOY_TIER] = 1
	sim.depth[Data.CONVOY_TIER] = 1
	sim.lorry_done = true
	# a boss left armed on another tier is turned off by the next pick: the sim
	# keeps the toggle on after a run, and a tier read with a boss in reads red
	# for the rest of a run (the twelfth read's T8 at 0% with 700 dps against 4.8)
	sim.boss_armed[11] = true
	sim.lorry_done = false                # the pick is the Services: the Barracks' head must come off
	t = bot.pick_tier(sim)
	_check(t != 8 and not sim.boss_armed.get(8, false), "the bot's pick left the Quartermaster armed on T8 (picked T%d)" % t)
	sim.lorry_done = true
	bot.last_tier = t
	# a runner that can't hold the depth steps back and picks as before: no
	# armour, no meds, level 3 - under at T5 whatever the tree
	sim.equipped["Primary"]["affixes"] = []
	sim.equipped["Armour"] = null
	sim.equipped["Helmet"] = null
	sim.xp = Data.xp_for_level(3)
	sim.hp = sim.max_hp()
	t = bot.pick_tier(sim)
	_check(sim.survival(t) >= Bot.PUSH and (t != 8 or sim.depth[8] == 1), "a weak runner past the campaign did not pick a site that reads PUSH: T%d, site depth %d, odds %.2f" % [t, sim.depth[t], sim.survival(t)])
	sim.lorry_done = false
	sim.boss_armed.clear()
	sim.odds_budget = budget0
	sim.load_dict(saved)
	print("the dig rule ok")
	_leave_checks(main)


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
	sim.deploy(3)
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


## The Fence's gamble (Matt, 6 Oct): five kinds on offer, rotated with the restock; pay and get a
## random one of the kind at the top tier opened, never Common; one time in fifty a unique of the kind.
func _gamble_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.candidates = []
	sim.auto_equip = false
	sim.restock()
	_check(sim.gamble.size() == Data.GAMBLE_SHOWN and sim.gamble.all(func(k): return not sim.gamble_kind(k).is_empty()), "the Fence's offer is not %d kinds: %s" % [Data.GAMBLE_SHOWN, str(sim.gamble)])
	var before: Array = sim.gamble.duplicate()
	var rotated := false
	for k in range(12):
		sim.restock()
		rotated = rotated or sim.gamble != before
	_check(rotated, "twelve restocks never changed the Fence's offer: %s" % str(sim.gamble))
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
		var fits: bool = Data.UNIQUES.any(func(u): return not u.has("site") and not u.get("boss", false) and u["slot"] == kd["slot"] and (kd["type"] == "" or Items.base_named(kd["slot"], u["base"]).get("type", "") == kd["type"]) and Items.unique_fits(u, sim.shop_unique_tier()))   # the chase is never the Fence's (part 3); its range takes the deepest tier dug (12 Oct)
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
	sim.wound = ""                     # whole: the bot keeps the Clinic's price back from the gamble when there is one to pay
	sim.hp = sim.max_hp()              # (the wound first: an HP wound lifts the maximum when it goes)
	var lorry_hold: bool = sim.lorry_done
	sim.lorry_done = true              # no Lorry watch saved for: the rule's own reserve is what's read here
	sim.cash = sim.gamble_price("rifle") * 3 - 1
	bot._gamble_one(sim)
	_check(bot.bought.is_empty(), "the bot gambled under three times the price")
	sim.cash = sim.gamble_price("rifle") * 3
	bot._gamble_one(sim)
	_check(bot.bought.size() == 1 and "rifle" in str(bot.bought[0][1]) and not ("rifle" in sim.gamble), "the bot did not gamble a rifle when flush: %s (cash %.0f, price %d, reserve %.0f, can %s, room %s)" % [str(bot.bought), sim.cash, sim.gamble_price("rifle"), bot._reserve(sim), str(sim.can_gamble("rifle")), str(sim.stash_room(4))])
	sim.lorry_done = lorry_hold
	# the takings: a run's cash and the Fence's money, averaged over the last few runs
	var tk0: float = sim.takings
	sim.deploy(3)
	sim.mission["cash"] = 5000.0
	sim.extract_now()
	_check(sim.takings > 0.0 and (tk0 <= 0.0 or absf(sim.takings - lerp(tk0, 5000.0, 0.25)) <= 1.0 or sim.takings >= 5000.0 * 0.25), "a run's cash did not reach the takings: %.0f from %.0f" % [sim.takings, tk0])
	sim.load_dict(saved)
	print("the Fence's gamble ok")
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


## Map juicing (9 Oct, docs/design/juicing.md): no words on campaign sites; papers teach the Radio its words;
## tiers and the words a site holds by depth; pools by zone and depth; the seven crafts and their prices; Twist
## seals; the words' bite and pay and their flags in the run; they stay through a run and a save; the screen.
func _radio_juice_checks(main) -> void:
	var sim = main.sim
	# the band (Bands-U A): the book's rows a label apart at least, the sites' list inside the room, the detail's crafts inside it
	var rdo = main._radio
	var bstep: float = rdo._book[rdo.BOOK_COLS].position.y - rdo._book[0].position.y if rdo._book.size() > rdo.BOOK_COLS else 99.0
	_check(bstep >= rdo._book[0].size.y and rdo.HEAD_H == Pal.BAND_H, "the Radio's book rows overlap: a step of %.1f for %.0f px labels" % [bstep, rdo._book[0].size.y])
	var last_row: Button = rdo._rows.back()["button"]
	_check(last_row.position.y + last_row.size.y <= Pal.ROOM_H, "the Radio's last site runs out of the room")
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	# before the depths open: nothing known, nothing worked, nothing crafted
	if not sim.campaign_done():
		sim.words[3] = [{"w": "Numbers", "t": 1}]
		_check(sim.words_known().is_empty() and not sim.juiceable(3) and sim.active_words(3).is_empty() and not ("Numbers" in sim.effective(3)["intel"]) and not sim.can_word_craft(3, "tune"), "a campaign site carries the Radio's words")
		sim.words[3] = []
		main.show_room(main.COMMS)
		_check(main._radio._quiet[0].visible and main._radio._title.text == "Nothing on the air", "the Radio does not say nothing's on the air in the campaign")
		_check_fit(main, "Radio (the campaign)")
	_finish_campaign(sim)
	sim.atlas = {}
	sim.yard_picks.erase("radio")
	sim.yard_ranks = {}
	sim._yard_changed("")
	for i in range(Data.TIERS.size()):
		sim.words[i] = []
		sim.sealed[i] = false
	sim.book = []
	sim.notes = 100000
	for k in range(Data.TIERS.size()):
		sim.best_depth[k] = 1                  # the zones heard: only the streets', below
	sim.best_depth[3] = 30
	sim.set_depth(3, 1)
	_check(not sim.juiceable(3) and not sim.can_word_craft(3, "broadcast"), "a site at depth 1 takes words")
	# the book: four to start, a zone's three once one of its sites is cleared at depth 2, a paper's when read
	var known: Array = sim.words_known()
	_check(known.size() == 4 + 3 and "Numbers" in known and "Dogs off the lead" in known and not ("Market day" in known) and not ("Bailiffs" in known), "the words known at the depths' opening are off: %s" % str(known))
	var p45: Dictionary = sim._plain(Data.PAPER, "A P45")
	sim._read(p45)
	_check(sim.knows_word("Laid off") and sim.word_taught_by("A P45") == "Laid off" and sim.events.back()[1].contains("Laid off".to_lower()), "reading the P45 did not teach Laid off: %s" % str(sim.events.back()))
	# how many and how strong by depth
	for row in [[2, 2, 1], [5, 3, 1], [8, 3, 2], [9, 4, 2], [15, 4, 3]]:
		sim.set_depth(3, row[0])
		_check(sim.max_words(3) == row[1] and sim.word_tier_cap(row[0]) == row[2], "depth %d holds %d words to tier %d, not %d to %d" % [row[0], sim.max_words(3), sim.word_tier_cap(row[0]), row[1], row[2]])
	# the pools: the site's zone's own, the general, the deep only from their depth; never twice on a site
	sim.set_depth(3, 15)
	sim._read(sim._plain(Data.PAPER, "A ration book"))
	sim._read(sim._plain(Data.PAPER, "A council minute"))
	var seen := {}
	for k in range(120):
		var rw: Array = sim._roll_words(3, [], 4)
		var names: Array = rw.map(func(wd): return wd["w"])
		for n in names:
			seen[n] = true
		var uniq := {}
		for n in names:
			uniq[n] = true
		_check(names.size() == 4 and uniq.size() == 4, "a roll put a word on twice or came up short: %s" % str(names))
		_check(rw.all(func(wd): return int(wd["t"]) >= 1 and int(wd["t"]) <= 3), "a roll's tier is off: %s" % str(rw))
	_check(seen.has("Rationed") and not seen.has("Curfew") and not seen.has("Market day") and not seen.has("Squaddies") and seen.has("Dogs off the lead") and seen.has("Laid off"), "the pools are off at depth 15 on the streets: %s" % str(seen.keys()))
	# the crafts: prices in notes by depth; each does its one thing
	sim.set_depth(3, 9)
	var n0: int = sim.notes
	var cost: int = sim.word_craft_cost(3, "broadcast")
	_check(cost == 27 and not sim.can_word_craft(3, "retune") and not sim.can_word_craft(3, "hold") and sim.word_craft(3, "broadcast") and sim.words[3].size() == 4 and sim.notes == n0 - cost, "Broadcast did not fill the site for 27 notes: %s, %d" % [str(sim.words[3]), n0 - sim.notes])
	_check(not sim.can_word_craft(3, "broadcast") and not sim.can_word_craft(3, "tune") and sim.word_craft_block(3, "tune").begins_with("Full"), "a full site takes another word")
	var held: String = sim.words[3][1]["w"]
	_check(sim.word_craft(3, "hold", held) and sim.words[3].size() == 4 and held in sim.word_names(3), "Hold lost the held word: %s" % str(sim.words[3]))
	var before: Array = sim.word_names(3)
	_check(sim.word_craft(3, "retune") and sim.words[3].size() == 4, "Retune changed the count")
	_check(sim.word_craft(3, "clear") and sim.words[3].is_empty(), "Clear left words on")
	_check(sim.word_craft(3, "tune") and sim.words[3].size() == 1, "Tune in did not add one")
	var opts: Array = sim.call_options(3)
	_check(not opts.is_empty() and not (sim.words[3][0]["w"] in opts) and not ("Curfew" in opts), "Call in offers what's on the site or too deep: %s" % str(opts))
	_check(sim.word_craft(3, "call", opts[0]) and opts[0] in sim.word_names(3), "Call in did not add the word asked for")
	_check(not sim.word_craft(3, "call", "Curfew"), "Call in took a word deeper than the site")
	# the words in the run: their bite and pay, tiers by depth, held to what the depth allows
	sim.words[3] = []
	var plain: Dictionary = sim.effective(3)
	sim.words[3] = [{"w": "Numbers", "t": 2}]
	var e2: Dictionary = sim.effective(3)
	_check(is_equal_approx(e2["hp"] / plain["hp"], pow(1.4, 1.75)) and is_equal_approx(e2["drop"] / plain["drop"], pow(1.3, 1.75)) and int(e2["word_tiers"]["Numbers"]) == 2, "Numbers at tier II is off: hp ×%.3f" % (e2["hp"] / plain["hp"]))
	sim.set_depth(3, 2)
	_check(sim.word_tier_now(3, 3) == 1 and int(sim.effective(3)["word_tiers"]["Numbers"]) == 1, "a tier II word ran at tier II at depth 2")
	sim.set_depth(3, 9)
	_check(sim.word_words("Numbers", 1) == ["HP +40%", "finds +30%"], "a word's words are off: %s" % str(sim.word_words("Numbers", 1)))
	# the flags: no meds, no kill cash, a clock, your armour cut, the head walking
	sim.words[3] = [{"w": "Rationed", "t": 1}, {"w": "Overdrawn", "t": 1}]
	sim.set_depth(3, 15)
	sim.rig.append(sim._plain(Data.MEDICAL, "Bandage"))
	sim.hp = sim.max_hp()
	sim.deploy(3)
	var m: Dictionary = sim.mission
	_check(m != null and m["t"].get("no_meds", false) and not sim.use_med(sim.first_med()["id"]), "Rationed let a med be used")
	var cash0: float = float(m["cash"])
	sim._kill(m, m["t"])
	_check(is_equal_approx(float(m["cash"]), cash0), "Overdrawn paid cash for a kill: %.0f" % (float(m["cash"]) - cash0))
	sim.extract_now()
	if sim.on_mission():
		sim._extract()
	_check(sim.word_names(3) == ["Rationed", "Overdrawn"], "a run home spent the site's words: %s" % str(sim.word_names(3)))
	var vest_was = sim.equipped["Armour"]
	sim.equipped["Armour"] = sim._plain("Armour", "Stab vest")
	sim._dry_memo.clear()
	sim.words[3] = [{"w": "Pawned", "t": 1}]
	var t_p: Dictionary = sim.effective(3)
	t_p["types"] = {"physical": 1.0}
	sim.words[3] = []
	var t_0: Dictionary = sim.effective(3)
	t_0["types"] = {"physical": 1.0}
	t_p["dps"] = t_0["dps"]
	_check(sim.armour() > 0.0 and sim.incoming_rate(t_p, 1) > sim.incoming_rate(t_0, 1), "Pawned did not cut your armour: %.2f vs %.2f with %.0f armour" % [sim.incoming_rate(t_p, 1), sim.incoming_rate(t_0, 1), sim.armour()])
	sim.equipped["Armour"] = vest_was
	sim._dry_memo.clear()
	sim._read(sim._plain(Data.PAPER, "The Manager's note"))
	sim.best_depth[6] = 60
	sim.set_depth(6, 50)
	sim.words[6] = [{"w": "The Manager walks", "t": 1}]
	var tw: Dictionary = sim.effective(6)
	var notes_w: int = sim.notes
	sim.hp = sim.max_hp()
	sim.deploy(6)
	_check(tw.has("boss") and str(tw["boss"]["name"]) == str(Data.BOSSES[1]["name"]) and sim.on_mission() and sim.notes == notes_w and sim.mission.has("boss"), "The Manager walks did not bring the Town's head for free: %s, notes %d → %d" % [str(tw.get("boss", {})), notes_w, sim.notes])
	sim.extract_now()
	if sim.on_mission():
		sim._extract()
	sim.words[6] = []
	sim.best_depth[3] = 30
	sim.set_depth(3, 24)
	sim.words[3] = []
	var clock_plain: float = sim.clock_of(3)
	sim.words[3] = [{"w": "Last bus", "t": 1}]
	_check(is_equal_approx(sim.clock_of(3), clock_plain * 0.5), "Last bus did not halve the clock: %.0f of %.0f" % [sim.clock_of(3), clock_plain])
	sim.words[3] = [{"w": "Numbers", "t": 3}, {"w": "Market day", "t": 3}]
	_check(is_equal_approx(sim.clock_of(3), clock_plain), "the Radio's words moved the clock: %.0f of %.0f" % [sim.clock_of(3), clock_plain])
	sim.words[3] = []
	# Twist: one of four, always sealed; a sealed site takes nothing but a dear Clear
	sim.set_depth(3, 15)
	var fours := 0
	var deeps := 0
	for k in range(30):
		sim.sealed[3] = false
		sim.words[3] = [{"w": "Numbers", "t": 1}, {"w": "Ex-army", "t": 1}]
		_check(sim.word_craft(3, "twist") and sim.sealed[3], "Twist did not seal the site")
		fours += 1 if sim.words[3].any(func(wd): return int(wd["t"]) == 4) else 0
		deeps += 1 if sim.words[3].any(func(wd): return Data.word_of(wd["w"])["learn"] == "deep") else 0
	_check(fours > 3 and deeps > 1, "Twist's outcomes are off in thirty: %d tier IV, %d deep" % [fours, deeps])
	_check(not sim.can_word_craft(3, "tune") and not sim.can_word_craft(3, "twist") and sim.word_craft_block(3, "retune").begins_with("Sealed"), "a sealed site took a craft")
	_check(sim.word_craft_cost(3, "clear") == int(ceil(0.5 * 15 * Data.SEALED_CLEAR)) and sim.word_craft(3, "clear") and not sim.sealed[3], "Clear on a sealed site is not ten times, or did not unseal")
	# the words and the book survive a save
	sim.words[3] = [{"w": "Bailiffs", "t": 2}]
	sim.sealed[3] = true
	var rt: Dictionary = sim.to_dict()
	sim.words[3] = []
	sim.sealed[3] = false
	sim.load_dict(rt)
	_check(sim.words[3] == [{"w": "Bailiffs", "t": 2}] and sim.sealed[3] and sim.knows_word("Laid off"), "the Radio's words did not survive a save: %s" % str(sim.words[3]))
	var old: Dictionary = sim.to_dict()
	old.erase("words")
	old["intel"] = [["Numbers"]]
	sim.load_dict(old)
	_check(sim.words.all(func(w): return w.is_empty()), "an old save's words were kept")
	# the screen: a row a site with a ladder, the picked site's words and crafts, the book
	sim.sealed[3] = false
	sim.words[3] = []
	sim.set_depth(3, 9)
	main.show_room(main.COMMS)
	var rd = main._radio
	rd._pick(3)
	main.refresh()
	_check(rd.visible and rd.row(3)["button"].visible and not rd._quiet[0].visible and rd.craft_button("broadcast") != null and not rd.craft_button("broadcast").disabled and rd.craft_button("retune").disabled, "the Radio's crafts don't match the site: broadcast %s, retune %s" % [str(rd.craft_button("broadcast").disabled), str(rd.craft_button("retune").disabled)])
	_check_fit(main, "Radio (a silent site)")
	rd._craft("broadcast")
	main.refresh()
	_check(sim.words[3].size() == 4 and rd.word_row(3)["panel"].visible and rd.word_row(0)["badge_label"].text in ["I", "II"] and rd.word_row(0)["bite"].text.begins_with("▲") and rd.word_row(0)["pay"].text.begins_with("●"), "the Radio's word rows are off after a broadcast: %s" % str(sim.words[3]))
	_check(rd._get.text != "Nothing yet" and rd._bring.text != "Nothing yet", "the totals are empty on a juiced site")
	_check_fit(main, "Radio (juiced)")
	rd._craft("call")
	_check(not main._menu.visible, "Call in opened its chooser on a full site")
	sim.words[3] = sim.words[3].slice(0, 2)
	main.refresh()
	rd._craft("call")
	_check(main._menu.visible, "Call in did not open the chooser")
	main._menu.close()
	rd._craft("hold")
	_check(main._menu.visible, "Hold did not open the chooser")
	main._menu.close()
	sim.atlas_points = 40
	for k in ["good_reception", "good_reception", "clear_air", "booster", "booster", "booster", "long_wave", "tip_offs", "tip_offs", "strong_signal", "strong_signal", "early_word", "early_word", "held_frequency", "relay"]:
		sim.rank_atlas(k)
	_check(sim.atlas_rank("relay") == 1, "the air lane did not open to the Relay")
	main.refresh()
	_check(rd._stand[0].visible and rd._filter.visible, "the book has no standing word or filter button")
	main._choose_book("standing0")
	_check(main._menu.visible, "the standing word's chooser did not open")
	main._menu.close()
	sim.set_standing(0, "Ex-army")
	sim.set_filtered("Numbers")
	main.refresh()
	_check(rd._stand[0].text.contains("Ex-army") and rd._filter.text.contains("Numbers"), "the book's buttons don't name their words: '%s' / '%s'" % [rd._stand[0].text, rd._filter.text])
	_check_fit(main, "Radio (the book, the standing word)")
	# the Runs card: a word's tier as its chip's tag
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(1)
	main._missions._shown = ""
	main.refresh()
	var c: Dictionary = main._missions._cols[0]
	_check(c["intel"].shown() >= 1 and c["intel_head"].text.contains("from the Radio"), "the Runs card does not carry the Radio's words: '%s'" % c["intel_head"].text)
	_check_fit(main, "Runs (juiced)")
	sim.load_dict(saved)
	main.refresh()
	print("map juicing ok: campaign sites plain, the book, depth's words and tiers, the pools, seven crafts, Twist, the flags, the save, the screen")


## Run timers (9 Oct, docs/design/timers.md): a site's clock, the same for every build; it runs only while a gang
## is on you; a head brings his own time; out of time the runner lives, the pack and two pieces of kit don't
## (the insurance pays for the kit); the dry runs read it; the run screen and the Runs card show it.
## Matt's notes of 10 Oct: a node's sentence under its title and never "wants N points" (the tree and the button say
## the cost); the Workshop's heading says Workshop; the top bar's XP is this runner's after a move.
func _panel_words_checks(main) -> void:
	var sim = main.sim
	var hold_pts: int = sim.training_points
	main.show_room(main.BARRACKS)
	var bk = main._barracks
	var pick := ""
	for t in sim.trees():
		if t == null or t.get("drawer", false):
			continue
		for k in range(t["nodes"].size()):
			var id := "%s/%d" % [t["name"], k]
			if not sim.tree.has(id) and sim.train_block(id, true) == "":
				pick = id
				break
		if pick != "":
			break
	sim.training_points = sim.points_spent()           # none free: the block would be the points
	bk.selected = pick
	bk._shown = ""
	main.refresh()
	if pick != "":
		_check(not bk._words.text.to_lower().contains("wants 1 point") and not bk._words.text.to_lower().contains("point free"), "a node's sentence still says the points: '%s'" % bk._words.text)
		_check(bk._words.position.y >= bk._title.position.y + bk._title.size.y - 2.0 and bk._words.position.x + bk._words.size.x <= bk._train.position.x - 8.0, "a node's sentence is not under its title, clear of the buttons")
		_check(bk._train.disabled, "Train is not off with no point free")
		# four buttons late on leave ~430 px: every node's sentence still says itself, over its two lines
		var worst := 0
		for t in sim.trees():
			if t == null or t.get("drawer", false):
				continue
			for k in range(t["nodes"].size()):
				var s: String = bk._sentence(t["nodes"][k])
				bk.fit_two([s], 430.0)
				if (bk._words.text + " " + bk._words2.text).strip_edges() != s.strip_edges() or UI.text_width(bk._words2, bk._words2.text) > 430.0:
					worst += 1
		_check(worst == 0, "%d node sentences do not fit two lines at 430 px" % worst)
		bk._shown = ""
		main.refresh()
		_check_fit(main, "Training (a node, no point free)")
	sim.training_points = hold_pts
	bk.selected = ""
	bk._shown = ""
	main.show_room(main.WORKSHOP)
	main.refresh()
	_check(main._workshop._kicker.text == "The Workshop", "the Workshop's heading says '%s'" % main._workshop._kicker.text)
	var hold_bank: int = sim.paragon_banked
	sim.paragon_banked = 12
	main.refresh()
	_check(not main._top_labels["xp"].text.begins_with("-") and not main._top_labels["xp"].text.begins_with("−") and main._top_lines["xp"][1].size.x >= 0.0, "the top bar's XP reads below nought after a move: '%s'" % main._top_labels["xp"].text)
	sim.paragon_banked = hold_bank
	main.show_room(main.OVERVIEW)
	main.refresh()
	print("the panel's words ok: under the title, no points; the Workshop's heading; the top bar's XP after a move")


## The rooms' bands (10 Oct, Rooms-B): Training, the Workshop, the Radio and the Yard under their painted places once
## painted (Stats has its band); the art under the words, covering the heading, shaded from the left, the words with a
## shadow; nothing while the file is missing.
func _room_band_checks(main) -> void:
	var rooms := [[main.BARRACKS, main._barracks, "the_caravan"], [main.WORKSHOP, main._workshop, "the_workshop"], [main.COMMS, main._radio, "the_radio"], [main.OVERVIEW, main._yard_tree, "the_yard"]]
	var stand_in: Texture2D = UI.place_texture("Ransacked Streets")
	for r in rooms:
		var hb: Dictionary = r[1].head_band
		var art: TextureRect = hb["art"]
		var head: Panel = art.get_parent()
		var file := "res://art/places/%s.png" % r[2]
		var painted: bool = ResourceLoader.exists(file) or FileAccess.file_exists(file)
		_check(UI.place_slug(hb["place"]) == r[2], "%s's band names %s, not %s" % [r[2], UI.place_slug(hb["place"]), r[2]])
		_check(art.visible == painted and hb["shade"].visible == painted, "%s's band does not follow its art (painted %s)" % [r[2], str(painted)])
		_check(art.get_index() == 0 and hb["shade"].get_index() == 1 and head.clip_contents and art.size == head.size - Vector2(2, 2) and art.position == Vector2(1, 1) and art.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s's band is not under the heading's words, or not inside its line" % r[2])
		if stand_in != null and not painted:
			UI.set_head_art(hb, stand_in)
			var unshadowed := 0
			for c in head.get_children():
				if c is Label and c.get_theme_color("font_shadow_color").a < 0.5:
					unshadowed += 1
			_check(art.visible and hb["shade"].visible and unshadowed == 0, "%s's band, painted, leaves %d words without a shadow" % [r[2], unshadowed])
			var sc: float = maxf(art.size.x / stand_in.get_width(), art.size.y / stand_in.get_height())
			_check((art.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST) == is_equal_approx(sc, roundf(sc)), "%s's band filters a %.2fx scale the wrong way" % [r[2], sc])
			main.show_room(r[0])
			main.refresh()
			_check_fit(main, "%s (a stand-in band)" % r[2])
			UI.set_head_art(hb, null)
			for c in head.get_children():
				if c is Label:
					_check(c.get_theme_color("font_shadow_color").a < 0.01, "%s's words kept a shadow on the plain card" % r[2])
	main.show_room(main.OVERVIEW)
	main.refresh()
	print("the rooms' bands ok: four headings under their places, the words over them")


## The Runner room's backdrop (10 Oct, Kit-B): under the figure and the slots, the frame round them; the painted
## lock-up at 40% with the slots as glass where the art is, the drawn light where it isn't.
func _backdrop_checks(main) -> void:
	var sim = main.sim
	main.show_room(main.ARMOURY)
	main.refresh()
	var body = main._armoury._body
	_check(body.get_child(0) == body.backdrop and body.backdrop.size == body.size and body.backdrop.mouse_filter == Control.MOUSE_FILTER_IGNORE, "the backdrop is not under the figure and the slots, or takes the mouse")
	# the kit room's art back under the loadout (Matt, 10 Oct: "add the art we have for that screen back in"): painted
	# when the file is there, the drawn light while it isn't
	var kit_file := "res://art/places/the_kit_room.png"
	var kit_painted: bool = ResourceLoader.exists(kit_file) or FileAccess.file_exists(kit_file)
	_check(body.has_backdrop_art() == kit_painted and body._backdrop_art.get_parent() == body.backdrop and body._vignette.visible == kit_painted, "the kit room's art does not follow its file (painted %s)" % str(kit_painted))
	_check(body.get_child(1) == body._frame and body._frame.mouse_filter == Control.MOUSE_FILTER_IGNORE and body._flat.get_index() > body._frame.get_index(), "the backdrop's frame or the flat figure's layer is out of order, or takes the mouse")
	for slot in Data.SLOTS:
		var b: Dictionary = body._boxes[slot]
		_check(b["zone"].get_index() > body._flat.get_index(), "the %s slot is under the backdrop's layers" % slot)
		var sb: StyleBoxFlat = b["outline"].get_theme_stylebox("panel")
		var filled: bool = sim.equipped[slot] != null
		# the card is glass whether full or not (Runner-R A: it carries the words); the picture's cell is glass too
		_check(is_equal_approx(sb.bg_color.a, body.GLASS_ALPHA), "the %s card is not glass: %.2f (%s)" % [slot, sb.bg_color.a, "filled" if filled else "empty"])
		# the loadout (Runner-R A): the slot named always; a full card names its item and its figure; Matt's order -
		# the weapons and the charm down the left, the helmet over the armour, the rig and the pack down the right
		_check(b["name"].text == slot.to_upper() and b["name"].visible, "the %s card does not name its slot" % slot)
		if filled:
			# the picture big enough to read: a long gun across the card, the rest at its left
			var cz: Vector2 = b["cell"].size
			var fp: Vector2i = Items.footprint(sim.equipped[slot])
			var shown_h: float = minf(cz.y, cz.x * float(fp.y) / float(fp.x))
			_check(shown_h >= 36.0, "the %s card's picture is a sliver: %.0f px tall in %s" % [slot, shown_h, str(cz)])
			# the art fills the card (Runner-R B's way, Matt 10 Oct): the name is the art's and the tooltip's, the figure over it
			_check(b["cell"].tooltip_text.begins_with(Items.full_name(sim.equipped[slot])) and b["fig"].text == "" and b["cell"].size.x >= body.box_rect(slot).size.x - 8 and b["cell"].size.y >= body.box_rect(slot).size.y - body.TOP_STRIP - body.FOOT_STRIP - 2 and not Rect2(b["cell"].position, b["cell"].size).intersects(Rect2(b["name"].position, Vector2(b["name"].size.x, 18))), "the %s card's art or words are off: '%s' / '%s' %s" % [slot, b["cell"].tooltip_text, b["fig"].text, str(b["cell"].size)])
		var cr: Rect2 = body.box_rect(slot)
		_check((cr.position.x < body.FIGURE_X) == (slot in ["Backpack", "Primary", "Secondary"]), "the %s card is on the wrong side" % slot)
		_check(not cr.intersects(Rect2(body.FIGURE_X - body.FIGURE_W / 2.0, body.FIGURE_Y, body.FIGURE_W, body.FIGURE_H)), "the %s card sits on the figure" % slot)
		_check(b["cell"].glass, "the %s slot's cell is not glass" % slot)
		_check(Rect2(Vector2.ZERO, body.size).encloses(Rect2(b["zone"].position, b["zone"].size)), "the %s slot leaves the backdrop's frame" % slot)
	_check_fit(main, "Runner (the backdrop)")
	# Matt's order (10 Oct): the pack big over the primary and the secondary down the left; the helmet, the armour, the
	# rig and the charm down the right; no worn card; the charm smaller than the armour; each column filling the loadout
	var by := func(sl): return body.box_rect(sl).position.y
	_check(by.call("Backpack") < by.call("Primary") and by.call("Primary") < by.call("Secondary") and by.call("Helmet") < by.call("Armour") and by.call("Armour") < by.call("Rig") and by.call("Rig") < by.call("Charm"), "the loadout's order is not Matt's")
	_check(not body.has_method("worn_rect") and body.box_rect("Charm").size.y < body.box_rect("Armour").size.y and body.box_rect("Backpack").size.y >= body.box_rect("Primary").size.y, "the worn card is back, or the charm, armour or pack sized wrong")
	for col in [body.LEFT, body.RIGHT]:
		_check(absf(body.box_rect(col.back()).end.y - (body.HEIGHT - body.PAD)) < 0.5, "the %s column does not fill the loadout" % col.back())
	# the figure fills the gap between the columns (Matt, 10 Oct: his redraw looked too small): its drawing, margin
	# cropped, binds on the gap's height or width
	var fd: Vector2 = body.figure_drawn()
	_check(fd == Vector2.ZERO or fd.y >= body.FIGURE_H - 1.0 or fd.x >= body.FIGURE_W - 1.0, "the figure is drawn %s in a %d × %d gap" % [str(fd), body.FIGURE_W, body.FIGURE_H])
	# a figure a class (Matt, 10 Oct): the runner's past's own drawing when there is one, art/body.png when not; it
	# follows a change of past
	var cls_hold: String = sim.cls
	for cd in Data.CLASSES:
		sim.cls = cd["name"]
		body.show_state(sim)
		var own: String = body.BODY_CLASS_ART % str(cd["name"]).to_lower()
		var has_own: bool = ResourceLoader.exists(own) or FileAccess.file_exists(own)
		_check(body.figure_path == (own if has_own else body.figure_for("")), "%s shows %s, not its own figure" % [cd["name"], body.figure_path])
		var fd2: Vector2 = body.figure_drawn()
		_check(body.figure_path == "" or fd2.y >= body.FIGURE_H - 1.0 or fd2.x >= body.FIGURE_W - 1.0, "%s's figure is drawn %s in the gap" % [cd["name"], str(fd2)])
	sim.cls = cls_hold
	body.show_state(sim)
	# the strip over it: who, HP, damage, armour, inside the strip and above the loadout
	var arm = main._armoury
	_check(arm._hp.text.contains("HP") and arm._dps.text.contains("dmg/s") and arm._who.text.contains("level") and arm.BODY_Y >= arm.STRIP_H and arm.CONTAINERS_Y + arm._containers.size.y <= Pal.ROOM_H, "the runner strip or the column's stack is off: '%s' '%s' '%s'" % [arm._who.text, arm._hp.text, arm._dps.text])
	print("the loadout ok: the strip, the cards in Matt's order, the kit room under it, glass cards")


## The purse on the top bar (10 Oct, Bar-C): notes and scrap through the campaign, each salvage kind joining once
## there's any; the worst figures out on a run still clear of the runner's figures (the fit's purse check).
func _purse_checks(main) -> void:
	var sim = main.sim
	var hold: Array = [sim.salvage.duplicate(), sim.scrap, sim.notes]
	sim.salvage = {"copper": 0, "steel": 0, "army": 0}
	main.refresh()
	_check(main._top_labels["scrap"].visible and main._top_labels["scrap"].text == Fmt.num(sim.scrap) and not main._top_labels["copper"].visible and not main._top_glyphs["army"].visible, "the campaign's purse is not notes and scrap")
	_check_fit(main, "Top bar (the campaign's purse)")
	# a painted art/ui/<k>.png where there is one (the purse manifest), else the engine's line glyph
	for k in ["scrap", "copper", "steel", "army"]:
		var painted: Texture2D = UI.glyph_texture(k)
		_check(main._top_glyphs[k].texture == (painted if painted != null else NodeGlyphs.texture(k)), "the top bar's %s glyph is not its art or its line" % k)
	sim.salvage = {"copper": 0, "steel": 7, "army": 0}
	main.refresh()
	_check(main._top_labels["steel"].visible and main._top_labels["steel"].text == "7" and not main._top_labels["copper"].visible, "safe steel did not join the purse alone")
	sim.salvage = {"copper": 9999, "steel": 9999, "army": 9999}
	sim.scrap = 99999
	sim.notes = 999999
	sim.hp = sim.max_hp()
	sim.deploy(3)
	main.refresh()
	_check(main._top_glyphs["where"].tooltip_text.begins_with("Out: ") and main._top_glyphs["where"].mouse_filter != Control.MOUSE_FILTER_IGNORE, "the place's glyph does not keep its words where a hover finds them: '%s'" % main._top_glyphs["where"].tooltip_text)
	# each purse label's box is its figure: a tooltip never lies over its neighbour
	for k in ["notes", "scrap", "copper", "steel", "army", "cash"]:
		var pl: Label = main._top_labels[k]
		if pl.visible:
			_check(pl.size.x <= UI.text_width(pl, pl.text) + 4.0, "the top bar's %s box runs past its figure: %.0f for %.0f" % [k, pl.size.x, UI.text_width(pl, pl.text)])
	_check_fit(main, "Top bar (every currency, out on a run)")
	sim.extract_now()
	sim.salvage = hold[0]
	sim.scrap = hold[1]
	sim.notes = hold[2]
	main.refresh()
	print("the purse ok: notes and scrap, the salvage as it's found, clear of the figures at the worst")


## The way out (10 Oct, docs/design/way_out.md, Run-P B): Get out now before the clear is a last gang at the door and
## so long to see them off - seen off, home with the pack; out of time, a time-out; after the clear, free as before.
func _way_out_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	var autos: Array = [sim.auto_equip, sim.auto_sell]
	sim.auto_equip = false
	sim.auto_sell = false                       # the pack's find is read in the stash as it came home
	_check(sim.way_out_s(sim.effective(11)) > sim.way_out_s(sim.effective(3)) and is_equal_approx(sim.way_out_s(sim.effective(3)), Data.WAY_OUT_S), "the way out does not grow with the tier: %.0f / %.0f" % [sim.way_out_s(sim.effective(3)), sim.way_out_s(sim.effective(11))])
	sim.hp = sim.max_hp()
	sim.deploy(3)
	var m: Dictionary = sim.mission
	m["target_hp"] = 1e12
	sim.hp = 1e9
	main.show_room(main.MISSIONS)
	main.refresh()
	var rs = main._run
	_check(rs._button.text.begins_with("Get out now · ") and rs._button.text.ends_with("and a last gang"), "before the clear Get out now does not say its price: '%s'" % rs._button.text)
	_check_fit(main, "Run (the way out's price)")
	var found: Dictionary = sim._plain("Helmet", "Hard hat")
	m["found"].append(found)
	var pool: int = int(m["remaining"])
	rs._get_out()
	_check(sim.on_mission() and m.get("way_out", false) and int(m["remaining"]) == sim.door_gang(m["t"]) and int(m["left_behind"]) == pool, "Get out now before the clear did not start the way out: %s / %d at the door" % [str(m.get("way_out", false)), int(m["remaining"])])
	_check(is_equal_approx(float(m["way_out_t"]), minf(sim.way_out_s(m["t"]), float(m["clock"]))), "the way out's time is off: %.1f" % float(m["way_out_t"]))
	main.refresh()
	_check(rs._band.kicker.text.ends_with("the way out") and rs._band.headline.text == Fmt.mss(ceilf(float(m["way_out_t"]))) and rs._fight["head"].text == "THE FIGHT · THE WAY OUT" and rs._button.text.begins_with("Getting out"),
		"the run screen does not show the way out: '%s' / '%s' / '%s' / '%s'" % [rs._band.kicker.text, rs._band.headline.text, rs._fight["head"].text, rs._button.text])
	_check(rs._band._bar_label.text.ends_with("at the door seen off"), "the way out's bar does not count the door: '%s'" % rs._band._bar_label.text)
	_check_fit(main, "Run (the way out)")
	rs._get_out()
	_check(sim.on_mission() and m.get("way_out", false), "a second press left the way out")
	var w0: float = float(m["way_out_t"])
	sim.advance(1.0)
	_check(sim.on_mission() and is_equal_approx(float(m["way_out_t"]), w0 - 1.0), "the way out's time did not run: %.1f from %.1f" % [float(m["way_out_t"]), w0])
	# seen off: home with the pack
	m["remaining"] = 1
	m["target_hp"] = 0.01
	for w in range(6):                         # past a melee wait or an underlay's grace
		if sim.on_mission():
			sim.advance(1.0)
	_check(not sim.on_mission() and sim.last_report.get("way_out", false) and not sim.last_report.get("timed_out", false) and sim.stash.has(found), "seeing them off did not bring the pack home: %s" % str(sim.last_report.get("outcome", "")))
	# out of time at the door: a time-out
	sim.hp = sim.max_hp()
	sim.deploy(3)
	m = sim.mission
	m["target_hp"] = 1e12
	sim.hp = 1e9
	sim.get_out()
	m["target_hp"] = 1e12
	m["way_out_t"] = 0.5
	sim.advance(1.0)
	_check(not sim.on_mission() and sim.last_report.get("timed_out", false) and sim.last_report.get("outcome", "") == "Out of time", "out of time at the door was not a time-out: %s" % str(sim.last_report.get("outcome", "")))
	# never longer than the run's clock has left
	sim.hp = sim.max_hp()
	sim.deploy(3)
	m = sim.mission
	m["clock"] = 6.0
	sim.get_out()
	_check(float(m["way_out_t"]) <= 6.0, "the way out ran past the run's clock: %.1f" % float(m["way_out_t"]))
	sim.extract_now()
	# after the clear: free and at once
	sim.hp = sim.max_hp()
	sim.deploy(3)
	m = sim.mission
	m["remaining"] = 0
	sim._clear(m, m["t"])
	sim.get_out()
	_check(not sim.on_mission() and not sim.last_report.get("way_out", false), "after the clear Get out now was not free and at once")
	# a Ghost's run is cleared from the start, but its first gang on you is no clear: the way out (the review, 10 Oct)
	sim.hp = sim.max_hp()
	sim.deploy(3)
	m = sim.mission
	m["cleared"] = true
	m["ghost_pending"] = true
	m["remaining"] = 3
	m["target_hp"] = 1e12
	sim.get_out()
	_check(sim.on_mission() and m.get("way_out", false), "a Ghost's run left for free with its first gang on")
	sim.extract_now()
	# a head who has come out is left behind; the door's gang down is out, never the head coming back
	sim.hp = 1e9
	sim.deploy(3)
	m = sim.mission
	m["boss"] = sim._boss_entry({"name": "The Carpet Man", "hp": 1e9, "dps": 1.0, "zone": 0})
	m["boss"]["started"] = true
	m["remaining"] = 1
	m["target_hp"] = 1e9
	sim.get_out()
	_check(not m["boss"]["started"], "the head kept fighting through the way out")
	m["remaining"] = 1
	m["target_hp"] = 0.01
	for w in range(6):                         # past a melee wait or an underlay's grace
		if sim.on_mission():
			sim.advance(1.0)
	_check(not sim.on_mission() and sim.last_report.get("way_out", false), "the door's gang down did not end the run with a head left behind")
	# saved and loaded mid way out, it carries on
	sim.hp = 1e9
	sim.deploy(3)
	m = sim.mission
	m["target_hp"] = 1e12
	sim.get_out()
	var mid: Dictionary = sim.to_dict()
	sim.load_dict(JSON.parse_string(JSON.stringify(mid)))
	m = sim.mission
	_check(sim.on_mission() and m.get("way_out", false) and float(m["way_out_t"]) > 0.0, "a load mid way out lost it")
	m["remaining"] = 1
	m["target_hp"] = 0.01
	sim.hp = 1e9
	for w in range(6):
		if sim.on_mission():
			sim.advance(1.0)
	_check(not sim.on_mission() and sim.last_report.get("way_out", false), "a loaded way out did not end when seen off")
	# the price follows the run's clock as it falls under the way out's time
	sim.hp = 1e9
	sim.deploy(8 if sim.tier_open(11) else 0)
	m = sim.mission
	m["target_hp"] = 1e12
	main.refresh()
	m["clock"] = 7.0
	main.refresh()
	_check(rs._button.text.contains(Fmt.mss(7.0)), "the price did not follow the run's clock: '%s'" % rs._button.text)
	sim.extract_now()
	sim.load_dict(saved)
	sim.auto_equip = autos[0]
	sim.auto_sell = autos[1]
	main.refresh()
	print("the way out ok: the price, the door's gang, the time, seen off, out of time, the clock's cap, free after the clear")


func _clock_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	var t0: Dictionary = sim.effective(3)
	_check(is_equal_approx(sim.clock_of(3), Data.CLOCK_BASE + Data.CLOCK_PER_HEAD * (int(t0["plain_pool"]) + Data.CLOCK_GANGS)), "the streets' clock is off: %.0f" % sim.clock_of(3))
	_check(is_equal_approx(sim.clock_for_head(t0, float(t0["plain_hp"]) * 10.0), Data.CLOCK_PER_HEAD * 10.0), "a head ten heads strong does not bring ten heads' time")
	# it runs while they're on you, and stands while the site's clear
	sim.hp = sim.max_hp()
	sim.deploy(3)
	var m: Dictionary = sim.mission
	_check(m != null and is_equal_approx(float(m["clock"]), sim.clock_budget(m["t"])) and is_equal_approx(float(m["clock_max"]), float(m["clock"])), "the run did not start on the site's clock")
	m["target_hp"] = 1e12
	sim.hp = 1e9
	var c0: float = float(m["clock"])
	sim.advance(2.0)
	_check(sim.on_mission() and is_equal_approx(float(m["clock"]), c0 - 2.0), "the clock did not run in the fight: %.1f from %.1f" % [float(m["clock"]), c0])
	main.show_room(main.MISSIONS)
	main.refresh()
	var rs = main._run
	_check(rs._band.headline.text == Fmt.mss(ceilf(float(m["clock"]))) and rs._band.unit.text.begins_with("left"), "the run's headline is not the clock: '%s' / '%s'" % [rs._band.headline.text, rs._band.unit.text])
	_check_fit(main, "Run (the clock)")
	m["remaining"] = 0
	m["cleared"] = true
	m["patrol_timer"] = -1e9                     # no gang for a while
	var c1: float = float(m["clock"])
	sim.advance(3.0)
	_check(sim.on_mission() and is_equal_approx(float(m["clock"]), c1), "the clock ran while the site was clear: %.1f from %.1f" % [float(m["clock"]), c1])
	main.refresh()
	_check(rs._band.unit.text.contains("stopped") or rs._band.unit.text == "left", "the run's clock does not say it's stopped: '%s'" % rs._band.unit.text)
	# out of time: the runner home, the pack lost, two pieces of kit with it
	m["remaining"] = 5
	m["cleared"] = false
	m["target_hp"] = 1e12
	var junk: Dictionary = sim._plain("Helmet", "Hard hat")
	m["found"].append(junk)
	for s in ["Helmet", "Armour", "Secondary"]:
		if sim.equipped[s] == null:
			sim.equipped[s] = sim._plain(s, Data.BASES[s][0]["name"])
	var worn0: int = 0
	var ids0 := {}
	for s in Data.SLOTS:
		worn0 += 1 if sim.equipped[s] != null else 0
		ids0[s] = sim.equipped[s]["id"] if sim.equipped[s] != null else -1
	var lost0: int = sim.operators_lost
	var auto_eq0 = sim.auto_equip
	sim.auto_equip = false                       # the slot check reads the kit as the clock left it
	m["clock"] = 0.5
	sim.advance(1.0)
	var worn1: int = 0
	for s in Data.SLOTS:
		worn1 += 1 if sim.equipped[s] != null else 0
	_check(not sim.on_mission() and sim.last_report.get("outcome", "") == "Out of time" and sim.operators_lost == lost0 and sim.hp > 0.0, "running out of time did not end the run with the runner home: %s" % str(sim.last_report.get("outcome", "")))
	var fresh := 0
	for s in Data.SLOTS:
		if sim.equipped[s] != null and sim.equipped[s]["base"] in ["Hand-me-down nail gun", "Work jacket", "Plastic bag", "Bum bag"] and int(sim.equipped[s]["rarity"]) == 0:
			fresh += 1
	_check(worn0 - worn1 + fresh >= Data.CLOCK_LOSE_KIT and worn1 >= worn0 - Data.CLOCK_LOSE_KIT and (not sim.stash.has(junk) or sim.yard_has("fetch")), "out of time lost %d pieces of kit (%d hand-me-downs in), or the pack came home" % [worn0 - worn1, fresh])
	_check(sim.equipped["Primary"] != null, "out of time left the runner with no gun")
	var changed := 0
	for s in Data.SLOTS:
		var id1: int = sim.equipped[s]["id"] if sim.equipped[s] != null else -1
		changed += 1 if id1 != ids0[s] else 0
	_check(changed == Data.CLOCK_LOSE_KIT, "out of time changed %d slots, not %d" % [changed, Data.CLOCK_LOSE_KIT])
	sim.auto_equip = auto_eq0
	_check(sim.events.slice(-4).any(func(ev): return str(ev[1]).begins_with("Out of time")), "out of time has no line")
	# insured, the kit comes back to the stash
	for s in ["Helmet", "Armour", "Secondary"]:
		if sim.equipped[s] == null:
			sim.equipped[s] = sim._plain(s, Data.BASES[s][0]["name"])
	sim.cash += 1e6
	sim.hp = sim.max_hp()
	if sim.can_insure(3):
		sim.set_insure(true)
	sim.deploy(3)
	m = sim.mission
	_check(m != null and m.get("insured", false), "the insured time-out test could not insure its run")
	if m != null and m.get("insured", false):
		var stash0: int = sim.stash.size()
		m["clock"] = 0.5
		m["target_hp"] = 1e12
		sim.hp = 1e9
		sim.advance(1.0)
		_check(not sim.on_mission() and sim.stash.size() >= stash0 + Data.CLOCK_LOSE_KIT, "the insurance did not pay for the kit lost to the clock: %d → %d" % [stash0, sim.stash.size()])
	elif m != null:
		sim.extract_now()
	# the dry runs read the clock: out of time is a run lost
	var dm := {"dry": true}
	sim._time_out(dm)
	_check(dm.get("dead", false) and dm.get("timed_out", false), "a dry run out of time did not read as lost")
	# and a real dry run: fists against the streets, the runner unkillable, loses to the clock
	var gun0 = sim.equipped["Primary"]
	var sec0 = sim.equipped["Secondary"]
	var hat0 = sim.equipped["Helmet"]
	var hp0: float = sim.hp
	sim.equipped["Primary"] = null
	sim.equipped["Secondary"] = null      # fists means fists: a good secondary took the streets in time (10 Oct)
	var hat: Dictionary = sim._plain("Helmet", Data.BASES["Helmet"][0]["name"])
	hat["affixes"].append({"stat": "hp", "value": 1e7})          # a runner who can't go down: only the clock beats him
	sim.equipped["Helmet"] = hat
	sim.hp = sim.max_hp()
	var to0: int = int(sim.prof.get("dry_timeouts", 0))
	var rr := RandomNumberGenerator.new()
	rr.seed = 7
	var won: bool = sim._dry_run(3, rr)
	_check(not won and int(sim.prof.get("dry_timeouts", 0)) == to0 + 1, "fists against the streets' clock did not time out in the odds (won %s)" % str(won))
	# the Runs card goes red when the fight won't fit
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(1)
	main._missions._shown = ""
	main.refresh()
	var cr: Dictionary = main._missions._cols[0]
	var t00 = Data.ZONES[1]["tiers"][0]
	_check(sim.estimate(t00) > sim.clock_of(t00) and cr["tiles"][2]["value"].get_theme_color("font_color") == Pal.BAD, "fists' Runs card is not red over the clock: %.0f of %.0f" % [sim.estimate(t00), sim.clock_of(t00)])
	sim.equipped["Primary"] = gun0
	sim.equipped["Secondary"] = sec0
	sim.equipped["Helmet"] = hat0
	sim.hp = hp0
	# the Runs card: the clock beside the fight, red when the fight won't fit
	sim.load_dict(saved)
	main.show_room(main.MISSIONS)
	main._missions._pick_zone(1)
	main._missions._shown = ""
	main.refresh()
	var c: Dictionary = main._missions._cols[0]
	_check(c["tiles"][2]["value"].text.contains(Fmt.mss(sim.clock_of(Data.ZONES[1]["tiers"][0]))), "the Runs card's clock is off: '%s'" % c["tiles"][2]["value"].text)
	var red: bool = c["tiles"][2]["value"].get_theme_color("font_color") == Pal.BAD
	_check(red == (sim.estimate(Data.ZONES[1]["tiers"][0]) > sim.clock_of(Data.ZONES[1]["tiers"][0])), "the Runs card's clock is red when it shouldn't be, or not when it should")
	_check_fit(main, "Runs (the clock)")
	sim.load_dict(saved)
	main.refresh()
	print("run timers ok: the budget, the head's time, ticking only in a fight, out of time, the insurance, the dry runs, the screens")


## A joint's halves meet at the line (Matt, 10 Oct): this pair's half on the upper lane's bottom row or the lower's
## top row; any other class's half in that column (a second past's) off it.
func _check_joint_rows(bk, k: int) -> void:
	var sim = bk.sim
	var lane: Dictionary = bk._lanes[k]
	var lt = lane["tree"]
	var want: int = 1 if k % 2 == 0 else 0
	var pair: Dictionary = Data.joint_in(sim.cls, lt["name"])
	var col := -1
	for i in range(lt["nodes"].size()):
		if not pair.is_empty() and str(lt["nodes"][i].get("joint", "")) == str(pair["key"]):
			col = int(lt["nodes"][i].get("col", 0))
			_check(int(lane["rows"][i]) == want, "%s's joint half is on row %d, not at the line (second past %s)" % [lt["name"], int(lane["rows"][i]), sim.cls2])
	for i in range(lt["nodes"].size()):
		var nd: Dictionary = lt["nodes"][i]
		if int(nd.get("col", 0)) == col and str(nd.get("joint", "")) != str(pair["key"]):
			_check(int(lane["rows"][i]) != want, "%s: another half sits at the line (second past %s)" % [lt["name"], sim.cls2])


## Every visible label's text under a node, for checks on what a panel says.
func _texts(n: Node) -> Array:
	var out: Array = []
	if n is CanvasItem and not n.visible:
		return out
	if n is Label and n.text != "":
		out.append(n.text)
	for c in n.get_children():
		out.append_array(_texts(c))
	return out


## The playtest record (11 Oct): what the player does lands in sim.chronicle, a dry run adds nothing, the record
## rides the save and the move, the clock at the game snapshots every ten minutes, and the read makes its page from it.
func _chronicle_checks() -> void:
	var s = Sim.new()
	s.start()
	var kinds := func() -> Dictionary:
		var k := {}
		for e in s.chronicle:
			k[e["k"]] = int(k.get(e["k"], 0)) + 1
		return k
	s.cash += 100000.0
	s.set_class("Doorman")
	_check(kinds.call().get("class", 0) == 1, "a class change wrote no line: %s" % str(kinds.call()))
	var n0: int = s.chronicle.size()
	s.survival(3)                                  # the odds: dry runs
	_check(s.chronicle.size() == n0, "a dry run wrote %d lines to the record" % (s.chronicle.size() - n0))
	for i in range(4):
		s.deploy(0)
		var guard := 0
		while s.on_mission() and guard < 3000:
			s.hp = s.max_hp()                      # kept alive: a death would hand the record a fresh, classless runner
			s.advance(1.0)
			guard += 1
		if s.on_mission():
			s.extract_now()
	_check(s.cls == "Doorman", "the record's runner died on tier 1")
	var lv0: int = s.level()
	while s.level() < lv0 + 3:
		s.xp += 50.0
	s._earn_points(lv0)                           # what a run's XP does on the way back
	var k: Dictionary = kinds.call()
	_check(k.get("run", 0) == 4, "four runs wrote %d run lines" % k.get("run", 0))
	_check(k.get("level", 0) >= 1 and s.level() > 1, "levelling to %d wrote no level line" % s.level())
	_check(s.chronicle.filter(func(e): return e["k"] == "level")[-1].get("to", 0) == s.level(), "the level line does not read the level reached")
	var run: Dictionary = s.chronicle.filter(func(e): return e["k"] == "run")[0]
	for f in ["t", "p", "w", "lv", "cls", "yard", "tier", "site", "outcome", "time", "kills", "of", "dps", "kit"]:
		_check(run.has(f), "a run line has no '%s': %s" % [f, str(run.keys())])
	_check(s.train_node("Muscle/0"), "Muscle/0 did not train for the record: %s" % s.train_block("Muscle/0"))
	_check(kinds.call().get("train", 0) == 1, "training wrote no line")
	_check(s.yard_pick("generator", 0, "a"), "the generator pick did not buy: %s" % s.yard_pick_block("generator", 0, "a"))
	_check(kinds.call().get("yard", 0) == 1, "a yard pick wrote no line")
	# the clock at the game: a snapshot each SNAP_S played, none between
	var snaps0: int = kinds.call().get("snap", 0)
	for i in range(int(Sim.SNAP_S * 2.5)):
		s.tick_played(1.0)
	_check(kinds.call().get("snap", 0) - snaps0 == 2, "two and a half snapshots' time played wrote %d" % (kinds.call().get("snap", 0) - snaps0))
	# the save carries the count and the clock, never the lines (they go to the record file: _record_file_checks)
	_check(s.chron_count == s.chronicle.size(), "the record counts %d lines and holds %d" % [s.chron_count, s.chronicle.size()])
	var d: Dictionary = s.to_dict()
	_check(not d.has("chronicle"), "the save carries the record's lines")
	var t = Sim.new()
	t.load_dict(JSON.parse_string(JSON.stringify(d)))
	_check(t.chron_count == s.chron_count and t.chronicle.is_empty() and absf(t.played_s - s.played_s) < 0.01, "the count and the clock did not ride the save: %d of %d lines, %.0f of %.0f s" % [t.chron_count, s.chron_count, t.played_s, s.played_s])
	t.tick_played(1.0)
	_check(t.chronicle.is_empty(), "a loaded save snapshotted again at once")
	# a save from the first build (v1) carried its lines: they wait to go out to the file, none lost
	var v1: Dictionary = d.duplicate()
	v1.erase("chron_count")
	v1["chronicle"] = [{"k": "start", "t": 0.0, "p": 0.0}, {"k": "run", "t": 10.0, "p": 10.0}]
	var u = Sim.new()
	u.load_dict(JSON.parse_string(JSON.stringify(v1)))
	_check(u.chronicle.size() == 2 and u.chron_count == 2, "a v1 save's record was dropped on loading: %d waiting, %d counted" % [u.chronicle.size(), u.chron_count])
	var kept: int = s.chronicle.size()
	_finish_campaign(s)
	_check(s.can_move_yard(), "the record's sim cannot move yard")
	if s.move_yard():
		_check(s.chronicle.size() == kept + 1 and s.chron_count == kept + 1 and s.chronicle[-1]["k"] == "move" and s.played_s > 0.0, "the move lost the record: %d lines of %d" % [s.chronicle.size(), kept + 1])
	# the read
	var page: String = PlaytestRead.summarize(s.to_dict(), s.chronicle, "smoke")
	for h in ["## The time", "## Milestones", "## The gates, read from play", "## Runs, site by site", "## Hour by hour", "## Where the money and the points went", "## The kit, as it changed"]:
		_check(page.contains(h), "the playtest read has no '%s'" % h)
	_check(page.contains("Class: none to Doorman") and page.contains("Level "), "the playtest read's milestones miss the class or a level")


## The record file (11 Oct, the reviewer): the lines go to the .record.jsonl beside the save on each save and leave
## the sim; a slot takes a copy and brings it back; a new game moves the old record aside; the read takes the save
## through JSON with the file, as on the player's machine.
func _record_file_checks(main) -> void:
	main.new_game()
	var rec: String = main.record_file()
	_check(rec == SMOKE_SAVE.get_basename() + ".record.jsonl", "the smoke's record is at %s" % rec)
	_check(main.sim.chronicle.is_empty() and PlaytestRead.read_record(rec).size() == main.sim.chron_count and main.sim.chron_count >= 1, "a new game's save did not write its start to the record: %d in the file, %d counted, %d waiting" % [PlaytestRead.read_record(rec).size(), main.sim.chron_count, main.sim.chronicle.size()])
	_set_cls(main.sim, "Doorman")
	main.sim.cash += 100000.0
	main.sim.yard_pick("generator", 0, "a")
	for i in range(int(Sim.SNAP_S) + 1):
		main.sim.tick_played(1.0)
	main.save_game()
	var lines: Array = PlaytestRead.read_record(rec)
	_check(lines.size() == main.sim.chron_count and main.sim.chronicle.is_empty(), "the save left the record at %d lines of %d" % [lines.size(), main.sim.chron_count])
	_check(lines.any(func(e): return e["k"] == "class") and lines.any(func(e): return e["k"] == "yard") and lines.any(func(e): return e["k"] == "snap"), "the record file misses the class, the pick or the snapshot: %s" % str(lines.map(func(e): return e["k"])))
	var bytes := FileAccess.get_file_as_string(SMOKE_SAVE).length()
	main.save_game()
	_check(PlaytestRead.read_record(rec).size() == lines.size() and absi(FileAccess.get_file_as_string(SMOKE_SAVE).length() - bytes) < 200, "a second save wrote the record again or grew the save")
	# a slot takes the record with it
	main.save_game(SMOKE_SLOT % 3)
	_check(PlaytestRead.read_record(main.record_file(SMOKE_SLOT % 3)).size() == lines.size(), "the slot did not take the record")
	# loading: a session line, ahead of the settle's runs
	main.load_game(SMOKE_SAVE)
	main.save_game()
	var after: Array = PlaytestRead.read_record(rec)
	_check(after.size() == lines.size() + 1 and after[-1]["k"] == "session", "loading did not write one session line: %s" % str(after.slice(lines.size()).map(func(e): return e["k"])))
	# the read, from the files as the player has them: the save through JSON, every number a float
	var d: Dictionary = main._read_save(SMOKE_SAVE)
	var page: String = PlaytestRead.summarize(d["sim"], PlaytestRead.read_record(rec), SMOKE_SAVE)
	_check(page.contains("## Milestones") and page.contains("Class: none to Doorman") and page.contains("## Hour by hour") and not page.contains("were lost") and not page.contains("past the save"), "the read from the files is short: %s" % page.substr(0, 300))
	# a slot loaded brings its record back as the autosave's, the one there moved aside
	main.sim.chron("after the slot")
	main.save_game()
	main.load_game(SMOKE_SLOT % 3)
	_check(PlaytestRead.read_record(rec).size() == lines.size(), "the loaded slot's record is not the autosave's: %d lines, not %d" % [PlaytestRead.read_record(rec).size(), lines.size()])
	var kept: Array = Array(DirAccess.get_files_at("user://")).filter(func(f): return f.begins_with(SMOKE_SAVE.get_file().get_basename() + ".record.") and f != rec.get_file())
	_check(not kept.is_empty(), "the autosave's record was not kept aside when the slot came in")
	# a new game starts an empty record and keeps the old one
	main.new_game()
	_check(PlaytestRead.read_record(rec).size() == main.sim.chron_count and main.sim.chron_count <= 2, "a new game's record holds the last game's lines: %d" % PlaytestRead.read_record(rec).size())


## The junk rules (11 Oct, Matt's list): the rarity the Fence takes up to, never an upgrade on what's worn, never a
## kind kept, the buttons going round, the line saying it, an old save's toggle read as commons, the rules saved.
func _junk_rule_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	main.show_room(main.ARMOURY)
	main._armoury.selected = {}
	sim.junk_upto = -1
	sim.junk_keep = ""
	main.refresh()
	var words := []
	for k in range(4):
		main._armoury._toggle(1)
		words.append(main._armoury._toggles[1].text)
		_check_fit(main, "Lock-up (sell %s)" % main._armoury._toggles[1].text)
	_check(words == ["Sell: commons", "Sell: to uncommon", "Sell: to rare", "Sell: off"] and sim.junk_upto == -1, "the sell rule does not go round: %s" % str(words))
	_check(main._armoury._toggles[2].disabled, "the keep rule is live with nothing sold")
	main._armoury._toggle(1)
	main._armoury._toggle(1)                  # to uncommon
	var keeps := []
	for k in range(sim.JUNK_KEEPS.size()):
		main._armoury._toggle(2)
		keeps.append(sim.junk_keep)
		_check_fit(main, "Lock-up (keep %s)" % main._armoury._toggles[2].text)
	_check(keeps == ["guns", "body", "bags", "parts", ""], "the keep rule does not go round: %s" % str(keeps))
	_check(main._armoury.junk_words(sim).contains("commons and uncommons") and main._armoury.junk_words(sim).contains("never an upgrade"), "the rules' line is off: %s" % main._armoury.junk_words(sim))
	# what goes: an uncommon spare under what's worn; what stays: a rare, an upgrade, a kept kind
	sim.equipped["Armour"] = sim._plain("Armour", "Riot suit")
	sim.equipped["Helmet"] = sim._plain("Helmet", "Visored helmet")
	var spare: Dictionary = sim._plain("Helmet", "Cycle helmet")
	spare["rarity"] = 1
	var rare: Dictionary = sim._plain("Helmet", "Cycle helmet")
	rare["rarity"] = 2
	var up: Dictionary = sim._plain("Armour", "Riot suit")
	up["rarity"] = 1
	up["affixes"] = [{"stat": "hp", "value": 60.0, "tier": 3}]
	var gun: Dictionary = sim._plain("Secondary", "Knife")
	gun["rarity"] = 0
	_check(sim.is_upgrade(up) and not sim.is_upgrade(spare), "the upgrade reads wrong: up %s, spare %s" % [sim.is_upgrade(up), sim.is_upgrade(spare)])
	sim.junk_keep = "guns"
	_check(sim.is_junk(spare) and not sim.is_junk(rare) and not sim.is_junk(up) and not sim.is_junk(gun), "the rules read wrong: spare %s rare %s upgrade %s gun %s" % [sim.is_junk(spare), sim.is_junk(rare), sim.is_junk(up), sim.is_junk(gun)])
	sim.junk_keep = ""
	_check(sim.is_junk(gun) == (not sim.is_upgrade(gun)), "with nothing kept the gun is not by the other rules")
	sim.junk_upto = -1
	_check(not sim.is_junk(spare), "the rules sell with the rule off")
	# the save: the rules, and an old save's toggle as commons
	sim.junk_upto = 2
	sim.junk_keep = "bags"
	var d: Dictionary = JSON.parse_string(JSON.stringify(sim.to_dict()))
	sim.load_dict(d)
	_check(sim.junk_upto == 2 and sim.junk_keep == "bags", "the rules did not save: %d %s" % [sim.junk_upto, sim.junk_keep])
	d.erase("junk_upto")
	d.erase("junk_keep")
	d["auto_sell"] = true
	sim.load_dict(d)
	_check(sim.junk_upto == 0 and sim.junk_keep == "", "an old save's junk toggle is not commons: %d" % sim.junk_upto)
	sim.load_dict(saved)
	main.refresh()
	print("junk rules ok: the rarity, the upgrade kept, the kind kept, the buttons, the line, the save")


## The upgrade's arrow (11 Oct, Matt's list): on a stash item that beats what's worn in its slot, nowhere else, gone
## once it's on; inside its cell; in the pack and on the Fence's shelf the same.
func _upgrade_arrow_checks(main) -> void:
	var sim = main.sim
	var saved: Dictionary = sim.to_dict()
	while not sim.stash_room(12) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])
	sim.equipped["Helmet"] = sim._plain("Helmet", "Hard hat")
	var better: Dictionary = sim._plain("Helmet", "Visored helmet")
	var worse: Dictionary = sim._plain("Helmet", "Cycle helmet")
	sim.stash_put(better)
	sim.stash_put(worse)
	main.show_room(main.ARMOURY)
	main._armoury.selected = {}
	main._armoury._inv.kind = 0
	main._armoury._inv.rarity = -1
	main.refresh()
	var inv = main._armoury._inv
	var cb = inv.cell_node(inv.cell_of(better["id"]))
	var cw = inv.cell_node(inv.cell_of(worse["id"]))
	_check(cb != null and cb._up.visible and cw != null and not cw._up.visible, "the arrow is not on the better helmet alone: better %s, worse %s" % [cb != null and cb._up.visible, cw != null and cw._up.visible])
	if cb != null:
		_check(Rect2(Vector2.ZERO, cb.size).encloses(Rect2(cb._up.position, cb._up.size)), "the arrow leaves its cell")
	_check_fit(main, "Lock-up (an upgrade's arrow)")
	for slot in Data.SLOTS:
		var c = main._armoury._body._boxes[slot]["cell"]
		_check(not c._up.visible, "a worn %s carries the arrow" % slot)
	sim.equip_item(better["id"])
	main.refresh()
	var cw2 = inv.cell_node(inv.cell_of(worse["id"]))
	var hard = inv.cell_node(inv.cell_of(sim.stash.filter(func(x): return x["base"] == "Hard hat")[0]["id"])) if sim.stash.any(func(x): return x["base"] == "Hard hat") else null
	_check(cw2 != null and not cw2._up.visible and (hard == null or not hard._up.visible), "an arrow stayed once the better helmet went on")
	sim.load_dict(saved)
	main.refresh()
	_try_on_checks(main)
	print("upgrade arrows ok: the better piece alone, inside its cell, never on the body, gone once worn")


## Tried on (11 Oct, Matt: the Van's Spare's +18% damage read worse than a machine pistol that cost him damage):
## better is the runner's damage with the piece worn, so the verdict, the arrow, the deltas, the junk rules and
## Equip if better all agree with the top bar; and a plain better piece still reads better.
func _try_on_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	while not sim.stash_room(12) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])
	var vans: Dictionary = Items.roll_unique(sim._unique_named("The Van's Spare"), sim.rng)
	vans["base"] = "Old revolver"            # the case as Matt met it (11 Oct), on its old body: tiered (12 Oct) it rolls at T3 or up
	vans["tier"] = 2
	vans["attachments"] = {"optic": null}
	sim.equipped["Secondary"] = vans
	var mp: Dictionary = sim._plain("Secondary", "Machine pistol")
	mp["affixes"] = [{"stat": "damage_pct", "value": 10.0, "tier": 2}]
	sim.stash_put(mp)
	_check(Items.score(mp) > Items.score(vans), "the case no longer stands: the pistol's own score is under the Van's Spare's")
	var before: float = sim.fit_value({}, "Secondary")
	var with_mp: float = sim.fit_value(mp)
	_check(with_mp < before and sim.compare(mp) == -1 and not sim.is_upgrade(mp), "the machine pistol over the Van's Spare reads %d (%.1f against %.1f dmg/s)" % [sim.compare(mp), with_mp, before])
	sim.auto_equip = true
	_check(not sim.equip_best("Secondary") and sim.equipped["Secondary"]["id"] == vans["id"], "Equip if better put the pistol on over the Van's Spare")
	sim.junk_upto = 2
	_check(sim.is_junk(mp), "the junk rules keep the pistol that costs damage")
	main.show_room(main.ARMOURY)
	main._armoury.selected = {"kind": "stash", "id": mp["id"]}
	main.refresh()
	var cell = main._armoury._inv.cell_node(main._armoury._inv.cell_of(mp["id"]))
	_check(cell != null and not cell._up.visible, "the pistol that costs damage carries the arrow")
	_check(main._armoury._pick._verdict.text == "▼ Downgrade", "the verdict on the pistol reads '%s'" % main._armoury._pick._verdict.text)
	var ds: Array = PickPanel.deltas_for(sim, mp, vans)
	_check(not ds.is_empty() and float(ds[0][0]) < 0.0 and str(ds[0][1]).ends_with("dmg/s"), "the deltas don't lead with the damage lost: %s" % str(ds))
	_check_fit(main, "Lock-up (a pistol against the Van's Spare)")
	# the other way: the Van's Spare over the pistol is the upgrade, and Equip if better takes it
	sim.equipped["Secondary"] = mp
	sim.stash.erase(mp)
	sim.stash_put(vans)
	_check(sim.compare(vans) == 1 and sim.equip_best("Secondary") and sim.equipped["Secondary"]["id"] == vans["id"], "the Van's Spare over the pistol is not the upgrade")
	# a plain better vest still reads better; the same vest a trade when it costs the damage a worn helmet gave
	var vest: Dictionary = sim._plain("Armour", "Stab vest")
	sim.equipped["Armour"] = vest
	var riot: Dictionary = sim._plain("Armour", "Riot suit")
	_check(sim.compare(riot) == 1, "a riot suit over a stab vest is not the upgrade")
	var dmg_vest: Dictionary = sim._plain("Armour", "Stab vest")
	dmg_vest["affixes"] = [{"stat": "damage_pct", "value": 30.0, "tier": 4}]
	sim.equipped["Armour"] = dmg_vest
	_check(sim.compare(riot) == 0, "a riot suit that costs the vest's damage is not a trade: %d" % sim.compare(riot))
	# the answers hold through a run's shooting: rounds spent aren't a change of kit (the first cut threw them away
	# each second, the rig's counts in the key)
	sim.load_dict(saved)
	if sim.equipped["Primary"] == null or Items.ammo_type(sim.equipped["Primary"]) in ["none", ""]:
		sim.equipped["Primary"] = sim._plain("Primary", "Pipe shotgun")     # a gun that spends rounds (the Allotments lean to melee: 12 Oct)
	var box: Dictionary = sim.ammo_box(Items.ammo_type(sim.equipped["Primary"]))
	if not box.is_empty():
		sim.rig.push_front(sim._plain(Data.AMMO, box["name"]))     # fed whatever the smoke left in the rig
	sim.rig.append(sim._plain(Data.MEDICAL, "Bandage"))
	sim.hp = sim.max_hp()
	sim.deploy(3)
	sim.mission["target_hp"] = 1e9
	sim.advance(1.0)
	var k0: int = sim._kit_key()
	var r0: int = sim.rounds_for(sim.equipped["Primary"]) if sim.equipped["Primary"] != null else 0
	for k in range(5):
		sim.hp = sim.max_hp()
		sim.advance(1.0)
	var r1: int = sim.rounds_for(sim.equipped["Primary"]) if sim.equipped["Primary"] != null else 0
	_check(r1 < r0 and sim._kit_key() == k0, "the try-on's answers were thrown away by rounds spent (%d -> %d rounds, key %s)" % [r0, r1, "same" if sim._kit_key() == k0 else "changed"])
	# but a thing leaving the rig is a change (armour a med, the review): a med used throws them away
	var med: Dictionary = sim.first_med()
	if not med.is_empty():
		sim.use_med(med["id"])
		_check(sim._kit_key() != k0, "a med used left the try-on's answers standing (armour a med counts the rig)")
	sim.extract_now()
	sim.load_dict(saved)
	main._armoury.selected = {}
	main.refresh()
	print("tried on ok: the Van's Spare kept, the arrow, the verdict, the deltas, the junk, equip if better, a trade, held through a run")


## What came back (11 Oct, Matt's list): every run since the last Seen added up on a card over the Runs screen -
## the runs, cash, XP, items, levels, the dearest find, the firsts - over a column the last run didn't come from,
## put away by Seen, kept by the save, never added to by a dry run.
func _came_back_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.came_back_seen()
	main.show_room(main.MISSIONS)
	main._missions.zone = 0
	main.refresh()
	_check(not main._missions._came.visible, "the card shows with no run since Seen")
	sim.survival(3)
	_check(int(sim.came_back["runs"]) == 0, "a dry run added to what came back")
	var cash0: float = sim.cash
	for k in range(2):
		sim.hp = sim.max_hp()
		sim.deploy(3)
		var g := 0
		while sim.on_mission() and g < 3000:
			sim.hp = sim.max_hp()
			sim.advance(1.0)
			g += 1
		if sim.on_mission():
			sim.extract_now()
	var cb: Dictionary = sim.came_back
	_check(int(cb["runs"]) == 2, "two runs read %d on the card" % int(cb["runs"]))
	_check(float(cb["xp"]) > 0.0 and float(cb["cash"]) >= 0.0, "the card's XP and cash did not add: %s" % str(cb))
	# a find, a first and a level, as a run would bring them
	var find: Dictionary = sim._plain("Armour", "Riot suit")
	find["rarity"] = 3
	find["value"] = 99999
	sim.stash_put(find)
	sim._came_back_find(find)
	var cheap: Dictionary = sim._plain("Helmet", "Cycle helmet")
	sim._came_back_find(cheap)
	_check(int(sim.came_back["find"]["id"]) == int(find["id"]), "the card's find is not the dearest")
	for k in range(6):
		sim.chron("clear", {"site": "Test site %d" % k, "depth": 2 + k, "first": k == 0})
	_check(sim.came_back["firsts"].size() == sim.CAME_BACK_FIRSTS and int(sim.came_back["more"]) >= 2, "the firsts did not cap: %s" % str(sim.came_back["firsts"]))
	var lv0: int = sim.level()
	sim.came_back["lv_from"] = lv0
	while sim.level() < lv0 + 2:
		sim.xp += 50.0
	main.refresh()
	var card = main._missions._came
	_check(card.visible, "the card did not show after two runs")
	_check(card._head.text.begins_with("WHAT CAME BACK · 2 RUNS"), "the card's head reads '%s'" % card._head.text)
	_check(card._tiles[3]["value"].text.contains("→"), "the card's level does not read the climb: '%s'" % card._tiles[3]["value"].text)
	_check(card._cell.visible and card._find_name.text.begins_with(Items.full_name(find).get_slice(" ", 0)) and card._find_line.text.contains(Fmt.money(99999.0)), "the card's find is off: '%s' / '%s'" % [card._find_name.text, card._find_line.text])
	_check(card._firsts[card.FIRSTS - 1].text.begins_with("and ") and card._firsts.any(func(l): return l.text == "First clear: Test site 0"), "the card's firsts read: %s" % str(card._firsts.map(func(l): return l.text)))
	var col0 := Rect2(0, 0, main._missions.COL_W, Pal.ROOM_H)
	_check(not Rect2(card.position, card.size).intersects(col0), "the card sits over the column the run came from (tier 1)")
	_check(Rect2(Vector2.ZERO, main._missions.size).encloses(Rect2(card.position, card.size)), "the card leaves the Runs screen")
	_check_fit(main, "Runs (what came back)")
	_came_back_buttons_clear(main, "the run from tier 1")
	# the endgame's figures in a quarter-width tile (the first smoke: £47,082 ran out of it)
	var hold_cb: Dictionary = sim.came_back.duplicate(true)
	sim.came_back["cash"] = 12345678.0
	sim.came_back["xp"] = 9876543.0
	sim.came_back["runs"] = 1234
	sim.came_back["deaths"] = 12
	main.refresh()
	_check_fit(main, "Runs (what came back, the endgame's figures)")
	sim.came_back = hold_cb
	main.refresh()
	# a run from the right-hand column puts it on the left
	sim.last_report["tier"] = Data.ZONES[main._missions.zone]["tiers"][2]     # the right-hand column of the zone on show
	main._missions._shown = ""
	main.refresh()
	_check(card.position.x == 0.0, "the card did not move off the right-hand column the run came from")
	_came_back_buttons_clear(main, "the run from tier 3")
	sim.last_report["tier"] = Data.ZONES[1]["tiers"][0]
	main.refresh()
	# the save keeps it; Seen puts it away and starts again
	var d: Dictionary = JSON.parse_string(JSON.stringify(sim.to_dict()))
	sim.load_dict(d)
	_check(int(sim.came_back["runs"]) == 2 and int(sim.came_back["find"]["id"]) == int(find["id"]), "the save lost what came back")
	main.refresh()
	card._on_seen()
	main.refresh()
	_check(not card.visible and int(sim.came_back["runs"]) == 0 and sim.came_back["firsts"].is_empty() and int(sim.came_back["lv_from"]) == sim.level(), "Seen did not put the card away and start again")
	sim.load_dict(saved)
	main.refresh()
	# a move keeps the tally (an away move mustn't wipe it), the climb from the new runner's level
	var y = Sim.new()
	y.start()
	y.came_back["runs"] = 3
	y.came_back["firsts"] = ["First clear: Somewhere"]
	_finish_campaign(y)
	_check(y.move_yard() and int(y.came_back["runs"]) == 3 and y.came_back["firsts"].size() == 2 and int(y.came_back["lv_from"]) == y.level(), "the move wiped what came back: %s" % str(y.came_back))
	print("what came back ok: the runs, the money, the find, the firsts capped, the level, the column, the buttons clear, the save, the move, Seen")


## No button on the Runs screen under the card: the column it sits over keeps its Set off, auto and insure clear.
func _came_back_buttons_clear(main, where: String) -> void:
	var card = main._missions._came
	var cr: Rect2 = card.get_global_rect()
	for c in main._missions._cols:
		for b in [c["deploy"], c["auto"], c["depth_down"], c["depth_up"], c["boss"], c["insure"]]:
			if b.is_visible_in_tree():
				_check(not cr.intersects(b.get_global_rect()), "the card covers '%s' (%s)" % [b.text, where])
		if c["note"].text != "":
			_check(not cr.intersects(c["note"].get_global_rect()), "the card covers the column's note '%s' (%s)" % [c["note"].text, where])


## The rig on a run (11 Oct, Matt): the best grade of a gun's rounds fires first and the next takes over; rounds go
## from the rig into the pack (a better gun's rounds need the pouch); a med says what it heals, on the hover and in
## the pick, the heal is that figure, and the log says what it healed after the cap.
func _rig_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.equipped["Primary"] = sim._plain("Primary", "Stalking rifle")
	sim.equipped["Secondary"] = null
	sim.rig.clear()
	var plain: Dictionary = sim._plain(Data.AMMO, "Rifle rounds")
	var depot: Dictionary = sim._plain(Data.AMMO, "Depot rounds")
	depot["rounds"] = 5
	sim.rig.append(plain)
	sim.rig.append(depot)
	var band: Dictionary = sim._plain(Data.MEDICAL, "Bandage")
	sim.rig.append(band)
	_check(sim.feed_stack(sim.equipped["Primary"]) == depot and sim.grade_bonus(sim.equipped["Primary"]) == 25.0, "the Depot rounds behind the plain ones don't fire first")
	sim.hp = sim.max_hp()
	sim.deploy(3)
	sim.mission["target_hp"] = 1e9
	var p0: int = int(plain["rounds"])
	var g := 0
	while sim.rig.has(depot) and g < 120:
		sim.hp = sim.max_hp()
		sim.advance(1.0)
		g += 1
	_check(not sim.rig.has(depot) and int(plain["rounds"]) <= p0, "the Depot rounds did not run out first (plain %d of %d)" % [int(plain["rounds"]), p0])
	sim.hp = sim.max_hp()
	sim.advance(2.0)
	_check(int(plain["rounds"]) < p0 and sim.feed_stack(sim.equipped["Primary"]) == plain, "the plain rounds did not take over when the Depot rounds ran out")
	# into the pack, from the run screen
	main.show_room(main.MISSIONS)
	main.refresh()
	var run_ui = main._run
	var k: int = sim.rig.find(plain)
	run_ui._rig_pressed(k)
	main.refresh()
	_check(run_ui._rig_pick == int(plain["id"]) and run_ui._pick._buttons[0].visible and run_ui._pick._buttons[0].text == "Into the pack" and not run_ui._pick._buttons[0].disabled, "the rig's rounds don't offer Into the pack")
	_check_fit(main, "Run (rounds picked in the rig)")
	run_ui._pick._press(0)
	main.refresh()
	_check(not sim.rig.has(plain) and sim.mission["found"].has(plain) and run_ui._rig_pick == -1, "Into the pack did not move the rounds")
	_check(not sim.can_rig_to_pack(band["id"]), "a med can be stowed in the pack")
	# no room: the button says so
	var stack2: Dictionary = sim._plain(Data.AMMO, "Rifle rounds")
	sim.rig.push_front(stack2)
	while sim.pack_used(sim.mission) < sim.capacity():
		sim.mission["found"].append(sim._plain(Data.MEDICAL, "Bandage"))
	run_ui._rig_pressed(0)
	main.refresh()
	_check(not sim.can_rig_to_pack(stack2["id"]) and run_ui._pick._buttons[0].disabled, "Into the pack is offered into a full pack")
	_check_fit(main, "Run (rounds picked, the pack full)")
	run_ui._rig_pressed(0)                   # a second tap lets go
	main.refresh()
	_check(run_ui._rig_pick == -1, "a second tap on the rounds did not let go")
	# a med in the pack says what it heals in the pick
	var spare: Dictionary = sim.mission["found"][sim.mission["found"].size() - 1]
	var kk: int = run_ui._inv.cell_of(spare["id"])
	if kk >= 0:
		run_ui._inv._pick(kk)
		main.refresh()
		_check(run_ui._pick._right_lines.any(func(l): return l.text.contains(sim.med_words(spare))), "the pack's med does not say what it heals")
		_check_fit(main, "Run (a med picked in the pack)")
		run_ui._inv.selected = -1
		main.refresh()
	# the med: the hover, the pick, the heal, the log
	var cell = null
	for c in run_ui._rig_cells:
		if c.visible and c.id == int(band["id"]):
			cell = c
	var words: String = sim.med_words(band)
	_check(words.begins_with("+%d HP" % int(round(sim.med_heal(band)))) and cell != null and cell.tooltip_text.contains(words), "the med's hover does not say what it heals: '%s'" % (cell.tooltip_text if cell != null else "no cell"))
	sim.hp = maxf(1.0, sim.max_hp() - sim.med_heal(band) - 20.0)
	var hp0: float = sim.hp
	sim.mission["target_hp"] = 1e9
	sim.mission["remaining"] = 0
	_check(sim.use_med(band["id"]), "the bandage would not use")
	var g2 := 0
	while sim.mission != null and sim.mission["using"] != null and g2 < 30:
		sim.advance(0.5)
		g2 += 1
	var line: String = ""
	for ev in sim.events:
		if str(ev[1]).begins_with("Bandage used: +"):
			line = str(ev[1])
	_check(line != "" and line.contains("+%d HP" % int(round(sim.med_heal(band)))), "the log does not say what the bandage healed: '%s' (HP %d to %d)" % [line, int(hp0), int(sim.hp)])
	sim.extract_now()
	# rounds moved to the pack come home to the rig (or the stash), not as loot, even with the stash full
	sim.hp = sim.max_hp()
	sim.rig.clear()
	var mine: Dictionary = sim._plain(Data.AMMO, "Rifle rounds")
	sim.rig.append(mine)
	while sim.stash_room(1):
		sim.stash.append(sim._plain("Helmet", "Cycle helmet"))
	sim.deploy(3)
	sim.mission["found"] = []
	_check(sim.rig_to_pack(mine["id"]), "the rounds would not go into the pack")
	sim.extract_now()
	_check(sim.rig.any(func(x): return int(x["id"]) == int(mine["id"])) and int(sim.last_report["loot"]) == 0, "the runner's rounds did not come home to the rig, or counted as loot (loot %d)" % int(sim.last_report["loot"]))
	_check(not mine.has("from_rig"), "the rounds came home still marked as the rig's")
	sim.load_dict(saved)
	main.refresh()
	print("rig ok: the best grade first and the next after, into the pack and its room, home to the rig, the med's hover, its heal and the log")


## Three calls of Matt's (11 Oct): a build's own element's rounds fire before a dearer grade; nothing reads as better
## than a worn unique without a clear margin; a gun with no rounds in the rig says so under its verdict.
func _build_rounds_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.equipped["Primary"] = sim._plain("Primary", "Stalking rifle")
	sim.rig.clear()
	var depot: Dictionary = sim._plain(Data.AMMO, "Depot rounds")
	var salted: Dictionary = sim._plain(Data.AMMO, "Salted rounds")
	sim.rig.append(depot)
	sim.rig.append(salted)
	sim.tree = []
	_check(sim.feed_stack(sim.equipped["Primary"]) == depot, "with no element trained the dearest grade does not fire first")
	sim.tree.append("The cold/0")
	_check(sim.build_elements().has("frost") and sim.feed_stack(sim.equipped["Primary"]) == salted, "a frost build does not fire its salted rounds before Depot: %s" % str(sim.build_elements()))
	sim.tree = []
	_check(sim.feed_stack(sim.equipped["Primary"]) == depot, "the frost rounds still fire first with the tree gone")
	# a respec to the same count is another build (the review): fire then frost, one node each
	sim.tree = ["Petrol/0"]
	sim.feed_stack(sim.equipped["Primary"])
	sim.tree = ["The cold/0"]
	_check(sim.feed_stack(sim.equipped["Primary"]) == salted, "a respec from fire to frost at the same count left the fire build's rounds order")
	# the secondary's grade is damage only: no element first for it. A fire build with SMGs both hands: the primary
	# fires the incendiary rounds first, the machine pistol behind it the belt links (dearer, damage only)
	sim.tree = ["Petrol/0"]
	sim.equipped["Primary"] = sim._plain("Primary", "Workshop SMG")
	sim.equipped["Secondary"] = sim._plain("Secondary", "Machine pistol")
	var belt: Dictionary = sim._plain(Data.AMMO, "Belt links")
	var fire: Dictionary = sim._plain(Data.AMMO, "Incendiary SMG rounds")
	sim.rig.append(belt)
	sim.rig.append(fire)
	_check(sim.feed_stack(sim.equipped["Primary"]) == fire and sim.feed_stack(sim.equipped["Secondary"]) == belt, "the primary and secondary don't each fire their own best: %s / %s" % [sim.feed_stack(sim.equipped["Primary"]).get("base", ""), sim.feed_stack(sim.equipped["Secondary"]).get("base", "")])
	sim.equipped["Secondary"] = null
	sim.equipped["Primary"] = sim._plain("Primary", "Stalking rifle")
	sim.tree = []
	# a worn unique gun is judged on the runner's damage like anything else: a pistol that beats the Van's Spare with
	# it on is the upgrade (a margin held the bot to it all game, the 11 Oct read)
	var vans: Dictionary = Items.roll_unique(sim._unique_named("The Van's Spare"), sim.rng)
	sim.equipped["Secondary"] = vans
	var pct := 0.0
	var found := false
	while pct < 400.0:
		var mp: Dictionary = sim._plain("Secondary", "Machine pistol")
		mp["affixes"] = [{"stat": "damage_pct", "value": pct, "tier": 3}]
		if sim.upgrade_gain(mp) > 0.02:
			found = true
			_check(sim.compare(mp) == 1, "a pistol %.0f%% better on the runner's damage does not read better than a worn Van's Spare" % (sim.upgrade_gain(mp) * 100.0))
			break
		pct += 5.0
	_check(found, "no pistol up to 400 per cent damage beat the Van's Spare: the case doesn't stand")
	# a gun with no rounds in the rig says so
	sim.equipped["Secondary"] = null
	sim.rig.clear()
	while not sim.stash_room(12) and not sim.stash.is_empty():
		sim.sell(sim.stash[0])
	var smg: Dictionary = sim._plain("Primary", "Workshop SMG")
	sim.stash_put(smg)
	main.show_room(main.ARMOURY)
	main._armoury.selected = {"kind": "stash", "id": smg["id"]}
	main._armoury._shown = ""
	main.refresh()
	_check(main._armoury._pick._words.text.begins_with("No rounds for it"), "a gun with no rounds in the rig does not say so: '%s'" % main._armoury._pick._words.text)
	# and over an empty slot, where it matters most
	sim.equipped["Primary"] = null
	main._armoury._shown = ""
	main.refresh()
	_check(main._armoury._pick._words.text.begins_with("No rounds for it"), "a gun for an empty slot with no rounds does not say so: '%s'" % main._armoury._pick._words.text)
	_check_fit(main, "Lock-up (a gun with no rounds, nothing fitted)")
	# both hints at once, on the run screen where the pick has Equip and Ditch beside it
	sim.equipped["Primary"] = sim._plain("Primary", "Stalking rifle")
	sim.rig = [sim._plain(Data.AMMO, "Rifle rounds")]       # rounds for the rifle, none for the SMG
	sim.hp = sim.max_hp()
	sim.deploy(3)
	sim.mission["target_hp"] = 1e9
	var big: Dictionary = sim._plain("Primary", "Workshop SMG")
	sim.mission["found"] = [big]
	while sim.pack_used(sim.mission) < sim.capacity():
		sim.mission["found"].append(sim._plain(Data.MEDICAL, "Bandage"))
	main.show_room(main.MISSIONS)
	main.refresh()
	main._run._inv._pick(main._run._inv.cell_of(big["id"]))
	main.refresh()
	var hw: String = main._run._pick._words.text
	_check(hw.begins_with("No rounds") and hw.contains("No room"), "the run's pick does not carry both hints: '%s'" % hw)
	_check_fit(main, "Run (no rounds and no room)")
	sim.extract_now()
	# a charm over a worn unique charm is never the upgrade (its rule is beyond the charm's score)
	var keys: Dictionary = Items.roll_unique(sim._unique_named("The Van Keys"), sim.rng)
	sim.equipped["Charm"] = keys
	var plain_charm: Dictionary = sim._plain("Charm", "Dog tag")
	plain_charm["rarity"] = 3
	plain_charm["affixes"] = [{"stat": "loot_pct", "value": 60.0, "tier": 5}]
	_check(sim.compare(plain_charm) != 1, "a plain charm reads better than the worn Van Keys")
	_check_fit(main, "Lock-up (a gun with no rounds)")
	sim.load_dict(saved)
	main._armoury.selected = {}
	main.refresh()
	print("build rounds ok: the build's element first, a worn unique gun judged like any other, no rounds said")


## The bar's skull (11 Oct, Matt): shown when what the dots still have to take off covers the HP left, on their bar
## and on yours; gone when it doesn't. Shown only - the fight goes on as it would.
func _skull_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	var saved: Dictionary = sim.to_dict()
	sim.hp = sim.max_hp()
	sim.deploy(3)
	var m: Dictionary = sim.mission
	main.show_room(main.MISSIONS)
	m["target_hp"] = 100.0
	m["dots"] = {"poison": 40.0}
	main.refresh()
	var run_ui = main._run
	_check(not run_ui._fight["skull"].visible, "the skull shows with the dots short of the HP left")
	m["dots"] = {"poison": 70.0, "fire": 40.0}
	main.refresh()
	_check(run_ui._fight["skull"].visible, "no skull with the dots covering the HP left (110 against 100)")
	var hp_before: float = m["target_hp"]
	_check(is_equal_approx(hp_before, 100.0), "the skull changed the fight")
	m["my_dots"] = {"bleed": sim.hp + 10.0}
	main.refresh()
	_check(run_ui._runner["skull"].visible, "no skull on your own bar with a bleed that will have you")
	m["my_dots"] = {}
	main.refresh()
	_check(not run_ui._runner["skull"].visible, "the skull stayed on your bar with nothing on you")
	_check(run_ui.dots_finish(50.0, {"bleed": 50.0}) and not run_ui.dots_finish(0.0, {"bleed": 5.0}) and not run_ui.dots_finish(50.0, {}), "dots_finish reads wrong")
	sim.extract_now()
	sim.load_dict(saved)
	main.refresh()
	print("skull ok: on their bar and yours when the dots cover what's left, gone when they don't")


## The Runner's cards (11 Oct, Matt): the slot's name floats over the card, not inside it, and a picked slot shows
## one frame - the gear's own cell is the card, the empty card's outline hidden under it. And the title's foot carries
## the version, not the window line.
func _card_frame_checks(main) -> void:
	var sim = main.sim
	if sim.on_mission():
		sim.extract_now()
	main.show_room(main.ARMOURY)
	var body = main._armoury._body
	for slot in Data.SLOTS:
		body._pick(slot)                      # as a press on the card: the Lock-up picks the slot
		main.refresh()
		var b: Dictionary = body._boxes[slot]
		var full: bool = sim.equipped[slot] != null
		_check(b["name"].position.y + b["name"].size.y <= body.TOP_STRIP + 0.5, "the %s label is not over its card" % slot)
		if full:
			_check(not b["outline"].visible and b["cell"].visible and is_equal_approx(b["cell"].position.y, float(body.TOP_STRIP)) and is_equal_approx(b["cell"].size.x, body.box_rect(slot).size.x), "the picked %s card shows two frames, or its gear doesn't fill it" % slot)
		else:
			_check(b["outline"].visible and b["outline"].position.y >= body.TOP_STRIP - 0.5, "the empty %s card has no outline under its label" % slot)
	_check_fit(main, "Lock-up (labels over the cards)")
	body.selected = ""
	main._armoury.selected = {}
	main.refresh()
	var Menu = load("res://scripts/ui/menu.gd")
	_check(Menu._build_words() == "FIAT · v" + Menu.VERSION and not Menu._build_words().contains("×"), "the title's foot reads '%s', not the version" % Menu._build_words())
	print("card frames ok: the label over the card, one frame picked; the title's version")
