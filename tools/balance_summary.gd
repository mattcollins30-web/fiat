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

# the pass's gates (15 Oct, Matt approved; docs/design/balance_gates.md): twice the campaign as it stands, the bot at
# BOT_PACE of a hand's time (the 13 Oct reads' Bank against Matt's own the next day; his playtest re-measures it)
const BOT_PACE := 0.85
const BANK := [1.1, 1.6]        # the Manager beaten, the element builds' median, bot hours (2 x 47 min by hand)
const QM := [1.6, 2.3]          # the Quartermaster beaten: the campaign done (2 x 67 min by hand)
const QM_BAND := 2.0            # the slowest element build's Quartermaster within this of the fastest
const QM_LEVEL := [18, 22]      # the runner's level at the Quartermaster
const LV30_AFTER := 2.0         # level 30 within this many hours of the Quartermaster
const SIGNAL_GAP := 1.0 / 3.0   # from the Radio's opening to hour 12: a signal made at least every 20 min
const REACH_GAP := 0.75         # and reach +1 at least every 45 min
const LADDER_TO := 12.0
const STORY_BY := 10.0          # Kev's three beats done by this hour
const LV50 := [12.0, 24.0]      # level 50 not before, and by
const ODDS_FLOOR := 0.6         # survival at every open tier in the kit as it stands
const SEARCHES_A_GAP := 2.0     # the Outskirts' and the Estate's sites at depth 1: searches in a gap between gangs
const TIMEOUTS := 0.05          # runs out of time, under one in twenty
const LEAVE_BY5 := 0.5          # of the runs that stay into the third gang, the share gone by the fifth
const CITY_TOP := [0.08, 0.16]  # the loot read: epic or better in the City's gear (D6: the read counts gear alone now; 5-10% of every find was 8-16% of the gear)
const SETS_UNDER := 1.0 / 50.0  # set pieces a roll, everywhere in the read
const CASH_HOURS := 2.0         # cash in hand at the end, in hours of the build's income
const SCRAP_TOP_OF := {"Scrapper": 8.0}
const SCRAP := [0.5, 7.0]       # scrap earned an hour, in the dearest craft's worth
const PLAIN_BY := 24.0          # a plain build (no element tree) only has to finish the campaign by this
const TOP_SHARE := 0.02         # the probe: the top rarity at +35% quality (the plain share the weights' own)
const TOP_SHARE_PLAIN := 0.008
const FINDS_RATIO := [1.20, 1.30]
const LOOT_READ := "res://docs/balance/loot_read.md"


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
	# the element builds are the game (Matt, 11 Oct: every class has its two elements; who'd play without one?): every
	# gate below reads them alone. The plain builds - a class to its keystones, no element tree - are a floor, read on
	# their own row: every read finishes the campaign within PLAIN_BY
	var plains: Array = full.filter(func(b): return str(b.get("element", "")) == "")
	full = full.filter(func(b): return str(b.get("element", "")) != "")

	_pace_rows(rows, full)
	_ladder_rows(rows, full)
	# 9: no reds
	if not full.is_empty():
		var reds_in: Array = []
		for bd in full:
			for o in bd.get("odds", []):
				if float(o[1]) < ODDS_FLOOR:
					reds_in.append("%s T%d %.0f%%" % [bd["build"], int(o[0]), float(o[1]) * 100.0])
		rows.append(["9. No reds", "no open site at depth 1 under %.0f%%" % (ODDS_FLOOR * 100.0), "; ".join(reds_in) if not reds_in.is_empty() else "every open site at or over the floor", reds_in.is_empty()])
	_clock_rows(rows, full)
	_loot_rows(rows, full, probe)
	_economy_rows(rows, full)
	# the plain floor: every read of a plain build finishes the campaign
	if not plains.is_empty():
		var stuck: Array = []
		var times: Array = []
		for g in reads:
			if str(g.get("element", "")) != "":
				continue
			var h := float(g.get("qm_at", -1.0))
			if h < 0.0 or h > PLAIN_BY:
				stuck.append("%s %s in %s" % [g["build"], _hours(h), _hours(float(g.get("elapsed_h", g.get("hours", 0.0))))])
			else:
				times.append(h)
		rows.append(["The plain floor", "every read of a plain build beats the Quartermaster by hour %.0f" % PLAIN_BY, ("every read (latest %s)" % _hours(times.max())) if stuck.is_empty() else "stuck: " + ", ".join(stuck), stuck.is_empty()])
	# shown, not judged: the playtest's (deaths, wounds) - the bot doesn't take a player's risks
	var shown: Array = []
	for bd in full:
		var every: float = (float(bd["runs"]) / float(bd["bails"])) if int(bd.get("bails", 0)) > 0 else 999.0
		var wnd: float = (float(bd["wounded_runs"]) / float(bd["runs"])) if int(bd["runs"]) > 0 else 0.0
		shown.append("%s: bails one in %s, wounded %.0f%%" % [bd["build"], ("%.0f" % every) if every < 999.0 else "never", wnd * 100.0])
	rows.append(["Deaths and wounds", "judged at Matt's playtest (a death one run in 10-30, the first about 2 h 45 by hand; 5-30% wounded)", "the bot, not judged: " + "; ".join(shown), null])
	var reds := 0
	for r in rows:
		if r[3] is bool and not r[3]:
			reds += 1
	var out: Array = []
	out.append("# Balance summary")
	out.append("")
	out.append("Written %s by tools/balance_summary.gd from %d reads of %d builds (%d element, %d plain)%s. %s" % [
		Time.get_datetime_string_from_system(false, true), reads.size(), full.size() + plains.size(), full.size(), plains.size(), " and the probe" if not probe.is_empty() else " (no probe)",
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
	out.append("| Build | Hours | Manager | Quartermaster (level) | Level 30 | Level 50 | Radio | Signal gap / reach gap | Story | Reach | Level | Runs | Bails | Wounded | Into gang 3 (gone by 5) | Cash | Scrap (crafts/h) | Odds by tier | Kit |")
	out.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
	for b in reads:
		var wnd: float = (float(b["wounded_runs"]) / float(b["runs"])) if int(b["runs"]) > 0 else 0.0
		var dearest_b := float(b.get("dearest_build", 0))
		var crafts_b: float = (float(b.get("scrap_per_h", 0.0)) / dearest_b) if dearest_b > 0.0 else 0.0
		var odds: Array = []
		for o in b.get("odds", []):
			odds.append("T%d %.0f%%" % [int(o[0]), float(o[1]) * 100.0])
		out.append("| %s | %.1f (%.0f s wall) | %s | %s (%d) | %s | %s | %s | %s / %s | %s | %d | %d | %d | %d | %.0f%% | %d (%d) | %d | %d (%.1f) | %s | %s |" % [
			b["build"], float(b.get("elapsed_h", b["hours"])), float(b.get("wall_s", 0)), _hours(float(b.get("manager_at", -1.0))),
			_hours(float(b.get("qm_at", -1.0))), int(b.get("level_at_qm", -1)), _hours(float(b.get("lv30_at", -1.0))), _hours(float(b.get("lv50_at", -1.0))),
			_hours(float(b.get("radio_at", -1.0))), _mins(float(b.get("signal_gap_h", -1.0))), _mins(float(b.get("reach_gap_h", -1.0))), _hours(float(b.get("story_at", -1.0))),
			int(b.get("reach", 0)), int(b.get("level", 0)), int(b["runs"]), int(b.get("bails", 0)), wnd * 100.0, int(b.get("gang3_runs", 0)), int(b.get("left_by5", 0)),
			int(b["cash_end"]), int(b["scrap_end"]), crafts_b, " ".join(odds), str(b.get("kit", ""))])
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


## Gates 1-5: the Manager, the Quartermaster, the builds' band, the level at him, level 30 after him.
func _pace_rows(rows: Array, full: Array) -> void:
	if full.is_empty():
		return
	for pair in [["manager_at", "1. The Bank", BANK, "the Manager beaten"], ["qm_at", "2. The Quartermaster", QM, "the campaign done"]]:
		var vals: Array = []
		var never: Array = []
		for bd in full:
			if float(bd.get(pair[0], -1.0)) >= 0.0:
				vals.append(float(bd[pair[0]]))
			else:
				never.append(bd["build"])
		var med: float = _median(vals) if not vals.is_empty() else -1.0
		var band: Array = pair[2]
		var ok: bool = never.is_empty() and med >= band[0] and med <= band[1]
		var t: String = "median %s (%s to %s)" % [_hours(med), _hours(vals.min() if not vals.is_empty() else -1.0), _hours(vals.max() if not vals.is_empty() else -1.0)]
		if not never.is_empty():
			t += "; never: " + ", ".join(never)
		rows.append([pair[1], "%s at %.1f-%.1f h, the element builds' median (bot, %.2f of a hand)" % [pair[3], band[0], band[1], BOT_PACE], t, ok])
	var qms: Array = full.filter(func(bd): return float(bd.get("qm_at", -1.0)) >= 0.0).map(func(bd): return float(bd["qm_at"]))
	var band_ok: bool = qms.size() == full.size() and not qms.is_empty() and qms.max() <= QM_BAND * qms.min() + 0.001
	rows.append(["3. The builds' band", "the slowest Quartermaster within %.1fx the fastest" % QM_BAND, ("%s to %s" % [_hours(qms.min()), _hours(qms.max())]) if not qms.is_empty() else "none reached him", band_ok])
	var off: Array = []
	var lv: Array = []
	for bd in full:
		var l: int = int(bd.get("level_at_qm", -1))
		lv.append("%s %d" % [bd["build"], l])
		if l < QM_LEVEL[0] or l > QM_LEVEL[1]:
			off.append("%s %s" % [bd["build"], str(l) if l >= 0 else "never"])
	rows.append(["4. Levels against the campaign", "level %d-%d at the Quartermaster" % [QM_LEVEL[0], QM_LEVEL[1]], ("off: " + ", ".join(off)) if not off.is_empty() else "every build: " + ", ".join(lv), off.is_empty()])
	var late: Array = []
	for bd in full:
		var q := float(bd.get("qm_at", -1.0))
		var l30 := float(bd.get("lv30_at", -1.0))
		if q < 0.0 or l30 < 0.0 or l30 - q > LV30_AFTER:
			late.append("%s %s after him" % [bd["build"], ("%.1f h" % (l30 - q)) if q >= 0.0 and l30 >= 0.0 else "never"])
	rows.append(["5. The capstone", "level 30 within %.0f h of the Quartermaster" % LV30_AFTER, ("late: " + ", ".join(late)) if not late.is_empty() else "every build", late.is_empty()])


## Gates 6-8: the Radio's ladder, Kev's story, retirement.
func _ladder_rows(rows: Array, full: Array) -> void:
	if full.is_empty():
		return
	var off: Array = []
	var all_t: Array = []
	for bd in full:
		var sg := float(bd.get("signal_gap_h", -1.0))
		var rg := float(bd.get("reach_gap_h", -1.0))
		all_t.append("%s %s/%s" % [bd["build"], _mins(sg), _mins(rg)])
		if float(bd.get("radio_at", -1.0)) >= LADDER_TO:
			off.append("%s: the Radio opened at %s, after hour %.0f" % [bd["build"], _hours(float(bd["radio_at"])), LADDER_TO])
			continue
		if sg < 0.0 or rg < 0.0 or sg > SIGNAL_GAP + 0.001 or rg > REACH_GAP + 0.001:
			off.append("%s: signals %s, reach %s" % [bd["build"], _mins(sg), _mins(rg)])
	rows.append(["6. The Radio's ladder", "from the Radio's opening to hour %.0f, a signal at least every %d min and reach +1 every %d min (the longest stretch)" % [LADDER_TO, int(SIGNAL_GAP * 60.0), int(REACH_GAP * 60.0)],
		("off: " + "; ".join(off)) if not off.is_empty() else "every build (signals/reach): " + ", ".join(all_t), off.is_empty()])
	var late: Array = []
	for bd in full:
		var h := float(bd.get("story_at", -1.0))
		if h < 0.0 or h > STORY_BY:
			late.append("%s %s" % [bd["build"], _hours(h)])
	rows.append(["7. Kev's story", "the three beats done by hour %.0f" % STORY_BY, ("late: " + ", ".join(late)) if not late.is_empty() else "every build", late.is_empty()])
	var off50: Array = []
	var short: Array = []
	for bd in full:
		var h := float(bd.get("lv50_at", -1.0))
		var ran := float(bd.get("elapsed_h", bd["hours"]))
		if h < 0.0 and ran < LV50[1]:
			short.append(bd["build"])
		elif h < LV50[0] or h > LV50[1]:
			off50.append("%s %s" % [bd["build"], _hours(h)])
	var ok50: Variant = null                 # unread in a short read with nothing off
	if short.is_empty() or not off50.is_empty():
		ok50 = off50.is_empty()
	var t50: String = ("off: " + ", ".join(off50)) if not off50.is_empty() else "every build in the band"
	if not short.is_empty():
		t50 += " (not reached in a read shorter than %.0f h: %s)" % [LV50[1], ", ".join(short)]
	rows.append(["8. Retirement", "level 50 not before hour %.0f and by hour %.0f" % [LV50[0], LV50[1]], t50, ok50])


## Gates 10-11: the gang clock and staying.
func _clock_rows(rows: Array, full: Array) -> void:
	if full.is_empty():
		return
	var tight: Array = []
	var outs: Array = []
	for bd in full:
		for gc in bd.get("gang_clock", []):
			if float(gc[1]) < SEARCHES_A_GAP:
				tight.append("%s T%d %.1f" % [bd["build"], int(gc[0]), float(gc[1])])
		var share: float = (float(bd["timeouts"]) / float(bd["runs"])) if int(bd["runs"]) > 0 else 0.0
		if share >= TIMEOUTS:
			outs.append("%s %.1f%% out of time" % [bd["build"], share * 100.0])
	var t: String = ("searches a gap under %.0f: " % SEARCHES_A_GAP + ", ".join(tight.slice(0, 12)) + (" and %d more" % (tight.size() - 12) if tight.size() > 12 else "")) if not tight.is_empty() else "every site %.0f searches a gap or more" % SEARCHES_A_GAP
	if not outs.is_empty():
		t += "; " + ", ".join(outs)
	rows.append(["10. The gang clock", "the Outskirts' and the Estate's sites at depth 1: %.0f searches a gap between gangs; under %.0f%% of runs out of time" % [SEARCHES_A_GAP, TIMEOUTS * 100.0], t, tight.is_empty() and outs.is_empty()])
	var off: Array = []
	var none: Array = []
	for bd in full:
		var n := int(bd.get("gang3_runs", 0))
		if n == 0:
			none.append(bd["build"])
			continue
		var share: float = float(bd.get("left_by5", 0)) / float(n)
		if share < LEAVE_BY5:
			off.append("%s %.0f%% of %d" % [bd["build"], share * 100.0, n])
	var t2: String = ("stays too long: " + ", ".join(off)) if not off.is_empty() else "every build that stayed"
	if not none.is_empty():
		t2 += " (never into a third gang: %s)" % ", ".join(none)
	var ok11: Variant = null                 # no build ever stayed into a third gang: nothing to judge
	if none.size() < full.size():
		ok11 = off.is_empty()
	rows.append(["11. Staying costs", "of the runs into a third gang, %.0f%% or more gone by the fifth" % (LEAVE_BY5 * 100.0), t2, ok11])


## Gates 12-13 from the loot read (tests/loot_read.gd) and the builds, with the probe's two kept.
func _loot_rows(rows: Array, full: Array, probe: Dictionary) -> void:
	var lr: Dictionary = _read_loot()
	if lr.is_empty():
		rows.append(["12. The loot tables", "", "no loot read (tests/loot_read.gd writes docs/balance/loot_read.md)", false])
		rows.append(["13. The gamble", "", "no loot read", false])
	else:
		var notes: Array = []
		var ok := true
		var commons: Array = []
		for sec in ["Outskirts", "Estate", "Town", "City"]:
			commons.append(_mean(lr.get(sec, {}).get("drops", []).map(func(r): return float(r["rar"][0]))))
		for k in range(1, commons.size()):
			if commons[k] > commons[k - 1] + 0.5:
				ok = false
		notes.append("commons by zone " + "/".join(commons.map(func(c): return "%.0f" % c)))
		var top: float = _mean(lr.get("City", {}).get("drops", []).map(func(r): return float(r["rar"][3]) + float(r["rar"][4]))) / 100.0
		ok = ok and top >= CITY_TOP[0] and top <= CITY_TOP[1]
		notes.append("the City's epic or better %.1f%%" % (top * 100.0))
		var sets_max := 0.0
		for sec in lr:
			for r in lr[sec].get("drops", []) + lr[sec].get("gamble", []):
				sets_max = maxf(sets_max, float(r["sets"]) / float(lr[sec]["rolls"]))
		ok = ok and sets_max < SETS_UNDER
		notes.append("set pieces at most 1 in %.0f" % (1.0 / sets_max if sets_max > 0.0 else 9999.0))
		var with_u: Array = full.filter(func(bd): return bool(bd.get("loose_unique_by_qm", false)))
		ok = ok and with_u.size() * 2 > full.size()
		notes.append("a loose unique by the Quartermaster on %d of %d builds" % [with_u.size(), full.size()])
		rows.append(["12. The loot tables", "commons fall zone on zone; epic or better %.0f-%.0f%% in the City; set pieces under 1 in %.0f; a loose unique by the Quartermaster on most builds" % [CITY_TOP[0] * 100.0, CITY_TOP[1] * 100.0, 1.0 / SETS_UNDER], "; ".join(notes), ok])
		var past: Array = []
		for sec in ["Outskirts", "Estate", "Town", "City"]:
			if not lr.has(sec):
				continue
			var dw: Array = lr[sec].get("drops", []).map(func(r): return int(r["wear"]))
			for r in lr[sec].get("gamble", []):
				if not dw.is_empty() and int(r["wear"]) > dw.max():
					past.append("%s: the gamble's %d over the drops' best %d" % [sec, int(r["wear"]), dw.max()])
		rows.append(["13. The gamble", "its finds' level to wear never past the drops' at the same point (the loot read)", ("; ".join(past)) if not past.is_empty() else "at or under the drops at every campaign point", past.is_empty()])
	if not probe.is_empty():
		var es := float(probe.get("top_share", probe.get("elite_share", 0.0)))
		var esp := float(probe.get("top_share_plain", probe.get("elite_share_plain", 0.0)))
		rows.append(["Loot quality visible", "Legendary share %.1f%% at +35%% quality (%.1f%% plain)" % [TOP_SHARE * 100.0, TOP_SHARE_PLAIN * 100.0],
			"%.2f%% boosted, %.2f%% plain" % [es * 100.0, esp * 100.0], es >= TOP_SHARE and esp >= TOP_SHARE_PLAIN])
		var fr := float(probe["finds_ratio"])
		rows.append(["Quantity honest", "finds at +25%% quantity %.2f to %.2f times plain" % [FINDS_RATIO[0], FINDS_RATIO[1]],
			"%.2f (%.2f against %.2f a search)" % [fr, float(probe["finds_boosted"]), float(probe["finds_plain"])], FINDS_RATIO[0] <= fr and fr <= FINDS_RATIO[1]])


## Gates 14-15: cash in hand and scrap earned.
func _economy_rows(rows: Array, full: Array) -> void:
	if full.is_empty():
		return
	var over: Array = []
	var most := 0.0
	for bd in full:
		var per_h := float(bd.get("cash_per_h", 0.0))
		var held: float = (float(bd["cash_end"]) / per_h) if per_h > 0.0 else 0.0
		most = maxf(most, held)
		if held > CASH_HOURS:
			over.append("%s holds %d tins, %.1f hours' income" % [bd["build"], int(bd["cash_end"]), held])
	rows.append(["14. Cash sink", "cash in hand at the end no more than %.0f hours' income" % CASH_HOURS, "; ".join(over) if not over.is_empty() else "every build under (most %.1f)" % most, over.is_empty()])
	var off: Array = []
	for bd in full:
		var dearest := float(bd.get("dearest_build", 0))
		var crafts: float = (float(bd.get("scrap_per_h", 0.0)) / dearest) if dearest > 0.0 else 0.0
		bd["_crafts"] = crafts
		if crafts < SCRAP[0] or crafts > float(SCRAP_TOP_OF.get(str(bd.get("class", "")), SCRAP[1])):
			off.append("%s %.1f crafts/h" % [bd["build"], crafts])
	rows.append(["15. Scrap", "scrap earned an hour worth %.1f to %.0f of the dearest craft (the Scrapper to %.0f)" % [SCRAP[0], SCRAP[1], SCRAP_TOP_OF["Scrapper"]], "; ".join(off) if not off.is_empty() else "every build in the band", off.is_empty()])


## The loot read's tables: {"Outskirts": {rolls, drops: [{rar: [C,U,R,E,L], wear, sets}], gamble: [...]}, ...} for the
## campaign's four points ("## <Zone> done (...)"); {} with no read.
func _read_loot() -> Dictionary:
	if not FileAccess.file_exists(LOOT_READ):
		return {}
	var out := {}
	var sec := ""
	var rolls := 600
	for line in FileAccess.get_file_as_string(LOOT_READ).split("\n"):
		if line.begins_with("600 rolls") or line.contains(" rolls a source"):
			rolls = int(line.split(" ")[0])
		if line.begins_with("## "):
			sec = ""
			for z in ["Outskirts", "Estate", "Town", "City"]:
				if line.begins_with("## %s done" % z):
					sec = z
					out[sec] = {"rolls": rolls, "drops": [], "gamble": []}
			continue
		if sec == "" or not line.begins_with("| ") or line.begins_with("| Source") or line.begins_with("|---"):
			continue
		var cells: Array = Array(line.split("|")).map(func(c): return str(c).strip_edges()).filter(func(c): return c != "")
		if cells.size() < 7:
			continue
		var rar: Array = Array(str(cells[1]).split("/")).map(func(v): return float(v))
		var row := {"rar": rar, "wear": int(cells[3]), "sets": int(cells[6])}
		out[sec]["gamble" if str(cells[0]).begins_with("The gamble") else "drops"].append(row)
	return out


func _mean(vals: Array) -> float:
	if vals.is_empty():
		return 0.0
	var t := 0.0
	for v in vals:
		t += float(v)
	return t / vals.size()


func _mins(h: float) -> String:
	return "never" if h < 0.0 else "%d min" % int(round(h * 60.0))


## 1234567 as "1,234,567".
func _thousands(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


## One build's reads as one: the firsts by their median (a never counts as later than any), the odds by the median a
## tier, cash, scrap and level by the mean, runs, deaths and wounded runs summed, the clears joined.
func _merged(gs: Array) -> Dictionary:
	if gs.size() == 1:
		return gs[0]
	var m: Dictionary = gs[0].duplicate(true)
	for key in ["bank_at", "keystone_at", "capstone_at", "lorry_at", "manager_at", "qm_at", "lv30_at", "lv50_at", "radio_at", "story_at", "signal_gap_h", "reach_gap_h", "level_at_qm"]:
		if not gs[0].has(key):
			continue
		# by their median, a never counted as later than any (the review, 15 Oct: one read of two that never got there
		# makes the build's never - a gate isn't green on the other read alone); never stays -1, not 505 h
		var vals: Array = gs.map(func(g): return float(g.get(key, -1.0))).map(func(v): return INF if v < 0.0 else v)
		var med: float = _median(vals)
		m[key] = -1.0 if is_inf(med) else snappedf(med, 0.01)
	for key in ["cash_end", "scrap_end", "scrap_spent", "notes_end", "level", "scrap_per_h", "cash_per_h", "bails_per_h", "elapsed_h", "wall_s"]:
		if not gs[0].has(key):
			continue                      # an older read without the key keeps lacking it (the rows read the lack)
		var total := 0.0
		for g in gs:
			total += float(g.get(key, 0))
		m[key] = snappedf(total / gs.size(), 0.01)
	for key in ["runs", "deaths", "wounded_runs", "timeouts", "dry_timeouts", "bails", "moves", "lorries", "gang3_runs", "left_by5"]:
		if not gs[0].has(key) and key in ["timeouts", "dry_timeouts"]:
			continue                      # a read from before the clock (9 Oct) lacks them: the Clock row reads the lack
		var n := 0
		for g in gs:
			n += int(g.get(key, 0))
		m[key] = n
	m["services_depth"] = gs.map(func(g): return int(g.get("services_depth", 0))).max()
	m["loose_unique_by_qm"] = gs.filter(func(g): return bool(g.get("loose_unique_by_qm", false))).size() * 2 > gs.size()     # most of its reads
	m["reach"] = int(_median(gs.map(func(g): return float(g.get("reach", 0)))))
	var clock: Dictionary = {}
	for g in gs:
		for gc in g.get("gang_clock", []):
			clock[int(gc[0])] = minf(float(clock.get(int(gc[0]), 999.0)), float(gc[1]))     # the tightest read a site
	m["gang_clock"] = clock.keys().map(func(k): return [k, clock[k]])
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
	@warning_ignore("integer_division")
	return float(v[n / 2]) if n % 2 == 1 else (float(v[n / 2 - 1]) + float(v[n / 2])) / 2.0


func _hours(v: float) -> String:
	return "never" if v < 0.0 else "%.1f h" % v
