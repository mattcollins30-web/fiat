extends SceneTree
## The playtest read (11 Oct): takes a save and its playtest record (the .record.jsonl beside it, a line a JSON
## object, see sim.gd's chron and main.gd's _flush_record) and writes
## docs/balance/playtest.md - the time at the game, the milestones by the player's own hours, the balance gates
## read from play (the same figures as summary.md's, so the bot's targets can be set from a person's), the runs
## site by site, the hour-by-hour curve and where the money and the points went.
##
##     godot --headless --path . -s tools/playtest_summary.gd -- [save]
##
## The save defaults to the autosave (user://fiat.save, the game's own, its record user://fiat.record.jsonl); a slot
## or a copied file works too, its record beside it. A record's earlier games are kept as fiat.record.<time>.jsonl.
## tools\playtest.bat runs it, and the watcher does on docs\balance\playtest.flag.

const OUT := "res://docs/balance/playtest.md"
const GATES := preload("res://tools/balance_summary.gd")
const Data := preload("res://scripts/sim/data.gd")
const Sim := preload("res://scripts/sim/sim.gd")
const LEVELS := [5, 10, 15, 20, 25, 30, 40, 50]
const DEPTHS := [2, 4, 6, 8, 10, 12, 16, 20]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() and str(args[0]) != "" else "user://fiat.save"
	var f := FileAccess.open(path, FileAccess.READ)
	var out := ""
	if f == null:
		out = "# Playtest record\n\nNo save at %s.\n" % path
	else:
		var d = JSON.parse_string(f.get_as_text())
		if not (d is Dictionary) or not d.has("sim"):
			out = "# Playtest record\n\n%s isn't a Fiat save.\n" % path
		else:
			var ch: Array = read_record(record_path(path))
			ch.append_array(d["sim"].get("chronicle", []))     # a save written by a script (the bot's), lines and all
			Sim._shift_sites(d["sim"])                          # a save from before the Outskirts (12 Oct): its sites up three
			for e in ch:
				if not e.has("sv") and e.has("tier") and str(e.get("k", "")) in ["clear", "run", "boss", "word"]:     # a site's index, never an item's tier
					e["tier"] = int(e["tier"]) + Data.OUTSKIRTS_SITES     # a line from before the Outskirts: the site's index then
				if not e.has("sv") and e.has("zone"):
					e["zone"] = int(e["zone"]) + 1
			out = summarize(d["sim"], ch, path)
	var w := FileAccess.open(OUT, FileAccess.WRITE)
	if w != null:
		w.store_string(out)
		w.close()
	print(out)
	quit()


## The record file beside a save: user://fiat.save -> user://fiat.record.jsonl (main.gd's record_file).
static func record_path(save: String) -> String:
	return save.get_basename() + ".record.jsonl"


## A record file's lines, oldest first; a line that doesn't parse (a write cut off by a crash) is skipped.
static func read_record(path: String) -> Array:
	var out: Array = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line == "":
			continue
		var e = JSON.parse_string(line)
		if e is Dictionary and e.has("k"):
			out.append(e)
	f.close()
	return out


## The whole read, as markdown: the save's sim dict and the record's lines.
## The Runs card's words by its odds (Words.ODDS), high to low: [from, to, words].
const ODDS_BANDS := [[0.9, 1.01, "Safe"], [0.75, 0.9, "Likely"], [0.6, 0.75, "Risky"], [0.4, 0.6, "A coin toss"], [0.2, 0.4, "Long odds"], [0.0, 0.2, "A bad idea"]]


static func summarize(s: Dictionary, ch: Array, path := "") -> String:
	var played: float = float(s.get("played_s", 0.0))
	var by_play: bool = played > 0.0
	var L: Array = []
	L.append("# Playtest record")
	L.append("")
	L.append("Read %s from %s. Record v%d, %d lines. Hours are the player's own at the game%s." % [Time.get_datetime_string_from_system(), path,
		int(s.get("chronicle_v", 0)), ch.size(), "" if by_play else " (none recorded: the sim's clock instead)"])
	if int(s.get("chron_count", ch.size())) > ch.size():
		L.append("")
		L.append("The save counts %d lines and the record holds %d: the rest were lost (a record file deleted or a slot's not copied)." % [int(s["chron_count"]), ch.size()])
	elif s.has("chron_count") and ch.size() > int(s["chron_count"]):
		L.append("")
		L.append("The record holds %d lines past the save's %d: a slot saved since the autosave, a crash between the two (those lines may repeat), or an older game's record that couldn't be moved aside." % [ch.size() - int(s["chron_count"]), int(s["chron_count"])])
	if ch.is_empty():
		L.append("")
		L.append("No playtest record beside the save: it's from before 11 Oct, or the game hasn't saved yet.")
		return "\n".join(L) + "\n"
	var runs: Array = ch.filter(func(e): return e["k"] == "run")
	var live: Array = runs.filter(func(e): return not e.get("away", false))
	var away_s := 0.0
	var sessions := 0
	for e in ch:
		if e["k"] == "session":
			sessions += 1
			away_s += float(e.get("settled_s", 0))
	# ---- the time
	L.append("")
	L.append("## The time")
	L.append("")
	L.append("| Played | The sim's clock | Away, settled | Sessions | Runs (live / away) | Runners lost |")
	L.append("| --- | --- | --- | --- | --- | --- |")
	L.append("| %s | %s | %s | %d | %d (%d / %d) | %d |" % [_h(played), _h(float(s.get("elapsed", 0.0))), _h(away_s), sessions,
		runs.size(), live.size(), runs.size() - live.size(), int(s.get("operators_lost", 0))])
	# ---- milestones
	L.append("")
	L.append("## Milestones")
	L.append("")
	L.append("| When (played) | Sim | Level | What |")
	L.append("| --- | --- | --- | --- |")
	var ms: Array = []
	var lv_seen := {}
	var dp_seen := {}
	var first_key := ""
	var first_cap := ""
	var first_death := false
	for e in ch:
		var k: String = e["k"]
		match k:
			"start":
				ms.append([e, "New game%s" % (" (hardcore)" if e.get("hardcore", false) else "")])
			"clear":
				if e.get("first", false):
					ms.append([e, "First clear: %s (site level %d, %s dmg/s, kit %s)" % [e["site"], int(e.get("site_level", 0)), str(e.get("dps", "?")), _money(e.get("kit", 0))]])
				var dep: int = int(e.get("depth", 1))
				for target in DEPTHS:
					if dep >= target and not dp_seen.has(target):
						dp_seen[target] = true
						ms.append([e, "Depth %d cleared (%s)" % [target, e["site"]]])
			"boss":
				if e.get("first", false) or e.get("pinnacle", false):
					ms.append([e, "%s down%s" % [e["name"], " at full strength" if e.get("pinnacle", false) else ""]])
			"deeds":
				ms.append([e, "The deeds found (the Bank's vault)"])
			"lorry":
				ms.append([e, "The lorry beaten (%d)" % int(e.get("lorries", 1))])
			"move":
				ms.append([e, "The Pitch moved%s" % ((" - trade: %s" % e["trade"]) if str(e.get("trade", "")) != "" else "")])
			"level":
				var to: int = int(e.get("to", 0))
				for target in LEVELS:
					if to >= target and not lv_seen.has(target):
						lv_seen[target] = true
						ms.append([e, "Level %d" % target])
			"train":
				if e.get("keystone", false) and first_key == "":
					first_key = str(e["name"])
					ms.append([e, "First keystone: %s (%s)" % [e["name"], e["tree"]]])
				if e.get("capstone", false) and first_cap == "":
					first_cap = str(e["name"])
					ms.append([e, "First capstone: %s (%s)" % [e["name"], e["tree"]]])
			"class":
				ms.append([e, "Class: %s to %s (%s)" % [e.get("from", "") if str(e.get("from", "")) != "" else "none", e["to"], _money(e.get("cost", 0))]])
			"ascend":
				ms.append([e, "Second past: %s" % e["second"]])
			"retire":
				ms.append([e, "Retired"])
			"run":
				if e.get("outcome", "") == "Dead" and not first_death:
					first_death = true
					ms.append([e, "First death: %s, depth %d" % [e["site"], int(e.get("depth", 1))]])
	for m in ms:
		var e: Dictionary = m[0]
		L.append("| %s | %s | %d | %s |" % [_when(e, by_play), _h(float(e.get("t", 0.0))), int(e.get("lv", 0)), m[1]])
	# ---- the gates, from play
	L.append("")
	L.append("## The gates, read from play")
	L.append("")
	L.append("The same figures summary.md reads off the bot, read off the player. The bot's targets can be set from these.")
	L.append("")
	L.append("| Gate | The bot's target | Play |")
	L.append("| --- | --- | --- |")
	var bank: Dictionary = _first(ch, func(e): return e["k"] == "clear" and e.get("first", false) and int(e.get("tier", -1)) == Data.BANK)
	L.append("| The bank | (the band: slowest within %.1fx the fastest) | %s |" % [GATES.BANK_BAND, _at(bank, by_play)])
	var key: Dictionary = _first(ch, func(e): return e["k"] == "train" and e.get("keystone", false))
	L.append("| The keystone | by hour %.0f | %s |" % [GATES.KEYSTONE_BY, _at(key, by_play)])
	var cap: Dictionary = _first(ch, func(e): return e["k"] == "train" and e.get("capstone", false))
	L.append("| The capstone | by hour %.0f | %s |" % [GATES.CAPSTONE_BY, _at(cap, by_play)])
	var lorry: Dictionary = _first(ch, func(e): return e["k"] == "lorry")
	L.append("| The lorry | by hour %.0f | %s |" % [GATES.LORRY_BY, _at(lorry, by_play)])
	var deaths := live.filter(func(e): return e.get("outcome", "") == "Dead").size()
	L.append("| Deaths | a death one run in %.0f to %.0f | %s |" % [GATES.DEATH_RUNS[0], GATES.DEATH_RUNS[1],
		("%d in %d live runs: one in %.0f" % [deaths, live.size(), float(live.size()) / deaths]) if deaths > 0 else "none in %d live runs" % live.size()])
	var wounded := live.filter(func(e): return e.get("wounded", false)).size()
	L.append("| Wounds | %.0f-%.0f%% of runs | %s |" % [GATES.WOUNDS[0] * 100.0, GATES.WOUNDS[1] * 100.0, _pct(wounded, live.size())])
	var outs := live.filter(func(e): return e.get("timed_out", false)).size()
	L.append("| Clock | under %.0f%% out of time | %s |" % [GATES.TIMEOUTS * 100.0, _pct(outs, live.size())])
	var ways := live.filter(func(e): return e.get("way_out", false)).size()
	L.append("| The way out | (not a gate) | %s of runs left by the way out |" % _pct(ways, live.size()))
	var deeper := ch.filter(func(e): return e["k"] == "clear" and not e.get("first", false) and _hours(e, by_play) >= GATES.DEPTH_FROM)
	var span: float = (played if by_play else float(s.get("elapsed", 0.0))) / 3600.0 - GATES.DEPTH_FROM
	L.append("| Depth pace | a depth an hour from hour %.0f | %s |" % [GATES.DEPTH_FROM, ("%.2f an hour (%d new depths in %.1f h)" % [deeper.size() / span, deeper.size(), span]) if span > 0.5 else "not yet past hour %.0f" % GATES.DEPTH_FROM])
	# ---- runs by site
	L.append("")
	L.append("## Runs, site by site (away runs counted, and shown apart)")
	L.append("")
	L.append("| Site | Runs | Away | Deepest | Deaths | Wounded | Out of time | Way out | Cut and run | Time a run | Kills of the pool | Cash a run | XP a run |")
	L.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
	var sites := {}
	for e in runs:
		var nm: String = e["site"]
		if not sites.has(nm):
			sites[nm] = {"n": 0, "away": 0, "deep": 0, "dead": 0, "wound": 0, "out": 0, "way": 0, "cut": 0, "time": 0.0, "kills": 0, "of": 0, "cash": 0, "xp": 0, "tier": int(e["tier"])}
		var r: Dictionary = sites[nm]
		r["n"] += 1
		r["away"] += 1 if e.get("away", false) else 0
		r["deep"] = maxi(int(r["deep"]), int(e.get("depth", 1)))
		r["dead"] += 1 if e.get("outcome", "") == "Dead" else 0
		r["wound"] += 1 if e.get("wounded", false) else 0
		r["out"] += 1 if e.get("timed_out", false) else 0
		r["way"] += 1 if e.get("way_out", false) else 0
		r["cut"] += 1 if e.get("outcome", "") == "Cut and run" else 0
		r["time"] += float(e.get("time", 0.0))
		r["kills"] += int(e.get("kills", 0))
		r["of"] += int(e.get("of", 0))
		r["cash"] += int(e.get("cash", 0))
		r["xp"] += int(e.get("xp", 0))
	var names: Array = sites.keys()
	names.sort_custom(func(a, b): return int(sites[a]["tier"]) < int(sites[b]["tier"]))
	for nm in names:
		var r: Dictionary = sites[nm]
		var n: int = r["n"]
		L.append("| %s | %d | %d | %d | %d | %s | %s | %s | %s | %.0f s | %.0f%% | %s | %d |" % [nm, n, r["away"], r["deep"], r["dead"], _pct(r["wound"], n), _pct(r["out"], n), _pct(r["way"], n),
			_pct(r["cut"], n), r["time"] / n, 100.0 * r["kills"] / maxf(1.0, r["of"]), _money(r["cash"] / n), r["xp"] / n])
	# ---- the odds set off at (12 Oct, Matt: "how the bot plays isn't how a person plays"): the Runs card's reading at
	# the gate, by its words, and what came of it - the bot's PUSH is set from where people actually go
	var read_runs: Array = runs.filter(func(e): return float(e.get("odds", -1.0)) >= 0.0 and not e.get("away", false))
	L.append("")
	L.append("## The odds set off at (the Runs card's reading at the gate)")
	L.append("")
	if read_runs.is_empty():
		L.append("No run in this record carries its odds (a save from before 12 Oct, or none read).")
	else:
		L.append("| The card read | Runs | Deaths | Wounded | Cut and run | Regen worn (median, HP/s) |")
		L.append("| --- | --- | --- | --- | --- | --- |")
		for band in ODDS_BANDS:
			var these: Array = read_runs.filter(func(e): return float(e["odds"]) >= float(band[0]) and float(e["odds"]) < float(band[1]))
			if these.is_empty():
				continue
			var regens: Array = these.map(func(e): return float(e.get("regen", 0.0)))
			regens.sort()
			@warning_ignore("integer_division")
			L.append("| %s (%.0f-%.0f%%) | %d | %d | %s | %s | %.1f |" % [band[2], 100.0 * float(band[0]), minf(100.0, 100.0 * float(band[1])), these.size(),
				these.filter(func(e): return e.get("outcome", "") == "Dead").size(), _pct(these.filter(func(e): return e.get("wounded", false)).size(), these.size()),
				_pct(these.filter(func(e): return e.get("outcome", "") == "Cut and run").size(), these.size()), regens[regens.size() / 2]])
		var odds_all: Array = read_runs.map(func(e): return float(e["odds"]))
		odds_all.sort()
		L.append("")
		@warning_ignore("integer_division")
		L.append("Median odds at the gate: %.0f%%; the lowest taken: %.0f%%; %d of %d runs read." % [100.0 * odds_all[odds_all.size() / 2], 100.0 * odds_all[0], read_runs.size(), runs.size()])
	# ---- hour by hour
	var snaps: Array = ch.filter(func(e): return e["k"] == "snap")
	if not snaps.is_empty():
		L.append("")
		L.append("## Hour by hour (a snapshot every ten minutes played; the first of each half hour shown)")
		L.append("")
		L.append("| Played | Level | Cash | In since the start | Notes | Scrap | Deepest | dmg/s | Max HP | Armour | Kit | Pitch built | Map | Runs | Lost |")
		L.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
		var shown := {}
		for e in snaps:
			var hr: int = int(floor(float(e["p"]) / 1800.0 + 0.001))     # the first snapshot in each half hour
			if shown.has(hr):
				continue
			shown[hr] = true
			L.append("| %s | %d | %s | %s | %d | %d | %d | %s | %d | %.0f%% | %s | %d | %d | %d | %d |" % [_h(float(e["p"])), int(e["lv"]), _money(e.get("cash", 0)), _money(e.get("cash_in", 0)),
				int(e.get("notes", 0)), int(e.get("scrap", 0)), int(e.get("deepest", 0)), str(e.get("dps", "")), int(e.get("max_hp", 0)), 100.0 * float(e.get("mit", 0.0)),
				_money(e.get("kit", 0)), int(e.get("yard_built", 0)), int(e.get("atlas", 0)), int(e.get("runs", 0)), int(e.get("lost", 0))])
	# ---- where it went
	L.append("")
	L.append("## Where the money and the points went")
	L.append("")
	var spend := {"yard": 0, "yard_rank": 0, "craft": 0, "gamble": 0, "heal": 0, "treat": 0, "respec": 0, "class": 0, "word": 0}
	var count := {}
	for e in ch:
		var k: String = e["k"]
		count[k] = int(count.get(k, 0)) + 1
		match k:
			"yard", "yard_rank", "craft", "heal", "treat", "respec", "class", "word":
				spend[k] += int(e.get("cost", 0))
			"gamble":
				spend["gamble"] += int(e.get("price", 0))
	L.append("| The Pitch | Ranks | The Workshop's jobs | The Fence's word | Heals | Treatment | Respecs | Class changes | The Radio (notes) |")
	L.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- |")
	L.append("| %s (%d) | %s (%d) | %s (%d) | %s (%d) | %s (%d) | %s (%d) | %s (%d) | %s (%d) | %d (%d) |" % [_money(spend["yard"]), int(count.get("yard", 0)), _money(spend["yard_rank"]), int(count.get("yard_rank", 0)),
		_money(spend["craft"]), int(count.get("craft", 0)), _money(spend["gamble"]), int(count.get("gamble", 0)), _money(spend["heal"]), int(count.get("heal", 0)),
		_money(spend["treat"]), int(count.get("treat", 0)), _money(spend["respec"]), int(count.get("respec", 0)), _money(spend["class"]), int(count.get("class", 0)), spend["word"], int(count.get("word", 0))])
	L.append("")
	L.append("Trained, tree by tree:")
	var trees := {}
	for e in ch:
		if e["k"] == "train":
			trees[e["tree"]] = int(trees.get(e["tree"], 0)) + 1
	for tn in trees:
		L.append("- %s: %d nodes" % [tn, trees[tn]])
	L.append("")
	L.append("The Pitch, in the order built:")
	for e in ch:
		if e["k"] == "yard":
			L.append("- %s: %s %s (%s)" % [_when(e, by_play), e["key"], e["name"], _money(e.get("cost", 0))])
	# ---- the kit
	L.append("")
	L.append("## The kit, as it changed")
	L.append("")
	L.append("| When | Slot | On | Tier | Rarity | Worth | How |")
	L.append("| --- | --- | --- | --- | --- | --- | --- |")
	for e in ch:
		if e["k"] == "equip":
			var on: Dictionary = e.get("on", {})
			L.append("| %s | %s | %s | %d | %s | %s | %s |" % [_when(e, by_play), e["slot"], on.get("name", ""), int(on.get("tier", 0)), _rarity(on), _money(on.get("value", 0)), e.get("how", "")])
	L.append("")
	L.append("Lines in the record, by kind: %s." % ", ".join(count.keys().map(func(k): return "%s %d" % [k, count[k]])))
	return "\n".join(L) + "\n"


static func _hours(e: Dictionary, by_play: bool) -> float:
	return float(e.get("p", 0.0) if by_play else e.get("t", 0.0)) / 3600.0


static func _when(e: Dictionary, by_play: bool) -> String:
	return _h(float(e.get("p", 0.0) if by_play else e.get("t", 0.0)))


static func _at(e: Dictionary, by_play: bool) -> String:
	return "not yet" if e.is_empty() else "%s (level %d)" % [_when(e, by_play), int(e.get("lv", 0))]


static func _first(ch: Array, pred: Callable) -> Dictionary:
	for e in ch:
		if pred.call(e):
			return e
	return {}


static func _h(seconds: float) -> String:
	if seconds < 3600.0:
		return "%d m" % int(seconds / 60.0)
	return "%.1f h" % (seconds / 3600.0)


static func _pct(n: int, of: int) -> String:
	return "-" if of <= 0 else "%.0f%% (%d)" % [100.0 * n / of, n]


static func _money(v) -> String:
	var n := int(v)
	var neg := n < 0
	var t := str(absi(n))
	var out := ""
	while t.length() > 3:
		out = "," + t.right(3) + out
		t = t.left(t.length() - 3)
	return ("-£" if neg else "£") + t + out


static func _rarity(it: Dictionary) -> String:
	if it.get("unique", false):
		return "Unique"
	var r := int(it.get("rarity", 0))
	return Data.RARITIES[r]["name"] if r >= 0 and r < Data.RARITIES.size() else str(r)
