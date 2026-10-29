extends Control
## The Map, between runs (19 Oct, the drawn Map, Matt's pick B): the map at the left - every zone an area, every site a
## pin in its odds' colour, the order's places once opened (map_view.gd) - and the picked pin's card at the right:
## everything about that site in one place - the hostiles, the odds, the intel - and Set off and Auto at the foot. While
## the runner is out, main.gd shows the live cards instead. Fixed geometry in the card grid's 1536 x 916.

signal acted
signal to_issuer                       # the County card's links (the canvas 'The County board')
signal to_bench

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const Band := preload("res://scripts/ui/band.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const CameBack := preload("res://scripts/ui/came_back.gd")
const TierGuide := preload("res://scripts/ui/tier_guide.gd")
const Order := preload("res://scripts/ui/order.gd")
const County := preload("res://scripts/ui/county.gd")
const MapView := preload("res://scripts/ui/map_view.gd")
const Items := preload("res://scripts/sim/items.gd")
const SkillPicker := preload("res://scripts/ui/skill_picker.gd")
const SkillBar := preload("res://scripts/ui/skill_bar.gd")
const RepeatReport := preload("res://scripts/ui/repeat_report.gd")
const WagersPanel := preload("res://scripts/ui/wagers_panel.gd")
const WHY_UNDER := 0.6                # the reasons show at Risky and worse

const COL_GAP := 16
@warning_ignore("integer_division")
const COL_W := (Pal.GRID_W - 2 * COL_GAP) / 3                 # 501
const PAD := 20
const INNER := COL_W - 2 * PAD                                # 461
const LINE_H := 28
const BOSS_W := 150                # the boss toggle beside Set off
const REPEAT_W := 170              # "Run it ×5" beside Set off (29 Oct, docs/design/trips.md 1); Kev's wagers in its place before a first clear or a head
const DEPTH_BTN := 48              # the −/+ stacked at the depth tile's right, the endgame's ladder
const DEPTH_TILE := 4              # the depth tile's place in the six
const BAND_H := 180                # the art band at the top of a column: the rooms' one height (12 Oct: 200, the 20 paid the resists' second row)
const FIRE_W := 148                # "They fire" / "They resist" before the chips
const BOX_PAD := 10                # the outline round the fight, the elements and the word
const BOX_GAP := 9                 # between the boxes (12 Oct: 12, the 6 paid the resists' second row)
const RESIST_ROWS := 2             # what they resist wraps to a second row (12 Oct: one row dropped chips - the city showed 2 of 4)
const WORD_ROWS := 4               # the radio's two words and the sky's two, a row each
const FOOT_H := 48                 # the insurance's row, the rig's top-up beside it (23 Oct, parked item 4)

var sim
var zone := 0                      # the picked site's zone
var selected := -1                 # the site whose card shows (19 Oct: a pin picked); -1 until the first show picks the furthest open
var order_key := ""                # an order's place picked instead (its card in the site's place)
var _map                           # map_view.gd
var _title: Label                  # the row's left: the picked site's zone and its sky
var _cols: Array = []              # the card (one, at the right since the drawn Map): its labels and buttons
var _skill_pick: SkillPicker       # the run's three skills, over the map (milestone 8)
var _shown := ""
var _came                          # what came back (came_back.gd): the runs since the player last looked, under its button
var _came_btn: Button              # the tally's button at the zone row's right, before the guide's
var _order                         # the order's places (order.gd): one card at the right, its pin picked
var _county                        # the County (county.gd, 25 Oct): over the map and the card while it's picked
var _county_btn: Button            # "The County" in the row, once the town's on fiat
var county_on := false
var _guide_btn: Button             # "What a site pays" (16 Oct, item 11): the map's tier guide, at the row's end
var _guide
var _came_open := false            # the card dropped down
var _report                        # the repeat's report (repeat_report.gd, 29 Oct): over the map when they're back
var _wagers                        # Kev's wagers (wagers_panel.gd, 29 Oct): over the map while open
# back at level 1 (21 Oct, canvas "The code book and the death pick" 2): after a death the card's column is the trait
# pick - the two who turned up as cards, what the death took and what stays, Set off shut till one's picked
var _pick: Panel
var _pick_kicker: Label
var _pick_title: Label
var _pick_line: Label
var _pick_line2: Label
var _pick_cards: Array = []         # {button, name, chips}
var _pick_head: Label
var _pick_lost: Chips
var _pick_go: Button
const PICK_CARD_H := 104
# the map moved to the Radio (12 Oct): the zone row is the four zones, the Outskirts first; the order's fifth (18 Oct)
const ZONE_H := 56
const TOP := ZONE_H + 16
const CARD_X := 2 * (COL_W + COL_GAP)      # the card, the right third
const MAP_W := 2 * COL_W + COL_GAP         # the map, the left two


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	# the row: the picked site's zone and its sky at the left (the zones are the map's now, not tabs)
	_title = UI.label(self, Rect2(0, 0, Pal.GRID_W - GUIDE_W - CAME_BTN_W - COUNTY_BTN_W - 3 * COL_GAP, ZONE_H), "", "SemiBold", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_map = MapView.new(Rect2(0, TOP, MAP_W, Pal.ROOM_H - TOP))
	_map.picked.connect(select)
	_map.picked_order.connect(select_order)
	add_child(_map)
	# what came back (12 Oct, Matt's playtest: the card over a column "doesn't work where it is"): a button at the zone
	# row's right while there's a tally, the card dropping under it when pressed
	_came_btn = UI.button(self, Rect2(Pal.GRID_W - GUIDE_W - COL_GAP - CAME_BTN_W, 0, CAME_BTN_W, ZONE_H), false)
	_came_btn.pressed.connect(_toggle_came)
	_came_btn.visible = false
	_county_btn = UI.button(self, Rect2(Pal.GRID_W - GUIDE_W - CAME_BTN_W - COUNTY_BTN_W - 2 * COL_GAP, 0, COUNTY_BTN_W, ZONE_H), false)
	_county_btn.pressed.connect(func(): set_county(not county_on))
	_county_btn.visible = false
	for col in range(1):
		var x := CARD_X
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
		c["fire_label"] = UI.label(panel, Rect2(PAD, y, FIRE_W - 8, Chips.CHIP_H), "THEY FIRE", "Medium", 20, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["chips"] = Chips.new(INNER - FIRE_W)
		c["chips"].position = Vector2(PAD + FIRE_W, y)
		panel.add_child(c["chips"])
		y += Chips.CHIP_H + 8
		c["resist_label"] = UI.label(panel, Rect2(PAD, y, FIRE_W - 8, Chips.CHIP_H), "THEY RESIST", "Medium", 20, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["resist"] = Chips.new(INNER - FIRE_W)
		c["resist"].position = Vector2(PAD + FIRE_W, y)
		panel.add_child(c["resist"])
		y += RESIST_ROWS * (Chips.CHIP_H + Chips.ROW_GAP) - Chips.ROW_GAP + BOX_PAD
		c["boxes"][1].size.y = y - c["boxes"][1].position.y
		y += BOX_GAP
		c["boxes"][2].position.y = y
		y += BOX_PAD
		# the word: the head carries the sky; a row a word, its name left and its effect right
		c["intel_head"] = UI.head(panel, Rect2(PAD, y, INNER, UI.HEAD_H), "Conditions")
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
		# the foot: Set off across, the insurance and the rig's top-up sharing the row under it (21 Oct, Matt: auto-run's
		# gone; 23 Oct: the top-up beside the paper)
		var fy := Pal.ROOM_H - TOP - PAD - FOOT_H
		@warning_ignore("integer_division")
		var half: int = (INNER - 8) / 2
		# insurance: the Fence holds the paper on the kit for the next run
		c["insure"] = UI.button(panel, Rect2(PAD, fy, half, FOOT_H), false)
		c["insure"].pressed.connect(_insure.bind(col))
		# the rig at the gate: one button that cycles Fill up, Best grades only, Leave it (parked item 4, the 21 Oct board)
		c["rig"] = UI.button(panel, Rect2(PAD + INNER - half, fy, half, FOOT_H), false)
		c["rig"].pressed.connect(_rig.bind(col))
		c["rig"].tooltip_text = Words.TOP_UP_TIP
		# the skills (24 Oct, milestone 8; Matt: A): a third button in the row, the three pictures on it, the picker
		# over the map behind it
		c["skills"] = UI.button(panel, Rect2(PAD, fy, half, FOOT_H), false)
		c["skills"].tooltip_text = "Change skills"
		c["skills"].pressed.connect(_skills_open)
		c["skill_pics"] = []
		for k in range(Data.SKILL_SLOTS):
			var sp := TextureRect.new()
			sp.size = Vector2(32, 32)
			sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c["skills"].add_child(sp)
			c["skill_pics"].append(sp)
		fy -= Pal.BUTTON_H + 12
		c["deploy"] = UI.button(panel, Rect2(PAD, fy, INNER, Pal.BUTTON_H), true)
		c["deploy"].text = "Set off"
		c["deploy"].pressed.connect(_deploy.bind(col))
		# the zone's last site has its boss: a toggle beside Set off takes them on
		c["boss"] = UI.button(panel, Rect2(PAD + INNER - BOSS_W, fy, BOSS_W, Pal.BUTTON_H), false)
		c["boss"].pressed.connect(_boss.bind(col))
		c["boss"].visible = false
		c["note"] = UI.label(panel, Rect2(PAD, fy - 36, INNER, 30), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		# the repeat runs (29 Oct): "Run it ×5" beside Set off, shut with its reason on the note; Kev's wagers in its place
		# on a run he bets on (a first clear, a head armed)
		c["repeat"] = UI.button(panel, Rect2(PAD + INNER - REPEAT_W, fy, REPEAT_W, Pal.BUTTON_H), false)
		c["repeat"].pressed.connect(_repeat.bind(col))
		c["wager"] = UI.button(panel, Rect2(PAD + INNER - REPEAT_W, fy, REPEAT_W, Pal.BUTTON_H), false)
		c["wager"].pressed.connect(_wager_open.bind(col))
		c["wager"].visible = false
		_cols.append(c)
	_build_pick()
	_skill_pick = SkillPicker.new()
	_skill_pick.position = Vector2(20, TOP + 8)
	_skill_pick.acted.connect(func():
		_shown = ""
		acted.emit())
	add_child(_skill_pick)
	_order = Order.new(TOP)
	_order.visible = false
	_order.mouse_filter = Control.MOUSE_FILTER_IGNORE     # its full-width frame over the map: only its card takes a click
	_order.acted.connect(func(): acted.emit())
	add_child(_order)
	_county = County.new(Rect2(0, TOP, Pal.GRID_W, Pal.ROOM_H - TOP))
	_county.visible = false
	_county.acted.connect(func(): acted.emit())
	_county.to_issuer.connect(func(): to_issuer.emit())
	_county.to_bench.connect(func(): to_bench.emit())
	add_child(_county)
	_came = CameBack.new()
	_came.visible = false
	_came.acted.connect(func(): acted.emit())
	add_child(_came)
	_wagers = WagersPanel.new()
	_wagers.position = Vector2(0, TOP)
	_wagers.acted.connect(func():
		_shown = ""
		acted.emit())
	add_child(_wagers)
	_report = RepeatReport.new()
	_report.position = Vector2(0, TOP)
	_report.acted.connect(func():
		_shown = ""
		acted.emit())
	add_child(_report)
	_guide_btn = UI.button(self, Rect2(Pal.GRID_W - GUIDE_W, 0, GUIDE_W, ZONE_H), false)
	_guide_btn.tooltip_text = "What a site pays at each signal level, and where to farm"
	_guide_btn.pressed.connect(_open_guide)
	_guide = TierGuide.new()
	_guide.closed.connect(func(): acted.emit())
	add_child(_guide)


func _build_pick() -> void:
	_pick = UI.panel(self, Rect2(CARD_X, TOP, COL_W, Pal.ROOM_H - TOP), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_pick.visible = false
	_pick_kicker = UI.label(_pick, Rect2(PAD, 16, INNER, 24), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_pick_title = UI.label(_pick, Rect2(PAD, 42, INNER, 40), "Pick a trait", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_pick_line = UI.label(_pick, Rect2(PAD, 88, INNER, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_pick_line2 = UI.label(_pick, Rect2(PAD, 112, INNER, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(2):
		var b := Button.new()
		b.position = Vector2(PAD, 150 + k * (PICK_CARD_H + 12))
		b.size = Vector2(INNER, PICK_CARD_H)
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick_trait.bind(k))
		_pick.add_child(b)
		UI.style_button(b, false)
		var c := {"button": b}
		c["name"] = UI.label(b, Rect2(16, 12, INNER - 32, 34), "", "SemiBold", Pal.TITLE - 6, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["name"].mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ch := Chips.new(INNER - 32, 3)
		ch.position = Vector2(16, 58)
		b.add_child(ch)
		c["chips"] = ch
		_pick_cards.append(c)
	var hy: float = 150 + 2 * (PICK_CARD_H + 12) + 12
	UI.panel(_pick, Rect2(PAD, hy - 10, INNER, 1), UI.box(Pal.CARD_LINE, 0))     # UI.panel adds it (23 Oct: a second add_child logged "Can't add child" at every launch)
	_pick_head = UI.label(_pick, Rect2(PAD, hy, INNER, 22), "WHAT THE DEATH TOOK, AND WHAT STAYS", "Medium", Pal.CELL_TEXT - 2, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_pick_lost = Chips.new(INNER, 6)
	_pick_lost.position = Vector2(PAD, hy + 28)
	_pick.add_child(_pick_lost)
	_pick_go = UI.button(_pick, Rect2(PAD, Pal.ROOM_H - TOP - PAD - 2 * Pal.BUTTON_H - 12, INNER, Pal.BUTTON_H), true)
	_pick_go.disabled = true


## The trait's words as chips: what it costs (a "−") in the bad tone, the rest good (Greedy: tins +15%, max HP −10%).
static func trait_chips(words: String) -> Array:
	var out: Array = []
	for part in words.split(", "):
		var w: String = str(part)
		out.append({"forms": [w.substr(0, 1).to_upper() + w.substr(1)], "colour": Pal.BAD if w.contains("−") else Pal.GOOD})
	return out


func _show_pick() -> void:
	var who: String = sim.cls if sim.cls != "" else "runner"
	UI.fit(_pick_kicker, ["The %s · back at level 1" % who, "Back at level 1"])
	UI.fit(_pick_line, ["It stays with the %s until the next death." % who, "It stays until the next death."])
	UI.fit(_pick_line2, ["The other one goes."])
	for k in range(2):
		var c: Dictionary = _pick_cards[k]
		var nm: String = str(sim.candidates[k]) if k < sim.candidates.size() else ""
		c["button"].visible = nm != ""
		var row: Dictionary = {}
		for t in Data.TRAITS:
			if t["name"] == nm:
				row = t
		UI.fit(c["name"], [nm])
		c["chips"].show_chips(trait_chips(str(row.get("words", ""))), 1, true)
	var lost: Array = [{"forms": ["The kit worn"], "colour": Pal.BAD}, {"forms": ["The %s's levels" % who, "The levels"], "colour": Pal.BAD},
		{"forms": ["The tree's points back to spend", "The tree's points"], "colour": Pal.TEXT_2}, {"forms": ["The stash"], "colour": Pal.TEXT_2}]
	if sim.crew_played().size() > 1:
		lost.append({"forms": ["The rest of the crew", "The crew"], "colour": Pal.TEXT_2})
	if sim.paragon_xp > 0.0 or not sim.ring.is_empty():
		lost.append({"forms": ["Paragon"], "colour": Pal.TEXT_2})
	_pick_lost.show_chips(lost, 3, true)
	UI.fit_button(_pick_go, ["Set off · pick a trait first", "Pick a trait first"])


func _pick_trait(k: int) -> void:
	if sim.choose_runner(k):
		_shown = ""
		acted.emit()


## The site the Map opens on: the furthest open (12 Oct: not the Outskirts every launch).
func _default_site() -> int:
	var out := 0
	for i in range(Data.TIERS.size()):
		if sim.tier_open(i):
			out = i
	return out


## The tier guide over the room, on the site of the zone's first open column (else where it was left).
func _open_guide() -> void:
	_guide.open(sim, _tier(0) if _guide.site < 0 else -1)
	_guide.move_to_front()


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	if selected < 0 or selected >= Data.TIERS.size() or not sim.zone_open(int(Data.TIERS[selected]["zone"])):
		selected = _default_site()
	if order_key != "" and not sim.order_known(order_key):     # a place unknown again (its zone shut under the level, 20 Oct) gives the card back
		order_key = ""
	zone = int(Data.TIERS[selected]["zone"])
	_show_came_back()
	_report.show_state(sim)                  # the repeat's card, while it waits to be put away (29 Oct)
	if _wagers.visible:
		_wagers.show_state(sim)
	UI.fit_button(_guide_btn, ["What a site pays ?", "Site guide ?", "?"])
	var place: String = str(Data.pinnacle(order_key)["place"]) if order_key != "" else str(Data.ZONES[zone]["name"])
	var sky: String = sim.sky_words(selected, false)
	UI.fit(_title, ["%s · %s" % [place, sky], place])
	_map.show_state(sim, selected, order_key)
	if _guide.visible:
		_guide.show_state(sim)
		_guide.move_to_front()             # over the tally's card, which comes to the front on every refresh
	if _skill_pick.visible:
		_skill_pick.visible = not sim.on_mission()     # set off: the three are locked
		_skill_pick.show_state(sim)
		_skill_pick.move_to_front()
	var picking: bool = sim.candidates.size() == 2 and not sim.on_mission()
	_county_btn.visible = sim.issued and not picking
	if not sim.issued:
		county_on = false
	UI.fit_button(_county_btn, ["Back to the map", "The map"] if county_on else ["The County", "County"])
	UI.style_button(_county_btn, county_on, "good")
	_county.visible = county_on and not picking
	_map.visible = not _county.visible
	if _county.visible:
		UI.fit(_title, [Words.COUNTY["title"] + " · " + Words.COUNTY["progress"] % sim.county_taken_count(), Words.COUNTY["title"]])
		_county.show_state(sim)
		_order.visible = false
		_pick.visible = false
		for c in _cols:
			c["panel"].visible = false
			c["edge"].visible = false
		_shown = ""
		_came.move_to_front()
		_guide.move_to_front()
		return
	_pick.visible = picking
	if picking:
		_order.visible = false
		for c in _cols:
			c["panel"].visible = false
			c["edge"].visible = false
		_show_pick()
		_shown = ""
		_came.move_to_front()
		_guide.move_to_front()
		return
	var on_order: bool = order_key != ""
	_order.visible = on_order
	for c in _cols:
		c["panel"].visible = not on_order
		c["edge"].visible = c["edge"].visible and not on_order
	if on_order:
		_order.set_only(order_key)
		_order.show_state(sim)
		_shown = ""
		_came.move_to_front()
		_guide.move_to_front()
		return
	# the odds are read a few milliseconds a frame by the shell (main._read_odds); the screen shows what has settled
	var settled := ""
	for i in range(Data.TIERS.size()):
		settled += ("2" if sim.odds_settled(i) else "1") if sim.odds_ready(i) else "0"
	@warning_ignore("integer_division")
	var sig := "%s|%s|%s|%d|%d|%d|%d|%d|%d|%d|%s" % [str(sim.depth), str(sim.best_depth), str(sim.words) + str(sim.standing) + str(sim.weather) + str(int(sim.elapsed / 60.0)) + settled, 0,
			int(sim.hp), sim.best_tier, int(sim.dps()), int(sim.armour()), sim.tree.size(), selected, str(sim.depot_cleared)] + "|%d|%s|%s|%s|%s|%d" % [sim.notes, str(sim.boss_armed), str(sim.bosses_beaten), str(sim.campaign_done()), str(sim.atlas), sim.atlas_points] + "|%s|%d|%s|%d" % [str(sim.insure_next), int(sim.cash) / 50, sim.top_up_mode, int(sim.odds_read(selected).get("runs", 0))] + "|%s|%s|%s|%d" % [sim.repeat_block(selected), str(sim.wager_site_open(selected)), str(sim.wagers.get(sim.wager_site_key(selected), {})), sim.repeat_count()]
	if sig == _shown:
		return
	_shown = sig
	var tiers: Array = Data.ZONES[zone]["tiers"]
	for k in range(1):
		var i: int = selected
		var c: Dictionary = _cols[k]
		var tier_n: int = tiers.find(i) + 1
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
			var kicker: String = "%s · Tier %d" % [Data.ZONES[zone]["name"], tier_n]     # the zone's, the map no longer a tab a zone (19 Oct); the gear's level is the Gear level tile's
			band.set_words(kicker, Data.TIERS[i]["name"], Words.odds_words(odds),
				("%s to clear" % Fmt.pct(odds)) if sim.odds_ready(i) else "reading the odds", Pal.tone_color(tone) if sim.odds_ready(i) else Pal.TEXT_3)
			# why it reads low (17 Oct, Matt: the item-colours canvas): the headline under the title, the reasons under it
			var why: Array = odds_reasons(sim, i) if sim.odds_ready(i) and odds < WHY_UNDER else []
			band.headline_under_title(not why.is_empty())
			band.chips.visible = not why.is_empty()
			if not why.is_empty():
				band.chips.show_chips(why, 2, true)     # two rows for the hints (23 Oct)
			band.chip_rows(band.chips._rows_used if not why.is_empty() else 1)
		elif sim.level_gated(i) and (tiers.find(i) == 0 or int(sim.best_depth[i - 1]) > 0):
			band.set_words("%s · Tier %d" % [Data.ZONES[zone]["name"], tier_n], Data.TIERS[i]["name"], "Locked", "Opens at level %d" % sim.site_gate(i), Pal.TEXT_3)     # its drops' level less one (19 Oct)
			band.headline_under_title(false)
			band.chips.visible = false
		else:
			band.set_words("%s · Tier %d" % [Data.ZONES[zone]["name"], tier_n], Data.TIERS[i]["name"], "Locked", "After %s" % Words.mid(Data.TIERS[i - 1]["name"]), Pal.TEXT_3)     # "Clear the Garden Centre first" sat on "Locked" (18 Oct)
			band.headline_under_title(false)
			band.chips.visible = false
		# a site is always its campaign self (15 Oct, signals_map.png): no depth's −/+; the depths are the signals'
		c["depth_down"].visible = false
		c["depth_up"].visible = false
		var p_odds: float = sim.paper_odds(i)
		var tiles: Array = [
			["Gang", ["%d × %.0f HP" % [t["pool"], t["hp"]], "%d × %.0f" % [t["pool"], t["hp"]]]],
			["Their fire", ["%.1f dmg/s each" % t["dps"], "%.1f/s" % t["dps"]]],
			["Fight · clock", [     # "Fight time · run clock" wanted 179 px of the tile's 128 (18 Oct)
			"%s of %s" % [Fmt.mss(sim.estimate(i)), Fmt.mss(sim.clock_of(i))], "%s/%s" % [Fmt.mss(sim.estimate(i)), Fmt.mss(sim.clock_of(i))],
			("over %s" % Fmt.mss(sim.clock_of(i))) if sim.estimate(i) > sim.clock_of(i) else "clock %s" % Fmt.mss(sim.clock_of(i))]],     # the run's clock beside the fight (9 Oct); a fight too long to print says it's over the clock (19 Oct: it fell to "clock 5:12", the fight gone)
			["Item level", sim.finds_words(int(t["level"]))],     # the level to wear what it drops, the number an item's own Level chip says (18 Oct)
			["Papers", ["1 in %d finds" % maxi(1, roundi(1.0 / maxf(p_odds, 0.001))), "1 in %d" % maxi(1, roundi(1.0 / maxf(p_odds, 0.001)))]],     # the endgame's keys, found here (15 Oct)
			["The site", sim.site_state_forms(i)],     # its crates (27 Oct): fresh, what's left, or picked clean
		]
		for r in range(6):
			UI.set_tile(c["tiles"][r], tiles[r][0], tiles[r][1], Pal.TEXT if is_open else Pal.TEXT_3)
		if is_open and sim.estimate(i) > sim.clock_of(i):
			UI.set_tile(c["tiles"][2], tiles[2][0], tiles[2][1], Pal.BAD)     # a fight that won't fit the clock: the DPS check, failed
		# the figure keeps clear of the −/+ when the ladder's open
		for l in [c["tiles"][DEPTH_TILE]["value"], c["tiles"][DEPTH_TILE]["key"]]:
			l.size.x = c["tiles"][DEPTH_TILE]["panel"].size.x - 20
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
		var rows: Array = word_rows(sim, names, wtiers) if is_open else []
		# what a run here brings for the rebuild (20 Oct, Matt: "never clear when said material drops"), the first row
		if is_open and sim.campaign_done() and not sim.material_split(i).is_empty():
			var mk: String = str(sim.material_split(i).keys()[0])
			var pc: int = int(round(sim.material_odds(i) * 100.0))
			rows.push_front({"forms": [sim.thing_name(mk)], "colour": MATERIAL_TONE, "tail": ["%d%% a run brings some home, a death too" % pc, "%d%% a run" % pc]})
		c["intel"].show_rows(rows, WORD_ROWS)
		UI.fit(c["intel_head"], ["CONDITIONS · %s" % sim.sky_words(i, false), "CONDITIONS"])     # the weather is the row's (18 Oct, said once)     # the sky (13 Oct, Matt); the codes live on signals (15 Oct), so the head no longer counts them (18 Oct)
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
		_repeat_lay(c, i, is_open)
		if c["boss"].visible:
			var armed: bool = sim.boss_armed.get(i, false)
			c["boss"].text = ("Convoy ✓" if armed else "Convoy") if convoy else ("Head ✓" if armed else "Head")
			c["boss"].disabled = sim.on_mission() or (not armed and not sim.can_arm_boss(i))
			UI.style_button(c["boss"], false, "bad" if armed else "")
		c["insure"].visible = is_open
		_foot_lay(c, is_open)
		UI.fit_button(c["insure"], ["Insured ✓"] if sim.insure_next else ["Insure kit · %s" % Fmt.money(sim.insure_cost(i)), "Insure · %s" % Fmt.money(sim.insure_cost(i)), "Insure · %s" % Fmt.money(sim.insure_cost(i)).replace(" tins", ""), "Insure"])
		c["insure"].disabled = sim.on_mission() or (not sim.insure_next and not sim.can_insure(i))
		UI.style_button(c["insure"], false, "good" if sim.insure_next else "")
		c["rig"].visible = is_open
		c["rig"].disabled = sim.on_mission()
		UI.fit_button(c["rig"], ["Rig at the gate: %s ▾" % Words.TOP_UP_MID[sim.top_up_mode], "Rig: %s ▾" % Words.TOP_UP_MID[sim.top_up_mode], "%s ▾" % Words.TOP_UP_SHORT[sim.top_up_mode], "%s ▾" % Words.TOP_UP_TINY[sim.top_up_mode]])
		var rep_why: String = sim.repeat_block(i) if c["repeat"].visible else ""
		if not is_open:
			c["note"].text = ""
		elif sim.away():
			UI.fit(c["note"], [Words.REPEAT["shut_away"]])
		elif sim.hp < sim.max_hp() * 0.5:
			c["note"].text = "The runner is under half HP"
		elif c["boss"].visible and sim.boss_armed.get(i, false):
			var cost: int = sim.boss_cost(i)
			UI.fit(c["note"], [("%s: free, the first time" % boss["name"]) if cost == 0 else ("%s: %s, you have %s" % [boss["name"], Fmt.notes(cost), Fmt.notes(sim.notes)]), "%s: %s" % [boss["name"], Fmt.notes(cost)], boss["name"]])
		elif c["boss"].visible and not sim.boss_armed.get(i, false) and sim.boss_cost(i) > 0 and sim.notes < sim.boss_cost(i):
			UI.fit(c["note"], ["%s wants %s; you have %s" % [boss["name"], Fmt.notes(sim.boss_cost(i)), Fmt.notes(sim.notes)], "%s: %s" % [boss["name"], Fmt.notes(sim.boss_cost(i))], "Not enough notes"])
		elif rep_why != "":
			var cnt: int = sim.repeat_count()
			UI.fit(c["note"], [(Words.REPEAT["note"] % [cnt, rep_why]) if cnt > 0 else Words.REPEAT["note_full"] % rep_why, rep_why])     # why "Run it ×5" is shut, on the card (29 Oct)
		else:
			c["note"].text = ""
		UI.fit_sentences(c["site"][0], Words.site_line(Data.TIERS[i]["name"], int(t["depth"])) if is_open else "")


## The ladder's stations ahead on a site (the endgame, 7 Oct): the crew's head at full strength at PINNACLE_DEPTH
## on the zone's last site, the lorry at CONVOY_DEPTH on the Services; "" once past them or where there are none.
func _station_words(i: int) -> String:
	var out: Array = []
	var b: Dictionary = sim.boss_of(i)
	if not b.is_empty() and sim.depth[i] < sim.pinnacle_depth(i):
		out.append("Level %d signal: %s at full strength" % [sim.lv_at(i, sim.pinnacle_depth(i)), b["name"]])
	var own: Dictionary = sim.site_unique(i)
	if not own.is_empty() and not (own["name"] in sim.shelf):
		out.append(Words.SHELF["own_note"] % [sim.site_unique_level(i), own["name"]])
	return " · ".join(out)


# ------------------------------------------------------------------ acting

func _tier(_k: int) -> int:
	return selected


## A pin picked (19 Oct): its card. A shut site in an open zone shows too - what opens it.
func select(i: int) -> void:
	if i < 0 or i >= Data.TIERS.size() or sim == null or not sim.zone_open(int(Data.TIERS[i]["zone"])):
		return
	selected = i
	order_key = ""
	if _wagers.visible and _wagers.key != sim.wager_site_key(i):
		_wagers.visible = false               # Kev's offer is the picked site's: another pin, another offer (the review)
	_shown = ""
	show_state(sim)


## The County over the map, or the map back (25 Oct).
## Off the Map, the County's shut card goes (the review: it outlived the board).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible and _county != null:
		_county.hide_shut()


func set_county(on: bool) -> void:
	county_on = on and sim != null and sim.issued
	if not county_on and _county != null:
		_county.hide_shut()
	_shown = ""
	_county._shown = ""
	if sim != null:
		show_state(sim)


## An order's place picked: its card in the site's place.
func select_order(k: String) -> void:
	if sim == null or not sim.order_known(k):
		return
	order_key = k
	_shown = ""
	show_state(sim)


## A zone's first site (the tabs' old call, kept for the tests): its card.
func _pick_zone(z: int) -> void:
	if z >= 0 and z < Data.ZONES.size():
		select(int(Data.ZONES[z]["tiers"][0]))


## The words as chip rows: the name in its tone (amber harder, green easier),
## the effect as the tail, whole then cut by clause with "+N". Shared with the radio.
const MATERIAL_TONE := Color("d6c27a")     # the materials' sand (the canvas "Fiat – The playtest batch")


static func word_rows(sim_v, names: Array, tiers := {}) -> Array:
	var out := []
	for nm in names:
		if tiers.has(nm):
			# a Radio word (9 Oct): its tier as the tag, its bite and pay as the tail, amber - it bites for what it pays
			var t: int = int(tiers[nm])
			var ww: Array = sim_v.word_words(nm, t)
			var tail := [str(ww[0]) + " · " + str(ww[1]), str(ww[0]).get_slice(", ", 0) + " · " + str(ww[1]).get_slice(", ", 0), str(ww[1]).get_slice(", ", 0)]
			out.append({"forms": [nm], "tag": Data.WORD_TIER_NAMES[clampi(t, 1, 4) - 1], "colour": Pal.WARN, "tail": tail})
			continue
		var m: Dictionary = sim_v.modifier(nm)
		var clauses: PackedStringArray = str(m["words"]).split(", ", false)
		var forms := []
		for n in range(clauses.size(), 0, -1):
			forms.append(", ".join(clauses.slice(0, n)) + ((" +%d" % (clauses.size() - n)) if n < clauses.size() else ""))
		var tone := word_tone(m)
		out.append({"forms": [nm], "colour": Pal.tone_color(tone) if tone != "" else Pal.TEXT_2, "tail": forms})
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
			chips.append(["%.0f%% %s · you resist %.0f%%%s" % [share * 100.0, ty, sim.resist(ty) * 100.0, ot], "%s · resist %.0f%%%s" % [ty.capitalize(), sim.resist(ty) * 100.0, ot], ty])
	if chips.is_empty():
		chips.append(["Physical only · armour takes %s" % Fmt.pct(sim.mitigation()), "Physical only", "physical"])
	# the rig short of the fight's rounds (16 Oct): first, in red - the Bank's dry shotgun
	var short: Array = sim.rounds_short(int(t["tier"])) if is_open else []
	if not short.is_empty():
		chips.push_front({"forms": ["Rounds short: %d of ~%d" % [int(short[0]), int(short[1])], "Short: %d of ~%d" % [int(short[0]), int(short[1])], "Rounds short"], "colour": "bad"})     # its shortest says it without the figures, so the resist chip after it keeps its room (18 Oct)
	c["fire_label"].visible = is_open
	c["chips"].visible = is_open
	c["chips"].show_chips(chips if is_open else [], 1, true)     # every chip short before one's left off: the rounds' warning first, so it's never the one (the smoke caught it dropped)


func _depth(k: int, by: int) -> void:
	var i := _tier(k)
	sim.set_depth(i, sim.depth[i] + by)
	acted.emit()


## The rig at the gate's button: Fill up, Best grades only, Leave it, round again (23 Oct).
func _rig(_k: int) -> void:
	var modes: Array = sim.TOP_UP_MODES
	sim.set_top_up(modes[(modes.find(sim.top_up_mode) + 1) % modes.size()])
	_shown = ""
	acted.emit()


## The card's foot: Insure and Rig ▾ in halves, or in thirds with the skills' button when this class has skills.
func _foot_lay(c: Dictionary, is_open: bool) -> void:
	var with_skills: bool = is_open and Data.SKILLS.values().any(func(d): return str(d["cls"]) == sim.cls)
	c["skills"].visible = with_skills
	@warning_ignore("integer_division")
	var w: int = ((INNER - 16) / 3) if with_skills else ((INNER - 8) / 2)
	c["insure"].size.x = w
	c["rig"].position.x = PAD + w + 8 if with_skills else PAD + INNER - w
	c["rig"].size.x = w
	if not with_skills:
		return
	c["skills"].position.x = PAD + INNER - w
	c["skills"].size.x = w
	c["skills"].disabled = sim.on_mission()
	var span: float = 3 * 32 + 2 * 6
	for k in range(Data.SKILL_SLOTS):
		var sp: TextureRect = c["skill_pics"][k]
		var id: String = str(sim.skill_slots[k])
		sp.position = Vector2((w - span) / 2.0 + k * 38, (FOOT_H - 32) / 2.0)
		sp.texture = SkillBar.picture(id) if id != "" else null
		sp.modulate = Color.WHITE if id != "" and sim.skill_known(id) else Color(1, 1, 1, 0.35)
	if sim.skill_slots.all(func(x): return str(x) == ""):
		UI.fit_button(c["skills"], ["Change skills", "Skills"])
	else:
		c["skills"].text = ""


func _skills_open() -> void:
	if sim == null:
		return
	_skill_pick.open(sim)
	_skill_pick.move_to_front()


func _insure(_k: int) -> void:
	sim.set_insure(not sim.insure_next)
	_shown = ""
	acted.emit()


func _deploy(k: int) -> void:
	sim.deploy(_tier(k))
	_skill_pick.visible = false                # set off: the three are locked
	acted.emit()


## The Set off row (29 Oct): Set off, then "Run it ×5" (or Kev's wagers in its place on a run he bets on), then the head's
## toggle when the site has one; Set off takes what's left.
func _repeat_lay(c: Dictionary, i: int, is_open: bool) -> void:
	var wager_on: bool = is_open and sim.wager_site_open(i)
	c["wager"].visible = wager_on
	c["repeat"].visible = is_open and not wager_on
	var right: float = PAD + INNER - (BOSS_W + 8 if c["boss"].visible else 0)
	for b in [c["repeat"], c["wager"]]:
		b.position.x = right - REPEAT_W
	c["deploy"].size.x = (right - REPEAT_W - 8.0 - PAD) if is_open else float(INNER)
	if c["repeat"].visible:
		var n: int = sim.repeat_count()
		var why: String = sim.repeat_block(i)
		c["repeat"].disabled = why != ""
		UI.fit_button(c["repeat"], [Words.REPEAT["button"] % n, Words.REPEAT["button_short"] % n] if n > 0 else [Words.REPEAT["button_full"], Words.REPEAT["button_full_short"], Words.REPEAT["button_full_tiny"]])
	if wager_on:
		var key: String = sim.wager_site_key(i)
		var on: int = sim.wagers.get(key, {}).get("taken", []).size()
		UI.fit_button(c["wager"], [Words.WAGERS["button_on"] % on, Words.WAGERS["button_n"] % on, "%d" % on] if on > 0 else [Words.WAGERS["button"]])     # the count, never a second gold button (the review)


func _repeat(k: int) -> void:
	if sim.start_repeat(_tier(k)):
		_skill_pick.visible = false
	_shown = ""
	acted.emit()


func _wager_open(k: int) -> void:
	var i := _tier(k)
	_wagers.open(sim, sim.wager_site_key(i), Data.TIERS[i]["name"])
	_wagers.move_to_front()
	_shown = ""
	acted.emit()


func _boss(k: int) -> void:
	var i := _tier(k)
	sim.arm_boss(i, not sim.boss_armed.get(i, false))
	acted.emit()


## What came back (12 Oct): a button at the zone row's right while runs have come home since Seen, the zone tabs
## narrowing to make room; pressed, the card drops under it at the screen's right, over the top of the right-hand
## column only (its band and fight), clear of every button. Seen puts both away.
const CAME_BTN_W := 340
const GUIDE_W := 220               # the tier guide's button, the zone row's last
const COUNTY_BTN_W := 220          # the County's, before the tally's (25 Oct)
const CAME_Y := ZONE_H + 4


var _kev_opened := -1               # the beat whose line opened the came-back card


func _show_came_back() -> void:
	_came.show_state(sim)
	var has: bool = _came.visible
	if not has:
		_came_open = false
	# a beat of Kev's story beaten: the card opens itself, once, so his line is seen (20 Oct, Matt: "no pay off")
	var kb: int = int(sim.came_back.get("kev", -1)) if has else -1
	if kb >= 0 and kb != _kev_opened:
		_came_open = true
	_kev_opened = kb
	_came_btn.visible = has
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
	var picking: bool = sim.candidates.size() == 2 and not sim.on_mission()
	_came_btn.disabled = picking
	_came.visible = has and _came_open and order_key == "" and not picking and not county_on     # nor over the County's board (the smoke: it sat on its zones)     # an order's card has the column (20 Oct: the card over it); the trait pick too (the review)
	_came.position = Vector2(Pal.GRID_W - _came.size.x, CAME_Y)
	_came.move_to_front()


func _toggle_came() -> void:
	if county_on:
		_came_open = true                     # on the County board a press always shows it: back to the map (the third review: a dead button)
		set_county(false)
	else:
		_came_open = not _came_open
	_show_came_back()


## For the tests: every label and button with text.
## Why a site reads low (17 Oct, Matt: a 0% with no bandages and no way to buy any): what the runner is short of,
## worst first - no meds, HP under half, a gun with no rounds, a wound, a level under the gear the site drops - as chips,
## each a long form and a short.
static func odds_reasons(s, i: int) -> Array:
	var out: Array = []
	if s.meds_carried() <= 0:
		out.append({"forms": ["No meds"], "colour": "bad"})
	if s.hp < s.max_hp() * 0.5:
		var hp_forms: Array = ["HP %d of %d" % [s.hp_shown(), s.max_hp_shown()], "HP %d" % s.hp_shown()]
		if not s.on_mission() and s.rest_rate_now() > 0.0:
			var full: String = Fmt.mss((s.max_hp() - s.hp) / s.rest_rate_now())
			hp_forms = ["HP %d of %d, full in %s" % [s.hp_shown(), s.max_hp_shown(), full], "HP %d, full in %s" % [s.hp_shown(), full]] + hp_forms     # resting at camp mends it (17 Oct)
		out.append({"forms": hp_forms, "colour": "bad"})
	var gun = s.equipped["Primary"]
	if gun != null and not (Items.ammo_type(gun) in ["", "none"]) and not Items.free_rounds(gun):
		var have: int = s.rounds_for(gun)
		if s.rig_room(1):
			for it in s.stash:                   # the gate tops up from the stash (rounds_short's count)
				if Items.is_ammo(it) and Items.base_of(it)["type"] == Items.ammo_type(gun):
					have += int(it.get("rounds", 0))
		if have <= 0:
			out.append({"forms": ["No rounds"], "colour": "bad"})
	if not s.wounds.is_empty():
		out.append({"forms": [s.wound_words(), "Wounded"], "colour": "warn"})
	var gear_lv: int = s.wear_of(int(s.effective(i)["level"]))
	if s.level() < gear_lv:
		out.append({"forms": ["Level %d; its gear needs level %d" % [s.level(), gear_lv], "Gear needs level %d" % gear_lv], "colour": "warn"})
	# hints off the odds' own runs (23 Oct, parked item 7; Matt: "just hints in the form of chips", never the figures or
	# how the odds are worked): what the body or the guns are short of
	var g: Dictionary = s.odds_gap(i)
	var lost: int = int(g.get("runs", 0)) - int(g.get("alive", 0))
	if not g.is_empty() and lost > 0 and lost * 3 >= int(g["runs"]):
		var hints: Array = []
		if int(g["timed"]) > int(g["killed"]):
			hints.append("Not enough damage")
		else:
			if not out.any(func(r): return str(r["forms"][0]).begins_with("HP ")):
				hints.append("Not enough HP")
			if float(g["phys_share"]) >= 0.35:
				hints.append("Not enough armour")
			if str(g["el_type"]) != "" and float(g["el_share"]) >= 0.35 and s.resist(str(g["el_type"])) < 0.5:
				hints.append("Not enough %s resist" % str(g["el_type"]))
			if float(g.get("lost_down", 0.0)) * 2.0 < float(g["pool"]):
				hints.append("Not enough damage")
			if s.meds_carried() > 0 and s.meds_carried() < 3:
				hints.append("Not enough meds in the rig")
		for h in hints:
			out.append({"forms": [h, h.replace("Not enough ", "More ").replace(" in the rig", "")], "colour": "warn"})     # "Low HP" read as hurt (the language pass)
	# and the one thing to do about it, in green: the site before this one, ground (Matt: "grind previous level")
	var before: int = s.site_before(i)
	if before >= 0 and not out.is_empty():
		out.push_front({"forms": ["Grind %s first" % Words.mid(Data.TIERS[before]["name"]), "Grind %s" % Words.mid(Data.TIERS[before]["name"]), "Grind first"], "colour": "good"})
	return out


func text_nodes() -> Array:
	var out: Array = _text_nodes_under()
	for over in [_report, _wagers]:            # over the map (29 Oct): what's under it isn't the screen's
		if over.visible:
			var r: Rect2 = over.get_global_rect()
			out = out.filter(func(n): return not r.intersects(n.get_global_rect())) + over.text_nodes()
	return out


func _text_nodes_under() -> Array:
	var out: Array = []
	out.append_array(_came.text_nodes())
	if _came_btn.visible:
		out.append(_came_btn)
	if _county_btn.visible:
		out.append(_county_btn)
	out.append(_guide_btn)
	if _guide.visible:
		return _guide.text_nodes() + [_guide_btn]     # over the room: its labels are what shows
	out.append(_title)
	if not _skill_pick.visible:
		out.append_array(_map.text_nodes())     # the picker covers the map
	if _pick.visible:
		out.append_array([_pick_kicker, _pick_title, _pick_line, _pick_line2, _pick_head, _pick_go])
		for c in _pick_cards:
			if c["button"].visible:
				out.append(c["name"])
				out.append_array(c["chips"].text_nodes())
		out.append_array(_pick_lost.text_nodes())
		if _came.visible:
			out.append_array(_came.text_nodes())
		return out
	if _order.visible:
		out.append_array(_order.text_nodes())
		return out
	if _county.visible:
		out.append_array(_county.text_nodes())
		return out
	out.append_array(_skill_pick.text_nodes())
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
		for b in [c["deploy"], c["depth_down"], c["depth_up"], c["boss"], c["insure"], c["rig"], c["skills"], c["repeat"], c["wager"]]:
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
