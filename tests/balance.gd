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
const Feel := preload("res://tools/feel_gates.gd")
const CHECKPOINT := "res://docs/balance/pass/radio_checkpoint.save"     # the parity reads' start (25 Oct): the one save as the Radio opens
const LONG_WALL_MIN := 440         # the long read stops itself here (1 Nov, BUILD38): balance.bat kills it at 480; the stop is read between the bot's steps, and one step ran nearly five minutes past it in the cloud's test read, so forty minutes' room for that and the end's reads and saves
static var long_snap_h := 20.0     # the long read's state kept at this game hour (`snap=N` on the line)


func _init() -> void:
	Sim.combos_off = true                  # the broken builds sit outside the balance (21 Oct, Matt): the read never meets one
	Sim.exploits_off = true                # and the exploits (27 Oct, Matt) always
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
	var args: Array = Array(OS.get_cmdline_user_args())
	Bot.norepeat = args.has("norepeat")          # a read without the repeat runs (29 Oct): `-- 16 one Drifter fire 0 read1 norepeat`
	args = args.filter(func(a): return str(a) != "norepeat")
	# the long pass's hour-20 snapshot at another hour (1 Nov, BUILD38: `snap=2` proves it in a short read); 20 unless given
	for a in args:
		if str(a).begins_with("snap=") and str(a).substr(5).is_valid_float():
			long_snap_h = float(str(a).substr(5))
	args = args.filter(func(a): return not str(a).begins_with("snap="))
	if args.size() > 0:
		hours = float(args[0])
	if args.size() > 1:
		cls = args[1]
	if args.size() > 2:
		every_run = int(args[2])
	var element: String = str(args[3]) if args.size() > 3 else ""     # `-- 4 Scrapper 0 fire`: the class as a fire build
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
	if cls == "one":
		# `-- 32 one Drifter fire`: the one-save read (25 Oct, step 8): from the Poacher, the target build when its class
		# opens, the crew's swaps after; the same gates as `gate`. `-- 32 one Drifter fire 0 checkpoint` also writes
		# the Radio's checkpoint save as the Radio opens and stops there (the parity reads start from it)
		# `-- 32 one Drifter fire 0 read2`: the pass's second read of the build, its end state saved as its own (the review)
		# `-- 16 one Drifter fire 0 read1 cap20`: the quick pass's read (28 Oct, Matt: "buy time on balance passes"), stopped
		# after 20 minutes of wall wherever it's got to, its GATES line saying so (capped_at)
		# `-- 24 one Poacher poison 0 long`: the long pass's read (1 Nov, BUILD38): no two-hour stop, an HOUR line every game
		# hour, the state at hour 20 kept (pass/long-<Class>-<element>-h20.save), its end state pass/long-<Class>-<element>.save
		var tag: String = args[5] if args.size() > 5 else ""
		var cap: String = args[6] if args.size() > 6 else ""
		_gate(hours, args[2] if args.size() > 2 else "Drifter", args[3] if args.size() > 3 else "fire", int(args[4]) if args.size() > 4 else 0, true, tag == "checkpoint", tag.trim_prefix("read") if tag.begins_with("read") else "",
				int(cap.trim_prefix("cap")) if cap.begins_with("cap") else 0, tag == "long")
		return
	if cls == "parity":
		# `-- 4 parity Drifter fire [cap20]`: a cap is the quick pass's wall limit in minutes (the fix round); else PARITY_WALL_MIN
		var pcap: String = str(args[4]) if args.size() > 4 else ""
		_parity(hours, args[2] if args.size() > 2 else "Poacher", args[3] if args.size() > 3 else "", int(pcap.trim_prefix("cap")) if pcap.begins_with("cap") else PARITY_WALL_MIN)
		return
	if cls == "probe":
		_probe()
		return
	if cls == "broken":
		# `-- 0 broken embers`: a broken build's gauntlet (26 Oct, Matt) from its class's one-save end state, its pieces
		# and recipe on; `-- 0 broken hunt0`: the hunt's best; `-- 0 broken embers 2`: from the pass's second read's end state
		_broken(hours, args[2] if args.size() > 2 else "embers", false, str(args[3]) if args.size() > 3 else "")
		return
	if cls == "gauntlet":
		# `-- 0 gauntlet Drifter fire`: the build's one-save end state as played, through the gauntlet (26 Oct, Matt);
		# `-- 0 gauntlet Drifter fire 2`: from the pass's second read's end state (the fix round: both tries read the first's)
		# `-- 0 gauntlet Drifter fire long` / `... h20`: the long pass's two (1 Nov, BUILD38) - from the long read's end state
		# with the standard camp, as the full pass's; from its hour-20 state at the camp the six reads' hour 20 made
		var gtag: String = str(args[4]) if args.size() > 4 else ""
		var gb: Dictionary = {}
		if gtag == "long" or gtag == "h20":
			gb = _long_gauntlet(args[2] if args.size() > 2 else "Drifter", args[3] if args.size() > 3 else "fire", gtag == "h20")
		else:
			gb = _gauntlet(args[2] if args.size() > 2 else "Drifter", args[3] if args.size() > 3 else "fire", {}, gtag)
		gb["build"] = "%s-%s" % [gb["class"], gb["element"]]
		print("GAUNTLET " + JSON.stringify(gb))
		quit(0)
		return
	if cls == "hunt":
		# `-- 2 hunt 1 0 12`: the build hunt's stage 1, shard 0 of 12 (26 Oct, Matt); `-- 16 broken hunt0 [plain]` its finalists
		_hunt(hours, int(args[2]) if args.size() > 2 else 1, int(args[3]) if args.size() > 3 else 0, int(args[4]) if args.size() > 4 else 1)
		return
	var sim = Sim.new()
	sim.loot_by_hand = false            # the bot takes what it finds as it goes (13 Oct: the floor is the player's)
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
		sim.loot_by_hand = false            # the bot takes what it finds as it goes (13 Oct: the floor is the player's)
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
		sim.loot_by_hand = false            # the bot takes what it finds as it goes (13 Oct: the floor is the player's)
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
		print("%-7s | %-9s | %7s | %8s | %3d | %3.0f%% | %5.0f | %3d %3d | %s | %s" % [el, cls, _hm(bank) if bank >= 0.0 else "never", _hm(key) if key >= 0.0 else "never", sim.level(),
				float(sim.conversion()[el]) * 100.0, float(per[el]), runs, kias, sim.best_depth, _kit(sim)])
		for b in bot.bought:
			if str(b[1]).begins_with("bench") or str(b[1]).begins_with("the second past"):
				print("    %s at %s" % [b[1], _hm(b[0])])
	quit(0)


## The firsts the pass's gates read (15 Oct, docs/design/balance_gates.md), each the hour it first came true.
func _gate_firsts(sim, g: Dictionary, loose_seen: bool) -> void:
	var h: float = snappedf(sim.elapsed / 3600.0, 0.01)
	if float(g["gk_at"]) < 0.0 and sim.bosses_beaten[0]:
		g["gk_at"] = h
		g["level_at_gk"] = sim.level()
	if float(g["manager_at"]) < 0.0 and sim.bosses_beaten[2]:
		g["manager_at"] = h
	if float(g["qm_at"]) < 0.0 and sim.bosses_beaten[3]:
		g["qm_at"] = h
		g["level_at_qm"] = sim.level()
		g["loose_unique_by_qm"] = loose_seen
	if float(g["lv30_at"]) < 0.0 and sim.level() >= 30:
		g["lv30_at"] = h
	if float(g["lv50_at"]) < 0.0 and sim.level() >= 50:
		g["lv50_at"] = h
	if float(g["radio_at"]) < 0.0 and sim.room_open("radio"):
		g["radio_at"] = h
	if float(g["story_at"]) < 0.0 and sim.story_beat >= Data.STORY_BEATS.size():
		g["story_at"] = h


## The longest stretch in hours from `from_h` to `to_h` with none of `times` in it; -1 when it never started.
## The gun type a run's damage goes under (29 Oct, the itemisation's reads): the primary's as it set off; "fists" with none.
static func dealt_type(sim) -> String:
	return str(Items.base_of(sim.equipped["Primary"]).get("type", "")) if sim.equipped["Primary"] != null else "fists"


## A step's run's own damage dealt into its gun type's total (the fix round, 29 Oct, the review's A2: the record's "dealt"
## is the runner's best single run, so the steps it went up read only those): the run's report, when the step made one.
static func dealt_add(by: Dictionary, ty: String, sim, rep0) -> void:
	var rep = sim.last_report
	if rep is Dictionary and not is_same(rep, rep0) and rep.has("fight"):
		by[ty] = snappedf(float(by.get(ty, 0.0)) + float(rep["fight"].get("dealt", 0.0)), 1.0)


static func _longest_gap(from_h: float, to_h: float, times: Array) -> float:
	if from_h < 0.0 or to_h <= from_h:
		return -1.0
	var pts: Array = times.filter(func(t): return float(t) > from_h and float(t) <= to_h)
	pts.sort()
	var last: float = from_h
	var worst := 0.0
	for t in pts:
		worst = maxf(worst, float(t) - last)
		last = float(t)
	return snappedf(maxf(worst, to_h - last), 0.01)


## The one-build read the pass runs eleven of at once (tools/balance.bat): the half-hour lines as the plain
## read, then a GATES line of JSON the summary parses - when the bank fell, the keystone and the capstone,
## the deaths, the wounded runs, the cash against the top bench, the scrap against the dearest build, the
## depths cleared by the hour, the odds at every open tier at the end.
func _gate(hours: float, cls: String, element: String, seed_v := 0, one_save := false, checkpoint := false, read_n := "", cap_min := 0, long_read := false) -> void:
	var sim = Sim.new()
	sim.loot_by_hand = false            # the bot takes what it finds as it goes (13 Oct: the floor is the player's)
	sim.start()
	if seed_v != 0:
		sim.rng.seed = seed_v
	var start_cls: String = str(Data.CLASSES[0]["name"]) if one_save else cls     # a new game's the Poacher (24 Oct)
	# `-- 16 one Recruit played 0 read1`: the class as played (31 Oct, BUILD34) - both its elements, both joints, its
	# build's element (the crew's, Bot.CREW_BUILDS) first; the read's GATES line carries `played`
	var played: bool = one_save and element == "played"
	if played:
		element = str(Bot.CREW_BUILDS.get(cls, ""))
	sim.set_class(start_cls)
	sim.fast_memo = true                  # the run reads its kit once in thirty seconds, as a dry run does (8 Oct)
	sim.odds_runs_max = 24                # and the odds at twenty-four dry runs a read, glasses or not (the verdict at PUSH is the same; the number shown is the player's)
	var bot = Bot.new()
	bot.element = element
	bot.cls = cls
	bot.keystones_first = element == ""
	if one_save:
		bot.cls = start_cls
		bot.element = element if start_cls == cls else str(Bot.CREW_BUILDS.get(start_cls, ""))
		bot.keystones_first = false
		bot.target_cls = cls
		bot.target_el = element
		bot.wall_on = true                    # the campaign as played (30 Oct): walled, another class goes out
		bot.as_played = played
	var build: String = cls + ((" as " + element) if element != "" else "")
	if played:
		build = cls + " as played"
	print("Fiat gate read: %.0f h, %s%s" % [hours, build, " (one save, from the %s)" % start_cls if one_save else ""])
	print("h:mm | tier (depth) surv | lvl | cash | stash | loadout £ | dps | hp | runs KIA | last 30 min: missions, £ earned, items")
	var g := {"build": build, "class": cls, "element": element, "hours": hours, "bank_at": -1.0, "keystone_at": -1.0, "capstone_at": -1.0,
		"runs": 0, "deaths": 0, "wounded_runs": 0, "timeouts": 0, "depth_clears": [],
		# the pass's gates (15 Oct, docs/design/balance_gates.md): the heads, the levels, the Radio's ladder, Kev's story, staying
		"manager_at": -1.0, "first_death_at": -1.0, "qm_at": -1.0, "level_at_qm": -1, "lv30_at": -1.0, "lv50_at": -1.0, "radio_at": -1.0, "story_at": -1.0,
		"loose_unique_by_qm": false, "reach_log": [], "gang3_runs": 0, "left_by5": 0,
		# the itemisation's reads (29 Oct, shown not judged): the bases the bot wore, by slot, in hours; damage dealt by gun type
		"worn": {}, "dealt_by_type": {},
		# the levels against the sites (17 Oct, Matt: "you should be at the correct level round about the time you hit the
		# zone the gear starts to drop"): the level at each site's first clear, and the Outskirts' head
		"first_clear_lv": {}, "gk_at": -1.0, "level_at_gk": -1, "one_save": one_save,
		# P1 on the campaign alone (to the Quartermaster: past him a death keeps the level, past 50 the paragon goes - 31 Oct; the death band is
		# the campaign's): the runs, deaths and bails (left under a quarter HP) until the Quartermaster falls
		"campaign_runs": 0, "campaign_deaths": 0, "campaign_bails": 0, "first_bail_at": -1.0, "repeats": 0, "repeat_runs": 0, "repeat_bails": 0, "norepeat": Bot.norepeat,
		# P3 on the runs the bot takes at a person's odds (25 Oct, the tools review: farmed at PUSH, the median is 100% by
		# construction): the odds at the gate of every first clear and every head not yet beaten; the farm's apart
		"first_odds": []}
	# when the build's element opened for its class (31 Oct, BUILD34 phase 1: the Recruit as physical played as the
	# camp's frost and bleed, his own never opened): bot hours, -1 never
	g["el_open_at"] = -1.0
	if played:
		g["as_played"] = true
	var pl := {}                              # as played (BUILD34): class -> its elements' opening, its joints' halves, its Pitch
	if played:
		# the class going in noted as it leaves (the review: a swap inside the step left the outgoing class's last state
		# unread); on the real camp only - a wall's odds swap a copy
		bot.on_swap = func(s) -> void:
			if s == sim:
				played_note(sim, pl, g, sim.pitch_spent())
	var farm_odds: Array = []
	var boss_uniques: Dictionary = {}
	for u in Data.UNIQUES:
		if u.get("boss", false):
			boss_uniques[str(u["name"])] = true
	var loose_seen := false
	var reach_seen: int = sim.reach
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
	# the long read (1 Nov, BUILD38): the hourly book, the hour-20 state, no two-hour stop - its own stop just under the kill
	var lg := {"next_h": 1, "xp": {}, "cash_from": 0.0, "deaths_from": 0, "county_n": 0, "h20": false, "issue_at": -1.0, "lost": 0.0, "deaths_after_qm": 0}
	if long_read and cap_min == 0:
		cap_min = LONG_WALL_MIN                # a `capN` after `long` stops it sooner (a test's)
	while sim.elapsed < hours * 3600.0 and (long_read or Time.get_ticks_msec() - t0 < 7200000):     # two hours of wall: thirty-two simulated hours run under an hour with the bot reading one site a pick
		if cap_min > 0 and Time.get_ticks_msec() - t0 >= cap_min * 60000:
			g["capped_at"] = snappedf(sim.elapsed / 3600.0, 0.01)     # the quick pass's cap (28 Oct): the summary names it
			print("CAPPED at %s of %d h: %d minutes of wall" % [_hm(sim.elapsed), int(hours), cap_min])
			break
		var items_before: int = sim.stash.size()
		var lost_before: int = sim.operators_lost
		var uniques_before: Dictionary = {}
		if not loose_seen and float(g["qm_at"]) < 0.0:
			for it in sim.stash + sim.equipped.values() + sim.rig:
				if it is Dictionary and it.has("unique"):
					uniques_before[int(it["id"])] = true
		var c0: int = sim.chronicle.size()           # the run's own line is past here (P3)
		var bails0: int = bot.bails
		var depth0: Array = sim.best_depth.duplicate()
		var beaten0: Array = sim.bosses_beaten.duplicate()
		var lorry0: bool = sim.lorry_done
		var in_campaign: bool = float(g["qm_at"]) < 0.0
		var p0 := Time.get_ticks_usec()
		var worn_e0: float = sim.elapsed                     # what the bot wore and what each gun type dealt (29 Oct, the itemisation's reads)
		var worn0: Dictionary = {}
		for sl in Data.SLOTS:
			if sim.equipped.get(sl) != null:
				worn0[sl] = str(sim.equipped[sl]["base"])
		var dealt_ty: String = dealt_type(sim)
		var rep0 = sim.last_report
		var reps0: int = bot.repeats_gone
		var pitch0: int = sim.pitch_spent()
		var xb0: Dictionary = xp_book(sim) if long_read else {}
		var t: int = bot.step(sim)
		var rep_t: Dictionary = bot.last_repeat if bot.repeats_gone > reps0 else {}     # a repeat's runs, each counted (29 Oct, the tools review)
		if long_read:
			var xs: Dictionary = xp_split(xb0, xp_book(sim), sim.chronicle.slice(c0), not rep_t.is_empty())
			for k in xs:
				if k == "lost":
					lg["lost"] = float(lg["lost"]) + float(xs[k])
				else:
					lg["xp"][k] = float(lg["xp"].get(k, 0.0)) + float(xs[k])
		var worn_h: float = (sim.elapsed - worn_e0) / 3600.0
		for sl in worn0:
			if not g["worn"].has(sl):
				g["worn"][sl] = {}
			g["worn"][sl][worn0[sl]] = snappedf(float(g["worn"][sl].get(worn0[sl], 0.0)) + worn_h, 0.001)
		dealt_add(g["dealt_by_type"], dealt_ty, sim, rep0)
		step_us += Time.get_ticks_usec() - p0
		if t >= 0:
			var n_runs: int = maxi(1, int(rep_t.get("runs", 1)))
			g["runs"] += n_runs
			if not rep_t.is_empty():
				g["repeats"] += 1
				g["repeat_runs"] += n_runs
				g["repeat_bails"] += int(rep_t["bails"])
				g["timeouts"] += int(rep_t["timeouts"])
				g["wounded_runs"] += int(rep_t["wounds"])
			_first_or_farm(sim, c0, depth0, beaten0, lorry0, g["first_odds"], farm_odds)
			if in_campaign:
				g["campaign_runs"] += n_runs
				g["campaign_bails"] += int(rep_t.get("bails", 0))
				if sim.operators_lost > lost_before:
					g["campaign_deaths"] += 1
				elif bot.bails > bails0:
					g["campaign_bails"] += 1      # a bail that died anyway counts once, as the death
			if (bot.bails > bails0 or int(rep_t.get("bails", 0)) > 0) and float(g["first_bail_at"]) < 0.0:
				g["first_bail_at"] = snappedf(sim.elapsed / 3600.0, 0.01)
			mark_runs += n_runs
			var r = sim.last_report if rep_t.is_empty() else {}     # a repeat's figures are counted above, run by run
			if bool(r.get("timed_out", false)):
				g["timeouts"] += 1                # out of time (9 Oct): the clock's gate
			if sim.operators_lost > lost_before:
				g["deaths"] += 1
				if not in_campaign:
					lg["deaths_after_qm"] = int(lg["deaths_after_qm"]) + 1     # past the Quartermaster (the long pass's table)
				if float(g.get("first_death_at", -1.0)) < 0.0:
					g["first_death_at"] = snappedf(sim.elapsed / 3600.0, 0.01)     # the pass's gate (20 Oct), bot hours as every _at here (the review: played_s never moves in a read)
			elif bool(r.get("wounded", false)):
				g["wounded_runs"] += 1
			mark_items += sim.stash.size() - items_before
			if float(g["bank_at"]) < 0.0 and sim.best_depth[Data.BANK] > 0:
				g["bank_at"] = snappedf(sim.elapsed / 3600.0, 0.01)
			var gangs: int = int(r.get("patrols", 0))
			if gangs >= 3:
				g["gang3_runs"] += 1              # stayed into the third gang: did it leave by the fifth (gate 11)
				if gangs <= 5:
					g["left_by5"] += 1
			if not loose_seen and float(g["qm_at"]) < 0.0:
				for it in sim.stash + sim.equipped.values() + sim.rig:
					if it is Dictionary and it.has("unique") and not boss_uniques.has(str(it["unique"])) and not uniques_before.has(int(it["id"])):
						loose_seen = true         # a campaign's loose unique off a run (gate 12): not a head's, not bought (the tidy's after)
			for i in range(Data.TIERS.size()):
				var key := "%d/%d" % [i, sim.best_depth[i]]
				if sim.best_depth[i] > 0 and not depth_seen.has(key):
					depth_seen[key] = true
					if int(sim.best_depth[i]) == 1:
						g["first_clear_lv"][str(i)] = sim.level()
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
		_gate_firsts(sim, g, loose_seen)
		if float(g["el_open_at"]) < 0.0 and element != "" and sim.cls == cls and element in sim.class_elements():
			g["el_open_at"] = snappedf(sim.elapsed / 3600.0, 0.01)
		if played:
			played_note(sim, pl, g, pitch0)
		if checkpoint and sim.room_open("radio") and not sim.on_mission():
			var cf := FileAccess.open(CHECKPOINT, FileAccess.WRITE)
			cf.store_string(JSON.stringify({"sim": sim.to_dict(), "hour": snappedf(sim.elapsed / 3600.0, 0.01), "route": bot.bought.filter(func(x): return str(x[1]).begins_with("crew") or str(x[1]).begins_with("the target"))}))
			cf.close()
			print("CHECKPOINT the Radio's open at %s, level %d, as the %s: %s" % [_hm(sim.elapsed), sim.level(), sim.cls, CHECKPOINT])
			quit(0)
			return
		if element == "" and float(g["qm_at"]) >= 0.0:
			print("  the plain floor's beaten at %s: the read ends here (22 Oct, the pass's wall)" % _hm(sim.elapsed))
			break                           # a plain build's one gate is the Quartermaster by hour 24; past him its hours were the pass's slowest
		if sim.reach != reach_seen:
			reach_seen = sim.reach
			g["reach_log"].append([snappedf(sim.elapsed / 3600.0, 0.01), sim.reach])
		if scrap_16 < 0.0 and sim.elapsed >= 16.0 * 3600.0:
			scrap_16 = float(int(sim.scrap) + int(g.get("scrap_spent", 0)) + int(sim.exp_scrap_out))     # shipped scrap is spent scrap (the expeditions)
		if sim.issued and not g.has("cash_in_at_issue"):
			g["cash_in_at_issue"] = sim.cash_in       # the money in from here is fiat (the third review: gate 14 added tins to fiat)
		if long_read:
			long_book(sim, cls, element, g, lg, c0)
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
		scrap_16 = float(int(sim.scrap) + int(g.get("scrap_spent", 0)) + int(sim.exp_scrap_out))
	if long_read:
		long_end(sim, cls, element, g, lg)
	# the end's figures are the read's build's (the fix round, H3: a walled class out read its own odds, level and kit)
	if one_save:
		end_noted(sim, bot, cls, pl, g, played)
	g["end_class"] = sim.cls                  # the runner the end's figures read: the build's class, or why not in `route`
	if played:
		g["played"] = played_gates(sim, pl, g)
	# the end: the odds at every open tier at depth 1 - the campaign's odds - in the kit as it stands;
	# the ladder's depths are depth pace's business, and the bot leaves its site dug deep
	g["cash_earned"] = sim.cash_in       # all of it, the fence's money with the runs': the cash row reads hours of income in hand, and the sinks are priced off the same
	var odds := []
	var gang_clock := []
	var hp0: float = sim.hp
	sim.hp = sim.max_hp()                 # read whole: the last run may have left it hurt, and the reader keys on the HP
	# (30 Oct, the designer's A: the reads see the rule - the real magazines, filled at the gate, and the gate's box in the pack)
	sim._fill_mags()
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
			if i <= 5:
				var te: Dictionary = sim.effective(i)
				gang_clock.append([i, snappedf(minf(99.0, sim.patrol_s(te) / maxf(0.01, sim.search_s(te))), 0.01)])     # Never there: no gangs (INF isn't JSON)     # searches in a gap between gangs (gate 10)
			if s < 0.6:
				_odds_detail(sim, i, s)
			sim.words[i] = intel0
			sim.set_depth(i, d0)
	sim.hp = hp0
	g["odds"] = odds
	g["gang_clock"] = gang_clock
	# the Radio's ladder from its opening to hour 12 (gate 6): the longest stretch without a signal made, and without reach
	var to_h: float = minf(12.0, sim.elapsed / 3600.0)
	# the first Yard's ladder: a move (at level 50) starts the campaign again and shuts the Radio till its Quartermaster,
	# which isn't a gap in the ladder (16 Oct: every signal gap over 20 min in the D29 read was after a move)
	var moved: Array = bot.bought.filter(func(x): return str(x[1]).begins_with("moved the pitch"))
	if not moved.is_empty():
		to_h = minf(to_h, float(moved[0][0]) / 3600.0)
	var sig_h: Array = bot.bought.filter(func(x): return str(x[1]).begins_with("a signal")).map(func(x): return float(x[0]) / 3600.0)
	g["signal_gap_h"] = _longest_gap(float(g["radio_at"]), to_h, sig_h)
	g["reach_gap_h"] = _longest_gap(float(g["radio_at"]), to_h, g["reach_log"].map(func(x): return float(x[0])))
	# and its pace (16 Oct, Matt: gate 6's reach as an average and a longest stretch): levels a hour, the Radio to hour 12
	var reach_12: int = Data.REACH_START
	for x in g["reach_log"]:
		if float(x[0]) <= to_h:
			reach_12 = int(x[1])
	var ladder_h: float = to_h - float(g["radio_at"])
	g["reach_rate"] = snappedf(float(reach_12 - Data.REACH_START) / ladder_h, 0.01) if float(g["radio_at"]) >= 0.0 and ladder_h > 0.0 else -1.0
	g["cash_end"] = int(sim.cash)
	g["cash_per_h"] = snappedf(float(g.get("cash_earned", 0.0)) / maxf(0.01, sim.elapsed / 3600.0), 1.0)
	g["notes_end"] = int(sim.notes)
	g["scrap_end"] = int(sim.scrap)
	g["scrap_spent"] = int(g.get("scrap_spent", 0))
	g["exp"] = exp_gates(sim, bot)               # the expeditions (29 Oct, shown, not judged)
	g["level"] = sim.level()
	g["best_tier"] = sim.best_tier
	g["best_depth"] = sim.best_depth
	g["yard_built"] = sim.yard_built()           # the Yard's lanes (9 Oct): picks built, both sides of a column counted (24 Oct), ranks bought
	var ranks := 0
	for k in sim.yard_ranks:
		ranks += int(sim.yard_ranks[k])
	g["yard_ranks"] = ranks
	g["dearest_build"] = Data.BUILD_GUN * 3
	g["elapsed_h"] = snappedf(sim.elapsed / 3600.0, 0.01)
	@warning_ignore("integer_division")
	g["wall_s"] = (Time.get_ticks_msec() - t0) / 1000
	g["kit"] = _kit(sim)
	g["bails"] = bot.bails + bot.repeat_bails     # a repeat's bails too (29 Oct); repeat_bails says how many
	g["dry_timeouts"] = int(sim.prof.get("dry_timeouts", 0))     # the odds' runs lost to the clock, for the read
	# the endgame's two (7 Oct): the lorry's hour and the moves, and the ladders' spread - the deepest depth the
	# streets and the barracks read PUSH in the kit as it stands (the depth set past the ladder for the read)
	g["lorry_at"] = snappedf(bot.lorry_at, 0.01) if bot.lorry_at >= 0.0 else -1.0
	g["tempers"] = bot.tempers           # the Bench's tempers the read made (25 Oct)
	g["walls"] = bot.walls                    # the wall's swaps (30 Oct): [hour, tier, a head?, from, to, to's odds, from's odds]
	g["crew_swaps"] = bot.crew_swaps     # the crew (21 Oct, step 7): swaps, the classes played, the board's level
	g["route"] = bot.bought.filter(func(x): return str(x[1]).begins_with("crew") or str(x[1]).begins_with("the target")).map(func(x): return [snappedf(float(x[0]) / 3600.0, 0.01), str(x[1])])     # the one save's classes, when (25 Oct)
	g["crew"] = sim.crew_played().map(func(c): return "%s %d" % [c, sim.crew_level(c)])
	g["paragon"] = sim.paragon()
	g["lorries"] = sim.lorries
	g["services_depth"] = int(sim.best_depth[Data.CONVOY_TIER])
	# the Radio's endgame (15 Oct): the reach, Kev's story, the signals made and the papers held
	g["reach"] = sim.reach
	g["story_beat"] = sim.story_beat
	g["signals_made"] = bot.bought.filter(func(x): return str(x[1]).begins_with("a signal")).size()
	g["papers_held"] = sim.signal_papers().size()
	# the pass's gates (20 Oct, Matt): the signals by grade - a faint one won about nine in ten, a full one at the reach
	# about a coin flip - and the reach's longest stand over the whole read (the endgame's stall, about an hour), and
	# the odds the runs went in at (the median about 70-90%)
	var sg_faint := [0, 0]
	var sg_full := [0, 0]
	for e in sim.chronicle:
		if str(e.get("k", "")) != "signal_done" or e.get("story", false):
			continue
		var gr: int = int(e.get("grade", 0))
		if gr == 1:
			sg_faint[0] += 1
			sg_faint[1] += 1 if e.get("won", false) else 0
		elif gr == 3 and int(e.get("level", 0)) >= int(e.get("reach", 0)):
			sg_full[0] += 1
			sg_full[1] += 1 if e.get("won", false) else 0
	g["faint"] = sg_faint
	g["full_at_reach"] = sg_full
	# the Issue and the County (25 Oct): when the town went on fiat, the order's and the County's wins, issued kit
	g["issue_at"] = -1.0
	g["county_firsts"] = []
	for e in sim.chronicle:
		if str(e.get("k", "")) == "issue" and float(g["issue_at"]) < 0.0:
			g["issue_at"] = snappedf(float(e.get("t", 0.0)) / 3600.0, 0.01)
		if str(e.get("k", "")) == "county_done" and e.get("won", false):
			if not (str(e["key"]) in g["county_firsts"].map(func(x): return x[1])):
				g["county_firsts"].append([snappedf(float(e.get("t", 0.0)) / 3600.0, 0.01), str(e["key"]), int(e.get("level", 0))])
	g["orders_beaten"] = sim.order_beaten.duplicate()
	g["county_taken"] = sim.county_taken_count()
	g["issued_worn"] = sim.issued_worn()
	g["issued_bought"] = sim.issued_serial
	if g.has("cash_in_at_issue"):
		g["fiat_per_h"] = snappedf((sim.cash_in - float(g["cash_in_at_issue"])) / maxf(0.01, sim.elapsed / 3600.0 - float(g["issue_at"])), 0.01)
	g["fiat"] = {"cash": int(sim.cash), "circulation": int(sim.circulation), "prices": snappedf(sim.circ_mult(), 0.01), "rate": snappedf(sim.fiat_rate, 0.01)} if sim.issued else {}
	var stand_to: float = sim.elapsed / 3600.0 if moved.is_empty() else float(moved[0][0]) / 3600.0     # to the first move: the move is the stall's answer, and the campaign again isn't a stand
	g["reach_stand_h"] = _longest_gap(float(g["radio_at"]), stand_to, g["reach_log"].map(func(x): return float(x[0]))) if float(g["radio_at"]) >= 0.0 else -1.0
	var gate_odds: Array = []
	for e in sim.chronicle:
		if str(e.get("k", "")) == "run" and e.has("odds") and float(e["odds"]) >= 0.0:
			gate_odds.append(float(e["odds"]))
	gate_odds.sort()
	@warning_ignore("integer_division")
	g["odds_median"] = gate_odds[gate_odds.size() / 2] if not gate_odds.is_empty() else -1.0
	farm_odds.sort()
	@warning_ignore("integer_division")
	g["farm_odds_median"] = farm_odds[farm_odds.size() / 2] if not farm_odds.is_empty() else -1.0
	# the ladders at the first lorry (the first yard's, read in the loop below when it fell; Matt, 8 Oct: the spread
	# widens as the yards compound, and the design's figure was a first yard's); at the end when it never fell
	if first_ladder.is_empty() and sim.campaign_done():
		var l0 := Time.get_ticks_usec()
		first_ladder = _ladder_read(sim, bot.PUSH)
		ladder_us += Time.get_ticks_usec() - l0
	g["ladder"] = first_ladder
	g["feel"] = Feel.read(sim.chronicle, true)    # an old record's away runs count as play          # how play felt (19 Oct): the gates a playtest is judged by too
	# where the wall went, in seconds: the bot's step holds the odds reads (survival: the dry runs, their snapshots)
	# and the real run's ticks; the tidy is the fitting, selling and building; the ladder reads are their own
	var pr: Dictionary = sim.prof
	var tidy_parts := {}
	for k in bot.prof:
		@warning_ignore("integer_division")
		tidy_parts[k] = int(bot.prof[k]) / 1000000     # the tidy's parts (22 Oct): fit, train, yard, mounts, sell, shop, endgame
	@warning_ignore("integer_division")
	g["prof"] = {"step_s": step_us / 1000000, "tidy_s": tidy_us / 1000000, "tidy_parts": tidy_parts, "ladder_s": ladder_us / 1000000,
		"surv_s": int(pr["surv_us"]) / 1000000, "surv_calls": pr["surv_calls"], "surv_reads": pr["surv_reads"],
		"dry_runs": pr["dry_runs"], "dry_ticks": pr["dry_ticks"], "snap_s": int(pr["snap_us"]) / 1000000,
		"real_ticks": pr["real_ticks"], "real_s": int(pr["real_us"]) / 1000000}
	print("  wall %ds: step %ds (odds %ds on %d reads of %d calls, %d dry runs, %d dry ticks, snapshots %ds; the run %d ticks %ds), tidy %ds (%s), ladders %ds" % [g["wall_s"],
		g["prof"]["step_s"], g["prof"]["surv_s"], pr["surv_reads"], pr["surv_calls"], pr["dry_runs"], pr["dry_ticks"], g["prof"]["snap_s"], pr["real_ticks"], g["prof"]["real_s"], g["prof"]["tidy_s"], str(tidy_parts), g["prof"]["ladder_s"]])
	g["scrap_per_h"] = snappedf(scrap_16 / minf(16.0, maxf(0.01, sim.elapsed / 3600.0)), 0.1)      # the first sixteen hours' (Matt, 8 Oct)
	g["bails_per_h"] = snappedf(float(g["bails"]) / maxf(0.01, sim.elapsed / 3600.0), 0.01)
	for b in bot.bought:
		print("  %s at %s" % [b[1], _hm(b[0])])
	# the yard as the read left it, for reading a gate offline (the convoy's odds at hour 16, say): docs/balance/<build>.save
	var save_path := "res://docs/balance/pass/%s%s.save" % [build.replace(" as ", "-"), ("-" + read_n) if read_n != "" else ""]
	if long_read:
		save_path = long_save_path(cls, element, false)
	var sf := FileAccess.open(save_path, FileAccess.WRITE)
	if sf != null:
		sf.store_string(JSON.stringify({"sim": sim.to_dict()}))
		sf.close()
		g["end_save"] = save_path
	print("GATES " + JSON.stringify(g))
	quit(0)


## The read's build out for the end's figures, and as played its state there noted (the review: the end's tidy can
## close a joint the loop never saw).
static func end_noted(sim, bot, cls: String, pl: Dictionary, g: Dictionary, played: bool) -> void:
	var p0: int = sim.pitch_spent()
	end_as_build(sim, bot, cls)
	if played:
		played_note(sim, pl, g, p0)


## The as-played read's step noted (BUILD34): for the runner out, when each of its own two elements opened for it, when
## each joint's class half and element half went in and when the joint closed (and at what level), and the Pitch it
## spent; the camp's element points at the Quartermaster. Bot hours.
static func played_note(sim, pl: Dictionary, g: Dictionary, pitch0: int) -> void:
	var c: String = sim.cls
	if not pl.has(c):
		pl[c] = {"opened": {}, "how": {}, "self_opened": {}, "class_half": {}, "element_half": {}, "closed": {}, "closed_lv": {}, "pitch": 0}
	var rec: Dictionary = pl[c]
	var h: float = snappedf(sim.elapsed / 3600.0, 0.01)
	# the opens the classes made themselves since the last note (the chronicle's element_open, the runner's class on it;
	# a free open of the camp's counts): an element first seen open without one was inherited (the camp's two derived)
	var ci: int = int(g.get("_chron_i", 0))
	for k in range(mini(ci, sim.chronicle.size()), sim.chronicle.size()):
		var e: Dictionary = sim.chronicle[k]
		var oel := ""
		if str(e.get("k", "")) == "element_open":
			oel = str(e.get("element", ""))       # a free open: the camp's element, opened for this class
		elif str(e.get("k", "")) == "train" and sim.is_element_starter(str(e.get("id", ""))):
			oel = sim.element_of(str(e["id"]))    # a paid open: the starter bought with a Pitch point
		if oel != "":
			var oc: String = str(e.get("cls", ""))
			if not pl.has(oc):
				pl[oc] = {"opened": {}, "how": {}, "self_opened": {}, "class_half": {}, "element_half": {}, "closed": {}, "closed_lv": {}, "pitch": 0}
			pl[oc]["self_opened"][oel] = true
	g["_chron_i"] = sim.chronicle.size()
	rec["pitch"] = int(rec["pitch"]) + maxi(0, sim.pitch_spent() - pitch0)
	var open_now: Array = sim.class_elements()
	for el in Bot.own_elements(c):
		if el in open_now and not rec["opened"].has(el):
			rec["opened"][el] = h
			rec["how"][el] = "itself" if rec["self_opened"].has(el) else "inherited"
		var j: Dictionary = Data.joint_in(c, str(Data.element_tree_of(str(el)).get("name", "")))
		var halves: Array = Bot.joint_halves(c, str(el))
		if j.is_empty() or halves.is_empty():
			continue
		var key: String = str(j["key"])
		if not rec["class_half"].has(key) and sim.tree.has(str(halves[0])):
			rec["class_half"][key] = h
		if not rec["element_half"].has(key) and sim.tree.has(str(halves[1])):
			rec["element_half"][key] = h
		if not rec["closed"].has(key) and sim.has_joint(key):
			rec["closed"][key] = h
			rec["closed_lv"][key] = sim.level()
	if float(g.get("qm_at", -1.0)) >= 0.0 and not g.has("_points_at_qm"):
		g["_points_at_qm"] = sim.element_points.duplicate()


## The GATES line's `played` (BUILD34): per class played, its two elements (the build's first) - when each opened for it,
## the camp's points in each at the Quartermaster and at the end - and its two joints: when the class half, the element
## half and the joint went in (null never), the level it closed at; the Pitch it spent while out. The camp's Pitch.
static func played_gates(sim, pl: Dictionary, g: Dictionary) -> Dictionary:
	var at_qm: Dictionary = g.get("_points_at_qm", {})
	g.erase("_points_at_qm")
	g.erase("_chron_i")
	var classes := {}
	for c in pl:
		var rec: Dictionary = pl[c]
		var first: String = str(g["element"]) if c == str(g["class"]) else str(Bot.CREW_BUILDS.get(c, ""))
		var els: Array = Bot.own_elements(c, first)
		var joints := {}
		for el in els:
			var j: Dictionary = Data.joint_in(c, str(Data.element_tree_of(str(el)).get("name", "")))
			if j.is_empty():
				continue
			var key: String = str(j["key"])
			joints[key] = {"element": el, "class_half": rec["class_half"].get(key, null), "element_half": rec["element_half"].get(key, null),
				"closed": rec["closed"].get(key, null), "closed_lv": rec["closed_lv"].get(key, null)}
		var opened: Array = []
		var how: Array = []
		var points: Array = []
		var points_qm: Array = []
		var none_at_qm = null                 # no Quartermaster: null; beaten with none earned by then: 0
		if float(g.get("qm_at", -1.0)) >= 0.0:
			none_at_qm = 0
		for el in els:
			opened.append(rec["opened"].get(el, null))
			how.append(rec["how"].get(el, null))
			points.append(int(sim.element_points.get(el, 0)))
			points_qm.append(at_qm.get(el, none_at_qm))
		var lv: int = sim.level() if c == sim.cls else sim.crew_level(c)
		classes[c] = {"elements": els, "opened": opened, "opened_how": how, "points": points, "points_at_qm": points_qm, "joints": joints, "pitch": int(rec["pitch"]), "level": lv}
	return {"classes": classes, "pitch_spent": sim.pitch_spent(), "pitch_points": sim.pitch_points()}


## The read's build out for the end's figures (the fix round, H3): the odds, the gang clock, the level and the kit are
## the runner's out, so a one-save read the wall or the crew left on another class puts its target back first - from
## the roster, its own tree and kit, quietly (no swap counted). A target never played, or busy, stays as it is.
static func end_as_build(sim, bot, cls: String) -> void:
	if sim.cls == cls or sim.on_mission() or not (cls in sim.crew_played()):
		return
	bot._crew_out(sim, cls, true)
	bot._tidy_kit(sim)                         # the crew's floor lifts it on the swap: its points spent and its kit looked over, as the bot would
	sim.hp = sim.max_hp()


## A run's odds at the gate (25 Oct, P3), from its chronicle line past `c0`: a first clear (the site never cleared
## before it) or a head not yet beaten (the lorry while it stands) to `first`, any other campaign run to `farm`; a
## signal's run, and a card read part-way (-1), to neither.
static func _first_or_farm(sim, c0: int, depth0: Array, beaten0: Array, lorry0: bool, first: Array, farm: Array) -> void:
	for k in range(c0, sim.chronicle.size()):
		var e: Dictionary = sim.chronicle[k]
		if str(e.get("k", "")) != "run" or e.get("signal", false) or float(e.get("odds", -1.0)) < 0.0:
			continue
		var i: int = int(e.get("tier", -1))
		var fresh: bool = i >= 0 and i < depth0.size() and int(depth0[i]) <= 0
		if e.has("boss"):
			var b: Dictionary = sim.boss_of(i)
			fresh = fresh or (not lorry0 if b.is_empty() else not bool(beaten0[int(b["zone"])]))
		if fresh:
			first.append(snappedf(float(e["odds"]), 0.01))
		else:
			farm.append(snappedf(float(e["odds"]), 0.01))
		return


## The deepest depth the streets and the barracks read `push` in the kit as it stands: the runner whole and armed (a
## gun with a few rounds left reads 0%, and the lorry's fight leaves few), the depth set past the ladder for the read,
## the plain site, the words and the HP put back after.
func _ladder_read(sim, push: float) -> Dictionary:
	var ladder := {}
	var hp0: float = sim.hp
	sim.hp = sim.max_hp()
	# (30 Oct, the designer's A: the reads see the rule - the real magazines, filled at the gate, and the gate's box in the pack)
	sim._fill_mags()
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
			@warning_ignore("integer_division")
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
	sim.hp = hp0
	return ladder


## The loot gates, build-free: the Legendary share at +35% quality, finds a search at +25% quantity, from a
## fresh yard with a big sample. One process, seconds.
func _probe() -> void:
	var sim = Sim.new()
	sim.loot_by_hand = false            # the bot takes what it finds as it goes (13 Oct: the floor is the player's)
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
		var pack: Dictionary = sim._plain("Backpack", "Special forces bergen")     # named (29 Oct, the review): the list's last is a loot-quantity pack now
		pack["affixes"] = [] if pair[1] == 0.0 else [{"stat": "loot_pct", "value": int(pair[1] * 100), "tier": 5}]
		sim.equipped["Backpack"] = pack
		sim.tree = []
		for oi in Data.ZONES[0]["tiers"]:
			sim.best_depth[oi] = maxi(1, int(sim.best_depth[oi]))     # the Outskirts walked, so the Streets are open (12 Oct)
		sim.bosses_beaten[0] = true               # and the Gamekeeper down: the Estate opens on him since the gates (13 Oct)
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
			m["crates_off"] = true            # no crates: the quantity read, searches without an end
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
		sim.armour(), sim.mitigation(), sim.pace(), sim.contact(t), meds, ",".join(sim.wounds.keys()), str(sim.is_night()), sim.weather_of(i), str(sim.word_names(i)), float(t["hp"]), float(t["dps"]), int(t["pool"]), str(t.get("res", {}))])


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
	@warning_ignore("integer_division")
	return "%d:%02d" % [int(s) / 3600, (int(s) % 3600) / 60]


## Build parity (25 Oct, step 8): one build for a fixed spell from the Radio's checkpoint - the same world, the same
## kit in the stash, the class taken whether or not the save had opened it - and what it made of the spell: the reach
## and the levels gained, the signals won, the deaths. One PARITY line; the summary sets the builds side by side.
## A broken build (26 Oct, Matt: "test they are broken and can smash all content at least once"): the gauntlet (below)
## from its class's one-save end state, its pieces and recipe on and its combos counting. BROKEN {json}: each place
## won or not. `key` a combo's, or "hunt<n>": the build hunt's nth best (stage 2's lines, pass/hunt-s2-*.txt, ranked
## as _hunt_ranked does).
const BROKEN_ELEMENT := {"embers": "fire", "clean_kills": "frost", "flatline": "shock", "opened_for_good": "bleed", "live_load": "shock", "drilled": "physical"}
const STAY_OUT := 20                     # Matt, 26 Oct: "until HP bail or 20 patrols"
const HUNT_DIR := "res://docs/balance/pass/"     # pass/hunt-s<stage>-<shard>.txt (tools\\balance.bat <hours> 0 hunt)
const HUNT_TOP := 20                     # the first stage's builds the second tries every unique on (Matt, 26 Oct: two stages)
func _broken(_hours: float, key: String, _plain := false, read_n := "") -> void:
	var spec: Dictionary = {}
	if key.begins_with("hunt") and key.substr(4).is_valid_int():
		var ranked: Array = _hunt_ranked(2)
		var n: int = int(key.substr(4))
		spec = _hunt_spec(ranked[n]) if n >= 0 and n < ranked.size() else {}
	elif Data.COMBOS.has(key):
		var c: Dictionary = Data.COMBOS[key]
		spec = {"id": key, "class": str(c["class"]), "element": str(BROKEN_ELEMENT.get(key, "")), "recipe": c.get("recipe", []),
			"set": str(c["set"]), "pieces": int(c["pieces"]), "rule": str(c["rule"]), "gun": "", "combo": key}
	if spec.is_empty():
		print("BROKEN " + JSON.stringify({"build": key, "error": "no such build"}))
		quit(0)
		return
	var b: Dictionary = _gauntlet(str(spec["class"]), str(spec["element"]), spec, read_n)
	b["build"] = key
	print("BROKEN " + JSON.stringify(b))
	quit(0)


## The gauntlet (26 Oct, Matt: "a gauntlet" - is it broken, can it smash all content at least once; its kit "the final
## pass's end states"): a one-save read's end (pass/<Class>-<element>.save, its 32 h kit), as played or with a build's
## pieces and recipe put on; the campaign done and the order's places rebuilt; then every piece of the endgame once, in
## order - the Grid, the Archive, the Mint (whose first win is the Issue), the County's twelve zone by zone - each at
## its own level, GAUNTLET_TRIES tries. Before each County zone the issued kit it wants is bought and worn in the slots
## the build leaves free. A death puts the camp back as it was before the try (the kit is the question, not one life).
## A place not won is opened anyway (`forced`), so every later one still gets its fight. Broken: every one won.
const STANDARD_REACH := 55        # DRAFT (31 Oct): to be replaced from the pass's figures at hour 20. Set from the target band alone (level 50 at 12-24 h, the reach near the level), not from a read: no read of the merged build reaches hour 20 yet. Was 90 (Matt, 27 Oct: past the County's top)
const STANDARD_ROLLS := 30        # finds a slot, the best kept
const STANDARD_PARAGON := 5       # DRAFT (31 Oct): to be replaced from the pass's figures at hour 20. Set from the band too (a few paragon levels past 50 at PARAGON_XP_GROW 0.25), not from a read. Was 30 (Matt, 27 Oct)
const GAUNTLET_TRIES := 3
const ISSUED_ORDER := ["Helmet", "Rig", "Charm", "Armour", "Secondary", "Primary"]     # the slots a build gives up first
const GAUNTLET_WALL_MIN := 50     # minutes of wall before the read stops and says so (the fix round, H1: balance.bat kills it at 60)
func _gauntlet(cls: String, element: String, spec: Dictionary, read_n := "", save_path := "", camp := {}) -> Dictionary:
	var out := spec.duplicate(true)
	out["class"] = cls
	out["element"] = element
	var d = null
	var path := ""
	# the pass's read `read_n` (balance.bat's second gauntlet reads the second end state: the fix round), else its
	# first, else its second (the review: one file both wrote)
	# the long pass's (1 Nov, BUILD38): the one save it names, no other
	for n in ([save_path] if save_path != "" else (["-" + read_n] if read_n != "" else []) + ["-1", "-2", ""]):
		path = save_path if save_path != "" else "res://docs/balance/pass/%s-%s%s.save" % [cls, element, n]
		var text := FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
		d = JSON.parse_string(text) if text != "" else null
		if d is Dictionary and d.has("sim"):
			break
	if not (d is Dictionary) or not d.has("sim"):
		out["error"] = "no end state for %s as %s (its read unfinished, or no pass yet)" % [cls, element]
		return out
	out["end_state"] = path.get_file()
	Sim.combos_off = spec.is_empty()         # as played: the balance's own rule; with a build on, its combos count
	var sim = Sim.new()
	sim.load_dict(d["sim"])
	sim.loot_by_hand = false
	sim.fast_memo = true
	sim.odds_runs_max = 24
	if sim.on_mission():
		sim.extract_now()
	sim.expeditions = []                     # a checkpoint's expeditions put away: a lead out can't be played (set_class refuses)
	if sim.cls != cls and not sim.set_class(cls):
		push_error("the read can't take %s from the save (%s)" % [cls, sim.cls])
	var bot = Bot.new()
	bot.cls = cls
	bot.element = element
	bot.crew_on = false
	var walked: Array = []
	for rp in spec.get("recipe", []):
		var rid: String = Data.node_id_named(str(rp))
		var ok: bool = rid != "" and _walk(sim, rid)
		walked.append([str(rp), ok, "" if ok else (sim.train_block(rid) if rid != "" else "no such node")])
	out["recipe"] = walked
	var combo := str(spec.get("combo", ""))
	if combo != "":
		bot.broken = combo
	elif not spec.is_empty():
		bot.hold = {"set": str(spec.get("set", "")), "pieces": int(spec.get("pieces", 0)), "rule": str(spec.get("rule", "")), "gun": str(spec.get("gun", ""))}
	if bot.holding():
		bot._hold_broken(sim)
	var t0 := Time.get_ticks_msec()
	for i in range(Data.TIERS.size()):
		sim.best_depth[i] = maxi(1, int(sim.best_depth[i]))     # the campaign done, as the order's camp would be
	for z in range(sim.bosses_beaten.size()):
		sim.bosses_beaten[z] = true
	for k in ["grid", "archive", "mint"]:
		var ob: String = str(Data.pinnacle(k)["opened_by"])
		sim.rebuilt[ob] = maxi(1, sim.rebuild_rank(ob))
	if sim.level() < 50 and not camp.get("keep_level", false):     # the hour-20 camp keeps its level (BUILD38)
		var before_lv: int = sim.level()
		out["lifted_from"] = before_lv         # a read the bot left under 50 starts the endgame at 50: the bot's pace, not the build's (27 Oct)
		var pts0: int = sim.training_points
		sim.xp = maxf(float(sim.xp), Data.xp_for_level(50))
		sim._earn_points(before_lv)           # the levels' points too, as a runner who got there would have
		out["points_gained"] = sim.training_points - pts0
		bot.tidy(sim)
	out["reach_played"] = sim.reach
	_standard_camp(sim, bot, int(camp.get("reach", STANDARD_REACH)), int(camp.get("paragon", STANDARD_PARAGON)))                   # every build from the same camp (Matt, 27 Oct: the reads' reach was the bot's luck)
	if bot.holding():
		bot._hold_broken(sim)
	out["level0"] = sim.level()
	out["reach0"] = sim.reach
	out["kit0"] = _kit(sim)
	out["on_at_start"] = sim.combo_on(combo) if combo != "" else false
	# an order not yet won first, at its first-win level (the Mint opens the County); the County; then the orders won
	# before, on their ladder over the Treasury (Matt, 27 Oct)
	var content: Array = ["grid", "archive", "mint"].filter(func(k): return int(sim.order_beaten.get(k, 0)) == 0)
	for z in range(Data.COUNTY_ZONES.size()):
		content.append_array(Sim.county_places(z))
	content.append_array(["grid", "archive", "mint"].filter(func(k): return not content.has(k)))
	var run: Dictionary = gauntlet_run(sim, bot, content, GAUNTLET_WALL_MIN * 60000)
	var rows: Array = run["rows"]
	out["cut_short"] = run["cut"]             # stopped at its wall limit: the places after it not fought (H1)
	out["gauntlet"] = rows
	out["won"] = rows.filter(func(r): return r["won"]).size()
	out["of"] = rows.size()
	out["beaten"] = {}
	for r in rows:
		if r["won"]:
			out["beaten"][str(r["key"])] = int(r["tries"])
	out["missing"] = rows.filter(func(r): return not r["won"]).map(func(r): return str(r["key"]))
	out["deaths"] = run["deaths"]
	out["wounds"] = run["wounds"]
	out["tries"] = run["tries"]
	out["first_try"] = rows.filter(func(r): return r["won"] and int(r["tries"]) == 1).size()
	out["issued_worn"] = sim.issued_worn()
	out["on_at_end"] = sim.combo_on(combo) if combo != "" else false
	out["combo_on"] = Data.COMBOS.keys().filter(func(kk): return sim.combo_on(str(kk)))
	out["kit"] = _kit(sim)
	@warning_ignore("integer_division")
	out["wall_s"] = (Time.get_ticks_msec() - t0) / 1000
	return out


## The gauntlet's places in order (_gauntlet's): each fought up to GAUNTLET_TRIES times, the camp put back after a lost
## try; past `limit_ms` of the process's wall (the engine's own clock, the one balance.bat's kill reads) the rest go
## unfought, "cut short" (the fix round, H1: killed at 60 min, it wrote no line). {rows, deaths, wounds, tries, cut}.
static func gauntlet_run(sim, bot, content: Array, limit_ms: int) -> Dictionary:
	var rows: Array = []
	var deaths := 0
	var wounds := 0
	var tries_all := 0
	var cut := false
	for k in content:
		if not cut and Time.get_ticks_msec() >= limit_ms:
			cut = true
		if cut:
			rows.append({"key": k, "level": sim.order_level(k), "won": false, "tries": 0, "forced": false, "why": "cut short: the read's wall limit", "ends": []})
			continue
		var no_kit := ""
		if Sim.is_county(k):
			no_kit = _gauntlet_issued(sim, bot, sim.county_want(int(Data.county(k)["cz"])))
		var row := {"key": k, "level": sim.order_level(k), "won": false, "tries": 0, "forced": false, "why": "", "ends": []}
		for n in range(GAUNTLET_TRIES):
			if Time.get_ticks_msec() >= limit_ms:
				cut = true
				row["why"] = "cut short: the read's wall limit"
				if not row["won"]:
					row["tries"] = 0             # shown cut, not lost three times (the merge's review)
				break
			bot.tidy(sim)
			gauntlet_ready(sim, bot, k)
			var why: String = sim.order_block(k)
			if why != "":
				row["why"] = why + ((" (the Issuer: %s)" % no_kit) if no_kit != "" else "")
				break
			var before: Dictionary = sim.to_dict()
			row["tries"] = n + 1
			row["hp"] = int(sim.max_hp())
			row["dps"] = int(sim.dps())
			var lost: int = sim.operators_lost
			if not sim.deploy_order(k):
				row["why"] = "would not set off"
				break
			var guard := 0
			while sim.on_mission() and guard < 20000:
				sim.advance(1.0)
				if sim.on_mission() and sim.hp < sim.max_hp() * 0.4 and sim.mission["using"] == null and not sim.first_med().is_empty():
					sim.use_med(sim.first_med()["id"])
				if sim.on_mission() and bot.should_leave(sim) and not sim.mission.get("way_out", false) and (n < GAUNTLET_TRIES - 1 or sim.mission["cleared"]):
					sim.get_out()                 # the last try fights to the end, then leaves on the clear (Matt, 27 Oct: a player at a head with nothing to lose)
				guard += 1
			if sim.on_mission():
				sim.extract_now()
			var rep = sim.last_report
			tries_all += 1
			if rep is Dictionary and bool(rep.get("wounded", false)):
				wounds += 1
			if rep is Dictionary:
				row["ends"].append("%s %d/%d %.0fs" % [("timed out" if rep.get("timed_out", false) else str(rep.get("outcome", "?"))), int(rep.get("kills", 0)), int(rep.get("of", 0)), float(rep.get("time", 0.0))])
			var last: Dictionary = {}
			for e in sim.chronicle:
				if str(e.get("k", "")) in ["order_done", "county_done"] and str(e.get("key", "")) == k:
					last = e
			if bool(last.get("won", false)):
				row["won"] = true
				break
			if sim.operators_lost > lost:
				deaths += 1
			sim.load_dict(before)                 # the camp as it was, whatever the loss (a death, a time-out's kit, a bail): the next try is the same kit's (the review)
			if bot.holding():
				bot._hold_broken(sim)
		if not row["won"]:
			row["forced"] = true                  # opened anyway: the places after it get their fight
			sim.order_beaten[k] = maxi(1, int(sim.order_beaten.get(k, 0)))
			if k == "mint" and not sim.issued:
				sim.issue()
		rows.append(row)
	return {"rows": rows, "deaths": deaths, "wounds": wounds, "tries": tries_all, "cut": cut}


## Before each of the gauntlet's tries (the fix round, H8): whole, as a person sets off from the Clinic - the HP and
## every wound seen to (the fixture's Clinic, free: the issued kit's money is the fixture's too) - and the bot's three
## skills picked for the place's site, as its step picks them before a run.
static func gauntlet_ready(sim, bot, k: String) -> void:
	sim.hp = sim.max_hp()
	if not sim.wounds.is_empty():
		sim.wounds = {}
		sim._dry_memo.clear()
	bot.pick_skills(sim, int(Data.pinnacle(k)["site"]))


## The standard camp (Matt, 27 Oct, docs/design/pinnacle_and_exploits.md): the reach at STANDARD_REACH, the paragon at
## STANDARD_PARAGON, and every slot's
## kit at its item level - a unique or a set piece worn rolled again as itself, the rest the best of STANDARD_ROLLS finds
## of the slot (a gun of the type worn), no commons; issued kit as the counter sells it at the camp's reach, a stamped
## piece stamped still. The rig as it is; the build's held pieces after, by _hold_broken.
## `reach` and `par` the long pass's camp from its reads' hour 20 (1 Nov, BUILD38); the constants otherwise.
func _standard_camp(sim, bot, reach := STANDARD_REACH, par := STANDARD_PARAGON) -> void:
	sim.reach = reach
	# the paragon at STANDARD_PARAGON, spent again by the bot (Matt, 27 Oct: the two that cleared everything had 673 and 213)
	sim.paragon_xp = Data.xp_for_level(Data.MAX_LEVEL + par) - Data.xp_for_level(Data.MAX_LEVEL)
	sim.paragon_reset_free()
	var lv: int = mini(Items.max_ilvl_for(sim.level()), reach)
	var tier: int = sim.tier_for_level(lv)
	# the stash's kit past the camp's level goes: the bot's tidy wore it again (a read's ilvl-155 plate, 164k HP)
	sim.stash = sim.stash.filter(func(x): return not (x is Dictionary and str(x.get("slot", "")) in Data.SLOTS and Items.ilvl(x) > lv))
	for sl in Data.SLOTS:
		var worn = sim.equipped.get(sl)
		var fresh: Dictionary = {}
		if worn != null and worn.get("issued", false):
			fresh = sim.issued_piece(sl, -1, true)     # issued kit at the camp's reach too (a read's came in at item level 155)
		elif worn != null and worn.has("pattern") and not worn.has("unique"):
			# a patterned piece: the best find of the slot at the camp's level, with the pattern's rule put on it (the review)
			var pb: Dictionary = {}
			var pb_sc := -INF
			for k in range(STANDARD_ROLLS):
				var cand: Dictionary = Items.roll(sl, tier, sim.rng, sim.rarity_bonus(), true, false, "", "", 0.33, 0, lv)
				if cand.is_empty() or not sim.can_wear(cand):
					continue
				var csc: float = sim.fit_value(cand, sl)
				if csc > pb_sc:
					pb = cand
					pb_sc = csc
			fresh = pb if not pb.is_empty() else worn.duplicate(true)
			fresh["rule"] = worn["rule"]
			fresh["pattern"] = worn["pattern"]
		elif worn != null and worn.has("unique"):
			fresh = Items.roll_unique(sim._unique_named(str(worn["unique"])), sim.rng, lv, tier)
		elif worn != null and worn.has("set"):
			var st: Dictionary = Items.set_named(str(worn["set"]))
			for pc in st.get("pieces", []):
				if str(pc["slot"]) == sl:
					fresh = Items.roll_set_piece(str(worn["set"]), pc, sim.rng, lv, tier)
		else:
			var want_type: String = str(Items.base_of(worn).get("type", "")) if worn != null and sl in ["Primary", "Secondary"] else ""
			var want_ammo: String = Items.ammo_type(worn) if want_type != "" else ""     # and the rounds it fires (the three-stage review, game 9)
			var best: Dictionary = {}
			var best_sc := -INF
			for k in range(STANDARD_ROLLS * (4 if want_type != "" else 1)):
				var it: Dictionary = Items.roll(sl, tier, sim.rng, sim.rarity_bonus(), true, false, "", want_type, 0.33, 0, lv)
				if it.is_empty() or not sim.can_wear(it) or (want_type != "" and (str(Items.base_of(it).get("type", "")) != want_type or Items.ammo_type(it) != want_ammo)):
					continue
				# as a player keeps: tried on, the slot's own read (HP and damage both, Matt 27 Oct); the build's own gun by its score
				var sc: float = bot._elem_score(it, sim) if bot.element != "" and sl == "Primary" else sim.fit_value(it, sl)
				if best.is_empty() or sc > best_sc:
					best = it
					best_sc = sc
			fresh = best
		if not fresh.is_empty() and worn != null and worn.get("stamped", false):
			fresh["stamped"] = true                # stamped at the Bench: it still counts for the County
		if not fresh.is_empty():
			# the old gun's parts on the new where a mount matches: the element's socketable with them (the review)
			if worn != null and worn.has("attachments") and fresh.has("attachments") and fresh != worn:
				for mount in worn["attachments"]:
					var part = worn["attachments"][mount]
					# a part at or under the camp's level, or a socketable (its figure is its base's); a deeper part's mount left for the tidy
					if (fresh["attachments"].has(mount) or str(mount).begins_with("socket")) and part != null and (Items.is_socketable(part) or Items.ilvl(part) <= lv):
						fresh["attachments"][mount] = worn["attachments"][mount]
			sim.equipped[sl] = fresh
			sim._mag_with(fresh)                   # its standard magazine to the stash, as a gun got brings (the three-stage review, game 9)
	while sim.rig_used() > sim.med_capacity() and not sim.rig.is_empty():
		sim.rig.pop_back()                      # a new rig with fewer pouches: the last of its contents go
	sim._dry_memo.clear()
	bot._tidied_at = -1e9                     # a tidy now, whatever the lift's just did (the review: inside its minute it was a no-op)
	bot.tidy(sim)


## Room in the stash for an issued piece (27 Oct: a full stash kept a Recruit out of the County): the cheapest pieces
## that aren't issued go to the Fence till there's room for the biggest piece.
static func _gauntlet_room(sim) -> void:
	var guard := 0
	while not sim.stash_room(6) and guard < 400:
		var spare: Array = sim.stash.filter(func(x): return x is Dictionary and not x.get("issued", false) and not x.has("deeds"))
		if spare.is_empty():
			return
		spare.sort_custom(func(a, b): return sim.sell_price(a) < sim.sell_price(b))
		sim.stash.erase(spare[0])
		guard += 1


## Issued kit for a County zone: bought at the counter (the fixture's money) and worn, the slots the build holds kept,
## till `want` are on. Why a piece wasn't bought, if one wasn't ("Wear at level 50": the runner's under the County).
static func _gauntlet_issued(sim, bot, want: int) -> String:
	var why := ""
	var cash0: float = sim.cash               # the fixture's money buys the issued kit alone (the review: the shop spent the rest)
	for sl in ISSUED_ORDER:
		if sim.issued_worn() >= want:
			break
		if sl in bot.broken_slots:
			continue
		var w = sim.equipped.get(sl)
		if w != null and w.get("issued", false):
			continue
		if sl in ["Primary", "Secondary"] and w != null:
			# the build's own gun stamped, never swapped for the Issuer's (as Bot._issued; the fix round's analyst: the
			# gauntlet bought issued guns over the build's, and the poison builds' 'losses' were the issued guns')
			if not w.get("stamped", false):
				sim.cash = maxf(sim.cash, float(sim.stamp_price(w)) * 2.0)
				if not sim.stamp(int(w["id"])):
					why = sim.stamp_block(w)
			continue
		sim.cash = maxf(sim.cash, float(sim.issued_price(sl)) * 2.0)
		_gauntlet_room(sim)
		if sim.buy_issued(sl):
			sim.equip_item(sim.stash.back()["id"])
			sim._dry_memo.clear()
		else:
			why = sim.issued_block(sl)
	# short still: the build's own held pieces stamped at the Bench (Matt, 26 Oct: stamping for entry)
	for sl in bot.broken_slots:
		if sim.issued_worn() >= want:
			break
		var held = sim.equipped.get(sl)
		if held == null or held.get("stamped", false) or held.get("issued", false):
			continue
		sim.cash = maxf(sim.cash, float(sim.stamp_price(held)) * 2.0)
		if not sim.stamp(int(held["id"])):
			why = sim.stamp_block(held)
	sim.cash = cash0
	return why if sim.issued_worn() < want else ""


## The build hunt (26 Oct, Matt: "cook some different builds up - the whole point is broken builds not these specific
## builds being broken"): every class's two joints, each with every set at its count or none (stage 1); the stage's
## best HUNT_TOP, each with every unique whose slot the set leaves free (stage 2). This shard's share of the stage's
## list, a short read each, one HUNT {json} line a build; the summary ranks them (balance_summary.gd -- hunt).
func _hunt(hours: float, stage: int, shard: int, shards: int) -> void:
	var specs: Array = _hunt_specs(stage)
	print("Fiat build hunt: stage %d, shard %d of %d, %d builds in the stage, %.1f h each" % [stage, shard, shards, specs.size(), hours])
	for i in range(specs.size()):
		if i % maxi(1, shards) != shard:
			continue
		var b: Dictionary = _build_read(hours, specs[i], false, false)
		b["stage"] = stage
		print("HUNT " + JSON.stringify(b))
	quit(0)


## A joint's build (the class's half of an element): its class, element, the four nodes (the class lane's joint half,
## the element's class half, its keystone and capstone) and its gun type (the element half's, else the class's).
func _joint_build(j: Dictionary) -> Dictionary:
	var key := str(j["key"])
	var et: Dictionary = Data.tree_named(str(j["element_tree"]))
	var ct: Dictionary = Data.tree_named(str(j["tree"]))
	var recipe: Array = []
	var gun := ""
	for nd in ct["nodes"]:
		if str(nd.get("joint", "")) == key:
			recipe.append("%s/%s" % [ct["name"], nd["name"]])
	for nd in et["nodes"]:
		if str(nd.get("joint", "")) == key:
			recipe.append("%s/%s" % [et["name"], nd["name"]])
			var ty = nd.get("type", "")
			gun = str(ty[0]) if ty is Array and not ty.is_empty() else str(ty)
	for flag in ["keystone", "capstone"]:
		for nd in et["nodes"]:
			if nd.get(flag, false):
				recipe.append("%s/%s" % [et["name"], nd["name"]])
	if gun == "":
		gun = str(Bot.TYPE_OF.get(str(j["class"]), ""))
	return {"joint": key, "class": str(j["class"]), "element": key.get_slice("_", 1), "recipe": recipe, "gun": gun}


## A HUNT line's build again as a spec (its recipe from the tables: the line's own is the walk's [path, ok, why]).
func _hunt_spec(row: Dictionary) -> Dictionary:
	for j in Data.JOINTS:
		if str(j["key"]) == str(row.get("joint", "")):
			return _joint_build(j).merged({"id": str(row.get("id", "")), "set": str(row.get("set", "")), "pieces": int(row.get("pieces", 0)),
				"rule": str(row.get("rule", "")), "unique": str(row.get("unique", "")), "combo": ""}, true)
	return {}


## The stage's list, the same in every shard: stage 1 from the tables, stage 2 from stage 1's lines on disk.
func _hunt_specs(stage: int) -> Array:
	var out: Array = []
	if stage == 1:
		for j in Data.JOINTS:
			var jb: Dictionary = _joint_build(j)
			out.append(jb.merged({"id": "%s" % jb["joint"], "set": "", "pieces": 0, "rule": "", "combo": ""}))
			for st in Data.SETS:
				out.append(jb.merged({"id": "%s+%s" % [jb["joint"], st["name"]], "set": str(st["name"]), "pieces": int(st["pieces"].size()), "rule": "", "combo": ""}))
		return out
	var top: Array = _hunt_ranked(1).slice(0, HUNT_TOP)
	for sp in top:
		var used := {}
		if str(sp["set"]) != "":
			for pc in Items.set_named(str(sp["set"]))["pieces"]:
				used[str(pc["slot"])] = true
		for u in Data.UNIQUES:
			if str(u.get("rule", "")) == "" or used.has(str(u["slot"])):
				continue
			var s2: Dictionary = _hunt_spec(sp).merged({"rule": str(u["rule"]), "unique": str(u["name"]), "id": "%s+%s" % [sp["id"], u["name"]]}, true)
			out.append(s2)
	return out


## A stage's HUNT lines on disk, best first: the damage really dealt a second fought, then the reach gained.
func _hunt_ranked(stage: int) -> Array:
	var rows: Array = []
	for f in DirAccess.get_files_at(HUNT_DIR):
		if not (f.begins_with("hunt-s%d-" % stage) and f.ends_with(".txt")):
			continue
		for line in FileAccess.get_file_as_string(HUNT_DIR + f).split("\n"):
			if line.begins_with("HUNT {"):
				var d = JSON.parse_string(line.substr(5))
				if d is Dictionary and not d.has("error"):
					rows.append(d)
	rows.sort_custom(func(x, y):
		if float(x.get("rate", 0.0)) != float(y.get("rate", 0.0)):
			return float(x.get("rate", 0.0)) > float(y.get("rate", 0.0))
		return str(x.get("id", "")) < str(y.get("id", "")))
	return rows


## The build's start (the broken reads', the hunt's, the gauntlet's): the Radio's checkpoint at level 50, the spec's
## class, its recipe walked, its pieces held, the combos on unless `plain`. {sim, bot, walked} or {error}.
func _fixture(spec: Dictionary, plain: bool) -> Dictionary:
	var text := FileAccess.get_file_as_string(CHECKPOINT)
	var d = JSON.parse_string(text) if text != "" else null
	if not (d is Dictionary) or not d.has("sim"):
		return {"error": "no checkpoint at " + CHECKPOINT}
	Sim.combos_off = plain                   # this read alone: the build's whole point (the plain baseline keeps them off)
	var sim = Sim.new()
	sim.load_dict(d["sim"])
	sim.loot_by_hand = false
	sim.fast_memo = true
	sim.odds_runs_max = 24
	var cls: String = str(spec["class"])
	var kit0: Dictionary = sim.equipped.duplicate(true)
	var rig0: Array = sim.rig.duplicate(true)
	var xp0: float = float(sim.xp)
	sim.expeditions = []                     # as the parity read's (29 Oct)
	if sim.cls != cls and not sim.set_class(cls):
		push_error("the fixture can't take %s (%s)" % [cls, sim.cls])
	sim.xp = xp0
	sim.equipped = kit0
	sim.rig = rig0
	sim.tree = sim.tree.filter(func(id): return sim.is_camp(str(id)))
	sim.skill_slots = ["", "", ""]
	# at level 50 (the build's keystone and capstone want it, as the smoke walks the recipes): the camp the checkpoint's,
	# the runner the build's whole
	sim.xp = maxf(float(sim.xp), Data.xp_for_level(50))
	sim.best_level = maxi(int(sim.best_level), 50)
	var walked: Array = []
	for path in spec.get("recipe", []):
		var rid: String = Data.node_id_named(str(path))
		var ok: bool = rid != "" and _walk(sim, rid)
		walked.append([str(path), ok, "" if ok else (sim.train_block(rid) if rid != "" else "no such node")])
	var bot = Bot.new()
	bot.cls = cls
	bot.element = str(spec.get("element", ""))
	bot.crew_on = false
	# the baseline holds the same pieces too, the combo off: the one difference (the review)
	var combo := str(spec.get("combo", ""))
	if combo != "":
		bot.broken = combo
	else:
		bot.hold = {"set": str(spec.get("set", "")), "pieces": int(spec.get("pieces", 0)), "rule": str(spec.get("rule", "")), "gun": str(spec.get("gun", ""))}
	bot._hold_broken(sim)
	sim._dry_memo.clear()
	sim.hp = sim.max_hp()
	return {"sim": sim, "bot": bot, "walked": walked}


## One build's read from the Radio's checkpoint at level 50 (the hunt's): the spec's class,
## recipe walked, pieces held, the combos on unless `plain`, the runner staying out; `full` the half-hour lines and
## the shop as the broken read prints them. What it beat, the reach, and the damage really dealt a second fought
## (each run's fight breakdown: dealt over its seconds fighting) - over all runs, and over the long ones (ten
## patrols or more) and the short apart: a build that runs away deals more the longer it's out.
func _build_read(hours: float, spec: Dictionary, plain: bool, full: bool) -> Dictionary:
	var out := spec.duplicate(true)
	var fx: Dictionary = _fixture(spec, plain)
	if fx.has("error"):
		out["error"] = fx["error"]
		return out
	var sim = fx["sim"]
	var bot = fx["bot"]
	var walked: Array = fx["walked"]
	var cls: String = str(spec["class"])
	var combo := str(spec.get("combo", ""))
	bot.stay_out = STAY_OUT
	var start_s: float = sim.elapsed
	out.merge({"plain": plain, "hours": hours, "recipe": walked, "on_at_start": sim.combo_on(combo) if combo != "" else false,
		"reach0": sim.reach, "level0": sim.level(), "dps0": snappedf(float(sim.damage_split()["total"]), 0.1), "runs": 0, "deaths": 0, "patrols": 0}, true)
	var dealt := [0.0, 0.0, 0.0]               # all, long runs, short runs
	var fought := [0.0, 0.0, 0.0]
	var t_end: float = sim.elapsed + hours * 3600.0
	var t0 := Time.get_ticks_msec()
	var next_mark: float = sim.elapsed + 1800.0
	if full:
		print("Fiat broken read: %s (%s as %s)%s, %.0f h from the checkpoint; on: %s" % [spec.get("id", "?"), cls, bot.element, " - the plain baseline" if plain else "", hours, str(out["on_at_start"])])
	while sim.elapsed < t_end and Time.get_ticks_msec() - t0 < 12600000:
		var lost: int = sim.operators_lost
		var on_going: bool = combo != "" and sim.combo_on(combo)
		var t: int = bot.step(sim)
		if t >= 0:
			out["runs"] += 1
			out["runs_on"] = int(out.get("runs_on", 0)) + (1 if on_going else 0)     # the build on as the run set off (the review)
			if sim.operators_lost > lost:
				out["deaths"] += 1
			var rep = sim.last_report
			if rep is Dictionary and rep.has("fight"):
				var fd: float = float(rep["fight"].get("dealt", 0.0))
				var fs: float = float(rep["fight"].get("s", 0.0))
				var long_run: bool = int(rep.get("patrols", 0)) >= 10
				out["patrols"] += int(rep.get("patrols", 0))
				var how: String = "timed out" if rep.get("timed_out", false) else str(rep.get("outcome", "?"))
				out["ends"] = out.get("ends", {})
				out["ends"][how] = int(out["ends"].get(how, 0)) + 1
				for k in [0, 1 if long_run else 2]:
					dealt[k] += fd
					fought[k] += fs
			bot.tidy(sim)
		if full and sim.elapsed >= next_mark:
			next_mark += 1800.0
			print("%s | reach %d | level %d | dps %.0f | dealt/s %.0f | hp %.0f | on %s | fiat %s | county %d" % [_hm(sim.elapsed - start_s), sim.reach, sim.level(), sim.dps(),
				dealt[0] / maxf(1.0, fought[0]), sim.max_hp(), str(combo != "" and sim.combo_on(combo)), str(sim.issued), sim.county_taken_count()])
	# what it beat, and when (hours from its start)
	var beaten := {}
	var top_signal := 0
	for e in sim.chronicle:
		if float(e.get("t", 0.0)) < start_s:
			continue
		var h: float = snappedf((float(e.get("t", 0.0)) - start_s) / 3600.0, 0.01)
		match str(e.get("k", "")):
			"order_done":
				if e.get("won", false) and not beaten.has(str(e["key"])):
					beaten[str(e["key"])] = h
			"county_done":
				if e.get("won", false) and not beaten.has(str(e["key"])):
					beaten[str(e["key"])] = h
			"issue":
				if not beaten.has("issue"):
					beaten["issue"] = h
			"signal_done":
				if e.get("won", false):
					top_signal = maxi(top_signal, int(e.get("level", 0)))
	var content: Array = ["grid", "archive", "mint", "issue"]
	for cc in Data.COUNTY:
		content.append(str(cc["key"]))
	out["beaten"] = beaten
	out["missing"] = content.filter(func(k): return not beaten.has(k))
	out["top_signal_won"] = top_signal
	out["reach1"] = sim.reach
	out["level1"] = sim.level()
	out["dps1"] = snappedf(float(sim.damage_split()["total"]), 0.1)
	out["rate"] = snappedf(dealt[0] / maxf(1.0, fought[0]), 0.1)            # the damage really dealt a second fought
	out["rate_long"] = snappedf(dealt[1] / maxf(1.0, fought[1]), 0.1) if fought[1] > 0.0 else -1.0
	out["rate_short"] = snappedf(dealt[2] / maxf(1.0, fought[2]), 0.1) if fought[2] > 0.0 else -1.0
	out["on_at_end"] = sim.combo_on(combo) if combo != "" else false
	out["combo_on"] = Data.COMBOS.keys().filter(func(k): return sim.combo_on(str(k)))     # a hunted build that is one of the six
	out["issued_worn"] = sim.issued_worn()
	out["played_h"] = snappedf((sim.elapsed - start_s) / 3600.0, 0.01)
	out["cut_short"] = sim.elapsed < t_end
	out["kit"] = _kit(sim)
	@warning_ignore("integer_division")
	out["wall_s"] = (Time.get_ticks_msec() - t0) / 1000
	if full:
		for x in bot.bought:
			print("  %s at %s" % [x[1], _hm(x[0] - start_s)])
	return out


## A node trained from nothing as the smoke walks a recipe: each step on its path, its points given if short.
func _walk(sim, id: String) -> bool:
	for k in range(60):
		if sim.tree.has(id):
			return true
		var nxt: String = id if (sim.touches_trained(id) or Data.web_entry(sim.node(id))) else sim.path_next(id)
		if nxt == "":
			return false
		if sim.free_for(nxt) < sim.node_cost(nxt):
			if sim.is_pitch(nxt):
				sim.best_level += sim.node_cost(nxt)
			elif sim.element_of(nxt) != "":
				sim.element_points[sim.element_of(nxt)] = int(sim.element_points.get(sim.element_of(nxt), 0)) + sim.node_cost(nxt)
			else:
				sim.training_points += sim.node_cost(nxt)
		if not sim.train_node(nxt):
			return false
	return false


const PARITY_WALL_MIN := 50      # minutes of wall before a parity read stops and says so (the fix round, H1: balance.bat kills it at 60)
func _parity(hours: float, cls: String, element: String, cap_min := PARITY_WALL_MIN) -> void:
	var text := FileAccess.get_file_as_string(CHECKPOINT)
	var d = JSON.parse_string(text) if text != "" else null
	if not (d is Dictionary) or not d.has("sim"):
		print("PARITY " + JSON.stringify({"build": "%s as %s" % [cls, element], "error": "no checkpoint at " + CHECKPOINT}))
		quit(0)
		return
	var sim = Sim.new()
	sim.load_dict(d["sim"])
	sim.loot_by_hand = false
	sim.fast_memo = true
	sim.odds_runs_max = 24
	# every build starts alike (the review): the checkpoint runner's level, points and kit, the class's own trees empty
	# and the points free for the build to spend - the checkpoint's own class included, so its tree is no head start
	var xp0: float = float(sim.xp)
	var pts0: int = int(sim.training_points)
	var best0: int = int(sim.best_level)
	var kit0: Dictionary = sim.equipped.duplicate(true)
	var rig0: Array = sim.rig.duplicate(true)
	sim.expeditions = []                     # a checkpoint's expeditions put away: a lead out can't be played (29 Oct)
	if sim.cls != cls and not sim.set_class(cls):     # a parity read takes the class whether the save had opened it or not
		push_error("the parity read can't take %s (%s)" % [cls, sim.cls])
	sim.xp = xp0
	sim.training_points = pts0
	sim.best_level = best0
	sim.equipped = kit0
	sim.rig = rig0
	sim.tree = sim.tree.filter(func(id): return sim.is_camp(str(id)))
	sim.skill_slots = ["", "", ""]
	sim._dry_memo.clear()
	sim.hp = sim.max_hp()
	var p: Dictionary = parity_play(sim, parity_bot(cls, element), hours, cap_min * 60000)
	p.merge({"build": "%s as %s" % [cls, element], "class": cls, "element": element, "from_h": float(d.get("hour", 0.0)), "wall_cap_min": cap_min}, true)
	p["kit"] = _kit(sim)
	print("PARITY " + JSON.stringify(p))
	quit(0)


## The parity read's bot: the build's own class for the whole spell (no crew), and no repeat runs (the fix round, H7:
## a repeat set off near the spell's end ran on past it, so the reads' spells differed).
static func parity_bot(cls: String, element: String):
	var bot = Bot.new()
	bot.cls = cls
	bot.element = element
	bot.crew_on = false                      # one class for the spell: the comparison is the build's own
	bot.repeats = false
	return bot


## The parity read's spell: `hours` of the yard's time from where the sim stands, or till `limit_ms` of the process's
## wall (the engine's clock, the one balance.bat's kill reads; the fix round, H1), the line saying which (cut_short).
static func parity_play(sim, bot, hours: float, limit_ms: int) -> Dictionary:
	var start_s: float = sim.elapsed
	var p := {"hours": hours, "reach0": sim.reach, "level0": sim.level(), "dps0": snappedf(float(sim.damage_split()["total"]), 0.1), "runs": 0, "deaths": 0,
		"signals_won": 0, "signals_run": 0, "norepeat": not bot.repeats}
	var t_end: float = sim.elapsed + hours * 3600.0
	var t0 := Time.get_ticks_msec()
	while sim.elapsed < t_end and Time.get_ticks_msec() < limit_ms:
		var lost: int = sim.operators_lost
		var t: int = bot.step(sim)
		if t >= 0:
			p["runs"] += 1
			if sim.operators_lost > lost:
				p["deaths"] += 1
			bot.tidy(sim)
	for e in sim.chronicle:
		if str(e.get("k", "")) == "signal_done" and float(e.get("t", 0.0)) >= start_s:
			p["signals_run"] += 1
			p["signals_won"] += 1 if e.get("won", false) else 0
	p["reach1"] = sim.reach
	p["level1"] = sim.level()
	p["dps1"] = snappedf(float(sim.damage_split()["total"]), 0.1)
	p["played_h"] = snappedf((sim.elapsed - start_s) / 3600.0, 0.01)     # a read the wall cut short says so (the review)
	p["cut_short"] = sim.elapsed < t_end
	p["reach_gain"] = int(p["reach1"]) - int(p["reach0"])
	p["level_gain"] = int(p["level1"]) - int(p["level0"])
	@warning_ignore("integer_division")
	p["wall_s"] = (Time.get_ticks_msec() - t0) / 1000
	return p



## The expeditions in a read (29 Oct, the fix round; shown, not judged): sent, home, held, fetched, walked from, the
## cargo's worth out and the returns' worth in, the wages, the scrap shipped.
static func exp_gates(sim, bot) -> Dictionary:
	return {"sent": int(bot.exp_sent), "back": int(sim.exp_back_n), "held": int(sim.exp_held_n), "fetched": int(bot.exp_fetched), "paid": int(bot.exp_paid),
		"walked": int(bot.exp_walked), "cargo_out": int(sim.exp_worth_out), "return_in": int(sim.exp_return_in), "wages": int(sim.exp_wages_paid), "scrap_out": int(sim.exp_scrap_out)}


## ------------------------------------------------------------------ the long pass (1 Nov, BUILD38)
## `tools\balance.bat 24 1 long`: six one-save reads, one a class, 24 game hours each with no two-hour stop (each stops
## itself at LONG_WALL_MIN under balance.bat's 480-minute kill); an HOUR line every game hour, the state at hour 20 kept;
## then the gauntlet twice a build - from the end state with the standard camp (as the full pass's), and from the hour-20
## state at the camp the six reads' hour 20 made (the median reach and paragon, each build's own kit and level).

## The long read's saves: its end state, or its state at hour 20 (long_snap_h).
static func long_save_path(cls: String, element: String, h20: bool) -> String:
	return "res://docs/balance/pass/long-%s-%s%s.save" % [cls, element, "-h20" if h20 else ""]


## Every XP a camp holds: each class's (the runner's live, the crew's on the roster), the runner's name, the paragon's.
static func xp_book(sim) -> Dictionary:
	var x := {}
	for n in sim.roster:
		x[str(n)] = float(sim.roster[n].get("xp", 0.0))
	if sim.cls != "":
		x[str(sim.cls)] = float(sim.xp)
	return {"p": float(sim.paragon_xp), "x": x, "r": str(sim.cls)}


## A step's XP by where it came from (the long pass's HOUR lines; PROBE36's sources, read from outside the game): the
## step's own chronicle names it - a repeat, a County place, an order (grid, archive, mint), Kev's story signal, a
## signal, a site's run - in that order; a benched class's XP is an expedition's; a class swapped in lifted to the crew's
## floor is "lift"; XP a death took back is "lost". The paragon's goes with the step's, or the expedition's on a step
## with nothing else.
static func xp_split(b0: Dictionary, b1: Dictionary, entries: Array, repeat: bool) -> Dictionary:
	var kinds := {}
	var lifted := {}
	for e in entries:
		var k := str(e.get("k", ""))
		if not kinds.has(k):
			kinds[k] = e
		if k == "swap":
			lifted[str(e.get("to", ""))] = Data.xp_for_level(int(e.get("level", 1)))
	var src := "other"
	if repeat:
		src = "repeats"
	elif kinds.has("county_done"):
		src = "county"
	elif kinds.has("order_done"):
		src = str(kinds["order_done"].get("key", "order"))
	elif kinds.has("signal_done"):
		src = "kev" if kinds["signal_done"].get("story", false) else "signals"
	elif kinds.has("run"):
		src = "sites"
	var out := {}
	var x0: Dictionary = b0.get("x", {})
	var x1: Dictionary = b1.get("x", {})
	var runners: Array = [str(b0.get("r", "")), str(b1.get("r", ""))]
	var exp_xp := 0.0
	for c in x1:
		var a: float = float(x0.get(c, 0.0))
		var d: float = float(x1[c]) - a
		if lifted.has(c):
			var lift: float = clampf(float(lifted[c]) - a, 0.0, maxf(0.0, d))
			if lift > 0.0:
				out["lift"] = float(out.get("lift", 0.0)) + lift
			d -= lift
		if d < 0.0:
			out["lost"] = float(out.get("lost", 0.0)) - d
		elif d > 0.0:
			var to: String = src if (c in runners) else "expeditions"
			if to == "expeditions":
				exp_xp += d
			out[to] = float(out.get(to, 0.0)) + d
	var dp: float = float(b1.get("p", 0.0)) - float(b0.get("p", 0.0))
	if dp > 0.0:
		var pto: String = "expeditions" if src == "other" and exp_xp > 0.0 else src
		out[pto] = float(out.get(pto, 0.0)) + dp
	return out


## After each step of a long read: the Issue's hour and the County's first wins off the chronicle, the state at hour
## long_snap_h kept, and an HOUR line for every game hour the step passed.
static func long_book(sim, cls: String, element: String, g: Dictionary, lg: Dictionary, _c0: int) -> void:
	var ci: int = int(lg.get("chron_i", 0))
	for i in range(mini(ci, sim.chronicle.size()), sim.chronicle.size()):
		var e: Dictionary = sim.chronicle[i]
		var k := str(e.get("k", ""))
		if k == "issue" and float(lg["issue_at"]) < 0.0:
			lg["issue_at"] = snappedf(float(e.get("t", sim.elapsed)) / 3600.0, 0.01)
		elif k == "county_done" and e.get("won", false):
			if not lg.has("county"):
				lg["county"] = []
			if not lg["county"].any(func(x): return str(x[1]) == str(e.get("key", ""))):
				lg["county"].append([snappedf(float(e.get("t", sim.elapsed)) / 3600.0, 0.01), str(e.get("key", ""))])
	lg["chron_i"] = sim.chronicle.size()
	if not bool(lg["h20"]) and sim.elapsed >= long_snap_h * 3600.0 and not sim.on_mission():
		long_h20(sim, cls, element, g, lg, false)
	var n_rows := 0
	while sim.elapsed >= float(lg["next_h"]) * 3600.0:
		var row: Dictionary = long_row(sim, cls, g, lg, float(lg["next_h"]), false)
		if n_rows > 0:
			row["same_step"] = true          # one step past several hours (the review): this hour's state is the step's end, its window empty
		print("HOUR " + JSON.stringify(row))
		n_rows += 1
		lg["next_h"] = int(lg["next_h"]) + 1


## One HOUR line: the hour, the build's level (the runner's too), the reach, the paragon and its points unspent, the cash
## held and earned that hour, XP that hour by source, the deaths (all told and that hour), the Issue's hour, the County's
## places won (and the new ones). The window's figures start again after it.
static func long_row(sim, cls: String, g: Dictionary, lg: Dictionary, h: float, end: bool) -> Dictionary:
	var xp := {}
	for k in lg["xp"]:
		xp[k] = snappedf(float(lg["xp"][k]), 1.0)
	var county: Array = lg.get("county", [])
	var row := {"h": h, "at": snappedf(sim.elapsed / 3600.0, 0.01), "end": end, "runner": str(sim.cls), "level": sim.crew_level(cls), "runner_level": sim.level(),
		"reach": sim.reach, "paragon": sim.paragon(), "paragon_free": sim.paragon_free(), "cash": snappedf(float(sim.cash), 1.0),
		"earned": snappedf(float(sim.cash_in) - float(lg["cash_from"]), 1.0), "xp": xp, "deaths": int(g["deaths"]), "deaths_h": int(g["deaths"]) - int(lg["deaths_from"]),
		"issue_at": lg["issue_at"], "county": county.size(), "county_new": county.slice(int(lg["county_n"])).map(func(x): return str(x[1]))}
	lg["xp"] = {}
	lg["cash_from"] = float(sim.cash_in)
	lg["deaths_from"] = int(g["deaths"])
	lg["county_n"] = county.size()
	return row


## The state at hour long_snap_h (or the read's end, when it ended before): pass/long-<Class>-<element>-h20.save, the
## read's own build put out on a copy first, as the end state is (its kit, its level on the crew's floor); an H20 line.
static func long_h20(sim, cls: String, element: String, g: Dictionary, lg: Dictionary, at_end: bool) -> void:
	var cp = Sim.new()
	cp.load_dict(sim.to_dict())
	if cp.on_mission():
		cp.extract_now()
	var b2 = Bot.new()
	b2.cls = str(cp.cls)
	b2.element = element if cp.cls == cls else str(Bot.CREW_BUILDS.get(str(cp.cls), ""))
	b2.builds = {cls: {"element": element, "keystones_first": false}}
	end_as_build(cp, b2, cls)
	var path := long_save_path(cls, element, true)
	var h: float = snappedf(sim.elapsed / 3600.0, 0.01)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"sim": cp.to_dict(), "hour": h, "snap_h": long_snap_h}))
		f.close()
	lg["h20"] = true
	g["h20_at"] = h
	g["h20_save"] = path
	print("H20 " + JSON.stringify({"at": h, "snap_h": long_snap_h, "end": at_end, "save": path, "class": str(cp.cls), "level": cp.level(), "reach": cp.reach, "paragon": cp.paragon()}))


## The long read's end: the last part-hour's HOUR line (`end`), the hour-20 state if the read never got there, and its
## figures on the GATES line.
static func long_end(sim, cls: String, element: String, g: Dictionary, lg: Dictionary) -> void:
	long_book(sim, cls, element, g, lg, 0)
	if not bool(lg["h20"]):
		long_h20(sim, cls, element, g, lg, true)
	print("HOUR " + JSON.stringify(long_row(sim, cls, g, lg, snappedf(sim.elapsed / 3600.0, 0.01), true)))
	g["long"] = true
	g["deaths_after_qm"] = int(lg["deaths_after_qm"])
	g["xp_lost"] = snappedf(float(lg["lost"]), 1.0)
	g["snap_h"] = long_snap_h


## The long pass's gauntlet (`-- 0 gauntlet <Class> <element> long|h20`): from the long read's end state with the
## standard camp, as the full pass's; or from its hour-20 state at the camp the six reads' hour 20 made
## (tools/balance_summary.gd long_camp: the median reach and paragon), its level kept.
func _long_gauntlet(cls: String, element: String, h20: bool) -> Dictionary:
	var camp := {}
	if h20:
		var Sum = load("res://tools/balance_summary.gd")
		camp = Sum.long_camp(Sum.long_reads())
		if int(camp.get("n", 0)) == 0:
			return {"class": cls, "element": element, "long": "h20", "error": "no hour-20 figures in the pass's long reads"}
		camp["keep_level"] = true
	var out: Dictionary = _gauntlet(cls, element, {}, "", long_save_path(cls, element, h20), camp)
	out["long"] = "h20" if h20 else "end"
	if h20:
		out["camp"] = camp
	return out
