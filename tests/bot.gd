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
const SAFE_PAST_CAP := 0.8     # past level 50 the coin flip's bar (1 Nov, BUILD41, PROBE40 4: 75-100 deaths after the Quartermaster on three builds): with paragon XP and kit at stake, a signal under this is skipped, not run at COIN
const STAKE_SHARE := 0.5       # a run whose kit lost on a death would take this share of the DPS or more is insured when it can be afforded (BUILD41)
const INSURE_SPARE_STAKE := 1.5     # the price in hand this many times over insures a County run or a run with that much at stake (the rest: three times)
const SETTLE_TRIES := 200      # reads of a pending odds figure before the bot gives up on it this step (each read runs more of its dry runs)
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
## reading PUSH on a held signal; else the played one CREW_AHEAD levels or more over the one out (a death
## before the Quartermaster sends a runner back to level 1; past him it keeps the level); else, the one out at the cap, the next not played, at the crew's build for it (CREW_BUILDS;
## the read's own class keeps the read's build). Swaps are free at camp; each class keeps its own tree and kit.
## (The first cut sent a new class out every two hours: five level-1 runners and nobody at the reach.)
const CREW_STAND := 7200.0
const CREW_AHEAD := 5
const CREW_BUILDS := {"Doorman": "bleed", "Drifter": "fire", "Poacher": "frost", "Paramedic": "shock", "Scrapper": "shock", "Recruit": "physical"}     # the Recruit (24 Oct); the Paramedic shock (joints B)
var crew_on := true
## The repeat runs (29 Oct, docs/design/trips.md 1): past the campaign (the Quartermaster down; the designer: a person
## watches the campaign) the bot farms a cleared site with "Run it ×N" when the gate allows (90%+ at full HP, no head on),
## as a person leaving the game to it would; `norepeat` on a read switches it off. Kev's wagers off unless asked for.
var repeats := true
static var norepeat := false      # a read without repeats (`norepeat` on balance.gd's line): every Bot.new() reads it
var wagers_on := false
var repeat_runs := 0              # repeat runs gone, all told (the summary's)
var repeat_bails := 0
var repeat_wounds := 0
var repeat_timeouts := 0
var repeats_gone := 0             # repeats set off
var last_repeat := {}             # the last repeat's sums (Sim.repeat_totals), for the read to count its runs one by one
var crew_swaps := 0
## The wall (30 Oct, Matt: "in real play you'd hit a wall with a class and switch - which is why I wanted this design"):
## in the campaign, picks that are no step forward for WALL_S of the yard's time are a wall - a step forward is a first
## clear or a head not yet beaten taken at FIRST or better (a fallback pick under FIRST is none). Walled, the open
## class that reads the wall best goes out: a played one at FIRST; else a new one at its crew build, to grow on the
## cleared sites; else, none new, a played one that reads it 0.05 better than the one out. The one walled is read
## again when it levels or every WALL_S (wall_return) and comes back when it reads the wall at FIRST. The read's own
## target isn't walled away while it's still levelling (a level in the last WALL_S). Swaps are free at camp. Off but
## for the one-save campaign reads (balance.gd).
const WALL_S := 7200.0
var wall_on := false
var walls: Array = []             # [hour, tier, a head?, from, to, the odds `to` read (-1 a new one), the odds `from` read] a swap
var _walled := {}                 # class -> {lv, at}: walled away, read again when it levels or WALL_S after `at` (the fix round)
var _tgt_lv := -1                 # the target's level when last seen out, and the hour it moved: still levelling, it stays out
var _tgt_lv_at := -1e9
var _wall_from := -1.0
var _wall_cls := ""
var _wall_grace_lv := 0           # a new class out grows to the walled one's level before its own clock runs (the review)
var _wall_home := false           # the campaign done: the read's own class back out, once
## The one-save read (25 Oct, the endgame chase step 8: Matt, "effectively a different game" a class): the read starts
## as the Poacher, as a new game does, and takes its target build the moment that class opens; the crew's swaps after.
var target_cls := ""
var target_el := ""
var _target_taken := false
var builds := {}                  # class -> {element, keystones_first} as the bot plays it
## The as-played reads (31 Oct, BUILD34: the designer's play - "I spent my first two pitch points opening both elements
## to get the bars moving. Then focussed on the pitch itself"): each class opens its own two elements with its first
## Pitch points, its class points go to both joints' class halves first, each open element's points to its joint half
## first. Off for every other read.
var as_played := false
var on_swap := Callable()        # called with the camp before a class goes in (the as-played read's note); unset, nothing
## A broken-build read (26 Oct, Matt: "test they are broken and can smash all content at least once"): the combo's key.
## Its set pieces and unique are held on the runner, found again at the reach as it climbs (as a player who chases the
## build keeps it); issued kit goes in the slots the build leaves free.
var broken := ""
var broken_slots: Array = []
var held_slots: Array = []               # the slots _hold_broken wants (1 Nov): _wear_ups leaves them be
## A hunted build (26 Oct, Matt: "cook some different builds up"): {set, pieces, rule, gun}, held as a combo's is - the
## set at its count ("" none), a unique by its rule ("" none), a primary of the gun type ("" the bot's own). Set, it
## stands in for `broken`'s combo.
var hold := {}
## Stay out (26 Oct, Matt): a build's stacks are the run's, so a read of one keeps farming patrols - past a full pack -
## till this many, or the bail. 0: the two patrols a normal run leaves on.
var stay_out := 0
const STAY_CLOCK_MIN := 20.0      # seconds of clock a stay keeps at least, the kill rate unread
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


func _crew_out(sim, name: String, quiet := false) -> bool:
	if not sim.class_open(name):
		return false                      # shut till its head (or Kev's story): the game's own rule, which set_class leaves to Training
	if on_swap.is_valid():
		on_swap.call(sim)                 # the as-played read's note of the class going in (BUILD34, the review)
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
	if not quiet:
		crew_swaps += 1
		bought.append([sim.elapsed, "crew: %s out for %s (level %d)" % [name, from, sim.level()]])
	return true


## The campaign's next step for the crew: the first open site not yet cleared, else the first head not yet beaten whose
## sites are; [tier, a head?], or [-1, false] when nothing open stands (a site shut for the level is no wall: a level
## comes from farming).
func wall_at(sim) -> Array:
	for i in range(Data.TIERS.size()):
		if not sim.tier_open(i):
			continue
		if int(sim.best_depth[i]) <= 0:
			return [i, false]
		var b: Dictionary = sim.boss_of(i)
		if not b.is_empty() and not sim.bosses_beaten[int(b["zone"])]:
			return [i, true]
	return [-1, false]


## The odds the runner out reads at the wall: a head armed for the read (0 when the notes for him aren't there).
func wall_odds(sim, wall: Array) -> float:
	var i: int = int(wall[0])
	if i < 0:
		return 0.0
	if not bool(wall[1]):
		return sim.survival(i)
	var was: bool = sim.boss_armed.get(i, false)
	if not was:
		if not sim.can_arm_boss(i):
			return 0.0
		sim.arm_boss(i, true)
	var o: float = sim.survival(i)
	if not was:
		sim.arm_boss(i, false)
	return o


## A pick noted (the step's): a first clear or a head at FIRST or better is a step forward; anything else, the wall's
## clock runs. The target's level is watched here too (its levelling keeps it out).
func wall_note(sim, t: int) -> void:
	if sim.cls != _wall_cls:
		_wall_cls = sim.cls
		_wall_from = -1.0                 # a new runner out: its own clock
	if target_cls != "" and sim.cls == target_cls and sim.level() != _tgt_lv:
		_tgt_lv = sim.level()
		_tgt_lv_at = sim.elapsed
	var head: Dictionary = sim.boss_of(t) if t >= 0 else {}
	var head_new: bool = t >= 0 and bool(sim.boss_armed.get(t, false)) and not head.is_empty() and not sim.bosses_beaten[int(head["zone"])]     # a beaten head farmed is no step (the review)
	if sim.level() < _wall_grace_lv or (t >= 0 and (int(sim.best_depth[t]) <= 0 or head_new) and pick_odds(sim, t) >= FIRST):     # a fallback under FIRST is no step (the fix round: it stopped the clock for good)
		_wall_from = -1.0
	elif _wall_from < 0.0:
		_wall_from = sim.elapsed


## The odds a pick went in at: the site as pick_tier left it (a head armed or not), read from its memo.
func pick_odds(sim, t: int) -> float:
	return sim.survival(t)


## The read's own target out and a level up in the last WALL_S: still growing, so not walled away (the fix round).
## The read's own build still levelling isn't walled away - for one more wall's clock at most (the fix round's merge: a
## farming target levels for hours, and a 10 h read sat at the Bank the whole read with no wall).
var _tgt_exempt_from := -1.0
func target_levelling(sim) -> bool:
	if not (target_cls != "" and sim.cls == target_cls and sim.elapsed - _tgt_lv_at < WALL_S):
		_tgt_exempt_from = -1.0
		return false
	if _tgt_exempt_from < 0.0:
		_tgt_exempt_from = sim.elapsed
	return sim.elapsed - _tgt_exempt_from < WALL_S


## Another played class's odds at the wall, read on a copy of the camp (the review: a trial swap on the real one sold
## spares, spent cash, healed the bench and reset the lorry's read): that class out, its kit looked over, at full HP.
## The bot's own state is put back after. A swap, not the game's read_as_class: the wall asks what the class would do
## swapped in and tidied - its own stash tabs, the crew's floor's points trained - which a read can't give without moving
## the camp; the read itself goes through read_as_class on the copy, at the floor and rested (30 Oct, refactor 2).
func class_wall_odds(sim, name: String, wall: Array) -> float:
	var c = sim.get_script().new()
	c.load_dict(sim.to_dict())
	c.fast_memo = sim.fast_memo
	c.odds_runs_max = sim.odds_runs_max
	var keep := {"cls": cls, "element": element, "keystones_first": keystones_first, "builds": builds.duplicate(true), "lorry_ok": lorry_ok,
		"lorry_read_at": lorry_read_at, "_farm_at": _farm_at, "_tidied_at": _tidied_at, "_tidied_runner": _tidied_runner, "crew_swaps": crew_swaps}
	var n_bought: int = bought.size()
	var o := 0.0
	if name == c.cls or _crew_out(c, name, true):
		_tidy_kit(c)
		o = float(c.read_as_class(c.cls, func() -> float: return wall_odds(c, wall), true, true))
	for k in keep:
		set(k, keep[k])
	bought.resize(n_bought)
	return o


## The wall's clock run out: the class that reads it best goes out. True when the runner out changed.
func wall_check(sim) -> bool:
	if not wall_on or sim.campaign_done() or sim.on_mission() or _wall_from < 0.0 or sim.elapsed - _wall_from < WALL_S:
		return false
	_wall_from = sim.elapsed                  # the next look a clock from now, swap or not
	if target_levelling(sim):
		return false                          # the read's own build still levelling: it farms on (the fix round)
	var wall: Array = wall_at(sim)
	if int(wall[0]) < 0:
		return false
	var from: String = sim.cls
	var cur_odds: float = class_wall_odds(sim, from, wall)     # the one out read on the copy too (the review: a head armed on the real camp logs)
	var best := ""
	var best_odds := -1.0
	for name in sim.crew_played():
		if name == from:
			continue
		var o: float = class_wall_odds(sim, name, wall)
		if o > best_odds:
			best_odds = o
			best = name
	var to := ""
	if best != "" and best_odds >= FIRST:
		to = best                             # a played class that takes it
	else:
		for name in CREW_BUILDS:
			if name != from and not (name in sim.crew_played()) and sim.class_open(name):
				to = name                     # a new one, to grow on the cleared sites
				best_odds = -1.0
				break
		if to == "" and best != "" and best_odds > cur_odds + 0.05:
			to = best                         # none takes it and none new: the class nearest to it
	var new_one: bool = not (to in sim.crew_played())
	var from_lv: int = sim.level()
	if to == "" or not _crew_out(sim, to):
		return false
	_wall_cls = to
	_wall_from = -1.0
	_wall_grace_lv = from_lv if new_one else 0
	_walled[from] = {"lv": from_lv, "at": sim.elapsed}     # read again when it levels or a clock from now (wall_return)
	_walled.erase(to)
	walls.append([snappedf(sim.elapsed / 3600.0, 0.01), int(wall[0]), bool(wall[1]), from, to, snappedf(best_odds, 0.01), snappedf(cur_odds, 0.01)])
	bought.append([sim.elapsed, "crew: walled at %s %d - %s out (%s)" % ["head on" if wall[1] else "site", int(wall[0]), to, "%.0f%%" % (best_odds * 100.0) if best_odds >= 0.0 else "new"]])
	return true


## A class walled away read again (the fix round): when it has levelled, or WALL_S since its last read, its odds at the
## wall as it stands now, on a copy of the camp; back out when they read FIRST or better (the one out set aside, not
## walled). Not over the target while it's still levelling. True when the runner out changed.
func wall_return(sim) -> bool:
	if not wall_on or _walled.is_empty() or sim.campaign_done() or sim.on_mission() or target_levelling(sim):
		return false
	var wall: Array = wall_at(sim)
	if int(wall[0]) < 0:
		return false
	for name in _walled.keys():
		if name == sim.cls:
			_walled.erase(name)               # back out some other way (the crew, the target): no longer walled
			continue
		var rec: Dictionary = _walled[name]
		var lv: int = sim.crew_level(name)
		if lv <= int(rec["lv"]) and sim.elapsed - float(rec["at"]) < WALL_S:
			continue
		rec["lv"] = lv
		rec["at"] = sim.elapsed
		var o: float = class_wall_odds(sim, name, wall)
		if o < FIRST:
			continue
		var from: String = sim.cls
		var cur_odds: float = class_wall_odds(sim, from, wall)
		if not _crew_out(sim, name):
			continue
		_walled.erase(name)
		_wall_cls = name
		_wall_from = -1.0
		_wall_grace_lv = 0
		walls.append([snappedf(sim.elapsed / 3600.0, 0.01), int(wall[0]), bool(wall[1]), from, name, snappedf(o, 0.01), snappedf(cur_odds, 0.01)])
		bought.append([sim.elapsed, "crew: %s back at %s %d (%.0f%%)" % [name, "head on" if wall[1] else "site", int(wall[0]), o * 100.0]])
		return true
	return false


## The target build out the hour its class opens (the one-save read); a read that starts as its target has it taken
## from the first step (the fix round, H4: the Poacher's reads took it back on the step after their first wall swap).
func take_target(sim) -> void:
	if target_cls == "" or _target_taken or sim.on_mission():
		return
	if sim.cls == target_cls:
		_target_taken = true
		return
	if sim.class_open(target_cls):
		builds[target_cls] = {"element": target_el, "keystones_first": false}
		if _crew_out(sim, target_cls):
			_target_taken = true              # the build the read is for, from the hour its class opens
			bought.append([sim.elapsed, "the target: %s as %s, opened" % [target_cls, target_el]])


## The campaign done: the read's own build back out for the endgame, once (the review).
func wall_home(sim) -> void:
	if wall_on and not _wall_home and _target_taken and sim.campaign_done() and not sim.on_mission():
		_wall_home = true
		_walled.clear()
		if sim.cls != target_cls:
			_crew_out(sim, target_cls)


func step(sim) -> int:
	sim.loot_by_hand = false                  # the bot takes what it finds as it goes (13 Oct: the floor is the player's)
	after_death(sim)                          # a death since the last step: every odds figure read again before it goes (BUILD41)
	take_target(sim)
	wall_home(sim)
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
	var fetched: bool = expeditions_on and not sim.on_mission() and _expeditions(sim)     # the expeditions (29 Oct): a hold-up fought is this step's run
	t0 = _lap("step/expeditions", t0)         # every step (the tools review's C8: the sends' reads were booked to the next lap)
	if fetched:
		t = int(sim.mission["tier"])
		last_tier = -1
	var okey: String = _pick_order(sim) if sim.campaign_done() and not fetched else ""
	var o_beaten: int = int(sim.order_beaten.get(okey, 0)) if okey != "" else 0
	if okey != "":
		var o_lv: int = sim.order_level(okey)
		var o_ins: int = order_insure_cost(sim, okey)
		if insure_for(sim, sim.is_county(okey), o_ins):
			sim.set_insure(true)                 # the County's runs insured when it can be afforded (BUILD41)
		if not sim.deploy_order(okey):
			sim.set_insure(false)                # the paper's not left armed for the next run (the review)
		else:
			t = int(Data.pinnacle(okey)["site"])
			last_tier = -1
			bought.append([sim.elapsed, "ran %s at level %d" % [str(Data.pinnacle(okey)["place"]), o_lv]])
			_order_ran = okey
			_order_beaten0 = o_beaten
		t0 = _lap("step/order", t0)
	if t < 0 and not fetched and sim.campaign_done() and sim.room_open("radio"):
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
			if insure_for(sim, false, ins):
				sim.set_insure(true)             # three times the price in hand; half again with the kit a big share of the DPS (BUILD41)
			var sg_lv: int = sim.signal_level(sim.signal_at(k))
			var sg_tags: String = _sig_tags(sim.signal_at(k))
			var sg_odds: float = float(sim.signal_odds(k)[0])
			if not sim.deploy_signal(k):
				sim.set_insure(false)
				t = -1
			else:
				ran_signal = [sg_lv, sg_odds, sim.reach, sg_tags]
	if t < 0 and not fetched:
		if wall_on and (wall_return(sim) or wall_check(sim)):
			_tidy_kit(sim)                    # the class out wears its own kit before its pick
		t = pick_tier(sim)
		last_tier = t
		if wall_on and not sim.campaign_done():
			wall_note(sim, t)
		t0 = _lap("step/pick_tier", t0)
		if repeat_ok(sim) and sim.can_repeat(t) and sim.start_repeat(t):
			_repeat_out(sim)                  # farmed unwatched: the repeat's runs, then the report put away
			_lap("step/repeat", t0)
			return t
		if wagers_on and sim.wager_site_open(t):
			var wk: String = sim.wager_site_key(t)
			for k in range(sim.wager_offer(wk).size()):
				sim.take_wager(wk, k)
		sim.deploy(t)
	t0 = _lap("step/deploy", t0)
	var guard := 0
	while sim.on_mission() and guard < 3000:
		sim.advance(1.0)
		if sim.on_mission():
			_wear_ups(sim)                    # an upgrade found worn there and then, by the swap (1 Nov)
		if sim.on_mission() and sim.event_asking():
			sim.event_by_orders()             # a run event (1 Nov): the bot goes by the standing orders, as a repeat run does
		if sim.on_mission() and sim.hp < sim.max_hp() * 0.4 and sim.mission["using"] == null and not sim.first_med().is_empty():
			sim.use_med(sim.first_med()["id"])
		if sim.on_mission() and should_leave(sim) and not sim.mission.get("way_out", false):
			if sim.hp < sim.max_hp() * 0.25:
				bails += 1
			sim.get_out()                     # the player's button: before the clear, the way out (10 Oct)
		guard += 1
	if sim.on_mission():
		sim.extract_now()                 # never back with a run still on: the yard would stand still
	if _order_ran != "":
		order_done(sim, _order_ran, int(sim.order_beaten.get(_order_ran, 0)) > _order_beaten0)
		_order_ran = ""
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
var _order_ran := ""                  # the place this step's run went to (BUILD45): its outcome counted after the run
var _order_beaten0 := 0


## The order's places and the County's (25 Oct, the Issue): read every ORDER_EVERY of the yard's time - a dry run is a
## head's long fight - and run one when it reads: a County place not yet taken, or the Mint before the Issue, at FIRST;
## any other at PUSH. The County's road first, then the Mint, then the deepest.
const ORDER_EVERY := 1800.0
var _order_read_at := -1e9
func _pick_order(sim) -> String:
	if sim.elapsed - _order_read_at < ORDER_EVERY:
		return ""
	_order_read_at = sim.elapsed
	var keys: Array = []
	for c in Data.COUNTY:
		keys.append(str(c["key"]))
	for p in Data.PINNACLES:
		keys.append(str(p["key"]))
	var best := ""
	var best_rank := -1
	for k in keys:
		if sim.order_block(k) != "" or order_backed_off(sim, k):
			continue
		var county: bool = sim.is_county(k)
		var first: bool = int(sim.order_beaten.get(k, 0)) == 0
		var need: float = FIRST if (first and (county or k == "mint" or (k == "grid" and not sim.issued))) else PUSH     # the Grid's key opens the Mint (the sixth pass)
		var rank: int = (2000 if county and first else (1000 if (k == "mint" or (k == "grid" and first)) and not sim.issued else 0)) + sim.order_level(k)
		if rank <= best_rank:
			continue
		var od: Array = settled_odds(func(): return sim.order_odds(k))     # a finished read only (BUILD41)
		if bool(od[1]) and float(od[0]) >= need:
			best = k
			best_rank = rank
	return best


## A place lost ORDER_LOSSES runs in a row is let be ORDER_BACK_OFF of the yard's time (BUILD45, probe45 #1: the
## Doorman ran the Toll Plaza 1,039 times, the Poacher the Golf Club 855, on a read that said 1.00). A loss is a run
## that didn't beat it: dead, or out by the way out; a win clears the count.
const ORDER_LOSSES := 2
const ORDER_BACK_OFF := 7200.0
var _order_lost := {}                 # place key -> runs lost in a row
var _order_off := {}                  # place key -> the yard's time it's read again


func order_done(sim, k: String, won: bool) -> void:
	if won:
		_order_lost.erase(k)
		return
	_order_lost[k] = int(_order_lost.get(k, 0)) + 1
	if int(_order_lost[k]) >= ORDER_LOSSES:
		_order_lost.erase(k)
		_order_off[k] = sim.elapsed + ORDER_BACK_OFF
		bought.append([sim.elapsed, "backed off %s for %.0f h: lost %d in a row" % [str(Data.pinnacle(k)["place"]), ORDER_BACK_OFF / 3600.0, ORDER_LOSSES]])


func order_backed_off(sim, k: String) -> bool:
	return sim.elapsed < float(_order_off.get(k, -1e9))


## Issued kit (25 Oct): a piece a slot from the Issuer once the town's on fiat, while three times its price is in hand
## (the County's first zones want them worn), a slot's piece bought again when the counter's is ten levels past it;
## worn whatever the score says. And a burn when the prices run past half again and the fiat's there four times.
func _issued(sim) -> void:
	if not sim.issued or sim.on_mission():
		return
	var slots: Array = issued_slots(sim)
	for u in Data.ISSUED:
		var sl: String = str(u["slot"])
		if not (sl in slots):
			continue                          # only what the next zone wants (Matt, 26 Oct: the build's gun stays on)
		var worn = sim.equipped.get(sl)
		if (sl in GUN_SLOTS or sl in stamp_only) and worn != null and not worn.get("issued", false):
			# the build's own gun stamped at the Bench, not swapped for his (Matt, 26 Oct: stamping for entry)
			if not worn.get("stamped", false) and sim.cash >= sim.stamp_price(worn) * 3.0 and sim.stamp(int(worn["id"])):
				bought.append([sim.elapsed, "stamped %s for %d fiat" % [sl, sim.stamp_price(worn)]])
			continue
		var have_lv: int = Items.ilvl(worn) if worn != null and worn.get("issued", false) else -100
		var offer: Dictionary = sim.issued_piece(sl)
		if Items.ilvl(offer) - have_lv < 10 or not sim.can_wear(offer):
			continue                          # nothing bought it can't wear (the pass, 26 Oct: 140 pieces for a level-1 runner)
		var price: int = sim.issued_price(sl)
		if sim.cash >= price * 3.0 and sim.buy_issued(sl):
			bought.append([sim.elapsed, "issued %s for %d fiat" % [sl, price]])
	_wear_issued(sim)
	if sim.circ_mult() > 1.5 and sim.can_burn() and sim.cash >= sim.burn_price() * 4.0 and sim.elapsed - _burnt_at >= BURN_EVERY:
		_burnt_at = sim.elapsed                # an hour between (the pass: 2,380 burns on one read)
		var paid: float = sim.burn_price()
		sim.burn()
		bought.append([sim.elapsed, "burnt %d fiat" % int(paid)])


const BURN_EVERY := 3600.0
var _burnt_at := -1e9


## The broken build's pieces on (a read of one): the set at its count and the unique, each rolled again at the item level
## the runner can wear and the reach drops when the one worn falls RENEW_UNDER levels short.
const RENEW_UNDER := 5
func holding() -> bool:
	return broken != "" or not hold.is_empty()


func _hold_broken(sim) -> void:
	var c: Dictionary = hold if not hold.is_empty() else Data.COMBOS.get(broken, {})
	if c.is_empty():
		return
	var lv: int = mini(Items.max_ilvl_for(sim.level()), maxi(1, sim.reach))
	var want := {}                             # slot -> [kind, def]
	var set_name := str(c.get("set", ""))
	var st: Dictionary = Items.set_named(set_name) if set_name != "" else {}
	for k in range(int(c.get("pieces", 0)) if not st.is_empty() else 0):
		want[str(st["pieces"][k]["slot"])] = ["set", st["pieces"][k]]
	var unique_slot := ""
	var rule := str(c.get("rule", ""))
	for u in (Data.UNIQUES if rule != "" else []):
		if str(u.get("rule", "")) == rule:
			want[str(u["slot"])] = ["unique", u]
			unique_slot = str(u["slot"])
			break
	var gun := str(c.get("gun", ""))
	if gun != "" and not want.has("Primary"):
		want["Primary"] = ["gun", gun]
	# kept from issued kit: the unique's slot and one real piece of the set (issued kit counts as the set's rest, Matt 26 Oct)
	var first_set := ""
	for k in range(int(c.get("pieces", 0)) if not st.is_empty() else 0):
		if str(st["pieces"][k]["slot"]) != unique_slot:
			first_set = str(st["pieces"][k]["slot"])
			break
	broken_slots = [unique_slot, first_set] + (["Primary"] if want.has("Primary") and want["Primary"][0] == "gun" else [])
	held_slots = want.keys()                  # every slot the build wants: kept off a run's swaps too (_wear_ups, the review)
	for sl in want:
		var worn = sim.equipped.get(sl)
		var kind: String = want[sl][0]
		var issued_in: bool = kind == "set" and sl != first_set and worn != null and worn.get("issued", false)
		if issued_in:
			continue                              # an issued piece holds the set's place here
		var fits := func(cand) -> bool:
			return cand != null and ((kind == "set" and str(cand.get("set", "")) == set_name and str(cand.get("slot", "")) == sl) or (kind == "unique" and str(cand.get("rule", "")) == rule)
				or (kind == "gun" and str(cand.get("slot", "")) == "Primary" and str(Items.base_of(cand).get("type", "")) == gun))
		if fits.call(worn) and Items.ilvl(worn) >= lv - RENEW_UNDER:
			continue
		# one in the stash first, the best of them still fresh (the review: a roll each time threw the fitted mounts away)
		var kept = null
		for st_it in sim.stash:
			if fits.call(st_it) and sim.can_wear(st_it) and Items.ilvl(st_it) >= lv - RENEW_UNDER and (kept == null or Items.score(st_it) > Items.score(kept)):
				kept = st_it
		if kept != null:
			sim.equip_item(kept["id"])
			sim._dry_memo.clear()
			continue
		var tier: int = sim.tier_for_level(lv)        # the depth's tier (the level's best since the itemisation, 29 Oct): a set piece or a unique found there is lifted to it (26 Oct: without it, the campaign's bases)
		var it: Dictionary = {}
		if kind == "set":
			it = Items.roll_set_piece(set_name, want[sl][1], sim.rng, lv, tier)
		elif kind == "unique":
			it = Items.roll_unique(want[sl][1], sim.rng, lv, tier)
		else:
			it = _roll_gun(sim, gun, lv, tier)
		if it.is_empty():
			continue
		sim.equipped[sl] = it
		sim._dry_memo.clear()
	if sim.equipped.get("Primary") == null:
		sim.equip_best("Primary")


## A hunted build's primary: one of its type, no common, rolled at the depth's tier and the item level (a find there).
func _roll_gun(sim, type: String, lv: int, tier: int) -> Dictionary:
	for k in range(200):
		var it: Dictionary = Items.roll("Primary", tier, sim.rng, 0.0, true, false, "", type, 0.33, 0, lv)
		if str(Items.base_of(it).get("type", "")) == type and sim.can_wear(it):
			return it
	return {}


## The newest issued piece of each slot worn (a broken build's slots kept for the build).
## The slots issued kit goes in (Matt, 26 Oct, the third review: the bot wore all six from the Issue on, so every
## post-Issue hour measured the issued kit): as many as the deepest open County zone wants, the helmet, rig, charm,
## armour and sidearm before the gun; a held build's slots kept.
const ISSUED_FIRST := ["Helmet", "Rig", "Charm", "Armour", "Secondary", "Primary"]
const GUN_SLOTS := ["Primary", "Secondary"]     # stamped rather than swapped
## Other slots whose own piece is stamped, never swapped for the Issuer's (BUILD45, probe45 #3: the gauntlet's tidy
## swapped the h20 Doorman's coat for the Issued plate at the Golf Club, HP 4,178 to 2,263). The gauntlet sets it; the
## bot's own play doesn't.
var stamp_only: Array = []
func issued_slots(sim) -> Array:
	var z := 0
	for k in range(Data.COUNTY_ZONES.size()):
		if sim.county_zone_open(k):
			z = k
	var want: int = sim.county_want(z)
	return ISSUED_FIRST.filter(func(sl): return not (sl in broken_slots)).slice(0, want)


## A stamped piece in a slot the next zone wants stays on (the review: a better gun swapped it out, the County shut till
## the bot paid to stamp again).
func _keep_stamped(sim, sl: String) -> bool:
	var w = sim.equipped.get(sl)
	return w != null and w.get("stamped", false) and sl in issued_slots(sim)


func _wear_issued(sim) -> void:
	var slots: Array = issued_slots(sim)
	for sl in Data.SLOTS:
		if sl in broken_slots or not (sl in slots):
			continue
		var own = sim.equipped.get(sl)
		if own != null and own.get("stamped", false):
			continue                              # a stamped piece of its own stays on
		if sl in stamp_only and own != null and not own.get("issued", false):
			continue                              # the gauntlet's build keeps its own (BUILD45)
		var best = null
		for it in sim.stash:
			if it.get("issued", false) and str(it.get("slot", "")) == sl and sim.can_wear(it) and (best == null or Items.ilvl(it) > Items.ilvl(best)):
				best = it
		var worn = sim.equipped.get(sl)
		if best != null and (worn == null or not worn.get("issued", false) or Items.ilvl(best) > Items.ilvl(worn)):
			_wear(sim, best)


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


## Whether the bot repeats now: switched on and the campaign done (the designer, 29 Oct: a person watches the campaign).
func repeat_ok(sim) -> bool:
	return repeats and not norepeat and sim.campaign_done()


## A repeat out: the world on a second at a time until they're back, the report's runs counted, the card put away.
func _repeat_out(sim) -> void:
	var guard := 0
	while sim.away() and guard < 200000:
		sim.advance(1.0)
		guard += 1
	var rep: Dictionary = sim.repeat_report
	var tot: Dictionary = sim.repeat_totals(rep)
	repeat_runs += int(tot["runs"])
	repeat_bails += int(tot["bails"])
	repeat_wounds += int(tot["wounds"])
	repeat_timeouts += int(tot["timeouts"])
	repeats_gone += 1
	last_repeat = tot
	bought.append([sim.elapsed, "repeat: %d runs at %s, %d bails, ended %s" % [int(tot["runs"]), str(Data.TIERS[int(rep.get("site", 0))]["name"]), int(tot["bails"]), str(rep.get("ended", ""))]])
	sim.repeat_seen()


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
	# after the clear, home when the clock left is under twice the door's gang, or the next patrol's, at the kill rate
	# (Matt, 26 Oct: "leave on a short clock" - a time-out loses the pack, two worn pieces and the win); every run, not
	# only a stay (the fix round, H2: a normal run sat the clock out waiting on its second gang)
	if _short_after_clear(sim, m):
		return true
	if stay_out > 0:
		return m["patrols"] >= stay_out       # a build's read: farm the patrols past a full pack, the stacks are the run's (26 Oct)
	return sim.pack_used(m) >= sim.capacity() or m["patrols"] >= 2 or sim.crates_done(m)


## The clock after the clear (should_leave's): under twice the door's gang, or the next patrol's, at the kill rate so far.
func _short_after_clear(sim, m: Dictionary) -> bool:
	if not m.has("clock") or int(m["remaining"]) > 0 or m.get("way_out", false):
		return false
	var used: float = float(m.get("clock_used", 0.0))
	var rate: float = float(m["kills"]) / used if used > 0.0 and int(m["kills"]) >= 4 else 0.0
	var door: float = float(sim.door_gang(m["t"])) / rate if rate > 0.0 else STAY_CLOCK_MIN
	var next_patrol: float = float(sim.PATROL_BASE + int(m["patrols"])) / rate if rate > 0.0 else STAY_CLOCK_MIN     # the next gang, a man bigger each time (the review)
	return float(m["clock"]) < maxf(maxf(door * 2.0, next_patrol), STAY_CLOCK_MIN)


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
	_issued(sim)
	_endgame(sim)
	_lap("endgame", t0)


## An upgrade found on a run worn there and then (1 Nov, BUILD42, Matt: "I'd just swap jackets"): off the floor by the
## sim's swap (wear_from_floor), what comes off left down, never shuffled through the pack - and one the auto-run put in
## the pack the same way (equip_from_pack: what comes off into the cells freed, else down). The slots a build holds (a
## broken build's, the type's and the element's gun) and the County's issued slots are the tidy's at home, as before.
## Each piece read once a run (a try-on each: the pass's time).
var _ups_seen := {}
var _ups_run := -1
func _wear_ups(sim) -> void:
	if int(sim.runs_total) != _ups_run:
		_ups_run = int(sim.runs_total)
		_ups_seen.clear()
	var m: Dictionary = sim.mission
	var fresh: Array = []
	for it in sim.floor_items() + m["found"]:
		if not _ups_seen.has(int(it["id"])):
			_ups_seen[int(it["id"])] = true
			if str(it.get("slot", "")) in Data.SLOTS:
				fresh.append(it)
	if fresh.is_empty():
		return
	var held: Array = broken_slots + issued_slots(sim) + (held_slots if holding() else [])     # every slot a held build wants (the review)
	if (keystones_first and TYPE_OF.has(sim.cls)) or element != "":
		held.append("Primary")
	for it in fresh:
		var id: int = int(it["id"])
		var sl: String = str(it["slot"])
		if sl in held or _keep_stamped(sim, sl) or not sim.is_upgrade(it):
			continue
		if sim.floor_items().has(it):
			sim.wear_from_floor(id)
		else:
			sim.equip_from_pack(id)


## The kit looked over: the best of everything fitted, the points spent, the mounts, the spares sold, the shop.
func _tidy_kit(sim) -> void:
	var t0 := Time.get_ticks_usec()
	for s in Data.SLOTS:
		if not (s in broken_slots) and not _keep_stamped(sim, s):     # a held build's slots stay its own (the review: the held gun rolled again every tidy); a stamped gun the zone needs stays on
			sim.equip_best(s)
	if keystones_first and TYPE_OF.has(sim.cls) and not ("Primary" in broken_slots) and not _keep_stamped(sim, "Primary"):
		_hold_the_type(sim, TYPE_OF[sim.cls])
	if element != "" and not ("Primary" in broken_slots) and not _keep_stamped(sim, "Primary"):
		_hold_the_element(sim)
	_wear_issued(sim)                         # issued kit stays on (the County wants it worn)
	if holding():
		_hold_broken(sim)
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
	if holding():
		_hold_broken(sim)                      # after the shop too (the review: its equip_best took the build off)
	_lap("shop", t0)


## The endgame's business: the exchange for what a build is short of, the map's points
## spent, the mate's unique when the notes are there twice over, the bench
## adding an affix to what's worn when notes are spare.
func _endgame(sim) -> void:
	_exchange_short(sim)
	# the rebuild (18 Oct, docs/design/rebuild.md §7): the cheapest place it can build, by the materials it wants - the
	# Mint first once the Grid's key is in hand (Matt, 26 Oct, the sixth pass: 3 reads of 24 built it, the cheaper places
	# taking its ledgers and army kit), nothing else spending what it wants till it stands
	var mint_wants := {}
	if sim.rebuild_rank("mint") == 0 and sim.held_of("grid_key") > 0:
		if sim.can_rebuild("mint") and sim.rebuild_place("mint"):
			bought.append([sim.elapsed, "rebuilt mint to rank 1"])
		else:
			mint_wants = sim.rebuild_cost("mint")
	var cheapest := ""
	var least := 1 << 30
	for r in Data.REBUILDS:
		if not mint_wants.is_empty() and sim.rebuild_cost(r["key"]).keys().any(func(m): return mint_wants.has(m)):
			continue
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
			_bin_streak += 1
	if sim.reach > _reach_seen:
		_reach_seen = sim.reach
		_bin_streak = 0                           # the reach moved: back to full signals
	var n_papers: int = _papers_now()
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
			if plain.size() < n_papers and not sim.signals.is_empty():     # plain holds every plain paper when there are under PILE_TOP
				break                         # short of three with a signal held: wait for the rest (20 Oct: one or two only when there's nothing to run)
			ids = plain.slice(0, n_papers).map(func(x): return int(x["id"]))
		if sim.decrypt(ids).is_empty():
			break
		if ids.size() == 1 and _bin_streak > STUCK_BINS:
			_bin_streak -= 1                       # a Faint one made: after a few, Clear ones again (the kit's had its chance to catch up)
		bought.append([sim.elapsed, "a signal from %d paper%s: level %d" % [ids.size(), "" if ids.size() == 1 else "s", sim.signal_level(sim.signals.back())]])


## Papers a signal (Matt, 27 Oct: the bot stuck at reach 31 binned 1,100 Full signals at 0%): three, as a player makes
## them; after STUCK_BINS binned in a row with the reach standing, two (Clear: the reach to five under); after twice
## that, one (Faint: under the reach, for the kit and the papers home). The reach moving resets it.
func _papers_now() -> int:
	if _bin_streak >= STUCK_BINS * 2:
		return 1
	if _bin_streak >= STUCK_BINS:
		return 2
	return Data.SIGNAL_PAPERS


## The held signal to run: the deepest that reads PUSH (Kev's at a head's odds, FIRST); -1 for none - the campaign's
## sites farmed meanwhile, for the kit and the papers. Three held and none to run: _make_signals bins the worst (D2).
func _pick_signal(sim) -> int:
	var best := -1
	var odds: Array = []                      # each held signal's read, finished (BUILD41: a pending read is waited out, never run on)
	for k in range(sim.signals.size()):
		var kk: int = k
		var od: Array = settled_odds(func(): return sim.signal_odds(kk))
		odds.append(float(od[0]) if bool(od[1]) else -1.0)
	for k in range(sim.signals.size()):
		var sg: Dictionary = sim.signal_at(k)
		var o: float = odds[k]
		var need: float = FIRST if int(sg.get("story", -1)) >= 0 else PUSH
		if o >= need and (best < 0 or sim.signal_level(sg) > sim.signal_level(sim.signal_at(best))):
			best = k
	if best < 0 and sim.signals.size() >= Data.SIGNALS_HELD:
		# the reach as a player meets it (the pass, 20 Oct): nothing to win sure, so the full one at the reach at a coin flip;
		# past level 50, with the paragon's XP and the kit at stake, at SAFE_PAST_CAP (BUILD41)
		var best_o := coin_bar(sim)
		for k in range(sim.signals.size()):
			var sg: Dictionary = sim.signal_at(k)
			var o: float = odds[k]
			if int(sg.get("grade", 0)) == 3 and int(sg.get("story", -1)) < 0 and sim.signal_level(sg) >= sim.reach and o >= best_o:
				best = k
				best_o = o
	return best


## The coin flip's bar: COIN, or SAFE_PAST_CAP past level 50 (BUILD41: the paragon's XP and the kit at stake).
func coin_bar(sim) -> float:
	return maxf(COIN, SAFE_PAST_CAP) if sim.level() >= Data.MAX_LEVEL else COIN


## An odds read finished before the bot acts on it (BUILD41, PROBE40 4: runs set off on a read not settled): `read`
## returns [odds, settled]; it's read again till settled, SETTLE_TRIES at most. [odds, settled].
func settled_odds(read: Callable) -> Array:
	var r: Array = read.call()
	var n := 0
	while not bool(r[1]) and n < SETTLE_TRIES:
		r = read.call()
		n += 1
	return r


## The share of the DPS a death would take with the kit (BUILD41): the worn pieces a death loses (not issued, not a
## mythic) swapped for the best the stash holds for the slot - what the next runner would wear (the review: against a
## bare runner even the starter kit read 0.75, and every signal was insured); a slot with nothing spare reads the
## starter piece the next runner brings (Sim._starter_loadout; the re-review) - for the read, then put back.
var _starter := {}
func _starter_kit(sim) -> Dictionary:
	if _starter.is_empty():
		# the starter's pieces made once on dice of their own, the camp's dice and item ids left as they were
		var rng_was = sim.rng
		var id_was: int = Items._next_id
		sim.rng = RandomNumberGenerator.new()
		var eq_was: Dictionary = sim.equipped.duplicate()
		var rig_was: Array = sim.rig.duplicate()
		sim._starter_loadout()
		for sl in Data.SLOTS:
			if sim.equipped.get(sl) != null and sim.equipped[sl] != eq_was.get(sl):
				_starter[sl] = sim.equipped[sl]
		sim.equipped = eq_was
		sim.rig = rig_was
		sim.rng = rng_was
		Items._next_id = id_was
	return _starter


func stake_share(sim) -> float:
	var full: float = sim.dps()
	if full <= 0.0:
		return 0.0
	var off := {}
	for sl in Data.SLOTS:
		var w = sim.equipped.get(sl)
		if w != null and not w.get("issued", false) and not w.get("mythic", false):
			off[sl] = w
	if off.is_empty():
		return 0.0
	var spare := {}
	for sl in off:
		var best = null
		var best_v := -INF
		for it in sim.stash:
			if it is Dictionary and str(it.get("slot", "")) == sl and sim.can_wear(it):
				var v: float = sim.fit_value(it, sl)
				if best == null or v > best_v:
					best = it
					best_v = v
		spare[sl] = best if best != null else _starter_kit(sim).get(sl, null)
	for sl in off:
		sim.equipped[sl] = spare[sl]
	sim._dry_memo.clear()
	var bare: float = sim.dps()
	for sl in off:
		sim.equipped[sl] = off[sl]
	sim._dry_memo.clear()
	return clampf(1.0 - bare / full, 0.0, 1.0)


## Whether a run is insured (BUILD41): a County run, or one with STAKE_SHARE of the DPS at stake, when INSURE_SPARE_STAKE
## times the price is in hand; any other at three times, as before. `cost` -1: it can't be.
func insure_for(sim, county: bool, cost: int) -> bool:
	if cost < 0:
		return false
	if sim.cash >= cost * 3:
		return true
	return (county or stake_share(sim) >= STAKE_SHARE) and sim.cash >= cost * INSURE_SPARE_STAKE


## An order's insurance at its own depth, as deploy_order charges it, or -1 when it can't be insured.
func order_insure_cost(sim, k: String) -> int:
	if sim.order_block(k) != "":
		return -1
	var sg: Dictionary = sim.order_sig(k)
	sim._sig_on(sg)
	var i: int = int(sg["site"])
	var c: int = sim.insure_cost(i) if sim.can_insure(i) else -1
	sim._sig_off()
	return c


## After a death (BUILD41, PROBE40 4: 32 of the Doorman's 91 came on the first or second run after one): every odds
## figure the bot holds is the dead runner's - the signals' and the sites' reads cleared, the lorry's read again - so the
## next run goes on a read of the kit the new runner has. The orders are read afresh at their next ORDER_EVERY, not at
## once (BUILD45, probe45 #1: at once, a place that read 1.00 was run again the minute after each death).
var _lost_seen := -1
func after_death(sim) -> bool:
	if _lost_seen < 0:
		_lost_seen = int(sim.operators_lost)
		return false
	if int(sim.operators_lost) == _lost_seen:
		return false
	_lost_seen = int(sim.operators_lost)
	sim._sig_odds.clear()
	sim._surv_cache.clear()
	lorry_ok = false
	lorry_read_at = -1e9
	return true                               # the orders' ORDER_EVERY kept (BUILD45, probe45 #1: reset here, a death re-ran the place at once)


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
const BENCH_SLOTS := ["Primary", "Armour", "Helmet", "Gloves", "Charm", "Rig", "Secondary"]     # the gloves (29 Oct): read by _power, pace and the reloads in
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
	var floor_cash := maxf(sim.tins_now(2000.0), _reserve(sim))
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
		if c >= 0 and sim.cash - c >= maxf(sim.tins_now(2000.0), _reserve(sim)) and sim.craft(it["id"], "socket"):
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
		if cost < 0 or sim.cash - cost < maxf(sim.tins_now(2000.0), _reserve(sim)) or not sim.craft(it["id"], kind, stat):
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
func _elem_share(it: Dictionary, sim = null) -> float:
	var sh: float = _elem_share_of(it, element, sim)
	if as_played:
		var own: Array = own_elements(cls, element)
		if own.size() > 1 and str(own[0]) == element:
			sh += AS_PLAYED_SECOND * _elem_share_of(it, str(own[1]), sim)     # the class's other element (BUILD34): read too, at half
	return sh


## As played, the class's second element's share in the gun's compare: half the build's own (BUILD34) - the build's element
## first, the other still worth carrying.
const AS_PLAYED_SECOND := 0.5


func _elem_share_of(it: Dictionary, el: String, sim = null) -> float:
	if str(it.get("rule", "")) == "weed_burner":
		return 1.0 if el == "fire" else -0.45     # all fire: an element build's own element switched off (25 Oct, the review: on 11 of 24 end kits)
	if el == "physical":
		# the physical build (Knuckles, 9 Oct): the share of the gun's hit that isn't converted
		var conv := 0.0
		for ty in Data.ELEMENTS:
			var st := "conv_%s_pct" % ty
			conv += float(Items.base_of(it).get(st, 0)) + Items.affix_total(it, st) + Items.fitted_sum(it, st)
		conv += _rounds_conv_total(it, sim)     # one grade fires at a time: the most converting magazine, not each element's best
		return maxf(1.0 - Data.CONV_CAP, 1.0 - conv / 100.0)     # the physical floor (31 Oct): a tenth stays physical, as the game's conversion
	var stat := "conv_%s_pct" % el
	var s := float(Items.base_of(it).get(stat, 0))
	s += Items.affix_total(it, stat)
	s += Items.fitted_sum(it, stat)
	s += _rounds_conv(it, stat, sim)
	return minf(Data.CONV_CAP, s / 100.0)     # no more of a hit than the game converts (the physical floor, 31 Oct)


## The conversion a gun gets from the rounds its magazines hold (31 Oct, PROBE33: hollow point's bleed, incendiary's fire
## went uncounted, a melee base's own counted): the most of the stat among the rig's loaded magazines that fit it - the
## same for the worn gun and a spare (the reviewer: feed_stack puts the element first for the worn primary only, so a
## spare of the same gun read a lower share). 0 for a blade.
func _rounds_conv(it: Dictionary, stat: String, sim) -> float:
	if not Items.is_gun(it) or Items.mag_size(it) <= 0 or sim == null:
		return 0.0
	var best := 0.0
	for mg in sim.mags_for(it):
		if int(mg.get("rounds", 0)) > 0:
			best = maxf(best, float(Items.grade_base(mg).get(stat, 0)))
	return best


## The most total conversion any one loaded magazine that fits the gun carries (the physical build's read: a gun fires
## one grade at a time, so a Salted and an Incendiary magazine aren't 60% between them).
func _rounds_conv_total(it: Dictionary, sim) -> float:
	if not Items.is_gun(it) or Items.mag_size(it) <= 0 or sim == null:
		return 0.0
	var best := 0.0
	for mg in sim.mags_for(it):
		if int(mg.get("rounds", 0)) > 0:
			var t := 0.0
			for el in Data.ELEMENTS:
				t += float(Items.grade_base(mg).get("conv_%s_pct" % el, 0))
			best = maxf(best, t)
	return best


func _elem_score(it: Dictionary, sim = null) -> float:
	return Items.score(it) * (1.0 + ELEM_WEIGHT * _elem_share(it, sim))


## A piece on as the Kit would put it on (the fix round, 29 Oct, the game review's C7): "Swap, parts and all" when the worn
## one's parts go onto it, else a plain equip.
static func _wear(sim, it: Dictionary) -> void:
	if sim.swap_moves(it) and sim.swap_with_parts(int(it["id"])):
		return
	sim.equip_item(int(it["id"]))


func _hold_the_element(sim) -> void:
	var cur = sim.equipped["Primary"]
	var best := {}
	for it in sim.stash:
		if it["slot"] == "Primary" and sim.can_wear(it) and (best.is_empty() or _elem_score(it, sim) > _elem_score(best, sim)):
			best = it
	if best.is_empty():
		return
	if cur == null or (_elem_score(best, sim) > _elem_score(cur, sim) and sim.fit_value(best, "Primary", -1, sim.swap_moves(best)) >= sim.damage_total() * ELEM_DPS_FLOOR):
		_wear(sim, best)        # D23: the element's gun, but not at a fifth less damage, read on a try-on - a shock Scrapper took one at half at an hour and held the Estate's wall for twenty


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
		_wear(sim, best)


## A site with nothing to open (28 Oct, the crates remembered): every crate taken and none back yet on the trickle.
static func picked_clean(sim, i: int) -> bool:
	var st: Array = sim.site_stock(i)
	return not st.is_empty() and Array(st[0]).size() + int(st[1]) == 0


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
		for pass_i in range(2):                  # a site picked clean is passed over for one with crates to open (28 Oct), unless none holds
			for i in order:
				if pass_i == 0 and picked_clean(sim, i):
					continue
				if sim.survival(i) >= PUSH:      # every site at its campaign self (15 Oct): the highest that holds, for its papers
					best = i
					break
			if best >= 0:
				break
	if best < 0:
		var found := false
		var clean_fallback := -1
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
					found = true                 # a head to fight is never swapped for a fallback (the review)
					break
				sim.arm_boss(i, false)
			var odds: float = sim.survival(i)
			if odds >= (FIRST if sim.best_depth[i] <= 0 else PUSH):     # a first clear at a person's odds; what's cleared, farmed at PUSH
				if sim.best_depth[i] > 0 and picked_clean(sim, i):
					if clean_fallback < 0:
						clean_fallback = i      # farmed and picked clean (28 Oct): the next site down that holds, this one if none
					continue
				best = i
				found = true
				break
			if odds >= best_odds:
				best_odds = odds                  # ties to the lower tier: the old fallback was the lowest open tier
				best = i
		if not found and clean_fallback >= 0:
			best = clean_fallback
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
## The exchange (28 Oct: the Fence's contracts gone for it), used sparingly: the salvage a Yard pick or rank is short
## of when its tins are there, and the materials the nearest rebuild is short of, bought with tins - only what's short,
## only out of a quarter of the cash, never into the reserve or the build's own price.
const EXCHANGE_CASH_SHARE := 0.25
func _exchange_short(sim) -> void:
	if sim.on_mission() or not sim.room_open("fence"):
		return
	var wants: Array = []                     # [currency, short, tins the build itself still needs]
	# the steps _build_yard would buy (28 Oct, the review: every open column's both sides turned tins into salvage the
	# bot wouldn't spend for hours): its own line's next step; the other line's once its own are as far as they open
	var own_left: bool = Data.YARD.any(func(yb): return _line_next_open(sim, yb, BOT_LINE.get(yb["key"], "a")))
	for b in Data.YARD:
		var key: String = b["key"]
		var kind: String = b["salvage"]
		var own: String = BOT_LINE.get(key, "a")
		for side in ([own] if own_left else [own, "b" if own == "a" else "a"]):
			var c: int = _next_step(sim, b, side)
			if c >= 0 and c < sim.yard_cols() and sim.yard_pick_block(key, c, side).begins_with("Wants"):
				wants.append([kind, sim.yard_pick_salvage(key, c) - int(sim.salvage.get(kind, 0)), sim.yard_pick_cost(key, c)])
		if sim.yard_rank_block(key).begins_with("Wants"):
			wants.append([kind, sim.yard_rank_salvage(key) - int(sim.salvage.get(kind, 0)), sim.yard_rank_cost(key)])
	if sim.rebuild_open():
		var least := 1 << 30
		var near := {}
		for r in Data.REBUILDS:
			var cost: Dictionary = sim.rebuild_cost(r["key"])
			var short := {}
			var n := 0
			for m in cost:
				var gap: int = int(cost[m]) - sim.held_of(m)
				if gap > 0:
					short[m] = gap
					n += gap
			if n == 0 or short.keys().any(func(m): return Data.KEY_ITEMS.has(m)):
				continue                          # built already, or a key item short: the exchange has none
			if n < least:
				least = n
				near = short
		for m in near:
			wants.append([m, int(near[m]), 0])
	var done := {}
	for w in wants:
		var cur: String = w[0]
		var need: int = int(w[1])
		if need <= 0 or done.has(cur) or not sim.exchange_offered().has(cur):
			continue
		var rate: float = sim.exchange_rate("tins", cur)
		if rate <= 0.0:
			continue
		var tins: int = int(ceil(need / rate))
		while sim.exchange_get("tins", cur, tins) < need:
			tins += 1
		if tins > sim.cash * EXCHANGE_CASH_SHARE or sim.cash - tins < _reserve(sim) + float(w[2]):
			continue
		if sim.exchange("tins", cur, tins):
			done[cur] = true
			bought.append([sim.elapsed, "exchange: %d tins for %d %s" % [tins, need, cur]])


func _reserve(sim) -> float:
	return sim.treat_cost() * 3.0     # nothing when whole: the bench keeps its own £2,000 floor (the Lorry watch's saving went 28 Oct, the review: it was 0 since 15 Oct)


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


## The skill web (3 Nov): the bot buys toward an ordered list of target nodes (web_targets) by the shortest path
## (Sim.web_path), one point at a time; a target behind a gate (a keystone's 15 spent, a capstone's 40) waits while
## the points go to the next target, and comes back when the gate opens. With every target owned or shut, a free point
## goes on the nearest node it can take that costs the runner nothing (no drawback, no gun it hasn't got).
func _train_tree(sim) -> void:
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
	var targets: Array = web_targets(sim.cls, element)
	for _guard in range(400):
		if sim.points_free() <= 0:
			return
		var took := false
		for t in targets:
			if sim.web_owned(str(t)):
				continue
			var path: Array = sim.web_path(str(t))
			if path.is_empty():
				continue
			if sim.can_train(str(path[0])):
				sim.train_node(str(path[0]))
				took = true
				break
		if not took and not _spare_point(sim):
			return


## A free point with every target owned or behind its gate: the frontier's best node that asks nothing back - a notable
## first, then a small; never one with a cost (Night work's kind), a keystone or capstone off the plan, one typed for a
## gun not in hand, or another element's conversion.
func _spare_point(sim) -> bool:
	var best := ""
	var best_k := -1
	for id in sim.web_frontier():
		var nd: Dictionary = sim.node(str(id))
		if nd.get("cost", false) or nd.get("keystone", false) or nd.get("capstone", false) or sim.web_class_only(str(id)) != "":
			continue                          # nor another class's start or skill: no use to this one (merge 47)
		if nd.has("type") and not sim._active(nd):
			continue
		var eff: String = str(nd.get("effect", ""))
		if eff.begins_with("conv_") and eff != "conv_%s_pct" % element:
			continue                              # another element's conversion: it would thin the build's own
		var k: int = 1 if nd.get("notable", false) else 0
		if k > best_k:
			best_k = k
			best = str(id)
	return best != "" and sim.train_node(best)


## A class's build as targets on the web, in order (BUILD47-W): its element's flower (the pair's half there, its
## conversions, the centre notable) and that element's keystone; the class's pair half on that side and that flower's keystone; the centre's
## inner ring's life and Guard; the second element's flower - its pair half and centre notable (the class's other of
## AFFINITY; not its conversions, which thin the first's, nor its keystone, which can undo it - Bust them up ends every
## conversion); the class's capstone; then the first element's capstone. A plain build (no element) takes the first of the class's own two.
static func web_targets(c: String, el: String) -> Array:
	var two: Array = own_elements(c, el)
	if two.is_empty():
		return []
	var first: String = el if el != "" else str(two[0])
	var out: Array = []
	var firsts: Array = _element_targets(c, first)
	out.append_array(firsts.slice(0, firsts.size() - 1))      # the flower and its keystone; its capstone at the end
	var halves: Array = joint_halves(c, first)
	if not halves.is_empty():
		out.append(str(halves[0]))
		out.append(_flower_keystone(str(halves[0])))
	for id in Data.web_ids():
		if Data.web_slot(str(id)).begins_with("h") and str(_node_of(str(id)).get("effect", "")) in ["hp", "guard_pct"]:     # the inner ring's
			out.append(str(id))
	for e in two:
		if str(e) != first and first in two:                         # the class's other of its pair (an off-pair build has none)
			var second: Array = _element_targets(c, str(e))
			out.append(second[0])                                     # its flower: the pair's half and the centre notable - not its
			out.append(second[second.size() - 3])                    # conversions (they'd thin the first's), nor its keystone (Bust them up ends every conversion)
			var h2: Array = joint_halves(c, str(e))
			if not h2.is_empty():
				out.append(str(h2[0]))
	for id in Data.web_ids():
		if Data.web_kind(str(id)) == "capstone" and Data.web_region(str(id)) == "class:" + c:
			out.append(str(id))
	out.append(firsts[firsts.size() - 1])
	return out.filter(func(x): return str(x) != "")


## An element's targets for a class: the class's half there, the flower's conversions, its centre notable, its keystone,
## its capstone (last: web_targets puts it at the end).
static func _element_targets(c: String, el: String) -> Array:
	var et: Dictionary = Data.element_tree_of(el)
	var k := -1
	for i in range(Data.ELEMENT_TREES.size()):
		if Data.ELEMENT_TREES[i] == et:
			k = i
	if k < 0:
		return []
	var tn: String = str(et["name"])
	var slots: Array = []
	for id in Data.web_ids():
		if str(id).get_slice("/", 0) == tn:
			slots.append(Data.web_slot(str(id)))
	var pre: String = str(slots[0]).get_slice("_", 0)        # "e0"
	var halves: Array = joint_halves(c, el)
	var out: Array = [str(halves[1]) if not halves.is_empty() else ""]
	for i in range(8):                                        # the flower's conversions: what makes the build its element
		var o: String = Data.web_of_slot("%s_%d" % [pre, i])
		if str(_node_of(o).get("effect", "")).begins_with("conv_"):
			out.append(o)
	return out + [Data.web_of_slot(pre + "_n"), Data.web_of_slot(pre + "_ks"), Data.web_of_slot(pre + "_cap")]


## The keystone in the flower a node sits in ("k0_R6" -> the keystone among "k0_R*"), or "".
static func _flower_keystone(id: String) -> String:
	var sl: String = Data.web_slot(id)
	for i in range(8):
		var o: String = Data.web_of_slot(sl.substr(0, 4) + str(i))
		if o != "" and Data.web_kind(o) == "keystone":
			return o
	return ""


static func _node_of(id: String) -> Dictionary:
	var t: Dictionary = Data.tree_named(id.get_slice("/", 0))
	var i: int = int(id.get_slice("/", 1))
	return t["nodes"][i] if not t.is_empty() and i < t["nodes"].size() else {}


## A class's own two elements (Data.AFFINITY), the build's element first when it's one of them.
static func own_elements(c: String, first := "") -> Array:
	var two: Array = Array(Data.AFFINITY.get(c, [])).duplicate()
	if first in two:
		two.erase(first)
		two.push_front(first)
	return two


## A class's pair with an element: [its class tree's half, its element tree's half] as node ids, or [] (BUILD34).
static func joint_halves(c: String, el: String) -> Array:
	for j in Data.JOINTS:
		if str(j["class"]) == c and str(Data.tree_named(str(j["element_tree"])).get("element", "")) == el:
			return [_joint_node(str(j["tree"]), str(j["key"])), _joint_node(str(j["element_tree"]), str(j["key"]))]
	return []


static func _joint_node(tree_name: String, key: String) -> String:
	var t: Dictionary = Data.tree_named(tree_name)
	for i in range(t.get("nodes", []).size()):
		if str(t["nodes"][i].get("joint", "")) == key:
			return "%s/%d" % [tree_name, i]
	return ""


## The Yard's lanes (9 Oct; two lines a building, 28 Oct): each building's line in BOT_LINE, cheapest
## first, with £500 kept back; then a rank where one is open, with half its price again kept back.
const BOT_LINE := {"bench": "a", "stash": "a", "clinic": "a", "fence": "b", "radio": "a", "generator": "a", "lookout": "a", "kennel": "a", "bunkhouse": "a"}     # the Bunkhouse's repeat line (29 Oct)     # the line the bot climbs in each building (28 Oct, two lines a building: the lines that hold most of the picks it took before)
## The cheapest rank the Pitch could buy now (no rank open: a price past any).
func _cheapest_rank(sim) -> int:
	var out := 1 << 40
	for b in Data.YARD:
		if sim.can_yard_rank(b["key"]) or sim.yard_rank_block(b["key"]) == "Short of tins":
			out = mini(out, sim.yard_rank_cost(b["key"]))
	return out


func _build_yard(sim) -> void:
	# two lines a building (28 Oct): the bot climbs its line in each building (BOT_LINE), the cheapest next step first;
	# then the other lines' next steps at their dearer price; then ranks
	var best_key := ""
	var best_col := -1
	var best_side := ""
	var best_cost := 1 << 40
	for b in Data.YARD:
		var side: String = BOT_LINE.get(b["key"], "a")
		var c: int = _next_step(sim, b, side)
		if c >= 0 and sim.can_yard_pick(b["key"], c, side) and sim.yard_pick_cost(b["key"], c) < best_cost:
			best_key = b["key"]
			best_col = c
			best_side = side
			best_cost = sim.yard_pick_cost(b["key"], c)
	if best_key != "" and sim.cash >= best_cost + sim.tins_now(500.0):
		if sim.yard_pick(best_key, best_col, best_side):
			bought.append([sim.elapsed, "%s %s for £%d" % [best_key, Data.yard_building(best_key)["picks"][best_col][0 if best_side == "a" else 1]["id"], best_cost]])
		return
	var firsts_left := false
	for yb in Data.YARD:
		if _line_next_open(sim, yb, BOT_LINE.get(yb["key"], "a")):
			firsts_left = true
	if best_key == "" and not firsts_left:
		# every line it climbs is as far as it opens (its price or salvage aside - the review): the other lines, cheapest first, with half again in hand
		var sec_key := ""
		var sec_col := -1
		var sec_side := ""
		var sec_cost := 1 << 40
		for b in Data.YARD:
			var other: String = "b" if BOT_LINE.get(b["key"], "a") == "a" else "a"
			var c: int = _next_step(sim, b, other)
			if c >= 0 and sim.can_yard_pick(b["key"], c, other) and sim.yard_pick_cost(b["key"], c) < sec_cost:
				sec_key = b["key"]
				sec_col = c
				sec_side = other
				sec_cost = sim.yard_pick_cost(b["key"], c)
		if sec_key != "" and sim.cash >= sec_cost * 1.5 and sec_cost <= _cheapest_rank(sim):
			if sim.yard_pick(sec_key, sec_col, sec_side):
				bought.append([sim.elapsed, "%s %s (its other line) for £%d" % [sec_key, Data.yard_building(sec_key)["picks"][sec_col][0 if sec_side == "a" else 1]["id"], sec_cost]])
			return
	for b in Data.YARD:
		if sim.can_yard_rank(b["key"]) and sim.cash >= sim.yard_rank_cost(b["key"]) * 1.5:
			var cost: int = sim.yard_rank_cost(b["key"])
			if sim.buy_yard_rank(b["key"]):
				bought.append([sim.elapsed, "%s rank %d for £%d" % [b["key"], sim.yard_rank(b["key"]), cost]])
			return


## A line's next step is there to build, its price or salvage aside (as _build_yard's "firsts left" reads it).
static func _line_next_open(sim, b: Dictionary, side: String) -> bool:
	var c: int = _next_step(sim, b, side)
	return c >= 0 and c < sim.yard_cols() and not sim.yard_pick_block(b["key"], c, side).begins_with("Opens with")


## A line's next step to build: its first column not built on that side, or -1 when the line's done.
static func _next_step(sim, b: Dictionary, side: String) -> int:
	for c in range(b["picks"].size()):
		if not sim.yard_built_side(b["key"], c, side):
			return -1 if sim.yard_stub(b["key"], c, side) else c     # the Bunkhouse's line B (29 Oct): nothing to build till the Quartermaster
	return -1


## The rig for the next run (28 Oct, Matt: HEAL, MAGAZINE, CURE): the supplies handed in, the stash stocked - boxes
## for the guns at the Fence, a cure for each of the front's elements and a heal off the Clinic's shelf, as a player
## buys them (the review: the bot bought any med the list had, any number, off no shelf) - then packed by the gate's
## own packer (Sim._top_up, Sim.pack_rig), never by hand (30 Oct, review30 refactor 3: the balance reads measure the
## packing the player gets); a pouch still free, a heal off her shelf bought into the stash and the packer run again.
## The gate's packing, on "fill" whatever the save's setting (the clean-up's review: a save on "Leave it" left the bot's
## rig unpacked, and every restock bought a heal that never went in): the reads measure the packer a player gets by default.
func _pack(sim) -> void:
	if sim.on_mission():
		return
	sim._fill_mags()
	sim.pack_rig("fill", -1, false)           # the gate's own packing (BUILD48 A, item 24: no magazines past each gun's first)
	sim._fill_mags()                          # the newly packed magazines filled, as the gate does (30 Oct)
	sim.gate_box_always = true                # and its box for the refills at the gate, as "fill" packs it (the fix round, the designer's A)


func _restock_meds(sim) -> void:
	if sim.can_hand_in():
		sim.hand_in_supplies()                # the medic's supplies, as a person hands them over coming home (28 Oct)
	_restock_rounds(sim)
	_stock_cures(sim)
	if not sim.rig.any(func(x): return Items.is_heal(x)) and not sim.stash.any(func(x): return Items.is_heal(x)):
		_buy_shelf_heal(sim, sim.med_capacity() - sim.rig_used())
	_pack(sim)
	var guard := 0
	while sim.rig_room(1) and guard < 40:
		guard += 1
		var used: int = sim.rig_used()
		if not _buy_shelf_heal(sim, sim.med_capacity() - used):
			return
		_pack(sim)
		if sim.rig_used() == used:
			return                            # the packer took nothing more: the rig's as the gate leaves it


## The cheapest heal on the Clinic's shelf that fits so many pouches, bought into the stash (28 Oct, the review: her
## shelf, as the player buys; a bandage off no shelf till then). False when there's none, or the cash is short.
func _buy_shelf_heal(sim, pouches: int) -> bool:
	if pouches <= 0 or sim.cash < sim.tins_now(200.0) or not sim.room_open("clinic"):
		return false
	var best := {}
	for it in sim.clinic:
		if Items.is_heal(it) and Items.size(it) <= pouches and sim.cash >= sim.clinic_price(it) and sim.stash_fits(it):
			if best.is_empty() or sim.clinic_price(it) < sim.clinic_price(best) or (sim.clinic_price(it) == sim.clinic_price(best) and Items.size(it) < Items.size(best)):
				best = it
	return not best.is_empty() and sim.buy_clinic(int(best["id"]))


## A cure in the stash for each element the front's gangs throw that the rig hasn't one for (28 Oct, the cures): off
## the Clinic's shelf, the cheapest, as the player buys them.
func _stock_cures(sim) -> void:
	for ty in sim.zone_elements(sim.front_tier()).slice(0, Data.TOP_UP_CURES):
		if not sim.first_cure(ty).is_empty() or sim.stash.any(func(x): return Items.cure_of(x) == ty):
			continue
		if sim.cash < sim.tins_now(200.0) or not sim.room_open("clinic"):
			continue
		var best := {}
		for it in sim.clinic:
			if Items.cure_of(it) == ty and sim.cash >= sim.clinic_price(it) and sim.stash_fits(it) and (best.is_empty() or sim.clinic_price(it) < sim.clinic_price(best)):
				best = it
		if not best.is_empty():
			sim.buy_clinic(int(best["id"]))


## The cures stocked and packed, as the gate packs them (the smoke's fixture reads it alone).
func _pack_cures(sim) -> void:
	_stock_cures(sim)
	sim.pack_rig("fill", -1, false)           # as the gate packs (BUILD48 A, item 24)


## Rounds for both guns into the stash: two runs' worth for the primary, one for the secondary; bought by the box when
## the stash has none. The rig's packing is the gate's (Sim.pack_rig: a dry primary's first pouch before a cure or a
## spare heal, rounds neither gun fires back to the stash); the bot only buys.
func _restock_rounds(sim) -> void:
	for pair in [["Primary", 2.0], ["Secondary", 1.0]]:
		var gun = sim.equipped[pair[0]]
		if gun == null or Items.ammo_type(gun) == "none" or Items.free_rounds(gun):
			continue                          # a gun that spends nothing wants no rounds (18 Oct: the Weed Burner, the Spare Key)
		var type: String = Items.ammo_type(gun)
		# rounds for a run: the gun's rate over two minutes
		var want: int = int(Items.base_of(gun)["rof"] * 120.0 * pair[1])
		var guard := 0
		# magazines as items (30 Oct): standard magazines off the Fence's shelf for the pouches the gate packs (Sim.pack_rig,
		# at its share of the rig; the secondary of another type its one), then boxes for what they hold - the rounds the
		# run wants, as far as the magazines hold; a dry primary's bought with the rig full, the packer making its room
		var share: int = maxi(1, ceili(sim.med_capacity() * Data.RIG_MAG_SHARE)) if pair[0] == "Primary" else 1
		_buy_mags(sim, gun, share)
		var mag_room := 0
		for mg in sim.rig + sim.stash:
			if Items.mag_fits(mg, gun):
				mag_room += Items.mag_cap(mg, gun)
		# the magazines' fill and the gate's box for the refills, whatever the rig's free pouches (the three-stage review,
		# game 3: a box never goes in the rig now, so a full rig bought nothing and the gate packed what little was left)
		var need: int = mini(want, mag_room) - sim.rounds_for(gun) + int(sim.ammo_box(type).get("rounds", 0))
		while _stash_rounds(sim, type) < need and guard < 6:
			guard += 1
			if not sim.buy_ammo(type):
				if sim.stash_room(1):
					break
				# no room for the box: the cheapest spare goes - only when the box can be bought (the review: with the Fence
				# shut it binned a spare a pass, six a tidy, for nothing)
				if not sim.room_open("fence"):
					break
				var worst := {}
				for it in sim.stash:
					if Items.is_medical(it) or Items.is_ammo(it) or Items.is_mag(it) or Items.is_paper(it) or Items.is_supplies(it) or it.get("mythic", false):
						continue
					if element != "" and Items.is_socketable(it) and float(Items.base_of(it).get("conv_%s_pct" % element, 0)) > 0.0:
						continue
					if worst.is_empty() or it["value"] < worst["value"]:
						worst = it
				if worst.is_empty() or not _dispose(sim, worst):
					break


## Standard magazines for a gun off the Fence's shelf (30 Oct), till the rig and the stash hold `want` that fit it.
static func _buy_mags(sim, gun: Dictionary, want: int) -> void:
	var have: int = (sim.rig + sim.stash).filter(func(x): return Items.mag_fits(x, gun)).size()
	for it in sim.market.duplicate():
		if have >= want:
			return
		if Items.mag_fits(it, gun) and sim.cash >= sim.price(it) and sim.stash_fits(it) and sim.buy_id(int(it["id"])):
			have += 1


## The stash's rounds of a type.
static func _stash_rounds(sim, type: String) -> int:
	var n := 0
	for it in sim.stash:
		if Items.is_ammo(it) and str(Items.base_of(it)["type"]) == type:
			n += int(it.get("rounds", 0))
	return n


const AMMO_STACKS_KEPT := 6


const HELD_READ_S := 1200.0
const ELEM_DPS_FLOOR := 0.8
const ELEM_WEIGHT := 1.0          # the element's weight in the build's gun compare (31 Oct, PROBE33: 2 carried a melee with half the paper dps)
const STUCK_BINS := 6                # Full signals binned in a row, the reach standing, before the bot makes Clear ones (27 Oct)
var _bin_streak := 0
var _reach_seen := 0
var _held_at := {}


## A spare gone: sold, or binned for its scrap while the Fence is shut (D27: before the Carpet Man's ledger nothing
## sold, the stash filled with spares, nothing more was picked up, and a shock Scrapper never left the Estate).
func _dispose(sim, it: Dictionary) -> bool:
	return sim.sell(it) if sim.room_open("fence") else sim.bin(int(it["id"]))


## The best of a slot in the stash, tried on, or {} (31 Oct, the clean-up: the bot's own, out of the sim, which never
## asked it). The kit's key once a scan (22 Oct, the pass's wall): nothing moves while it looks.
static func best_in_stash(sim, slot: String) -> Dictionary:
	var best := {}
	var bs := -INF
	var key: int = sim._kit_key()
	for it in sim.stash:
		if it["slot"] == slot:
			var v: float = sim.fit_value(it, slot, key)
			if v > bs:
				best = it
				bs = v
	return best


func _sell_spares(sim) -> void:
	var keep_type: String = TYPE_OF.get(sim.cls, "") if keystones_first else ""
	# meds: a dozen cells' worth stay, the dearest; the rig can't carry more and they pile up otherwise
	var meds: Array = sim.stash.filter(func(it): return Items.is_heal(it))
	meds.sort_custom(func(a, b): return a["value"] > b["value"])
	var med_cells := 0
	for it in meds:
		med_cells += Items.size(it)
		if med_cells > 12:
			_dispose(sim, it)
	# cures (28 Oct): three of each kept, the rest go
	var cure_n := {}
	for it in sim.stash.filter(func(x): return Items.is_cure(x)):
		cure_n[it["base"]] = int(cure_n.get(it["base"], 0)) + 1
		if int(cure_n[it["base"]]) > 3:
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
		var b: Dictionary = best_in_stash(sim, slot)
		if not b.is_empty():
			best_id[slot] = int(b["id"])
	var type_best: Dictionary = _best_of_type(sim, keep_type) if keep_type != "" else {}
	var mount_rank := {}                  # item id -> its rank among the mount's parts, best first
	for it in sim.stash:
		if Items.is_attachment(it) and not mount_rank.has(str(it["mount"])):
			var ranked: Array = sim.attachments_for(it["mount"])
			for r in range(ranked.size()):
				mount_rank[int(ranked[r]["id"])] = r
	var sock_rank: Dictionary = _sock_ranks(sim)
	for it in sim.stash.duplicate():
		if Items.is_medical(it) or Items.is_paper(it) or Items.is_supplies(it) or it.get("mythic", false):
			continue                      # a paper's a key to the endgame now (15 Oct): kept; a mythic never goes; supplies are the medic's
		if Items.is_ammo(it):
			var fired := false
			for g in [sim.equipped["Primary"], sim.equipped["Secondary"]]:
				fired = fired or (g != null and Items.base_of(it)["type"] == Items.ammo_type(g))
			if not fired:
				_dispose(sim, it)
			continue
		if Items.is_mag(it):
			# magazines (30 Oct): those the worn guns take stay, the biggest, as many as the rig's pouches; the rest go
			var g_fit = null
			for g in [sim.equipped["Primary"], sim.equipped["Secondary"]]:
				if g != null and Items.mag_fits(it, g):
					g_fit = g
			if g_fit == null:
				_dispose(sim, it)
			else:
				var mine: Array = sim.stash.filter(func(x): return Items.mag_fits(x, g_fit))
				mine.sort_custom(func(a, b_in): return Items.mag_cap(a, g_fit) > Items.mag_cap(b_in, g_fit))
				if mine.find(it) >= maxi(2, sim.med_capacity()):
					_dispose(sim, it)
			continue
		if keep_type != "" and it["slot"] == "Primary" and Items.base_of(it).get("type", "") == keep_type and not type_best.is_empty() and int(type_best["id"]) == int(it["id"]):
			continue                      # the best spare of the class's type stays; the rest of them go
		if element != "" and Items.is_socketable(it) and float(Items.base_of(it).get("conv_%s_pct" % element, 0)) > 0.0:
			if int(sock_rank.get(int(it["id"]), 0)) >= SOCK_KEPT:
				_dispose(sim, it)                # the best SOCK_KEPT of each kept, as the attachments (BUILD45, probe45 #2: 589 stacks of Lighter fluid filled the Drifter's stash)
			continue
		if element != "" and it["slot"] == "Primary":
			var cur = sim.equipped["Primary"]
			if cur == null or _elem_score(it, sim) >= _elem_score(cur, sim) * 0.8:
				continue
		if Items.is_attachment(it):
			# the best three of a mount stay; attachments_for() is sorted best first
			if int(mount_rank.get(int(it["id"]), 99)) >= 3:
				_dispose(sim, it)
			continue
		if int(best_id.get(str(it["slot"]), -1)) != int(it["id"]):
			_dispose(sim, it)


## The build's element's socketables, each kind ranked best first by worth (a stack's count and an affix's in it):
## item id -> its rank among its kind (BUILD45).
const SOCK_KEPT := 3
func _sock_ranks(sim) -> Dictionary:
	var by_base := {}
	for it in sim.stash:
		if Items.is_socketable(it) and float(Items.base_of(it).get("conv_%s_pct" % element, 0)) > 0.0:
			if not by_base.has(it["base"]):
				by_base[it["base"]] = []
			by_base[it["base"]].append(it)
	var out := {}
	for b in by_base:
		var l: Array = by_base[b]
		l.sort_custom(func(a, c): return int(a.get("value", 0)) > int(c.get("value", 0)) or (int(a.get("value", 0)) == int(c.get("value", 0)) and int(a["id"]) < int(c["id"])))
		for r in range(l.size()):
			out[int(l[r]["id"])] = r
	return out


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
			if Items.is_socketable(it) and float(Items.base_of(it).get("conv_%s_pct" % element, 0)) > 0.0 and sim.cash >= sim.price(it) + sim.tins_now(500.0) and _socket_wanting(sim) != "" and sim.buy(i):
				bought.append([sim.elapsed, "%s for £%d" % [it["base"].to_lower(), sim.price(it)]])
				break
	for i in range(sim.market.size()):
		var it: Dictionary = sim.market[i]
		if Items.is_attachment(it) or (Items.rig_item(it) or Items.is_ammo(it)) or not sim.can_wear(it):
			continue                       # gear over the runner's level waits (15 Oct): not bought to wear yet
		var cur = sim.equipped[it["slot"]]
		var g: float = sim.upgrade_gain(it, true) if sim.compare(it, -1, true) == 1 else 0.0     # tried on (11 Oct), as the Kit's arrow reads it once home (the swap)
		if element != "" and it["slot"] == "Primary":
			g = ((_elem_score(it, sim) - _elem_score(cur, sim)) / maxf(_elem_score(cur, sim), 0.01)) if cur != null else sim.EMPTY_GAIN   # a build weighs its gun its own way, as a share like the rest
		if g > gain and sim.cash >= sim.price(it) + sim.tins_now(100.0):
			gain = g
			pick = i
	if pick >= 0:
		sim.buy(pick)
		for s in Data.SLOTS:
			if not (s in broken_slots) and not _keep_stamped(sim, s):
				sim.equip_best(s)
		if element != "" and not ("Primary" in broken_slots) and not _keep_stamped(sim, "Primary"):
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


# ------------------------------------------------------------------ the expeditions (29 Oct, docs/design/trips.md 3, 6)

## The bot's expeditions, as a person leaving them to run would: once the Quartermaster's down, the Bunkhouse's line B
## built as the cash allows, the pool's best hired to the cap, and every free slot sent - the highest-level runner not
## selected leading, the best free hands, the spare cargo (scrap and salvage over what the Pitch wants; never the meds,
## the notes or the rebuild's materials) cut down until the risk reads EXP_RISK_AT or under, to the hardest far place
## whose odds read EXP_ODDS_AT. A crew back is put away at once; a held one is fought for (Fetch them) when the runner
## reads PUSH at the hold site, else ransomed with the cash there EXP_RANSOM_SPARE times over, else walked from.
## `expeditions_on` false: none (the campaign's reads; they're shut till the Quartermaster in any case).
var expeditions_on := true
var exp_sent := 0
var exp_held := 0
var exp_fetched := 0
var exp_walked := 0
var exp_paid := 0
var _held_seen := {}              # expedition id -> true: each held one counted once (the fix round: a lost fetch counted again)
## The fix round (29 Oct, the review's B4: the bot never shipped): lower bars, so a camp past the Quartermaster ships its
## spare scrap, salvage, notes and materials regularly - what the Bench, the Pitch, the heads and the rebuild don't want.
const EXP_RISK_AT := 0.45
const EXP_ODDS_AT := 0.45
const EXP_RANSOM_SPARE := 2.0
const EXP_SCRAP_KEEP := 1000
const EXP_SALVAGE_KEEP := 40
const EXP_NOTES_KEEP := 300


## Returns true when a hold-up's fetch has set off (the step's run).
func _expeditions(sim) -> bool:
	if not sim.expeditions_open():
		return false
	for e in sim.expeditions.duplicate():
		var id: int = int(e["id"])
		if str(e["state"]) == "back":
			sim.exp_take(id)
		elif str(e["state"]) == "held":
			if not _held_seen.has(id):
				_held_seen[id] = true
				exp_held += 1
			var i: int = sim.exp_hold_site(id)
			if sim.exp_fetch_block(id) == "" and i >= 0 and sim.odds_ready(i) and float(sim.odds_now(i)) >= PUSH and sim.exp_fetch(id):
				exp_fetched += 1
				bought.append([sim.elapsed, "expedition held up: fetched from %s" % str(Data.TIERS[i]["name"])])
				return true
			if sim.cash >= sim.exp_ransom(id) * EXP_RANSOM_SPARE and sim.exp_pay(id):
				sim.exp_take(id)
				exp_paid += 1
				bought.append([sim.elapsed, "expedition held up: ransom paid"])
			elif sim.exp_walk(id):
				exp_walked += 1
				bought.append([sim.elapsed, "expedition held up: walked away"])
	var bh: Dictionary = Data.yard_building("bunkhouse")
	var c: int = _next_step(sim, bh, "b")
	if c >= 0 and sim.can_yard_pick("bunkhouse", c, "b") and sim.cash >= sim.yard_pick_cost("bunkhouse", c) * 3.0:
		sim.yard_pick("bunkhouse", c, "b")
		bought.append([sim.elapsed, "bunkhouse b%d" % (c + 1)])
	if sim.pool_open():
		var pool: Array = sim.hand_pool_now().duplicate()
		pool.sort_custom(func(a, b): return int(a["rarity"]) * 10 + int(a["tier"]) > int(b["rarity"]) * 10 + int(b["tier"]))
		for h in pool:
			if sim.hands.size() >= sim.roster_cap():
				break
			sim.hire_hand(int(h["id"]))
		if sim.hand_pool.is_empty() and sim.hands.size() < sim.roster_cap() and sim.cash >= sim.reroll_cost(false) * 10.0:
			sim.reroll_pool(false)
	var guard := 0
	while sim.exp_busy() < sim.exp_at_once() and guard < 3:
		guard += 1
		if not _exp_send(sim):
			break
	return false


## The spare cargo: scrap over EXP_SCRAP_KEEP, salvage over EXP_SALVAGE_KEEP, notes over EXP_NOTES_KEEP (before the
## Issue), each material over the most any rebuild's next rank wants of it. [kind, count].
func exp_spare(sim) -> Array:
	var out: Array = []
	if sim.scrap > EXP_SCRAP_KEEP + 200:
		out.append(["scrap", sim.scrap - EXP_SCRAP_KEEP])
	for k in Data.SALVAGE:
		var n: int = int(sim.salvage.get(k, 0)) - EXP_SALVAGE_KEEP
		if n > 0:
			out.append([k, n])
	if not sim.issued and sim.notes > EXP_NOTES_KEEP + 50:
		out.append(["notes", sim.notes - EXP_NOTES_KEEP])
	for m in Data.MATERIAL_ORDER:
		var want := 0
		for r in Data.REBUILDS:
			want = maxi(want, int(sim.rebuild_cost(str(r["key"])).get(m, 0)))
		var n: int = sim.held_of(str(m)) - want
		if n > 0:
			out.append([m, n])
	return out


func _exp_send(sim) -> bool:
	var leads: Array = sim.exp_leads()
	if leads.is_empty():
		return false
	leads.sort_custom(func(a, b): return sim.crew_level(str(a)) > sim.crew_level(str(b)))
	var lead: String = str(leads[0])
	var free: Array = sim.hands.filter(func(h): return sim.hand_free(h))
	free.sort_custom(func(a, b): return int(a["rarity"]) * 10 + int(a["tier"]) > int(b["rarity"]) * 10 + int(b["tier"]))
	var hs: Array = free.slice(0, sim.exp_hands_max()).map(func(h): return int(h["id"]))
	while not hs.is_empty() and sim.cash < sim.crew_wages(hs):
		hs.pop_back()
	var spare: Array = exp_spare(sim)
	spare.sort_custom(func(a, b): return sim.cargo_slot_worth(str(a[0]), int(a[1])) > sim.cargo_slot_worth(str(b[0]), int(b[1])))
	spare = spare.slice(0, sim.exp_slots(hs))
	if spare.is_empty():
		return false
	var place := -1
	for p in range(Data.EXP_PLACES.size() - 1, -1, -1):
		if float(sim.exp_odds(p, lead)[0]) >= EXP_ODDS_AT:
			place = p
			break
	if place < 0:
		return false                          # no place reads EXP_ODDS_AT: nothing sent (the fix round; it sent to the nearest anyway)
	# the cargo cut to what the risk allows: the odds' part first, then the worth that fills the rest to EXP_RISK_AT
	var odds: float = sim.exp_crew_odds(place, lead, hs)
	var risk0: float = sim.exp_risk(place, lead, hs, 0.0, odds)
	if risk0 >= EXP_RISK_AT:
		return false
	var full: Array = spare.map(func(x): return {"kind": str(x[0]), "n": int(x[1])})
	var room: float = (EXP_RISK_AT - risk0) * sim.lead_strength(lead) / Data.EXP_RISK_K
	var share: float = minf(1.0, room / maxf(1.0, sim.cargo_worth(full)))
	var goods: Array = full.map(func(x): return {"kind": str(x["kind"]), "n": int(floor(int(x["n"]) * share))}).filter(func(x): return int(x["n"]) > 0)
	if goods.is_empty():
		return false
	var worth: float = sim.cargo_worth(goods)
	var risk: float = sim.exp_risk(place, lead, hs, worth, odds)
	if sim.send_expedition(place, lead, hs, goods, str(Data.SLOTS[sim.exp_sent % Data.SLOTS.size()])):
		exp_sent += 1
		bought.append([sim.elapsed, "expedition: %s to %s, %d hands, worth %d, risk %.2f" % [lead, str(Data.EXP_PLACES[place]["short"]), hs.size(), int(worth), risk]])
		return true
	return false
