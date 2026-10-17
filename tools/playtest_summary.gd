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
	# the pass's gates (15 Oct, docs/design/balance_gates.md): by hand the targets are the bot's over its pace
	var hand := func(h: float) -> String: return "%.1f h" % (h / GATES.BOT_PACE)
	var mgr: Dictionary = _first(ch, func(e): return e["k"] == "boss" and int(e.get("zone", -1)) == 2)
	L.append("| 1. The Bank (the Manager) | %s-%s by hand | %s |" % [hand.call(GATES.BANK[0]), hand.call(GATES.BANK[1]), _at(mgr, by_play)])
	var qm: Dictionary = _first(ch, func(e): return e["k"] == "boss" and int(e.get("zone", -1)) == 3)
	L.append("| 2. The Quartermaster | %s-%s by hand | %s |" % [hand.call(GATES.QM[0]), hand.call(GATES.QM[1]), _at(qm, by_play)])
	L.append("| 4. Level at the Quartermaster | %d-%d | %s |" % [GATES.QM_LEVEL[0], GATES.QM_LEVEL[1], ("%d" % int(qm.get("lv", 0))) if not qm.is_empty() else "not yet"])
	var l30: Dictionary = _first(ch, func(e): return e["k"] == "level" and int(e.get("to", 0)) >= 30)
	L.append("| 5. Level 30 | within %.0f h of the Quartermaster | %s |" % [GATES.LV30_AFTER, _at(l30, by_play)])
	var radio: Dictionary = _first(ch, func(e): return e["k"] == "open" and str(e.get("room", "")) == "radio")
	var sigs := ch.filter(func(e): return e["k"] == "signal")
	L.append("| 6. The Radio's ladder | a signal every %d min from the Radio | the Radio %s; %d signals made |" % [int(GATES.SIGNAL_GAP * 60.0), _at(radio, by_play), sigs.size()])
	var story: Dictionary = _first(ch, func(e): return e["k"] == "story" and int(e.get("beat", -1)) >= Data.STORY_BEATS.size() - 1)
	L.append("| 7. Kev's story | done by hour %.0f (bot) | %s |" % [GATES.STORY_BY, _at(story, by_play)])
	var l50: Dictionary = _first(ch, func(e): return e["k"] == "level" and int(e.get("to", 0)) >= 50)
	L.append("| 8. Retirement (level 50) | hour %.0f-%.0f (bot) | %s |" % [GATES.LV50[0], GATES.LV50[1], _at(l50, by_play)])
	var deaths := live.filter(func(e): return e.get("outcome", "") == "Dead").size()
	var first_dead: Dictionary = _first(live, func(e): return e.get("outcome", "") == "Dead")
	L.append("| Deaths (judged here) | a death one run in 10 to 30, the first about 2 h 45 | %s; the first %s |" % [
		("%d in %d live runs: one in %.0f" % [deaths, live.size(), float(live.size()) / deaths]) if deaths > 0 else "none in %d live runs" % live.size(), _at(first_dead, by_play)])
	var wounded := live.filter(func(e): return e.get("wounded", false)).size()
	L.append("| Wounds (judged here) | 5-30%% of runs | %s |" % _pct(wounded, live.size()))
	var outs := live.filter(func(e): return e.get("timed_out", false)).size()
	L.append("| 10. Clock | under %.0f%% out of time | %s |" % [GATES.TIMEOUTS * 100.0, _pct(outs, live.size())])
	var into3 := live.filter(func(e): return int(e.get("patrols", 0)) >= 3)
	var gone5 := into3.filter(func(e): return int(e.get("patrols", 0)) <= 5).size()
	L.append("| 11. Staying costs | %.0f%% of runs into a third gang gone by the fifth | %s |" % [GATES.LEAVE_BY5 * 100.0, ("%d of %d" % [gone5, into3.size()]) if not into3.is_empty() else "never into a third gang"])
	var ways := live.filter(func(e): return e.get("way_out", false)).size()
	L.append("| The way out | (not a gate) | %s of runs left by the way out |" % _pct(ways, live.size()))
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
	# ---- the dots and the drops (17 Oct): how much of the damage the dots' ticks did, against what the one figure said,
	# by the +% dots on; and the gear found against what the runner could wear - the campaign's and the signals' apart
	var dot_runs: Array = runs.filter(func(e): return e.has("ticked") and not e.get("away", false))
	L.append("")
	L.append("## The dots and the drops")
	L.append("")
	if dot_runs.is_empty():
		L.append("No run in this record carries the dots and the drops (a save from before 17 Oct).")
	else:
		L.append("| Runs | +% dots on (gear, tree) | Dealt | From dots' ticks | The figure's dot share (mean) |")
		L.append("| --- | --- | --- | --- | --- |")
		var groups := {}
		for e in dot_runs:
			var key := "%.0f%%, %.0f%%" % [float(e.get("dot_gear", 0.0)), float(e.get("dot_tree", 0.0))]
			if not groups.has(key):
				groups[key] = {"n": 0, "dealt": 0, "ticked": 0, "share": 0.0}
			var g: Dictionary = groups[key]
			g["n"] += 1
			g["dealt"] += int(e.get("dealt", 0))
			g["ticked"] += int(e.get("ticked", 0))
			g["share"] += float(e.get("split_dot", 0.0)) / maxf(0.1, float(e.get("split_total", 0.0)))
		for key in groups:
			var g: Dictionary = groups[key]
			L.append("| %d | %s | %d | %s | %.0f%% |" % [g["n"], key, int(g["dealt"]), _pct(int(g["ticked"]), maxi(1, int(g["dealt"]))), 100.0 * float(g["share"]) / maxf(1.0, float(g["n"]))])
		L.append("")
		L.append("| Gear found on | Runs | Gear | Wearable when found | At your level (from a site over it) |")
		L.append("| --- | --- | --- | --- | --- |")
		for sig in [false, true]:
			var these: Array = dot_runs.filter(func(e): return bool(e.get("signal", false)) == sig)
			if these.is_empty():
				continue
			var gear: int = these.reduce(func(a, e): return a + int(e.get("gear", 0)), 0)
			L.append("| %s | %d | %d | %s | %s |" % ["Signals" if sig else "The campaign", these.size(), gear,
				_pct(these.reduce(func(a, e): return a + int(e.get("gear_wearable", 0)), 0), maxi(1, gear)),
				_pct(these.reduce(func(a, e): return a + int(e.get("gear_at_mine", 0)), 0), maxi(1, gear))])
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
	var spend := {"yard": 0, "yard_rank": 0, "craft": 0, "gamble": 0, "heal": 0, "treat": 0, "respec": 0, "class": 0, "word": 0, "kev": 0}
	var count := {}
	for e in ch:
		var k: String = e["k"]
		count[k] = int(count.get(k, 0)) + 1
		match k:
			"yard", "yard_rank", "craft", "heal", "treat", "respec", "class", "word":
				spend[k] += int(e.get("cost", 0))
			"gamble":
				spend["gamble"] += int(e.get("price", 0))
			"kev":
				spend["kev"] += int(e.get("price", 0))
	L.append("| The Pitch | Ranks | The Workshop's jobs | The Fence's word | Heals | Treatment | Respecs | Class changes | The Radio (notes) | Kev's papers (notes) |")
	L.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
	L.append("| %s (%d) | %s (%d) | %s (%d) | %s (%d) | %s (%d) | %s (%d) | %s (%d) | %s (%d) | %d (%d) | %d (%d) |" % [_money(spend["yard"]), int(count.get("yard", 0)), _money(spend["yard_rank"]), int(count.get("yard_rank", 0)),
		_money(spend["craft"]), int(count.get("craft", 0)), _money(spend["gamble"]), int(count.get("gamble", 0)), _money(spend["heal"]), int(count.get("heal", 0)),
		_money(spend["treat"]), int(count.get("treat", 0)), _money(spend["respec"]), int(count.get("respec", 0)), _money(spend["class"]), int(count.get("class", 0)), spend["word"], int(count.get("word", 0)), spend["kev"], int(count.get("kev", 0))])
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
