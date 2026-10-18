extends RefCounted
## The camp and its one operator. Cash is the one number; the operator's level
## and the stash are the progression. A mission is the idle action: it runs in
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
var clinic: Array = []             # the Clinic's shelf: meds, so many a level, restocked after a run             # items for sale
var mission = null                 # null, or the mission in progress (a Dictionary)
var last_report = null             # the last mission's outcome, for Mission Control
var operators_lost := 0
var yard_picks := {}               # the Yard's lanes (9 Oct): building key -> [five sides, "a", "b" or ""]
var yard_ranks := {}               # building key -> ranks bought
var yard_open := 1                 # the columns opened, for good: a move doesn't close them
var yard_seen := {}                # what the Yard has been looked at with buyable ("key/col", "key/rN"): the rail's badge is for the rest
var yard_seen_cols := 1            # and the columns open then
var salvage := {"copper": 0, "steel": 0, "army": 0}    # the deep sites' salvage, one kind a zone (9 Oct)
var loot_by_hand := true          # the floor (13 Oct, Matt): a search's finds wait on the floor for the player to take; the bot reads them in as before
var away_on := false               # the shell's away-settling is running: Overtime and the Generator's rank pay on it
var hardcore := false              # a death ends the Yard, stash and all
var wound := ""                    # a wound (30): "pace", "armour" or "hp" cut a tenth until the Clinic treats it; "" for none
var camp_lost := false             # hardcore: set by the KIA that ended it
var tree: Array = []               # node ids taken, "Branch/index"; the camp's, kept across operators
var cls := ""                      # the operator's class, by name; "" is none yet
var cls2 := ""                     # the second past, from ASCEND_LEVEL: its first tree opens too
var runner_trait := ""             # what this runner turned up with
var candidates: Array = []         # when a runner dies, two turn up: their traits, to pick from
var promised := ""                 # a trait the next arrival brings (a runner brought home from a run)
var words: Array = []              # per tier: the Radio's words on the site, [{"w": name, "t": tier}] (9 Oct: map juicing)
var sealed: Array = []             # per tier: twisted, so nothing but Clear touches its words
var filtered := ""                 # the map's Clear air: a known word the Radio never rolls
var standing: Array = []           # the map's Relay and the whole band: words on every site with a ladder
var depth: Array = []              # per tier: the depth chosen, 1 up
var best_depth: Array = []         # per tier: the deepest cleared, 0 if none
var training_points := 0           # earned, one a level, across operators
var best_level := 1                # the camp's best level (9 Oct): a level earns a point only past it, so a new runner re-levels for nothing
var last_craft := {}               # the Bench's last job: {id, kind, words}, for the toast and the craft panel
var best_tier := 0                 # highest tier extracted from
var depot_cleared := false         # the slice's win
var past: Array = []               # the runners before this one: {class, level, runs, end}
var retired: Array = []            # the traits on the wall (36): a third of each stays with the Yard, newest last
var loose_kit: Array = []          # out on the estate: {item, who, from, run} - a dead runner's kit, a unique the Fence moved on
var book: Array = []               # the papers found, by name, in the order found: the drawer in the Caravan
var heard: Array = []                # the radio's lines heard, in order (12 Oct, the lore pass): voice/index keys
var keepsakes: Array = []          # the heads' things kept (15 Oct): the vet's bag, the ledger, the radio, the tool roll
var shelf: Array = []              # the uniques found, by name, in the order found: the shelf in the Caravan
var shelf_tier: Dictionary = {}    # a unique's name -> the best tier of it found (12 Oct, uniques by tier)
var worn: Array = []               # per tier: the elapsed second it was last cleared, or -1 - a picked-over site comes back over RECOVER_H
var worn_depth: Array = []         # and the depth it was cleared at: another depth is another site, fresh (Matt, 7 Oct: "depth needs to reset the site being picked over"); the worn depth stays worn until it recovers
var weather: Array = []            # per zone: "", "Rain" or "Fog"
var weather_at := -1               # the hour the weather was last rolled
var last_next := ""                # the last "what's next" line the log carried
var auto_equip := false            # idle: the best of each slot goes on when a run comes home
## The junk rules (11 Oct, Matt's list: in place of the one junk toggle). What the Fence takes when a run comes home:
## the gear at or under `junk_upto`'s rarity (-1, nothing), never an upgrade on what's worn (is_upgrade), never a kind
## kept (`junk_keep`, one of JUNK_KEEPS), and never what the junk run never took (rounds, meds, grenades, papers,
## parts that socket, uniques, set pieces, the deeds, a built gun).
const JUNK_KEEPS := {"": [], "guns": ["Primary", "Secondary"], "body": ["Helmet", "Armour", "Charm"], "bags": ["Rig", "Backpack"], "parts": ["Attachment"]}
var junk_upto := -1
var junk_keep := ""
var auto_sell: bool:                 # the old toggle: on is "sell the commons" (old saves, the tests)
	get:
		return junk_upto >= 0
	set(v):
		junk_upto = (maxi(junk_upto, 0) if v else -1)
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
var bosses_beaten: Array = []      # per zone: the crew's head is down
var boss_armed: Dictionary = {}    # tier -> true: the next run there takes the boss on
var notes := 0                     # the old paper money: the crews still take it
var scrap := 0                     # the Bench's material (34): found, stripped, ditched for
var takings := 0.0                 # what the Yard takes a run, averaged over the last few: the run's cash and the Fence's money (the pass, 6 Oct)
var gamble_base := 0.0             # the gamble's own: the takings, but a run moves it GAMBLE_STEP at most (13 Oct, Matt: 305 to 2366 off one sale)
var _takings_run := 0.0            # the cash in since the last run came home
var cash_in := 0.0                 # every pound in since the game began (runs, sales, contracts); not saved: the readers' figure
var atlas := {}                    # the map's passives: key -> rank
var boss_paid: Array = []          # per tier: the depths a head's price has been paid at (Long memory: once a depth)
var atlas_points := 0              # earned: one a new depth cleared past the first
var contracts: Array = []          # the Fence's: {kind, slot, rarity, count, level, stat, pay, amount, salvage}
var passes := 0                    # contracts turned down since the last run home: the first is free (9 Oct)
var mate := {}                     # the Fence's mate's offer: {unique, notes}
var runs_total := 0                # every run, every runner: the mate's clock
var wounded_total := 0             # runs that ended wounded, every runner (saved; the wounds row reads a player's save by it)
var yard_moves := 0                # how many times the Yard has moved (the prestige)
var lorry_done := false            # the convoy beaten in this yard (7 Oct); the move lights on it
var lorries := 0                   # across every yard: how many times
var paragon_banked := 0            # the paragon levels of the runners before, kept by the move (8 Oct)
var signals: Array = []            # the Radio's signals held (15 Oct): [{id, site, zone, depth, codes, papers, head, convoy, line}]
var reach := Data.REACH_START       # a level: the highest signal beaten, plus one (D3)
var signal_seq := 0
var story_beat := 0                 # Kev's story: the beats beaten (0-3); past the third the depot comes round again
var _sig: Dictionary = {}           # the signal swapped onto its site: read, or run (mission["signal"])
var best_dig := {}                 # the Yard's deepest hold: {site, depth, yard}, kept across moves (the wall's score)
var trades: Array = []             # the Yard's trade: elements whose keystone every class may take, one a move, for good
var insure_next := false           # the next run is insured: the Fence holds the paper on the kit
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
var mythics_on := true                  # off for the balance read: a read is never one (docs/design/mythics.md)


func _init() -> void:
	for s in Data.SLOTS:
		equipped[s] = null
	for i in range(Data.TIERS.size()):
		words.append([])
		sealed.append(false)
		depth.append(1)
		best_depth.append(0)
		worn.append(-1.0)
		worn_depth.append(1)
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
		return
	_seed_n += 1
	rng.seed = fixed_seed + _seed_n
	mythic_rng.seed = fixed_seed + _seed_n + 7919
	material_rng.seed = fixed_seed + _seed_n + 104729


func start() -> void:
	_reseed()
	unlocked = []                          # a fresh camp: every room a head opens is shut
	met = []
	_starter_loadout()
	for k in range(Data.START_STASH_BANDAGES):
		stash_put(_plain(Data.MEDICAL, "Bandage"))     # a new camp's spares (17 Oct, Matt): meds before the Clinic opens
	restock()
	came_back_seen()
	while contracts.size() < contracts_open():
		contracts.append(roll_contract())
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


## Levels past the cap (7 Oct): the same curve, +PARAGON_PCT damage and HP each, no top. The Yard's, not the runner's:
## a move banks the runner's paragon levels and the next runner adds to them (the eighteenth read: a fresh yard's runner
## at level 44 read the stations at 0.00 that the last one held at 1.00, with every paragon level gone).
func paragon() -> int:
	return paragon_banked + Data.paragon_for_xp(xp)


## The Yard's prestige: the lorries beaten, each LORRY_MULT on damage and HP, kept across moves.
static var lorry_mult_off := false   # the balance read's A/B switch (12 Oct): the lorries beaten multiply nothing
func lorry_mult() -> float:
	return 1.0 if lorry_mult_off else pow(Data.LORRY_MULT, lorries)


## What grows without end: the paragon levels and the lorries, as one multiplier on damage and HP.
func growth_mult() -> float:
	return (1.0 + Data.PARAGON_PCT * paragon() / 100.0) * lorry_mult()


func max_hp() -> float:
	return _memo("max_hp", _max_hp_raw)


func _max_hp_raw() -> float:
	var m := Data.BASE_HP + Data.HP_PER_LEVEL * (level() - 1) + tree_sum("hp")
	for s in Data.SLOTS:
		if equipped[s] != null:
			m += Items.affix_total(equipped[s], "hp")
	return m * cm("hp") * trait_mult("hp") * wound_mult("hp") * growth_mult() * (1.0 + (Data.FX["yard/theatre"] if yard_has("theatre") else 0.0) + Data.FX["yard_rank/clinic"] * yard_rank("clinic"))


## Damage a second: the primary, a third of the secondary, the level, the affixes.
## Damage a second: the primary while it has rounds, else the secondary at full
## (a third of it behind the primary, or all of it with Double tap), else fists.
func dps() -> float:
	if _trying or not (_dry_on or (fast_memo and mission != null)):
		return _dps(null)
	# the odds' runs and the reader's (15 Oct, refactor A4): the figure read twice a tick (dps, type_dps), so kept
	# while nothing it reads has moved - each gun fed or not and by what, HP either side of half, the first lot, the
	# XP, the kit (not the rounds' count: that moves every tick; which stacks have any decides the feed)
	var feed := []
	for it in rig:
		if it["slot"] == Data.AMMO and int(it["rounds"]) > 0:
			feed.append(it["base"])
	var k := [feed, hp < max_hp() * 0.5, mission != null and (not mission["cleared"] or mission.get("ghost_pending", false)), xp, wound, _kit_ids()]
	var c = _dry_memo.get("dps")
	if c != null and c[0] == k:
		return c[1]
	var v := _dps(null)
	_dry_memo["dps"] = [k, v]
	return v


## Damage a second in its parts (10 Oct, the Stats sheet's chain): {guns, level, pct, attack, past, trait, growth},
## each as dps() multiplies them - guns × (1 + level + pct) × (1 + attack) × past × trait × growth - so the sheet
## draws what dps() is made of and never a formula of its own.
func damage_parts() -> Dictionary:
	var parts := {}
	_dps(parts)
	return parts


func _dps(parts) -> float:
	var d := 0.0
	var primary_live := equipped["Primary"] != null and has_rounds(equipped["Primary"])
	var secondary_live := equipped["Secondary"] != null and has_rounds(equipped["Secondary"])
	if primary_live:
		d += Items.dps(equipped["Primary"]) * (1.0 + grade_bonus(equipped["Primary"]) / 100.0) * (Data.FX["node/cap_jerry"] if (has_node("cap_jerry") and gun_type() == "improvised") else 1.0) * _class_gun_mult(equipped["Primary"])   # Jerry-rigged: something improvised hits half again as hard
	if secondary_live:
		var sec := Items.dps(equipped["Secondary"]) * (1.0 + grade_bonus(equipped["Secondary"]) / 100.0) * _class_gun_mult(equipped["Secondary"]) * secondary_share(primary_live)
		if has_rule("branch_pistol") and hp < max_hp() * 0.5:
			sec *= Data.FX["rule/branch_pistol"]
		d += sec
	if d <= 0.0:
		d = Data.UNARMED_DPS
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
	return d * (1.0 + Data.DMG_PER_LEVEL * (level() - 1) + pct / 100.0) * (1.0 + _affix_sum("attack_pct") / 100.0) * cm("damage") * trait_mult("damage") * growth_mult()


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
	var a := 0.0
	for s in Data.SLOTS:
		if equipped[s] != null:
			a += Items.armour(equipped[s])
	a += _affix_sum("armour_per_med") * rig.size() + _fitted_sum("salt")
	if mission != null:
		a += _affix_sum("armour_per_free") * maxi(0, capacity_raw() - pack_used(mission))
	return a * (1.0 + (tree_sum("armour_pct") + _affix_sum("armour_pct")) / 100.0) * (Data.FX["node/shock_more.armour"] if (has_node("shock_more") and not has_rule("sparkys_gloves")) else 1.0) * wound_mult("armour")


## The wound's cut on a stat: a tenth off the one it names, nothing off the rest.
func wound_mult(stat: String) -> float:
	return 1.0 - Data.WOUND_PCT / 100.0 * (2.0 / 3.0 if yard_has("physio") else 1.0) if wound == stat else 1.0


## The wound in words: "Wounded: pace −10%", or "" unhurt.
func wound_words() -> String:
	if wound == "":
		return ""
	return "Wounded: %s −%d%%" % [("max HP" if wound == "hp" else wound), wound_pct()]


## The wound's cut as it is, in percent: Physio's third off included (18 Oct, Matt on Q7: it always read 10).
func wound_pct() -> int:
	return int(round((1.0 - wound_mult(wound)) * 100.0)) if wound != "" else 0


## A hit took the runner under a quarter: a wound, one stat cut until treated. A second replaces the first.
func _wound(m: Dictionary) -> void:
	if not room_open("clinic"):
		return                                # nothing to treat it with till the Gamekeeper's down (17 Oct, Matt's playtest): no wound before the Clinic
	var was := wound
	wound = Data.WOUND_STATS[rng.randi_range(0, Data.WOUND_STATS.size() - 1)]
	if not m.get("wounded", false):
		wounded_total += 1                # runs that ended wounded, every runner (the wounds row reads Matt's save by it, 8 Oct)
	m["wounded"] = true
	_dry_memo.clear()
	if wound == "hp":
		hp = minf(hp, max_hp())
	# one at a time (15 Oct, parked item 16: "Wounded again" four times read as stacking): a second says what it replaced
	var after: String = ""
	if was == wound:
		after = " (the same wound: one at a time)"
	elif was != "":
		after = " (replaces %s)" % ("max HP" if was == "hp" else was)
	log_event(wound_words() + after)


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
	return a / (a + Data.ARMOUR_K)


func _mitigation_raw() -> float:
	if has_rule("nans_cardigan"):
		return 0.0                               # no armour at all
	var a := armour() * cm("armour")
	return a / (a + Data.ARMOUR_K)


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
		total += 0.33
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
	if total > 1.0:
		for ty in Data.ELEMENTS:
			out[ty] /= total
		total = 1.0
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
	if (ty == "fire" and tree.has("Petrol/3")) or (ty == "poison" and tree.has("The Rat Man/3")) or (ty == "bleed" and (tree.has("Blades/3") or has_set_rule("carpet"))):
		s *= Data.FX["set/carpet.bleed_s"]
	if ty == "poison" and has_rule("rat_mans_overalls"):
		s *= Data.FX["rule/rat_mans_overalls"]                                 # the overalls: the same pool, twice as fast
	return s


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
func damage_split(res := {}) -> Dictionary:
	var per := type_dps()
	var hits := 0.0
	var dots := {}
	var dot := 0.0
	var grow := dot_grow(true)
	for ty in Data.TYPES:
		var r := float(res.get(ty, 0.0))
		if ty == "shock" and has_rule("sparkys_gloves"):
			r = 0.0
		var rate := float(per[ty]) * (1.0 - r)
		hits += rate
		if not Data.DOTS.has(ty) or rate <= 0.0:
			continue
		var cap := float(dot_stacks(ty, true)) * dot_depth(true) * (1.5 if (ty == "bleed" and has_node("cap_bleed_out")) else 1.0)
		var f := cap * maxf(grow, 1.0) if (ty == "bleed" and has_node("bleed_forever")) else minf(grow, cap * maxf(grow, 1.0))     # Won't stop: the pool never drains, so it sits at its cap
		dots[ty] = rate * float(Data.DOTS[ty]["ratio"]) * f
		dot += float(dots[ty])
	return {"hits": hits, "dots": dots, "dot": dot, "total": hits + dot}


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
	var r: float = _affix_sum("%s_res" % ty) + _affix_sum("all_res") + tree_sum("%s_res" % ty) + tree_sum("all_res") + _affix_sum("%s_proofed" % ty) + (0.0 if has_rule("blue_plaque") else base_res(ty))
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
		total += t["dps"] * on_you * share * ((1.0 - _mitigation_under(t)) if ty == "physical" else (1.0 - resist(ty)))
	return total * ((1.0 - chill_amount()) if chilled else 1.0) * (Data.MELEE_INCOMING if melee() else 1.0)


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
	dots[ty] = minf(cap, float(dots.get(ty, 0.0)) + landed * float(d["ratio"]) * grow)     # the trees' too, on them only (16 Oct: Fumes was read nowhere)


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
		var part: float = float(types[ty]) * ((1.0 - mitigation()) if ty == "physical" else (1.0 - resist(ty)))
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


## Loot the pack can bring back.
func capacity() -> int:
	return capacity_raw() * (Data.MYTHIC_PACK if has_rule("removal_van") else 1)     # the Removal Van (a mythic): four times the pack


## The pack as its frame and the tree make it, without the Removal Van: what the empty-cell sums read (the review: the
## Lorry's Load paid notes for 9,999 cells).
func capacity_raw() -> int:
	var extra := (Data.FX["node/pack_mule"] if has_node("pack_mule") else 0)
	var base := 2 if equipped["Backpack"] == null else maxi(1, Items.capacity(equipped["Backpack"]))
	return int((base + extra) * (Data.FX["node/hoarder.capacity"] if has_node("hoarder") else 1) * (Data.FX["rule/the_float.capacity"] if has_rule("the_float") else 1.0))


## Meds the rig can carry. No rig, no meds. (The Float stops the meds only, not the rig: 18 Oct, Matt's call on Q0.)
func med_capacity() -> int:
	if equipped["Rig"] == null:
		return 0
	var n: int = (Items.capacity(equipped["Rig"]) + int(tree_sum("med_cap")) + int(_affix_sum("med_cap"))) * (Data.FX["rule/issue_webbing"] if has_rule("issue_webbing") else 1)
	n += (Data.FX["yard/rig_wiring"] if yard_has("rig_wiring") else 0) + (Data.RIG_ROW if yard_has("battery") else 0)    # the Generator's picks
	return mini(n, Data.RIG_CAP)


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
	b += _affix_sum("loot_per_med") * rig.size() / 100.0
	if has_node("poison_more"):
		b -= Data.FX["node/poison_more.quantity"]                                 # the rat's share
	return b


## Rarer finds: the tree's and the class's, as a bonus the roll reads.
func rarity_bonus() -> float:
	var r := tree_sum("rarity") / 100.0 + trait_add("rarity") + charm_find() / 100.0 + Data.MOVE_FIND * yard_moves / 100.0 \
		+ yard_quality() / 100.0       # the dog knows what's worth carrying (27)
	return r * (Data.FX["rule/bookies_pencil.rarity"] if has_rule("bookies_pencil") else 1.0)


func sell_price(it: Dictionary) -> int:
	return int(round(it["value"] * inflation() * (1.0 + (tree_sum("sell_pct") + set_stat("sell_pct") + (Data.FX["joint/scrapper_fire.sell"] if has_joint("scrapper_fire") else 0.0) + yard_sell_pct()) / 100.0) * (Data.FX["node/buyers_market.sell"] if has_node("buyers_market") else 1.0)))


## HP for the screens: whole points, rounded the same way both sides, never past the max.
func max_hp_shown() -> int:
	return int(round(max_hp()))


func hp_shown() -> int:
	return mini(max_hp_shown(), int(ceil(hp - 0.001)))


## Money that goes off: what a pound of the opening day's price costs now.
## Every cash price and every cash income runs through it; the notes don't.
func inflation() -> float:
	var h: float = maxf(0.0, elapsed / 3600.0 - Data.INFLATION_GRACE_H)
	return minf(Data.INFLATION_CAP, 1.0 + Data.INFLATION_RATE * h)


## The rise, in percent, for the screens: "Prices up 42%".
func inflation_pct() -> int:
	return int(round((inflation() - 1.0) * 100.0))


## A cash price of the opening day, at today's: rounded to the pound, never below the original when it was positive.
func _inf(x: float) -> int:
	return int(round(x * inflation()))


# ------------------------------------------------------------------ the class

func class_data() -> Dictionary:
	for c in Data.CLASSES:
		if c["name"] == cls:
			return c
	return {}


## A class multiplier by key, 1.0 without one.
func cm(key: String) -> float:
	return float(class_data().get(key, 1.0))


func set_class(name: String) -> bool:
	if mission != null or name == cls or name == cls2:
		return false                       # the second past's class is taken already: a change to it would lose the second past
	_dry_memo.clear()
	for c in Data.CLASSES:
		if c["name"] == name:
			# a change costs the respec of what it gives back (9 Oct: clicking a class was a free respec); a new runner picks free
			var cost := class_change_cost(name)
			if cost > 0 and cash < cost:
				return false
			var drops: Array = _change_drops(name)
			cash -= cost
			chron("class", {"from": cls, "to": name, "cost": cost, "dropped": drops.size()})
			cls = name
			# the old class's trees come back as points, and what the new class can't keep: another class's half, an
			# element off its pair (it would cost double now); the Yard's and the pair's elements stay
			tree = tree.filter(func(id): return not (id in drops))
			log_event("The runner was a %s, before" % name)
			_say_next()
			return true
	return false


## What a class change to `to` costs: the respec price of what it gives back (_change_drops) - those points at
## the respec rate, at today's prices. Nothing with no class yet, or nothing to give back.
func class_change_cost(to := "") -> int:
	if cls == "":
		return 0
	var pts := 0
	for id in _change_drops(to):
		pts += node_cost(id)
	return _inf(pts * Data.RESPEC_CASH)


## The nodes a change to `to` gives back: the old class's trees; and, when `to` is named, another class's half
## in an element tree and an element off `to`'s pair (the second past's affinities still count).
func _change_drops(to := "") -> Array:
	var out: Array = []
	var keep_classes: Array = [to, cls2].filter(func(c): return c != "")
	for id in tree:
		var tn: String = str(id).get_slice("/", 0)
		var t := Data.tree_named(tn)
		if cls != "" and t.get("class", "") == cls:
			out.append(id)                 # (a runner with no class has no class trees: the Yard's has no "class" either)
		elif to != "" and t.has("element"):
			var el: String = t["element"]
			var paired: bool = has_rule("qm_manual") or el in trades or keep_classes.any(func(c): return el in Data.AFFINITY.get(c, []))
			if not paired or not Data.for_classes(node(id), keep_classes):
				out.append(id)
	return out


# ------------------------------------------------------------------ the tree

## The three trees on show: the class's first, the Yard's, the class's second.
## The trees on show: the class's, the Yard's, the second past's, and every element's.
func trees() -> Array:
	var out: Array = Data.trees_for(cls, cls2)
	out.append_array(Data.ELEMENT_TREES)
	return out


## Whether an element is one of the runner's two (or the second past's).
func affinity(element: String) -> bool:
	if element == "" or has_rule("qm_manual") or element in trades:
		return true
	return element in Data.AFFINITY.get(cls, []) or element in Data.AFFINITY.get(cls2, [])


## The Yard's trade: an element the move brings with it. Any of the five not taken already.
func can_trade(element: String) -> bool:
	return element in Data.ELEMENTS and not (element in trades)


## The runner's trait, as a multiplier on a figure (1.0 when it has none), and
## a third of every retired runner's with it (36).
func trait_mult(key: String) -> float:
	var m := 1.0
	for t in Data.TRAITS:
		if t["name"] == runner_trait:
			m *= float(t.get(key, 1.0))
		if t["name"] in retired:
			m *= 1.0 + maxf(0.0, float(t.get(key, 1.0)) - 1.0) * Data.RETIRE_SHARE * retired.count(t["name"])     # the good third only: the wall keeps what they were good at
	return m


## A trait's additive figure (the Lucky one's loot quality), the runner's and the wall's third.
func trait_add(key: String) -> float:
	var a := 0.0
	for t in Data.TRAITS:
		if t["name"] == runner_trait:
			a += float(t.get(key, 0.0))
		if t["name"] in retired:
			a += float(t.get(key, 0.0)) * Data.RETIRE_SHARE * retired.count(t["name"])
	return a


## Retirement (36): at RETIRE_LEVEL the runner can go to the wall instead of dying on a run. Their kit comes
## off into the stash, their trees refund as a death's do, the Yard keeps a third of their trait, and two
## new runners turn up to pick from.
func can_retire() -> bool:
	return level() >= Data.RETIRE_LEVEL and cls != "" and mission == null


func retire() -> bool:
	if not can_retire():
		return false
	chron("retire", {"trait": runner_trait, "runner_runs": runner_runs})
	past.append({"class": cls, "level": level(), "runs": runner_runs, "end": "retired", "site": _deepest_held()[0], "depth": _deepest_held()[1], "held_lv": _deepest_held()[2]})
	if runner_trait != "":
		retired.append(runner_trait)
		while retired.size() > Data.RETIRED_MAX:
			retired.pop_front()              # the oldest makes way
	log_event("%s retires to the wall at level %d. The Pitch keeps a little of what they were." % [cls, level()])
	runner_runs = 0
	_record_reset()
	for s in Data.SLOTS:
		if equipped[s] != null:
			stash.append(equipped[s])        # theirs stays: whatever the room
			equipped[s] = null
	for it in rig:
		if not stash_put(it):
			stash.append(it)
	rig = []
	xp = 0.0
	wound = ""
	hp = Data.BASE_HP
	auto_tier = -1
	_starter_loadout()
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
	_refund_runner_trees()
	_dry_memo.clear()
	return true


# ------------------------------------------------------------------ the Fence's contracts

## One contract (9 Oct): a kind of ask and what it pays, in currency.
func roll_contract() -> Dictionary:
	var kind: String = _weighted(Data.CONTRACT_KINDS)
	if kind == "deep" and deepest_site_level() - Data.CONTRACT_DEEP_LESS < Data.CONTRACT_DEEP_FROM:
		kind = "gear"                             # a deep ask wants a deep site first: early, any piece would do
	var c := {"kind": kind, "slot": "", "rarity": 1, "count": 1, "level": 0, "stat": "", "pay": "cash", "amount": 0, "salvage": ""}
	match kind:
		"gear":
			c["slot"] = Data.CONTRACT_SLOTS[rng.randi_range(0, Data.CONTRACT_SLOTS.size() - 1)]
			c["rarity"] = rng.randi_range(1, 2)
			c["count"] = rng.randi_range(1, 3)
		"deep":
			c["count"] = rng.randi_range(1, 2)
			c["level"] = maxi(2, deepest_site_level() - Data.CONTRACT_DEEP_LESS)
		"affix":
			c["slot"] = Data.CONTRACT_SLOTS[rng.randi_range(0, Data.CONTRACT_SLOTS.size() - 2)]     # gear with affixes: not the gun parts
			var allowed: Array = Items.allowed_affixes(c["slot"])
			if allowed.is_empty():
				c["kind"] = "gear"
				c["rarity"] = 1
			else:
				c["stat"] = allowed[rng.randi_range(0, allowed.size() - 1)]["stat"]
		"papers":
			c["count"] = rng.randi_range(2, 4)
		"meds":
			c["count"] = rng.randi_range(2, 5)
	_price_contract(c)
	return c


## A key by its weight: {"a": 0.5, "b": 0.25, ...}.
func _weighted(w: Dictionary) -> String:
	var total := 0.0
	for k in w:
		total += float(w[k])
	var r := rng.randf() * total
	for k in w:
		r -= float(w[k])
		if r <= 0.0:
			return k
	return w.keys().back()


## How much an ask is worth: the count × the rarity for gear, three a deep piece, three an affix, a paper apiece,
## a med a half.
func contract_weight(c: Dictionary) -> float:
	match str(c.get("kind", "gear")):
		"deep":
			return 3.0 * int(c["count"])
		"affix":
			return 3.0
		"papers":
			return float(int(c["count"]))
		"meds":
			return int(c["count"]) / 2.0
	return float(int(c["count"]) * int(c["rarity"]))


## The zones whose salvage drops: a site of it dug to SALVAGE_DEPTH.
func salvage_kinds() -> Array:
	var out: Array = []
	for z in range(Data.ZONES.size()):
		for i in Data.ZONES[z]["tiers"]:
			if dug_depth(i) >= Data.SALVAGE_DEPTH and Data.ZONE_SALVAGE[z] != "":
				out.append(Data.ZONE_SALVAGE[z])
				break
	return out


## What it pays: cash a share of a run's takings (today's prices), notes and scrap by the deepest depth, salvage by
## the weight - never a salvage no site drops yet.
func _price_contract(c: Dictionary) -> void:
	var pays: Dictionary = Data.CONTRACT_PAYS.duplicate()
	var kinds := salvage_kinds()
	if kinds.is_empty():
		pays.erase("salvage")
	if c["kind"] == "meds":
		pays.erase("cash")                        # meds the Clinic sells for pennies: never a cash pump
	c["pay"] = _weighted(pays)
	var w := contract_weight(c)
	var deep: float = 1.0 + deepest() / 5.0
	match c["pay"]:
		"cash":
			c["amount"] = maxi(10, int(round(a_runs_takings() * Data.CONTRACT_CASH * minf(w, Data.CONTRACT_CASH_WEIGHT_MAX) / 10.0)) * 10)     # a share of a run's takings
		"notes":
			c["amount"] = maxi(1, int(ceil(Data.CONTRACT_NOTES * w * deep)))
		"scrap":
			c["amount"] = maxi(1, int(ceil(Data.CONTRACT_SCRAP * w * deep)))
		"salvage":
			c["salvage"] = kinds[rng.randi_range(0, kinds.size() - 1)]
			c["amount"] = maxi(1, int(ceil(w)))
	_contract_floor(c)


## A gear ask's pay never under CONTRACT_OVER_FENCE of what its pieces fetch (12 Oct): cash at the Fence's price, scrap
## at what they'd scrap for. Raises, never lowers: a save's contracts come up to it on load.
func _contract_floor(c: Dictionary) -> void:
	var worth := contract_worth(c)
	if worth <= 0.0:
		return
	match str(c.get("pay", "")):
		"cash":
			var price_v: float = float(sell_price({"value": int(round(worth))}))
			c["amount"] = maxi(int(c["amount"]), int(round(price_v * Data.CONTRACT_OVER_FENCE / 10.0)) * 10)
		"scrap":
			c["amount"] = maxi(int(c["amount"]), int(ceil(worth / Data.SCRAP_PER_POUND * Data.CONTRACT_OVER_FENCE)))


## What a gear ask's pieces are worth (12 Oct), before the Fence's own price: the slot's bases a find draws now (the
## deepest open site's loot tier, held to the slot's top, and the two under it; never the starting kit, a site's own or
## a socketable), their mean value at the rarity asked, times the count. A deep ask reads every contract slot at the
## level's tier; an affix ask an uncommon of its slot; papers and meds nothing (their pay stays as it was).
func contract_worth(c: Dictionary) -> float:
	var kind := str(c.get("kind", "gear"))
	if not (kind in ["gear", "deep", "affix"]):
		return 0.0
	var want: int = loot_tier_at(int(c["level"]) if kind == "deep" else deepest_site_level())
	var slots: Array = Data.CONTRACT_SLOTS if kind == "deep" else [str(c["slot"])]
	var r: int = 1 if kind == "affix" else (0 if kind == "deep" else clampi(int(c["rarity"]), 0, Data.RARITIES.size() - 1))
	var total := 0.0
	var n := 0
	for slot in slots:
		var pool: Array = []
		var top := 1
		for b in (Data.ATTACHMENTS if slot == Data.ATTACHMENT else Data.BASES[slot]):
			if b.get("start", false) or str(b.get("mount", "")) == "socket" or Items.exclusive_to(str(b["name"])) != "" or not b.has("value"):
				continue
			pool.append(b)
			top = maxi(top, int(b.get("tier", 1)))
		var t_hi: int = mini(want, top)
		for b in pool:
			var t := int(b.get("tier", 1))
			if t <= t_hi and t >= t_hi - 2:
				total += float(b["value"])
				n += 1
	if n == 0:
		return 0.0
	return total / n * float(Data.RARITIES[r]["value"]) * int(c.get("count", 1))


func contract_fits(c: Dictionary, it: Dictionary) -> bool:
	if it.has("unique") or it.has("set") or Items.is_deeds(it):
		return false
	match str(c.get("kind", "gear")):
		"deep":
			return str(it["slot"]) in Data.CONTRACT_SLOTS and Items.ilvl(it) >= int(c["level"])
		"affix":
			return it["slot"] == c["slot"] and it.get("affixes", []).any(func(a): return a["stat"] == c["stat"])
		"papers":
			return Items.is_paper(it)
		"meds":
			return Items.is_medical(it)
	return it["slot"] == c["slot"] and int(it["rarity"]) >= int(c["rarity"])


## What in the stash would go to this contract: the cheapest that fit, up to its count.
func contract_items(c: Dictionary) -> Array:
	var fits: Array = []
	for it in stash:
		if contract_fits(c, it):
			fits.append(it)
	fits.sort_custom(func(a, b): return a["value"] < b["value"])
	return fits.slice(0, int(c["count"]))


func can_hand_in(k: int) -> bool:
	if not room_open("fence") or mission != null or k < 0 or k >= contracts.size():
		return false
	var c: Dictionary = contracts[k]
	return contract_items(c).size() >= int(c["count"])


func hand_in(k: int) -> bool:
	if not can_hand_in(k):
		return false
	var c: Dictionary = contracts[k]
	for it in contract_items(c):
		_remove(it)
	var paid := ""
	match c["pay"]:
		"cash":
			cash += float(c["amount"])          # not through _earn: a run's takings price the contracts, and this would feed them
			cash_in += float(c["amount"])
			paid = _cash_words(float(c["amount"]))
		"notes":
			var n_paid: int = int(c["amount"]) * (Data.FX["yard/fixer"] if yard_has("fixer") else 1)     # the Fence's Fixer
			notes += n_paid
			paid = "%d notes" % n_paid
		"scrap":
			scrap += int(c["amount"])
			paid = "%d scrap" % int(c["amount"])
		"salvage":
			salvage[c["salvage"]] = int(salvage.get(c["salvage"], 0)) + int(c["amount"])
			paid = contract_pay_words(c)
	log_event("Handed in: %s. %s" % [contract_words(c), paid])
	chron("contract", {"kind": str(c.get("kind", "")), "pay": str(c["pay"]), "amount": int(c.get("amount", 0))})
	contracts[k] = roll_contract()
	return true


## The price of turning one down now: the first after a run home free, then notes, doubling.
func pass_cost() -> int:
	if passes == 0:
		return 0
	return Data.CONTRACT_PASS_NOTES * int(pow(2, passes - 1))


func can_pass_contract(k: int) -> bool:
	return mission == null and k >= 0 and k < contracts.size() and notes >= pass_cost()


## Turn one down: another in its place, the price paid.
func pass_contract(k: int) -> bool:
	if not can_pass_contract(k):
		return false
	notes -= pass_cost()
	passes += 1
	contracts[k] = roll_contract()
	return true


func contract_words(c: Dictionary) -> String:
	var n: int = int(c["count"])
	var num: String = ["", "one", "two", "three", "four", "five", "six"][n] if n <= 6 else str(n)
	match str(c.get("kind", "gear")):
		"deep":
			return "%s piece%s from level %d up" % [num, "" if n == 1 else "s", int(c["level"])]
		"affix":
			var slot: String = "gun part" if c["slot"] == Data.ATTACHMENT else str(c["slot"]).to_lower()
			return "%s %s with %s" % ["an" if slot.substr(0, 1) in ["a", "e", "i", "o", "u"] else "a", slot, contract_affix_phrase(str(c["stat"]))]
		"papers":
			return "%s paper%s, any" % [num, "" if n == 1 else "s"]
		"meds":
			return "%s med%s, any" % [num, "" if n == 1 else "s"]
	var noun: String = "gun part" if c["slot"] == Data.ATTACHMENT else str(c["slot"]).to_lower()
	if n != 1:
		noun = noun.trim_suffix("y") + "ies" if noun.ends_with("ry") else noun + "s"     # primaries, not primarys
	var what: String = "%s %s" % [Data.RARITIES[c["rarity"]]["name"].to_lower(), noun]
	return "%s %s" % [num, what]


## An affix as a contract names it: a conversion as such, the two armours apart, a long label to its first clause.
func contract_affix_phrase(stat: String) -> String:
	if stat.begins_with("conv_"):
		return "%s conversion" % stat.trim_prefix("conv_").trim_suffix("_pct")
	if stat == "armour_pct":
		return "% armour"
	if stat == "armour":
		return "flat armour"
	if stat == "dot_pct":
		return "damage over time"
	var a: Dictionary = Items.affix_def(stat)
	return str(a.get("label", stat)).get_slice(",", 0)


func contract_pay_words(c: Dictionary) -> String:
	match c["pay"]:
		"cash":
			return _cash_words(float(c["amount"]))
		"notes":
			return "%d notes" % (int(c["amount"]) * (Data.FX["yard/fixer"] if yard_has("fixer") else 1))     # what the hand-in pays, the Fixer's double with it
		"scrap":
			return "%d scrap" % int(c["amount"])
		"salvage":
			return "%d %s" % [int(c["amount"]), str(Data.SALVAGE_NAMES.get(c["salvage"], c["salvage"])).to_lower()]
	return ""


func _unique_named(name: String) -> Dictionary:
	for u in Data.UNIQUES:
		if u["name"] == name:
			return u
	return {}


## The Fence's mate: one of the loose uniques, for notes.
## At the player's deepest tier (12 Oct, uniques by tier), one whose range takes it; the tier rides with the offer.
func roll_mate() -> Dictionary:
	var at := shop_unique_tier()
	var u: Dictionary = pick_unique(loose_uniques(deepest()), at, true)    # his deep stock opens as you go deeper
	var tier_v: int = Items.unique_tier(u, at)
	return {"unique": u["name"], "tier": tier_v, "notes": Data.MATE_NOTES * tier_v}


## The tier a shop's unique comes at (the mate, the Back room, a gamble): the loot tier of the deepest site dug.
func shop_unique_tier() -> int:
	return loot_tier_at(deepest_site_level())


## The mate's offer, rolled: at its tier (a save from before the tiers has none: its own base's).
func _mate_item() -> Dictionary:
	var u := _unique_named(mate["unique"])
	if u.is_empty():
		return {}
	return Items.roll_unique(u, rng, -1, int(mate.get("tier", -1)))


func can_buy_mate() -> bool:
	if not room_open("fence") or mission != null or mate.is_empty() or notes < int(mate["notes"]):
		return false
	var it := _mate_item()
	return not it.is_empty() and stash_fits(it)


func buy_mate() -> bool:
	if not can_buy_mate():
		return false
	notes -= int(mate["notes"])
	var it := _mate_item()
	stash.append(it)
	_read(it)
	log_event("From the Fence's mate, for %d notes: %s" % [int(mate["notes"]), it["unique"]])
	mate = roll_mate()
	return true


# ------------------------------------------------------------------ moving the Yard

func can_move_yard() -> bool:
	return campaign_done() and mission == null and not camp_lost


## The move's compounding (7 Oct): a moved yard's ladders start at this depth past the first (to LADDER_FLOOR_MAX),
## and its first `yard_moves` nodes of the Yard's tree are free.
func ladder_floor() -> int:
	return mini(yard_moves, Data.LADDER_FLOOR_MAX)


func free_yard_nodes() -> int:
	return yard_moves


## The deepest site and depth held in this yard, for the wall: [site name, depth], ["", 0] with nothing cleared.
func _deepest_held() -> Array:
	var best := -1
	var at := 0
	for i in range(Data.TIERS.size()):
		if best_depth[i] > at or (best_depth[i] == at and at > 0 and i > best):
			at = best_depth[i]
			best = i
	return [Data.TIERS[best]["name"] if best >= 0 else "", at, lv_at(best, at) if best >= 0 else 0]     # the level for the screens (18 Oct)


## The Yard's tree nodes taken, in the order they were taken.
func _yard_nodes_taken() -> Array:
	var out: Array = []
	for id in tree:
		if str(id).begins_with(Data.COMMON_TREE + "/"):
			out.append(id)
	return out


## Start again somewhere else. The uniques come, worn or stashed; the Yard's
## own tree; the runners before; half the notes; the move's own bonus.
func move_yard(trade := "") -> bool:
	if not can_move_yard() or (trade != "" and not can_trade(trade)):
		return false
	chron("move", {"trade": trade, "lorries": lorries})
	var uniques: Array = []
	for it in stash:
		if it.has("unique"):
			uniques.append(it)
	for s in Data.SLOTS:
		if equipped[s] != null and equipped[s].has("unique"):
			uniques.append(equipped[s])
	var yard_tree: Array = []
	for id in tree:
		if str(id).begins_with("The Pitch/"):
			yard_tree.append(id)
	var kept_share: float = Data.FX["yard/dry_store"] if yard_has("dry_store") else Data.MOVE_NOTES_KEPT     # the Stash's Dry store
	var keep := {"past": past, "retired": retired.duplicate(), "deeds_fate": deeds_fate, "hardcore": hardcore, "notes": int(notes * kept_share), "scrap": int(scrap * kept_share),
		"yard_picks": yard_picks.duplicate(true), "yard_ranks": yard_ranks.duplicate(), "yard_open": yard_cols(), "salvage": salvage.duplicate(),
		"yard_seen": yard_seen.duplicate(), "yard_seen_cols": yard_seen_cols, "filtered": filtered, "standing": standing.duplicate(),
		"moves": yard_moves + 1, "elapsed": elapsed, "events": events, "operators_lost": operators_lost, "trades": trades.duplicate(), "book": book.duplicate(), "heard": heard.duplicate(), "shelf": shelf.duplicate(), "shelf_tier": shelf_tier.duplicate(), "keepsakes": keepsakes.duplicate(),
		"lorries": lorries, "best_dig": best_dig.duplicate(), "held": {}, "atlas": atlas.duplicate(), "atlas_points": atlas_points,
		"signals": signals.duplicate(true), "reach": reach, "signal_seq": signal_seq, "story_beat": story_beat,
		"materials": materials.duplicate(), "key_items": key_items.duplicate(), "rebuilt": rebuilt.duplicate(), "order_beaten": order_beaten.duplicate(),
		"paragon_banked": paragon(), "chronicle": chronicle, "chron_count": chron_count, "played_s": played_s,
		"came_back": came_back.duplicate(true), "unlocked": unlocked.duplicate(), "met": met.duplicate()}     # the card's tally too: an away move mustn't wipe what came back     # the playtest record runs on through a move
	if atlas_rank("held_frequency") > 0:
		for i in range(words.size()):
			keep["held"][i] = [words[i].duplicate(true), sealed[i]]     # Held frequency: every site keeps its words through the move
	if trade != "":
		keep["trades"].append(trade)
	var fresh = get_script().new()
	fresh.start()
	load_dict(fresh.to_dict())
	past = keep["past"]
	retired = keep["retired"]             # the wall moves with the Yard (36)
	deeds_fate = keep["deeds_fate"]
	hardcore = keep["hardcore"]
	notes = keep["notes"]
	scrap = keep["scrap"]                 # scrap moves with the Yard the way notes do (34)
	yard_moves = keep["moves"]
	lorries = keep["lorries"]
	best_dig = keep["best_dig"]
	signals = keep["signals"]             # the Radio's held signals and your reach move with the Yard (15 Oct)
	reach = keep["reach"]
	signal_seq = keep["signal_seq"]
	story_beat = keep["story_beat"]
	materials = keep["materials"]         # the rebuild survives a move (18 Oct, Matt's call 1): what's built, what's held, the order's
	key_items = keep["key_items"]
	rebuilt = keep["rebuilt"]
	order_beaten = keep["order_beaten"]
	paragon_banked = keep["paragon_banked"]
	chronicle = keep["chronicle"]
	chron_count = keep["chron_count"]
	came_back = keep["came_back"]
	if not came_back.is_empty():
		came_back["lv_from"] = level()        # the new runner starts the climb again
	played_s = keep["played_s"]
	_snaps = int(played_s / SNAP_S)
	yard_picks = keep["yard_picks"]       # the buildings move with the Yard (9 Oct): picks, ranks, the columns opened, the salvage
	yard_ranks = keep["yard_ranks"]
	yard_open = keep["yard_open"]
	salvage = keep["salvage"]
	filtered = keep["filtered"]
	standing = keep["standing"]
	yard_seen = keep["yard_seen"]             # what the badge has shown moves too: a move is no news
	yard_seen_cols = keep["yard_seen_cols"]
	atlas = keep["atlas"]                 # the map is the long tail (part 4, 7 Oct): its ranks and points move with the Yard
	atlas_points = keep["atlas_points"]
	for i in keep["held"]:
		words[i] = keep["held"][i][0]
		sealed[i] = keep["held"][i][1]
	elapsed = keep["elapsed"]
	events = keep["events"]
	operators_lost = keep["operators_lost"]
	trades = keep["trades"]
	book = keep["book"]
	heard = keep["heard"]
	met = keep["met"]                     # a move doesn't introduce the rooms again
	unlocked = keep["unlocked"]           # the rooms the heads opened stay open: the Yard moves, not the town's memory (13 Oct)
	shelf = keep["shelf"]
	keepsakes = keep["keepsakes"]
	shelf_tier = keep["shelf_tier"]
	tree = yard_tree
	training_points = points_spent() + Data.MOVE_POINTS * yard_moves
	for it in uniques:
		stash.append(it)                   # whatever the new stash holds: they're the point of moving
	_yard_changed("")
	_yard_grew({"stock": Data.MARKET_STOCK, "back": false, "open": Data.CONTRACTS_OPEN})    # the new yard's shelf and contracts were rolled with nothing built
	cash = float(Data.STARTING_CASH) * inflation()    # the float, at today's prices
	log_event(Words.YARD["moved"])
	if trade != "":
		log_event(Words.YARD["trade"] % Words.mid(Data.tree_of_element(trade)["name"]))     # names as named (18 Oct)
	last_next = ""
	log_event(Words.NEXT["moved"])
	return true


# ------------------------------------------------------------------ what's next

## The first ten minutes, and every minute after: what the Yard would say to
## do next, from where the campaign stands. The log carries it when it changes.
func next_words(short := false) -> String:
	var w: Dictionary = Words.NEXT_SHORT if short else Words.NEXT
	if cls == "":
		return w["past"]
	if runs_total == 0:
		return w["first"]
	if lorry_done:
		return w["lorry"]
	if campaign_done():
		return w["done"] % convoy_depth() if "%d" in w["done"] else w["done"]
	for k in range(contracts.size()):
		if can_hand_in(k) and mission == null:
			return w["contract"]
	for z in range(Data.ZONES.size()):
		if zone_complete(z):
			continue
		if not zone_open(z):
			break
		for i in Data.ZONES[z]["tiers"]:
			if best_depth[i] <= 0:
				return w["site"] % Data.TIERS[i]["name"]
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
	for z in range(Data.ZONES.size()):
		var odds: Array = Data.WEATHER_ODDS[mini(z, Data.WEATHER_ODDS.size() - 1)]
		var r := rng.randf()
		weather[z] = "Rain" if r < float(odds[0]) else ("Fog" if r < float(odds[0]) + float(odds[1]) else "")


func weather_of(i: int) -> String:
	return str(weather[int(Data.TIERS[i]["zone"])])


## How picked over a site is, 0 to 1: full on the clear, gone RECOVER_H later.
func wear(i: int) -> float:
	if worn[i] < 0.0 or int(worn_depth[i]) != depth[i]:
		return 0.0
	return clampf(1.0 - (elapsed - worn[i]) / recover_s(), 0.0, 1.0)


## How long a picked-over site takes to come back: RECOVER_H, half again as fast a rank of Worn in.
func recover_s() -> float:
	return Data.RECOVER_H * 3600.0 / (1.0 + Data.FX["atlas/worn_in"] * atlas_rank("worn_in"))


## The item level the runner can wear now: the highest whose wear level is theirs or under (16 Oct).
func wearable_level() -> int:
	var lv := 1
	while lv < Data.MAX_LEVEL and wear_of(lv + 1) <= level():
		lv += 1
	return lv


## The runner's level an item level asks to be worn.
static func wear_of(item_level: int) -> int:
	return Items.wear_level({"slot": "Primary", "base": "", "tier": 1, "ilvl": item_level})


## A site's or a signal's finds, in the runner's terms (16 Oct, Matt: "if the bank says it drops level 6 gear then my
## expectation is that i need to be level 6"): the level to wear them, and the fifth at the runner's when that's lower.
func finds_words(item_level: int) -> Array:
	var top: int = wear_of(item_level)
	var mine: int = wear_of(mini(item_level, wearable_level()))
	if mine >= top:
		return ["level %d gear" % top, "level %d" % top]
	var pct: int = roundi(Data.FIND_AT_MINE * 100.0)
	return ["level %d gear · %d%% at level %d" % [top, pct, mine], "level %d · %d%% at level %d" % [top, pct, mine], "level %d" % top]


## The site's state, for the card: fresh, settling, or picked over and when it's back.
## The level a gamble rolls at (15 Oct, the loot read): your deepest site's, as its drops - but never past what the
## runner can wear (the review: a deep signal's level would padlock every gamble for the endgame).
func gamble_level() -> int:
	return clampi(deepest_cleared_level(), 1, maxi(1, int((level() + Data.WEAR_PER_ILVL - 1.0) / Data.WEAR_PER_ILVL)))


## A loose unique a find (15 Oct, the loot read): a trickle from the Town on, growing with the depth, capped.
func unique_odds(t: Dictionary) -> float:
	var z: int = int(Data.TIERS[int(t["tier"])]["zone"])
	var base: float = Data.UNIQUE_CAMPAIGN if z >= Data.UNIQUE_FROM_ZONE else 0.0
	return minf(Data.UNIQUE_CAP, base + Data.UNIQUE_DROP * maxi(0, int(t["depth"]) - 1))


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


func site_state(i: int) -> String:
	var w := wear(i)
	if w <= 0.0:
		return Words.SKY["fresh"]
	var back: float = recover_s() - (elapsed - float(worn[i]))
	var mins: int = int(ceil(back / 60.0))
	@warning_ignore("integer_division")
	var when := ("%dh%02d" % [mins / 60, mins % 60]) if mins >= 60 else ("%d min" % mins)
	return (Words.SKY["worn"] if w > 0.5 else Words.SKY["settling"]) % when


## The sky over a site, in words: the clock, night or day, the weather.
func sky_words(i: int, with_weather := true) -> String:
	var w := weather_of(i) if with_weather else ""
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
				log_event(Words.RADIO_LEAD + str(r["text"]))
			return


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
			log_event("%s: a code on it. The Radio has %s now." % [it["base"], taught.to_lower()])     # map juicing (9 Oct): a paper carries its code (13 Oct: codes, not words)
	if it.has("unique") and not (it["unique"] in shelf):
		shelf.append(it["unique"])
		chron("unique", {"name": str(it["unique"]), "shelf": shelf.size(), "tier": int(it.get("tier", 0))})
	if it.has("unique") and not Items.is_paper(it):
		shelf_tier[it["unique"]] = maxi(int(shelf_tier.get(it["unique"], 0)), int(it.get("tier", 0)))


## The Radio open (15 Oct): every paper held is read at once, the codes on them in one line.
func _read_held() -> void:
	var before: int = book.size()
	var held: Array = stash.duplicate()
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
		return ["The deeds", "Held, sold or burned", ""]
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
	if not stash_room(1):
		return "no room in the stash"
	return ""


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
	if it.is_empty() or not (stash_fits(it) or _stack_room(it)):
		return {}
	var cost: int = kev_price()
	notes -= cost
	stash_put(it)
	_read(it)
	chron("kev", {"price": cost, "item": _chron_item(it)})
	log_event("%s %s" % [Words.KEV_SOLD, Items.full_name(it).to_lower()])
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
	for it in stash:
		if it["id"] == id:
			return it
	return {}


## What the Bench can do to this item: the price, in cash (notes for a bump);
## -1 for can't. `stat` is the affix picked, for lock and one.
func craft_cost(it: Dictionary, kind: String, stat := "") -> int:
	if it.is_empty() or it.has("unique") or it.has("set") or Items.is_ammo(it) or Items.is_paper(it) or not Data.CRAFT.has(kind):
		return -1                             # a set piece's affixes are the set's: no bench job on one (the pass, 6 Oct)
	var has_stat := false
	for a in it["affixes"]:
		has_stat = has_stat or a["stat"] == stat
	match kind:
		"reroll", "strip":
			if it["affixes"].is_empty():
				return -1
		"lock":
			if it["affixes"].size() < 2 or not has_stat:
				return -1
		"one":
			if not has_stat:
				return -1
		"add":
			if int(it["rarity"]) >= Data.RARITIES.size() - 1 or Items.allowed_affixes(it["slot"]).size() <= it["affixes"].size():
				return -1
		"socket":
			if not (it["slot"] in Data.SOCKET_SLOTS) or Items.sockets(it) >= socket_max():
				return -1
		"bump":
			if Items.ilvl(it) >= int(it["tier"]) + bump_cap():
				return -1
			return int(Data.CRAFT[kind]["notes"]) * Items.ilvl(it)
	var price_v: int = int(Data.CRAFT[kind]["cash"]) * Items.ilvl(it) * (int(it["rarity"]) + 1)
	if kind == "one":
		for a in it["affixes"]:
			if a["stat"] == stat:
				price_v *= int(a.get("tier", 1))     # the better the tier, the dearer
	if yard_has("cheap_parts"):
		price_v = int(round(price_v * Data.FX["yard/cheap_parts"]))      # the Bench's Cheap parts
	return _inf(price_v)


func craft_in_notes(kind: String) -> bool:
	return Data.CRAFT.get(kind, {}).has("notes")


# ------------------------------------------------------------------ scrap and the Build column (34)

## What an item is worth in scrap: its value over SCRAP_PER_POUND, a stack by what it holds.
func scrap_of(it: Dictionary) -> int:
	if it.is_empty() or Items.is_deeds(it):
		return 0
	return int(float(it["value"]) / Data.SCRAP_PER_POUND) * (Data.FX["yard/strip_for_parts"] if yard_has("strip_for_parts") else 1)


## The Kit room's bin (13 Oct, Matt's playtest: the stash full with the Fence and the Workshop shut): a stash thing
## thrown out for the scrap a ditch gives, at any time, gone for good. Never the deeds (theirs is a choice of its own).
func can_bin(it: Dictionary) -> bool:
	return not it.is_empty() and not Items.is_deeds(it) and stash.has(it)


func bin(id: int) -> bool:
	for it in stash:
		if int(it["id"]) == id:
			if not can_bin(it):
				return false
			var bits: int = scrap_of(it)
			_remove(it)
			scrap += bits                     # gone for good: a binned unique isn't one of the gangs' to wear again (the review)
			chron("bin", {"item": _chron_item(it), "scrap": bits})
			log_event("Binned: %s%s" % [Items.full_name(it).to_lower() if not it.has("unique") else Items.full_name(it), (", %d scrap" % bits) if bits > 0 else ""])
			return true
	return false


## A stash item broken down at the Bench for its scrap. Gone for good.
func scrap_item(id: int) -> bool:
	if mission != null or not room_open("workshop"):
		return false
	for it in stash:
		if it["id"] == id:
			var bits: int = scrap_of(it)
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
				if int(b["tier"]) > maxi(Data.CAMPAIGN_TIER, loot_tier_at(deepest_site_level())):
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
	var ok: bool = has_from and scrap >= cost and mission == null and room
	if why == "" and not ok:
		why = "The runner is out" if mission != null else ("No room in the stash" if not room else "Short of scrap")
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
	last_craft = {"id": made["id"], "kind": "build", "words": "Built %s for %d scrap" % [name.to_lower(), int(o["scrap"])]}
	chron("build", {"name": name, "scrap": int(o["scrap"])})
	log_event("In the Workshop, for %d scrap: %s" % [int(o["scrap"]), name.to_lower()])
	_dry_memo.clear()
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
	if mission != null or not room_open("workshop"):     # shut until the Quartermaster's tool roll (13 Oct)
		return false
	var cost := craft_cost(item_by_id(id), kind, stat)
	if cost < 0:
		return false
	return notes >= cost if craft_in_notes(kind) else cash >= float(cost)


func craft(id: int, kind: String, stat := "") -> bool:
	if not can_craft(id, kind, stat):
		return false
	var it := item_by_id(id)
	var cost := craft_cost(it, kind, stat)
	var before: Array = Items.affix_lines(it, false, true)
	var sockets_before: int = Items.sockets(it)
	var level_before: int = Items.ilvl(it)
	match kind:
		"reroll":
			Items.reroll_affixes(it, rng, "", yard_has("masterwork"))
		"lock":
			Items.reroll_affixes(it, rng, stat, yard_has("masterwork"), yard_has("two_locks"))
		"one":
			if Items.reroll_one(it, stat, rng, Data.FX["yard/steady_hands"] if yard_has("steady_hands") else 1.0, yard_has("fine_tuning"), yard_has("masterwork")) == 0:
				return false
		"add":
			if not Items.add_affix(it, rng, yard_has("masterwork")):
				return false
		"socket":
			if not Items.add_socket(it, socket_max()):
				return false
		"strip":
			Items.strip_affixes(it)
		"bump":
			it["ilvl"] = mini(int(it["tier"]) + bump_cap(), Items.ilvl(it) + bump_levels())
	# what the Bench did, in words the player can check against the piece
	var words_v := _craft_words(it, kind, stat, before, sockets_before, level_before)
	last_craft = {"id": id, "kind": kind, "words": words_v}
	chron("craft", {"kind": kind, "stat": stat, "cost": cost, "item": _chron_item(it), "worn": not stash.has(it)})
	if not stash.has(it):
		_surv_cache = {}                       # a job on worn kit (the Workshop, 9 Oct): the odds read it again, the id is the same
		_dry_memo.clear()
	if craft_in_notes(kind):
		notes -= cost
		log_event("In the Workshop, for %d notes, %s: %s" % [cost, it["base"].to_lower(), words_v])
	else:
		cash -= float(cost)
		log_event("In the Workshop, for %s, %s: %s" % [_cash_words(float(cost)), it["base"].to_lower(), words_v])
	return true


## "Added +12% damage · T2", "Re-rolled: +4% damage · T1, +2 HP/s · T1 → ...".
func _craft_words(it: Dictionary, kind: String, stat: String, before: Array, _sockets_before: int, level_before: int) -> String:
	var after: Array = Items.affix_lines(it, false, true)
	match kind:
		"add":
			for line in after:
				if not (line in before):
					return "Added %s" % line
			return "Added an affix"
		"reroll":
			return "Re-rolled: %s → %s" % [", ".join(before), ", ".join(after)]
		"lock":
			var kept := ""
			for line in after:
				if line in before and line.contains(str(Items.affix_def(stat).get("label", stat))):
					kept = line
			var rest_before := before.filter(func(l): return l != kept)
			var rest_after := after.filter(func(l): return l != kept)
			return "Kept %s; re-rolled the rest: %s → %s" % [kept, ", ".join(rest_before), ", ".join(rest_after)]
		"one":
			var was := ""
			var now := ""
			for line in before:
				if not (line in after):
					was = line
			for line in after:
				if not (line in before):
					now = line
			return "%s → %s" % [was, now] if was != "" and now != "" else "Re-rolled one: no change"
		"socket":
			return "A socket cut: %d now" % Items.sockets(it)
		"strip":
			return "Stripped: %s gone" % ", ".join(before)
		"bump":
			return "Item level %d → %d: nothing under T%d rolls" % [level_before, Items.ilvl(it), mini(Items.tier_floor(Items.ilvl(it)), Items.rarity_cap(it))]
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
	if mission != null or atlas_free() < 1:
		return false
	for a in Data.ATLAS:
		if a["key"] == key:
			return atlas_rank(key) < int(a["max"]) and atlas_open(key)
	return false


## The map as lanes (9 Oct): a node's column in its lane is its place there, two to a column; the column opens
## on the points spent in that lane (Data.ATLAS_GATES), like the trees.
func atlas_open(key: String) -> bool:
	var col := atlas_col(key)
	if col < 0:
		return false
	return atlas_in_lane(int(Data.atlas_of(key)["column"])) >= int(Data.ATLAS_GATES[mini(col, Data.ATLAS_GATES.size() - 1)])


func atlas_col(key: String) -> int:
	var lane: int = int(Data.atlas_of(key).get("column", -1))
	var k := 0
	for a in Data.ATLAS:
		if int(a["column"]) != lane:
			continue
		if a["key"] == key:
			@warning_ignore("integer_division")
			return k / 2
		k += 1
	return -1


func atlas_in_lane(lane: int) -> int:
	var n := 0
	for a in Data.ATLAS:
		if int(a["column"]) == lane:
			n += atlas_rank(a["key"])
	return n


func rank_atlas(key: String) -> bool:
	if not can_rank_atlas(key):
		return false
	atlas[key] = atlas_rank(key) + 1
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
	candidates = []
	log_event("The one who stays is %s. The other moved on.%s" % [Data.TRAIT_WORDS.get(runner_trait, runner_trait.to_lower()), (" " + Words.TRAITS[runner_trait]) if Words.TRAITS.has(runner_trait) else ""])     # the trait's line (12 Oct): said of the one who stays
	return true


## The second past: a different class, from level ASCEND_LEVEL, for its first tree.
## Training's 15 Oct gates (the core's points, the keystones' and capstones' levels, the second past's 20) on; only the
## smoke's mechanics areas turn them off, to test a joint or a keystone without the build behind it. Not saved.
var core_gates := true


func can_ascend() -> bool:
	return ascend_block() == "" and mission == null


## Why the second past can't be taken yet, or "": the level, then the points in the first class tree (15 Oct).
func ascend_block() -> String:
	if cls == "":
		return "no past yet"
	if level() < Data.ASCEND_LEVEL:
		return "at level %d" % Data.ASCEND_LEVEL
	var first: String = first_tree()
	if core_gates and points_in(first) < Data.ASCEND_CORE:
		return "at %d in %s (%d now)" % [Data.ASCEND_CORE, first, points_in(first)]
	return ""


## The runner's first class tree, by name ("Muscle"), or "".
func first_tree() -> String:
	var ts: Array = Data.trees_for(cls)
	return str(ts[0]["name"]) if not ts.is_empty() and ts[0].get("class", "") == cls else ""


## An element tree's core (15 Oct): the class tree its joint is in for this runner, on show - the most-trained, with a second
## past's - or the first class tree off the pair. "" for a tree that isn't an element's.
func core_tree(tree_name: String) -> String:
	if not Data.tree_named(tree_name).has("element"):
		return ""
	var best := ""
	for c in my_classes():
		var j: Dictionary = Data.joint_in(c, tree_name)
		if not j.is_empty() and _on_show(str(j["tree"])) and (best == "" or points_in(str(j["tree"])) > points_in(best)):     # a second past's other tree isn't one it has
			best = str(j["tree"])
	return best if best != "" else first_tree()


## The points in the core an element tree's node wants (CORE_GATES, CORE_CAPSTONE), 0 for none.
static func core_need(t: Dictionary, nd: Dictionary) -> int:
	if not t.has("element"):
		return 0
	if nd.get("capstone", false):
		return Data.CORE_CAPSTONE
	var need := 0
	for g in Data.CORE_GATES:
		if int(nd.get("col", 0)) >= int(g[0]):
			need = int(g[1])
	return need


func set_second(name: String) -> bool:
	if not can_ascend() or name == cls or name == cls2:
		return false
	_dry_memo.clear()
	for c in Data.CLASSES:
		if c["name"] == name:
			cls2 = name
			chron("ascend", {"second": name})
			var kept := []
			for id in tree:
				if _on_show(str(id).get_slice("/", 0)):
					kept.append(id)
			tree = kept
			log_event("The runner was a %s too, once" % name)
			return true
	return false


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


## A trained node counts unless it's typed for a gun that isn't in hand ("type" is one gun type, or a
## list of them), or it's the top of an element tree - column 5 or 6 - with no closed joint there: a class
## change reopened it, so it stays trained and does nothing until a joint there closes again (9 Oct).
## `_active` reads the type alone; `node_active` (by id) reads both - the screen's and the tests'.
func _active(n: Dictionary) -> bool:
	if not n.has("type"):
		return true
	var ty = n["type"]
	return (gun_type() in ty) if ty is Array else ty == gun_type()


func node_active(id: String) -> bool:
	var n := node(id)
	if n.is_empty() or not _active(n):
		return false
	var tname: String = id.get_slice("/", 0)
	return not (not Data.element_tree(tname).is_empty() and int(n.get("col", 0)) >= Data.ELEMENT_GATED_COL and not _tops_open(tname))


func has_node(effect: String) -> bool:
	for e in _nodes_for(effect):
		if _active(e[0]) and (e[2] == "" or _tops_open(e[2])):
			return true
	return false


## The small nodes' numbers for an effect, added up: a node's own value, or its "also" figure for a second effect.
func tree_sum(effect: String) -> float:
	var t := 0.0
	for e in _nodes_for(effect):
		if _active(e[0]) and (e[2] == "" or _tops_open(e[2])):
			t += float(e[1])
	return t


## The trained nodes by effect - [node, its figure for that effect, the element tree it waits on or ""], a node
## under its "also" effects too - built once per shape of the tree and the runner's classes: the fight asks for
## effects every tick. The joints closed and the element tops open are worked out with it.
var _eff_cache := {}
var _eff_hash := 0
var _closed := {}                  # joint key -> true, closed
var _open_tops := {}               # element tree name -> true: its columns 5 and 6 work (a joint closed there, or a trade)
func _nodes_for(effect: String) -> Array:
	var cap: bool = has_rule("headmasters_cap")
	var h := hash([tree, cls, cls2, trades, cap])
	if h != _eff_hash or _eff_cache.is_empty():
		_eff_cache = {"": []}
		_closed = {}
		_open_tops = {}
		for j in Data.JOINTS:
			if (j["class"] == cls or j["class"] == cls2) and _half_trained(j, j["tree"]) and _half_trained(j, j["element_tree"]):
				_closed[j["key"]] = true
				_open_tops[j["element_tree"]] = true
		for el in trades:
			var et := Data.tree_of_element(el)
			if not et.is_empty():
				_open_tops[et["name"]] = true
		var ids: Array = tree.duplicate()
		if cap:
			for ct in Data.trees_for(cls, cls2):      # the Headmaster's Cap (a mythic): every node of the class's trees -
				if str(ct.get("class", "")) == "":
					continue                          # the class's own, not the Yard's
				for i in range(ct.get("nodes", []).size()):
					var cid := "%s/%d" % [ct["name"], i]
					if not (cid in ids) and not ct["nodes"][i].get("keystone", false):
						ids.append(cid)               # but its keystones, whose costs are the point (the review: Hit and run, Never there)
		for id in ids:
			var n := node(id)
			if n.is_empty():
				continue
			var tname: String = str(id).get_slice("/", 0)
			var waits: String = tname if (not Data.element_tree(tname).is_empty() and int(n.get("col", 0)) >= Data.ELEMENT_GATED_COL) else ""
			var e: String = n.get("effect", "")
			if not _eff_cache.has(e):
				_eff_cache[e] = []
			_eff_cache[e].append([n, n.get("value", 0), waits])
			for k in n.get("also", {}):
				if not _eff_cache.has(k):
					_eff_cache[k] = []
				_eff_cache[k].append([n, n["also"][k], waits])
		_eff_hash = h
	return _eff_cache.get(effect, [])


## Whether a joint's half in a tree is trained: the node in that tree carrying the joint's key.
func _half_trained(j: Dictionary, tree_name: String) -> bool:
	var t := Data.tree_named(tree_name)
	for i in range(t.get("nodes", []).size()):
		if str(t["nodes"][i].get("joint", "")) == j["key"] and tree.has("%s/%d" % [tree_name, i]):
			return true
	return false


## A joint closed: both halves trained by a runner of its class (or a second past of it).
func has_joint(key: String) -> bool:
	_nodes_for("")
	return _closed.has(key)


## An element tree's top columns open: a joint closed there, the Yard's trade of its element, or the
## Quartermaster's Manual ("every keystone open").
func _tops_open(tree_name: String) -> bool:
	_nodes_for("")
	return _open_tops.has(tree_name) or has_rule("qm_manual") or has_rule("last_orders") or has_rule("headmasters_cap")


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
func _memo(key: String, f: Callable) -> Variant:
	if _trying or not (_dry_on or (fast_memo and mission != null)):     # a try-on reads the kit it's trying, never a memo
		return f.call()
	if _dry_memo.has(key):
		return _dry_memo[key]
	var v = f.call()
	_dry_memo[key] = v
	return v
func _snapshot_rules() -> Dictionary:
	var out := {}
	for s in Data.SLOTS:
		if equipped[s] != null and equipped[s].get("rule", "") != "":
			out[equipped[s]["rule"]] = true
	for it in stash:
		if Items.is_paper(it) and it.get("rule", "") != "":
			out[it["rule"]] = true
	return out


func node_cost(id: String) -> int:
	var parts := id.split("/")
	if parts[0] == Data.COMMON_TREE:
		# a move's free node: the first free_yard_nodes() of the Yard's tree cost nothing (7 Oct)
		var taken := _yard_nodes_taken()
		var k: int = taken.find(id)
		if (k >= 0 and k < free_yard_nodes()) or (k < 0 and taken.size() < free_yard_nodes()):
			return 0
	var n := node(id)
	var cost := Data.base_cost(Data.tree_named(parts[0]), n)
	var t := Data.element_tree(parts[0])
	if not t.is_empty() and not affinity(t["element"]):
		cost *= Data.OFF_AFFINITY_COST       # off the class's pair: double
	return cost


func points_spent() -> int:
	var n := 0
	for id in tree:
		n += node_cost(id)
	return n


func points_free() -> int:
	return training_points - points_spent()


## The classes whose halves this runner can train: theirs and the second past's.
func my_classes() -> Array:
	var out: Array = []
	for c in [cls, cls2]:
		if c != "":
			out.append(c)
	return out


## What's been spent in a tree, at the tree's own prices: what its gates count.
func points_in(tree_name: String) -> int:
	var t := Data.tree_named(tree_name)
	var n := 0
	for id in tree:
		if str(id).get_slice("/", 0) == tree_name:
			n += Data.base_cost(t, node(id))
	return n


## Why a node can't be trained now, in words, or "" when it can (the Training screen's line, the tests').
## `ignore_points`: everything but the points free - the screen draws a node it could reach with more points as open.
func train_block(id: String, ignore_points := false) -> String:
	if tree.has(id):
		return "trained"
	var n := node(id)
	if n.is_empty():
		return "no such node"
	var parts := id.split("/")
	if not _on_show(parts[0]):
		return "not one of this runner's trees"
	if not Data.for_classes(n, my_classes()):
		return "%s only" % n["class"]
	var t := Data.tree_named(parts[0])
	var col: int = int(n.get("col", 0))
	var g: int = Data.gate(t, col, my_classes())
	if points_in(parts[0]) < g:
		return "opens at %d points in %s (%d now)" % [g, parts[0], points_in(parts[0])]
	var need: int = core_need(t, n) if core_gates else 0
	var core: String = core_tree(parts[0]) if need > 0 else ""
	if core != "" and points_in(core) < need:
		return "opens at %d points in %s (%d now)" % [need, core, points_in(core)]     # the core first (15 Oct)
	if core_gates and n.get("keystone", false) and level() < Data.KEYSTONE_LEVEL:
		return "opens at level %d" % Data.KEYSTONE_LEVEL
	if core_gates and n.get("capstone", false) and level() < Data.CAPSTONE_LEVEL:
		return "opens at level %d" % Data.CAPSTONE_LEVEL
	if t.has("element") and col >= Data.ELEMENT_GATED_COL and not _tops_open(parts[0]):
		return "wants a joint joined in %s" % parts[0]
	if n.get("capstone", false):
		# the capstone wants the tree's shape behind it: the keystone and every notable this runner can train
		for k in range(t["nodes"].size()):
			var nd: Dictionary = t["nodes"][k]
			if (nd.get("keystone", false) or nd.get("notable", false)) and not nd.get("beside", false) and Data.for_classes(nd, my_classes()) and not tree.has("%s/%d" % [parts[0], k]):
				return "wants the keystone and every notable first"
	if not ignore_points and points_free() < node_cost(id):
		return "wants %d point%s" % [node_cost(id), "" if node_cost(id) == 1 else "s"]
	return ""


## A node can be trained: its column open in its tree, a point free for it, and for an element tree's top
## a closed joint there; a class's half is that class's alone.
func can_train(id: String) -> bool:
	return train_block(id) == ""


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
	else:
		tree.append(id)
	_dry_memo = {}
	var other: float = float(damage_split()["total"])
	tree = keep
	_dry_memo = kept_memo
	var with_it: float = now if had else other
	var without: float = other if had else now
	var add: float = with_it - without
	return [add, add / without if without > 0.0 else 0.0]


func train_node(id: String) -> bool:
	if not can_train(id):
		return false
	_dry_memo.clear()                     # the memos read the tree (A4's review)
	var nd: Dictionary = node(id)
	var paid: int = node_cost(id)
	tree.append(id)
	log_event("Trained: %s" % nd["name"])
	chron("train", {"id": id, "name": str(nd["name"]), "tree": id.get_slice("/", 0), "col": int(nd.get("col", 0)), "cost": paid,
		"keystone": bool(nd.get("keystone", false)), "capstone": bool(nd.get("capstone", false)), "notable": bool(nd.get("notable", false)),
		"joint": str(nd.get("joint", "")), "free": training_points - points_spent()})
	return true


func _on_show(branch: String) -> bool:
	for t in trees():
		if t["name"] == branch:
			return true
	return false


func respec_cost() -> int:
	return _inf(points_spent() * Data.RESPEC_CASH)


func respec() -> bool:
	if tree.is_empty() or cash < respec_cost():
		return false
	_dry_memo.clear()
	var paid := respec_cost()
	cash -= paid
	chron("respec", {"cost": paid, "points": points_spent()})
	tree = []
	log_event("Training reset: the points are free to spend again")
	return true


## Levels earn points for the camp, whatever happens to the operator - but only past the camp's best
## (9 Oct): dying and re-levelling a new runner earned the same points again, without end.
func _earn_points(before: int) -> void:
	var after := level()
	if after > best_level:
		var gained: int = after - maxi(before, best_level)
		best_level = after
		training_points += gained
		log_event("Level %d: %d training point%s" % [after, gained, "" if gained == 1 else "s"])
		chron("level", {"to": after, "gained": gained, "best": true})
	elif after > before:
		log_event("Level %d: no training point – the Pitch has had a runner at level %d" % [after, best_level])
		chron("level", {"to": after, "gained": 0, "best": false})


func contact(t: Dictionary) -> int:
	if has_node("one_at_a_time"):
		return 1
	if has_rule("gritters_hopper") and mission != null and float(mission.get("chill_t", 0.0)) > 0.0:
		return 1                                 # chilled gangs come one at a time
	return maxi(1, (Data.FX["node/overwatch"] if has_node("overwatch") else CONTACT) + int(t.get("contact", 0)) + int(class_data().get("contact", 0)) + (Data.FX["rule/sergeants_whistle.contact"] if has_rule("sergeants_whistle") else 0) - (Data.FX["set/army.contact"] if has_set_rule("army") else 0))


## Seconds a search takes: the intel's multiple, cut by Fieldcraft's search nodes.
func search_s(t: Dictionary) -> float:
	return SEARCH_S * (Data.FX["rule/miners_lamp"] if has_rule("miners_lamp") else 1.0) * float(t.get("search", 1.0)) * maxf(0.4, 1.0 - (tree_sum("search_pct") + _affix_sum("search_pct")) / 100.0) * cm("search") * (Data.FX["node/never_there.search"] if has_node("never_there") else 1.0) * trait_mult("search") \
		* (1.0 - Data.FX["atlas/deeper_pockets"] * atlas_rank("deeper_pockets")) * (Data.FX["yard/second_dog"] if yard_has("second_dog") else 1.0)


## Seconds to the next lot. The first lot waits for the lookout too; "never
## there" means none ever comes.
func patrol_s(t: Dictionary, first := false) -> float:
	if has_node("never_there"):
		return INF
	var base := (Data.FX["node/quiet_feet"] if has_node("quiet_feet") else PATROL_S) * float(t.get("patrol", 1.0)) * cm("patrol")
	base *= 1.0 + (_fitted_sum("patrol_pct") + tree_sum("patrol_pct") + _affix_sum("patrol_pct")) / 100.0
	base *= yard_patrol()
	if first:
		base *= (1.0 + (Data.FX["yard/spotter"] if yard_has("spotter") else 0.0) + (Data.FX["yard/lookout_post"] if yard_has("lookout_post") else 0.0)) * (Data.FX["node/early_doors"] if has_node("early_doors") else 1.0)
	if has_node("loud"):
		base *= Data.FX["node/loud.patrol"]
	return base * trait_mult("patrol") * (1.0 + Data.FX["atlas/quiet_roads"] * atlas_rank("quiet_roads")) * (Data.FX["rule/lollipop"] if has_rule("lollipop") else 1.0)


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
		* (Data.FX["rule/van_keys"] if has_rule("van_keys") else 1.0) * (Data.FX["node/frost_more.pace"] if has_node("frost_more") else 1.0) * (Data.FX["node/physical_more.pace"] if has_node("physical_more") else 1.0) * (Data.FX["rule/the_float.pace"] if has_rule("the_float") else 1.0) * wound_mult("pace")


# ------------------------------------------------------------------ ammo

## The rounds in the rig for a gun's type, every stack counted (feed_stack says which fires).
func rounds_for(gun: Dictionary) -> int:
	var n := 0
	var t := Items.ammo_type(gun)
	for it in rig:
		if Items.is_ammo(it) and Items.base_of(it)["type"] == t:
			n += int(it["rounds"])
	return n


func has_rounds(gun: Dictionary) -> bool:
	if _trying:
		# a try-on weighs a gun fed when its rounds are a trip to the rig: in the stash or the rig, or at the Fence to buy
		# (13 Oct, the ammo trap: with the Fence shut, Equip if better swapped the nail gun for a rifle nobody had rounds
		# for, and the runner fought with their fists)
		var type: String = Items.ammo_type(gun)
		if type in ["", "none"] or Items.free_rounds(gun) or room_open("fence"):
			return true
		return rounds_for(gun) > 0 or stash.any(func(x): return Items.is_ammo(x) and Items.base_of(x)["type"] == type)
	if Items.ammo_type(gun) == "none" or Items.free_rounds(gun):
		return true                          # a bat never runs dry; the burner takes nothing
	return Items.ammo_type(gun) != "" and rounds_for(gun) > 0


## A melee primary: in among them.
func melee() -> bool:
	return equipped["Primary"] != null and Items.is_melee(equipped["Primary"])


## The better grade's damage, from the stack that's feeding the gun now.
func grade_bonus(gun: Dictionary) -> float:
	return grade_stat(gun, "damage_pct")


## What the grade in the gun's live stack carries for a stat: its damage, a share as an element (33), a first-shot weight.
func grade_stat(gun, stat: String) -> float:
	if gun == null:
		return 0.0                       # no gun in hand: untyped on purpose, a typed parameter would refuse the null
	var stack := feed_stack(gun)
	return float(Items.base_of(stack).get(stat, 0)) if not stack.is_empty() else 0.0


## The stack a gun fires from (11 Oct, Matt: Depot rounds put in the rig did nothing, the first stack of the type
## fed whatever was better): the best grade of its type with rounds left. A grade carrying an element the runner
## has trained into (a node in that element's tree) comes first - a fire build fires its incendiaries before Depot
## (Matt, the same day) - then by the grade's worth (Rifle 40, Match 100, Salted 150, Depot 170), the first in the
## rig on a tie. {} when it's dry.
func feed_stack(gun: Dictionary) -> Dictionary:
	var t := Items.ammo_type(gun)
	# the element only counts for the primary: a secondary's grade is damage only (the conversion reads the primary's)
	var els: Array = build_elements() if is_same(gun, equipped["Primary"]) else []
	var best := {}
	var bv := -1
	for it in rig:
		if Items.is_ammo(it) and Items.base_of(it)["type"] == t and int(it["rounds"]) > 0:
			var b: Dictionary = Items.base_of(it)
			var v: int = int(b.get("value", 0))
			for e in els:
				if float(b.get("conv_%s_pct" % e, 0)) > 0.0:
					v += 100000                  # the build's own element before any worth
			if v > bv:
				best = it
				bv = v
	return best


## The elements the runner is built for: each element whose tree has a node trained. Read again when the tree changes
## (a hash of the node list, as the trees' own lookups key theirs every tick).
var _els_key := -1
var _els: Array = []
func build_elements() -> Array:
	var k: int = hash(tree)              # the nodes themselves: a respec retrained to the same count is another build (the review)
	if k != _els_key:
		_els_key = k
		_els = []
		for et in Data.ELEMENT_TREES:
			for id in tree:
				if str(id).begins_with(str(et["name"]) + "/"):
					_els.append(et["element"])
					break
	return _els


## Rounds fired this tick come off the first stack of the type; an empty
## stack is dropped, and a gun that's just run dry says so.
func _spend_rounds(gun: Dictionary, shots: float) -> void:
	var t := Items.ammo_type(gun)
	if t == "none" or Items.free_rounds(gun):
		return
	var m: Dictionary = mission
	m["fired"] = m.get("fired", {})
	m["fired"][t] = float(m["fired"].get(t, 0.0)) + shots
	while m["fired"][t] >= 1.0:
		var stack := feed_stack(gun)       # the best grade first, as the damage reads it
		if stack.is_empty():
			m["fired"][t] = 0.0
			return
		# the tick's rounds off the one stack at once (A4: a scan of the rig a round was a quarter of a dry run's tick);
		# the feed only changes when a stack runs out
		var n: int = mini(int(m["fired"][t]), int(stack["rounds"]))
		stack["rounds"] = int(stack["rounds"]) - n
		m["fired"][t] -= float(n)
		if int(stack["rounds"]) <= 0:
			rig.erase(stack)
			_dry_memo.erase("conversion")   # the grade's share goes with the stack (33), in a dry run too
			if rounds_for(gun) <= 0:
				log_event("%s: out of rounds" % gun["base"])
				m["ran_dry"] = str(gun["base"])     # for the out-of-time line (16 Oct)


## The Fence sells standard boxes of every type without end: a box a type.
func ammo_box(type: String) -> Dictionary:
	for b in Data.BASES[Data.AMMO]:
		if b["type"] == type and not b.has("damage_pct"):
			return b
	return {}


func ammo_price(type: String) -> int:
	var b := ammo_box(type)
	return _inf(b["value"] * Data.AMMO_PRICE) if not b.is_empty() else 0


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
		if Items.is_medical(it):
			return it
	return {}


func meds_carried() -> int:
	if has_rule("the_float"):
		return 0
	var n := 0
	for it in rig:
		if Items.is_medical(it):
			n += 1
	return n


## Walking fire: the primary's `sustain` [a second, cap] as the stream's multiplier after `sustain_t` seconds on one gang.
func sustain_mult(m: Dictionary) -> float:
	var gun = equipped["Primary"]
	if gun == null or not Items.base_of(gun).has("sustain"):
		return 1.0
	var su: Array = Items.base_of(gun)["sustain"]
	return 1.0 + minf(float(su[1]), float(su[0]) * float(m.get("sustain_t", 0.0))) / 100.0


## A unique's rule, by its flag, when one is worn.
func has_rule(rule: String) -> bool:
	if _dry_on:
		return _dry_rules.has(rule)
	for s in Data.SLOTS:
		if equipped[s] != null and equipped[s].get("rule", "") == rule:
			return true
	for it in stash:
		if Items.is_paper(it) and it.get("rule", "") == rule:
			return true                          # a paper with a rule counts from the stash
	return false


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
		out.append({"name": u["name"], "found": u["name"] in shelf, "where": Words.SHELF["own_gap"] % [Data.TIERS[i]["name"], site_unique_level(i)]})
	for u in Data.UNIQUES:
		if u.has("pinnacle"):
			for b in Data.BOSSES:
				if int(b["zone"]) == int(u["pinnacle"]):
					out.append({"name": u["name"], "found": u["name"] in shelf, "where": Words.SHELF["head_gap"] % [b["name"], lv_at(int(b["tier"]), pinnacle_depth(int(b["tier"])))]})
	out.append({"name": Data.CONVOY_UNIQUE, "found": Data.CONVOY_UNIQUE in shelf, "where": Words.SHELF["lorry_gap"]})     # the depot's, Kev's last beat (15 Oct)
	for p in Data.PINNACLES:
		out.append({"name": p["unique"], "found": p["unique"] in shelf, "where": Words.SHELF["order_gap"] % [p["who"], Words.mid(str(p["place"]))]})     # the order's (18 Oct)
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
	return (float(Items.base_of(equipped[Data.CHARM]).get("find", 0)) if equipped[Data.CHARM] != null else 0.0) + _affix_sum("rarity_pct")


func charm_cash() -> float:
	return (float(Items.base_of(equipped[Data.CHARM]).get("cash", 0)) if equipped[Data.CHARM] != null else 0.0) + _affix_sum("cash_pct") + _fitted_sum("wire_pct") + Data.MOVE_CASH * yard_moves


# ------------------------------------------------------------------ the stash

func stash_cap() -> int:
	return Data.STASH_CELLS + (Data.FX["yard/shelving"] if yard_has("shelving") else 0) + (Data.FX["yard/another_unit"] if yard_has("another_unit") else 0) + (Data.FX["yard/lock_up"] if yard_has("lock_up") else 0) \
		+ (Data.FX["yard/annex"] if yard_has("annex") else 0) + Data.FX["yard_rank/stash"] * yard_rank("stash")


## Whether a stash item takes no cells: the Stash's Racks (rounds, meds, grenades), Wall of fame (uniques and set
## pieces), Paper rack (papers and charms).
func stash_free(it: Dictionary) -> bool:
	if yard_has("racks") and (Items.is_ammo(it) or Items.is_medical(it) or Items.is_grenade(it)):
		return true
	if yard_has("wall_of_fame") and (it.has("unique") or it.has("set")):
		return true
	return yard_has("paper_rack") and (Items.is_paper(it) or it["slot"] == Data.CHARM)


## Cells in use.
func stash_used() -> int:
	var n := 0
	for it in stash:
		if not stash_free(it):
			n += Items.size(it)
	return n


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


# ------------------------------------------------------------------ the camp's upgrades

func rest_rate() -> float:
	var base: float = Data.REST_BASE + (Data.FX["yard/beds"] if yard_has("beds") else 0.0) + (Data.FX["yard/ward"] if yard_has("ward") else 0.0)
	return base * (Data.FX["node/second_wind"] if has_node("second_wind") else 1.0) * (1.0 + tree_sum("rest_pct") / 100.0) * (1.0 + town_stat("rest_pct") / 100.0)     # the pumping station (18 Oct)


## The Clinic's shelf and the Fence's, by the Yard's picks.
func clinic_stock() -> int:
	return Data.CLINIC_STOCK + (Data.FX["yard/shelf"] if yard_has("shelf") else 0) + (Data.FX["yard/stockroom"] if yard_has("stockroom") else 0)


func market_stock() -> int:
	return Data.MARKET_STOCK + (Data.FX["yard/stall"] if yard_has("stall") else 0) + (Data.FX["yard/shopfront"] if yard_has("shopfront") else 0) + int(floor(town_stat("shelf")))     # the market hall (18 Oct)


## Cash in, counted: the sinks are priced off what the Yard takes a run.
func _earn(x: float) -> void:
	if away_on and x > 0.0:
		x *= 1.0 + (Data.FX["yard/overtime.away"] if yard_has("overtime") else 0.0) + Data.FX["yard_rank/generator"] * yard_rank("generator")     # the Generator's Overtime and rank: cash made while you're away
	cash += x
	_takings_run += x
	cash_in += x


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
	return campaign_done() and tier_open(i) and int(depth[i]) >= int(Data.WORD_TIER_DEPTH[0])


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
		n = maxi(n, _sig["codes"].size())     # a signal's papers' codes, every one (15 Oct)
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
		if int(best_depth[i]) >= int(Data.WORD_TIER_DEPTH[0]):     # depth 2 anywhere is a signal won there: the same on every site
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
	var boost: float = (Data.FX["yard/military_band"] if yard_has("military_band") else 0.0) + Data.FX["yard_rank/radio"] * yard_rank("radio") + Data.FX["atlas/booster"] * atlas_rank("booster")
	for side in ["bite", "pay"]:
		var part: Dictionary = w[side]
		for k in part:
			var v = part[k]
			if k in WORD_MULT_KEYS:
				var x: float = pow(float(v), pw)
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


## A site's totals, the way a PoE map shows them: what you get and what they bring, multiplied through.
func word_totals(i: int) -> Dictionary:
	var gets := {"drop": 1.0, "rarity": 0.0, "cash": 1.0, "xp": 1.0, "loot_tier": 0}
	var bring := {"hp": 1.0, "dps": 1.0, "pool": 1.0, "patrol": 1.0, "pace": 1.0, "search": 1.0, "armour": 1.0, "contact": 0, "flags": [], "res": {}, "types": {}}
	for aw in active_words(i):
		var e := word_effect(aw[0], aw[1])
		for k in ["drop", "cash", "xp"]:
			gets[k] *= float(e.get(k, 1.0))
		gets["rarity"] += float(e.get("rarity", 0.0))
		gets["loot_tier"] += int(e.get("loot_tier", 0))
		for k in ["hp", "dps", "pool", "patrol", "pace", "search", "armour"]:
			bring[k] *= float(e.get(k, 1.0))
		if e.has("res"):
			bring["res"][e["res"]] = float(bring["res"].get(e["res"], 0.0)) + float(e.get("res_add", 0.0))
		if e.has("type"):
			bring["types"][e["type"]] = float(bring["types"].get(e["type"], 0.0)) + float(e.get("share", 0.0))
		bring["contact"] += int(e.get("contact", 0))
		bring["soaked"] = float(bring.get("soaked", 0.0)) + float(e.get("soaked", 0.0))
		for f in ["no_meds", "no_kill_cash", "clock_half", "boss_walks"]:
			if e.has(f):
				bring["flags"].append(f)
	return {"get": gets, "bring": bring}


## The totals as lines: ["Finds +64% · quality +40%", "HP +70% · fire +30%"]; "" for a side with nothing.
func word_total_words(i: int) -> Array:
	var tt := word_totals(i)
	var g: Dictionary = tt["get"]
	var b: Dictionary = tt["bring"]
	var gw: Array = []
	var pc := func(x: float) -> String: return "%d%%" % int(round(absf(x - 1.0) * 100.0))
	if g["drop"] > 1.005:
		gw.append("finds +" + pc.call(g["drop"]))
	if g["rarity"] > 0.005:
		gw.append("loot quality +%d%%" % int(round(g["rarity"] * 100.0)))
	if g["cash"] > 1.005:
		gw.append("tins +" + pc.call(g["cash"]))
	if g["xp"] > 1.005:
		gw.append("XP +" + pc.call(g["xp"]))
	if g["loot_tier"] > 0:
		gw.append("loot +%d tier%s" % [g["loot_tier"], "" if g["loot_tier"] == 1 else "s"])
	var bw: Array = []
	if b["hp"] > 1.005:
		bw.append("HP +" + pc.call(b["hp"]))
	if b["dps"] > 1.005:
		bw.append("fire +" + pc.call(b["dps"]))
	if b["pool"] > 1.005:
		bw.append("gang size +" + pc.call(b["pool"]))
	if b["patrol"] < 0.995:
		bw.append("gangs %s sooner" % pc.call(b["patrol"]))
	if b["pace"] < 0.995:
		bw.append("pace −" + pc.call(b["pace"]))
	if b["search"] > 1.005:
		bw.append("searches %s slower" % pc.call(b["search"]))
	if b["armour"] < 0.995:
		bw.append("your armour −" + pc.call(b["armour"]))
	if b["contact"] > 0:
		bw.append("+%d on you" % b["contact"])
	for ty in b["types"]:
		bw.append("%d%% %s" % [int(round(float(b["types"][ty]) * 100.0)), ty])
	for ty in b["res"]:
		bw.append("%s resist %d%%" % [ty, int(round(float(b["res"][ty]) * 100.0))])
	if float(b.get("soaked", 0.0)) > 0.005:
		bw.append("your resist −%d%%" % int(round(float(b["soaked"]) * 100.0)))
	for f in b["flags"]:
		bw.append({"no_meds": "no meds", "no_kill_cash": "no kill tins", "clock_half": "half the clock", "boss_walks": "the head, free"}[f])
	return [" · ".join(gw), " · ".join(bw)]


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
	v *= (1.0 - Data.FX["atlas/good_reception"] * atlas_rank("good_reception")) * (Data.FX["yard/scanner"] if yard_has("scanner") else 1.0)
	if key == "call":
		v *= 1.0 - Data.FX["atlas/early_word"] * atlas_rank("early_word")
	if key == "clear" and sealed[i]:
		v *= Data.SEALED_CLEAR
	return maxi(1, int(ceil(v)))


## Why a craft can't be done now ("" if it can).
func word_craft_block(i: int, key: String) -> String:
	if not room_open("radio"):
		return "The Radio isn't on the air yet"     # until the Quartermaster's set (13 Oct)
	if mission != null:
		return "The runner is out"
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
	log_event("%s on %s: %s" % [c["name"], Words.mid(tier(i)["name"]), ", ".join(word_names(i)).to_lower() if not words[i].is_empty() else "silent"])
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
			log_event("Twisted: %s goes to tier IV" % str(words[i][k]["w"]).to_lower())
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
				log_event("Twisted: %s comes on the air" % str(wd["w"]).to_lower())
		2:
			log_event("Twisted: nothing changes")
		3:
			var cap := maxi(1, word_tier_cap(site_depth(i)))
			var n: int = words[i].size()
			words[i] = _roll_words(i, [], n)
			for wd in words[i]:
				wd["t"] = cap
			log_event("Twisted: every code again, at tier %s" % Data.WORD_TIER_NAMES[cap - 1])
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
				if sd == "a" or sd == "b":
					_yard_set[b["picks"][c][0 if sd == "a" else 1]["id"]] = true
		_yard_dirty = false
	return _yard_set.has(id)


func yard_rank(key: String) -> int:
	return int(yard_ranks.get(key, 0))


## The side built in a building's column: "a", "b" or "".
func yard_side(key: String, col: int) -> String:
	var sides: Array = yard_picks.get(key, [])
	return str(sides[col]) if col < sides.size() else ""


## How many picks are built, of how many there are.
func yard_built() -> int:
	var n := 0
	for b in Data.YARD:
		for c in range(b["picks"].size()):
			if yard_side(b["key"], c) != "":
				n += 1
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
	return tier_depth(lv_at(i, int(best_depth[i]))) if int(best_depth[i]) >= 2 else 1


## The deepest site's level (its tier and its depth): the Gunsmith's and the Arms dealer's.
## The deepest level among the sites cleared (D6, the gamble's gate: the next zone's first site, open and not yet
## cleared, put the gamble a level past every drop the runner had seen).
## What a site of level `lv` pays you (D9, 15 Oct, Matt: "fall off past 5 levels"): whole up to OVER_LEVEL_FREE site levels
## under you, OVER_LEVEL_STEP less a level past that, never under OVER_LEVEL_FLOOR. Your level read as a site's - the
## item level you wear at - and never past the furthest you've got (D12: the deepest site cleared, or the highest
## signal won): a runner held at the Carpet Man was paid a tenth for the Estate he was stuck in, and never got out.
func over_level_share(lv: int) -> float:
	var mine: float = (level() + Data.WEAR_PER_ILVL - 1.0) / Data.WEAR_PER_ILVL
	if not campaign_done():
		mine = minf(mine, float(deepest_cleared_level()))     # held at a wall: its last sites pay whole (D12)
	var beyond: float = mine - float(lv) - Data.OVER_LEVEL_FREE
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


## A column's price: the building's figure at today's prices; changing a built pick costs YARD_REFIT of it.
func yard_pick_cost(key: String, col: int) -> int:
	var b := Data.yard_building(key)
	if b.is_empty() or col < 0 or col >= b["costs"].size():
		return -1
	var c: int = _inf(int(b["costs"][col]))
	return int(round(c * Data.YARD_REFIT)) if yard_side(key, col) != "" else c


## The salvage a column wants: the fifth's, YARD_PICK_SALVAGE of the building's kind (none for a refit).
func yard_pick_salvage(key: String, col: int) -> int:
	return Data.YARD_PICK_SALVAGE if col == 4 and yard_side(key, col) == "" else 0


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
	if col >= yard_cols():
		return Data.yard_gate(col)
	if yard_side(key, col) == side:
		return "Built"
	if cash < yard_pick_cost(key, col):
		return "Short of tins"
	if int(salvage.get(b["salvage"], 0)) < yard_pick_salvage(key, col):
		return "Wants %d %s" % [yard_pick_salvage(key, col), Data.SALVAGE_NAMES[b["salvage"]].to_lower()]
	return ""


func can_yard_pick(key: String, col: int, side: String) -> bool:
	return yard_pick_block(key, col, side) == ""


## Build a pick, or change one (a refit, for YARD_REFIT of the price).
func yard_pick(key: String, col: int, side: String) -> bool:
	if not can_yard_pick(key, col, side):
		return false
	var b := Data.yard_building(key)
	var refit: bool = yard_side(key, col) != ""
	var pk0: Dictionary = b["picks"][col][0 if side == "a" else 1]
	chron("yard", {"key": key, "col": col, "side": side, "name": str(pk0["name"]), "cost": yard_pick_cost(key, col), "salvage": yard_pick_salvage(key, col), "refit": refit})
	cash -= yard_pick_cost(key, col)
	salvage[b["salvage"]] = int(salvage.get(b["salvage"], 0)) - yard_pick_salvage(key, col)
	var sides: Array = yard_picks.get(key, ["", "", "", "", ""]).duplicate()
	while sides.size() < b["picks"].size():
		sides.append("")
	sides[col] = side
	var before := _yard_before()
	yard_picks[key] = sides
	_yard_changed(key)
	_yard_grew(before)
	var pk: Dictionary = b["picks"][col][0 if side == "a" else 1]
	log_event("%s %s: %s" % [b["name"], "refitted" if refit else "built", "%s - %s" % [pk["name"], str(pk["words"]).to_lower()]])
	return true


## A rank's price: YARD_RANK_CASH × YARD_RANK_GROWTH a rank bought, at today's prices; salvage, one more a rank.
func yard_rank_cost(key: String) -> int:
	return _inf(int(round(Data.YARD_RANK_CASH * pow(Data.YARD_RANK_GROWTH, yard_rank(key)))))


func yard_rank_salvage(key: String) -> int:
	return Data.YARD_RANK_SALVAGE + yard_rank(key)


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
	if cash < yard_rank_cost(key):
		return "Short of tins"
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
	_yard_changed(key)
	log_event("%s, rank %d: %s" % [b["name"], yard_rank(key), str(b["rank"]["words"]).to_lower()])
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
	for b in Data.YARD:
		var have: int = int(salvage.get(b["salvage"], 0))
		for c in range(b["picks"].size()):
			if c < yard_cols() and yard_side(b["key"], c) == "" and cash >= yard_pick_cost(b["key"], c) and have >= yard_pick_salvage(b["key"], c):
				out.append("%s/%d" % [b["key"], c])
		if yard_cols() >= Data.YARD_COLS and cash >= yard_rank_cost(b["key"]) and have >= yard_rank_salvage(b["key"]):
			out.append("%s/r%d" % [b["key"], yard_rank(b["key"]) + 1])
	return out


## The rail's badge (Matt, 9 Oct: lit nearly always, so it was ignored): only for news - a column opened since
## the Yard was last looked at, or something buyable that wasn't when it was. Looking clears it.
func yard_news() -> bool:
	if yard_cols() > yard_seen_cols:
		return true
	for id in _yard_buyable_ids():
		if not yard_seen.has(id):
			return true
	return false


func yard_mark_seen() -> void:
	yard_seen_cols = yard_cols()
	for id in _yard_buyable_ids():
		yard_seen[id] = true


## A refit that takes cells away (off Shelving, Racks, the Annex...): how many cells the stash would be over after
## it, 0 if none. Allowed, but the strip says so first.
func yard_refit_over(key: String, col: int, side: String) -> int:
	var was: Dictionary = yard_picks.duplicate(true)
	var sides: Array = yard_picks.get(key, ["", "", "", "", ""]).duplicate()
	sides[col] = side
	yard_picks[key] = sides
	_yard_dirty = true
	var over: int = stash_used() - stash_cap()
	yard_picks = was
	_yard_dirty = true
	var now_over: int = stash_used() - stash_cap()
	return maxi(0, over) if over > now_over else 0


## What a pick changed: the figures read fresh; the Fence's and the Clinic's shelves and the odds again.
func _yard_changed(_key: String) -> void:
	_yard_dirty = true
	_dry_memo.clear()
	_surv_cache = {}                          # the odds read the Yard too: the Jammer, the Med lab, the Charger


## What a pick or a refit might grow or shrink, read before it's built: the Fence's shelf, the Back room, the
## contracts open, Pin.
func _yard_before() -> Dictionary:
	return {"stock": market_stock(), "back": yard_has("back_room"), "open": contracts_open()}


## A pick that grows a shelf or the contracts adds only what it grew by - never a re-roll or a refill of what's
## there (the reviewers' catches: a Fence pick re-rolled every site's words, and any build refilled a shelf the
## player had bought from). A refit away shrinks them back: Orders' two contracts, Pin's pins.
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
			market.append(Items.roll_unique(bu, rng, -1, shop_unique_tier()))
	while contracts.size() < contracts_open():
		contracts.append(roll_contract())
	if contracts_open() < int(before["open"]) and contracts.size() > contracts_open():
		contracts = contracts.slice(0, contracts_open())


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


func contracts_open() -> int:
	return Data.CONTRACTS_OPEN + (Data.FX["yard/orders"] if yard_has("orders") else 0)


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
	if not d.has("yard_picks"):
		var old := {"stash": [int(d.get("stash_level", 0)), [0, 1, 3]], "clinic": [int(d.get("medic_level", 0)), [0, 1]],
			"fence": [int(d.get("market_level", 0)), [0, 1]], "radio": [int(d.get("comms_level", 0)), [0, 1, 2]],
			"generator": [int(d.get("generator_level", 0)), [0, 1, 2]], "lookout": [int(d.get("lookout_level", 0)), [0, 1, 2]],
			"kennel": [int(d.get("kennel_level", 0)), [0, 1, 2]]}
		for key in old:
			var lv: int = old[key][0]
			var cols: Array = old[key][1]
			for k in range(mini(lv, cols.size())):
				var sides: Array = yard_picks.get(key, ["", "", "", "", ""])
				sides[int(cols[k])] = "a"
				yard_picks[key] = sides
	_yard_dirty = true


# ------------------------------------------------------------------ the workshop

## Every mount from the start (9 Oct: the Bench's levels went; crafting is open from the first minute).
func mount_open(_mount: String) -> bool:
	return true


func socket_max() -> int:
	return Data.SOCKET_MAX + (Data.FX["yard/third_socket"] if yard_has("third_socket") else 0)


func bump_cap() -> int:
	return Data.BUMP_CAP + yard_rank("bench")


func bump_levels() -> int:
	return Data.BUMP_LEVELS * (Data.FX["yard/overbump"] if yard_has("overbump") else 1)


## Why a stash attachment cannot go on a fitted gun's mount: "" when it can.
## A part made for a type (a choke, a bipod) is refused on any other gun (Matt, 6 Oct), not fitted for nothing.
func fit_refusal(slot: String, id: int) -> String:
	if mission != null:
		return "The runner is out"
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
			return true
	return false


## One off a stack in the stash (a bottle from the bottles), or the item itself.
func _one_off(it: Dictionary) -> Dictionary:
	if Items.stacks(it) and Items.stack_size(it) > 1:
		Items.set_stack(it, Items.stack_size(it) - 1)
		return Items.one_of(it)
	_remove(it)
	return it


## A socketable into a named socket of a fitted item.
func fit_socket(slot: String, mount: String, id: int) -> bool:
	if mission != null or not Data.SLOTS.has(slot) or equipped[slot] == null or not mount.begins_with("socket"):
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
			return true
	return false


func strip(slot: String, mount: String) -> bool:
	if mission != null or equipped[slot] == null:
		return false
	var gun: Dictionary = equipped[slot]
	if gun["attachments"].get(mount, null) == null:
		return false
	if not (stash_fits(gun["attachments"][mount]) or _stack_room(gun["attachments"][mount])):
		return false
	stash_put(gun["attachments"][mount])
	gun["attachments"][mount] = null
	return true


## The stash's attachments that go on this mount, best first.
## The stash's parts for a mount, best first; `gun_type` given, only the ones that go on that type of gun.
func attachments_for(mount: String, gun_type_v := "") -> Array:
	var out: Array = []
	for it in stash:
		if Items.is_attachment(it) and (it["mount"] == mount or (mount.begins_with("socket") and it["mount"] == "socket")):
			if gun_type_v == "" or Items.att_fits(it, gun_type_v):
				out.append(it)
	out.sort_custom(func(a, b): return Items.score(a) > Items.score(b))
	return out


func _affix_sum(stat: String) -> float:
	return _memo("_affix_sum/" + stat, __affix_sum_raw.bind(stat))


func __affix_sum_raw(stat: String) -> float:
	var t := 0.0
	for s in Data.SLOTS:
		if equipped[s] != null:
			t += Items.affix_total(equipped[s], stat)
	t += set_stat(stat)
	if stat != "all_res" and has_rule("blue_plaque"):
		return 0.0                               # a Blue Plaque: nothing else on you counts
	return t


# ------------------------------------------------------------------ sets
## How many of a set are worn; its bonuses at two and at the full set.
func set_count(name: String) -> int:
	var n := 0
	for s in Data.SLOTS:
		if equipped[s] != null and equipped[s].get("set", "") == name:
			n += 1
	return n


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
			v += equipped[s]["value"]
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
const CONTACT := 3                 # hostiles firing at once; the rest wait their turn
const SEARCH_S := 15.0
const PATROL_S := 24.0          # D6 (gate 10): 20 left 1.6-1.9 searches a gap on the early sites
const PATROL_BASE := 2
const SURVIVAL_RUNS := 40
const AUTO_REST := 0.95            # auto-run redeploys at this share of max HP

var auto_tier := -1                # a tier to keep running, or -1
var _surv_cache := {}              # tier -> [key, odds]


func tier(i: int) -> Dictionary:
	return Data.TIERS[i]


## A zone opens when the one before it is complete: its sites cleared and
## its boss beaten. All three complete is the campaign done, and the depth
## ladder and the radio's call-in open with it.
func zone_open(z: int) -> bool:
	return z == 0 or zone_complete(z - 1)


func zone_complete(z: int) -> bool:
	for i in Data.ZONES[z]["tiers"]:
		if best_depth[i] <= 0:
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
	return int(Data.PINNACLE_DEPTH[int(Data.TIERS[i]["zone"])]) + yard_moves - Data.FX["atlas/full_strength"] * atlas_rank("full_strength")


## The depth the old Services' convoy ran from (the depot's signal now, 15 Oct): CONVOY_DEPTH, a depth deeper a move.
func convoy_depth() -> int:
	return Data.CONVOY_DEPTH + yard_moves     # the old Services' convoy (the depot's signal now, 15 Oct); its two shortcuts went to the signals


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
	return (not boss_of(i).is_empty() or is_convoy(i)) and mission == null and tier_open(i) and notes >= boss_cost(i)


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
			log_event("%s: %s" % [b["name"], Words.BOSSES[b["name"]]["armed"]])


## A tier is open when its zone is and the tier before it in that zone has
## been cleared (best_depth > 0), or it's the zone's first.
func tier_open(i: int) -> bool:
	var t: Dictionary = Data.TIERS[i]
	if not zone_open(t["zone"]):
		return false
	var zt: Array = Data.ZONES[t["zone"]]["tiers"]
	var k := zt.find(i)
	return k == 0 or best_depth[zt[k - 1]] > 0


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


## The gear tier a level draws bases from: the streets reach the city's bases at depth 9, the Barracks from depth 1.
## Past the campaign's six (10 Oct, docs/design/deep_guns.md): a deep tier a step from level 12, 16 and 20.
static func loot_tier_at(level_v: int) -> int:
	var t: int = clampi(int(floor(level_v * Data.CAMPAIGN_TIER / 9.0)), 1, Data.CAMPAIGN_TIER)
	for at in Data.DEEP_TIER_LEVELS:
		if level_v >= int(at):
			t += 1
	return mini(t, Data.MAX_TIER)


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
	if d == 1:
		e["hp"] *= Data.CAMPAIGN_HOSTILE     # D20: the campaign's crews a touch softer, the levels at the Quartermaster held by XP
		e["dps"] *= Data.CAMPAIGN_HOSTILE
	if d >= 2 and (campaign_done() or ahead):
		# the endgame (7 Oct): the curve by the site's level, bent by its shape, never under the site's own
		# campaign curve - so the streets' ladder is gentle and long and the Barracks' steep and short; the
		# bases a find draws from and its item level follow the level too (the sites were the same fight before)
		var shape: Dictionary = base["shape"]
		var c: Dictionary = Data.CURVE
		var g: float = pow(1.0 + float(c["grow"]), lv - 9)
		var r: float = pow(1.0 + float(c["reward"]), lv - 9)
		e["pool"] = int(shape["pool"])
		# a signal's fight is its level's curve alone, bent by the site's shape (D14): the site's own campaign floor made
		# a City site's level 22 seven times the Allotments' (4200 x 1.25^13 against the curve's 3200 x 1.14^13), and
		# the Radio's signals split into won and binned by the site they landed on, not their level
		# D21: and on a signal the shape keeps its crowd and toughness but not its fire - the soft sites' many and the hard
		# ones' few come to much the same crew HP (14 x 0.6 against 8 x 1.5), and fire x0.7 against x1.4 was nine levels at
		# the 8% slope: the reach ran ahead on the soft sites and four in five rolls past it were unwinnable
		e["hp"] = float(c["hp"]) * g * float(shape["hp"]) if on_sig else maxf(float(e["hp"]), float(c["hp"]) * g * float(shape["hp"]))
		e["dps"] = float(c["dps"]) * g if on_sig else maxf(float(e["dps"]), float(c["dps"]) * g * float(shape["dps"]))
		e["xp"] = float(c["xp"]) * r if on_sig else maxf(float(e["xp"]), float(c["xp"]) * r)     # and its pay (the review)
		e["cash"] = float(c["cash"]) * r * float(shape.get("cash", 1.0)) if on_sig else maxf(float(e["cash"]), float(c["cash"]) * r * float(shape.get("cash", 1.0)))
		e["drop"] = float(c["drop"]) + Data.DEPTH_DROP * (d - 2) if on_sig else maxf(float(e["drop"]), float(c["drop"]) + Data.DEPTH_DROP * (d - 2))
		e["loot_tier"] = loot_tier_at(lv)
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
	var sets: bool = before >= 2
	for lv in range(from_lv, from_lv + count):
		var td: int = tier_depth(lv)
		var f: Dictionary = depth_figures(i, td, lv, true, true)
		var uq: float = unique_odds({"tier": i, "depth": td})
		var marks: Array = []
		if td >= 2 and not sets:
			marks.append(["Set pieces drop", "set"])
		sets = sets or td >= 2
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
const DECRYPT_NEEDS_PAPERS := "put three papers in"     # decrypt_block's "not enough chosen", which the Radio reads as no block (18 Oct: a words change broke the match)


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
	e["drop"] *= 1.0 + Data.FX["atlas/easy_pickings"] * atlas_rank("easy_pickings")
	e["cash"] *= (1.0 + Data.FX["atlas/every_penny"] * atlas_rank("every_penny")) * (Data.FX["atlas/heavy_crews.cash"] if atlas_rank("heavy_crews") > 0 else 1.0)
	e["xp"] *= (1.0 + Data.FX["atlas/wages"] * atlas_rank("wages")) * (Data.FX["atlas/heavy_crews.xp"] if atlas_rank("heavy_crews") > 0 else 1.0)
	e["pace"] *= 1.0 + Data.FX["atlas/short_cuts"] * atlas_rank("short_cuts")
	e["contact"] += (Data.FX["atlas/heavy_crews.contact"] if atlas_rank("heavy_crews") > 0 else 0) - (Data.FX["atlas/open_ground"] if atlas_rank("open_ground") > 0 else 0)
	e["rarity"] += Data.FX["atlas/tip_offs"] * atlas_rank("tip_offs")
	if atlas_rank("local_knowledge") > 0:
		e["loot_tier"] = mini(loot_cap(lv), int(e["loot_tier"]) + 1)
	if night_run and yard_has("dead_air"):
		e["patrol"] *= Data.FX["yard/dead_air"]                  # the Radio's Dead air
	var sky: String = weather_of(i)
	if sky != "":
		e["intel"].append(sky)               # applied with the words below, softened by the Radio's Weather set
	if sky != "" and yard_has("forecast"):
		e["cash"] *= Data.FX["yard/forecast"]                     # the Radio's forecast: a run under the weather pays
	var w := wear(i)
	if w > 0.0:
		e["drop"] *= 1.0 - Data.WORN_DROP * w
		e["cash"] *= 1.0 - Data.WORN_CASH * w
	e["plain_pool"] = int(e["pool"])         # the clock reads the site as plain (9 Oct): the words bite through it; the heads are formed from the same
	e["plain_hp"] = float(e["hp"])
	var act: Array = active_words(i)
	var walks := false
	for aw in act:
		if Data.word_of(aw[0])["bite"].has("boss_walks"):
			walks = true
	var b := boss_of(i)
	var sig_here: bool = not _sig.is_empty() and int(_sig["site"]) == i
	if sig_here and _sig.has("order"):
		e["boss"] = order_head(str(_sig["order"]), e)     # the order's true pinnacle (18 Oct): their own head, on the host site's crew
		e["name"] = Data.pinnacle(str(_sig["order"]))["place"]
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
	elif not b.is_empty() and boss_armed.get(i, false):
		e["boss"] = boss_form(b, e, is_pinnacle(i))
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
	if mission == null:
		# the ladder is the endgame's; a moved yard's opens to the floor from a site's first clear (7 Oct)
		var top: int = maxi(best_depth[i] + 1, (ladder_floor() + 1) if best_depth[i] > 0 else 1) if campaign_done() else 1
		depth[i] = clampi(d, 1, top)


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
	return out


## Held of a material or a key item.
func held_of(k: String) -> int:
	return int(key_items.get(k, 0)) if Data.KEY_ITEMS.has(k) else int(materials.get(k, 0))


## A material's or a key item's name.
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
			return "Short of %s" % (Words.mid(thing_name(k)) if Data.KEY_ITEMS.has(k) else thing_name(k).to_lower())     # a key item's name keeps its proper noun
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
	rebuilt[key] = rebuild_rank(key) + 1
	var r: Dictionary = Data.rebuild(key)
	chron("rebuild", {"key": key, "rank": rebuild_rank(key), "worth": town_worth(), "cost": cost.duplicate()})
	log_event(Words.REBUILD["built"] % [r["name"], rebuild_rank(key), town_worth()])
	if rebuild_rank(key) == 1 and r.has("opens"):
		log_event(Words.REBUILD["opened"] % Data.pinnacle(str(r["opens"]))["place"])
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
		if rk <= 0:
			continue
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
	return town_worth() * pay * Data.MINT_TINS * inflation() * (2.0 if held_of("fiat_note") > 0 else 1.0)


## The material a site's run brings: its own; a signal or the order's on an Outskirts site, its crew's area's first.
func material_at(i: int) -> String:
	var kind: String = Data.SITE_MATERIAL[i]
	if kind == "" and not _sig.is_empty() and int(_sig["site"]) == i:
		for k in Data.MATERIAL_ORDER:
			if int(Data.MATERIALS[k]["area"]) == maxi(1, int(_sig["zone"])):
				return k
	return kind


## A run's chance at its site's material: MATERIAL_RUN on the campaign, a signal's by its level; a move adds a share.
func material_odds(i: int) -> float:
	if material_at(i) == "":
		return 0.0
	var base: float = Data.MATERIAL_RUN
	if not _sig.is_empty() and int(_sig["site"]) == i:
		base = Data.MATERIAL_SIGNAL + Data.MATERIAL_SIGNAL_STEP * maxi(0, signal_level(_sig) - Data.REACH_START)
	return minf(Data.MATERIAL_CAP, base + Data.MATERIAL_MOVE * yard_moves)


## The run's materials home, whatever happened (death included): a head's handful, the run's roll, a signal's fuses.
func _bank_materials(m: Dictionary) -> void:
	if m.get("dry", false) or _dry_on:
		return
	var got: Dictionary = m.get("materials", {}).duplicate()
	var i: int = int(m["tier"])
	if int(m["kills"]) > 0:
		var kind: String = material_at(i)
		if kind != "" and material_rng.randf() < material_odds(i):
			got[kind] = int(got.get(kind, 0)) + material_rng.randi_range(Data.MATERIAL_HANDFUL[0], Data.MATERIAL_HANDFUL[1])
		if not _sig.is_empty() and int(_sig["site"]) == i and material_rng.randf() < Data.FUSE_SIGNAL:
			got["fuses"] = int(got.get("fuses", 0)) + material_rng.randi_range(1, 2)
	m["materials"] = got
	if got.is_empty():
		return
	var first: bool = materials.is_empty() and town_worth() == 0
	var said: Array = []
	for k in Data.MATERIAL_ORDER:
		if got.has(k):
			materials[k] = int(materials.get(k, 0)) + int(got[k])
			said.append("%d %s" % [int(got[k]), thing_name(k).to_lower()])
	chron("materials", {"got": got.duplicate()})
	log_event(Words.REBUILD["material"] % ", ".join(said))
	if first:
		log_event(Words.REBUILD["first_material"] % thing_name(got.keys()[0]))


## A crew's head down: their handful of the site's material, home with the run.
func _head_materials(m: Dictionary) -> void:
	var kind: String = material_at(int(m["tier"]))
	if kind == "" or m.get("dry", false):
		return
	m["materials"] = m.get("materials", {})
	m["materials"][kind] = int(m["materials"].get(kind, 0)) + material_rng.randi_range(Data.MATERIAL_HEAD[0], Data.MATERIAL_HEAD[1])


## The order's true pinnacles: open once their rebuild is.
func order_open(k: String) -> bool:
	var p: Dictionary = Data.pinnacle(k)
	return not p.is_empty() and rebuild_rank(str(p["opened_by"])) > 0


func any_order_open() -> bool:
	for p in Data.PINNACLES:
		if order_open(p["key"]):
			return true
	return false


## A true pinnacle's level: your reach and its own step past it, a level more every PINNACLE_WORTH of the town's worth
## and every time it's been beaten.
func order_level(k: String) -> int:
	var p: Dictionary = Data.pinnacle(k)
	@warning_ignore("integer_division")
	return maxi(Data.REACH_START, reach) + int(p["over"]) + town_worth() / Data.PINNACLE_WORTH + int(order_beaten.get(k, 0))


## A true pinnacle as a signal: laid on its host site the way a signal is, under its own name and head.
func order_sig(k: String) -> Dictionary:
	var p: Dictionary = Data.pinnacle(k)
	var site: int = int(p["site"])
	return {"id": -1, "site": site, "zone": int(p["zone"]), "depth": depth_for_level(site, order_level(k)), "codes": [], "papers": [],
		"head": false, "convoy": false, "line": 0, "story": -1, "order": k}


## The head a true pinnacle fields, formed on the fight's figures as a crew's head is.
func order_head(k: String, e: Dictionary) -> Dictionary:
	var p: Dictionary = Data.pinnacle(k)
	var b := boss_form({"name": p["who"], "hp": p["hp"], "dps": p["dps"], "zone": p["zone"]}, e, false)
	b["order"] = k
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
	var out: Array = [float(c[1]), int(c[2]) >= odds_runs()] if c[0] == _odds_key(i) else [0.0, false]
	_sig_off()
	return out


## Why a true pinnacle can't be run now, or "".
func order_block(k: String) -> String:
	var p: Dictionary = Data.pinnacle(k)
	if p.is_empty():
		return "no such place"
	if not order_open(k):
		return "Rebuild %s to open" % str(Data.rebuild(str(p["opened_by"]))["name"]).to_lower()
	if not can_deploy() or not _sig.is_empty():
		return "The runner is out" if mission != null else "The runner can't go"
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
	chron("order_run", {"key": k, "level": order_level(k)})
	return true


## A true pinnacle's head down: the run's pay, their unique (always the first time), their handful of materials.
func _order_down(m: Dictionary, t: Dictionary, b: Dictionary) -> void:
	var k: String = str(b["order"])
	var p: Dictionary = Data.pinnacle(k)
	var first: bool = int(order_beaten.get(k, 0)) == 0
	chron("order_down", {"key": k, "first": first, "level": int(t.get("level", 0))})
	_head_materials(m)
	if first or rng.randf() < Data.PINNACLE_UNIQUE:
		var it := Items.roll_unique(_unique_named(str(p["unique"])), rng, int(t.get("level", -1)), int(t["loot_tier"]))
		m["found"].append(it)
		_read(it)
		log_event("%s is down. Found: %s." % [p["who"], it["unique"]])
	else:
		log_event("%s is down." % p["who"])


## A true pinnacle's run over: beaten, its drop comes home (and the first time its keepsake); either way the site goes
## back to its campaign self. The reach is the signals'; the order's never moves it.
func _order_done(won: bool) -> void:
	var k: String = str(_sig["order"])
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
		log_event("Brought home: %s" % thing_name(drop))
	if first and p.has("first"):
		var f: String = str(p["first"])
		key_items[f] = held_of(f) + 1
		if f == "fiat_note":
			log_event(Words.REBUILD["note"])
	log_event(Words.REBUILD["order_won"] % p["who"])


# ------------------------------------------------------------------ signals (15 Oct, the Radio's endgame)

## The papers a signal can be made of: read papers in the stash, not the deeds, a head's thing or a unique's rule paper.
func signal_papers() -> Array:
	var out: Array = []
	for it in stash:
		if Items.is_paper(it) and not Items.is_deeds(it) and Items.opens(it) == "" and not it.has("unique"):
			out.append(it)
	return out


## Why three papers can't be decrypted now, or "".
func decrypt_block(ids: Array) -> String:
	if not room_open("radio"):
		return "the Radio's shut"
	if not campaign_done():
		return "the campaign first"
	if signals.size() >= Data.SIGNALS_HELD:
		return "%d signals held: run or bin one" % Data.SIGNALS_HELD
	if ids.size() != Data.SIGNAL_PAPERS:
		return DECRYPT_NEEDS_PAPERS
	var have: Array = signal_papers().map(func(x): return int(x["id"]))
	var seen_ids := {}
	for id in ids:
		if not (int(id) in have) or seen_ids.has(int(id)):
			return "three papers from the stash"
		seen_ids[int(id)] = true
	var beats := {}
	var bases := {}
	for it in stash:
		if int(it["id"]) in ids:
			beats[story_of(it)] = true
			bases[str(it["base"])] = true
	if beats.size() > 1 or (beats.has(-1) == false and bases.size() < Data.SIGNAL_PAPERS):
		return "Kev's papers go in together, the three of a beat"
	if not beats.has(-1) and not beats.has(story_now()):
		return "not the part of Kev's story he's on"
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
	var held: Array = stash.duplicate()
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


## The levels three papers would roll: the reach's band, one higher for a rare paper (D3: levels, not depths).
func signal_band(ids: Array) -> Array:
	var lo: int = reach + (maxi(int(Data.SIGNAL_ROLL[0][0]), -int(Data.FX["atlas/lie_of_the_land"])) if atlas_rank("lie_of_the_land") > 0 else int(Data.SIGNAL_ROLL[0][0]))
	var hi: int = reach + int(Data.SIGNAL_ROLL[Data.SIGNAL_ROLL.size() - 1][0]) + (int(Data.FX["atlas/lorrys_route"]) if atlas_rank("lorrys_route") > 0 else 0)
	var up: int = 1 if _papers_rare(ids) else 0
	return [maxi(Data.REACH_START, lo + up), hi + up]


func _papers_rare(ids: Array) -> bool:
	for it in stash:
		if int(it["id"]) in ids and int(it.get("rarity", 0)) >= Data.PAPER_DEEPER_AT:
			return true
	return false


## Three papers in, a signal out: the papers spent, the place, the crew, the depth and the extras rolled, each paper's
## code on it. {} if it can't be made.
func decrypt(ids: Array) -> Dictionary:
	if decrypt_block(ids) != "":
		return {}
	var papers: Array = []
	var codes: Array = []
	for it in stash.duplicate():
		if int(it["id"]) in ids:
			papers.append(str(it["base"]))
			var code: String = word_taught_by(str(it["base"]))
			if code != "" and not (code in codes):
				codes.append(code)
	var up: int = 1 if _papers_rare(ids) else 0
	var beat: int = -1
	for it in stash:
		if int(it["id"]) in ids:
			beat = story_of(it)
	for it in stash.duplicate():
		if int(it["id"]) in ids:
			_remove(it)
	if beat >= 0:
		return _story_signal(beat, papers)
	var x := rng.randf()
	var step := 0
	for row in Data.SIGNAL_ROLL:
		x -= float(row[1])
		step = int(row[0])
		if x <= 0.0:
			break
	if atlas_rank("lie_of_the_land") > 0:
		step = maxi(step, -int(Data.FX["atlas/lie_of_the_land"]))     # The lie of the land: no roll far under the reach (18 Oct)
	if step == int(Data.SIGNAL_ROLL[Data.SIGNAL_ROLL.size() - 1][0]) and atlas_rank("lorrys_route") > 0 and rng.randf() < 0.5:
		step += int(Data.FX["atlas/lorrys_route"])     # The lorry's route: the top of the band a depth further, half the time it's reached
	signal_seq += 1
	var site: int = rng.randi_range(0, Data.TIERS.size() - 1)
	var sig := {"id": signal_seq, "site": site, "zone": rng.randi_range(0, Data.ZONES.size() - 1),
		"depth": depth_for_level(site, maxi(Data.REACH_START, reach + step + up)), "codes": codes, "papers": papers,
		"head": rng.randf() < Data.SIGNAL_HEAD_ODDS, "convoy": rng.randf() < Data.SIGNAL_CONVOY_ODDS,
		"line": rng.randi_range(0, Words.SIGNAL_LINES.size() - 1)}
	signals.append(sig)
	chron("signal", {"id": signal_seq, "site": int(sig["site"]), "zone": int(sig["zone"]), "depth": int(sig["depth"]), "codes": codes.duplicate(), "papers": papers.duplicate()})
	log_event(Words.SIGNAL_MADE % [Words.mid(str(Data.TIERS[int(sig["site"])]["name"])), signal_level(sig)])
	return sig


## A beat's signal: its site and crew, STORY_UNDER levels under your reach; the head at full strength, or the depot's convoy.
func _story_signal(beat: int, papers: Array) -> Dictionary:
	var b: Dictionary = Data.STORY_BEATS[beat]
	signal_seq += 1
	var convoy: bool = bool(b.get("convoy", false))
	var sig := {"id": signal_seq, "site": int(b["site"]), "zone": int(b["zone"]), "depth": depth_for_level(int(b["site"]), maxi(Data.REACH_START, reach - Data.STORY_UNDER)), "codes": [], "papers": papers,
		"head": not convoy, "convoy": false, "convoy_fight": convoy, "line": 0, "story": beat}
	signals.append(sig)
	chron("signal", {"id": signal_seq, "site": int(sig["site"]), "zone": int(sig["zone"]), "depth": int(sig["depth"]), "story": beat, "papers": papers.duplicate()})
	log_event(Words.STORY[beat]["made"])
	return sig


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
	return maxi(2, lv - (i - Data.OUTSKIRTS_SITES))


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
	signals.remove_at(k)
	return true


## The signal laid on its site - its depth, its codes at the depth's tier, its crew read by effective() - for a read
## or a run; _sig_off() puts the site back. One at a time.
func _sig_on(sg: Dictionary) -> void:
	var i: int = int(sg["site"])
	sg["was"] = {"depth": depth[i], "words": words[i].duplicate(true), "sealed": sealed[i], "armed": boss_armed.get(i, false),
		"worn": worn[i], "worn_depth": worn_depth[i]}     # a signal's run doesn't wear the campaign site (the review)
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
	if was.has("worn"):
		worn[i] = was["worn"]
		worn_depth[i] = int(was["worn_depth"])
	_sig.erase("was")
	_sig = {}


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


## The odds read so far, without running any (the Radio's card, as odds_now is the Map's).
func signal_odds_now(k: int) -> Array:
	var sg := signal_at(k)
	if sg.is_empty() or not _sig.is_empty() or not _sig_odds.has(int(sg["id"])):
		return [0.0, false]
	_sig_on(sg)
	var i: int = int(sg["site"])
	var c: Array = _sig_odds[int(sg["id"])]
	var out: Array = [float(c[1]), int(c[2]) >= odds_runs()] if c[0] == _odds_key(i) else [0.0, false]
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
	if not m.has("signal") or _sig.is_empty():
		return
	var d: int = signal_level(_sig)
	var won: bool = bool(m["cleared"]) and not died and not m.get("ghost_pending", false) and not bool(m.get("timed_out", false)) and not (m.has("boss") and bool(m["boss"].get("alive", false)))
	if _sig.has("order"):
		_order_done(won)
		_sig_off()
		return
	chron("signal_done", {"id": int(_sig["id"]), "level": d, "won": won})
	if won and d >= reach:
		reach += 1                             # a level a win (D25: d + 1 let a roll over the reach jump it two and three at a time - the reach to 30-44 by hour 12, then hours at the kit's wall)
		atlas_points += 1
		log_event(Words.SIGNAL_REACH % [d, reach])
	elif not won:
		log_event(Words.SIGNAL_LOST)
	var beat: int = int(_sig.get("story", -1))
	if won and beat >= 0 and beat == story_now():
		chron("story", {"beat": beat})
		log_event(Words.STORY[beat]["won"])
		story_beat = mini(story_beat + 1, Data.STORY_BEATS.size())
		if rebuild_open():
			log_event(Words.REBUILD["open"])      # Kev's last line opens the rebuild (18 Oct)
	elif won and rng.randf() < Data.STORY_DROP * (Data.FX["yard/lorry_watch"] if yard_has("lorry_watch") else 1.0):     # the Radio's Lorry watch
		_story_find()
	_sig_off()


## A signal beaten brings home the next of the beat's papers not held, now and then (STORY_DROP).
func _story_find() -> void:
	var held: Array = story_held()
	for nm in story_papers(story_now()):
		if not (nm in held):
			var it := _plain(Data.PAPER, nm)
			stash.append(it)                  # home with the run, whatever the room: Kev's
			_read(it)
			log_event(Words.STORY[story_now()]["found"] % [nm, held.size() + 1])
			return


func on_mission() -> bool:
	return mission != null


func searching() -> bool:
	return mission != null and mission["cleared"]


func can_deploy() -> bool:
	return mission == null and hp > 0.0


func can_deploy_to(i: int) -> bool:
	return can_deploy() and tier_open(i)


## Seconds a tier's fight should take at the operator's damage, for the card.
## The primary's rounds against a site's fight (16 Oct, Matt's dry shotgun at the Bank): [in the rig, the fight wants] -
## the fight's estimate at the gun's rate of fire - when the rig's short; [] when it isn't, or the gun takes none. The rig
## read is the one that goes out: it tops up from the stash coming home.
func rounds_short(i: int) -> Array:
	var gun = equipped["Primary"]
	if gun == null or Items.ammo_type(gun) in ["", "none"] or Items.free_rounds(gun):
		return []
	var t := effective(i)
	var want: int = ceili(estimate(i) * float(Items.base_of(gun)["rof"]) * pace() * float(t["pace"]))
	var have: int = rounds_for(gun)
	if rig_room(1):
		for it in stash:     # the gate tops up from the stash (the review): a box bought since home still goes out
			if Items.is_ammo(it) and Items.base_of(it)["type"] == Items.ammo_type(gun):
				have += int(it.get("rounds", 0))
	return [have, want] if have < want else []


func estimate(i: int) -> float:
	var t := effective(i)
	return t["pool"] * t["hp"] / (dps() * pace() * t["pace"])


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
	return common + [depth[i], str(words[i]), weather_of(i), boss_armed.get(i, false),
		int(_sig["id"]) if not _sig.is_empty() and int(_sig["site"]) == i else 0]     # a signal laid on the site reads apart from it (15 Oct)


## The key's runner half, the same for every site: worked once a frame while the shell reads the odds (16 Oct: twelve
## sites' keys a frame - each a dps(), an armour(), a max_hp() - ate the 5 ms before the City's dry runs got any, on
## Matt's machine), else every call. Nothing the key reads moves inside one frame's read: a dry run puts it all back.
var _key_memo := []
var _key_memo_t := -1
func _odds_key_common() -> Array:
	if odds_time_ms > 0.0 and _key_memo_t == _odds_t0 and not _key_memo.is_empty():
		return _key_memo
	var k: Array = [int(round(hp * 10.0 / maxf(max_hp(), 1.0))), _odds_bucket(max_hp()), _odds_bucket(dps()), _odds_bucket(armour()), _odds_bucket(pace() * 100.0), str(standing), tree.size(), rig.size(), campaign_done(), yard_moves, str(atlas), is_night(), wound, _kit_ids()]
	if odds_time_ms > 0.0:
		_key_memo = k
		_key_memo_t = _odds_t0
	return k


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
		if _dry_run(i, c[4]):
			c[3] += 1
		c[2] += 1
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


## Whether the odds for a tier are fully read (the shell shows them dimmer until they are).
func odds_settled(i: int) -> bool:
	var runs: int = odds_runs() if odds_runs_max <= 0 else mini(odds_runs(), odds_runs_max)     # the read's cap as survival() runs it (D13 review)
	return _surv_cache.has(i) and _surv_cache[i][0] == _odds_key(i) and _surv_cache[i][2] >= runs


## The fight alone, run through the real fight code on a scratch mission with
## nothing kept - the same rates, rules, dots, keystones and meds as a run -
## DRY_STEP seconds at a time: true if it ends with HP left. The state goes
## back as it was: HP, XP, the rig, the log, the dice.
const DRY_STEP := 2.0
const TREE_V := 2                    # the trees' layout: 2, the lanes (9 Oct); a save before has its tree refunded
const BAIL := 0.25                   # the HP a player (and the bots) get out at: the odds count that as lost
func _dry_run(i: int, r: RandomNumberGenerator) -> bool:
	var p0 := Time.get_ticks_usec()
	prof["dry_runs"] += 1
	var t := effective(i)
	var keep := {"hp": hp, "xp": xp, "rig": rig.duplicate(true), "events": events.duplicate(true), "mission": mission,
		"rng": rng, "promised": promised, "training_points": training_points, "best_level": best_level, "insure_next": insure_next, "events_total": events_total}
	prof["snap_us"] += Time.get_ticks_usec() - p0
	rng = r
	_yard_setting_off()                       # the Charger and the Field kit read in the odds too (kept and put back above)
	var pool: int = int(t["pool"]) - (Data.FX["node/trapline.heads"] if has_node("trapline") else 0) - (Data.FX["joint/poacher_frost.heads"] if has_joint("poacher_frost") else 0) - (Data.FX["yard/flares.heads"] if yard_has("flares") else 0)
	var m := {
		"tier": i, "t": t, "remaining": maxi(1, pool), "target_hp": float(t["hp"]), "kills": 0, "found": [], "insured": false, "clock": clock_budget(t),
		"left": 0, "cash": 0.0, "xp": 0.0, "elapsed": 0.0, "hp_start": hp, "cleared": false,
		"search": 0.0, "searches": 0, "patrol_timer": 0.0, "patrols": 0, "last_incoming": 0.0,
		"using": null, "meds_used": 0, "fresh": true, "swapped": 0, "chill_t": Data.FX["joint/poacher_frost.chill_s"] if has_joint("poacher_frost") else 0.0, "event": "", "event_at": -1.0, "dry": true,
	}
	if t.has("boss"):
		m["boss"] = _boss_entry(t["boss"])
		m["boss_queue"] = []
		for q in t.get("boss_queue", []):
			m["boss_queue"].append(_boss_entry(q))
		m["convoy"] = t.get("convoy", false)
	# what may happen on the way, on the odds' own dice, as deploy rolls it (15 Oct, refactor A4: the odds missed a
	# convoy's extra lot; parked item 14). Only one that comes before the clear plays: a dry run ends at the clear,
	# so a convoy in the search still isn't in the odds
	var ev: String = roll_event()
	if ev != "":
		m["event"] = ev
		m["event_at"] = rng.randf_range(Data.EVENT_WINDOW[0], Data.EVENT_WINDOW[1])
	if not _sig.is_empty() and int(_sig["site"]) == i and bool(_sig.get("convoy", false)) and str(m.get("event", "")) == "":
		m["event"] = "convoy"                  # a signal's convoy, as deploy_signal sets it when nothing else is on (D17: the odds left it out)
		m["event_at"] = rng.randf_range(Data.EVENT_WINDOW[0], Data.EVENT_WINDOW[1])
	mission = m
	_dry_rules = _snapshot_rules()
	_dry_memo = {}
	_dry_on = true
	_gang_arrives(m)                          # Guard at the first gang, as a run (12 Oct); after the memo's reset (the review)
	var guard_v := 0
	_dry_min_hp = 1.0
	while guard_v < 450 and not m.get("dead", false):    # fifteen minutes of fighting is a loss
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
	var alive: bool = not m.get("dead", false) and hp > 0.0 and guard_v < 450     # out of time reads as dead
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
	return alive


func deploy(i: int) -> void:
	if not can_deploy_to(i):
		return
	if not candidates.is_empty():
		choose_runner(0)                  # nobody picked: the first one stays
	_top_up()                                 # the worn guns' rounds from the stash, into the rig's room (16 Oct): before the insurance and the odds read
	var odds_seen: float = odds_now(i) if odds_settled(i) else -1.0     # what the Runs card read at the gate, settled (12 Oct: the record; a part-read card logs -1)
	var gate_split: Dictionary = {} if _dry_on else damage_split()     # the one figure as it went out, for the record (the review: at the end a dry gun reads low)
	_dry_memo.clear()                     # the run reads the kit as it stands at the gate (fast_memo)
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
		log_event("Insured for %s. %s" % [_cash_words(insure_cost(i)), Words.FENCE["insured"]])
	insure_next = false
	_yard_setting_off()                       # before the run's record of its starting HP
	var pool: int = int(t["pool"]) - (Data.FX["node/trapline.heads"] if has_node("trapline") else 0) - (Data.FX["joint/poacher_frost.heads"] if has_joint("poacher_frost") else 0) - (Data.FX["yard/flares.heads"] if yard_has("flares") else 0)
	mission = {
		"tier": i, "t": t, "remaining": maxi(1, pool), "target_hp": float(t["hp"]), "kills": 0, "found": [], "insured": insured, "clock": clock_budget(t), "clock_max": clock_budget(t),
		"left": 0, "cash": 0.0, "xp": 0.0, "elapsed": 0.0, "hp_start": hp, "cleared": false, "odds_seen": odds_seen,
		"split_gate": [float(gate_split.get("total", 0.0)), float(gate_split.get("dot", 0.0))], "wear_gate": wearable_level(),
		"search": 0.0, "searches": 0, "patrol_timer": 0.0, "patrols": 0, "last_incoming": 0.0,
		"using": null, "meds_used": 0, "fresh": true, "swapped": 0, "chill_t": Data.FX["joint/poacher_frost.chill_s"] if has_joint("poacher_frost") else 0.0,
	}
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
	var ev: String = roll_event()
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
	log_event("Out to %s, %s%s%s" % [Words.mid(t["name"]), Words.mid(zone_name(i)), at_lv, (": " + intel) if intel != "" else ""])     # no codes, no colon (13 Oct, Matt's save)
	_maybe_wearing(mission)
	var key := "%d/%d" % [i, t["depth"]]
	if not seen.has(key):
		seen[key] = true
		var line := Words.site_line(t["name"], int(t["depth"]))
		if line != "":
			log_event(line)


## Auto-run: keep deploying to a tier between rests. Off on KIA or a full stash.
func set_auto(i: int) -> void:
	auto_tier = -1 if auto_tier == i else i


## The world goes `seconds` on - a frame, or hours away. Rest, auto-run
## redeploys and missions run in order, so an offline span plays as a live one would.
func advance(seconds: float) -> void:
	elapsed += seconds
	_roll_weather()
	if hp > max_hp():
		hp = max_hp()                        # the max can drop when kit comes off
	var left := seconds
	while left > 0.0:
		if mission != null:
			var step := minf(1.0, left)
			var p0 := Time.get_ticks_usec()
			if fast_memo:
				_memo_age += step
				if _memo_age >= FAST_MEMO_S:
					_memo_age = 0.0
					_dry_memo.clear()
			_tick(step)
			prof["real_ticks"] += 1
			prof["real_us"] += Time.get_ticks_usec() - p0
			left -= step
			continue
		var ready := max_hp() * AUTO_REST
		if auto_tier >= 0 and hp >= ready:
			if stash_used() >= stash_cap():
				auto_tier = -1
				log_event("Auto-run stopped: the stash is full")
				continue
			deploy(auto_tier)
			if mission == null:
				auto_tier = -1   # the tier closed under it; rest instead
			continue
		if auto_tier >= 0 and rest_rate() > 0.0:
			# rest only as far as the redeploy point, then go again; the bus depot's ranks rest it quicker (18 Oct)
			var auto_rest: float = rest_rate() * (1.0 + town_stat("auto_rest_pct") / 100.0)
			var dt := minf(left, (ready - hp) / auto_rest)
			hp = minf(max_hp(), hp + auto_rest * dt)
			left -= maxf(dt, 0.001)
			continue
		if hp < max_hp():
			hp = minf(max_hp(), hp + rest_rate() * left)
		left = 0.0


func _tick(dt: float) -> void:
	var m: Dictionary = mission
	var t: Dictionary = m["t"]
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
	else:
		_search(m, t, dt)
		if has_node("walk_it_off"):
			_heal(m, dt)                         # through _heal: the Paramedic's overflow counts (12 Oct)
		if has_node("breather"):
			_guard_add(m, guard_cap() * 0.1 * dt)     # Breather: with no one on you, Guard comes back
		if yard_has("drip"):
			_heal(m, max_hp() * 0.01 * dt)        # the Clinic's Drip
	if mission == null:
		return
	if _affix_sum("regen") > 0.0:
		_heal(m, _affix_sum("regen") * dt)
	if has_rule("nans_cardigan"):
		_heal(m, max_hp() * 0.03 * dt)
	if float(m.get("event_at", -1.0)) >= 0.0 and m["elapsed"] >= float(m["event_at"]) and not m.get("way_out", false):
		_event(m, t)
	# the Medic's rule: a med by itself under 40%
	if (class_data().get("auto_med", false) or has_rule("paramedics_bumbag")) and m["using"] == null and hp < max_hp() * 0.4 and not first_med().is_empty():
		use_med(first_med()["id"])
	elif has_rule("ambulance_bag") and m["using"] == null and hp < max_hp() * Data.MYTHIC_AUTO_MED and not first_med().is_empty():
		use_med(first_med()["id"])            # the Ambulance's Bag: one by itself under half
	_patch(m, dt)
	if float(m.get("immune_t", 0.0)) > 0.0:
		m["immune_t"] = maxf(0.0, float(m["immune_t"]) - dt)     # Clean hands' grace runs down whether they're on you or not
	if m["cleared"]:
		if not gang_held(m) and m["remaining"] <= 0:
			m["patrol_timer"] += dt          # only while it's quiet (14 Oct, Matt): every gang beaten gives the search its window back
		if m["patrol_timer"] >= patrol_s(t, m["patrols"] == 0) and not has_rule("freedom"):     # the Freedom of the Borough (a mythic): none after the clear
			m["patrol_timer"] = 0.0
			m["patrols"] += 1
			m["fresh"] = true
			m.erase("opened")
			m["sustain_t"] = 0.0
			_gang_arrives(m)
			var grown: int = 0 if has_node("cap_dead_quiet") else m["patrols"] - 1      # Dead quiet: every gang the size of the first
			var size: int = maxi(1, PATROL_BASE + grown - (Data.FX["node/trapline.heads"] if has_node("trapline") else 0) + (Data.FX["node/loud.gang"] if has_node("loud") else 0) - (Data.FX["rule/wardens_hat.gang"] if has_rule("wardens_hat") else 0))
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
			m["remaining"] += size
			if m["target_hp"] <= 0.0:
				m["target_hp"] = float(t["hp"])
			log_event(gang_line(m, size))
			if auto_tier >= 0 or m.get("leave_full", false):
				_extract()                  # auto-run, or "fill up then go", leaves as the gang arrives
				return
	if (auto_tier >= 0 or m.get("leave_full", false)) and m["cleared"] and (pack_used(m) >= capacity() or crates_done(m)):
		_extract()                           # the pack full, or every crate open: nothing more to stay for


## The run's clock (9 Oct, docs/design/timers.md): a site's budget, the same for every build - so many seconds a
## head of its plain pool and of the gangs after it - halved by the Radio's Last bus.
func clock_budget(t: Dictionary) -> float:
	var heads: int = int(t.get("plain_pool", t.get("pool", 1))) + Data.CLOCK_GANGS
	return (Data.CLOCK_BASE + Data.CLOCK_PER_HEAD * heads) * (0.5 if t.get("clock_half", false) else 1.0)


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
	_floor_mythics_in(m)
	var t := tier(m["tier"])
	var insured: bool = m.get("insured", false)
	if auto_tier >= 0:
		auto_tier = -1                         # out of time stops the auto-run, as a wound or a death does: no run after run lost
		log_event("Auto-run stopped")
	var worn_v: Array = []
	for s in Data.SLOTS:
		if equipped[s] != null and not equipped[s].get("mythic", false):     # a mythic is never lost (16 Oct)
			worn_v.append(s)
	var lost: Array = []
	var lost_slots: Array = []
	for k in range(mini(Data.CLOCK_LOSE_KIT, worn_v.size())):
		var s: String = worn_v[rng.randi_range(0, worn_v.size() - 1)]
		worn_v.erase(s)
		lost_slots.append(s)
		var it: Dictionary = equipped[s]
		equipped[s] = null
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
	var kept_pack: bool = insured and yard_has("insurance_desk")
	var carried := ""
	if not kept_pack and not m["found"].is_empty():
		var keep: Array = m["found"].filter(func(it): return Items.is_deeds(it) or it.get("mythic", false))     # the deeds come home whatever: _extract writes their fate; a mythic too
		var rest: Array = m["found"].filter(func(it): return not Items.is_deeds(it) and not it.get("mythic", false))
		if yard_has("fetch") and not rest.is_empty():
			var best: Dictionary = rest[0]
			for it in rest:
				if sell_price(it) > sell_price(best):
					best = it
			stash.append(best)                   # the Kennel's Fetch: the best of the pack, carried out - straight in, as on a death
			carried = Items.full_name(best)
			log_event("The dog came home with %s" % (carried if best.has("unique") else carried.to_lower()))
			rest.erase(best)
		m["left"] = int(m["left"]) + rest.size()
		m["found"] = keep
	_dry_memo.clear()
	# the line says it all (16 Oct, Matt's playtest): what went, the rig's contents with the rig, where it went, and why
	var rig_gone: bool = "Rig" in lost_slots and not insured
	log_event("Out of time in %s. The pack's gone%s%s%s." % [Words.mid(t["name"]), "" if lost.is_empty() else ", and %s with it" % " and ".join(lost),
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
## max HP (half with Transfusion), grown by Overtime and `guard_pct`. It lasts the run.
func guard_cap() -> float:
	var share: float = Data.GUARD_SHARE * (Data.FX["node/cap_transfusion"] if has_node("cap_transfusion") else 1.0)
	return max_hp() * share * (1.0 + (_affix_sum("guard_pct") + (Data.FX["node/overtime.guard"] if has_node("overtime") else 0.0)) / 100.0)


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
func _gang_arrives(m: Dictionary) -> void:
	var share: float = (Data.FX["node/squared_up"] if has_node("squared_up") else 0.0) + _affix_sum("guard_gang")
	if share > 0.0:
		_guard_add(m, max_hp() * share / 100.0)


## Their fire on you this tick, through Guard first: what's left comes off HP. "Guard gone" when it breaks.
func _take(m: Dictionary, amount: float) -> float:
	var g: float = float(m.get("guard", 0.0))
	if g > 0.0:
		var off: float = minf(g, amount)
		m["guard"] = g - off
		m["guarded"] = float(m.get("guarded", 0.0)) + off     # for the run screen
		amount -= off
		if m["guard"] <= 0.0 and g >= guard_cap() * 0.05 and not m.get("dry", false):
			log_event("Guard gone")              # a Guard worth the name broken, never a trickle of overheal (the review)
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
	return {"name": b["name"], "hp": b["hp"], "dps": b["dps"], "zone": b["zone"], "pinnacle": b.get("pinnacle", false), "order": str(b.get("order", "")), "started": false, "alive": true}


## A run's event on the dice, or "" (17 Oct, Matt: a convoy on the very first Allotments run took both starter
## bandages and left the next site at 0% with no way to buy more): no passing convoy in the first CONVOY_FROM_RUN
## runs; the other two still come on the same odds.
func roll_event() -> String:
	if not (rng.randf() < Data.EVENT_ODDS or has_rule("caretakers_keys")):
		return ""
	var pool: Array = Data.EVENTS if runs_total >= Data.CONVOY_FROM_RUN else Data.EVENTS.filter(func(e): return e != "convoy")
	return pool[rng.randi_range(0, pool.size() - 1)]


## The run's event, once.
func _event(m: Dictionary, t: Dictionary) -> void:
	var what: String = str(m.get("event", ""))
	m["event_at"] = -1.0
	m["event_done"] = what
	match what:
		"convoy":
			var size: int = PATROL_BASE + 2
			m["remaining"] += size
			_gang_arrives(m)
			m["clock"] = float(m.get("clock", 0.0)) + Data.CLOCK_PER_HEAD * size      # a convoy's crew brings its own time
			m["clock_max"] = float(m.get("clock_max", 0.0)) + Data.CLOCK_PER_HEAD * size
			if m["target_hp"] <= 0.0:
				m["target_hp"] = float(t["hp"])
				m.erase("opened")             # the Starting Pistol: a new one, its own first shot; one already up has had it
			m["fresh"] = true
			m["sustain_t"] = 0.0
			m["notes"] = int(m.get("notes", 0)) + notes_a_kill(t) * size
			log_event("%s %s" % [Words.EVENTS["convoy"], Words.EVENTS["convoy_notes"]])
		"trapped":
			var pool: Array = []
			for row in Data.TRAITS:
				if row["name"] != runner_trait:
					pool.append(row["name"])
			promised = pool[rng.randi_range(0, pool.size() - 1)]
			log_event(Words.EVENTS["trapped"])
		"cache":
			if m.get("dry", false):
				return                        # the odds: a cache is loot, not the fight (A4)
			# a cache is always opened now (9 Oct: the Bench's levels went - it wanted Bench 2)
			var up: Dictionary = t.duplicate()
			up["loot_tier"] = mini(loot_cap(int(t.get("level", lv_at(int(t["tier"]), int(t["depth"]))))), int(t["loot_tier"]) + 1)
			up["rarity"] = float(t.get("rarity", 0.0)) + 0.5
			_find(m, up)
			log_event(Words.EVENTS["cache"])


func _fight(m: Dictionary, t: Dictionary, dt: float) -> void:
	var swing := rng.randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	var headshot := 1.0
	if m["fresh"]:
		headshot += (_fitted_sum("first_pct") + float(class_data().get("first_pct", 0)) + grade_stat(equipped["Primary"], "first_pct")) / 100.0   # match rounds: a flat crit on the first (33)
	headshot += tree_sum("first_pct") / 100.0 if m["fresh"] else 0.0
	if m["fresh"] and yard_has("range_cards"):
		headshot += Data.FX["yard/range_cards"]                       # the Lookout's Range cards: the first shot on every gang half again
	if m["fresh"] and atlas_rank("marked_men") > 0:
		headshot += 0.25
	if m["fresh"] and has_rule("grandads"):
		headshot += Data.FX["rule/grandads"]
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
	var mult: float = pace() * t["pace"] * swing * headshot * sustain_mult(m) * dt
	var res: Dictionary = t.get("res", {})
	var per_type := type_dps()
	var landed_total := 0.0
	var crowd_on_you: int = mini(m["remaining"], contact(t))
	var held := gun_type()
	mult *= _joint_hit_mult(m, held)
	for ty in Data.TYPES:
		var r_ty: float = float(res.get(ty, 0.0))
		if ty == "physical":
			r_ty = phys_resist(r_ty)                  # Knuckles: the Doorman's knuckles and Bust them up get through their jackets
		var landed: float = float(per_type[ty]) * (1.0 - r_ty) * mult * ((1.0 + shock_amount()) if shocked else 1.0)
		if ty == "physical" and has_node("cap_shatter") and float(m.get("chill_t", 0.0)) > 0.0:
			landed *= Data.FX["node/cap_shatter"]                             # Shatter: a chilled target takes double from the physical
		if ty == "frost" and has_rule("gritters_keys") and float(m.get("chill_t", 0.0)) > 0.0:
			landed *= Data.FX["rule/gritters_keys"]                             # the Gritter's Keys: chilled, they take double frost
		if ty == "bleed" and has_node("cap_bleed_out"):
			landed *= Data.FX["node/cap_bleed_out"]                             # Bleed out: bleeds half again as hard
		var single := landed                      # what one of them takes, before a spread
		if has_node("melee_sweep"):
			landed *= crowd_on_you                # Through the lot: a swing hits everyone on you
		elif ty == "fire" and (has_node("fire_spread") or has_rule("weed_burner")):
			landed *= crowd_on_you                # Spreads: fire hits everyone on you
		if ty == "shock" and (has_node("shock_chain") or has_rule("jump_leads") or has_rule("substation_key")) and (m["fresh"] or shocked):
			landed *= crowd_on_you                # Live wire: shock on one of them is shock on all of them, while it holds
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
				m["chill_t"] = 999.0 if has_rule("gritters_keys") else status_s(1.0)    # the Gritter's Keys: a chill holds as long as you fire
			if ty == "shock":
				m["shock_t"] = 999.0 if (has_rule("tester") or has_node("cap_arc")) else status_s(1.0)     # Arc: the shock holds as long as you fire
	if has_rule("gritters_hopper"):
		m["chill_t"] = 1.0                        # everyone on you is chilled, always
	_joints_on_hit(m, t, landed_total, held, dt)
	m["target_hp"] -= landed_total
	var ticked_on_them := 0.0
	if m.has("dots"):
		if not m.has("dealt_by"):
			m["dealt_by"] = {}
		var tb := {}
		ticked_on_them = _dot_tick(m["dots"], dt, tb)
		if not m.has("ticked_by"):
			m["ticked_by"] = {}
		for ty in tb:
			m["dealt_by"][ty] = float(m["dealt_by"].get(ty, 0.0)) + tb[ty]
			m["ticked_by"][ty] = float(m["ticked_by"].get(ty, 0.0)) + tb[ty]     # the ticks apart from the hits, for the numbers (13 Oct)
		m["target_hp"] -= ticked_on_them
	m["dealt"] = float(m.get("dealt", 0.0)) + landed_total + ticked_on_them    # for the numbers on the run screen
	m["landed_rate"] = landed_total / maxf(dt, 0.001)                            # what landed this tick, a second: the top bar's damage line moves on it (8 Oct)
	# the rounds behind that: the primary's rate while it's live, the secondary's when it fires
	var primary_live := equipped["Primary"] != null and has_rounds(equipped["Primary"])
	if primary_live and not has_rule("qm_rifle"):
		_spend_rounds(equipped["Primary"], Items.base_of(equipped["Primary"])["rof"] * pace() * t["pace"] * dt)
	# the secondary spends what it fires: its full rate when it's the gun in
	# hand (the primary dry or gone, or Double tap), a third while it backs the primary
	if equipped["Secondary"] != null and has_rounds(equipped["Secondary"]):
		var share: float = secondary_share(primary_live)
		_spend_rounds(equipped["Secondary"], Items.base_of(equipped["Secondary"])["rof"] * pace() * t["pace"] * dt * share)
	var boss_on: bool = m.has("boss") and m["boss"]["started"] and m["boss"]["alive"]
	while m["target_hp"] <= 0.0 and m["remaining"] > 0:
		m["remaining"] -= 1
		if m["fresh"] and has_node("in_the_hide"):
			_guard_add(m, max_hp() * 0.15)       # In the hide: the first of a gang down
		m["fresh"] = false
		if boss_on:
			m["target_hp"] = 0.0
			_boss_down(m, t)
			boss_on = false
			if not m.get("boss_queue", []).is_empty():
				m["boss"] = m["boss_queue"].pop_front()     # the next of the convoy
				m["remaining"] = 0                           # comes out below
			break
		m["target_hp"] += t["hp"]
		m.erase("opened")                    # the Starting Pistol: the next of them has its own first shot
		m["kill_shocked"] = float(m.get("shock_t", 0.0)) > 0.0
		m["kill_burning"] = float(m.get("dots", {}).get("fire", 0.0)) > 0.0
		if has_node("cap_flattened") and float(type_dps().get("physical", 0.0)) > 0.0:
			m["flat_t"] = Data.FX["node/cap_flattened"]                        # Flattened: the plain put them down; the next of them fire at half for two seconds
		m.erase("full_dose")
		var carried := {}
		if (has_rule("rat_mans_bag") or has_node("cap_lingers")) and m.get("dots", {}).has("poison"):
			carried["poison"] = m["dots"]["poison"]  # the Rat Man's Bag, or Lingers: poison carries to the next
		if (has_rule("butchers_steel") or has_rule("butchers_apron") or has_node("cap_bleed_out")) and m.get("dots", {}).has("bleed"):
			carried["bleed"] = m["dots"]["bleed"]
		if has_node("cap_spread") and m.get("dots", {}).has("fire"):
			carried["fire"] = m["dots"]["fire"]      # Spread: the burn carries
		m["dots"] = carried                  # the next of them is a new target
		m["chill_t"] = 0.0
		m["shock_t"] = 0.0
		_kill(m, t)
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
			log_event("%s comes out%s. %s" % [m["boss"]["name"], ", at full strength" if m["boss"].get("pinnacle", false) else "", Words.BOSSES.get(m["boss"]["name"], {}).get("out", "")])
			return
		m["target_hp"] = 0.0
		m["last_incoming"] = 0.0
		if m.has("t_home"):
			m["t"] = m["t_home"]               # the harder gang down (B9): the site's own again
			m.erase("t_home")
		m["my_dots"] = {}                    # the picking over: nothing ticks on you
		if not m["cleared"] or m.get("ghost_pending", false):
			m["ghost_pending"] = false
			_clear(m, t)                     # a Ghost's clear is the first gang beaten
		return
	var on_you := mini(m["remaining"], contact(t))
	var chilled: bool = float(m.get("chill_t", 0.0)) > 0.0
	var incoming: float = incoming_rate(t, on_you, chilled) * rng.randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	if boss_on:
		on_you = 1
		incoming = incoming_rate({"dps": m["boss"]["dps"], "types": t.get("types", {})}, 1, chilled) * rng.randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	if m["fresh"] and has_rule("underlay"):
		m["grace"] = float(m.get("grace", 0.0)) + dt
		if m["grace"] <= 2.0:
			incoming = 0.0                     # the first two seconds of a gang land on the underlay
	elif not m["fresh"]:
		m["grace"] = 0.0
	if on_you >= 3 and has_node("bodyline"):
		incoming *= Data.FX["node/bodyline"]
	if on_you >= 3:
		incoming *= 1.0 - _affix_sum("crowd_less_pct") / 100.0
	if on_you >= 3 and has_rule("doormans"):
		incoming *= Data.FX["rule/doormans"]
	incoming *= _joints_on_incoming(m, chilled, dt)
	if float(m.get("immune_t", 0.0)) > 0.0:
		incoming = 0.0                                  # Clean hands: nothing lands for a while after a med
	# what their fire leaves on you: a share of the elemental part burns, poisons, bleeds, and ticks while the fight's on
	if not m.has("my_dots"):
		m["my_dots"] = {}
	var their_types: Dictionary = t.get("types", {})
	for ty in ["fire", "poison", "bleed"]:
		var share := float(their_types.get(ty, 0.0))
		if share > 0.0 and incoming > 0.0:
			_dot_add(m["my_dots"], ty, incoming * share * dt, incoming * share)
			if ty == "poison" and has_rule("gamekeepers_flask"):
				if not m.has("dots"):
					m["dots"] = {}
				_dot_add(m["dots"], "poison", incoming * share * dt, incoming * share)   # poisons them back
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
	var tick_total := 0.0
	for ty in tick_by:
		tick_total += float(tick_by[ty])
	var reached: float = on_hp / maxf(tick_total, 0.000001)     # over what the types made, so Held's cut is out of them too (the review)
	for ty in tick_by:
		m["taken_by"][ty] = float(m["taken_by"].get(ty, 0.0)) + float(tick_by[ty]) * reached
	if above and hp > 0.0 and hp < max_hp() * Data.WOUND_AT and not m.get("dry", false):
		_wound(m)                            # the hit that took them under a quarter leaves a wound (30); never a dry run's, which restores hp but not the wound
		if auto_tier >= 0 and not yard_has("whistle"):
			auto_tier = -1                   # auto-run stops on a wound: the Clinic is a decision, not a silent tax (the Lookout's whistle: not)
			log_event("Auto-run stopped: wounded")
	if hp <= 0.0:
		if has_node("not_today") and not m.get("saved", false):
			m["saved"] = true
			hp = max_hp() * 0.5
			log_event("Not today: back up on half HP")
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
	var f := 1.0
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
	if float(m.get("flat_t", 0.0)) > 0.0:
		m["flat_t"] = maxf(0.0, float(m["flat_t"]) - dt)
		f *= 0.5                                  # Flattened: the next of them fire at half
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


## The Paramedic's dose, joined: a med used is a full stack of poison on the gang.
func _dose(m: Dictionary) -> void:
	_dot_fill(m, "poison")
	m["dosed"] = int(m.get("dosed", 0)) + 1


## What a med heals this runner, before the max HP caps it: its own figure through the past, the trait, the trees,
## the nodes, the rules, the set and the Yard. The rig's hover, the pick panel and the heal itself all read this.
func med_heal(it: Dictionary) -> float:
	return Items.heal(it) * cm("heal") * trait_mult("heal") * (1.0 + tree_sum("heal_pct") / 100.0) * (Data.FX["node/walking_wounded.heal"] if has_node("walking_wounded") else 1.0) * (Data.FX["rule/ladle.med_heal"] if has_rule("ladle") else 1.0) * (Data.FX["set/ambulance.heal"] if has_set_rule("ambulance") else 1.0) * (Data.FX["yard/med_lab"] if yard_has("med_lab") else 1.0) * (Data.FX["rule/paramedics_bumbag"] if has_rule("paramedics_bumbag") else 1.0)


## A med in words: "+42 HP over 3 s" (at once with Field surgery).
func med_words(it: Dictionary) -> String:
	var t := use_time(it)
	return "+%d HP %s" % [int(round(med_heal(it))), ("over %s s" % (("%.1f" % t) if t < 10.0 and t != floorf(t) else "%d" % int(t))) if t > 0.0 else "at once"]


## Using a med: the seconds run down under whatever fire there is, then it heals.
func use_med(id: int) -> bool:
	if mission == null or mission["using"] != null or mission["t"].get("no_meds", false):
		return false                          # the Radio's Rationed: no meds on the run
	for k in range(rig.size()):
		if rig[k]["id"] == id:
			var it: Dictionary = rig[k]
			if has_rule("ambulance_bag"):
				pass                           # the Ambulance's Bag (a mythic): never used up
			elif (has_node("second_shift") or has_set_rule("ambulance")) and not mission.get("free_med", false):
				mission["free_med"] = true     # the first med of the run isn't spent
			else:
				rig.remove_at(k)
			mission["using"] = {"name": it["base"], "left": use_time(it), "heal": med_heal(it), "overflow": Items.affix_total(it, "overflow_pct") / 100.0}
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
	var single: float = 80.0 * (1.0 + increased("fire") / 100.0) * more("fire") * (1.0 - r) * ((1.0 + shock_amount()) if float(m.get("shock_t", 0.0)) > 0.0 else 1.0)
	var crowd: int = mini(m["remaining"], contact(t))
	m["target_hp"] -= single * crowd
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
		var single: float = float(b["damage"]) * (1.0 + increased(ty) / 100.0) * more(ty) * (1.0 - r) * ((1.0 + shock_amount()) if float(m.get("shock_t", 0.0)) > 0.0 else 1.0)
		if ty == "bleed" and has_node("cap_bleed_out"):
			single *= Data.FX["node/cap_bleed_out"]                     # Bleed out: a nail bomb's bleed, half again too
		var crowd: int = mini(m["remaining"], contact(t))
		var landed: float = single * crowd
		rig.remove_at(k)
		m["target_hp"] -= landed
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
		log_event("%s thrown: %.0f %s to %d of them" % [it["base"], landed, ty, crowd])
		return true
	return false


func _patch(m: Dictionary, dt: float) -> void:
	if m["using"] == null:
		return
	m["using"]["left"] -= dt
	if has_node("overtime") and float(m.get("guard", 0.0)) > 0.0:
		m["using"]["left"] -= dt                 # Overtime: with Guard up, a med takes half the time
	if m["using"]["left"] <= 0.0 or has_node("field_surgery"):
		var hp_was := hp
		_heal(m, m["using"]["heal"] * (Data.FX["joint/paramedic_frost.heal"] if (has_joint("paramedic_frost") and float(m.get("chill_t", 0.0)) > 0.0) else 1.0), true, float(m["using"].get("overflow", 0.0)))
		if has_node("cap_transfusion"):
			m["guard"] = guard_cap()             # Transfusion: a med fills Guard to the top
		m["using"]["gained"] = hp - hp_was     # what it healed, after the max HP caps it (the log's figure)
		if has_joint("paramedic_poison") and m["remaining"] > 0:
			_dose(m)                         # the Paramedic's dose, joined: the med's a full stack of poison on them
		if m.has("my_dots"):
			m["my_dots"].erase("bleed")      # a dressing stops the bleeding
		if has_node("cap_clean_hands"):
			m["my_dots"] = {}                # Clean hands: everything on you cleared, and a grace
			m["immune_t"] = 3.0
		if has_rule("arsonists_rig") and m["remaining"] > 0:
			_alight(m)                       # the Arsonist's Rig: the med's a petrol bomb's worth on everyone on you
		m["meds_used"] += 1
		log_event("%s used: +%d HP (%d of %d)" % [m["using"]["name"], int(round(float(m["using"].get("gained", 0.0)))), ceili(hp), ceili(max_hp())])
		m["using"] = null


func _kill(m: Dictionary, t: Dictionary) -> void:
	m["kills"] += 1
	_heal(m, _affix_sum("life_per_kill") + (max_hp() * Data.FX["rule/keepers_gun"] if has_rule("keepers_gun") else 0.0) + (max_hp() * Data.FX["rule/ladle.kill_heal"] if has_rule("ladle") else 0.0) + (max_hp() * Data.FX["node/cap_iron"] if has_node("cap_iron") and hp < max_hp() * 0.5 else 0.0))
	if m.get("dry", false):
		return                               # a dry run: the fight only, nothing earned
	var gain: float = t["xp"] * (Data.FX["node/hit_and_run.kill_pay"] if has_node("hit_and_run") else 1.0) * (Data.MYTHIC_PAY if has_rule("freedom") else 1.0)
	m["xp"] += gain
	var before := level()
	xp += gain
	_earn_points(before)
	var pay := 1.0 if not has_node("hit_and_run") else 1.5
	m["cash"] += (0.0 if t.get("no_kill_cash", false) else 1.0) * (t["cash"] * rng.randf_range(0.5, 1.5) * (1.0 + (tree_sum("cash_pct") + charm_cash()) / 100.0) + _affix_sum("cash_per_kill")) * inflation() * pay * (Data.FX["rule/bookies_pencil.cash"] if has_rule("bookies_pencil") else 1.0) * (Data.FX["set/bank.kill_cash"] if has_set_rule("bank") else 1.0) \
		* (Data.FX["node/light_fingers.cash"] if has_node("light_fingers") else 1.0) * (Data.FX["rule/managers_coat"] if has_rule("managers_coat") else 1.0) * trait_mult("cash") * (Data.MYTHIC_PAY if has_rule("freedom") else 1.0)
	if not has_rule("managers_coat"):
		m["notes"] = int(m.get("notes", 0)) + notes_a_kill(t) * (int(Data.MYTHIC_PAY) if has_rule("freedom") else 1)
	var dd: int = int(t.get("depth", 1))
	var kind: String = Data.ZONE_SALVAGE[int(Data.TIERS[int(t["tier"])]["zone"])]
	if kind != "" and dd >= Data.SALVAGE_DEPTH and rng.randf() < Data.SALVAGE_KILL * (dd - Data.SALVAGE_DEPTH + 1):
		m["salvage"] = m.get("salvage", {})
		m["salvage"][kind] = int(m["salvage"].get(kind, 0)) + 1      # the deep sites' salvage (9 Oct), home with the run
	if has_node("quiet_hands"):
		return
	if has_node("nothing_wasted") or (has_joint("scrapper_fire") and m.get("kill_burning", false)) or rng.randf() < t["drop"] * (1.0 + loot_bonus()) * (Data.FX["node/loud.drop"] if has_node("loud") else 1.0) * (1.0 + Data.FX["atlas/their_own_kit"] * atlas_rank("their_own_kit")) * pay:
		if has_rule("qm_ledger"):
			var up: Dictionary = t.duplicate()
			up["loot_tier"] = mini(loot_cap(int(t.get("level", lv_at(int(t["tier"]), int(t["depth"]))))), int(t["loot_tier"]) + 1)     # signed for: a tier up
			_find(m, up, true)
		else:
			_find(m, t, true)


## The old paper money: every kill carries some, more the deeper you are.
func notes_a_kill(t: Dictionary) -> int:
	return (int(ceil(Data.NOTES_KILL * (1.0 + (int(t["depth"]) - 1) / 3.0) * (1.0 + _affix_sum("notes_pct") / 100.0))) + atlas_rank("paid_in_notes")) * (Data.FX["rule/wardens_hat.notes"] if has_rule("wardens_hat") else 1)


## The crew's head is down: their drop, the notes they held, the zone's boss beaten.
func _boss_down(m: Dictionary, t: Dictionary) -> void:
	var b: Dictionary = m["boss"]
	b["alive"] = false
	m["kills"] += 1
	if m.get("dry", false):
		return
	m["xp"] += t["xp"] * 10.0
	var before := level()
	xp += t["xp"] * 10.0
	_earn_points(before)
	m["cash"] += (0.0 if t.get("no_kill_cash", false) else 1.0) * t["cash"] * 10.0 * inflation()     # the Radio's Overdrawn: no cash off the head either
	m["notes"] = int(m.get("notes", 0)) + int(round(Data.NOTES_BOSS * int(t["depth"]) * (1.0 + Data.FX["atlas/bounties"] * atlas_rank("bounties"))))
	if str(b.get("order", "")) != "":
		_order_down(m, t, b)                  # the order's true pinnacle: their own drops, none of a crew's
		return
	_head_materials(m)                        # the rebuild (18 Oct): a head's handful of the site's material
	if b.get("pinnacle", false) and atlas_rank("head_start") > 0:
		atlas_points += 1                     # Head start: a head beaten at full strength pays a map point
		log_event(Words.MAP["head_start"] % b["name"])
	var first: bool = not bosses_beaten[int(b["zone"])]
	chron("boss", {"name": str(b["name"]), "zone": int(b["zone"]), "tier": int(m["tier"]), "depth": int(t.get("depth", 1)), "first": first,
		"pinnacle": bool(b.get("pinnacle", false)), "convoy": bool(m.get("convoy", false))})
	bosses_beaten[int(b["zone"])] = true
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
		m["found"].append(ld)
		_read(ld)
		log_event("The convoy's done. Found: %s." % ld["unique"])
		if not lorry_done:
			lorry_done = true
			lorries += 1
			chron("lorry", {"lorries": lorries})
			log_event(Words.YARD["lorry"])
	if not pool.is_empty():
		var it := Items.roll_unique(pool[rng.randi_range(0, pool.size() - 1)], rng, int(t.get("level", -1)), int(t["loot_tier"]))     # at the depth he's fought at (12 Oct)
		m["found"].append(it)                  # theirs comes home whatever the pack holds
		_read(it)
		log_event("%s is down. %s Found: %s." % [b["name"], Words.BOSSES.get(b["name"], {}).get("down", ""), it["unique"]])
		if atlas_rank("two_of_everything") > 0:
			var it2 := Items.roll_unique(pool[rng.randi_range(0, pool.size() - 1)], rng, int(t.get("level", -1)), int(t["loot_tier"]))
			m["found"].append(it2)
			_read(it2)
			log_event("And a second: %s." % it2["unique"])
	if pool.is_empty():
		log_event("%s is down. %s" % [b["name"], Words.BOSSES.get(b["name"], {}).get("down", "")])     # a head with no unique of his own (the Gamekeeper)
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
				log_event("Found: %s" % thing["base"])
				m["found"].append(thing)          # in the pack to see, a keepsake home (15 Oct): the room opens here, the thing goes to the drawer
			_home_gate(thing)
	if first and campaign_done():
		log_event(Words.YARD["campaign"])


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


## The Garden Centre's first clear (17 Oct): one of Data.FIRST_GUNS, plain, and a box of its rounds, in the pack whatever
## the room - the step every save gets.
func _first_gun(m: Dictionary) -> void:
	var pick: Array = Data.FIRST_GUNS[rng.randi_range(0, Data.FIRST_GUNS.size() - 1)]
	var gun: Dictionary = _plain(str(pick[0]), str(pick[1]))
	gun["first_gun"] = true                   # kept by a full pack like the deeds (_pack_keeps); the mark comes off at home
	m["found"].append(gun)
	var box := {}
	for b in Data.BASES[Data.AMMO]:
		if str(b["type"]) == Items.ammo_type(gun) and int(b["tier"]) == 1:
			box = _plain(Data.AMMO, str(b["name"]))
			box["first_gun"] = true
			break
	if not box.is_empty():
		m["found"].append(box)
	log_event(Words.FIRST_GUN % [Words.a_thing(str(gun["base"])), str(box.get("base", "rounds")).to_lower()])
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
	var owned: Array = owned_ammo_types(m) if slot == Data.AMMO else []
	if slot == Data.AMMO and owned.is_empty():
		slot = gear_slot                      # rounds for no gun you have (17 Oct, Matt's playtest: three boxes, no gun): something else instead
	var said := ""
	var quality: float = rarity_bonus() + float(t.get("rarity", 0.0)) + float(crate.get("rarity", 0.0))
	var it: Dictionary
	var loose: Array = loose_at(int(t["depth"]), int(t["loot_tier"]))     # those whose range takes the find's tier (12 Oct)
	var pieces: Array = set_pieces_at(int(t["depth"]))
	var own: Dictionary = site_unique(int(t["tier"]))
	var own_odds: float = Data.SITE_UNIQUE_DROP * (1.0 if own.is_empty() or not (own["name"] in shelf) else Data.SITE_UNIQUE_AGAIN)
	var myth: Dictionary = mythic_roll()
	var find_lv: int = int(t.get("level", lv_at(int(t["tier"]), int(t["depth"]))))
	var find_tier: int = int(t["loot_tier"])
	if slot in Data.SLOTS and rng.randf() < Data.FIND_AT_MINE and wearable_level() < find_lv:
		# a fifth of the plain gear at the level the runner wears (16 Oct), on a base the campaign gives - as a gamble
		# rolls: a deep signal's tier-7+ bases stay the deep runner's (the review)
		find_lv = wearable_level()
		find_tier = mini(find_tier, gear_tier())
	if not myth.is_empty():
		it = Items.roll_unique(myth, rng, int(t.get("level", -1)), int(t["loot_tier"]))     # a mythic: one find in MYTHIC_ODDS_IN, anywhere
		said = Words.MYTHIC_FOUND % it["unique"]
	elif not own.is_empty() and int(t["depth"]) >= site_unique_depth(int(t["tier"])) and rng.randf() < own_odds:
		it = Items.roll_unique(own, rng, int(t.get("level", -1)), int(t["loot_tier"]))     # the site's own, only here and only this deep (endgame part 3), at the find's tier
		said = "Found: %s. %s" % [it["unique"], Words.SHELF["own_found"] % site["name"]]
	elif not loose.is_empty() and rng.randf() < minf(Data.UNIQUE_CAP, unique_odds(t) * float(crate.get("unique", 1.0))):     # a Safe's double, inside the cap (the review)
		it = Items.roll_unique(pick_unique(loose, int(t["loot_tier"])), rng, int(t.get("level", -1)), int(t["loot_tier"]))     # the band's weight picks
		said = "Found: %s" % it["unique"]
	elif t["depth"] >= 2 and not pieces.is_empty() and rng.randf() < minf(Data.SET_CAP, Data.SET_DROP * (t["depth"] - 1)):
		var pick: Array = pieces[rng.randi_range(0, pieces.size() - 1)]
		it = Items.roll_set_piece(pick[0], pick[1], rng, int(t.get("level", -1)))
		said = "Found: %s, %s" % [it["piece"], str(pick[0]).to_lower()]
	else:
		# quality decides the rarity: the trees', the charm's and the intel's; quantity is how much, not how good (27)
		it = Items.roll(slot, 1 if slot == Data.PAPER else find_tier, rng, quality, has_node("all_or_nothing"), has_rule("lucky_cap"),
			site["name"], str(site["drops"].get("type", "")), Data.FX["atlas/picked_over.base"] + Data.FX["atlas/picked_over"] * atlas_rank("picked_over"), int(t["depth"]), find_lv)
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
	if from_kill and m.get("kill_shocked", false) and has_joint("drifter_shock") and slot in Data.SLOTS and not it.has("unique") and not it.has("set") and not Items.is_deeds(it):
		var twice: Dictionary = Items.roll(slot, 1 if slot == Data.PAPER else find_tier, rng, quality, has_node("all_or_nothing"), has_rule("lucky_cap"),
			site["name"], str(site["drops"].get("type", "")), Data.FX["atlas/picked_over.base"] + Data.FX["atlas/picked_over"] * atlas_rank("picked_over"), int(t["depth"]), find_lv)
		if int(twice.get("rarity", 0)) > int(it.get("rarity", 0)):
			it = twice                       # the Drifter's leads, joined: a shocked kill's drop rolls its rarity twice
	if has_node("cap_loaded_dice") and int(it.get("rarity", 0)) >= 2 and not it.has("unique") and not it.has("set") and slot != Data.PAPER:
		var again: Dictionary = Items.roll(slot, 1 if slot == Data.PAPER else find_tier, rng, quality, has_node("all_or_nothing"), has_rule("lucky_cap"),
			site["name"], str(site["drops"].get("type", "")), Data.FX["atlas/picked_over.base"] + Data.FX["atlas/picked_over"] * atlas_rank("picked_over"), int(t["depth"]), find_lv)
		if Items.score(again) > Items.score(it):
			it = again                       # Loaded dice: a Rare or better rolls twice, keeps the better
	if capture:
		return {"it": it, "said": said}
	var shown: Dictionary = it.duplicate(true)     # as found: landing joins a stack and leaves the find's own count at what was left over
	_land(m, it, said, not from_kill and not crate.is_empty() and by_hand(m))
	return {"it": shown, "said": said}


## A find rolled, into the pack - or onto the floor, a search's by hand (13 Oct) - its line in the log, and a gun's box
## of rounds while the Fence is shut.
func _land(m: Dictionary, it: Dictionary, said := "", to_floor := false) -> void:
	if said != "":
		log_event(said)
	if to_floor:
		m["floor"] = m.get("floor", [])
		m["floor"].append(it)
	else:
		_place_find(m, it)
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
## nothing's swapped without the player (in the fight, before the floor's on screen, the auto-run's rule); on an
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
	if pack_used(m) + Items.size(it) <= capacity():
		m["found"].append(it)
		_read(it)
		return
	if by_hand(m) and m.has("crates"):
		m["floor"] = m.get("floor", [])
		m["floor"].append(it)                 # the player's to take, or leave - once the search is on and the floor's on screen (the review)
		return
	if not _pack_keeps(it):
		m["left"] += 1
		return
	var cheapest := -1
	for k in range(m["found"].size()):
		var f: Dictionary = m["found"][k]
		if Items.size(f) >= Items.size(it) and not _pack_keeps(f) and Items.opens(f) == "" and (cheapest < 0 or f["value"] < m["found"][cheapest]["value"]):
			cheapest = k
	if cheapest >= 0:
		m["found"][cheapest] = it
		m["swapped"] = m.get("swapped", 0) + 1
		_read(it)
	elif it.get("mythic", false):
		m["found"].append(it)                 # a mythic with nothing its size to make way (17 Oct): in over the pack's size, as a head's uniques come home
		_read(it)
	else:
		m["left"] += 1


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
	_wearing_off(m)
	worn[m["tier"]] = elapsed
	worn_depth[m["tier"]] = depth[m["tier"]]
	var bonus: float = t["xp"] * t["pool"] * Data.CLEAR_BONUS * (Data.FX["node/stand"] if has_node("stand") else 1.0) * (Data.MYTHIC_PAY if has_rule("freedom") else 1.0)
	m["xp"] += bonus
	var before := level()
	xp += bonus
	_earn_points(before)
	best_tier = maxi(best_tier, mini(Data.TIERS.size() - 1, m["tier"] + 1))
	var cd: int = int(depth[m["tier"]])     # the site's own depth: a signal's t["depth"] is its level's on the Barracks (D3), not this site's (D14 review)
	var first_clear: bool = not seen.has("cleared/%d" % m["tier"])
	if m.has("signal") and m["signal"].has("order"):
		cd = 0                                # the order's run (18 Oct): no depth, no best signal, no Yard column; the reach is the signals'
	if first_clear or cd > best_depth[m["tier"]]:
		chron("clear", {"tier": int(m["tier"]), "site": str(tier(m["tier"])["name"]), "depth": int(cd), "first": first_clear,
			"site_level": int(t.get("level", 0)), "dps": snappedf(dps(), 0.1), "kit": loadout_value()})
	if cd > best_depth[m["tier"]]:
		best_depth[m["tier"]] = cd
		if cd >= 2 and int(m["tier"]) >= Data.OUTSKIRTS_SITES and not m.has("signal"):     # the map's points from the Streets on (12 Oct); a signal's are its reach's (15 Oct)
			atlas_points += 1
	if cd >= 2 and int(m["tier"]) >= Data.OUTSKIRTS_SITES and (cd > int(best_dig.get("depth", 0)) or (cd == int(best_dig.get("depth", 0)) and m["tier"] > int(best_dig.get("tier", -1)))):
		best_dig = {"site": t["name"], "tier": m["tier"], "depth": cd, "yard": yard_moves + 1}     # the ladder's, not the campaign's
	if m["tier"] == Data.OUTSKIRTS_SITES + 2 and not depot_cleared:     # the Retail Park: the slice's win (index 5 since the Outskirts)
		depot_cleared = true
	if not seen.has("cleared/%d" % m["tier"]):
		seen["cleared/%d" % m["tier"]] = true
		log_event(Words.site_cleared(t["name"]))
	else:
		log_event("%s cleared. Picking it over; more will come." % t["name"])
	if int(m["tier"]) == Data.FIRST_GUN_SITE and not seen.has("first_gun_home") and owned_ammo_types(m).is_empty():
		_first_gun(m)                         # until one's home (the review: a first clear's gun lost to a time-out would never come again)
	# the deeds come off the Manager now, not the Bank's first clear (13 Oct, Matt): see the boss's things
	if not m.has("crates"):
		_roll_crates(m, t)                    # the search: the site's crates, in the dice's order (13 Oct); a Ghost's rolled at its first search


## The searches a cleared site's crates add up to (29; the crates since 13 Oct): by depth, and quantity pushes it.
func thin_after(t: Dictionary) -> int:
	var n: float = Data.THIN_AFTER + Data.THIN_PER_DEPTH * int(t["depth"])
	return int(roundf(n * (1.0 + maxf(0.0, loot_bonus()))))


## The lookout's top level (31): the first gang after the clear waits for the call, and the call is a full pack.
func gang_held(m: Dictionary) -> bool:
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
	m["crate_i"] = 0
	if dog_sniffs():
		for q in queue:
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
	while m["search"] >= every:
		m["search"] -= every
		m["searches"] += 1
		var cd: Dictionary = {} if cr.is_empty() else crate_for(cr)
		if has_node("sheet_metal"):
			_guard_add(m, max_hp() * 0.06)       # Sheet metal: every cache searched
		if rng.randf() < Data.NOTES_SEARCH * float(cd.get("notes", 1.0)):
			m["notes"] = int(m.get("notes", 0)) + rng.randi_range(1, 2)
		if rng.randf() < Data.SCRAP_SEARCH * float(cd.get("scrap", 1.0)):
			m["scrap"] = int(m.get("scrap", 0)) + rng.randi_range(Data.SCRAP_HANDFUL[0], Data.SCRAP_HANDFUL[1])     # a handful of scrap (34)
		if cd.get("tins", false):
			m["cash"] += float(t["cash"]) * rng.randf_range(0.5, 2.0) * inflation()     # a safe: a handful of tins (the pass, 13 Oct: 1-3 read the Bank 17% over)
		var finds: int = 1 + (1 if (has_node("scavenger") or has_node("quiet_hands")) else 0) + (Data.FX["yard/a_dog"] if yard_has("a_dog") else 0) + (Data.FX["yard/pack"] if yard_has("pack") else 0) + (Data.FX["rule/postman"] if has_rule("postman") else 0) + (Data.MYTHIC_SEARCH_FINDS if has_rule("removal_van") else 0)
		if atlas_rank("second_look") >= 2 or (atlas_rank("second_look") == 1 and int(m["searches"]) % 2 == 0):
			finds += 1                        # Second look: one more every other search, then every search
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
				log_event("%s picked clean: every crate open" % t["name"])
				return


## Drop something from the pack mid-run to make room: the cheapest thing, or
## every common. What's dropped is gone.
func cheapest_in_pack() -> Dictionary:
	if mission == null or mission["found"].is_empty():
		return {}
	var pick: Dictionary = mission["found"][0]
	for it in mission["found"]:
		if it["value"] < pick["value"]:
			pick = it
	return pick


func ditch(id: int) -> bool:
	if mission == null:
		return false
	for k in range(mission["found"].size()):
		if mission["found"][k]["id"] == id:
			var it: Dictionary = mission["found"][k]
			mission["found"].remove_at(k)
			mission["ditched"] = int(mission.get("ditched", 0)) + 1
			if Items.is_deeds(it):
				deeds_fate = "burned"
				log_event(Words.DEEDS["burned"])
			else:
				var bits: int = scrap_of(it)
				mission["scrap"] = int(mission.get("scrap", 0)) + bits     # ditched for scrap (34): what comes home of it
				log_event("Ditched: %s%s" % [it["base"].to_lower(), (", %d scrap" % bits) if bits > 0 else ""])
				# onto the floor (13 Oct): it can be taken back while you're there, the scrap with it
				it["ditch_scrap"] = bits
				mission["floor"] = mission.get("floor", [])
				mission["floor"].append(it)
			return true
	return false


func ditch_commons() -> int:
	if mission == null:
		return 0
	var n := 0
	for it in mission["found"].duplicate():
		if it["rarity"] == 0 and not Items.is_paper(it) and ditch(it["id"]):     # nor the papers, the endgame's keys (15 Oct)
			n += 1
	return n


# ------------------------------------------------------------------ the floor (13 Oct, Matt)

## A search's finds by hand: on the floor, for the player to take - not on an auto-run, "Fill up, then go", away,
## a dry run, or for the bot.
func by_hand(m: Dictionary) -> bool:
	return loot_by_hand and auto_tier < 0 and not m.get("leave_full", false) and not away_on and not m.get("dry", false)


func floor_items() -> Array:
	return mission.get("floor", []) if mission != null else []


## Whether a thing on the floor goes in the pack: a cell for it, or a stack it joins.
func floor_fits(it: Dictionary) -> bool:
	if mission == null:
		return false
	if pack_used(mission) + Items.size(it) <= capacity():
		return true
	if Items.stacks(it):
		for f in mission["found"]:
			if Items.same_stack(f, it) and Items.stack_size(f) < Items.stack_cap(f):
				return true
	return false


## Off the floor into the pack: only if it fits (no swapping - the player chose it); a stack joins what it can, the rest
## stays down. A thing ditched comes back with its scrap.
func take_floor(id: int) -> bool:
	if mission == null:
		return false
	var fl: Array = floor_items()
	for k in range(fl.size()):
		if int(fl[k]["id"]) != id:
			continue
		var it: Dictionary = fl[k]
		if not floor_fits(it):
			return false
		if it.has("ditch_scrap") and Items.stacks(it) and pack_used(mission) + Items.size(it) > capacity():
			var room := 0
			for f in mission["found"]:
				if Items.same_stack(f, it):
					room += maxi(0, Items.stack_cap(f) - Items.stack_size(f))
			if room < Items.stack_size(it):
				return false                      # a ditched stack comes back whole or not at all: its scrap with it (the review)
		if Items.stacks(it):
			for f in mission["found"]:
				if Items.same_stack(f, it) and Items.stack_size(f) < Items.stack_cap(f):
					var moved: int = mini(Items.stack_cap(f) - Items.stack_size(f), Items.stack_size(it))
					Items.set_stack(f, Items.stack_size(f) + moved)
					Items.set_stack(it, Items.stack_size(it) - moved)
			if Items.stack_size(it) <= 0:
				fl.remove_at(k)
				_untake_scrap(it)
				return true
			if pack_used(mission) + Items.size(it) > capacity():
				return true                       # some joined; the rest stays on the floor
		fl.remove_at(k)
		mission["found"].append(it)
		_untake_scrap(it)
		_read(it)
		return true
	return false


func _untake_scrap(it: Dictionary) -> void:
	if it.has("ditch_scrap"):
		mission["scrap"] = maxi(0, int(mission.get("scrap", 0)) - int(it["ditch_scrap"]))
		it.erase("ditch_scrap")


## Everything on the floor that fits, the dearest first: "Fill up, then go" picks up what was left down.
func take_all() -> int:
	var n := 0
	var fl: Array = floor_items().duplicate()
	fl.sort_custom(func(a, b): return int(a["value"]) > int(b["value"]))
	for it in fl:
		if not it.has("ditch_scrap") and take_floor(int(it["id"])):
			n += 1
	return n


## Leave now with what's been found. Pressed by hand, it also ends an auto-run:
## a manual extract is the player taking the wheel back.
## Whether the runner can leave now: Stand and fight holds them until the clear.
func can_extract() -> bool:
	return mission != null and (mission["cleared"] or not has_node("stand"))


func extract_now() -> void:
	if mission != null and can_extract():
		if auto_tier >= 0:
			auto_tier = -1
			log_event("Auto-run stopped")
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
	if auto_tier >= 0:
		auto_tier = -1
		log_event("Auto-run stopped")
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
	var size: int = maxi(1, PATROL_BASE - (Data.FX["node/trapline.heads"] if has_node("trapline") else 0) + (Data.FX["node/loud.gang"] if has_node("loud") else 0) - (Data.FX["rule/wardens_hat.gang"] if has_rule("wardens_hat") else 0))
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
	log_event("Making for the way out, %d at the door" % size)


## The door's gang down: out with the pack.
func _seen_off(m: Dictionary) -> void:
	m["seen_off"] = true
	log_event("Seen off at the door. Out with the pack.")
	_extract()


func stop_auto() -> void:
	if auto_tier >= 0:
		auto_tier = -1
		log_event("Auto-run stopped; this run goes on")


func _extract() -> void:
	if mission != null and mission.get("dry", false):
		return
	var m: Dictionary = mission
	_floor_mythics_in(m)
	var t := tier(m["tier"])
	var timed_out: bool = m.get("timed_out", false)
	if m.get("ghost_pending", false) and (pack_used(m) >= capacity() or crates_done(m)) and not timed_out:     # a site picked clean is a Ghost's clear too (13 Oct)     # out of time is no clear, kept pack or not
		m["ghost_pending"] = false
		_clear(m, m["t"])                     # Ghost: a full pack brought home is the clear (the site as deployed to, its depth with it)
		log_event("Ghost: the pack's full, and %s counts as cleared" % Words.mid(t["name"]))
	m["left"] = int(m["left"]) + m.get("floor", []).filter(func(x): return not x.has("ditch_scrap")).size()     # what was left on the floor: passed over
	m["cash"] += _affix_sum("cash_per_cell") * pack_used(m) * inflation()
	if has_node("cap_the_lot") and pack_used(m) >= capacity() and not timed_out:
		m["cash"] *= Data.FX["node/cap_the_lot"]                      # The lot: a full pack pays double
	if has_rule("issuers_robes"):
		m["cash"] *= 1.0 + town_worth() / 100.0                      # the Issuer's Robes: +1% a point of the town's worth
	m["cash"] += mint_tins()                                         # the mint (18 Oct): the town's worth pays on every run home
	_bank_materials(m)
	_earn(float(m["cash"]))
	var base0: float = a_gamble_base()
	gamble_base = clampf(lerp(base0, _takings_run, 0.25), base0 * (1.0 - Data.GAMBLE_STEP), base0 * (1.0 + Data.GAMBLE_STEP))     # before takings moves: the first run starts from its stand-in
	takings = _takings_run if takings <= 0.0 else lerp(takings, _takings_run, 0.25)     # a run's takings: this run's cash and the Fence's money since the last
	_takings_run = 0.0
	scrap += int(m.get("scrap", 0))       # the run's scrap comes home (34)
	var sv: Dictionary = m.get("salvage", {})
	for kind in sv:
		salvage[kind] = int(salvage.get(kind, 0)) + int(sv[kind])      # and its salvage (9 Oct)
	var run_notes: int = int(m.get("notes", 0))
	if has_rule("lorrys_load"):
		run_notes += maxi(0, capacity_raw() - pack_used(m)) * int(m["t"]["depth"])     # every empty cell is notes
	if has_rule("managers_pen"):
		run_notes *= Data.FX["rule/managers_pen"]
	if has_rule("drivers_log"):
		run_notes *= Data.FX["rule/drivers_log"]
	notes += run_notes
	if yard_has("bins"):
		m["found"] = _bin_commons(m["found"])     # the Stash's Bins: the run's commons to scrap before they're stashed
	var stashed := 0
	for it in m["found"]:
		var first: bool = it.get("first_gun", false) and Items.is_gun(it)
		it.erase("first_gun")
		if first:
			stash.append(it)                  # the first gun comes home whatever the room, as a mythic does, and it's home: no more (17 Oct)
			seen["first_gun_home"] = true
			stashed += 1
			continue
		if it.get("from_rig", false):
			# the runner's own rounds, moved to the pack on the run: back to the rig when there's a pouch, else the
			# stash, never loot (the review: a full stash dropped them without a word)
			it.erase("from_rig")
			if rig_room(Items.size(it)):
				rig.append(it)
			elif not stash_put(it):
				log_event("No room for the %s: left at the gate" % str(it["base"]).to_lower())
			continue
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
		elif it.get("mythic", false):
			stash.append(it)                 # a mythic comes home whatever the room, as the deeds do (17 Oct)
			stashed += 1
		else:
			continue
		if not Items.rig_item(it):
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
		"left": m["left"] + (m["found"].size() - stashed), "cash": m["cash"], "xp": m["xp"],
		"hp_lost": m["hp_start"] - hp, "time": m["elapsed"], "searches": m["searches"], "patrols": m["patrols"], "wounded": bool(m.get("wounded", false)), "scrap": int(m.get("scrap", 0)), "salvage": sv.duplicate(),
		"clock_used": float(m.get("clock_used", 0.0)), "clock_left": float(m.get("clock", 0.0)), "timed_out": bool(m.get("timed_out", false)), "way_out": bool(m.get("way_out", false)),
	}
	log_event("%s from %s: %d kill%s, %d item%s, %s" % [outcome, Words.mid(t["name"]), m["kills"], "" if int(m["kills"]) == 1 else "s", stashed, "" if int(stashed) == 1 else "s",
			_cash_words(m["cash"])])
	_radio_after_run()
	_chron_run(m, outcome, {"loot": stashed, "left": int(last_report["left"]), "cash": int(m["cash"]), "xp": int(m["xp"]),
		"notes": run_notes, "scrap": int(m.get("scrap", 0)), "salvage": sv.duplicate(), "hp_lost": int(m["hp_start"] - hp),
		"wounded": bool(m.get("wounded", false)), "timed_out": bool(m.get("timed_out", false)), "way_out": bool(m.get("way_out", false)),
		"clock_used": snappedf(float(m.get("clock_used", 0.0)), 0.1), "searches": int(m["searches"]), "patrols": int(m["patrols"]),
		"cleared": bool(m["cleared"]), "pack": pack_used(m), "cap": capacity()})
	_record_run(m)
	_signal_done(m)
	mission = null
	_idle_tidy()
	_say_next()
	restock()
	_top_up()                                 # home, the rig loaded again: the card's odds read the rig that goes out (the review)


## The runner's record, from a run that came back (8 Oct).
func _record_run(m: Dictionary) -> void:
	record["runs"] = int(record.get("runs", 0)) + 1
	record["kills"] = maxi(int(record.get("kills", 0)), int(m["kills"]))
	record["dealt"] = maxf(float(record.get("dealt", 0.0)), float(m.get("dealt", 0.0)))
	record["cash"] = maxf(float(record.get("cash", 0.0)), float(m["cash"]))
	for it in m["found"]:
		if int(it.get("value", 0)) > int(record.get("find_value", 0)):
			record["find_value"] = int(it["value"])
			record["find"] = Items.full_name(it)


## A run's end in the playtest record: where, how deep, how it ended, what the runner was, and the run's own figures.
func _chron_run(m: Dictionary, outcome: String, extra: Dictionary) -> void:
	if _dry_on:
		return                                    # chron would drop it: the odds' runs skip the reading too
	var et: Dictionary = m.get("t", tier(m["tier"]))
	var b = m.get("boss", null)
	var d := {"tier": int(m["tier"]), "site": str(tier(m["tier"])["name"]), "depth": int(et.get("depth", 1)), "site_level": int(et.get("level", 0)),
		"outcome": outcome, "time": snappedf(float(m["elapsed"]), 0.1), "kills": int(m["kills"]), "of": int(et.get("pool", 0)),
		"auto": auto_tier >= 0, "cls2": cls2, "hp_max": int(max_hp()), "dps": snappedf(dps(), 0.1), "mit": snappedf(mitigation(), 0.001),
		"kit": loadout_value(), "wound_in": wound,
		# what the player saw and set off against (12 Oct, Matt: "how the bot plays isn't how a person plays"): the
		# odds the Runs card read at the gate (-1 unread), the site's own fire and HP, and the kit's regen
		"odds": snappedf(float(m.get("odds_seen", -1.0)), 0.01), "their_hp": int(et.get("hp", 0)), "their_dps": snappedf(float(et.get("dps", 0.0)), 0.1),
		"regen": snappedf(_affix_sum("regen"), 0.1)}
	if b != null and b is Dictionary and not b.is_empty():
		d["boss"] = str(b.get("name", ""))
		d["boss_down"] = not bool(b.get("alive", true))
	if m.get("convoy", false):
		d["convoy"] = true
	# the dots and the drops (17 Oct, for the balance after Matt's playtest): what the run dealt and how much of it the
	# dots' ticks, the one figure and its dot part, the +% dots worn and trained; and its gear finds against what the
	# runner can wear - the dot change and the fifth at yours, read from a person's play
	var ticked := 0.0
	var by := {}
	for ty in m.get("ticked_by", {}):
		ticked += float(m["ticked_by"][ty])
		by[ty] = roundi(float(m["ticked_by"][ty]))
	var split: Array = m.get("split_gate", [0.0, 0.0])
	d["dealt"] = roundi(float(m.get("dealt", 0.0)))
	d["ticked"] = roundi(ticked)
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
	for it in m.get("found", []):
		if str(it.get("slot", "")) in Data.SLOTS and not it.get("mythic", false):
			gear += 1
			wearable += 1 if Items.wear_level(it) <= level() else 0
			at_mine += 1 if Items.ilvl(it) == mine and int(et.get("level", 0)) > mine else 0
	d["gear"] = gear
	d["gear_wearable"] = wearable
	d["gear_at_mine"] = at_mine
	d.merge(extra, true)
	chron("run", d)


func _record_reset() -> void:
	record = {"since": elapsed, "kills": 0, "dealt": 0.0, "cash": 0.0, "find": "", "find_value": 0, "runs": 0, "deaths_seen": operators_lost}


## The caps pass (8 Oct): every string in a save that is an old name becomes the new one, wherever it sits -
## an item's unique, the shelf, the mate, a contract, a tree's node id ("The yard/3", then "The Yard/3", to "The Pitch/3").
static func _rename_old(v: Variant) -> void:
	if v is Dictionary:
		for k in v.keys():
			var x = v[k]
			if x is String:
				v[k] = _renamed(x)
			else:
				_rename_old(x)
	elif v is Array:
		for i in range(v.size()):
			var x = v[i]
			if x is String:
				v[i] = _renamed(x)
			else:
				_rename_old(x)


static func _renamed(x: String) -> String:
	if Data.RENAMES.has(x):
		return Data.RENAMES[x]
	for old in ["The yard/", "The Yard/"]:     # the Yard became the Pitch (14 Oct)
		if x.begins_with(old):
			return "The Pitch/" + x.trim_prefix(old)
	return x


## KIA: the loadout and what was found are gone; the stash and cash stay. A
## fresh operator takes over at level 1. Auto-run stops.
## A mythic left on the floor at a run's end (17 Oct: a full pack by hand, or "No room: make some" never made) comes
## home as one in the pack does: into the pack first, over its size if need be, so each ending's own rule takes it.
func _floor_mythics_in(m: Dictionary) -> void:
	var fl: Array = m.get("floor", [])
	for it in fl.filter(func(x): return x.get("mythic", false)):
		fl.erase(it)
		m["found"].append(it)


func _kia() -> void:
	var m: Dictionary = mission
	if m.get("dry", false):
		m["dead"] = true                     # a dry run: the answer, nothing lost
		return
	_floor_mythics_in(m)
	var t := tier(m["tier"])
	var dogs_share: bool = has_node("cap_dogs_share") and not m.get("insured", false) and not rig.is_empty()
	var lost := loadout_value()
	if dogs_share:
		for it in rig:
			lost -= int(it["value"])         # the dog's share: the rig is not lost
	last_report = {
		"outcome": "Dead", "tier": m["tier"], "kills": m["kills"], "of": int(t["pool"]), "loot": 0,
		"left": m["found"].size() + m["left"], "cash": 0.0, "xp": 0.0, "hp_lost": m["hp_start"], "time": m["elapsed"],
		"lost_value": lost, "searches": m["searches"], "patrols": m["patrols"],
	}
	_bank_materials(m)                       # the rebuild's materials come home whatever happens (18 Oct, Matt's call: never lost)
	_chron_run(m, "Dead", {"lost_value": lost, "insured": bool(m.get("insured", false)), "searches": int(m["searches"]), "patrols": int(m["patrols"]),
		"cleared": bool(m["cleared"]), "runner_runs": runner_runs})
	past.append({"class": cls, "level": level(), "runs": runner_runs, "end": "died in %s" % Words.mid(t["name"]), "site": _deepest_held()[0], "depth": _deepest_held()[1], "held_lv": _deepest_held()[2]})
	if Words.PASTS.has(cls) and not _dry_on:
		log_event("On the Pitch's list of the dead: a %s. %s" % [cls.to_lower(), Words.PASTS[cls]["wall"]])     # the runner as the Yard remembers them (12 Oct; the wall is the retired's)
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
		log_event("Dead in %s. %s" % [Words.mid(t["name"]), Words.FENCE["paid_out"]])
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
			log_event("The insurance paid on the pack too: %d thing%s" % [m["found"].size(), "" if m["found"].size() == 1 else "s"])
	else:
		log_event("Dead in %s. Kit lost (%s). %s" % [Words.mid(t["name"]), _cash_words(lost), Words.RECYCLE["listed"]])
		for s in Data.SLOTS:
			if equipped[s] != null:
				if equipped[s].get("mythic", false):
					stash.append(equipped[s])        # a mythic is never lost: it comes home (16 Oct)
				else:
					_lose(equipped[s], "the last %s" % cls, "runner")
		if dogs_share:
			for it in rig:
				stash.append(it)                 # the dog's share: the rig comes home
			log_event("The dog came home with the rig: %d pouch%s" % [rig.size(), "" if rig.size() == 1 else "es"])
	if not m.get("pack_kept", false):
		for it in m["found"].filter(func(x): return x.get("mythic", false)):
			stash.append(it)                     # a mythic found on the run comes home, whatever (16 Oct)
			m["found"].erase(it)
	if yard_has("fetch") and not m["found"].is_empty() and not m.get("pack_kept", false):
		# the kennel's top level (31): the dog carries the best thing in the pack home
		var best: Dictionary = m["found"][0]
		for it in m["found"]:
			if sell_price(it) > sell_price(best):
				best = it
		if not _home_gate(best):
			stash.append(best)
		last_report["carried"] = Items.full_name(best)
		last_report["left"] = int(last_report["left"]) - 1
		log_event("The dog came home with %s" % (Items.full_name(best) if best.has("unique") else Items.full_name(best).to_lower()))
		if Items.is_deeds(best) and deeds_fate == "":
			deeds_fate = "held"                  # the deeds, carried home: held all the same
			log_event(Words.DEEDS["held"])
	for s in Data.SLOTS:
		equipped[s] = null
	rig = []
	operators_lost += 1
	xp = 0.0
	wound = ""                           # theirs, gone with them
	hp = Data.BASE_HP
	_signal_done(m, true)
	mission = null
	auto_tier = -1
	if hardcore:
		camp_lost = true
		log_event(Words.YARD["hardcore_lost"])
		return
	# the new operator brings their own worn kit, so a KIA with an empty stash
	# and no cash is a setback, not a dead end
	_starter_loadout()
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


## The runner's own trees - the class's, the second past's, and the elements'
## (a fire build is the runner's, not the Yard's) - back to points; the class
## unpicked. Only the Yard's tree stays taken.
func _refund_runner_trees() -> void:
	var spent_before := points_spent()
	cls = ""
	cls2 = ""
	var kept := []
	for id in tree:
		if str(id).get_slice("/", 0) == Data.COMMON_TREE:
			kept.append(id)
	tree = kept
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
	return "%s%s%s tin%s" % ["−" if n < 0 else "", s, out, "" if n == 1 else "s"]     # grouped as the screens say it


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
	var slot: String = str(it.get("slot", ""))
	var swap: bool = not it.is_empty() and equipped.has(slot)
	var was = equipped[slot] if swap else null
	if swap:
		equipped[slot] = it
	var v = f.call()
	if swap:
		equipped[slot] = was
	_trying = was_trying
	return v


## The runner's figure for a slot with `it` worn ({} for the kit as it is): the damage for a gun, the survival figure
## for the body (survival_value: HP, regen, armour and resists against the fight being pushed), the piece's score for
## bags and charms.
func fit_value(it: Dictionary, slot := "") -> float:
	if slot == "":
		slot = str(it.get("slot", ""))
	# cached with the verdicts (the bot's sell loop asks for the best of a slot once a stash item)
	var key := _kit_key()
	if key != _cmp_key:
		_cmp_key = key
		_cmp_cache.clear()
	var fk := "f/%s/%d" % [slot, hash(it)]
	if _cmp_cache.has(fk):
		return _cmp_cache[fk]
	var v := _fit_value(it, slot)
	_cmp_cache[fk] = v
	return v


func _fit_value(it: Dictionary, slot: String) -> float:
	match Data.SLOT_SCORE.get(slot, ""):
		"dps":
			return _try(it, dps)
		"armour":
			return _try(it, survival_value.bind(front_fight()))
	if it.is_empty():
		return Items.score(equipped[slot]) if equipped.get(slot) != null else 0.0
	return Items.score(it)


## The body's figure (12 Oct, Matt: a +5 HP/s helmet and charm carried his run while the arrow called 50-armour drops
## better - armour and half the HP saw no regen, no resist): how many times over the runner stands the fight being
## pushed. HP, regen over the fight and HP a kill, against their fire through armour and resists over the same
## seconds - regen, resists, armour and HP in one currency, at the depth that's open. Read tried on (fit_value).
const SURV_SLOTS := ["Helmet", "Armour", "Charm", "Rig"]
## `fight` is the fight's seconds, held at the worn kit's (front_fight) when a piece is tried on: what a piece does to
## the damage and the pace is the damage's own reading, not counted twice through a longer fight (the riot suit's -8
## pace read as less survival than a stab vest's 15 armour).
func survival_value(fight := -1.0) -> float:
	var i := front_tier()
	var t := effective(i)
	if fight <= 0.0:
		fight = front_fight()
	var took: float = incoming_rate(t, contact(t)) * fight
	var back: float = max_hp() + _affix_sum("regen") * fight + _affix_sum("life_per_kill") * float(t["pool"])
	return back / maxf(took, 0.000001)       # an easy front still reads the armour (a floor of 1 HP hid it: the review)


## The seconds the fight being pushed takes on the kit as worn, every gun fed as a try-on reads it (out of rounds,
## the fists' fight ran twenty-five times as long); no damage at all reads as an hour.
func front_fight() -> float:
	var key := _kit_key()
	if key != _cmp_key:
		_cmp_key = key
		_cmp_cache.clear()
	if not _cmp_cache.has("ff"):             # once a kit (the review: every cell of a grid asked it again)
		_cmp_cache["ff"] = clampf(float(_try({}, func(): return estimate(front_tier()))), 1.0, 3600.0)
	return _cmp_cache["ff"]


## The rounds' types to hand, when the Fence is shut (a try-on reads a gun fed only then: the verdicts follow them).
func _rounds_on_hand() -> String:
	if room_open("fence"):
		return ""
	var types := {}
	for it in rig + stash:
		if Items.is_ammo(it):
			types[Items.base_of(it)["type"]] = true
	var k: Array = types.keys()
	k.sort()
	return ",".join(k)


## The fight being pushed: the open site that hits hardest at its set depth (the campaign's newest site, the
## endgame's deepest ladder). The kit doesn't move it; the depths and the clears do.
var _front_key := 0
var _front := 0
func front_tier() -> int:
	var key: int = hash([depth, best_depth, campaign_done(), yard_moves, bosses_beaten, words, standing, atlas])     # what opens a site and what it fights with (the review)
	if key == _front_key:
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
	return _front


## The body's figure with `it` worn, as a share up or down on the kit as it is (0.0 for a slot that has none).
func survival_gain(it: Dictionary) -> float:
	var slot: String = str(it.get("slot", ""))
	if not (slot in SURV_SLOTS) or not equipped.has(slot):
		return 0.0
	var key := _kit_key()
	if key != _cmp_key:
		_cmp_key = key
		_cmp_cache.clear()
	var sk := "s/%d" % hash(it)
	if not _cmp_cache.has(sk):
		if not _cmp_cache.has("s0"):
			_cmp_cache["s0"] = _try({}, survival_value)
		var s0: float = _cmp_cache["s0"]
		_cmp_cache[sk] = (float(_try(it, survival_value.bind(front_fight()))) - s0) / maxf(s0, 0.0001)
	return _cmp_cache[sk]


## Against what's worn in its slot: 1 better, 0 a sidegrade (or a trade: up one way, down another), -1 worse. A gun
## by the runner's damage with it on; anything else by its own job and the damage with it on, and a helmet, coat,
## charm or rig by the survival figure too (12 Oct; a helmet's or coat's job is that figure). An empty slot takes
## anything that goes in it.
func compare(it: Dictionary) -> int:
	var slot: String = str(it.get("slot", ""))
	if not equipped.has(slot):
		return 0
	if equipped[slot] == null:
		return 1
	# the grids ask for every cell ten times a second: an answer stands until the kit or the piece changes
	var key := _kit_key()
	if key != _cmp_key:
		_cmp_key = key
		_cmp_cache.clear()
	var ih: int = hash(it)
	if _cmp_cache.has(ih):
		return _cmp_cache[ih]
	var c := _compare(it, slot)
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
	var lot: bool = mission != null and (not mission.get("cleared", false) or mission.get("ghost_pending", false))     # First lot counts until the clear
	var pack: int = pack_used(mission) if mission != null else -1        # armour a free cell (the review)
	return hash([equipped, level(), tree, cls, cls2, wound, _rig_grades(), rig.size(), pack, yard_picks, yard_ranks, trades, mission != null, lot, paragon(), hp < max_hp() * 0.5, front_tier(), _rounds_on_hand(),
			weather_of(front_tier()), is_night()])     # the front: the body's figure reads the fight being pushed, under its sky (14 Oct: a verdict under rain stood after it cleared)


## The rounds in the rig as the guns see them: each stack with rounds left, by its grade, in the rig's order.
func _rig_grades() -> Array:
	var out: Array = []
	for it in rig:
		if Items.is_ammo(it) and int(it["rounds"]) > 0:
			out.append(str(it["base"]))
	return out


func _compare(it: Dictionary, slot: String) -> int:
	var d0: float = _try({}, dps)
	var rel: float = (_try(it, dps) - d0) / maxf(d0, 0.01)
	var g: int = 1 if rel > TRY_EPS else (-1 if rel < -TRY_EPS else 0)
	var kind: String = Data.SLOT_SCORE.get(slot, "")
	if kind == "dps":
		return g
	# each way it's read (12 Oct): the damage, the piece's own job, and for what's on the body the survival figure (a
	# body piece's job is that figure). Up on one and down on none, better; the reverse, worse; both, a trade
	var ways: Array = [g]
	var srel: float = survival_gain(it)
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
func upgrade_gain(it: Dictionary) -> float:
	var slot: String = str(it.get("slot", ""))
	if not equipped.has(slot):
		return 0.0
	if equipped[slot] == null:
		return EMPTY_GAIN
	var v0: float = fit_value({}, slot)
	var g: float = (fit_value(it) - v0) / maxf(v0, 0.000001)
	if slot in SURV_SLOTS and Data.SLOT_SCORE.get(slot, "") != "armour":
		g = maxf(g, survival_gain(it))       # a charm or rig bought for its regen or resists (the review: the bot never would)
	return g


## The best of a slot in the stash, tried on, or {}.
func best_in_stash(slot: String) -> Dictionary:
	var best := {}
	var bs := -INF
	for it in stash:
		if it["slot"] == slot:
			var v := fit_value(it)
			if v > bs:
				best = it
				bs = v
	return best


func equip_best(slot: String) -> bool:
	if mission != null:
		return false
	# the best of the ones that are better outright (a trade is the player's to make)
	var best := {}
	var bs := -INF
	for it in stash:
		if it["slot"] == slot and can_wear(it) and compare(it) == 1:
			var v := fit_value(it)
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
	_feed(best)
	return true


## At the gate (16 Oct, Matt's playtest: the drum shotgun went dry at the Bank with 110 slugs in the stash): the worn
## guns' rounds come out of the stash into the rig, as much as its room holds - the grade the gun fires first first
## (its build's element, then the dearer grade, as feed_stack reads them), topping a stack before taking a pouch.
## Meds and what's in the rig already stay. Logs what went in.
func _top_up() -> void:
	if mission != null:
		return
	var lists: Array = []
	for slot in ["Primary", "Secondary"]:
		var gun = equipped[slot]
		if gun == null:
			continue
		var t := Items.ammo_type(gun)
		if t in ["", "none"] or Items.free_rounds(gun):
			continue
		var els: Array = build_elements() if slot == "Primary" else []
		var stacks: Array = stash.filter(func(x): return Items.is_ammo(x) and Items.base_of(x)["type"] == t and int(x.get("rounds", 0)) > 0)
		var worth := func(x: Dictionary) -> int:
			var b: Dictionary = Items.base_of(x)
			var v: int = int(b.get("value", 0))
			for e in els:
				if float(b.get("conv_%s_pct" % e, 0)) > 0.0:
					v += 100000
			return v
		stacks.sort_custom(func(a, b): return worth.call(a) > worth.call(b))
		lists.append(stacks)
	# each gun's first grade before either gun's second (the review: a primary's boxes took every pouch, the secondary none)
	var order: Array = []
	var longest := 0
	for l in lists:
		longest = maxi(longest, l.size())
	for k in range(longest):
		for l in lists:
			if k < l.size() and not order.has(l[k]):
				order.append(l[k])
	var moved := 0
	for it in order:
		if not stash.has(it):
			continue
		var before: int = int(it["rounds"])
		take(int(it["id"]))                    # all of it, some of it (a stack topped, no pouch left) or none; the next grade still tries
		moved += before - (int(it["rounds"]) if stash.has(it) else 0)
	if moved > 0:
		_dry_memo.clear()
		log_event("Topped up: %d rounds from the stash into the rig" % moved)


## A gun put on with its rounds in the stash and none in the rig: a box of them to the rig, a stack of rounds no gun
## fires going back to the stash for the room (13 Oct, the review: Equip if better put the rifle on and the runner went
## out with its box still in the stash).
func _feed(gun: Dictionary) -> void:
	var type: String = Items.ammo_type(gun)
	if mission != null or type in ["", "none"] or rounds_for(gun) > 0:
		return
	var box := {}
	for it in stash:
		if Items.is_ammo(it) and Items.base_of(it)["type"] == type:
			box = it
			break
	if box.is_empty():
		return
	if not rig_room(Items.size(box)):
		var fired: Array = []
		for s in ["Primary", "Secondary"]:
			if equipped[s] != null:
				fired.append(Items.ammo_type(equipped[s]))
		for it in rig.duplicate():
			if Items.is_ammo(it) and not (Items.base_of(it)["type"] in fired):
				leave(it["id"])
				if rig_room(Items.size(box)):
					break
	take(box["id"])


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
			return true
	return false


## Whether a stash item can go into its slot now: not on a run, and what it
## replaces must fit in the stash once the new one has left it (footprints
## differ - a riot suit coming off needs more room than a stab vest going on).
func can_equip_item(id: int) -> bool:
	if mission != null:
		return false
	for it in stash:
		if it["id"] == id:
			var slot: String = it["slot"]
			if not equipped.has(slot) or not can_wear(it):
				return false
			if equipped[slot] == null:
				return true
			var out_cells: int = 0 if stash_free(it) else Items.size(it)
			var in_cells: int = 0 if stash_free(equipped[slot]) else Items.size(equipped[slot])
			return stash_used() - out_cells + in_cells <= stash_cap()
	return false


## A med from the stash into the rig, if there's a slot for it.
func take(id: int) -> bool:
	if mission != null:
		return false
	return _take_from(stash, id)


## Gear found out there, fitted while the run's on (Matt, 6 Oct): what comes
## off goes into the pack in its place, so it needs the cells the swap frees
## plus any more the fitted piece takes.
func can_equip_from_pack(id: int) -> bool:
	if mission == null:
		return false
	for it in mission["found"]:
		if it["id"] == id:
			var slot: String = it["slot"]
			if not equipped.has(slot) or Items.is_deeds(it) or not can_wear(it):
				return false
			# the room is read with the found piece on: a smaller backpack or rig found must still hold what's carried
			var was = equipped[slot]
			equipped[slot] = it
			_dry_memo.clear()
			var ok: bool = pack_used(mission) - Items.size(it) + (Items.size(was) if was != null else 0) <= capacity() and (slot != "Rig" or rig_used() <= med_capacity())
			equipped[slot] = was
			_dry_memo.clear()
			return ok
	return false


func equip_from_pack(id: int) -> bool:
	if not can_equip_from_pack(id):
		return false
	var m: Dictionary = mission
	for k in range(m["found"].size()):
		var it: Dictionary = m["found"][k]
		if it["id"] == id:
			var slot: String = it["slot"]
			m["found"].remove_at(k)
			if equipped[slot] != null:
				m["found"].append(equipped[slot])
				log_event("%s on, %s into the pack" % [it["base"], equipped[slot]["base"].to_lower()])
			else:
				log_event("%s on" % it["base"])
			chron("equip", {"slot": slot, "how": "pack", "on": _chron_item(it), "off": _chron_item(equipped[slot])})
			equipped[slot] = it
			_read(it)
			_dry_memo.clear()
			if hp > max_hp():
				hp = max_hp()
			return true
	return false


## A med or rounds found out there, into the rig while the run's on.
## Rounds out of the rig and into the pack on a run (11 Oct, Matt: a better rifle and its rounds found, and the rig
## full of the shotgun's shells with no way to make room). Needs the cells in the pack; never what's being used.
func can_rig_to_pack(id: int) -> bool:
	if mission == null:
		return false
	for it in rig:
		if int(it["id"]) == id:
			return Items.is_ammo(it) and _pack_has_room(mission, Items.size(it))     # rounds only: a med is used, never stowed
	return false


func rig_to_pack(id: int) -> bool:
	if not can_rig_to_pack(id):
		return false
	for k in range(rig.size()):
		if int(rig[k]["id"]) == id:
			var it: Dictionary = rig[k]
			rig.remove_at(k)
			it["from_rig"] = true              # the runner's own: home to the rig, not counted as loot
			mission["found"].append(it)
			log_event("%s into the pack" % it["base"])
			return true
	return false


func _pack_has_room(m: Dictionary, cells: int) -> bool:
	return pack_used(m) + cells <= capacity()


func take_from_pack(id: int) -> bool:
	if mission == null:
		return false
	return _take_from(mission["found"], id)


## Whether any of the rig's stacks of the same rounds has room: a drop that
## tops up, even with no pouch free and even if some stays behind.
func rig_tops_up(it: Dictionary) -> bool:
	if not Items.is_ammo(it):
		return false
	for r in rig:
		if Items.same_stack(r, it) and Items.stack_size(r) < Items.stack_cap(r):
			return true
	return false


func _take_from(src: Array, id: int) -> bool:
	for it in src:
		if it["id"] == id and Items.rig_item(it):
			if Items.is_medical(it) and has_rule("the_float"):
				return false                    # the Float carries no meds (18 Oct)
			if Items.is_ammo(it):
				# top up the rig's stack of the same rounds first; what's left takes a pouch, or stays
				var topped := false
				for r in rig:
					if Items.same_stack(r, it) and Items.stack_size(r) < Items.stack_cap(r):
						var moved: int = mini(Items.stack_cap(r) - Items.stack_size(r), Items.stack_size(it))
						if moved > 0:
							Items.set_stack(r, Items.stack_size(r) + moved)
							Items.set_stack(it, Items.stack_size(it) - moved)
							topped = true
						if Items.stack_size(it) <= 0:
							src.erase(it)
							return true
				if not rig_room(1):
					return topped
			if not rig_room(Items.size(it)):
				return false
			src.erase(it)
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


## A med out of the rig, back to the stash.
func leave(id: int) -> bool:
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
	if mission != null or equipped[slot] == null or not stash_fits(equipped[slot]):
		return false
	stash.append(equipped[slot])
	equipped[slot] = null
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
	passes = 0                                # a run home: the next contract turned down is free again (9 Oct)
	_restock_clinic()
	_restock_gamble()
	_restock_market()


## The Fence's shelf, rolled afresh.
func _restock_market() -> void:
	market = []
	var t := gear_tier()
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
			it = Items.roll(it["slot"], loot_tier_at(deepest_site_level()), rng, 0.0, false, false, "", "", Data.FX["yard/arms_dealer"], 0, deepest_site_level())     # the Fence's Arms dealer
		market.append(it)
	if yard_has("back_room"):
		var bu := pick_unique(loose_uniques(0), shop_unique_tier(), true)
		if not bu.is_empty():
			market.append(Items.roll_unique(bu, rng, -1, shop_unique_tier()))    # the Fence's Back room: a loose one (the ungated), held in its range


## The Fence's gamble: GAMBLE_SHOWN kinds of the eleven, rotated with every restock.
func _restock_gamble() -> void:
	var kinds: Array = []
	for k in Data.GAMBLE_KINDS:
		if _gamble_has_base(k):
			kinds.append(k["kind"])        # only a kind the Fence can source at the tier opened
	kinds.shuffle()
	gamble = kinds.slice(0, Data.GAMBLE_SHOWN)


## Whether the pool holds a base of the kind at the tier opened (not a start base).
func _gamble_has_base(k: Dictionary) -> bool:
	for b in Data.BASES[k["slot"]]:
		if not b.get("start", false) and int(b["tier"]) <= gear_tier() and (k["type"] == "" or b.get("type", "") == k["type"]):
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
	return room_open("fence") and mission == null and kind in gamble and cash >= gamble_price(kind) and stash_room(1)     # room for one cell at least: the roll's own size is checked when it lands


## Pay, and the thing turns up in the stash: a random one of the kind, rolled at the top tier opened
## with the Fence's quality, never Common; or, one time in fifty, a unique of the kind. The kind leaves
## the offer; the next restock brings five more. `unique_roll` is the tests' dice.
func gamble_buy(kind: String, unique_roll := -1.0) -> Dictionary:
	if not can_gamble(kind):
		return {}
	var k := gamble_kind(kind)
	var it := roll_gamble(k, unique_roll)
	if not (stash_fits(it) or _stack_room(it)):
		return {}
	chron("gamble", {"kind": kind, "price": gamble_price(kind), "item": _chron_item(it)})
	cash -= gamble_price(kind)
	gamble.erase(kind)
	stash_put(it)
	last_craft = {"id": it["id"], "kind": "gamble", "words": "The Fence's word: %s" % Items.full_name(it)}     # names as named (18 Oct)
	log_event("A word in the right ear: %s" % Items.full_name(it))
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
			return Items.roll_unique(gu, rng, -1, shop_unique_tier())     # one whose range takes the deepest tier dug; else a plain roll
	var it: Dictionary = {}
	for tries in range(40):
		it = Items.roll(k["slot"], gear_tier(), rng, Data.GAMBLE_QUALITY, true, false, "", k["type"], 0.33, 0, gamble_level())     # at your deepest site's level, as its drops (15 Oct, the loot read)
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
	return _inf(it["value"] * Data.MARKET_MARKUP * (Data.FX["node/buyers_market.buy"] if has_node("buyers_market") else 1.0) * (1.0 - town_stat("fence_pct") / 100.0))     # the market hall (18 Oct)


func buy(i: int) -> bool:
	if not room_open("fence"):
		return false
	if i >= market.size() or not (stash_fits(market[i]) or _stack_room(market[i])) or cash < price(market[i]):
		return false
	cash -= price(market[i])
	stash_put(market[i])
	market.remove_at(i)
	return true


func sell(it: Dictionary) -> bool:
	if not room_open("fence"):
		return false                          # the Fence is shut until the Carpet Man's ledger (13 Oct)
	if not _remove(it):
		return false
	_earn(float(sell_price(it)))
	if it.has("unique"):
		_lose(it, "", "fence")                # he said someone would want it; later someone has it
	if Items.is_deeds(it):
		deeds_fate = "sold"
		log_event(Words.DEEDS["sold"])
	return true


## Half a stack off into a stack of its own, beside it (12 Oct, Matt's playtest: "need a way to split ammo stacks"):
## rounds or bottles, two or more, in the stash (a free cell wanted) or the rig (a free slot); the larger half stays.
func can_split(id: int) -> bool:
	if mission != null:
		return false
	for where in [stash, rig]:
		for it in where:
			if it["id"] == id:
				if not Items.stacks(it) or Items.stack_size(it) < 2:
					return false
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


## Items are matched by id, never by contents: two commons can read the same.
func _remove(it: Dictionary) -> bool:
	for k in range(stash.size()):
		if stash[k]["id"] == it["id"]:
			stash.remove_at(k)
			return true
	return false


## Every item of a rarity in the stash, sold.
func sell_rarity(r: int) -> int:
	var n := 0
	for it in stash.duplicate():
		if it["rarity"] == r and not Items.is_paper(it) and not it.get("mythic", false):     # nor a mythic in a lot (the review)     # the deeds are sold on purpose or not at all; a paper's a key to the endgame (15 Oct): one at a time
			sell(it)
			n += 1
	return n


## The junk run.
func sell_commons() -> int:
	return sell_rarity(0)


## Whether the junk rules sell this: at or under the rarity, not an upgrade, not a kind kept, and never what the junk
## run leaves (rounds, meds, grenades, papers, socketed parts, uniques, set pieces, the deeds, a built gun).
func is_junk(it: Dictionary) -> bool:
	if junk_upto < 0 or int(it.get("rarity", 0)) > junk_upto:
		return false
	if Items.rig_item(it) or Items.is_paper(it) or Items.is_socketable(it) or it.has("unique") or it.has("set") or Items.is_deeds(it) or it.get("built", false):
		return false
	if str(it.get("slot", "")) in JUNK_KEEPS.get(junk_keep, []):
		return false
	return compare(it) != 1              # an upgrade waiting for its level is kept too


## Better than what's worn, tried on (compare), and wearable now: the compare's "▲ Upgrade", the stash's arrow.
func is_upgrade(it: Dictionary) -> bool:
	return can_wear(it) and compare(it) == 1


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
		if is_junk(it):
			var p: int = sell_price(it)
			if sell(it):
				got += p
				n += 1
	if n > 0:
		log_event("The Fence took the junk: %d thing%s, %s" % [n, "" if n == 1 else "s", _cash_words(got)])
	return n


## The Stash's Bins: the common gear in a run's finds scrapped, the junk run's filter (never a built gun, the
## deeds, rounds, meds, papers, socketables, uniques or set pieces); the rest is what still goes to the stash.
func _bin_commons(found: Array) -> Array:
	var kept: Array = []
	var n := 0
	var got := 0
	for it in found:
		if int(it.get("rarity", 0)) == 0 and not (Items.rig_item(it) or Items.is_paper(it) or Items.is_socketable(it) or it.has("unique") or it.has("set") or Items.is_deeds(it) or it.get("built", false) or Items.is_ammo(it) or it.get("first_gun", false)):
			got += scrap_of(it)
			n += 1
		else:
			kept.append(it)
	scrap += got
	if n > 0:
		log_event("Into the bins: %d thing%s, %d scrap" % [n, "" if n == 1 else "s", got])
	return kept


## Idle: what the toggles do when a run comes home.
func _idle_tidy() -> void:
	if auto_sell:
		sell_junk()
	if auto_equip:
		var changed := []
		for s in Data.SLOTS:
			if equip_best(s):
				changed.append(Items.full_name(equipped[s]))
		if not changed.is_empty():
			log_event("Put on: %s" % ", ".join(changed))


# ------------------------------------------------------------------ the medic tent

## The Medic Tent's shelf: every common med up to the next tier, at its markup.
## The Clinic's shelf: clinic_stock() meds, rolled from the
## bases it carries, cheaper ones more often. Finite until the next run.
func _restock_clinic() -> void:
	clinic = []
	var bases := med_stock()
	for k in range(clinic_stock()):
		var b: Dictionary = bases[mini(bases.size() - 1, int(absf(rng.randfn(0.0, 1.2))))]
		var it := Items.roll(Data.MEDICAL, int(b["tier"]), rng)
		it["base"] = b["name"]
		it["rarity"] = 0
		it["affixes"] = []
		it["tier"] = b["tier"]
		it["value"] = b["value"]
		clinic.append(it)


func clinic_price(it: Dictionary) -> int:
	return int(round(it["value"] * Data.MED_PRICE * (1.0 - town_stat("clinic_pct") / 100.0)))     # the pumping station (18 Oct)


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
	var t := mini(3, gear_tier())
	for b in Data.BASES[Data.MEDICAL]:
		if b["tier"] <= t:
			out.append(b)
	return out


func med_price(base: Dictionary) -> int:
	return _inf(base["value"] * Data.MED_PRICE * (1.0 - town_stat("clinic_pct") / 100.0))


func buy_med(name: String) -> bool:
	if not room_open("clinic"):
		return false
	for b in med_stock():
		if b["name"] == name:
			if cash < med_price(b) or not (stash_room(1) or yard_has("racks")):
				return false
			cash -= med_price(b)
			var it := Items.roll(Data.MEDICAL, int(b["tier"]), rng)
			it["base"] = name
			it["rarity"] = 0
			it["affixes"] = []
			it["tier"] = b["tier"]
			it["value"] = b["value"]
			stash.append(it)
			return true
	return false


# ------------------------------------------------------------------ the Yard's upgrades

func away_cap_s() -> float:
	var hours: int = Data.AWAY_HOURS
	for pair in [["twelve_hours", 12], ["a_day", 24], ["two_days", 48], ["grid", 72]]:
		if yard_has(pair[0]):
			hours = maxi(hours, int(pair[1]))
	return hours * 3600.0


## The HP back, and the wound seen to: WOUND_CASH a level, the Clinic's discount on both.
## The Clinic's two jobs, priced apart (Matt, 7 Oct: "heal my HP and treat the wound separately"): the HP back
## at TREAT_CASH_PER_HP a point, the wound at WOUND_CASH a level; the Clinic's discount on both.
func _treat_rate() -> float:
	return inflation() * maxf(0.2, 1.0 - tree_sum("treat_pct") / 100.0) * (1.0 - town_stat("clinic_pct") / 100.0)


func heal_cost() -> int:
	return int(ceil(maxf(0.0, max_hp() - hp) * Data.TREAT_CASH_PER_HP * _treat_rate()))


func wound_cost() -> int:
	return int(ceil(Data.WOUND_CASH * level() * _treat_rate() * (Data.FX["yard/surgery"] if yard_has("surgery") else 1.0))) if wound != "" else 0


## Both at once: what the bot pays, and the old button.
func treat_cost() -> int:
	return heal_cost() + wound_cost()


func needs_treating() -> bool:
	return hp < max_hp() or wound != ""


func can_heal() -> bool:
	return room_open("clinic") and mission == null and hp < max_hp() - 0.5 and cash >= heal_cost()


func can_treat_wound() -> bool:
	return room_open("clinic") and mission == null and wound != "" and cash >= wound_cost()


func heal() -> bool:
	if not can_heal():
		return false
	chron("heal", {"cost": heal_cost(), "hp": int(hp), "max": int(max_hp())})
	cash -= heal_cost()
	hp = max_hp()
	return true


func treat_wound() -> bool:
	if not can_treat_wound():
		return false
	chron("treat", {"cost": wound_cost(), "wound": wound})
	cash -= wound_cost()
	log_event("The wound seen to: %s back" % ("max HP" if wound == "hp" else wound))
	wound = ""
	_dry_memo.clear()
	return true


func treat() -> bool:
	if not room_open("clinic") or mission != null or not needs_treating() or cash < treat_cost():     # the Clinic's (13 Oct)
		return false
	chron("treat", {"cost": treat_cost(), "wound": wound, "hp": int(hp), "max": int(max_hp())})
	cash -= treat_cost()
	if wound != "":
		log_event("The wound seen to: %s back" % ("max HP" if wound == "hp" else wound))
		wound = ""
		_dry_memo.clear()
	hp = max_hp()
	return true


# ------------------------------------------------------------------ events, saving

## An event carries the time of day it happened, as the mission log shows it.
## The figures a return-from-away summary compares: a snapshot before and after.
func snapshot() -> Dictionary:
	return {"cash": cash, "xp": xp, "level": level(), "stash": stash.size(), "lost": operators_lost,
		"events": events.size(), "elapsed": elapsed, "runs": runs_total}


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
		"lv": level(), "cls": cls, "yard": yard_moves + 1, "sv": SITES_V}     # sv: the site numbering (12 Oct: the Outskirts moved every site up three)
	if away_on:
		e["away"] = true
	e.merge(data, true)
	chronicle.append(e)
	chron_count += 1
	_came_back_line(e)


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
		"best_tier": best_tier, "best_depth": best_depth.duplicate(), "deepest": deepest_v, "points": training_points, "spent": points_spent(),
		"yard_built": yard_built(), "atlas": atlas_spent(), "stash": stash.size(), "dps": snappedf(dps(), 0.1), "max_hp": int(max_hp()),
		"mit": snappedf(mitigation(), 0.001), "runs": runs_total, "lost": operators_lost, "kit": loadout_value()}


## A worn piece, as the record keeps it.
static func _chron_item(it) -> Dictionary:
	if it == null:
		return {}
	return {"base": str(it["base"]), "name": Items.full_name(it), "slot": str(it["slot"]), "tier": int(it.get("tier", 0)),
		"rarity": int(it.get("rarity", 0)), "value": int(it.get("value", 0)), "unique": it.has("unique"), "set": it.has("set")}


func to_dict() -> Dictionary:
	return _state().duplicate(true)      # a copy: the live items aren't shared with the save


func _state() -> Dictionary:
	return {
		"cash": cash, "xp": xp, "hp": hp, "equipped": equipped, "rig": rig, "stash": stash, "market": market, "gamble": gamble,
		"mission": mission, "last_report": last_report, "operators_lost": operators_lost,
		"best_tier": best_tier, "depot_cleared": depot_cleared, "elapsed": elapsed, "events": events,
		"next_id": Items._next_id, "auto_tier": auto_tier, "auto_equip": auto_equip, "junk_upto": junk_upto, "junk_keep": junk_keep, "came_back": came_back, "tree": tree, "tree_v": TREE_V, "training_points": training_points, "best_level": best_level,
		"words": words, "sealed": sealed, "filtered": filtered, "standing": standing, "depth": depth, "best_depth": best_depth, "class": cls,
		"yard_picks": yard_picks.duplicate(true), "yard_ranks": yard_ranks.duplicate(), "yard_open": yard_open, "salvage": salvage.duplicate(),
		"yard_seen": yard_seen.keys(), "yard_seen_cols": yard_seen_cols,
		"hardcore": hardcore, "camp_lost": camp_lost, "clinic": clinic, "wound": wound,
		"past": past, "loose_kit": loose_kit, "book": book.duplicate(), "heard": heard.duplicate(), "shelf": shelf.duplicate(), "keepsakes": keepsakes.duplicate(), "shelf_tier": shelf_tier.duplicate(), "worn": worn.duplicate(), "worn_depth": worn_depth.duplicate(), "weather": weather.duplicate(), "weather_at": weather_at, "last_next": last_next, "events_total": events_total, "runner_runs": runner_runs, "record": record.duplicate(), "seen": seen, "deeds_found": deeds_found, "unlocked": unlocked.duplicate(), "met": met.duplicate(), "deeds_fate": deeds_fate, "lorry_done": lorry_done, "lorries": lorries, "best_dig": best_dig.duplicate(), "paragon_banked": paragon_banked,
		"signals": signals.duplicate(true), "reach": reach, "signal_seq": signal_seq, "story_beat": story_beat,
		"materials": materials.duplicate(), "key_items": key_items.duplicate(), "rebuilt": rebuilt.duplicate(), "order_beaten": order_beaten.duplicate(),
		"bosses_beaten": bosses_beaten, "notes": notes, "scrap": scrap, "takings": takings, "gamble_base": gamble_base, "retired": retired.duplicate(), "class2": cls2, "atlas": atlas, "atlas_points": atlas_points, "boss_paid": boss_paid,
		"contracts": contracts, "passes": passes, "mate": mate, "runs_total": runs_total, "wounded_total": wounded_total, "yard_moves": yard_moves, "trades": trades.duplicate(), "insure_next": insure_next,
		"trait": runner_trait, "candidates": candidates, "promised": promised,
		"chron_count": chron_count, "chronicle_v": CHRONICLE_V, "played_s": played_s, "sites_v": SITES_V,
	}


## The site numbering (12 Oct): 2 since the Outskirts came before the Estate. A save at 1 has nine sites and three zones.
const SITES_V := 2


## A save from before the Outskirts: every per-site list gets the Outskirts' three in front (counted cleared at depth 1:
## that runner was past them), every per-zone list the Outskirts in front, and every site's index up three, every
## zone's up one - the mission out, its head, the last report, the deepest dig, the auto-run and the best tier.
static func _shift_sites(d: Dictionary) -> void:
	if int(d.get("sites_v", 1)) >= SITES_V or not d.has("depth") or Array(d["depth"]).size() != Data.TIERS.size() - Data.OUTSKIRTS_SITES:
		return
	var n: int = Data.OUTSKIRTS_SITES
	var front := func(key: String, v) -> void:
		if d.has(key) and d[key] is Array:
			var a: Array = d[key]
			for k in range(n):
				a.push_front(v.duplicate() if v is Array else v)
	front.call("depth", 1)
	front.call("best_depth", 1)
	front.call("worn_depth", 1)
	front.call("worn", -1.0)
	front.call("sealed", false)
	front.call("words", [])
	front.call("boss_paid", [])
	for key in ["weather", "bosses_beaten"]:
		if d.has(key) and d[key] is Array:
			if key == "weather":
				d[key].push_front("")
			else:
				d[key].push_front(true)
	d["best_tier"] = int(d.get("best_tier", 0)) + n
	if int(d.get("auto_tier", -1)) >= 0:
		d["auto_tier"] = int(d["auto_tier"]) + n
	var m = d.get("mission", null)
	if m is Dictionary:
		m["tier"] = int(m.get("tier", 0)) + n
		if m.get("t", null) is Dictionary:
			m["t"]["tier"] = int(m["t"].get("tier", 0)) + n
			if m["t"].get("boss", null) is Dictionary:
				m["t"]["boss"]["zone"] = int(m["t"]["boss"].get("zone", 0)) + 1
		for k in ["boss"]:
			if m.get(k, null) is Dictionary:
				m[k]["zone"] = int(m[k].get("zone", 0)) + 1
		for b in m.get("boss_queue", []) + (m["t"].get("boss_queue", []) if m.get("t", null) is Dictionary else []):
			if b is Dictionary:
				b["zone"] = int(b.get("zone", 0)) + 1
	if d.get("last_report", null) is Dictionary and d["last_report"].has("tier"):
		d["last_report"]["tier"] = int(d["last_report"]["tier"]) + n
	if d.get("best_dig", null) is Dictionary and d["best_dig"].has("tier"):
		d["best_dig"]["tier"] = int(d["best_dig"]["tier"]) + n
	# what the yard has seen, keyed by site: "cleared/N" and "N/D" up three; the Outskirts' counted seen (the review)
	if d.get("seen", null) is Dictionary:
		var moved := {}
		for k in d["seen"]:
			var key := str(k)
			if key.begins_with("cleared/") and key.get_slice("/", 1).is_valid_int():
				moved["cleared/%d" % (int(key.get_slice("/", 1)) + n)] = d["seen"][k]
			elif key.get_slice_count("/") == 2 and key.get_slice("/", 0).is_valid_int() and key.get_slice("/", 1).is_valid_int():
				moved["%d/%s" % [int(key.get_slice("/", 0)) + n, key.get_slice("/", 1)]] = d["seen"][k]
			else:
				moved[key] = d["seen"][k]
		for i in range(n):
			moved["cleared/%d" % i] = true
			moved["%d/1" % i] = true
		d["seen"] = moved
	d["sites_v"] = SITES_V


func load_dict(d: Dictionary) -> void:
	_els_key = -1                         # the build's elements read again from the loaded tree
	d = d.duplicate(true)                # the save's items stay the save's; the live ones are copies
	_rename_old(d)                       # a save from before the caps pass (8 Oct) carries the old names
	_shift_sites(d)                      # a save from before the Outskirts (12 Oct): every site up three, every zone up one
	cash = float(d.get("cash", Data.STARTING_CASH))
	xp = float(d.get("xp", 0.0))
	hp = float(d.get("hp", Data.BASE_HP))
	var e: Dictionary = d.get("equipped", {})
	for s in Data.SLOTS:
		equipped[s] = e.get(s, null)
	rig = d.get("rig", [])
	stash = d.get("stash", [])
	market = d.get("market", [])
	gamble = d.get("gamble", [])
	clinic = d.get("clinic", [])
	mission = d.get("mission", null)
	last_report = d.get("last_report", null)
	operators_lost = int(d.get("operators_lost", 0))
	best_tier = int(d.get("best_tier", 0))
	auto_tier = int(d.get("auto_tier", -1))
	auto_equip = bool(d.get("auto_equip", false))
	junk_upto = int(d.get("junk_upto", 0 if bool(d.get("auto_sell", false)) else -1))
	junk_keep = str(d.get("junk_keep", ""))
	if not JUNK_KEEPS.has(junk_keep):
		junk_keep = ""
	came_back = d.get("came_back", {})
	tree = d.get("tree", [])
	cls = d.get("class", "")
	# saves from before the language pass carry the old names
	const OLD_WORDS := {"Recon": "Poacher", "Enforcer": "Doorman", "Medic": "Paramedic", "Saboteur": "Scrapper", "Ghost": "Drifter"}
	cls = OLD_WORDS.get(cls, cls)
	cls2 = str(d.get("class2", ""))
	runner_trait = str(d.get("trait", ""))
	candidates = d.get("candidates", [])
	promised = str(d.get("promised", ""))
	chronicle = d.get("chronicle", [])    # the record's lines live in their file; a save from the first build (v1) carried them, and they go out at the next save
	chron_count = int(d.get("chron_count", chronicle.size()))
	played_s = float(d.get("played_s", 0.0))
	_snaps = int(played_s / SNAP_S)
	# trees from before the class trees: nodes that aren't in the trees on show are refunded
	var kept := []
	for id in tree:
		if _on_show(str(id).get_slice("/", 0)) and not node(str(id)).is_empty():
			kept.append(id)
	tree = kept
	_load_yard(d)
	hardcore = bool(d.get("hardcore", false))
	wound = str(d.get("wound", "")) if str(d.get("wound", "")) in Data.WOUND_STATS else ""
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
	if int(d.get("tree_v", 1)) < TREE_V and not tree.is_empty():
		tree = []                          # the lanes (9 Oct) moved the nodes: a tree from before comes back as points, once
		log_event("The trees are laid out again: every point is free to spend")
	depot_cleared = bool(d.get("depot_cleared", false))
	past = d.get("past", [])
	loose_kit = Array(d.get("loose_kit", []))
	book = Array(d.get("book", []))
	heard = Array(d.get("heard", []))
	shelf = Array(d.get("shelf", []))
	keepsakes = Array(d.get("keepsakes", []))
	shelf_tier = {}
	for k in d.get("shelf_tier", {}):
		shelf_tier[str(k)] = int(d["shelf_tier"][k])
	if d.has("worn"):
		for i in range(mini(worn.size(), d["worn"].size())):
			worn[i] = float(d["worn"][i])
	if d.has("worn_depth"):
		for i in range(mini(worn_depth.size(), d["worn_depth"].size())):
			worn_depth[i] = int(d["worn_depth"][i])
	else:
		for i in range(worn_depth.size()):
			worn_depth[i] = depth[i] if i < depth.size() else 1     # a save from before: the worn site is the depth it stands at
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
	deeds_found = bool(d.get("deeds_found", false))
	if d.has("unlocked"):
		unlocked = Array(d["unlocked"])
	else:
		unlocked = Data.ROOMS_SHUT.duplicate()   # a save from before the gates (13 Oct) played with every room open: it keeps them
	if d.has("met"):
		met = Array(d["met"])
	else:
		met = Words.ROOM_INTRO_FIRST + unlocked.duplicate()     # a save from before the room cards (14 Oct): it's met what it has open
	deeds_fate = str(d.get("deeds_fate", d.get("ending", "")))     # the old saves' name for it
	lorry_done = bool(d.get("lorry_done", false))
	lorries = int(d.get("lorries", 0))
	paragon_banked = int(d.get("paragon_banked", 0))
	best_dig = d.get("best_dig", {}).duplicate() if d.get("best_dig", {}) is Dictionary else {}
	signals = d.get("signals", []).duplicate(true)
	for sg in signals:
		_sig_ints(sg)
	reach = int(d.get("reach", Data.REACH_START))
	signal_seq = int(d.get("signal_seq", 0))
	story_beat = int(d.get("story_beat", 0))
	materials = _counts(d.get("materials", {}))
	key_items = _counts(d.get("key_items", {}))
	rebuilt = _counts(d.get("rebuilt", {}))
	order_beaten = _counts(d.get("order_beaten", {}))
	_sig = {}
	if mission != null and mission.get("signal", null) is Dictionary:
		_sig = mission["signal"]                 # a signal's run, saved mid-run: its site still carries it
		_sig_ints(_sig)
	notes = int(d.get("notes", 0))
	scrap = int(d.get("scrap", 0))
	takings = float(d.get("takings", 0.0))
	gamble_base = float(d.get("gamble_base", takings))     # an older save: from where its price stood
	retired = []
	for r in d.get("retired", []):
		retired.append(str(r))
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
	contracts = []
	for c in d.get("contracts", []):
		if not (str(c.get("pay", "")) in Data.CONTRACT_PAYS) or not c.has("kind"):
			contracts.append(roll_contract())    # a save from before (9 Oct): a unique, a socketable or rounds, rolled again
			continue
		contracts.append({"kind": str(c["kind"]), "slot": str(c.get("slot", "")), "rarity": int(c.get("rarity", 1)), "count": int(c.get("count", 1)), "level": int(c.get("level", 0)),
			"stat": str(c.get("stat", "")), "pay": str(c["pay"]), "amount": int(c.get("amount", 0)), "salvage": str(c.get("salvage", ""))})
	passes = int(d.get("passes", 0))
	while contracts.size() < contracts_open():
		contracts.append(roll_contract())
	for c in contracts:
		_contract_floor(c)                       # a save's asks up to what their pieces fetch (12 Oct)
	mate = {}
	if d.has("mate") and not d["mate"].is_empty():
		mate = {"unique": str(d["mate"]["unique"]), "notes": int(d["mate"]["notes"])}
		if d["mate"].has("tier"):
			mate["tier"] = int(d["mate"]["tier"])     # the tier he has it at (12 Oct): a reload keeps the offer as offered
	if mate.is_empty():
		mate = roll_mate()
	runs_total = int(d.get("runs_total", 0))
	wounded_total = int(d.get("wounded_total", 0))
	yard_moves = int(d.get("yard_moves", 0))
	trades = Array(d.get("trades", []))
	insure_next = bool(d.get("insure_next", false))
	var bb: Array = d.get("bosses_beaten", [])
	for z in range(Data.ZONES.size()):
		bosses_beaten[z] = bool(bb[z]) if z < bb.size() else false
	# a save from before the city: the zones it had cleared count as complete
	if bb.is_empty() and bool(d.get("depot_cleared", false)):
		bosses_beaten[1] = true              # the Estate (index 1 since the Outskirts)
	# a save from before the Gamekeeper (13 Oct): an Outskirts cleared had nobody to beat, so he counts as beaten
	if not d.has("unlocked") and not bosses_beaten[0]:
		var outskirts_done := true
		for i in Data.ZONES[0]["tiers"]:
			outskirts_done = outskirts_done and int(Array(d.get("best_depth", []))[i] if i < Array(d.get("best_depth", [])).size() else 0) > 0
		bosses_beaten[0] = outskirts_done
	elapsed = float(d.get("elapsed", 0.0))
	events = d.get("events", [])
	Items._next_id = maxi(Items._next_id, int(d.get("next_id", 1)))
	_reseed()
	# JSON turns ints to floats; the sim's counters want ints back
	if mission != null:
		if not mission.has("cleared"):
			mission = null                  # a save from before the search phase: the mission is dropped
		else:
			for k in ["remaining", "kills", "left", "tier", "searches", "patrols"]:
				mission[k] = int(mission[k])
			if not mission.has("using"):
				mission["using"] = null
				mission["meds_used"] = 0
			if not mission.has("fresh"):
				mission["fresh"] = false
			if not mission.has("t"):
				mission = null                  # from before intel: dropped
			else:
				for k in ["pool", "loot_tier", "contact", "depth", "tier"]:
					mission["t"][k] = int(mission["t"][k])
					if mission.has("t_home"):
						mission["t_home"][k] = int(mission["t_home"][k])     # a harder gang standing (B9)
				if not mission.has("clock"):
					mission["clock"] = clock_budget(mission["t"])     # a run from before the clock (9 Oct): the site's, from now
					mission["clock_max"] = mission["clock"]
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
	for it in _all_items() + crate_items:
		it["id"] = int(it["id"])
		it["rarity"] = int(it["rarity"])
		it["tier"] = int(it["tier"])
		it["value"] = int(it["value"])
		if it.has("rounds"):
			it["rounds"] = int(it["rounds"])
		if not d.has("shelf_tier") and it.has("unique") and not Items.is_paper(it) and it["unique"] in shelf and not (it in market):
			shelf_tier[it["unique"]] = maxi(int(shelf_tier.get(it["unique"], 0)), int(it["tier"]))     # a save from before the tiers: the shelf's from what's owned
	if market.is_empty():
		restock()
		passes = int(d.get("passes", 0))     # the restock is the shelf's; the turn-downs stay as saved
	if not d.has("gamble"):
		_restock_gamble()                 # a save from before the Fence's gamble: the offer rolled now, with the tiers loaded (an empty offer is a bought-out one)


func _all_items() -> Array:
	var out: Array = []
	for s in Data.SLOTS:
		if equipped[s] != null:
			out.append(equipped[s])
	out.append_array(rig)
	out.append_array(stash)
	out.append_array(market)
	if mission != null:
		out.append_array(mission["found"])
	# attachments fitted on guns ride inside them
	var nested: Array = []
	for it in out:
		for mount in it.get("attachments", {}):
			if it["attachments"][mount] != null:
				nested.append(it["attachments"][mount])
	out.append_array(nested)
	return out
