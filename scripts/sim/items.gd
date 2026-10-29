extends RefCounted
## Items: rolling them, reading them, scoring them. An item is a Dictionary so
## it saves as JSON without ceremony:
##   {id, slot, base (name), rarity (index), affixes: [{stat, value}],
##    attachments: {slot_name: null | item}, tier, value}
## A gun's `attachments` map is its own body - the slots are real, the contents
## are null for now.

const Data := preload("res://scripts/sim/data.gd")

static var _next_id := 1


## A new item of this slot, from the bases a zone tier can drop, at a rarity
## rolled from the table. `rng` so the tests can replay a run.
static func roll(slot: String, max_tier: int, rng: RandomNumberGenerator, rarity_bonus := 0.0, no_commons := false, fewer_commons := false,
		site := "", prefer := "", own_share := 0.33, depth := 0, level := -1) -> Dictionary:
	# the site's own: a base found only there drops only there, and a third of
	# the time the roll is one of them; a site that leans to a gun type leans
	var pool: Array = []
	var own: Array = []
	for b in (Data.ATTACHMENTS if slot == Data.ATTACHMENT else Data.BASES[slot]):
		if b["tier"] > max_tier:
			continue
		if int(b.get("depth", 0)) > depth:
			continue                          # a deep paper: only past its depth
		if b.get("start", false):
			continue                          # the starting kit: worn on day one, never found
		var home := exclusive_to(b["name"])
		if home != "" and home != site:
			continue
		if home == site and site != "":
			own.append(b)
		pool.append(b)
	if not own.is_empty() and rng.randf() < own_share:
		pool = own
	elif prefer != "" and rng.randf() < 0.5:
		var typed: Array = []
		for b in pool:
			if b.get("type", "") == prefer:
				typed.append(b)
		if not typed.is_empty():
			pool = typed
	var base: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var r := _roll_rarity(rng, rarity_bonus)
	if no_commons and r == 0:
		r = 1
	if fewer_commons and r == 0 and rng.randf() < 0.5:
		r = _roll_rarity(rng, rarity_bonus)
	# the item's level: its base's tier and the depth it dropped at; it sets the floor under the tiers its
	# affixes roll, and the rarity sets the cap (a Legendary from the first site is five T5s on a tier-1 base)
	# the item's level: the site's (its tier and depth: the endgame, 7 Oct) when the find is a site's, else the
	# base's tier and the depth as before (the shelf, the gamble, the Clinic)
	var ilvl_v: int = level if level >= 0 else int(base["tier"]) + maxi(0, depth)
	var affixes: Array = []
	var picked := pick_affixes(slot, int(Data.RARITIES[r]["affixes"]), rng)
	for a in picked:
		affixes.append(roll_affix(a, ilvl_v, rng, 0, int(Data.RARITIES[r]["tier"])))
	var attachments := {}
	for name in base.get("attachments", []):
		attachments[name] = null
	if slot in Data.SOCKET_SLOTS:
		var x := rng.randf()
		var n := 0
		var acc := 0.0
		for k in range(Data.SOCKET_ODDS.size()):
			acc += Data.SOCKET_ODDS[k]
			if x <= acc:
				n = k
				break
		n += bodge(base)                       # something improvised: one more than another gun (29 Oct, the type edge)
		for k in range(n):
			attachments["socket %d" % (k + 1)] = null
	if slot == Data.AMMO or slot == Data.PAPER or slot == Data.GRENADE or (slot == Data.ATTACHMENT and base.get("mount", "") == "socket"):
		r = mini(r, Data.PAPER_RARITY_MAX) if slot == Data.PAPER else 0     # a box is a box; a bottle a bottle; a grenade a grenade; a paper rare or plain (15 Oct: a rare one rolls its signal deeper)
		affixes = []
	if slot == Data.SUPPLIES:
		r = 0
		affixes = []
	if slot == Data.MEDICAL and base.has("cure"):
		r = 0                                 # a cure is a cure (28 Oct): its one job, nothing to roll
		affixes = []
	var it := {
		"id": _next_id, "slot": slot, "base": base["name"], "rarity": r, "affixes": affixes,
		"attachments": attachments, "tier": base["tier"], "ilvl": ilvl_v,
		"value": int(round(base["value"] * Data.RARITIES[r]["value"])),
	}
	if slot == Data.AMMO:
		it["rounds"] = int(base["rounds"])
	if slot == Data.ATTACHMENT:
		it["mount"] = base["mount"]
		if base["mount"] == "socket":
			it["count"] = 1
	if slot == Data.SUPPLIES:
		it["count"] = 1
	_next_id += 1
	return it


## Rarity weights, shifted toward the rare end by loot find.
## The rarity by weight; quality compounds up the ladder (a rank's weight × (1 + quality)^rank), so
## +35% is ×1.35 on Uncommon and ×3.3 on Legendary - a step the player can see at the top, where it
## was a flat ×1.35 on everything above Common and the Legendary share barely moved.
static func _roll_rarity(rng: RandomNumberGenerator, bonus: float) -> int:
	var weights: Array = []
	var total := 0.0
	for i in range(Data.RARITIES.size()):
		var w: float = Data.RARITIES[i]["weight"]
		if i > 0:
			w *= pow(1.0 + bonus, i)
		weights.append(w)
		total += w
	var x := rng.randf() * total
	for i in range(weights.size()):
		x -= weights[i]
		if x <= 0.0:
			return i
	return 0


static var _exclusive := {}       # base -> the site it drops at, from the sites' "only" lists


## The one site a base drops at, or "" when it drops anywhere.
static func exclusive_to(base: String) -> String:
	if _exclusive.is_empty():
		for t in Data.TIERS:
			for name in t["drops"].get("only", []):
				_exclusive[name] = t["name"]
	return _exclusive.get(base, "")


## The base's table row.
## A base by its slot and name; {} when there is none.
static func base_named(slot: String, name: String) -> Dictionary:
	for b in (Data.ATTACHMENTS if slot == Data.ATTACHMENT else Data.BASES[slot]):
		if b["name"] == name:
			return b
	return {}


static var _base_index := {}      # slot -> name -> base: the tables are read a few hundred times a tick in a dry run (7 Oct, the Runs screen's lag)


static func base_of(it: Dictionary) -> Dictionary:
	var slot: String = it["slot"]
	var by_name: Dictionary = _base_index.get(slot, {})
	if by_name.is_empty():
		for b in (Data.ATTACHMENTS if slot == Data.ATTACHMENT else Data.BASES[slot]):
			by_name[b["name"]] = b
		_base_index[slot] = by_name
	return by_name.get(it["base"], {})


## The item's footprint, W x H in cells: the base's own, or its slot's default.
static func footprint(it: Dictionary) -> Vector2i:
	var f: Array = Data.FOOTPRINTS.get(it["base"], Data.SIZE.get(it["slot"], [1, 1]))
	return Vector2i(int(f[0]), int(f[1]))


## Cells the item takes: its footprint's area. Capacities are counted in these.
static func size(it: Dictionary) -> int:
	var f := footprint(it)
	return f.x * f.y


## The file stem a base's picture is kept under: lowercase, every run of
## anything but a letter or digit one underscore. "Semi-auto .22" -> semi_auto_22.
static func slug(base: String) -> String:
	var out := ""
	var gap := false
	for ch in base.to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			if gap and out != "":
				out += "_"
			gap = false
			out += ch
		else:
			gap = true
	return out


static var _art := {}      # slug -> Texture2D or null, once looked for


## The name a base's pictures are under (the fix round, 29 Oct): its own, else the older one it was made as (Data.ART_AS).
static func art_name(base: String) -> String:
	return str(Data.ART_AS.get(base, base))


## The item's picture, if one has been made: res://art/items/<slug>.png.
## A unique has its own (grandad_s_shotgun.png) and falls back to its
## base's until that's made. Looked for once; null means text instead.
static func art(it: Dictionary) -> Texture2D:
	if it.has("unique"):
		var own := _art_named(slug(it["unique"]))
		if own != null:
			return own
	if it.has("piece"):
		var own := _art_named(slug(it["piece"]))
		if own != null:
			return own
	var base := _art_named(slug(art_name(str(it["base"]))))
	if base == null and is_paper(it) and not is_deeds(it):
		return _art_named("paper")        # every paper is the same folded thing in the cell; the words tell them apart
	return base


## A rig pouch's picture (28 Oct, magazines): its magazines by the rounds' type - art/items/mag_<type>.png, "belt" for
## belt links - or null, and the cell keeps the box's picture.
static func mag_art(it: Dictionary) -> Texture2D:
	var name := mag_slug(it)
	return _art_named(name) if name != "" else null


## The pouch's picture's name: "mag_<the rounds' type>", "mag_belt" for belt links; "" for anything not rounds.
static func mag_slug(it: Dictionary) -> String:
	if it.is_empty() or not is_ammo(it):
		return ""
	var kind: String = "belt" if str(it.get("base", "")) == "Belt links" else str(base_of(it).get("type", ""))
	return ("mag_" + kind) if kind != "" else ""


static func _art_named(s: String) -> Texture2D:
	if not _art.has(s):
		var path := "res://art/items/%s.png" % s
		_art[s] = null
		if ResourceLoader.exists(path):
			_art[s] = load(path)          # imported by the editor: the export carries it
		elif FileAccess.file_exists(path):
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))   # dropped in, not yet imported
			if img != null:
				_art[s] = ImageTexture.create_from_image(img)
	return _art[s]


static func is_attachment(it: Dictionary) -> bool:
	return it["slot"] == Data.ATTACHMENT


static func is_gun(it: Dictionary) -> bool:
	return base_of(it).has("damage") and base_of(it).has("rof")     # a grenade has damage and no rate


## An attachment's figure for a stat: its base plus its affixes.
static func att_stat(it: Dictionary, stat: String) -> float:
	return float(base_of(it).get(stat, 0)) + affix_total(it, stat)


## What a gun's fitted attachments add up to for a stat. A part made for a
## type (a choke, a bipod) only counts on a gun of that type.
static func fitted_sum(gun: Dictionary, stat: String) -> float:
	var t := 0.0
	var gun_type: String = base_of(gun).get("type", "")
	for mount in gun.get("attachments", {}):
		var a = gun["attachments"][mount]
		if a != null and att_fits(a, gun_type):
			t += att_stat(a, stat)
	return t


## "Shotguns only", "SMGs only", "Improvised guns only": what a typed part goes on.
static func only_words(a: Dictionary) -> String:
	var t: String = base_of(a).get("type", "")
	return {"smg": "SMGs only", "improvised": "Improvised guns only"}.get(t, "%ss only" % t.capitalize())


## Whether an attachment's effects count on a gun of this type.
static func att_fits(a: Dictionary, gun_type: String) -> bool:
	var need: String = base_of(a).get("type", "")
	return need == "" or need == gun_type


static func fitted_count(gun: Dictionary) -> int:
	var n := 0
	for mount in gun.get("attachments", {}):
		if gun["attachments"][mount] != null:
			n += 1
	return n


## What's fitted on a gun, long to short: "Holo sight, Bipod + lighter fluid",
## "2 parts + 1 socketable", "3 fitted"; "nothing fitted" / "no mounts" when empty.
static func fitted_words(gun: Dictionary) -> Array:
	var parts := []
	var socks := []
	for mount in gun.get("attachments", {}):
		var a = gun["attachments"][mount]
		if a == null:
			continue
		if str(mount).begins_with("socket"):
			socks.append(str(a["base"]).to_lower())
		else:
			parts.append(str(a["base"]))
	var mounts: int = gun.get("attachments", {}).size()
	if mounts == 0:
		return ["no mounts"]
	if parts.is_empty() and socks.is_empty():
		return ["nothing fitted", "%d mount%s" % [mounts, "" if mounts == 1 else "s"]]
	var long: String = ", ".join(parts)
	if not socks.is_empty():
		long += (" + " if not parts.is_empty() else "") + ", ".join(socks)
	var counts := []
	if not parts.is_empty():
		counts.append("%d part%s" % [parts.size(), "" if parts.size() == 1 else "s"])
	if not socks.is_empty():
		counts.append("%d socketable%s" % [socks.size(), "" if socks.size() == 1 else "s"])
	return [long, " + ".join(counts), "%d fitted" % (parts.size() + socks.size())]


static func rarity_name(it: Dictionary) -> String:
	if it.get("mythic", false):
		return "Mythic"
	if it.has("unique"):
		return "Unique"
	if it.has("set"):
		return "Set"
	return Data.RARITIES[it["rarity"]]["name"]


## The name a row or a title shows: the base, since rarity is the colour on
## the edge and the word on the figure line; a unique goes by its own name.
static func full_name(it: Dictionary) -> String:
	if it.has("serial"):
		return "%s · No. %04d" % [it["unique"], int(it["serial"])]     # issued kit's number (25 Oct)
	if it.has("unique"):
		return it["unique"]
	if it.has("piece"):
		return it["piece"]
	return it["base"]


# ------------------------------------------------------------------ affixes and tiers

## The affixes a slot can roll.
static func allowed_affixes(slot: String) -> Array:
	var allowed: Array = []
	for a in Data.AFFIXES:
		if slot in a["slots"]:
			allowed.append(a)
	return allowed


static func affix_def(stat: String) -> Dictionary:
	for a in Data.AFFIXES:
		if a["stat"] == stat:
			return a
	return {}


## An affix's def for a slot (29 Oct): the slot's own where it has one - the gloves' armour rolls small, a gun part's damage
## 2-6 against a gun's 4-24 (the fix round: the Bench re-rolled a part's on the gun's range) - else affix_def's.
static func affix_def_for(stat: String, slot: String) -> Dictionary:
	for a in Data.AFFIXES:
		if a["stat"] == stat and slot in a.get("slots", []):
			return a
	return affix_def(stat)


## `n` distinct affixes for a slot, by weight, none already in `have`.
static func pick_affixes(slot: String, n: int, rng: RandomNumberGenerator, have: Array = []) -> Array:
	var pool: Array = []
	for a in allowed_affixes(slot):
		if not (a["stat"] in have):
			pool.append(a)
	var out: Array = []
	while out.size() < n and not pool.is_empty():
		var total := 0.0
		for a in pool:
			total += float(a.get("weight", 1.0))
		var x := rng.randf() * total
		var pick := 0
		for k in range(pool.size()):
			x -= float(pool[k].get("weight", 1.0))
			if x <= 0.0:
				pick = k
				break
		out.append(pool[pick])
		pool.remove_at(pick)
	return out


## The best tier an item level opens: T1 always, T5 from level TIER_CAP[4].
static func tier_cap(ilvl_v: int) -> int:
	var best := 1
	for k in range(Data.TIER_CAP.size()):
		if ilvl_v >= int(Data.TIER_CAP[k]):
			best = k + 1
	return best


## The floor an item level puts under a drop's affix tiers: T1 until TIER_FLOOR[1], T2 from there, and so
## on; never above the cap the rarity gives (a Common from the deep is still one T1).
static func tier_floor(ilvl_v: int) -> int:
	var lo := 1
	for k in range(Data.TIER_FLOOR.size()):
		if ilvl_v >= int(Data.TIER_FLOOR[k]):
			lo = k + 1
	return lo


## A tier from the ones open, the better the rarer.
## A tier between the level's floor and the cap, by weight. The cap is the rarity's on a drop
## (`rarity_cap` > 0), the level's at the Bench.
static func roll_tier(ilvl_v: int, rng: RandomNumberGenerator, rarity_cap_v := 0) -> int:
	var cap := rarity_cap_v if rarity_cap_v > 0 else tier_cap(ilvl_v)
	var lo := mini(tier_floor(ilvl_v), cap)
	var total := 0.0
	for t in range(lo, cap + 1):
		total += float(Data.TIER_WEIGHT[t - 1])
	var x := rng.randf() * total
	for t in range(lo, cap + 1):
		x -= float(Data.TIER_WEIGHT[t - 1])
		if x <= 0.0:
			return t
	return lo


## An affix's value range at a tier: the span cut in five, T5 the top fifth.
static func tier_range(a: Dictionary, tier: int) -> Array:
	var lo := float(a["min"])
	var hi := float(a["max"])
	var w := (hi - lo + 1.0) / float(Data.AFFIX_TIERS)
	var k := tier - 1                                # 0 for T1, 4 for T5
	var from := int(floor(lo + w * k))
	var to := int(floor(lo + w * (k + 1))) - 1
	if tier == Data.AFFIX_TIERS:
		to = int(hi)
	return [from, maxi(from, to)]


static func roll_affix(a: Dictionary, ilvl_v: int, rng: RandomNumberGenerator, tier := 0, rarity_cap_v := 0, top := false) -> Dictionary:
	var t := tier if tier > 0 else roll_tier(ilvl_v, rng, rarity_cap_v)
	var r := tier_range(a, t)
	var lo: int = int(ceil((r[0] + r[1]) / 2.0)) if top else int(r[0])      # the Bench's Masterwork (9 Oct): the top half of the tier
	var raw: float = rng.randi_range(mini(lo, r[1]), r[1]) * affix_mult(str(a["stat"]), ilvl_v)
	var div := float(a.get("div", 1))
	var v: Variant = int(round(raw))
	if div > 1.0:
		v = snappedf(raw / div, 0.1)
	return {"stat": a["stat"], "value": v, "tier": t}


## A stat's figures are tenths (regen, the pass of 20 Oct): its def's "div" over 1.
static func is_tenths(stat: String) -> bool:
	return float(affix_def(stat).get("div", 1)) > 1.0


## An affix figure as a line shows it: "0.4" for a tenths stat, "15" for the rest.
static func fig(stat: String, v: float) -> String:
	return ("%.1f" % v) if is_tenths(stat) else ("%d" % int(round(v)))


## The deep drop's edge (7 Oct): an affix's value times this at an item level - nothing to ILVL_FROM, ILVL_SCALE a level
## past it, no top - so a depth-20 find of a tier beats a depth-10 one, and the chase never ends.
static func ilvl_mult(ilvl_v: int) -> float:
	return 1.0 + Data.ILVL_SCALE * maxi(0, ilvl_v - Data.ILVL_FROM)


## Gear scaling (21 Oct): a base's damage and armour, and a flat line's figure, times this past ILVL_GROW_FROM.
static func grow(ilvl_v: int) -> float:
	return pow(1.0 + Data.ILVL_GROW, maxi(0, ilvl_v - Data.ILVL_GROW_FROM))


## An affix's figure at an item level: a percent line on the straight line, a flat combat line (FLAT_GROW) on it to the
## deep tier and compounding past it, as the bases.
static func affix_mult(stat: String, ilvl_v: int) -> float:
	if stat in Data.FLAT_GROW:
		return ilvl_mult(mini(ilvl_v, Data.ILVL_GROW_FROM)) * grow(ilvl_v)
	return ilvl_mult(ilvl_v)


## A fixed affix list (a unique's, a set piece's) at an item level: the values scaled as a drop's would be.
static func _scaled(affixes: Array, ilvl_v: int) -> Array:
	var out: Array = affixes.duplicate(true)
	for a in out:
		var m: float = affix_mult(str(a["stat"]), ilvl_v)
		if is_tenths(str(a["stat"])):
			a["value"] = snappedf(float(a["value"]) * m, 0.1)
		else:
			a["value"] = int(round(float(a["value"]) * m))
	return out


## What a piece is worth (25 Oct, the review: value never grew with item level, so the Fence, scrap and insurance went
## flat while income grew): its value grown as its base's damage and armour are, past ILVL_GROW_FROM. Gear only.
static func worth(it: Dictionary) -> float:
	var v: float = float(it.get("value", 0))
	if str(it.get("slot", "")) in Data.SLOTS:
		v *= grow(ilvl(it))
	return v


static func ilvl(it: Dictionary) -> int:
	return int(it.get("ilvl", it["tier"]))


## The runner's level a piece needs to be worn (15 Oct, gear gated by level): only what goes in a body slot; rounds,
## meds, parts and papers carry no level.
static func wear_level(it: Dictionary) -> int:
	if not (str(it.get("slot", "")) in Data.SLOTS) or it.get("mythic", false):
		return 1
	return wear_for(ilvl(it) - mini(int(it.get("tempered", 0)), Data.TEMPER_PAST_WEAR))     # its first tempers don't raise its wear (the second review)


## A piece a temper grows: a base with damage or armour (a rig, a pack, a charm has neither).
static func grows(it: Dictionary) -> bool:
	var b := base_of(it)
	return b.has("damage") or b.has("armour")


## A temper's flat lines: each FLAT_GROW affix as a drop one item level deeper rolls it - from the figure it had before
## its first temper ("v0" at "lv0"), so a small line grows rather than rounding back each time (the reviewer: +8 HP).
static func temper_lines(it: Dictionary) -> void:
	var lv := ilvl(it)
	for a in it.get("affixes", []):
		var st := str(a["stat"])
		if not (st in Data.FLAT_GROW):
			continue
		if not a.has("v0"):
			a["v0"] = float(a["value"])
			a["lv0"] = lv
		var r: float = affix_mult(st, lv + 1) / maxf(0.0001, affix_mult(st, int(a["lv0"])))
		if is_tenths(st):
			a["value"] = snappedf(float(a["v0"]) * r, 0.1)
		else:
			a["value"] = int(round(float(a["v0"]) * r))


## An item level's wear (21 Oct, the crew's read): the campaign's curve to WEAR_FLAT (the City's 12-16), then the
## item level itself, as a signal's level is - a level-43 runner wears a level-43 signal's finds. The curve alone put
## every find past 25 at level 50: the classes under it walled at the reach's 45 in their campaign kit, and one at 50
## put on a stash of deep finds at once and ran the reach to 221.
static func wear_for(ilvl_v: int) -> int:
	return clampi(mini(int(round(ilvl_v * Data.WEAR_PER_ILVL - Data.WEAR_OFFSET)), maxi(ilvl_v, Data.WEAR_FLAT)), 1, Data.MAX_LEVEL)


## The deepest item level a runner of `level` wears: wear_for's inverse (no top at MAX_LEVEL).
static func max_ilvl_for(level: int) -> int:
	if level >= Data.MAX_LEVEL:
		return 1 << 20
	if level >= Data.WEAR_FLAT:
		return level
	return int((level + Data.WEAR_OFFSET) / Data.WEAR_PER_ILVL)


## The bench: the affixes rolled again (the count kept), one of them rolled
## again (its tier mostly kept; up a step sometimes, down a step less often,
## the odds narrowing as the tier rises), one more added, all of them off.
static func reroll_affixes(it: Dictionary, rng: RandomNumberGenerator, keep: Array = [], top := false) -> void:
	var n: int = it["affixes"].size()
	var kept: Array = []
	for a in it["affixes"]:
		if a["stat"] in keep:
			kept.append(a)                       # the padlocked ones (20 Oct: the Bench's padlocks; Two locks a second)
	var have: Array = []
	for a in kept:
		have.append(a["stat"])
	it["affixes"] = kept
	for a in pick_affixes(it["slot"], n - kept.size(), rng, have):
		it["affixes"].append(roll_affix(a, ilvl(it), rng, 0, rarity_cap(it), top))     # the Bench works as a drop does: the rarity's cap, the level's floor


## Every affix but the padlocked ones rolled again where it is: the same stat, new figures (20 Oct).
static func reroll_values(it: Dictionary, keep: Array, rng: RandomNumberGenerator, up_mult := 1.0, no_down := false, top := false) -> void:
	for a in it["affixes"].duplicate():
		if not (a["stat"] in keep):
			reroll_one(it, str(a["stat"]), rng, up_mult, no_down, top)


## One affix rolled again. Returns the new tier, or 0 if the stat isn't on it.
static func reroll_one(it: Dictionary, stat: String, rng: RandomNumberGenerator, up_mult := 1.0, no_down := false, top := false) -> int:
	for k in range(it["affixes"].size()):
		var a: Dictionary = it["affixes"][k]
		if a["stat"] != stat:
			continue
		var d := affix_def_for(stat, str(it.get("slot", "")))
		var t: int = int(a.get("tier", 1))
		var cap := maxi(rarity_cap(it), t)                     # one rule at the Bench (the pass, 6 Oct): the rarity's cap, the level's floor; a tier already past the cap (an old save) is left where it is
		var lo := mini(tier_floor(ilvl(it)), cap)
		var up := 0.25 / float(t) * up_mult                    # T1 → T2 one in four; T4 → T5 one in sixteen (×2 with Steady hands)
		var x := rng.randf()
		if x < up and t < cap:
			t += 1
		elif x < up + 0.1 and t > lo and not no_down:       # Fine tuning: never down
			t -= 1
		t = clampi(t, lo, cap)
		it["affixes"][k] = roll_affix(d, ilvl(it), rng, t, 0, top)
		return t
	return 0


## The best tier an item's rarity allows its affixes: the drop's cap, and the Bench's.
static func rarity_cap(it: Dictionary) -> int:
	return int(Data.RARITIES[clampi(int(it.get("rarity", 0)), 0, Data.RARITIES.size() - 1)]["tier"])


## One more affix, one not already on it, and the rarity up a step.
static func add_affix(it: Dictionary, rng: RandomNumberGenerator, top := false) -> bool:
	var have: Array = []
	for a in it["affixes"]:
		have.append(a["stat"])
	var open: Array = []
	for a in allowed_affixes(it["slot"]):
		if not (a["stat"] in have):
			open.append(a)
	if open.is_empty() or int(it["rarity"]) >= Data.RARITIES.size() - 1:
		return false
	var picked := pick_affixes(it["slot"], 1, rng, have)
	if picked.is_empty():
		return false
	it["rarity"] = int(it["rarity"]) + 1
	it["affixes"].append(roll_affix(picked[0], ilvl(it), rng, 0, rarity_cap(it), top))     # the new rarity's cap
	it["value"] = int(round(base_of(it)["value"] * Data.RARITIES[it["rarity"]]["value"]))
	return true


static func strip_affixes(it: Dictionary) -> void:
	it["affixes"] = []
	it["rarity"] = 0
	it["value"] = int(round(base_of(it)["value"] * Data.RARITIES[0]["value"]))


## Something improvised's edge (29 Oct, docs/design/itemisation.md §3): its sockets, one more than another gun's, on
## the roll, at the Bench and with the Pitch's Third socket. `b` a base (or an item: its base is read).
static func bodge(b: Dictionary) -> int:
	var base: Dictionary = base_of(b) if b.has("slot") and b.has("base") else b
	return int(Data.EDGE["improvised"]["sockets"]) if (str(base.get("type", "")) == "improvised" and base.has("rof")) else 0


## The sockets a piece can take: SOCKET_MAX, `extra` (the Pitch's Third socket), and an improvised gun's one more.
static func socket_cap(it: Dictionary, extra := 0) -> int:
	return Data.SOCKET_MAX + extra + bodge(it)


static func add_socket(it: Dictionary, most := Data.SOCKET_MAX) -> bool:
	if not (it["slot"] in Data.SOCKET_SLOTS) or sockets(it) >= most:
		return false
	it["attachments"]["socket %d" % (sockets(it) + 1)] = null
	return true


## A set piece, rolled: its base, its fixed affixes, the set's name on it. With a find's tier (21 Oct, Matt: "the set
## pieces dropping became useless") it keeps its own base - its resist, its conversion, its look - lifted to the best
## figure of its type at that tier, as a unique past its type's top is.
static func roll_set_piece(set_name: String, piece: Dictionary, rng: RandomNumberGenerator, level := -1, tier := -1) -> Dictionary:
	var it := roll(piece["slot"], int(base_named(piece["slot"], piece["base"]).get("tier", Data.CAMPAIGN_TIER)), rng, 0.0, false, false, "", "", 0.33, 0, level)     # at its own base's tier: a deep throwaway would set its level (10 Oct)
	it["base"] = piece["base"]
	it["tier"] = base_of(it)["tier"]
	var lift := set_lift(piece, tier)
	if lift > 1.0:
		it["lift"] = lift
	it["rarity"] = 2
	it["affixes"] = _scaled(piece["affixes"], ilvl(it))
	it["set"] = set_name
	it["piece"] = piece["name"]
	it["value"] = int(round(base_of(it)["value"] * Data.RARITIES[2]["value"] * 1.5))
	return it


## A set piece's lift at a find's tier: the best body of its type there over its own base's figure, never under 1.
static func set_lift(piece: Dictionary, tier: int) -> float:
	var own := base_named(piece["slot"], piece["base"])
	if tier <= int(own.get("tier", 1)) or own.is_empty() or not (Data.SLOT_SCORE[piece["slot"]] in ["dps", "armour", "find"]):
		return 1.0                         # a bag's or a rig's cells don't lift: a grid, not a figure (the review)
	var at := unique_body({"name": "set|" + str(piece["name"]), "slot": piece["slot"], "base": piece["base"]}, tier)
	var was := _base_score(piece["slot"], own)
	if was <= 0.0:
		return 1.0
	return maxf(1.0, _base_score(piece["slot"], base_named(piece["slot"], at["base"])) * float(at["lift"]) / was)


static func set_named(name: String) -> Dictionary:
	for s in Data.SETS:
		if s["name"] == name:
			return s
	return {}


## A unique, rolled: its base, its fixed affixes, its name, its rule. With a range (12 Oct, docs/design/uniques.md) it
## comes at `tier` held inside its range (its own base's tier when none is given), on unique_body's base for that tier;
## a paper has no range and keeps its base.
static var fixed_uniques := false     # the balance read's A/B switch (12 Oct): every unique on its own base, as before the tiers
static func roll_unique(u: Dictionary, rng: RandomNumberGenerator, level := -1, tier := -1, off_head := false) -> Dictionary:
	var body := {"base": u["base"], "tier": int(base_named(u["slot"], u["base"]).get("tier", Data.CAMPAIGN_TIER)), "lift": 1.0}
	var head: bool = off_head and u.get("boss", false)     # a head's own, off him (21 Oct): a tier past the site's loot, lifted
	if u.has("range") and not fixed_uniques:
		var at: int = tier if tier > 0 else int(body["tier"])
		if head:
			# a tier past the site's loot, floored at the unique's own range (29 Oct, the review: the Quartermaster's came off
			# at its base's T6, over the City's T4) and never past the campaign's top on a campaign find
			at = mini(maxi(at + 1, int(u["range"][0])), maxi(at, Data.CAMPAIGN_TIER)) if at <= Data.CAMPAIGN_TIER else maxi(at + 1, int(u["range"][0]))
		body = unique_body(u, unique_tier(u, at)).duplicate()     # a copy: the cache's own stays plain (the review)
	if head:
		body["lift"] = float(body["lift"]) * Data.BOSS_UNIQUE_LIFT
	var it := roll(u["slot"], int(body["tier"]), rng, 0.0, false, false, "", "", 0.33, 0, level)     # at its body's tier: a deep throwaway would set its level (10 Oct)
	it["base"] = body["base"]
	it["tier"] = int(body["tier"])
	if float(body["lift"]) > 1.0:
		it["lift"] = float(body["lift"])
	# the mounts are the body's own (roll() drew them off whatever base it picked); the sockets it rolled stay
	var att := {}
	for name in base_of(it).get("attachments", []):
		att[name] = null
	for k in it["attachments"]:
		if str(k).begins_with("socket"):
			att[k] = null
	it["attachments"] = att
	if level < 0:
		it["ilvl"] = maxi(ilvl(it), int(body["tier"]))
	it["rarity"] = Data.RARITIES.size() - 1
	it["affixes"] = _scaled(u["affixes"], ilvl(it))          # found deep, it carries the depth (7 Oct)
	it["unique"] = u["name"]
	it["rule"] = u["rule"]
	if u.get("mythic", false):
		it["mythic"] = true                   # worn at any level, never lost (docs/design/mythics.md)
	it["value"] = int(round(base_of(it)["value"] * float(body["lift"]) * Data.RARITIES[Data.RARITIES.size() - 1]["value"] * 1.5))
	return it


## A tier held inside a unique's range; a unique without one (a paper) keeps its base's.
static func unique_tier(u: Dictionary, tier: int) -> int:
	if not u.has("range"):
		return int(base_named(u["slot"], u["base"]).get("tier", 1))
	return clampi(tier, int(u["range"][0]), int(u["range"][1]))


## Whether a unique can drop at a find of this tier: inside its range.
static func unique_fits(u: Dictionary, tier: int) -> bool:
	return u.has("range") and tier >= int(u["range"][0]) and tier <= int(u["range"][1])


## The body a scaling unique wears at a tier: the best base of its slot at that tier by the slot's own figure (a gun's
## of its own type; a helmet or armour without a resist built in, so the rule stays the unique's), never the start's,
## a site's own or a paper. Where its type has no base at that tier (a melee secondary stops at the Cosh), the type's
## best below it, lifted by the slot's curve - the best figure of the slot at the tier over the best at the body's.
## {base, tier, lift}.
static var _bodies := {}
static func unique_body(u: Dictionary, tier: int) -> Dictionary:
	var key := "%s|%d" % [u["name"], tier]
	if _bodies.has(key):
		return _bodies[key]
	var own := base_named(u["slot"], u["base"])
	var type: String = str(own.get("type", ""))
	var best := {}
	var best_score := -1.0
	for b in Data.BASES[u["slot"]]:
		if int(b["tier"]) > tier or not _body_fits(u, b, type):
			continue
		var sc := _base_score(u["slot"], b)
		# the best figure at or under the tier, the higher tier on a tie (a T5 Plate rig carries less than the T4 harness:
		# the reviewer's catch - a T5 copy must never be the weaker)
		if best.is_empty() or sc > best_score or (sc == best_score and int(b["tier"]) > int(best["tier"])):
			best = b
			best_score = sc
	if best.is_empty():
		best = own
		best_score = _base_score(u["slot"], own)
	var lift := 1.0
	if int(best["tier"]) < tier and Data.SLOT_SCORE[u["slot"]] == "dps":
		# its own type's next base up, when there is one: the lift goes part way to it (a T5 pistol between the T4 and
		# the T6, never past the T6 - the reviewer's catch); past the type's top, the slot's curve
		var next := {}
		for b in Data.BASES[u["slot"]]:
			if int(b["tier"]) > tier and _body_fits(u, b, type) and (next.is_empty() or int(b["tier"]) < int(next["tier"]) or (int(b["tier"]) == int(next["tier"]) and _base_score(u["slot"], b) > _base_score(u["slot"], next))):
				next = b
		if not next.is_empty() and best_score > 0.0:
			var span := float(int(next["tier"]) - int(best["tier"]))
			lift = pow(_base_score(u["slot"], next) / best_score, float(tier - int(best["tier"])) / span)
		else:
			var at := _slot_curve(u["slot"], tier)
			var was := _slot_curve(u["slot"], int(best["tier"]))
			if was > 0.0 and at > was:
				lift = at / was
	lift = maxf(1.0, lift)
	var out := {"base": best["name"], "tier": maxi(tier, int(best["tier"])), "lift": lift}     # the copy's tier is the tier it came at
	_bodies[key] = out
	return out


## A base a unique can wear: _body_ok, its own gun type, and its `body` hint (12 Oct, the pass's list): a family the
## rule wants kept - Nan's Cardigan light (no pace lost: its rule takes the armour anyway), the Butcher's Steel a
## blade that bleeds (a quarter or more of the hit).
static func _body_fits(u: Dictionary, b: Dictionary, type: String) -> bool:
	if not _body_ok(b) or str(b.get("type", "")) != type:
		return false
	var hint: Dictionary = u.get("body", {})
	if hint.has("pace_min") and float(b.get("pace", 0)) < float(hint["pace_min"]):
		return false
	if hint.has("bleed_min") and float(b.get("conv_bleed_pct", 0)) < float(hint["bleed_min"]):
		return false
	return true


static func _body_ok(b: Dictionary) -> bool:
	return not b.get("start", false) and not b.has("res") and int(b.get("depth", 0)) == 0


static func _base_score(slot: String, b: Dictionary) -> float:
	return score({"slot": slot, "base": b["name"], "affixes": [], "attachments": {}, "tier": b["tier"]})


## The best plain figure of a slot at or below a tier (the lift's curve).
static func _slot_curve(slot: String, tier: int) -> float:
	var top := 0.0
	for b in Data.BASES[slot]:
		if int(b["tier"]) <= tier and _body_ok(b):
			top = maxf(top, _base_score(slot, b))
	return top


## A base's built-in figure for a stat (29 Oct, the itemisation's roles): the gloves' grip or rate of fire, a visor's
## quicker searches, a specialist rig's Guard, a charm's element - read beside the affixes (Sim._affix_index), never an
## affix itself, so a Blue Plaque leaves it standing.
static func base_stat(it: Dictionary, stat: String) -> float:
	return float(base_of(it).get("stats", {}).get(stat, 0.0))


## A stat as worn on a piece: its base's built-in figure and its affixes'.
static func stat_total(it: Dictionary, stat: String) -> float:
	return base_stat(it, stat) + affix_total(it, stat)


## A worn base's role (29 Oct, §2): heavy, light or specialist; a pair of gloves' grip, pace or rate. "" for the rest.
static func role(it: Dictionary) -> String:
	return str(base_of(it).get("role", ""))


## A pair of gloves' figures as worn: quicker reloads, pace and rate of fire, each base and affixes.
static func glove_figs(it: Dictionary) -> Dictionary:
	return {"reload_pct": stat_total(it, "reload_pct"), "pace": base_pace(it) + affix_total(it, "speed_pct"), "attack_pct": stat_total(it, "attack_pct")}


## The gloves' one figure, their role's (29 Oct: the headline, the card, the pick panel): [figure, words].
## A pair of gloves' unit short, for a cell or a card with no room for the long (the fix round, 29 Oct, the UI review's B4):
## "reload", "RoF", "pace" - the deltas' own.
static func glove_unit_short(it: Dictionary) -> String:
	return {"pace": "pace", "rate": "RoF"}.get(role(it), "reload")


static func glove_headline(it: Dictionary) -> Array:
	var f := glove_figs(it)
	match role(it):
		"pace":
			return ["+%d%%" % int(round(f["pace"])), "pace"]
		"rate":
			return ["+%d%%" % int(round(f["attack_pct"])), "rate of fire"]
	return ["+%d%%" % int(round(f["reload_pct"])), "quicker reloads"]


## The gun type's edge as one line under the item's figure (29 Oct, §3; the style guide's mechanics voice, the number
## first): "" for a gun that has none in its slot (an SMG or a blade carried second) and anything that isn't a gun.
static func edge_words(it: Dictionary) -> String:
	var f: Array = edge_forms(it)
	return str(f[0]) if not f.is_empty() else ""


## The edge's line, long to short (the fix round, 29 Oct, the language reviews: the rule said, the number first; the rifle's
## middle form keeps both its halves for a head): [] for a gun with none (a secondary's SMG, rifle or shotgun).
static func edge_forms(it: Dictionary) -> Array:
	if not is_gun(it):
		return []
	var ty: String = str(base_of(it).get("type", ""))
	var primary: bool = str(it.get("slot", "")) == "Primary"
	if ty == "improvised":
		var n: int = int(Data.EDGE["improvised"]["sockets"])
		return ["%d more socket%s than other guns" % [n, "" if n == 1 else "s"], "+%d socket%s" % [n, "" if n == 1 else "s"]]
	if ty == "pistol":
		return ["Full rate of fire while the primary reloads", "Fires on through reloads"]
	if ty == "melee":
		if not primary:
			return ["Never runs dry"]
		var mx: int = int(round(float(Data.EDGE["melee"]["x"]) * 100.0))
		var on: int = int(Data.EDGE["melee"]["on_you"])
		return ["Never runs dry · +%d%% damage with %d or more on you" % [mx, on], "+%d%% with %d+ on you" % [mx, on]]
	if not primary:
		return []
	match ty:
		"rifle":
			var pc: int = int(round(float(Data.EDGE["rifle"]["pierce"]) * 100.0))
			var op: int = int(round(float(Data.EDGE["rifle"]["opener"]) * 100.0))
			return ["%d%% of armour ignored · +%d%% damage with the first round at each man" % [pc, op], "%d%% armour ignored · +%d%% first round" % [pc, op]]     # both halves even short (the UI review's B5)
		"shotgun":
			var sx: int = int(round(float(Data.EDGE["shotgun"]["x"]) * 100.0))
			return ["%d%% of each blast carries to the man behind" % sx, "%d%% carries to the man behind" % sx]
		"smg":
			var su: Array = base_of(it).get("sustain", [0, 0])
			if int(su[0]) <= 0:
				return []
			return ["+%d%% damage for each second on the same gang, to +%d%%" % [int(su[0]), int(su[1])], "+%d%%/s on one gang, to +%d%%" % [int(su[0]), int(su[1])]]
	return []


## The edge's line short, for a row with no room (29 Oct).
static func edge_short(it: Dictionary) -> String:
	var f: Array = edge_forms(it)
	return str(f[-1]) if not f.is_empty() else ""


## A base's own pace, as a percent (weight: a riot suit slows, leathers don't).
static func base_pace(it: Dictionary) -> float:
	return float(base_of(it).get("pace", 0))


## A gun's type word for a line: "rifle", "SMG"; "" for anything that isn't a gun.
static func type_word(it: Dictionary) -> String:
	var t: String = base_of(it).get("type", "")
	return "SMG" if t == "smg" else t


## A gun's damage a second as fitted, before the operator's own multipliers.
static func dps(it: Dictionary) -> float:
	var b := base_of(it)
	if not b.has("damage") or not b.has("rof"):
		return 0.0
	return b["damage"] * b["rof"] * (1.0 + fitted_sum(it, "damage_pct") / 100.0) * float(it.get("lift", 1.0)) * grow(ilvl(it))     # a unique past its type's top base: lifted (12 Oct); past the deep tier, its level's (21 Oct)


static func armour(it: Dictionary) -> float:
	return base_of(it).get("armour", 0.0) * float(it.get("lift", 1.0)) * grow(ilvl(it)) + affix_total(it, "armour")     # a set piece's lift; past the deep tier, its level's (21 Oct)


## A med's healing, and the seconds it takes.
static func heal(it: Dictionary) -> float:
	return base_of(it).get("heal", 0.0) * (1.0 + affix_total(it, "heal_pct") / 100.0)


static func use_time(it: Dictionary) -> float:
	return float(base_of(it).get("use", 0.0)) * maxf(0.3, 1.0 - affix_total(it, "med_fast_pct") / 100.0)     # its own Quicker to use (28 Oct)


## A gun's magazine (28 Oct): its base's own "mag", else its rounds' type's MAG_SIZE; 0 for a gun that has none
## (a bat, a free-round gun).
static func mag_size(gun: Dictionary) -> int:
	var t := ammo_type(gun)
	if t in ["", "none"] or free_rounds(gun):
		return 0
	return int(base_of(gun).get("mag", Data.MAG_SIZE.get(t, 0)))


## A gun's reload before the runner's speed: its base's "reload", else its type's RELOAD_S.
static func reload_base(gun: Dictionary) -> float:
	return float(base_of(gun).get("reload", Data.RELOAD_S.get(ammo_type(gun), 2.0)))


## The rounds a rig pouch holds of a type: MAG_POUCH magazines of its MAG_SIZE.
static func pouch_cap_of(type: String) -> int:
	return Data.MAG_POUCH * int(Data.MAG_SIZE.get(type, 30))


static func pouch_cap(it: Dictionary) -> int:
	return Data.MAG_POUCH * box_mag(it)


## A box's magazine: its base's own "mag" (Belt links' belt, 28 Oct, the review), else its type's MAG_SIZE.
static func box_mag(it: Dictionary) -> int:
	var b: Dictionary = base_of(it)
	return int(b.get("mag", Data.MAG_SIZE.get(str(b.get("type", "")), 30)))


## A rig pouch's magazines as the cell draws them (28 Oct): MAG_POUCH, each its share loaded, the full ones first.
static func pouch_fills(it: Dictionary) -> Array:
	var mag: float = float(box_mag(it))
	var loaded: float = float(it.get("rounds", 0)) / mag
	var out: Array = []
	for k in range(Data.MAG_POUCH):
		out.append(clampf(loaded - k, 0.0, 1.0))
	return out


## A pouch's magazines in words: "3 mags", "2 mags + 12".
static func pouch_words(it: Dictionary) -> String:
	var mag: int = box_mag(it)
	var r: int = int(it.get("rounds", 0))
	@warning_ignore("integer_division")
	var full: int = r / mag
	var part: int = r - full * mag
	var head: String = "%d mag%s" % [full, "" if full == 1 else "s"]
	return head if part == 0 else ("%s + %d" % [head, part] if full > 0 else "%d rounds" % part)


static func is_medical(it: Dictionary) -> bool:
	return it["slot"] == Data.MEDICAL


## A cure (28 Oct): a med that stops an element on you instead of healing. "" for a heal or anything else.
static func cure_of(it: Dictionary) -> String:
	if it.get("slot", "") != Data.MEDICAL:
		return ""
	return str(base_of(it).get("cure", ""))


static func is_cure(it: Dictionary) -> bool:
	return cure_of(it) != ""


## A med that heals: every med but a cure.
static func is_heal(it: Dictionary) -> bool:
	return is_medical(it) and not is_cure(it)


static func is_paper(it: Dictionary) -> bool:
	return it["slot"] == Data.PAPER


## The room a head's own thing opens ("" for anything else): the vet's bag the clinic, the deeds the yard (13 Oct).
static func opens(it: Dictionary) -> String:
	if it.get("slot", "") != Data.PAPER:
		return ""
	for b in Data.BOSSES:
		var o: Dictionary = b.get("opens", {})
		for room in o:
			if str(o[room]) == str(it["base"]):
				return str(room)
	return ""


static func is_deeds(it: Dictionary) -> bool:
	return it["slot"] == Data.PAPER and it["base"] == "The deeds"


static func is_ammo(it: Dictionary) -> bool:
	return it["slot"] == Data.AMMO


static func is_grenade(it: Dictionary) -> bool:
	return it["slot"] == Data.GRENADE


## Medical supplies (28 Oct): a stack for the Clinic.
static func is_supplies(it: Dictionary) -> bool:
	return it.get("slot", "") == Data.SUPPLIES


## What goes in the rig's pouches: meds, rounds, grenades.
static func rig_item(it: Dictionary) -> bool:
	return is_medical(it) or is_ammo(it) or is_grenade(it)


## The ammo type a gun fires, "" for anything that isn't a gun.
static func ammo_type(gun: Dictionary) -> String:
	if gun.get("nails", false):
		return "improvised"               # built at the Bench (34): fires nails whatever it is
	var b := base_of(gun)
	return str(b.get("ammo", b.get("type", "")))


static func is_melee(it: Dictionary) -> bool:
	return base_of(it).get("type", "") == "melee"


## A gun that never spends a round: the Council's Weed Burner, the Spare Key (18 Oct, Matt on Q5: its own thing, not
## Double tap's again).
static func free_rounds(gun: Dictionary) -> bool:
	return str(gun.get("rule", "")) in ["spare_key"]     # the Weed Burner takes shells now (25 Oct, the review: no rounds and all fire and a spread was three rules)


## What a gun takes, by the standard box of its type: "Takes shells"; a bat, nothing.
static func ammo_words(gun: Dictionary) -> String:
	var type := ammo_type(gun)
	if type == "none" or free_rounds(gun):
		return "Takes no rounds"
	if type == "" or not is_gun(gun):
		return ""
	for b in Data.BASES[Data.AMMO]:
		if b["type"] == type and int(b["tier"]) == 1:
			return "Takes %s" % str(b["name"]).to_lower()
	return ""


static func capacity(it: Dictionary) -> int:
	return int(base_of(it).get("capacity", 0)) + int(affix_total(it, "capacity"))


static func affix_total(it: Dictionary, stat: String) -> float:
	var t := 0.0
	for a in it["affixes"]:
		if a["stat"] == stat:
			t += a["value"]
	return t


## What the Armoury compares two items of a slot by.
static func score(it: Dictionary) -> float:
	match Data.SLOT_SCORE[it["slot"]]:
		"dps":
			return dps(it) * (1.0 + affix_total(it, "damage_pct") / 100.0)
		"armour":
			return armour(it) + affix_total(it, "hp") * 0.5
		"capacity":
			return capacity(it) + affix_total(it, "loot_pct") * 0.1
		"heal":
			return heal(it)
		"throw":
			return float(base_of(it).get("damage", 0.0))
		"rounds":
			return float(it.get("rounds", 0)) * (1.0 + float(base_of(it).get("damage_pct", 0)) / 100.0)
		"attach":
			if is_socketable(it):
				return att_stat(it, "conv_fire_pct") + att_stat(it, "conv_frost_pct") + att_stat(it, "conv_poison_pct") + att_stat(it, "conv_shock_pct") + att_stat(it, "salt") + att_stat(it, "wire_pct")
			return att_stat(it, "damage_pct") + att_stat(it, "first_pct") / 3.0 + att_stat(it, "speed_pct") + att_stat(it, "patrol_pct") / 4.0
		"find":
			return find(it) + cash_pct(it) * 0.5
		"grip":
			var f := glove_figs(it)     # the gloves' job (29 Oct): rate of fire and pace a point each, a reload's what the fight
			return float(f["attack_pct"]) + float(f["pace"]) + float(f["reload_pct"]) * GRIP_RELOAD_W     # pays for one (the fix round)
	return 0.0


## A charm's magic find and cash, base plus affixes.
static func find(it: Dictionary) -> float:
	return float(base_of(it).get("find", 0)) * float(it.get("lift", 1.0)) + affix_total(it, "rarity_pct")     # a set charm's lift (21 Oct)


static func cash_pct(it: Dictionary) -> float:
	return float(base_of(it).get("cash", 0)) * float(it.get("lift", 1.0)) + affix_total(it, "cash_pct")


static func is_charm(it: Dictionary) -> bool:
	return it["slot"] == Data.CHARM


static func is_socketable(it: Dictionary) -> bool:
	return it["slot"] == Data.ATTACHMENT and it.get("mount", "") == "socket"


## How many sockets an item has, and how many are filled.
static func sockets(it: Dictionary) -> int:
	var n := 0
	for mount in it.get("attachments", {}):
		if str(mount).begins_with("socket"):
			n += 1
	return n


## One line per affix for a card: "+8% damage"; `short` for "+8% dmg".
static func affix_lines(it: Dictionary, short := false, tiers := false) -> Array:
	var out: Array = []
	for a in it["affixes"]:
		var d := affix_def(a["stat"])
		var label: String = str(d.get("short" if short else "label", a["stat"]))
		var pct: bool = a["stat"].ends_with("_pct") or a["stat"] in ["loot_per_lot", "guard_gang"]     # guard_gang is a share of max HP (18 Oct)
		var line: String
		if label == "pouch" and int(a["value"]) != 1:
			label = "pouches"                    # "+1 pouch", "+2 pouches" (18 Oct)
		var plus: String = "" if a["stat"] in ["crowd_less_pct", "cdr_pct"] else "+"     # "8% less damage with three or more on you", "8% shorter cooldowns"
		line = "%s%s%s %s" % [plus, fig(str(a["stat"]), float(a["value"])), "%" if pct else "", label]
		if d.get("flag", false):
			line = label                         # on or off, no figure: a med's cure built in (28 Oct)
		if tiers and a.has("tier"):
			line += " · T%d" % int(a["tier"])
		out.append(line)
	return out


## An item's figure line, long to short, for UI.fit: "17 dmg/s · Common T1
## improvised · 3 cells" down to "17 dmg/s · T1". `tail` is appended to each.
## What kind of thing it is, for the card: the slot it fills, and the type
## where the slot has them - "Primary · rifle", "Secondary · melee", "Helmet",
## "Rounds · shotgun", "Gun part · optic", "Socketable", "Paper", "Charm", "Med".
## The mounts a bat or a blade has, not a gun: a part for one says so.
## A quicker-reload point against a rate-of-fire one in the gloves' score (the fix round, 29 Oct, the review's B3): a
## gun fires about 85% of the time, so 1% off a reload is about 0.15% more firing.
const GRIP_RELOAD_W := 0.15

const MELEE_MOUNTS := ["grip", "business end"]


static func is_melee_mount(mount: String) -> bool:
	return mount in MELEE_MOUNTS


## What a part fits, as a player reads it: "a gun's optic", "a bat's head".
static func mount_words(mount: String) -> String:
	return ("a bat's %s" if is_melee_mount(mount) else "a gun's %s") % mount


## The mount as a line's first word: "Optic", "Business end".
static func mount_name(mount: String) -> String:
	return mount.left(1).to_upper() + mount.substr(1)


static func kind_words(it: Dictionary) -> String:
	var slot: String = it["slot"]
	if slot == Data.ATTACHMENT:
		if is_socketable(it):
			return "Socketable"
		var mount: String = it.get("mount", "")
		return ("Melee part · %s" if is_melee_mount(mount) else "Gun part · %s") % mount
	if slot == Data.AMMO:
		return "Rounds · %s" % base_of(it).get("type", "")
	if slot == Data.MEDICAL:
		return "Cure" if is_cure(it) else "Med"
	if slot == Data.SUPPLIES:
		return "Supplies"
	if slot == Data.PAPER:
		return "Paper"
	if is_melee(it):
		return "%s · melee" % slot
	var tw := type_word(it)
	return ("%s · %s" % [slot, tw]) if tw != "" else slot


static func figure_options(it: Dictionary, tail := "") -> Array:
	var h := headline(it)
	var tw := type_word(it)
	var unit: String = "dmg/s" if (tw != "" and is_gun(it)) else h[1]
	var cells := "%d cell%s" % [size(it), "" if size(it) == 1 else "s"]
	var t := (" · " + tail) if tail != "" else ""
	var kind := kind_words(it)
	var short_kind: String = kind.get_slice(" · ", 0)
	return [
		"%s · %s %s · %s T%d · %s%s" % [kind, h[0], unit, rarity_name(it), it["tier"], cells, t],
		"%s · %s %s · %s T%d%s" % [kind, h[0], unit, rarity_name(it), it["tier"], t],
		"%s · %s %s · T%d%s" % [kind, h[0], unit, it["tier"], t],
		"%s · %s %s · T%d%s" % [short_kind, h[0], unit, it["tier"], t],
		"%s · %s %s%s" % [short_kind, h[0], unit, t],
	]


## The tier of the k-th affix (1 when it has none recorded), for its colour band.
static func affix_tier(it: Dictionary, k: int) -> int:
	if k >= it["affixes"].size():
		return 1
	return int(it["affixes"][k].get("tier", 1))


## An item's affix line, long to short: every affix in words, then the short
## words, then a count.
## A base's built-in resists as words: "fire res 35", "fire res 20 · shock res 20"; "" for none.
static func base_res_words(it: Dictionary) -> String:
	var out := []
	var res: Dictionary = base_of(it).get("res", {})
	for ty in Data.ELEMENTS:
		if res.has(ty):
			out.append("%s resist %d%%" % [ty, int(res[ty])])
	# a worn base's role figure (29 Oct): its pace and its built-in line, the number first - what the base gives before any
	# affix; a pair of gloves' headline figure isn't said twice. A gun's edge is its own line (edge_words), walking fire too
	if not is_gun(it):
		var head: String = str(glove_headline(it)[1]) if str(it.get("slot", "")) == Data.GLOVES else ""
		if base_pace(it) != 0.0 and head != "pace":
			out.append("%s%d%% pace" % ["+" if base_pace(it) > 0.0 else "−", int(absf(base_pace(it)))])
		var st: Dictionary = base_of(it).get("stats", {})
		for k in st:
			var d := affix_def(str(k))
			if str(d.get("label", "")) == head:
				continue
			out.append("%s%s%% %s" % ["" if k == "guard_gang" else "+", fig(str(k), float(st[k])), str(d.get("label", k))])
	return " · ".join(out)


static func affix_options(it: Dictionary) -> Array:
	if it["affixes"].is_empty():
		return ["No affixes"]
	var n: int = it["affixes"].size()
	return [", ".join(affix_lines(it)), ", ".join(affix_lines(it, true)), "%d affix%s" % [n, "" if n == 1 else "es"]]


## The headline figure and its unit for a card.
static func headline(it: Dictionary) -> Array:
	var b := base_of(it)
	if it["slot"] == Data.GRENADE:
		return ["%.0f" % b["damage"], "%s to everyone on you" % b["type"]]
	if b.has("cure"):
		return ["Stops", str(b["cure"])]              # a cure (28 Oct): what it stops
	if it["slot"] == Data.SUPPLIES:
		return ["×%d" % int(it.get("count", 1)), "for the Clinic"]
	if b.has("damage"):
		return ["%.0f" % dps(it), "dmg/s"]     # the style guide's form (25 Oct, the review)
	if b.has("armour"):
		return ["%.0f" % armour(it), "armour"]
	if b.has("heal"):
		return ["%.0f" % heal(it), "HP in %.0f s" % use_time(it)]
	if b.has("rounds"):
		return ["%d" % int(it.get("rounds", 0)), "rounds" + ((", +%d%%" % int(b["damage_pct"])) if b.has("damage_pct") else "") + grade_words(b)]

	if b.has("mount"):
		var lead := att_lead(it)
		return [lead[0], lead[1]]
	if it["slot"] == Data.PAPER:
		return ["Paper", ""]                    # its worth is nothing to say (16 Oct, Matt): the item head says what it is, with the sim
	if it["slot"] == Data.CHARM:
		return ["+%.0f%%" % find(it), "loot quality"]
	if it["slot"] == Data.GLOVES:
		return glove_headline(it)
	return ["%d" % capacity(it), "capacity"]


## A grade's element or crit, as words after its damage: ", 20% as bleed", ", first shot +25%".
static func grade_words(b: Dictionary) -> String:
	for ty in Data.ELEMENTS:
		if b.has("conv_%s_pct" % ty):
			return ", %d%% as %s" % [int(b["conv_%s_pct" % ty]), ty]
	if b.has("first_pct"):
		return ", +%d%% damage to each gang's first" % int(b["first_pct"])
	return ""


## An attachment's headline: its biggest effect.
static func att_lead(it: Dictionary) -> Array:
	var best := ["", ""]
	var sz := 0.0
	for pair in [["damage_pct", "% damage"], ["first_pct", "% damage to each gang's first"], ["speed_pct", "% pace"], ["patrol_pct", "% later gangs"],
			["conv_fire_pct", "% of hits as fire"], ["conv_frost_pct", "% of hits as frost"], ["conv_poison_pct", "% of hits as poison"], ["conv_shock_pct", "% of hits as shock"], ["conv_bleed_pct", "% of hits as bleed"], ["salt", " armour"], ["wire_pct", "% tins"]]:
		var v := att_stat(it, pair[0])
		if absf(v) > sz:
			sz = absf(v)
			var sgn: String = "+" if v > 0 else "−"
			if pair[0].begins_with("conv_"):
				sgn = ""                     # "15% of hits as fire" is a share, not a bonus
			best = ["%s%.0f%s" % [sgn, absf(v), "%" if pair[1].begins_with("%") else ""], pair[1].trim_prefix("%").strip_edges()]
	return best


## Every effect an attachment carries, as short words: "+9% dmg, −4% pace".
## `base_only`: the part's own figures, its rolled affixes left for their own lines.
static func att_words(it: Dictionary, short := false, base_only := false) -> String:
	var out := []
	for pair in [["damage_pct", "dmg", "dmg"], ["first_pct", "damage to the first of each gang", "first"], ["speed_pct", "pace", "pace"], ["patrol_pct", "later gangs", "delay"],
			["conv_fire_pct", "of hits as fire: they burn", "as fire"], ["conv_frost_pct", "of hits as frost: they're chilled", "as frost"], ["conv_poison_pct", "of hits as poison: it lingers", "as poison"], ["conv_shock_pct", "of hits as shock: they take more damage", "as shock"], ["conv_bleed_pct", "of hits as bleed: they keep bleeding", "as bleed"], ["salt", "armour", "armour"], ["wire_pct", "tins from every kill", "tins"]]:
		var v: float = float(base_of(it).get(pair[0], 0)) if base_only else att_stat(it, pair[0])
		if absf(v) >= 0.5:
			var sgn: String = "" if pair[0].begins_with("conv_") else ("+" if v > 0 else "−")
			out.append("%s%.0f%s %s" % [sgn, absf(v), "" if pair[0] == "salt" else "%", pair[2] if short else pair[1]])
	return ", ".join(out)


## What a socketable is, in a line: where it goes and what it does there.
static func socket_words(it: Dictionary) -> String:
	var b := base_of(it)
	if b.has("salt"):
		return "A socketable: in any socket, +%d armour" % int(b["salt"])
	if b.has("wire_pct"):
		return "A socketable: in any socket, +%d%% tins from every kill" % int(b["wire_pct"])
	for ty in ["fire", "frost", "poison", "shock"]:
		if b.has("conv_%s_pct" % ty):
			return "A socketable: in any socket, %d%% of your hits land as %s" % [int(b["conv_%s_pct" % ty]), ty]
	return "A socketable: goes in a socket in the Workshop"


## Stacks: how many a stack of this can hold, and how many it holds.
static func stack_cap(it: Dictionary) -> int:
	if is_ammo(it):
		return int(base_of(it)["rounds"]) * Data.STACK_BOXES
	if is_socketable(it):
		return Data.SOCKET_STACK
	if is_supplies(it):
		return Data.SUPPLY_STACK
	return 1


static func stack_size(it: Dictionary) -> int:
	if is_ammo(it):
		return int(it.get("rounds", 0))
	if is_socketable(it) or is_supplies(it):
		return int(it.get("count", 1))
	return 1


static func stacks(it: Dictionary) -> bool:
	return is_ammo(it) or is_supplies(it) or (is_socketable(it) and it.get("affixes", []).is_empty())


## Two stacks that can merge: the same base, both plain.
static func same_stack(a: Dictionary, b: Dictionary) -> bool:
	return stacks(a) and stacks(b) and a["base"] == b["base"] and a["slot"] == b["slot"]


## Put n of a stack's rounds or count into another; the stack's value follows what it holds.
static func set_stack(it: Dictionary, n: int) -> void:
	var b := base_of(it)
	if is_ammo(it):
		it["rounds"] = n
		it["value"] = int(round(float(b["value"]) * n / float(b["rounds"])))
	elif is_socketable(it) or is_supplies(it):
		it["count"] = n
		it["value"] = int(b["value"]) * n


## A copy of one off a stack (a socketable going into a socket).
static func one_of(it: Dictionary) -> Dictionary:
	var one := it.duplicate(true)
	one["id"] = _next_id
	_next_id += 1
	set_stack(one, 1)
	return one


## What a paper in the stash is for now (10 Oct): a rule paper works from the stash, keep it; a read one is spent,
## its word kept by the Radio, safe to sell. The Lock-up and the Fence both say it; "" for the deeds or one unread.
static func paper_keep(it: Dictionary, book: Array) -> String:
	if not is_paper(it) or is_deeds(it) or not (it["base"] in book):
		return ""
	if str(it.get("rule", "")) != "":
		return "Works from the stash: keep it"
	return "Read: the Radio keeps the code"


# ------------------------------------------------------------------ the expeditions' hands (29 Oct, docs/design/trips.md 3)

## A hired hand, rolled as a piece of gear is (Matt: "hands come in the gear's tiers with affixes"): the trade its base,
## a tier, a rarity from the gear's table (Legendary at most), one affix a rarity step from the expeditions' own pool,
## each at a tier the rarity caps - the same roll_affix as a drop. `trade` "" for one at random; `place_keys` the far
## places an affix can name. Saved as an item: {id, slot "Hand", base, trade, rarity, tier, ilvl, affixes, lv, xp, look}.
static func roll_hand(tier: int, rng: RandomNumberGenerator, rarity_bonus := 0.0, no_commons := false, trade := "", place_keys: Array = []) -> Dictionary:
	var trades: Array = Data.HAND_TRADES
	var t: Dictionary = trades[rng.randi_range(0, trades.size() - 1)]
	for td in trades:
		if str(td["trade"]) == trade:
			t = td
	var r := mini(_roll_rarity(rng, rarity_bonus), Data.HAND_RARITY_MAX)
	if no_commons and r == 0:
		r = 1
	var tv: int = clampi(tier, 1, Data.MAX_TIER)
	var affixes: Array = []
	var pool: Array = Data.HAND_AFFIXES.duplicate()
	while affixes.size() < mini(r + 1, Data.HAND_AFFIX_MAX) and not pool.is_empty():
		var total := 0.0
		for a in pool:
			total += float(a.get("weight", 1.0))
		var x := rng.randf() * total
		var pick := 0
		for k in range(pool.size()):
			x -= float(pool[k].get("weight", 1.0))
			if x <= 0.0:
				pick = k
				break
		var a: Dictionary = pool[pick]
		pool.remove_at(pick)
		if bool(a.get("place", false)) and place_keys.is_empty():
			continue
		var af := roll_affix(a, tv, rng, 0, int(Data.RARITIES[r]["tier"]))
		if bool(a.get("place", false)):
			af["place"] = str(place_keys[rng.randi_range(0, place_keys.size() - 1)])
		affixes.append(af)
	var it := {"id": _next_id, "slot": Data.HAND_SLOT, "base": t["name"], "trade": t["trade"], "rarity": r, "tier": tv, "ilvl": tv,
		"affixes": affixes, "attachments": {}, "value": 0, "lv": 1, "xp": 0, "look": hand_look(r)}
	_next_id += 1
	return it


static func is_hand(it: Dictionary) -> bool:
	return str(it.get("slot", "")) == Data.HAND_SLOT


## A hand's face of the three its trade has, by rarity: Common and Uncommon, Rare and Epic, Legendary.
static func hand_look(r: int) -> int:
	return 0 if r <= 1 else (1 if r <= 3 else 2)


static func hand_trade(it: Dictionary) -> Dictionary:
	for t in Data.HAND_TRADES:
		if str(t["trade"]) == str(it.get("trade", "")):
			return t
	return {}


static func hand_affix_def(stat: String) -> Dictionary:
	for a in Data.HAND_AFFIXES:
		if str(a["stat"]) == stat:
			return a
	return {}


## A level's rise on a hand's figures: HAND_LV_GROW a level past the first.
static func hand_grow(it: Dictionary) -> float:
	return 1.0 + Data.HAND_LV_GROW * (clampi(int(it.get("lv", 1)), 1, Data.HAND_LV_MAX) - 1)


## The trade's figure: its `fig` a tier to its cap, the level's rise on it (the cargo and the crates are counts: the
## quartermaster's second slot from tier 5, the cracker's crate a three tiers).
static func hand_fig(it: Dictionary) -> int:
	var t := hand_trade(it)
	if t.is_empty():
		return 0
	var tier: int = int(it.get("tier", 1))
	match str(t["stat"]):
		"cargo":
			return 2 if tier >= 5 else 1
		"crates":
			return mini(int(t["cap"]), 1 + int(floor(tier / 3.0)))
	return mini(int(t["cap"]), int(round(float(t["fig"]) * tier * hand_grow(it))))


## An affix's figure as it stands: its roll, the hand's level's rise on it (a count or a flag doesn't rise).
static func hand_affix_value(it: Dictionary, a: Dictionary) -> int:
	var d := hand_affix_def(str(a["stat"]))
	if bool(d.get("flag", false)) or int(d.get("max", 1)) <= 1:
		return int(a["value"])
	return int(round(float(a["value"]) * hand_grow(it)))


## The trade's line, the number first (a chip): "+15% finds", "−24% time", "+1 cargo slot".
static func hand_trade_line(it: Dictionary) -> String:
	var f := hand_fig(it)
	match str(hand_trade(it).get("stat", "")):
		"finds":
			return "+%d%% finds" % f
		"bail":
			return "−%d%% lost on a bad roll" % f
		"odds":
			return "+%d%% odds" % f
		"crates":
			return "+%d crate%s" % [f, "" if f == 1 else "s"]
		"time":
			return "−%d%% time" % f
		"cargo":
			return "+%d cargo slot%s" % [f, "" if f == 1 else "s"]
	return ""


## The trade's line, shorter for a small cell.
static func hand_trade_short(it: Dictionary) -> String:
	var f := hand_fig(it)
	match str(hand_trade(it).get("stat", "")):
		"bail":
			return "−%d%% lost" % f
		"cargo":
			return "+%d cargo" % f
		"crates":
			return "+%d crate%s" % [f, "" if f == 1 else "s"]
	return hand_trade_line(it)


## The affixes' lines, the number first: "+8% odds", "−10% risk", "+1 cargo slot", "+15% from Liverpool",
## "Never held up in London". `short`: the far place's short name; `tight` the smallest cell's ("+30% Brum", "Safe:
## the Plain"). `tiers`: " · T3" after each.
static func hand_lines(it: Dictionary, short := true, tiers := false, tight := false) -> Array:
	var out: Array = []
	for a in it.get("affixes", []):
		var d := hand_affix_def(str(a["stat"]))
		var place := ""
		if a.has("place"):
			for p in Data.EXP_PLACES:
				if str(p["key"]) == str(a["place"]):
					place = str(p["tag"] if tight else (p["short"] if short else p["name"]))
		var label: String = str(d.get("tight" if tight and d.has("tight") else "short", a["stat"]))
		if label.contains("%s"):
			label = label % place
		var v: int = hand_affix_value(it, a)
		var line: String
		if bool(d.get("flag", false)):
			line = label.left(1).to_upper() + label.substr(1)     # sentence case: "Never held up in London"
		elif bool(d.get("pct", false)):
			line = "%s%d%% %s" % ["−" if bool(d.get("less", false)) else "+", v, label]
		else:
			line = "+%d %s%s" % [v, label, "" if v == 1 else "s"]
		if tiers and a.has("tier"):
			line += " · T%d" % int(a["tier"])
		out.append(line)
	return out


## A hand's sum of one affix stat (a far place's own only for that place): its rolls with the level's rise.
static func hand_affix_sum(it: Dictionary, stat: String, place_key := "") -> int:
	var v := 0
	for a in it.get("affixes", []):
		if str(a["stat"]) != stat:
			continue
		if a.has("place") and str(a["place"]) != place_key:
			continue
		v += hand_affix_value(it, a)
	return v
