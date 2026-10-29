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
const Words := preload("res://scripts/sim/words.gd")
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
const CHAIN_ROWS := 6                       # the Attack card's chain (29 Oct: the gun type's edge a row of its own, so the rows add up)
const CHAIN_H := 20                         # in the five rows' 120 px
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
var fight_button: Button                   # the Last run card's "The fight ›" (24 Oct, the breakdown)
var fight_panel: Panel                     # the breakdown over the room; built on show
var _fight_labels: Array = []              # every label the breakdown shows, for the fit checks
var collection_button: Button              # the Record card's "The collection ›" (24 Oct, the endgame chase)
var collection_panel: Panel                # the collection over the room; built on show
var _coll_labels: Array = []


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

func _card(nm: String, col: int, y: float, h: float, title: String) -> Dictionary:
	var c := {"x": float(COL_X[col]), "y": y, "w": float(COL_W[col]), "h": h}
	c["panel"] = UI.panel(self, Rect2(c["x"], y, c["w"], h), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	c["title"] = UI.head(self, Rect2(c["x"] + PAD, y + 10, c["w"] - 2 * PAD, UI.HEAD_H), title)
	c["headline"] = UI.label(self, Rect2(c["x"] + PAD, y + 36, 200, 50), "", "SemiBold", Pal.HEADLINE, Pal.TEXT)
	c["unit"] = UI.label(self, Rect2(c["x"] + PAD, y + 46, c["w"] - 2 * PAD, 36), "", "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	cards[nm] = c
	return c


func _card_wide(nm: String, y: float, h: float, title: String) -> Dictionary:
	var c := {"x": 0.0, "y": y, "w": float(W), "h": h}
	c["panel"] = UI.panel(self, Rect2(0, y, W, h), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	c["title"] = UI.head(self, Rect2(PAD, y + 10, 300, UI.HEAD_H), title)
	c["headline"] = UI.label(self, Rect2(PAD, y + 30, 80, 46), "", "SemiBold", Pal.HEADLINE, Pal.TEXT)
	c["unit"] = UI.label(self, Rect2(PAD, y + 40, 160, 36), "", "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	cards[nm] = c
	return c


## A row: a glyph, its words, its figure at the right.
func _row(c: Dictionary, y: float, glyph: String) -> Dictionary:
	var r := {}
	r["glyph"] = _glyph(Rect2(c["x"] + PAD, y + (ROW_H - 18) / 2.0, 18, 18), glyph, Pal.TEXT_3)
	r["key"] = UI.label(self, Rect2(c["x"] + PAD + 26, y, c["w"] * 0.5, ROW_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	r["value"] = UI.label(self, Rect2(c["x"] + c["w"] * 0.42, y, c["w"] * 0.58 - PAD, ROW_H), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	return r


## A bar row: its words, a bar, its figure.
func _bar_row(c: Dictionary, y: float, tick := -1.0, rh := ROW_H) -> Dictionary:
	var r := {}
	r["key"] = UI.label(self, Rect2(c["x"] + PAD, y, KEY_W, rh), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var bw: float = c["w"] - 2 * PAD - KEY_W - VAL_W - 16
	r["track"] = UI.panel(self, Rect2(c["x"] + PAD + KEY_W + 8, y + (rh - BAR_TH) / 2.0, bw, BAR_TH), UI.box(Pal.BG, 4))
	r["fill"] = UI.panel(r["track"], Rect2(0, 0, 0, BAR_TH), UI.box(Pal.ACCENT, 4))
	if tick >= 0.0:
		r["tick"] = UI.panel(r["track"], Rect2(bw * tick - 1, -3, 2, BAR_TH + 6), UI.box(Pal.TEXT_2, 0))
	r["value"] = UI.label(self, Rect2(c["x"] + c["w"] - PAD - VAL_W, y, VAL_W, rh), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
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
	for k in range(CHAIN_ROWS):
		c["chain"].append(_bar_row(c, y + 116 + k * CHAIN_H, -1.0, CHAIN_H))
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
		@warning_ignore("integer_division")
		var ty: float = y + 40 + (k / 2) * (TILE_H + GAP)
		var t := {}
		t["panel"] = UI.panel(self, Rect2(tx, ty, tw, TILE_H), UI.box(Pal.BG, 6))
		t["glyph"] = _glyph(Rect2(tx + 12, ty + 8, 20, 20), glyphs[k], Pal.ACCENT)
		t["value"] = UI.label(self, Rect2(tx + 12, ty + 26, tw - 24, 32), "", "SemiBold", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
		t["key"] = UI.label(self, Rect2(tx + 12, ty + 56, tw - 24, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["tiles"].append(t)
	c["status"] = _small(c, y + c["h"] - 30)
	collection_button = UI.button(self, Rect2(c["x"] + c["w"] - PAD - COLL_BTN_W, y + 6, COLL_BTN_W, 30), false)
	collection_button.text = Words.COLLECTION["button"]
	collection_button.add_theme_font_size_override("font_size", Pal.CELL_TEXT)
	collection_button.pressed.connect(show_collection)


func _build_last() -> void:
	var c: Dictionary = cards["last"]
	var y: float = c["y"]
	c["edge"] = UI.panel(self, Rect2(c["x"], y + 1, 4, c["h"] - 2), UI.box(Pal.GOOD, 2))
	c["headline"].add_theme_font_size_override("font_size", Pal.TITLE + 4)
	c["rows"] = []
	var keys := ["where", "skull", "dmg", "cash", "clock"]
	for k in range(keys.size()):
		c["rows"].append(_row(c, y + 88 + k * ROW_H, keys[k]))
	fight_button = UI.button(self, Rect2(c["x"] + c["w"] - PAD - FIGHT_BTN_W, y + 8, FIGHT_BTN_W, 34), false)
	fight_button.text = Words.FIGHT_BUTTON
	fight_button.add_theme_font_size_override("font_size", Pal.CELL_TEXT)
	fight_button.pressed.connect(show_fight)
	c["status"] = UI.label(self, Rect2(c["x"] + PAD, y + c["h"] - 32, c["w"] - 2 * PAD, 26), "", "Medium", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)


func _build_wall() -> void:
	var c: Dictionary = cards["wall"]
	var y: float = c["y"]
	c["sub"] = UI.label(self, Rect2(PAD, y + 76, 262, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
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
	var split: Dictionary = sim.damage_split()     # the one figure: the hits and the dots together (16 Oct, item 14)
	band.set_words("Stats · %s" % (sim.cls if sim.cls != "" else "no past yet"), "", "", [""])     # the level is THE RUNNER's, the dmg/s ATTACK's (18 Oct, said once)
	People.show(_band_face, sim.cls)
	_show_runner(lv)
	_show_attack(lv, dps, split)
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
	if lv >= Data.MAX_LEVEL:                 # at the cap: the crew's paragon (21 Oct)
		var pg: Array = sim.paragon_progress()
		c["fill"].size.x = roundf(c["track"].size.x * clampf(pg[0] / maxf(1.0, pg[1]), 0.0, 1.0))
		c["xp"].text = "%s / %s XP to paragon %d" % [Fmt.num(pg[0]), Fmt.num(pg[1]), sim.paragon() + 1]
	else:
		var this_xp := Data.xp_for_level(lv)
		var next_xp := Data.xp_for_level(lv + 1)
		c["fill"].size.x = roundf(c["track"].size.x * clampf((sim.xp - this_xp) / maxf(1.0, next_xp - this_xp), 0.0, 1.0))
		c["xp"].text = "%s / %s XP to level %d" % [Fmt.num(sim.xp - this_xp), Fmt.num(next_xp - this_xp), lv + 1]
	var who := []
	if not sim.wounds.is_empty():
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
		dig = "%s, level %d" % [str(sim.best_dig["site"]).trim_prefix("The "), sim.lv_at(int(sim.best_dig["tier"]), int(sim.best_dig["depth"]))]
	var rows: Array = c["rows"]
	_set_row(rows[0], "Pace", ["×%.2f" % sim.pace()])
	_set_row(rows[1], "Pack · rig", ["%d cells · %d pouch%s" % [sim.capacity(), sim.med_capacity(), "" if sim.med_capacity() == 1 else "es"], "%d · %d" % [sim.capacity(), sim.med_capacity()]])
	_set_row(rows[2], "Runs, this runner", ["%d" % sim.runner_runs])
	_set_row(rows[3], "Alive for", [Fmt.clock(alive)])
	_set_row(rows[4], "Best signal", [dig, dig.get_slice(",", 0)])
	_set_row(rows[5], "Kit worth", [Fmt.money(sim.loadout_value())], Pal.ACCENT)
	UI.fit(c["note"], [sim.next_words(true), sim.next_words(true).replace(" on the Map", ""), ""])


func _show_attack(_lv: int, dps: float, split: Dictionary) -> void:
	var c: Dictionary = cards["attack"]
	_headline(c, "%.0f" % float(split["total"]), "dmg/s", Pal.ACCENT)
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
	# the gun type's edge (29 Oct, the itemisation): what the fight pays on the hits for the primary's type, as the headline reads it
	var ex: float = sim.edge_read()
	top = maxf(top, dps * ex)
	_set_bar(c["chain"][4], edge_key(sim.equipped["Primary"]), dps * ex / top, ("×%.2f" % ex) if absf(ex - 1.0) >= 0.005 else "—", gold)
	_set_bar(c["chain"][5], "= base", dps * ex / top, "%.0f/s" % (dps * ex), Pal.ACCENT, Pal.ACCENT)     # before the types' own increases and the dots: the headline has those
	for k in range(4):
		var r: Dictionary = c["chain"][k]
		r["fill"].size.x = roundf(r["track"].size.x * clampf([steps[0], steps[1], steps[2], steps[3]][k] / top, 0.0, 1.0))     # against the top with the edge in
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
	var first_pct: float = sim.first_pct_total()     # the fight's own figure (21 Oct)
	UI.fit(c["note"], [sim.split_words(split), sim.split_words(split, true)])     # the headline in its parts: the hits, then each dot's burn (item 14)
	var firing: String = ("%s: %s" % [Items.type_word(sim.equipped["Primary"]).left(1).to_upper() + Items.type_word(sim.equipped["Primary"]).substr(1), Items.edge_words(sim.equipped["Primary"]).get_slice(" · ", 0)]) if (sim.equipped["Primary"] != null and Items.edge_words(sim.equipped["Primary"]) != "") else (("Firing %s" % {"rifle": "a rifle", "shotgun": "a shotgun", "improvised": "something improvised", "pistol": "a pistol", "melee": "a blade"}.get(sim.gun_type(), sim.gun_type())) if sim.gun_type() != "" else "Nothing in hand")
	var extra: String = ("growth ×%.2f · first of each gang %s" % [sim.growth_mult(), signed_pct(first_pct)]) if sim.growth_mult() > 1.001 else "first of each gang %s" % signed_pct(first_pct)
	UI.fit(c["status"], ["%s · %s" % [firing, extra], firing])


## The edge row's name (the fix round, 29 Oct, the language review: "Type edge" named nothing): the primary's type, "Rifle
## edge", "SMG edge"; "Gun's edge" with none in hand.
static func edge_key(gun) -> String:
	if gun == null:
		return "Gun's edge"
	var w: String = Items.type_word(gun)
	return "%s edge" % (w.left(1).to_upper() + w.substr(1)) if w != "" else "Gun's edge"


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
	c["armour_big"].text = "%s stopped" % Fmt.pct(sim.mitigation())
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
		UI.fit(c["note"], ["Resist caps at %d%% · each point past it adds 1%% damage · ● you resist none of what sites fire" % int(Data.RESIST_CAP), "Resist caps at %d%% · each point past it adds 1%% damage" % int(Data.RESIST_CAP), "Resist caps at %d%%" % int(Data.RESIST_CAP)])
		c["note"].add_theme_color_override("font_color", Pal.TEXT_3)
	else:
		# Guard (12 Oct): its cap and where it comes from, in its own colour; the cap's note is the bars' ticks
		var cap: int = int(round(sim.guard_cap()))
		UI.fit(c["note"], ["Guard (a shield over HP) up to %d: %s" % [cap, ", ".join(gs)], "Guard up to %d: %s" % [cap, ", ".join(gs)], "Guard to %d: %s" % [cap, gs[0] + (" +%d" % (gs.size() - 1) if gs.size() > 1 else "")], "Guard up to %d" % cap])
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
	_set_row(c["rows"][0], "Search", [("%.0f%% faster" % search_faster) if search_faster > 0.5 else "no bonus"])
	_set_row(c["rows"][1], "Gangs", [("%.0f%% later" % patrol_later) if patrol_later > 0.5 else ("never" if sim.has_node("never_there") else "no bonus")])
	c["status"].text = dog_words(sim)


## The Kennel's line.
static func dog_words(s) -> String:
	var finds: int = (1 if s.yard_has("a_dog") else 0) + (1 if s.yard_has("second_dog") else 0) + (2 if s.yard_has("pack") else 0)
	if finds > 0:
		return "The dogs find +%d a search" % finds if finds > 1 else "A dog finds +1 a search"
	return "No dog yet: built at the Kennel in the Yard" if s.yard_side("kennel", 0) == "" else "A dog with a nose for it"


func _show_record() -> void:
	var c: Dictionary = cards["record"]
	var rec: Dictionary = sim.record
	_headline(c, "", "")
	c["headline"].visible = false
	c["unit"].visible = false
	var t: Array = c["tiles"]
	var find: String = str(rec.get("find", ""))
	_tile(t[0], ["%d" % int(rec.get("kills", 0))], "most kills, a run")
	_tile(t[1], [Fmt.num(float(rec.get("dealt", 0.0)))], "most damage, a run")
	_tile(t[2], [Fmt.money(float(rec.get("cash", 0.0)))], "the best take")
	_tile(t[3], [find, find.get_slice(" ", find.count(" "))] if find != "" else ["nothing yet"], ("dearest find · %s" % Fmt.money(float(rec.get("find_value", 0)))) if find != "" else "the dearest find", Pal.ACCENT if find != "" else Pal.TEXT_3)
	var seen: int = sim.operators_lost - int(rec.get("deaths_seen", 0))
	c["status"].text = ("%d lost on their watch" % seen) if seen > 0 else "no one lost on their watch"     # runs and time alive are THE RUNNER's rows (18 Oct, said once)


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
		fight_button.visible = false
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
	var fb: Dictionary = r.get("fight", {})
	var per_s: float = float(fb.get("dealt", 0.0)) / maxf(float(fb.get("s", 0.0)), 1.0)
	_set_row(rows[2], "Damage", ["%s · %s/s" % [Fmt.num(float(fb.get("dealt", r.get("dealt", 0.0)))), Fmt.num(per_s)], Fmt.num(float(fb.get("dealt", r.get("dealt", 0.0))))])
	_set_row(rows[3], "Tins · scrap", ["%s · %d" % [Fmt.money(r["cash"]), int(r.get("scrap", 0))]])
	_set_row(rows[4], "Loot · time", ["%d item%s · %s" % [r["loot"], "" if int(r["loot"]) == 1 else "s", Fmt.mss(r["time"])], Fmt.mss(r["time"])])
	fight_button.visible = not fb.is_empty()
	var status: String = ""
	if dead:
		status = ("Lost %s, one carried" if r.has("carried") else "Lost %s of kit") % Fmt.money(r["lost_value"])
	elif timed_out:
		status = "Out of time: the pack and up to %d pieces of kit lost" % Data.CLOCK_LOSE_KIT
	elif r.get("wounded", false):
		status = "Wounded: seen to at the Clinic"
	elif r.get("way_out", false):
		status = "Left by the way out"
	c["status"].text = status
	c["status"].add_theme_color_override("font_color", Pal.BAD if (dead or r.get("wounded", false)) else (Pal.ACCENT if timed_out else Pal.TEXT_2))


func _show_wall() -> void:
	var c: Dictionary = cards["wall"]
	_headline(c, "%d" % sim.operators_lost, "lost")
	UI.fit(c["sub"], ["%s runs, every runner" % Fmt.group(sim.runs_total), "%s runs in all" % Fmt.group(sim.runs_total), "%s runs" % Fmt.group(sim.runs_total)])
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
		UI.fit(p["line"], ["%s runs · %s" % [Fmt.group(int(past["runs"])), end], "%s runs · %s" % [Fmt.group(int(past["runs"])), "lost" if lost else end.get_slice(" ", 0)], "%s runs" % Fmt.group(int(past["runs"]))])
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


# ------------------------------------------------------------------ the fight's breakdown (24 Oct, the endgame chase)

const FIGHT_BTN_W := 150
const FIGHT_W := 1100
const FIGHT_H := 560
const SRC_W := 560
const SRC_LABEL_W := 230
const SRC_VAL_W := 96
const TOOK_LABEL_W := 96
const TOOK_VAL_W := 78
const PCT_W := 46


## The last run's fight over the room: the damage by source, what hit you, the skills. Built fresh each time it opens.
func show_fight() -> void:
	hide_fight()
	hide_collection()
	var r = sim.last_report
	if r == null or not (r is Dictionary) or not r.has("fight"):
		return
	var fb: Dictionary = r["fight"]
	_fight_labels = []
	var x0: float = (W - FIGHT_W) / 2.0
	var y0: float = R1_Y + 20
	fight_panel = UI.panel(self, Rect2(x0, y0, FIGHT_W, FIGHT_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	fight_panel.mouse_filter = Control.MOUSE_FILTER_STOP     # the room's cards under it take no click (the review)
	var p := fight_panel
	var t: Dictionary = sim.tier(int(r["tier"]))
	_fl(p, Rect2(22, 16, 640, 34), [Words.FIGHT_TITLE % t["name"], str(t["name"])], "SemiBold", Pal.LINE, Pal.TEXT)
	_fl(p, Rect2(560, 22, FIGHT_W - 582, 26), [Words.FIGHT_SUB % [Fmt.mss(float(fb.get("s", 0.0))), int(r["kills"]), int(r.get("patrols", 0))], "%s fighting" % Fmt.mss(float(fb.get("s", 0.0)))], "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT)
	var dealt: float = float(fb.get("dealt", 0.0))
	var took_total := 0.0
	for ty in fb.get("took", {}):
		took_total += float(fb["took"][ty])
	var heads: Array = [Fmt.num(dealt), Fmt.num(dealt / maxf(float(fb.get("s", 0.0)), 1.0)), Fmt.num(took_total), "%d%%" % roundi(float(fb.get("stopped", 0.0)) * 100.0), "%d" % int(fb.get("meds", 0))]
	for k in range(heads.size()):
		_fl(p, Rect2(22 + k * 170, 58, 160, 20), [Words.FIGHT_HEADS[k]], "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_3)
		_fl(p, Rect2(22 + k * 170, 76, 160, 32), [heads[k]], "SemiBold", Pal.FLOOR, Pal.TEXT)
	# the sources
	_fl(p, Rect2(22, 120, SRC_W, 20), [Words.FIGHT_SRC.to_upper()], "Medium", Pal.CELL_TEXT - 2, Pal.TEXT_3)
	var rows: Array = fb.get("src", [])
	for k in range(rows.size()):
		var y: float = 146 + k * 32
		var amt: float = float(rows[k][1])
		var frac: float = clampf(amt / maxf(dealt, 1.0), 0.0, 1.0)
		_fight_bar(p, 22, y, SRC_W, SRC_LABEL_W, SRC_VAL_W, str(rows[k][0]), Fmt.num(amt), frac, _src_tone(str(rows[k][0])))
	# what hit you
	var tx: float = 22 + SRC_W + 40
	var tw: float = FIGHT_W - tx - 22
	_fl(p, Rect2(tx, 120, tw, 20), [Words.FIGHT_TOOK.to_upper()], "Medium", Pal.CELL_TEXT - 2, Pal.TEXT_3)
	var types: Array = fb.get("took", {}).keys()
	types.sort_custom(func(a, b): return float(fb["took"][a]) > float(fb["took"][b]))
	for k in range(mini(types.size(), 6)):
		var ty: String = str(types[k])
		var amt2: float = float(fb["took"][ty])
		_fight_bar(p, tx, 146 + k * 32, tw, TOOK_LABEL_W, TOOK_VAL_W, str(Words.TOOK_WORDS.get(ty, ty.capitalize())), Fmt.num(amt2), clampf(amt2 / maxf(took_total, 1.0), 0.0, 1.0), Pal.tone_color(ty) if ty != "physical" else Pal.TEXT)
	# the skills
	var sy: float = 146 + maxi(3, mini(types.size(), 6)) * 32 + 14
	_fl(p, Rect2(tx, sy, tw, 20), [Words.FIGHT_SKILLS.to_upper()], "Medium", Pal.CELL_TEXT - 2, Pal.TEXT_3)
	var sks: Array = fb.get("skills", [])
	if sks.is_empty():
		_fl(p, Rect2(tx, sy + 26, tw, 26), [Words.FIGHT_NONE], "Regular", Pal.CELL_TEXT, Pal.TEXT_3)
	for k in range(mini(sks.size(), 3)):
		_fl(p, Rect2(tx, sy + 26 + k * 28, tw * 0.5, 26), [str(sks[k][0])], "Regular", Pal.CELL_TEXT, Pal.TEXT)
		_fl(p, Rect2(tx + tw * 0.4, sy + 26 + k * 28, tw * 0.6, 26), ["%d use%s · %s" % [int(sks[k][1]), "" if int(sks[k][1]) == 1 else "s", Fmt.num(float(sks[k][2]))], "%d · %s" % [int(sks[k][1]), Fmt.num(float(sks[k][2]))]], "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT)
	var close := UI.button(p, Rect2(FIGHT_W - 22 - 140, FIGHT_H - 22 - 46, 140, 46), false)
	close.text = Words.FIGHT_CLOSE
	close.pressed.connect(hide_fight)


func hide_fight() -> void:
	if fight_panel != null and is_instance_valid(fight_panel):
		fight_panel.queue_free()
	fight_panel = null
	_fight_labels = []


func _fl(parent: Node, rect: Rect2, options: Array, weight: String, fs: int, tone: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l: Label = UI.label(parent, rect, str(options[0]), weight, fs, tone, align, false)
	UI.fit(l, options)
	_fight_labels.append(l)
	return l


func _fight_bar(p: Node, x: float, y: float, w: float, lw: float, vw: float, words: String, val: String, frac: float, tone: Color) -> void:
	_fl(p, Rect2(x, y, lw, 26), [words, words.get_slice(" · ", 0)], "Regular", Pal.CELL_TEXT, Pal.TEXT)
	var bx: float = x + lw + 8
	var bw: float = w - lw - 8 - vw - PCT_W - 8
	UI.panel(p, Rect2(bx, y + 9, bw, BAR_TH), UI.box(Pal.BG, 4))
	if frac > 0.0:
		UI.panel(p, Rect2(bx, y + 9, maxf(4.0, bw * frac), BAR_TH), UI.box(tone, 4))
	_fl(p, Rect2(x + w - vw - PCT_W, y, vw, 26), [val], "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	_fl(p, Rect2(x + w - PCT_W, y, PCT_W, 26), ["%d%%" % roundi(frac * 100.0)], "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT)


## A source's bar colour: an element's damage over time in its colour, a skill amber, a gun plain.
func _src_tone(words: String) -> Color:
	for k in Words.BREAKDOWN:
		if str(k).begins_with("dot:") and words == str(Words.BREAKDOWN[k]):
			return Pal.tone_color(str(k).trim_prefix("dot:"))
	if words.contains(" · ") and words.contains("use"):
		return Pal.ACCENT
	return Pal.TEXT


## The breakdown's labels, for the fit checks.
func fight_text_nodes() -> Array:
	return _fight_labels.filter(func(l): return is_instance_valid(l))


# ------------------------------------------------------------------ the collection (24 Oct, the endgame chase, phase 6)

const COLL_BTN_W := 190
const COLL_W := 1100
const COLL_H := 880
const COLL_TILE_H := 84
const COLL_COLS := 4                        # the uniques' names, in columns
const COLL_ROW := 24                         # 26 to 24 (29 Oct: the gloves' two uniques put a fourteenth row in the grid)
const COLL_MARK_W := 30


## Over the room, as the fight's breakdown: six tiles, every unique (found in colour, the rest "?" and the slot), every
## site's marks by depth. Nothing here gives power.
func show_collection() -> void:
	hide_collection()
	hide_fight()
	var col: Dictionary = sim.collection()
	_coll_labels = []
	collection_panel = UI.panel(self, Rect2((W - COLL_W) / 2.0, (H - COLL_H) / 2.0, COLL_W, COLL_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	collection_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var p := collection_panel
	var inner: float = COLL_W - 44
	_cl(p, Rect2(22, 14, 500, 40), [Words.COLLECTION["title"]], "SemiBold", Pal.LINE, Pal.TEXT)
	_cl(p, Rect2(22, 54, 600, 24), [Words.COLLECTION["sub"]], "Regular", Pal.CELL_TEXT, Pal.TEXT_3)
	var close := UI.button(p, Rect2(COLL_W - 22 - 140, 16, 140, 44), false)
	close.text = Words.COLLECTION["close"]
	close.pressed.connect(hide_collection)
	_coll_labels.append(close)
	# the tiles: three a row
	var tw: float = (inner - 2 * GAP) / 3.0
	var tones := {"uniques": Pal.tone_color("unique"), "mythics": Pal.MYTHIC, "sites": Pal.ACCENT, "classes": Pal.GOOD, "order": Pal.ACCENT, "sets": Pal.tone_color("set")}
	var tiles: Array = col["tiles"]
	for k in range(tiles.size()):
		var key: String = str(tiles[k][0])
		var n: int = int(tiles[k][1])
		var of: int = int(tiles[k][2])
		@warning_ignore("integer_division")
		var tx: float = 22 + (k % 3) * (tw + GAP)
		@warning_ignore("integer_division")
		var ty: float = 92 + (k / 3) * (COLL_TILE_H + GAP)
		UI.panel(p, Rect2(tx, ty, tw, COLL_TILE_H), UI.box(Pal.BG, 6))
		_cl(p, Rect2(tx + 12, ty + 6, tw - 24, 22), [Words.COLLECTION[key]], "Regular", Pal.CELL_TEXT, Pal.TEXT_3)
		var num := _cl(p, Rect2(tx + 12, ty + 28, 90, 34), ["%d" % n], "SemiBold", Pal.LINE, Pal.TEXT)
		num.size.x = ceilf(UI.text_width(num, num.text)) + 2
		_cl(p, Rect2(tx + 12 + num.size.x + 6, ty + 36, 120, 24), [Words.COLLECTION["of"] % of], "Regular", Pal.CELL_TEXT, Pal.TEXT_3)
		var track := UI.panel(p, Rect2(tx + 12, ty + COLL_TILE_H - 16, tw - 24, 6), UI.box(Pal.BUTTON, 3))
		UI.panel(track, Rect2(0, 0, roundf((tw - 24) * clampf(float(n) / maxf(of, 1), 0.0, 1.0)), 6), UI.box(tones.get(key, Pal.ACCENT), 3))
	# the uniques
	var uq: Array = col["uniques"]
	var gy: float = 92 + 2 * (COLL_TILE_H + GAP) + 12
	_cl(p, Rect2(22, gy, inner, 22), [Words.COLLECTION["grid_head"].to_upper()], "Medium", Pal.CELL_TEXT - 2, Pal.TEXT_3)
	var cw: float = (inner - (COLL_COLS - 1) * 8) / COLL_COLS
	@warning_ignore("integer_division")
	var per_col: int = (uq.size() + COLL_COLS - 1) / COLL_COLS
	for k in range(uq.size()):
		@warning_ignore("integer_division")
		var cx: float = 22 + (k / per_col) * (cw + 8)
		var cy: float = gy + 28 + (k % per_col) * COLL_ROW
		var found: bool = bool(uq[k][2])
		var l := _cl(p, Rect2(cx, cy, cw, COLL_ROW), [str(uq[k][0])] if found else [Words.COLLECTION["unfound"] % str(uq[k][1])], "Regular", Pal.CELL_TEXT - 1, Pal.tone_color("unique") if found else Pal.TEXT_3)
		l.tooltip_text = "" if found else str(uq[k][1])
	# the sites: a mark at each depth, two columns
	var sy: float = gy + 28 + per_col * COLL_ROW + 14
	_cl(p, Rect2(22, sy, inner, 22), [(Words.COLLECTION["sites_head"] % ", ".join(Data.COLLECTION_LEVELS.map(func(x): return str(x)))).to_upper()], "Medium", Pal.CELL_TEXT - 2, Pal.TEXT_3)
	var sites: Array = col["sites"]
	@warning_ignore("integer_division")
	var half: int = (sites.size() + 1) / 2
	var colw: float = (inner - 24) / 2.0
	for k in range(sites.size()):
		@warning_ignore("integer_division")
		var sx: float = 22 + (k / half) * (colw + 24)
		var ry: float = sy + 28 + (k % half) * COLL_ROW
		var d: int = int(sites[k][1])
		_cl(p, Rect2(sx, ry, 210, COLL_ROW), [str(sites[k][0])], "Regular", Pal.CELL_TEXT - 1, Pal.TEXT)
		for m in range(Data.COLLECTION_LEVELS.size()):
			UI.panel(p, Rect2(sx + 216 + m * (COLL_MARK_W + 4), ry + 6, COLL_MARK_W, COLL_ROW - 12), UI.box(Pal.ACCENT if d >= int(Data.COLLECTION_LEVELS[m]) else Pal.BUTTON, 3))
		var dx: float = sx + 216 + Data.COLLECTION_LEVELS.size() * (COLL_MARK_W + 4) + 6
		_cl(p, Rect2(dx, ry, colw - (dx - sx), COLL_ROW), [Words.COLLECTION["level"] % d if d > 0 else Words.COLLECTION["none"]], "Regular", Pal.CELL_TEXT - 2, Pal.TEXT_3)


func hide_collection() -> void:
	if collection_panel != null and is_instance_valid(collection_panel):
		collection_panel.queue_free()
	collection_panel = null
	_coll_labels = []


func _cl(parent: Node, rect: Rect2, options: Array, weight: String, fs: int, tone: Color) -> Label:
	var l: Label = UI.label(parent, rect, str(options[0]), weight, fs, tone, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.fit(l, options)
	_coll_labels.append(l)
	return l


## For the tests: every label and button the collection shows.
func collection_text_nodes() -> Array:
	return _coll_labels.filter(func(l): return is_instance_valid(l))
