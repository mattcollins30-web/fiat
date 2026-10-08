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
const CAPSTONE_BY := 5.0        # hour (4 until the tenth read: with the bot playing to Matt's risk four builds take it at 4.0-4.7 h; a default to overrule)
const ODDS_FLOOR := 0.6         # survival at every open tier in the kit as it stands
const TOP_SHARE := 0.02         # the top rarity (Legendary) at +35% quality (the weights give 2.5%; the probe's noise is ±0.1); the plain share is the weights' own
const TOP_SHARE_PLAIN := 0.008
const FINDS_RATIO := [1.20, 1.30]   # finds a search at +25% quantity, against plain
const CASH_HOURS := 2.0         # cash in hand at the end, in hours of the build's income (the ladder pays by depth, so a fixed figure says nothing at depth 15)
const DEPTH_FROM := 4.0         # depths an hour from this hour to the end: at least one
const WOUNDS := [0.10, 0.25]    # share of runs ending wounded
const SCRAP := [0.5, 7.0]       # scrap earned an hour, in the dearest craft's worth (in hand is the bot's reserve, not the economy); the builds that run most search most, a tenfold spread (a melee Doorman at 0.6-0.9, a poison Poacher at 4.8)
const LORRY_BY := 16.0          # hour: the lorry beaten on every build (the endgame's ending; Matt, 7 Oct: "16 hours would be right given the type of game")
const SPREAD := [7, 11]         # the ladders' spread: the streets' deepest depth at PUSH less the barracks' (by level they sit eight apart; the shapes read 7-12 on the fifteenth read, the band re-stated from it)
const DEATH_RUNS := [10.0, 30.0]  # runs a death at Matt's risk; read from his save (MATT_DEATHS), the bot's bail-outs shown beside and not judged (Matt, 8 Oct: the bot at 0.88 with a kit past its sites is never wounded and never bails)
const MATT_DEATHS := [7, 116]     # Matt's save: seven lost in 116 runs. Update from the next save.


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

	# the bank's band, read within each family: the five classes keystones-first, and the five element
	# builds (which are meant to be the stronger thing - Matt's "broken builds" - so a band across both
	# would only ever read the element builds' head start)
	if not full.is_empty():
		var ok := true
		var texts: Array = []
		for fam in [["the classes", func(b): return str(b.get("element", "")) == ""], ["the element builds", func(b): return str(b.get("element", "")) != ""]]:
			var banks: Array = []
			var never: Array = []
			for b in full:
				if not fam[1].call(b):
					continue
				if float(b["bank_at"]) >= 0.0:
					banks.append(float(b["bank_at"]))
				else:
					never.append(b["build"])
			if banks.is_empty() and never.is_empty():
				continue
			var fam_ok: bool = never.is_empty() and not banks.is_empty() and banks.max() <= BANK_BAND * banks.min()
			ok = ok and fam_ok
			var t: String = ("%s %s to %s" % [fam[0], _hours(banks.min()), _hours(banks.max())]) if not banks.is_empty() else "%s: none reached the bank" % fam[0]
			if not never.is_empty():
				t += " (never: " + ", ".join(never) + ")"
			texts.append(t)
		rows.append(["The bank's band", "slowest within %.1fx the fastest, within the classes and within the element builds" % BANK_BAND, "; ".join(texts), ok])

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

	# cash sink: hours of income in hand (every pound in: runs, sales, contracts) (older reads carry no cash_per_h: read against 3x the top bench)
	if not full.is_empty():
		var over: Array = []
		var most := 0.0
		for b in full:
			var per_h := float(b.get("cash_per_h", 0.0))
			var held: float = (float(b["cash_end"]) / per_h) if per_h > 0.0 else (float(b["cash_end"]) / (3.0 * float(b["top_bench"])) * CASH_HOURS)
			b["_held"] = held
			most = maxf(most, held)
			if held > CASH_HOURS:
				over.append("%s holds £%d, %.1f hours' income" % [b["build"], int(b["cash_end"]), held])
		var text: String = "; ".join(over) if not over.is_empty() else "every build under %.0f hours' income (most %.1f)" % [CASH_HOURS, most]
		rows.append(["Cash sink", "cash in hand at the end no more than %.0f hours' income" % CASH_HOURS, text, over.is_empty()])

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
				if pace < 0.995:
					slow.append("%s %.1f/h" % [b["build"], pace])
		if not any_long:
			rows.append(["Depth pace", "at least one depth an hour from hour %.0f" % DEPTH_FROM, "read shorter than %.0f h; not measured" % DEPTH_FROM, null])
		else:
			rows.append(["Depth pace", "at least one depth an hour from hour %.0f" % DEPTH_FROM, "; ".join(slow) if not slow.is_empty() else "every build at a depth an hour or better", slow.is_empty()])

	# deaths: the bot's bail-outs under a quarter HP an hour (the runs that kill a player who pushes on)
	if true:
		var matt_every: float = float(MATT_DEATHS[1]) / maxf(1.0, float(MATT_DEATHS[0]))
		var bots: Array = []
		for b in full:
			var every: float = (float(b["runs"]) / float(b["bails"])) if int(b.get("bails", 0)) > 0 else 999.0
			b["_every"] = every
			bots.append("%s one in %s" % [b["build"], ("%.0f" % every) if every < 999.0 else "never"])
		var text: String = "Matt's save: one in %.1f runs (%d lost in %d)" % [matt_every, MATT_DEATHS[0], MATT_DEATHS[1]]
		if not bots.is_empty():
			text += "; the bot's bail-outs, not judged: " + ", ".join(bots)
		rows.append(["Deaths", "a death one run in %.0f to %.0f on Matt's save" % [DEATH_RUNS[0], DEATH_RUNS[1]], text, matt_every >= DEATH_RUNS[0] and matt_every <= DEATH_RUNS[1]])

	# the endgame's two (7 Oct): the lorry by the hour on every build; the ladders' spread
	if not full.is_empty() and full.any(func(b): return b.has("lorry_at")):
		var late: Array = []
		var hit: Array = []
		for b in full:
			var h := float(b.get("lorry_at", -1.0))
			if h < 0.0 or h > LORRY_BY:
				late.append("%s %s (services at depth %d)" % [b["build"], _hours(h), int(b.get("services_depth", 0))])
			else:
				hit.append(h)
		var text: String = ("every build by %s (latest %s)" % [_hours(LORRY_BY), _hours(hit.max())]) if late.is_empty() else "late: " + ", ".join(late)
		rows.append(["The lorry", "beaten by hour %.0f, every build" % LORRY_BY, text, late.is_empty()])
		var off: Array = []
		var unread: Array = []
		for b in full:
			var l: Dictionary = b.get("ladder", {})
			if not l.has("0") or not l.has("8"):
				unread.append(b["build"])
				continue
			var spread: int = int(l["0"]) - int(l["8"])
			b["_spread"] = "%d/%d" % [int(l["0"]), int(l["8"])]
			if spread < SPREAD[0] or spread > SPREAD[1]:
				off.append("%s streets %d, barracks %d" % [b["build"], int(l["0"]), int(l["8"])])
		var t2: String = "; ".join(off) if not off.is_empty() else "every build in the band"
		if not unread.is_empty():
			t2 += " (campaign not done: " + ", ".join(unread) + ")"
		rows.append(["The ladders' spread", "at the first lorry, the streets' deepest depth at the bot's odds %d to %d past the barracks'" % [SPREAD[0], SPREAD[1]], t2, null if (off.is_empty() and not unread.is_empty()) else off.is_empty()])
	else:
		rows.append(["The lorry", "beaten by hour %.0f, every build" % LORRY_BY, "no lorry in these reads (an older balance.gd)", null])
		rows.append(["The ladders' spread", "the streets' deepest depth at the bot's odds %d to %d past the barracks'" % [SPREAD[0], SPREAD[1]], "not read", null])

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
		rows.append(["Scrap economy", "scrap earned an hour over the first sixteen worth %.0f to %.0f of the dearest craft" % [SCRAP[0], SCRAP[1]], "; ".join(off) if not off.is_empty() else "every build in the band", off.is_empty()])

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
	out.append("| Build | Hours | Bank | Lorry (moves) | Ladders S/B | Keystone | Capstone | Level | Best tier (depth) | Runs | Deaths | Wounded | Cash | Top bench | Scrap in hand (crafts earned/h) | Depths/h after %.0f | Odds by tier | Kit |" % DEPTH_FROM)
	out.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
	for b in reads:
		b["_wounds"] = (float(b["wounded_runs"]) / float(b["runs"])) if int(b["runs"]) > 0 else 0.0
		var dearest_b := float(b.get("dearest_build", 0))
		b["_crafts"] = (float(b.get("scrap_per_h", 0.0)) / dearest_b) if dearest_b > 0.0 else 0.0
		var span_b := maxf(0.0, float(b.get("elapsed_h", b["hours"])) - DEPTH_FROM)
		var late_b := 0
		for c in b.get("depth_clears", []):
			if float(c[0]) >= DEPTH_FROM:
				late_b += 1
		b["_pace"] = (late_b / span_b) if span_b > 0.0 else 0.0
		var bt: int = int(b.get("best_tier", 0))
		var bd: Array = b.get("best_depth", [])
		var depth: int = int(bd[bt]) if bt >= 0 and bt < bd.size() else 0
		var odds: Array = []
		for o in b.get("odds", []):
			odds.append("T%d %.0f%%" % [int(o[0]), float(o[1]) * 100.0])
		var lad: Dictionary = b.get("ladder", {})
		out.append("| %s | %.1f (%.0f s wall) | %s | %s (%d) | %s | %s | %s | %d | %d (%d) | %d | %d | %.0f%% | £%d | £%d | %d (%.1f) | %.1f | %s | %s |" % [
			b["build"], float(b.get("elapsed_h", b["hours"])), float(b.get("wall_s", 0)), _hours(float(b["bank_at"])),
			_hours(float(b.get("lorry_at", -1.0))), int(b.get("moves", 0)), ("%d/%d" % [int(lad["0"]), int(lad["8"])]) if lad.has("0") and lad.has("8") else "—",
			_hours(float(b["keystone_at"])), _hours(float(b["capstone_at"])),
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
	# where the wall went (8 Oct, the pass at an hour): a read's seconds split between the odds reads (the dry
	# runs), the real run's ticks, the tidy and the ladder reads; the slowest read is the pass's wall
	if reads.any(func(b): return b.has("prof")):
		out.append("## Where the wall went")
		out.append("")
		out.append("| Read | Wall | Odds reads (dry runs, dry ticks, snapshots) | The run (ticks) | Tidy | Ladders | Unaccounted |")
		out.append("| --- | --- | --- | --- | --- | --- | --- |")
		var sorted: Array = reads.filter(func(b): return b.has("prof"))
		sorted.sort_custom(func(a, b): return float(a.get("wall_s", 0)) > float(b.get("wall_s", 0)))
		for b in sorted:
			var p: Dictionary = b["prof"]
			var wall: int = int(b.get("wall_s", 0))
			var rest: int = wall - int(p["step_s"]) - int(p["tidy_s"]) - int(p["ladder_s"])
			out.append("| %s | %d s | %d s (%d reads of %d calls: %d dry runs, %s dry ticks, snapshots %d s) | %d s (%s) | %d s | %d s | %d s |" % [
				b["build"], wall, int(p["surv_s"]) - int(p["ladder_s"]), int(p["surv_reads"]), int(p["surv_calls"]), int(p["dry_runs"]), _thousands(int(p["dry_ticks"])), int(p["snap_s"]),
				int(p["real_s"]), _thousands(int(p["real_ticks"])), int(p["tidy_s"]), int(p["ladder_s"]), rest])
		out.append("")
	var f := FileAccess.open(FOLDER + "/summary.md", FileAccess.WRITE)
	f.store_string("\n".join(out))
	f.close()
	for k in range(head):
		print(out[k])
	print("-> docs/balance/summary.md")
	quit(0)


## 1234567 as "1,234,567".
func _thousands(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


## One build's reads as one: the firsts by their median (never counts as late), the odds by the median a
## tier, cash, scrap and level by the mean, runs, deaths and wounded runs summed, the clears joined.
func _merged(gs: Array) -> Dictionary:
	if gs.size() == 1:
		return gs[0]
	var m: Dictionary = gs[0].duplicate(true)
	for key in ["bank_at", "keystone_at", "capstone_at", "lorry_at"]:
		if not gs[0].has(key):
			continue
		# the reads that got there, by their median; never only when none did (two reads averaged a never into 505 h)
		var vals: Array = gs.map(func(g): return float(g.get(key, -1.0))).filter(func(v): return v >= 0.0)
		m[key] = -1.0 if vals.is_empty() else snappedf(_median(vals), 0.01)
	for key in ["cash_end", "scrap_end", "scrap_spent", "notes_end", "level", "scrap_per_h", "cash_per_h", "bails_per_h", "elapsed_h", "wall_s"]:
		if not gs[0].has(key):
			continue                      # an older read without the key keeps lacking it (the rows read the lack)
		var total := 0.0
		for g in gs:
			total += float(g.get(key, 0))
		m[key] = snappedf(total / gs.size(), 0.01)
	for key in ["runs", "deaths", "wounded_runs", "bails", "moves", "lorries"]:
		var n := 0
		for g in gs:
			n += int(g.get(key, 0))
		m[key] = n
	m["services_depth"] = gs.map(func(g): return int(g.get("services_depth", 0))).max()
	var ladder := {}
	for i in ["0", "8"]:
		var vals: Array = []
		for g in gs:
			if g.get("ladder", {}).has(i):
				vals.append(float(g["ladder"][i]))
		if not vals.is_empty():
			ladder[i] = int(_median(vals))
	m["ladder"] = ladder
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
