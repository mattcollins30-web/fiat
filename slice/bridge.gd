extends RefCounted
## The ARPG slice's bridge to the game's maths (build 72, builder G). Static functions only: W's world and H's HUD call
## them with the ctx that runner_ctx built. The ctx carries the slice's OWN Sim - a copy of the camp's runner (or the
## level-14 Poacher fixture) - and a mission dictionary on it that stands for the slice's fight, so the sim's own reads
## (the 0.15 stats, the helmet and armour by depth, the streak, the pinning rule, jams, a med's heal, the find roll)
## answer as they would on a run. The camp's sim is never written; nothing the slice does goes back.
##
## The fight in the sim is a rate over ticks; here it is rounds. One round's worth is the gun's share of the damage a
## second over its rate of fire - the same figure the sim's tick spreads over rof x pace x dt shots - and each round
## rolls the sim's chances (headshot, leg, arm, jam) once. Figures without a sim counterpart are in SliceTuning's G block.

const Sim := preload("res://scripts/sim/sim.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const T := preload("res://slice/tuning.gd")

const SITE_TIER := 5                 # the Retail Park: the Estate's car park
## The site's level follows the runner (merge, 9 Nov): his level less SliceTuning.SITE_LEVEL_UNDER, at least 1 - the
## level-14 fixture's car park is level 12, as the brief had it.
static func site_level(s) -> int:
	return maxi(1, int(s.level()) - T.SITE_LEVEL_UNDER)
const FIXTURE_LEVEL := 14            # no runner at camp: a level-14 Poacher
const FIXTURE_GUNS := ["Regimental rifle", "Officer's revolver"]     # a T5 rifle and a T6 revolver: worn at level 14
const FIXTURE_SKILLS := ["clean_shot", "collared", "net_every_hole"]
const FIXTURE_ELEMENT := "poison"     # the Poacher's: Poacher's bait, rifles' poison (Data.AFFINITY)
## The Poacher's skills the slice plays, and which are aimed (they act on the men by the aim point).
const AIMED := {"flush_them_out": true, "one_for_the_pot": true, "collared": true, "gin_trap": true, "net_every_hole": true}
const SLOT_NAMES := ["Primary", "Secondary"]


# ------------------------------------------------------------------ the ctx

## The runner and the site for the slice. `main`: the title's main node (anything with a `sim`), or null.
static func runner_ctx(main, seed_v := 72) -> Dictionary:
	var s := Sim.new()
	var fixture := true
	var camp = main.get("sim") if main != null and main is Object else null
	if camp != null and str(camp.cls) != "":
		s.load_dict(camp.to_dict())
		s.mission = null                      # a camp with a run out: the slice is its own fight
		fixture = false
	else:
		_fixture(s, seed_v)
	s.rng.seed = seed_v
	s.fight_rng.seed = seed_v + 1
	var stand_in: String = _stand_in(s, seed_v)
	_arm(s)
	var t := site_figures(s)
	var m := _mission(s, t)
	s.mission = m
	s.hp = s.max_hp()
	var ctx := {"sim": s, "fixture": fixture, "seed": seed_v, "site": _site_words(s, t), "t": t,
		"class_name": str(s.cls), "level": s.level(), "hp_max": int(round(s.max_hp())), "guard_max": int(round(s.guard_cap())),
		"energy_max": s.max_energy(), "pace_pct": (s.pace() - 1.0) * 100.0, "portrait": _portrait(str(s.cls)),
		"guns": [], "meds": [], "skills": [], "last_legs_hp": last_legs_hp_of(s), "last_legs_s": last_legs_s_of(s),
		"events": [], "buffs": {}, "using": {}, "traps": [], "gang_i": 0, "kills": 0, "world": null}
	for slot in SLOT_NAMES:
		var g = s.equipped[slot]
		if g == null or float(Items.base_of(g).get("rof", 0.0)) <= 0.0:
			continue
		ctx["guns"].append(_gun_entry(s, slot, g))
	if stand_in != "":
		for e in ctx["guns"]:
			if str(e["slot"]) == "Primary":
				e["stand_in"] = true
	ctx["meds"] = _meds(s)
	ctx["skills"] = _skills(s, fixture)
	ctx["boxes"] = boxes_for(s, ctx["guns"])
	ctx["contact"] = int(s.contact(t))          # the sim's: how many of a gang are on you at once
	return ctx


## A primary that can't fire in the slice (no rate, no magazine: a hammer, a bow on no rounds): the fixture's rifle in its
## place, on the slice's own Sim, so its reads are the stand-in's. Returns the stand-in's name, "" when none was needed.
static func _stand_in(s, seed_v: int) -> String:
	var g = s.equipped["Primary"]
	if g != null and float(Items.base_of(g).get("rof", 0.0)) > 0.0 and Items.mag_size(g) > 0:
		return ""
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var b: Dictionary = Items.base_named("Primary", FIXTURE_GUNS[0])
	s.equipped["Primary"] = Items.roll_on("Primary", b, r, 1.0, true, false, 0, FIXTURE_LEVEL)
	s._stats_dirty()
	return FIXTURE_GUNS[0]


## The rounds in the pack's boxes for each gun's type (the sim's refill: a magazine filled by hand from a box): the
## camp's boxes of that type, read; none, the slice's own box of SliceTuning.G_BOX_ROUNDS. {ammo type: rounds}.
static func boxes_for(s, guns: Array) -> Dictionary:
	var out := {}
	for e in guns:
		var ty: String = str(e.get("ammo", ""))
		if ty == "" or out.has(ty):
			continue
		var n := 0
		for it in s._rounds_held():
			if Items.is_ammo(it) and str(Items.base_of(it)["type"]) == ty:
				n += int(it.get("rounds", 0))
		out[ty] = n if n > 0 else T.G_BOX_ROUNDS
	return out


## Rounds found (a crate's, a man's drop): boxes of a gun's type go into the pack's count. Returns the rounds taken in.
static func take_rounds(ctx: Dictionary, items: Array) -> int:
	var got := 0
	for it in items:
		if it is Dictionary and it.has("base") and Items.is_ammo(it):
			var ty: String = str(Items.base_of(it)["type"])
			if ctx.get("boxes", {}).has(ty):
				ctx["boxes"][ty] = int(ctx["boxes"][ty]) + int(it.get("rounds", 0))
				got += int(it.get("rounds", 0))
	return got


## A magazine filled by hand from the pack's box: the sim's REFILL_MULT times the gun's reload.
static func refill_s(gun: Dictionary) -> float:
	return float(gun.get("reload_s", 2.0)) * Data.REFILL_MULT


## A level-14 Poacher in worn kit of his level, rolled with affixes on a fixed seed: no camp, no web past the class's start.
static func _fixture(s, seed_v: int) -> void:
	s.rng.seed = seed_v
	s.start()
	s.set_class("Poacher")
	s.xp = Data.xp_for_level(FIXTURE_LEVEL)
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	for k in range(SLOT_NAMES.size()):
		var b: Dictionary = Items.base_named(SLOT_NAMES[k], FIXTURE_GUNS[k])
		if not b.is_empty():
			s.equipped[SLOT_NAMES[k]] = Items.roll_on(SLOT_NAMES[k], b, r, 1.0, true, false, 0, FIXTURE_LEVEL)
	for slot in ["Helmet", "Armour", "Gloves", "Rig"]:
		var it: Dictionary = Items.roll(slot, Sim.loot_tier_at(FIXTURE_LEVEL), r, 1.0, true, false, "", "", 0.33, 0, FIXTURE_LEVEL)
		if not it.is_empty():
			s.equipped[slot] = it
	s.rig = s.rig.filter(func(x): return not Items.is_medical(x))
	for nm in ["First aid kit", "First aid kit", "Bandage", "Bandage"]:
		s.rig.append(s._plain(Data.MEDICAL, nm))
	for k in range(3):
		s.skill_slots[k] = FIXTURE_SKILLS[k]
	s._stats_dirty()
	s.training_points = (FIXTURE_LEVEL - 1) * Data.POINTS_A_LEVEL     # the points a level-14 runner has had
	var bot = load("res://tests/bot.gd").new()     # the web as the balance bot trains a level-14 Poacher: his poison build
	bot.element = FIXTURE_ELEMENT
	bot.cls = "Poacher"
	bot._train_tree(s)
	s._stats_dirty()


## Each worn gun fed: a loaded magazine of its type in the slice's rig when it has none, so the sim reads it live (the
## slice keeps its own rounds; the sim only needs to know the gun fires).
static func _arm(s) -> void:
	for slot in SLOT_NAMES:
		var g = s.equipped[slot]
		if g == null or Items.mag_size(g) <= 0:
			continue
		if s.mags_for(g).any(func(x): return int(x.get("rounds", 0)) > 0):
			continue
		var mag_base := "Rifle magazine" if Items.ammo_type(g) == "rifle" else ("%s magazine" % Items.ammo_type(g).capitalize())
		if Items.base_named(Data.MAGAZINE, mag_base).is_empty():
			continue
		var mag: Dictionary = s._plain(Data.MAGAZINE, mag_base)
		mag["rounds"] = Items.mag_cap(mag, g)
		mag["ammo"] = "%s rounds" % Items.ammo_type(g).capitalize()
		s.rig.append(mag)
	s._stats_dirty()


## The car park's figures: the Retail Park as a signal at level 12 plays it (its depth's curve), the Estate's crew's damage
## types and resists at that depth.
static func site_figures(s) -> Dictionary:
	var lv: int = site_level(s)
	var d: int = Sim.tier_depth(lv)
	var t: Dictionary = s.depth_figures(SITE_TIER, d, lv, true, true)
	var crew: Array = s._crew_types(int(Data.TIERS[SITE_TIER]["zone"]), d, [])
	t["types"] = crew[0]
	t["res"] = crew[1]
	t["level"] = lv
	return t


## The slice's fight as a mission on the slice's sim: what the reads it calls look at, nothing a run's end would.
static func _mission(s, t: Dictionary) -> Dictionary:
	var m := {"tier": SITE_TIER, "t": t, "remaining": 0, "target_hp": 0.0, "kills": 0, "found": [], "insured": false,
		"clock": 9999.0, "clock_max": 9999.0, "left": 0, "cash": 0.0, "xp": 0.0, "elapsed": 0.0, "hp_start": s.hp,
		"cleared": false, "search": 0.0, "searches": 0, "patrol_timer": 0.0, "patrols": 0, "last_incoming": 0.0,
		"using": null, "meds_used": 0, "fresh": true, "swapped": 0, "chill_t": 0.0, "fire_x": {}, "my_dots": {},
		"dry": false, "slice": true, "guard": 0.0, "f66_streak": 0, "sk": {"energy": s.max_energy(), "cd": [0.0, 0.0, 0.0],
		"fx": {}, "seq": 0, "press": -1, "share": {}}}
	return m


static func _site_words(s, t: Dictionary) -> Dictionary:
	var pool: int = int(t["pool"])
	var base_n: int = maxi(1, int(ceil(float(pool) / float(T.G_GANGS))))
	var sizes: Array = []
	var cut: int = (int(Data.FX["node/trapline.heads"]) if s.has_node("trapline") or s.has_node("snare_and_wait") else 0) + (int(Data.FX["yard/flares.heads"]) if s.yard_has("flares") else 0)
	for g in range(T.G_GANGS):
		sizes.append(clampi(base_n + g - cut, 1, T.G_GANG_MAX))
	return {"name": T.G_SITE_NAME, "place": str(Data.ZONES[int(Data.TIERS[SITE_TIER]["zone"])]["name"]), "level": int(t["level"]),
		"man_hp": float(t["hp"]), "man_dps": float(t["dps"]), "types": t["types"], "res": t["res"], "gangs": T.G_GANGS,
		"gang_sizes": sizes, "first_gang_s": T.G_FIRST_GANG_S, "next_gang_s": s.patrol_s(t) * T.G_CLOCK_X,
		"hard_odds": Data.HARD66_ODDS if int(t["level"]) >= Data.HARD66_LEVEL else 0.0, "drop": float(t["drop"])}


static func _portrait(cls_v: String) -> String:
	var sl: String = Items.slug(cls_v)
	for p in ["res://art/people_new/%s.png" % sl, "res://art/people/%s.png" % sl]:
		if ResourceLoader.exists(p):
			return p
	return ""


static func _item_icon(it: Dictionary) -> String:
	var p := "res://art/items/%s.png" % Items.slug(Items.art_name(str(it.get("base", ""))))
	return p if ResourceLoader.exists(p) else ""


static func _gun_entry(s, slot: String, g: Dictionary) -> Dictionary:
	var b: Dictionary = Items.base_of(g)
	var mags: int = 0
	for it in s.mags_for(g):
		mags += 1
	return {"slot": slot, "name": str(g.get("unique", g.get("piece", g["base"]))), "base": str(g["base"]), "icon": _item_icon(g),
		"rof": float(b["rof"]) * s.pace() * s.rate_x(), "mag": maxi(1, Items.mag_size(g)) if Items.mag_size(g) > 0 else 0,
		"reload_s": s.reload_s(g) / maxf(0.01, s.pace()), "mags": maxi(T.G_SPARE_MAGS, mags - 1), "type": str(b.get("type", "")),
		"ammo": Items.ammo_type(g), "item": g, "stand_in": false}


static func _meds(s) -> Array:
	var out: Array = []
	var by: Dictionary = {}
	for it in s.rig:
		if not Items.is_medical(it) or Items.is_cure(it):
			continue
		var nm: String = str(it["base"])
		if by.has(nm):
			by[nm]["count"] += 1
			continue
		if out.size() >= T.G_MED_SLOTS:
			continue
		var e := {"name": nm, "base": nm, "icon": _item_icon(it), "heal": int(round(s.med_heal(it))), "use_s": s.use_time(it), "count": 1, "item": it}
		by[nm] = e
		out.append(e)
	return out


static func _skills(s, fixture: bool) -> Array:
	var ids: Array = []
	for k in range(3):
		var id: String = str(s.skill_slots[k]) if k < s.skill_slots.size() else ""
		ids.append(id)
	if not fixture:
		var learnt: Array = s.skills_learnt()
		for k in range(3):
			if ids[k] == "":
				for id in learnt:
					if not (id in ids):
						ids[k] = str(id)
						break
	var out: Array = []
	for id in ids:
		if id == "" or s.skill(id).is_empty():
			out.append({"id": "", "name": "", "line": "", "icon": "", "cd": 0.0, "cost": 0.0, "aimed": false})
			continue
		var sk: Dictionary = s.skill(id)
		var icon := "res://art/skills/%s.png" % id
		out.append({"id": id, "name": str(sk["name"]), "line": str(sk.get("line", "")), "icon": icon if ResourceLoader.exists(icon) else "",
			"cd": s.skill_cooldown(id), "cost": float(sk.get("cost", 0.0)) * s.skill_cost_mult(), "aimed": AIMED.has(id),
			"in_slice": _skill_in_slice(id)})
	return out


static func _skill_in_slice(id: String) -> bool:
	return id in ["clean_shot", "flush_them_out", "go_to_ground", "one_for_the_pot", "collared", "gin_trap", "decoy", "net_every_hole"]


# ------------------------------------------------------------------ small reads

static func last_legs_hp_of(s) -> int:
	return int(Data.LAST66_HOLD) if last_legs_s_of(s) > 0.0 else 0


static func last_legs_s_of(s) -> float:
	var secs: float = s.f66_stat("last_stand_s")
	if s.has_rule("lifeboat"):
		secs = maxf(secs, Data.LIFEBOAT67_S)
	return secs


static func last_legs_hp(ctx: Dictionary) -> int:
	return int(ctx.get("last_legs_hp", 0))


static func last_legs_s(ctx: Dictionary) -> float:
	return float(ctx.get("last_legs_s", 0.0))


static func streak(ctx: Dictionary) -> int:
	return int(ctx["sim"].mission.get("f66_streak", 0))


static func streak_pct(ctx: Dictionary) -> float:
	return ctx["sim"].f66_streak_bonus_pct()


static func jam_s(_ctx: Dictionary) -> float:
	return Data.JAM66_S


static func search_s(ctx: Dictionary) -> float:
	return ctx["sim"].search_s(ctx["t"]) * T.G_SEARCH_X


## The sim's events for H's pops, kept on the ctx: {kind, ...}.
static func events(ctx: Dictionary) -> Array:
	return ctx["events"]


static func pop_events(ctx: Dictionary) -> Array:
	var out: Array = ctx["events"].duplicate()
	ctx["events"].clear()
	return out


static func _event(ctx: Dictionary, kind: String, d := {}) -> void:
	d["kind"] = kind
	ctx["events"].append(d)
	while ctx["events"].size() > T.G_EVENTS_KEPT:
		ctx["events"].pop_front()


# ------------------------------------------------------------------ a man

## A gang man's state as the bridge reads it (the man node keeps it): his HP, his dots, his timers.
static func man_state(ctx: Dictionary, gang_i: int, hard_name := "", traits: Array = []) -> Dictionary:
	var t: Dictionary = ctx["t"]
	var hp_v: float = float(t["hp"]) * (Data.HARD66_HP if hard_name != "" else 1.0) * float(ctx.get("man_hp_x", T.MAN_HP_X))
	var ms := {"hp": hp_v, "hp_max": hp_v, "dps": float(t["dps"]) * T.G_MAN_DPS_X, "types": t["types"], "res": t["res"], "gang": gang_i,
		"hard": hard_name != "", "name": hard_name, "traits": traits.duplicate(), "dots": {}, "opened": false,
		"chill_t": 0.0, "shock_t": 0.0, "arm_t": 0.0, "leg_t": 0.0, "stun_t": 0.0, "exposed_t": 0.0, "supp": 0.0,
		"trap": false, "acted": {}, "since_shot": 99.0}
	return ms


## Whether a round jams (the sim's chance for the gun: its tier's, jam_pct, never with no_jam), per round fired.
static func jams(ctx: Dictionary, gun: Dictionary, rng: RandomNumberGenerator) -> bool:
	var s = ctx["sim"]
	var it: Dictionary = gun.get("item", gun)
	var slot: String = str(gun.get("slot", "Primary"))
	if not s.uses_mag(slot):
		return false
	var jp: float = s.f66_jam_pct(it)
	if jp > 0.0 and rng.randf() < jp / 100.0:
		_event(ctx, "jam", {"slot": slot, "s": Data.JAM66_S, "gun": str(gun.get("name", ""))})
		return true
	return false


## One round of the runner's `gun` (a ctx gun entry) on a man, as the real fight computes it. Writes the man's HP, dots and
## timers into `ms`; returns {damage:int, amount:float, by_type, headshot, helmet, leg, arm, killed, hard, clean}.
static func shot_damage(ctx: Dictionary, gun: Dictionary, ms: Dictionary, rng: RandomNumberGenerator, aimed_head := false) -> Dictionary:
	var s = ctx["sim"]
	var m: Dictionary = s.mission
	var t: Dictionary = ctx["t"]
	var it: Dictionary = gun.get("item", gun)
	var slot: String = str(gun.get("slot", "Primary"))
	var sv: Dictionary = s._f66_sv(m)
	var one: float = round_damage(ctx, gun)
	var per: Dictionary = s.type_dps()
	var total: float = 0.0
	for ty in per:
		total += float(per[ty])
	var swing: float = rng.randf_range(1.0 - Sim.VARIANCE, 1.0 + Sim.VARIANCE)
	var mult: float = swing
	var first: bool = bool(m.get("fresh", false))
	if first:
		mult *= 1.0 + s.first_pct_total() / 100.0                  # the first shot at each gang (Range cards and the like are camp's)
		m["fresh"] = false
	if ms.get("trap", false):
		mult *= float(Data.SKILLS["gin_trap"]["fx"]["trap_mult"])  # Gin trap: his first hit
		ms["trap"] = false
		_skill_dot_on(ctx, ms, "bleed", float(Data.SKILLS["gin_trap"]["fx"]["bleed_s"]))
	var clean := false
	if ctx["buffs"].get("clean_shot", false):
		mult *= float(Data.SKILLS["clean_shot"]["fx"]["shot_mult"])
		ctx["buffs"]["clean_shot"] = false
		clean = true
	if float(ms.get("exposed_t", 0.0)) > 0.0:
		mult *= 1.0 + float(Data.SKILLS["flush_them_out"]["fx"]["exposed"])
	if s.has_node("last_orders") and _gang_left(ctx) == 1:
		mult *= 1.4
	var shocked: bool = float(ms.get("shock_t", 0.0)) > 0.0
	var edge: String = str(Items.base_of(it).get("type", "")) if slot == "Primary" else ""
	var e_pierce: float = float(Data.EDGE["rifle"]["pierce"]) if edge == "rifle" else 0.0
	var by := {}
	var landed_total := 0.0
	var top := ["physical", 0.0]
	var res: Dictionary = ms.get("res", {})
	for ty in Data.TYPES:
		var share: float = float(per[ty]) / total if total > 0.0 else (1.0 if ty == "physical" else 0.0)
		if share <= 0.0:
			continue
		var r_ty: float = float(res.get(ty, 0.0))
		if ty == "shock" and s.has_rule("sparkys_gloves"):
			r_ty = 0.0
		if ty == "physical":
			r_ty = s.phys_resist(r_ty) * (1.0 - e_pierce)
		var landed: float = one * share * (1.0 - r_ty) * mult * ((1.0 + s.shock_amount()) if shocked else 1.0) * Sim.exploit_x(m)
		if ty == "bleed" and s.has_node("cap_bleed_out"):
			landed *= Data.FX["node/cap_bleed_out"]
		by[ty] = landed
		landed_total += landed
		if landed > float(top[1]):
			top = [ty, landed]
		if Data.DOTS.has(ty) and landed > 0.0:
			_dot_add(ctx, ms, ty, landed, landed * float(gun.get("rof", 1.0)))
		if ty == "frost" and landed > 0.0:
			ms["chill_t"] = s.status_s(1.0) * (1.0 + s.tree_sum("frost_last_pct") / 100.0)
		if ty == "shock" and landed > 0.0:
			ms["shock_t"] = s.status_s(1.0)
	if edge == "rifle" and not ms.get("opened", false):
		landed_total += float(Data.EDGE["rifle"]["opener"]) * landed_total     # a rifle's opener: a round's worth more into each new man
	ms["opened"] = true
	# (BUILD66-F) armour, the streak, Elbow grease / Covering fire / Body count
	var arm: float = man_armour(ctx, ms, sv)
	var x: float = landed_total * (1.0 - arm) * (1.0 + s.f66_streak_bonus_pct(sv) / 100.0) * s.s68_dmg_x(m, it)
	var base_hit: float = x
	var head_pct: float = clampf(Data.HEAD66_PCT + float(sv["head_pct"]) + (T.G_AIM_HEAD_PCT if aimed_head else 0.0), 0.0, 100.0)
	var heads: int = 1 if rng.randf() < head_pct / 100.0 else 0
	heads = s.u67_heads(m, slot, it, 1.0, heads)
	heads = s.s68_heads(m, 1.0, heads)
	var helmet := false
	if heads > 0:
		var cut: float = s.f66_helmet(t, sv)
		helmet = cut > 0.0
		x += base_hit * maxf(0.0, Data.HEAD66_X + float(sv["head_dmg_pct"]) / 100.0 - 1.0) * (1.0 - cut)
	var leg: bool = rng.randf() < clampf(float(sv["leg_pct"]), 0.0, 100.0) / 100.0
	if leg:
		ms["leg_t"] = T.G_LEG_SLOW_S
		ctx["leg_push"] = float(ctx.get("leg_push", 0.0)) + Data.LEG66_S     # the next gang later, as the sim's patrol timer
	var arm_shot: bool = rng.randf() < clampf(float(sv["arm_pct"]), 0.0, 100.0) / 100.0
	if arm_shot:
		ms["arm_t"] = Data.ARM66_S
	# the pinning meter on him: sustained fire fills it, only from a source (0.15.4)
	if s.f70_pins(sv):
		var rof: float = maxf(0.1, float(gun.get("rof", 1.0)))
		ms["supp"] = minf(1.0, float(ms.get("supp", 0.0)) + 1.0 / (rof * Data.SUPP66_FILL_S) * (1.0 + float(sv["suppress_pct"]) / 100.0) * (Data.RATTLE67_PIN_X if s.has_rule("football_rattle") else 1.0))
	ms["since_shot"] = 0.0
	ms["hp"] = float(ms["hp"]) - x
	var killed: bool = float(ms["hp"]) <= 0.0
	var st: Dictionary = s._f66_stats(m)
	st["shots"] = float(st["shots"]) + 1.0
	if heads > 0:
		st["headshots"] = int(st["headshots"]) + 1
		_event(ctx, "headshot", {"amount": x, "hard": bool(ms.get("hard", false)), "helmet": helmet, "kill": killed})
	if arm > 0.0:
		st["armour_hits"] = float(st["armour_hits"]) + 1.0
	var out := {"damage": int(round(x)), "amount": x, "by_type": by, "top_type": str(top[0]), "headshot": heads > 0, "helmet": helmet,
		"leg": leg, "arm": arm_shot, "armour": arm, "killed": killed, "hard": bool(ms.get("hard", false)), "clean": clean,
		"pinned": float(ms.get("supp", 0.0)) >= 1.0}
	if killed:
		out.merge(on_kill(ctx, ms, rng), true)
	return out


## One round's damage of a gun before the man: its share of the damage a second (the sim's own chain) over its rate.
static func round_damage(ctx: Dictionary, gun: Dictionary) -> float:
	var s = ctx["sim"]
	var it: Dictionary = gun.get("item", gun)
	var slot: String = str(gun.get("slot", "Primary"))
	var b: Dictionary = Items.base_of(it)
	var rof: float = maxf(0.01, float(b.get("rof", 1.0)))
	var own: float = Items.dps(it) * (1.0 + s.grade_bonus(it) / 100.0) * s._class_gun_mult(it)
	if slot == "Primary" and s.has_node("cap_jerry") and str(b.get("type", "")) == "improvised":
		own *= Data.FX["node/cap_jerry"]
	if slot == "Secondary" and s.has_rule("branch_pistol") and s.hp < s.max_hp() * 0.5:
		own *= Data.FX["rule/branch_pistol"]
	var u: Array = s.u67_gun_x(true)
	own *= float(u[0] if slot == "Primary" else u[1])
	var pair: Array = s._gun_dps()
	var guns: float = float(pair[0]) + float(pair[1])
	var runner_x: float = s.dps() / guns if guns > 0.0 else 1.0     # the level, the %, attack, the class, growth: the sim's chain
	return own * runner_x / (rof * s.rate_x())


## The share of a hit his armour takes (f66_armour on him): the depth's, an Armoured hard man's doubled, pierce_pct.
static func man_armour(ctx: Dictionary, ms: Dictionary, sv := {}) -> float:
	var s = ctx["sim"]
	var a: float = Sim.f66_by_depth(ctx["t"], Data.ARMOUR66_DEPTH, Data.ARMOUR66_TAKE)
	if bool(ms.get("hard", false)) and "armoured" in ms.get("traits", []):
		a = maxf(a, Data.HARD66_ARMOUR_MIN / 100.0) * 2.0
	if s.has_rule("armourers_box"):
		a *= Data.BOX67_ARMOUR
	return clampf(a * (1.0 - s._f66_v(sv, "pierce_pct") / 100.0), 0.0, 0.9)


## A dot on him, as the sim's _dot_add: a share of what landed into his pool, capped by the rate.
static func _dot_add(ctx: Dictionary, ms: Dictionary, ty: String, landed: float, rate_cap: float) -> void:
	var s = ctx["sim"]
	var d: Dictionary = Data.DOTS[ty]
	var grow: float = s.dot_grow(true)
	var cap: float = rate_cap * float(d["ratio"]) * s.dot_seconds(ty, true) * s.dot_stacks(ty, true) * s.dot_depth(true) * maxf(grow, 1.0)
	var old: float = float(ms["dots"].get(ty, 0.0))
	ms["dots"][ty] = maxf(old, minf(cap, old + landed * float(d["ratio"]) * grow))


## A skill's dot: `secs` of your damage into his pool (the sim's _skill_dot).
static func _skill_dot_on(ctx: Dictionary, ms: Dictionary, ty: String, secs: float) -> void:
	var raw: float = ctx["sim"].damage_total_raw()
	_dot_add(ctx, ms, ty, raw * secs, raw)


## His dots this frame: what they deal (the man takes it off his HP). Returns {amount, by}.
static func man_dots_tick(ctx: Dictionary, ms: Dictionary, dt: float) -> Dictionary:
	var s = ctx["sim"]
	var by := {}
	var dealt := 0.0
	for ty in ms["dots"].keys():
		var pool: float = float(ms["dots"][ty])
		if pool <= 0.0:
			ms["dots"].erase(ty)
			continue
		var drain: float = minf(pool, pool / s.dot_seconds(ty, true) * dt)
		if not (ty == "bleed" and s.has_node("bleed_forever")):
			ms["dots"][ty] = pool - drain
		dealt += drain
		by[ty] = drain
	for k in ["chill_t", "shock_t", "arm_t", "leg_t", "stun_t", "exposed_t"]:
		ms[k] = maxf(0.0, float(ms.get(k, 0.0)) - dt)
	ms["since_shot"] = float(ms.get("since_shot", 0.0)) + dt
	if float(ms.get("since_shot", 0.0)) > T.G_PIN_GRACE_S:
		ms["supp"] = maxf(0.0, float(ms.get("supp", 0.0)) - dt / Data.SUPP66_DRAIN_S)
	if bool(ms.get("hard", false)) and "medic" in ms.get("traits", []) and float(ms["hp"]) > 0.0:
		ms["hp"] = minf(float(ms["hp_max"]), float(ms["hp"]) + Data.MEDIC66_PCT / 100.0 * float(ctx["t"]["hp"]) * dt)     # First aider: himself (the sim's: the man in front)
	ms["hp"] = float(ms["hp"]) - dealt
	return {"amount": dealt, "by": by, "killed": dealt > 0.0 and float(ms["hp"]) <= 0.0}


## A man down: the streak, scavenger's round, the kill's heal, the hard man's drop, the find roll. Returns
## {drops: Array, heal: float, scav: bool}.
static func on_kill(ctx: Dictionary, ms: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var s = ctx["sim"]
	var m: Dictionary = s.mission
	m["f66_streak"] = int(m.get("f66_streak", 0)) + 1
	var st: Dictionary = s._f66_stats(m)
	st["best_streak"] = maxi(int(st["best_streak"]), int(m["f66_streak"]))
	m["kills"] = int(m.get("kills", 0)) + 1
	ctx["kills"] = int(ctx["kills"]) + 1
	var scav: bool = rng.randf() < s.f66_stat("scav_pct") / 100.0
	var heal: float = s._kill_heal()
	if bool(ms.get("hard", false)):
		_event(ctx, "hard_down", {"name": str(ms.get("name", ""))})
	return {"drops": kill_drops(ctx, ms, rng), "heal": heal, "scav": scav, "streak": int(m["f66_streak"])}


## The find roll on a kill (the sim's _kill: the site's drop chance and the loot bonus; the hard man's one more, better).
static func kill_drops(ctx: Dictionary, ms: Dictionary, rng: RandomNumberGenerator) -> Array:
	var s = ctx["sim"]
	var m: Dictionary = s.mission
	var t: Dictionary = ctx["t"]
	var out: Array = []
	if rng.randf() < float(t["drop"]) * (1.0 + s.loot_bonus()):
		out.append_array(_find(s, m, t, true))
	if bool(ms.get("hard", false)):
		var better: Dictionary = t.duplicate()
		better["rarity"] = float(t.get("rarity", 0.0)) + Data.HARD66_RARITY
		out.append_array(_find(s, m, better, true))
	return out


## A crate searched: the sim's find on a search.
static func crate_finds(ctx: Dictionary, _rng: RandomNumberGenerator = null) -> Array:
	var s = ctx["sim"]
	var out: Array = []
	for k in range(T.G_CRATE_FINDS):
		out.append_array(_find(s, s.mission, ctx["t"], false))
	return out


## The sim's _find on the slice's mission; the item it placed (pack, floor or stack), taken back out of the slice's sim
## so nothing piles up there.
static func _find(s, m: Dictionary, t: Dictionary, from_kill: bool) -> Array:
	var got: Dictionary = s._find(m, t, from_kill)
	var it: Dictionary = got.get("it", {}) if got.get("it", null) is Dictionary else {}
	if it.is_empty():
		return []
	return [{"name": _item_name(it), "rarity": int(it.get("rarity", 0)), "slot": str(it.get("slot", "")), "icon": _item_icon(it), "item": it}]


static func _item_name(it: Dictionary) -> String:
	return str(it.get("unique", it.get("piece", it.get("base", ""))))


static func _gang_left(ctx: Dictionary) -> int:
	var w = ctx.get("world", null)
	if w == null or not is_instance_valid(w) or w.get("gang") == null:
		return 0
	return int(w.gang.alive)


# ------------------------------------------------------------------ their fire on you

## One of their rounds on the runner: their fire a second over SliceTuning.G_MAN_ROF, by type - physical through your
## armour, the rest your resists - the crowd rules, low HP, Decoy, Go to ground, an arm-shot man's misses, a Spotter,
## Guard first. `on_you`: how many have you in their sights now. Returns {hp_loss:int, guard_loss:int, missed, amount, by_type}.
static func hit_on_runner(ctx: Dictionary, runner, ms: Dictionary, rng: RandomNumberGenerator, on_you := 1, spotter := false) -> Dictionary:
	var s = ctx["sim"]
	var m: Dictionary = s.mission
	var t: Dictionary = ctx["t"]
	if runner != null:
		s.hp = float(runner.hp)
	var miss := {"hp_loss": 0, "guard_loss": 0, "missed": true, "amount": 0.0, "by_type": {}}
	if float(ctx["buffs"].get("hidden_t", 0.0)) > 0.0:
		return miss                                    # Go to ground: out of sight
	if float(ms.get("arm_t", 0.0)) > 0.0 and rng.randf() < (Data.KNUCKLES67_MISS if s.has_rule("bouncers") else Data.ARM66_MISS):
		return miss                                    # an arm shot: he misses more
	var raw: float = float(ms["dps"]) / T.G_MAN_ROF * rng.randf_range(1.0 - Sim.VARIANCE, 1.0 + Sim.VARIANCE)
	var types: Dictionary = ms.get("types", {"physical": 1.0})
	var by := {}
	var amount := 0.0
	for ty in types:
		var share := float(types[ty])
		var part: float = raw * share * ((1.0 - s._mitigation_under(t)) if ty == "physical" else (1.0 - s.resist(ty))) * (1.1 if ty == "fire" and s.has_node("blast_burns") else 1.0)
		by[ty] = part
		amount += part
	amount *= Data.MELEE_INCOMING if s.melee() else 1.0
	amount *= s.crowd_mult(on_you)
	amount *= s.low_hp_mult()
	amount *= 1.0 - float(Data.SKILLS["decoy"]["fx"]["less_in"]) * (1.0 if float(ctx["buffs"].get("decoy_t", 0.0)) > 0.0 else 0.0)
	if spotter:
		amount *= 1.0 + Data.SPOTTER66_PCT / 100.0
	amount *= s.combo_guard(m)
	if float(m.get("immune_t", 0.0)) > 0.0:
		amount = 0.0
	# their burn, poison and bleed: a share into the pools on you (ticked in tick())
	for ty in ["fire", "poison", "bleed"]:
		var sh := float(types.get(ty, 0.0))
		if sh > 0.0 and amount > 0.0 and not s.cure_wards(m, ty):
			s._dot_add(m["my_dots"], ty, amount * sh, amount * sh * T.G_MAN_ROF)
	return _land_on_runner(ctx, runner, amount, by)


## What reaches the runner: Guard first (the sim's _take), the streak's hit (_f66_taken).
static func _land_on_runner(ctx: Dictionary, runner, amount: float, by: Dictionary) -> Dictionary:
	var s = ctx["sim"]
	var m: Dictionary = s.mission
	# Guard's fractions carried as HP's are (the review, 9 Nov: a round to whole Guard ate small hits whole): what's spent
	# of the next point already is off what stands
	var g_frac: float = float(ctx.get("guard_frac", 0.0))
	var g: float = maxf(0.0, (float(runner.guard) if runner != null else float(m.get("guard", 0.0))) - g_frac)
	var off: float = minf(g, amount)
	var on_hp: float = amount - off
	var guard_loss: int = int(floor(off + g_frac))
	ctx["guard_frac"] = off + g_frac - float(guard_loss)
	var hp_loss: int = int(floor(on_hp + float(ctx.get("hp_frac", 0.0))))
	ctx["hp_frac"] = on_hp + float(ctx.get("hp_frac", 0.0)) - float(hp_loss)     # the fractions carried: small hits still add up
	m["guard"] = g - off
	var had: int = int(m.get("f66_streak", 0))
	s._f66_taken(m, on_hp)
	if had > 0 and int(m.get("f66_streak", 0)) == 0:
		_event(ctx, "streak_end", {"was": had})
	return {"hp_loss": hp_loss, "guard_loss": guard_loss, "missed": false, "amount": amount, "by_type": by}


# ------------------------------------------------------------------ skills and meds

## Fires skill slot `i` (Q/E/R): its energy and cooldown on the runner, its effect on the men by `aim` when aimed.
static func use_skill(world, i: int, aim: Vector2) -> bool:
	var ctx: Dictionary = world.ctx
	var runner = world.runner
	if i < 0 or i >= ctx["skills"].size():
		return false
	var sk: Dictionary = ctx["skills"][i]
	var id: String = str(sk.get("id", ""))
	if id == "" or not _skill_in_slice(id):
		return false
	var st: Dictionary = runner.skill_state.get(i, {"cd_left": 0.0, "cd": float(sk["cd"])})
	if float(st["cd_left"]) > 0.0 or float(runner.energy) < float(sk["cost"]):
		return false
	var fx: Dictionary = Data.SKILLS[id]["fx"]
	var men: Array = world.men()
	var hit: Array = []
	match id:
		"clean_shot":
			ctx["buffs"]["clean_shot"] = true
		"flush_them_out":
			var mn = _nearest(men, aim, T.G_AIM_PICK_R)
			if mn == null:
				return false
			mn.state_data()["exposed_t"] = float(fx["exposed_s"])
			if mn.has_method("flush"):
				mn.flush(runner.global_position)
			hit.append(mn)
		"go_to_ground":
			ctx["buffs"]["hidden_t"] = float(fx["hidden_s"])
			for ty in fx["clears"]:
				ctx["sim"].mission["my_dots"].erase(ty)
		"one_for_the_pot":
			var mn = _nearest(men, aim, T.G_AIM_PICK_R)
			if mn == null or float(mn.state_data()["hp"]) > float(mn.state_data()["hp_max"]) * T.G_POT_UNDER:
				return false                                  # the finisher's rule: a man under a quarter
			var ms: Dictionary = mn.state_data()
			var res := {"damage": int(ceil(float(ms["hp"]))), "amount": float(ms["hp"]), "headshot": false, "killed": true, "skill": id}
			ms["hp"] = 0.0
			res.merge(on_kill(ctx, ms, world.rng), true)
			mn.die_by(res)
			hit.append(mn)
		"collared":
			var mn = _nearest(men, aim, T.G_AIM_PICK_R)
			if mn == null:
				return false
			mn.state_data()["stun_t"] = float(fx["stun_one_s"])
			hit.append(mn)
		"gin_trap":
			ctx["traps"].append({"at": aim, "r": T.G_TRAP_R})
		"decoy":
			ctx["buffs"]["decoy_t"] = float(fx["less_in_s"])
		"net_every_hole":
			for mn in men:
				if mn.global_position.distance_to(aim) <= T.G_NET_R:
					mn.state_data()["stun_t"] = float(fx["stun_all_s"])
					_skill_dot_on(ctx, mn.state_data(), "bleed", float(fx["bleed_s"]))
					hit.append(mn)
			if hit.is_empty():
				return false
	runner.energy = float(runner.energy) - float(sk["cost"])
	runner.skill_state[i] = {"cd_left": float(sk["cd"]), "cd": float(sk["cd"])}
	_event(ctx, "skill", {"i": i, "id": id, "name": str(sk["name"]), "at": aim, "men": hit.size()})
	return true


static func _nearest(men: Array, at: Vector2, within: float):
	var best = null
	var bd := within
	for mn in men:
		if not is_instance_valid(mn) or mn.is_dead():
			continue
		var d: float = mn.global_position.distance_to(at)
		if d <= bd:
			bd = d
			best = mn
	return best


## A med from the rig (1-4): its heal (the sim's med_heal) over its use time (use_time), one at a time; a dressing stops
## the bleeding when it's done.
static func use_med(world, i: int) -> bool:
	var ctx: Dictionary = world.ctx
	var runner = world.runner
	if i < 0 or i >= ctx["meds"].size() or not ctx["using"].is_empty():
		return false
	var md: Dictionary = ctx["meds"][i]
	if int(md["count"]) <= 0 or int(runner.hp) >= int(runner.hp_max):
		return false
	md["count"] = int(md["count"]) - 1
	var secs: float = float(md["use_s"])
	ctx["using"] = {"i": i, "left": secs, "time": secs, "heal": float(md["heal"]), "given": 0.0, "frac": 0.0}
	_event(ctx, "med", {"i": i, "name": str(md["name"]), "heal": int(md["heal"]), "s": secs})
	if secs <= 0.0:
		_med_tick(ctx, runner, 0.0)
	return true


static func _med_tick(ctx: Dictionary, runner, dt: float) -> void:
	var u: Dictionary = ctx["using"]
	if u.is_empty():
		return
	var total: float = float(u["heal"])
	var portion: float = total - float(u["given"]) if float(u["left"]) <= dt else total * dt / maxf(0.0001, float(u["time"]))
	u["left"] = float(u["left"]) - dt
	u["given"] = float(u["given"]) + portion
	u["frac"] = float(u["frac"]) + portion
	var n: int = int(floor(float(u["frac"])))
	if n > 0:
		u["frac"] = float(u["frac"]) - n
		runner.heal(n)
	if float(u["left"]) <= 0.0:
		ctx["sim"].mission["my_dots"].erase("bleed")      # a dressing stops the bleeding
		ctx["using"] = {}


## The bridge's frame (the gang director calls it): energy, cooldowns, buffs, a med going in, the dots on you, the
## traps, Guard's cap, the sim mission's clock.
static func tick(world, dt: float) -> void:
	var ctx: Dictionary = world.ctx
	var runner = world.runner
	if runner == null:
		return
	var s = ctx["sim"]
	var m: Dictionary = s.mission
	m["elapsed"] = float(m["elapsed"]) + dt
	s.hp = float(runner.hp)
	runner.energy = minf(float(runner.energy_max), float(runner.energy) + s.energy_regen() * dt)
	for i in runner.skill_state.keys():
		var st: Dictionary = runner.skill_state[i]
		st["cd_left"] = maxf(0.0, float(st["cd_left"]) - dt)
	for k in ctx["buffs"].keys():
		if str(k).ends_with("_t"):
			ctx["buffs"][k] = maxf(0.0, float(ctx["buffs"][k]) - dt)
	_med_tick(ctx, runner, dt)
	# what their fire left on you: the pools tick
	if not m["my_dots"].is_empty():
		var by := {}
		var dealt: float = s._dot_tick(m["my_dots"], dt, by)
		if dealt > 0.0 and int(runner.hp) > 0:
			var res: Dictionary = _land_on_runner(ctx, runner, dealt, by)
			res["dot"] = true
			if int(res["hp_loss"]) > 0 or int(res["guard_loss"]) > 0:
				runner.apply_hit(res)
	# Gin traps: the first man to step in
	for trap in ctx["traps"].duplicate():
		for mn in world.men():
			if is_instance_valid(mn) and not mn.is_dead() and mn.global_position.distance_to(trap["at"]) <= float(trap["r"]):
				mn.state_data()["trap"] = true
				mn.state_data()["stun_t"] = maxf(float(mn.state_data()["stun_t"]), T.G_TRAP_HOLD_S)
				ctx["traps"].erase(trap)
				_event(ctx, "trap", {"at": trap["at"]})
				break


## A new gang arrives (the director calls it): the sim's Guard at a gang (Squared up, guard_gang, Bin lid), energy full
## and the cooldowns ready as each fight starts in the sim, the first shot's bonus due again.
static func gang_arrives(world, gang_i: int) -> void:
	var ctx: Dictionary = world.ctx
	var s = ctx["sim"]
	var m: Dictionary = s.mission
	m["patrols"] = gang_i
	m["fresh"] = true
	m["remaining"] = int(ctx["site"]["gang_sizes"][gang_i])
	ctx["gang_i"] = gang_i
	var share: float = (Data.FX["node/squared_up"] if s.has_node("squared_up") else 0.0) + s._affix_sum("guard_gang") + (25.0 if s.has_node("bin_lid") else 0.0)
	var runner = world.runner
	if runner != null:
		if share > 0.0:
			runner.guard = mini(int(runner.guard_max), int(runner.guard) + int(round(s.max_hp() * share / 100.0)))
		runner.energy = float(runner.energy_max)
		for i in runner.skill_state.keys():
			runner.skill_state[i]["cd_left"] = 0.0
