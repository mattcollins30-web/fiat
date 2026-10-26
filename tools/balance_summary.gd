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

const FOLDER := "res://docs/balance/pass"     # the pass's own folder (25 Oct): the smoke's log stays out of it
const NOT_BUILDS := ["smoke.txt", "checkpoint.txt", "loot_read.txt", "expected.txt"]     # .txt in the pass folder that aren't a build's read
const SUMMARY := "res://docs/balance/summary.md"
## Each gate's kind (25 Oct, Matt: bot timings aren't tuned before a playtest; the bot doesn't take a player's risks):
## "design" a red to fix; "bot timing" his play sets the figure; "bot play" the bot's caution, shown for the shape.
const TIMING_GATES := ["1.", "2.", "3.", "5.", "7.", "8.", "17.", "P4."]
const BOT_PLAY_GATES := ["P1.", "P2.", "P3.", "P6.", "Wounds (as played)", "Deaths (as played)", "Deaths and wounds"]     # P6 (25 Oct, the tools review): the bot runs a full signal only at PUSH, or at COIN with three held
## Why a gate can go unjudged, for the header (25 Oct, the tools review: "19 RED" didn't say one went unread)
const UNJUDGED_WHY := {"11.": "the bot leaves at the second gang, bar a head's run", "8.": "the reads were shorter than the window", "P3.": "no first clears or heads recorded", "P6.": "no signals run"}

# the pass's gates (15 Oct, Matt approved; docs/design/balance_gates.md): twice the campaign as it stands, the bot at
# BOT_PACE of a hand's time (the 13 Oct reads' Bank against Matt's own the next day; his playtest re-measures it)
const BOT_PACE := 0.85
# the pass of 20 Oct (Matt: "Yeah I think they are a good starting place for gates"): the figures by hand, the bot's
# read against them at BOT_PACE. The bots set the shape (deaths, odds, stalls, builds finishing); Matt's play sets the times.
const HAND_BANK := [1.5, 2.5]
const HAND_QM := [3.0, 4.0]
const HAND_STORY_BY := 13.0
const HAND_LORRY := [10.0, 13.0]   # one moment with Kev's story (20 Oct, Matt: "One gate, ~10-13 h"): his third beat is the depot, its convoy the lorry
const BANK := [HAND_BANK[0] * BOT_PACE, HAND_BANK[1] * BOT_PACE]     # the Manager beaten, the element builds' median, bot hours (was 1.1-1.7, 17 Oct)
const QM := [HAND_QM[0] * BOT_PACE, HAND_QM[1] * BOT_PACE]           # the Quartermaster beaten, the campaign done (was 1.4-2.1)
const LORRY := [HAND_LORRY[0] * BOT_PACE, HAND_LORRY[1] * BOT_PACE]
const DEATH_EVERY := [10.0, 30.0]  # a death one run in this many, the bot's (the bots set the shape)
const FIRST_DEATH_BY := 2.0 * 1.25 # the first by about 2 h by hand (a quarter's slack: "about")
const WOUNDED := [0.05, 0.30]      # of runs, wounded
const ODDS_MED := [0.70, 0.90]     # the odds at the gate, the median run
const REACH_STAND := 1.2           # the endgame's stall: the reach never stands more than about an hour (bot hours)
const FAINT_WON := 0.85            # a faint signal won about nine in ten
const FULL_WON := [0.35, 0.65]     # a full one at the reach about a coin flip
const HAND_GK := [0.3, 0.5]     # the Gamekeeper beaten, the Outskirts done (17 Oct, Matt: "about 25 minutes" by hand)
const GK := [HAND_GK[0] * BOT_PACE, HAND_GK[1] * BOT_PACE]     # bot hours as every hand figure (25 Oct, the tools review: it was the one left unscaled)
const GK_LEVEL := 3             # and the runner at least this level leaving them
const SITE_LEVEL_UNDER := 1     # at a site's first clear, the runner no more than this under the level to wear its gear (17 Oct, Matt)
const SITE_LEVEL_OVER := 3      # nor more than this over it (the Outskirts' grind not a level ahead of the gear for long)
const Sim := preload("res://scripts/sim/sim.gd")
const Feel := preload("res://tools/feel_gates.gd")
const Data := preload("res://scripts/sim/data.gd")
const QM_BAND := 2.0            # the slowest element build's Quartermaster within this of the fastest
const QM_LEVEL := [19, 23]      # the runner's level at the Quartermaster (25 Oct, Matt: 20-24 to 19-23 - the Barracks' gear is level 16 and gate 16 holds him to 3 over it, so 20-24 and gate 16 couldn't both pass; 17 Oct: was 18-22)
const LV30_AFTER := 2.0         # level 30 within this many hours of the Quartermaster
const SIGNAL_GAP := 1.0 / 3.0   # from the Radio's opening to hour 12: a signal made at least every 20 min
const REACH_GAP := 3.0          # and the reach never more than 3 h without a level (16 Oct, Matt: was +1 every 45 min)
const REACH_RATE := 1.0         # and on average a level an hour or better
const LADDER_TO := 12.0
const STORY_BY := HAND_STORY_BY * BOT_PACE     # Kev's three beats done by this hour (bot hours)
const LV50 := [12.0, 24.0]      # level 50 not before, and by - on the median element read (Matt, 16 Oct)
const LV50_FLOOR := 8.0         # and no read before this
const ODDS_FLOOR := 0.6         # survival at every open tier in the kit as it stands
const SEARCHES_A_GAP := 2.0     # the Outskirts' and the Estate's sites at depth 1: searches in a gap between gangs
const TIMEOUTS := 0.05          # runs out of time, under one in twenty
const LEAVE_BY5 := 0.5          # of the runs that stay into the third gang, the share gone by the fifth
const CITY_TOP := [0.08, 0.16]  # the loot read: epic or better in the City's gear (D6: the read counts gear alone now; 5-10% of every find was 8-16% of the gear)
const SETS_UNDER := 1.0 / 50.0  # set pieces a roll, everywhere in the read
const CASH_HOURS := 2.0         # cash in hand at the end, in hours of the build's income
const SCRAP_HOURS := 2.0        # scrap in hand at the end, in hours of the build's scrap income (25 Oct, the third pass: as
                                 # cash; the old yardstick, a 120-scrap build, was a price nothing paid once tempering came)
const PLAIN_BY := 24.0          # a plain build (no element tree) only has to finish the campaign by this
const TOP_SHARE := 0.02         # the probe: the top rarity at +35% quality (the plain share the weights' own)
const TOP_SHARE_PLAIN := 0.008
const FINDS_RATIO := [1.20, 1.30]
const LOOT_READ := "res://docs/balance/loot_read.md"
const PARITY_BAND := 0.5        # build parity (25 Oct): every build's reach gained in the spell at least this share of the best's


const BROKEN_OUTRUN := 1.5     # a broken build's reach gained, at least this times its plain baseline's (Matt, 26 Oct: "both")
const BROKEN_MD := "res://docs/balance/broken.md"
const HUNT_MD := "res://docs/balance/hunt.md"
const HUNT_ROWS := 30          # a stage's table: its best this many (every build's line stays in pass/hunt-s<stage>-*.txt)


## The broken builds' reads (26 Oct): a BROKEN line each in pass/broken-<key>[-plain].txt.
static func read_broken() -> Array:
	var out: Array = []
	var dir := DirAccess.open(FOLDER)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.ends_with(".txt") and f.begins_with("broken-"):
			var got := false
			for line in FileAccess.get_file_as_string(FOLDER + "/" + f).split("\n"):
				if line.begins_with("BROKEN "):
					var bp = JSON.parse_string(line.substr(7).strip_edges())
					if bp is Dictionary:
						out.append(bp)
						got = true
			if not got:
				var nm: String = f.get_basename().substr(7)
				out.append({"build": nm.trim_suffix("-plain"), "plain": nm.ends_with("-plain"), "error": "no BROKEN line (the read crashed or was cut off)"})
	return out


## The broken builds' table (26 Oct, Matt: broken is "both" - every piece of content beaten once, and the reach well past
## the same runner, start and pieces, the combos off): a row a build, its plain baseline beside it, judged.
static func broken_table(all: Array) -> Array:
	var out: Array = []
	var broken: Array = all.filter(func(b): return not b.get("plain", false))
	if broken.is_empty():
		return out
	var plain := {}
	for b in all:
		if b.get("plain", false):
			plain[str(b.get("build", ""))] = b
	out.append("")
	out.append("## The broken builds (outside the balance)")
	out.append("")
	out.append("Each from the Radio's checkpoint at level 50, the combos on for it alone, its set and unique held at the depth's tier, issued kit in the set's other slots; its plain baseline the same runner, start and pieces with the combos off. Broken when it beat everything (the Grid, the Archive, the Mint, the Issue and the County's twelve) and its reach gained is at least %.1f times its baseline's." % BROKEN_OUTRUN)
	out.append("")
	out.append("| Build | Class | Played | Runs with it on | Reach (plain) | Dealt a second fought (plain) | Beaten (hour) | Never | Deaths | |")
	out.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
	broken.sort_custom(func(a, b): return str(a.get("build", "")) < str(b.get("build", "")))
	for bb in broken:
		if bb.has("error"):
			out.append("| %s | | | | | | %s | | | RED |" % [bb.get("build", "?"), bb["error"]])
			continue
		var pb: Dictionary = plain.get(str(bb["build"]), {})
		var gain: int = int(bb.get("reach1", 0)) - int(bb.get("reach0", 0))
		var pgain: int = (int(pb.get("reach1", 0)) - int(pb.get("reach0", 0))) if not pb.is_empty() and not pb.has("error") else -1
		var missing: Array = bb.get("missing", [])
		# outran: a gain of its own, and 1.5x a baseline that gained something (a baseline at +0 can't be outrun by ratio: the review)
		var outran: bool = pgain > 0 and gain > 0 and gain >= BROKEN_OUTRUN * pgain
		var why_not: String = "no baseline" if pgain < 0 else ("its baseline gained nothing to judge by" if pgain == 0 else ("not %.1fx its baseline" % BROKEN_OUTRUN))
		var bt: Dictionary = bb.get("beaten", {})
		var bt_words: Array = bt.keys().map(func(k): return "%s %.1f" % [k, float(bt[k])])
		var label: String = str(bb["build"]) + ((" = " + str(bb["id"])) if str(bb.get("id", bb["build"])) != str(bb["build"]) else "")
		out.append("| %s | %s as %s | %.1f of %.1f h%s | %d of %d | %d to %d (+%d; plain %s) | %s (%s) | %s | %s | %d | %s |" % [label, bb.get("class", ""), bb.get("element", ""),
			float(bb.get("played_h", 0.0)), float(bb.get("hours", 0.0)), " (cut short)" if bb.get("cut_short", false) else "",
			int(bb.get("runs_on", 0)), int(bb.get("runs", 0)), int(bb.get("reach0", 0)), int(bb.get("reach1", 0)), gain, ("+%d" % pgain) if pgain >= 0 else "none",
			str(int(float(bb.get("rate", 0.0)))), str(int(float(pb.get("rate", 0.0)))) if not pb.is_empty() else "none", ", ".join(bt_words) if not bt_words.is_empty() else "nothing",
			", ".join(missing) if not missing.is_empty() else "none - everything fell", int(bb.get("deaths", 0)),
			"BROKEN" if (missing.is_empty() and outran) else ("RED: " + ("content left" if not missing.is_empty() else "") + (" and " if not missing.is_empty() and not outran else "") + (why_not if not outran else ""))])
	return out


## The build hunt's stage (26 Oct, Matt: "cook some different builds up"): its HUNT lines, best first by the damage
## really dealt a second fought - over all its runs, the long ones (ten patrols or more) and the short apart.
static func hunt_table(stage: int) -> Array:
	var rows: Array = []
	var bad: Array = []
	var dir := DirAccess.open(FOLDER)
	if dir != null:
		for f in dir.get_files():
			if not (f.begins_with("hunt-s%d-" % stage) and f.ends_with(".txt")):
				continue
			var got := 0
			for line in FileAccess.get_file_as_string(FOLDER + "/" + f).split("\n"):
				if line.begins_with("HUNT {"):
					var d = JSON.parse_string(line.substr(5).strip_edges())
					if d is Dictionary:
						rows.append(d)
						got += 1
			if got == 0:
				bad.append(f.get_basename())
	rows.sort_custom(func(x, y): return float(x.get("rate", 0.0)) > float(y.get("rate", 0.0)))
	var out: Array = ["", "## Stage %d: %d builds%s" % [stage, rows.size(), (" (no lines from %s)" % ", ".join(bad)) if not bad.is_empty() else ""], ""]
	if rows.is_empty():
		return out
	out.append("| # | Build | Dealt a second fought | Long runs | Short runs | Reach | Beaten | Deaths | Timed out | One of the six |")
	out.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
	for i in range(mini(HUNT_ROWS, rows.size())):
		var r: Dictionary = rows[i]
		var rl := float(r.get("rate_long", -1.0))
		var rs := float(r.get("rate_short", -1.0))
		out.append("| %d | %s | %d | %s | %s | %d to %d | %s | %d | %d of %d | %s |" % [i + 1, r.get("id", "?"), int(float(r.get("rate", 0.0))),
			str(int(rl)) if rl >= 0.0 else "-", str(int(rs)) if rs >= 0.0 else "-", int(r.get("reach0", 0)), int(r.get("reach1", 0)),
			", ".join(r.get("beaten", {}).keys()) if not r.get("beaten", {}).is_empty() else "-", int(r.get("deaths", 0)), int(r.get("ends", {}).get("timed out", 0)), int(r.get("runs", 0)), ", ".join(r.get("combo_on", [])) if not r.get("combo_on", []).is_empty() else "-"])
	return out


func _init() -> void:
	if "hunt" in OS.get_cmdline_user_args():
		# `-- hunt`: the build hunt (tools\balance.bat <hours> 0 hunt), to docs/balance/hunt.md - the two stages, then the
		# finalists' 16 h reads judged as the broken builds are
		var hl: Array = ["# The build hunt", "", "Written %s from %s." % [Time.get_datetime_string_from_system(false, true), FileAccess.get_file_as_string(FOLDER + "/broken_commit.log").strip_edges()], "",
			"Every class's two joints, each with every set at its count or none (stage 1); stage 1's best twenty, each with every unique whose slot the set leaves free (stage 2); stage 2's best six, 16 h each from the checkpoint against a plain baseline (the finalists). Every read from the Radio's checkpoint at level 50, the recipe walked, the pieces held at the depth's tier, the runner staying out till 20 patrols or the bail. Ranked by the damage really dealt a second fought."]
		hl.append_array(hunt_table(1))
		hl.append_array(hunt_table(2))
		var fin: Array = read_broken()
		if fin.is_empty():
			hl.append_array(["", "## The finalists", "", "No finalist reads."])
		else:
			hl.append_array(broken_table(fin))
		var hf := FileAccess.open(HUNT_MD, FileAccess.WRITE)
		hf.store_string("\n".join(hl) + "\n")
		hf.close()
		print("-> docs/balance/hunt.md")
		quit(0)
		return
	if "broken" in OS.get_cmdline_user_args():
		# `-- broken`: the broken builds' reads alone (tools\balance.bat <hours> 0 broken), to docs/balance/broken.md
		var lines: Array = ["# The broken builds", "", "Written %s from %s." % [Time.get_datetime_string_from_system(false, true), FileAccess.get_file_as_string(FOLDER + "/broken_commit.log").strip_edges()]]
		lines.append_array(broken_table(read_broken()))
		var bf := FileAccess.open(BROKEN_MD, FileAccess.WRITE)
		bf.store_string("\n".join(lines) + "\n")
		bf.close()
		print("-> docs/balance/broken.md")
		quit(0)
		return
	var builds: Array = []
	var probe: Dictionary = {}
	var dir := DirAccess.open(FOLDER)
	if dir == null:
		printerr("no docs/balance folder; run tools\\balance.bat first")
		quit(1)
		return
	var names: Array = []
	var parity: Array = []                # the parity reads (25 Oct): a PARITY line each, their own table and row
	var broken: Array = read_broken()     # the broken builds' reads (26 Oct): a BROKEN line each, outside the gates
	for f in dir.get_files():
		if f.ends_with(".txt") and (f.begins_with("broken-") or f.begins_with("hunt-")):
			continue
		elif f.ends_with(".txt") and f.begins_with("parity-"):
			var got := false
			for line in FileAccess.get_file_as_string(FOLDER + "/" + f).split("\n"):
				if line.begins_with("PARITY "):
					var pp = JSON.parse_string(line.substr(7).strip_edges())
					if pp is Dictionary:
						parity.append(pp)
						got = true
			if not got:
				var pn: PackedStringArray = f.get_basename().substr(7).split("-")     # parity-<class>-<element>[-<read>]
				parity.append({"build": "%s as %s" % [pn[0], pn[1] if pn.size() > 1 else "?"], "error": "no PARITY line (the read crashed or was cut off)"})     # counted, not dropped (the review)
		elif f.ends_with(".txt") and not f in NOT_BUILDS:
			names.append(f)
	names.sort()
	# how each read ended (25 Oct, the tools review: a killed read read as crashed, and one that never wrote went unnamed):
	# its .done from tools/balance_read.bat ("done ok", "done killed-time", ...; the checkpoint's kept as .end), the
	# names balance.bat started (pass/expected.txt), and whether the pass's five-hour deadline fired (pass/deadline.log)
	var deadline: bool = FileAccess.file_exists(FOLDER + "/deadline.log")
	var ends: Dictionary = {}
	for f in dir.get_files():
		if f.ends_with(".done") or f == "checkpoint.end":
			ends[f.get_basename()] = FileAccess.get_file_as_string(FOLDER + "/" + f).strip_edges().trim_prefix("done").strip_edges()
	var expected: Array = []
	for line in FileAccess.get_file_as_string(FOLDER + "/expected.txt").split("\n"):
		if line.strip_edges() != "":
			expected.append(line.strip_edges())
	var bad_ends: Array = []
	var to_check: Array = (expected + ["checkpoint"]) if not expected.is_empty() else []     # the checkpoint runs first in every pass
	for nm in to_check:
		var end = ends.get(nm, null)
		if not FileAccess.file_exists(FOLDER + "/" + nm + ".txt"):
			bad_ends.append("%s: no file (the read never started or never wrote)" % nm)
		elif end == null or not str(end) in ["ok", ""]:
			bad_ends.append("%s: %s" % [nm, _end_words(end, deadline)])
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
	_pass_rows(rows, full)
	_ladder_rows(rows, full, reads.filter(func(b): return str(b.get("element", "")) != ""))
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
	_feel_rows(rows, reads.filter(func(b): return str(b.get("element", "")) != "" and b.has("feel")))
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
		rows.append(["The plain floor", "every read of a plain build beats the Quartermaster by hour %.0f (a plain read ends at him, 22 Oct: its rows above are to there)" % PLAIN_BY, ("every read (latest %s)" % _hours(times.max())) if stuck.is_empty() else "stuck: " + ", ".join(stuck), stuck.is_empty()])
	# build parity: from the one checkpoint, the same spell, every build's reach gained against the best's
	if not parity.is_empty():
		var ok_p: Array = parity.filter(func(pp): return not pp.has("error"))
		# two reads a build (25 Oct, the second review: one death decided a 4 h read): judged on their mean
		var by_b: Dictionary = {}
		for pp in ok_p:
			if not by_b.has(pp["build"]):
				by_b[pp["build"]] = []
			by_b[pp["build"]].append(float(pp.get("reach_gain", 0)))
		var mean_g: Dictionary = {}
		for bn in by_b:
			var tot := 0.0
			for g in by_b[bn]:
				tot += g
			mean_g[bn] = tot / float(by_b[bn].size())
		var best_g: int = int(round(mean_g.values().max())) if not mean_g.is_empty() else 0
		var behind: Array = []
		for bn in mean_g:
			if float(mean_g[bn]) < PARITY_BAND * best_g:
				behind.append("%s +%d%s" % [bn, int(round(mean_g[bn])), "" if by_b[bn].size() < 2 else " (%s)" % ", ".join(by_b[bn].map(func(g): return "+%d" % int(g)))])
		for pp in ok_p:
			if pp.get("cut_short", false):
				behind.append("%s cut short at %.1f h" % [pp["build"], float(pp.get("played_h", 0.0))])
		rows.append(["P. Build parity", "from the Radio's checkpoint, %.0f h each: every build's reach gained, the mean of its reads, at least %.0f%% of the best's (+%d)" % [float(ok_p[0].get("hours", 0.0)) if not ok_p.is_empty() else 0.0, PARITY_BAND * 100.0, best_g],
			("every build" if behind.is_empty() else "behind: " + ", ".join(behind)) + ("" if ok_p.size() == parity.size() else " (%d reads gave no figures: see the table)" % (parity.size() - ok_p.size())), behind.is_empty() and ok_p.size() == parity.size() and best_g > 0])
	# shown, not judged: the playtest's (deaths, wounds) - the bot doesn't take a player's risks
	var shown: Array = []
	for bd in full:
		var every: float = (float(bd["runs"]) / float(bd["bails"])) if int(bd.get("bails", 0)) > 0 else 999.0
		var wnd: float = (float(bd["wounded_runs"]) / float(bd["runs"])) if int(bd["runs"]) > 0 else 0.0
		shown.append("%s: bails one in %s, wounded %.0f%%" % [bd["build"], ("%.0f" % every) if every < 999.0 else "never", wnd * 100.0])
	rows.append(["Deaths and wounds (shown)", "the bails and wounds a build", "; ".join(shown), null])
	var reds := 0
	var reds_by := {"design": 0, "bot timing": 0, "bot play": 0}
	for r in rows:
		if r[3] is bool and not r[3]:
			reds += 1
			reds_by[_kind(str(r[0]))] += 1
	# the gates nothing could judge (25 Oct, the tools review), named in the header; a "(shown)" row is never judged
	var unjudged: Array = []
	for r in rows:
		if r[3] == null and not str(r[0]).contains("(shown)"):
			var why := "nothing to read"
			for k in UNJUDGED_WHY:
				if str(r[0]).begins_with(k):
					why = UNJUDGED_WHY[k]
			unjudged.append("%s: %s" % [r[0], why])
	# the commit the pass ran on (25 Oct, the tools review: balance.bat wrote it and nothing read it)
	var commit := FileAccess.get_file_as_string(FOLDER + "/commit.log").strip_edges().trim_prefix("The pass on ")
	var out: Array = []
	out.append("# Balance summary")
	out.append("")
	out.append("Written %s by tools/balance_summary.gd from %d reads of %d builds (%d element, %d plain)%s, on commit %s. %s%s" % [
		Time.get_datetime_string_from_system(false, true), reads.size(), full.size() + plains.size(), full.size(), plains.size(), " and the probe" if not probe.is_empty() else " (no probe)",
		commit if commit != "" else "unknown (no pass/commit.log)",
		("%d RED: %d design, %d bot timing, %d bot play." % [reds, reds_by["design"], reds_by["bot timing"], reds_by["bot play"]]) if reds > 0 else "No reds.",
		(" %d not judged (%s)." % [unjudged.size(), "; ".join(unjudged)]) if not unjudged.is_empty() else ""])
	var missing: Array = []
	for b in builds:
		if b.get("missing", false):
			missing.append("%s (%s)" % [b["build"], _end_words(ends.get(b["build"], null), deadline)])
	if not missing.is_empty():
		out.append("")
		out.append("No GATES line in: " + ", ".join(missing) + "; see its .txt.")
	if not bad_ends.is_empty():
		out.append("")
		out.append("Reads that didn't finish ok: " + "; ".join(bad_ends) + ".")
	if expected.is_empty():
		out.append("")
		out.append("No pass/expected.txt (a pass from before 25 Oct): a read that never wrote can't be named.")
	out.append("")
	out.append("| Gate | Kind | Green when | Read | |")
	out.append("| --- | --- | --- | --- | --- |")
	for r in rows:
		out.append("| %s | %s | %s | %s | %s |" % [r[0], _kind(str(r[0])), r[1], r[2], "—" if r[3] == null else ("GREEN" if r[3] else "RED")])
	var head := out.size()
	out.append_array(broken_table(broken))
	out.append("")
	out.append("## The builds")
	out.append("")
	out.append("| Build | Hours | Manager | Quartermaster (level) | Level 30 | Level 50 | Radio | Signal gap / reach gap | Story | Reach | Level | Runs | Bails | Wounded | Into gang 3 (gone by 5) | Cash | Scrap (crafts/h) | Tempers | Odds by tier | Kit |")
	out.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
	for b in reads:
		var wnd: float = (float(b["wounded_runs"]) / float(b["runs"])) if int(b["runs"]) > 0 else 0.0
		var dearest_b := float(b.get("dearest_build", 0))
		var crafts_b: float = (float(b.get("scrap_per_h", 0.0)) / dearest_b) if dearest_b > 0.0 else 0.0
		var odds: Array = []
		for o in b.get("odds", []):
			odds.append("T%d %.0f%%" % [int(o[0]), float(o[1]) * 100.0])
		out.append("| %s | %.1f (%.0f s wall) | %s | %s (%d) | %s | %s | %s | %s / %s | %s | %d | %d | %d | %d | %.0f%% | %d (%d) | %d | %d (%.1f) | %s | %s | %s |" % [
			b["build"], float(b.get("elapsed_h", b["hours"])), float(b.get("wall_s", 0)), _hours(float(b.get("manager_at", -1.0))),
			_hours(float(b.get("qm_at", -1.0))), int(b.get("level_at_qm", -1)), _hours(float(b.get("lv30_at", -1.0))), _hours(float(b.get("lv50_at", -1.0))),
			_hours(float(b.get("radio_at", -1.0))), _mins(float(b.get("signal_gap_h", -1.0))), _mins(float(b.get("reach_gap_h", -1.0))), _hours(float(b.get("story_at", -1.0))),
			int(b.get("reach", 0)), int(b.get("level", 0)), int(b["runs"]), int(b.get("bails", 0)), wnd * 100.0, int(b.get("gang3_runs", 0)), int(b.get("left_by5", 0)),
			int(b["cash_end"]), int(b["scrap_end"]), crafts_b, str(int(b["tempers"])) if b.has("tempers") else "-", " ".join(odds), str(b.get("kit", ""))])     # the Bench's tempers (25 Oct)
	out.append("")
	if reads.any(func(b): return b.get("one_save", false)):
		out.append("The one save's classes (25 Oct): each read from the Poacher, the target build when its class opened, the crew's swaps after.")
		out.append("")
		for b in reads:
			var route: Array = b.get("route", []).map(func(x): return "%.1f h %s" % [float(x[0]), str(x[1])])
			out.append("- %s: %s" % [b["build"], "; ".join(route) if not route.is_empty() else "the Poacher throughout"])
		out.append("")
	if not parity.is_empty():
		out.append("## Build parity")
		out.append("")
		out.append("| Build | From | Reach | Level | Damage | Runs | Deaths | Signals won | Kit |")
		out.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- |")
		var ps: Array = parity.duplicate()
		ps.sort_custom(func(a, b): return int(a.get("reach_gain", 0)) > int(b.get("reach_gain", 0)))
		for pp in ps:
			if pp.has("error"):
				out.append("| %s | %s | | | | | | | |" % [pp["build"], pp["error"]])
				continue
			out.append("| %s | hour %.1f | %d to %d (+%d) | %d to %d | %.0f to %.0f | %d | %d | %d of %d | %s |" % [pp["build"], float(pp.get("from_h", 0.0)), int(pp["reach0"]), int(pp["reach1"]), int(pp["reach_gain"]),
				int(pp["level0"]), int(pp["level1"]), float(pp["dps0"]), float(pp["dps1"]), int(pp["runs"]), int(pp["deaths"]), int(pp["signals_won"]), int(pp["signals_run"]), str(pp.get("kit", ""))])
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
			var parts: Array = []           # the tidy's parts (22 Oct), the biggest first
			var tp: Dictionary = p.get("tidy_parts", {})
			var keys: Array = tp.keys()
			keys.sort_custom(func(x, y): return int(tp[x]) > int(tp[y]))
			for k in keys:
				if int(tp[k]) > 0:
					parts.append("%s %d" % [k, int(tp[k])])
			out.append("| %s | %d s | %d s (%d reads of %d calls: %d dry runs, %s dry ticks, snapshots %d s) | %d s (%s) | %d s%s | %d s | %d s |" % [
				b["build"], wall, int(p["surv_s"]) - int(p["ladder_s"]), int(p["surv_reads"]), int(p["surv_calls"]), int(p["dry_runs"]), _thousands(int(p["dry_ticks"])), int(p["snap_s"]),
				int(p["real_s"]), _thousands(int(p["real_ticks"])), int(p["tidy_s"]), (" (" + ", ".join(parts) + ")") if not parts.is_empty() else "", int(p["ladder_s"]), rest])
		out.append("")
	var f := FileAccess.open(SUMMARY, FileAccess.WRITE)
	f.store_string("\n".join(out))
	f.close()
	for k in range(head):
		print(out[k])
	print("-> docs/balance/summary.md")
	quit(0)


## How it felt (19 Oct, tools/feel_gates.gd): the gates a playtest is judged by, on every element read - green when
## every read is, the worst read shown. playtest.md judges Matt's record by the same.
func _feel_rows(rows: Array, el_reads: Array) -> void:
	if el_reads.is_empty():
		return
	var per: Array = el_reads.map(func(b): return Feel.rows(b["feel"]))
	for k in range(per[0].size()):
		var greens := 0
		var judged := 0
		var worst := ""
		for j in range(per.size()):
			var r: Array = per[j][k]
			if r[3] == null:
				continue
			judged += 1
			if r[3]:
				greens += 1
			elif worst == "":
				worst = "%s: %s" % [el_reads[j]["build"], r[2]]
		rows.append([per[0][k][0] + " (as played)", per[0][k][1], ("%d of %d reads green" % [greens, judged]) + ((" · " + worst) if worst != "" else ""), Feel._judged(judged > 0, greens == judged)])


## The pass's gates (20 Oct): deaths and wounds, the odds at the gate, the lorry, the endgame's stall, the signals.
func _pass_rows(rows: Array, full: Array) -> void:
	if full.is_empty():
		return
	var off: Array = []
	var all_t: Array = []
	var old_reads := false
	for bd in full:
		# the campaign's runs alone, a bail (left under a quarter HP) counted as a death (25 Oct, Matt; the tools review: the
		# bails are the bot's near-deaths); a read from before then has the whole read's deaths only, and says so
		var campaign: bool = bd.has("campaign_runs")
		old_reads = old_reads or not campaign
		var runs: int = int(bd.get("campaign_runs", bd.get("runs", 0)))
		var losses: int = int(bd.get("campaign_deaths", 0)) + int(bd.get("campaign_bails", 0)) if campaign else int(bd.get("deaths", 0))
		var every: float = float(runs) / float(losses) if losses > 0 else INF
		var fd: float = float(bd.get("first_death_at", -1.0))
		var fb: float = float(bd.get("first_bail_at", -1.0))
		all_t.append("%s 1 in %s (%d deaths, %d bails of %d runs), first death %s, first bail %s" % [bd["build"], ("%.0f" % every) if not is_inf(every) else "never",
			int(bd.get("campaign_deaths", bd.get("deaths", 0))), int(bd.get("campaign_bails", 0)), runs, _hours(fd), _hours(fb)])
		if is_inf(every) or every < DEATH_EVERY[0] or every > DEATH_EVERY[1] or fd < 0.0 or fd > FIRST_DEATH_BY * BOT_PACE:
			off.append(all_t[-1])
	rows.append(["P1. Deaths", "in the campaign (to the Quartermaster: past level 50 a death starts again at level 1 by design), a death or a bail (left under a quarter HP) one run in %.0f-%.0f; the first death by %.1f h (bot)" % [DEATH_EVERY[0], DEATH_EVERY[1], FIRST_DEATH_BY * BOT_PACE],
		(("off: " + "; ".join(off)) if not off.is_empty() else "every build: " + "; ".join(all_t)) + (" (reads from before 25 Oct: their whole read's deaths, no bails)" if old_reads else ""), off.is_empty()])
	off = []
	all_t = []
	for bd in full:
		var runs: int = int(bd.get("runs", 0))
		var w: float = float(bd.get("wounded_runs", 0)) / float(runs) if runs > 0 else 0.0
		all_t.append("%s %.0f%%" % [bd["build"], w * 100.0])
		if w < WOUNDED[0] or w > WOUNDED[1]:
			off.append(all_t[-1])
	rows.append(["P2. Wounds", "%.0f-%.0f%% of runs wounded" % [WOUNDED[0] * 100.0, WOUNDED[1] * 100.0], ("off: " + ", ".join(off)) if not off.is_empty() else "every build: " + ", ".join(all_t), off.is_empty()])
	# judged on the first clears and the heads not yet beaten (25 Oct, Matt; the tools review: the bot farms at PUSH, so
	# every farm run reads 92-100% by construction): the runs it takes at a person's odds, pooled; the farm's shown
	var firsts: Array = []
	var meds: Array = []
	for bd in full:
		var fo: Array = bd.get("first_odds", [])
		firsts.append_array(fo)
		if not fo.is_empty():
			meds.append(_median(fo))
	var farms: Array = full.map(func(bd): return float(bd.get("farm_odds_median", -1.0))).filter(func(v): return v >= 0.0)
	var mo: float = _median(firsts) if not firsts.is_empty() else -1.0
	var p3: Variant = null                   # unjudged with none recorded
	if not firsts.is_empty():
		p3 = mo >= ODDS_MED[0] and mo <= ODDS_MED[1]
	rows.append(["P3. Odds at the gate", "the median first clear and head (a site never cleared, a head not yet beaten) went in at %.0f-%.0f%%; the farm's runs shown" % [ODDS_MED[0] * 100.0, ODDS_MED[1] * 100.0],
		("median %.0f%% of %d runs (builds %.0f%% to %.0f%%)" % [mo * 100.0, firsts.size(), meds.min() * 100.0, meds.max() * 100.0] if not firsts.is_empty() else "no first clears or heads recorded (a read from before 25 Oct)")
		+ ("; the farm's median %.0f%% (builds %.0f%% to %.0f%%)" % [_median(farms) * 100.0, farms.min() * 100.0, farms.max() * 100.0] if not farms.is_empty() else ""), p3])
	var lv: Array = []
	var never: Array = []
	for bd in full:
		if float(bd.get("lorry_at", -1.0)) >= 0.0:
			lv.append(float(bd["lorry_at"]))
		else:
			never.append(bd["build"])
	var ml: float = _median(lv + never.map(func(_b): return INF)) if not (lv.is_empty() and never.is_empty()) else INF
	rows.append(["P4. The lorry", "beaten at %.1f-%.1f h, the element builds' median (bot)" % [LORRY[0], LORRY[1]], "median %s%s" % [_hours(-1.0 if is_inf(ml) else ml), ("; never: " + ", ".join(never)) if not never.is_empty() else ""], not is_inf(ml) and ml >= LORRY[0] and ml <= LORRY[1]])
	off = []
	all_t = []
	for bd in full:
		var st: float = float(bd.get("reach_stand_h", -1.0))
		all_t.append("%s %s" % [bd["build"], _hours(st)])
		if st < 0.0 or st > REACH_STAND:
			off.append(all_t[-1])
	rows.append(["P5. The endgame's stall", "the reach never stands more than %.1f h, the Radio's opening to the first move (or the read's end)" % REACH_STAND, ("off: " + ", ".join(off)) if not off.is_empty() else "every build: " + ", ".join(all_t), off.is_empty()])
	var fa := [0, 0]
	var fu := [0, 0]
	for bd in full:
		for k in [0, 1]:
			fa[k] += int(bd.get("faint", [0, 0])[k])
			fu[k] += int(bd.get("full_at_reach", [0, 0])[k])
	var fa_r: float = float(fa[1]) / float(fa[0]) if fa[0] > 0 else -1.0
	var fu_r: float = float(fu[1]) / float(fu[0]) if fu[0] > 0 else -1.0
	# a 0 of 0 is no read, not a red (25 Oct, the tools review): the part with none is shown and left out of the verdict
	var fa_words: String = ("faint %d of %d (%.0f%%)" % [fa[1], fa[0], fa_r * 100.0]) if fa[0] > 0 else "no faint signals run"
	var fu_words: String = ("full at the reach %d of %d (%.0f%%)" % [fu[1], fu[0], fu_r * 100.0]) if fu[0] > 0 else "no full signals at the reach run"
	var p6 = null if fa[0] == 0 and fu[0] == 0 else ((fa[0] == 0 or fa_r >= FAINT_WON) and (fu[0] == 0 or (fu_r >= FULL_WON[0] and fu_r <= FULL_WON[1])))
	rows.append(["P6. The signals", "faint won %.0f%% or more; full at the reach won %.0f-%.0f%%" % [FAINT_WON * 100.0, FULL_WON[0] * 100.0, FULL_WON[1] * 100.0], "%s; %s" % [fa_words, fu_words], p6])


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
	# 14 and 15 (17 Oct, Matt's playtest: the Parade at level 1-2 dropping level 4 gear, the Outskirts pointless)
	var off_sites: Array = []
	var site_words: Array = []
	for i in range(Data.OUTSKIRTS_SITES + 1, Data.TIERS.size()):     # the Parade on: the Outskirts' and the Streets' gear is level 1
		var lvs: Array = []
		for bd in full:
			var fl: Dictionary = bd.get("first_clear_lv", {})
			if fl.has(str(i)):
				lvs.append(float(fl[str(i)]))
		var wear: int = Sim.wear_of(Sim.lv_at(i, 1))
		if lvs.is_empty():
			off_sites.append("%s never" % Data.TIERS[i]["name"])
			continue
		var med: int = int(_median(lvs))
		site_words.append("%s %d/%d" % [str(Data.TIERS[i]["name"]).replace("The ", ""), med, wear])
		if med < wear - SITE_LEVEL_UNDER or med > wear + SITE_LEVEL_OVER:
			off_sites.append("%s %d (gear %d)" % [Data.TIERS[i]["name"], med, wear])
	rows.append(["16. Levels against the sites", "at each site's first clear from the Parade on, the median build within %d under and %d over the level to wear its gear" % [SITE_LEVEL_UNDER, SITE_LEVEL_OVER],
		(("off: " + ", ".join(off_sites) + " · ") if not off_sites.is_empty() else "") + "level/gear: " + ", ".join(site_words), off_sites.is_empty()])
	var gks: Array = full.filter(func(bd): return float(bd.get("gk_at", -1.0)) >= 0.0).map(func(bd): return float(bd["gk_at"]))
	var gk_lvs: Array = full.filter(func(bd): return int(bd.get("level_at_gk", -1)) >= 0).map(func(bd): return float(bd["level_at_gk"]))
	var gk_med: float = _median(gks) if gks.size() == full.size() and not gks.is_empty() else -1.0
	var gk_lv: int = int(_median(gk_lvs)) if not gk_lvs.is_empty() else -1
	# to two places (25 Oct, the tools review: a median of 0.25-0.29 h printed "0.3 h" against a 0.3 floor and read red)
	rows.append(["17. The Outskirts", "the Gamekeeper beaten at %.2f-%.2f h, the median build, at level %d or more (bot, %.2f of a hand)" % [GK[0], GK[1], GK_LEVEL, BOT_PACE],
		"median %s at level %d (%s to %s)" % [_hours2(gk_med), gk_lv, _hours2(gks.min() if not gks.is_empty() else -1.0), _hours2(gks.max() if not gks.is_empty() else -1.0)],
		gk_med >= GK[0] and gk_med <= GK[1] and gk_lv >= GK_LEVEL])


## Gates 6-8: the Radio's ladder, Kev's story, retirement.
func _ladder_rows(rows: Array, full: Array, el_reads: Array) -> void:
	if full.is_empty():
		return
	var off: Array = []
	var all_t: Array = []
	for bd in full:
		var sg := float(bd.get("signal_gap_h", -1.0))
		var rg := float(bd.get("reach_gap_h", -1.0))
		var rr := float(bd.get("reach_rate", -1.0))
		all_t.append("%s %s/%s/%.1f an hour" % [bd["build"], _mins(sg), _mins(rg), rr])
		if float(bd.get("radio_at", -1.0)) >= LADDER_TO:
			off.append("%s: the Radio opened at %s, after hour %.0f" % [bd["build"], _hours(float(bd["radio_at"])), LADDER_TO])
			continue
		if sg < 0.0 or sg > SIGNAL_GAP + 0.001 or rr < REACH_RATE - 0.001:
			off.append("%s: signals %s, %.1f an hour" % [bd["build"], _mins(sg), rr])
	# the reach's longest stretch on the median read of them all (Matt, 16 Oct: the spread is read to read, not build to build)
	var stretches: Array = el_reads.map(func(g): return float(g.get("reach_gap_h", -1.0))).map(func(v): return INF if v < 0.0 else v)
	var med_rg: float = _median(stretches) if not stretches.is_empty() else INF
	if med_rg > REACH_GAP + 0.001:
		off.append("the reach's longest stretch on the median read %s (over %.0f h)" % [_mins(-1.0 if is_inf(med_rg) else med_rg), REACH_GAP])
	rows.append(["6. The Radio's ladder", "from the Radio's opening to hour %.0f, every build: a signal at least every %d min (the longest stretch) and the reach %.0f level an hour or better on average; the median read never %.0f h without a level" % [LADDER_TO, int(SIGNAL_GAP * 60.0), REACH_RATE, REACH_GAP],
		("off: " + "; ".join(off)) if not off.is_empty() else "every build (signals/reach longest/reach an hour): %s; the median read's longest %s" % [", ".join(all_t), _mins(med_rg)], off.is_empty()])
	var late: Array = []
	for bd in full:
		var h := float(bd.get("story_at", -1.0))
		if h < 0.0 or h > STORY_BY:
			late.append("%s %s" % [bd["build"], _hours(h)])
	rows.append(["7. Kev's story", "the three beats done by hour %.0f" % STORY_BY, ("late: " + ", ".join(late)) if not late.is_empty() else "every build", late.is_empty()])
	# level 50 by the median of every element read, a never counted later than any, and no read before LV50_FLOOR
	# (Matt, 16 Oct: the same build lands either side of the window read to read)
	var short: Array = el_reads.filter(func(g): return float(g.get("lv50_at", -1.0)) < 0.0 and float(g.get("elapsed_h", g["hours"])) < LV50[1])
	var at50: Array = el_reads.map(func(g): return float(g.get("lv50_at", -1.0))).map(func(v): return INF if v < 0.0 else v)
	var med50: float = _median(at50) if not at50.is_empty() else INF
	var early: Array = el_reads.filter(func(g): return float(g.get("lv50_at", -1.0)) >= 0.0 and float(g["lv50_at"]) < LV50_FLOOR).map(func(g): return "%s %s" % [g["build"], _hours(float(g["lv50_at"]))])
	var nevers: int = at50.filter(func(v): return is_inf(v)).size()
	var ok50: Variant = null                 # unread when the reads were short
	if short.is_empty():
		ok50 = med50 >= LV50[0] and med50 <= LV50[1] and early.is_empty()
	var t50: String = "the median read %s (%d of %d reads never)" % [_hours(-1.0 if is_inf(med50) else med50), nevers, at50.size()]
	if not early.is_empty():
		t50 += "; before %.0f h: %s" % [LV50_FLOOR, ", ".join(early)]
	if not short.is_empty():
		t50 += " (reads shorter than %.0f h: not judged)" % LV50[1]
	rows.append(["8. Retirement", "level 50 on the median element read not before hour %.0f and by hour %.0f, and no read before hour %.0f" % [LV50[0], LV50[1], LV50_FLOOR], t50, ok50])


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
	var most_s := 0.0
	for bd in full:
		# the whole read's rate, as the cash's (the reviewer: the first sixteen hours' under-read a deep kit's scrap)
		var per_hs: float = (float(bd.get("scrap_end", 0)) + float(bd.get("scrap_spent", 0))) / maxf(0.01, float(bd.get("elapsed_h", 0.0)))
		if per_hs <= 0.0:
			if int(bd.get("scrap_end", 0)) > 0:
				off.append("%s holds %d scrap and earned none" % [bd["build"], int(bd.get("scrap_end", 0))])
			continue
		var held_s: float = float(bd.get("scrap_end", 0)) / per_hs
		most_s = maxf(most_s, held_s)
		if held_s > SCRAP_HOURS:
			off.append("%s holds %d scrap, %.1f hours' scrap" % [bd["build"], int(bd.get("scrap_end", 0)), held_s])
	rows.append(["15. Scrap", "scrap in hand at the end no more than %.0f hours' scrap income (the tempers spend it)" % SCRAP_HOURS, "; ".join(off) if not off.is_empty() else "every build under (most %.1f)" % most_s, off.is_empty()])
	# the Issue and the County (25 Oct): the Issuer beaten and the town on fiat by the read's end on most builds; how far
	# into the County each got, and the fiat's state, for the read
	var issued_n := 0
	var bits: Array = []
	for bd in full:
		var at: float = float(bd.get("issue_at", -1.0))
		if at >= 0.0:
			issued_n += 1
		bits.append("%s %s, County %d/12, %d issued" % [bd["build"], ("on fiat at %.1f h" % at) if at >= 0.0 else "no Issue", int(bd.get("county_taken", 0)), int(bd.get("issued_bought", 0))])
	rows.append(["18. The Issue", "the Issuer beaten and the town on fiat by the read's end, most builds (the County's progress read alongside)", "; ".join(bits), issued_n * 2 > full.size()])


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
	for key in ["bank_at", "keystone_at", "capstone_at", "lorry_at", "manager_at", "qm_at", "lv30_at", "lv50_at", "radio_at", "story_at", "signal_gap_h", "reach_gap_h", "level_at_qm", "gk_at", "level_at_gk", "odds_median", "farm_odds_median"]:
		if not gs[0].has(key):
			continue
		# by their median, a never counted as later than any (the review, 15 Oct: one read of two that never got there
		# makes the build's never - a gate isn't green on the other read alone); never stays -1, not 505 h
		var vals: Array = gs.map(func(g): return float(g.get(key, -1.0))).map(func(v): return INF if v < 0.0 else v)
		var med: float = _median(vals)
		m[key] = -1.0 if is_inf(med) else snappedf(med, 0.01)
	# the reach's pace (gate 6): a read whose Radio never opened by hour 12 makes the build's never; else the median
	var rates: Array = gs.map(func(g): return float(g.get("reach_rate", -1.0)))
	m["reach_rate"] = -1.0 if rates.any(func(v): return v < 0.0) else snappedf(_median(rates), 0.01)
	for key in ["cash_end", "scrap_end", "scrap_spent", "notes_end", "level", "scrap_per_h", "cash_per_h", "bails_per_h", "elapsed_h", "wall_s"]:
		if not gs[0].has(key):
			continue                      # an older read without the key keeps lacking it (the rows read the lack)
		var total := 0.0
		for g in gs:
			total += float(g.get(key, 0))
		m[key] = snappedf(total / gs.size(), 0.01)
	for key in ["runs", "deaths", "wounded_runs", "timeouts", "dry_timeouts", "bails", "moves", "lorries", "gang3_runs", "left_by5", "campaign_runs", "campaign_deaths", "campaign_bails", "tempers"]:
		if not gs[0].has(key) and key in ["timeouts", "dry_timeouts", "campaign_runs", "campaign_deaths", "campaign_bails", "tempers"]:
			continue                      # a read from before the clock (9 Oct) lacks them: the Clock row reads the lack
		var n := 0
		for g in gs:
			n += int(g.get(key, 0))
		m[key] = n
	# a never-more-than gate takes the worst read (the review): the longest stand, the earliest first death; -1 is never
	var stands: Array = gs.map(func(g): return float(g.get("reach_stand_h", -1.0)))
	m["reach_stand_h"] = -1.0 if stands.any(func(v): return v < 0.0) else stands.max()
	var firsts: Array = gs.map(func(g): return float(g.get("first_death_at", -1.0))).filter(func(v): return v >= 0.0)
	m["first_death_at"] = firsts.min() if not firsts.is_empty() else -1.0
	var bails_at: Array = gs.map(func(g): return float(g.get("first_bail_at", -1.0))).filter(func(v): return v >= 0.0)
	m["first_bail_at"] = bails_at.min() if not bails_at.is_empty() else -1.0
	var fo: Array = []                       # P3's runs, every read's (25 Oct)
	for g in gs:
		fo.append_array(g.get("first_odds", []))
	m["first_odds"] = fo
	for key in ["faint", "full_at_reach"]:
		var sum := [0, 0]
		for g in gs:
			var v: Array = g.get(key, [0, 0])
			sum[0] += int(v[0])
			sum[1] += int(v[1])
		m[key] = sum
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
	var fcl := {}
	for g in gs:
		for k in g.get("first_clear_lv", {}):
			if not fcl.has(k):
				fcl[k] = []
			fcl[k].append(float(g["first_clear_lv"][k]))
	var fcm := {}
	for k in fcl:
		fcm[k] = int(_median(fcl[k]))
	m["first_clear_lv"] = fcm
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


func _hours2(v: float) -> String:
	return "never" if v < 0.0 else "%.2f h" % v


## How a read ended, in words, from its .done's word (null for no .done: still going at the deadline, or never ended;
## "" for a bare "done", from before 25 Oct).
static func _end_words(end: Variant, deadline: bool) -> String:
	if end == null:
		return "still going at the five-hour deadline" if deadline else "no .done: it never finished"
	match str(end):
		"ok", "":
			return "it finished"
		"killed-time":
			return "killed: it ran past its minutes"
		"killed-error":
			return "killed: silent after a SCRIPT ERROR"
		"crashed":
			return "crashed: Godot ended with an error"
	return "ended '%s'" % end


## A gate's kind, by its name: "bot timing", "bot play" or "design".
static func _kind(name: String) -> String:
	for g in BOT_PLAY_GATES:
		if name.begins_with(g):
			return "bot play"
	for g in TIMING_GATES:
		if name.begins_with(g):
			return "bot timing"
	return "design"
