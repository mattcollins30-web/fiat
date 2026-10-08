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
const YardWorks := preload("res://scripts/ui/yard_works.gd")
const YardTown := preload("res://scripts/ui/yard_town.gd")
const RailButton := preload("res://scripts/ui/rail_button.gd")
const Menu := preload("res://scripts/ui/menu.gd")
const Intro := preload("res://scripts/ui/intro.gd")
const Words := preload("res://scripts/sim/words.gd")
const Juice := preload("res://scripts/ui/juice.gd")
const Sound := preload("res://scripts/ui/sound.gd")
const SETTINGS_FILE := "user://fiat_settings.save"
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
## Where this shell saves: the files above, unless a test points it elsewhere (7 Oct: the smoke wrote the
## player's own autosave and slot 1 on the Legion, and took the autosave with its lost-camp check).
var save_file := SAVE_FILE
var slot_file := SLOT_FILE
const SLOTS := 3
const SAVE_VERSION := 1
const AUTOSAVE_S := 30.0
const REFRESH_S := 0.1
const ODDS_BUDGET := 24             # dry runs a tier a call at most on the Runs screen; the brake is the time (7 Oct)
const ODDS_MS := 5.0                # of odds work a frame on the Runs screen: the screen stays smooth, the tiers settle over a second or two
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
const TOP_KEYS := ["level", "hp", "dps", "xp", "where", "notes", "cash"]
const TOP_WORST := {
	"cash": "£9,999,999",
	"notes": "999,999",
	"level": "50 +999",
	"hp": "999 / 999",
	"dps": "9,999 dmg/s",
	"xp": "9,999,999 / 9,999,999",
	"where": "Out: Ransacked streets",
}
const TOP_GAP := 28
const TOP_GLYPH := 26            # the glyph before a figure (8 Oct)
const TOP_GLYPH_GAP := 8
const TOP_LINE_W := 150          # the line under the HP and XP figures
const TOP_CAPTION_W := 94        # "LEVEL" before the level's figure
const TOP_GLYPH_OF := {"hp": "hp", "dps": "dps", "xp": "xp", "where": "where", "notes": "notes", "cash": "cash"}
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
var _top_glyphs := {}
var _top_lines := {}             # hp, xp: [track, fill]
var _top_caption: Label
var _rail: Control
var _rail_panel: Panel
var _rail_head: Label
var _rail_buttons := {}
var _grid: Control
var _cards: Array = []
var _yard_works                    # the Yard's right half (7 Oct): the yard's jobs on one card two wide
var _yard_town                     # and under it the town and the purse
const YARD_SLOTS := [0, 1, 4, 5]   # the Yard's four cards: the left two columns; the wide pair takes the right
var _armoury
var _barracks
var _missions
var _workshop
var _run
var _juice
var _sound
var _events_seen := 0              # how many log lines the toasts have looked at
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
	# the top bar as a sheet (8 Oct, round two: C on the design canvas): the level a figure with LEVEL beside it,
	# HP and XP as figures with a thin line under each, a glyph before every figure, the place with its pin in the
	# middle, notes and cash with theirs at the right, cash in gold. Each slot as wide as the widest text it can
	# hold, so nothing shifts as figures change.
	var x := 0.0
	var inner: float = 1920.0 - 2 * Pal.MARGIN
	var widths := {}
	for k in TOP_KEYS:
		var weight: String = "SemiBold" if k in ["level", "cash"] else "Medium"
		var size: int = Pal.TITLE if k == "level" else Pal.FLOOR
		widths[k] = ceilf(UI.font(weight, k != "where").get_string_size(TOP_WORST[k], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x) + 4
	var slot_w := func(k: String) -> float:
		return float(widths[k]) + (TOP_GLYPH + TOP_GLYPH_GAP if TOP_GLYPH_OF.has(k) else 0.0) + (TOP_CAPTION_W if k == "level" else 0.0)
	for k in TOP_KEYS:
		var w: float = widths[k]
		var align := HORIZONTAL_ALIGNMENT_LEFT
		match k:
			"where":
				# centred in the room between the runner's figures and the purse, so the widest XP never meets it
				var purse: float = slot_w.call("notes") + TOP_GAP + slot_w.call("cash")
				x = x + (inner - purse - TOP_GAP - x - slot_w.call(k)) / 2.0
			"notes":
				x = inner - slot_w.call("cash") - TOP_GAP - slot_w.call(k)
			"cash":
				x = inner - slot_w.call(k)
		var gx := x
		if TOP_GLYPH_OF.has(k):
			var tint: Color = Pal.ACCENT if k == "cash" else Pal.TEXT_3
			_top_glyphs[k] = UI.glyph(_top_row, Rect2(gx, (Pal.TOP_H - TOP_GLYPH) / 2.0, TOP_GLYPH, TOP_GLYPH), TOP_GLYPH_OF[k], tint)
			x += TOP_GLYPH + TOP_GLYPH_GAP
		if k == "level":
			# LEVEL before the figure (8 Oct, Matt: "1 LEVEL" read wrong)
			_top_caption = UI.label(_top_row, Rect2(x, 0, TOP_CAPTION_W - 8, Pal.TOP_H), "LEVEL", "Medium", Pal.FLOOR, Pal.TEXT_3)
			x += TOP_CAPTION_W
		if k in ["notes", "cash"]:
			align = HORIZONTAL_ALIGNMENT_RIGHT
		var weight: String = "SemiBold" if k in ["level", "cash"] else "Medium"
		var color: Color = Pal.ACCENT if k == "cash" else (Pal.TEXT if k in ["level", "hp", "xp", "dps"] else Pal.TEXT_2)
		if k in ["hp", "xp", "dps"]:
			# the figure sits up, its line under it (dmg/s too, Matt, 8 Oct: "so it reads the same as HP and XP")
			_top_labels[k] = UI.label(_top_row, Rect2(x, 8, w, 34), "", weight, Pal.FLOOR, color, align, true)
			var lw: float = TOP_LINE_W                # the line is the progress, not an underline: one width, the figure may run past it
			_top_lines[k] = [UI.panel(_top_row, Rect2(x, 46, lw, 4), UI.box(Pal.TRACK, 2)),
					UI.panel(_top_row, Rect2(x, 46, lw, 4), UI.box({"hp": Pal.GOOD, "xp": Pal.ACCENT, "dps": Pal.TEXT_2}[k], 2))]
		else:
			_top_labels[k] = UI.label(_top_row, Rect2(x, 0, w, Pal.TOP_H), "", weight, Pal.TITLE if k == "level" else Pal.FLOOR, color, align, k != "where")
		x += w
		x += TOP_GAP
	# the rail as a ledger (8 Oct): one panel, a heading, the rooms as rows under hairlines; its height is the
	# layout's (to the log's bottom), the rows sharing it
	_rail = Control.new()
	add_child(_rail)
	_rail_panel = UI.panel(_rail, Rect2(0, 0, Pal.RAIL_W, Pal.RAIL_HEAD_H + ROOMS.size() * Pal.RAIL_BTN_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_rail_head = UI.label(_rail, Rect2(22, 0, Pal.RAIL_W - 44, Pal.RAIL_HEAD_H), "ROOMS", "Medium", Pal.FLOOR, Pal.TEXT_3)
	UI.panel(_rail, Rect2(0, Pal.RAIL_HEAD_H - 1, Pal.RAIL_W, 1), UI.box(Pal.CARD_LINE, 0))
	for i in range(ROOMS.size()):
		var name: String = ROOMS[i]
		var b = RailButton.new(name)
		b.position = Vector2(0, Pal.RAIL_HEAD_H + i * (Pal.RAIL_BTN_H + Pal.RAIL_GAP))
		b.last = i == ROOMS.size() - 1
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
	_yard_works = YardWorks.new()
	_yard_works.position = Vector2(2 * (Pal.CARD_W + Pal.CARD_GAP), 0)
	_yard_works.acted.connect(refresh)
	_grid.add_child(_yard_works)
	_yard_town = YardTown.new()
	_yard_town.position = Vector2(2 * (Pal.CARD_W + Pal.CARD_GAP), Pal.CARD_H + Pal.CARD_GAP)
	_yard_town.acted.connect(refresh)
	_grid.add_child(_yard_town)
	_armoury = Armoury.new()
	_armoury.acted.connect(refresh)
	_armoury.bench.connect(_open_bench)
	_armoury.visible = false
	add_child(_armoury)
	_barracks = Barracks.new()
	_barracks.acted.connect(refresh)
	_barracks.ascend.connect(_choose_second)
	_barracks.retire.connect(_confirm_retire)
	_barracks.visible = false
	add_child(_barracks)
	_missions = Missions.new()
	_missions.acted.connect(refresh)
	_missions.visible = false
	add_child(_missions)
	_workshop = Workshop.new()
	_workshop.acted.connect(refresh)
	_workshop.bench.connect(_open_bench)
	_workshop.build.connect(_open_builds)
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
	_juice = Juice.new()
	add_child(_juice)
	_run.juice = _juice
	_sound = Sound.new()
	add_child(_sound)
	_load_settings()
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
	_juice.size = s
	_juice.set_top(Pal.TOP_H + 12)
	var x0 := floorf((s.x - 1920.0) / 2.0) + Pal.MARGIN
	_top_row.position = Vector2(x0, 0)
	var free := s.y - Pal.TOP_H - Pal.MARGIN - Pal.CARD_GAP - Pal.EVENTS_H - Pal.MARGIN - Pal.ROOM_H
	var band_y := Pal.TOP_H + Pal.MARGIN + floorf(maxf(0.0, free) / 2.0)
	_rail.position = Vector2(x0, band_y)
	# the rail runs from the band's top to the log's bottom, the rows sharing what's under the heading (8 Oct)
	var rail_h: float = maxf(s.y - Pal.MARGIN - band_y, Pal.RAIL_HEAD_H + ROOMS.size() * 72.0)     # a screen too short for the rows gets rows of 72 and a rail that runs under
	_rail_panel.size.y = rail_h
	var row_h: float = floorf((rail_h - Pal.RAIL_HEAD_H) / ROOMS.size())
	for i in range(ROOMS.size()):
		var b = _rail_buttons[ROOMS[i]]
		b.position.y = Pal.RAIL_HEAD_H + i * row_h
		b.set_row_height(row_h)
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
	_read_odds()
	_move_dps_line(delta)
	_since_refresh += delta
	if _since_refresh >= REFRESH_S:
		_since_refresh = 0.0
		refresh()


## The damage line moves with the fight (Matt, 8 Oct: "a static bar looks weird"): on a run it shows what's
## landing a second against what the kit can put out, so it swings with the spread, spikes on a first shot,
## climbs with walking fire, drops under a resist and falls away while the runner searches; in the yard it
## settles to the kit's share. Eased, a few frames behind.
var _dps_shown := -1.0
func _move_dps_line(delta: float) -> void:
	if not _top_lines.has("dps"):
		return
	var target: float = _dps_share()
	if sim.on_mission():
		var m: Dictionary = sim.mission
		target *= clampf(float(m.get("landed_rate", 0.0)) / maxf(sim.dps(), 1.0), 0.0, 1.6)
		target = minf(target, 1.0)
	if _dps_shown < 0.0:
		_dps_shown = target
	_dps_shown = lerpf(_dps_shown, target, clampf(delta * 8.0, 0.0, 1.0))
	_top_lines["dps"][1].size.x = _top_lines["dps"][0].size.x * _dps_shown


## The Runs screen's odds, a few milliseconds a frame (7 Oct: three dry runs a tier a refresh was half a second
## of stall at the top of the ladder): the zone on screen first, then the rest, until every open tier has settled.
func _read_odds() -> void:
	if not (room == MISSIONS or room == COMMS) or sim.on_mission():
		return
	sim.odds_time_ms = ODDS_MS
	sim.odds_frame_start()
	var order: Array = []
	for i in Data.ZONES[_missions.zone]["tiers"] if _missions.zone < Data.ZONES.size() else []:
		order.append(i)
	for i in range(Data.TIERS.size()):
		if not (i in order):
			order.append(i)
	for i in order:
		if sim._odds_time_up():
			break
		if sim.tier_open(i) and not sim.odds_settled(i):
			sim.survival(i)
	sim.odds_time_ms = 0.0


## The log's best lines as toasts: what was found, who's out and who's down,
## a level, what came off him, a yard moved. Lines the shell's seen stay seen.
func _toast_new_lines() -> void:
	var total: int = sim.events_total
	if _events_seen > total or _events_seen == 0:
		_events_seen = total               # a new game, a load, or the first look: nothing old gets toasted
		return
	var fresh: int = mini(total - _events_seen, sim.events.size())
	var now: float = Time.get_unix_time_from_system()
	for k in range(sim.events.size() - fresh, sim.events.size()):
		var line: String = str(sim.events[k][1])
		var tone := Words.toast_tone(line)
		# only what just happened: a load or a settle brings old lines, and those stay in the log
		if tone != "none" and now - float(sim.events[k][0]) < 5.0 and not (line in _juice.lines()):
			_juice.toast(line, tone)
	_events_seen = total


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
	var saved := FileAccess.file_exists(save_file)
	items.append({"name": "Continue", "detail": _save_words(save_file) if saved else "No camp in progress",
			"action": load_game.bind(save_file), "enabled": saved})
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
		if FileAccess.file_exists(slot_file % (k + 1)):
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
		var path := slot_file % (k + 1)
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
		{"name": "Sound: on" if _sound.enabled else "Sound: off", "detail": "The yard's ambient, the gun, the gangs, the door", "action": _toggle_sound},
		{"name": "Save", "detail": "The autosave; it saves on its own every thirty seconds", "action": _save_and_resume},
		{"name": "Save to a slot", "detail": _slots_words(), "action": show_slots.bind(true, show_pause)},
		{"name": "Quit to title", "detail": "Saves first", "action": _quit_to_title},
	], _menu.close)


func _toggle_sound() -> void:
	_sound.set_enabled(not _sound.enabled)
	_save_settings()
	show_pause()


func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_FILE):
		var f := FileAccess.open(SETTINGS_FILE, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text())
		f.close()
		if d is Dictionary:
			_sound.enabled = bool(d.get("sound", true))


func _save_settings() -> void:
	var f := FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"sound": _sound.enabled}))
		f.close()


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
	sim.odds_budget = ODDS_BUDGET       # the Runs screen reads its odds over a few frames, not in one
	sim.hardcore = hardcore
	sim.start()
	room = OVERVIEW
	speed = 1.0
	_speed_label.visible = false
	_menu.close()
	save_game()
	refresh()


func save_game(path := "") -> void:
	if path == "":
		path = save_file
	if sim == null or sim.camp_lost:
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"version": SAVE_VERSION, "saved": Time.get_unix_time_from_system(), "sim": sim.to_dict()}))
	f.close()
	if path == save_file:
		_since_save = 0.0


func load_game(path := "") -> void:
	if path == "":
		path = save_file
	var d := _read_save(path)
	if d.is_empty():
		return
	sim = Sim.new()
	sim.odds_budget = ODDS_BUDGET       # the Runs screen reads its odds over a few frames, not in one
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
	DirAccess.remove_absolute(save_file)
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
	_toast_new_lines()
	_sound.follow(sim)
	_top_labels["cash"].text = Fmt.money(sim.cash)
	_top_labels["notes"].text = Fmt.num(sim.notes)
	_top_labels["level"].text = ("%d +%d" % [sim.level(), sim.paragon()]) if sim.paragon() > 0 else ("%d" % sim.level())
	_top_labels["hp"].text = "%d / %d" % [sim.hp_shown(), sim.max_hp_shown()]
	_top_labels["dps"].text = "%.0f dmg/s" % sim.dps()
	_top_labels["xp"].text = _xp_words()
	_top_lines["hp"][1].size.x = _top_lines["hp"][0].size.x * clampf(sim.hp / maxf(sim.max_hp(), 1.0), 0.0, 1.0)
	_top_lines["xp"][1].size.x = _top_lines["xp"][0].size.x * _xp_share()
	if _dps_shown < 0.0:
		_top_lines["dps"][1].size.x = _top_lines["dps"][0].size.x * _dps_share()     # the first paint; _move_dps_line has it from there
	# the purse's glyphs before their right-aligned figures
	for k in ["notes", "cash"]:
		var l: Label = _top_labels[k]
		_top_glyphs[k].position.x = l.position.x + l.size.x - ceilf(UI.text_width(l, l.text)) - TOP_GLYPH_GAP - TOP_GLYPH
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
	var slots: Array = YARD_SLOTS if room == OVERVIEW else range(Pal.MAX_CARDS)
	for c in _cards:
		c.visible = false
	for i in range(mini(cards.size(), slots.size())):
		var c = _cards[slots[i]]
		c.visible = true
		c.show_data(cards[i])
	_yard_works.visible = room == OVERVIEW
	_yard_town.visible = room == OVERVIEW
	if room == OVERVIEW:
		_show_yard_works()
		_yard_town.show_data(_town_purse())
	var ev: Array = sim.events
	for i in range(Pal.EVENT_LINES):
		var j := ev.size() - 1 - i
		_event_times[i].text = _time_of_day(ev[j][0]) if j >= 0 else ""
		UI.fit(_event_labels[i], _by_sentence(str(ev[j][1])) if j >= 0 else [""])


## A line's shorter forms: the whole, then fewer sentences, then the first clause - never trailing off.
static func _by_sentence(line: String) -> Array:
	var out: Array = [line]
	var parts := line.split(". ", false)
	for n in range(parts.size() - 1, 0, -1):
		var head := ". ".join(parts.slice(0, n))
		out.append(head if head.ends_with(".") else head + ".")
	var clause := line.get_slice(";", 0).get_slice(":", 0)
	if clause != line and not (clause in out):
		out.append(clause)
	# one long sentence with a comma in it: up to the last comma, with its full stop (a runner's long name in a long base's)
	var first := out.back() as String
	var comma := first.rfind(", ")
	if comma > 0:
		out.append(first.substr(0, comma) + ".")
	return out


## "XP 1,234 / 2,345": into this level, of what the next takes; "XP 101,333" at the top.
func _xp_words() -> String:
	var lv: int = sim.level() + sim.paragon()          # past the cap the paragon levels count on, on the same curve (7 Oct)
	var this_xp := Data.xp_for_level(lv)
	var next_xp := Data.xp_for_level(lv + 1)
	return "%s / %s" % [Fmt.num(sim.xp - this_xp), Fmt.num(next_xp - this_xp)]


## The damage line's fill, 0 to 1: a minute's fire against the best open site's first gang at its depth
## - full when the gang falls inside the minute. It grows with the kit and drops back as a harder site opens.
func _dps_share() -> float:
	var i: int = clampi(sim.best_tier, 0, Data.TIERS.size() - 1)
	var t: Dictionary = sim.effective(i)
	var gang: float = float(t.get("pool", 1)) * float(t.get("hp", 1.0))
	return clampf(sim.dps() * 60.0 / maxf(gang, 1.0), 0.0, 1.0)


## The level's progress, 0 to 1, for the line under the XP figure.
func _xp_share() -> float:
	var lv: int = sim.level() + sim.paragon()
	var this_xp := Data.xp_for_level(lv)
	var next_xp := Data.xp_for_level(lv + 1)
	return clampf((sim.xp - this_xp) / maxf(1.0, next_xp - this_xp), 0.0, 1.0)


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
			# the yard's jobs were easy to miss: the rail says when one is affordable, as the fence's does for a contract
			var can := false
			for j in _yard_jobs():
				if int(j["cost"]) > 0 and bool(j["can"]):
					can = true
			var built := 0
			var of := 0
			for j in _yard_jobs():
				built += int(j["level"])
				of += int(j["of"])
			return {"status1": "Level %d runner" % sim.level(), "status2": Fmt.money(sim.cash), "figure": "%d/%d" % [built, of],
					"badge": "Upgrade" if can else "", "badge_tone": "good"}
		MISSIONS:
			if sim.on_mission():
				var m: Dictionary = sim.mission
				return {"status1": "Picking over" if m["remaining"] == 0 else "%d left" % m["remaining"],
						"status2": sim.tier(m["tier"])["name"], "badge": "Live", "badge_tone": "good"}
			var open_zones := 0
			for z in range(Data.ZONES.size()):
				if sim.zone_open(z):
					open_zones += 1
			return {"status1": "%d zone%s open" % [open_zones, "" if open_zones == 1 else "s"], "status2": "Best: tier %d" % sim.best_tier if sim.best_tier > 0 else "Nothing cleared yet",
					"figure": ("T%d" % sim.best_tier) if sim.best_tier > 0 else ""}
		ARMOURY:
			var n := 0
			for s in Data.SLOTS:
				if sim.equipped[s] != null:
					n += 1
			return {"status1": "%d in the stash" % sim.stash.size(), "status2": "%d of %d slots" % [n, Data.SLOTS.size()], "figure": "%d/%d" % [n, Data.SLOTS.size()]}
		WORKSHOP:
			var fitted := 0
			var atts := 0
			for s in ["Primary", "Secondary"]:
				if sim.equipped[s] != null:
					fitted += Items.fitted_count(sim.equipped[s])
			for it in sim.stash:
				if Items.is_attachment(it):
					atts += 1
			return {"status1": "Upgrade ready" if sim.can_upgrade_workshop() else "%d fitted, %d spare" % [fitted, atts],     # "Upgrade affordable" was 221 px in a 206 line (8 Oct)
					"status2": "Level %d bench" % sim.workshop, "figure": "%d" % sim.workshop}
		BARRACKS:
			var free: int = sim.points_free()
			return {"status1": sim.cls if sim.cls != "" else "No past", "status2": "%d pts spent" % sim.points_spent(), "figure": "%d" % sim.points_spent(),
					"badge": ("%d free" % free) if free > 0 else "", "badge_tone": "good"}
		MEDIC:
			var full: bool = sim.hp >= sim.max_hp() - 0.5
			return {"status1": "HP %d / %d" % [sim.hp_shown(), sim.max_hp_shown()],
					"status2": "Fit" if full else "Resting", "figure": "Fit" if full else "%d%%" % int(round(100.0 * sim.hp / maxf(sim.max_hp(), 1.0))),
					"badge": "" if full or sim.on_mission() else "Hurt", "badge_tone": "warn"}
		MARKET:
			# the contracts were easy to miss as a tab: the rail says when one's ready, or pays a unique
			var ready := 0
			var unique_pay := 0
			for k in range(sim.contracts.size()):
				if sim.can_hand_in(k):
					ready += 1
				elif sim.contracts[k].get("pay", "") == "unique":
					unique_pay += 1
			var badge: String = "Ready" if ready > 0 else ("Unique" if unique_pay > 0 else "")
			return {"status1": ("%d contract%s" % [sim.contracts.size(), "" if sim.contracts.size() == 1 else "s"]) if not sim.contracts.is_empty() else "%d to sell" % sim.stash.size(), "status2": "%d for sale" % sim.market.size(),
					"figure": "%d" % sim.market.size(), "badge": badge, "badge_tone": "good" if ready > 0 else "warn"}
		COMMS:
			var pins := 0
			for p in sim.pinned:
				if p:
					pins += 1
			return {"status1": ("%d pinned" % pins) if pins > 0 else ("Word for cash" if sim.comms_level > 0 else "No set yet"), "status2": "Level %d set" % sim.comms_level, "figure": "%d" % sim.comms_level}
	return {}


# ------------------------------------------------------------------ camp

## A bonus as a signed percent: "+8%", "−5%", "0%"; never "+-5%".
static func _signed_pct(v: float) -> String:
	var r := roundf(v)
	if r < 0.0:
		return "−%.0f%%" % -r
	return "+%.0f%%" % r if r > 0.0 else "0%"


func _camp_cards() -> Array:
	var out := []
	var lv: int = sim.level()
	var next_xp := Data.xp_for_level(mini(lv + 1, Data.MAX_LEVEL))
	var this_xp := Data.xp_for_level(lv)
	var fill: float = 1.0 if lv >= Data.MAX_LEVEL else clampf((sim.xp - this_xp) / maxf(1.0, next_xp - this_xp), 0.0, 1.0)
	# the runner: the fight's figures
	# the runner's past and trait as chips: one each, theirs, gone with them
	var td: Dictionary = sim.trait_data()
	var who := []
	if sim.cls != "":
		who.append([sim.cls, ""])
	if not td.is_empty():
		who.append(["%s: %s" % [td["name"], td["words"]], "good"])
	if sim.wound != "":
		who.push_front([sim.wound_words(), "bad"])                # the wound (30) first: the trait's words are long and a full row drops from the right
	out.append({
		"title": "Runner", "headline": "Level %d" % lv, "unit": "no past yet" if sim.cls == "" else "",
		"bar": {"fill": fill, "text": _xp_words(), "smooth": true},
		"chips": who,
		"lines": [["Damage", "%.0f/s" % sim.dps()], ["Armour", "%.0f (%s)" % [sim.armour(), Fmt.pct(sim.mitigation())]],
			["Pace", "×%.2f" % sim.pace()], ["Pack · rig", "%d cells · %d" % [sim.capacity(), sim.med_capacity()]]],
		"status": ("Wall: %s" % ", ".join(sim.retired)) if not sim.retired.is_empty() else "Runners lost: %d" % sim.operators_lost,     # the wall (36) takes the line once anyone is on it: a third of each one's trait stays
		"note": [sim.next_words(true), sim.next_words(true).replace(" on Runs", "")],     # "Arm the quartermaster on Runs" is the long one
	})
	# the elements: what you deal as each, what you resist of each
	var conv: Dictionary = sim.conversion()
	var elem_share: float = clampf(1.0 - float(conv.get("physical", 1.0)), 0.0, 1.0)
	var elines := []
	var zone_fires := {}
	for i in range(Data.TIERS.size()):
		if sim.tier_open(i):
			for ty in Data.ZONE_TYPES[int(Data.TIERS[i]["zone"])]["types"]:
				zone_fires[ty] = true
	for ty in Data.ELEMENTS:
		var deal: float = float(conv.get(ty, 0.0)) * 100.0
		var res: float = sim.resist(ty) * 100.0
		var words = (["deal %.0f%% · res %.0f%%" % [deal, res], "%.0f%% · res %.0f%%" % [deal, res]]) if deal > 0.0 else ("res %.0f%%" % res)
		elines.append([ty.capitalize(), words, ty])
	var fire_chips := []
	for ty in Data.ELEMENTS:
		if zone_fires.has(ty):
			fire_chips.append([ty.capitalize(), ty])
	out.append({
		"title": "Elements", "headline": "%.0f%%" % (elem_share * 100.0), "unit": "of your damage",
		"chips": fire_chips,
		"lines": elines,
		"note": "Resists cap at %d%%" % int(Data.RESIST_CAP),
		"status": "What the open sites fire" if not fire_chips.is_empty() else "Nothing open fires an element",
	})
	# the finds: quality and quantity, and the rest of what a run gives
	var search_faster: float = (1.0 - sim.search_s({}) / sim.SEARCH_S) * 100.0
	var patrol_later: float = (sim.patrol_s({}) / sim.PATROL_S - 1.0) * 100.0 if not sim.has_node("never_there") else 0.0
	out.append({
		"title": "Finds", "headline": _signed_pct(sim.rarity_bonus() * 100.0), "unit": "loot quality",
		"lines": [["Loot quantity", _signed_pct(sim.loot_bonus() * 100.0)], ["Cash", _signed_pct(sim.tree_sum("cash_pct") + sim.charm_cash())],
			["Notes", _signed_pct(sim._affix_sum("notes_pct"))], ["Search", ("%.0f%% faster" % search_faster) if search_faster > 0.5 else "as it comes"],
			["Gangs", ("%.0f%% later" % patrol_later) if patrol_later > 0.5 else ("never" if sim.has_node("never_there") else "as they come")]],
		"note": "Quality: rarer. Quantity: more",
		"status": "A dog finds +%d a search" % Data.KENNEL_LEVELS[sim.kennel_level]["finds"] if sim.kennel_level > 0 else "No dog yet",
	})
	# the last run
	var r = sim.last_report
	if r != null:
		var t: Dictionary = sim.tier(r["tier"])
		out.append({
			"title": "Last run", "headline": r["outcome"], "unit": "",
			"lines": [["Where", t["name"]], ["Kills · gangs", "%d · %d" % [r["kills"], int(r.get("patrols", 0))]], ["Loot", "%d item%s" % [r["loot"], "" if int(r["loot"]) == 1 else "s"]],
				["Cash · scrap", "%s · %d" % [Fmt.money(r["cash"]), int(r.get("scrap", 0))]], ["Took", Fmt.mss(r["time"])]],
			"tone": "bad" if r["outcome"] == "Dead" else "good",
			"status": (("Lost %s, one carried" if r.has("carried") else "Lost %s of kit") % Fmt.money(r["lost_value"])) if r["outcome"] == "Dead" else (("XP +%s · wounded" % Fmt.num(r["xp"])) if r.get("wounded", false) else "XP +%s" % Fmt.num(r["xp"])),
		})
	else:
		out.append({"title": "Last run", "headline": "None yet", "unit": "", "lines": [], "note": "The first run writes here", "status": ""})
	return out


## The yard's jobs for the wide card (7 Oct): the works, the stash and the bench, each with its level, what it
## does now and next (forms longest first), its price and its action. The fence, the clinic and the radio are
## upgraded in their own rooms.
func _yard_jobs() -> Array:
	var g: Array = Data.GENERATOR_LEVELS
	var lk: Array = Data.LOOKOUT_LEVELS
	var kn: Array = Data.KENNEL_LEVELS
	var st: Array = Data.STASH_LEVELS
	var ws: Array = Data.WORKSHOP
	var gen_words := func(lv: int) -> Array:
		return ["a second rig row", "a rig row"] if g[lv].get("rig_row", false) else ["%d hours away count" % g[lv]["hours"], "%d h away" % g[lv]["hours"]]
	var look_words := func(lv: int) -> Array:
		if lk[lv].get("call", false):
			return ["the call, a full pack", "the call"]
		if lv == 0:
			return ["the odds a guess", "a guess"]
		return ["first gang ×%.1f%s" % [lk[lv]["first"], ", good odds" if int(lk[lv]["runs"]) > int(lk[0]["runs"]) else ""], "first ×%.1f" % lk[lv]["first"]]
	var dog_words := func(lv: int) -> Array:
		if lv == 0:
			return ["no dog"]
		if kn[lv].get("carries", false):
			return ["carries the best home", "carries home"]
		if float(kn[lv]["patrol"]) > 1.0:
			return ["gangs %d%% later, +%d%% quality" % [int(round((float(kn[lv]["patrol"]) - 1.0) * 100.0)), int(kn[lv]["quality"])], "gangs %d%% later" % int(round((float(kn[lv]["patrol"]) - 1.0) * 100.0))]
		return ["+%d a search, +%d%% quality" % [int(kn[lv]["finds"]), int(kn[lv]["quality"])], "+%d a search" % int(kn[lv]["finds"])]
	var stash_words := func(lv: int) -> Array:
		return ["%d cells" % int(st[lv]["cells"])]
	var bench_words := func(lv: int) -> Array:
		var parts: PackedStringArray = str(ws[lv]["words"]).split(": ")
		return [parts[1] if parts.size() > 1 else parts[0], parts[0]]
	var out := []
	for job in [
			["Generator", sim.generator_level, g.size() - 1, gen_words, sim.generator_cost(), sim.can_upgrade_generator(), sim.upgrade_generator],
			["Lookout", sim.lookout_level, lk.size() - 1, look_words, sim.lookout_cost(), sim.can_upgrade_lookout(), sim.upgrade_lookout],
			["Kennel", sim.kennel_level, kn.size() - 1, dog_words, sim.kennel_cost(), sim.can_upgrade_kennel(), sim.upgrade_kennel],
			["Stash", sim.stash_level, st.size() - 1, stash_words, sim.stash_cost(), sim.can_upgrade_stash(), sim.upgrade_stash],
			["Bench", sim.workshop, ws.size() - 1, bench_words, sim.workshop_cost(), sim.can_upgrade_workshop(), sim.upgrade_workshop]]:
		var lv: int = int(job[1])
		var words: Callable = job[3]
		out.append({"name": job[0], "level": lv, "of": int(job[2]), "now": words.call(lv), "next": words.call(mini(lv + 1, int(job[2]))) if int(job[4]) > 0 else [],
				"cost": int(job[4]), "can": bool(job[5]), "action": job[6]})
	return out


func _show_yard_works() -> void:
	var jobs := _yard_jobs()
	var built := 0
	var of := 0
	for j in jobs:
		built += int(j["level"])
		of += int(j["of"])
	_yard_works.show_jobs("The yard", "%d" % built, "of %d levels built" % of, jobs, "The fence, the clinic and the radio are upgraded in their rooms; the stash holds what comes home")


## The town and the purse on one card (7 Oct): the zones with their depths, the trade, what opens the next
## zone; cash, notes and scrap, kit worth, prices. The clock and the autosave in the foot; Move the yard when it can.
func _town_purse() -> Dictionary:
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
	if not sim.trades.is_empty():
		var names := []
		for el in sim.trades:
			names.append(Data.tree_of_element(el)["name"])
		zlines.append(["Yard's trade", ", ".join(names)])
	if not sim.best_dig.is_empty():
		# the yard's best dig, the score across yards (the endgame, 7 Oct)
		var site: String = str(sim.best_dig["site"]).to_lower().trim_prefix("the ")
		zlines.append(["Best dig", ["%s, depth %d · yard %d" % [site, int(sim.best_dig["depth"]), int(sim.best_dig["yard"])], "%s, depth %d" % [site, int(sim.best_dig["depth"])], "%s D%d" % [site, int(sim.best_dig["depth"])], "depth %d" % int(sim.best_dig["depth"])], "accent"])
	var town_note: Variant = [Words.NOTES["zones"] if not sim.campaign_done() else Words.NOTES["zones_done"], Words.NOTES["patch"]]
	if sim.lorry_done:
		town_note = ["The lorry's beaten: move the yard when you're ready", "The lorry's beaten"]
	var d := {
		"title": "The town and the purse" if sim.yard_moves == 0 else "The town and the purse · yard %d" % (sim.yard_moves + 1),
		"headline": Fmt.money(sim.cash), "unit": "in hand",
		"left": {"kicker": "The town · %d of %d zones open" % [open_zones, Data.ZONES.size()], "lines": zlines,
			"note": town_note, "note_tone": "good" if sim.lorry_done else ""},
		"right": {"kicker": "The purse", "lines": [["Cash", Fmt.money(sim.cash), "accent"], ["Notes · scrap", "%d · %d" % [sim.notes, sim.scrap]], ["Kit worth", Fmt.money(sim.loadout_value())],
			["Stash", "%d of %d cells" % [sim.stash_used(), sim.stash_cap()]], ["Prices", ("up %d%%" % sim.inflation_pct()) if sim.inflation_pct() > 0 else "as they were"]],
			"note": "Cash goes off; notes don't" if sim.inflation_pct() > 0 else "What the fence pays"},
		"status": ["Autosaves every 30 s · %s played" % Fmt.clock(sim.elapsed), "%s played" % Fmt.clock(sim.elapsed)],
	}
	if sim.can_move_yard():
		d["button"] = {"text": "Move the yard", "action": _confirm_move, "enabled": true, "primary": sim.lorry_done}
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
	var set_words: PackedStringArray = Data.COMMS_LEVELS[sim.comms_level]["words"].split(": ")
	var tower := {"title": set_words[0], "headline": "Level %d" % sim.comms_level, "unit": "of %d" % (Data.COMMS_LEVELS.size() - 1),
		"band": {"site": "the radio", "tone": 3, "kicker": "The radio"},
		"lines": [["Hears", [set_words[1] if set_words.size() > 1 else "", "the word"]]]}
	if sim.comms_cost() > 0:
		var nxt: PackedStringArray = Data.COMMS_LEVELS[sim.comms_level + 1]["words"].split(": ")
		tower["lines"].append(["Next", [nxt[0], "a better set"]])
		tower["lines"].append(["Costs", Fmt.money(sim.comms_cost())])
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
		# the radio's own words, not the sky's: those are on the Runs card. The
		# words as chips (a harder site's in amber, an easier one's in green), each
		# one's figures on a line under; the odds to clear the fight with them on
		# a row a word: its name in its tone (amber harder, green easier), its effect beside, shortened by clause when it must
		var words: Array = sim.intel[i]
		var lines := []
		if words.is_empty():
			lines.append(["Nothing on the air for it", ""])
		var odds: float = sim.odds_now(i)         # as read so far (the shell reads them a few ms a frame on this room too)
		var zone_i := 0
		for z in range(Data.ZONES.size()):
			if i in Data.ZONES[z]["tiers"]:
				zone_i = z
		var odds_tone := "good" if odds >= 0.9 else ("warn" if odds >= 0.6 else "bad")
		var d := {"title": t["name"], "headline": Words.odds_words(odds), "unit": ("%s to clear, D%d" % [Fmt.pct(odds), t["depth"]]) if sim.odds_settled(i) else "reading the odds",
			"unit_forms": ["%s to clear, D%d" % [Fmt.pct(odds), t["depth"]], "%s, D%d" % [Fmt.pct(odds), t["depth"]], Fmt.pct(odds)] if sim.odds_settled(i) else ["reading the odds", "reading"],
			"band": {"site": t["name"], "tone": zone_i, "kicker": "%s · depth %d" % [Data.ZONES[zone_i]["name"], t["depth"]], "colour": Pal.tone_color(odds_tone) if sim.odds_settled(i) else Pal.TEXT_3},
			"lines": lines, "word_rows": _missions.word_rows(sim, words), "tone": "good" if sim.pinned[i] else ""}
		var buttons := [{"text": "New word (%s)" % _word_price(i, false), "action": sim.buy_intel.bind(i), "enabled": sim.can_buy_intel(i)}]
		if sim.can_pin():
			buttons.append({"text": "Unpin" if sim.pinned[i] else "Pin", "action": sim.set_pinned.bind(i, not sim.pinned[i]), "primary": false,
				"tone": "good" if sim.pinned[i] else ""})
		if sim.can_juice():
			# juicing: call in a word of your choosing, or hold one and re-roll the rest
			buttons.append({"text": "Call in", "action": _choose_word.bind(i, 0), "enabled": sim.can_add_word(i), "primary": false})
			buttons.append({"text": "Hold", "action": _choose_hold.bind(i), "enabled": sim.can_lock_word(i), "primary": false})
		d["buttons"] = buttons
		# a note only while there's a line for it: two rows of buttons and three words fill the card
		if lines.size() + words.size() + 1 <= 4 and buttons.size() <= 2:
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
	_menu.open("Call in a word on %s" % sim.tier(i)["name"].to_lower(), "%s, and the site carries it until a run spends it" % _word_price(i, true), items, _menu.close)


func _add_word(i: int, name: String) -> void:
	sim.add_word(i, name)
	_menu.close()
	refresh()


func _choose_hold(i: int) -> void:
	var items := []
	for name in sim.intel[i]:
		items.append({"name": name, "detail": "Keep this; the rest re-roll", "action": _hold_word.bind(i, name)})
	items.append({"name": "Back", "detail": "", "action": _menu.close})
	_menu.open("Hold a word on %s" % sim.tier(i)["name"].to_lower(), "%s" % (Fmt.count(sim.intel_notes(i) * 2, "note") if sim.words_in_notes() else Fmt.money(sim.intel_cost(i) * 2)), items, _menu.close)


## A word's price as the card says it: cash, or notes under the map's Open channel.
func _word_price(i: int, called: bool) -> String:
	if sim.words_in_notes():
		return Fmt.count(sim.juice_notes(i) if called else sim.intel_notes(i), "note")
	return Fmt.money(sim.juice_cost(i) if called else sim.intel_cost(i))


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
## Retirement (36): the runner to the wall, a third of their trait kept, their kit to the stash, two new to pick from.
func _confirm_retire() -> void:
	var td: Dictionary = sim.trait_data()
	var kept: String = ("a third of %s kept" % td["name"].to_lower()) if not td.is_empty() else "no trait to keep"
	var items := [
		{"name": "Retire %s" % sim.cls.to_lower(), "detail": "Level %d, %d runs. Kit to the stash, trees refunded, %s. Two new turn up." % [sim.level(), sim.runner_runs, kept], "action": _retire},
		{"name": "Not yet", "detail": "", "action": _menu.close},
	]
	_menu.open("Retire to the wall?", "A runner who retires is not a runner who died: the wall keeps a little of what they were, up to three.", items, _menu.close)


func _retire() -> void:
	if sim.retire():
		_menu.close()
		_asked_runner = false
		refresh()


func _confirm_move() -> void:
	var items := [
		{"name": "Move the yard", "detail": "Start again. The uniques, the yard's tree, the list, the wall, half the notes and the yard's trade come. Nothing else.", "action": _pick_trade},
		{"name": "Stay", "detail": "", "action": _menu.close},
	]
	var floor_next: int = mini(sim.yard_moves + 1, Data.LADDER_FLOOR_MAX)
	_menu.open("Move the yard?", "A yard that's moved finds rarer things and more cash (+%d%% each a move), %d points to start, its ladders from depth %d once a site is cleared, and %d free node%s on the yard's tree." % [Data.MOVE_FIND, Data.MOVE_POINTS * (sim.yard_moves + 1), floor_next + 1, sim.yard_moves + 1, "" if sim.yard_moves == 0 else "s"], items, _menu.close)


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
## The Build column (34): a kind, then its builds four a page, each priced in scrap and saying what it wants.
const BUILD_KINDS := [["box", "A box of rounds", "A standard box of any type you have a gun for"], ["grade", "A better grade", "Scrap and the box below it"],
	["med", "A med", "Scrap and the one below it"], ["gun", "An improvised gun", "Common, plain, fires nails whatever it is"], ["grenade", "A grenade", "Scrap and the element's socketable"]]

func _open_builds(page := 0) -> void:
	var items := []
	var kinds: Array = BUILD_KINDS.slice(page * 4, page * 4 + 4)
	for k in kinds:
		items.append({"name": k[1], "detail": k[2], "action": _open_build_kind.bind(k[0], 0)})
	if BUILD_KINDS.size() > (page + 1) * 4:
		items.append({"name": "More …", "detail": "", "action": _open_builds.bind(page + 1)})
	else:
		items.append({"name": "Back", "detail": "", "action": _menu.close})
	_menu.open("Build for scrap", "%d scrap in hand · bench level %d" % [sim.scrap, sim.workshop], items.slice(0, 5), _menu.close)


func _open_build_kind(kind: String, page: int) -> void:
	var opts: Array = sim.build_options(kind)
	var items := []
	for o in opts.slice(page * 4, page * 4 + 4):
		var wants: String = (" · wants %s" % (("a box of %s" % str(o["from"]).to_lower()) if kind == "grade" else str(o["from"]).to_lower())) if o["from"] != "" else ""
		var detail: String = ("Tier %d%s" % [o["tier"], wants]) + ("" if o["ok"] else " · %s" % o["why"])
		items.append({"name": "%s · %d scrap" % [o["name"], o["scrap"]], "detail": detail, "action": _build_one.bind(kind, o["name"]), "enabled": bool(o["ok"])})
	if opts.size() > (page + 1) * 4:
		items.append({"name": "More …", "detail": "", "action": _open_build_kind.bind(kind, page + 1)})
	else:
		items.append({"name": "Back", "detail": "", "action": _open_builds.bind(0)})
	if items.size() > 5:
		items = items.slice(0, 5)
	var title: String = ""
	for k in BUILD_KINDS:
		if k[0] == kind:
			title = k[1]
	_menu.open(title, "%d scrap in hand" % sim.scrap, items, _open_builds.bind(0))


func _build_one(kind: String, name: String) -> void:
	if sim.build(kind, name):
		_menu.close()
		refresh()
		_juice.toast("Built: %s" % name.to_lower(), "good")


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
		items.append({"name": lines[k], "detail": detail, "action": _open_bench_one.bind(id, stat), "color": Pal.tier_color(Items.affix_tier(it, k))})
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
	var short := str(Items.affix_def(stat).get("label", stat))
	_menu.open([label, short, stat] if label != "" else [short, stat], _purse(), items, _open_bench_picks.bind(id))


func _craft_price(kind: String, cost: int) -> String:
	return ("%d notes" % cost) if sim.craft_in_notes(kind) else Fmt.money(cost)


func _purse() -> String:
	return "you have %s and %d notes" % [Fmt.money(sim.cash), sim.notes]


func _craft(id: int, kind: String, stat: String) -> void:
	if sim.craft(id, kind, stat) and _juice != null:
		_juice.toast(sim.last_craft["words"], "good")
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


