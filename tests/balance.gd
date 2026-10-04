extends SceneTree
## The balance reader: godot --headless --path . -s tests/balance.gd -- [hours] [class] [runs]
## `-- 6 all` reads every class for six hours with a bot that trains to its
## keystones first, one line each: which build clears the bank first, and by
## how much, is a number we chose.
## `-- 6 elements [class]` reads the five element builds: a bot each that
## trains the element's tree to its keystone, holds the element's gun and
## socketables, and sends the primary to the bench for the element's affixes.
## The class is the element's affinity unless given.
## No shell. tests/bot.gd plays like a pushy player and this prints a line every
## thirty simulated minutes - where it is, what it has, what it's bought - then
## the firsts (each tier's first clear) and the camp purchases. With a third
## argument it prints every mission for that many runs instead.

const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Sim := preload("res://scripts/sim/sim.gd")
const Bot := preload("res://tests/bot.gd")


func _init() -> void:
	var hours := 8.0
	var cls := "Doorman"
	var every_run := 0
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		hours = float(args[0])
	if args.size() > 1:
		cls = args[1]
	if args.size() > 2:
		every_run = int(args[2])
	if cls == "all":
		_all_classes(hours)
		return
	if cls == "elements":
		_elements(hours, args[2] if args.size() > 2 else "")
		return
	var sim = Sim.new()
	sim.start()
	sim.set_class(cls)
	var bot = Bot.new()
	print("Fiat balance read: %.0f h, %s" % [hours, cls])
	if every_run == 0:
		print("h:mm | tier (depth) surv | lvl | cash | stash | loadout £ | dps | hp | runs KIA | last 30 min: missions, £ earned, items")
	var next_mark := 1800.0
	var runs := 0
	var kias := 0
	var earned := 0.0
	var mark_runs := 0
	var mark_cash := 0.0
	var mark_items := 0
	var firsts := {}
	var t0 := Time.get_ticks_msec()
	while sim.elapsed < hours * 3600.0 and Time.get_ticks_msec() - t0 < 540000:
		var items_before: int = sim.stash.size()
		var lost_before: int = sim.operators_lost
		var hp0: float = sim.hp
		var t: int = bot.step(sim)
		if t >= 0:
			runs += 1
			mark_runs += 1
			if sim.operators_lost > lost_before:
				kias += 1
			var r = sim.last_report
			earned += float(r.get("cash", 0.0))
			mark_cash += float(r.get("cash", 0.0))
			mark_items += sim.stash.size() - items_before
			if sim.best_depth[t] > 0 and not firsts.has("tier %d cleared" % t):
				firsts["tier %d cleared" % t] = sim.elapsed
			if every_run > 0:
				print("%s run %d t%d d%d: %s %ds, hp %.0f→%.0f, xp %.0f, £%.0f, %d items | lvl %d dps %.0f hp %.0f mit %.0f%% | %s" % [_hm(sim.elapsed), runs, t, sim.depth[t],
						r["outcome"], int(r["time"]), hp0, sim.hp, r["xp"], r["cash"], r["loot"], sim.level(), sim.dps(), sim.max_hp(), sim.mitigation() * 100, _kit(sim)])
				if runs >= every_run:
					break
			bot.tidy(sim)
		if sim.elapsed >= next_mark:
			if every_run == 0:
				var tt: int = maxi(t, 0)
				print("%s | %d (%d) %2d%% | %2d | £%6d | %2d/%d | £%5d | %4.1f | %3.0f/%3.0f | %3d %d | %2d, £%5d, %d" % [_hm(sim.elapsed), tt, sim.depth[tt], int(round(sim.survival(tt) * 100)),
						sim.level(), int(sim.cash), sim.stash.size(), sim.stash_cap(), int(sim.loadout_value()), sim.dps(), sim.hp, sim.max_hp(), runs, kias, mark_runs, int(mark_cash), mark_items])
			next_mark += 1800.0
			mark_runs = 0
			mark_cash = 0.0
			mark_items = 0
	print("")
	print("firsts:")
	var keys := firsts.keys()
	keys.sort_custom(func(a, b): return firsts[a] < firsts[b])
	for k in keys:
		print("  %s at %s" % [k, _hm(firsts[k])])
	print("best depth by tier: %s" % [sim.best_depth])
	print("bought:")
	for b in bot.bought:
		print("  %s at %s" % [b[1], _hm(b[0])])
	print("end: %d runs, %d KIA, £%d earned from missions, level %d, tree %d/%d points, %d items in stash, %s" % [runs, kias, int(earned), sim.level(), sim.points_spent(), sim.points_spent() + sim.points_free(), sim.stash.size(), _kit(sim)])
	quit(0)


func _all_classes(hours: float) -> void:
	print("Fiat builds read: %.0f h a class, keystones first" % hours)
	print("class      | bank at | lvl | £ in hand | runs KIA | keystones | kit")
	for c in Data.CLASSES:
		var sim = Sim.new()
		sim.start()
		sim.set_class(c["name"])
		var bot = Bot.new()
		bot.keystones_first = true
		var runs := 0
		var kias := 0
		var bank := -1.0
		var t0 := Time.get_ticks_msec()
		while sim.elapsed < hours * 3600.0 and Time.get_ticks_msec() - t0 < 150000:
			var lost_before: int = sim.operators_lost
			var t: int = bot.step(sim)
			if t >= 0:
				runs += 1
				if sim.operators_lost > lost_before:
					kias += 1
				if bank < 0.0 and sim.best_depth[5] > 0:
					bank = sim.elapsed
				bot.tidy(sim)
		var keys := []
		for id in sim.tree:
			if sim.node(id).get("keystone", false):
				keys.append(sim.node(id)["name"])
		print("%-10s | %7s | %3d | £%8d | %3d %3d | %s | %s" % [c["name"], _hm(bank) if bank >= 0.0 else "never", sim.level(), int(sim.cash), runs, kias, ", ".join(keys) if not keys.is_empty() else "none", _kit(sim)])
	quit(0)


## One line an element: the class, when the bank fell, when the keystone was
## taken, how much of a hit is the element and how much lands, the deepest
## on every tier (where the build walls), the kit.
func _elements(hours: float, forced: String) -> void:
	print("Fiat element builds read: %.0f h a build%s" % [hours, (", as a " + forced) if forced != "" else ""])
	print("element | class     | bank at | keystone | lvl | share | el dps | runs KIA | best depth by tier | kit")
	for t in Data.ELEMENT_TREES:
		var el: String = t["element"]
		var cls := forced
		if cls == "":
			for c in Data.CLASSES:
				if el in Data.AFFINITY.get(c["name"], []):
					cls = c["name"]
					break
		var sim = Sim.new()
		sim.start()
		sim.set_class(cls)
		var bot = Bot.new()
		bot.element = el
		var runs := 0
		var kias := 0
		var bank := -1.0
		var key := -1.0
		var t0 := Time.get_ticks_msec()
		while sim.elapsed < hours * 3600.0 and Time.get_ticks_msec() - t0 < 1200000:
			var lost_before: int = sim.operators_lost
			var tier: int = bot.step(sim)
			if tier >= 0:
				runs += 1
				if sim.operators_lost > lost_before:
					kias += 1
				if bank < 0.0 and sim.best_depth[5] > 0:
					bank = sim.elapsed
				bot.tidy(sim)
				if key < 0.0 and sim.tree.has("%s/6" % t["name"]):
					key = sim.elapsed
		var per: Dictionary = sim.type_dps()
		var total := 0.0
		for ty in per:
			total += float(per[ty])
		print("%-7s | %-9s | %7s | %8s | %3d | %3.0f%% | %5.0f | %3d %3d | %s | %s" % [el, cls, _hm(bank) if bank >= 0.0 else "never", _hm(key) if key >= 0.0 else "never", sim.level(),
				float(sim.conversion()[el]) * 100.0, float(per[el]), runs, kias, sim.best_depth, _kit(sim)])
		for b in bot.bought:
			if str(b[1]).begins_with("bench") or str(b[1]).begins_with("the second past"):
				print("    %s at %s" % [b[1], _hm(b[0])])
	quit(0)


func _kit(sim) -> String:
	var out := []
	for s in ["Primary", "Secondary", "Armour", "Helmet"]:
		var it = sim.equipped[s]
		if it != null:
			var fitted := 0
			for a in it["attachments"].values():
				if a != null:
					fitted += 1
			out.append("%s%s" % [Items.full_name(it), " +%d att" % fitted if fitted > 0 else ""])
	return ", ".join(out)


func _hm(s: float) -> String:
	return "%d:%02d" % [int(s) / 3600, (int(s) % 3600) / 60]
