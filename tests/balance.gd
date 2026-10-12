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
	# the A/B switches (12 Oct): docs/balance/ab.cfg (not .txt: balance.bat clears those), a word a line - "fixed_uniques" (every unique on its own base, as
	# before the tiers), "no_lorry_mult" (the lorries beaten multiply nothing). No file, no switch.
	var ab := FileAccess.open("res://docs/balance/ab.cfg", FileAccess.READ)
	if ab != null:
		var words := ab.get_as_text()
		ab.close()
		Items.fixed_uniques = words.contains("fixed_uniques")
		Sim.lorry_mult_off = words.contains("no_lorry_mult")
		print("A/B: %s" % words.strip_edges())
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
		# `-- 8 gate Doorman` or `-- 8 gate Poacher fire`: one build, every gate read, a GATES line at the end;
		# a fifth argument seeds the yard's dice (`-- 8 gate Scrapper "" 7`), for reading a change against the same start
		_gate(hours, args[2] if args.size() > 2 else "Doorman", args[3] if args.size() > 3 else "", int(args[4]) if args.size() > 4 else 0)
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
				if bank < 0.0 and sim.best_depth[Data.BANK] > 0:
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
				if bank < 0.0 and sim.best_depth[Data.BANK] > 0:
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
func _gate(hours: float, cls: String, element: String, seed := 0) -> void:
	var sim = Sim.new()
	sim.start()
	if seed != 0:
		sim.rng.seed = seed
	sim.set_class(cls)
	sim.fast_memo = true                  # the run reads its kit once in thirty seconds, as a dry run does (8 Oct)
	sim.odds_runs_max = 24                # and the odds at twenty-four dry runs a read, glasses or not (the verdict at PUSH is the same; the number shown is the player's)
	var bot = Bot.new()
	bot.element = element
	bot.cls = cls
	bot.keystones_first = element == ""
	var build: String = cls + ((" as " + element) if element != "" else "")
	print("Fiat gate read: %.0f h, %s" % [hours, build])
	print("h:mm | tier (depth) surv | lvl | cash | stash | loadout £ | dps | hp | runs KIA | last 30 min: missions, £ earned, items")
	var g := {"build": build, "class": cls, "element": element, "hours": hours, "bank_at": -1.0, "keystone_at": -1.0, "capstone_at": -1.0,
		"runs": 0, "deaths": 0, "wounded_runs": 0, "timeouts": 0, "depth_clears": [], "bought_bench": -1.0}
	var next_mark := 1800.0
	var mark_runs := 0
	var mark_cash := 0.0
	var mark_cash_from := 0.0
	var mark_items := 0
	var depth_seen: Dictionary = {}
	var first_ladder := {}
	var scrap_16 := -1.0
	var step_us := 0         # where the wall goes (8 Oct): the bot's step (the odds reads and the run), its tidy, the ladder reads
	var tidy_us := 0
	var ladder_us := 0
	var t0 := Time.get_ticks_msec()
	while sim.elapsed < hours * 3600.0 and Time.get_ticks_msec() - t0 < 7200000:     # two hours of wall: thirty-two simulated hours run under an hour with the bot reading one site a pick
		var items_before: int = sim.stash.size()
		var lost_before: int = sim.operators_lost
		var p0 := Time.get_ticks_usec()
		var t: int = bot.step(sim)
		step_us += Time.get_ticks_usec() - p0
		if t >= 0:
			g["runs"] += 1
			mark_runs += 1
			var r = sim.last_report
			if bool(r.get("timed_out", false)):
				g["timeouts"] += 1                # out of time (9 Oct): the clock's gate
			if sim.operators_lost > lost_before:
				g["deaths"] += 1
			elif bool(r.get("wounded", false)):
				g["wounded_runs"] += 1
			mark_items += sim.stash.size() - items_before
			if float(g["bank_at"]) < 0.0 and sim.best_depth[Data.BANK] > 0:
				g["bank_at"] = snappedf(sim.elapsed / 3600.0, 0.01)
			for i in range(Data.TIERS.size()):
				var key := "%d/%d" % [i, sim.best_depth[i]]
				if sim.best_depth[i] > 0 and not depth_seen.has(key):
					depth_seen[key] = true
					g["depth_clears"].append([snappedf(sim.elapsed / 3600.0, 0.01), i, sim.best_depth[i]])
			if sim.lorry_done and first_ladder.is_empty():
				var l0 := Time.get_ticks_usec()
				first_ladder = _ladder_read(sim, bot.PUSH)   # the first yard's ladders, as the lorry fell and before the move
				ladder_us += Time.get_ticks_usec() - l0
			var scrap_before: int = int(sim.scrap)
			var y0 := Time.get_ticks_usec()
			bot.tidy(sim)
			tidy_us += Time.get_ticks_usec() - y0
			if int(sim.scrap) < scrap_before:
				g["scrap_spent"] = int(g.get("scrap_spent", 0)) + scrap_before - int(sim.scrap)     # the bench's builds: earned = in hand + spent
		if float(g["keystone_at"]) < 0.0 or float(g["capstone_at"]) < 0.0:
			for id in sim.tree:
				var nd: Dictionary = sim.node(id)
				if float(g["keystone_at"]) < 0.0 and nd.get("keystone", false):
					g["keystone_at"] = snappedf(sim.elapsed / 3600.0, 0.01)
				if float(g["capstone_at"]) < 0.0 and nd.get("capstone", false):
					g["capstone_at"] = snappedf(sim.elapsed / 3600.0, 0.01)
		if scrap_16 < 0.0 and sim.elapsed >= 16.0 * 3600.0:
			scrap_16 = float(int(sim.scrap) + int(g.get("scrap_spent", 0)))
		if sim.elapsed >= next_mark:
			var tt: int = maxi(t, 0)
			mark_cash = sim.cash_in - mark_cash_from     # every pound in since the last mark: the runs' cash and the fence's money (read here, after the tidy's sales)
			print("%s | %d (%d) %2d%% | %2d | £%6d | %2d/%d | £%5d | %4.1f | %3.0f/%3.0f | %3d %d | %2d, £%5d, %d" % [_hm(sim.elapsed), tt, sim.depth[tt], int(round(sim.survival(tt) * 100)),
					sim.level(), int(sim.cash), sim.stash.size(), sim.stash_cap(), int(sim.loadout_value()), sim.dps(), sim.hp, sim.max_hp(), g["runs"], g["deaths"], mark_runs, int(mark_cash), mark_items])
			next_mark += 1800.0
			mark_runs = 0
			mark_cash_from = sim.cash_in
			mark_items = 0
	if scrap_16 < 0.0:
		scrap_16 = float(int(sim.scrap) + int(g.get("scrap_spent", 0)))
	# the end: the odds at every open tier at depth 1 - the campaign's odds - in the kit as it stands;
	# the ladder's depths are depth pace's business, and the bot leaves its site dug deep
	g["cash_earned"] = sim.cash_in       # all of it, the fence's money with the runs': the cash row reads hours of income in hand, and the sinks are priced off the same
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
		if sim.tier_open(i) and i <= sim.best_tier:      # the tiers held: the one just opened reads what it reads until the kit catches up
			var d0: int = sim.depth[i]
			var intel0: Array = sim.words[i].duplicate(true)
			sim.set_depth(i, 1)
			sim.words[i] = []                 # the plain site: the words on it are the ladder's business (a Resistant word reads any kit red)
			if sim.boss_armed.get(i, false):
				sim.arm_boss(i, false)        # and no boss left armed from an earlier pick: the campaign's odds are the site's
			var s: float = sim.survival(i)
			odds.append([i, snappedf(s, 0.001)])
			if s < 0.6:
				_odds_detail(sim, i, s)
			sim.words[i] = intel0
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
	g["level"] = sim.level()
	g["best_tier"] = sim.best_tier
	g["best_depth"] = sim.best_depth
	g["yard_built"] = sim.yard_built()           # the Yard's lanes (9 Oct): picks built, ranks bought
	var ranks := 0
	for k in sim.yard_ranks:
		ranks += int(sim.yard_ranks[k])
	g["yard_ranks"] = ranks
	g["top_bench"] = 14000                       # the old top Bench's price: the summary's cash-held yardstick when nothing was earned
	g["dearest_build"] = Data.BUILD_GUN * 3
	g["elapsed_h"] = snappedf(sim.elapsed / 3600.0, 0.01)
	g["wall_s"] = (Time.get_ticks_msec() - t0) / 1000
	g["kit"] = _kit(sim)
	g["bails"] = bot.bails
	g["dry_timeouts"] = int(sim.prof.get("dry_timeouts", 0))     # the odds' runs lost to the clock, for the read
	# the endgame's two (7 Oct): the lorry's hour and the moves, and the ladders' spread - the deepest depth the
	# streets and the barracks read PUSH in the kit as it stands (the depth set past the ladder for the read)
	g["lorry_at"] = snappedf(bot.lorry_at, 0.01) if bot.lorry_at >= 0.0 else -1.0
	g["lorries"] = sim.lorries
	g["moves"] = bot.moves
	g["services_depth"] = int(sim.best_depth[Data.CONVOY_TIER])
	# the ladders at the first lorry (the first yard's, read in the loop below when it fell; Matt, 8 Oct: the spread
	# widens as the yards compound, and the design's figure was a first yard's); at the end when it never fell
	if first_ladder.is_empty() and sim.campaign_done():
		var l0 := Time.get_ticks_usec()
		first_ladder = _ladder_read(sim, bot.PUSH)
		ladder_us += Time.get_ticks_usec() - l0
	g["ladder"] = first_ladder
	# where the wall went, in seconds: the bot's step holds the odds reads (survival: the dry runs, their snapshots)
	# and the real run's ticks; the tidy is the fitting, selling and building; the ladder reads are their own
	var pr: Dictionary = sim.prof
	g["prof"] = {"step_s": step_us / 1000000, "tidy_s": tidy_us / 1000000, "ladder_s": ladder_us / 1000000,
		"surv_s": int(pr["surv_us"]) / 1000000, "surv_calls": pr["surv_calls"], "surv_reads": pr["surv_reads"],
		"dry_runs": pr["dry_runs"], "dry_ticks": pr["dry_ticks"], "snap_s": int(pr["snap_us"]) / 1000000,
		"real_ticks": pr["real_ticks"], "real_s": int(pr["real_us"]) / 1000000}
	print("  wall %ds: step %ds (odds %ds on %d reads of %d calls, %d dry runs, %d dry ticks, snapshots %ds; the run %d ticks %ds), tidy %ds, ladders %ds" % [g["wall_s"],
		g["prof"]["step_s"], g["prof"]["surv_s"], pr["surv_reads"], pr["surv_calls"], pr["dry_runs"], pr["dry_ticks"], g["prof"]["snap_s"], pr["real_ticks"], g["prof"]["real_s"], g["prof"]["tidy_s"], g["prof"]["ladder_s"]])
	g["scrap_per_h"] = snappedf(scrap_16 / minf(16.0, maxf(0.01, sim.elapsed / 3600.0)), 0.1)      # the first sixteen hours' (Matt, 8 Oct)
	g["bails_per_h"] = snappedf(bot.bails / maxf(0.01, sim.elapsed / 3600.0), 0.01)
	g["runs_per_bail"] = snappedf(float(g["runs"]) / maxf(1.0, float(bot.bails)), 0.1) if bot.bails > 0 else 999.0
	for b in bot.bought:
		print("  %s at %s" % [b[1], _hm(b[0])])
	# the yard as the read left it, for reading a gate offline (the convoy's odds at hour 16, say): docs/balance/<build>.save
	var save_path := "res://docs/balance/%s.save" % build.replace(" as ", "-")
	var sf := FileAccess.open(save_path, FileAccess.WRITE)
	if sf != null:
		sf.store_string(JSON.stringify({"sim": sim.to_dict()}))
		sf.close()
		g["end_save"] = save_path
	print("GATES " + JSON.stringify(g))
	quit(0)


## The deepest depth the streets and the barracks read `push` in the kit as it stands: the runner whole and armed (a
## gun with a few rounds left reads 0%, and the lorry's fight leaves few), the depth set past the ladder for the read,
## the plain site, the words and the HP put back after.
func _ladder_read(sim, push: float) -> Dictionary:
	var ladder := {}
	var hp0: float = sim.hp
	sim.hp = sim.max_hp()
	var boxes: Array = []
	for s in ["Primary", "Secondary"]:
		var gun = sim.equipped[s]
		if gun != null and Items.ammo_type(gun) != "none" and not sim.ammo_box(Items.ammo_type(gun)).is_empty():
			var box: Dictionary = sim._plain(Data.AMMO, sim.ammo_box(Items.ammo_type(gun))["name"])
			box["rounds"] = 100000
			sim.rig.append(box)
			boxes.append(box)
	for pair in [[Data.OUTSKIRTS_SITES, "0"], [Data.TIERS.size() - 1, "8"]]:     # the Streets and the Barracks, keyed as before the Outskirts (12 Oct)
		var i: int = pair[0]
		var d0: int = sim.depth[i]
		var intel0: Array = sim.words[i].duplicate(true)
		sim.words[i] = []
		# the deepest depth that holds, by halving (8 Oct, the pass at an hour: thirty reads a site stepped; the
		# odds fall with the depth, so five or six reads find the edge) - lo holds, hi doesn't
		var lo := 0
		var hi := 31
		while hi - lo > 1:
			var d: int = (lo + hi) / 2
			sim.depth[i] = d
			sim._surv_cache.erase(i)
			if sim.survival(i) >= push:
				lo = d
			else:
				hi = d
		ladder[str(pair[1])] = lo
		sim.depth[i] = d0
		sim.words[i] = intel0
		sim._surv_cache.erase(i)
	for box in boxes:
		sim.rig.erase(box)
	sim.hp = hp0
	return ladder


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
		for oi in Data.ZONES[0]["tiers"]:
			sim.best_depth[oi] = maxi(1, int(sim.best_depth[oi]))     # the Outskirts walked, so the Streets are open (12 Oct)
		sim.hp = sim.max_hp()
		sim.deploy(Data.OUTSKIRTS_SITES)          # the Streets, as before the Outskirts (12 Oct)
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
		sim.armour(), sim.mitigation(), sim.pace(), sim.contact(t), meds, sim.wound, str(sim.is_night()), sim.weather_of(i), str(sim.word_names(i)), float(t["hp"]), float(t["dps"]), int(t["pool"]), str(t.get("res", {}))])


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
