extends Control
## The Map, between runs (19 Oct, the drawn Map, Matt's pick B): the map at the left - every zone an area, every site a
## pin in its odds' colour, the order's places once opened (map_view.gd) - and the picked pin's card at the right:
## everything about that site in one place - the hostiles, the odds, the intel - and Set off and Auto at the foot. While
## the runner is out, main.gd shows the live cards instead. Fixed geometry in the card grid's 1536 x 916.

signal acted
signal to_issuer                       # the County card's links (the canvas 'The County board')
signal to_bench
signal to_kit                          # the site card's fix chips (2 Nov, BUILD46-S): armour, HP, damage, resist
signal to_clinic                       # and a wound or HP under half
signal to_radio                        # the Map's goal line: "Signals that bring them" (BUILD49 U, item 21)
signal to_town                         # an order's shut place: its rebuild, the Radio's Town tab (BUILD49 U, item 23)

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const CameBack := preload("res://scripts/ui/came_back.gd")
const TierGuide := preload("res://scripts/ui/tier_guide.gd")
const Order := preload("res://scripts/ui/order.gd")
const County := preload("res://scripts/ui/county.gd")
const MapView := preload("res://scripts/ui/map_view.gd")
const Items := preload("res://scripts/sim/items.gd")
const SkillPicker := preload("res://scripts/ui/skill_picker.gd")
const RoundsPanel := preload("res://scripts/ui/rounds_panel.gd")
const SkillBar := preload("res://scripts/ui/skill_bar.gd")
const RepeatReport := preload("res://scripts/ui/repeat_report.gd")
const WagersPanel := preload("res://scripts/ui/wagers_panel.gd")
const ExpeditionsPanel := preload("res://scripts/ui/expeditions_panel.gd")
const ExpeditionReport := preload("res://scripts/ui/expedition_report.gd")
const SiteCard := preload("res://scripts/ui/site_card.gd")
const WagerOdds := preload("res://scripts/ui/wager_odds.gd")
const KevStory := preload("res://scripts/ui/kev_story.gd")
const WHY_UNDER := 0.6                # the reasons show at Risky and worse

const COL_GAP := 16
@warning_ignore("integer_division")
const COL_W := (Pal.GRID_W - 2 * COL_GAP) / 3                 # 501
const PAD := 20
const INNER := COL_W - 2 * PAD                                # 461
const LINE_H := 28
const REPEAT_W := 170              # "Run it ×5" beside Set off (29 Oct, docs/design/trips.md 1); Kev's wagers in its place before a first clear or a head
const NOTE_UP := 42                # the note's row over Set off, and the death line's under it (BUILD49 U, item 18)
const DEATH_UP := 23.5
const FOOT_H := 48                 # the insurance's row, the rig's top-up beside it (23 Oct, parked item 4)

var sim
var zone := 0                      # the picked site's zone
var selected := -1                 # the site whose card shows (19 Oct: a pin picked); -1 until the first show picks the furthest open
var order_key := ""                # an order's place picked instead (its card in the site's place)
var _map                           # map_view.gd
var _title: Label                  # the row's left: the picked site's zone and its sky
var _cols: Array = []              # the card (one, at the right since the drawn Map): its labels and buttons
var _skill_pick: SkillPicker       # the run's three skills, over the map (milestone 8)
var rounds_panel: RoundsPanel      # the rounds for the run, over the map (BUILD46-R): open_rounds
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
	_goal_build()
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
		# the card's body (2 Nov, BUILD46-S; docs/design/site_card.md): one fixed layout from the picture to "You here",
		# the buttons under it as before
		var body := SiteCard.new(COL_W)
		panel.add_child(body)
		body.fix.connect(_fix)
		body.view_changed.connect(_head_pick.bind(col))     # the card's Head takes him on (BUILD48 item 1: one control)
		c["card"] = body
		# the foot: Set off across, the insurance and the rig's top-up sharing the row under it (21 Oct, Matt: auto-run's
		# gone; 23 Oct: the top-up beside the paper)
		var fy := Pal.ROOM_H - TOP - PAD - FOOT_H
		@warning_ignore("integer_division")
		var half: int = (INNER - 8) / 2
		# insurance: the Fence holds the paper on the kit for the next run
		c["insure"] = UI.button(panel, Rect2(PAD, fy, half, FOOT_H), false)
		c["insure"].pressed.connect(_insure.bind(col))
		# the rounds for the run (BUILD46-R): "Rounds ▾" opens the picker over the map (was the rig's top-up, cycling)
		c["rig"] = UI.button(panel, Rect2(PAD + INNER - half, fy, half, FOOT_H), false)
		c["rig"].pressed.connect(_rig.bind(col))
		c["rig"].tooltip_text = Words.ROUNDS["tip"]
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
		fy -= Pal.BUTTON_H + 6                 # 12 → 6: the room for the death line's row (BUILD49 U, item 18)
		c["deploy"] = UI.button(panel, Rect2(PAD, fy, INNER, Pal.BUTTON_H), true)
		c["deploy"].text = "Set off"
		c["deploy"].pressed.connect(_deploy.bind(col))
		c["town"] = UI.button(panel, Rect2(PAD, fy, INNER, Pal.BUTTON_H), false)     # an order's shut place: its rebuild (item 23)
		c["town"].pressed.connect(func(): to_town.emit())
		c["town"].visible = false
		c["note"] = UI.label(panel, Rect2(PAD, fy - NOTE_UP, INNER, 22), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)     # 24 → 15 px for the death line's row (BUILD49 U, item 18)
		# what a death here costs this runner now (BUILD49 U, item 18; Matt: "Nothing in the game says this"): a dot and a
		# line in the bad tone straight over Set off
		c["death_dot"] = UI.panel(panel, Rect2(PAD + 1, fy - DEATH_UP + 7.5, 7, 7), UI.box(Pal.BAD, 4))
		c["death"] = UI.label(panel, Rect2(PAD + 14, fy - DEATH_UP, INNER - 14, 22), "", "Regular", Pal.CELL_TEXT - 2, Pal.BAD, HORIZONTAL_ALIGNMENT_LEFT, false)
		# the repeat runs (29 Oct): "Run it ×5" beside Set off, shut with its reason on the note; Kev's wagers in its place
		# on a run he bets on (a first clear, a head armed)
		c["repeat"] = UI.button(panel, Rect2(PAD + INNER - REPEAT_W, fy, REPEAT_W, Pal.BUTTON_H), false)
		c["repeat"].pressed.connect(_repeat.bind(col))
		c["wager"] = UI.button(panel, Rect2(PAD + INNER - REPEAT_W, fy, REPEAT_W, Pal.BUTTON_H), false)
		c["wager"].pressed.connect(_wager_open.bind(col))
		c["wager"].visible = false
		_cols.append(c)
	_build_pick()
	rounds_panel = RoundsPanel.new()
	rounds_panel.position = Vector2(20, TOP + 8)
	rounds_panel.acted.connect(func():
		_shown = ""
		acted.emit())
	add_child(rounds_panel)
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
	_exp_build()


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
	var lv: int = sim.level()     # 1 before the Quartermaster; past him the level kept, 50 past the cap (31 Oct)
	var pk: int = sim.paragon() if lv >= Data.MAX_LEVEL else 0     # past 50 the paragon levels are kept too (1 Nov): the kept chip says it
	if lv > 1 or sim.death_keeps_level():     # past the Quartermaster a level-1 runner keeps level 1 too (the re-review)
		UI.fit(_pick_kicker, ["The %s · still level %d" % [who, lv], "Still level %d" % lv])     # a level kept reads as kept, not a reset (31 Oct, the UI review)
	else:
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
	var gone: Dictionary = {"forms": ["The %s's levels" % who, "The levels"], "colour": Pal.BAD}
	if lv >= Data.MAX_LEVEL:
		# past 50 the XP into the paragon level goes, the paragon levels stay (1 Nov; what this death really took, recorded
		# by the sim before the reset, 31 Oct)
		var p_xp: float = float(sim.last_report.get("paragon_lost_xp", 0.0))
		gone = {}
		if p_xp > 0.0:
			gone = {"forms": ["XP towards paragon %d" % (pk + 1), "Paragon XP"], "colour": Pal.BAD}     # one phrase for the loss (1 Nov, the review)
	elif lv > 1:
		gone = {"forms": ["XP towards level %d" % (lv + 1), "The level's XP"], "colour": Pal.BAD}
	var lost: Array = [{"forms": ["The kit worn"], "colour": Pal.BAD}]
	if not gone.is_empty():
		lost.append(gone)
	lost.append_array([{"forms": ["The tree's points back to spend", "The tree's points"], "colour": Pal.TEXT_2}, {"forms": ["The stash"], "colour": Pal.TEXT_2}])
	if sim.crew_played().size() > 1:
		lost.append({"forms": ["The rest of the crew", "The crew"], "colour": Pal.TEXT_2})
	if lv < Data.MAX_LEVEL and (sim.paragon_xp > 0.0 or not sim.ring.is_empty()):
		lost.append({"forms": ["Paragon"], "colour": Pal.TEXT_2})     # kept: the crew's, earned by another class past 50 (a death below 50 leaves it)
	elif pk > 0:
		lost.append({"forms": ["Paragon %d" % pk, "Paragon"], "colour": Pal.TEXT_2})     # kept past 50 too (1 Nov)
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
	if rounds_panel.visible:
		if rounds_panel.site != selected or order_key != "":
			rounds_panel.visible = false             # another site picked: its own plan's behind its own button
		rounds_panel.show_state(sim)
		rounds_panel.move_to_front()
	var picking: bool = sim.candidates.size() == 2 and not sim.on_mission()
	_county_btn.visible = sim.issued and not picking
	if not sim.issued:
		county_on = false
	UI.fit_button(_county_btn, ["Back to the map", "The map"] if county_on else ["The County", "County"])
	UI.style_button(_county_btn, county_on, "good")
	if _exp_state(picking):
		_goal.visible = false                  # the Expeditions over the Map: the goal line under them goes (item 21)
		return                                   # the Expeditions over the map and the card (29 Oct)
	_county.visible = county_on and not picking
	_map.visible = not _county.visible
	_goal_show()                               # the town's goal line over the Map (BUILD49 U, item 21)
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
	_order.visible = false                     # the order's places are drawn by the site card now (BUILD49 U, item 23)
	for c in _cols:
		c["panel"].visible = true
	if on_order:
		_show_order_card(order_key)
		_shown = ""
		_came.move_to_front()
		_guide.move_to_front()
		return
	for c in _cols:
		c["town"].visible = false
	# the odds are read a few milliseconds a frame by the shell (main._read_odds); the screen shows what has settled
	var settled := ""
	for i in range(Data.TIERS.size()):
		settled += ("2" if sim.odds_settled(i) else "1") if sim.odds_ready(i) else "0"
	@warning_ignore("integer_division")
	var sig := "%s|%s|%s|%d|%d|%d|%d|%d|%d|%d|%s" % [str(sim.depth), str(sim.best_depth), str(sim.words) + str(sim.standing) + str(sim.weather) + str(int(sim.elapsed / 60.0)) + settled, 0,
			int(sim.hp), sim.best_tier, int(sim.dps()), int(sim.armour()), sim.tree.size(), selected, str(sim.depot_cleared)] + "|%d|%s|%s|%s|%s|%d" % [sim.notes, str(sim.boss_armed), str(sim.bosses_beaten), str(sim.campaign_done()), str(sim.atlas), sim.atlas_points] + "|%s|%d|%s|%d" % [str(sim.insure_next), int(sim.cash) / 50, sim.top_up_mode, int(sim.odds_read(selected).get("runs", 0))] + "|%s|%s|%s|%d" % [sim.repeat_block(selected), str(sim.wager_site_open(selected)), str(sim.wagers.get(sim.wager_site_key(selected), {})), sim.repeat_count()] \
			+ "|%s|%s|%s|%d|%d|%d|%s" % [str(sim.site_runs.get(str(selected), {})), str(sim.left_behind), sim.cls, sim.rig.size(), sim.stash.size(), sim.stat_v, str(_cols[0]["card"].head_view)] + "|" + WagerOdds.state()     # the site card's (BUILD46-S); Kev's wagers' reads (BUILD49 U)
	if sig == _shown:
		return
	_shown = sig
	for k in range(1):
		var i: int = selected
		var c: Dictionary = _cols[k]
		var t: Dictionary = sim.effective(i)
		var is_open: bool = sim.tier_open(i)
		var odds: float = sim.odds_now(i) if is_open else 0.0     # as read so far: the shell reads them a few ms a frame
		var tone := "good" if odds >= 0.9 else ("warn" if odds >= 0.6 else "bad")
		c["edge"].visible = is_open
		(c["edge"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.tone_color(tone)
		# the card's body (BUILD46-S): what the runner's short of, as fix chips, at Risky and worse
		var why: Array = odds_reasons(sim, i) if is_open and sim.odds_ready(i) and odds < WHY_UNDER else []
		c["card"].head_view = bool(sim.boss_armed.get(i, false))     # the card shows the head when he's taken on, else the gang (BUILD48 item 1)
		c["card"].show_state(sim, i, why)
		c["deploy"].visible = is_open
		var walks: bool = t.get("boss_walks", false) and not sim.boss_armed.get(i, false)     # the Radio's Manager walks: free
		c["deploy"].disabled = not sim.can_deploy_to(i) or (t.has("boss") and not walks and sim.notes < sim.boss_cost(i))
		_repeat_lay(c, i, is_open)
		c["insure"].visible = is_open
		_foot_lay(c, is_open)
		UI.fit_button(c["insure"], ["Insured ✓"] if sim.insure_next else ["Insure kit · %s" % Fmt.money(sim.insure_cost(i)), "Insure · %s" % Fmt.money(sim.insure_cost(i)), "Insure · %s" % Fmt.money(sim.insure_cost(i)).replace(" tins", ""), "Insure"])
		c["insure"].disabled = sim.on_mission() or (not sim.insure_next and not sim.can_insure(i))
		UI.style_button(c["insure"], false, "good" if sim.insure_next else "")
		c["rig"].visible = is_open
		c["rig"].disabled = sim.on_mission()
		UI.fit_button(c["rig"], [Words.ROUNDS["button"], Words.ROUNDS["button_short"]])
		UI.style_button(c["rig"], false, "bad" if not sim.rounds_short(i).is_empty() else "")     # red while the plan's short (BUILD46-R; the merge: the old chips' read went with _show_chips)
		_death_lay(c, i, is_open)
		var rep_why: String = sim.repeat_block(i) if c["repeat"].visible else ""
		var wstrip: Array = WagerOdds.strip_forms(sim, sim.wager_site_key(i)) if is_open and sim.wager_site_open(i) else []     # what's on (BUILD49 U, item 19)
		c["note"].add_theme_color_override("font_color", Pal.WARN if not wstrip.is_empty() and rep_why == "" and not sim.away() and sim.hp >= sim.max_hp() * 0.5 else Pal.TEXT_2)
		if not is_open:
			c["note"].text = ""
		elif sim.away():
			UI.fit(c["note"], [Words.REPEAT["shut_away"]])
		elif sim.hp < sim.max_hp() * 0.5:
			c["note"].text = "The runner is under half HP"
		elif rep_why != "":
			var cnt: int = sim.repeat_count()
			UI.fit(c["note"], [(Words.REPEAT["note"] % [cnt, rep_why]) if cnt > 0 else Words.REPEAT["note_full"] % rep_why, rep_why])     # why "Run it ×5" is shut, on the card (29 Oct)
		elif not wstrip.is_empty():
			UI.fit(c["note"], wstrip)
		else:
			c["note"].text = ""


## An order's place on the card (BUILD49 U, item 23): the site card drawn for it, Set off for it (or, shut, the town's
## rebuild that opens it), Insure, Rounds and the skills for its host site, the death line; no repeat, no wagers.
func _show_order_card(k: String) -> void:
	var c: Dictionary = _cols[0]
	var p: Dictionary = Data.pinnacle(k)
	var i: int = int(p["site"])
	var open: bool = sim.order_open(k)
	var why: Array = []
	var od: Array = sim.order_odds_now(k) if open else [0.0, false]
	if open and bool(od[1]) and float(od[0]) < WHY_UNDER:
		why = odds_reasons(sim, i)
	c["card"].show_order(sim, k, why)
	c["edge"].visible = open
	(c["edge"].get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.tone_color("good" if float(od[0]) >= 0.9 else ("warn" if float(od[0]) >= 0.6 else "bad")) if bool(od[1]) else Pal.CARD_LINE
	c["repeat"].visible = false
	c["wager"].visible = false
	var block: String = sim.order_block(k)
	c["deploy"].visible = open
	c["deploy"].size.x = INNER
	c["deploy"].disabled = block != ""
	UI.fit_button(c["deploy"], [Words.U49_ORDER["set_off"] % Words.mid(str(p["place"])), "Set off"])
	c["town"].visible = not open
	UI.fit_button(c["town"], [Words.U49_ORDER["town"]])
	c["insure"].visible = open
	c["rig"].visible = open
	_foot_lay(c, open)
	UI.fit_button(c["insure"], ["Insured ✓"] if sim.insure_next else ["Insure kit · %s" % Fmt.money(sim.insure_cost(i)), "Insure · %s" % Fmt.money(sim.insure_cost(i)), "Insure"])
	c["insure"].disabled = sim.on_mission() or (not sim.insure_next and not sim.can_insure(i))
	UI.style_button(c["insure"], false, "good" if sim.insure_next else "")
	c["rig"].disabled = sim.on_mission()
	UI.fit_button(c["rig"], [Words.ROUNDS["button"], Words.ROUNDS["button_short"]])
	_death_lay(c, i, open)
	c["note"].add_theme_color_override("font_color", Pal.TEXT_2)
	if not open:
		var rb: String = str(Data.rebuild(str(p["opened_by"])).get("name", "")).trim_prefix("The ").to_lower()
		UI.fit(c["note"], [Words.U49_ORDER["town_line"] % rb])
	elif block != "" and not sim.on_mission():
		UI.fit(c["note"], [block])
	else:
		c["note"].text = ""


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
	if county_on:
		exp_on = false                         # one over the map at a time (29 Oct)
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


func _depth(k: int, by: int) -> void:
	var i := _tier(k)
	sim.set_depth(i, sim.depth[i] + by)
	acted.emit()


## The card's "Rounds ▾" and its red rounds chip (BUILD46-R): the rounds picker for the site.
func _rig(k: int) -> void:
	open_rounds(_tier(k))


## The rounds for the run over the map, on a site's plan (BUILD46-R, the canvas "Fiat – Rounds and magazines", board 2):
## the one opener - the card's "Rounds ▾", its red rounds chip, and builder S's card call it. -1: the picked site.
func open_rounds(i := -1) -> void:
	if sim == null:
		return
	var at: int = selected if i < 0 else i
	if rounds_panel.visible and rounds_panel.site == at:
		rounds_panel.visible = false          # a second press shuts it
		rounds_panel._grades_shut()
	else:
		_skill_pick.visible = false
		rounds_panel.open(sim, at)
		rounds_panel.move_to_front()
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
	rounds_panel.visible = false               # one panel over the map at a time (BUILD46-R)
	_skill_pick.open(sim)
	_skill_pick.move_to_front()


func _insure(_k: int) -> void:
	sim.set_insure(not sim.insure_next)
	_shown = ""
	acted.emit()


func _deploy(k: int) -> void:
	if order_key != "":
		if sim.deploy_order(order_key):        # an order's place, laid on its host site (item 23)
			_skill_pick.visible = false
			rounds_panel.visible = false
			acted.emit()
		return
	sim.deploy(_tier(k))
	_skill_pick.visible = false                # set off: the three are locked
	rounds_panel.visible = false               # and the rounds have gone out (BUILD46-R)
	acted.emit()


## The Set off row (29 Oct): Set off, then "Run it ×5" (or Kev's wagers in its place on a run he bets on); Set off takes
## what's left. The head's taken on from the card's Gang / Head toggle (BUILD48 item 1), not a button here.
func _repeat_lay(c: Dictionary, i: int, is_open: bool) -> void:
	var wager_on: bool = is_open and sim.wager_site_open(i)
	c["wager"].visible = wager_on
	c["repeat"].visible = is_open and not wager_on
	var right: float = PAD + INNER
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


## The death line by Set off (BUILD49 U, item 18): what a death here costs the runner now - back to level 1 before the
## Quartermaster falls (the level kept after, and at the cap), the worn kit lost unless the run's insured.
static func death_forms(s, i: int) -> Array:
	var D: Dictionary = Words.U49_DEATH
	if bool(s.get("hardcore")):
		return [D["hardcore"]]
	var kept: bool = s.death_keeps_level() or s.level() >= Data.MAX_LEVEL
	var insured: bool = s.insure_next and s.can_insure(i)
	var kit: String = D["insured"] if insured else D["kit"]
	return [(D["kept"] if kept else D["back"]) % kit, (D["kept_short"] if kept else D["back_short"]) % kit]


func _death_lay(c: Dictionary, i: int, is_open: bool) -> void:
	var on: bool = is_open and not sim.away()
	c["death"].visible = on
	c["death_dot"].visible = on
	if on:
		UI.fit(c["death"], death_forms(sim, i))


func _repeat(k: int) -> void:
	if sim.start_repeat(_tier(k)):
		_skill_pick.visible = false
		rounds_panel.visible = false
	_shown = ""
	acted.emit()


func _wager_open(k: int) -> void:
	var i := _tier(k)
	_wagers.open(sim, sim.wager_site_key(i), Data.TIERS[i]["name"])
	_wagers.move_to_front()
	_shown = ""
	acted.emit()


## The card's Gang / Head toggle pressed (BUILD48 item 1, Matt: "there should just be one"): Head takes him on, Gang lets
## him be; the card then shows whichever he is, so the toggle and Set off never disagree.
func _head_pick(k: int) -> void:
	var i := _tier(k)
	var card = _cols[k]["card"]
	var want: bool = bool(card.head_view)
	if want != bool(sim.boss_armed.get(i, false)):
		sim.arm_boss(i, want)
	card.head_view = bool(sim.boss_armed.get(i, false))
	_shown = ""
	acted.emit()


## A fix chip on the site card (2 Nov, BUILD46-S): the meds to the gate's top-up (then the Kit), the rounds to the
## rounds picker, armour and the like to the Kit, a wound or HP to the Clinic, "<site> first" picks that site.
func _fix(act: String) -> void:
	if sim == null:
		return
	if act.begins_with("site:"):
		select(int(act.trim_prefix("site:")))
		acted.emit()
	elif act == "rounds":
		open_rounds(selected)
	elif act == "meds" and not bool(sim.rounds_plan(selected).get("top", true)) and not sim.on_mission():
		sim.plan_set_top(selected, true)       # the gate tops the rig up with meds: this site's plan's tick (merge 46, BUILD46-R's plans)
		_shown = ""
		acted.emit()
	elif act == "clinic" and sim.room_open("clinic"):
		to_clinic.emit()
	else:
		to_kit.emit()


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
		out.append({"forms": ["No meds"], "colour": "bad", "act": "meds"})
	if s.hp < s.max_hp() * 0.5:
		var hp_forms: Array = ["HP %d of %d" % [s.hp_shown(), s.max_hp_shown()], "HP %d" % s.hp_shown()]
		if not s.on_mission() and s.rest_rate_now() > 0.0:
			var full: String = Fmt.mss((s.max_hp() - s.hp) / s.rest_rate_now())
			hp_forms = ["HP %d of %d, full in %s" % [s.hp_shown(), s.max_hp_shown(), full], "HP %d, full in %s" % [s.hp_shown(), full]] + hp_forms     # resting at camp mends it (17 Oct)
		out.append({"forms": hp_forms, "colour": "bad", "act": "clinic"})
	var gun = s.equipped["Primary"]
	if gun != null and not (Items.ammo_type(gun) in ["", "none"]) and not Items.free_rounds(gun):
		var have: int = s.rounds_for(gun)
		if not s.mags_for(gun).is_empty() or s.stash.any(func(x): return Items.mag_fits(x, gun)):
			for it in s.stash:                   # the gate fills the magazines from the stash (rounds_short's count; 30 Oct, a magazine to fill)
				if Items.is_ammo(it) and Items.base_of(it)["type"] == Items.ammo_type(gun):
					have += int(it.get("rounds", 0))
		if s.mags_for(gun).is_empty() and not s.stash.any(func(x): return Items.mag_fits(x, gun)):
			out.append({"forms": ["No magazine"], "colour": "bad", "act": "rounds"})     # boxes but nothing to load them in (the three-stage review, UI 15)
		elif have <= 0:
			out.append({"forms": ["No rounds"], "colour": "bad", "act": "rounds"})
	if not s.wounds.is_empty():
		out.append({"forms": [s.wound_words(), "Wounded"], "colour": "warn", "act": "clinic"})
	var gear_lv: int = s.wear_of(int(s.effective(i)["level"]))
	if s.level() < gear_lv:
		out.append({"forms": ["Level %d; its gear needs level %d" % [s.level(), gear_lv], "Gear needs level %d" % gear_lv], "colour": "warn", "act": "kit"})
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
			out.append({"forms": [h, h.replace("Not enough ", "More ").replace(" in the rig", "")], "colour": "warn", "act": "meds" if h.ends_with("in the rig") else "kit"})     # "Low HP" read as hurt (the language pass)
	# and the one thing to do about it, in green: the site before this one, ground (Matt: "grind previous level")
	var before: int = s.site_before(i)
	if before >= 0 and not out.is_empty():
		out.push_front({"forms": ["Grind %s first" % Words.mid(Data.TIERS[before]["name"]), "Grind %s" % Words.mid(Data.TIERS[before]["name"]), "Grind first"], "colour": "good", "act": "site:%d" % before})
	return out


func text_nodes() -> Array:
	var out: Array = _text_nodes_under()
	for over in [_report, _wagers, _exp_report]:            # over the map (29 Oct): what's under it isn't the screen's
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
	if _exp_btn.visible:
		out.append(_exp_btn)
	out.append(_guide_btn)
	if _guide.visible:
		return _guide.text_nodes() + [_guide_btn]     # over the room: its labels are what shows
	out.append(_title)
	if not _skill_pick.visible and not rounds_panel.visible:
		out.append_array(_map.text_nodes())     # the picker covers the map; the rounds picker too (BUILD46-R)
		if _goal.visible:
			out.append_array([_goal_text, _goal_next] + ([_goal_btn] if _goal_btn.visible else []))
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
	if _exp_panel.visible:
		out.append_array(_exp_panel.text_nodes())     # the Expeditions over the map (29 Oct)
		if _came.visible:
			var er: Rect2 = _came.get_global_rect()     # under the came-back card is out of sight (BUILD49 U: the place card reaches under it)
			out = out.filter(func(n): return _came.is_ancestor_of(n) or not er.intersects(n.get_global_rect()))
		return out
	out.append_array(_skill_pick.text_nodes())
	out.append_array(rounds_panel.text_nodes())
	for c in _cols:
		out.append_array(c["card"].text_nodes())
		out.append(c["note"])
		if c["death"].visible:
			out.append(c["death"])
		for b in [c["deploy"], c["insure"], c["rig"], c["skills"], c["repeat"], c["wager"]]:
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
	for c in _cols:
		if c["panel"].visible and not _pick.visible and not _order.visible and not _county.visible:
			out.append_array(c["card"].line_pairs())     # the card's rows, key and value (BUILD46-S)
	return out


# ------------------------------------------------------------------ the Expeditions tab (29 Oct, docs/design/trips.md 3)

const EXP_BTN_W := 280             # "Expeditions" in the row, before the County's (the fix round: "Expeditions · 1 back" fits)
var exp_on := false
var _exp_btn: Button
var _exp_panel                     # expeditions_panel.gd: over the map and the card while it's on
var _exp_report                    # expedition_report.gd: over the map when a crew's back or held


func _exp_build() -> void:
	var x: float = _county_btn.position.x - COL_GAP - EXP_BTN_W
	_title.size.x = x - COL_GAP
	_exp_btn = UI.button(self, Rect2(x, 0, EXP_BTN_W, ZONE_H), false)
	_exp_btn.pressed.connect(func(): set_expeditions(not exp_on))
	_exp_btn.visible = false
	_exp_panel = ExpeditionsPanel.new()
	_exp_panel.position = Vector2(0, TOP)
	_exp_panel.acted.connect(func():
		_shown = ""
		acted.emit())
	_exp_panel.report.connect(func(id: int):
		_exp_report.id = id
		_shown = ""
		acted.emit())
	add_child(_exp_panel)
	_exp_report = ExpeditionReport.new()
	_exp_report.position = Vector2((Pal.GRID_W - ExpeditionReport.W) / 2.0, TOP + 40)
	_exp_report.acted.connect(func():
		_shown = ""
		acted.emit())
	add_child(_exp_report)


func set_expeditions(on: bool) -> void:
	exp_on = on and sim != null and sim.expeditions_open()
	if exp_on:
		county_on = false
		_county.hide_shut()
	_shown = ""
	if sim != null:
		show_state(sim)


## The tab's button, the panel over the map and the card, the report over everything: true when the panel has the room.
func _exp_state(picking: bool) -> bool:
	var E: Dictionary = Words.EXPEDITIONS
	var open: bool = sim.expeditions_open()
	_exp_btn.visible = open and not picking
	if not open:
		exp_on = false
	var back: int = sim.expeditions.filter(func(e): return str(e["state"]) != "out").size()
	UI.fit_button(_exp_btn, [E["tab_map"], E["tab_map_short"]] if exp_on else ([E["tab_back"] % back, E["tab_back_short"] % back] if back > 0 else [E["tab"], E["tab_short"]]))
	UI.style_button(_exp_btn, exp_on or back > 0, "good" if exp_on else "")
	_exp_report.show_state(sim)
	_exp_report.move_to_front()
	_exp_panel.visible = exp_on and not picking
	if not _exp_panel.visible:
		return false
	_map.visible = false
	_county.visible = false
	_order.visible = false
	_pick.visible = false
	for c in _cols:
		c["panel"].visible = false
		c["edge"].visible = false
	var out_n: int = sim.exp_busy() - back
	UI.fit(_title, [E["title"] + " · " + (E["progress_back"] % [out_n, back] if back > 0 else E["progress"] % [out_n, sim.exp_at_once()]), E["title"]])     # out and back apart (the UI review's B9)
	_exp_panel.show_state(sim)
	_shown = ""
	_exp_report.move_to_front()
	_guide.move_to_front()
	return true

# ------------------------------------------------------------------ the town's goal line (BUILD49 U, item 21)

## Over the drawn Map, always on from the Radio's opening (docs/design/act_two.md §1; Matt: "Where is the county unlock
## after this ?"): "The town: N of 6 running" with six pips, the next step and what it still wants, and "Signals that
## bring them" to the Radio. Before the Radio: "The town: the Radio first".
const GOAL_H := 44
const GOAL_BTN_W := 232
const GOAL_PIP := 12
const GOAL_PIP_R := 6
var _goal: Panel
var _goal_text: Label
var _goal_pips: Array = []
var _goal_next: Label
var _goal_btn: Button


func _goal_build() -> void:
	_goal = UI.panel(self, Rect2(8, TOP + 8, MAP_W - 16, GOAL_H), UI.box(Color(Pal.BG, 0.88), 8, 1, Pal.CARD_LINE))
	_goal_text = UI.label(_goal, Rect2(14, 0, 240, GOAL_H), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(Data.REBUILDS.size()):
		var pp := UI.panel(_goal, Rect2(0, (GOAL_H - GOAL_PIP) / 2.0, GOAL_PIP, GOAL_PIP), UI.box(Color(0, 0, 0, 0), GOAL_PIP_R, 2, Pal.ACCENT))
		_goal_pips.append(pp)
	_goal_next = UI.label(_goal, Rect2(0, 0, 100, GOAL_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_goal_btn = UI.button(_goal, Rect2(MAP_W - 16 - 6 - GOAL_BTN_W, 5, GOAL_BTN_W, GOAL_H - 10), false)
	_goal_btn.add_theme_font_size_override("font_size", Pal.CELL_TEXT)
	_goal_btn.text = Words.U49_NEXT["signals"]
	_goal_btn.pressed.connect(func(): to_radio.emit())


## The places running: built at their first rank (the goal line counts a place at its first rank, act two §1).
static func town_running(s) -> int:
	var n := 0
	for r in Data.REBUILDS:
		if int(s.rebuild_rank(str(r["key"]))) > 0:
			n += 1
	return n


var _goal_sig := ""
func _goal_show() -> void:
	if _goal.visible != _map.visible:
		_goal.visible = _map.visible
	if not _goal.visible:
		return
	var radio: bool = sim.room_open("radio")
	var run: int = town_running(sim)
	var gs: String = "%s|%d|%s|%s|%s" % [str(radio), run, str(sim.rebuilt), str(sim.materials), str(sim.key_items)]
	if gs == _goal_sig:
		return                                 # laid out once a change (the Map's frame budget: BUILD43)
	_goal_sig = gs
	var x: float = 14.0
	if not radio:
		UI.fit(_goal_text, [Words.U49_NEXT["goal_pre"]])
	else:
		UI.fit(_goal_text, [Words.U49_NEXT["goal"] % [run, Data.REBUILDS.size()]])
	_goal_text.size.x = ceilf(UI.text_width(_goal_text, _goal_text.text)) + 2
	x += _goal_text.size.x + 12
	for k in range(_goal_pips.size()):
		var pp: Panel = _goal_pips[k]
		pp.visible = radio
		pp.position.x = x
		x += GOAL_PIP + 5
		pp.add_theme_stylebox_override("panel", UI.box(Pal.ACCENT if k < run else Color(0, 0, 0, 0), GOAL_PIP_R, 0 if k < run else 2, Pal.ACCENT))
	var nk: String = KevStory.town_next(sim) if radio else ""
	_goal_btn.visible = radio and nk != ""
	_goal_next.visible = radio
	if not radio:
		return
	x += 10
	_goal_next.position.x = x
	_goal_next.size.x = (_goal_btn.position.x - 12.0 if _goal_btn.visible else _goal.size.x - 14.0) - x
	if nk == "":
		UI.fit(_goal_next, [Words.U49_NEXT["goal_done"]])
		return
	var what: String = Words.mid(str(Data.rebuild(nk)["name"]))
	var forms: Array = []
	for w in KevStory.wants_forms(sim, nk):
		forms.append((Words.U49_NEXT["goal_next"] % what) + (" · " + str(w) if str(w) != "" else ""))
	forms.append(Words.U49_NEXT["goal_next"] % what)
	UI.fit(_goal_next, forms)
