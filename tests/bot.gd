extends RefCounted
## The bot the balance reader and the peek script share: a pushy player.
## Deploys where survival is at least PUSH, climbs depth where it's CLIMB,
## uses a med under 40% HP, bails at a quarter, leaves after two patrols or a
## full pack; between missions fits the best of everything, trains, buys the
## camp with £500 to spare, sells spares, shops, refills the rig.

const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")

const PUSH := 0.75
const CLIMB := 0.9

var bought: Array = []    # [sim seconds, what]
var keystones_first := false   # train the class trees to their keystones before the yard's
var element := ""              # a build: its tree to the keystone first, its gear held, the bench aimed at it
var last_tier := -1            # the tier of the last run, the one the climb reads
const TYPE_OF := {"Poacher": "rifle", "Doorman": "shotgun", "Scrapper": "improvised", "Drifter": "smg"}   # the gun a class builds around


## One mission on the tier the bot would pick, or a minute's rest if it's hurt
## and can't pay the tent. Returns the tier run, or -1 for a rest.
func step(sim) -> int:
	# patched up first, then the pick: the odds read at full strength, so a
	# boss gets armed when the runner can take him, not refused because he's hurt
	# whole before the pick: treated when the cash is there three times over,
	# rested otherwise; under 70% it waits. Whole every time, the odds read once
	# a kit rather than once a mission (the reader's key carries the HP)
	if sim.hp < sim.max_hp() * 0.7:
		if not (sim.cash > sim.treat_cost() * 3.0 and sim.treat()):
			sim.advance(60.0)
			return -1
	elif sim.needs_treating() and sim.cash > sim.treat_cost() * 3.0:
		sim.treat()                       # the wound seen to on return, when the cash is there (30)
	elif sim.hp < sim.max_hp():
		sim.advance((sim.max_hp() - sim.hp) / maxf(sim.rest_rate(), 0.1))
	var t := pick_tier(sim)
	last_tier = t
	sim.deploy(t)
	var guard := 0
	while sim.on_mission() and guard < 3000:
		sim.advance(1.0)
		if sim.on_mission() and sim.hp < sim.max_hp() * 0.4 and sim.mission["using"] == null and not sim.first_med().is_empty():
			sim.use_med(sim.first_med()["id"])
		if sim.on_mission() and should_leave(sim):
			sim.extract_now()
		guard += 1
	if sim.on_mission():
		sim.extract_now()                 # never back with a run still on: the yard would stand still
	return t


## When the bot leaves a run: under a quarter HP; or with the site cleared,
## the pack full, a second gang in, or the site picked over (its finds down to
## the floor - a Never there runner, whom no gang moves on, leaves on this).
func should_leave(sim) -> bool:
	if not sim.on_mission():
		return false
	if sim.hp < sim.max_hp() * 0.25:
		return true
	if not sim.searching():
		return false
	var m: Dictionary = sim.mission
	return sim.pack_used(m) >= sim.capacity() or m["patrols"] >= 2 or sim.thinning(m, m["t"]) <= Data.THIN_FLOOR


## Between missions: fit the best of every slot and mount, spend points, buy
## the camp with £500 to spare, sell spares, buy the one market item that
## beats what's fitted, refill the rig.
func tidy(sim) -> void:
	for s in Data.SLOTS:
		sim.equip_best(s)
	if keystones_first and TYPE_OF.has(sim.cls):
		_hold_the_type(sim, TYPE_OF[sim.cls])
	if element != "":
		_second_past_for(sim)
		_hold_the_element(sim)
	_climb(sim)
	_train_tree(sim)
	var sinks := [["workshop", sim.can_upgrade_workshop, sim.workshop_cost, sim.upgrade_workshop],
			["stash", sim.can_upgrade_stash, sim.stash_cost, sim.upgrade_stash], ["medic", sim.can_upgrade_medic, sim.medic_cost, sim.upgrade_medic],
			["market", sim.can_upgrade_market, sim.market_cost, sim.upgrade_market], ["comms", sim.can_upgrade_comms, sim.comms_cost, sim.upgrade_comms],
			["generator", sim.can_upgrade_generator, sim.generator_cost, sim.upgrade_generator], ["lookout", sim.can_upgrade_lookout, sim.lookout_cost, sim.upgrade_lookout],
			["kennel", sim.can_upgrade_kennel, sim.kennel_cost, sim.upgrade_kennel]]
	for s in sinks:
		if s[1].call() and sim.cash >= s[2].call() + 500:
			var cost: int = s[2].call()
			s[3].call()
			bought.append([sim.elapsed, "%s for £%d" % [s[0], cost]])
	var slots: Array = Data.SOCKET_SLOTS.duplicate()
	slots.erase("Primary")
	slots.push_front("Primary")              # the primary's sockets before the secondary's
	for slot in slots:
		var gun = sim.equipped[slot]
		if gun == null:
			continue
		for mount in gun["attachments"]:
			if not sim.mount_open(mount):
				continue
			var best: Array = sim.attachments_for(mount, str(Items.base_of(gun).get("type", "")))     # the parts that go on this gun
			if best.is_empty():
				continue
			var cur = gun["attachments"][mount]
			var want: Dictionary = best[0]
			if element != "" and str(mount).begins_with("socket"):
				# the build's own socketable before the best by score
				for a in best:
					if float(Items.base_of(a).get("conv_%s_pct" % element, 0)) > 0.0:
						want = a
						break
				if cur != null and float(Items.base_of(cur).get("conv_%s_pct" % element, 0)) > 0.0:
					continue
			if cur == null or Items.score(want) > Items.score(cur) or (element != "" and not is_same(want, best[0])):
				sim.fit(slot, want["id"])
	_sell_spares(sim)
	_buy_upgrade(sim)
	_restock_meds(sim)
	_endgame(sim)


## The endgame's business: contracts handed in when ready, the map's points
## spent, the mate's unique when the notes are there twice over, the bench
## adding an affix to what's worn when notes are spare.
func _endgame(sim) -> void:
	for k in range(sim.contracts.size()):
		if sim.can_hand_in(k):
			var c: Dictionary = sim.contracts[k]
			# only when the items that go aren't what's worn or the best spare
			var ok := true
			for it in sim.contract_items(c):
				var best: Dictionary = sim.best_in_stash(it["slot"])
				if not best.is_empty() and best["id"] == it["id"] and sim.equipped.get(it["slot"], null) == null:
					ok = false
			if ok:
				var pay: String = sim.contract_pay_words(c)
				sim.hand_in(k)
				bought.append([sim.elapsed, "contract: %s" % pay])
	while sim.atlas_free() > 0:
		var took := false
		for key in ["picked_over", "paid_in_notes", "quiet_roads", "deeper_pockets", "two_of_everything", "word_travels"]:
			if sim.can_rank_atlas(key):
				sim.rank_atlas(key)
				took = true
				break
		if not took:
			break
	if sim.can_buy_mate() and sim.notes >= int(sim.mate["notes"]) * 3:
		var name: String = sim.mate["unique"]
		sim.buy_mate()
		bought.append([sim.elapsed, "the mate: %s" % name])
	# the cash sinks past the campaign: a word called in on the tier it'll run, and
	# the kit insured, while there's ten times the price in hand
	if sim.campaign_done():
		var t: int = pick_tier(sim)
		while sim.can_add_word(t) and sim.cash >= sim.juice_cost(t) * 10:
			var cost: int = sim.juice_cost(t)
			sim.add_word(t, sim.juice_options(t)[0])
			bought.append([sim.elapsed, "word on tier %d for £%d" % [t, cost]])
		if sim.can_insure(t) and sim.cash >= sim.insure_cost(t) * 10 and sim.survival(t) < 0.95:
			sim.set_insure(true)
	# the bench: an affix on what's worn, while the notes stay above the next boss's price
	var floor_notes: int = 0
	for i in range(Data.TIERS.size()):
		floor_notes = maxi(floor_notes, sim.boss_cost(i))
	if element != "":
		_craft_toward(sim)
	for s in ["Primary", "Armour", "Helmet", "Secondary"]:
		var it = sim.equipped[s]
		if it == null:
			continue
		var cost: int = sim.craft_cost(it, "add")
		if cost >= 0 and sim.cash - cost >= 2000.0 and sim.craft(it["id"], "add"):
			bought.append([sim.elapsed, "bench: an affix on the %s for £%d" % [s.to_lower(), cost]])


## The build's bench work on the primary: a socket for the element's
## socketable; an affix added until the element's conversion or increased
## turns up; when the piece is full without one, the rest re-rolled with the
## element's affix locked, or all of it re-rolled - while two grand stays.
func _craft_toward(sim) -> void:
	var it = sim.equipped["Primary"]
	if it == null or it.has("unique"):
		return
	var conv := "conv_%s_pct" % element
	var inc := "%s_pct" % element
	if Items.sockets(it) == 0:
		var c: int = sim.craft_cost(it, "socket")
		if c >= 0 and sim.cash - c >= 2000.0 and sim.craft(it["id"], "socket"):
			bought.append([sim.elapsed, "bench: a socket on the primary for £%d" % c])
	var has_conv := false
	var has_inc := false
	for a in it["affixes"]:
		has_conv = has_conv or a["stat"] == conv
		has_inc = has_inc or a["stat"] == inc
	if has_conv and has_inc:
		return
	var tries := 0
	while tries < 4 and not (has_conv and has_inc):
		tries += 1
		var kind := "add"
		var stat := ""
		if sim.craft_cost(it, "add") < 0:
			# full: re-roll around what's right, or the lot
			kind = "lock" if (has_conv or has_inc) and sim.craft_cost(it, "lock", conv if has_conv else inc) >= 0 else "reroll"
			stat = (conv if has_conv else inc) if kind == "lock" else ""
		var cost: int = sim.craft_cost(it, kind, stat)
		if cost < 0 or sim.cash - cost < 2000.0 or not sim.craft(it["id"], kind, stat):
			return
		bought.append([sim.elapsed, "bench: %s on the primary for £%d, after %s" % [Data.CRAFT[kind]["name"].to_lower(), cost, element]])
		has_conv = false
		has_inc = false
		for a in it["affixes"]:
			has_conv = has_conv or a["stat"] == conv
			has_inc = has_inc or a["stat"] == inc


## The build's gun: the primary in the stash with the most of the element
## behind it - the base's share, its affixes, what's fitted - weighed with its
## score; a plain gun needs to be well ahead to displace one that carries the element.
func _elem_share(it: Dictionary) -> float:
	var stat := "conv_%s_pct" % element
	var s := float(Items.base_of(it).get(stat, 0))
	s += Items.affix_total(it, stat)
	s += Items.fitted_sum(it, stat)
	return s / 100.0


func _elem_score(it: Dictionary) -> float:
	return Items.score(it) * (1.0 + 2.0 * _elem_share(it))


func _hold_the_element(sim) -> void:
	var cur = sim.equipped["Primary"]
	var best := {}
	for it in sim.stash:
		if it["slot"] == "Primary" and (best.is_empty() or _elem_score(it) > _elem_score(best)):
			best = it
	if best.is_empty():
		return
	if cur == null or _elem_score(best) > _elem_score(cur):
		sim.equip_item(best["id"])


## At the second past, a class with the element's affinity when the first
## hasn't: the keystone needs it.
func _second_past_for(sim) -> void:
	if not sim.can_ascend() or sim.cls2 != "" or sim.affinity(element):
		return
	for c in Data.CLASSES:
		if c["name"] != sim.cls and element in Data.AFFINITY.get(c["name"], []):
			if sim.set_second(c["name"]):
				bought.append([sim.elapsed, "the second past: %s, for %s" % [c["name"].to_lower(), element]])
			return


## The highest tier that reads PUSH or better, stepping a tier's depth back
## down first where it has climbed past that - a player would. If nothing
## reads PUSH, the tier with the best odds, and a full rest before it. Past
## the campaign, the site dug deepest, while it reads PUSH at its depth.
## A build keeps its gun type: the best primary of the class's type from the
## stash goes in if it's within 70% of whatever's fitted, so the typed
## notables and the keystone count.
func _hold_the_type(sim, type: String) -> void:
	var cur = sim.equipped["Primary"]
	if cur != null and Items.base_of(cur).get("type", "") == type:
		return
	var best := {}
	for it in sim.stash:
		if it["slot"] == "Primary" and Items.base_of(it).get("type", "") == type and (best.is_empty() or Items.score(it) > Items.score(best)):
			best = it
	if best.is_empty():
		return
	if cur == null or Items.score(best) >= Items.score(cur) * 0.7:
		sim.equip_item(best["id"])


func pick_tier(sim) -> int:
	# from the top down, stopping at the first tier that reads PUSH: each read
	# is the lookout's dry runs, so the tiers under the one it will run go unread
	var best := -1
	var best_odds := -1.0
	# the endgame: past the campaign every site at a depth is the same fight
	# (the curve), the sites differing by what they drop, so a player digs
	# one site; the bot keeps to the one it has dug deepest while it reads PUSH
	if sim.campaign_done():
		var site := -1
		for i in range(Data.TIERS.size()):
			if sim.tier_open(i) and (site < 0 or sim.best_depth[i] >= sim.best_depth[site]):
				site = i
		if site >= 0:
			while sim.depth[site] > 1 and sim.survival(site) < PUSH:
				sim.set_depth(site, sim.depth[site] - 1)
			if sim.survival(site) >= PUSH:
				best = site
	if best < 0:
		for i in range(Data.TIERS.size() - 1, -1, -1):
			if not sim.tier_open(i):
				continue
			while sim.depth[i] > 1 and sim.survival(i) < PUSH:
				sim.set_depth(i, sim.depth[i] - 1)
			var odds: float = sim.survival(i)
			if odds >= PUSH:
				best = i
				break
			if odds >= best_odds:
				best_odds = odds                  # ties to the lower tier: the old fallback was the lowest open tier
				best = i
	best = maxi(best, 0)
	# the zone's boss, once its last site is cleared and the crew's head still
	# stands: armed when the odds hold with them in; past the campaign, when
	# the notes are there
	var b: Dictionary = sim.boss_of(best)
	if not b.is_empty() and sim.best_depth[best] > 0 and (not sim.bosses_beaten[int(b["zone"])] or sim.notes >= sim.boss_cost(best) * 2):
		sim.arm_boss(best, true)
		if sim.survival(best) < PUSH:
			sim.arm_boss(best, false)
	elif not b.is_empty():
		sim.arm_boss(best, false)
	if sim.survival(best) < PUSH:
		sim.advance((sim.max_hp() - sim.hp) / maxf(sim.rest_rate(), 0.1))
	return best


## Climb: when the tier just run reads safe, go a depth deeper on it. The
## tier just run alone: a player digs where they play, and every tier read
## costs the lookout's dry runs.
func _climb(sim) -> void:
	var i := last_tier
	if i >= 0 and sim.tier_open(i) and sim.depth[i] <= sim.best_depth[i] and sim.survival(i) >= CLIMB:
		sim.set_depth(i, sim.depth[i] + 1)


func _train_tree(sim) -> void:
	var spent := true
	var order: Array = sim.trees()
	if keystones_first and order.size() == 3:
		order = [order[0], order[2], order[1]]
	if element != "":
		# the build's tree first, to its keystone and past it; the class's after
		var mine: Array = order.filter(func(t): return t.get("element", "") == element)
		order = mine + order.filter(func(t): return not t.has("element"))
	while sim.points_free() > 0 and spent:
		spent = false
		for b in order:
			var next_id := ""
			for i in range(b["nodes"].size()):
				var id := "%s/%d" % [b["name"], i]
				if not sim.tree.has(id):
					next_id = id
					break
			if next_id == "":
				continue                  # this tree is done; the next
			if sim.can_train(next_id):
				sim.train_node(next_id)
				spent = true
				break
			if keystones_first:
				return                    # save up for it rather than spend elsewhere
			if element != "" and b.get("element", "") == element and sim.points_free() < sim.node_cost(next_id):
				return                    # an off-affinity node at double: save for it


func _restock_meds(sim) -> void:
	_restock_rounds(sim)
	while sim.rig_room(1):
		var took := false
		for it in sim.stash:
			if Items.is_medical(it):
				took = sim.take(it["id"])
				break
		if took:
			continue
		if sim.cash < 200.0 or not sim.buy_med("Bandage"):
			return


## Rounds for both guns: two runs' worth for the primary, one for the
## secondary; bought by the box when the stash has none. A stack in the rig
## for a type neither gun fires goes back to the stash first (a gun swapped
## leaves its old rounds behind), and sells with the spares.
func _restock_rounds(sim) -> void:
	var types: Array = []
	for s in ["Primary", "Secondary"]:
		if sim.equipped[s] != null:
			types.append(Items.ammo_type(sim.equipped[s]))
	for it in sim.rig.duplicate():
		if Items.is_ammo(it) and not (Items.base_of(it)["type"] in types):
			sim.leave(it["id"])
	for pair in [["Primary", 2.0], ["Secondary", 1.0]]:
		var gun = sim.equipped[pair[0]]
		if gun == null or Items.ammo_type(gun) == "none":
			continue
		var type: String = Items.ammo_type(gun)
		# rounds for a run: the gun's rate over two minutes
		var want: int = int(Items.base_of(gun)["rof"] * 120.0 * pair[1])
		if pair[0] == "Primary" and sim.rounds_for(gun) == 0 and not sim.rig_room(1) and sim.med_capacity() > 0:
			sim.leave(sim.rig.back()["id"])     # a dry primary beats a third bandage
		var guard := 0
		while sim.rounds_for(gun) < want and sim.rig_room(1) and guard < 6:
			guard += 1
			var took := false
			for it in sim.stash:
				if Items.is_ammo(it) and Items.base_of(it)["type"] == type:
					took = sim.take(it["id"])
					break
			if took:
				continue
			if not sim.buy_ammo(type):
				if sim.stash_room(1):
					break
				# no room for the box: the cheapest spare goes
				var worst := {}
				for it in sim.stash:
					if Items.is_medical(it) or Items.is_ammo(it) or Items.is_paper(it):
						continue
					if element != "" and Items.is_socketable(it) and float(Items.base_of(it).get("conv_%s_pct" % element, 0)) > 0.0:
						continue
					if worst.is_empty() or it["value"] < worst["value"]:
						worst = it
				if worst.is_empty() or not sim.sell(worst):
					break


func _sell_spares(sim) -> void:
	var keep_type: String = TYPE_OF.get(sim.cls, "") if keystones_first else ""
	# meds: a dozen cells' worth stay, the dearest; the rig can't carry more and they pile up otherwise
	var meds: Array = sim.stash.filter(func(it): return Items.is_medical(it))
	meds.sort_custom(func(a, b): return a["value"] > b["value"])
	var med_cells := 0
	for it in meds:
		med_cells += Items.size(it)
		if med_cells > 12:
			sim.sell(it)
	for it in sim.stash.duplicate():
		if Items.is_medical(it):
			continue
		if Items.is_ammo(it):
			var fired := false
			for g in [sim.equipped["Primary"], sim.equipped["Secondary"]]:
				fired = fired or (g != null and Items.base_of(it)["type"] == Items.ammo_type(g))
			if not fired:
				sim.sell(it)
			continue
		if keep_type != "" and it["slot"] == "Primary" and Items.base_of(it).get("type", "") == keep_type and _best_of_type(sim, keep_type) == it:
			continue                      # the best spare of the class's type stays; the rest of them go
		if element != "" and Items.is_socketable(it) and float(Items.base_of(it).get("conv_%s_pct" % element, 0)) > 0.0:
			continue
		if element != "" and it["slot"] == "Primary":
			var cur = sim.equipped["Primary"]
			if cur == null or _elem_score(it) >= _elem_score(cur) * 0.8:
				continue
		if Items.is_attachment(it):
			# the best three of a mount stay; attachments_for() is sorted best first
			var rank: int = sim.attachments_for(it["mount"]).find(it)
			if rank >= 3:
				sim.sell(it)
			continue
		var best: Dictionary = sim.best_in_stash(it["slot"])
		if best.is_empty() or best["id"] != it["id"]:
			sim.sell(it)


## The best primary of a type in the stash, by score; {} when none.
func _best_of_type(sim, type: String) -> Dictionary:
	var best := {}
	for it in sim.stash:
		if it["slot"] == "Primary" and Items.base_of(it).get("type", "") == type and (best.is_empty() or Items.score(it) > Items.score(best)):
			best = it
	return best


func _buy_upgrade(sim) -> void:
	var pick := -1
	var gain := 0.0
	if element != "":
		for i in range(sim.market.size()):
			var it: Dictionary = sim.market[i]
			if Items.is_socketable(it) and float(Items.base_of(it).get("conv_%s_pct" % element, 0)) > 0.0 and sim.cash >= sim.price(it) + 500 and _socket_wanting(sim) != "":
				sim.buy(i)
				bought.append([sim.elapsed, "%s for £%d" % [it["base"].to_lower(), sim.price(it)]])
				break
	for i in range(sim.market.size()):
		var it: Dictionary = sim.market[i]
		if Items.is_attachment(it) or Items.rig_item(it):
			continue
		var cur = sim.equipped[it["slot"]]
		var g: float = Items.score(it) - (Items.score(cur) if cur != null else 0.0)
		if element != "" and it["slot"] == "Primary":
			g = _elem_score(it) - (_elem_score(cur) if cur != null else 0.0)   # a build weighs its gun its own way
		if g > gain and sim.cash >= sim.price(it) + 100:
			gain = g
			pick = i
	if pick >= 0:
		sim.buy(pick)
		for s in Data.SLOTS:
			sim.equip_best(s)
		if element != "":
			_hold_the_element(sim)


## A worn gun's socket without the element's socketable in it, or "".
func _socket_wanting(sim) -> String:
	for slot in Data.SOCKET_SLOTS:
		var gun = sim.equipped[slot]
		if gun == null:
			continue
		for mount in gun["attachments"]:
			if str(mount).begins_with("socket"):
				var cur = gun["attachments"][mount]
				if cur == null or float(Items.base_of(cur).get("conv_%s_pct" % element, 0)) <= 0.0:
					return mount
	return ""
