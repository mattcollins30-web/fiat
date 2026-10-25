extends RefCounted
## The bot the balance reader and the peek script share: a pushy player.
## Deploys where survival is at least PUSH, climbs depth where it's CLIMB (once the campaign's done: RUSH, 12 Oct),
## uses a med under 40% HP, bails at a quarter, leaves after two patrols or a
## full pack; between missions fits the best of everything, trains, buys the
## camp with £500 to spare, sells spares, shops, refills the rig.

const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")

const PUSH := 0.88             # the pass (6-7 Oct): at 0.75 the bot bailed under a quarter one run in four, at 0.85 one in eight, at 0.9 one in 33-47 on four builds, against Matt's one in seventeen
const CLIMB := 0.92            # 0.95 read depth pace under one an hour on four builds
const FIRST := 0.65            # a site not yet cleared, or a head not yet beaten, is taken at this (13 Oct, Matt's recorded odds: 17 of 22 runs at 100%, every first clear and head at 0.42-0.83, the median two in three); what's cleared is farmed at PUSH
const CLINIC_SPARE := 2.0      # the Clinic paid whenever its price is in hand this many times over (13 Oct: Matt paid 26-380 a visit and never waited out his HP)
const RUSH := true             # the campaign as a person plays it (12 Oct, Matt's fire Drifter: one run a site, depth 1, straight to the next when it reads PUSH): no climbing until the campaign's done; the endgame climbs as before
const COIN := 0.5             # the pass (20 Oct, the agreed gate: a full signal at the reach about a coin flip): three held and none at PUSH, a full one at the reach is run at this, insured, before one's binned
const LORRY_ODDS := 0.6        # the lorry is taken at better than even, the kit insured (7 Oct)
const LORRY_EVERY := 1200.0    # seconds of the yard's time between reads of the lorry's odds (a convoy read is three long fights a dry run: the seventeenth read ran at a third of the pace)
var lorry_read_at := -1e9      # when the lorry's odds were last read (the yard's clock, which the move keeps)
var lorry_ok := false          # what that read said: the lorry is armed on it without reading again (a pick disarms everything first)

var bought: Array = []    # [sim seconds, what]
var keystones_first := false   # train the class trees to their keystones before the yard's
var element := ""              # a build: its tree to the keystone first, its gear held, the bench aimed at it
var last_tier := -1            # the tier of the last run, the one the climb reads
var cls := ""                  # the class the gate set: put back on the runner after a move (the move unpicks it)
var lorry_at := -1.0           # the hour the first lorry was beaten
var bails := 0                 # runs left under a quarter HP: the deaths a player who pushes on takes (the deaths row)
var _cleared_at := {}           # tier -> the depth its words were last cleared at: none put back there
const TYPE_OF := {"Poacher": "rifle", "Doorman": "shotgun", "Scrapper": "improvised", "Drifter": "smg", "Recruit": "rifle"}   # the gun a class builds around


## One mission on the tier the bot would pick, or a minute's rest if it's hurt
## and can't pay the tent. Returns the tier run, or -1 for a rest.
## The crew (21 Oct, step 7): the reach stood CREW_STAND with nothing to run, another class goes out - a played one
## reading PUSH on a held signal; else the played one CREW_AHEAD levels or more over the one out (a death's level 1
## goes back to the best); else, the one out at the cap, the next not played, at the crew's build for it (CREW_BUILDS;
## the read's own class keeps the read's build). Swaps are free at camp; each class keeps its own tree and kit.
## (The first cut sent a new class out every two hours: five level-1 runners and nobody at the reach.)
const CREW_STAND := 7200.0
const CREW_AHEAD := 5
const CREW_BUILDS := {"Doorman": "bleed", "Drifter": "fire", "Poacher": "frost", "Paramedic": "shock", "Scrapper": "shock", "Recruit": "physical"}     # the Recruit (24 Oct); the Paramedic shock (joints B)
var crew_on := true
var crew_swaps := 0
## The one-save read (25 Oct, the endgame chase step 8: Matt, "effectively a different game" a class): the read starts
## as the Poacher, as a new game does, and takes its target build the moment that class opens; the crew's swaps after.
var target_cls := ""
var target_el := ""
var _target_taken := false
var builds := {}                  # class -> {element, keystones_first} as the bot plays it
var _stood_from := -1.0


func _crew_turn(sim) -> int:
	if target_cls != "" and sim.cls == target_cls and sim.level() < Data.MAX_LEVEL:
		return -1                         # the one save's target plays on till the cap: the Poacher it left doesn't come back over it (the review)
	for name in sim.crew_played():
		if name == sim.cls:
			continue
		for j in range(sim.signals.size()):
			if float(sim.signal_odds_class(j, name)[0]) >= PUSH and _crew_out(sim, name):
				return j                  # the swap carries its odds: the signal it read runs
	var best := ""
	for name in sim.crew_played():
		if name != sim.cls and sim.crew_level(name) >= sim.level() + CREW_AHEAD and (best == "" or sim.crew_level(name) > sim.crew_level(best)):
			best = name
	if best != "" and _crew_out(sim, best):
		return -1                         # the best class back out
	if sim.level() < Data.MAX_LEVEL:
		return -1                         # still growing: no new class yet
	for name in CREW_BUILDS:
		if not (name in sim.crew_played()) and _crew_out(sim, name):
			return -1                     # a new one: the sites first, as any runner
	return -1


func _crew_out(sim, name: String) -> bool:
	if not sim.class_open(name):
		return false                      # shut till its head (or Kev's story): the game's own rule, which set_class leaves to Training
	var from: String = sim.cls
	builds[from] = {"element": element, "keystones_first": keystones_first}     # the class going in keeps its build (the review: the runner's, not the bot's own cls)
	if not sim.set_class(name):
		return false
	cls = name
	var b: Dictionary = builds.get(name, {"element": str(CREW_BUILDS.get(name, "")), "keystones_first": false})
	element = str(b["element"])
	keystones_first = bool(b["keystones_first"])
	lorry_ok = false                      # the lorry's read and the farm were the last runner's (the review)
	lorry_read_at = -1e9
	_farm_at = -1e9
	crew_swaps += 1
	bought.append([sim.elapsed, "crew: %s out for %s (level %d)" % [name, from, sim.level()]])
	return true


func step(sim) -> int:
	sim.loot_by_hand = false                  # the bot takes what it finds as it goes (13 Oct: the floor is the player's)
	if not sim.on_mission() and target_cls != "" and not _target_taken and sim.cls != target_cls and sim.class_open(target_cls):
		builds[target_cls] = {"element": target_el, "keystones_first": false}
		if _crew_out(sim, target_cls):
			_target_taken = true              # the build the read is for, from the hour its class opens
			bought.append([sim.elapsed, "the target: %s as %s, opened" % [target_cls, target_el]])
	if not sim.on_mission():
		pick_skills(sim, sim.front_tier())     # its three, before the odds read the sites (milestone 8, step 3d)
	sim.mythics_on = false                    # a read is never a mythic's (16 Oct, docs/design/mythics.md)
	# patched up first, then the pick: the odds read at full strength, so a
	# boss gets armed when the runner can take him, not refused because he's hurt
	# whole before the pick: treated when the cash is there three times over,
	# rested otherwise; under 70% it waits. Whole every time, the odds read once
	# a kit rather than once a mission (the reader's key carries the HP)
	# the Clinic first, as a person does (13 Oct): treated whenever it's open and the price is there twice over;
	# rested otherwise, and under 70% it waits
	if sim.needs_treating() and sim.room_open("clinic") and sim.cash > sim.treat_cost() * CLINIC_SPARE and sim.treat():
		pass
	elif sim.hp < sim.max_hp() * 0.7:
		sim.advance(60.0)
		return -1
	elif sim.hp < sim.max_hp():
		sim.advance((sim.max_hp() - sim.hp) / maxf(sim.rest_rate(), 0.1))
	# the endgame (15 Oct): the Radio's signals - made when there are papers, run when one reads its odds; else a
	# campaign site farmed for the papers
	var t := -1
	var t0 := Time.get_ticks_usec()
	if sim.campaign_done() and sim.room_open("radio"):
		_make_signals(sim)
		t0 = _lap("step/signals", t0)
		var k := _pick_signal(sim)
		t0 = _lap("step/pick_signal", t0)
		if k >= 0:
			_stood_from = -1.0
		elif crew_on:
			if _stood_from < 0.0:
				_stood_from = sim.elapsed
			elif sim.elapsed - _stood_from >= CREW_STAND:
				_stood_from = -1.0
				k = _crew_turn(sim)
		if k >= 0:
			t = int(sim.signal_at(k)["site"])
			last_tier = -1                    # a signal's site is random: the endgame's tidy reads the farm it'll run next (the review)
			var ins: int = sim.signal_insure_cost(k)
			if ins >= 0 and sim.cash >= ins * 3:
				sim.set_insure(true)
			var sg_lv: int = sim.signal_level(sim.signal_at(k))
			var sg_tags: String = _sig_tags(sim.signal_at(k))
			var sg_odds: float = float(sim.signal_odds(k)[0])
			if not sim.deploy_signal(k):
				sim.set_insure(false)
				t = -1
			else:
				ran_signal = [sg_lv, sg_odds, sim.reach, sg_tags]
	if t < 0:
		t = pick_tier(sim)
		last_tier = t
		t0 = _lap("step/pick_tier", t0)
		sim.deploy(t)
	t0 = _lap("step/deploy", t0)
	var guard := 0
	while sim.on_mission() and guard < 3000:
		sim.advance(1.0)
		if sim.on_mission() and sim.hp < sim.max_hp() * 0.4 and sim.mission["using"] == null and not sim.first_med().is_empty():
			sim.use_med(sim.first_med()["id"])
		if sim.on_mission() and should_leave(sim) and not sim.mission.get("way_out", false):
			if sim.hp < sim.max_hp() * 0.25:
				bails += 1
			sim.get_out()                     # the player's button: before the clear, the way out (10 Oct)
		guard += 1
	if sim.on_mission():
		sim.extract_now()                 # never back with a run still on: the yard would stand still
	_lap("step/run", t0)
	if bool(sim.last_report.get("timed_out", false)) and float(sim.last_report.get("time", -1.0)) >= 0.0 and int(sim.runs_total) != _to_seen:
		_to_seen = int(sim.runs_total)
		bought.append([sim.elapsed, "out of time: tier %d%s, %d of %d down, %d gangs, way out %s, clock used %.0f s" % [int(sim.last_report["tier"]),
			" (a signal)" if not ran_signal.is_empty() else "", int(sim.last_report["kills"]), int(sim.last_report["of"]), int(sim.last_report["patrols"]),
			str(sim.last_report["way_out"]), float(sim.last_report["clock_used"])]])
	if not ran_signal.is_empty():
		bought.append([sim.elapsed, "ran a signal: level %d at %.0f%%, reach %d -> %d%s" % [ran_signal[0], float(ran_signal[1]) * 100.0, ran_signal[2], sim.reach, ran_signal[3]]])
		ran_signal = []
	return t
var ran_signal: Array = []
var _to_seen := -1


## A signal's extras for the log: its site, the head, a convoy, its codes.
func _sig_tags(sg: Dictionary) -> String:
	var out: String = " (site %d" % int(sg.get("site", 0))
	if bool(sg.get("head", false)):
		out += ", head"
	if bool(sg.get("convoy", false)) or bool(sg.get("convoy_fight", false)):
		out += ", convoy"
	if int(sg.get("story", -1)) >= 0:
		out += ", Kev's"
	if not (sg.get("codes", []) as Array).is_empty():
		out += ", codes " + ",".join(PackedStringArray((sg["codes"] as Array).map(func(c): return str(c))))
	return out + ")"


## When the bot leaves a run: under a quarter HP; or with the site cleared,
## the pack full, a second gang in, or the site picked over (its finds down to
## the floor - a Never there runner, whom no gang moves on, leaves on this).
## The bot's three skills (skills.md §3): the best damage skill it has learnt (a signature first, then the dearest),
## the cleanse that clears what site `i` fires (bleed, poison, burn), then a control or defensive skill; what's left
## filled dearest first, a cleanse the site doesn't call for last. Every rule on auto: the bot never presses.
func pick_skills(sim, i: int) -> void:
	var learnt: Array = sim.skills_learnt().filter(func(id): return id != "back_of_the_van" and str(Data.SKILLS[id].get("rule", "")) != "last_stand")     # the bot throws no grenades, and leaves at a quarter HP before a killing hit (the review)
	var rank := func(id) -> float: return (100.0 if Data.SKILLS[id].get("signature", false) else 0.0) + float(Data.SKILLS[id]["cost"])
	var by_rank := func(ids: Array) -> Array:
		var out: Array = ids.duplicate()
		out.sort_custom(func(a, b): return rank.call(a) > rank.call(b) or (rank.call(a) == rank.call(b) and str(a) < str(b)))     # ties by id: the same picks whatever the table's order (the review)
		return out
	var picks: Array = []
	var dmg: Array = by_rank.call(learnt.filter(func(id): return Data.SKILLS[id].get("kind", "") == "damage"))
	if not dmg.is_empty():
		picks.append(dmg[0])
	var fires: Array = []
	if i >= 0:
		for ty in sim.effective(i).get("types", {}):
			if float(sim.effective(i)["types"][ty]) > 0.0:
				fires.append(str(ty))
	var cleanse: Array = by_rank.call(learnt.filter(func(id): return Data.SKILLS[id].get("kind", "") == "cleanse" and Data.SKILLS[id]["fx"].get("clears", []).any(func(ty): return ty in fires)))
	if not cleanse.is_empty():
		picks.append(cleanse[0])
	var guard: Array = by_rank.call(learnt.filter(func(id): return Data.SKILLS[id].get("kind", "") in ["control", "defence"]))
	if not guard.is_empty():
		picks.append(guard[0])
	for pass_i in range(2):
		for id in by_rank.call(learnt):
			if picks.size() >= Data.SKILL_SLOTS:
				break
			if not picks.has(id) and (pass_i == 1 or Data.SKILLS[id].get("kind", "") != "cleanse"):
				picks.append(id)          # a cleanse the site doesn't call for only when nothing else is left
	while picks.size() < Data.SKILL_SLOTS:
		picks.append("")
	sim.skill_slots = picks.slice(0, Data.SKILL_SLOTS)
	sim.skill_auto = [true, true, true]


func should_leave(sim) -> bool:
	if not sim.on_mission():
		return false
	if sim.hp < sim.max_hp() * 0.25:
		return true
	if _clock_short(sim):
		return true
	if not sim.searching():
		return false
	var m: Dictionary = sim.mission
	if m.has("boss") and m["boss"]["alive"]:
		return false                      # a head or the lorry still standing: the run is for him, picked over or not (the eighteenth read left the convoy at 12 of 16 with the pack "full")
	return sim.pack_used(m) >= sim.capacity() or m["patrols"] >= 2 or sim.crates_done(m)


## The clock against the kills (D17): at the rate they've gone down so far, the rest won't before it runs out, and
## there's still time to fight the door's gang - out, as a player does, rather than lose two pieces of kit to it.
func _clock_short(sim) -> bool:
	var m: Dictionary = sim.mission
	if m.get("way_out", false) or m.get("dry", false) or int(m["remaining"]) <= 0 or not m.has("clock") or m.has("boss"):
		return false                      # a head's run is for the head (D24: a Kev's beat cut and run before its head came out lost its papers)
	var used: float = float(m.get("clock_used", 0.0))
	if used < 90.0 or int(m["kills"]) < 4:
		return false                      # the first kills come slow: read the rate once there's one to read
	var rate: float = float(m["kills"]) / used
	var need: float = float(m["remaining"]) / rate
	var door: float = float(sim.door_gang(m["t"])) / rate
	var ck: float = float(m["clock"])
	return ck < need * 1.1 and ck > door * 2.0


## Between missions: fit the best of every slot and mount, spend points, buy
## the camp with £500 to spare, sell spares, buy the one market item that
## beats what's fitted, refill the rig.
var prof := {}                    # where a tidy's wall goes, in microseconds a part (the reader's wall table)
func _lap(key: String, t0: int) -> int:
	var now := Time.get_ticks_usec()
	prof[key] = int(prof.get(key, 0)) + now - t0
	return now


## The fitting, training, selling and shopping once a minute of the camp's time at most (22 Oct, the pass's wall: a
## level-50 build's runs are seconds long, and a tidy after each was half the wall; a player doesn't re-fit every run
## either) - every run while runs are longer than that, and whenever the stash is nearly full, the runner changed or
## the run wounded. The Yard, the meds and the endgame's business every run (the review: the gates read those).
const TIDY_EVERY := 60.0
var _tidied_at := -1e9
var _tidied_runner := ""
func tidy(sim) -> void:
	var t0 := Time.get_ticks_usec()
	_climb(sim)
	_build_yard(sim)
	t0 = _lap("yard", t0)
	var runner: String = "%s/%d" % [sim.cls, sim.operators_lost]
	var hurt: bool = sim.last_report is Dictionary and bool(sim.last_report.get("wounded", false))     # a wound: the kit looked over now
	if sim.elapsed - _tidied_at >= TIDY_EVERY or runner != _tidied_runner or hurt or sim.stash_used() >= sim.stash_cap() * 0.9:
		_tidied_at = sim.elapsed
		_tidied_runner = runner
		_tidy_kit(sim)
	t0 = Time.get_ticks_usec()
	_restock_meds(sim)                    # every run: the rig's meds and the endgame's business (the review: a run out with no meds, a signal waiting)
	_endgame(sim)
	_lap("endgame", t0)


## The kit looked over: the best of everything fitted, the points spent, the mounts, the spares sold, the shop.
func _tidy_kit(sim) -> void:
	var t0 := Time.get_ticks_usec()
	for s in Data.SLOTS:
		sim.equip_best(s)
	if keystones_first and TYPE_OF.has(sim.cls):
		_hold_the_type(sim, TYPE_OF[sim.cls])
	if element != "":
		_hold_the_element(sim)
	t0 = _lap("fit", t0)
	_train_tree(sim)
	t0 = _lap("train", t0)
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
	t0 = _lap("mounts", t0)
	_sell_spares(sim)
	t0 = _lap("sell", t0)
	_buy_upgrade(sim)
	_lap("shop", t0)


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
				if not (it["slot"] in Data.SLOTS):
					continue                      # meds and papers: nothing worn to keep
				var best: Dictionary = sim.best_in_stash(it["slot"])
				if not best.is_empty() and best["id"] == it["id"] and sim.equipped.get(it["slot"], null) == null:
					ok = false
			if ok:
				var pay: String = sim.contract_pay_words(c)
				sim.hand_in(k)
				bought.append([sim.elapsed, "contract: %s" % pay])
	# the rebuild (18 Oct, docs/design/rebuild.md §7): the cheapest place it can build, by the materials it wants
	var cheapest := ""
	var least := 1 << 30
	for r in Data.REBUILDS:
		if sim.can_rebuild(r["key"]):
			var n := 0
			var cost: Dictionary = sim.rebuild_cost(r["key"])
			for k in cost:
				n += int(cost[k])
			if n < least:
				least = n
				cheapest = r["key"]
	if cheapest != "" and sim.rebuild_place(cheapest):
		bought.append([sim.elapsed, "rebuilt %s to rank %d" % [cheapest, sim.rebuild_rank(cheapest)]])
	# the map at thirty-six (7 Oct): a rank a point, the columns in turn, each down its chain
	var col := 0
	while sim.atlas_free() > 0:
		var took := false
		for k in range(3):
			var c: int = (col + k) % 3
			for t in Data.MAP_WEB:
				if int(t["column"]) != c:
					continue
				for nd in t["nodes"]:         # the Map's web (slice 4): the spine first, then each branch with its fillers, as pathed
					if sim.can_rank_atlas(str(nd["key"])):
						sim.rank_atlas(str(nd["key"]))
						took = true
						break
				if took:
					break
			if took:
				col = (c + 1) % 3
				break
		if not took:
			break
	# what the air's nodes set (9 Oct): the standing words the richest-paying known, the filter the stingiest
	for k in range(2):
		if sim.standing_open(k) and (k >= sim.standing.size() or sim.standing[k] == ""):
			var best := ""
			var best_v := 0.0
			for name in sim.words_known():
				if name in sim.standing:
					continue
				var v: float = sim._words_pay([{"w": name, "t": 1}])
				if v > best_v:
					best = name
					best_v = v
			if best != "":
				sim.set_standing(k, best)
	if sim.atlas_rank("clear_air") > 0 and sim.filtered == "":
		var worst := ""
		var worst_v := 1e9
		for name in sim.words_known():
			var v: float = sim._words_pay([{"w": name, "t": 1}])
			if v < worst_v:
				worst = name
				worst_v = v
		sim.set_filtered(worst)
	if sim.lorry_done and lorry_at < 0.0:
		lorry_at = sim.elapsed / 3600.0
	if sim.can_buy_mate() and sim.notes - int(sim.mate["notes"]) >= _notes_kept(sim) and sim.notes >= int(sim.mate["notes"]) * 3:
		var name: String = sim.mate["unique"]
		sim.buy_mate()
		bought.append([sim.elapsed, "the mate: %s" % name])
	# the sinks past the campaign (9 Oct, map juicing): the site it'll run broadcast to its most while the notes
	# hold twice the price over the kept floor, tuned up when the depth grows its room, cleared when its words
	# read it under even odds; and the kit insured, while there's twice the price in hand
	if sim.campaign_done():
		# the tier it'll run: the one just run (8 Oct, the pass at an hour: a full pick here, every site read, and
		# the word it put on changed that site's key so the step's pick read it all again - two picks a run)
		var t: int = last_tier if last_tier >= 0 and sim.tier_open(last_tier) else _farm_tier(sim)
		for key in ["broadcast", "tune"]:
			if _cleared_at.get(t, -1) == sim.depth[t] or sim.survival(t) < PUSH:
				break                     # words that had to be cleared at this depth aren't put back on it (the twenty-fifth read: a plain Drifter broadcast, cleared and broadcast again on the services 270 times)
			if sim.can_word_craft(t, key) and sim.notes - sim.word_craft_cost(t, key) * 2 >= _notes_kept(sim):
				var cost: int = sim.word_craft_cost(t, key)
				sim.word_craft(t, key)
				bought.append([sim.elapsed, "%s on tier %d for %d notes" % [key, t, cost]])
		if not sim.words[t].is_empty() and sim.can_word_craft(t, "clear") and sim.survival(t) < 0.5:
			sim.word_craft(t, "clear")
			_cleared_at[t] = sim.depth[t]
			bought.append([sim.elapsed, "cleared tier %d" % t])
		if sim.can_insure(t) and sim.cash >= sim.insure_cost(t) * 3 and sim.survival(t) < 0.95:
			sim.set_insure(true)
	# the bench: an affix on what's worn, while the notes stay above the next boss's price
	var floor_notes: int = 0
	for i in range(Data.TIERS.size()):
		floor_notes = maxi(floor_notes, sim.boss_cost(i))
	if element != "":
		_craft_toward(sim)
	_bench_needs(sim)
	_build_one(sim)
	_gamble_one(sim)




## The farm the endgame's tidy reads for its words (15 Oct, the pass's wall): pick_tier reads every site's odds, a third
## of a tidy's time once signals run (after one the site's random, so last_tier's gone every tidy); kept ten minutes.
var _farm_at := -1e9
var _farm := 0
func _farm_tier(sim) -> int:
	if sim.elapsed - _farm_at >= FARM_KEEP_S or not sim.tier_open(_farm):
		_farm = pick_tier(sim)
		_farm_at = sim.elapsed
	return _farm
const FARM_KEEP_S := 600.0


## The Radio (15 Oct): signals made while there's room - Kev's beat when its three are held, else three papers, the
## rare first - and, the Radio full with none worth running, the worst held binned for a fresh roll.
## The pile by kind, read once a shape of it (22 Oct, the pass's wall: a runaway read's pile ran to thousands of
## papers, and each step filtered it four times and sorted it): {plain: the rarest PILE_TOP, rarest first; plain_n:
## how many plain there are; story: this beat's}. One pass, no sort: a step makes three signals at most.
const PILE_TOP := 3 * Data.SIGNAL_PAPERS
var _pile_key: Array = []
var _pile := {"plain": [], "plain_n": 0, "story": []}
func _pile_of(sim) -> Dictionary:
	var all: Array = sim.signal_papers()
	var key := [all.size(), sim.story_now(), int(sim.signal_seq), Items._next_id]     # the item count: a same-size swap in a step (the review)
	if key == _pile_key:
		return _pile
	_pile_key = key
	var plain: Array = []
	var plain_n := 0
	var story: Array = []
	var now: int = sim.story_now()
	for x in all:
		var st: int = sim.story_of(x)
		if st < 0:
			plain_n += 1
			var r: int = int(x.get("rarity", 0))
			if plain.size() < PILE_TOP or r > int(plain[plain.size() - 1].get("rarity", 0)):
				var at: int = plain.size()
				while at > 0 and int(plain[at - 1].get("rarity", 0)) < r:
					at -= 1                   # the rarest first; a tie behind what came first (as the sort left them)
				plain.insert(at, x)
				if plain.size() > PILE_TOP:
					plain.pop_back()
		elif st == now:
			story.append(x)
	_pile = {"plain": plain, "plain_n": plain_n, "story": story}
	return _pile


func _make_signals(sim) -> void:
	# three held and none to run, and papers for another: a player bins the worst (never Kev's) for a fresh roll (D2)
	if sim.signals.size() >= Data.SIGNALS_HELD and _pick_signal(sim) < 0 and int(_pile_of(sim)["plain_n"]) >= Data.SIGNAL_PAPERS:
		var worst := -1
		var wo := 2.0
		for k in range(sim.signals.size()):
			if int(sim.signal_at(k).get("story", -1)) >= 0:
				continue
			var read: Array = sim.signal_odds(k)
			var sid: int = int(sim.signal_at(k).get("id", -1))
			if not _held_at.has(sid):
				_held_at[sid] = sim.elapsed
			if not bool(read[1]) and sim.elapsed - float(_held_at[sid]) < HELD_READ_S:
				worst = -1                    # odds still being read: nothing binned on a part-read (D13: fresh signals went at "0%")
				break                         # - for twenty minutes: a kit changed at the bench starts its read again (D18: never settled, papers piled to 113)
			var o: float = float(read[0])
			if o < wo:
				wo = o
				worst = k
		if worst >= 0:
			bought.append([sim.elapsed, "binned a signal: level %d at %.0f%%%s" % [sim.signal_level(sim.signal_at(worst)), wo * 100.0, _sig_tags(sim.signal_at(worst))]])
			sim.bin_signal(worst)
	var guard := 0
	while sim.signals.size() < Data.SIGNALS_HELD and guard < Data.SIGNALS_HELD:
		guard += 1
		var story: Array = _pile_of(sim)["story"]
		var ids: Array = []
		if sim.story_held().size() == Data.SIGNAL_PAPERS and story.size() >= Data.SIGNAL_PAPERS:
			var seen := {}
			for it in story:
				if not seen.has(str(it["base"])):
					seen[str(it["base"])] = true
					ids.append(int(it["id"]))
		else:
			var plain: Array = _pile_of(sim)["plain"]
			# short of three with the notes for Kev's pile (16 Oct): a player buys the rest of a signal
			while plain.size() < Data.SIGNAL_PAPERS and sim.campaign_done() and sim.kev_block() == "":
				var price: int = sim.kev_price()
				var got: Dictionary = sim.ask_kev()
				if got.is_empty():
					break
				bought.append([sim.elapsed, "off Kev's pile: %s for %d notes" % [str(got["base"]).to_lower(), price]])
				plain = _pile_of(sim)["plain"]
			if plain.size() < Data.SIGNAL_PAPERS and not sim.signals.is_empty():     # plain holds every plain paper when there are under PILE_TOP
				break                         # short of three with a signal held: wait for the rest (20 Oct: one or two only when there's nothing to run)
			ids = plain.slice(0, Data.SIGNAL_PAPERS).map(func(x): return int(x["id"]))
		if sim.decrypt(ids).is_empty():
			break
		bought.append([sim.elapsed, "a signal from %d paper%s: level %d" % [ids.size(), "" if ids.size() == 1 else "s", sim.signal_level(sim.signals.back())]])


## The held signal to run: the deepest that reads PUSH (Kev's at a head's odds, FIRST); -1 for none - the campaign's
## sites farmed meanwhile, for the kit and the papers. Three held and none to run: _make_signals bins the worst (D2).
func _pick_signal(sim) -> int:
	var best := -1
	for k in range(sim.signals.size()):
		var sg: Dictionary = sim.signal_at(k)
		var o: float = float(sim.signal_odds(k)[0])
		var need: float = FIRST if int(sg.get("story", -1)) >= 0 else PUSH
		if o >= need and (best < 0 or sim.signal_level(sg) > sim.signal_level(sim.signal_at(best))):
			best = k
	if best < 0 and sim.signals.size() >= Data.SIGNALS_HELD:
		# the reach as a player meets it (the pass, 20 Oct): nothing to win sure, so the full one at the reach at a coin flip
		var best_o := COIN
		for k in range(sim.signals.size()):
			var sg: Dictionary = sim.signal_at(k)
			var o: float = float(sim.signal_odds(k)[0])
			if int(sg.get("grade", 0)) == 3 and int(sg.get("story", -1)) < 0 and sim.signal_level(sg) >= sim.reach and o >= best_o:
				best = k
				best_o = o
	return best


## The fence's gamble as a flush player takes it: one a run at most, the kind of the primary's type
## when it's on offer, else armour or a helmet, while three times the price stays in hand.
func _gamble_one(sim) -> void:
	var gun = sim.equipped["Primary"]
	var want: Array = []
	if gun != null:
		want.append(str(Items.base_of(gun).get("type", "")))
	want.append_array(["armour", "helmet"])
	for kind in want:
		if kind in sim.gamble and sim.cash - sim.gamble_price(kind) * 3 >= _reserve(sim) and sim.can_gamble(kind):
			var cost: int = sim.gamble_price(kind)
			var it: Dictionary = sim.gamble_buy(kind)
			if not it.is_empty():
				bought.append([sim.elapsed, "gambled %s for £%d: %s" % [kind, cost, Items.full_name(it).to_lower()]])
			return
	# nothing it wanted on offer and the cash piling: whatever he has, at six times the price in hand
	for kind in sim.gamble.duplicate():
		if sim.cash - sim.gamble_price(kind) * 6 >= _reserve(sim) and sim.can_gamble(kind):
			var cost: int = sim.gamble_price(kind)
			var it: Dictionary = sim.gamble_buy(kind)
			if not it.is_empty():
				bought.append([sim.elapsed, "gambled %s for £%d: %s" % [kind, cost, Items.full_name(it).to_lower()]])
			return


## The bench's scrap as a player spends it: one build a run at most, while
## the scrap stays at twice the price - the best grade of rounds for the
## primary's type the stash can make, else the best med. The reader for the
## scrap row: what piles up past a build a run is the prices' to answer for.
func _build_one(sim) -> void:
	var gun = sim.equipped["Primary"]
	var type: String = Items.ammo_type(gun) if gun != null else ""
	var picks: Array = []
	# rounds only while the stash holds under three boxes of the gun's type: a box a run for thirty hours filled the
	# stash to 327 of 234 and dropped every find (the eighteenth read)
	var boxes := 0
	for it in sim.stash:
		if Items.is_ammo(it) and Items.base_of(it).get("type", "") == type:
			boxes += 1
	for o in sim.build_options("grade"):
		if o["ok"] and boxes < 3 and Items.base_named(Data.AMMO, o["name"]).get("type", "") == type:
			picks.append(o)
	if picks.is_empty():
		for o in sim.build_options("med"):
			if o["ok"] and o["from"] != "":
				picks.append(o)
	if picks.is_empty():
		return
	picks.sort_custom(func(a, b): return int(a["tier"]) > int(b["tier"]))
	var o: Dictionary = picks[0]
	if sim.scrap >= int(o["scrap"]) * 2 and sim.build(o["kind"], o["name"]):
		bought.append([sim.elapsed, "built %s for %d scrap" % [o["name"].to_lower(), int(o["scrap"])]])


## The Bench as an ARPG player uses it (the pass, 20 Oct, Matt: "cap resistances, roll perfect gear for your build and
## increase hp/armour"; "if you have a fire build then all damage should be for fire and increase fire + increasing
## dots"): the kit read as one figure - how many times over the runner stands the fight being pushed, its length the
## damage's (_power) - so damage, its element, the dots, HP, armour, resists to the cap and regen are one currency, and
## an affix that adds nothing to it (loot, notes, an element the build doesn't fire, a resist past the cap) is dead.
## Every worn piece but a bag, each tidy at most BENCH_EVERY apart: its level raised with notes, an affix added while
## there's room, then the dead affixes rolled away (the build's own lines padlocked first: the element's conversion,
## its increase, the dots), or, with nothing dead, the weakest's values - rolled again until the piece reads better
## than it did, BENCH_TRIES at most, while two grand stays. No undo: a run of bad rolls is kept, as a player's is.
const BENCH_SLOTS := ["Primary", "Armour", "Helmet", "Charm", "Rig", "Secondary"]
const BENCH_EVERY := 600.0      # sim seconds between the Bench's passes (the odds' reads are the wall's)
const BENCH_TRIES := 6          # rolls on one piece a pass before it moves on
const BENCH_JOBS := 16          # jobs a pass at most
const DEAD := 0.004             # an affix under this share of the kit's figure does nothing for the build
## What the kit's figure can't read - loot, tins, notes, searches, the meds' carry, gangs later: never dead, never
## rolled away (the review: a charm's every line read dead and was rolled six times a pass for ever)
const UTILITY := ["loot_pct", "rarity_pct", "notes_pct", "cash_pct", "search_pct", "capacity", "cash_per_kill", "loot_per_lot",
	"loot_per_med", "cash_per_cell", "patrol_pct", "med_cap", "med_speed_pct", "heal_pct", "overflow_pct"]
var _bench_at := -1e9
var _bench_done := {}           # a piece that came out of a pass no better: its id and affixes, left till either moves


## The kit's figure (_bench_needs): survival_value with the fight's seconds read off the kit tried on, so the damage
## counts by shortening the fight. `it` tried on in its slot ({} for the kit as worn).
## The fight's length off the top bar's figure (damage_total: the element's hit, its increase and the dots - the
## review: estimate's dps() is the raw hits, so fire, fire % and dots read as nothing).
func _power(sim, it := {}) -> float:
	return float(sim._try(it, func():
		var t: Dictionary = sim.effective(sim.front_tier())
		var fight: float = float(t["pool"]) * float(t["hp"]) / maxf(0.000001, sim.damage_total() * sim.pace() * float(t["pace"]))
		return sim.survival_value(clampf(fight, 1.0, 3600.0))))


## Each affix's share of the kit's figure on the worn piece in `slot`: [[stat, share], ...], the best first.
func _shares(sim, slot: String) -> Array:
	var it: Dictionary = sim.equipped[slot]
	var p0 := _power(sim)
	var out: Array = []
	for k in range(it["affixes"].size()):
		var without: Dictionary = it.duplicate(true)
		without["affixes"].remove_at(k)
		out.append([str(it["affixes"][k]["stat"]), (p0 - _power(sim, without)) / maxf(p0, 0.000001)])
	out.sort_custom(func(x, y): return float(x[1]) > float(y[1]))
	return out


## The build's own lines on a gun, padlocked before anything else: the element's conversion and increase, the dots
## for a burn, poison or bleed build.
func _build_lines() -> Array:
	if element == "" or element == "physical":
		return ["physical_pct", "damage_pct"] if element == "physical" else []
	var out := ["conv_%s_pct" % element, "%s_pct" % element]
	if element in ["fire", "poison", "bleed"]:
		out.append("dot_pct")
	return out


## Tempering (25 Oct, the endgame): the cheapest worn piece a level up while the scrap and the tins run to it, the
## Build column's scrap kept back - so the climb goes as fast as the piles allow, as a player's would.
const TEMPER_SLOTS := ["Primary", "Armour", "Helmet", "Secondary"]     # the bags take no temper now (the second review)
## What a temper on a slot is worth to the bot, against its scrap: the gun is the whole offence (the second review: the
## cheapest-first rotation gave it one temper in seven).
const TEMPER_WEIGHT := {"Primary": 3.0, "Armour": 1.5, "Helmet": 1.0, "Secondary": 1.0}
const TEMPERS_A_PASS := 24
var tempers := 0                  # every temper the read made (the summary's)


func _temper(sim, floor_cash: float) -> void:
	var keep: int = Data.BUILD_GUN * 3
	var done := 0
	for n in range(TEMPERS_A_PASS):
		# the most worth a cost first, its tins counted in scrap at the Fence's rate; one it can't pay for is passed over,
		# not the end of the pass (the reviewer: the gun's tins short stopped every temper)
		var picks: Array = []
		for sl in TEMPER_SLOTS:
			var it = sim.equipped.get(sl)
			if it == null or sim.temper_block(it) != "":
				continue
			var sc: int = sim.temper_scrap(it)
			var cc: int = sim.craft_cost(it, "temper")
			if cc < 0 or sim.scrap - sc < keep or sim.cash - cc < floor_cash:
				continue
			picks.append([float(TEMPER_WEIGHT[sl]) / float(maxi(1, sc) + cc / float(Data.SCRAP_PER_POUND)), it])
		if picks.is_empty():
			break
		picks.sort_custom(func(a, b): return a[0] > b[0])
		if not sim.craft(picks[0][1]["id"], "temper"):
			break
		done += 1
		tempers += 1
	if done > 0:
		var lv: Array = TEMPER_SLOTS.filter(func(sl): return sim.equipped.get(sl) != null).map(func(sl): return Items.ilvl(sim.equipped[sl]))
		bought.append([sim.elapsed, "bench: %d tempers, the kit at item levels %s" % [done, str(lv)]])


func _bench_needs(sim) -> void:
	if sim.elapsed - _bench_at < BENCH_EVERY:
		return
	_bench_at = sim.elapsed
	var floor_cash := maxf(2000.0, _reserve(sim))
	_temper(sim, floor_cash)
	var jobs := 0
	for s in BENCH_SLOTS:
		var it = sim.equipped.get(s)
		if it == null or it.has("unique") or it.has("set") or jobs >= BENCH_JOBS:
			continue
		# its level first (notes): the lowest tiers stop rolling
		var bc: int = sim.craft_cost(it, "bump")
		if bc >= 0 and sim.notes - bc >= _notes_kept(sim) and sim.notes >= bc * 2 and sim.craft(it["id"], "bump"):
			jobs += 1
			bought.append([sim.elapsed, "bench: the %s's level raised for %d notes" % [s.to_lower(), bc]])
		# an affix while there's room: never worse, and a rarity up (the tiers' cap with it)
		var ac: int = sim.craft_cost(it, "add")
		if ac >= 0 and sim.cash - ac >= floor_cash and sim.craft(it["id"], "add"):
			jobs += 1
			bought.append([sim.elapsed, "bench: an affix on the %s for £%d" % [s.to_lower(), ac]])
		if it["affixes"].is_empty():
			continue
		var done_key := hash([int(it["id"]), it["affixes"]])
		if _bench_done.get(done_key, false):
			continue
		var shares := _shares(sim, s)
		var dead: Array = shares.filter(func(x): return float(x[1]) < DEAD and not (x[0] in UTILITY))
		var kept: int = shares.size() - dead.size()
		# new affixes only when every line worth keeping fits under the padlocks (the review: one dead line on a
		# five-line piece and one padlock rolled four to fix one); else the weakest line the figure reads, by its values
		var kind := "affixes" if not dead.is_empty() and kept <= sim.lock_max() else "values"
		var weakest_stat := ""
		if kind == "values":
			for k in range(shares.size() - 1, -1, -1):
				var st: String = str(shares[k][0])
				if st in UTILITY or float(shares[k][1]) < DEAD:
					continue
				for a in it["affixes"]:
					if str(a["stat"]) == st and int(a.get("tier", 1)) < Items.rarity_cap(it):
						weakest_stat = st
				if weakest_stat != "":
					break
			if weakest_stat == "":
				_bench_done[done_key] = true
				continue                  # every line it reads at the rarity's cap: as good as the Bench makes it
		# padlocks: the build's lines on it, then the best shares, then what the figure can't read - never a dead one
		it["locks"] = []
		var order: Array = []
		for st in _build_lines():
			if it["affixes"].any(func(a): return str(a["stat"]) == st):
				order.append(st)
		for x in shares:
			if float(x[1]) >= DEAD and not (x[0] in order):
				order.append(x[0])
		for x in shares:
			if x[0] in UTILITY and not (x[0] in order):
				order.append(x[0])
		if kind == "values":
			order.erase(weakest_stat)
		for st in order:
			if not sim.toggle_lock(int(it["id"]), str(st)):
				break
		var p_start := _power(sim)
		var tries := 0
		while tries < BENCH_TRIES and jobs < BENCH_JOBS:
			var cost: int = sim.craft_cost(it, kind)
			if cost < 0 or sim.cash - cost < floor_cash or not sim.craft(it["id"], kind):
				break
			tries += 1
			jobs += 1
			var p := _power(sim)
			bought.append([sim.elapsed, "bench: the %s's %s re-rolled for £%d (%+.1f%%)" % [s.to_lower(), "affixes" if kind == "affixes" else "values", cost, (p / maxf(p_start, 0.000001) - 1.0) * 100.0]])
			if p > p_start * 1.001:
				break                     # better than it was: kept, the next piece
		if tries > 0 and _power(sim) <= p_start * 1.001:
			_bench_done[hash([int(it["id"]), it["affixes"]])] = true     # no better this pass: left till it changes


## The build's bench work on the primary: a socket for the element's
## socketable; an affix added until the element's conversion or increased
## turns up; when the piece is full without one, the rest re-rolled with the
## element's affix locked, or all of it re-rolled - while two grand stays.
func _craft_toward(sim) -> void:
	var it = sim.equipped["Primary"]
	if it == null or it.has("unique") or element == "physical":
		return                            # the physical build has no conversion or socketable to chase (the reviewer's catch: it re-rolled for one forever)
	var conv := "conv_%s_pct" % element
	var inc := "%s_pct" % element
	if Items.sockets(it) == 0:
		var c: int = sim.craft_cost(it, "socket")
		if c >= 0 and sim.cash - c >= maxf(2000.0, _reserve(sim)) and sim.craft(it["id"], "socket"):
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
			if has_conv or has_inc:
				return                    # full with one on: the needs-led Bench padlocks it and rolls the rest (the review: the two fought over the gun)
			# full with neither: new affixes, the lot (20 Oct: padlocks)
			kind = "affixes"
			it["locks"] = []
		var cost: int = sim.craft_cost(it, kind, stat)
		if cost < 0 or sim.cash - cost < maxf(2000.0, _reserve(sim)) or not sim.craft(it["id"], kind, stat):
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
	if str(it.get("rule", "")) == "weed_burner":
		return 1.0 if element == "fire" else -0.45     # all fire: an element build's own element switched off (25 Oct, the review: on 11 of 24 end kits)
	if element == "physical":
		# the physical build (Knuckles, 9 Oct): the share of the gun's hit that isn't converted
		var conv := 0.0
		for el in Data.ELEMENTS:
			var st := "conv_%s_pct" % el
			conv += float(Items.base_of(it).get(st, 0)) + Items.affix_total(it, st) + Items.fitted_sum(it, st)
		return maxf(0.0, 1.0 - conv / 100.0)
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
		if it["slot"] == "Primary" and sim.can_wear(it) and (best.is_empty() or _elem_score(it) > _elem_score(best)):
			best = it
	if best.is_empty():
		return
	if cur == null or (_elem_score(best) > _elem_score(cur) and sim.fit_value(best, "Primary") >= sim.damage_total() * ELEM_DPS_FLOOR):
		sim.equip_item(best["id"])        # D23: the element's gun, but not at a fifth less damage, read on a try-on - a shock Scrapper took one at half at an hour and held the Estate's wall for twenty


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
		if it["slot"] == "Primary" and sim.can_wear(it) and Items.base_of(it).get("type", "") == type and (best.is_empty() or Items.score(it) > Items.score(best)):
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
	_disarm_stale(sim)
	# the endgame (7 Oct): a site's depth is fought at its level, so the bot runs the site that reads
	# PUSH at the highest level (the barracks at depth 2 over the streets at depth 8: the better kit),
	# except that the lorry is the ending - while it isn't beaten, the services come first when they read
	# PUSH at their depth, and the climb digs them toward it
	if sim.campaign_done():
		# the sites as they stand first (a read each) - a site climbed past its clear that no longer reads PUSH steps
		# back to the clear, or it would sit unread for the rest of the run - then, when none holds, the ladders
		# stepped back, the highest level first
		# (the highest level first and the first that holds taken: a read is the lookout's dry runs, and past level
		# 14 a fight is minutes long, so nine reads a pick ran the seventeenth read at a third of the pace)
		var order: Array = []
		for i in range(Data.TIERS.size()):
			if sim.tier_open(i):
				order.append(i)
		order.sort_custom(func(a, b_in): return _aim_level(sim, a) > _aim_level(sim, b_in))
		for i in order:
			if sim.survival(i) >= PUSH:          # every site at its campaign self (15 Oct): the highest that holds, for its papers
				best = i
				break
	if best < 0:
		for i in range(Data.TIERS.size() - 1, -1, -1):
			if not sim.tier_open(i):
				continue
			while sim.depth[i] > 1 and sim.survival(i) < PUSH:
				sim.set_depth(i, sim.depth[i] - 1)
			var head: Dictionary = sim.boss_of(i)
			if not head.is_empty() and sim.best_depth[i] > 0 and not sim.bosses_beaten[int(head["zone"])] and sim.can_arm_boss(i):
				sim.arm_boss(i, true)               # a head not yet beaten, at a person's odds (the review: farmed sites never armed him)
				if sim.survival(i) >= FIRST:
					best = i
					break
				sim.arm_boss(i, false)
			var odds: float = sim.survival(i)
			if odds >= (FIRST if sim.best_depth[i] <= 0 else PUSH):     # a first clear at a person's odds; what's cleared, farmed at PUSH
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
	if not b.is_empty() and sim.best_depth[best] > 0 and (not sim.bosses_beaten[int(b["zone"])] or (sim.notes >= sim.boss_cost(best) * 2 and sim.notes - sim.boss_cost(best) >= _notes_kept(sim))):
		sim.arm_boss(best, true)
		if sim.survival(best) < (FIRST if not sim.bosses_beaten[int(b["zone"])] else PUSH):     # a head not yet beaten at a person's odds (13 Oct)
			sim.arm_boss(best, false)
	elif not b.is_empty():
		sim.arm_boss(best, false)
	# the lorry: armed on the services at its depth when the notes are there and the odds hold with the convoy in
	# (the price and the convoy grow with the depth: when the armed read fails, the services step back toward
	# convoy_depth() and read again, so the bot does not dig past the lorry it cannot take)
	if best == Data.CONVOY_TIER and sim.is_convoy(best) and not sim.lorry_done and sim.notes >= sim.boss_cost(best):
		if sim.elapsed - lorry_read_at >= LORRY_EVERY:
			lorry_read_at = sim.elapsed
			lorry_ok = false
			while true:
				sim.arm_boss(best, false)
				if sim.notes >= sim.boss_cost(best):
					sim.arm_boss(best, true)
					if sim.survival(best) >= LORRY_ODDS:
						lorry_ok = true
						break
					sim.arm_boss(best, false)
				if sim.depth[best] <= sim.convoy_depth():
					break
				sim.set_depth(best, sim.depth[best] - 1)
		if lorry_ok and sim.notes >= sim.boss_cost(best):
			sim.arm_boss(best, true)
			if sim.can_insure(best):
				sim.set_insure(true)         # the lorry, insured
			return best
	if sim.survival(best) < (FIRST if sim.best_depth[best] <= 0 or sim.boss_armed.get(best, false) else PUSH):
		sim.advance((sim.max_hp() - sim.hp) / maxf(sim.rest_rate(), 0.1))
	return best


## What the bot keeps back from the bench, the gamble and the words: the clinic's price three times over (the
## sixteenth read: a wounded Poacher spent every run's take on affixes, never had the treatment's price when
## the next run came, and ran the services hurt and wounded for seven hours at £3k a run), and £2,000.
func _reserve(sim) -> float:
	return sim.treat_cost() * 3.0 + _lorry_watch_saving(sim)     # nothing when whole: the bench keeps its own £2,000 floor


## The Radio's Lorry watch (the convoy two depths shallower) saved for while the lorry stands and its column is
## open (the twenty-fifth read, 9 Oct: every build that beat the lorry bought it first, at £45-85k; the plain
## Drifter's bench spent every run's take as it came, never held the price, never bought it, and sat under the
## convoy's depth for 32 hours). A player who knows the lorry is the ending saves for the pick that brings it near.
const LORRY_WATCH_COL := 3
func _lorry_watch_saving(_sim) -> float:
	return 0.0                                # the lorry's the depot's signal now (15 Oct): the convoy's depth no longer matters


## The notes kept back for the lorry once the services stand at its depth (the nineteenth read: three yards read the
## convoy at 1.00 and sat at 844-1,679 notes against its 1,680-2,160, the rest gone on the mate and the heads).
func _notes_kept(_sim) -> int:
	return 0                                  # the lorry's the depot's signal now (15 Oct): its papers paid, no notes kept for it


## What a site is worth running past the campaign: its level, and its papers (the Bank's three times).
func _aim_level(sim, i: int) -> float:
	return sim.site_level(i) + sim.paper_odds(i) * 100.0


## A boss left armed on a tier the bot moved on from would read that tier red
## for the rest of the run (the sim keeps the toggle on until it is turned off):
## every pick reads the plain sites, and arms the one it picks below.
func _disarm_stale(sim) -> void:
	for i in range(Data.TIERS.size()):
		if sim.boss_armed.get(i, false):
			sim.arm_boss(i, false)


## Climb: gone (18 Oct, Matt: a player can't set a site's depth since signals took the depths on 15 Oct, so the bot
## doesn't either; set_depth held the campaign at depth 1 already, this makes it plain).
func _climb(_sim) -> void:
	return


func _train_tree(sim) -> void:
	var spent := true
	var order: Array = sim.trees()
	if keystones_first and order.size() == 3:
		order = [order[0], order[2], order[1]]
	if element != "":
		# the build's tree first, to its keystone and past it; the class's after
		var mine: Array = order.filter(func(t): return t.get("element", "") == element)
		# then the class tree holding the runner's half of that element's joint: its keystone wants the joint closed
		var joined: Array = []
		for c in sim.my_classes():
			var j: Dictionary = Data.joint_in(c, mine[0]["name"]) if not mine.is_empty() else {}
			if not j.is_empty():
				joined.append(j["tree"])
		var halves: Array = order.filter(func(t): return t["name"] in joined)
		order = mine + halves + order.filter(func(t): return not t.has("element") and not (t["name"] in joined))
	# the paragon board (21 Oct, the crew): the lowest resist up while it's short of the cap, a point in three; damage and HP
	# the rest, in turn. Find and tins the bot leaves (a player's call)
	while sim.paragon_free() > 0:
		var low := Data.RESIST_CAP
		for ty in Data.ELEMENTS:
			low = minf(low, sim.resist_raw(ty))
		var n: int = sim.paragon_spent()
		var key: String = "resists" if low < Data.RESIST_CAP and n % 3 == 2 else ("damage" if sim.paragon_pts("damage") <= sim.paragon_pts("hp") else "hp")
		if not sim.paragon_add(key):
			break
	# the Pitch's tree first, from its own pool (21 Oct: the camp's points, apart from the class's)
	var pitch_t: Dictionary = Data.tree_named(Data.COMMON_TREE)
	if element != "" and not sim.element_opened(element) and sim.pitch_free() > 0:
		var et0: Dictionary = Data.element_tree_of(element)
		for i in range(et0["nodes"].size()):
			var sid: String = "%s/%d" % [et0["name"], i]
			if sim.is_element_starter(sid) and sim.can_train(sid):
				sim.train_node(sid)            # the Pitch circle (24 Oct): the build's element opened with the first Pitch point
				break
	while sim.pitch_free() > 0:
		var pid := _next_in(sim, pitch_t)
		if pid == "" or not sim.can_train(pid):
			break
		sim.train_node(pid)
	# the elements' regions from their own pools (slice 3: points earned on the use meter), each as far as it goes
	for et in Data.ELEMENT_TREES:
		while sim.element_free(et["element"]) > 0:
			var eid := _next_in(sim, et)
			if eid == "" or not sim.can_train(eid):
				break
			sim.train_node(eid)
	order = order.filter(func(t): return t["name"] != Data.COMMON_TREE and not t.has("element") and not t.get("ring", false))     # the class's lanes alone: the Pitch, the elements and the ring have their pools above
	while sim.points_free() > 0 and spent:
		spent = false
		for b in order:
			var next_id := _next_in(sim, b)
			if next_id == "":
				continue                  # this tree is done; the next
			if sim.can_train(next_id):
				sim.train_node(next_id)
				spent = true
				break
			if keystones_first:
				return                    # save up for it rather than spend elsewhere


## The Yard's lanes (9 Oct): every open column's pick, its first side unless PICK_B names the second, cheapest
## first, with £500 kept back; then a rank where one is open, with half its price again kept back.
const PICK_B := {"bench": [1], "stash": [], "clinic": [], "fence": [1, 4], "radio": [], "generator": [], "lookout": [], "kennel": [3]}   # the Generator's first sides (24 Oct: its away picks gone; the energy ones read in milestone 9)
## The cheapest rank the Pitch could buy now (no rank open: a price past any).
func _cheapest_rank(sim) -> int:
	var out := 1 << 40
	for b in Data.YARD:
		if sim.can_yard_rank(b["key"]) or sim.yard_rank_block(b["key"]) == "Short of tins":
			out = mini(out, sim.yard_rank_cost(b["key"]))
	return out


func _build_yard(sim) -> void:
	if _lorry_watch_saving(sim) > 0.0 and sim.cash >= _lorry_watch_saving(sim) and sim.can_yard_pick("radio", LORRY_WATCH_COL, "a"):
		var cost: int = sim.yard_pick_cost("radio", LORRY_WATCH_COL)
		if sim.yard_pick("radio", LORRY_WATCH_COL, "a"):
			bought.append([sim.elapsed, "radio lorry_watch for £%d" % cost])
		return
	var best_key := ""
	var best_col := -1
	var best_cost := 1 << 40
	for b in Data.YARD:
		for c in range(b["picks"].size()):
			if sim.yard_side(b["key"], c) != "":
				continue
			var side: String = "b" if c in PICK_B.get(b["key"], []) else "a"
			if sim.can_yard_pick(b["key"], c, side) and sim.yard_pick_cost(b["key"], c) < best_cost:
				best_key = b["key"]
				best_col = c
				best_cost = sim.yard_pick_cost(b["key"], c)
	if best_key != "" and sim.cash >= best_cost + 500 and sim.cash - best_cost >= _lorry_watch_saving(sim):
		var side: String = "b" if best_col in PICK_B.get(best_key, []) else "a"
		if sim.yard_pick(best_key, best_col, side):
			bought.append([sim.elapsed, "%s %s for £%d" % [best_key, Data.yard_building(best_key)["picks"][best_col][0 if side == "a" else 1]["id"], best_cost]])
		return
	var firsts_left: bool = Data.YARD.any(func(yb): return range(yb["picks"].size()).any(func(c): return c < sim.yard_cols() and sim.yard_side(yb["key"], c) == "" and not sim.yard_pick_block(yb["key"], c, "a").begins_with("Opens with")))
	if best_key == "" and not firsts_left:
		# every open column has its first side (its price or salvage aside - the review): a column's other side (24 Oct,
		# option B), the cheapest, with half again in hand
		var sec_key := ""
		var sec_col := -1
		var sec_side := ""
		var sec_cost := 1 << 40
		for b in Data.YARD:
			for c in range(b["picks"].size()):
				var have: String = sim.yard_side(b["key"], c)
				if have.length() != 1:
					continue
				var other: String = "b" if have == "a" else "a"
				if sim.can_yard_pick(b["key"], c, other) and sim.yard_pick_cost(b["key"], c) < sec_cost:
					sec_key = b["key"]
					sec_col = c
					sec_side = other
					sec_cost = sim.yard_pick_cost(b["key"], c)
		if sec_key != "" and sim.cash >= sec_cost * 1.5 and sim.cash - sec_cost >= _lorry_watch_saving(sim) and sec_cost <= _cheapest_rank(sim):
			if sim.yard_pick(sec_key, sec_col, sec_side):
				bought.append([sim.elapsed, "%s %s (its other side) for £%d" % [sec_key, Data.yard_building(sec_key)["picks"][sec_col][0 if sec_side == "a" else 1]["id"], sec_cost]])
			return
	for b in Data.YARD:
		if sim.can_yard_rank(b["key"]) and sim.cash >= sim.yard_rank_cost(b["key"]) * 1.5 and sim.cash - sim.yard_rank_cost(b["key"]) >= _lorry_watch_saving(sim):
			var cost: int = sim.yard_rank_cost(b["key"])
			if sim.buy_yard_rank(b["key"]):
				bought.append([sim.elapsed, "%s rank %d for £%d" % [b["key"], sim.yard_rank(b["key"]), cost]])
			return


## A tree's next node for this runner, left to right (the lanes, 9 Oct): the lowest column's untaken node it
## could train with the points - never another class's half, an element's top with no joint closed there,
## or a capstone before its tree's shape. "" when there's none now.
func _next_in(sim, b: Dictionary) -> String:
	var best := ""
	var best_key := 1 << 20
	for i in range(b["nodes"].size()):
		var id := "%s/%d" % [b["name"], i]
		if sim.tree.has(id):
			continue
		var why: String = sim.train_block(id, true)
		if why != "" and (not why.begins_with("opens at") or why.begins_with("opens at level")):
			continue                      # a level's wait (15 Oct) isn't saved for: the points go elsewhere meanwhile
		var nd: Dictionary = b["nodes"][i]
		if nd.get("keystone", false) and sim.keystone_held_against(id) != "":
			continue                      # the keystone choice (22 Oct): the bot keeps the first it took
		if nd.has("type") and not nd.has("joint") and not sim._active(nd):
			continue                      # a notable typed for a gun not in hand (the review): no point in it - a joint's half is the build's whatever's in hand now
		if nd.has("bridge"):
			continue                      # the bridge (slice 3) is a player's call: the bot reads its own class
		var at: Array = nd.get("at", [nd.get("col", 0), nd.get("row", 0)])
		var key: int = int(round(float(at[0]) * 100.0)) + int(round(absf(float(at[1])) * 10.0))     # along the lane, the rails before what hangs off them
		if key < best_key:
			best_key = key
			best = id
	return best


func _restock_meds(sim) -> void:
	_restock_rounds(sim)
	var guard := 0
	while sim.rig_room(1) and guard < 40:
		guard += 1
		var took := false
		var small := false
		for it in sim.stash:
			if Items.is_medical(it):
				small = small or Items.size(it) <= 1
				if sim.take(it["id"]):
					took = true
					break
		if took:
			continue
		# a bandage only when the stash has no one-cell med (D13: a kit too big for the room left was tried, refused and
		# a bandage bought for the stash, again and again - a hundred, the cash gone and the stash full, papers left lying)
		if small or sim.cash < 200.0 or not sim.buy_med("Bandage"):
			return


## Rounds for both guns: two runs' worth for the primary, one for the
## secondary; bought by the box when the stash has none. A stack in the rig
## for a type neither gun fires goes back to the stash first (a gun swapped
## leaves its old rounds behind), and sells with the spares.
func _restock_rounds(sim) -> void:
	var types: Array = []
	for s in ["Primary", "Secondary"]:
		if sim.equipped[s] != null and not Items.free_rounds(sim.equipped[s]):
			types.append(Items.ammo_type(sim.equipped[s]))
	for it in sim.rig.duplicate():
		if Items.is_ammo(it) and not (Items.base_of(it)["type"] in types):
			sim.leave(it["id"])
	for pair in [["Primary", 2.0], ["Secondary", 1.0]]:
		var gun = sim.equipped[pair[0]]
		if gun == null or Items.ammo_type(gun) == "none" or Items.free_rounds(gun):
			continue                          # a gun that spends nothing wants no rounds (18 Oct: the Weed Burner, the Spare Key)
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
				# no room for the box: the cheapest spare goes - only when the box can be bought (the review: with the Fence
				# shut it binned a spare a pass, six a tidy, for nothing)
				if not sim.room_open("fence"):
					break
				var worst := {}
				for it in sim.stash:
					if Items.is_medical(it) or Items.is_ammo(it) or Items.is_paper(it) or it.get("mythic", false):
						continue
					if element != "" and Items.is_socketable(it) and float(Items.base_of(it).get("conv_%s_pct" % element, 0)) > 0.0:
						continue
					if worst.is_empty() or it["value"] < worst["value"]:
						worst = it
				if worst.is_empty() or not _dispose(sim, worst):
					break


const AMMO_STACKS_KEPT := 6


const HELD_READ_S := 1200.0
const ELEM_DPS_FLOOR := 0.8
var _held_at := {}


## A spare gone: sold, or binned for its scrap while the Fence is shut (D27: before the Carpet Man's ledger nothing
## sold, the stash filled with spares, nothing more was picked up, and a shock Scrapper never left the Estate).
func _dispose(sim, it: Dictionary) -> bool:
	return sim.sell(it) if sim.room_open("fence") else sim.bin(int(it["id"]))


func _sell_spares(sim) -> void:
	var keep_type: String = TYPE_OF.get(sim.cls, "") if keystones_first else ""
	# meds: a dozen cells' worth stay, the dearest; the rig can't carry more and they pile up otherwise
	var meds: Array = sim.stash.filter(func(it): return Items.is_medical(it))
	meds.sort_custom(func(a, b): return a["value"] > b["value"])
	var med_cells := 0
	for it in meds:
		med_cells += Items.size(it)
		if med_cells > 12:
			_dispose(sim, it)
	# rounds a gun fires: the six dearest stacks a type stay (D15: a bleed Doorman's stash held 176 stacks, full, and
	# picked nothing up - no papers - for the last ten hours of the read)
	var by_type := {}
	for it in sim.stash:
		if Items.is_ammo(it):
			var ty: String = str(Items.base_of(it)["type"])
			if not by_type.has(ty):
				by_type[ty] = []
			by_type[ty].append(it)
	# (the plain papers' cull went 22 Oct: papers live on the Radio's pile since 18 Oct, which no sell reaches - the
	# cull sorted a pile of thousands and failed to sell each one, every tidy, for nothing)
	for ty in by_type:
		var stacks: Array = by_type[ty]
		stacks.sort_custom(func(a, b_in): return int(a.get("value", 0)) > int(b_in.get("value", 0)))     # the dearest: grade and rounds (the review)
		for it in stacks.slice(AMMO_STACKS_KEPT):
			_dispose(sim, it)
	# the keepers read once (22 Oct, the pass's wall: the best of a slot was asked once an item, a scan of the stash
	# each, with the kit's key hashed every ask): the best of each slot, of the class's type, of each mount
	var best_id := {}
	for slot in Data.SLOTS:
		var b: Dictionary = sim.best_in_stash(slot)
		if not b.is_empty():
			best_id[slot] = int(b["id"])
	var type_best: Dictionary = _best_of_type(sim, keep_type) if keep_type != "" else {}
	var mount_rank := {}                  # item id -> its rank among the mount's parts, best first
	for it in sim.stash:
		if Items.is_attachment(it) and not mount_rank.has(str(it["mount"])):
			var ranked: Array = sim.attachments_for(it["mount"])
			for r in range(ranked.size()):
				mount_rank[int(ranked[r]["id"])] = r
	for it in sim.stash.duplicate():
		if Items.is_medical(it) or Items.is_paper(it) or it.get("mythic", false):
			continue                      # a paper's a key to the endgame now (15 Oct): kept; a mythic never goes
		if Items.is_ammo(it):
			var fired := false
			for g in [sim.equipped["Primary"], sim.equipped["Secondary"]]:
				fired = fired or (g != null and Items.base_of(it)["type"] == Items.ammo_type(g))
			if not fired:
				_dispose(sim, it)
			continue
		if keep_type != "" and it["slot"] == "Primary" and Items.base_of(it).get("type", "") == keep_type and not type_best.is_empty() and int(type_best["id"]) == int(it["id"]):
			continue                      # the best spare of the class's type stays; the rest of them go
		if element != "" and Items.is_socketable(it) and float(Items.base_of(it).get("conv_%s_pct" % element, 0)) > 0.0:
			continue
		if element != "" and it["slot"] == "Primary":
			var cur = sim.equipped["Primary"]
			if cur == null or _elem_score(it) >= _elem_score(cur) * 0.8:
				continue
		if Items.is_attachment(it):
			# the best three of a mount stay; attachments_for() is sorted best first
			if int(mount_rank.get(int(it["id"]), 99)) >= 3:
				_dispose(sim, it)
			continue
		if int(best_id.get(str(it["slot"]), -1)) != int(it["id"]):
			_dispose(sim, it)


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
			if Items.is_socketable(it) and float(Items.base_of(it).get("conv_%s_pct" % element, 0)) > 0.0 and sim.cash >= sim.price(it) + 500 and _socket_wanting(sim) != "" and sim.buy(i):
				bought.append([sim.elapsed, "%s for £%d" % [it["base"].to_lower(), sim.price(it)]])
				break
	for i in range(sim.market.size()):
		var it: Dictionary = sim.market[i]
		if Items.is_attachment(it) or Items.rig_item(it) or not sim.can_wear(it):
			continue                       # gear over the runner's level waits (15 Oct): not bought to wear yet
		var cur = sim.equipped[it["slot"]]
		var g: float = sim.upgrade_gain(it) if sim.compare(it) == 1 else 0.0     # tried on (11 Oct), as the player's arrow
		if element != "" and it["slot"] == "Primary":
			g = ((_elem_score(it) - _elem_score(cur)) / maxf(_elem_score(cur), 0.01)) if cur != null else sim.EMPTY_GAIN   # a build weighs its gun its own way, as a share like the rest
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
