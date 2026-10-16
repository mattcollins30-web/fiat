extends SceneTree
## The loot read (15 Oct, parked item 17, Matt: "firstly inconsistent"): what each source hands out at four points of
## the campaign and two of the endgame - a kill's drop and a search's find on every open site, the gamble - by rarity,
## the level to wear against the runner's, and the uniques and set pieces. `godot --headless --path . -s
## tests/loot_read.gd` writes docs/balance/loot_read.md.
const Sim := preload("res://scripts/sim/sim.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const N := 600
# [the point, sites open to (index), the runner's level there (Matt's 14 Oct save, the bot's for the endgame), signal depth]
const POINTS := [["Outskirts done", 2, 5, 1], ["Estate done", 5, 11, 1], ["Town done", 8, 17, 1], ["City done", 11, 22, 1], ["Signals, level 14", 11, 30, 6], ["Signals, level 20", 11, 40, 12]]     # D6: the levels the D5 read reached them at; a signal's level on the Barracks


func _init() -> void:
	seed(11)
	Sim.fixed_seed = 11
	var out: Array = ["# The loot read (%s)" % Time.get_date_string_from_system(), "",
		"%d rolls a source. Rarity: C/U/R/E/L share of the gear. Wear: the level to wear's median, and the share a runner of that point's level can't wear yet. Gear only for wear (rounds, meds, parts and papers carry no level)." % N, ""]
	for p in POINTS:
		var sim = Sim.new()
		sim.start()
		sim.mythics_on = false            # the tables' read, not a mythic's (16 Oct)
		sim.set_class("Doorman")
		for i in range(Data.TIERS.size()):
			sim.best_depth[i] = 1 if i <= int(p[1]) else 0
		for z in range(Data.ZONES.size()):
			sim.bosses_beaten[z] = int(Data.ZONES[z]["tiers"].back()) <= int(p[1])
		sim.xp = Data.xp_for_level(int(p[2]))
		sim.unlocked = Data.ROOMS_SHUT.duplicate()
		out.append("## %s (runner level %d%s)" % [p[0], int(p[2]), (", depth %d" % int(p[3])) if int(p[3]) > 1 else ""])
		out.append("")
		out.append("| Source | Rarity C/U/R/E/L | Gear % | Wear median | Can't wear | Uniques | Sets |")
		out.append("|---|---|---|---|---|---|---|")
		var sites: Array = [int(p[1])] if int(p[3]) > 1 else range(maxi(0, int(p[1]) - 2), int(p[1]) + 1)
		for i in sites:
			sim.depth[i] = int(p[3])
			sim.hp = sim.max_hp()
			sim.deploy(i)
			var m: Dictionary = sim.mission
			var t: Dictionary = m["t"]
			for from_kill in [true, false]:
				var items: Array = []
				for k in range(N):
					var r: Dictionary = sim._find(m, t, from_kill, {}, true)
					if not r.is_empty():
						items.append(r["it"])
				out.append(_row("%s, %s" % [Data.TIERS[i]["name"], "a kill" if from_kill else "a search"], items, int(p[2])))
			sim.mission = null
			sim.depth[i] = 1
		# the gamble: every kind at this point
		var g: Array = []
		for k in Data.GAMBLE_KINDS:
			for n in range(int(float(N) / Data.GAMBLE_KINDS.size())):
				g.append(sim.roll_gamble(k))
		out.append(_row("The gamble (every kind)", g, int(p[2])))
		out.append("")
	var f := FileAccess.open("res://docs/balance/loot_read.md", FileAccess.WRITE)
	f.store_string("\n".join(out) + "\n")
	f.close()
	print("\n".join(out))
	quit()


func _row(name: String, items: Array, lv: int) -> String:
	var rar := [0, 0, 0, 0, 0]
	var wears: Array = []
	var locked := 0
	var uniques := 0
	var sets := 0
	for it in items:
		if str(it["slot"]) in Data.SLOTS:
			rar[mini(4, int(it.get("rarity", 0)))] += 1     # the gear's rarity (D6): rounds and meds have none worth reading
		if it.has("unique"):
			uniques += 1
		if it.has("set"):
			sets += 1
		if str(it["slot"]) in Data.SLOTS:
			var w: int = Items.wear_level(it)
			wears.append(w)
			if w > lv:
				locked += 1
	wears.sort()
	var n: float = maxf(1.0, items.size())
	var gear: int = wears.size()
	return "| %s | %s | %d%% | %s | %d%% | %d | %d |" % [name, "/".join(rar.map(func(x): return "%d" % roundi(100.0 * x / maxf(1.0, gear)))), roundi(100.0 * gear / n),
		str(wears[int(wears.size() / 2.0)]) if gear > 0 else "-", roundi(100.0 * locked / maxf(1.0, gear)), uniques, sets]
