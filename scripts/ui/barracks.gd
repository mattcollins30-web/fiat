extends Control
## The Caravan's screen: what the runner was, and training. Three trees as
## three columns - the class's first, the yard's, the class's second - a chain
## each, read top down; a node lit when taken, open when it's next, dim when
## it isn't. Under them a panel for the selected node and the Train and
## Respec buttons. Fixed geometry inside the card grid's 1536 x 864.

signal acted
signal ascend                      # the Second past button: the owner offers the classes
signal retire                      # the Retire button (36): the owner asks, then the runner goes to the wall

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const People := preload("res://scripts/ui/people.gd")
const Words := preload("res://scripts/sim/words.gd")
const Band := preload("res://scripts/ui/band.gd")
const Chips := preload("res://scripts/ui/chips.gd")

const COL_GAP := 16
const COL_W := (Pal.GRID_W - 2 * COL_GAP) / 3                 # 501
const BAND_H := 150                                            # the band: the runner, the points free, the classes along its foot
const FACE := 116                                              # the runner's portrait in the band
const CLASS_H := 40                                            # the class buttons, across the band's top right
const CLASS_W := 176
const TREE_Y := BAND_H + 14
const HEAD_H := 40
const SWAP_W := 160                                            # the middle head's "◂ Petrol" and "Live ▸", either side of the name
const NODE_H := 40                                             # a drawer row's name line
const NODE_GAP := 6
const NODES_Y := TREE_Y + HEAD_H + 6
const TILE_H := 52                                             # a node: a tile, two across, the keystone and the capstone the width
const RAIL_W := 22                                             # the rail down a tree's left: filled as far as it's taken
const TILE_W := (COL_W - RAIL_W - NODE_GAP) / 2
const TILE_ROWS := 7                                           # the yard's twelve nodes two across, and the capstone under
const COLUMN_H := TILE_ROWS * (TILE_H + NODE_GAP) - NODE_GAP   # what a tree takes: a drawer page fits in it too (400)
const SUM_Y := NODES_Y + COLUMN_H + 12                         # what the trees add up to
const SUM_H := 10 + Chips.CHIP_H + 10                            # one line: the head at the left, the eight sums as chips (Caravan-E, 7 Oct; the tiles before were cut at the foot)
const SUM_HEAD_W := 150
const PANEL_Y := SUM_Y + SUM_H + 12
const PANEL_H := Pal.ROOM_H - PANEL_Y
const PAD := 20

var sim
var selected := ""                 # a node id, or ""
var _class_buttons: Array = []
var _class_words: Label
const ROWS := 13                   # the yard's twelve nodes and its capstone; a class tree's ten or eleven and its capstone
var _heads: Array = []             # a column each: {name, count}
var _rows: Array = []              # [column][row] -> {button, name, effect, more (the cost), id}
var _rails: Array = []             # a column each: {track, fill, ticks[], top, bottom}
const TICKS := 5
var _band: Band
var _sum: Panel                    # what the small nodes add up to, under the trees
var _sum_head: Label
var _sum_chips: Chips              # the eight sums, key-value chips, muted at zero
var _chips: Chips                  # the node's figure as a chip, and its type
var _shown_trees := ""
var _panel: Panel
var _face: TextureRect             # the class's portrait, in the band, when there is one
var _title: Label
var _words: Label
var _points: Label                 # "3 of 29" points free: the band's headline
var _scope: Label                  # whose a node is: the yard's, kept, or the runner's, gone with them
var _past: Label                   # the runners before this one
var _wall: Array = []              # their faces, newest first, small
const WALL := 6
const WALL_S := 64
var _ascend: Button                # the second past, from level 30
var _retire: Button                # retire to the wall, from level 30 (36)
var _swap: Button                  # over the middle column's head, right: the next of the yard's tree, the second past's, the elements', the drawer, the shelf
var _back: Button                  # its left: the one before, so an overshoot is one press back
var mid := 0                       # which of the middle trees shows
var drawer_page := 0               # the drawer's page: PAGE papers at a time
const WORD_H := 26                                 # a line of a paper's or a unique's words
var _train: Button
var _respec: Button
var _shown := ""


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	# the band: the runner's face, the class and trait, the points free; the classes along its foot
	var band_panel := UI.panel(self, Rect2(0, 0, Pal.GRID_W, BAND_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_band = Band.new(Pal.GRID_W, BAND_H, 3)
	band_panel.add_child(_band)
	_face = People.rect(_band, Vector2(PAD, 16), FACE / 128.0)
	_points = _band.headline
	_band.right_from(64)
	# the classes: five buttons across the band's top right; the trait's lines sit under them
	var cw := CLASS_W
	var cx0: float = Pal.GRID_W - PAD - Data.CLASSES.size() * cw - 8 * (Data.CLASSES.size() - 1)
	for k in range(Data.CLASSES.size()):
		var cb := UI.button(band_panel, Rect2(cx0 + k * (cw + 8), 12, cw, CLASS_H), false)
		cb.text = Data.CLASSES[k]["name"]
		cb.add_theme_font_size_override("font_size", 22)
		cb.pressed.connect(_pick_class.bind(Data.CLASSES[k]["name"]))
		_class_buttons.append(cb)
	for b in range(3):
		var x := b * (COL_W + COL_GAP)
		var head := UI.panel(self, Rect2(x, TREE_Y, COL_W, HEAD_H), UI.box(Pal.PANEL, 8))
		var h := {}
		h["name"] = UI.label(head, Rect2(PAD, 0, COL_W - 2 * PAD, HEAD_H), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		h["count"] = UI.label(head, Rect2(PAD, 0, COL_W - 2 * PAD, HEAD_H), "", "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT)
		h["panel"] = head
		_heads.append(h)
		# the rail: a track, its fill, ticks where the notables sit, the taken count over it and the tree's size under
		var r := {}
		r["top"] = UI.label(self, Rect2(x - 4, NODES_Y - 2, RAIL_W + 2, 16), "", "SemiBold", 13, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
		r["track"] = UI.panel(self, Rect2(x + (RAIL_W - 6) / 2 - 3, NODES_Y + 16, 6, COLUMN_H - 32), UI.box(Pal.CARD_LINE, 3))
		r["fill"] = UI.panel(r["track"], Rect2(0, 0, 6, 0), UI.box(Pal.ACCENT, 3))
		r["ticks"] = []
		for t in range(TICKS):
			var tick := UI.panel(r["track"], Rect2(-3, 0, 12, 3), UI.box(Pal.ACCENT, 2))
			tick.visible = false
			r["ticks"].append(tick)
		r["bottom"] = UI.label(self, Rect2(x - 4, NODES_Y + COLUMN_H - 14, RAIL_W + 2, 16), "", "Regular", 13, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER)
		_rails.append(r)
		var col := []
		for i in range(ROWS):
			var btn := Button.new()
			btn.position = Vector2(x + RAIL_W, NODES_Y)
			btn.size = Vector2(TILE_W, TILE_H)
			btn.text = ""
			btn.focus_mode = Control.FOCUS_ALL
			btn.pressed.connect(_pick_at.bind(b, i))
			add_child(btn)
			var n := {"button": btn, "id": "", "x": x}
			n["name"] = UI.label(btn, Rect2(10, 3, TILE_W - 20, 22), "", "Regular", Pal.CELL_TEXT_BIG + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			n["more"] = UI.label(btn, Rect2(10, 3, TILE_W - 20, 22), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT)   # the cost, right of the name; the drawer's second line
			n["effect"] = UI.label(btn, Rect2(10, 27, TILE_W - 20, 22), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			n["more2"] = UI.label(btn, Rect2(PAD, 0, COL_W - 2 * PAD, NODE_H), "", "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
			n["more2"].visible = false     # the shelf's third line
			col.append(n)
		_rows.append(col)
	# what the trees add up to: the small nodes' figures, summed
	_sum = UI.panel(self, Rect2(0, SUM_Y, Pal.GRID_W, SUM_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_sum_head = UI.head(_sum, Rect2(PAD, 10, SUM_HEAD_W, Chips.CHIP_H), "Add up to")
	_sum_head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sum_chips = Chips.new(Pal.GRID_W - 2 * PAD - SUM_HEAD_W - 10, 8)
	_sum_chips.position = Vector2(PAD + SUM_HEAD_W + 10, 10)
	_sum.add_child(_sum_chips)
	_panel = UI.panel(self, Rect2(0, PANEL_Y, Pal.GRID_W, PANEL_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_title = UI.label(_panel, Rect2(PAD, 10, Pal.GRID_W - 2 * PAD, 34), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_chips = Chips.new(600)
	_chips.position = Vector2(PAD, 47)
	_panel.add_child(_chips)
	_words = UI.label(_panel, Rect2(PAD, 46, Pal.GRID_W - 2 * PAD, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_scope = UI.label(_panel, Rect2(PAD, 74, Pal.GRID_W - 2 * PAD, 28), "", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_past = UI.label(_panel, Rect2(PAD, 108, Pal.GRID_W - 2 * PAD - 520, 30), "", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(WALL):
		_wall.append(People.rect(_panel, Vector2(PAD, PANEL_H - WALL_S - 10), 0.5))
	_train = UI.button(_panel, Rect2(0, PANEL_H - PAD - Pal.BUTTON_H, 200, Pal.BUTTON_H), true)
	_train.pressed.connect(_on_train)
	_respec = UI.button(_panel, Rect2(0, PANEL_H - PAD - Pal.BUTTON_H, 240, Pal.BUTTON_H), false)
	_respec.pressed.connect(_on_respec)
	_ascend = UI.button(_panel, Rect2(0, PANEL_H - PAD - Pal.BUTTON_H, 240, Pal.BUTTON_H), false)
	_ascend.pressed.connect(func(): ascend.emit())
	_ascend.visible = false
	_retire = UI.button(_panel, Rect2(0, PANEL_H - PAD - Pal.BUTTON_H, 240, Pal.BUTTON_H), false)
	_retire.pressed.connect(func(): retire.emit())
	_retire.visible = false
	_swap = UI.button(self, Rect2(COL_W + COL_GAP + COL_W - SWAP_W, TREE_Y, SWAP_W, HEAD_H), false)
	_swap.pressed.connect(_on_swap)
	_swap.visible = false
	_swap.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_back = UI.button(self, Rect2(COL_W + COL_GAP, TREE_Y, SWAP_W, HEAD_H), false)
	_back.pressed.connect(_on_back)
	_back.visible = false
	_back.alignment = HORIZONTAL_ALIGNMENT_LEFT


const EFFECT_WORDS := {
	"damage_pct": "+%d%% damage", "hp": "+%d max HP", "loot_pct": "+%d%% quantity", "search_pct": "Search %d%% faster",
	"first_pct": "First shot +%d%%", "patrol_pct": "Gangs %d%% later", "armour_pct": "Armour +%d%%", "heal_pct": "Meds +%d%%",
	"med_speed_pct": "Meds %d%% quicker", "med_cap": "+%d med carried", "rest_pct": "Rest +%d%%", "treat_pct": "Treatment −%d%%",
	"att_share": "+%d%% attachments", "sell_pct": "Fence pays +%d%%", "cash_pct": "Cash +%d%%", "rarity": "+%d%% quality",
	"pace_pct": "+%d%% pace", "damage_low_pct": "+%d%% dmg under ½ HP",
	"conv_fire_pct": "%d%% as fire", "conv_frost_pct": "%d%% as frost", "conv_poison_pct": "%d%% as poison", "conv_shock_pct": "%d%% as shock", "conv_bleed_pct": "%d%% as bleed",
	"fire_pct": "+%d%% fire", "frost_pct": "+%d%% frost", "poison_pct": "+%d%% poison", "shock_pct": "+%d%% shock", "bleed_pct": "+%d%% bleed", "physical_pct": "+%d%% physical",
	"dot_pct": "+%d%% dots",
}
const TYPE_WORDS := {"rifle": "rifles", "shotgun": "shotguns", "smg": "SMGs", "improvised": "improvised", "pistol": "pistols", "melee": "melee"}
## The panel's sentence for a plain node: what happens, in words; the figure is the chip's (Caravan-E, 7 Oct).
const PANEL_WORDS := {
	"damage_pct": "Every shot hits harder, whatever is in hand.", "hp": "More to lose before a bail-out.", "loot_pct": "Every search turns up a little more.",
	"search_pct": "The picking-over goes quicker.", "first_pct": "The opening shot on every gang hits harder.", "patrol_pct": "The next gang takes longer to arrive.",
	"armour_pct": "Less of every hit gets through.", "heal_pct": "Every med heals more.", "med_speed_pct": "Every med works quicker.", "med_cap": "One more pouch on the rig.",
	"rest_pct": "Resting at the yard heals faster.", "treat_pct": "The clinic charges less.", "att_share": "Gun parts count for more.",
	"sell_pct": "The fence pays more for what you sell.", "cash_pct": "Every run's take is bigger.", "rarity": "Rarer things turn up.",
	"pace_pct": "The fight and the search go quicker.", "damage_low_pct": "Under half HP, every shot hits harder.",
	"conv_fire_pct": "A share of every hit lands as fire and keeps burning.", "conv_frost_pct": "A share of every hit lands as frost and slows them.", "conv_poison_pct": "A share of every hit lands as poison and keeps working.",
	"conv_shock_pct": "A share of every hit lands as shock.", "conv_bleed_pct": "A share of every hit lands as bleed and keeps bleeding.",
	"fire_pct": "Fire hits harder.", "frost_pct": "Frost hits harder.", "poison_pct": "Poison hits harder.", "shock_pct": "Shock hits harder.",
	"bleed_pct": "Bleed hits harder.", "physical_pct": "Plain shot hits harder.", "dot_pct": "Burns, poison and bleeds all do more.",
}
## The chip's tone for a node's figure: an element's colour for its damage or conversion, the accent for a
## notable, keystone or capstone, green for a plain bonus.
static func _effect_tone(nd: Dictionary) -> Color:
	if nd.get("capstone", false) or nd.get("keystone", false) or nd.get("notable", false):
		return Pal.ACCENT
	var e: String = str(nd.get("effect", ""))
	for el in Pal.ELEMENT_COLOURS:
		if e.begins_with("conv_" + el) or e.begins_with(el + "_pct"):
			return Pal.ELEMENT_COLOURS[el]
	return Pal.GOOD


## The sentence under a node: its own words for a notable, keystone or capstone; the effect's for a plain one.
static func _sentence(nd: Dictionary) -> String:
	if nd.has("words"):
		var w: String = str(nd["words"])
		return w if w.ends_with(".") or w.ends_with("!") else w + "."
	return str(PANEL_WORDS.get(nd["effect"], ""))


## The panel's chip: a notable with a figure shows the figure (Rifleman: "First shot +100%"); a keystone or
## capstone its kind; a plain node its figure.
static func _chip_words(nd: Dictionary) -> String:
	if nd.get("capstone", false):
		return "Capstone"
	if nd.get("keystone", false):
		return "Keystone"
	if EFFECT_WORDS.has(nd.get("effect", "")) and nd.has("value"):
		return EFFECT_WORDS[nd["effect"]] % nd.get("value", 0)
	return "Notable"


static func _effect_words(nd: Dictionary) -> String:
	if nd.get("capstone", false):
		return "Capstone"
	if nd.get("keystone", false):
		return "Keystone"
	if nd.get("notable", false):
		return "Notable"
	var w: String = EFFECT_WORDS.get(nd["effect"], "Notable") % nd.get("value", 0) if EFFECT_WORDS.has(nd["effect"]) else "Notable"
	if nd.has("type"):
		w += ", " + TYPE_WORDS[nd["type"]]
	return w


func _style(b: Button, look: String) -> void:
	# "taken": lit with the accent; "open": plain; "locked": dim
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var sb: StyleBoxFlat
		match look:
			"taken":
				sb = UI.box(Pal.SELECT, 8)
				sb.border_width_left = 6
				sb.border_color = Pal.ACCENT
			"idle":
				# taken, but typed for a gun that isn't in hand
				sb = UI.box(Pal.SELECT, 8)
				sb.border_width_left = 6
				sb.border_color = Pal.TEXT_3
			"open":
				sb = UI.box(Pal.CARD if state == "hover" else Pal.PANEL, 8)
			_:
				sb = UI.box(Pal.BG, 8)
		if look == "selected":
			sb = UI.box(Pal.SELECT, 8)
			sb.set_border_width_all(2)
			sb.border_color = Pal.ACCENT
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 8, 2, Pal.TEXT))


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	var sig := "%s|%s|%d|%d|%s|%s|%d|%s|%d|%d|%d|%s|%d|%s" % [selected, str(sim.tree), sim.training_points, int(sim.cash), sim.cls, str(sim.on_mission()), mid, sim.cls2, sim.book.size(), drawer_page, sim.shelf.size(),
		sim.gun_type(), sim.level(), str(sim.trades)]        # the gun in hand idles typed nodes; the level opens the second past; a trade halves costs
	if sig == _shown:
		return
	_shown = sig
	for k in range(Data.CLASSES.size()):
		var cb: Button = _class_buttons[k]
		var name: String = Data.CLASSES[k]["name"]
		cb.text = name if sim.cls != name else "%s ✓" % name
		cb.disabled = sim.on_mission()
		UI.style_button(cb, sim.cls == name)
	# the band: the runner, the points free as the headline, the trait on the right
	var cd0: Dictionary = sim.class_data()
	var td0: Dictionary = sim.trait_data()
	var faced := People.show(_face, sim.cls)
	_band.portrait_width(FACE if faced else 0)
	var free0: int = sim.points_free()
	var who0: String = str(cd0.get("name", "No past yet"))
	_band.set_words(("%s · %s" % [who0, td0["name"]]) if not td0.is_empty() else who0, "The caravan",
		"%d of %d" % [free0, sim.training_points], ["point%s free" % ("" if sim.training_points == 1 else "s"), "free"], Pal.ACCENT if free0 > 0 else Pal.TEXT_2)
	_band.headline_under_title(true)
	if not td0.is_empty():
		var trait_line := "%s: %s" % [td0["name"], td0["words"]]
		_band.set_right([trait_line if UI.text_width(_band.right[0], trait_line) <= _band.RIGHT_W else td0["name"], "one a runner, theirs"])
	else:
		_band.set_right([])
	var trees: Array = sim.trees()
	# the class's two trees either side; the middle cycles the yard's, the
	# second past's and the five elements'. With no class, the yard's alone.
	var mids := _mid_trees(trees)
	mid = mid % maxi(1, mids.size())
	var cols := [null, null, null]
	if sim.cls != "":
		cols = [trees[0], mids[mid], trees[2]]
	else:
		cols[1] = mids[mid]
	_swap.visible = mids.size() > 1
	_back.visible = mids.size() > 1
	var next_name: String = mids[(mid + 1) % mids.size()]["name"] if mids.size() > 1 else ""
	var prev_name: String = mids[(mid - 1 + mids.size()) % mids.size()]["name"] if mids.size() > 1 else ""
	for sb in [_swap, _back]:
		sb.add_theme_stylebox_override("normal", UI.box(Color.TRANSPARENT, 8))
		sb.add_theme_stylebox_override("hover", UI.box(Color(Pal.CARD, 0.5), 8))
		sb.add_theme_font_size_override("font_size", 18)
	_swap.text = _arrow_text(_swap, next_name, false) if mids.size() > 1 else ""
	_back.text = _arrow_text(_back, prev_name, true) if mids.size() > 1 else ""
	for b in range(3):
		var branch = cols[b]
		var h: Dictionary = _heads[b]
		h["panel"].visible = branch != null
		_rail_show(b, branch)
		if branch == null:
			for i in range(ROWS):
				_rows[b][i]["button"].visible = false
				_rows[b][i]["id"] = ""
			continue
		var taken := 0
		var who: String = branch.get("class", "")
		# the middle head shares its row with the back and next buttons: the name sits centred between them
		var flanked: bool = b == 1 and _swap.visible
		h["name"].position.x = SWAP_W if flanked else PAD
		h["name"].size.x = COL_W - 2 * (SWAP_W if flanked else PAD)
		h["name"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if flanked else HORIZONTAL_ALIGNMENT_LEFT
		if branch.get("drawer", false):
			_show_drawer(b, branch)
			continue
		if branch.has("element"):
			UI.fit(h["name"], ["%s · %s%s" % [branch["name"], branch["element"], "" if sim.affinity(branch["element"]) else " · double"], "%s · %s" % [branch["name"], branch["element"]], branch["name"]])
		else:
			UI.fit(h["name"], [branch["name"] if who == "" else "%s · %s" % [branch["name"], who], branch["name"]])
		for i in range(ROWS):
			var n: Dictionary = _rows[b][i]
			if i >= branch["nodes"].size():
				n["button"].visible = false
				n["id"] = ""
				continue
			var id := "%s/%d" % [branch["name"], i]
			var nd: Dictionary = branch["nodes"][i]
			n["id"] = id
			n["button"].visible = true
			n["more2"].visible = false
			n["more2"].text = ""
			_place(n, branch, i)
			var cost: int = sim.node_cost(id)
			var pts := "%d pt%s" % [cost, "" if cost == 1 else "s"]
			# the tile: ★ a notable, ◆ the keystone, the name; the cost at the right; the effect under
			var big: bool = nd.get("notable", false) or nd.get("keystone", false) or nd.get("capstone", false)
			n["name"].add_theme_font_override("font", UI.font("SemiBold" if big else "Regular", false))
			var mark: String = "◆◆ " if nd.get("capstone", false) else ("◆ " if nd.get("keystone", false) else ("★ " if nd.get("notable", false) else ""))
			n["more"].visible = true
			n["more"].text = pts
			# the name keeps clear of the cost: whole, then its first word
			var room: float = n["name"].size.x - UI.text_width(n["more"], pts) - 16.0
			n["name"].text = mark + nd["name"]
			if UI.text_width(n["name"], n["name"].text) > room:
				n["name"].text = mark + _short_name(nd["name"])
			# a plain node's figure; a notable's words cut to their first clause, "Notable" when even that won't fit
			var eff: String = _effect_words(nd)
			if big and nd.has("words"):
				var first: String = str(nd["words"])
				for sep in ["; ", ": ", ", "]:
					first = first.get_slice(sep, 0)
				UI.fit(n["effect"], [str(nd["words"]), first, eff])
			else:
				UI.fit(n["effect"], [eff, eff.get_slice(", ", 0)])
			var is_taken: bool = sim.tree.has(id)
			var need := Data.node_needs(branch, i)
			var open: bool = sim.can_train(id) or (not is_taken and (need < 0 or sim.tree.has("%s/%d" % [branch["name"], need])))
			if is_taken:
				taken += 1
			var look := ("taken" if sim._active(nd) else "idle") if is_taken else ("open" if open else "locked")
			if id == selected:
				look = "selected"
			_style(n["button"], look)
			n["name"].add_theme_color_override("font_color", Pal.TEXT if (is_taken or open) else Pal.TEXT_3)
			n["effect"].add_theme_color_override("font_color", Pal.TEXT_2 if (is_taken or open) else Pal.TEXT_3)
			n["more"].add_theme_color_override("font_color", Pal.TEXT_2 if (is_taken or open) else Pal.TEXT_3)
		h["count"].text = "%d of %d" % [taken, branch["nodes"].size()]
		h["count"].visible = not (b == 1 and _swap.visible)      # the swap sits where the count would
		_rail_fill(b, branch, taken)
	_show_sum(cols)
	_show_panel()


## A node's name cut to its first word when the tile won't take it.
static func _short_name(name: String) -> String:
	var words: PackedStringArray = name.split(" ", false)
	return words[0] if words.size() > 1 else name


## The rail beside a tree: shown for a tree, hidden for the drawer and the shelf.
func _rail_show(b: int, branch) -> void:
	var r: Dictionary = _rails[b]
	var on: bool = branch != null and not branch.get("drawer", false)
	for k in ["top", "track", "bottom"]:
		r[k].visible = on


## The rail's fill: as far down the tiles as the tree is taken (a half-taken row fills half); a tick a notable.
func _rail_fill(b: int, branch: Dictionary, taken: int) -> void:
	var r: Dictionary = _rails[b]
	var rects: Array = _tile_rects(branch)
	var rows_total: int = _rows_of(rects)
	var filled := 0.0
	var row_taken := {}
	var row_n := {}
	for i in range(branch["nodes"].size()):
		var row: int = int(rects[i].position.y)
		row_n[row] = int(row_n.get(row, 0)) + 1
		if sim.tree.has("%s/%d" % [branch["name"], i]):
			row_taken[row] = int(row_taken.get(row, 0)) + 1
	for row in row_n:
		filled += float(row_taken.get(row, 0)) / float(row_n[row])
	var track_h: float = r["track"].size.y
	r["fill"].size.y = roundf(track_h * (filled / maxf(1.0, float(rows_total))))
	r["top"].text = "%d" % taken
	r["bottom"].text = "%d" % branch["nodes"].size()
	var t := 0
	for i in range(branch["nodes"].size()):
		var nd: Dictionary = branch["nodes"][i]
		if (nd.get("notable", false) or nd.get("keystone", false) or nd.get("capstone", false)) and t < TICKS:
			var tick: Panel = r["ticks"][t]
			tick.visible = true
			# the tick at the row's middle, in the track's own height
			tick.position.y = clampf((rects[i].position.y + TILE_H / 2.0 - 16.0) / (COLUMN_H - 32.0) * track_h, 0.0, track_h - 3.0)
			(tick.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.ACCENT if sim.tree.has("%s/%d" % [branch["name"], i]) else Pal.TEXT_3
			t += 1
	for k in range(t, TICKS):
		r["ticks"][k].visible = false


## How many rows of tiles a set of rects takes.
static func _rows_of(rects: Array) -> int:
	var ys := {}
	for rc in rects:
		ys[int(rc.position.y)] = true
	return ys.size()


## What the small nodes add up to, over the trees showing: the figures the Yard reads, by source.
func _show_sum(cols: Array) -> void:
	var sums := {}
	var notables_taken := 0
	var notables_open := 0
	for branch in cols:
		if branch == null or branch.get("drawer", false):
			continue
		for i in range(branch["nodes"].size()):
			var nd: Dictionary = branch["nodes"][i]
			var id := "%s/%d" % [branch["name"], i]
			if nd.get("notable", false) or nd.get("keystone", false) or nd.get("capstone", false):
				if sim.tree.has(id):
					notables_taken += 1
				else:
					notables_open += 1
			elif sim.tree.has(id) and sim._active(nd):
				sums[nd["effect"]] = float(sums.get(nd["effect"], 0.0)) + float(nd.get("value", 0))
	var figures := [
		["Damage", "+%.0f%%" % sums.get("damage_pct", 0.0)], ["Max HP", "+%.0f" % sums.get("hp", 0.0)], ["First shot", "+%.0f%%" % sums.get("first_pct", 0.0)],
		["Search", "%.0f%% faster" % sums.get("search_pct", 0.0)], ["Gangs", "%.0f%% later" % sums.get("patrol_pct", 0.0)],
		["Quality", "+%.0f%%" % sums.get("rarity", 0.0)], ["Quantity", "+%.0f%%" % sums.get("loot_pct", 0.0)],
		["Notables", "%d of %d" % [notables_taken, notables_taken + notables_open]],
	]
	var items := []
	for f in figures:
		var zero: bool = f[1].begins_with("+0") or f[1].begins_with("0%")
		items.append({"tag": f[0], "forms": [f[1]], "colour": Pal.ACCENT if f[0] == "Notables" else (Pal.TEXT_2 if zero else Pal.GOOD)})
	_sum_chips.show_chips(items)


func _show_panel() -> void:
	_train.visible = false
	_chips.visible = false
	for l in [_title, _words, _scope]:
		l.position.x = PAD
		l.size.x = Pal.GRID_W - 2 * PAD
	_past.position.x = PAD
	_scope.text = ""
	if selected == "":
		var cd: Dictionary = sim.class_data()
		if cd.is_empty():
			_title.text = "No past yet"
			_words.text = "Pick one above: what the runner was, and how they fight now. Free to change in the yard"
		else:
			var td: Dictionary = sim.trait_data()
			_title.text = ("%s · %s" % [cd["name"], td["name"]]) if not td.is_empty() else "%s" % cd["name"]
			UI.fit(_words, [cd["words"]])
			if not td.is_empty():
				UI.fit(_scope, ["%s: %s · the runner's trait, one each, goes with them" % [td["name"], td["words"]], "%s: %s · one a runner" % [td["name"], td["words"]], "%s: %s" % [td["name"], td["words"]]])
	else:
		var nd: Dictionary = sim.node(selected)
		if nd.is_empty():
			selected = ""
			_show_panel()
			return
		_title.text = nd["name"] + (" · capstone" if nd.get("capstone", false) else (" · keystone" if nd.get("keystone", false) else (" · notable" if nd.get("notable", false) else "")))
		# the figure as a chip in its tone, the type as a muted one, and one sentence after them (Caravan-E)
		var items := [{"forms": [_chip_words(nd)], "colour": _effect_tone(nd)}]
		if nd.has("type"):
			items.append({"forms": [TYPE_WORDS[nd["type"]]], "colour": Pal.TEXT_2})
		_chips.visible = true
		_chips.show_chips(items)
		_words.position.x = PAD + _chips.used_width() + 10
		_words.size.x = Pal.GRID_W - PAD - _words.position.x
		UI.fit(_words, [_sentence(nd), ""])
		# the capstone's wants; whose the node is went (Matt, 7 Oct: the same two lines under every node, useless)
		var branch: String = str(selected).get_slice("/", 0)
		if nd.get("capstone", false) and not sim.tree.has(selected):
			var has_key: bool = Data.tree_named(branch)["nodes"].any(func(x): return x.get("keystone", false))
			if has_key:
				UI.fit(_scope, ["The capstone: wants the keystone and every notable of the tree, and a quarter of the tree's points again", "Wants the keystone and every notable first", "Wants the whole tree first"])
			else:
				UI.fit(_scope, ["The capstone: wants every notable of the tree, and a quarter of the tree's points again", "Wants every notable first", "Wants the whole tree first"])
		if sim.tree.has(selected):
			_title.text += " · trained" if sim._active(nd) else " · trained, idle without the gun for it"
		else:
			_train.visible = true
			var cost: int = sim.node_cost(selected)
			_train.text = "Train (%d point%s)" % [cost, "" if cost == 1 else "s"]
			_train.disabled = not sim.can_train(selected)
			_train.size.x = ceilf(UI.text_width(_train, _train.text)) + 48
	_respec.text = "Respec for %s" % Fmt.money(sim.respec_cost())
	_respec.disabled = sim.tree.is_empty() or sim.cash < sim.respec_cost()
	_respec.size.x = ceilf(UI.text_width(_respec, _respec.text)) + 48
	var x := Pal.GRID_W - PAD
	x -= _respec.size.x
	_respec.position.x = x
	_ascend.visible = sim.cls != "" and (sim.can_ascend() or sim.cls2 != "")
	if _ascend.visible:
		_ascend.text = ("Second past: %s" % sim.cls2) if sim.cls2 != "" else "Take a second past"
		_ascend.disabled = not sim.can_ascend()
		_ascend.size.x = ceilf(UI.text_width(_ascend, _ascend.text)) + 48
		x -= 12 + _ascend.size.x
		_ascend.position.x = x
	_retire.visible = sim.cls != "" and sim.level() >= Data.RETIRE_LEVEL
	if _retire.visible:
		_retire.text = "Retire to the wall"
		_retire.disabled = not sim.can_retire()
		_retire.size.x = ceilf(UI.text_width(_retire, _retire.text)) + 48
		x -= 12 + _retire.size.x
		_retire.position.x = x
	if _train.visible:
		x -= 12 + _train.size.x
		_train.position.x = x
	# the runners before, in what's left beside the buttons: on the class's panel, not under a node
	_past.size.x = x - 12 - _past.position.x
	_past.visible = selected == ""
	if selected == "":
		_show_past()
	else:
		for t in _wall:
			t.visible = false


# ------------------------------------------------------------------ acting

## The runners before this one, newest first: who, how long, how it ended.
func _show_past() -> void:
	if sim.past.is_empty():
		# no one before this runner: what this one was, instead
		for t in _wall:
			t.visible = false
		UI.fit(_past, [Words.PASTS[sim.cls]["was"] if Words.PASTS.has(sim.cls) else "", ""])
		return
	var long := []
	var short := []
	for k in range(sim.past.size() - 1, -1, -1):
		var r: Dictionary = sim.past[k]
		long.append("a %s, %d run%s, %s" % [str(r["class"]).to_lower(), int(r["runs"]), "" if int(r["runs"]) == 1 else "s", r["end"]])
		short.append("%s %d" % [str(r["class"]).to_lower(), int(r["runs"])])
	# the wall: their faces, newest first, and the line beside it in what's left
	var x: float = _past.position.x
	var faces := 0
	for k in range(WALL):
		var t: TextureRect = _wall[k]
		var shown := false
		if k < sim.past.size():
			shown = People.show(t, str(sim.past[sim.past.size() - 1 - k]["class"]))
		else:
			t.visible = false
		if shown:
			t.position = Vector2(x, PANEL_H - WALL_S - 10)
			x += WALL_S + 8
			faces += 1
	var right: float = _past.position.x + _past.size.x
	if faces > 0:
		x += 8
		_past.position.x = x
		_past.size.x = maxf(60.0, right - x)
	var more: int = sim.past.size() - faces
	var tail := (" and %d more" % more) if faces > 0 and more > 0 else ""
	UI.fit(_past, ["Before: " + "; ".join(long), "Before: " + ("; ".join(long.slice(0, 2)) + tail if faces > 0 else "; ".join(long)), "Before: " + ", ".join(short), long[0] + tail, "%d runner%s before this one" % [sim.past.size(), "" if sim.past.size() == 1 else "s"]])


func _pick(id: String) -> void:
	if id.begins_with("drawer/"):
		drawer_page += 1                   # a click on the drawer turns the page
		_shown = ""
		show_state(sim)
		return
	selected = id
	show_state(sim)


func _pick_at(col: int, row: int) -> void:
	var id: String = _rows[col][row]["id"]
	if id != "":
		_pick(id)


## Where a node sits: the tiles two across in the order of the tree, the
## keystone across both; a notable's row is its own. Returns the rects for
## every node of the branch, in the column's own space.
static func _tile_rects(branch: Dictionary) -> Array:
	var out: Array = []
	var row := 0
	var col := 0
	for i in range(branch["nodes"].size()):
		var nd: Dictionary = branch["nodes"][i]
		var wide: bool = nd.get("keystone", false) or nd.get("capstone", false)
		if wide and col == 1:
			row += 1
			col = 0
		out.append(Rect2(RAIL_W + col * (TILE_W + NODE_GAP), row * (TILE_H + NODE_GAP), (2 * TILE_W + NODE_GAP) if wide else TILE_W, TILE_H))
		if wide:
			row += 1
			col = 0
		else:
			col += 1
			if col == 2:
				col = 0
				row += 1
	return out


func _place(n: Dictionary, branch: Dictionary, i: int) -> void:
	var b: Button = n["button"]
	var rc: Rect2 = _tile_rects(branch)[i]
	b.position = Vector2(n["x"] + rc.position.x, NODES_Y + rc.position.y)
	b.size = rc.size
	n["name"].position = Vector2(10, 3)
	n["name"].size = Vector2(rc.size.x - 20, 22)
	n["more"].position = Vector2(10, 3)
	n["more"].size = Vector2(rc.size.x - 20, 22)
	n["more"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	n["effect"].position = Vector2(10, 27)
	n["effect"].size = Vector2(rc.size.x - 20, 22)
	n["effect"].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


## The node the branches fork from: the first node two others need.
static func _fork_at(branch: Dictionary) -> int:
	var counts := {}
	for i in range(1, branch["nodes"].size()):
		var need := Data.node_needs(branch, i)
		counts[need] = int(counts.get(need, 0)) + 1
		if counts[need] >= 2:
			return need
	return -1


## Whether a node sits on a branch off the spine (for the indent).
static func _in_branch(branch: Dictionary, i: int) -> bool:
	var k := i
	while k > 0:
		var need := Data.node_needs(branch, k)
		if need != k - 1:
			return true
		k = need
	return false


## The middle column's trees: the yard's, the second past's first, the elements'.
func _mid_trees(trees: Array) -> Array:
	var out: Array = []
	if sim.cls == "":
		return [trees[0]] if not trees.is_empty() else []
	out.append(trees[1])
	for t in trees.slice(3):
		out.append(t)
	out.append(_drawer_branch())
	out.append(_shelf_branch())
	return out


## The drawer, as a column: the papers found so far, in the order found,
## PAGE a page; a click on any of them turns the page.
func _drawer_branch() -> Dictionary:
	return _pages_branch("The drawer", sim.book, sim.book_pages().size(), Words.BOOK["empty"], func(name): return Words.item_words(name), 2)


## The shelf: the uniques found, the same way, their three lines under each.
func _shelf_branch() -> Dictionary:
	return _pages_branch("The shelf", sim.shelf, Data.UNIQUES.size(), Words.SHELF["empty"], func(name): return Words.UNIQUES.get(name, ""), 3)


## A page of a list: a row a name with `lines` of words under it, as many rows as the column takes.
func _pages_branch(title: String, list: Array, total: int, empty: String, words: Callable, lines: int) -> Dictionary:
	var row_h: int = NODE_H + lines * WORD_H + 4
	var per: int = maxi(1, (COLUMN_H + NODE_GAP) / (row_h + NODE_GAP))
	var pages: int = maxi(1, ceili(float(list.size()) / per))
	var page: int = drawer_page % pages
	var nodes: Array = []
	var start: int = page * per
	for k in range(start, mini(list.size(), start + per)):
		nodes.append({"name": "%d. %s" % [k + 1, list[k]], "words": str(words.call(list[k]))})
	if nodes.is_empty():
		nodes.append({"name": empty, "words": ""})
	return {"name": title, "drawer": true, "nodes": nodes, "pages": pages, "page": page, "found": list.size(), "total": total, "lines": lines, "row_h": row_h}


func _show_drawer(b: int, branch: Dictionary) -> void:
	var h: Dictionary = _heads[b]
	var total: int = branch["total"]
	var found: int = branch["found"]
	var title: String = branch["name"]
	var page := (" · page %d of %d" % [int(branch["page"]) + 1, int(branch["pages"])]) if int(branch["pages"]) > 1 else ""
	var short_page := (" · p%d/%d" % [int(branch["page"]) + 1, int(branch["pages"])]) if int(branch["pages"]) > 1 else ""
	var short_title: String = title.get_slice(" ", 1).capitalize()
	UI.fit(h["name"], [title + " · " + Words.BOOK["count"] % [found, total] + page, "%s · %d of %d%s" % [short_title, found, total, short_page], "%s %d/%d%s" % [short_title, found, total, short_page], "%d/%d%s" % [found, total, short_page], title])
	h["count"].visible = false
	for i in range(ROWS):
		var n: Dictionary = _rows[b][i]
		if i >= branch["nodes"].size():
			n["button"].visible = false
			n["id"] = ""
			continue
		var nd: Dictionary = branch["nodes"][i]
		var btn: Button = n["button"]
		var row_h: int = branch["row_h"]
		var lines: int = branch["lines"]
		btn.visible = true
		btn.position = Vector2(n["x"], NODES_Y + i * (row_h + NODE_GAP))
		btn.size = Vector2(COL_W, row_h)
		n["id"] = "drawer/%d" % i
		n["name"].position = Vector2(PAD, 4)
		n["name"].size = Vector2(COL_W - 2 * PAD, NODE_H - 4)
		n["name"].add_theme_font_override("font", UI.font("SemiBold" if nd["words"] != "" else "Regular", false))
		var word_labels: Array = [n["effect"], n["more"], n["more2"]]
		for k in range(3):
			var l: Label = word_labels[k]
			l.visible = k < lines
			l.position = Vector2(PAD, NODE_H - 2 + k * WORD_H)
			l.size = Vector2(COL_W - 2 * PAD, WORD_H)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			l.add_theme_color_override("font_color", Pal.TEXT_2)
			l.text = ""
		if nd["words"] == "":
			UI.wrap([n["name"]] + word_labels.slice(0, lines), nd["name"])     # the empty line, over the row
		else:
			UI.fit(n["name"], [nd["name"]])
			UI.wrap(word_labels.slice(0, lines), nd["words"])
		_style(btn, "taken" if nd["words"] != "" else "locked")
		n["name"].add_theme_color_override("font_color", Pal.TEXT)


## A paper's words cut to the column: up to the last full stop that fits.
static func _short(words: String) -> String:
	var cut := words.rfind(".", words.length() - 2)
	return words.substr(0, cut + 1) if cut > 0 else words


func _on_swap() -> void:
	mid += 1
	drawer_page = 0
	_shown = ""
	show_state(sim)


## "◂ Petrol" when the name fits the button, "◂ Back" when it doesn't.
func _arrow_text(b: Button, name: String, back: bool) -> String:
	var full := ("◂ %s" % name) if back else ("%s ▸" % name)
	var w: float = b.get_theme_font("font").get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x
	if w <= SWAP_W - 12:
		return full
	return "◂ Back" if back else "Next ▸"


func _on_back() -> void:
	mid = mid - 1 + _mid_trees(sim.trees()).size()
	drawer_page = 0
	_shown = ""
	show_state(sim)


func _pick_class(name: String) -> void:
	if sim.set_class(name):
		selected = ""
		acted.emit()
	show_state(sim)


func _on_train() -> void:
	if selected != "" and sim.train_node(selected):
		acted.emit()
	show_state(sim)


func _on_respec() -> void:
	if sim.respec():
		acted.emit()
	show_state(sim)


## For the tests: every label with text.
func text_nodes() -> Array:
	var out: Array = [_title, _words, _scope, _past, _respec, _sum_head]
	if _chips.visible:
		out.append_array(_chips.text_nodes())
	out.append_array(_sum_chips.text_nodes())
	out.append_array(_band.text_nodes())
	for r in _rails:
		if r["track"].visible:
			out.append_array([r["top"], r["bottom"]])
	if _ascend.visible:
		out.append(_ascend)
	if _retire.visible:
		out.append(_retire)
	if _swap.visible:
		out.append_array([_swap, _back])
	if _train.visible:
		out.append(_train)
	out.append_array(_class_buttons)
	for h in _heads:
		if h["panel"].visible:
			out.append_array([h["name"], h["count"]])
	for col in _rows:
		for n in col:
			if n["button"].visible:
				out.append_array([n["name"], n["effect"]])
				if n["more"].visible:
					out.append(n["more"])
				if n["more2"].visible:
					out.append(n["more2"])
	return out
