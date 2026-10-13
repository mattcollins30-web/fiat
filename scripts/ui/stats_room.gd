extends Control
## The Stats room as a sheet (10 Oct, Stats-R A on the canvas; Matt: the one room that "reads like a sample Godot
## project ... the info we have should be included"). A short band over three rows: who (the runner), the fight
## (attack, defence - the tall cards), the haul and the past (finds, the record, the last run), and the wall along
## the foot. Each part has the picture that suits it: the damage as a chain that shows where it comes from, the
## resists as bars against the cap, the finds as bars, the record as trophies, the wall as the runners' plates.
## Every figure the eight cards had; the Kit card's worth moved into the runner's facts (the Runner room has the kit).

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const People := preload("res://scripts/ui/people.gd")
const Band := preload("res://scripts/ui/band.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")

const W := Pal.GRID_W                      # 1536
const H := Pal.ROOM_H                      # 916
const BAND_H := Pal.BAND_H                  # the rooms' one band (10 Oct, Bands-U A): 96 → 180, paid for by the rows below
const GAP := 10
const PAD := 18
const COL_X := [0, 450, 998]
const COL_W := [440, 538, 538]
const R1_Y := BAND_H + GAP
const R1_H := 332
const R2_Y := R1_Y + R1_H + GAP
const R2_H := 252
const R3_Y := R2_Y + R2_H + GAP
const R3_H := H - R3_Y
const ROW_H := 24                          # 28 → 24 (Bands-U A)
const BAR_TH := 10
const FACE := 64                           # the band's face and the wall's: a clean half of the 128 px portraits
const PLATE_W := 236
const PLATE_H := 84
const TILE_H := 84                          # the record's tiles (96 → 84, Bands-U A)
const PLATES := 5
const KEY_W := 150                          # a chain or bar row's words before its bar
const VAL_W := 86                           # and its figure after it

var sim
var band: Band
var _band_face: TextureRect
var cards := {}                            # name -> {panel, title, headline, unit, ...}: the tests read them by name


func _init() -> void:
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	band = Band.new(W, BAND_H, 4)
	add_child(band)
	band.portrait_width(Pal.BAND_FACE)
	band.room_band()
	band.set_site("The Stats")              # art/places/the_stats.png once painted (Rooms-B); the skyline till then
	_band_face = People.rect(band, Vector2(Band.PAD, (BAND_H - Pal.BAND_FACE) / 2.0), Pal.BAND_FACE / 128.0)
	_card("runner", 0, R1_Y, R1_H, "The runner")
	_card("attack", 1, R1_Y, R1_H, "Attack")
	_card("defence", 2, R1_Y, R1_H, "Defence")
	_card("finds", 0, R2_Y, R2_H, "Finds")
	_card("record", 1, R2_Y, R2_H, "The record")
	_card("last", 2, R2_Y, R2_H, "Last run")
	_card_wide("wall", R3_Y, R3_H, "The wall")
	_build_runner()
	_build_attack()
	_build_defence()
	_build_finds()
	_build_record()
	_build_last()
	_build_wall()


# ------------------------------------------------------------------ building

func _card(name: String, col: int, y: float, h: float, title: String) -> Dictionary:
	var c := {"x": float(COL_X[col]), "y": y, "w": float(COL_W[col]), "h": h}
	c["panel"] = UI.panel(self, Rect2(c["x"], y, c["w"], h), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	c["title"] = UI.head(self, Rect2(c["x"] + PAD, y + 10, c["w"] - 2 * PAD, UI.HEAD_H), title)
	c["headline"] = UI.label(self, Rect2(c["x"] + PAD, y + 36, 200, 50), "", "SemiBold", Pal.HEADLINE, Pal.TEXT)
	c["unit"] = UI.label(self, Rect2(c["x"] + PAD, y + 46, c["w"] - 2 * PAD, 36), "", "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	cards[name] = c
	return c


func _card_wide(name: String, y: float, h: float, title: String) -> Dictionary:
	var c := {"x": 0.0, "y": y, "w": float(W), "h": h}
	c["panel"] = UI.panel(self, Rect2(0, y, W, h), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	c["title"] = UI.head(self, Rect2(PAD, y + 10, 300, UI.HEAD_H), title)
	c["headline"] = UI.label(self, Rect2(PAD, y + 30, 80, 46), "", "SemiBold", Pal.HEADLINE, Pal.TEXT)
	c["unit"] = UI.label(self, Rect2(PAD, y + 40, 160, 36), "", "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	cards[name] = c
	return c


## A row: a glyph, its words, its figure at the right.
func _row(c: Dictionary, y: float, glyph: String) -> Dictionary:
	var r := {}
	r["glyph"] = _glyph(Rect2(c["x"] + PAD, y + (ROW_H - 18) / 2.0, 18, 18), glyph, Pal.TEXT_3)
	r["key"] = UI.label(self, Rect2(c["x"] + PAD + 26, y, c["w"] * 0.5, ROW_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	r["value"] = UI.label(self, Rect2(c["x"] + c["w"] * 0.42, y, c["w"] * 0.58 - PAD, ROW_H), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	return r


## A bar row: its words, a bar, its figure.
func _bar_row(c: Dictionary, y: float, tick := -1.0) -> Dictionary:
	var r := {}
	r["key"] = UI.label(self, Rect2(c["x"] + PAD, y, KEY_W, ROW_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var bw: float = c["w"] - 2 * PAD - KEY_W - VAL_W - 16
	r["track"] = UI.panel(self, Rect2(c["x"] + PAD + KEY_W + 8, y + (ROW_H - BAR_TH) / 2.0, bw, BAR_TH), UI.box(Pal.BG, 4))
	r["fill"] = UI.panel(r["track"], Rect2(0, 0, 0, BAR_TH), UI.box(Pal.ACCENT, 4))
	if tick >= 0.0:
		r["tick"] = UI.panel(r["track"], Rect2(bw * tick - 1, -3, 2, BAR_TH + 6), UI.box(Pal.TEXT_2, 0))
	r["value"] = UI.label(self, Rect2(c["x"] + c["w"] - PAD - VAL_W, y, VAL_W, ROW_H), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	return r


func _glyph(rect: Rect2, key: String, tint: Color, parent: Node = null) -> TextureRect:
	var t := TextureRect.new()
	t.position = rect.position
	t.size = rect.size
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture = NodeGlyphs.texture(key)
	t.modulate = tint
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else self).add_child(t)
	return t


func _small(c: Dictionary, y: float, w := -1.0) -> Label:
	return UI.label(self, Rect2(c["x"] + PAD, y, (w if w > 0.0 else c["w"] - 2 * PAD), 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)


func _build_runner() -> void:
	var c: Dictionary = cards["runner"]
	var y: float = c["y"]
	c["track"] = UI.panel(self, Rect2(c["x"] + PAD, y + 96, c["w"] - 2 * PAD, BAR_TH), UI.box(Pal.BG, 4))
	c["fill"] = UI.panel(c["track"], Rect2(0, 0, 0, BAR_TH), UI.box(Pal.ACCENT, 4))
	c["xp"] = _small(c, y + 110)
	c["chips"] = Chips.new(c["w"] - 2 * PAD)
	c["chips"].position = Vector2(c["x"] + PAD, y + 134)
	add_child(c["chips"])
	c["rows"] = []
	var keys := ["pace", "pack", "runs", "clock", "depth", "cash"]
	for k in range(keys.size()):
		c["rows"].append(_row(c, y + 160 + k * ROW_H, keys[k]))
	c["note"] = _small(c, y + c["h"] - 26)


func _build_attack() -> void:
	var c: Dictionary = cards["attack"]
	var y: float = c["y"]
	c["kicker"] = _small(c, y + 92)
	c["chain"] = []
	for k in range(5):
		c["chain"].append(_bar_row(c, y + 116 + k * ROW_H))
	c["split"] = UI.panel(self, Rect2(c["x"] + PAD, y + 240, c["w"] - 2 * PAD, BAR_TH), UI.box(Pal.BG, 4))
	c["segs"] = []
	for ty in Data.TYPES:
		c["segs"].append(UI.panel(c["split"], Rect2(0, 0, 0, BAR_TH), UI.box(Pal.tone_color(ty) if ty != "physical" else Pal.TEXT_3, 0)))
	c["chips"] = Chips.new(c["w"] - 2 * PAD)
	c["chips"].position = Vector2(c["x"] + PAD, y + 256)
	add_child(c["chips"])
	c["note"] = _small(c, y + 282)
	c["status"] = _small(c, y + c["h"] - 26)


func _build_defence() -> void:
	var c: Dictionary = cards["defence"]
	var y: float = c["y"]
	c["armour_big"] = UI.label(self, Rect2(c["x"] + c["w"] * 0.5, y + 40, c["w"] * 0.5 - PAD, 44), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	c["track"] = UI.panel(self, Rect2(c["x"] + PAD, y + 96, c["w"] - 2 * PAD, BAR_TH), UI.box(Pal.BG, 4))
	c["fill"] = UI.panel(c["track"], Rect2(0, 0, 0, BAR_TH), UI.box(Color("9fb0c0"), 4))
	c["armour_line"] = _small(c, y + 110)
	c["res"] = []
	for k in range(Data.ELEMENTS.size()):
		c["res"].append(_bar_row(c, y + 138 + k * ROW_H, Data.RESIST_CAP / 100.0))
	c["note"] = _small(c, y + 262)
	c["status"] = _small(c, y + c["h"] - 26)


func _build_finds() -> void:
	var c: Dictionary = cards["finds"]
	var y: float = c["y"]
	c["bars"] = []
	for k in range(3):
		c["bars"].append(_bar_row(c, y + 90 + k * ROW_H))
	c["rows"] = [_row(c, y + 90 + 3 * ROW_H + 6, "search"), _row(c, y + 90 + 4 * ROW_H + 6, "loud")]
	c["status"] = _small(c, y + c["h"] - 30)


func _build_record() -> void:
	var c: Dictionary = cards["record"]
	var y: float = c["y"]
	var tw: float = (c["w"] - 2 * PAD - GAP) / 2.0
	c["tiles"] = []
	var glyphs := ["skull", "dmg", "cash", "gem"]
	for k in range(4):
		var tx: float = c["x"] + PAD + (k % 2) * (tw + GAP)
		var ty: float = y + 40 + (k / 2) * (TILE_H + GAP)
		var t := {}
		t["panel"] = UI.panel(self, Rect2(tx, ty, tw, TILE_H), UI.box(Pal.BG, 6))
		t["glyph"] = _glyph(Rect2(tx + 12, ty + 8, 20, 20), glyphs[k], Pal.ACCENT)
		t["value"] = UI.label(self, Rect2(tx + 12, ty + 26, tw - 24, 32), "", "SemiBold", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
		t["key"] = UI.label(self, Rect2(tx + 12, ty + 56, tw - 24, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["tiles"].append(t)
	c["status"] = _small(c, y + c["h"] - 30)


func _build_last() -> void:
	var c: Dictionary = cards["last"]
	var y: float = c["y"]
	c["edge"] = UI.panel(self, Rect2(c["x"], y + 1, 4, c["h"] - 2), UI.box(Pal.GOOD, 2))
	c["headline"].add_theme_font_size_override("font_size", Pal.TITLE + 4)
	c["rows"] = []
	var keys := ["where", "skull", "pack", "cash", "clock"]
	for k in range(keys.size()):
		c["rows"].append(_row(c, y + 88 + k * ROW_H, keys[k]))
	c["status"] = UI.label(self, Rect2(c["x"] + PAD, y + c["h"] - 32, c["w"] - 2 * PAD, 26), "", "Medium", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)


func _build_wall() -> void:
	var c: Dictionary = cards["wall"]
	var y: float = c["y"]
	c["sub"] = UI.label(self, Rect2(PAD, y + 76, 262, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	c["retired"] = UI.label(self, Rect2(PAD, y + 98, 262, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	c["plates"] = []
	var x0: float = W - PAD - PLATES * PLATE_W - (PLATES - 1) * GAP
	var py: float = y + (R3_H - PLATE_H) / 2.0
	for k in range(PLATES):
		var px: float = x0 + k * (PLATE_W + GAP)
		var p := {}
		p["panel"] = UI.panel(self, Rect2(px, py, PLATE_W, PLATE_H), UI.box(Pal.BG, 6, 1, Pal.CARD_LINE))
		p["face"] = People.rect(self, Vector2(px + 10, py + (PLATE_H - FACE) / 2.0), 0.5)
		p["name"] = UI.label(self, Rect2(px + FACE + 20, py + 12, PLATE_W - FACE - 30, 28), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		p["line"] = UI.label(self, Rect2(px + FACE + 20, py + 42, PLATE_W - FACE - 30, 26), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["plates"].append(p)


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	var lv: int = sim.level()
	var dps: float = sim.dps()
	band.set_words("Stats · %s, level %d" % [sim.cls if sim.cls != "" else "no past yet", lv], "", "%.0f" % dps, ["dmg/s"])
	People.show(_band_face, sim.cls)
	_show_runner(lv)
	_show_attack(lv, dps)
	_show_defence()
	_show_finds()
	_show_record()
	_show_last()
	_show_wall()


func _headline(c: Dictionary, text: String, unit: String, colour := Pal.TEXT) -> void:
	c["headline"].text = text
	c["headline"].add_theme_color_override("font_color", colour)
	var hw: float = ceilf(UI.text_width(c["headline"], text))
	c["headline"].size.x = hw + 4
	c["unit"].text = unit
	c["unit"].position.x = c["headline"].position.x + hw + 12
	c["unit"].size.x = maxf(40.0, c["x"] + c["w"] - PAD - c["unit"].position.x - (c["w"] * 0.5 if c.has("armour_big") else 0.0))


func _set_row(r: Dictionary, key: String, values: Array, tone := Pal.TEXT) -> void:
	r["key"].text = key
	UI.fit(r["value"], values)
	r["value"].add_theme_color_override("font_color", tone)


func _set_bar(r: Dictionary, key: String, frac: float, value: String, colour: Color, value_tone := Pal.TEXT) -> void:
	r["key"].text = key
	r["fill"].size.x = roundf(r["track"].size.x * clampf(frac, 0.0, 1.0))
	(r["fill"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = colour
	r["value"].text = value
	r["value"].add_theme_color_override("font_color", value_tone)


static func signed_pct(v: float) -> String:
	return ("+%.0f%%" % v) if v >= 0.5 else (("−%.0f%%" % absf(v)) if v <= -0.5 else "0%")


func _show_runner(lv: int) -> void:
	var c: Dictionary = cards["runner"]
	_headline(c, "%d" % lv, "level" if sim.paragon() == 0 else "level · +%d paragon" % sim.paragon())
	var shown: int = lv + Data.paragon_for_xp(sim.xp)        # this runner's own levels: the banked paragon is another yard's XP (the review)
	var this_xp := Data.xp_for_level(shown)
	var next_xp := Data.xp_for_level(shown + 1)
	var fill: float = clampf((sim.xp - this_xp) / maxf(1.0, next_xp - this_xp), 0.0, 1.0)
	c["fill"].size.x = roundf(c["track"].size.x * fill)
	c["xp"].text = "%s / %s xp to %d" % [Fmt.num(sim.xp - this_xp), Fmt.num(next_xp - this_xp), shown + 1]
	var who := []
	if sim.wound != "":
		who.append([sim.wound_words(), "bad"])
	if sim.cls != "":
		who.append([sim.cls, ""])
	var td: Dictionary = sim.trait_data()
	if not td.is_empty():
		who.append({"forms": ["%s: %s" % [td["name"], td["words"]], str(td["name"])], "colour": "good"})     # the name alone where the figures won't fit
	c["chips"].show_chips(who)
	var alive: float = sim.elapsed - float(sim.record.get("since", 0.0))
	var dig: String = "none yet"
	if not sim.best_dig.is_empty():
		dig = "%s, depth %d" % [str(sim.best_dig["site"]).trim_prefix("The "), int(sim.best_dig["depth"])]
	var rows: Array = c["rows"]
	_set_row(rows[0], "Pace", ["×%.2f" % sim.pace()])
	_set_row(rows[1], "Pack · rig", ["%d cells · %d" % [sim.capacity(), sim.med_capacity()], "%d · %d" % [sim.capacity(), sim.med_capacity()]])
	_set_row(rows[2], "Runs, this runner", ["%d" % sim.runner_runs])
	_set_row(rows[3], "Alive", [Fmt.clock(alive)])
	_set_row(rows[4], "Deepest hold", [dig, dig.get_slice(",", 0)])
	_set_row(rows[5], "Kit worth", [Fmt.money(sim.loadout_value())], Pal.ACCENT)
	UI.fit(c["note"], [sim.next_words(true), sim.next_words(true).replace(" on the Map", ""), ""])


func _show_attack(lv: int, dps: float) -> void:
	var c: Dictionary = cards["attack"]
	_headline(c, "%.0f" % dps, "dmg/s", Pal.ACCENT)
	var cd: Dictionary = sim.class_data()
	# how it's built (the review): dps()'s own parts, in its order - the guns (their grades and the secondary's share),
	# the level, the affixes and the tree on top of it, the attack, the past, then the trait and growth to the total
	var p: Dictionary = sim.damage_parts()
	var steps := [float(p["guns"])]
	steps.append(steps[0] * (1.0 + float(p["level"])))
	steps.append(steps[0] * (1.0 + float(p["level"]) + float(p["pct"])) * (1.0 + float(p["attack"])))
	steps.append(steps[2] * float(p["past"]))
	var top: float = maxf(dps, steps.max())
	var gold := Color("c98a2f")
	c["kicker"].text = "How it's built"
	_set_bar(c["chain"][0], "Guns", steps[0] / top, "%.0f/s" % steps[0], gold)
	_set_bar(c["chain"][1], "Level", steps[1] / top, "+%.0f%%" % (float(p["level"]) * 100.0), gold)
	var on_top: float = ((1.0 + float(p["level"]) + float(p["pct"])) * (1.0 + float(p["attack"])) / (1.0 + float(p["level"])) - 1.0) * 100.0
	_set_bar(c["chain"][2], "Affixes · tree", steps[2] / top, signed_pct(on_top), gold)
	_set_bar(c["chain"][3], "Past", steps[3] / top, ("×%.2f" % float(p["past"])) if sim.cls != "" else "—", gold)
	_set_bar(c["chain"][4], "= total", dps / top, "%.0f/s" % dps, Pal.ACCENT, Pal.ACCENT)
	# the elements dealt: one bar, a segment a type, and the chips name them
	var conv: Dictionary = sim.conversion()
	var x := 0.0
	var phys: float = 1.0
	var chips := []
	for k in range(Data.TYPES.size()):
		var ty: String = Data.TYPES[k]
		var share: float = 0.0
		if ty != "physical":
			share = float(conv.get(ty, 0.0))
			phys -= share
	for k in range(Data.TYPES.size()):
		var ty: String = Data.TYPES[k]
		var share: float = maxf(0.0, phys) if ty == "physical" else float(conv.get(ty, 0.0))
		var seg: Panel = c["segs"][k]
		var w: float = roundf(c["split"].size.x * share)
		seg.position.x = x
		seg.size.x = w
		seg.visible = w >= 1.0
		x += w
		if ty != "physical" and share * 100.0 > 0.5:
			chips.append(["%s %.0f%%" % [ty.capitalize(), share * 100.0], ty])
	if chips.is_empty():
		chips.append(["All of it physical", ""])
	c["chips"].show_chips(chips)
	var first_pct: float = sim._fitted_sum("first_pct") + float(cd.get("first_pct", 0)) + sim.tree_sum("first_pct")
	c["note"].text = ("Growth ×%.2f past the cap · first shot %s" % [sim.growth_mult(), signed_pct(first_pct)]) if sim.growth_mult() > 1.001 else "First shot %s" % signed_pct(first_pct)
	c["status"].text = "Walking fire: the SMG" if sim.gun_type() == "smg" else (("Firing %s" % {"rifle": "a rifle", "shotgun": "a shotgun", "improvised": "something improvised", "pistol": "a pistol", "melee": "a blade"}.get(sim.gun_type(), sim.gun_type())) if sim.gun_type() != "" else "Nothing in hand")


## The elements the open sites fire.
func _zone_fires() -> Dictionary:
	var out := {}
	for i in range(Data.TIERS.size()):
		if sim.tier_open(i):
			for ty in Data.ZONE_TYPES[int(Data.TIERS[i]["zone"])]["types"]:
				out[ty] = true
	return out


func _show_defence() -> void:
	var c: Dictionary = cards["defence"]
	_headline(c, "%d" % sim.max_hp_shown(), "max HP")
	c["armour_big"].text = "%s armour" % Fmt.pct(sim.mitigation())
	c["fill"].size.x = roundf(c["track"].size.x * clampf(sim.mitigation(), 0.0, 1.0))
	c["armour_line"].text = "%.0f armour · %s of a hit stopped" % [sim.armour(), Fmt.pct(sim.mitigation())]
	var fires := _zone_fires()
	var fired := []
	for k in range(Data.ELEMENTS.size()):
		var ty: String = Data.ELEMENTS[k]
		var v: float = sim.resist(ty) * 100.0
		var naked: bool = fires.has(ty) and v < 0.5
		var over: float = sim.over_cap(ty)
		var vt: String = ("%.0f%% ●" % v) if naked else ("%.0f%% +%.0f" % [v, over] if over >= 0.5 else "%.0f%%" % v)     # over the cap (12 Oct): what's past it, as that element's damage
		_set_bar(c["res"][k], ty.capitalize(), v / 100.0, vt, Pal.tone_color(ty), Pal.BAD if naked else Pal.tone_color(ty))
		if fires.has(ty):
			fired.append(ty)
	var gs: Array = sim.guard_sources()
	if gs.is_empty():
		c["note"].text = "%d%% cap · +N past it is +N%% damage · ● none where sites hit" % int(Data.RESIST_CAP)
		c["note"].add_theme_color_override("font_color", Pal.TEXT_3)
	else:
		# Guard (12 Oct): its cap and where it comes from, in its own colour; the cap's note is the bars' ticks
		var cap: int = int(round(sim.guard_cap()))
		UI.fit(c["note"], ["Guard to %d: %s" % [cap, ", ".join(gs)], "Guard to %d: %s" % [cap, gs[0] + (" +%d" % (gs.size() - 1) if gs.size() > 1 else "")], "Guard to %d" % cap])
		c["note"].add_theme_color_override("font_color", Pal.GUARD)
	c["status"].text = (("Sites fire %s" % ", ".join(fired)) if fired.size() <= 3 else "Sites fire %d elements" % fired.size()) if not fired.is_empty() else "Nothing open fires an element"


func _show_finds() -> void:
	var c: Dictionary = cards["finds"]
	_headline(c, signed_pct(sim.rarity_bonus() * 100.0), "loot quality", Pal.GOOD)
	var qty: float = sim.loot_bonus() * 100.0
	var cash: float = sim.tree_sum("cash_pct") + sim.charm_cash()
	var notes: float = sim._affix_sum("notes_pct")
	_set_bar(c["bars"][0], "Loot quantity", qty / 100.0, signed_pct(qty), Pal.GOOD)
	_set_bar(c["bars"][1], "Tins", cash / 100.0, signed_pct(cash), Pal.GOOD)
	_set_bar(c["bars"][2], "Notes", notes / 100.0, signed_pct(notes), Pal.GOOD)
	var search_faster: float = (1.0 - sim.search_s({}) / sim.SEARCH_S) * 100.0
	var patrol_later: float = (sim.patrol_s({}) / sim.PATROL_S - 1.0) * 100.0 if not sim.has_node("never_there") else 0.0
	_set_row(c["rows"][0], "Search", [("%.0f%% faster" % search_faster) if search_faster > 0.5 else "as it comes"])
	_set_row(c["rows"][1], "Gangs", [("%.0f%% later" % patrol_later) if patrol_later > 0.5 else ("never" if sim.has_node("never_there") else "as they come")])
	c["status"].text = dog_words(sim)


## The Kennel's line.
static func dog_words(s) -> String:
	var finds: int = (1 if s.yard_has("a_dog") else 0) + (1 if s.yard_has("second_dog") else 0) + (2 if s.yard_has("pack") else 0)
	if finds > 0:
		return "The dogs find +%d a search" % finds if finds > 1 else "A dog finds +1 a search"
	return "No dog finding yet" if s.yard_side("kennel", 0) == "" else "A dog with a nose for it"


func _show_record() -> void:
	var c: Dictionary = cards["record"]
	var rec: Dictionary = sim.record
	_headline(c, "", "")
	c["headline"].visible = false
	c["unit"].visible = false
	var t: Array = c["tiles"]
	var find: String = str(rec.get("find", ""))
	_tile(t[0], ["%d" % int(rec.get("kills", 0))], "kills, the best run")
	_tile(t[1], [Fmt.num(float(rec.get("dealt", 0.0)))], "most damage, a run")
	_tile(t[2], [Fmt.money(float(rec.get("cash", 0.0)))], "the best take")
	_tile(t[3], [find, find.get_slice(" ", find.count(" "))] if find != "" else ["nothing yet"], ("dearest find · %s" % Fmt.money(float(rec.get("find_value", 0)))) if find != "" else "the dearest find", Pal.ACCENT if find != "" else Pal.TEXT_3)
	var alive: float = sim.elapsed - float(sim.record.get("since", 0.0))
	var seen: int = sim.operators_lost - int(rec.get("deaths_seen", 0))
	UI.fit(c["status"], ["%d runs back · alive %s · %s" % [int(rec.get("runs", 0)), Fmt.clock(alive), ("%d lost on their watch" % seen) if seen > 0 else "no one lost on their watch"],
		"%d runs back · alive %s" % [int(rec.get("runs", 0)), Fmt.clock(alive)]])


func _tile(t: Dictionary, values: Array, key: String, tone := Pal.TEXT) -> void:
	UI.fit(t["value"], values)
	t["value"].add_theme_color_override("font_color", tone)
	UI.fit(t["key"], [key, key.get_slice(" · ", 0)])


func _show_last() -> void:
	var c: Dictionary = cards["last"]
	var r = sim.last_report
	var rows: Array = c["rows"]
	if r == null:
		_headline(c, "None yet", "")
		for row in rows:
			_set_row(row, "", [""])
			row["glyph"].visible = false
		c["status"].text = "The first run writes here"
		(c["edge"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.CARD_LINE
		return
	var dead: bool = r["outcome"] == "Dead"
	var timed_out: bool = r.get("timed_out", false)
	var tone: Color = Pal.BAD if dead else (Pal.ACCENT if timed_out else Pal.GOOD)
	_headline(c, str(r["outcome"]), ("· XP +%s" % Fmt.num(r["xp"])) if not dead else "", tone)
	(c["edge"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = tone
	for row in rows:
		row["glyph"].visible = true
	var t: Dictionary = sim.tier(r["tier"])
	_set_row(rows[0], "Where", [t["name"], str(t["name"]).trim_prefix("The ")])
	_set_row(rows[1], "Kills · gangs", ["%d · %d" % [r["kills"], int(r.get("patrols", 0))]])
	_set_row(rows[2], "Loot", ["%d item%s" % [r["loot"], "" if int(r["loot"]) == 1 else "s"]])
	_set_row(rows[3], "Tins · scrap", ["%s · %d" % [Fmt.money(r["cash"]), int(r.get("scrap", 0))]])
	_set_row(rows[4], "Took", [Fmt.mss(r["time"])])
	var status: String = ""
	if dead:
		status = ("Lost %s, one carried" if r.has("carried") else "Lost %s of kit") % Fmt.money(r["lost_value"])
	elif timed_out:
		status = "Out of time: the pack and %d pieces of kit lost" % Data.CLOCK_LOSE_KIT
	elif r.get("wounded", false):
		status = "Wounded: seen to at the Clinic"
	elif r.get("way_out", false):
		status = "Out by the way out"
	c["status"].text = status
	c["status"].add_theme_color_override("font_color", Pal.BAD if (dead or r.get("wounded", false)) else (Pal.ACCENT if timed_out else Pal.TEXT_2))


func _show_wall() -> void:
	var c: Dictionary = cards["wall"]
	_headline(c, "%d" % sim.operators_lost, "lost")
	UI.fit(c["sub"], ["%d retired · %d runs, every runner" % [sim.retired.size(), sim.runs_total], "%d retired · %d runs in all" % [sim.retired.size(), sim.runs_total], "%d retired · %d runs" % [sim.retired.size(), sim.runs_total]])
	UI.fit(c["retired"], [("Wall: %s" % ", ".join(sim.retired)) if not sim.retired.is_empty() else "No one retired yet", "Wall: %d traits" % sim.retired.size()])
	var plates: Array = c["plates"]
	for k in range(PLATES):
		var p: Dictionary = plates[k]
		var i: int = sim.past.size() - 1 - k              # newest first
		if i < 0:
			p["face"].visible = false
			p["name"].text = ""
			p["line"].text = ""
			(p["panel"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color.TRANSPARENT
			continue
		(p["panel"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.BG
		var past: Dictionary = sim.past[i]
		var end: String = str(past.get("end", ""))
		var lost: bool = end.begins_with("died")
		People.show(p["face"], str(past["class"]))
		p["face"].modulate = Color(0.55, 0.55, 0.55) if lost else Color.WHITE
		p["name"].text = "%s · %d" % [past["class"], int(past["level"])]
		UI.fit(p["line"], ["%d runs · %s" % [int(past["runs"]), end], "%d runs · %s" % [int(past["runs"]), "lost" if lost else end.get_slice(" ", 0)], "%d runs" % int(past["runs"])])
		p["line"].add_theme_color_override("font_color", Pal.BAD if lost else Pal.GOOD)


## Every label the room shows, for the fit checks.
func text_nodes() -> Array:
	var out: Array = band.text_nodes()
	for c in cards.values():
		for k in c.keys():
			var v = c[k]
			if v is Label:
				out.append(v)
			elif v is Array:
				for e in v:
					if e is Dictionary:
						for e2 in e.values():
							if e2 is Label:
								out.append(e2)
	return out
