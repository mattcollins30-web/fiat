extends RefCounted
## The camp and its runner (one out at a time; the crew's other classes wait in Training, 21 Oct). Cash is the one
## number; the runner's level and the stash are the progression. A mission is the idle action: it runs in
## seconds, combat resolves as numbers underneath, and it ends with an extract,
## an early extract, or a KIA that takes the loadout with it. No clock of its
## own - main.gd feeds it seconds.

const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")

var cash := float(Data.STARTING_CASH)
var xp := 0.0
var hp := Data.BASE_HP
var equipped := {}                 # slot -> item or null
var rig: Array = []                # medical items carried, in the rig's slots
var stash: Array = []              # items
var market: Array = []
var gamble: Array = []             # the Fence's gamble: the kinds on offer, rotated with the restock (GAMBLE_KINDS keys)
var clinic: Array = []             # the Clinic's shelf: meds, so many a level, restocked after a run
var supplies_in := 0               # medical supplies handed to the medic, all told (28 Oct): her shelf's steps, for good
var mission = null                 # null, or the mission in progress (a Dictionary)
var last_report = null             # the last mission's outcome, for Mission Control
var operators_lost := 0
var yard_picks := {}               # the Yard's lanes (9 Oct): building key -> [five columns' sides, "a", "b", "ab" (both, 24 Oct) or ""]
var yard_ranks := {}               # building key -> ranks bought
var yard_open := 1                 # the columns opened, for good: a move doesn't close them
var yard_seen := {}                # what the Yard has been looked at with buyable ("key/col", "key/rN"): the rail's badge is for the rest
var yard_seen_cols := 1            # and the columns open then
var salvage := {"copper": 0, "steel": 0, "army": 0}    # the deep sites' salvage, one kind a zone (9 Oct)
var loot_by_hand := true          # the floor (13 Oct, Matt): a search's finds wait on the floor for the player to take; the bot reads them in as before
var hardcore := false              # a death ends the Yard, stash and all
var skill_slots: Array = ["", "", ""]     # the three a run takes, set before it on the Runs card; locked out on a run
var skill_auto: Array = [true, true, true]    # a slot's rule on (it fires by itself) or off (only when pressed)
var wounds := {}                   # the wounds (30; stacked, 19 Oct): area -> {stat, what, from, hp_pct}, three at most, the Clinic the cure
var camp_lost := false             # hardcore: set by the KIA that ended it
var tree: Array = []               # node ids taken, "Branch/index"; the camp's, kept across operators
var cls := ""                      # the operator's class, by name; "" is none yet
var roster := {}                   # the crew (21 Oct): every other class's own runner, by class name (RUNNER_KEYS); the one out is live in the fields
var runner_trait := ""             # what this runner turned up with
var candidates: Array = []         # when a runner dies, two turn up: their traits, to pick from
var promised := ""                 # a trait the next arrival brings (a runner brought home from a run)
var trader_standing := {}          # run events (1 Nov): a trader's key -> the camp's trades with him, any class
var standing_orders := {}          # a family -> its standing order for runs nobody's watching (Data.EVENT_ORDERS); unset, its first
var event_last := ""               # the family of the last event a run had: never the same twice running
var event_threads := {}            # what carries between runs: "freed", "bag" (they remember it; no cost yet)
var words: Array = []              # per tier: the Radio's words on the site, [{"w": name, "t": tier}] (9 Oct: map juicing)
var sealed: Array = []             # per tier: twisted, so nothing but Clear touches its words
var filtered := ""                 # the map's Clear air: a known word the Radio never rolls
var standing: Array = []           # the map's Relay and the whole band: words on every site with a ladder
var depth: Array = []              # per tier: the depth chosen, 1 up
var best_depth: Array = []         # per tier: the deepest cleared, 0 if none
var clear_level: Dictionary = {}   # tier -> the runner's level at its first clear (21 Oct): the campaign's fight hardens from there
var training_points := 0           # the runner's own: two a level past its class's best (skill web version two)
var rewards_earned := {}              # the camp's reward points (skill web version two, 4 Nov): key -> [points, why]; every runner's, each counted once
var best_level := 1                # the camp's best level (9 Oct): a level earns a point only past it, so a new runner re-levels for nothing
var last_craft := {}               # the Bench's last job: {id, kind, words}, for the toast and the craft panel
var best_tier := 0                 # highest tier extracted from
var depot_cleared := false         # the slice's win
var past: Array = []               # the runners before this one: {class, level, runs, end}; the newest PAST_KEPT (BUILD45)
var past_folded := {}              # the older ones' totals: {runners, runs, died} (BUILD45, past_count)
var loose_kit: Array = []          # out on the estate: {item, who, from, run} - a dead runner's kit, a unique the Fence moved on
var book: Array = []               # the papers found, by name, in the order found: the drawer in the Caravan
var heard: Array = []                # the radio's lines heard, in order (12 Oct, the lore pass): voice/index keys
var keepsakes: Array = []          # the heads' things kept (15 Oct): the vet's bag, the fitter's kit, the ledger, the radio
var shelf: Array = []              # the uniques found, by name, in the order found: the shelf in the Caravan
var sets_seen: Array = []          # the set pieces found, by name (24 Oct, the collection): a set's complete once all its pieces are here
var shelf_tier: Dictionary = {}    # a unique's name -> the best tier of it found (12 Oct, uniques by tier)
var site_crates := {}              # a campaign site's crates left between runs (27 Oct, Matt: "going back for the safe ... feels like a chase"): str(tier) -> {"left", "at", "full"}
var site_runs := {}                # the Map card's "You here" (2 Nov, BUILD46-S): str(tier) -> {tries, clears, best, last, last_t, last_full}
var left_behind := {}              # a head's thing not home yet (2 Nov, BUILD46-S): room -> the tier it waits at; the room at half till it's fetched
var weather: Array = []            # per zone: "", "Rain" or "Fog"
var weather_at := -1               # the hour the weather was last rolled
var last_next := ""                # the last "what's next" line the log carried
var auto_equip := false            # idle: the best of each slot goes on when a run comes home
## The junk rules (11 Oct, Matt's list: in place of the one junk toggle). What the Fence takes when a run comes home:
## the gear at or under `junk_upto`'s rarity (-1, nothing), never an upgrade on what's worn (is_upgrade), never a kind
## kept (`junk_keep`, one of JUNK_KEEPS), and never what the junk run never took (rounds, meds, grenades, papers,
## parts that socket, uniques, set pieces, the deeds, a built gun).
const JUNK_KEEPS := {"": [], "guns": ["Primary", "Secondary"], "body": ["Helmet", "Armour", "Gloves", "Charm"], "bags": ["Rig", "Backpack"], "parts": ["Attachment"]}
var junk_upto := -1
var junk_keep := ""
## What came back (11 Oct, Matt's list): every run since the player last looked, added up for the Runs screen's card -
## runs, deaths, cash, XP, notes, scrap, items stashed, kit lost, the dearest find, the levels, and the firsts.
var came_back := {}
var runner_runs := 0               # this runner's runs so far
## This runner's record (8 Oct, the Runner room): the Yard's clock when they arrived, their best run by kills,
## by damage dealt and by cash, the dearest thing they found, the deepest site they held. Reset with the runner.
var record := {"since": 0.0, "kills": 0, "dealt": 0.0, "cash": 0.0, "find": "", "find_value": 0, "runs": 0, "deaths_seen": 0}
var seen: Dictionary = {}          # "tier/depth" -> true once the site's line has been given
var deeds_found := false           # the Bank's vault, opened once
## The rooms a head has opened (13 Oct, docs/design/campaign_gates.md): the clinic, the fence, the yard, the radio, the
## workshop. A bare sim has them all (the tests, the tools); a fresh camp (start) has none.
var unlocked: Array = Data.ROOMS_SHUT.duplicate()
var met: Array = []                # the rooms whose first-visit card has been shown (14 Oct): Words.ROOM_INTROS keys
var deeds_fate := ""               # what became of the deeds: burned, sold, held ("ending" in a save from before 15 Oct)
var deeds_back := false            # the Bailiff has dropped the sold deeds once (27 Oct): sold again, sold for good
var bosses_beaten: Array = []      # per zone: the crew's head is down
var boss_armed: Dictionary = {}    # tier -> true: the next run there takes the boss on
var _notes := 0                    # the old paper money: the crews still take it
## The notes (25 Oct, the Issue: docs/design/the_issue.md): before the Issue a count of their own; after it the crews take
## fiat, so a note reads as its fiat (note_price()) out of the cash - every "notes" price and pay keeps working.
var notes: int:
	get:
		return int(floor(cash / note_price())) if issued else _notes
	set(v):
		if issued:
			var d: float = float(v - (int(floor(cash / note_price())))) * note_price()
			if d > 0.0:
				_earn(d)                          # notes paid after the Issue are fiat income, into circulation (Matt, 26 Oct: "count them as income")
			else:
				cash += d                         # spent: a note reads back as paid (the reviewer)
		else:
			_notes = v
## The Issue (25 Oct, Matt: "all currency then changes to fiat from that point forward"): one way, at the first Issuer
## win. Tins and notes converted once, hard on piles; prices after it follow the fiat in circulation, not the clock.
var issued := false
var fiat_issue_inf := 1.0               # the clock's prices on the day of the Issue: fiat prices start from them
var circulation := 0.0                 # fiat paid out since the Issue, less what's been burnt
var fiat_rate := 1.0                   # the Issuer's rate: the Fence buys at it
var issued_serial := 0                 # issued kit's numbers so far
var issue_moment := {}                 # the Issue's figures for its card: {pile, notes, fiat}; met as "issue"
var scrap := 0                     # the Bench's material (34): found, stripped, ditched for
var takings := 0.0                 # what the Yard takes a run, averaged over the last few: the run's cash and the Fence's money (the pass, 6 Oct)
var gamble_base := 0.0             # the gamble's own: the takings, but a run moves it GAMBLE_STEP at most (13 Oct, Matt: 305 to 2366 off one sale)
var _takings_run := 0.0            # the cash in since the last run came home
var cash_in := 0.0                 # every pound in since the game began (runs, sales); not saved: the readers' figure
var atlas := {}                    # the map's passives: key -> rank
var boss_paid: Array = []          # per tier: the depths a head's price has been paid at (Long memory: once a depth)
var atlas_points := 0              # earned: one a new depth cleared past the first
var exchange_day := 0              # the exchange's day (28 Oct, Matt: contracts replaced by currency conversion): one a run home, the rates' dice
var mate := {}                     # the Fence's mate's offer: {unique, notes}
var runs_total := 0                # every run, every runner: the mate's clock
var wounded_total := 0             # runs that ended wounded, every runner (saved; the wounds row reads a player's save by it)
var lorry_done := false            # the convoy beaten in this yard (7 Oct); the move lights on it
var lorries := 0                   # across every yard: how many times
var papers: Array = []             # the Radio's pile (18 Oct, Matt: "papers found never touch the stash"): the papers a signal is made of
var signals: Array = []            # the Radio's signals held (15 Oct): [{id, site, zone, depth, codes, papers, head, convoy, line}]
var reach := Data.REACH_START       # a level: the highest signal beaten, plus one (D3)
var signal_seq := 0
var story_beat := 0                 # Kev's story: the beats beaten (0-3); past the third the depot comes round again
var story_at := {}                  # a beat beaten -> the hours played then (20 Oct: the story so far, on the Radio)
var _sig: Dictionary = {}           # the signal swapped onto its site: read, or run (mission["signal"])
var best_dig := {}                 # the Yard's deepest hold: {site, depth, yard}, kept across moves (the wall's score)
var insure_next := false           # the next run is insured: the Fence holds the paper on the kit
var workbench_day := -1            # Workbench (22 Oct): the day its free Bench job was had
var materials := {}                # the rebuild (18 Oct, docs/design/rebuild.md): material key -> count; never lost, kept by a move
var key_items := {}                # the order's drops: key -> count (the Grid's key, ledger seals, the FIAT note)
var rebuilt := {}                  # the town's places put back: key -> rank; kept by a move
var order_beaten := {}             # the true pinnacles: key -> times beaten
var elapsed := 0.0
var events: Array = []
## The playtest record (11 Oct, Matt: "did we actually log everything required? The answer is not really"): every
## moment a balance read wants, stamped with the sim's clock, the player's own time at the game and the wall clock.
## A run's end, each first clear and head, the levels, the trees, the Yard, the classes, the kit, the Workshop, the
## Fence, the Radio, the sessions and a snapshot every ten minutes played. The lines wait in `chronicle` until the
## shell appends them to the record file beside the save on each save (main.gd's _flush_record: the save itself never
## carries them, so it doesn't grow with the hours); the bot and the tests, with no shell, keep them all here.
## tools/playtest.bat reads the record file.
const CHRONICLE_V := 2
const SNAP_S := 600.0                # a snapshot every ten minutes played
var chronicle: Array = []            # lines not yet written to the record file
var chron_count := 0                 # every line ever written, the file's and the waiting ones
var played_s := 0.0                  # real seconds at the game, the player there (the shell adds them: not away, not the menu)
var _snaps := 0
var rng := RandomNumberGenerator.new()
var mythic_rng := RandomNumberGenerator.new()     # the mythics' own dice (16 Oct): the one roll a find leaves every other draw where it was
var material_rng := RandomNumberGenerator.new()   # the rebuild's own dice (18 Oct): a run's material leaves every other draw where it was
var focus_rng := RandomNumberGenerator.new()      # a signal's focus (BUILD50-T): its roll and its weighting on its own dice
var mythics_on := true                  # off for the balance read: a read is never one (docs/design/mythics.md)


func _init() -> void:
	for s in Data.SLOTS:
		equipped[s] = null
	for i in range(Data.TIERS.size()):
		words.append([])
		sealed.append(false)
		depth.append(1)
		best_depth.append(0)
		boss_paid.append([])
	for z in range(Data.ZONES.size()):
		bosses_beaten.append(false)
		weather.append("")


## A fresh camp: a starter loadout, the first stock on the market.
## The fingerprint's dice (15 Oct, tests/fingerprint.gd): with `fixed_seed` set, a new camp and a loaded one
## (a Yard's move is both) roll fixed dice instead of fresh ones, so a refactor can be proved to move nothing.
static var fixed_seed := 0
static var _seed_n := 0


func _reseed() -> void:
	if fixed_seed == 0:
		rng.randomize()
		mythic_rng.randomize()
		material_rng.randomize()
		focus_rng.randomize()
		return
	_seed_n += 1
	rng.seed = fixed_seed + _seed_n
	mythic_rng.seed = fixed_seed + _seed_n + 7919
	material_rng.seed = fixed_seed + _seed_n + 104729
	focus_rng.seed = fixed_seed + _seed_n + 130363


func start() -> void:
	_reseed()
	gate_box_always = false                # the bot's flag, never a save's (the three-stage review, tools 2)
	unlocked = []                          # a fresh camp: every room a head opens is shut
	met = []
	_starter_loadout()
	for k in range(Data.START_STASH_BANDAGES):
		stash_put(_plain(Data.MEDICAL, "Bandage"))     # a new camp's spares (17 Oct, Matt): meds before the Clinic opens
	restock()
	came_back_seen()
	mate = roll_mate()
	# (18 Oct, Matt on Q8: the opening's scenes tell it; the log no longer tells it again on another timeline)
	log_event(Words.YARD["set"])
	_say_next()


func _starter_loadout() -> void:
	equipped["Primary"] = _plain("Primary", START_WEAPON)     # a hammer, no rounds (13 Oct, Matt): the guns come when there's ammo for them
	equipped["Armour"] = _plain("Armour", "Work jacket")
	equipped["Backpack"] = _plain("Backpack", "Plastic bag")
	equipped["Rig"] = _plain("Rig", "Bum bag")
	for k in range(2):
		rig.append(_plain(Data.MEDICAL, "Bandage"))
		_stats_dirty()


const START_WEAPON := "Claw hammer"


## A common of this base, no affixes: the worn kit a runner arrives with.
func _plain(slot: String, base: String) -> Dictionary:
	var it := Items.roll(slot, 1, rng)
	it["base"] = base
	it["rarity"] = 0
	it["affixes"] = []
	it["tier"] = Items.base_of(it)["tier"]
	it["value"] = Items.base_of(it)["value"]
	it["attachments"] = {}
	for name in Items.base_of(it).get("attachments", []):
		it["attachments"][name] = null
	if slot == Data.AMMO:
		it["rounds"] = int(Items.base_of(it)["rounds"])
	if slot == Data.MAGAZINE:
		it["rounds"] = 0
		it["ammo"] = ""
	if slot == Data.ATTACHMENT:
		it["mount"] = Items.base_of(it)["mount"]
		if it["mount"] == "socket":
			it["count"] = 1
	return it


# ------------------------------------------------------------------ the operator

func level() -> int:
	if xp != _level_xp:
		_level_xp = xp
		_level_at = Data.level_for_xp(xp)        # read a few times a tick: the curve's walk once an XP (15 Oct, A4)
	return _level_at


var _level_xp := -1.0
var _level_at := 1


## The paragon board (21 Oct, the crew): XP any class earns past MAX_LEVEL is the crew's, on the same curve past the cap;
## each paragon level a point on the board (damage, HP, resists, find, tins), every class reading every point. No top; a
## class's death keeps it. Taken back at the Barracks for tins, as a tree's points are.
var paragon_xp := 0.0
var ring := {}                     # the ring (slice 4, web.md §6): ring node id -> the paragon points on it, to RING_STACK


func paragon() -> int:
	return Data.paragon_for_xp(Data.xp_for_level(Data.MAX_LEVEL) + paragon_xp)


## The XP into the next paragon level, and what that level takes.
func paragon_progress() -> Array:
	var cap := Data.xp_for_level(Data.MAX_LEVEL)
	var p := paragon()
	var lo := Data.xp_for_level(Data.MAX_LEVEL + p) - cap
	var hi := Data.xp_for_level(Data.MAX_LEVEL + p + 1) - cap
	return [paragon_xp - lo, hi - lo]


func paragon_pts(key: String) -> int:
	var n := 0
	for id in ring:
		if str(node(str(id)).get("key", "")) == key:
			n += int(ring[id])
	return n


func paragon_spent() -> int:
	var n := 0
	for k in ring:
		n += int(ring[k])
	return n


func is_ring(id: String) -> bool:
	return id.get_slice("/", 0) == Data.RING_TREE


func paragon_free() -> int:
	return maxi(0, paragon() - paragon_spent())


## A board row's figure as a multiplier (damage, HP, tins) or a percent (resists, find).
func paragon_pct(key: String) -> float:
	return float(Data.paragon_row(key).get("pct", 0.0)) * paragon_pts(key)


## A row's multiplier: a row in PARAGON_COMPOUND multiplies each point on the last (25 Oct); since the designer's call
## (31 Oct, PROBE36) that list is empty and every row adds - damage and HP 2% a point, the tins 3%.
func paragon_mult(key: String) -> float:
	var pct: float = float(Data.paragon_row(key).get("pct", 0.0)) / 100.0
	if key in Data.PARAGON_COMPOUND:
		return pow(1.0 + pct, paragon_pts(key))     # damage and HP: each on the last (25 Oct, the review)
	return 1.0 + pct * paragon_pts(key)              # the rest add (the second review: the tins row was never meant to compound)


## A paragon point on the ring's nearest open node of a row (the bot's and the tests' way in): one with room on it
## that's reached, the fullest first (a stack before a new node); none reached, a point on the way round the ring
## to the nearest, as a player paths (the step is a point on a node of another row).
func paragon_add(key: String) -> bool:
	if paragon_free() <= 0 or Data.paragon_row(key).is_empty():
		return false
	var best := ""
	var best_stack := -1
	var nodes: Array = Data.RING["nodes"]
	for i in range(nodes.size()):
		if str(nodes[i].get("key", "")) != key:
			continue
		var id := "%s/%d" % [Data.RING_TREE, i]
		if train_block(id) != "":
			continue
		var st: int = int(ring.get(id, 0))
		if st > best_stack:
			best_stack = st
			best = id
	if best != "":
		return train_node(best)
	# the way round: the reachable node nearest (by steps round the ring) to a node of the row with room on it
	var step := ""
	var step_d := 1 << 20
	for i in range(nodes.size()):
		var id := "%s/%d" % [Data.RING_TREE, i]
		if train_block(id) != "":
			continue
		for j in range(nodes.size()):
			if str(nodes[j].get("key", "")) != key or int(ring.get("%s/%d" % [Data.RING_TREE, j], 0)) >= int(nodes[j]["stack"]):
				continue
			var d: int = mini(absi(i - j), nodes.size() - absi(i - j))
			if d < step_d:
				step_d = d
				step = id
	return step != "" and train_node(step)


func paragon_reset_cost() -> int:
	return _inf(paragon_spent() * Data.RESPEC_CASH)


## The ring cleared for nothing (the tests' fixtures).
func paragon_reset_free() -> void:
	ring = {}
	tree = tree.filter(func(id): return not is_ring(str(id)))
	_dry_memo.clear()
	_stats_dirty()


func paragon_reset() -> bool:
	if paragon_spent() == 0 or cash < paragon_reset_cost():
		return false
	_dry_memo.clear()
	_stats_dirty()
	var paid := paragon_reset_cost()
	cash -= paid
	chron("respec", {"cost": paid, "points": paragon_spent(), "paragon": true})
	ring = {}
	tree = tree.filter(func(id): return not is_ring(str(id)))
	_stats_dirty()
	log_event(Words.LOG["paragon_reset"])
	return true


## XP in: the runner's to the cap, the rest the crew's paragon.
func _gain_xp(g: float) -> void:
	if mission != null and mission.has("night") and not bool(mission.get("night_home", false)) and not mission.get("dry", false):
		mission["night_xp"] = float(mission.get("night_xp", 0.0)) + g * night_xp_mult(int(mission["night"]))     # a night's XP held in its run, home with the haul (BUILD50 N)
		return
	if mission != null and bool(mission.get("unwatched", false)):
		g *= float(repeat.get("share", repeat_xp_share()))     # a repeat run's share of a watched run's (29 Oct)
		mission["xp_got"] = float(mission.get("xp_got", 0.0)) + g
	var room := maxf(0.0, Data.xp_for_level(Data.MAX_LEVEL) - xp)
	xp += minf(g, room)
	paragon_xp += g - minf(g, room)


## The Yard's prestige: the lorries beaten, each LORRY_MULT on damage and HP, kept across moves.
static var lorry_mult_off := false   # the balance read's A/B switch (12 Oct): the lorries beaten multiply nothing
func lorry_mult() -> float:
	return 1.0 if lorry_mult_off else pow(Data.LORRY_MULT, lorries)


## What grows without end: the paragon board's damage or HP, and the lorries.
func growth_mult(key := "damage") -> float:
	return paragon_mult(key) * lorry_mult()


func max_hp() -> float:
	return _memo("max_hp", _max_hp_raw)


func _max_hp_raw() -> float:
	var m := Data.BASE_HP + Data.HP_PER_LEVEL * (level() - 1) + tree_sum("hp")
	for s in Data.SLOTS:
		if equipped[s] != null:
			m += Items.affix_total(equipped[s], "hp")
	return m * cm("hp") * trait_mult("hp") * wound_mult("hp") * growth_mult("hp") * (1.0 + (Data.FX["yard/theatre"] if yard_has("theatre") else 0.0) + Data.FX["yard_rank/clinic"] * yard_rank("clinic"))


## Damage a second: the primary while it has rounds, else the secondary at full
## (a third of it behind the primary, or all of it with Double tap), else fists.
func dps() -> float:
	var live := not (_dry_on or (fast_memo and mission != null))
	if _trying or (live and live_memo_off):
		return _dps(null)
	# the odds' runs and the reader's (15 Oct, refactor A4): the figure read twice a tick (dps, type_dps), so kept
	# while nothing it reads has moved - each gun fed or not and by what, HP either side of half, the first lot, the
	# XP, the kit (not the rounds' count: that moves every tick; which stacks have any decides the feed)
	var feed := []
	for it in rig:
		if Items.is_mag(it) and int(it["rounds"]) > 0:
			feed.append(str(it.get("ammo", "")))
	if mission != null:
		feed.append(mission.get("mag_in", {}).values())     # the magazine in each gun: its grade (30 Oct)
	var k := [feed, hp < max_hp() * 0.5, mission != null and (not mission["cleared"] or mission.get("ghost_pending", false)), xp, wounds.keys(), _kit_ids(),
		mission.get("fire_x", {}).values() if mission != null else []]     # the reloads (28 Oct)
	if live:
		return _live_dps(k)
	var c = _dry_memo.get("dps")
	if c != null and c[0] == k:
		return c[1]
	var v := _dps(null)
	_dry_memo["dps"] = [k, v]
	return v


## dps() in the shell's play (BUILD43): kept in the live memo on the same key the dry memo's uses.
func _live_dps(k: Array) -> float:
	_live_sync()
	var c = _live_memo.get("dps")
	if c != null and c[0] == k:
		if memo_check:
			var fv := _dps(null)
			if fv != float(c[1]):
				memo_stale.append(["dps", c[1], fv, elapsed, mission != null])
				_live_memo["dps"] = [k, fv]
				return fv
		return c[1]
	var v := _dps(null)
	_live_memo["dps"] = [k, v]
	return v


## Damage a second in its parts (10 Oct, the Stats sheet's chain): {guns, level, pct, attack, past, trait, growth},
## each as dps() multiplies them - guns × (1 + level + pct) × (1 + attack) × past × trait × growth - so the sheet
## draws what dps() is made of and never a formula of its own.
func damage_parts() -> Dictionary:
	var parts := {}
	_dps(parts)
	return parts


func _dps(parts) -> float:
	var pair: Array = _gun_dps()             # the primary's and the secondary's (29 Oct: apart, the type edge is the primary's own)
	var d: float = float(pair[0]) + float(pair[1])
	var primary_live := equipped["Primary"] != null and has_rounds(equipped["Primary"])
	var secondary_live := equipped["Secondary"] != null and has_rounds(equipped["Secondary"])
	if d <= 0.0 and not (primary_live or secondary_live):
		d = Data.UNARMED_DPS                  # fists only with no gun live: a reload is a pause, not a punch
	var pct := _affix_sum("damage_pct") + tree_sum("damage_pct")
	var fitted := 0
	for s in ["Primary", "Secondary"]:
		if equipped[s] != null:
			fitted += Items.fitted_count(equipped[s])
	pct += _affix_sum("damage_per_att") * fitted
	# conditional: under half HP; on the first lot (the fight before the clear)
	if hp < max_hp() * 0.5:
		pct += _affix_sum("damage_low_pct") + tree_sum("damage_low_pct") + (Data.FX["node/walking_wounded.damage_low"] if has_node("walking_wounded") else 0.0)
	if mission != null and (not mission["cleared"] or mission.get("ghost_pending", false)):
		pct += _affix_sum("first_lot_pct")
	if parts != null:
		parts.merge({"guns": d, "level": Data.DMG_PER_LEVEL * (level() - 1), "pct": pct / 100.0, "attack": _affix_sum("attack_pct") / 100.0,
			"past": cm("damage"), "trait": trait_mult("damage"), "growth": growth_mult()}, true)
	return d * (1.0 + Data.DMG_PER_LEVEL * (level() - 1) + pct / 100.0) * (1.0 + _affix_sum("attack_pct") / 100.0) * cm("damage") * trait_mult("damage") * growth_mult() \
		* (Data.FX["rule/safecrackers"] if has_rule("safecrackers") else 1.0) \
		* (0.85 if has_node("live_firing") else 1.0)     # Firing blanks (the Recruit's keystone): his damage 15% down


## The guns' damage a second before the runner's own multipliers, [the primary's, the secondary's] (29 Oct, split out of
## _dps so the type edge can read the primary's share): each gun by the share of now it fires, its reloads apart (the
## magazines, 28 Oct); while the primary reloads, the secondary at the primary's sling's share (30 Oct: the sling; none
## without one); with the primary dry or refilling a magazine, at full.
func _gun_dps() -> Array:
	var p := 0.0
	var sd := 0.0
	var primary_live := equipped["Primary"] != null and has_rounds(equipped["Primary"])
	var secondary_live := equipped["Secondary"] != null and has_rounds(equipped["Secondary"])
	var px: float = fire_x("Primary") if primary_live else 0.0
	if primary_live:
		p = Items.dps(equipped["Primary"]) * (1.0 + grade_bonus(equipped["Primary"]) / 100.0) * (Data.FX["node/cap_jerry"] if (has_node("cap_jerry") and gun_type() == "improvised") else 1.0) * _class_gun_mult(equipped["Primary"]) * px   # Jerry-rigged: something improvised hits half again as hard
	if secondary_live:
		var sec_share: float = (secondary_share(true) * px + (1.0 - px) * reload_share()) if primary_live else 1.0     # through the primary's reloads its backing share, a sling's lift (30 Oct, the designer's B)
		sd = Items.dps(equipped["Secondary"]) * (1.0 + grade_bonus(equipped["Secondary"]) / 100.0) * _class_gun_mult(equipped["Secondary"]) * sec_share * fire_x("Secondary")
		if has_rule("branch_pistol") and hp < max_hp() * 0.5:
			sd *= Data.FX["rule/branch_pistol"]
	return [p, sd]


## The gun type's edge (29 Oct, docs/design/itemisation.md §3): the primary's type when it's in hand and fed, else "" -
## a rifle pierces and opens, an SMG walks its fire, a shotgun spreads, a melee weapon takes a crowd; the edge is the
## primary's alone (an improvised gun's is its extra socket, a pistol's its quick draw: neither in the fight's sums).
static var edges_off := false     # the smoke's A/B switch (29 Oct): the fight with no type edge, to measure the edge against its read
func edge_type() -> String:
	if edges_off:
		return ""
	var g = equipped["Primary"]
	if g == null or not has_rounds(g):
		return ""
	return str(Items.base_of(g).get("type", ""))


## The primary's share of the guns' damage now: what the edge multiplies (the secondary's share takes none).
func edge_share() -> float:
	var pair: Array = _gun_dps()
	var tot: float = float(pair[0]) + float(pair[1])
	return float(pair[0]) / tot if tot > 0.0 else 0.0


## The edge as the hits read it (29 Oct, the review: the try-on, the Kit's arrows, the bot's picks and the odds' figure
## read what the real fight pays): the multiplier on the hits at a site - the mission's while one runs, else the fight
## being pushed (front_tier) - worked out the way _fight pays it, per type:
## - rifle: their physical resist cut by the pierce, and one shot's opener on every man (the gang's HP in a pool, so
##   an opener that kills a man early carries into the next: the rate over 1 - opener/HP, never past ×1 + EDGE opener);
## - SMG: walking fire over the first gang's length (the base's `sustain`: it grows a second, to its cap);
## - shotgun: the spread on every man while a second stands behind him (the last of a gang has none);
## - melee: the crowd's bonus while two or more are on you (the last of a gang alone, or a contact of one, none).
func edge_read(t: Dictionary = {}) -> float:
	var ty := edge_type()
	if not (ty in ["rifle", "smg", "shotgun", "melee"]):
		return 1.0
	if t.is_empty():
		t = _edge_site()
	var share := edge_share()
	if share <= 0.0:
		return 1.0
	var per := type_dps()
	var res: Dictionary = t.get("res", {})
	var plain := 0.0
	for k in Data.TYPES:
		var r: float = float(res.get(k, 0.0))
		if k == "physical":
			r = phys_resist(r)
		plain += float(per[k]) * (1.0 - r)
	if plain <= 0.0:
		return 1.0
	var n: float = maxf(1.0, float(t.get("pool", 1)))
	var man: float = maxf(1.0, float(t.get("hp", 1.0)))
	var e := float(Data.EDGE.get(ty, {}).get("x", 0.0))
	match ty:
		"rifle":
			var r_p: float = phys_resist(float(res.get("physical", 0.0)))
			var pierced: float = plain + float(per["physical"]) * r_p * float(Data.EDGE["rifle"]["pierce"]) * share
			var g = equipped["Primary"]
			var shot: float = pierced * share / maxf(0.01, float(Items.base_of(g)["rof"]) * mag_share("Primary"))     # one of the primary's rounds, landed (pace cancels: hits and rounds both ride it)
			var op: float = float(Data.EDGE["rifle"]["opener"])
			var opener: float = minf(1.0 + op, 1.0 / maxf(0.01, 1.0 - op * minf(1.0, shot / man)))
			return pierced / plain * opener
		"smg":
			var su: Array = Items.base_of(equipped["Primary"]).get("sustain", [0, 0])
			var a: float = float(su[0]) / 100.0
			var c: float = float(su[1]) / 100.0
			if a <= 0.0 or c <= 0.0:
				return 1.0
			var t0: float = n * man / maxf(0.01, plain * pace() * float(t.get("pace", 1.0)))     # the first gang's seconds, no walking fire
			var full: float = c / a + a * (c / a) * (c / a) / 2.0                             # the plain seconds the stream's climb to its cap is worth
			var secs: float = ((-1.0 + sqrt(1.0 + 2.0 * a * t0)) / a) if t0 <= full else (t0 + c * c / (2.0 * a)) / (1.0 + c)
			return t0 / maxf(0.001, secs)
		"shotgun", "melee":
			if ty == "melee" and contact(t) < int(Data.EDGE["melee"]["on_you"]):
				return 1.0
			var x: float = 1.0 + e * share
			# the men who go without: a shotgun's last (no one behind him), a blade's last on_you - 1 (too few on you; the
			# fix round, the game review's C3: counted from on_you, not fixed at one)
			var k: float = clampf(float(int(Data.EDGE["melee"]["on_you"]) - 1) if ty == "melee" else 1.0, 1.0, n)
			return n / ((n - k) / x + k)
	return 1.0


## The site the edge is read at: the mission's while one runs (its own crew), else the fight being pushed; kept a kit's
## front (effective() is dear, and the try-ons ask once a piece).
var _edge_key := -1
var _edge_t := {}
func _edge_site() -> Dictionary:
	if mission != null and mission.get("t", null) is Dictionary:
		return mission["t"]
	var k: int = hash([front_tier(), depth, words, standing, campaign_done(), is_night(), atlas])     # the night's pace and the atlas too (the game review's C11)
	if k != _edge_key:
		_edge_key = k
		var e: Dictionary = effective(front_tier())
		_edge_t = {"pool": e["pool"], "hp": e["hp"], "res": e.get("res", {}), "pace": e["pace"], "contact": e.get("contact", 0)}
	return _edge_t


## What the secondary fires behind the primary: a third; all of it with Double tap or the primary dry; two thirds with
## the Van's Spare (15 Oct, Matt: was all of it).
func secondary_share(primary_live: bool) -> float:
	if not primary_live or has_node("double_tap") or has_rule("spare_key"):
		return 1.0                            # the Spare Key (a mythic): at full rate, always
	if has_rule("vans_spare"):
		return Data.FX["rule/vans_spare"]
	return 1.0 / 3.0


## The class's own gun: the Scrapper's improvised guns do 20% more (12 Oct); 1 for any other gun or class.
func _class_gun_mult(it: Dictionary) -> float:
	return cm("improvised") if Items.base_of(it).get("type", "") == "improvised" else 1.0


func armour() -> float:
	# BUILD43: read five times a paint, each a walk of the kit, the trees and the pack - kept in the live memo only: the
	# dry runs, a try-on and fast_memo read it fresh as they always did (the dry memo would hold it, and move the odds)
	if _trying or _dry_on or (fast_memo and mission != null):
		return _armour_raw()
	return _live_read("armour", _armour_raw)


func _armour_raw() -> float:
	var a := 0.0
	for s in Data.SLOTS:
		if equipped[s] != null:
			a += Items.armour(equipped[s])
	a += _affix_sum("armour_per_med") * rig.size() + _fitted_sum("salt")
	if mission != null:
		a += _affix_sum("armour_per_free") * maxi(0, capacity_raw() - pack_used(mission))
	return a * (1.0 + (tree_sum("armour_pct") + _affix_sum("armour_pct") + (float(mission.get("buff_armour_pct", 0.0)) if mission != null else 0.0)) / 100.0) * (Data.FX["node/shock_more.armour"] if (has_node("shock_more") and not has_rule("sparkys_gloves")) else 1.0) * wound_mult("armour")


## The wounds' cut on a stat: a tenth off for the one that names it (one an area, so one a stat), nothing off the rest.
func wound_mult(stat: String) -> float:
	for a in wounds:
		if str(wounds[a]["stat"]) == stat:
			return 1.0 - Data.WOUND_PCT / 100.0 * (2.0 / 3.0 if yard_has("physio") else 1.0)
	return 1.0


## A stat's name in a wound's words.
static func wound_stat_name(stat: String) -> String:
	return "max HP" if stat == "hp" else stat


## The wounds in words: "Wounded: pace −10%", "2 wounds: pace, armour −10%", or "" unhurt.
func wound_words() -> String:
	if wounds.is_empty():
		return ""
	var stats: Array = []
	for a in Data.WOUND_AREAS:
		if wounds.has(a):
			stats.append(wound_stat_name(str(wounds[a]["stat"])))
	if stats.size() == 1:
		return "Wounded: %s −%d%%" % [stats[0], wound_pct()]
	return "%d wounds: %s −%d%%" % [stats.size(), ", ".join(stats), wound_pct()]


## A wound's cut as it is, in percent: Physio's third off included (18 Oct, Matt on Q7: it always read 10).
func wound_pct() -> int:
	return int(round(Data.WOUND_PCT * (2.0 / 3.0 if yard_has("physio") else 1.0))) if not wounds.is_empty() else 0


## A hit took the runner under a third: a wound, to an area not yet hurt - the head's cuts max HP, the chest's armour,
## the legs' pace - until the Clinic treats it (19 Oct, Matt: they stack, three at most). One a run; with all three
## carried, a fourth bad run adds nothing.
func _wound(m: Dictionary) -> void:
	if not room_open("clinic"):
		return                                # nothing to treat it with till the Gamekeeper's down (17 Oct, Matt's playtest): no wound before the Clinic
	if m.get("wounded", false):
		return                                # one a run
	m["wounded"] = true
	wounded_total += 1                        # runs that ended wounded, every runner (the wounds row reads Matt's save by it, 8 Oct)
	var free: Array = Data.WOUND_AREAS.filter(func(a): return not wounds.has(a))
	if free.is_empty():
		log_event(Words.WOUNDS["full"])
		return
	var area: String = free[rng.randi_range(0, free.size() - 1)]
	var spec: Dictionary = Data.WOUND_AREA[area]
	var whats: Array = spec["what"]
	wounds[area] = {"stat": str(spec["stat"]), "what": str(whats[rng.randi_range(0, whats.size() - 1)]), "from": str(tier(int(m.get("tier", 0)))["name"]),
		"hp_pct": int(round(100.0 * hp / maxf(max_hp(), 1.0)))}
	_dry_memo.clear()
	_stats_dirty()
	if spec["stat"] == "hp":
		hp = minf(hp, max_hp())
	log_event(Words.WOUNDS["took"] % [str(spec["name"]), str(wounds[area]["what"]), wound_stat_name(str(spec["stat"])), wound_pct(), wounds.size()])


## The share of incoming damage the armour stops.
func mitigation() -> float:
	return _memo("mitigation", _mitigation_raw)


## The armour as the run's words leave it (the Radio's Pawned): the mitigation with the armour cut.
func _mitigation_under(t: Dictionary) -> float:
	var f: float = float(t.get("armour", 1.0))
	if f >= 1.0 and mission != null:
		f = float(mission["t"].get("armour", 1.0))
	if f >= 1.0 or has_rule("nans_cardigan"):
		return mitigation()
	var a := armour() * cm("armour") * f
	return a / (a + armour_k())


func _mitigation_raw() -> float:
	if has_rule("nans_cardigan"):
		return 0.0                               # no armour at all
	var a := armour() * cm("armour")
	return a / (a + armour_k())


## The level fought (21 Oct, gear scaling): the run's, or at camp the front site's, as the Map's odds read it.
func fight_level() -> int:
	return int(mission["t"].get("level", site_level(front_tier()))) if mission != null else site_level(front_tier())


## The gear's growth at the level fought: the armour's cut reads against it (at-level armour holds its share, never
## running to a hundred), and what's bought low and used there - a med's heal, a grenade's hit - grows with it.
func fight_grow() -> float:
	return Items.grow(fight_level())


func armour_k() -> float:
	return Data.ARMOUR_K * fight_grow()


# ------------------------------------------------------------------ the damage model
## A hit is split by type (conversion), each share multiplied by its own
## increased and more, cut by their resist to it; the sum is what lands.
## Physical is what's left after the conversions. Armour stops physical
## only; the elements only resists stop.

## The shares of a hit by type, summing to 1.
func conversion() -> Dictionary:
	return _memo("conversion", _conversion_raw)


func _conversion_raw() -> Dictionary:
	var out := {}
	var total := 0.0
	for ty in Data.ELEMENTS:
		var share: float = (_affix_sum("conv_%s_pct" % ty) + _fitted_sum("conv_%s_pct" % ty) + tree_sum("conv_%s_pct" % ty)) / 100.0
		if equipped["Primary"] != null:
			share += float(Items.base_of(equipped["Primary"]).get("conv_%s_pct" % ty, 0)) / 100.0   # a bat's nails
			share += grade_stat(equipped["Primary"], "conv_%s_pct" % ty) / 100.0                     # the rounds' grade (33): hollow point bleeds, incendiary burns; the secondary's grade is damage only
		out[ty] = maxf(0.0, share)
		total += out[ty]
	if has_rule("jump_leads"):
		out["shock"] += Data.FX["rule/jump_leads"]
		total += Data.FX["rule/jump_leads"]   # the same figure both places (25 Oct, the review)
	if has_node("bust_them_up"):
		for ty in Data.ELEMENTS:
			out[ty] = 0.0                    # Bust them up: nothing you fire converts
		total = 0.0
	if has_rule("weed_burner"):
		for ty in Data.ELEMENTS:
			out[ty] = 0.0
		out["fire"] = 1.0
		total = 1.0
	if has_rule("last_orders"):
		for ty in Data.ELEMENTS:
			out[ty] = 1.0                    # the Last Orders (a mythic): every hit all of it every element, and physical too
		out["physical"] = 1.0
		return out
	var cap: float = 1.0 if has_rule("weed_burner") else Data.CONV_CAP     # the physical floor (31 Oct); the Weed Burner's "all damage is fire" its own
	if total > cap:
		for ty in Data.ELEMENTS:
			out[ty] *= cap / total
		total = cap
	out["physical"] = 1.0 - total
	return out


## Everything that increases a type, in percent, added together.
func increased(ty: String) -> float:
	return _memo("increased/" + ty, _increased_raw.bind(ty))


func _increased_raw(ty: String) -> float:
	var inc: float = _affix_sum("%s_pct" % ty) + tree_sum("%s_pct" % ty) + _affix_sum("%s_proofed" % ty)
	inc += over_cap(ty) * (2.0 if has_node("proof_" + ty) else 1.0)     # over the cap (12 Oct): what's past it is that element's damage
	if ty == "physical" and has_node("thick_skinned"):
		inc += clampf((armour() - Data.THICK_SKIN_FROM) / Data.FX["node/thick_skinned.armour_per_pct"], 0.0, Data.OVER_CAP)     # Thick-skinned: armour past 200, a tenth of it
	return inc


## Everything that multiplies a type on its own: the element's costly notable, keystones, uniques.
func more(ty: String) -> float:
	return _memo("more/" + ty, _more_raw.bind(ty))


func _more_raw(ty: String) -> float:
	var m := 1.0
	if has_node("%s_more" % ty):
		m *= 1.4
	if ty == "frost" and has_node("frost_freeze"):
		m *= Data.FX["node/frost_freeze"]
	if ty == "bleed" and has_rule("butchers_steel"):
		m *= Data.FX["rule/butchers_steel"]
	if ty == "shock" and has_rule("tester"):
		m *= Data.FX["rule/tester"]
	if has_rule("sergeants_whistle"):
		m *= Data.FX["rule/sergeants_whistle.damage"]
	if has_rule("qm_manual"):
		m *= 1.0 + Data.FX["rule/qm_manual"] * a51_elements_held()     # the Quartermaster's Manual (BUILD51-A): its rule back
	if (ty == "fire" or ty == "shock") and yard_has("arc_lamps"):
		m *= Data.FX["yard/arc_lamps"]                                  # the Generator's Arc lamps
	if (ty == "poison" or ty == "bleed") and yard_has("ratter"):
		m *= Data.FX["yard/ratter"]                                  # the Kennel's Ratter
	if has_set_rule("army"):
		m *= Data.FX["set/army.damage"]
	return m


## A dot's seconds: the element's notable doubles them.
## `theirs`: the dot is on them (the runner's rules shape it); false for one on you, which keeps the plain figures.
func dot_seconds(ty: String, theirs := true) -> float:
	var s := float(Data.DOTS[ty]["s"])
	if not theirs:
		return s
	if (ty == "fire" and tree.has("Petrol/3")) or (ty == "poison" and tree.has("The Rat Man/3")) or (ty == "bleed" and tree.has("Blades/3")):
		s *= Data.FX["node/fire_pct.notable_s"]     # the element's notable: its own figure, not the Carpet set's (25 Oct, the review)
	elif ty == "bleed" and has_set_rule("carpet"):
		s *= Data.FX["set/carpet.bleed_s"]
	if ty == "poison" and has_rule("rat_mans_overalls"):
		s *= Data.FX["rule/rat_mans_overalls"]                                 # the overalls: the same pool, twice as fast
	return s * (1.0 + tree_sum("%s_last_pct" % ty) / 100.0)                    # Oil drum, Serrated, Takes its time (22 Oct): longer


func dot_stacks(ty: String, theirs := true) -> int:
	var n := int(Data.DOTS[ty]["stacks"])
	if not theirs:
		return n
	if ty == "poison" and has_node("poison_stacks"):
		n = Data.FX["node/poison_stacks"]
	if ty == "poison" and (has_rule("rat_mans_bag") or has_rule("rat_mans_overalls")):
		n = 999
	if ty == "bleed" and (has_node("bleed_forever") or has_rule("butchers_apron")):
		n = 3                                    # Won't stop, or the apron: a bleed on a bleed on a bleed
	return n


## How much slower chilled gangs fire, and how much more shocked ones take.
func chill_amount() -> float:
	if has_node("frost_freeze"):
		return Data.FREEZE
	return 0.4 if tree.has("The cold/3") else Data.CHILL


func shock_amount() -> float:
	if has_rule("substation_key"):
		return Data.FX["rule/substation_key"]                               # the Substation Key: shocked, they take 60% more
	return 0.4 if tree.has("Live/3") else Data.SHOCK


## Damage a second by type, before their resist: the base, split, increased, more.
func type_dps() -> Dictionary:
	var base := dps()
	var conv := conversion()
	var out := {}
	for ty in Data.TYPES:
		out[ty] = base * float(conv[ty]) * (1.0 + increased(ty) / 100.0) * more(ty)
	return out


## Damage a second as one figure (16 Oct, item 14): the hits by type, and each dot's steady burn on top. A pool fed
## landed × ratio × grow a second and draining over its seconds deals that a second, under its cap (the gun's rate ×
## ratio × seconds × stacks × depth × grow) - so a dot's figure is rate × ratio × grow × min(1, stacks × depth), as
## _dot_add and _dot_tick work it; Won't stop's bleed never drains, so it sits at the cap. `res`, when given, is their
## resist by type (a site's), cut from each type as damage_rate does. {hits, dots: {type: dps}, dot, total}.
func damage_split(res := {}, edge := true) -> Dictionary:
	var per := type_dps()
	var ex: float = edge_read() if edge else 1.0     # the gun type's edge on the hits as the fight pays it (29 Oct); a skill's figure has none.
	var hits := 0.0                                  # The burn stays the plain rate's: the pools' caps in the fight are the plain rate's
	var dots := {}
	var dot := 0.0
	var grow := dot_grow(true)
	for ty in Data.TYPES:
		var r := float(res.get(ty, 0.0))
		if ty == "shock" and has_rule("sparkys_gloves"):
			r = 0.0
		var rate := float(per[ty]) * (1.0 - r)
		hits += rate * ex
		if not Data.DOTS.has(ty) or rate <= 0.0:
			continue
		var cap := float(dot_stacks(ty, true)) * dot_depth(true) * (1.5 if (ty == "bleed" and has_node("cap_bleed_out")) else 1.0)
		var f := cap * maxf(grow, 1.0) if (ty == "bleed" and has_node("bleed_forever")) else minf(grow, cap * maxf(grow, 1.0))     # Won't stop: the pool never drains, so it sits at its cap
		dots[ty] = rate * float(Data.DOTS[ty]["ratio"]) * f
		dot += float(dots[ty])
	return {"hits": hits, "dots": dots, "dot": dot, "total": hits + dot}


## Damage a second as the fight lands it (29 Oct): the top bar's figure at the runner's pace - what a pair of gloves is
## judged by, so a pace pair reads as the more damage it is (the bot's and the Kit's picks, the junk rules).
func fight_damage() -> float:
	return damage_total() * pace()


## The damage a second the top bar shows (18 Oct, Matt: a fire build's Epic read as a downgrade from a Common): the
## hits and the dots' burn together, so a try-on weighs a piece by the figure the player sees.
func damage_total() -> float:
	return float(damage_split()["total"])


## The figure without the gun type's edge (29 Oct): what a skill's hit and its dots are made from.
func damage_total_raw() -> float:
	return float(damage_split({}, false)["total"])


## The top bar's figure with a part on the gun in `slot` (18 Oct: the Workshop read the gun's raw hits, so a part that
## turns hits to fire read as nothing): [as worn now, with the part fitted].
## `at` names the mount when it isn't the part's own: a socketable's socket ("socket 2"), 19 Oct - Matt: the Workshop
## said nothing of what a socketable does to the damage. One in the socket, as fit_socket puts it.
func damage_with_part(slot: String, part: Dictionary, at := "") -> Array:
	var now: float = _try({}, damage_total)
	var gear = equipped.get(slot, null)
	var key: String = at if at != "" else str(part.get("mount", ""))
	if gear == null or key == "":
		return [now, now]
	var copy: Dictionary = gear.duplicate(true)
	copy["attachments"][key] = _one_copy(part)
	return [now, _try(copy, damage_total)]


## One of a part, as fit_socket's _one_off puts it in (a stack's one), without touching the stash's or minting an id.
func _one_copy(part: Dictionary) -> Dictionary:
	var one: Dictionary = part.duplicate(true)
	if Items.stacks(one) and Items.stack_size(one) > 1:
		Items.set_stack(one, 1)
	return one


## A socketable in a body piece's socket (19 Oct, the review): the body's figure the Kit judges it by - how many times
## over the runner stands the fight (survival_value), or the piece's score for a bag or a charm - [now, with it].
func body_with_part(slot: String, part: Dictionary, at: String) -> Array:
	var now: float = _fit_value({}, slot)
	var gear = equipped.get(slot, null)
	if gear == null or at == "":
		return [now, now]
	var copy: Dictionary = gear.duplicate(true)
	copy["attachments"][at] = _one_copy(part)
	return [now, _fit_value(copy, slot)]


## damage_split in words, for the top bar's tip and the Stats sheet: "321 from hits · 31 burning", or short "Hits 321 · burn 31".
func split_words(split: Dictionary, short := false) -> String:
	var parts := [("Hits %.0f" if short else "%.0f from hits") % float(split["hits"])]
	var dots: Dictionary = split["dots"]
	for ty in ["fire", "poison", "bleed"]:
		if float(dots.get(ty, 0.0)) >= 0.5:
			if short:
				parts.append("%s %.0f" % [{"fire": "burn", "poison": "poison", "bleed": "bleed"}[ty], float(dots[ty])])
			else:
				parts.append("%.0f %s" % [float(dots[ty]), {"fire": "burning", "poison": "poison", "bleed": "bleeding"}[ty]])
	if parts.size() == 1:
		return "All hits: no burn, poison or bleed" if short else "All of it hits: no burn, poison or bleed"
	return " · ".join(parts)


## What lands on a target a second: each type cut by their resist to it; shocked, more of everything.
func damage_rate(t: Dictionary, shocked := false) -> float:
	var res: Dictionary = t.get("res", {})
	var total := 0.0
	var per := type_dps()
	var ex: float = edge_read(t) if t.has("pool") else 1.0     # a site's: the type edge as it pays there (29 Oct)
	if ex != 1.0:
		for k in per:
			per[k] = float(per[k]) * ex
	for ty in Data.TYPES:
		var r := float(res.get(ty, 0.0))
		if ty == "shock" and has_rule("sparkys_gloves"):
			r = 0.0
		total += float(per[ty]) * (1.0 - r)
	return total * ((1.0 + shock_amount()) if shocked else 1.0)


## Your resist to a type, as a share, capped.
func resist(ty: String) -> float:
	return _memo("resist/" + ty, _resist_raw.bind(ty))


func _resist_raw(ty: String) -> float:
	return clampf(resist_raw(ty), 0.0, Data.RESIST_CAP) / 100.0


## A resist before the cap, in percent (12 Oct, over the cap): the affixes, the trees, the bases, the -proofed lines,
## less a Water cannon's soaking on the run. What's past RESIST_CAP is over_cap's.
func resist_raw(ty: String) -> float:
	return _memo("resist_raw/" + ty, _resist_raw_pct.bind(ty))


func _resist_raw_pct(ty: String) -> float:
	if ty == "physical" or (ty == "fire" and has_rule("vicars_thermos")):
		return 0.0
	var r: float = _affix_sum("%s_res" % ty) + _affix_sum("all_res") + tree_sum("%s_res" % ty) + tree_sum("all_res") + _affix_sum("%s_proofed" % ty) + base_res(ty)     # a base's resist is its role (29 Oct): a Blue Plaque leaves it
	r += clampf(Data.RESIST_CAP - r, 0.0, paragon_pct("resists"))     # the board's points to the cap, never past it into over_cap's damage (the review)
	if mission != null:
		r -= float(mission["t"].get("soaked", 0.0)) * 100.0     # the Water cannon: your resists down for the run
	return r


## An element's resist past the cap, to OVER_CAP: what over the cap turns into its damage.
func over_cap(ty: String) -> float:
	if has_rule("blue_plaque"):
		return 0.0                               # the listing: nothing else counts, so nothing's over (the design's check)
	return clampf(resist_raw(ty) - Data.RESIST_CAP, 0.0, Data.OVER_CAP)


## A resist built into what's worn (the welder's mask, the lineman's coat): the bases' own, beside the affixes.
func base_res(ty: String) -> float:
	var r := 0.0
	for s in Data.SLOTS:
		if equipped[s] != null:
			r += float(Items.base_of(equipped[s]).get("res", {}).get(ty, 0.0))
	return r


## Their fire a second on you: each type's share, physical through armour, the
## rest through resists; chilled, slower; three or more, the crowd rules.
func incoming_rate(t: Dictionary, on_you: int, chilled := false) -> float:
	var types: Dictionary = t.get("types", {"physical": 1.0})
	var total := 0.0
	for ty in types:
		var share := float(types[ty])
		total += t["dps"] * on_you * share * ((1.0 - _mitigation_under(t)) if ty == "physical" else (1.0 - resist(ty))) * (1.1 if ty == "fire" and has_node("blast_burns") else 1.0)     # Blast burns' cost
	return total * ((1.0 - chill_amount()) if chilled else 1.0) * (Data.MELEE_INCOMING if melee() else 1.0)


## Not today (24 Oct, Matt: Code blue took its killing hit): under a quarter HP, 40% less of their fire lands.
func low_hp_mult() -> float:
	return Data.FX["node/not_today"] if has_node("not_today") and hp < max_hp() * Data.FX["node/not_today.under"] else 1.0


## What a crowd on you takes off their fire (23 Oct, Matt's compare: the Doorman's Jacket read a downgrade - its rule
## was the fight's alone, the body's figure never saw it): Bodyline, the crowd_less affixes, the Jacket, with three or
## more on you. The fight and survival_value read the same.
func crowd_mult(on_you: int) -> float:
	if on_you < 3:
		return 1.0
	var m := 1.0
	if has_node("bodyline"):
		m *= Data.FX["node/bodyline"]
	m *= 1.0 - _affix_sum("crowd_less_pct") / 100.0
	if has_rule("doormans"):
		m *= Data.FX["rule/doormans"]
	return m


## A dot's pool grows by a share of what landed and drains over its seconds;
## stacks cap the pool. `dots` is {type: pool}.
func _dot_add(dots: Dictionary, ty: String, landed: float, rate_cap: float) -> void:
	if not Data.DOTS.has(ty) or landed <= 0.0:
		return
	var d: Dictionary = Data.DOTS[ty]
	var theirs: bool = mission == null or not is_same(dots, mission.get("my_dots"))     # the same dictionary, not equal contents: two empty pools read alike (12 Oct)
	var grow: float = dot_grow(theirs)
	# the cap grows with it (16 Oct, Matt): a one-stack burn sat at its cap, so +% dot damage only filled it sooner
	var cap: float = rate_cap * float(d["ratio"]) * dot_seconds(ty, theirs) * dot_stacks(ty, theirs) * dot_depth(theirs) * maxf(grow, 1.0)
	if ty == "bleed" and theirs and combo_on("opened_for_good"):
		cap = Data.COMBO_CEILING                 # Opened for good: no top a gang could find (a float's, kept off INF for the save)
	var old: float = float(dots.get(ty, 0.0))
	dots[ty] = maxf(old, minf(cap, old + landed * float(d["ratio"]) * grow))     # the trees' too, on them only (16 Oct: Fumes was read nowhere); never lowers a pool: a carry over the cap stands (FIX51, the review's 1)
	_f51_cap_seen(dots, ty, cap)               # the site's cap kept for the carry's top (FIX51)


## A dot's growth: the kit's dot_pct and the trees', on them only - a burn on you is their fire's, and your gear's
## +% dots never fed it (17 Oct, Matt: "gear boosts only your dots").
func dot_grow(theirs := true) -> float:
	if not theirs:
		return 1.0
	return 1.0 + (_affix_sum("dot_pct") + tree_sum("dot_pct")) / 100.0


## What the dots deal this tick, draining their pools.
## `by`, when given, collects the tick per type (for the run screen's colours).
func _dot_tick(dots: Dictionary, dt: float, by: Dictionary) -> float:
	var dealt := 0.0
	for ty in dots.keys():
		var pool := float(dots[ty])
		if pool <= 0.0:
			dots.erase(ty)
			continue
		var theirs: bool = mission == null or not is_same(dots, mission.get("my_dots"))     # the same dictionary, not equal contents: two empty pools read alike (12 Oct)
		var tick := minf(pool, pool / dot_seconds(ty, theirs) * dt)
		if not (ty == "bleed" and has_node("bleed_forever") and theirs):
			dots[ty] = pool - tick             # Won't stop: a bleed on them doesn't fade
		dealt += tick
		by[ty] = float(by.get(ty, 0.0)) + tick
	return dealt


## Their fire on you this second, by type, after your armour and resists: the
## shares of incoming_rate, for the run screen's colours.
func incoming_shares(t: Dictionary) -> Dictionary:
	var types: Dictionary = t.get("types", {"physical": 1.0})
	var out := {}
	var total := 0.0
	for ty in types:
		var part: float = float(types[ty]) * ((1.0 - _mitigation_under(t)) if ty == "physical" else (1.0 - resist(ty)))     # as their fire lands (Pawned's armour): 25 Oct
		out[ty] = part
		total += part
	for ty in out:
		out[ty] = out[ty] / total if total > 0.0 else 0.0
	return out


## What's on them, as [words, tone] pairs for the chips: burning, poisoned, bleeding, chilled, shocked.
func dots_on_them() -> Array:
	var out := []
	if mission == null or mission["remaining"] <= 0:
		return out
	var dots: Dictionary = mission.get("dots", {})
	for ty in ["fire", "poison", "bleed"]:
		if float(dots.get(ty, 0.0)) > 0.5:
			out.append([{"fire": "Burning", "poison": "Poisoned", "bleed": "Bleeding"}[ty], ty])
	if float(mission.get("chill_t", 0.0)) > 0.0:
		out.append(["Chilled", "frost"])
	if float(mission.get("shock_t", 0.0)) > 0.0:
		out.append(["Shocked", "shock"])
	return out


## A true pinnacle's own fight as chips for "On them" (24 Oct): the Lineman's shield and his stun, the Issuer's
## printed men, the Registrar's red tape.
## A true pinnacle's chips: his ("On them"), or with `on_you` the Registrar's, which are on the runner (the language pass).
func order_chips(on_you := false) -> Array:
	var out: Array = []
	if mission == null:
		return out
	var m: Dictionary = mission
	var mech: String = _order_mech(m)
	if (mech in ["archive", "auditor", "bailiff"]) != on_you:
		return out
	if mech == "treasurer":
		mech = "grid" if float(m.get("shield", 0.0)) > 0.0 or float(m.get("stunned_t", 0.0)) > 0.0 else "mint"
	match mech:
		"grid":
			if float(m.get("stunned_t", 0.0)) > 0.0:
				out.append([Words.ORDER_CHIPS["stunned"] % int(ceil(float(m["stunned_t"]))), "Stunned", "shock"])
			elif float(m.get("shield", 0.0)) > 0.0:
				out.append([Words.ORDER_CHIPS["shield"] % maxi(0, int(ceil(Data.ORDER_SHIELD_WINDOW - float(m.get("shield_t", 0.0))))), "Shielded", "frost"])
		"archive":
			if float(m.get("taped_t", 0.0)) > 0.0:
				out.append([Words.ORDER_CHIPS["taped"] % int(ceil(float(m["taped_t"]))), "Red tape", "bleed"])
			elif not m.get("sealed", {}).is_empty():
				out.append([Words.ORDER_CHIPS["sealed"], "Stamped", "bleed"])
		"mint", "collector":
			if int(m.get("printed", 0)) > 0:
				out.append([Words.ORDER_CHIPS["printed"] % mini(int(m["printed"]), contact(m["t"])), "Printed", "fire"])     # those on you, not every one alive
			if mech == "collector" and collector_taken(m) > 1.0:
				out.append([Words.COUNTY["chip_owed"] % roundi((collector_taken(m) - 1.0) * 100.0), "Owed", "fire"])
		"auditor":
			out.append([Words.COUNTY["chip_tax"], "Taxed", "bleed"])
			if not m.get("sealed", {}).is_empty():
				out.append([Words.ORDER_CHIPS["sealed"], "Stamped", "bleed"])
		"bailiff":
			if bool(m.get("seize_on", false)):
				var sz: String = str(m["seized"])
				if sz == DEEDS_SEIZED:
					out.append([Words.COUNTY["chip_seized"] % "the deeds · get him under half", "Seized: the deeds", "bleed"])
					return out
				var piece = equipped.get(sz)
				var hit: String = ("−%d%% fire" % roundi(float(Data.BAILIFF_CUT[sz]) * 100.0)) if Data.BAILIFF_CUT.has(sz) else ("×%.2f taken" % Data.BAILIFF_TAKEN)
				out.append([Words.COUNTY["chip_seized"] % ("your %s · %s" % [Items.full_name(piece) if piece != null else sz.to_lower(), hit]), "Seized: %s" % sz.to_lower(), "bleed"])     # the piece and what it costs (the third review)
	return out


## Loot the pack can bring back.
func capacity() -> int:
	if _pack_holding:
		return _held_cap                      # BUILD45: one read through a packing (held_pack)
	return capacity_raw() * (Data.MYTHIC_PACK if has_rule("removal_van") else 1)     # the Removal Van (a mythic): four times the pack


## The pack as its frame and the tree make it, without the Removal Van: what the empty-cell sums read (the review: the
## Lorry's Load paid notes for 9,999 cells).
func capacity_raw() -> int:
	var extra := (Data.FX["node/pack_mule"] if has_node("pack_mule") else 0) + int(tree_sum("cells"))     # Light pack (22 Oct)
	var base := 2 if equipped["Backpack"] == null else maxi(1, Items.capacity(equipped["Backpack"]))
	extra += int(town_stat("pack_cells"))     # the bus depot (21 Oct, in auto-run's rest's place)
	return int((base + extra) * (Data.FX["node/hoarder.capacity"] if has_node("hoarder") else 1) * (Data.FX["rule/the_float.capacity"] if has_rule("the_float") else 1.0))


## Meds the rig can carry. No rig, no meds. (The Float stops the meds only, not the rig: 18 Oct, Matt's call on Q0.)
func med_capacity() -> int:
	if equipped["Rig"] == null:
		return 0
	var n: int = (Items.capacity(equipped["Rig"]) + int(tree_sum("med_cap")) + int(_affix_sum("med_cap"))) * (Data.FX["rule/issue_webbing"] if has_rule("issue_webbing") else 1)
	n += (Data.FX["yard/rig_wiring"] if yard_has("rig_wiring") else 0) + (Data.RIG_ROW if yard_has("battery") else 0)    # the Generator's picks
	n -= 1 if has_node("danger_area") else 0     # Grenadier (the Recruit's keystone): a pouch fewer
	return clampi(n, 0, Data.RIG_CAP)


## The rig's pouches are cells: a first aid kit takes two, a surgeon's kit four.
func rig_used() -> int:
	var n := 0
	for it in rig:
		n += Items.size(it)
	return n


func rig_room(cells: int) -> bool:
	return rig_used() + cells <= med_capacity()


func loot_bonus() -> float:
	var b := (_affix_sum("loot_pct") + tree_sum("loot_pct")) / 100.0 + float(class_data().get("loot", 0.0))
	if mission != null:
		b += _affix_sum("loot_per_lot") * mission["patrols"] / 100.0
	b += greed_quantity()
	b += _affix_sum("loot_per_med") * rig.size() / 100.0
	b += roll_bonus()
	if has_node("poison_more"):
		b -= Data.FX["node/poison_more.quantity"]                                 # the rat's share
	return b


## Rarer finds: the tree's and the class's, as a bonus the roll reads.
## On a roll (22 Oct): +5% find and loot quality a kill untouched, to +50%; a hit taken resets it.
func roll_bonus() -> float:
	return 0.05 * int(mission.get("roll", 0)) if mission != null and has_node("on_a_roll") else 0.0


## Greed after the clear (25 Oct, the review: staying was never worth it): every gang that comes after the site's
## cleared adds loot quality and quantity for the rest of the run - Tarkov's choice, to go or to stay.
func greed_gangs() -> int:
	return int(mission.get("patrols", 0)) if mission != null and mission.get("cleared", false) else 0


func greed_quality() -> float:
	return Data.GREED_QUALITY * greed_gangs()


func greed_quantity() -> float:
	return Data.GREED_QUANTITY * greed_gangs()


func rarity_bonus() -> float:
	var r := tree_sum("rarity") / 100.0 + trait_add("rarity") + charm_find() / 100.0 \
		+ yard_quality() / 100.0 + paragon_pct("find") / 100.0 + roll_bonus() + greed_quality()       # the dog knows what's worth carrying (27); the paragon board's find; greed
	return r * (Data.FX["rule/bookies_pencil.rarity"] if has_rule("bookies_pencil") else 1.0)


func sell_price(it: Dictionary) -> int:
	var inf: float = inflation() / circ_mult() if it.has("issue_k") and issued else inflation()     # held through the Issue: at the Issue's prices for good, as the cash (Matt, 26 Oct)
	var got := int(round(Items.worth(it) * float(it.get("issue_k", 1.0)) * inf * (fence_rate() if issued else 1.0) * (1.0 + (tree_sum("sell_pct") + set_stat("sell_pct") + (Data.FX["joint/scrapper_fire.sell"] if has_joint("scrapper_fire") else 0.0) + yard_sell_pct()) / 100.0) * (Data.FX["node/buyers_market.sell"] if has_node("buyers_market") else 1.0)))
	var cap: int = shop_price(it)
	return mini(got, maxi(0, cap - 1)) if cap > 0 else got     # never back for what it costs (S1, S2): the Fence's and the Clinic's stock sells under its price


## What the Fence or the Clinic charges for a thing it stocks, at today's buy multipliers, or 0 when neither stocks it:
## rounds (a box's price, by what the stack holds), meds (the Clinic's), a piece bought off the shelf (its price there).
func shop_price(it: Dictionary) -> int:
	if Items.is_ammo(it):
		return _inf(Items.worth(it) * Data.AMMO_PRICE * _buy_k("fence_pct"))
	if Items.is_medical(it):
		return clinic_price(it)
	if bool(it.get("shop_bought", false)):
		return price(it)
	return 0


## The buy side's multipliers, as the shelf's price() has them: Buyer's market, the town's discount (`town`: the market
## hall's fence_pct, the pumping station's clinic_pct), Shop local's buy_pct.
func _buy_k(town: String) -> float:
	return (Data.FX["node/buyers_market.buy"] if has_node("buyers_market") else 1.0) * (1.0 - town_stat(town) / 100.0) * (1.0 - tree_sum("buy_pct") / 100.0)


## HP for the screens: whole points, rounded the same way both sides, never past the max.
func max_hp_shown() -> int:
	return int(round(max_hp()))


func hp_shown() -> int:
	return mini(max_hp_shown(), int(ceil(hp - 0.001)))


## Money that goes off: what a pound of the opening day's price costs now.
## Every cash price and every cash income runs through it; the notes don't.
func inflation() -> float:
	if issued:
		return fiat_issue_inf * Data.FIAT_SCALE * circ_mult()     # after the Issue: fiat, by the money about (the Issue)
	var h: float = maxf(0.0, elapsed / 3600.0 - Data.INFLATION_GRACE_H)
	return minf(Data.INFLATION_CAP, 1.0 + Data.INFLATION_RATE * h)


## After the Issue: prices by the fiat in circulation - the more about, the more it all costs.
## The rate the Fence buys at after the Issue: the Issuer's, never under 1.0 with the issued cap worn.
func fence_rate() -> float:
	return maxf(fiat_rate, 1.0) if has_rule("issued_cap") else fiat_rate


func circ_mult() -> float:
	return minf(Data.FIAT_CIRC_CAP, 1.0 + maxf(0.0, circulation) / Data.FIAT_CIRC_SPAN)


## The rise, in percent, for the screens: "Prices up 42%" (after the Issue, by the circulation's).
func inflation_pct() -> int:
	if issued:
		return int(round((circ_mult() - 1.0) * 100.0))
	return int(round((inflation() - 1.0) * 100.0))


## A sum of the old day's tins as it stands now: as it is before the Issue, at the new money's after (Bung's, the bot's floors).
func tins_now(x: float) -> float:
	return x * inflation() if issued else x     # at today's prices, the circulation's rise in (the third review: the Issue's alone)


## A note's worth in fiat after the Issue (the crews' prices and pays read through it).
func note_price() -> float:
	return maxf(0.0001, Data.NOTE_TINS * inflation())


## The Issue: the first Issuer win. Every tin and note held, converted once, hard on piles; tins and notes gone for good.
## What the Issue would give now: {"fiat", "kit_k", "money", "held"} (the third review's A1(a): the Mint's card warns before the win).
func issue_preview() -> Dictionary:
	var money: float = maxf(0.0, cash) + float(_notes) * Data.NOTE_TINS * inflation()
	var held := 0.0                            # the kit's sale worth joins the pile (Matt, 26 Oct): kit bought to dodge the root doesn't
	for it in _kit_held():
		held += float(sell_price(it))
	held += exchange_held_worth()              # and the exchange's held (28 Oct, Matt): tins parked in scrap or salvage don't either
	held += exp_pile_worth()                   # and the expeditions out or waiting (the fix round, 29 Oct): a shipment doesn't dodge it
	var pile: float = money + held
	var k: float = (Data.FIAT_PILE_K * sqrt(pile)) / pile if pile > 0.0 else Data.FIAT_SCALE
	return {"fiat": money * k, "kit_k": clampf(k / Data.FIAT_SCALE, 0.0, 1.0), "money": money, "held": held}


func issue() -> void:
	if issued:
		return
	var money: float = maxf(0.0, cash) + float(_notes) * Data.NOTE_TINS * inflation()
	var held := 0.0                            # the kit's sale worth joins the pile (Matt, 26 Oct): kit bought to dodge the root doesn't
	var kit_held: Array = _kit_held()
	for it in kit_held:
		held += float(sell_price(it))
	held += exchange_held_worth()              # the exchange's held, as the preview's (28 Oct, Matt)
	held += exp_pile_worth()                   # the expeditions out or waiting, as the preview's (29 Oct)
	var pile: float = money + held
	fiat_issue_inf = inflation()
	if mission != null:
		mission["cash"] = float(mission.get("cash", 0.0)) * Data.FIAT_SCALE     # the run it happens on: its tins come home as fiat too (the reviewer)
	takings *= Data.FIAT_SCALE                 # the averages prices are taken off, at the new money's (the reviewer)
	gamble_base *= Data.FIAT_SCALE
	_takings_run *= Data.FIAT_SCALE
	var whole: float = Data.FIAT_PILE_K * sqrt(pile)
	var k: float = whole / pile if pile > 0.0 else Data.FIAT_SCALE     # a tin's fiat at the Issue, the pile's
	var fiat: float = money * k
	var hard: float = clampf(k / Data.FIAT_SCALE, 0.0, 1.0)            # the stash sells at the pile's rate, not the day's
	for it in kit_held:
		it["issue_k"] = hard                   # every piece held: at the pile's rate, and at the Issue's prices for good (the review: a small pile's kit went unstamped)
	_exp_issue(k, hard)                        # the expeditions convert with the pile (29 Oct)
	issue_moment = {"pile": int(round(cash)), "notes": _notes, "stash": int(round(held)), "fiat": int(round(fiat)), "kit_k": snappedf(hard, 0.01)}
	_notes = 0
	issued = true
	cash = fiat
	circulation = 0.0
	fiat_rate = 1.0
	log_event(Words.ISSUE["log"] % fiat_words(fiat))
	chron("issue", issue_moment.duplicate())
	_web_reward("issue", Data.REWARD_ISSUE, Words.WEB_REWARD["issue"])     # the Issue: two points for every runner


## Scrap, salvage and materials held, at their exchange worth today (28 Oct, Matt, the review's A2): what joins the
## Issue's pile beside the kit, so tins parked in them before the Issue are converted hard on piles too.
func exchange_held_worth() -> float:
	var w := 0.0
	for cur in ["scrap"] + Array(Data.SALVAGE) + Array(Data.MATERIAL_ORDER):
		var n: int = exchange_held(cur)
		if n > 0:
			w += float(n) * exchange_worth(cur)
	return w


## Every piece held at the Issue, worn or not: the stash, the runner's kit, every other runner's in the crew (the review:
## worn kit taken off after sold at the day's rate).
func _kit_held() -> Array:
	var out: Array = []
	var kits: Array = [equipped]
	for nm in roster:
		kits.append(Dictionary(roster[nm]).get("equipped", {}))
	for it in stash:
		if it is Dictionary and not it.get("issued", false) and not Items.is_deeds(it):     # the deeds are property, not money: the Issue can't touch them (27 Oct, Matt)
			out.append(it)
	for kit in kits:
		for sl in kit:
			var it = kit[sl]
			if it is Dictionary and not it.get("issued", false) and not out.has(it):
				out.append(it)
	return out


static func fiat_words(x: float) -> String:
	var n := int(round(x))
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return "ƒ" + s + out


## The Issuer's rate after a sale or a burn: a sale pushes it down, a burn up; back towards 1.0 with time.
func _rate_unit() -> float:
	return maxf(1.0, Data.RATE_SALE_UNIT * inflation())


func _rate_after_sale(x: float) -> void:
	if issued and x > 0.0:
		fiat_rate = maxf(Data.RATE_MIN, fiat_rate - Data.RATE_SALE_STEP * x / _rate_unit())


## Burn fiat at the Issuer's counter: out of circulation (twice the sum, the Seal four times), the rate up a little.
func burn_price() -> int:
	return maxi(1, int(round(maxf(0.0, circulation) * Data.BURN_SHARE / Data.BURN_MULT)))     # a share of what's about (Matt, 26 Oct)


func can_burn() -> bool:
	return issued and mission == null and cash >= float(burn_price()) and burn_moves()


## A burn takes something out of circulation (the third review: at none in it, a burn spent ƒ3,030 for nothing).
func burn_moves() -> bool:
	return circulation > 0.0          # the review: at the price cap both multipliers read ×4, and a burn still takes fiat out


func burn() -> bool:
	if not can_burn():
		return false
	var x := float(burn_price())
	cash -= x
	circulation = maxf(0.0, circulation - x * Data.BURN_MULT * (Data.FX["rule/issued_seal.burn"] if has_rule("issued_seal") else 1.0))
	fiat_rate = minf(Data.RATE_MAX, fiat_rate + Data.RATE_SALE_STEP * x / _rate_unit())
	chron("burn", {"fiat": int(x)})
	return true


## What a burn would bring the prices to, for its button.
func circ_mult_after_burn() -> float:
	var c: float = maxf(0.0, circulation - float(burn_price()) * Data.BURN_MULT * (Data.FX["rule/issued_seal.burn"] if has_rule("issued_seal") else 1.0))
	return minf(Data.FIAT_CIRC_CAP, 1.0 + c / Data.FIAT_CIRC_SPAN)


## A cash price of the opening day, at today's: rounded to the pound, never below the original when it was positive.
func _inf(x: float) -> int:
	var v := int(round(x * inflation()))
	return maxi(1, v) if x > 0.0 else v      # never under one when it cost something (the third review: after the Issue, ammo and meds rounded to ƒ0, free)


# ------------------------------------------------------------------ the class

func class_data() -> Dictionary:
	for c in Data.CLASSES:
		if c["name"] == cls:
			return c
	return {}


## A class multiplier by key, 1.0 without one.
func cm(key: String) -> float:
	return float(class_data().get(key, 1.0))


## The class screen swaps (21 Oct, Matt: "you swap the class and it moves to whatever level you have in that class along
## with its skill tree"): a runner with no class yet takes the first one picked as theirs; after that a pick puts the
## runner out away with everything that's theirs (RUNNER_KEYS) and brings in that class's own - or a new one at level
## 1 with the arrival's kit. At camp only.
const RUNNER_KEYS := ["xp", "hp", "equipped", "rig", "wounds", "tree", "training_points", "best_level", "trait", "candidates", "runner_runs", "record", "insure_next", "skill_slots", "skill_auto"]


func set_class(name: String) -> bool:
	if runner_busy() or name == cls or Data.CLASSES.filter(func(c): return c["name"] == name).is_empty() or lead_out(name):     # a lead away on an expedition (29 Oct)
		return false
	_dry_memo.clear()
	_stats_dirty()
	if cls == "":
		cls = name                             # the first pick: this runner is that class's
		_ensure_start()                        # its start, owned from level 1 (the skill web)
		chron("class", {"from": "", "to": name})
		log_event(Words.LOG["class_before"] % name)
		_say_next()
		return true
	var from := cls
	var join := join_level(name)                # the crew's floor (30 Oct): read before the swap, off the other classes as they stand
	var pitch: Array = tree.filter(func(id): return is_ring(str(id)))     # the crew's paragon ring stays out whoever runs; the web is each runner's own
	var own_tabs: Array = stash.filter(func(x): return tab_of(x) != "")     # the class's own stash tabs go with them
	stash = stash.filter(func(x): return tab_of(x) == "")
	roster[from] = _runner_out()
	roster[from]["tab_items"] = own_tabs
	_crew_odds[from] = _sig_odds                # the signals' odds read for each go with them (the review: a swap read them again)
	_sig_odds = _crew_odds.get(name, {})
	_crew_odds.erase(name)
	if roster.has(name):
		_runner_in(roster[name])
		stash.append_array(roster[name].get("tab_items", []))     # their own tabs back in the stash
		roster.erase(name)
	else:
		_runner_in(_new_runner())
	tree = tree.filter(func(id): return not is_ring(str(id))) + pitch
	_stats_dirty()
	cls = name
	_ensure_start()
	_skills_known_only()
	_caches_out()
	var lv: int = maxi(level(), join)
	chron("swap", {"from": from, "to": name, "level": lv})
	log_event(Words.CREW["swap"] % [from, name, lv])
	if join > level():
		log_event(Words.CREW["floor"] % [name, join, Data.CREW_FLOOR_UNDER])     # said before its points' line
	_crew_floor_lift(join)
	if came_back.has("lv_from"):
		came_back["lv_from"] = level()          # the card's climb is this runner's
	_say_next()
	return true


## The crew's floor (30 Oct, Matt, shared XP option B): each class keeps its own level, tree and kit, but one swapped in
## (a benched class, or a new one) joins at no less than the best of the crew's OTHER classes less CREW_FLOOR_UNDER, never
## past MAX_LEVEL (the paragon's untouched). The XP is raised to that level's threshold and the levels gained go through
## _earn_points, as if levelled. Only set_class lifts: a death (which never swaps) before the Quartermaster still puts its class
## back to level 1 (past him it keeps the level, 31 Oct) and that class stays there for the rest of its spell out; it's lifted again only when it next comes in after another
## class has been out (the floor is read off the other classes, never its own old level). crew_level stays the stored
## level (what the bench, a lead and a save hold); join_level is what a swap would bring out.
func join_level(name: String) -> int:
	var own: int = maxi(1, crew_level(name))
	if cls == "" or name == cls:
		return own                             # the first pick, or the one out: nothing to join
	var best := 0
	for c in crew_played():
		if str(c) != name:
			best = maxi(best, crew_level(str(c)))
	return maxi(own, mini(Data.MAX_LEVEL, best - Data.CREW_FLOOR_UNDER))


## The runner just swapped in lifted to `join` if under it: the XP to its threshold, the points through _earn_points, a
## runner rested at the old level rested at the new.
func _crew_floor_lift(join: int) -> void:
	var before := level()
	if join <= before:
		return
	var rested: bool = hp >= max_hp() - 0.001
	xp = maxf(xp, Data.xp_for_level(join))
	_caches_out()
	_earn_points(before)
	if rested:
		hp = max_hp()


## The runner's web made legal (a load): the start, then the saved nodes in their saved order, each kept only if the
## rule takes it as it comes - joined back to the start through owned ones, its gate met, a point free, not another
## class's start or skill - in passes until one keeps none. What's past the points goes latest first; a node cut off
## from the start goes, and with it what hung only from it. The ring's own stay as they are.
func _web_legal() -> void:
	if cls == "":
		return
	var st: String = Data.web_start(cls)
	var want: Array = []
	var keep: Array = [st]
	for id in tree:
		var sid := str(id)
		if is_ring(sid):
			keep.append(id)
		elif sid != st and not want.has(sid) and not node(sid).is_empty():
			want.append(sid)
	var was: int = tree.size()
	tree = keep
	_stats_dirty()
	var took := true
	while took and not want.is_empty():
		took = false
		var still: Array = []
		for id in want:
			if train_block(id) == "":
				tree.append(id)
				took = true
			else:
				still.append(id)
		want = still
	if tree.size() != was:
		_dry_memo.clear()
		_stats_dirty()


## Every runner's web made legal as a save loads: the one out, then each of the crew's as their own class.
func _web_legal_all() -> void:
	_web_legal()
	var hold := {"cls": cls, "tree": tree, "training_points": training_points}
	for k in roster:
		var r: Dictionary = roster[k]
		if not (r.get("tree", []) is Array) or Array(r.get("tree", [])).is_empty():
			continue
		cls = str(k)
		tree = Array(r["tree"]).duplicate()
		training_points = int(r.get("training_points", 0))
		_web_legal()
		r["tree"] = tree.filter(func(id): return not is_ring(str(id)))
	cls = hold["cls"]
	tree = hold["tree"]
	training_points = hold["training_points"]
	_eff_hash = 0
	_stats_dirty()


## A slot holding a skill this runner doesn't know empties (a swap, a load, a death, a respec): the picker counts it free.
func _skills_known_only() -> void:
	for k in range(skill_slots.size()):
		if str(skill_slots[k]) != "" and not skill_known(str(skill_slots[k])):
			skill_slots[k] = ""


## The runner out, as the crew holds them: the live fields, moved (not copied: the kit is the same items).
func _runner_out() -> Dictionary:
	return {"xp": xp, "hp": hp, "equipped": equipped, "rig": rig, "wounds": wounds, "tree": tree.filter(func(id): return not is_ring(str(id))), "training_points": training_points,
		"best_level": best_level, "trait": runner_trait, "candidates": candidates, "runner_runs": runner_runs, "record": record,
		"insure_next": insure_next, "skill_slots": skill_slots.duplicate(), "skill_auto": skill_auto.duplicate()}     # the skills are the class's (25 Oct, the review)


func _runner_in(r: Dictionary) -> void:
	xp = float(r.get("xp", 0.0))
	hp = float(r.get("hp", Data.BASE_HP))
	equipped = r.get("equipped", {})
	for sl in Data.SLOTS:
		if not equipped.has(sl):
			equipped[sl] = null
	rig = r.get("rig", [])
	wounds = r.get("wounds", {})
	tree = r.get("tree", [])
	_stats_dirty()
	training_points = int(r.get("training_points", 0))
	best_level = int(r.get("best_level", 1))
	runner_trait = str(r.get("trait", ""))
	candidates = r.get("candidates", [])
	runner_runs = int(r.get("runner_runs", 0))
	record = r.get("record", {"since": elapsed, "kills": 0, "dealt": 0.0, "cash": 0.0, "find": "", "find_value": 0, "runs": 0, "deaths_seen": operators_lost})
	insure_next = bool(r.get("insure_next", false))
	skill_slots = Array(r.get("skill_slots", ["", "", ""])).map(func(x): return str(x))
	skill_auto = Array(r.get("skill_auto", [true, true, true])).map(func(x): return bool(x))
	while skill_slots.size() < Data.SKILL_SLOTS:
		skill_slots.append("")
	while skill_auto.size() < Data.SKILL_SLOTS:
		skill_auto.append(true)


## A class not played yet: level 1, the arrival's kit, no trait (as the first runner), no points.
func _new_runner() -> Dictionary:
	var hold := [equipped, rig]
	equipped = {}
	for sl in Data.SLOTS:
		equipped[sl] = null
	rig = []
	_starter_loadout()
	var r := {"xp": 0.0, "hp": Data.BASE_HP, "equipped": equipped, "rig": rig, "wounds": {}, "tree": [], "training_points": 0,
		"best_level": 1, "trait": "", "candidates": [], "runner_runs": 0, "insure_next": false, "skill_slots": ["", "", ""], "skill_auto": [true, true, true]}
	equipped = hold[0]
	_stats_dirty()
	rig = hold[1]
	return r


## What a runner swapped or read in can't check for itself (30 Oct, refactor 1: the rest check runner_key - the odds key's
## memos, the try-ons' - or their own hash of the tree and class, or the XP): the odds, whose key is bucketed and carries
## no class (it seeds the dice, so it stays as it is); the rules, whose key counts the stash, not what's in it (the
## class's own tabs move with a swap); and the fast memo, which checks no key (runner_parts).
func _caches_out() -> void:
	_dry_memo.clear()
	_stats_dirty()
	_rules_key = []                            # the rules in play are the runner's (22 Oct)
	_surv_cache = {}


## A class's runner as the screens read it: the one out live, the rest from the crew. {} for a class not played.
func crew_runner(name: String) -> Dictionary:
	if name == cls and cls != "":
		return _runner_out()
	return roster.get(name, {})


## A class's level, 0 for one not played.
func crew_level(name: String) -> int:
	var r := crew_runner(name)
	return 0 if r.is_empty() else Data.level_for_xp(float(r.get("xp", 0.0)))


## The element a class's runner has trained most (by nodes in its flower), "" for none or a class not played.
func crew_element(name: String) -> String:
	var r := crew_runner(name)
	var best := ""
	var most := 0
	var count := {}
	for id in r.get("tree", []):
		var et := Data.element_tree(str(id).get_slice("/", 0))
		if not et.is_empty() and Data.web_region(str(id)).begins_with("el:"):
			count[et["element"]] = int(count.get(et["element"], 0)) + 1     # its flower's nodes, not the joins in its colour
	for el in count:
		if int(count[el]) > most:
			most = int(count[el])
			best = str(el)
	return best
# ------------------------------------------------------------------ the tree

## The trees on show: the whole web (every class's, the centre's, every element's) and the paragon ring.
func trees() -> Array:
	var out: Array = Data.TREES.duplicate()
	out.append_array(Data.ELEMENT_TREES)
	out.append(Data.RING)
	return out


## The runner's trait, as a multiplier on a figure (1.0 when it has none).
func trait_mult(key: String) -> float:
	var m := 1.0
	for t in Data.TRAITS:
		if t["name"] == runner_trait:
			m *= float(t.get(key, 1.0))
	return m


## A trait's additive figure (the Lucky one's loot quality).
func trait_add(key: String) -> float:
	var a := 0.0
	for t in Data.TRAITS:
		if t["name"] == runner_trait:
			a += float(t.get(key, 0.0))
	return a


# ------------------------------------------------------------------ the exchange

## The exchange (28 Oct, Matt: "contracts should be replaced by currency conversion - notes, tins, scrap with varying
## rates for each"; salvage and the County's materials too): what's on it, in the screen's order. Tins always; notes
## till the Issue (read out of the fiat after it); scrap; a salvage kind once held or its zone dug to SALVAGE_DEPTH; a
## material once held or its site cleared (fuses once held or the rebuild's open).
func exchange_offered() -> Array:
	var out: Array = ["tins"]
	if not issued:
		out.append("notes")
	out.append("scrap")
	var kinds := salvage_kinds()
	for k in Data.SALVAGE:
		if int(salvage.get(k, 0)) > 0 or kinds.has(k):
			out.append(k)
	var mats := materials_met()
	for k in Data.MATERIAL_ORDER:
		if held_of(k) > 0 or mats.has(k):
			out.append(k)
	return out


## What can be given on the exchange: the board less scrap, which is bought, never sold (scrap buy-only, 28 Oct, the
## review: scrapped with Strip for parts and Salvage, then sold, it paid up to 2.8x the Fence - and the Clinic's shelf
## bought, scrapped and sold was a money pump).
const EXCHANGE_BUY_ONLY := ["scrap"]
func exchange_gives() -> Array:
	return exchange_offered().filter(func(c): return not (c in EXCHANGE_BUY_ONLY))


## The zones whose salvage drops: a site of it dug to SALVAGE_DEPTH.
func salvage_kinds() -> Array:
	var out: Array = []
	for z in range(Data.ZONES.size()):
		for i in Data.ZONES[z]["tiers"]:
			if dug_depth(i) >= Data.SALVAGE_DEPTH and Data.ZONE_SALVAGE[z] != "":
				out.append(Data.ZONE_SALVAGE[z])
				break
	return out


## The materials met by the run (24 Oct, for the contracts; the exchange's since 28 Oct): those of the sites cleared
## (Data.SITE_MATERIAL), in their order; the signals' fuses once the rebuild's open.
func materials_met() -> Array:
	var out: Array = []
	for i in range(mini(Data.SITE_MATERIAL.size(), best_depth.size())):
		var k: String = str(Data.SITE_MATERIAL[i])
		if k != "" and int(best_depth[i]) >= 1 and not out.has(k):
			out.append(k)
	if rebuild_open() and not out.has("fuses"):
		out.append("fuses")
	return out


## What's held of a currency on the exchange: whole tins, notes, scrap, a salvage kind, a material.
func exchange_held(cur: String) -> int:
	match cur:
		"tins":
			return int(floor(maxf(0.0, cash)))
		"notes":
			return notes
		"scrap":
			return scrap
	if Data.SALVAGE.has(cur):
		return int(salvage.get(cur, 0))
	return held_of(cur)


func _exchange_add(cur: String, n: int) -> void:
	match cur:
		"tins":
			cash += n                             # a trade, not takings: no _earn (after the Issue the fiat's just cash)
		"notes":
			notes += n                            # the property handles itself
		"scrap":
			scrap += n
		_:
			if Data.SALVAGE.has(cur):
				salvage[cur] = int(salvage.get(cur, 0)) + n
			else:
				materials[cur] = held_of(cur) + n
				if int(materials[cur]) <= 0:
					materials.erase(cur)          # none left: off the count, as the rebuild keeps it


## A currency's name on the exchange: the money's, Notes, Scrap, the salvage's, the material's.
func exchange_name(cur: String) -> String:
	match cur:
		"tins":
			return money_word().capitalize()
		"notes":
			return "Notes"
		"scrap":
			return "Scrap"
	if Data.SALVAGE.has(cur):
		return str(Data.SALVAGE_NAMES[cur])
	return thing_name(cur)


## A currency's drift on a day: ±EXCHANGE_DRIFT from a hash of the day and the currency, through dice of its own (a
## bare string hash moved every currency together, day on day) - the sim's dice never drawn, so the rates move no
## other roll. Tins are the yardstick: they never drift.
func exchange_drift(cur: String, day := -1) -> float:
	if cur == "tins":
		return 1.0
	var r := RandomNumberGenerator.new()
	r.seed = hash("exchange|%d|%s" % [exchange_day if day < 0 else day, cur])
	return 1.0 + Data.EXCHANGE_DRIFT * r.randf_range(-1.0, 1.0)


## A currency's worth in tins on a day (today by default): its base at the day's prices, times the day's drift.
## A day before the first (yesterday on day 0) reads as today.
func exchange_worth(cur: String, day := -1) -> float:
	if cur == "tins":
		return 1.0
	var d: int = exchange_day if day < 0 else maxi(0, day)
	return float(Data.EXCHANGE_BASE.get(cur, 0.0)) * inflation() * exchange_drift(cur, d)


## What the exchange keeps either way: EXCHANGE_SPREAD, the Fence's Contacts less.
func exchange_spread() -> float:
	return Data.FX["yard/contacts"] if yard_has("contacts") else Data.EXCHANGE_SPREAD


## The Fence's Fixer: more on every trade.
func exchange_fixer() -> float:
	return Data.FX["yard/fixer"] if yard_has("fixer") else 1.0


## One of `from` buys this much `to` today: worth over worth, less the spread, the Fixer's on top.
func exchange_rate(from: String, to: String, day := -1) -> float:
	if from == to or from in EXCHANGE_BUY_ONLY:
		return 0.0                            # scrap buy-only (28 Oct, the review): never given
	var wt: float = exchange_worth(to, day)
	if wt <= 0.0:
		return 0.0
	# the day's drift only ever goes against you (the review: buy on a cheap day, sell on a dear one, and a free drift
	# beat the spread - a money pump): what you give is worth at most its base, what you get costs at least its base
	var give: float = exchange_worth(from, day) / maxf(0.0001, exchange_drift(from, _ex_day(day))) * minf(1.0, exchange_drift(from, _ex_day(day))) if from != "tins" else 1.0
	var get_w: float = wt / maxf(0.0001, exchange_drift(to, _ex_day(day))) * maxf(1.0, exchange_drift(to, _ex_day(day))) if to != "tins" else 1.0
	return give / get_w * (1.0 - exchange_spread()) * exchange_fixer()


func _ex_day(day: int) -> int:
	return exchange_day if day < 0 else maxi(0, day)


## What `amount` of `from` gets of `to` now, rounded down.
func exchange_get(from: String, to: String, amount: int) -> int:
	return int(floor(float(amount) * exchange_rate(from, to)))


## Why a trade can't go now, or "": the Fence shut, the runner out, a pair not on, the amount.
func exchange_block(from: String, to: String, amount: int) -> String:
	if not room_open("fence"):
		return "The Fence isn't open"
	if mission != null:
		return "The runner is out"
	var on := exchange_offered()
	if from in EXCHANGE_BUY_ONLY and on.has(to):
		return "%s is bought, never sold" % exchange_name(from)     # scrap buy-only (28 Oct, the review)
	if from == to or not on.has(from) or not on.has(to):
		return "Pick two to trade"
	if amount <= 0:
		return "Nothing to give"
	if amount > exchange_held(from):
		return "Not that much held"
	if exchange_get(from, to, amount) <= 0:
		return "Too little for one"
	return ""


func can_exchange(from: String, to: String, amount: int) -> bool:
	return exchange_block(from, to, amount) == ""


## A trade: `amount` of `from` for what it gets of `to`, rounded down.
func exchange(from: String, to: String, amount: int) -> bool:
	if not can_exchange(from, to, amount):
		return false
	var got: int = exchange_get(from, to, amount)
	var rate: float = exchange_rate(from, to)
	_exchange_add(from, -amount)
	_exchange_add(to, got)
	log_event(Words.LOG["exchange"] % [amount, exchange_name(from).to_lower(), got, exchange_name(to).to_lower()])
	chron("exchange", {"from": from, "to": to, "give": amount, "got": got, "day": exchange_day, "rate": snappedf(rate, 0.0001)})
	return true


func _unique_named(name: String) -> Dictionary:
	for u in Data.UNIQUES:
		if u["name"] == name:
			return u
	for u in Data.ISSUED:
		if u["name"] == name:
			return u                         # issued kit (25 Oct): the Issuer's, read as a unique
	return {}


# ------------------------------------------------------------------ issued kit (25 Oct, the Issue)

func issued_def(slot: String) -> Dictionary:
	for u in Data.ISSUED:
		if str(u["slot"]) == slot:
			return u
	return {}


## The piece the counter offers for a slot, at the reach: rolled fresh (no number till it's bought).
## The piece the counter (or a head) has for `slot`: the same one every read; `fresh` a copy of its own to keep.
func issued_piece(slot: String, at := -1, fresh := false) -> Dictionary:
	var u := issued_def(slot)
	if u.is_empty():
		return {}
	var lv: int = (maxi(1, reach) + Data.ISSUED_OVER) if at < 0 else at     # a County head's at his level (25 Oct)
	var key := "%s|%d|%d" % [slot, lv, issued_serial]
	var it: Dictionary = _issued_cache.get(key, {})
	if it.is_empty():
		var r := RandomNumberGenerator.new()
		r.seed = hash([slot, lv, issued_serial])     # its own dice: what the counter shows is what's bought, and the run's dice don't move
		it = Items.roll_unique(u, r, lv)
		it["ilvl"] = lv
		it["lift"] = Data.ISSUED_LIFT
		it["issued"] = true
		it["affixes"] = Items._scaled(u["affixes"], lv)
		if _issued_cache.size() > 64:
			_issued_cache.clear()
		_issued_cache[key] = it                  # read once a key (the third review: a fresh roll and a new id on every price check)
	return Items.one_of(it) if fresh else it


var _issued_cache := {}


func issued_price(slot: String) -> int:
	var it := issued_piece(slot)
	return -1 if it.is_empty() else maxi(1, _inf(Items.worth(it) * Data.ISSUED_PRICE))


func issued_block(slot: String) -> String:
	if not issued:
		return Words.ISSUED["not_yet"]
	if mission != null:
		return Words.ISSUED["on_a_run"]
	var wl: int = wear_lock(issued_piece(slot))
	if wl > 0:
		return Words.ISSUED["wear_at"] % wl          # the third review: six item-level-60 pieces sold to a level-50 runner, none wearable
	if cash < float(issued_price(slot)):
		return Words.ISSUED["short"]
	if not fits_with_mag(issued_piece(slot)):
		return Words.ISSUED["no_room"]
	return ""


func buy_issued(slot: String) -> bool:
	if issued_block(slot) != "":
		return false
	var paid := float(issued_price(slot))
	var it := issued_piece(slot, -1, true)
	issued_serial += 1
	it["serial"] = issued_serial
	cash -= paid
	stash.append(it)
	_mag_with(it)
	_read(it)
	chron("issued", {"slot": slot, "serial": issued_serial, "fiat": int(paid)})
	log_event(Words.ISSUED["bought"] % [Items.full_name(it), fiat_words(paid)])
	return true


## Issued pieces worn (the County's zones want them).
func issued_worn() -> int:
	var n := 0
	for sl in Data.SLOTS:
		var it = equipped.get(sl)
		if it != null and (it.get("issued", false) or it.get("stamped", false)) and not issued_def(sl).is_empty():
			n += 1                               # a piece of your own stamped at the Bench counts too (Matt, 26 Oct); only in a slot he issues (29 Oct)
	return n


## Stamping (26 Oct, Matt: "something in crafting that allows the player to stamp a piece of gear they own for entry"):
## at the Bench, a piece of your own kit stamped for the slot's issued price counts towards the County's want, as
## issued kit does; nothing else about it changes. Why it can't be, or "".
func stamp_block(it: Dictionary) -> String:
	if not issued:
		return Words.STAMP["not_yet"]
	if runner_busy():                       # away on a repeat too (30 Oct, the review's refactor 5): the kit's with the runner
		return Words.STAMP["on_a_run"] if mission != null else Words.REPEAT["shut_away"]
	if it.is_empty() or not (str(it.get("slot", "")) in Data.SLOTS):
		return Words.STAMP["not_kit"]
	if issued_def(str(it["slot"])).is_empty():
		return Words.STAMP["no_issue"]                # no issued piece in the slot (29 Oct, the review: a pack stamped for −1 fiat; the gloves)
	if it.get("issued", false):
		return Words.STAMP["issued"]
	if it.get("stamped", false):
		return Words.STAMP["done"]
	if cash < float(stamp_price(it)):
		return Words.STAMP["short"]
	return ""


func stamp_price(it: Dictionary) -> int:
	return issued_price(str(it.get("slot", "")))     # the slot's issued price: keep your own piece or take his, the same either way (Matt)


func stamp(id: int) -> bool:
	var it := item_by_id(id)
	if stamp_block(it) != "":
		return false
	var cost := stamp_price(it)
	cash -= float(cost)
	it["stamped"] = true
	_dry_memo.clear()
	_stats_dirty()
	log_event(Words.STAMP["log"] % [Items.full_name(it), fiat_words(float(cost))])
	chron("stamp", {"slot": str(it["slot"]), "fiat": cost})
	return true


## The issued plate: the order's and the County's fights hit you at a fifth less.
func issued_plate_cut(m: Dictionary) -> float:
	if not has_rule("issued_plate"):
		return 1.0
	var county: bool = (m.has("t") and bool(m["t"].get("county", false))) or _order_mech(m) in ["bailiff", "auditor", "collector", "treasurer"]
	var order: bool = (m.has("signal") and m["signal"] is Dictionary and m["signal"].has("order")) or (m.has("boss") and str(m["boss"].get("order", "")) != "")     # the run's own, not whatever's laid on a site (the third review: another site's odds read mid-run took the cut)
	return Data.FX["rule/issued_plate.cut"] if (county or order) else 1.0


## The Fence's mate: one of the loose uniques, for notes.
## At the player's deepest tier (12 Oct, uniques by tier), one whose range takes it; the tier rides with the offer.
func roll_mate() -> Dictionary:
	var at := shop_unique_tier()
	var u: Dictionary = pick_unique(loose_uniques(deepest()), at, true)    # his deep stock opens as you go deeper
	var tier_v: int = Items.unique_tier(u, at)
	return {"unique": u["name"], "tier": tier_v, "notes": Data.MATE_NOTES * tier_v}


## The tier a shop's unique comes at (the mate, the Back room, a gamble): the loot tier of the deepest site dug.
func shop_unique_tier() -> int:
	return best_tier_open()


## The mate's offer, rolled: at its tier (a save from before the tiers has none: its own base's).
func _mate_item() -> Dictionary:
	var u := _unique_named(mate["unique"])
	if u.is_empty():
		return {}
	return Items.roll_unique(u, rng, gamble_level(), int(mate.get("tier", -1)))     # at the gamble's level: it scales as a find (21 Oct)


func can_buy_mate() -> bool:
	if not room_open("fence") or mission != null or mate.is_empty() or notes < int(mate["notes"]):
		return false
	var it := _mate_item()
	return not it.is_empty() and fits_with_mag(it)


func buy_mate() -> bool:
	if not can_buy_mate():
		return false
	notes -= int(mate["notes"])
	var it := _mate_item()
	stash.append(it)
	_mag_with(it)
	_read(it)
	log_event(Words.LOG["mate"] % [int(mate["notes"]), it["unique"]])
	mate = roll_mate()
	return true


## The deepest site and depth held in this yard, for the wall: [site name, depth], ["", 0] with nothing cleared.
func _deepest_held() -> Array:
	var best := -1
	var at := 0
	for i in range(Data.TIERS.size()):
		if best_depth[i] > at or (best_depth[i] == at and at > 0 and i > best):
			at = best_depth[i]
			best = i
	return [Data.TIERS[best]["name"] if best >= 0 else "", at, lv_at(best, at) if best >= 0 else 0]     # the level for the screens (18 Oct)


# ------------------------------------------------------------------ what's next

## The first ten minutes, and every minute after: what the Yard would say to
## do next, from where the campaign stands. The log carries it when it changes.
func next_words(short := false) -> String:
	var w: Dictionary = Words.NEXT_SHORT if short else Words.NEXT
	if cls == "":
		return w["past"]
	if runs_total == 0:
		return w["first"]
	if can_hand_in():
		return w["supplies"]  # supplies waiting on the medic (28 Oct, Matt: as a ready contract was), the endgame's too
	if campaign_done():     # the lorry's line is the log's, once (21 Oct: the move it pointed at is gone)
		return w["done"] % convoy_depth() if "%d" in w["done"] else w["done"]
	for z in range(Data.ZONES.size()):
		if zone_complete(z):
			continue
		if not zone_open(z):
			if zone_level_shut(z):
				return w["level"] % zone_gate(z)
			break
		for i in Data.ZONES[z]["tiers"]:
			if stage_done(int(i)) < Data.STAGE_OPENS:     # (BUILD55-A) the 2/3 that opens the next
				return w["site"] % (Words.mid(str(Data.TIERS[i]["name"])) if not short else Data.TIERS[i]["name"])     # (FIX55, the language pass) mid-sentence: "at the Pleasure Park"
		for b in Data.BOSSES:
			if int(b["zone"]) == z and not bosses_beaten[z]:
				return (w["head"] % [b["name"], Words.mid(Data.TIERS[int(b["tier"])]["name"])]) if not short else (w["head"] % Words.mid(b["name"]))
	return w["done"] % convoy_depth() if "%d" in w["done"] else w["done"]


## Say it once, when it changes; the Yard's set line says it first.
func _say_next() -> void:
	var w := next_words()
	if w != last_next:
		last_next = w
		log_event(w)


# ------------------------------------------------------------------ the places changing

## The Yard's clock: hours on the 24, from the morning the Yard opened.
func hour_of_day() -> float:
	return fmod(Data.CLOCK_START + elapsed / 3600.0, 24.0)


func is_night() -> bool:
	var h := hour_of_day()
	return h >= Data.NIGHT_FROM or h < Data.NIGHT_TO


func clock_words() -> String:
	var h := hour_of_day()
	return "%02d:%02d" % [int(h), int(fmod(h, 1.0) * 60.0)]


## The weather by zone, rolled once an hour of the Yard's time.
func _roll_weather() -> void:
	var hour := int(elapsed / (Data.WEATHER_H * 3600.0))
	if hour == weather_at:
		return
	weather_at = hour
	_dry_memo.clear()                     # the weather is in the figures (fast_memo)
	_stats_dirty()
	for z in range(Data.ZONES.size()):
		var odds: Array = Data.WEATHER_ODDS[mini(z, Data.WEATHER_ODDS.size() - 1)]
		var r := rng.randf()
		weather[z] = "Rain" if r < float(odds[0]) else ("Fog" if r < float(odds[0]) + float(odds[1]) else "")


func weather_of(i: int) -> String:
	return str(weather[int(Data.TIERS[i]["zone"])])


## The sky in a site's fight: its zone's, but no rain under a roof (Data.INDOOR_SITES; the Map keeps the zone's).
func fight_weather_of(i: int) -> String:
	var w := weather_of(i)
	return "" if w == "Rain" and str(Data.TIERS[i]["name"]) in Data.INDOOR_SITES else w


## A crate back on a picked-over site every this long (27 Oct, the trickle): half again as fast a rank of Worn in.
func crate_trickle_s() -> float:
	return Data.CRATE_TRICKLE_S / (1.0 + Data.FX["atlas/worn_in"] * atlas_rank("worn_in"))


## Whether a run's crates are the site's to remember: a campaign run, not a signal's, a dry read or the balance's.
static func _site_keeps(m: Dictionary) -> bool:
	return not m.get("dry", false) and not m.has("signal") and not m.get("crates_off", false)


## The site's crates now, as the Map reads them: [what was left, crates back since, the full set] - [] for fresh.
func site_stock(i: int) -> Array:
	var e: Dictionary = site_crates.get(str(i), {})
	if e.is_empty():
		return []
	var left: Array = e.get("left", [])
	var full: int = int(e.get("full", left.size()))
	var back: int = mini(maxi(0, full - left.size()), int(floor(maxf(0.0, elapsed - float(e.get("at", elapsed))) / crate_trickle_s())))
	if left.size() + back >= full:
		return []                             # all back: fresh
	return [left, back, full]


## The run's end at a campaign site: the crates it didn't open wait there, part-searched as they were, the dog's nose on
## them (27 Oct). A locked one passed over without the Keys isn't kept.
func _site_remember(m: Dictionary) -> void:
	if not _site_keeps(m) or not m.has("crates"):
		return
	var cs: Array = m["crates"]
	var i: int = int(m.get("crate_i", 0))
	var left: Array = []
	for j in range(i, cs.size()):
		var q: Dictionary = cs[j]
		if q.get("passed", false) or int(q["done"]) >= int(q["searches"]):
			continue
		var kept: Dictionary = q.duplicate(true)
		kept["finds"] = []
		left.append(kept)
	site_crates[str(m["tier"])] = {"left": left, "at": elapsed, "full": maxi(int(m.get("crates_n", cs.size())), left.size())}


## The search's crates from what the site kept: what was left, then a fresh crate a trickle since, up to the full set.
## False when the site's fresh (no memory, or all back): the dice roll a full set as ever.
func _site_resume(m: Dictionary, fresh: Array) -> bool:
	if not _site_keeps(m):
		return false
	var key := str(m["tier"])
	var st: Array = site_stock(int(m["tier"]))
	site_crates.erase(key)                    # the run has them now; its end writes what's left again
	if st.is_empty():
		return false
	var queue: Array = []
	for q in st[0]:
		var c: Dictionary = q.duplicate(true)
		c["done"] = int(c["done"])
		c["searches"] = int(c["searches"])
		c.erase("passed")
		queue.append(c)
	for k in range(mini(int(st[1]), fresh.size())):
		queue.append(fresh[k])
	m["crates"] = queue
	m["crates_n"] = int(st[2])
	m["crate_i"] = 0
	m["crates_none"] = queue.is_empty()       # picked clean already, nothing back yet: nothing for this run to open
	return true


## The player's pick of the next crate (27 Oct): the one clicked goes next - straight away if the one in hand isn't
## started, else once it's done. Never one passed over, nor one already open.
func crate_pick(j: int) -> bool:
	if mission == null or not mission.has("crates"):
		return false
	var cs: Array = mission["crates"]
	var i: int = int(mission.get("crate_i", 0))
	if j <= i or j >= cs.size() or cs[j].get("passed", false) or (cs[j].get("locked", false) and not has_keys()):
		return false
	var to: int = i if i < cs.size() and int(cs[i]["done"]) == 0 else i + 1
	if j != to:
		var q: Dictionary = cs[j]
		cs.remove_at(j)
		cs.insert(to, q)
	if to == i:
		mission["search"] = 0.0               # a fresh start on the one picked
	return true


## The item level the runner can wear now: the highest whose wear level is theirs or under (16 Oct).
func wearable_level() -> int:
	return Items.max_ilvl_for(level())     # wear_for's inverse (21 Oct): no top at the cap, so a level-50 runner's fifth drops at the signal's own level


## The runner's level an item level asks to be worn.
static func wear_of(item_level: int) -> int:
	return Items.wear_level({"slot": "Primary", "base": "", "tier": 1, "ilvl": item_level})


## A site's or a signal's finds, in the runner's terms (16 Oct, Matt: "if the bank says it drops level 6 gear then my
## expectation is that i need to be level 6"): the level to wear them, and the fifth at the runner's when that's lower.
func finds_words(item_level: int) -> Array:
	return [str(wear_of(item_level))]         # the Gear level tile's figure (18 Oct, Matt: "just a number", the same on every site)


## The site's state, for the card: fresh, settling, or picked over and when it's back.
## The level a gamble rolls at (15 Oct, the loot read): your deepest site's, as its drops - but never past what the
## runner can wear (the review: a deep signal's level would padlock every gamble for the endgame).
func gamble_level() -> int:
	return clampi(deepest_cleared_level(), 1, maxi(1, Items.max_ilvl_for(level())))


## A loose unique a find (15 Oct, the loot read): a trickle from the Town on, growing with the depth, capped.
func unique_odds(t: Dictionary) -> float:
	var z: int = int(Data.TIERS[int(t["tier"])]["zone"])
	var base: float = Data.UNIQUE_CAMPAIGN if z >= Data.UNIQUE_FROM_ZONE else 0.0
	return minf(Data.UNIQUE_CAP, base + Data.UNIQUE_DROP * maxi(0, int(t["depth"]) - 1))     # (FIX55, review 6) intended: a stage's depth counts too - the Town's and the City's 3/3 roll loose uniques at the cap, a 3/3's reward


## A find's mythic (16 Oct, docs/design/mythics.md): one in MYTHIC_ODDS_IN on its own dice, wherever it is; one held
## (worn or stashed) isn't rolled again until all seven are. {} for none.
func mythic_roll() -> Dictionary:
	if not mythics_on or mythic_rng.randi_range(1, Data.MYTHIC_ODDS_IN) != 1:
		return {}
	return mythic_pick()


func mythic_pick() -> Dictionary:
	var held: Array = []
	for it in stash:
		if it.get("mythic", false):
			held.append(str(it["unique"]))
	for s in Data.SLOTS:
		if equipped[s] != null and equipped[s].get("mythic", false):
			held.append(str(equipped[s]["unique"]))
	var all: Array = Data.UNIQUES.filter(func(u): return u.get("mythic", false))
	var fresh: Array = all.filter(func(u): return not (str(u["name"]) in held))
	var pool: Array = fresh if not fresh.is_empty() else all
	return pool[mythic_rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else {}


## A search's find at a site being a paper (the Map's Papers tile, 15 Oct; the find's own roll).
func paper_odds(i: int) -> float:
	var shape: Dictionary = Data.TIERS[i]["shape"]
	return Data.PAPER_DROP * float(shape.get("paper", 1.0)) * (Data.FX["node/light_fingers.papers"] if has_node("light_fingers") else 1.0) * (Data.FX["yard/tracker.papers"] if yard_has("tracker") else 1.0) \
		* (1.0 + town_stat("paper_pct") / 100.0) * (2.0 if has_rule("registrars_satchel") else 1.0)     # the library, the Registrar's Satchel (18 Oct)


## The site's crates for the Map's tile (27 Oct): fresh; what's left there, the best first; or picked clean and when a
## crate's back. Long to short.
func site_state_forms(i: int) -> Array:
	var st: Array = site_stock(i)
	if st.is_empty():
		return [Words.SKY["fresh"]]
	var n: int = Array(st[0]).size() + int(st[1])
	if n == 0:
		var e: Dictionary = site_crates.get(str(i), {})
		var wait: float = crate_trickle_s() - fmod(maxf(0.0, elapsed - float(e.get("at", elapsed))), crate_trickle_s())
		var when := "%d min" % maxi(1, int(ceil(wait / 60.0)))
		return [Words.SKY["clean"] % when, Words.SKY["clean_short"] % when, Words.SKY["clean_tiny"]]     # (28 Oct: "Clean · 3 min" ran past the Map's 128 px tile)
	var best: Array = Array(st[0]).duplicate()
	best.sort_custom(func(a, b): return int(crate_def(str(a["key"])).get("searches", 1)) > int(crate_def(str(b["key"])).get("searches", 1)))
	var top: String = str(crate_def(str(best[0]["key"])).get("short", best[0]["name"])) if not best.is_empty() else ""
	var forms: Array = []
	if top != "" and n > 1:
		forms.append(Words.SKY["left_top"] % [top, n - 1])
	elif top != "":
		forms.append(top)
	forms.append(Words.SKY["left"] % [n, "" if n == 1 else "s"])
	return forms


## The sky over a site, in words: the clock, night or day, the weather.
func sky_words(i: int, with_weather := true) -> String:
	var w := fight_weather_of(i) if with_weather else ""     # the site's own: dry under a roof
	return "%s, %s%s" % [clock_words(), Words.SKY["night"] if is_night() else Words.SKY["day"], (", " + Words.SKY[w.to_lower()]) if w != "" else ""]


# ------------------------------------------------------------------ the papers as the book

## Whether a room a head opens is open (the clinic, the fence, the yard, the radio, the workshop); any other is.
func room_open(key: String) -> bool:
	return not (key in Data.ROOMS_SHUT) or key in unlocked


## The room a Yard building serves ("" for one that serves none): the Bench is the Workshop's.
static func building_room(key: String) -> String:
	return {"bench": "workshop", "clinic": "clinic", "fence": "fence", "radio": "radio"}.get(key, "")


## Every room open (the tests' camps).
func unlock_all() -> void:
	unlocked = Data.ROOMS_SHUT.duplicate()


## The deeds in the stash or the pack (a second drop is never wanted then).
func _deeds_held(m: Dictionary) -> bool:
	for it in stash + Array(m.get("found", [])):
		if Items.is_deeds(it):
			return true
	return false


## A head's thing left behind (2 Nov, BUILD46-S; the designer: "the room at half until fetched"): the drop still opens
## its room, but at half - each room its one plain handicap - until the thing is home. It turns up again as a find on
## the next clear of the site it was lost at (_left_find). The halves: the Clinic rests at half speed and stocks half
## her shelf (rest_rate, clinic_stock); the Fence's shelf half (market_stock); the Workshop's scrap from breaking down
## half (scrap_yield); the Pitch's builds at double (yard_pick_cost, yard_rank_cost); the Radio holds half the signals
## (signals_cap).
const HALF_ROOMS := ["clinic", "fence", "workshop", "yard", "radio"]


func room_half(key: String) -> bool:
	if not left_behind.has(key) or not room_open(key):
		return false
	return key != "yard" or deeds_fate == ""     # the deeds' fate decided (sold, burned) frees the Pitch: they never drop again


## The thing that opens a room, by name ("The vet's bag"); "" for a room no head opens.
static func room_thing(key: String) -> String:
	for b in Data.BOSSES:
		if b.get("opens", {}).has(key):
			return str(b["opens"][key])
	return ""


## The site a room's thing waits at; -1 when the room is whole.
func half_site(key: String) -> int:
	return int(left_behind.get(key, -1)) if room_half(key) else -1


## The rooms whose things wait at site i (the Map card's bring-home tile).
func waits_at(i: int) -> Array:
	return HALF_ROOMS.filter(func(r): return half_site(r) == i)


## The signals the Radio holds: half, rounded up, while its set is still out.
func signals_cap() -> int:
	return ceili(Data.SIGNALS_HELD / 2.0) if room_half("radio") else Data.SIGNALS_HELD


## A head's thing dropped on a run: its room waits at half on this site till the thing's home.
func _left_drop(room: String, m: Dictionary) -> void:
	if _dry_on or m.get("dry", false):
		return
	left_behind[room] = int(m["tier"])


## A thing home: its room is whole.
func _left_home(it: Dictionary) -> void:
	var room: String = Items.opens(it)
	if room == "" or not left_behind.has(room):
		return
	var was: bool = room_half(room)
	left_behind.erase(room)
	if was and not _dry_on:
		var nm: String = str(it["base"])
		var rm: String = Words.cap1(str(Words.HALF["room"][room]))
		log_event(Words.HALF["whole"] % [(nm + " are") if nm == "The deeds" else (nm + "'s"), rm + "'s"])     # are / 's by the thing's name, as main.half_forms (fix 46, S4; the language pass)


## A site cleared where a thing waits: it turns up again, in the pack (the deeds as the head drops them).
func _left_find(m: Dictionary) -> void:
	if _dry_on or m.get("dry", false) or m.get("signal", {}).has("order"):
		return
	for room in waits_at(int(m["tier"])):
		var nm: String = room_thing(str(room))
		if Array(m["found"]).any(func(x): return str(x.get("base", "")) == nm) or (room == "yard" and _deeds_held(m)):
			continue
		var thing := _plain(Data.PAPER, nm)
		if Items.is_deeds(thing):
			thing["deeds"] = true
		m["found"].append(thing)
		log_event(Words.HALF["found"] % [nm, "turn" if nm == "The deeds" else "turns", Words.mid(str(Data.TIERS[int(m["tier"])]["name"]))])


## The Map card's "You here" (2 Nov, BUILD46-S): a run's end at its site - tried, cleared and how fast, how it ended.
## A County place's run isn't its host's.
func _site_run_note(m: Dictionary, outcome: String, extra: Dictionary) -> void:
	if m.get("signal", {}).has("order"):
		return
	var k := str(int(m["tier"]))
	var r: Dictionary = site_runs.get(k, {"tries": 0, "clears": 0, "best": -1.0})
	r["tries"] = int(r["tries"]) + 1
	if bool(m.get("cleared", false)) and float(m.get("clear_t", -1.0)) >= 0.0:
		r["clears"] = int(r["clears"]) + 1
		var t: float = float(m["clear_t"])
		r["best"] = t if float(r["best"]) < 0.0 else minf(float(r["best"]), t)
	r["last"] = outcome
	r["last_t"] = snappedf(float(m["elapsed"]), 0.1)
	r["last_full"] = int(extra.get("pack", 0)) >= int(extra.get("cap", 1 << 30))
	site_runs[k] = r


## A site's record: {tries, clears, best (s, -1 none), last ("" none), last_t, last_full}.
func site_record(i: int) -> Dictionary:
	var r: Dictionary = site_runs.get(str(i), {})
	return {"tries": int(r.get("tries", 0)), "clears": int(r.get("clears", 0)), "best": float(r.get("best", -1.0)),
		"last": str(r.get("last", "")), "last_t": float(r.get("last_t", 0.0)), "last_full": bool(r.get("last_full", false))}


## A head's thing: its room opens (at the drop; again a no-op home), the log and the radio say so; true unless it's
## kept (the deeds are, for their fate: held, sold or burned).
func _home_gate(it: Dictionary) -> bool:
	var room: String = Items.opens(it)
	if room == "":
		return false
	if not (room in unlocked):
		unlocked.append(room)
		chron("open", {"room": room})
		if not Items.is_deeds(it) and not (str(it["base"]) in keepsakes):
			keepsakes.append(str(it["base"]))     # the drawer keeps it (15 Oct)
		if room == "radio":
			_read_held()
		if not _dry_on:
			log_event(Words.GATES[room])
			for b in Data.BOSSES:
				if b.get("opens", {}).has(room):
					_hear_gate(str(b["name"]) + "/after")
	return not Items.is_deeds(it)


## A gate's line on the radio, once (its key in what's heard).
func _hear_gate(gate: String) -> void:
	for k in range(Words.RADIO.size()):
		var r: Dictionary = Words.RADIO[k]
		if str(r.get("gate", "")) == gate:
			var key := "%s/%d" % [r["voice"], k]
			if not (key in heard) and not _dry_on:
				heard.append(key)
				log_event(Words.RADIO_LEAD + str(r["text"]))     # every line at the gate (27 Oct: the Manager's opens two rooms, a line each)


## A gate's "before" line is done with once every room its head opens is open (13 Oct, Matt: the Clinic saved, the
## medic still asking for the bag on the strip). Any other line, false.
func gate_line_done(r: Dictionary) -> bool:
	var gate: String = str(r.get("gate", ""))
	if not gate.ends_with("/before"):
		return false
	for b in Data.BOSSES:
		if str(b["name"]) + "/before" == gate:
			for room in b.get("opens", {}):
				if not room_open(str(room)):
					return false
			return true
	return false


## The line before a room opens: once its head's site is open and the room isn't.
func _gate_lines() -> void:
	for b in Data.BOSSES:
		var shut := false
		for room in b.get("opens", {}):
			shut = shut or not room_open(str(room))
		if shut and tier_open(int(b["tier"])):
			_hear_gate(str(b["name"]) + "/before")


## A paper picked up is read, and goes in the drawer by name, once, in the order found - once the Radio's open to read
## it (15 Oct: encrypted till then; the Radio reads every one held when it opens).
func _read(it: Dictionary, quiet := false) -> void:
	if Items.is_paper(it) and not Items.is_deeds(it) and not (it["base"] in book) and room_open("radio") and story_of(it) < 0 and Items.opens(it) == "":     # Kev's aren't the drawer's (the review)
		book.append(it["base"])
		chron("paper", {"name": str(it["base"]), "pages": book.size()})
		var taught := word_taught_by(str(it["base"]))
		if taught != "" and not _dry_on and not quiet:
			log_event(Words.LOG["paper_code"] % [it["base"], taught.to_lower()])     # map juicing (9 Oct): a paper carries its code (13 Oct: codes, not words)
	if it.has("unique") and not it.get("issued", false) and not (it["unique"] in shelf):     # issued kit isn't a find for the shelf (the third review: the count ran past its "of N")
		shelf.append(it["unique"])
		chron("unique", {"name": str(it["unique"]), "shelf": shelf.size(), "tier": int(it.get("tier", 0))})
	if it.has("set") and it.has("piece") and not (str(it["piece"]) in sets_seen):
		sets_seen.append(str(it["piece"]))
	if it.has("unique") and not Items.is_paper(it):
		shelf_tier[it["unique"]] = maxi(int(shelf_tier.get(it["unique"], 0)), int(it.get("tier", 0)))


## The Radio open (15 Oct): every paper held is read at once, the codes on them in one line.
func _read_held() -> void:
	var before: int = book.size()
	var held: Array = stash.duplicate()
	held.append_array(papers)
	if mission != null:
		held.append_array(mission["found"])
	for it in held:
		_read(it, true)
	if book.size() > before and not _dry_on:
		log_event(Words.RADIO_READ % (book.size() - before))


## What a paper's pick says on the right (15 Oct; the papers' parked item: it said "In the drawer, in Training"):
## [title, line, line].
func paper_lines(it: Dictionary) -> Array:
	if Items.is_deeds(it):
		return ["The deeds", "Held, sold or burned", "Bricks, not money: the Issue can't touch them"]
	if str(it.get("rule", "")) != "":
		return ["The drawer", "Works from the stash", "Keep it"]     # a unique's rule paper (the Lorry Driver's Log)
	if story_of(it) >= 0:
		return ["Kev's story", str(Data.STORY_BEATS[story_of(it)]["name"]), "Three of Kev's story papers together make a signal"]
	if not room_open("radio"):
		return ["Encrypted", "Read once the Radio's open", "Keep it: a key to the endgame"]
	var code: String = word_taught_by(str(it["base"]))
	return ["The Radio", "Carries %s" % code.to_lower() if code != "" else "No code: a line of the before",
		"Rare: rolls the signal 1 level higher" if int(it.get("rarity", 0)) >= Data.PAPER_DEEPER_AT else "Three make a signal"]


## Kev's papers (16 Oct): a plain paper from the pile for notes - KEV_RUNS runs' notes on the top open site, a kill's
## notes at the depth of your reach (the read after: a flat price let a late build buy 48 and retire at 6.5 h).
func kev_price() -> int:
	var d: int = tier_depth(reach) if campaign_done() else 1
	var a_kill: float = ceilf(Data.NOTES_KILL * (1.0 + (d - 1) / 3.0))
	return maxi(Data.KEV_FLOOR, roundi(Data.KEV_RUNS * float(Data.TIERS[top_tier()]["pool"]) * a_kill))


## Why Kev can't sell one now, or "".
func kev_block() -> String:
	if not room_open("radio"):
		return "the Radio's shut"
	if not campaign_done():
		return "the campaign first"            # as a signal: before it, a paper's for its code, and the drops bring those
	if mission != null:
		return "the runner's out"
	if notes < kev_price():
		return "%d notes" % kev_price()
	return ""                                  # his paper goes to the Radio's pile, not the stash (18 Oct)


## Pay the notes, a plain paper in the stash: rolled as a find at the deepest site's level and depth (a rare one still
## rolls a signal deeper), never Kev's story, the deeds or a head's thing. Logged and read into the book. {} when not.
func ask_kev() -> Dictionary:
	if kev_block() != "":
		return {}
	var pages: Array = book_pages()
	var deep := 1
	for i in range(best_depth.size()):
		deep = maxi(deep, dug_depth(i))     # the drops' scale, the Barracks' depth at the level (the review: a site's own depth ran far ahead)
	var it: Dictionary = {}
	for tries in range(40):
		it = Items.roll(Data.PAPER, 1, rng, 0.0, false, false, "", "", 0.33, deep, gamble_level())
		if str(it["base"]) in pages:
			break
		it = {}
	if it.is_empty():
		return {}
	var cost: int = kev_price()
	notes -= cost
	papers.append(it)
	_read(it)
	chron("kev", {"price": cost, "item": _chron_item(it)})
	log_event(Words.LOG["kev_sold"] % [Words.KEV_SOLD, Items.full_name(it).to_lower()])
	return it


## Every paper there is to find, deep ones last.
func book_pages() -> Array:
	var out: Array = []
	for b in Data.BASES[Data.PAPER]:
		if b["name"] != "The deeds" and Items.opens({"slot": Data.PAPER, "base": b["name"]}) == "" and not b.has("story"):     # nor a head's thing (13 Oct), nor Kev's (15 Oct)
			out.append(b["name"])
	return out


# ------------------------------------------------------------------ the estate recycles

## A piece out on the estate: worn by a gang member a few runs from now.
func _lose(it: Dictionary, who: String, from: String) -> void:
	loose_kit.append({"item": it.duplicate(true), "who": who, "from": from, "run": runs_total})
	while loose_kit.size() > Data.RECYCLE_KEEP:
		loose_kit.pop_front()


## At the start of a run: one of a gang may be wearing something off the list.
func _maybe_wearing(m: Dictionary, force := false) -> void:
	if loose_kit.is_empty() or m.get("dry", false):
		return
	if not force and rng.randf() >= Data.RECYCLE_ODDS:
		return
	for k in range(loose_kit.size()):
		var e: Dictionary = loose_kit[k]
		if runs_total - int(e["run"]) >= Data.RECYCLE_RUNS or force:
			loose_kit.remove_at(k)
			m["wearing"] = e
			var it: Dictionary = e["item"]
			if e["from"] == "fence":
				log_event(Words.RECYCLE["has"] % (it["unique"] if it.has("unique") else it["base"].to_lower()))
			else:
				log_event(Words.RECYCLE["wearing"] % [e["who"], it["base"].to_lower()])
			return


## The site's cleared: what he was wearing comes off him, into the pack whatever it holds.
func _wearing_off(m: Dictionary) -> void:
	if not m.has("wearing"):
		return
	var e: Dictionary = m["wearing"]
	m.erase("wearing")
	var it: Dictionary = e["item"]
	it["spared"] = true                       # the runner's own come back: no loot rule touches it (the review)
	it["recovered"] = true                    # and no bag swap spills it (1 Nov, the review): off at home (_pack_unmark)
	m["found"].append(it)
	_read(it)
	if e["from"] == "fence" or it.has("unique"):
		log_event(Words.RECYCLE["off_unique"] % (it["unique"] if it.has("unique") else it["base"]))
	else:
		var who: String = e["who"]
		log_event(Words.RECYCLE["off"] % [Words.mid_base(str(it["base"])), who.substr(0, 1).to_upper() + who.substr(1)])


# ------------------------------------------------------------------ the Bench's crafting

## An item of yours by id: worn, or in the stash.
func item_by_id(id: int) -> Dictionary:
	for s in Data.SLOTS:
		if equipped[s] != null and equipped[s]["id"] == id:
			return equipped[s]
	for it in stash + papers:
		if it["id"] == id:
			return it
	return {}


## What the Bench can do to this item: the price, in cash (notes for a bump);
## -1 for can't. `stat` is the affix picked, for lock and one.
func craft_cost(it: Dictionary, kind: String, _stat := "") -> int:     # the stat: the old pick jobs' (20 Oct: padlocks now)
	var base_v := _craft_cost_raw(it, kind, _stat)
	if base_v > 0 and workbench_free():
		return 0                              # Workbench (22 Oct): one Bench job a day is free
	return base_v


## Workbench: the day's free job not yet had.
func workbench_free() -> bool:
	return has_node("workbench") and workbench_day != int(elapsed / 86400.0)


func _craft_cost_raw(it: Dictionary, kind: String, _stat := "") -> int:
	if kind == "temper":
		return _temper_cash(it)
	if it.is_empty() or it.has("unique") or it.has("set") or Items.is_ammo(it) or Items.is_mag(it) or Items.is_paper(it) or not Data.CRAFT.has(kind):
		return -1                             # a set piece's affixes are the set's: no bench job on one (the pass, 6 Oct)
	var locked: Array = locks_of(it)
	match kind:
		"strip":
			if it["affixes"].is_empty():
				return -1
		"values", "affixes":
			if it["affixes"].size() - locked.size() <= 0:
				return -1                       # nothing left unlocked to roll
		"add":
			if int(it["rarity"]) >= Data.RARITIES.size() - 1 or Items.allowed_affixes(it["slot"]).size() <= it["affixes"].size():
				return -1
		"resist":
			if resist_job_block(it, _stat) != "":
				return -1                       # "Add a resist" (BUILD50-T): its slots, its element not on it already
		"socket":
			if not (it["slot"] in Data.SOCKET_SLOTS) or Items.sockets(it) >= socket_max(it):
				return -1
		"bump":
			if Items.ilvl(it) >= int(it["tier"]) + bump_cap():
				return -1
			return int(Data.CRAFT[kind]["notes"]) * Items.ilvl(it)
	var price_v: int = int(Data.CRAFT[kind]["cash"]) * Items.ilvl(it) * (int(it["rarity"]) + 1)
	if kind == "values":
		var tiers := 0
		for a in it["affixes"]:
			if not (a["stat"] in locked):
				tiers += int(a.get("tier", 1))     # the better the tiers rolled again, the dearer
		price_v *= tiers
	if kind in ["values", "affixes"]:
		price_v = int(round(price_v * (1.0 + Data.LOCK_PRICE * locked.size())))     # a padlock adds to it
	if yard_has("cheap_parts"):
		price_v = int(round(price_v * Data.FX["yard/cheap_parts"]))      # the Bench's Cheap parts
	return _inf(price_v)


## Tempering (25 Oct, the review: nothing on the runner's side compounded, so the reach ran away or stood): a piece past
## the Bench's raise (a unique or a set piece at any level, never a mythic) one item level up, for scrap that grows
## TEMPER_GROW a level past the raise and money by its worth (the second review). Not past what the runner can wear.
func temper_over(it: Dictionary) -> int:
	return int(it.get("tempered", 0))         # the tempers it has had (the review: a unique rolled deep started 30 "over")


## A temper's scrap: by the piece's item level, as its worth and its scrap grow, so price and income climb together and
## a low piece is cheap to catch up (the second review: by the count, the price outran income and the reach stood).
func temper_scrap(it: Dictionary) -> int:
	return int(round(float(Data.CRAFT["temper"]["scrap"]) * pow(Data.TEMPER_GROW, maxi(0, Items.ilvl(it) - Data.ILVL_GROW_FROM))))


func temper_block(it: Dictionary) -> String:
	if it.is_empty() or not (str(it.get("slot", "")) in Data.SLOTS):
		return Words.TEMPER["no_piece"]
	if it.get("mythic", false):
		return Words.TEMPER["mythic"]
	var special: bool = it.has("unique") or it.has("set")
	if not Items.grows(it):
		return Words.TEMPER["no_grow"]          # a rig, a pack, a charm: nothing on it grows (the second review)
	if not special and Items.ilvl(it) < int(it["tier"]) + bump_cap():
		return Words.TEMPER["raise_first"]
	var next: Dictionary = it.duplicate()
	next["ilvl"] = Items.ilvl(it) + 1
	next["tempered"] = temper_over(it) + 1
	if Items.wear_level(next) > level():
		return Words.TEMPER["too_high"]         # its first TEMPER_PAST_WEAR tempers don't raise its wear (the second review)
	return ""


func _temper_cash(it: Dictionary) -> int:
	if temper_block(it) != "":
		return -1
	return maxi(1, _inf(Items.worth(it) * Data.TEMPER_CASH))     # a share of the piece's worth, so the sink grows with income; not the Fence's bonuses (the second review, and its reviewer)


## The Bench's padlocks (20 Oct): the stats locked on a piece (still on it), how many it may have, and the toggle.
func locks_of(it: Dictionary) -> Array:
	var have: Array = it.get("affixes", []).map(func(a): return str(a["stat"]))
	return it.get("locks", []).filter(func(s): return str(s) in have)


func lock_max() -> int:
	return Data.LOCKS + (1 if yard_has("two_locks") else 0)


## Why a padlock can't go on (or come off) this affix now, or "".
func lock_block(it: Dictionary, stat: String) -> String:
	if it.is_empty() or it.has("unique") or it.has("set"):
		return "Nothing to lock on it"
	if not it.get("affixes", []).any(func(a): return str(a["stat"]) == stat):
		return "No such affix"
	var locked: Array = locks_of(it)
	if stat in locked:
		return ""
	if locked.size() >= lock_max():
		return "%d of %d padlocks on" % [locked.size(), lock_max()]
	if locked.size() + 1 >= it["affixes"].size():
		return "One has to stay unlocked"
	return ""


func toggle_lock(id: int, stat: String) -> bool:
	var it := item_by_id(id)
	if lock_block(it, stat) != "":
		return false
	var locked: Array = locks_of(it)
	if stat in locked:
		locked.erase(stat)
	else:
		locked.append(stat)
	it["locks"] = locked
	return true


func craft_in_notes(kind: String) -> bool:
	return Data.CRAFT.get(kind, {}).has("notes")


# ------------------------------------------------------------------ scrap and the Build column (34)

## What an item is worth in scrap: its value over SCRAP_PER_POUND, a stack by what it holds.
func scrap_of(it: Dictionary) -> int:
	if it.is_empty() or Items.is_deeds(it):
		return 0
	return int(Items.worth(it) / Data.SCRAP_PER_POUND) * (Data.FX["yard/strip_for_parts"] if yard_has("strip_for_parts") else 1)


## The Kit room's bin (13 Oct, Matt's playtest: the stash full with the Fence and the Workshop shut): a stash thing
## thrown out, at any time, gone for good - for nothing (27 Oct, Matt: scrapping is the Workshop's). Never the deeds.
func can_bin(it: Dictionary) -> bool:
	return not it.is_empty() and not Items.is_deeds(it) and stash.has(it)


func bin(id: int) -> bool:
	for it in stash:
		if int(it["id"]) == id:
			if not can_bin(it):
				return false
			_remove(it)                       # gone for good: a binned unique isn't one of the gangs' to wear again (the review)
			chron("bin", {"item": _chron_item(it), "scrap": 0})
			log_event(Words.LOG["binned"] % (Items.full_name(it).to_lower() if not it.has("unique") else Items.full_name(it)))
			return true
	return false


## What scrapping a thing at the Workshop gives: its scrap, half again with Salvage (27 Oct: from the ditch to the Workshop).
func scrap_yield(it: Dictionary) -> int:
	return int(ceil(scrap_of(it) * (Data.FX["node/salvage"] if has_node("salvage") else 1.0) * (0.5 if room_half("workshop") else 1.0)))     # the fitter's kit still out (BUILD46-S)


## A stash item broken down at the Bench for its scrap. Gone for good.
func scrap_item(id: int) -> bool:
	if runner_busy() or not room_open("workshop"):     # away on a repeat too (30 Oct, refactor 5): the Bench waits, as it does on a run
		return false
	for it in stash:
		if it["id"] == id:
			var bits: int = scrap_yield(it)
			_remove(it)
			scrap += bits
			if yard_has("salvage_line") and int(it.get("rarity", 0)) >= 2:
				salvage["steel"] = int(salvage["steel"]) + 1      # the Bench's Salvage line
			last_craft = {"id": -1, "kind": "scrap", "words": "Scrapped %s: %d scrap" % [it["base"].to_lower(), bits]}     # the Bench's foot and the toast read it (8 Oct)
			chron("scrap", {"item": _chron_item(it), "scrap": bits})
			log_event(last_craft["words"])
			return true
	return false


## The stash's standard boxes of this base, as rounds; a full box of them is what a grade wants.
func _rounds_in_stash(base_name: String) -> int:
	var n := 0
	for it in stash:
		if Items.is_ammo(it) and it["base"] == base_name:
			n += int(it["rounds"])
	return n


func _count_in_stash(base_name: String) -> int:
	var n := 0
	for it in stash:
		if it["base"] == base_name:
			n += Items.stack_size(it)
	return n


## The guns' types the runner has a gun for: what a box can be built of.
func gun_types_held() -> Array:
	var out := []
	for s in ["Primary", "Secondary"]:
		if equipped[s] != null:
			var t := Items.ammo_type(equipped[s])
			if t != "" and t != "none" and not out.has(t):
				out.append(t)
	for it in stash:
		if Items.is_gun(it):
			var t := Items.ammo_type(it)
			if t != "" and t != "none" and not out.has(t):
				out.append(t)
	return out


## The Build column: every build of a kind, with its cost, what it wants and whether it can be built now.
## kind: "box" (a standard box of a type), "grade" (a graded box, from the one below), "med", "gun"
## (an improvised gun, Common, firing nails), "grenade". Each: {name, scrap, from, from_n, ok, why, tier}.
func build_options(kind: String) -> Array:
	var out := []
	match kind:
		"box":
			for b in Data.BASES[Data.AMMO]:
				if b.has("from") or b.has("damage_pct"):
					continue
				var held: bool = b["type"] in gun_types_held()
				out.append(_build_entry(kind, b["name"], Data.BUILD_BOX, "", 0, held, "" if held else "No gun for it", int(b["tier"])))
		"grade":
			for b in Data.BASES[Data.AMMO]:
				if not b.has("from"):
					continue
				var need: int = int(Items.base_named(Data.AMMO, b["from"])["rounds"])
				var have: int = _rounds_in_stash(b["from"])
				out.append(_build_entry(kind, b["name"], Data.BUILD_GRADE * int(b["tier"]), b["from"], need, have >= need, "" if have >= need else "Wants a box of %s" % b["from"].to_lower(), int(b["tier"])))
		"med":
			for b in Data.BASES[Data.MEDICAL]:
				var from: String = str(b.get("from", ""))
				var have: int = _count_in_stash(from) if from != "" else 1
				out.append(_build_entry(kind, b["name"], Data.BUILD_MED * int(b["tier"]), from, 1 if from != "" else 0, have >= 1, "" if have >= 1 else "Wants a %s" % from.to_lower(), int(b["tier"])))
		"gun":
			for b in Data.BASES["Primary"]:
				if b.get("type", "") != "improvised" or b.get("start", false):
					continue                  # the starting gun is nobody's build
				if int(b["tier"]) > maxi(Data.CAMPAIGN_TIER, best_tier_open()):
					continue                  # a deep base (10 Oct) is built once a site that drops its tier is reached
				out.append(_build_entry(kind, b["name"], Data.BUILD_GUN * int(b["tier"]), "", 0, true, "", int(b["tier"])))
		"grenade":
			for b in Data.BASES[Data.GRENADE]:
				var from: String = str(b.get("from", ""))
				var have: int = _count_in_stash(from) if from != "" else 1
				out.append(_build_entry(kind, b["name"], Data.BUILD_GRENADE * int(b["tier"]), from, 1 if from != "" else 0, have >= 1, "" if have >= 1 else "Wants %s" % from.to_lower(), int(b["tier"])))
	return out


func _build_entry(kind: String, name: String, cost: int, from: String, from_n: int, has_from: bool, why: String, tier_v: int) -> Dictionary:
	# room for what it makes (the eighteenth read, 8 Oct: a bot built a box a run for thirty hours and the stash sat at
	# 327 of 234 with every find dropped): a box or a grade needs a stack with room or a cell, a med or a grenade a cell
	var made_slot: String = Data.AMMO if (kind == "box" or kind == "grade") else (Data.MEDICAL if kind == "med" else (Data.GRENADE if kind == "grenade" else "Primary"))
	var room: bool = stash_room(1) or (made_slot == Data.AMMO and _stack_room(_plain(Data.AMMO, name))) or (yard_has("racks") and made_slot != "Primary")
	if made_slot == "Primary":
		var fp: Array = Data.FOOTPRINTS.get(name, Data.SIZE["Primary"])
		room = stash_room(int(fp[0]) * int(fp[1]) + (0 if yard_has("racks") else 1))     # a gun and the magazine that comes with it (the fix round; no roll for a read)
	var ok: bool = has_from and scrap >= cost and not runner_busy() and room     # away on a repeat too (30 Oct, refactor 5)
	if why == "" and not ok:
		why = busy_words() if runner_busy() else ("No room in the stash" if not room else "Short of scrap")
	return {"kind": kind, "name": name, "scrap": cost, "from": from, "from_n": from_n, "ok": ok, "why": why, "tier": tier_v}


func build_option(kind: String, name: String) -> Dictionary:
	for o in build_options(kind):
		if o["name"] == name:
			return o
	return {}


## Build it: the scrap goes, what it wants goes (a box's rounds off the stash's stacks, one off a socketable's
## stack, a med), and the thing lands in the stash. A gun built is Common, plain, and fires nails.
func build(kind: String, name: String) -> bool:
	if not room_open("workshop"):
		return false
	var o := build_option(kind, name)
	if o.is_empty() or not o["ok"]:
		return false
	var made: Dictionary
	match kind:
		"box", "grade":
			made = _plain(Data.AMMO, name)       # a full box
			if o["from"] != "":
				_take_rounds(o["from"], o["from_n"])
		"med":
			made = _plain(Data.MEDICAL, name)
			if o["from"] != "":
				_take_one(o["from"])
		"gun":
			made = _plain("Primary", name)
			made["nails"] = true
			made["built"] = true
			if yard_has("gunsmith"):
				made["ilvl"] = maxi(Items.ilvl(made), deepest_site_level())     # the Bench's Gunsmith: built at your deepest site's level
		"grenade":
			made = _plain(Data.GRENADE, name)
			if o["from"] != "":
				_take_one(o["from"])
	scrap -= int(o["scrap"])
	if not stash_put(made):
		stash.append(made)                   # whatever the room: it was paid for
	_mag_with(made)
	last_craft = {"id": made["id"], "kind": "build", "words": "Built %s for %d scrap" % [name.to_lower(), int(o["scrap"])]}
	chron("build", {"name": name, "scrap": int(o["scrap"])})
	log_event(Words.LOG["built"] % [int(o["scrap"]), name.to_lower()])
	_dry_memo.clear()
	_stats_dirty()
	return true


## Rounds of a base off the stash's stacks, the fullest first.
func _take_rounds(base_name: String, n: int) -> void:
	var left := n
	var stacks: Array = stash.filter(func(it): return Items.is_ammo(it) and it["base"] == base_name)
	stacks.sort_custom(func(a, b): return int(a["rounds"]) > int(b["rounds"]))
	for st in stacks:
		if left <= 0:
			break
		var take_v: int = mini(left, int(st["rounds"]))
		Items.set_stack(st, int(st["rounds"]) - take_v)
		left -= take_v
		if int(st["rounds"]) <= 0:
			st.erase("tab")
			stash.erase(st)


## One of a base off the stash: one off a stack, or the item itself.
func _take_one(base_name: String) -> void:
	for it in stash:
		if it["base"] == base_name:
			if Items.stacks(it) and Items.stack_size(it) > 1:
				Items.set_stack(it, Items.stack_size(it) - 1)
			else:
				_remove(it)
			return


func can_craft(id: int, kind: String, stat := "") -> bool:
	if runner_busy() or not room_open("workshop"):     # away on a repeat too (30 Oct, refactor 5); shut until the Carpet Man's fitter's kit (27 Oct; the Quartermaster's tool roll before)
		return false
	var cost := craft_cost(item_by_id(id), kind, stat)
	if cost < 0:
		return false
	if kind == "temper" and scrap < temper_scrap(item_by_id(id)):
		return false
	return notes >= cost if craft_in_notes(kind) else cash >= float(cost)


func craft(id: int, kind: String, stat := "") -> bool:
	if not can_craft(id, kind, stat):
		return false
	var it := item_by_id(id)
	var cost := craft_cost(it, kind, stat)
	if cost == 0 and workbench_free() and _craft_cost_raw(it, kind, stat) > 0:
		workbench_day = int(elapsed / 86400.0)     # Workbench: the day's free job had (a job free of itself doesn't spend it: the review)
	var before: Array = Items.affix_lines(it, false, true)
	var sockets_before: int = Items.sockets(it)
	var level_before: int = Items.ilvl(it)
	match kind:
		"values":
			Items.reroll_values(it, locks_of(it), rng, Data.FX["yard/steady_hands"] if yard_has("steady_hands") else 1.0, yard_has("fine_tuning"), yard_has("masterwork"))
		"affixes":
			Items.reroll_affixes(it, rng, locks_of(it), yard_has("masterwork"))
		"add":
			if not Items.add_affix(it, rng, yard_has("masterwork")):
				return false
		"resist":
			if not Items.add_resist(it, stat.trim_suffix("_res"), rng):
				return false                    # BUILD50-T
		"socket":
			if not Items.add_socket(it, socket_max(it)):
				return false
		"strip":
			Items.strip_affixes(it)
			it["locks"] = []
		"bump":
			it["ilvl"] = mini(int(it["tier"]) + bump_cap(), Items.ilvl(it) + bump_levels())
		"temper":
			scrap -= temper_scrap(it)
			Items.temper_lines(it)                   # its flat lines grow as a drop a level deeper has them (the second review)
			it["ilvl"] = Items.ilvl(it) + 1
			it["tempered"] = int(it.get("tempered", 0)) + 1
	# what the Bench did, in words the player can check against the piece
	var words_v := _craft_words(it, kind, stat, before, sockets_before, level_before)
	last_craft = {"id": id, "kind": kind, "words": words_v}
	chron("craft", {"kind": kind, "stat": stat, "cost": cost, "item": _chron_item(it), "worn": not stash.has(it)})
	if not stash.has(it):
		_surv_cache = {}                       # a job on worn kit (the Workshop, 9 Oct): the odds read it again, the id is the same
		_dry_memo.clear()
		_stats_dirty()
	if craft_in_notes(kind):
		notes -= cost
		log_event(Words.LOG["crafted_notes"] % [cost, it["base"].to_lower(), words_v])
	else:
		cash -= float(cost)
		log_event(Words.LOG["crafted"] % [_cash_words(float(cost)), it["base"].to_lower(), words_v])
	return true


## "Added +12% damage · T2", "Re-rolled: +4% damage · T1, +2 HP/s · T1 → ...".
func _craft_words(it: Dictionary, kind: String, _stat: String, before: Array, _sockets_before: int, level_before: int) -> String:
	var after: Array = Items.affix_lines(it, false, true)
	match kind:
		"add", "resist":
			for line in after:
				if not (line in before):
					return "Added %s" % line
			return "Added an affix"
		"values", "affixes":
			var kept: Array = after.filter(func(l): return l in before)
			var gone: Array = before.filter(func(l): return not (l in after))
			var came: Array = after.filter(func(l): return not (l in before))
			var said: String = ("New values" if kind == "values" else "New affixes") + (": %s → %s" % [", ".join(gone), ", ".join(came)] if not came.is_empty() else ": no change")
			return ("Kept %s; " % ", ".join(kept) + said.substr(0, 1).to_lower() + said.substr(1)) if not kept.is_empty() and not came.is_empty() else said
		"socket":
			return "A socket cut: %d now" % Items.sockets(it)
		"strip":
			return "Stripped: %s gone" % ", ".join(before)
		"bump":
			return "Item level %d → %d: nothing under T%d rolls" % [level_before, Items.ilvl(it), mini(Items.tier_floor(Items.ilvl(it)), Items.rarity_cap(it))]
		"temper":
			return Words.TEMPER["done"] % [level_before, Items.ilvl(it)]
	return Data.CRAFT[kind]["name"]


## The map: its points and ranks.
func atlas_rank(key: String) -> int:
	return int(atlas.get(key, 0))


func atlas_spent() -> int:
	var n := 0
	for k in atlas:
		n += int(atlas[k])
	return n


func atlas_free() -> int:
	return atlas_points - atlas_spent()


func can_rank_atlas(key: String) -> bool:
	return atlas_block(key) == ""


## Why a map node can't take a rank now, or "" (the Map's web, 22 Oct: pathed - its region's entry, or touching a
## ranked node - not a column's gate).
func atlas_block(key: String, ignore_points := false) -> String:
	var a: Dictionary = Data.atlas_of(key)
	if a.is_empty():
		return "no such node"
	if mission != null:
		return "the runner is out"
	if atlas_rank(key) >= int(a["max"]):
		return "top rank"
	if not atlas_open(key):
		var near := atlas_path_next(key)
		return "wants a path to it: %s first" % (Data.map_node(near).get("name", near) if near != "" else "an entry")
	if a.get("keystone", false) and atlas_in_lane(int(a["column"])) < Data.MAP_KEYSTONE_POINTS:
		return "opens at %d points in %s" % [Data.MAP_KEYSTONE_POINTS, str(Data.ATLAS_COLUMNS[int(a["column"])]).to_lower()]
	if not ignore_points and atlas_free() < 1:
		return "wants a point"
	return ""


## The Map's pathing: a node is open when it's its region's entry or touches a ranked node along a link.
func atlas_open(key: String) -> bool:
	var id := Data.map_id(key)
	if id == "":
		return false
	if Data.map_node(id).get("entry", false) or atlas_rank(key) > 0:
		return true                           # an entry, or one already ranked (its next rank wants no path)
	for other in Data.map_links().get(id, []):
		if atlas_rank(str(Data.map_node(other)["key"])) > 0:
			return true
	return false


## The next node to rank on the way to one not yet open (the screen's hint, the bot's walk): a breadth-first walk
## back from it to the ranked set or an entry; "" if none.
func atlas_path_next(key: String) -> String:
	var id := Data.map_id(key)
	var links: Dictionary = Data.map_links()
	var parent := {id: ""}
	var queue: Array = [id]
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		for other in links.get(cur, []):
			if parent.has(other):
				continue
			parent[other] = cur
			if atlas_rank(str(Data.map_node(other)["key"])) > 0:
				return cur
			if Data.map_node(other).get("entry", false):
				return other
			queue.append(other)
	return ""


func atlas_in_lane(lane: int) -> int:
	var n := 0
	for a in Data.ATLAS_ALL:
		if int(a["column"]) == lane:
			n += atlas_rank(a["key"])
	return n


## A ranked node's figure with the fillers' shares in (the Map's web): "Searches 3% quicker" is 0.3 of Deeper pockets.
func atlas_level(key: String) -> float:
	var n: float = float(atlas_rank(key))
	for a in Data.ATLAS_ALL:
		if a.get("filler", false) and str(a.get("as", "")) == key and atlas_rank(str(a["key"])) > 0:
			n += float(a["ranks"])
	return n


func rank_atlas(key: String) -> bool:
	if not can_rank_atlas(key):
		return false
	atlas[key] = atlas_rank(key) + 1
	_stats_dirty()
	chron("atlas", {"key": key, "rank": atlas[key]})
	return true


## The map's points come back; the ranks go, and what they set (the standing words, Clear air's filter).
func reset_atlas() -> void:
	atlas = {}
	filtered = ""
	standing = []
	_surv_cache = {}


func trait_data() -> Dictionary:
	for t in Data.TRAITS:
		if t["name"] == runner_trait:
			return t
	return {}


## Two turn up when one dies: pick which stays. The other goes on.
func choose_runner(k: int) -> bool:
	if candidates.is_empty() or k < 0 or k >= candidates.size():
		return false
	runner_trait = candidates[k]
	_stats_dirty()                            # the trait multiplies HP, pace and damage
	candidates = []
	log_event(Words.LOG["runner_stays"] % [Data.TRAIT_WORDS.get(runner_trait, runner_trait.to_lower()), (" " + Words.TRAITS[runner_trait]) if Words.TRAITS.has(runner_trait) else ""])     # the trait's line (12 Oct): said of the one who stays
	return true


## The web's two gates (a keystone at KEYSTONE_SPENT points spent, a capstone at CAPSTONE_SPENT) on; only the smoke's
## mechanics areas turn them off, to test a pair or a keystone without the build behind it. Not saved.
var core_gates := true


## The runner's first class tree, by name ("Muscle"), or "".
func first_tree() -> String:
	var ts: Array = Data.trees_for(cls)
	return str(ts[0]["name"]) if not ts.is_empty() and ts[0].get("class", "") == cls else ""


func node(id: String) -> Dictionary:
	var parts := id.split("/")
	var t := Data.tree_named(parts[0])
	if t.is_empty() or int(parts[1]) >= t["nodes"].size():
		return {}
	return t["nodes"][int(parts[1])]


## The primary's type: what a typed node checks.
func gun_type() -> String:
	if equipped["Primary"] == null:
		return ""
	return Items.base_of(equipped["Primary"]).get("type", "")


## An owned node counts unless it's typed for a gun that isn't in hand ("type" is one gun type, or a list of them).
## Everything on the web is the runner's own (the skill web, 3 Nov): another class's half works like any node.
func _active(n: Dictionary) -> bool:
	if not n.has("type"):
		return true
	var ty = n["type"]
	return (gun_type() in ty) if ty is Array else ty == gun_type()


func node_active(id: String) -> bool:
	var n := node(id)
	return not n.is_empty() and _active(n)


func has_node(effect: String) -> bool:
	for e in _nodes_for(effect):
		if _active(e[0]):
			return true
	return false


## The small nodes' numbers for an effect, added up: a node's own value, or its "also" figure for a second effect.
func tree_sum(effect: String) -> float:
	var t := 0.0
	for e in _nodes_for(effect):
		if _active(e[0]):
			t += float(e[1])
	return t


## The owned nodes by effect - [node, its figure for that effect], a node under its "also" effects too - built once
## per shape of the tree and the runner's class: the fight asks for effects every tick. The pairs done are worked
## out with it. The class's start counts owned whether or not it's in the tree (a fixture's tree set straight).
var _eff_cache := {}
var _eff_hash := 0
var _closed := {}                  # pair key -> true, done
func _nodes_for(effect: String) -> Array:
	var cap: bool = has_rule("headmasters_cap")
	var h := hash([tree, cls, cap, core_gates])
	if h != _eff_hash or _eff_cache.is_empty():
		_eff_cache = {"": []}
		_closed = {}
		for j in Data.JOINTS:
			if j["class"] == cls and _half_trained(j, j["tree"]) and _half_trained(j, j["element_tree"]):
				_closed[j["key"]] = true
		var ids: Array = tree.duplicate()
		var st: String = Data.web_start(cls) if cls != "" else ""
		if st != "" and not ids.has(st):
			ids.append(st)
		if cap:
			var cap_top: bool = not core_gates or points_spent() >= Data.CAPSTONE_SPENT     # its capstone only at CAPSTONE_SPENT spent, as the web's rule (3 Nov, the review of build 47: the Cap bought round the gate)
			for ct in Data.trees_for(cls):      # the Headmaster's Cap (a mythic): every node of the class's trees -
				if str(ct.get("class", "")) == "":
					continue                          # the class's own, not the centre's
				for i in range(ct.get("nodes", []).size()):
					var cid := "%s/%d" % [ct["name"], i]
					if ct["nodes"][i].get("capstone", false) and not cap_top:
						continue
					if not (cid in ids) and not ct["nodes"][i].get("keystone", false) and not ct["nodes"][i].get("cost", false) and not ct["nodes"][i].has("skill"):
						ids.append(cid)               # nor its skills (24 Oct, milestone 8: a mythic that taught all eight was the review's catch);               # but its keystones and the nodes with a cost (Data's "cost"), whose costs are the point (21 Oct, Matt: "fix both" - Hit and run, a notable, came with it)
		for id in ids:
			var n := node(id)
			if n.is_empty():
				continue
			var e: String = n.get("effect", "")
			if not _eff_cache.has(e):
				_eff_cache[e] = []
			_eff_cache[e].append([n, n.get("value", 0)])
			for k in n.get("also", {}):
				if not _eff_cache.has(k):
					_eff_cache[k] = []
				_eff_cache[k].append([n, n["also"][k]])
		_eff_hash = h
	return _eff_cache.get(effect, [])


## Whether a pair's half in a tree is owned: the node in that tree carrying the pair's key.
func _half_trained(j: Dictionary, tree_name: String) -> bool:
	var hid := _half_id(j, tree_name)
	return hid != "" and web_owned(hid)


## A pair done: both halves owned by a runner of its class.
func has_joint(key: String) -> bool:
	_nodes_for("")
	return _closed.has(key)


## A dry run reads the rules once: nothing worn or stashed changes while it runs.
## The figures that only the kit and the tree decide are memoised for its length too.
var _dry_on := false
var _dry_rules := {}
var _dry_memo := {}
## The balance gate's brake (8 Oct, the pass at an hour): the memo stays on through a real run too, cleared
## every FAST_MEMO_S of the run's time and wherever the kit changes, so a tick reads the kit once in thirty
## seconds rather than thirty times a second. A dry run already reads the kit once in fifteen minutes; the
## shell leaves this off and reads fresh every call.
var fast_memo := false
const FAST_MEMO_S := 30.0
var _memo_age := 0.0
var _try_memo := {}                # a try-on's own memo (22 Oct, the pass's wall): the kit stands still inside one try, and
                                   # a try-on's damage asked each affix sum twenty times over; cleared as a try begins and ends
func _memo(key: String, f: Callable) -> Variant:
	if _trying:                        # a try-on reads the kit it's trying, never the dry memo
		if _try_memo.has(key):
			return _try_memo[key]
		var tv = f.call()
		_try_memo[key] = tv
		return tv
	if not (_dry_on or (fast_memo and mission != null)):
		return _live_read(key, f)
	if _dry_memo.has(key):
		return _dry_memo[key]
	var v = f.call()
	_dry_memo[key] = v
	return v


## The live stat memo (1 Nov, BUILD43, perf43's cause 1: every stat worked out from scratch on every call, 12 ms of a
## fight's frame). Where the dry memo and fast_memo aren't on - the shell's own play - a stat read is kept until
## _stats_dirty() says something it reads has moved: kit worn, taken off, tempered or socketed, a tree or the ring
## spent, a level, a wound, a buff, the sky, the rules, a run's start and end, a load. What moves inside a run without
## a call (the rig's count, the pack, the clear, the soaking, the feed) is in _live_ctx, read on every hit; HP either
## side of half is dps()'s own key, as the dry memo's. It must hand back what a fresh read would: `memo_check` reads each hit fresh as well and counts any
## that differ (the smoke's check, tests/fingerprint.gd's `live` hash).
var _live_memo := {}
var _live_ctx_at: Array = []
## Bumped wherever a stat can move: a screen's signature for "has the runner's figure moved" (the run screen's rig).
var stat_v := 0
static var live_memo_off := false        # the A/B switch: every read fresh, as before BUILD43
static var memo_check := false           # each hit read fresh too; a differing one lands in memo_stale
var memo_stale: Array = []


func _stats_dirty() -> void:
	stat_v += 1
	_live_memo.clear()


func _live_read(key: String, f: Callable) -> Variant:
	if live_memo_off:
		return f.call()
	_live_sync()
	if _live_memo.has(key):
		var hv = _live_memo[key]
		if memo_check:
			var fv = f.call()
			if typeof(fv) != typeof(hv) or fv != hv:
				memo_stale.append([key, hv, fv, elapsed, mission != null])
				_live_memo[key] = fv
				return fv
		return hv
	var v = f.call()
	_live_memo[key] = v
	return v


func _live_sync() -> void:
	var ctx := _live_ctx()
	if ctx != _live_ctx_at:
		_live_ctx_at = ctx
		_stats_dirty()


## What a run moves under the stats without a call: compared on every live read, so it stays a handful of figures -
## the level (a level-up mid-run: max HP), the rig's count (armour a med) and its loaded magazines (a gun's feed and
## so its grade's conversion), at camp the front's level (the armour's cut), the pack's cells used (armour a free cell), the clear (the Milkman's pace), the Water
## cannon's soaking, the run's plate, the magazine in each gun.
func _live_ctx() -> Array:
	var loaded := 0
	for it in rig:
		if int(it.get("rounds", 0)) > 0:
			loaded += 1
	var kit := []                             # what's worn by id, the trees' and the wounds' counts: cheap, and a piece
	for sl in Data.SLOTS:                      # set straight in (a test's, or a path that forgot its call) is read afresh
		kit.append(equipped[sl]["id"] if equipped[sl] != null else -1)
	if mission == null:
		return [false, level(), rig.size(), loaded, kit, tree.size(), wounds.size(), fight_level()]     # the front's level: the armour's cut at camp (review 43, 1)
	var m: Dictionary = mission
	var t: Dictionary = m.get("t", {})
	return [true, level(), rig.size(), loaded, kit, tree.size(), wounds.size(), pack_used(m) if m.has("found") else 0, m.get("cleared", false), m.get("ghost_pending", false),
		t.get("soaked", 0.0), m.get("buff_armour_pct", 0.0), Dictionary(m.get("mag_in", {})).values(), t.get("level", 0)]


## The guard behind the calls (BUILD43): everything else a stat reads, hashed - the runner whole (runner_parts: the
## kit by value, the trees, the level, the class, the skills), the wounds, the stash (its papers' rules), the Yard,
## the lorries, the ring, the sky and the front. Read at each tick and each screen refresh, so a change some path
## made without _stats_dirty() can't outlive the frame; the smoke's memo_check is what finds such a path.
var _live_state_at := 0
func live_guard() -> void:
	if live_memo_off or _dry_on:
		return
	var h := hash([runner_parts(), wounds, stash.size(), _removed, yard_picks, yard_ranks, lorries, weather, is_night(), front_tier(),
		standing, atlas, issued, mission != null])     # the stash's count and what's gone from it: a paper's rule in or out
	if h != _live_state_at:
		_live_state_at = h
		_stats_dirty()


func _snapshot_rules() -> Dictionary:
	var out := {}
	for s in Data.SLOTS:
		if equipped[s] != null and equipped[s].get("rule", "") != "":
			out[equipped[s]["rule"]] = true
	for it in stash:
		if Items.is_paper(it) and it.get("rule", "") != "":
			out[it["rule"]] = true
	return out


## Every node costs one point (the skill web, 3 Nov: the one rule); the class's start none; a paragon ring point one.
func node_cost(id: String) -> int:
	return 0 if is_start(id) else 1


## The runner's class's start (Data.web_start): owned from level 1, free, its skill the class's first.
func is_start(id: String) -> bool:
	return cls != "" and id == Data.web_start(cls)


## The start in the tree and its skill in a slot (a new runner, a swap, a reset, a death, a load): the one node a
## runner never lacks. `slot` (a class picked or swapped in): its skill into an empty slot too; off (a reset, a death,
## a load): the tree alone, the slots as they were.
func _ensure_start(slot := true) -> void:
	var st: String = Data.web_start(cls) if cls != "" else ""
	if st == "":
		return
	if not tree.has(st):
		tree.insert(0, st)
		_dry_memo.clear()
		_stats_dirty()
	var sk: String = str(node(st).get("skill", ""))
	if slot and sk != "" and skill_known(sk) and not skill_slots.has(sk):
		var free_slot: int = skill_slots.find("")
		if free_slot >= 0:
			skill_slots[free_slot] = sk


## The runner's points spent: every web node owned but the start.
func points_spent() -> int:
	var n := 0
	for id in tree:
		if not is_ring(str(id)):
			n += node_cost(str(id))
	return n


func points_free() -> int:
	return training_points + reward_points() - points_spent()


## The centre's tree (the old Pitch's name): a node of it is the runner's like any other now.
func is_pitch(id: String) -> bool:
	return id.get_slice("/", 0) == Data.COMMON_TREE


## The element a node's tree is ("" for a class's or the centre's).
func element_of(id: String) -> String:
	return str(Data.element_tree(id.get_slice("/", 0)).get("element", ""))


func crew_best_level() -> int:
	var b := best_level
	for k in roster:
		b = maxi(b, int(roster[k].get("best_level", 1)))
	return b


## The points a node is bought from: the paragon ring's own, or the runner's.
func free_for(id: String) -> int:
	return paragon_free() if is_ring(id) else points_free()


## The classes whose pairs this runner closes: its own.
func my_classes() -> Array:
	return [cls] if cls != "" else []


## What's been spent in a tree: its nodes owned, a point each.
func points_in(tree_name: String) -> int:
	var n := 0
	for id in tree:
		if str(id).get_slice("/", 0) == tree_name:
			n += node_cost(str(id))
	return n


## Why a node can't be taken now, in the game's words, or "" when it can (the Training screen's line, the tests').
## A web node (skill_web.md, the one rule): joined to one owned, a point free, a keystone KEYSTONE_SPENT points spent
## first and a capstone CAPSTONE_SPENT (core_gates off in the smoke's mechanics areas lifts those two). The paragon
## ring keeps its own: a path round from an entry, a node's stack. `ignore_points`: everything but the points free.
func train_block(id: String, ignore_points := false, _said := true) -> String:
	var n := node(id)
	if n.is_empty():
		return "no such node"
	if n.has("ring"):
		if int(ring.get(id, 0)) >= int(n["stack"]):
			return "full: %d points on it" % int(n["stack"])
		if not Data.web_entry(n) and not touches_trained(id):
			return "wants a path round the ring"
		if not ignore_points and paragon_free() < 1:
			return "wants 1 point"
		return ""
	if not n.has("slot"):
		return "no such node"
	if web_owned(id):
		return "trained"
	if not touches_trained(id):
		return Words.WEB_BLOCK["joined"]
	var spent := points_spent()
	if core_gates and n.get("keystone", false) and spent < Data.KEYSTONE_SPENT:
		return Words.WEB_BLOCK["keystone"] % Data.KEYSTONE_SPENT
	if core_gates and n.get("capstone", false) and spent < Data.CAPSTONE_SPENT:
		return Words.WEB_BLOCK["capstone"] % Data.CAPSTONE_SPENT
	if not ignore_points and points_free() < node_cost(id):
		return Words.WEB_BLOCK["points"]
	return ""


func can_train(id: String) -> bool:
	return train_block(id) == ""


## Another class's start or skill node: its class's name, else "". Taken and walked through like any node (the one
## rule: the next class is reached by distance), but it does nothing for this runner - a skill needs its class - and
## the card says so (3 Nov, merge 47's second round); the bot never aims at one.
var _barred_cls := "-"
var _barred := {}
func web_class_only(id: String) -> String:
	if _barred_cls != cls:
		_barred = {}
		for wt in Data.TREES:
			var tc: String = str(wt.get("class", ""))
			if tc == "" or tc == cls:
				continue
			for i in range(wt.get("nodes", []).size()):
				var nd: Dictionary = wt["nodes"][i]
				if nd.get("start", false) or nd.has("skill"):
					_barred["%s/%d" % [wt["name"], i]] = tc
		_barred_cls = cls
	return str(_barred.get(id, ""))


## The web's pathing: a node joined to one owned (the start counts).
func touches_trained(id: String) -> bool:
	var links: Dictionary = Data.web_links_all()
	for other in links.get(id, []):
		if web_owned(str(other)) or (is_ring(str(other)) and tree.has(other)):
			return true
	return false


## The path from what's owned to a node not owned: the ids to buy, nearest first, the node last ([] if owned or none).
## A breadth-first walk out from every owned node over the web's links: the fewest nodes (every node costs one).
func web_path(id: String) -> Array:
	if web_owned(id) or node(id).is_empty() or is_ring(id):
		return []
	var links: Dictionary = Data.web_links_all()
	var parent := {}
	var queue: Array = []
	for o in tree:
		if not is_ring(str(o)):
			parent[str(o)] = ""
			queue.append(str(o))
	var st: String = Data.web_start(cls) if cls != "" else ""
	if st != "" and not parent.has(st):
		parent[st] = ""
		queue.append(st)
	var head := 0
	while head < queue.size():
		var cur: String = queue[head]
		head += 1
		if cur == id:
			var out: Array = []
			var at: String = id
			while at != "" and not web_owned(at):
				out.push_front(at)
				at = str(parent[at])
			return out
		for nb in links.get(cur, []):
			if not parent.has(nb):
				parent[nb] = cur
				queue.append(nb)
	return []


## The next node to buy on the way to one not yet joined ("" if none): the path's first. The screen's hint, the bot's
## walk. The ring: the node beside one with a point, or an entry.
func path_next(id: String) -> String:
	if is_ring(id):
		var links: Dictionary = Data.web_links_all()
		var parent := {id: ""}
		var queue: Array = [id]
		while not queue.is_empty():
			var cur: String = queue.pop_front()
			for other in links.get(cur, []):
				if parent.has(other):
					continue
				parent[other] = cur
				if tree.has(other):
					return cur
				if Data.web_entry(node(other)):
					return other
				queue.append(other)
		return ""
	var p := web_path(id)
	return str(p[0]) if not p.is_empty() else ""


## What a node adds to the one damage figure (16 Oct, item 14): damage_split's total with it and without it - taken
## for one not yet trained, taken off for one that is - with the guns fed as they are, so it reads against the top
## bar's figure. The memos read the tree, so they're set aside while it's changed. [added a second, as a share of the
## figure without it]; [0, 0] for a node with no damage in it.
func node_damage_gain(id: String) -> Array:
	var kept_memo := _dry_memo
	_dry_memo = {}
	var had: bool = tree.has(id)
	var now: float = float(damage_split()["total"])
	var keep: Array = tree.duplicate()             # put back as it was: the order is the order taken (the review)
	if had:
		tree.erase(id)
		_stats_dirty()
	else:
		tree.append(id)
		_stats_dirty()
	_dry_memo = {}
	var other: float = float(damage_split()["total"])
	tree = keep
	_stats_dirty()
	_dry_memo = kept_memo
	var with_it: float = now if had else other
	var without: float = other if had else now
	var add: float = with_it - without
	return [add, add / without if without > 0.0 else 0.0]


func train_node(id: String) -> bool:
	if not can_train(id):
		return false
	_dry_memo.clear()                     # the memos read the tree (A4's review)
	_stats_dirty()
	var nd: Dictionary = node(id)
	if nd.has("ring"):
		ring[id] = int(ring.get(id, 0)) + 1     # the ring (slice 4): a paragon point on the node, stacked
		_stats_dirty()
		if not tree.has(id):
			tree.append(id)
			_stats_dirty()
		chron("paragon", {"key": str(nd["key"]), "points": paragon_pts(str(nd["key"]))})
		return true
	var paid: int = node_cost(id)
	tree.append(id)
	_stats_dirty()
	log_event(Words.LOG["trained"] % nd["name"])
	if nd.has("skill") and skill_known(str(nd["skill"])) and mission == null and not skill_slots.has(str(nd["skill"])):
		var free_slot: int = skill_slots.find("")
		if free_slot >= 0:
			skill_slots[free_slot] = str(nd["skill"])     # a skill learnt goes in the first empty slot; the Runs card changes them (milestone 8)
	chron("train", {"id": id, "name": str(nd["name"]), "tree": id.get_slice("/", 0), "slot": str(nd.get("slot", "")), "cost": paid,
		"keystone": bool(nd.get("keystone", false)), "capstone": bool(nd.get("capstone", false)), "notable": bool(nd.get("notable", false)),
		"joint": str(nd.get("joint", "")), "free": free_for(id), "spent": points_spent()})
	return true


## Every tree is on show: the web is one (the skill web, 3 Nov).
func _on_show(branch: String) -> bool:
	return not Data.tree_named(branch).is_empty()


## BUILD45's one read of the runner's trees for a web's restate: the web is one now, so `f` is just called (the screen's hook).
func held_trees(f: Callable) -> Variant:
	return f.call()


## A reset (skill_web.md: "a reset gives every point back"): every web node but the start back to points, at today's
## price. The paragon ring has its own.
func respec_cost() -> int:
	return _inf(points_spent() * Data.RESPEC_CASH)


static func _first_lower(t: String) -> String:
	return t.substr(0, 1).to_lower() + t.substr(1) if t != "" else t


func can_respec() -> bool:
	return not runner_busy() and points_spent() > 0 and cash >= respec_cost()


func respec() -> bool:
	if not can_respec():
		return false
	_dry_memo.clear()
	_stats_dirty()
	var paid := respec_cost()
	cash -= paid
	chron("respec", {"cost": paid, "points": points_spent()})
	tree = tree.filter(func(id): return is_ring(str(id)))     # the web back to points; the ring's are the crew's and stay
	_stats_dirty()
	_ensure_start(false)                  # its skill stays where it was slotted
	_skills_known_only()
	log_event(Words.LOG["training_reset"])
	return true


# ------------------------------------------------------------------ the web's API (BUILD47_COMMON.md)

## Owned by this runner: in its tree, or its class's start.
func web_owned(id: String) -> bool:
	return tree.has(id) or is_start(id)


## "" when the node can be taken now, else why in the game's words.
func web_can_take(id: String) -> String:
	var b := train_block(id)
	return Words.WEB_BLOCK["owned"] if b == "trained" else b


func web_take(id: String) -> bool:
	return train_node(id)


## The nodes takeable now (`ignore_points`: joined and gated, points or not - the screen's amber ring with none free).
func web_frontier(ignore_points := false) -> Array:
	var out: Array = []
	var looked := {}
	for o in tree + [Data.web_start(cls) if cls != "" else ""]:
		if str(o) == "" or is_ring(str(o)):
			continue
		for nb in Data.web_links(str(o)):
			if not looked.has(nb) and not web_owned(str(nb)):
				looked[nb] = true
				if train_block(str(nb), ignore_points) == "":
					out.append(nb)
	return out


func web_points() -> int:
	return training_points + reward_points()


## The camp's reward points (skill web version two, "The rule for spending"): {"points": the total, "from": [{"key",
## "points", "why"}, ...] in the order earned} - "why" a head's name, a story paper's name, or "the Issue".
func web_rewards() -> Dictionary:
	var out: Array = []
	for k in rewards_earned:
		out.append({"key": str(k), "points": int(rewards_earned[k][0]), "why": str(rewards_earned[k][1])})
	return {"points": reward_points(), "from": out}


## Every reward point the camp has earned: each runner's, past and future.
func reward_points() -> int:
	var n := 0
	for k in rewards_earned:
		n += int(rewards_earned[k][0])
	return n


## A reward earned, once: a head's first fall ("head:<name>"), a story paper decrypted ("kev:<paper>"), the Issue
## ("issue"). Logged and chronicled; a second time does nothing. True when it was new.
func _web_reward(key: String, pts: int, why: String) -> bool:
	if rewards_earned.has(key) or pts <= 0:
		return false
	rewards_earned[key] = [pts, why]
	log_event(Words.WEB_REWARD["log"] % [why, pts, "" if pts == 1 else "s"])
	chron("reward", {"key": key, "points": pts, "total": reward_points()})
	return true


func web_spent() -> int:
	return points_spent()


func web_free() -> int:
	return points_free()


## The runner's class's two pairs: {"key", "words", "halves": [the class's half, the element's half], "done"}.
func web_pairs() -> Array:
	var out: Array = []
	for j in Data.JOINTS:
		if j["class"] != cls:
			continue
		var halves: Array = [_half_id(j, str(j["tree"])), _half_id(j, str(j["element_tree"]))]
		out.append({"key": j["key"], "words": j["words"], "halves": halves, "done": web_owned(halves[0]) and web_owned(halves[1])})
	return out


## A pair's half in a tree: the node there carrying the pair's key.
func _half_id(j: Dictionary, tree_name: String) -> String:
	var t := Data.tree_named(tree_name)
	for i in range(t.get("nodes", []).size()):
		if str(t["nodes"][i].get("joint", "")) == j["key"]:
			return "%s/%d" % [tree_name, i]
	return ""


## The fewest nodes to buy to own it (0 if owned; -1 if it can't be reached).
func web_steps(id: String) -> int:
	if web_owned(id):
		return 0
	var p := web_path(id)
	return p.size() if not p.is_empty() else -1


func web_reset() -> bool:
	return respec()


## Levels earn points for the camp, whatever happens to the operator - but only past the camp's best
## (9 Oct): dying and re-levelling a new runner earned the same points again, without end.
func _earn_points(before: int) -> void:
	var got: Array = _points_up(before, level(), best_level, "")
	best_level = int(got[0])
	training_points += int(got[1])


## The one rule for a level's points, the runner out's or a benched class's (`who`, 30 Oct: a lead's expedition XP):
## points only for the levels past that class's best. [the best now, the points gained]; said in the log and chronicled.
func _points_up(before: int, after: int, best: int, who: String) -> Array:
	if after > best:
		var gained: int = (after - maxi(before, best)) * Data.POINTS_A_LEVEL     # two a level (skill web version two)
		if who == "":
			log_event(Words.LOG["level_points"] % [after, gained, "" if gained == 1 else "s"])
			chron("level", {"to": after, "gained": gained, "best": true})
		else:
			log_event(Words.CREW["lead_level"] % [who, after, gained, "" if gained == 1 else "s"])
			chron("lead_level", {"cls": who, "to": after, "gained": gained, "best": true})     # not "level": that's the runner out's
		return [after, gained]
	if after > before:
		if who == "":
			log_event(Words.LOG["level_no_point"] % [after, best])
			chron("level", {"to": after, "gained": 0, "best": false})
		else:
			log_event(Words.CREW["lead_level_none"] % [who, after, best])
			chron("lead_level", {"cls": who, "to": after, "gained": 0, "best": false})
	return [best, 0]


## XP to a benched class's runner (an expedition's lead, 30 Oct, the review's S4): the one roster-side path, as _gain_xp
## and _earn_points are the runner out's - to MAX_LEVEL, the rest the crew's paragon, the points for the levels it rose.
func _crew_gain_xp(name: String, g: float) -> void:
	if not roster.has(name) or g <= 0.0:
		return
	var r: Dictionary = roster[name]
	var x0: float = float(r.get("xp", 0.0))
	var before: int = Data.level_for_xp(x0)
	var room := maxf(0.0, Data.xp_for_level(Data.MAX_LEVEL) - x0)
	r["xp"] = x0 + minf(g, room)
	paragon_xp += g - minf(g, room)
	var got: Array = _points_up(before, Data.level_for_xp(float(r["xp"])), int(r.get("best_level", 1)), name)
	r["best_level"] = int(got[0])
	r["training_points"] = int(r.get("training_points", 0)) + int(got[1])


func contact(t: Dictionary) -> int:
	if has_node("one_at_a_time"):
		return 1
	if has_rule("gritters_hopper") and mission != null and float(mission.get("chill_t", 0.0)) > 0.0:
		return 1                                 # chilled gangs come one at a time
	return maxi(1, (Data.FX["node/overwatch"] if has_node("overwatch") else CONTACT) + int(t.get("contact", 0)) + int(class_data().get("contact", 0)) + (Data.FX["rule/sergeants_whistle.contact"] if has_rule("sergeants_whistle") else 0) - (Data.FX["set/army.contact"] if has_set_rule("army") else 0))


## Seconds a search takes: the intel's multiple, cut by Fieldcraft's search nodes.
func search_s(t: Dictionary) -> float:
	return SEARCH_S * (Data.FX["rule/miners_lamp"] if has_rule("miners_lamp") else 1.0) * float(t.get("search", 1.0)) * maxf(0.4, 1.0 - (tree_sum("search_pct") + _affix_sum("search_pct")) / 100.0) * cm("search") * (Data.FX["node/never_there.search"] if has_node("never_there") else 1.0) * trait_mult("search") \
		* (1.0 - Data.FX["atlas/deeper_pockets"] * atlas_level("deeper_pockets")) * (Data.FX["yard/second_dog"] if yard_has("second_dog") else 1.0)


## Seconds to the next lot. The first lot waits for the lookout too; "never
## there" means none ever comes.
func patrol_s(t: Dictionary, first := false) -> float:
	if has_node("never_there"):
		return INF
	var base := (Data.FX["node/quiet_feet"] if has_node("quiet_feet") else PATROL_S) * float(t.get("patrol", 1.0)) * cm("patrol")
	if t.has("tier"):
		base *= float(Data.PATROL_ZONE[int(Data.TIERS[int(t["tier"])]["zone"])])     # the gangs sooner a zone along (21 Oct; the stats sheet asks with no site)
	base *= 1.0 + (_fitted_sum("patrol_pct") + tree_sum("patrol_pct") + _affix_sum("patrol_pct")) / 100.0
	base *= yard_patrol()
	if first:
		base *= Data.PATROL_FIRST * (1.0 + (Data.FX["yard/spotter"] if yard_has("spotter") else 0.0) + (Data.FX["yard/lookout_post"] if yard_has("lookout_post") else 0.0)) * (Data.FX["node/early_doors"] if has_node("early_doors") else 1.0) * (2.0 if has_node("b_roads") else 1.0)     # B-roads (22 Oct): the first takes 100% longer
	if has_node("loud"):
		base *= Data.FX["node/loud.patrol"]
	return base * trait_mult("patrol") * (1.0 + Data.FX["atlas/quiet_roads"] * atlas_level("quiet_roads")) * (Data.FX["rule/lollipop"] if has_rule("lollipop") else 1.0)


func use_time(it: Dictionary) -> float:
	if has_node("field_surgery"):
		return 0.0
	return Items.use_time(it) * (Data.FX["node/triage"] if has_node("triage") else 1.0) * maxf(0.3, 1.0 - (tree_sum("med_speed_pct") + _affix_sum("med_speed_pct")) / 100.0) * (Data.FX["node/bleed_more.med_time"] if has_node("bleed_more") else 1.0)


func pace() -> float:
	return _memo("pace", _pace_raw)


func _pace_raw() -> float:
	var worn_v := 0.0
	for s in Data.SLOTS:
		if equipped[s] != null:
			worn_v += Items.base_pace(equipped[s])
	return (1.0 + (_affix_sum("speed_pct") + _fitted_sum("speed_pct") + tree_sum("pace_pct") + worn_v) / 100.0) * cm("pace") * (Data.FX["node/one_at_a_time.pace"] if has_node("one_at_a_time") else 1.0) * (Data.FX["node/hoarder.pace"] if has_node("hoarder") else 1.0) * trait_mult("pace") \
		* (Data.FX["rule/van_keys"] if has_rule("van_keys") else 1.0) * (Data.FX["node/frost_more.pace"] if has_node("frost_more") else 1.0) * (Data.FX["node/physical_more.pace"] if has_node("physical_more") else 1.0) * (Data.FX["rule/the_float.pace"] if has_rule("the_float") else 1.0) * wound_mult("pace") \
		* (Data.FX["rule/milkmans"] if (has_rule("milkmans") and (_trying or (mission != null and not mission.get("cleared", false)))) else 1.0)     # the Milkman's Gloves: before the clear; a try-on reads it on, as the fight has it (the fix round, the game review's C4)


# ------------------------------------------------------------------ ammo

## Magazines as items (30 Oct, docs/design/meds_ammo_clinic.md "Magazines as items"): the rig carries magazines, each
## loaded with one grade; a gun fires from the loaded ones that fit it (its type), both guns of a type from one pool.
## The magazines in the rig that feed a gun, loaded or not, in the rig's order.
func mags_for(gun) -> Array:
	if not (gun is Dictionary):
		return []
	return rig.filter(func(x): return Items.mag_fits(x, gun))


## The rounds in the rig's magazines for a gun's type (feed_stack says which fires).
func rounds_for(gun: Dictionary) -> int:
	var n := 0
	for it in mags_for(gun):
		n += int(it.get("rounds", 0))
	return n


func has_rounds(gun: Dictionary) -> bool:
	if _trying:
		# a try-on weighs a gun fed when its rounds are a trip to the rig: in the stash or the rig, or at the Fence to buy
		# (13 Oct, the ammo trap: with the Fence shut, Equip if better swapped the nail gun for a rifle nobody had rounds
		# for, and the runner fought with their fists); every gun comes with a magazine (30 Oct)
		var type: String = Items.ammo_type(gun)
		if type in ["", "none"] or Items.free_rounds(gun) or room_open("fence"):
			return true
		return rounds_for(gun) > 0 or _rounds_held().any(func(x): return Items.is_ammo(x) and Items.base_of(x)["type"] == type)
	if Items.ammo_type(gun) == "none" or Items.free_rounds(gun):
		return true                          # a bat never runs dry; nor the spare key
	return Items.ammo_type(gun) != "" and rounds_for(gun) > 0


## A gun in a slot that fires from a magazine (28 Oct, magazines): not a bat, not a free-round gun, not the
## Quartermaster's rifle in the hands (it never spends a round).
func uses_mag(slot: String) -> bool:
	var gun = equipped[slot]
	if gun == null or Items.mag_size(gun) <= 0:
		return false
	return not (slot == "Primary" and has_rule("qm_rifle"))


## A reload's seconds for this gun: its own, cut by its reload_pct (and the trees', none yet).
func reload_s(gun: Dictionary) -> float:
	if has_rule("safecrackers"):
		return 0.0                               # the Safecracker's Gloves: no reload at all
	return Items.reload_base(gun) / (1.0 + (_affix_sum("reload_pct") + tree_sum("reload_pct")) / 100.0)     # quicker reloads is the gloves' (29 Oct): theirs, base and affixes


## The rig's swap (BUILD46-R, 2 Nov, Matt's call: a rig affix, Data's hot_swap): a gun with a second loaded magazine swaps
## with no reload, and the spent one refills from the pack's box as the runner fires, at a hand refill's pace.
func hot_swap() -> bool:
	return _affix_sum("hot_swap") > 0.0


## The guns' rate of fire from a rule (the fix round, 29 Oct, the game review's C5): the Safecracker's Gloves' −15%. The damage
## a second carries it (_dps); the rounds spent, the rounds wanted and a rifle's opener a shot read it here.
func rate_x() -> float:
	return float(Data.FX["rule/safecrackers"]) if has_rule("safecrackers") else 1.0


## The sling on the primary (30 Oct, the magazine mount became the sling): its share of the secondary's fire while the
## primary reloads between magazines; 0 with none.
func sling_share() -> float:
	var g = equipped["Primary"]
	if g == null:
		return 0.0
	return clampf(Items.fitted_sum(g, "sling_pct") / 100.0, 0.0, 1.0)


## The secondary's share while the primary reloads (30 Oct, the designer's call B): its usual backing share, lifted to the
## sling's when that's more - never lower.
func reload_share() -> float:
	return maxf(secondary_share(true), sling_share())


## The magazines a slot's gun reads its pauses off (30 Oct): the loaded ones in the rig that fit it; none, one of the
## gun's own (a try-on, a gun on the way to its first fill).
func _mags_read(gun: Dictionary, slot := "") -> Array:
	var out: Array = mags_for(gun).filter(func(x): return int(x.get("rounds", 0)) > 0)
	if out.is_empty():
		out = mags_for(gun)
	if shared_mags():
		# two guns of one type share the pool (the three-stage review, game 2): the secondary holds one magazine and the
		# primary cycles the rest - with one alone, the primary takes it and the secondary has none
		# in the fight's own order (_next_mag: the build's element, the grade's worth, the fullest): the primary loads the
		# first, the secondary the next (the reviewer on m32c, 2)
		# the primary's first by its build's elements (_next_mag("Primary")), the secondary's from the rest without them
		# (_next_mag("Secondary")), the primary the rest (the reviewer on m32c)
		var els: Array = build_elements()
		var key_p := func(x: Dictionary) -> float: return float(_grade_worth(Items.grade_base(x), els)) * 1000.0 + float(x.get("rounds", 0))
		var key_s := func(x: Dictionary) -> float: return float(_grade_worth(Items.grade_base(x), [])) * 1000.0 + float(x.get("rounds", 0))
		if out.size() < 2:
			return [] if slot == "Secondary" else out
		var first: Dictionary = out[0]
		for x in out:
			if key_p.call(x) > key_p.call(first):
				first = x
		var rest: Array = out.filter(func(x): return not is_same(x, first))
		var sec: Dictionary = rest[0]
		for x in rest:
			if key_s.call(x) > key_s.call(sec):
				sec = x
		if slot == "Secondary":
			return [sec]
		if slot == "Primary":
			return [first] + rest.filter(func(x): return not is_same(x, sec))
	return out


## Whether the two worn guns feed from one type's magazines (the three-stage review, game 2): one pool, shared.
func shared_mags() -> bool:
	var p = equipped["Primary"]
	var q = equipped["Secondary"]
	return p != null and q != null and Items.mag_size(p) > 0 and Items.mag_size(q) > 0 and Items.ammo_type(p) == Items.ammo_type(q) and Items.ammo_type(p) != ""


## The share of the time a slot's gun fires, its reloads apart, read off the magazines it carries (30 Oct): the seconds
## they last over those and a reload into each (the gun's reload times the magazine's). What the figures out of a
## fight read (the odds' survival read, the sheet, a try-on).
func mag_share(slot: String) -> float:
	if not uses_mag(slot):
		return 1.0
	var gun: Dictionary = equipped[slot]
	var rate: float = maxf(0.01, float(Items.base_of(gun)["rof"]))     # pace scales the fire and the reloads alike (the fix round): it cancels
	if slot == "Secondary" and equipped["Primary"] != null and has_rounds(equipped["Primary"]):
		# behind the primary as the fight spends it (the second review): its backing share while the primary fires, the
		# reload's share (a sling's lift) through the primary's reloads
		var px: float = mag_share("Primary")
		rate *= secondary_share(true) * px + (1.0 - px) * reload_share()
	var fire_s := 0.0
	var re_s := 0.0
	var mags: Array = _mags_read(gun, slot)
	if mags.is_empty() and slot == "Secondary" and shared_mags() and not mags_for(gun).is_empty():
		return 0.0                                # its one magazine is the primary's (the three-stage review, game 2)
	if mags.is_empty():
		fire_s = float(Items.mag_size(gun)) / rate
		re_s = reload_s(gun)
	for mg in mags:
		fire_s += float(Items.mag_cap(mg, gun)) / rate
		re_s += reload_s(gun) * Items.mag_reload_x(mg)
	if mags.size() >= 2 and hot_swap():
		# the rig's swap (BUILD46-R), its lift capped (BUILD51-A, the 2 Nov reviews): never past the no-swap share +A51_SWAP_LIFT
		return minf(1.0, fire_s / maxf(0.0001, fire_s + re_s) + A51_SWAP_LIFT)
	return fire_s / maxf(0.0001, fire_s + re_s)


## The share of now a slot's gun fires: the fight's own tick (its reload running, 28 Oct), else its average.
func fire_x(slot: String) -> float:
	if mission != null and not _trying and mission.has("fire_x"):
		return float(mission["fire_x"].get(slot, 1.0))
	return mag_share(slot)


## The pace a fight's reloads and refills run at (the fix round, the coordinator's call: the fight paced the fire and not the
## reloads, so a slower runner read as reloading less of the time): the runner's pace times the site's, as the fire's.
func reload_pace(m) -> float:
	var tp: float = float(m["t"].get("pace", 1.0)) if (m is Dictionary and m.get("t", null) is Dictionary) else 1.0
	return maxf(0.01, pace() * tp)


## The magazine in a slot's gun on a run, {} with none.
func mag_in(slot: String) -> Dictionary:
	if mission == null or not mission.has("mag_in"):
		return {}
	var id: int = int(mission["mag_in"].get(slot, -1))
	for it in rig:
		if int(it["id"]) == id:
			return it
	return {}


## A slot's magazine in the fight: [rounds left in it, its size, seconds of reload left]. [0, 0, 0] with none.
func mag_now(slot: String) -> Array:
	if mission == null or not uses_mag(slot):
		return [0, 0, 0.0]
	var gun: Dictionary = equipped[slot]
	var cur: Dictionary = mag_in(slot)
	if cur.is_empty():
		cur = _next_mag(slot)
	var left_s: float = float(mission.get("reload_t", {}).get(slot, 0.0)) / reload_pace(mission)     # in seconds, at the pace it runs
	if cur.is_empty():
		return [0, 0, left_s]
	return [int(cur.get("rounds", 0)), Items.mag_cap(cur, gun), left_s]


## The Kit's line under a gun (30 Oct, the approved canvas): its magazines in the rig and the rounds in them, long to
## short - "3 magazines · 36 rounds", "36 rounds"; "No rounds needed" for a blade or a free-round gun.
func kit_mag_line(gun: Dictionary) -> Array:
	if Items.mag_size(gun) <= 0:
		return [Words.MAG_WORDS["no_rounds"]]
	if shared_mags() and is_same(gun, equipped["Secondary"]):
		# the pool counted once, on the primary (the three-stage review, UI 5)
		var pn: String = Words.mid_base(str(equipped["Primary"]["base"]))
		return [Words.MAG_WORDS["shares"] % pn, Words.MAG_WORDS["shares_short"], Words.MAG_WORDS["shared"]]
	var rounds: String = Words.count_of(rounds_for(gun), "round")
	return [Words.MAG_WORDS["kit_line"] % [Words.count_of(mags_for(gun).size(), "magazine"), rounds], rounds]


## The Kit's "THE RIG" card for a magazine (30 Oct, the approved canvas): each worn gun's magazines and rounds, the meds,
## and the rounds left in the stash to refill - a line each, long to short.
func rig_card_lines() -> Array:
	var out: Array = []
	var types: Array = []
	for slot in ["Primary", "Secondary"]:
		var g = equipped[slot]
		if g == null:
			continue
		var line: Array = kit_mag_line(g)
		var nm: String = str(g["base"])
		out.append([Words.MAG_WORDS["rig_gun"] % [nm, Words.mid_base(str(line[0])) if (Items.mag_size(g) <= 0 or line.size() == 3) else str(line[0]).replace(" · ", ", ")],
			Words.MAG_WORDS["rig_gun"] % [nm, Words.mid_base(str(line[1])) if line.size() == 3 else str(line[-1])], str(line[-1])])
		if Items.mag_size(g) > 0 and not (Items.ammo_type(g) in types):
			types.append(Items.ammo_type(g))
	var heals: Array = []
	var cure_n := {}
	var grenades := 0
	for it in rig:
		if Items.is_cure(it):
			cure_n[Items.cure_of(it)] = int(cure_n.get(Items.cure_of(it), 0)) + 1
		elif Items.is_medical(it):
			heals.append(it)
		elif Items.is_grenade(it):
			grenades += 1
	# the meds counted by kind, one list ("Meds: a bandage, 2 packs of painkillers and a cure for bleed": the three-stage
	# review, UI 13; the reviewer on m32c, 5), the grenades on the same line (UI 4: a fifth line pushed the stash's rounds
	# off the card); no meds, the grenades their own (the reviewer, 10)
	var th: Array = _things(heals)
	var meds: Array = Words.things_parts(th[0], th[1])
	var n_cures := 0
	for e in cure_n:
		var ail: String = str(Words.MAG_WORDS["cure_for"].get(e, e))     # the ailment's word (the language pass): "2 cures for burns"
		meds.append((Words.MAG_WORDS["rig_cure"] % ail) if int(cure_n[e]) == 1 else (Words.MAG_WORDS["rig_cures"] % [int(cure_n[e]), ail]))
		n_cures += int(cure_n[e])
	var n_meds: int = heals.size() + n_cures
	if n_meds == 0 and grenades > 0:
		out.append([Words.MAG_WORDS["rig_grenades"] % grenades])
	else:
		var gl: String = (" · " + Words.count_of(grenades, "grenade")) if grenades > 0 else ""
		out.append([Words.MAG_WORDS["rig_meds"] % ((Words.and_list(meds) if n_meds > 0 else Words.MAG_WORDS["rig_none"]) + gl),
			Words.MAG_WORDS["rig_meds"] % ((str(n_meds) if n_meds > 0 else Words.MAG_WORDS["rig_none"]) + gl)])
	var left: Array = []
	for ty in types:
		var n := 0
		for it in stash:
			if Items.is_ammo(it) and str(Items.base_of(it)["type"]) == ty:
				n += int(it.get("rounds", 0))
		var box: Dictionary = ammo_box(str(ty))
		left.append("%s %s" % [_group_n(n), Words.mid_base(str(box.get("name", "rounds")))])
	if not left.is_empty():
		out.append([Words.MAG_WORDS["rig_stash"] % ", ".join(left), Words.MAG_WORDS["rig_stash"] % str(left[0]), Words.MAG_WORDS["rig_stash_short"] % str(left[0])])
	return out


## Items as Words.things_list takes them: [their bases, the bases' own forms where the data gives them - {"plural",
## "one"}: "2 tubes of burn gel", "a tube of burn gel"].
static func _things(items: Array) -> Array:
	var names: Array = []
	var forms := {}
	for it in items:
		names.append(str(it["base"]))
		var b: Dictionary = Items.base_of(it)
		if b.has("plural") or b.has("one"):
			forms[str(it["base"])] = {"plural": str(b.get("plural", "")), "one": str(b.get("one", ""))}
	return [names, forms]


## A thousands comma, as the screens write a count ("1,288").
static func _group_n(n: int) -> String:
	return Words.group(n)                     # the one grouping (the reviewer on m32c, 9)


## The magazine in the rig a stash magazine is compared with (30 Oct): of its type, the smallest; {} for none.
func mag_rig_match(it: Dictionary) -> Dictionary:
	var best := {}
	var gun = mag_gun(it)
	for r in rig:
		if Items.is_mag(r) and Items.mag_type(r) == Items.mag_type(it) and not is_same(r, it):
			if best.is_empty() or Items.mag_cap(r, gun) < Items.mag_cap(best, gun):
				best = r
	return best


## A magazine against another for the compare's foot (30 Oct, the approved canvas): [[delta, words], ...] - rounds,
## pouches (more is a cost), reload seconds (slower is a cost) - and the verdict [words, tone].
func mag_compare(it: Dictionary, other: Dictionary) -> Array:
	var gun = mag_gun(it)
	var out: Array = []
	var dr: int = Items.mag_cap(it, gun) - Items.mag_cap(other, gun)
	if dr != 0:
		out.append([float(dr), Words.count_of(absi(dr), "round")])
	var dp: int = Items.size(it) - Items.size(other)
	if dp != 0:
		out.append([-float(dp), Words.count_of(absi(dp), "pouch", "pouches")])
	var base_s: float = reload_s(gun) if gun is Dictionary else float(Data.RELOAD_S.get(Items.mag_type(it), 2.0))
	var ds: float = base_s * (Items.mag_reload_x(it) - Items.mag_reload_x(other))
	if absf(ds) >= 0.05:
		out.append([-ds, "%s s reload" % Words.fig1(absf(ds))])
	var up: bool = out.any(func(d): return float(d[0]) > 0.0)
	var down: bool = out.any(func(d): return float(d[0]) < 0.0)
	var verdict: Array = ["▲ Upgrade", "good"] if up and not down else (["▼ Downgrade", "bad"] if down and not up else ["Sidegrade", "warn"])
	return [verdict, out]


## A stash magazine swapped for one in the rig (30 Oct, the compare's "Swap into the rig"): the rig's back to the stash,
## this one in, filled from the boxes. False when the rig or the stash hasn't the room, or the runner's out.
func can_mag_swap(stash_id: int, rig_id: int) -> bool:
	if runner_busy():
		return false
	var a := {}
	var b := {}
	for it in stash:
		if int(it["id"]) == stash_id and Items.is_mag(it):
			a = it
	for it in rig:
		if int(it["id"]) == rig_id:
			b = it
	if a.is_empty() or b.is_empty():
		return false
	return rig_used() - Items.size(b) + Items.size(a) <= med_capacity() and (stash_free(b) or stash_used() - (0 if stash_free(a) or tab_of(a) != "" else Items.size(a)) + Items.size(b) <= stash_cap())


func mag_swap(stash_id: int, rig_id: int) -> bool:
	if not can_mag_swap(stash_id, rig_id):
		return false
	var a := {}
	for it in stash:
		if int(it["id"]) == stash_id:
			a = it
	var b := {}
	for k in range(rig.size()):
		if int(rig[k]["id"]) == rig_id:
			b = rig[k]
			rig.remove_at(k)
			break
	_remove(a)
	rig.append(a)
	if not stash_put(b):
		stash.append(b)
	_fill_mags()
	_dry_memo.clear()
	_stats_dirty()
	return true


## A magazine in the stash or the rig, by id; {} for none (BUILD46-R: Unload and Load with).
func _mag_by_id(id: int) -> Dictionary:
	for it in stash + rig:
		if int(it["id"]) == id and Items.is_mag(it):
			return it
	return {}


## Unload (BUILD46-R, 2 Nov, Matt: "no way of unloading mags in the stash"): a magazine's rounds back to the stash as their
## grade, the magazine empty. At home only, with room in the stash for the rounds (a stack's room, or a cell).
func can_mag_unload(id: int) -> bool:
	var it: Dictionary = _mag_by_id(id)
	if runner_busy() or it.is_empty() or int(it.get("rounds", 0)) <= 0 or str(it.get("ammo", "")) == "":
		return false
	var back: Dictionary = _plain(Data.AMMO, str(it["ammo"]))
	Items.set_stack(back, int(it["rounds"]))
	return _stack_room(back) or stash_fits(back)


func mag_unload(id: int) -> bool:
	if not can_mag_unload(id):
		return false
	var it: Dictionary = _mag_by_id(id)
	var back: Dictionary = _plain(Data.AMMO, str(it["ammo"]))
	Items.set_stack(back, int(it["rounds"]))
	if not stash_put(back):
		stash.append(back)
	it["rounds"] = 0
	it["ammo"] = ""
	_dry_memo.clear()
	_stats_dirty()
	return true


## The stash's grades a magazine takes, [[grade, rounds], ...], the best first (the build's element first for the primary's).
func load_grades(id: int) -> Array:
	var it: Dictionary = _mag_by_id(id)
	if it.is_empty():
		return []
	var counts: Dictionary = _grade_counts()
	var els: Array = build_elements() if Items.mag_fits(it, equipped["Primary"]) else []
	var out: Array = []
	for g in counts:
		var b: Dictionary = Items.base_named(Data.AMMO, str(g))
		if not b.is_empty() and str(b["type"]) == Items.mag_type(it) and int(counts[g]) > 0 and can_mag_load(id, str(g)):
			out.append([str(g), int(counts[g])])     # never the grade a full magazine already holds (fix 46, R7)
	out.sort_custom(func(a, b2): return _grade_worth(Items.base_named(Data.AMMO, str(a[0])), els) > _grade_worth(Items.base_named(Data.AMMO, str(b2[0])), els))
	return out


## A grade's tag after its name (BUILD46-R, the stash's load list): "+20%" for a damage grade, its element for one that
## lands as one ("fire"); "" for a plain box.
static func grade_tag(grade: String) -> String:
	var b: Dictionary = Items.base_named(Data.AMMO, grade)
	for ty in Data.ELEMENTS:
		if b.has("conv_%s_pct" % ty):
			return ty
	if b.has("damage_pct"):
		return Words.ROUNDS["grade_damage"] % int(b["damage_pct"])
	return ""


## Load with (BUILD46-R, Matt: "loading a different ammo type"): what's in it back to the stash, then filled to its size
## from that grade. A grade it already holds tops it up. At home only.
func can_mag_load(id: int, grade: String) -> bool:
	var it: Dictionary = _mag_by_id(id)
	if runner_busy() or it.is_empty() or _rounds_in_stash(grade) <= 0:
		return false
	var b: Dictionary = Items.base_named(Data.AMMO, grade)
	if b.is_empty() or str(b["type"]) != Items.mag_type(it):
		return false
	if str(it.get("ammo", "")) == grade:
		return int(it.get("rounds", 0)) < Items.mag_cap(it, mag_gun(it))
	if int(it.get("rounds", 0)) > 0 and str(it.get("ammo", "")) != "":
		# what's in it goes back first: onto its grade's stacks, else a cell of its own - never over the stash (fix 46, R8)
		var back: Dictionary = _plain(Data.AMMO, str(it["ammo"]))
		Items.set_stack(back, int(it["rounds"]))
		return _stack_room(back) or stash_fits(back)
	return true


func mag_load_with(id: int, grade: String) -> bool:
	if not can_mag_load(id, grade):
		return false
	var it: Dictionary = _mag_by_id(id)
	var cap: int = Items.mag_cap(it, mag_gun(it))
	var have: int = int(it.get("rounds", 0)) if str(it.get("ammo", "")) == grade else 0
	var n: int = mini(cap - have, _rounds_in_stash(grade))
	if have == 0 and int(it.get("rounds", 0)) > 0 and str(it.get("ammo", "")) != "":
		var back: Dictionary = _plain(Data.AMMO, str(it["ammo"]))
		Items.set_stack(back, int(it["rounds"]))
		if not stash_put(back):               # merged onto its stacks or a cell of its own: can_mag_load made sure (fix 46, R8)
			return false
	_take_rounds(grade, n)
	it["rounds"] = have + n
	it["ammo"] = grade
	_dry_memo.clear()
	_stats_dirty()
	return true


## Why Load with is shut on a magazine that has grades of its type in the stash, or "": the stash can't take its rounds
## back (R8's room check; the re-review: a greyed button gives its reason).
func load_block(id: int) -> String:
	var it: Dictionary = _mag_by_id(id)
	if it.is_empty() or runner_busy() or not load_grades(id).is_empty():
		return ""
	var counts: Dictionary = _grade_counts()
	for g in counts:
		var b: Dictionary = Items.base_named(Data.AMMO, str(g))
		if not b.is_empty() and str(b["type"]) == Items.mag_type(it) and int(counts[g]) > 0 and not (str(g) == str(it.get("ammo", "")) and int(it.get("rounds", 0)) >= Items.mag_cap(it, mag_gun(it))):
			return Words.ISSUED["no_room"]
	return ""


## A magazine's fill, 0 to 1, against the gun it feeds (the cell's bar).
func mag_fill(it: Dictionary) -> float:
	return clampf(float(it.get("rounds", 0)) / float(maxi(1, Items.mag_cap(it, mag_gun(it)))), 0.0, 1.0)


## A magazine as a line: "12 of 16 rounds", against the gun it feeds; never over its size (the fix round).
func mag_words(it: Dictionary) -> String:
	var cap: int = Items.mag_cap(it, mag_gun(it))
	return Words.MAG_WORDS["figure"] % [mini(int(it.get("rounds", 0)), cap), cap]


## The loaded magazines for a slot's gun past the one in it: the spares the run's Rounds tile counts.
func mags_spare(slot: String) -> int:
	var gun = equipped[slot]
	if gun == null:
		return 0
	var cur: Dictionary = mag_in(slot)
	var other: Dictionary = mag_in("Secondary" if slot == "Primary" else "Primary")     # nor the other gun's (the three-stage review, UI 16)
	return mags_for(gun).filter(func(x): return int(x.get("rounds", 0)) > 0 and not is_same(x, cur) and not is_same(x, other)).size()


## A magazine being refilled by hand for a slot's gun's type (30 Oct, the playtest's item 4): seconds left, 0 for none.
func refill_now(slot: String) -> float:
	var gun = equipped[slot]
	if mission == null or gun == null or not mission.has("refill"):
		return 0.0
	return float(Dictionary(mission["refill"].get(Items.ammo_type(gun), {})).get("t", 0.0)) / reload_pace(mission)     # seconds, at the pace it runs


## The next loaded magazine for a slot's gun: by the feed's order (the build's element, then the grade's worth, then the
## fullest), never the one in the other gun.
func _next_mag(slot: String) -> Dictionary:
	var gun = equipped[slot]
	if gun == null:
		return {}
	var oslot: String = "Secondary" if slot == "Primary" else "Primary"
	var other: Dictionary = mag_in(oslot)
	var cur: Dictionary = mag_in(slot)
	var o_to: int = int(mission.get("reload_to", {}).get(oslot, -1)) if mission != null else -1     # nor the one the other's reload is putting in
	var els: Array = build_elements() if slot == "Primary" else []
	var best := {}
	var bv := -1.0
	for it in mags_for(gun):
		if int(it.get("rounds", 0)) <= 0 or is_same(it, other) or is_same(it, cur) or int(it["id"]) == o_to:
			continue
		var v: float = float(_grade_worth(Items.grade_base(it), els)) * 1000.0 + float(it["rounds"])
		if v > bv:
			best = it
			bv = v
	return best


## The primary's magazine when the rig has none loaded for it but the secondary holds the type's last (the three-stage
## review, game 2): the secondary's, taken out of it - the secondary is then without. {} otherwise.
func _share_take(m: Dictionary, slot: String) -> Dictionary:
	if slot != "Primary" or equipped["Primary"] == null:
		return {}
	var other: Dictionary = mag_in("Secondary")
	if not other.is_empty() and int(other.get("rounds", 0)) > 0 and Items.mag_fits(other, equipped["Primary"]):
		m["mag_in"].erase("Secondary")
		return other
	# or the one the secondary's reload is putting in, its reload stopped (the reviewer on m32c, 8)
	var to_id: int = int(m.get("reload_to", {}).get("Secondary", -1))
	for it in rig:
		if int(it["id"]) == to_id and int(it.get("rounds", 0)) > 0 and Items.mag_fits(it, equipped["Primary"]):
			m["reload_to"].erase("Secondary")
			m["reload_t"].erase("Secondary")
			return it
	return {}


## A grade's worth for the feed's order: its value, and the build's own element before any worth.
static func _grade_worth(b: Dictionary, els: Array) -> int:
	var v: int = int(b.get("value", 0))
	for e in els:
		if float(b.get("conv_%s_pct" % e, 0)) > 0.0:
			v += 100000
	return v


## A magazine into a slot's gun: the feed's grade may move (the conversion reads it).
func _mag_load(m: Dictionary, slot: String, it: Dictionary) -> void:
	if it.is_empty():
		m["mag_in"].erase(slot)
	else:
		m["mag_in"][slot] = int(it["id"])
	_dry_memo.erase("conversion")
	_stats_dirty()


## The magazines before a tick's fire (28 Oct; 30 Oct, as items): a reload under way runs on, the tick's share of fire
## what's left of it past the reload; done, the next magazine is in. A gun fired for the first time loads at once. With
## every magazine of its type spent and a box of it in the pack, the runner refills one by hand: a long reload, the gun
## quiet (the secondary carries the fight as when out of rounds).
func _mags_tick(m: Dictionary, dt: float) -> void:
	if not m.has("fire_x"):
		m["fire_x"] = {}
		m["mag_in"] = {}
		m["reload_t"] = {}
		m["reload_to"] = {}
		m["refill"] = {}
	if not m.has("bg_refill"):
		m["bg_refill"] = {}                       # the rig's swap's refills (BUILD46-R): {magazine id: seconds left}
	var dtp: float = dt * reload_pace(m)          # reloads and refills at the runner's pace, as the fire is (the fix round)
	a51_mags_seen(m)                              # BUILD51-A: which guns have had a magazine in the rig this run
	_refills_tick(m, dtp)
	_bg_refills_tick(m, dtp)
	for slot in ["Primary", "Secondary"]:
		if not uses_mag(slot) or not has_rounds(equipped[slot]):
			m["fire_x"][slot] = 1.0
			if uses_mag(slot):
				_refill_start(m, slot)
			continue
		var left: float = float(m["reload_t"].get(slot, 0.0))
		if left > 0.0:
			m["fire_x"][slot] = clampf((dtp - left) / maxf(dtp, 0.0001), 0.0, 1.0)
			left -= dtp
			if left <= 0.0:
				m["reload_t"].erase(slot)
				_mag_load(m, slot, _reload_target(m, slot))
			else:
				m["reload_t"][slot] = left
			continue
		m["fire_x"][slot] = 1.0
		var cur: Dictionary = mag_in(slot)
		if cur.is_empty() or int(cur.get("rounds", 0)) <= 0:
			var nx: Dictionary = _next_mag(slot)
			if nx.is_empty():
				nx = _share_take(m, slot)
			_mag_load(m, slot, nx)                # the first magazine: in at the gate; one taken out of the rig, the next
			if nx.is_empty():
				m["fire_x"][slot] = 0.0           # no magazine in it: it doesn't fire (the three-stage review, game 2)


## The magazine a reload is putting in: the one it started with while it's still loaded, else the next.
func _reload_target(m: Dictionary, slot: String) -> Dictionary:
	var id: int = int(m["reload_to"].get(slot, -1))
	m["reload_to"].erase(slot)
	for it in rig:
		if int(it["id"]) == id and int(it.get("rounds", 0)) > 0 and not is_same(it, mag_in("Secondary" if slot == "Primary" else "Primary")):
			return it
	return _next_mag(slot)


## A refill begun (30 Oct): a slot's gun has no loaded magazine, one of its type is in the rig, a box of the type in the pack.
func _refill_start(m: Dictionary, slot: String) -> void:
	var gun: Dictionary = equipped[slot]
	var ty: String = Items.ammo_type(gun)
	if m["refill"].has(ty) or rounds_for(gun) > 0:
		return
	if _bg_refilling(m, ty):
		return                                    # the rig's swap is refilling one already (BUILD46-R): that one's sooner
	if _pack_box(m, ty).is_empty():
		return
	var mags: Array = mags_for(gun)
	if mags.is_empty() and not a51_mag_had(m, gun):     # only a gun that's had none in the rig this run (BUILD51-A)
		# none in the rig (the three-stage review, game 1): one that fits from the pack, room made for it as a gun fitted does
		for f in m["found"].duplicate():
			if Items.is_mag(f) and Items.mag_fits(f, gun) and not a51_hand_out(m, f) and _rig_room_for(m, f, gun):
				m["found"].erase(f)
				pack_off(f)
				f.erase("first_gun")
				rig.append(f)
				mags = [f]
				break
	if mags.is_empty():
		return
	var pick: Dictionary = mags[0]
	for it in mags:
		if Items.mag_cap(it, gun) > Items.mag_cap(pick, gun):
			pick = it                             # the biggest, for the long wait
	var secs: float = reload_s(gun) * Data.REFILL_MULT
	m["refill"][ty] = {"t": secs, "id": int(pick["id"]), "slot": slot}
	m["refills"] = int(m.get("refills", 0)) + 1
	if not m.get("refill_said", false):
		m["refill_said"] = true               # once a gang (the three-stage review, game 6: the log's cap was all refills)
		log_event(Words.LOG["refilling"])


## The best box of a type in the run's pack, {} for none.
func _pack_box(m: Dictionary, ty: String) -> Dictionary:
	var best := {}
	var bv := -1
	for it in m.get("found", []):
		if Items.is_ammo(it) and str(Items.base_of(it)["type"]) == ty and int(it.get("rounds", 0)) > 0:
			var v: int = _grade_worth(Items.base_of(it), build_elements())
			if v > bv:
				best = it
				bv = v
	return best


## The boxes the gate packs for the refills (30 Oct, the designer's call A: "a box in the pack"): one of each worn gun's
## rounds type - the grade its magazines hold, else the stash's best of the type, on "Best grades only" the top-up's grade
## or none - one box of that grade at most (its base's rounds), up to what the stash holds after the fill. `read`: the
## odds' and the card's read, after a dry run of the same fill (_fill_plan); the gate packs what _box_plan gives either way.
var gate_box_always := false     # the bot's (30 Oct): it packs on "fill" whatever the save says, its gate box too


func _gate_boxes(read := false, bg_in = null, at := -1) -> Array:
	var p: Dictionary = rounds_plan(at)       # the site's plan (BUILD46-R)
	var counts: Dictionary = _grade_counts()
	var bg = bg_in if bg_in != null else _plan_bg(p, counts)     # the gate's: the top-up's own, worked out before its fill
	var plan: Array = []
	if read:
		plan = _gate_mags_plan(p)             # the read's box after a dry run of the same fill, grade by grade (the reviewer on m32c, 3)
		if bool(p.get("load", true)):
			_fill_plan(plan, counts, bg, _plan_picks(p, counts))
	if not read:
		return _box_plan(counts, null, bg, p, at)     # the rig as it is: the gate's own, after its fill
	return _box_plan(counts, plan, bg, p, at)


## The gate's boxes off `counts` (the stash's rounds by grade, after the fill): for each worn gun's type the grade its
## magazines hold (`plan`: the read's filled copies; null, the rig as it is), else the counts' best; on "Best grades only"
## that grade or nothing (the reviewer on m32c, 1). Each one box of its grade at most (the base's rounds), taken off
## `counts`.
func _box_plan(counts: Dictionary, plan, bg, rp = null, at := -1) -> Array:
	var out: Array = []
	var types: Array = []
	var p: Dictionary = rp if rp is Dictionary else rounds_plan(at)
	var room: int = capacity()               # the pack's cells at the gate (BUILD46-R): what doesn't fit stays home
	for slot in ["Primary", "Secondary"]:
		var g = equipped[slot]
		if g == null or Items.mag_size(g) <= 0 or Items.ammo_type(g) in types:
			continue
		var ty: String = Items.ammo_type(g)
		types.append(ty)
		var grade := ""
		var pick: String = _plan_grade(p, ty)
		if pick != "" and int(counts.get(pick, 0)) > 0:
			grade = pick                      # the plan's grade (BUILD46-R)
		elif gate_box_always:
			grade = _best_in_counts(counts, ty, slot == "Primary")     # the bot's: its best grade
		elif bg is Dictionary and bg.has(ty):
			grade = str(bg.get(ty, ""))
		else:
			var held: Dictionary = _plan_feed(plan, g, slot) if plan is Array else feed_stack(g)
			if not held.is_empty() and Items.is_mag(held):
				grade = str(held.get("ammo", ""))
			if grade == "" or int(counts.get(grade, 0)) <= 0:
				grade = _best_in_counts(counts, ty, slot == "Primary")
		if grade == "" or int(counts.get(grade, 0)) <= 0:
			continue
		# N boxes of the grade (BUILD46-R: the 0.10.2 one-box rule went), each its base's rounds, the last what's left;
		# a repeat run's one at least (it always packed one); the bot's its own count
		var n: int = _plan_boxes(p, ty)
		var per: int = int(Items.base_named(Data.AMMO, grade)["rounds"])
		if gate_box_always:
			var have := 0
			for r in (plan if plan is Array else rig):
				if Items.mag_fits(r, g):
					have += int(r.get("rounds", 0))
			n = _bot_boxes(at, ty, have, per)
		elif _repeat_going:
			n = maxi(1, n)
		for k in range(n):
			if int(counts[grade]) <= 0 or room <= 0:
				break
			var box: Dictionary = _plain(Data.AMMO, grade)
			Items.set_stack(box, mini(per, int(counts[grade])))
			counts[grade] = int(counts[grade]) - int(box["rounds"])
			box["carried"] = true                 # the runner's own: home to the stash, never loot
			room -= Items.size(box)
			out.append(box)
	return out


## The magazine a gun feeds from among the plan's copies, as feed_stack reads the rig: the best loaded grade.
func _plan_feed(plan: Array, g: Dictionary, slot: String) -> Dictionary:
	var els: Array = build_elements() if slot == "Primary" else []
	var best := {}
	var bv := -1
	for it in plan:
		if Items.mag_fits(it, g) and int(it.get("rounds", 0)) > 0:
			var v: int = _grade_worth(Items.grade_base(it), els)
			if v > bv:
				best = it
				bv = v
	return best


## Whether the gate packs its box (the second review: one predicate for the run and the odds' read): not on "Leave it",
## except a repeat run's packing or the bot's.
func gate_box_on(at := -1) -> bool:
	if _repeat_going or gate_box_always:
		return true
	var p: Dictionary = rounds_plan(at)       # any boxes in the site's plan (BUILD46-R); the old "Leave it" none
	for slot in ["Primary", "Secondary"]:
		var g = equipped[slot]
		if g != null and Items.mag_size(g) > 0 and _plan_boxes(p, Items.ammo_type(g)) > 0:
			return true
	return false


## The gate's boxes into the run's pack, off the stash, where the pack has the room; logged a box a line.
func _pack_boxes(m: Dictionary) -> void:
	for box in _gate_boxes(false, _gate_bg, int(m.get("tier", -1))):     # "Best grades only": the grade the top-up worked out before filling (the reviewer on m32c); the site's plan (BUILD46-R)
		var spot: Array = pack_spot(m, box)
		if spot.is_empty():
			continue
		_take_rounds(str(box["base"]), int(box["rounds"]))
		_pack_put(m, box, spot)
		log_event(Words.PACKED_BOX % Words.mid_base(str(box["base"])))


## The refills under way run on; done, the magazine is filled from the pack's best box of its type and goes in the gun.
func _refills_tick(m: Dictionary, dt: float, all_done := false) -> void:
	for ty in m["refill"].keys():
		var r: Dictionary = m["refill"][ty]
		r["t"] = float(r["t"]) - dt
		if float(r["t"]) > 0.0 and not all_done:
			continue
		m["refill"].erase(ty)
		var mg := {}
		for it in rig:
			if int(it["id"]) == int(r["id"]):
				mg = it
		var box: Dictionary = _pack_box(m, str(ty))
		var slot: String = str(r["slot"])
		if mg.is_empty() or box.is_empty() or equipped[slot] == null:
			continue
		var n: int = mini(Items.mag_cap(mg, equipped[slot]), int(box["rounds"]))
		mg["rounds"] = n
		mg["ammo"] = str(box["base"])
		m["last_refill"] = n                  # what the box gave, for the reads and the tests
		Items.set_stack(box, int(box["rounds"]) - n)
		if int(box["rounds"]) <= 0:
			m["found"].erase(box)
		_mag_load(m, slot, mg)
		_dry_memo.clear()
		_stats_dirty()


## The rig's swap's refill begun (BUILD46-R): a spent magazine of a gun's type, refilled from the pack's best box of the
## type over a hand refill's seconds while the gun fires the next. Nothing with no box in the pack.
func _bg_refill_start(m: Dictionary, mg: Dictionary, gun: Dictionary) -> void:
	if mg.is_empty() or not m.has("bg_refill") or m["bg_refill"].has(int(mg["id"])):
		return
	if _pack_box(m, Items.ammo_type(gun)).is_empty():
		return
	m["bg_refill"][int(mg["id"])] = reload_s(gun) * Data.REFILL_MULT
	m["bg_refills"] = int(m.get("bg_refills", 0)) + 1


## Whether the rig's swap is refilling a magazine of this type.
func _bg_refilling(m: Dictionary, ty: String) -> bool:
	for id in m.get("bg_refill", {}):
		for it in rig:
			if int(it["id"]) == int(id) and Items.mag_type(it) == ty:
				return true
	return false


## The rig's swap's refills run on (BUILD46-R); done, the magazine is filled from the pack's best box of its type -
## the one in neither gun - and waits in the rig for its turn.
func _bg_refills_tick(m: Dictionary, dt: float, all_done := false) -> void:
	for id in m["bg_refill"].keys():
		var left: float = float(m["bg_refill"][id]) - dt
		if left > 0.0 and not all_done:
			m["bg_refill"][id] = left
			continue
		m["bg_refill"].erase(id)
		var mg := {}
		for it in rig:
			if int(it["id"]) == int(id):
				mg = it
		if mg.is_empty() or int(mg.get("rounds", 0)) > 0:
			continue
		var box: Dictionary = _pack_box(m, Items.mag_type(mg))
		if box.is_empty():
			continue
		var n: int = mini(Items.mag_cap(mg, mag_gun(mg)), int(box["rounds"]))
		mg["rounds"] = n
		mg["ammo"] = str(box["base"])
		Items.set_stack(box, int(box["rounds"]) - n)
		if int(box["rounds"]) <= 0:
			m["found"].erase(box)
		_dry_memo.clear()
		_stats_dirty()


## Shots out of a slot's magazine (28 Oct; 30 Oct, as items): rounds come off the magazine in the gun; empty, the next
## loaded one goes in after a reload (the gun's, times the next magazine's kind). None left: out of rounds.
func _fire_rounds(m: Dictionary, slot: String, shots: float) -> void:
	if not uses_mag(slot) or not m.has("mag_in"):
		return
	var gun: Dictionary = equipped[slot]
	m["fired"] = m.get("fired", {})
	m["fired"][slot] = float(m["fired"].get(slot, 0.0)) + shots
	while float(m["fired"][slot]) >= 1.0:
		var cur: Dictionary = mag_in(slot)
		if cur.is_empty() or int(cur.get("rounds", 0)) <= 0 or float(m["reload_t"].get(slot, 0.0)) > 0.0:
			m["fired"][slot] = 0.0
			return
		var n: int = mini(int(m["fired"][slot]), int(cur["rounds"]))
		cur["rounds"] = int(cur["rounds"]) - n
		m["fired"][slot] = float(m["fired"][slot]) - float(n)
		if int(cur["rounds"]) > 0:
			continue
		m["fired"][slot] = 0.0
		cur["ammo"] = ""                          # spent: it takes any grade next
		var nxt: Dictionary = _next_mag(slot)
		if nxt.is_empty():
			nxt = _share_take(m, slot)            # the secondary's, the type's last (the three-stage review, game 2)
		if nxt.is_empty():
			_mag_load(m, slot, {})
			if rounds_for(gun) <= 0 and _pack_box(m, Items.ammo_type(gun)).is_empty():     # dry only with no box left to refill from (game 6)
				log_event(Words.LOG["out_of_rounds"] % gun["base"])
				m["ran_dry"] = str(gun["base"])     # for the out-of-time line (16 Oct)
			return
		if hot_swap():
			# the rig's swap (BUILD46-R): the next one's in, the spent one refills from the pack as it fires; a short pause, the
			# lift capped at A51_SWAP_LIFT over the gun's no-swap share (BUILD51-A)
			_bg_refill_start(m, cur, gun)
			m["swaps"] = int(m.get("swaps", 0)) + 1
			var pause: float = a51_swap_pause(slot, nxt)
			if pause <= 0.0:
				_mag_load(m, slot, nxt)
				continue
			m["reload_t"][slot] = pause
			m["reload_to"][slot] = int(nxt["id"])
			return
		m["reloads"] = int(m.get("reloads", 0)) + 1
		var secs: float = reload_s(gun) * Items.mag_reload_x(nxt)
		if secs <= 0.0:
			_mag_load(m, slot, nxt)              # no reload (the Safecracker's): the next one's in at once
			continue
		m["reload_t"][slot] = secs
		m["reload_to"][slot] = int(nxt["id"])
		return


## Between gangs the magazines are seen to (28 Oct; 30 Oct, as items): the quiet's reload, free - a reload or a refill
## under way done, and a gun's magazine swapped for a fuller one of its type if the rig has one.
func _mags_topped(m: Dictionary) -> void:
	if not m.has("mag_in"):
		return
	m.erase("refill_said")                    # the next gang's refills say so once again
	a51_quiet_pull(m)                         # BUILD51-A: a gun fitted mid-fight takes its magazine from the pack in the quiet
	_refills_tick(m, 0.0, true)
	if m.has("bg_refill"):
		_bg_refills_tick(m, 0.0, true)       # the rig's swap's too (BUILD46-R)
	for slot in ["Primary", "Secondary"]:
		if m["reload_t"].has(slot):
			m["reload_t"].erase(slot)             # a reload under way when the last one went down: done in the quiet
			_mag_load(m, slot, _reload_target(m, slot))
		m["fire_x"][slot] = 1.0
		if not uses_mag(slot) or not has_rounds(equipped[slot]):
			continue
		var cur: Dictionary = mag_in(slot)
		var nxt: Dictionary = _next_mag(slot)
		if cur.is_empty() and nxt.is_empty():
			nxt = _share_take(m, slot)            # the type's last, in the secondary (the three-stage review, game 2)
		if cur.is_empty() or (not nxt.is_empty() and int(nxt["rounds"]) > int(cur.get("rounds", 0)) and int(cur.get("rounds", 0)) < Items.mag_cap(cur, equipped[slot])):
			if not nxt.is_empty():
				_mag_load(m, slot, nxt)


## The boxes a try-on counts as a trip to the rig's magazines: the stash's, and on a run the pack's (30 Oct: a box in the
## pack refills a magazine by hand).
func _rounds_held() -> Array:
	var out: Array = stash.filter(func(x): return Items.is_ammo(x))
	if mission != null:
		out.append_array(mission.get("found", []).filter(func(x): return Items.is_ammo(x)))
	return out


## A melee primary: in among them.
func melee() -> bool:
	return equipped["Primary"] != null and Items.is_melee(equipped["Primary"])


## The better grade's damage, from the magazine that's feeding the gun now.
func grade_bonus(gun: Dictionary) -> float:
	return grade_stat(gun, "damage_pct")


## What the grade feeding the gun carries for a stat: its damage, a share as an element (33), a first-shot weight.
func grade_stat(gun, stat: String) -> float:
	if gun == null:
		return 0.0                       # no gun in hand: untyped on purpose, a typed parameter would refuse the null
	var stack := feed_stack(gun)
	return float(Items.grade_base(stack).get(stat, 0)) if not stack.is_empty() else 0.0


## What a gun fires from (11 Oct, Matt: the best grade fires first; 30 Oct, as items): on a run, the magazine in it,
## else the next; at home, the best loaded magazine that fits it - a grade carrying an element the runner has trained
## into first (a fire build fires its incendiaries before Depot), then by the grade's worth. A try-on reads the best
## grade on hand, the stash's boxes too. {} when it's dry.
func feed_stack(gun: Dictionary) -> Dictionary:
	if _trying:                           # a try-on's kit stands still: the feed read once a gun (22 Oct, the pass's wall:
		var fk := "feed/%d" % int(gun.get("id", hash(gun)))     # a try read the stash's rounds six times); a run's feed is never memoised, its magazines run dry
		if not _try_memo.has(fk):
			_try_memo[fk] = _feed_stack_raw(gun)
		return _try_memo[fk]
	return _feed_stack_raw(gun)


func _feed_stack_raw(gun: Dictionary) -> Dictionary:
	if mission != null and not _trying:
		for slot in ["Primary", "Secondary"]:
			if is_same(gun, equipped[slot]):
				var cur: Dictionary = mag_in(slot)
				if not cur.is_empty() and int(cur.get("rounds", 0)) > 0:
					return cur
	var t := Items.ammo_type(gun)
	# the element only counts for the primary: a secondary's grade is damage only (the conversion reads the primary's)
	var els: Array = build_elements() if is_same(gun, equipped["Primary"]) else []
	var best := {}
	var bv := -1
	var pool: Array = mags_for(gun).filter(func(x): return int(x.get("rounds", 0)) > 0)
	if _trying:
		pool += _rounds_held().filter(func(x): return str(Items.base_of(x)["type"]) == t and int(x.get("rounds", 0)) > 0)
	for it in pool:
		var v: int = _grade_worth(Items.grade_base(it), els)
		if v > bv:
			best = it
			bv = v
	return best


## The elements the runner is built for: each element whose flower (its region on the web, not the joins it lends its
## colour to) has a node owned. Read again when the tree or the class change.
var _els_key := -1
var _els: Array = []
func build_elements() -> Array:
	var k: int = hash([tree, cls])     # the nodes themselves: a respec retrained to the same count is another build (the review)
	if k != _els_key:
		_els_key = k
		_els = []
		for et in Data.ELEMENT_TREES:
			for id in tree:
				if str(id).begins_with(str(et["name"]) + "/") and Data.web_region(str(id)).begins_with("el:"):
					_els.append(et["element"])
					break
	return _els


## The Fence sells standard boxes of every type without end: a box a type.
func ammo_box(type: String) -> Dictionary:
	for b in Data.BASES[Data.AMMO]:
		if b["type"] == type and not b.has("damage_pct"):
			return b
	return {}


func ammo_price(type: String) -> int:
	var b := ammo_box(type)
	return _inf(b["value"] * Data.AMMO_PRICE * _buy_k("fence_pct")) if not b.is_empty() else 0     # the shelf's buy multipliers (S1): Buyer's market doubles a box too


func buy_ammo(type: String) -> bool:
	if not room_open("fence"):
		return false
	var b := ammo_box(type)
	if b.is_empty() or cash < ammo_price(type) or not (stash_room(1) or yard_has("racks") or _stack_room(_plain(Data.AMMO, b["name"]))):
		return false
	cash -= ammo_price(type)
	stash_put(_plain(Data.AMMO, b["name"]))
	return true


## The first med in the rig, for the Use button and the Paramedic's rule.
func first_med() -> Dictionary:
	if has_rule("the_float"):
		return {}                            # the Float: no meds used (18 Oct: the rig stays for rounds and grenades)
	for it in rig:
		if Items.is_heal(it):
			return it                        # a heal: a cure is never the Use button's (28 Oct)
	return {}


## The heals in the rig (a cure isn't one: "No meds" means nothing to patch up with).
func meds_carried() -> int:
	if has_rule("the_float"):
		return 0
	var n := 0
	for it in rig:
		if Items.is_heal(it):
			n += 1
	return n


## The first cure in the rig for an element on you (28 Oct), {} when there's none or the Float's on.
func first_cure(ty: String) -> Dictionary:
	if has_rule("the_float"):
		return {}
	for it in rig:
		if Items.cure_of(it) == ty:
			return it
	return {}


## What an element on you would still take (28 Oct, the cures): a burn's, a poison's or a bleed's pool to tick off;
## frost's and shock's pools, the same measure of what their fire left. What the runner's auto-cure weighs.
func ail_weight(m: Dictionary, ty: String) -> float:
	if Data.DOTS.has(ty):
		return float(m.get("my_dots", {}).get(ty, 0.0))
	return float(m.get("my_ails", {}).get(ty, 0.0))


## An element cured on you: off you now, and CURE_IMMUNE_S before it can land again.
func _cure_on(m: Dictionary, ty: String) -> void:
	if Data.DOTS.has(ty):
		m.get("my_dots", {}).erase(ty)
	else:
		m.get("my_ails", {}).erase(ty)
	if not m.has("cure_t"):
		m["cure_t"] = {}
	m["cure_t"][ty] = Data.CURE_IMMUNE_S


## Frost or shock on you now, as a share of its whole effect (0 to 1): its pool over MY_AILS' full share of max HP.
func my_ail(m: Dictionary, ty: String) -> float:
	var pool: float = float(m.get("my_ails", {}).get(ty, 0.0))
	if pool <= 0.0:
		return 0.0                               # the hot path: nothing on you, no max HP read
	return clampf(pool / maxf(1.0, max_hp() * float(Data.MY_AILS[ty]["full"])), 0.0, 1.0)


## Your fire's pace under a chill on you: 1 with none, MY_AILS' frost `most` slower at the full pool.
func my_chill_x(m: Dictionary) -> float:
	return 1.0 - my_ail(m, "frost") * float(Data.MY_AILS["frost"]["most"])


## Whether a cure's grace holds an element off you now (28 Oct).
func cure_wards(m: Dictionary, ty: String) -> bool:
	return float(m.get("cure_t", {}).get(ty, 0.0)) > 0.0


## Everything on you gone: the dots and frost's and shock's pools (Clean hands, Code blue, a clear-all skill, a gang
## picked over).
func _clear_on_you(m: Dictionary) -> void:
	m["my_dots"] = {}
	m["my_ails"] = {}


## The runner's own cure (28 Oct): each element on you that would take CURE_AT of the HP left, cured by the first
## cure for it in the rig, as a heal goes in under 40%.
func _auto_cure(m: Dictionary) -> void:
	if m["t"].get("no_meds", false) or hp <= 0.0:
		return
	for ty in Data.ELEMENTS:
		if cure_wards(m, ty) or ail_weight(m, ty) < hp * Data.CURE_AT:
			continue
		var c := first_cure(ty)
		if not c.is_empty():
			use_med(int(c["id"]))


## A cure used: its element off you at once and CURE_IMMUNE_S before it lands again. Spent unless the Ambulance's Bag,
## the Second opinion or the run's first free med (Second shift, the Ambulance set) say otherwise - a cure is a med to
## them (28 Oct, the design: "the mythic Ambulance bag and the Paramedic's bum bag read 'a med' as a heal or a cure").
func _cure(m: Dictionary, k: int) -> void:
	var it: Dictionary = rig[k]
	var ty: String = Items.cure_of(it)
	if has_rule("ambulance_bag") or exploit_on("second_opinion"):
		pass
	elif (has_node("second_shift") or has_set_rule("ambulance")) and not m.get("free_med", false):
		m["free_med"] = true
	else:
		rig.remove_at(k)
	_cure_on(m, ty)
	m["cures_used"] = int(m.get("cures_used", 0)) + 1
	if not m.get("dry", false):
		log_event(Words.LOG["cure_used"] % [it["base"], Words.CURE_WORD[ty], int(Data.CURE_IMMUNE_S)])     # never the odds' dry runs (the review)


## Walking fire: the primary's `sustain` [a second, cap] as the stream's multiplier after `sustain_t` seconds on one gang.
func sustain_mult(m: Dictionary) -> float:
	var gun = equipped["Primary"]
	if gun == null or not Items.base_of(gun).has("sustain") or edges_off:     # walking fire is the SMG's edge (29 Oct): off with the rest
		return 1.0
	var su: Array = Items.base_of(gun)["sustain"]
	return 1.0 + minf(float(su[1]), float(su[0]) * float(m.get("sustain_t", 0.0))) / 100.0


## A unique's rule, by its flag, when one is worn.
## The rules in play, read from the kit and the stash once a shape of them (22 Oct, the pass's wall: a tick asked
## fifty times, each a walk of the stash). The shape: the worn pieces' rules, the stash's count, the item count and
## the count of what's left the stash - a paper comes or goes by one of those (the review: a paper sold as an old
## piece comes in off the rig keeps the count, so the leavings count too); a load or a class swap reads afresh.
var _rules := {}
var _rules_key := []
var _removed := 0                  # what _remove and the pile's sweep have taken out of the stash, ever
func has_rule(rule: String) -> bool:
	if _dry_on:
		return _dry_rules.has(rule)
	var on_body := []
	for s in Data.SLOTS:
		if equipped[s] != null:
			on_body.append(equipped[s].get("rule", ""))
	var key := [on_body, stash.size(), Items._next_id, _removed]
	if key != _rules_key:
		_rules_key = key
		_rules = _snapshot_rules()
	return _rules.has(rule)


## The loose uniques that can turn up at a depth: the ones gated at it or
## shallower. A site's own is never loose.
func loose_uniques(at_depth: int) -> Array:
	var out: Array = []
	for u in Data.UNIQUES:
		if not u.get("boss", false) and not u.has("site") and not u.get("mythic", false) and int(u.get("depth", 0)) <= at_depth:
			out.append(u)
	return out


## A unique out of a pool at a find's tier (12 Oct, uniques by tier): among those whose range takes the tier, the
## band's weight picks (levelling 10, core 4, chase 1). {} when none can drop there; `any` falls back (a shop's:
## something is always on offer) to the ones the tier has outgrown, held at their top, and only then the whole pool -
## never a deeper one than the player's dug to when an outgrown one will do (the reviewer's catch).
func pick_unique(pool: Array, tier_v: int, any := false) -> Dictionary:
	var fits: Array = pool.filter(func(u): return Items.unique_fits(u, tier_v))
	if fits.is_empty():
		if not any or pool.is_empty():
			return {}
		fits = pool.filter(func(u): return u.has("range") and int(u["range"][1]) < tier_v)
		if fits.is_empty():
			fits = pool
	var total := 0.0
	for u in fits:
		total += float(Data.UNIQUE_BAND_WEIGHT.get(str(u.get("band", "core")), 1.0))
	var x := rng.randf() * total
	for u in fits:
		x -= float(Data.UNIQUE_BAND_WEIGHT.get(str(u.get("band", "core")), 1.0))
		if x <= 0.0:
			return u
	return fits.back()


## The loose uniques a find can drop: gated at its depth or shallower, the range taking its tier. Cached: the table
## never changes, and _find reads it every find.
var _loose_at := {}
func loose_at(at_depth: int, tier_v: int) -> Array:
	var key := at_depth * 100 + tier_v
	if not _loose_at.has(key):
		_loose_at[key] = loose_uniques(at_depth).filter(func(u): return Items.unique_fits(u, tier_v))
	return _loose_at[key]


## A site's own unique (endgame part 3): one a site, found there only, past
## `site_unique_depth`. Empty for a site without one.
func site_unique(i: int) -> Dictionary:
	for u in Data.UNIQUES:
		if int(u.get("site", -1)) == i:
			return u
	return {}


## The depth a site's own drops from: by the site's zone, the gentler the
## ladder the deeper (the streets at 12, the Barracks at 6).
func site_unique_depth(i: int) -> int:
	return int(Data.SITE_UNIQUE_DEPTH[int(Data.TIERS[i]["zone"])])


## The shelf's chase (endgame part 3): the thirteen the shelf is empty of until
## the ladders are climbed - the nine sites' own, the three heads' charms, the
## lorry's load - each {name, found, where}, `where` the words for the gap.
func shelf_chase() -> Array:
	var out: Array = []
	for i in range(Data.TIERS.size()):
		var u := site_unique(i)
		if u.is_empty():
			continue
		out.append({"name": u["name"], "found": u["name"] in shelf, "where": Words.SHELF["own_gap"] % [Data.TIERS[i]["name"], site_unique_level(i)], "known": zone_open(int(Data.TIERS[i]["zone"]))})
	for u in Data.UNIQUES:
		if u.has("pinnacle"):
			for b in Data.BOSSES:
				if int(b["zone"]) == int(u["pinnacle"]):
					out.append({"name": u["name"], "found": u["name"] in shelf, "where": Words.SHELF["head_gap"] % [b["name"], lv_at(int(b["tier"]), pinnacle_depth(int(b["tier"])))], "known": zone_open(int(b["zone"]))})
	out.append({"name": Data.CONVOY_UNIQUE, "found": Data.CONVOY_UNIQUE in shelf, "where": Words.SHELF["lorry_gap"], "known": true})     # the depot's, Kev's last beat (15 Oct)
	for p in Data.PINNACLES:
		for uk in ["unique", "unique2"]:
			if p.has(uk):
				out.append({"name": p[uk], "found": p[uk] in shelf, "where": Words.SHELF["order_gap"] % [p["who"], Words.mid(str(p["place"]))], "known": order_known(str(p["key"]))})     # the order's (18 Oct), both (24 Oct)
	return out


## The deepest the Yard has been, on any site.
func deepest() -> int:
	var d := 1
	for i in range(Data.OUTSKIRTS_SITES, best_depth.size()):     # the Outskirts' ladders are the gentle ones: the depths that count are from the Streets (12 Oct)
		d = maxi(d, int(best_depth[i]))
	return d


## What the fitted guns' attachments add up to for a stat (pace, patrol delay,
## first-hostile damage); a gun's damage attachments are already in its dps.
func _fitted_sum(stat: String) -> float:
	return _memo("_fitted_sum/" + stat, __fitted_sum_raw.bind(stat))


func __fitted_sum_raw(stat: String) -> float:
	var t := 0.0
	for s in Data.SOCKET_SLOTS:
		if equipped[s] != null:
			t += Items.fitted_sum(equipped[s], stat)
	return t


## The charm's figures: magic find (rarer finds) and cash, in percent.
func charm_find() -> float:
	# the charm's own figure, and every loot-quality affix worn (the charm's, the helmet's, the pack's)
	return (Items.find(equipped[Data.CHARM]) - Items.affix_total(equipped[Data.CHARM], "rarity_pct") if equipped[Data.CHARM] != null else 0.0) + _affix_sum("rarity_pct")     # the base's, lifted (21 Oct)


func charm_cash() -> float:
	return (Items.cash_pct(equipped[Data.CHARM]) - Items.affix_total(equipped[Data.CHARM], "cash_pct") if equipped[Data.CHARM] != null else 0.0) + _affix_sum("cash_pct") + _fitted_sum("wire_pct")


# ------------------------------------------------------------------ the stash

func stash_cap() -> int:
	return Data.STASH_CELLS + (Data.FX["yard/shelving"] if yard_has("shelving") else 0) + (Data.FX["yard/another_unit"] if yard_has("another_unit") else 0) + (Data.FX["yard/lock_up"] if yard_has("lock_up") else 0) \
		+ (Data.FX["yard/annex"] if yard_has("annex") else 0) + Data.FX["yard_rank/stash"] * yard_rank("stash")


## Whether a stash item takes no cells: the Stash's Racks (rounds, meds, grenades), Wall of fame (uniques and set
## pieces). (The Paper rack's papers and charms went with it: papers live on the pile; it's the Filing cabinet, 19 Oct.)
func stash_free(it: Dictionary) -> bool:
	if Items.is_material(it):
		return true                       # scrap and materials (1 Nov): counted in at the gate, never a stash cell
	if yard_has("racks") and (Items.is_ammo(it) or Items.is_mag(it) or Items.is_medical(it) or Items.is_grenade(it)):
		return true
	return yard_has("wall_of_fame") and (it.has("unique") or it.has("set"))


## Cells in use: the shared tab's (21 Oct: a class's own tabs count apart, tab_used). What a run brings home goes there.
func stash_used() -> int:
	return tab_used("")


## The stash's tabs (21 Oct, Matt: "a shared tab between all classes and then one or two per class that isn't shared"):
## [key, name] - the shared one "", the class out's own "own", and its second "own2" with the Stash's Dry store. A
## class's own tabs go with it on a swap (set_class); the stash holds the shared tab and the class out's.
func stash_tabs() -> Array:
	var out: Array = [["", "Shared"]]
	if cls != "":
		out.append(["own", cls])
		if yard_has("dry_store"):
			out.append(["own2", "%s 2" % cls])
	return out


static func tab_of(it: Dictionary) -> String:
	return str(it.get("tab", ""))


func tab_used(tab: String) -> int:
	var n := 0
	for it in stash:
		if tab_of(it) == tab and not stash_free(it):
			n += Items.size(it)
	return n


func tab_cap(tab: String) -> int:
	match tab:
		"":
			return stash_cap()
		"own":
			return Data.CLASS_TAB_CELLS if cls != "" else 0
		"own2":
			return Data.CLASS_TAB_CELLS if cls != "" and yard_has("dry_store") else 0
	return 0


## A stash piece to another tab, where there's room for it. False when it can't go.
func move_to_tab(id: int, tab: String) -> bool:
	var it: Dictionary = {}
	for x in stash:
		if int(x["id"]) == id:
			it = x
	if it.is_empty() or tab_of(it) == tab or not stash_tabs().any(func(t): return t[0] == tab):
		return false
	if not stash_free(it) and tab_used(tab) + Items.size(it) > tab_cap(tab):
		return false
	if tab == "":
		it.erase("tab")
	else:
		it["tab"] = tab
	return true


func stash_room(cells: int) -> bool:
	return stash_used() + cells <= stash_cap()


## Room in the stash for this item: its cells, or none wanted at all (the Stash's Racks, Wall of fame, Paper rack).
func stash_fits(it: Dictionary) -> bool:
	return stash_free(it) or stash_room(Items.size(it))


## Cells the pack has used on this mission.
func pack_used(m: Dictionary) -> int:
	var n := 0
	for it in m["found"]:
		n += Items.size(it)
	return n


# ------------------------------------------------------------------ the pack as a grid (Matt, 27 Oct)
# The pack is the bag's own shape: pack_w() cells across, capacity() cells laid row by row (the last row short when the
# count runs out). Every piece in it has "pos" [x, y] and "rot" (turned a quarter: its footprint's sides swapped); a
# find lands where it fits, tried both ways; one that doesn't waits on the floor. A piece that must come home whatever
# the room (a head's unique, the first gun, a mythic) and finds none is "strapped" on: carried, no place. A piece in
# found with no "pos" (an old save, a test's fixture) is settled into the first place it fits.

## The pack's width: the bag's own (Data's "w"); no bag, two.
func pack_w() -> int:
	if _pack_holding:
		return _held_w
	var bag = equipped.get("Backpack")
	if bag == null:
		return 2
	return clampi(int(Items.base_of(bag).get("w", 5)), 1, Data.PACK_MAX_W)


## Rows the pack's cells run to.
func pack_rows() -> int:
	var w := pack_w()
	return ceili(float(capacity()) / float(w))


## A piece's footprint as it lies: turned, its sides swapped.
static func pack_fp(it: Dictionary, rot = null) -> Vector2i:
	var f := Items.footprint(it)
	var r: bool = bool(it.get("rot", false)) if rot == null else bool(rot)
	return Vector2i(f.y, f.x) if r else f


## Whether a cell is one of the pack's: inside its width and among its first capacity() cells.
static func pack_cell_in(x: int, y: int, w: int, cap: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y * w + x < cap


## The cells taken, {y * w + x: id}, by every placed piece but `skip_id`'s.
func _pack_taken(m: Dictionary, skip_id := -1) -> Dictionary:
	var w := pack_w()
	var out := {}
	for f in m["found"]:
		if not f.has("pos") or int(f["id"]) == skip_id:
			continue
		var fp := pack_fp(f)
		var px: int = int(f["pos"][0])
		var py: int = int(f["pos"][1])
		for yy in range(fp.y):
			for xx in range(fp.x):
				out[(py + yy) * w + px + xx] = int(f["id"])
	return out


## Whether `it` lies at (x, y) as `rot` says, every cell the pack's and free.
func pack_free_at(m: Dictionary, it: Dictionary, x: int, y: int, rot: bool, taken = null) -> bool:
	var w := pack_w()
	var cap := capacity()
	var tk: Dictionary = taken if taken != null else _pack_taken(m, int(it.get("id", -1)))
	var fp := pack_fp(it, rot)
	for yy in range(fp.y):
		for xx in range(fp.x):
			if not pack_cell_in(x + xx, y + yy, w, cap) or tk.has((y + yy) * w + x + xx):
				return false
	return true


## The first place `it` fits, row by row, lying as it is and then turned: [x, y, rot], or [] for none.
func pack_spot(m: Dictionary, it: Dictionary, taken = null) -> Array:
	_pack_settle(m)
	return _pack_first(m, it, taken if taken != null else _pack_taken(m, int(it.get("id", -1))))


func _pack_first(m: Dictionary, it: Dictionary, tk: Dictionary) -> Array:
	var fp := Items.footprint(it)
	var w := pack_w()
	var rows := pack_rows()
	for rot in ([false] if fp.x == fp.y else [false, true]):
		for y in range(rows):
			for x in range(w):
				if pack_free_at(m, it, x, y, rot, tk):
					return [x, y, rot]
	return []


## Into the pack at a spot from pack_spot.
func _pack_put(m: Dictionary, it: Dictionary, spot: Array) -> void:
	it["pos"] = [int(spot[0]), int(spot[1])]
	it["rot"] = bool(spot[2])
	it.erase("strapped")
	if not m["found"].has(it):
		m["found"].append(it)


## Every piece in found with no place (an old save, a forced find, one strapped on) settled: placed where it fits,
## else strapped on. A place that doesn't hold is forgotten first.
func _pack_settle(m: Dictionary) -> void:
	var key := [pack_w(), capacity()]
	if m.get("pack_key", key) != key:
		m["pack_key"] = key
		_pack_repack(m)                       # the shape changed under it (a bag, the Removal Van, a node): packed afresh
		return
	m["pack_key"] = key
	# a place that doesn't hold (a piece back in with an old "pos", a fixture): forgotten, and placed afresh below
	var held := {}
	for f in m["found"]:
		if not f.has("pos"):
			continue
		var fp := pack_fp(f)
		var ok := true                        # the pack's one screen now (28 Oct): no page edge to keep off
		for yy in range(fp.y):
			for xx in range(fp.x):
				var cx: int = int(f["pos"][0]) + xx
				var cy: int = int(f["pos"][1]) + yy
				if not pack_cell_in(cx, cy, key[0], key[1]) or held.has(cy * key[0] + cx):
					ok = false
		if not ok:
			pack_off(f)
			continue
		for yy in range(fp.y):
			for xx in range(fp.x):
				held[(int(f["pos"][1]) + yy) * key[0] + int(f["pos"][0]) + xx] = true
	for f in m["found"]:
		if f.has("pos"):
			continue
		var spot := _pack_first(m, f, _pack_taken(m, int(f["id"])))     # strapped on, tried again: room made, it goes in
		if spot.is_empty():
			f["strapped"] = true
		else:
			f["pos"] = [int(spot[0]), int(spot[1])]
			f["rot"] = bool(spot[2])
			f.erase("strapped")


## BUILD45 (2 Nov, perf44 4: a bag's preview asked the pack's size 28,000 times, each a stat read through the live memo,
## 1.2 s): `f` called with the pack's width and cells read once. Only around a packing, which moves the pieces' places
## and nothing the size is read from (the bag worn, the trees, the rules, the town).
var _pack_holding := false
var _held_cap := 0
var _held_w := 0
func held_pack(f: Callable) -> Variant:
	var was: Array = [_pack_holding, _held_cap, _held_w]     # inside another (a bag tried on): read afresh, then put back
	_pack_holding = false
	_held_cap = capacity()
	_held_w = pack_w()
	_pack_holding = true
	var v = f.call()
	_pack_holding = was[0]
	_held_cap = was[1]
	_held_w = was[2]
	return v


## Every piece placed, or strapped on, before the pack is drawn. Settled again only when the pack has moved since
## (BUILD43: a full pack's strapped pieces tried every cell each paint, 17 ms of it): a settled pack settles to itself.
var _layout_sig := 0
var _layout_m = null
var pack_settles := 0                          # for the tests: the paints that settled the pack
func pack_layout(m: Dictionary) -> void:
	if is_same(m, _layout_m) and hash([pack_w(), capacity(), m["found"]]) == _layout_sig:
		return
	pack_settles += 1
	_pack_settle(m)
	_layout_m = m
	_layout_sig = hash([pack_w(), capacity(), m["found"]])


## The player's drag: a piece in the pack to (x, y), turned or not. False when it won't lie there.
func pack_move(id: int, x: int, y: int, rot: bool) -> bool:
	if mission == null:
		return false
	_pack_settle(mission)
	for f in mission["found"]:
		if int(f["id"]) == id:
			if not pack_free_at(mission, f, x, y, rot):
				return false
			f["pos"] = [x, y]
			f["rot"] = rot
			f.erase("strapped")
			return true
	return false


## The selected piece turned a quarter where it lies (27 Oct, Matt: "when you have an item selected fullstop it can be
## rotated"): about its top-left cell; false, and it stays as it was, when the turned shape won't lie there.
func pack_turn(id: int) -> bool:
	if mission == null:
		return false
	_pack_settle(mission)
	for f in mission["found"]:
		if int(f["id"]) == id and f.has("pos"):
			var to: bool = not bool(f.get("rot", false))
			var fp := Items.footprint(f)
			if fp.x == fp.y:
				return true                    # a square turned is itself
			if not pack_free_at(mission, f, int(f["pos"][0]), int(f["pos"][1]), to):
				return false
			f["rot"] = to
			return true
	return false


## Out of the pack onto the floor, by hand: room made for something else (the floor's the run's).
func put_down(id: int) -> bool:
	if mission == null or not by_hand(mission):
		return false
	for k in range(mission["found"].size()):
		var f: Dictionary = mission["found"][k]
		if int(f["id"]) == id:
			if _stays_up(f):
				return false                     # the runner's own rounds (the gate's box too), the deeds: not left behind by a drag
			mission["found"].remove_at(k)
			pack_off(f)
			f.erase("head_drop")                 # put down by hand: left if left, as a ditched thing (1 Nov)
			mission["floor"] = mission.get("floor", [])
			mission["floor"].append(f)
			return true
	return false


## A piece out of the pack (worn, into the rig, onto the floor): its place there is forgotten (the review: a piece worn
## kept its "pos", and back in by a forced append it lay over whatever was there now).
static func pack_off(it: Dictionary) -> void:
	it.erase("pos")
	it.erase("rot")
	it.erase("strapped")
	it.erase("ditched")                       # nor is it ditched once it's off the floor (the review: a ditched mythic came home marked)


## The run's over: the pack's places are the run's, not the piece's (home, the stash lays it out).
func _pack_unmark(m: Dictionary) -> void:
	for f in m["found"]:
		pack_off(f)
		f.erase("head_drop")                  # home: no longer a head's drop to bring in
		f.erase("recovered")


## Whether every piece of `items` lies in a pack `w` across and `cap` cells, packed afresh (the biggest first): a bag
## swapped mid-run must hold what's carried.
func _pack_all_fit(items: Array, w: int, cap: int) -> bool:
	var taken := {}
	var order: Array = items.filter(func(f): return not f.get("strapped", false))
	order.sort_custom(func(a, b): return Items.size(a) > Items.size(b))
	for f in order:
		var fp0 := Items.footprint(f)
		var placed := false
		for rot in ([false] if fp0.x == fp0.y else [false, true]):
			var fp := Vector2i(fp0.y, fp0.x) if rot else fp0
			for y in range(ceili(float(cap) / float(w))):
				for x in range(w):
					if placed:
						break
					var ok := true
					for yy in range(fp.y):
						for xx in range(fp.x):
							if not pack_cell_in(x + xx, y + yy, w, cap) or taken.has((y + yy) * w + x + xx):
								ok = false
					if ok:
						for yy in range(fp.y):
							for xx in range(fp.x):
								taken[(y + yy) * w + x + xx] = true
						placed = true
		if not placed:
			return false
	return true


## The pack packed afresh, the biggest first (a bag swapped mid-run): what no longer fits is strapped on.
func _pack_repack(m: Dictionary) -> void:
	m["pack_key"] = [pack_w(), capacity()]
	for f in m["found"]:
		pack_off(f)
	var order: Array = m["found"].duplicate()
	order.sort_custom(func(a, b): return Items.size(a) > Items.size(b))
	var keep: Array = m["found"].duplicate()
	m["found"].clear()
	for f in order:
		m["found"].append(f)
		_pack_settle(m)
	m["found"].assign(keep)


# ------------------------------------------------------------------ the camp's upgrades

func rest_rate() -> float:
	var base: float = Data.REST_BASE + (Data.FX["yard/beds"] if yard_has("beds") else 0.0) + (Data.FX["yard/ward"] if yard_has("ward") else 0.0)
	return base * (Data.FX["node/second_wind"] if has_node("second_wind") else 1.0) * (1.0 + tree_sum("rest_pct") / 100.0) * (1.0 + town_stat("rest_pct") / 100.0) * (0.5 if room_half("clinic") else 1.0)     # the pumping station (18 Oct); the Clinic at half (BUILD46-S)


## The Clinic's shelf and the Fence's, by the Yard's picks.
func clinic_stock() -> int:
	var n: int = Data.CLINIC_STOCK + (Data.FX["yard/shelf"] if yard_has("shelf") else 0) + (Data.FX["yard/stockroom"] if yard_has("stockroom") else 0)
	return ceili(n / 2.0) if room_half("clinic") else n     # the vet's bag still out (BUILD46-S)


func market_stock() -> int:
	var n: int = Data.MARKET_STOCK + (Data.FX["yard/stall"] if yard_has("stall") else 0) + (Data.FX["yard/shopfront"] if yard_has("shopfront") else 0) + int(floor(town_stat("shelf")))     # the market hall (18 Oct)
	return ceili(n / 2.0) if room_half("fence") else n     # the ledger still out (BUILD46-S)


## Cash in, counted: the sinks are priced off what the Yard takes a run.
func _earn(x: float) -> void:
	cash += x
	_takings_run += x
	cash_in += x
	if issued and x > 0.0:
		circulation += x                     # the Issue: every fiat paid out is more about


## What a run on the tier pays in kills, at its depth, before the day's prices.
func run_pay(i: int) -> float:
	var t := effective(i)
	return float(t["cash"]) * float(t["pool"])


## What a run brings in, as the Yard has found it lately: the run's cash and the Fence's money for
## its loot, averaged over the last few runs, at the day's prices already. The base the endgame's sinks
## are priced off (the pass, 6 Oct): the kills' cash alone was a tenth of it, the loot is the money.
## Before any run has come home, the top open tier's kills.
func a_runs_takings() -> float:
	if takings > 0.0:
		return takings
	return run_pay(top_tier()) * inflation()


## Insurance: a share of the kit's worth, by the depth of the run.
func insure_cost(i: int) -> int:
	if has_rule("drivers_log"):
		return 0
	return int(ceil(loadout_value() * inflation() * Data.INSURE_RATE * depth[i] * (Data.FX["yard/strongroom"] if yard_has("strongroom") else 1.0) / 10.0)) * 10


func can_insure(i: int) -> bool:
	return room_open("fence") and mission == null and tier_open(i) and cash >= insure_cost(i) and loadout_value() > 0


func set_insure(on: bool) -> void:
	insure_next = on


# ------------------------------------------------------------------ the Radio: map juicing (9 Oct, docs/design/juicing.md)

## A site carries words once its ladder is open: the campaign done and depth 2 or deeper. Campaign sites are
## plain (Matt: "you don't juice campaign maps in PoE").
func juiceable(i: int) -> bool:
	return campaign_done() and tier_open(i) and int(depth[i]) >= maxi(Data.SIGNAL_DEPTH, int(Data.WORD_TIER_DEPTH[0]))     # (BUILD55-A) never a stage


## The top tier a word reaches at a depth: 0 above the first, then I, II, III.
func word_tier_cap(d: int) -> int:
	var n := 0
	for k in range(Data.WORD_TIER_DEPTH.size()):
		if d >= int(Data.WORD_TIER_DEPTH[k]):
			n = k + 1
	return n


## How many words a site carries: by its depth, one more with the map's Long wave, one more with the Yard's Long range.
func max_words(i: int) -> int:
	var n := 0
	for row in Data.WORD_MAX_DEPTH:
		if site_depth(i) >= int(row[0]):
			n = int(row[1])
	if not _sig.is_empty() and int(_sig["site"]) == i:
		n = mini(maxi(n, _sig["codes"].size()), int(signal_grade(int(_sig.get("grade", 0)))["codes"]))     # a signal's papers' codes, every one (15 Oct), to its grade's most (20 Oct)
	if n == 0:
		return 0
	return n + atlas_rank("long_wave") + (Data.FX["yard/long_range"] if yard_has("long_range") else 0)


## The book's words: the four the depths open with, every paper's read, every zone's once a site of it is
## cleared at depth 2.
func words_known() -> Array:
	var out: Array = []
	if not campaign_done():
		return out
	for w in Data.WORDS:
		if knows_word(w["name"]):
			out.append(w["name"])
	return out


func knows_word(name: String) -> bool:
	var w := Data.word_of(name)
	if w.is_empty():
		return false
	match str(w["learn"]):
		"start":
			return true
		"paper", "deep":
			return book.has(str(w["paper"]))
		"zone":
			return zone_heard(int(w["zone"]))
	return false


func zone_heard(z: int) -> bool:
	for i in Data.ZONES[z]["tiers"]:
		if int(best_depth[i]) >= maxi(Data.SIGNAL_DEPTH, int(Data.WORD_TIER_DEPTH[0])):     # (BUILD55-A) a signal's depth, not a stage's; depth 2 anywhere is a signal won there: the same on every site
			return true
	return false


## The paper's word: what reading it teaches the Radio ("" if none).
static func word_taught_by(paper: String) -> String:
	for w in Data.WORDS:
		if str(w.get("paper", "")) == paper:
			return w["name"]
	return ""


func word_names(i: int) -> Array:
	var out: Array = []
	for wd in words[i]:
		out.append(wd["w"])
	return out


## The words a site could roll now, by pool: known, not on it, not filtered (the map's Clear air), deep enough.
func _word_pools(i: int, exclude: Array) -> Dictionary:
	var pools := {"zone": [], "general": [], "deep": []}
	var z: int = int(Data.TIERS[i]["zone"])
	for name in words_known():
		if name in exclude or (name == filtered and atlas_rank("clear_air") > 0):
			continue
		var w := Data.word_of(name)
		if int(depth[i]) < int(w.get("depth", 0)):
			continue
		match str(w["learn"]):
			"zone":
				if int(w["zone"]) == z:
					pools["zone"].append(name)
			"deep":
				pools["deep"].append(name)
			_:
				pools["general"].append(name)
	return pools


## One word rolled for a site: a pool by its weight among those with anything in them, a word from it, a tier.
func _roll_word(i: int, exclude: Array) -> Dictionary:
	var pools := _word_pools(i, exclude)
	var total := 0.0
	for k in pools:
		if not pools[k].is_empty():
			total += float(Data.WORD_POOLS[k])
	if total <= 0.0:
		return {}
	var r := rng.randf() * total
	for k in ["zone", "general", "deep"]:
		if pools[k].is_empty():
			continue
		r -= float(Data.WORD_POOLS[k])
		if r <= 0.0 or k == "deep":
			var list: Array = pools[k]
			return {"w": list[rng.randi_range(0, list.size() - 1)], "t": _roll_tier(i)}
	var last: Array = pools["general"] if not pools["general"].is_empty() else (pools["zone"] if not pools["zone"].is_empty() else pools["deep"])
	return {"w": last[rng.randi_range(0, last.size() - 1)], "t": _roll_tier(i)}


## A rolled word's tier: the depth's top half the time (three in four with the map's Strong signal), a lower one
## otherwise; Strong signal's second rank lets the top go one past the depth's.
func _roll_tier(i: int) -> int:
	var cap := word_tier_cap(site_depth(i))
	if atlas_rank("strong_signal") >= 2:
		cap = mini(3, cap + 1)
	if cap <= 1:
		return maxi(cap, 1)
	var top: float = 0.75 if atlas_rank("strong_signal") >= 1 else 0.5
	if rng.randf() < top:
		return cap
	return rng.randi_range(1, cap - 1)


## The words a site rolls to fill `n` places, beside `keep`.
func _roll_words(i: int, keep: Array, n: int) -> Array:
	var out: Array = keep.duplicate(true)
	for k in range(n):
		var have: Array = []
		for wd in out:
			have.append(wd["w"])
		var wd := _roll_word(i, have)
		if wd.is_empty():
			break
		out.append(wd)
	return out


## The tier a word works at on its site now: what it rolled, held to what the depth allows (a site run shallower
## than it was juiced at works shallower); Twist's tier IV works only where III does.
func word_tier_now(i: int, t: int) -> int:
	var cap := word_tier_cap(site_depth(i))
	if atlas_rank("strong_signal") >= 2:
		cap = mini(3, cap + 1)
	if t >= 4 and cap >= 3:
		return 4
	return mini(t, cap)


## The words working on a site now, [name, tier]: its own, then the standing words (the map's Relay, the whole
## band) at the site's top tier where they aren't already on it. Nothing on a campaign site.
func active_words(i: int) -> Array:
	var out: Array = []
	if not juiceable(i):
		return out
	var names: Array = []
	for wd in words[i].slice(0, max_words(i)):   # a site run shallower than it was juiced works its first words only
		var t := word_tier_now(i, int(wd["t"]))
		if t > 0:
			out.append([wd["w"], t])
			names.append(wd["w"])
	for k in range(standing.size()):
		var sw: String = standing[k]
		if sw != "" and standing_open(k) and knows_word(sw) and not (sw in names):
			out.append([sw, maxi(1, word_tier_cap(site_depth(i)))])
			names.append(sw)
	return out


const WORD_MULT_KEYS := ["hp", "dps", "pool", "patrol", "pace", "search", "armour", "drop", "cash", "xp"]
const WORD_ADD_KEYS := ["rarity", "share", "res_add", "soaked"]

## A word at a tier, as the run reads it: its bite (halved by the Yard's Jammer) and its pay (grown by the
## Military band, the Radio's rank and the map's Booster), a multiplier as m^pow, an added figure ×pow, a count
## and a flag as they are.
func word_effect(name: String, t: int) -> Dictionary:
	var w := Data.word_of(name)
	var out := {}
	if w.is_empty():
		return out
	var pw: float = float(Data.WORD_TIER_POW[clampi(t, 1, 4) - 1])
	var jam: bool = yard_has("jammer")
	var boost: float = (Data.FX["yard/military_band"] if yard_has("military_band") else 0.0) + Data.FX["yard_rank/radio"] * yard_rank("radio") + Data.FX["atlas/booster"] * atlas_level("booster")
	for side in ["bite", "pay"]:
		var part: Dictionary = w[side]
		for k in part:
			var v = part[k]
			if k in WORD_MULT_KEYS:
				var x: float = pow(float(v), minf(pw, Data.WORD_POOL_POW_TOP) if k in Data.WORD_POOL_KEYS else pw)     # the pool and drops stop at tier II's (31 Oct)
				if side == "bite" and jam:
					x = pow(x, 0.5)
				elif side == "pay" and boost > 0.0:
					x = 1.0 + (x - 1.0) * (1.0 + boost)
				out[k] = float(out.get(k, 1.0)) * x
			elif k in WORD_ADD_KEYS:
				var a: float = float(v) * pw
				if side == "bite" and jam:
					a *= 0.5
				elif side == "pay":
					a *= 1.0 + boost
				out[k] = float(out.get(k, 0.0)) + a
			elif k == "crates":
				# a crate's weight on the site (13 Oct): a multiplier each, grown by the tier and the Radio's boost
				var cr: Dictionary = out.get("crates", {})
				for key in v:
					var x: float = pow(float(v[key]), pw)
					if boost > 0.0:
						x = 1.0 + (x - 1.0) * (1.0 + boost)
					cr[key] = float(cr.get(key, 1.0)) * x
				out["crates"] = cr
			elif k == "contact" or k == "loot_tier":
				var c: int = int(v)
				if side == "bite" and jam:
					c = int(c * 0.5)
				out[k] = int(out.get(k, 0)) + c
			else:
				out[k] = v
	return out


## A word's two halves in words, at a tier: ["HP +70%", "Finds +53%"].
func word_words(name: String, t: int) -> Array:
	var w := Data.word_of(name)
	if w.is_empty():
		return ["", ""]
	var e := word_effect(name, t)
	var bite: Array = []
	var pay: Array = []
	for k in w["bite"]:
		bite.append(_word_part(k, e, w["bite"]))
	for k in w["pay"]:
		pay.append(_word_part(k, e, w["pay"]))
	if pay.is_empty() and w["bite"].has("boss_walks"):
		pay.append("his drops every run")
	return [", ".join(bite.filter(func(x): return x != "")), ", ".join(pay.filter(func(x): return x != ""))]


func _word_part(k: String, e: Dictionary, part: Dictionary) -> String:
	var pc := func(x: float) -> String: return "%d%%" % int(round(absf(x - 1.0) * 100.0))
	match k:
		"hp":
			return "their HP +" + pc.call(e["hp"])
		"dps":
			return "their fire +" + pc.call(e["dps"])
		"pool":
			return ("gang size ×%s" % ("%.1f" % float(e["pool"])).trim_suffix(".0")) if float(e["pool"]) >= 2.0 else "gang size +" + pc.call(e["pool"])
		"patrol":
			return "gangs %s sooner" % pc.call(e["patrol"])
		"pace":
			return "pace −" + pc.call(e["pace"])
		"search":
			return "searches %s slower" % pc.call(e["search"])
		"armour":
			return "your armour −" + pc.call(e["armour"])
		"contact":
			var c: int = int(e.get("contact", 0))
			return "" if c <= 0 else ("one more on you" if c == 1 else "%d more on you" % c)
		"type":
			return "%d%% of their fire is %s" % [int(round(float(e.get("share", 0.0)) * 100.0)), str(part["type"])]
		"res":
			return "they resist %s +%d%%" % ["all" if part["res"] == "all" else str(part["res"]), int(round(float(e.get("res_add", 0.0)) * 100.0))]
		"soaked":
			return "your resist −%d%%" % int(round(float(e.get("soaked", 0.0)) * 100.0))
		"no_meds":
			return "no meds on the run"
		"no_kill_cash":
			return "no tins from kills"
		"clock_half":
			return "the clock halved"
		"boss_walks":
			return "the area's head every run, free"
		"drop":
			return "finds +" + pc.call(e["drop"])
		"cash":
			return "tins +" + pc.call(e["cash"])
		"xp":
			return "XP +" + pc.call(e["xp"])
		"rarity":
			return "loot quality +%d%%" % int(round(float(e["rarity"]) * 100.0))
		"crates":
			var bits: Array = []
			for key in e.get("crates", {}):
				var nm: String = str(crate_def(key).get("name", key)).to_lower()
				bits.append("%s%s ×%s" % [nm, "es" if nm.ends_with("x") else "s", ("%.1f" % float(e["crates"][key])).trim_suffix(".0")])
			return ", ".join(bits)
		"loot_tier":
			var n: int = int(e["loot_tier"])
			return "loot a tier up" if n == 1 else "loot %d tiers up" % n
	return ""


## What a set of words pays, roughly: cash × finds × (1 + quality) (the Yard's Two channels keeps the better).
func _words_pay(list: Array) -> float:
	var v := 1.0
	for wd in list:
		var e := word_effect(wd["w"], int(wd["t"]))
		v *= float(e.get("cash", 1.0)) * float(e.get("drop", 1.0)) * (1.0 + float(e.get("rarity", 0.0)))
	return v


## A craft's price in notes: the craft's figure × the site's depth, less the map's Good reception and the Yard's
## Scanner (Call in less the map's Early word too); Clear on a sealed site ten times over.
func word_craft_cost(i: int, key: String) -> int:
	var c := Data.craft_of(key)
	if c.is_empty():
		return 0
	var v: float = float(c["cost"]) * maxf(1.0, float(depth[i]))
	v *= (1.0 - Data.FX["atlas/good_reception"] * atlas_level("good_reception")) * (Data.FX["yard/scanner"] if yard_has("scanner") else 1.0)
	if key == "call":
		v *= 1.0 - Data.FX["atlas/early_word"] * atlas_level("early_word")
	if key == "hold" and atlas_rank("held_frequency") > 0:
		v *= Data.FX["atlas/held_frequency"]     # Held frequency (21 Oct: was "sites keep their codes when the Pitch moves", the move gone)
	if key == "clear" and sealed[i]:
		v *= Data.SEALED_CLEAR
	return maxi(1, int(ceil(v)))


## Why a craft can't be done now ("" if it can).
func word_craft_block(i: int, key: String) -> String:
	if not room_open("radio"):
		return "The Radio isn't on the air yet"     # until the Quartermaster's set (13 Oct)
	if runner_busy():
		return busy_words()                       # out, or away on a repeat (29 Oct)
	if not juiceable(i):
		return "Codes go on signals, after the campaign"
	var n: int = words[i].size()
	if sealed[i] and key != "clear":
		return "Sealed: only Clear"
	match key:
		"tune", "call":
			if n >= max_words(i):
				return "Full: %d of %d" % [n, max_words(i)]
			if key == "tune" and _word_pools(i, word_names(i)).values().all(func(l): return l.is_empty()):
				return "No more known codes to tune in"
			if key == "call" and call_options(i).is_empty():
				return "No more known codes to call in"
		"broadcast":
			if n > 0:
				return "Only on a site with no codes"
		"retune", "clear", "twist":
			if n == 0:
				return "No codes on it"
		"hold":
			if n < 2:
				return "Wants two codes"
	if notes < word_craft_cost(i, key):
		return "Short of notes"
	return ""


func can_word_craft(i: int, key: String) -> bool:
	return word_craft_block(i, key) == ""


## The words that could be called in: every one known and deep enough that isn't on the site.
func call_options(i: int) -> Array:
	var out: Array = []
	var have := word_names(i)
	for name in words_known():
		if name in have or int(depth[i]) < int(Data.word_of(name).get("depth", 0)):
			continue
		out.append(name)
	return out


## Craft a site's words: `arg` is the word for Call in and Hold.
func word_craft(i: int, key: String, arg := "") -> bool:
	if not can_word_craft(i, key):
		return false
	if key == "call" and not (arg in call_options(i)):
		return false
	if key == "hold" and not (arg in word_names(i)):
		return false
	var paid_notes := word_craft_cost(i, key)
	notes -= paid_notes
	var two: bool = yard_has("two_channels") and (key == "tune" or key == "retune")
	match key:
		"tune":
			words[i] = _better_roll(i, words[i], 1, two)
		"broadcast":
			words[i] = _roll_words(i, [], max_words(i))
		"retune":
			words[i] = _better_roll(i, [], words[i].size(), two)
		"hold":
			var kept: Array = words[i].filter(func(wd): return wd["w"] == arg)
			words[i] = _roll_words(i, kept, words[i].size() - 1)
		"call":
			words[i].append({"w": arg, "t": _roll_tier(i)})
		"clear":
			words[i] = []
			sealed[i] = false
		"twist":
			_twist(i)
	_surv_cache.erase(i)
	var c := Data.craft_of(key)
	log_event(Words.LOG["word_craft"] % [c["name"], Words.mid(tier(i)["name"]), ", ".join(word_names(i)).to_lower() if not words[i].is_empty() else "silent"])
	chron("word", {"tier": i, "craft": key, "words": word_names(i), "cost": paid_notes})
	return true


## A roll of `n` words beside `keep`, twice over with the Yard's Two channels and the better kept.
func _better_roll(i: int, keep: Array, n: int, twice: bool) -> Array:
	var a := _roll_words(i, keep, n)
	if not twice:
		return a
	var b := _roll_words(i, keep, n)
	return b if _words_pay(b) > _words_pay(a) else a


## Twist (PoE's Vaal orb): a word to tier IV, a deep word whether known or not, nothing, or every word again at
## its depth's top tier; whichever, the site is sealed. The map's Bent doubles the first.
func _twist(i: int) -> void:
	var odds: Array = Data.TWIST_ODDS.duplicate()
	if atlas_rank("bent") > 0:
		odds[0] = float(odds[0]) * 2.0
	var total := 0.0
	for o in odds:
		total += float(o)
	var r := rng.randf() * total
	var pick := 0
	while pick < odds.size() - 1 and r > float(odds[pick]):
		r -= float(odds[pick])
		pick += 1
	match pick:
		0:
			var k := rng.randi_range(0, words[i].size() - 1)
			words[i][k]["t"] = 4
			log_event(Words.LOG["twist_tier"] % str(words[i][k]["w"]).to_lower())
		1:
			var deep: Array = []
			for w in Data.WORDS:
				if w["learn"] == "deep" and not (w["name"] in word_names(i)):
					deep.append(w["name"])
			if not deep.is_empty():
				var wd := {"w": deep[rng.randi_range(0, deep.size() - 1)], "t": maxi(1, word_tier_cap(site_depth(i)))}
				if words[i].size() >= max_words(i):
					words[i][rng.randi_range(0, words[i].size() - 1)] = wd
				else:
					words[i].append(wd)
				log_event(Words.LOG["twist_air"] % str(wd["w"]).to_lower())
		2:
			log_event(Words.LOG["twist_none"])
		3:
			var cap := maxi(1, word_tier_cap(site_depth(i)))
			var n: int = words[i].size()
			words[i] = _roll_words(i, [], n)
			for wd in words[i]:
				wd["t"] = cap
			log_event(Words.LOG["twist_all"] % Data.WORD_TIER_NAMES[cap - 1])
	sealed[i] = true


## The standing words (the map's Relay, the whole band): one slot a node.
func standing_open(k: int) -> bool:
	return atlas_rank("relay") > 0 if k == 0 else atlas_rank("whole_band") > 0


func set_standing(k: int, name: String) -> bool:
	if k < 0 or k > 1 or not standing_open(k) or (name != "" and not knows_word(name)):
		return false
	while standing.size() <= k:
		standing.append("")
	standing[k] = name
	_surv_cache = {}
	return true


## The map's Clear air: one known word the Radio never rolls.
func set_filtered(name: String) -> bool:
	if atlas_rank("clear_air") <= 0 or (name != "" and not knows_word(name)):
		return false
	filtered = name
	return true


# ------------------------------------------------------------------ the Yard's lanes (9 Oct, docs/design/yard.md)

## Whether a pick is built: the set of the built ones, worked out again whenever the picks change.
var _yard_set := {}
var _yard_dirty := true
func yard_has(id: String) -> bool:
	if _yard_dirty:
		_yard_set = {}
		for b in Data.YARD:
			var sides: Array = yard_picks.get(b["key"], [])
			for c in range(mini(sides.size(), b["picks"].size())):
				var sd: String = str(sides[c])
				if sd.contains("a"):
					_yard_set[b["picks"][c][0]["id"]] = true
				if sd.contains("b"):
					_yard_set[b["picks"][c][1]["id"]] = true     # both sides built (24 Oct, option B)
		_yard_dirty = false
	return _yard_set.has(id)


func yard_rank(key: String) -> int:
	return int(yard_ranks.get(key, 0))


## The sides built in a building's column: "a", "b", "ab" (both, 24 Oct: option B) or "".
func yard_side(key: String, col: int) -> String:
	var sides: Array = yard_picks.get(key, [])
	return str(sides[col]) if col < sides.size() else ""


## How many picks are built: both sides of a column count (24 Oct, option B; the record and the balance read it).
func yard_built() -> int:
	var n := 0
	for b in Data.YARD:
		for c in range(b["picks"].size()):
			n += yard_side(b["key"], c).length()
	return n


## The deepest a site has been held, this Yard or one before: the depth columns read it.
func deepest_dug() -> int:
	var d := 0
	for i in range(Data.OUTSKIRTS_SITES, depth.size()):     # from the Streets (12 Oct): the Outskirts' depths are cheap
		d = maxi(d, dug_depth(i))             # the depth held, not the one the selector is on
	if best_dig.has("tier"):
		d = maxi(d, tier_depth(lv_at(int(best_dig["tier"]), int(best_dig.get("depth", 0)))))
	else:
		d = maxi(d, int(best_dig.get("depth", 0)))     # a record without its site reads as it was written
	return d


## A site's deepest clear as the Barracks' depth at its level (D15 review): signals land on any site, so what a depth
## opens (the Yard's columns, a zone's salvage and codes) reads the level, not which site a signal fell on.
func dug_depth(i: int) -> int:
	if int(best_depth[i]) <= 0:
		return 0
	return tier_depth(lv_at(i, int(best_depth[i]))) if int(best_depth[i]) >= Data.SIGNAL_DEPTH else 1     # (BUILD55-A) a stage digs nothing


## The deepest site's level (its tier and its depth): the Gunsmith's and the Arms dealer's.
## The deepest level among the sites cleared (D6, the gamble's gate: the next zone's first site, open and not yet
## cleared, put the gamble a level past every drop the runner had seen).
## What a site of level `lv` pays you (D9, 15 Oct, Matt: "fall off past 5 levels"): whole up to OVER_LEVEL_FREE site levels
## under you, OVER_LEVEL_STEP less a level past that, never under OVER_LEVEL_FLOOR. In the campaign, your level against
## the level the site's gear wants (25 Oct; D12's clamp to the deepest clear is gone); after it, the item level you wear
## at against the site's.
func over_level_share(lv: int) -> float:
	var beyond: float
	if not campaign_done():
		# the campaign: your level against the level its gear wants (Matt, 25 Oct, the second review: the D12 clamp paid every
		# frontier run whole, so OVER_LEVEL_FREE never bit; read in item levels it fell off a cliff at WEAR_FLAT)
		beyond = float(level() - Items.wear_for(lv)) - Data.OVER_LEVEL_FREE
	else:
		var mine: float = float(mini(Items.max_ilvl_for(level()), Data.MAX_LEVEL))     # the item level you wear at (21 Oct: past WEAR_FLAT, your level)
		beyond = mine - float(lv) - Data.OVER_LEVEL_FREE
	return clampf(1.0 - Data.OVER_LEVEL_STEP * maxf(0.0, beyond), Data.OVER_LEVEL_FLOOR, 1.0)


func deepest_cleared_level() -> int:
	var lv := 1
	for i in range(depth.size()):
		if int(best_depth[i]) > 0:
			lv = maxi(lv, lv_at(i, int(best_depth[i])))
	return lv


func deepest_site_level() -> int:
	var lv := 1
	for i in range(depth.size()):
		if tier_open(i):
			lv = maxi(lv, lv_at(i, maxi(1, int(best_depth[i]))))
	return lv


## The columns the campaign and the depth have opened, kept for good (a move closes none).
func yard_cols() -> int:
	var n := 1
	if zone_open(2):                         # the Town (zones moved up one with the Outskirts, 12 Oct)
		n = 2
	if zone_open(3):                         # the City
		n = 3
	if campaign_done():
		n = 4
	if deepest_dug() >= Data.YARD_GATE_DEPTHS[4]:
		n = 5
	if deepest_dug() >= Data.YARD_GATE_DEPTHS[5]:
		n = 6
	yard_open = maxi(yard_open, n)
	return yard_open


## Whether this side of a column is built.
func yard_built_side(key: String, col: int, side: String) -> bool:
	return side != "" and yard_side(key, col).contains(side)


## A column's next price: the building's figure at today's prices; its other side, once one is built, YARD_SECOND of it.
func yard_pick_cost(key: String, col: int) -> int:
	var b := Data.yard_building(key)
	if b.is_empty() or col < 0 or col >= b["costs"].size():
		return -1
	var c: int = _inf(int(b["costs"][col])) * (2 if room_half("yard") else 1)     # the deeds still out: double (BUILD46-S)
	return _round_price(int(round(c * Data.YARD_SECOND)) if yard_side(key, col) != "" else c)


## The salvage a column wants: the fifth's, YARD_PICK_SALVAGE of the building's kind, for each side.
func yard_pick_salvage(key: String, col: int) -> int:
	return Data.YARD_PICK_SALVAGE if col == 4 and yard_side(key, col).length() < 2 else 0


## Why a pick can't be built now, or "": the column shut, built already, the cash or the salvage short.
func yard_pick_block(key: String, col: int, side: String) -> String:
	var b := Data.yard_building(key)
	if b.is_empty() or col < 0 or col >= b["picks"].size() or not (side in ["a", "b"]):
		return "no such upgrade"
	if not room_open("yard"):
		return "The Yard opens with the Manager's deeds"     # until the Manager's deeds (13 Oct)
	if not room_open(building_room(key)):
		return "Opens with %s" % Words.GATES["shut"][building_room(key)]     # a building for a shut room waits on it
	if mission != null:
		return "The runner is out"
	if yard_stub(key, col, side):
		return Words.REPEAT["stub"]                  # the Bunkhouse's line B (29 Oct): after the Quartermaster
	if col >= yard_cols():
		return Data.yard_gate(col)
	if yard_built_side(key, col, side):
		return "Built"
	if col > 0 and not yard_built_side(key, col - 1, side):
		return "After %s" % str(b["picks"][col - 1][0 if side == "a" else 1]["name"])     # a line climbs in order (28 Oct, two lines a building)
	if cash < yard_pick_cost(key, col):
		return "Short of " + money_word()
	if int(salvage.get(b["salvage"], 0)) < yard_pick_salvage(key, col):
		return "Wants %d %s" % [yard_pick_salvage(key, col), Data.SALVAGE_NAMES[b["salvage"]].to_lower()]
	return ""


func can_yard_pick(key: String, col: int, side: String) -> bool:
	return yard_pick_block(key, col, side) == ""


## Build a pick: the column's first side at its price, the other later at YARD_SECOND of it (nothing locks, 24 Oct).
func yard_pick(key: String, col: int, side: String) -> bool:
	if not can_yard_pick(key, col, side):
		return false
	var b := Data.yard_building(key)
	var second: bool = yard_side(key, col) != ""
	var pk0: Dictionary = b["picks"][col][0 if side == "a" else 1]
	chron("yard", {"key": key, "col": col, "side": side, "name": str(pk0["name"]), "cost": yard_pick_cost(key, col), "salvage": yard_pick_salvage(key, col), "second": second})
	cash -= yard_pick_cost(key, col)
	salvage[b["salvage"]] = int(salvage.get(b["salvage"], 0)) - yard_pick_salvage(key, col)
	var sides: Array = yard_picks.get(key, ["", "", "", "", ""]).duplicate()
	while sides.size() < b["picks"].size():
		sides.append("")
	sides[col] = "ab" if second else side
	var before := _yard_before()
	yard_picks[key] = sides
	_stats_dirty()
	_yard_changed(key)
	_yard_grew(before)
	var pk: Dictionary = b["picks"][col][0 if side == "a" else 1]
	log_event(Words.LOG["yard_built"] % [b["name"], "%s - %s" % [pk["name"], _first_lower(str(pk["words"]))]])     # the first letter only: "XP" stays (the language pass)
	return true


## A rank's price: YARD_RANK_CASH × YARD_RANK_GROWTH a rank bought, at today's prices; salvage, one more a rank.
func yard_rank_cost(key: String) -> int:
	return _round_price(_inf(int(round(Data.YARD_RANK_CASH * pow(Data.YARD_RANK_GROWTH, yard_rank(key))))) * (2 if room_half("yard") else 1))     # the deeds still out (BUILD46-S)


## A Pitch price, rounded (20 Oct, Matt's video: prices climbing a few tins with the clock read as a click raising
## them): to the hundred from a thousand, the thousand from a hundred thousand, so they move in steps, seldom.
static func _round_price(x: int) -> int:
	if x >= 100000:
		return int(round(x / 1000.0)) * 1000
	if x >= 1000:
		return int(round(x / 100.0)) * 100
	return x


func yard_rank_salvage(key: String) -> int:
	return Data.YARD_RANK_SALVAGE + yard_rank(key) if yard_rank(key) < Data.YARD_RANK_SALVAGE_TO else 0     # past the fifth, tins alone (24 Oct)


func yard_rank_block(key: String) -> String:
	var b := Data.yard_building(key)
	if b.is_empty():
		return "no such building"
	if not room_open("yard"):
		return "The Yard opens with the Manager's deeds"
	if not room_open(building_room(key)):
		return "Opens with %s" % Words.GATES["shut"][building_room(key)]
	if mission != null:
		return "The runner is out"
	if yard_cols() < Data.YARD_COLS:
		return Data.yard_gate(Data.YARD_COLS - 1)
	if not (yard_built_side(key, 4, "a") or yard_built_side(key, 4, "b")):
		return "After a line's fifth step"            # ranks once either line is done (28 Oct, two lines a building)
	if cash < yard_rank_cost(key):
		return "Short of " + money_word()
	if int(salvage.get(b["salvage"], 0)) < yard_rank_salvage(key):
		return "Wants %d %s" % [yard_rank_salvage(key), Data.SALVAGE_NAMES[b["salvage"]].to_lower()]
	return ""


func can_yard_rank(key: String) -> bool:
	return yard_rank_block(key) == ""


func buy_yard_rank(key: String) -> bool:
	if not can_yard_rank(key):
		return false
	var b := Data.yard_building(key)
	chron("yard_rank", {"key": key, "rank": yard_rank(key) + 1, "cost": yard_rank_cost(key), "salvage": yard_rank_salvage(key)})
	cash -= yard_rank_cost(key)
	salvage[b["salvage"]] = int(salvage.get(b["salvage"], 0)) - yard_rank_salvage(key)
	yard_ranks[key] = yard_rank(key) + 1
	_stats_dirty()
	_yard_changed(key)
	log_event(Words.LOG["yard_rank"] % [b["name"], yard_rank(key), _first_lower(str(b["rank"]["words"]))])
	return true


## Setting off: the Generator's Charger (full HP) and the Clinic's Field kit (a bandage in the rig, if there's room).
func _yard_setting_off() -> void:
	if yard_has("charger"):
		hp = max_hp()
	if yard_has("field_kit") and rig_room(1) and not has_rule("the_float"):     # the Float carries no meds (18 Oct)
		rig.append(_plain(Data.MEDICAL, "Bandage"))


## What's buyable now, by id: an open column with nothing built ("key/col"), a rank ("key/rN", N the next).
## The runner being out doesn't count (the reviewer's catch: a Yard looked at mid-run marked nothing seen).
func _yard_buyable_ids() -> Array:
	var out: Array = []
	var cols: int = yard_cols()               # once (BUILD45): asked a pick, 148 times a refresh on a late save
	for b in Data.YARD:
		var have: int = int(salvage.get(b["salvage"], 0))
		for c in range(b["picks"].size()):
			var next_side: bool = ["a", "b"].any(func(sd): return not yard_built_side(b["key"], c, sd) and (c == 0 or yard_built_side(b["key"], c - 1, sd)))     # a line's next step (28 Oct)
			if c < cols and next_side and cash >= yard_pick_cost(b["key"], c) and have >= yard_pick_salvage(b["key"], c):
				out.append("%s/%d%s" % [b["key"], c, "" if yard_side(b["key"], c) == "" else "+"])     # "+": its other side (option B)
		if cols >= Data.YARD_COLS and (yard_built_side(b["key"], 4, "a") or yard_built_side(b["key"], 4, "b")) and cash >= yard_rank_cost(b["key"]) and have >= yard_rank_salvage(b["key"]):
			out.append("%s/r%d" % [b["key"], yard_rank(b["key"]) + 1])
	return out


## The rail's badge (Matt, 9 Oct: lit nearly always, so it was ignored): only for news - a column opened since
## the Yard was last looked at, or something buyable that wasn't when it was. Looking clears it.
func yard_news() -> bool:
	var cols: int = yard_cols()
	if cols > yard_seen_cols:
		return true
	# _yard_buyable_ids' list, each id's price read only when it's one not yet seen (BUILD43: the rail read every price
	# and every column's count ten times a second, 1.2 ms a paint): true for the same ids
	for b in Data.YARD:
		var have: int = int(salvage.get(b["salvage"], 0))
		for c in range(mini(cols, b["picks"].size())):
			if yard_side(b["key"], c) != "" or yard_seen.has("%s/%d" % [b["key"], c]):
				continue                       # a column's other side lights nothing (the review: every first side built would)
			var next_side: bool = ["a", "b"].any(func(sd): return not yard_built_side(b["key"], c, sd) and (c == 0 or yard_built_side(b["key"], c - 1, sd)))     # a line's next step (28 Oct)
			if next_side and cash >= yard_pick_cost(b["key"], c) and have >= yard_pick_salvage(b["key"], c):
				return true
		if cols >= Data.YARD_COLS and (yard_built_side(b["key"], 4, "a") or yard_built_side(b["key"], 4, "b")) and not yard_seen.has("%s/r%d" % [b["key"], yard_rank(b["key"]) + 1]) \
				and cash >= yard_rank_cost(b["key"]) and have >= yard_rank_salvage(b["key"]):
			return true
	return false


func yard_mark_seen() -> void:
	yard_seen_cols = yard_cols()
	for id in _yard_buyable_ids():
		yard_seen[id] = true


## What a pick changed: the figures read fresh; the Fence's and the Clinic's shelves and the odds again.
func _yard_changed(_key: String) -> void:
	_yard_dirty = true
	_dry_memo.clear()
	_stats_dirty()
	_surv_cache = {}                          # the odds read the Yard too: the Jammer, the Med lab, the Charger
	if not yard_has("dry_store"):
		# the Dry store gone (a guard: no refit takes a pick away since 24 Oct, option B; a fixture can): its second tabs fold into the first, the class out's and the crew's
		for it in stash:
			if tab_of(it) == "own2":
				it["tab"] = "own"
		for k in roster:
			for it in roster[k].get("tab_items", []):
				if tab_of(it) == "own2":
					it["tab"] = "own"


## What a pick or a refit might grow or shrink, read before it's built: the Fence's shelf, the Back room, Pin.
func _yard_before() -> Dictionary:
	return {"stock": market_stock(), "back": yard_has("back_room")}


## A pick that grows a shelf adds only what it grew by - never a re-roll or a refill of what's
## there (the reviewers' catches: a Fence pick re-rolled every site's words, and any build refilled a shelf the
## player had bought from). A refit away shrinks them back: Pin's pins.
func _yard_grew(before: Dictionary) -> void:
	var add: int = market_stock() - int(before["stock"])
	if add > 0:
		var have: Array = market
		_restock_market()
		var fresh: Array = market.filter(func(x): return not x.has("unique"))
		market = have + fresh.slice(0, add)
	if yard_has("back_room") and not bool(before["back"]) and not market.any(func(x): return x.has("unique")):
		var bu := pick_unique(loose_uniques(0), shop_unique_tier(), true)
		if not bu.is_empty():
			market.append(Items.roll_unique(bu, rng, gamble_level(), shop_unique_tier()))


## The Kennel's quality; the gangs' lateness from the Kennel and the Lookout; the odds' dry runs; the sales.
func yard_quality() -> float:
	return (Data.FX["yard/good_nose"] if yard_has("good_nose") else 0.0) + (Data.FX["yard/pedigree"] if yard_has("pedigree") else 0.0) + (Data.FX["yard/champion"] if yard_has("champion") else 0.0) + Data.FX["yard_rank/kennel"] * yard_rank("kennel")


func yard_patrol() -> float:
	return (Data.FX["yard/guard_dog"] if yard_has("guard_dog") else 1.0) * (Data.FX["yard/tripwires"] if yard_has("tripwires") else 1.0) * (Data.FX["yard/watch_rota"] if yard_has("watch_rota") and is_night() else 1.0) \
		* (Data.FX["yard/crows_nest"] if yard_has("crows_nest") else 1.0) * (1.0 + Data.FX["yard_rank/lookout"] * yard_rank("lookout"))


func odds_runs() -> int:
	return Data.FX["yard/glasses"] if yard_has("glasses") else Data.ODDS_RUNS


func yard_sell_pct() -> float:
	return (Data.FX["yard/haggling"] if yard_has("haggling") else 0.0) + (Data.FX["yard/dealers_cut"] if yard_has("dealers_cut") else 0.0) + Data.FX["yard_rank/fence"] * yard_rank("fence")


## The Yard's lanes from a save; a save from before them maps its buildings' levels onto the picks that match,
## free (docs/design/yard.md §5).
func _load_yard(d: Dictionary) -> void:
	yard_picks = d.get("yard_picks", {}).duplicate(true)
	yard_ranks = d.get("yard_ranks", {}).duplicate()
	yard_open = int(d.get("yard_open", 1))
	yard_seen = {}
	for id in d.get("yard_seen", []):
		yard_seen[str(id)] = true
	yard_seen_cols = int(d.get("yard_seen_cols", yard_open))     # a save from before the badge: its columns aren't news
	salvage = {"copper": 0, "steel": 0, "army": 0}
	var sv: Dictionary = d.get("salvage", {})
	for k in sv:
		salvage[k] = int(sv[k])
	_yard_dirty = true


# ------------------------------------------------------------------ the workshop

## Every mount from the start (9 Oct: the Bench's levels went; crafting is open from the first minute).
func mount_open(_mount: String) -> bool:
	return true


func socket_max(it: Dictionary = {}) -> int:
	return Items.socket_cap(it, Data.FX["yard/third_socket"] if yard_has("third_socket") else 0)     # an improvised gun's one more (29 Oct)


func bump_cap() -> int:
	return Data.BUMP_CAP + yard_rank("bench")


func bump_levels() -> int:
	return Data.BUMP_LEVELS * (Data.FX["yard/overbump"] if yard_has("overbump") else 1)


## Why a stash attachment cannot go on a fitted gun's mount: "" when it can.
## A part made for a type (a choke, a bipod) is refused on any other gun (Matt, 6 Oct), not fitted for nothing.
func fit_refusal(slot: String, id: int) -> String:
	if runner_busy():
		return "The runner is out" if mission != null else Words.REPEAT["shut_away"]
	if equipped[slot] == null:
		return "Nothing fitted as %s" % slot.to_lower()
	var gun: Dictionary = equipped[slot]
	for it in stash:
		if it["id"] == id and Items.is_attachment(it):
			if it["mount"] == "socket":
				return ""
			if not gun["attachments"].has(it["mount"]):
				return "The %s has no %s mount" % [gun["base"].to_lower(), it["mount"]]
			if not mount_open(it["mount"]):
				return "Needs a bigger Bench: built on the Pitch"
			if not Items.att_fits(it, str(Items.base_of(gun).get("type", ""))):
				return Items.only_words(it)
			return ""
	return "Not in the stash"


func can_fit(slot: String, id: int) -> bool:
	return fit_refusal(slot, id) == ""


## A stash attachment onto a fitted gun's mount. What was there goes to the stash.
func fit(slot: String, id: int) -> bool:
	if not can_fit(slot, id):
		return false
	var gun: Dictionary = equipped[slot]
	for it in stash:
		if it["id"] == id and Items.is_attachment(it):
			var mount: String = it["mount"]
			if mount == "socket":
				# any socket, the first empty one or the one named
				mount = ""
				for key in gun["attachments"]:
					if str(key).begins_with("socket") and (mount == "" or gun["attachments"][key] == null):
						mount = key
						if gun["attachments"][key] == null:
							break
				if mount == "":
					return false
			if not gun["attachments"].has(mount) or not mount_open(mount):
				return false
			var going: Dictionary = _one_off(it)
			if gun["attachments"][mount] != null:
				stash_put(gun["attachments"][mount])
			gun["attachments"][mount] = going
			_stats_dirty()
			return true
	return false


## One off a stack in the stash (a bottle from the bottles), or the item itself.
func _one_off(it: Dictionary) -> Dictionary:
	if Items.stacks(it) and Items.stack_size(it) > 1:
		Items.set_stack(it, Items.stack_size(it) - 1)
		var one: Dictionary = Items.one_of(it)
		one.erase("tab")                     # the piece leaves the stash; stashed again it goes to the shared tab
		return one
	_remove(it)
	return it


## A socketable into a named socket of a fitted item.
func fit_socket(slot: String, mount: String, id: int) -> bool:
	if runner_busy() or not Data.SLOTS.has(slot) or equipped[slot] == null or not mount.begins_with("socket"):
		return false
	var it_at: Dictionary = equipped[slot]
	if not it_at["attachments"].has(mount) or not mount_open(mount):
		return false
	for it in stash:
		if it["id"] == id and Items.is_socketable(it):
			var going: Dictionary = _one_off(it)
			if it_at["attachments"][mount] != null:
				stash_put(it_at["attachments"][mount])
			it_at["attachments"][mount] = going
			_stats_dirty()
			return true
	return false


func strip(slot: String, mount: String) -> bool:
	if runner_busy() or equipped[slot] == null:
		return false
	var gun: Dictionary = equipped[slot]
	if gun["attachments"].get(mount, null) == null:
		return false
	if not (stash_fits(gun["attachments"][mount]) or _stack_room(gun["attachments"][mount])):
		return false
	stash_put(gun["attachments"][mount])
	gun["attachments"][mount] = null
	_stats_dirty()
	return true


## Every part off a worn piece at once (28 Oct, Matt: "no way to strip everything off a weapon at once"): each
## attachment and socketable back to the stash as room allows, free as one is. [taken off, left on for want of room].
func strip_all(slot: String) -> Array:
	if runner_busy() or equipped.get(slot) == null:
		return [0, 0]
	var off := 0
	var left := 0
	for mount in Dictionary(equipped[slot].get("attachments", {})).keys():
		if equipped[slot]["attachments"][mount] == null:
			continue
		if strip(slot, str(mount)):
			off += 1
		else:
			left += 1
	if off > 0:
		log_event(Words.LOG["stripped"] % [str(equipped[slot]["base"]).to_lower(), off, "" if off == 1 else "s", (", %d left on: no room" % left) if left > 0 else ""])
	return [off, left]


## Strip all can take one off now (28 Oct, the review: live with the stash full, then nothing): not on a run, and a part
## on the piece the stash has room for.
func can_strip_any(slot: String) -> bool:
	if runner_busy() or equipped.get(slot) == null:     # as strip_all (T4): not lit between a repeat's runs
		return false
	return Dictionary(equipped[slot].get("attachments", {})).values().any(func(a): return a != null and (stash_fits(a) or _stack_room(a)))


## The parts on a worn piece.
func parts_on(slot: String) -> int:
	if equipped.get(slot) == null:
		return 0
	return Dictionary(equipped[slot].get("attachments", {})).values().filter(func(a): return a != null).size()


## The stash's attachments that go on this mount, best first.
## The stash's parts for a mount, best first; `gun_type` given, only the ones that go on that type of gun.
func attachments_for(mount: String, gun_type_v := "") -> Array:
	var scored: Array = []                # [score, item]: the score read once a part, not once a comparison (22 Oct, the pass's wall)
	for it in stash:
		if Items.is_attachment(it) and (it["mount"] == mount or (mount.begins_with("socket") and it["mount"] == "socket")):
			if gun_type_v == "" or Items.att_fits(it, gun_type_v):
				scored.append([Items.score(it), it])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	var out: Array = []
	for p in scored:
		out.append(p[1])
	return out


## HP a second back from the kit and the web's fillers (22 Oct).
func regen_rate() -> float:
	return _affix_sum("regen") + tree_sum("regen")


func _affix_sum(stat: String) -> float:
	return _memo("_affix_sum/" + stat, __affix_sum_raw.bind(stat))


func __affix_sum_raw(stat: String) -> float:
	var base: float = float(_base_stat_index().get(stat, 0.0))     # the bases' built-in figures (29 Oct, the roles): never an affix, so the plaque leaves them
	if stat != "all_res" and has_rule("blue_plaque"):
		return base                              # a Blue Plaque: no other affix on you counts
	return float(_affix_index().get(stat, 0.0)) + base


## The worn bases' built-in figures by stat (29 Oct, docs/design/itemisation.md §2: a role a base, a built-in figure).
func _base_stat_index() -> Dictionary:
	return _memo("base_stat_index", _base_stat_index_raw)


func _base_stat_index_raw() -> Dictionary:
	var out := {}
	for s in Data.SLOTS:
		if equipped[s] != null:
			var st: Dictionary = Items.base_of(equipped[s]).get("stats", {})
			for k in st:
				out[k] = float(out.get(k, 0.0)) + float(st[k])
	return out


## Every worn affix and set bonus added up by stat in one walk of the kit, memoised with the rest (22 Oct, the pass's
## wall: a try-on asked thirty stats, each a walk of the six pieces) - as Items.affix_total and set_stat add them.
func _affix_index() -> Dictionary:
	return _memo("affix_index", _affix_index_raw)


func _affix_index_raw() -> Dictionary:
	var out := {}
	for s in Data.SLOTS:
		if equipped[s] != null:
			for a in equipped[s]["affixes"]:
				out[a["stat"]] = float(out.get(a["stat"], 0.0)) + float(a["value"])
	for b in set_bonuses():
		for st in b.get("stats", {}):
			out[st] = float(out.get(st, 0.0)) + float(b["stats"][st])
	return out


# ------------------------------------------------------------------ sets
## How many of a set are worn; its bonuses at two and at the full set.
func set_count(name: String) -> int:
	var n := 0
	for s in Data.SLOTS:
		if equipped[s] != null and equipped[s].get("set", "") == name:
			n += 1
	if n == 0:
		return 0
	# issued kit counts as a piece of the set you're wearing, in a slot the set has a piece for (Matt, 26 Oct: a broken
	# build wears the Issuer's kit too) - one set a piece: the one with the most real pieces on, by name on a tie (the review)
	for pc in Items.set_named(name).get("pieces", []):
		var sl: String = str(pc["slot"])
		var it = equipped.get(sl)
		if it != null and it.get("issued", false) and _issued_set_for(sl) == name:
			n += 1
	return n


## How many of a set's worn pieces are issued kit counted in (the Kit's set line says so).
func set_issued(name: String) -> int:
	var n := 0
	if set_count(name) == 0:
		return 0
	for pc in Items.set_named(name).get("pieces", []):
		var sl: String = str(pc["slot"])
		var it = equipped.get(sl)
		if it != null and it.get("issued", false) and _issued_set_for(sl) == name:
			n += 1
	return n


## The set an issued piece in `slot` counts for: of the sets with a piece for that slot and a real piece worn, the one
## with the most real pieces on (by name on a tie); "" for none.
func _issued_set_for(slot: String) -> String:
	var best := ""
	var best_n := 0
	for st in Data.SETS:
		if not st["pieces"].any(func(pc): return str(pc["slot"]) == slot):
			continue
		var real := 0
		for s in Data.SLOTS:
			if equipped[s] != null and equipped[s].get("set", "") == st["name"]:
				real += 1
		if real > best_n or (real == best_n and real > 0 and str(st["name"]) < best):
			best = str(st["name"])
			best_n = real
	return best


## The set bonuses in force: every threshold at or under the count.
func set_bonuses() -> Array:
	return _memo("set_bonuses", _set_bonuses_raw)     # read by contact() twice a tick, and the sums (A4)


func _set_bonuses_raw() -> Array:
	var out: Array = []
	for st in Data.SETS:
		var n := set_count(st["name"])
		for k in st["bonuses"]:
			if n >= int(k):
				out.append(st["bonuses"][k])
	return out


func set_stat(stat: String) -> float:
	var t := 0.0
	for b in set_bonuses():
		t += float(b.get("stats", {}).get(stat, 0.0))
	return t


func has_set_rule(rule: String) -> bool:
	for b in set_bonuses():
		if b.get("rule", "") == rule:
			return true
	return false


## A broken build (21 Oct, Data.COMBOS): the class, its set at its count, the unique's rule, both nodes. Outside the
## balance passes, as the mythics: the balance read can switch them off.
static var combos_off := false
static var exploits_off := false     # the balance reads: an exploit never meets a read (Matt, 27 Oct)
## A watched run's event asks (1 Nov): the shell on screen sets it (main.gd as the game's own scene). Off, as in every
## harness, the bot and the reads, an event goes by the standing orders the moment it comes, as on a repeat run.
static var asks := false


## An exploit on (Data.EXPLOITS): the class, its two nodes trained, its unique's rule worn.
func exploit_on(key: String) -> bool:
	if exploits_off or not Data.EXPLOITS.has(key):
		return false
	return _memo("exploit/" + key, _exploit_raw.bind(key))


func _exploit_raw(key: String) -> bool:
	var x: Dictionary = Data.EXPLOITS[key]
	if cls != str(x["class"]) or not has_rule(str(x["rule"])):
		return false
	for path in x["nodes"]:
		if not (Data.node_id_named(str(path)) in tree):
			return false
	return true


## The run's exploit figure: what every hit is multiplied by, 1 with none (First of many, Last orders again, Never trips).
static func exploit_x(m: Dictionary) -> float:
	return float(m.get("ex_x", 1.0))


func _exploit_grow(m: Dictionary, key: String, times := 1.0) -> void:
	m["ex_x"] = minf(Data.COMBO_CEILING, exploit_x(m) * pow(float(Data.EXPLOITS[key]["grow"]), times))


func combo_on(key: String) -> bool:
	if combos_off or not Data.COMBOS.has(key):
		return false
	return _memo("combo/" + key, _combo_raw.bind(key))


func _combo_raw(key: String) -> bool:
	var c: Dictionary = Data.COMBOS[key]
	if cls != str(c["class"]) or set_count(str(c["set"])) < int(c["pieces"]) or not has_rule(str(c["rule"])):
		return false
	for n in c["nodes"]:
		if not has_node(str(n)):
			return false
	return true


## A pinnacle build's defensive half (Matt, 27 Oct, docs/design/pinnacle_and_exploits.md): its stacks also take
## COMBO_GUARD_STEP a stack off their fire, to COMBO_GUARD_CAP, so the loop keeps the runner standing. 1.0 with none on.
func combo_guard(m: Dictionary) -> float:
	if combo_stacks(m) <= 0.0 or not Data.COMBOS.keys().any(func(k): return combo_on(str(k))):
		return 1.0
	return 1.0 - minf(Data.COMBO_GUARD_CAP, Data.COMBO_GUARD_STEP * combo_stacks(m))


## A pinnacle build's warm start (Matt, 27 Oct, the gauntlet: a kill-stack build died before its stacks came against the
## County's twenty-man crews): every run opens with COMBO_WARM stacks. The key of the build on, "" for none.
func _combo_warm(m: Dictionary) -> String:
	for k in Data.COMBOS:
		if combo_on(str(k)):
			m["combo"] = maxf(float(m.get("combo", 0.0)), Data.COMBO_WARM)
			return str(k)
	return ""


## A run's stacks of the build on, and a stack's worth.
static func combo_stacks(m: Dictionary) -> float:
	return float(m.get("combo", 0.0))


static func combo_step(key: String) -> float:
	return float(Data.COMBOS[key]["step"])


func _combo_stack(m: Dictionary, key: String, n := 1.0) -> void:
	if combo_stacks(m) <= 0.0 and not m.get("dry", false):
		log_event(Words.COMBOS[key])          # once a run: something's catching, never what
	m["combo"] = minf(Data.COMBO_CEILING, combo_stacks(m) + n)


## The sets that can turn up at a depth.
func set_pieces_at(at_depth: int) -> Array:
	var out: Array = []
	for st in Data.SETS:
		if int(st.get("depth", 0)) <= at_depth:
			for p in st["pieces"]:
				out.append([st["name"], p])
	return out


func loadout_value() -> int:
	var v := 0
	for s in Data.SLOTS:
		if equipped[s] != null:
			v += equipped[s]["value"]              # its base worth: insurance is priced on it (the review: by item level it outgrew a deep run's takings)
	for it in rig:
		v += it["value"]
	return v


# ------------------------------------------------------------------ the mission
##
## A mission has two phases. The fight: the tier's pool of hostiles, one at a
## time, both sides' damage swinging ±VARIANCE a second. The clear ends the
## fight and starts the search: every SEARCH_S a cache gives up an item, and
## every PATROL_S a patrol arrives, each bigger than the last, which has to be
## fought before searching goes on. Extract any time; KIA at zero HP.

const VARIANCE := 0.25
const SKILL_CAST_EVERY := 0.25         # a tick this long or longer can cast another skill (the bot's 1 s, the odds' 2 s)
const CONTACT := 3                 # hostiles firing at once; the rest wait their turn
const SEARCH_S := 20.0             # 15 to 20 (21 Oct, the tuning batch): a search is a beat
const PATROL_S := 24.0          # D6 (gate 10): 20 left 1.6-1.9 searches a gap on the early sites
const PATROL_BASE := 2
const SURVIVAL_RUNS := 40
var _surv_cache := {}              # tier -> [key, odds]


func tier(i: int) -> Dictionary:
	return Data.TIERS[i]


## A zone opens when the one before it is complete: its sites cleared and
## its boss beaten. All three complete is the campaign done, and the depth
## ladder and the radio's call-in open with it.
func zone_open(z: int) -> bool:
	return z == 0 or (zone_complete(z - 1) and not zone_level_shut(z))


## The level a zone opens at (19 Oct, Matt: "keep a zone locked until the level cap is hit"): its first site's gate,
## so a zone never opens with all its sites shut for the level.
func zone_gate(z: int) -> int:
	var g := 999
	for i in Data.ZONES[z]["tiers"]:
		g = mini(g, site_gate(int(i)))
	return g


## The zone before is done but the runner's under the zone's gate - and nothing in it cleared yet in this yard (a new
## runner after a death goes back to what the camp has taken, as a site does).
func zone_level_shut(z: int) -> bool:
	if z == 0 or not zone_complete(z - 1) or level() >= zone_gate(z):
		return false
	for i in Data.ZONES[z]["tiers"]:
		if int(best_depth[i]) > 0:
			return false
	return true


func zone_complete(z: int) -> bool:
	for i in Data.ZONES[z]["tiers"]:
		if stage_done(int(i)) < Data.STAGE_OPENS:     # (BUILD55-A) every site's 2/3
			return false
	return bosses_beaten[z] or zone_boss(z).is_empty()     # the Outskirts has no crew (12 Oct): its sites cleared is it done


## A zone's crew's head, {} for a zone without one (the Outskirts).
func zone_boss(z: int) -> Dictionary:
	for b in Data.BOSSES:
		if int(b["zone"]) == z:
			return b
	return {}


func campaign_done() -> bool:
	for z in range(Data.ZONES.size()):
		if not zone_complete(z):
			return false
	return true


## The boss of a tier, if it has one (the zone's last site).
func boss_of(i: int) -> Dictionary:
	for b in Data.BOSSES:
		if int(b["tier"]) == i:
			return b
	return {}


## What the next run against a tier's boss costs in notes: nothing until the
## crew's head has been beaten once (the campaign), then their price by depth.
func boss_cost(i: int) -> int:
	if _exp_fetch >= 0:
		return 0                              # a hold-up fetched (29 Oct): the holder's the run's, free
	if _a55_head == i:
		return head_fight_cost(int(Data.TIERS[i]["zone"]))     # (BUILD55-A) the head's own fight: his notes, not by depth
	if is_convoy(i):
		var total := 0
		for b in Data.BOSSES:
			if int(b["zone"]) < 1:
				continue                              # the Gamekeeper doesn't ride the convoy
			total += int(b["notes"]) * depth[i]       # the plain three: they come light (Matt, 8 Oct; it was the full-strength rate, 2,160 at depth 8)
		return total
	var b := boss_of(i)
	if b.is_empty() or not bosses_beaten[int(b["zone"])]:
		return 0
	if atlas_rank("long_memory") > 0 and i < boss_paid.size() and (depth[i] in boss_paid[i]):
		return 0                              # Long memory: paid once at this depth
	return int(round(int(b["notes"]) * depth[i] * (Data.PINNACLE_COST if is_pinnacle(i) else 1) * (1.0 - atlas_rank("heads_up") / 3.0)))


## A word with its bite scaled toward nothing: a multiplier m becomes 1 + (m - 1) × f, a contact rounded.
static func _softened(m: Dictionary, f: float) -> Dictionary:
	var out: Dictionary = m.duplicate()
	for k in ["hp", "dps", "xp", "cash", "drop", "pace", "patrol", "search"]:
		if out.has(k):
			out[k] = 1.0 + (float(out[k]) - 1.0) * f
	if out.has("contact"):
		var c: int = int(out["contact"])
		out["contact"] = signi(c) * ceili(absf(c) * f)     # away from nothing (18 Oct, Matt on Q6): half of Fog's one fewer is still one
	if out.has("rarity"):
		out["rarity"] = float(out["rarity"]) * f
	return out


## The depth a crew's head comes at full strength from on a site: PINNACLE_DEPTH for the site's zone (level 14 on his
## own site), a depth deeper for every move made (the endgame climbs with the loop), two sooner with Full strength.
func pinnacle_depth(i: int) -> int:
	return int(Data.PINNACLE_DEPTH[int(Data.TIERS[i]["zone"])]) - Data.FX["atlas/full_strength"] * atlas_rank("full_strength")


## The depth the old Services' convoy ran from (the depot's signal now, 15 Oct): CONVOY_DEPTH, a depth deeper a move.
func convoy_depth() -> int:
	return Data.CONVOY_DEPTH     # the old Services' convoy (the depot's signal now, 15 Oct); its two shortcuts went to the signals


## From pinnacle_depth(i) a crew's head comes at full strength.
func is_pinnacle(i: int) -> bool:
	return depth[i] >= pinnacle_depth(i)


## The Services, deep enough: the convoy, all three crews.
func is_convoy(i: int) -> bool:
	return i == Data.CONVOY_TIER and depth[i] >= convoy_depth() and campaign_done()


## A boss as they come at this tier and depth: the crew's head, or at full strength.
func boss_form(b: Dictionary, e: Dictionary, pinnacle: bool, convoy := false) -> Dictionary:
	var hp_v: float = e["hp"] * float(b["hp"]) * (Data.PINNACLE_HP if pinnacle else 1.0) * (Data.CONVOY_HP if convoy else 1.0)
	var dps_v: float = e["dps"] * float(b["dps"]) * (Data.PINNACLE_DPS if pinnacle else 1.0) * (Data.CONVOY_DPS if convoy else 1.0)
	return {"name": b["name"], "hp": hp_v, "dps": dps_v, "zone": int(b["zone"]), "pinnacle": pinnacle}


func can_arm_boss(i: int) -> bool:
	return (is_convoy(i) or (not boss_of(i).is_empty() and int(depth[i]) >= Data.SIGNAL_DEPTH)) and not runner_busy() and tier_open(i) and notes >= boss_cost(i)     # away (29 Oct): no head on a repeat; (BUILD55-A) a head is his own fight now (start_head_fight), never armed on a stage's run


## Armed for the next run, and only that run: the deploy takes it off, so the notes are paid once a choice (7 Oct).
func arm_boss(i: int, on: bool) -> void:
	if on and not can_arm_boss(i):
		return
	var was: bool = boss_armed.get(i, false)
	boss_armed[i] = on
	_surv_cache.erase(i)
	if on and not was and not _dry_on:
		var b := boss_of(i)
		if not b.is_empty() and Words.BOSSES.has(b["name"]):
			log_event(Words.LOG["head_armed"] % [b["name"], Words.BOSSES[b["name"]]["armed"]])


## A tier is open when its zone is and the tier before it in that zone has
## been cleared (best_depth > 0), or it's the zone's first.
func tier_open(i: int) -> bool:
	var t: Dictionary = Data.TIERS[i]
	if not zone_open(t["zone"]):
		return false
	var zt: Array = Data.ZONES[t["zone"]]["tiers"]
	var k := zt.find(i)
	return (k == 0 or stage_done(int(zt[k - 1])) >= Data.STAGE_OPENS) and not level_gated(i)     # (BUILD55-A) the one before's 2/3


## The level a site first opens at (19 Oct, Matt: "the level a player enters a new level matches the level of the gear
## drops - at worst you'd be one ahead"): its drops' level at depth 1, less one.
func site_gate(i: int) -> int:
	return maxi(1, wear_of(lv_at(i, 1)) - 1)


## Shut for the runner's level: a site not yet cleared in this yard, under its gate. Once cleared it stays open - a
## new runner after a death can go back to what the camp has taken.
func level_gated(i: int) -> bool:
	return int(best_depth[i]) <= 0 and level() < site_gate(i)


## The zone a tier belongs to, by name, for the log.
func zone_name(i: int) -> String:
	return Data.ZONES[Data.TIERS[i]["zone"]]["name"]


## A site's level: its tier and the depth it stands at (the endgame, 7 Oct: the ladder is nine ladders).
## The streets at depth 8 is level 8; the Barracks at depth 1 is level 9, at depth 8 level 16. The endgame's
## curve, the bases a find draws from and the item level a find carries all run by it.
func site_level(i: int) -> int:
	return lv_at(i, int(depth[i]))


## A site's level at a depth: its place past the Outskirts and the depth (12 Oct: the Streets at depth 1 is level 1, as
## before the Outskirts came; the Outskirts' are level 1 until their depth climbs past their place).
static func lv_at(i: int, d: int) -> int:
	return maxi(1, i - Data.OUTSKIRTS_SITES + d)


## The gear tier a level draws bases from (29 Oct, docs/design/itemisation.md §1: one tier a zone): under the signals'
## first level a site's own tier stands (the floor here; depth_figures clamps every site to its own), from it the
## signals' steps - T5 at level 10, T6 13, T7 16, T8 20, T9 24 - so a campaign site pushed past its first clear follows
## them (the Streets at level 10 drop T5).
static func loot_tier_at(level_v: int) -> int:
	var t: int = 1
	for at in Data.DEEP_TIER_LEVELS:
		if level_v >= int(at):
			t = maxi(t, Data.CAMPAIGN_TIER) + 1
	return mini(t, Data.MAX_TIER)


## A site's tier at a level (29 Oct, the review): never under its own, past its first clear too.
static func site_tier_at(i: int, level_v: int) -> int:
	return maxi(int(Data.TIERS[i]["loot_tier"]), loot_tier_at(level_v))


## The best tier a level reaches (29 Oct): the signals' from level 10, under it the best campaign site's whose first
## level it is or past (the Streets' T2 at level 1, the City's T4 from 7) - a level's own, with no site in hand.
static func tier_for_level(level_v: int) -> int:
	var t: int = loot_tier_at(level_v)
	for i in range(Data.TIERS.size()):
		if lv_at(i, 1) <= level_v:
			t = maxi(t, int(Data.TIERS[i]["loot_tier"]))
	return t


## The best tier open (29 Oct, the review: the shelf stuck at T4 once the signals opened): the open sites' own, or the
## deepest level's - what the Fence's shelf, the gamble, the Arms dealer, the mate and the Back room roll at.
func best_tier_open() -> int:
	return maxi(gear_tier(), loot_tier_at(deepest_site_level()))


## The top a tier-up can reach at a level: a campaign site's "a tier up" stays in the campaign's six.
static func loot_cap(level_v: int) -> int:
	return Data.CAMPAIGN_TIER if level_v < int(Data.DEEP_TIER_LEVELS[0]) else Data.MAX_TIER


## The tier as it will be fought: depth and intel applied. Every multiplier
## the fight and the search read comes from this, not the base table.
## A site's plain figures at a depth (16 Oct, split out of effective for the map's tier guide): the campaign's or the
## endgame's curve, the zone's quality and the over-level share - none of the run's own (the night, the map, the
## words, the sky, the wear). `on_sig`: a signal's fight, its level's curve alone. `ahead`: the endgame's curve though
## the campaign isn't done (the guide, showing what the signals will be).
func depth_figures(i: int, d: int, lv: int, on_sig := false, ahead := false) -> Dictionary:
	var base: Dictionary = Data.TIERS[i]
	var e := {
		"name": base["name"], "tier": i, "depth": d, "level": lv, "pool": int(base["pool"]),
		"hp": base["hp"] * pow(1.0 + Data.DEPTH_HOSTILE, d - 1),
		"dps": base["dps"] * pow(1.0 + Data.DEPTH_HOSTILE, d - 1),
		"xp": base["xp"] * pow(1.0 + Data.DEPTH_REWARD, d - 1),
		"cash": base["cash"] * pow(1.0 + Data.DEPTH_REWARD, d - 1),
		"drop": base["drop"] + Data.DEPTH_DROP * (d - 1),
		"loot_tier": int(base["loot_tier"]), "rarity": Data.DEPTH_RARITY * (d - 1),
		"pace": 1.0, "patrol": 1.0, "search": 1.0, "contact": 0, "intel": [], "word_tiers": {}, "armour": 1.0,
	}
	if d < Data.SIGNAL_DEPTH and not on_sig:     # (BUILD55-A) the stages, 1/3 to 3/3: the campaign's fight
		var hostile: float = float(Data.CAMPAIGN_HOSTILE[int(base["zone"])])     # by zone (the pass, 20 Oct); D20: the campaign's crews a touch softer
		# the campaign gets harder with the runner's level (21 Oct, Matt): a site past CAMPAIGN_LEVEL_FREE under the
		# runner compounds its heads' HP and fire a level; and its pool is CAMPAIGN_POOL bigger, the fight the run's length
		var harder: float = campaign_level_mult(i, d)
		hostile *= harder
		e["clock_mult"] = harder               # the clock keeps pace: the level's tax is on the fight, not the time
		e["hp"] *= hostile
		e["dps"] *= hostile
		e["pool"] = int(round(float(e["pool"]) * Data.CAMPAIGN_POOL))
	if d >= Data.SIGNAL_DEPTH and (campaign_done() or ahead):     # (BUILD55-A) the curve from depth 4: the stages keep their own figures after the campaign
		# the endgame (7 Oct): the curve by the site's level, bent by its shape, never under the site's own
		# campaign curve - so the streets' ladder is gentle and long and the Barracks' steep and short; the
		# bases a find draws from and its item level follow the level too (the sites were the same fight before)
		var shape: Dictionary = base["shape"]
		var c: Dictionary = Data.CURVE
		var g: float = pow(1.0 + float(c["grow"]), mini(lv, Data.CURVE_LATE_FROM) - 9) * pow(1.0 + Data.CURVE_LATE_GROW, maxi(0, lv - Data.CURVE_LATE_FROM))     # gentler past CURVE_LATE_FROM (24 Oct): a slope, not a wall
		var r: float = pow(1.0 + float(c["reward"]), lv - 9)
		e["pool"] = int(shape["pool"])
		# a signal's fight is its level's curve alone, bent by the site's shape (D14): the site's own campaign floor made
		# a City site's level 22 seven times the Allotments' (4200 x 1.25^13 against the curve's 3200 x 1.14^13), and
		# the Radio's signals split into won and binned by the site they landed on, not their level
		# D21: and on a signal the shape keeps its crowd and toughness but not its fire - the soft sites' many and the hard
		# ones' few come to much the same crew HP (14 x 0.6 against 8 x 1.5), and fire x0.7 against x1.4 was nine levels at
		# the 8% slope: the reach ran ahead on the soft sites and four in five rolls past it were unwinnable
		var kh: float = Data.curve_k(lv)                 # the level's gear against before (29 Oct, the new tiers): its HP by it, its fire half way
		var kd: float = (1.0 + kh) / 2.0
		e["hp"] = float(c["hp"]) * g * kh * float(shape["hp"]) if on_sig else maxf(float(e["hp"]), float(c["hp"]) * g * kh * float(shape["hp"]))
		e["dps"] = float(c["dps"]) * g * kd if on_sig else maxf(float(e["dps"]), float(c["dps"]) * g * kd * float(shape["dps"]))
		e["xp"] = float(c["xp"]) * r if on_sig else maxf(float(e["xp"]), float(c["xp"]) * r)     # and its pay (the review)
		e["cash"] = float(c["cash"]) * r * float(shape.get("cash", 1.0)) if on_sig else maxf(float(e["cash"]), float(c["cash"]) * r * float(shape.get("cash", 1.0)))
		e["drop"] = float(c["drop"]) + Data.DEPTH_DROP * (d - 2) if on_sig else maxf(float(e["drop"]), float(c["drop"]) + Data.DEPTH_DROP * (d - 2))
		e["loot_tier"] = site_tier_at(i, lv)     # never under the site's own tier (29 Oct, the review)
		e["rarity"] = float(c["rarity"]) * (d - 1)
		e["patrol"] = float(shape.get("patrol", 1.0))
	e["rarity"] += Data.ZONE_QUALITY[int(base["zone"])]     # a zone's quality (15 Oct, the loot read): a City drop is rarer than an Outskirts one
	var share: float = over_level_share(lv)
	e["xp"] *= share                         # D9 (Matt): a site well under you pays less XP and fewer tins
	e["cash"] *= share
	e["over_level"] = share
	return e


## The map's tier guide (16 Oct, item 11; "Fiat - Map tier guide", approved; the review: depth comes by signals now, by
## level, so the ladder is a signal's): a row a signal level on site `i` from `from_lv` - the level to wear its finds and
## the runner's fifth when that's lower, the gangs' HP and the pay against a campaign run here, the drops and rarity on
## it, the loose-unique chance, and what opens at it ([words, kind]: set, unique, deep, cap). As a signal plays it:
## depth_figures at tier_depth(level), the curve alone (on_sig); none of a run's own.
func guide_rows(i: int, from_lv: int, count := 12) -> Array:
	var b: Dictionary = depth_figures(i, 1, lv_at(i, 1))
	var mine: int = wearable_level()
	var own: Dictionary = site_unique(i)
	var rows: Array = []
	var before: int = tier_depth(from_lv - 1) if from_lv > lv_at(i, 1) else 0     # what the levels under the first row already opened
	var capped: bool = before > 0 and unique_odds({"tier": i, "depth": before}) >= Data.UNIQUE_CAP - 1e-6
	var sets: bool = before >= Data.SIGNAL_DEPTH     # (BUILD55-A)
	for lv in range(from_lv, from_lv + count):
		var td: int = tier_depth(lv)
		var f: Dictionary = depth_figures(i, td, lv, true, true)
		var uq: float = unique_odds({"tier": i, "depth": td})
		var marks: Array = []
		if td >= Data.SIGNAL_DEPTH and not sets:     # (BUILD55-A) set pieces from depth 4
			marks.append(["Set pieces drop", "set"])
		sets = sets or td >= Data.SIGNAL_DEPTH
		if not own.is_empty() and td == site_unique_depth(i):
			marks.append(["%s drops" % own["name"], "unique"])
		if lv in Data.DEEP_TIER_LEVELS:
			marks.append(["Deep gear, T%d" % loot_tier_at(lv), "deep"])
		if uq >= Data.UNIQUE_CAP - 1e-6 and not capped:
			marks.append(["Uniques at their cap", "unique"])
		capped = capped or uq >= Data.UNIQUE_CAP - 1e-6
		rows.append({"level": lv, "depth": td, "wear": wear_of(lv), "mine": wear_of(mine) if mine < lv else 0,
			"gangs": float(f["pool"]) * float(f["hp"]) / maxf(1e-9, float(b["pool"]) * float(b["hp"])),
			"pay": float(f["xp"]) / maxf(1e-9, float(b["xp"])),
			"drop": (float(f["drop"]) - float(b["drop"])) * 100.0, "rarity": (float(f["rarity"]) - float(b["rarity"])) * 100.0,
			"unique": uq, "marks": marks, "here": lv == reach})
	return rows


## The signal level a site's own unique starts dropping from: the first whose depth reaches site_unique_depth.
const DECRYPT_NEEDS_PAPERS := "put a paper in"     # decrypt_block's "not enough chosen", which the Radio reads as no block (18 Oct: a words change broke the match)


func site_unique_level(i: int) -> int:
	return tier_level(site_unique_depth(i))


## The level a Barracks-equivalent depth is (tier_depth's inverse): the depth a signal, a paper's gate or a site's own
## unique is keyed on, as the screens say it (18 Oct: levels on screen).
static func tier_level(d: int) -> int:
	return d + (Data.TIERS.size() - 1 - Data.OUTSKIRTS_SITES)


## Where the guide's ladder starts for a site: a few levels under the reach, never under the site's own level or the
## lowest a signal rolls.
func guide_from(i: int, count := 12) -> int:
	return maxi(maxi(lv_at(i, 1), Data.REACH_START), mini(reach - 4, 999 - count))     # no signal rolls under REACH_START (the review)


func effective(i: int) -> Dictionary:
	var base: Dictionary = Data.TIERS[i]
	var lv: int = lv_at(i, int(depth[i]))
	var e := depth_figures(i, site_depth(i), lv, not _sig.is_empty() and int(_sig["site"]) == i)     # a signal's depth: its level's on the hardest site, whatever site it's on (D3, the review)
	var d: int = int(e["depth"])
	var night_run: bool = has_node("night_work") or atlas_rank("after_dark") > 0 or is_night()
	if night_run:
		var night := modifier("Night")
		if not yard_has("floodlights") and town_stat("night_feet") <= 0.0 and not has_rule("linemans_lamp"):     # the Generator's Floodlights, the substation, the Lineman's Lamp: night's finds without its slow feet
			e["pace"] *= 1.0 - (1.0 - night.get("pace", 1.0)) * (Data.FX["yard/night_set"] if yard_has("night_set") else 1.0)   # the Radio's Night set: the slower feet halved
		e["rarity"] += night.get("rarity", 0.0) * (Data.FX["atlas/after_dark"] if atlas_rank("after_dark") > 0 else 1.0) * (2.0 if has_rule("linemans_lamp") else 1.0)   # After dark: the dark gives half again
		e["rarity"] += town_stat("night_rarity_pct") / 100.0     # the substation's ranks past the first
		e["intel"].append("Night")
	# the map at thirty-six (7 Oct): the sites' and the crews' columns, on every site
	e["drop"] *= 1.0 + Data.FX["atlas/easy_pickings"] * atlas_level("easy_pickings")
	e["cash"] *= (1.0 + Data.FX["atlas/every_penny"] * atlas_level("every_penny")) * (Data.FX["atlas/heavy_crews.cash"] if atlas_rank("heavy_crews") > 0 else 1.0)
	e["xp"] *= (1.0 + Data.FX["atlas/wages"] * atlas_level("wages")) * (Data.FX["atlas/heavy_crews.xp"] if atlas_rank("heavy_crews") > 0 else 1.0)
	e["pace"] *= 1.0 + Data.FX["atlas/short_cuts"] * atlas_rank("short_cuts")
	e["contact"] += (Data.FX["atlas/heavy_crews.contact"] if atlas_rank("heavy_crews") > 0 else 0) - (Data.FX["atlas/open_ground"] if atlas_rank("open_ground") > 0 else 0)
	e["rarity"] += Data.FX["atlas/tip_offs"] * atlas_level("tip_offs")
	if atlas_rank("local_knowledge") > 0:
		e["loot_tier"] = mini(loot_cap(lv), int(e["loot_tier"]) + 1)
	if night_run and yard_has("dead_air"):
		e["patrol"] *= Data.FX["yard/dead_air"]                  # the Radio's Dead air
	var sky: String = fight_weather_of(i)     # under a roof the rain bites nothing and pays no forecast (Matt, 25 Oct)
	if sky != "":
		e["intel"].append(sky)               # applied with the words below, softened by the Radio's Weather set
	elif weather_of(i) == "Rain":
		e["intel"].append("Roofed")          # the card says why it's dry: rain on the zone, none in here
	if sky != "" and yard_has("forecast"):
		e["cash"] *= Data.FX["yard/forecast"]                     # the Radio's forecast: a run under the weather pays
	# no wear (27 Oct, Matt: "kill drops should remain the same really"): a cleared site's picked over in its crates alone
	if not _sig.is_empty() and int(_sig["site"]) == i and is_county(str(_sig.get("order", ""))):
		_b61_figures(e, _sig)                # (BUILD61-A) a County stage or head: the place's own row, not the curve
	if _a55_head == i:
		e["pool"] = maxi(1, int(floor(float(e["pool"]) / 2.0)))     # (BUILD55-A) the head's own fight: half the site's gangs at his gate's man (FIX55b: the 2/3's), then him
		e["head_fight"] = true
	e["plain_pool"] = int(e["pool"])         # the clock reads the site as plain (9 Oct): the words bite through it; the heads are formed from the same
	e["plain_hp"] = float(e["hp"])
	var act: Array = active_words(i)
	var walks := false
	for aw in act:
		if Data.word_of(aw[0])["bite"].has("boss_walks"):
			walks = true
	var b := boss_of(i)
	var sig_here: bool = not _sig.is_empty() and int(_sig["site"]) == i
	if sig_here and str(_sig.get("county", "")) != "" and is_county(str(_sig["county"])):
		e["name"] = Data.county(str(_sig["county"]))["place"]     # the remix: a signal on one of the County's places
		e["county"] = true
	if sig_here and _sig.has("order"):
		if Data.pinnacle(str(_sig["order"])).has("who") and (not is_county(str(_sig["order"])) or _sig.has("chead")):     # a County place without its head is its crew alone (25 Oct); (BUILD61-A) he's on his own fight only
			e["boss"] = order_head(str(_sig["order"]), e)     # the order's true pinnacle (18 Oct): their own head, on the host site's crew
			if _sig.has("chead"):
				var d1: float = 1.0 / (1.0 + Data.DEPTH_HOSTILE)     # (BUILD61-A) him on the 1/3's man, his gang on the 2/3's
				e["boss"]["hp"] = float(e["boss"]["hp"]) * d1
				e["boss"]["dps"] = float(e["boss"]["dps"]) * d1
		e["name"] = Data.pinnacle(str(_sig["order"]))["place"]
		e["county"] = is_county(str(_sig["order"]))
	elif sig_here and str(_sig.get("county_head", "")) != "" and is_county(str(_sig["county_head"])):
		e["boss"] = order_head(str(_sig["county_head"]), e)     # the remix: one of the Issuer's people away from home (25 Oct)
		e["boss"]["pinnacle"] = true
		e["boss"]["remix"] = true                                # down, his issued kit; not a County run (no chron of one)
		e["boss"]["hp"] = float(e["boss"]["hp"]) * Data.PINNACLE_HP
	elif sig_here and bool(_sig.get("head", false)) and not zone_boss(int(_sig["zone"])).is_empty():
		e["boss"] = boss_form(zone_boss(int(_sig["zone"])), e, true)     # a signal's extra: the crew's head at full strength
	elif (boss_armed.get(i, false) and is_convoy(i)) or (sig_here and bool(_sig.get("convoy_fight", false))):     # the depot's signal: the convoy (15 Oct)
		# the convoy: all three, one after another, come light (CONVOY_HP of their HP, CONVOY_DPS of their fire): the crews stayed with the load
		var queue: Array = []
		for cb in Data.BOSSES:
			if int(cb["zone"]) >= 1:                  # the three crews; the Gamekeeper stays on his farm (13 Oct)
				queue.append(boss_form(cb, e, false, true))
		e["boss"] = queue[0]
		e["boss_queue"] = queue.slice(1)
		e["convoy"] = true
	elif not b.is_empty() and boss_armed.get(i, false) and (_a55_head == i or _exp_fetch >= 0 or int(depth[i]) >= Data.SIGNAL_DEPTH):     # (BUILD55-A) his own fight, a hold-up fetched, the old ladder's depths; never after a stage's pool
		e["boss"] = boss_form(b, e, is_pinnacle(i))
		if _a55_head == i:
			# (FIX55b, Matt: "the wall is still there early game") him on his site's 1/3 man, his gang on the 2/3's: the
			# fight's own figures (night, the tax) carried, the stage's step taken off
			var d1: Dictionary = depth_figures(i, 1, lv_at(i, 1))
			var dg: Dictionary = depth_figures(i, int(e["depth"]), lv_at(i, int(e["depth"])))
			e["boss"]["hp"] = float(e["boss"]["hp"]) * float(d1["hp"]) / maxf(0.001, float(dg["hp"]))
			e["boss"]["dps"] = float(e["boss"]["dps"]) * float(d1["dps"]) / maxf(0.001, float(dg["dps"]))
	elif walks and not zone_boss(int(base["zone"])).is_empty():     # the zone's head walks (the Gamekeeper on the Outskirts since 13 Oct)
		e["boss"] = boss_form(zone_boss(int(base["zone"])), e, false)     # The Manager walks: the zone's head on every run, free (formed as an armed head is, before the words)
	for name in e["intel"]:
		if name == "Night":
			continue                              # the clock's night is applied above
		var m := modifier(name)
		if yard_has("weather_set"):
			m = _softened(m, Data.FX["yard/weather_set"])               # the Radio's Weather set: the sky's word bites half as hard
		e["hp"] *= m.get("hp", 1.0)
		e["xp"] *= m.get("xp", 1.0)
		e["cash"] *= m.get("cash", 1.0)
		e["drop"] *= m.get("drop", 1.0)
		e["rarity"] += m.get("rarity", 0.0)
		e["pace"] *= m.get("pace", 1.0)
		e["patrol"] *= m.get("patrol", 1.0)
		e["search"] *= m.get("search", 1.0)
		e["contact"] += int(m.get("contact", 0))
	# the Radio's words (9 Oct, map juicing): each at its tier, the bite and the pay
	var wfx: Array = []
	for aw in act:
		var m := word_effect(aw[0], aw[1])
		wfx.append(m)
		e["intel"].append(aw[0])
		e["word_tiers"][aw[0]] = aw[1]
		e["hp"] *= m.get("hp", 1.0)
		e["dps"] *= m.get("dps", 1.0)
		e["xp"] *= m.get("xp", 1.0)
		e["cash"] *= m.get("cash", 1.0)
		e["drop"] *= m.get("drop", 1.0)
		e["loot_tier"] = mini(loot_cap(int(e["level"])), e["loot_tier"] + int(m.get("loot_tier", 0)))
		e["rarity"] += m.get("rarity", 0.0)
		e["pace"] *= m.get("pace", 1.0)
		e["patrol"] *= m.get("patrol", 1.0)
		e["search"] *= m.get("search", 1.0)
		e["contact"] += int(m.get("contact", 0))
		e["pool"] = maxi(1, int(round(float(e["pool"]) * float(m.get("pool", 1.0)))))
		e["armour"] *= float(m.get("armour", 1.0))
		e["soaked"] = float(e.get("soaked", 0.0)) + float(m.get("soaked", 0.0))     # the Water cannon (12 Oct): your resists down
		for key in m.get("crates", {}):
			if not e.has("crates"):
				e["crates"] = {}
			e["crates"][key] = float(e["crates"].get(key, 1.0)) * float(m["crates"][key])     # a code's crates (13 Oct)
		for f in ["no_meds", "no_kill_cash", "boss_walks"]:
			if m.get(f, false):
				e[f] = true
		if m.get("clock_half", false):
			e["clock_half"] = true
	# what their fire is made of, and what they resist: the zone's, grown by depth, and the words
	e["crew_zone"] = int(_sig["zone"]) if sig_here else int(base["zone"])     # a signal's crew is from any zone (15 Oct)
	var crew: Array = _crew_types(int(e["crew_zone"]), d, wfx)
	e["types"] = crew[0]
	e["res"] = crew[1]
	return e


## A crew's fire by type and what they resist: their zone's, grown by depth `d`, and the words' `wfx` on top. [types, res]
func _crew_types(zone_i: int, d: int, wfx: Array) -> Array:
	var zone: Dictionary = Data.ZONE_TYPES[zone_i]
	var types := {}
	for ty in zone["types"]:
		types[ty] = minf(Data.ZONE_SHARE_CAP, float(zone["types"][ty]) + Data.ZONE_GROW * (d - 1))
	# a zone hardens with depth against its own: what it wears and what it throws; the rest stays open, so every site is somebody's
	var res := {}
	for ty in Data.TYPES:
		var own: bool = zone["res"].has(ty) or zone["types"].has(ty)
		res[ty] = float(zone["res"].get(ty, 0.0)) + (Data.RESIST_DEPTH_STEP * (d - Data.RESIST_DEPTH + 1) if d >= Data.RESIST_DEPTH and own else 0.0)
	for m in wfx:
		if m.has("type"):
			types[m["type"]] = minf(0.9, float(types.get(m["type"], 0.0)) + float(m["share"]))
		if m.has("res"):
			for ty in (Data.TYPES if m["res"] == "all" else [m["res"]]):
				res[ty] += float(m["res_add"])
	var elemental := 0.0
	for ty in types:
		elemental += types[ty]
	if elemental > 0.9:
		for ty in types:
			types[ty] *= 0.9 / elemental
		elemental = 0.9
	types["physical"] = 1.0 - elemental
	for ty in res:
		res[ty] = minf(Data.RESIST_ENEMY_CAP, res[ty])
	return [types, res]


func modifier(name: String) -> Dictionary:
	for m in Data.MODIFIERS:
		if m["name"] == name:
			return m
	return {}


## Depth up or down. A site's words stay as they are; their tiers work at what the new depth allows.
func set_depth(i: int, d: int) -> void:
	if not runner_busy():                     # away (29 Oct): the site's level stands while the repeat's on it
		var top: int = mini(Data.STAGES, stage_done(i) + 1)     # (BUILD55-A) the stages: up to the one past the furthest cleared, at any time
		depth[i] = clampi(d, 1, top)
		a55_pick[i] = depth[i]
		_stats_dirty()                        # the front's level: the armour's cut at camp (review 43, 1)


# ------------------------------------------------------------------ the rebuild (18 Oct, docs/design/rebuild.md)

## A saved count map, its numbers back to ints (through a save they came back floats).
static func _counts(v: Variant) -> Dictionary:
	var out := {}
	if v is Dictionary:
		for k in v:
			if int(v[k]) != 0:
				out[str(k)] = int(v[k])
	return out


## The rebuild opens on Kev's last line: the depot's beat beaten.
func rebuild_open() -> bool:
	return story_beat >= Data.STORY_BEATS.size()


func rebuild_rank(key: String) -> int:
	return int(rebuilt.get(key, 0))


## The town's worth: every rank built, the number the endgame chases. Never down; a move keeps it.
func town_worth() -> int:
	var w := 0
	for k in rebuilt:
		w += int(rebuilt[k])
	return w


## What the next rank of a place wants: material and key-item keys -> counts.
func rebuild_cost(key: String) -> Dictionary:
	var r: Dictionary = Data.rebuild(key)
	if r.is_empty():
		return {}
	var next: int = rebuild_rank(key) + 1
	var out := {}
	for m in r["costs"]:
		out[m] = int(round(int(r["costs"][m]) * pow(Data.REBUILD_GROWTH, next - 1)))
	if next == 1:
		for m in r.get("first", {}):
			out[m] = int(out.get(m, 0)) + int(r["first"][m])
	if next >= 2:
		out["fuses"] = int(out.get("fuses", 0)) + Data.REBUILD_FUSES * (next - 1)
	if next >= Data.REBUILD_KEY_RANK:
		out[r["rank_key"]] = int(out.get(r["rank_key"], 0)) + 1
	if rebuild_halves > 0:
		for m in out:
			out[m] = int(ceil(int(out[m]) / 2.0))     # Birmingham's quota (29 Oct): the next rebuild at half
	return out


## Held of a material or a key item.
func held_of(k: String) -> int:
	return int(key_items.get(k, 0)) if Data.KEY_ITEMS.has(k) else int(materials.get(k, 0))


## A material's or a key item's name.
## A key item known (20 Oct): held, or the order's place that drops it known; till then its name reads scrambled.
func key_known(k: String) -> bool:
	if held_of(k) > 0:
		return true
	for p in Data.PINNACLES:
		if (str(p.get("drop", "")) == k or str(p.get("first", "")) == k) and order_known(str(p["key"])):
			return true
	return false


## A material's or key item's name as the player knows it: a key item's scrambled till key_known.
func thing_label(k: String) -> String:
	return thing_name(k) if not Data.KEY_ITEMS.has(k) or key_known(k) else Words.scramble(thing_name(k))


static func thing_name(k: String) -> String:
	if Data.KEY_ITEMS.has(k):
		return str(Data.KEY_ITEMS[k]["name"])
	return str(Data.MATERIALS.get(k, {"name": k})["name"])


## Why the next rank can't be built, or "".
func rebuild_block(key: String) -> String:
	if Data.rebuild(key).is_empty():
		return "no such place"
	if not rebuild_open():
		return "After Kev's story"
	if mission != null:
		return "The runner is out"
	var cost := rebuild_cost(key)
	for k in cost:
		if held_of(k) < int(cost[k]):
			return "Short of %s" % ((Words.mid(thing_name(k)) if key_known(k) else thing_label(k)) if Data.KEY_ITEMS.has(k) else thing_name(k).to_lower())     # a key item's name keeps its proper noun
	if cash < float(rebuild_tins(key)):
		return Words.T50_TOWN["short_tins"] % money_word()     # tins pay for the town (BUILD50-T)
	return ""


func can_rebuild(key: String) -> bool:
	return rebuild_block(key) == ""


func rebuild_place(key: String) -> bool:
	if not can_rebuild(key):
		return false
	var cost := rebuild_cost(key)
	for k in cost:
		var bag: Dictionary = key_items if Data.KEY_ITEMS.has(k) else materials
		bag[k] = held_of(k) - int(cost[k])
		if int(bag[k]) <= 0:
			bag.erase(k)                       # none left: off the count, as a save keeps it
	var tins: int = rebuild_tins(key)
	cash -= float(tins)                        # tins pay for the town (BUILD50-T): with the materials, never into debt (rebuild_block)
	rebuilt[key] = rebuild_rank(key) + 1
	if rebuild_halves > 0:
		rebuild_halves -= 1                   # Birmingham's quota spent (29 Oct)
	var r: Dictionary = Data.rebuild(key)
	chron("rebuild", {"key": key, "rank": rebuild_rank(key), "worth": town_worth(), "cost": cost.duplicate(), "tins": tins})
	log_event(Words.REBUILD["built"] % [r["name"], rebuild_rank(key), town_worth()])
	if rebuild_rank(key) == 1 and r.has("opens"):
		var place: String = str(Data.pinnacle(str(r["opens"]))["place"])
		log_event(Words.REBUILD["opened"] % (place if order_known(str(r["opens"])) else Words.scramble(place)))     # scrambled while its zone's shut (20 Oct)
	_yard_changed("")                          # the shelf and the prices read the town
	return true


## One effect at a rank: base, and step a rank past the first, to its cap.
static func fx_at(fx: Dictionary, rank: int) -> float:
	if rank <= 0:
		return 0.0
	var v: float = float(fx["base"]) + float(fx["step"]) * (rank - 1)
	return minf(v, float(fx["cap"])) if fx.has("cap") else v


## What the town does, by stat: every place's effect at its rank, summed.
func town_stat(stat: String) -> float:
	var v := 0.0
	for r in Data.REBUILDS:
		var rk: int = int(rebuilt.get(r["key"], 0))
		if rk <= 0 or town_stopped.has(str(r["key"])):
			continue                           # a place stopped, unpaid, does nothing (BUILD50-T)
		for fx in r["fx"]:
			if fx["stat"] == stat:
				v += fx_at(fx, rk)
	return v


## A place's effects in words at a rank (its next rank's to show what's coming): the lines with anything in them.
func rebuild_words(key: String, rank: int) -> Array:
	var out: Array = []
	for fx in Data.rebuild(key).get("fx", []):
		var v: float = fx_at(fx, maxi(1, rank))
		if v <= 0.0:
			continue
		out.append(str(fx["say"]) % int(floor(v)) if str(fx["say"]).contains("%") else str(fx["say"]))
	return out


## The mint's tins on a run: the worth × its pay × MINT_TINS, at today's prices; twice that with the FIAT note held.
func mint_tins() -> float:
	var pay: float = town_stat("mint_pay")
	if pay <= 0.0:
		return 0.0
	return town_worth() * pay * Data.MINT_TINS * inflation()     # the note's doubling went with the Issue (25 Oct): fiat after it


## The Mint pays on clears only (31 Oct, the designer): a run home with its site cleared - its gangs down, its head too
## if it has one - and neither bailed nor out of time. A bail or a time-out pays nothing from it.
func mint_pays(m: Dictionary) -> bool:
	return bool(m.get("cleared", false)) and not m.get("bailed", false) and not m.get("timed_out", false) and not m.get("ghost_pending", false) \
		and not (m.has("boss") and bool(m["boss"].get("alive", false)))


# ------------------------------------------------------------------ act two: tins pay for the town (BUILD50-T)

## docs/design/act_two.md §1-2 (Matt, 4 Nov: "389,080 tins with nothing to buy"): a build costs tins with its materials,
## every run home each place built draws its wage from the tins in hand in the town's order (Data.REBUILDS); one the
## tins don't cover stops - its effects off, its pin unlit - till a day it's paid. Never debt. At today's prices (_inf):
## fiat after the Issue (the_issue.md's price rule).
var town_stopped := {}              # place key -> true: stopped, unpaid


## A build's tins: REBUILD_TINS x REBUILD_GROWTH a rank past the first, at today's prices; half on Birmingham's quota.
func rebuild_tins(key: String) -> int:
	if not Data.REBUILD_TINS.has(key):
		return 0
	var t: float = float(Data.REBUILD_TINS[key]) * pow(Data.REBUILD_GROWTH, rebuild_rank(key))
	if rebuild_halves > 0:
		t = ceilf(t / 2.0)
	return _inf(t)


## A place's day's wage at its rank, at today's prices; 0 when not built.
func town_wage(key: String) -> int:
	var rk: int = rebuild_rank(key)
	if rk <= 0 or not Data.TOWN_WAGES.has(key):
		return 0
	return _inf(float(Data.TOWN_WAGES[key]) * (1.0 + Data.TOWN_WAGE_RANK * (rk - 1)))


## The day's bill: every place built, running or stopped (a stopped one runs again when it's paid).
func town_bill() -> int:
	var b := 0
	for r in Data.REBUILDS:
		b += town_wage(str(r["key"]))
	return b


## How many days the tins in hand cover the bill; -1 with nothing to pay.
func town_days() -> int:
	var b: int = town_bill()
	if b <= 0:
		return -1
	return int(floor(maxf(0.0, cash) / float(b)))


## A place running: built and paid.
func town_on(key: String) -> bool:
	return rebuild_rank(key) > 0 and not town_stopped.has(key)


func town_running() -> int:
	var n := 0
	for r in Data.REBUILDS:
		if town_on(str(r["key"])):
			n += 1
	return n


## The next step on the town's road: the first place not built, "" when all are.
func town_next_key() -> String:
	for r in Data.REBUILDS:
		if rebuild_rank(str(r["key"])) <= 0:
			return str(r["key"])
	return ""


## The day's wages, at a run home (the exchange's day): each place built in the town's order, from the tins in hand;
## one not covered stops (a toast), one stopped and paid runs again (a toast). Never into debt.
func town_pay_day() -> void:
	var paid := 0
	var stopped: Array = []
	var was: Dictionary = town_stopped.duplicate()
	for r in Data.REBUILDS:
		var k: String = str(r["key"])
		var w: int = town_wage(k)
		if w <= 0:
			continue
		if cash >= float(w):
			cash -= float(w)
			paid += w
			if town_stopped.has(k):
				town_stopped.erase(k)
				log_event(Words.T50_TOWN["log_back"] % Words.mid(str(r["name"])))
		else:
			stopped.append(k)
			if not town_stopped.has(k):
				town_stopped[k] = true
				log_event(Words.T50_TOWN["log_stopped"] % [Words.mid(str(r["name"])), money_word()])
	if paid > 0 or not stopped.is_empty():
		chron("wages", {"paid": paid, "stopped": stopped, "day": exchange_day})
	if was != town_stopped:
		_yard_changed("")                     # a place stopped or back: the shelf and the prices read the town


# ------------------------------------------------------------------ act two: a signal's focus (BUILD50-T, §4)

## A signal rolls what it drops: a material (the town's next step's first short, else its crew's area's), a slot, an
## element's resist or a unique's chance, on its own dice. Saved with the signal. N's chain links call it too.
func signal_focus_roll(sg: Dictionary) -> void:
	var tot := 0.0
	for w in Data.FOCUS_WEIGHTS:
		tot += float(w)
	var x: float = focus_rng.randf() * tot
	var kind: String = Data.FOCUS_KINDS[0]
	for k in range(Data.FOCUS_KINDS.size()):
		x -= float(Data.FOCUS_WEIGHTS[k])
		if x <= 0.0:
			kind = Data.FOCUS_KINDS[k]
			break
	var f := {"kind": kind}
	match kind:
		"material":
			f["key"] = focus_material(int(sg.get("zone", 1)))
		"slot":
			f["slot"] = Data.FOCUS_SLOTS[focus_rng.randi_range(0, Data.FOCUS_SLOTS.size() - 1)]
		"resist":
			f["el"] = Data.ELEMENTS[focus_rng.randi_range(0, Data.ELEMENTS.size() - 1)]
	sg["focus"] = f


## A material focus's material: the town's next step's first the camp is short of, else its first; with the town
## whole, one of the crew's area's two.
func focus_material(zone: int) -> String:
	var nk: String = town_next_key()
	if nk != "":
		var cost: Dictionary = rebuild_cost(nk)
		var mats: Array = Data.MATERIAL_ORDER.filter(func(k): return cost.has(k))
		for k in mats:
			if held_of(str(k)) < int(cost[k]):
				return str(k)
		if not mats.is_empty():
			return str(mats[0])
	var area: Array = Data.MATERIAL_ORDER.filter(func(k): return int(Data.MATERIALS[k]["area"]) == clampi(zone, 1, 3))
	return str(area[focus_rng.randi_range(0, area.size() - 1)]) if not area.is_empty() else "fuses"


## The focus of the signal on its run, {} for none.
func _focus() -> Dictionary:
	return _sig.get("focus", {}) if not _sig.is_empty() else {}


func focus_unique_mult() -> float:
	return Data.FOCUS_UNIQUE if str(_focus().get("kind", "")) == "unique" else 1.0


## A find's chance of a loose unique: the site's, a crate's lift, a unique focus and a night's fat drop, all inside
## UNIQUE_CAP (fix 50: the focus and the fat drop sat outside it).
func loose_unique_chance(t: Dictionary, crate_mult := 1.0, fat := false) -> float:
	return minf(Data.UNIQUE_BOOST_CAP, minf(Data.UNIQUE_CAP, unique_odds(t) * crate_mult) * focus_unique_mult() * (Data.NIGHT_FAT_UNIQUE if fat else 1.0))


## A slot focus: a gear find's slot its slot one time in two (FOCUS_SLOT).
func _focus_slot(slot: String) -> String:
	var f: Dictionary = _focus()
	if str(f.get("kind", "")) != "slot" or not (slot in Data.SLOTS):
		return slot
	return str(f["slot"]) if focus_rng.randf() < Data.FOCUS_SLOT else slot


## A resist focus: a gear find that can carry the element's resist carries it one time in three (FOCUS_RESIST) - added,
## the rarity a step up, or in a last affix's place at the top rarity. A unique, a set piece or a mythic as it is.
func _focus_resist(it: Dictionary) -> void:
	var f: Dictionary = _focus()
	if str(f.get("kind", "")) != "resist" or it.is_empty() or not (str(it.get("slot", "")) in Data.SLOTS):
		return
	if it.has("unique") or it.has("set") or it.get("mythic", false) or not it.has("affixes"):
		return
	var stat: String = str(f["el"]) + "_res"
	var d: Dictionary = Items.affix_def(stat)
	if d.is_empty() or not (str(it["slot"]) in d["slots"]):
		return
	if focus_rng.randf() >= Data.FOCUS_RESIST:
		return
	for a in it["affixes"]:
		if str(a["stat"]) == stat:
			return
	if int(it["rarity"]) < Data.RARITIES.size() - 1:
		it["rarity"] = int(it["rarity"]) + 1
		it["affixes"].append(Items.roll_affix(d, Items.ilvl(it), focus_rng, 0, Items.rarity_cap(it)))
		it["value"] = int(round(Items.base_of(it)["value"] * Data.RARITIES[it["rarity"]]["value"]))
	else:
		it["affixes"][it["affixes"].size() - 1] = Items.roll_affix(d, Items.ilvl(it), focus_rng, 0, Items.rarity_cap(it))


## "Add a resist" (act two §5): why it can't go on this piece for this resist ("" when it can). `stat` an element's
## resist ("fire_res"); "" asks only of the piece.
func resist_job_block(it: Dictionary, stat := "") -> String:
	if it.is_empty() or not (str(it.get("slot", "")) in Data.RESIST_JOB_SLOTS):
		return Words.T50_RESIST["no_slot"]
	if int(it.get("rarity", 0)) >= Data.RARITIES.size() - 1:
		return Words.T50_RESIST["top"]
	if stat != "":
		if not (stat.trim_suffix("_res") in Data.ELEMENTS) or not stat.ends_with("_res"):
			return Words.T50_RESIST["no_such"]
		for a in it["affixes"]:
			if str(a["stat"]) == stat:
				return Words.T50_RESIST["has"]
	return ""


## What a site's run can bring, as shares: the campaign site its own; a signal or the order's laid on it its crew's
## area's two (20 Oct, Matt: "flooded in some, barely any of others ... you can't really target farm"), the one held
## fewer of the likelier - each weighted 1 / (held + MATERIAL_LEAN). {} for none (the Outskirts on the campaign).
func material_split(i: int) -> Dictionary:
	if not _sig.is_empty() and int(_sig["site"]) == i:
		var area: int = maxi(1, int(_sig.get("zone", 1)))
		var ks: Array = Data.MATERIAL_ORDER.filter(func(k): return int(Data.MATERIALS[k]["area"]) == area)
		var w := {}
		var tot := 0.0
		for k in ks:
			w[k] = 1.0 / (float(materials.get(k, 0)) + Data.MATERIAL_LEAN)
			tot += float(w[k])
		for k in w:
			w[k] = float(w[k]) / tot
		return w
	var kind: String = Data.SITE_MATERIAL[i]
	return {kind: 1.0} if kind != "" else {}


## The material a run brings, rolled from its shares (one share: that one; "" for none).
func material_at(i: int) -> String:
	var split: Dictionary = material_split(i)
	if split.size() <= 1:
		return "" if split.is_empty() else str(split.keys()[0])
	var x: float = material_rng.randf()
	for k in split:
		x -= float(split[k])
		if x <= 0.0:
			return str(k)
	return str(split.keys().back())


## A run's chance at its site's material: MATERIAL_RUN on the campaign, a signal's by its level; a move adds a share.
func material_odds(i: int) -> float:
	if material_split(i).is_empty():
		return 0.0
	var base: float = Data.MATERIAL_RUN
	if not _sig.is_empty() and int(_sig["site"]) == i:
		base = Data.MATERIAL_SIGNAL + Data.MATERIAL_SIGNAL_STEP * maxi(0, signal_level(_sig) - Data.REACH_START)
	return minf(Data.MATERIAL_CAP, base)


## The run's roll at its site's material, at its first kill (1 Nov: a find in the pack, carried home or lost with it;
## till then rolled at the end, death included): the site's handful at material_odds, a signal's fuses at FUSE_SIGNAL.
func _run_materials(m: Dictionary) -> void:
	if m.get("dry", false) or _dry_on or m.get("mat_rolled", false):
		return
	m["mat_rolled"] = true
	var i: int = int(m["tier"])
	if not material_split(i).is_empty() and material_rng.randf() < material_odds(i):
		_haul_find(m, material_at(i), material_rng.randi_range(Data.MATERIAL_HANDFUL[0], Data.MATERIAL_HANDFUL[1]))
	if not _sig.is_empty() and int(_sig["site"]) == i and material_rng.randf() < Data.FUSE_SIGNAL:
		_haul_find(m, "fuses", material_rng.randi_range(1, 2))
	if not _sig.is_empty() and int(_sig["site"]) == i and str(_sig.get("focus", {}).get("kind", "")) == "material":
		_haul_find(m, str(_sig["focus"]["key"]), Data.FOCUS_MATERIAL)     # a material focus (BUILD50-T): its handful in the pack


## A crew's head down: their handful of the site's material, into the pack as a find (1 Nov).
func _head_materials(m: Dictionary) -> void:
	var kind: String = material_at(int(m["tier"]))
	if kind == "" or m.get("dry", false):
		return
	_haul_find(m, kind, material_rng.randi_range(Data.MATERIAL_HEAD[0], Data.MATERIAL_HEAD[1]))


## Scrap or a material found on the run (1 Nov, materials in the pack): `n` of it as stacks of its cap, each found like
## gear - a stack in the pack topped up first, then a cell of its own, else the floor by hand (the player chooses what
## to drop) or, on "Fill up, then go", passed over (_place_find).
func _haul_find(m: Dictionary, key: String, n: int) -> void:
	while n > 0:
		var it: Dictionary = Items.haul(key, 1)
		if it.is_empty():
			return
		var k: int = mini(n, Items.stack_cap(it))
		Items.set_stack(it, k)
		n -= k
		_place_find(m, it)


## Scrap and materials home (1 Nov): every stack in the pack (`from_pack`: a run home) and any the stash took (the dog's
## fetch, the Insurance desk, on a death or out of time) counted into the Pitch's scrap and materials - the counters the
## Bench, the Workshop and the rebuild spend - and the items gone, so they never take a stash cell. The run's report
## reads m["scrap"] and m["materials"]; the log says what came home. Returns {key: n}.
func _haul_home(m: Dictionary, from_pack: bool) -> Dictionary:
	var got := {}
	var lists: Array = [stash]
	if from_pack:
		lists.append(m["found"])
	for list in lists:
		for it in (list as Array).duplicate():
			if Items.is_material(it):
				var k: String = Items.material_key(it)
				got[k] = int(got.get(k, 0)) + Items.stack_size(it)
				(list as Array).erase(it)
	var run_scrap: int = int(got.get("scrap", 0))
	scrap += run_scrap
	m["scrap"] = int(m.get("scrap", 0)) + run_scrap
	var mats: Dictionary = got.duplicate()
	mats.erase("scrap")
	m["materials"] = mats
	if mats.is_empty():
		return got
	var first: bool = materials.is_empty() and town_worth() == 0
	var said: Array = []
	for k in Data.MATERIAL_ORDER:
		if mats.has(k):
			materials[k] = int(materials.get(k, 0)) + int(mats[k])
			said.append("%d %s" % [int(mats[k]), thing_name(k).to_lower()])
	chron("materials", {"got": mats.duplicate()})
	log_event(Words.REBUILD["material"] % ", ".join(said))
	if first:
		log_event(Words.REBUILD["first_material"] % thing_name(Data.MATERIAL_ORDER.filter(func(x): return mats.has(x))[0]))
	return got


## A save's run from before the rename (1 Nov, Matt: the material "Copper wire" is "Copper cable", the socketable keeps
## its name): its stacks in the pack and on the floor by the new name. The counts are keyed copper_wire, as before.
const HAUL_RENAMED := {"Copper wire": "Copper cable"}
static func _haul_names_up(m) -> void:
	if not (m is Dictionary):
		return
	for list in [m.get("found", []), m.get("floor", [])]:
		for it in list:
			if it is Dictionary and str(it.get("slot", "")) == Data.MATERIAL and HAUL_RENAMED.has(str(it.get("base", ""))):
				it["base"] = HAUL_RENAMED[str(it["base"])]


## The dog's pick of a pack (1 Nov, the re-review): the dearest wearable kit by its sale (a body slot's: guns, armour, the
## rig, the pack, a charm); with none, the dearest of everything else - rounds, meds, magazines, scrap and material stacks.
func fetch_pick(items: Array) -> Dictionary:
	var gear: Array = items.filter(func(x): return str(x.get("slot", "")) in Data.SLOTS)
	var from: Array = gear if not gear.is_empty() else items
	var best: Dictionary = {}
	for it in from:
		if best.is_empty() or sell_price(it) > sell_price(best):
			best = it
	return best


## A death's scrap and materials brought home (1 Nov, the review: the dog's or the Insurance desk's): on the run's report,
## the "Dead" record line and the came-back card, as a run home's are.
func _dead_haul_said(m: Dictionary, got: Dictionary, dead_e: Dictionary) -> void:
	var n: int = int(got.get("scrap", 0))
	var mats: Dictionary = m.get("materials", {})
	last_report["scrap"] = n
	last_report["materials"] = mats.duplicate()
	if not dead_e.is_empty():
		dead_e["scrap"] = n
		dead_e["materials"] = mats.duplicate()
		if n > 0 and not came_back.is_empty() and not unwatched():
			came_back["scrap"] = int(came_back.get("scrap", 0)) + n


## The order's true pinnacles: open once their rebuild is.
func order_open(k: String) -> bool:
	if is_county(k):
		return county_open(k)
	var p: Dictionary = Data.pinnacle(k)
	return not p.is_empty() and rebuild_rank(str(p["opened_by"])) > 0


## An order's place known (20 Oct, Matt: "the grid, archive and mint also need to be encoded"): its place rebuilt and
## its host site's zone open; till then its names read scrambled, as a shut zone's do.
func order_known(k: String) -> bool:
	if is_county(k):
		return county_zone_open(int(Data.county(k)["cz"]))
	var p: Dictionary = Data.pinnacle(k)
	return order_open(k) and zone_open(int(Data.TIERS[int(p["site"])]["zone"]))


## A true pinnacle's level: your reach and its own step past it, a level more every PINNACLE_WORTH of the town's worth
## and every time it's been beaten.
func order_level(k: String) -> int:
	if is_county(k):
		return county_level(k)
	var p: Dictionary = Data.pinnacle(k)
	if p.has("level"):
		# the Grid at 35, the Archive at 40 and the Mint at 45 for the first win (Matt, 26 Oct, the sixth pass: at the reach +
		# 2 + the worth no read won the Lineman); after it a set ladder over the County, 90/95/100 and 2 a win (Matt, 27 Oct,
		# docs/design/pinnacle_and_exploits.md: with the reach they ran ahead of every build, a wall)
		var wins: int = int(order_beaten.get(k, 0))
		return int(p["level"]) if wins == 0 else int(p.get("again", p["level"])) + Data.ORDER_AGAIN_STEP * (wins - 1)
	@warning_ignore("integer_division")
	return maxi(Data.REACH_START, reach) + int(p["over"]) + town_worth() / Data.PINNACLE_WORTH + int(order_beaten.get(k, 0))


## A true pinnacle as a signal: laid on its host site the way a signal is, under its own name and head.
func order_sig(k: String) -> Dictionary:
	if is_county(k):
		return county_sig(k, county_stage_pick(k))     # (BUILD61-A) a County place at its picked stage
	var p: Dictionary = Data.pinnacle(k)
	var site: int = int(p["site"])
	return {"id": -1, "site": site, "zone": int(p["zone"]), "depth": depth_for_level(site, order_level(k)), "codes": [], "papers": [],
		"head": false, "convoy": false, "line": 0, "story": -1, "order": k}


## The head a true pinnacle fields, formed on the fight's figures as a crew's head is.
func order_head(k: String, e: Dictionary) -> Dictionary:
	var p: Dictionary = Data.pinnacle(k)
	# an order won before, on its ladder: its head softer (Matt, 27 Oct, the gauntlet: the repeats' fire was the wall);
	# the first win as tuned, so the Issue's timing holds
	var soft: float = float(p.get("again_soft", Data.ORDER_AGAIN_SOFT)) if not is_county(k) and int(order_beaten.get(k, 0)) > 0 else 1.0     # the Mint's own (27 Oct)
	var b := boss_form({"name": p["who"], "hp": float(p["hp"]) * soft, "dps": float(p["dps"]) * soft, "zone": p["zone"]}, e, false)
	b["order"] = k
	b["mech"] = str(p.get("mech", k))     # the fight he brings: the order's own by key, a County head's by his (25 Oct)
	return b


## A true pinnacle's figures, as it would run.
func order_read(k: String) -> Dictionary:
	if not _sig.is_empty() or not order_open(k):
		return {}
	var sg := order_sig(k)
	_sig_on(sg)
	var e := effective(int(sg["site"]))
	_sig_off()
	return e


## A true pinnacle's odds, read a few dry runs at a time as a signal's are. [odds so far, settled].
func order_odds(k: String) -> Array:
	if not _sig.is_empty() or not order_open(k):
		return [0.0, false]
	var sg := order_sig(k)
	_sig_on(sg)
	var i: int = int(sg["site"])
	var key: String = "order/%s/%d" % [k, int(sg["depth"])]
	var home = _surv_cache.get(i, null)
	if _sig_odds.has(key):
		_surv_cache[i] = _sig_odds[key]
	else:
		_surv_cache.erase(i)
	var o: float = survival(i)
	var done: bool = odds_settled(i)
	_sig_odds[key] = _surv_cache[i]
	if home != null:
		_surv_cache[i] = home
	else:
		_surv_cache.erase(i)
	_sig_off()
	return [o, done]


## The odds read so far, without running any (the Map's order card, as signal_odds_now is the Radio's).
func order_odds_now(k: String) -> Array:
	if not _sig.is_empty() or not order_open(k):
		return [0.0, false]
	var sg := order_sig(k)
	var key: String = "order/%s/%d" % [k, int(sg["depth"])]
	if not _sig_odds.has(key):
		return [0.0, false]
	_sig_on(sg)
	var i: int = int(sg["site"])
	var c: Array = _sig_odds[key]
	var out: Array = [float(c[1]), int(c[2]) >= mini(odds_runs(), Data.ODDS_RUNS)] if c[0] == _odds_key(i) else [0.0, false]
	_sig_off()
	return out


## Why a true pinnacle can't be run now, or "".
func order_block(k: String) -> String:
	var p: Dictionary = Data.pinnacle(k)
	if p.is_empty():
		return "no such place"
	if is_county(k):
		var cw: String = county_block(k)
		if cw != "":
			return cw
	elif not order_open(k):
		return "Rebuild %s to open" % str(Data.rebuild(str(p["opened_by"]))["name"]).to_lower()
	if not can_deploy() or not _sig.is_empty():
		return "The runner is out" if mission != null else (Words.REPEAT["shut_away"] if away() else "The runner can't go")
	if not tier_open(int(p["site"])):
		return "The way there is shut"            # its host site shut (the review: a silent failed Go)
	return ""


## Run a true pinnacle: laid on its host site for the run, as a signal is; nothing spent to go.
func deploy_order(k: String) -> bool:
	if order_block(k) != "":
		return false
	var sg := order_sig(k)
	_sig_on(sg)
	deploy(int(sg["site"]))
	if mission == null:
		_sig_off()
		return false
	mission["signal"] = sg
	if is_county(k):
		_b61_marks(mission, sg)                  # (BUILD61-A) the place and its stage on the mission
	chron("order_run", {"key": k, "level": order_level(k)})
	return true


## A true pinnacle's head down: the run's pay, their unique (always the first time), their handful of materials.
func _order_down(m: Dictionary, t: Dictionary, b: Dictionary) -> void:
	var k: String = str(b["order"])
	if is_county(k):
		_county_down(m, t, b)
		return
	var p: Dictionary = Data.pinnacle(k)
	var first: bool = int(order_beaten.get(k, 0)) == 0
	_web_reward("head:" + str(p["who"]), Data.REWARD_HEAD, str(p["who"]))     # the order's heads: their first fall
	chron("order_down", {"key": k, "first": first, "level": int(t.get("level", 0))})
	_head_materials(m)
	if first or rng.randf() < Data.PINNACLE_UNIQUE:
		var which: String = str(p["unique"]) if (not p.has("unique2") or rng.randf() < 0.5) else str(p["unique2"])     # one of the two (24 Oct)
		var it := Items.roll_unique(_unique_named(which), rng, maxi(int(t.get("level", -1)), reach), int(t["loot_tier"]))     # at the reach if past the place (the third review)
		_head_drop(m, it, false)
		log_event(Words.LOG["order_down_found"] % [p["who"], it["unique"]])
	else:
		log_event(Words.LOG["order_down"] % p["who"])


## A true pinnacle's run over: beaten, its drop comes home (and the first time its keepsake); either way the site goes
## back to its campaign self. The reach is the signals'; the order's never moves it.
func _order_done(won: bool) -> void:
	var k: String = str(_sig["order"])
	if is_county(k):
		_county_done(k, won)
		return
	var p: Dictionary = Data.pinnacle(k)
	chron("order_done", {"key": k, "won": won})
	if not won:
		log_event(Words.REBUILD["order_lost"] % p["who"])
		return
	var first: bool = int(order_beaten.get(k, 0)) == 0
	order_beaten[k] = int(order_beaten.get(k, 0)) + 1
	var drop: String = str(p.get("drop", ""))
	if drop != "":
		key_items[drop] = held_of(drop) + 1
		log_event(Words.LOG["brought_home"] % thing_name(drop))
	if first and p.has("first"):
		var f: String = str(p["first"])
		key_items[f] = held_of(f) + 1
		if f == "fiat_note":
			log_event(Words.REBUILD["note"])
			issue()                              # the Issue: the town on his money from here (25 Oct)
	elif k == "mint" and issued:
		var haul: float = print_haul(int(order_beaten.get(k, 0)))
		_earn(haul)
		circulation += haul * Data.PRINT_CIRC          # he prints: a haul, and the prices jump with it
		log_event(Words.ISSUE["printed"] % fiat_words(haul))
	log_event(Words.REBUILD["order_won"] % p["who"])


## The Issuer's print on his `wins`th win (the first is the Issue): each smaller than the last (Matt, 26 Oct: "a
## choice, not a farm").
func print_haul(wins: int) -> float:
	return float(_inf(Data.PRINT_HAUL * pow(Data.PRINT_DECAY, maxi(0, wins - 2))))


# ------------------------------------------------------------------ the County (25 Oct, the Issue's second campaign)

## A County place: fought as one of the order's (its key in `_sig["order"]`), on its host site.
static func is_county(k: String) -> bool:
	return not Data.county(k).is_empty()


## A County zone's places, in order; the last is its head's.
static func county_places(z: int) -> Array:
	var out: Array = []
	for c in Data.COUNTY:
		if int(c["cz"]) == z:
			out.append(str(c["key"]))
	return out


static func county_head_key(z: int) -> String:
	var ks := county_places(z)
	return str(ks.back()) if not ks.is_empty() else ""


## A County zone stands open once the town's on fiat and the zone before has lost its head. (Its want of issued kit
## is on the places' Go, county_block: take a piece off and the zone's still there, its places shut till it's back.)
func county_zone_open(z: int) -> bool:
	if not issued or z < 0 or z >= Data.COUNTY_ZONES.size():
		return false
	return z == 0 or county_head_falls(z - 1) > 0     # (BUILD61-A) the head's own falls


## A place opens when its zone has and the place before it in the zone is taken.
func county_open(k: String) -> bool:
	var c: Dictionary = Data.county(k)
	if c.is_empty() or not county_zone_open(int(c["cz"])):
		return false
	var ks := county_places(int(c["cz"]))
	var at: int = ks.find(k)
	return at == 0 or county_stage_done(str(ks[at - 1])) >= Data.STAGE_OPENS     # (BUILD61-A) the place before at its 2/3


func county_want(z: int) -> int:
	return int(Data.ISSUED_WANT[clampi(z, 0, Data.ISSUED_WANT.size() - 1)])


## Why a County place can't be run for what it is (its zone, the place before, the issued kit worn), or "".
func county_block(k: String) -> String:
	var c: Dictionary = Data.county(k)
	var z: int = int(c["cz"])
	if not issued:
		return Words.COUNTY["not_yet"]
	if not county_zone_open(z):
		return Words.COUNTY["zone_shut"] % str(Data.COUNTY_ZONES[z - 1]["head"])
	if not county_open(k):
		var ks := county_places(z)
		return Words.COUNTY["place_shut"] % Words.mid(str(Data.county(str(ks[ks.find(k) - 1]))["place"]))
	if issued_worn() < county_want(z):
		return Words.COUNTY["want"] % [county_want(z), issued_worn()]
	return county_stage_block(k, county_stage_pick(k))     # (BUILD61-A) its picked stage's


## A County place's level: its set level, and a level more every time it's been taken.
func county_level(k: String) -> int:
	return county_stage_level(k, county_stage_pick(k))     # (BUILD61-A) its picked stage's: no level a win


## The Treasurer down: the County taken, and the Radio's remix open.
func county_done() -> bool:
	return county_head_falls(Data.COUNTY_ZONES.size() - 1) > 0     # (BUILD61-A)


## The places taken, of the twelve.
func county_taken_count() -> int:
	var n := 0
	for c in Data.COUNTY:
		if county_stage_done(str(c["key"])) >= Data.STAGE_OPENS:     # (BUILD61-A) taken: its 2/3
			n += 1
	return n


## A County head down: his handful of the site's material, and issued kit at his level, stamped and numbered.
func _county_down(m: Dictionary, t: Dictionary, b: Dictionary) -> void:
	var k: String = str(b["order"])
	var c: Dictionary = Data.county(k)
	if not bool(b.get("remix", false)) and c.has("who"):
		_web_reward("head:" + str(c["who"]), Data.REWARD_HEAD, str(c["who"]))     # the County's four heads: their first fall
	if not bool(b.get("remix", false)):
		chron("county_head", {"key": k, "first": county_head_falls(int(c["cz"])) == 0, "level": int(t.get("level", 0))})     # (BUILD61-A) his own falls
	_head_materials(m)
	var lv: int = maxi(int(t.get("level", reach)), reach) + Data.ISSUED_OVER + 2     # a tier over the counter's (the third review: a head's was always weaker)
	var got: Array = []
	for n in range(Data.COUNTY_HEAD_ISSUED):
		var slot: String = str(Data.ISSUED[rng.randi_range(0, Data.ISSUED.size() - 1)]["slot"])
		var it := issued_piece(slot, lv, true)
		issued_serial += 1
		it["serial"] = issued_serial
		m["found"].append(it)
		_read(it)
		got.append(Items.full_name(it))
	log_event(Words.COUNTY["head_down"] % [str(c["who"]), ", ".join(got)])
	if str(b.get("mech", "")) == "bailiff":     # the head itself: down, _order_mech reads nothing (the review)
		if bool(m.get("seize_on", false)):
			m["seize_on"] = false              # down in one blow from over half: what he held is let go all the same (the review)
		_bailiff_drops_deeds(m)


## A County run over: won, the place is taken (and its next one opens, or the next zone with its head); either way
## the host site goes back to its campaign self.
func _county_done(k: String, won: bool) -> void:
	var c: Dictionary = Data.county(k)
	chron("county_done", {"key": k, "won": won, "level": lv_at(int(_sig.get("site", c["site"])), int(_sig.get("depth", 1))), "stage": int(_sig.get("stage", 0)), "head": int(_sig.get("chead", -1))})     # (BUILD61-A) the stage, the head
	if not won:
		log_event(Words.COUNTY["lost"] % str(c["place"]))
		return
	_b61_won(k)                                  # (BUILD61-A) the stage's tick or the head's fall


# ------------------------------------------------------------------ signals (15 Oct, the Radio's endgame)

## A paper for the Radio's pile: not the deeds, a head's thing or a unique's rule paper (those keep the stash).
static func is_pile_paper(it: Dictionary) -> bool:
	return Items.is_paper(it) and not Items.is_deeds(it) and Items.opens(it) == "" and not it.has("unique")


## Any pile paper that reached the stash goes to the Radio's pile (18 Oct, Matt: contracts took his papers): run home,
## Kev's, a load from before the pile. Never sold, never a contract's, no stash cells.
func _sweep_papers() -> void:
	for it in stash.duplicate():
		if is_pile_paper(it):
			it.erase("tab")
			stash.erase(it)
			_removed += 1
			papers.append(it)
	_pile_trim()


## The pile at its cap (23 Oct, parked item 9): past PILE_CAP the plainest plain paper goes - the lowest rarity, the
## oldest of those - never Kev's; said once a trim.
func _pile_trim() -> void:
	var over: int = papers.size() - Data.PILE_CAP
	if over <= 0:
		return
	var plain: Array = []                       # [rarity, place] - the plainest first, the oldest of a rarity first
	for i in range(papers.size()):
		if story_of(papers[i]) < 0:
			plain.append([int(papers[i].get("rarity", 0)), i])
	plain.sort_custom(func(a, b): return a[0] < b[0] if a[0] != b[0] else a[1] < b[1])
	var went: int = mini(over, plain.size())    # sorted once and sliced (the review: a 28k-paper save trimmed one at a time)
	var gone: Array = []
	for k in range(went):
		gone.append(plain[k][1])
	gone.sort()
	gone.reverse()                              # the places from the back so the front's hold
	for i in gone:
		papers.remove_at(i)
	if went > 0 and not _dry_on:
		log_event(Words.PILE_FULL % Data.PILE_CAP)


## The papers a signal can be made of: the Radio's pile.
func signal_papers() -> Array:
	_sweep_papers()
	return papers


## The pile's ids, read once a shape of it (22 Oct): a paper comes by the count or the item count, goes by a signal made.
var _pile_ids_key: Array = []
var _pile_ids_set := {}
func _pile_ids() -> Dictionary:
	var all: Array = signal_papers()
	var key := [all.size(), Items._next_id, signal_seq]
	if key != _pile_ids_key:
		_pile_ids_key = key
		_pile_ids_set = {}
		for x in all:
			_pile_ids_set[int(x["id"])] = true
	return _pile_ids_set


## Why three papers can't be decrypted now, or "".
func decrypt_block(ids: Array, crew := -1) -> String:
	if not room_open("radio"):
		return "the Radio's shut"
	if not campaign_done():
		return "the campaign first"
	if signals.size() >= signals_cap():
		return "%d signals held: run or bin one" % signals_cap()     # half while the set's out (BUILD46-S)
	if ids.is_empty():
		return DECRYPT_NEEDS_PAPERS
	if ids.size() > Data.SIGNAL_PAPERS:
		return "three papers at most"
	var have: Dictionary = _pile_ids()    # (22 Oct, the pass's wall: a pile of thousands walked thrice a paper)
	var seen_ids := {}
	for id in ids:
		if not have.has(int(id)) or seen_ids.has(int(id)):
			return "papers from the Radio's pile"
		seen_ids[int(id)] = true
	var beats := {}
	var bases := {}
	for it in papers:
		if int(it["id"]) in ids:
			beats[story_of(it)] = true
			bases[str(it["base"])] = true
	if beats.size() > 1 or (beats.has(-1) == false and bases.size() < Data.SIGNAL_PAPERS):     # a beat's three, never one or two of it
		return "Kev's papers go in together, the three of a beat"
	if not beats.has(-1) and not beats.has(story_now()):
		return "not the part of Kev's story he's on"
	if crew >= 0 and beats.has(-1):
		if crew < 1 or crew >= Data.ZONES.size():
			return "no such crew"
		if notes < Data.AIM_NOTES:
			return "%d notes for Kev to tune it" % Data.AIM_NOTES
	return ""


## Kev's story (15 Oct): a paper's beat, or -1 for any other.
static func story_of(it: Dictionary) -> int:
	if not Items.is_paper(it):
		return -1
	return int(Items.base_named(Data.PAPER, str(it["base"])).get("story", -1))


## The beat Kev's on: the next unbeaten, the depot again once all three are.
func story_now() -> int:
	return mini(story_beat, Data.STORY_BEATS.size() - 1)


## A beat's three papers, by name.
static func story_papers(beat: int) -> Array:
	var out: Array = []
	for b in Data.BASES[Data.PAPER]:
		if int(b.get("story", -1)) == beat:
			out.append(str(b["name"]))
	return out


## Which of the beat Kev's on are held (stash or pack), by name.
func story_held() -> Array:
	var held: Array = stash.duplicate() + papers
	if mission != null:
		held.append_array(mission["found"])
	var out: Array = []
	for sg in signals:
		if int(sg.get("story", -1)) == story_now():
			return story_papers(story_now())     # the beat's signal is held already: nothing more to find (the review)
	for it in held:
		if story_of(it) == story_now() and not (str(it["base"]) in out):
			out.append(str(it["base"]))
	return out


## A signal's grade by the papers in (20 Oct): one Faint, two Clear, three Full; none reads as three (the band the
## decoder shows before any paper's in, and a signal from before the grades).
static func signal_grade(n: int) -> Dictionary:
	var k: int = clampi(n, 1, Data.SIGNAL_GRADES.size()) if n > 0 else Data.SIGNAL_GRADES.size()
	return Data.SIGNAL_GRADES[k - 1]


## The levels these papers would roll: their grade's band round the reach, one higher for a rare paper (D3: levels,
## not depths).
func signal_band(ids: Array) -> Array:
	var roll: Array = signal_grade(ids.size())["roll"]
	var lo: int = reach + (maxi(int(roll[0][0]), -int(Data.FX["atlas/lie_of_the_land"])) if atlas_rank("lie_of_the_land") > 0 else int(roll[0][0]))
	var hi: int = reach + int(roll[roll.size() - 1][0]) + (int(Data.FX["atlas/lorrys_route"]) if atlas_rank("lorrys_route") > 0 else 0)
	var up: int = 1 if _papers_rare(ids) else 0
	return [maxi(Data.REACH_START, lo + up), maxi(Data.REACH_START, hi + up)]     # a faint band at the first reach is the first level (20 Oct)


## The most codes these papers' signal could carry at the top of its band: the depth's count (WORD_MAX_DEPTH, read
## at the level's tier depth as max_words reads it), never past its grade's (20 Oct), and the map's Long wave and the
## Yard's Long range on top.
func signal_codes_most(ids: Array) -> int:
	var d: int = tier_depth(int(signal_band(ids)[1]))
	var n := 0
	for row in Data.WORD_MAX_DEPTH:
		if d >= int(row[0]):
			n = int(row[1])
	n = mini(maxi(n, ids.size()), int(signal_grade(ids.size())["codes"]))
	return n + atlas_rank("long_wave") + (Data.FX["yard/long_range"] if yard_has("long_range") else 0)


func _papers_rare(ids: Array) -> bool:
	for it in signal_papers():
		if int(it["id"]) in ids and int(it.get("rarity", 0)) >= Data.PAPER_DEEPER_AT:
			return true
	return false


## Three papers in, a signal out: the papers spent, the place, the crew, the depth and the extras rolled, each paper's
## code on it. {} if it can't be made.
## `crew`: an area's crew to call (1 the Estate .. 3 the City), Kev tuning it for AIM_NOTES (20 Oct, Matt: "you can't
## really target farm what you are short of"); -1 any crew, rolled.
func decrypt(ids: Array, crew := -1) -> Dictionary:
	if decrypt_block(ids, crew) != "":
		return {}
	var names: Array = []
	var codes: Array = []
	var want := {}
	for id in ids:
		want[int(id)] = true
	var up := 0
	var beat: int = -1
	var left: Array = []
	for it in papers:                      # one pass of the pile (22 Oct, the pass's wall): the spent read, the rest kept
		if not want.has(int(it["id"])):
			left.append(it)
			continue
		names.append(str(it["base"]))
		var code: String = word_taught_by(str(it["base"]))
		if code != "" and not (code in codes):
			codes.append(code)
		if int(it.get("rarity", 0)) >= Data.PAPER_DEEPER_AT:
			up = 1                             # a rare paper in: a level up (as _papers_rare read it)
		beat = story_of(it)
	papers = left                          # spent off the Radio's pile
	if beat >= 0:
		for nm in names:
			_web_reward("kev:" + str(nm), Data.REWARD_KEV, str(nm))     # a chapter of Kev's story: a point each paper, once
		return _story_signal(beat, names)
	var grade: Dictionary = signal_grade(ids.size())
	var roll: Array = grade["roll"]
	var x := rng.randf()
	var step := 0
	for row in roll:
		x -= float(row[1])
		step = int(row[0])
		if x <= 0.0:
			break
	if atlas_rank("lie_of_the_land") > 0:
		step = maxi(step, -int(Data.FX["atlas/lie_of_the_land"]))     # The lie of the land: no roll far under the reach (18 Oct)
	if step == int(roll[roll.size() - 1][0]) and atlas_rank("lorrys_route") > 0 and rng.randf() < 0.5:
		step += int(Data.FX["atlas/lorrys_route"])     # The lorry's route: the top of the band a depth further, half the time it's reached
	signal_seq += 1
	var site: int = rng.randi_range(0, Data.TIERS.size() - 1)
	var zone: int = rng.randi_range(0, Data.ZONES.size() - 1)
	if crew >= 1:
		zone = crew
		notes -= Data.AIM_NOTES
	var sig := {"id": signal_seq, "site": site, "zone": zone,
		"depth": depth_for_level(site, maxi(Data.REACH_START, reach + step + up)), "codes": codes, "papers": names,
		"head": rng.randf() < Data.SIGNAL_HEAD_ODDS * float(grade["extras"]), "convoy": rng.randf() < Data.SIGNAL_CONVOY_ODDS * float(grade["extras"]),
		"line": rng.randi_range(0, Words.SIGNAL_LINES.size() - 1), "grade": int(grade["papers"])}
	_remix(sig, step + up)
	signal_focus_roll(sig)                 # what it drops (BUILD50-T, act two §4)
	signals.append(sig)
	chron("signal", {"id": signal_seq, "site": int(sig["site"]), "zone": int(sig["zone"]), "depth": int(sig["depth"]), "codes": codes.duplicate(), "papers": names.duplicate()})
	log_event(Words.SIGNAL_MADE % [Words.mid(signal_place(sig)), signal_level(sig)])
	return sig


## A beat's signal: its site and crew, STORY_UNDER levels under your reach; the head at full strength, or the depot's convoy.
func _story_signal(beat: int, names: Array) -> Dictionary:
	var b: Dictionary = Data.STORY_BEATS[beat]
	signal_seq += 1
	var convoy: bool = bool(b.get("convoy", false))
	var sig := {"id": signal_seq, "site": int(b["site"]), "zone": int(b["zone"]), "depth": depth_for_level(int(b["site"]), maxi(Data.REACH_START, reach - Data.STORY_UNDER)), "codes": [], "papers": names,
		"head": not convoy, "convoy": false, "convoy_fight": convoy, "line": 0, "story": beat}
	signals.append(sig)
	chron("signal", {"id": signal_seq, "site": int(sig["site"]), "zone": int(sig["zone"]), "depth": int(sig["depth"]), "story": beat, "papers": names.duplicate()})
	log_event(Words.STORY[beat]["made"])
	return sig


## The Radio's remix (25 Oct, after the Treasurer): a signal may be laid on one of the County's places (its host's
## plate and drops, the crew any campaign's), and its head, when it brings one, one of the Issuer's people away from home.
func _remix(sig: Dictionary, over: int) -> void:
	if not county_done():
		return
	if rng.randf() < Data.REMIX_COUNTY_ODDS:
		var c: Dictionary = Data.COUNTY[rng.randi_range(0, Data.COUNTY.size() - 1)]
		sig["county"] = str(c["key"])
		sig["site"] = int(c["site"])
		sig["depth"] = depth_for_level(int(sig["site"]), maxi(Data.REACH_START, reach + over))
	if bool(sig.get("head", false)) and rng.randf() < Data.REMIX_HEAD_ODDS:
		sig["county_head"] = county_head_key(rng.randi_range(0, Data.COUNTY_ZONES.size() - 1))


## A signal's head as the Radio names it: one of the Issuer's people in the remix, else the crew's.
func signal_head_name(sg: Dictionary) -> String:
	if str(sg.get("county_head", "")) != "" and is_county(str(sg["county_head"])):
		return str(Data.county(str(sg["county_head"]))["who"])
	return str(zone_boss(int(sg.get("zone", 0))).get("name", "their head"))


## A signal's place as the Radio names it: a County place's when the remix laid it on one.
func signal_place(sg: Dictionary) -> String:
	if str(sg.get("county", "")) != "" and is_county(str(sg["county"])):
		return str(Data.county(str(sg["county"]))["place"])
	return str(Data.TIERS[int(sg["site"])]["name"])


## The deepest signals in the remix carry issued kit (25 Oct): one won at the reach or past it, now and then, a piece
## at its level comes home.
func _remix_issued(d: int) -> void:
	if not county_done() or d < reach or rng.randf() >= Data.REMIX_ISSUED_ODDS:
		return
	var slot: String = str(Data.ISSUED[rng.randi_range(0, Data.ISSUED.size() - 1)]["slot"])
	var it := issued_piece(slot, d + Data.ISSUED_OVER, true)
	if not stash_room(Items.size(it)):
		return
	issued_serial += 1
	it["serial"] = issued_serial
	stash.append(it)
	_mag_with(it)
	_read(it)
	log_event(Words.COUNTY["remix_issued"] % Items.full_name(it))


func _sig_ints(sg: Dictionary) -> void:
	for k in ["id", "site", "zone", "depth", "line"]:
		sg[k] = int(sg.get(k, 0))
	sg["story"] = int(sg.get("story", -1))


## A signal's codes as a site carries them, [{w, t}]: its papers' at the depth's tier, or as the Radio's crafts left them.
func signal_words(sg: Dictionary) -> Array:
	if sg.has("words"):
		var out: Array = []
		for wd in sg["words"]:
			out.append({"w": str(wd["w"]), "t": int(wd["t"])})
		return out
	var codes: Array = []
	for c in sg["codes"]:
		codes.append({"w": str(c), "t": maxi(1, word_tier_cap(tier_depth(signal_level(sg))))})
	return codes


## The depth site `i` is fought, juiced and counted at: its own, or with a signal on it the depth its level is on the
## hardest site (D3, the review: a level's fight, its words, its loot and its clears the same on every site).
func site_depth(i: int) -> int:
	if not _sig.is_empty() and int(_sig["site"]) == i:
		return tier_depth(lv_at(i, int(depth[i])))
	return int(depth[i])


## A signal's level: its site's at its depth (D3: what the reach counts).
func signal_level(sg: Dictionary) -> int:
	return lv_at(int(sg["site"]), int(sg["depth"]))


## The depth that puts site `i` at level `lv`; never under 2 (depth 1 is the campaign's).
static func depth_for_level(i: int, lv: int) -> int:
	return maxi(Data.SIGNAL_DEPTH, lv - (i - Data.OUTSKIRTS_SITES))     # (BUILD55-A) past the stages: signals and stages never share a depth


## A level's codes' tier, read as the hardest site's depth at it (the Barracks: the tiers' depths as they always were
## on the campaign's last site), so a signal's codes are its level's whatever the site.
static func tier_depth(lv: int) -> int:
	return maxi(1, lv - (Data.TIERS.size() - 1 - Data.OUTSKIRTS_SITES))


## The Radio's crafts on a held signal (15 Oct, signals_radio.png): Tune in, Retune and Twist, as a site's were - laid
## on its site for the craft, the codes it leaves kept on the signal.
const SIGNAL_CRAFTS := ["tune", "retune", "twist"]


func signal_craft_block(k: int, key: String) -> String:
	var sg := signal_at(k)
	if sg.is_empty() or not (key in SIGNAL_CRAFTS):
		return "no such signal"
	if not _sig.is_empty():
		return "The runner is out"
	_sig_on(sg)
	var why: String = word_craft_block(int(sg["site"]), key)
	_sig_off()
	return why


func signal_craft_cost(k: int, key: String) -> int:
	var sg := signal_at(k)
	if sg.is_empty() or not _sig.is_empty():
		return 0
	_sig_on(sg)
	var c: int = word_craft_cost(int(sg["site"]), key)
	_sig_off()
	return c


func signal_craft(k: int, key: String) -> bool:
	if signal_craft_block(k, key) != "":
		return false
	var sg := signal_at(k)
	_sig_on(sg)
	var i: int = int(sg["site"])
	var ok: bool = word_craft(i, key)
	if ok:
		sg["words"] = words[i].duplicate(true)
		sg["sealed"] = sealed[i]
	_sig_off()
	return ok


## A held signal by its place on the Radio, or {}.
func signal_at(k: int) -> Dictionary:
	return signals[k] if k >= 0 and k < signals.size() else {}


## A held signal, off the Radio: its papers stay spent.
func bin_signal(k: int) -> bool:
	if signal_at(k).is_empty():
		return false
	log_event(Words.SIGNAL_BINNED % Words.mid(str(Data.TIERS[int(signals[k]["site"])]["name"])))
	for c in _crew_odds:
		_crew_odds[c].erase(int(signals[k]["id"]))     # the crew's reads of it go with it
	signals.remove_at(k)
	return true


## The signal laid on its site - its depth, its codes at the depth's tier, its crew read by effective() - for a read
## or a run; _sig_off() puts the site back. One at a time.
func _sig_on(sg: Dictionary) -> void:
	var i: int = int(sg["site"])
	sg["was"] = {"depth": depth[i], "words": words[i].duplicate(true), "sealed": sealed[i], "armed": boss_armed.get(i, false)}
	depth[i] = int(sg["depth"])
	words[i] = signal_words(sg)
	sealed[i] = bool(sg.get("sealed", false))
	boss_armed[i] = false
	_sig = sg


func _sig_off() -> void:
	if _sig.is_empty():
		return
	var i: int = int(_sig["site"])
	var was: Dictionary = _sig.get("was", {})
	depth[i] = int(was.get("depth", 1))
	var back: Array = []
	for wd in was.get("words", []):
		back.append({"w": str(wd["w"]), "t": int(wd["t"])})     # through a save the tiers came back floats (the review)
	words[i] = back
	sealed[i] = bool(was.get("sealed", false))
	boss_armed[i] = bool(was.get("armed", false))
	_sig.erase("was")
	_sig = {}


## What a held signal's run brings: its crew's area's materials as shares, and the chance a run brings one. [{}, 0.0].
func signal_materials(k: int) -> Array:
	var sg := signal_at(k)
	if sg.is_empty() or not _sig.is_empty():
		return [{}, 0.0]
	_sig_on(sg)
	var i: int = int(sg["site"])
	var out: Array = [material_split(i), material_odds(i)]
	_sig_off()
	return out


## A held signal as it would run: its site's figures (effective) with it laid on.
func signal_read(k: int) -> Dictionary:
	var sg := signal_at(k)
	if sg.is_empty() or not _sig.is_empty():
		return {}
	_sig_on(sg)
	var e := effective(int(sg["site"]))
	_sig_off()
	return e


## A held signal's odds, read a few dry runs at a time as a site's are (odds_budget, the frame's brake): its own read,
## kept by the signal's id apart from its site's. [odds so far, settled].
var _sig_odds := {}


func signal_odds(k: int) -> Array:
	var sg := signal_at(k)
	if sg.is_empty() or not _sig.is_empty():
		return [0.0, false]
	_sig_on(sg)
	var i: int = int(sg["site"])
	var home = _surv_cache.get(i, null)
	if _sig_odds.has(int(sg["id"])):
		_surv_cache[i] = _sig_odds[int(sg["id"])]
	else:
		_surv_cache.erase(i)
	var o: float = survival(i)
	var done: bool = odds_settled(i)
	_sig_odds[int(sg["id"])] = _surv_cache[i]
	if home != null:
		_surv_cache[i] = home
	else:
		_surv_cache.erase(i)
	_sig_off()
	return [o, done]


## A held signal's odds for another of the crew (21 Oct, Matt: "Hit a signal with 70% shock resist? Switch to your bleed
## paramedic and steam roll it"): that class's runner put out for the read - their level, tree, kit - and back, each
## class's reads kept apart. [odds, settled]; [0, true] for a class not played. `now`: what's read, running none.
var _crew_odds := {}                 # class -> {signal id -> the odds' cache}
var _crew_now := {}                  # "class/signal id" -> [odds, settled], the last read (the screens read it, no swap)
func signal_odds_class(k: int, name: String, now := false) -> Array:
	if name == cls or cls == "":
		return signal_odds_now(k) if now else signal_odds(k)
	if not roster.has(name) or mission != null:
		return [0.0, false]
	var sg := signal_at(k)
	var ck := "%s/%d/%d" % [name, int(sg.get("id", -1)), hash([sg, class_read_key(name, true, false)])]     # the signal as crafted, and the class as a press brings them out (T2: their XP or kit moved, the row stayed)
	if now and _crew_now.has(ck):
		return _crew_now[ck]                 # read once a frame by the shell's budget; the screens take it from here
	var read := func() -> Array:
		var held: Dictionary = _sig_odds
		_sig_odds = _crew_odds.get(name, {})
		var o: Array = signal_odds_now(k) if now else signal_odds(k)
		_crew_odds[name] = _sig_odds
		_sig_odds = held
		return o
	var out: Array = read_as_class(name, read, true, false)     # at the level a press brings them out at (the crew's floor), at their own HP
	if _crew_now.size() > 96:
		_crew_now.clear()                    # as _exp_cache: the keys move with the bench, the old ones never read again
	_crew_now[ck] = out
	return out


## Another class's odds, the one way (30 Oct, refactor 2: the Radio's crew row, the expeditions board and the bot's wall
## rule each read them their own way, with their own key and HP rule, and had drifted apart): `fn` called with `name`'s
## runner out - their level, trees, kit, skills, wounds - on the camp as it is, then everything put back; nothing moves
## but for the moment. `lift`: at the level a press would bring them out at (join_level, the crew's floor) - the Radio's
## row, whose press swaps them in; else at their own, as a lead sets off and stays benched. `rested`: at full HP (a lead
## sets off rested; the bot reads the wall rested); else at their own HP, rested at the lifted level if they were rested at
## their own, as the swap brings them out. The one out (or no class yet) is read as they stand, under the same HP rule.
## Whatever `fn` returns. The reads that keep a result key it by class_read_key.
func read_as_class(name: String, fn: Callable, lift := true, rested := false) -> Variant:
	var swap: bool = name != cls and cls != "" and roster.has(name)
	var jl: int = join_level(name) if lift else 0     # read before the swap, off the other classes as they stand
	var h: Dictionary = _read_as(name) if swap else {}
	var x0: float = xp
	var hp0: float = hp
	var whole: bool = rested or hp >= max_hp() - 0.001
	xp = maxf(xp, Data.xp_for_level(jl)) if jl > 0 else xp
	_stats_dirty()
	if whole:
		hp = max_hp()                          # at the lifted level
	var out = fn.call()
	xp = x0                                    # the bench keeps its own level: the floor's taken on the swap
	_stats_dirty()
	hp = hp0
	if swap:
		_read_back(h)
	return out


## What another class's read hangs on, for the reads that keep one (the crew row's, the board's): the class's runner as
## the crew holds them - their XP, HP (unless read rested), kit by value, trees, skills, wounds, trait, rig - the level a
## press brings them out at when read lifted, and what the camp gives everyone (the atlas, the Yard, the Pitch's and the
## elements' nodes, the ring, the standing, the class's two elements). One key for both (30 Oct, refactor 2).
func class_read_key(name: String, lift: bool, rested: bool) -> int:
	var rr: Dictionary = roster.get(name, {})
	return hash([name, lift, rested, join_level(name) if lift else 0, float(rr.get("xp", 0.0)), -1.0 if rested else float(rr.get("hp", 0.0)), rr.get("equipped", {}),
		rr.get("tree", []), rr.get("skill_slots", []), rr.get("skill_auto", []), Dictionary(rr.get("wounds", {})).keys(), str(rr.get("trait", "")), Array(rr.get("rig", [])).size(),
		atlas, yard_picks, yard_ranks, ring, str(standing)])


## Another class's runner out for a read only (the odds), and back: nothing's moved but for the moment.
func _read_as(name: String) -> Dictionary:
	var h := {"out": _runner_out(), "cls": cls, "pitch": tree.filter(func(id): return is_ring(str(id))), "surv": _surv_cache}     # the crew's: the paragon ring (the web is each runner's own, 3 Nov)
	_runner_in(roster[name])
	tree = tree + h["pitch"]
	_stats_dirty()
	cls = name
	_caches_out()
	return h


func _read_back(h: Dictionary) -> void:
	var tabs = roster[cls].get("tab_items", null) if roster.has(cls) else null
	roster[cls] = _runner_out()                # what the read put back where it was (a dry run restores the rig as a new array)
	if tabs != null:
		roster[cls]["tab_items"] = tabs        # the class's own stash tabs stay with it (the merge's review: a read dropped them)
	_runner_in(h["out"])
	tree = tree + h["pitch"]
	_stats_dirty()
	cls = str(h["cls"])
	_caches_out()
	_surv_cache = h["surv"]


## The crew's classes played, the one out first: the Radio's crew row.
func crew_played() -> Array:
	var out: Array = [cls] if cls != "" else []
	for c in Data.CLASSES:
		if roster.has(c["name"]):
			out.append(c["name"])
	return out


## The odds read so far, without running any (the Radio's card, as odds_now is the Map's).
func signal_odds_now(k: int) -> Array:
	var sg := signal_at(k)
	if sg.is_empty() or not _sig.is_empty() or not _sig_odds.has(int(sg["id"])):
		return [0.0, false]
	_sig_on(sg)
	var i: int = int(sg["site"])
	var c: Array = _sig_odds[int(sg["id"])]
	var out: Array = [float(c[1]), int(c[2]) >= mini(odds_runs(), Data.ODDS_RUNS)] if c[0] == _odds_key(i) else [0.0, false]
	_sig_off()
	return out


## The insurance on a held signal, at its depth (as deploy charges it), or -1 when it can't be insured.
func signal_insure_cost(k: int) -> int:
	var sg := signal_at(k)
	if sg.is_empty() or not _sig.is_empty():
		return -1
	_sig_on(sg)
	var i: int = int(sg["site"])
	var c: int = insure_cost(i) if can_insure(i) else -1
	_sig_off()
	return c


## Run a held signal: laid on its site for the run, gone from the Radio whatever happens.
func deploy_signal(k: int) -> bool:
	var sg := signal_at(k)
	if sg.is_empty() or not can_deploy() or not _sig.is_empty():
		return false
	_sig_on(sg)
	deploy(int(sg["site"]))
	if mission == null:
		_sig_off()
		return false
	signals.remove_at(k)
	mission["signal"] = sg
	if bool(sg.get("convoy", false)) and str(mission.get("event", "")) == "":
		mission["event"] = "convoy"            # the extra: a convoy's crew joins on the way
		mission["event_at"] = rng.randf_range(Data.EVENT_WINDOW[0], Data.EVENT_WINDOW[1])
	chron("signal_run", {"id": int(sg["id"]), "depth": int(sg["depth"])})
	return true


## A signal's run over: beaten (cleared, its head down if it had one) at your reach or past it raises the reach and pays
## a point on the Dial; the site goes back to its campaign self.
func _signal_done(m: Dictionary, died := false) -> void:
	_a55_run_end(m)                           # (BUILD55-A) a head's fight: his site back at its stage; the picks follow
	if not m.has("signal") or _sig.is_empty():
		return
	var d: int = signal_level(_sig)
	var won: bool = bool(m["cleared"]) and not died and not m.get("ghost_pending", false) and not bool(m.get("timed_out", false)) and not (m.has("boss") and bool(m["boss"].get("alive", false)))
	if _sig.has("order"):
		_order_done(won)
		_sig_off()
		return
	chron("signal_done", {"id": int(_sig["id"]), "level": d, "won": won, "grade": int(_sig.get("grade", 0)), "reach": reach, "story": _sig.has("story")})     # the grade and the reach it met (the pass, 20 Oct: the signals' gate)
	if won:
		_signal_papers_home(m)                 # beaten ones only (18 Oct, Matt)
		_remix_issued(d)
	if won and d >= reach and int(_sig.get("grade", 0)) != 1:     # a faint one never moves it (20 Oct; at the first reach its band is the reach)
		reach += 1                             # a level a win (D25: d + 1 let a roll over the reach jump it two and three at a time - the reach to 30-44 by hour 12, then hours at the kit's wall)
		atlas_points += 1
		log_event(Words.SIGNAL_REACH % [d, reach])
	elif not won:
		log_event(Words.SIGNAL_LOST)
	var beat: int = int(_sig.get("story", -1))
	if won and beat >= 0 and beat == story_now():
		chron("story", {"beat": beat})
		if not story_at.has(beat):
			story_at[beat] = played_s / 3600.0
		log_event(Words.STORY[beat]["won"])
		var opened_before: Array = Data.CLASSES.map(func(c): return class_open(str(c["name"])))
		story_beat = mini(story_beat + 1, Data.STORY_BEATS.size())
		_say_unlocks(opened_before)
		if rebuild_open():
			log_event(Words.REBUILD["open"])      # Kev's last line opens the rebuild (18 Oct)
	elif won and rng.randf() < Data.STORY_DROP * (Data.FX["yard/lorry_watch"] if yard_has("lorry_watch") else 1.0):     # the Radio's Lorry watch
		_story_find()
	_sig_off()


## A signal beaten brings SIGNAL_PAPERS_HOME papers home at the least (18 Oct, Matt: "at a minimum a signal run needs
## to provide 2 of low quality"; "only beaten ones"): what it found counts, plain ones (common or uncommon) make up the rest, to the pile.
func _signal_papers_home(m: Dictionary) -> void:
	var found := 0
	for it in m.get("found", []):
		if is_pile_paper(it) and story_of(it) < 0:
			found += 1                         # Kev's don't count: they're the story's, not the drawer's
	var pages: Array = signal_pages(int(m["t"]["depth"]), str(Data.TIERS[int(m["t"]["tier"])]["name"]))
	var added: Array = []
	for k in range(maxi(0, signal_papers_min() - found)):
		if pages.is_empty():
			break
		var it := _plain(Data.PAPER, str(pages[rng.randi_range(0, pages.size() - 1)]))
		it["rarity"] = rng.randi_range(0, 1)
		papers.append(it)
		_read(it, true)
		added.append(str(it["base"]).to_lower())
	if not added.is_empty():
		log_event(Words.SIGNAL_PAPERS % ", ".join(added))


## The papers a beaten signal brings home at the least: SIGNAL_PAPERS_HOME, one more with the Stash's Filing cabinet.
func signal_papers_min() -> int:
	return Data.SIGNAL_PAPERS_HOME + (Data.FX["yard/filing_cabinet"] if yard_has("filing_cabinet") else 0)


## The papers a signal's top-up can be (the review): the book's pages found at this depth and this site, as a find
## would be - no deep paper early, none of another site's own.
func signal_pages(at_depth: int, site: String) -> Array:
	var out: Array = []
	for nm in book_pages():
		var home := Items.exclusive_to(nm)
		if int(Items.base_named(Data.PAPER, nm).get("depth", 0)) <= at_depth and (home == "" or home == site):
			out.append(nm)
	return out


## A signal beaten brings home the next of the beat's papers not held, now and then (STORY_DROP).
func _story_find() -> void:
	var held: Array = story_held()
	for nm in story_papers(story_now()):
		if not (nm in held):
			var it := _plain(Data.PAPER, nm)
			papers.append(it)                 # home with the run, to the Radio's pile: Kev's
			_read(it)
			log_event(Words.STORY[story_now()]["found"] % [nm, held.size() + 1])
			return


func on_mission() -> bool:
	return mission != null


func searching() -> bool:
	return mission != null and mission["cleared"]


func can_deploy() -> bool:
	return mission == null and hp > 0.0 and (not away() or _repeat_going)     # away on a repeat (29 Oct): the gate's the repeat's


func can_deploy_to(i: int) -> bool:
	return can_deploy() and tier_open(i) and (int(depth[i]) > Data.STAGES or _a55_head == i or (not _sig.is_empty() and int(_sig["site"]) == i) or stage_open(i, int(depth[i])))     # (BUILD55-A) the stage's own gates


## Seconds a tier's fight should take at the operator's damage, for the card.
## The primary's rounds against a site's fight (16 Oct, Matt's dry shotgun at the Bank): [in the rig, the fight wants] -
## the fight's estimate at the gun's rate of fire - when the rig's short; [] when it isn't, or the gun takes none. The rig
## read is the one that goes out: it tops up from the stash coming home.
func rounds_short(i: int) -> Array:
	# what goes out (the reviewer on m32c, 3): a dry run of the gate's fill, grade by grade - the rig's magazines and the
	# stash's the top-up may still pack - then the boxes the site's plan packs off what's left (BUILD46-R: rounds_read)
	var r: Array = rounds_read(i)
	return r if not r.is_empty() and int(r[0]) < int(r[1]) else []


func estimate(i: int) -> float:
	var t := effective(i)
	return t["pool"] * t["hp"] / (dps() * edge_read(t) * pace() * t["pace"])     # the gun type's edge as it pays there (29 Oct)


## The chance of clearing the fight alive from here, from SURVIVAL_RUNS dry
## runs with the swing in. Cached until the figures it depends on change.
## The shell sets a budget: that many dry runs a call, the rest on later
## calls, so the Runs screen settles over a few frames rather than hanging
## while nine tiers read at once. The bots and the tests leave it at 0: all at once.
var odds_budget := 0
## The balance gate's cap on a read's dry runs (8 Oct, the pass at an hour): the lookout's glasses read sixty
## a site for the player's number, and the bot's verdict at PUSH is the same at twenty-four. 0, no cap.
var odds_runs_max := 0
## The shell's other brake (7 Oct, the Runs screen's lag): no new dry run starts once `odds_time_ms` has gone
## since `odds_frame_start()`; one always runs, so a read never stalls. 0, no brake. And a read that is
## plainly settled settles early: EARLY_RUNS all alive with HP never under half, or all dead, reads as
## the whole lookout's.
var odds_time_ms := 0.0
var _odds_t0 := 0
const EARLY_RUNS := 8
const EARLY_FEW := 4
const EARLY_FEW_HP := 0.7
var _dry_min_hp := 1.0               # the last dry run's lowest HP, as a share of the max
## Where the time goes (8 Oct, the pass at an hour): counts and microseconds the balance gate prints. Cheap
## enough to leave on: a few adds a tick.
var prof := {"surv_calls": 0, "surv_reads": 0, "surv_us": 0, "dry_runs": 0, "dry_ticks": 0, "snap_us": 0, "real_ticks": 0, "real_us": 0, "dry_timeouts": 0}


func odds_frame_start() -> void:
	_odds_t0 = Time.get_ticks_usec()


func _odds_time_up() -> bool:
	return odds_time_ms > 0.0 and (Time.get_ticks_usec() - _odds_t0) / 1000.0 >= odds_time_ms

## What's worn, by id: a swap that moves only a resist or a rule still reads the odds again.
func _kit_ids() -> Array:
	var out := []
	for s in Data.SLOTS:
		out.append(equipped[s]["id"] if equipped[s] != null else -1)
	return out


func _odds_key(i: int) -> Array:
	# HP to the nearest tenth of the bar, so a rest doesn't recompute it every second (rounded: a rest to full that
	# lands a hair under read as nine tenths and re-read); the figures in steps of 2%, so a paragon level or an
	# affix's hair doesn't re-read the odds (8 Oct, the pass at an hour: nearly every pick re-read)
	var common: Array = _odds_key_common()
	return common + [depth[i], str(words[i]), fight_weather_of(i), boss_armed.get(i, false), int(clear_level.get(i, 0)), int(clear_level.get(stage_key(i, int(depth[i])), 0)), _a55_head == i,     # (BUILD55-A) the stage's tax floor, the head's fight; the first clear sets the tax's floor (21 Oct)
		int(_sig["id"]) if not _sig.is_empty() and int(_sig["site"]) == i else 0,     # a signal laid on the site reads apart from it (15 Oct)
		str(rounds_plans.get(str(i), rounds_plans.get("camp", ""))),     # the rounds the site's plan packs (BUILD46-R)
		str(wagers_read(i).map(func(w): return str(w["cond"])))]     # Kev's wagers taken on its run (BUILD48 A, item 17)


## The key's runner half, the same for every site: worked once a frame while the shell reads the odds (16 Oct: twelve
## sites' keys a frame - each a dps(), an armour(), a max_hp() - ate the 5 ms before the City's dry runs got any, on
## Matt's machine), else every call. Nothing the key reads moves inside one frame's read: a dry run puts it all back.
var _key_memo := []
var _key_memo_t := -1
## And the shell's paint (19 Oct, Matt: the Map lagged after Glasses): a screen asks every site's odds_settled and
## odds_now ten times a second, a key each - 25 ms of dps() and armour() a paint on Matt's save. Inside a paint
## nothing moves, so the shell opens a scope (odds_scope) and the key is worked once in it.
var _scope := 0
var _scope_memo := []
func odds_scope(on: bool) -> void:
	_scope = 1 if on else 0                # no nesting: opening resets, so a paint cut short by an error can't leave it stuck
	_scope_memo = []


## Each memo is [the runner's key and HP it was worked for, the key]: another class read inside the frame or the paint
## (a crew row, a lead), or the HP set whole for the repeat's gate, works its own (30 Oct, refactor 1: was cleared by hand
## in _caches_out and _whole).
func _odds_key_common() -> Array:
	var who := [runner_key(), hp]
	if _scope > 0 and not _scope_memo.is_empty() and _scope_memo[0] == who:
		return _scope_memo[1]
	if odds_time_ms > 0.0 and _key_memo_t == _odds_t0 and not _key_memo.is_empty() and _key_memo[0] == who:
		return _key_memo[1]
	prof["key_common"] = int(prof.get("key_common", 0)) + 1
	var k: Array = [int(round(hp * 10.0 / maxf(max_hp(), 1.0))), _odds_bucket(max_hp()), _odds_bucket(dps()), _odds_bucket(armour()), _odds_bucket(pace() * 100.0), str(standing), tree.size(), rig.size(), campaign_done(), str(atlas), is_night(), wounds.keys(), _kit_ids(), str(ring), level(), str(skill_slots), str(skill_auto)]     # the skills slotted and their rules (T1: a slotted skill left the site's old odds); the board: a resist point moves no bucket (the review); the level: the campaign's fight moves with it (21 Oct); the class's two (28 Oct, the review: a close moves no tree)
	if odds_time_ms > 0.0:
		_key_memo = [who, k]
		_key_memo_t = _odds_t0
	if _scope > 0:
		_scope_memo = [who, k]
	return k


## What the runner's odds hang on, as a cheap figure for a screen's "has anything moved" (BUILD45, main._odds_sig): the
## live guard's hash of the state it last saw - the runner whole, the wounds, the stash's count, the Yard, the lorries,
## the elements, the sky, the front, the standing, the atlas, the Issue - worked each frame by advance() already. A
## read puts everything back, so it reads the same after one (stat_v doesn't: a crew read bumps it). Worked here when
## the memo's switched off.
func odds_state() -> int:
	if live_memo_off:
		return hash([runner_parts(), wounds, stash.size(), _removed, yard_picks, yard_ranks, lorries, weather, is_night(), front_tier(),
			standing, atlas, issued, mission != null])
	return _live_state_at


## A figure in steps of 2%: the odds don't move for less.
func _odds_bucket(x: float) -> int:
	return int(log(maxf(x, 1.0)) / log(1.02))


## The odds as read so far, without running any: what a screen shows while the shell reads them a few
## milliseconds a frame. 0 until the first dry run of a fresh read.
func odds_now(i: int) -> float:
	if _surv_cache.has(i) and _surv_cache[i][0] == _odds_key(i):
		return _surv_cache[i][1]
	return 0.0


func survival(i: int) -> float:
	var p0 := Time.get_ticks_usec()
	prof["surv_calls"] += 1
	var key := _odds_key(i)
	var runs: int = odds_runs()
	if odds_runs_max > 0:
		runs = mini(runs, odds_runs_max)
	var c: Array
	if _surv_cache.has(i) and _surv_cache[i][0] == key:
		c = _surv_cache[i]
		if c[2] >= runs:
			prof["surv_us"] += Time.get_ticks_usec() - p0
			return c[1]
	else:
		prof["surv_reads"] += 1
		var r := RandomNumberGenerator.new()
		r.seed = hash(key) + i
		c = [key, 0.0, 0, 0, r, 1.0]         # key, odds so far, runs done, alive, the dice, the lowest HP share seen
		_surv_cache[i] = c
	var to_do: int = runs - c[2] if odds_budget <= 0 else mini(odds_budget, runs - c[2])
	for k in range(to_do):
		if k > 0 and _odds_time_up():
			break
		_dry_last = {}                        # the tally pairs with this run alone (the review: a probe's run could sit there)
		var went: int = _dry_run_stepped(i, c)
		if went < 0:
			break                             # parked at the frame's end (BUILD43): it goes on in the next
		if went == 1:
			c[3] += 1
		c[2] += 1
		_tally(i, key)
		c[5] = minf(float(c[5]), _dry_min_hp)
		if c[2] == EARLY_FEW and (c[3] == EARLY_FEW and float(c[5]) >= EARLY_FEW_HP or c[3] == 0) and odds_runs_max > 0 and not boss_armed.get(i, false):
			c[3] = runs if c[3] > 0 else 0   # (15 Oct, refactor A4) the gate's read only: four clean - none under 70% - or four dead says it sooner; the Map's own number reads on
			c[2] = runs
			break
		if c[2] == EARLY_RUNS and (c[3] == EARLY_RUNS and float(c[5]) >= 0.5 or c[3] == 0):
			c[3] = runs if c[3] > 0 else 0   # plainly settled: the rest of the lookout's runs would say the same
			c[2] = runs
			break
		if odds_runs_max > 0 and c[2] >= EARLY_RUNS and c[2] - c[3] >= 3 and not boss_armed.get(i, false):
			# the gate's read (8 Oct): three down by the eighth can't reach the bot's PUSH over twenty-four, so the
			# read stands as it is; a boss's read runs on, the lorry is taken at better than even
			c[3] = int(round(float(c[3]) / float(c[2]) * runs))     # the share so far, as the lookout's count
			c[2] = runs
			break
	c[1] = float(c[3]) / maxf(1.0, c[2])
	prof["surv_us"] += Time.get_ticks_usec() - p0
	return c[1]


## The Map's read steps a dry run across frames (BUILD43): the shell sets it around the reads it makes in its few
## milliseconds a frame (main._read_odds), and nothing else does - the bot, the reads and the gate run each whole.
var odds_step := false


## One dry run of the read `c`: 1 back, 0 lost, -1 parked. With odds_step and a frame's time set, a run stops when
## the time's up and is kept on the read itself (c[6]) for the next call; one parked there is taken up first, and
## run to its end when the call isn't the Map's (the gate's read at deploy).
func _dry_run_stepped(i: int, c: Array) -> int:
	var stepping: bool = odds_step and odds_time_ms > 0.0
	var job = c[6] if c.size() > 6 else null
	if job != null and int(job["who"]) != runner_key():
		(c[4] as RandomNumberGenerator).state = int(job["dice"])     # the runner's moved under a parked run (a piece by value, a
		job = null                                                   # node): it starts again, on the dice it started on
		c[6] = null
	if job == null:
		if not stepping:
			return 1 if _dry_run(i, c[4]) else 0
		var who := runner_key()
		var dice: int = (c[4] as RandomNumberGenerator).state
		job = _dry_begin(i, c[4])
		job["who"] = who
		job["dice"] = dice
		if _odds_time_up():
			_dry_park(job)                    # begun at the frame's end (BUILD45, perf44 #7: the begin and a late fight's first
			if c.size() > 6:                  # tick, 2 and 4 ms, were one 6-8 ms slice): its ticks wait for the next frame
				c[6] = job
			else:
				c.append(job)
			return -1
	else:
		c[6] = null
		_dry_resume(job)
	if not _dry_steps(job, (_odds_t0 + int(odds_time_ms * 1000.0)) if stepping else -1):
		_dry_park(job)
		if c.size() > 6:
			c[6] = job
		else:
			c.append(job)
		return -1
	return 1 if _dry_finish(job) else 0


## What the dry runs saw (23 Oct, parked item 7, Matt: "we need to do a better job of telling players why the odds
## are 0% and what they can do to bump things up"): a tally a site, kept with the odds' key - the runs read, how many
## came back, how many were killed and how many ran out of time, the seconds and the heads down when the lost ones
## ended, what reached HP and by what type, the lowest HP seen.
var _odds_tally := {}
var _dry_last := {}


func _tally(i: int, key: Array) -> void:
	if _dry_last.is_empty():
		return
	var tl: Dictionary = _odds_tally.get(i, {})
	if tl.is_empty() or tl["key"] != key:
		tl = {"key": key, "runs": 0, "alive": 0, "killed": 0, "timed": 0, "lost_s": 0.0, "lost_down": 0, "taken": 0.0, "fight_s": 0.0, "taken_by": {}, "pool": 0, "min_hp": 1.0}
		_odds_tally[i] = tl
	var d: Dictionary = _dry_last
	tl["runs"] += 1
	tl["pool"] = int(d["pool"])
	tl["fight_s"] += float(d["elapsed"])
	tl["taken"] += float(d["taken"])
	tl["min_hp"] = minf(float(tl["min_hp"]), float(d["min_hp"]))
	for ty in d["taken_by"]:
		tl["taken_by"][ty] = float(tl["taken_by"].get(ty, 0.0)) + float(d["taken_by"][ty])
	if d["alive"]:
		tl["alive"] += 1
	else:
		if d["timed"]:
			tl["timed"] += 1
		else:
			tl["killed"] += 1
		tl["lost_s"] += float(d["elapsed"])
		tl["lost_down"] += int(d["kills"])
	_dry_last = {}


## The site before a site: the one before it in its zone, else the zone before's last; -1 for the first of all (23 Oct,
## the Map's green chip: "grind the site before").
func site_before(i: int) -> int:
	var z: int = int(Data.TIERS[i]["zone"])
	var tiers: Array = Data.ZONES[z]["tiers"]
	var k: int = tiers.find(i)
	if k > 0:
		return int(tiers[k - 1])
	if z > 0:
		return int(Data.ZONES[z - 1]["tiers"].back())
	return -1


## The tally as it stands for a site's current read, {} before any run of it.
func odds_read(i: int) -> Dictionary:
	var tl: Dictionary = _odds_tally.get(i, {})
	if tl.is_empty() or tl["key"] != _odds_key(i) or int(tl["runs"]) == 0:
		return {}
	return tl


## Why a site reads as it does, in the runner's own figures (23 Oct, parked item 7): how the lost runs ended (killed
## or out of time, at what second, with how many heads down), what reached HP a second and by what type, and what
## would close the gap - the HP, the armour, the damage a second, the resist - each alone, from the fight's length
## as the card has it (estimate) and what reached HP over the runs. {} with nothing read.
func odds_gap(i: int) -> Dictionary:
	var r: Dictionary = odds_read(i)
	if r.is_empty():
		return {}
	var lost: int = int(r["killed"]) + int(r["timed"])
	var out := {"runs": int(r["runs"]), "alive": int(r["alive"]), "killed": int(r["killed"]), "timed": int(r["timed"]), "pool": int(r["pool"]), "min_hp": float(r["min_hp"])}
	if lost > 0:
		out["lost_s"] = float(r["lost_s"]) / lost
		out["lost_down"] = float(r["lost_down"]) / lost
	var rate: float = float(r["taken"]) / maxf(float(r["fight_s"]), 1.0)
	out["rate"] = rate
	var top := ""
	var total := 0.0
	for ty in r["taken_by"]:
		total += float(r["taken_by"][ty])
		if top == "" or float(r["taken_by"][ty]) > float(r["taken_by"][top]):
			top = str(ty)
	out["top_type"] = top
	out["top_share"] = (float(r["taken_by"][top]) / total) if top != "" and total > 0.0 else 0.0
	out["phys_share"] = (float(r["taken_by"].get("physical", 0.0)) / total) if total > 0.0 else 0.0
	var el := ""                                        # the element that did most, armour's counterpart
	for ty in r["taken_by"]:
		if str(ty) != "physical" and (el == "" or float(r["taken_by"][ty]) > float(r["taken_by"][el])):
			el = str(ty)
	out["el_type"] = el
	out["el_share"] = (float(r["taken_by"][el]) / total) if el != "" and total > 0.0 else 0.0
	if lost == 0 or rate <= 0.0:
		return out
	var fight_s: float = estimate(i)
	var heals: float = regen_rate() * fight_s
	for it in rig:
		if Items.is_medical(it):
			heals += med_heal(it)
	var need: float = rate * fight_s
	var have: float = max_hp() * (1.0 - BAIL) + heals
	if int(r["timed"]) > int(r["killed"]):
		out["dps_need"] = int(ceil(dps() * fight_s / maxf(clock_of(i), 1.0)))     # the fight inside the clock
		return out
	if have >= need:
		return out
	var f: float = have / need                        # what's taken must come down to this share of itself
	out["hp_need"] = int(ceil((need - heals) / (1.0 - BAIL)))
	out["dps_need"] = int(ceil(dps() / f))             # or the fight that much shorter
	var p: float = float(r["taken_by"].get("physical", 0.0)) / maxf(total, 0.001)
	if p > 0.0:
		var fp: float = (f - (1.0 - p)) / p             # the physical part's share of itself, the rest as it is
		if fp > 0.0:
			out["armour_need"] = int(ceil((armour() + armour_k()) / fp - armour_k()))
	if el != "" and total > 0.0:
		var e: float = float(r["taken_by"][el]) / total
		var fe: float = (f - (1.0 - e)) / e
		if fe > 0.0:
			var res_need: float = 1.0 - fe * (1.0 - resist(el))
			if res_need * 100.0 <= Data.RESIST_CAP:
				out["resist_type"] = el
				out["resist_need"] = int(ceil(res_need * 100.0))
	return out


## Whether the odds for a tier have read enough to show (19 Oct, Matt: Glasses' sixty runs kept the Map on "reading
## the odds"): the plain lookout's twenty-four, or all of them when fewer; the rest read on behind the number.
func odds_ready(i: int) -> bool:
	var runs: int = odds_runs() if odds_runs_max <= 0 else mini(odds_runs(), odds_runs_max)
	return _surv_cache.has(i) and _surv_cache[i][0] == _odds_key(i) and _surv_cache[i][2] >= mini(runs, Data.ODDS_RUNS)


## The Map's last read a site (BUILD48 A, parked item 3; Matt: "just calculate odds when a place is clicked on and keep
## the last read odds for places not selected"): the shell reads the picked place alone and keeps each place's read here
## as it comes in (odds_keep); a pin not picked shows it - in its colour while nothing it hangs on has moved, dimmed once
## the kit, the level, the HP or the place has (its odds key no longer the read's). Not saved: a loaded camp's pins wait
## for their first pick.
var _odds_last := {}


## Keeps site `i`'s read, once it has read enough to show (odds_ready).
func odds_keep(i: int) -> void:
	if odds_ready(i):
		_odds_last[i] = [_surv_cache[i][1], _surv_cache[i][0]]


## Site `i`'s last read kept: [odds, current (read under the odds key as it is now)], or [] for none.
func odds_last(i: int) -> Array:
	var l = _odds_last.get(i, null)
	if l == null:
		return []
	return [float(l[0]), l[1] == _odds_key(i)]


## Whether the odds for a tier are fully read (the shell shows them dimmer until they are).
func odds_settled(i: int) -> bool:
	var runs: int = odds_runs() if odds_runs_max <= 0 else mini(odds_runs(), odds_runs_max)     # the read's cap as survival() runs it (D13 review)
	return _surv_cache.has(i) and _surv_cache[i][0] == _odds_key(i) and _surv_cache[i][2] >= runs


## The fight alone, run through the real fight code on a scratch mission with
## nothing kept - the same rates, rules, dots, keystones and meds as a run -
## DRY_STEP seconds at a time: true if it ends with HP left. The state goes
## back as it was: HP, XP, the rig, the log, the dice.
## 1 s, the live fight's own step (2 Nov, BUILD45 bug 1, probe45 #1): at 2 s a gang killed inside the first tick died
## before it landed a hit - the Scrapper's Distribution Centre read 1.00 and died live 5 runs in 6.
const DRY_STEP := 1.0
const DRY_TICKS := int(900.0 / DRY_STEP)     # fifteen minutes of fighting, at the step
const BAIL := 0.25                   # the HP a player (and the bots) get out at: the odds count that as lost
func _dry_run(i: int, r: RandomNumberGenerator) -> bool:
	var job := _dry_begin(i, r)
	_dry_steps(job, -1)
	return _dry_finish(job)


## A dry run in three parts (BUILD43, perf43's cause 4: one of 17-50 ms couldn't be split, and the Map's frames ran
## over their 5 ms of odds): _dry_run calls them back to back, as it always ran; the Map's read (odds_step) parks one
## at its frame's end (_dry_park) and takes it up in the next (_dry_resume) - the same ticks on the same dice in the
## same order, so the odds read the same. The job: the live state kept, the scratch mission, the ticks so far.
func _dry_begin(i: int, r: RandomNumberGenerator) -> Dictionary:
	var p0 := Time.get_ticks_usec()
	prof["dry_runs"] += 1
	var t := effective(i)
	var keep := {"hp": hp, "xp": xp, "rig": rig.duplicate(true), "events": events.duplicate(true), "mission": mission,
		"rng": rng, "promised": promised, "training_points": training_points, "best_level": best_level, "insure_next": insure_next, "events_total": events_total}
	prof["snap_us"] += Time.get_ticks_usec() - p0
	var live_kept: Array = _dry_live_out()
	rng = r
	if not night_on():
		_yard_setting_off()                       # the Charger and the Field kit read in the odds too (kept and put back above); never at a night's break, where the runner stands as they are (fix 50)
	var pool: int = int(t["pool"]) - (Data.FX["node/trapline.heads"] if has_node("trapline") or has_node("snare_and_wait") else 0) - (Data.FX["joint/poacher_frost.heads"] if has_joint("poacher_frost") else 0) - (Data.FX["yard/flares.heads"] if yard_has("flares") else 0)
	var m := {
		"tier": i, "t": t, "remaining": maxi(1, pool), "target_hp": float(t["hp"]), "kills": 0, "found": a51_dry_found(i), "insured": false, "clock": clock_budget(t),
		"left": 0, "cash": 0.0, "xp": 0.0, "elapsed": 0.0, "hp_start": hp, "cleared": false,
		"search": 0.0, "searches": 0, "patrol_timer": 0.0, "patrols": 0, "last_incoming": 0.0,
		"using": null, "meds_used": 0, "fresh": true, "swapped": 0, "chill_t": Data.FX["joint/poacher_frost.chill_s"] if has_joint("poacher_frost") else 0.0, "event": "", "event_at": -1.0, "dry": true,
	}
	_combo_warm(m)                            # the odds read the warm start too
	_a55_mission_marks(m, i)                  # (BUILD55-A) the stage, for the finds
	if t.has("boss"):
		m["boss"] = _boss_entry(t["boss"])
		m["boss_queue"] = []
		for q in t.get("boss_queue", []):
			m["boss_queue"].append(_boss_entry(q))
		m["convoy"] = t.get("convoy", false)
	_wagers_dry(m, wagers_read(i))            # Kev's wagers taken on this run's (BUILD48 A, item 17): the odds read the fight they make
	# no run event in the odds (1 Nov, run events): they come in the lull after the clear, where a dry run has ended, and
	# a threat is a choice, not the run's fight; the odds roll none and move no dice for one. A signal's convoy still
	# joins the fight it comes into (D17)
	if not _sig.is_empty() and int(_sig["site"]) == i and bool(_sig.get("convoy", false)) and str(m.get("event", "")) == "":
		m["event"] = "convoy"                  # a signal's convoy, as deploy_signal sets it when nothing else is on (D17: the odds left it out)
		m["event_at"] = rng.randf_range(Data.EVENT_WINDOW[0], Data.EVENT_WINDOW[1])
	mission = m
	_dry_rules = _snapshot_rules()
	_dry_memo = {}
	_dry_on = true
	_gang_arrives(m)                          # Guard at the first gang, as a run (12 Oct); after the memo's reset (the review)
	_dry_min_hp = 1.0
	return {"keep": keep, "m": m, "pool": pool, "guard": 0, "elapsed": elapsed, "live_elapsed": elapsed, "live_memo": live_kept}


## The run's ticks, until it ends or the clock passes `until_us` (-1: to its end). True when it's ended. At least one
## tick a call, so a parked run always moves on.
func _dry_steps(job: Dictionary, until_us: int) -> bool:
	var m: Dictionary = job["m"]
	var guard_v: int = job["guard"]
	var n := 0
	while guard_v < DRY_TICKS and not m.get("dead", false):    # fifteen minutes of fighting is a loss
		if until_us >= 0 and n > 0 and Time.get_ticks_usec() >= until_us:
			job["guard"] = guard_v
			return false
		n += 1
		_tick(DRY_STEP)
		prof["dry_ticks"] += 1
		_dry_min_hp = minf(_dry_min_hp, hp / maxf(max_hp(), 1.0))
		if hp < max_hp() * BAIL:
			m["dead"] = true                 # a quarter left is where anyone sensible gets out: that run's lost too
		if m.get("dead", false):
			break
		var boss_alive: bool = m.has("boss") and m["boss"]["alive"]
		if m["remaining"] <= 0 and not boss_alive:
			break
		# a player who patches up under 40%, like the Use button
		if m["using"] == null and hp < max_hp() * 0.4 and not first_med().is_empty():
			use_med(first_med()["id"])
		guard_v += 1
	job["guard"] = guard_v
	return true


func _dry_finish(job: Dictionary) -> bool:
	var m: Dictionary = job["m"]
	var guard_v: int = job["guard"]
	var pool: int = job["pool"]
	var keep: Dictionary = job["keep"]
	var alive: bool = not m.get("dead", false) and hp > 0.0 and guard_v < DRY_TICKS     # out of time reads as dead
	_dry_last = {"alive": alive, "timed": not alive and (m.get("timed_out", false) or guard_v >= DRY_TICKS), "kills": int(m["kills"]), "pool": maxi(1, pool),
		"elapsed": float(m["elapsed"]), "taken": float(m.get("taken", 0.0)), "taken_by": m.get("taken_by", {}), "min_hp": _dry_min_hp}     # for the tally (23 Oct)
	_dry_on = false
	hp = keep["hp"]
	xp = keep["xp"]
	rig = keep["rig"]
	events = keep["events"]
	mission = keep["mission"]
	rng = keep["rng"]
	promised = keep["promised"]
	training_points = keep["training_points"]
	best_level = keep["best_level"]
	insure_next = keep["insure_next"]
	events_total = keep["events_total"]
	elapsed = job["live_elapsed"]
	_dry_live_in(job)
	return alive


## The live stat memo through a dry run (BUILD45, perf44 #7): put by as the run starts or takes up, a fresh one for its
## ticks, and back when it stops - the live state is back as it was, so what the memo held is still so. Before, every
## dry slice cleared it (the run's HP and rig moved the ctx), and the next live read worked dps() and the rest afresh:
## ~1.8 ms of a late save's frame, each frame the odds read.
func _dry_live_out() -> Array:
	var kept: Array = [_live_memo, _live_ctx_at]
	_live_memo = {}
	return kept


func _dry_live_in(job: Dictionary) -> void:
	var kept: Array = job.get("live_memo", [])
	if kept.size() == 2:
		_live_memo = kept[0]
		_live_ctx_at = kept[1]
	job.erase("live_memo")


## What a dry run swaps in for its ticks: the keep's (the runner's HP, XP, rig, log, the run, the dice), and the dry
## memo's own. A parked job holds its own of these; the live ones go back while it waits.
const DRY_KEPT := ["hp", "xp", "rig", "events", "mission", "rng", "promised", "training_points", "best_level", "insure_next", "events_total"]
const DRY_OWN := ["_dry_rules", "_dry_memo", "_dry_min_hp"]


## A dry job stops at the frame's end: its state put by, the live state back as it was when it took up.
func _dry_park(job: Dictionary) -> void:
	var own := {}
	for k in DRY_KEPT + DRY_OWN:
		own[k] = get(k)
	job["own"] = own
	_dry_memo = {}                            # the live game's own while it waits: a clear there leaves the run's alone (review 43, 6)
	_dry_rules = {}
	_dry_on = false
	for k in DRY_KEPT:
		set(k, job["keep"][k])
	elapsed = job["live_elapsed"]
	_dry_live_in(job)


## And takes up again: the live state kept as it is now (what goes back at its end or its next stop), its own put in,
## the clock held where it started (a run reads one moment, as one frame's run did).
func _dry_resume(job: Dictionary) -> void:
	var keep := {}
	for k in DRY_KEPT:
		keep[k] = get(k)
	job["keep"] = keep
	job["live_elapsed"] = elapsed
	job["live_memo"] = _dry_live_out()
	elapsed = job["elapsed"]
	for k in DRY_KEPT + DRY_OWN:
		set(k, job["own"][k])
	job.erase("own")
	_dry_on = true


func deploy(i: int) -> void:
	if not can_deploy_to(i):
		return
	var wager_gate: bool = (not _sig.is_empty() and int(_sig["site"]) == i) or f55_first_clear(i) or _a55_head == i or bool(boss_armed.get(i, false))     # Kev's wagers go only on a run whose gate is open as it sets off; (FIX55) a stage's first clear, the head's fight
	if not candidates.is_empty():
		choose_runner(0)                  # nobody picked: the first one stays
	var odds_seen: float = _gate_odds(i)     # what the Runs card read at the gate, settled (12 Oct: the record; a part-read card logs -1); before the top-up, whose pouches re-key the odds (23 Oct)
	if not _night_going:
		_top_up(i if _repeat_going else -1, i)    # the worn guns' rounds and the meds from the stash, into the rig's room (16 Oct): before the insurance; a repeat's for its site (S9); the site's plan (BUILD46-R)
	var gate_split: Dictionary = {} if _dry_on else damage_split()     # the one figure as it went out, for the record (the review: at the end a dry gun reads low)
	_dry_memo.clear()                     # the run reads the kit as it stands at the gate (fast_memo)
	_stats_dirty()
	_memo_age = 0.0
	var t := effective(i)
	var sig_head: bool = not _sig.is_empty() and int(_sig["site"]) == i     # a signal's head comes with it: the papers paid
	if t.has("boss") and not sig_head and not (t.get("boss_walks", false) and not boss_armed.get(i, false)):
		var cost := boss_cost(i)
		if notes < cost:
			return
		notes -= cost
		if cost > 0 and i < boss_paid.size() and not (depth[i] in boss_paid[i]):
			boss_paid[i].append(depth[i]) # Long memory reads it: paid once a depth
		boss_armed[i] = false             # one run, like the insurance: the fight is this run's, and the notes are the run's too; arm him again to go back
		_surv_cache.erase(i)
	var insured := false
	if insure_next and can_insure(i):
		cash -= insure_cost(i)
		insured = true
		log_event(Words.LOG["insured"] % [_cash_words(insure_cost(i)), Words.FENCE["insured"]])
	insure_next = false
	if not _night_going:
		_yard_setting_off()                       # before the run's record of its starting HP; never a night's next link (BUILD50 N)
	var pool: int = int(t["pool"]) - (Data.FX["node/trapline.heads"] if has_node("trapline") or has_node("snare_and_wait") else 0) - (Data.FX["joint/poacher_frost.heads"] if has_joint("poacher_frost") else 0) - (Data.FX["yard/flares.heads"] if yard_has("flares") else 0)
	mission = {
		"tier": i, "t": t, "remaining": maxi(1, pool), "target_hp": float(t["hp"]), "kills": 0, "found": [], "insured": insured, "clock": clock_budget(t), "clock_max": clock_budget(t),
		"left": 0, "cash": 0.0, "xp": 0.0, "elapsed": 0.0, "hp_start": hp, "cleared": false, "odds_seen": odds_seen,
		"split_gate": [float(gate_split.get("total", 0.0)), float(gate_split.get("dot", 0.0))], "wear_gate": wearable_level(),
		"search": 0.0, "searches": 0, "patrol_timer": 0.0, "patrols": 0, "last_incoming": 0.0,
		"using": null, "meds_used": 0, "fresh": true, "swapped": 0, "chill_t": Data.FX["joint/poacher_frost.chill_s"] if has_joint("poacher_frost") else 0.0,
	}
	if gate_box_on(i) and not _night_going:     # never a night's next link: its pack is the night's (fix 50)
		_pack_boxes(mission)                  # the plan's boxes of each worn gun's rounds into the pack, for the refills (30 Oct, the designer's A; BUILD46-R)
	var warm_key := _combo_warm(mission)
	if warm_key != "":
		log_event(Words.COMBOS[warm_key])       # the build's on: its one line, at the start now the loop starts warm
	if has_node("cap_ghost") and not t.has("boss"):
		mission["remaining"] = 0              # Ghost: the first gang never comes; the run starts at the search
		mission["target_hp"] = 0.0
		mission["fresh"] = false
		mission["cleared"] = true             # searching from the first second; the clear itself (the ladder, the bonus) is a full pack brought home, or the first gang beaten
		mission["ghost_pending"] = true
	if t.has("boss"):
		mission["boss"] = _boss_entry(t["boss"])
		mission["boss_queue"] = []
		for q in t.get("boss_queue", []):
			mission["boss_queue"].append(_boss_entry(q))
		mission["convoy"] = t.get("convoy", false)
	# something may happen on the way: when, and what
	mission["event"] = ""
	mission["event_at"] = -1.0
	var ev: String = roll_event(i, int(t.get("level", 0)))
	if ev != "":
		mission["event"] = ev
		mission["event_at"] = rng.randf_range(Data.EVENT_WINDOW[0], Data.EVENT_WINDOW[1])
	if mission["remaining"] > 0:
		_gang_arrives(mission)                # Guard at the first gang (12 Oct)
	runner_runs += 1
	runs_total += 1
	if runs_total % Data.MATE_RUNS == 0:
		mate = roll_mate()
	var intel: String = ", ".join(t["intel"]).to_lower()
	var at_lv: String = (", level %d" % int(t.get("level", 0))) if not _sig.is_empty() else ""     # a signal says its level; a campaign run says nothing (18 Oct: no depth on screen)
	var zn: String = zone_name(i)
	var ck: Dictionary = Data.county(str(_sig.get("order", _sig.get("county", "")))) if bool(t.get("county", false)) and not _sig.is_empty() else {}
	if not ck.is_empty():
		zn = str(Data.COUNTY_ZONES[int(ck["cz"])]["name"])     # a County place's own zone, not its host's (the third review); a remixed one's too
	log_event(Words.LOG["out_to"] % [Words.mid(t["name"]), Words.mid(zn), at_lv, (": " + intel) if intel != "" else ""])     # no codes, no colon (13 Oct, Matt's save)
	_threads_at_deploy(mission, i)            # BUILD46-E: a tip's stash here, word of the Vagabond, a head's weakness
	_maybe_wearing(mission)
	var key := "%d/%d" % [i, t["depth"]]
	if not seen.has(key):
		seen[key] = true
		var line := Words.site_line(t["name"], int(t["depth"]))
		if line != "":
			log_event(line)
	var b61_wk: String = _b61_wager_key(i)     # (BUILD61-A) a County stage's first clear or a head's fight: its own key; none on any other County run
	if not _repeat_going and not _dry_on and wager_gate and (b61_wk != "" or not (sig_head and is_county(str(_sig.get("order", ""))))):
		_wagers_on(mission, b61_wk if b61_wk != "" else ("sig:%d" % int(_sig["id"])) if sig_head else (wager_head_key(int(Data.TIERS[i]["zone"])) if _a55_head == i else wager_site_key(i)))     # Kev's wagers taken there (29 Oct): never a repeat's; (FIX55) the head's fight its own
	_a55_mission_marks(mission, i)            # (BUILD55-A) mission["stage"] and ["depth"]
	mark_site_seen(i)



## The world goes `seconds` on, a frame at a time: the run out plays on, or rest at camp (21 Oct, Matt: no auto-run -
## nothing sets off by itself; 24 Oct: no offline - the world waits while the game's shut).
func advance(seconds: float) -> void:
	elapsed += seconds
	_exp_tick()                              # the expeditions' clocks (29 Oct): played time, the world waits while the game's shut
	_roll_weather()
	if issued and fiat_rate != 1.0:
		fiat_rate = move_toward(fiat_rate, 1.0, Data.RATE_RECOVER_H * seconds / 3600.0)     # the rate drifts back
	if issued and circulation > 0.0:
		circulation *= pow(0.5, seconds / (Data.CIRC_HALF_H * 3600.0))     # the fiat about drains, and the prices drift back (Matt, 26 Oct)
	live_guard()                             # the live memo's guard (BUILD43): once a frame, and each further step of a long advance
	if hp > max_hp():
		hp = max_hp()                        # the max can drop when kit comes off
	var left := seconds
	var steps := 0
	while left > 0.0:
		if steps > 0:
			live_guard()
		steps += 1
		if night_break():
			if not _night_auto_step():
				left = 0.0                        # a night's break: the world waits on the player, no rest (BUILD50 N)
			continue
		if mission != null:
			if _c51_dogs_held(mission):
				if not _c51_dogs_step():
					left = 0.0                    # (BUILD51-C) a repeat's run waits on its dogs' read, a few ms a frame
				continue                          # answered: looked at again (the order may have taken the runner out)
			var step := minf(1.0, left)
			var p0 := Time.get_ticks_usec()
			if fast_memo:
				_memo_age += step
				if _memo_age >= FAST_MEMO_S:
					_memo_age = 0.0
					_dry_memo.clear()
					_stats_dirty()
			_tick(step)
			if mission != null and bool(mission.get("unwatched", false)):
				_unwatched_step()                 # a repeat's run (29 Oct): the bail at once, a med under 40%
			prof["real_ticks"] += 1
			prof["real_us"] += Time.get_ticks_usec() - p0
			left -= step
			continue
		if away():
			left = _repeat_rest(left)             # between repeat runs: rest, and out again at full HP
			continue
		if hp < max_hp():     # at camp: rest
			hp = minf(max_hp(), hp + rest_rate() * left)
		left = 0.0


func _tick(dt: float) -> void:
	var m: Dictionary = mission
	var t: Dictionary = m["t"]
	if event_paused(m):
		m["paused_s"] = float(m.get("paused_s", 0.0)) + dt     # a run event's choice waits: the gang clock stops (1 Nov)
		return
	m["elapsed"] += dt
	if m["remaining"] > 0:
		# the clock (9 Oct): it runs while a gang is on you, and stands while the site is clear
		if not has_rule("bomb_suit"):
			m["clock"] = float(m.get("clock", clock_budget(t))) - dt     # the Bomb Disposal Suit (a mythic): never runs out
		m["clock_used"] = float(m.get("clock_used", 0.0)) + dt
		if m.get("way_out", false):
			m["way_out_t"] = float(m["way_out_t"]) - dt
		if m["clock"] <= 0.0 or (m.get("way_out", false) and float(m["way_out_t"]) <= 0.0):
			_time_out(m)
			return
		_fight(m, t, dt)
		if mission != null and m.has("dogs_home") and int(m["remaining"]) <= 0:
			_dogs_done(m)                        # a threat seen off (1 Nov): the site's own gang again, the next one later
		if mission != null and m.has("clue_home") and int(m["patrols"]) > int(m.get("clue_from", 0)) and int(m["remaining"]) <= 0:
			_clue_done(m)                        # a body's clue (BUILD46-E): the tougher gang beaten, its notes paid
	else:
		# the clock runs through a search too, at CLOCK_SEARCH_RATE (21 Oct: it stood while the site was clear, so a
		# strong build never saw it; staying has a price). A dry run ends at the clear and never gets here.
		if not has_rule("bomb_suit"):
			m["clock"] = float(m.get("clock", clock_budget(t))) - dt * Data.CLOCK_SEARCH_RATE
			m["clock_used"] = float(m.get("clock_used", 0.0)) + dt * Data.CLOCK_SEARCH_RATE
			if m["clock"] <= 0.0:
				_time_out(m)
				return
		_search(m, t, dt)
		if nothing_left(m):
			log_event(Words.RUN_HOME_CLEAN % t["name"])     # picked clean and the next gang after the clock: home with the pack (Matt, 26 Oct)
			extract_now()
			return
		if has_node("walk_it_off"):
			_heal(m, dt)                         # through _heal: the Paramedic's overflow counts (12 Oct)
		if has_node("breather"):
			_guard_add(m, guard_cap() * 0.1 * dt)     # Breather: with no one on you, Guard comes back
		if yard_has("drip"):
			_heal(m, max_hp() * 0.01 * dt)        # the Clinic's Drip
	if mission == null:
		return
	if regen_rate() > 0.0:
		_heal(m, regen_rate() * dt)
	if has_rule("nans_cardigan"):
		_heal(m, max_hp() * 0.03 * dt)
	if float(m.get("event_at", -1.0)) >= 0.0 and m["elapsed"] >= float(m["event_at"]) and not m.get("way_out", false):
		if str(m.get("event", "")) == "convoy":
			_event(m, t)                          # a signal's convoy joins whatever's on
		elif event_lull(m):
			_event_arrive(m)                      # a run event, in the lull between gangs (1 Nov)
			if mission == null:
				return
	_dogs_tick(m, dt)
	# the Medic's rule: a med by itself under 40%
	if (class_data().get("auto_med", false) or has_rule("paramedics_bumbag")) and m["using"] == null and hp < max_hp() * 0.4 and not first_med().is_empty():
		use_med(first_med()["id"])
	elif has_rule("ambulance_bag") and m["using"] == null and hp < max_hp() * Data.MYTHIC_AUTO_MED and not first_med().is_empty():
		use_med(first_med()["id"])            # the Ambulance's Bag: one by itself under half
	_auto_cure(m)                             # a cure by itself when its element's heavy on you (28 Oct): every runner's
	_patch(m, dt)
	for ty in m.get("cure_t", {}).keys():
		m["cure_t"][ty] = float(m["cure_t"][ty]) - dt     # a cure's grace runs down whether they're on you or not
		if float(m["cure_t"][ty]) <= 0.0:
			m["cure_t"].erase(ty)
	if float(m.get("immune_t", 0.0)) > 0.0:
		m["immune_t"] = maxf(0.0, float(m["immune_t"]) - dt)     # Clean hands' grace runs down whether they're on you or not
	if m["cleared"]:
		if not gang_held(m) and m["remaining"] <= 0 and not dogs_waiting(m):
			m["patrol_timer"] += dt          # only while it's quiet (14 Oct, Matt): every gang beaten gives the search its window back
		if m["patrol_timer"] >= patrol_s(t, m["patrols"] == 0) and not has_rule("freedom"):     # the Freedom of the Borough (a mythic): none after the clear
			m["patrol_timer"] = 0.0
			m["patrols"] += 1
			m["fresh"] = true
			m.erase("opened")
			m["sustain_t"] = 0.0
			m.erase("clocked")
			_gang_arrives(m)
			var grown: int = 0 if has_node("cap_dead_quiet") else m["patrols"] - 1      # Dead quiet: every gang the size of the first
			var size: int = maxi(1, PATROL_BASE + grown - (Data.FX["node/trapline.heads"] if has_node("trapline") or has_node("snare_and_wait") else 0) + (Data.FX["node/loud.gang"] if has_node("loud") else 0) - (Data.FX["rule/wardens_hat.gang"] if has_rule("wardens_hat") else 0))
			if m.get("twine", false):
				size = maxi(1, size - 1)          # Twine: the snare line the last search set
				m.erase("twine")
			if has_rule("scouts_whistle"):
				size = 1
			if yard_has("flares"):
				size = maxi(1, size - Data.FX["yard/flares.heads"])     # the Lookout's Flares: every gang a head short
			if has_joint("poacher_frost"):
				size = maxi(1, size - Data.FX["joint/poacher_frost.heads"])     # the Poacher's snare, joined: every gang one head short, and chilled
				m["chill_t"] = Data.FX["joint/poacher_frost.chill_s"]
			if has_node("cap_poached"):
				_find(m, t)                  # Poached: they arrive already light
			if has_node("hit_and_run"):
				_extract()                  # out when the first gang comes
				return
			if m["remaining"] <= 0 and rng.randf() < gang_next_odds(int(m["patrols"])):
				_gang_harder(m)                     # B9 (15 Oct): the next zone's crew, harder a head
				t = m["t"]
			size = ceili(size * float(m.get("wager_gang", 1.0)))     # Kev's bigger gang: every gang (29 Oct, the review)
			m["remaining"] += size
			if m["target_hp"] <= 0.0:
				m["target_hp"] = float(t["hp"])
			log_event(gang_line(m, size))
			if m.get("leave_full", false):
				_extract()                  # "fill up then go" leaves as the gang arrives
				return
	if m.get("leave_full", false) and m["cleared"] and (pack_used(m) >= capacity() or crates_done(m)):
		_extract()                           # the pack full, or every crate open: nothing more to stay for


## The run's clock (9 Oct, docs/design/timers.md): a site's budget, the same for every build - so many seconds a
## head of its plain pool and of the gangs after it - halved by the Radio's Last bus.
func clock_budget(t: Dictionary) -> float:
	var heads: int = int(t.get("plain_pool", t.get("pool", 1))) + Data.CLOCK_GANGS
	return (Data.CLOCK_BASE + Data.CLOCK_PER_HEAD * heads) * (0.5 if t.get("clock_half", false) else 1.0) * float(t.get("clock_mult", 1.0))


## The campaign's fight at a site, harder with the runner's level (21 Oct, Matt: "yes to campaign getting harder"): x1
## until the site's first clear and for CAMPAIGN_LEVEL_FREE levels after it, then compounding CAMPAIGN_LEVEL_GROW a
## level gained since, CAMPAIGN_LEVEL_MAX at most. The frontier never hardens: a site you haven't cleared is as it is.
func campaign_level_mult(i: int, s := 1) -> float:
	var k: int = stage_key(i, s)     # (BUILD55-A) keyed per stage: never on a stage not cleared
	if not clear_level.has(k):
		return 1.0
	return minf(Data.CAMPAIGN_LEVEL_MAX, pow(1.0 + Data.CAMPAIGN_LEVEL_GROW, maxi(0, level() - int(clear_level[k]) - Data.CAMPAIGN_LEVEL_FREE)))


## A crew's head brings his own time when he comes out: a head's seconds for every plain head's HP he carries.
func clock_for_head(t: Dictionary, head_hp: float) -> float:
	return Data.CLOCK_PER_HEAD * head_hp / maxf(1.0, float(t.get("plain_hp", t.get("hp", 1.0))))


## The clock a site would start with now, for the Runs card.
func clock_of(i: int) -> float:
	return clock_budget(effective(i))


## Out of time: the runner gets out, the pack doesn't, and CLOCK_LOSE_KIT pieces of worn kit go with it - the
## insurance pays for those as on a death (the Fence's Insurance desk the pack too); the dog fetches the best of it.
func _time_out(m: Dictionary) -> void:
	m["timed_out"] = true
	if m.get("dry", false):
		m["dead"] = true                       # the odds: out of time is a run lost
		prof["dry_timeouts"] = int(prof.get("dry_timeouts", 0)) + 1     # the bot and the balance gate count them
		return
	_event_end(m)                              # his run-only goods back before the rig goes anywhere (40-E review 2)
	if m.get("unwatched", false):
		_bail(m)                               # unwatched (29 Oct): out of time is a bail, the kit kept
		return
	_floor_mythics_in(m)
	_pack_unmark(m)                       # before the dog and the insurance send pieces home (the review)
	var t := tier(m["tier"])
	var insured: bool = m.get("insured", false)
	var worn_v: Array = []
	for s in Data.SLOTS:
		if equipped[s] != null and not equipped[s].get("mythic", false) and not equipped[s].get("issued", false):     # a mythic is never lost (16 Oct), nor issued kit
			worn_v.append(s)
	var lost: Array = []
	var lost_slots: Array = []
	for k in range(mini(Data.CLOCK_LOSE_KIT, worn_v.size())):
		var s: String = worn_v[rng.randi_range(0, worn_v.size() - 1)]
		worn_v.erase(s)
		lost_slots.append(s)
		var it: Dictionary = equipped[s]
		equipped[s] = null
		_stats_dirty()
		lost.append(Items.full_name(it).to_lower() if not it.has("unique") else Items.full_name(it))
		if insured:
			stash.append(it)                     # the Fence held the paper on it
		else:
			_lose(it, "a runner", "runner")
		if s == "Rig":
			for r_it in rig:
				if insured:
					stash.append(r_it)               # what was in it goes with it
			rig = []
	# the hand-me-downs in their places, once every loss is in, as a new runner arrives with (no runner left with fists
	# and a clock: a spiral); the hammer needs no rounds (13 Oct)
	var start_v := {"Primary": START_WEAPON, "Armour": "Work jacket", "Backpack": "Plastic bag", "Rig": "Bum bag"}
	for s in lost_slots:
		if start_v.has(s):
			equipped[s] = _plain(s, start_v[s])
			_stats_dirty()
	var kept_pack: bool = insured and yard_has("insurance_desk")
	var carried := ""
	if not kept_pack and not m["found"].is_empty():
		var keep: Array = m["found"].filter(func(it): return Items.is_deeds(it) or it.get("mythic", false))     # the deeds come home whatever: _extract writes their fate; a mythic too
		var rest: Array = m["found"].filter(func(it): return not Items.is_deeds(it) and not it.get("mythic", false))
		var fetchable: Array = rest.filter(func(it): return not it.get("carried", false))     # never the gate's box (the three-stage review, game 13)
		if yard_has("fetch") and not fetchable.is_empty():
			var best: Dictionary = fetch_pick(fetchable)     # gear before scrap and materials (1 Nov)
			stash.append(best)                   # the Kennel's Fetch: the best of the pack, carried out - straight in, as on a death
			carried = Items.full_name(best)
			log_event(Words.LOG["dog_home"] % (carried if best.has("unique") else carried.to_lower()))
			rest.erase(best)
		m["left"] = int(m["left"]) + rest.size()
		m["found"] = keep
	_dry_memo.clear()
	_stats_dirty()
	# the line says it all (16 Oct, Matt's playtest): what went, the rig's contents with the rig, where it went, and why
	var rig_gone: bool = "Rig" in lost_slots and not insured
	log_event(Words.LOG["out_of_time"] % [Words.mid(t["name"]), "" if lost.is_empty() else ", and %s with it" % " and ".join(lost),
		", and what was in the rig" if rig_gone else "", "; insured, the kit comes back to the stash" if insured and not lost.is_empty() else ""])
	if not lost.is_empty() and not insured:
		log_event(Words.TIME_OUT_LOOSE[0 if lost.size() == 1 else 1])
	if str(m.get("ran_dry", "")) != "":
		log_event(Words.TIME_OUT_DRY % str(m["ran_dry"]).to_lower())
	_extract()
	if carried != "":
		last_report["carried"] = carried


## "Fill up, then go": with the fight won, keep searching and leave by itself
## when the pack's full or the next gang comes - the auto-run's rule, for one
## run, so a long gang delay isn't three minutes of watching.
func set_leave_full(on: bool) -> bool:
	if mission == null:
		return false
	mission["leave_full"] = on
	if on:
		take_all()                            # the floor's into the pack first (13 Oct)
	if on and mission["cleared"] and pack_used(mission) >= capacity():
		_extract()
	return true


## HP back, counted for the run screen's green numbers (regen, a med, life on a kill). What heals past full is Guard
## for the Paramedic, and the `overflow` share of it for a med with that line; `med` marks a med's heal.
func _heal(m: Dictionary, amount: float, _med := false, overflow := 0.0) -> void:
	var before := hp
	hp = minf(max_hp(), hp + amount)
	m["healed"] = float(m.get("healed", 0.0)) + (hp - before)
	# Guard (12 Oct, docs/design/shields.md): what heals past full - all of it the Paramedic's, a med's `overflow`
	# share anyone's
	var past_v: float = maxf(0.0, amount - (hp - before))
	var share: float = 1.0 if class_data().get("overheal", false) else overflow
	if past_v > 0.0 and share > 0.0:
		_guard_add(m, past_v * minf(1.0, share))


## Guard (12 Oct, docs/design/shields.md): a second bar over HP that their fire takes first. Its cap: GUARD_SHARE of
## max HP (half with Transfusion), grown by Overtime and `guard_pct` (the kit's, and the web centre's rings, 3 Nov). It lasts the run.
func guard_cap() -> float:
	var share: float = Data.GUARD_SHARE * (Data.FX["node/cap_transfusion"] if has_node("cap_transfusion") else 1.0)
	return max_hp() * share * (1.0 + (_affix_sum("guard_pct") + tree_sum("guard_pct") + (Data.FX["node/overtime.guard"] if has_node("overtime") else 0.0)) / 100.0)


func guard() -> float:
	return float(mission.get("guard", 0.0)) if mission != null else 0.0


func _guard_add(m: Dictionary, amount: float) -> void:
	if amount <= 0.0:
		return
	m["guard"] = minf(guard_cap(), float(m.get("guard", 0.0)) + amount)


## Where this runner's Guard comes from, in words (the Stats sheet, 12 Oct): [] when nothing fills it.
func guard_sources() -> Array:
	var out: Array = []
	if class_data().get("overheal", false):
		out.append("overheal")
	if has_node("cap_transfusion"):
		out.append("a med fills it")
	var gang: float = (Data.FX["node/squared_up"] if has_node("squared_up") else 0.0) + _affix_sum("guard_gang")
	if gang > 0.0:
		out.append("%d%% of max HP a gang" % int(round(gang)))
	if has_node("in_the_hide"):
		out.append("15% of max HP when a gang's first goes down")
	if has_node("sheet_metal"):
		out.append("6% of max HP a crate searched")
	if has_node("breather"):
		out.append("back between gangs")
	if rig.any(func(it): return Items.is_medical(it) and Items.affix_total(it, "overflow_pct") > 0.0):
		out.append("a med's overflow")
	return out


## A gang arriving (the first, a patrol, the convoy's, the door's): Squared up and the `guard_gang` lines.
func _gang_arrives(m: Dictionary, new_fight := true) -> void:
	if new_fight:
		_mags_topped(m)                       # the quiet's reload: full magazines for the next gang (28 Oct)
	if new_fight or not m.has("sk"):
		_skills_fight_start(m)                # a fight starts: energy full, the skills ready (milestone 8)
	else:
		m["sk"]["seq"] = int(m["sk"]["seq"]) + 1     # men join the fight in progress: Gin trap's next one
	var share: float = (Data.FX["node/squared_up"] if has_node("squared_up") else 0.0) + _affix_sum("guard_gang") + (25.0 if has_node("bin_lid") else 0.0)     # Bin lid (22 Oct): Guard of 25% as each gang arrives
	if share > 0.0:
		_guard_add(m, max_hp() * share / 100.0)


# ------------------------------------------------------------------ repeat runs and safe to leave (29 Oct, docs/design/trips.md 1, 2)

## "Run it ×5" (Matt, 28 Oct: "staring at the same animations over and over gets old"): a cleared site reading 90% or
## better at full HP, run five times unwatched, one after another in their real played time - the runner away, the rooms
## free but the runner's kit, class, tree resets, the site's level and codes and its head locked. Between runs the runner
## rests (the Clinic's rate as a share of max HP: repeat_rest_rate), the rig's packed (pack_rig) and they go again at full
## HP. An unwatched run leaves by the auto-run rule (leave_full), uses a med under 40% as the bot does, fires every skill
## slotted (the designer: manual ones too) and never dies: under BAIL it bails at once - the pack lost but the deeds, the
## mythics, issued kit, uniques and its own rounds; the tins and the kill XP kept. Its XP is a share of a watched run's
## (the Bunkhouse raises it). Two bails in a row end it; so do "Bring them back" (after the run out), every run done and a
## stash too full for what it keeps. A wound is rested off between runs (the designer: it doesn't end the repeat). The
## pack sorts itself at the gate (_repeat_sort): only the best upgrade a slot comes home. No offline: the world waits.
var repeat := {}               # the repeat out: {site, of (0: till the stash is full), done, phase "run"/"rest", stop, bails_row, bails, runs, kept, ups, t0, run_t0, lv0, wounds0, share, own_list}
var repeat_report := {}        # the last repeat's card, until it's put away: {site, of, runs, kept, time, ended, reason, lv0, lv1, share}
var _repeat_going := false     # the repeat's own deploy: the gate's shut to everything else while the runner's away
const REPEAT_ROOM := 9         # the stash's cells a repeat wants free to go on: the biggest find's (3 x 3)


func away() -> bool:
	return not repeat.is_empty()


## Whether the run out is a repeat's, nobody watching.
func unwatched() -> bool:
	return mission != null and bool(mission.get("unwatched", false))


## The runner's kit, class and tree are theirs while a run's out or they're away (the rooms are free; the runner isn't).
func runner_busy() -> bool:
	return mission != null or away()


## Why the runner can't be changed now ("" when they can): out on a run, or away on a repeat.
func busy_words() -> String:
	if away():
		return Words.REPEAT["shut_away"]
	return Words.REPEAT["shut_out"] if mission != null else ""


## Runs a repeat goes: 5, the Bunkhouse's 10 and 20, or 0 for till the stash is full.
func repeat_count() -> int:
	if yard_has("rr_full"):
		return 0
	if yard_has("rr_twenty"):
		return 20
	if yard_has("rr_ten"):
		return 10
	return Data.REPEAT_RUNS


## A repeat run's XP, a share of a watched run's: 12%, the Bunkhouse's 17, 22 and 30 (1 Nov: halved; a watched run always pays more).
func repeat_xp_share() -> float:
	if yard_has("rr_rest"):
		return Data.REPEAT_XP[3]
	if yard_has("rr_list"):
		return Data.REPEAT_XP[2]
	if yard_has("rr_ten"):
		return Data.REPEAT_XP[1]
	return Data.REPEAT_XP[0]


## The rest between repeat runs (the review: a flat rate left a late repeat mostly resting): the Clinic's rate as a share
## of max HP - what it heals a second of BASE_HP, of the runner's max - twice with Bunk beds, 5% quicker a Bunkhouse rank.
func repeat_rest_rate() -> float:
	return rest_rate() * max_hp() / maxf(1.0, Data.BASE_HP) * (2.0 if yard_has("rr_rest") else 1.0) * (1.0 + Data.REPEAT_RANK_REST * yard_rank("bunkhouse"))


## The rest the runner's on now: between repeat runs the repeat's, else the camp's. The top bar, the Clinic and the Map read it.
func rest_rate_now() -> float:
	return repeat_rest_rate() if away() else rest_rate()


## The site's odds at full HP (the designer: the 90% gate reads the runner whole, as the repeat rests first): [read, odds].
func repeat_odds(i: int) -> Array:
	if hp >= max_hp() - 0.01:
		return [odds_ready(i), odds_now(i)]   # whole: the site's own read is the gate's
	return _whole(i, func(): return [odds_ready(i), odds_now(i)])


## The full-HP read the gate wants, a step at a time in the shell's odds budget (main._read_odds).
func repeat_read(i: int) -> void:
	if mission != null or hp >= max_hp() - 0.01:
		return
	_whole(i, func(): return survival(i))


## The runner read whole for the repeat's gate (U1, U2): HP to the max, the key worked afresh - never the frame's or the
## paint's memo, worked at the hurt HP - and the read in its own slot of _surv_cache ("whole:<site>"), so the site's
## hurt read the Map shows is never overwritten by it. Everything put back after.
func _whole(i: int, fn: Callable) -> Variant:
	var slot := "whole:%d" % i
	var home = _surv_cache.get(i, null)
	if _surv_cache.has(slot):
		_surv_cache[i] = _surv_cache[slot]
	else:
		_surv_cache.erase(i)
	var h := hp
	hp = max_hp()                            # the key's memos hold the HP they were worked at: the whole read works its own
	var out = fn.call()
	hp = h
	if _surv_cache.has(i):
		_surv_cache[slot] = _surv_cache[i]
	if home != null:
		_surv_cache[i] = home
	else:
		_surv_cache.erase(i)
	return out


## Why "Run it ×5" is shut on a site, or "" when it can go: the runner away or out, a trait to pick, not cleared, a head
## (or the convoy) on, the stash full, the odds at full HP still reading or under 90%.
func repeat_block(i: int) -> String:
	if i < 0 or i >= Data.TIERS.size() or not tier_open(i):
		return Words.REPEAT["shut_site"]
	if away():
		return Words.REPEAT["shut_away"]
	if mission != null:
		return Words.REPEAT["shut_out"]
	if candidates.size() == 2:
		return Words.REPEAT["shut_trait"]
	if int(best_depth[i]) <= 0 or f55_first_clear(i):     # (FIX55, review 2) the picked stage not yet cleared: its first clear is watched
		return Words.REPEAT["shut_new"]
	if bool(boss_armed.get(i, false)):
		return Words.REPEAT["shut_convoy"] if is_convoy(i) else Words.REPEAT["shut_head"]
	if not stash_room(REPEAT_ROOM):
		return Words.REPEAT["shut_full"]
	var o: Array = repeat_odds(i)
	if not bool(o[0]):
		return Words.REPEAT["shut_reading"]
	if float(o[1]) < Data.REPEAT_ODDS:
		return Words.REPEAT["shut_odds"] % int(floor(float(o[1]) * 100.0))
	return ""


func can_repeat(i: int) -> bool:
	return repeat_block(i) == ""


## Set off on a repeat: rested to full first when hurt, then the first run.
func start_repeat(i: int) -> bool:
	if not can_repeat(i):
		return false
	repeat = {"site": i, "of": repeat_count(), "done": 0, "phase": "rest", "stop": false, "bails_row": 0, "bails": 0, "runs": [], "kept": [], "ups": {},
		"t0": elapsed, "run_t0": elapsed, "lv0": level(), "wounds0": wounds.duplicate(true), "share": repeat_xp_share(), "own_list": yard_has("rr_list"), "first": true}
	repeat_report = {}
	var of: int = int(repeat["of"])
	log_event(Words.REPEAT["set_off"] % [Words.mid(str(Data.TIERS[i]["name"])), (Words.REPEAT["times"] % of) if of > 0 else Words.REPEAT["till_full"]])
	chron("repeat", {"site": str(Data.TIERS[i]["name"]), "of": of, "share": float(repeat["share"])})
	if hp >= max_hp() - 0.01:
		_repeat_go()
	return true


## "Bring them back": the run out is the last; resting between runs, back now.
func bring_back() -> void:
	if not away():
		return
	repeat["stop"] = true
	if mission == null:
		_repeat_end("back")
	else:
		log_event(Words.REPEAT["calling"])


## The next run of the repeat: the rig packed from the stash whatever the gate's top-up says, then out, unwatched. A head
## is never on a repeat run (locked while away; disarmed here whatever).
func _repeat_go() -> void:
	var i: int = int(repeat["site"])
	if str(repeat.get("county", "")) == "" and bool(boss_armed.get(i, false)):     # (BUILD61 review) a County repeat leaves its host site's head as he was
		boss_armed[i] = false
		_surv_cache.erase(i)
	var rp: Dictionary = rounds_plan(i)       # the site's plan (BUILD46-R): its grades; a repeat packs and fills whatever its tick
	var rc: Dictionary = _grade_counts()
	var bg = _plan_bg(rp, rc)     # once, before filling (the reviewer on m32c, 1): held for the gate's own top-up and box
	var picks: Dictionary = _plan_picks(rp, rc)
	_fill_mags(bg, picks)
	pack_rig("fill", i, false)               # the site's cures, not the front's (S9); no magazines past each gun's first, as the gate (BUILD48 A, item 24)
	_fill_mags(bg, picks)                     # the magazines it packed, filled (30 Oct)
	var ins := insure_next
	insure_next = false                       # the paper's for a watched run
	_repeat_going = true
	_bg_hold = bg
	if str(repeat.get("county", "")) != "":
		_b61_repeat_deploy()                     # (BUILD61-A) a County place's stage, laid on its host site
	else:
		deploy(i)
	_bg_hold = null
	_repeat_going = false
	insure_next = ins
	if mission == null:
		var rep := repeat
		repeat = {}                           # the real reason (U3): away, the gate only ever said "the runner is away"
		var why: String = repeat_block(i) if str(rep.get("county", "")) == "" else county_stage_block(str(rep["county"]), int(rep.get("cstage", 1)))     # (BUILD61-A)
		repeat = rep
		_repeat_end("blocked", Words.mid_base(why if why != "" else Words.REPEAT["shut_out"]))     # said mid-sentence, its first letter down and HP kept: "Ended: the stash is full"
		return
	mission["unwatched"] = true
	mission["leave_full"] = true             # the auto-run's rule: a full pack, every crate open, or as the next gang comes
	repeat["phase"] = "run"
	repeat["first"] = false
	repeat["run_t0"] = elapsed


## The wounds the repeat gave, rested off when a run's home (the designer: a bail's wound doesn't end it): any wound not
## there, as it was, when the repeat set off. Rested off before the rest, so the rest is to the true max HP.
func _rest_off_wounds() -> void:
	var before: Dictionary = repeat.get("wounds0", {}) if repeat.get("wounds0", {}) is Dictionary else {}
	var changed := false
	var same := func(a, b) -> bool:          # field by field, as the save's load reads them (S3: through JSON hp_pct came back 10.0, not 10)
		return a is Dictionary and b is Dictionary and str(a.get("stat", "")) == str(b.get("stat", "")) and str(a.get("what", "")) == str(b.get("what", "")) \
			and str(a.get("from", "")) == str(b.get("from", "")) and int(a.get("hp_pct", 0)) == int(b.get("hp_pct", 0))
	for area in wounds.keys():
		if not before.has(area) or not same.call(before[area], wounds[area]):
			wounds.erase(area)
			_stats_dirty()
			changed = true
	if changed:
		_caches_out()


## The world's seconds while the runner's at camp between repeat runs: rest, and out again at full HP. What's left over.
func _repeat_rest(left: float) -> float:
	repeat["phase"] = "rest"
	var rate: float = maxf(repeat_rest_rate(), 0.1)
	var need: float = maxf(0.0, max_hp() - hp) / rate
	if need > left:
		hp += rate * left
		return 0.0
	hp = max_hp()
	_repeat_go()
	return left - need


## After each of an unwatched run's ticks: the bail under BAIL, at once; a med under 40%, as the bot uses one.
func _unwatched_step() -> void:
	var m: Dictionary = mission
	if hp < max_hp() * BAIL:
		_bail(m)
		return
	if m["using"] == null and hp < max_hp() * Data.REPEAT_MED_UNDER and not first_med().is_empty():
		use_med(int(first_med()["id"]))


## A bail (Matt's call 1: never a death unwatched): out at once with the loadout, the pack lost but what never is - the
## deeds, mythics, issued kit, uniques (the designer) and the runner's own rounds.
func _bail(m: Dictionary) -> void:
	_event_end(m)
	m["bailed"] = true
	hp = maxf(hp, 1.0)
	_floor_mythics_in(m)
	var keep: Array = m["found"].filter(func(it): return Items.is_deeds(it) or it.get("mythic", false) or it.get("issued", false) or it.has("unique") or it.get("from_rig", false) or it.get("carried", false))
	m["left"] = int(m["left"]) + m["found"].size() - keep.size()
	m["found"] = keep
	log_event(Words.REPEAT["bail"] % Words.mid(str(tier(int(m["tier"]))["name"])))
	_extract()


## Why the gate keeps a find from an unwatched run, or "" for the Fence: the runner's rounds and meds, papers and what
## opens a room, the deeds, mythics, issued kit, uniques always (the designer), what the junk rules never sell (set
## pieces, socketables, supplies) and your loot rules' keeps with Your own list. Upgrades are _repeat_sort's: the best a
## slot, while the stash has room.
func repeat_keep_why(it: Dictionary, own_list := false) -> String:
	if it.get("from_rig", false) or it.get("carried", false):
		return "own"
	if it.get("first_gun", false):
		return Words.REPEAT["why_first"]
	if Items.is_deeds(it):
		return Words.REPEAT["why_deeds"]
	if it.get("mythic", false):
		return Words.REPEAT["why_mythic"]
	if it.get("issued", false):
		return Words.REPEAT["why_issued"]
	if it.has("unique"):
		return Words.REPEAT["why_unique"]
	if Items.is_paper(it) or is_pile_paper(it):
		return Words.REPEAT["why_paper"]
	if Items.opens(it) != "":
		return Words.REPEAT["why_opens"]
	if Items.is_ammo(it) or Items.is_mag(it):
		return Words.REPEAT["why_rounds"]
	if Items.rig_item(it):
		return Words.REPEAT["why_meds"]
	if Items.is_supplies(it):
		return Words.REPEAT["why_supplies"]
	if it.has("set") or it.has("pattern") or Items.is_socketable(it) or it.get("built", false):
		return Words.REPEAT["why_set"] if it.has("set") else Words.REPEAT["why_socket"]
	if own_list and loot_rule_act(it) in ["keep", "highlight"]:
		return Words.REPEAT["why_list"]
	return ""


## The pack sorted at the gate, after the loot rules and the Bins: what's kept goes on home, an upgrade only the best a
## slot of the whole repeat (the designer: a better one later sends the earlier one to the Fence), the rest sold at the
## Fence (binned for scrap while it's shut). The run's tally in the mission: rep_sold, rep_sold_tins, rep_kept.
func _repeat_sort(m: Dictionary) -> Array:
	var own: bool = bool(repeat.get("own_list", false))
	var kept: Array = []
	var chips: Array = []
	var rest: Array = []
	var best_up := {}                         # slot -> [item, gain]: this run's best upgrade a slot
	for it in m["found"]:
		var why: String = repeat_keep_why(it, own)
		if why != "":
			kept.append(it)
			if why != "own":
				chips.append({"id": int(it.get("id", -1)), "name": Items.full_name(it), "rarity": int(it.get("rarity", 0)), "why": why})
			continue
		if is_upgrade(it):
			var g: float = upgrade_gain(it)
			var sl: String = str(it["slot"])
			if not best_up.has(sl) or g > float(best_up[sl][1]):
				if best_up.has(sl):
					rest.append(best_up[sl][0])
				best_up[sl] = [it, g]
				continue
		rest.append(it)
	var ups: Dictionary = repeat.get("ups", {}).duplicate()
	var removed := 0
	for sl in best_up:
		var it: Dictionary = best_up[sl][0]
		var g: float = float(best_up[sl][1])
		if (ups.has(sl) and g <= float(ups[sl]["gain"])) or not stash_fits(it):
			rest.append(it)
			continue
		if ups.has(sl) and away():
			var old: Dictionary = item_by_id(int(ups[sl]["id"]))
			if not old.is_empty() and stash.has(old) and _remove(old):
				rest.append(old)                   # the earlier upgrade, bettered: to the Fence with the rest
				var n0: int = repeat["kept"].size()
				repeat["kept"] = repeat["kept"].filter(func(c): return int(c.get("id", -2)) != int(old["id"]))
				removed += n0 - repeat["kept"].size()
		ups[sl] = {"id": int(it.get("id", -1)), "gain": g}
		kept.append(it)
		chips.append({"id": int(it.get("id", -1)), "name": Items.full_name(it), "rarity": int(it.get("rarity", 0)), "why": Words.REPEAT["why_upgrade"]})
	if away():
		repeat["ups"] = ups
	var sold := 0
	var sold_tins := 0.0
	var binned := 0
	for it in rest:
		if room_open("fence"):
			var got := float(sell_price(it))
			_earn(got)
			_rate_after_sale(got)
			sold += 1
			sold_tins += got
		else:
			scrap += scrap_of(it)                # the Fence shut: the junk to the bins
			binned += 1
	m["rep_sold"] = sold
	m["rep_sold_tins"] = sold_tins
	m["rep_binned"] = binned
	m["rep_kept"] = chips
	m["rep_unkept"] = removed
	if sold > 0:
		log_event(Words.REPEAT["sold"] % [sold, "" if sold == 1 else "s", _cash_words(sold_tins)])
	return kept


func _materials_total() -> int:
	var n := 0
	for k in materials:
		n += int(materials[k])
	return n


## A repeat run home (_extract's last act): its line in the report, the wounds it gave rested off, then the rest, or the end.
func _repeat_run_done(m: Dictionary, pre: Dictionary) -> void:
	if not away():
		return
	var bailed: bool = bool(m.get("bailed", false))
	var rec := {"n": int(repeat["done"]) + 1, "kills": int(m.get("kills", 0)), "tins": float(m.get("cash", 0.0)) + float(m.get("rep_sold_tins", 0.0)), "run_tins": float(m.get("cash", 0.0)),
		"sold": int(m.get("rep_sold", 0)), "sold_tins": float(m.get("rep_sold_tins", 0.0)), "scrap": scrap - int(pre["scrap"]), "mats": _materials_total() - int(pre["mats"]),
		"xp": float(m.get("xp_got", 0.0)), "kept": m.get("rep_kept", []).size() - int(m.get("rep_unkept", 0)), "bail": bailed, "wounded": bool(m.get("wounded", false)),
		"cleared": bool(m.get("cleared", false)) and not bailed, "timed_out": bool(m.get("timed_out", false)), "time": elapsed - float(repeat["run_t0"])}
	repeat["runs"].append(rec)
	repeat["done"] = int(repeat["done"]) + 1
	repeat["kept"].append_array(m.get("rep_kept", []))
	_rest_off_wounds()                        # before the rest: rested to the true max HP, the next run whole (the review)
	if bailed:
		repeat["bails_row"] = int(repeat["bails_row"]) + 1
		repeat["bails"] = int(repeat["bails"]) + 1
	else:
		repeat["bails_row"] = 0
	var of: int = int(repeat["of"])
	var why := ""
	if int(repeat["bails_row"]) >= 2:
		why = "bails"
	elif bool(repeat["stop"]):
		why = "back"
	elif (of > 0 and int(repeat["done"]) >= of) or int(repeat["done"]) >= Data.REPEAT_MAX:
		why = "done"
	elif bool(m.get("rep_overflow", false)) or not stash_room(REPEAT_ROOM):
		why = "full"                          # what it keeps won't fit next time: home now, nothing lost
	if why != "":
		_repeat_end(why)
	else:
		repeat["phase"] = "rest"


## The repeat over: its card waits on the Map until it's put away. `reason` the shut reason when it couldn't set off.
func _repeat_end(why: String, reason := "") -> void:
	var r: Dictionary = repeat
	_rest_off_wounds()
	repeat = {}
	_a55_sync(int(r["site"]))                 # (FIX55, review 5) a stage first cleared while away: the site's depth follows its pick now
	repeat_report = {"site": int(r["site"]), "county": str(r.get("county", "")), "of": int(r["of"]),     # (BUILD61-A) a County repeat's place
		"runs": r["runs"], "kept": r["kept"], "time": elapsed - float(r["t0"]), "ended": why, "reason": reason,
		"lv0": int(r["lv0"]), "lv1": level(), "share": float(r["share"])}
	var tot := repeat_totals(repeat_report)     # (BUILD61-A) the report and the line: a County repeat's place
	log_event(Words.REPEAT["back"] % [Words.mid(repeat_place_name(r)), int(tot["runs"]), "" if int(tot["runs"]) == 1 else "s", int(tot["bails"]), "" if int(tot["bails"]) == 1 else "s"])
	chron("repeat_back", {"site": str(Data.TIERS[int(r["site"])]["name"]), "runs": int(tot["runs"]), "bails": int(tot["bails"]), "ended": why, "xp": snappedf(float(tot["xp"]), 1.0), "tins": snappedf(float(tot["tins"]), 1.0)})


## A repeat report's sums, its runs added up: the card's figures and the smoke's.
static func repeat_totals(rep: Dictionary) -> Dictionary:
	var out := {"runs": 0, "kills": 0, "kept": 0, "tins": 0.0, "sold": 0, "sold_tins": 0.0, "scrap": 0, "mats": 0, "xp": 0.0, "bails": 0, "wounds": 0, "cleared": 0, "timeouts": 0}
	for r in rep.get("runs", []):
		out["runs"] += 1
		for k in ["kills", "kept", "sold", "scrap", "mats"]:
			out[k] += int(r.get(k, 0))
		for k in ["tins", "sold_tins", "xp"]:
			out[k] += float(r.get(k, 0.0))
		out["bails"] += 1 if bool(r.get("bail", false)) else 0
		out["wounds"] += 1 if bool(r.get("wounded", false)) else 0
		out["cleared"] += 1 if bool(r.get("cleared", false)) else 0
		out["timeouts"] += 1 if bool(r.get("timed_out", false)) else 0
	return out


## What the Bunkhouse gives now, in one line: the runs a repeat goes and its XP (the Pitch's list, once).
func repeat_gives() -> String:
	var n: int = repeat_count()
	return (Words.REPEAT["gives"] % [n, int(round(repeat_xp_share() * 100.0))]) if n > 0 else Words.REPEAT["gives_full"] % int(round(repeat_xp_share() * 100.0))


func repeat_seen() -> void:
	repeat_report = {}


## The away card's figures: the run out (1 up), of how many (0: till the stash is full), the share done (the stash's
## fill till full) and the seconds left at the pace so far - to the run out's end once they're called back.
func repeat_progress() -> Dictionary:
	if not away():
		return {}
	var i: int = int(repeat["site"])
	var done: int = int(repeat["done"])
	var of: int = int(repeat["of"])
	var stop: bool = bool(repeat["stop"])
	var spent: float = elapsed - float(repeat["t0"])
	var per: float = spent / done if done > 0 else maxf(60.0, estimate(i) * 1.5 + 60.0)
	var into: float = elapsed - float(repeat["run_t0"]) if mission != null else 0.0
	var share: float = clampf(into / maxf(per, 1.0), 0.0, 0.95)
	var to: int = done + 1 if stop else of
	var left: float = maxf(0.0, per * (to - done) - into) if (of > 0 or stop) else -1.0
	var fill: float = (float(done) + share) / maxf(1.0, to) if (of > 0 or stop) else clampf(float(stash_used()) / maxf(1.0, stash_cap()), 0.0, 1.0)
	return {"site": i, "n": mini(done + 1, of) if of > 0 else done + 1, "of": of, "share": fill,
		"left": left, "bails": int(repeat["bails"]), "out": mission != null, "stop": stop, "first": bool(repeat.get("first", false))}


# ------------------------------------------------------------------ Kev's wagers (29 Oct, the endgame's first activity)

## Before a watched run - a first clear or an armed head on the Map, a signal on the Radio - Kev offers 1-3 wagers, each
## a harder word for a payout (one of each pay an offer); take any, they stack, and go on the next run there whose gate is
## open as it sets off (never a repeat's, never a plain farm run after the head's untaken). Kev's at the Radio: the
## wagers open with it (docs/design/endgame_activities.md: "the wagers with the Radio").
var wagers := {}               # key ("site:3", "sig:17") -> {"seq": offers made there so far, "taken": [offer indices]}


static func wager_site_key(i: int) -> String:
	return "site:%d" % i


func wager_signal_key(k: int) -> String:
	var sg := signal_at(k)
	return ("sig:%d" % int(sg["id"])) if not sg.is_empty() else ""


## Whether Kev has an offer on the site's next run: the Radio open, the runner home, a first clear or a head armed.
func wager_site_open(i: int) -> bool:
	return room_open("radio") and not runner_busy() and i >= 0 and i < Data.TIERS.size() and tier_open(i) and (f55_first_clear(i) or bool(boss_armed.get(i, false)))     # (FIX55) any stage's first clear


func wager_signal_open(k: int) -> bool:
	return room_open("radio") and not runner_busy() and not signal_at(k).is_empty()


## Kev's offer there: 1-3 wagers seeded from the run (the place and how many offers it's had), each a different word
## and a different pay (the designer: one a pay kind an offer).
func wager_offer(key: String) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = hash([key, int(wagers.get(key, {}).get("seq", 0)), fixed_seed])
	var n: int = r.randi_range(1, 3)
	var conds: Array = range(Data.WAGER_CONDS.size())
	var pays: Array = range(Data.WAGER_PAYS.size())
	for list in [conds, pays]:
		for k in range(list.size() - 1, 0, -1):
			var j: int = r.randi_range(0, k)
			var tmp = list[k]
			list[k] = list[j]
			list[j] = tmp
	var out: Array = []
	for k in range(mini(n, pays.size())):
		var pay: Dictionary = Data.WAGER_PAYS[int(pays[k])]
		var slot: String = str(Data.WAGER_SLOTS[r.randi_range(0, Data.WAGER_SLOTS.size() - 1)]) if str(pay["id"]) == "slot" else ""
		out.append({"cond": str(Data.WAGER_CONDS[int(conds[k])]["id"]), "pay": str(pay["id"]), "slot": slot})
	return out


func wager_taken(key: String, k: int) -> bool:
	return k in wagers.get(key, {}).get("taken", [])


## Take a wager, or drop one taken. Logged.
func take_wager(key: String, k: int, on := true) -> bool:
	var offer := wager_offer(key)
	if k < 0 or k >= offer.size() or (runner_busy() and key != night_wager_key()):     # at a night's break, the next link's (BUILD50 N)
		return false
	var w: Dictionary = wagers.get(key, {"seq": 0, "taken": []})
	var taken: Array = w.get("taken", [])
	if on == (k in taken):
		return false
	if on:
		taken.append(k)
	else:
		taken.erase(k)
	w["taken"] = taken
	wagers[key] = w
	log_event((Words.WAGERS["taken"] if on else Words.WAGERS["left"]) % wager_words(offer[k]))
	chron("wager", {"key": key, "cond": str(offer[k]["cond"]), "pay": str(offer[k]["pay"]), "slot": str(offer[k]["slot"]), "on": on})
	return true


## A wager in a line: "+50% men for ×1.5 notes".
static func wager_cond_chip(w: Dictionary) -> String:
	for c in Data.WAGER_CONDS:
		if str(c["id"]) == str(w["cond"]):
			return str(c["chip"])
	return ""


static func wager_pay_chip(w: Dictionary) -> String:
	for p in Data.WAGER_PAYS:
		if str(p["id"]) == str(w["pay"]):
			return (str(p["chip"]) % str(Data.WAGER_SLOT_WORDS.get(str(w["slot"]), str(w["slot"]).to_lower()))) if str(p["id"]) == "slot" else str(p["chip"])
	return ""


static func wager_words(w: Dictionary) -> String:
	return Words.WAGERS["line"] % [wager_cond_chip(w), wager_pay_chip(w)]


## The wagers taken there, on the run setting off (deploy, with their gate open): the harder words on its fight, the
## payouts marked to pay. Spent: the next offer there is a fresh one.
func _wagers_on(m: Dictionary, key: String) -> void:
	var taken: Array = wagers.get(key, {}).get("taken", [])
	if taken.is_empty():
		return
	var offer := wager_offer(key)
	var on: Array = []
	m["t"] = m["t"].duplicate(true)
	var t: Dictionary = m["t"]
	for k in taken:
		if int(k) >= offer.size():
			continue
		var w: Dictionary = offer[int(k)]
		on.append(w)
		match str(w["cond"]):
			"gang":
				t["pool"] = ceili(float(t["pool"]) * Data.WAGER_GANG)
				if int(m["remaining"]) > 0:
					m["remaining"] = ceili(float(m["remaining"]) * Data.WAGER_GANG)
				m["wager_gang"] = float(m.get("wager_gang", 1.0)) * Data.WAGER_GANG     # every gang after it too (the review: a real risk)
			"no_meds":
				t["no_meds"] = true
			"clock":
				m["clock"] = float(m["clock"]) * Data.WAGER_CLOCK
				m["clock_max"] = float(m.get("clock_max", m["clock"])) * Data.WAGER_CLOCK
			"hard":
				t["dps"] = float(t["dps"]) * Data.WAGER_HARD
				for b in ([m["boss"]] if m.get("boss", null) is Dictionary else []) + m.get("boss_queue", []):
					b["dps"] = float(b["dps"]) * Data.WAGER_HARD     # the head and the convoy's next too (S7, the designer's call: it's the fight the wager is about)
		match str(w["pay"]):
			"notes":
				m["wager_notes"] = float(m.get("wager_notes", 1.0)) * 1.5
			"slot":
				var sl: Dictionary = m.get("wager_slots", {})
				sl[str(w["slot"])] = int(sl.get(str(w["slot"]), 1)) * 3
				m["wager_slots"] = sl
			"quality":
				t["rarity"] = float(t.get("rarity", 0.0)) + 0.5
	m["wagers"] = on
	wagers[key] = {"seq": int(wagers.get(key, {}).get("seq", 0)) + 1, "taken": []}
	log_event(Words.WAGERS["on"] % [" · ".join(on.map(func(x): return wager_words(x)))])
	chron("wagers_on", {"key": key, "n": on.size()})


## The wagers a read of site `i` takes (BUILD48 A, parked item 17: the odds read 100% for a fight with meds the runner
## didn't have): those taken on its next run as deploy would put them on - the signal's laid on it (a signal read), else the
## site's while its gate is open (a first clear, a head armed) - as their offers. [] for none, an order's or a County read.
func wagers_read(i: int) -> Array:
	var key := ""
	if not _sig.is_empty() and int(_sig["site"]) == i:
		key = _b61_wager_key(i)                  # (BUILD61-A) a County stage's first clear, a County head's fight
		if key == "" and (_sig.has("order") or str(_sig.get("county_head", "")) != ""):
			return []
		if key == "":
			key = "sig:%d" % int(_sig["id"])
	elif _a55_head == i:
		key = wager_head_key(int(Data.TIERS[i]["zone"]))     # (FIX55) the head's fight: his own offer
	elif f55_first_clear(i) or bool(boss_armed.get(i, false)):
		key = wager_site_key(i)                 # (FIX55) any stage's first clear
	else:
		return []
	var taken: Array = wagers.get(key, {}).get("taken", [])
	if taken.is_empty():
		return []
	var offer := wager_offer(key)
	var out: Array = []
	for k in taken:
		if int(k) < offer.size():
			out.append(offer[int(k)])
	return out


## The wagers' terms on a dry run's fight (BUILD48 A, item 17): what _wagers_on puts on a run's - more men, no meds, the
## clock, harder fire - and none of the pay, nothing spent or logged.
func _wagers_dry(m: Dictionary, on: Array) -> void:
	if on.is_empty():
		return
	m["t"] = m["t"].duplicate(true)
	var t: Dictionary = m["t"]
	for w in on:
		match str(w["cond"]):
			"gang":
				t["pool"] = ceili(float(t["pool"]) * Data.WAGER_GANG)
				m["remaining"] = ceili(float(m["remaining"]) * Data.WAGER_GANG)
				m["wager_gang"] = float(m.get("wager_gang", 1.0)) * Data.WAGER_GANG
			"no_meds":
				t["no_meds"] = true
			"clock":
				m["clock"] = float(m["clock"]) * Data.WAGER_CLOCK
				m["clock_max"] = float(m.get("clock_max", m["clock"])) * Data.WAGER_CLOCK
			"hard":
				t["dps"] = float(t["dps"]) * Data.WAGER_HARD
				for b in ([m["boss"]] if m.get("boss", null) is Dictionary else []) + m.get("boss_queue", []):
					b["dps"] = float(b["dps"]) * Data.WAGER_HARD


## A slot's wagered finds: the find landed, and its two more of the same slot (×3), rolled as it was.
func _wager_finds(m: Dictionary, it: Dictionary, roll: Callable, to_floor: bool) -> void:
	var x: int = int(m.get("wager_slots", {}).get(str(it.get("slot", "")), 1))
	if x <= 1 or it.has("unique") or it.get("mythic", false):
		return
	for k in range(x - 1):
		var extra: Dictionary = roll.call()
		_land(m, extra, "", to_floor)
		m["wager_finds"] = int(m.get("wager_finds", 0)) + 1


# ------------------------------------------------------------------ patterns (24 Oct, the endgame chase, phase 4)

## A unique broken down to its pattern: the unique's rule, kept at the Workshop (not in the stash) for one use on a
## rare or better of the same slot. Mythics and set pieces have none.
var patterns: Array = []                   # [{"unique": name, "slot": slot, "rule": rule}]


func can_break(it: Dictionary) -> String:
	if not it.has("unique") or it.get("mythic", false) or it.get("issued", false) or str(it.get("rule", "")) == "":
		return Words.PATTERNS["not_unique"]     # issued kit isn't broken into patterns (the reviewer)
	if not stash.has(it):
		return Words.PATTERNS["not_stashed"]
	if runner_busy():                       # away on a repeat too (30 Oct, refactor 5)
		return Words.PATTERNS["out"] if mission != null else Words.REPEAT["shut_away"]
	return ""


func break_unique(it: Dictionary) -> bool:
	if can_break(it) != "":
		return false
	stash.erase(it)
	patterns.append({"unique": str(it["unique"]), "slot": str(it["slot"]), "rule": str(it["rule"])})
	chron("pattern", {"unique": str(it["unique"])})
	log_event(Words.PATTERNS["broken"] % it["unique"])
	return true


## What putting a pattern on an item costs: a pinnacle's drop (the Grid's key for a helmet or a rig, a ledger seal
## else), PATTERN_MATERIAL of the material you hold most of, tins by the item's level.
func pattern_cost(it: Dictionary) -> Dictionary:
	var key: String = "grid_key" if str(it.get("slot", "")) in ["Helmet", "Rig"] else "ledger_seal"
	var mat := ""
	var most := -1
	for k in Data.MATERIAL_ORDER:
		if int(materials.get(k, 0)) > most:
			most = int(materials.get(k, 0))
			mat = k
	var lv: int = int(it.get("level", 1))
	var tins: int = _round_price(_inf(int(Data.PATTERN_TINS * pow(Data.PATTERN_GROW, maxi(0, lv - 1)))))
	return {"key": key, "material": mat, "material_n": Data.PATTERN_MATERIAL, "tins": tins}


func pattern_block(it: Dictionary, k: int) -> String:
	if k < 0 or k >= patterns.size():
		return Words.PATTERNS["no_pattern"]
	var pt: Dictionary = patterns[k]
	if it.has("unique") or it.has("set") or it.get("mythic", false) or it.has("pattern") or str(it.get("rule", "")) != "":
		return Words.PATTERNS["has_one"]
	if int(it.get("rarity", 0)) < Data.PATTERN_RARITY:
		return Words.PATTERNS["too_plain"]
	if str(it.get("slot", "")) != str(pt["slot"]):
		return Words.PATTERNS["wrong_slot"] % str(pt["slot"])
	if runner_busy():                       # away on a repeat too (30 Oct, refactor 5)
		return Words.PATTERNS["out"] if mission != null else Words.REPEAT["shut_away"]
	var c: Dictionary = pattern_cost(it)
	if held_of(str(c["key"])) < 1:
		return Words.PATTERNS["wants"] % thing_name(str(c["key"]))
	if int(materials.get(str(c["material"]), 0)) < int(c["material_n"]):
		return Words.PATTERNS["wants_n"] % [int(c["material_n"]), thing_name(str(c["material"]))]
	if cash < float(c["tins"]):
		return str(Words.PATTERNS["short"]).replace("tins", money_word())
	return ""


func apply_pattern(it: Dictionary, k: int) -> bool:
	if pattern_block(it, k) != "":
		return false
	var c: Dictionary = pattern_cost(it)
	var pt: Dictionary = patterns[k]
	key_items[str(c["key"])] = held_of(str(c["key"])) - 1
	materials[str(c["material"])] = int(materials.get(str(c["material"]), 0)) - int(c["material_n"])
	cash -= float(c["tins"])
	it["rule"] = str(pt["rule"])
	it["pattern"] = str(pt["unique"])
	patterns.remove_at(k)
	_rules_key = []                            # the rules read again: an item worn took a rule
	_dry_memo.clear()
	_stats_dirty()
	chron("pattern_on", {"unique": str(pt["unique"]), "tins": int(c["tins"])})
	log_event(Words.PATTERNS["put_on"] % [Items.full_name(it), pt["unique"]])
	return true


## A true pinnacle's own fight (24 Oct, the endgame chase): "grid", "archive" or "mint" while that head is out, or "".
func _order_mech(m: Dictionary) -> String:
	if not m.has("boss"):
		return ""
	var b: Dictionary = m["boss"]
	if not b.get("started", false) or not b.get("alive", false):
		return ""
	return str(b.get("mech", b.get("order", "")))


## Each pinnacle's clock a tick: the Lineman's shield up, its window and its return, his stun; the Registrar's seal on
## the skill you'd fire next (your fire cut, with none); the Issuer printing a man.
func _order_tick(m: Dictionary, t: Dictionary, dt: float, mech: String) -> void:
	m["stunned_t"] = maxf(0.0, float(m.get("stunned_t", 0.0)) - dt)
	m["taped_t"] = maxf(0.0, float(m.get("taped_t", 0.0)) - dt)
	var seal_map: Dictionary = m.get("sealed", {})
	for k in seal_map.keys():
		seal_map[k] = float(seal_map[k]) - dt
		if float(seal_map[k]) <= 0.0:
			seal_map.erase(k)
	m["sealed"] = seal_map
	var bhp: float = float(m["boss"]["hp"])
	if mech == "treasurer":
		_order_tick_as(m, t, dt, "grid", bhp)     # the Treasurer: the Lineman's shield and the Issuer's press (25 Oct)
		_order_tick_as(m, t, dt, "mint", bhp)
		return
	if mech == "auditor":
		mech = "archive"                     # the Auditor seals as the Registrar does; his tax is on the skills' cost
	elif mech == "collector":
		_collector_tick(m, dt)
		mech = "mint"
	elif mech == "bailiff":
		_bailiff_tick(m, bhp)
		return
	_order_tick_as(m, t, dt, mech, bhp)


## The fights that print men (the Issuer's press, the Collector's debtors, the Treasurer's), and that shield.
static func mech_prints(mech: String) -> bool:
	return mech in ["mint", "collector", "treasurer"]


static func mech_shields(mech: String) -> bool:
	return mech in ["grid", "treasurer"]


## The Collector's clock: what you take grows COLLECTOR_GROW every COLLECTOR_EVERY seconds he's out.
func _collector_tick(m: Dictionary, dt: float) -> void:
	m["grow_t"] = float(m.get("grow_t", 0.0)) + dt


func collector_taken(m: Dictionary) -> float:
	return 1.0 + Data.COLLECTOR_GROW * floorf(float(m.get("grow_t", 0.0)) / Data.COLLECTOR_EVERY)


const DEEDS_SEIZED := "deeds"            # what m["seized"] reads when the Bailiff holds the deeds, not a slot


## A run over with the Bailiff still holding the deeds (fled, timed out or dead): he keeps them - sold, to the County.
func _bailiff_keeps_deeds(m: Dictionary) -> void:
	if m.get("dry", false) or str(m.get("seized", "")) != DEEDS_SEIZED or not bool(m.get("seize_on", false)):
		return
	if m.get("boss") is Dictionary and not bool(m["boss"].get("alive", true)):
		return                                    # he's down: nothing of yours is his
	for src in [stash, m["found"]]:
		for it in src.duplicate():
			if Items.is_deeds(it):
				src.erase(it)
	deeds_fate = "sold"
	deeds_back = true                         # his to sell on: they don't come round again
	log_event(Words.DEEDS["taken"])


## The Bailiff down with the deeds sold (27 Oct): they're in his case, sold on and come round again - once.
func _bailiff_drops_deeds(m: Dictionary) -> void:
	if m.get("dry", false) or deeds_fate != "sold" or deeds_back or _deeds_held(m):
		return
	var thing := _plain(Data.PAPER, "The deeds")
	thing["deeds"] = true
	deeds_back = true
	deeds_fate = ""                           # the choice open again
	m["found"].append(thing)
	log_event(Words.DEEDS["back"])


## The deeds burned at home (27 Oct): held, then let go of. Out of the stash; nobody owes anybody.
func burn_deeds(id: int) -> bool:
	if mission != null:
		return false
	for it in stash:
		if int(it["id"]) == id and Items.is_deeds(it):
			_remove(it)
			deeds_fate = "burned"
			log_event(Words.DEEDS["burned"])
			return true
	return false


## The Bailiff's hold: as he comes out he seizes your best piece worn (by its worth); under BAILIFF_FREE of his HP he
## lets it go.
func _bailiff_tick(m: Dictionary, bhp: float) -> void:
	if not m.has("seized") and deeds_fate == "burned":
		m["seized"] = ""                       # the deeds burned (27 Oct, Matt): his warrant's paper is ash; he has nothing on you
		m["seize_on"] = false
		if not m.get("dry", false):
			log_event(Words.DEEDS["void"])
	elif not m.has("seized") and deeds_fate == "held" and _deeds_held(m):
		m["seized"] = DEEDS_SEIZED             # held: it's the deeds he wants, not your kit - till you make him let go
		m["seize_on"] = true
		if not m.get("dry", false):
			log_event(Words.DEEDS["seized"])
	if not m.has("seized"):
		var best := ""
		var top := -1.0
		for sl in Data.SLOTS:
			var it = equipped.get(sl)
			if it != null and Items.grows(it) and float(Items.worth(it)) > top:     # a piece with damage or armour to count half (Matt's rule)
				top = float(Items.worth(it))
				best = str(sl)
		m["seized"] = best
		m["seize_on"] = best != ""
	if bool(m.get("seize_on", false)) and float(m["target_hp"]) < bhp * Data.BAILIFF_FREE:
		m["seize_on"] = false
		if not m.get("dry", false):
			log_event(Words.COUNTY["let_go"] % str(m["seized"]).to_lower())


## What the County's heads add to the fire on you: the Collector's growing bill, the Bailiff holding your armour.
func county_taken(m: Dictionary) -> float:
	var mech: String = _order_mech(m)
	if mech == "collector":
		return collector_taken(m)
	if mech == "bailiff" and bool(m.get("seize_on", false)) and not Data.BAILIFF_CUT.has(str(m.get("seized", ""))) and str(m.get("seized", "")) != DEEDS_SEIZED:
		return Data.BAILIFF_TAKEN
	return 1.0


## One of the order's clocks for a tick (the Treasurer runs two).
func _order_tick_as(m: Dictionary, t: Dictionary, dt: float, mech: String, bhp: float) -> void:
	var seal_map: Dictionary = m.get("sealed", {})
	match mech:
		"grid":
			if not m.has("shield"):
				m["shield"] = bhp * Data.ORDER_SHIELD           # up as he comes out
				m["shield_max"] = m["shield"]
				m["shield_t"] = 0.0
			if float(m["shield"]) > 0.0:
				m["shield_t"] = float(m["shield_t"]) + dt
				if float(m["shield_t"]) >= Data.ORDER_SHIELD_WINDOW:
					m["shield"] = m["shield_max"]               # not broken in time: it fills again
					m["shield_t"] = 0.0
			else:
				m["shield_back"] = float(m.get("shield_back", 0.0)) - dt
				if float(m["shield_back"]) <= 0.0:
					m["shield"] = m["shield_max"]               # back up after a while
					m["shield_t"] = 0.0
		"archive":
			m["seal_t"] = float(m.get("seal_t", 0.0)) + dt
			if float(m["seal_t"]) >= Data.ORDER_SEAL_EVERY:
				m["seal_t"] = 0.0
				var slot: int = _seal_target(m)
				if slot >= 0:
					seal_map[str(slot)] = Data.ORDER_SEAL_FOR
					m["sealed"] = seal_map
				else:
					m["taped_t"] = Data.ORDER_SEAL_FOR
		"mint":
			m["print_t"] = float(m.get("print_t", 0.0)) + dt
			var every: float = Data.COLLECTOR_MEN_EVERY if str(m["boss"].get("mech", "")) == "collector" else Data.ORDER_PRINT_EVERY
			if float(m["print_t"]) >= every and int(m.get("printed", 0)) < Data.ORDER_PRINT_MAX:
				m["print_t"] = 0.0
				m["printed"] = int(m.get("printed", 0)) + 1
				m["print_pool"] = float(m.get("print_pool", 0.0)) + float(t["hp"])     # one of the host crew's men


## The skill the Registrar seals: the one you'd fire next - the first ready, else the nearest off its cooldown; -1
## with none slotted.
func _seal_target(m: Dictionary) -> int:
	if not m.has("sk"):
		return -1
	var best := -1
	var best_cd := INF
	for i in range(skill_slots.size()):
		var id: String = str(skill_slots[i])
		if id == "" or skill(id).is_empty() or not skill_known(id):
			continue
		var cd: float = float(m["sk"]["cd"][i])
		if cd < best_cd:
			best_cd = cd
			best = i
	return best


## The damage that landed on him this tick, taken first by the Lineman's shield or the Issuer's printed men. Breaking
## the shield stuns him; a printed man down is a kill.
func _order_absorb(m: Dictionary, t: Dictionary, hp_before: float, mech: String) -> void:
	var took: float = hp_before - float(m["target_hp"])
	if took <= 0.0:
		return
	if mech_shields(mech) and float(m.get("shield", 0.0)) > 0.0:
		var off: float = minf(float(m["shield"]), took)
		m["shield"] = float(m["shield"]) - off
		m["target_hp"] = float(m["target_hp"]) + off
		if float(m["shield"]) <= 0.0:
			m["stunned_t"] = Data.ORDER_SHIELD_STUN
			m["shield_back"] = Data.ORDER_SHIELD_BACK
			m["shield_breaks"] = int(m.get("shield_breaks", 0)) + 1
	elif mech_prints(mech) and float(m.get("print_pool", 0.0)) > 0.0:
		var off2: float = minf(float(m["print_pool"]), took)
		m["print_pool"] = float(m["print_pool"]) - off2
		m["target_hp"] = float(m["target_hp"]) + off2
		var left: int = int(ceil(float(m["print_pool"]) / maxf(float(t["hp"]), 1.0) - 0.001))
		var down: int = int(m.get("printed", 0)) - left
		if down > 0:
			m["printed"] = left
			m["kills"] = int(m["kills"]) + down
			m["printed_down"] = int(m.get("printed_down", 0)) + down
			_run_materials(m)                    # a printed man down is a kill to the run's material roll too (1 Nov, the review); not on a dry run
			m["grow_t"] = 0.0                    # the Collector's: one of his men down, what you take back to nothing
			for k in range(down):
				_heal(m, _kill_heal())             # a printed man down is a kill to the heals and the skills (25 Oct, the review); no drop, no pay
				_skills_on_kill(m)


## The fight's breakdown (24 Oct, the endgame chase): a run's damage by where it came from - "Gun name", "dot:fire",
## "skill:<id>", "grenades", "rule:<key>" - read on the run's report and the Stats room's breakdown.
func _count_src(m: Dictionary, key: String, amount: float) -> void:
	if amount <= 0.0 or not is_finite(amount) or key == "" or key == "skill:" or m.get("dry", false):
		return
	if not m.has("by_src"):
		m["by_src"] = {}
	m["by_src"][key] = minf(Data.COMBO_CEILING, float(m["by_src"].get(key, 0.0)) + amount)


## A run's fight in figures (24 Oct): the damage by source, biggest first (at most BREAKDOWN_ROWS, the rest "Other"),
## what hit you by type, each skill's uses and damage, the seconds fought. Words come from Words.BREAKDOWN.
func fight_breakdown(m: Dictionary) -> Dictionary:
	var src: Array = []
	var total := 0.0
	for k in m.get("by_src", {}):
		src.append([str(k), float(m["by_src"][k])])
		total += float(m["by_src"][k])
	src.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	var dealt: float = float(m.get("dealt", 0.0))
	var rows: Array = []
	for k in range(mini(src.size(), Data.BREAKDOWN_ROWS)):
		rows.append([src_words(str(src[k][0]), m), snappedf(float(src[k][1]), 1.0)])
	var rest: float = maxf(0.0, dealt - total) + (src.slice(Data.BREAKDOWN_ROWS).reduce(func(acc, e): return acc + float(e[1]), 0.0) if src.size() > Data.BREAKDOWN_ROWS else 0.0)
	if rest >= dealt * 0.005 and rest > 0.0:
		rows.append([Words.BREAKDOWN["other"], snappedf(rest, 1.0)])
	var took := {}
	for ty in m.get("taken_by", {}):
		if float(m["taken_by"][ty]) >= 1.0:
			took[str(ty)] = snappedf(float(m["taken_by"][ty]), 1.0)
	var skills: Array = []
	for id in m.get("sk_uses", {}):
		skills.append([str(skill(str(id)).get("name", id)), int(m["sk_uses"][id]), snappedf(float(m.get("by_src", {}).get("skill:" + str(id), 0.0)), 1.0)])
	return {"dealt": snappedf(dealt, 1.0), "s": snappedf(float(m.get("fight_s", 0.0)), 0.1), "src": rows, "took": took, "skills": skills,
		"meds": int(m.get("meds_used", 0)), "stopped": snappedf(mitigation(), 0.001)}


## A breakdown source's words: a gun's name, "Burning", a skill's name.
func src_words(key: String, m := {}) -> String:
	if key.begins_with("dot:"):
		return str(Words.BREAKDOWN.get(key, key.trim_prefix("dot:")))
	if key.begins_with("skill:"):
		var id: String = key.trim_prefix("skill:")
		var uses: int = int(m.get("sk_uses", {}).get(id, 0))
		return str(skill(id).get("name", id)) + ((" · %d use%s" % [uses, "" if uses == 1 else "s"]) if uses > 0 else "")
	if key.begins_with("rule:") or key == "grenades" or key == "fists":
		return str(Words.BREAKDOWN.get(key, key))
	return key


## The gun the tick's hits are counted to: the primary while it has rounds (or is a blade), else the secondary.
func _gun_src() -> String:
	var p = equipped.get("Primary", null)
	if p != null and (has_rounds(p) or has_rule("qm_rifle")):
		return Items.full_name(p)
	var sec = equipped.get("Secondary", null)
	return Items.full_name(sec) if sec != null else "fists"


## Their fire on you this tick, through Guard first: what's left comes off HP. "Guard gone" when it breaks.
func _take(m: Dictionary, amount: float) -> float:
	var g: float = float(m.get("guard", 0.0))
	if g > 0.0:
		var off: float = minf(g, amount)
		m["guard"] = g - off
		m["guarded"] = float(m.get("guarded", 0.0)) + off     # for the run screen
		amount -= off
		if m["guard"] <= 0.0 and g >= guard_cap() * 0.05 and not m.get("dry", false):
			log_event(Words.LOG["guard_gone"])              # a Guard worth the name broken, never a trickle of overheal (the review)
	if has_rule("bomb_suit"):
		# the Bomb Disposal Suit (a mythic): never more than a twentieth of your HP in a second of the run
		var sec := int(float(m.get("elapsed", 0.0)))
		if int(m.get("suit_s", -1)) != sec:
			m["suit_s"] = sec
			m["suit_took"] = 0.0
		amount = minf(amount, maxf(0.0, max_hp() * Data.MYTHIC_HURT_A_SECOND - float(m["suit_took"])))
		m["suit_took"] = float(m["suit_took"]) + amount
	hp -= amount
	return amount


func _boss_entry(b: Dictionary) -> Dictionary:
	return {"name": b["name"], "hp": b["hp"], "dps": b["dps"], "zone": b["zone"], "pinnacle": b.get("pinnacle", false), "order": str(b.get("order", "")), "mech": str(b.get("mech", b.get("order", ""))), "remix": bool(b.get("remix", false)), "started": false, "alive": true}


## A run's event on the dice, or "" (1 Nov, run events; docs/design/run_events.md): EVENT_ODDS of runs (every run with the
## Caretaker's Keys), the family weighted by the site `i`'s kind, zone, weather and the night and its level `lv` (none
## of those with no site), never the family the last run had; no threat passing in the first CONVOY_FROM_RUN runs (17 Oct,
## Matt: a convoy on the very first Allotments run took both starter bandages).
func roll_event(i := -1, lv := 0) -> String:
	if not (rng.randf() < Data.EVENT_ODDS or has_rule("caretakers_keys")):
		return ""
	var fams: Array = []
	var ws: Array = []
	var total := 0.0
	for f in Data.EVENT_ORDER:
		var w: float = event_weight(f, i, lv)
		if w > 0.0:
			fams.append(f)
			ws.append(w)
			total += w
	if fams.is_empty():
		return ""
	var r: float = rng.randf() * total
	for k in range(fams.size()):
		r -= float(ws[k])
		if r <= 0.0:
			return fams[k]
	return fams.back()


## A family's weight on the dice at site `i` (-1: no site) of level `lv`; 0 when it can't come. The six BUILD46-E families
## are scaled down together wherever they'd take the slice's four (EVENT_SLICE) under EVENT_SLICE_MIN of the events (fix 46,
## E7: the four the designer said "play well" fell to 47% at the Relay).
func event_weight(f: String, i := -1, lv := 0) -> float:
	var w: float = _event_raw(f, i, lv)
	if w <= 0.0 or f in Data.EVENT_SLICE:
		return w
	var four := 0.0
	var six := 0.0
	for g in Data.EVENT_ORDER:
		if g in Data.EVENT_SLICE:
			four += _event_raw(g, i, lv)
		else:
			six += _event_raw(g, i, lv)
	var room: float = four * (1.0 - Data.EVENT_SLICE_MIN) / Data.EVENT_SLICE_MIN
	return w * minf(1.0, room / six) if six > 0.0 else w


func _event_raw(f: String, i := -1, lv := 0) -> float:
	var fd: Dictionary = Data.EVENT_FAMILIES[f]
	if f == event_last or runs_total < int(fd.get("from_run", 0)) or (bool(fd.get("threat", false)) and runs_total < Data.CONVOY_FROM_RUN):
		return 0.0
	var w: float = float(fd["weight"])
	if bool(fd.get("threat", false)) and not thread_list("robbed").is_empty():
		w *= Data.ROBBED_THREAT                # a crew you robbed is out there (BUILD46-E threads)
	if i >= 0:
		w *= _event_lean(fd, i) * (1.0 + float(fd.get("level", 0.0)) * maxi(0, lv))
		var zm: Array = fd.get("zone", [])
		var z: int = zone_of(i)
		if z >= 0 and z < zm.size():
			w *= float(zm[z])
	return w


## An entry's leaning at site `i`: by its kind, the night and the weather (a multiplier each, 1 unnamed).
func _event_lean(e: Dictionary, i: int) -> float:
	var w: float = float(e.get("kind", {}).get(Data.SITE_KIND[i] if i < Data.SITE_KIND.size() else "", 1.0))
	if is_night():
		w *= float(e.get("night", 1.0))
	w *= float(e.get("weather", {}).get(fight_weather_of(i), 1.0))
	return w


## One of a pool's entries for site `i` (Data.EVENT_POOLS), on the run's dice: those for its zone, by their weights.
func _pool_pick(key: String, i: int) -> Dictionary:
	var z: int = zone_of(i)
	var rows: Array = Data.EVENT_POOLS[key].filter(func(e): return not e.has("zones") or z in e["zones"])
	if rows.is_empty():
		rows = Data.EVENT_POOLS[key]
	var total := 0.0
	var ws: Array = []
	for e in rows:
		var w: float = float(e.get("weight", 1.0)) * _event_lean(e, i)
		ws.append(w)
		total += w
	var r: float = rng.randf() * total
	for k in range(rows.size()):
		r -= float(ws[k])
		if r <= 0.0:
			return rows[k]
	return rows.back()


## The run's event out now ({} with none): {fam, state "ask"/"fight"/"done", zone, line, and its slots}.
func event_now() -> Dictionary:
	if mission == null or not mission.has("ev"):
		return {}
	return mission["ev"]


## A run event's choice is waiting.
func event_asking() -> bool:
	return str(event_now().get("state", "")) == "ask"


## The gang clock stopped for a choice (1 Nov): an event that isn't a threat, asking. A threat never pauses.
func event_paused(m) -> bool:
	if m == null or not m.has("ev"):
		return false
	var ev: Dictionary = m["ev"]
	return str(ev.get("state", "")) == "ask" and str(ev.get("fam", "")) != "threat"


## The lull between gangs: the site cleared and its first search done (the fix round, G1: the pack can hold scrap for
## the Scrap man by then), nobody on you, no head waiting, the way out not started, no Ghost's clear pending (G10);
## never a dry run.
func event_lull(m: Dictionary) -> bool:
	if m.get("dry", false) or m.get("way_out", false) or int(m["remaining"]) > 0 or not m["cleared"] or m.get("ghost_pending", false):
		return false
	if int(m.get("searches", 0)) < 1 and not a51_nothing_to_search(m):
		return false                         # after a first search, or none to make: a picked-over site's lull opens too (BUILD51-A)
	return not (m.has("boss") and bool(m["boss"]["alive"]))


## The event comes into the scene: its slots from the pools, its line in the log. Asked on a watched run; else the
## standing orders answer at once.
func _event_arrive(m: Dictionary) -> void:
	var fam: String = str(m["event"])
	m["event_at"] = -1.0
	m["event_done"] = fam
	event_last = fam
	var i: int = int(m["tier"])
	var z: int = clampi(zone_of(i), 0, 3)
	var ev := {"fam": fam, "state": "ask", "zone": z, "at": float(m["elapsed"])}
	var lines: Array = []
	match fam:
		"need":
			var who: Dictionary = _pool_pick("need_who", i)
			var what: Dictionary = _pool_pick("need_what", i)
			ev["who"] = str(who["w"])
			ev["he"] = str(who.get("he", "he"))
			ev["what"] = str(what["w"])
			ev["it"] = str(what.get("it", "it"))
			ev["pin"] = bool(what.get("pin", true))
			lines = Words.EV["need_pin" if ev["pin"] else "need_hurt"][z]
		"locked":
			var lw: Dictionary = _pool_pick("locked_what", i)
			ev["what"] = str(lw["w"])
			ev["door"] = bool(lw.get("door", false))
			ev["art"] = str(lw.get("art", "cabinet"))     # its picture (BUILD46-E: art/events/<art>_shut / _open.png)
			lines = Words.EV["locked"][z]
		"threat":
			ev["n"] = clampi(PATROL_BASE + int(m["patrols"]) + Data.DOGS_MORE, 2, Data.DOGS_MAX)
			ev["close_t"] = Data.DOGS_CLOSE_S
			ev["who"] = _threat_who(m, z)          # the dogs, or a rival crew (BUILD46-E): their own gang, carrying
			if str(ev["who"]) == "crew":
				_crew_arrive(m, ev)
			if asks and not m.get("unwatched", false):
				_dogs_job = {"ev": ev, "job": _dogs_begin(m, int(ev["n"]), threat_as(ev, m))}     # a watched run: taken now, read a few ms a frame (BUILD43)
			elif asks:
				_c51_dogs_begin(m, ev)             # (BUILD51-C) a repeat's run in the game: stepped too, the run held till it's read
			else:
				ev["odds"] = _dogs_read(m, int(ev["n"]), threat_as(ev, m))     # read once as they come: the face, and the standing order's
			lines = Words.EV["dogs"][z] if str(ev["who"]) == "dogs" else Words.EV["crew_back" if bool(ev.get("back", false)) else "crew"][z]
		"trader":
			ev["who"] = _trader_who(m)
			ev["bought"] = []
			ev["trades"] = 0
			var known: bool = int(trader_standing.get(str(ev["who"]), 0)) > 0     # a trader remembers you (BUILD46-E threads)
			var says: Array = Words.EV[("vag_says" if str(ev["who"]) == "vagabond" else "trader_says") + ("_known" if known else "")]
			ev["says"] = says[rng.randi_range(0, says.size() - 1)]
			lines = Words.EV["vagabond" if str(ev["who"]) == "vagabond" else "trader"][z]
			if str(ev["who"]) == "vagabond":
				_vag_stock(m, ev)
		"danger", "stash", "body", "wreck", "broadcast", "weather":
			lines = _event_slots(m, ev, i, z)
	lines = _event_lines(lines, ev, i)
	var pick = lines[rng.randi_range(0, lines.size() - 1)]
	ev["line"] = event_fill(str(pick["t"]) if pick is Dictionary else str(pick), ev)
	m["ev"] = ev
	log_event(ev["line"])
	if (not asks or m.get("unwatched", false)) and not _c51_dogs_held(m):     # (BUILD51-C) the dogs' order once they're read
		_event_by_orders(m)


## A zone's lines that suit the moment: a line with "kind" only at those site kinds, "night" only at night, "door" only
## for a locked thing with a door; all of them if none suit.
func _event_lines(lines: Array, ev: Dictionary, i: int) -> Array:
	var ok: Array = lines.filter(func(l):
		if not (l is Dictionary):
			return true
		if l.has("kind") and not (Data.SITE_KIND[i] in l["kind"]):
			return false
		if bool(l.get("night", false)) and not is_night():
			return false
		return not bool(l.get("door", false)) or bool(ev.get("door", false)))
	return ok if not ok.is_empty() else lines


## A line's slots filled from the event's: {who} {what} {it} {n}, and the pronouns {he} {him} {his} ({He} capitalised).
static func event_fill(text: String, ev: Dictionary) -> String:
	var she: bool = str(ev.get("he", "he")) == "she"
	var p := {"he": "she" if she else "he", "him": "her" if she else "him", "his": "her" if she else "his"}
	text = text.replace("{who}", str(ev.get("who", ""))).replace("{what}", str(ev.get("what", ""))).replace("{it}", str(ev.get("it", ""))).replace("{n}", str(int(ev.get("n", 0))))
	text = text.replace("{prize}", str(ev.get("prize", "")))     # BUILD46-E: a dangerous place's prize
	for k in p:
		text = text.replace("{%s}" % k, p[k]).replace("{%s}" % Words.cap1(k), Words.cap1(p[k]))
	return text


## The pronouns of the one in need: [he, him, his].
static func event_pron(ev: Dictionary) -> Array:
	return ["she", "her", "her"] if str(ev.get("he", "he")) == "she" else ["he", "him", "his"]


## Pulling them out clean, as the face says: NEED_CLEAN, less the night's, the weather's and under half HP's shares.
func need_clean_odds() -> float:
	var c: float = Data.NEED_CLEAN
	if mission == null:
		return c
	var i: int = int(mission["tier"])
	if is_night():
		c -= Data.NEED_CLEAN_NIGHT
	if fight_weather_of(i) != "":
		c -= Data.NEED_CLEAN_WEATHER
	if hp < max_hp() * 0.5:
		c -= Data.NEED_CLEAN_LOW_HP
	return clampf(c, Data.NEED_CLEAN_MIN, Data.NEED_CLEAN_MAX)


## The choices a non-threat event offers now, in the panel's order: [{key, text, face (forms long to short), ok}].
## "Leave" is always there and always open. A trader's shelf is trader_shelf().
func event_options() -> Array:
	var ev: Dictionary = event_now()
	var out: Array = []
	match str(ev.get("fam", "")):
		"need":
			var pr: Array = event_pron(ev)
			var pin: bool = bool(ev.get("pin", true))
			var free := {"key": "free", "text": (Words.EV["free"] if pin else Words.EV["patch"]) % pr[1], "ok": true, "s": Data.NEED_FREE_S}
			if pin:
				var c: int = roundi(need_clean_odds() * 100.0)
				var slip: int = roundi(Data.NEED_SLIP * 100.0)
				free["face"] = [Words.EV["free_pin"][0] % [int(Data.NEED_FREE_S), c, 100 - c, str(ev.get("it", "it")), slip], Words.EV["free_pin"][1] % [int(Data.NEED_FREE_S), c, slip]]
			else:
				var med: Dictionary = first_med()
				free["ok"] = not med.is_empty()
				free["face"] = [Words.EV["free_hurt"] % [int(Data.NEED_FREE_S), Words.a_med(str(med["base"]))]] if not med.is_empty() else [Words.EV["free_no_med"]]
			out.append(free)
			out.append({"key": "bag", "text": Words.EV["bag"] % pr[2], "face": [Words.EV["bag_face"] % [int(Data.NEED_BAG_S), Words.cap1(pr[0])]], "ok": true, "s": Data.NEED_BAG_S})
			out.append({"key": "leave", "text": Words.EV["leave_him"] % pr[1], "face": [Words.EV["nothing"]], "ok": true, "s": 0.0})
		"locked":
			out.append({"key": "force", "text": Words.EV["force"], "ok": true, "face": [Words.EV["force_face"] % [int(Data.LOCK_FORCE_S), int(Data.LOCK_NOISE_S)]], "s": Data.LOCK_FORCE_S})
			var can: bool = lock_rounds_slot() != ""
			out.append({"key": "shoot", "text": Words.EV["shoot"], "ok": can, "face": [Words.EV["shoot_face"] % [int(Data.LOCK_SHOOT_S), Data.LOCK_ROUNDS]] if can else [Words.EV["shoot_no"]], "s": Data.LOCK_SHOOT_S})
			out.append({"key": "leave", "text": Words.EV["leave_it"], "face": [Words.EV["nothing"]], "ok": true, "s": 0.0})
		"danger", "stash", "body", "wreck", "broadcast", "weather":
			out = _options_more(ev)                # BUILD46-E
	# a choice whose seconds would run the run's clock out is greyed (the fix round, G8)
	for o in out:
		if float(o["s"]) > 0.0 and bool(o["ok"]) and not event_time_for(float(o["s"])):
			o["ok"] = false
			o["face"] = [Words.EV["no_time"]]
	return out


## Whether the run's clock has `s` seconds of a choice in it, at the search's rate, with a second to spare.
func event_time_for(s: float) -> bool:
	if mission == null or has_rule("bomb_suit"):
		return true
	return float(mission.get("clock", 0.0)) - s * Data.CLOCK_SEARCH_RATE > 1.0


## The gun whose magazines hold LOCK_ROUNDS to spare for a lock, "" for none (a gun with no magazine has no rounds to spare).
func lock_rounds_slot() -> String:
	for slot in ["Primary", "Secondary"]:
		if equipped[slot] != null and uses_mag(slot) and mag_rounds(slot) >= Data.LOCK_ROUNDS:
			return slot
	return ""


## The rounds in a slot's magazines: the one in it and the rig's of its type.
func mag_rounds(slot: String) -> int:
	if equipped[slot] == null or not uses_mag(slot):
		return 0
	var ty: String = Items.ammo_type(equipped[slot])
	var n := 0
	for it in rig:
		if Items.is_mag(it) and Items.mag_type(it) == ty:
			n += int(it.get("rounds", 0))
	return n


## Rounds out of a slot's magazines, the one in the gun first, then the rig's of its type.
func _spend_rounds(slot: String, n: int) -> void:
	var ty: String = Items.ammo_type(equipped[slot])
	var mags: Array = []
	var cur: Dictionary = mag_in(slot)
	if not cur.is_empty():
		mags.append(cur)
	for it in rig:
		if Items.is_mag(it) and Items.mag_type(it) == ty and not mags.has(it):
			mags.append(it)
	for mg in mags:
		var k: int = mini(n, int(mg.get("rounds", 0)))
		mg["rounds"] = int(mg.get("rounds", 0)) - k
		n -= k
		if n <= 0:
			return


## A choice taken on a non-threat event (the panel's buttons, the standing orders): its cost and its reward land, the
## scene's state moves on and the clock goes again. False when it can't be taken.
func event_pick(key: String) -> bool:
	var ev: Dictionary = event_now()
	if not event_asking() or str(ev["fam"]) in ["threat", "trader"]:
		return false
	var opt: Array = event_options().filter(func(o): return o["key"] == key)
	if opt.is_empty() or not bool(opt[0]["ok"]):
		return false
	var m: Dictionary = mission
	var t: Dictionary = m["t"]
	var pr: Array = event_pron(ev)
	var who: String = str(ev.get("who", ""))
	if key == "home":
		log_event(Words.EV["headed_home"])     # the weather turning: out now with the pack (BUILD46-E)
		_event_close(m, "home")
		get_out()
		return true
	match key:
		"free":
			_event_spend(m, Data.NEED_FREE_S)
			if bool(ev.get("pin", true)):
				if rng.randf() < need_clean_odds():
					log_event(Words.EV["freed"] % [who, Words.cap1(pr[0])])
				else:
					var lost: float = minf(max_hp() * Data.NEED_SLIP, maxf(0.0, hp - 1.0))     # never the last of it
					hp -= lost
					ev["slipped"] = true
					log_event(Words.EV["freed_slip"] % [Words.cap1(str(ev.get("it", "it"))), roundi(lost), pr[0]])
			else:
				var med: Dictionary = first_med()
				rig.erase(med)
				log_event(Words.EV["freed_med"] % [who, Words.a_med(str(med["base"])), Words.cap1(pr[0])])
			var pool: Array = []
			for row in Data.TRAITS:
				if row["name"] != runner_trait:
					pool.append(row["name"])
			promised = pool[rng.randi_range(0, pool.size() - 1)]     # the trapped runner's thread: a candidate when a runner's next needed
			event_threads["freed"] = int(event_threads.get("freed", 0)) + 1
		"bag":
			_event_spend(m, Data.NEED_BAG_S)
			_find(m, t)
			event_threads["bag"] = int(event_threads.get("bag", 0)) + 1     # they remember it
			_thread_add("robbed", {"zone": int(ev.get("zone", 0)), "run": runs_total})     # BUILD46-E: their crew may come for it
			log_event(Words.EV["bagged"] % Words.cap1(pr[0]))
		"force":
			_event_spend(m, Data.LOCK_FORCE_S)
			m["patrol_timer"] = float(m["patrol_timer"]) + Data.LOCK_NOISE_S     # the noise: the next gang sooner
			log_event(Words.EV["forced"])
			_event_cache(m, t)
		"shoot":
			_event_spend(m, Data.LOCK_SHOOT_S)
			_spend_rounds(lock_rounds_slot(), Data.LOCK_ROUNDS)
			log_event(Words.EV["shot"] % Data.LOCK_ROUNDS)
			_event_cache(m, t)
		"leave":
			var fam_l: String = str(ev["fam"])
			log_event(Words.EV["left_him"] % pr[1] if fam_l == "need" else (Words.EV["left_it"] if fam_l == "locked" else (Words.EV["let_passed"] if fam_l == "weather" else Words.EV["left_be"])))
		_:
			_pick_more(m, t, ev, key)              # BUILD46-E: the other six
	if mission == null:
		return true
	_event_close(m, key)
	return true


## The choice made: the scene shows how it went, the clock goes again.
func _event_close(m: Dictionary, outcome: String) -> void:
	var ev: Dictionary = m["ev"]
	ev["state"] = "done"
	ev["outcome"] = outcome
	ev["done_at"] = float(m["elapsed"])
	_dry_memo.clear()
	_stats_dirty()


## Time an event's choice costs: the gang clock moves on (the next gang that much sooner) and the run's clock spends it.
func _event_spend(m: Dictionary, s: float) -> void:
	m["patrol_timer"] = float(m["patrol_timer"]) + s
	m["elapsed"] = float(m["elapsed"]) + s     # the run's time and the world's (the fix round: a choice's seconds are played)
	elapsed += s
	if not has_rule("bomb_suit"):
		m["clock"] = float(m.get("clock", 0.0)) - s * Data.CLOCK_SEARCH_RATE
		m["clock_used"] = float(m.get("clock_used", 0.0)) + s * Data.CLOCK_SEARCH_RATE


## A locked thing open: a find a tier up (the cache's, as it paid: 9 Oct, opened at any Bench).
func _event_cache(m: Dictionary, t: Dictionary) -> void:
	var up: Dictionary = t.duplicate()
	up["loot_tier"] = mini(loot_cap(int(t.get("level", lv_at(int(t["tier"]), int(t["depth"]))))), int(t["loot_tier"]) + 1)
	up["rarity"] = float(t.get("rarity", 0.0)) + Data.LOCK_RARITY
	_find(m, up)


# ------------------------------------------------------------------ a threat passing: the dogs (1 Nov)

## The dogs standing in the scene, the choice open: the gang clock holds for them (they're the threat at hand).
func dogs_waiting(m: Dictionary) -> bool:
	return m.has("ev") and str(m["ev"].get("fam", "")) == "threat" and str(m["ev"].get("state", "")) == "ask"


## The dogs as a gang: the site's gang at DOG_HP and DOG_DPS a dog, its damage types and resists as the site's gang has
## them (the fix round, G3: a bite through armour alone made them far easier than "about a normal gang at the site";
## a pack off the moor fights at the Outskirts' weight, one off the motorway at the City's), carrying nothing.
static func dogs_t(t: Dictionary) -> Dictionary:
	var d: Dictionary = t.duplicate()
	d["hp"] = float(t["hp"]) * Data.DOG_HP
	d["dps"] = float(t["dps"]) * Data.DOG_DPS
	d["xp"] = float(t["xp"]) * Data.DOG_XP
	d["drop"] = 0.0
	d["no_kill_cash"] = true
	d["dogs"] = true
	return d


## The odds on the dogs' face: read as they came (_dogs_read), the share of DOG_READS short dry fights won.
func dogs_odds() -> float:
	var ev: Dictionary = event_now()
	if ev.is_empty() or str(ev["fam"]) != "threat":
		return 0.0
	if not ev.has("odds"):
		if not _dogs_job.is_empty() and is_same(_dogs_job["ev"], ev):
			_dogs_job_run(-1)                     # the read begun as they came, to its end now (BUILD43)
		else:
			ev["odds"] = _dogs_read(mission, int(ev["n"]), threat_as(ev, mission))
	return float(ev["odds"])


## The dogs read through the real fight code (the fix round, G2/G3: the formula missed reloads, dots, the swing and the
## crowd): DOG_READS fights of `n` dogs from where the runner stands now (HP, Guard, the rig), on a scratch mission with
## the odds' own seeded dice, DOG_READ_STEP seconds a tick, a med under 40% as the Use button, lost under BAIL; won when
## they're all down. Nothing kept - HP, XP, the rig, the log, the run and the run's dice go back as they were.
## `as_t`, given, reads that gang instead (a normal gang of the site's, for the dogs' tuning and its check).
func _dogs_read(live: Dictionary, n: int, as_t: Dictionary = {}) -> float:
	var job := _dogs_begin(live, n, as_t)
	_dogs_steps(job, -1)
	return _dogs_finish(job)


## The dogs' read in parts (BUILD43, perf43's spike: six dry fights, 267-314 ms in one frame), as the dry run's: what
## the fights start from taken as the dogs come (HP, the rig, the pack's boxes, the magazines, Guard), the fights run
## back to back by _dogs_read, or a few ms a frame on a watched run (dogs_read_step) while they stand.
func _dogs_begin(live: Dictionary, n: int, as_t: Dictionary = {}) -> Dictionary:
	var site_t: Dictionary = live.get("dogs_home", live["t"])
	var d: Dictionary = dogs_t(site_t) if as_t.is_empty() else as_t
	var keep := {"hp": hp, "xp": xp, "rig": rig.duplicate(true), "events": events.duplicate(true), "mission": mission,
		"rng": rng, "promised": promised, "training_points": training_points, "best_level": best_level, "insure_next": insure_next, "events_total": events_total}
	var mags := {}
	for mk in ["fire_x", "mag_in", "reload_t", "reload_to", "refill"]:
		if live.has(mk):
			mags[mk] = live[mk].duplicate(true)     # the magazines as they stand, and the pack's boxes below: the refills a fight has
	return {"keep": keep, "d": d, "n": n, "tier": int(live["tier"]), "guard_hp": float(live.get("guard", 0.0)),
		"ammo": live["found"].filter(func(x): return Items.is_ammo(x)).duplicate(true), "mags": mags, "k": 0, "won": 0, "m": null, "guard": 0,
		"elapsed": elapsed, "live_elapsed": elapsed}


## The fights, until the last is done or the clock passes `until_us` (-1: to the end); true when they're all done.
## Expects the live state in place between fights and the fight's own in one (as _dry_steps).
func _dogs_steps(job: Dictionary, until_us: int) -> bool:
	var keep: Dictionary = job["keep"]
	var d: Dictionary = job["d"]
	var n: int = job["n"]
	var ticks := 0
	while int(job["k"]) < Data.DOG_READS:
		var m = job["m"]
		if m == null:
			var r := RandomNumberGenerator.new()
			r.seed = hash([int(job["tier"]), n, roundi(keep["hp"])]) + int(job["k"])
			rng = r
			hp = keep["hp"]
			rig = keep["rig"].duplicate(true)
			m = {
				"tier": int(job["tier"]), "t": d, "remaining": n, "target_hp": float(d["hp"]), "kills": 0, "found": Array(job["ammo"]).duplicate(true), "insured": false, "clock": 1e9,
				"left": 0, "cash": 0.0, "xp": 0.0, "elapsed": 0.0, "hp_start": hp, "cleared": true, "guard": float(job["guard_hp"]),
				"search": 0.0, "searches": 0, "patrol_timer": -1e9, "patrols": 0, "last_incoming": 0.0,
				"using": null, "meds_used": 0, "fresh": true, "swapped": 0, "chill_t": 0.0, "event": "", "event_at": -1.0, "dry": true,
			}
			for mk in job["mags"]:
				m[mk] = job["mags"][mk].duplicate(true)
			_combo_warm(m)
			mission = m
			_dry_rules = _snapshot_rules()
			_dry_memo = {}
			_dry_on = true
			_gang_arrives(m)
			job["m"] = m
			job["guard"] = 0
		var guard_v: int = job["guard"]
		while guard_v * Data.DOG_READ_STEP < Data.DOG_READ_MAX_S and not m.get("dead", false):
			if until_us >= 0 and ticks > 0 and Time.get_ticks_usec() >= until_us:
				job["guard"] = guard_v
				return false
			ticks += 1
			_tick(Data.DOG_READ_STEP)
			if hp < max_hp() * BAIL:
				m["dead"] = true
			if m.get("dead", false) or int(m["remaining"]) <= 0:
				break
			if m["using"] == null and hp < max_hp() * 0.4 and not first_med().is_empty():
				use_med(first_med()["id"])
			guard_v += 1
		if not m.get("dead", false) and int(m["remaining"]) <= 0:
			job["won"] = int(job["won"]) + 1
		_dry_on = false
		job["m"] = null
		job["k"] = int(job["k"]) + 1
	return true


func _dogs_finish(job: Dictionary) -> float:
	var keep: Dictionary = job["keep"]
	hp = keep["hp"]
	xp = keep["xp"]
	rig = keep["rig"]
	events = keep["events"]
	mission = keep["mission"]
	rng = keep["rng"]
	promised = keep["promised"]
	training_points = keep["training_points"]
	best_level = keep["best_level"]
	insure_next = keep["insure_next"]
	events_total = keep["events_total"]
	elapsed = job["live_elapsed"]
	_dry_memo.clear()
	_stats_dirty()
	return float(job["won"]) / float(Data.DOG_READS)


## The dogs' read on a watched run (BUILD43): begun as they come (_event_arrive, the moment the old read was taken),
## stepped a few ms a frame by the shell; the panel reads "reading…" until it's done. Not saved: a load reads afresh.
var _dogs_job := {}


## Whether the dogs' odds are still being read: the panel's "reading…".
func dogs_reading() -> bool:
	var ev: Dictionary = event_now()
	return not _dogs_job.is_empty() and is_same(_dogs_job["ev"], ev) and not ev.has("odds")


## The shell's frame: the dogs' read on for `ms`, from where it stopped. Done, the odds go on the event as the old
## read put them there.
func dogs_read_step(ms: float) -> void:
	if _dogs_job.is_empty() or _dogs_job.get("unwatched", false):     # (BUILD51-C) a repeat's run's read is advance()'s
		return
	var ev: Dictionary = event_now()
	if not is_same(_dogs_job["ev"], ev) or ev.has("odds") or mission == null or not dogs_waiting(mission):
		_dogs_job = {}                        # gone, read some other way (dogs_odds at the order's call), or answered: nothing reads it now
		return
	_dogs_job_run(Time.get_ticks_usec() + int(ms * 1000.0))


## The job on to `until_us` (-1: the end): its own state in for the ticks, the live state back after.
func _dogs_job_run(until_us: int) -> void:
	var job: Dictionary = _dogs_job["job"]
	var live := {}
	for k in DRY_KEPT:
		live[k] = get(k)
	var live_elapsed := elapsed
	elapsed = job["elapsed"]                  # the read's moment, as the old read was one frame's
	var own: Dictionary = _dogs_job.get("own", {})
	for k in own:
		set(k, own[k])
	if job["m"] != null:
		_dry_on = true
	var done := _dogs_steps(job, until_us)
	if done:
		job["live_elapsed"] = live_elapsed
		job["keep"] = live                    # what goes back is the live state as it is now
		var ev: Dictionary = _dogs_job["ev"]
		_dogs_job = {}
		ev["odds"] = _dogs_finish(job)
		return
	var keep_own := {}
	for k in DRY_KEPT + DRY_OWN:
		keep_own[k] = get(k)
	_dogs_job["own"] = keep_own
	_dry_memo = {}                            # as _dry_park (review 43, 6)
	_dry_rules = {}
	_dry_on = false
	for k in DRY_KEPT:
		set(k, live[k])
	elapsed = live_elapsed


## The run's own odds, as the Runs card read them at the gate (a threat's standing order); EVENT_FIGHT_AT unread.
func run_odds(m: Dictionary) -> float:
	var o: float = float(m.get("odds_seen", -1.0))
	return o if o >= 0.0 else Data.EVENT_FIGHT_AT


## The dogs' seconds in the lull run down; then they come on.
func _dogs_tick(m: Dictionary, dt: float) -> void:
	if not dogs_waiting(m):
		return
	m["ev"]["close_t"] = float(m["ev"].get("close_t", 0.0)) - dt
	if float(m["ev"]["close_t"]) <= 0.0:
		dogs_fight()


## Stand and fight: the dogs on you as a gang on the normal rules, the site's own gang put by till they're down.
func dogs_fight() -> bool:
	if mission == null or not dogs_waiting(mission):
		return false
	var m: Dictionary = mission
	var ev: Dictionary = m["ev"]
	ev["state"] = "fight"
	m["dogs_home"] = m["t"]
	m["t"] = threat_t(ev, m["t"])            # the dogs, or a rival crew (BUILD46-E)
	m["remaining"] = int(m["remaining"]) + int(ev["n"])
	m["target_hp"] = float(m["t"]["hp"])
	m["fresh"] = true
	m.erase("opened")
	m["sustain_t"] = 0.0
	_gang_arrives(m)
	_dry_memo.clear()
	_stats_dirty()
	log_event(Words.EV["crew_on" if str(ev.get("who", "dogs")) == "crew" else "dogs_on"])
	return true


## Get out now, with the dogs in the lull: the event's over ("out") and the run's own way out - home now once the site's
## cleared, else the way out with its gang (a Ghost's run: the fix round, U2).
func dogs_out() -> bool:
	if mission == null or not dogs_waiting(mission) or not can_extract():
		return false                          # no way out (Stand): the dogs stay (40-E review 9)
	_event_close(mission, "out")
	get_out()
	return true


## The dogs seen off: the site's own gang back, its next one DOGS_PUSH_S later.
func _dogs_done(m: Dictionary) -> void:
	m["t"] = m["dogs_home"]
	m.erase("dogs_home")
	m["target_hp"] = 0.0
	m["patrol_timer"] = float(m["patrol_timer"]) - Data.DOGS_PUSH_S
	_event_close(m, "fought")
	if str(m["ev"].get("who", "dogs")) == "crew":
		log_event(Words.EV["crew_off_push"] % int(Data.DOGS_PUSH_S))     # the push said, as the dogs' (fix 46, E11)
		_crew_paid(m)                          # BUILD46-E: what they carried, and maybe a crew that'll want it back
		return
	log_event(Words.EV["dogs_off"] % int(Data.DOGS_PUSH_S))


# ------------------------------------------------------------------ a trader: the Scrap man (1 Nov)

## The scrap in the pack's stacks.
func pack_scrap(m) -> int:
	if m == null:
		return 0
	var n := 0
	for it in m["found"]:
		if Items.is_scrap(it):
			n += Items.stack_size(it)
	return n


## Scrap out of the pack's stacks, the smallest first; a stack gone when it's spent.
func _take_scrap(m: Dictionary, n: int) -> void:
	var stacks: Array = m["found"].filter(func(it): return Items.is_scrap(it))
	stacks.sort_custom(func(a, b): return Items.stack_size(a) < Items.stack_size(b))
	for it in stacks:
		var k: int = mini(n, Items.stack_size(it))
		n -= k
		if Items.stack_size(it) - k <= 0:
			m["found"].erase(it)
		else:
			Items.set_stack(it, Items.stack_size(it) - k)
		if n <= 0:
			return


## A trader's standing step: how many of TRADER_STEPS his trades have reached.
func trader_step(key := "scrap_man") -> int:
	var n: int = int(trader_standing.get(key, 0))
	return Data.TRADER_STEPS.filter(func(s): return n >= int(s)).size()


## The trader's shelf now: [{key, text, price, ok, bought}] - his plate, magazines, the gang held up and a bandage, one
## of each a visit; from the first step the bandage is on the house, from the second everything 33% off.
func trader_shelf() -> Array:
	var ev: Dictionary = event_now()
	if str(ev.get("fam", "")) != "trader":
		return []
	if str(ev.get("who", "")) == "vagabond":
		return _vag_shelf(ev)                  # BUILD46-E
	var step: int = trader_step(str(ev["who"]))
	var have: int = pack_scrap(mission)
	var bought: Array = ev.get("bought", [])
	var out: Array = []
	for row in Data.TRADER_SHELF:
		var cost_v: int = int(ceil(float(row["price"]) * (1.0 - Data.TRADER_STEP_OFF))) if step >= 2 else int(row["price"])
		var text: String = ""
		match str(row["key"]):
			"plate":
				text = Words.EV["shelf_plate"] % int(trader_plate_pct())
			"mags":
				text = Words.EV["shelf_mags"]
			"held":
				text = Words.EV["shelf_held"] % int(row["held_s"])
			"bandage":
				text = Words.EV["shelf_bandage_free"] if step >= 1 else Words.EV["shelf_bandage"]
				if step >= 1:
					cost_v = 0
		var why: String = Words.EV["mags_none"] if str(row["key"]) == "mags" and not mags_short() else ""     # nothing to fill: not sold (40-E review 3)
		out.append({"key": row["key"], "text": text, "price": cost_v, "bought": row["key"] in bought, "why": why if not (row["key"] in bought) else "",
			"ok": not (row["key"] in bought) and have >= cost_v and event_asking() and why == ""})
	return out


## The plate's armour this run: TRADER_SHELF's, his good plate's from the third step.
func trader_plate_pct() -> float:
	return Data.TRADER_GOOD_PLATE if trader_step(str(event_now().get("who", "scrap_man"))) >= 3 else float(Data.TRADER_SHELF[0]["armour_pct"])


## The next step up his shelf: [trades it needs, its words, trades still to go], or [] at the top.
func trader_next_step() -> Array:
	var who: String = str(event_now().get("who", "scrap_man"))
	var n: int = int(trader_standing.get(who, 0))
	var k: int = trader_step(who)
	if k >= Data.TRADER_STEPS.size():
		return []
	var w: String = Words.EV["vag_step_words" if who == "vagabond" else "step_words"][k]
	if w.contains("%d"):
		w = w % int(Data.TRADER_GOOD_PLATE)
	return [int(Data.TRADER_STEPS[k]), w, int(Data.TRADER_STEPS[k]) - n]


## Buy off his shelf: scrap out of the pack, the buff for this run only (his rounds and his bandage go back to him at
## the run's end: _event_end). A paid one is a trade, counted on his standing when the visit ends; the bandage on the
## house isn't one. False when it can't be had.
func trader_buy(key: String) -> bool:
	var row: Array = trader_shelf().filter(func(r): return r["key"] == key)
	if row.is_empty() or not bool(row[0]["ok"]):
		return false
	if str(event_now().get("who", "")) == "vagabond":
		return _vag_buy(row[0])                # BUILD46-E
	var m: Dictionary = mission
	var ev: Dictionary = m["ev"]
	var cost_v: int = int(row[0]["price"])
	_take_scrap(m, cost_v)
	ev["bought"].append(key)
	var said: String = ""
	match key:
		"plate":
			m["buff_armour_pct"] = maxf(float(m.get("buff_armour_pct", 0.0)), trader_plate_pct())
			said = Words.EV["trade_plate"]
		"mags":
			_mags_from_his(m)
			said = Words.EV["trade_mags"]
		"held":
			m["patrol_timer"] = float(m["patrol_timer"]) - float(Data.TRADER_SHELF[2]["held_s"])
			said = Words.EV["trade_held"] % int(Data.TRADER_SHELF[2]["held_s"])
		"bandage":
			var b: Dictionary = _plain(Data.MEDICAL, "Bandage")
			b["his"] = true                      # run-only: what's left of it goes back at the run's end
			if rig_room(Items.size(b)):
				rig.append(b)
			else:
				_place_find(m, b)
			said = Words.EV["trade_bandage"]
	if cost_v > 0:
		ev["trades"] = int(ev.get("trades", 0)) + 1
		log_event(Words.EV["traded"] % [said, cost_v])
	else:
		log_event(Words.EV["traded_free"])
	_dry_memo.clear()
	_stats_dirty()
	_memo_age = 0.0
	return true


## Done with him: he pushes off, the visit's trades go on his count, and the clock goes again.
func trader_done() -> bool:
	if not event_asking() or str(event_now()["fam"]) != "trader":
		return false
	log_event(Words.EV["vag_gone" if str(event_now().get("who", "")) == "vagabond" else "trader_gone"])
	_trader_count(mission["ev"])
	_event_close(mission, "traded" if not event_now()["bought"].is_empty() else "leave")
	return true


## A visit's trades onto his standing, once (the fix round: a step never lands within the visit that earns it).
func _trader_count(ev: Dictionary) -> void:
	if bool(ev.get("counted", false)):
		return
	ev["counted"] = true
	var who: String = str(ev.get("who", "scrap_man"))
	trader_standing[who] = int(trader_standing.get(who, 0)) + int(ev.get("trades", 0))


## A worn gun's magazine in the rig short of full: his magazines have something to fill.
func mags_short() -> bool:
	for slot in ["Primary", "Secondary"]:
		if equipped[slot] == null or not uses_mag(slot):
			continue
		var ty: String = Items.ammo_type(equipped[slot])
		for it in rig:
			if Items.is_mag(it) and Items.mag_type(it) == ty and int(it.get("rounds", 0)) < Items.mag_cap(it, equipped[slot]):
				return true
	return false


## His magazines: every magazine in the rig of a worn gun's type full, the ones in the guns too - his rounds, not yours:
## what each held before is kept (m.his_mags) and what's left of his comes off at the run's end. An empty one takes the
## feed's grade, else the box's, as rounds on a kill do (the fix round, G4).
func _mags_from_his(m: Dictionary) -> void:
	var his: Dictionary = m.get("his_mags", {})
	for slot in ["Primary", "Secondary"]:
		if equipped[slot] == null or not uses_mag(slot):
			continue
		var gun: Dictionary = equipped[slot]
		var ty: String = Items.ammo_type(gun)
		for it in rig:
			if Items.is_mag(it) and Items.mag_type(it) == ty:
				var k: String = str(int(it["id"]))
				if not his.has(k):
					his[k] = int(it.get("rounds", 0))
				if str(it.get("ammo", "")) == "" or int(it.get("rounds", 0)) <= 0:
					var fed: String = Items.grade_name(feed_stack(gun))
					it["ammo"] = fed if fed != "" else str(ammo_box(ty).get("name", ""))
				it["rounds"] = Items.mag_cap(it, gun)
		if m.has("reload_t") and m["reload_t"].has(slot):
			m["reload_t"].erase(slot)
	m["his_mags"] = his
	_mags_topped(m)


## The run's end, whatever it was (the extract, a death; the fix round): the site's own gang back if the dogs were on
## (G9: the record reads the site, not the dogs), a visit's trades counted, and what the Scrap man sold run-only taken
## back - his bandage wherever it is, and his rounds off the top of each magazine he filled (G5).
func _event_end(m: Dictionary) -> void:
	if m.has("dogs_home"):
		m["t"] = m["dogs_home"]
		m.erase("dogs_home")
	for hk in ["clue_home", "turn_home"]:      # BUILD46-E: a body's clue's gang, the weather pressed on in - the record reads the site
		if m.has(hk):
			m["t"] = m[hk]
			m.erase(hk)
	if m.has("ev") and str(m["ev"].get("fam", "")) == "trader":
		_trader_count(m["ev"])
	for list in [rig, m["found"], m.get("floor", [])]:
		for it in (list as Array).duplicate():
			if bool(it.get("his", false)):
				(list as Array).erase(it)
	var his: Dictionary = m.get("his_mags", {})
	for it in rig:
		var k: String = str(int(it.get("id", -1)))
		if his.has(k) and Items.is_mag(it):
			it["rounds"] = mini(int(it.get("rounds", 0)), int(his[k]))
			if int(it["rounds"]) <= 0:
				it["ammo"] = ""
	m.erase("his_mags")


# ------------------------------------------------------------------ the standing orders (1 Nov)

## A family's standing order: the player's, else its first (Data.EVENT_ORDERS; a new family "leave").
func event_order(fam: String) -> String:
	var ch: Array = Data.EVENT_ORDERS.get(fam, ["leave"])
	var o: String = str(standing_orders.get(fam, ch[0]))
	return o if o in ch else str(ch[0])


func set_order(fam: String, key: String) -> bool:
	if not (key in Data.EVENT_ORDERS.get(fam, [])):
		return false
	standing_orders[fam] = key
	return true


## The event out now answered by its standing order (the bot's, a run asked with nobody to answer).
func event_by_orders() -> bool:
	if not event_asking():
		return false
	_event_by_orders(mission)
	return true


## A run nobody's watching (a repeat run, the bot, away) can't stop and ask: the event goes by its standing order.
func _event_by_orders(m: Dictionary) -> void:
	var ev: Dictionary = m["ev"]
	var fam: String = str(ev["fam"])
	var o: String = event_order(fam)
	match fam:
		"need":
			var free: Array = event_options().filter(func(x): return x["key"] == "free" and bool(x["ok"]))
			if o == "bag":
				event_pick("bag")
			elif o == "help_cheap" and not free.is_empty() and (not bool(ev.get("pin", true)) or need_clean_odds() >= Data.NEED_HELP_AT):
				event_pick("free")                 # "Help if it's a med or 70% clean": a med for the hurt, a pin at 70% or better
			else:
				event_pick("leave")
		"locked":
			if not (o in ["force", "shoot"] and event_pick(o)):
				event_pick("leave")
		"threat":
			var odds: float = dogs_odds()
			if o == "always" or (o == "odds_80" and odds >= 0.8) or (o == "odds_run" and odds >= run_odds(m)):
				dogs_fight()
			elif can_extract():
				log_event(Words.EV["crew_out" if str(ev.get("who", "dogs")) == "crew" else "dogs_out"] % [roundi(odds * 100.0), roundi((0.8 if o == "odds_80" else run_odds(m)) * 100.0)])
				_event_close(m, "out")
				extract_now()
			else:
				dogs_fight()                       # no way out (Stand): they come on
		"danger", "stash", "body", "wreck", "broadcast", "weather":
			_orders_more(m, ev, o)                 # BUILD46-E
		"trader":
			if o == "armour30" and pack_scrap(m) >= 30 and str(ev.get("who", "")) == "scrap_man":
				trader_buy("plate")
			elif o == "all":
				for row in trader_shelf():
					trader_buy(str(row["key"]))
			trader_done()


# ------------------------------------------------------------------ BUILD46-E (2 Nov): the other six families, the rival crew, the Vagabond, the threads

## The other six families' slots from the pools (docs/design/run_events.md's table), and the zone's lines for them.
## `art` names the prop's picture (art/events/<art>_shut.png and _open.png: event_prop.gd, shapes till they land).
func _event_slots(m: Dictionary, ev: Dictionary, i: int, z: int) -> Array:
	var fam: String = str(ev["fam"])
	match fam:
		"danger":
			var d: Dictionary = _pool_pick("danger_what", i)
			ev["what"] = str(d["w"])
			ev["it"] = str(d.get("it", "it"))
			ev["prize"] = str(_pool_pick("danger_prize", i)["w"])
			ev["art"] = "hazard"
		"stash":
			ev["art"] = "stash_bag"
			ev["what"] = str(_pool_pick("stash_what", i)["w"])
			if bool(m.get("event_tip", false)):
				ev["tip"] = true                   # a tip's stash (a thread): where they said, no catch
				return Words.EV["stash_tip"][z]
			var c: Dictionary = _pool_pick("stash_catch", i)
			ev["catch"] = str(c["w"])
			ev["catch_kind"] = str(c.get("catch", "trip"))
		"body":
			ev["art"] = "body"
			ev["who"] = str(_pool_pick("body_who", i)["w"])
		"wreck":
			ev["art"] = "wreck"
			ev["what"] = str(_pool_pick("wreck_what", i)["w"])
		"broadcast":
			ev["art"] = "radio"
			ev["what"] = str(_pool_pick("radio_what", i)["w"])
		"weather":
			var tn: Dictionary = _pool_pick("turn", i)
			if str(tn.get("not", "")) != "" and str(tn["not"]) == fight_weather_of(i):
				tn = Data.EVENT_POOLS["turn"][2]       # no fog rolling into a fog: the light going early instead
			ev["what"] = str(tn["w"])
			ev["loot"] = int(tn["loot"])
			ev["harder"] = int(tn["harder"])
			if bool(tn.get("alone", false)):
				return [Words.EV["weather"][z][1]]    # "The power comes back on. The streets go quiet." - never "... over the town"
	return Words.EV[fam][z]


## A risky choice's clean odds, as the face says: `base`, less the night's, the weather's and under half HP's shares (the
## pin's: NEED_CLEAN_NIGHT, _WEATHER, _LOW_HP), between NEED_CLEAN_MIN and NEED_CLEAN_MAX.
func event_clean_odds(base: float) -> float:
	var c: float = base
	if mission == null:
		return c
	if is_night():
		c -= Data.NEED_CLEAN_NIGHT
	if fight_weather_of(int(mission["tier"])) != "":
		c -= Data.NEED_CLEAN_WEATHER
	if hp < max_hp() * 0.5:
		c -= Data.NEED_CLEAN_LOW_HP
	return clampf(c, Data.NEED_CLEAN_MIN, Data.NEED_CLEAN_MAX)


## A body's pockets: BODY_TINS a man of the site's gang's tins.
func body_tins() -> int:
	if mission == null:
		return 0
	return maxi(1, roundi(float(mission["t"].get("cash", 1.0)) * inflation() * Data.BODY_TINS))


## The material a wreck's cut gives at site `i` (the site's own; "" for none: the Outskirts').
func wreck_mat(i: int) -> String:
	return str(Data.SITE_MATERIAL[i]) if i >= 0 and i < Data.SITE_MATERIAL.size() else ""


## The other six families' choices, in the panel's order, "Leave it" last ("Let it pass" for the weather).
func _options_more(ev: Dictionary) -> Array:
	var fam: String = str(ev["fam"])
	var out: Array = []
	match fam:
		"danger":
			var hurt: int = roundi(Data.DANGER_HURT * 100.0)
			for row in [["go", Words.EV["go_in"], Data.DANGER_S, Data.DANGER_CLEAN], ["careful", Words.EV["careful"], Data.DANGER_CAREFUL_S, Data.DANGER_CAREFUL_CLEAN]]:
				var c: int = roundi(event_clean_odds(float(row[3])) * 100.0)
				out.append({"key": row[0], "text": row[1], "ok": true, "s": float(row[2]),
					"face": [Words.EV["danger_face"][0] % [int(row[2]), c, 100 - c, hurt], Words.EV["danger_face"][1] % [int(row[2]), c, hurt]]})
		"stash":
			if bool(ev.get("tip", false)):
				out.append({"key": "take", "text": Words.EV["stash_take"], "ok": true, "s": Data.STASH_TAKE_S, "face": [Words.EV["tip_face"] % [int(Data.STASH_TAKE_S), Data.STASH_FINDS]]})
			else:
				var c: int = roundi((1.0 - Data.STASH_CATCH) * 100.0)
				out.append({"key": "take", "text": Words.EV["stash_take"], "ok": true, "s": Data.STASH_TAKE_S,
					"face": [Words.EV["take_face"] % [int(Data.STASH_TAKE_S), 100 - c]]})     # one figure (the language pass)
				out.append({"key": "check", "text": Words.EV["check"], "ok": true, "s": Data.STASH_CHECK_S, "face": [Words.EV["check_face"] % [int(Data.STASH_CHECK_S), Data.STASH_FINDS]]})
		"body":
			out.append({"key": "search", "text": Words.EV["search"], "ok": true, "s": Data.BODY_S, "face": [Words.EV["search_face"] % [int(Data.BODY_S), roundi(Data.BODY_CLUE * 100.0)]]})
			out.append({"key": "pockets", "text": Words.EV["pockets"], "ok": true, "s": Data.BODY_POCKETS_S, "face": [Words.EV["pockets_face"] % [int(Data.BODY_POCKETS_S), _cash_words(body_tins()), roundi(Data.F51_POCKETS_FIND * 100.0)]]})     # (FIX51) the find's chance
		"wreck":
			out.append({"key": "strip", "text": Words.EV["strip"], "ok": true, "s": Data.WRECK_S, "face": [Words.EV["strip_face"] % [int(Data.WRECK_S), Data.WRECK_SCRAP[0], Data.WRECK_SCRAP[1]]]})
			var can: bool = pack_scrap(mission) >= Data.WRECK_CUT_SCRAP
			var mk: String = wreck_mat(int(mission["tier"])) if mission != null else ""
			var cut_face: Array = [Words.EV["cut_no"]]
			if can:
				cut_face = [Words.EV["cut_face"][0] % [int(Data.WRECK_CUT_S), Data.WRECK_CUT_SCRAP, "%d–%d" % [int(Data.WRECK_MAT[0]), int(Data.WRECK_MAT[1])], Words.mid_base(str(Data.MATERIALS[mk]["name"]))], Words.EV["cut_face"][1] % [int(Data.WRECK_CUT_S), Data.WRECK_CUT_SCRAP]] if mk != "" else [Words.EV["cut_face"][1] % [int(Data.WRECK_CUT_S), Data.WRECK_CUT_SCRAP]]
			out.append({"key": "cut", "text": Words.EV["cut"], "ok": can, "s": Data.WRECK_CUT_S, "face": cut_face})
		"broadcast":
			out.append({"key": "listen", "text": Words.EV["listen"], "ok": true, "s": Data.RADIO_S, "face": [Words.EV["listen_face"] % int(Data.RADIO_S)]})
			out.append({"key": "short", "text": Words.EV["short"], "ok": true, "s": Data.RADIO_SHORT_S, "face": [Words.EV["short_face"] % [int(Data.RADIO_SHORT_S), roundi(Data.RADIO_SHORT_TIP * 100.0)]]})
		"weather":
			out.append({"key": "press", "text": Words.EV["press"], "ok": true, "s": 0.0, "face": [Words.EV["press_face"] % [int(ev.get("loot", 0)), int(ev.get("harder", 0))]]})
			out.append({"key": "home", "text": Words.EV["home"], "ok": can_extract(), "s": 0.0, "face": [Words.EV["home_face"]]})
	out.append({"key": "leave", "text": Words.EV["let_pass"] if fam == "weather" else Words.EV["leave_it"], "face": [Words.EV["nothing"]], "ok": true, "s": 0.0})
	return out


## A choice taken on one of the other six (event_pick's): its cost and its reward.
func _pick_more(m: Dictionary, t: Dictionary, ev: Dictionary, key: String) -> void:
	match key:
		"go", "careful":
			var c: float = event_clean_odds(Data.DANGER_CLEAN if key == "go" else Data.DANGER_CAREFUL_CLEAN)
			_event_spend(m, Data.DANGER_S if key == "go" else Data.DANGER_CAREFUL_S)
			if rng.randf() < c:
				log_event(Words.EV["danger_clean"])
			else:
				var lost: float = minf(max_hp() * Data.DANGER_HURT, maxf(0.0, hp - 1.0))     # never the last of it
				hp -= lost
				ev["hurt"] = true
				log_event(Words.EV["danger_hurt"] % roundi(lost))
			_event_cache(m, t)
		"take":
			_event_spend(m, Data.STASH_TAKE_S)
			if bool(ev.get("tip", false)):
				log_event(Words.EV["stash_tip_took"])
				for k in range(Data.STASH_FINDS):
					_event_cache(m, t)
				return
			if rng.randf() < Data.STASH_CATCH:
				ev["caught"] = true
				if str(ev.get("catch_kind", "trip")) == "trip":
					var lost: float = minf(max_hp() * Data.STASH_TRIP, maxf(0.0, hp - 1.0))
					hp -= lost
					log_event(Words.EV["stash_trip"] % roundi(lost))
				else:
					m["patrol_timer"] = maxf(float(m["patrol_timer"]), patrol_s(t, int(m["patrols"]) == 0))     # watched: the next gang now
					log_event(Words.EV["stash_watched"])
			else:
				log_event(Words.EV["stash_took"])
			for k in range(Data.STASH_FINDS):
				_find(m, t)
		"check":
			_event_spend(m, Data.STASH_CHECK_S)
			log_event(Words.EV["stash_checked"] % str(ev.get("catch", "")))
			for k in range(Data.STASH_FINDS):
				_find(m, t)
		"search":
			_event_spend(m, Data.BODY_S)
			log_event(Words.EV["body_searched"])
			_find(m, t)
			if rng.randf() < Data.BODY_CLUE:
				_clue(m, ev)
		"pockets":
			var n: int = body_tins()
			_event_spend(m, Data.BODY_POCKETS_S)
			m["cash"] = float(m["cash"]) + n
			log_event(Words.EV["pocketed"] % _cash_words(n))
			if rng.randf() < Data.F51_POCKETS_FIND:
				_find(m, t)                       # and what was on him: a find, as a search's (BUILD51-A), a chance of one (FIX51: Search not the trap)
		"strip":
			_event_spend(m, Data.WRECK_S)
			var n: int = rng.randi_range(Data.WRECK_SCRAP[0], Data.WRECK_SCRAP[1])
			_haul_find(m, "scrap", n)
			log_event(Words.EV["stripped"] % n)
		"cut":
			_event_spend(m, Data.WRECK_CUT_S)
			_take_scrap(m, Data.WRECK_CUT_SCRAP)
			var mk: String = wreck_mat(int(m["tier"]))
			if mk != "":
				_haul_find(m, mk, rng.randi_range(Data.WRECK_MAT[0], Data.WRECK_MAT[1]))
			log_event(Words.EV["cut_open"] % Data.WRECK_CUT_SCRAP)
			_event_cache(m, t)
		"listen":
			_event_spend(m, Data.RADIO_S)
			_tip_roll(m)
		"short":
			_event_spend(m, Data.RADIO_SHORT_S)
			if rng.randf() < Data.RADIO_SHORT_TIP:
				_tip_roll(m)
			else:
				log_event(Words.EV["no_tip"])
		"press":
			m["turn_home"] = m["t"]                    # the site's own back at the run's end (_event_end): the record reads it
			var nt: Dictionary = m["t"].duplicate()
			nt["rarity"] = float(nt.get("rarity", 0.0)) + float(ev.get("loot", 0)) / 100.0
			nt["dps"] = float(nt["dps"]) * (1.0 + float(ev.get("harder", 0)) / 100.0)
			m["t"] = nt
			log_event(Words.EV["pressed"])
	_dry_memo.clear()
	_stats_dirty()


## A body's clue: the site's head's weakness (a thread: BODY_HEAD_CUT off his HP the next run he's out), or - no head
## here, or the other half - whatever killed them still about: the next gang BODY_GANG tougher, BODY_GANG_NOTES notes a man.
func _clue(m: Dictionary, ev: Dictionary) -> void:
	var i: int = int(m["tier"])
	var head: Dictionary = boss_of(i)
	if not head.is_empty() and rng.randf() < 0.5:
		ev["clue"] = "head"
		_thread_add("weak", {"site": i, "run": runs_total})
		log_event(Words.EV["clue_head"] % [Words.mid(str(head["name"])), roundi(Data.BODY_HEAD_CUT * 100.0)])
		return
	ev["clue"] = "gang"
	m["clue_home"] = m["t"]
	m["clue_from"] = int(m["patrols"])
	m["clue_kills"] = int(m["kills"])
	var nt: Dictionary = m["t"].duplicate()
	nt["hp"] = float(nt["hp"]) * Data.BODY_GANG
	nt["dps"] = float(nt["dps"]) * Data.BODY_GANG
	m["t"] = nt
	log_event(Words.EV["clue_gang"])


## The clue's gang beaten: their notes, and the site's own gang again.
func _clue_done(m: Dictionary) -> void:
	m["notes"] = int(m.get("notes", 0)) + Data.BODY_GANG_NOTES * maxi(0, int(m["kills"]) - int(m.get("clue_kills", 0)))
	m["t"] = m["clue_home"]
	m.erase("clue_home")


## A tip (a broadcast heard, the Vagabond's rumour): a stash at another open site on a later run there, or word of the
## Vagabond (TIP_TRADER; or with nowhere else open) - the next run's event is him. A thread.
func _tip_roll(m: Dictionary) -> void:
	var here: int = int(m["tier"])
	var sites: Array = range(Data.TIERS.size()).filter(func(si): return si != here and tier_open(si))
	if sites.is_empty() or rng.randf() < Data.TIP_TRADER:
		_thread_add("tips", {"kind": "trader", "run": runs_total})
		log_event(Words.EV["tip_trader"])
		return
	var k: int = int(sites[rng.randi_range(0, sites.size() - 1)])
	_thread_add("tips", {"kind": "site", "site": k, "run": runs_total})
	log_event(Words.EV["tip_site"] % Words.mid(str(Data.TIERS[k]["name"])))


## A thread's list (event_threads[key]): tips, robbed crews, heads' weaknesses. Never more than THREAD_MAX.
func thread_list(key: String) -> Array:
	var l = event_threads.get(key, [])
	return l if l is Array else []


func _thread_add(key: String, entry: Dictionary) -> void:
	var l: Array = thread_list(key)
	l.append(entry)
	while l.size() > Data.THREAD_MAX:
		l.pop_front()                          # bounded: the oldest goes
	event_threads[key] = l


## A run set off (deploy): the threads that land on it. A tip's stash here is the run's event (no catch); word of the
## Vagabond makes him the run's event; a head's weakness here comes off his HP. A stale tip (TIP_RUNS) goes.
func _threads_at_deploy(m: Dictionary, i: int) -> void:
	if m.get("dry", false):
		return
	var tips: Array = thread_list("tips").filter(func(tp): return runs_total - int(tp.get("run", 0)) <= Data.TIP_RUNS)
	event_threads["tips"] = tips
	var here: Array = tips.filter(func(tp): return str(tp.get("kind", "")) == "site" and int(tp.get("site", -1)) == i)
	var vag: Array = tips.filter(func(tp): return str(tp.get("kind", "")) == "trader")
	if not here.is_empty() and str(m.get("event", "")) != "convoy":
		tips.erase(here[0])
		m["event"] = "stash"
		m["event_tip"] = true
		m["event_at"] = rng.randf_range(Data.EVENT_WINDOW[0], Data.EVENT_WINDOW[1])
	elif not vag.is_empty() and str(m.get("event", "")) != "convoy":
		tips.erase(vag[0])
		m["event"] = "trader"
		m["event_who"] = "vagabond"
		m["event_at"] = rng.randf_range(Data.EVENT_WINDOW[0], Data.EVENT_WINDOW[1])
	var weak: Array = thread_list("weak").filter(func(w): return int(w.get("site", -1)) == i)
	if not weak.is_empty() and m.has("boss"):
		event_threads["weak"].erase(weak[0])
		m["boss"]["hp"] = float(m["boss"]["hp"]) * (1.0 - Data.BODY_HEAD_CUT)
		log_event(Words.EV["weak_used"] % [roundi(Data.BODY_HEAD_CUT * 100.0), Words.mid(str(m["boss"]["name"]))])


## The standing orders for the other six (_event_by_orders'): the order's choice when it can be had, else "leave".
func _orders_more(m: Dictionary, ev: Dictionary, o: String) -> void:
	var ok := func(k: String) -> bool:
		return event_options().any(func(x): return x["key"] == k and bool(x["ok"]))
	var pick: String = "leave"
	match o:
		"careful", "go", "take", "check", "search", "pockets", "strip", "cut", "listen", "short", "press", "home":
			pick = o
		"press_80":
			pick = "press" if run_odds(m) >= f51_press_at() else "leave"     # the player's at WEATHER_PRESS_AT, the bot's its own (FIX51)
	if str(ev["fam"]) == "stash" and bool(ev.get("tip", false)) and pick != "leave":
		pick = "take"                              # a tip's stash has no catch to check
	if pick == "careful" and not ok.call("careful"):
		pick = "leave"                             # "time allowing"
	if pick == "cut" and not ok.call("cut"):
		pick = "strip"                             # "scrap allowing": strip it instead
	if not (ok.call(pick) and event_pick(pick)):
		event_pick("leave")


# ------------------------------------------------------------------ BUILD46-E: a rival crew (A threat passing, beside the dogs)

## Who's passing: the event's pinned one (a thread, the tests), else a robbed crew back for you (ROBBED_BACK while one's
## out there), else a rival crew (CREW_SHARE of the zone's, from CREW_FROM_RUN), else the dogs.
func _threat_who(m: Dictionary, z: int) -> String:
	var pin: String = str(m.get("event_who", ""))
	if pin in ["dogs", "crew"]:
		return pin
	if pin == "crew_back" or (not thread_list("robbed").is_empty() and rng.randf() < Data.ROBBED_BACK):
		m["crew_back"] = true
		return "crew"
	if runs_total >= Data.CREW_FROM_RUN and rng.randf() < float(Data.CREW_SHARE[clampi(z, 0, Data.CREW_SHARE.size() - 1)]):
		return "crew"
	return "dogs"


## A rival crew as they come: whether they're a robbed crew back (the thread spent), and what they carry - notes
## (CREW_NOTES a man's), or (CREW_FIND) a find a tier up.
func _crew_arrive(m: Dictionary, ev: Dictionary) -> void:
	if bool(m.get("crew_back", false)):
		ev["back"] = true
		var l: Array = thread_list("robbed")
		if not l.is_empty():
			l.pop_front()
		event_threads["robbed"] = l
	m.erase("crew_back")
	if rng.randf() < Data.CREW_FIND:
		ev["carry"] = "find"
	else:
		ev["carry"] = "notes"
		ev["carry_n"] = Data.CREW_NOTES * notes_a_kill(m["t"]) * int(ev["n"])


## A rival crew as a gang: the site's gang at CREW_HP and CREW_DPS a man (x1.5 its difficulty), its damage types and
## resists, a man's XP, nothing a man carries (they carry it as a crew: _crew_paid).
static func crew_t(t: Dictionary) -> Dictionary:
	var d: Dictionary = t.duplicate()
	d["hp"] = float(t["hp"]) * Data.CREW_HP
	d["dps"] = float(t["dps"]) * Data.CREW_DPS
	d["drop"] = 0.0
	d["no_kill_cash"] = true
	d["dogs"] = true                           # the kill's early return: its XP, nothing a man carries
	d["crew"] = true
	return d


## The threat's gang: the dogs' or the crew's, off the site's `t`.
static func threat_t(ev: Dictionary, t: Dictionary) -> Dictionary:
	return crew_t(t) if str(ev.get("who", "dogs")) == "crew" else dogs_t(t)


## The gang the threat's odds read (_dogs_read's `as_t`): {} for the dogs (their own), the crew's for a crew.
func threat_as(ev: Dictionary, m: Dictionary) -> Dictionary:
	return crew_t(m.get("dogs_home", m["t"])) if str(ev.get("who", "dogs")) == "crew" else {}


## A rival crew seen off: what they carried, and (CREW_ROBBED, not a crew already back) a crew that'll want it back.
func _crew_paid(m: Dictionary) -> void:
	var ev: Dictionary = m["ev"]
	if str(ev.get("carry", "")) == "find":
		_event_cache(m, m["t"])
		log_event(Words.EV["crew_off_find"])
	else:
		var n: int = int(ev.get("carry_n", 0))
		m["notes"] = int(m.get("notes", 0)) + n
		log_event(Words.EV["crew_off_notes"] % n)
	if not bool(ev.get("back", false)) and rng.randf() < Data.CREW_ROBBED:
		_thread_add("robbed", {"zone": int(ev.get("zone", 0)), "run": runs_total})


# ------------------------------------------------------------------ BUILD46-E: the Vagabond (the second trader)

const VAG_SLOTS := ["Primary", "Secondary", "Helmet", "Armour", "Gloves", "Rig", "Backpack"]


## Which trader: the event's pinned one (a tip, the tests), else the Vagabond VAG_SHARE of them from VAG_FROM_RUN.
func _trader_who(m: Dictionary) -> String:
	var pin: String = str(m.get("event_who", ""))
	if Data.TRADERS.has(pin):
		return pin
	return "vagabond" if runs_total >= Data.VAG_FROM_RUN and rng.randf() < Data.VAG_SHARE else "scrap_man"


## His stock as he comes: VAG_GEAR pieces (one more from the first step) at the site's tier, VAG_UP of them a tier up
## (all from the third step), each priced off its worth (_vag_price); a rumour VAG_RUMOUR of visits (every visit from
## the third step).
func _vag_stock(m: Dictionary, ev: Dictionary) -> void:
	var step: int = trader_step("vagabond")
	var t: Dictionary = m["t"]
	var cap: int = loot_cap(int(t.get("level", lv_at(int(t["tier"]), int(t["depth"])))))
	var stock: Array = []
	for k in range(Data.VAG_GEAR + (1 if step >= 1 else 0)):
		var tt: Dictionary = t.duplicate()
		var up: bool = (step >= 3 or rng.randf() < Data.VAG_UP) and int(t["loot_tier"]) < cap
		if up:
			tt["loot_tier"] = int(t["loot_tier"]) + 1
		var it := {}
		for tries in range(4):
			it = Dictionary(_find(m, tt, false, {"slots": VAG_SLOTS, "lean": 1.0}, true).get("it", {}))
			if not it.is_empty() and str(it.get("slot", "")) in VAG_SLOTS:
				break
			it = {}
		if not it.is_empty():
			stock.append({"it": it, "up": up, "price": _vag_price(t, it, up)})
	ev["shelf"] = stock
	ev["rumour"] = step >= 3 or rng.randf() < Data.VAG_RUMOUR


## His price off the piece's worth (fix 46, E1: off a man's tins it was a few percent of the Fence's): what the Fence would
## pay for it x VAG_SELL_X, so even his best standing's discount stays over it - never a tins pump.
func _vag_price(_t: Dictionary, it: Dictionary, _up: bool) -> int:
	return maxi(1, int(ceil(float(sell_price(it)) * Data.VAG_SELL_X)))


## The rebuild materials in the pack's stacks (not scrap).
func pack_materials(m) -> int:
	if m == null:
		return 0
	var n := 0
	for it in m["found"]:
		if Items.is_material(it) and not Items.is_scrap(it):
			n += Items.stack_size(it)
	return n


## Materials out of the pack's stacks, the biggest first; a stack gone when it's spent.
func _take_materials(m: Dictionary, n: int) -> void:
	var stacks: Array = m["found"].filter(func(it): return Items.is_material(it) and not Items.is_scrap(it))
	stacks.sort_custom(func(a, b): return Items.stack_size(a) > Items.stack_size(b))
	for it in stacks:
		var k: int = mini(n, Items.stack_size(it))
		n -= k
		if Items.stack_size(it) - k <= 0:
			m["found"].erase(it)
		else:
			Items.set_stack(it, Items.stack_size(it) - k)
		if n <= 0:
			return


## His shelf now (trader_shelf's): [{key, text, short, price, pay ("tins"/"mat"), ok, bought, why}] - the gear, then the
## rumour (materials when the pack has them, else tins); from the second step 33% off.
func _vag_shelf(ev: Dictionary) -> Array:
	var step: int = trader_step("vagabond")
	var off: float = (1.0 - Data.TRADER_STEP_OFF) if step >= 2 else 1.0
	var tins: int = int(floor(cash))         # the camp's tins, the home purse as the Fence's (BUILD48 A, parked item 16, Matt's pick): a run's take couldn't pay his shelf
	var mats: int = pack_materials(mission)
	var bought: Array = ev.get("bought", [])
	var out: Array = []
	var stock: Array = ev.get("shelf", [])
	for k in range(stock.size()):
		var row: Dictionary = stock[k]
		var key: String = "gear%d" % k
		var it: Dictionary = row["it"]
		var cost_v: int = maxi(1, int(ceil(float(row["price"]) * off)))
		var text: String = Words.EV["shelf_gear_up" if bool(row.get("up", false)) else "shelf_gear"] % [Items.full_name(it), Items.rarity_name(it)]
		# a full pack (fix 46, E2): greyed and said - never his tins for nothing; loot by hand, it waits on the floor
		var room: bool = by_hand(mission) or not pack_spot(mission, it).is_empty()
		out.append({"key": key, "text": text, "short": Items.full_name(it), "price": cost_v, "pay": "tins", "bought": key in bought,
			"why": "" if room or key in bought else Words.EV["vag_no_room"],
			"ok": not (key in bought) and tins >= cost_v and room and event_asking()})
	if bool(ev.get("rumour", false)):
		var mat_price: int = maxi(1, int(ceil(Data.VAG_RUMOUR_MAT * off)))
		var by_mat: bool = mats >= mat_price
		var cost_r: int = mat_price if by_mat else maxi(1, int(ceil(float(mission["t"].get("cash", 1.0)) * inflation() * Data.VAG_RUMOUR_TINS * off)))
		out.append({"key": "rumour", "text": Words.EV["shelf_rumour"], "short": Words.EV["shelf_rumour"], "price": cost_r, "pay": "mat" if by_mat else "tins",
			"bought": "rumour" in bought, "why": "", "ok": not ("rumour" in bought) and (mats if by_mat else tins) >= cost_r and event_asking()})
	return out


## Buy off his shelf: tins off the camp's at home (BUILD48 A, item 16), or materials off the pack's stacks; gear into the
## pack (it comes home), a rumour a tip. A trade on his standing as the visit ends.
func _vag_buy(row: Dictionary) -> bool:
	var m: Dictionary = mission
	var ev: Dictionary = m["ev"]
	var cost_v: int = int(row["price"])
	var paid: String = ""
	if str(row["pay"]) == "mat":
		_take_materials(m, cost_v)
		paid = Words.EV["vag_mat"] % cost_v
	else:
		cash -= cost_v                        # the camp's tins (BUILD48 A, item 16), not the run's take
		paid = _cash_words(cost_v)
	ev["bought"].append(row["key"])
	ev["trades"] = int(ev.get("trades", 0)) + 1
	if str(row["key"]) == "rumour":
		log_event(Words.EV["vag_traded"] % [Words.EV["vag_rumour"], paid])
		_tip_roll(m)
	else:
		var k: int = int(str(row["key"]).trim_prefix("gear"))
		var it: Dictionary = Dictionary(ev["shelf"][k]["it"]).duplicate(true)
		_place_find(m, it)
		log_event(Words.EV["vag_traded"] % [Items.full_name(it), paid])
	_dry_memo.clear()
	_stats_dirty()
	_memo_age = 0.0
	return true


## The run's event, once: a signal's convoy (17 Oct; the run's own came in with the families, 1 Nov).
func _event(m: Dictionary, t: Dictionary) -> void:
	var what: String = str(m.get("event", ""))
	m["event_at"] = -1.0
	m["event_done"] = what
	if what != "convoy":
		return
	var size: int = PATROL_BASE + 2
	var mid_fight: bool = int(m["remaining"]) > 0
	m["remaining"] += size
	_gang_arrives(m, not mid_fight)       # a convoy into a fight in progress joins it: no fresh energy (the review)
	m["clock"] = float(m.get("clock", 0.0)) + Data.CLOCK_PER_HEAD * size      # a convoy's crew brings its own time
	m["clock_max"] = float(m.get("clock_max", 0.0)) + Data.CLOCK_PER_HEAD * size
	if m["target_hp"] <= 0.0:
		m["target_hp"] = float(t["hp"])
		m.erase("opened")             # the Starting Pistol: a new one, its own first shot; one already up has had it
	m["fresh"] = true
	m["sustain_t"] = 0.0
	m["notes"] = int(m.get("notes", 0)) + notes_a_kill(t) * size
	log_event(Words.LOG["convoy_event"] % [Words.EVENTS["convoy"], Words.EVENTS["convoy_notes"]])


## The first of each gang's extra, in percent: the parts fitted, the class, the rounds' grade, the trees, and the
## affixes and set lines (21 Oct, Matt: "fix both" - the affixes' and the sets' were read nowhere in the fight).
func first_pct_total() -> float:
	return _fitted_sum("first_pct") + float(class_data().get("first_pct", 0)) + grade_stat(equipped["Primary"], "first_pct") + tree_sum("first_pct") + _affix_sum("first_pct")


func _fight(m: Dictionary, t: Dictionary, dt: float) -> void:
	m["fight_s"] = float(m.get("fight_s", 0.0)) + dt     # the breakdown's seconds of fighting (24 Oct)
	var mech: String = _order_mech(m)                      # a true pinnacle's own fight (24 Oct, the endgame chase)
	if mech != "":
		_order_tick(m, t, dt, mech)
	var hp_before: float = float(m["target_hp"])
	# the swing held a second of fight, not a tick (25 Oct, the review): the bot's one-second ticks, the odds' two-second
	# steps and a player's frames then see the same spread of hits
	m["swing_t"] = float(m.get("swing_t", 1.0)) + dt
	if m["swing_t"] >= 1.0 or not m.has("swing"):
		m["swing"] = rng.randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
		m["swing_t"] = fmod(float(m["swing_t"]), 1.0)
	var swing: float = float(m["swing"])
	var headshot := 1.0
	if m["fresh"]:
		headshot += first_pct_total() / 100.0
	if m["fresh"] and yard_has("range_cards"):
		headshot += Data.FX["yard/range_cards"]                       # the Lookout's Range cards: the first shot on every gang half again
	if m["fresh"] and atlas_rank("marked_men") > 0:
		headshot += 0.25
	if m["fresh"] and has_rule("grandads"):
		headshot += Data.FX["rule/grandads"]
	if m["fresh"]:
		m["first_bonus"] = headshot - 1.0
	if m["fresh"] and has_node("snare_and_wait"):
		headshot *= 0.5                       # Snare and wait: the first of each gang takes half (after the bonus is kept: Clean kills reads it, the review)
	if m["fresh"] and has_node("capacitor"):
		m["shock_t"] = maxf(float(m.get("shock_t", 0.0)), status_s(1.0) + dt)     # Capacitor: your first hit on each gang shocks
	if combo_on("clean_kills") and combo_stacks(m) > 0.0:
		headshot += (0.0 if m["fresh"] else float(m.get("first_bonus", 0.0))) + combo_step("clean_kills") * combo_stacks(m)     # Clean kills: the first shot never ends (its own if: Capacitor's elif skipped it; the first shot's bonus once, 25 Oct)
	if m["fresh"] and (has_node("one_shot") or has_rule("lollipop")):
		m["target_hp"] = 0.0              # the first of the lot drops where it stands
	if has_rule("starting_pistol") and not m.get("opened", false) and m["remaining"] > 0 and float(m["target_hp"]) > 0.0:
		_starting_shot(m, t)
	# in among them: their first shot lands before your first swing, each gang
	if melee() and m["fresh"]:
		m["melee_wait"] = float(m.get("melee_wait", 0.0)) + dt
		if m["melee_wait"] <= Data.MELEE_WAIT:
			headshot = 0.0
	elif not m["fresh"]:
		m["melee_wait"] = 0.0
	# a chill or a shock from the last tick wears off first, so one landed this
	# tick holds through their fire below and into the next, whatever the tick's length
	m["chill_t"] = maxf(0.0, float(m.get("chill_t", 0.0)) - dt)
	m["shock_t"] = maxf(0.0, float(m.get("shock_t", 0.0)) - dt)
	# the hit, by type: each share cut by their resist to it; shocked, more of everything
	var shocked: bool = float(m.get("shock_t", 0.0)) > 0.0
	# walking fire (the SMG line, 7 Oct): the stream grows the longer the gun fires on one gang
	m["sustain_t"] = float(m.get("sustain_t", 0.0)) + dt
	var mult: float = pace() * t["pace"] * swing * headshot * sustain_mult(m) * dt * my_chill_x(m)
	if m.get("clocked", false):
		mult *= 1.1                           # Clocked: the first of the gang down, +10% for the rest of it
	if float(m.get("taped_t", 0.0)) > 0.0:
		mult *= 1.0 - Data.ORDER_TAPE_CUT     # the Registrar's red tape with nothing to seal: your fire cut
	if mech == "bailiff":
		mult *= 1.0 - float(Data.BAILIFF_CUT.get(str(m.get("seized", "")), 0.0)) * (1.0 if bool(m.get("seize_on", false)) else 0.0)     # the Bailiff holds your gun
	if has_node("last_orders") and m["remaining"] == 1 and not (m.has("boss") and m["boss"]["started"] and m["boss"]["alive"]):
		mult *= 1.4                           # Last orders: +40% to the last of each gang
	if has_node("bin_lid") and float(m.get("guard", 0.0)) > 0.0:
		mult *= 0.8                           # Bin lid: −20% damage while Guard holds
	var jab: float = 1.0
	if float(m.get("jab_t", 0.0)) > 0.0:
		m["jab_t"] = maxf(0.0, float(m["jab_t"]) - dt)
		jab = 1.2                             # Jab: +20% pace for 8 seconds after a med (the rounds go with it, below)
		mult *= 1.2 * jab                     # and +20% damage
	_mags_tick(m, dt)                         # the reloads before the hit (28 Oct, magazines): a gun reloading fires for what's left of the tick
	var res: Dictionary = t.get("res", {})
	var per_type := type_dps()
	var landed_total := 0.0
	var single_total := 0.0                   # what the one in front took this tick, every type: the Revolver's killing shot is cut from it
	var single_top := ["physical", 0.0]
	var crowd_on_you: int = mini(m["remaining"], contact(t))
	if mech_prints(mech):
		crowd_on_you = mini(1 + int(m.get("printed", 0)), contact(t) + 1)     # the Issuer's printed men stand with him: spread reaches them
	_skills_tick(m, t, dt, (1 + int(m.get("printed", 0)) if mech_prints(mech) else 1) if (m.has("boss") and m["boss"]["started"] and m["boss"]["alive"]) else int(m["remaining"]))     # the skills before the hit (milestone 8); "3+ on you" counts everyone in the fight, not just those firing (Matt's call 3, skills.md §11)
	mult *= _skill_hit_mult(m)
	var held := gun_type()
	mult *= _joint_hit_mult(m, held)
	# the gun type's edge (29 Oct, docs/design/itemisation.md §3), on the primary's share of the hit: a rifle's pierce (and
	# its opener, below), a shotgun's spread into the next in line, a melee weapon's crowd; the read is edge_read's
	var edge: String = edge_type()
	var e_share: float = edge_share() if edge != "" else 0.0
	var e_pierce: float = float(Data.EDGE["rifle"]["pierce"]) * e_share if edge == "rifle" else 0.0
	var e_hit: float = (1.0 + float(Data.EDGE["melee"]["x"]) * e_share) if (edge == "melee" and crowd_on_you >= int(Data.EDGE["melee"]["on_you"])) else 1.0
	var e_spread: float = float(Data.EDGE["shotgun"]["x"]) * e_share if (edge == "shotgun" and int(m["remaining"]) >= 2) else 0.0
	for ty in Data.TYPES:
		var r_ty: float = float(res.get(ty, 0.0))
		if ty == "physical":
			r_ty = phys_resist(r_ty)                  # Knuckles: the Doorman's knuckles and Bust them up get through their jackets
			r_ty *= 1.0 - e_pierce                    # a rifle's pierce: so much of their armour ignored
		r_ty *= 1.0 - _skill_pat(m)                   # Pat down: their armour and resists off (milestone 8)
		var landed: float = float(per_type[ty]) * (1.0 - r_ty) * mult * e_hit * _skill_type_mult(m, ty) * ((1.0 + shock_amount() + (combo_step("live_load") * combo_stacks(m) if combo_on("live_load") else 0.0) + (combo_step("flatline") * combo_stacks(m) if combo_on("flatline") else 0.0)) if shocked else 1.0)
		landed *= exploit_x(m)
		if ty == "fire" and combo_on("embers"):
			landed *= 1.0 + combo_step("embers") * combo_stacks(m)          # Embers
		if ty == "physical" and combo_on("drilled"):
			landed *= 1.0 + combo_step("drilled") * combo_stacks(m)         # Drilled (the Recruit's)
		if ty == "physical" and has_node("cap_shatter") and float(m.get("chill_t", 0.0)) > 0.0:
			landed *= Data.FX["node/cap_shatter"]                             # Shatter: a chilled target takes double from the physical
		if ty == "physical" and has_node("brittle") and float(m.get("chill_t", 0.0)) > 0.0:
			landed *= 1.3                                                     # Brittle: +30% physical to a frozen one
		if ty == "frost" and has_rule("gritters_keys") and float(m.get("chill_t", 0.0)) > 0.0:
			landed *= Data.FX["rule/gritters_keys"]                             # the Gritter's Keys: chilled, they take double frost
		if ty == "bleed" and has_node("cap_bleed_out"):
			landed *= Data.FX["node/cap_bleed_out"]                             # Bleed out: bleeds half again as hard
		var single := landed                      # what one of them takes, before a spread
		single_total += single
		if single > float(single_top[1]):
			single_top = [ty, single]
		if has_node("melee_sweep"):
			landed *= crowd_on_you                # Through the lot: a swing hits everyone on you
		elif ty == "fire" and (has_node("fire_spread") or has_rule("weed_burner")):
			landed *= crowd_on_you                # Spreads: fire hits everyone on you
		if ty == "shock" and (has_node("shock_chain") or has_rule("jump_leads") or has_rule("substation_key")) and (m["fresh"] or shocked):
			landed *= crowd_on_you                # Live wire: shock on one of them is shock on all of them, while it holds
		elif ty == "shock" and has_rule("linemans_bag") and shocked and crowd_on_you > 1:
			landed *= 1.0 + Data.FX["rule/linemans_bag.arc"] * (crowd_on_you - 1)     # the Lineman's Tool Bag: the shock arcs to the rest at half
		if e_spread > 0.0:
			landed += single * e_spread           # a shotgun's spread: each round hits the next in line too
		if ty == "fire" and has_node("fire_more"):
			hp -= minf(single * 0.02, max_hp() * 0.01 * dt)   # petrol on your hands: 2% of a hit, never past 1% of you a second
		landed_total += landed
		if landed > 0.0:
			if not m.has("dealt_by"):
				m["dealt_by"] = {}
			m["dealt_by"][ty] = float(m["dealt_by"].get(ty, 0.0)) + landed
			if not m.has("dots"):
				m["dots"] = {}
			_dot_add(m["dots"], ty, landed, float(per_type[ty]) * (1.0 - r_ty) * pace() * t["pace"] * (1.5 if (ty == "bleed" and has_node("cap_bleed_out")) else 1.0))
			if ty == "frost":
				m["chill_t"] = 999.0 if has_rule("gritters_keys") else status_s(1.0) * (1.0 + tree_sum("frost_last_pct") / 100.0)    # the Gritter's Keys: a chill holds as long as you fire; Deep freeze: longer
			if ty == "shock":
				m["shock_t"] = 999.0 if (has_rule("tester") or has_node("cap_arc")) else status_s(1.0)     # Arc: the shock holds as long as you fire
	if has_rule("gritters_hopper"):
		m["chill_t"] = 1.0                        # everyone on you is chilled, always
	if edge == "rifle" and single_total > 0.0:
		# a rifle's opener: one round's worth more into each new man, once (a round, not a tick: the bot's second, the odds'
		# two and a player's frames pay it the same); due until the primary fires, so a reload holds it
		var e_boss: bool = m.has("boss") and m["boss"]["started"] and m["boss"]["alive"]
		var man_id: String = "%d/%d/%s/%d" % [int(m.get("kills", 0)), int(m["remaining"]), str(e_boss), int(m.get("patrols", 0))]
		var e_shots: float = float(Items.base_of(equipped["Primary"])["rof"]) * pace() * jab * float(t["pace"]) * dt * float(m.get("fire_x", {}).get("Primary", 1.0)) * my_chill_x(m) * rate_x()
		if str(m.get("edge_opened", "")) != man_id and e_shots > 0.000001:
			m["edge_opened"] = man_id
			var ob: float = float(Data.EDGE["rifle"]["opener"]) * single_total * e_share / e_shots
			landed_total += ob
			if not m.has("dealt_by"):
				m["dealt_by"] = {}
			m["dealt_by"][str(single_top[0])] = float(m["dealt_by"].get(str(single_top[0]), 0.0)) + ob
	_joints_on_hit(m, t, landed_total, held, dt)
	_count_src(m, _gun_src(), landed_total)
	m["target_hp"] -= landed_total
	var ticked_on_them := 0.0
	if m.has("dots"):
		if not m.has("dealt_by"):
			m["dealt_by"] = {}
		var tb := {}
		ticked_on_them = _dot_tick(m["dots"], dt, tb)
		if has_node("arterial") and float(tb.get("bleed", 0.0)) > 0.0 and float(m.get("target_t", 0.0)) < 1.0:
			ticked_on_them += float(tb["bleed"])      # Arterial: the bleed does double in a target's first second
			tb["bleed"] = float(tb["bleed"]) * 2.0
		if not m.has("ticked_by"):
			m["ticked_by"] = {}
		for ty in tb:
			m["dealt_by"][ty] = float(m["dealt_by"].get(ty, 0.0)) + tb[ty]
			m["ticked_by"][ty] = float(m["ticked_by"].get(ty, 0.0)) + tb[ty]     # the ticks apart from the hits, for the numbers (13 Oct)
			_count_src(m, "dot:" + str(ty), float(tb[ty]))
		m["target_hp"] -= ticked_on_them
	m["dealt"] = float(m.get("dealt", 0.0)) + landed_total + ticked_on_them    # for the numbers on the run screen
	m["landed_rate"] = landed_total / maxf(dt, 0.001)                            # what landed this tick, a second: the top bar's damage line moves on it (8 Oct)
	# the rounds behind that: the primary's rate while it's live, the secondary's when it fires
	var primary_live := equipped["Primary"] != null and has_rounds(equipped["Primary"])
	var chill_x: float = my_chill_x(m)
	var px_t: float = float(m["fire_x"].get("Primary", 1.0))
	if primary_live and not has_rule("qm_rifle"):
		var p_shots: float = Items.base_of(equipped["Primary"])["rof"] * pace() * jab * t["pace"] * dt * px_t * chill_x * rate_x()
		_fire_rounds(m, "Primary", p_shots)
	# the secondary spends what it fires: its full rate when it's the gun in hand (the primary dry, gone or refilling a
	# magazine, or Double tap), a third while it backs the primary, the sling's share while the primary reloads (30 Oct)
	if equipped["Secondary"] != null and has_rounds(equipped["Secondary"]):
		var share: float = (secondary_share(true) * px_t + (1.0 - px_t) * reload_share()) if primary_live else 1.0
		var s_shots: float = Items.base_of(equipped["Secondary"])["rof"] * pace() * jab * t["pace"] * dt * share * float(m["fire_x"].get("Secondary", 1.0)) * chill_x * rate_x()
		_fire_rounds(m, "Secondary", s_shots)
	if mech != "":
		_order_absorb(m, t, hp_before, mech)  # the Lineman's shield, the Issuer's printed men: they take the hits first
	var boss_on: bool = m.has("boss") and m["boss"]["started"] and m["boss"]["alive"]
	m["target_t"] = float(m.get("target_t", 0.0)) + dt
	# the Issuer's Revolver: the killing shot - one shot of what the one in front took this tick, not the tick's whole
	# (25 Oct, the review: the whole tick, spread and dots, wiped the gang off one kill)
	var in_hand = equipped["Primary"] if equipped["Primary"] != null and has_rounds(equipped["Primary"]) else equipped["Secondary"]     # the gun firing: the Revolver's own when the primary's dry (the review)
	var shots: float = maxf(1.0, (float(Items.base_of(in_hand).get("rof", 1.0)) if in_hand != null else 1.0) * pace() * float(t["pace"]) * dt)
	var last_hit: float = single_total / shots
	if has_node("overload") and not boss_on and shocked and m["remaining"] > 0 and m["target_hp"] > 0.0 and m["target_hp"] <= 0.2 * float(t["hp"]):
		m["target_hp"] = 0.0                  # Overload: a shocked one dies under 20% HP
	while m["target_hp"] <= 0.0 and m["remaining"] > 0:
		m["remaining"] -= 1
		m["target_t"] = 0.0
		if m["fresh"] and has_node("in_the_hide"):
			_guard_add(m, max_hp() * 0.15)       # In the hide: the first of a gang down
		if m["fresh"] and has_node("clocked"):
			m["clocked"] = true                  # Clocked: the first of the gang down
		if has_node("floored") and float(type_dps().get("physical", 0.0)) > 0.0:
			m["floor_t"] = 1.0                   # Floored: the next of them, staggered, loses a second of fire
		m["fresh"] = false
		if boss_on:
			_skills_on_kill(m)                        # a head's a kill too: Kickback, Jackpot, Breakdown
			m["target_hp"] = 0.0
			_boss_down(m, t)
			boss_on = false
			if not m.get("boss_queue", []).is_empty():
				m["boss"] = m["boss_queue"].pop_front()     # the next of the convoy
				m["remaining"] = 0                           # comes out below
			break
		m["target_hp"] += t["hp"]
		if m.has("sk"):
			m["sk"]["seq"] = int(m["sk"]["seq"]) + 1     # a man joins the fight: Gin trap's next one
		_skills_on_kill(m)                            # Kickback, Jackpot, Breakdown (milestone 8)
		m.erase("opened")                    # the Starting Pistol: the next of them has its own first shot
		m["kill_shocked"] = float(m.get("shock_t", 0.0)) > 0.0
		m["kill_burning"] = float(m.get("dots", {}).get("fire", 0.0)) > 0.0
		m["kill_bleeding"] = float(m.get("dots", {}).get("bleed", 0.0)) > 0.0
		if (combo_on("embers") and m["kill_burning"]) or (combo_on("live_load") and m["kill_shocked"]) or (combo_on("clean_kills") and float(m.get("chill_t", 0.0)) > 0.0):
			_combo_stack(m, "embers" if combo_on("embers") else ("live_load" if combo_on("live_load") else "clean_kills"))
		if combo_on("flatline") and m["kill_shocked"]:
			_combo_stack(m, "flatline")               # Flatline (the Paramedic's, joints B): a shocked kill charges him
			hp = minf(max_hp(), hp + max_hp() * Data.FLATLINE_HEAL)
		if combo_on("opened_for_good") and m.get("dots", {}).has("bleed"):
			_combo_stack(m, "opened_for_good")
			m["dots"]["bleed"] = minf(Data.COMBO_CEILING, float(m["dots"]["bleed"]) * (1.0 + combo_step("opened_for_good")))     # Opened for good: the bleed carries, more of it
		if combo_on("drilled") and m.has("sk") and _sk_running(m["sk"]):
			_combo_stack(m, "drilled")                # a kill while a skill of his runs
		if has_node("cap_flattened") and float(type_dps().get("physical", 0.0)) > 0.0:
			m["flat_t"] = Data.FX["node/cap_flattened"]                        # Flattened: the plain put them down; the next of them fire at half for two seconds
		m.erase("full_dose")
		var carried := a51_carried(m.get("dots", {}), m)     # (FIX51: m, for the carry's top) the carries (BUILD51-A): a notable half the dose, a capstone or a unique the whole and +25% a carry
		if carried.has("bleed") and exploit_on("bad_blood") and hp < max_hp() * 0.5:
			carried["bleed"] = minf(Data.COMBO_CEILING, float(carried["bleed"]) * float(Data.EXPLOITS["bad_blood"]["grow"]))     # the tick's own under-half-HP share taken again
		m["dots"] = carried                  # the next of them is a new target
		m["chill_t"] = 0.0
		m["shock_t"] = 0.0
		_kill(m, t)
		if exploit_on("first_of_many"):
			_exploit_grow(m, "first_of_many")     # the Pistol's shot opens every man: each one the first, and Clocked never let go
		if exploit_on("last_orders_again"):
			_exploit_grow(m, "last_orders_again")     # the Revolver's hit carries its Last orders on into the next
		if has_rule("issuers_revolver") and last_hit > 0.0 and m["remaining"] > 0:
			var printed_hit: float = minf(last_hit, float(t["hp"]))
			m["target_hp"] -= printed_hit          # the Issuer's Revolver: the killing shot again on the next; a kill from it does the same
			_count_src(m, "rule:issuers_revolver", printed_hit)
			m["dealt"] = float(m.get("dealt", 0.0)) + printed_hit
			if not m.has("dealt_by"):
				m["dealt_by"] = {}
			m["dealt_by"][str(single_top[0])] = float(m["dealt_by"].get(str(single_top[0]), 0.0)) + printed_hit     # booked to the shot's own type
	if m["remaining"] <= 0:
		if m.get("way_out", false):
			_seen_off(m)
			return
		if m.has("boss") and m["boss"]["alive"] and not m["boss"]["started"]:
			# the pool is down; the crew's head comes out
			m["boss"]["started"] = true
			m["remaining"] = 1
			m["target_hp"] = float(m["boss"]["hp"])
			var head_s: float = clock_for_head(t, float(m["boss"]["hp"]))
			m["clock"] = float(m.get("clock", 0.0)) + head_s     # the head brings his own time
			m["clock_max"] = float(m.get("clock_max", 0.0)) + head_s
			m["fresh"] = true
			m.erase("opened")
			m["sustain_t"] = 0.0
			_gang_arrives(m)                     # the head is a gang of his own: Squared up and the guard lines (the review)
			log_event(Words.LOG["head_out"] % [m["boss"]["name"], ", at full strength" if m["boss"].get("pinnacle", false) else "", Words.BOSSES.get(m["boss"]["name"], {}).get("out", "")])
			return
		m["target_hp"] = 0.0
		m["last_incoming"] = 0.0
		if m.has("t_home"):
			m["t"] = m["t_home"]               # the harder gang down (B9): the site's own again
			m.erase("t_home")
		_clear_on_you(m)                    # the picking over: nothing ticks on you
		if not m["cleared"] or m.get("ghost_pending", false):
			m["ghost_pending"] = false
			_clear(m, t)                     # a Ghost's clear is the first gang beaten
		return
	var on_you := mini(m["remaining"], contact(t))
	var chilled: bool = float(m.get("chill_t", 0.0)) > 0.0
	m["their_swing_t"] = float(m.get("their_swing_t", 1.0)) + dt
	if m["their_swing_t"] >= 1.0 or not m.has("their_swing"):
		m["their_swing"] = rng.randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)     # held a second, as yours (25 Oct)
		m["their_swing_t"] = fmod(float(m["their_swing_t"]), 1.0)
	var their_swing: float = float(m["their_swing"])
	var incoming: float = incoming_rate(t, on_you, chilled) * their_swing
	if boss_on:
		on_you = 1
		incoming = incoming_rate({"dps": m["boss"]["dps"], "types": t.get("types", {})}, 1, chilled) * their_swing
		if float(m.get("stunned_t", 0.0)) > 0.0:
			incoming = 0.0                     # the Lineman, his shield broken: stunned
		if mech_prints(mech) and int(m.get("printed", 0)) > 0:
			var pn: int = mini(int(m["printed"]), contact(t))     # no more fire on you than can reach you (the review)
			on_you = 1 + pn
			incoming += incoming_rate(t, pn, chilled) * their_swing     # the Issuer's printed men fire too
	if m["fresh"] and has_rule("underlay"):
		m["grace"] = float(m.get("grace", 0.0)) + dt
		if m["grace"] <= 2.0:
			incoming = 0.0                     # the first two seconds of a gang land on the underlay
	elif not m["fresh"]:
		m["grace"] = 0.0
	incoming *= crowd_mult(on_you)
	incoming *= low_hp_mult()
	incoming *= _skill_in_mult(m, on_you)        # the skills: out of sight, stunned, the decoy (milestone 8)
	incoming *= combo_guard(m)
	if exploit_on("never_trips") and float(m.get("shock_t", 0.0)) > 0.0:
		_exploit_grow(m, "never_trips", dt)     # the Ring main's jump lands on a man the Tester keeps shocked, and goes again
	incoming *= _joints_on_incoming(m, chilled, dt)
	if float(m.get("immune_t", 0.0)) > 0.0:
		incoming = 0.0                                  # Clean hands: nothing lands for a while after a med
	# what their fire leaves on you: a share of the elemental part burns, poisons, bleeds, and ticks while the fight's on
	if not m.has("my_dots"):
		m["my_dots"] = {}
	var their_types: Dictionary = t.get("types", {})
	for ty in ["fire", "poison", "bleed"]:
		var share := float(their_types.get(ty, 0.0))
		if share > 0.0 and incoming > 0.0 and not cure_wards(m, ty) and _skill_dot_lands(m, ty):     # a cure's grace (28 Oct), a ward, or Close shave's one miss (milestone 8)
			_dot_add(m["my_dots"], ty, incoming * share * dt, incoming * share)
			if ty == "poison" and has_rule("gamekeepers_flask"):
				if not m.has("dots"):
					m["dots"] = {}
				_dot_add(m["dots"], "poison", incoming * share * dt, incoming * share)   # poisons them back
	# frost and shock on you (28 Oct, the cures): a pool of what their fire's frost and shock left, filling and draining
	# as a burn's does; chilled, your fire's slower (the hit's mult), shocked, more of theirs lands (here)
	if not m.has("my_ails"):
		m["my_ails"] = {}
	for ty in Data.MY_AILS:
		var a: Dictionary = Data.MY_AILS[ty]
		var pool: float = float(m["my_ails"].get(ty, 0.0))
		pool -= minf(pool, pool / float(a["s"]) * dt)
		var share_a := float(their_types.get(ty, 0.0))
		if share_a > 0.0 and incoming > 0.0 and not cure_wards(m, ty) and not _skill_wards(m, ty):
			pool = minf(max_hp() * float(a["full"]), pool + incoming * share_a * dt * float(a["ratio"]))
		if pool > 0.001:
			m["my_ails"][ty] = pool
		else:
			m["my_ails"].erase(ty)
	incoming *= 1.0 + my_ail(m, "shock") * float(Data.MY_AILS["shock"]["most"])
	if not m.has("taken_by"):
		m["taken_by"] = {}
	var shares := incoming_shares({"types": their_types} if not their_types.is_empty() else {})
	var tick_by := {}                          # this tick's by type, added below at the share that reached HP (Guard's apart)
	for ty in shares:
		tick_by[ty] = incoming * dt * float(shares[ty])
	var fire_pool: float = float(m["my_dots"].get("fire", 0.0))
	var ticked_by := {}
	var ticked: float = _dot_tick(m["my_dots"], dt, ticked_by)
	if has_rule("keepers_wax"):
		for ty in ["poison", "bleed"]:
			if ticked_by.has(ty):
				var cut: float = float(ticked_by[ty]) * (1.0 - Data.FX["rule/keepers_wax"])     # the Keeper's Wax Jacket
				ticked_by[ty] = float(ticked_by[ty]) - cut
				ticked -= cut
	if has_rule("vicars_thermos") and fire_pool > 0.0:
		var fire_tick: float = fire_pool - float(m["my_dots"].get("fire", 0.0))
		ticked -= fire_tick
		ticked_by.erase("fire")
		_heal(m, fire_tick)                        # a burn on you heals you instead
	for ty in ticked_by:
		tick_by[ty] = float(tick_by.get(ty, 0.0)) + float(ticked_by[ty])
	incoming += ticked / maxf(dt, 0.001)
	if has_node("cap_held"):
		incoming = minf(incoming, max_hp() * Data.FX["node/cap_held"])       # Held: no second of their fire, their shots and what they left on you, takes more than a tenth
	m["last_incoming"] = incoming
	var above: bool = hp >= max_hp() * Data.WOUND_AT
	var on_hp: float = _take(m, incoming * dt)
	m["taken"] = float(m.get("taken", 0.0)) + on_hp     # for the run screen's red numbers: what reached HP, Guard's share apart
	if on_hp > 0.0:
		m["roll"] = 0                         # On a roll: a hit taken ends the streak
	if has_node("off_the_canvas") and not m.get("canvas_done", false) and hp > 0.0 and hp <= max_hp() / 3.0:
		m["canvas_done"] = true
		_guard_add(m, max_hp() * 0.2)         # Off the canvas: Guard of 20% at a third HP, once a run
	var tick_total := 0.0
	for ty in tick_by:
		tick_total += float(tick_by[ty])
	var reached: float = on_hp / maxf(tick_total, 0.000001)     # over what the types made, so Held's cut is out of them too (the review)
	for ty in tick_by:
		m["taken_by"][ty] = float(m["taken_by"].get(ty, 0.0)) + float(tick_by[ty]) * reached
	if above and hp > 0.0 and hp < max_hp() * Data.WOUND_AT and not m.get("dry", false) and not _skill_wound_kept(m):
		_wound(m)                            # the hit that took them under a quarter leaves a wound (30); never a dry run's, which restores hp but not the wound
	if hp <= 0.0:
		if _skill_last_stand(m):
			log_event(Words.LOG["code_blue"] % int(round(hp)))
			return
		_kia()


## Their physical resist after Knuckles: the Doorman's knuckles' share ignored, all of it with Bust them up.
func phys_resist(r: float) -> float:
	if has_node("bust_them_up"):
		return 0.0
	return r * maxf(0.0, 1.0 - tree_sum("phys_pen") / 100.0)


## The joints' payoffs on your hit (9 Oct, docs/design/trees.md §3): what a closed joint adds to a tick of
## your fire, after the hit's types have landed.
func _joints_on_hit(m: Dictionary, _t: Dictionary, landed_total: float, held: String, dt: float) -> void:
	if landed_total <= 0.0:
		return
	if not m.has("dots"):
		m["dots"] = {}
	var rate: float = landed_total / maxf(dt, 0.001)
	if has_joint("drifter_fire") and held == "smg":
		_dot_top_up(m["dots"], "fire", landed_total * 0.1, rate * 0.1)       # the bursts ignite
	if has_joint("doorman_bleed") and (held == "shotgun" or held == "melee"):
		_dot_top_up(m["dots"], "bleed", landed_total * 0.1, rate * 0.1)      # every shell and swing opens a bleed
	if has_joint("scrapper_shock") and held == "improvised":
		m["shock_t"] = maxf(float(m.get("shock_t", 0.0)), 1.0)               # every hit from an improvised gun shocks
	if has_joint("poacher_poison") and m["fresh"] and not m.has("full_dose") and float(m["dots"].get("poison", 0.0)) > 0.0:
		m["full_dose"] = true
		_dot_fill(m, "poison")                                                 # the first shot on a gang: its poison at full stacks


## A joint's dot on top of what the gun's conversion built: never less than was there (the reviewer's catch: a
## small cap of its own would have clamped a big burn down).
func _dot_top_up(dots: Dictionary, ty: String, add: float, rate_cap: float) -> void:
	var was := float(dots.get(ty, 0.0))
	_dot_add(dots, ty, add, rate_cap)
	dots[ty] = maxf(float(dots.get(ty, 0.0)), was)


## The joints' share on your hit this tick: the Drifter's petrol, joined - a burning gang takes a quarter
## more from the SMG.
func _joint_hit_mult(m: Dictionary, held: String) -> float:
	if has_joint("drifter_fire") and held == "smg" and float(m.get("dots", {}).get("fire", 0.0)) > 0.0:
		return Data.FX["joint/drifter_fire"]
	return 1.0


## Their fire on you after the joints and Knuckles: a share, 1.0 with none. Runs Flattened's clock down.
func _joints_on_incoming(m: Dictionary, chilled: bool, dt: float) -> float:
	var f := issued_plate_cut(m) * county_taken(m)     # the issued plate (25 Oct); the County's heads
	var held := gun_type()
	if has_joint("paramedic_frost") and chilled:
		f *= Data.FX["joint/paramedic_frost.taken"]                                  # chilled gangs do 30% less to you
	if has_joint("doorman_bleed") and float(m.get("dots", {}).get("bleed", 0.0)) > 0.0:
		f *= Data.FX["joint/doorman_bleed"]                                  # bleeding gangs do 20% less
	if has_joint("doorman_physical") and (held == "shotgun" or held == "melee"):
		f *= Data.FX["joint/doorman_physical"]                                 # every shell and swing staggers: they fire 25% slower
	var stagger := tree_sum("stagger")
	if stagger > 0.0 and float(type_dps().get("physical", 0.0)) > 0.0:
		f *= maxf(0.0, 1.0 - stagger / 100.0)     # Stagger: your hits slow their fire
	# Flattened and Floored hold one man (the next of them), not the gang: his share of the fire (25 Oct, the review)
	var on: float = float(maxi(1, mini(int(m.get("remaining", 1)), contact(m["t"])))) if m.has("t") else 1.0
	if float(m.get("flat_t", 0.0)) > 0.0:
		m["flat_t"] = maxf(0.0, float(m["flat_t"]) - dt)
		f *= 1.0 - Data.FX["node/cap_flattened.cut"] / on     # Flattened: the next of them fires at half
	if float(m.get("floor_t", 0.0)) > 0.0:
		m["floor_t"] = maxf(0.0, float(m["floor_t"]) - dt)
		f *= 1.0 - 1.0 / on                       # Floored: a staggered one loses a second of fire
	return f


## A dot on them filled to its cap: every stack, at the gun's rate for the type.
func _dot_fill(m: Dictionary, ty: String) -> void:
	if not Data.DOTS.has(ty):
		return
	if not m.has("dots"):
		m["dots"] = {}
	var t: Dictionary = m["t"]
	var rate: float = float(type_dps()[ty]) * (1.0 - float(t.get("res", {}).get(ty, 0.0))) * pace() * float(t["pace"])
	var cap: float = rate * float(Data.DOTS[ty]["ratio"]) * dot_seconds(ty, true) * dot_fill_stacks(ty) * dot_depth(true) * maxf(dot_grow(true), 1.0)
	m["dots"][ty] = maxf(float(m["dots"].get(ty, 0.0)), cap)


## The stacks a fill counts: dot_stacks, but a rule that lifts the cap (the Rat Man's Bag, the Overalls: 999) fills to
## what the tree gives, not to the lifted cap (12 Oct, the lorry-fix read: a first shot or a dose at 999 stacks was
## a pool of thousands of seconds of the gun, carried gang to gang - the poison builds' lorry at 1.5-2.7 h).
func dot_fill_stacks(ty: String) -> int:
	var n := dot_stacks(ty, true)
	if ty == "poison" and n >= 999:
		n = Data.FX["node/poison_stacks"] if has_node("poison_stacks") else int(Data.DOTS[ty]["stacks"])
	return n


## What a med heals this runner, before the max HP caps it: its own figure through the past, the trait, the trees,
## the nodes, the rules, the set and the Yard. The rig's hover, the pick panel and the heal itself all read this.
func med_heal(it: Dictionary) -> float:
	return Items.heal(it) * fight_grow() * cm("heal") * trait_mult("heal") * (1.0 + (tree_sum("heal_pct") + _affix_sum("heal_pct")) / 100.0) * (Data.FX["node/walking_wounded.heal"] if has_node("walking_wounded") else 1.0) * (Data.FX["rule/ladle.med_heal"] if has_rule("ladle") else 1.0) * (Data.FX["set/ambulance.heal"] if has_set_rule("ambulance") else 1.0) * (Data.FX["yard/med_lab"] if yard_has("med_lab") else 1.0) * (Data.FX["rule/paramedics_bumbag"] if has_rule("paramedics_bumbag") else 1.0)


## A med in words: "+42 HP over 3 s" (at once with Field surgery); a cure, what it stops and for how long.
func med_words(it: Dictionary) -> String:
	if Items.is_cure(it):
		return "%s, then %d s before it lands again" % [Words.CURE_CLEARS[Items.cure_of(it)], int(Data.CURE_IMMUNE_S)]
	var t := use_time(it)
	return "+%d HP %s" % [int(round(med_heal(it))), ("over %s s" % (("%.1f" % t) if t < 10.0 and t != floorf(t) else "%d" % int(t))) if t > 0.0 else "at once"]


## Using a med: the seconds run down under whatever fire there is, then it heals.
func use_med(id: int) -> bool:
	if mission == null or mission["t"].get("no_meds", false):
		return false                          # the Radio's Rationed: no meds on the run
	for k in range(rig.size()):
		if rig[k]["id"] == id and Items.is_cure(rig[k]):
			if has_rule("the_float"):
				return false
			_cure(mission, k)                 # a cure (28 Oct): at once, beside a heal going in
			return true
	if mission["using"] != null:
		return false
	for k in range(rig.size()):
		if rig[k]["id"] == id:
			var it: Dictionary = rig[k]
			if hp >= max_hp() - 0.001 and Items.affix_total(it, "overflow_pct") <= 0.0 and not class_data().get("overheal", false):
				return false                   # full, and nowhere for it to go: kept (the review: its end-of-heal work came free)
			if has_rule("ambulance_bag"):
				pass                           # the Ambulance's Bag (a mythic): never used up
			elif exploit_on("second_opinion"):
				pass                           # the Bag's own use clears the first-med flag: never spent
			elif (has_node("second_shift") or has_set_rule("ambulance")) and not mission.get("free_med", false):
				mission["free_med"] = true     # the first med of the run isn't spent
			else:
				rig.remove_at(k)
			var heal_v: float = med_heal(it) * (1.5 if has_node("worst_first") and hp < max_hp() * 0.5 else 1.0)     # Worst first: +50% under half HP
			if has_node("jab"):
				hp = maxf(1.0, hp - max_hp() * 0.05)     # Jab: a med costs 5% max HP
				mission["jab_t"] = 8.0                   # and gives +20% damage and pace for 8 seconds
			mission["using"] = {"name": it["base"], "left": use_time(it), "time": use_time(it), "heal": heal_v, "overflow": Items.affix_total(it, "overflow_pct") / 100.0, "given": 0.0, "gained": 0.0,
				"guard": Items.affix_total(it, "med_guard_pct") / 100.0, "cures": Data.ELEMENTS.filter(func(ty): return Items.affix_total(it, "cure_" + ty) > 0.0)}     # a rolled med's own (28 Oct, the Clinic's shelf)
			_patch(mission, 0.0)          # field surgery: at once
			return true
	return false


## The Starting Pistol (12 Oct): the secondary's first shot at each of them, triple, before anything else lands - one
## shot of its own figure (its damage a second over its rate), through the physical's increases, their armour and a shock.
func _starting_shot(m: Dictionary, t: Dictionary) -> void:
	m["opened"] = true
	var sec = equipped["Secondary"]
	if sec == null or not has_rounds(sec):
		return
	var rof: float = maxf(0.01, float(Items.base_of(sec).get("rof", 1.0)))
	var parts := {}
	var full: float = _dps(parts)
	var chain: float = full / maxf(0.001, float(parts.get("guns", 1.0)))     # the runner's whole chain on a gun's figure: level, damage, attack, past, trait, growth
	var shot: float = Items.dps(sec) * (1.0 + grade_bonus(sec) / 100.0) / rof * 3.0 * chain * (1.0 + increased("physical") / 100.0) * more("physical") \
		* (1.0 - phys_resist(float(t.get("res", {}).get("physical", 0.0)))) * ((1.0 + shock_amount()) if float(m.get("shock_t", 0.0)) > 0.0 else 1.0)
	m["target_hp"] -= shot
	_count_src(m, Items.full_name(sec), shot)
	m["dealt"] = float(m.get("dealt", 0.0)) + shot
	if not m.has("dealt_by"):
		m["dealt_by"] = {}
	m["dealt_by"]["physical"] = float(m["dealt_by"].get("physical", 0.0)) + shot


## How deep a burn, a poison or a bleed on them can build: the Plumber's Belt doubles the pool, drained at the same
## seconds, so it ticks twice as hard and never slower (12 Oct; doubling the seconds dealt less on a quick kill).
func dot_depth(theirs := true) -> float:
	return 2.0 if theirs and has_rule("plumbers_belt") else 1.0


## How long a chill or a shock holds on them: the Plumber's Belt doubles it (12 Oct).
func status_s(s: float) -> float:
	return s * (Data.FX["rule/plumbers_belt"] if has_rule("plumbers_belt") else 1.0)


## The Arsonist's Rig: a petrol bomb's worth of fire on everyone on you, through the model.
func _alight(m: Dictionary) -> void:
	var t: Dictionary = m["t"]
	var r := float(t.get("res", {}).get("fire", 0.0))
	var single: float = Data.FX["rule/arsonists_rig.blast"] * fight_grow() * (1.0 + increased("fire") / 100.0) * more("fire") * (1.0 - r) * ((1.0 + shock_amount()) if float(m.get("shock_t", 0.0)) > 0.0 else 1.0)
	var crowd: int = mini(m["remaining"], contact(t))
	m["target_hp"] -= single * crowd
	_count_src(m, "rule:arsonists_rig", single * crowd)
	m["dealt"] = float(m.get("dealt", 0.0)) + single * crowd
	if not m.has("dealt_by"):
		m["dealt_by"] = {}
	m["dealt_by"]["fire"] = float(m["dealt_by"].get("fire", 0.0)) + single * crowd
	if not m.has("dots"):
		m["dots"] = {}
	_dot_add(m["dots"], "fire", single, maxf(single, float(type_dps()["fire"]) * (1.0 - r) * pace() * t["pace"]))


## A grenade thrown from a pouch (32): its damage to everyone on you, as its
## type through the damage model (the trees' increases and mores, their
## resist), its dot on the gang, a chill or a shock as its type does. Spends
## the pouch; Second shift covers meds, not these.
func use_grenade(id: int) -> bool:
	if mission == null or mission["remaining"] <= 0 or mission.get("dry", false):
		return false
	var m: Dictionary = mission
	var t: Dictionary = m["t"]
	for k in range(rig.size()):
		var it: Dictionary = rig[k]
		if it["id"] != id or not Items.is_grenade(it):
			continue
		var b := Items.base_of(it)
		var ty: String = b["type"]
		var res: Dictionary = t.get("res", {})
		var r := float(res.get(ty, 0.0))
		if ty == "shock" and has_rule("sparkys_gloves"):
			r = 0.0
		var single: float = float(b["damage"]) * fight_grow() * (1.0 + increased(ty) / 100.0) * more(ty) * (1.0 - r) * ((1.0 + shock_amount()) if float(m.get("shock_t", 0.0)) > 0.0 else 1.0) * grenade_mult()
		if ty == "bleed" and has_node("cap_bleed_out"):
			single *= Data.FX["node/cap_bleed_out"]                     # Bleed out: a nail bomb's bleed, half again too
		var crowd: int = mini(m["remaining"], contact(t) + (1 if has_node("grenade_extra") else 0))     # Cook it off: one more
		var landed: float = single * crowd
		rig.remove_at(k)
		_grenade_after(m, single)
		m["target_hp"] -= landed
		_count_src(m, "grenades", landed)
		m["dealt"] = float(m.get("dealt", 0.0)) + landed
		if not m.has("dealt_by"):
			m["dealt_by"] = {}
		m["dealt_by"][ty] = float(m["dealt_by"].get(ty, 0.0)) + landed
		if not m.has("dots"):
			m["dots"] = {}
		# the dot's cap: the gun's own rate for the type, or the throw's, whichever is the bigger, so a throw never shrinks a burn the gun built
		var gun_rate: float = float(type_dps()[ty]) * (1.0 - r) * pace() * t["pace"] * (1.5 if (ty == "bleed" and has_node("cap_bleed_out")) else 1.0)
		_dot_add(m["dots"], ty, single, maxf(single, gun_rate))
		if ty == "frost":
			m["chill_t"] = status_s(2.0)
		if ty == "shock":
			m["shock_t"] = 999.0 if (has_rule("tester") or has_node("cap_arc")) else status_s(2.0)
		m["thrown"] = int(m.get("thrown", 0)) + 1
		log_event(Words.LOG["thrown"] % [it["base"], landed, ty, crowd])
		return true
	return false


## A med as it says (19 Oct, Matt: "heal Xhp over N seconds" healed nothing till the timer ran out, then all of it): its
## heal a share every second over its time, stopping at full - unless what heals past full has somewhere to go (a med's
## overflow, the Paramedic's overheal: Guard). Field surgery: all of it at once. The rest of a med's work (Transfusion,
## the dose, the bleed stopped, Clean hands, the Arsonist's Rig) lands as it finishes.
func _patch(m: Dictionary, dt: float) -> void:
	if m["using"] == null:
		return
	var u: Dictionary = m["using"]
	var step: float = dt * (2.0 if has_node("overtime") and float(m.get("guard", 0.0)) > 0.0 else 1.0)     # Overtime: with Guard up, a med takes half the time
	var total_t: float = maxf(float(u.get("time", u["left"])), 0.0001)
	var total: float = float(u["heal"])
	var portion: float = total - float(u.get("given", 0.0)) if has_node("field_surgery") or float(u["left"]) <= step \
		else total * step / total_t
	u["left"] = float(u["left"]) - step
	if has_node("field_surgery"):
		u["left"] = 0.0
	var spills: bool = float(u.get("overflow", 0.0)) > 0.0 or class_data().get("overheal", false)
	if portion > 0.0:
		var hp_was := hp
		_heal(m, portion * (Data.FX["joint/paramedic_frost.heal"] if (has_joint("paramedic_frost") and float(m.get("chill_t", 0.0)) > 0.0) else 1.0), true, float(u.get("overflow", 0.0)))
		u["given"] = float(u.get("given", 0.0)) + portion
		u["gained"] = float(u.get("gained", 0.0)) + (hp - hp_was)     # what it healed, after the max HP caps it (the log's figure)
	if float(u["left"]) > 0.0 and not (hp >= max_hp() - 0.001 and not spills):
		return
	if has_node("cap_transfusion"):
		m["guard"] = guard_cap()             # Transfusion: a med fills Guard to the top
	if has_joint("paramedic_shock") and m["remaining"] > 0:
		m["shock_t"] = maxf(float(m.get("shock_t", 0.0)), status_s(3.0))     # the Paramedic's paddles, joined: a med shocks them (joints B, 24 Oct)
	if m.has("my_dots"):
		m["my_dots"].erase("bleed")      # a dressing stops the bleeding
	if has_node("cap_clean_hands"):
		_clear_on_you(m)                # Clean hands: everything on you cleared, and a grace
		m["immune_t"] = 3.0
	if float(u.get("guard", 0.0)) > 0.0:
		_guard_add(m, max_hp() * float(u["guard"]))     # a rolled med's beat of Guard (28 Oct)
	for ty in u.get("cures", []):
		_cure_on(m, ty)                            # a cure built in: its element off you, and its grace, as the cure's
	if has_rule("arsonists_rig") and m["remaining"] > 0:
		_alight(m)                       # the Arsonist's Rig: the med's a petrol bomb's worth on everyone on you
	m["meds_used"] += 1
	log_event(Words.LOG["med_used"] % [u["name"], int(round(float(u.get("gained", 0.0)))), ceili(hp), ceili(max_hp()), " · stopped at full" if float(u["left"]) > 0.0 else ""])
	m["using"] = null


## What a kill heals: life on kill, the Keeper's gun, the Ladle, Iron.
func _kill_heal() -> float:
	return _affix_sum("life_per_kill") + (max_hp() * Data.FX["rule/keepers_gun"] if has_rule("keepers_gun") else 0.0) + (max_hp() * Data.FX["rule/ladle.kill_heal"] if has_rule("ladle") else 0.0) + (max_hp() * Data.FX["node/cap_iron"] if has_node("cap_iron") and hp < max_hp() * 0.5 else 0.0)


func _kill(m: Dictionary, t: Dictionary) -> void:
	m["kills"] += 1
	var skfx: Dictionary = m.get("sk", {}).get("fx", {})
	_heal(m, _kill_heal())
	if m.get("dry", false):
		return                               # a dry run: the fight only, nothing earned
	_run_materials(m)                        # the run's material roll, at its first kill (1 Nov: into the pack)
	var gain: float = t["xp"] * (Data.FX["node/hit_and_run.kill_pay"] if has_node("hit_and_run") else 1.0) * (Data.MYTHIC_PAY if has_rule("freedom") else 1.0)
	m["xp"] += gain
	var before := level()
	_gain_xp(gain)
	_earn_points(before)
	if bool(t.get("dogs", false)):
		return                                   # a dog: its XP, nothing it carries (1 Nov, run events)
	if skfx.get("no_drop", false):
		skfx["no_drop"] = false
		return                                   # Barred: thrown out, counted (his XP), nothing from him - no tins, notes, salvage or find (the review)
	var pay: float = 1.0 if not has_node("hit_and_run") else float(Data.FX["node/hit_and_run.kill_pay"])     # the XP's figure (25 Oct, the review)
	m["cash"] += (Data.FX["rule/issued_rifle.kill"] if has_rule("issued_rifle") else 1.0) * (0.0 if t.get("no_kill_cash", false) else 1.0) * (t["cash"] * rng.randf_range(0.5, 1.5) * (1.0 + (tree_sum("cash_pct") + charm_cash()) / 100.0) + _affix_sum("cash_per_kill")) * inflation() * pay * (Data.FX["rule/bookies_pencil.cash"] if has_rule("bookies_pencil") else 1.0) * (Data.FX["set/bank.kill_cash"] if has_set_rule("bank") else 1.0) \
		* (Data.FX["node/light_fingers.cash"] if has_node("light_fingers") else 1.0) * (Data.FX["rule/managers_coat"] if has_rule("managers_coat") else 1.0) * trait_mult("cash") * (Data.MYTHIC_PAY if has_rule("freedom") else 1.0)
	if not has_rule("managers_coat"):
		m["notes"] = int(m.get("notes", 0)) + notes_a_kill(t) * (int(Data.MYTHIC_PAY) if has_rule("freedom") else 1)
	var dd: int = int(t.get("depth", 1))
	var kind: String = Data.ZONE_SALVAGE[int(Data.TIERS[int(t["tier"])]["zone"])]
	if kind != "" and dd >= Data.SALVAGE_DEPTH and rng.randf() < Data.SALVAGE_KILL * (dd - Data.SALVAGE_DEPTH + 1):
		m["salvage"] = m.get("salvage", {})
		m["salvage"][kind] = int(m["salvage"].get(kind, 0)) + 1      # the deep sites' salvage (9 Oct), home with the run
	if has_node("on_a_roll") and not has_node("quiet_hands"):
		m["roll"] = mini(10, int(m.get("roll", 0)) + 1)     # On a roll: a kill untouched
	if has_node("quiet_hands"):
		return
	if float(skfx.get("chancer", 0.0)) > 0.0:
		var lucky: Dictionary = t.duplicate()
		lucky["rarity"] = float(t.get("rarity", 0.0)) + float(skfx["chancer"])
		skfx["chancer"] = 0.0
		_find(m, lucky, true)                    # Chancer: this one always drops, and better
		return
	if has_node("breakers_yard"):
		if int(m["kills"]) % 3 == 0:
			_find(m, t, true, {"slots": [Data.ATTACHMENT], "lean": 1.0, "socket": true})     # Breaker's yard: 1 kill in 3, a gun part or a socketable
		return                                   # and no plain kit
	if has_node("nothing_wasted") or (has_joint("scrapper_fire") and m.get("kill_burning", false)) or rng.randf() < t["drop"] * (1.0 + loot_bonus()) * (Data.FX["node/loud.drop"] if has_node("loud") else 1.0) * (1.0 + Data.FX["atlas/their_own_kit"] * atlas_rank("their_own_kit")) * pay:
		if has_rule("qm_ledger"):
			var up: Dictionary = t.duplicate()
			up["loot_tier"] = mini(loot_cap(int(t.get("level", lv_at(int(t["tier"]), int(t["depth"]))))), int(t["loot_tier"]) + 1)     # signed for: a tier up
			_find(m, up, true)
		else:
			_find(m, t, true)


## The old paper money: every kill carries some, more the deeper you are.
func notes_a_kill(t: Dictionary) -> int:
	return (int(ceil(Data.NOTES_KILL * (1.0 + (int(t["depth"]) - 1) / 3.0) * (1.0 + _affix_sum("notes_pct") / 100.0))) + int(round(atlas_level("paid_in_notes")))) * (Data.FX["rule/wardens_hat.notes"] if has_rule("wardens_hat") else 1)


## The crew's head is down: their drop, the notes they held, the zone's boss beaten.
func _boss_down(m: Dictionary, t: Dictionary) -> void:
	var b: Dictionary = m["boss"]
	b["alive"] = false
	m["kills"] += 1
	if m.get("dry", false):
		return
	_run_materials(m)                     # a head the run's first kill: its roll too (1 Nov)
	m["xp"] += t["xp"] * 10.0
	var before := level()
	_gain_xp(t["xp"] * 10.0)
	_earn_points(before)
	m["cash"] += (0.0 if t.get("no_kill_cash", false) else 1.0) * t["cash"] * 10.0 * inflation()     # the Radio's Overdrawn: no cash off the head either
	m["notes"] = int(m.get("notes", 0)) + int(round(Data.NOTES_BOSS * (1 if bool(m.get("head_fight", false)) and str(m.get("county", "")) == "" else int(t["depth"])) * (1.0 + Data.FX["atlas/bounties"] * atlas_rank("bounties"))))     # (BUILD55-A) the head's fight at 3/3 pays as at 1/3
	if str(b.get("order", "")) != "":
		_order_down(m, t, b)                  # the order's true pinnacle: their own drops, none of a crew's
		return
	_head_materials(m)                        # the rebuild (18 Oct): a head's handful of the site's material
	if b.get("pinnacle", false) and atlas_rank("head_start") > 0:
		atlas_points += 1                     # Head start: a head beaten at full strength pays a map point
		log_event(Words.MAP["head_start"] % b["name"])
	var first: bool = not bosses_beaten[int(b["zone"])]
	if first:
		_web_reward("head:" + str(b["name"]), Data.REWARD_HEAD, str(b["name"]))
		_a55_head_first(int(b["zone"]))       # (BUILD55-A) the next zone's first site "New"; the Carpet Man's road     # a head's first fall: a point for every runner
	chron("boss", {"name": str(b["name"]), "zone": int(b["zone"]), "tier": int(m["tier"]), "depth": int(t.get("depth", 1)), "first": first,
		"pinnacle": bool(b.get("pinnacle", false)), "convoy": bool(m.get("convoy", false))})
	var opened_before: Array = Data.CLASSES.map(func(c): return class_open(str(c["name"])))
	bosses_beaten[int(b["zone"])] = true
	_say_unlocks(opened_before)
	var pool: Array = []
	var head: Dictionary = {}
	for cb in Data.BOSSES:
		if cb["name"] == b["name"]:
			head = cb
	for u in Data.UNIQUES:
		if u["name"] in head.get("uniques", []):
			pool.append(u)
		elif b.get("pinnacle", false) and int(u.get("pinnacle", -1)) == int(b["zone"]):
			pool.append(u)                    # at full strength, their charm is in the pool
	if m.get("convoy", false) and m.get("boss_queue", []).is_empty():
		# the last of the convoy: the Lorry's Load comes home too, and the lorry's done for this Yard (7 Oct)
		var ld := Items.roll_unique(_unique_named(Data.CONVOY_UNIQUE), rng, int(t.get("level", -1)), int(t["loot_tier"]))
		_head_drop(m, ld)
		log_event(Words.LOG["convoy_done"] % ld["unique"])
		if not lorry_done:
			lorry_done = true
			lorries += 1
			_stats_dirty()                     # the lorries multiply damage and HP: read afresh this tick (review 43, 4)
			chron("lorry", {"lorries": lorries})
			log_event(Words.YARD["lorry"])
	if not pool.is_empty():
		var it := Items.roll_unique(pool[rng.randi_range(0, pool.size() - 1)], rng, int(t.get("level", -1)), int(t["loot_tier"]), true)     # at the depth he's fought at (12 Oct); his own, off him (21 Oct)
		_head_drop(m, it)                      # on the floor by hand, like any find (1 Nov); else into the pack whatever it holds
		log_event(Words.LOG["head_down_found"] % [b["name"], Words.BOSSES.get(b["name"], {}).get("down", ""), it["unique"]])
		if atlas_rank("two_of_everything") > 0:
			var it2 := Items.roll_unique(pool[rng.randi_range(0, pool.size() - 1)], rng, int(t.get("level", -1)), int(t["loot_tier"]), true)
			_head_drop(m, it2)
			log_event(Words.LOG["second_unique"] % it2["unique"])
	if pool.is_empty():
		log_event(Words.LOG["head_down"] % [b["name"], Words.BOSSES.get(b["name"], {}).get("down", "")])     # a head with no unique of his own (the Gamekeeper)
	# the rooms he holds (13 Oct): the drop is the sign (Matt) - his thing opens its room there and then. The deeds
	# come home in the pack whatever it holds, for their fate, and drop again while it's undecided and none held (a
	# death lost them, or a save from before the gates hadn't had them); the rest open their room and go to it.
	if not m.get("convoy", false):
		for room in head.get("opens", {}):
			var thing := _plain(Data.PAPER, str(head["opens"][room]))
			if Items.is_deeds(thing):
				if deeds_fate != "" or _deeds_held(m):
					continue
				thing["deeds"] = true
				if not deeds_found:
					deeds_found = true
					chron("deeds", {})
				log_event(Words.DEEDS["found"])
				m["found"].append(thing)
			elif room_open(str(room)):
				continue
			else:
				log_event(Words.LOG["found"] % thing["base"])
				m["found"].append(thing)          # in the pack to see, a keepsake home (15 Oct): the room opens here, the thing goes to the drawer
			_home_gate(thing)
			_left_drop(str(room), m)              # at half till it's home (2 Nov, BUILD46-S)
	if first and campaign_done():
		log_event(Words.YARD["campaign"])


## A head's unique off him (1 Nov, Matt's playtest: the Keeper's Wax Jacket sat in a spot of its own under the pack's
## cells, "No room in the pack" and Equip greyed): by hand it lands on the floor like any other find, to take or wear
## off the floor; on an auto-run or "Fill up, then go" into the pack whatever it holds (strapped on), as before. `mag`:
## a gun's magazine on it, as the crew heads' always were.
func _head_drop(m: Dictionary, it: Dictionary, mag := true) -> void:
	if by_hand(m):
		_floor_put(m, it)
		it["head_drop"] = true                # left down, it still comes home (_floor_mythics_in; the review)
	else:
		m["found"].append(it)
	if mag:
		_mag_in_pack(m, it)
	_read(it)


## A gun's standard magazine, empty (30 Oct: every gun the runner gets comes with one), {} for a gun that takes none.
func gun_mag(gun: Dictionary) -> Dictionary:
	if Items.mag_size(gun) <= 0:
		return {}
	var b: Dictionary = Items.standard_mag(Items.ammo_type(gun))
	return _plain(Data.MAGAZINE, str(b["name"])) if not b.is_empty() else {}


## A head's gun (30 Oct) brings its standard magazine on it (the fix round): kept as the gun is, home with it.
func _mag_in_pack(_m: Dictionary, it: Dictionary) -> void:
	if not Items.is_gun(it) or it.get("with_mag", false):
		return
	_mag_attach(it)


## A gun's magazine carried with it (the fix round, the review's 3): on the gun itself till it's home (into the stash with
## it) or fitted on the run (into the rig) - kept whenever the gun is kept, left when it's left.
func _mag_attach(gun: Dictionary) -> void:
	gun["with_mag"] = true
	var mag: Dictionary = gun_mag(gun)
	if not mag.is_empty():
		gun["mag_item"] = mag


## The magazines carried on guns, off them: a gun in the stash puts its own in the stash beside it (whatever the room: it
## came with the gun), a worn gun's goes to the stash too. At home, before the gate.
func _mags_home() -> void:
	for g in stash.duplicate() + [equipped["Primary"], equipped["Secondary"]]:
		if g is Dictionary and g.has("mag_item"):
			var mag: Dictionary = g["mag_item"]
			g.erase("mag_item")
			if not stash_put(mag):
				stash.append(mag)


## Room in the stash for a piece and, a gun, the magazine that comes with it (the fix round, the review's 7).
func fits_with_mag(it: Dictionary) -> bool:
	var need: int = 0 if stash_free(it) else Items.size(it)
	if Items.is_gun(it) and not it.get("with_mag", false) and Items.mag_size(it) > 0 and not yard_has("racks"):
		need += 1                             # its standard magazine, a cell (no roll: a room check spends no dice)
	return stash_used() + need <= stash_cap()


## A gun got (bought, built, issued, off a head, an expedition's) brings its standard magazine to the stash, once
## (30 Oct: a gun is never dead for want of one). A find's comes in the pack with it instead (_land).
func _mag_with(it: Dictionary) -> void:
	if not Items.is_gun(it) or it.get("with_mag", false):
		return
	it["with_mag"] = true
	var mag: Dictionary = gun_mag(it)
	if not mag.is_empty() and not stash_put(mag):
		stash.append(mag)                     # whatever the room: it came with the gun
	var k: int = stash.find(it)
	if k >= 0 and k < stash.size() - 1:
		stash.remove_at(k)
		stash.append(it)                      # the gun the last in, its magazine before it


## The rounds the guns you have take (17 Oct): worn, in the stash, in the rig, in this run's pack - none for a blade or a
## gun that takes none.
func owned_ammo_types(m = null) -> Array:
	var out: Array = []
	var guns: Array = [equipped["Primary"], equipped["Secondary"]] + stash + rig
	if m is Dictionary:
		guns += m.get("found", []) + m.get("floor", [])
	for g in guns:
		if g is Dictionary and Items.is_gun(g):
			var ty: String = Items.ammo_type(g)
			if not (ty in ["", "none"]) and not (ty in out):
				out.append(ty)
	return out


## The Garden Centre's first clear (17 Oct): one of Data.FIRST_GUNS, plain, its standard magazine (30 Oct) and a box of
## its rounds, in the pack whatever the room - the step every save gets.
func _first_gun(m: Dictionary) -> void:
	var pick: Array = Data.FIRST_GUNS[rng.randi_range(0, Data.FIRST_GUNS.size() - 1)]
	var gun: Dictionary = _plain(str(pick[0]), str(pick[1]))
	gun["first_gun"] = true                   # kept by a full pack like the deeds (_pack_keeps); the mark comes off at home
	m["found"].append(gun)
	var mag: Dictionary = gun_mag(gun)
	gun["with_mag"] = true
	if not mag.is_empty():
		mag["first_gun"] = true
		m["found"].append(mag)
	var box := {}
	for b in Data.BASES[Data.AMMO]:
		if str(b["type"]) == Items.ammo_type(gun) and int(b["tier"]) == 1:
			box = _plain(Data.AMMO, str(b["name"]))
			box["first_gun"] = true
			break
	if not box.is_empty():
		m["found"].append(box)
	log_event(Words.FIRST_GUN % [Words.a_thing(str(gun["base"])), Words.a_thing(str(mag.get("base", "magazine"))), Words.mid_base(str(box.get("base", "rounds")))])     # never lower-cased whole (the three-stage review, UI 18)
	chron("first_gun", {"base": str(gun["base"])})


## A find. `from_kill`: what they were carrying - guns, armour, a helmet, a
## rig. From a look: what the site holds - attachments, meds, packs, and a
## share of gear left lying about. `crate`, a Data.CRATES entry: its lean and its quality (13 Oct). `capture`: rolled,
## not landed - the dog's sniff rolls a crate's best find at the clear and lands it when the crate's opened. Returns
## {"it": the find, "said": its log line}, or {} for none.
func _find(m: Dictionary, t: Dictionary, from_kill := false, crate: Dictionary = {}, capture := false) -> Dictionary:
	if has_rule("removal_van") and not m.get("dry", false):
		t = t.duplicate()                     # the Removal Van (a mythic): every find a tier up
		t["loot_tier"] = mini(loot_cap(int(t.get("level", lv_at(int(t["tier"]), int(t["depth"]))))), int(t["loot_tier"]) + 1)
	if not capture:
		m["finds"] = int(m.get("finds", 0)) + 1    # every find, stacked, swapped or left: the count the tests read (a nosed one counts when it lands)
	if has_node("all_or_nothing"):
		m["skipped"] = int(m.get("skipped", 0)) + 1
		if m["skipped"] % 2 == 0:
			return {}                     # half as much is found
	# the site's own shape of find: its slot weights, and its leanings to
	# meds, ammo, parts and papers
	var site: Dictionary = Data.TIERS[int(t["tier"])]
	var shape: Dictionary = site["shape"]
	var slot: String = _site_slot(site, from_kill)
	var gear_slot: String = slot
	var kind := rng.randf()
	if from_kill:
		if kind < Data.MED_DROP * 0.5 * float(shape.get("med", 1.0)):
			slot = Data.MEDICAL
		elif kind < Data.MED_DROP * 0.5 * float(shape.get("med", 1.0)) + Data.AMMO_DROP * float(shape.get("ammo", 1.0)):
			slot = Data.AMMO
	else:
		if rng.randf() < paper_odds(int(t["tier"])):
			slot = Data.PAPER
		elif rng.randf() < Data.CHARM_DROP * (Data.FX["yard/tracker.charms"] if yard_has("tracker") else 1.0):
			slot = Data.CHARM
		elif kind < Data.MED_DROP * float(shape.get("med", 1.0)):
			slot = Data.MEDICAL
		elif kind < Data.MED_DROP * float(shape.get("med", 1.0)) + (Data.ATT_DROP + tree_sum("att_share") / 100.0) * float(shape.get("att", 1.0)):
			slot = Data.ATTACHMENT
		elif kind < Data.MED_DROP * float(shape.get("med", 1.0)) + (Data.ATT_DROP + tree_sum("att_share") / 100.0) * float(shape.get("att", 1.0)) + Data.AMMO_DROP * 0.5 * float(shape.get("ammo", 1.0)):
			slot = Data.AMMO
		elif kind < Data.MED_DROP * float(shape.get("med", 1.0)) + (Data.ATT_DROP + tree_sum("att_share") / 100.0) * float(shape.get("att", 1.0)) + Data.AMMO_DROP * 0.5 * float(shape.get("ammo", 1.0)) + Data.GRENADE_DROP:
			slot = Data.GRENADE                   # a grenade lying about (32)
	# the crate's lean (13 Oct): an ammo tin's finds mostly rounds, a military crate's guns and armour
	if not crate.is_empty() and crate.has("slots") and rng.randf() < float(crate.get("lean", 0.0)):
		slot = str(crate["slots"][rng.randi_range(0, crate["slots"].size() - 1)])
	if slot == Data.ATTACHMENT and rng.randf() < Data.MAG_OF_PARTS:
		slot = Data.MAGAZINE                  # a magazine (30 Oct, magazines as items): a share of what would be a gun part
	var owned: Array = owned_ammo_types(m) if (slot == Data.AMMO or slot == Data.MAGAZINE) else []
	if slot == Data.AMMO and owned.is_empty():
		slot = gear_slot                      # rounds for no gun you have (17 Oct, Matt's playtest: three boxes, no gun): something else instead
	slot = _focus_slot(slot)                  # a slot focus (BUILD50-T): one gear find in two its slot, on its own dice
	var socket_find: bool = slot != Data.PAPER and rng.randf() < (0.5 if crate.get("socket", false) else Data.SOCKET_FIND)     # a socketable, its own kind of find, kills too (21 Oct); half of Breaker's yard's
	if socket_find:
		slot = Data.ATTACHMENT
	if _supplies_take(slot, from_kill, socket_find, site, crate):
		slot = Data.SUPPLIES                  # medical supplies (28 Oct): a medicine cabinet's, a site's leaning to meds
	var said := ""
	var quality: float = rarity_bonus() + float(t.get("rarity", 0.0)) + float(crate.get("rarity", 0.0))
	var fat: bool = str(m.get("night_special", "")) == "fat"     # a night's fat drop (BUILD50 N): quality ×2, a unique's chance ×3
	if fat:
		quality *= Data.NIGHT_FAT_QUALITY
	var it: Dictionary
	var loose: Array = loose_at(int(t["depth"]), int(t["loot_tier"]))     # those whose range takes the find's tier (12 Oct)
	var pieces: Array = set_pieces_at(int(t["depth"]))
	var own: Dictionary = site_unique(int(t["tier"]))
	var own_odds: float = Data.SITE_UNIQUE_DROP * (1.0 if own.is_empty() or not (own["name"] in shelf) else Data.SITE_UNIQUE_AGAIN)
	var myth: Dictionary = mythic_roll()
	var find_lv: int = int(t.get("level", lv_at(int(t["tier"]), int(t["depth"]))))
	var find_tier: int = int(t["loot_tier"])
	find_tier = c55_tier_up(m, t, slot, find_tier, find_lv)     # (BUILD55-C) a 3/3's quarter a tier up, within loot_cap
	if slot in Data.SLOTS and rng.randf() < Data.FIND_AT_MINE and wearable_level() < find_lv:
		# a fifth of the plain gear at the level the runner wears (16 Oct), on a base the campaign gives - as a gamble
		# rolls: a deep signal's tier-7+ bases stay the deep runner's (the review); the tier his level's own (the fix round,
		# 29 Oct, the review's B4: the campaign's best is T4 now, the early signals' T5-6)
		find_lv = wearable_level()
		find_tier = mini(find_tier, tier_for_level(find_lv))
	if not myth.is_empty():
		it = Items.roll_unique(myth, rng, int(t.get("level", -1)), int(t["loot_tier"]))     # a mythic: one find in MYTHIC_ODDS_IN, anywhere - ahead of a socketable (the review), and of supplies (28 Oct, the review)
		said = Words.MYTHIC_FOUND % it["unique"]
	elif slot == Data.SUPPLIES:
		it = _plain(Data.SUPPLIES, "Medical supplies")
		Items.set_stack(it, rng.randi_range(int(Data.SUPPLY_COUNT[0]), int(Data.SUPPLY_COUNT[1])))
	elif socket_find:
		it = socket_find_roll(int(t["loot_tier"]))
	elif not own.is_empty() and int(t["depth"]) >= site_unique_depth(int(t["tier"])) and rng.randf() < own_odds:
		it = Items.roll_unique(own, rng, int(t.get("level", -1)), int(t["loot_tier"]))     # the site's own, only here and only this deep (endgame part 3), at the find's tier
		said = "Found: %s. %s" % [it["unique"], Words.SHELF["own_found"] % site["name"]]
	elif not loose.is_empty() and rng.randf() < loose_unique_chance(t, float(crate.get("unique", 1.0)), fat):     # a Safe's double, a unique focus and a fat drop, inside the cap (the review; fix 50)
		it = Items.roll_unique(pick_unique(loose, int(t["loot_tier"])), rng, int(t.get("level", -1)), int(t["loot_tier"]))     # the band's weight picks
		said = "Found: %s" % it["unique"]
	elif t["depth"] >= Data.SIGNAL_DEPTH and not pieces.is_empty() and rng.randf() < minf(Data.SET_CAP, Data.SET_DROP * (t["depth"] - 1)):     # (BUILD55-A) from depth 4, never a stage
		var pick: Array = pieces[rng.randi_range(0, pieces.size() - 1)]
		it = Items.roll_set_piece(pick[0], pick[1], rng, int(t.get("level", -1)), int(t["loot_tier"]))
		said = "Found: %s, %s" % [it["piece"], str(pick[0]).to_lower()]
	else:
		# quality decides the rarity: the trees', the charm's and the intel's; quantity is how much, not how good (27)
		it = Items.roll(slot, 1 if slot == Data.PAPER else find_tier, rng, quality, has_node("all_or_nothing"), has_rule("lucky_cap"),
			site["name"], str(site["drops"].get("type", "")), Data.FX["atlas/picked_over.base"] + Data.FX["atlas/picked_over"] * atlas_rank("picked_over"), int(t["depth"]), find_lv,
			c61_theme(m, t, slot, find_tier), c61_share(m, t, slot))     # (BUILD55-C) the site's list; (BUILD61-C) a County place's, a 3/3's top quarter
		if slot == Data.AMMO:
			# rounds only for a gun you have (17 Oct): half for the one in your hands, as they always were, the rest any you
			# own - a stash of guns kept to sell doesn't thin the hands' share (the review) - at the find's tier or under
			var hand_ty: String = Items.ammo_type(equipped["Primary"]) if equipped["Primary"] != null else ""
			var want: Array = owned
			if hand_ty in owned and rng.randf() < 0.5:
				want = [hand_ty]
			var fits := []
			if not (str(Items.base_of(it)["type"]) in want):
				for b in Data.BASES[Data.AMMO]:
					if str(b["type"]) in want and int(b["tier"]) <= int(t["loot_tier"]):
						fits.append(b)
				if fits.is_empty():
					for b in Data.BASES[Data.AMMO]:
						if str(b["type"]) in want and int(b["tier"]) == 1:
							fits.append(b)
			if not fits.is_empty():
				it = _plain(Data.AMMO, fits[rng.randi_range(0, fits.size() - 1)]["name"])
		elif slot == Data.MAGAZINE and not owned.is_empty() and not (Items.mag_type(it) in owned) and rng.randf() < 0.7:
			# a magazine mostly for a gun you have (30 Oct), at the find's tier or under, its kind kept where the type has it
			var mfits: Array = Data.BASES[Data.MAGAZINE].filter(func(b): return str(b["type"]) in owned and int(b["tier"]) <= maxi(1, find_tier))
			var same_kind: Array = mfits.filter(func(b): return str(b["kind"]) == Items.mag_kind(it))
			if not same_kind.is_empty():
				mfits = same_kind
			if not mfits.is_empty():
				it = _plain(Data.MAGAZINE, str(mfits[rng.randi_range(0, mfits.size() - 1)]["name"]))
	if from_kill and m.get("kill_bleeding", false) and has_joint("drifter_bleed") and slot in Data.SLOTS and not it.has("unique") and not it.has("set") and not Items.is_deeds(it):
		var twice: Dictionary = Items.roll(slot, 1 if slot == Data.PAPER else find_tier, rng, quality, has_node("all_or_nothing"), has_rule("lucky_cap"),
			site["name"], str(site["drops"].get("type", "")), Data.FX["atlas/picked_over.base"] + Data.FX["atlas/picked_over"] * atlas_rank("picked_over"), int(t["depth"]), find_lv)
		if int(twice.get("rarity", 0)) > int(it.get("rarity", 0)):
			it = twice                       # the Drifter's razor, joined: a bleeding kill's drop rolls its rarity twice
	if has_node("cap_loaded_dice") and int(it.get("rarity", 0)) >= 2 and not it.has("unique") and not it.has("set") and slot != Data.PAPER:
		var again: Dictionary = Items.roll(slot, 1 if slot == Data.PAPER else find_tier, rng, quality, has_node("all_or_nothing"), has_rule("lucky_cap"),
			site["name"], str(site["drops"].get("type", "")), Data.FX["atlas/picked_over.base"] + Data.FX["atlas/picked_over"] * atlas_rank("picked_over"), int(t["depth"]), find_lv)
		if Items.score(again) > Items.score(it):
			it = again                       # Loaded dice: a Rare or better rolls twice, keeps the better
	_focus_resist(it)                         # a resist focus (BUILD50-T): one gear find in three carries it
	if capture:
		return {"it": it, "said": said}
	var shown: Dictionary = it.duplicate(true)     # as found: landing joins a stack and leaves the find's own count at what was left over
	_land(m, it, said, not from_kill and not crate.is_empty() and by_hand(m))
	if m.has("wager_slots") and str(it.get("slot", "")) in Data.SLOTS:
		_wager_finds(m, it, func(): return Items.roll(str(it["slot"]), find_tier, rng, quality, has_node("all_or_nothing"), has_rule("lucky_cap"),
			site["name"], str(site["drops"].get("type", "")), Data.FX["atlas/picked_over.base"] + Data.FX["atlas/picked_over"] * atlas_rank("picked_over"), int(t["depth"]), find_lv),
			not from_kill and not crate.is_empty() and by_hand(m))     # Kev's ×3 a slot's finds (29 Oct)
	return {"it": shown, "said": said}


## Whether a look's find is medical supplies instead: a look's (not a kill's), not a socketable, and never a paper
## (28 Oct, the review: at the Hospital they took the endgame's keys), at supply_odds.
func _supplies_take(slot: String, from_kill: bool, socket_find: bool, site: Dictionary, crate: Dictionary) -> bool:
	return not from_kill and not socket_find and slot != Data.PAPER and rng.randf() < supply_odds(site, crate)


## The share of a look that's medical supplies (28 Oct): SUPPLY_FIND times a site's lean to meds where it has one, and
## SUPPLY_CABINET more in a medicine cabinet.
func supply_odds(site: Dictionary, crate: Dictionary) -> float:
	var med: float = float(site.get("shape", {}).get("med", 0.0))
	return (Data.SUPPLY_FIND * med if med > 1.0 else 0.0) + (Data.SUPPLY_CABINET if str(crate.get("key", "")) == "medicine" else 0.0)


## A socketable found (21 Oct): one at the find's tier or under, SOCKET_OWN of the time one of the class's own pair's
## elements (a class with no socketable for its pair - the Doorman's bleed and physical - any).
func socket_find_roll(at_tier: int) -> Dictionary:
	var pool: Array = []
	for b in Data.ATTACHMENTS:
		if str(b.get("mount", "")) == "socket" and int(b["tier"]) <= maxi(1, at_tier):
			pool.append(b)
	var own: Array = pool.filter(func(b): return Data.AFFINITY.get(cls, []).any(func(el): return float(b.get("conv_%s_pct" % el, 0)) > 0.0))
	var from: Array = own if not own.is_empty() and rng.randf() < Data.SOCKET_OWN else pool
	return _plain(Data.ATTACHMENT, str(from[rng.randi_range(0, from.size() - 1)]["name"]))


## A find rolled, into the pack - or onto the floor, a search's by hand (13 Oct) - its line in the log, a gun's standard
## magazine (30 Oct: a gun is never dead for want of one), and a gun's box of rounds while the Fence is shut.
func _land(m: Dictionary, it: Dictionary, said := "", to_floor := false) -> void:
	if said != "":
		log_event(said)
	if to_floor:
		m["floor"] = m.get("floor", [])
		m["floor"].append(it)
	else:
		_place_find(m, it)
	if Items.is_gun(it) and not it.get("with_mag", false):
		_mag_attach(it)                       # its magazine on it: wherever the gun goes (the fix round)
	# a gun found while the Fence is shut comes with a box of its own rounds (13 Oct, the ammo trap: rounds are sold
	# at the Fence only, and a gun with none is a club)
	if (it["slot"] == "Primary" or it["slot"] == "Secondary") and not room_open("fence") and not Items.free_rounds(it):
		var type: String = Items.ammo_type(it)
		var box: Dictionary = ammo_box(type) if not (type in ["", "none"]) else {}
		if not box.is_empty():
			if to_floor:
				m["floor"].append(_plain(Data.AMMO, str(box["name"])))
			else:
				_place_find(m, _plain(Data.AMMO, str(box["name"])))


## A find into the pack: joined to a stack it fits, a cell of its own if there's room. Full (15 Oct, Matt: a 6-pouch rig,
## an upgrade on his bum bag, swapped out for an epic school bag worse than the one he wore): by hand, to the floor -
## nothing's swapped without the player (27 Oct, the grid: in the fight too - it waits for the floor to show); on an
## auto-run or "Fill up, then go", only an upgrade on what's worn (or a
## paper, the endgame's keys) swaps in, for the cheapest thing at least its size that isn't one; else passed over.
func _place_find(m: Dictionary, it: Dictionary) -> void:
	if Items.stacks(it):
		for f in m["found"]:
			if Items.same_stack(f, it) and Items.stack_size(f) < Items.stack_cap(f):
				var moved: int = mini(Items.stack_cap(f) - Items.stack_size(f), Items.stack_size(it))
				Items.set_stack(f, Items.stack_size(f) + moved)
				Items.set_stack(it, Items.stack_size(it) - moved)
				if Items.stack_size(it) <= 0:
					return                    # joined what was found already: no new cell
	var spot := pack_spot(m, it)
	if not spot.is_empty():
		_pack_put(m, it, spot)
		_read(it)
		return
	if by_hand(m):
		m["floor"] = m.get("floor", [])
		m["floor"].append(it)                 # the player's to take, or leave: on screen once the search is on (27 Oct: never swapped for him, the fight included)
		return
	if not _pack_keeps(it):
		m["left"] += 1
		return
	# the cheapest thing that isn't kept and, taken out, leaves a place it fits (27 Oct, the grid: where it lies counts,
	# not its cells alone); PACK_SWAP_TRIES of the not-kept tried (22 Oct, the pass's wall: a full pack
	# of a hundred was tried on piece by piece for every find - the keep check is a try-on)
	if _drop_hauls_for(m, it):
		return                                # scrap and materials first, the least worth first: they rank below any gear (1 Nov, the review)
	var order: Array = []
	for k in range(m["found"].size()):
		var f: Dictionary = m["found"][k]
		if Items.opens(f) == "" and not f.get("from_rig", false) and not f.get("carried", false) and not Items.is_material(f):
			order.append(k)
	# what's at least its size first (its place alone may hold it), then the smaller (beside a gap they may), each cheapest first
	var need := Items.size(it)
	order.sort_custom(func(a, b):
		var fa: Dictionary = m["found"][a]
		var fb: Dictionary = m["found"][b]
		var ba: bool = Items.size(fa) >= need
		var bb: bool = Items.size(fb) >= need
		return fa["value"] < fb["value"] if ba == bb else ba)
	# the pack's verdicts, kept while what they read stands: the kit, the level, the feed, the wounds, HP under half
	# (the review: a gun runs dry, an upgrade goes on mid-run) - not the pack itself, which every find moves
	var keeps: Dictionary = m.get("keeps", {})
	var kk: int = hash([equipped, level(), _rig_grades(), _rounds_on_hand(), wounds.keys(), hp < max_hp() * 0.5])
	if int(keeps.get("key", 0)) != kk:
		keeps = {"key": kk}
		m["keeps"] = keeps
	var tries := 0
	for k in order:
		var f: Dictionary = m["found"][k]
		var fid: int = int(f["id"])
		if not keeps.has(fid):
			keeps[fid] = _pack_keeps(f)
		if keeps[fid]:
			continue
		tries += 1
		if tries > PACK_SWAP_TRIES:
			break
		if f.get("strapped", false):
			continue                          # strapped on, it holds no place to give
		var tk := _pack_taken(m, fid)
		var room := _pack_first(m, it, tk)
		if room.is_empty():
			continue
		m["found"][k] = it
		it["pos"] = [int(room[0]), int(room[1])]
		it["rot"] = bool(room[2])
		m["swapped"] = m.get("swapped", 0) + 1
		_read(it)
		return
	if it.get("mythic", false):
		it["strapped"] = true
		m["found"].append(it)                 # a mythic with no place to make (17 Oct): strapped on, as a head's uniques come home
		_read(it)
	else:
		m["left"] += 1


const PACK_SWAP_TRIES := 12


## A kept find (an upgrade, a paper, a mythic) that no one swap makes room for (1 Nov, materials in the pack: a pack of
## 1-cell stacks never frees a gun's row one at a time): the scrap and material stacks given up, the least worth first,
## till a place opens - and only those lying in that place go. False, nothing moved, when even all of them won't do.
func _drop_hauls_for(m: Dictionary, it: Dictionary) -> bool:
	var hauls: Array = m["found"].filter(func(f): return Items.is_material(f) and f.has("pos"))
	if hauls.is_empty():
		return false
	hauls.sort_custom(func(a, b): return int(a["value"]) < int(b["value"]))
	var tk0 := _pack_taken(m)
	var tk: Dictionary = tk0.duplicate()
	var room: Array = []
	for f in hauls:
		for c in tk0:
			if int(tk0[c]) == int(f["id"]):
				tk.erase(c)
		room = _pack_first(m, it, tk)
		if not room.is_empty():
			break
	if room.is_empty():
		return false
	var w := pack_w()
	var fp := pack_fp(it, bool(room[2]))
	var gone := {}
	for yy in range(fp.y):
		for xx in range(fp.x):
			var c: int = (int(room[1]) + yy) * w + int(room[0]) + xx
			if tk0.has(c):
				gone[int(tk0[c])] = true
	for f in m["found"].duplicate():
		if gone.has(int(f["id"])):
			m["found"].erase(f)
			m["left"] = int(m["left"]) + 1
	it["pos"] = [int(room[0]), int(room[1])]
	it["rot"] = bool(room[2])
	m["found"].append(it)
	m["swapped"] = m.get("swapped", 0) + 1
	_read(it)
	return true


## What a full pack holds on to on an auto-run (15 Oct): an upgrade on what's worn, a paper, the deeds - and a mythic
## (17 Oct, Matt: "never lost" meant it could still be passed over by a full pack, or swapped out of one).
func _pack_keeps(it: Dictionary) -> bool:
	return Items.is_paper(it) or it.get("mythic", false) or it.get("first_gun", false) or is_upgrade(it)


## A find's slot, from the site's own weights (a kill carries what was worn;
## a search finds what the site holds). Rig and pack come from searches more.
func _site_slot(site: Dictionary, from_kill: bool) -> String:
	var weights: Dictionary = site["drops"]["slots"]
	var total := 0.0
	var w := {}
	for slot in weights:
		var v := float(weights[slot])
		if from_kill and (slot == "Backpack" or slot == "Rig"):
			v *= 0.5
		w[slot] = v
		total += v
	var x := rng.randf() * total
	for slot in w:
		x -= w[slot]
		if x <= 0.0:
			return slot
	return "Primary"


## The pool is down: the clear bonus, the tier opened, the search begins.
func _clear(m: Dictionary, t: Dictionary) -> void:
	m["cleared"] = true
	if m.get("dry", false):
		return
	m["clear_t"] = float(m["elapsed"])         # the site's best time (2 Nov, BUILD46-S)
	_left_find(m)                              # a head's thing left here: found again (2 Nov, BUILD46-S)
	_wearing_off(m)
	var bonus: float = t["xp"] * t["pool"] * Data.CLEAR_BONUS * (Data.FX["node/stand"] if has_node("stand") else 1.0) * (Data.MYTHIC_PAY if has_rule("freedom") else 1.0)
	m["xp"] += bonus
	var before := level()
	_gain_xp(bonus)
	_earn_points(before)
	best_tier = maxi(best_tier, mini(Data.TIERS.size() - 1, m["tier"] + 1))
	var cd: int = int(depth[m["tier"]])     # the site's own depth: a signal's t["depth"] is its level's on the Barracks (D3), not this site's (D14 review)
	var first_clear: bool = not seen.has("cleared/%d" % m["tier"])
	if m.has("signal") and m["signal"].has("order"):
		cd = 0                                # the order's run (18 Oct): no depth, no best signal, no Yard column; the reach is the signals'
	if bool(m.get("head_fight", false)):
		cd = 0                                # (BUILD55-A) the head's own fight clears no stage
	if first_clear or cd > best_depth[m["tier"]]:
		chron("clear", {"tier": int(m["tier"]), "site": str(tier(m["tier"])["name"]), "depth": int(cd), "first": first_clear,
			"site_level": int(t.get("level", 0)), "dps": snappedf(dps(), 0.1), "kit": loadout_value()})
	if cd > best_depth[m["tier"]]:
		best_depth[m["tier"]] = cd
		if cd >= Data.SIGNAL_DEPTH and int(m["tier"]) >= Data.OUTSKIRTS_SITES and not m.has("signal"):     # (BUILD55-A) no Map point from a stage     # the map's points from the Streets on (12 Oct); a signal's are its reach's (15 Oct)
			atlas_points += 1
	if cd >= Data.SIGNAL_DEPTH and int(m["tier"]) >= Data.OUTSKIRTS_SITES and (cd > int(best_dig.get("depth", 0)) or (cd == int(best_dig.get("depth", 0)) and m["tier"] > int(best_dig.get("tier", -1)))):
		best_dig = {"site": t["name"], "tier": m["tier"], "depth": cd}     # the ladder's, not the campaign's
	if m["tier"] == Data.OUTSKIRTS_SITES + 2 and not depot_cleared:     # the Retail Park: the slice's win (index 5 since the Outskirts)
		depot_cleared = true
	if not seen.has("cleared/%d" % m["tier"]):
		seen["cleared/%d" % m["tier"]] = true
		if not clear_level.has(int(m["tier"])):
			clear_level[int(m["tier"])] = level()     # the level the site was first cleared at: its fight hardens from here (21 Oct)
			if has_node("word_of_mouth"):
				m["notes"] = int(m.get("notes", 0)) + 1     # Word of mouth: a note on each site's first clear
		log_event(Words.LOG["cleared"] % t["name"])     # (BUILD55-A) the site's own "cleared" line waits for its first 2/3 (_a55_stage_clear)
	else:
		log_event(Words.LOG["cleared"] % t["name"])
	_a55_stage_clear(m, t)
	if int(m["tier"]) == Data.FIRST_GUN_SITE and not seen.has("first_gun_home") and owned_ammo_types(m).is_empty():
		_first_gun(m)                         # until one's home (the review: a first clear's gun lost to a time-out would never come again)
	# the deeds come off the Manager now, not the Bank's first clear (13 Oct, Matt): see the boss's things
	if not m.has("crates"):
		_roll_crates(m, t)                    # the search: the site's crates, in the dice's order (13 Oct); a Ghost's rolled at its first search


## The searches a cleared site's crates add up to (29; the crates since 13 Oct): by depth, and quantity pushes it.
func thin_after(t: Dictionary) -> int:
	var n: float = Data.THIN_AFTER + Data.THIN_PER_DEPTH * int(t["depth"])
	return int(roundf(n))     # loot quantity is more a search, not more searches too (Matt, 26 Oct: the third review's A9, counted twice)


## The lookout's top level (31): the first gang after the clear waits for the call, and the call is a full pack.
func gang_held(m: Dictionary) -> bool:
	if m["patrols"] == 0 and yard_has("early_warning") and int(m.get("crate_i", 0)) < 1 and not m.get("dry", false) and not crates_done(m):
		return true                           # the Lookout's Early warning (21 Oct, in the whistle's place): not before the first crate's searched
	return m["patrols"] == 0 and yard_has("hold_fire") and pack_used(m) < capacity() and not m.get("dry", false) and not crates_done(m)     # picked clean: nothing left to wait for (13 Oct)


# ------------------------------------------------------------------ the crates (13 Oct, docs/design/search_crates.md)

## A crate's line in Data.CRATES by its key; {} for none.
static func crate_def(key: String) -> Dictionary:
	for c in Data.CRATES:
		if c["key"] == key:
			return c
	return {}


## The Kennel's top rank (Matt, 13 Oct): the dog noses what's in a crate before it's opened.
func dog_sniffs() -> bool:
	return yard_has("pack") or yard_has("champion")


## A site's crates' weights: the crate's own, the site's leaning (its shape, its own crates), the depth.
func crate_weights(t: Dictionary) -> Dictionary:
	var site: Dictionary = Data.TIERS[int(t["tier"])]
	var shape: Dictionary = site["shape"]
	var own: Dictionary = Data.CRATE_SITES.get(str(site["name"]), {})
	var coded: Dictionary = t.get("crates", {})          # the site's codes (13 Oct): more of a kind, and a kind it wouldn't have yet
	var out := {}
	for c in Data.CRATES:
		if int(site["zone"]) < int(c.get("from_zone", 0)) and not coded.has(c["key"]):
			continue
		var w: float = float(c["w"]) * (float(shape.get(c["shape"], 1.0)) if c.has("shape") else 1.0) + float(c.get("depth_w", 0.0)) * maxi(0, int(t["depth"]) - 1)
		out[c["key"]] = w * float(own.get(c["key"], 1.0)) * float(coded.get(c["key"], 1.0))
	return out


## The crates rolled at the clear: the dice's order, their searches adding up to thin_after. With the dog's nose,
## each crate's first find is rolled now and shown on it shut.
func _roll_crates(m: Dictionary, t: Dictionary) -> void:
	var w: Dictionary = crate_weights(t)
	var total_w := 0.0
	for k in w:
		total_w += float(w[k])
	var queue: Array = []
	var total := 0
	var target: int = maxi(1, thin_after(t))
	if str(m.get("night_special", "")) == "stash":
		target = int(ceil(target * Data.NIGHT_STASH_CRATES))     # a night's fifth: a room of crates (BUILD50 N)
	while total < target:
		var x: float = rng.randf() * total_w
		var key: String = str(w.keys()[0])
		for k in w:
			x -= float(w[k])
			if x <= 0.0:
				key = str(k)
				break
		var c: Dictionary = crate_def(key)
		var locked: bool = c.get("locks", false) and rng.randf() < Data.CRATE_LOCK
		queue.append({"key": key, "name": c["name"], "searches": int(c["searches"]), "done": 0, "finds": [], "locked": locked})
		if not locked:
			total += int(c["searches"])       # a locked one is over and above the site's searches: the Keys' to open
	m["crates"] = queue
	m["crates_n"] = queue.size()
	m["crate_i"] = 0
	if _site_resume(m, queue):
		queue = m["crates"]                   # what the site kept, then what's come back (27 Oct)
	if dog_sniffs():
		for q in queue:
			if q.has("held") or int(q["done"]) > 0:
				continue                      # nosed on an earlier run, or already open
			var held: Dictionary = _find(m, t, false, crate_for(q), true)
			if not held.is_empty():
				q["held"] = held
	_pass_locked(m)


## A crate in the queue as the finds read it: its line in Data.CRATES, a locked one's quality up.
static func crate_for(q: Dictionary) -> Dictionary:
	var c: Dictionary = crate_def(str(q["key"]))
	if q.get("locked", false):
		c = c.duplicate()
		c["rarity"] = float(c.get("rarity", 0.0)) + Data.CRATE_LOCK_RARITY
	return c


## Whether a run opens locked crates: the Caretaker's Keys.
func has_keys() -> bool:
	return has_rule("caretakers_keys") or has_rule("freedom") or has_set_rule("council")     # the Freedom of the Borough, the Council's 4-piece (18 Oct: its clause was never wired): every crate opens


## Locked crates in hand without the Keys are passed over, marked so.
func _pass_locked(m: Dictionary) -> void:
	if has_keys():
		return
	var cs: Array = m.get("crates", [])
	while int(m.get("crate_i", 0)) < cs.size() and cs[int(m["crate_i"])].get("locked", false):
		cs[int(m["crate_i"])]["passed"] = true
		m["crate_i"] = int(m["crate_i"]) + 1


## The crate being opened; {} once they're all open (or before the clear).
func crate_now(m: Dictionary) -> Dictionary:
	var cs: Array = m.get("crates", [])
	var i: int = int(m.get("crate_i", 0))
	return cs[i] if i < cs.size() else {}


## Every crate open: the site's picked over, nothing more to find.
## Picked clean with nothing more before time's up (Matt, 26 Oct; the first review's 2(a)): every crate open, quiet,
## and the next gang due after the clock runs out (or none comes at all). The runner comes home on their own.
func nothing_left(m: Dictionary) -> bool:
	if m == null or m.get("dry", false) or not m["cleared"] or m["remaining"] > 0 or m.get("way_out", false) or has_rule("bomb_suit") or not crates_done(m):
		return false
	if not can_extract():
		return false
	var next: float = INF if has_rule("freedom") else patrol_s(m["t"], m["patrols"] == 0) - float(m["patrol_timer"])
	return next * Data.CLOCK_SEARCH_RATE > maxf(0.0, float(m.get("clock", 0.0)))


func crates_done(m: Dictionary) -> bool:
	return m.has("crates") and crate_now(m).is_empty() and not m.get("crates_off", false)


## Nothing alive on the site: the crate being opened gives a search every search_s, its finds as before (finds by
## quantity, the dogs, the Scavenger), leaning to its kind. `crates_off` (the balance read): no crates, no end.
func _search(m: Dictionary, t: Dictionary, dt: float) -> void:
	var off: bool = m.get("crates_off", false)
	if not off and not m.has("crates"):
		_roll_crates(m, t)                    # a run that started searching (Ghost), or a save from before the crates
	var cr: Dictionary = {} if off else crate_now(m)
	if not off and cr.is_empty():
		m["search"] = 0.0
		return                                # picked over: every crate open
	m["search"] += dt
	var every := search_s(t)
	if has_node("clocking_off") and int(m["searches"]) == 0 and not m.get("clocked_off", false):
		m["clocked_off"] = true
		m["search"] = every                   # Clocking off: the first search after a clear is instant
	while m["search"] >= every:
		m["search"] -= every
		m["searches"] += 1
		var cd: Dictionary = {} if cr.is_empty() else crate_for(cr)
		if has_node("twine"):
			m["twine"] = true                 # Twine: the next gang arrives one fewer
		if has_node("spare_change") and rng.randf() < 0.2:
			m["notes"] = int(m.get("notes", 0)) + 1     # Spare change: a note one search in five
		if has_node("sheet_metal"):
			_guard_add(m, max_hp() * 0.06)       # Sheet metal: every cache searched
		if rng.randf() < Data.NOTES_SEARCH * float(cd.get("notes", 1.0)):
			m["notes"] = int(m.get("notes", 0)) + rng.randi_range(1, 2)
		if rng.randf() < Data.SCRAP_SEARCH * float(cd.get("scrap", 1.0)):
			_haul_find(m, "scrap", rng.randi_range(Data.SCRAP_HANDFUL[0], Data.SCRAP_HANDFUL[1]))     # a handful of scrap (34), a pack item (1 Nov)
		if cd.get("tins", false):
			m["cash"] += float(t["cash"]) * rng.randf_range(0.5, 2.0) * inflation()     # a safe: a handful of tins (the pass, 13 Oct: 1-3 read the Bank 17% over)
		var finds: int = 1 + (1 if (has_node("scavenger") or has_node("quiet_hands")) else 0) + (Data.FX["yard/a_dog"] if yard_has("a_dog") else 0) + (Data.FX["yard/pack"] if yard_has("pack") else 0) + (Data.FX["rule/postman"] if has_rule("postman") else 0) + (Data.MYTHIC_SEARCH_FINDS if has_rule("removal_van") else 0)
		if atlas_rank("second_look") >= 2 or (atlas_rank("second_look") == 1 and int(m["searches"]) % 2 == 0):
			finds += 1                        # Second look: one more every other search, then every search
		if str(m.get("night_special", "")) == "stash":
			finds *= Data.NIGHT_STASH_FINDS     # a night's stash: two finds a search (BUILD50 N)
		# quantity reaches searches: +25% is a fourth find one search in four, carried as a fraction (27)
		m["extra"] = float(m.get("extra", 0.0)) + maxf(0.0, loot_bonus())
		while m["extra"] >= 1.0:
			m["extra"] -= 1.0
			finds += 1
		for k in range(finds):
			var got: Dictionary
			if k == 0 and not cr.is_empty() and int(cr["done"]) == 0 and cr.has("held"):
				got = {"it": cr["held"]["it"].duplicate(true)}     # what the dog nosed: the crate's first find, as found
				m["finds"] = int(m.get("finds", 0)) + 1
				_land(m, cr["held"]["it"], str(cr["held"].get("said", "")), by_hand(m))
			else:
				got = _find(m, t, false, cd)
			if not cr.is_empty() and not got.is_empty():
				cr["finds"].append(got["it"])
		if cr.is_empty():
			continue
		cr["done"] = int(cr["done"]) + 1
		if int(cr["done"]) >= int(cr["searches"]):
			m["crate_i"] = int(m.get("crate_i", 0)) + 1
			_pass_locked(m)
			cr = crate_now(m)
			if cr.is_empty():
				m["search"] = 0.0
				log_event(Words.LOG["picked_clean"] % t["name"])
				return


## Drop something from the pack mid-run to make room: the cheapest thing, or
## every common. What's dropped is gone.
func cheapest_in_pack() -> Dictionary:
	if mission == null or mission["found"].is_empty():
		return {}
	var pick: Dictionary = {}
	for it in mission["found"]:
		if it.get("carried", false):
			continue                              # the gate's box isn't a find to drop
		if pick.is_empty() or it["value"] < pick["value"]:
			pick = it
	return pick


func ditch(id: int) -> bool:
	if mission == null:
		return false
	for k in range(mission["found"].size()):
		if mission["found"][k]["id"] == id:
			var it: Dictionary = mission["found"][k]
			if it.get("carried", false):
				return false                      # the gate's box: the stash's rounds, never ditched (the second review)
			mission["found"].remove_at(k)
			mission["ditched"] = int(mission.get("ditched", 0)) + 1
			# down on the floor, no scrap (27 Oct, Matt: "scrapping should only be available in the workshop now - ditch
			# should instead just ditch the item on the floor and if you leave it you leave it"); Fill up leaves it there
			pack_off(it)
			it["ditched"] = true
			mission["floor"] = mission.get("floor", [])
			mission["floor"].append(it)
			log_event(Words.LOG["ditched"] % it["base"].to_lower())
			return true
	return false


# ------------------------------------------------------------------ the floor (13 Oct, Matt)

## A search's finds by hand: on the floor, for the player to take - not on "Fill up, then go",
## a dry run, or for the bot.
func by_hand(m: Dictionary) -> bool:
	return loot_by_hand and not m.get("leave_full", false) and not m.get("dry", false)


func floor_items() -> Array:
	return mission.get("floor", []) if mission != null else []


## Whether a thing on the floor goes in the pack: a place it lies (either way round), or a stack it joins.
func floor_fits(it: Dictionary) -> bool:
	if mission == null:
		return false
	if Items.stacks(it):
		for f in mission["found"]:
			if Items.same_stack(f, it) and Items.stack_size(f) < Items.stack_cap(f):
				return true
	return not pack_spot(mission, it).is_empty()


## Off the floor into the pack: only if it fits (no swapping - the player chose it); a stack joins what it can, the rest
## stays down. `at` [x, y, rot] is where the player dropped it (the grid, 27 Oct); empty, the first place it lies.
## A thing ditched comes back with its scrap.
func take_floor(id: int, at: Array = []) -> bool:
	if mission == null:
		return false
	var fl: Array = floor_items()
	for k in range(fl.size()):
		if int(fl[k]["id"]) != id:
			continue
		var it: Dictionary = fl[k]
		var joined := false
		if Items.stacks(it):
			for f in mission["found"]:
				if Items.same_stack(f, it) and Items.stack_size(f) < Items.stack_cap(f):
					var moved: int = mini(Items.stack_cap(f) - Items.stack_size(f), Items.stack_size(it))
					Items.set_stack(f, Items.stack_size(f) + moved)
					Items.set_stack(it, Items.stack_size(it) - moved)
					joined = joined or moved > 0
			if Items.stack_size(it) <= 0:
				fl.remove_at(k)
				return true
		var spot: Array = []
		if at.is_empty():
			spot = pack_spot(mission, it)
		else:
			_pack_settle(mission)
			if pack_free_at(mission, it, int(at[0]), int(at[1]), bool(at[2])):
				spot = [int(at[0]), int(at[1]), bool(at[2])]
		if spot.is_empty():
			return joined                      # no place: it stays down (what of a stack could join, did)
		fl.remove_at(k)
		it.erase("ditched")                   # taken back: the player's again
		it["spared"] = true                   # taken off the floor by hand: chosen, so no rule scraps it
		_pack_put(mission, it, spot)
		_read(it)
		return true
	return false


## Everything on the floor that fits, the dearest first: "Fill up, then go" picks up what was left down.
func take_all() -> int:
	var n := 0
	var fl: Array = floor_items().filter(func(x): return not x.get("ditched", false))     # what the player put down stays down
	fl.sort_custom(func(a, b): return int(a["value"]) > int(b["value"]))
	for it in fl:
		if take_floor(int(it["id"])):
			n += 1
	return n


## Leave now with what's been found. Pressed by hand, it also ends an auto-run:
## a manual extract is the player taking the wheel back.
## Whether the runner can leave now: Stand and fight holds them until the clear.
func can_extract() -> bool:
	return mission != null and (mission["cleared"] or not has_node("stand"))


func extract_now() -> void:
	if mission != null and can_extract():
		_extract()


## The player's Get out now (10 Oct, docs/design/way_out.md): free and at once after the clear, as before; before
## it, the way out - a last gang at the door and so long to see them off. extract_now stays the instant leave the
## tools and the tests use.
func get_out() -> void:
	if mission == null or not can_extract():
		return
	if (mission["cleared"] and not mission.get("ghost_pending", false)) or mission.get("dry", false):
		extract_now()                          # a Ghost's run is cleared from the start; its clear is the first gang beaten
		return
	if mission.get("way_out", false):
		return                                 # already making for it
	_start_way_out(mission)


## How long the way out gives at a site: WAY_OUT_S, so much more a site along, never more than the run's clock has left.
func way_out_s(t: Dictionary, m = null) -> float:
	var s: float = Data.WAY_OUT_S + Data.WAY_OUT_PER_TIER * maxi(0, int(t["tier"]) - Data.OUTSKIRTS_SITES)     # from the Streets, as before the Outskirts (12 Oct)
	if m != null:
		s = minf(s, maxf(1.0, float(m.get("clock", s))))
	return s


## The gang at the door: the site's own (its words on it), the size of the gangs after a clear's first - the Flares,
## Trapline and the Poacher's snare shrink it as they shrink those.
func door_gang(_t: Dictionary) -> int:
	var size: int = maxi(1, PATROL_BASE - (Data.FX["node/trapline.heads"] if has_node("trapline") or has_node("snare_and_wait") else 0) + (Data.FX["node/loud.gang"] if has_node("loud") else 0) - (Data.FX["rule/wardens_hat.gang"] if has_rule("wardens_hat") else 0))
	if has_rule("scouts_whistle"):
		size = 1
	if yard_has("flares"):
		size = maxi(1, size - Data.FX["yard/flares.heads"])
	if has_joint("poacher_frost"):
		size = maxi(1, size - Data.FX["joint/poacher_frost.heads"])
	return size


func _start_way_out(m: Dictionary) -> void:
	var t: Dictionary = m["t"]
	var size := door_gang(t)
	m["way_out"] = true
	m["way_out_t"] = way_out_s(t, m)
	m["way_out_max"] = m["way_out_t"]
	m["way_out_gang"] = size
	m["left_behind"] = int(m["remaining"])
	if m.has("boss") and m["boss"]["alive"]:
		m["boss"]["started"] = false           # the head is left with the rest of them
	m["remaining"] = size
	m["target_hp"] = float(t["hp"])
	m["dots"] = {}
	m["chill_t"] = Data.FX["joint/poacher_frost.chill_s"] if has_joint("poacher_frost") else 0.0
	m["shock_t"] = 0.0
	m["fresh"] = true
	m.erase("opened")
	m["sustain_t"] = 0.0
	_gang_arrives(m)
	log_event(Words.LOG["way_out"] % size)


## The door's gang down: out with the pack.
func _seen_off(m: Dictionary) -> void:
	m["seen_off"] = true
	log_event(Words.LOG["seen_off"])
	_extract()


func _extract() -> void:
	if mission != null and mission.get("dry", false):
		return
	if mission != null and mission.has("night") and _night_link_end(mission):
		return                                # a night's link done: the break, or the night home from there (BUILD50 N)
	var m: Dictionary = mission
	_event_end(m)                         # the dogs off the record, his run-only goods back (the fix round)
	var rep_pre: Dictionary = {"scrap": scrap, "mats": _materials_total()} if m.get("unwatched", false) else {}     # a repeat run's line (29 Oct)
	_site_remember(m)                     # the crates left for next time (27 Oct)
	_bailiff_keeps_deeds(m)
	_floor_mythics_in(m)
	_pack_unmark(m)
	var t := tier(m["tier"])
	var timed_out: bool = m.get("timed_out", false)
	if m.get("ghost_pending", false) and (pack_used(m) >= capacity() or (crates_done(m) and not m.get("crates_none", false))) and not timed_out:     # a site left picked clean by an earlier run is no Ghost's clear (the review)     # a site picked clean is a Ghost's clear too (13 Oct)     # out of time is no clear, kept pack or not
		m["ghost_pending"] = false
		_clear(m, m["t"])                     # Ghost: a full pack brought home is the clear (the site as deployed to, its depth with it)
		log_event(Words.LOG["ghost"] % Words.mid(t["name"]))
	m["left"] = int(m["left"]) + m.get("floor", []).size()     # what was left on the floor: passed over
	if m.get("floor", []).any(func(x): return Items.is_deeds(x)) and deeds_fate == "":
		deeds_fate = "burned"                 # ditched and left: gone, as a ditch burned them before (27 Oct)
		log_event(Words.DEEDS["burned"])
	m["cash"] += _affix_sum("cash_per_cell") * pack_used(m) * inflation()
	if has_node("cap_the_lot") and pack_used(m) >= capacity() and not timed_out:
		m["cash"] *= Data.FX["node/cap_the_lot"]                      # The lot: a full pack pays double
	if has_rule("issuers_robes"):
		m["cash"] *= 1.0 + town_worth() / 100.0                      # the Issuer's Robes: +1% a point of the town's worth
	m["cash"] *= paragon_mult("tins")                                # the paragon board's tins
	if mint_pays(m):
		m["cash"] += mint_tins()                                     # the mint (18 Oct): the town's worth pays on a run home - a clear's only (31 Oct)
	_earn(float(m["cash"]))
	_night_home_done(m)                       # a night's XP home with its haul (BUILD50 N)
	var run_notes: int = int(m.get("notes", 0))
	if has_rule("lorrys_load"):
		run_notes += maxi(0, capacity_raw() - pack_used(m)) * int(m["t"]["depth"])     # every empty cell is notes
	if has_rule("managers_pen"):
		run_notes *= Data.FX["rule/managers_pen"]
	if has_rule("drivers_log"):
		run_notes *= Data.FX["rule/drivers_log"]
	if float(m.get("wager_notes", 1.0)) != 1.0:
		var before_w: int = run_notes
		var held_w: int = mini(run_notes, int(m.get("notes_link0", 0)))     # a night's earlier links' notes: not the wager's (fix 50)
		run_notes = held_w + int(round((run_notes - held_w) * float(m["wager_notes"])))     # Kev's wager paid (29 Oct)
		log_event(Words.WAGERS["paid_notes"] % [run_notes - before_w, "" if run_notes - before_w == 1 else "s"])
	notes += run_notes                        # before the takings: after the Issue the notes are this run's income (the review)
	var base0: float = a_gamble_base()
	gamble_base = clampf(lerp(base0, _takings_run, 0.25), base0 * (1.0 - Data.GAMBLE_STEP), base0 * (1.0 + Data.GAMBLE_STEP))     # before takings moves: the first run starts from its stand-in
	takings = _takings_run if takings <= 0.0 else lerp(takings, _takings_run, 0.25)     # a run's takings: this run's cash and the Fence's money since the last
	_takings_run = 0.0
	_haul_home(m, true)                   # the pack's scrap and materials into the Pitch's counts (1 Nov): after the Lorry's Load's cells (they're filled), before the gate's sorts
	var sv: Dictionary = m.get("salvage", {})
	for kind in sv:
		salvage[kind] = int(salvage.get(kind, 0)) + int(sv[kind])      # and its salvage (9 Oct)
	if m.get("unwatched", false):
		m["found_pre"] = m["found"].duplicate()     # the record's gear finds, before the gate's sort
	m["found"] = apply_loot_rules(m["found"])    # the loot filter (24 Oct): keep, highlight or scrap as it comes in - first, so a kept common skips the Bins
	if yard_has("bins"):
		m["found"] = _bin_commons(m["found"])     # the Stash's Bins: the run's commons to scrap before they're stashed
	if m.get("unwatched", false):
		m["found"] = _repeat_sort(m)          # a repeat run's pack sorted at the gate (29 Oct), after the rules and the Bins: its kept chips are what goes in
	var stashed := 0
	var own_home := 0                         # the runner's own kit home (the gate's box, the rig's own): neither loot nor left
	for it in m["found"]:
		var first: bool = it.get("first_gun", false) and (Items.is_gun(it) or Items.is_mag(it))     # and its magazine (30 Oct)
		it.erase("first_gun")
		it.erase("spared")
		if first:
			stash.append(it)                  # the first gun comes home whatever the room, as a mythic does, and it's home: no more (17 Oct)
			if Items.is_gun(it):
				seen["first_gun_home"] = true
			stashed += 1
			continue
		if it.get("carried", false):
			it.erase("carried")
			own_home += 1                     # the runner's own: neither loot nor left (the second review)
			m["own_ids"] = m.get("own_ids", []) + [int(it["id"])]
			if not stash_put(it):
				log_event(Words.LOG["left_at_gate"] % str(it["base"]).to_lower())
			continue                          # the gate's box for the refills (30 Oct): what's left comes home, never loot
		if it.get("from_rig", false):
			# the runner's own rounds, moved to the pack on the run: back to the rig when there's a pouch, else the
			# stash, never loot (the review: a full stash dropped them without a word)
			it.erase("from_rig")
			own_home += 1
			m["own_ids"] = m.get("own_ids", []) + [int(it["id"])]
			if rig_room(Items.size(it)):
				rig.append(it)
			elif not stash_put(it):
				log_event(Words.LOG["left_at_gate"] % str(it["base"]).to_lower())
			continue
		if is_pile_paper(it):
			papers.append(it)                # the Radio's pile, whatever the room (18 Oct, Matt): never the stash
			stashed += 1
			continue
		_left_home(it)                       # its room whole again (2 Nov, BUILD46-S)
		if _home_gate(it):
			stashed += 1                     # home, as a keepsake: not left behind (the review)
			continue                         # a head's thing: its room opens, and it stays there (13 Oct)
		if Items.is_deeds(it):
			stash.append(it)                 # whatever the room: the deeds come home
			stashed += 1
			if deeds_fate == "":
				deeds_fate = "held"
				log_event(Words.DEEDS["held"])
		elif stash_put(it):
			stashed += 1
		elif it.get("mythic", false) or it.get("issued", false):
			stash.append(it)                 # a mythic comes home whatever the room, as the deeds do (17 Oct); a head's issued piece too (the third review)
			stashed += 1
		elif m.get("unwatched", false):
			stash.append(it)                 # a repeat's keeps never lost to a full stash (the review): home, and the repeat ends
			m["rep_overflow"] = true
			stashed += 1
		else:
			continue
		if not (Items.rig_item(it) or Items.is_ammo(it)) and not m.get("unwatched", false):
			_came_back_find(it)              # the card's dearest find (rounds and meds aren't finds)
	var outcome := "Back"
	if m.get("timed_out", false):
		outcome = "Out of time"
	elif not m["cleared"]:
		outcome = "Cut and run"
	elif m["patrols"] > 0:
		outcome = "Back, chased"
	last_report = {
		"outcome": outcome, "tier": m["tier"], "kills": m["kills"], "of": int(t["pool"]), "loot": stashed,
		"left": m["left"] + (m["found"].size() - stashed - own_home), "cash": m["cash"], "xp": m["xp"],
		"hp_lost": m["hp_start"] - hp, "time": m["elapsed"], "searches": m["searches"], "patrols": m["patrols"], "wounded": bool(m.get("wounded", false)), "scrap": int(m.get("scrap", 0)), "salvage": sv.duplicate(),
		"clock_used": float(m.get("clock_used", 0.0)), "clock_left": float(m.get("clock", 0.0)), "timed_out": bool(m.get("timed_out", false)), "way_out": bool(m.get("way_out", false)),
		"fight": fight_breakdown(m),
		"event": str(m["ev"].get("fam", "")) if m.has("ev") else "", "event_out": str(m["ev"].get("outcome", m["ev"].get("state", ""))) if m.has("ev") else "",
	}
	log_event(Words.LOG["home"] % [outcome, Words.mid(t["name"]), m["kills"], "" if int(m["kills"]) == 1 else "s", stashed, "" if int(stashed) == 1 else "s",
			_cash_words(m["cash"])])
	_radio_after_run()
	_chron_run(m, outcome, {"loot": stashed, "left": int(last_report["left"]), "cash": int(m["cash"]), "xp": int(m["xp"]),
		"notes": run_notes, "scrap": int(m.get("scrap", 0)), "salvage": sv.duplicate(), "hp_lost": int(m["hp_start"] - hp),
		"wounded": bool(m.get("wounded", false)), "timed_out": bool(m.get("timed_out", false)), "way_out": bool(m.get("way_out", false)),
		"clock_used": snappedf(float(m.get("clock_used", 0.0)), 0.1), "searches": int(m["searches"]), "patrols": int(m["patrols"]),
		"cleared": bool(m["cleared"]), "pack": pack_used(m), "cap": capacity()})
	_record_run(m)
	_signal_done(m)
	_sweep_papers()
	mission = null
	_idle_tidy()
	_say_next()
	exchange_day += 1                         # a run home: the exchange's new day of rates (28 Oct, Matt's play-day)
	town_pay_day()                            # and the town's wages (BUILD50-T)
	restock()
	_top_up()                                 # home, the rig loaded again: the card's odds read the rig that goes out (the review)
	if not rep_pre.is_empty():
		_repeat_run_done(m, rep_pre)          # the repeat's next, or its end (29 Oct)
	if m.has("exp_fetch"):
		_exp_fetched(m)                       # a hold-up fetched (29 Oct): the holder down, the crew home


## The runner's record, from a run that came back (8 Oct).
func _record_run(m: Dictionary) -> void:
	record["runs"] = int(record.get("runs", 0)) + 1
	record["kills"] = maxi(int(record.get("kills", 0)), int(m["kills"]))
	record["dealt"] = maxf(float(record.get("dealt", 0.0)), float(m.get("dealt", 0.0)))
	record["cash"] = maxf(float(record.get("cash", 0.0)), float(m["cash"]))
	for it in m["found"]:
		if int(it["id"]) in m.get("own_ids", []):
			continue                              # the runner's own (the gate's box, the rig's): not a find
		if int(it.get("value", 0)) > int(record.get("find_value", 0)):
			record["find_value"] = int(it["value"])
			record["find"] = Items.full_name(it)
			record["find_item"] = it.duplicate(true)     # its picture and rarity on Stats' record (BUILD49 U, item 12)


## A run's end in the playtest record: where, how deep, how it ended, what the runner was, and the run's own figures.
func _chron_run(m: Dictionary, outcome: String, extra: Dictionary) -> void:
	if _dry_on:
		return                                    # chron would drop it: the odds' runs skip the reading too
	_site_run_note(m, outcome, extra)             # the Map card's "You here" (2 Nov, BUILD46-S)
	var et: Dictionary = m.get("t", tier(m["tier"]))
	var b = m.get("boss", null)
	var d := {"tier": int(m["tier"]), "site": str(tier(m["tier"])["name"]), "depth": int(et.get("depth", 1)), "site_level": int(et.get("level", 0)),
		"outcome": outcome, "time": snappedf(float(m["elapsed"]), 0.1), "kills": int(m["kills"]), "of": int(et.get("pool", 0)),
		"hp_max": int(max_hp()), "dps": snappedf(dps(), 0.1), "mit": snappedf(mitigation(), 0.001),
		"kit": loadout_value(), "wound_in": ",".join(wounds.keys()),
		# what the player saw and set off against (12 Oct, Matt: "how the bot plays isn't how a person plays"): the
		# odds the Runs card read at the gate (-1 unread), the site's own fire and HP, and the kit's regen
		"odds": snappedf(float(m.get("odds_seen", -1.0)), 0.01), "their_hp": int(et.get("hp", 0)), "their_dps": snappedf(float(et.get("dps", 0.0)), 0.1),
		"regen": snappedf(regen_rate(), 0.1)}
	if b != null and b is Dictionary and not b.is_empty():
		d["boss"] = str(b.get("name", ""))
		d["boss_down"] = not bool(b.get("alive", true))
	if m.get("convoy", false):
		d["convoy"] = true
	if m.has("ev"):
		d["event"] = str(m["ev"].get("fam", ""))     # the run's event and what came of it (the fix round, T7): the summaries' row
		d["event_out"] = str(m["ev"].get("outcome", "")) if str(m["ev"].get("state", "")) == "done" else str(m["ev"].get("state", ""))
	# the dots and the drops (17 Oct, for the balance after Matt's playtest): what the run dealt and how much of it the
	# dots' ticks, the one figure and its dot part, the +% dots worn and trained; and its gear finds against what the
	# runner can wear - the dot change and the fifth at yours, read from a person's play
	var ticked := 0.0
	var by := {}
	for ty in m.get("ticked_by", {}):
		ticked += float(m["ticked_by"][ty])
		by[ty] = roundi(float(m["ticked_by"][ty]))
	var split: Array = m.get("split_gate", [0.0, 0.0])
	d["dealt"] = snappedf(float(m.get("dealt", 0.0)), 1.0)     # a float: a broken build's run is past an int's top (21 Oct)
	d["ticked"] = snappedf(ticked, 1.0)
	d["ticked_by"] = by
	d["split_total"] = snappedf(float(split[0]), 0.1)
	d["split_dot"] = snappedf(float(split[1]), 0.1)
	d["dot_gear"] = snappedf(_affix_sum("dot_pct"), 0.1)
	d["dot_tree"] = snappedf(tree_sum("dot_pct"), 0.1)
	d["signal"] = m.has("signal")
	if m.has("signal") and m["signal"].has("order"):
		d["order"] = str(m["signal"]["order"])     # the order's runs apart from the signals' (18 Oct)
	var gear := 0
	var wearable := 0
	var at_mine := 0
	var mine: int = int(m.get("wear_gate", wearable_level()))     # as it was at the gate: a level-up mid-run would miss the finds rolled before it (the review)
	for it in m.get("found_pre", m.get("found", [])):
		if str(it.get("slot", "")) in Data.SLOTS and not it.get("mythic", false):
			gear += 1
			wearable += 1 if Items.wear_level(it) <= level() else 0
			at_mine += 1 if Items.ilvl(it) == mine and int(et.get("level", 0)) > mine else 0
	d["gear"] = gear
	d["gear_wearable"] = wearable
	d["gear_at_mine"] = at_mine
	if m.get("unwatched", false):
		d["unwatched"] = true                     # a repeat's run (29 Oct): the readers count it apart from play
		d["xp_shared"] = snappedf(float(m.get("xp_got", 0.0)), 0.01)
	d.merge(extra, true)
	chron("run", d)


func _record_reset() -> void:
	record = {"since": elapsed, "kills": 0, "dealt": 0.0, "cash": 0.0, "find": "", "find_value": 0, "runs": 0, "deaths_seen": operators_lost}


## KIA: the loadout and what was found are gone; the stash and cash stay. A
## fresh runner takes over: at level 1 before the Quartermaster, at the dead one's level past him, at 50 past the cap
## with the paragon levels kept (31 Oct; 1 Nov): only the XP towards the next level or paragon level goes. Auto-run stops.
## A mythic left on the floor at a run's end (17 Oct: a full pack by hand, or "No room: make some" never made) comes
## home as one in the pack does: into the pack first, over its size if need be, so each ending's own rule takes it.
func _floor_mythics_in(m: Dictionary) -> void:
	var fl: Array = m.get("floor", [])
	for it in fl.filter(func(x): return x.get("mythic", false) or x.get("issued", false) or (x.get("head_drop", false) and not x.get("ditched", false))):
		fl.erase(it)                          # a head's drop left down too, unless ditched (1 Nov, the review: it came home before)
		it.erase("ditched")
		it.erase("head_drop")
		m["found"].append(it)


func _kia() -> void:
	var m: Dictionary = mission
	if m.get("dry", false):
		m["dead"] = true                     # a dry run: the answer, nothing lost
		return
	if m.get("unwatched", false):
		_bail(m)                             # never a death unwatched (29 Oct, Matt's call 1): a bail
		return
	_event_end(m)
	_site_remember(m)                     # the crates left for next time (27 Oct)
	_bailiff_keeps_deeds(m)
	_floor_mythics_in(m)
	_pack_unmark(m)
	var t := tier(m["tier"])
	var dogs_share: bool = has_node("cap_dogs_share") and not m.get("insured", false) and not rig.is_empty()
	var lost := loadout_value()
	if dogs_share:
		for it in rig:
			lost -= int(it["value"])         # the dog's share: the rig is not lost
	last_report = {
		"outcome": "Dead", "tier": m["tier"], "kills": m["kills"], "of": int(t["pool"]), "loot": 0,
		"left": m["found"].size() + m["left"], "cash": 0.0, "xp": 0.0, "hp_lost": m["hp_start"], "time": m["elapsed"],
		"lost_value": lost, "searches": m["searches"], "patrols": m["patrols"], "fight": fight_breakdown(m),
	}
	_chron_run(m, "Dead", {"lost_value": lost, "insured": bool(m.get("insured", false)), "searches": int(m["searches"]), "patrols": int(m["patrols"]),
		"cleared": bool(m["cleared"]), "runner_runs": runner_runs})
	var dead_e: Dictionary = chronicle.back() if not chronicle.is_empty() and str(chronicle.back().get("k", "")) == "run" and str(chronicle.back().get("outcome", "")) == "Dead" else {}
	past.append({"class": cls, "level": level(), "runs": runner_runs, "end": "died in %s" % Words.mid(t["name"]), "site": _deepest_held()[0], "depth": _deepest_held()[1], "held_lv": _deepest_held()[2]})
	_past_fold()
	if Words.PASTS.has(cls) and not _dry_on:
		log_event(Words.LOG["wall"] % [cls.to_lower(), Words.PASTS[cls]["wall"]])     # the runner as the Yard remembers them (12 Oct; the wall is the retired's)
	runner_runs = 0
	_record_reset()
	if m.get("insured", false):
		# the Fence held the paper: what was worn and carried comes back to the stash, whatever the room
		last_report["lost_value"] = 0
		for s in Data.SLOTS:
			if equipped[s] != null:
				stash.append(equipped[s])
		for it in rig:
			stash.append(it)
		log_event(Words.LOG["dead_insured"] % [Words.mid(t["name"]), Words.FENCE["paid_out"]])
		if yard_has("insurance_desk") and not m["found"].is_empty():
			for it in m["found"]:
				if _home_gate(it):
					continue                     # a head's thing opens its room (13 Oct)
				stash.append(it)                 # the Fence's Insurance desk: the pack comes home too
				if Items.is_deeds(it) and deeds_fate == "":
					deeds_fate = "held"
					log_event(Words.DEEDS["held"])
			m["pack_kept"] = true
			last_report["left"] = int(m["left"])
			log_event(Words.LOG["insured_pack"] % [m["found"].size(), "" if m["found"].size() == 1 else "s"])
	else:
		log_event(Words.LOG["dead"] % [Words.mid(t["name"]), _cash_words(lost), Words.RECYCLE["listed"]])
		var pocket: bool = has_node("back_pocket")
		for s in Data.SLOTS:
			if equipped[s] != null:
				if equipped[s].get("mythic", false) or equipped[s].get("issued", false):
					stash.append(equipped[s])        # a mythic is never lost: it comes home (16 Oct); nor issued kit (25 Oct)
				elif pocket:
					pocket = false
					stash.append(equipped[s])        # Back pocket (22 Oct): the Fence keeps one piece free
					log_event(Words.LOG["back_pocket"] % Items.full_name(equipped[s]).to_lower())
				else:
					_lose(equipped[s], "the last %s" % cls, "runner")
		if dogs_share:
			for it in rig:
				stash.append(it)                 # the dog's share: the rig comes home
			log_event(Words.LOG["dog_rig"] % [rig.size(), "" if rig.size() == 1 else "es"])
	if not m.get("pack_kept", false):
		for it in m["found"].filter(func(x): return x.get("mythic", false) or x.get("issued", false)):
			stash.append(it)                     # a mythic found on the run comes home, whatever (16 Oct); a head's issued piece too (the third review)
			m["found"].erase(it)
	if yard_has("fetch") and not m["found"].is_empty() and not m.get("pack_kept", false):
		# the kennel's top level (31): the dog carries the best thing in the pack home - gear before scrap and materials (1 Nov)
		var best: Dictionary = fetch_pick(m["found"])
		if not _home_gate(best):
			stash.append(best)
		last_report["carried"] = Items.full_name(best)
		last_report["left"] = int(last_report["left"]) - 1
		log_event(Words.LOG["dog_home"] % (Items.full_name(best) if best.has("unique") else Items.full_name(best).to_lower()))
		if Items.is_deeds(best) and deeds_fate == "":
			deeds_fate = "held"                  # the deeds, carried home: held all the same
			log_event(Words.DEEDS["held"])
	var hauled: Dictionary = _haul_home(m, false)     # what the Insurance desk or the dog brought of the pack's scrap and materials, counted in (1 Nov); the rest lost with the pack
	_dead_haul_said(m, hauled, dead_e)
	for s in Data.SLOTS:
		equipped[s] = null
		_stats_dirty()
	rig = []
	operators_lost += 1
	if level() >= Data.MAX_LEVEL:
		# past the cap the next runner starts at it (Matt, 26 Oct: the third review's M2 - a death sent a level-50 runner
		# to 1, and shut the County till 50 again); the designer's call (1 Nov, PROBE40: the long pass's 75-100 deaths
		# past 50 kept the paragons at 0-2): the paragon levels stay too, only the XP towards the next one goes; the ring
		# stays trained
		xp = Data.xp_for_level(Data.MAX_LEVEL)
		var p_kept: int = paragon()
		var p_floor: float = Data.xp_for_level(Data.MAX_LEVEL + p_kept) - Data.xp_for_level(Data.MAX_LEVEL)
		var p_lost: float = maxf(0.0, paragon_xp - p_floor)
		last_report["paragon_kept"] = p_kept
		last_report["paragon_lost_xp"] = p_lost      # what the death took, for the card
		var kept_w: String = Words.YARD["kept_paragon"] % p_kept if p_kept > 0 else Words.YARD["kept_level"] % Data.MAX_LEVEL
		_came_back_death_xp(p_lost, kept_w, Words.YARD["kept_paragon"] % (p_kept + 1))
		if p_lost > 0.0 and not hardcore:
			# hardcore: its own lines only (the review); only when XP went (the review: a second death said so with none)
			log_event(Words.YARD["paragon_lost"] % [p_kept + 1, p_kept] if p_kept > 0 else Words.YARD["paragon_first_lost"])
		paragon_xp = p_floor
	elif death_keeps_level():
		var keep: int = level()
		var lv_lost: float = maxf(0.0, xp - Data.xp_for_level(keep))
		_came_back_death_xp(lv_lost, Words.YARD["kept_level"] % keep, Words.YARD["kept_level"] % (keep + 1))
		xp = Data.xp_for_level(keep)             # the designer's call (31 Oct): past the Quartermaster a death costs the XP towards the next level, never the level
		if lv_lost > 0.0 and not hardcore:
			log_event(Words.YARD["level_kept"] % [keep + 1, keep])     # hardcore: no next runner, its own lines only (the review)
	else:
		xp = 0.0
	wounds = {}                          # theirs, gone with them
	_stats_dirty()
	hp = Data.BASE_HP
	_night_dead(m)                            # a night's haul lost with the run (BUILD50 N)
	_signal_done(m, true)
	_sweep_papers()                           # a paper the insurance or the dog brought home: the Radio's pile
	mission = null
	if hardcore:
		camp_lost = true
		log_event(Words.YARD["hardcore_lost"])
		return
	# the new operator brings their own worn kit, so a KIA with an empty stash
	# and no cash is a setback, not a dead end
	_starter_loadout()
	exchange_day += 1                         # home, if not whole: the exchange's new day (28 Oct)
	town_pay_day()                            # and the town's wages (BUILD50-T)
	restock()
	# two turn up; one is who was brought home from a run, if anyone was
	var pool: Array = []
	for row in Data.TRAITS:
		pool.append(row["name"])
	pool.shuffle()
	candidates = [pool[0], pool[1]]
	if promised != "":
		candidates[1] = promised
		promised = ""
	runner_trait = candidates[0]
	log_event(Words.PASTS[cls]["arrives"] if Words.PASTS.has(cls) else "Two new runners turn up at the Pitch with their own kit: pick one.")
	# the dead runner's past goes with them: their class and its trees come
	# back as points for the next to spend from the start, with a past of their
	# own to pick. The Yard's tree and the elements' are the Yard's and stay.
	_refund_runner_trees()


## A death's XP for the came-back card (1 Nov): the XP towards the next level or paragon level it took, summed over the
## deaths since Seen; what was kept ("level 36", "paragon 7") and what the XP was towards ("level 37", "paragon 8") as of
## the last.
func _came_back_death_xp(lost_xp: float, kept: String, towards: String) -> void:
	if hardcore or _dry_on:
		return
	if came_back.is_empty():
		came_back_seen()
	came_back["xp_lost"] = float(came_back.get("xp_lost", 0.0)) + maxf(0.0, lost_xp)
	came_back["kept"] = kept
	came_back["towards"] = towards


## The odds read at the gate, settled, or -1 (the record): a signal's or an order's own read when one's laid on the site
## (BUILD41's review: they live in _sig_odds under the signal's id or the order's key, so the site's cache logged -1
## for every one), else the site's.
func _gate_odds(i: int) -> float:
	if _sig.is_empty() or int(_sig["site"]) != i:
		return odds_now(i) if odds_settled(i) else -1.0
	var key: Variant = int(_sig["id"])
	if _sig.has("order"):
		key = "order/%s/%d" % [str(_sig["order"]), int(_sig["depth"])]
	var c = _sig_odds.get(key, null)
	var runs: int = odds_runs() if odds_runs_max <= 0 else mini(odds_runs(), odds_runs_max)
	return float(c[1]) if c is Array and c[0] == _odds_key(i) and int(c[2]) >= runs else -1.0


## A death below the cap keeps the level once the Quartermaster's down (the designer's call, 31 Oct, PROBE36: a death
## sent a level-36 runner to 1 and any slower curve read as "never"); before him a death is back to level 1.
func death_keeps_level() -> bool:
	return expeditions_open() and level() < Data.MAX_LEVEL


## The runner's web back to points on a death - the whole of it but the start (the skill web: it's all the runner's);
## the class stays the class (21 Oct, the crew: "puts that class back to level 1 with a trait"). The ring stays.
func _refund_runner_trees() -> void:
	var spent_before := points_spent()
	var kept := []
	for id in tree:
		if is_ring(str(id)):
			kept.append(id)                  # the paragon ring is the crew's: it stays
	tree = kept
	_dry_memo.clear()
	_stats_dirty()
	_ensure_start(false)
	_skills_known_only()                     # the dead runner's skills leave the slots with his trees (the second review)
	var freed := spent_before - points_spent()
	if freed > 0:
		log_event(Words.YARD["runner_refund"] % [freed, "" if freed == 1 else "s"])


func _cash_words(x: float) -> String:
	var n := int(round(x))
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	if issued:
		return "%sƒ%s%s" % ["−" if n < 0 else "", s, out]     # after the Issue, fiat (the third review: the log still said tins)
	return "%s%s%s tin%s" % ["−" if n < 0 else "", s, out, "" if n == 1 else "s"]     # grouped as the screens say it


## The money's name as the screens say it: tins, then fiat after the Issue (the third review).
func money_word() -> String:
	return "fiat" if issued else "tins"


# ------------------------------------------------------------------ the armoury

## Trying it on (11 Oct, Matt: the Van's Spare's +18% damage read worse than a machine pistol that cost him damage).
## A piece's own score sees it alone; what it does on this runner - a damage % on the whole of the damage, the
## secondary's third behind the primary, a unique's rule, the trees' gun types, the sets - only shows with it worn.
## So "better" is read with it in its slot for a moment, every gun counted fed, nothing memoised, then put back.
var _trying := false
const TRY_EPS := 0.005               # half a percent either way is the same


## What `f` reads with `it` in its slot (or as the kit is, `it` empty), every gun fed.
func _try(it: Dictionary, f: Callable) -> Variant:
	var was_trying := _trying
	_trying = true
	_try_memo.clear()                  # the kit's about to differ from whatever the last try read
	var slot: String = str(it.get("slot", ""))
	var swap: bool = not it.is_empty() and equipped.has(slot)
	var was = equipped[slot] if swap else null
	if swap:
		equipped[slot] = it
	var v = f.call()
	if swap:
		equipped[slot] = was
	_try_memo.clear()                  # and differs again now the piece is off (an outer try reads afresh)
	_trying = was_trying
	return v


## The runner's figure for a slot with `it` worn ({} for the kit as it is): the damage for a gun, the survival figure
## for the body (survival_value: HP, regen, armour and resists against the fight being pushed), the piece's score for
## bags and charms.
## `key`: the kit's key when the caller has it (a scan of the stash reads it once, not once an item).
## `moved`: read with the worn piece's parts moved over (moved_over) - where the screen's act is "Swap, parts and all" (the
## Kit, Equip if better); else as the piece stands, as an equip moves nothing (a run's pack, the Fence: the fix round).
func fit_value(it: Dictionary, slot := "", key := -1, moved := false) -> float:
	if slot == "":
		slot = str(it.get("slot", ""))
	# cached with the verdicts (the bot's sell loop asks for the best of a slot once a stash item)
	if key < 0:
		key = _kit_key()
	if key != _cmp_key:
		_cmp_key = key
		_cmp_cache.clear()
	var fk := "f/%s/%d/%s" % [slot, hash(it), "m" if moved else ""]
	if _cmp_cache.has(fk):
		return _cmp_cache[fk]
	var v := _fit_value(it, slot, moved)
	_cmp_cache[fk] = v
	return v


func _fit_value(it: Dictionary, slot: String, moved := false) -> float:
	if moved:
		it = moved_over(it)                  # what you'd wear after the swap: the worn piece's parts on it where they fit (29 Oct, the compare's A)
	match Data.SLOT_SCORE.get(slot, ""):
		"dps":
			return _try(it, damage_total)     # the hits and the burn, as the top bar reads them (18 Oct)
		"grip":
			return _try(it, fight_damage)     # gloves (29 Oct, the review: pace read as a damage drop): the fight's figure, pace in
		"armour":
			return _try(it, survival_value.bind(front_fight()))
	if it.is_empty():
		return Items.score(equipped[slot]) if equipped.get(slot) != null else 0.0
	return Items.score(it, mag_gun(it) if Items.is_mag(it) else null)     # a magazine against the gun it feeds (game 10)


## The body's figure (12 Oct, Matt: a +5 HP/s helmet and charm carried his run while the arrow called 50-armour drops
## better - armour and half the HP saw no regen, no resist): how many times over the runner stands the fight being
## pushed. HP, regen over the fight and HP a kill, against their fire through armour and resists over the same
## seconds - regen, resists, armour and HP in one currency, at the depth that's open. Read tried on (fit_value).
const SURV_SLOTS := ["Helmet", "Armour", "Charm", "Rig"]
## `fight` is the fight's seconds, held at the worn kit's (front_fight) when a piece is tried on: what a piece does to
## the damage and the pace is the damage's own reading, not counted twice through a longer fight (the riot suit's -8
## pace read as less survival than a stab vest's 15 armour).
func survival_value(fight := -1.0) -> float:
	var t := surv_fight()
	if fight <= 0.0:
		fight = front_fight()
	var on_you: int = contact(t)
	var took: float = incoming_rate(t, on_you) * crowd_mult(on_you) * fight     # the crowd's rules too (23 Oct)
	var back: float = max_hp() + regen_rate() * fight + _affix_sum("life_per_kill") * float(t["pool"])
	return back / maxf(took, 0.000001)       # an easy front still reads the armour (a floor of 1 HP hid it: the review)


## The seconds the fight being pushed takes on the kit as worn, every gun fed as a try-on reads it (out of rounds,
## the fists' fight ran twenty-five times as long); no damage at all reads as an hour.
func front_fight() -> float:
	var key := _kit_key()
	if key != _cmp_key:
		_cmp_key = key
		_cmp_cache.clear()
	if not _cmp_cache.has("ff"):             # once a kit (the review: every cell of a grid asked it again)
		_cmp_cache["ff"] = clampf(float(_try({}, func(): return _surv_estimate(surv_fight()))), 1.0, 3600.0)
	return _cmp_cache["ff"]


## The fight the body's figure is read against (BUILD48 A, parked item 22; Matt: "why the disparity here between being in a
## fight and out ?"): on a run, the run's own (as the gun's edge and the level fought read it); at camp the fight being
## pushed, front_tier()'s. Before, a run read front_tier() too - and on a signal's run that was the signal's site at its
## level with its codes on, so the same piece read "Upgrade" in the pack and "Sidegrade" in the stash. The figure's line
## says which (surv_against) and is never called odds.
func surv_fight() -> Dictionary:
	if mission != null and mission.get("t", null) is Dictionary and not mission.get("dry", false):
		return mission["t"]
	return effective(front_tier())


## The yardstick in words: "against this run" on one, "against the Barracks" at camp.
func surv_against() -> String:
	if mission != null and mission.get("t", null) is Dictionary and not mission.get("dry", false):
		return Words.YARDSTICK["run"]
	return Words.YARDSTICK["home"] % Words.mid(str(Data.TIERS[front_tier()]["name"]))


## estimate() against a fight as given (the yardstick's): its seconds at the runner's damage.
func _surv_estimate(t: Dictionary) -> float:
	return float(t["pool"]) * float(t["hp"]) / maxf(dps() * edge_read(t) * pace() * float(t["pace"]), 0.000001)


## The rounds' types to hand, when the Fence is shut (a try-on reads a gun fed only then: the verdicts follow them).
func _rounds_on_hand() -> String:
	if room_open("fence"):
		return ""
	var types := {}
	for it in rig + _rounds_held():          # the pack's too (21 Oct)
		if Items.is_ammo(it):
			types[Items.base_of(it)["type"]] = true
		elif Items.is_mag(it) and int(it.get("rounds", 0)) > 0:
			types[Items.mag_type(it)] = true     # a loaded magazine (30 Oct)
	var k: Array = types.keys()
	k.sort()
	return ",".join(k)


## The fight being pushed: the open site that hits hardest at its set depth (the campaign's newest site, the
## endgame's deepest ladder). The kit doesn't move it; the depths and the clears do.
var _front_key := 0
var _front := 0
func front_tier() -> int:
	var key: int = hash([depth, best_depth, campaign_done(), bosses_beaten, words, standing, atlas])     # what opens a site and what it fights with (the review)
	if key == _front_key:
		return _front
	var kept: int = _c51_front_seen(key)     # (BUILD51-C) a state seen lately: a parked read's signal laid on and off
	if kept >= 0:                            # each frame made live_guard work this out twice a frame (~2 ms a frame late)
		_front_key = key
		_front = kept
		return _front
	var bf := -1.0
	_front = 0
	for i in range(Data.TIERS.size()):
		if tier_open(i):
			var t := effective(i)
			var f: float = float(t["dps"]) * float(t["hp"]) * float(t["pool"])
			if f > bf:
				bf = f
				_front = i
	_front_key = key
	_c51_front_keep(key, _front)             # (BUILD51-C)
	return _front


## The body's figure with `it` worn, as a share up or down on the kit as it is (0.0 for a slot that has none).
func survival_gain(it: Dictionary, moved := false) -> float:
	var slot: String = str(it.get("slot", ""))
	if not (slot in SURV_SLOTS) or not equipped.has(slot):
		return 0.0
	var key := _kit_key()
	if key != _cmp_key:
		_cmp_key = key
		_cmp_cache.clear()
	var sk := "s/%d/%s" % [hash(it), "m" if moved else ""]
	if not _cmp_cache.has(sk):
		if not _cmp_cache.has("s0"):
			_cmp_cache["s0"] = _try({}, survival_value)
		var s0: float = _cmp_cache["s0"]
		_cmp_cache[sk] = (float(_try(moved_over(it) if moved else it, survival_value.bind(front_fight()))) - s0) / maxf(s0, 0.0001)     # with your parts moved over when the swap's the act (29 Oct)
	return _cmp_cache[sk]


## Against what's worn in its slot: 1 better, 0 a sidegrade (or a trade: up one way, down another), -1 worse. A gun
## by the runner's damage with it on; anything else by its own job and the damage with it on, and a helmet, coat,
## charm or rig by the survival figure too (12 Oct; a helmet's or coat's job is that figure). An empty slot takes
## anything that goes in it.
func compare(it: Dictionary, key := -1, moved := false) -> int:
	var slot: String = str(it.get("slot", ""))
	if not equipped.has(slot):
		return 0
	if equipped[slot] == null:
		return 1
	# the grids ask for every cell ten times a second: an answer stands until the kit or the piece changes
	if key < 0:
		key = _kit_key()
	if key != _cmp_key:
		_cmp_key = key
		_cmp_cache.clear()
	var ih: int = hash([it, moved])
	if _cmp_cache.has(ih):
		return _cmp_cache[ih]
	var c := _compare(it, slot, moved)
	# over a worn unique bag or charm (Matt, 11 Oct): their figure is the piece's own score, which never sees the
	# unique's rule (the Van Keys' 12 against a plain charm's 30), so nothing is better outright - the player's to
	# judge. A gun's or body piece's figure is the runner's own with it on, the rule counted where it touches the
	# damage or the armour, so it's judged like anything else (a quarter's margin there held the bot to a T2 Van's
	# Spare all game: services at depth 5 at 11.6 h against 3.4 h on the same dice, the 11 Oct read)
	if c == 1 and equipped[slot].has("unique"):
		var kind: String = Data.SLOT_SCORE.get(slot, "")
		if not (kind == "dps" or kind == "armour") or equipped[slot].get("mythic", false):
			c = 0                             # a worn mythic's rule never shows in a figure: never swapped out for one (the review)
	_cmp_cache[ih] = c
	return c


var _cmp_key := 0
var _cmp_cache := {}                 # hash of the piece -> its verdict, while the kit stays as it is


## What the try-on's answers hang on: what's worn (bench work and all), the level, the trees, the pasts, a wound,
## the grades of rounds in the rig (what feeds a gun - never the count, which falls every shot of a run and would
## throw the answers away each second) and how many things it holds (armour a med), the pack's fill on a run
## (armour a free cell), the Yard (the Clinic's HP), the trades, and whether a run is on.
func _kit_key() -> int:
	if _key_holding:
		return _key_held                 # BUILD45: one key through a paint that moves nothing it reads (held_kit_key)
	return hash(_kit_parts())


## What the key is made of (21 Oct: apart, so the smoke can say which part changed).
func _kit_parts() -> Array:
	var lot: bool = mission != null and (not mission.get("cleared", false) or mission.get("ghost_pending", false))     # First lot counts until the clear
	var pack: int = pack_used(mission) if mission != null else -1        # armour a free cell (the review)
	return [runner_key(), _rig_grades(), _stash_grades(), pack, yard_picks, yard_ranks, mission != null, lot, hp < max_hp() * 0.5, front_tier(), _rounds_on_hand(),
			fight_weather_of(front_tier()), is_night(),
			[int(mission["t"].get("tier", -1)), int(mission["t"].get("level", 0)), int(mission["t"].get("depth", 0))] if mission != null and mission.get("t", null) is Dictionary else []]     # the run's own fight, the body's yardstick on a run (BUILD48 A, item 22)     # the runner whole (runner_parts: the kit, the level, the trees, the skills a run takes and their rules on or off); the front: the body's figure reads the fight being pushed, under its sky (14 Oct: a verdict under rain stood after it cleared)


## The runner out, whole (30 Oct, refactor 1, the review's 28 caches each cleared by hand): who they are and everything of
## theirs a figure reads - the class, the level, the trait, what's worn by value (ids, parts, bench work), the trees, the
## skills slotted and on, the wounds, the ring, the class's two elements, the rig's count. The one key the caches that
## hang on the runner check (the try-ons' _kit_key, the odds key's memos), so a class read or swapped in, a level
## gained, a skill slotted can't leave one standing. HP is each cache's own grain (the odds read it to a tenth, the
## try-ons either side of half), as the camp's figures are (the Yard, the sky, the front). Not the fast memo (the balance
## gate's, through a run): checked a tick, it moved the fixed-dice fingerprint the balance pass is reading (a level gained
## mid-run keeps the old max HP till the memo ages), so it stays cleared by hand and aged.
func runner_parts() -> Array:
	return [cls, level(), runner_trait, equipped, tree, skill_slots, skill_auto, wounds.keys(), ring, rig.size()]


func runner_key() -> int:
	return hash(runner_parts())


## BUILD45 (2 Nov, perf44 1): the key a stash's arrow stands on - the try-ons' own (_kit_parts), but the pack's fill
## only where a figure reads it: armour an empty pack cell, worn or on the piece judged (`apf`). Nothing else a verdict
## reads counts the pack's cells (_armour_raw), so a find picked up on a run no longer throws every arrow away.
func arrow_key(apf := false) -> int:
	var parts := _kit_parts()
	if not apf and not _worn_reads_pack():
		parts[3] = -2
	return hash(parts)


## Whether a piece carries armour an empty pack cell (its figure reads the pack's fill).
static func reads_pack(it: Dictionary) -> bool:
	for a in it.get("affixes", []):
		if str(a.get("stat", "")) == "armour_per_free":
			return true
	return false


## BUILD45 (2 Nov, perf44 1: the Fence's rows asked the try-ons' key 400 times a paint, 0.3 ms each, the stash walked for
## its rounds every time): `f` called with the key worked out once and handed back to every compare inside it. Only
## for a paint that changes nothing the key is made of (the Fence's rows: rarity_sells takes pieces out and puts them
## back, never rounds, a paper, the kit, the rig or the pack); never held across a frame, never on the bot's path.
var _key_holding := false
var _key_held := 0
var _sells_held := {}                       # rarity -> what its row sells, through one hold
func held_kit_key(f: Callable) -> Variant:
	if _key_holding:
		return f.call()
	_key_held = hash(_kit_parts())
	_sells_held = {}
	_key_holding = true
	var v = f.call()
	_key_holding = false
	_sells_held = {}
	return v


func _worn_reads_pack() -> bool:
	for s in Data.SLOTS:
		if equipped[s] != null and reads_pack(equipped[s]):
			return true
	return false


## The past runners (BUILD45, perf44 #9, the designer's go): the newest PAST_KEPT kept whole in `past`, older ones folded
## into past_folded's running totals - 1,079 of them were 134-164 KB of a late save, 27-33 ms an autosave. Anything that
## counts the runners before reads past_count(), the same before and after a fold.
const PAST_KEPT := 100
func _past_fold() -> void:
	while past.size() > PAST_KEPT:
		var r: Dictionary = past.pop_front()
		past_folded["runners"] = int(past_folded.get("runners", 0)) + 1
		past_folded["runs"] = int(past_folded.get("runs", 0)) + int(r.get("runs", 0))
		past_folded["died"] = int(past_folded.get("died", 0)) + (1 if str(r.get("end", "")).begins_with("died") else 0)


## Every runner before this one, the folded ones too.
func past_count() -> int:
	return past.size() + int(past_folded.get("runners", 0))


## The rounds in the rig as the guns see them: each magazine with rounds left, by its grade, in the rig's order.
func _rig_grades() -> Array:
	var out: Array = []
	for it in rig:
		if Items.is_mag(it) and int(it["rounds"]) > 0:
			out.append(str(it.get("ammo", "")))
	return out


## The grades of rounds in the stash, by name (20 Oct): a try-on feeds a gun from them too (feed_stack).
func _stash_grades() -> Array:
	var out := {}
	for it in _rounds_held():                # the stash's, and the pack's on a run (21 Oct)
		if int(it["rounds"]) > 0:
			out[str(it["base"])] = true
	var k: Array = out.keys()
	k.sort()
	return k


func _compare(it: Dictionary, slot: String, moved := false) -> int:
	if moved:
		it = moved_over(it)                  # the Kit's verdict reads the piece with your parts moved over (29 Oct, the compare's A)
	# the top bar's figure, the dots in (18 Oct: the hits alone called a fire build's Epic a downgrade); once a kit, as
	# the survival baseline is (22 Oct, the pass's wall: it was tried on again for every piece compared)
	if not _cmp_cache.has("d0"):
		_cmp_cache["d0"] = _try({}, damage_total)
	var d0: float = _cmp_cache["d0"]
	var rel: float = (_try(it, damage_total) - d0) / maxf(d0, 0.01)
	var g: int = 1 if rel > TRY_EPS else (-1 if rel < -TRY_EPS else 0)
	var kind: String = Data.SLOT_SCORE.get(slot, "")
	if kind == "dps":
		return g
	if kind == "grip":
		# gloves (29 Oct): the fight's damage, pace in - their whole job; a trade is the player's
		if not _cmp_cache.has("f0"):
			_cmp_cache["f0"] = _try({}, fight_damage)
		var frel: float = (_try(it, fight_damage) - float(_cmp_cache["f0"])) / maxf(float(_cmp_cache["f0"]), 0.01)
		return 1 if frel > TRY_EPS else (-1 if frel < -TRY_EPS else 0)
	# each way it's read (12 Oct): the damage, the piece's own job, and for what's on the body the survival figure (a
	# body piece's job is that figure). Up on one and down on none, better; the reverse, worse; both, a trade
	var ways: Array = [g]
	var srel: float = survival_gain(it)      # `it` is already as it'd be worn
	if slot in SURV_SLOTS:
		ways.append(1 if srel > TRY_EPS else (-1 if srel < -TRY_EPS else 0))
	if kind != "armour":
		var own: float = Items.score(it) - Items.score(equipped[slot])
		ways.append(1 if own >= 0.05 else (-1 if own <= -0.05 else 0))
	var up: bool = ways.has(1)
	var down: bool = ways.has(-1)
	if up and not down:
		return 1
	if down and not up:
		return -1
	return 0                             # a trade, or the same: the panel's deltas say which way


## How much better, as a share of what the slot gives now (the bot's shop weighs one slot against another by it).
## An empty slot filled counts as doubling it (1.0): first in line, without the share blowing up over nothing.
const EMPTY_GAIN := 1.0
func upgrade_gain(it: Dictionary, moved := false) -> float:
	var slot: String = str(it.get("slot", ""))
	if not equipped.has(slot):
		return 0.0
	if equipped[slot] == null:
		return EMPTY_GAIN
	var v0: float = fit_value({}, slot)
	var g: float = (fit_value(it, "", -1, moved) - v0) / maxf(v0, 0.000001)
	if slot in SURV_SLOTS and Data.SLOT_SCORE.get(slot, "") != "armour":
		g = maxf(g, survival_gain(it, moved))       # a charm or rig bought for its regen or resists (the review: the bot never would)
	return g


func equip_best(slot: String) -> bool:
	if runner_busy():                         # away (29 Oct): the kit's with the runner
		return false
	# the best of the ones that are better outright (a trade is the player's to make)
	var best := {}
	var bs := -INF
	var key := _kit_key()                # once a scan (22 Oct, the pass's wall)
	for it in stash:
		if it["slot"] == slot and can_wear(it) and compare(it, key, true) == 1:     # read as the swap leaves it (29 Oct)
			var v := fit_value(it, slot, key, true)
			if v > bs:
				best = it
				bs = v
	if best.is_empty():
		return false
	if swap_moves(best) and swap_with_parts(int(best["id"])):     # read with your parts moved over, worn so (29 Oct, the compare's A)
		_feed(best)
		return true
	if swap_moves(best) or not can_equip_item(int(best["id"])):
		# the parts-and-all swap refused, or no room for a plain one (30 Oct, the review's I6): read again as they stand,
		# only what a plain swap can wear with the stash's room - never the piece picked with parts it won't get
		best = {}
		bs = -INF
		for it in stash:
			if it["slot"] == slot and can_equip_item(int(it["id"])) and compare(it, key, false) == 1:
				var v := fit_value(it, slot, key, false)
				if v > bs:
					best = it
					bs = v
		if best.is_empty():
			return false
	_remove(best)
	chron("equip", {"slot": slot, "how": "best", "on": _chron_item(best), "off": _chron_item(equipped[slot])})
	if equipped[slot] != null:
		stash.append(equipped[slot])
	equipped[slot] = best
	_stats_dirty()
	if slot == "Rig":
		_rig_shed()
	_feed(best)
	return true


## The compare's three readings (29 Oct, Matt: "it becomes really difficult to compare an item 1:1 if you have
## attachments and sockets"; the Compare board's layout A). A piece and the worn one in its slot, either with parts or
## socketables on: as they stand, base to base (both bare), and with your parts moved over - the found piece with the
## worn's parts where its mounts take them (open at the Bench, a typed part on its type), its socketables in the
## sockets it has; what won't go goes to the stash, named. The Kit's verdict, its stash's arrow and Equip if better read
## the third (moved_over) when the swap moves something, so what's read is what's worn after "Swap, parts and all";
## everywhere else (a run's pack, the Fence) reads as they stand (the fix round, 29 Oct).
func has_parts(piece) -> bool:
	return piece is Dictionary and Dictionary(piece.get("attachments", {})).values().any(func(a): return a != null)


## Whether "Swap, parts and all" moves anything (the fix round, 29 Oct, the UI review's B2): the worn one in its slot carries a
## part that goes onto `it`. Else the act is a plain Equip, read as the piece stands.
func swap_moves(it: Dictionary) -> bool:
	var on_kit = equipped.get(str(it.get("slot", "")))
	if on_kit == null or int(on_kit.get("id", -1)) == int(it.get("id", -2)) or not has_parts(on_kit):
		return false
	return not Array(parts_moved(it, on_kit)["moved"]).is_empty()


## The found piece with the worn's parts on it where they fit: {copy, moved: [names], left: [names], bumped: [the found's
## own parts they push off]}.
func parts_moved(found: Dictionary, on_kit: Dictionary) -> Dictionary:
	var copy: Dictionary = found.duplicate(true)
	var moved: Array = []
	var left: Array = []
	var left_ids: Array = []
	var bumped: Array = []
	var ty: String = str(Items.base_of(found).get("type", ""))
	var socks: Array = []
	for k in copy.get("attachments", {}):
		if str(k).begins_with("socket"):
			socks.append(str(k))
	socks.sort()
	for mount in on_kit.get("attachments", {}):
		var a = on_kit["attachments"][mount]
		if a == null:
			continue
		var at := ""
		if str(mount).begins_with("socket"):
			if not socks.is_empty():
				at = str(socks.pop_front())
		elif copy["attachments"].has(mount) and mount_open(str(mount)) and Items.att_fits(a, ty):
			at = str(mount)
		if at == "":
			left.append(str(a["base"]))
			left_ids.append(int(a["id"]))
			continue
		if copy["attachments"][at] != null:
			bumped.append(copy["attachments"][at])
		copy["attachments"][at] = Dictionary(a).duplicate(true)
		moved.append(str(a["base"]))
	return {"copy": copy, "moved": moved, "left": left, "left_ids": left_ids, "bumped": bumped}


## A piece as the try-ons read it: with the worn's parts moved over when the worn one in its slot carries any (and it isn't
## the worn one itself); else as it is.
func moved_over(it: Dictionary) -> Dictionary:
	if it.is_empty():
		return it
	var on_kit = equipped.get(str(it.get("slot", "")))
	if on_kit == null or int(on_kit.get("id", -1)) == int(it.get("id", -2)) or not has_parts(on_kit):
		return it
	return parts_moved(it, on_kit)["copy"]


## A piece bare: no parts, no socketables, its mounts and sockets as they are.
static func bare(it: Dictionary) -> Dictionary:
	var b: Dictionary = it.duplicate(true)
	for k in b.get("attachments", {}):
		b["attachments"][k] = null
	return b


## The three readings for a gun against the worn one, [] when neither carries a part or it's no gun (one reading as before):
## each {key, label, found, worn, line} - the runner's damage a second, as the sim sums it.
func compare_readings(it: Dictionary) -> Array:
	var slot: String = str(it.get("slot", ""))
	var on_kit = equipped.get(slot)
	# a gun's alone (the fix round, 29 Oct, the UI review's B6 and D5): a body piece's odds against the front sit flat, so
	# its socketable reads better as the plain head and the deltas
	if Data.SLOT_SCORE.get(slot, "") != "dps" or on_kit == null or int(on_kit.get("id", -1)) == int(it.get("id", -2)) or not (has_parts(on_kit) or has_parts(it)):
		return []
	var f: Callable = damage_total
	var w_stand: float = float(_try({}, f))
	var mv: Dictionary = parts_moved(it, on_kit)
	var out: Array = []
	out.append({"key": "stand", "label": "As they stand", "found": float(_try(it, f)), "worn": w_stand, "line": _stand_line(it, on_kit)})
	out.append({"key": "bare", "label": "Base to base", "found": float(_try(bare(it), f)), "worn": float(_try(bare(on_kit), f)), "line": ["Both bare: no parts, no sockets", "Both bare"]})
	out.append({"key": "moved", "label": "With your parts moved over", "found": float(_try(mv["copy"], f)), "worn": w_stand, "line": _moved_line(mv), "left": mv["left"]})
	return out


## The first reading's small line: what's on each now, long to short.
func _stand_line(it: Dictionary, on_kit: Dictionary) -> Array:
	var yours: Array = Items.fitted_words(on_kit)
	var theirs: Array = Items.fitted_words(it)
	var y: String = "nothing on yours" if not has_parts(on_kit) else "yours: %s" % str(yours[mini(1, yours.size() - 1)])
	var t: String = "nothing on this" if not has_parts(it) else "this: %s" % str(theirs[mini(1, theirs.size() - 1)])
	var line: String = "%s · %s" % [y, t]
	var n_y: int = Dictionary(on_kit.get("attachments", {})).values().filter(func(a): return a != null).size()
	var n_t: int = Dictionary(it.get("attachments", {})).values().filter(func(a): return a != null).size()
	return [line.left(1).to_upper() + line.substr(1), "Yours %d fitted · this %d" % [n_y, n_t]]     # the middle form keeps the count (the fix round, the UI review's C3)


## The third reading's small line, long to short: what moves onto this one, what of yours goes to the stash, and this one's
## own parts it pushes off (the fix round, 29 Oct: the UI review's B3 and C4, the language review's "to the stash").
func _moved_line(mv: Dictionary) -> Array:
	var moved: Array = mv["moved"]
	var off: Array = Array(mv["left"]) + Array(mv["bumped"]).map(func(a): return str(a["base"]))
	var go: String = ("%s onto this one" % ", ".join(moved)) if not moved.is_empty() else "Nothing moves over"
	var stash_w: String = ("%s to the stash" % ", ".join(off)) if not off.is_empty() else ""
	var forms: Array = []
	forms.append(go + ((" · " + stash_w) if stash_w != "" else ""))
	if not off.is_empty():
		forms.append("%s · %d to the stash" % [("%d moved" % moved.size()) if not moved.is_empty() else "Nothing moves over", off.size()])
		forms.append("%d moved · %d off" % [moved.size(), off.size()])
	else:
		forms.append("%d part%s moved over" % [moved.size(), "" if moved.size() == 1 else "s"])
	return forms


## Whether "Swap, parts and all" can happen now (30 Oct, the review's U4: the button was lit with no room, and pressing it
## did nothing): it can be worn, and the stash has the room for the old piece and every part that comes off.
func can_swap_with_parts(id: int) -> bool:
	if runner_busy() or not can_equip_item(id):
		return false
	var it := {}
	for x in stash:
		if int(x["id"]) == id:
			it = x
	if it.is_empty():
		return false
	var on_kit = equipped[str(it["slot"])]
	if on_kit == null or not has_parts(on_kit):
		return true                           # a plain Equip: can_equip_item's room
	var mv: Dictionary = parts_moved(it, on_kit)
	var need := 0
	for b in mv["bumped"]:
		need += Items.size(b)
	for mount in on_kit["attachments"]:
		var a = on_kit["attachments"][mount]
		if a != null and int(a["id"]) in mv["left_ids"]:
			need += Items.size(a)
	var out_cells: int = 0 if stash_free(it) or tab_of(it) != "" else Items.size(it)
	return stash_used() - out_cells + Items.size(on_kit) + need <= stash_cap()


## Swap, parts and all (29 Oct): the stash piece on, the worn one's parts and socketables onto it where they fit, the
## rest off into the stash; the new piece's own parts they push off go to the stash too. False when it can't be worn,
## or the stash hasn't the room for what comes off.
func swap_with_parts(id: int) -> bool:
	if not can_swap_with_parts(id):
		return false
	var it := {}
	for x in stash:
		if int(x["id"]) == id:
			it = x
	var slot: String = str(it["slot"])
	var on_kit = equipped[slot]
	if on_kit == null or not has_parts(on_kit):
		return equip_item(id)
	var mv: Dictionary = parts_moved(it, on_kit)
	if not equip_item(id):
		return false
	var new_piece: Dictionary = equipped[slot]
	var moved_n := 0
	for at in mv["copy"]["attachments"]:
		var a = mv["copy"]["attachments"][at]
		if a == null:
			continue
		for mount in on_kit["attachments"]:
			var w = on_kit["attachments"][mount]
			if w != null and int(w["id"]) == int(a["id"]):
				if new_piece["attachments"].get(at) != null:
					stash_put(new_piece["attachments"][at])     # the new piece's own, pushed off
				new_piece["attachments"][at] = w
				on_kit["attachments"][mount] = null
				moved_n += 1
				break
	for mount in on_kit["attachments"]:
		if on_kit["attachments"][mount] != null:
			stash_put(on_kit["attachments"][mount])     # what won't go: off the old piece into the stash
			on_kit["attachments"][mount] = null
	_dry_memo.clear()
	_stats_dirty()
	var off: Array = Array(mv["left"]) + Array(mv["bumped"]).map(func(a): return str(a["base"]))
	var nm: String = Words.mid(Items.full_name(new_piece)) if new_piece.has("unique") else "the " + Words.mid_base(Items.full_name(new_piece))     # never lowered whole (the language review)
	log_event(Words.LOG["swapped"] % [nm, moved_n, (", %s to the stash" % ", ".join(off)) if not off.is_empty() else ""])
	return true


## The rig at the gate (23 Oct, parked item 4, the 21 Oct mockup): what the gate takes out of the stash into the
## rig's room before a run. "fill": every grade of the worn guns' rounds and the meds, the build's grade first;
## "best": the top grade of each, nothing plainer; "leave": the rig goes as packed. Set once on the Map, kept.
const TOP_UP_MODES := ["leave", "fill", "best"]
## The old Map button's three settings (BUILD46-R, 2 Nov: the rounds picker took its place): read off the camp's plan
## (rounds_plan), and set as the whole of it - every site's own plan goes, the camp's is the mode's (_plan_of_mode).
var top_up_mode: String:
	get:
		return _plan_mode(rounds_plan(-1))
	set(v):
		if v in TOP_UP_MODES:
			rounds_plans = {"camp": _plan_of_mode(v)}


func set_top_up(mode: String) -> void:
	if mode in TOP_UP_MODES and (mode != top_up_mode or rounds_plans.size() > 1):
		top_up_mode = mode
		_dry_memo.clear()
		_stats_dirty()


# ------------------------------------------------------------------ rounds for the run (BUILD46-R)
## Rounds for the run (2 Nov, Matt's playtest: "no way of selecting which rounds to take with you in the pack"; the
## canvas "Fiat – Rounds and magazines", board 2): a plan a site - each worn gun's rounds type, its grade (`grade`: ""
## the gate's own pick, the grade its magazines hold or the stash's best) and how many boxes of it ride in the pack
## (`boxes`), and whether the rig is packed and its magazines topped up from the stash first (`top`). A site never set
## reads the camp's plan, which follows the last one set anywhere. `load` false: the magazines go as they are, not even
## topped up (the tick's off); the old "Leave it" kept `load` (its magazines were always filled). `best`: the old "Best
## grades only". 0.10.2's one-box rule went (the designer's call: boxes cost pack cells).
const PLAN_BASE := {"top": true, "load": true, "best": false, "boxes": 1, "guns": {}}
var rounds_plans := {}                  # {"camp": plan, "<site>": plan}: only what's been set


func _plan_of_mode(mode: String) -> Dictionary:
	var p: Dictionary = PLAN_BASE.duplicate(true)
	if mode == "leave":
		p["top"] = false
		p["boxes"] = 0
	p["best"] = mode == "best"
	return p


func _plan_mode(p: Dictionary) -> String:
	if not bool(p.get("top", true)):
		return "leave"
	return "best" if bool(p.get("best", false)) else "fill"


## A site's plan as the gate reads it: its own, else the camp's, else the base's. -1: the camp's.
func rounds_plan(i := -1) -> Dictionary:
	var p: Dictionary = PLAN_BASE.duplicate(true)
	var own = rounds_plans.get(str(i), null) if i >= 0 else null
	var src = own if own is Dictionary else rounds_plans.get("camp", null)
	if src is Dictionary:
		p.merge(Dictionary(src).duplicate(true), true)
	return p


## Whether a site has its own plan (the panel's foot says where it's remembered).
func rounds_plan_own(i: int) -> bool:
	return rounds_plans.has(str(i))


## The grade a site's plan picks for a type, "" for the gate's own.
func plan_grade(i: int, ty: String) -> String:
	return _plan_grade(rounds_plan(i), ty)


## The boxes a site's plan packs of a type (the panel's count).
func plan_boxes(i: int, ty: String) -> int:
	return _plan_boxes(rounds_plan(i), ty)


## The plan's grade for a rounds type, "" for the gate's own pick.
static func _plan_grade(p: Dictionary, ty: String) -> String:
	return str(Dictionary(p.get("guns", {}).get(ty, {})).get("grade", ""))


## The boxes the plan packs of a type: its own count, else the plan's.
static func _plan_boxes(p: Dictionary, ty: String) -> int:
	var g: Dictionary = p.get("guns", {}).get(ty, {})
	return maxi(0, int(g.get("boxes", p.get("boxes", 1))))


## A change to a site's plan (the panel's): the site keeps its own from now, and the camp's follows it (a site never set
## starts from the last choice). Not while the runner's out.
func _plan_edit(i: int, f: Callable) -> bool:
	if runner_busy():
		return false
	var p: Dictionary = rounds_plan(i)
	f.call(p)
	if i >= 0:
		rounds_plans[str(i)] = p
	rounds_plans["camp"] = p.duplicate(true)
	_dry_memo.clear()
	_stats_dirty()
	if i >= 0:
		_surv_cache.erase(i)
	return true


func plan_set_grade(i: int, ty: String, grade: String) -> bool:
	return _plan_edit(i, func(p: Dictionary):
		var g: Dictionary = p["guns"].get(ty, {})
		g["grade"] = grade
		p["guns"][ty] = g)


func plan_set_boxes(i: int, ty: String, n: int) -> bool:
	return _plan_edit(i, func(p: Dictionary):
		var g: Dictionary = p["guns"].get(ty, {})
		g["boxes"] = clampi(n, 0, Data.PLAN_BOXES_MAX)
		p["guns"][ty] = g)


## The rig packed at the gate (the meds and cures, the old Top up / Leave it): the meds chip's (merge 46).
func plan_set_top(i: int, on: bool) -> bool:
	return _plan_edit(i, func(p: Dictionary):
		p["top"] = on)


## The panel's tick, "Top the magazines up first, from the stash": the magazines' fill alone (fix 46, R2 - off, the
## meds and cures are still packed into the rig).
func plan_set_load(i: int, on: bool) -> bool:
	return _plan_edit(i, func(p: Dictionary):
		p["load"] = on)


## The plan's explicit grades the stash holds, {type: grade}: what the gate's fill swaps a magazine to and fills an
## empty one with.
func _plan_picks(p: Dictionary, counts: Dictionary) -> Dictionary:
	var out := {}
	for ty in p.get("guns", {}):
		var g: String = _plan_grade(p, str(ty))
		if g != "" and int(counts.get(g, 0)) > 0:
			out[str(ty)] = g
	return out


## The grades the fill holds to (`bg`): "Best grades only"'s; {} for none. The plan's picks are a preference, not a bar
## (fix 46, R1): they stay out of it, so a pick that runs short leaves the other magazines their own or the best grade.
func _plan_bg(p: Dictionary, counts: Dictionary) -> Dictionary:
	return best_grades(counts) if bool(p.get("best", false)) else {}


## A magazine holding another grade than the plan's pick, its rounds back to `counts` (and to the stash, `real`) so the
## fill can load the pick (the panel's "Shells ▾"): only while the stash still has some of the pick at that moment (fix 46,
## R1: a pick run out keeps the rest of the magazines as they are, filled with their own).
func _plan_swap(it: Dictionary, counts: Dictionary, picks: Dictionary, real: bool) -> void:
	var ty: String = Items.mag_type(it)
	var have: int = int(it.get("rounds", 0))
	if not picks.has(ty) or have <= 0 or str(it.get("ammo", "")) == str(picks[ty]) or str(it.get("ammo", "")) == "":
		return
	if int(counts.get(str(picks[ty]), 0)) < Items.mag_cap(it, mag_gun(it)):
		return                                # only when the pick fills it: never a full magazine swapped for a few rounds (the re-review)
	var was: String = str(it["ammo"])
	if real:
		var back: Dictionary = _plain(Data.AMMO, was)
		Items.set_stack(back, have)
		if not stash_put(back):
			stash.append(back)
	counts[was] = int(counts.get(was, 0)) + have
	it["rounds"] = 0
	it["ammo"] = ""


## The bot's boxes (BUILD46-R, the brief: "~1.2x the fight's need within its pack room, its best grade"): for the
## primary's type, the boxes that bring its rounds to BOT_ROUNDS_X the fight's want past what its magazines hold, one at
## least, a quarter of the pack at most; any other type one.
func _bot_boxes(i: int, ty: String, have: int, per: int) -> int:
	var g = equipped["Primary"]
	if g == null or Items.ammo_type(g) != ty or i < 0:
		return 1
	var want: int = _rounds_want(i)
	var box: int = maxi(1, per)
	@warning_ignore("integer_division")
	var room: int = maxi(1, capacity() / 4)
	return clampi(ceili(maxf(0.0, Data.BOT_ROUNDS_X * float(want) - float(have)) / float(box)), 1, room)


## The fight's rounds for the primary at a site: its estimate at the gun's rate, its reloads' pauses firing nothing.
func _rounds_want(i: int) -> int:
	var gun = equipped["Primary"]
	if gun == null:
		return 0
	var t := effective(i)
	return ceili(estimate(i) * float(Items.base_of(gun)["rof"]) * pace() * float(t["pace"]) * mag_share("Primary") * rate_x())


## What goes out to a site under its plan: [the primary's rounds (its magazines after the fill, and its boxes), the fight's
## want]; [] when the primary takes none.
func rounds_read(i: int) -> Array:
	var gun = equipped["Primary"]
	if gun == null or Items.ammo_type(gun) in ["", "none"] or Items.free_rounds(gun):
		return []
	var ty: String = Items.ammo_type(gun)
	var have := 0
	var mags: Array = _gate_read(i)
	for r in mags[0]:
		if Items.mag_fits(r, gun):
			have += int(r.get("rounds", 0))
	for b in mags[1]:
		if str(Items.base_of(b)["type"]) == ty:
			have += int(b["rounds"])
	return [have, _rounds_want(i)]


## The gate's read for a site: [its magazines as copies after the plan's fill, the boxes it would pack] (the stash's
## rounds by grade taken as they'd go).
func _gate_read(i: int) -> Array:
	var p: Dictionary = rounds_plan(i)
	var counts: Dictionary = _grade_counts()
	var bg: Dictionary = _plan_bg(p, counts)
	var picks: Dictionary = _plan_picks(p, counts)
	var plan: Array = _gate_mags_plan(p)
	if bool(p.get("load", true)):
		_fill_plan(plan, counts, bg, picks)
	var boxes: Array = _box_plan(counts, plan, bg, p, i) if gate_box_on(i) else []
	return [plan, boxes]


## The panel's rows (the canvas's board 2), one a worn gun's rounds type, the primary's first: {type, slot, gun, grade (what
## the gate packs), picked (the plan's own, "" for the gate's), grades [[name, rounds in the stash]] the best first,
## boxes (planned), packed (the boxes that go), loaded (its magazines' rounds after the fill), box_rounds, cells}.
func rounds_rows(i: int) -> Array:
	var p: Dictionary = rounds_plan(i)
	var read: Array = _gate_read(i)
	var counts: Dictionary = _grade_counts()
	var out: Array = []
	var types: Array = []
	for slot in ["Primary", "Secondary"]:
		var g = equipped[slot]
		if g == null or Items.mag_size(g) <= 0 or Items.ammo_type(g) in types:
			continue
		var ty: String = Items.ammo_type(g)
		types.append(ty)
		var grades: Array = []
		for k in counts:
			var b: Dictionary = Items.base_named(Data.AMMO, str(k))
			if not b.is_empty() and str(b["type"]) == ty and int(counts[k]) > 0:
				grades.append([str(k), int(counts[k])])
		var els: Array = build_elements() if slot == "Primary" else []
		grades.sort_custom(func(a, b2): return _grade_worth(Items.base_named(Data.AMMO, str(a[0])), els) > _grade_worth(Items.base_named(Data.AMMO, str(b2[0])), els))
		var loaded := 0
		var held := ""
		for r in read[0]:
			if Items.mag_fits(r, g):
				loaded += int(r.get("rounds", 0))
				if held == "" and int(r.get("rounds", 0)) > 0:
					held = str(r.get("ammo", ""))
		var box_r := 0
		var cells := 0
		var grade := ""
		for b in read[1]:
			if str(Items.base_of(b)["type"]) == ty:
				box_r += int(b["rounds"])
				cells += Items.size(b)
				grade = str(b["base"])
		var picked: String = _plan_grade(p, ty)
		if grade == "":
			grade = picked if picked != "" and int(counts.get(picked, 0)) > 0 else (held if held != "" else (str(grades[0][0]) if not grades.is_empty() else ""))
		out.append({"type": ty, "slot": slot, "gun": str(g["base"]), "grade": grade, "picked": picked, "grades": grades,
			"boxes": _plan_boxes(p, ty), "packed": cells, "loaded": loaded, "box_rounds": box_r, "cells": cells})
	return out


## Whether the plan's boxes all go (the panel's line when they don't): [boxes planned, boxes that go, the pack's cells].
func rounds_room(i: int) -> Array:
	var p: Dictionary = rounds_plan(i)
	var planned := 0
	var types: Array = []
	for slot in ["Primary", "Secondary"]:
		var g = equipped[slot]
		if g != null and Items.mag_size(g) > 0 and not (Items.ammo_type(g) in types):
			types.append(Items.ammo_type(g))
			planned += _plan_boxes(p, Items.ammo_type(g))
	var went := 0
	for b in _gate_read(i)[1]:
		went += Items.size(b)
	return [planned, went, capacity()]


## At the gate (16 Oct, Matt's playtest: the drum shotgun went dry at the Bank with 110 slugs in the stash; 30 Oct,
## magazines as items): every magazine in the rig is filled from the stash's boxes of its type, free, whatever the
## mode (loading is the game's, not the player's); then, unless the mode is "leave", pack_rig packs the rest from the
## stash and those are filled too. What's in the rig already stays. Logs what went in.
func _top_up(at := -1, site := -1) -> void:
	if mission != null:
		return
	_mags_home()                              # the magazines that came home on their guns (the fix round)
	var plan: Dictionary = rounds_plan(site if site >= 0 else at)     # the site's plan (BUILD46-R), the camp's at home
	var mode: String = _plan_mode(plan)
	var counts: Dictionary = _grade_counts()
	var bg = _plan_bg(plan, counts)     # once a top-up, from the stash before filling (the reviewer on m32c, 1), the gate's box's too
	if _bg_hold != null:
		bg = _bg_hold
	var picks: Dictionary = _plan_picks(plan, counts)
	_gate_bg = bg
	var fill_on: bool = bool(plan.get("load", true))     # the tick off (BUILD46-R): the magazines go as they are; the rig's meds still packed (fix 46, R2)
	# what the last run used (BUILD48 A, parked item 24, Matt's pick; Matt: "another annoyance is the rig constantly being
	# filled up with magazines"): the rig's magazines that came back short are filled, as before, and no more are packed
	# than went out - each worn gun's first only, when the rig holds none of its; the meds left alone by them
	var f: Array = _fill_mags(bg, picks) if fill_on else [0, []]
	var got: Array = [0, 0]
	if mode != "leave":
		got = pack_rig(mode, at, false)
		if fill_on:
			var f2: Array = _fill_mags(bg, picks)
			f = [int(f[0]) + int(f2[0]), Array(f[1]) + Array(f2[1]).filter(func(g): return not (g in f[1]))]
	if int(f[0]) > 0 or int(got[0]) > 0 or int(got[1]) > 0:
		_dry_memo.clear()
		_stats_dirty()
	if int(got[0]) > 0 or int(got[1]) > 0:
		log_event(Words.topped_up(int(got[0]), int(got[1])))
	if int(f[0]) > 0:
		log_event(Words.filled_mags(int(f[0]), f[1]))


## The worn gun a magazine feeds: the primary when it fits, else the secondary, else null (its type's own size then).
func mag_gun(it: Dictionary):
	for slot in ["Primary", "Secondary"]:
		if Items.mag_fits(it, equipped[slot]):
			return equipped[slot]
	return null


## The rig's magazines filled at home (28 Oct; 30 Oct, as items): each one short of its size, from the stash's boxes of
## its type - one holding rounds tops up with its own grade, an empty one takes the best grade the stash has (the
## build's element first, for the primary's). Free. [magazines filled, the grades' names].
func _fill_mags(bg = null, picks := {}) -> Array:
	if bg == null and top_up_mode == "best":
		bg = best_grades()
	var counts: Dictionary = _grade_counts()
	var filled := 0
	var grades: Array = []
	var order: Array = rig.filter(func(x): return Items.is_mag(x))
	order.sort_custom(func(a, b): return _mag_rank(a) < _mag_rank(b))
	for it in order:
		var gun = mag_gun(it)
		var cap: int = Items.mag_cap(it, gun)
		_plan_swap(it, counts, picks, true)    # the plan's grade in place of another (BUILD46-R)
		var have: int = int(it.get("rounds", 0))
		if have > cap:
			# over its size (a gun swapped for one with a smaller magazine): the rest back to the stash as a box of its grade
			var back: Dictionary = _plain(Data.AMMO, str(it["ammo"]))
			Items.set_stack(back, have - cap)
			if not stash_put(back):
				stash.append(back)
			counts[str(it["ammo"])] = int(counts.get(str(it["ammo"]), 0)) + have - cap
			it["rounds"] = cap
			continue
		var grade: String = _fill_grade(it, gun, counts, bg, picks)
		var n: int = mini(cap - have, int(counts.get(grade, 0))) if grade != "" else 0
		if n <= 0:
			continue
		_take_rounds(grade, n)
		counts[grade] = int(counts[grade]) - n
		it["rounds"] = have + n
		it["ammo"] = grade
		filled += 1
		if not (grade in grades):
			grades.append(grade)
	return [filled, grades]


## The grade a magazine is filled with at the gate, off `counts` (the stash's rounds by grade): its own when it holds some,
## else the best the counts have for it; on "Best grades only" (`bg`, best_grades()) that grade or none - a plainer one
## never goes in (the three-stage review, tools 3; the reviewer on m32c, 1). "" for none.
func _fill_grade(it: Dictionary, gun, counts: Dictionary, bg, picks := {}) -> String:
	var ty: String = Items.mag_type(it)
	var grade: String = str(it.get("ammo", "")) if int(it.get("rounds", 0)) > 0 else _best_in_counts(counts, ty, is_same(gun, equipped["Primary"]))
	if picks.has(ty) and int(counts.get(str(picks[ty]), 0)) > 0 and (int(it.get("rounds", 0)) <= 0 or grade == str(picks[ty])):
		return str(picks[ty])                 # the plan's pick (BUILD46-R), over "Best grades only"'s bar (fix 46: picks left bg)
	if grade == "" or (bg is Dictionary and bg.has(ty) and grade != str(bg[ty])):
		return ""
	return grade


## The gate's fill on copies, for the reads (the reviewer on m32c, 3): `mags` copies of magazines, filled as _fill_mags
## fills, off `counts`, which they take from. The rounds put in.
func _fill_plan(mags: Array, counts: Dictionary, bg, picks := {}) -> int:
	var put := 0
	var order: Array = mags.duplicate()
	order.sort_custom(func(a, b): return _mag_rank(a) < _mag_rank(b))
	for it in order:
		var gun = mag_gun(it)
		var cap: int = Items.mag_cap(it, gun)
		_plan_swap(it, counts, picks, false)
		var have: int = int(it.get("rounds", 0))
		if have > cap:
			counts[str(it["ammo"])] = int(counts.get(str(it["ammo"]), 0)) + have - cap
			it["rounds"] = cap
			continue
		var grade: String = _fill_grade(it, gun, counts, bg, picks)
		var n: int = mini(cap - have, int(counts.get(grade, 0))) if grade != "" else 0
		if n <= 0:
			continue
		counts[grade] = int(counts[grade]) - n
		it["rounds"] = have + n
		it["ammo"] = grade
		put += n
	return put


## The stash's rounds by grade.
func _grade_counts() -> Dictionary:
	var out := {}
	for it in stash:
		if Items.is_ammo(it) and int(it.get("rounds", 0)) > 0:
			out[str(it["base"])] = int(out.get(str(it["base"]), 0)) + int(it["rounds"])
	return out


## The best grade of a type in `counts`, by name: the primary's, its build's element first. "" for none.
func _best_in_counts(counts: Dictionary, ty: String, primary: bool) -> String:
	var els: Array = build_elements() if primary else []
	var best := ""
	var bv := -1
	for g in counts:
		if int(counts[g]) <= 0:
			continue
		var b: Dictionary = Items.base_named(Data.AMMO, str(g))
		if b.is_empty() or str(b["type"]) != ty:
			continue
		var v: int = _grade_worth(b, els)
		if v > bv:
			best = str(g)
			bv = v
	return best


## "Best grades only": a type's best grade in the stash, worked out once before a fill (the reviewer on m32c: after the
## fill had taken it, a second reading went to the plainer grade; counting the rig's grades refused the stash's shells
## for a part-spent magazine of slugs) and handed to whatever reads it after - the top-up's fills, the gate's box.
## A magazine already holding a grade keeps it, never mixed. {type: grade}.
var _gate_bg = null              # the last top-up's, for the gate's box after the fill
var _bg_hold = null              # a repeat run's, worked out before its own fills, for the gate's top-up
func best_grades(counts = null) -> Dictionary:
	if counts == null:
		counts = _grade_counts()
	var cand: Dictionary = counts
	var pty: String = Items.ammo_type(equipped["Primary"]) if equipped["Primary"] != null else ""
	var out := {}
	var types: Array = []
	for g in cand:
		var b: Dictionary = Items.base_named(Data.AMMO, str(g))
		if not b.is_empty() and not (str(b["type"]) in types):
			types.append(str(b["type"]))
	for ty in types:
		out[ty] = _best_in_counts(cand, ty, ty == pty)
	return out


## The magazines the gate would fill, as copies (the reads): the rig's, and on a top-up the stash's the packing may still
## put in the pouches its magazines' share leaves - each worn gun's, the primary's first (rounds_short's rule, 16 Oct).
func _gate_mags_plan(p = null) -> Array:
	var out: Array = rig.filter(func(x): return Items.is_mag(x)).map(func(x): return x.duplicate())
	if (p is Dictionary and bool(p.get("top", true))) or (p == null and top_up_mode != "leave"):
		var pouches: int = mini(mag_pouch_room(), med_capacity() - rig_used())
		for slot in ["Primary", "Secondary"]:     # each gun's first alone, when the rig has none of its (BUILD48 A, item 24: pack_rig's gate)
			var g = equipped[slot]
			if g == null or out.any(func(x): return Items.mag_fits(x, g)):
				continue
			for r in stash:
				if Items.mag_fits(r, g) and Items.size(r) <= pouches and not out.any(func(x): return int(x["id"]) == int(r["id"])):
					pouches -= Items.size(r)
					out.append(r.duplicate())
					break
	return out


## The filling's order: the primary's magazines, then the secondary's, then any other.
func _mag_rank(it: Dictionary) -> int:
	if Items.mag_fits(it, equipped["Primary"]):
		return 0
	return 1 if Items.mag_fits(it, equipped["Secondary"]) else 2


## The rig packed from the stash (28 Oct, Matt, the review: magazines then cures left a Bum bag no heal; 30 Oct,
## magazines as items): HEAL, MAGAZINE, CURE - at least one heal and one of the primary's magazines first, when the rig
## has the room and the stash has them; then a cure for each of the front's elements (TOP_UP_CURES at most); then the
## rest, the primary's magazines and then the secondary's up to RIG_MAG_SHARE of the rig's pouches (one kept for a
## secondary firing another type), the heals the pouches left. A magazine is packed only with rounds to fill it (in it,
## or a box of its type in the stash). "best" takes the best heal alone. What's in the rig already stays. The gate's
## top-up and the bot pack by it. [magazines moved, meds and cures in].
## `mags_share` off (the watched gate's top-up, BUILD48 A, item 24): no magazines past each worn gun's first (one when the
## rig holds none of its type), and no heal put back for their share - the meds left alone by the magazines.
func pack_rig(mode := "fill", at := -1, mags_share := true) -> Array:
	if mission != null:
		return [0, 0]
	var lists: Array = []
	for slot in ["Primary", "Secondary"]:
		var gun = equipped[slot]
		if gun == null or Items.mag_size(gun) <= 0:
			continue
		var t := Items.ammo_type(gun)
		var boxes: bool = stash.any(func(x): return Items.is_ammo(x) and str(Items.base_of(x)["type"]) == t and int(x.get("rounds", 0)) > 0)
		var mags: Array = stash.filter(func(x): return Items.mag_fits(x, gun) and (boxes or int(x.get("rounds", 0)) > 0))
		# the most rounds first: loaded, then the biggest; a drum's two pouches weighed against two of the gun's own
		mags.sort_custom(func(a, b): return float(a.get("rounds", 0)) * 1000.0 + float(Items.mag_cap(a, gun)) / float(Items.size(a)) > float(b.get("rounds", 0)) * 1000.0 + float(Items.mag_cap(b, gun)) / float(Items.size(b)))
		lists.append([t, mags])
	var meds: Array = stash.filter(func(x): return Items.is_heal(x))
	meds.sort_custom(func(a, b): return med_heal(a) > med_heal(b))
	if mode == "best" and not meds.is_empty():
		var top_med: String = str(meds[0]["base"])
		meds = meds.filter(func(x): return str(x["base"]) == top_med)
	var moved := 0
	var meds_in := 0
	# the primary's own magazines (29 Oct, the stall: a pouch of nails left from an old gun read as "magazines in", and
	# the new gun's first never came)
	var has_mags: bool = not lists.is_empty() and rig.any(func(x): return Items.is_mag(x) and Items.mag_type(x) == str(lists[0][0]))
	var mags_to_come: bool = not has_mags and not lists.is_empty() and not lists[0][1].is_empty()
	# HEAL, MAGAZINE, CURE (29 Oct, the stall: what stayed in the rig from before - two cures and a two-pouch kit in a
	# four-pouch rig - sent the runner out with 1,500 shells in the stash and none in the gun, the bot for hours): the
	# primary's first magazine comes before magazines neither gun fires, a cure, or any heal but the best, so those go
	# back to the stash, in that order, until there's room for it (and a heal, when none is in)
	if mags_to_come and med_capacity() > 0:
		var fired: Array = lists.map(func(l): return str(l[0]))
		var need_room: int = Items.size(lists[0][1][0])     # the magazine (a drum two); and with no heal in, the smallest heal the stash has beside it
		if not meds.is_empty() and not rig.any(func(x): return Items.is_heal(x)):
			need_room += meds.map(func(x): return Items.size(x)).min()
		var best_heal = null
		for it in rig:
			if Items.is_heal(it) and (best_heal == null or med_heal(it) > med_heal(best_heal)):
				best_heal = it
		var out_first: Array = rig.filter(func(x): return Items.is_mag(x) and not (Items.mag_type(x) in fired))
		var cures: Array = rig.filter(func(x): return Items.is_cure(x))
		cures.reverse()
		out_first += cures
		out_first += rig.filter(func(x): return Items.is_heal(x) and x != best_heal)
		for it in out_first:
			if rig_room(need_room):
				break
			_rig_leave(int(it["id"]))
	# one heal: the best that leaves room for the magazine to come
	if not rig.any(func(x): return Items.is_heal(x)):
		var keep: int = Items.size(lists[0][1][0]) if mags_to_come else 0
		for it in meds:
			if rig_room(Items.size(it) + keep) and _rig_take(int(it["id"])):
				meds_in += 1
				break
		if meds_in == 0 and keep > 0:
			for it in meds:
				if rig_room(Items.size(it)) and _rig_take(int(it["id"])):
					meds_in += 1                  # no room for both: the heal first, as Matt's order has it
					break
	# one of the primary's magazines
	if mags_to_come:
		moved += _pack_mags(lists[0][1], Items.size(lists[0][1][0]))
	# the cures: one for each element the front's gangs throw, the heaviest first, a pouch each; a repeat's, its own
	# site's (S9: `at`, the site it's going to): a cure for another zone goes back to the stash for one of them
	var cure_els: Array = zone_elements(front_tier() if at < 0 else at).slice(0, Data.TOP_UP_CURES)
	for ty in cure_els:
		if not first_cure(ty).is_empty():
			continue
		if at >= 0 and not rig_room(1) and stash.any(func(x): return Items.cure_of(x) == ty):
			for c in rig.filter(func(x): return Items.is_cure(x) and not (Items.cure_of(x) in cure_els)):
				if _rig_leave(int(c["id"])):
					break
		if not rig_room(1):
			continue
		for it in stash:
			if Items.cure_of(it) == ty:
				if _rig_take(int(it["id"])):
					meds_in += 1
				break
	# the magazines' share before spare heals (30 Oct, the clean-up's R2: a rig filled with heals while a bat was worn kept
	# them over the next gun's magazines - one pouch of rounds, run after run): heals past the best go back to the stash
	# while the primary's magazines are under their share and more of them are in the stash
	if mags_share and not lists.is_empty() and not lists[0][1].filter(func(x): return stash.has(x)).is_empty():
		var best_h = null
		for it in rig:
			if Items.is_heal(it) and (best_h == null or med_heal(it) > med_heal(best_h)):
				best_h = it
		var spare: Array = rig.filter(func(x): return Items.is_heal(x) and x != best_h)
		spare.reverse()
		for it in spare:
			if med_capacity() - rig_used() >= mag_pouch_room():
				break
			_rig_leave(int(it["id"]))
	# the rest: the magazines to their share - the primary's, then the secondary's (one kept for it when it fires another
	# type; the same type shares the primary's)
	var room: int = mini(mag_pouch_room(), med_capacity() - rig_used())
	var two_types: bool = lists.size() > 1 and str(lists[1][0]) != str(lists[0][0]) and not lists[1][1].is_empty() \
		and not rig.any(func(x): return Items.is_mag(x) and Items.mag_type(x) == str(lists[1][0]))
	var prim_in: bool = not lists.is_empty() and rig.any(func(x): return Items.is_mag(x) and Items.mag_type(x) == str(lists[0][0]))
	var sec_need: int = Items.size(lists[1][1][0]) if two_types else 0
	var sec_quota: int = sec_need if two_types and (room >= sec_need + 1 or (room >= sec_need and prim_in)) else 0     # the primary's in already: the secondary's the next
	var quotas: Array = [room - sec_quota, sec_quota]
	for li in range(lists.size()):
		if mags_share:
			moved += _pack_mags(lists[li][1], int(quotas[li]))
		elif not lists[li][1].is_empty() and not rig.any(func(x): return Items.is_mag(x) and Items.mag_type(x) == str(lists[li][0])):
			moved += _pack_mags(lists[li][1], Items.size(lists[li][1][0]))     # a gun's first, never dead for want of one
	# and the heals, the best first, a pouch each while the rig has one
	for it in meds:
		if not stash.has(it) or not rig_room(Items.size(it)):
			continue                              # a kit takes two pouches; a bandage after it may still fit
		if _rig_take(int(it["id"])):
			meds_in += 1
	return [moved, meds_in]


## Magazines into the rig from this list, in its order, up to `pouches` pouches' worth (a drum two). The magazines moved.
func _pack_mags(mags: Array, pouches: int) -> int:
	var moved := 0
	var used := 0
	for it in mags:
		if not stash.has(it) or used + Items.size(it) > pouches or not rig_room(Items.size(it)):
			continue
		if _rig_take(int(it["id"])):
			used += Items.size(it)
			moved += 1
	return moved


## The pouches the gate's top-up may still give magazines (28 Oct): RIG_MAG_SHARE of the rig, less those holding one.
func mag_pouch_room() -> int:
	var held := 0
	for x in rig:
		if Items.is_mag(x):
			held += Items.size(x)
	return maxi(0, ceili(med_capacity() * Data.RIG_MAG_SHARE) - held)



## The elements a site's gangs throw, the heaviest first (28 Oct): what a cure is packed for. Its zone's own mix.
func zone_elements(i: int) -> Array:
	var types: Dictionary = Data.ZONE_TYPES[int(Data.TIERS[clampi(i, 0, Data.TIERS.size() - 1)]["zone"])]["types"]
	var out: Array = types.keys().filter(func(ty): return ty in Data.ELEMENTS)
	out.sort_custom(func(a, b): return float(types[a]) > float(types[b]))
	return out


## A gun put on with no magazine for it in the rig (13 Oct, the review: Equip if better put the rifle on and the runner
## went out with its box still in the stash; 30 Oct, as items): one of the stash's magazines that fits it to the rig,
## a magazine no worn gun fires going back to the stash for the room, and filled from the boxes.
func _feed(gun: Dictionary) -> void:
	if mission != null or Items.mag_size(gun) <= 0 or not mags_for(gun).is_empty():
		return
	var mag := {}
	for it in stash:
		if Items.mag_fits(it, gun) and (mag.is_empty() or int(it.get("rounds", 0)) > int(mag.get("rounds", 0))):
			mag = it
	if mag.is_empty():
		return
	if not rig_room(Items.size(mag)):
		for it in rig.duplicate():
			if Items.is_mag(it) and not Items.mag_fits(it, equipped["Primary"]) and not Items.mag_fits(it, equipped["Secondary"]):
				_rig_leave(it["id"])
				if rig_room(Items.size(mag)):
					break
	if _rig_take(mag["id"]):
		_fill_mags()



## A particular stash item, by id, into its slot; what was fitted goes to the stash.
func equip_item(id: int) -> bool:
	if not can_equip_item(id):
		return false
	for it in stash:
		if it["id"] == id:
			var slot: String = it["slot"]
			_remove(it)
			chron("equip", {"slot": slot, "how": "hand", "on": _chron_item(it), "off": _chron_item(equipped[slot])})
			if equipped[slot] != null:
				stash.append(equipped[slot])
			equipped[slot] = it
			_stats_dirty()
			if slot == "Rig":
				_rig_shed()
			return true
	return false


## What a rig would leave over (30 Oct, the playtest's item 1: a Body warmer kept the Bum bag's three bandages): the
## rig's pieces past its pouches with `rig_it` worn, the last packed first.
func rig_overflow(rig_it) -> Array:
	var was = equipped["Rig"]
	equipped["Rig"] = rig_it
	_dry_memo.clear()
	_stats_dirty()
	var cap: int = med_capacity()
	equipped["Rig"] = was
	_dry_memo.clear()
	_stats_dirty()
	var used: int = rig_used()
	var out: Array = []
	var k: int = rig.size() - 1
	while used > cap and k >= 0:
		out.append(rig[k])
		used -= Items.size(rig[k])
		k -= 1
	return out


## A smaller rig on: what's over its pouches back to the stash, the last packed first, and the log says what.
func _rig_shed(line := Words.SMALLER_RIG) -> void:
	var back: Array = []
	while rig_used() > med_capacity() and not rig.is_empty():
		var it: Dictionary = rig.pop_back()
		if not stash_put(it):
			stash.append(it)                  # can_equip_item checked the room: never lost
		back.append(it)
	if not back.is_empty():
		_dry_memo.clear()
		_stats_dirty()
		var th: Array = _things(back)
		log_event(line % Words.things_list(th[0], th[1]))     # repeats counted (the three-stage review, UI 13)


## Whether a stash item can go into its slot now: not on a run, and what it
## replaces must fit in the stash once the new one has left it (footprints
## differ - a riot suit coming off needs more room than a stab vest going on).
func can_equip_item(id: int) -> bool:
	if runner_busy():                    # out, or away on a repeat (29 Oct): the kit's with them
		return false
	for it in stash:
		if it["id"] == id:
			var slot: String = it["slot"]
			if not equipped.has(slot) or not can_wear(it):
				return false
			var over := 0
			if slot == "Rig":
				for o in rig_overflow(it):
					over += 0 if stash_free(o) else Items.size(o)     # a smaller rig's overflow goes to the stash (30 Oct): it needs the room
			if equipped[slot] == null and over == 0:
				return true
			var out_cells: int = 0 if stash_free(it) or tab_of(it) != "" else Items.size(it)     # a piece off a class's tab frees none of the shared tab's
			var in_cells: int = 0 if equipped[slot] == null or stash_free(equipped[slot]) else Items.size(equipped[slot])
			return stash_used() - out_cells + in_cells + over <= stash_cap()
	return false


## A med from the stash into the rig, if there's a slot for it. Not while the runner's busy (T4: between a repeat's
## runs too); the gate's own packing goes by _rig_take.
func take(id: int) -> bool:
	if runner_busy():
		return false
	if not _rig_take(id):
		return false
	if rig.any(func(x): return int(x["id"]) == id and Items.is_mag(x)):
		_fill_mags()                          # filled from the stash's boxes, as Swap does (the three-stage review, UI 2)
		_dry_memo.clear()
		_stats_dirty()
	return true


func _rig_take(id: int) -> bool:
	if mission != null:
		return false
	return _take_from(stash, id)


## Gear found out there, fitted while the run's on (Matt, 6 Oct): what comes off goes into the pack in its place when
## the cells the swap frees hold it, else to the floor (1 Nov, Matt's playtest: "I'd just swap jackets"); a bag's what's
## carried repacked in the new one, what it can't hold to the floor, the old bag placed after (the review: never the
## empty bag kept and the loot spilled); a smaller rig's overflow into the pack where it lies, the rest to the floor.
## Never blocked for room: the rules a piece is worn by are wearable_on_run's, the floor's swap's too.
func can_equip_from_pack(id: int) -> bool:
	if mission == null:
		return false
	for it in mission["found"]:
		if it["id"] == id:
			return wearable_on_run(it)
	return false


## The rules a find is worn by on a run, from the pack or off the floor (1 Nov: one place for both, the pick card's too):
## a slot the runner has, never the deeds, and the runner's level (can_wear) - `any_level`, the level left out (a piece
## that waits on a padlock).
func wearable_on_run(it: Dictionary, any_level := false) -> bool:
	return equipped.has(str(it.get("slot", ""))) and not Items.is_deeds(it) and (any_level or can_wear(it))


## A piece as the log names it (the review: a base never lowered in code): a unique by its name, a base as it is, or
## mid-sentence by Words.mid_base.
static func _log_name(it: Dictionary, mid := false) -> String:
	if it.has("unique"):
		return str(it["unique"])
	return Words.mid_base(str(it["base"])) if mid else str(it["base"])


func equip_from_pack(id: int) -> bool:
	if not can_equip_from_pack(id):
		return false
	var m: Dictionary = mission
	for k in range(m["found"].size()):
		var it: Dictionary = m["found"][k]
		if it["id"] == id:
			var slot: String = it["slot"]
			var was = equipped[slot]
			var spot: Array = [] if slot == "Backpack" or was == null else _pack_swap_spot(m, it, was)
			m["found"].remove_at(k)
			pack_off(it)
			it.erase("head_drop")                    # worn: the runner's now
			if was != null:
				was["spared"] = true                 # what he had on: his, not loot
				if slot != "Backpack":
					if spot.is_empty():
						_floor_put(m, was)            # no place in the cells freed (1 Nov): down, not blocked
						log_event(Words.LOG["equipped_to_floor"] % [_log_name(it), _log_name(was, true)])
					else:
						_pack_put(m, was, spot)
						log_event(Words.LOG["equipped_into_pack"] % [_log_name(it), _log_name(was, true)])
			else:
				log_event(Words.LOG["equipped"] % _log_name(it))
			chron("equip", {"slot": slot, "how": "pack", "on": _chron_item(it), "off": _chron_item(was)})
			equipped[slot] = it
			_stats_dirty()
			_worn_on_run(m, it, slot, was)
			return true
	return false


## A piece just worn on a run, from the pack or off the floor: a gun loads its own magazine, a bag repacks what's carried
## (what it can't hold to the floor, then `bag_was` - the old bag from the pack - placed, else down), a smaller rig's
## overflow into the pack where it lies and the rest down, HP held to the new most.
func _worn_on_run(m: Dictionary, it: Dictionary, slot: String, bag_was = null) -> void:
	if m.has("mag_in"):
		m["mag_in"].erase(slot)           # a gun picked up loads its own magazine (28 Oct)
		m["reload_t"].erase(slot)
		m["reload_to"].erase(slot)
	_mag_from_pack(m, it)
	_read(it)
	_dry_memo.clear()
	_stats_dirty()
	var down: Array = []
	if slot == "Backpack":
		var plan: Dictionary = _bag_settle(m, bag_was)
		down = plan["down"]
		if bag_was != null:
			log_event(Words.LOG["equipped_to_floor" if plan["off"] else "equipped_into_pack"] % [_log_name(it), _log_name(bag_was, true)])
	elif slot == "Rig":
		var over: Array = []
		while rig_used() > med_capacity() and not rig.is_empty():
			over.append(rig.pop_back())       # the last packed first, as rig_overflow reads it
		var spots: Array = _rig_over_spots(m, over, _pack_taken(m))
		for j in range(over.size()):
			var r: Dictionary = over[j]
			if spots[j].is_empty():
				_floor_put(m, r)
				down.append(r)
			else:
				r["from_rig"] = true          # the runner's own: home to the rig, as rig_to_pack's (the review)
				_pack_put(m, r, spots[j])
		_dry_memo.clear()
		_stats_dirty()
	if not down.is_empty():
		var th: Array = _things(down)
		log_event(Words.LOG["to_floor"] % Words.things_list(th[0], th[1]))
	if hp > max_hp():
		hp = max_hp()


## A bag just worn (on `m`, the live run's or a copy's): what's carried packed afresh in it, what it can't place down
## (what must come home, _spill_keeps, stays strapped on), then `was` - the old bag, from the pack - placed where it
## lies, else down. {"down": what went down, "off": whether `was` did}.
func _bag_settle(m: Dictionary, was) -> Dictionary:
	_pack_repack(m)
	var down: Array = []
	for f in m["found"].duplicate():
		if f.get("strapped", false) and not _spill_keeps(f):
			m["found"].erase(f)
			_floor_put(m, f)
			down.append(f)
	var off := false
	if was != null:
		var sp: Array = _pack_first(m, was, _pack_taken(m, int(was["id"])))
		if sp.is_empty():
			_floor_put(m, was)
			off = true
		else:
			_pack_put(m, was, sp)
	return {"down": down, "off": off}


## Where a smaller rig's overflow lies in the pack, each in turn (cells `taken` already): [x, y, rot], or [] for the floor.
func _rig_over_spots(m: Dictionary, over: Array, taken: Dictionary) -> Array:
	var tk: Dictionary = taken.duplicate()
	var w := pack_w()
	var out: Array = []
	for r in over:
		var sp: Array = _pack_first(m, r, tk)
		out.append(sp)
		if sp.is_empty():
			continue
		var fp := pack_fp(r, bool(sp[2]))
		for yy in range(fp.y):
			for xx in range(fp.x):
				tk[(int(sp[1]) + yy) * w + int(sp[0]) + xx] = -1
	return out


## Off the floor and worn (1 Nov, Matt's playtest: "realistically why would I take off my current jacket, stuff it into
## the pack, then equip the new jacket I just found on the floor - I'd just swap jackets"): the piece it replaces goes
## on the floor, never into the pack; the new one needs no room. A bag: the old one down, what's carried repacked in the
## new one, what it can't hold down too; a rig: its overflow into the pack where it lies, the rest down. The floor has no
## cap, so a swap is never refused for it.
func can_wear_from_floor(id: int) -> bool:
	for it in floor_items():
		if int(it["id"]) == id:
			return wearable_on_run(it)
	return false


func wear_from_floor(id: int) -> bool:
	if not can_wear_from_floor(id):
		return false
	var m: Dictionary = mission
	var fl: Array = m["floor"]
	for k in range(fl.size()):
		var it: Dictionary = fl[k]
		if int(it["id"]) != id:
			continue
		var slot: String = it["slot"]
		var was = equipped[slot]
		fl.remove_at(k)
		pack_off(it)
		it.erase("head_drop")                 # worn: the runner's now
		it["spared"] = true                   # taken off the floor by hand: chosen (as take_floor)
		if was != null:
			was["spared"] = true              # what he had on: his, not loot, should he pick it up again
			_floor_put(m, was)
			log_event(Words.LOG["equipped_to_floor"] % [_log_name(it), _log_name(was, true)])
		else:
			log_event(Words.LOG["equipped"] % _log_name(it))
		chron("equip", {"slot": slot, "how": "floor", "on": _chron_item(it), "off": _chron_item(was)})
		equipped[slot] = it
		_stats_dirty()
		_worn_on_run(m, it, slot)
		return true
	return false


## What wearing a find leaves on the floor, read before it's worn (the pick card says it first): {"off": the piece coming
## off when it goes down, else null; "spill": what goes down besides}. For a find in the pack or on the floor.
func wear_preview(id: int) -> Dictionary:
	if mission == null:
		return {"off": null, "spill": []}
	# kept per pick and pack (BUILD43, perf43's spike: a bag's spill read 31-43 ms a paint, ten paints a second): the
	# find, the worn kit, the pack and the floor as they lie, the rig's pieces
	var key: int = hash([id, _kit_ids(), mission["found"], mission.get("floor", []), rig.map(func(x): return int(x.get("id", -1))), capacity(), med_capacity(), pack_w()])     # the pack's and the rig's shape too (review 43, 8)
	if key != _wear_pv_key or not is_same(mission, _wear_pv_m):
		_wear_pv_m = mission
		_wear_pv_key = key
		_wear_pv = _wear_preview_raw(id)
	return _wear_pv
var _wear_pv_key := 0
var _wear_pv_m = null
var _wear_pv := {}


func _wear_preview_raw(id: int) -> Dictionary:
	var out := {"off": null, "spill": []}
	if mission == null:
		return out
	var m: Dictionary = mission
	var it: Dictionary = {}
	var on_floor := false
	for f in floor_items():
		if int(f["id"]) == id:
			it = f
			on_floor = true
	for f in m["found"]:
		if int(f["id"]) == id:
			it = f
	if it.is_empty() or not equipped.has(str(it["slot"])):
		return out
	var slot: String = it["slot"]
	var was = equipped[slot]
	if slot == "Backpack":
		var pv: Dictionary = _bag_spill(m, it, null if on_floor else was)
		if was != null and (on_floor or pv["off"]):
			out["off"] = was
		var ids: Dictionary = {}
		for i in pv["down"]:
			ids[i] = true
		out["spill"] = m["found"].filter(func(f): return ids.has(int(f["id"])))
		return out
	var spot: Array = [] if was == null or on_floor else _pack_swap_spot(m, it, was)
	if was != null and spot.is_empty():
		out["off"] = was
	if slot == "Rig":
		var over: Array = rig_overflow(it)
		var tk: Dictionary = _pack_taken(m, int(it["id"]))
		if not spot.is_empty():
			var fp := pack_fp(was, bool(spot[2]))
			for yy in range(fp.y):
				for xx in range(fp.x):
					tk[(int(spot[1]) + yy) * pack_w() + int(spot[0]) + xx] = -1     # the old rig where it'll lie
		var spots: Array = _rig_over_spots(m, over, tk)
		var down: Array = []
		for j in range(over.size()):
			if spots[j].is_empty():
				down.append(over[j])
		out["spill"] = down
	return out


## What a bag put on would leave down, read on copies (the review: nothing live moved and put back): the pack's pieces
## but `bag`, and `was` (the old bag, from the pack) to place after, packed in `bag` as _bag_settle does. Only the bag worn
## is tried on for the shape's reads (pack_w, capacity), and put back. {"down": the ids that go down, "off": `was` too}.
func _bag_spill(m: Dictionary, bag: Dictionary, was) -> Dictionary:
	# BUILD45 (perf44 4: the first pick up to 1.5 s): the packing moves only a piece's own place ("pos", "rot", "strapped",
	# set or taken off whole), so each piece is a shallow copy, not a deep one; and the stats read for the bag tried on
	# are kept apart, the memo of the kit as it is put back as it was (dirtied, it read the whole kit afresh after)
	var scratch := {"found": [], "floor": []}
	for f in m["found"]:
		if int(f["id"]) != int(bag["id"]):
			scratch["found"].append(f.duplicate())
	var memo_was: Dictionary = _live_memo
	var ctx_was = _live_ctx_at
	var state_was = _live_state_at
	_live_memo = {}
	var worn = equipped["Backpack"]
	equipped["Backpack"] = bag
	_stats_dirty()
	var plan: Dictionary = held_pack(_bag_settle.bind(scratch, was.duplicate() if was != null else null))
	equipped["Backpack"] = worn
	_stats_dirty()
	_live_memo = memo_was                     # the kit as it was, read as it was
	_live_ctx_at = ctx_was
	_live_state_at = state_was
	return {"down": plan["down"].map(func(f): return int(f["id"])), "off": plan["off"]}


## Onto the floor (a swap's piece coming off, what a bag or rig can't hold): its place in the pack forgotten.
func _floor_put(m: Dictionary, it: Dictionary) -> void:
	pack_off(it)
	m["floor"] = m.get("floor", [])
	m["floor"].append(it)


## What never goes down on the floor: the runner's own rounds and the gate's box, the deeds (put_down's rule).
static func _stays_up(f: Dictionary) -> bool:
	return f.get("from_rig", false) or f.get("carried", false) or Items.is_deeds(f)


## What a bag swap never spills (the review): _stays_up's, and what was strapped on to come home - the first gun, a
## head's keepsake paper, the runner's own taken back off a gang (recovered: "spared" alone is every find taken by hand),
## a head's drop.
static func _spill_keeps(f: Dictionary) -> bool:
	return _stays_up(f) or f.get("first_gun", false) or Items.opens(f) != "" or f.get("recovered", false) or f.get("head_drop", false)


## A gun fitted from the pack (30 Oct, the playtest's item 4): with no magazine for it in the rig, the pack's one that
## fits goes in, room permitting - found with the gun, it's the gun's own.
func _mag_from_pack(m: Dictionary, gun: Dictionary) -> void:
	if gun.has("mag_item"):
		var own: Dictionary = gun["mag_item"]
		if mags_for(gun).is_empty() and _rig_room_for(m, own, gun):
			gun.erase("mag_item")
			rig.append(own)                   # the gun's own, into the rig (the fix round: it travels on the gun)
			return
	if Items.mag_size(gun) <= 0 or not mags_for(gun).is_empty():
		return
	for f in m["found"].duplicate():
		if Items.mag_fits(f, gun) and not a51_hand_out(m, f) and _rig_room_for(m, f, gun):     # never one the player took out (BUILD51-A)
			m["found"].erase(f)
			pack_off(f)
			f.erase("first_gun")
			rig.append(f)
			return


## Room in the rig for a gun's magazine on a run (the three-stage review, game 1: a fresh camp's first gun found with the
## Bum bag full of bandages never fired): with no free pouch, the rig's last-packed heals go into the pack, where it has
## the spots, till the magazine fits - the runner's own (home to the rig), and the log lists them. False, nothing moved,
## when the heals and the pack can't make the room.
func _rig_room_for(m: Dictionary, mag: Dictionary, gun: Dictionary) -> bool:
	var need: int = Items.size(mag)
	if rig_room(need):
		return true
	if int(m.get("remaining", 0)) > 0 and not _a51_quiet:
		return false                          # no heal out while the site has men left (remaining: the whole pool, the quiet between gangs too), unless it's the quiet's own pull (a51_quiet_pull: a gun fitted in the quiet gets its magazine as the next gang comes) (BUILD51-A; FIX51 the words)
	var heals: Array = []
	var freed := 0
	for k in range(rig.size() - 1, -1, -1):
		if rig_used() - freed + need <= med_capacity():
			break
		var it: Dictionary = rig[k]
		if Items.is_medical(it) and not Items.is_cure(it):
			heals.append(it)
			freed += Items.size(it)
	if rig_used() - freed + need > med_capacity():
		return false
	_pack_settle(m)
	var spots: Array = []
	var taken: Dictionary = _pack_taken(m, int(mag.get("id", -1)))     # the pack magazine about to leave frees its cells (the reviewer on m32c, 7)
	var pw := pack_w()
	for h in heals:
		var sp: Array = _pack_first(m, h, taken)
		if sp.is_empty():
			return false
		spots.append(sp)
		var fp := pack_fp(h, bool(sp[2]))
		for yy in range(fp.y):
			for xx in range(fp.x):
				taken[(int(sp[1]) + yy) * pw + int(sp[0]) + xx] = -1
	for k in range(heals.size()):
		var h: Dictionary = heals[k]
		rig.erase(h)
		h["from_rig"] = true                  # the runner's own: home to the rig, not loot
		_pack_put(m, h, spots[k])
	var th: Array = _things(heals)
	log_event(Words.MADE_ROOM % [Words.things_list(th[0], th[1]), Words.mid_base(str(gun["base"]))])
	_dry_memo.clear()
	_stats_dirty()
	return true


## A med or rounds found out there, into the rig while the run's on.
## Rounds out of the rig and into the pack on a run (11 Oct, Matt: a better rifle and its rounds found, and the rig
## full of the shotgun's shells with no way to make room). Needs the cells in the pack; never what's being used.
func can_rig_to_pack(id: int) -> bool:
	if mission == null:
		return false
	for it in rig:
		if int(it["id"]) == id:
			return Items.is_mag(it) and not pack_spot(mission, it).is_empty()     # a magazine only (30 Oct): a med is used, never stowed
	return false


func rig_to_pack(id: int) -> bool:
	if not can_rig_to_pack(id):
		return false
	for k in range(rig.size()):
		if int(rig[k]["id"]) == id:
			var it: Dictionary = rig[k]
			rig.remove_at(k)
			it["from_rig"] = true              # the runner's own: home to the rig, not counted as loot
			a51_mark_hand_out(mission, it, true)     # out by hand: it stays out till the player puts it back (BUILD51-A)
			_pack_put(mission, it, pack_spot(mission, it))
			log_event(Words.LOG["into_pack"] % it["base"])
			return true
	return false


## Where `was` (coming off) lies in the pack once `it` (going on) has left it: where `it` lay first, else anywhere.
func _pack_swap_spot(m: Dictionary, it: Dictionary, was: Dictionary) -> Array:
	_pack_settle(m)
	var tk := _pack_taken(m, int(it["id"]))
	if it.has("pos"):
		for rot in [false, true]:
			if pack_free_at(m, was, int(it["pos"][0]), int(it["pos"][1]), rot, tk):
				return [int(it["pos"][0]), int(it["pos"][1]), rot]
	return _pack_first(m, was, tk)


func take_from_pack(id: int) -> bool:
	if mission == null:
		return false
	var ok: bool = _take_from(mission["found"], id)
	if ok:
		a51_mark_hand_out(mission, {"id": id}, false)     # put back by hand (BUILD51-A)
	return ok


## Whether a drop tops up something in the rig with no pouch free: nothing does now (30 Oct: rounds never go in the
## rig; a magazine takes its own pouch).
func rig_tops_up(_it: Dictionary) -> bool:
	return false


func _take_from(src: Array, id: int) -> bool:
	for it in src:
		if it["id"] == id and Items.rig_item(it):
			if Items.is_medical(it) and has_rule("the_float"):
				return false                    # the Float carries no meds (18 Oct)
			if not rig_room(Items.size(it)):
				return false
			src.erase(it)
			pack_off(it)
			rig.append(it)
			return true
	return false


## Whether a stack would merge into the stash entirely without a cell.
func _stack_room(it: Dictionary) -> bool:
	var left: int = Items.stack_size(it)
	for s in stash:
		if Items.same_stack(s, it):
			left -= Items.stack_cap(s) - Items.stack_size(s)
	return left <= 0


## A med out of the rig, back to the stash. Not while the runner's busy (T4); the gate's own packing goes by _rig_leave.
func leave(id: int) -> bool:
	if runner_busy():
		return false
	return _rig_leave(id)


func _rig_leave(id: int) -> bool:
	if mission != null:
		return false
	var leaving := {}
	for r in rig:
		if r["id"] == id:
			leaving = r
	if leaving.is_empty() or not (stash_fits(leaving) or _stack_room(leaving)):
		return false
	for k in range(rig.size()):
		if rig[k]["id"] == id:
			var it: Dictionary = rig[k]
			rig.remove_at(k)
			stash_put(it)
			return true
	return false


func unequip(slot: String) -> bool:
	if runner_busy() or equipped[slot] == null or not stash_fits(equipped[slot]):
		return false
	if slot == "Rig":
		# the rig off: what's in it to the stash, as a smaller rig's overflow (the fix round, D); refused with no room
		var need: int = 0 if stash_free(equipped[slot]) else Items.size(equipped[slot])
		for it in rig:
			need += 0 if stash_free(it) else Items.size(it)
		if stash_used() + need > stash_cap():
			return false
	stash.append(equipped[slot])
	equipped[slot] = null
	_stats_dirty()
	if slot == "Rig":
		_rig_shed(Words.RIG_OFF)
	return true


# ------------------------------------------------------------------ the black market

## The best gear tier any open site drops: what the Fence and the Clinic stock.
func gear_tier() -> int:
	var t := 1
	for i in range(Data.TIERS.size()):
		if tier_open(i):
			t = maxi(t, int(Data.TIERS[i]["loot_tier"]))
	return t


func restock() -> void:
	_restock_clinic()
	_restock_gamble()
	_restock_market()


## The Fence's shelf, rolled afresh.
func _restock_market() -> void:
	market = []
	var t := best_tier_open()                # the best tier open, the endgame's too (29 Oct, the review)
	var deep_lv := -1
	for k in range(market_stock()):
		var slot: String = Data.SLOTS[rng.randi_range(0, Data.SLOTS.size() - 1)]
		var roll := rng.randf()
		if roll < 0.3:
			slot = Data.ATTACHMENT
		elif roll < 0.45:
			slot = Data.AMMO
		elif roll < 0.52:
			slot = Data.GRENADE                  # a grenade or two on the shelf (32)
		var it: Dictionary = Items.roll(slot, t, rng)
		# a standard box is on the box row without end; the shelf's rounds are the special ones
		for tries in range(8):
			if not (Items.is_ammo(it) and not Items.base_of(it).has("damage_pct") and it["affixes"].is_empty()):
				break
			it = Items.roll(slot, t, rng)
		if Items.is_ammo(it) and not Items.base_of(it).has("damage_pct") and it["affixes"].is_empty():
			it = Items.roll(Data.SLOTS[rng.randi_range(0, Data.SLOTS.size() - 1)], t, rng)
		if yard_has("arms_dealer") and not Items.is_ammo(it) and not Items.is_grenade(it):
			if deep_lv < 0:
				deep_lv = deepest_site_level()     # once a restock (BUILD45): nothing it reads moves while the shelf's rolled
			it = Items.roll(it["slot"], t, rng, 0.0, false, false, "", "", Data.FX["yard/arms_dealer"], 0, deep_lv)     # the Fence's Arms dealer
		market.append(it)
	_shelf_primary(t)
	# the standard magazines (30 Oct, magazines as items): SHELF_MAGS of each type a gun you hold takes, every restock
	for ty in owned_ammo_types():
		var mb: Dictionary = Items.standard_mag(ty)
		for k in range(Data.SHELF_MAGS if not mb.is_empty() else 0):
			market.append(_plain(Data.MAGAZINE, str(mb["name"])))
	if yard_has("back_room"):
		var bu := pick_unique(loose_uniques(0), shop_unique_tier(), true)
		if not bu.is_empty():
			market.append(Items.roll_unique(bu, rng, gamble_level(), shop_unique_tier()))    # the Fence's Back room: a loose one (the ungated), held in its range


## A primary at the zone's gear tier always on the shelf (31 Oct, the designer: a Poacher read never found a gun past
## tier 2 and never beat the Manager): a shelf that rolled none gets one plain one of that tier, a base drawn as the loot
## rolls draw one (the found-anywhere bases, the start's and the deep papers' left out). It sells with its standard
## magazine, as every gun bought does (buy, _mag_with).
func _shelf_primary(t: int) -> void:
	for it in market:
		if str(it.get("slot", "")) == "Primary" and int(it.get("tier", 0)) == t:
			return
	var pool: Array = []
	for b in Data.BASES["Primary"]:
		if int(b["tier"]) == t and not b.get("start", false) and int(b.get("depth", 0)) <= 0 and Items.exclusive_to(str(b["name"])) == "":
			pool.append(b)
	if pool.is_empty():
		return
	var base: Dictionary = Items._tier_pick("Primary", pool, t, rng)
	var it: Dictionary = _plain("Primary", str(base["name"]))
	it["ilvl"] = t                             # the level a Fence roll of the tier gives
	market.append(it)


## The Fence's gamble: GAMBLE_SHOWN kinds of the twelve, rotated with every restock.
func _restock_gamble() -> void:
	var kinds: Array = []
	var top: int = best_tier_open()          # once a restock (BUILD45, perf44 #7: asked once a base, 87 times, ~20 ms a restock late)
	for k in Data.GAMBLE_KINDS:
		if _gamble_has_base(k, top):
			kinds.append(k["kind"])        # only a kind the Fence can source at the tier opened
	kinds.shuffle()
	gamble = kinds.slice(0, Data.GAMBLE_SHOWN)


## Whether the pool holds a base of the kind at the tier opened (not a start base).
func _gamble_has_base(k: Dictionary, top := -1) -> bool:
	if top < 0:
		top = best_tier_open()
	for b in Data.BASES[k["slot"]]:
		if not b.get("start", false) and int(b["tier"]) <= top and (k["type"] == "" or b.get("type", "") == k["type"]):
			return true
	return false


static func gamble_kind(kind: String) -> Dictionary:
	for k in Data.GAMBLE_KINDS:
		if k["kind"] == kind:
			return k
	return {}


## The top open tier: what the Fence rolls a gamble at, and what its price is read off.
func top_tier() -> int:
	var top := 0
	for i in range(Data.TIERS.size()):
		if tier_open(i):
			top = i
	return top


## What the gamble's priced off: a run's takings, Fence money and all, but one run moves it GAMBLE_STEP at most - a
## clear-out at the Fence creeps the price up over runs, never lurches it (13 Oct, Matt's save: 305 then 2366). Before
## the first run home, the same stand-in the takings have.
func a_gamble_base() -> float:
	return gamble_base if gamble_base > 0.0 else a_runs_takings()


## The price of a gamble: GAMBLE_RUNS of the gamble's base, never under the floor.
func gamble_price(kind: String) -> int:
	if gamble_kind(kind).is_empty():
		return -1
	return int(round(maxf(float(_inf(Data.GAMBLE_FLOOR)), a_gamble_base() * Data.GAMBLE_RUNS) * (Data.FX["yard/gamblers_table"] if yard_has("gamblers_table") else 1.0)))


func can_gamble(kind: String) -> bool:
	return room_open("fence") and mission == null and kind in gamble and (cash >= gamble_price(kind) or gamble_tokens > 0) and stash_room(1)     # a gamble token (29 Oct, Bristol's): free     # room for one cell at least: the roll's own size is checked when it lands


## Pay, and the thing turns up in the stash: a random one of the kind, rolled at the top tier opened
## with the Fence's quality, never Common; or, one time in fifty, a unique of the kind. The kind leaves
## the offer; the next restock brings five more. `unique_roll` is the tests' dice.
func gamble_buy(kind: String, unique_roll := -1.0) -> Dictionary:
	if not can_gamble(kind):
		return {}
	var k := gamble_kind(kind)
	var it := roll_gamble(k, unique_roll)
	if not (fits_with_mag(it) or _stack_room(it)):
		return {}
	chron("gamble", {"kind": kind, "price": 0 if gamble_tokens > 0 else gamble_price(kind), "token": gamble_tokens > 0, "item": _chron_item(it)})
	if gamble_tokens > 0:
		gamble_tokens -= 1                    # Bristol's token (29 Oct): this one's free
	else:
		cash -= gamble_price(kind)
	gamble.erase(kind)
	stash_put(it)
	_mag_with(it)
	last_craft = {"id": it["id"], "kind": "gamble", "words": "The Fence's word: %s" % Items.full_name(it)}     # names as named (18 Oct)
	log_event(Words.LOG["gamble_word"] % Items.full_name(it))
	return it


## The roll behind a gamble, for the kind: a unique of the kind on GAMBLE_UNIQUE, else a drop of the
## slot at the top open tier's loot tier with the Fence's quality on it, never Common, of the type
## when the kind has one.
func roll_gamble(k: Dictionary, unique_roll := -1.0) -> Dictionary:
	var x: float = unique_roll if unique_roll >= 0.0 else rng.randf()
	if x < Data.GAMBLE_UNIQUE:
		var fits: Array = []
		for u in Data.UNIQUES:
			if u.has("site") or u.get("boss", false) or u.get("mythic", false):
				continue                                  # the chase is the ladders', never the Fence's (endgame part 3); a mythic only found
			if u["slot"] == k["slot"] and (k["type"] == "" or Items.base_named(k["slot"], u["base"]).get("type", "") == k["type"]):
				fits.append(u)
		var gu := pick_unique(fits, shop_unique_tier())
		if not gu.is_empty():
			return Items.roll_unique(gu, rng, gamble_level(), shop_unique_tier())     # one whose range takes the deepest tier dug; else a plain roll
	var it: Dictionary = {}
	for tries in range(40):
		it = Items.roll(k["slot"], best_tier_open(), rng, Data.GAMBLE_QUALITY, true, false, "", k["type"], 0.33, 0, gamble_level())     # at your deepest site's level, as its drops (15 Oct, the loot read)
		if k["type"] == "" or Items.base_of(it).get("type", "") == k["type"]:
			return it
	# the type never came up: the kind's lowest base, with the roll's affixes on it
	for b in Data.BASES[k["slot"]]:
		if not b.get("start", false) and b.get("type", "") == k["type"]:
			it["base"] = b["name"]
			it["tier"] = int(b["tier"])
			it["attachments"] = {}
			for name in b.get("attachments", []):
				it["attachments"][name] = null
			it["value"] = int(round(float(b["value"]) * float(Data.RARITIES[int(it["rarity"])]["value"])))
			break
	return it


## A standard box of rounds on the shelf costs what the box row charges for
## the same box; everything else carries the gear markup.
func price(it: Dictionary) -> int:
	if Items.is_ammo(it) and not Items.base_of(it).has("damage_pct") and it["affixes"].is_empty():
		return ammo_price(str(Items.base_of(it)["type"]))
	return _inf(Items.worth(it) * Data.MARKET_MARKUP * (Data.FX["node/buyers_market.buy"] if has_node("buyers_market") else 1.0) * (1.0 - town_stat("fence_pct") / 100.0) * (1.0 - tree_sum("buy_pct") / 100.0))     # the market hall (18 Oct); Shop local (22 Oct)


func buy(i: int) -> bool:
	if not room_open("fence"):
		return false
	if i >= market.size() or not (fits_with_mag(market[i]) or _stack_room(market[i])) or cash < price(market[i]):
		return false
	cash -= price(market[i])
	market[i]["shop_bought"] = true          # sells back under its shelf price (S2)
	stash_put(market[i])
	_mag_with(market[i])
	market.remove_at(i)
	return true


func sell(it: Dictionary) -> bool:
	if not room_open("fence"):
		return false                          # the Fence is shut until the Carpet Man's ledger (13 Oct)
	if not _remove(it):
		return false
	var got := float(sell_price(it))
	_earn(got)
	_rate_after_sale(got)
	if it.has("unique") and not it.get("issued", false):
		_lose(it, "", "fence")                # he said someone would want it; later someone has it
	if Items.is_deeds(it):
		deeds_fate = "sold"
		log_event(Words.DEEDS["sold"])
	return true


## Half a stack off into a stack of its own, beside it (12 Oct, Matt's playtest: "need a way to split ammo stacks"):
## rounds or bottles, two or more, in the stash (a free cell wanted) or the rig (a free slot); the larger half stays.
func can_split(id: int) -> bool:
	if runner_busy():                     # the rig's stacks too (T4): not between a repeat's runs
		return false
	for where in [stash, rig]:
		for it in where:
			if it["id"] == id:
				if not Items.stacks(it) or Items.stack_size(it) < 2:
					return false
				if where == stash and tab_of(it) != "":     # the half stays in the stack's own tab
					return stash_free(it) or tab_used(tab_of(it)) + Items.size(it) <= tab_cap(tab_of(it))
				return stash_fits(it) if where == stash else rig_room(Items.size(it))     # the Racks hold rounds without a cell
	return false


func split_stack(id: int) -> bool:
	if not can_split(id):
		return false
	for where in [stash, rig]:
		for it in where:
			if it["id"] == id:
				@warning_ignore("integer_division")
				var half: int = Items.stack_size(it) / 2
				var off: Dictionary = Items.one_of(it)
				Items.set_stack(off, half)
				Items.set_stack(it, Items.stack_size(it) - half)
				where.append(off)                # not stash_put: that would merge it straight back
				_dry_memo.clear()
				_stats_dirty()
				return true
	return false


## Into the stash, merging what stacks: rounds into the same base's stack to
## its cap, a bottle onto the bottles; the rest as its own stack if there's
## room. Returns whether everything found a place.
func stash_put(it: Dictionary) -> bool:
	if Items.stacks(it):
		var left: int = Items.stack_size(it)
		for s in stash:
			if left <= 0:
				break
			if Items.same_stack(s, it) and Items.stack_size(s) < Items.stack_cap(s):
				var room: int = Items.stack_cap(s) - Items.stack_size(s)
				var moved: int = mini(room, left)
				Items.set_stack(s, Items.stack_size(s) + moved)
				left -= moved
		if left <= 0:
			return true
		Items.set_stack(it, left)
	if not stash_fits(it):
		return false
	stash.append(it)
	return true


## A magazine the sweeps may take, as a common (the fix round, the review's 4: spare magazines piled up): out of the rig
## and empty, and either for no gun you hold or past the rig's share of its type kept in the stash besides the rig's - the best kept
## (the three-stage review). `extra`: a run's finds, read with the stash.
func spare_mag(it: Dictionary, extra: Array = []) -> bool:
	if not Items.is_mag(it) or rig.has(it) or int(it.get("rounds", 0)) > 0:
		return false
	var ty: String = Items.mag_type(it)
	var held: bool = _mags_holding and extra.is_empty()     # BUILD45: a stash that holds still (held_mags): read once
	if held and not _mags_held.has("types"):
		_mags_held["types"] = owned_ammo_types(mission)
	if not (ty in (_mags_held["types"] if held else owned_ammo_types(mission))):
		return true
	var keep_n: int = maxi(1, ceili(med_capacity() * Data.RIG_MAG_SHARE))
	if held and _mags_held.has("pool/" + ty):
		return _mags_held["pool/" + ty].find(it) >= keep_n
	# the stash's own share, the rig's apart (the three-stage review, game 8: counted with the rig's, a death that emptied
	# the rig left no spares and the next runner's guns couldn't fire)
	var pool: Array = (stash + extra).filter(func(x): return Items.is_mag(x) and Items.mag_type(x) == ty)
	var key := func(x: Dictionary) -> float: return float(x.get("rounds", 0)) * 1000.0 + float(Items.mag_cap(x)) / float(Items.size(x)) * 10.0 - float(x.get("id", 0)) * 1e-6
	pool.sort_custom(func(a, b): return key.call(a) > key.call(b))
	if held:
		_mags_held["pool/" + ty] = pool
	return pool.find(it) >= keep_n


## BUILD45 (2 Nov, perf44 1: the Fence's rows sorted a type's magazines again for every magazine, 1 ms each late): `f`
## called with the guns' rounds types and each type's magazines read once - only over a stash nothing is taken from
## (rarity_spare's own walk, not the sells' cascade, which takes pieces out as it goes).
var _mags_holding := false
var _mags_held := {}
func held_mags(f: Callable) -> Variant:
	var was: bool = _mags_holding
	_mags_held = {}
	_mags_holding = true
	var v = f.call()
	_mags_holding = was
	_mags_held = {}
	return v


## Items are matched by id, never by contents: two commons can read the same.
func _remove(it: Dictionary) -> bool:
	for k in range(stash.size()):
		if stash[k]["id"] == it["id"]:
			stash[k].erase("tab")              # out of the stash, out of its tab: whatever brings it back puts it in the shared one
			stash.remove_at(k)
			_removed += 1
			return true
	return false


## Every item of a rarity in the stash, sold.
func sell_rarity(r: int) -> int:
	var n := 0
	for it in rarity_sells(r):
		if sell(it):
			n += 1
	return n


## What a rarity row's Sell takes (the second review: the row's count and the button agree): the spares of that rarity on
## the shared tab, and those the sale leaves spare in turn - a gun sold leaves its magazines spare (the fix round) - read
## pass by pass with the sold ones out of the stash, then put back.
func rarity_sells(r: int) -> Array:
	if _key_holding and _sells_held.has(r):
		return _sells_held[r].duplicate()     # BUILD45: once a rarity through the Fence's paint (held_kit_key)
	var out: Array = []
	var was: Array = stash.duplicate()
	var again := true
	while again:
		again = false
		for it in stash.duplicate():
			if _spare(it, r) and tab_of(it) == "":     # the shared tab's (21 Oct): a class's own is kept
				out.append(it)
				stash.erase(it)
				again = true
	stash = was                               # as it stood, its order too
	if _key_holding:
		_sells_held[r] = out.duplicate()
	return out


## A piece the Fence's rarity row sells (19 Oct, Matt's Fence A: "sell what you don't wear"): that rarity, not a paper,
## not a mythic, not the deeds, not rounds, meds or grenades (19 Oct, Matt: they stay out - rounds have their boxes), and
## not an upgrade on what's worn - that's kept.
func _spare(it: Dictionary, r: int) -> bool:
	return int(it["rarity"]) == r and not ((Items.rig_item(it) and not spare_mag(it)) or Items.is_ammo(it)) and not Items.is_paper(it) and not it.get("mythic", false) and not Items.is_deeds(it) and not (str(it.get("slot", "")) in Data.SLOTS and compare(it) == 1) and not sell_kept(it)


## A piece the rarity row passes by as Sell when home does (25 Oct, the review: "Sell Legendary" sold uniques): a
## unique, a set piece, a patterned piece, one a loot rule keeps or highlights, one in a saved kit, a built gun.
func sell_kept(it: Dictionary) -> bool:
	if it.has("unique") or it.has("set") or it.has("pattern") or it.get("built", false):
		return true
	if tab_of(it) != "":
		return true                          # a class's own tab (21 Oct): kept, and counted kept (the second review: the row counted it spare)
	if loot_rule_act(it) in ["keep", "highlight"]:
		return true
	for c in loadouts:
		for e in loadouts[c]:
			if e is Dictionary and int(it.get("id", -1)) in e.get("gear", {}).values():
				return true                  # any class's kit: the shared stash holds them all (the review)
	return false


## A rarity's row: [pieces sold, what they fetch, upgrades kept back].
func rarity_spare(r: int) -> Array:
	var n := 0
	var worth := 0
	var sells: Array = rarity_sells(r)          # what the button sells, the cascade in (the second review)
	var sold := {}                              # BUILD45: by id (a stash piece's own), not each piece compared whole
	for it in sells:
		n += 1
		worth += sell_price(it)
		sold[int(it["id"])] = true
	var kept: int = held_mags(_rarity_kept.bind(r, sold))     # the stash holds still through it: its magazines read once
	return [n, worth, kept]


func _rarity_kept(r: int, sold: Dictionary) -> int:
	var kept := 0
	for it in stash:
		if sold.has(int(it["id"])) or _spare(it, r):
			continue
		elif int(it["rarity"]) == r and str(it.get("slot", "")) in Data.SLOTS and (compare(it, -1, true) == 1 or sell_kept(it)):
			kept += 1
	return kept


## Whether the junk rules sell this: at or under the rarity, not an upgrade, not a kind kept, and never what the junk
## run leaves (rounds, meds, grenades, papers, socketed parts, uniques, set pieces, the deeds, a built gun).
func is_junk(it: Dictionary) -> bool:
	if junk_upto < 0 or int(it.get("rarity", 0)) > junk_upto:
		return false
	if ((Items.rig_item(it) and not spare_mag(it)) or Items.is_ammo(it)) or Items.is_paper(it) or Items.is_socketable(it) or Items.is_supplies(it) or it.has("unique") or it.has("set") or it.has("pattern") or Items.is_deeds(it) or it.get("built", false) or loot_rule_act(it) in ["keep", "highlight"]:     # a rule's keep: asked now, so a rule deleted lets it go again (the review)
		return false
	if str(it.get("slot", "")) in JUNK_KEEPS.get(junk_keep, []):
		return false
	return compare(it, -1, true) != 1    # an upgrade waiting for its level is kept too; read as the Kit's swap would wear it


## Better than what's worn, tried on (compare), and wearable now: the compare's "▲ Upgrade", the stash's arrow. `moved`: as
## the swap would leave it (the Kit's stash), else as it stands (a run's pack, the Fence's shelf: the fix round, 29 Oct).
func is_upgrade(it: Dictionary, moved := false) -> bool:
	return can_wear(it) and compare(it, -1, moved) == 1


## Gear gated by level (15 Oct): whether the runner is level enough to put it on.
func can_wear(it: Dictionary) -> bool:
	return Items.wear_level(it) <= level()


## The level a piece waits for, or 0 when it can be worn now: the padlock's number.
func wear_lock(it: Dictionary) -> int:
	var w: int = Items.wear_level(it)
	return w if w > level() else 0


## The idle junk run, by the junk rules (is_junk).
func sell_junk() -> int:
	var n := 0
	var got := 0.0
	for it in stash.duplicate():
		if is_junk(it) and tab_of(it) == "":     # a class's own tab is kept: the junk run sells the shared one
			var p: int = sell_price(it)
			if sell(it):
				got += p
				n += 1
	if n > 0:
		log_event(Words.LOG["junk_sold"] % [n, "" if n == 1 else "s", _cash_words(got)])
	return n


## The Stash's Bins: the common gear in a run's finds scrapped, the junk run's filter (never a built gun, the
## deeds, rounds, meds, papers, socketables, uniques or set pieces); the rest is what still goes to the stash.
func _bin_commons(found: Array) -> Array:
	var kept: Array = []
	var n := 0
	var got := 0
	for it in found:
		if int(it.get("rarity", 0)) == 0 and not (loot_rule_act(it) in ["keep", "highlight"]) and not ((Items.rig_item(it) and not spare_mag(it, found)) or Items.is_ammo(it) or Items.is_paper(it) or Items.is_socketable(it) or Items.is_supplies(it) or it.has("unique") or it.has("set") or Items.is_deeds(it) or it.get("built", false) or it.get("first_gun", false)):
			got += scrap_of(it)
			n += 1
		else:
			kept.append(it)
	scrap += got
	if n > 0:
		log_event(Words.LOG["binned_n"] % [n, "" if n == 1 else "s", got])
	return kept


# ------------------------------------------------------------------ the loot filter (24 Oct, the endgame chase, phase 5)

## The rules a run's finds pass through as it comes home, the first that fits winning: keep it, highlight it (an amber
## edge in the stash) or scrap it for its scrap. Off till a rule is added; nothing fits, kept. Never the run's own
## rounds, meds, papers, the deeds or a first gun: the gear alone.
var loot_rules_on := true               # the panel's master switch: off, nothing's touched and the rules wait
const LOOT_RULES_MAX := 8                # the panel's rows
var loot_rules: Array = []               # [{"kind": "any"|"special", "rarity": int (at least), "upto": int (at most), "slot": "", "gun": "", "tier": 0, "act": "keep"|"highlight"|"scrap", "on": bool}]


static func loot_rule_new() -> Dictionary:
	return {"kind": "any", "rarity": 0, "upto": 0, "slot": "", "gun": "", "tier": 0, "act": "keep", "on": false}     # off till it's set and switched on: an Add changes nothing (the review)


func loot_rule_fits(r: Dictionary, it: Dictionary) -> bool:
	if not (str(it.get("slot", "")) in Data.SLOTS):
		return false
	var special: bool = it.has("unique") or it.has("set") or it.get("mythic", false) or it.has("pattern")
	if str(r.get("kind", "any")) == "special":
		return special
	if special:
		return false                         # a unique, a set piece, a mythic: only a "special" rule touches one
	var rar: int = int(it.get("rarity", 0))
	if rar < int(r.get("rarity", 0)) or rar > int(r.get("upto", 4)):
		return false
	if str(r.get("slot", "")) != "" and str(it["slot"]) != str(r["slot"]) and not (str(r["slot"]) == "Body" and str(it["slot"]) in ["Helmet", "Armour", "Gloves", "Charm"]) and not (str(r["slot"]) == "Bags" and str(it["slot"]) in ["Rig", "Backpack"]):
		return false
	if str(r.get("gun", "")) != "" and str(Items.base_of(it).get("type", "")) != str(r["gun"]):
		return false
	if int(r.get("tier", 0)) > 0:
		var best := 0
		for a in it.get("affixes", []):
			best = maxi(best, int(a.get("tier", 0)))
		if best < int(r["tier"]):
			return false
	return true


## The act a piece meets: "keep", "highlight", "scrap", or "" when no rule's on and fits.
func loot_rule_act(it: Dictionary) -> String:
	if not loot_rules_on:
		return ""
	for r in loot_rules:
		if bool(r.get("on", true)) and loot_rule_fits(r, it):
			return str(r.get("act", "keep"))
	return ""


func apply_loot_rules(found: Array) -> Array:
	if loot_rules.is_empty() or not loot_rules_on:
		return found
	var kept: Array = []
	var n := 0
	var got := 0
	for it in found:
		if it.get("first_gun", false) or it.get("from_rig", false) or it.get("spared", false) or not (str(it.get("slot", "")) in Data.SLOTS):
			kept.append(it)
			continue
		var act: String = loot_rule_act(it)
		if act == "scrap" and (it.has("unique") or it.has("set") or it.get("mythic", false) or it.has("pattern")):
			act = "keep"                     # a unique, a set piece, a mythic or a patterned piece is never scrapped by a rule (the review)
		match act:
			"scrap":
				got += scrap_of(it)
				n += 1
			"highlight":
				it["hl"] = true
				kept.append(it)
			_:
				kept.append(it)
	scrap += got
	if n > 0:
		log_event(Words.LOOT_RULES["scrapped"] % [n, "" if n == 1 else "s", got])
	return kept


## A rule added at the foot (the first that fits wins, so a new rule waits behind the old); false at the cap.
func loot_rule_add() -> bool:
	if loot_rules.size() >= LOOT_RULES_MAX:
		return false
	loot_rules.append(loot_rule_new())
	return true


## A rule up one place: it is asked before the one above it now.
func loot_rule_up(i: int) -> void:
	if i > 0 and i < loot_rules.size():
		var r = loot_rules[i]
		loot_rules[i] = loot_rules[i - 1]
		loot_rules[i - 1] = r


## A rule in words: "Common or uncommon · any slot", "Any unique, set piece or mythic".
func loot_rule_words(r: Dictionary) -> String:
	if str(r.get("kind", "any")) == "special":
		return Words.LOOT_RULES["special"]
	var names: Array = Data.RARITIES.map(func(x): return str(x["name"]) if x is Dictionary else str(x))
	var lo: int = int(r.get("rarity", 0))
	var hi: int = int(r.get("upto", 4))
	var rar: String = "%s to %s" % [names[lo], names[hi]]
	if lo == 0 and hi >= 4:
		rar = Words.LOOT_RULES["any_rarity"]
	elif lo == hi:
		rar = names[lo]
	elif hi >= 4:
		rar = Words.LOOT_RULES["or_better"] % names[lo]
	elif lo == 0:
		rar = Words.LOOT_RULES["upto"] % names[hi]
	var bits: Array = [rar]
	bits.append(str(r["slot"]) if str(r.get("slot", "")) != "" else Words.LOOT_RULES["any_slot"])
	if str(r.get("gun", "")) != "":
		bits.append(str(r["gun"]).to_upper() if str(r["gun"]) == "smg" else str(r["gun"]).capitalize())
	if int(r.get("tier", 0)) > 0:
		bits.append((Words.LOOT_RULES["tier_top"] if int(r["tier"]) >= Data.AFFIX_TIERS else Words.LOOT_RULES["tier"]) % int(r["tier"]))
	return " · ".join(bits)


## Idle: what the toggles do when a run comes home.
func _idle_tidy() -> void:
	if junk_upto >= 0:
		sell_junk()
	if auto_equip:
		var changed := []
		for s in Data.SLOTS:
			if equip_best(s):
				changed.append(Items.full_name(equipped[s]))
		if not changed.is_empty():
			log_event(Words.LOG["put_on"] % ", ".join(changed))


# ------------------------------------------------------------------ the medic tent

## The Medic Tent's shelf: every common med up to the next tier, at its markup.
## The Clinic's shelf: clinic_stock() meds, rolled from the
## bases it carries, cheaper ones more often. Finite until the next run.
## Her supplies (28 Oct): CLINIC_CURES of the shelf are cures, the front's elements first; the rest heals from her
## tier, and past the steps that say so a share of them Magic or Rare, rolled with the meds' affixes.
func _restock_clinic() -> void:
	clinic = []
	var bases := med_stock().filter(func(b): return not b.has("cure"))
	var cures: Array = clinic_cures()
	var n_cures: int = mini(Data.CLINIC_CURES, clinic_stock() - 1) if not cures.is_empty() else 0
	var step: Dictionary = clinic_step_now()
	for k in range(clinic_stock() - n_cures):
		var b: Dictionary = bases[mini(bases.size() - 1, int(absf(rng.randfn(0.0, 1.2))))]
		var it := _plain(Data.MEDICAL, str(b["name"]))
		it["ilvl"] = int(b["tier"])           # at its base's tier, as the old shelf's (28 Oct, the review: _plain's roll left ilvl 1)
		var x := rng.randf()
		var r: int = 2 if x < float(step.get("rare", 0.0)) else (1 if x < float(step.get("rare", 0.0)) + float(step.get("magic", 0.0)) else 0)
		if r > 0:
			_roll_med(it, r)
		clinic.append(it)
	for k in range(n_cures):
		clinic.append(_plain(Data.MEDICAL, str(cures[k % cures.size()]["name"])))


## A med rolled up to a rarity at the Clinic (28 Oct): the rarity's affixes from the meds' own, at its tier's level.
func _roll_med(it: Dictionary, r: int) -> void:
	it["rarity"] = r
	it["affixes"] = []
	for a in Items.pick_affixes(Data.MEDICAL, int(Data.RARITIES[r]["affixes"]), rng):
		it["affixes"].append(Items.roll_affix(a, Items.ilvl(it), rng, 0, int(Data.RARITIES[r]["tier"])))
	it["value"] = int(round(float(Items.base_of(it)["value"]) * float(Data.RARITIES[r]["value"])))


## The cures she stocks, the front's elements first, then the rest of what her tier carries.
func clinic_cures() -> Array:
	var all: Array = med_stock().filter(func(b): return b.has("cure"))
	var front: Array = zone_elements(front_tier())
	all.sort_custom(func(a, b): return (front.find(a["cure"]) if front.has(a["cure"]) else 99) < (front.find(b["cure"]) if front.has(b["cure"]) else 99))
	return all


## Her steps reached by the supplies handed in (28 Oct): 0 for none.
func clinic_step() -> int:
	var n := 0
	for st in Data.CLINIC_STEPS:
		if supplies_in >= int(st["need"]):
			n += 1
	return n


## The step's figures she stocks by now: {} before the first.
func clinic_step_now() -> Dictionary:
	var k: int = clinic_step()
	return {} if k == 0 else Data.CLINIC_STEPS[k - 1]


## The supplies to her next step, or -1 when she's at the last.
func clinic_next_need() -> int:
	var k: int = clinic_step()
	return -1 if k >= Data.CLINIC_STEPS.size() else int(Data.CLINIC_STEPS[k]["need"]) - supplies_in


## Medical supplies in the stash.
func supplies_held() -> int:
	var n := 0
	for it in stash:
		if Items.is_supplies(it):
			n += Items.stack_size(it)
	return n


func can_hand_in() -> bool:
	return room_open("clinic") and mission == null and supplies_held() > 0


## The stash's medical supplies to the medic (28 Oct): counted for good; a step reached, her shelf restocked to it.
func hand_in_supplies() -> int:
	if not can_hand_in():
		return 0
	var n: int = supplies_held()
	var was: int = clinic_step()
	for it in stash.duplicate():
		if Items.is_supplies(it):
			it.erase("tab")
			stash.erase(it)
	supplies_in += n
	chron("supplies", {"n": n, "total": supplies_in})
	log_event(Words.SUPPLIES_IN % [n, supplies_in])
	if clinic_step() > was:
		_restock_clinic()
		log_event(Words.SUPPLIES_STEP[clinic_step() - 1])
	return n


func clinic_price(it: Dictionary) -> int:
	return _inf(it["value"] * Data.MED_PRICE * _buy_k("clinic_pct"))     # the shelf's buy multipliers (S1); the pumping station (18 Oct); at today's prices, as the list's (the third review: after the Issue it read opening-day tins as fiat)


func buy_clinic(id: int) -> bool:
	if not room_open("clinic"):
		return false                          # the Clinic is shut until the Gamekeeper's vet's bag (13 Oct)
	for k in range(clinic.size()):
		if clinic[k]["id"] == id:
			var it: Dictionary = clinic[k]
			if cash < clinic_price(it) or not stash_fits(it):
				return false
			cash -= clinic_price(it)
			clinic.remove_at(k)
			stash.append(it)
			return true
	return false


## Buy off the Fence's shelf by the item's id.
func buy_id(id: int) -> bool:
	for k in range(market.size()):
		if market[k]["id"] == id:
			return buy(k)
	return false


func med_stock() -> Array:
	var out: Array = []
	var lift: int = int(clinic_step_now().get("tier", 0))     # her supplies (28 Oct): a tier up, floor and top, a step
	var t := mini(3, gear_tier()) + lift
	for b in Data.BASES[Data.MEDICAL]:
		if b["tier"] <= t and (b.has("cure") or int(b["tier"]) > lift or t - lift <= 0):
			out.append(b)
	if not out.any(func(b): return not b.has("cure")):
		out = Data.BASES[Data.MEDICAL].filter(func(b): return int(b["tier"]) <= t)     # nothing left above the floor: all she has
	return out


# ------------------------------------------------------------------ the Yard's upgrades

## The Generator's energy (24 Oct, milestone 8: its away picks gone, docs/design/skills.md). The skill engine reads
## these; until it lands they're the figures alone.
func generator_max_energy() -> float:
	return (Data.FX["yard/jerry_can"] if yard_has("jerry_can") else 0.0) + Data.FX["yard_rank/generator"] * yard_rank("generator")


func generator_energy_regen() -> float:
	return Data.FX["yard/dynamo"] if yard_has("dynamo") else 0.0


func generator_kill_energy() -> float:
	return Data.FX["yard/kickback"] if yard_has("kickback") else 0.0


func generator_cooldown_pct() -> float:
	return Data.FX["yard/flywheel"] if yard_has("flywheel") else 0.0


## Pilot light: a fight's first skill costs no energy.
func generator_first_free() -> bool:
	return yard_has("pilot_light")


# ------------------------------------------------------------------ skills (24 Oct, milestone 8: docs/design/skills.md)

func skill(id: String) -> Dictionary:
	return Data.SKILLS.get(id, {})


func max_energy() -> float:
	return maxf(10.0, Data.ENERGY_POOL + _affix_sum("energy_max") + tree_sum("energy_max") + generator_max_energy() - (30.0 if has_node("double_time") else 0.0))


## A second's energy: the base, a quarter of pace's bonus, energy gain (%), the Dynamo.
func energy_regen() -> float:
	return (Data.ENERGY_REGEN * (1.0 + (pace() - 1.0) * Data.ENERGY_PACE_SHARE) * (1.0 + (_affix_sum("energy_regen_pct") + tree_sum("energy_regen_pct")) / 100.0) + generator_energy_regen()) \
		* float(class_data().get("energy_regen", 1.0)) * (2.0 if has_node("double_time") else 1.0)     # the Recruit's, his Double time


## Cooldowns shorter by this per cent: the kit's and the Flywheel's, CDR_CAP at most.
func cooldown_cut() -> float:
	return minf(Data.CDR_CAP, _affix_sum("cdr_pct") + tree_sum("cdr_pct") + generator_cooldown_pct())


func skill_cooldown(id: String) -> float:
	if exploit_on("overdrawn"):
		return Data.EXPLOIT_CD                  # the wrap: past the cap and costed as a credit
	return float(skill(id).get("cd", 0.0)) * (1.0 - cooldown_cut() / 100.0) * (0.7 if has_node("on_the_double") else 1.0)     # Quick march: past the cap, its own


## Learnt: its skill node trained, and the node working for this runner (another class's half doesn't teach them its
## skills - skills.md §3, only your class's).
func skill_known(id: String) -> bool:
	return str(skill(id).get("cls", "")) == cls and has_node("skill_" + id)     # a bridge opens a region's passives, never its class's skills


## The skills this runner has learnt, in the order of Data.SKILLS (the picker's).
func skills_learnt() -> Array:
	return Data.SKILLS.keys().filter(func(id): return skill_known(str(id)))


## Whether a class can be taken (24 Oct, milestone 8: skills.md §6): the Poacher from the start, each other after its
## head - the Gamekeeper the Paramedic, the Carpet Man the Doorman, the Manager the Scrapper, the Quartermaster the
## Recruit - and the Drifter after Kev's first story.
func class_open(name: String) -> bool:
	match name:
		"Poacher":
			return true
		"Paramedic":
			return bosses_beaten.size() > 0 and bosses_beaten[0]
		"Doorman":
			return bosses_beaten.size() > 1 and bosses_beaten[1]
		"Scrapper":
			return bosses_beaten.size() > 2 and bosses_beaten[2]
		"Recruit":
			return bosses_beaten.size() > 3 and bosses_beaten[3]
		"Drifter":
			return story_beat >= 1
	return false


## The classes a head or the story just opened, said in the log (`before`: class_open for each, in Data.CLASSES order).
func _say_unlocks(before: Array) -> void:
	for k in range(Data.CLASSES.size()):
		var nm: String = str(Data.CLASSES[k]["name"])
		if not bool(before[k]) and class_open(nm) and Words.CLASS_UNLOCK.has(nm):
			log_event(str(Words.CLASS_UNLOCK[nm]["line"]))
			chron("class_open", {"class": nm})


## Puts a learnt skill in slot `i` ("" empties it); one copy a loadout, never on a run.
func set_skill_slot(i: int, id: String) -> bool:
	if i < 0 or i >= Data.SKILL_SLOTS or runner_busy():
		return false
	if id != "" and (not skill_known(id) or skill(id).is_empty()):
		return false
	for k in range(Data.SKILL_SLOTS):
		if k != i and id != "" and skill_slots[k] == id:
			skill_slots[k] = ""
	skill_slots[i] = id
	_stats_dirty()
	return true


func set_skill_auto(i: int, on: bool) -> void:
	if i >= 0 and i < Data.SKILL_SLOTS:
		skill_auto[i] = on
		_stats_dirty()


## Fires slot `i` on the next tick if it can (the player's press: the rule set aside, not the cost or the cooldown).
func press_skill(i: int) -> bool:
	if mission == null or i < 0 or i >= Data.SKILL_SLOTS or str(skill_slots[i]) == "":
		return false
	var sk: Dictionary = mission.get("sk", {})
	if sk.is_empty() or skill_wait(i) > 0.0 or skill_cost_now(i) > float(sk["energy"]) or mission["remaining"] <= 0:
		return false
	sk["press"] = i
	return true


## Seconds before slot `i` is off its cooldown (0 ready; 0 off a run).
func skill_wait(i: int) -> float:
	if mission == null or not mission.has("sk"):
		return 0.0
	return float(mission["sk"]["cd"][i])


## What slot `i` costs now: nothing while Pilot light's first is still to come.
func skill_cost_now(i: int) -> float:
	var id: String = str(skill_slots[i])
	if id == "":
		return 0.0
	if mission != null and mission.get("sk", {}).get("free", false):
		return 0.0
	var half: bool = mission != null and float(mission.get("sk", {}).get("fx", {}).get("fam_t", 0.0)) > 0.0     # Fire and manoeuvre
	var tax: float = Data.AUDITOR_TAX if mission != null and _order_mech(mission) == "auditor" else 1.0     # the Auditor's (25 Oct)
	return float(skill(id).get("cost", 0.0)) * (0.5 if half else 1.0) * skill_cost_mult() * tax


## What every skill costs, as a share: the Recruit's 10% off, Firing blanks' 25% off, Quick march's 25% on.
func skill_cost_mult() -> float:
	if exploit_on("overdrawn"):
		return 0.0
	return float(class_data().get("skill_cost", 1.0)) * (0.75 if has_node("live_firing") else 1.0) * (1.25 if has_node("on_the_double") else 1.0)


func energy_now() -> float:
	return float(mission["sk"]["energy"]) if mission != null and mission.has("sk") else max_energy()


## A fight starts (each gang, the head's too): energy full, every slot ready, Pilot light's first free again.
func _skills_fight_start(m: Dictionary) -> void:
	var sk: Dictionary = m.get("sk", {})
	sk["energy"] = max_energy()
	sk["cd"] = [0.0, 0.0, 0.0]
	sk["free"] = generator_first_free()
	sk["fight_t"] = 0.0
	sk["press"] = -1
	sk["seq"] = int(sk.get("seq", 0)) + 1     # a man joins: Gin trap's next one
	if not sk.has("fx"):
		sk["fx"] = {}
	sk["fx"]["stuns"] = []                    # the last gang's stunned men are gone with it, and its timed effects
	for k in sk["fx"].keys():
		if str(k).ends_with("_t"):
			sk["fx"][k] = 0.0                     # (the review: a Net on the last man held the next gang's fire); a set trap stays
	sk["share"] = {}
	sk["stun_share"] = 0.0
	sk["once"] = {}                           # Back of the van: once a fight, not once a run (the review)
	if not sk.has("cast"):
		sk["cast"] = 0
	m["sk"] = sk


## Whether slot `i`'s rule holds now.
func _skill_rule_holds(m: Dictionary, t: Dictionary, rule: String, on_you: int) -> bool:
	var dots: Dictionary = m.get("my_dots", {})
	var ailing: Array = dots.keys().filter(func(ty): return float(dots[ty]) > 0.0)
	match rule:
		"ready", "opener_ready":
			return true
		"on_you_2":
			return on_you >= 2
		"on_you_3":
			return on_you >= 3
		"on_you_3_half":
			return on_you >= 3 and hp > max_hp() * 0.5
		"under_half":
			return hp < max_hp() * 0.5
		"ailing":
			return not ailing.is_empty()
		"bleeding":
			return ailing.has("bleed")
		"poison_burn":
			return ailing.has("poison") or ailing.has("fire")
		"ailments_2":
			return ailing.size() >= 2
		"finisher":
			return float(m["target_hp"]) > 0.0 and float(m["target_hp"]) < Data.FINISHER_AT * _target_max(m, t)
		"opener":
			return float(m["sk"]["fight_t"]) < Data.OPENER_S
		"low_rounds":
			var gun = equipped["Primary"]
			return gun != null and not (Items.ammo_type(gun) in ["", "none"] or Items.free_rounds(gun)) and rounds_for(gun) < Data.LOW_ROUNDS
		"no_grenade":
			return not rig.any(func(it): return Items.is_grenade(it))
		"last_stand":
			return false                          # never by itself on a tick: the hit that would kill you calls it (_skill_last_stand)
	return false


## The man in front's full HP: the head's when he's out.
func _target_max(m: Dictionary, t: Dictionary) -> float:
	if _head_out(m):
		return float(m["boss"]["hp"])
	return float(t["hp"])


func _head_out(m: Dictionary) -> bool:
	return m.has("boss") and m["boss"]["started"] and m["boss"]["alive"]


## A tick of the skills, before the hit: energy and cooldowns, effects running down, then at most one skill fires -
## the pressed one, else the dearest whose rule holds (two on one tick: the other waits a tick).
func _skills_tick(m: Dictionary, t: Dictionary, dt: float, on_you: int) -> void:
	if not m.has("sk"):
		_skills_fight_start(m)
	var sk: Dictionary = m["sk"]
	if skill_slots == ["", "", ""] and int(sk["fx"].get("trap_at", -1)) < 0 and sk["fx"].get("stuns", []).is_empty() and not _sk_timer_left(sk):
		sk["share"] = {}                      # nothing slotted and nothing running: nothing to run (every dry run of a camp
		sk["stun_share"] = 0.0                # without skills); a grenade's Ringing ears still runs down (the review)
		return
	sk["fight_t"] = float(sk["fight_t"]) + dt
	sk["dt"] = dt
	var fx: Dictionary = sk["fx"]
	var share: Dictionary = {}
	for k in fx.keys():
		if str(k).ends_with("_t"):
			share[k] = clampf(float(fx[k]) / dt, 0.0, 1.0) if dt > 0.0 else (1.0 if float(fx[k]) > 0.0 else 0.0)     # the share of this tick it still covers (the review: a 2 s dry step read a 1 s window whole)
			fx[k] = maxf(0.0, float(fx[k]) - dt)
	sk["share"] = share
	var regen_x: float = 1.0 + (float(fx.get("regen_x", 1.0)) - 1.0) * _sk_share(m, "regen_t")     # Two sugars
	sk["energy"] = minf(max_energy(), float(sk["energy"]) + energy_regen() * regen_x * dt)
	var cd_rate: float = 1.0 + _sk_share(m, "fam_t")          # Fire and manoeuvre: cooldowns pass twice as quickly
	for i in range(Data.SKILL_SLOTS):
		sk["cd"][i] = maxf(0.0, float(sk["cd"][i]) - dt * cd_rate)
	var stuns: Array = fx.get("stuns", [])
	var stun_share := 0.0
	for j in range(stuns.size()):
		stun_share += clampf(float(stuns[j]) / dt, 0.0, 1.0) if dt > 0.0 else 1.0     # each stun by the share of the tick it covers
		stuns[j] = float(stuns[j]) - dt
	fx["stuns"] = stuns.filter(func(x): return float(x) > 0.0)
	sk["stun_share"] = stun_share
	# Gin trap: a man joined since it was set
	if fx.get("trap_at", -1) >= 0 and int(sk["seq"]) > int(fx["trap_at"]) and float(m["target_hp"]) > 0.0:
		var trap: Dictionary = skill("gin_trap")["fx"]
		m["src_now"] = "gin_trap"                   # the breakdown: the trap's spring is its own, whatever was cast since
		_skill_damage(m, _skill_base() * float(trap["trap_mult"]), "physical", true)
		_skill_dot(m, "bleed", float(trap["bleed_s"]))
		fx["trap_at"] = -1
	var pressed: int = int(sk.get("press", -1))
	sk["press"] = -1
	# as many casts as a player's frames would get in this tick (25 Oct, the review: one a tick starved the bot's
	# one-second ticks and the odds' two-second steps of skills a 60 fps player fires)
	for cast in range(maxi(1, ceili(dt / SKILL_CAST_EVERY))):
		var pick := -1
		if cast == 0 and pressed >= 0 and _skill_can(m, pressed):
			pick = pressed
		else:
			var best := -1.0
			for i in range(Data.SKILL_SLOTS):
				var id: String = str(skill_slots[i])
				if id == "" or not (skill_auto[i] or m.get("unwatched", false)) or not _skill_can(m, i):     # unwatched (29 Oct, the designer): the manual ones fire too
					continue
				if not _skill_rule_holds(m, t, str(skill(id)["rule"]), on_you):
					continue
				if float(skill(id)["cost"]) > best:
					best = float(skill(id)["cost"])
					pick = i
		if pick < 0:
			break
		_skill_fire(m, t, pick)


## Any timer left at all, a grenade's stun included: the tick runs while one is (the dry runs' hot path: a plain loop).
func _sk_timer_left(sk: Dictionary) -> bool:
	var fx: Dictionary = sk["fx"]
	for k in fx:
		if str(k).ends_with("_t") and float(fx[k]) > 0.0:
			return true
	return false


## A skill's timed effect still running: a timer left, or one this tick
## still covers (the tick counts down before the hit, so an effect's last tick reads 0 left - the review).
func _sk_running(sk: Dictionary) -> bool:
	return _sk_effect_share(sk) > 0.0


## How much of this tick a skill's effect covers, the most of them (Cover me, Drilled): every skill's timer, its wards
## included; Ringing ears' stun is a grenade's, not a skill's.
func _sk_effect_share(sk: Dictionary) -> float:
	var fx: Dictionary = sk["fx"]
	var share: Dictionary = sk.get("share", {})
	var out := 0.0
	for k in fx:
		var key: String = str(k)
		if not key.ends_with("_t") or key == "stun_all_t":
			continue
		if float(fx[k]) > 0.0:
			return 1.0
		out = maxf(out, float(share.get(k, 0.0)))
	return out


## The energy a slotted Last stand keeps back while it's still to come (Code blue: "its energy is kept back all run").
func _skill_reserve(m: Dictionary, but: int = -1) -> float:
	var out := 0.0
	for i in range(Data.SKILL_SLOTS):
		var id: String = str(skill_slots[i])
		if i != but and id != "" and str(skill(id).get("rule", "")) == "last_stand" and skill_known(id) and not m.get("last_stand_used", false):
			out += float(skill(id)["cost"])
	return out


func _skill_can(m: Dictionary, i: int) -> bool:
	var id: String = str(skill_slots[i])
	if float(m.get("sealed", {}).get(str(i), 0.0)) > 0.0:
		return false                          # the Registrar's seal (24 Oct); keyed by the slot as words, so a save keeps it
	if id == "" or skill(id).is_empty() or not skill_known(id) or float(m["sk"]["cd"][i]) > 0.0 or m["remaining"] <= 0:
		return false
	if skill(id).get("once_fight", false) and m["sk"].get("once", {}).has(id):
		return false
	if skill(id).get("once_run", false) and m.get("last_stand_used", false):
		return false
	if str(skill(id).get("rule", "")) == "last_stand":
		return false                          # Code blue: only the hit that would kill you fires it, never a press (the review)
	if skill(id).get("fx", {}).get("barred", false) and _head_out(m):
		return false                          # Barred: never on a head
	if float(skill(id).get("cash", 0.0)) > cash:
		return false                          # Bung: the tins first
	return skill_cost_now(i) <= float(m["sk"]["energy"]) - _skill_reserve(m, i)


## A skill goes off: its energy (and tins) and cooldown, then what it does.
func _skill_fire(m: Dictionary, t: Dictionary, i: int) -> void:
	var sk: Dictionary = m["sk"]
	var id: String = str(skill_slots[i])
	var d: Dictionary = skill(id)
	var f: Dictionary = d["fx"]
	var paid: float = skill_cost_now(i)
	sk["energy"] = float(sk["energy"]) - paid
	sk["free"] = false
	sk["cd"][i] = skill_cooldown(id)
	sk["cast"] = int(sk["cast"]) + 1
	sk["last"] = {"slot": i, "id": id, "at": float(m["elapsed"])}     # for the frame: the button's flash, the word over it
	m["src_now"] = id                                               # the breakdown: this skill's hits are its own (24 Oct)
	if not m.has("sk_uses"):
		m["sk_uses"] = {}
	m["sk_uses"][id] = int(m["sk_uses"].get(id, 0)) + 1
	if d.get("once_fight", false):
		if not sk.has("once"):
			sk["once"] = {}
		sk["once"][id] = true
	if float(d.get("cash", 0.0)) > 0.0 and not m.get("dry", false):
		cash -= tins_now(float(d["cash"]))     # Bung's tins (fiat after the Issue)
	if has_node("cap_passing_out"):
		sk["energy"] = minf(max_energy(), float(sk["energy"]) + 5.0)     # Passing-out parade: every skill gives 5 back
	var stamped := false
	if has_rule("registrars_stamp"):
		sk["stamp"] = int(sk.get("stamp", 0)) + 1
		if int(sk["stamp"]) % Data.STAMP_EVERY == 0:
			stamped = true                     # the Registrar's Stamp: this one's free and goes off twice
			sk["energy"] = minf(max_energy(), float(sk["energy"]) + paid)     # what this one cost, never more (the review)
	_skill_effect(m, t, f)
	if stamped:
		_skill_effect(m, t, f)


## What a skill does to the fight (its `fx`, Data.SKILLS). Timed effects keep their figure beside their timer.
func _skill_effect(m: Dictionary, t: Dictionary, f: Dictionary) -> void:
	var sk: Dictionary = m["sk"]
	var fx: Dictionary = sk["fx"]
	if f.has("coin") and rng.randf() >= float(f["coin"]):
		return                                # Coin toss: the bad side
	if f.has("shot_mult"):
		fx["shot_x"] = float(f["shot_mult"])
		_sk_set(sk, "shot_t", float(f["shot_s"]))
	if f.has("exposed"):
		fx["exposed_x"] = maxf(float(f["exposed"]), float(fx.get("exposed_x", 0.0)) if float(fx.get("exposed_t", 0.0)) > 0.0 else 0.0)
		_sk_set(sk, "exposed_t", maxf(float(f["exposed_s"]), float(fx.get("exposed_t", 0.0))))
	if f.has("hit_mult"):
		var secs: float = float(f.get("hit_s", 0.0))
		if f.has("hit_shots"):
			var gun = equipped["Primary"]
			secs = float(f["hit_shots"]) / maxf(0.1, float(Items.base_of(gun)["rof"]) * pace() if gun != null else 1.0)     # Make ready: the next ten shots, at the gun's rate
		fx["buff_x"] = maxf(float(f["hit_mult"]), float(fx.get("buff_x", 1.0)) if float(fx.get("buff_t", 0.0)) > 0.0 else 1.0)
		_sk_set(sk, "buff_t", maxf(secs, float(fx.get("buff_t", 0.0))))
	if f.has("type_mult"):
		fx["type_x"] = f["type_mult"]
		_sk_set(sk, "type_t", float(f["type_s"]))
	if f.has("hidden_s"):
		_sk_set(sk, "hidden_t", maxf(float(f["hidden_s"]), float(fx.get("hidden_t", 0.0))))
	if f.has("dodge_hits"):
		var on: int = maxi(1, mini(int(m["remaining"]), contact(t)))
		_sk_set(sk, "hidden_t", maxf(float(f["dodge_hits"]) / float(on), float(fx.get("hidden_t", 0.0))))     # Duck and weave: a hit a man a second, so many seconds
	for ty in f.get("clears", []):
		m.get("my_dots", {}).erase(ty)
		m.get("my_ails", {}).erase(ty)
	if f.get("clear_all", false):
		_clear_on_you(m)
	if f.has("ward"):
		for ty in f["ward"]:
			_sk_set(sk, "ward_%s_t" % ty, float(f["ward_s"]))
	if f.get("close_shave", false):
		fx["shave"] = true
	if f.get("no_wound_run", false):
		m["no_wound"] = true
	if f.get("wound_ward", false):
		fx["wound_ward"] = true
	if f.get("execute", false):
		if _head_out(m):
			_skill_damage(m, _skill_base() * float(f["head_mult"]), "physical", true)
		else:
			_skill_damage(m, maxf(0.0, float(m["target_hp"])))
	if f.has("hit_now"):
		var crowd: int = mini(int(f.get("spread", 1)), maxi(1, mini(int(m["remaining"]), contact(t))))
		_skill_damage(m, _skill_base() * float(f["hit_now"]) * float(crowd), "shock" if f.get("shock", false) else "physical", true)
	if f.get("shock", false):
		m["shock_t"] = maxf(float(m.get("shock_t", 0.0)), status_s(1.0))
	if f.has("dot"):
		_skill_dot(m, str(f["dot"]), float(f["dot_x"]))
	if f.has("self_hp"):
		hp = maxf(1.0, hp - max_hp() * float(f["self_hp"]))     # Danger close: it costs you, never the last of you
	if f.has("stun_one_s"):
		var dt_now: float = float(sk.get("dt", 0.0))
		var dur: float = float(f["stun_one_s"])
		sk["stun_share"] = float(sk.get("stun_share", 0.0)) + (clampf(dur / dt_now, 0.0, 1.0) if dt_now > 0.0 else 1.0)
		if dur - dt_now > 0.0:
			fx["stuns"] = fx.get("stuns", []) + [dur - dt_now]
	if f.has("trap_mult"):
		fx["trap_at"] = int(sk["seq"])
	if f.has("less_in"):
		fx["less_in_x"] = maxf(float(f["less_in"]), float(fx.get("less_in_x", 0.0)) if float(fx.get("less_in_t", 0.0)) > 0.0 else 0.0)
		_sk_set(sk, "less_in_t", maxf(float(f["less_in_s"]), float(fx.get("less_in_t", 0.0))))
	if f.has("armour_mult"):
		fx["armour_x"] = float(f["armour_mult"])
		_sk_set(sk, "armour_t", float(f["armour_s"]))
	if f.has("regen_mult"):
		fx["regen_x"] = float(f["regen_mult"])
		_sk_set(sk, "regen_t", float(f["regen_s"]))
	if f.has("fam_s"):
		_sk_set(sk, "fam_t", float(f["fam_s"]))
	if f.has("pat_down_s"):
		_sk_set(sk, "pat_t", float(f["pat_down_s"]))
	if f.has("stun_all_s"):
		_sk_set(sk, "stun_all_t", maxf(float(f["stun_all_s"]), float(fx.get("stun_all_t", 0.0))))
		if f.has("bleed_s"):
			_skill_dot(m, "bleed", float(f["bleed_s"]))
	if f.get("barred", false) and int(m["remaining"]) > 0 and not _head_out(m):
		fx["no_drop"] = true                  # counted as a kill, nothing from him (_kill reads it)
		if int(m["remaining"]) > 1:
			m["remaining"] -= 1               # one of those waiting goes
			_kill(m, t)
			_skills_on_kill(m)                # a kill: Kickback, Jackpot, Breakdown (the review)
		else:
			m["target_hp"] = minf(float(m["target_hp"]), 0.0)     # the last: down where he stands, through the kill loop
	if f.has("rounds_on_kill"):
		fx["rounds_on_kill"] = int(f["rounds_on_kill"])
	if f.has("chancer"):
		fx["chancer"] = float(f["chancer"])
	if f.has("jackpot_s"):
		fx["jackpot_cut"] = float(f["jackpot_cut"])
		_sk_set(sk, "jackpot_t", float(f["jackpot_s"]))
	if f.has("energy_now"):
		sk["energy"] = minf(max_energy(), float(sk["energy"]) + float(f["energy_now"]))
	if f.has("cd_cut"):
		for k in range(Data.SKILL_SLOTS):
			sk["cd"][k] = maxf(0.0, float(sk["cd"][k]) - float(f["cd_cut"]))
	if f.has("grenade_to_rig") and not m.get("dry", false):
		var g: Dictionary = _plain(Data.GRENADE, str(f["grenade_to_rig"]))
		if rig_room(Items.size(g)):
			rig.append(g)
	if f.has("lob"):
		_skill_lob(m, t, Items.base_named(Data.GRENADE, str(f["lob"])))


## A grenade's damage as a share: the Recruit's Ordnance (Pull the pin, Detonators) and Grenadier's double.
func grenade_mult() -> float:
	return (1.0 + tree_sum("grenade_pct") / 100.0) * (2.0 if has_node("danger_area") else 1.0)


## After a throw: Blast burns sets them burning, Ringing ears stuns everyone it hit.
func _grenade_after(m: Dictionary, single: float) -> void:
	if has_node("blast_burns"):
		if not m.has("dots"):
			m["dots"] = {}
		_dot_add(m["dots"], "fire", single * 0.5, maxf(single * 0.5, float(type_dps()["fire"])))
	if has_node("cap_shock_awe") and m.has("sk"):
		var fx_g: Dictionary = m["sk"]["fx"]
		fx_g["stun_all_t"] = maxf(1.0, float(fx_g.get("stun_all_t", 0.0)))     # a throw comes between ticks: its whole second, the next tick's share
		if not m["sk"].has("share"):                                           # counts it (the review: _sk_set's last tick's dt could eat it)
			m["sk"]["share"] = {}
		m["sk"]["share"]["stun_all_t"] = 1.0


## A skill's grenade (Lob one in): a throw's damage to everyone on you, by its type, none spent from the rig.
func _skill_lob(m: Dictionary, t: Dictionary, b: Dictionary) -> void:
	if b.is_empty():
		return
	var ty: String = str(b["type"])
	var r: float = float(t.get("res", {}).get(ty, 0.0))
	var single: float = float(b["damage"]) * fight_grow() * (1.0 + increased(ty) / 100.0) * more(ty) * (1.0 - r) * grenade_mult()
	var crowd: int = mini(int(m["remaining"]), contact(t) + (1 if has_node("grenade_extra") else 0))
	_skill_damage(m, single * crowd, ty)
	_grenade_after(m, single)
	if not m.has("dots"):
		m["dots"] = {}
	_dot_add(m["dots"], ty, single, maxf(single, float(type_dps()[ty]) * (1.0 - r)))
	m["thrown"] = int(m.get("thrown", 0)) + 1


## A kill and the skills: Kickback's energy, Jackpot's cooldowns, Breakdown's rounds; Chancer and Barred read in _kill.
func _skills_on_kill(m: Dictionary) -> void:
	if not m.has("sk"):
		return
	var sk: Dictionary = m["sk"]
	sk["energy"] = minf(max_energy(), float(sk["energy"]) + generator_kill_energy())     # Kickback
	if float(sk["fx"].get("jackpot_t", 0.0)) > 0.0:
		for k in range(Data.SKILL_SLOTS):
			sk["cd"][k] = maxf(0.0, float(sk["cd"][k]) - float(sk["fx"].get("jackpot_cut", 0.0)))
	var rk: int = int(sk["fx"].get("rounds_on_kill", 0))
	if rk > 0 and not m.get("dry", false):
		sk["fx"]["rounds_on_kill"] = 0
		var gun = equipped["Primary"]
		var ty: String = Items.ammo_type(gun) if gun != null else ""
		if ty != "" and ty != "none":
			# into the magazine in the gun, to its size (30 Oct, magazines as items), else the first of its type in the rig
			# a magazine holding rounds tops up with its own grade (the fix round); an empty one takes the feed's, else the box's
			var mg: Dictionary = mag_in("Primary")
			if mg.is_empty() or int(mg.get("rounds", 0)) <= 0:
				var loaded: Array = mags_for(gun).filter(func(x): return int(x.get("rounds", 0)) > 0 and int(x["rounds"]) < Items.mag_cap(x, gun))
				mg = loaded[0] if not loaded.is_empty() else (mg if not mg.is_empty() else (mags_for(gun)[0] if not mags_for(gun).is_empty() else {}))
			if not mg.is_empty():
				if str(mg.get("ammo", "")) == "" or int(mg.get("rounds", 0)) <= 0:
					var fed: String = Items.grade_name(feed_stack(gun))
					mg["ammo"] = fed if fed != "" else str(ammo_box(ty).get("name", ""))
				mg["rounds"] = mini(Items.mag_cap(mg, gun), int(mg.get("rounds", 0)) + rk)


## The hit that would kill you, with Code blue slotted and its energy kept: back on 30%, every ailment cleared. True if it
## took the hit.
func _skill_last_stand(m: Dictionary) -> bool:
	if m.get("last_stand_used", false) or not m.has("sk"):
		return false
	for i in range(Data.SKILL_SLOTS):
		var id: String = str(skill_slots[i])
		if id == "" or str(skill(id).get("rule", "")) != "last_stand" or not skill_known(id):
			continue
		if float(m["sk"]["energy"]) < float(skill(id)["cost"]):
			continue
		m["last_stand_used"] = true
		m["sk"]["energy"] = float(m["sk"]["energy"]) - float(skill(id)["cost"])
		m["sk"]["cast"] = int(m["sk"]["cast"]) + 1
		m["sk"]["last"] = {"slot": i, "id": id, "at": float(m["elapsed"])}
		hp = max_hp() * float(skill(id)["fx"]["last_stand_hp"])
		_clear_on_you(m)
		return true
	return false


## Whether a skill keeps a wound off: Major incident's for the run, Strapped up's for the next one (spent here).
func _skill_wound_kept(m: Dictionary) -> bool:
	if m.get("no_wound", false):
		return true
	var fx: Dictionary = m.get("sk", {}).get("fx", {})
	if fx.get("wound_ward", false):
		fx["wound_ward"] = false
		return true
	return false


## Whether a dot of `ty` can land on you now: a ward against it (Tourniquet, Antidote), or Close shave's one miss
## (spent on the first that tries).
func _skill_dot_lands(m: Dictionary, ty: String) -> bool:
	var fx: Dictionary = m.get("sk", {}).get("fx", {})
	if _skill_wards(m, ty):
		return false
	if fx.get("shave", false):
		fx["shave"] = false
		return false
	return true


## Whether a skill's ward holds `ty` off you now (Tourniquet, Antidote): the ward alone, Close shave's miss unspent
## (28 Oct: frost's and shock's pools on you read it too).
func _skill_wards(m: Dictionary, ty: String) -> bool:
	if not m.has("sk"):
		return false
	var fx: Dictionary = m["sk"].get("fx", {})
	return float(fx.get("ward_%s_t" % ty, 0.0)) > 0.0 or _sk_share(m, "ward_%s_t" % ty) > 0.0


## A timed effect starts in the tick it's cast in: that tick counts its share now and the timer keeps only what's left
## after it (the review: setting the whole length mid-tick counted the tick twice).
func _sk_set(sk: Dictionary, key: String, dur: float) -> void:
	var dt: float = float(sk.get("dt", 0.0))
	if not sk.has("share"):
		sk["share"] = {}
	sk["share"][key] = clampf(dur / dt, 0.0, 1.0) if dt > 0.0 else 1.0
	sk["fx"][key] = maxf(0.0, dur - dt)


## A skill's base: your hits a second, not the dots' burn (25 Oct, the review: a dot build's skills rode its burn).
func _skill_base() -> float:
	return float(damage_split({}, false)["hits"])     # never the gun type's edge (29 Oct, the review)


## A skill's hit on the man in front, counted with the rest (the run screen's numbers read `dealt`). `resisted`: cut
## by their resist to its type and lifted by a shock, as your gun's hits are (25 Oct, the review: skills skipped the
## game's main check); a finisher's or a throw's own figure passes false.
func _skill_damage(m: Dictionary, amount: float, ty := "physical", resisted := false) -> void:
	if resisted and m.has("t"):
		var r_ty: float = float(m["t"].get("res", {}).get(ty, 0.0))
		if ty == "physical":
			r_ty = phys_resist(r_ty)
		r_ty *= 1.0 - _skill_pat(m)
		amount *= (1.0 - r_ty) * ((1.0 + shock_amount()) if float(m.get("shock_t", 0.0)) > 0.0 else 1.0)
	if has_joint("recruit_physical"):
		amount *= 1.25                         # the Recruit's, joined with Knuckles: a skill's own hit 25% harder
	if has_rule("linemans_bag") and float(m.get("shock_t", 0.0)) > 0.0:
		amount *= Data.FX["rule/linemans_bag.skills"]     # the Lineman's Tool Bag: shocked men take more from your skills
	if has_joint("recruit_poison") and amount > 0.0:
		if not m.has("dots"):
			m["dots"] = {}
		_dot_add(m["dots"], "poison", amount * 0.3, maxf(amount * 0.3, damage_total_raw()))     # joined with the Rat Man: it poisons them (joints B, 24 Oct)
	m["target_hp"] -= amount
	_count_src(m, "skill:" + str(m.get("src_now", "")), amount)
	m["dealt"] = float(m.get("dealt", 0.0)) + amount
	if not m.has("dealt_by"):
		m["dealt_by"] = {}
	m["dealt_by"][ty] = float(m["dealt_by"].get(ty, 0.0)) + amount


## A skill's dot on the man in front: `secs` of your damage into his `ty` pool.
func _skill_dot(m: Dictionary, ty: String, secs: float) -> void:
	if not m.has("dots"):
		m["dots"] = {}
	_dot_add(m["dots"], ty, damage_total_raw() * secs, damage_total_raw())     # a skill's dot: no type edge (29 Oct)


## The share of this tick a timed effect covers: a whole tick while it runs, the part left in its last.
func _sk_share(m: Dictionary, key: String) -> float:
	var sk: Dictionary = m.get("sk", {})
	if sk.get("share", {}).has(key):
		return float(sk["share"][key])
	return 1.0 if float(sk.get("fx", {}).get(key, 0.0)) > 0.0 else 0.0


## Your hit this tick, after the skills: a shot's window, the exposure on them, a damage buff - each by the share of the
## tick it covers.
func _skill_hit_mult(m: Dictionary) -> float:
	var fx: Dictionary = m.get("sk", {}).get("fx", {})
	var x := 1.0
	x *= 1.0 + (float(fx.get("shot_x", 1.0)) - 1.0) * _sk_share(m, "shot_t")
	x *= 1.0 + float(fx.get("exposed_x", 0.0)) * _sk_share(m, "exposed_t")
	x *= 1.0 + (float(fx.get("buff_x", 1.0)) - 1.0) * _sk_share(m, "buff_t")
	return x


## A type's hit this tick after the skills (Short circuit's shock +30%).
func _skill_type_mult(m: Dictionary, ty: String) -> float:
	var fx: Dictionary = m.get("sk", {}).get("fx", {})
	var tx: Dictionary = fx.get("type_x", {})
	if not tx.has(ty):
		return 1.0
	return 1.0 + (float(tx[ty]) - 1.0) * _sk_share(m, "type_t")


## Whether their armour and resists are off (Pat down) this tick, as a share.
func _skill_pat(m: Dictionary) -> float:
	return _sk_share(m, "pat_t")


## Their fire this tick, after the skills: out of sight, all stunned, some stunned, less of it, your armour braced.
func _skill_in_mult(m: Dictionary, on_you: int) -> float:
	var fx: Dictionary = m.get("sk", {}).get("fx", {})
	var x := 1.0 - maxf(_sk_share(m, "hidden_t"), _sk_share(m, "stun_all_t"))
	var stunned: float = float(m.get("sk", {}).get("stun_share", 0.0))
	if stunned > 0.0 and on_you > 0:
		x *= maxf(0.0, float(on_you) - stunned) / float(on_you)
	x *= 1.0 - float(fx.get("less_in_x", 0.0)) * _sk_share(m, "less_in_t")
	if tree_sum("cover_pct") > 0.0 and m.has("sk"):
		x *= 1.0 - tree_sum("cover_pct") / 100.0 * _sk_effect_share(m["sk"])     # Cover me: while a skill of yours runs
	var brace: float = _sk_share(m, "armour_t")
	if brace > 0.0:
		var a: float = armour()
		var now_mit: float = a / (a + armour_k())
		var braced: float = a * float(fx.get("armour_x", 1.0)) / (a * float(fx.get("armour_x", 1.0)) + armour_k())
		x *= 1.0 - brace * (1.0 - (1.0 - braced) / maxf(0.0001, 1.0 - now_mit))     # Brace: the armour's share, as if it were 60% more (on the whole of their fire: first figures)
	return x


## The HP back, and the wound seen to: WOUND_CASH a level, the Clinic's discount on both.
## The Clinic's two jobs, priced apart (Matt, 7 Oct: "heal my HP and treat the wound separately"): the HP back
## at TREAT_CASH_PER_HP a point, the wound at WOUND_CASH a level; the Clinic's discount on both.
func _treat_rate() -> float:
	return inflation() * maxf(0.2, 1.0 - tree_sum("treat_pct") / 100.0) * (1.0 - town_stat("clinic_pct") / 100.0)


func heal_cost() -> int:
	return int(ceil(maxf(0.0, max_hp() - hp) * Data.TREAT_CASH_PER_HP * _treat_rate()))


## A wound's treatment: WOUND_CASH a level, the Clinic's discount and the Surgery's.
func wound_cost(area := "") -> int:
	if area == "":
		var all := 0
		for a in wounds:
			all += wound_cost(a)
		return all
	return int(ceil(Data.WOUND_CASH * level() * _treat_rate() * (Data.FX["yard/surgery"] if yard_has("surgery") else 1.0))) if wounds.has(area) else 0


## Both at once: what the bot pays, and the Clinic's Treat everything (the HP and every wound).
func treat_cost() -> int:
	return heal_cost() + wound_cost()


func needs_treating() -> bool:
	return hp < max_hp() or not wounds.is_empty()


func can_heal() -> bool:
	return room_open("clinic") and mission == null and hp < max_hp() - 0.5 and cash >= heal_cost()


func can_treat_wound(area := "") -> bool:
	var has: bool = wounds.has(area) if area != "" else not wounds.is_empty()
	return room_open("clinic") and mission == null and has and cash >= wound_cost(area)


func heal() -> bool:
	if not can_heal():
		return false
	chron("heal", {"cost": heal_cost(), "hp": int(hp), "max": int(max_hp())})
	cash -= heal_cost()
	hp = max_hp()
	return true


## One wound seen to, by its area; "" for every one of them.
func treat_wound(area := "") -> bool:
	if not can_treat_wound(area):
		return false
	var areas: Array = [area] if area != "" else Data.WOUND_AREAS.filter(func(a): return wounds.has(a))
	chron("treat", {"cost": wound_cost(area), "wound": ",".join(areas)})
	cash -= wound_cost(area)
	for a in areas:
		log_event(Words.WOUNDS["treated"] % [str(Data.WOUND_AREA[a]["name"]), wound_stat_name(str(wounds[a]["stat"]))])
		wounds.erase(a)
	_dry_memo.clear()
	_stats_dirty()
	return true


func treat() -> bool:
	if not room_open("clinic") or mission != null or not needs_treating() or cash < treat_cost():     # the Clinic's (13 Oct)
		return false
	chron("treat", {"cost": treat_cost(), "wound": ",".join(wounds.keys()), "hp": int(hp), "max": int(max_hp())})
	cash -= treat_cost()
	for a in Data.WOUND_AREAS:
		if wounds.has(a):
			log_event(Words.WOUNDS["treated"] % [str(Data.WOUND_AREA[a]["name"]), wound_stat_name(str(wounds[a]["stat"]))])
	if not wounds.is_empty():
		wounds = {}
		_dry_memo.clear()
		_stats_dirty()
	hp = max_hp()
	return true


# ------------------------------------------------------------------ events, saving

## An event carries the time of day it happened, as the mission log shows it.
var events_total := 0              # every line ever logged, counted (the log keeps twenty)
## A gang as it arrives (12 Oct, the lore pass): the zone's gang by name, how many, and a line of theirs, in turn.
## A harder gang (B9) is the next zone's, said so; the City's own hard core past the last.
func gang_line(m: Dictionary, size: int) -> String:
	var z: int = zone_of(int(m.get("tier", 0)))
	var hard: int = int(m["t"].get("hard_zone", -1)) if m.get("t", null) is Dictionary else -1
	if hard >= 0:
		z = hard
	if z < 0 or z >= Words.GANGS.size():
		return "Another gang, %d of them" % size
	var g: Dictionary = Words.GANGS[z]
	var said: String = Words.rotate(g["arrive"], int(m.get("patrols", 0)) + runs_total)
	if hard >= 0:
		var from: String = Words.GANG_HARD_CORE if m.has("t_home") and hard == int(m["t_home"].get("crew_zone", -1)) else Words.GANG_IN_FROM % Words.mid(str(Data.ZONES[hard]["name"]))
		return "%s, %d of them, %s. %s" % [g["name"], size, from, said]
	return "%s, %d of them. %s" % [g["name"], size, said]


## The chance the `n`th gang of a run is the next zone's crew (B9): none for the first, a step a gang past it, to the cap.
func gang_next_odds(n: int) -> float:
	return clampf(float(n - 1) * Data.GANG_NEXT_STEP, 0.0, Data.GANG_NEXT_MAX)


## The next zone's crew (B9, 15 Oct): the run's site as it is, its heads GANG_NEXT_HP harder and GANG_NEXT_DPS hotter, their
## fire and resists the next zone's at the site's depth with the words on top (the City's own, past the last). Held while
## the gang stands; the site comes back when they're down.
func _gang_harder(m: Dictionary) -> void:
	var home: Dictionary = m.get("t_home", m["t"])
	var h: Dictionary = home.duplicate()
	var z: int = mini(Data.ZONE_TYPES.size() - 1, int(home.get("crew_zone", zone_of(int(m.get("tier", 0))))) + 1)
	var wfx: Array = []
	for w in home.get("word_tiers", {}):
		wfx.append(word_effect(w, int(home["word_tiers"][w])))
	var crew: Array = _crew_types(z, int(home.get("depth", 1)), wfx)
	h["hp"] = float(home["hp"]) * Data.GANG_NEXT_HP
	h["dps"] = float(home["dps"]) * Data.GANG_NEXT_DPS
	h["types"] = crew[0]
	h["res"] = crew[1]
	h["hard_zone"] = z
	m["t_home"] = home
	m["t"] = h


## The zone a site is in, or -1.
func zone_of(tier_i: int) -> int:
	for z in range(Data.ZONES.size()):
		if tier_i in Data.ZONES[z]["tiers"]:
			return z
	return -1


## The radio's next line (12 Oct, docs/design/lore.md): the first unheard one whose gate is open - a zone open, or
## lorries beaten - or {} when there's none yet.
func radio_next() -> Dictionary:
	for k in range(Words.RADIO.size()):
		var r: Dictionary = Words.RADIO[k]
		var key := "%s/%d" % [r["voice"], k]
		if key in heard:
			continue
		if r.has("zone") and not zone_open(int(r["zone"])):
			continue
		if r.has("lorries") and lorries < int(r["lorries"]):
			continue
		if r.has("deeds") and deeds_fate != str(r["deeds"]):
			continue                              # the deeds' fate's own line (27 Oct)
		if r.has("gate") or (r.has("room") and not room_open(str(r["room"]))):
			continue                              # a gate's line is said at its gate; a room's voice once it's open (13 Oct)
		return {"key": key, "voice": r["voice"], "text": r["text"]}
	return {}


## A heard line by its key: the RADIO row, or {}.
static func radio_line(key: String) -> Dictionary:
	var k: int = int(key.get_slice("/", 1))
	if k < 0 or k >= Words.RADIO.size():
		return {}
	return Words.RADIO[k]


## Every RADIO_EVERY runs home the radio comes on: the next line, into the log and the Caravan's list.
func _radio_after_run() -> void:
	if _dry_on:
		return
	_gate_lines()                             # a room's line before it opens, the run its head's site opens (13 Oct)
	if runs_total % Data.RADIO_EVERY != 0:
		return
	var r := radio_next()
	if r.is_empty():
		return
	heard.append(r["key"])
	log_event(Words.RADIO_LEAD + str(r["text"]))     # no speaker (13 Oct): the radio line under the top bar plays it


func log_event(text: String) -> void:
	events.append([Time.get_unix_time_from_system(), text])
	events_total += 1
	while events.size() > 20:
		events.pop_front()


## What came back, started again (the card's Seen): nothing since, from the level the runner is at now.
func came_back_seen() -> void:
	came_back = {"runs": 0, "deaths": 0, "cash": 0.0, "xp": 0.0, "notes": 0, "scrap": 0, "items": 0, "lost": 0,
		"lv_from": level(), "find": {}, "firsts": [], "more": 0, "since": elapsed}


const CAME_BACK_FIRSTS := 4          # the card's lines; past that, "and N more"


## A record line, added to what came back: a run's takings, and the firsts worth a line on the card.
func _came_back_line(e: Dictionary) -> void:
	if came_back.is_empty():
		came_back_seen()
	var cb := came_back
	var line := ""
	match str(e["k"]):
		"run":
			cb["runs"] = int(cb["runs"]) + 1
			if e.get("outcome", "") == "Dead":
				cb["deaths"] = int(cb["deaths"]) + 1
				cb["lost"] = int(cb["lost"]) + int(e.get("lost_value", 0))
			else:
				cb["cash"] = float(cb["cash"]) + float(e.get("cash", 0))
				cb["xp"] = float(cb["xp"]) + float(e.get("xp", 0))
				cb["notes"] = int(cb["notes"]) + int(e.get("notes", 0))
				cb["scrap"] = int(cb["scrap"]) + int(e.get("scrap", 0))
				cb["items"] = int(cb["items"]) + int(e.get("loot", 0))
		"clear":
			line = ("First clear: %s" % e["site"]) if e.get("first", false) else ("%s held at level %d" % [e["site"], int(e.get("site_level", e["depth"]))])
		"boss":
			if e.get("first", false):
				line = "%s down" % e["name"]
		"unique":
			line = "Found %s" % e["name"]
		"paper":
			line = "Read %s" % e["name"]
		"deeds":
			line = "The deeds, from the Bank's vault"
		"lorry":
			line = "The lorry beaten"
		"story":
			cb["kev"] = int(e.get("beat", 0))     # Kev's line on the card (20 Oct, Matt: "no pay off")
		"move":
			line = "The Pitch moved on"
	if line != "":
		if cb["firsts"].size() < CAME_BACK_FIRSTS:
			cb["firsts"].append(line)
		else:
			cb["more"] = int(cb["more"]) + 1


## The dearest thing a run brought home, kept for the card (a copy: it may be sold or worn by the time it's seen).
func _came_back_find(it: Dictionary) -> void:
	if came_back.is_empty():
		came_back_seen()
	var f: Dictionary = came_back["find"]
	if f.is_empty() or int(it.get("value", 0)) > int(f.get("value", 0)):
		came_back["find"] = it.duplicate(true)


## A line in the playtest record. Never from a dry run (the odds and the bot's reads), always with the clocks.
func chron(kind: String, data := {}) -> void:
	if _dry_on:
		return
	var e := {"k": kind, "t": snappedf(elapsed, 0.1), "p": snappedf(played_s, 0.1), "w": int(Time.get_unix_time_from_system()),
		"lv": level(), "cls": cls, "sv": SITES_V}     # sv: the site numbering (12 Oct: the Outskirts moved every site up three)
	e.merge(data, true)
	chronicle.append(e)
	chron_count += 1
	if not unwatched():
		_came_back_line(e)                    # a repeat's runs have their own report (29 Oct): not the per-run card


## The shell's real time at the game: the player's hours, and a snapshot every SNAP_S of them.
func tick_played(delta: float) -> void:
	played_s += delta
	if int(played_s / SNAP_S) > _snaps:
		_snaps = int(played_s / SNAP_S)
		chron("snap", snap_line())


## What a snapshot holds: the purse, the runner, the reach, the spend.
func snap_line() -> Dictionary:
	var deepest_v := 0
	for d in best_depth:
		deepest_v = maxi(deepest_v, int(d))
	return {"cash": int(cash), "cash_in": int(cash_in), "notes": notes, "scrap": scrap, "salvage": salvage.duplicate(), "xp": int(xp),
		"best_tier": best_tier, "best_depth": best_depth.duplicate(), "deepest": deepest_v, "points": web_points(), "spent": points_spent(),
		"yard_built": yard_built(), "atlas": atlas_spent(), "stash": stash.size(), "dps": snappedf(dps(), 0.1), "max_hp": int(max_hp()),
		"mit": snappedf(mitigation(), 0.001), "runs": runs_total, "lost": operators_lost, "kit": loadout_value()}


## A worn piece, as the record keeps it.
static func _chron_item(it) -> Dictionary:
	if it == null:
		return {}
	return {"base": str(it["base"]), "name": Items.full_name(it), "slot": str(it["slot"]), "tier": int(it.get("tier", 0)),
		"rarity": int(it.get("rarity", 0)), "value": int(it.get("value", 0)), "unique": it.has("unique"), "set": it.has("set")}


func to_dict() -> Dictionary:
	var d: Dictionary = _state().duplicate(true)      # a copy: the live items aren't shared with the save
	d["expeditions"] = exp_state().duplicate(true)    # the expeditions and the hands (29 Oct)
	d["town_stopped"] = town_stopped.keys()           # the town's places stopped, unpaid (BUILD50-T)
	d["night"] = _night_save()                        # a night on the air (BUILD50 N)
	return d


func _state() -> Dictionary:
	return {
		"cash": cash, "issued": issued, "fiat_issue_inf": fiat_issue_inf, "circulation": circulation, "fiat_rate": fiat_rate, "issued_serial": issued_serial, "issue_moment": issue_moment,
		"xp": xp, "hp": hp, "equipped": equipped, "rig": rig, "stash": stash, "market": market, "gamble": gamble,
		"mission": mission, "last_report": last_report, "operators_lost": operators_lost,
		"best_tier": best_tier, "depot_cleared": depot_cleared, "elapsed": elapsed, "events": events,
		"next_id": Items._next_id, "auto_equip": auto_equip, "junk_upto": junk_upto, "junk_keep": junk_keep, "came_back": came_back, "tree": tree, "training_points": training_points, "best_level": best_level, "web_rewards": rewards_earned,
		"words": words, "sealed": sealed, "filtered": filtered, "standing": standing, "depth": depth, "best_depth": best_depth, "class": cls, "crew": roster,
		"yard_picks": yard_picks.duplicate(true), "yard_ranks": yard_ranks.duplicate(), "yard_open": yard_open, "salvage": salvage.duplicate(),
		"yard_seen": yard_seen.keys(), "yard_seen_cols": yard_seen_cols,
		"hardcore": hardcore, "camp_lost": camp_lost, "clinic": clinic, "supplies_in": supplies_in, "wounds": wounds.duplicate(true),
		"past": past, "past_folded": past_folded.duplicate(), "loose_kit": loose_kit, "book": book.duplicate(), "heard": heard.duplicate(), "shelf": shelf.duplicate(), "keepsakes": keepsakes.duplicate(), "shelf_tier": shelf_tier.duplicate(), "site_crates": site_crates.duplicate(true), "site_runs": site_runs.duplicate(true), "left_behind": left_behind.duplicate(), "weather": weather.duplicate(), "weather_at": weather_at, "last_next": last_next, "events_total": events_total, "runner_runs": runner_runs, "record": record.duplicate(), "seen": seen, "deeds_found": deeds_found, "unlocked": unlocked.duplicate(), "met": met.duplicate(), "deeds_fate": deeds_fate, "deeds_back": deeds_back, "lorry_done": lorry_done, "lorries": lorries, "paragon_xp": paragon_xp, "best_dig": best_dig.duplicate(), "clear_level": clear_level.duplicate(), "stages": a55_save(), "workbench_day": workbench_day, "patterns": patterns.duplicate(true), "loot_rules": loot_rules.duplicate(true), "loot_rules_on": loot_rules_on, "sets_seen": sets_seen.duplicate(), "loadouts": loadouts.duplicate(true), "ring": ring.duplicate(),
		"signals": signals.duplicate(true), "reach": reach, "signal_seq": signal_seq, "story_beat": story_beat, "story_at": story_at, "papers": papers,
		"materials": materials.duplicate(), "key_items": key_items.duplicate(), "rebuilt": rebuilt.duplicate(), "order_beaten": order_beaten.duplicate(),
		"bosses_beaten": bosses_beaten, "notes": _notes, "scrap": scrap, "takings": takings, "gamble_base": gamble_base, "atlas": atlas, "atlas_points": atlas_points, "boss_paid": boss_paid,
		"exchange_day": exchange_day, "mate": mate, "runs_total": runs_total, "wounded_total": wounded_total, "insure_next": insure_next, "top_up_mode": top_up_mode, "rounds_plans": rounds_plans,
		"trait": runner_trait, "candidates": candidates, "promised": promised,
		"chron_count": chron_count, "chronicle_v": CHRONICLE_V, "played_s": played_s,
		"skill_slots": skill_slots, "skill_auto": skill_auto,
		"repeat": repeat, "repeat_report": repeat_report, "wagers": wagers,
		"trader_standing": trader_standing, "standing_orders": standing_orders, "event_last": event_last, "event_threads": event_threads,
	}


## The site numbering (12 Oct): 2 since the Outskirts came before the Estate. The record's lines carry it ("sv"), so
## tools/playtest_summary.gd reads a line from before with its sites where they stood.
const SITES_V := 2


func load_dict(d: Dictionary) -> void:
	gate_box_always = false                      # the bot's flag, set again by its packing (the three-stage review, tools 2)
	_issued_cache.clear()                        # its pieces' ids were the old run of ids (the review)
	_els_key = -1                         # the build's elements read again from the loaded tree
	_rules_key = []                       # and the rules in play (22 Oct), and the pile's ids
	_pile_ids_key = []
	d = d.duplicate(true)                # the save's items stay the save's; the live ones are copies
	issued = bool(d.get("issued", false))
	fiat_issue_inf = float(d.get("fiat_issue_inf", 1.0))
	circulation = float(d.get("circulation", 0.0))
	fiat_rate = float(d.get("fiat_rate", 1.0))
	issued_serial = int(d.get("issued_serial", 0))
	issue_moment = d.get("issue_moment", {})
	cash = float(d.get("cash", Data.STARTING_CASH))
	xp = float(d.get("xp", 0.0))
	_stats_dirty()
	hp = float(d.get("hp", Data.BASE_HP))
	var e: Dictionary = d.get("equipped", {})
	for s in Data.SLOTS:
		equipped[s] = e.get(s, null)
		_stats_dirty()
	rig = d.get("rig", [])
	stash = d.get("stash", [])
	market = d.get("market", [])
	gamble = d.get("gamble", [])
	clinic = d.get("clinic", [])
	supplies_in = int(d.get("supplies_in", 0))
	mission = d.get("mission", null)
	_haul_names_up(mission)
	repeat = d.get("repeat", {})                 # away on a repeat (29 Oct): saved mid-repeat, back where it was
	repeat_report = d.get("repeat_report", {})
	wagers = d.get("wagers", {})
	for wk in wagers:
		wagers[wk]["taken"] = Array(wagers[wk].get("taken", [])).map(func(x): return int(x))     # JSON's floats: the offer's indices
	if mission is Dictionary:
		if mission.get("pack_key", null) is Array:
			mission["pack_key"] = mission["pack_key"].map(func(v): return int(v))     # JSON's floats: the shape reads as itself
		for f in mission.get("found", []):
			if f.get("pos", null) is Array:
				f["pos"] = [int(f["pos"][0]), int(f["pos"][1])]
	last_report = d.get("last_report", null)
	operators_lost = int(d.get("operators_lost", 0))
	best_tier = int(d.get("best_tier", 0))
	auto_equip = bool(d.get("auto_equip", false))
	junk_upto = int(d.get("junk_upto", -1))
	junk_keep = str(d.get("junk_keep", ""))
	if not JUNK_KEEPS.has(junk_keep):
		junk_keep = ""
	came_back = d.get("came_back", {})
	tree = d.get("tree", [])
	_stats_dirty()
	cls = d.get("class", "")
	roster = {}
	var cw = d.get("crew", {})
	if cw is Dictionary:
		for k in cw:
			if cw[k] is Dictionary:
				var r: Dictionary = cw[k].duplicate(true)
				var eq: Dictionary = {}
				for sl in Data.SLOTS:
					eq[sl] = r.get("equipped", {}).get(sl, null)
				r["equipped"] = eq
				r["xp"] = float(r.get("xp", 0.0))
				roster[str(k)] = r     # the crew: each other class's own (21 Oct)
	runner_trait = str(d.get("trait", ""))
	candidates = d.get("candidates", [])
	promised = str(d.get("promised", ""))
	trader_standing = d.get("trader_standing", {})
	standing_orders = d.get("standing_orders", {})
	event_last = str(d.get("event_last", ""))
	event_threads = d.get("event_threads", {})
	chronicle = []                        # the record's lines live in their file, never the save
	chron_count = int(d.get("chron_count", 0))
	played_s = float(d.get("played_s", 0.0))
	_snaps = int(played_s / SNAP_S)
	# trees from before the class trees: nodes that aren't in the trees on show are refunded
	var kept := []
	for id in tree:
		if _on_show(str(id).get_slice("/", 0)) and not node(str(id)).is_empty():
			kept.append(id)
	tree = kept
	_ensure_start(false)                  # the class's start (the skill web): an older tree's runner holds it too
	_stats_dirty()
	_load_yard(d)
	skill_slots = d.get("skill_slots", ["", "", ""]).duplicate()
	skill_auto = d.get("skill_auto", [true, true, true]).duplicate()
	hardcore = bool(d.get("hardcore", false))
	wounds = {}
	_stats_dirty()
	var saved_w = d.get("wounds", {})
	if saved_w is Dictionary:
		for a in saved_w:
			if str(a) in Data.WOUND_AREAS and saved_w[a] is Dictionary:
				wounds[str(a)] = {"stat": str(Data.WOUND_AREA[str(a)]["stat"]), "what": str(saved_w[a].get("what", "")), "from": str(saved_w[a].get("from", "")), "hp_pct": int(saved_w[a].get("hp_pct", 0))}
	camp_lost = bool(d.get("camp_lost", false))
	if d.has("depth"):
		for i in range(Data.TIERS.size()):
			if i < d["depth"].size():
				depth[i] = int(d["depth"][i])
				best_depth[i] = int(d["best_depth"][i])
	# the Radio's words (9 Oct): a save from before map juicing has its old words cleared
	var dw: Array = d.get("words", [])
	var ds: Array = d.get("sealed", [])
	for i in range(Data.TIERS.size()):
		words[i] = []
		sealed[i] = false
		if i < dw.size():
			for wd in dw[i]:
				if wd is Dictionary and not Data.word_of(str(wd.get("w", ""))).is_empty():
					words[i].append({"w": str(wd["w"]), "t": int(wd.get("t", 1))})
		if i < ds.size():
			sealed[i] = bool(ds[i])
	filtered = str(d.get("filtered", ""))
	standing = []
	for sw in d.get("standing", []):
		standing.append(str(sw))
	training_points = int(d.get("training_points", maxi(0, level() - 1)))
	best_level = int(d.get("best_level", level()))
	rewards_earned = {}
	var wr: Dictionary = d.get("web_rewards", {})
	for rk in wr:
		rewards_earned[str(rk)] = [int(wr[rk][0]), str(wr[rk][1])]
	_web_legal_all()                         # a tree the rule can't make loads as one it can (3 Nov, the review of build 47)
	depot_cleared = bool(d.get("depot_cleared", false))
	past = d.get("past", [])
	past_folded = Dictionary(d.get("past_folded", {})).duplicate()
	_past_fold()                             # an old save's whole list (1,079 runners on the long reads) folded as it loads
	loose_kit = Array(d.get("loose_kit", []))
	book = Array(d.get("book", []))
	heard = Array(d.get("heard", []))
	shelf = Array(d.get("shelf", []))
	keepsakes = Array(d.get("keepsakes", []))
	shelf_tier = {}
	for k in d.get("shelf_tier", {}):
		shelf_tier[str(k)] = int(d["shelf_tier"][k])
	site_crates = {}
	for k in d.get("site_crates", {}):
		site_crates[str(k)] = Dictionary(d["site_crates"][k]).duplicate(true)
	site_runs = {}
	for k in d.get("site_runs", {}):
		site_runs[str(k)] = Dictionary(d["site_runs"][k]).duplicate(true)
	left_behind = {}
	for k in d.get("left_behind", {}):
		left_behind[str(k)] = int(d["left_behind"][k])
	if d.has("weather"):
		for z in range(mini(weather.size(), d["weather"].size())):
			weather[z] = str(d["weather"][z])
	weather_at = int(d.get("weather_at", -1))
	last_next = str(d.get("last_next", ""))
	events_total = int(d.get("events_total", events.size()))
	runner_runs = int(d.get("runner_runs", 0))
	if d.has("record"):
		record = d["record"].duplicate()
	seen = d.get("seen", {})
	clear_level = {}
	for k in d.get("clear_level", {}):
		clear_level[int(k)] = int(d["clear_level"][k])     # JSON's keys come back as strings
	a55_load(d)                               # (BUILD55-A) the stages
	workbench_day = int(d.get("workbench_day", -1))
	loot_rules_on = bool(d.get("loot_rules_on", true))
	sets_seen = Array(d.get("sets_seen", [])).map(func(x): return str(x))
	loadouts = {}
	var lo = d.get("loadouts", {})
	if lo is Dictionary:
		for c in lo:
			if lo[c] is Array:
				var three: Array = []
				for k in range(Data.LOADOUTS):
					var le = lo[c][k] if k < lo[c].size() else {}
					three.append(_loadout_clean(le if le is Dictionary else {}))
				loadouts[str(c)] = three
	loot_rules = []
	for r in d.get("loot_rules", []):
		if r is Dictionary:
			var nr: Dictionary = loot_rule_new()
			for k in nr:
				if r.has(k):
					if nr[k] is int:
						nr[k] = int(r[k])
					elif nr[k] is bool:
						nr[k] = bool(r[k])
					else:
						nr[k] = str(r[k])
			loot_rules.append(nr)
	patterns = []
	for pt in d.get("patterns", []):
		if pt is Dictionary and pt.has("rule"):
			patterns.append({"unique": str(pt.get("unique", "")), "slot": str(pt.get("slot", "")), "rule": str(pt["rule"])})
	deeds_found = bool(d.get("deeds_found", false))
	unlocked = Array(d.get("unlocked", []))
	met = Array(d.get("met", []))
	deeds_fate = str(d.get("deeds_fate", ""))
	deeds_back = bool(d.get("deeds_back", false))
	lorry_done = bool(d.get("lorry_done", false))
	lorries = int(d.get("lorries", 0))
	paragon_xp = float(d.get("paragon_xp", 0.0))
	ring = {}
	for k in d.get("ring", {}):
		ring[str(k)] = int(d["ring"][k])     # JSON reads the counts as floats
		_stats_dirty()
	best_dig = d.get("best_dig", {}).duplicate() if d.get("best_dig", {}) is Dictionary else {}
	signals = d.get("signals", []).duplicate(true)
	for sg in signals:
		_sig_ints(sg)
	reach = int(d.get("reach", Data.REACH_START))
	signal_seq = int(d.get("signal_seq", 0))
	story_beat = int(d.get("story_beat", 0))
	story_at = {}
	var sa: Dictionary = d.get("story_at", {})
	for kb in sa:
		story_at[int(kb)] = float(sa[kb])           # the keys come back strings through the save
	papers = d.get("papers", []).duplicate(true)
	materials = _counts(d.get("materials", {}))
	key_items = _counts(d.get("key_items", {}))
	rebuilt = _counts(d.get("rebuilt", {}))
	order_beaten = _counts(d.get("order_beaten", {}))
	b61_load(d)                               # (BUILD61-A) the County's stages, after the wins (a 26 save's carry over)
	_sig = {}
	if mission != null and mission.get("signal", null) is Dictionary:
		_sig = mission["signal"]                 # a signal's run, saved mid-run: its site still carries it
		_sig_ints(_sig)
	_notes = int(d.get("notes", 0)) if not issued else 0
	scrap = int(d.get("scrap", 0))
	takings = float(d.get("takings", 0.0))
	gamble_base = float(d.get("gamble_base", takings))     # an older save: from where its price stood
	atlas = {}
	for k in d.get("atlas", {}):
		if not Data.atlas_of(str(k)).is_empty():
			atlas[str(k)] = mini(int(d["atlas"][k]), int(Data.atlas_of(str(k))["max"]))     # a node the map dropped (9 Oct: the air) gives its points back
	atlas_points = int(d.get("atlas_points", 0))
	boss_paid = []
	var paid: Array = d.get("boss_paid", [])
	for i in range(Data.TIERS.size()):
		var at: Array = []
		if i < paid.size() and paid[i] is Array:
			for x in paid[i]:
				at.append(int(x))
		boss_paid.append(at)
	exchange_day = int(d.get("exchange_day", 0))     # the exchange (28 Oct): an old save's "contracts" are ignored
	mate = {}
	if d.has("mate") and not d["mate"].is_empty():
		mate = {"unique": str(d["mate"]["unique"]), "notes": int(d["mate"]["notes"])}
		if d["mate"].has("tier"):
			mate["tier"] = int(d["mate"]["tier"])     # the tier he has it at (12 Oct): a reload keeps the offer as offered
	if mate.is_empty():
		mate = roll_mate()
	runs_total = int(d.get("runs_total", 0))
	wounded_total = int(d.get("wounded_total", 0))
	insure_next = bool(d.get("insure_next", false))
	top_up_mode = str(d.get("top_up_mode", "fill")) if str(d.get("top_up_mode", "fill")) in TOP_UP_MODES else "fill"     # the old button's, as the camp's plan (BUILD46-R: it migrates)
	if d.get("rounds_plans", null) is Dictionary:
		rounds_plans = Dictionary(d["rounds_plans"]).duplicate(true)
	var bb: Array = d.get("bosses_beaten", [])
	for z in range(Data.ZONES.size()):
		bosses_beaten[z] = bool(bb[z]) if z < bb.size() else false
	elapsed = float(d.get("elapsed", 0.0))
	events = d.get("events", [])
	Items._next_id = maxi(Items._next_id, int(d.get("next_id", 1)))
	_reseed()
	# JSON turns ints to floats; the sim's counters want ints back
	if mission != null:
		for k in ["remaining", "kills", "left", "tier", "searches", "patrols"]:
			mission[k] = int(mission[k])
		for k in ["pool", "loot_tier", "contact", "depth", "tier"]:
			mission["t"][k] = int(mission["t"][k])
			if mission.has("t_home"):
				mission["t_home"][k] = int(mission["t_home"][k])     # a harder gang standing (B9)
	var crate_items: Array = []
	if mission != null and mission.has("crates"):
		mission["crate_i"] = int(mission.get("crate_i", 0))
		for q in mission["crates"]:
			q["searches"] = int(q["searches"])
			q["done"] = int(q["done"])
			crate_items.append_array(q.get("finds", []))
			if q.has("held"):
				crate_items.append(q["held"]["it"])
	if mission != null:
		crate_items.append_array(mission.get("floor", []))
	for it in _all_items() + crate_items + _roster_items():
		it["id"] = int(it["id"])
		it["rarity"] = int(it["rarity"])
		it["tier"] = int(it["tier"])
		it["value"] = int(it["value"])
		if it.has("rounds"):
			it["rounds"] = int(it["rounds"])
	if market.is_empty():
		restock()
	_skills_known_only()                  # a slot the runner can't use is free (25 Oct, the review)
	exp_load(d.get("expeditions", {}))    # the expeditions and the hands (29 Oct)
	town_stopped = {}
	for k in d.get("town_stopped", []):
		town_stopped[str(k)] = true       # the town's places stopped, unpaid (BUILD50-T)
	_night_load(d.get("night", {}) if d.get("night", {}) is Dictionary else {})     # a night on the air (BUILD50 N)


## The crew's kit, the runners not out (21 Oct): their worn pieces, their rigs, what's fitted in them - for the load's
## number clean-up only (the rest of the sim never reaches them).
func _roster_items() -> Array:
	var out: Array = []
	for k in roster:
		for sl in Data.SLOTS:
			var it = roster[k].get("equipped", {}).get(sl, null)
			if it != null:
				out.append(it)
		out.append_array(roster[k].get("rig", []))
		out.append_array(roster[k].get("tab_items", []))
	var nested: Array = []
	for it in out:
		for mount in it.get("attachments", {}):
			if it["attachments"][mount] != null:
				nested.append(it["attachments"][mount])
	out.append_array(nested)
	return out


func _all_items() -> Array:
	var out: Array = []
	for s in Data.SLOTS:
		if equipped[s] != null:
			out.append(equipped[s])
	out.append_array(rig)
	out.append_array(stash)
	out.append_array(papers)
	out.append_array(market)
	if mission != null:
		out.append_array(mission["found"])
	# attachments fitted on guns ride inside them
	var nested: Array = []
	for it in out:
		for mount in it.get("attachments", {}):
			if it["attachments"][mount] != null:
				nested.append(it["attachments"][mount])
		if it.get("mag_item", null) is Dictionary:
			nested.append(it["mag_item"])         # a gun's own magazine, carried on it (the second review)
	out.append_array(nested)
	return out


# ------------------------------------------------------------------ the collection (24 Oct, the endgame chase, phase 6)

## What's been found and done across every runner, for the Stats room's collection: no power from any of it.
## {"tiles": [[key, n, of]], "uniques": [[name, slot, found]], "sites": [[name, best level]]}.
func collection() -> Dictionary:
	var uniques: Array = []
	var myth_n := 0
	var myth_of := 0
	for u in Data.UNIQUES:
		var found: bool = str(u["name"]) in shelf
		if u.get("mythic", false):
			myth_of += 1
			myth_n += 1 if found else 0
		else:
			uniques.append([str(u["name"]), str(u["slot"]), found])
	var sites: Array = []
	var deep := 0
	for i in range(Data.TIERS.size()):
		var d: int = int(best_depth[i]) if i < best_depth.size() else 0
		var lv: int = lv_at(i, d) if d > 0 else 0          # levels on screen, never depth (the language pass)
		sites.append([str(Data.TIERS[i]["name"]), lv])
		deep += 1 if lv >= int(Data.COLLECTION_LEVELS[-1]) else 0
	var classes := 0
	for c in Data.CLASSES:
		classes += 1 if crew_level(str(c["name"])) >= Data.COLLECTION_CLASS_LEVEL else 0
	var orders := 0
	var order_of := 0
	for p in Data.PINNACLES:
		order_of += 1
		orders += 1 if int(order_beaten.get(str(p["key"]), 0)) > 0 else 0
	var seen_pcs: Array = sets_seen.duplicate()          # with what's held: a camp from before the log counts its pieces
	for it in stash + equipped.values():
		if it != null and it.has("piece") and not (str(it["piece"]) in seen_pcs):
			seen_pcs.append(str(it["piece"]))
	var sets := 0
	for st in Data.SETS:
		sets += 1 if st["pieces"].all(func(pc): return str(pc["name"]) in seen_pcs) else 0
	var found_n: int = uniques.filter(func(x): return x[2]).size()
	return {"tiles": [["uniques", found_n, uniques.size()], ["mythics", myth_n, myth_of], ["sites", deep, Data.TIERS.size()],
			["classes", classes, Data.CLASSES.size()], ["order", orders, order_of], ["sets", sets, Data.SETS.size()]],
		"uniques": uniques, "sites": sites}


# ------------------------------------------------------------------ loadouts and build codes (24 Oct, the endgame chase, phase 7)

## Three loadouts a runner, kept by class: the gear by id (and its name, to say what's gone), the rig's bases in order,
## the three skills. Wearing one swaps from the stash; a piece that's gone is named and what's on stays on.
var loadouts := {}                  # class -> [Data.LOADOUTS of {} or {"gear": {slot: id}, "names": {slot: name}, "rig": [bases], "skills": [ids]}]


static func _loadout_clean(e: Dictionary) -> Dictionary:
	if e.is_empty() or not (e.get("gear", null) is Dictionary):
		return {}
	var out := {"gear": {}, "names": {}, "rig": [], "skills": []}
	for slot in e["gear"]:
		out["gear"][str(slot)] = int(e["gear"][slot])
		out["names"][str(slot)] = str(e.get("names", {}).get(slot, ""))
	out["rig"] = Array(e.get("rig", [])).map(func(x): return str(x))
	out["skills"] = Array(e.get("skills", [])).map(func(x): return str(x))
	return out


func loadout(i: int) -> Dictionary:
	var three: Array = loadouts.get(cls, [])
	return three[i] if i >= 0 and i < three.size() else {}


## What's worn now, kept in loadout i.
func loadout_save(i: int) -> bool:
	if i < 0 or i >= Data.LOADOUTS or cls == "":
		return false
	if not loadouts.has(cls):
		loadouts[cls] = []
		for k in range(Data.LOADOUTS):
			loadouts[cls].append({})
	var e := {"gear": {}, "names": {}, "rig": [], "skills": skill_slots.duplicate()}
	for slot in Data.SLOTS:
		if equipped.get(slot) != null:
			e["gear"][slot] = int(equipped[slot]["id"])
			e["names"][slot] = Items.full_name(equipped[slot])
	for it in rig:
		e["rig"].append(str(it["base"]))
	loadouts[cls][i] = e
	chron("loadout", {"what": "save", "i": i})
	return true


## "empty", "worn" (it's what's on), "ready" (every piece to hand) or "short" (a piece gone).
func loadout_state(i: int) -> String:
	var e := loadout(i)
	if e.is_empty():
		return "empty"
	var all_on := true
	for slot in e["gear"]:
		var id: int = int(e["gear"][slot])
		if equipped.get(slot) != null and int(equipped[slot]["id"]) == id:
			continue
		all_on = false
		if not stash.any(func(x): return int(x["id"]) == id):
			return "short"
	return "worn" if all_on and e["skills"] == skill_slots else "ready"


## The pieces a loadout names that aren't to hand.
func loadout_missing(i: int) -> Array:
	var e := loadout(i)
	var out := []
	for slot in e.get("gear", {}):
		var id: int = int(e["gear"][slot])
		var on: bool = equipped.get(slot) != null and int(equipped[slot]["id"]) == id
		if not on and not stash.any(func(x): return int(x["id"]) == id):
			out.append(str(e["names"].get(slot, slot)))
	return out


## Into loadout i: each piece from the stash into its slot, the rig topped up to its bases, the skills slotted. What
## won't come (gone, or no room for what comes off) is named in the log; what's on stays on. False on a run or empty.
func loadout_wear(i: int) -> bool:
	var e := loadout(i)
	if e.is_empty() or runner_busy():
		return false
	_dry_memo.clear()
	_stats_dirty()
	var missed: Array = []
	for slot in e["gear"]:
		var id: int = int(e["gear"][slot])
		if equipped.get(slot) != null and int(equipped[slot]["id"]) == id:
			continue
		if not (stash.any(func(x): return int(x["id"]) == id) and equip_item(id)):
			missed.append(str(e["names"].get(slot, slot)))
	# the rig: each base it held, as many as it held, from the stash if the rig is short of them
	var want := {}
	for b in e["rig"]:
		want[b] = int(want.get(b, 0)) + 1
	for b in want:
		var have: int = rig.filter(func(x): return str(x["base"]) == b).size()
		for it in stash.filter(func(x): return str(x["base"]) == b and Items.rig_item(x)):
			# a box gives a pouch a take (28 Oct, the review: one pouch a box left a kit of three pouches short): take
			# again while it's there, counting what the rig holds of the base
			while have < int(want[b]) and stash.has(it) and take(int(it["id"])):
				have = rig.filter(func(x): return str(x["base"]) == b).size()
			if have >= int(want[b]):
				break
		if have < int(want[b]):
			missed.append(str(b))                 # the rig short of it: none in the stash, or no room (the review)
	_fill_mags()                              # the magazines taken in, filled from the boxes (30 Oct)
	for k in range(mini(e["skills"].size(), Data.SKILL_SLOTS)):
		set_skill_slot(k, str(e["skills"][k]) if skill_known(str(e["skills"][k])) else "")
	chron("loadout", {"what": "wear", "i": i, "missed": missed.size()})
	log_event(Words.LOADOUTS["worn"] % (i + 1) if missed.is_empty() else Words.LOADOUTS["worn_short"] % [i + 1, ", ".join(missed)])
	return true


## A build as a code: the class, the web's nodes in the order taken, the three skills. "FIAT1-" and the bytes as
## url-safe base64: [class][skills n][skill...][node high, node low]... - a node by its place in the layout's order
## (Data.web_ids; two bytes, the web's version two has 1,549), a skill by its index in the sorted list, so it's short.
static func _build_skills() -> Array:
	var ids: Array = Data.SKILLS.keys()
	ids.sort()
	return ids


## The lists a code indexes, as one byte: a code from a game whose trees or skills have moved reads as another
## version's, not as a build of other nodes (the review).
static func _build_version() -> int:
	var bits: Array = []
	for t in Data.TREES + Data.ELEMENT_TREES:
		bits.append("%s:%d" % [t["name"], t["nodes"].size()])
		for nd in t["nodes"]:
			bits.append("%s@%s" % [nd.get("name", ""), nd.get("slot", "")])     # the web's layout too (3 Nov): a node moved is another build
	bits.append_array(_build_skills())
	return hash(",".join(bits)) & 0xff


## A web node's place in the layout's order (the code's two bytes), built once.
static var _build_at := {}
static func _build_index() -> Dictionary:
	if _build_at.is_empty():
		var ids: Array = Data.web_ids()
		for i in range(ids.size()):
			_build_at[str(ids[i])] = i
	return _build_at


func build_code() -> String:
	var skills := _build_skills()
	var b := PackedByteArray()
	b.append(_build_version())
	b.append(maxi(0, Data.CLASSES.map(func(c): return str(c["name"])).find(cls)))
	var sk: Array = skill_slots.filter(func(x): return str(x) != "" and skills.has(str(x)))
	b.append(sk.size())
	for id in sk:
		b.append(skills.find(str(id)))
	var at := _build_index()
	for id in tree:
		if not at.has(str(id)) or is_ring(str(id)):
			continue                          # the runner's web; the ring is the crew's (the review)
		b.append(int(at[str(id)]) >> 8)
		b.append(int(at[str(id)]) & 0xff)
	return Data.BUILD_PREFIX + Marshalls.raw_to_base64(b).replace("+", "-").replace("/", "_").replace("=", "")


## A code read back: {"cls", "nodes", "skills"}, or {} when it isn't one.
func build_read(code: String) -> Dictionary:
	code = code.strip_edges()
	if not code.begins_with(Data.BUILD_PREFIX):
		return {}
	var raw: String = code.substr(Data.BUILD_PREFIX.length())
	for ch in raw:
		if not (ch in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"):
			return {}                        # not the code's letters: the decoder would complain aloud
	var body: String = raw.replace("-", "+").replace("_", "/")
	while body.length() % 4 != 0:
		body += "="
	var b: PackedByteArray = Marshalls.base64_to_raw(body)
	if b.size() < 3:
		return {}
	if int(b[0]) != _build_version():
		return {"old": true}
	b = b.slice(1)
	if int(b[0]) >= Data.CLASSES.size():
		return {}
	var ids: Array = Data.web_ids()
	var skills := _build_skills()
	var n: int = int(b[1])
	if b.size() < 2 + n or (b.size() - 2 - n) % 2 != 0:
		return {}
	var out := {"cls": str(Data.CLASSES[int(b[0])]["name"]), "skills": [], "nodes": []}
	for k in range(n):
		if int(b[2 + k]) >= skills.size():
			return {}
		out["skills"].append(str(skills[int(b[2 + k])]))
	var k2: int = 2 + n
	while k2 < b.size():
		var i: int = (int(b[k2]) << 8) | int(b[k2 + 1])
		if i >= ids.size():
			return {}
		var id: String = str(ids[i])
		out["nodes"].append(id)
		k2 += 2
	return out


## What retraining into a build would do, tried on a copy: {"block": "" or why not, "cost": tins, "trained": n,
## "of": n, "missed": [names]}. Nothing here changes.
func build_plan(bd: Dictionary) -> Dictionary:
	if bd.is_empty() or bd.has("old"):
		return {"block": Words.BUILD["old"] if bd.has("old") else Words.BUILD["bad"], "cost": 0, "trained": 0, "of": 0, "missed": []}
	if mission != null:
		return {"block": Words.BUILD["out"], "cost": 0, "trained": 0, "of": bd["nodes"].size(), "missed": []}
	if str(bd["cls"]) != cls:
		return {"block": Words.BUILD["class"] % str(bd["cls"]), "cost": 0, "trained": 0, "of": bd["nodes"].size(), "missed": []}
	var copy = get_script().new()
	copy.load_dict(JSON.parse_string(JSON.stringify(to_dict())))
	copy._dry_on = true
	var r: Dictionary = copy._build_apply(bd)
	return r


## Tins as the screen writes them (Fmt.money's form; the sim loads no UI script): "12,000 tins".
static func _tins_words(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return "%s%s %s" % [s, out, "tin" if n == 1 else "tins"]


func build_apply(bd: Dictionary) -> Dictionary:
	var plan := build_plan(bd)
	if str(plan["block"]) != "":
		return plan
	return _build_apply(bd)


func _build_apply(bd: Dictionary) -> Dictionary:
	var cost := 0
	var mine: Array = tree.filter(func(id): return not is_ring(str(id)))
	var wanted: Array = bd["nodes"].filter(func(id): return not is_ring(str(id)))
	if mine.any(func(id): return not wanted.has(id)):          # a reset only when something trained isn't in the code (the review)
		cost = respec_cost()
		if cash < cost:
			return {"block": Words.BUILD["short"] % _tins_words(cost), "cost": cost, "trained": 0, "of": bd["nodes"].size(), "missed": []}
		respec()
	var trained := 0
	var left: Array = []
	for id in wanted:
		if tree.has(id):
			trained += 1
		else:
			left.append(str(id))
	# in passes until one trains none (3 Nov, the review of build 47): a code in any order trains whole, each node by
	# the rule as it comes in reach - joined, its gate, a point free
	var took := true
	while took and not left.is_empty():
		took = false
		var still: Array = []
		for id in left:
			if train_node(str(id)):
				trained += 1
				took = true
			else:
				still.append(id)
		left = still
	var missed: Array = left.map(func(id): return str(node(str(id)).get("name", id)))
	for k in range(Data.SKILL_SLOTS):
		set_skill_slot(k, str(bd["skills"][k]) if k < bd["skills"].size() and skill_known(str(bd["skills"][k])) else "")
	return {"block": "", "cost": cost, "trained": trained, "of": wanted.size(), "missed": missed}


# ------------------------------------------------------------------ expeditions (29 Oct, docs/design/trips.md 3, 4 line B, 6)

## The endgame's expeditions (the design's "trips"): once the Quartermaster falls, a crew - a runner of another of the
## camp's classes leading (never the selected one: a watched run always pays more), up to two hired hands - takes cargo
## (salvage, rebuild materials, meds, scrap, notes) to a far place and comes back after its played time with that
## place's rewards, sized and graded by the cargo's worth (Settlers' "shipment value": they convert, they don't print).
## The odds are the gate's dry read of the lead's kit against the place's fight (Data.EXP_HOST at the place's level, its
## gang's types; never fought on screen); the risk is the cargo's worth over the lead's kit's and the odds short of
## 100%, the hands' trades and the Bunkhouse's rank bringing it down. A bad roll loses 25-100% of the return; nobody
## dies. Now and then (more at high risk) the crew comes back held: fetched by the selected runner (a watched run at a
## site with a head, the head the holder), ransomed, or walked away from (the cargo and the hands sent are gone).
## Played time only: the world waits while the game's shut.
var expeditions: Array = []        # {id, place, lead, hands: [ids], cargo: [{kind, n}], worth, odds, risk, hold, t0, dur, slot, state "out"/"back"/"held", res, seen}
var hands: Array = []              # the roster: hired hands, items of slot "Hand" (Items.roll_hand)
var hand_pool: Array = []          # the Bunkhouse's six to hire
var exp_seq := 0
var exp_sent := 0                  # expeditions sent, all told
var quota_done := {}               # place key -> the week its quota was met
var gamble_tokens := 0             # Bristol's: the Fence's gamble free, one a token
var rebuild_halves := 0            # Birmingham's quota: the next rebuild at half
var _exp_fetch := -1               # the hold-up being fetched: its head comes free for the run (boss_cost)
var _exp_cache := {}               # "lead/place/..." -> the odds' cache, as a signal's
var _exp_now := {}                 # and the last read, [odds, settled]: the screens read it, running none
## The balance read's tallies (the fix round, 29 Oct): saved, all told.
var exp_back_n := 0                # crews home with a return
var exp_held_n := 0                # held up
var exp_worth_out := 0.0           # the cargo's worth shipped
var exp_return_in := 0.0           # the returns' worth rolled
var exp_wages_paid := 0
var exp_scrap_out := 0             # scrap shipped (spent, as the Bench's is)


## The expeditions out or waiting, at their cargo's worth: what joins the Issue's pile (the review's A1).
func exp_pile_worth() -> float:
	var w := 0.0
	for e in expeditions:
		w += float(e["worth"])
	return w


## The Issue (the review's A1): every expedition out or waiting converts with the pile - its cargo's worth, a rolled
## return's tins and budget at the pile's `k`, its finds stamped at the Issue's prices as the stash's are.
func _exp_issue(k: float, hard: float) -> void:
	for e in expeditions:
		e["worth"] = float(e["worth"]) * k
		e["quota_worth"] = float(e.get("quota_worth", 0.0)) * k
		var res: Dictionary = e.get("res", {})
		for key in ["due", "total"]:
			if res.has(key):
				res[key] = float(res[key]) * k
		if res.has("cur") and res["cur"].has("tins"):
			res["cur"]["tins"] = float(res["cur"]["tins"]) * k
		for it in res.get("items", []):
			it["issue_k"] = hard


## A count and its cargo's name, grouped and singular at one (the UI review's A3: "1 fuses", "7972 scrap").
func cargo_words(kind: String, n: int) -> String:
	var noun: String = cargo_name(kind).to_lower()
	if n == 1:
		noun = {"fuses": "fuse", "cable drums": "cable drum", "meds": "med", "ledgers": "ledger", "notes": "note"}.get(noun, noun)
	return "%s %s" % [_group(n), noun]


static func _group(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("−" if n < 0 else "") + s + out


## The Quartermaster down: the expeditions open, and the Bunkhouse's line B with them.
func expeditions_open() -> bool:
	for b in Data.BOSSES:
		if str(b["name"]) == "The Quartermaster":
			return int(b["zone"]) < bosses_beaten.size() and bool(bosses_beaten[int(b["zone"])])
	return false


## A Pitch step that can't be built yet whatever the price: a data stub, or the Bunkhouse's line B before the
## Quartermaster (the step reads "After the Quartermaster").
## The Pitch's buildable steps (29 Oct): every pick bar the stubs and line B while the expeditions are shut - the
## headline's and the cards' "of N".
func yard_steps(key := "") -> int:
	var n := 0
	for b in Data.YARD:
		if key != "" and str(b["key"]) != key:
			continue
		for col in range(b["picks"].size()):
			for side in ["a", "b"]:
				n += 0 if yard_stub(str(b["key"]), col, side) else 1
	return n


func yard_stub(key: String, col: int, side: String) -> bool:
	var b := Data.yard_building(key)
	if b.is_empty() or col < 0 or col >= b["picks"].size():
		return false
	if bool(b["picks"][col][0 if side == "a" else 1].get("stub", false)):
		return true
	return key == "bunkhouse" and side == "b" and not expeditions_open()


## Expeditions out at once: one, Two at once's two, Three at once's three.
func exp_at_once() -> int:
	return 3 if yard_has("trip_three") else (2 if yard_has("trip_two") else 1)


## Hands an expedition takes: none before A hand along (the lead alone), one, Two along's two.
func exp_hands_max() -> int:
	return 2 if yard_has("trip_two_hands") else (1 if yard_has("trip_hand") else 0)


func roster_cap() -> int:
	return int(Data.HAND_ROSTER[1] if yard_has("trip_roster") else Data.HAND_ROSTER[0])


func quotas_open() -> bool:
	return yard_has("trip_roster")


func pool_open() -> bool:
	return expeditions_open() and yard_has("trip_hand")


func better_faces_open() -> bool:
	return pool_open() and yard_has("trip_two_hands")


func exp_place(p: int) -> Dictionary:
	return Data.EXP_PLACES[p] if p >= 0 and p < Data.EXP_PLACES.size() else {}


func exp_place_keys() -> Array:
	return Data.EXP_PLACES.map(func(pl): return str(pl["key"]))


## A far place's level: its own at the least, else the reach's with its offset - the far places climb with the camp.
func exp_level(p: int) -> int:
	var pl := exp_place(p)
	return maxi(int(pl.get("lv", 1)), reach + int(pl.get("reach", 0)))


## The place's fight as a signal laid on the host site: its level's depth there, its gang's zone, no codes.
func _exp_sig(p: int) -> Dictionary:
	var pl := exp_place(p)
	return {"id": Data.EXP_SIG_ID + p, "site": Data.EXP_HOST, "zone": int(pl["zone"]), "depth": maxi(2, exp_level(p) - lv_at(Data.EXP_HOST, 1) + 1), "words": [], "codes": [], "papers": [], "far": str(pl["key"])}


## The expeditions not yet put away: out, back or held.
func exp_busy() -> int:
	return expeditions.size()


func exp_by_id(id: int) -> Dictionary:
	for e in expeditions:
		if int(e["id"]) == id:
			return e
	return {}


## Whether a class's runner is away leading an expedition: their kit is the expedition's till it's put away.
func lead_out(name: String) -> bool:
	return expeditions.any(func(e): return str(e["lead"]) == name)


## The leads to pick from: the camp's other classes' runners, not away (the selected runner never goes).
func exp_leads() -> Array:
	var out: Array = []
	for c in Data.CLASSES:
		var nm: String = str(c["name"])
		if nm != cls and roster.has(nm) and not lead_out(nm):
			out.append(nm)
	return out


func hand_by_id(id: int) -> Dictionary:
	for h in hands:
		if int(h["id"]) == id:
			return h
	return {}


## A hand on an expedition not put away yet.
func hand_out(h: Dictionary) -> bool:
	return expeditions.any(func(e): return int(h["id"]) in e["hands"])


## Hurt (a bad roll): sits out for as long as that expedition took, played time.
func hand_hurt(h: Dictionary) -> bool:
	return float(h.get("hurt_until", -1.0)) > elapsed


func hand_free(h: Dictionary) -> bool:
	return not hand_out(h) and not hand_hurt(h)


## The crew's sum of a figure: the trades' and the affixes' (the far place's own for that place).
##   finds, bail, odds, crates, time, cargo (trades); odds, risk, cargo, finds, quality, time, hold, safe (affixes)
const _EXP_AFFIX_STAT := {"x_odds": "odds", "x_risk": "risk", "x_slot": "cargo", "x_finds": "finds", "x_quality": "quality", "x_time": "time", "x_hold": "hold", "x_place": "finds", "x_safe": "safe"}
func crew_fig(hand_ids: Array, stat: String, p := -1) -> float:
	var key: String = str(exp_place(p).get("key", ""))
	var v := 0.0
	for id in hand_ids:
		var h := hand_by_id(int(id))
		if h.is_empty():
			continue
		if str(Items.hand_trade(h).get("stat", "")) == stat:
			v += Items.hand_fig(h)
		for a in h.get("affixes", []):
			var st: String = str(a["stat"])
			if _EXP_AFFIX_STAT.get(st, "") != stat:
				continue
			if a.has("place") and str(a["place"]) != key:
				continue
			v += Items.hand_affix_value(h, a)
	return v


func exp_slots(hand_ids: Array) -> int:
	return mini(Data.EXP_SLOTS_MAX, Data.EXP_SLOTS + int(crew_fig(hand_ids, "cargo")))


## What can go as cargo, held now: notes (before the Issue), scrap, the salvage, the materials, meds.
func cargo_kinds() -> Array:
	var out: Array = []
	var all: Array = (["notes"] if not issued else []) + ["scrap"] + Data.SALVAGE + Data.MATERIAL_ORDER + ["meds"]
	for k in all:
		if cargo_held(str(k)) > 0:
			out.append(k)
	return out


func _exp_meds() -> Array:
	var meds: Array = stash.filter(func(it): return Items.is_medical(it))
	meds.sort_custom(func(a, b): return sell_price(a) < sell_price(b))     # the cheapest go first
	return meds


func cargo_held(kind: String) -> int:
	if kind == "meds":
		var n := 0
		for it in stash:
			if Items.is_medical(it):
				n += Items.stack_size(it)
		return n
	if kind == "notes" and issued:
		return 0
	return exchange_held(kind)


func cargo_name(kind: String) -> String:
	return "Meds" if kind == "meds" else exchange_name(kind)


## A cargo slot's worth: so many of the kind at the exchange's worth today; meds at what the Fence pays, cheapest first.
func cargo_slot_worth(kind: String, n: int) -> float:
	if n <= 0:
		return 0.0
	if kind == "meds":
		var w := 0.0
		var left := n
		for it in _exp_meds():
			if left <= 0:
				break
			var k: int = mini(left, Items.stack_size(it))
			w += float(sell_price(it)) / maxf(1.0, float(Items.stack_size(it))) * k
			left -= k
		return w * (1.0 - exchange_spread())
	return float(n) * cargo_unit(kind)


## A unit of cargo's worth, as a trade would value it (the fix round, 29 Oct: shipping is never a better exchange than
## the exchange): the exchange's give rate to tins, its spread and the day's drift against you in; scrap - bought, never
## sold - at what the find it came from would fetch at the Fence (its exchange worth over the Bench's scrap multipliers,
## less the spread), so scrapping and shipping can't beat selling: scrap ships at that worth times cargo_cut, so even the
## best return (EXP_RETURN x EXP_BONUS_CAP) brings a scrapped find home at no more than the Fence pays (28 Oct). Exchange
## kinds and meds ship at their worth: their round trip at about x1.2 is the designer's ("acceptable", 31 Oct).
func cargo_unit(kind: String) -> float:
	if kind == "scrap":
		var mult: float = (float(Data.FX["yard/strip_for_parts"]) if yard_has("strip_for_parts") else 1.0) * (float(Data.FX["node/salvage"]) if has_node("salvage") else 1.0)
		return exchange_worth("scrap") * (1.0 - exchange_spread()) / maxf(1.0, mult) * cargo_cut()
	return exchange_rate(kind, "tins")


## Scrap's shipped worth's cut: 1 over the best return (EXP_RETURN x EXP_BONUS_CAP) when that's over 1 (31 Oct).
func cargo_cut() -> float:
	return 1.0 / maxf(1.0, Data.EXP_RETURN * Data.EXP_BONUS_CAP)


func cargo_worth(cargo: Array) -> float:
	var w := 0.0
	for c in cargo:
		w += cargo_slot_worth(str(c["kind"]), int(c["n"]))
	return w


## A share of what's held of a kind, at least one while there's any.
func cargo_share(kind: String, share: float) -> int:
	var held: int = cargo_held(kind)
	return mini(held, maxi(1 if held > 0 else 0, int(ceil(held * share))))


## The lead's kit's worth: what the crew's strength is read against the cargo's.
func lead_strength(lead: String) -> float:
	var r := crew_runner(lead)
	var w := 0.0
	for sl in Data.SLOTS:
		var it = r.get("equipped", {}).get(sl, null)
		if it != null:
			w += Items.worth(it) * inflation()
	return maxf(w, tins_now(100.0))


## The far place's odds for a lead's kit: that class's runner put out for the read and back (as the crew's signal reads,
## signal_odds_class), the place laid on the host site. [odds, settled]; `now` the last read, running none.
func exp_odds(p: int, lead: String, now := false) -> Array:
	if exp_place(p).is_empty() or lead == cls or not roster.has(lead):
		return [0.0, false]
	var ck := "%s/%d/%d" % [lead, p, hash([exp_level(p), class_read_key(lead, false, true)])]
	if now or mission != null or not _sig.is_empty():
		return _exp_now.get(ck, [0.0, false])
	var read := func() -> Array:
		var sg := _exp_sig(p)
		_sig_on(sg)
		var i: int = int(sg["site"])
		if _exp_cache.has(ck):
			_surv_cache[i] = _exp_cache[ck]
		else:
			_surv_cache.erase(i)
		var o: float = survival(i)
		var done: bool = odds_settled(i)
		_exp_cache[ck] = _surv_cache[i]
		_sig_off()
		return [o, done]
	var out: Array = read_as_class(lead, read, false, true)     # at their own level (a lead stays benched), set off rested (a lead swapped out hurt read 0%)
	if _exp_cache.size() > 96:
		_exp_cache.clear()
	if _exp_now.size() > 96:
		_exp_now.clear()                     # trimmed as _exp_cache (T2)
	_exp_now[ck] = out
	return out


## The crew's odds: the lead's read, the scouts' and "+% odds" on top.
func exp_crew_odds(p: int, lead: String, hand_ids: Array, now := true) -> float:
	var o: float = float(exp_odds(p, lead, now)[0])
	return clampf(o + crew_fig(hand_ids, "odds", p) / 100.0, 0.0, 1.0)


## The risk: the cargo's worth over the lead's kit's (EXP_RISK_K), and the odds short of 100% (EXP_ODDS_W); the hands'
## "−% risk" and the Bunkhouse's rank off it.
func exp_risk(p: int, lead: String, hand_ids: Array, worth: float, odds: float) -> float:
	var r: float = Data.EXP_RISK_K * worth / lead_strength(lead) + (1.0 - odds) * Data.EXP_ODDS_W
	r -= crew_fig(hand_ids, "risk", p) / 100.0 + Data.EXP_RANK_RISK * yard_rank("bunkhouse")
	return clampf(r, Data.EXP_RISK_MIN, Data.EXP_RISK_MAX)


## The chance of a hold-up: rare, more at high risk; "−% hold-ups" off it; never with "Never held up in" the place.
func exp_hold_chance(p: int, hand_ids: Array, risk: float) -> float:
	if crew_fig(hand_ids, "safe", p) > 0.0:
		return 0.0
	return clampf((Data.EXP_HOLD + Data.EXP_HOLD_RISK * risk) * (1.0 - crew_fig(hand_ids, "hold", p) / 100.0), 0.0, 1.0)


## The time away, played: the place's, the drivers' and "−% time" off it, never under half.
func exp_time(p: int, hand_ids: Array) -> float:
	return float(exp_place(p).get("time", 0)) * maxf(Data.EXP_TIME_FLOOR, 1.0 - crew_fig(hand_ids, "time", p) / 100.0)


## A hand's wage an expedition (only a hand sent is paid): by tier and rarity, at today's prices, "−% wage" off it.
func hand_wage(h: Dictionary) -> int:
	var base: float = Data.HAND_WAGE * int(h.get("tier", 1)) * float(Data.RARITIES[clampi(int(h.get("rarity", 0)), 0, Data.RARITIES.size() - 1)]["value"])
	return int(round(_inf(base) * maxf(0.0, 1.0 - Items.hand_affix_sum(h, "x_wage") / 100.0)))     # at today's prices, before the Issue too (the fix round)


func crew_wages(hand_ids: Array) -> int:
	var w := 0
	for id in hand_ids:
		var h := hand_by_id(int(id))
		if not h.is_empty():
			w += hand_wage(h)
	return w


## The return's worth before the roll: the cargo's (EXP_RETURN), the porters' and "+% finds" on top.
func exp_return_worth(p: int, worth: float, hand_ids: Array) -> float:
	return maxf(0.0, worth) * Data.EXP_RETURN * exp_bonus(hand_ids, p)


## The hands' bonuses on the return, all told: the porters' and "+% finds", the crackers' crates (EXP_CRATE_SHARE of the
## cargo a crate) - never past EXP_BONUS_CAP (the fix round, 29 Oct: two porters tripled a shipment).
func exp_bonus(hand_ids: Array, p := -1) -> float:
	return minf(Data.EXP_BONUS_CAP, _exp_bonus_raw(hand_ids, p))


func _exp_bonus_raw(hand_ids: Array, p := -1) -> float:
	return 1.0 + crew_fig(hand_ids, "finds", p) / 100.0 + crew_fig(hand_ids, "crates", p) * Data.EXP_CRATE_SHARE


## The return's loot quality: grows with the cargo's worth (a doubling over EXP_QUALITY_UNIT a step), "+% loot quality" on top.
func exp_quality(worth: float, hand_ids: Array, p := -1) -> float:
	if worth <= 0.0:
		return 0.0
	return Data.EXP_QUALITY_K * log(1.0 + worth / (Data.EXP_QUALITY_UNIT * inflation())) / log(2.0) + crew_fig(hand_ids, "quality", p) / 100.0     # the unit at today's prices (the fix round)


## This week: EXP_WEEK_H hours of the world's played time (the fix round, 29 Oct: the exchange's day was a run home, a
## "week" 16 minutes), and the hours left in it.
func exp_week() -> int:
	return int(floor(elapsed / (Data.EXP_WEEK_H * 3600.0)))


func exp_week_left() -> float:
	return (exp_week() + 1) * Data.EXP_WEEK_H * 3600.0 - elapsed


## A place's quota this week: {kind, n, item} - what it wants (one of the cargo kinds the camp has met), how many, and
## its item's words; {} while the quotas are shut. Its own dice, the week's: the same all week.
func exp_quota(p: int) -> Dictionary:
	var pl := exp_place(p)
	if pl.is_empty() or not quotas_open():
		return {}
	var known: Array = quota_kinds_now()
	if known.is_empty():
		return {}
	var r := RandomNumberGenerator.new()
	r.seed = hash(["quota", str(pl["key"]), exp_week()])
	var kind: String = str(known[r.randi_range(0, known.size() - 1)])
	var unit: float = Data.EXP_MED_UNIT * inflation() if kind == "meds" else float(Data.EXCHANGE_BASE.get(kind, 1.0)) * inflation()
	var n: int = maxi(1, int(ceil(float(Data.EXP_QUOTA_WORTH[p]) * inflation() / maxf(unit, 0.01))))
	var named: String = _quota_unique(r) if str(pl["quota"]) == "named" else ""
	var out := {"kind": kind, "n": n, "item": _quota_item_words(p, named)}
	if named != "":
		out["unique"] = named
	return out


## The kinds a week's quotas are rolled from, frozen at the week's start (the fix round, 29 Oct: holding one copper moved
## five places' quotas): meds, the salvage and materials the camp has met or holds - never scrap, which the exchange
## sells at any time.
var quota_kinds := {}              # {week, kinds}
func quota_kinds_now() -> Array:
	if int(quota_kinds.get("week", -1)) != exp_week():
		var known: Array = ["meds"] + salvage_kinds() + materials_met()
		for k in Array(Data.SALVAGE) + Array(Data.MATERIAL_ORDER):
			if cargo_held(str(k)) > 0 and not known.has(k):
				known.append(k)
		quota_kinds = {"week": exp_week(), "kinds": known}
	return quota_kinds["kinds"]


func _quota_unique(r: RandomNumberGenerator) -> String:
	var pool: Array = Data.UNIQUES.filter(func(u): return not u.has("site") and not u.get("boss", false) and not u.get("mythic", false) and str(u["slot"]) in Data.SLOTS)
	return str(pool[r.randi_range(0, pool.size() - 1)]["name"]) if not pool.is_empty() else ""


func _quota_item_words(p: int, named: String) -> String:
	var q: String = str(exp_place(p)["quota"])
	if q == "named":
		return Words.EXPEDITIONS["q_named"] % Words.mid(named)
	if q == "set":
		return Words.EXPEDITIONS["q_issued"] if issued else Words.EXPEDITIONS["q_set"]
	if q == "mythic":
		return Words.EXPEDITIONS["q_mythic"] % int(round(Data.EXP_MYTHIC_CHANCE * 100.0))
	return str(Words.EXPEDITIONS.get("q_" + q, q))


## Whether a cargo meets a place's quota this week: enough of its kind in it, the quotas open, not met already.
func quota_met_by(p: int, cargo: Array) -> bool:
	var q := exp_quota(p)
	if q.is_empty() or int(quota_done.get(str(exp_place(p)["key"]), -1)) == exp_week():
		return false
	var n := 0
	for c in cargo:
		if str(c["kind"]) == str(q["kind"]):
			n += int(c["n"])
	return n >= int(q["n"])


## Why an expedition can't go, or "": shut, the slots full, the lead, the hands, the cargo, the odds unread, the wages.
func exp_send_block(p: int, lead: String, hand_ids: Array, cargo: Array) -> String:
	var E: Dictionary = Words.EXPEDITIONS
	if not expeditions_open():
		return E["shut_open"]
	if exp_place(p).is_empty():
		return E["shut_open"]
	if exp_busy() >= exp_at_once():
		return E["shut_at_once"] % exp_at_once()
	if lead != "" and lead == cls:
		return E["shut_selected"]                  # the selected runner never goes (Matt): a watched run always pays more
	if lead == "" or not roster.has(lead):
		return E["shut_lead"]
	if lead_out(lead):
		return E["shut_lead_out"] % lead
	if mission != null or not _sig.is_empty():
		return E["shut_run_out"]                   # the lead's XP is read at camp (30 Oct, S5: sent with a run out, it was 0)
	if hand_ids.size() > exp_hands_max():
		return E["shut_hands"] % [exp_hands_max(), "" if exp_hands_max() == 1 else "s"]
	for id in hand_ids:
		var h := hand_by_id(int(id))
		if h.is_empty() or not hand_free(h) or hand_ids.count(id) > 1:
			return E["shut_hand"] % (str(h.get("base", "A hand")))
	var any := false
	var seen_kinds: Array = []
	for c in cargo:
		if int(c["n"]) <= 0:
			continue
		if seen_kinds.has(str(c["kind"])) or int(c["n"]) > cargo_held(str(c["kind"])):
			return E["shut_cargo"]
		seen_kinds.append(str(c["kind"]))
		any = true
	if not any or cargo.size() > exp_slots(hand_ids):
		return E["shut_cargo"]
	if not bool(exp_odds(p, lead, true)[1]):
		return E["shut_reading"]
	if cash < crew_wages(hand_ids):
		return E["shut_wage"] % money_word()
	return ""


## Send them: the cargo leaves the camp, the hands sent are paid, the clock starts. `slot` London's pick.
func send_expedition(p: int, lead: String, hand_ids: Array, cargo: Array, slot := "") -> bool:
	if exp_send_block(p, lead, hand_ids, cargo) != "":
		return false
	var goods: Array = cargo.filter(func(c): return int(c["n"]) > 0).map(func(c): return {"kind": str(c["kind"]), "n": int(c["n"])})
	var worth: float = cargo_worth(goods)
	var odds: float = exp_crew_odds(p, lead, hand_ids)
	var risk: float = exp_risk(p, lead, hand_ids, worth, odds)
	var quota: bool = quota_met_by(p, goods)
	var qd: Dictionary = exp_quota(p) if quota else {}     # read before the cargo leaves (the review's A5: the last of a kind moved the week's dice)
	var quota_worth := 0.0
	for c in goods:
		if quota and str(c["kind"]) == str(qd["kind"]):
			quota_worth += cargo_slot_worth(str(c["kind"]), int(c["n"]))
	var xp_run: float = _exp_xp_run(p, lead)
	for c in goods:
		_cargo_take(str(c["kind"]), int(c["n"]))
		if str(c["kind"]) == "scrap":
			exp_scrap_out += int(c["n"])
	var wages: int = crew_wages(hand_ids)
	cash -= wages
	exp_seq += 1
	exp_sent += 1
	var e := {"id": exp_seq, "place": p, "lead": lead, "hands": hand_ids.map(func(x): return int(x)), "cargo": goods, "worth": worth, "odds": odds, "risk": risk,
		"hold": exp_hold_chance(p, hand_ids, risk), "quota": quota, "t0": elapsed, "dur": exp_time(p, hand_ids), "slot": slot if slot != "" else "Primary",
		"state": "out", "res": {}, "seen": false, "wages": wages, "lead_lv": crew_level(lead), "xp_run": xp_run, "quota_worth": quota_worth}
	if quota:
		quota_done[str(exp_place(p)["key"])] = exp_week()     # the week's quota is this shipment's, whatever the roll
		e["quota_item"] = str(qd.get("unique", ""))
	expeditions.append(e)
	exp_worth_out += worth
	exp_wages_paid += wages
	log_event(Words.EXPEDITIONS["sent"] % [lead, Words.mid(str(exp_place(p)["name"])), _cash_words(worth)])
	chron("expedition", {"place": str(exp_place(p)["key"]), "lead": lead, "hands": e["hands"].size(), "worth": int(worth), "odds": snappedf(odds, 0.01), "risk": snappedf(risk, 0.01), "quota": quota})
	return true


## The cargo out of the camp's holdings.
func _cargo_take(kind: String, n: int) -> void:
	if kind == "meds":
		var left := n
		for it in _exp_meds():
			if left <= 0:
				break
			var k: int = mini(left, Items.stack_size(it))
			if k >= Items.stack_size(it):
				stash.erase(it)
			else:
				Items.set_stack(it, Items.stack_size(it) - k)
			left -= k
		return
	_exchange_add(kind, -n)


## The world's seconds (advance): an expedition whose time is up comes back, or is held.
func _exp_tick() -> void:
	if _dry_on:
		return
	for e in expeditions:
		if str(e["state"]) == "out" and elapsed - float(e["t0"]) >= float(e["dur"]):
			_exp_resolve(e)


## Time's up: the risk's roll (a bad one loses 25-100%, a medic's share less), the hold-up's, the quota's bonus; back,
## the return rolled; held, it waits on the way out.
func _exp_resolve(e: Dictionary) -> void:
	var p: int = int(e["place"])
	var hs: Array = e["hands"]
	var bad: bool = rng.randf() < float(e["risk"])
	var loss := 0.0
	if bad:
		loss = rng.randf_range(Data.EXP_LOSS[0], Data.EXP_LOSS[1]) * (1.0 - minf(0.9, crew_fig(hs, "bail", p) / 100.0))
	var held: bool = rng.randf() < float(e["hold"])
	var bonus: float = rng.randf_range(Data.EXP_QUOTA_BONUS[0], Data.EXP_QUOTA_BONUS[1]) if bool(e.get("quota", false)) else 0.0
	e["res"] = {"bad": bad, "loss": loss, "bonus": bonus}
	e["res"]["due"] = _exp_total(e)                # what's coming back after the roll: the ransom reads it
	e["seen"] = false
	var pname: String = Words.mid(str(exp_place(p)["name"]))
	if held:
		e["state"] = "held"
		exp_held_n += 1
		log_event(Words.EXPEDITIONS["held_log"] % pname)
		chron("held_up", {"place": str(exp_place(p)["key"]), "risk": snappedf(float(e["risk"]), 0.01)})
		return
	_exp_home(e, loss)
	log_event(Words.EXPEDITIONS["back_log"] % [pname, _exp_got_words(e)])


## The crew home with the return (a fetch brings it whole): rolled now, put away with Take it; the hands' levels and
## hurts.
func _exp_home(e: Dictionary, loss: float, unhurt := false) -> void:
	var res: Dictionary = e["res"]
	res["loss"] = loss
	_exp_roll_return(e)
	e["state"] = "back"
	e["seen"] = false
	exp_back_n += 1
	var ups: Array = []
	var hurt: Array = []
	var medic: bool = e["hands"].any(func(id): return str(hand_by_id(int(id)).get("trade", "")) == "medic")
	for id in e["hands"]:
		var h := hand_by_id(int(id))
		if h.is_empty():
			continue
		var lv0: int = int(h.get("lv", 1))
		h["xp"] = int(h.get("xp", 0)) + 1
		@warning_ignore("integer_division")
		h["lv"] = mini(Data.HAND_LV_MAX, 1 + int(h["xp"]) / Data.HAND_LV_EVERY)
		ups.append([int(id), lv0, int(h["lv"])])
		if bool(res.get("bad", false)) and not medic and not unhurt:
			h["hurt_until"] = elapsed + float(e["dur"])     # hurt for one expedition (trips.md 3): as long as this one took
			hurt.append(int(id))
	res["ups"] = ups
	res["hurt"] = hurt
	var lead: String = str(e["lead"])
	if roster.has(lead):
		var got: float = float(e.get("xp_run", 0.0)) * repeat_xp_share()     # the lead's XP: a repeat run's share of a run there (the fix round, 29 Oct)
		_crew_gain_xp(lead, got)                 # its points, the cap and the paragon (30 Oct, S4)
		res["lead_xp"] = got


## A run's XP at the far place, as a watched run there would earn it (the place's fight laid on: its gang's XP a man,
## the pool) - the lead's share of it comes home with them.
## Read as the lead (30 Oct, S6): the XP's cut for a site under you is the lead's level, not the runner out's, as exp_odds
## reads; never with a run out (S5: exp_send_block shuts the send then, so no lead goes for 0).
func _exp_xp_run(p: int, lead: String) -> float:
	if not _sig.is_empty() or mission != null and not _repeat_going or not roster.has(lead):
		return 0.0
	var h := _read_as(lead)
	var sg := _exp_sig(p)
	_sig_on(sg)
	var t := effective(int(sg["site"]))
	_sig_off()
	_read_back(h)
	return float(t["xp"]) * float(t["pool"])


## The return's worth after the roll: the cargo's at EXP_RETURN, the hands' bonus (capped), less the loss; the quota's
## bonus on its own slot.
func _exp_total(e: Dictionary) -> float:
	var res: Dictionary = e.get("res", {})
	var keep: float = 1.0 - float(res.get("loss", 0.0))
	return (exp_return_worth(int(e["place"]), float(e["worth"]), e["hands"]) + float(e.get("quota_worth", 0.0)) * Data.EXP_RETURN * float(res.get("bonus", 0.0))) * keep


## The return: the place's kinds by share at the return's worth (the lead's class's kind takes EXP_CLASS_SHARE), less the
## roll's loss, the quota's bonus on top; the crackers' crates; the quota's item. Items up to EXP_ITEMS_MAX, the rest of
## their worth as scrap.
func _exp_roll_return(e: Dictionary) -> void:
	var p: int = int(e["place"])
	var pl := exp_place(p)
	var res: Dictionary = e["res"]
	var hs: Array = e["hands"]
	var total: float = _exp_total(e)
	var raw: float = _exp_bonus_raw(hs, p)
	var crates: float = total * crew_fig(hs, "crates", p) * Data.EXP_CRATE_SHARE / raw if raw > 0.0 else 0.0     # the crates' share of it, inside the cap
	total -= crates
	var q: float = exp_quality(float(e["worth"]), hs, p)
	var tier_v: int = best_tier_open()
	var shares: Array = []
	var ck: String = str(Data.EXP_CLASS_KIND.get(str(e["lead"]), ""))
	for kv in pl["pays"]:
		shares.append([str(kv[0]), float(kv[1]) * (1.0 - (Data.EXP_CLASS_SHARE if ck != "" else 0.0))])
	if ck != "":
		shares.append([ck, Data.EXP_CLASS_SHARE])
	var items: Array = []
	var cur := {}
	for sh in shares:
		var budget: float = total * float(sh[1])
		_exp_fill(str(sh[0]), budget, q, tier_v, str(e.get("slot", "Primary")), items, cur)
	if crates > 0.0:
		_exp_fill(str(pl["pays"][0][0]), crates, q + 0.25, tier_v, str(e.get("slot", "Primary")), items, cur)     # the crackers': the place's first kind, a better find
	total += crates
	var quota_it := {}
	if bool(e.get("quota", false)) and total > 0.0:
		quota_it = _exp_quota_item(e, tier_v)
		if not quota_it.is_empty():
			items.append(quota_it)
	res["items"] = items
	res["cur"] = cur
	res["total"] = total
	res["quota_item"] = Items.full_name(quota_it) if not quota_it.is_empty() else ""
	res["quota_id"] = int(quota_it["id"]) if not quota_it.is_empty() else -1
	exp_return_in += total


## A share of the return, `budget` its worth: items rolled until it's spent (the last at the chance of what's left),
## currencies counted out. Into `items` and `cur`.
func _exp_fill(kind: String, budget: float, q: float, tier_v: int, slot: String, items: Array, cur: Dictionary) -> void:
	if budget <= 0.0:
		return
	match kind:
		"tins":
			cur["tins"] = float(cur.get("tins", 0.0)) + budget
			return
		"tokens":
			var each_t: float = maxf(1.0, float(gamble_price(str(Data.GAMBLE_KINDS[0]["kind"]))))
			var n: int = int(floor(budget / each_t)) + (1 if rng.randf() < fmod(budget, each_t) / each_t else 0)
			if n > 0:
				cur["tokens"] = int(cur.get("tokens", 0)) + n
			return
		"army", "fuses", "scrap":
			var cn: int = _exp_count(budget / maxf(0.01, exchange_worth(kind)))
			if cn > 0:
				cur[kind] = int(cur.get(kind, 0)) + cn
			return
		"materials":
			var mats: Array = materials_met().filter(func(k): return k != "fuses")
			if mats.is_empty():
				mats = ["copper_wire"]
			var each: float = budget / mats.size()
			for mk in mats:
				var mn: int = _exp_count(each / maxf(0.01, exchange_worth(str(mk))))
				if mn > 0:
					cur[mk] = int(cur.get(mk, 0)) + mn
			return
	var left := budget
	var tries := 0
	while left > 0.0 and tries < 40:
		tries += 1
		if items.size() >= Data.EXP_ITEMS_MAX:
			cur["scrap"] = int(cur.get("scrap", 0)) + _exp_count(left / maxf(0.01, exchange_worth("scrap")))     # the rest as scrap
			return
		var it := _exp_item(kind, q, tier_v, slot)
		if it.is_empty():
			cur["tins"] = float(cur.get("tins", 0.0)) + left
			return
		var w: float = maxf(Data.EXP_ITEM_FLOOR * inflation(), float(sell_price(it)) * maxf(1.0, float(Items.stack_size(it))))
		if w > left and rng.randf() >= left / w:
			return                                  # the last at the chance of what's left
		items.append(it)
		left -= w


## A count from a figure: its whole part, and one more at the chance of what's left (the review's B6: Birmingham's shares
## rounded to nothing).
func _exp_count(x: float) -> int:
	var n: int = int(floor(maxf(0.0, x)))
	return n + (1 if rng.randf() < x - n else 0)


## One find of a return's kind, at the camp's best tier with the return's quality.
func _exp_item(kind: String, q: float, tier_v: int, slot: String) -> Dictionary:
	match kind:
		"meds":
			return Items.roll(Data.MEDICAL, tier_v, rng, q)
		"supplies":
			return _plain(Data.SUPPLIES, str(Data.BASES[Data.SUPPLIES][0]["name"]))
		"parts", "socketables":
			for k in range(20):
				var a := Items.roll(Data.ATTACHMENT, tier_v, rng, q)
				if (str(a.get("mount", "")) == "socket") == (kind == "socketables"):
					return a
			return {}
		"charms":
			return Items.roll("Charm", tier_v, rng, q)
		"papers":
			return Items.roll(Data.PAPER, tier_v, rng, q)
		"socketed":
			var sl: String = str(Data.SOCKET_SLOTS[rng.randi_range(0, Data.SOCKET_SLOTS.size() - 1)])
			var g := Items.roll(sl, tier_v, rng, q, true)
			while Items.add_socket(g):
				pass
			return g
		"uniques":
			return _exp_unique(slot, tier_v, "")
	return {}


## A unique of a slot (London's pick) at a tier, or the one named; {} when none fits.
func _exp_unique(slot: String, tier_v: int, named: String) -> Dictionary:
	var plain: Array = Data.UNIQUES.filter(func(u): return not u.has("site") and not u.get("boss", false) and not u.get("mythic", false) and str(u["slot"]) in Data.SLOTS)
	var pool: Array = plain.filter(func(u): return str(u["name"]) == named) if named != "" else plain.filter(func(u): return str(u["slot"]) == slot and Items.unique_fits(u, tier_v))
	if pool.is_empty() and named == "":
		pool = plain.filter(func(u): return str(u["slot"]) == slot)
	if pool.is_empty():
		return {}
	return Items.roll_unique(pool[rng.randi_range(0, pool.size() - 1)], rng, -1, tier_v)


## The quota's item: Swansea's mythic chance, Salisbury's set (an issued piece after the Issue), Liverpool's socketed
## unique, London's named one; Bristol's is the gamble rerolled and Birmingham's a rebuild at half (no item).
func _exp_quota_item(e: Dictionary, tier_v: int) -> Dictionary:
	match str(exp_place(int(e["place"]))["quota"]):
		"mythic":
			if mythics_on and rng.randf() < Data.EXP_MYTHIC_CHANCE:
				var u := mythic_pick()
				if not u.is_empty():
					return Items.roll_unique(u, rng, -1, tier_v)
			return {}
		"gamble":
			e["res"]["gamble"] = true                  # the Fence's gamble restocked on Take it (the review's C7: not under a plan)
			return {}
		"rebuild":
			e["res"]["halves"] = 1
			return {}
		"set":
			if issued:
				var sl: String = str(Data.ISSUED[rng.randi_range(0, Data.ISSUED.size() - 1)]["slot"])
				return issued_piece(sl, -1, true)
			var st: Dictionary = Data.SETS[rng.randi_range(0, Data.SETS.size() - 1)]
			var pc: Dictionary = st["pieces"][rng.randi_range(0, st["pieces"].size() - 1)]
			return Items.roll_set_piece(str(st["name"]), pc, rng, -1, tier_v)
		"socketed":
			var sl2: String = str(Data.SOCKET_SLOTS[rng.randi_range(0, Data.SOCKET_SLOTS.size() - 1)])
			var u2 := _exp_unique(sl2, tier_v, "")
			if not u2.is_empty():
				while Items.add_socket(u2):
					pass
			return u2
		"named":
			return _exp_unique("", tier_v, str(e.get("quota_item", "")))
	return {}


## What came back, in a line: the kinds and counts.
func _exp_got_words(e: Dictionary) -> String:
	var res: Dictionary = e.get("res", {})
	var parts: Array = []
	var n: int = res.get("items", []).size()
	if n > 0:
		parts.append("%d find%s" % [n, "" if n == 1 else "s"])
	for k in res.get("cur", {}):
		var v = res["cur"][k]
		if str(k) == "tins":
			parts.append(_cash_words(float(v)))
		elif str(k) == "tokens":
			parts.append(Words.EXPEDITIONS["tokens"] % [int(v), "" if int(v) == 1 else "s"])
		else:
			parts.append(cargo_words(str(k), int(v)))
	return ", ".join(parts) if not parts.is_empty() else Words.EXPEDITIONS["rep_nothing"]


## Take it: the return into the camp - the finds to the stash (what has no room sold at the gate), the rest counted in;
## the expedition put away, its lead and hands free.
func exp_take(id: int) -> bool:
	var e := exp_by_id(id)
	if e.is_empty() or str(e["state"]) != "back":
		return false
	var res: Dictionary = e["res"]
	var sold := 0
	var sold_tins := 0.0
	for it in res.get("items", []):
		if is_pile_paper(it):
			papers.append(it)
		elif stash_put(it):
			_mag_with(it)
		else:
			if it.get("mythic", false) or int(it["id"]) == int(res.get("quota_id", -1)):
				stash.append(it)                       # a mythic or the quota's item comes home whatever the room, as a mythic does
			else:
				var got := float(sell_price(it))
				_earn(got)                             # income, as a sale is (the fix round: the balance's cash in)
				sold += 1
				sold_tins += got
	if sold > 0:
		log_event(Words.EXPEDITIONS["no_room"] % [sold, _cash_words(sold_tins)])
	for k in res.get("cur", {}):
		var v = res["cur"][k]
		match str(k):
			"tins":
				_earn(float(v))                        # income (the fix round)
			"tokens":
				gamble_tokens += int(v)
			_:
				_exchange_add(str(k), int(v))
	rebuild_halves += int(res.get("halves", 0))
	if bool(res.get("gamble", false)):
		_restock_gamble()
	expeditions.erase(e)
	chron("expedition_home", {"place": str(exp_place(int(e["place"]))["key"]), "worth": int(e["worth"]), "total": int(res.get("total", 0.0)), "bad": bool(res.get("bad", false)), "items": res.get("items", []).size()})
	return true


## The report seen and put by: Later.
func exp_later(id: int) -> void:
	var e := exp_by_id(id)
	if not e.is_empty():
		e["seen"] = true


## The first expedition back or held whose report hasn't been seen, {} for none.
func exp_report_due() -> Dictionary:
	for e in expeditions:
		if str(e["state"]) in ["back", "held"] and not bool(e.get("seen", false)) and not exp_fetching(int(e["id"])):
			return e
	return {}


## A hold-up's ransom: half of what's coming back after the roll (the fix round, 29 Oct: half the cargo could be dearer
## than the return), never under EXP_RANSOM_MIN at today's prices.
func exp_ransom(id: int) -> int:
	var e := exp_by_id(id)
	if e.is_empty():
		return -1
	var due: float = float(e.get("res", {}).get("due", _exp_total(e)))
	return int(round(maxf(Data.EXP_RANSOM_MIN * inflation(), due * Data.EXP_RANSOM)))


func exp_pay(id: int) -> bool:
	var e := exp_by_id(id)
	if e.is_empty() or str(e["state"]) != "held" or exp_fetching(id) or cash < exp_ransom(id):
		return false
	var ransom: int = exp_ransom(id)
	cash -= ransom
	_exp_home(e, float(e["res"].get("loss", 0.0)))
	log_event(Words.EXPEDITIONS["paid"] % [_cash_words(ransom), Words.mid(str(exp_place(int(e["place"]))["name"]))])
	chron("ransom", {"place": str(exp_place(int(e["place"]))["key"]), "paid": ransom})
	return true


## Walk away: the cargo and the hands sent leave the camp (Matt's call); the lead comes home empty-handed.
func exp_walk(id: int) -> bool:
	var e := exp_by_id(id)
	if e.is_empty() or str(e["state"]) != "held" or exp_fetching(id):
		return false
	var gone: Array = []
	for hid in e["hands"]:
		var h := hand_by_id(int(hid))
		if not h.is_empty():
			gone.append(str(h["base"]))
			hands.erase(h)
	var pname: String = Words.mid(str(exp_place(int(e["place"]))["name"]))
	log_event(Words.EXPEDITIONS["walked"] % [pname, ", ".join(gone)] if not gone.is_empty() else Words.EXPEDITIONS["walked_none"] % pname)
	expeditions.erase(e)
	chron("walked_away", {"place": str(exp_place(int(e["place"]))["key"]), "hands": gone.size()})
	return true


## The site a hold-up is fetched from: the place's own, a campaign site with a head and fight art.
func exp_hold_site(id: int) -> int:
	var e := exp_by_id(id)
	return int(exp_place(int(e.get("place", -1))).get("hold", -1)) if not e.is_empty() else -1


func exp_fetching(id: int) -> bool:
	return mission != null and int(mission.get("exp_fetch", -1)) == id


func exp_fetch_block(id: int) -> String:
	var e := exp_by_id(id)
	if e.is_empty() or str(e["state"]) != "held":
		return Words.EXPEDITIONS["shut_open"]
	if exp_fetching(id):
		return Words.EXPEDITIONS["fetch_out"] % Words.mid(str(Data.TIERS[exp_hold_site(id)]["name"]))
	if mission != null or away():
		return Words.EXPEDITIONS["shut_out"]
	var i: int = exp_hold_site(id)
	if i < 0 or not can_deploy_to(i) or boss_of(i).is_empty():
		return Words.REPEAT["shut_site"]
	if candidates.size() == 2:
		return Words.REPEAT["shut_trait"]
	return ""


## Go after them: the selected runner to the hold site, its head the holder (free), a watched run. Its head down brings
## the party home with the return as rolled, the hands unhurt: _exp_fetched from the run's end.
func exp_fetch(id: int) -> bool:
	if exp_fetch_block(id) != "":
		return false
	var i: int = exp_hold_site(id)
	var was: bool = bool(boss_armed.get(i, false))
	_exp_fetch = id
	boss_armed[i] = true
	_surv_cache.erase(i)
	deploy(i)
	_exp_fetch = -1
	if mission == null:
		boss_armed[i] = was
		return false
	mission["exp_fetch"] = id
	return true


## A fetch's run home (_extract): the holder down, the party home with the return as rolled and the hands unhurt; else
## still held.
func _exp_fetched(m: Dictionary) -> void:
	var e := exp_by_id(int(m.get("exp_fetch", -1)))
	if e.is_empty() or str(e["state"]) != "held":
		return
	var pname: String = Words.mid(str(exp_place(int(e["place"]))["name"]))
	if m.has("boss") and not bool(m["boss"].get("alive", true)):
		_exp_home(e, float(e["res"].get("loss", 0.0)), true)     # the return as rolled, no refund; the hands brought home unhurt (the fix round)
		e["res"]["fetched"] = true
		log_event(Words.EXPEDITIONS["fetched"] % pname)
		chron("fetched", {"place": str(exp_place(int(e["place"]))["key"])})
	else:
		e["seen"] = false
		log_event(Words.EXPEDITIONS["fetch_failed"] % pname)


# ---- the hands: the pool, the roster

## Rolled at the camp's best tier (two under it to it), the gear's rarity table; Better faces: the top tier, no commons
## and the quality doubled.
func _roll_hand(better: bool) -> Dictionary:
	var top: int = best_tier_open()
	var t: int = top if better else rng.randi_range(maxi(1, top - 2), top)
	return Items.roll_hand(t, rng, (1.0 if better else 0.0), better, "", exp_place_keys())


## The pool of six: rolled the first time it's opened, then by New faces and Better faces.
func hand_pool_now() -> Array:
	if pool_open() and hand_pool.is_empty() and not bool(seen.get("hand_pool_rolled", false)):
		seen["hand_pool_rolled"] = true
		_fill_pool(false)
	return hand_pool


func _fill_pool(better: bool) -> void:
	hand_pool = []
	for k in range(Data.HAND_POOL):
		hand_pool.append(_roll_hand(better))


func reroll_cost(better: bool) -> int:
	return _round_price(_inf(float(Data.HAND_REROLL[1 if better else 0])))     # at today's prices (the fix round)


func reroll_block(better: bool) -> String:
	if not pool_open():
		return Words.EXPEDITIONS["hands_shut"]
	if better and not better_faces_open():
		return Words.EXPEDITIONS["better_shut"]
	if cash < reroll_cost(better):
		return Words.EXPEDITIONS["short_cash"] % money_word()
	return ""


## New faces (tins) and Better faces (more tins): the pool of six rolled again.
func reroll_pool(better: bool) -> bool:
	if reroll_block(better) != "":
		return false
	cash -= reroll_cost(better)
	_fill_pool(better)
	chron("new_faces", {"better": better, "cost": reroll_cost(better)})
	return true


func hire_block(id: int) -> String:
	if not pool_open():
		return Words.EXPEDITIONS["hands_shut"]
	if not hand_pool.any(func(h): return int(h["id"]) == id):
		return Words.EXPEDITIONS["pick_hand"]
	if hands.size() >= roster_cap():
		return Words.EXPEDITIONS["roster_full"]
	return ""


## Hire: off the pool onto the roster, free (a wage only for a hand sent).
func hire_hand(id: int) -> bool:
	if hire_block(id) != "":
		return false
	for h in hand_pool:
		if int(h["id"]) == id:
			hand_pool.erase(h)
			hands.append(h)
			log_event(Words.EXPEDITIONS["hired"] % [str(h["base"]), Items.rarity_name(h)])
			return true
	return false


## Let go: off the roster for good, freeing a place. Never one away.
func let_go(id: int) -> bool:
	var h := hand_by_id(id)
	if h.is_empty() or hand_out(h):
		return false
	hands.erase(h)
	log_event(Words.EXPEDITIONS["let_go_log"] % str(h["base"]))
	return true


# ---- the save

func exp_state() -> Dictionary:
	return {"expeditions": expeditions, "hands": hands, "pool": hand_pool, "seq": exp_seq, "sent": exp_sent, "quota_done": quota_done,
		"tokens": gamble_tokens, "halves": rebuild_halves, "quota_kinds": quota_kinds, "back_n": exp_back_n, "held_n": exp_held_n,
		"worth_out": exp_worth_out, "return_in": exp_return_in, "wages": exp_wages_paid, "scrap_out": exp_scrap_out}


func exp_load(d: Dictionary) -> void:
	expeditions = d.get("expeditions", [])
	hands = d.get("hands", [])
	hand_pool = d.get("pool", [])
	exp_seq = int(d.get("seq", 0))
	exp_sent = int(d.get("sent", 0))
	quota_done = d.get("quota_done", {})
	gamble_tokens = int(d.get("tokens", 0))
	rebuild_halves = int(d.get("halves", 0))
	quota_kinds = d.get("quota_kinds", {})
	if quota_kinds.has("week"):
		quota_kinds["week"] = int(quota_kinds["week"])
	exp_back_n = int(d.get("back_n", 0))
	exp_held_n = int(d.get("held_n", 0))
	exp_worth_out = float(d.get("worth_out", 0.0))
	exp_return_in = float(d.get("return_in", 0.0))
	exp_wages_paid = int(d.get("wages", 0))
	exp_scrap_out = int(d.get("scrap_out", 0))
	_exp_cache = {}
	_exp_now = {}
	var top := 0
	for h in hands + hand_pool:
		for k in ["id", "rarity", "tier", "ilvl", "lv", "xp", "look", "value"]:
			if h.has(k):
				h[k] = int(h[k])
		for a in h.get("affixes", []):
			a["value"] = int(a["value"])
			a["tier"] = int(a.get("tier", 1))
		top = maxi(top, int(h["id"]))
	for e in expeditions:
		for k in ["id", "place"]:
			e[k] = int(e[k])
		e["hands"] = Array(e.get("hands", [])).map(func(x): return int(x))
		for c in e.get("cargo", []):
			c["n"] = int(c["n"])
		for it in e.get("res", {}).get("items", []):
			for k in ["id", "rarity", "tier", "value", "rounds", "count", "ilvl"]:
				if it.has(k):
					it[k] = int(it[k])     # value and rounds too, as the stash's load (the review's C3)
			top = maxi(top, int(it["id"]))
	for k in quota_done.keys():
		quota_done[k] = int(quota_done[k])
	Items._next_id = maxi(Items._next_id, top + 1)


# ------------------------------------------------------------------ a night on the air (BUILD50 N, act_two.md §3)

## Signals chained (Matt, 4 Nov: "being done in 30secs then having to repeat the whole process to go again - think we
## need to be able to chain them together"): a night starts on a held signal; each link is a signal's fight as a run is;
## between them the break, where the runner stands as they are - HP, meds, magazines, the pack, the wounds - no rest, no
## gate top-up, no Clinic. The next link is the next held signal, then one rolled at the reach + 1. Every fifth link
## brings something special. It ends on Get out at a break, a death, the night's clock out or a full pack.
## The night's run is one run that goes on: the pack, the tins, the notes and the salvage carried from link to link in the
## run itself, so whatever ends it is a run's end - home through _extract, or lost through _kia. Its XP is held in the run
## (night_xp) and comes home with it; a death loses it with the rest of the haul.
var night_chain := {}                  # the night in progress: {link, done, results, fight_s, kills, next, next_id, cls, start_link_lv}
var night_rules: Array = []      # the tuning rules: [{"kind": "want"|"never"|"wager", "code": name, "cond": wager cond id, "on": bool}]
var night_floor := Data.NIGHT_FLOOR     # "Auto: keep going" while the odds stay at or over this
var night_auto := false          # the tick on the break
var _night_going := false        # a link after the first setting off: no gate top-up, no Yard's setting-off


func night_on() -> bool:
	return not night_chain.is_empty()


## At a break: a link won or lost and the next not yet set off; the world waits on the player (no rest).
func night_break() -> bool:
	return not night_chain.is_empty() and mission != null and bool(mission.get("night_break", false))


## The link under way (or the one just done, at a break), from 1.
func night_link() -> int:
	return int(night_chain.get("link", 0))


## A link's special: every NIGHT_FIFTH link in turn a head away from home, a stash, a fat drop; "" for the rest.
static func night_special(link: int) -> String:
	if link <= 0 or link % Data.NIGHT_FIFTH != 0:
		return ""
	return str(Data.NIGHT_FIFTHS[(floori(link / float(Data.NIGHT_FIFTH)) - 1) % Data.NIGHT_FIFTHS.size()])


## The next fifth link from `link` on (the chain strip's dashed one).
static func night_next_fifth(link: int) -> int:
	return (floori(link / float(Data.NIGHT_FIFTH)) + 1) * Data.NIGHT_FIFTH


## A link's XP: 5% more a link past the first (NIGHT_XP_STEP).
static func night_xp_mult(link: int) -> float:
	return 1.0 + Data.NIGHT_XP_STEP * maxi(0, link - 1)


## The night's fight time left on its clock, in seconds.
func night_clock_left() -> float:
	var used: float = float(night_chain.get("fight_s", 0.0))
	if mission != null and mission.has("night") and not bool(mission.get("night_break", false)):
		used += float(mission.get("elapsed", 0.0)) - float(mission.get("paused_s", 0.0))
	return maxf(0.0, Data.NIGHT_CLOCK - used)


## Why a night can't start on held signal `k` now ("" when it can).
func night_block(k: int) -> String:
	var sg := signal_at(k)
	if sg.is_empty():
		return "no such signal"
	if sg.has("order"):
		return Words.NIGHT["order_alone"]
	if not can_deploy() or not _sig.is_empty():
		return busy_words() if busy_words() != "" else "The runner is out"
	if candidates.size() == 2:
		return "Pick a trait first"
	return ""


## Start a night on held signal `k`: its run is the first link, the one out the night's runner.
func start_night(k: int) -> bool:
	if night_block(k) != "":
		return false
	var sg := signal_at(k)
	night_chain = {"link": 1, "done": 0, "results": [], "fight_s": 0.0, "kills": 0, "next": {}, "next_id": -1, "cls": cls}
	if night_special(1) == "head":
		sg["head"] = true
	if not deploy_signal(k):
		night_chain = {}
		return false
	_night_mark(mission)
	log_event(Words.NIGHT["log_start"] % [Words.mid(signal_place(sg)), signal_level(sg)])
	chron("night", {"what": "start", "id": int(sg["id"]), "level": signal_level(sg)})
	return true


## A link's run marked as the night's: its number, its special, the XP it holds.
func _night_mark(m: Dictionary) -> void:
	var link: int = night_link()
	m["night"] = link
	m["night_special"] = night_special(link)
	m["night_xp"] = float(m.get("night_xp", 0.0))


## A link's end, from _extract (true: held at the break, or the night's sent home from here; the caller's done). Out of
## time ends the night as a run out of time (the clock's taken the pack already): false, and _extract goes on.
func _night_link_end(m: Dictionary) -> bool:
	if bool(m.get("night_home", false)) or bool(m.get("night_break", false)):
		return false
	if bool(m.get("timed_out", false)):
		m["night_home"] = true
		m["night_end"] = "time"
		return false
	_event_end(m)                              # as _extract: the dogs off the record, his run-only goods back
	_bailiff_keeps_deeds(m)
	_floor_mythics_in(m)
	if m.get("ghost_pending", false) and (pack_used(m) >= capacity() or (crates_done(m) and not m.get("crates_none", false))):
		m["ghost_pending"] = false
		_clear(m, m["t"])                      # Ghost: a full pack is the clear, as _extract reads it
	m["left"] = int(m["left"]) + m.get("floor", []).size()     # the floor stays with its site
	m["floor"] = []
	if float(m.get("wager_notes", 1.0)) != 1.0:
		var held_n: int = int(m.get("notes_link0", 0))     # the earlier links' notes: the wager's not on them (fix 50)
		m["notes"] = held_n + int(round((int(m.get("notes", 0)) - held_n) * float(m["wager_notes"])))     # Kev's notes wager paid on its own link's notes
		m["wager_notes"] = 1.0
	var lv: int = signal_level(_sig) if not _sig.is_empty() else 0
	var won: bool = bool(m["cleared"]) and not m.get("ghost_pending", false) and not (m.has("boss") and bool(m["boss"].get("alive", false)))
	_signal_done(m)                            # the reach counted link by link, the papers home, Kev's story
	m.erase("signal")
	night_chain["done"] = int(night_chain.get("done", 0)) + 1
	night_chain["results"] = Array(night_chain.get("results", [])) + [won]
	night_chain["fight_s"] = float(night_chain.get("fight_s", 0.0)) + float(m["elapsed"]) - float(m.get("paused_s", 0.0))
	night_chain["kills"] = int(night_chain.get("kills", 0)) + int(m["kills"])
	m["night_break"] = true
	log_event((Words.NIGHT["log_won"] if won else Words.NIGHT["log_lost"]) % [night_link(), Words.mid(str(m["t"]["name"]))])
	chron("night", {"what": "link", "link": night_link(), "level": lv, "won": won, "special": str(m.get("night_special", "")), "hp": int(hp), "pack": pack_used(m)})
	if night_clock_left() <= 0.0:
		_night_home(m, "clock")
	elif pack_used(m) >= capacity():
		_night_home(m, "full")
	else:
		_night_prepare_next()
	return true


## A held signal given the fifth's head at a break put back as it was, the night ending there (fix 50).
func _night_head_back() -> void:
	var hb: Array = night_chain.get("head_back", [])
	night_chain.erase("head_back")
	if hb.size() < 2:
		return
	for sg in signals:
		if int(sg["id"]) == int(hb[0]):
			sg["head"] = bool(hb[1])


## The night home with its haul: at a break, the run's end as a run home.
func _night_home(m: Dictionary, why: String) -> void:
	_night_head_back()
	m["night_home"] = true
	m["night_end"] = why
	log_event(Words.NIGHT["end_" + why])
	_extract()


## Get out with the haul (the break's button).
func night_get_out() -> bool:
	if not night_break():
		return false
	_night_home(mission, "out")
	return true


## The night's XP home, its record, the night done: from _extract once the night's run comes home.
func _night_home_done(m: Dictionary) -> void:
	if not m.has("night") or night_chain.is_empty():
		return
	var g: float = float(m.get("night_xp", 0.0))
	m["xp"] = g                                # the card's XP: the night's, each link's step in it
	var before := level()
	_gain_xp(g)
	_earn_points(before)
	chron("night", {"what": "home", "end": str(m.get("night_end", "out")), "links": int(night_chain.get("done", 0)), "won": Array(night_chain.get("results", [])).count(true), "xp": int(g), "tins": int(m["cash"]), "pack": pack_used(m)})
	night_chain = {}


## A death on a link: the night's haul goes with the run (_kia loses the pack, the tins and notes were never earned,
## the XP was held in the run).
func _night_dead(m: Dictionary) -> void:
	if not m.has("night") or night_chain.is_empty():
		return
	_night_head_back()
	log_event(Words.NIGHT["end_dead"] % int(m.get("night_xp", 0.0)))
	chron("night", {"what": "dead", "link": night_link(), "links": int(night_chain.get("done", 0))})
	night_chain = {}


## The next link at a break: the next held signal, else one rolled at the reach + 1; a fifth's head on it; Kev's wagers
## the tuning rules accept taken.
func _night_prepare_next() -> void:
	var link: int = night_link() + 1
	night_chain["next"] = {}
	night_chain["next_id"] = -1
	if not signals.is_empty():
		night_chain["next_id"] = int(signals[0]["id"])
	else:
		night_chain["next"] = _night_roll()
	var sg: Dictionary = night_next_sig()
	if night_special(link) == "head":
		if int(night_chain["next_id"]) >= 0 and not night_chain.has("head_back"):
			night_chain["head_back"] = [int(sg["id"]), bool(sg.get("head", false))]     # a held signal's head as it was, put back if the night ends at this break (fix 50)
		sg["head"] = true                      # a head away from home: the crew's, at the link's level, his drops
	var key: String = "sig:%d" % int(sg["id"])
	var offer: Array = wager_offer(key)
	for k in range(offer.size()):
		if _night_rule_takes(offer[k]) and not wager_taken(key, k):
			take_wager(key, k)


## The next link's signal: the held one by its id, or the rolled one. {} when none.
func night_next_sig() -> Dictionary:
	if night_chain.is_empty():
		return {}
	var id: int = int(night_chain.get("next_id", -1))
	if id >= 0:
		for sg in signals:
			if int(sg["id"]) == id:
				return sg
		return {}
	return night_chain.get("next", {})


## The crew whose area's materials the town's next step still wants (act_two.md §3: "at a site the town's next step needs
## materials from where one fits"); -1 when none does.
func _night_want_zone() -> int:
	for key in Words.U49_TOWN_ROAD:
		if rebuild_rank(str(key)) > 0:
			continue
		var cost: Dictionary = rebuild_cost(str(key))
		for mk in cost:
			if Data.MATERIALS.has(mk) and held_of(str(mk)) < int(cost[mk]):
				return int(Data.MATERIALS[mk]["area"])
		return -1
	return -1


## A link rolled at the reach + 1: an open site, the crew the town wants materials from where one fits, its codes by the
## tuning rules.
func _night_roll() -> Dictionary:
	var open: Array = range(Data.TIERS.size()).filter(func(i): return tier_open(int(i)))
	var site: int = int(open[rng.randi_range(0, open.size() - 1)]) if not open.is_empty() else rng.randi_range(0, Data.TIERS.size() - 1)
	var zone: int = _night_want_zone()
	if zone < 1 or zone >= Data.ZONES.size():
		zone = rng.randi_range(0, Data.ZONES.size() - 1)
	signal_seq += 1
	var sg := {"id": signal_seq, "site": site, "zone": zone, "depth": depth_for_level(site, maxi(Data.REACH_START, reach + 1)), "codes": [], "papers": [],
		"head": false, "convoy": rng.randf() < Data.SIGNAL_CONVOY_ODDS, "line": rng.randi_range(0, Words.SIGNAL_LINES.size() - 1), "grade": 3, "rolled": true}
	_sig_on(sg)
	sg["words"] = _night_codes(site, max_words(site))
	_sig_off()
	signal_focus_roll(sg)                  # what it drops, as a decrypted signal's (merge 50: T's focus on N's rolled link)
	return sg


## The codes a rolled link carries, `n` of them by the tuning rules: each code decided by the first rule naming it
## (checked top down, as the loot rules); the wanted ones on first, in the rules' order, where known and deep enough;
## the rest rolled, never one refused.
func _night_codes(i: int, n: int) -> Array:
	var decided := {}
	for r in night_rules:
		if bool(r.get("on", true)) and str(r.get("kind", "")) in ["want", "never"] and not decided.has(str(r.get("code", ""))):
			decided[str(r["code"])] = str(r["kind"])
	var out: Array = []
	for name in decided:
		if out.size() >= n:
			break
		if decided[name] == "want" and knows_word(str(name)) and int(depth[i]) >= int(Data.word_of(str(name)).get("depth", 0)):
			out.append({"w": str(name), "t": _roll_tier(i)})
	var never: Array = decided.keys().filter(func(nm): return decided[nm] == "never")
	while out.size() < n:
		var wd := _roll_word(i, out.map(func(x): return str(x["w"])) + never)
		if wd.is_empty():
			break
		out.append(wd)
	return out


## Whether the tuning rules take Kev's wager `w` at a break: the first rule naming its cost decides.
func _night_rule_takes(w: Dictionary) -> bool:
	for r in night_rules:
		if bool(r.get("on", true)) and str(r.get("kind", "")) == "wager" and str(r.get("cond", "")) == str(w["cond"]):
			return true
	return false


## A tuning rule added (a code wanted by default, the first code known), moved up, changed or taken off.
func night_rule_add(kind := "want", code := "", cond := "") -> bool:
	if night_rules.size() >= Data.NIGHT_RULES_MAX:
		return false
	if kind == "wager":
		if cond == "":
			cond = str(Data.WAGER_CONDS[0]["id"])
		night_rules.append({"kind": "wager", "code": "", "cond": cond, "on": true})
		return true
	if code == "":
		var known: Array = words_known()
		code = str(known[0]) if not known.is_empty() else str(Data.WORDS[0]["name"])
	night_rules.append({"kind": kind, "code": code, "cond": "", "on": true})
	return true


func night_rule_up(k: int) -> bool:
	if k <= 0 or k >= night_rules.size():
		return false
	var r = night_rules[k]
	night_rules[k] = night_rules[k - 1]
	night_rules[k - 1] = r
	return true


func night_rule_drop(k: int) -> bool:
	if k < 0 or k >= night_rules.size():
		return false
	night_rules.remove_at(k)
	return true


## A rule's kind or its code (or wager) stepped on by `by`; its on switch.
func night_rule_step(k: int, what: String, by := 1) -> bool:
	if k < 0 or k >= night_rules.size():
		return false
	var r: Dictionary = night_rules[k]
	match what:
		"kind":
			var kinds := ["want", "never", "wager"]
			r["kind"] = kinds[(kinds.find(str(r["kind"])) + by + kinds.size()) % kinds.size()]
			if str(r["kind"]) == "wager" and str(r.get("cond", "")) == "":
				r["cond"] = str(Data.WAGER_CONDS[0]["id"])
			if str(r["kind"]) != "wager" and str(r.get("code", "")) == "":
				var known: Array = words_known()
				r["code"] = str(known[0]) if not known.is_empty() else str(Data.WORDS[0]["name"])
		"value":
			if str(r["kind"]) == "wager":
				var ids: Array = Data.WAGER_CONDS.map(func(c): return str(c["id"]))
				r["cond"] = ids[(ids.find(str(r["cond"])) + by + ids.size()) % ids.size()]
			else:
				var known: Array = words_known()
				if known.is_empty():
					return false
				r["code"] = known[(known.find(str(r["code"])) + by + known.size()) % known.size()]
		"on":
			r["on"] = not bool(r.get("on", true))
	return true


## The odds floor for "Auto: keep going", in steps of 5%.
func night_floor_step(by: int) -> void:
	night_floor = clampf(snappedf(night_floor + 0.05 * by, 0.05), 0.05, 1.0)


## The next link set off from the break: its signal laid on its site and run as a run is, with the run's pack, tins,
## notes, salvage and held XP carried in; no rest, no gate top-up. False when it can't go.
func night_next() -> bool:
	if not night_break():
		return false
	var sg: Dictionary = night_next_sig()
	if sg.is_empty():
		return false
	var old: Dictionary = mission
	var k: int = signals.find(sg)
	var rolled: bool = k < 0
	if rolled:
		signals.append(sg)                     # laid on the Radio's list for the set-off only: deploy_signal takes it off
		k = signals.size() - 1
	mission = null
	_night_going = true
	var went: bool = deploy_signal(k)
	_night_going = false
	if not went:
		if rolled:
			signals.erase(sg)
		mission = old
		return false
	var m: Dictionary = mission
	for key in ["found", "pack_key", "night_xp", "wounded", "salvage"]:
		if old.has(key):
			m[key] = old[key]                  # the pack and what's held, as they stand
	for key in ["cash", "notes", "scrap", "meds_used", "finds", "ditched", "left", "xp", "cures_used"]:
		if old.has(key):
			m[key] = old[key] + m.get(key, 0)  # the night's so far and this link's start (a convoy's, a tip's)
	m["hp_start"] = float(old.get("hp_start", hp))
	m["notes_link0"] = int(old.get("notes", 0))     # the night's notes before this link: a notes wager pays on the rest (fix 50)
	night_chain.erase("head_back")             # the held signal's run now: its head goes with it
	night_chain["link"] = night_link() + 1
	night_chain["next"] = {}
	night_chain["next_id"] = -1
	_night_mark(m)
	log_event(Words.NIGHT["log_next"] % [night_link(), Words.mid(signal_place(sg)), signal_level(sg)])
	return true


## The odds to clear the next link as the runner stands - their HP, the meds and magazines in the rig, the wagers taken
## on it - read a few dry runs at a time as the Radio's are (the shell steps them). [odds, settled].
func night_odds() -> Array:
	var sg: Dictionary = night_next_sig()
	if sg.is_empty() or not _sig.is_empty():
		return [0.0, false]
	var held_m = mission
	_a51_night_pack = Array(held_m.get("found", [])) if held_m is Dictionary else []     # BUILD51-A: the night's own pack, not a gate's
	mission = null                             # read as a set-off would be: no run out
	_sig_on(sg)
	var i: int = int(sg["site"])
	var home = _surv_cache.get(i, null)
	if _sig_odds.has(int(sg["id"])):
		_surv_cache[i] = _sig_odds[int(sg["id"])]
	else:
		_surv_cache.erase(i)
	_f51_night_read = true                     # (FIX51) the dry runs begun in this read take the night's pack
	var o: float = survival(i)
	_f51_night_read = false                    # (FIX51)
	var done: bool = odds_settled(i)
	_sig_odds[int(sg["id"])] = _surv_cache[i]
	if home != null:
		_surv_cache[i] = home
	else:
		_surv_cache.erase(i)
	_sig_off()
	mission = held_m
	return [o, done]


## The odds read so far, running none (the break's screen).
func night_odds_now() -> Array:
	var sg: Dictionary = night_next_sig()
	if sg.is_empty() or not _sig.is_empty() or not _sig_odds.has(int(sg["id"])):
		return [0.0, false]
	var held_m = mission
	mission = null
	_sig_on(sg)
	var i: int = int(sg["site"])
	var c: Array = _sig_odds[int(sg["id"])]
	var out: Array = [float(c[1]), int(c[2]) >= mini(odds_runs(), Data.ODDS_RUNS)] if c[0] == _odds_key(i) else [0.0, false]
	_sig_off()
	mission = held_m
	return out


## A break with "Auto: keep going" ticked: the next link sets off by itself while the odds stay at or over the floor;
## under it the night waits for the player, said once. True when it set off.
func _night_auto_step() -> bool:
	if not night_auto or not night_break():
		return false
	var o: Array = night_odds()
	if not bool(o[1]):
		return false
	if float(o[0]) >= night_floor - 0.0001:
		return night_next()
	if int(night_chain.get("auto_said", -1)) != night_link():
		night_chain["auto_said"] = night_link()
		log_event(Words.NIGHT["auto_stop"] % [roundi(float(o[0]) * 100.0), roundi(night_floor * 100.0)])
	return false


## Kev's wager offered on the next link at a break: taken there as on the Radio.
func night_wager_key() -> String:
	var sg: Dictionary = night_next_sig()
	return ("sig:%d" % int(sg["id"])) if night_break() and not sg.is_empty() else ""


## The Radio's tune, retune and twist on the next link at a break, at their prices (signal_craft's, the run's held off
## the Radio for the craft).
func night_craft_block(key: String) -> String:
	var sg: Dictionary = night_next_sig()
	if sg.is_empty() or not night_break() or not (key in SIGNAL_CRAFTS):
		return "no next link"
	var held_m = mission
	mission = null
	_sig_on(sg)
	var why: String = word_craft_block(int(sg["site"]), key)
	_sig_off()
	mission = held_m
	return why


func night_craft_cost(key: String) -> int:
	var sg: Dictionary = night_next_sig()
	if sg.is_empty() or not _sig.is_empty():
		return 0
	var held_m = mission
	mission = null
	_sig_on(sg)
	var c: int = word_craft_cost(int(sg["site"]), key)
	_sig_off()
	mission = held_m
	return c


func night_craft(key: String) -> bool:
	if night_craft_block(key) != "":
		return false
	var sg: Dictionary = night_next_sig()
	var held_m = mission
	mission = null
	_sig_on(sg)
	var i: int = int(sg["site"])
	var ok: bool = word_craft(i, key)
	if ok:
		sg["words"] = words[i].duplicate(true)
		sg["sealed"] = sealed[i]
	_sig_off()
	mission = held_m
	return ok


## The night's haul so far, for the break: tins, notes, XP, the pack's materials by kind and its kit.
func night_haul() -> Dictionary:
	if mission == null or not mission.has("night"):
		return {}
	var m: Dictionary = mission
	var mats := {}
	var kit: Array = []
	for it in m["found"]:
		if it.get("carried", false) or it.get("from_rig", false):
			continue
		if Items.is_material(it):
			mats[str(it["base"])] = int(mats.get(str(it["base"]), 0)) + Items.stack_size(it)
		elif str(it.get("slot", "")) in Data.SLOTS:
			kit.append(it)
	kit.sort_custom(func(a, b): return int(a.get("rarity", 0)) > int(b.get("rarity", 0)))
	return {"tins": float(m["cash"]), "notes": int(m.get("notes", 0)), "xp": float(m.get("night_xp", 0.0)), "materials": mats, "kit": kit}


func _night_save() -> Dictionary:
	return {"night": night_chain.duplicate(true), "rules": night_rules.duplicate(true), "floor": night_floor, "auto": night_auto}


func _night_load(d: Dictionary) -> void:
	night_chain = d.get("night", {}).duplicate(true) if d.get("night", {}) is Dictionary else {}
	if not night_chain.is_empty():
		for k in ["link", "done", "kills", "next_id", "auto_said"]:
			if night_chain.has(k):
				night_chain[k] = int(night_chain[k])
		night_chain["fight_s"] = float(night_chain.get("fight_s", 0.0))
		night_chain["results"] = Array(night_chain.get("results", [])).map(func(x): return bool(x))
		if night_chain.get("next", {}) is Dictionary and not night_chain["next"].is_empty():
			_sig_ints(night_chain["next"])
			for wd in night_chain["next"].get("words", []):
				wd["t"] = int(wd["t"])
	if mission is Dictionary and mission.has("night"):
		mission["night"] = int(mission["night"])
	night_rules = []
	for r in d.get("rules", []):
		if r is Dictionary:
			night_rules.append({"kind": str(r.get("kind", "want")), "code": str(r.get("code", "")), "cond": str(r.get("cond", "")), "on": bool(r.get("on", true))})
	night_floor = float(d.get("floor", Data.NIGHT_FLOOR))
	night_auto = bool(d.get("auto", false))


## What the next link brings: its crew's area's materials as shares and the chance a link brings one. [{}, 0.0].
func night_materials() -> Array:
	var sg: Dictionary = night_next_sig()
	if sg.is_empty() or not _sig.is_empty():
		return [{}, 0.0]
	var held_m = mission
	mission = null
	_sig_on(sg)
	var i: int = int(sg["site"])
	var out: Array = [material_split(i), material_odds(i)]
	_sig_off()
	mission = held_m
	return out


## The runner as they stand at a break: the meds in the rig, the magazines full and the rounds loaded.
func night_carried() -> Dictionary:
	var meds := 0
	var mags := 0
	var rounds := 0
	for it in rig:
		if Items.is_medical(it):
			meds += Items.stack_size(it)
		elif Items.is_mag(it):
			rounds += int(it.get("rounds", 0))
			if int(it.get("rounds", 0)) >= Items.mag_cap(it):
				mags += 1
	return {"meds": meds, "mags": mags, "rounds": rounds, "meds_used": int(mission.get("meds_used", 0)) if mission != null else 0}


# ------------------------------------------------------------------ BUILD51-A (5 Nov): sim rules, the try-on, the web

## A magazine moved to the pack mid-fight comes back (the 0.13.0 playtest's item 3, Matt: "i nearly died because i
## couldnt move my secondary mag to take a med"): one the player takes out of the rig on a run stays out till the player
## puts it back - a hand-moved mark on the run (by id); the pull from the pack only for a gun that's had no magazine in
## the rig this run (the three-stage review's game 1, the fresh camp's first gun); never a heal out while a gang's on you.
func a51_mark_hand_out(m, it: Dictionary, on: bool) -> void:
	if not (m is Dictionary):
		return
	if not m.has("hand_out"):
		m["hand_out"] = {}
	var k: String = str(int(it.get("id", -1)))
	if on and Items.is_mag(it):
		m["hand_out"][k] = true
	else:
		m["hand_out"].erase(k)


func a51_hand_out(m: Dictionary, it: Dictionary) -> bool:
	return Dictionary(m.get("hand_out", {})).has(str(int(it.get("id", -1))))


## Each worn gun that has a magazine of its in the rig, marked for the run (by the gun's id).
func a51_mags_seen(m: Dictionary) -> void:
	if not m.has("mag_had"):
		m["mag_had"] = {}
	for slot in ["Primary", "Secondary"]:
		var g = equipped[slot]
		if g != null and Items.mag_size(g) > 0 and not m["mag_had"].has(str(int(g["id"]))) and not mags_for(g).is_empty():
			m["mag_had"][str(int(g["id"]))] = true


func a51_mag_had(m: Dictionary, gun: Dictionary) -> bool:
	return Dictionary(m.get("mag_had", {})).has(str(int(gun.get("id", -1))))


## In the quiet between gangs (_mags_topped): a worn gun that's had no magazine in the rig this run takes one that fits
## from the pack, room made as a gun fitted does - the room a gang on you never makes (a gun fitted mid-fight, the rig full).
var _a51_quiet := false                 # the quiet's own pull: the next gang not yet on you
func a51_quiet_pull(m: Dictionary) -> void:
	_a51_quiet = true
	for slot in ["Primary", "Secondary"]:
		var g = equipped[slot]
		if g != null and Items.mag_size(g) > 0 and mags_for(g).is_empty() and not a51_mag_had(m, g):
			_mag_from_pack(m, g)
	_a51_quiet = false


## The carries (the 0.13.0 playtest's item 6, Matt: "Catching and lingers do the same thing no?"): what a dying man's
## burn, poison or bleed leaves the next. A notable (Catching, Backdraught) carries half the dose; a capstone (Lingers,
## Wildfire, Bleed out) or a unique that carries (the Rat Man's Bag, the Butcher's Steel and Apron) the whole and
## A51_CARRY_GROW more each carry, to the combo ceiling; holding both, the capstone's.
const A51_CARRY_HALF := 0.5
const A51_CARRY_GROW := 0.25
func a51_carry_rate(ty: String) -> float:
	var whole := false
	var half := false
	match ty:
		"poison":
			whole = has_rule("rat_mans_bag") or has_node("cap_lingers")
			half = has_node("catching")
		"fire":
			whole = has_node("cap_spread")
			half = has_node("backdraught")
		"bleed":
			whole = has_rule("butchers_steel") or has_rule("butchers_apron") or has_node("cap_bleed_out")
	if whole:
		return 1.0 + A51_CARRY_GROW
	return A51_CARRY_HALF if half else 0.0


func a51_carried(dots: Dictionary, m = null) -> Dictionary:
	var out := {}
	for ty in ["poison", "fire", "bleed"]:
		var r: float = a51_carry_rate(ty)
		if r > 0.0 and dots.has(ty):
			out[ty] = minf(Data.COMBO_CEILING, float(dots[ty]) * r)
			if r > 1.0 and m is Dictionary:
				out[ty] = f51_carry_top(m, ty, float(dots[ty]), float(out[ty]))     # the growth's top (FIX51)
	return out


## Act two (f) (the break's dry run): a night's next link sets off with the pack as it stands - no gate, no top-up - so its
## odds read the boxes of rounds the night's pack holds, never the gate's (night_next carries "found" over as it is).
var _a51_night_pack: Array = []
func a51_dry_found(i: int) -> Array:
	if _f51_night_read:                        # (FIX51, the review's 9) inside night_odds' read, not night_on() and a cached pack
		return _a51_night_pack.filter(func(f): return Items.is_ammo(f)).map(func(f): return Dictionary(f).duplicate(true))
	return _gate_boxes(true, null, i) if gate_box_on(i) else []


## Nothing left to search on a run's site: every crate open, or none at all (the parked bug of 3 Nov: at a picked-over
## site the lull waited for a first search that never came, and the rolled event was silently lost).
func a51_nothing_to_search(m: Dictionary) -> bool:
	if m.get("crates_off", false):
		return false                          # the balance read's no-crates run: no lull rule of its own
	return crate_now(m).is_empty()


## The Quartermaster's Manual's count (its rule since the web's version two dropped the two-elements cap it lifted): the
## elements (fire, frost, poison, shock, bleed) the runner holds a perk in.
func a51_elements_held() -> int:
	return build_elements().filter(func(e): return str(e) in Data.ELEMENTS).size()


## The rig's swap capped (the 2 Nov reviews, for the balance pass: the swap lifted a gun's fire share to 1.0, +13-30%): a
## gun's share of the time firing never passes its no-swap share by more than this.
const A51_SWAP_LIFT := Data.F51_SWAP_LIFT     # (FIX51: the figure in Data, the affix's words read it)
## The swap's pause before magazine `mg` fires, in reload seconds (the reload's own clock): the gun fires its magazine in f,
## would reload in r; firing f of every f + pause holds it at its no-swap share f / (f + r) plus A51_SWAP_LIFT.
func a51_swap_pause(slot: String, mg: Dictionary) -> float:
	var gun = equipped[slot]
	if gun == null:
		return 0.0
	var rate: float = maxf(0.01, float(Items.base_of(gun)["rof"]))
	if slot == "Secondary" and equipped["Primary"] != null and has_rounds(equipped["Primary"]):
		var px: float = mag_share("Primary")
		rate *= secondary_share(true) * px + (1.0 - px) * reload_share()     # as mag_share reads the secondary's fire
	var f: float = float(Items.mag_cap(mg, gun)) / maxf(0.0001, rate)
	var r: float = reload_s(gun) * Items.mag_reload_x(mg)
	if r <= 0.0 or f <= 0.0:
		return 0.0
	var s1: float = minf(1.0, f / (f + r) + A51_SWAP_LIFT)
	return f * (1.0 - s1) / maxf(s1, 0.0001)
# ------------------------------------------------------------------ BUILD51-C (5 Nov): the speed

## front_tier's last few answers by their key (BUILD51-C): a signal's dry run parked across frames lays the signal on its
## site (its depth and words) and takes it off again, so the front's key flipped between two states every frame and each
## flip worked the front out afresh - every open site's effective(), ~1-2 ms a call, live_guard's ~2 ms a frame on the
## Radio of a late save. The same key is the same answer, so a handful kept by key is the old read, only cheaper; what
## effective() reads beyond the key (the runner's level against each site's clear: the campaign's level tax) is kept with
## them, so a level-up still works it out afresh as before.
const FRONT_SEEN_MAX := 8
var _front_seen := {}


func _c51_front_seen_key(key: int) -> int:
	return hash([key, level(), clear_level])


## The front kept for `key` as the runner stands, or -1.
func _c51_front_seen(key: int) -> int:
	return int(_front_seen.get(_c51_front_seen_key(key), -1))


func _c51_front_keep(key: int, front: int) -> void:
	if _front_seen.size() >= FRONT_SEEN_MAX:
		_front_seen.clear()
	_front_seen[_c51_front_seen_key(key)] = front


## The dogs on a repeat's run (BUILD51-C; the open notes: "dogs on a repeat run read their odds in one lump (~0.3 s)"):
## a run nobody watches answered them by its standing order the moment they came, so their read - DOG_READS dry fights
## - ran whole in that frame. In the game (asks) it's now the watched run's job, stepped DOGS_REPEAT_MS a frame by
## advance(), the run held still (no tick, its clocks stood) until it's read, then the order as before: the same odds,
## the same moment of the run. The bot and the tests' shells (asks off) read it whole as before.
const DOGS_REPEAT_MS := 3.0


func _c51_dogs_begin(m: Dictionary, ev: Dictionary) -> void:
	_dogs_job = {"ev": ev, "job": _dogs_begin(m, int(ev["n"]), threat_as(ev, m)), "unwatched": true}


## An unwatched run's dogs come and not yet answered (in the game): the run waits on their read and its order.
func _c51_dogs_held(m) -> bool:
	return m != null and asks and bool(m.get("unwatched", false)) and dogs_waiting(m)


## The read on for DOGS_REPEAT_MS (begun afresh if it isn't the job in hand: a load, say); read, the standing order
## answers. True when it's answered.
func _c51_dogs_step() -> bool:
	var ev: Dictionary = mission["ev"]
	if ev.has("odds"):
		_event_by_orders(mission)
		return true
	if _dogs_job.is_empty() or not is_same(_dogs_job["ev"], ev):
		_c51_dogs_begin(mission, ev)
	_dogs_job_run(Time.get_ticks_usec() + int(DOGS_REPEAT_MS * 1000.0))
	if not ev.has("odds"):
		return false
	_event_by_orders(mission)
	return true


# ------------------------------------------------------------------ FIX51 (5 Nov): the review of build 51

## The carry's top (the review's 1): a carry's growth (x1.25) never takes a pool past twice the element's normal cap at
## this site - the biggest cap _dot_add has worked out for it here - or, for a pool with no cap (the Rat Man's Bag or
## Overalls' poison, Opened for good's bleed), past twice the dose the site's first carry of it took. Never lower than
## the pool itself: a carry is the whole at least.
func f51_carry_top(m: Dictionary, ty: String, pool: float, grown: float) -> float:
	var top: float
	if f51_uncapped(ty):
		if not m.has("f51_first"):
			m["f51_first"] = {}
		if not m["f51_first"].has(ty):
			m["f51_first"][ty] = pool
		top = 2.0 * float(m["f51_first"][ty])
	else:
		top = 2.0 * float(Dictionary(m.get("f51_cap", {})).get(ty, pool))
	return maxf(pool, minf(top, grown))


## A pool with no top a gang could find: the Rat Man's poison, Opened for good's bleed.
func f51_uncapped(ty: String) -> bool:
	if ty == "poison":
		return has_rule("rat_mans_bag") or has_rule("rat_mans_overalls")
	return ty == "bleed" and combo_on("opened_for_good")


## The cap _dot_add worked out for the run's own pool on the gang (the mission's "dots"), the biggest at this site.
func _f51_cap_seen(dots: Dictionary, ty: String, cap: float) -> void:
	if mission == null or cap >= Data.COMBO_CEILING or not is_same(dots, mission.get("dots")):
		return
	if not mission.has("f51_cap"):
		mission["f51_cap"] = {}
	if cap > float(mission["f51_cap"].get(ty, 0.0)):
		mission["f51_cap"][ty] = cap


## A night's break reading its next link's odds (night_odds): the dry runs it begins take the night's own pack.
var _f51_night_read := false


## "Press on at N% odds or better": the player's order at WEATHER_PRESS_AT (Matt's, mid-playtest), the bot's at its own
## F51_BOT_PRESS_AT (the bot sets f51_bot_press).
var f51_bot_press := false


func f51_press_at() -> float:
	return Data.F51_BOT_PRESS_AT if f51_bot_press else Data.WEATHER_PRESS_AT


# ------------------------------------------------------------------ BUILD55-A (5 Nov): stages per site (docs/design/stages.md §2-4, §8)
# A campaign site's stage is its depth 1-3 (Data.STAGES); "1/3" on screen. 2/3 opens the next site (on a zone's last
# site, the head's own fight); 3/3 is for the grind. A signal's clear never moves a stage (it keeps depth >= 4).

var a55_done: Dictionary = {}     # site -> the furthest stage cleared on it (1-3); a signal's clear never moves it
var a55_pick: Dictionary = {}     # site -> the stage the player picked (1-3); none: the furthest open
var a55_new: Dictionary = {}      # site -> true: opened (by a 2/3 or a head's fall) and not yet picked - the Map's "· New"
var _a55_head := -1               # the site a head's own fight is being formed on (start_head_fight, head_fight_preview)


## The furthest stage cleared on site i (0-3).
func stage_done(i: int) -> int:
	return int(a55_done.get(i, 0))


## A stage's level: lv_at at the stage (the 1/3 the site's own, a level a stage up).
func stage_level(i: int, s: int) -> int:
	return lv_at(i, s)


## A stage's level gate: today's formula on the stage's level (wear_of(level) - 1).
func stage_gate(i: int, s: int) -> int:
	return maxi(1, wear_of(lv_at(i, s)) - 1)


## Shut for the runner's level: a stage not yet cleared, under its gate. Once cleared it stays open.
func stage_level_gated(i: int, s: int) -> bool:
	return stage_done(i) < s and level() < stage_gate(i, s)


## A stage can be run: the site open, the stage before it cleared, its level gate met.
func stage_open(i: int, s: int) -> bool:
	if i < 0 or i >= Data.TIERS.size() or s < 1 or s > Data.STAGES:
		return false
	return tier_open(i) and stage_done(i) >= s - 1 and not stage_level_gated(i, s)


## Why a stage is shut, in the card's words ("" when open): "After 1/3", "Opens at level 7", "After Top Farm 2/3",
## "After the Gamekeeper".
func stage_block(i: int, s: int) -> String:
	if stage_open(i, s) or i < 0 or i >= Data.TIERS.size():
		return ""
	var w: Dictionary = Words.A55_STAGE
	if not tier_open(i):
		var z: int = int(Data.TIERS[i]["zone"])
		var zt: Array = Data.ZONES[z]["tiers"]
		if not zone_open(z):
			if zone_level_shut(z):
				return w["level"] % zone_gate(z)
			var pz: int = maxi(0, z - 1)
			var hb: Dictionary = zone_boss(pz)
			for pi in Data.ZONES[pz]["tiers"]:
				if stage_done(int(pi)) < Data.STAGE_OPENS:
					return w["after_site"] % Words.mid(str(Data.TIERS[int(pi)]["name"]))
			if not hb.is_empty():
				return w["after_head"] % Words.mid(str(hb["name"]))
			return ""
		var k: int = zt.find(i)
		if k > 0 and stage_done(int(zt[k - 1])) < Data.STAGE_OPENS:
			return w["after_site"] % Words.mid(str(Data.TIERS[int(zt[k - 1])]["name"]))
		return w["level"] % site_gate(i)
	if s > 1 and stage_done(i) < s - 1:
		return w["after_stage"] % (s - 1)
	if stage_level_gated(i, s):
		return w["level"] % stage_gate(i, s)
	return ""


## The furthest stage open on a site (1 when none is).
func stage_furthest(i: int) -> int:
	for s in range(Data.STAGES, 0, -1):
		if stage_open(i, s):
			return s
	return 1


## The stage the card's Set off runs: the one picked while it's open, else the furthest open.
func stage_pick(i: int) -> int:
	var p: int = int(a55_pick.get(i, 0))
	if p >= 1 and stage_open(i, p):
		return p
	return stage_furthest(i)


## The player picks a stage on the card: kept until a new stage opens there; the site's depth follows it.
func set_stage_pick(i: int, s: int) -> void:
	if not stage_open(i, s):
		return
	a55_pick[i] = s
	mark_site_seen(i)
	_a55_sync(i)


## The site's depth set to its picked stage (never mid-run, never under a signal or a head's fight).
func _a55_sync(i: int) -> void:
	if i < 0 or i >= Data.TIERS.size() or runner_busy() or (not _sig.is_empty() and int(_sig["site"]) == i) or _a55_head == i:
		return
	var p: int = stage_pick(i)
	if int(depth[i]) != p:
		depth[i] = p
		_surv_cache.erase(i)
		_stats_dirty()


## The Map's "· New": opened by a 2/3 or a head's fall, open now, not yet picked.
func site_new(i: int) -> bool:
	return bool(a55_new.get(i, false)) and tier_open(i)


func mark_site_seen(i: int) -> void:
	a55_new.erase(i)


## The key a stage's first-clear level is kept under in clear_level: the site's own for the 1/3 (as before stages).
static func stage_key(i: int, s: int) -> int:
	return i + 100 * (maxi(1, s) - 1)


## A stage run's clear (from _clear): the stage's tick, its tax floor, the next site's "New", the cleared lines.
func _a55_stage_clear(m: Dictionary, t: Dictionary) -> void:
	if m.has("signal") or bool(m.get("head_fight", false)) or not m.has("stage"):
		return                                   # a signal's or a head's clear never moves a stage (BUILD55-A)
	var i: int = int(m["tier"])
	var s: int = int(m["stage"])
	if not clear_level.has(stage_key(i, s)):
		clear_level[stage_key(i, s)] = level()   # the level tax per stage: never on a stage not cleared
	if s <= stage_done(i):
		return
	a55_done[i] = s
	a55_pick.erase(i)                            # a new stage open: the card goes to the furthest again
	if s == Data.STAGE_OPENS:
		log_event(Words.site_cleared(str(t["name"])))     # the site's "cleared" line on its first 2/3 (the stage that opens the next)
		var zt: Array = Data.ZONES[int(Data.TIERS[i]["zone"])]["tiers"]
		var k: int = zt.find(i)
		if k >= 0 and k + 1 < zt.size():
			a55_new[int(zt[k + 1])] = true
	chron("stage", {"tier": i, "site": str(t["name"]), "stage": s, "level": level()})


## A head's first fall: the next zone's first site is new on the Map.
func _a55_head_first(z: int) -> void:
	if z + 1 < Data.ZONES.size():
		a55_new[int(Data.ZONES[z + 1]["tiers"][0])] = true
	if z == 1:
		log_event(Words.A55_STAGE["road_town"])     # the Retail Park's "the road to the Town is open", on the Carpet Man's fall


## The site a zone's head is fought on (his zone's last), -1 for none.
func head_site(z: int) -> int:
	var b: Dictionary = zone_boss(z)
	return int(b["tier"]) if not b.is_empty() else -1


## What the head's own fight costs: free until his first fall, then his notes (Long memory: paid once; Heads up).
func head_fight_cost(z: int) -> int:
	var b: Dictionary = zone_boss(z)
	if b.is_empty() or not bosses_beaten[z]:
		return 0
	var i: int = int(b["tier"])
	if atlas_rank("long_memory") > 0 and i < boss_paid.size() and (Data.STAGE_OPENS in boss_paid[i]):     # (FIX55b) his fight at his gate stage, paid there
		return 0
	return int(round(int(b["notes"]) * (1.0 - atlas_rank("heads_up") / 3.0)))


## Why the head's own fight is shut ("" when it can go): his site's 2/3 not cleared, the runner out, the notes short.
func head_fight_block(z: int) -> String:
	var i: int = head_site(z)
	var w: Dictionary = Words.A55_STAGE
	if i < 0:
		return w["head_after"]
	if not tier_open(i) or stage_done(i) < Data.STAGE_OPENS:
		return w["head_after"]
	if runner_busy() or not can_deploy():
		return w["head_busy"]
	var cost: int = head_fight_cost(z)
	if notes < cost:
		return w["head_notes"]
	return ""


func head_fight_open(z: int) -> bool:
	return head_fight_block(z) == ""


## The head's fight as it would be formed: his site at its 2/3 (FIX55b), half its gangs, then him on its 1/3 man ({} for none).
func head_fight_preview(z: int) -> Dictionary:
	var i: int = head_site(z)
	if i < 0:
		return {}
	var was: int = int(depth[i])
	var was_armed: bool = bool(boss_armed.get(i, false))
	depth[i] = Data.STAGE_OPENS     # (FIX55b) his gate stage, the 2/3: his gang its man
	_a55_head = i
	boss_armed[i] = true
	var e: Dictionary = effective(i)
	boss_armed[i] = was_armed
	_a55_head = -1
	depth[i] = was
	return e


## The head's own fight (stages.md §4): his site at its 3/3 level, half its gangs at the 3/3 man, then him at his
## BOSSES multipliers; his den the backdrop from the first man (mission["head_fight"]). The site's depth goes back
## after the run (_a55_run_end).
func start_head_fight(z: int) -> bool:
	if not head_fight_open(z):
		return false
	var i: int = head_site(z)
	var was: int = int(depth[i])
	var b: Dictionary = zone_boss(z)
	if Words.BOSSES.has(b["name"]):
		log_event(Words.LOG["head_armed"] % [b["name"], Words.BOSSES[b["name"]]["armed"]])     # his line as he's taken on (arm_boss's)
	depth[i] = Data.STAGE_OPENS     # (FIX55b) his gate stage, the 2/3: his gang its man
	_a55_head = i
	boss_armed[i] = true
	deploy(i)
	_a55_head = -1
	if mission == null or int(mission.get("tier", -1)) != i:
		boss_armed[i] = false
		depth[i] = was
		return false
	mission["head_fight"] = true
	mission["a55_was"] = was
	mission["depth"] = Data.STAGE_OPENS     # (FIX55b)
	mission.erase("stage")
	return true


## A run over (from _signal_done, both ends): a head's fight puts his site back at its stage; every other site's depth
## follows its picked stage (a clear or a level may have opened one). A signal's site goes back with _sig_off.
func _a55_run_end(m: Dictionary) -> void:
	if m.get("dry", false):
		return
	if bool(m.get("head_fight", false)) and m.has("a55_was"):
		var hi: int = int(m["tier"])
		depth[hi] = int(m["a55_was"])
		m.erase("a55_was")
		boss_armed[hi] = false
		_surv_cache.erase(hi)
	for i in range(Data.TIERS.size()):
		if (not _sig.is_empty() and int(_sig["site"]) == i) or (away() and int(repeat.get("site", -1)) == i):
			continue                             # a signal's site goes back with _sig_off; a repeat keeps its stage to the end
		var p: int = stage_pick(i)
		if int(depth[i]) != p and int(depth[i]) <= Data.STAGES:
			depth[i] = p
			_surv_cache.erase(i)


## A stage's run: the stage and its depth on the mission (signals keep their depth >= 4).
func _a55_mission_marks(m: Dictionary, i: int) -> void:
	if not _sig.is_empty() and int(_sig["site"]) == i:
		m["depth"] = site_depth(i)
		return
	m["depth"] = int(depth[i])
	if _a55_head != i:
		m["stage"] = clampi(int(depth[i]), 1, Data.STAGES)


## The saved stage state.
func a55_save() -> Dictionary:
	return {"done": a55_done.duplicate(), "pick": a55_pick.duplicate(), "new": a55_new.duplicate(), "county": b61_save()}     # (BUILD61-A) the County's


func a55_load(d: Dictionary) -> void:
	a55_done = {}
	a55_pick = {}
	a55_new = {}
	var st: Dictionary = d.get("stages", {}) if d.get("stages", {}) is Dictionary else {}
	for k in st.get("done", {}):
		a55_done[int(k)] = clampi(int(st["done"][k]), 0, Data.STAGES)     # JSON's keys come back as strings
	for k in st.get("pick", {}):
		a55_pick[int(k)] = clampi(int(st["pick"][k]), 1, Data.STAGES)
	for k in st.get("new", {}):
		if bool(st["new"][k]):
			a55_new[int(k)] = true


## The head's fight's odds, read as a site's are (the lookout's dry runs): his site at 3/3, his gang, then him. 0 when
## there's no head. The read lays the fight on the site for its runs and puts it back, in its own slot (FIX55, review 1:
## it shared the site's, so the card's head read and the shell's site read wiped each other and never settled). Stepped
## a few ms a frame when the shell calls it (main._read_odds, odds_step); whole for the bot and the gate.
func head_fight_odds(z: int) -> float:
	var i: int = head_site(z)
	if i < 0 or runner_busy():
		return 0.0
	return float(_f55_head_slot(z, func(): return survival(i)))


## The head's fight's odds as read so far, without running any (FIX55, review 1: the card reads this while the shell
## steps the read): [ready to show, the odds, settled].
func head_odds_now(z: int) -> Array:
	var i: int = head_site(z)
	if i < 0 or runner_busy():
		return [false, 0.0, false]
	return _f55_head_slot(z, func(): return [odds_ready(i), odds_now(i), odds_settled(i)])


## The head's fight laid on his site for `fn` (FIX55, review 1): depth 3, armed, _a55_head; the read and its tally in
## their own slots ("head:<site>"), as _whole's are, so the site's own read is never overwritten by his. All put back.
func _f55_head_slot(z: int, fn: Callable) -> Variant:
	var i: int = head_site(z)
	var slot := "head:%d" % i
	var home = _surv_cache.get(i, null)
	var home_t = _odds_tally.get(i, null)
	if _surv_cache.has(slot):
		_surv_cache[i] = _surv_cache[slot]
	else:
		_surv_cache.erase(i)
	if _odds_tally.has(slot):
		_odds_tally[i] = _odds_tally[slot]
	else:
		_odds_tally.erase(i)
	var was: int = int(depth[i])
	var was_armed = boss_armed.get(i, null)
	depth[i] = Data.STAGE_OPENS     # (FIX55b) his gate stage, the 2/3: his gang its man
	_a55_head = i
	boss_armed[i] = true
	var out = fn.call()
	if was_armed != null:
		boss_armed[i] = was_armed
	else:
		boss_armed.erase(i)                 # as it was: the shell's base hashes boss_armed
	_a55_head = -1
	depth[i] = was
	if _surv_cache.has(i):
		_surv_cache[slot] = _surv_cache[i]
	if _odds_tally.has(i):
		_odds_tally[slot] = _odds_tally[i]
	if home != null:
		_surv_cache[i] = home
	else:
		_surv_cache.erase(i)
	if home_t != null:
		_odds_tally[i] = home_t
	else:
		_odds_tally.erase(i)
	return out


# ------------------------------------------------------------------ BUILD55-C (5 Nov): themed finds (docs/design/stages.md §5)
## The stage a run is on: mission["stage"] (1-3) on a campaign site's stage, 0 for anything else - a signal's (depth 4
## or more), the head's own fight (FIX55, review 4: no 3/3 tier-up), a run with no stage. (FIX55: the stub's fallback
## to the run's depth is gone now A's mark is in.)
func c55_stage(m: Dictionary, _t: Dictionary) -> int:
	if bool(m.get("head_fight", false)) or not m.has("stage"):
		return 0
	return int(m["stage"])


## A find's themed list: the site's (Data.SITE_THEMES) for plain gear on a stage, [] otherwise - a signal's finds,
## papers, meds, rounds, parts and the rest roll as before.
func c55_theme(m: Dictionary, t: Dictionary, slot: String) -> Array:
	if not (slot in Data.SLOTS) or (c55_stage(m, t) <= 0 and not bool(m.get("head_fight", false))):     # (FIX55, review 4) his site's list on the head's fight too
		return []
	if county_run_key(m) != "":
		return Data.COUNTY_THEMES.get(county_run_key(m), [])     # (BUILD61-C) a County place's list, not its host site's (t["tier"] is the host)
	return Data.SITE_THEMES.get(str(Data.TIERS[int(t["tier"])]["name"]), [])


## A plain gear find's tier on a 3/3: STAGE_TIER_UP of them one up, never past loot_cap at the find's level. Draws the
## dice only on a 3/3, so every other run's finds roll as before.
func c55_tier_up(m: Dictionary, t: Dictionary, slot: String, tier_v: int, level_v: int) -> int:
	if not (slot in Data.SLOTS) or c55_stage(m, t) != 3 or county_run_key(m) != "":     # (BUILD61-C) a County 3/3's quarter is its top tier instead (c61_theme)
		return tier_v
	if rng.randf() < Data.STAGE_TIER_UP:
		return mini(loot_cap(level_v), tier_v + 1)
	return tier_v


# ------------------------------------------------------------------ FIX55 (5 Nov): the review's findings
## A stage's first clear (FIX55, review 3): the site's picked stage (its depth, 1-3) not yet cleared. Kev bets on it, as
## he did on a site's first clear before stages; the repeat's gate shuts on it (review 2).
func f55_first_clear(i: int) -> bool:
	return i >= 0 and i < Data.TIERS.size() and int(depth[i]) >= 1 and int(depth[i]) <= Data.STAGES and stage_done(i) < int(depth[i])


## Kev's offer on a zone's head's own fight (FIX55, review 3): its own key, as an armed head's was the site's.
static func wager_head_key(z: int) -> String:
	return "head:%d" % z


## Whether Kev has an offer on the head's fight: the Radio open and the fight open (his site's 2/3, the runner home).
func wager_head_open(z: int) -> bool:
	return room_open("radio") and head_fight_open(z)


# ------------------------------------------------------------------ BUILD61-C (6 Nov): the County's themed finds (docs/design/county_stages.md §4)
var _c61_top := false        # the last c61_theme's pick: a County 3/3's top-tier quarter (its share is the whole find)


## A plain gear find's themed list (the Items.roll call in _find): c55_theme's - the site's, or a County place's
## (Data.COUNTY_THEMES) - and on a County 3/3, STAGE_TIER_UP of them its top tier alone (c61_top): a tier up can't pass
## T9, so the quarter rolls from the list's T9 instead (Matt, 6 Nov: "your picks", open call 3). Draws dice only on a
## County 3/3's plain gear at T9, so every other find rolls as before.
func c61_theme(m: Dictionary, t: Dictionary, slot: String, tier_v: int) -> Array:
	_c61_top = false
	var lst: Array = c55_theme(m, t, slot)
	if lst.is_empty() or county_run_key(m) == "" or county_run_stage(m) != Data.STAGES or tier_v < Data.COUNTY_TOP_TIER:
		return lst
	if rng.randf() < Data.STAGE_TIER_UP:
		_c61_top = true
		return c61_top(county_run_key(m), slot)
	return lst


## The share of a find that rolls from its list: THEME_SHARE, or all of it on a County 3/3's top-tier quarter. Read right
## after c61_theme (the same find).
func c61_share(_m: Dictionary, _t: Dictionary, _slot: String) -> float:
	return 1.0 if _c61_top else Data.THEME_SHARE


## A County place's top tier for a slot: its list's T9 bases there, else every T9 base of the slot (the issued six off,
## never the start kit) - so the Motorway's 3/3, whose list is T7-T8, still finds its quarter at T9.
static func c61_top(k: String, slot: String) -> Array:
	var stamped: Array = Data.ISSUED.map(func(p): return str(p["base"]))
	var own: Array = []
	var any: Array = []
	for b in Data.BASES.get(slot, []):
		if int(b["tier"]) != Data.COUNTY_TOP_TIER or b.get("start", false) or str(b["name"]) in stamped:
			continue
		any.append(str(b["name"]))
		if str(b["name"]) in Data.COUNTY_THEMES.get(k, []):
			own.append(str(b["name"]))
	return own if not own.is_empty() else any


# ------------------------------------------------------------------ BUILD61-A (6 Nov): the County's stages (docs/design/county_stages.md §2-3, §7)
# A County place's stage is 1/3, 2/3 or 3/3, keyed by its place key (Data.COUNTY "key"). 2/3 opens the next place; on a
# zone's last place it opens the head's own fight, and his fall the next zone; 3/3 is for the grind. Each stage wants
# the zone's issued kit worn. A signal's clear (the remix) never moves a stage. Run as the order's are: a sig on the host
# site (order_sig), its figures the place's own row (_b61_figures), not the endgame curve.

var cs_done: Dictionary = {}       # place key -> the furthest stage cleared (0-3)
var cs_pick: Dictionary = {}       # place key -> the stage picked (1-3); none: the furthest open
var cs_new: Dictionary = {}        # place key -> true: opened (a 2/3, a head's fall) and not yet picked - the pin's "· New"
var county_heads: Dictionary = {}  # County zone -> its head's falls (was order_beaten[his place]; that stays the place's wins)


func county_stage_done(k: String) -> int:
	return int(cs_done.get(k, 0))


## A stage's level: the place's 1/3 (its row's `level`), COUNTY_STAGE_LEVELS a stage up.
func county_stage_level(k: String, s: int) -> int:
	var c: Dictionary = Data.county(k)
	if c.is_empty():
		return 0
	return int(c["level"]) + Data.COUNTY_STAGE_LEVELS * (clampi(s, 1, Data.STAGES) - 1)


## A stage can be run: the zone and the place open, the stage before cleared, the zone's issued kit worn.
func county_stage_open(k: String, s: int) -> bool:
	return is_county(k) and s >= 1 and s <= Data.STAGES and county_stage_block(k, s) == ""


## Why a stage is shut ("" when open), the card's words: "Not before the Issue", "After the Bailiff", "After the Toll
## Plaza 2/3", "After 1/3", the issued want.
func county_stage_block(k: String, s: int) -> String:
	var c: Dictionary = Data.county(k)
	if c.is_empty() or s < 1 or s > Data.STAGES:
		return Words.COUNTY["not_yet"]
	var z: int = int(c["cz"])
	var w: Dictionary = Words.A55_STAGE
	if not issued:
		return Words.COUNTY["not_yet"]
	if not county_zone_open(z):
		return w["after_head"] % Words.mid(str(Data.COUNTY_ZONES[z - 1]["head"]))
	if not county_open(k):
		var ks := county_places(z)
		return w["after_site"] % Words.mid(str(Data.county(str(ks[ks.find(k) - 1]))["place"]))
	if s > 1 and county_stage_done(k) < s - 1:
		return w["after_stage"] % (s - 1)
	if issued_worn() < county_want(z):
		return Words.COUNTY["want"] % [county_want(z), issued_worn()]
	return ""


## The furthest stage open (1 when none is).
func county_stage_furthest(k: String) -> int:
	for s in range(Data.STAGES, 0, -1):
		if county_stage_open(k, s):
			return s
	return 1


## The stage Go runs: the one picked while it's open, else the furthest open.
func county_stage_pick(k: String) -> int:
	var p: int = int(cs_pick.get(k, 0))
	if p >= 1 and county_stage_open(k, p):
		return p
	return county_stage_furthest(k)


func set_county_pick(k: String, s: int) -> void:
	if not county_stage_open(k, s):
		return
	cs_pick[k] = s
	mark_county_seen(k)


func county_site_new(k: String) -> bool:
	return bool(cs_new.get(k, false)) and county_open(k)


func mark_county_seen(k: String) -> void:
	cs_new.erase(k)


## A stage's figures (§3's table): {level, gangs, man_hp, man_dps, hp, dps} - the row's 1/3 man x1.22 a stage, the whole
## the man x gangs. Before the run's own (the night, the words, the issued plate).
func county_stage_figures(k: String, s: int) -> Dictionary:
	var c: Dictionary = Data.county(k)
	if c.is_empty():
		return {}
	var st: float = pow(1.0 + Data.DEPTH_HOSTILE, clampi(s, 1, Data.STAGES) - 1)
	var g: int = int(c["gangs"])
	var mh: float = float(c["man_hp"]) * st
	var md: float = float(c["man_dps"]) * st
	return {"level": county_stage_level(k, s), "gangs": g, "man_hp": mh, "man_dps": md, "hp": mh * g, "dps": md * g}


## A County place as a sig on its host site at stage `s`, or a head's own fight (`hz` his zone).
func county_sig(k: String, s: int, hz := -1) -> Dictionary:
	var c: Dictionary = Data.county(k)
	var site: int = int(c["site"])
	var st: int = Data.STAGE_OPENS if hz >= 0 else clampi(s, 1, Data.STAGES)
	var sg := {"id": -1, "site": site, "zone": int(c["zone"]), "depth": depth_for_level(site, county_stage_level(k, st)), "codes": [], "papers": [],
		"head": false, "convoy": false, "line": 0, "story": -1, "order": k, "stage": st}
	if hz >= 0:
		sg["chead"] = hz
	return sg


## The County's own figures on the fight (from effective, a County sig laid on its site): the row's man at the stage,
## its gangs (half, rounded down, on the head's fight, at the 2/3's man). Marks the run's County key, stage and head.
func _b61_figures(e: Dictionary, sg: Dictionary) -> void:
	var k: String = str(sg["order"])
	var hz: int = int(sg.get("chead", -1))
	var s: int = int(sg.get("stage", 1))
	var f: Dictionary = county_stage_figures(k, s)
	if f.is_empty():
		return
	e["hp"] = float(f["man_hp"])
	e["dps"] = float(f["man_dps"])
	e["pool"] = maxi(1, int(floor(float(f["gangs"]) / 2.0))) if hz >= 0 else int(f["gangs"])
	e["county_key"] = k
	e["stage"] = 0 if hz >= 0 else s
	e["chead"] = hz
	if hz >= 0:
		e["head_fight"] = true


## A County run's place key ("" for none) and its stage (1-3; 0 on a head's fight or none), off a mission.
static func county_run_key(m: Dictionary) -> String:
	return str(m.get("county", ""))


static func county_run_stage(m: Dictionary) -> int:
	if str(m.get("county", "")) == "" or bool(m.get("head_fight", false)):
		return 0
	return int(m.get("stage", 0))


## Run a County place at stage `s` (picked first).
func deploy_county(k: String, s: int) -> bool:
	if not county_stage_open(k, s):
		return false
	set_county_pick(k, s)
	return deploy_order(k)


## A County sig out: laid on its host site, the runner sent, the mission marked (the place, its stage or the head).
func _b61_deploy(sg: Dictionary) -> bool:
	_sig_on(sg)
	deploy(int(sg["site"]))
	if mission == null:
		_sig_off()
		return false
	mission["signal"] = sg
	_b61_marks(mission, sg)
	return true


func _b61_marks(m: Dictionary, sg: Dictionary) -> void:
	var k: String = str(sg["order"])
	m["county"] = k
	if sg.has("chead"):
		m["head_fight"] = true
		m["chead"] = int(sg["chead"])
		m.erase("stage")
	else:
		m["stage"] = int(sg.get("stage", 1))


# --- the heads' own fights

func county_head_place(z: int) -> String:
	return county_head_key(z)


func county_head_falls(z: int) -> int:
	return int(county_heads.get(z, 0))


## His fight's level: his place's 2/3 (48 / 57 / 66 / 75).
func county_head_level(z: int) -> int:
	return county_stage_level(county_head_key(z), Data.STAGE_OPENS)


## Why his fight is shut ("" when it can go): his place's 2/3 not cleared, the issued want, the runner out.
func county_head_fight_block(z: int) -> String:
	var k: String = county_head_key(z)
	var w: Dictionary = Words.A55_STAGE
	if k == "" or not issued or not county_open(k) or county_stage_done(k) < Data.STAGE_OPENS:
		return w["head_after"]
	if issued_worn() < county_want(z):
		return Words.COUNTY["want"] % [county_want(z), issued_worn()]
	if not can_deploy() or not _sig.is_empty() or runner_busy():
		return w["head_busy"]
	if not tier_open(int(Data.county(k)["site"])):
		return w["head_busy"]
	return ""


func county_head_fight_open(z: int) -> bool:
	return county_head_fight_block(z) == ""


## His fight as it would be formed ({} for none, or with a run out): effective() under his sig; e["boss"] is him.
func county_head_fight_preview(z: int) -> Dictionary:
	var k: String = county_head_key(z)
	if k == "" or not _sig.is_empty():
		return {}
	var sg := county_sig(k, Data.STAGE_OPENS, z)
	_sig_on(sg)
	var e := effective(int(sg["site"]))
	_sig_off()
	return e


## The read's key in _sig_odds for a County sig ("whole" for the repeat's full-HP read).
static func _b61_odds_key(sg: Dictionary, whole := false) -> String:
	var k: String = ("chead/%d" % int(sg["chead"])) if sg.has("chead") else ("order/%s" % str(sg["order"]))
	return "%s/%d%s" % [k, int(sg["depth"]), "/whole" if whole else ""]


## A County sig's odds: `step` runs a few dry runs (as order_odds), else reads what's there (as order_odds_now).
## [odds, settled]; with `ready` [ready to show, odds, settled].
func _b61_odds(sg: Dictionary, step: bool, whole := false, ready := false) -> Array:
	var none: Array = [false, 0.0, false] if ready else [0.0, false]
	if not _sig.is_empty():
		return none
	var key: String = _b61_odds_key(sg, whole)
	if not step and not _sig_odds.has(key):
		return none
	_sig_on(sg)
	var i: int = int(sg["site"])
	var h := hp
	if whole:
		hp = max_hp()
	var home = _surv_cache.get(i, null)
	if _sig_odds.has(key):
		_surv_cache[i] = _sig_odds[key]
	else:
		_surv_cache.erase(i)
	if step:
		survival(i)
	var out: Array = [odds_ready(i), odds_now(i), odds_settled(i)]
	if _surv_cache.has(i):
		_sig_odds[key] = _surv_cache[i]
	if home != null:
		_surv_cache[i] = home
	else:
		_surv_cache.erase(i)
	hp = h
	_sig_off()
	return out if ready else [float(out[1]), bool(out[2])]


## His fight's odds, a few dry runs a call (the shell's budget; whole for the bot): [odds, settled].
func county_head_fight_odds(z: int) -> Array:
	var k: String = county_head_key(z)
	if k == "" or county_stage_done(k) < Data.STAGE_OPENS:
		return [0.0, false]
	return _b61_odds(county_sig(k, Data.STAGE_OPENS, z), true)


## His fight's odds read so far, running none (the card): [odds, settled].
func county_head_odds_now(z: int) -> Array:
	var k: String = county_head_key(z)
	if k == "" or county_stage_done(k) < Data.STAGE_OPENS:
		return [0.0, false]
	return _b61_odds(county_sig(k, Data.STAGE_OPENS, z), false)


## His own fight: his gang, then him, on his place at its 2/3's level; his den from the first man (mission["head_fight"],
## mission["chead"]). Free, as County runs are.
func start_county_head(z: int) -> bool:
	if not county_head_fight_open(z):
		return false
	var k: String = county_head_key(z)
	var c: Dictionary = Data.county(k)
	if Words.BOSSES.has(c["who"]) and Words.BOSSES[c["who"]].has("armed"):
		log_event(Words.LOG["head_armed"] % [c["who"], Words.BOSSES[c["who"]]["armed"]])
	var sg := county_sig(k, Data.STAGE_OPENS, z)
	if not _b61_deploy(sg):
		return false
	chron("order_run", {"key": k, "level": county_head_level(z), "head": z})
	return true


# --- the clear

## A County run over (from _county_done, the sig still on): the stage's tick, the place's "taken" at its first 2/3 and
## the next place New; a head's fall, the next zone and its first place New. True when it handled the win.
func _b61_won(k: String) -> void:
	var c: Dictionary = Data.county(k)
	var z: int = int(c["cz"])
	var hz: int = int(_sig.get("chead", -1))
	var was_done: bool = county_done()
	if hz >= 0:
		var first: bool = county_head_falls(hz) == 0
		county_heads[hz] = county_head_falls(hz) + 1
		if first and hz + 1 < Data.COUNTY_ZONES.size():
			log_event(Words.COUNTY["zone_opens"] % [str(Data.COUNTY_ZONES[hz + 1]["name"]), county_want(hz + 1)])
			var nk: Array = county_places(hz + 1)
			if not nk.is_empty():
				cs_new[str(nk[0])] = true
		if county_done() and not was_done:
			log_event(Words.COUNTY["remix"])
		return
	order_beaten[k] = int(order_beaten.get(k, 0)) + 1     # the place's wins, any stage
	var s: int = clampi(int(_sig.get("stage", 1)), 1, Data.STAGES)
	if s <= county_stage_done(k):
		log_event(Words.COUNTY["again"] % str(c["place"]))
		return
	cs_done[k] = s
	cs_pick.erase(k)                               # a new stage open: the card goes to the furthest again
	chron("county_stage", {"key": k, "stage": s, "level": county_stage_level(k, s)})
	if s == Data.STAGE_OPENS:
		log_event(Words.COUNTY["taken"] % str(c["place"]))
		var ks: Array = county_places(z)
		var at: int = ks.find(k)
		if at >= 0 and at + 1 < ks.size():
			cs_new[str(ks[at + 1])] = true


# --- the repeat ("Run it ×N" on a County place)

## A County stage's first clear: the picked stage not yet cleared. Kev bets on it; the repeat shuts on it.
func county_first_clear(k: String) -> bool:
	return is_county(k) and county_stage_done(k) < county_stage_pick(k)


## The place's odds at full HP for the repeat's gate: [read, odds].
func county_repeat_odds(k: String) -> Array:
	var sg := county_sig(k, county_stage_pick(k))
	return _b61_odds(sg, false, hp < max_hp() - 0.01, true).slice(0, 2)


## The full-HP read, a step at a time (the shell's budget, as repeat_read).
func county_repeat_read(k: String) -> void:
	if mission != null or hp >= max_hp() - 0.01 or not is_county(k):
		return
	_b61_odds(county_sig(k, county_stage_pick(k)), true, true)


## Why "Run it ×N" is shut on a County place ("" when it can go).
func county_repeat_block(k: String) -> String:
	if not is_county(k) or not county_stage_open(k, county_stage_pick(k)):
		return Words.REPEAT["shut_site"]
	if away():
		return Words.REPEAT["shut_away"]
	if mission != null or not _sig.is_empty():
		return Words.REPEAT["shut_out"]
	if candidates.size() == 2:
		return Words.REPEAT["shut_trait"]
	if county_first_clear(k):
		return Words.REPEAT["shut_new"]
	if not stash_room(REPEAT_ROOM):
		return Words.REPEAT["shut_full"]
	var o: Array = county_repeat_odds(k)
	if not bool(o[0]):
		return Words.REPEAT["shut_reading"]
	if float(o[1]) < Data.REPEAT_ODDS:
		return Words.REPEAT["shut_odds"] % int(floor(float(o[1]) * 100.0))
	return ""


func county_can_repeat(k: String) -> bool:
	return county_repeat_block(k) == ""


## Set off on a County repeat: its picked stage, each run a County run (deploy_order's), unwatched.
func start_county_repeat(k: String) -> bool:
	if not county_can_repeat(k):
		return false
	var s: int = county_stage_pick(k)
	var c: Dictionary = Data.county(k)
	repeat = {"site": int(c["site"]), "county": k, "cstage": s, "of": repeat_count(), "done": 0, "phase": "rest", "stop": false, "bails_row": 0, "bails": 0, "runs": [], "kept": [], "ups": {},
		"t0": elapsed, "run_t0": elapsed, "lv0": level(), "wounds0": wounds.duplicate(true), "share": repeat_xp_share(), "own_list": yard_has("rr_list"), "first": true}
	repeat_report = {}
	var of: int = int(repeat["of"])
	log_event(Words.REPEAT["set_off"] % [Words.mid(str(c["place"])), (Words.REPEAT["times"] % of) if of > 0 else Words.REPEAT["till_full"]])
	chron("repeat", {"site": str(c["place"]), "of": of, "share": float(repeat["share"]), "county": k, "stage": s})
	if hp >= max_hp() - 0.01:
		_repeat_go()
	return true


## The repeat's run out on a County place (from _repeat_go, the rig packed): its stage's sig, sent.
func _b61_repeat_deploy() -> void:
	var k: String = str(repeat["county"])
	var s: int = int(repeat.get("cstage", 1))
	if county_stage_block(k, s) != "" or not can_deploy() or not _sig.is_empty():
		return                                  # mission stays null: _repeat_go ends the repeat with the reason
	_b61_deploy(county_sig(k, s))


## The repeat's place name: a County repeat's place, else its site's.
static func repeat_place_name(r: Dictionary) -> String:
	if str(r.get("county", "")) != "" and not Data.county(str(r["county"])).is_empty():
		return str(Data.county(str(r["county"]))["place"])
	return str(Data.TIERS[int(r.get("site", 0))]["name"])


# --- Kev's wagers

static func wager_county_key(k: String) -> String:
	return "county:%s" % k


static func wager_county_head_key(z: int) -> String:
	return "chead:%d" % z


func wager_county_open(k: String) -> bool:
	return room_open("radio") and not runner_busy() and county_stage_open(k, county_stage_pick(k)) and county_first_clear(k)


func wager_county_head_open(z: int) -> bool:
	return room_open("radio") and county_head_fight_open(z)


## The wager key of the County sig on site `i` ("" for none): the head's own, or the place's on a stage's first clear.
func _b61_wager_key(i: int) -> String:
	if _sig.is_empty() or int(_sig["site"]) != i or not is_county(str(_sig.get("order", ""))):
		return ""
	if _sig.has("chead"):
		return wager_county_head_key(int(_sig["chead"]))
	var k: String = str(_sig["order"])
	return wager_county_key(k) if county_stage_done(k) < int(_sig.get("stage", 1)) else ""


# --- the save

func b61_save() -> Dictionary:
	var heads := {}
	for z in county_heads:
		heads[str(z)] = int(county_heads[z])
	return {"done": cs_done.duplicate(), "pick": cs_pick.duplicate(), "new": cs_new.duplicate(), "heads": heads}


## The County's stage state, defaults for a save from before it (26): nothing cleared. A 26 save's County wins (none on
## Matt's fresh 0.14.0 save) carry over as the 2/3 on each place won and a fall for each head whose place was won.
func b61_load(d: Dictionary) -> void:
	cs_done = {}
	cs_pick = {}
	cs_new = {}
	county_heads = {}
	var st: Dictionary = d.get("stages", {}) if d.get("stages", {}) is Dictionary else {}
	if not (st.get("county", null) is Dictionary):
		for c in Data.COUNTY:
			var k: String = str(c["key"])
			if int(order_beaten.get(k, 0)) > 0:
				cs_done[k] = Data.STAGE_OPENS
				if c.has("who"):
					county_heads[int(c["cz"])] = int(order_beaten[k])
		return
	var cd: Dictionary = st["county"]
	for k in cd.get("done", {}):
		if is_county(str(k)):
			cs_done[str(k)] = clampi(int(cd["done"][k]), 0, Data.STAGES)
	for k in cd.get("pick", {}):
		if is_county(str(k)):
			cs_pick[str(k)] = clampi(int(cd["pick"][k]), 1, Data.STAGES)
	for k in cd.get("new", {}):
		if is_county(str(k)) and bool(cd["new"][k]):
			cs_new[str(k)] = true
	for z in cd.get("heads", {}):
		if int(z) >= 0 and int(z) < Data.COUNTY_ZONES.size():
			county_heads[int(z)] = maxi(0, int(cd["heads"][z]))
