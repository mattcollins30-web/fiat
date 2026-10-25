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
signal built(kind, name)            # the Build view (21 Oct, out of the old menu): main builds it and toasts it

const Pal := preload("res://scripts/ui/palette.gd")
const Arm := preload("res://scripts/ui/arm.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const Inventory := preload("res://scripts/ui/inventory.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const PickPanel := preload("res://scripts/ui/pick_panel.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")
const ItemHeadRef := preload("res://scripts/ui/item_head.gd")

const BODY_W := Inventory.SIDE_W                              # 608
const GAP := 24
const PAD := 20
const HEAD_H := Pal.BAND_H         # the rooms' one band across the top (10 Oct, Bands-U A): 118 → 180
const TOP := HEAD_H + 14           # the columns under it
const VIEW_W := 144                # a view's tab (140 until "Weapons", 18 Oct)
const VIEW_H := 40
const VIEWS := ["guns", "sockets", "craft", "build", "patterns"]
const VIEW_NAMES := ["Weapons", "Sockets", "Craft", "Build", "Patterns"]     # Patterns (24 Oct, the endgame chase)
const VIEWS_X := Pal.GRID_W - PAD - 5 * (VIEW_W + 6) + 6     # the views at the band's foot, right (Bands-U A): five since Patterns
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
const PIECE_H := 372               # the Craft view's piece card: five affix rows, their padlocks, the two re-rolls (20 Oct)
const AFFIX_H := 38                # an affix row
const AFFIX_ROWS := 5              # a Legendary's five (20 Oct, Matt: "i can only ever see 3 out of the 5 affixes")
const AFFIX_BTN_H := 46            # the two re-rolls, a row under the affixes
const JOB_COLS := 3
const JOB_H := 104                 # a job tile
const JOB_GAP := 8
@warning_ignore("integer_division")
const JOB_W := (BODY_W - 2 * PAD - JOB_GAP) / JOB_COLS        # 280
const JOBS := ["add", "socket", "strip", "bump", "temper", "scrap"]      # the re-rolls are the piece card's now, by its padlocks (20 Oct); Temper the sixth tile (25 Oct)
const JOB_NAMES := {"bump": "Item level +3", "temper": "Temper +1", "scrap": "Scrap it", "strip": "Strip affixes"}
const JOB_WORDS := {"add": "One more affix, the rarity a step up", "socket": "Adds a socket, up to %d", "strip": "Every affix gone; it goes Common",
	"bump": "The lowest affix tiers stop rolling", "temper": "+1 item level: damage, armour, HP grow", "scrap": "Broken down for scrap; gone for good"}
const RE_ROLLS := ["values", "affixes"]
const ORDINAL := ["first", "second", "third", "fourth", "fifth"]
const FOOT_H := 44
const GUNS := ["Primary", "Secondary"]
## The Build view (21 Oct, "Fiat – Build for scrap" A): what to build as tiles, its builds as cards, the stash's kind on
## the right with what the picked one takes ringed, the pick panel the build.
## A kind: its key, its tile's name, the slot it makes, the slot it takes from (the grid shows that), what it takes.
const BUILD_KINDS := [["box", "Rounds", "Ammo", "Ammo", "A box of any type you have a gun for"], ["grade", "Grades", "Ammo", "Ammo", "Scrap and the box below it"],
	["med", "Meds", "Medical", "Medical", "Scrap and the one below it"], ["gun", "Guns", "Primary", "Primary", "Common, plain, fires nails"],
	["grenade", "Grenades", "Grenade", "Attachment", "Scrap and the element's socketable"]]
const KIND_H := 70
const KINDS_H := 40 + KIND_H + 14
const BUILD_COLS := 2
const BUILD_ROWS := 6               # twelve a page: the guns are eleven once the deep tiers open (the review); more pages if more
const BUILD_CARD_H := 64
const BUILD_GAP := 8
@warning_ignore("integer_division")
const BUILD_CARD_W := (BODY_W - 2 * PAD - BUILD_GAP) / BUILD_COLS
@warning_ignore("integer_division")
const KIND_W := (BODY_W - 2 * PAD - 4 * BUILD_GAP) / 5

var head_band := {}                # the heading's painted place (10 Oct, Rooms-B)
var sim
var view := "guns"                 # "guns", "sockets", "craft", "build" or "patterns"
var sel_pattern := -1              # the Patterns view: the pattern kept that's picked
var _pat: Panel                    # the Patterns view's column
var _pat_labels := {}
var _pat_rows: Array = []          # the patterns kept, as buttons
var _pat_break: Button
var _pat_put: Button
var _pat_cost: Chips
var build_kind := "med"            # the Build view's kind, and the build picked in it
var sel_build := ""
var build_page := 0
var _tab_turned_for := ""          # the build the grid last turned its tab for: once a pick, so Shared can still be looked at
var _kinds: Panel
var _kind_tiles: Array = []        # five: {button, name, count}
var _builds: Panel
var _builds_head: Label
var _build_cards: Array = []       # ten: {button, name, cost, words}
var _builds_foot: Label
var _build_prev: Button
var _build_next: Button
var _build_pages: Label
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
var _affix_rows: Array = []                   # five: {button, lock, label, tag, track, mark} - a row toggles its padlock
var _affix_buttons: Array[Button] = []        # the two re-rolls of what isn't locked: values, affixes
var _lock_line: Label                         # what's locked, the padlocks in use
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
	_kicker = UI.label(head, Rect2(PAD, 8, Pal.BAND_TEXT_W, 24), "Workshop", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_headline = UI.label(head, Rect2(PAD, 32, Pal.BAND_TEXT_W, 44), "", "SemiBold", Pal.HEADLINE - 4, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_unit = UI.label(head, Rect2(PAD, 38, Pal.BAND_TEXT_W, 36), "", "Medium", Pal.CELL_TEXT_BIG + 2, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	for i in range(VIEWS.size()):
		var v := UI.button(head, Rect2(VIEWS_X + i * (VIEW_W + 6), HEAD_H - 16 - VIEW_H, VIEW_W, VIEW_H), false)      # plain: _style skins the one that's on (a primary start left Guns' text dark, 8 Oct)
		v.text = VIEW_NAMES[i]     # the hammer and the knife are in it (18 Oct, Q12)
		v.pressed.connect(_set_view.bind(VIEWS[i]))
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
	var ay := 54 + Chips.CHIP_H + 8
	var rw: float = BODY_W - 2 * PAD + 20
	for k in range(AFFIX_ROWS):
		var b := Button.new()
		b.position = Vector2(PAD - 10, ay + k * AFFIX_H)
		b.size = Vector2(rw, AFFIX_H - 2)
		b.text = ""
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_toggle_lock.bind(k))
		_piece.add_child(b)
		var r := {"button": b, "stat": ""}
		r["lock"] = TextureRect.new()
		r["lock"].texture = NodeGlyphs.texture("lock")
		r["lock"].position = Vector2(10, (AFFIX_H - 2 - 22) / 2.0)
		r["lock"].size = Vector2(22, 22)
		r["lock"].expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r["lock"].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r["lock"].mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(r["lock"])
		r["label"] = UI.label(b, Rect2(42, 0, rw - 54, AFFIX_H - 8), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		r["tag"] = UI.label(b, Rect2(42, 0, rw - 54, AFFIX_H - 2), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT)     # the line's right end: the tier and its range
		# where the roll sits in its tier: a track under the words, a mark on it
		r["track"] = UI.panel(b, Rect2(42, AFFIX_H - 9, rw - 42 - 180, 4), UI.box(Pal.BG, 2))
		r["track"].mouse_filter = Control.MOUSE_FILTER_IGNORE
		r["mark"] = UI.panel(r["track"], Rect2(0, -3, 4, 10), UI.box(Pal.TEXT_2, 2))
		r["mark"].mouse_filter = Control.MOUSE_FILTER_IGNORE
		_affix_rows.append(r)
	_lock_line = UI.label(_piece, Rect2(PAD, ay + AFFIX_ROWS * AFFIX_H + 2, BODY_W - 2 * PAD, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	@warning_ignore("integer_division")
	var bw: int = (BODY_W - 2 * PAD - 8) / 2
	for i in range(2):
		var b := UI.button(_piece, Rect2(PAD + i * (bw + 8), PIECE_H - 12 - AFFIX_BTN_H, bw, AFFIX_BTN_H), i == 0)
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
		@warning_ignore("integer_division")
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
			t["words"].append(UI.label(b, Rect2(12, 34 + i * 20, JOB_W - 24, 20), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false))
		t["price"] = UI.label(b, Rect2(12, JOB_H - 30, JOB_W - 24, 26), "", "SemiBold", Pal.CELL_TEXT_BIG, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, true)
		_job_tiles.append(t)
		_job_actions.append(Callable())
	@warning_ignore("integer_division")
	var fy := jy + ((JOBS.size() + JOB_COLS - 1) / JOB_COLS) * (JOB_H + JOB_GAP) + 4
	_build = UI.button(_jobs, Rect2(BODY_W - PAD - 100, fy, 100, FOOT_H), false)
	_build.pressed.connect(func(): _set_view("build"))     # the Build view (21 Oct): the old menu's gone
	_foot = UI.label(_jobs, Rect2(PAD, fy, BODY_W - 2 * PAD - 240, FOOT_H), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_jobs.size.y = fy + FOOT_H + 14
	# the Guns view: a card a gun - the slot and figure, the name and its chips, the mounts as tiles
	var y := TOP
	@warning_ignore("integer_division")
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
			@warning_ignore("integer_division")
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
	@warning_ignore("integer_division")
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
	_build_build_view()
	_build_patterns_view()
	_show_view()
	# the grid: the stash's attachments, for the selected mount when one is; the gear in the Craft view
	_inv = Inventory.new()
	_inv.position = Vector2(GRID_X, TOP)
	_inv.set_rows(GRID_ROWS)
	_inv.fixed_kind = Data.ATTACHMENT
	_inv.stash_tabs = true                # the shared tab and the class's own, as the Armoury's (21 Oct)
	_inv.picked.connect(_on_inv_pick)
	_inv.acted.connect(_on_inv_acted)
	add_child(_inv)
	_pick = PickPanel.new(GRID_W, PANEL_H)
	_pick.position = Vector2(GRID_X, PANEL_Y)
	_pick.acted.connect(func(): acted.emit())
	add_child(_pick)
	for i in range(PickPanel.BUTTONS):
		_pick_actions.append(Callable())


func _build_build_view() -> void:
	_kinds = UI.panel(self, Rect2(0, TOP, BODY_W, KINDS_H), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	UI.label(_kinds, Rect2(PAD, 10, 300, 24), "WHAT TO BUILD", "Medium", 13, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(BUILD_KINDS.size()):
		var b := Button.new()
		b.position = Vector2(PAD + k * (KIND_W + BUILD_GAP), 40)
		b.size = Vector2(KIND_W, KIND_H)
		b.text = ""
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick_kind.bind(str(BUILD_KINDS[k][0])))
		_kinds.add_child(b)
		var t := {"button": b}
		t["name"] = UI.label(b, Rect2(8, 8, KIND_W - 16, 26), str(BUILD_KINDS[k][1]), "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		t["count"] = UI.label(b, Rect2(8, 36, KIND_W - 16, 22), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		_kind_tiles.append(t)
	var by: float = TOP + KINDS_H + 10
	_builds = UI.panel(self, Rect2(0, by, BODY_W, Pal.ROOM_H - by), UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
	_builds_head = UI.label(_builds, Rect2(PAD, 10, BODY_W - 2 * PAD, 24), "", "Medium", 13, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(BUILD_COLS * BUILD_ROWS):
		var b := Button.new()
		@warning_ignore("integer_division")
		b.position = Vector2(PAD + (k % BUILD_COLS) * (BUILD_CARD_W + BUILD_GAP), 40 + (k / BUILD_COLS) * (BUILD_CARD_H + BUILD_GAP))
		b.size = Vector2(BUILD_CARD_W, BUILD_CARD_H)
		b.text = ""
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_pick_build_card.bind(k))
		_builds.add_child(b)
		var c := {"button": b, "name_key": ""}
		c["name"] = UI.label(b, Rect2(12, 6, BUILD_CARD_W - 24, 26), "", "SemiBold", Pal.CELL_TEXT_BIG + 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["cost"] = UI.label(b, Rect2(12, 34, BUILD_CARD_W - 24, 22), "", "SemiBold", Pal.CELL_TEXT - 1, Pal.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT)
		c["words"] = UI.label(b, Rect2(12, 34, BUILD_CARD_W - 24, 22), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		_build_cards.append(c)
	var fy: float = 40 + BUILD_ROWS * (BUILD_CARD_H + BUILD_GAP) + 6
	_builds_foot = UI.label(_builds, Rect2(PAD, fy, BODY_W - 2 * PAD - 150, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_build_prev = UI.button(_builds, Rect2(BODY_W - PAD - 140, fy - 4, 40, 34), false)
	_build_prev.text = "‹"
	_build_prev.pressed.connect(_turn_builds.bind(-1))
	_build_pages = UI.label(_builds, Rect2(BODY_W - PAD - 100, fy, 60, 26), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
	_build_next = UI.button(_builds, Rect2(BODY_W - PAD - 40, fy - 4, 40, 34), false)
	_build_next.text = "›"
	_build_next.pressed.connect(_turn_builds.bind(1))


static func build_slot(kind: String) -> String:
	return _kind_field(kind, 2)


## The slot a kind's builds take from: the grid shows it (a grenade takes a socketable: the review).
static func takes_slot(kind: String) -> String:
	return _kind_field(kind, 3)


static func _kind_field(kind: String, f: int) -> String:
	for k in BUILD_KINDS:
		if k[0] == kind:
			return str(k[f])
	return ""


func _build_page_count() -> int:
	@warning_ignore("integer_division")
	return maxi(1, (sim.build_options(build_kind).size() + _build_cards.size() - 1) / _build_cards.size())


func _turn_builds(d: int) -> void:
	build_page = posmod(build_page + d, _build_page_count())
	_shown = ""
	show_state(sim)


func _pick_kind(kind: String) -> void:
	build_kind = kind
	sel_build = ""
	build_page = 0
	_shown = ""
	show_state(sim)


func _pick_build_card(k: int) -> void:
	sel_build = str(_build_cards[k]["name_key"])
	_shown = ""
	show_state(sim)


func _do_build(kind: String, nm: String) -> void:
	built.emit(kind, nm)


## A why-not, short: "Wants a box of pistol hollow point" → "No pistol hollow point".
static func why_short(why: String) -> String:
	return why.replace("Wants a box of ", "No ").replace("Wants a ", "No ").replace("Wants ", "No ")


## What a build's card says under its name: its tier, then what it wants and whether it's in the stash, or why not.
func build_words(o: Dictionary) -> Array:
	var t: String = "T%d" % int(o["tier"])
	if not bool(o["ok"]):
		var why: String = str(o["why"])
		return ["%s · %s" % [t, why], why, "%s · %s" % [t, why_short(why)], why_short(why)]     # the why outlives the tier (the smoke: a card read "T2" alone)
	if str(o["from"]) != "":
		var what: String = ("a box of %s" % str(o["from"]).to_lower()) if o["kind"] == "grade" else str(o["from"]).to_lower()
		return ["%s · wants %s" % [t, what], "%s · %s" % [t, what], t]
	return [t]


func _show_build() -> void:
	var on_bench: bool = not sim.on_mission()
	for k in range(BUILD_KINDS.size()):
		var t: Dictionary = _kind_tiles[k]
		var kind: String = str(BUILD_KINDS[k][0])
		var n: int = sim.build_options(kind).filter(func(o): return bool(o["ok"])).size()
		UI.fit(t["count"], [("%d to build" % n) if n > 0 else "none yet", str(n)])
		t["count"].add_theme_color_override("font_color", Pal.TEXT_2 if n > 0 else Pal.TEXT_3)
		_style(t["button"], kind == build_kind)
	var all_opts: Array = sim.build_options(build_kind)
	var pages: int = _build_page_count()
	build_page = clampi(build_page, 0, pages - 1)
	var opts: Array = all_opts.slice(build_page * _build_cards.size(), (build_page + 1) * _build_cards.size())
	var title: String = _kind_field(build_kind, 1).to_upper()
	var takes: String = _kind_field(build_kind, 4).to_upper()
	UI.fit(_builds_head, ["%s · %s · %d SCRAP IN HAND" % [title, takes, sim.scrap], "%s · %s" % [title, takes], "%s · %d SCRAP IN HAND" % [title, sim.scrap], title])
	_build_prev.visible = pages > 1
	_build_next.visible = pages > 1
	_build_pages.visible = pages > 1
	_build_pages.text = "%d/%d" % [build_page + 1, pages]
	for k in range(_build_cards.size()):
		var c: Dictionary = _build_cards[k]
		var b: Button = c["button"]
		b.visible = k < opts.size()
		if not b.visible:
			c["name_key"] = ""
			continue
		var o: Dictionary = opts[k]
		c["name_key"] = str(o["name"])
		UI.fit(c["name"], [str(o["name"])])
		c["cost"].text = "%d scrap" % int(o["scrap"])
		c["words"].size.x = BUILD_CARD_W - 24 - ceilf(UI.text_width(c["cost"], c["cost"].text)) - 16     # the cost on the words' line, right: the name has the card's width
		UI.fit(c["words"], build_words(o))
		var ok: bool = bool(o["ok"])
		c["name"].add_theme_color_override("font_color", Pal.TEXT if ok else Pal.TEXT_3)
		c["cost"].add_theme_color_override("font_color", Pal.ACCENT if ok else Pal.TEXT_3)
		c["words"].add_theme_color_override("font_color", Pal.TEXT_2 if ok else Pal.BAD)
		_style(b, str(o["name"]) == sel_build, "", not ok)
	_builds_foot.text = "" if on_bench else "The runner is out: the Bench waits"
	# the pick panel: the build, or what to do
	var picked: Dictionary = sim.build_option(build_kind, sel_build) if sel_build != "" else {}
	if picked.is_empty():
		sel_build = ""
		_pick.show_empty("Pick a build", ["%d scrap in hand" % sim.scrap, "Scrap comes from searches, scrapping here and ditching"])
		_set_pick_buttons([])
		return
	var made: Dictionary = sim._plain(build_slot(build_kind), str(picked["name"]))
	_pick.show_pick(made, sim, "Build · it makes")
	var lines: Array = []
	if str(picked["from"]) != "":
		var have: int = sim._rounds_in_stash(str(picked["from"])) if build_kind == "grade" else sim._count_in_stash(str(picked["from"]))
		lines.append(("A box of %s: %d rounds in the stash" % [str(picked["from"]).to_lower(), have]) if build_kind == "grade" else ("%s: %d in the stash" % [str(picked["from"]), have]))
	if not bool(picked["ok"]):
		lines.append(str(picked["why"]))
	_pick.show_right_words("It takes", "%d of %d scrap" % [int(picked["scrap"]), sim.scrap], lines)
	_set_pick_buttons([{"text": "Build · %d scrap" % int(picked["scrap"]), "action": _do_build.bind(build_kind, str(picked["name"])), "enabled": bool(picked["ok"]), "primary": true}])


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
	var what: String = "Socketables" if view == "sockets" else "Gun parts"
	if sel_mount != "":
		what = sel_mount.capitalize() if sel_mount.begins_with("socket") else "%s mount" % Items.mount_name(sel_mount)
	if view == "craft":
		source = _craftable()
		what = "Gear"
	_inv.marks = {}
	if view == "build":
		var slot_b: String = takes_slot(build_kind)
		source = sim.stash.filter(func(it): return str(it["slot"]) == slot_b)
		what = _kind_field(build_kind, 1)
		var ob: Dictionary = sim.build_option(build_kind, sel_build) if sel_build != "" else {}
		if not ob.is_empty() and str(ob["from"]) != "":
			var tabs_with := {}
			for it in source:
				if str(it["base"]) == str(ob["from"]):
					_inv.marks[it["id"]] = "go"     # what the picked build takes, ringed (the mock)
					tabs_with[sim.tab_of(it)] = true
			if sel_build != _tab_turned_for and not tabs_with.is_empty() and not tabs_with.has(_inv.tab):
				_inv.tab = str(tabs_with.keys()[0])
				_inv.page = 0
		_tab_turned_for = sel_build     # the grid turns to the tab that holds it (the build takes from any: the review)
	if view == "patterns":
		source = sim.stash.filter(func(it): return (it.has("unique") and not it.get("mythic", false)) or (int(it.get("rarity", 0)) >= Data.PATTERN_RARITY and not it.has("set") and not it.has("pattern") and str(it.get("rule", "")) == "" and str(it.get("slot", "")) in Data.SLOTS))
		what = Words.PATTERNS["tab"]
	_inv.fixed_kind = "" if view in ["craft", "patterns"] else (takes_slot(build_kind) if view == "build" else Data.ATTACHMENT)
	_inv.show_items(sim, source, sim.stash_used(), sim.stash_cap(), what)
	if view == "patterns":
		_show_patterns()
		return
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
			var type_word: String = str(Items.base_of(gun).get("type", "gun"))
			g["chips"].show_chips([[type_word.to_upper() if type_word == "smg" else type_word.capitalize(), Pal.TEXT_2], [Items.rarity_name(gun), Pal.tone_color(rarity_tone(gun)) if rarity_tone(gun) != "" else Pal.TEXT_2]])     # what's fitted is the mount tiles' (18 Oct, said once)
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
				r["fitted"].add_theme_font_size_override("font_size", UI.TILE_TEXT)
				r["fitted"].text = "Empty"
				r["fitted"].add_theme_color_override("font_color", Pal.TEXT_3)
				_style(r["button"], on)
			else:
				_fit_part(r["fitted"], str(a["base"]))
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
				r["fitted"].add_theme_font_size_override("font_size", UI.TILE_TEXT)
				r["fitted"].text = "Empty"
				r["fitted"].add_theme_color_override("font_color", Pal.TEXT_3)
				_style(r["button"], on)
			else:
				_fit_part(r["fitted"], str(a["base"]))
				r["fitted"].add_theme_color_override("font_color", Pal.tier_color(int(a.get("tier", 1))))
				_style(r["button"], on, rarity_tone(a))
	# the heading (9 Oct): every job and mount open from the start; the Bench's picks, built in the Yard, named
	var picks: Array = []
	var bench := Data.yard_building("bench")
	for c in range(bench["picks"].size()):
		var sd: String = sim.yard_side("bench", c)
		for k in range(2):
			if sd.contains("ab"[k]):
				picks.append(str(bench["picks"][c][k]["name"]))     # both sides of a column can be built (24 Oct, option B)
	var cols_built: int = range(bench["picks"].size()).filter(func(c): return sim.yard_side("bench", c) != "").size()
	_headline.text = "%d of 5" % cols_built
	_unit.position.x = PAD + ceilf(UI.text_width(_headline, _headline.text)) + 10
	_unit.size.x = PAD + Pal.BAND_TEXT_W + 120 - _unit.position.x
	UI.fit(_unit, ["upgrades built · rank %d" % sim.yard_rank("bench") if sim.yard_rank("bench") > 0 else "upgrades built", "upgrades"])
	_chips.show_chips([], 3)     # tins, notes and scrap are the top bar's and the Craft panel's (18 Oct, said once)
	if picks.is_empty():
		UI.fit(_next, ["Every job and mount is open from the start; the Bench's upgrades are built on the Pitch", "The Bench's upgrades are built on the Pitch", "Upgrades: the Pitch"])
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
	return out


## A part's name in its slot (20 Oct, Matt: "Hundre" in the Magazine slot): the whole name, else its first word, never
## a word cut; when even that's too wide the type steps down, PART_MIN at the least.
const PART_MIN := UI.TILE_TEXT - 6


static func _fit_part(l: Label, base: String) -> void:
	l.remove_theme_font_size_override("font_size")
	var forms: Array = _short_names(base)
	var fs: int = UI.TILE_TEXT
	while true:
		l.add_theme_font_size_override("font_size", fs)
		for o in forms:
			if UI.text_width(l, o) <= l.size.x:
				l.text = o
				return
		if fs <= PART_MIN:
			l.text = forms.back()
			return
		fs -= 1


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
	@warning_ignore("integer_division")
	var parts := [view, sel_slot, sel_mount, str(sel_id), str(sel_pattern), _break_arm.sig(), str(sim.patterns.size()), sel_stat, str(sim.on_mission()), str(sim.yard_picks.get("bench", [])) + str(sim.yard_rank("bench")), str(int(sim.cash) / 100), str(_inv.many),
		str(sim.notes), str(sim.scrap), str(sim.last_craft.get("id", -1)), str(sim.last_craft.get("words", "")), build_kind, sel_build, str(build_page), str(sim.stash.size()), str(sim.stash_used()), str(sim.gun_types_held()), str(sim.deepest_site_level()), _inv.tab]
	# the craft view's piece changes under the Bench: its level, affixes and sockets are in the signature too
	var picked := _selected_item()
	if not picked.is_empty():
		parts.append(str(hash([picked.get("ilvl", 0), picked.get("affixes", []), picked.get("attachments", {}).keys(), picked.get("locks", []), sim.lock_max()])))
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
	if view == "build":
		_show_build()
		return
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
			_pick.show_right_words("The socket", "Needs a Bench upgrade: built on the Pitch", [])
		else:
			var gear: Dictionary = sim.equipped[target_slot]
			var cur = gear["attachments"].get(key, null)
			var gun_slot: bool = Data.SLOT_SCORE.get(target_slot, "") == "dps"
			# what it does (19 Oct, Matt): in a gun, the top bar's figure; in a body piece, the body's figure the Kit judges by
			var dw: Array = sim.damage_with_part(target_slot, it, key) if gun_slot else sim.body_with_part(target_slot, it, key)
			var line: String = ("Fitting it: %.0f → %.0f dmg/s" % [float(dw[0]), float(dw[1])]) if gun_slot else ("Fitting it: stands the fight %.1f× → %.1f×" % [float(dw[0]), float(dw[1])])
			if cur != null:
				_pick.show_fitted(cur, sim, "On the %s · %s" % [target_slot.to_lower(), key])
			else:
				_pick.show_right_words("On the %s · %s" % [target_slot.to_lower(), key], "Empty", [line])
			_part_verdict(it, cur, dw, gun_slot)
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
			var dw: Array = sim.damage_with_part(target_slot, it)     # the top bar's figure, before and after (18 Oct), read once
			if cur != null:
				_pick.show_fitted(cur, sim, kicker)
			else:
				_pick.show_right_words(kicker, "Empty", ["Fitting it: %.0f → %.0f dmg/s" % [float(dw[0]), float(dw[1])]] if why == "" else [])
			if why == "":
				_part_verdict(it, cur, dw)
			else:
				_pick.set_hint_options([why, ("No " + why.get_slice(" has no ", 1)) if why.contains(" has no ") else why.get_slice(":", 0), "Doesn't fit"])     # short forms for the tail's chip (the review)
			buttons.append({"text": "Fit", "action": sim.fit.bind(target_slot, it["id"]), "enabled": why == "", "primary": true})
	_set_pick_buttons(buttons)


## A part's or a socketable's verdict against what's there: the runner's damage as the top bar reads it, the burn in
## (18 Oct), and each stat it moves. Gun parts and socketables alike (19 Oct).
func _part_verdict(it: Dictionary, cur, dw: Array, by_damage := true) -> void:
	var deltas := []
	var d_dps: float = float(dw[1]) - float(dw[0])
	if not by_damage:
		d_dps = d_dps / maxf(absf(float(dw[0])), 0.01) * 100.0     # a body piece's figure moves in shares: a percent of it reads as the damage's 1
	elif absf(d_dps) >= 0.5:
		deltas.append([d_dps, "%.0f dmg/s" % absf(d_dps)])
	for pair in [["damage_pct", "% dmg"], ["first_pct", "% first"], ["speed_pct", "% pace"], ["patrol_pct", "% delay"], ["conv_fire_pct", "% as fire"], ["conv_frost_pct", "% as frost"], ["conv_poison_pct", "% as poison"], ["conv_shock_pct", "% as shock"], ["conv_bleed_pct", "% as bleed"], ["salt", " armour"], ["wire_pct", "% tins"]]:
		var dv: float = Items.att_stat(it, pair[0]) - (Items.att_stat(cur, pair[0]) if cur != null else 0.0)
		if absf(dv) >= 0.5:
			deltas.append([dv, "%.0f%s" % [absf(dv), pair[1]]])
	var tone: String = "good" if d_dps > 0.5 else ("bad" if d_dps < -0.5 else "warn")
	_pick.set_verdict(("▲ Upgrade" if tone == "good" else ("▼ Downgrade" if tone == "bad" else "Sidegrade")) if cur != null else ("▲ Fits" if d_dps >= -0.5 else "▼ Costs damage"), tone, deltas)


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
	_lock_line.text = ""
	if it.is_empty():
		for r in _affix_rows:
			r["button"].visible = false
		_piece_title.text = "Pick a piece"
		_piece_words[0].text = "Stash gear only: not parts, meds, uniques or sets"
		_piece_words[1].text = "Worn gear: press Workshop on it in the Kit"
		_piece_words[2].text = "Pick a piece to see what each job costs."
		_pick.show_empty("Nothing picked", [("In hand: %s and %d scrap" % [Fmt.money(sim.cash), sim.scrap]) if sim.issued else ("In hand: %s, %d notes and %d scrap" % [Fmt.money(sim.cash), sim.notes, sim.scrap]), "Scrap comes from searches, scrapping here and ditching"])
		_set_pick_buttons([])
	else:
		var h := Items.headline(it)
		var tw := Items.type_word(it)
		var fig := "%s %s" % [h[0], "dmg/s" if (tw != "" and Items.is_gun(it)) else h[1]]
		_piece_figure.text = fig
		_piece_title.size.x = BODY_W - 2 * PAD - ceilf(UI.text_width(_piece_figure, fig)) - 16
		UI.fit(_piece_title, [Items.full_name(it), it["base"]])
		var floor_t: int = mini(Items.tier_floor(Items.ilvl(it)), Items.rarity_cap(it))
		var chips := [[Items.rarity_name(it), Pal.tone_color(rarity_tone(it)) if rarity_tone(it) != "" else Pal.TEXT_2], ["Item level %d" % Items.ilvl(it), Pal.TEXT_2],
			{"forms": ["Affixes roll T%d to T%d" % [floor_t, Items.rarity_cap(it)], "T%d–T%d" % [floor_t, Items.rarity_cap(it)]], "colour": Pal.TEXT_2}]
		if it["slot"] in Data.SOCKET_SLOTS:
			var n := Items.sockets(it)
			chips.append(["%d socket%s" % [n, "" if n == 1 else "s"] if n > 0 else "no sockets", Pal.TEXT_2])
		_piece_chips.show_chips(chips, 1)
		var lines: Array = Items.affix_lines(it, false, false)
		var short_lines: Array = Items.affix_lines(it, true, false)
		var locked: Array = sim.locks_of(it)
		var n_aff: int = lines.size()
		for k in range(AFFIX_ROWS):
			var r: Dictionary = _affix_rows[k]
			var has: bool = k < n_aff
			r["stat"] = it["affixes"][k]["stat"] if has else ""
			r["button"].visible = has or k == n_aff
			var tier: int = Items.affix_tier(it, k)
			var colour: Color = Pal.tier_color(tier) if has else Pal.TEXT_3
			var on: bool = has and r["stat"] in locked
			r["lock"].visible = has
			r["lock"].modulate = Pal.ACCENT if on else Pal.TEXT_3
			r["track"].visible = has
			if has:
				# its tier's figures at this piece's level, and where the roll sits in them (20 Oct, Matt: "we need a range displayed")
				var rg: Array = tier_figures(it, k)
				var st: String = str(it["affixes"][k]["stat"])
				r["tag"].text = "T%d · %s–%s" % [tier, Items.fig(st, float(rg[0])), Items.fig(st, float(rg[1]))]
				var room: float = r["label"].size.x - UI.text_width(r["tag"], r["tag"].text) - 16
				r["label"].text = short_lines[k]
				for o in [lines[k], short_lines[k]]:
					if UI.text_width(r["label"], o) <= room:
						r["label"].text = o
						break
				if UI.text_width(r["label"], r["label"].text) > room:
					r["tag"].text = "T%d" % tier          # the words first: the range goes before the affix does
				var span: float = maxf(0.1 if Items.is_tenths(st) else 1.0, float(rg[1]) - float(rg[0]))
				var at: float = clampf((float(it["affixes"][k]["value"]) - float(rg[0])) / span, 0.0, 1.0) if float(rg[1]) > float(rg[0]) else 1.0
				r["mark"].position.x = at * (r["track"].size.x - 4.0)
				r["mark"].add_theme_stylebox_override("panel", UI.box(colour, 2))
				r["button"].tooltip_text = "Click to %s it: a re-roll %s" % ["unlock" if on else "padlock", "will roll it again" if on else "leaves it as it is"]
			else:
				var cap_next: int = mini(Items.rarity_cap(it) + 1, Data.AFFIX_TIERS)
				r["label"].text = "No %s affix" % ORDINAL[k]
				UI.fit(r["tag"], ["Add one: tiers to T%d" % cap_next, "T%d" % cap_next] if int(it["rarity"]) < Data.RARITIES.size() - 1 else [""])
				r["button"].tooltip_text = ""
			r["label"].add_theme_color_override("font_color", colour)
			r["tag"].add_theme_color_override("font_color", Pal.TEXT_2 if has else Pal.TEXT_3)
			r["button"].disabled = not has
			_style(r["button"], on, "", not has, false)
			if not has:
				# the next empty row: no box at all
				for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
					r["button"].add_theme_stylebox_override(st, UI.box(Color.TRANSPARENT, 8))
		# what's locked and how many padlocks; the two re-rolls of the rest, priced
		var lk: Array = []
		for a in it["affixes"]:
			if a["stat"] in locked:
				lk.append(lines[it["affixes"].find(a)])
		var pads: String = "%d of %d padlocks" % [locked.size(), sim.lock_max()]
		UI.fit(_lock_line, (["Locked: %s · %s" % [", ".join(lk), pads], "Locked: %s" % ", ".join(lk)] if not lk.is_empty() else
			["Click an affix to padlock it: the re-rolls leave it as it is · %s" % pads, "Click an affix to padlock it · %s" % pads, "Click an affix to padlock it"]) if n_aff > 0 else [""])
		_lock_line.add_theme_color_override("font_color", Pal.GOOD if not lk.is_empty() else Pal.TEXT_2)
		for i in range(2):
			var kind: String = RE_ROLLS[i]
			var b := _affix_buttons[i]
			var cost: int = sim.craft_cost(it, kind)
			b.visible = cost >= 0
			if cost < 0:
				continue
			var nm: String = str(Data.CRAFT[kind]["name"])
			UI.fit_button(b, ["%s · %s" % [nm, Fmt.money(cost)], "%s · %s" % [nm.get_slice(" ", 1).capitalize(), Fmt.money(cost)], Fmt.money(cost)])
			b.tooltip_text = str(Data.CRAFT[kind]["words"])
			b.disabled = not (on_bench and sim.can_craft(it["id"], kind))
			_affix_actions[i] = _do_craft.bind(it["id"], kind, "")
		_pick.show_pick(it, sim, "The piece · worn" if _worn(it) else "The piece · in the stash")
		_set_pick_buttons([])
	# THE JOBS
	for k in range(JOBS.size()):
		var kind: String = JOBS[k]
		var t: Dictionary = _job_tiles[k]
		var b: Button = t["button"]
		UI.fit(t["name"], [JOB_NAMES.get(kind, Data.CRAFT.get(kind, {}).get("name", kind))])
		var jw: String = JOB_WORDS.get(kind, Data.CRAFT.get(kind, {}).get("words", ""))
		if kind == "temper" and not it.is_empty() and sim.temper_block(it) != "":
			jw = sim.temper_block(it)                  # why it can't, in its words: nothing grows, a mythic, Item level +3 first, past your level (the second review)
		UI.wrap(t["words"], jw % sim.socket_max() if kind == "socket" else jw)     # "up to %d": the real cap (18 Oct)
		var cost: int = -1
		if not it.is_empty():
			cost = ((-1 if _worn(it) else sim.scrap_of(it)) if kind == "scrap" else sim.craft_cost(it, kind))     # a worn piece isn't scrapped off the runner
		var can: bool = false
		if cost >= 0:
			can = on_bench and (true if kind == "scrap" else sim.can_craft(it["id"], kind))
			if kind == "temper" and sim.scrap < sim.temper_scrap(it):
				var also: String = (" · " + Fmt.money_k(cost)) if sim.cash < float(cost) else ""     # and the tins, when they're short too (the reviewer)
				UI.fit(t["price"], [Words.TEMPER["short"] % Fmt.group(sim.temper_scrap(it)) + also, Words.TEMPER["short"] % Fmt.short_num(sim.temper_scrap(it)) + also, Words.TEMPER["short"] % Fmt.short_num(sim.temper_scrap(it))])     # short of scrap: says so (the second review)
			elif kind == "temper":
				UI.fit(t["price"], [Words.TEMPER["price"] % [Fmt.group(sim.temper_scrap(it)), Fmt.money(cost)], Words.TEMPER["price"] % [Fmt.short_num(sim.temper_scrap(it)), Fmt.money_k(cost)]])
			else:
				t["price"].text = ("+%d scrap" % cost) if kind == "scrap" else (Fmt.notes(cost) if sim.craft_in_notes(kind) else Fmt.money(cost))
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


## A row's padlock on or off (20 Oct): the re-rolls leave a locked affix as it is.
func _toggle_lock(k: int) -> void:
	var it := _selected_item()
	var stat: String = _affix_rows[k]["stat"]
	if it.is_empty() or stat == "":
		return
	if not sim.toggle_lock(int(it["id"]), stat):
		var why: String = sim.lock_block(it, stat)
		if why != "":
			_lock_line.text = why
	_shown = ""
	show_state(sim)
	acted.emit()


## An affix's tier's figures on this piece, low and high, as its line shows them (the item level's edge in).
func tier_figures(it: Dictionary, k: int) -> Array:
	var a: Dictionary = it["affixes"][k]
	var d: Dictionary = Items.affix_def(str(a["stat"]))
	var r: Array = Items.tier_range(d, int(a.get("tier", 1)))
	var m: float = Items.ilvl_mult(Items.ilvl(it))
	var div := float(d.get("div", 1))
	if div > 1.0:
		return [snappedf(float(r[0]) * m / div, 0.1), snappedf(float(r[1]) * m / div, 0.1)]     # tenths (20 Oct)
	return [int(round(float(r[0]) * m)), int(round(float(r[1]) * m))]


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
	sel_pattern = -1
	sel_slot = ""
	sel_mount = ""
	sel_id = -1
	sel_stat = ""
	sel_build = ""
	_show_view()
	if sim != null:
		show_state(sim)


func _show_view() -> void:
	for i in range(VIEWS.size()):
		_style(_views[i], VIEWS[i] == view)
	_piece.visible = view == "craft"
	_jobs.visible = view == "craft"
	_kinds.visible = view == "build"
	_builds.visible = view == "build"
	_pat.visible = view == "patterns"
	if _pick != null:
		_pick.visible = view != "patterns"
	for slot in GUNS:
		var g: Dictionary = _guns[slot]
		g["card"].visible = view == "guns"
	for slot in Data.SOCKET_SLOTS:
		var g: Dictionary = _socks[slot]
		g["head"].visible = view == "sockets"
		for mount in g["rows"]:
			g["rows"][mount]["button"].visible = view == "sockets"


## The gun's damage a second with this attachment in place of the mount's.
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
		if _lock_line.text != "":
			out.append(_lock_line)
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
	elif view == "build":
		out.append(_builds_head)
		for t in _kind_tiles:
			out.append_array([t["name"], t["count"]])
		for c in _build_cards:
			if c["button"].visible:
				out.append_array([c["name"], c["cost"], c["words"]])
		if _builds_foot.text != "":
			out.append(_builds_foot)
		if _build_pages.visible:
			out.append(_build_pages)
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
	elif view == "build":
		for c in _build_cards:
			if c["button"].visible:
				out.append([c["words"], c["cost"]])
	else:
		out.append([_piece_title, _piece_figure])
		for r in _affix_rows:
			if r["button"].visible and r["tag"].text != "":
				out.append([r["label"], r["tag"]])
	return out


# ------------------------------------------------------------------ Patterns (24 Oct, the endgame chase, phase 4)

const PAT_ROWS := 5
const PAT_ROW_H := 44


func _build_patterns_view() -> void:
	_pat = UI.panel(self, Rect2(0, TOP, BODY_W, Pal.ROOM_H - TOP), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_pat.visible = false
	var y := 14.0
	_pat_labels["break_head"] = UI.label(_pat, Rect2(PAD, y, BODY_W - 2 * PAD, 22), Words.PATTERNS["break_head"].to_upper(), "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_pat_labels["unique"] = UI.label(_pat, Rect2(PAD, y + 26, BODY_W - 2 * PAD, 30), "", "SemiBold", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_pat_labels["power"] = UI.label(_pat, Rect2(PAD, y + 58, BODY_W - 2 * PAD, 52), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_pat_labels["power"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pat_break = UI.button(_pat, Rect2(PAD, y + 114, 290, 44), true)
	_pat_break.text = Words.PATTERNS["break"]
	_pat_break.pressed.connect(_do_break)
	_pat_labels["gone"] = UI.label(_pat, Rect2(PAD + 302, y + 110, BODY_W - 2 * PAD - 302, 52), Words.PATTERNS["gone"], "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_pat_labels["gone"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART     # what's lost and what's kept, before the press (the language pass)
	y += 176
	_pat_labels["kept_head"] = UI.label(_pat, Rect2(PAD, y, 220, 22), "", "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_pat_labels["kept_note"] = UI.label(_pat, Rect2(PAD + 230, y, BODY_W - 2 * PAD - 230, 22), Words.PATTERNS["kept_note"], "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
	for k in range(PAT_ROWS):
		var b := UI.button(_pat, Rect2(PAD, y + 28 + k * (PAT_ROW_H + 6), BODY_W - 2 * PAD, PAT_ROW_H), false)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG)
		b.pressed.connect(_pick_pattern.bind(k))
		_pat_rows.append(b)
	_pat_labels["none"] = UI.label(_pat, Rect2(PAD, y + 28, BODY_W - 2 * PAD, PAT_ROW_H), Words.PATTERNS["none_kept"], "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	y += 28 + PAT_ROWS * (PAT_ROW_H + 6) + 10
	_pat_labels["put_head"] = UI.label(_pat, Rect2(PAD, y, BODY_W - 2 * PAD, 22), Words.PATTERNS["put_head"].to_upper(), "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_pat_labels["target"] = UI.label(_pat, Rect2(PAD, y + 26, BODY_W - 2 * PAD, 30), "", "SemiBold", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_pat_cost = Chips.new(BODY_W - 2 * PAD, 4)
	_pat_cost.position = Vector2(PAD, y + 62)
	_pat.add_child(_pat_cost)
	_pat_put = UI.button(_pat, Rect2(PAD, y + 100, 200, 44), true)
	_pat_put.text = Words.PATTERNS["put"]
	_pat_put.pressed.connect(_do_put)
	_pat_labels["why"] = UI.label(_pat, Rect2(PAD + 212, y + 96, BODY_W - 2 * PAD - 212, 52), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_pat_labels["why"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _show_patterns() -> void:
	var it := _selected_item()
	var is_u: bool = not it.is_empty() and it.has("unique")
	UI.fit(_pat_labels["unique"], [Items.full_name(it) if is_u else Words.PATTERNS["pick_unique"]])
	_pat_labels["unique"].add_theme_color_override("font_color", Pal.tone_color("unique") if is_u else Pal.TEXT_3)
	var rule_words: Array = ItemHeadRef.unique_rule(it) if is_u else []
	_pat_labels["power"].text = str(rule_words[0]) if not rule_words.is_empty() else ""
	var why_b: String = sim.can_break(it) if is_u else Words.PATTERNS["pick_unique"]
	_pat_break.disabled = why_b != ""
	var armed: bool = is_u and _break_arm.holds(int(it["id"]))
	_pat_break.text = Words.PATTERNS["break_sure"] if armed else Words.PATTERNS["break"]
	UI.style_button(_pat_break, not armed, "bad" if armed else "")
	_pat_labels["gone"].text = Words.PATTERNS["gone"] if why_b == "" else why_b
	_pat_labels["kept_head"].text = (Words.PATTERNS["kept_head"] % sim.patterns.size()).to_upper()
	if sel_pattern >= sim.patterns.size():
		sel_pattern = -1
	_pat_labels["none"].visible = sim.patterns.is_empty()
	for k in range(PAT_ROWS):
		var b: Button = _pat_rows[k]
		b.visible = k < sim.patterns.size()
		if not b.visible:
			continue
		var pt: Dictionary = sim.patterns[k]
		UI.fit_button(b, ["%s · %s" % [pt["unique"], str(pt["slot"]).to_lower()], str(pt["unique"])])
		_style(b, k == sel_pattern)
	var target: bool = not it.is_empty() and not is_u
	UI.fit(_pat_labels["target"], [Items.full_name(it) if target else Words.PATTERNS["pick_rare"]])
	_pat_labels["target"].add_theme_color_override("font_color", Pal.TEXT if target else Pal.TEXT_3)
	var why_p: String = sim.pattern_block(it, sel_pattern) if target else (Words.PATTERNS["no_pattern"] if sel_pattern < 0 else Words.PATTERNS["pick_rare"])
	_pat_cost.visible = target and sel_pattern >= 0
	if _pat_cost.visible:
		var c: Dictionary = sim.pattern_cost(it)
		_pat_cost.show_chips([["1 %s" % sim.thing_name(str(c["key"])), "unique"], ["%d %s" % [int(c["material_n"]), sim.thing_name(str(c["material"]))], "warn"], [Fmt.money(float(c["tins"])), Pal.ACCENT]])
	_pat_put.disabled = why_p != ""
	_pat_labels["why"].text = why_p if why_p != "" else Words.PATTERNS["put_note"]     # nothing in the way: what the press spends, and that it stays


func _pick_pattern(k: int) -> void:
	sel_pattern = -1 if sel_pattern == k else k
	show_state(sim)


## A unique's break asks twice, as the Kit's bin does (the review): the first press arms it, the second breaks it.
var _break_arm := Arm.new()                # a while, another piece, or leaving the room disarms it (the second review)


func _do_break() -> void:
	var it := _selected_item()
	if it.is_empty():
		return
	if not _break_arm.press(int(it["id"])):
		_show_patterns()
		return
	if sim.break_unique(it):
		sel_id = -1
		sel_pattern = sim.patterns.size() - 1
		acted.emit()


func _do_put() -> void:
	var it := _selected_item()
	if sim.apply_pattern(it, sel_pattern):
		sel_pattern = -1
		acted.emit()


## The Patterns view's words, for the fit checks.
func pattern_text_nodes() -> Array:
	var out: Array = _pat_labels.values().filter(func(l): return l.visible and l.text != "")
	out.append_array(_pat_rows.filter(func(b): return b.visible))
	out.append_array([_pat_break, _pat_put])
	out.append_array(_pat_cost.text_nodes() if _pat_cost.visible else [])
	return out


## Out of the room, the break's arm goes (the second review).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		_break_arm.clear()
