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
const Band := preload("res://scripts/ui/band.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const CameBack := preload("res://scripts/ui/came_back.gd")

const COL_GAP := 16
const COL_W := (Pal.GRID_W - 2 * COL_GAP) / 3                 # 501
const PAD := 20
const INNER := COL_W - 2 * PAD                                # 461
const LINE_H := 28
const BOSS_W := 150                # the boss toggle beside Set off
const DEPTH_BTN := 48              # the −/+ stacked at the depth tile's right, the endgame's ladder
const DEPTH_TILE := 4              # the depth tile's place in the six
const BAND_H := 180                # the art band at the top of a column: the rooms' one height (12 Oct: 200, the 20 paid the resists' second row)
const FIRE_W := 148                # "They fire" / "They resist" before the chips
const BOX_PAD := 10                # the outline round the fight, the elements and the word
const BOX_GAP := 9                 # between the boxes (12 Oct: 12, the 6 paid the resists' second row)
const RESIST_ROWS := 2             # what they resist wraps to a second row (12 Oct: one row dropped chips - the city showed 2 of 4)
const WORD_ROWS := 4               # the radio's two words and the sky's two, a row each

var sim
var zone := 0                      # the zone whose tiers the columns show
var _zone_set := false             # the first show opens on the furthest zone open (12 Oct: not the Outskirts every launch)
var _zone_buttons: Array = []
var _zone_art: Array = []                 # a TextureRect a tab, behind it
var _cols: Array = []              # per column: the labels and buttons
var _shown := ""
var _came                          # what came back (came_back.gd): the runs since the player last looked, under its button
var _came_btn: Button              # the tally's button at the zone row's right
var _came_open := false            # the card dropped down
# the map moved to the Radio (12 Oct): the zone row is the four zones, the Outskirts first
const ZONE_H := 56
const TOP := ZONE_H + 16


## A tab over its zone's art: a dark glass over the picture so the name reads, the picked one ringed in the
## accent instead of filled with it, a shut one darker.
func _style_art_tab(b: Button, picked: bool) -> void:
	var ring: Color = Pal.ACCENT if picked else Pal.CARD_LINE
	var w := 3 if picked else 1
	var glass := func(a: float, bw: int, c: Color) -> StyleBoxFlat:
		var sb := UI.box(Color(0, 0, 0, a), 8, bw, c)
		sb.content_margin_left = 12            # the plain tab's margins
		sb.content_margin_right = 12
		return sb
	b.add_theme_stylebox_override("normal", glass.call(0.25 if picked else 0.45, w, ring))
	b.add_theme_stylebox_override("hover", glass.call(0.15 if picked else 0.3, w, ring))
	b.add_theme_stylebox_override("pressed", glass.call(0.25, w, ring))
	b.add_theme_stylebox_override("hover_pressed", glass.call(0.25, w, ring))
	b.add_theme_stylebox_override("disabled", glass.call(0.7, 1, Pal.CARD_LINE))
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 8, 2, Pal.TEXT))
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, Pal.TEXT)
	b.add_theme_color_override("font_disabled_color", Pal.TEXT_2)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	b.add_theme_constant_override("outline_size", 4)


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	# the zones, as a row of buttons across the top
	var zw := (Pal.GRID_W - COL_GAP * (Data.ZONES.size() - 1)) / Data.ZONES.size()
	for z in range(Data.ZONES.size()):
		var art := TextureRect.new()             # the zone's painted art behind its tab (9 Oct), when there is one
		art.position = Vector2(z * (zw + COL_GAP), 0)
		art.size = Vector2(zw, ZONE_H)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.clip_contents = true
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.texture = UI.place_texture(Data.ZONES[z]["name"])
		art.visible = art.texture != null
		if art.texture != null and art.texture.get_width() > zw:
			art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR     # scaled down into the tab: smoothed
		add_child(art)
		_zone_art.append(art)
		var b := UI.button(self, Rect2(z * (zw + COL_GAP), 0, zw, ZONE_H), false)
		b.text = Data.ZONES[z]["name"]
		b.pressed.connect(_pick_zone.bind(z))
		_zone_buttons.append(b)
	# what came back (12 Oct, Matt's playtest: the card over a column "doesn't work where it is"): a button at the zone
	# row's right while there's a tally, the card dropping under it when pressed
	_came_btn = UI.button(self, Rect2(Pal.GRID_W - CAME_BTN_W, 0, CAME_BTN_W, ZONE_H), false)
	_came_btn.pressed.connect(_toggle_came)
	_came_btn.visible = false
	for col in range(3):
		var x := col * (COL_W + COL_GAP)
		var panel := UI.panel(self, Rect2(x, TOP, COL_W, Pal.ROOM_H - TOP), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
		var edge := StyleBoxFlat.new()
		edge.bg_color = Pal.GOOD
		edge.corner_radius_top_left = 8
		edge.corner_radius_bottom_left = 8
		var c := {"panel": panel, "edge": UI.panel(self, Rect2(x, TOP, 6, Pal.ROOM_H - TOP), edge)}
		# the art band: tier and zone, the site's name, the odds as the headline
		var band := Band.new(COL_W, BAND_H, zone)
		panel.add_child(band)
		c["band"] = band
		var y := BAND_H + 14
		# three boxes under the band: the fight, the elements, the word
		c["boxes"] = []
		for k in range(3):
			c["boxes"].append(UI.panel(panel, Rect2(PAD - BOX_PAD, 0, INNER + 2 * BOX_PAD, 10), UI.box(Color.TRANSPARENT, 8, 1, Pal.CARD_LINE)))
		c["boxes"][0].position.y = y
		y += BOX_PAD
		# the fight, as tiles: them, their fire, the fight's length, the drops, the depth, the rewards
		c["tiles"] = UI.tile_row(panel, PAD, y, INNER, 3) + UI.tile_row(panel, PAD, y + UI.TILE_H + 8, INNER, 3)
		var depth_tile: Dictionary = c["tiles"][DEPTH_TILE]
		c["depth_up"] = UI.button(depth_tile["panel"], Rect2(depth_tile["panel"].size.x - DEPTH_BTN - 6, 4, DEPTH_BTN, 26), false)
		c["depth_down"] = UI.button(depth_tile["panel"], Rect2(depth_tile["panel"].size.x - DEPTH_BTN - 6, 32, DEPTH_BTN, 26), false)
		c["depth_down"].text = "−"
		c["depth_down"].pressed.connect(_depth.bind(col, -1))
		for b in [c["depth_up"], c["depth_down"]]:
			b.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)     # small enough for a 26 px button
		c["depth_up"].text = "+"
		c["depth_up"].pressed.connect(_depth.bind(col, 1))
		y += 2 * UI.TILE_H + 8 + BOX_PAD
		c["boxes"][0].size.y = y - c["boxes"][0].position.y
		y += BOX_GAP
		c["boxes"][1].position.y = y
		y += BOX_PAD
		# what they fire, as chips in the element's colour, with your resist to each; what they resist, the same way
		c["fire_label"] = UI.label(panel, Rect2(PAD, y, FIRE_W - 8, Chips.CHIP_H), "They fire", "Regular", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["chips"] = Chips.new(INNER - FIRE_W)
		c["chips"].position = Vector2(PAD + FIRE_W, y)
		panel.add_child(c["chips"])
		y += Chips.CHIP_H + 8
		c["resist_label"] = UI.label(panel, Rect2(PAD, y, FIRE_W - 8, Chips.CHIP_H), "They resist", "Regular", Pal.LINE, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["resist"] = Chips.new(INNER - FIRE_W)
		c["resist"].position = Vector2(PAD + FIRE_W, y)
		panel.add_child(c["resist"])
		y += RESIST_ROWS * (Chips.CHIP_H + Chips.ROW_GAP) - Chips.ROW_GAP + BOX_PAD
		c["boxes"][1].size.y = y - c["boxes"][1].position.y
		y += BOX_GAP
		c["boxes"][2].position.y = y
		y += BOX_PAD
		# the word: the head carries the sky; a row a word, its name left and its effect right
		c["intel_head"] = UI.head(panel, Rect2(PAD, y, INNER, UI.HEAD_H), "The codes")
		y += UI.HEAD_H + 2
		# the words as toned rows: the name in its tone, its effect muted beside it, one chip a row
		c["intel"] = Chips.new(INNER)
		c["intel"].position = Vector2(PAD, y)
		panel.add_child(c["intel"])
		y += WORD_ROWS * (Chips.CHIP_H + Chips.ROW_GAP) - Chips.ROW_GAP + 8
		# the site's own line at this depth, one row (the whole, else its first sentence)
		c["site"] = [UI.label(panel, Rect2(PAD, y, INNER, 24), "", "Regular", Pal.CELL_TEXT_BIG + 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)]
		y += 24 + BOX_PAD
		c["boxes"][2].size.y = y - c["boxes"][2].position.y
		# the foot: Deploy across, Auto under it
		var fy := Pal.ROOM_H - TOP - PAD - Pal.BUTTON_H
		c["auto"] = UI.button(panel, Rect2(PAD, fy, INNER - BOSS_W - 8, Pal.BUTTON_H), false)
		c["auto"].pressed.connect(_auto.bind(col))
		# insurance: the Fence holds the paper on the kit for the next run
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
		_cols.append(c)
	_came = CameBack.new()
	_came.visible = false
	_came.acted.connect(func(): acted.emit())
	add_child(_came)


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	if not _zone_set or not sim.zone_open(zone):
		_zone_set = true
		for z in range(Data.ZONES.size()):
			if sim.zone_open(z):
				zone = z
	_show_came_back()
	# the odds are read a few milliseconds a frame by the shell (main._read_odds); the screen shows what has settled
	var settled := ""
	for i in range(Data.TIERS.size()):
		settled += "1" if sim.odds_settled(i) else "0"
	var sig := "%s|%s|%s|%d|%d|%d|%d|%d|%d|%d|%s" % [str(sim.depth), str(sim.best_depth), str(sim.words) + str(sim.standing) + str(sim.weather) + str(int(sim.elapsed / 60.0)) + settled, sim.auto_tier,
			int(sim.hp), sim.best_tier, int(sim.dps()), int(sim.armour()), sim.tree.size(), zone, str(sim.depot_cleared)] + "|%d|%s|%s|%s|%s|%d" % [sim.notes, str(sim.boss_armed), str(sim.bosses_beaten), str(sim.campaign_done()), str(sim.atlas), sim.atlas_points] + "|%s|%d" % [str(sim.insure_next), int(sim.cash) / 50]
	if sig == _shown:
		return
	_shown = sig
	for z in range(Data.ZONES.size()):
		var zb: Button = _zone_buttons[z]
		var open_z: bool = sim.zone_open(z)
		zb.text = Data.ZONES[z]["name"] if open_z else "%s · locked" % Data.ZONES[z]["name"]
		zb.disabled = not open_z
		if _zone_art[z].visible:
			_style_art_tab(zb, z == zone)
		else:
			UI.style_button(zb, z == zone)
			zb.remove_theme_constant_override("outline_size")
	var tiers: Array = Data.ZONES[zone]["tiers"]
	for k in range(3):
		var i: int = tiers[k]
		var c: Dictionary = _cols[k]
		var t: Dictionary = sim.effective(i)
		var is_open: bool = sim.tier_open(i)
		var odds: float = sim.odds_now(i) if is_open else 0.0     # as read so far: the shell reads them a few ms a frame
		var tone := "good" if odds >= 0.9 else ("warn" if odds >= 0.6 else "bad")
		c["edge"].visible = is_open
		(c["edge"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.tone_color(tone)
		var band: Band = c["band"]
		band.set_site(Data.TIERS[i]["name"])
		band.set_tone(zone)
		band.title.add_theme_color_override("font_color", Pal.TEXT if is_open else Pal.TEXT_3)
		if is_open:
			# still reading: dimmer, and the screen keeps refreshing until it's settled
			# the site's level on the kicker past the campaign (7 Oct): the tier and the depth together are what the fight and its finds are
			var kicker: String = ("Tier %d · %s · level %d" % [k + 1, Data.ZONES[zone]["name"], int(t["level"])]) if sim.campaign_done() else ("Tier %d · %s" % [k + 1, Data.ZONES[zone]["name"]])
			band.set_words(kicker, Data.TIERS[i]["name"], Words.odds_words(odds),
				("%s to clear" % Fmt.pct(odds)) if sim.odds_settled(i) else "reading the odds", Pal.tone_color(tone) if sim.odds_settled(i) else Pal.TEXT_3)
		else:
			band.set_words("Tier %d · %s" % [k + 1, Data.ZONES[zone]["name"]], Data.TIERS[i]["name"], "Locked", "clear tier %d first" % k, Pal.TEXT_3)
		# the depth ladder is the endgame's: until the campaign's done it reads as such
		var endgame: bool = sim.campaign_done()
		c["depth_down"].visible = endgame
		c["depth_up"].visible = endgame
		c["depth_down"].disabled = not is_open or sim.on_mission() or t["depth"] <= 1
		c["depth_up"].disabled = not is_open or sim.on_mission() or t["depth"] > sim.best_depth[i]
		var tiles: Array = [
			["Them", ["%d × %.0f HP" % [t["pool"], t["hp"]], "%d × %.0f" % [t["pool"], t["hp"]]]],
			["Their fire", ["%.1f/s each" % t["dps"], "%.1f/s" % t["dps"]]],
			["Fight · clock", ["%s of %s" % [Fmt.mss(sim.estimate(i)), Fmt.mss(sim.clock_of(i))], "%s/%s" % [Fmt.mss(sim.estimate(i)), Fmt.mss(sim.clock_of(i))], "over %s" % Fmt.mss(sim.clock_of(i))]],     # the run's clock beside the fight (9 Oct)
			["Finds" if endgame else "Drops", (["level %d · tier %d gear" % [t["level"], t["loot_tier"]], "level %d gear" % t["level"], "level %d" % t["level"]]) if endgame else ["tier %d gear" % t["loot_tier"], "tier %d" % t["loot_tier"]]],
			["Depth", [("%d of %d" % [t["depth"], sim.best_depth[i] + 1]), "%d/%d" % [t["depth"], sim.best_depth[i] + 1]] if endgame else ["Locked"]],
			["Rewards", ["×%.1f" % pow(1.0 + Data.DEPTH_REWARD, t["depth"] - 1)]],
		]
		if sim.wear(i) > 0.0:
			var state: String = sim.site_state(i)
			tiles[5] = ["The site", [state, state.get_slice(" · ", 0)]]
		for r in range(6):
			UI.set_tile(c["tiles"][r], tiles[r][0], tiles[r][1], Pal.TEXT if is_open else Pal.TEXT_3)
		if is_open and sim.estimate(i) > sim.clock_of(i):
			UI.set_tile(c["tiles"][2], tiles[2][0], tiles[2][1], Pal.BAD)     # a fight that won't fit the clock: the DPS check, failed
		# the figure keeps clear of the −/+ when the ladder's open
		for l in [c["tiles"][DEPTH_TILE]["value"], c["tiles"][DEPTH_TILE]["key"]]:
			l.size.x = c["tiles"][DEPTH_TILE]["panel"].size.x - 20 - ((DEPTH_BTN + 8) if endgame else 0)
		UI.set_tile(c["tiles"][DEPTH_TILE], tiles[DEPTH_TILE][0], tiles[DEPTH_TILE][1], Pal.TEXT if is_open else Pal.TEXT_3)
		_show_chips(c, t, is_open)
		# what they resist, a chip an element in its colour, the same shape as what they fire; "nothing" when they don't
		c["resist_label"].visible = is_open
		c["resist"].visible = is_open
		if is_open:
			show_resists(c["resist"], t)
		else:
			c["resist"].show_chips([])
		# four rows: the radio's words first, the sky's after; a fifth (three called in, at night, in weather) is left off the end
		var wtiers: Dictionary = t.get("word_tiers", {})
		var names: Array = wtiers.keys()
		for nm in t["intel"]:
			if not (nm in names):
				names.append(nm)                 # the Radio's words first, the sky's after
		c["intel"].show_rows(word_rows(sim, names, wtiers) if is_open else [], WORD_ROWS)
		var radio: String = ("%d code%s from the Radio" % [wtiers.size(), "" if wtiers.size() == 1 else "s"]) if sim.juiceable(i) else ("codes from depth 2" if sim.campaign_done() else "a plain site")
		UI.fit(c["intel_head"], ["THE CODES · %s · %s" % [sim.sky_words(i), radio], "THE CODES · %s" % sim.sky_words(i), "THE CODES"])
		var auto: bool = sim.auto_tier == i
		c["deploy"].visible = is_open
		var walks: bool = t.get("boss_walks", false) and not sim.boss_armed.get(i, false)     # the Radio's Manager walks: free
		c["deploy"].disabled = not sim.can_deploy_to(i) or (t.has("boss") and not walks and sim.notes < sim.boss_cost(i))
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
		elif endgame and _station_words(i) != "":
			UI.fit(c["note"], [_station_words(i), _station_words(i).get_slice(" · ", 0), _station_words(i).get_slice(" · ", 0).replace(" at full strength", ", full strength"), _station_words(i).get_slice(":", 0)])
		else:
			c["note"].text = ""
		UI.fit_sentences(c["site"][0], Words.site_line(Data.TIERS[i]["name"], int(t["depth"])) if is_open else "")


## The ladder's stations ahead on a site (the endgame, 7 Oct): the crew's head at full strength at PINNACLE_DEPTH
## on the zone's last site, the lorry at CONVOY_DEPTH on the Services; "" once past them or where there are none.
func _station_words(i: int) -> String:
	var out: Array = []
	var b: Dictionary = sim.boss_of(i)
	if not b.is_empty() and sim.depth[i] < sim.pinnacle_depth(i):
		out.append("Depth %d: %s at full strength" % [sim.pinnacle_depth(i), b["name"]])
	if i == Data.CONVOY_TIER and sim.depth[i] < sim.convoy_depth():
		out.append("Depth %d: the lorry" % sim.convoy_depth())
	var own: Dictionary = sim.site_unique(i)
	if not own.is_empty() and not (own["name"] in sim.shelf):
		out.append(Words.SHELF["own_note"] % [sim.site_unique_depth(i), own["name"]])
	return " · ".join(out)


# ------------------------------------------------------------------ acting

func _tier(k: int) -> int:
	return Data.ZONES[zone]["tiers"][k]


func _pick_zone(z: int) -> void:
	if z >= 0 and z < Data.ZONES.size() and sim.zone_open(z):
		zone = z
		show_state(sim)


## The words as chip rows: the name in its tone (amber harder, green easier),
## the effect as the tail, whole then cut by clause with "+N". Shared with the radio.
static func word_rows(sim, names: Array, tiers := {}) -> Array:
	var out := []
	for name in names:
		if tiers.has(name):
			# a Radio word (9 Oct): its tier as the tag, its bite and pay as the tail, amber - it bites for what it pays
			var t: int = int(tiers[name])
			var ww: Array = sim.word_words(name, t)
			var tail := [str(ww[0]) + " · " + str(ww[1]), str(ww[0]).get_slice(", ", 0) + " · " + str(ww[1]).get_slice(", ", 0), str(ww[1]).get_slice(", ", 0)]
			out.append({"forms": [name], "tag": Data.WORD_TIER_NAMES[clampi(t, 1, 4) - 1], "colour": Pal.WARN, "tail": tail})
			continue
		var m: Dictionary = sim.modifier(name)
		var clauses: PackedStringArray = str(m["words"]).split(", ", false)
		var forms := []
		for n in range(clauses.size(), 0, -1):
			forms.append(", ".join(clauses.slice(0, n)) + ((" +%d" % (clauses.size() - n)) if n < clauses.size() else ""))
		var tone := word_tone(m)
		out.append({"forms": [name], "colour": Pal.tone_color(tone) if tone != "" else Pal.TEXT_2, "tail": forms})
	return out


## A word's tone: amber when it makes the fight harder, green when it makes it
## easier or richer, plain when it's a trade.
static func word_tone(m: Dictionary) -> String:
	var harder: bool = float(m.get("hp", 1.0)) > 1.0 or float(m.get("dps", 1.0)) > 1.0 or float(m.get("patrol", 1.0)) < 1.0 or int(m.get("contact", 0)) > 0
	var easier: bool = float(m.get("hp", 1.0)) < 1.0 or float(m.get("dps", 1.0)) < 1.0 or float(m.get("patrol", 1.0)) > 1.0 or int(m.get("contact", 0)) < 0
	if harder and not easier:
		return "warn"
	if easier and not harder:
		return "good"
	return ""


## What a site resists, a chip an element in its colour, over RESIST_ROWS rows; "Nothing" when it resists nothing. When
## the names don't all fit (all five, past Kitted out) every chip falls back to its figure alone, still in its colour,
## so none is dropped. Returns the chips wanted; the smoke counts them against what shows.
static func show_resists(chips, t: Dictionary) -> int:
	var long := []
	var short := []
	for ty in Data.ELEMENTS:
		if float(t.get("res", {}).get(ty, 0.0)) > 0.0:
			var fig := "%.0f%%" % (float(t["res"][ty]) * 100.0)
			long.append(["%s %s" % [ty.capitalize(), fig], ty])
			short.append([fig, ty])
	if long.is_empty():
		long.append(["Nothing", Pal.TEXT_2])
	chips.show_chips(long, RESIST_ROWS)
	if chips.shown() < long.size():
		chips.show_chips(short, RESIST_ROWS)
	return long.size()


## What they fire, a chip an element in its colour with your resist to it;
## "Physical" alone when a site fires nothing else. Chips past the row are left off.
func _show_chips(c: Dictionary, t: Dictionary, is_open: bool) -> void:
	var chips := []
	for ty in Data.ELEMENTS:
		var share: float = float(t.get("types", {}).get(ty, 0.0))
		if share > 0.0:
			var over: float = sim.over_cap(ty)
			var ot: String = (" +%.0f" % over) if over >= 0.5 else ""     # over the cap (12 Oct)
			chips.append(["%s %.0f%% · you resist %.0f%%%s" % [ty.capitalize(), share * 100.0, sim.resist(ty) * 100.0, ot], "%s · res %.0f%%%s" % [ty.capitalize(), sim.resist(ty) * 100.0, ot], ty])
	if chips.is_empty():
		chips.append(["Physical only · armour takes %s" % Fmt.pct(sim.mitigation()), "Physical only", "physical"])
	c["fire_label"].visible = is_open
	c["chips"].visible = is_open
	c["chips"].show_chips(chips if is_open else [])


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


## What came back (12 Oct): a button at the zone row's right while runs have come home since Seen, the zone tabs
## narrowing to make room; pressed, the card drops under it at the screen's right, over the top of the right-hand
## column only (its band and fight), clear of every button. Seen puts both away.
const CAME_BTN_W := 340
const CAME_Y := ZONE_H + 4


func _show_came_back() -> void:
	_came.show_state(sim)
	var has: bool = _came.visible
	if not has:
		_came_open = false
	_came_btn.visible = has
	var zn: int = Data.ZONES.size()
	var room: float = Pal.GRID_W - ((CAME_BTN_W + COL_GAP) if has else 0)
	var zw: float = (room - COL_GAP * (zn - 1)) / zn
	for z in range(zn):
		_zone_buttons[z].position.x = z * (zw + COL_GAP)
		_zone_buttons[z].size.x = zw
		_zone_art[z].position.x = z * (zw + COL_GAP)
		_zone_art[z].size.x = zw
	if has:
		var cb: Dictionary = sim.came_back
		var runs: int = int(cb.get("runs", 0))
		var rw := "%d run%s" % [runs, "" if runs == 1 else "s"]
		var cash: float = float(cb.get("cash", 0.0))
		var arrow := " ▴" if _came_open else " ▾"
		var forms := ["What came back · %s · +%s%s" % [rw, Fmt.money(cash), arrow], "Came back · %s · +%s%s" % [rw, Fmt.money(cash), arrow], "Came back · %s%s" % [rw, arrow], "%s back%s" % [rw, arrow]]
		_came_btn.text = forms.back()
		for f in forms:
			if UI.text_width(_came_btn, f) <= CAME_BTN_W - 28:
				_came_btn.text = f
				break
		UI.style_button(_came_btn, _came_open, "good")
	_came.visible = has and _came_open
	_came.position = Vector2(Pal.GRID_W - _came.size.x, CAME_Y)
	_came.move_to_front()


func _toggle_came() -> void:
	_came_open = not _came_open
	_show_came_back()


## For the tests: every label and button with text.
func text_nodes() -> Array:
	var out: Array = []
	out.append_array(_came.text_nodes())
	if _came_btn.visible:
		out.append(_came_btn)
	for zb in _zone_buttons:
		out.append(zb)
	for c in _cols:
		out.append_array(c["band"].text_nodes())
		out.append_array([c["intel_head"], c["note"], c["fire_label"], c["resist_label"]])
		out.append_array(c["site"])
		if c["resist"].visible:
			out.append_array(c["resist"].text_nodes())
		for t in c["tiles"]:
			out.append_array([t["key"], t["value"]])
		if c["chips"].visible:
			out.append_array(c["chips"].text_nodes())
		out.append_array(c["intel"].text_nodes())
		for b in [c["deploy"], c["auto"], c["depth_down"], c["depth_up"], c["boss"], c["insure"]]:
			if b.visible:
				out.append(b)
	if _came.visible:
		# under the card is out of sight: the column's words there aren't the screen's (the card's own are)
		var cr: Rect2 = _came.get_global_rect()
		out = out.filter(func(n): return _came.is_ancestor_of(n) or not cr.intersects(n.get_global_rect()))
	return out


## Label/value pairs that share a line, for the fit check.
func line_pairs() -> Array:
	var out: Array = []
	return out
