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
	var element := args[3] if args.size() > 3 else ""     # `-- 4 Scrapper 0 fire`: the class as a fire build
	if cls == "all":
		_all_classes(hours)
		return
	if cls == "elements":
		_elements(hours, args[2] if args.size() > 2 else "")
		return
	if cls == "gate":
		# `-- 8 gate Doorman` or `-- 8 gate Poacher fire`: one build, every gate read, a GATES line at the end
		_gate(hours, args[2] if args.size() > 2 else "Doorman", args[3] if args.size() > 3 else "")
		return
	if cls == "probe":
		_probe()
		return
	var sim = Sim.new()
	sim.start()
	sim.set_class(cls)
	var bot = Bot.new()
	bot.element = element
	print("Fiat balance read: %.0f h, %s%s" % [hours, cls, (" as " + element) if element != "" else ""])
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
		while sim.elapsed < hours * 3600.0 and Time.get_ticks_msec() - t0 < 480000:
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


## The one-build read the pass runs eleven of at once (tools/balance.bat): the half-hour lines as the plain
## read, then a GATES line of JSON the summary parses - when the bank fell, the keystone and the capstone,
## the deaths, the wounded runs, the cash against the top bench, the scrap against the dearest build, the
## depths cleared by the hour, the odds at every open tier at the end.
func _gate(hours: float, cls: String, element: String) -> void:
	var sim = Sim.new()
	sim.start()
	sim.set_class(cls)
	var bot = Bot.new()
	bot.element = element
	bot.keystones_first = element == ""
	var build: String = cls + ((" as " + element) if element != "" else "")
	print("Fiat gate read: %.0f h, %s" % [hours, build])
	print("h:mm | tier (depth) surv | lvl | cash | stash | loadout £ | dps | hp | runs KIA | last 30 min: missions, £ earned, items")
	var g := {"build": build, "class": cls, "element": element, "hours": hours, "bank_at": -1.0, "keystone_at": -1.0, "capstone_at": -1.0,
		"runs": 0, "deaths": 0, "wounded_runs": 0, "depth_clears": [], "bought_bench": -1.0}
	var next_mark := 1800.0
	var mark_runs := 0
	var mark_cash := 0.0
	var mark_items := 0
	var depth_seen: Dictionary = {}
	var t0 := Time.get_ticks_msec()
	while sim.elapsed < hours * 3600.0 and Time.get_ticks_msec() - t0 < 1800000:
		var items_before: int = sim.stash.size()
		var lost_before: int = sim.operators_lost
		var t: int = bot.step(sim)
		if t >= 0:
			g["runs"] += 1
			mark_runs += 1
			var r = sim.last_report
			if sim.operators_lost > lost_before:
				g["deaths"] += 1
			elif bool(r.get("wounded", false)):
				g["wounded_runs"] += 1
			mark_cash += float(r.get("cash", 0.0))
			g["cash_earned"] = float(g.get("cash_earned", 0.0)) + float(r.get("cash", 0.0))     # the runs' takings, for the cash row (hours of takings in hand)
			mark_items += sim.stash.size() - items_before
			if float(g["bank_at"]) < 0.0 and sim.best_depth[Data.BANK] > 0:
				g["bank_at"] = snappedf(sim.elapsed / 3600.0, 0.01)
			for i in range(Data.TIERS.size()):
				var key := "%d/%d" % [i, sim.best_depth[i]]
				if sim.best_depth[i] > 0 and not depth_seen.has(key):
					depth_seen[key] = true
					g["depth_clears"].append([snappedf(sim.elapsed / 3600.0, 0.01), i, sim.best_depth[i]])
			var scrap_before: int = int(sim.scrap)
			bot.tidy(sim)
			if int(sim.scrap) < scrap_before:
				g["scrap_spent"] = int(g.get("scrap_spent", 0)) + scrap_before - int(sim.scrap)     # the bench's builds: earned = in hand + spent
		if float(g["keystone_at"]) < 0.0 or float(g["capstone_at"]) < 0.0:
			for id in sim.tree:
				var nd: Dictionary = sim.node(id)
				if float(g["keystone_at"]) < 0.0 and nd.get("keystone", false):
					g["keystone_at"] = snappedf(sim.elapsed / 3600.0, 0.01)
				if float(g["capstone_at"]) < 0.0 and nd.get("capstone", false):
					g["capstone_at"] = snappedf(sim.elapsed / 3600.0, 0.01)
		if sim.elapsed >= next_mark:
			var tt: int = maxi(t, 0)
			print("%s | %d (%d) %2d%% | %2d | £%6d | %2d/%d | £%5d | %4.1f | %3.0f/%3.0f | %3d %d | %2d, £%5d, %d" % [_hm(sim.elapsed), tt, sim.depth[tt], int(round(sim.survival(tt) * 100)),
					sim.level(), int(sim.cash), sim.stash.size(), sim.stash_cap(), int(sim.loadout_value()), sim.dps(), sim.hp, sim.max_hp(), g["runs"], g["deaths"], mark_runs, int(mark_cash), mark_items])
			next_mark += 1800.0
			mark_runs = 0
			mark_cash = 0.0
			mark_items = 0
	# the end: the odds at every open tier at depth 1 - the campaign's odds - in the kit as it stands;
	# the ladder's depths are depth pace's business, and the bot leaves its site dug deep
	var odds := []
	var hp0: float = sim.hp
	sim.hp = sim.max_hp()                 # read whole: the last run may have left it hurt, and the reader keys on the HP
	var boxes: Array = []                 # and armed: a gun with a few rounds left reads 0% (the dry run burns them in seconds)
	for s in ["Primary", "Secondary"]:
		var gun = sim.equipped[s]
		if gun != null and Items.ammo_type(gun) != "none" and not sim.ammo_box(Items.ammo_type(gun)).is_empty():
			var box: Dictionary = sim._plain(Data.AMMO, sim.ammo_box(Items.ammo_type(gun))["name"])
			box["rounds"] = 100000
			sim.rig.append(box)
			boxes.append(box)
	for i in range(Data.TIERS.size()):
		if sim.tier_open(i):
			var d0: int = sim.depth[i]
			var intel0: Array = sim.intel[i].duplicate()
			sim.set_depth(i, 1)
			sim.intel[i] = []                 # the plain site: the words on it are the ladder's business (a Resistant word reads any kit red)
			var s: float = sim.survival(i)
			odds.append([i, snappedf(s, 0.001)])
			if s < 0.6:
				_odds_detail(sim, i, s)
			sim.intel[i] = intel0
			sim.set_depth(i, d0)
	for box in boxes:
		sim.rig.erase(box)
	sim.hp = hp0
	g["odds"] = odds
	g["cash_end"] = int(sim.cash)
	g["cash_per_h"] = snappedf(float(g.get("cash_earned", 0.0)) / maxf(0.01, sim.elapsed / 3600.0), 1.0)
	g["notes_end"] = int(sim.notes)
	g["scrap_end"] = int(sim.scrap)
	g["scrap_spent"] = int(g.get("scrap_spent", 0))
	g["scrap_per_h"] = snappedf((int(sim.scrap) + int(g["scrap_spent"])) / maxf(0.01, sim.elapsed / 3600.0), 0.1)
	g["level"] = sim.level()
	g["best_tier"] = sim.best_tier
	g["best_depth"] = sim.best_depth
	g["bench"] = sim.workshop
	g["top_bench"] = int(Data.WORKSHOP.back()["cost"])
	g["dearest_build"] = Data.BUILD_GUN * 3
	g["elapsed_h"] = snappedf(sim.elapsed / 3600.0, 0.01)
	g["wall_s"] = (Time.get_ticks_msec() - t0) / 1000
	g["kit"] = _kit(sim)
	g["bails"] = bot.bails
	g["bails_per_h"] = snappedf(bot.bails / maxf(0.01, sim.elapsed / 3600.0), 0.01)
	for b in bot.bought:
		print("  %s at %s" % [b[1], _hm(b[0])])
	print("GATES " + JSON.stringify(g))
	quit(0)


## The loot gates, build-free: the Legendary share at +35% quality, finds a search at +25% quantity, from a
## fresh yard with a big sample. One process, seconds.
func _probe() -> void:
	var sim = Sim.new()
	sim.start()
	sim.set_class("Doorman")                 # no class loot share: the plain read is plain
	var g := {"build": "probe"}
	# the Legendary share at +35% quality (and unboosted), tier 3 gear, 20000 rolls
	for pair in [["top_share", 0.35], ["top_share_plain", 0.0]]:
		var elites := 0
		for k in range(20000):
			var it: Dictionary = Items.roll("Primary", 3, sim.rng, pair[1])
			if int(it["rarity"]) == Data.RARITIES.size() - 1:
				elites += 1
		g[pair[0]] = snappedf(elites / 20000.0, 0.0001)
	# finds a search at +25% quantity against the plain, over 400 searches each
	var per := {}
	for pair in [["finds_plain", 0.0], ["finds_boosted", 0.25]]:
		var pack: Dictionary = sim._plain("Backpack", Data.BASES["Backpack"].back()["name"])
		pack["affixes"] = [] if pair[1] == 0.0 else [{"stat": "loot_pct", "value": int(pair[1] * 100), "tier": 5}]
		sim.equipped["Backpack"] = pack
		sim.tree = []
		sim.deploy(0)
		var m: Dictionary = sim.mission
		m["remaining"] = 0
		m["cleared"] = true
		m["patrol_timer"] = -1e9
		m["event_at"] = -1.0
		var f0: int = int(m.get("finds", 0))
		var s0: int = m["searches"]
		while m["searches"] - s0 < 400 and sim.on_mission():
			sim.hp = sim.max_hp()
			m["remaining"] = 0
			m["searches"] = mini(m["searches"], s0 + 400)
			m["thin_after"] = 100000          # the searches in full: the quantity read, not the thinning
			sim.advance(1.0)
		per[pair[0]] = float(int(m.get("finds", 0)) - f0) / maxf(1.0, float(m["searches"] - s0))
		sim.extract_now()
	g["finds_plain"] = snappedf(per["finds_plain"], 0.01)
	g["finds_boosted"] = snappedf(per["finds_boosted"], 0.01)
	g["finds_ratio"] = snappedf(per["finds_boosted"] / maxf(0.01, per["finds_plain"]), 0.01)
	print("GATES " + JSON.stringify(g))
	quit(0)


## What the dry run saw, for a tier that reads red at the end: the runner's figures against the site's.
func _odds_detail(sim, i: int, s: float) -> void:
	var t: Dictionary = sim.effective(i)
	var gun = sim.equipped["Primary"]
	var meds := 0
	for it in sim.rig:
		if Items.is_medical(it):
			meds += 1
	print("  odds T%d %.0f%% at depth 1: hp %.0f/%.0f dps %.1f (gun %s, rounds %s %d, grade %.0f) armour %.0f mitigation %.2f pace %.2f contact %d meds %d wound '%s' night %s weather '%s' intel %s | site hp %.0f dps %.1f pool %d res %s" % [
		i, s * 100.0, sim.hp, sim.max_hp(), sim.dps(), Items.full_name(gun) if gun != null else "none", str(sim.has_rounds(gun)) if gun != null else "-", sim.rounds_for(gun) if gun != null else 0, sim.grade_bonus(gun) if gun != null else 0.0,
		sim.armour(), sim.mitigation(), sim.pace(), sim.contact(t), meds, sim.wound, str(sim.is_night()), sim.weather_of(i), str(sim.intel[i]), float(t["hp"]), float(t["dps"]), int(t["pool"]), str(t.get("res", {}))])


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
