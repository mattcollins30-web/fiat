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
const YardTree := preload("res://scripts/ui/yard_tree.gd")
const RadioScreen := preload("res://scripts/ui/radio.gd")
const RailButton := preload("res://scripts/ui/rail_button.gd")
const Menu := preload("res://scripts/ui/menu.gd")
const Intro := preload("res://scripts/ui/intro.gd")
const Words := preload("res://scripts/sim/words.gd")
const Juice := preload("res://scripts/ui/juice.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")
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
const StatsRoom := preload("res://scripts/ui/stats_room.gd")

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
const ARMOURY := "Runner"          # the loadout (9 Oct, Matt: "I click runner expecting to see my loadout"): was the Lock-up
const MEDIC := "Clinic"
const MARKET := "The Fence"
const BARRACKS := "Training"       # the Caravan's room (8 Oct, Matt: "caravan doesn't make any sense when it displays perk points/skill trees"); the Caravan stays as the place on its screen
const WORKSHOP := "Workshop"       # was the Bench (9 Oct); the Bench stays the Yard's building
const COMMS := "Radio"
const RUNNER := "Stats"            # the runner's sheet, attack, defence, the record (8 Oct); was the Runner room until 9 Oct
const ROOMS := [OVERVIEW, RUNNER, ARMOURY, MISSIONS, BARRACKS, WORKSHOP, MEDIC, MARKET, COMMS]     # Matt's order (9 Oct)

## The top bar: level and HP on the left, the purse right-justified on the right. The left group's slots are as wide
## as the widest text they can hold, so nothing there shifts; the purse lays out by its figures as they read
## (_lay_top_right), so a salvage kind can join it.
const TOP_KEYS := ["level", "hp", "xp", "dps", "where", "notes", "scrap", "copper", "steel", "army", "cash"]
## The right group, right to left (10 Oct, Bar-C): the cash, each salvage kind once there's any, scrap, notes, the place.
const TOP_RIGHT := ["cash", "army", "steel", "copper", "scrap", "notes", "where"]
const TOP_SALVAGE := ["copper", "steel", "army"]
const TOP_TONE := {"scrap": Color("eceded"), "copper": Color("d08a5a"), "steel": Color("9fb3c8"), "army": Color("a3b06a")}
const TOP_TIP := {"notes": "Notes: the Radio's currency", "scrap": "Scrap: the Workshop's material", "copper": "Copper: salvage from the Estate's depths, for the Yard",
	"steel": "Safe steel: salvage from the Town's depths, for the Yard", "army": "Army surplus: salvage from the City's depths, for the Yard", "cash": "Cash",
	"where": "Where the runner is"}
const TOP_WORST := {
	"cash": "£9,999,999",
	"notes": "999,999",
	"scrap": "999,999",
	"copper": "9,999",
	"steel": "9,999",
	"army": "9,999",
	"level": "50 +999",
	"hp": "999 / 999",
	"dps": "9,999 dmg/s",
	"xp": "99,999 / 99,999",         # _short reads a hundred thousand up as 123k, so this is the widest
	"where": "Out: Ransacked Streets",
	"class": "Paramedic",
}
const TOP_GAP := 28
const TOP_GLYPH := 26            # the glyph before a figure (8 Oct)
const TOP_GLYPH_GAP := 8
const TOP_LINE_W := 180          # the line under the HP, XP and damage figures: the slots step by it, so the three sit at one gap (8 Oct)
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
var _top_class: Label            # the runner's past after the level's figure
var _rail: Control
var _rail_panel: Panel
var _rail_head: Label
var _rail_buttons := {}
var _grid: Control
var _cards: Array = []
var _yard_tree                     # the Yard (8 Oct): the works as a tree, the town and the purse in its heading
var _radio                         # the Radio (9 Oct): map juicing, the sites and their words, the crafts, the book
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
var _stats                         # the Stats room as a sheet (10 Oct, Stats-R A)
var _events: Panel
var _event_times: Array[Label] = []
var _event_labels: Array[Label] = []
var _prev_time: Label             # the line before the latest, dimmer, at the log's right
var _prev_label: Label
const PREV_X := 1000              # the latest line's widest: the line before starts where it ends
const PREV_GAP := 48
var _speed_label: Label
var _menu
var intro := true                  # the studio card before the title; the tests turn it off
var _asked_runner := false         # the two-turn-up menu, shown once per death


func _init() -> void:
	_build()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_fit_window_to_screen()
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
	# the top bar as a sheet (8 Oct, round two: C on the design canvas; the last pass, Matt: "Level 9 (class)",
	# "sort the gaps", "swap XP and DMG", "right justify" the purse): LEVEL, the figure and the class as one
	# group; HP, XP and damage as figures with one line under each at one gap; the place, notes and cash
	# right-justified at the same gap, their glyphs set before the text on every refresh. Each slot as wide as the
	# widest text it can hold, so nothing shifts as figures change.
	var inner: float = 1920.0 - 2 * Pal.MARGIN
	var widths := {}
	for k in TOP_KEYS + ["class"]:
		var weight: String = "SemiBold" if k in ["level", "cash"] else "Medium"
		var size: int = Pal.TITLE if k == "level" else Pal.FLOOR
		widths[k] = ceilf(UI.font(weight, k != "where").get_string_size(TOP_WORST[k], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x) + 4
	var slot_w := func(k: String) -> float:
		return float(widths[k]) + (TOP_GLYPH + TOP_GLYPH_GAP if TOP_GLYPH_OF.has(k) else 0.0)
	# the left group, in order
	var x := 0.0
	_top_caption = UI.label(_top_row, Rect2(x, 0, TOP_CAPTION_W - 8, Pal.TOP_H), "LEVEL", "Medium", Pal.FLOOR, Pal.TEXT_3)
	x += TOP_CAPTION_W
	_top_labels["level"] = UI.label(_top_row, Rect2(x, 0, widths["level"], Pal.TOP_H), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_top_class = UI.label(_top_row, Rect2(x, 0, widths["class"], Pal.TOP_H), "", "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)   # placed after the figure on refresh
	x += widths["level"] + 10 + widths["class"] + TOP_GAP
	for k in ["hp", "xp", "dps"]:
		_top_glyphs[k] = UI.glyph(_top_row, Rect2(x, (Pal.TOP_H - TOP_GLYPH) / 2.0, TOP_GLYPH, TOP_GLYPH), TOP_GLYPH_OF[k], Pal.TEXT_3)
		x += TOP_GLYPH + TOP_GLYPH_GAP
		# the figure sits up, its line under it: one width, the figure may run past it
		_top_labels[k] = UI.label(_top_row, Rect2(x, 8, widths[k], 34), "", "Medium", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
		_top_lines[k] = [UI.panel(_top_row, Rect2(x, 46, TOP_LINE_W, 4), UI.box(Pal.TRACK, 2)),
				UI.panel(_top_row, Rect2(x, 46, TOP_LINE_W, 4), UI.box({"hp": Pal.GOOD, "xp": Pal.ACCENT, "dps": Pal.TEXT_2}[k], 2))]
		x += TOP_LINE_W + TOP_GAP
	# the right group, right-justified at one gap: the place, notes, scrap, the salvage found, cash (Bar-C); each slot as
	# wide as its widest figure, laid out on refresh so a salvage kind joins when there's any
	for k in TOP_RIGHT:
		var tint: Color = Pal.ACCENT if k == "cash" else Pal.TEXT_3
		if TOP_GLYPH_OF.has(k):
			_top_glyphs[k] = UI.glyph(_top_row, Rect2(0, (Pal.TOP_H - TOP_GLYPH) / 2.0, TOP_GLYPH, TOP_GLYPH), TOP_GLYPH_OF[k], tint)
		else:
			_top_glyphs[k] = UI.glyph(_top_row, Rect2(0, (Pal.TOP_H - TOP_GLYPH) / 2.0, TOP_GLYPH, TOP_GLYPH), k, TOP_TONE[k])
			if UI.glyph_texture(k) == null:
				_top_glyphs[k].texture = NodeGlyphs.texture(k)      # the engine's line glyph until art/ui/<k>.png is painted (the purse manifest)
				_top_glyphs[k].modulate = TOP_TONE[k]
		var color: Color = Pal.ACCENT if k == "cash" else (TOP_TONE[k] if TOP_TONE.has(k) else Pal.TEXT_2)
		_top_labels[k] = UI.label(_top_row, Rect2(0, 0, widths[k], Pal.TOP_H), "", "SemiBold" if k == "cash" else "Medium", Pal.FLOOR, color, HORIZONTAL_ALIGNMENT_RIGHT, k != "where")
		if TOP_TIP.has(k):
			for c in [_top_glyphs[k], _top_labels[k]]:
				c.tooltip_text = TOP_TIP[k]
				c.mouse_filter = Control.MOUSE_FILTER_PASS
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
	_yard_tree = YardTree.new()
	_yard_tree.acted.connect(refresh)
	add_child(_yard_tree)
	_radio = RadioScreen.new()
	_radio.acted.connect(refresh)
	_radio.choose.connect(_choose_word)
	_radio.choose_book.connect(_choose_book)
	_radio.visible = false
	add_child(_radio)
	_armoury = Armoury.new()
	_armoury.acted.connect(refresh)
	_armoury.bench.connect(_open_workshop)
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
	_workshop.craft.connect(_craft)                # the Workshop's jobs, done in the room (8 Oct); worn gear comes in through the Runner room's Workshop button (9 Oct)
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
	_stats = StatsRoom.new()
	_stats.visible = false
	add_child(_stats)
	_events = UI.panel(self, Rect2(0, 0, Pal.GRID_W, Pal.EVENTS_H), UI.box(Pal.PANEL, 8))
	var tones := [Pal.TEXT, Pal.TEXT_2, Pal.TEXT_3]
	var tw := ceilf(UI.font("Regular").get_string_size(EVENT_TIME_WORST, HORIZONTAL_ALIGNMENT_LEFT, -1, Pal.FLOOR).x)
	var sw := ceilf(UI.font("SemiBold", false).get_string_size(SPEED_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, Pal.FLOOR).x)
	for i in range(Pal.EVENT_LINES):
		_event_times.append(UI.label(_events, Rect2(20, 4 + i * 27, tw, 27), "", "Regular", Pal.FLOOR, tones[i],
				HORIZONTAL_ALIGNMENT_LEFT))       # left-justified (8 Oct, Matt: "the log sits oddly"); the line follows the time's width on refresh
		_event_labels.append(UI.label(_events, Rect2(20 + tw + 20, 4 + i * 27, Pal.GRID_W - 40 - tw - 20 - sw - 20, 27), "",
				"Regular", Pal.FLOOR, tones[i], HORIZONTAL_ALIGNMENT_LEFT, false))
	# the line before, dimmer, to the right (8 Oct, Matt: the dead space; a line you missed stays on screen a run)
	_prev_time = UI.label(_events, Rect2(PREV_X, 4, tw, 27), "", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT)
	_prev_label = UI.label(_events, Rect2(PREV_X + tw + 16, 4, Pal.GRID_W - 20 - PREV_X - tw - 16 - sw - 20, 27), "", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
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

## The Steam Deck (8 Oct, Matt: "the lower part of the screen is unclickable -
## anything from fence down"). Greenhorn met the same and its notes carry the
## mechanism (game_manager.gd, _apply_native_window_size): gamescope places
## whatever pixel size the game's window asks for on the real panel, scaling
## it, and reports the pointer back in PANEL pixels, which the engine's own
## content-scale transform then reads as if they were already in the window's
## space. Zero error at the origin, growing with distance - the rows low on the
## screen go out of reach. The fix is the same as Greenhorn's: ask for the
## window at the screen's own size, unconditionally, and let the stretch
## (canvas_items, expand) do all the scaling as on any other screen. The first
## cut here gated it on "the window is bigger than the screen", which gamescope
## never reports, so it did nothing on the Deck.
##
## Linux only, as Greenhorn's is: on an exported Windows build under the GL
## Compatibility renderer, any window-geometry change from script segfaults
## (Greenhorn's isolated it over ten export cycles), and Windows never had the
## bug - a plain window manager shows the requested window at its size.
## Desktop mode on the Deck (a window manager, the window fitted by it) was
## fine both times; game mode (gamescope alone) was not.
func _fit_window_to_screen() -> void:
	if DisplayServer.get_name() == "headless" or OS.get_name() != "Linux":
		return
	var win := get_window()
	if win == null or win.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]:
		return
	var screen: Vector2i = DisplayServer.screen_get_size(win.current_screen)
	if screen.x <= 0 or screen.y <= 0:
		return
	# the project opens the window maximized on Windows only (window/size/mode.windows=2, 8 Oct): on
	# the Deck a maximized 1920 x 1080 window had gamescope set its own screen to 1920 x 1080 (the
	# foot read "1920×1080 → 1920×1080" in game mode), so there was no smaller screen to size to;
	# windowed, as Greenhorn's is, the screen stays the panel's 1280 x 800. Windowed here too, in case.
	win.mode = Window.MODE_WINDOWED
	win.size = screen                      # through the Window, so the canvas follows at once
	win.position = DisplayServer.screen_get_position(win.current_screen)


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
	_yard_tree.position = _grid.position
	_radio.position = _grid.position
	_armoury.position = _grid.position
	_barracks.position = _grid.position
	_missions.position = _grid.position
	_workshop.position = _grid.position
	_run.position = _grid.position
	_fence.position = _grid.position
	_clinic.position = _grid.position
	_stats.position = _grid.position
	# the log sits under the grid, bottom right; the rail runs the full height beside it
	_events.position = Vector2(x0 + Pal.RAIL_W + Pal.MARGIN, s.y - Pal.MARGIN - Pal.EVENTS_H)
	_menu.layout(s)


# ------------------------------------------------------------------ the clock

func _process(delta: float) -> void:
	if sim == null or _menu.visible:
		return
	sim.advance(delta * speed)
	sim.tick_played(delta)              # the player's own time at the game, for the playtest record (11 Oct)
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
## climbs with walking fire, drops under a resist and falls away while the runner searches; in the Yard it
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
			"action": load_game.bind(save_file), "enabled": saved, "glyph": "menu_continue"})
	items.append({"name": "New camp", "detail": "One runner, a nail gun, £150",
			"action": new_game.bind(false), "confirm": "This replaces the camp in progress - press again" if saved else "", "glyph": "menu_new"})
	items.append({"name": "New camp, hardcore", "detail": "A death ends the Yard: stash, cash, everything",
			"action": new_game.bind(true), "confirm": "This replaces the camp in progress - press again" if saved else "", "glyph": "menu_skull"})
	items.append({"name": "Load a slot", "detail": _slots_words(), "action": show_slots.bind(false, show_title), "glyph": "menu_slots"})
	items.append({"name": "Quit", "detail": "", "action": _quit, "glyph": "menu_quit"})
	_menu.open("Fiat", "Let it be done", items, Callable(), true, Rect2(), true)


## "Level 22, £14,437, 2 h 10 m played · 1 Oct, 11:04" for a save file, or "".
func _save_words(path: String) -> String:
	var d := _read_save(path)
	if d.is_empty():
		return ""
	var sd: Dictionary = d["sim"]
	var played: float = float(sd.get("elapsed", 0.0))
	return "Level %d · %s · %s · %s%s" % [Data.level_for_xp(float(sd.get("xp", 0.0))), Fmt.money(float(sd.get("cash", 0.0))),
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


## The pause as a drawer over the rail (Pause B, 8 Oct): the rooms' column becomes the menu's.
func show_pause() -> void:
	_menu.open("Paused", "Hardcore camp" if sim.hardcore else "", [
		{"name": "Resume", "detail": "", "action": _menu.close, "glyph": "menu_continue"},
		{"name": "Sound: on" if _sound.enabled else "Sound: off", "detail": "The Yard's ambient, the gun, the gangs, the door", "action": _toggle_sound, "glyph": "menu_sound"},
		{"name": "Save", "detail": "The autosave; it saves on its own every thirty seconds", "action": _save_and_resume, "glyph": "menu_save"},
		{"name": "Save to a slot", "detail": _slots_words(), "action": show_slots.bind(true, show_pause), "glyph": "menu_slots"},
		{"name": "Quit to title", "detail": "Saves first", "action": _quit_to_title, "glyph": "menu_title"},
	], _menu.close, false, Rect2(_rail.position, _rail_panel.size))


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
	_archive_record()                    # the last game's record kept beside, this one's starts empty
	sim = Sim.new()
	sim.odds_budget = ODDS_BUDGET       # the Runs screen reads its odds over a few frames, not in one
	sim.hardcore = hardcore
	sim.start()
	sim.chron("start", {"hardcore": hardcore, "version": SAVE_VERSION})
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
	_flush_record()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"version": SAVE_VERSION, "saved": Time.get_unix_time_from_system(), "sim": sim.to_dict()}))
	f.close()
	if path != save_file and FileAccess.file_exists(record_file()):
		if DirAccess.copy_absolute(record_file(), record_file(path)) != OK:     # a slot takes the record so far with it
			push_warning("the playtest record did not copy to %s" % record_file(path))
	if path == save_file:
		_since_save = 0.0


func load_game(path := "") -> void:
	if path == "":
		path = save_file
	var d := _read_save(path)
	if d.is_empty():
		return
	if path != save_file:
		# a slot: it carries on as the autosave, so its record becomes the autosave's (the one there kept beside)
		if _archive_record() and FileAccess.file_exists(record_file(path)):
			if DirAccess.copy_absolute(record_file(path), record_file()) != OK:
				push_warning("the slot's playtest record did not come in")
	sim = Sim.new()
	sim.odds_budget = ODDS_BUDGET       # the Runs screen reads its odds over a few frames, not in one
	sim.load_dict(d["sim"])
	room = OVERVIEW
	speed = 1.0
	_speed_label.visible = false
	_menu.close()
	var away := Time.get_unix_time_from_system() - float(d.get("saved", 0.0))
	# a session in the playtest record, ahead of the runs the settle adds: how long away, how much of it the sim
	# settles (11 Oct; the away runs carry their own flag)
	sim.chron("session", {"away_s": int(away), "settled_s": int(minf(away, sim.away_cap_s())) if away >= 60.0 else 0})
	if away >= 60.0:
		_settle_away(away)
	refresh()


## Offline: the time away runs through the sim - rest, or auto-run missions
## if one was on - up to the cap, and a screen says what happened.
func _settle_away(away: float) -> void:
	var seconds := minf(away, sim.away_cap_s())
	var before: Dictionary = sim.snapshot()
	var left := seconds
	sim.away_on = true                     # the Generator's Overtime and rank pay on the time away (9 Oct)
	while left > 0.0:
		var step := minf(600.0, left)
		sim.advance(step)
		left -= step
		if sim.camp_lost:
			break
	sim.away_on = false
	var after: Dictionary = sim.snapshot()
	# the log's deploys all carry the replay's real time, so the summary counts
	# by cash and items - what the player cares about
	var words := ""
	var runs: int = int(after.get("runs", 0)) - int(before.get("runs", 0))
	if sim.auto_tier >= 0 or runs > 0 or after["cash"] != before["cash"] or after["lost"] != before["lost"]:
		var where: String = Words.mid(sim.tier(sim.auto_tier)["name"]) if sim.auto_tier >= 0 else "the Estate"
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
	var words := "The Yard is gone with the runner."
	if r != null and r.has("lost_value"):
		words = "Dead in %s with %s of kit on. The Yard is gone with the runner." % [Words.mid(sim.tier(r["tier"])["name"]), Fmt.money(r["lost_value"])]
	_flush_record()                       # the death goes into the record, which outlives the save
	DirAccess.remove_absolute(save_file)
	_menu.open("The Yard is lost", words, [{"name": "Back to the title", "detail": "", "action": _to_title_no_save}], _to_title_no_save, true)


## The playtest record (11 Oct): the sim's lines go into a file beside the save, appended on each save, so the save
## never carries the hours of them (an autosave every 30 s copying megabytes would hitch). user://fiat.save's is
## user://fiat.record.jsonl, a line a JSON object; tools/playtest_summary.gd reads them together.
func record_file(path := "") -> String:
	return (save_file if path == "" else path).get_basename() + ".record.jsonl"


func _flush_record() -> void:
	if sim == null or sim.chronicle.is_empty():
		return
	var path := record_file()
	var f := FileAccess.open(path, FileAccess.READ_WRITE) if FileAccess.file_exists(path) else FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return                            # kept waiting: the next save tries again
	f.seek_end()
	for e in sim.chronicle:
		f.store_line(JSON.stringify(e))
	f.close()
	sim.chronicle.clear()


## The autosave's record moved aside (fiat.record.<unix ms>.jsonl) before a new game or a slot takes its place.
## False when it couldn't (the file held open elsewhere, the read running): then nothing is copied over it. A rename
## that fails is tried as a copy and a delete; a game whose record couldn't move carries on in the old file rather
## than lose it (the read's count line says so).
func _archive_record() -> bool:
	var path := record_file()
	if not FileAccess.file_exists(path):
		return true
	var to := "%s.%d.jsonl" % [path.get_basename(), int(Time.get_unix_time_from_system() * 1000.0)]
	if DirAccess.rename_absolute(path, to) == OK:
		return true
	if DirAccess.copy_absolute(path, to) == OK and DirAccess.remove_absolute(path) == OK:
		return true
	push_warning("the playtest record could not be moved aside: %s" % path)
	return false


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
	_top_labels["scrap"].text = Fmt.num(sim.scrap)
	for k in TOP_SALVAGE:
		_top_labels[k].text = Fmt.num(int(sim.salvage.get(k, 0)))
	_top_labels["level"].text = ("%d +%d" % [sim.level(), sim.paragon()]) if sim.paragon() > 0 else ("%d" % sim.level())
	_top_labels["hp"].text = ("%d / %d +%d" % [sim.hp_shown(), sim.max_hp_shown(), int(round(sim.guard()))]) if sim.guard() >= 0.5 else "%d / %d" % [sim.hp_shown(), sim.max_hp_shown()]     # Guard (12 Oct)
	_top_labels["dps"].text = "%.0f dmg/s" % sim.dps()
	_top_labels["xp"].text = _xp_words()
	_top_lines["hp"][1].size.x = _top_lines["hp"][0].size.x * clampf(sim.hp / maxf(sim.max_hp(), 1.0), 0.0, 1.0)
	_top_lines["xp"][1].size.x = _top_lines["xp"][0].size.x * _xp_share()
	if _dps_shown < 0.0:
		_top_lines["dps"][1].size.x = _top_lines["dps"][0].size.x * _dps_share()     # the first paint; _move_dps_line has it from there
	_top_labels["where"].text = ("Out: " + sim.tier(sim.mission["tier"])["name"]) if sim.on_mission() else "In the Yard"
	_top_class.text = sim.cls
	_top_class.position.x = _top_labels["level"].position.x + ceilf(UI.text_width(_top_labels["level"], _top_labels["level"].text)) + 10
	_lay_top_right()
	if room == OVERVIEW:
		sim.yard_mark_seen()                  # before the rail is painted: the badge never shows on the Yard while it's open
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
	_stats.visible = room == RUNNER
	_grid.visible = not (room == ARMOURY or room == BARRACKS or room == WORKSHOP or room == MISSIONS or room == MARKET or room == MEDIC or room == OVERVIEW or room == COMMS or room == RUNNER)
	_radio.visible = room == COMMS
	if room == COMMS:
		_radio.show_state(sim)
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
	elif room == RUNNER:
		_stats.show_state(sim)
	var cards: Array = []                     # the card grid's last room went to its own sheet (10 Oct, Stats-R A)
	# each card set once to where it ends up: hiding them all and showing the used ones again, ten
	# times a second, dropped a button's hover and any press in progress - the Radio's buttons flickered
	# and took a click only now and then (9 Oct)
	for i in range(_cards.size()):
		var on: bool = i < cards.size()
		_cards[i].visible = on
		if on:
			_cards[i].show_data(cards[i])
	# the Yard: the works as a tree (8 Oct), with the town and the purse in its heading
	_yard_tree.visible = room == OVERVIEW
	if room == OVERVIEW:
		_yard_tree.show_state(sim, _town_purse())
	var ev: Array = sim.events
	for i in range(Pal.EVENT_LINES):
		var j := ev.size() - 1 - i
		_event_times[i].text = _time_of_day(ev[j][0]) if j >= 0 else ""
		var lx: float = 20 + ceilf(UI.text_width(_event_times[i], _event_times[i].text)) + 16
		_event_labels[i].position.x = lx
		_event_labels[i].size.x = PREV_X - 20 - lx
		UI.fit(_event_labels[i], _by_sentence(str(ev[j][1])) if j >= 0 else [""])
	# the line before starts where the latest ends (PREV_X at the latest's widest), and goes when it can't fit whole
	var jp := ev.size() - 2
	var cur: Label = _event_labels[0]
	var tx: float = cur.position.x + ceilf(UI.text_width(cur, cur.text)) + PREV_GAP
	_prev_time.text = _time_of_day(ev[jp][0]) if jp >= 0 else ""
	_prev_time.position.x = tx
	var px: float = tx + ceilf(UI.text_width(_prev_time, _prev_time.text)) + 16
	_prev_label.position.x = px
	_prev_label.size.x = Pal.GRID_W - 20 - px - (_speed_label.size.x + 20 if _speed_label.visible else 0.0)
	var forms: Array = _by_sentence(str(ev[jp][1])) if jp >= 0 else [""]
	UI.fit(_prev_label, forms)
	if UI.text_width(_prev_label, _prev_label.text) > _prev_label.size.x:
		# no form fits whole (the Legion's smoke caught one that slipped the fit by ten pixels): it goes rather than trails off
		_prev_label.text = ""
		_prev_time.text = ""


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
	var lv: int = sim.level() + Data.paragon_for_xp(sim.xp)   # this runner's own: the banked paragon is another yard's XP (10 Oct)
	var this_xp := Data.xp_for_level(lv)
	var next_xp := Data.xp_for_level(lv + 1)
	return "%s / %s" % [_short(sim.xp - this_xp), _short(next_xp - this_xp)]


## The right group from the right edge (10 Oct, Bar-C): a salvage kind only once there's any (the campaign reads notes
## and scrap); each slot its glyph and its figure as it reads now, so the purse never reaches the HP, XP and damage.
## Where it would, it tightens: the place without "Out:", the salvage closer together, the place's words to its glyph
## alone (its tooltip keeps them), then every gap closer.
func _lay_top_right() -> void:
	var left_end := 0.0
	for k in ["hp", "xp", "dps"]:
		var lk: Label = _top_labels[k]
		left_end = maxf(left_end, maxf(_top_lines[k][0].position.x + _top_lines[k][0].size.x, lk.position.x + UI.text_width(lk, lk.text)))
	var place: String = _top_labels["where"].text
	_top_glyphs["where"].tooltip_text = place
	for step in range(5):
		_top_labels["where"].text = place.trim_prefix("Out: ") if step >= 1 else place
		_top_labels["where"].visible = step < 3
		var x: float = 1920.0 - 2 * Pal.MARGIN
		var first_x: float = x
		for k in TOP_RIGHT:
			var shown: bool = not (k in TOP_SALVAGE) or int(sim.salvage.get(k, 0)) > 0
			_top_glyphs[k].visible = shown
			if k != "where":
				_top_labels[k].visible = shown
			if not shown:
				continue
			var l: Label = _top_labels[k]
			var text_w: float = ceilf(UI.text_width(l, l.text)) if l.visible else -TOP_GLYPH_GAP
			if l.visible:
				l.size.x = text_w + 2.0                       # the box its figure, so its tooltip covers nothing beside it
				l.position.x = x - l.size.x
			x -= text_w + TOP_GLYPH_GAP + TOP_GLYPH
			_top_glyphs[k].position.x = x
			first_x = x
			var gap: float = 10.0 if (step >= 2 and k in TOP_SALVAGE) else (14.0 if step >= 4 else float(TOP_GAP))
			x -= gap
		if first_x >= left_end + TOP_GAP:
			return


## A figure for the top bar: 12,345 · 123k · 1.2M, so the XP slot stays narrow past the cap.
static func _short(x: float) -> String:
	if x >= 1e6:
		return "%.1fM" % (x / 1e6)
	if x >= 1e5:
		return "%.0fk" % (x / 1e3)
	return Fmt.num(x)


## The damage line's fill, 0 to 1: a minute's fire against the best open site's first gang at its depth
## - full when the gang falls inside the minute. It grows with the kit and drops back as a harder site opens.
func _dps_share() -> float:
	var i: int = clampi(sim.best_tier, 0, Data.TIERS.size() - 1)
	var t: Dictionary = sim.effective(i)
	var gang: float = float(t.get("pool", 1)) * float(t.get("hp", 1.0))
	return clampf(sim.dps() * 60.0 / maxf(gang, 1.0), 0.0, 1.0)


## The level's progress, 0 to 1, for the line under the XP figure.
func _xp_share() -> float:
	var lv: int = sim.level() + Data.paragon_for_xp(sim.xp)
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
	# the rail says only when a room wants a decision (8 Oct: the status lines went - a room's state is in the room)
	match name:
		OVERVIEW:
			# the Yard's jobs were easy to miss: the rail says when one is affordable, as the Fence's does for a contract
			return {"badge": "Upgrade" if sim.yard_news() else "", "badge_tone": "good"}     # news only (9 Oct): looking at the Yard clears it
		MISSIONS:
			return {"badge": "Live" if sim.on_mission() else "", "badge_tone": "good"}
		BARRACKS:
			var free: int = sim.points_free()
			return {"badge": ("%d free" % free) if free > 0 else "", "badge_tone": "good"}
		MEDIC:
			var full: bool = sim.hp >= sim.max_hp() - 0.5
			return {"badge": "" if full or sim.on_mission() else "Hurt", "badge_tone": "warn"}
		MARKET:
			# the contracts were easy to miss as a tab: the rail says when one's ready (they pay currency only, 9 Oct)
			var ready := 0
			for k in range(sim.contracts.size()):
				if sim.can_hand_in(k):
					ready += 1
			return {"badge": "Ready" if ready > 0 else "", "badge_tone": "good"}
	return {}


## The town and the purse on one card (7 Oct): the zones with their depths, the trade, what opens the next
## zone; cash, notes and scrap, kit worth, prices. The clock and the autosave in the foot; Move the Yard when it can.
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
		# the Yard's best dig, the score across yards (the endgame, 7 Oct)
		var site: String = str(sim.best_dig["site"]).trim_prefix("The ")
		zlines.append(["Best dig", ["%s, depth %d · yard %d" % [site, int(sim.best_dig["depth"]), int(sim.best_dig["yard"])], "%s, depth %d" % [site, int(sim.best_dig["depth"])], "%s D%d" % [site, int(sim.best_dig["depth"])], "depth %d" % int(sim.best_dig["depth"])], "accent"])
	var town_note: Variant = [Words.NOTES["zones"] if not sim.campaign_done() else Words.NOTES["zones_done"], Words.NOTES["patch"]]
	if sim.lorry_done:
		town_note = ["The lorry's beaten: move the Yard when you're ready", "The lorry's beaten"]
	var d := {
		"title": "The town and the purse" if sim.yard_moves == 0 else "The town and the purse · yard %d" % (sim.yard_moves + 1),
		"headline": Fmt.money(sim.cash), "unit": "in hand",
		"left": {"kicker": "The town · %d of %d zones open" % [open_zones, Data.ZONES.size()], "lines": zlines,
			"note": town_note, "note_tone": "good" if sim.lorry_done else ""},
		"right": {"kicker": "The purse", "lines": [["Cash", Fmt.money(sim.cash), "accent"], ["Notes · scrap", "%d · %d" % [sim.notes, sim.scrap]], ["Kit worth", Fmt.money(sim.loadout_value())],
			["Stash", "%d of %d cells" % [sim.stash_used(), sim.stash_cap()]], ["Prices", ("up %d%%" % sim.inflation_pct()) if sim.inflation_pct() > 0 else "as they were"]],
			"note": "Cash goes off; notes don't" if sim.inflation_pct() > 0 else "What the Fence pays"},
		"status": ["Autosaves every 30 s · %s played" % Fmt.clock(sim.elapsed), "%s played" % Fmt.clock(sim.elapsed)],
	}
	if sim.can_move_yard():
		d["button"] = {"text": "Move the Yard", "action": _confirm_move, "enabled": true, "primary": sim.lorry_done}
	return d


# ------------------------------------------------------------------ the run
# (the live run is scripts/ui/run.gd: the three panels and the pack grid)

# ------------------------------------------------------------------ armoury

# ------------------------------------------------------------------ the Clinic
# (a screen of its own: scripts/ui/clinic.gd - treatment, the shelf, the stash's meds and the rig)


# ------------------------------------------------------------------ the Fence
# (a screen of its own: scripts/ui/fence.gd - the shelf and the stash grid)


# ------------------------------------------------------------------ comms tower

## The Radio's crafts that want a word (9 Oct): Call in a word from the book, Hold one of the site's - four a page and More.
func _choose_word(i: int, key: String, page := 0) -> void:
	var options: Array = sim.call_options(i) if key == "call" else sim.word_names(i)
	var items := []
	var per := 4
	for k in range(page * per, mini(options.size(), (page + 1) * per)):
		var name: String = options[k]
		var ww: Array = sim.word_words(name, maxi(1, sim.word_tier_cap(int(sim.depth[i]))))
		items.append({"name": name, "detail": "%s · %s" % [ww[0], ww[1]], "action": _do_word.bind(i, key, name)})
	if (page + 1) * per < options.size():
		items.append({"name": "More", "detail": "", "action": _choose_word.bind(i, key, page + 1)})
	else:
		items.append({"name": "Back", "detail": "", "action": _menu.close})
	var title: String = ("Call in a word on %s" if key == "call" else "Hold a word on %s") % sim.tier(i)["name"].to_lower()
	_menu.open(title, "%s, and the words stay until you change them" % Fmt.count(sim.word_craft_cost(i, key), "note"), items, _menu.close)


func _do_word(i: int, key: String, name: String) -> void:
	sim.word_craft(i, key, name)
	_menu.close()
	refresh()


## The book's choices: a standing word (the map's Relay, the whole band) or the word never heard (Clear air).
func _choose_book(kind: String, page := 0) -> void:
	var options: Array = sim.words_known()
	options.insert(0, "")
	var items := []
	var per := 4
	for k in range(page * per, mini(options.size(), (page + 1) * per)):
		var name: String = options[k]
		items.append({"name": name if name != "" else "None", "detail": "" if name == "" else "%s · %s" % sim.word_words(name, 1), "action": _set_book.bind(kind, name)})
	if (page + 1) * per < options.size():
		items.append({"name": "More", "detail": "", "action": _choose_book.bind(kind, page + 1)})
	else:
		items.append({"name": "Back", "detail": "", "action": _menu.close})
	var title: String = "The word never heard" if kind == "filter" else "A standing word on every site"
	_menu.open(title, "From the book: change it any time", items, _menu.close)


func _set_book(kind: String, name: String) -> void:
	if kind == "filter":
		sim.set_filtered(name)
	else:
		sim.set_standing(int(kind.trim_prefix("standing")), name)
	_menu.close()
	refresh()


## After a death, two turn up: pick who stays.
func _choose_runner() -> void:
	var items := []
	for k in range(sim.candidates.size()):
		var tr: Dictionary = {}
		for t in Data.TRAITS:
			if t["name"] == sim.candidates[k]:
				tr = t
		items.append({"name": tr.get("name", sim.candidates[k]), "detail": tr.get("words", ""), "action": _pick_runner.bind(k)})
	_menu.open("Two turn up at the Yard", "One stays. The other moves on.", items, Callable())


func _pick_runner(k: int) -> void:
	sim.choose_runner(k)
	_asked_runner = false
	_menu.close()
	refresh()


## Moving the Yard: asked twice, since everything but the uniques goes.
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
		{"name": "Move the Yard", "detail": "Start again. The uniques, the Yard's tree, the list, the wall, half the notes and the Yard's trade come. Nothing else.", "action": _pick_trade},
		{"name": "Stay", "detail": "", "action": _menu.close},
	]
	var floor_next: int = mini(sim.yard_moves + 1, Data.LADDER_FLOOR_MAX)
	_menu.open("Move the Yard?", "A yard that's moved finds rarer things and more cash (+%d%% each a move), %d points to start, its ladders from depth %d once a site is cleared, and %d free node%s on the Yard's tree." % [Data.MOVE_FIND, Data.MOVE_POINTS * (sim.yard_moves + 1), floor_next + 1, sim.yard_moves + 1, "" if sim.yard_moves == 0 else "s"], items, _menu.close)


## The Yard's trade: one element comes with the move, and every class after
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
	_menu.open("The Yard's trade", "Which trade comes with the Yard?", items, _menu.close)


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
	_menu.open("Build for scrap", "%d scrap in hand" % sim.scrap, items.slice(0, 5), _menu.close)


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


## The Runner room's Workshop button on a piece (9 Oct): the Workshop's Craft view with it picked, worn or
## not - the old menu went (Matt: "it opens the old menu - need to just remove the old one").
func _open_workshop(id: int) -> void:
	if sim.item_by_id(id).is_empty():
		return
	show_room(WORKSHOP)
	_workshop.open_piece(id)
	refresh()


func _craft(id: int, kind: String, stat: String) -> void:
	var done: bool = sim.scrap_item(id) if kind == "scrap" else sim.craft(id, kind, stat)     # the Bench's scrap tile comes through here too (8 Oct)
	if done and _juice != null:
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
