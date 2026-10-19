extends RefCounted
## The gates for how play feels (19 Oct, Matt: "maybe the way we run the balance pass needs some work" - the bot's
## times were green while his playtest reached the Barracks five levels under its gear, wore a third of what dropped,
## took no wound in 26 runs and made more from the Fence's contracts than from running). Read off a chronicle - the
## bot's (tests/balance.gd puts it in its GATES line as "feel") and the player's record (tools/playtest_summary.gd) -
## and judged the same way on both, so a playtest says what the bot missed.
##
## The numbers marked PROPOSED wait on Matt.

const Sim := preload("res://scripts/sim/sim.gd")

const ENTRY_UNDER := 1             # at a site's first clear (the Parade on), no more than a level under its gear's (Matt, 18 Oct: "at worst one ahead")
const ENTRY_OVER := 3              # nor more than three over it (balance_summary's gate 16)
const WEARABLE_MIN := 0.6          # PROPOSED: of the campaign's plain gear finds, the share the runner can wear when it drops
const WOUNDED := [0.05, 0.30]      # of runs, wounded (Matt's, the bot's summary says "judged at Matt's playtest")
const DEATH_EVERY := [10.0, 30.0]  # a death one run in this many (the same)
const DEATHS_FROM := 30            # judged once there are this many runs; fewer, shown
const CONTRACTS_MAX := 0.5         # PROPOSED: the Fence's contracts' tins, at most this share of the runs' tins


## The figures, off a chronicle's lines (the record's dictionaries). A player's away runs (the offline settle) count
## for nothing here; the bot's "away" hours are the same play flagged for pay (bot.gd's AWAY_SHARE), so it counts them.
## Wounds are counted from the Clinic's opening: before it a run can't wound (sim._wound).
static func read(ch: Array, count_away := false) -> Dictionary:
	var f := {"entries": [], "gear": 0, "wearable": 0, "runs": 0, "wound_runs": 0, "wounded": 0, "deaths": 0, "run_cash": 0.0, "contract_cash": 0.0}
	var campaign := true
	var clinic := false
	for e in ch:
		match str(e.get("k", "")):
			"clear":
				if bool(e.get("first", false)) and int(e.get("site_level", 0)) >= 2 and int(e.get("depth", 1)) == 1:
					var yard: int = int(e.get("yard", 1))
					f["entries"].append([("Y%d %s" % [yard, str(e.get("site", ""))]) if yard > 1 else str(e.get("site", "")), int(e.get("lv", 0)), Sim.wear_of(int(e["site_level"]))])
			"open":
				if str(e.get("room", "")) == "clinic":
					clinic = true
			"move":
				campaign = true                 # a new yard's campaign: its gear read again
			"boss":
				if int(e.get("zone", -1)) == 3:
					campaign = false            # the Quartermaster down: the campaign's gear read ends
			"run":
				if e.get("away", false) and not count_away:
					continue
				f["runs"] += 1
				f["run_cash"] += float(e.get("cash", 0.0))
				if clinic:
					f["wound_runs"] += 1
				if str(e.get("outcome", "")) == "Dead":
					f["deaths"] += 1
				elif e.get("wounded", false):
					f["wounded"] += 1
				if campaign and not e.get("signal", false):
					f["gear"] += int(e.get("gear", 0))
					f["wearable"] += int(e.get("gear_wearable", 0))
			"contract":
				if str(e.get("pay", "")) == "cash":
					f["contract_cash"] += float(e.get("amount", 0.0))
	return f


## The rows: [gate, green when, read, true/false, or null when there's too little to judge].
static func rows(f: Dictionary) -> Array:
	var out: Array = []
	var off: Array = []
	var seen: Array = []
	for en in f.get("entries", []):
		seen.append("%s %d/%d" % [en[0], int(en[1]), int(en[2])])
		if int(en[1]) < int(en[2]) - ENTRY_UNDER or int(en[1]) > int(en[2]) + ENTRY_OVER:
			off.append("%s %d (gear %d)" % [en[0], int(en[1]), int(en[2])])
	out.append(["Level on entry", "at each site's first clear from the Parade, within %d under and %d over its gear's level" % [ENTRY_UNDER, ENTRY_OVER],
		(("off: " + ", ".join(off) + " · ") if not off.is_empty() else "") + ("level/gear: " + ", ".join(seen) if not seen.is_empty() else "no first clear yet"),
		_judged(not seen.is_empty(), off.is_empty())])
	var gear: int = int(f.get("gear", 0))
	var share: float = float(f.get("wearable", 0)) / float(gear) if gear > 0 else 0.0
	out.append(["Gear to wear", "%d%% or more of the campaign's plain gear finds wearable as they drop" % roundi(WEARABLE_MIN * 100.0),
		("%d of %d (%d%%)" % [int(f.get("wearable", 0)), gear, roundi(share * 100.0)]) if gear > 0 else "no gear found yet", _judged(gear > 0, share >= WEARABLE_MIN)])
	var runs: int = int(f.get("runs", 0))
	var wr: int = int(f.get("wound_runs", 0))
	var wnd: float = float(f.get("wounded", 0)) / float(wr) if wr > 0 else 0.0
	out.append(["Wounds", "%d-%d%% of runs from the Clinic's opening" % [roundi(WOUNDED[0] * 100.0), roundi(WOUNDED[1] * 100.0)],
		"%d of %d runs (%d%%)" % [int(f.get("wounded", 0)), wr, roundi(wnd * 100.0)], _judged(wr > 0, wnd >= WOUNDED[0] and wnd <= WOUNDED[1])])
	var deaths: int = int(f.get("deaths", 0))
	var every: float = float(runs) / float(deaths) if deaths > 0 else 0.0
	var dead_ok = null
	if runs >= DEATHS_FROM:
		dead_ok = deaths > 0 and every >= DEATH_EVERY[0] and every <= DEATH_EVERY[1]
	out.append(["Deaths", "one run in %d-%d (judged from %d runs)" % [int(DEATH_EVERY[0]), int(DEATH_EVERY[1]), DEATHS_FROM],
		("%d in %d runs: one in %.0f" % [deaths, runs, every]) if deaths > 0 else "none in %d runs" % runs, dead_ok])
	var rc: float = float(f.get("run_cash", 0.0))
	var cc: float = float(f.get("contract_cash", 0.0))
	out.append(["Contracts against runs", "the Fence's contracts' tins at most %d%% of the runs' tins" % roundi(CONTRACTS_MAX * 100.0),
		"contracts %s, runs %s (%d%%)" % [_k(cc), _k(rc), roundi(cc / maxf(rc, 1.0) * 100.0)], _judged(rc > 0.0, cc <= rc * CONTRACTS_MAX)])
	return out


## A gate's verdict: true or false, or null when there's nothing yet to judge.
static func _judged(can: bool, ok: bool) -> Variant:
	if not can:
		return null
	return ok


static func _k(v: float) -> String:
	return ("%.1fk" % (v / 1000.0)) if v >= 1000.0 else "%d" % int(v)
