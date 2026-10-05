extends Control
## Fiat's menu shell, carried from Storeys' (and Pithole's before it): the
## camp's rooms down the left, the selected room's cards on the right, the
## figures across the top and the last events along the bottom. No art - the
## build rule - though this one will want it if it plays.
##
## The first slice (docs/design/concept.md): one operator, one zone in three
## tiers, a mission as the idle action with combat as numbers underneath,
## loot with affixes, KIA takes the loadout, the depot clear as the win. The
## game autosaves every thirty seconds and on closing; one save. Esc pauses;
## F8 toggles ten-times speed, for testing.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Card := preload("res://scripts/ui/card.gd")
const RailButton := preload("res://scripts/ui/rail_button.gd")
const Menu := preload("res://scripts/ui/menu.gd")
const Intro := preload("res://scripts/ui/intro.gd")
const Words := preload("res://scripts/sim/words.gd")
const Data := preload("res://scripts/sim/data.gd")
const Sim := preload("res://scripts/sim/sim.gd")
const Items := preload("res://scripts/sim/items.gd")
const Armoury := preload("res://scripts/ui/armoury.gd")
const Barracks := preload("res://scripts/ui/barracks.gd")
const Missions := preload("res://scripts/ui/missions.gd")
const Workshop := preload("res://scripts/ui/workshop.gd")
const Run := preload("res://scripts/ui/run.gd")
const Vendor := preload("res://scripts/ui/vendor.gd")

const SAVE_FILE := "user://fiat.save"           # the autosave: the game in progress
const SLOT_FILE := "user://fiat_slot%d.save"    # saves the player makes
const SLOTS := 3
const SAVE_VERSION := 1
const AUTOSAVE_S := 30.0
const REFRESH_S := 0.1
const OVERVIEW := "The Yard"
const MISSIONS := "Runs"
const ARMOURY := "Lock-up"
const MEDIC := "Clinic"
const MARKET := "The Fence"
const BARRACKS := "Caravan"
const WORKSHOP := "Bench"
const COMMS := "Radio"
const ROOMS := [OVERVIEW, MISSIONS, ARMOURY, WORKSHOP, BARRACKS, MEDIC, MARKET, COMMS]

## The top bar: level and HP on the left, where the runner is in the centre,
## cash on the right; each in a fixed slot as wide as the widest text it can
## hold, so nothing shifts as figures change.
const TOP_KEYS := ["level", "hp", "xp", "where", "notes", "cash"]
const TOP_WORST := {
	"cash": "£9,999,999",
	"notes": "999,999 notes",
	"level": "Level 50",
	"hp": "HP 999 / 999",
	"xp": "XP 999,999 / 999,999",
	"where": "Out: Ransacked streets",
}
const TOP_GAP := 28
const EVENT_TIME_WORST := "99:59:59"
const SPEED_TEXT := "×10 speed (F8)"

var sim
var room := OVERVIEW
var speed := 1.0
var _since_save := 0.0
var _since_refresh := 0.0

var _bg: Panel
var _top: Panel
var _top_row: Control
var _top_labels := {}
var _rail: Control
var _rail_buttons := {}
var _grid: Control
var _cards: Array = []
var _armoury
var _barracks
var _missions
var _workshop
var _run
var _fence
var _clinic
var _events: Panel
var _event_times: Array[Label] = []
var _event_labels: Array[Label] = []
var _speed_label: Label
var _menu
var intro := true                  # the studio card before the title; the tests turn it off
var _asked_runner := false         # the two-turn-up menu, shown once per death


func _init() -> void:
	_build()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()
	if intro:
		var card := Intro.new()
		card.done.connect(show_title)
		add_child(card)
	else:
		show_title()


# ------------------------------------------------------------------ building

func _build() -> void:
	_bg = UI.panel(self, Rect2(Vector2.ZERO, Vector2(1920, 1080)), UI.box(Pal.BG, 0))
	_top = UI.panel(self, Rect2(0, 0, 1920, Pal.TOP_H), UI.box(Pal.PANEL, 0))
	_top_row = Control.new()
	_top_row.size = Vector2(1920 - 2 * Pal.MARGIN, Pal.TOP_H)
	_top.add_child(_top_row)
	var x := 0.0
	for k in TOP_KEYS:
		var w := ceilf(UI.font("Medium", k != "where").get_string_size(TOP_WORST[k], HORIZONTAL_ALIGNMENT_LEFT, -1, Pal.FLOOR).x) + 4
		var align := HORIZONTAL_ALIGNMENT_LEFT
		match k:
			"where":
				x = (1920.0 - 2 * Pal.MARGIN - w) / 2.0
				align = HORIZONTAL_ALIGNMENT_CENTER
			"notes":
				var cw := ceilf(UI.font("Medium").get_string_size(TOP_WORST["cash"], HORIZONTAL_ALIGNMENT_LEFT, -1, Pal.FLOOR).x) + 4
				x = 1920.0 - 2 * Pal.MARGIN - cw - TOP_GAP - w
				align = HORIZONTAL_ALIGNMENT_RIGHT
			"cash":
				x = 1920.0 - 2 * Pal.MARGIN - w
				align = HORIZONTAL_ALIGNMENT_RIGHT
		_top_labels[k] = UI.label(_top_row, Rect2(x, 0, w, Pal.TOP_H), "", "Medium" if k != "cash" else "SemiBold", Pal.FLOOR,
				Pal.TEXT if k == "cash" else Pal.TEXT_2, align, k != "where")
		x += w + TOP_GAP
	_rail = Control.new()
	add_child(_rail)
	for i in range(ROOMS.size()):
		var name: String = ROOMS[i]
		var b = RailButton.new(name)
		b.position = Vector2(0, i * (Pal.RAIL_BTN_H + Pal.RAIL_GAP))
		b.pressed.connect(show_room.bind(name))
		_rail.add_child(b)
		_rail_buttons[name] = b
	_grid = Control.new()
	add_child(_grid)
	for i in range(Pal.MAX_CARDS):
		var c = Card.new()
		c.position = Vector2((i % Pal.COLS) * (Pal.CARD_W + Pal.CARD_GAP), (i / Pal.COLS) * (Pal.CARD_H + Pal.CARD_GAP))
		c.acted.connect(refresh)
		_grid.add_child(c)
		_cards.append(c)
	_armoury = Armoury.new()
	_armoury.acted.connect(refresh)
	_armoury.bench.connect(_open_bench)
	_armoury.visible = false
	add_child(_armoury)
	_barracks = Barracks.new()
	_barracks.acted.connect(refresh)
	_barracks.ascend.connect(_choose_second)
	_barracks.visible = false
	add_child(_barracks)
	_missions = Missions.new()
	_missions.acted.connect(refresh)
	_missions.visible = false
	add_child(_missions)
	_workshop = Workshop.new()
	_workshop.acted.connect(refresh)
	_workshop.bench.connect(_open_bench)
	_workshop.visible = false
	add_child(_workshop)
	_run = Run.new()
	_run.acted.connect(refresh)
	_run.visible = false
	add_child(_run)
	_fence = Vendor.new()
	_fence.setup("fence")
	_fence.acted.connect(refresh)
	_fence.visible = false
	add_child(_fence)
	_clinic = Vendor.new()
	_clinic.setup("clinic")
	_clinic.acted.connect(refresh)
	_clinic.visible = false
	add_child(_clinic)
	_events = UI.panel(self, Rect2(0, 0, Pal.GRID_W, Pal.EVENTS_H), UI.box(Pal.PANEL, 8))
	var tones := [Pal.TEXT, Pal.TEXT_2, Pal.TEXT_3]
	var tw := ceilf(UI.font("Regular").get_string_size(EVENT_TIME_WORST, HORIZONTAL_ALIGNMENT_LEFT, -1, Pal.FLOOR).x)
	var sw := ceilf(UI.font("SemiBold", false).get_string_size(SPEED_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, Pal.FLOOR).x)
	for i in range(Pal.EVENT_LINES):
		_event_times.append(UI.label(_events, Rect2(20, 4 + i * 27, tw, 27), "", "Regular", Pal.FLOOR, tones[i],
				HORIZONTAL_ALIGNMENT_RIGHT))
		_event_labels.append(UI.label(_events, Rect2(20 + tw + 20, 4 + i * 27, Pal.GRID_W - 40 - tw - 20 - sw - 20, 27), "",
				"Regular", Pal.FLOOR, tones[i], HORIZONTAL_ALIGNMENT_LEFT, false))
	_speed_label = UI.label(_events, Rect2(Pal.GRID_W - 20 - sw, 4, sw, 27), SPEED_TEXT, "SemiBold", Pal.FLOOR, Pal.WARN,
			HORIZONTAL_ALIGNMENT_RIGHT, false)
	_speed_label.visible = false
	_menu = Menu.new()
	add_child(_menu)


# ------------------------------------------------------------------ layout

func _on_resize() -> void:
	layout(get_viewport_rect().size)


## 1920 x 1080 is the design; a taller screen's extra height goes above and
## below the grid.
func layout(s: Vector2) -> void:
	_bg.size = s
	_top.size = Vector2(s.x, Pal.TOP_H)
	var x0 := floorf((s.x - 1920.0) / 2.0) + Pal.MARGIN
	_top_row.position = Vector2(x0, 0)
	var free := s.y - Pal.TOP_H - Pal.MARGIN - Pal.CARD_GAP - Pal.EVENTS_H - Pal.MARGIN - Pal.ROOM_H
	var band_y := Pal.TOP_H + Pal.MARGIN + floorf(maxf(0.0, free) / 2.0)
	_rail.position = Vector2(x0, band_y)
	_grid.position = Vector2(x0 + Pal.RAIL_W + Pal.MARGIN, band_y)
	_armoury.position = _grid.position
	_barracks.position = _grid.position
	_missions.position = _grid.position
	_workshop.position = _grid.position
	_run.position = _grid.position
	_fence.position = _grid.position
	_clinic.position = _grid.position
	# the log sits under the grid, bottom right; the rail runs the full height beside it
	_events.position = Vector2(x0 + Pal.RAIL_W + Pal.MARGIN, s.y - Pal.MARGIN - Pal.EVENTS_H)
	_menu.layout(s)


# ------------------------------------------------------------------ the clock

func _process(delta: float) -> void:
	if sim == null or _menu.visible:
		return
	sim.advance(delta * speed)
	if sim.camp_lost:
		show_camp_lost()
		return
	_since_save += delta
	if _since_save >= AUTOSAVE_S:
		save_game()
	_since_refresh += delta
	if _since_refresh >= REFRESH_S:
		_since_refresh = 0.0
		refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _menu.visible:
				_menu.back()
			elif sim != null:
				show_pause()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F8 and sim != null:
			speed = 1.0 if speed > 1.0 else 10.0
			_speed_label.visible = speed > 1.0
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and sim != null:
		save_game()


# ------------------------------------------------------------------ menus

func show_title() -> void:
	var items := []
	var saved := FileAccess.file_exists(SAVE_FILE)
	items.append({"name": "Continue", "detail": _save_words(SAVE_FILE) if saved else "No camp in progress",
			"action": load_game.bind(SAVE_FILE), "enabled": saved})
	items.append({"name": "New camp", "detail": "One runner, a nail gun, £150",
			"action": new_game.bind(false), "confirm": "This replaces the camp in progress - press again" if saved else ""})
	items.append({"name": "New camp, hardcore", "detail": "A death ends the yard: stash, cash, everything",
			"action": new_game.bind(true), "confirm": "This replaces the camp in progress - press again" if saved else ""})
	items.append({"name": "Load a slot", "detail": _slots_words(), "action": show_slots.bind(false, show_title)})
	items.append({"name": "Quit", "detail": "", "action": _quit})
	_menu.open("Fiat", "Let it be done", items, Callable(), true)


## "Level 22, £14,437, 2 h 10 m played · 1 Oct, 11:04" for a save file, or "".
func _save_words(path: String) -> String:
	var d := _read_save(path)
	if d.is_empty():
		return ""
	var sd: Dictionary = d["sim"]
	var played: float = float(sd.get("elapsed", 0.0))
	return "Level %d, %s, %s played · %s%s" % [Data.level_for_xp(float(sd.get("xp", 0.0))), Fmt.money(float(sd.get("cash", 0.0))),
			Fmt.away(played), Fmt.when(float(d.get("saved", 0.0))), " · hardcore" if sd.get("hardcore", false) else ""]


func _slots_words() -> String:
	var n := 0
	for k in range(SLOTS):
		if FileAccess.file_exists(SLOT_FILE % (k + 1)):
			n += 1
	return "%d of %d slots used" % [n, SLOTS]


func _read_save(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if not (d is Dictionary) or not d.has("sim"):
		return {}
	return d


## The slots: to save into (from the pause menu) or to load from (from the title).
func show_slots(saving: bool, back: Callable) -> void:
	var items := []
	for k in range(SLOTS):
		var path := SLOT_FILE % (k + 1)
		var used := FileAccess.file_exists(path)
		var words := _save_words(path) if used else "Empty"
		if saving:
			items.append({"name": "Slot %d" % (k + 1), "detail": words, "action": _save_to_slot.bind(path),
					"confirm": "Overwrite this slot - press again" if used else ""})
		else:
			items.append({"name": "Slot %d" % (k + 1), "detail": words, "action": load_game.bind(path), "enabled": used})
	items.append({"name": "Back", "detail": "", "action": back})
	_menu.open("Save to a slot" if saving else "Load a slot", "Saves the player makes; the game autosaves on its own", items, back)


func _save_to_slot(path: String) -> void:
	save_game(path)
	_menu.close()


func show_pause() -> void:
	_menu.open("Paused", "Hardcore camp" if sim.hardcore else "", [
		{"name": "Resume", "detail": "", "action": _menu.close},
		{"name": "Save", "detail": "The autosave; it saves on its own every thirty seconds", "action": _save_and_resume},
		{"name": "Save to a slot", "detail": _slots_words(), "action": show_slots.bind(true, show_pause)},
		{"name": "Quit to title", "detail": "Saves first", "action": _quit_to_title},
	], _menu.close)


func _save_and_resume() -> void:
	save_game()
	_menu.close()


func _quit_to_title() -> void:
	save_game()
	sim = null
	show_title()


# ------------------------------------------------------------------ the game

func new_game(hardcore := false) -> void:
	sim = Sim.new()
	sim.hardcore = hardcore
	sim.start()
	room = OVERVIEW
	speed = 1.0
	_speed_label.visible = false
	_menu.close()
	save_game()
	refresh()


func save_game(path := SAVE_FILE) -> void:
	if sim == null or sim.camp_lost:
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"version": SAVE_VERSION, "saved": Time.get_unix_time_from_system(), "sim": sim.to_dict()}))
	f.close()
	if path == SAVE_FILE:
		_since_save = 0.0


func load_game(path := SAVE_FILE) -> void:
	var d := _read_save(path)
	if d.is_empty():
		return
	sim = Sim.new()
	sim.load_dict(d["sim"])
	room = OVERVIEW
	speed = 1.0
	_speed_label.visible = false
	_menu.close()
	var away := Time.get_unix_time_from_system() - float(d.get("saved", 0.0))
	if away >= 60.0:
		_settle_away(away)
	refresh()


## Offline: the time away runs through the sim - rest, or auto-run missions
## if one was on - up to the cap, and a screen says what happened.
func _settle_away(away: float) -> void:
	var seconds := minf(away, sim.away_cap_s())
	var before: Dictionary = sim.snapshot()
	var left := seconds
	while left > 0.0:
		var step := minf(600.0, left)
		sim.advance(step)
		left -= step
		if sim.camp_lost:
			break
	var after: Dictionary = sim.snapshot()
	# the log's deploys all carry the replay's real time, so the summary counts
	# by cash and items - what the player cares about
	var words := ""
	var runs: int = int(after.get("runs", 0)) - int(before.get("runs", 0))
	if sim.auto_tier >= 0 or runs > 0 or after["cash"] != before["cash"] or after["lost"] != before["lost"]:
		var where: String = sim.tier(sim.auto_tier)["name"].to_lower() if sim.auto_tier >= 0 else "the estate"
		var things: int = after["stash"] - before["stash"]
		words = Words.AWAY["ran"] % [Fmt.away(away), runs, "" if runs == 1 else "s", where, "+" if after["cash"] >= before["cash"] else "", Fmt.money(after["cash"] - before["cash"]),
				things, "" if things == 1 else "s", before["level"], after["level"]]
		if after["lost"] > before["lost"]:
			words += Words.AWAY["lost"]
	else:
		words = Words.AWAY["rested"] % Fmt.away(away)
	if away > seconds:
		words += Words.AWAY["settled"] % Fmt.away(seconds)
	if sim.inflation_pct() > 0:
		words += Words.AWAY["prices"] % sim.inflation_pct()
	if sim.camp_lost:
		show_camp_lost()
		return
	_menu.open(Words.AWAY["title"], words, [{"name": "Continue", "detail": "", "action": _menu.close}], _menu.close)
	save_game()


## Hardcore: the KIA that ended the camp. The autosave goes; the slots stay.
func show_camp_lost() -> void:
	var r = sim.last_report
	var words := "The yard is gone with the runner."
	if r != null and r.has("lost_value"):
		words = "Dead in %s with %s of kit on. The yard is gone with the runner." % [sim.tier(r["tier"])["name"].to_lower(), Fmt.money(r["lost_value"])]
	DirAccess.remove_absolute(SAVE_FILE)
	_menu.open("The yard is lost", words, [{"name": "Back to the title", "detail": "", "action": _to_title_no_save}], _to_title_no_save, true)


func _quit() -> void:
	if is_inside_tree():
		get_tree().quit()


func _to_title_no_save() -> void:
	sim = null
	show_title()


func show_room(name: String) -> void:
	room = name
	refresh()


# ------------------------------------------------------------------ showing

func refresh() -> void:
	if sim == null:
		return
	# two turned up after a death: the choice, once, before anything else
	if sim.candidates.size() == 2 and not _menu.visible and not sim.on_mission() and not _asked_runner:
		_asked_runner = true
		_choose_runner()
	_top_labels["cash"].text = Fmt.money(sim.cash)
	_top_labels["notes"].text = Fmt.count(sim.notes, "note")
	_top_labels["level"].text = "Level %d" % sim.level()
	_top_labels["hp"].text = "HP %d / %d" % [ceili(sim.hp), int(sim.max_hp())]
	_top_labels["xp"].text = _xp_words()
	_top_labels["where"].text = ("Out: " + sim.tier(sim.mission["tier"])["name"]) if sim.on_mission() else "In the yard"
	for name in ROOMS:
		var b = _rail_buttons[name]
		b.set_selected(name == room)
		b.show_status(_rail_status(name))
	# the Lock-up, the Caravan, the Bench and Runs are screens of their own,
	# in the grid's place: Runs is the tiers between runs and the live run
	# with the pack grid while the runner is out
	var missions_screen: bool = room == MISSIONS and not sim.on_mission()
	var run_screen: bool = room == MISSIONS and sim.on_mission()
	_armoury.visible = room == ARMOURY
	_barracks.visible = room == BARRACKS
	_workshop.visible = room == WORKSHOP
	_missions.visible = missions_screen
	_run.visible = run_screen
	_fence.visible = room == MARKET
	_clinic.visible = room == MEDIC
	_grid.visible = not (room == ARMOURY or room == BARRACKS or room == WORKSHOP or room == MISSIONS or room == MARKET or room == MEDIC)
	if room == ARMOURY:
		_armoury.show_state(sim)
	elif room == BARRACKS:
		_barracks.show_state(sim)
	elif room == WORKSHOP:
		_workshop.show_state(sim)
	elif missions_screen:
		_missions.show_state(sim)
	elif run_screen:
		_run.show_state(sim)
	elif room == MARKET:
		_fence.show_state(sim)
	elif room == MEDIC:
		_clinic.show_state(sim)
	var cards: Array
	match room:
		MISSIONS, ARMOURY, BARRACKS, WORKSHOP, MARKET, MEDIC:
			cards = []
		COMMS:
			cards = _comms_cards()
		_:
			cards = _camp_cards()
	for i in range(Pal.MAX_CARDS):
		var c = _cards[i]
		c.visible = i < cards.size()
		if c.visible:
			c.show_data(cards[i])
	var ev: Array = sim.events
	for i in range(Pal.EVENT_LINES):
		var j := ev.size() - 1 - i
		_event_times[i].text = _time_of_day(ev[j][0]) if j >= 0 else ""
		_event_labels[i].text = ev[j][1] if j >= 0 else ""


## "XP 1,234 / 2,345": into this level, of what the next takes; "XP 101,333" at the top.
func _xp_words() -> String:
	var lv: int = sim.level()
	if lv >= Data.MAX_LEVEL:
		return "XP %s" % Fmt.num(sim.xp)
	var this_xp := Data.xp_for_level(lv)
	var next_xp := Data.xp_for_level(lv + 1)
	return "XP %s / %s" % [Fmt.num(sim.xp - this_xp), Fmt.num(next_xp - this_xp)]


## "11:04", local. An event from a save before the log kept the time of day
## carries the run clock instead and shows as such.
func _time_of_day(stamp: float) -> String:
	if stamp < 1e9:
		return Fmt.clock(stamp)
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(int(stamp) + bias)
	return "%02d:%02d" % [d["hour"], d["minute"]]


func _rail_status(name: String) -> Dictionary:
	match name:
		OVERVIEW:
			return {"status1": "Level %d runner" % sim.level(), "status2": Fmt.money(sim.cash)}
		MISSIONS:
			if sim.on_mission():
				var m: Dictionary = sim.mission
				return {"status1": "Picking over" if m["remaining"] == 0 else "%d left" % m["remaining"],
						"status2": sim.tier(m["tier"])["name"], "badge": "Live", "badge_tone": "good"}
			var open_zones := 0
			for z in range(Data.ZONES.size()):
				if sim.zone_open(z):
					open_zones += 1
			return {"status1": "%d zone%s open" % [open_zones, "" if open_zones == 1 else "s"], "status2": "Best: tier %d" % sim.best_tier if sim.best_tier > 0 else "Nothing cleared yet"}
		ARMOURY:
			var n := 0
			for s in Data.SLOTS:
				if sim.equipped[s] != null:
					n += 1
			return {"status1": "%d of %d slots" % [n, Data.SLOTS.size()], "status2": "%d in the stash" % sim.stash.size()}
		WORKSHOP:
			var fitted := 0
			var atts := 0
			for s in ["Primary", "Secondary"]:
				if sim.equipped[s] != null:
					fitted += Items.fitted_count(sim.equipped[s])
			for it in sim.stash:
				if Items.is_attachment(it):
					atts += 1
			return {"status1": "Level %d bench" % sim.workshop,
					"status2": "Upgrade affordable" if sim.can_upgrade_workshop() else "%d fitted, %d spare" % [fitted, atts]}
		BARRACKS:
			var free: int = sim.points_free()
			return {"status1": sim.cls if sim.cls != "" else "No past", "status2": "%d pts spent" % sim.points_spent(),
					"badge": ("%d free" % free) if free > 0 else "", "badge_tone": "good"}
		MEDIC:
			var full: bool = sim.hp >= sim.max_hp() - 0.5
			return {"status1": "HP %d / %d" % [ceili(sim.hp), int(sim.max_hp())],
					"status2": "Fit" if full else "Resting", "badge": "" if full or sim.on_mission() else "Hurt",
					"badge_tone": "warn"}
		MARKET:
			return {"status1": "%d for sale" % sim.market.size(), "status2": "%d to sell" % sim.stash.size()}
		COMMS:
			var pins := 0
			for p in sim.pinned:
				if p:
					pins += 1
			return {"status1": "Level %d set" % sim.comms_level, "status2": ("%d pinned" % pins) if pins > 0 else ("Word for cash" if sim.comms_level > 0 else "No set yet")}
	return {}


# ------------------------------------------------------------------ camp

func _camp_cards() -> Array:
	var out := []
	var lv: int = sim.level()
	var next_xp := Data.xp_for_level(mini(lv + 1, Data.MAX_LEVEL))
	var this_xp := Data.xp_for_level(lv)
	var fill: float = 1.0 if lv >= Data.MAX_LEVEL else clampf((sim.xp - this_xp) / maxf(1.0, next_xp - this_xp), 0.0, 1.0)
	out.append({
		"title": "Runner", "headline": "Level %d" % lv, "unit": "",
		"bar": {"fill": fill, "text": _xp_words(), "smooth": true},
		"lines": [["Damage", "%.0f/s" % sim.dps()], ["Armour", "%.0f (%s)" % [sim.armour(), Fmt.pct(sim.mitigation())]],
			["Max HP", "%d" % int(sim.max_hp())], ["Pack", "%d cells" % sim.capacity()], ["Rig", "%d of %d pouches" % [sim.rig_used(), sim.med_capacity()]]],
		"status": "%s · runners lost: %d" % [sim.cls if sim.cls != "" else "No past yet", sim.operators_lost],
		"note": sim.next_words(true),
	})
	var cash_card := {
		"title": "Cash", "headline": Fmt.money(sim.cash), "unit": "",
		"lines": [["Kit worth", Fmt.money(sim.loadout_value())], ["Stash", "%d of %d cells" % [sim.stash_used(), sim.stash_cap()]]],
		"note": "What the fence pays",
	}
	if sim.stash_cost() > 0:
		cash_card["lines"].append(["Bigger stash", Fmt.money(sim.stash_cost())])
		cash_card["buttons"] = [{"text": "Upgrade stash (%s)" % Fmt.money(sim.stash_cost()), "action": sim.upgrade_stash, "enabled": sim.can_upgrade_stash(), "primary": false}]
	else:
		cash_card["status"] = "The stash is as big as it gets"
	out.append(cash_card)
	var r = sim.last_report
	if r != null:
		var t: Dictionary = sim.tier(r["tier"])
		out.append({
			"title": "Last run", "headline": r["outcome"], "unit": "",
			"lines": [["Where", t["name"]], ["Kills", "%d" % r["kills"]], ["Loot", "%d items" % r["loot"]],
				["Gangs", "%d" % int(r.get("patrols", 0))], ["Cash", Fmt.money(r["cash"])], ["Took", Fmt.mss(r["time"])]],
			"tone": "bad" if r["outcome"] == "Dead" else "good",
			"status": ("Lost %s of kit" % Fmt.money(r["lost_value"])) if r["outcome"] == "Dead" else ("XP +%s" % Fmt.num(r["xp"])),
		})
	var zlines := []
	for z in range(Data.ZONES.size()):
		var deepest := 0
		for i in Data.ZONES[z]["tiers"]:
			deepest = maxi(deepest, sim.best_depth[i])
		zlines.append([Data.ZONES[z]["name"], ("depth %d" % deepest) if deepest > 0 else ("open" if sim.zone_open(z) else "locked")])
	var open_zones := 0
	for z in range(Data.ZONES.size()):
		if sim.zone_open(z):
			open_zones += 1
	var town := {
		"title": "The town" if sim.yard_moves == 0 else "The town · yard %d" % (sim.yard_moves + 1), "headline": "%d" % open_zones, "unit": "of %d zones open" % Data.ZONES.size(),
		"lines": zlines,
		"note": Words.NOTES["zones"] if not sim.campaign_done() else Words.NOTES["zones_done"],
		"tone": "good" if sim.campaign_done() else "",
		"status": Words.NOTES["patch"],
	}
	if not sim.trades.is_empty():
		var names := []
		for el in sim.trades:
			names.append(Data.tree_of_element(el)["name"])
		town["lines"].append(["Yard's trade", ", ".join(names)])
	if sim.can_move_yard():
		town["buttons"] = [{"text": "Move the yard", "action": _confirm_move, "enabled": true, "primary": false}]
	out.append(town)
	out.append({
		"title": "Played", "headline": Fmt.clock(sim.elapsed), "unit": "",
		"lines": [["Now", sim.tier(sim.mission["tier"])["name"] if sim.on_mission() else "in the yard"], ["Prices", ("up %d%%" % sim.inflation_pct()) if sim.inflation_pct() > 0 else "as they were"]],
		"note": "Cash goes off; notes don't" if sim.inflation_pct() > 0 else "",
		"status": "Autosaves every 30 s",
	})
	out.append(_upgrade_card("Generator", "Away counts for", "%d h" % Data.GENERATOR_LEVELS[sim.generator_level]["hours"], Data.GENERATOR_LEVELS, sim.generator_level,
			sim.generator_cost(), sim.can_upgrade_generator(), sim.upgrade_generator, Words.NOTES["generator"]))
	out.append(_upgrade_card("Lookout", "First gang takes", "×%.1f" % Data.LOOKOUT_LEVELS[sim.lookout_level]["first"], Data.LOOKOUT_LEVELS, sim.lookout_level,
			sim.lookout_cost(), sim.can_upgrade_lookout(), sim.upgrade_lookout, "Sees the first gang coming"))
	out.append(_upgrade_card("Kennel", "Extra a search", "+%d" % Data.KENNEL_LEVELS[sim.kennel_level]["finds"], Data.KENNEL_LEVELS, sim.kennel_level,
			sim.kennel_cost(), sim.can_upgrade_kennel(), sim.upgrade_kennel, "A dog, when there is one"))
	return out


## A yard upgrade as a card: its level, what it does now, what the next costs.
func _upgrade_card(title: String, line: String, figure: String, levels: Array, level: int, cost: int, can: bool, action: Callable, status: String) -> Dictionary:
	var d := {"title": title, "headline": "Level %d" % level, "unit": "of %d" % (levels.size() - 1),
		"lines": [[line, figure]], "note": levels[level]["words"].split(":")[0], "status": status}
	if cost > 0:
		d["lines"].append(["Next", Fmt.money(cost)])
		d["buttons"] = [{"text": "Build (%s)" % Fmt.money(cost), "action": action, "enabled": can, "primary": false}]
	else:
		d["status"] = "As good as it gets"
	return d


# ------------------------------------------------------------------ the run
# (the live run is scripts/ui/run.gd: the three panels and the pack grid)

# ------------------------------------------------------------------ armoury

# ------------------------------------------------------------------ the clinic
# (a screen of its own: scripts/ui/clinic.gd - treatment, the shelf, the stash's meds and the rig)


# ------------------------------------------------------------------ the fence
# (a screen of its own: scripts/ui/fence.gd - the shelf and the stash grid)


# ------------------------------------------------------------------ comms tower

func _comms_cards() -> Array:
	var out := []
	var tower := {"title": "The set", "headline": "Level %d" % sim.comms_level, "unit": "of %d" % (Data.COMMS_LEVELS.size() - 1),
		"lines": [["Now", Data.COMMS_LEVELS[sim.comms_level]["words"].split(":")[0]]],
		"note": Data.COMMS_LEVELS[sim.comms_level]["words"].split(": ")[1].capitalize()}
	if sim.comms_cost() > 0:
		tower["lines"].append(["Next", Fmt.money(sim.comms_cost())])
		tower["buttons"] = [{"text": "Build (%s)" % Fmt.money(sim.comms_cost()), "action": sim.upgrade_comms, "enabled": sim.can_upgrade_comms()}]
	else:
		tower["status"] = "As good as it gets"
	out.append(tower)
	if sim.comms_level == 0:
		return out
	for i in range(Data.TIERS.size()):
		if not sim.tier_open(i):
			continue
		var t: Dictionary = sim.effective(i)
		var lines := []
		# the radio's own words, not the sky's: those are on the Runs card
		var words: Array = sim.intel[i]
		var tight: bool = words.size() > 2 and sim.can_juice()     # four buttons leave four lines
		for name in words:
			if tight:
				lines.append([name, sim.modifier(name)["words"]])
			else:
				lines.append([name, ""])
				lines.append(["", sim.modifier(name)["words"]])
		var d := {"title": t["name"], "headline": "D%d" % t["depth"], "unit": sim.zone_name(i), "lines": lines,
			"tone": "good" if sim.pinned[i] else ""}
		var buttons := [{"text": "New word (%s)" % Fmt.money(sim.intel_cost(i)), "action": sim.buy_intel.bind(i), "enabled": sim.can_buy_intel(i)}]
		if sim.can_pin():
			buttons.append({"text": "Unpin" if sim.pinned[i] else "Pin", "action": sim.set_pinned.bind(i, not sim.pinned[i]), "primary": false,
				"tone": "good" if sim.pinned[i] else ""})
		if sim.can_juice():
			# juicing: call in a word of your choosing, or hold one and re-roll the rest
			buttons.append({"text": "Call in", "action": _choose_word.bind(i, 0), "enabled": sim.can_add_word(i), "primary": false})
			buttons.append({"text": "Hold", "action": _choose_hold.bind(i), "enabled": sim.can_lock_word(i), "primary": false})
		d["buttons"] = buttons
		# a note only while there's a line for it: two rows of buttons and three words fill the card
		if lines.size() <= 4 and buttons.size() <= 2:
			d["note"] = "Pinned: runs don't spend it" if sim.pinned[i] else ""
		out.append(d)
	return out


## The menu as a chooser: four words a page and More, for calling one in.
func _choose_word(i: int, page: int) -> void:
	var options: Array = sim.juice_options(i)
	var items := []
	var per := 4
	for k in range(page * per, mini(options.size(), (page + 1) * per)):
		var name: String = options[k]
		items.append({"name": name, "detail": sim.modifier(name)["words"], "action": _add_word.bind(i, name)})
	if (page + 1) * per < options.size():
		items.append({"name": "More", "detail": "", "action": _choose_word.bind(i, page + 1)})
	else:
		items.append({"name": "Back", "detail": "", "action": _menu.close})
	_menu.open("Call in a word on %s" % sim.tier(i)["name"].to_lower(), "%s, and the site carries it until a run spends it" % Fmt.money(sim.juice_cost(i)), items, _menu.close)


func _add_word(i: int, name: String) -> void:
	sim.add_word(i, name)
	_menu.close()
	refresh()


func _choose_hold(i: int) -> void:
	var items := []
	for name in sim.intel[i]:
		items.append({"name": name, "detail": "Keep this; the rest re-roll", "action": _hold_word.bind(i, name)})
	items.append({"name": "Back", "detail": "", "action": _menu.close})
	_menu.open("Hold a word on %s" % sim.tier(i)["name"].to_lower(), "%s" % Fmt.money(sim.intel_cost(i) * 2), items, _menu.close)


## After a death, two turn up: pick who stays.
func _choose_runner() -> void:
	var items := []
	for k in range(sim.candidates.size()):
		var tr: Dictionary = {}
		for t in Data.TRAITS:
			if t["name"] == sim.candidates[k]:
				tr = t
		items.append({"name": tr.get("name", sim.candidates[k]), "detail": tr.get("words", ""), "action": _pick_runner.bind(k)})
	_menu.open("Two turn up at the yard", "One stays. The other moves on.", items, Callable())


func _pick_runner(k: int) -> void:
	sim.choose_runner(k)
	_asked_runner = false
	_menu.close()
	refresh()


## Moving the yard: asked twice, since everything but the uniques goes.
func _confirm_move() -> void:
	var items := [
		{"name": "Move the yard", "detail": "Start again. The uniques, the yard's tree, the list, half the notes and the yard's trade come. Nothing else.", "action": _pick_trade},
		{"name": "Stay", "detail": "", "action": _menu.close},
	]
	_menu.open("Move the yard?", "A yard that's moved finds rarer things, and more cash: +%d%% each a move, and %d points to start." % [Data.MOVE_FIND, Data.MOVE_POINTS], items, _menu.close)


## The yard's trade: one element comes with the move, and every class after
## takes its keystone at the class's own price. Five to pick from, one a move.
func _pick_trade() -> void:
	var items := []
	for el in Data.ELEMENTS:
		if sim.can_trade(el):
			var t: Dictionary = Data.tree_of_element(el)
			var key: Dictionary = t["nodes"][6]
			items.append({"name": t["name"], "detail": "%s for every class, for good: %s" % [key["name"], key["words"]], "action": _move_yard.bind(el)})
	if items.is_empty():
		_move_yard("")
		return
	_menu.open("The yard's trade", "Which trade comes with the yard?", items, _menu.close)


func _move_yard(trade: String) -> void:
	sim.move_yard(trade)
	_menu.close()
	refresh()


## The bench's menu for an item: what can be done to it, in notes.
func _open_bench(id: int) -> void:
	var it: Dictionary = sim.item_by_id(id)
	if it.is_empty():
		return
	# page 1: the whole-item jobs; page 2: the ones that pick an affix
	var page1 := ["reroll", "add", "socket", "strip"]
	var items := []
	for kind in page1:
		var cost: int = sim.craft_cost(it, kind)
		if cost < 0:
			continue
		items.append({"name": "%s · %s" % [Data.CRAFT[kind]["name"], _craft_price(kind, cost)], "detail": Data.CRAFT[kind]["words"] + ("" if sim.can_craft(id, kind) else " · not enough"),
			"action": _craft.bind(id, kind, "")})
	if sim.craft_cost(it, "one", it["affixes"][0]["stat"] if not it["affixes"].is_empty() else "") >= 0 or sim.craft_cost(it, "bump") >= 0:
		items.append({"name": "One affix, or the level …", "detail": "Lock one and re-roll the rest, re-roll one, raise the level", "action": _open_bench_picks.bind(id)})
	items.append({"name": "Back", "detail": "", "action": _menu.close})
	_menu.open(it["base"], "%s · level %d · %s" % [Items.rarity_name(it), Items.ilvl(it), _purse()], items.slice(0, 5), _menu.close)


## The second page: the jobs that pick an affix, and the level in notes.
func _open_bench_picks(id: int) -> void:
	var it: Dictionary = sim.item_by_id(id)
	if it.is_empty():
		return
	var items := []
	var lines: Array = Items.affix_lines(it, true, true)
	for k in range(mini(it["affixes"].size(), 3)):
		var stat: String = it["affixes"][k]["stat"]
		var lock: int = sim.craft_cost(it, "lock", stat)
		var one: int = sim.craft_cost(it, "one", stat)
		var detail := "Re-roll it for %s" % Fmt.money(one)
		if lock >= 0:
			detail += " · keep it and re-roll the rest for %s" % Fmt.money(lock)
		items.append({"name": lines[k], "detail": detail, "action": _open_bench_one.bind(id, stat)})
	var bump: int = sim.craft_cost(it, "bump")
	if bump >= 0 and items.size() < 4:
		items.append({"name": "%s · %d notes" % [Data.CRAFT["bump"]["name"], bump], "detail": Data.CRAFT["bump"]["words"], "action": _craft.bind(id, "bump", "")})
	items.append({"name": "Back", "detail": "", "action": _open_bench.bind(id)})
	_menu.open(it["base"], "Pick an affix · %s" % _purse(), items.slice(0, 5), _open_bench.bind(id))


func _open_bench_one(id: int, stat: String) -> void:
	var it: Dictionary = sim.item_by_id(id)
	if it.is_empty():
		return
	var items := []
	for kind in ["one", "lock"]:
		var cost: int = sim.craft_cost(it, kind, stat)
		if cost >= 0:
			items.append({"name": "%s · %s" % [Data.CRAFT[kind]["name"], Fmt.money(cost)], "detail": Data.CRAFT[kind]["words"] + ("" if sim.can_craft(id, kind, stat) else " · not enough"),
				"action": _craft.bind(id, kind, stat)})
	items.append({"name": "Back", "detail": "", "action": _open_bench_picks.bind(id)})
	var label := ""
	for line in Items.affix_lines(it, false, true):
		if line.contains(str(Items.affix_def(stat).get("label", stat))):
			label = line
	_menu.open(label if label != "" else stat, _purse(), items, _open_bench_picks.bind(id))


func _craft_price(kind: String, cost: int) -> String:
	return ("%d notes" % cost) if sim.craft_in_notes(kind) else Fmt.money(cost)


func _purse() -> String:
	return "you have %s and %d notes" % [Fmt.money(sim.cash), sim.notes]


func _craft(id: int, kind: String, stat: String) -> void:
	sim.craft(id, kind, stat)
	_menu.close()
	refresh()


## The second past, from level 30: a different class, for its first tree.
func _choose_second() -> void:
	var items := []
	for c in Data.CLASSES:
		if c["name"] != sim.cls and c["name"] != sim.cls2 and items.size() < 4:
			items.append({"name": c["name"], "detail": c["words"], "action": _set_second.bind(c["name"])})
	items.append({"name": "Back", "detail": "", "action": _menu.close})
	_menu.open("A second past", "Opens that class's first tree beside yours. Changing it refunds it.", items, _menu.close)


func _set_second(name: String) -> void:
	sim.set_second(name)
	_menu.close()
	refresh()


func _hold_word(i: int, name: String) -> void:
	sim.lock_word(i, name)
	_menu.close()
	refresh()


