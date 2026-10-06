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
		site := "", prefer := "", own_share := 0.33, depth := 0) -> Dictionary:
	# the site's own: a base found only there drops only there, and a third of
	# the time the roll is one of them; a site that leans to a gun type leans
	var pool: Array = []
	var own: Array = []
	for b in (Data.ATTACHMENTS if slot == Data.ATTACHMENT else Data.BASES[slot]):
		if b["tier"] > max_tier:
			continue
		if int(b.get("depth", 0)) > depth:
			continue                          # a deep paper: only past its depth
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
	# the item's level: its base's tier and the depth it dropped at; it sets the tiers its affixes can roll
	var ilvl: int = int(base["tier"]) + maxi(0, depth)
	var affixes: Array = []
	var picked := pick_affixes(slot, int(Data.RARITIES[r]["affixes"]), rng)
	for a in picked:
		affixes.append(roll_affix(a, ilvl, rng))
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
		for k in range(n):
			attachments["socket %d" % (k + 1)] = null
	if slot == Data.AMMO or slot == Data.PAPER or (slot == Data.ATTACHMENT and base.get("mount", "") == "socket"):
		r = 0                             # a box is a box; a letter is a letter; a bottle is a bottle, so they stack
		affixes = []
	var it := {
		"id": _next_id, "slot": slot, "base": base["name"], "rarity": r, "affixes": affixes,
		"attachments": attachments, "tier": base["tier"], "ilvl": ilvl,
		"value": int(round(base["value"] * Data.RARITIES[r]["value"])),
	}
	if slot == Data.AMMO:
		it["rounds"] = int(base["rounds"])
	if slot == Data.ATTACHMENT:
		it["mount"] = base["mount"]
		if base["mount"] == "socket":
			it["count"] = 1
	_next_id += 1
	return it


## Rarity weights, shifted toward the rare end by loot find.
static func _roll_rarity(rng: RandomNumberGenerator, bonus: float) -> int:
	var weights: Array = []
	var total := 0.0
	for i in range(Data.RARITIES.size()):
		var w: float = Data.RARITIES[i]["weight"]
		if i > 0:
			w *= 1.0 + bonus
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
static func base_of(it: Dictionary) -> Dictionary:
	for b in (Data.ATTACHMENTS if it["slot"] == Data.ATTACHMENT else Data.BASES[it["slot"]]):
		if b["name"] == it["base"]:
			return b
	return {}


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
	var base := _art_named(slug(it["base"]))
	if base == null and is_paper(it) and not is_deeds(it):
		return _art_named("paper")        # every paper is the same folded thing in the cell; the words tell them apart
	return base


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
	return base_of(it).has("damage")


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
	if it.has("unique"):
		return "Unique"
	if it.has("set"):
		return "Set"
	return Data.RARITIES[it["rarity"]]["name"]


## The name a row or a title shows: the base, since rarity is the colour on
## the edge and the word on the figure line; a unique goes by its own name.
static func full_name(it: Dictionary) -> String:
	if it.has("unique"):
		return it["unique"]
	if it.has("piece"):
		return it["piece"]
	return it["base"]


static func is_unique(it: Dictionary) -> bool:
	return it.has("unique")


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
static func tier_cap(ilvl: int) -> int:
	var best := 1
	for k in range(Data.TIER_CAP.size()):
		if ilvl >= int(Data.TIER_CAP[k]):
			best = k + 1
	return best


## A tier from the ones open, the better the rarer.
static func roll_tier(ilvl: int, rng: RandomNumberGenerator) -> int:
	var cap := tier_cap(ilvl)
	var total := 0.0
	for t in range(1, cap + 1):
		total += float(Data.TIER_WEIGHT[t - 1])
	var x := rng.randf() * total
	for t in range(1, cap + 1):
		x -= float(Data.TIER_WEIGHT[t - 1])
		if x <= 0.0:
			return t
	return 1


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


static func roll_affix(a: Dictionary, ilvl: int, rng: RandomNumberGenerator, tier := 0) -> Dictionary:
	var t := tier if tier > 0 else roll_tier(ilvl, rng)
	var r := tier_range(a, t)
	return {"stat": a["stat"], "value": rng.randi_range(r[0], r[1]), "tier": t}


static func ilvl(it: Dictionary) -> int:
	return int(it.get("ilvl", it["tier"]))


## The bench: the affixes rolled again (the count kept), one of them rolled
## again (its tier mostly kept; up a step sometimes, down a step less often,
## the odds narrowing as the tier rises), one more added, all of them off.
static func reroll_affixes(it: Dictionary, rng: RandomNumberGenerator, keep: String = "") -> void:
	var n: int = it["affixes"].size()
	var kept: Array = []
	for a in it["affixes"]:
		if a["stat"] == keep:
			kept.append(a)
	var have: Array = []
	for a in kept:
		have.append(a["stat"])
	it["affixes"] = kept
	for a in pick_affixes(it["slot"], n - kept.size(), rng, have):
		it["affixes"].append(roll_affix(a, ilvl(it), rng))


## One affix rolled again. Returns the new tier, or 0 if the stat isn't on it.
static func reroll_one(it: Dictionary, stat: String, rng: RandomNumberGenerator) -> int:
	for k in range(it["affixes"].size()):
		var a: Dictionary = it["affixes"][k]
		if a["stat"] != stat:
			continue
		var d := affix_def(stat)
		var t: int = int(a.get("tier", 1))
		var cap := tier_cap(ilvl(it))
		var up := 0.25 / float(t)                              # T1 → T2 one in four; T4 → T5 one in sixteen
		var x := rng.randf()
		if x < up and t < cap:
			t += 1
		elif x < up + 0.1 and t > 1:
			t -= 1
		it["affixes"][k] = roll_affix(d, ilvl(it), rng, t)
		return t
	return 0


## One more affix, one not already on it, and the rarity up a step.
static func add_affix(it: Dictionary, rng: RandomNumberGenerator) -> bool:
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
	it["affixes"].append(roll_affix(picked[0], ilvl(it), rng))
	it["rarity"] = int(it["rarity"]) + 1
	it["value"] = int(round(base_of(it)["value"] * Data.RARITIES[it["rarity"]]["value"]))
	return true


static func strip_affixes(it: Dictionary) -> void:
	it["affixes"] = []
	it["rarity"] = 0
	it["value"] = int(round(base_of(it)["value"] * Data.RARITIES[0]["value"]))


static func add_socket(it: Dictionary) -> bool:
	if not (it["slot"] in Data.SOCKET_SLOTS) or sockets(it) >= Data.SOCKET_MAX:
		return false
	it["attachments"]["socket %d" % (sockets(it) + 1)] = null
	return true


## A set piece, rolled: its base, its fixed affixes, the set's name on it.
static func roll_set_piece(set_name: String, piece: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var it := roll(piece["slot"], Data.MAX_TIER, rng)
	it["base"] = piece["base"]
	it["tier"] = base_of(it)["tier"]
	it["rarity"] = 2
	it["affixes"] = piece["affixes"].duplicate(true)
	it["set"] = set_name
	it["piece"] = piece["name"]
	it["value"] = int(round(base_of(it)["value"] * Data.RARITIES[2]["value"] * 1.5))
	return it


static func is_set(it: Dictionary) -> bool:
	return it.has("set")


static func set_named(name: String) -> Dictionary:
	for s in Data.SETS:
		if s["name"] == name:
			return s
	return {}


## A unique, rolled: its base, its fixed affixes, its name, its rule.
static func roll_unique(u: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var it := roll(u["slot"], Data.MAX_TIER, rng)
	it["base"] = u["base"]
	it["tier"] = base_of(it)["tier"]
	it["rarity"] = 3
	it["affixes"] = u["affixes"].duplicate(true)
	it["unique"] = u["name"]
	it["rule"] = u["rule"]
	it["value"] = int(round(base_of(it)["value"] * Data.RARITIES[3]["value"] * 1.5))
	return it


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
	if not b.has("damage"):
		return 0.0
	return b["damage"] * b["rof"] * (1.0 + fitted_sum(it, "damage_pct") / 100.0)


static func armour(it: Dictionary) -> float:
	return base_of(it).get("armour", 0.0) + affix_total(it, "armour")


## A med's healing, and the seconds it takes.
static func heal(it: Dictionary) -> float:
	return base_of(it).get("heal", 0.0) * (1.0 + affix_total(it, "heal_pct") / 100.0)


static func use_time(it: Dictionary) -> float:
	return base_of(it).get("use", 0.0)


static func is_medical(it: Dictionary) -> bool:
	return it["slot"] == Data.MEDICAL


static func is_paper(it: Dictionary) -> bool:
	return it["slot"] == Data.PAPER


static func is_deeds(it: Dictionary) -> bool:
	return it["slot"] == Data.PAPER and it["base"] == "The deeds"


static func is_ammo(it: Dictionary) -> bool:
	return it["slot"] == Data.AMMO


## The ammo type a gun fires, "" for anything that isn't a gun.
static func ammo_type(gun: Dictionary) -> String:
	var b := base_of(gun)
	return str(b.get("ammo", b.get("type", "")))


static func is_melee(it: Dictionary) -> bool:
	return base_of(it).get("type", "") == "melee"


## What a gun takes, by the standard box of its type: "Takes shells"; a bat, nothing.
static func ammo_words(gun: Dictionary) -> String:
	var type := ammo_type(gun)
	if type == "none" or gun.get("rule", "") == "weed_burner":
		return "Takes nothing"
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
		"rounds":
			return float(it.get("rounds", 0)) * (1.0 + float(base_of(it).get("damage_pct", 0)) / 100.0)
		"attach":
			if is_socketable(it):
				return att_stat(it, "conv_fire_pct") + att_stat(it, "conv_frost_pct") + att_stat(it, "conv_poison_pct") + att_stat(it, "conv_shock_pct") + att_stat(it, "salt") + att_stat(it, "wire_pct")
			return att_stat(it, "damage_pct") + att_stat(it, "first_pct") / 3.0 + att_stat(it, "speed_pct") + att_stat(it, "patrol_pct") / 4.0
		"find":
			return find(it) + cash_pct(it) * 0.5
	return 0.0


## A charm's magic find and cash, base plus affixes.
static func find(it: Dictionary) -> float:
	return float(base_of(it).get("find", 0)) + affix_total(it, "rarity_pct")


static func cash_pct(it: Dictionary) -> float:
	return float(base_of(it).get("cash", 0)) + affix_total(it, "cash_pct")


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
		var pct: bool = a["stat"].ends_with("_pct") or a["stat"] == "loot_per_lot"
		var line: String
		if a["stat"] == "cash_per_kill":
			line = "+£%d %s" % [a["value"], label]
		else:
			line = "+%d%s %s" % [a["value"], "%" if pct else "", label]
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
		return "Med"
	if slot == Data.PAPER:
		return "Paper"
	if is_melee(it):
		return "%s · melee" % slot
	var tw := type_word(it)
	return ("%s · %s" % [slot, tw]) if tw != "" else slot


static func figure_options(it: Dictionary, tail := "") -> Array:
	var h := headline(it)
	var tw := type_word(it)
	var unit: String = "dmg/s" if tw != "" else h[1]
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
static func affix_options(it: Dictionary) -> Array:
	if it["affixes"].is_empty():
		return ["No affixes"]
	var n: int = it["affixes"].size()
	return [", ".join(affix_lines(it)), ", ".join(affix_lines(it, true)), "%d affix%s" % [n, "" if n == 1 else "es"]]


## The headline figure and its unit for a card.
static func headline(it: Dictionary) -> Array:
	var b := base_of(it)
	if b.has("damage"):
		return ["%.0f" % dps(it), "damage/s"]
	if b.has("armour"):
		return ["%.0f" % armour(it), "armour"]
	if b.has("heal"):
		return ["%.0f" % heal(it), "HP in %.0f s" % use_time(it)]
	if b.has("rounds"):
		return ["%d" % int(it.get("rounds", 0)), "rounds" + ((", +%d%%" % int(b["damage_pct"])) if b.has("damage_pct") else "")]
	if b.has("mount"):
		var lead := att_lead(it)
		return [lead[0], lead[1]]
	if it["slot"] == Data.PAPER:
		return ["£%d" % int(it["value"]), "to the fence"]
	if it["slot"] == Data.CHARM:
		return ["+%.0f%%" % find(it), "loot quality"]
	return ["%d" % capacity(it), "capacity"]


## An attachment's headline: its biggest effect.
static func att_lead(it: Dictionary) -> Array:
	var best := ["", ""]
	var size := 0.0
	for pair in [["damage_pct", "% damage"], ["first_pct", "% first shot"], ["speed_pct", "% pace"], ["patrol_pct", "% gang delay"],
			["conv_fire_pct", "% of hits as fire"], ["conv_frost_pct", "% of hits as frost"], ["conv_poison_pct", "% of hits as poison"], ["conv_shock_pct", "% of hits as shock"], ["conv_bleed_pct", "% of hits as bleed"], ["salt", " armour"], ["wire_pct", "% cash"]]:
		var v := att_stat(it, pair[0])
		if absf(v) > size:
			size = absf(v)
			var sign: String = "+" if v > 0 else "−"
			if pair[0].begins_with("conv_"):
				sign = ""                     # "15% of hits as fire" is a share, not a bonus
			best = ["%s%.0f%s" % [sign, absf(v), "%" if pair[1].begins_with("%") else ""], pair[1].trim_prefix("%").strip_edges()]
	return best


## Every effect an attachment carries, as short words: "+9% dmg, −4% pace".
## `base_only`: the part's own figures, its rolled affixes left for their own lines.
static func att_words(it: Dictionary, short := false, base_only := false) -> String:
	var out := []
	for pair in [["damage_pct", "dmg", "dmg"], ["first_pct", "first shot", "first"], ["speed_pct", "pace", "pace"], ["patrol_pct", "gang delay", "delay"],
			["conv_fire_pct", "of hits as fire: they burn", "as fire"], ["conv_frost_pct", "of hits as frost: they're chilled", "as frost"], ["conv_poison_pct", "of hits as poison: it lingers", "as poison"], ["conv_shock_pct", "of hits as shock: they take more", "as shock"], ["conv_bleed_pct", "of hits as bleed: they keep bleeding", "as bleed"], ["salt", "armour", "armour"], ["wire_pct", "cash from every kill", "cash"]]:
		var v: float = float(base_of(it).get(pair[0], 0)) if base_only else att_stat(it, pair[0])
		if absf(v) >= 0.5:
			var sign: String = "" if pair[0].begins_with("conv_") else ("+" if v > 0 else "−")
			out.append("%s%.0f%s %s" % [sign, absf(v), "" if pair[0] == "salt" else "%", pair[2] if short else pair[1]])
	return ", ".join(out)


## What a socketable is, in a line: where it goes and what it does there.
static func socket_words(it: Dictionary) -> String:
	var b := base_of(it)
	if b.has("salt"):
		return "A socketable: packed into any socket, +%d armour" % int(b["salt"])
	if b.has("wire_pct"):
		return "A socketable: in any socket, +%d%% cash from every kill" % int(b["wire_pct"])
	for ty in ["fire", "frost", "poison", "shock"]:
		if b.has("conv_%s_pct" % ty):
			return "A socketable: in any socket, %d%% of your hits land as %s" % [int(b["conv_%s_pct" % ty]), ty]
	return "A socketable: goes in a socket at the bench"


## Stacks: how many a stack of this can hold, and how many it holds.
static func stack_cap(it: Dictionary) -> int:
	if is_ammo(it):
		return int(base_of(it)["rounds"]) * Data.STACK_BOXES
	if is_socketable(it):
		return Data.SOCKET_STACK
	return 1


static func stack_size(it: Dictionary) -> int:
	if is_ammo(it):
		return int(it.get("rounds", 0))
	if is_socketable(it):
		return int(it.get("count", 1))
	return 1


static func stacks(it: Dictionary) -> bool:
	return is_ammo(it) or (is_socketable(it) and it.get("affixes", []).is_empty())


## Two stacks that can merge: the same base, both plain.
static func same_stack(a: Dictionary, b: Dictionary) -> bool:
	return stacks(a) and stacks(b) and a["base"] == b["base"] and a["slot"] == b["slot"]


## Put n of a stack's rounds or count into another; the stack's value follows what it holds.
static func set_stack(it: Dictionary, n: int) -> void:
	var b := base_of(it)
	if is_ammo(it):
		it["rounds"] = n
		it["value"] = int(round(float(b["value"]) * n / float(b["rounds"])))
	elif is_socketable(it):
		it["count"] = n
		it["value"] = int(b["value"]) * n


## A copy of one off a stack (a socketable going into a socket).
static func one_of(it: Dictionary) -> Dictionary:
	var one := it.duplicate(true)
	one["id"] = _next_id
	_next_id += 1
	set_stack(one, 1)
	return one
