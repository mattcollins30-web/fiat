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
const TYPE_OF := {"Poacher": "rifle", "Doorman": "shotgun", "Scrapper": "improvised", "Drifter": "smg"}   # the gun a class builds around


## One mission on the tier the bot would pick, or a minute's rest if it's hurt
## and can't pay the tent. Returns the tier run, or -1 for a rest.
func step(sim) -> int:
	var t := pick_tier(sim)
	if sim.hp < sim.max_hp() * 0.7:
		if not (sim.cash > sim.medic_cost() * 3.0 and sim.treat()):
			sim.advance(60.0)
			return -1
	sim.deploy(t)
	var guard := 0
	while sim.on_mission() and guard < 3000:
		sim.advance(1.0)
		if sim.on_mission() and sim.hp < sim.max_hp() * 0.4 and sim.mission["using"] == null and not sim.first_med().is_empty():
			sim.use_med(sim.first_med()["id"])
		if sim.on_mission() and (sim.hp < sim.max_hp() * 0.25 or (sim.searching() and (sim.pack_used(sim.mission) >= sim.capacity() or sim.mission["patrols"] >= 2))):
			sim.extract_now()
		guard += 1
	return t


## Between missions: fit the best of every slot and mount, spend points, buy
## the camp with £500 to spare, sell spares, buy the one market item that
## beats what's fitted, refill the rig.
func tidy(sim) -> void:
	for s in Data.SLOTS:
		sim.equip_best(s)
	if keystones_first and TYPE_OF.has(sim.cls):
		_hold_the_type(sim, TYPE_OF[sim.cls])
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
	for slot in Data.SOCKET_SLOTS:
		var gun = sim.equipped[slot]
		if gun == null:
			continue
		for mount in gun["attachments"]:
			if not sim.mount_open(mount):
				continue
			var best: Array = sim.attachments_for(mount)
			if best.is_empty():
				continue
			var cur = gun["attachments"][mount]
			if cur == null or Items.score(best[0]) > Items.score(cur):
				sim.fit(slot, best[0]["id"])
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
	for s in ["Primary", "Armour", "Helmet", "Secondary"]:
		var it = sim.equipped[s]
		if it == null:
			continue
		var cost: int = sim.craft_cost(it, "add")
		if cost >= 0 and sim.cash - cost >= 2000.0 and sim.craft(it["id"], "add"):
			bought.append([sim.elapsed, "bench: an affix on the %s for £%d" % [s.to_lower(), cost]])


## The highest tier that reads PUSH or better, stepping a tier's depth back
## down first where it has climbed past that - a player would. If nothing
## reads PUSH, the tier with the best odds, and a full rest before it.
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
	var best := -1
	var best_odds := -1.0
	for i in range(Data.TIERS.size()):
		if not sim.tier_open(i):
			continue
		while sim.depth[i] > 1 and sim.survival(i) < PUSH:
			sim.set_depth(i, sim.depth[i] - 1)
		var odds: float = sim.survival(i)
		if odds >= PUSH:
			best = i
		elif best < 0 and odds > best_odds:
			best_odds = odds
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


## Climb: when a tier reads safe, go a depth deeper on it.
func _climb(sim) -> void:
	for i in range(Data.TIERS.size()):
		if sim.tier_open(i) and sim.depth[i] <= sim.best_depth[i] and sim.survival(i) >= CLIMB:
			sim.set_depth(i, sim.depth[i] + 1)


func _train_tree(sim) -> void:
	var spent := true
	var order: Array = sim.trees()
	if keystones_first and order.size() == 3:
		order = [order[0], order[2], order[1]]
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


## Rounds for the primary: a stack in the rig, two when there's room; bought
## by the box when the stash has none. Spare stacks for other types are sold with the spares.
func _restock_rounds(sim) -> void:
	var gun = sim.equipped["Primary"]
	if gun == null:
		return
	var type: String = Items.ammo_type(gun)
	# rounds for two runs: the gun's rate over two minutes, twice
	var want: int = int(Items.base_of(gun)["rof"] * 120.0 * 2.0)
	if sim.rounds_for(gun) == 0 and not sim.rig_room(1) and sim.med_capacity() > 0:
		sim.leave(sim.rig.back()["id"])     # a dry gun beats a third bandage
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
			return


func _sell_spares(sim) -> void:
	var keep_type: String = TYPE_OF.get(sim.cls, "") if keystones_first else ""
	for it in sim.stash.duplicate():
		if Items.is_medical(it):
			continue
		if Items.is_ammo(it):
			var gun = sim.equipped["Primary"]
			if gun == null or Items.base_of(it)["type"] != Items.ammo_type(gun):
				sim.sell(it)
			continue
		if keep_type != "" and it["slot"] == "Primary" and Items.base_of(it).get("type", "") == keep_type:
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


func _buy_upgrade(sim) -> void:
	var pick := -1
	var gain := 0.0
	for i in range(sim.market.size()):
		var it: Dictionary = sim.market[i]
		if Items.is_attachment(it) or Items.is_medical(it) or Items.is_ammo(it):
			continue
		var cur = sim.equipped[it["slot"]]
		var g: float = Items.score(it) - (Items.score(cur) if cur != null else 0.0)
		if g > gain and sim.cash >= sim.price(it) + 100:
			gain = g
			pick = i
	if pick >= 0:
		sim.buy(pick)
		for s in Data.SLOTS:
			sim.equip_best(s)

