extends SceneTree
## The balance summary: reads every docs/balance/*.txt that tools/balance.bat
## wrote, takes the GATES line from each (one JSON object a build; the probe's
## carries the loot figures), and writes docs/balance/summary.md: the gates
## table from docs/design/concept.md with each row read RED or GREEN, then a
## line a build with its firsts, odds and economy, so the pass can be read
## without opening the raw files.
##
##     godot --headless --path . -s tools/balance_summary.gd
##
## The gate figures are the concept's defaults; change them here when the pass
## settles them. Deaths (the player's own, from the playtest save) is not a bot
## figure and is left to Matt's count.

const FOLDER := "res://docs/balance"

const BANK_BAND := 1.5          # slowest to the bank within this many times the fastest
const KEYSTONE_BY := 2.0        # hour
const CAPSTONE_BY := 4.0        # hour
const ODDS_FLOOR := 0.6         # survival at every open tier in the kit as it stands
const TOP_SHARE := 0.02         # the top rarity (Legendary) at +35% quality (the weights give 2.5%; the probe's noise is ±0.1); the plain share is the weights' own
const TOP_SHARE_PLAIN := 0.008
const FINDS_RATIO := [1.20, 1.30]   # finds a search at +25% quantity, against plain
const CASH_SINK := 3.0          # cash in hand at the end, times the top bench level
const DEPTH_FROM := 4.0         # depths an hour from this hour to the end: at least one
const WOUNDS := [0.10, 0.25]    # share of runs ending wounded
const SCRAP := [1.0, 3.0]       # scrap earned an hour, in the dearest craft's worth (in hand is the bot's reserve, not the economy)


func _init() -> void:
	var builds: Array = []
	var probe: Dictionary = {}
	var dir := DirAccess.open(FOLDER)
	if dir == null:
		printerr("no docs/balance folder; run tools\\balance.bat first")
		quit(1)
		return
	var names: Array = []
	for f in dir.get_files():
		if f.ends_with(".txt") and f != "smoke.txt":
			names.append(f)
	names.sort()
	for f in names:
		var g: Dictionary = {}
		var found := false
		for line in FileAccess.get_file_as_string(FOLDER + "/" + f).split("\n"):
			if line.begins_with("GATES "):
				var parsed = JSON.parse_string(line.substr(6).strip_edges())
				if parsed is Dictionary:
					g = parsed
					found = true
		if not found:
			builds.append({"build": f.substr(0, f.length() - 4), "missing": true})
		elif str(g.get("build", "")) == "probe":
			probe = g
		else:
			builds.append(g)
	var reads: Array = builds.filter(func(b): return not b.get("missing", false))
	# the same build read more than once (the bat runs each twice): one line a build for the gates -
	# the firsts and the odds by their median, the money by the mean, the counts summed - and every
	# read on its own in the builds table
	var by_build: Dictionary = {}
	for g in reads:
		if not by_build.has(g["build"]):
			by_build[g["build"]] = []
		by_build[g["build"]].append(g)
	var full: Array = []
	for name in by_build:
		full.append(_merged(by_build[name]))
	if full.is_empty() and probe.is_empty():
		printerr("no GATES lines under docs/balance; run tools\\balance.bat first")
		quit(1)
		return
	var rows: Array = []    # [name, green when, read, ok (true/false/null)]

	# the bank's band
	if not full.is_empty():
		var banks: Array = []
		var never: Array = []
		for b in full:
			if float(b["bank_at"]) >= 0.0:
				banks.append(float(b["bank_at"]))
			else:
				never.append(b["build"])
		var ok: bool = never.is_empty() and not banks.is_empty() and banks.max() <= BANK_BAND * banks.min()
		var text: String = ("fastest %s, slowest %s" % [_hours(banks.min()), _hours(banks.max())]) if not banks.is_empty() else "no build reached the bank"
		if not never.is_empty():
			text += "; never: " + ", ".join(never)
		rows.append(["The bank's band", "slowest within %.1fx the fastest" % BANK_BAND, text, ok])

	# the keystone, the capstone
	for pair in [["keystone_at", "The keystone", KEYSTONE_BY], ["capstone_at", "The capstone", CAPSTONE_BY]]:
		if full.is_empty():
			continue
		var key: String = pair[0]
		var by: float = pair[2]
		var late: Array = []
		var latest := 0.0
		for b in full:
			var h := float(b[key])
			if h < 0.0 or h > by:
				late.append("%s %s" % [b["build"], _hours(h)])
			latest = maxf(latest, h)
		var text: String = ("every build by %s (latest %s)" % [_hours(by), _hours(latest)]) if late.is_empty() else "late: " + ", ".join(late)
		rows.append([pair[1], "by hour %.0f, every build" % by, text, late.is_empty()])

	# no reds: the odds reader at every open tier
	if not full.is_empty():
		var reds: Array = []
		for b in full:
			for o in b.get("odds", []):
				if float(o[1]) < ODDS_FLOOR:
					reds.append("%s T%d %.0f%%" % [b["build"], int(o[0]), float(o[1]) * 100.0])
		rows.append(["No reds", "no open tier under %.0f%%" % (ODDS_FLOOR * 100.0), "; ".join(reds) if not reds.is_empty() else "every open tier at or over the floor", reds.is_empty()])

	# the probe's two
	if not probe.is_empty():
		var es := float(probe.get("top_share", probe.get("elite_share", 0.0)))
		var esp := float(probe.get("top_share_plain", probe.get("elite_share_plain", 0.0)))
		rows.append(["Loot quality visible", "Legendary share %.1f%% at +35%% quality (%.1f%% plain)" % [TOP_SHARE * 100.0, TOP_SHARE_PLAIN * 100.0],
			"%.2f%% boosted, %.2f%% plain" % [es * 100.0, esp * 100.0], es >= TOP_SHARE and esp >= TOP_SHARE_PLAIN])
		var fr := float(probe["finds_ratio"])
		rows.append(["Quantity honest", "finds at +25%% quantity %.2f to %.2f times plain" % [FINDS_RATIO[0], FINDS_RATIO[1]],
			"%.2f (%.2f against %.2f a search)" % [fr, float(probe["finds_boosted"]), float(probe["finds_plain"])], FINDS_RATIO[0] <= fr and fr <= FINDS_RATIO[1]])
	else:
		rows.append(["Loot quality visible", "", "no probe read", false])
		rows.append(["Quantity honest", "", "no probe read", false])

	# cash sink
	if not full.is_empty():
		var over: Array = []
		var most := 0
		for b in full:
			most = maxi(most, int(b["cash_end"]))
			if float(b["cash_end"]) > CASH_SINK * float(b["top_bench"]):
				over.append("%s holds £%d against a £%d top bench" % [b["build"], int(b["cash_end"]), int(b["top_bench"])])
		var text: String = "; ".join(over) if not over.is_empty() else "every build under %.0fx the top bench (most £%d)" % [CASH_SINK, most]
		rows.append(["Cash sink", "cash in hand at the end no more than %.0fx the top bench level" % CASH_SINK, text, over.is_empty()])

	# depth pace, over the hours actually run
	if not full.is_empty():
		var slow: Array = []
		var any_long := false
		for b in full:
			var ran := float(b.get("elapsed_h", b["hours"]))
			var span := maxf(0.0, ran - DEPTH_FROM)
			var late := 0
			for c in b.get("depth_clears", []):
				if float(c[0]) >= DEPTH_FROM:
					late += 1
			var pace: float = (late / span) if span > 0.0 else 0.0
			b["_pace"] = pace
			if span > 0.0:
				any_long = true
				if pace < 1.0:
					slow.append("%s %.1f/h" % [b["build"], pace])
		if not any_long:
			rows.append(["Depth pace", "at least one depth an hour from hour %.0f" % DEPTH_FROM, "read shorter than %.0f h; not measured" % DEPTH_FROM, null])
		else:
			rows.append(["Depth pace", "at least one depth an hour from hour %.0f" % DEPTH_FROM, "; ".join(slow) if not slow.is_empty() else "every build at a depth an hour or better", slow.is_empty()])

	rows.append(["Deaths", "one every N hours at Matt's risk", "from the playtest save, not the bot; Matt's count", null])

	# wounds
	if not full.is_empty():
		var off: Array = []
		for b in full:
			var share: float = (float(b["wounded_runs"]) / float(b["runs"])) if int(b["runs"]) > 0 else 0.0
			b["_wounds"] = share
			if share < WOUNDS[0] or share > WOUNDS[1]:
				off.append("%s %.0f%%" % [b["build"], share * 100.0])
		rows.append(["Wounds", "%.0f to %.0f%% of runs end wounded" % [WOUNDS[0] * 100.0, WOUNDS[1] * 100.0], "; ".join(off) if not off.is_empty() else "every build in the band", off.is_empty()])

	# scrap economy: earned an hour against the dearest craft (older reads carry no scrap_per_h: in hand over the hours)
	if not full.is_empty():
		var off: Array = []
		for b in full:
			var dearest := float(b.get("dearest_build", 0))
			var per_h: float = float(b.get("scrap_per_h", float(b["scrap_end"]) / maxf(0.01, float(b.get("elapsed_h", b["hours"])))))
			var crafts: float = (per_h / dearest) if dearest > 0.0 else 0.0
			b["_crafts"] = crafts
			if crafts < SCRAP[0] or crafts > SCRAP[1]:
				off.append("%s %.1f crafts/h" % [b["build"], crafts])
		rows.append(["Scrap economy", "scrap earned an hour worth %.0f to %.0f of the dearest craft" % [SCRAP[0], SCRAP[1]], "; ".join(off) if not off.is_empty() else "every build in the band", off.is_empty()])

	var reds := 0
	for r in rows:
		if r[3] is bool and not r[3]:
			reds += 1
	var out: Array = []
	out.append("# Balance summary")
	out.append("")
	out.append("Written %s by tools/balance_summary.gd from %d reads of %d builds%s. %s" % [
		Time.get_datetime_string_from_system(false, true), reads.size(), full.size(), " and the probe" if not probe.is_empty() else " (no probe)",
		("%d RED." % reds) if reds > 0 else "No reds."])
	var missing: Array = []
	for b in builds:
		if b.get("missing", false):
			missing.append(b["build"])
	if not missing.is_empty():
		out.append("")
		out.append("No GATES line in: " + ", ".join(missing) + " (the read crashed or was cut short; see its .txt).")
	out.append("")
	out.append("| Gate | Green when | Read | |")
	out.append("| --- | --- | --- | --- |")
	for r in rows:
		out.append("| %s | %s | %s | %s |" % [r[0], r[1], r[2], "—" if r[3] == null else ("GREEN" if r[3] else "RED")])
	var head := out.size()
	out.append("")
	out.append("## The builds")
	out.append("")
	out.append("| Build | Hours | Bank | Keystone | Capstone | Level | Best tier (depth) | Runs | Deaths | Wounded | Cash | Top bench | Scrap in hand (crafts earned/h) | Depths/h after %.0f | Odds by tier | Kit |" % DEPTH_FROM)
	out.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
	for b in reads:
		var bt: int = int(b.get("best_tier", 0))
		var bd: Array = b.get("best_depth", [])
		var depth: int = int(bd[bt]) if bt >= 0 and bt < bd.size() else 0
		var odds: Array = []
		for o in b.get("odds", []):
			odds.append("T%d %.0f%%" % [int(o[0]), float(o[1]) * 100.0])
		out.append("| %s | %.1f (%.0f s wall) | %s | %s | %s | %d | %d (%d) | %d | %d | %.0f%% | £%d | £%d | %d (%.1f) | %.1f | %s | %s |" % [
			b["build"], float(b.get("elapsed_h", b["hours"])), float(b.get("wall_s", 0)), _hours(float(b["bank_at"])), _hours(float(b["keystone_at"])), _hours(float(b["capstone_at"])),
			int(b.get("level", 0)), bt, depth, int(b["runs"]), int(b["deaths"]), float(b.get("_wounds", 0.0)) * 100.0,
			int(b["cash_end"]), int(b["top_bench"]), int(b["scrap_end"]), float(b.get("_crafts", 0.0)), float(b.get("_pace", 0.0)), " ".join(odds), str(b.get("kit", ""))])
	out.append("")
	out.append("Depth clears as [hour, tier, depth]:")
	out.append("")
	for b in reads:
		var clears: Array = []
		for c in b.get("depth_clears", []):
			clears.append("%.1f T%d d%d" % [float(c[0]), int(c[1]), int(c[2])])
		out.append("- %s: %s" % [b["build"], ", ".join(clears) if not clears.is_empty() else "none"])
	out.append("")
	var f := FileAccess.open(FOLDER + "/summary.md", FileAccess.WRITE)
	f.store_string("\n".join(out))
	f.close()
	for k in range(head):
		print(out[k])
	print("-> docs/balance/summary.md")
	quit(0)


## One build's reads as one: the firsts by their median (never counts as late), the odds by the median a
## tier, cash, scrap and level by the mean, runs, deaths and wounded runs summed, the clears joined.
func _merged(gs: Array) -> Dictionary:
	if gs.size() == 1:
		return gs[0]
	var m: Dictionary = gs[0].duplicate(true)
	for key in ["bank_at", "keystone_at", "capstone_at"]:
		var vals: Array = gs.map(func(g): return (float(g[key]) if float(g[key]) >= 0.0 else 999.0))
		var med := _median(vals)
		m[key] = -1.0 if med >= 999.0 else snappedf(med, 0.01)
	for key in ["cash_end", "scrap_end", "scrap_spent", "notes_end", "level", "scrap_per_h", "elapsed_h", "wall_s"]:
		var total := 0.0
		for g in gs:
			total += float(g.get(key, 0))
		m[key] = snappedf(total / gs.size(), 0.01)
	for key in ["runs", "deaths", "wounded_runs"]:
		var n := 0
		for g in gs:
			n += int(g.get(key, 0))
		m[key] = n
	var per_tier: Dictionary = {}
	for g in gs:
		for o in g.get("odds", []):
			if not per_tier.has(int(o[0])):
				per_tier[int(o[0])] = []
			per_tier[int(o[0])].append(float(o[1]))
	var odds: Array = []
	var tiers: Array = per_tier.keys()
	tiers.sort()
	for t in tiers:
		odds.append([t, snappedf(_median(per_tier[t]), 0.001)])
	m["odds"] = odds
	var clears: Array = []
	for g in gs:
		clears.append_array(g.get("depth_clears", []))
	m["depth_clears"] = clears
	m["hours"] = float(gs[0]["hours"])
	m["reads"] = gs.size()
	return m


func _median(vals: Array) -> float:
	var v := vals.duplicate()
	v.sort()
	var n := v.size()
	if n == 0:
		return 0.0
	return float(v[n / 2]) if n % 2 == 1 else (float(v[n / 2 - 1]) + float(v[n / 2])) / 2.0


func _hours(v: float) -> String:
	return "never" if v < 0.0 else "%.1f h" % v
