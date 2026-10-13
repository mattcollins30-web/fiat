extends Control
## The Bench's screen (its treatment, 8 Oct; the rooms' one band, 10 Oct): the
## band across the top in the Yard's shape - the room and its upgrades built,
## the purse as chips down the left, the three views at the foot, right, the
## Bench's line beside them - then the left column under it and the stash's
## grid with the pick panel on the right, as the Lock-up has them. The Bench's
## upgrades are built in the Yard.
## Three views of the left column: Guns (each gun a card, its mounts as
## tiles), Sockets (the sockets of the guns, the helmet and the armour, and
## the socketables that go in them) and Craft (the picked piece as a card with
## its affixes as rows, then THE JOBS as priced tiles - the Bench's work done
## in the room, nothing more than a press away). The grid follows the view.

signal acted
signal craft(id, kind, stat)       # a Bench job from the Craft view; main runs it (the toast, the refresh)
signal build                       # the Build column's menu (34): rounds, meds, a gun, a grenade for scrap

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const Inventory := preload("res://scripts/ui/inventory.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const PickPanel := preload("res://scripts/ui/pick_panel.gd")

const BODY_W := Inventory.SIDE_W                              # 608
const GAP := 24
const PAD := 20
const HEAD_H := Pal.BAND_H         # the rooms' one band across the top (10 Oct, Bands-U A): 118 → 180
const TOP := HEAD_H + 14           # the columns under it
const VIEW_W := 140                # a view's tab
const VIEW_H := 40
const VIEWS_X := Pal.GRID_W - PAD - 3 * VIEW_W - 12     # the views at the band's foot, right (Bands-U A)
const CARD_PAD := 14
const HEAD_LINE_H := 26            # a gun card's first line: the slot and the figure
const NAME_H := 34                 # the gun's name under it
const CHIPS_H := Chips.CHIP_H + 8  # the chip row under the name
const TILE_COLS := 3               # a gun's mounts as tiles, three across
const TILES := 6                   # five mounts and a spare, two rows
const ROW_GAP := 8
const GUN_CARD_H := CARD_PAD + HEAD_LINE_H + NAME_H + CHIPS_H + 2 * UI.TILE_H + ROW_GAP + CARD_PAD      # 250
const SOCK_HEAD_H := 44
const GRID_ROWS := 4               # the grid under the band: four rows a page (five before the band grew; it pages)
const GRID_X := BODY_W + GAP
const GRID_W := Inventory.WIDTH
const GRID_H := Inventory.GRID_Y + GRID_ROWS * Pal.CELL + (GRID_ROWS - 1) * Pal.CELL_GAP      # 448
const PANEL_Y := TOP + GRID_H + GAP
const PANEL_H := Pal.ROOM_H - PANEL_Y
const PIECE_H := 262               # the Craft view's piece card
const AFFIX_H := 36                # an affix row
const AFFIX_BTN_H := 40            # the picked affix's two jobs, a row under the affixes
const JOB_COLS := 2
const JOB_H := 104                 # a job tile
const JOB_GAP := 8
const JOB_W := (BODY_W - 2 * PAD - JOB_GAP) / JOB_COLS        # 280
const JOBS := ["reroll", "add", "socket", "strip", "bump", "scrap"]
const JOB_NAMES := {"bump": "Raise the level", "scrap": "Scrap it"}
const JOB_WORDS := {"bump": "Three levels up: the worst tiers stop rolling", "scrap": "Broken down for the builds; gone for good"}
const FOOT_H := 44
const GUNS := ["Primary", "Secondary"]
const ROWS_A_GUN := 5              # the most mounts a gun has

var head_band := {}                # the heading's painted place (10 Oct, Rooms-B)
var sim
var view := "guns"                 # "guns", "sockets" or "craft"
var _views: Array[Button] = []
var _kicker: Label                 # the heading: "The Bench", "Level 2", "fits optics, muzzles and magazines"
var _headline: Label
var _unit: Label
var _chips: Chips                  # the purse
var _next: Label                   # what the next level adds
# the Craft view
var _piece: Panel
var _piece_title: Label
var _piece_figure: Label
var _piece_chips: Chips
var _piece_words: Array[Label] = []           # nothing picked: what the Bench takes, three lines
var _affix_rows: Array = []                   # three: {button, dot, label, tag}
var _affix_buttons: Array[Button] = []        # the picked affix's two jobs: re-roll it, keep it and re-roll the others
var _affix_actions: Array = []
var _jobs: Panel
var _jobs_head: Label
var _job_tiles: Array = []                    # six: {button, name, words: [2], price}
var _job_actions: Array = []
var _foot: Label                              # the last job's words, or the state
var _build: Button
var sel_stat := ""                            # the picked affix's stat, in the Craft view
# the Guns and Sockets views
var _socks := {}                   # slot -> {head, label, name, rows: {mount -> {button, mount, fitted}}}
var sel_slot := ""                 # the gun slot whose mount is selected
var sel_mount := ""
var sel_id := -1                   # a stash item selected, or -1
var _guns := {}                    # slot -> {card, label, figure, name, chips, rows: [{button, key, mount, fitted}]}
var _inv
var _pick                          # the pick panel (pick_panel.gd): a part against the one in the mount; the piece in the Craft view
var _pick_actions: Array = []
var _shown := ""


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	# the heading: the room, its level and what it fits; the views; the purse; the Bench's line (its upgrades are the Yard's)
	var head := UI.panel(self, Rect2(0, 0, Pal.GRID_W, HEAD_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	head_band = UI.head_art(head, "The workshop")    # art/places/the_workshop.png (Rooms-B)
	# the band as the Yard's (Bands-U A): the words and the purse down the shaded left, the views at the foot, right
	_kicker = UI.label(head, Rect2(PAD, 8, Pal.BAND_TEXT_W, 24), "The Workshop", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_headline = UI.label(head, Rect2(PAD, 32, Pal.BAND_TEXT_W, 44), "", "SemiBold", Pal.HEADLINE - 4, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_unit = UI.label(head, Rect2(PAD, 38, Pal.BAND_TEXT_W, 36), "", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(3):
		var v := UI.button(head, Rect2(VIEWS_X + i * (VIEW_W + 6), HEAD_H - 16 - VIEW_H, VIEW_W, VIEW_H), false)      # plain: _style skins the one that's on (a primary start left Guns' text dark, 8 Oct)
		v.text = ["Guns", "Sockets", "Craft"][i]
		v.pressed.connect(_set_view.bind(["guns", "sockets", "craft"][i]))
		_views.append(v)
	_chips = Chips.new(Pal.BAND_TEXT_W, 3)
	_chips.position = Vector2(PAD, Pal.BAND_CHIPS_Y)
	head.add_child(_chips)
	_next = UI.label(head, Rect2(PAD + Pal.BAND_TEXT_W + 24, HEAD_H - 16 - VIEW_H, VIEWS_X - 16 - (PAD + Pal.BAND_TEXT_W + 24), VIEW_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)     # left of the views
	# the Craft view: the piece as a card, its affixes as rows, the picked one's jobs under them
	_piece = UI.panel(self, Rect2(0, TOP, BODY_W, PIECE_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_piece.visible = false
	_piece_title = UI.label(_piece, Rect2(PAD, 12, BODY_W - 2 * PAD, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_piece_figure = UI.label(_piece, Rect2(PAD, 18, BODY_W - 2 * PAD, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT)
	_piece_chips = Chips.new(BODY_W - 2 * PAD, 4)
	_piece_chips.position = Vector2(PAD, 54)
	_piece.add_child(_piece_chips)
	for i in range(3):
		_piece_words.append(UI.label(_piece, Rect2(PAD, 56 + i * 28, BODY_W - 2 * PAD, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
	var ay := 54 + Chips.CHIP_H + 10
	for k in range(3):
		var b := Button.new()
		b.position = Vector2(PAD - 10, ay + k * AFFIX_H)
		b.size = Vector2(BODY_W - 2 * PAD + 20, AFFIX_H)
		b.text = ""
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick_affix.bind(k))
		_piece.add_child(b)
		var r := {"button": b, "stat": ""}
		r["dot"] = UI.panel(b, Rect2(10, AFFIX_H / 2 - 4, 8, 8), UI.box(Pal.TEXT_2, 4))
		r["label"] = UI.label(b, Rect2(26, 0, BODY_W - 2 * PAD - 80, AFFIX_H), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["tag"] = UI.label(b, Rect2(BODY_W - 2 * PAD - 40, 0, 50, AFFIX_H), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT)
		_affix_rows.append(r)
	for i in range(2):
		var b := UI.button(_piece, Rect2(PAD, PIECE_H - 12 - AFFIX_BTN_H, 100, AFFIX_BTN_H), false)
		b.pressed.connect(_press_affix_job.bind(i))
		b.visible = false
		_affix_buttons.append(b)
		_affix_actions.append(Callable())
	# THE JOBS: six tiles with their prices, the last job's words and Build for scrap along the foot
	_jobs = UI.panel(self, Rect2(0, TOP + PIECE_H + 10, BODY_W, 0), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_jobs.visible = false
	_jobs_head = UI.label(_jobs, Rect2(PAD, 10, 200, 24), "THE JOBS", "Medium", 13, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	var jy := 40
	for k in range(JOBS.size()):
		var b := Button.new()
		b.position = Vector2(PAD + (k % JOB_COLS) * (JOB_W + JOB_GAP), jy + (k / JOB_COLS) * (JOB_H + JOB_GAP))
		b.size = Vector2(JOB_W, JOB_H)
		b.text = ""
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_press_job.bind(k))
		_jobs.add_child(b)
		var t := {"button": b}
		t["name"] = UI.label(b, Rect2(12, 8, JOB_W - 24, 26), "", "SemiBold", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		t["words"] = []
		for i in range(2):
			t["words"].append(UI.label(b, Rect2(12, 34 + i * 20, JOB_W - 24, 20), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		t["price"] = UI.label(b, Rect2(12, JOB_H - 30, JOB_W - 24, 26), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, true)
		_job_tiles.append(t)
		_job_actions.append(Callable())
	var fy := jy + 3 * (JOB_H + JOB_GAP) + 4
	_build = UI.button(_jobs, Rect2(BODY_W - PAD - 100, fy, 100, FOOT_H), false)
	_build.pressed.connect(func(): build.emit())
	_foot = UI.label(_jobs, Rect2(PAD, fy, BODY_W - 2 * PAD - 240, FOOT_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_jobs.size.y = fy + FOOT_H + 14
	# the Guns view: a card a gun - the slot and figure, the name and its chips, the mounts as tiles
	var y := TOP
	var tw := (BODY_W - 2 * PAD - ROW_GAP * (TILE_COLS - 1)) / TILE_COLS
	for slot in GUNS:
		var g := {}
		var card := UI.panel(self, Rect2(0, y, BODY_W, GUN_CARD_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
		g["card"] = card
		g["label"] = UI.label(card, Rect2(PAD, CARD_PAD, BODY_W - 2 * PAD, HEAD_LINE_H), slot, "Medium", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		g["figure"] = UI.label(card, Rect2(PAD, CARD_PAD, BODY_W - 2 * PAD, HEAD_LINE_H), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		g["name"] = UI.label(card, Rect2(PAD, CARD_PAD + HEAD_LINE_H, BODY_W - 2 * PAD, NAME_H), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		g["chips"] = Chips.new(BODY_W - 2 * PAD)
		g["chips"].position = Vector2(PAD, CARD_PAD + HEAD_LINE_H + NAME_H + 4)
		card.add_child(g["chips"])
		g["rows"] = []                       # six tiles; which mount each shows is the gun's (a bat has a grip and a head)
		var ty := CARD_PAD + HEAD_LINE_H + NAME_H + CHIPS_H
		for k in range(TILES):
			var b := Button.new()
			b.position = Vector2(PAD + (k % TILE_COLS) * (tw + ROW_GAP), ty + (k / TILE_COLS) * (UI.TILE_H + ROW_GAP))
			b.size = Vector2(tw, UI.TILE_H)
			b.text = ""
			b.focus_mode = Control.FOCUS_ALL
			b.pressed.connect(_pick_row.bind(slot, k))
			card.add_child(b)
			var r := {"button": b, "key": ""}
			r["mount"] = UI.label(b, Rect2(10, 4, tw - 20, 22), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			r["fitted"] = UI.label(b, Rect2(10, 26, tw - 20, 30), "", "SemiBold", UI.TILE_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			r["lock"] = UI.label(b, Rect2(tw - 36, 4, 26, 22), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT)
			g["rows"].append(r)
		y += GUN_CARD_H + 10
		_guns[slot] = g
	# the sockets view: the same shape, four groups, two rows each
	y = TOP
	var sw := (BODY_W - 2 * PAD - 2 * ROW_GAP) / 3     # three across (9 Oct): the Yard's Third socket cuts a third
	for slot in Data.SOCKET_SLOTS:
		var g := {}
		var card := UI.panel(self, Rect2(0, y, BODY_W, SOCK_HEAD_H + ROW_GAP + UI.TILE_H + CARD_PAD), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
		g["head"] = card
		g["label"] = UI.label(card, Rect2(PAD, 0, 150, SOCK_HEAD_H), slot, "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		g["name"] = UI.label(card, Rect2(PAD, 0, BODY_W - 2 * PAD, SOCK_HEAD_H), "", "SemiBold", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, false)
		g["rows"] = {}
		for k in range(Data.SOCKET_MAX + 1):
			var mount := "socket %d" % (k + 1)
			var b := Button.new()
			b.position = Vector2(PAD + k * (sw + ROW_GAP), SOCK_HEAD_H + ROW_GAP)
			b.size = Vector2(sw, UI.TILE_H)
			b.text = ""
			b.focus_mode = Control.FOCUS_ALL
			b.pressed.connect(_pick_mount.bind(slot, mount))
			card.add_child(b)
			var r := {"button": b}
			r["mount"] = UI.label(b, Rect2(10, 4, sw - 20, 22), Items.mount_name(mount), "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			r["fitted"] = UI.label(b, Rect2(10, 26, sw - 20, 30), "", "SemiBold", UI.TILE_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			g["rows"][mount] = r
		y += SOCK_HEAD_H + ROW_GAP + UI.TILE_H + CARD_PAD + 10
		_socks[slot] = g
	_show_view()
	# the grid: the stash's attachments, for the selected mount when one is; the gear in the Craft view
	_inv = Inventory.new()
	_inv.position = Vector2(GRID_X, TOP)
	_inv.set_rows(GRID_ROWS)
	_inv.fixed_kind = Data.ATTACHMENT
	_inv.picked.connect(_on_inv_pick)
	_inv.acted.connect(_on_inv_acted)
	add_child(_inv)
	_pick = PickPanel.new(GRID_W, PANEL_H)
	_pick.position = Vector2(GRID_X, PANEL_Y)
	_pick.acted.connect(func(): acted.emit())
	add_child(_pick)
	for i in range(PickPanel.BUTTONS):
		_pick_actions.append(Callable())


## A tile's look: picked (ringed), with a part (edged in its tone), empty, dim
## (locked, on the dark ground), or none (a mount the gun hasn't: a hollow slot).
func _style(b: Button, on: bool, tone := "", dim := false, none := false) -> void:
	var bg := Pal.SELECT if on else (Pal.BG if dim else Pal.PANEL)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var sb := UI.box(bg if state != "hover" or on or dim else Pal.CARD, 8)
		if none:
			sb = UI.box(Color.TRANSPARENT, 8, 1, Pal.RAIL_RULE)
		elif on:
			sb.set_border_width_all(2)
			sb.border_color = Pal.PICK
		elif tone != "":
			sb.border_width_left = 6
			sb.border_color = Pal.tone_color(tone)
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 8, 2, Pal.TEXT))


static func rarity_tone(it: Dictionary) -> String:
	return Pal.item_tone(it)


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	var source: Array = sim.attachments_for(sel_mount) if sel_mount != "" else _all_attachments(view == "sockets")
	var what: String = "Socketables" if view == "sockets" else "Attachments"
	if sel_mount != "":
		what = sel_mount.capitalize() if sel_mount.begins_with("socket") else "%s mount" % Items.mount_name(sel_mount)
	if view == "craft":
		source = _craftable()
		what = "Gear"
	_inv.fixed_kind = "" if view == "craft" else Data.ATTACHMENT
	_inv.show_items(sim, source, sim.stash_used(), sim.stash_cap(), what)
	var sig := _signature()
	if sig == _shown:
		return
	_shown = sig
	for slot in GUNS:
		var g: Dictionary = _guns[slot]
		var gun = sim.equipped[slot]
		if gun == null:
			g["name"].text = "Nothing fitted"
			g["name"].add_theme_color_override("font_color", Pal.TEXT_3)
			g["figure"].text = ""
		else:
			g["name"].text = gun["base"]
			g["name"].add_theme_color_override("font_color", Pal.TEXT)
			UI.fit(g["figure"], ["%.0f dmg/s · %s" % [Items.dps(gun), Items.ammo_words(gun).trim_prefix("Takes ")], "%.0f dmg/s" % Items.dps(gun)])
		# the chips: the type, the rarity in its tone, what's fitted
		g["chips"].visible = view == "guns" and gun != null
		if gun != null:
			var fw: Array = Items.fitted_words(gun)
			var fitted_chip: String = fw[2] if fw.size() > 2 else fw[0]          # "5 fitted", or "nothing fitted" / "no mounts"
			var type_word: String = str(Items.base_of(gun).get("type", "gun"))
			g["chips"].show_chips([[type_word.to_upper() if type_word == "smg" else type_word.capitalize(), Pal.TEXT_2], [Items.rarity_name(gun), Pal.tone_color(rarity_tone(gun)) if rarity_tone(gun) != "" else Pal.TEXT_2],
				[fitted_chip, Pal.GOOD if fw.size() > 2 else Pal.TEXT_2]])
		var mounts: Array = _mounts_of(gun)
		for k in range(TILES):
			var r: Dictionary = g["rows"][k]
			var mount: String = mounts[k] if k < mounts.size() else ""
			r["key"] = mount
			var has: bool = mount != ""
			var on: bool = sel_slot == slot and sel_mount == mount and mount != ""
			r["button"].visible = view == "guns" and (has or (gun != null and k < ceili(mounts.size() / float(TILE_COLS)) * TILE_COLS))     # hollow slots square the last row only
			r["mount"].text = Items.mount_name(mount) if mount != "" else ""
			r["lock"].text = ""
			if not has:
				# a mount the gun hasn't: a hollow slot, nothing in it
				r["fitted"].text = ""
				r["button"].disabled = true
				_style(r["button"], false, "", true, true)
				continue
			r["button"].disabled = false
			r["mount"].add_theme_color_override("font_color", Pal.TEXT_2)
			var a = gun["attachments"][mount]
			if a == null:
				r["fitted"].text = "Empty"
				r["fitted"].add_theme_color_override("font_color", Pal.TEXT_3)
				_style(r["button"], on)
			else:
				UI.fit(r["fitted"], _short_names(a["base"]))
				r["fitted"].add_theme_color_override("font_color", Pal.tier_color(int(a.get("tier", 1))))     # the part's tier, as the Lock-up bands it
				_style(r["button"], on, rarity_tone(a))
	for slot in Data.SOCKET_SLOTS:
		var g: Dictionary = _socks[slot]
		var gear = sim.equipped[slot]
		var n: int = 0 if gear == null else Items.sockets(gear)
		if gear == null:
			g["name"].text = "Nothing fitted"
			g["name"].add_theme_color_override("font_color", Pal.TEXT_3)
		else:
			if n > 0:
				g["name"].text = gear["base"]
			else:
				# shares the row with the slot's name on the left: 150 px for that
				g["name"].text = "No sockets"
				for o in ["%s: no sockets" % gear["base"], "%s: none" % gear["base"]]:
					if UI.text_width(g["name"], o) <= BODY_W - 2 * PAD - 160:
						g["name"].text = o
						break
			g["name"].add_theme_color_override("font_color", Pal.TEXT if n > 0 else Pal.TEXT_3)
		for mount in g["rows"]:
			var r: Dictionary = g["rows"][mount]
			var has: bool = gear != null and gear["attachments"].has(mount)
			var on: bool = sel_slot == slot and sel_mount == mount
			if not has:
				# a socket not cut yet: a hollow slot (as a mount the gun hasn't)
				r["fitted"].text = ""
				r["mount"].add_theme_color_override("font_color", Pal.TEXT_3)
				r["button"].disabled = true
				_style(r["button"], false, "", true, true)
				continue
			r["button"].disabled = false
			r["mount"].add_theme_color_override("font_color", Pal.TEXT_2)
			var a = gear["attachments"][mount]
			if a == null:
				r["fitted"].text = "Empty"
				r["fitted"].add_theme_color_override("font_color", Pal.TEXT_3)
				_style(r["button"], on)
			else:
				r["fitted"].text = a["base"]
				r["fitted"].add_theme_color_override("font_color", Pal.tier_color(int(a.get("tier", 1))))
				_style(r["button"], on, rarity_tone(a))
	# the heading (9 Oct): every job and mount open from the start; the Bench's picks, built in the Yard, named
	var picks: Array = []
	var bench := Data.yard_building("bench")
	for c in range(bench["picks"].size()):
		var sd: String = sim.yard_side("bench", c)
		if sd != "":
			picks.append(str(bench["picks"][c][0 if sd == "a" else 1]["name"]))
	_headline.text = "%d of 5" % picks.size()
	_unit.position.x = PAD + ceilf(UI.text_width(_headline, _headline.text)) + 10
	_unit.size.x = PAD + Pal.BAND_TEXT_W + 120 - _unit.position.x
	UI.fit(_unit, ["upgrades built · rank %d" % sim.yard_rank("bench") if sim.yard_rank("bench") > 0 else "upgrades built", "upgrades"])
	_chips.show_chips([{"forms": [Fmt.money(sim.cash) + " in hand", Fmt.money(sim.cash)], "colour": Pal.ACCENT}, {"forms": ["%d notes" % sim.notes], "colour": Pal.TEXT_2}, {"forms": ["%d scrap" % sim.scrap], "colour": Pal.TEXT_2}], 3)
	if picks.is_empty():
		UI.fit(_next, ["Every job and every mount, from the start; the Bench's upgrades are built in the Yard", "The Bench's upgrades are built in the Yard", "Upgrades: the Yard"])
	else:
		UI.fit(_next, ["Built: %s" % ", ".join(picks), ", ".join(picks), "Built: %s" % ", ".join(picks.slice(0, 2)), ", ".join(picks.slice(0, 2)), "%s and %d more" % [picks[0], picks.size() - 1] if picks.size() > 1 else str(picks[0]), str(picks[0]), "%d built" % picks.size()])
	_show_panel()


## A part's name as it fits a tile: whole, then its first word ("Drum" under
## "Magazine"), then its first word cut to six letters; never an ellipsis.
static func _short_names(base: String) -> Array:
	var words: PackedStringArray = base.split(" ", false)
	var out: Array = [base]
	if words.size() > 1 and words[0].length() >= 3:
		out.append(words[0])
	out.append(words[0].substr(0, 6) if not words.is_empty() else base)
	return out


## "optics, muzzles and grips".
static func _and(words: Array) -> String:
	if words.size() <= 1:
		return "" if words.is_empty() else str(words[0])
	return ", ".join(words.slice(0, words.size() - 1)) + " and " + str(words.back())


## The gun's own mounts, in the Bench's order, sockets apart.
func _mounts_of(gun) -> Array:
	var out: Array = []
	if gun == null:
		return out
	for mount in Data.MOUNTS:
		if gun["attachments"].has(mount):
			out.append(mount)
	return out


func _pick_row(slot: String, k: int) -> void:
	var key: String = _guns[slot]["rows"][k]["key"]
	if key != "":
		_pick_mount(slot, key)


## The stash's gun attachments, or its socketables.
func _all_attachments(socketables: bool) -> Array:
	var out: Array = []
	for it in sim.stash:
		if Items.is_attachment(it) and Items.is_socketable(it) == socketables:
			out.append(it)
	out.sort_custom(func(a, b): return Items.score(a) > Items.score(b))
	return out


func _signature() -> String:
	var parts := [view, sel_slot, sel_mount, str(sel_id), sel_stat, str(sim.on_mission()), str(sim.yard_picks.get("bench", [])) + str(sim.yard_rank("bench")), str(int(sim.cash) / 100), str(_inv.many),
		str(sim.notes), str(sim.scrap), str(sim.last_craft.get("id", -1)), str(sim.last_craft.get("words", ""))]
	# the craft view's piece changes under the Bench: its level, affixes and sockets are in the signature too
	var picked := _selected_item()
	if not picked.is_empty():
		parts.append(str(hash([picked.get("ilvl", 0), picked.get("affixes", []), picked.get("attachments", {}).keys()])))
	for slot in Data.SOCKET_SLOTS:
		var gun = sim.equipped[slot]
		if gun == null:
			parts.append("-")
			continue
		parts.append(str(gun["id"]))
		for mount in gun["attachments"]:
			var a = gun["attachments"][mount]
			parts.append("%s=%s" % [str(mount), "-" if a == null else str(a["id"])])
	for it in sim.stash:
		if Items.is_attachment(it):
			parts.append(str(it["id"]))
	return "|".join(parts)


func _selected_item() -> Dictionary:
	if sel_id < 0:
		return {}
	for it in sim.stash:
		if it["id"] == sel_id:
			return it
	for slot in Data.SLOTS:
		if sim.equipped[slot] != null and sim.equipped[slot]["id"] == sel_id:
			return sim.equipped[slot]            # a worn piece, sent from the Runner room (9 Oct)
	return {}


## Worn, not in the stash: picked from the Runner room's Workshop button.
func _worn(it: Dictionary) -> bool:
	return not it.is_empty() and not sim.stash.has(it)


## The Runner room's Workshop button (9 Oct): the Craft view with this piece picked.
func open_piece(id: int) -> void:
	if view != "craft":
		_set_view("craft")
	sel_slot = ""
	sel_mount = ""
	sel_stat = ""
	sel_id = id
	_shown = ""
	var it := _selected_item()
	if not it.is_empty() and Items.is_attachment(it):
		_set_view("sockets" if Items.is_socketable(it) else "guns")     # a part or a socketable is fitted, not crafted: its view, its mount picked
		sel_id = id
		if Items.is_socketable(it):
			sel_slot = _slot_for("socket")
			sel_mount = _socket_for(sel_slot)
		else:
			sel_mount = it["mount"]
			sel_slot = _slot_for(sel_mount)
		_shown = ""


func _fitted() -> Dictionary:
	if sel_slot == "" or sim.equipped[sel_slot] == null:
		return {}
	var a = sim.equipped[sel_slot]["attachments"].get(sel_mount, null)
	return a if a != null else {}


func _show_panel() -> void:
	var it := _selected_item()
	var fitted := _fitted()
	if view == "craft":
		_show_craft(it)
		return
	# the Guns and Sockets views: the pick panel, a part against the one in the mount (Pick-A)
	if sel_mount == "" and it.is_empty():
		_pick.show_empty("Select a socket" if view == "sockets" else "Select a mount",
			["A socket on the left, or a socketable on the right" if view == "sockets" else "A gun's mount on the left, or an attachment on the right"])
		_set_pick_buttons([])
		return
	var buttons := []
	if it.is_empty():
		# a mount picked: what's on it, or that it's empty
		if fitted.is_empty():
			_pick.show_empty("%s · %s: empty" % [sel_slot, Items.mount_name(sel_mount)],
				["Nothing in the stash fits" if sim.attachments_for(sel_mount).is_empty() else "Pick one on the right"])
			_set_pick_buttons([])
			return
		_pick.show_pick(fitted, sim, "Fitted · %s %s" % [sel_slot.to_lower(), Items.mount_name(fitted["mount"]).to_lower()])
		_pick.show_right_words("The stash", "Strip it back to the stash", ["Stash has %d of %d cells" % [sim.stash_used(), sim.stash_cap()]])
		buttons.append({"text": "Strip", "action": sim.strip.bind(sel_slot, sel_mount), "enabled": not sim.on_mission() and sim.stash_fits(fitted), "primary": true})
		_set_pick_buttons(buttons)
		return
	_pick.show_pick(it, sim, "The pick · in the stash")
	if Items.is_socketable(it):
		var target_slot := sel_slot if sel_slot != "" else _slot_for("socket")
		var key := sel_mount if sel_mount.begins_with("socket") else _socket_for(target_slot)
		if target_slot == "" or key == "":
			_pick.show_right_words("The socket", "Nothing fitted has a socket", [])
		elif not sim.mount_open(key):
			_pick.show_right_words("The socket", "Needs a Bench", [])
		else:
			var gear: Dictionary = sim.equipped[target_slot]
			var cur = gear["attachments"].get(key, null)
			if cur != null:
				_pick.show_fitted(cur, sim, "On the %s · %s" % [target_slot.to_lower(), key])
			else:
				_pick.show_right_words("On the %s · %s" % [target_slot.to_lower(), key], "Empty", ["Fitting it fills the socket"])
			buttons.append({"text": "Fit", "action": sim.fit_socket.bind(target_slot, key, it["id"]), "enabled": not sim.on_mission(), "primary": true})
	else:
		var target_slot := sel_slot if sel_slot != "" else _slot_for(it["mount"])
		if target_slot == "":
			_pick.show_right_words("The mount", "Nothing fitted takes a %s" % it["mount"], [["No %s with a %s mount" % ["bat or blade" if Items.is_melee_mount(it["mount"]) else "gun", it["mount"]], ""]])
		else:
			var gun: Dictionary = sim.equipped[target_slot]
			var cur = gun["attachments"].get(it["mount"], null)
			var why: String = sim.fit_refusal(target_slot, it["id"])
			var kicker: String = "On the %s · %s" % [target_slot.to_lower(), Items.mount_name(it["mount"]).to_lower()]
			if cur != null:
				_pick.show_fitted(cur, sim, kicker)
			else:
				_pick.show_right_words(kicker, "Empty", ["Fitting it: %.0f → %.0f dmg/s" % [Items.dps(gun), _dps_with(gun, it)]] if why == "" else [])
			if why == "":
				# the swap, as the gun's damage and each stat the part moves
				var deltas := []
				var d_dps: float = _dps_with(gun, it) - Items.dps(gun)
				if absf(d_dps) >= 0.5:
					deltas.append([d_dps, "%.0f dmg/s" % absf(d_dps)])
				for pair in [["damage_pct", "% dmg"], ["first_pct", "% first"], ["speed_pct", "% pace"], ["patrol_pct", "% delay"], ["conv_fire_pct", "% as fire"], ["conv_frost_pct", "% as frost"], ["conv_poison_pct", "% as poison"], ["conv_shock_pct", "% as shock"], ["conv_bleed_pct", "% as bleed"], ["salt", " armour"], ["wire_pct", "% tins"]]:
					var dv: float = Items.att_stat(it, pair[0]) - (Items.att_stat(cur, pair[0]) if cur != null else 0.0)
					if absf(dv) >= 0.5:
						deltas.append([dv, "%.0f%s" % [absf(dv), pair[1]]])
				var tone: String = "good" if d_dps > 0.5 else ("bad" if d_dps < -0.5 else "warn")
				_pick.set_verdict(("▲ Upgrade" if tone == "good" else ("▼ Downgrade" if tone == "bad" else "Sidegrade")) if cur != null else ("▲ Fits" if d_dps >= -0.5 else "▼ Costs damage"), tone, deltas)
			else:
				_pick.set_hint(why)
			buttons.append({"text": "Fit", "action": sim.fit.bind(target_slot, it["id"]), "enabled": why == "", "primary": true})
	_set_pick_buttons(buttons)


## The pick panel's buttons, each through _press_pick so the selection follows.
func _set_pick_buttons(buttons: Array) -> void:
	var items := []
	for i in range(buttons.size()):
		_pick_actions[i] = buttons[i]["action"]
		var d: Dictionary = buttons[i].duplicate()
		d["action"] = _press_pick.bind(i)
		items.append(d)
	_pick.set_buttons(items)


func _press_pick(i: int) -> void:
	if _pick_actions[i].is_valid():
		_pick_actions[i].call()
	if _selected_item().is_empty():
		sel_id = -1


## The gun this attachment would go on: the selected gun, else the primary
## if it has the mount, else the secondary.
## For a socketable: the first of the socket slots with an empty socket,
## else the first with any.
func _slot_for(mount: String) -> String:
	if mount == "socket":
		var any := ""
		for slot in Data.SOCKET_SLOTS:
			if sim.equipped[slot] != null and Items.sockets(sim.equipped[slot]) > 0:
				if any == "":
					any = slot
				if _socket_for(slot, true) != "":
					return slot
		return any
	for slot in GUNS:
		if sim.equipped[slot] != null and sim.equipped[slot]["attachments"].has(mount):
			return slot
	return ""


## The socket a socketable goes in on this slot's gear: the first empty one,
## else the first (unless only_empty).
func _socket_for(slot: String, only_empty := false) -> String:
	if slot == "" or sim.equipped[slot] == null:
		return ""
	var first := ""
	for key in sim.equipped[slot]["attachments"]:
		if str(key).begins_with("socket"):
			if sim.equipped[slot]["attachments"][key] == null:
				return key
			if first == "":
				first = key
	return "" if only_empty else first


## The stash's gear the Bench can work on.
func _craftable() -> Array:
	var out: Array = []
	for it in sim.stash:
		if not (Items.is_attachment(it) or Items.rig_item(it) or Items.is_paper(it) or it.has("unique") or it.has("set")):
			out.append(it)
	out.sort_custom(func(a, b): return a["value"] > b["value"])
	return out


## The Craft view: the piece as a card with its affixes as rows, THE JOBS
## priced under it, the pick panel at the right with the piece's figures.
func _show_craft(it: Dictionary) -> void:
	var on_bench: bool = not sim.on_mission()
	for l in _piece_words:
		l.text = ""
	_piece_figure.text = ""
	_piece_chips.visible = not it.is_empty()
	for r in _affix_rows:
		r["button"].visible = not it.is_empty()
	for b in _affix_buttons:
		b.visible = false
	if it.is_empty():
		sel_stat = ""
		_piece_title.text = "Pick a piece"
		_piece_words[0].text = "Stash gear only: not parts, meds, uniques or sets."
		_piece_words[1].text = "Worn gear: Workshop on it in the Kit."
		_piece_words[2].text = "The jobs below price up once a piece is picked."
		_pick.show_empty("Nothing picked", ["In hand: %s, %d notes and %d scrap" % [Fmt.money(sim.cash), sim.notes, sim.scrap], "Scrap: searched up, scrapped here, ditched"])
		_set_pick_buttons([])
	else:
		var h := Items.headline(it)
		var tw := Items.type_word(it)
		var fig := "%s %s" % [h[0], "dmg/s" if (tw != "" and Items.is_gun(it)) else h[1]]
		_piece_figure.text = fig
		_piece_title.size.x = BODY_W - 2 * PAD - ceilf(UI.text_width(_piece_figure, fig)) - 16
		UI.fit(_piece_title, [Items.full_name(it), it["base"]])
		var floor_t: int = mini(Items.tier_floor(Items.ilvl(it)), Items.rarity_cap(it))
		var chips := [[Items.rarity_name(it), Pal.tone_color(rarity_tone(it)) if rarity_tone(it) != "" else Pal.TEXT_2], ["Level %d" % Items.ilvl(it), Pal.TEXT_2],
			{"forms": ["Rolls T%d to T%d" % [floor_t, Items.rarity_cap(it)], "T%d–T%d" % [floor_t, Items.rarity_cap(it)]], "colour": Pal.TEXT_2}]
		if it["slot"] in Data.SOCKET_SLOTS:
			var n := Items.sockets(it)
			chips.append(["%d socket%s" % [n, "" if n == 1 else "s"] if n > 0 else "no sockets", Pal.TEXT_2])
		_piece_chips.show_chips(chips, 1)
		var lines: Array = Items.affix_lines(it, false, false)
		var short_lines: Array = Items.affix_lines(it, true, false)
		if not it["affixes"].any(func(a): return a["stat"] == sel_stat):
			sel_stat = ""
		for k in range(3):
			var r: Dictionary = _affix_rows[k]
			var has: bool = k < lines.size()
			r["stat"] = it["affixes"][k]["stat"] if has else ""
			var tier: int = Items.affix_tier(it, k)
			var colour: Color = Pal.tier_color(tier) if has else Pal.TEXT_3
			if has:
				UI.fit(r["label"], [lines[k], short_lines[k]])
			else:
				r["label"].text = "No %s affix" % ["first", "second", "third"][k] if k == lines.size() else ""
			r["label"].add_theme_color_override("font_color", colour)
			r["tag"].text = ("T%d" % tier) if has else ""
			r["dot"].add_theme_stylebox_override("panel", UI.box(colour, 4))
			r["dot"].visible = has or k == lines.size()
			r["button"].disabled = not has
			_style(r["button"], has and r["stat"] == sel_stat, "", not has, false)
			if not has:
				# a missing affix's row: no box at all
				for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
					r["button"].add_theme_stylebox_override(st, UI.box(Color.TRANSPARENT, 8))
		# the picked affix's two jobs, along the card's foot
		if sel_stat != "":
			# the two side by side, the longest words that fit the card's width
			var costs := [sim.craft_cost(it, "one", sel_stat), sim.craft_cost(it, "lock", sel_stat)]
			var forms := [["Re-roll this one", "Re-roll it", "This one"], ["Keep it, re-roll the rest", "Re-roll the rest", "The rest"]]
			for f in range(3):
				var x := PAD
				for i in range(2):
					var b := _affix_buttons[i]
					b.visible = costs[i] >= 0
					if costs[i] < 0:
						continue
					b.text = "%s · %s" % [forms[i][f], Fmt.money(costs[i])]
					b.disabled = not (on_bench and sim.can_craft(it["id"], ["one", "lock"][i], sel_stat))
					b.size.x = ceilf(UI.text_width(b, b.text)) + 32
					b.position.x = x
					x += b.size.x + 8
					_affix_actions[i] = _do_craft.bind(it["id"], ["one", "lock"][i], sel_stat)
				if x - 8 <= BODY_W - PAD:
					break
		_pick.show_pick(it, sim, "The piece · worn" if _worn(it) else "The piece · in the stash")
		_set_pick_buttons([])
	# THE JOBS
	for k in range(JOBS.size()):
		var kind: String = JOBS[k]
		var t: Dictionary = _job_tiles[k]
		var b: Button = t["button"]
		t["name"].text = JOB_NAMES.get(kind, Data.CRAFT.get(kind, {}).get("name", kind))
		UI.wrap(t["words"], JOB_WORDS.get(kind, Data.CRAFT.get(kind, {}).get("words", "")))
		var cost: int = -1
		if not it.is_empty():
			cost = ((-1 if _worn(it) else sim.scrap_of(it)) if kind == "scrap" else sim.craft_cost(it, kind))     # a worn piece isn't scrapped off the runner
		var can: bool = false
		if cost >= 0:
			can = on_bench and (true if kind == "scrap" else sim.can_craft(it["id"], kind))
			t["price"].text = ("+%d scrap" % cost) if kind == "scrap" else (("%d notes" % cost) if sim.craft_in_notes(kind) else Fmt.money(cost))
			_job_actions[k] = _do_craft.bind(it["id"], kind, "")          # scrap too: main runs it, toasts it
		else:
			t["price"].text = ""
			_job_actions[k] = Callable()
		# gold when it can be paid, grey when short, hollow when the piece can't take it (or none is picked)
		var state := "on" if can else ("off" if cost >= 0 else "none")
		t["price"].add_theme_color_override("font_color", Pal.ACCENT if can else Pal.TEXT_2)
		t["name"].add_theme_color_override("font_color", Pal.TEXT if state != "none" else Pal.TEXT_3)
		for l in t["words"]:
			l.add_theme_color_override("font_color", Pal.TEXT_2 if state != "none" else Pal.TEXT_3)
		b.disabled = not can
		for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var bg: Color = Pal.CARD if state != "none" else Color.TRANSPARENT
			if state == "on" and st in ["hover", "hover_pressed"]:
				bg = Pal.BUTTON_HOVER
			b.add_theme_stylebox_override(st, UI.box(bg, 7, 1, Pal.CARD_LINE if state != "none" else Pal.RAIL_RULE))
		b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 7, 2, Pal.TEXT))
	# the foot: the Bench's last job stays until the next; Build for scrap at the right
	_build.text = "Build for scrap"
	_build.size.x = ceilf(UI.text_width(_build, _build.text)) + 48
	_build.position.x = BODY_W - PAD - _build.size.x
	_build.disabled = not on_bench
	_foot.size.x = _build.position.x - 12 - PAD
	if not sim.last_craft.is_empty() and (sim.last_craft.get("kind", "") in ["build", "scrap"] or sim.last_craft.get("id", -1) == it.get("id", -2)):
		var w: String = str(sim.last_craft["words"])
		UI.fit(_foot, [w, w.get_slice(":", 0), w.get_slice(" · ", 0), w.get_slice(" ", 0)])     # down to its first word ("Added", "Re-rolled"): what was done, if not what to
		_foot.add_theme_color_override("font_color", Pal.GOOD)
	else:
		UI.fit(_foot, ["Nothing in the Workshop yet" if it.is_empty() else "%d scrap in hand" % sim.scrap, "%d scrap in hand" % sim.scrap])
		_foot.add_theme_color_override("font_color", Pal.TEXT_3)


func _do_craft(id: int, kind: String, stat: String) -> void:
	craft.emit(id, kind, stat)


func _pick_affix(k: int) -> void:
	var stat: String = _affix_rows[k]["stat"]
	sel_stat = "" if stat == sel_stat else stat
	_shown = ""
	show_state(sim)


func _press_affix_job(i: int) -> void:
	if _affix_actions[i].is_valid():
		_affix_actions[i].call()
	acted.emit()


func _press_job(k: int) -> void:
	if _job_actions[k].is_valid():
		_job_actions[k].call()
	if _selected_item().is_empty():
		sel_id = -1
	acted.emit()


func _set_view(v: String) -> void:
	if v == view:
		return
	view = v
	sel_slot = ""
	sel_mount = ""
	sel_id = -1
	sel_stat = ""
	_show_view()
	if sim != null:
		show_state(sim)


func _show_view() -> void:
	for i in range(3):
		_style(_views[i], ["guns", "sockets", "craft"][i] == view)
	_piece.visible = view == "craft"
	_jobs.visible = view == "craft"
	for slot in GUNS:
		var g: Dictionary = _guns[slot]
		g["card"].visible = view == "guns"
	for slot in Data.SOCKET_SLOTS:
		var g: Dictionary = _socks[slot]
		g["head"].visible = view == "sockets"
		for mount in g["rows"]:
			g["rows"][mount]["button"].visible = view == "sockets"


## The gun's damage a second with this attachment in place of the mount's.
func _dps_with(gun: Dictionary, it: Dictionary) -> float:
	var copy := gun.duplicate(true)
	copy["attachments"][it["mount"]] = it
	return Items.dps(copy)


# ------------------------------------------------------------------ acting

func _pick_mount(slot: String, mount: String) -> void:
	sel_slot = slot
	sel_mount = mount
	sel_id = -1
	show_state(sim)


func _on_inv_pick(id: int) -> void:
	if id >= 0:
		if id != sel_id:
			sel_stat = ""                  # a new piece: no affix picked on it yet
		sel_id = id
		var it := _selected_item()
		if sel_mount == "" and not it.is_empty() and view != "craft":
			if Items.is_socketable(it):
				sel_slot = _slot_for("socket")
				sel_mount = _socket_for(sel_slot)
			else:
				sel_mount = it["mount"]
				sel_slot = _slot_for(sel_mount)
	elif _inv.many:
		sel_id = -1
	show_state(sim)


func _on_inv_acted() -> void:
	if _selected_item().is_empty():
		sel_id = -1
	acted.emit()


## For the tests.
func _pick_cell(k: int) -> void:
	_inv._pick(k)


func _press(i: int) -> void:
	_pick.press(i)                     # the pick panel's button: its action, then the shell's refresh


func text_nodes() -> Array:
	var out: Array = [_kicker, _headline, _unit, _next]
	out.append_array(_chips.text_nodes())
	out.append_array(_views)
	out.append_array(_pick.text_nodes())
	if view == "craft":
		out.append_array([_piece_title, _piece_figure, _jobs_head, _foot, _build])
		out.append_array(_piece_chips.text_nodes() if _piece_chips.visible else [])
		for l in _piece_words:
			if l.text != "":
				out.append(l)
		for r in _affix_rows:
			if r["button"].visible and r["label"].text != "":
				out.append_array([r["label"], r["tag"]])
		for b in _affix_buttons:
			if b.visible:
				out.append(b)
		for t in _job_tiles:
			out.append(t["name"])
			for l in t["words"]:
				if l.text != "":
					out.append(l)
			if t["price"].text != "":
				out.append(t["price"])
	elif view == "guns":
		for slot in GUNS:
			var g: Dictionary = _guns[slot]
			out.append_array([g["label"], g["name"], g["figure"]])
			if g["chips"].visible:
				out.append_array(g["chips"].text_nodes())
			for r in g["rows"]:
				if r["button"].visible:
					out.append_array([r["mount"], r["fitted"]])
					if r["lock"].text != "":
						out.append(r["lock"])
	else:
		for slot in Data.SOCKET_SLOTS:
			var g: Dictionary = _socks[slot]
			out.append_array([g["label"], g["name"]])
			for mount in g["rows"]:
				var r: Dictionary = g["rows"][mount]
				out.append_array([r["mount"], r["fitted"]])
	out.append_array(_inv.text_nodes())
	return out


## A mount tile's name sits over its fitted part, so no pair shares a line;
## the gun's head keeps its slot and figure on one, the piece its name and figure
## (the heading's unit is laid after its level, so it is fitted on its own).
func line_pairs() -> Array:
	var out: Array = _pick.line_pairs()
	if view == "guns":
		for slot in GUNS:
			out.append([_guns[slot]["label"], _guns[slot]["figure"]])
			for r in _guns[slot]["rows"]:
				if r["button"].visible and r["lock"].text != "":
					out.append([r["mount"], r["lock"]])
	elif view == "sockets":
		for slot in Data.SOCKET_SLOTS:
			out.append([_socks[slot]["label"], _socks[slot]["name"]])
	else:
		out.append([_piece_title, _piece_figure])
		for r in _affix_rows:
			if r["button"].visible and r["tag"].text != "":
				out.append([r["label"], r["tag"]])
	return out
