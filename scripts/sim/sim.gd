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
var gamble: Array = []             # the fence's gamble: the kinds on offer, rotated with the restock (GAMBLE_KINDS keys)
var clinic: Array = []             # the clinic's shelf: meds, so many a level, restocked after a run             # items for sale
var mission = null                 # null, or the mission in progress (a Dictionary)
var last_report = null             # the last mission's outcome, for Mission Control
var operators_lost := 0
var generator_level := 0           # the yard's: hours away that count
var lookout_level := 0             # the first lot later; better odds
var kennel_level := 0              # a dog
var hardcore := false              # a death ends the yard, stash and all
var wound := ""                    # a wound (30): "pace", "armour" or "hp" cut a tenth until the clinic treats it; "" for none
var camp_lost := false             # hardcore: set by the KIA that ended it
var tree: Array = []               # node ids taken, "Branch/index"; the camp's, kept across operators
var cls := ""                      # the operator's class, by name; "" is none yet
var cls2 := ""                     # the second past, from ASCEND_LEVEL: its first tree opens too
var runner_trait := ""             # what this runner turned up with
var candidates: Array = []         # when a runner dies, two turn up: their traits, to pick from
var promised := ""                 # a trait the next arrival brings (a runner brought home from a run)
var workshop := 0                  # the Workshop's level; what mounts can be fitted
var stash_level := 0               # the stash's size, by level
var medic_level := 0               # the Medic Tent's rest rate
var market_level := 0              # the Black Market's stock
var comms_level := 0               # the Comms Tower: buying and pinning intel
var pinned: Array = []             # per tier: whether its intel is pinned
var intel: Array = []              # per tier: the modifier names on offer now
var depth: Array = []              # per tier: the depth chosen, 1 up
var best_depth: Array = []         # per tier: the deepest cleared, 0 if none
var training_points := 0           # earned, one a level, across operators
var last_craft := {}               # the bench's last job: {id, kind, words}, for the toast and the craft panel
var best_tier := 0                 # highest tier extracted from
var depot_cleared := false         # the slice's win
var past: Array = []               # the runners before this one: {class, level, runs, end}
var retired: Array = []            # the traits on the wall (36): a third of each stays with the yard, newest last
var loose_kit: Array = []          # out on the estate: {item, who, from, run} - a dead runner's kit, a unique the fence moved on
var book: Array = []               # the papers found, by name, in the order found: the drawer in the caravan
var shelf: Array = []              # the uniques found, by name, in the order found: the shelf in the caravan
var worn: Array = []               # per tier: the elapsed second it was last cleared, or -1 - a picked-over site comes back over RECOVER_H
var worn_depth: Array = []         # and the depth it was cleared at: another depth is another site, fresh (Matt, 7 Oct: "depth needs to reset the site being picked over"); the worn depth stays worn until it recovers
var weather: Array = []            # per zone: "", "Rain" or "Fog"
var weather_at := -1               # the hour the weather was last rolled
var last_next := ""                # the last "what's next" line the log carried
var auto_equip := false            # idle: the best of each slot goes on when a run comes home
var auto_sell := false             # idle: the common gear is sold when a run comes home
var runner_runs := 0               # this runner's runs so far
var seen: Dictionary = {}          # "tier/depth" -> true once the site's line has been given
var deeds_found := false           # the bank's vault, opened once
var ending := ""                   # what became of the deeds: burned, sold, held
var bosses_beaten: Array = []      # per zone: the crew's head is down
var boss_armed: Dictionary = {}    # tier -> true: the next run there takes the boss on
var notes := 0                     # the old paper money: the crews still take it
var scrap := 0                     # the bench's material (34): found, stripped, ditched for
var takings := 0.0                 # what the yard takes a run, averaged over the last few: the run's cash and the fence's money (the pass, 6 Oct)
var _takings_run := 0.0            # the cash in since the last run came home
var cash_in := 0.0                 # every pound in since the game began (runs, sales, contracts); not saved: the readers' figure
var atlas := {}                    # the map's passives: key -> rank
var boss_paid: Array = []          # per tier: the depths a head's price has been paid at (Long memory: once a depth)
var atlas_points := 0              # earned: one a new depth cleared past the first
var contracts: Array = []          # the fence's: {slot, rarity, count, pay, amount, unique}
var mate := {}                     # the fence's mate's offer: {unique, notes}
var runs_total := 0                # every run, every runner: the mate's clock
var wounded_total := 0             # runs that ended wounded, every runner (saved; the wounds row reads a player's save by it)
var yard_moves := 0                # how many times the yard has moved (the prestige)
var lorry_done := false            # the convoy beaten in this yard: the endgame's ending (7 Oct); the move lights on it
var lorries := 0                   # across every yard: how many times
var paragon_banked := 0            # the paragon levels of the runners before, kept by the move (8 Oct)
var best_dig := {}                 # the yard's deepest hold: {site, depth, yard}, kept across moves (the wall's score)
var trades: Array = []             # the yard's trade: elements whose keystone every class may take, one a move, for good
var insure_next := false           # the next run is insured: the fence holds the paper on the kit
var elapsed := 0.0
var events: Array = []
var rng := RandomNumberGenerator.new()


func _init() -> void:
	for s in Data.SLOTS:
		equipped[s] = null
	for i in range(Data.TIERS.size()):
		intel.append([])
		depth.append(1)
		best_depth.append(0)
		pinned.append(false)
		worn.append(-1.0)
		worn_depth.append(1)
		boss_paid.append([])
	for z in range(Data.ZONES.size()):
		bosses_beaten.append(false)
		weather.append("")


## A fresh camp: a starter loadout, the first stock on the market.
func start() -> void:
	rng.randomize()
	_starter_loadout()
	restock()
	while contracts.size() < Data.CONTRACTS_OPEN:
		contracts.append(roll_contract())
	mate = roll_mate()
	log_event(Words.YARD["set"])
	_say_next()


func _starter_loadout() -> void:
	equipped["Primary"] = _plain("Primary", "Hand-me-down nail gun")
	equipped["Armour"] = _plain("Armour", "Work jacket")
	equipped["Backpack"] = _plain("Backpack", "Plastic bag")
	equipped["Rig"] = _plain("Rig", "Bum bag")
	for k in range(2):
		rig.append(_plain(Data.MEDICAL, "Bandage"))
	rig.append(_plain(Data.AMMO, "Nails"))


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
	return Data.level_for_xp(xp)


## Levels past the cap (7 Oct): the same curve, +PARAGON_PCT damage and HP each, no top. The yard's, not the runner's:
## a move banks the runner's paragon levels and the next runner adds to them (the eighteenth read: a fresh yard's runner
## at level 44 read the stations at 0.00 that the last one held at 1.00, with every paragon level gone).
func paragon() -> int:
	return paragon_banked + Data.paragon_for_xp(xp)


## The yard's prestige: the lorries beaten, each LORRY_MULT on damage and HP, kept across moves.
func lorry_mult() -> float:
	return pow(Data.LORRY_MULT, lorries)


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
	return m * cm("hp") * trait_mult("hp") * wound_mult("hp") * growth_mult()


## Damage a second: the primary, a third of the secondary, the level, the affixes.
## Damage a second: the primary while it has rounds, else the secondary at full
## (a third of it behind the primary, or all of it with Double tap), else fists.
func dps() -> float:
	var d := 0.0
	var primary_live := equipped["Primary"] != null and has_rounds(equipped["Primary"])
	var secondary_live := equipped["Secondary"] != null and has_rounds(equipped["Secondary"])
	if primary_live:
		d += Items.dps(equipped["Primary"]) * (1.0 + grade_bonus(equipped["Primary"]) / 100.0) * (1.5 if (has_node("cap_jerry") and gun_type() == "improvised") else 1.0)   # Jerry-rigged: something improvised hits half again as hard
	if secondary_live:
		var sec := Items.dps(equipped["Secondary"]) * (1.0 + grade_bonus(equipped["Secondary"]) / 100.0) / (1.0 if (has_node("double_tap") or has_rule("vans_spare") or not primary_live) else 3.0)
		if has_rule("branch_pistol") and hp < max_hp() * 0.5:
			sec *= 2.0
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
		pct += _affix_sum("damage_low_pct") + tree_sum("damage_low_pct") + (40.0 if has_node("walking_wounded") else 0.0)
	if mission != null and (not mission["cleared"] or mission.get("ghost_pending", false)):
		pct += _affix_sum("first_lot_pct")
	return d * (1.0 + Data.DMG_PER_LEVEL * (level() - 1) + pct / 100.0) * (1.0 + _affix_sum("attack_pct") / 100.0) * cm("damage") * trait_mult("damage") * growth_mult()


func armour() -> float:
	var a := 0.0
	for s in Data.SLOTS:
		if equipped[s] != null:
			a += Items.armour(equipped[s])
	a += _affix_sum("armour_per_med") * rig.size() + _fitted_sum("salt")
	if mission != null:
		a += _affix_sum("armour_per_free") * maxi(0, capacity() - pack_used(mission)) + float(mission.get("bonus_armour", 0.0))
	return a * (1.0 + (tree_sum("armour_pct") + _affix_sum("armour_pct")) / 100.0) * (0.8 if (has_node("shock_more") and not has_rule("sparkys_gloves")) else 1.0) * wound_mult("armour")


## The wound's cut on a stat: a tenth off the one it names, nothing off the rest.
func wound_mult(stat: String) -> float:
	return 1.0 - Data.WOUND_PCT / 100.0 if wound == stat else 1.0


## The wound in words: "Wounded: pace −10%", or "" unhurt.
func wound_words() -> String:
	if wound == "":
		return ""
	return "Wounded: %s −%d%%" % [("max HP" if wound == "hp" else wound), Data.WOUND_PCT]


## A hit took the runner under a quarter: a wound, one stat cut until treated. A second replaces the first.
func _wound(m: Dictionary) -> void:
	var was := wound
	wound = Data.WOUND_STATS[rng.randi_range(0, Data.WOUND_STATS.size() - 1)]
	if not m.get("wounded", false):
		wounded_total += 1                # runs that ended wounded, every runner (the wounds row reads Matt's save by it, 8 Oct)
	m["wounded"] = true
	_dry_memo.clear()
	if wound == "hp":
		hp = minf(hp, max_hp())
	log_event(("Wounded again: %s" if was != "" else "Wounded: %s") % wound_words().trim_prefix("Wounded: "))


## The share of incoming damage the armour stops.
func mitigation() -> float:
	return _memo("mitigation", _mitigation_raw)


func _mitigation_raw() -> float:
	if has_rule("nans_cardigan"):
		return 0.0                               # no armour at all
	var a := armour() * (1.25 if has_node("plates") else 1.0) * cm("armour")
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
		out["shock"] += 0.33
		total += 0.33
	if has_rule("weed_burner"):
		for ty in Data.ELEMENTS:
			out[ty] = 0.0
		out["fire"] = 1.0
		total = 1.0
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
	return _affix_sum("%s_pct" % ty) + tree_sum("%s_pct" % ty)


## Everything that multiplies a type on its own: the element's costly notable, keystones, uniques.
func more(ty: String) -> float:
	return _memo("more/" + ty, _more_raw.bind(ty))


func _more_raw(ty: String) -> float:
	var m := 1.0
	if has_node("%s_more" % ty):
		m *= 1.4
	if ty == "frost" and has_node("frost_freeze"):
		m *= 0.5
	if ty == "bleed" and has_rule("butchers_steel"):
		m *= 2.0
	if ty == "shock" and has_rule("tester"):
		m *= 0.5
	if has_rule("sergeants_whistle"):
		m *= 1.6
	if has_set_rule("army"):
		m *= 1.3
	return m


## A dot's seconds: the element's notable doubles them.
## `theirs`: the dot is on them (the runner's rules shape it); false for one on you, which keeps the plain figures.
func dot_seconds(ty: String, theirs := true) -> float:
	var s := float(Data.DOTS[ty]["s"])
	if not theirs:
		return s
	if (ty == "fire" and tree.has("Petrol/3")) or (ty == "poison" and tree.has("The rat man/3")) or (ty == "bleed" and (tree.has("Blades/3") or has_set_rule("carpet"))):
		s *= 2.0
	if ty == "poison" and has_rule("rat_mans_overalls"):
		s *= 0.5                                 # the overalls: the same pool, twice as fast
	return s


func dot_stacks(ty: String, theirs := true) -> int:
	var n := int(Data.DOTS[ty]["stacks"])
	if not theirs:
		return n
	if ty == "poison" and has_node("poison_stacks"):
		n = 15
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
		return 0.6                               # the substation key: shocked, they take 60% more
	return 0.4 if tree.has("Live/3") else Data.SHOCK


## Damage a second by type, before their resist: the base, split, increased, more.
func type_dps() -> Dictionary:
	var base := dps()
	var conv := conversion()
	var out := {}
	for ty in Data.TYPES:
		out[ty] = base * float(conv[ty]) * (1.0 + increased(ty) / 100.0) * more(ty)
	return out


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
	if ty == "physical" or (ty == "fire" and has_rule("vicars_thermos")):
		return 0.0
	return minf(Data.RESIST_CAP, _affix_sum("%s_res" % ty) + _affix_sum("all_res") + tree_sum("%s_res" % ty) + tree_sum("all_res") + (0.0 if has_rule("blue_plaque") else base_res(ty))) / 100.0


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
		total += t["dps"] * on_you * share * ((1.0 - mitigation()) if ty == "physical" else (1.0 - resist(ty)))
	return total * ((1.0 - chill_amount()) if chilled else 1.0) * (Data.MELEE_INCOMING if melee() else 1.0)


## A dot's pool grows by a share of what landed and drains over its seconds;
## stacks cap the pool. `dots` is {type: pool}.
func _dot_add(dots: Dictionary, ty: String, landed: float, rate_cap: float) -> void:
	if not Data.DOTS.has(ty) or landed <= 0.0:
		return
	var d: Dictionary = Data.DOTS[ty]
	var theirs: bool = mission == null or dots != mission.get("my_dots", {})
	var cap: float = rate_cap * float(d["ratio"]) * dot_seconds(ty, theirs) * dot_stacks(ty, theirs)
	dots[ty] = minf(cap, float(dots.get(ty, 0.0)) + landed * float(d["ratio"]) * (1.0 + _affix_sum("dot_pct") / 100.0))


## What the dots deal this tick, draining their pools.
## `by`, when given, collects the tick per type (for the run screen's colours).
func _dot_tick(dots: Dictionary, dt: float, by: Dictionary) -> float:
	var dealt := 0.0
	for ty in dots.keys():
		var pool := float(dots[ty])
		if pool <= 0.0:
			dots.erase(ty)
			continue
		var theirs: bool = mission == null or dots != mission.get("my_dots", {})
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


## What's on you, for the run panel: "burning, bleeding".
func dots_on_you() -> Array:
	var out := []
	if mission == null:
		return out
	for ty in ["fire", "poison", "bleed"]:
		if float(mission.get("my_dots", {}).get(ty, 0.0)) > 0.5:
			out.append({"fire": "burning", "poison": "poisoned", "bleed": "bleeding"}[ty])
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
	var extra := (6 if has_node("pack_mule") else 0) + int(tree_sum("pack_cells"))
	var base := 2 if equipped["Backpack"] == null else maxi(1, Items.capacity(equipped["Backpack"]))
	return int((base + extra) * (2 if has_node("hoarder") else 1) * (1.5 if has_rule("the_float") else 1.0))


## Meds the rig can carry. No rig, no meds.
func med_capacity() -> int:
	if equipped["Rig"] == null or has_rule("the_float"):
		return 0
	var n: int = (Items.capacity(equipped["Rig"]) + int(tree_sum("med_cap")) + int(_affix_sum("med_cap"))) * (2 if has_rule("issue_webbing") else 1)
	if Data.GENERATOR_LEVELS[generator_level].get("rig_row", false):
		n += Data.RIG_ROW                    # the generator's top level: a second row of pouches (31)
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
		b -= 0.2                                 # the rat's share
	return b


## Rarer finds: the tree's and the class's, as a bonus the roll reads.
func rarity_bonus() -> float:
	var r := tree_sum("rarity") / 100.0 + trait_add("rarity") + charm_find() / 100.0 + Data.MOVE_FIND * yard_moves / 100.0 \
		+ float(Data.KENNEL_LEVELS[kennel_level].get("quality", 0.0)) / 100.0       # the dog knows what's worth carrying (27)
	return r * (2.0 if has_rule("bookies_pencil") else 1.0)


func sell_price(it: Dictionary) -> int:
	return int(round(it["value"] * inflation() * (1.0 + (tree_sum("sell_pct") + set_stat("sell_pct")) / 100.0) * (2.0 if has_node("buyers_market") else 1.0)))


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
	if mission != null:
		return false
	for c in Data.CLASSES:
		if c["name"] == name:
			cls = name
			# the old class's trees come back as points; the yard's tree stays
			var kept := []
			for id in tree:
				if _on_show(str(id).get_slice("/", 0)):
					kept.append(id)
			tree = kept
			log_event("The runner was a %s, before" % name.to_lower())
			_say_next()
			return true
	return false


# ------------------------------------------------------------------ the tree

## The three trees on show: the class's first, the yard's, the class's second.
## The trees on show: the class's, the yard's, the second past's, and every element's.
func trees() -> Array:
	var out: Array = Data.trees_for(cls, cls2)
	out.append_array(Data.ELEMENT_TREES)
	return out


## Whether an element is one of the runner's two (or the second past's).
func affinity(element: String) -> bool:
	if element == "" or has_rule("qm_manual") or element in trades:
		return true
	return element in Data.AFFINITY.get(cls, []) or element in Data.AFFINITY.get(cls2, [])


## The yard's trade: an element the move brings with it. Any of the five not taken already.
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
## off into the stash, their trees refund as a death's do, the yard keeps a third of their trait, and two
## new runners turn up to pick from.
func can_retire() -> bool:
	return level() >= Data.RETIRE_LEVEL and cls != "" and mission == null


func retire() -> bool:
	if not can_retire():
		return false
	past.append({"class": cls, "level": level(), "runs": runner_runs, "end": "retired", "site": _deepest_held()[0], "depth": _deepest_held()[1]})
	if runner_trait != "":
		retired.append(runner_trait)
		while retired.size() > Data.RETIRED_MAX:
			retired.pop_front()              # the oldest makes way
	log_event("%s retires to the wall at level %d. The yard keeps a little of what they were." % [cls, level()])
	runner_runs = 0
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
	for tr in Data.TRAITS:
		pool.append(tr["name"])
	pool.shuffle()
	candidates = [pool[0], pool[1]]
	if promised != "":
		candidates[1] = promised
		promised = ""
	runner_trait = candidates[0]
	log_event(Words.PASTS[cls]["arrives"] if Words.PASTS.has(cls) else "A new runner turns up at the yard with their own kit.")
	_refund_runner_trees()
	_dry_memo.clear()
	return true


# ------------------------------------------------------------------ the fence's contracts

## One contract: a slot, a rarity, a count, what it pays.
func roll_contract() -> Dictionary:
	var slot: String = Data.CONTRACT_SLOTS[rng.randi_range(0, Data.CONTRACT_SLOTS.size() - 1)]
	var c := {"slot": slot, "rarity": rng.randi_range(1, 2), "count": rng.randi_range(1, 3), "pay": "cash", "amount": 0, "unique": ""}
	if rng.randf() < Data.CONTRACT_UNIQUE_ODDS:
		var loose: Array = loose_uniques(0)            # the fence's contracts pay with the common ones only
		c["rarity"] = 2
		c["count"] = 3
		c["pay"] = "unique"
		c["unique"] = loose[rng.randi_range(0, loose.size() - 1)]["name"]
	elif rng.randf() < Data.CONTRACT_MATERIAL_ODDS:
		# craft materials (35): scrap, a socketable of the zone's element, or a graded box for a gun held
		var kind: int = rng.randi_range(0, 2)
		var types: Array = gun_types_held()
		if kind == 2 and not types.is_empty():
			var held: String = types[rng.randi_range(0, types.size() - 1)]
			var grades: Array = Data.BASES[Data.AMMO].filter(func(b): return b.has("from") and b["type"] == held)
			if not grades.is_empty():
				c["pay"] = "rounds"
				c["what"] = grades[rng.randi_range(0, grades.size() - 1)]["name"]
				c["amount"] = 1
		if kind == 1 and c["pay"] == "cash":
			var zone: int = int(Data.TIERS[best_tier]["zone"])
			var els: Array = Data.ZONE_TYPES[zone]["types"].keys()
			var el: String = els[rng.randi_range(0, els.size() - 1)] if not els.is_empty() else "fire"
			var socks: Array = Data.ATTACHMENTS.filter(func(a): return a.get("mount", "") == "socket" and a.has("conv_%s_pct" % el))
			if socks.is_empty():
				socks = Data.ATTACHMENTS.filter(func(a): return a["name"] == "Road salt")     # the estate's blades have no bottle: the salt instead
			if not socks.is_empty():
				c["pay"] = "socketable"
				c["what"] = socks[0]["name"]
				c["amount"] = 1
		if c["pay"] == "cash":
			c["pay"] = "scrap"
			c["amount"] = int(c["count"]) * int(c["rarity"]) * Data.CONTRACT_SCRAP
	elif rng.randf() < 0.5:
		c["pay"] = "notes"
		c["amount"] = int(c["count"]) * int(c["rarity"]) * Data.CONTRACT_NOTES
	else:
		# worth: the slot's bases' middle value at the rarity, a piece
		var bases: Array = Data.ATTACHMENTS if slot == Data.ATTACHMENT else Data.BASES[slot]
		var mid: float = float(bases[bases.size() / 2]["value"]) * float(Data.RARITIES[c["rarity"]]["value"])
		c["amount"] = int(round(mid * inflation() * Data.CONTRACT_CASH * c["count"] / 10.0)) * 10   # the fence quotes today's price
	return c


func contract_fits(c: Dictionary, it: Dictionary) -> bool:
	return it["slot"] == c["slot"] and int(it["rarity"]) >= int(c["rarity"]) and not it.has("unique") and not Items.is_deeds(it)


## What in the stash would go to this contract: the cheapest that fit, up to its count.
func contract_items(c: Dictionary) -> Array:
	var fits: Array = []
	for it in stash:
		if contract_fits(c, it):
			fits.append(it)
	fits.sort_custom(func(a, b): return a["value"] < b["value"])
	return fits.slice(0, int(c["count"]))


func can_hand_in(k: int) -> bool:
	if mission != null or k < 0 or k >= contracts.size():
		return false
	var c: Dictionary = contracts[k]
	var items := contract_items(c)
	if items.size() < int(c["count"]):
		return false
	if c["pay"] == "unique":
		var freed := 0
		for it in items:
			freed += Items.size(it)
		return stash_room(Items.size(Items.roll_unique(_unique_named(c["unique"]), rng)) - freed)
	return true


func hand_in(k: int) -> bool:
	if not can_hand_in(k):
		return false
	var c: Dictionary = contracts[k]
	for it in contract_items(c):
		_remove(it)
	var paid := ""
	match c["pay"]:
		"cash":
			_earn(float(c["amount"]))
			paid = _cash_words(float(c["amount"]))
		"notes":
			notes += int(c["amount"])
			paid = "%d notes" % int(c["amount"])
		"unique":
			var it := Items.roll_unique(_unique_named(c["unique"]), rng)
			stash.append(it)
			paid = it["unique"]
		"scrap":
			scrap += int(c["amount"])
			paid = "%d scrap" % int(c["amount"])
		"socketable":
			var sock: Dictionary = _plain(Data.ATTACHMENT, str(c["what"]))
			if not stash_put(sock):
				stash.append(sock)           # paid for: whatever the room, like a unique
			paid = str(c["what"])
		"rounds":
			var box: Dictionary = _plain(Data.AMMO, str(c["what"]))
			if not stash_put(box):
				stash.append(box)
			paid = "a box of %s" % str(c["what"]).to_lower()
	log_event("Handed in: %s. %s" % [contract_words(c), paid])
	contracts[k] = roll_contract()
	return true


## Turn one down: it's replaced, for nothing.
func pass_contract(k: int) -> bool:
	if mission != null or k < 0 or k >= contracts.size():
		return false
	contracts[k] = roll_contract()
	return true


func contract_words(c: Dictionary) -> String:
	var what: String = ("%s %s" % [Data.RARITIES[c["rarity"]]["name"].to_lower(), ("gun part" if c["slot"] == Data.ATTACHMENT else c["slot"].to_lower()) + ("" if int(c["count"]) == 1 else "s")])
	var n: int = int(c["count"])
	return "%s %s" % [["", "one", "two", "three", "four", "five", "six"][n] if n <= 6 else str(n), what]


func contract_pay_words(c: Dictionary) -> String:
	match c["pay"]:
		"cash":
			return _cash_words(float(c["amount"]))
		"notes":
			return "%d notes" % int(c["amount"])
		"scrap":
			return "%d scrap" % int(c["amount"])
		"socketable":
			return str(c.get("what", ""))
		"rounds":
			return "a box of %s" % str(c.get("what", "")).to_lower()
	return str(c["unique"])


func _unique_named(name: String) -> Dictionary:
	for u in Data.UNIQUES:
		if u["name"] == name:
			return u
	return {}


## The fence's mate: one of the loose uniques, for notes.
func roll_mate() -> Dictionary:
	var loose: Array = loose_uniques(deepest())    # his deep stock opens as you go deeper
	var u: Dictionary = loose[rng.randi_range(0, loose.size() - 1)]
	var tier: int = int(Items.base_of({"slot": u["slot"], "base": u["base"]}).get("tier", 1))
	return {"unique": u["name"], "notes": Data.MATE_NOTES * tier}


func can_buy_mate() -> bool:
	if mission != null or mate.is_empty() or notes < int(mate["notes"]):
		return false
	var u := _unique_named(mate["unique"])
	return not u.is_empty() and stash_room(Items.size(Items.roll_unique(u, rng)))


func buy_mate() -> bool:
	if not can_buy_mate():
		return false
	notes -= int(mate["notes"])
	var it := Items.roll_unique(_unique_named(mate["unique"]), rng)
	stash.append(it)
	_read(it)
	log_event("From the fence's mate, for %d notes: %s." % [int(mate["notes"]), it["unique"]])
	mate = roll_mate()
	return true


# ------------------------------------------------------------------ moving the yard

func can_move_yard() -> bool:
	return campaign_done() and mission == null and not camp_lost


## The move's compounding (7 Oct): a moved yard's ladders start at this depth past the first (to LADDER_FLOOR_MAX),
## and its first `yard_moves` nodes of the yard's tree are free.
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
	return [Data.TIERS[best]["name"] if best >= 0 else "", at]


## The yard's tree nodes taken, in the order they were taken.
func _yard_nodes_taken() -> Array:
	var out: Array = []
	for id in tree:
		if str(id).begins_with(Data.COMMON_TREE + "/"):
			out.append(id)
	return out


## Start again somewhere else. The uniques come, worn or stashed; the yard's
## own tree; the runners before; half the notes; the move's own bonus.
func move_yard(trade := "") -> bool:
	if not can_move_yard() or (trade != "" and not can_trade(trade)):
		return false
	var uniques: Array = []
	for it in stash:
		if it.has("unique"):
			uniques.append(it)
	for s in Data.SLOTS:
		if equipped[s] != null and equipped[s].has("unique"):
			uniques.append(equipped[s])
	var yard_tree: Array = []
	for id in tree:
		if str(id).begins_with("The yard/"):
			yard_tree.append(id)
	var keep := {"past": past, "retired": retired.duplicate(), "ending": ending, "hardcore": hardcore, "notes": int(notes * Data.MOVE_NOTES_KEPT), "scrap": int(scrap * Data.MOVE_NOTES_KEPT),
		"moves": yard_moves + 1, "elapsed": elapsed, "events": events, "operators_lost": operators_lost, "trades": trades.duplicate(), "book": book.duplicate(), "shelf": shelf.duplicate(),
		"lorries": lorries, "best_dig": best_dig.duplicate(), "held": {}, "atlas": atlas.duplicate(), "atlas_points": atlas_points,
		"paragon_banked": paragon()}
	if atlas_rank("held_word") > 0:
		for i in range(pinned.size()):
			if pinned[i]:
				keep["held"][i] = intel[i].duplicate()     # Held word: what's pinned at the radio moves with the yard
	if trade != "":
		keep["trades"].append(trade)
	var fresh = get_script().new()
	fresh.start()
	load_dict(fresh.to_dict())
	past = keep["past"]
	retired = keep["retired"]             # the wall moves with the yard (36)
	ending = keep["ending"]
	hardcore = keep["hardcore"]
	notes = keep["notes"]
	scrap = keep["scrap"]                 # scrap moves with the yard the way notes do (34)
	yard_moves = keep["moves"]
	lorries = keep["lorries"]
	best_dig = keep["best_dig"]
	paragon_banked = keep["paragon_banked"]
	atlas = keep["atlas"]                 # the map is the long tail (part 4, 7 Oct): its ranks and points move with the yard
	atlas_points = keep["atlas_points"]
	for i in keep["held"]:
		pinned[i] = true
		intel[i] = keep["held"][i]
	elapsed = keep["elapsed"]
	events = keep["events"]
	operators_lost = keep["operators_lost"]
	trades = keep["trades"]
	book = keep["book"]
	shelf = keep["shelf"]
	tree = yard_tree
	training_points = points_spent() + Data.MOVE_POINTS * yard_moves
	for it in uniques:
		stash.append(it)                   # whatever the new stash holds: they're the point of moving
	cash = float(Data.STARTING_CASH) * inflation()    # the float, at today's prices
	log_event(Words.YARD["moved"])
	if trade != "":
		log_event(Words.YARD["trade"] % Data.tree_of_element(trade)["name"].to_lower())
	last_next = ""
	log_event(Words.NEXT["moved"])
	return true


# ------------------------------------------------------------------ what's next

## The first ten minutes, and every minute after: what the yard would say to
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
				return (w["head"] % [b["name"].to_lower() if short else b["name"], Data.TIERS[int(b["tier"])]["name"].to_lower()]) if not short else (w["head"] % b["name"].to_lower())
	return w["done"] % convoy_depth() if "%d" in w["done"] else w["done"]


## Say it once, when it changes; the yard's set line says it first.
func _say_next() -> void:
	var w := next_words()
	if w != last_next:
		last_next = w
		log_event(w)


# ------------------------------------------------------------------ the places changing

## The yard's clock: hours on the 24, from the morning the yard opened.
func hour_of_day() -> float:
	return fmod(Data.CLOCK_START + elapsed / 3600.0, 24.0)


func is_night() -> bool:
	var h := hour_of_day()
	return h >= Data.NIGHT_FROM or h < Data.NIGHT_TO


func clock_words() -> String:
	var h := hour_of_day()
	return "%02d:%02d" % [int(h), int(fmod(h, 1.0) * 60.0)]


## The weather by zone, rolled once an hour of the yard's time.
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
	return Data.RECOVER_H * 3600.0 / (1.0 + 0.5 * atlas_rank("worn_in"))


## The site's state, for the card: fresh, settling, or picked over and when it's back.
func site_state(i: int) -> String:
	var w := wear(i)
	if w <= 0.0:
		return Words.SKY["fresh"]
	var back: float = recover_s() - (elapsed - float(worn[i]))
	var mins: int = int(ceil(back / 60.0))
	var when := ("%dh%02d" % [mins / 60, mins % 60]) if mins >= 60 else ("%d min" % mins)
	return (Words.SKY["worn"] if w > 0.5 else Words.SKY["settling"]) % when


## The sky over a site, in words: the clock, night or day, the weather.
func sky_words(i: int) -> String:
	var w := weather_of(i)
	return "%s, %s%s" % [clock_words(), Words.SKY["night"] if is_night() else Words.SKY["day"], (", " + Words.SKY[w.to_lower()]) if w != "" else ""]


# ------------------------------------------------------------------ the papers as the book

## A paper picked up is read, and goes in the drawer by name, once, in the order found.
func _read(it: Dictionary) -> void:
	if Items.is_paper(it) and not Items.is_deeds(it) and not (it["base"] in book):
		book.append(it["base"])
	if it.has("unique") and not (it["unique"] in shelf):
		shelf.append(it["unique"])


## Every paper there is to find, deep ones last.
func book_pages() -> Array:
	var out: Array = []
	for b in Data.BASES[Data.PAPER]:
		if b["name"] != "The deeds":
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
		log_event(Words.RECYCLE["off"] % [it["base"], who.substr(0, 1).to_upper() + who.substr(1)])


# ------------------------------------------------------------------ the bench's crafting

## An item of yours by id: worn, or in the stash.
func item_by_id(id: int) -> Dictionary:
	for s in Data.SLOTS:
		if equipped[s] != null and equipped[s]["id"] == id:
			return equipped[s]
	for it in stash:
		if it["id"] == id:
			return it
	return {}


## What the bench can do to this item: the price, in cash (notes for a bump);
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
			if not (it["slot"] in Data.SOCKET_SLOTS) or Items.sockets(it) >= Data.SOCKET_MAX:
				return -1
		"bump":
			if Items.ilvl(it) >= int(it["tier"]) + Data.BUMP_CAP:
				return -1
			return int(Data.CRAFT[kind]["notes"]) * Items.ilvl(it)
	var price: int = int(Data.CRAFT[kind]["cash"]) * Items.ilvl(it) * (int(it["rarity"]) + 1)
	if kind == "one":
		for a in it["affixes"]:
			if a["stat"] == stat:
				price *= int(a.get("tier", 1))     # the better the tier, the dearer
	return _inf(price)


func craft_in_notes(kind: String) -> bool:
	return Data.CRAFT.get(kind, {}).has("notes")


# ------------------------------------------------------------------ scrap and the Build column (34)

## What an item is worth in scrap: its value over SCRAP_PER_POUND, a stack by what it holds.
func scrap_of(it: Dictionary) -> int:
	if it.is_empty() or Items.is_deeds(it):
		return 0
	return int(float(it["value"]) / Data.SCRAP_PER_POUND)


## A stash item broken down at the bench for its scrap. Gone for good.
func scrap_item(id: int) -> bool:
	if mission != null or workshop < 1:
		return false
	for it in stash:
		if it["id"] == id:
			var bits: int = scrap_of(it)
			_remove(it)
			scrap += bits
			log_event("Scrapped %s: %d scrap" % [it["base"].to_lower(), bits])
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
				if b.get("type", "") != "improvised" or int(b["tier"]) > workshop or b.get("start", false):
					continue                  # the starting gun is nobody's build
				out.append(_build_entry(kind, b["name"], Data.BUILD_GUN * int(b["tier"]), "", 0, true, "", int(b["tier"])))
		"grenade":
			for b in Data.BASES[Data.GRENADE]:
				var from: String = str(b.get("from", ""))
				var have: int = _count_in_stash(from) if from != "" else 1
				out.append(_build_entry(kind, b["name"], Data.BUILD_GRENADE * int(b["tier"]), from, 1 if from != "" else 0, have >= 1, "" if have >= 1 else "Wants %s" % from.to_lower(), int(b["tier"])))
	return out


func _build_entry(kind: String, name: String, cost: int, from: String, from_n: int, has_from: bool, why: String, tier: int) -> Dictionary:
	# room for what it makes (the eighteenth read, 8 Oct: a bot built a box a run for thirty hours and the stash sat at
	# 327 of 234 with every find dropped): a box or a grade needs a stack with room or a cell, a med or a grenade a cell
	var made_slot: String = Data.AMMO if (kind == "box" or kind == "grade") else (Data.MEDICAL if kind == "med" else (Data.GRENADE if kind == "grenade" else "Primary"))
	var room: bool = stash_room(1) or (made_slot == Data.AMMO and _stack_room(_plain(Data.AMMO, name)))
	var ok: bool = has_from and scrap >= cost and mission == null and workshop >= 1 and room
	if why == "" and not ok:
		why = "The runner is out" if mission != null else ("Needs a bench" if workshop < 1 else ("No room in the stash" if not room else "Short of scrap"))
	return {"kind": kind, "name": name, "scrap": cost, "from": from, "from_n": from_n, "ok": ok, "why": why, "tier": tier}


func build_option(kind: String, name: String) -> Dictionary:
	for o in build_options(kind):
		if o["name"] == name:
			return o
	return {}


## Build it: the scrap goes, what it wants goes (a box's rounds off the stash's stacks, one off a socketable's
## stack, a med), and the thing lands in the stash. A gun built is Common, plain, and fires nails.
func build(kind: String, name: String) -> bool:
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
		"grenade":
			made = _plain(Data.GRENADE, name)
			if o["from"] != "":
				_take_one(o["from"])
	scrap -= int(o["scrap"])
	if not stash_put(made):
		stash.append(made)                   # whatever the room: it was paid for
	last_craft = {"id": made["id"], "kind": "build", "words": "Built %s for %d scrap" % [name.to_lower(), int(o["scrap"])]}
	log_event("At the bench, for %d scrap: %s" % [int(o["scrap"]), name.to_lower()])
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
		var take: int = mini(left, int(st["rounds"]))
		Items.set_stack(st, int(st["rounds"]) - take)
		left -= take
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
	if mission != null or workshop < 1:
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
			Items.reroll_affixes(it, rng)
		"lock":
			Items.reroll_affixes(it, rng, stat)
		"one":
			if Items.reroll_one(it, stat, rng) == 0:
				return false
		"add":
			if not Items.add_affix(it, rng):
				return false
		"socket":
			if not Items.add_socket(it):
				return false
		"strip":
			Items.strip_affixes(it)
		"bump":
			it["ilvl"] = mini(int(it["tier"]) + Data.BUMP_CAP, Items.ilvl(it) + Data.BUMP_LEVELS)
	# what the bench did, in words the player can check against the piece
	var words := _craft_words(it, kind, stat, before, sockets_before, level_before)
	last_craft = {"id": id, "kind": kind, "words": words}
	if craft_in_notes(kind):
		notes -= cost
		log_event("At the bench, for %d notes, %s: %s" % [cost, it["base"].to_lower(), words])
	else:
		cash -= float(cost)
		log_event("At the bench, for %s, %s: %s" % [_cash_words(float(cost)), it["base"].to_lower(), words])
	return true


## "Added +12% damage · T2", "Re-rolled: +4% damage · T1, +2 HP/s · T1 → ...".
func _craft_words(it: Dictionary, kind: String, stat: String, before: Array, sockets_before: int, level_before: int) -> String:
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
			return "Level %d → %d: nothing under T%d rolls" % [level_before, Items.ilvl(it), mini(Items.tier_floor(Items.ilvl(it)), Items.rarity_cap(it))]
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


## A node is open when the one before it in its column has a rank (the map at thirty-six, 7 Oct: each column a chain).
func atlas_open(key: String) -> bool:
	var before: String = ""
	for a in Data.ATLAS:
		if a["key"] == key:
			return before == "" or atlas_rank(before) > 0
		if int(a["column"]) == Data.atlas_of(key).get("column", -1):
			before = a["key"]
	return false


func rank_atlas(key: String) -> bool:
	if not can_rank_atlas(key):
		return false
	atlas[key] = atlas_rank(key) + 1
	return true


## The map's points come back; the ranks go.
func reset_atlas() -> void:
	atlas = {}


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
	log_event("The one who stays is %s. The other moved on." % Data.TRAIT_WORDS.get(runner_trait, runner_trait.to_lower()))
	return true


## The second past: a different class, from level ASCEND_LEVEL, for its first tree.
func can_ascend() -> bool:
	return level() >= Data.ASCEND_LEVEL and cls != "" and mission == null


func set_second(name: String) -> bool:
	if not can_ascend() or name == cls or name == cls2:
		return false
	for c in Data.CLASSES:
		if c["name"] == name:
			cls2 = name
			var kept := []
			for id in tree:
				if _on_show(str(id).get_slice("/", 0)):
					kept.append(id)
			tree = kept
			log_event("The runner was a %s too, once" % name.to_lower())
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


## A trained node counts unless it's typed for a gun that isn't in hand.
func _active(n: Dictionary) -> bool:
	return not n.has("type") or n["type"] == gun_type()


func has_node(effect: String) -> bool:
	for n in _nodes_for(effect):
		if _active(n):
			return true
	return false


## The small nodes' numbers for an effect, added up.
func tree_sum(effect: String) -> float:
	var t := 0.0
	for n in _nodes_for(effect):
		if _active(n):
			t += n.get("value", 0)
	return t


## The trained nodes by effect, built once per shape of the tree: the fight
## asks for effects every tick, and splitting ids each time was the cost.
var _eff_cache := {}
var _eff_hash := 0
func _nodes_for(effect: String) -> Array:
	var h := hash(tree)
	if h != _eff_hash or _eff_cache.is_empty():
		_eff_cache = {}
		for id in tree:
			var n := node(id)
			if n.is_empty():
				continue
			var e: String = n.get("effect", "")
			if not _eff_cache.has(e):
				_eff_cache[e] = []
			_eff_cache[e].append(n)
		_eff_hash = h
	return _eff_cache.get(effect, [])


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
	if not (_dry_on or (fast_memo and mission != null)):
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
		# a move's free node: the first free_yard_nodes() of the yard's tree cost nothing (7 Oct)
		var taken := _yard_nodes_taken()
		var k: int = taken.find(id)
		if (k >= 0 and k < free_yard_nodes()) or (k < 0 and taken.size() < free_yard_nodes()):
			return 0
	var n := node(id)
	var cost := Data.node_cost(int(parts[1]), n.get("notable", false), n.get("keystone", false))
	if n.get("capstone", false):
		cost = Data.capstone_cost(Data.tree_named(parts[0]))     # a third of the tree, on top of the tree
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


## A node can be trained with a point free and the one before it taken.
func can_train(id: String) -> bool:
	if tree.has(id) or node(id).is_empty() or points_free() < node_cost(id):
		return false
	var parts := id.split("/")
	if not _on_show(parts[0]):
		return false
	var i := int(parts[1])
	var t := Data.tree_named(parts[0])
	if t.has("element") and not affinity(t["element"]) and t["nodes"][i].get("keystone", false):
		return false                         # an element's keystone needs its affinity: the class's, or the second past's
	if t["nodes"][i].get("capstone", false):
		# the capstone wants the whole tree's shape behind it: the keystone and every notable
		for k in range(t["nodes"].size()):
			var nd: Dictionary = t["nodes"][k]
			if (nd.get("keystone", false) or nd.get("notable", false)) and not tree.has("%s/%d" % [parts[0], k]):
				return false
		return true
	var need := Data.node_needs(t, i)
	return need < 0 or tree.has("%s/%d" % [parts[0], need])


func train_node(id: String) -> bool:
	if not can_train(id):
		return false
	tree.append(id)
	log_event("Trained: %s" % node(id)["name"])
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
	cash -= respec_cost()
	tree = []
	log_event("Training reset: the points are free to spend again")
	return true


## Levels earn points for the camp, whatever happens to the operator.
func _earn_points(before: int) -> void:
	var after := level()
	if after > before:
		training_points += after - before
		log_event("Level %d: %d training point%s" % [after, after - before, "" if after - before == 1 else "s"])


func contact(t: Dictionary) -> int:
	if has_node("one_at_a_time"):
		return 1
	if has_rule("gritters_hopper") and mission != null and float(mission.get("chill_t", 0.0)) > 0.0:
		return 1                                 # chilled gangs come one at a time
	return maxi(1, (2 if has_node("overwatch") else CONTACT) + int(t.get("contact", 0)) + int(class_data().get("contact", 0)) + (2 if has_rule("sergeants_whistle") else 0) - (1 if has_set_rule("army") else 0))


## Seconds a search takes: the intel's multiple, cut by Fieldcraft's search nodes.
func search_s(t: Dictionary) -> float:
	return SEARCH_S * float(t.get("search", 1.0)) * maxf(0.4, 1.0 - (tree_sum("search_pct") + _affix_sum("search_pct")) / 100.0) * cm("search") * (2.0 if has_node("never_there") else 1.0) * trait_mult("search") \
		* (1.0 - 0.1 * atlas_rank("deeper_pockets"))


## Seconds to the next lot. The first lot waits for the lookout too; "never
## there" means none ever comes.
func patrol_s(t: Dictionary, first := false) -> float:
	if has_node("never_there"):
		return INF
	var base := (30.0 if has_node("quiet_feet") else PATROL_S) * float(t.get("patrol", 1.0)) * cm("patrol")
	base *= 1.0 + (_fitted_sum("patrol_pct") + tree_sum("patrol_pct") + _affix_sum("patrol_pct")) / 100.0
	base *= Data.KENNEL_LEVELS[kennel_level]["patrol"]
	if first:
		base *= Data.LOOKOUT_LEVELS[lookout_level]["first"] * (2.0 if has_node("early_doors") else 1.0)
	if has_node("loud"):
		base *= 0.6
	return base * trait_mult("patrol") * (1.0 + 0.1 * atlas_rank("quiet_roads")) * (2.0 if has_rule("lollipop") else 1.0)


func use_time(it: Dictionary) -> float:
	if has_node("field_surgery"):
		return 0.0
	return Items.use_time(it) * (0.5 if has_node("triage") else 1.0) * maxf(0.3, 1.0 - (tree_sum("med_speed_pct") + _affix_sum("med_speed_pct")) / 100.0) * (1.3 if has_node("bleed_more") else 1.0)


func pace() -> float:
	return _memo("pace", _pace_raw)


func _pace_raw() -> float:
	var worn := 0.0
	for s in Data.SLOTS:
		if equipped[s] != null:
			worn += Items.base_pace(equipped[s])
	return (1.0 + (_affix_sum("speed_pct") + _fitted_sum("speed_pct") + tree_sum("pace_pct") + worn) / 100.0) * cm("pace") * (0.75 if has_node("one_at_a_time") else 1.0) * (0.7 if has_node("hoarder") else 1.0) * trait_mult("pace") \
		* (1.25 if has_rule("van_keys") else 1.0) * (0.85 if has_node("frost_more") else 1.0) * (1.4 if has_rule("the_float") else 1.0) * wound_mult("pace")


# ------------------------------------------------------------------ ammo

## The rig's stacks for a gun's type, first taken first.
func rounds_for(gun: Dictionary) -> int:
	var n := 0
	var t := Items.ammo_type(gun)
	for it in rig:
		if Items.is_ammo(it) and Items.base_of(it)["type"] == t:
			n += int(it["rounds"])
	return n


func has_rounds(gun: Dictionary) -> bool:
	if Items.ammo_type(gun) == "none" or gun.get("rule", "") == "weed_burner":
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
	var t := Items.ammo_type(gun)
	for it in rig:
		if Items.is_ammo(it) and Items.base_of(it)["type"] == t and int(it["rounds"]) > 0:
			return float(Items.base_of(it).get(stat, 0))
	return 0.0


## Rounds fired this tick come off the first stack of the type; an empty
## stack is dropped, and a gun that's just run dry says so.
func _spend_rounds(gun: Dictionary, shots: float) -> void:
	var t := Items.ammo_type(gun)
	if t == "none" or gun.get("rule", "") == "weed_burner":
		return
	var m: Dictionary = mission
	m["fired"] = m.get("fired", {})
	m["fired"][t] = float(m["fired"].get(t, 0.0)) + shots
	while m["fired"][t] >= 1.0:
		var stack := {}
		for it in rig:
			if Items.is_ammo(it) and Items.base_of(it)["type"] == t and int(it["rounds"]) > 0:
				stack = it
				break
		if stack.is_empty():
			m["fired"][t] = 0.0
			return
		stack["rounds"] = int(stack["rounds"]) - 1
		m["fired"][t] -= 1.0
		if int(stack["rounds"]) <= 0:
			rig.erase(stack)
			_dry_memo.erase("conversion")   # the grade's share goes with the stack (33), in a dry run too
			if rounds_for(gun) <= 0:
				log_event("%s: dry" % gun["base"])


## The fence sells standard boxes of every type without end: a box a type.
func ammo_box(type: String) -> Dictionary:
	for b in Data.BASES[Data.AMMO]:
		if b["type"] == type and not b.has("damage_pct"):
			return b
	return {}


func ammo_price(type: String) -> int:
	var b := ammo_box(type)
	return _inf(b["value"] * Data.AMMO_PRICE) if not b.is_empty() else 0


func buy_ammo(type: String) -> bool:
	var b := ammo_box(type)
	if b.is_empty() or cash < ammo_price(type) or not (stash_room(1) or _stack_room(_plain(Data.AMMO, b["name"]))):
		return false
	cash -= ammo_price(type)
	stash_put(_plain(Data.AMMO, b["name"]))
	return true


## The first med in the rig, for the Use button and the Paramedic's rule.
func first_med() -> Dictionary:
	for it in rig:
		if Items.is_medical(it):
			return it
	return {}


func meds_carried() -> int:
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
		if not u.get("boss", false) and not u.has("site") and int(u.get("depth", 0)) <= at_depth:
			out.append(u)
	return out


## A site's own unique (endgame part 3): one a site, found there only, past
## `site_unique_depth`. Empty for a site without one.
func site_unique(i: int) -> Dictionary:
	for u in Data.UNIQUES:
		if int(u.get("site", -1)) == i:
			return u
	return {}


## The depth a site's own drops from: by the site's zone, the gentler the
## ladder the deeper (the streets at 12, the barracks at 6).
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
		out.append({"name": u["name"], "found": u["name"] in shelf, "where": Words.SHELF["own_gap"] % [Data.TIERS[i]["name"], site_unique_depth(i)]})
	for u in Data.UNIQUES:
		if u.has("pinnacle"):
			for b in Data.BOSSES:
				if int(b["zone"]) == int(u["pinnacle"]):
					out.append({"name": u["name"], "found": u["name"] in shelf, "where": Words.SHELF["head_gap"] % [b["name"], pinnacle_depth(int(b["tier"]))]})
	out.append({"name": Data.CONVOY_UNIQUE, "found": Data.CONVOY_UNIQUE in shelf, "where": Words.SHELF["lorry_gap"] % [convoy_depth(), Data.TIERS[Data.CONVOY_TIER]["name"].to_lower()]})
	return out


## The deepest the yard has been, on any site.
func deepest() -> int:
	var d := 1
	for i in range(best_depth.size()):
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
	return Data.STASH_LEVELS[stash_level]["cells"]


## Cells in use.
func stash_used() -> int:
	var n := 0
	for it in stash:
		n += Items.size(it)
	return n


func stash_room(cells: int) -> bool:
	return stash_used() + cells <= stash_cap()


func stash_cost() -> int:
	if stash_level >= Data.STASH_LEVELS.size() - 1:
		return 0
	return _inf(Data.STASH_LEVELS[stash_level + 1]["cost"])


func can_upgrade_stash() -> bool:
	return stash_level < Data.STASH_LEVELS.size() - 1 and cash >= stash_cost()


func upgrade_stash() -> bool:
	if not can_upgrade_stash():
		return false
	cash -= stash_cost()
	stash_level += 1
	log_event("The stash is bigger: %d cells" % stash_cap())
	return true


## Cells the pack has used on this mission.
func pack_used(m: Dictionary) -> int:
	var n := 0
	for it in m["found"]:
		n += Items.size(it)
	return n


# ------------------------------------------------------------------ the camp's upgrades

func rest_rate() -> float:
	return Data.MEDIC_LEVELS[medic_level]["rest"] * (2.0 if has_node("second_wind") else 1.0) * (1.0 + tree_sum("rest_pct") / 100.0)


func medic_cost() -> int:
	return 0 if medic_level >= Data.MEDIC_LEVELS.size() - 1 else _inf(Data.MEDIC_LEVELS[medic_level + 1]["cost"])


func can_upgrade_medic() -> bool:
	return medic_level < Data.MEDIC_LEVELS.size() - 1 and cash >= medic_cost()


func upgrade_medic() -> bool:
	if not can_upgrade_medic():
		return false
	cash -= medic_cost()
	medic_level += 1
	log_event("The clinic is better kitted: resting heals %.1f HP a second" % Data.MEDIC_LEVELS[medic_level]["rest"])
	return true


func market_cost() -> int:
	return 0 if market_level >= Data.MARKET_LEVELS.size() - 1 else _inf(Data.MARKET_LEVELS[market_level + 1]["cost"])


func can_upgrade_market() -> bool:
	return market_level < Data.MARKET_LEVELS.size() - 1 and cash >= market_cost()


func upgrade_market() -> bool:
	if not can_upgrade_market():
		return false
	cash -= market_cost()
	market_level += 1
	log_event("The fence carries more: %d on the shelf" % Data.MARKET_LEVELS[market_level]["stock"])
	restock()
	return true


func comms_cost() -> int:
	return 0 if comms_level >= Data.COMMS_LEVELS.size() - 1 else _inf(Data.COMMS_LEVELS[comms_level + 1]["cost"])


func can_upgrade_comms() -> bool:
	return comms_level < Data.COMMS_LEVELS.size() - 1 and cash >= comms_cost()


func upgrade_comms() -> bool:
	if not can_upgrade_comms():
		return false
	cash -= comms_cost()
	comms_level += 1
	log_event("Radio level %d: %s" % [comms_level, Data.COMMS_LEVELS[comms_level]["words"].to_lower()])
	return true


## Fresh intel on one tier, for cash - the tower's first job.
func intel_cost(i: int) -> int:
	return int(round(Data.INTEL_CASH[i] * (1.0 - 0.25 * atlas_rank("good_reception"))))


## Open channel (the map's keystone, 7 Oct): every word costs notes, never cash.
func words_in_notes() -> bool:
	return atlas_rank("open_channel") > 0


## A fresh word's price in notes, under Open channel: by the zone.
func intel_notes(i: int) -> int:
	return int(Data.OPEN_CHANNEL_NOTES[0]) * (int(Data.TIERS[i]["zone"]) + 1)


## A called-in word's price in notes, under Open channel.
func juice_notes(i: int) -> int:
	return int(Data.OPEN_CHANNEL_NOTES[1]) * (int(Data.TIERS[i]["zone"]) + 1)


func can_buy_intel(i: int) -> bool:
	return comms_level >= 1 and mission == null and tier_open(i) and (notes >= intel_notes(i) if words_in_notes() else cash >= intel_cost(i))


func buy_intel(i: int) -> bool:
	if not can_buy_intel(i):
		return false
	if words_in_notes():
		notes -= intel_notes(i)
	else:
		cash -= intel_cost(i)
	_roll_tier_intel(i)
	_surv_cache.erase(i)
	log_event("Fresh word on %s: %s" % [tier(i)["name"].to_lower(), ", ".join(intel[i]).to_lower()])
	return true


## Juicing - the radio's third job, at level 3: call in a word of your choosing
## on a tier (up to MAX_WORDS, at JUICE_COST times the tier's word price), or
## lock one word and re-roll the rest. The site is still spent by the run
## unless it's pinned, like PoE's map.
const MAX_WORDS := 3
const JUICE_COST := 3
const JUICE_SHARE := 0.5                  # the pass (6 Oct): a word costs half of what a run on the site pays

func can_juice() -> bool:
	return comms_level >= 3 and campaign_done()


## Cash in, counted: the sinks are priced off what the yard takes a run.
func _earn(x: float) -> void:
	cash += x
	_takings_run += x
	cash_in += x


## What a run on the tier pays in kills, at its depth, before the day's prices.
func run_pay(i: int) -> float:
	var t := effective(i)
	return float(t["cash"]) * float(t["pool"])


## What a run brings in, as the yard has found it lately: the run's cash and the fence's money for
## its loot, averaged over the last few runs, at the day's prices already. The base the endgame's sinks
## are priced off (the pass, 6 Oct): the kills' cash alone was a tenth of it, the loot is the money.
## Before any run has come home, the top open tier's kills.
func a_runs_takings() -> float:
	if takings > 0.0:
		return takings
	return run_pay(top_tier()) * inflation()


## The endgame's cash sink: half a run's pay on the site (never under the tier's word price three
## times over), and more by the words already on it. It was the tier's word price × 3 × the depth,
## which at depth 15 was £70k against a run paying £5k, and the pile sat under it.
func juice_cost(i: int) -> int:
	var base: float = maxf(_inf(Data.INTEL_CASH[i] * JUICE_COST), a_runs_takings() * JUICE_SHARE) * (1.0 + Data.JUICE_WORDS_MULT * intel[i].size())
	return int(round(base * (1.0 - 0.25 * atlas_rank("early_word")) / (2 if atlas_rank("word_travels") > 0 else 1)))


## Insurance: a share of the kit's worth, by the depth of the run.
func insure_cost(i: int) -> int:
	if has_rule("drivers_log"):
		return 0
	return int(ceil(loadout_value() * inflation() * Data.INSURE_RATE * depth[i] / 10.0)) * 10


func can_insure(i: int) -> bool:
	return mission == null and tier_open(i) and cash >= insure_cost(i) and loadout_value() > 0


func set_insure(on: bool) -> void:
	insure_next = on


## The words that could be called in on a tier: every modifier it doesn't have.
func juice_options(i: int) -> Array:
	var out := []
	for m in Data.MODIFIERS:
		if not (m["name"] in intel[i]) and not m.get("sky", false):
			out.append(m["name"])
	return out


## How many words a site carries: MAX_WORDS, one more with Long wave.
func max_words() -> int:
	return MAX_WORDS + atlas_rank("long_wave")


func can_add_word(i: int) -> bool:
	return can_juice() and mission == null and tier_open(i) and intel[i].size() < max_words() and (notes >= juice_notes(i) if words_in_notes() else cash >= juice_cost(i))


func add_word(i: int, name: String) -> bool:
	if not can_add_word(i) or not (name in juice_options(i)):
		return false
	if words_in_notes():
		notes -= juice_notes(i)
	else:
		cash -= juice_cost(i)
	intel[i].append(name)
	_surv_cache.erase(i)
	log_event("Called in on %s: %s" % [tier(i)["name"].to_lower(), name.to_lower()])
	return true


func can_lock_word(i: int) -> bool:
	return can_juice() and mission == null and tier_open(i) and intel[i].size() >= 2 and (notes >= intel_notes(i) * 2 if words_in_notes() else cash >= intel_cost(i) * 2)


## Keep one word, re-roll the others.
func lock_word(i: int, name: String) -> bool:
	if not can_lock_word(i) or not (name in intel[i]):
		return false
	if words_in_notes():
		notes -= intel_notes(i) * 2
	else:
		cash -= intel_cost(i) * 2
	var keep := [name]
	_roll_tier_intel(i)
	for w in intel[i]:
		if w != name and keep.size() < max_words() and not (w in keep):
			keep.append(w)
	intel[i] = keep
	_surv_cache.erase(i)
	log_event("Held %s on %s; the rest re-rolled: %s" % [name.to_lower(), tier(i)["name"].to_lower(), ", ".join(intel[i]).to_lower()])
	return true


## Pin a tier's intel so missions don't spend it - the tower's second job.
func can_pin() -> bool:
	return comms_level >= 2


func set_pinned(i: int, on: bool) -> void:
	if can_pin():
		pinned[i] = on


# ------------------------------------------------------------------ the workshop

func workshop_cost() -> int:
	if workshop >= Data.WORKSHOP.size() - 1:
		return 0
	return _inf(Data.WORKSHOP[workshop + 1]["cost"])


func can_upgrade_workshop() -> bool:
	return workshop < Data.WORKSHOP.size() - 1 and cash >= workshop_cost()


func upgrade_workshop() -> bool:
	if not can_upgrade_workshop():
		return false
	cash -= workshop_cost()
	workshop += 1
	log_event("Bench level %d: %s" % [workshop, Data.WORKSHOP[workshop]["words"].to_lower()])
	return true


func mount_open(mount: String) -> bool:
	if mount.begins_with("socket"):
		return workshop >= 1                 # any bench can seat a socket
	return mount in Data.WORKSHOP[workshop]["mounts"]


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
				return "Needs a bigger bench"
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
	if not (stash_room(1) or _stack_room(gun["attachments"][mount])):
		return false
	stash_put(gun["attachments"][mount])
	gun["attachments"][mount] = null
	return true


## The stash's attachments that go on this mount, best first.
## The stash's parts for a mount, best first; `gun_type` given, only the ones that go on that type of gun.
func attachments_for(mount: String, gun_type := "") -> Array:
	var out: Array = []
	for it in stash:
		if Items.is_attachment(it) and (it["mount"] == mount or (mount.begins_with("socket") and it["mount"] == "socket")):
			if gun_type == "" or Items.att_fits(it, gun_type):
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
		return 0.0                               # a blue plaque: nothing else on you counts
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
const PATROL_S := 20.0
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
	return bosses_beaten[z]


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
		out["contact"] = int(float(out["contact"]) * f)       # toward nothing: half of one on you is none
	if out.has("rarity"):
		out["rarity"] = float(out["rarity"]) * f
	return out


## The depth a crew's head comes at full strength from on a site: PINNACLE_DEPTH for the site's zone (level 14 on his
## own site), a depth deeper for every move made (the ending climbs with the loop), two sooner with Full strength.
func pinnacle_depth(i: int) -> int:
	return int(Data.PINNACLE_DEPTH[int(Data.TIERS[i]["zone"])]) + yard_moves - 2 * atlas_rank("full_strength")


## The depth the lorry runs the services from: CONVOY_DEPTH, a depth deeper a move, two sooner with The lorry's route.
func convoy_depth() -> int:
	return Data.CONVOY_DEPTH + yard_moves - 2 * atlas_rank("lorrys_route")


## From pinnacle_depth(i) a crew's head comes at full strength.
func is_pinnacle(i: int) -> bool:
	return depth[i] >= pinnacle_depth(i)


## The services, deep enough: the convoy, all three crews.
func is_convoy(i: int) -> bool:
	return i == Data.CONVOY_TIER and depth[i] >= convoy_depth() and campaign_done()


## A boss as they come at this tier and depth: the crew's head, or at full strength.
func boss_form(b: Dictionary, e: Dictionary, pinnacle: bool, convoy := false) -> Dictionary:
	var hp: float = e["hp"] * float(b["hp"]) * (Data.PINNACLE_HP if pinnacle else 1.0) * (Data.CONVOY_HP if convoy else 1.0)
	var dps: float = e["dps"] * float(b["dps"]) * (Data.PINNACLE_DPS if pinnacle else 1.0) * (Data.CONVOY_DPS if convoy else 1.0)
	return {"name": b["name"], "hp": hp, "dps": dps, "zone": int(b["zone"]), "pinnacle": pinnacle}


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
## The streets at depth 8 is level 8; the barracks at depth 1 is level 9, at depth 8 level 16. The endgame's
## curve, the bases a find draws from and the item level a find carries all run by it.
func site_level(i: int) -> int:
	return i + depth[i]


## The gear tier a level draws bases from: the streets reach the city's bases at depth 9, the barracks from depth 1.
static func loot_tier_at(level: int) -> int:
	return clampi(int(floor(level * Data.MAX_TIER / 9.0)), 1, Data.MAX_TIER)


## The tier as it will be fought: depth and intel applied. Every multiplier
## the fight and the search read comes from this, not the base table.
func effective(i: int) -> Dictionary:
	var base: Dictionary = Data.TIERS[i]
	var d: int = depth[i]
	var lv: int = i + d
	var e := {
		"name": base["name"], "tier": i, "depth": d, "level": lv, "pool": int(base["pool"]),
		"hp": base["hp"] * pow(1.0 + Data.DEPTH_HOSTILE, d - 1),
		"dps": base["dps"] * pow(1.0 + Data.DEPTH_HOSTILE, d - 1),
		"xp": base["xp"] * pow(1.0 + Data.DEPTH_REWARD, d - 1),
		"cash": base["cash"] * pow(1.0 + Data.DEPTH_REWARD, d - 1),
		"drop": base["drop"] + Data.DEPTH_DROP * (d - 1),
		"loot_tier": int(base["loot_tier"]), "rarity": Data.DEPTH_RARITY * (d - 1),
		"pace": 1.0, "patrol": 1.0, "search": 1.0, "contact": 0, "intel": intel[i].duplicate(),
	}
	if d >= 2 and campaign_done():
		# the endgame (7 Oct): the curve by the site's level, bent by its shape, never under the site's own
		# campaign curve - so the streets' ladder is gentle and long and the barracks' steep and short; the
		# bases a find draws from and its item level follow the level too (the sites were the same fight before)
		var shape: Dictionary = base["shape"]
		var c: Dictionary = Data.CURVE
		var g: float = pow(1.0 + float(c["grow"]), lv - 9)
		var r: float = pow(1.0 + float(c["reward"]), lv - 9)
		e["pool"] = int(shape["pool"])
		e["hp"] = maxf(float(e["hp"]), float(c["hp"]) * g * float(shape["hp"]))
		e["dps"] = maxf(float(e["dps"]), float(c["dps"]) * g * float(shape["dps"]))
		e["xp"] = maxf(float(e["xp"]), float(c["xp"]) * r)
		e["cash"] = maxf(float(e["cash"]), float(c["cash"]) * r * float(shape.get("cash", 1.0)))
		e["drop"] = maxf(float(e["drop"]), float(c["drop"]) + Data.DEPTH_DROP * (d - 2))
		e["loot_tier"] = loot_tier_at(lv)
		e["rarity"] = float(c["rarity"]) * (d - 1)
		e["patrol"] = float(shape.get("patrol", 1.0))
	var night_run: bool = has_node("night_work") or atlas_rank("after_dark") > 0 or is_night() or ("Night" in intel[i])
	if night_run and not ("Night" in intel[i]):
		var night := modifier("Night")
		e["pace"] *= 1.0 - (1.0 - night.get("pace", 1.0)) * (1.0 - 0.5 * atlas_rank("night_eyes"))   # Night eyes: the slower feet halved a rank
		e["rarity"] += night.get("rarity", 0.0) * (1.5 if atlas_rank("after_dark") > 0 else 1.0)   # After dark: the dark gives half again
		e["intel"].append("Night")
	# the map at thirty-six (7 Oct): the sites' and the crews' columns, on every site
	e["drop"] *= 1.0 + 0.1 * atlas_rank("easy_pickings")
	e["cash"] *= (1.0 + 0.1 * atlas_rank("every_penny")) * (1.5 if atlas_rank("heavy_crews") > 0 else 1.0)
	e["xp"] *= (1.0 + 0.1 * atlas_rank("wages")) * (1.5 if atlas_rank("heavy_crews") > 0 else 1.0)
	e["pace"] *= 1.0 + 0.05 * atlas_rank("short_cuts")
	e["contact"] += (1 if atlas_rank("heavy_crews") > 0 else 0) - (1 if atlas_rank("open_ground") > 0 else 0)
	e["rarity"] += 0.05 * atlas_rank("tip_offs")
	if atlas_rank("local_knowledge") > 0:
		e["loot_tier"] = mini(Data.MAX_TIER, int(e["loot_tier"]) + 1)
	if night_run and atlas_rank("dead_air") > 0:
		e["patrol"] *= 1.25
	var sky: String = weather_of(i)
	if sky != "" and not (sky in intel[i]) and atlas_rank("fair_weather") < 2:
		e["intel"].append(sky)               # applied with the words below, softened by Fair weather
	if sky != "" and atlas_rank("forecast") > 0:
		e["cash"] *= 1.2                     # The forecast: a run under the weather pays
	var w := wear(i)
	if w > 0.0:
		e["drop"] *= 1.0 - Data.WORN_DROP * w
		e["cash"] *= 1.0 - Data.WORN_CASH * w
	var b := boss_of(i)
	if boss_armed.get(i, false) and is_convoy(i):
		# the convoy: all three, one after another, come light (CONVOY_HP of their HP, plain fire): the crews stayed with the load
		var queue: Array = []
		for cb in Data.BOSSES:
			queue.append(boss_form(cb, e, false, true))
		e["boss"] = queue[0]
		e["boss_queue"] = queue.slice(1)
		e["convoy"] = true
	elif not b.is_empty() and boss_armed.get(i, false):
		e["boss"] = boss_form(b, e, is_pinnacle(i))
	for name in e["intel"]:
		if name == "Night" and not ("Night" in intel[i]):
			continue                              # the clock's night is applied above
		var m := modifier(name)
		if m.get("sky", false) and atlas_rank("fair_weather") > 0:
			m = _softened(m, 0.5)               # Fair weather: the sky's word bites half as hard
		if name == "Night" and atlas_rank("night_eyes") > 0:
			m = m.duplicate()
			m["pace"] = 1.0 - (1.0 - float(m.get("pace", 1.0))) * (1.0 - 0.5 * atlas_rank("night_eyes"))   # the rolled word, the same eyes
			m["rarity"] = float(m.get("rarity", 0.0)) * (1.5 if atlas_rank("after_dark") > 0 else 1.0)
		e["hp"] *= m.get("hp", 1.0)
		e["dps"] *= m.get("dps", 1.0)
		e["xp"] *= m.get("xp", 1.0)
		e["cash"] *= m.get("cash", 1.0)
		e["drop"] *= m.get("drop", 1.0)
		e["loot_tier"] = mini(Data.MAX_TIER, e["loot_tier"] + int(m.get("loot_tier", 0)))
		e["rarity"] += m.get("rarity", 0.0)
		e["pace"] *= m.get("pace", 1.0)
		e["patrol"] *= m.get("patrol", 1.0)
		e["search"] *= m.get("search", 1.0)
		e["contact"] += int(m.get("contact", 0))
	# what their fire is made of, and what they resist: the zone's, grown by depth, and the words
	var zone: Dictionary = Data.ZONE_TYPES[int(base["zone"])]
	var types := {}
	for ty in zone["types"]:
		types[ty] = minf(Data.ZONE_SHARE_CAP, float(zone["types"][ty]) + Data.ZONE_GROW * (d - 1))
	# a zone hardens with depth against its own: what it wears and what it throws; the rest stays open, so every site is somebody's
	var res := {}
	for ty in Data.TYPES:
		var own: bool = zone["res"].has(ty) or zone["types"].has(ty)
		res[ty] = float(zone["res"].get(ty, 0.0)) + (Data.RESIST_DEPTH_STEP * (d - Data.RESIST_DEPTH + 1) if d >= Data.RESIST_DEPTH and own else 0.0)
	for name in intel[i]:
		var m := modifier(name)
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
	e["types"] = types
	e["res"] = res
	return e


func modifier(name: String) -> Dictionary:
	for m in Data.MODIFIERS:
		if m["name"] == name:
			return m
	return {}


## New intel on every tier that isn't pinned: one modifier, two from tier 2
## and at depth 3 up.
func reroll_intel(force := false) -> void:
	for i in range(Data.TIERS.size()):
		if pinned[i] and not force:
			continue
		_roll_tier_intel(i)


func _roll_tier_intel(i: int) -> void:
	var n := 1 if (i == 0 and depth[i] < 3) else 2
	if Data.TIERS[i]["zone"] >= 1:
		n = 2
	n += atlas_rank("long_wave")              # Long wave: one more word a site
	var names := []
	var clear: bool = atlas_rank("clear_air") > 0
	var pool: Array = Data.MODIFIERS.filter(func(m): return not m.get("sky", false) and not (clear and m["name"] == "Resistant"))   # the sky's words come from the clock, not the radio; Clear air never hears Resistant
	pool.shuffle()
	for k in range(n):
		names.append(pool[k]["name"])
	intel[i] = names


## Depth up or down. The word on the tier stays as it is - it only changes
## after a run, so it can't be re-rolled by stepping the depth back and forth.
func set_depth(i: int, d: int) -> void:
	if mission == null:
		# the ladder is the endgame's; a moved yard's opens to the floor from a site's first clear (7 Oct)
		var top: int = maxi(best_depth[i] + 1, (ladder_floor() + 1) if best_depth[i] > 0 else 1) if campaign_done() else 1
		if campaign_done() and best_depth[i] > 0 and atlas_rank("lie_of_the_land") > 0:
			top += 1                          # The lie of the land: one past the deepest cleared
		depth[i] = clampi(d, 1, top)


func on_mission() -> bool:
	return mission != null


func searching() -> bool:
	return mission != null and mission["cleared"]


func can_deploy() -> bool:
	return mission == null and hp > 0.0


func can_deploy_to(i: int) -> bool:
	return can_deploy() and tier_open(i)


## Seconds a tier's fight should take at the operator's damage, for the card.
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
var _dry_min_hp := 1.0               # the last dry run's lowest HP, as a share of the max
## Where the time goes (8 Oct, the pass at an hour): counts and microseconds the balance gate prints. Cheap
## enough to leave on: a few adds a tick.
var prof := {"surv_calls": 0, "surv_reads": 0, "surv_us": 0, "dry_runs": 0, "dry_ticks": 0, "snap_us": 0, "real_ticks": 0, "real_us": 0}


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
	return [int(round(hp * 10.0 / maxf(max_hp(), 1.0))), _odds_bucket(max_hp()), _odds_bucket(dps()), _odds_bucket(armour()), _odds_bucket(pace() * 100.0), depth[i], str(intel[i]), tree.size(), rig.size(), boss_armed.get(i, false), campaign_done(), yard_moves, str(atlas), weather_of(i), is_night(), wound, _kit_ids()]


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
	var runs: int = Data.LOOKOUT_LEVELS[lookout_level]["runs"]
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
	return _surv_cache.has(i) and _surv_cache[i][0] == _odds_key(i) and _surv_cache[i][2] >= int(Data.LOOKOUT_LEVELS[lookout_level]["runs"])


## The fight alone, run through the real fight code on a scratch mission with
## nothing kept - the same rates, rules, dots, keystones and meds as a run -
## DRY_STEP seconds at a time: true if it ends with HP left. The state goes
## back as it was: HP, XP, the rig, the log, the dice.
const DRY_STEP := 2.0
const BAIL := 0.25                   # the HP a player (and the bots) get out at: the odds count that as lost
func _dry_run(i: int, r: RandomNumberGenerator) -> bool:
	var p0 := Time.get_ticks_usec()
	prof["dry_runs"] += 1
	var t := effective(i)
	var keep := {"hp": hp, "xp": xp, "rig": rig.duplicate(true), "events": events.duplicate(true), "mission": mission,
		"rng": rng, "promised": promised, "training_points": training_points, "insure_next": insure_next}
	prof["snap_us"] += Time.get_ticks_usec() - p0
	rng = r
	var pool: int = int(t["pool"]) - (1 if has_node("trapline") else 0)
	var m := {
		"tier": i, "t": t, "remaining": maxi(1, pool), "target_hp": float(t["hp"]), "kills": 0, "found": [], "insured": false,
		"left": 0, "cash": 0.0, "xp": 0.0, "elapsed": 0.0, "hp_start": hp, "cleared": false,
		"search": 0.0, "searches": 0, "patrol_timer": 0.0, "patrols": 0, "last_incoming": 0.0,
		"using": null, "meds_used": 0, "fresh": true, "swapped": 0, "event": "", "event_at": -1.0, "dry": true,
	}
	if t.has("boss"):
		m["boss"] = _boss_entry(t["boss"])
		m["boss_queue"] = []
		for q in t.get("boss_queue", []):
			m["boss_queue"].append(_boss_entry(q))
		m["convoy"] = t.get("convoy", false)
	mission = m
	_dry_rules = _snapshot_rules()
	_dry_memo = {}
	_dry_on = true
	var guard := 0
	_dry_min_hp = 1.0
	while guard < 450 and not m.get("dead", false):    # fifteen minutes of fighting is a loss
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
		guard += 1
	var alive: bool = not m.get("dead", false) and hp > 0.0 and guard < 450
	_dry_on = false
	hp = keep["hp"]
	xp = keep["xp"]
	rig = keep["rig"]
	events = keep["events"]
	mission = keep["mission"]
	rng = keep["rng"]
	promised = keep["promised"]
	training_points = keep["training_points"]
	insure_next = keep["insure_next"]
	return alive


func deploy(i: int) -> void:
	if not can_deploy_to(i):
		return
	if not candidates.is_empty():
		choose_runner(0)                  # nobody picked: the first one stays
	_dry_memo.clear()                     # the run reads the kit as it stands at the gate (fast_memo)
	_memo_age = 0.0
	var t := effective(i)
	if t.has("boss"):
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
	var pool: int = int(t["pool"]) - (1 if has_node("trapline") else 0)
	mission = {
		"tier": i, "t": t, "remaining": maxi(1, pool), "target_hp": float(t["hp"]), "kills": 0, "found": [], "insured": insured,
		"left": 0, "cash": 0.0, "xp": 0.0, "elapsed": 0.0, "hp_start": hp, "cleared": false,
		"search": 0.0, "searches": 0, "patrol_timer": 0.0, "patrols": 0, "last_incoming": 0.0,
		"using": null, "meds_used": 0, "fresh": true, "swapped": 0,
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
	if rng.randf() < Data.EVENT_ODDS or has_rule("caretakers_keys"):
		mission["event"] = Data.EVENTS[rng.randi_range(0, Data.EVENTS.size() - 1)]
		mission["event_at"] = rng.randf_range(Data.EVENT_WINDOW[0], Data.EVENT_WINDOW[1])
	runner_runs += 1
	runs_total += 1
	if runs_total % Data.MATE_RUNS == 0:
		mate = roll_mate()
	log_event("Out to %s, %s, depth %d: %s" % [t["name"], zone_name(i), t["depth"], ", ".join(t["intel"]).to_lower()])
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
			# rest only as far as the redeploy point, then go again
			var dt := minf(left, (ready - hp) / rest_rate())
			hp = minf(max_hp(), hp + rest_rate() * dt)
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
		_fight(m, t, dt)
	else:
		_search(m, t, dt)
		if has_node("walk_it_off"):
			hp = minf(max_hp(), hp + dt)
	if mission == null:
		return
	if _affix_sum("regen") > 0.0:
		_heal(m, _affix_sum("regen") * dt)
	if has_rule("nans_cardigan"):
		_heal(m, max_hp() * 0.03 * dt)
	if float(m.get("event_at", -1.0)) >= 0.0 and m["elapsed"] >= float(m["event_at"]):
		_event(m, t)
	# the Medic's rule: a med by itself under 40%
	if class_data().get("auto_med", false) and m["using"] == null and hp < max_hp() * 0.4 and not first_med().is_empty():
		use_med(first_med()["id"])
	_patch(m, dt)
	if float(m.get("immune_t", 0.0)) > 0.0:
		m["immune_t"] = maxf(0.0, float(m["immune_t"]) - dt)     # Clean hands' grace runs down whether they're on you or not
	if m["cleared"]:
		if not gang_held(m):
			m["patrol_timer"] += dt
		if m["patrol_timer"] >= patrol_s(t, m["patrols"] == 0):
			m["patrol_timer"] = 0.0
			m["patrols"] += 1
			m["fresh"] = true
			m["sustain_t"] = 0.0
			var grown: int = 0 if has_node("cap_dead_quiet") else m["patrols"] - 1      # Dead quiet: every gang the size of the first
			var size: int = maxi(1, PATROL_BASE + grown - (1 if has_node("trapline") else 0) + (1 if has_node("loud") else 0) - (1 if has_rule("wardens_hat") else 0))
			if has_rule("scouts_whistle"):
				size = 1
			if has_node("cap_poached"):
				_find(m, t)                  # Poached: they arrive already light
			if has_node("hit_and_run"):
				_extract()                  # out when the first gang comes
				return
			m["remaining"] += size
			if m["target_hp"] <= 0.0:
				m["target_hp"] = float(t["hp"])
			log_event("Another gang, %d of them" % size)
			if auto_tier >= 0 or m.get("leave_full", false):
				_extract()                  # auto-run, or "fill up then go", leaves as the gang arrives
				return
	if (auto_tier >= 0 or m.get("leave_full", false)) and m["cleared"] and pack_used(m) >= capacity():
		_extract()


## "Fill up, then go": with the fight won, keep searching and leave by itself
## when the pack's full or the next gang comes - the auto-run's rule, for one
## run, so a long gang delay isn't three minutes of watching.
func set_leave_full(on: bool) -> bool:
	if mission == null:
		return false
	mission["leave_full"] = on
	if on and mission["cleared"] and pack_used(mission) >= capacity():
		_extract()
	return true


## HP back, counted for the run screen's green numbers (regen, a med, life on a kill).
## `med` marks a med's heal: Transfusion keeps its overflow, not a trickle's.
func _heal(m: Dictionary, amount: float, med := false) -> void:
	var before := hp
	hp = minf(max_hp(), hp + amount)
	m["healed"] = float(m.get("healed", 0.0)) + (hp - before)
	if med and has_node("cap_transfusion"):
		m["bonus_armour"] = float(m.get("bonus_armour", 0.0)) + maxf(0.0, amount - (hp - before)) / 2.0     # Transfusion: a med's overflow is armour, two to one


func _boss_entry(b: Dictionary) -> Dictionary:
	return {"name": b["name"], "hp": b["hp"], "dps": b["dps"], "zone": b["zone"], "pinnacle": b.get("pinnacle", false), "started": false, "alive": true}


## The run's event, once.
func _event(m: Dictionary, t: Dictionary) -> void:
	var what: String = str(m.get("event", ""))
	m["event_at"] = -1.0
	m["event_done"] = what
	match what:
		"convoy":
			var size: int = PATROL_BASE + 2
			m["remaining"] += size
			if m["target_hp"] <= 0.0:
				m["target_hp"] = float(t["hp"])
			m["fresh"] = true
			m["sustain_t"] = 0.0
			m["notes"] = int(m.get("notes", 0)) + notes_a_kill(t) * size
			log_event("%s %s" % [Words.EVENTS["convoy"], Words.EVENTS["convoy_notes"]])
		"trapped":
			var pool: Array = []
			for tr in Data.TRAITS:
				if tr["name"] != runner_trait:
					pool.append(tr["name"])
			promised = pool[rng.randi_range(0, pool.size() - 1)]
			log_event(Words.EVENTS["trapped"])
		"cache":
			if workshop >= Data.EVENT_CACHE_BENCH or has_rule("caretakers_keys") or has_set_rule("council"):
				var up: Dictionary = t.duplicate()
				up["loot_tier"] = mini(Data.MAX_TIER, int(t["loot_tier"]) + 1)
				up["rarity"] = float(t.get("rarity", 0.0)) + 0.5
				_find(m, up)
				log_event(Words.EVENTS["cache"])
			else:
				log_event(Words.EVENTS["cache_shut"])


func _fight(m: Dictionary, t: Dictionary, dt: float) -> void:
	var swing := rng.randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	var headshot := 1.0
	if m["fresh"]:
		headshot += (0.25 if has_node("headshots") else 0.0) + (_fitted_sum("first_pct") + float(class_data().get("first_pct", 0)) + grade_stat(equipped["Primary"], "first_pct")) / 100.0   # match rounds: a flat crit on the first (33)
	headshot += tree_sum("first_pct") / 100.0 if m["fresh"] else 0.0
	if m["fresh"] and atlas_rank("marked_men") > 0:
		headshot += 0.25
	if m["fresh"] and has_rule("grandads"):
		headshot += 2.0
	if m["fresh"] and (has_node("one_shot") or has_rule("lollipop")):
		m["target_hp"] = 0.0              # the first of the lot drops where it stands
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
	for ty in Data.TYPES:
		var landed: float = float(per_type[ty]) * (1.0 - float(res.get(ty, 0.0))) * mult * ((1.0 + shock_amount()) if shocked else 1.0)
		if ty == "physical" and has_node("cap_shatter") and float(m.get("chill_t", 0.0)) > 0.0:
			landed *= 2.0                             # Shatter: a chilled target takes double from the physical
		if ty == "frost" and has_rule("gritters_keys") and float(m.get("chill_t", 0.0)) > 0.0:
			landed *= 2.0                             # the gritter's keys: chilled, they take double frost
		if ty == "bleed" and has_node("cap_bleed_out"):
			landed *= 1.5                             # Bleed out: bleeds half again as hard
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
			_dot_add(m["dots"], ty, landed, float(per_type[ty]) * (1.0 - float(res.get(ty, 0.0))) * pace() * t["pace"] * (1.5 if (ty == "bleed" and has_node("cap_bleed_out")) else 1.0))
			if ty == "frost":
				m["chill_t"] = 999.0 if has_rule("gritters_keys") else 1.0    # the gritter's keys: a chill holds as long as you fire
			if ty == "shock":
				m["shock_t"] = 999.0 if (has_rule("tester") or has_node("cap_arc")) else 1.0     # Arc: the shock holds as long as you fire
	if has_rule("gritters_hopper"):
		m["chill_t"] = 1.0                        # everyone on you is chilled, always
	m["target_hp"] -= landed_total
	var ticked_on_them := 0.0
	if m.has("dots"):
		if not m.has("dealt_by"):
			m["dealt_by"] = {}
		ticked_on_them = _dot_tick(m["dots"], dt, m["dealt_by"])
		m["target_hp"] -= ticked_on_them
	m["dealt"] = float(m.get("dealt", 0.0)) + landed_total + ticked_on_them    # for the numbers on the run screen
	# the rounds behind that: the primary's rate while it's live, the secondary's when it fires
	var primary_live := equipped["Primary"] != null and has_rounds(equipped["Primary"])
	if primary_live and not has_rule("qm_rifle"):
		_spend_rounds(equipped["Primary"], Items.base_of(equipped["Primary"])["rof"] * pace() * t["pace"] * dt)
	# the secondary spends what it fires: its full rate when it's the gun in
	# hand (the primary dry or gone, or Double tap), a third while it backs the primary
	if equipped["Secondary"] != null and has_rounds(equipped["Secondary"]):
		var share: float = 1.0 if (not primary_live or has_node("double_tap") or has_rule("vans_spare")) else 1.0 / 3.0
		_spend_rounds(equipped["Secondary"], Items.base_of(equipped["Secondary"])["rof"] * pace() * t["pace"] * dt * share)
	var boss_on: bool = m.has("boss") and m["boss"]["started"] and m["boss"]["alive"]
	while m["target_hp"] <= 0.0 and m["remaining"] > 0:
		m["remaining"] -= 1
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
		var carried := {}
		if (has_rule("rat_mans_bag") or has_node("cap_lingers")) and m.get("dots", {}).has("poison"):
			carried["poison"] = m["dots"]["poison"]  # the rat man's bag, or Lingers: poison carries to the next
		if (has_rule("butchers_steel") or has_rule("butchers_apron") or has_node("cap_bleed_out")) and m.get("dots", {}).has("bleed"):
			carried["bleed"] = m["dots"]["bleed"]
		if has_node("cap_spread") and m.get("dots", {}).has("fire"):
			carried["fire"] = m["dots"]["fire"]      # Spread: the burn carries
		m["dots"] = carried                  # the next of them is a new target
		m["chill_t"] = 0.0
		m["shock_t"] = 0.0
		_kill(m, t)
	if m["remaining"] <= 0:
		if m.has("boss") and m["boss"]["alive"] and not m["boss"]["started"]:
			# the pool is down; the crew's head comes out
			m["boss"]["started"] = true
			m["remaining"] = 1
			m["target_hp"] = float(m["boss"]["hp"])
			m["fresh"] = true
			m["sustain_t"] = 0.0
			log_event("%s comes out%s. %s" % [m["boss"]["name"], ", at full strength" if m["boss"].get("pinnacle", false) else "", Words.BOSSES.get(m["boss"]["name"], {}).get("out", "")])
			return
		m["target_hp"] = 0.0
		m["last_incoming"] = 0.0
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
		incoming *= 0.5
	if on_you >= 3:
		incoming *= 1.0 - _affix_sum("crowd_less_pct") / 100.0
	if on_you >= 3 and has_rule("doormans"):
		incoming *= 0.75
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
	for ty in shares:
		m["taken_by"][ty] = float(m["taken_by"].get(ty, 0.0)) + incoming * dt * float(shares[ty])
	var fire_pool: float = float(m["my_dots"].get("fire", 0.0))
	var ticked_by := {}
	var ticked: float = _dot_tick(m["my_dots"], dt, ticked_by)
	if has_rule("vicars_thermos") and fire_pool > 0.0:
		var fire_tick: float = fire_pool - float(m["my_dots"].get("fire", 0.0))
		ticked -= fire_tick
		ticked_by.erase("fire")
		_heal(m, fire_tick)                        # a burn on you heals you instead
	for ty in ticked_by:
		m["taken_by"][ty] = float(m["taken_by"].get(ty, 0.0)) + float(ticked_by[ty])
	incoming += ticked / maxf(dt, 0.001)
	if has_node("cap_held"):
		incoming = minf(incoming, max_hp() * 0.1)       # Held: no second of their fire, their shots and what they left on you, takes more than a tenth
	m["last_incoming"] = incoming
	var above: bool = hp >= max_hp() * Data.WOUND_AT
	hp -= incoming * dt
	m["taken"] = float(m.get("taken", 0.0)) + incoming * dt     # for the run screen's red numbers
	if above and hp > 0.0 and hp < max_hp() * Data.WOUND_AT and not m.get("dry", false):
		_wound(m)                            # the hit that took them under a quarter leaves a wound (30); never a dry run's, which restores hp but not the wound
		if auto_tier >= 0:
			auto_tier = -1                   # auto-run stops on a wound: the clinic is a decision, not a silent tax
			log_event("Auto-run stopped: wounded")
	if hp <= 0.0:
		if has_node("not_today") and not m.get("saved", false):
			m["saved"] = true
			hp = max_hp() * 0.5
			log_event("Not today: back up on half HP")
			return
		_kia()


## Using a med: the seconds run down under whatever fire there is, then it heals.
func use_med(id: int) -> bool:
	if mission == null or mission["using"] != null:
		return false
	for k in range(rig.size()):
		if rig[k]["id"] == id:
			var it: Dictionary = rig[k]
			if (has_node("second_shift") or has_set_rule("ambulance")) and not mission.get("free_med", false):
				mission["free_med"] = true     # the first med of the run isn't spent
			else:
				rig.remove_at(k)
			mission["using"] = {"name": it["base"], "left": use_time(it), "heal": Items.heal(it) * cm("heal") * trait_mult("heal") * (1.0 + tree_sum("heal_pct") / 100.0) * (0.5 if has_node("walking_wounded") else 1.0) * (0.0 if has_rule("ladle") else 1.0) * (2.0 if has_set_rule("ambulance") else 1.0)}
			_patch(mission, 0.0)          # field surgery: at once
			return true
	return false


## The arsonist's rig: a petrol bomb's worth of fire on everyone on you, through the model.
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
			single *= 1.5                     # Bleed out: a nail bomb's bleed, half again too
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
			m["chill_t"] = 2.0
		if ty == "shock":
			m["shock_t"] = 999.0 if (has_rule("tester") or has_node("cap_arc")) else 2.0
		m["thrown"] = int(m.get("thrown", 0)) + 1
		log_event("%s thrown: %.0f %s to %d of them" % [it["base"], landed, ty, crowd])
		return true
	return false


func _patch(m: Dictionary, dt: float) -> void:
	if m["using"] == null:
		return
	m["using"]["left"] -= dt
	if m["using"]["left"] <= 0.0 or has_node("field_surgery"):
		_heal(m, m["using"]["heal"], true)
		if m.has("my_dots"):
			m["my_dots"].erase("bleed")      # a dressing stops the bleeding
		if has_node("cap_clean_hands"):
			m["my_dots"] = {}                # Clean hands: everything on you cleared, and a grace
			m["immune_t"] = 3.0
		if has_rule("arsonists_rig") and m["remaining"] > 0:
			_alight(m)                       # the arsonist's rig: the med's a petrol bomb's worth on everyone on you
		m["meds_used"] += 1
		log_event("%s used: HP %d" % [m["using"]["name"], ceili(hp)])
		m["using"] = null


func _kill(m: Dictionary, t: Dictionary) -> void:
	m["kills"] += 1
	_heal(m, _affix_sum("life_per_kill") + (max_hp() * 0.1 if has_rule("ladle") else 0.0) + (max_hp() * 0.1 if has_node("cap_iron") and hp < max_hp() * 0.5 else 0.0))
	if m.get("dry", false):
		return                               # a dry run: the fight only, nothing earned
	var gain: float = t["xp"] * (1.5 if has_node("hit_and_run") else 1.0)
	m["xp"] += gain
	var before := level()
	xp += gain
	_earn_points(before)
	var pay := 1.0 if not has_node("hit_and_run") else 1.5
	m["cash"] += (t["cash"] * rng.randf_range(0.5, 1.5) * (1.0 + (tree_sum("cash_pct") + charm_cash()) / 100.0) + _affix_sum("cash_per_kill")) * inflation() * pay * (0.5 if has_rule("bookies_pencil") else 1.0) * (2.0 if has_set_rule("bank") else 1.0) \
		* (0.8 if has_node("light_fingers") else 1.0) * (1.5 if has_rule("managers_coat") else 1.0) * trait_mult("cash")
	if not has_rule("managers_coat"):
		m["notes"] = int(m.get("notes", 0)) + notes_a_kill(t)
	if has_node("quiet_hands"):
		return
	if has_node("nothing_wasted") or rng.randf() < t["drop"] * (1.0 + loot_bonus()) * (1.3 if has_node("loud") else 1.0) * (1.0 + 0.1 * atlas_rank("their_own_kit")) * pay:
		if has_rule("qm_ledger"):
			var up: Dictionary = t.duplicate()
			up["loot_tier"] = mini(Data.MAX_TIER, int(t["loot_tier"]) + 1)     # signed for: a tier up
			_find(m, up, true)
		else:
			_find(m, t, true)


## The old paper money: every kill carries some, more the deeper you are.
func notes_a_kill(t: Dictionary) -> int:
	return (int(ceil(Data.NOTES_KILL * (1.0 + (int(t["depth"]) - 1) / 3.0) * (1.0 + _affix_sum("notes_pct") / 100.0))) + atlas_rank("paid_in_notes")) * (2 if has_rule("wardens_hat") else 1)


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
	m["cash"] += t["cash"] * 10.0 * inflation()
	m["notes"] = int(m.get("notes", 0)) + int(round(Data.NOTES_BOSS * int(t["depth"]) * (1.0 + 0.5 * atlas_rank("bounties"))))
	if b.get("pinnacle", false) and atlas_rank("head_start") > 0:
		atlas_points += 1                     # Head start: a head beaten at full strength pays a map point
		log_event(Words.MAP["head_start"] % b["name"])
	var first: bool = not bosses_beaten[int(b["zone"])]
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
		# the last of the convoy: the lorry's load comes home too, and the yard's ending is written (7 Oct)
		var load := Items.roll_unique(_unique_named(Data.CONVOY_UNIQUE), rng, int(t.get("level", -1)))
		m["found"].append(load)
		_read(load)
		log_event("The convoy's done. Found: %s" % load["unique"])
		if not lorry_done:
			lorry_done = true
			lorries += 1
			log_event(Words.YARD["lorry"])
	if not pool.is_empty():
		var it := Items.roll_unique(pool[rng.randi_range(0, pool.size() - 1)], rng, int(t.get("level", -1)))
		m["found"].append(it)                  # theirs comes home whatever the pack holds
		_read(it)
		log_event("%s is down. %s Found: %s" % [b["name"], Words.BOSSES.get(b["name"], {}).get("down", ""), it["unique"]])
		if atlas_rank("two_of_everything") > 0:
			var it2 := Items.roll_unique(pool[rng.randi_range(0, pool.size() - 1)], rng, int(t.get("level", -1)))
			m["found"].append(it2)
			_read(it2)
			log_event("And a second: %s." % it2["unique"])
	if first and campaign_done():
		log_event(Words.YARD["campaign"])


## A find. `from_kill`: what they were carrying - guns, armour, a helmet, a
## rig. From a look: what the site holds - attachments, meds, packs, and a
## share of gear left lying about.
func _find(m: Dictionary, t: Dictionary, from_kill := false) -> void:
	m["finds"] = int(m.get("finds", 0)) + 1    # every find, stacked, swapped or left: the count the tests read
	if has_node("all_or_nothing"):
		m["skipped"] = int(m.get("skipped", 0)) + 1
		if m["skipped"] % 2 == 0:
			return                        # half as much is found
	# the site's own shape of find: its slot weights, and its leanings to
	# meds, ammo, parts and papers
	var site: Dictionary = Data.TIERS[int(t["tier"])]
	var shape: Dictionary = site["shape"]
	var slot: String = _site_slot(site, from_kill)
	var kind := rng.randf()
	if from_kill:
		if kind < Data.MED_DROP * 0.5 * float(shape.get("med", 1.0)):
			slot = Data.MEDICAL
		elif kind < Data.MED_DROP * 0.5 * float(shape.get("med", 1.0)) + Data.AMMO_DROP * float(shape.get("ammo", 1.0)):
			slot = Data.AMMO
	else:
		if rng.randf() < Data.PAPER_DROP * float(shape.get("paper", 1.0)) * (3.0 if has_node("light_fingers") else 1.0):
			slot = Data.PAPER
		elif rng.randf() < Data.CHARM_DROP:
			slot = Data.CHARM
		elif kind < Data.MED_DROP * float(shape.get("med", 1.0)):
			slot = Data.MEDICAL
		elif kind < Data.MED_DROP * float(shape.get("med", 1.0)) + (Data.ATT_DROP + tree_sum("att_share") / 100.0) * float(shape.get("att", 1.0)):
			slot = Data.ATTACHMENT
		elif kind < Data.MED_DROP * float(shape.get("med", 1.0)) + (Data.ATT_DROP + tree_sum("att_share") / 100.0) * float(shape.get("att", 1.0)) + Data.AMMO_DROP * 0.5 * float(shape.get("ammo", 1.0)):
			slot = Data.AMMO
		elif kind < Data.MED_DROP * float(shape.get("med", 1.0)) + (Data.ATT_DROP + tree_sum("att_share") / 100.0) * float(shape.get("att", 1.0)) + Data.AMMO_DROP * 0.5 * float(shape.get("ammo", 1.0)) + Data.GRENADE_DROP:
			slot = Data.GRENADE                   # a grenade lying about (32)
	var it: Dictionary
	var loose: Array = loose_uniques(int(t["depth"]))
	var pieces: Array = set_pieces_at(int(t["depth"]))
	var own: Dictionary = site_unique(int(t["tier"]))
	var own_odds: float = Data.SITE_UNIQUE_DROP * (1.0 if own.is_empty() or not (own["name"] in shelf) else Data.SITE_UNIQUE_AGAIN)
	if not own.is_empty() and int(t["depth"]) >= site_unique_depth(int(t["tier"])) and rng.randf() < own_odds:
		it = Items.roll_unique(own, rng, int(t.get("level", -1)))     # the site's own, only here and only this deep (endgame part 3)
		log_event("Found: %s. %s" % [it["unique"], Words.SHELF["own_found"] % site["name"]])
	elif t["depth"] >= 2 and rng.randf() < Data.UNIQUE_DROP * (t["depth"] - 1):
		it = Items.roll_unique(loose[rng.randi_range(0, loose.size() - 1)], rng, int(t.get("level", -1)))
		log_event("Found: %s" % it["unique"])
	elif t["depth"] >= 2 and not pieces.is_empty() and rng.randf() < Data.SET_DROP * (t["depth"] - 1):
		var pick: Array = pieces[rng.randi_range(0, pieces.size() - 1)]
		it = Items.roll_set_piece(pick[0], pick[1], rng, int(t.get("level", -1)))
		log_event("Found: %s, %s" % [it["piece"], str(pick[0]).to_lower()])
	else:
		# quality decides the rarity: the trees', the charm's and the intel's; quantity is how much, not how good (27)
		it = Items.roll(slot, 1 if slot == Data.PAPER else int(t["loot_tier"]), rng, rarity_bonus() + float(t.get("rarity", 0.0)), has_node("all_or_nothing"), has_rule("lucky_cap"),
			site["name"], str(site["drops"].get("type", "")), 0.33 + 0.1667 * atlas_rank("picked_over"), int(t["depth"]), int(t.get("level", int(t["tier"]) + int(t["depth"]))))
		if slot == Data.AMMO and equipped["Primary"] != null and rng.randf() < 0.5:
			# half the rounds found fit what's in your hands
			var mine := Items.ammo_type(equipped["Primary"])
			var fits := []
			for b in Data.BASES[Data.AMMO]:
				if b["type"] == mine and b["tier"] <= int(t["loot_tier"]):
					fits.append(b)
			if not fits.is_empty():
				it = _plain(Data.AMMO, fits[rng.randi_range(0, fits.size() - 1)]["name"])
	if has_node("cap_loaded_dice") and int(it.get("rarity", 0)) >= 2 and not it.has("unique") and not it.has("set"):
		var again: Dictionary = Items.roll(slot, 1 if slot == Data.PAPER else int(t["loot_tier"]), rng, rarity_bonus() + float(t.get("rarity", 0.0)), has_node("all_or_nothing"), has_rule("lucky_cap"),
			site["name"], str(site["drops"].get("type", "")), 0.33 + 0.1667 * atlas_rank("picked_over"), int(t["depth"]), int(t.get("level", int(t["tier"]) + int(t["depth"]))))
		if Items.score(again) > Items.score(it):
			it = again                       # Loaded dice: a Rare or better rolls twice, keeps the better
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
	# the pack is full: the find takes the place of the cheapest thing at
	# least its size, if it's worth more; anything else is passed over
	var cheapest := -1
	for k in range(m["found"].size()):
		if Items.size(m["found"][k]) >= Items.size(it) and (cheapest < 0 or m["found"][k]["value"] < m["found"][cheapest]["value"]):
			cheapest = k
	if cheapest >= 0 and it["value"] > m["found"][cheapest]["value"]:
		m["found"][cheapest] = it
		m["swapped"] = m.get("swapped", 0) + 1
		_read(it)
	else:
		m["left"] += 1


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
	var bonus: float = t["xp"] * t["pool"] * Data.CLEAR_BONUS * (2.0 if has_node("stand") else 1.0)
	m["xp"] += bonus
	var before := level()
	xp += bonus
	_earn_points(before)
	best_tier = maxi(best_tier, mini(Data.TIERS.size() - 1, m["tier"] + 1))
	if best_depth[m["tier"]] == 0 and ladder_floor() > 0:
		log_event("%s cleared; this yard's ladders start at depth %d" % [t["name"], ladder_floor() + 1])     # the floor opens the depths (set_depth); the clears stay honest for the wall and the map
	if t["depth"] > best_depth[m["tier"]]:
		best_depth[m["tier"]] = t["depth"]
		log_event("%s cleared at depth %d; depth %d is open" % [t["name"], t["depth"], t["depth"] + 1])
		if t["depth"] >= 2:
			atlas_points += 1
			log_event("A point on the map.")
	if t["depth"] >= 2 and (t["depth"] > int(best_dig.get("depth", 0)) or (t["depth"] == int(best_dig.get("depth", 0)) and m["tier"] > int(best_dig.get("tier", -1)))):
		best_dig = {"site": t["name"], "tier": m["tier"], "depth": t["depth"], "yard": yard_moves + 1}     # the ladder's, not the campaign's
	if m["tier"] == 2 and not depot_cleared:
		depot_cleared = true
	if not seen.has("cleared/%d" % m["tier"]):
		seen["cleared/%d" % m["tier"]] = true
		log_event(Words.site_cleared(t["name"]))
	else:
		log_event("%s cleared. Picking it over; more will come" % t["name"])
	if m["tier"] == Data.BANK and not deeds_found:
		deeds_found = true
		var deeds := _plain(Data.PAPER, "The deeds")
		deeds["deeds"] = true
		m["found"].append(deeds)            # whatever the pack holds, this comes too
		log_event(Words.DEEDS["found"])


## Picked over inside a run (29): the searches a site gives in full before its
## finds thin. By depth, and quantity bonuses push it.
func thin_after(t: Dictionary) -> int:
	var n: float = Data.THIN_AFTER + Data.THIN_PER_DEPTH * int(t["depth"])
	return int(roundf(n * (1.0 + maxf(0.0, loot_bonus()))))


## The share of a search's finds still there, 1 until thin_after, then a fifth
## less a search to the floor.
func thinning(m: Dictionary, t: Dictionary) -> float:
	# the searches in full only grow through a run (a med used would shrink the quantity bonus): the best figure yet holds
	m["thin_after"] = maxi(int(m.get("thin_after", 0)), thin_after(t))
	var past: int = maxi(0, int(m["searches"]) - int(m["thin_after"]))
	return clampf(1.0 - Data.THIN_STEP * past, Data.THIN_FLOOR, 1.0)


## The lookout's top level (31): the first gang after the clear waits for the call, and the call is a full pack.
func gang_held(m: Dictionary) -> bool:
	return m["patrols"] == 0 and Data.LOOKOUT_LEVELS[lookout_level].get("call", false) and pack_used(m) < capacity() and not m.get("dry", false)


## Nothing alive on the site: a cache every SEARCH_S.
func _search(m: Dictionary, t: Dictionary, dt: float) -> void:
	m["search"] += dt
	var every := search_s(t)
	while m["search"] >= every:
		m["search"] -= every
		m["searches"] += 1
		if rng.randf() < Data.NOTES_SEARCH:
			m["notes"] = int(m.get("notes", 0)) + rng.randi_range(1, 2)
		if rng.randf() < Data.SCRAP_SEARCH:
			m["scrap"] = int(m.get("scrap", 0)) + rng.randi_range(Data.SCRAP_HANDFUL[0], Data.SCRAP_HANDFUL[1])     # a handful of scrap (34)
		# every find this search is one of the share still there (29): past thin_after, each is a roll
		var thin := thinning(m, t)
		var finds: int = 1 + (1 if (has_node("scavenger") or has_node("quiet_hands")) else 0) + int(Data.KENNEL_LEVELS[kennel_level]["finds"]) + (1 if has_rule("postman") else 0)
		if atlas_rank("second_look") >= 2 or (atlas_rank("second_look") == 1 and int(m["searches"]) % 2 == 0):
			finds += 1                        # Second look: one more every other search, then every search
		# quantity reaches searches: +25% is a fourth find one search in four, carried as a fraction (27)
		m["extra"] = float(m.get("extra", 0.0)) + maxf(0.0, loot_bonus())
		while m["extra"] >= 1.0:
			m["extra"] -= 1.0
			finds += 1
		for k in range(finds):
			if thin >= 1.0 or rng.randf() < thin:
				_find(m, t)


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
				ending = "burned"
				log_event(Words.DEEDS["burned"])
			else:
				var bits: int = scrap_of(it)
				mission["scrap"] = int(mission.get("scrap", 0)) + bits     # ditched for scrap (34): what comes home of it
				log_event("Ditched: %s%s" % [it["base"].to_lower(), (", %d scrap" % bits) if bits > 0 else ""])
			return true
	return false


func ditch_commons() -> int:
	if mission == null:
		return 0
	var n := 0
	for it in mission["found"].duplicate():
		if it["rarity"] == 0 and not Items.is_deeds(it) and ditch(it["id"]):
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


func stop_auto() -> void:
	if auto_tier >= 0:
		auto_tier = -1
		log_event("Auto-run stopped; this run goes on")


func _extract() -> void:
	if mission != null and mission.get("dry", false):
		return
	var m: Dictionary = mission
	var t := tier(m["tier"])
	if m.get("ghost_pending", false) and pack_used(m) >= capacity():
		m["ghost_pending"] = false
		_clear(m, m["t"])                     # Ghost: a full pack brought home is the clear (the site as deployed to, its depth with it)
		log_event("Ghost: the pack full, and %s counts as cleared" % t["name"].to_lower())
	m["cash"] += _affix_sum("cash_per_cell") * pack_used(m) * inflation()
	if has_node("cap_the_lot") and pack_used(m) >= capacity():
		m["cash"] *= 2.0                      # The lot: a full pack pays double
	_earn(float(m["cash"]))
	takings = _takings_run if takings <= 0.0 else lerp(takings, _takings_run, 0.25)     # a run's takings: this run's cash and the fence's money since the last
	_takings_run = 0.0
	scrap += int(m.get("scrap", 0))       # the run's scrap comes home (34)
	var run_notes: int = int(m.get("notes", 0))
	if has_rule("lorrys_load"):
		run_notes += maxi(0, capacity() - pack_used(m)) * int(m["t"]["depth"])     # every empty cell is notes
	if has_rule("managers_pen"):
		run_notes *= 2
	if has_rule("drivers_log"):
		run_notes *= 2
	notes += run_notes
	var stashed := 0
	for it in m["found"]:
		if Items.is_deeds(it):
			stash.append(it)                 # whatever the room: the deeds come home
			stashed += 1
			if ending == "":
				ending = "held"
				log_event(Words.DEEDS["held"])
		elif stash_put(it):
			stashed += 1
	var outcome := "Back"
	if not m["cleared"]:
		outcome = "Cut and run"
	elif m["patrols"] > 0:
		outcome = "Back, chased"
	last_report = {
		"outcome": outcome, "tier": m["tier"], "kills": m["kills"], "of": int(t["pool"]), "loot": stashed,
		"left": m["left"] + (m["found"].size() - stashed), "cash": m["cash"], "xp": m["xp"],
		"hp_lost": m["hp_start"] - hp, "time": m["elapsed"], "searches": m["searches"], "patrols": m["patrols"], "wounded": bool(m.get("wounded", false)), "scrap": int(m.get("scrap", 0)),
	}
	log_event("%s from %s: %d kills, %d items, %s" % [outcome, t["name"].to_lower(), m["kills"], stashed,
			_cash_words(m["cash"])])
	mission = null
	_idle_tidy()
	_say_next()
	restock()


## KIA: the loadout and what was found are gone; the stash and cash stay. A
## fresh operator takes over at level 1. Auto-run stops.
func _kia() -> void:
	var m: Dictionary = mission
	if m.get("dry", false):
		m["dead"] = true                     # a dry run: the answer, nothing lost
		return
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
	past.append({"class": cls, "level": level(), "runs": runner_runs, "end": "died in %s" % t["name"].to_lower(), "site": _deepest_held()[0], "depth": _deepest_held()[1]})
	runner_runs = 0
	if m.get("insured", false):
		# the fence held the paper: what was worn and carried comes back to the stash, whatever the room
		last_report["lost_value"] = 0
		for s in Data.SLOTS:
			if equipped[s] != null:
				stash.append(equipped[s])
		for it in rig:
			stash.append(it)
		log_event("Dead in %s. %s" % [t["name"].to_lower(), Words.FENCE["paid_out"]])
	else:
		log_event("Dead in %s. Kit lost (%s). %s" % [t["name"].to_lower(), _cash_words(lost), Words.RECYCLE["listed"]])
		for s in Data.SLOTS:
			if equipped[s] != null:
				_lose(equipped[s], "the last %s" % cls.to_lower(), "runner")
		if dogs_share:
			for it in rig:
				stash.append(it)                 # the dog's share: the rig comes home
			log_event("The dog came home with the rig: %d pouch%s" % [rig.size(), "" if rig.size() == 1 else "es"])
	if Data.KENNEL_LEVELS[kennel_level].get("carries", false) and not m["found"].is_empty():
		# the kennel's top level (31): the dog carries the best thing in the pack home
		var best: Dictionary = m["found"][0]
		for it in m["found"]:
			if sell_price(it) > sell_price(best):
				best = it
		stash.append(best)
		last_report["carried"] = Items.full_name(best)
		last_report["left"] = int(last_report["left"]) - 1
		log_event("The dog came home with %s" % Items.full_name(best).to_lower())
		if Items.is_deeds(best) and ending == "":
			ending = "held"                  # the deeds, carried home: held all the same
			log_event(Words.DEEDS["held"])
	for s in Data.SLOTS:
		equipped[s] = null
	rig = []
	operators_lost += 1
	xp = 0.0
	wound = ""                           # theirs, gone with them
	hp = Data.BASE_HP
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
	for tr in Data.TRAITS:
		pool.append(tr["name"])
	pool.shuffle()
	candidates = [pool[0], pool[1]]
	if promised != "":
		candidates[1] = promised
		promised = ""
	runner_trait = candidates[0]
	log_event(Words.PASTS[cls]["arrives"] if Words.PASTS.has(cls) else "A new runner turns up at the yard with their own kit.")
	# the dead runner's past goes with them: their class and its trees come
	# back as points for the next to spend from the start, with a past of their
	# own to pick. The yard's tree and the elements' are the yard's and stay.
	_refund_runner_trees()


## The runner's own trees - the class's, the second past's, and the elements'
## (a fire build is the runner's, not the yard's) - back to points; the class
## unpicked. Only the yard's tree stays taken.
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
	return "£%d" % int(round(x))


# ------------------------------------------------------------------ the armoury

## The best item of a slot in the stash, by its score, or {}.
func best_in_stash(slot: String) -> Dictionary:
	var best := {}
	var bs := -1.0
	for it in stash:
		if it["slot"] == slot and Items.score(it) > bs:
			best = it
			bs = Items.score(it)
	return best


func equip_best(slot: String) -> bool:
	if mission != null:
		return false
	var best := best_in_stash(slot)
	if best.is_empty():
		return false
	if equipped[slot] != null and Items.score(equipped[slot]) >= Items.score(best):
		return false
	_remove(best)
	if equipped[slot] != null:
		stash.append(equipped[slot])
	equipped[slot] = best
	return true


## A particular stash item, by id, into its slot; what was fitted goes to the stash.
func equip_item(id: int) -> bool:
	if not can_equip_item(id):
		return false
	for it in stash:
		if it["id"] == id:
			var slot: String = it["slot"]
			_remove(it)
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
			if not equipped.has(slot):
				return false
			if equipped[slot] == null:
				return true
			return stash_used() - Items.size(it) + Items.size(equipped[slot]) <= stash_cap()
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
			if not equipped.has(slot) or Items.is_deeds(it):
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
			equipped[slot] = it
			_read(it)
			_dry_memo.clear()
			if hp > max_hp():
				hp = max_hp()
			return true
	return false


## A med or rounds found out there, into the rig while the run's on.
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


## Whether a stack of rounds would top up the rig's own stack entirely, with no pouch.
func rig_stack_room(it: Dictionary) -> bool:
	var left: int = Items.stack_size(it)
	for r in rig:
		if Items.same_stack(r, it):
			left -= Items.stack_cap(r) - Items.stack_size(r)
	return left <= 0


func _take_from(src: Array, id: int) -> bool:
	for it in src:
		if it["id"] == id and Items.rig_item(it):
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
	if leaving.is_empty() or not (stash_room(1) or _stack_room(leaving)):
		return false
	for k in range(rig.size()):
		if rig[k]["id"] == id:
			var it: Dictionary = rig[k]
			rig.remove_at(k)
			stash_put(it)
			return true
	return false


func unequip(slot: String) -> bool:
	if mission != null or equipped[slot] == null or not stash_room(Items.size(equipped[slot])):
		return false
	stash.append(equipped[slot])
	equipped[slot] = null
	return true


# ------------------------------------------------------------------ the black market

## The best gear tier any open site drops: what the fence and the clinic stock.
func gear_tier() -> int:
	var t := 1
	for i in range(Data.TIERS.size()):
		if tier_open(i):
			t = maxi(t, int(Data.TIERS[i]["loot_tier"]))
	return t


func restock() -> void:
	reroll_intel()
	_restock_clinic()
	_restock_gamble()
	market = []
	var t := gear_tier()
	for k in range(Data.MARKET_LEVELS[market_level]["stock"]):
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
		market.append(it)


## The fence's gamble: GAMBLE_SHOWN kinds of the eleven, rotated with every restock.
func _restock_gamble() -> void:
	var kinds: Array = []
	for k in Data.GAMBLE_KINDS:
		if _gamble_has_base(k):
			kinds.append(k["kind"])        # only a kind the fence can source at the tier opened
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


## The top open tier: what the fence rolls a gamble at, and what its price is read off.
func top_tier() -> int:
	var top := 0
	for i in range(Data.TIERS.size()):
		if tier_open(i):
			top = i
	return top


## The price of a gamble: GAMBLE_RUNS of what a run on the top open tier pays, never under the floor.
func gamble_price(kind: String) -> int:
	if gamble_kind(kind).is_empty():
		return -1
	return int(round(maxf(float(_inf(Data.GAMBLE_FLOOR)), a_runs_takings() * Data.GAMBLE_RUNS)))


func can_gamble(kind: String) -> bool:
	return mission == null and kind in gamble and cash >= gamble_price(kind) and stash_room(1)     # room for one cell at least: the roll's own size is checked when it lands


## Pay, and the thing turns up in the stash: a random one of the kind, rolled at the top tier opened
## with the fence's quality, never Common; or, one time in fifty, a unique of the kind. The kind leaves
## the offer; the next restock brings five more. `unique_roll` is the tests' dice.
func gamble_buy(kind: String, unique_roll := -1.0) -> Dictionary:
	if not can_gamble(kind):
		return {}
	var k := gamble_kind(kind)
	var it := roll_gamble(k, unique_roll)
	if not (stash_room(Items.size(it)) or _stack_room(it)):
		return {}
	cash -= gamble_price(kind)
	gamble.erase(kind)
	stash_put(it)
	last_craft = {"id": it["id"], "kind": "gamble", "words": "The fence's word: %s" % Items.full_name(it).to_lower()}
	log_event("A word in the right ear: %s" % Items.full_name(it).to_lower())
	return it


## The roll behind a gamble, for the kind: a unique of the kind on GAMBLE_UNIQUE, else a drop of the
## slot at the top open tier's loot tier with the fence's quality on it, never Common, of the type
## when the kind has one.
func roll_gamble(k: Dictionary, unique_roll := -1.0) -> Dictionary:
	var x: float = unique_roll if unique_roll >= 0.0 else rng.randf()
	if x < Data.GAMBLE_UNIQUE:
		var fits: Array = []
		for u in Data.UNIQUES:
			if u.has("site") or u.get("boss", false):
				continue                                  # the chase is the ladders', never the fence's (endgame part 3)
			if u["slot"] == k["slot"] and (k["type"] == "" or Items.base_named(k["slot"], u["base"]).get("type", "") == k["type"]):
				fits.append(u)
		if not fits.is_empty():
			return Items.roll_unique(fits[rng.randi_range(0, fits.size() - 1)], rng)
	var t := top_tier()
	var it: Dictionary = {}
	for tries in range(40):
		it = Items.roll(k["slot"], gear_tier(), rng, Data.GAMBLE_QUALITY, true, false, "", k["type"], 0.33, maxi(0, best_depth[t] - 1))
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
	return _inf(it["value"] * Data.MARKET_MARKUP * (2.0 if has_node("buyers_market") else 1.0))


func buy(i: int) -> bool:
	if i >= market.size() or not (stash_room(Items.size(market[i])) or _stack_room(market[i])) or cash < price(market[i]):
		return false
	cash -= price(market[i])
	stash_put(market[i])
	market.remove_at(i)
	return true


func sell(it: Dictionary) -> bool:
	if not _remove(it):
		return false
	_earn(float(sell_price(it)))
	if it.has("unique"):
		_lose(it, "", "fence")                # he said someone would want it; later someone has it
	if Items.is_deeds(it):
		ending = "sold"
		log_event(Words.DEEDS["sold"])
	return true


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
	if not stash_room(Items.size(it)):
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
		if it["rarity"] == r and not Items.is_deeds(it):     # the deeds are sold on purpose or not at all
			sell(it)
			n += 1
	return n


## The junk run.
func sell_commons() -> int:
	return sell_rarity(0)


## The idle junk run: common gear only - never rounds, meds, bottles, papers, uniques or set pieces.
func sell_junk() -> int:
	var n := 0
	var got := 0.0
	for it in stash.duplicate():
		if int(it["rarity"]) == 0 and not (Items.rig_item(it) or Items.is_paper(it) or Items.is_socketable(it) or it.has("unique") or it.has("set")):
			got += sell_price(it)
			sell(it)
			n += 1
	if n > 0:
		log_event("The fence took the junk: %d thing%s, %s." % [n, "" if n == 1 else "s", _cash_words(got)])
	return n


## Idle: what the toggles do when a run comes home.
func _idle_tidy() -> void:
	if auto_sell:
		sell_junk()
	if auto_equip:
		var changed := []
		for s in Data.SLOTS:
			var was = equipped[s]
			if equip_best(s):
				changed.append(Items.full_name(equipped[s]))
		if not changed.is_empty():
			log_event("Put on: %s." % ", ".join(changed))


## The stash's unequipped items, dearest first, for the market's sell cards.
func stash_by_value() -> Array:
	var out := stash.duplicate()
	out.sort_custom(func(a, b): return a["value"] > b["value"])
	return out


# ------------------------------------------------------------------ the medic tent

## The Medic Tent's shelf: every common med up to the next tier, at its markup.
## The clinic's shelf: MEDIC_LEVELS[level]["stock"] meds, rolled from the
## bases it carries, cheaper ones more often. Finite until the next run.
func _restock_clinic() -> void:
	clinic = []
	var bases := med_stock()
	for k in range(int(Data.MEDIC_LEVELS[medic_level]["stock"])):
		var b: Dictionary = bases[mini(bases.size() - 1, int(absf(rng.randfn(0.0, 1.2))))]
		var it := Items.roll(Data.MEDICAL, int(b["tier"]), rng)
		it["base"] = b["name"]
		it["rarity"] = 0
		it["affixes"] = []
		it["tier"] = b["tier"]
		it["value"] = b["value"]
		clinic.append(it)


func clinic_price(it: Dictionary) -> int:
	return int(round(it["value"] * Data.MED_PRICE))


func buy_clinic(id: int) -> bool:
	for k in range(clinic.size()):
		if clinic[k]["id"] == id:
			var it: Dictionary = clinic[k]
			if cash < clinic_price(it) or not stash_room(1):
				return false
			cash -= clinic_price(it)
			clinic.remove_at(k)
			stash.append(it)
			return true
	return false


## Buy off the fence's shelf by the item's id.
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
	return _inf(base["value"] * Data.MED_PRICE)


func buy_med(name: String) -> bool:
	for b in med_stock():
		if b["name"] == name:
			if cash < med_price(b) or not stash_room(1):
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


# ------------------------------------------------------------------ the yard's upgrades

func away_cap_s() -> float:
	return Data.GENERATOR_LEVELS[generator_level]["hours"] * 3600.0


func generator_cost() -> int:
	return 0 if generator_level >= Data.GENERATOR_LEVELS.size() - 1 else _inf(Data.GENERATOR_LEVELS[generator_level + 1]["cost"])


func can_upgrade_generator() -> bool:
	return generator_level < Data.GENERATOR_LEVELS.size() - 1 and cash >= generator_cost()


func upgrade_generator() -> bool:
	if not can_upgrade_generator():
		return false
	cash -= generator_cost()
	generator_level += 1
	log_event("Generator: %s" % Data.GENERATOR_LEVELS[generator_level]["words"].to_lower())
	return true


func lookout_cost() -> int:
	return 0 if lookout_level >= Data.LOOKOUT_LEVELS.size() - 1 else _inf(Data.LOOKOUT_LEVELS[lookout_level + 1]["cost"])


func can_upgrade_lookout() -> bool:
	return lookout_level < Data.LOOKOUT_LEVELS.size() - 1 and cash >= lookout_cost()


func upgrade_lookout() -> bool:
	if not can_upgrade_lookout():
		return false
	cash -= lookout_cost()
	lookout_level += 1
	_surv_cache = {}
	log_event("Lookout: %s" % Data.LOOKOUT_LEVELS[lookout_level]["words"].to_lower())
	return true


func kennel_cost() -> int:
	return 0 if kennel_level >= Data.KENNEL_LEVELS.size() - 1 else _inf(Data.KENNEL_LEVELS[kennel_level + 1]["cost"])


func can_upgrade_kennel() -> bool:
	return kennel_level < Data.KENNEL_LEVELS.size() - 1 and cash >= kennel_cost()


func upgrade_kennel() -> bool:
	if not can_upgrade_kennel():
		return false
	cash -= kennel_cost()
	kennel_level += 1
	log_event("Kennel: %s" % Data.KENNEL_LEVELS[kennel_level]["words"].to_lower())
	return true


## The HP back, and the wound seen to: WOUND_CASH a level, the clinic's discount on both.
## The clinic's two jobs, priced apart (Matt, 7 Oct: "heal my HP and treat the wound separately"): the HP back
## at TREAT_CASH_PER_HP a point, the wound at WOUND_CASH a level; the clinic's discount on both.
func _treat_rate() -> float:
	return inflation() * maxf(0.2, 1.0 - tree_sum("treat_pct") / 100.0)


func heal_cost() -> int:
	return int(ceil(maxf(0.0, max_hp() - hp) * Data.TREAT_CASH_PER_HP * _treat_rate()))


func wound_cost() -> int:
	return int(ceil(Data.WOUND_CASH * level() * _treat_rate())) if wound != "" else 0


## Both at once: what the bot pays, and the old button.
func treat_cost() -> int:
	return heal_cost() + wound_cost()


func needs_treating() -> bool:
	return hp < max_hp() or wound != ""


func can_heal() -> bool:
	return mission == null and hp < max_hp() - 0.5 and cash >= heal_cost()


func can_treat_wound() -> bool:
	return mission == null and wound != "" and cash >= wound_cost()


func heal() -> bool:
	if not can_heal():
		return false
	cash -= heal_cost()
	hp = max_hp()
	return true


func treat_wound() -> bool:
	if not can_treat_wound():
		return false
	cash -= wound_cost()
	log_event("The wound seen to: %s back" % ("max HP" if wound == "hp" else wound))
	wound = ""
	_dry_memo.clear()
	return true


func treat() -> bool:
	if mission != null or not needs_treating() or cash < treat_cost():
		return false
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
func log_event(text: String) -> void:
	events.append([Time.get_unix_time_from_system(), text])
	events_total += 1
	while events.size() > 20:
		events.pop_front()


func to_dict() -> Dictionary:
	return _state().duplicate(true)      # a copy: the live items aren't shared with the save


func _state() -> Dictionary:
	return {
		"cash": cash, "xp": xp, "hp": hp, "equipped": equipped, "rig": rig, "stash": stash, "market": market, "gamble": gamble,
		"mission": mission, "last_report": last_report, "operators_lost": operators_lost,
		"best_tier": best_tier, "depot_cleared": depot_cleared, "elapsed": elapsed, "events": events,
		"next_id": Items._next_id, "auto_tier": auto_tier, "auto_equip": auto_equip, "auto_sell": auto_sell, "tree": tree, "training_points": training_points,
		"intel": intel, "depth": depth, "best_depth": best_depth, "workshop": workshop, "class": cls, "stash_level": stash_level,
		"medic_level": medic_level, "market_level": market_level, "comms_level": comms_level, "pinned": pinned,
		"hardcore": hardcore, "camp_lost": camp_lost, "clinic": clinic, "wound": wound,
		"generator_level": generator_level, "lookout_level": lookout_level, "kennel_level": kennel_level,
		"past": past, "loose_kit": loose_kit, "book": book.duplicate(), "shelf": shelf.duplicate(), "worn": worn.duplicate(), "worn_depth": worn_depth.duplicate(), "weather": weather.duplicate(), "weather_at": weather_at, "last_next": last_next, "events_total": events_total, "runner_runs": runner_runs, "seen": seen, "deeds_found": deeds_found, "ending": ending, "lorry_done": lorry_done, "lorries": lorries, "best_dig": best_dig.duplicate(), "paragon_banked": paragon_banked,
		"bosses_beaten": bosses_beaten, "notes": notes, "scrap": scrap, "takings": takings, "retired": retired.duplicate(), "class2": cls2, "atlas": atlas, "atlas_points": atlas_points, "boss_paid": boss_paid,
		"contracts": contracts, "mate": mate, "runs_total": runs_total, "wounded_total": wounded_total, "yard_moves": yard_moves, "trades": trades.duplicate(), "insure_next": insure_next,
		"trait": runner_trait, "candidates": candidates, "promised": promised,
	}


func load_dict(d: Dictionary) -> void:
	d = d.duplicate(true)                # the save's items stay the save's; the live ones are copies
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
	auto_sell = bool(d.get("auto_sell", false))
	tree = d.get("tree", [])
	workshop = int(d.get("workshop", 0))
	cls = d.get("class", "")
	# saves from before the language pass carry the old names
	const OLD_WORDS := {"Recon": "Poacher", "Enforcer": "Doorman", "Medic": "Paramedic", "Saboteur": "Scrapper", "Ghost": "Drifter"}
	cls = OLD_WORDS.get(cls, cls)
	cls2 = str(d.get("class2", ""))
	runner_trait = str(d.get("trait", ""))
	candidates = d.get("candidates", [])
	promised = str(d.get("promised", ""))
	# trees from before the class trees: nodes that aren't in the trees on show are refunded
	var kept := []
	for id in tree:
		if _on_show(str(id).get_slice("/", 0)) and not node(str(id)).is_empty():
			kept.append(id)
	tree = kept
	stash_level = int(d.get("stash_level", 0))
	medic_level = int(d.get("medic_level", 0))
	market_level = int(d.get("market_level", 0))
	comms_level = int(d.get("comms_level", 0))
	hardcore = bool(d.get("hardcore", false))
	wound = str(d.get("wound", "")) if str(d.get("wound", "")) in Data.WOUND_STATS else ""
	generator_level = int(d.get("generator_level", 0))
	lookout_level = int(d.get("lookout_level", 0))
	kennel_level = int(d.get("kennel_level", 0))
	camp_lost = bool(d.get("camp_lost", false))
	var pn: Array = d.get("pinned", [])
	for i in range(mini(pn.size(), Data.TIERS.size())):
		pinned[i] = bool(pn[i])
	if d.has("depth"):
		for i in range(Data.TIERS.size()):
			if i < d["depth"].size():
				depth[i] = int(d["depth"][i])
				best_depth[i] = int(d["best_depth"][i])
				intel[i] = d["intel"][i]
		if d["depth"].size() < Data.TIERS.size():
			reroll_intel()
	else:
		reroll_intel()
	training_points = int(d.get("training_points", maxi(0, level() - 1)))
	depot_cleared = bool(d.get("depot_cleared", false))
	past = d.get("past", [])
	loose_kit = Array(d.get("loose_kit", []))
	book = Array(d.get("book", []))
	shelf = Array(d.get("shelf", []))
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
	seen = d.get("seen", {})
	deeds_found = bool(d.get("deeds_found", false))
	ending = str(d.get("ending", ""))
	lorry_done = bool(d.get("lorry_done", false))
	lorries = int(d.get("lorries", 0))
	paragon_banked = int(d.get("paragon_banked", 0))
	best_dig = d.get("best_dig", {}).duplicate() if d.get("best_dig", {}) is Dictionary else {}
	notes = int(d.get("notes", 0))
	scrap = int(d.get("scrap", 0))
	takings = float(d.get("takings", 0.0))
	retired = []
	for r in d.get("retired", []):
		retired.append(str(r))
	atlas = {}
	for k in d.get("atlas", {}):
		atlas[str(k)] = int(d["atlas"][k])
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
		contracts.append({"slot": str(c["slot"]), "rarity": int(c["rarity"]), "count": int(c["count"]), "pay": str(c["pay"]), "amount": int(c["amount"]), "unique": str(c.get("unique", "")), "what": str(c.get("what", ""))})
	while contracts.size() < Data.CONTRACTS_OPEN:
		contracts.append(roll_contract())
	mate = {}
	if d.has("mate") and not d["mate"].is_empty():
		mate = {"unique": str(d["mate"]["unique"]), "notes": int(d["mate"]["notes"])}
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
		bosses_beaten[0] = true
	elapsed = float(d.get("elapsed", 0.0))
	events = d.get("events", [])
	Items._next_id = maxi(Items._next_id, int(d.get("next_id", 1)))
	rng.randomize()
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
	for it in _all_items():
		it["id"] = int(it["id"])
		it["rarity"] = int(it["rarity"])
		it["tier"] = int(it["tier"])
		it["value"] = int(it["value"])
		if it.has("rounds"):
			it["rounds"] = int(it["rounds"])
	if market.is_empty():
		restock()
	if not d.has("gamble"):
		_restock_gamble()                 # a save from before the fence's gamble: the offer rolled now, with the tiers loaded (an empty offer is a bought-out one)


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
