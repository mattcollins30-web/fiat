extends Control
## The Missions screen, between missions: a column per tier of the zone,
## everything about that mission in one place - depth, the hostiles, the
## odds, the intel - and the Deploy and Auto buttons at the foot. While the
## operator is out, main.gd shows the live cards instead. Fixed geometry in
## the card grid's 1536 x 864, like the Armoury and the Barracks.

signal acted

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")

const COL_GAP := 16
const COL_W := (Pal.GRID_W - 2 * COL_GAP) / 3                 # 501
const PAD := 20
const INNER := COL_W - 2 * PAD                                # 461
const LINE_H := 28
const BOSS_W := 150                # the boss toggle beside Set off
const DEPTH_BTN := 72
const CHIPS := 4
const CHIP_H := 26
const CHIP_PAD := 8
const CHIP_GAP := 6

var sim
var zone := 0                      # the zone whose tiers the columns show
var _zone_buttons: Array = []
var _cols: Array = []              # per column: the labels and buttons
var _shown := ""
var _map: Panel                    # the map: the endgame's tree, in place of the columns
var _map_title: Label
var _map_words: Label
var _map_rows: Array = []          # per passive: {name, words, rank, button}
var _map_reset: Button
const MAP := 3                     # the fourth button on the zone row
const MAP_ROW_H := 72
const ZONE_H := 56
const TOP := ZONE_H + 16


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	# the zones, as a row of buttons across the top
	var zw := (Pal.GRID_W - COL_GAP * Data.ZONES.size()) / (Data.ZONES.size() + 1)
	for z in range(Data.ZONES.size() + 1):
		var b := UI.button(self, Rect2(z * (zw + COL_GAP), 0, zw, ZONE_H), false)
		b.text = Data.ZONES[z]["name"] if z < Data.ZONES.size() else "The map"
		b.pressed.connect(_pick_zone.bind(z))
		_zone_buttons.append(b)
	# the map: one panel, a row a passive, its rank and a button to take one
	_map = UI.panel(self, Rect2(0, TOP, Pal.GRID_W, Pal.ROOM_H - TOP), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_map.visible = false
	_map_title = UI.label(_map, Rect2(PAD, 16, Pal.GRID_W - 2 * PAD, 40), "The map", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_map_words = UI.label(_map, Rect2(PAD, 58, Pal.GRID_W - 2 * PAD, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var my := 110
	for a in Data.ATLAS:
		var r := {}
		r["name"] = UI.label(_map, Rect2(PAD, my, 300, 30), a["name"], "SemiBold", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["words"] = UI.label(_map, Rect2(PAD, my + 30, Pal.GRID_W - 2 * PAD - 400, 28), a["words"], "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["rank"] = UI.label(_map, Rect2(Pal.GRID_W - PAD - 410, my, 200, 30), "", "Medium", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
		r["button"] = UI.button(_map, Rect2(Pal.GRID_W - PAD - 190, my - 4, 190, Pal.BUTTON_H), false)
		r["button"].text = "Take a rank"
		r["button"].pressed.connect(_rank.bind(a["key"]))
		_map_rows.append(r)
		my += MAP_ROW_H
	_map_reset = UI.button(_map, Rect2(PAD, Pal.ROOM_H - TOP - PAD - Pal.BUTTON_H, 290, Pal.BUTTON_H), false)
	_map_reset.text = "Start the map again"
	_map_reset.pressed.connect(_reset_map)
	for col in range(3):
		var x := col * (COL_W + COL_GAP)
		var panel := UI.panel(self, Rect2(x, TOP, COL_W, Pal.ROOM_H - TOP), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
		var edge := StyleBoxFlat.new()
		edge.bg_color = Pal.GOOD
		edge.corner_radius_top_left = 8
		edge.corner_radius_bottom_left = 8
		var c := {"panel": panel, "edge": UI.panel(self, Rect2(x, TOP, 6, Pal.ROOM_H - TOP), edge)}
		var y := 16
		c["tier"] = UI.label(panel, Rect2(PAD, y, INNER, 28), "", "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		y += 30
		c["name"] = UI.label(panel, Rect2(PAD, y, INNER, 40), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		y += 46
		# the odds, big
		c["odds"] = UI.label(panel, Rect2(PAD, y, INNER, 52), "", "SemiBold", Pal.HEADLINE, Pal.TEXT)
		c["odds_unit"] = UI.label(panel, Rect2(PAD, y, INNER, 52), "", "Medium", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
		y += 58
		# the depth, with its buttons either side of the figure
		c["depth_label"] = UI.label(panel, Rect2(PAD, y, 120, Pal.BUTTON_H), "Depth", "Regular", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["depth_down"] = UI.button(panel, Rect2(PAD + INNER - 2 * DEPTH_BTN - 8 - 150, y, DEPTH_BTN, Pal.BUTTON_H), false)
		c["depth_down"].text = "−"
		c["depth_down"].pressed.connect(_depth.bind(col, -1))
		c["depth"] = UI.label(panel, Rect2(PAD + INNER - DEPTH_BTN - 8 - 150, y, 150, Pal.BUTTON_H), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		c["depth_up"] = UI.button(panel, Rect2(PAD + INNER - DEPTH_BTN, y, DEPTH_BTN, Pal.BUTTON_H), false)
		c["depth_up"].text = "+"
		c["depth_up"].pressed.connect(_depth.bind(col, 1))
		y += Pal.BUTTON_H + 12
		# the figures
		c["lines"] = []
		for k in range(5):
			var l := UI.label(panel, Rect2(PAD, y, INNER, LINE_H), "", "Regular", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			var v := UI.label(panel, Rect2(PAD, y, INNER, LINE_H), "", "Medium", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
			c["lines"].append([l, v])
			y += LINE_H
		# what they fire, as chips in the element's colour, with your resist to each
		y += 2
		c["chips"] = []
		c["chip_labels"] = []
		for k in range(CHIPS):
			var cp := UI.panel(panel, Rect2(PAD, y, 10, CHIP_H), UI.box(Pal.BUTTON, 6))
			cp.visible = false
			c["chips"].append(cp)
			c["chip_labels"].append(UI.label(cp, Rect2(CHIP_PAD, 0, 10, CHIP_H), "", "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		y += CHIP_H + 8
		# the intel
		c["intel_head"] = UI.label(panel, Rect2(PAD, y, INNER, 28), "Word", "SemiBold", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		y += 28
		c["intel"] = []
		for k in range(3):                     # the radio's two, and the sky's
			var n := UI.label(panel, Rect2(PAD, y, INNER, 28), "", "SemiBold", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			var w := UI.label(panel, Rect2(PAD, y + 28, INNER, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			c["intel"].append([n, w])
			y += 56
		c["intel_note"] = UI.label(panel, Rect2(PAD, y, INNER, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		# the foot: Deploy across, Auto under it
		var fy := Pal.ROOM_H - TOP - PAD - Pal.BUTTON_H
		c["auto"] = UI.button(panel, Rect2(PAD, fy, INNER - BOSS_W - 8, Pal.BUTTON_H), false)
		c["auto"].pressed.connect(_auto.bind(col))
		# insurance: the fence holds the paper on the kit for the next run
		c["insure"] = UI.button(panel, Rect2(PAD + INNER - BOSS_W, fy, BOSS_W, Pal.BUTTON_H), false)
		c["insure"].pressed.connect(_insure.bind(col))
		fy -= Pal.BUTTON_H + 12
		c["deploy"] = UI.button(panel, Rect2(PAD, fy, INNER, Pal.BUTTON_H), true)
		c["deploy"].text = "Set off"
		c["deploy"].pressed.connect(_deploy.bind(col))
		# the zone's last site has its boss: a toggle beside Set off takes them on
		c["boss"] = UI.button(panel, Rect2(PAD + INNER - BOSS_W, fy, BOSS_W, Pal.BUTTON_H), false)
		c["boss"].pressed.connect(_boss.bind(col))
		c["boss"].visible = false
		c["note"] = UI.label(panel, Rect2(PAD, fy - 36, INNER, 30), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		# the site's own line at this depth, two rows under the word, above the note
		c["site"] = []
		for k in range(2):
			c["site"].append(UI.label(panel, Rect2(PAD, y + 32 + k * 21, INNER, 21), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		_cols.append(c)


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	# the odds read a few dry runs a refresh (the shell's budget) until every open tier has settled
	var settled := ""
	for i in range(Data.TIERS.size()):
		if sim.tier_open(i) and not sim.odds_settled(i):
			sim.survival(i)
		settled += "1" if sim.odds_settled(i) else "0"
	var sig := "%s|%s|%s|%d|%d|%d|%d|%d|%d|%d|%s" % [str(sim.depth), str(sim.best_depth), str(sim.intel) + str(sim.weather) + str(int(sim.elapsed / 60.0)) + settled, sim.auto_tier,
			int(sim.hp), sim.best_tier, int(sim.dps()), int(sim.armour()), sim.tree.size(), zone, str(sim.depot_cleared)] + "|%d|%s|%s|%s|%s|%d" % [sim.notes, str(sim.boss_armed), str(sim.bosses_beaten), str(sim.campaign_done()), str(sim.atlas), sim.atlas_points] + "|%s|%d" % [str(sim.insure_next), int(sim.cash) / 50]
	if sig == _shown:
		return
	_shown = sig
	for z in range(Data.ZONES.size()):
		var zb: Button = _zone_buttons[z]
		var open_z: bool = sim.zone_open(z)
		zb.text = Data.ZONES[z]["name"] if open_z else "%s · locked" % Data.ZONES[z]["name"]
		zb.disabled = not open_z
		UI.style_button(zb, z == zone)
	var mb: Button = _zone_buttons[MAP]
	mb.text = "The map" if sim.campaign_done() else "The map · locked"
	mb.disabled = not sim.campaign_done()
	UI.style_button(mb, zone == MAP)
	_map.visible = zone == MAP
	for c in _cols:
		c["panel"].visible = zone != MAP
		c["edge"].visible = zone != MAP
	if zone == MAP:
		_show_map()
		return
	var tiers: Array = Data.ZONES[zone]["tiers"]
	for k in range(3):
		var i: int = tiers[k]
		var c: Dictionary = _cols[k]
		c["tier"].text = "Tier %d · %s" % [k + 1, Data.ZONES[zone]["name"]]
		c["name"].text = Data.TIERS[i]["name"]
		var t: Dictionary = sim.effective(i)
		var is_open: bool = sim.tier_open(i)
		var odds: float = sim.survival(i) if is_open else 0.0
		var tone := "good" if odds >= 0.9 else ("warn" if odds >= 0.6 else "bad")
		c["edge"].visible = is_open
		(c["edge"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.tone_color(tone)
		c["name"].add_theme_color_override("font_color", Pal.TEXT if is_open else Pal.TEXT_3)
		if is_open:
			c["odds"].text = Fmt.pct(odds)
			# still reading: dimmer, and the screen keeps refreshing until it's settled
			c["odds"].add_theme_color_override("font_color", Pal.tone_color(tone) if sim.odds_settled(i) else Pal.TEXT_3)
			c["odds_unit"].text = "to clear the fight" if sim.odds_settled(i) else "reading the odds"
		else:
			c["odds"].text = "Locked"
			c["odds"].add_theme_color_override("font_color", Pal.TEXT_3)
			c["odds_unit"].text = "clear tier %d first" % k
		# the depth ladder is the endgame's: until the campaign's done it reads as such
		var endgame: bool = sim.campaign_done()
		c["depth"].text = ("%d of %d" % [t["depth"], sim.best_depth[i] + 1]) if endgame else "Locked"
		c["depth_down"].visible = endgame
		c["depth_up"].visible = endgame
		# between its buttons when the ladder's open; across the row, right-justified, when it's locked
		c["depth"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if endgame else HORIZONTAL_ALIGNMENT_RIGHT
		c["depth"].position.x = (PAD + INNER - DEPTH_BTN - 8 - 150) if endgame else (PAD + 120)
		c["depth"].size.x = 150 if endgame else (INNER - 120)
		c["depth_down"].disabled = not is_open or sim.on_mission() or t["depth"] <= 1
		c["depth_up"].disabled = not is_open or sim.on_mission() or t["depth"] > sim.best_depth[i]
		var rows := [
			["Them", "%d × %.0f HP" % [t["pool"], t["hp"]]],
			["Their fire", "%.1f/s each" % t["dps"]],
			["Fight takes", Fmt.mss(sim.estimate(i))],
			["Drops up to", "tier %d gear" % t["loot_tier"]],
			["Rewards", "×%.1f" % pow(1.0 + Data.DEPTH_REWARD, t["depth"] - 1)],
		]
		var res_words := []
		for ty in Data.ELEMENTS:
			if float(t.get("res", {}).get(ty, 0.0)) > 0.0:
				res_words.append("%s %.0f%%" % [ty, float(t["res"][ty]) * 100.0])
		if sim.wear(i) > 0.0:
			rows[4] = ["The site", sim.site_state(i)]
		elif not res_words.is_empty():
			rows[4] = ["They resist", ", ".join(res_words)]
		for r in range(5):
			c["lines"][r][0].text = rows[r][0]
			# the value beside its label: whole, then fewer of its clauses, the rest as "+N"
			var clauses: PackedStringArray = str(rows[r][1]).split(", ", false)
			var options := []
			for n in range(clauses.size(), 0, -1):
				options.append(", ".join(clauses.slice(0, n)) + ((" +%d" % (clauses.size() - n)) if n < clauses.size() else ""))
			var label_w: float = UI.text_width(c["lines"][r][0], rows[r][0]) + 16.0
			var picked: String = options.back()
			for o in options:
				if label_w + UI.text_width(c["lines"][r][1], o) <= INNER:
					picked = o
					break
			c["lines"][r][1].text = picked
		_show_chips(c, t, is_open)
		for r in range(3):
			if r < t["intel"].size():
				var m: Dictionary = sim.modifier(t["intel"][r])
				c["intel"][r][0].text = m["name"]
				c["intel"][r][1].text = m["words"]
			else:
				c["intel"][r][0].text = ""
				c["intel"][r][1].text = ""
		UI.fit(c["intel_note"], ["%s · %s" % [sim.sky_words(i), "pinned at the radio" if sim.pinned[i] else "new word after every run"], sim.sky_words(i)])
		var auto: bool = sim.auto_tier == i
		c["deploy"].visible = is_open
		c["deploy"].disabled = not sim.can_deploy_to(i) or (t.has("boss") and sim.notes < sim.boss_cost(i))
		var boss: Dictionary = sim.boss_of(i)
		var convoy: bool = sim.is_convoy(i)
		if convoy:
			boss = {"name": "The convoy"}
		elif not boss.is_empty() and sim.is_pinnacle(i):
			boss = {"name": "%s, at full strength" % boss["name"]}
		c["boss"].visible = is_open and not boss.is_empty()
		c["deploy"].size.x = INNER - BOSS_W - 8 if c["boss"].visible else INNER
		if c["boss"].visible:
			var armed: bool = sim.boss_armed.get(i, false)
			c["boss"].text = ("Convoy ✓" if armed else "Convoy") if convoy else ("Boss ✓" if armed else "Boss")
			c["boss"].disabled = sim.on_mission() or (not armed and not sim.can_arm_boss(i))
			UI.style_button(c["boss"], false, "bad" if armed else "")
		c["auto"].visible = is_open
		c["auto"].text = "Auto-run: on" if auto else "Auto-run: off"
		UI.style_button(c["auto"], false, "good" if auto else "")
		c["insure"].visible = is_open
		var long_text: String = "Insured ✓" if sim.insure_next else "Insure %s" % Fmt.money(sim.insure_cost(i))
		c["insure"].text = long_text if UI.text_width(c["insure"], long_text) + 32 <= BOSS_W else ("Insured ✓" if sim.insure_next else "Insure")
		c["insure"].disabled = sim.on_mission() or (not sim.insure_next and not sim.can_insure(i))
		UI.style_button(c["insure"], false, "good" if sim.insure_next else "")
		if not is_open:
			c["note"].text = ""
		elif sim.hp < sim.max_hp() * 0.5:
			c["note"].text = "The runner is hurt"
		elif c["boss"].visible and sim.boss_armed.get(i, false):
			var cost: int = sim.boss_cost(i)
			UI.fit(c["note"], [("%s: free, the first time" % boss["name"]) if cost == 0 else ("%s: %d notes, you have %d" % [boss["name"], cost, sim.notes]), "%s: %d notes" % [boss["name"], cost], boss["name"]])
		elif c["boss"].visible and not sim.boss_armed.get(i, false) and sim.boss_cost(i) > 0 and sim.notes < sim.boss_cost(i):
			UI.fit(c["note"], ["%s wants %d notes; you have %d" % [boss["name"], sim.boss_cost(i), sim.notes], "%s: %d notes" % [boss["name"], sim.boss_cost(i)], "Not enough notes"])
		elif auto:
			c["note"].text = "Rests to 95%, leaves when the next gang comes"
		else:
			c["note"].text = ""
		UI.wrap(c["site"], Words.site_line(Data.TIERS[i]["name"], int(t["depth"])) if is_open else "")


# ------------------------------------------------------------------ acting

func _tier(k: int) -> int:
	return Data.ZONES[zone]["tiers"][k]


func _pick_zone(z: int) -> void:
	if (z == MAP and sim.campaign_done()) or (z < MAP and sim.zone_open(z)):
		zone = z
		show_state(sim)


func _show_map() -> void:
	var free: int = sim.atlas_free()
	_map_words.text = "%d point%s free of %d. A point for every new depth cleared past the first, on any site. What's taken here holds on every site." % [free, "" if free == 1 else "s", sim.atlas_points]
	for k in range(Data.ATLAS.size()):
		var a: Dictionary = Data.ATLAS[k]
		var r: Dictionary = _map_rows[k]
		var rank: int = sim.atlas_rank(a["key"])
		r["rank"].text = "%d of %d" % [rank, a["max"]]
		r["rank"].add_theme_color_override("font_color", Pal.TEXT if rank > 0 else Pal.TEXT_3)
		r["button"].disabled = not sim.can_rank_atlas(a["key"])
		UI.style_button(r["button"], rank > 0)
	_map_reset.disabled = sim.atlas_spent() == 0 or sim.on_mission()


func _rank(key: String) -> void:
	if sim.rank_atlas(key):
		acted.emit()
	_shown = ""
	show_state(sim)


func _reset_map() -> void:
	sim.reset_atlas()
	acted.emit()
	_shown = ""
	show_state(sim)


## What they fire, a chip an element in its colour with your resist to it;
## "Physical" alone when a site fires nothing else. Chips past the row are left off.
func _show_chips(c: Dictionary, t: Dictionary, is_open: bool) -> void:
	var chips := []
	for ty in Data.ELEMENTS:
		var share: float = float(t.get("types", {}).get(ty, 0.0))
		if share > 0.0:
			chips.append(["%s %.0f%% · you resist %.0f%%" % [ty.capitalize(), share * 100.0, sim.resist(ty) * 100.0], "%s · res %.0f%%" % [ty.capitalize(), sim.resist(ty) * 100.0], ty])
	if chips.is_empty():
		chips.append(["Physical only · armour takes %s" % Fmt.pct(sim.mitigation()), "Physical only", "physical"])
	var x := 0.0
	for k in range(CHIPS):
		var on: bool = is_open and k < chips.size()
		c["chips"][k].visible = on
		if not on:
			continue
		var l: Label = c["chip_labels"][k]
		var colour: Color = Pal.tone_color(chips[k][2])
		l.add_theme_color_override("font_color", colour)
		c["chips"][k].add_theme_stylebox_override("panel", UI.box(colour.darkened(0.72), 6))
		var w := 0.0
		for words in [chips[k][0], chips[k][1]]:
			w = ceilf(UI.text_width(l, words)) + 2 * CHIP_PAD
			l.text = words
			if x + w <= INNER:
				break
		if x + w > INNER:
			for j in range(k, CHIPS):
				c["chips"][j].visible = false
			break
		c["chips"][k].position.x = PAD + x
		c["chips"][k].size.x = w
		l.size.x = w - 2 * CHIP_PAD
		x += w + CHIP_GAP


func _depth(k: int, by: int) -> void:
	var i := _tier(k)
	sim.set_depth(i, sim.depth[i] + by)
	acted.emit()


func _auto(k: int) -> void:
	sim.set_auto(_tier(k))
	acted.emit()


func _insure(_k: int) -> void:
	sim.set_insure(not sim.insure_next)
	_shown = ""
	acted.emit()


func _deploy(k: int) -> void:
	sim.deploy(_tier(k))
	acted.emit()


func _boss(k: int) -> void:
	var i := _tier(k)
	sim.arm_boss(i, not sim.boss_armed.get(i, false))
	acted.emit()


## For the tests: every label and button with text.
func text_nodes() -> Array:
	var out: Array = []
	for zb in _zone_buttons:
		out.append(zb)
	if zone == MAP:
		out.append_array([_map_title, _map_words, _map_reset])
		for r in _map_rows:
			out.append_array([r["name"], r["words"], r["rank"], r["button"]])
		return out
	for c in _cols:
		out.append_array([c["tier"], c["name"], c["odds"], c["odds_unit"], c["depth_label"], c["depth"], c["intel_head"], c["intel_note"], c["note"]])
		out.append_array(c["site"])
		for k in range(CHIPS):
			if c["chips"][k].visible:
				out.append(c["chip_labels"][k])
		for pair in c["lines"]:
			out.append_array(pair)
		for pair in c["intel"]:
			out.append_array(pair)
		for b in [c["deploy"], c["auto"], c["depth_down"], c["depth_up"], c["boss"], c["insure"]]:
			if b.visible:
				out.append(b)
	return out


## Label/value pairs that share a line, for the fit check.
func line_pairs() -> Array:
	var out: Array = []
	for c in _cols:
		for pair in c["lines"]:
			if pair[0].text != "":
				out.append(pair)
	return out
