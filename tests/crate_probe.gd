extends SceneTree
## What a site's search is worth against its fights, crates against the old thinning (13 Oct): per site and depth,
## over many clears, the sell value, tins, notes and scrap from the kills, from the crates, and from the old search
## (crates off, thin_after searches in full and the thinned tail - 0.8, 0.6, 0.4 - the bot's leave at the floor).
const Data := preload("res://scripts/sim/data.gd")
const Sim := preload("res://scripts/sim/sim.gd")
const N := 300
var _v := 0.0
var _n := 0.0
func _drain(sim, m) -> void:
	for it in m["found"]:
		_v += sim.sell_price(it)
		_n += 1.0
	m["found"].clear()                    # the pack never fills: what's found, not what's kept
func _take(sim, m) -> Dictionary:
	_drain(sim, m)
	var out := {"value": _v, "cash": float(m["cash"]), "notes": float(m.get("notes", 0)), "scrap": float(m.get("scrap", 0)), "n": _n}
	_v = 0.0
	_n = 0.0
	return out
func _fresh(sim, i: int) -> Dictionary:
	var t: Dictionary = sim.effective(i)
	var m := {"tier": i, "t": t, "remaining": 0, "target_hp": 0.0, "kills": 0, "found": [], "left": 0, "cash": 0.0, "xp": 0.0, "elapsed": 0.0,
		"cleared": true, "search": 0.0, "searches": 0, "patrol_timer": 0.0, "patrols": 0, "using": null, "meds_used": 0, "fresh": false, "swapped": 0}
	return m
func _add(a: Dictionary, b: Dictionary) -> void:
	for k in b:
		a[k] = float(a.get(k, 0.0)) + float(b[k])
func _init() -> void:
	var sim = Sim.new()
	sim.loot_by_hand = false            # the bot takes what it finds as it goes (13 Oct: the floor is the player's)
	sim.rng.seed = 7
	sim.unlock_all()
	for z in range(sim.bosses_beaten.size()):
		sim.bosses_beaten[z] = true
	sim.best_tier = 11
	print("site d | kills: value n | crates: value tins notes scrap n searches | old: value tins notes scrap n | crates/old value, all-in")
	for i in [1, 3, 5, 7, 8, 10, 11]:
		for d in [1, 4]:
			sim.best_depth[i] = 10
			sim.depth[i] = d
			var kills := {}
			var crates := {}
			var old := {}
			var searches := 0.0
			for r in range(N):
				# the kills: the pool's drops
				var m := _fresh(sim, i)
				var t: Dictionary = m["t"]
				for k in range(int(t["pool"])):
					if sim.rng.randf() < float(t["drop"]):
						sim._find(m, t, true)
						_drain(sim, m)
				_add(kills, _take(sim, m))
				# the crates, every one opened
				m = _fresh(sim, i)
				sim._roll_crates(m, m["t"])
				while not sim.crate_now(m).is_empty():
					sim._search(m, m["t"], sim.search_s(m["t"]))
					_drain(sim, m)
				searches += m["searches"]
				_add(crates, _take(sim, m))
				# the old search: thin_after in full, then the tail at 0.8, 0.6, 0.4
				m = _fresh(sim, i)
				m["crates_off"] = true
				var n_full: int = sim.thin_after(m["t"]) - (Data.THIN_AFTER - 6)
				for s in range(n_full):
					sim._search(m, m["t"], sim.search_s(m["t"]))
					_drain(sim, m)
				var before: Dictionary = _take(sim, m)
				var tail := _fresh(sim, i)
				tail["crates_off"] = true
				for s in range(3):
					sim._search(tail, tail["t"], sim.search_s(tail["t"]))
					_drain(sim, tail)
				var tt: Dictionary = _take(sim, tail)
				for k in tt:
					before[k] += tt[k] * 0.6        # 0.8 + 0.6 + 0.4 of three searches
				_add(old, before)
			var all_new: float = kills["value"] + crates["value"] + crates["cash"]
			var all_old: float = kills["value"] + old["value"] + old["cash"]
			print("%s d%d | %.0f %.1f | %.0f %.0f %.1f %.1f %.1f %.1f | %.0f %.0f %.1f %.1f %.1f | %.2f, %.2f" % [Data.TIERS[i]["name"], d,
				kills["value"] / N, kills["n"] / N, crates["value"] / N, crates["cash"] / N, crates["notes"] / N, crates["scrap"] / N, crates["n"] / N, searches / N,
				old["value"] / N, old["cash"] / N, old["notes"] / N, old["scrap"] / N, old["n"] / N, crates["value"] / maxf(1.0, old["value"]), all_new / maxf(1.0, all_old)])
	quit()
