extends RefCounted
## Kev's wagers against the odds (BUILD49 U, item 19; Matt: "that menu needs a revamp"): the odds a run there reads
## with a given set of its wagers taken - none ("as you stand"), one alone ("the odds with it") or what's taken - read
## the way the Map's and the Radio's own odds are (sim.survival, sim.signal_odds: item 17's read, the wagers' terms on
## the dry runs), stepped in the shell's frame budget, each read's cache kept here and put back after every step so the
## screens' own reads aren't touched. Read again only when a panel opens or a wager is toggled (epoch).

const Words := preload("res://scripts/sim/words.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")

static var _jobs := {}               # "key|taken|epoch" -> {key, taken, c (the read's cache), o, done}
static var epoch := 0                 # moved when a panel opens or a wager is toggled: the reads start again then, never
                                      # on a tenth of HP (the review: a rest with the panel open re-read five fights a tenth)


## The odds there with `taken` (offer indices) in place of what's taken, as read so far: [odds, settled]. Nothing is run
## here: the read is asked for and the shell steps it in its frame budget (step(), from main._read_odds) - a dry run
## parked at the frame's few ms and taken up in the next, as the Map's and the Radio's own reads are. Only a read run to
## its whole count says settled (the review: the shell's 24-run budget stored a Glasses read's first 24 as the figure).
static func now(_sim, key: String, taken: Array) -> Array:
	var t2: Array = taken.duplicate()
	t2.sort()
	var mk: String = "%s|%s|%d" % [key, str(t2), epoch]
	if not _jobs.has(mk):
		if _jobs.size() > 32:
			_jobs.clear()
		_jobs[mk] = {"key": key, "taken": t2, "c": null, "o": 0.0, "done": false}
	var j: Dictionary = _jobs[mk]
	return [float(j["o"]), bool(j["done"])]


## The reads asked and not yet settled.
static func pending() -> bool:
	for j in _jobs.values():
		if not bool(j["done"]):
			return true
	return false


## A wager panel opened, a wager taken or dropped: read them again.
static func touch() -> void:
	epoch += 1
	_jobs.clear()


## What the reads stand at, for a screen's signature: it shows again as they settle.
static func state() -> String:
	var out := ""
	for j in _jobs.values():
		out += "%d%s" % [int(float(j["o"]) * 100.0), "s" if bool(j["done"]) else "r"]
	return out


## The shell's step (main._read_odds): each unsettled read taken on in turn till the frame's time is up.
static func step(sim) -> void:
	for j in _jobs.values():
		if bool(j["done"]):
			continue
		if sim._odds_time_up():
			return
		_advance(sim, j)


static func _advance(sim, j: Dictionary) -> void:
	var key: String = str(j["key"])
	var held: Dictionary = sim.wagers.get(key, {})
	var had: bool = sim.wagers.has(key)
	var trial: Dictionary = held.duplicate(true) if had else {"seq": 0, "taken": []}
	trial["taken"] = Array(j["taken"]).duplicate()
	sim.wagers[key] = trial
	if key.begins_with("site:"):
		var i: int = int(key.trim_prefix("site:"))
		var home = sim._surv_cache.get(i, null)
		var home_t = sim._odds_tally.get(i, null)
		_put_back(sim._surv_cache, i, j["c"])
		j["o"] = sim.survival(i)
		j["done"] = sim.odds_settled(i)
		j["c"] = sim._surv_cache.get(i, null)
		_put_back(sim._surv_cache, i, home)
		_put_back(sim._odds_tally, i, home_t)
	elif key.begins_with("sig:"):
		var id: int = int(key.trim_prefix("sig:"))
		var k := -1
		for n in range(sim.signals.size()):
			if int(sim.signals[n].get("id", -1)) == id:
				k = n
		if k < 0 or not sim._sig.is_empty():
			j["done"] = k < 0
		else:
			var i: int = int(sim.signal_at(k)["site"])
			var home = sim._sig_odds.get(id, null)
			var home_t = sim._odds_tally.get(i, null)
			_put_back(sim._sig_odds, id, j["c"])
			var r: Array = sim.signal_odds(k)
			j["o"] = float(r[0])
			j["done"] = bool(r[1])
			j["c"] = sim._sig_odds.get(id, null)
			_put_back(sim._sig_odds, id, home)
			_put_back(sim._odds_tally, i, home_t)
	else:
		j["done"] = true
	if had:
		sim.wagers[key] = held
	else:
		sim.wagers.erase(key)


static func _put_back(d: Dictionary, k, v) -> void:
	if v == null:
		d.erase(k)
	else:
		d[k] = v


## What's taken there, as offer indices.
static func taken_of(sim, key: String) -> Array:
	return Array(sim.wagers.get(key, {}).get("taken", [])).duplicate()


## The strip naming what's on there (by Set off on the Map's card and the Radio's): cost for pay, and the odds without
## it beside, long to short; [] when nothing's taken.
static func strip_forms(sim, key: String) -> Array:
	var taken: Array = taken_of(sim, key)
	if taken.is_empty():
		return []
	var offer: Array = sim.wager_offer(key)
	var lines: Array = []
	for k in taken:
		if int(k) < offer.size():
			lines.append(sim.wager_words(offer[int(k)]))
	var U: Dictionary = Words.U49_WAGERS
	var what: String = (U["strip"] if lines.size() == 1 else U["strip_n"]) % " · ".join(lines)
	var w0: Array = now(sim, key, [])
	if not bool(w0[1]):
		return [what, U["strip_short"] % lines.size()]     # the figure without it, once it's read
	return ["%s · %s" % [what, U["without"] % Fmt.pct(float(w0[0]))], what, U["strip_short"] % lines.size()]
